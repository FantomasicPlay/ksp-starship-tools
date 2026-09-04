using System.IO;
using System.Runtime.InteropServices;
using System.Text.Json;
using System.Windows;
using System.Windows.Interop;
using System.Windows.Threading;

namespace KspOverlay;

public partial class MainWindow : Window
{
    // ---- Win32: делаем окно прозрачным для мыши, чтобы не мешало играть ----
    private const int GWL_EXSTYLE = -20;
    private const int WS_EX_TRANSPARENT = 0x20;
    private const int WS_EX_LAYERED = 0x80000;
    private const int WS_EX_TOOLWINDOW = 0x80;
    private const int WS_EX_NOACTIVATE = 0x8000000;

    [DllImport("user32.dll", SetLastError = true)]
    private static extern int GetWindowLong(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    private const uint MOD_CONTROL = 0x0002;
    private const uint MOD_ALT = 0x0001;
    private const int HOTKEY_TOGGLE = 9001;
    private const int HOTKEY_QUIT = 9002;
    private const int WM_HOTKEY = 0x0312;

    private readonly DispatcherTimer _timer = new();
    private string _telemetryPath = "";     // бустер
    private string _shipPath = "";          // корабль
    private long _lastBoosterTicks = -1;
    private long _lastShipTicks = -1;
    private bool _ready;

    public MainWindow()
    {
        InitializeComponent();

        Left = 0;
        Top = 0;
        Width = SystemParameters.PrimaryScreenWidth;
        Height = SystemParameters.PrimaryScreenHeight;

        _telemetryPath = ResolveTelemetryPath();
        // корабль пишет соседний файл в той же папке
        var dir = Path.GetDirectoryName(_telemetryPath) ?? "";
        _shipPath = Path.Combine(dir, "telemetry_ship.json");

        Loaded += OnLoaded;
        SourceInitialized += OnSourceInitialized;
        Closed += (_, _) => _timer.Stop();
    }

    /// <summary>
    /// Путь к telemetry.json: аргумент командной строки -> overlay.config.json рядом с exe -> дефолт.
    /// </summary>
    private static string ResolveTelemetryPath()
    {
        var args = Environment.GetCommandLineArgs();
        if (args.Length > 1 && !string.IsNullOrWhiteSpace(args[1]))
            return args[1];

        var cfg = Path.Combine(AppContext.BaseDirectory, "overlay.config.json");
        if (File.Exists(cfg))
        {
            try
            {
                using var doc = JsonDocument.Parse(File.ReadAllText(cfg));
                if (doc.RootElement.TryGetProperty("telemetryPath", out var p))
                {
                    var v = p.GetString();
                    if (!string.IsNullOrWhiteSpace(v)) return v!;
                }
            }
            catch { /* битый конфиг — просто идём на дефолт */ }
        }

        return @"M:\SteamLibrary\steamapps\common\Kerbal Space Program SOL\Ships\Script\telemetry.json";
    }

    private void OnSourceInitialized(object? sender, EventArgs e)
    {
        var hwnd = new WindowInteropHelper(this).Handle;

        // клики проходят насквозь в игру
        var ex = GetWindowLong(hwnd, GWL_EXSTYLE);
        // NOACTIVATE — окно никогда не забирает фокус у игры при появлении
        SetWindowLong(hwnd, GWL_EXSTYLE,
            ex | WS_EX_TRANSPARENT | WS_EX_LAYERED | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE);

        var src = HwndSource.FromHwnd(hwnd);
        src?.AddHook(WndProc);

        RegisterHotKey(hwnd, HOTKEY_TOGGLE, MOD_CONTROL | MOD_ALT, 0x4F); // Ctrl+Alt+O — показать/скрыть
        RegisterHotKey(hwnd, HOTKEY_QUIT, MOD_CONTROL | MOD_ALT, 0x51);   // Ctrl+Alt+Q — выход
    }

    private IntPtr WndProc(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
    {
        if (msg == WM_HOTKEY)
        {
            var id = wParam.ToInt32();
            if (id == HOTKEY_TOGGLE)
            {
                Visibility = Visibility == Visibility.Visible ? Visibility.Hidden : Visibility.Visible;
                handled = true;
            }
            else if (id == HOTKEY_QUIT)
            {
                UnregisterHotKey(hwnd, HOTKEY_TOGGLE);
                UnregisterHotKey(hwnd, HOTKEY_QUIT);
                handled = true;
                Close();
            }
        }
        return IntPtr.Zero;
    }

    private async void OnLoaded(object sender, RoutedEventArgs e)
    {
        // Папку данных WebView2 держим в LocalAppData, а не рядом с exe:
        // на сетевом/другом диске её создание может не пройти, и окно тогда
        // просто остаётся пустым без единого сообщения.
        var userData = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "KspOverlay", "WebView2");
        Directory.CreateDirectory(userData);

        try
        {
            var env = await Microsoft.Web.WebView2.Core.CoreWebView2Environment
                .CreateAsync(null, userData);
            await Web.EnsureCoreWebView2Async(env);
        }
        catch (Exception ex)
        {
            App.Log("WebView2: " + ex);
            MessageBox.Show(
                "Не удалось запустить WebView2.\n\n" + ex.Message +
                "\n\nЛог: " + App.LogPath,
                "KSP Overlay", MessageBoxButton.OK, MessageBoxImage.Error);
            Close();
            return;
        }
        Web.CoreWebView2.Settings.AreDefaultContextMenusEnabled = false;
        Web.CoreWebView2.Settings.AreDevToolsEnabled = true;
        Web.CoreWebView2.Settings.IsZoomControlEnabled = false;
        Web.CoreWebView2.Settings.IsStatusBarEnabled = false;

        var ui = Path.Combine(AppContext.BaseDirectory, "ui");
        Web.CoreWebView2.SetVirtualHostNameToFolderMapping(
            "overlay.local", ui, Microsoft.Web.WebView2.Core.CoreWebView2HostResourceAccessKind.Allow);
        Web.CoreWebView2.Navigate("https://overlay.local/index.html");

        Web.CoreWebView2.NavigationCompleted += (_, _) =>
        {
            _ready = true;
            PushPath();
            // Проявляем окно только когда страница отрисована. Иначе на старте
            // на секунду вылезает пустой прямоугольник во весь экран.
            // Именно Opacity, а не Visibility: Show() из StartupUri перебивает
            // Visibility="Hidden", заданный в XAML.
            Opacity = 1;
            App.Log("страница загружена, окно показано");
        };

        _timer.Interval = TimeSpan.FromMilliseconds(50);
        _timer.Tick += (_, _) => Poll();
        _timer.Start();
    }

    private void PushPath()
    {
        var payload = JsonSerializer.Serialize(new { kind = "path", path = _telemetryPath });
        Web.CoreWebView2.PostWebMessageAsString(payload);
    }

    /// <summary>
    /// Читаем telemetry.json, только если он реально изменился. kOS переписывает его
    /// ~10 раз в секунду, поэтому файл может быть занят — читаем с шарингом и не паникуем.
    /// </summary>
    private void Poll()
    {
        if (!_ready) return;
        PollOne(_telemetryPath, "booster", ref _lastBoosterTicks);
        PollOne(_shipPath, "ship", ref _lastShipTicks);
    }

    /// <summary>
    /// Читаем файл, только если он реально изменился. kOS переписывает его ~10 раз
    /// в секунду, поэтому он может быть занят — читаем с шарингом и молча пропускаем тик.
    /// </summary>
    private void PollOne(string path, string who, ref long lastTicks)
    {
        string json;
        try
        {
            var fi = new FileInfo(path);
            if (!fi.Exists) return;
            if (fi.LastWriteTimeUtc.Ticks == lastTicks) return;
            lastTicks = fi.LastWriteTimeUtc.Ticks;

            using var fs = new FileStream(path, FileMode.Open, FileAccess.Read,
                                          FileShare.ReadWrite | FileShare.Delete);
            using var sr = new StreamReader(fs);
            json = sr.ReadToEnd();
        }
        catch (IOException) { return; }              // переписывается прямо сейчас
        catch (UnauthorizedAccessException) { return; }

        if (string.IsNullOrWhiteSpace(json)) return;
        if (json.TrimStart()[0] != '{') return;      // поймали недописанный файл

        try { using var _ = JsonDocument.Parse(json); }
        catch (JsonException) { return; }            // не шлём в UI битый кадр

        Web.CoreWebView2.PostWebMessageAsString(
            "{\"kind\":\"telemetry\",\"who\":\"" + who + "\",\"data\":" + json + "}");
    }
}
