using System.IO;
using System.Threading;
using System.Windows;

namespace KspOverlay;

public partial class App : Application
{
    // Второй экземпляр молча падал: WebView2 держит папку своих данных, и новый
    // процесс не мог её создать. Теперь запуск один, а при повторном — понятное
    // сообщение вместо тишины.
    private static Mutex? _single;

    public static string LogPath =>
        Path.Combine(Path.GetTempPath(), "KspOverlay.log");

    protected override void OnStartup(StartupEventArgs e)
    {
        _single = new Mutex(true, @"Local\KspOverlaySingleInstance", out var isNew);
        if (!isNew)
        {
            MessageBox.Show(
                "KspOverlay уже запущен.\n\nCtrl+Alt+O — показать/спрятать, Ctrl+Alt+Q — выход.",
                "KSP Overlay", MessageBoxButton.OK, MessageBoxImage.Information);
            Shutdown();
            return;
        }

        // любую необработанную ошибку пишем в лог, иначе окно просто не появляется
        DispatcherUnhandledException += (_, args) =>
        {
            Log("UI: " + args.Exception);
            MessageBox.Show("Ошибка: " + args.Exception.Message + "\n\nПодробности: " + LogPath,
                            "KSP Overlay", MessageBoxButton.OK, MessageBoxImage.Error);
            args.Handled = true;
            Shutdown();
        };
        AppDomain.CurrentDomain.UnhandledException += (_, args) =>
            Log("domain: " + args.ExceptionObject);

        Log("запуск");
        base.OnStartup(e);
    }

    public static void Log(string msg)
    {
        try { File.AppendAllText(LogPath, $"{DateTime.Now:HH:mm:ss}  {msg}{Environment.NewLine}"); }
        catch { /* лог не критичен */ }
    }
}
