wait until ship:unpacked.
set Scriptversion to "V3.6.1_Dev".

//<------------Telemtry Scale-------------->

set TScale to 1.

// 720p     -   0.67
// 1080p    -   1
// 1440p    -   1.33
// 2160p    -   2
//_________________________________________

set MissionName to "".

set TFinstalled to false.
for engines in ship:engines {
    if engines:hasmodule("TestFlightCore") {set TFinstalled to true. break.}
}
print "TestFlight installed: "+TFinstalled.
wait 0.2.



if homeconnection:isconnected if exists("0:/settings.json") {
    set L to readjson("0:/settings.json").
    if L:haskey("MissionName") {
        set MissionName to L["MissionName"].
    }
}

if homeconnection:isconnected if exists("0:/settings.json") {
    set L to readjson("0:/settings.json").
    if L:haskey("highSplash") {
        set highSplash to L["highSplash"].
    }
    else set highSplash to false.
}
else set highSplash to false.

if homeconnection:isconnected if exists("0:/settings.json") {
    set L to readjson("0:/settings.json").
    if L:haskey("Bl3LndProf") {
        set Bl3LndProf to L["Bl3LndProf"].
    }
    else set Bl3LndProf to false.
}
else set Bl3LndProf to false.

if homeconnection:isconnected if exists("0:/settings.json") {
    set L to readjson("0:/settings.json").
    if L:haskey("TelemetryScale") {
        set TScale to L["TelemetryScale"].
    }
}

if homeconnection:isconnected {
    if config:arch {
        shutdown.
    }
    switch to 0.
    if exists("1:booster.ksm") {
        if homeconnection:isconnected {
            if open("0:booster.ks"):readall:string = open("1:/boot/booster.ks"):readall:string {}
            else {
                COMPILE "0:/booster.ks" TO "0:/booster.ksm".
                if homeconnection:isconnected {
                    copypath("0:booster.ks", "1:/boot/").
                    copypath("booster.ksm", "1:").
                    set core:BOOTFILENAME to "booster.ksm".
                    reboot.
                }
            }
        }
    }
    else {
        print "booster.ksm doesn't yet exist in boot.. creating..".
        COMPILE "0:/booster.ks" TO "0:/booster.ksm".
        copypath("0:booster.ks", "1:/boot/").
        copypath("booster.ksm", "1:").
        set core:BOOTFILENAME to "booster.ksm".
        reboot.
    }
}
    
set config:ipu to 800.

set devMode to true. // Disables switching to ship for easy quicksaving (@<0 vertical speed)
set LogData to true.   // полный лог полёта в 0:/BoosterFlightData.csv
set ShipType to "".
set BoosterType to "".
set Block3Cluster to false.
set HSRType to "".
set Depot to false.
set starship to "xxx".
set ShipFound to false.
set LandSomewhereElse to false.
set idealVS to 0.
set LatCtrl to 0.
set LngCtrl to 0.
set LngError to 0.
set LatError to 0.
set ErrorVector to vCrs(north:vector,up:vector)*24000.
set BoosterFueled to false.
set RandomFlip to false.
set GoForCatch to false.
set NrCounterEngine to list().
set missingCount to 0.
set inactiveCount to 0.
set GridfinLength to 0.
set RadarRatio to 5.
set ApproachAngle to 0.
set DumpVentNotCore to false.
set ClusterSet to false.
set CH4set to false.
set ResetNeeded to false.
set FNBBooster to false.
set DecelFactor to 1.
set PadB to false.

set GFset to false.
set ECset to false.
set BTset to false.
set HSset to false.
for part in ship:parts {
    if part:name:contains("SEP.25.BOOSTER.CORE") and not BTset {
        set BoosterType to "Block2".
        set BoosterCore to part.
        set bLOXTank to part.
        set bCH4Tank to part.
        set bCMNDome to part.
        set FWD to part.
        set DumpVents to list().
        set ModulesFound to false.
        set x to 0.
        until x > part:modules:length-1 or ModulesFound {
            if part:getmodulebyindex(x):name = "ModuleEnginesFX" {
                DumpVents:add(part:getmodulebyindex(x)).
                set ModulesFound to true.
                break.
            }
            set x to x+1.
        }
        set BTset to true.
        set SinglePartBooster to true.
    }
    if part:name:contains("SEP.26.BOOSTER.CORE") and not BTset {
        set BoosterType to "Block3".
        set BoosterCore to part.
        set bLOXTank to part.
        set bCH4Tank to part.
        set bCMNDome to part.
        set FWD to part.
        set HSR to part.
        set HSRType to "Block3".
        set RandomFlip to false.
        set DumpVents to list().
        set ModulesFound to false.
        set x to 0.
        until x > part:modules:length-1 or ModulesFound {
            if part:getmodulebyindex(x):name = "ModuleEnginesFX" {
                DumpVents:add(part:getmodulebyindex(x)).
                set ModulesFound to true.
                break.
            }
            set x to x+1.
        }
        set BTset to true.
        set SinglePartBooster to true.
    }
    if part:name:contains("FNB.BL3.BOOSTERLOX") and not BTset {
        set BoosterType to "Block3".
        set Bl3LndProf to true.
        set bLOXTank to part.
        if not ECset set BoosterEngines to ship:partsnamed("FNB.BL3.BOOSTERLOX").
        set BoosterCore to part.
        set DumpVents to list().
        set ModulesFound to false.
        set x to 0.
        when defined bCMNDome then {
            until x > bCMNDome:modules:length-1 or ModulesFound {
                if bCMNDome:getmodulebyindex(x):name = "ModuleEnginesFX" {
                    DumpVents:add(bCMNDome:getmodulebyindex(x)).
                    set ModulesFound to true.
                    break.
                }
                set x to x+1.
            }
        }
        set BTset to true.
        set SinglePartBooster to false.
    }
    if part:name:contains("FNB.BL3.BOOSTER") and not part:name:contains("HSR") and not part:name:contains("FIN") and not part:name:contains("CH4") and not part:name:contains("LOX") and not part:name:contains("CMN") {
        set BoosterType to "Block3".
        set bCH4Tank to part.
        set bCMNDome to part.
        set FWD to part.
        set bLOXTank to part.
        set BoosterCore to part.
        if not ECset set BoosterEngines to ship:partsnamed("FNB.BL3.BOOSTER").
        set BTset to true.
        set SinglePartBooster to true.
    }
    if part:name:contains("FNB.BL1.BOOSTERLOX") and not BTset {
        set BoosterType to "Block1".
        set Bl3LndProf to false.
        set bLOXTank to part.
        set BoosterCore to part.
        set DumpVentNotCore to true.
        when defined bCMNDome then {
            set DumpVents to list(False).
            set ModulesFound to false.
            set x to 0.
            until x > bCMNDome:modules:length-1 or ModulesFound {
                if bCMNDome:getmodulebyindex(x):name = "ModuleEnginesFX" {
                    DumpVents:add(bCMNDome:getmodulebyindex(x)).
                    set DumpVents[0] to bCMNDome:getmodulebyindex(x).
                    set ModulesFound to true.
                    break.
                }
                set x to x+1.
            }
        }
        set BTset to true.
        set SinglePartBooster to false.
    }
    if part:name:contains("FNB.BL3.BOOSTERCH4") {
        set bCH4Tank to part.
        set FWD to part.
    }
    if part:name:contains("FNB.BL3.BOOSTERCMN") {
        set bCMNDome to part.
    }
    if part:name:contains("FNB.BL1.BOOSTERCH4") {
        set bCH4Tank to part.
        set FWD to part.
        set CH4set to true.
    }
    if part:name:contains("FNB.BL1.BOOSTERCMN") {
        set bCMNDome to part.
    }
    if part:name:contains("SEP.23.BOOSTER.CLUSTER") and not ECset {
        set BoosterEngines to ship:partsnamed("SEP.23.BOOSTER.CLUSTER").
        set ECset to true.
    }
    if part:name:contains("SEP.25.BOOSTER.CLUSTER") and not ECset {
        set BoosterEngines to ship:partsnamed("SEP.25.BOOSTER.CLUSTER").
        set ECset to true.
    }
    if part:name:contains("SEP.26.BOOSTER.CLUSTER") and not ECset {
        set BoosterEngines to ship:partsnamed("SEP.26.BOOSTER.CLUSTER").
        set ECset to true.
        set Block3Cluster to true.
    }
    if part:name:contains("FNB.BL1.BOOSTERCLUSTER") and not ECset {
        set BoosterEngines to ship:partsnamed("FNB.BL1.BOOSTERCLUSTER").
        set ClusterSet to true.
        set ECset to true.
        set Block3Cluster to true.
    }
    if part:name:contains("FNB.R3.CLUSTER") and not ECset {
        set BoosterEngines to ship:partsnamed("FNB.R3.CLUSTER").
        set ECset to true.
        set Block3Cluster to true.
    }
    if part:name:contains("SEP.23.BOOSTER.GRIDFIN") and not GFset {
        set GridfinsType to "23".
        set GridfinLength to ship:partsnamed("SEP.23.BOOSTER.GRIDFIN"):length.
        set GridfinsName to "SEP.23.BOOSTER.GRIDFIN".
        set GFset to true.
    }
    if part:name:contains("SEP.25.BOOSTER.GRIDFIN") and not GFset {
        set GridfinsType to "25".
        set GridfinLength to ship:partsnamed("SEP.25.BOOSTER.GRIDFIN"):length.
        set GridfinsName to "SEP.25.BOOSTER.GRIDFIN".
        set GFset to true.
    }
    if part:name:contains("SEP.26.BOOSTER.GRIDFIN") and not GFset {
        set GridfinsType to "26".
        set GridfinLength to ship:partsnamed("SEP.26.BOOSTER.GRIDFIN"):length.
        set GridfinsName to "SEP.26.BOOSTER.GRIDFIN".
        set GFset to true.
    }
    if part:name:contains("FNB.BL3.BOOSTERFIN") and not GFset {
        set GridfinsType to "Block3".
        set GridfinLength to ship:partsnamed("FNB.BL3.BOOSTERFIN"):length.
        set GridfinsName to "FNB.BL3.BOOSTERFIN".
        set GFset to true.
    }
    if part:name:contains("FNB.BL3.GRIDFIN") and not GFset {
        set GridfinsType to "Block3".
        set GridfinLength to ship:partsnamed("FNB.BL3.GRIDFIN"):length.
        set GridfinsName to "FNB.BL3.GRIDFIN".
        set GFset to true.
    }
    if part:name:contains("FNB.BL1.BOOSTERGRIDFIN") and not GFset {
        set GridfinsType to "Block1".
        set GridfinLength to ship:partsnamed("FNB.BL1.BOOSTERGRIDFIN"):length.
        set GridfinsName to "FNB.BL1.BOOSTERGRIDFIN".
        set GFset to true.
    }
    if part:name:contains("SEP.23.BOOSTER.HSR") and not HSset {
        set HSRType to "Block0".
        set HSR to part.
        set HSset to true.
    }
    if part:name:contains("SEP.25.BOOSTER.HSR") and not HSset {
        set HSRType to "Block1/2".
        set HSR to part.
        set HSset to true.
    }
    if part:name:contains("VS.25.HSR.BL3") and not HSset {
        set HSRType to "Block3".
        set Bl3LndProf to true.
        set HSR to part.
        set HSset to true.
    }
    if (part:name:contains("FNB.BL3.BOOSTERIHSR") or part:name:contains("FNB.BL3.IHSR")) and not HSset {
        set HSRType to "Block3".
        set Bl3LndProf to true.
        set HSR to part.
        set HSset to true.
    }
    if part:name:contains("FNB.BL1.BOOSTERHSR") and not HSset {
        set HSRType to "Block1/2".
        set HSR to part.
        set HSset to true.
    }
    if part:name:contains("FNB") and part:name:contains("BOOSTER") {
        set FNBBooster to true.
    }
}

if defined HSR set HSRpartname to HSR:name.
else set HSRpartname to "keinHSRmontiert".

// Block 3 садится по профилю 13-5-3 всегда: это его штатный режим, а не опция.
// Раньше это включалось только внутри Boostback(), из-за чего до отделения
// (стат-прожиг, перезагрузка CPU, страница настроек) профиль числился выключенным.
if BoosterType:contains("Block3") set Bl3LndProf to true.

print GridfinLength.

if GridfinLength = 4 {
    set Gridfins to list("","","","").
    for fin in ship:partsnamed(GridfinsName) {
        if vAng(vxcl(facing:forevector, fin:position - BoosterCore:position), facing:topvector) < 90 and vAng(vxcl(facing:forevector, fin:position - BoosterCore:position), facing:starvector) < 90 {
            set Gridfins[0] to fin.
        }
        else if vAng(vxcl(facing:forevector, fin:position - BoosterCore:position), facing:topvector) > 90 and vAng(vxcl(facing:forevector, fin:position - BoosterCore:position), facing:starvector) < 90 {
            set Gridfins[1] to fin.
        }
        else if vAng(vxcl(facing:forevector, fin:position - BoosterCore:position), facing:topvector) > 90 and vAng(vxcl(facing:forevector, fin:position - BoosterCore:position), facing:starvector) > 90 {
            set Gridfins[2] to fin.
        }
        else if vAng(vxcl(facing:forevector, fin:position - BoosterCore:position), facing:topvector) < 90 and vAng(vxcl(facing:forevector, fin:position - BoosterCore:position), facing:starvector) > 90 {
            set Gridfins[3] to fin.
        }
    }
}
else if GridfinLength = 3 {
    set Gridfins to list("","","").
    for fin in ship:partsnamed(GridfinsName) {
        if vAng(vxcl(facing:forevector, fin:position - BoosterCore:position), -facing:topvector) < 60 {
            set Gridfins[0] to fin.
        }
        else if vAng(vxcl(facing:forevector, fin:position - BoosterCore:position), facing:starvector) < 60 {
            set Gridfins[1] to fin.
        }
        else if vAng(vxcl(facing:forevector, fin:position - BoosterCore:position), -facing:starvector) < 60 {
            set Gridfins[2] to fin.
        }
    } 
}
else set Gridfins to list("","").
set x to 0.
set missingFin to list().
set foundFin to list().
set FinIDs to list().
set AllFINIDs to list().
set foundFinPart to list().
set done to false.
for fins in ship:partsnamed(GridfinsName) {
    AllFINIDs:add(fins:uid).
}
for fin in Gridfins {
    if fin = "" {
        missingFin:add(x).
    } else {
        FinIDs:add(fin:uid).
    }
    set x to x+1.
}
when x = GridfinLength then set done to true.
wait until done.
if missingFin:length > 0 {
    for id in AllFINIDs {
        if FinIDs:contains(id) {}
        else {
            foundFin:add(id).
        }
    }
}
from {local m is 0.} until m=foundFin:length STEP {set m to m+1.} DO {
    for Finpart in ship:parts {
        if Finpart:uid = foundFin[m] foundFinPart:add(Finpart).
    }
}
from {local o is 0.} until o=foundFin:length STEP {set o to o+1.} DO {
    for n in missingFin {
        set Gridfins[n] to foundFinPart[o].
    }
}
print Gridfins.
wait 0.2.

set ShipTypeFound to false.
for part in ship:parts {
    if part:name:contains("SEP.23.SHIP.BODY") or part:name:contains("SEP.23.SHIP.DEPOT") or part:name:contains("SEP.24.SHIP.CORE") or part:name:contains("SEP.25.SHIP.CORE") or part:name:contains("SEP.26.SHIP.CORE") or part:name:contains("FNB.BL2.LOX") or part:name:contains("FNB.BL3.LOX") {
        set ShipTank to part.
        set ShipConnectedToBooster to true.
        set ShipTank:getmodule("kOSProcessor"):volume:name to "Starship".
    }
    if part:name:contains("OLM.B2") {
        set PadB to true.
    }
    if part:name:contains("VS.25.BL2") {
        set RandomFlip to false.
        set ShipType to "Block2".
        set ShipTypeFound to true.
    }
    else if part:name:contains("SEP.24.SHIP.FWD.RIGHT.FLAP") {
        set ShipType to "Block1".
        set RandomFlip to true.
        set ShipTypeFound to true.
    }
    else if part:name:contains("SEP.23.SHIP.FWD.RIGHT") {
        set ShipType to "Block0".
        set RandomFlip to true.
        set ShipTypeFound to true.
    }
    else if part:name:contains("FNB.BL2.LOX") {
        set RandomFlip to false.
        set ShipType to "Block2".
        set ShipTypeFound to true.
    }
    else if part:name:contains("FNB.BL3.LOX") {
        set RandomFlip to false.
        set ShipType to "Block3".
        set ShipTypeFound to true.
    }
    else if part:name:contains("SEP.25.SHIP.CORE") {
        set RandomFlip to false.
        set ShipType to "Block2".
        set ShipTypeFound to true.
    }
    else if part:name:contains("SEP.26.SHIP.CORE") {
        set RandomFlip to false.
        set ShipType to "Block3".
        set ShipTypeFound to true.
    }
    else if not ShipTypeFound set ShipType to "None".
}

set EnginesFound to false.
FindEngines().

function FindEngines {
    set findingEngines to true.
    if BoosterEngines[0]:children:length > 1 and ( BoosterEngines[0]:children[0]:name:contains("SEP.24.R1C") 
            or BoosterEngines[0]:children[0]:name:contains("SEP.23.RAPTOR2.SL.RC") or BoosterEngines[0]:children[0]:name:contains("SEP.23.RAPTOR2.SL.RB") 
            or BoosterEngines[0]:children[0]:name:contains("SEP.26.R3.SL.C") or BoosterEngines[0]:children[0]:name:contains("Raptor.3RB") 
            or BoosterEngines[0]:children[0]:name:contains("FNB.R3.CENTER") or BoosterEngines[0]:children[0]:name:contains("SEP.26.R3.SL.B") 
            or BoosterEngines[0]:children[1]:name:contains("SEP.24.R1C") or BoosterEngines[0]:children[1]:name:contains("SEP.23.RAPTOR2.SL.RC") or BoosterEngines[0]:children[1]:name:contains("SEP.23.RAPTOR2.SL.RB")
            or BoosterEngines[0]:children[1]:name:contains("SEP.26.R3.SL.C") or BoosterEngines[0]:children[1]:name:contains("SEP.26.R3.SL.B")
            or BoosterEngines[0]:children[1]:name:contains("FNB.R3.CENTER") or BoosterEngines[0]:children[1]:name:contains("FNB.R3.BOOSTER") or BoosterEngines[0]:children[0]:title:contains("Nagata") ) {
        set BoosterSingleEngines to true.
        set BoosterSingleEnginesRB to list().
        set BoosterSingleEnginesRC to list().
        set MissingList to list().
        set x to 1.
        until x > 33 {
            if ship:partstagged(x:tostring):length > 0 {
                if x < 14 BoosterSingleEnginesRC:insert(x-1,ship:partstagged(x:tostring)[0]).
                else BoosterSingleEnginesRB:insert(x-14,ship:partstagged(x:tostring)[0]).
            }
            else {
                if x < 14 BoosterSingleEnginesRC:insert(x-1, False). 
                else BoosterSingleEnginesRB:insert(x-14, False).
                MissingList:add(x).
            }
            print x.
            set x to x + 1.
        }
        if MissingList:length > 0 {
            print("The Booster is missing " + MissingList:length + " Engines!").
            if MissingList:length > 0 print MissingList.
        }
    } 
    else {
        print "No Single Engines Found".
        print BoosterEngines[0]:children:length.
        if BoosterEngines[0]:children:length > 1 print ( BoosterEngines[0]:children[0]:name:contains("SEP.24.R1C") 
            or BoosterEngines[0]:children[0]:name:contains("SEP.23.RAPTOR2.SL.RC") or BoosterEngines[0]:children[0]:name:contains("SEP.23.RAPTOR2.SL.RB") 
            or BoosterEngines[0]:children[0]:name:contains("SEP.26.R3.SL.C") or BoosterEngines[0]:children[0]:name:contains("SEP.26.R3.SL.B") 
            or BoosterEngines[0]:children[0]:name:contains("FNB.R3.CENTER") or BoosterEngines[0]:children[0]:name:contains("FNB.R3.BOOSTER") 
            or BoosterEngines[0]:children[1]:name:contains("SEP.24.R1C") or BoosterEngines[0]:children[1]:name:contains("SEP.23.RAPTOR2.SL.RC") or BoosterEngines[0]:children[1]:name:contains("SEP.23.RAPTOR2.SL.RB")
            or BoosterEngines[0]:children[1]:name:contains("SEP.26.R3.SL.C") or BoosterEngines[0]:children[1]:name:contains("SEP.26.R3.SL.B")
            or BoosterEngines[0]:children[1]:name:contains("FNB.R3.CENTER") or BoosterEngines[0]:children[1]:name:contains("FNB.R3.BOOSTER") ).
        set BoosterSingleEngines to false.
    }
    set findingEngines to false.
    set EnginesFound to true.
}


set ModulesFound to false.
when EnginesFound then {
    if not BoosterSingleEngines {
        set x to 0.
        until x > BoosterEngines[0]:modules:length - 1 {
            set GimbMod to BoosterEngines[0]:getmodulebyindex(x).
            if GimbMod:name = "ModuleGimbal" {
                if GimbMod:gethiddenfield("gimbaltransformname") = "GimbalCore" or GimbMod:gethiddenfield("gimbaltransformname") = "Core" or GimbMod:gethiddenfield("gimbaltransformname") = "Gimbal_Center_Three" or GimbMod:gethiddenfield("gimbaltransformname") = "GimbalCenter"
                    set CtrGimbMod to GimbMod.
                else if GimbMod:gethiddenfield("gimbaltransformname") = "Gimbal2Inner" or GimbMod:gethiddenfield("gimbaltransformname") = "2Inner" or GimbMod:gethiddenfield("gimbaltransformname") = "Gimbal2" or GimbMod:gethiddenfield("gimbaltransformname") = "Gimbal_Middle_Two"
                    set Mid2GimbMod to GimbMod.
                else if GimbMod:gethiddenfield("gimbaltransformname") = "GimbalInner" or GimbMod:gethiddenfield("gimbaltransformname") = "Inner" or GimbMod:gethiddenfield("gimbaltransformname") = "Gimbal" or GimbMod:gethiddenfield("gimbaltransformname") = "Gimbal_Middle_Eight"
                    set MidGimbMod to GimbMod.
            }
            set x to x + 1.
        }
    }
    if defined CtrGimbMod {} else set CtrGimbMod to false.
    if defined Mid2GimbMod {} else set Mid2GimbMod to false.
    if defined MidGimbMod {} else set MidGimbMod to false.
}

wait until EnginesFound.
set InitialError to -9999.
set maxDecel to 0.00001.
set TotalstopTime to 0.
set TotalstopDist to 0.
set stopDist3 to 0.
set landingRatio to 0.
set GS to 0.
set BoostBackComplete to false.
set lastVesselChange to time:seconds.
set LandingBurnStarted to false.
set BoosterHeight to 0.
set stopTime9 to 0.
set TimeStabilized to 0.
set LFBooster to 0.
set LFBoosterCap to 0.
set LiftingPointToGridFinDist to 0.
set MiddleEnginesShutdown to false.
set StarshipExists to false.
set TowerExists to false.
set TargetOLM to false.
set BoosterDocked to false.
set QuickSaveLoaded to false.
set ShipNotFound to false.
set RollAngle to 0.
set missionTimer to 0.
set BoosterRot to 0.
if BoosterCore:hasmodule("FARPartModule") {
    set FAR to true.
}
else {
    set FAR to false.
}
set FailureMessage to false.
set hover to false.

set RSS to false.
set KSRSS to false.
set STOCK to false.
set Rescale to false.
set Planet1G to CONSTANT():G * (ship:body:mass / (ship:body:radius * ship:body:radius)).
set Block1 to false.
set Block1HSR to false.
set VentCutOff to false.
set command to "".
set parameter1 to "".
set GF to false.
set GFnoGO to false.
set GE to false.
set GG to false.
set GT to false.
set GTn to false.
set GD to true.
set GfC to false.
set FC to false.
set EC to false.
set PollTimer to 999.
set HSRJet to false.
set flipStartTime to -2.
set PurePitchFlip to false.
set FlipRampActive to false.
set FlipCmdAngle to 0.
set FlipTotalAngle to 0.
set SteeringVector to ship:facing.
set VentAllowed to false.
// Внешний оверлей включён -> встроенный HUD kOS не показываем, чтобы не
// накладывался. Кнопки опроса Go/NoGo (bGUI) остаются, они нужны.
set UseOverlay to true.
set OverlayTimer to 0.
set ActiveRC to 0.
set ActiveRB to 0.
// Тяга ОДНОГО двигателя, измеренная у игры на текущей высоте, кН.
// RaptorMeasured - сырой замер (идёт в лог всегда), RaptorThrustLive - принятое
// в модель значение (0 = ещё не мерили, тогда работает старая константа).
// Насколько точно бустер должен довести нос на цель, прежде чем даём ПОЛНУЮ
// связку на буст-бэке, градусы. Полная тяга поперёк оси заваливает тангаж под
// горизонт (Егор видел pitch до -10), поэтому зажигаем только когда корпус уже
// пришёл. История допуска: сток 110 (то есть "куда угодно") -> 30 -> 15.
// Нужно ещё позже - уменьшать это число; страховка по времени ниже не тронута.
set FullThrustAngle to 15.
// Доля высоты бустера, на которой руки получают команду на полный захват.
// История: сток 0.04 (меньше секунды до касания, руки не успевали), 0.12
// (руки смыкались, пока пины были в пяти метрах над ними), 0.06.
//
// Теперь 0.8, то есть около 33 м. На этой высоте между руками проходит узкий
// двигательный отсек, а решётчатые рули ещё в сорока метрах выше - закрывать
// уже можно, и у башни появляется несколько секунд вместо полусекунды.
// Удар 19:03 был не рулями: там створ 2.75 совпал с промахом 4 м, и бустер
// пришёл на верх руки сбоку. Значит опасна не высота, а закрытие при
// БОКОВОМ промахе - от этого страхует ArmCloseMaxOffset ниже.
set ArmCloseRatio to 0.8.
// Горизонтальное смещение бустера от точки посадки, при котором захват ещё
// разрешён. Больше - держим створ открытым и ждём: сомкнуть руки под
// сместившимся бустером означает поймать его боком за руку.
set ArmCloseMaxOffset to 4.
// Створ, который выставляем перед захватом. Поле "arms open angle" в модуле
// башни НЕ ОПУСКАЕТСЯ НИЖЕ 5 - ноль там просто клампится, и на панели остаётся
// 5.0. Полное смыкание делает не это поле, а действие "close arms".
// Поэтому: полем доводим до минимума, а закрываем кнопкой.
set ArmGripAngle to 5.
// Команда захвата уходит РОВНО ОДИН РАЗ. После неё руки закрыты, и любая
// следующая MechazillaArms с "true" их снова РАСКРОЕТ: ветка "true" в
// tower.ks дёргает toggle, когда у модуля есть событие "open arms", а после
// смыкания оно как раз появляется.
set ArmsCloseSent to false.
// CatchPos присваивается только внутри LandingGuidance. Условие отправки
// захвата её читает, а живёт оно в триггере по высоте - если триггер успеет
// раньше первого вызова наведения, kOS упадёт на неопределённой переменной.
// Нулевой вектор здесь даёт заведомо большой промах, то есть захват просто
// не уйдёт этим кадром - безопасный отказ вместо аварии.
set CatchPos to v(0,0,0).
// Куда именно целиться внутри рук. Сток бил в точку со смещением 1.2 м
// вдоль оси башни - по факту бустер садился на самый край палок.
// CatchOffsetAlong - глубже В башню (плюс = дальше от края).
// CatchOffsetSide  - поперёк палок, плюс = вправо от оси башни.
// Смещение точки прицеливания В СТОРОНУ БАШНИ, в единицах Scale^0.6 метра.
// Сток 1.2 - бустер садился заметно далеко от башни.
//
// ВАЖНО про измерение: по колонке TgtAlong эффект НЕ ВИДЕН и видно его не
// будет. TargetError входит в само наведение (GuidVec рулит на его
// обнуление), то есть контур замкнут: сдвигаешь CatchPos - вместе с ней
// едет и бустер, а остаточная ошибка слежения остаётся прежней. Раньше я
// из этого ошибочно заключил, что смещение вообще не работает - неверно,
// просто мерил не той величиной. Проверять глазами, где он реально сел.
set CatchOffsetAlong to 3.0.
set CatchOffsetSide to 0.
// Высота, с которой башня начинает доворачиваться под бустер. Сток - 240 м:
// поворот начинался фактически в последний момент.
set ArmRotAlt to 600.
// Последний зафиксированный угол поворота башни (см. GetBoosterRotation).
set RotLatched to false.
set RotLatchValue to 0.
// Скорость изменения угла и предыдущий замер - для экстраполяции в момент
// защёлки. Без них башня встаёт туда, где бустер БЫЛ.
set RotPrevAngle to 0.
set RotPrevTime to 0.
set RotRate to 0.
set RaptorMeasured to 0.
set RaptorThrustLive to 0.
// Момент РЕАЛЬНОГО касания. LandingTime ставится сильно позже - после дотяга
// тяги, ожидания затухания и выключения двигателей, а если скрипт до туда не
// дошёл, то не ставится вовсе (в логах так и было: EvLand = -1).
set TouchdownTime to 0.
// Ставятся триггером в момент отрыва. Инициализация нужна: телеметрия шлёт их
// каждый кадр, в том числе до старта, а round() от необъявленной переменной
// роняет весь писатель телеметрии.
set LiftoffMass to 0.
set LiftoffTWR to 0.
set EngMask to "".
set EngGeom to "".
// Порог, выше которого доворот по крену считается ложным и запрещается,
// и порог возврата управления. Значения зависят от фазы, см. SteeringCorrections:
// на буст-бэке жёстко (20/12) - там доворот только раскручивает корпус,
// на планировании мягко (150/135) - там ошибка настоящая и её надо убирать.
set MaxRollFix to 20.
set RollFixReturn to 12.
set RollRangeNormal to 3.
set RollRangeSaved to 3.
set Mode to "".
set MidStageDone to false.
set RollFrozen to false.
set RollNote to "".
set oPhase to "idle".
set PrevLogTime to 0.
set OxBooster to 0.
set OxBoosterCap to 1.
set LFdensity to 0.
set LandingReserveUnits to 10500.
// Пост-посадочные операции башни (стабилизаторы/толкатели/стыковка на OLM)
// отключены: они сбрасывают пойманный бустер. Ловля на этом не заканчивается -
// бустер просто остаётся висеть в палочках. Включить обратно = поставить true.
set RecoveryEnabled to false.
set cAbort to false.
set oldArms to false.
list targets in shiplist.
set BoosterLanded to false.
set Tminus to false.
set Rotating to false.
set WobblyBooster to false.
set TowerRotationVector to -vCrs(north:vector,up:vector).
set RollVector to vCrs(north:vector,up:vector).
set PositionError to RollVector.
set varR to 0.
set varPredct to 0.
set angle to 75.
set speed to 10.
set HighIncl to false.
set landDistance to 500.
set angleToTarget to 0.
set LandingVector to up:vector.
set TheTowerHeadingVector to vCrs(up:vector, north:vector).
set SteeringUpdateTime to 0.
set FlipTime to 0.
set CounterEngine to false.
set LandingBurnEC to false.
set Idle to true.
set offshoreDivert to false.
set AllSet to false.
set AllOnce to false.
set fullAuto to false.
set LZchange to false.
set BoosterStaticFireRunning to false.
set TMinusCountdown to 17.
set rebooted to false.
set HighLandingBurn to false.
set downToThree to false.
set HighAngleVec to facing:forevector.
set haVstrength to 0.
set MidShutdownSpeed to 69.
set TargetMidShutdown to 300.

if TFinstalled {
    set BBIgn to 100.
    set LBIgnC to 100.
    set LBIgnM to 100.
    set ifIgn to 0.
}
else {
    set BBIgn to 98.
    set LBIgnC to 98.
    set LBIgnM to 98.
    set ifIgn to 0.1.
}
local bTelemetry is GUI(150).
    set bTelemetry:style:bg to "starship_img/telemetry_bg".
    set bTelemetry:skin:label:textcolor to white.
    set bTelemetry:skin:textfield:textcolor to white.
    set bTelemetry:skin:label:font to "Arial Bold".
    set bTelemetry:skin:textfield:font to "Arial Bold".
local bAttitudeTelemetry is bTelemetry:addhlayout().
local GDlamp is bAttitudeTelemetry:addlabel().
    set GDlamp:style:bg to "starship_img/telemetry_fuel".
local boosterCluster is bAttitudeTelemetry:addvlayout().
local boosterStatus is bAttitudeTelemetry:addvlayout().
local boosterAttitude is bAttitudeTelemetry:addvlayout().
local missionTimeDisplay is bAttitudeTelemetry:addvlayout().
local shipSpace is bAttitudeTelemetry:addvlayout().
local EngBG is boosterCluster:addlabel(). 
    set EngBG:style:bg to "starship_img/EngPicBooster/zero".
    if BoosterType:contains("Block3") set EngBG:style:bg to "starship_img/EngPicBooster3/zero".
local Eng1 is boosterCluster:addlabel().
local Eng2 is boosterCluster:addlabel().
local Eng3 is boosterCluster:addlabel().
local Eng4 is boosterCluster:addlabel().
local Eng5 is boosterCluster:addlabel().
local Eng6 is boosterCluster:addlabel().
local Eng7 is boosterCluster:addlabel().
local Eng8 is boosterCluster:addlabel().
local Eng9 is boosterCluster:addlabel().
local Eng10 is boosterCluster:addlabel().
local Eng11 is boosterCluster:addlabel().
local Eng12 is boosterCluster:addlabel().
local Eng13 is boosterCluster:addlabel().
local Eng14 is boosterCluster:addlabel().
local Eng15 is boosterCluster:addlabel().
local Eng16 is boosterCluster:addlabel().
local Eng17 is boosterCluster:addlabel().
local Eng18 is boosterCluster:addlabel().
local Eng19 is boosterCluster:addlabel().
local Eng20 is boosterCluster:addlabel().
local Eng21 is boosterCluster:addlabel().
local Eng22 is boosterCluster:addlabel().
local Eng23 is boosterCluster:addlabel().
local Eng24 is boosterCluster:addlabel().
local Eng25 is boosterCluster:addlabel().
local Eng26 is boosterCluster:addlabel().
local Eng27 is boosterCluster:addlabel().
local Eng28 is boosterCluster:addlabel().
local Eng29 is boosterCluster:addlabel().
local Eng30 is boosterCluster:addlabel().
local Eng31 is boosterCluster:addlabel().
local Eng32 is boosterCluster:addlabel().
local Eng33 is boosterCluster:addlabel().
set EngClusterDisplay to List(Eng1, Eng2, Eng3, Eng4, Eng5, Eng6, Eng7, Eng8, Eng9, Eng10, Eng11, Eng12, Eng13, 
            Eng14, Eng15, Eng16, Eng17, Eng18, Eng19, Eng20, Eng21, Eng22, Eng23, Eng24, Eng25, Eng26, Eng27, Eng28, Eng29, Eng30, Eng31, Eng32, Eng33).
for lbl in EngClusterDisplay {
    set lbl:style:bg to "starship_img/EngPicBooster/0".
}
local bSpeed is boosterStatus:addlabel("<b>SPEED  </b>").
    set bSpeed:style:wordwrap to false.
local bAltitude is boosterStatus:addlabel("<b>ALTITUDE  </b>").
    set bAltitude:style:wordwrap to false.

local bLOX is boosterStatus:addhlayout().
local bLOXLabel is bLOX:addlabel("<b>LOX  </b>").
    set bLOXLabel:style:wordwrap to false.
local bLOXBorder is bLOX:addlabel("").
    set bLOXBorder:style:align to "CENTER".
    set bLOXBorder:style:bg to "starship_img/telemetry_fuel_bg".
local bLOXSlider is bLOX:addlabel().
    set bLOXSlider:style:align to "CENTER".
    set bLOXSlider:style:bg to "starship_img/telemetry_fuel".
local bLOXNumber is bLOX:addlabel("100%").
    set bLOXNumber:style:wordwrap to false.
    set bLOXNumber:style:align to "LEFT".

local bCH4 is boosterStatus:addhlayout().
local bCH4Label is bCH4:addlabel("<b>CH4  </b>").
    set bCH4Label:style:wordwrap to false.
local bCH4Border is bCH4:addlabel("").
    set bCH4Border:style:align to "CENTER".
    set bCH4Border:style:bg to "starship_img/telemetry_fuel_bg".
local bCH4Slider is bCH4:addlabel().
    set bCH4Slider:style:align to "CENTER".
    set bCH4Slider:style:bg to "starship_img/telemetry_fuel".
local bCH4Number is bCH4:addlabel("100%").
    set bCH4Number:style:wordwrap to false.
    set bCH4Number:style:align to "LEFT".

local bThrust is boosterStatus:addlabel("<b>THRUST  </b>").
local bAttitude is boosterAttitude:addlabel().
    set bAttitude:style:bg to "starship_img/booster/0".
local missionTimeLabel is missionTimeDisplay:addlabel().
local ClockHeader is missionTimeDisplay:addlabel().
    set ClockHeader:style:align to "center".
    set ClockHeader:text to MissionName.

local VersionDisplay is GUI(100).
    local VersionDisplayLabel is VersionDisplay:addlabel().
        set VersionDisplayLabel:style:align to "center".
        set VersionDisplayLabel:text to Scriptversion.
if not UseOverlay VersionDisplay:show().
local shipBackground is shipSpace:addlabel().



set bTelemetry:draggable to false.


local bGUI is GUI(150).
    set bGUI:style:bg to "starship_img/telemetry_bg".
    set bGUI:style:padding:v to 0.
    set bGUI:style:padding:h to 0.
    set bGUI:x to 0.
    set bGUI:skin:button:bg to  "starship_img/telemetry_bg".
    set bGUI:skin:button:on:bg to  "starship_img/starship_background_light".
    set bGUI:skin:button:hover:bg to  "starship_img/starship_background_light".
    set bGUI:skin:button:hover_on:bg to  "starship_img/starship_background_light".
    set bGUI:skin:button:textcolor to white.
    set bGUI:skin:label:textcolor to white.
    set bGUI:skin:textfield:textcolor to white.

local bGUIBox is bGUI:addhlayout().

local PollGUI is bGUIBox:addvlayout().
    
local leftright is PollGUI:addhlayout().
local GoNoGoPoll is leftright:addvlayout().
    set GoNoGoPoll:style:bg to "starship_img/starship_background_dark".
local Space is leftright:addvlayout().
local FDDecision is leftright:addvlayout().
local Space2 is leftright:addvlayout().

local spaceLabel is Space:addlabel("").
local spaceLabel2 is Space2:addlabel("").

local data1 is GoNoGoPoll:addlabel("Tower: ").
    set data1:style:wordwrap to false.
local Vehicle1 is GoNoGoPoll:addhlayout().
local data2 is Vehicle1:addlabel("Engines: ").
    set data2:style:wordwrap to false.
local data25 is Vehicle1:addlabel("Fuel: ").
    set data25:style:wordwrap to false.
local Vehicle2 is GoNoGoPoll:addhlayout().
local data3 is Vehicle2:addlabel("Gridfins: ").
    set data3:style:wordwrap to false.
local data35 is Vehicle2:addlabel("Tanks: ").
    set data35:style:wordwrap to false.
local data4 is GoNoGoPoll:addlabel("Flight Director: ").
    set data4:style:wordwrap to false.
local message0 is FDDecision:addlabel("<b>Flight Director:</b>").
    set message0:style:wordwrap to false.
local message1 is FDDecision:addlabel("<color=yellow>Go for Catch?</color>").
    set message1:style:wordwrap to false.
local buttonbox is FDDecision:addhlayout().
local Go to buttonbox:addbutton("<b><color=green>Confirm</color></b>").
    set Go:style:bg to "starship_img/starship_background_dark".
local NoGo to buttonbox:addbutton("<b><color=red>Deny</color></b>").
    set NoGo:style:bg to "starship_img/starship_background_dark".
local message4 is GoNoGoPoll:addlabel("Current decision: ").
    set message4:style:wordwrap to false.
local message3 is FDDecision:addlabel("Poll ending in: ??s").
    set message3:style:wordwrap to false.


CreateTelemetry().


function CreateTelemetry {
    
    set bGUI:style:border:h to 10*TScale.
    set bGUI:style:border:v to 10*TScale.
    set bGUI:y to -382*TScale.
    set bGUI:skin:button:border:v to 10*TScale.
    set bGUI:skin:button:border:h to 10*TScale.

    set spaceLabel:style:width to 10*TScale.
    set spaceLabel2:style:width to 8*TScale.

    set data1:style:margin:left to 10*TScale.
    set data1:style:margin:top to 10*TScale.
    set data1:style:width to 230*TScale.
    set data1:style:fontsize to 16*TScale.

    set data2:style:margin:left to 10*TScale.
    set data2:style:width to 115*TScale.
    set data2:style:fontsize to 16*TScale.

    set data25:style:margin:left to 10*TScale.
    set data25:style:width to 115*TScale.
    set data25:style:fontsize to 16*TScale.

    set data3:style:margin:left to 10*TScale.
    set data3:style:width to 115*TScale.
    set data3:style:fontsize to 16*TScale.

    set data35:style:margin:left to 10*TScale.
    set data35:style:width to 115*TScale.
    set data35:style:fontsize to 16*TScale.

    set data4:style:margin:left to 10*TScale.
    set data4:style:width to 230*TScale.
    set data4:style:fontsize to 16*TScale.

    set message0:style:margin:left to 10*TScale.
    set message0:style:margin:top to 15*TScale.
    set message0:style:width to 200*TScale.
    set message0:style:fontsize to 21*TScale.

    set message1:style:margin:left to 10*TScale.
    set message1:style:margin:top to 25*TScale.
    set message1:style:width to 200*TScale.
    set message1:style:fontsize to 21*TScale.

    set Go:style:width to 100*TScale.
    set Go:style:border:h to 10*(TScale^0.6).
    set Go:style:border:v to 10*(TScale^0.6).
    set Go:style:fontsize to 18*TScale.

    set NoGo:style:width to 100*TScale.
    set NoGo:style:border:h to 10*(TScale^0.6).
    set NoGo:style:border:v to 10*(TScale^0.6).
    set NoGo:style:fontsize to 18*TScale.

    set message4:style:margin:left to 10*TScale.
    set message4:style:margin:top to 10*TScale.
    set message4:style:width to 230*TScale.
    set message4:style:fontsize to 16*TScale.

    set message3:style:margin:left to 10*TScale.
    set message3:style:margin:top to 10*TScale.
    set message3:style:width to 200*TScale.
    set message3:style:fontsize to 18*TScale.

//--------------

    set bTelemetry:style:border:h to 10*TScale.
    set bTelemetry:style:border:v to 10*TScale.
    set bTelemetry:style:padding:v to 0.
    set bTelemetry:style:padding:h to 0.
    set bTelemetry:x to 0.
    set bTelemetry:y to -200*TScale.
    
    set GDlamp:style:margin:top to 170*TScale.
    set GDlamp:style:margin:left to 0.
    set GDlamp:style:width to 0.
    set GDlamp:style:height to 0.
    set GDlamp:style:overflow:left to -10*TScale.
    set GDlamp:style:overflow:right to 20*TScale.
    set GDlamp:style:overflow:top to 0*TScale.
    set GDlamp:style:overflow:bottom to -25*TScale.

    set overflow to 0.
    set EngBG:style:width to floor(180*TScale).
    set EngBG:style:height to floor(180*TScale).
    set EngBG:style:margin:top to ceiling(12*TScale).
    set EngBG:style:margin:left to 19*TScale.
    set EngBG:style:margin:right to ceiling(20*TScale).
    set EngBG:style:overflow:top to overflow.
    set EngBG:style:overflow:bottom to -overflow.
    set overflow to overflow + floor(192*TScale).
    for engLbl in EngClusterDisplay {
        set engLbl:style:width to floor(180*TScale).
        set engLbl:style:height to floor(180*TScale).
        set engLbl:style:margin:top to ceiling(12*TScale).
        set engLbl:style:margin:left to 19*TScale.
        set engLbl:style:margin:right to ceiling(20*TScale).
        set engLbl:style:overflow:top to overflow.
        set engLbl:style:overflow:bottom to -overflow.
        set overflow to overflow + floor(192*TScale).
    }

    set bSpeed:style:margin:left to 10*TScale.
    set bSpeed:style:margin:top to 14*TScale.
    set bSpeed:style:width to 296*TScale.
    set bSpeed:style:fontsize to 28*TScale.

    set bAltitude:style:margin:left to 10*TScale.
    set bAltitude:style:margin:top to 2*TScale.
    set bAltitude:style:width to 296*TScale.
    set bAltitude:style:fontsize to 28*TScale.

    set bLOXLabel:style:margin:left to 15*TScale.
    set bLOXLabel:style:margin:top to 10*TScale.
    set bLOXLabel:style:width to 60*TScale.
    set bLOXLabel:style:fontsize to 18*TScale.

    set bLOXBorder:style:margin:left to 0*TScale.
    set bLOXBorder:style:margin:top to 18*TScale.
    set bLOXBorder:style:width to 190*TScale.
    set bLOXBorder:style:height to 8*TScale.
    set bLOXBorder:style:border:h to 4*(TScale^0.6).
    set bLOXBorder:style:border:v to 0*TScale.
    set bLOXBorder:style:overflow:left to 0*TScale.
    set bLOXBorder:style:overflow:right to 8*TScale.
    set bLOXBorder:style:overflow:bottom to 1*TScale.

    set bLOXSlider:style:margin:left to 0*TScale.
    set bLOXSlider:style:margin:top to 18*TScale.
    set bLOXSlider:style:width to 0*TScale.
    set bLOXSlider:style:height to 8*TScale.
    set bLOXSlider:style:border:h to 4*(TScale^0.6).
    set bLOXSlider:style:border:v to 0*TScale.
    set bLOXSlider:style:overflow:left to 200*TScale.
    set bLOXSlider:style:overflow:right to 0*TScale.
    set bLOXSlider:style:overflow:bottom to 1*TScale.

    set bLOXNumber:style:padding:left to 0*TScale.
    set bLOXNumber:style:margin:left to 10*TScale.
    set bLOXNumber:style:margin:top to 12*TScale.
    set bLOXNumber:style:width to 20*TScale.
    set bLOXNumber:style:fontsize to 12*TScale.
    set bLOXNumber:style:overflow:left to 80*TScale.
    set bLOXNumber:style:overflow:right to 0*TScale.
    set bLOXNumber:style:overflow:bottom to 0*TScale.

    set bCH4Label:style:margin:left to 15*TScale.
    set bCH4Label:style:margin:top to 4*TScale.
    set bCH4Label:style:width to 60*TScale.
    set bCH4Label:style:fontsize to 18*TScale.

    set bCH4Border:style:margin:left to 0*TScale.
    set bCH4Border:style:margin:top to 13*TScale.
    set bCH4Border:style:width to 190*TScale.
    set bCH4Border:style:height to 8*TScale.
    set bCH4Border:style:border:h to 4*(TScale^0.6).
    set bCH4Border:style:border:v to 0*TScale.
    set bCH4Border:style:overflow:left to 0*TScale.
    set bCH4Border:style:overflow:right to 8*TScale.
    set bCH4Border:style:overflow:bottom to 1*TScale.

    set bCH4Slider:style:margin:left to 0*TScale.
    set bCH4Slider:style:margin:top to 13*TScale.
    set bCH4Slider:style:width to 0*TScale.
    set bCH4Slider:style:height to 8*TScale.
    set bCH4Slider:style:border:h to 4*(TScale^0.6).
    set bCH4Slider:style:border:v to 0*TScale.
    set bCH4Slider:style:overflow:left to 200*TScale.
    set bCH4Slider:style:overflow:right to 0*TScale.
    set bCH4Slider:style:overflow:bottom to 1*TScale.

    set bCH4Number:style:padding:left to 0*TScale.
    set bCH4Number:style:margin:left to 10*TScale.
    set bCH4Number:style:margin:top to 7*TScale.
    set bCH4Number:style:width to 20*TScale.
    set bCH4Number:style:fontsize to 12*TScale.
    set bCH4Number:style:overflow:left to 80*TScale.
    set bCH4Number:style:overflow:right to 0*TScale.
    set bCH4Number:style:overflow:bottom to 0*TScale.

     set bThrust:style:wordwrap to false.
     set bThrust:style:margin:left to 10*TScale.
     set bThrust:style:margin:top to 10*TScale.
     set bThrust:style:width to 150*TScale.
     set bThrust:style:fontsize to 14*TScale.

    set bAttitude:style:margin:left to 20*TScale.
    set bAttitude:style:margin:right to 20*TScale.
    set bAttitude:style:width to 170*TScale.
    set bAttitude:style:height to 170*TScale.
    set bAttitude:style:margin:top to 12*TScale.

    set missionTimeLabel:style:wordwrap to false.
    set missionTimeLabel:style:margin:left to 140*TScale.
    set missionTimeLabel:style:margin:right to 160*TScale.
    set missionTimeLabel:style:margin:top to 60*TScale.
    set missionTimeLabel:style:width to 160*TScale.
    set missionTimeLabel:style:fontsize to 42*TScale.
    set missionTimeLabel:style:align to "center".

    set ClockHeader:style:wordwrap to false.
    set ClockHeader:style:margin:left to 140*TScale.
    set ClockHeader:style:margin:right to 160*TScale.
    set ClockHeader:style:margin:top to 10*TScale.
    set ClockHeader:style:width to 160*TScale.
    set ClockHeader:style:fontsize to 24*TScale.

    set VersionDisplay:x to 0.
    set VersionDisplay:y to 25*TScale.
    set VersionDisplay:style:bg to "".
        set VersionDisplayLabel:style:wordwrap to false.
        set VersionDisplayLabel:style:width to 100*TScale.
        set VersionDisplayLabel:style:fontsize to 12*TScale.

    set shipBackground:style:width to 944*TScale.
}


set Go:onclick to {
    set GD to true.
}.
set NoGo:onclick to {
    set GD to false.
}.

if bodyexists("Earth") {
    if body("Earth"):radius > 1600000 {
        set RSS to true.
        set Planet to "Earth".
        set LaunchSites to lexicon("KSC", "28.549072,-80.655925").
        set offshoreSite to latlng(28.549,-80.5).
        set BoosterHeight to 70.6.
        set LiftingPointToGridFinDist to 4.5.
        set LFBoosterFuelCutOff to 12000.
        if not BoosterSingleEngines set LFBoosterFuelCutOff to 15000.
        if FAR {
            set LngCtrlPID to PIDLOOP(0.35, 0.45, 0.27, -10, 10).
        }
        else {
            set LngCtrlPID to PIDLOOP(0.35, 0.3, 0.27, -10, 10).
        }
        set BoosterGlideDistance to 2800. //2400 
        if BoosterSingleEngines set BoosterGlideDistance to BoosterGlideDistance * 1.07.
        set BoosterGlideFactor to 1.05.
        set VelCancelFactor to 1.
        set LngCtrlPID:setpoint to 20. //24
        set LatCtrlPID to PIDLOOP(0.25, 0.2, 0.15, -5, 5).
        set RollVector to heading(270,0):vector.
        set BoosterReturnMass to 200.
        set BoosterRaptorThrust to 2220.
        set BoosterRaptorThrust3 to 2230.
        if Block3Cluster or BoosterType:contains("Block3") {
            set BoosterRaptorThrust to 2500.
            set BoosterRaptorThrust3 to 2510.
        }
        set Scale to 1.6.
        set CorrFactor to 0.7.
        set PIDFactor to 24.
        set CatchVS to -0.5.
        set FinalDeceleration to 9.
    }
    else {
        set KSRSS to true.
        set Planet to "Earth".
        set LaunchSites to lexicon("KSC", "28.50895,-81.20396").
        set offshoreSite to latlng(28.50895,-80.4).
        set BoosterHeight to 42.2.
        set LiftingPointToGridFinDist to 0.3.
        // Было 3000 -> после множителей (метан x5.31, 33 двигателя x1.25, HSR x1.03)
        // порог получался 20512 при том, что бустер возвращается с ~7600.
        // Опрос требует > порога x1.12, поэтому "Fuel: NOGo" был гарантирован ВСЕГДА.
        // 900 -> итоговый порог ~6150, это реально достижимо.
        set LFBoosterFuelCutOff to 900. //3000
        if FAR {
            set LngCtrlPID to PIDLOOP(0.35, 0.3, 0.25, -10, 10).
        }
        else {
            set LngCtrlPID to PIDLOOP(0.35, 0.3, 0.25, -10, 10).
        }
        set BoosterGlideDistance to 1450.
        if BoosterSingleEngines set BoosterGlideDistance to BoosterGlideDistance * 1.24.
        set BoosterGlideFactor to 1.25.
        set VelCancelFactor to 0.4.
        set LngCtrlPID:setpoint to 32. //75
        set LatCtrlPID to PIDLOOP(0.25, 0.2, 0.1, -5, 5).
        set RollVector to heading(242,0):vector.
        set BoosterReturnMass to 125.
        set BoosterRaptorThrust to 555.
        set BoosterRaptorThrust3 to 555.
        if Block3Cluster or BoosterType:contains("Block3") {
            set BoosterRaptorThrust to 655.
            set BoosterRaptorThrust3 to 660.
        }
        set Scale to 1.
        set CorrFactor to 0.8.
        set PIDFactor to 8.
        // Касание было великовато (~2 м/с при цели 0.4) - целимся мягче.
        set CatchVS to -0.25.
        set FinalDeceleration to 4.
    }
}
else {
    if body("Kerbin"):radius > 1000000 {
        set KSRSS to true.
        set Planet to "Kerbin".
        set LaunchSites to lexicon("KSC", "28.50895,-81.20396").
        set offshoreSite to latlng(28.50895,-80.4).
        if body("Kerbin"):radius < 1500001 {
            set RESCALE to true.
            set LaunchSites to lexicon("KSC", "-0.0970,-74.5833").
            set offshoreSite to latlng(-0.09,-74.3).
        }
        set BoosterHeight to 42.2.
        set LiftingPointToGridFinDist to 0.3.
        set LFBoosterFuelCutOff to 3000. //3000
        if FAR {
            set LngCtrlPID to PIDLOOP(0.35, 0.3, 0.25, -10, 10).
        }
        else {
            set LngCtrlPID to PIDLOOP(0.35, 0.3, 0.25, -10, 10).
        }
        set BoosterGlideDistance to 1400.
        if BoosterSingleEngines set BoosterGlideDistance to BoosterGlideDistance * 1.24.
        set BoosterGlideFactor to 1.25.
        set VelCancelFactor to 0.4.
        set LngCtrlPID:setpoint to 32. //75
        set LatCtrlPID to PIDLOOP(0.25, 0.2, 0.15, -5, 5).
        set RollVector to heading(242,0):vector.
        set BoosterReturnMass to 125.
        set BoosterRaptorThrust to 555.
        set BoosterRaptorThrust3 to 555.
        if Block3Cluster or BoosterType:contains("Block3") {
            set BoosterRaptorThrust to 655.
            set BoosterRaptorThrust3 to 660.
        }
        set Scale to 1.
        set CorrFactor to 0.8.
        set PIDFactor to 8.
        set CatchVS to -0.4.
        set FinalDeceleration to 4.
    }
    else {
        set STOCK to true.
        set Planet to "Kerbin".
        set LaunchSites to lexicon("KSC", "-0.0972,-74.5577", "Dessert", "-6.5604,-143.95", "Woomerang", "45.2896,136.11", "Baikerbanur", "20.6635,-146.4210").
        set offshoreSite to latlng(-0.097,-73).
        set BoosterHeight to 42.2.
        set LiftingPointToGridFinDist to 0.3.
        set LFBoosterFuelCutOff to 2750.
        if FAR {
            set LngCtrlPID to PIDLOOP(0.35, 0.28, 0.36, -10, 10).
        }
        else {
            set LngCtrlPID to PIDLOOP(0.35, 0.28, 0.36, -10, 10).
        }
        set BoosterGlideDistance to 1040. //1100
        if BoosterSingleEngines set BoosterGlideDistance to BoosterGlideDistance * 1.25.
        set BoosterGlideFactor to 1.15.
        set VelCancelFactor to 0.3.
        set LngCtrlPID:setpoint to 50. //50
        set LatCtrlPID to PIDLOOP(0.25, 0.15, 0.15, -5, 5).
        set RollVector to heading(270,0):vector.
        set BoosterReturnMass to 125.
        set BoosterRaptorThrust to 555.
        set BoosterRaptorThrust3 to 555.
        if Block3Cluster or BoosterType:contains("Block3") {
            set BoosterRaptorThrust to 655.
            set BoosterRaptorThrust3 to 660.
        }
        set Scale to 1.
        set CorrFactor to 0.95.
        set PIDFactor to 8.
        set CatchVS to -0.5.
        set FinalDeceleration to 6.5.
    }
}

for res in bCH4Tank:resources {
    if res:name = "LqdMethane" {
        set LFBoosterFuelCutOff to LFBoosterFuelCutOff * 5.310536.
    }
}

set v2 to up:vector.
set t2 to 0.
set DragDecel to 0.

if BoosterSingleEngines set LFBoosterFuelCutOff to LFBoosterFuelCutOff * 1.25.

if BoosterType:contains("Block3") {
    set LFBoosterFuelCutOff to LFBoosterFuelCutOff * 1.25.
    set BoosterHeight to 45.4*Scale.
    if FNBBooster set LngCtrlPID:setpoint to LngCtrlPID:setpoint*0.55.
    else set LngCtrlPID:setpoint to LngCtrlPID:setpoint*1.1*Scale.
    set maxAoA to 17.
    set BoosterGlideDistance to BoosterGlideDistance * 1.8.
    set Block3PollTime to 10.
    set BoosterGlideFactor to BoosterGlideFactor * 0.85.
} else 
    set Block3PollTime to 0.
if FNBBooster {
    set BoosterGlideFactor to BoosterGlideFactor * 0.85.
} 
if FNBBooster and not BoosterType:contains("Block3") {
    set LFBoosterFuelCutOff to LFBoosterFuelCutOff * 0.9.
    set BoosterGlideDistance to BoosterGlideDistance * 1.25.
}

// Посадочный резерв задаём НАПРЯМУЮ В ЕДИНИЦАХ LF - одна цифра, без цепочки
// множителей стока. Плотность ресурса читаем только чтобы показывать тонны.
// 03.09.2026: снижен с 12000 на 1500 ед по просьбе - было 12000.
set LandingReserveUnits to 10500.
set LFBoosterFuelCutOff to LandingReserveUnits.
for res in bCH4Tank:resources {
    if res:name = "LqdMethane" or res:name = "CooledLqdMethane" or res:name = "LiquidFuel" {
        if res:density > 0 set LFdensity to res:density.
    }
}

set RadarAltOffset to BoosterHeight.
lock RadarAlt to alt:radar - RadarAltOffset.
lock GSVec to vxcl(up:vector,velocity:surface).
set LandingBurnAlt to 1800.
// Целевая скорость касания на палочки (Block 3, финальный участок).
// Было 1 м/с - слишком жёстко, били по нижнему упору ReqDecel и часто
// не успевали. Один параметр на всё торможение.
set TouchdownSpeed to 5.
// 03.09.2026: по факту в игре (не по логам - там как раз получилось прилично)
// 3 двигателя не успевают так же оперативно гасить скорость, как 5, при живом
// весе этого бустера. Посадка теперь целиком на 5 двигателях, без перехода на 3.
set Land5EnginesOnly to true.
set maxRoll to 5.
set maxAoA to 12.
// Выше по файлу для Block 3 стоит maxAoA 17, и эта строка его затирала (баг стока).
// В логе это видно как "LngCtrl: -12 / 12" - продольный канал стоял в упоре
// на всём спуске, отсюда недолёт под 400 м.
if BoosterType:contains("Block3") set maxAoA to 17.

set BoosterDockingHeight to 29.8*Scale.
set maxstabengage to 80 * Scale.
set maxpusherengage to 0.33*Scale.

set MZHeight to 70*Scale.

set BoosterDockingHeight to 32.6*Scale.
if RSS set BoosterDockingHeight to BoosterDockingHeight + 0.65.
set maxstabengage to 100 * Scale.
set maxpusherengage to 0.3*Scale.

if BoosterSingleEngines set IgnitionTime to 0.64.
else set IgnitionTime to 0.69.

if not ship:status = "FLYING" and not ship:status = "SUB_ORBITAL" or ship:status = "PRELAUNCH" set landingzone to ship:geoposition.
else if vAng(GSVec,vCrs(north:vector,up:vector)) < 90 and vAng(GSVec,north:vector) < 90 and addons:tr:hasimpact set landingzone to 
    latlng(addons:tr:impactpos:lat + min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
            addons:tr:impactpos:lng - min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
else if vAng(GSVec,vCrs(north:vector,up:vector)) < 90 and vAng(GSVec,north:vector) > 90 and addons:tr:hasimpact set landingzone to 
    latlng(addons:tr:impactpos:lat - min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
            addons:tr:impactpos:lng - min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
else if vAng(GSVec,vCrs(north:vector,up:vector)) > 90 and vAng(GSVec,north:vector) < 90 and addons:tr:hasimpact set landingzone to 
    latlng(addons:tr:impactpos:lat - min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
            addons:tr:impactpos:lng + min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
else if addons:tr:hasimpact set landingzone to 
    latlng(addons:tr:impactpos:lat + min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
            addons:tr:impactpos:lng + min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
else set landingzone to ship:geoposition.

set TgtLandingzone to landingzone.


SetGridFinAuthority(36).
DeactivateGridFins().

if exists("0:/BoosterFlightData.csv") {
    deletepath("0:/BoosterFlightData.csv").
}

clearscreen.
print "Booster Nominal Operation, awaiting command..".

print ShipType + "-Ship + " + HSRType + "-HSR + " + BoosterType + "-Booster ".
print "--> RandomFlipDir:" + RandomFlip.

set OnceShipName to false.
set ShipConnectedToBooster to true.
set ConnectedMessage to false.
set PreDockPos to false.
set TelemetryTimer to time:seconds.
set dbactive to false.



on ag10 {
    set GD to true.
    set GDlamp:style:bg to "starship_img/telemetry_fuel".
    return true.
} 
on ag9 {
    set GD to false.
    set GDlamp:style:bg to "starship_img/telemetry_fuel_bg".
    return true.
} 

on ag8 {
    if not BoostBackComplete set HSRJet to false.
    set message0:text to message0:text + "  <size=10>NoHSRjet</size>".
    return true.
} 

on ag5 {
    if not BoosterStaticFireRunning and not ShipConnectedToBooster and ship:partstitled("Starship Orbital Launch Mount"):length > 0 {
        set ship:partstitled("Starship Orbital Launch Mount")[0]:getmodule("kOSProcessor"):volume:name to "OrbitalLaunchMount".
        BoosterStaticFire().
    }
    wait 0.
    return true.
}

wait 0.

if BoosterSingleEngines {
    for gimbalEng in BoosterSingleEnginesRC {
        if gimbalEng:hassuffix("activate") gimbalEng:getmodule("ModuleGimbal"):SetField("gimbal limit", 85/Scale).
    }
}
else if FNBBooster {
    if Block3Cluster Mid2GimbMod:SetField("gimbal limit", 65).
    MidGimbMod:SetField("gimbal limit", 65).
    CtrGimbMod:SetField("gimbal limit", 65).
}
else {
    if Block3Cluster Mid2GimbMod:SetField("gimbal limit", 80/Scale).
    MidGimbMod:SetField("gimbal limit", 80/Scale).
    CtrGimbMod:SetField("gimbal limit", 85/Scale).
}
set MaxQ to false.
set Hotstaging to false.
set SECO to false.
set qCheck to 1.

when time:seconds > TelemetryTimer + 0.03 then {
    GUIupdate().
    set TelemetryTimer to time:seconds.
    return true.
}

// Телеметрия для внешнего оверлея: раз в 0.1 с переписываем 0:/telemetry.json.
// Пишем обычный JSON строкой, а не writejson - тот кладёт kOS-формат с $type,
// который снаружи парсить неудобно.
when time:seconds > OverlayTimer + 0.1 then {
    WriteTelemetry().
    set OverlayTimer to time:seconds.
    return true.
}



// Веха на таймлайне оверлея (MaxQ/Sep) до самого события - это средняя
// оценка по прошлым полётам, а не факт: реальное время зависит от массы
// (полезная нагрузка) и тяговооружённости, которые от миссии к миссии разные.
// Один и тот же оверлей летает и с тяжёлым грузом, и налегке - масштабировать
// оценку без данных, как она меняется с массой, значит просто гадать вместо
// исправления. Поэтому сначала копим факт: масса и тяга ровно в момент
// отрыва (MET=0), рядом с уже готовыми фактическими MaxQTime/HotstagingTime.
// Когда наберётся несколько полётов с разной нагрузкой, можно будет вывести
// формулу по факту, а не подгонять её на глазок.
// missionTimer стартует НУЛЁМ, поэтому условие "time:seconds > missionTimer"
// истинно сразу при загрузке скрипта: триггер срабатывал ещё до отсчёта, ловил
// массу неизвестно чего и тягу 0 (двигатели не запущены) - в логе так и вышло
// LiftoffTWR = 0. Ждём, пока отсчёт реально назначит момент старта.
// На T-0 ускоритель ЕЩЁ СТОИТ НА СТОЛЕ, и ship:mass считает вместе с ним
// стартовый стол и башню: в логе выходило LiftoffMass = 101403 т и TWR = 0.019
// при реальной массе связки 1241 т. Ждём фактического отрыва - как только
// пошла вертикальная скорость, зажимы отпущены и масса уже своя.
when missionTimer > 0 and time:seconds > missionTimer and verticalspeed > 0.1 then {
    set LiftoffMass to ship:mass.
    set LiftoffThrust to ship:availablethrust.
    set LiftoffTWR to LiftoffThrust / max(0.001, LiftoffMass * 9.80665).
}
when MaxQ then {
    set ClockHeader:text to "Max Q".
    set MaxQTime to time:seconds.
    when MaxQTime + 4 < time:seconds then set ClockHeader:text to MissionName.
}
when Hotstaging then {
    set ClockHeader:text to "Hotstaging".
    set HotstagingTime to time:seconds.
    when HotstagingTime + 5 < time:seconds then set ClockHeader:text to MissionName.
} 
when SECO then {
    set ClockHeader:text to "SECO".
    set SECOTime to time:seconds.
    when SECOTime + 4 < time:seconds then set ClockHeader:text to MissionName.
} 

wait 0.1.

until False {
    if SHIP:PARTSNAMED("SEP.23.SHIP.BODY"):LENGTH = 0 and SHIP:PARTSNAMED("SEP.23.SHIP.BODY.EXP"):LENGTH = 0 and SHIP:PARTSNAMED("SEP.24.SHIP.CORE"):LENGTH = 0 and SHIP:PARTSNAMED("SEP.24.SHIP.CORE.EXP"):LENGTH = 0 and SHIP:PARTSNAMED("SEP.23.SHIP.DEPOT"):LENGTH = 0 and SHIP:PARTSNAMED("BLOCK-2.MAIN.TANK"):LENGTH = 0 and ship:partsnamed("FNB.BL2.LOX"):length = 0 and ship:partsnamed("FNB.BL3.LOX"):length = 0 and ship:partsnamed("SEP.25.SHIP.CORE"):length = 0 and not ConnectedMessage {
        set ShipConnectedToBooster to false.
        //print("ShipFalse").
    } 
    else {
        set ShipConnectedToBooster to true.
        //print("ShipTrue").
    }
    if not OnceShipName {
        set starship to ship:name.
        set OnceShipName to true.
    }
    if not UseOverlay bTelemetry:show().
    if ShipConnectedToBooster = "false" and not (ship:status = "LANDED") and altitude > 10000 {
        Boostback().
    }
    //wait until false.
    if RecoveryEnabled and alt:radar < 150 and alt:radar > 20 and ship:mass - ship:drymass < 60 and not TowerOnShip()  and not (LandSomewhereElse) { //and not (RSS)
        if homeconnection:isconnected {
            if exists("0:/settings.json") {
                set L to readjson("0:/settings.json").
                if L:haskey("Auto-Stack") {
                    if L["Auto-Stack"] = true {
                        setLandingZone().
                        setTargetOLM().
                        if not PreDockPos {
                            AfterLandingTowerOperations().
                        } else {
                            BoosterDocking().
                        }
                        
                    }
                }
            }
        }
    }
    set command to "".
    UNTIL NOT CORE:MESSAGES:EMPTY {}
    SET RECEIVED TO CORE:MESSAGES:POP.
        if RECEIVED:CONTENT:CONTAINS(",") {
            set message to RECEIVED:CONTENT:SPLIT(",").
            set command to message[0].
            if message:length > 1 {
                if message:length = 2 set MesParameter to message[1].
            }
        }
    IF RECEIVED:CONTENT = "Boostback" {
        print RandomFlip.
        Boostback().
    } else if RECEIVED:CONTENT = "HSRJet"{
        set HSRJet to true.
    } 
    else if RECEIVED:CONTENT = "NoHSRJet" {
        set HSRJet to false.
    }
    else if command = "Arms" {
        set oldArms to MesParameter.
        if oldArms print "Old Arms".
        else print "New Arms".
    }
    else if RECEIVED:CONTENT = "Depot" {
        set Depot to true.
    }
    else if RECEIVED:CONTENT = "ShipDetected" {
        set ConnectedMessage to true.
    }
    else if RECEIVED:CONTENT = "Countdown" {
        set missionTimer to time:seconds.
        set missionTimer to missionTimer + TMinusCountdown.
    }
    else if command = "ScaleT" {
        bTelemetry:hide().
        set TScale to MesParameter:toscalar.
        CreateTelemetry().
        wait 0.2.
        reboot.
        bTelemetry:show().
    }
    else if command = "IgnChance" {
        set BBIgn to message[1]:toscalar.
        set LBIgnC to message[2]:toscalar.
        set LBIgnM to message[3]:toscalar.
        set ifIgn to message[4]:toscalar.
    }
    else if command = "fullAuto" {
        if MesParameter = "true" set fullAuto to true.
        else set fullAuto to false.
    }
    else if command = "highSplash" {
        if MesParameter = "true" set highSplash to true.
        else set highSplash to false.
        print "HighSplashdown: " + highSplash.
    }
    else if command = "MissionName" {
        set MissionName to MesParameter.
        set ClockHeader:text to MissionName.
    }
    else if RECEIVED:CONTENT = "Hotstaging" {
        set Hotstaging to true.
    }
    else if RECEIVED:CONTENT = "SECO" {
        set SECO to true.
    }
    else if command = "TMinusCountdown" {
        set TMinusCountdown to MesParameter:toscalar.
    }
    else if command = "Bl3LndProf" {
        // Приходит строкой ("true"/"false"), раньше клалось в переменную как есть.
        // Для Block 3 профиль 13-5-3 выключать нельзя - он штатный.
        if BoosterType:contains("Block3") set Bl3LndProf to true.
        else if MesParameter = "true" set Bl3LndProf to true.
        else set Bl3LndProf to false.
    }
    else if RECEIVED:content = "StaticFire" {
        if not BoosterStaticFireRunning and ship:partstitled("Starship Orbital Launch Mount"):length > 0 {
            set ship:partstitled("Starship Orbital Launch Mount")[0]:getmodule("kOSProcessor"):volume:name to "OrbitalLaunchMount".
            BoosterStaticFire().
        }
        sendMessage(processor(volume("Starship")),"bStaticFireFinished").
    }
    ELSE {
        PRINT "Unexpected message: " + RECEIVED:CONTENT.
    }
    wait 0.01.
}


function BoosterStaticFire {
    if (BoosterSingleEngines or defined BoosterEngines) and defined bLOXTank and defined bCH4Tank {
        set BoosterStaticFireRunning to true.
        set LaunchStand to ship:partstitled("Starship Orbital Launch Mount")[0].
        for x in range(0, LaunchStand:modules:length) {
            if LaunchStand:getmodulebyindex(x):hasaction("toggle fueling") or LaunchStand:getmodulebyindex(x):name:contains("ModuleGenerator") { 
                set FuelingModuleNr to x+1.
                break.
            }
        }
        if boosterCH4 < 8 or boosterLOX < 90 {
            hudtext("Fueling..",8,2,18,yellow,false).
            if LaunchStand:getmodulebyindex(FuelingModuleNr):HasEvent("Start Fueling") {
                LaunchStand:getmodulebyindex(FuelingModuleNr):DoEvent("Start Fueling").
            }
            until boosterCH4 > 16 and boosterLOX > 90 {
                for res in bCMNDome:resources {
                    if res:name:contains("Ox") {
                        if boosterLOX < 91 set res:enabled to true.
                        else set res:enabled to false.
                    }
                    if res:name:contains("Methane") {
                        if boosterCH4 < 17 set res:enabled to true.
                        else set res:enabled to false.
                    }
                }
                if BoosterType:contains("Block3") {
                    for res in bLOXTank:resources {
                        if res:name:contains("Ox") {
                            if boosterLOX < 91 set res:enabled to true.
                            else set res:enabled to false.
                        }
                        if res:name:contains("Methane") {
                            if boosterCH4 < 17 set res:enabled to true.
                            else set res:enabled to false.
                        }
                    }
                    for res in BoosterEngines[0]:resources {
                        if res:name:contains("Ox") {
                            if boosterLOX < 91 set res:enabled to true.
                            else set res:enabled to false.
                        }
                        if res:name:contains("Methane") {
                            if boosterCH4 < 17 set res:enabled to true.
                            else set res:enabled to false.
                        }
                    }
                    for res in bCH4Tank:resources {
                        if res:name:contains("Ox") {
                            if boosterLOX < 91 set res:enabled to true.
                            else set res:enabled to false.
                        }
                        if res:name:contains("Methane") {
                            if boosterCH4 < 17 set res:enabled to true.
                            else set res:enabled to false.
                        }
                    }
                    for res in FWD:resources {
                        if res:name:contains("Ox") {
                            if boosterLOX < 91 set res:enabled to true.
                            else set res:enabled to false.
                        }
                        if res:name:contains("Methane") {
                            if boosterCH4 < 17 set res:enabled to true.
                            else set res:enabled to false.
                        }
                    }
                }
                wait 0.2.
            }
            if LaunchStand:getmodulebyindex(FuelingModuleNr):HasEvent("Stop Fueling") {
                LaunchStand:getmodulebyindex(FuelingModuleNr):DoEvent("Stop Fueling").
            }
        }
        HUDTEXT("Initiating Static Fire..", 10, 2, 24, yellow, false).
        CheckFuel().
        if LFBooster > LFBoosterFuelCutOff {
            for res in bCH4Tank:resources {
                if res:name:contains("Methane") or res:name = "LiquidFuel" set res:enabled to false.
            }
        }
        if OxBooster/OxBoosterCap < 0.9 or LFBooster < LFBoosterFuelCutOff {
            RefuelBooster().
            until BoosterFueled {wait 0.03.}
        }
        for res in bCH4Tank:resources {
            if res:name:contains("Methane") or res:name = "LiquidFuel" set res:enabled to true.
        }
        set missionTimer to time:seconds + 15.
        until time:seconds - missionTimer > -10 {
            wait 0.03.
        }
        sendMessage(processor(volume("OrbitalLaunchMount")), "StaticFire,"+missionTimer).
        until time:seconds - missionTimer > -2 {
            wait 0.03.
        }
        lock throttle to 1.
        if not BoosterSingleEngines BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("next engine mode", true).
        wait 0.
        if not BoosterSingleEngines BoosterEngines[0]:getmodule("ModuleEnginesFX"):doaction("activate engine", true).
        else {
            for eng in BoosterSingleEnginesRC if eng:hassuffix("activate") if eng:activate.
        }
        until time:seconds - missionTimer > -1 {
            wait 0.03.
        }
        if not BoosterSingleEngines BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("previous engine mode", true). 
        else {
            set y to 0.
            for eng in BoosterSingleEnginesRB {
                if y = 3 or y = 7 or y = 11 or y = 15  or y = 19 {}
                else if eng:hassuffix("activate") if eng:activate.
                set y to y + 1.
            }
            set inactiveEng to List(3,7,11,15,19).
        }
        until time:seconds - missionTimer > -0.3 {
            wait 0.03.
        }
        if BoosterSingleEngines {
            set y to 0.
            for eng in BoosterSingleEnginesRB {
                if eng:hassuffix("activate") if inactiveEng:contains(y) if eng:activate.
                set y to y + 1.
            }
        }
        until time:seconds - missionTimer > 6 {
            wait 0.03.
        }
        if BoosterSingleEngines {
        set y to 0.
        until y > 3 {
            if BoosterSingleEnginesRB[y]:hassuffix("activate") BoosterSingleEnginesRB[y]:shutdown.
            if BoosterSingleEnginesRB[y+4]:hassuffix("activate") BoosterSingleEnginesRB[y+4]:shutdown.
            if BoosterSingleEnginesRB[y+8]:hassuffix("activate") BoosterSingleEnginesRB[y+8]:shutdown.
            if BoosterSingleEnginesRB[y+12]:hassuffix("activate") BoosterSingleEnginesRB[y+12]:shutdown.
            if BoosterSingleEnginesRB[y+16]:hassuffix("activate") BoosterSingleEnginesRB[y+16]:shutdown.
            set y to y + 1.
            wait 0.05.
        }
        set y to 0.
        until y > 1 {
            if BoosterSingleEnginesRC[y+3]:hassuffix("activate") BoosterSingleEnginesRC[y+3]:shutdown.
            if BoosterSingleEnginesRC[y+5]:hassuffix("activate") BoosterSingleEnginesRC[y+5]:shutdown.
            if BoosterSingleEnginesRC[y+7]:hassuffix("activate") BoosterSingleEnginesRC[y+7]:shutdown.
            if BoosterSingleEnginesRC[y+9]:hassuffix("activate") BoosterSingleEnginesRC[y+9]:shutdown.
            if BoosterSingleEnginesRC[y+11]:hassuffix("activate") BoosterSingleEnginesRC[y+11]:shutdown.
            set y to y + 1.
            wait 0.05.
        }
        if BoosterSingleEnginesRC[0]:hassuffix("activate") BoosterSingleEnginesRC[0]:shutdown.
        if BoosterSingleEnginesRC[1]:hassuffix("activate") BoosterSingleEnginesRC[1]:shutdown.
        if BoosterSingleEnginesRC[2]:hassuffix("activate") BoosterSingleEnginesRC[2]:shutdown.
        }
        else {
            BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("next engine mode", true).
            wait 0.2.
            BoosterEngines[0]:getmodule("ModuleEnginesFX"):doaction("shutdown engine", true).
        }
        lock throttle to 0.
        unlock throttle.
        until time:seconds - missionTimer > 10 {
            wait 0.03.
        }
        hudtext("Static Fire Complete",3,5,24,green,true).
        set BoosterStaticFireRunning to false.
    }
    set BoosterStaticFireRunning to false.
}

function RefuelBooster {
    sendMessage(Processor(volume("OrbitalLaunchMount")), "ToggleReFueling,true").
    until BoosterFueled {
        CheckFuel().
        if OxBooster/OxBoosterCap > 0.9 and LFBooster > LFBoosterFuelCutOff set BoosterFueled to true.
    }
    sendMessage(Processor(volume("OrbitalLaunchMount")), "ToggleReFueling,false").
}


function Boostback {
    set Idle to false.
    set RollVector to -vxcl(up:vector,facing:forevector).
    if BoosterSingleEngines for eng in BoosterSingleEnginesRB if eng:hassuffix("activate") eng:shutdown.
    wait until SHIP:PARTSNAMED("SEP.23.SHIP.BODY"):LENGTH = 0 and SHIP:PARTSNAMED("SEP.23.SHIP.BODY.EXP"):LENGTH = 0 and SHIP:PARTSNAMED("SEP.24.SHIP.CORE"):LENGTH = 0 and SHIP:PARTSNAMED("SEP.24.SHIP.CORE.EXP"):LENGTH = 0 and SHIP:PARTSNAMED("SEP.23.SHIP.DEPOT"):LENGTH = 0 and ship:partsnamed("FNB.BL2.LOX"):length = 0 and ship:partsnamed("FNB.BL3.LOX"):length = 0 and ship:partsnamed("SEP.25.SHIP.CORE"):length = 0.
    wait 0.001.
    // Раньше стояло внутри "if verticalspeed > 0" ниже вместе с несвязанной
    // логикой (HSR-детект, rebooted-флаг) - если к моменту входа в Boostback()
    // вертикальная скорость уже была <=0, время отделения не записывалось
    // вообще, и EvSep/лог вехи так и оставались -1 всю посадку. Отделение
    // случилось прямо здесь (мы только что дождались реального разъединения
    // партов), поэтому метка времени безусловна.
    set SeparationTime to time:seconds.
    set ShipConnectedToBooster to false.
    set ConnectedMessage to false.
    // Вентиль сброса топлива ("Vent System") активен ещё со старта и жрёт
    // ~1624 ед/с всё время буст-бэка. Закрываем его сразу после отделения.
    if SinglePartBooster BoosterCore:shutdown.
    else for vent in DumpVents if not vent:istype("Boolean") vent:doaction("shutdown engine", true).
    set config:ipu to 1500.
    rcs off.
    set steeringmanager:maxstoppingtime to 2.
    set bAttitude:style:bg to "starship_img/booster".
    set steeringManager:pitchpid:kd to 0.5.
    set steeringManager:yawpid:kd to 0.5.

    set HighLandingBurn to false.

    if RandomFlip set targetAp to ship:apoapsis - 200*Scale.
    else set targetAp to ship:apoapsis + 800*(Scale^1.5).

    if STOCK and not Bl3LndProf set BoosterGlideDistance to BoosterGlideDistance * 0.94.


    setLandingZone().
    setTargetOLM().

    set ApproachUPVector to (landingzone:position - body:position):normalized.
    set ApproachVector to vxcl(up:vector, landingzone:position - ship:position):normalized.
    set ErrorVector to vxcl(up:vector, ship:position - landingzone:position).
    
    SteeringCorrections().

    if not BoosterType:contains("Block3") and SinglePartBooster BoosterCore:controlfrom().
    if BoosterType:contains("Block3")
        set Bl3LndProf to true.
    if HSRJet set RadarAltOffset to BoosterHeight * 0.6.
    else set RadarAltOffset to BoosterHeight.

    if verticalspeed > 0 {
        set rebooted to false.
        if ship:partsnamed(HSRpartname):length = 0 and not BoosterType:contains("Block3") {
            set Block1HSR to true.
            set HSRJet to true.
        }
        lock FlipAngle to vang(vxcl(up:vector, facing:forevector), vxcl(up:vector, -ErrorVector)).

        set LaunchPitch to vAng(up:vector, facing:forevector).
        set PitchStrength to ((LaunchPitch)/45)^3.
        set PurePitchFlip to false.
        if RandomFlip {
            set rndPitch to round(random(),1).
            if rndPitch < 0.44 set PitchStrength to -PitchStrength.

            set rndYaw to round(random(),1).
            set YawStrength to max(round(random(),1),0.3).
            if rndYaw < 0.44 set YawStrength to -2.5*YawStrength.
            if 0.4 > YawStrength and YawStrength > -0.4 set PitchStrength to PitchStrength*1.5.
            if abs(YawStrength) + abs(PitchStrength) < 2.4 set PitchStrength to PitchStrength * (1 + 2.4-abs(YawStrength) + abs(PitchStrength)).

            set ship:control:pitch to -2 * PitchStrength.
            set ship:control:yaw to -2 * YawStrength.
            if not RSS set FlipTime to 4.4.
            else set FlipTime to 4.2.
        } else {
            // Чистый разворот по одной оси тангажа, "через верх".
            // Открытый импульс убран: он даёт неуправляемый кувырок, потому что
            // на время FlipTime*0.6 steering отключён и крен ничем не держится.
            // Raw-оси надо именно ОТПУСТИТЬ, а не обнулить: иначе они держат
            // приоритет над cooked-управлением и lock steering не получит руля.
            set ship:control:neutralize to true.
            set PurePitchFlip to true.
            if not RSS set FlipTime to 4.5.
            else set FlipTime to 4.2.

        }
        if PurePitchFlip {
            // Ось разворота берём МИРОВУЮ - нормаль к плоскости полёта (горизонталь,
            // перпендикулярная путевой скорости). Ось корпуса при неправильном крене
            // наклонена, и разворот вокруг неё уводит из плоскости - это и есть
            // боковой сдвиг.
            set FlipAxis to vCrs(up:vector, vxcl(up:vector, velocity:surface)):normalized.
            // Знак оси выбираем так, чтобы нос пошёл ВВЕРХ, через вертикаль, а не вниз.
            if vdot((ANGLEAXIS(10, FlipAxis) * ship:facing):forevector, up:vector) < vdot(ship:facing:forevector, up:vector) {
                set FlipAxis to -FlipAxis.
            }
            // Крен задаём ЯВНО: в разворот бустер идёт ВЕРХ НОГАМИ (топ вниз).
            // Тогда его собственная ось тангажа лежит в плоскости полёта.
            set FlipStartFacing to lookdirup(ship:facing:forevector, -up:vector).
            // LaunchPitch + 90: нос из наклонного положения уходит через вертикаль
            // в горизонт двигателями вперёд.
            set FlipTotalAngle to 90 + LaunchPitch.
            set FlipTargetDir to ANGLEAXIS(FlipTotalAngle, FlipAxis) * FlipStartFacing.
            // Крен на весь буст-бэк - "верх ногами", -up:vector берётся ЖИВЫМ прямо
            // в наведении (снимок на момент флипа устаревал: за бёрн бустер уходит
            // на сотни км, и локальная вертикаль успевает повернуться).
            // Исправляется крен только после выключения двигателей - на развороте
            // на вход, где наведение переходит на ApproachVector.

            // ЗАДАЁМ ТРАЕКТОРИЮ, А НЕ КОНЕЧНУЮ ТОЧКУ.
            // Команда ползёт по той же оси со скоростью FlipSlewRate град/с и при
            // этом не убегает от корпуса дальше FlipLead градусов ("поводок").
            // Пока рассогласование маленькое, SteeringManager работает в линейной
            // зоне и реально держит крен. Если сразу дать цель "150° в сторону",
            // он насыщается (Steering Error 100+), рули стоят в упоре, и дальше
            // бустер разворачивает аэродинамика - вот это и был увод вбок.
            set FlipSlewRate to 15.
            set FlipLead to 20.
            set FlipRampStart to time:seconds.
            lock FlipCmdAngle to min(FlipTotalAngle, min((time:seconds - FlipRampStart) * FlipSlewRate, vAng(ship:facing:forevector, FlipStartFacing:forevector) + FlipLead)).
            lock FlipPitchDir to ANGLEAXIS(FlipCmdAngle, FlipAxis) * FlipStartFacing.
            // Доворота по крену НЕТ. По лётным данным разворот по тангажу сам
            // приводит бустер в нужный крен: на курсе 270 требуемая поправка
            // равна нулю. Прежняя рампа на 180° была лишней и давала ту самую
            // ошибку по крену в 105-180 градусов, которая висела весь буст-бэк.
            lock steering to FlipPitchDir.
            set FlipRampActive to true.
        }
        else unlock steering.
        set ship:name to "Booster".
        wait 0.
        rcs on.
        lock throttle to 0.66.
        if not BoosterType:contains("Block3") when time:seconds > SeparationTime + 0.5 then {lock throttle to 0.95.}
        // Не-Block3 бустеры получают буст до 0.95 через 0.5 с, у Block3 такого
        // не было вообще - весь разворот на 5 движках шёл на голых 0.66. Тяга
        // через отклонённый гимбал - это и есть крутящий момент разворота, на
        // 0.66 его просто не хватает. Даём тот же буст, чуть быстрее (0.3 с),
        // потому что у 5 движков и так меньше суммарной тяги, чем у полного кольца.
        if BoosterType:contains("Block3") when time:seconds > SeparationTime + 0.3 then {lock throttle to 0.92.}
        sas off.
        // При чистом флипе крен нужно держать ВСЮ дорогу: иначе остаточная угловая
        // скорость по крену разворачивает саму ось тангажа и бустер уходит из плоскости.
        if PurePitchFlip set RollRangeNormal to 180.
        else set RollRangeNormal to 3.
        set SteeringManager:ROLLCONTROLANGLERANGE to RollRangeNormal.
        set RollFrozen to false.
        if PurePitchFlip set SteeringManager:rollts to 2.
        else set SteeringManager:rollts to 5.
        wait 0.1.
        HUDTEXT("Performing Boostback Burn..", 30, 2, 20, green, false).
        set ship:name to "Booster".
        clearscreen.
        print "Starting Boostback".
        set CurrentTime to time:seconds.
        set kuniverse:timewarp:warp to 0.
        bCH4Tank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).
        FWD:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).
        if BoosterType:contains("Block3") or ship:partsnamed("FNB.BL1.BOOSTERLOX"):length > 0 bCMNDome:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).
        // Разворот делаем ТЯГОЙ ПЯТЁРКИ. Раньше подвес средних тут запирался, и
        // корпус крутили только три центральных: по логу это ~4 град/с, за время
        // пятёрки бустер проходил лишь ~20 из 135 град. Средние тоже работают в
        // этом режиме - их подвес и даёт недостающий момент, без лишней тяги.
        if not BoosterSingleEngines MidGimbMod:SetField("gimbal limit", 90).
        if not BoosterSingleEngines MidGimbMod:doaction("free gimbal", true).
        if not BoosterSingleEngines CtrGimbMod:SetField("gimbal limit", 100).
        if not BoosterSingleEngines and Block3Cluster Mid2GimbMod:SetField("gimbal limit", 90).
        if not BoosterSingleEngines and Block3Cluster Mid2GimbMod:doaction("free gimbal", true).
        if BoosterSingleEngines {
            set x to 1.
            until x > 3 {
                if BoosterSingleEnginesRC[x-1]:hassuffix("activate") BoosterSingleEnginesRC[x-1]:getmodule("ModuleGimbal"):SetField("gimbal limit", 75).
                set x to x + 1.
            }
            set x to 1.
            until x > 3 {
                if BoosterSingleEnginesRC[x-1]:hassuffix("activate") set BoosterSingleEnginesRC[x-1]:gimbal:lock to false.
                set x to x + 1.
            }
        }
        SteeringCorrections().
        
        
        

        if RSS {
            SetLoadDistances(1750000).
        }
        else if KSRSS {
            SetLoadDistances(1500000).
        }
        else {
            SetLoadDistances(355000).
        }


        wait 0.001.
        if defined L and not starship:contains("Starship") {
            if L:haskey("Ship Name") {
                set starship to L["Ship Name"].
                until ShipFound or verticalspeed < 0 or ShipNotFound {
                    list targets in tgtlist.
                    for tgt in tgtlist {
                        if (tgt:name) = (starship) {
                            set ShipFound to true.
                            print tgt:name.
                            wait 0.001.
                        }
                    }
                    if not (ShipFound) {
                        set waittimer to time:seconds.
                        when waittimer + 3 > time:seconds then {
                            for tgt in tgtlist {
                                if tgt:name:contains("Starship") and (tgt:status = "SUB_ORBITAL" or tgt:status = "FLYING" or tgt:status = "ORBITAL")
                                    if tgt:orbit:periapsis < ship:body:atm:height {
                                        set ShipFound to true.
                                        print tgt:name.
                                        set starship to tgt:name.
                                        wait 0.001.
                                    }
                            }
                            if not ShipFound set ShipNotFound to true.
                        }
                    }
                    wait 0.
                }
            }
        } else if starship:contains("Starship") {
            set ShipFound to true.
        }

        if ship:partsnamed(HSRpartname):length = 0 {
            set ship:name to "Booster".
            set Block1HSR to true.
        }

        

        set flipStartTime to time:seconds.

        if PurePitchFlip {
            // На наведение по -ErrorVector переходим только когда доворот по тангажу
            // фактически закончен. Раньше времени эта цель даёт команду по рысканью
            // и крену одновременно - именно она и уводила бустер вбок.
            // Переходим на наведение по -ErrorVector только когда рампа доехала
            // до конца И корпус за ней успел. Таймаут большой: разворот теперь
            // идёт по скорости корпуса (~10-15 град/с), а не за FlipTime.
            when (FlipCmdAngle > FlipTotalAngle - 1 and vAng(ship:facing:forevector, FlipTargetDir:forevector) < 12) or time:seconds > flipStartTime + 40 then {
                set FlipRampActive to false.
                unlock FlipPitchDir.
                // Опора крена возвращена к стоковой. Было `-up:vector` (правка
                // прошлой сессии): по логу это переворачивало КОМАНДУ на 180
                // ровно в момент завершения флип-рампы (MET 116.9: Cmd 91.2 ->
                // 172.8, RollErr -0.24 -> 172.64), после чего крен приходилось
                // морозить на все 20 секунд ожога. Бустер стоял на TopVsUp 2.7,
                // а на выключении буст-бэка заморозка снималась и накопленное
                // расхождение вылезало как RollErr -90 на 14 секунд.
                // В начале буст-бэка команда была верной, а ошибка нулевой -
                // значит инверсия и была источником, а не доворот аппарата.
                // Опора "верха" была up:vector - facing:topvector. Это ноль-вектор
                // ровно тогда, когда крыша бустера приходит к зениту, - а это его
                // штатное положение на буст-бэке (top vs up = 2.3). lookdirup на
                // нулевой опоре вырождается и возвращает произвольный поперечный
                // "верх": на экране было fore vs up 90 И cmd top vs up 88.8, то
                // есть оба горизонтальны - это и есть те самые -90 крена.
                // До этого здесь стоял -up:vector: он не вырожден, но требует от
                // бустера лежать пузом вверх, а он лежит пузом вниз - отсюда были
                // -180. Правильная опора - та, где бустер уже стоит: up:vector.
                // Ошибка крена становится ~2 гр., заморозка на ожоге не нужна,
                // RCS не тратится. Нужное для планирования положение всё равно
                // ставит разворот в coast - он это делает за 4 секунды.
                lock SteeringVector to lookdirup(vxcl(up:vector, -ErrorVector), up:vector).
                lock steering to SteeringVector.
            }
        }
        else {
            when time:seconds > flipStartTime + FlipTime*0.6 then {
                lock SteeringVector to lookdirup(vxcl(up:vector, -ErrorVector), up:vector).
                lock steering to SteeringVector.
            }
        }

        //Middle Restart
        if not BoosterType:contains("Block3") { 
            when time:seconds > flipStartTime + FlipTime*0.8 and verticalspeed > 0 then {
                lock throttle to 0.6.
                wait 0.01.
                if BoosterSingleEngines {
                    set x to 1.
                    until x > 3 {
                        if BoosterSingleEnginesRC[x-1]:hassuffix("activate") set BoosterSingleEnginesRC[x-1]:gimbal:lock to false.
                        if BoosterSingleEnginesRC[x-1]:hassuffix("activate") BoosterSingleEnginesRC[x-1]:getmodule("ModuleGimbal"):SetField("gimbal limit", 50).
                        set x to x + 1.
                    }
                    set tEngStart to time:seconds.
                    if random() < BBIgn/100 if BoosterSingleEnginesRC[3]:hassuffix("activate") BoosterSingleEnginesRC[3]:activate.
                    if random() < BBIgn/100 if BoosterSingleEnginesRC[8]:hassuffix("activate") BoosterSingleEnginesRC[8]:activate.
                    when time:seconds - tEngStart > 0.24 then {
                        if random() < BBIgn/100 if BoosterSingleEnginesRC[4]:hassuffix("activate") BoosterSingleEnginesRC[4]:activate.
                        if random() < 0.98*BBIgn/100 if BoosterSingleEnginesRC[9]:hassuffix("activate") BoosterSingleEnginesRC[9]:activate.
                        when time:seconds - tEngStart > 0.48 then {
                            if random() < 0.98*BBIgn/100 if BoosterSingleEnginesRC[6]:hassuffix("activate") BoosterSingleEnginesRC[6]:activate.
                            if random() < BBIgn/100 if BoosterSingleEnginesRC[11]:hassuffix("activate") BoosterSingleEnginesRC[11]:activate.
                            when time:seconds - tEngStart > 0.72 then {
                                if random() < 0.98*BBIgn/100 if BoosterSingleEnginesRC[7]:hassuffix("activate") BoosterSingleEnginesRC[7]:activate.
                                if random() < BBIgn/100 if BoosterSingleEnginesRC[12]:hassuffix("activate") BoosterSingleEnginesRC[12]:activate.
                                when time:seconds - tEngStart > 0.96 then {
                                    if random() < BBIgn/100 if BoosterSingleEnginesRC[5]:hassuffix("activate") BoosterSingleEnginesRC[5]:activate.
                                    if random() < 0.98*BBIgn/100 if BoosterSingleEnginesRC[10]:hassuffix("activate") BoosterSingleEnginesRC[10]:activate.
                                    set EC to true.
                                }
                            }
                        }
                    }
                }
                else {
                    if Block3Cluster Mid2GimbMod:SetField("gimbal limit", 90).
                    MidGimbMod:SetField("gimbal limit", 90).
                    MidGimbMod:doaction("free gimbal", true).
                    if Block3Cluster Mid2GimbMod:doaction("free gimbal", true).
                    if BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):hasfield("Mode") {
                        set Mode to BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):getfield("Mode").
                    }
                    if Mode = "Middle Inner" or Mode = "Raptor_3_Inner" or Mode = "Inner" {} else {
                        BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("previous engine mode", true).
                        wait 0.
                        if BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):hasfield("Mode") {
                            set Mode to BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):getfield("Mode").
                        }
                        if Mode = "Raptor_3_2Inner" or Mode = "2Inner" BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("previous engine mode", true).
                    }
                }
            }
        }
        else {
            // Полную тягу даём только когда бустер РЕАЛЬНО развернулся носом назад.
            // Было: таймаут flipStartTime+FlipTime (4.5 c) выстреливал раньше, чем
            // заканчивался разворот на 135 град - по логу 33 двигателя включались
            // на 37% флипа, тяга шла мимо и тангаж проваливался под горизонт.
            // Старый допуск 110 град - это почти "куда угодно", стало 30.
            // Таймаут оставлен страховкой, но длинный, чтобы не срабатывал первым.
            // ПРОМЕЖУТОЧНАЯ СТУПЕНЬ 5 -> 13 на середине разворота. Пятёрка после
            // освобождения подвеса крутит бодро, но тяги для самого буст-бэка у
            // неё мало. 13 двигателей добавляют и момент, и полезную тягу, при
            // этом это ещё не полная связка - тангаж под горизонт не проваливает.
            // 03.09.2026: порог снижен 0.45 -> 0.3 (и таймаут 12 -> 9 с) - раньше
            // зажигаем 13 движков. Вместе с бустом throttle 5-движков до 0.92
            // выше флип и так должен идти быстрее, но это отдельная просьба -
            // зажигать 13 пораньше именно по доле пройденного разворота.
            set MidStageDone to false.
            when (FlipRampActive and FlipTotalAngle > 0 and FlipCmdAngle > FlipTotalAngle * 0.3)
                 or time:seconds > flipStartTime + 9 then {
                if not MidStageDone and not BoosterSingleEngines {
                    set MidStageDone to true.
                    if BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):hasfield("Mode") {
                        set Mode to BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):getfield("Mode").
                        if Mode = "2Inner" or Mode = "MiddleTwo" or Mode = "Middle Two" or Mode = "Raptor_3_2Inner" {
                            MidGimbMod:SetField("gimbal limit", 90).
                            MidGimbMod:doaction("free gimbal", true).
                            if Block3Cluster Mid2GimbMod:SetField("gimbal limit", 90).
                            if Block3Cluster Mid2GimbMod:doaction("free gimbal", true).
                            BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("previous engine mode", true).
                        }
                    }
                }
            }

            when vAng(facing:forevector, vxcl(up:vector, -ErrorVector)) < FullThrustAngle or time:seconds > flipStartTime + 22 then {
                if BoosterSingleEngines {
                    set tEngStart to time:seconds.
                    for eng in BoosterSingleEnginesRC if eng:hassuffix("activate") eng:activate.
                    when time:seconds - tEngStart > 0.8 then {
                        if random() < BBIgn/100 if BoosterSingleEnginesRB[0]:hassuffix("activate") BoosterSingleEnginesRB[0]:activate.
                        if random() < BBIgn/100 if BoosterSingleEnginesRB[2]:hassuffix("activate") BoosterSingleEnginesRB[2]:activate.
                        if random() < BBIgn/100 if BoosterSingleEnginesRB[4]:hassuffix("activate") BoosterSingleEnginesRB[4]:activate.
                        if random() < BBIgn/100 if BoosterSingleEnginesRB[6]:hassuffix("activate") BoosterSingleEnginesRB[6]:activate.
                        if random() < BBIgn/100 if BoosterSingleEnginesRB[8]:hassuffix("activate") BoosterSingleEnginesRB[8]:activate.
                        if random() < BBIgn/100 if BoosterSingleEnginesRB[10]:hassuffix("activate") BoosterSingleEnginesRB[10]:activate.
                        if random() < BBIgn/100 if BoosterSingleEnginesRB[12]:hassuffix("activate") BoosterSingleEnginesRB[12]:activate.
                        if random() < BBIgn/100 if BoosterSingleEnginesRB[14]:hassuffix("activate") BoosterSingleEnginesRB[14]:activate.
                        if random() < BBIgn/100 if BoosterSingleEnginesRB[16]:hassuffix("activate") BoosterSingleEnginesRB[16]:activate.
                        if random() < BBIgn/100 if BoosterSingleEnginesRB[18]:hassuffix("activate") BoosterSingleEnginesRB[18]:activate.
                        when time:seconds - tEngStart > 1.2 then {
                            if random() < BBIgn/100 if BoosterSingleEnginesRB[1]:hassuffix("activate") BoosterSingleEnginesRB[1]:activate.
                            if random() < BBIgn/100 if BoosterSingleEnginesRB[3]:hassuffix("activate") BoosterSingleEnginesRB[3]:activate.
                            if random() < BBIgn/100 if BoosterSingleEnginesRB[5]:hassuffix("activate") BoosterSingleEnginesRB[5]:activate.
                            if random() < BBIgn/100 if BoosterSingleEnginesRB[7]:hassuffix("activate") BoosterSingleEnginesRB[7]:activate.
                            if random() < BBIgn/100 if BoosterSingleEnginesRB[9]:hassuffix("activate") BoosterSingleEnginesRB[9]:activate.
                            if random() < BBIgn/100 if BoosterSingleEnginesRB[11]:hassuffix("activate") BoosterSingleEnginesRB[11]:activate.
                            if random() < BBIgn/100 if BoosterSingleEnginesRB[13]:hassuffix("activate") BoosterSingleEnginesRB[13]:activate.
                            if random() < BBIgn/100 if BoosterSingleEnginesRB[15]:hassuffix("activate") BoosterSingleEnginesRB[15]:activate.
                            if random() < BBIgn/100 if BoosterSingleEnginesRB[17]:hassuffix("activate") BoosterSingleEnginesRB[17]:activate.
                            if random() < BBIgn/100 if BoosterSingleEnginesRB[19]:hassuffix("activate") BoosterSingleEnginesRB[19]:activate.
                        }
                    }
                }
                else {
                    if Block3Cluster Mid2GimbMod:SetField("gimbal limit", 90).
                    MidGimbMod:SetField("gimbal limit", 90).
                    MidGimbMod:doaction("free gimbal", true).
                    set tEngStart to time:seconds.
                    BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("previous engine mode", true).
                    // Если промежуточная ступень уже перевела на 13, до полной
                    // связки остаётся ОДИН шаг - иначе режим проскочит мимо.
                    when time:seconds - tEngStart > 0.95 then {
                        set Mode to "".
                        if BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):hasfield("Mode") {
                            set Mode to BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):getfield("Mode").
                        }
                        if Mode = "All Engines" or Mode = "All" or Mode = "Outer Twenty" or Mode = "OuterTwenty" {}
                        else BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("previous engine mode", true).
                    }
                }
                when ship:groundspeed < 120 then {
                    if BoosterSingleEngines {
                        set tEngStop to time:seconds.
                        if random() < BBIgn/100 if BoosterSingleEnginesRB[0]:hassuffix("activate") BoosterSingleEnginesRB[0]:shutdown.
                        if random() < BBIgn/100 if BoosterSingleEnginesRB[2]:hassuffix("activate") BoosterSingleEnginesRB[2]:shutdown.
                        if random() < BBIgn/100 if BoosterSingleEnginesRB[4]:hassuffix("activate") BoosterSingleEnginesRB[4]:shutdown.
                        if random() < BBIgn/100 if BoosterSingleEnginesRB[6]:hassuffix("activate") BoosterSingleEnginesRB[6]:shutdown.
                        if random() < BBIgn/100 if BoosterSingleEnginesRB[8]:hassuffix("activate") BoosterSingleEnginesRB[8]:shutdown.
                        if random() < BBIgn/100 if BoosterSingleEnginesRB[10]:hassuffix("activate") BoosterSingleEnginesRB[10]:shutdown.
                        if random() < BBIgn/100 if BoosterSingleEnginesRB[12]:hassuffix("activate") BoosterSingleEnginesRB[12]:shutdown.
                        if random() < BBIgn/100 if BoosterSingleEnginesRB[14]:hassuffix("activate") BoosterSingleEnginesRB[14]:shutdown.
                        if random() < BBIgn/100 if BoosterSingleEnginesRB[16]:hassuffix("activate") BoosterSingleEnginesRB[16]:shutdown.
                        if random() < BBIgn/100 if BoosterSingleEnginesRB[18]:hassuffix("activate") BoosterSingleEnginesRB[18]:shutdown.
                        when time:seconds - tEngStop > 0.3 then {
                            if random() < BBIgn/100 if BoosterSingleEnginesRB[1]:hassuffix("activate") BoosterSingleEnginesRB[1]:shutdown.
                            if random() < BBIgn/100 if BoosterSingleEnginesRB[3]:hassuffix("activate") BoosterSingleEnginesRB[3]:shutdown.
                            if random() < BBIgn/100 if BoosterSingleEnginesRB[5]:hassuffix("activate") BoosterSingleEnginesRB[5]:shutdown.
                            if random() < BBIgn/100 if BoosterSingleEnginesRB[7]:hassuffix("activate") BoosterSingleEnginesRB[7]:shutdown.
                            if random() < BBIgn/100 if BoosterSingleEnginesRB[9]:hassuffix("activate") BoosterSingleEnginesRB[9]:shutdown.
                            if random() < BBIgn/100 if BoosterSingleEnginesRB[11]:hassuffix("activate") BoosterSingleEnginesRB[11]:shutdown.
                            if random() < BBIgn/100 if BoosterSingleEnginesRB[13]:hassuffix("activate") BoosterSingleEnginesRB[13]:shutdown.
                            if random() < BBIgn/100 if BoosterSingleEnginesRB[15]:hassuffix("activate") BoosterSingleEnginesRB[15]:shutdown.
                            if random() < BBIgn/100 if BoosterSingleEnginesRB[17]:hassuffix("activate") BoosterSingleEnginesRB[17]:shutdown.
                            if random() < BBIgn/100 if BoosterSingleEnginesRB[19]:hassuffix("activate") BoosterSingleEnginesRB[19]:shutdown.
                            for eng in BoosterSingleEnginesRB if eng:hassuffix("activate") eng:shutdown.
                        }
                    }
                    else {
                        BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("next engine mode", true).
                    }
                }
            }
        }
        when time:seconds > flipStartTime + FlipTime*0.75 or vAng(facing:forevector, vxcl(up:vector, -ErrorVector)) < 90 then {
            set ship:control:neutralize to true.
            set steeringmanager:maxstoppingtime to 1 + FlipAngle/(300*Scale) * FlipTime.
        }

        //show Poll HUD
        //activate yaw and neutralize on
        when time:seconds > flipStartTime + FlipTime or vAng(facing:forevector, -vxcl(up:vector,velocity:surface)) < 60 
                or vAng(vxcl(up:vector, -ErrorVector),facing:forevector) < 70 and vAng(up:vector,facing:forevector) > 90 then {
            set steeringmanager:yawtorquefactor to 0.9.
            set steeringmanager:maxstoppingtime to 1*Scale + FlipAngle/(260*Scale) * FlipTime.
            set steeringManager:rollcontrolanglerange to 70.
            // По телеметрии крен сходился всего ~6 град/с и за буст-бэк не успевал
            // добрать 105 градусов до перевёрнутого положения. Момента не хватало,
            // логика была верной, поэтому усиливаем именно канал крена.
            set steeringManager:rolltorquefactor to 14.
            set SteeringManager:rollts to 2.
            lock throttle to 0.75.
            set FC to true.
            if not fullAuto bGUI:show().
            if fullAuto bGUI:hide().
        }
        when time:seconds > flipStartTime + FlipTime * 1.24 then {
            set steeringmanager:maxstoppingtime to 0.8 + FlipAngle/(220*Scale) * FlipTime.
            unlock FlipAngle.
        }

        //increase yaw steering
        when time:seconds > flipStartTime + 10 then {
            set steeringmanager:yawtorquefactor to 0.7.
            set steeringmanager:maxstoppingtime to 0.6.
            set config:ipu to 1500.
            rcs on.
        }
        when BoostBackComplete then 
            set steeringmanager:yawtorquefactor to 0.1.

        when ((time:seconds > flipStartTime + 45 and RSS) or (time:seconds > flipStartTime + 55 and KSRSS)) or (time:seconds > flipStartTime + 50 and not (RSS or KSRSS)) then {
            if not fullAuto Go:hide().
            set NoGo:text to "<color=red>ABORT</color>".
            if not GfC and not fullAuto {
                NoGo:hide().
            }
        }
        when time:seconds > flipStartTime + 140 then { 
            set steeringmanager:yawtorquefactor to 1.
        }
        
        set SteeringManager:pitchtorquefactor to 1.
        SteeringCorrections().
        

        until vang(vxcl(up:vector, facing:forevector), vxcl(up:vector, -ErrorVector)) < 98 and AllSet or verticalspeed < -50 {
            SteeringCorrections().
            if ship:partsnamed(HSRpartname):length = 0 {
                set ship:name to "Booster".
                set Block1HSR to true.
            }
            //set ErrorVectorDraw to vecdraw(v(0,0,0), -40 * ErrorVector:normalized, blue, "ErrorVector", 20, true, 0.005, true, true).
            if (RadarAlt < 95000 and RSS) or (RadarAlt < 69000 and not (RSS)) {
                if kuniverse:timewarp:warp > 0 {set kuniverse:timewarp:warp to 0.}
            }
            if ErrorVector = v(0,0,0) and not FailureMessage and time:seconds > flipStartTime + 1 {
                //HUDTEXT("FAR failure! Please restart KSP..", 30, 2, 22, red, false).
                set FailureMessage to true.
            }
            rcs on.
            if FC PollUpdate().
            wait 0.05.
        }


        if RSS {
            lock throttle to max(min(-(LngError + BoosterGlideDistance - 1000) / 5000 + 0.01, 10 * 9.81 / (max(ship:availablethrust, 0.000001) / ship:mass)), 0.33).
        }
        else {
            lock throttle to max(min(-(LngError + BoosterGlideDistance - 1000) / 2500 + 0.01, 10 * 9.81 / (max(ship:availablethrust, 0.000001) / ship:mass)), 0.33).
        }
        lock SteeringVector to lookdirup(vxcl(up:vector, -ErrorVector) + (targetAp-apoapsis)*up:vector*(ErrorVector:mag/32000*Scale), -up:vector).
        lock steering to SteeringVector.


        when time:seconds > flipStartTime + 30 then {
            // Слив топлива во время работы двигателей убран - он даёт боковую тягу
            // и его приходится парировать RCS. Слив перенесён в glide-фазу (см. ниже).
            set config:ipu to 1500.
            set steeringManager:showfacingvectors to false.
            set steeringManager:showangularvectors to false.
        }
        when ship:groundspeed < 50 then {
            if RSS {
                lock throttle to min(0.8,max(min((-(LngError + BoosterGlideDistance - 1000) / 5000 + 0.01), (10 * 9.81 / (max(ship:availablethrust, 0.000001) / ship:mass))), 0.33)).
            }
            else {
                lock throttle to min(0.8,max(min((-(LngError + BoosterGlideDistance - 1000) / 2500 + 0.01), (10 * 9.81 / (max(ship:availablethrust, 0.000001) / ship:mass))), 0.33)).
            }
        }
        set changed to false.
        set lastCheck to GfC.
        set FailTimer to time:seconds.

        until (ErrorVector:mag < BoosterGlideDistance + 5400 * Scale) or verticalspeed < -60 or BoostBackComplete {
            if not GfC = lastCheck {
                set changed to true.
                set lastCheck to GfC.
            }
            if GfC and changed {
                setLandingZone().
                setTargetOLM().
                set changed to false.
            }
            else if not GfC and changed or cAbort {
                set landingzone to offshoreSite.
                set changed to false.
            }
            if random() < ifIgn/200 and BoosterSingleEngines and time:seconds - FailTimer > 3 {
                set FailTimer to time:seconds.
                set failedEngNr to 1+floor(random()*12).
                if BoosterSingleEnginesRC[failedEngNr-1]:hassuffix("activate") BoosterSingleEnginesRC[failedEngNr-1]:shutdown.
            } else set FailTimer to time:seconds.
            SteeringCorrections().
            set SteeringVectorBoostback to lookdirup(vxcl(up:vector, -ErrorVector), -up:vector * angleAxis(0,facing:forevector)).
            if kuniverse:timewarp:warp > 1 and LngError < -14000*Scale {set kuniverse:timewarp:warp to 1.}
            else if kuniverse:timewarp:warp > 0 and LngError > -14000*Scale {set kuniverse:timewarp:warp to 0.}
            PollUpdate().
            SetBoosterActive().
            wait 0.05.
        }

        if BoosterSingleEngines
            if missingCount > 1 
                set HighLandingBurn to true.


        if BoosterSingleEngines {
            set x to 1.
            for eng in BoosterSingleEnginesRC {
                if x = 1 or x = 2 or x = 3 {} else {
                    if eng:hassuffix("activate") {
                        eng:shutdown.
                        set eng:gimbal:lock to true.
                    }
                }
                set x to x + 1.
            }
        }
        else {
            BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("next engine mode", true).
            MidGimbMod:doaction("lock gimbal", true).
            wait 0.
            if Block3Cluster {
                Mid2GimbMod:doaction("lock gimbal", true).
                BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("next engine mode", true).
            }
        }
        // Вентиль на всём буст-бэке держим закрытым, слив будет только в glide.
        if SinglePartBooster BoosterCore:shutdown.
        else for vent in DumpVents if not vent:istype("Boolean") vent:doaction("shutdown engine", true).
        set steeringManager:rolltorquefactor to 2.
        if HSRType:contains("Block3") set HSRJet to false.

        if HSRJet set BoosterGlideDistance to BoosterGlideDistance * 0.93.

        until (LngError + 50 > -BoosterGlideDistance and LFBooster < LFBoosterFuelCutOff * 2) or (LngError + 50 > -BoosterGlideDistance*1.04) or verticalspeed < -280 or BoostBackComplete {
            if not GfC = lastCheck {
                set changed to true.
                set lastCheck to GfC.
            }
            if GfC and changed {
                setLandingZone().
                setTargetOLM().
                set changed to false.
            }
            else if not GfC and changed or cAbort {
                set landingzone to offshoreSite.
                set changed to false.
            }
            SteeringCorrections().
            set SteeringVectorBoostback to lookdirup(vxcl(up:vector, -ErrorVector), -up:vector * angleAxis(0,facing:forevector)).
            if kuniverse:timewarp:warp > 0 {set kuniverse:timewarp:warp to 0.}
            PollUpdate().
            SetBoosterActive().
            wait 0.03.
        }
        if BoosterSingleEngines {
            set x to 1.
            until x > 3 {
                if BoosterSingleEnginesRC[x-1]:hassuffix("activate") {
                    BoosterSingleEnginesRC[x-1]:shutdown.
                    set BoosterSingleEnginesRC[x-1]:gimbal:lock to true.
                }
                set x to x + 1.
            }
        }
        unlock throttle.
        lock throttle to 0.
        set BoostBackComplete to true.


        PollUpdate().

        if GfC and HSRJet {
            HUDTEXT("GO for Catch, HSR-Jettison", 8, 2, 20, green, false).
            if not KSRSS and not RSS {
                set LngCtrlPID:setpoint to LngCtrlPID:setpoint + 15.
            } else {
                set LngCtrlPID:setpoint to LngCtrlPID:setpoint + 12.
            }
        } else if GfC and not HSRJet {
            HUDTEXT("GO for Catch, NO HSR-Jettison", 8, 2, 20, green, false).
            if not KSRSS and not RSS {
                set LngCtrlPID:setpoint to LngCtrlPID:setpoint + 10.
            } else {
                set LngCtrlPID:setpoint to LngCtrlPID:setpoint + 8.
            }
        } else if not GfC and HSRJet {
            if WobblyBooster {HUDTEXT("Wobbly Booster Detected", 8, 2, 20, red, false).}
            HUDTEXT("Booster offshore divert, HSR-Jettison", 8, 2, 20, yellow, false).
            set offshoreDivert to true.
        } else if not GfC and not HSRJet {
            if WobblyBooster {HUDTEXT("Wobbly Booster Detected", 8, 2, 20, red, false).}
            HUDTEXT("Booster offshore divert, NO HSR-Jettison", 8, 2, 20, yellow, false).
            set offshoreDivert to true.
        }

        if offshoreDivert and highSplash
            lock RadarAlt to alt:radar - RadarAltOffset - MZHeight.


        if not BoosterSingleEngines and Bl3LndProf and not BoosterType:contains("Block3") set Bl3LndProf to false.

        
        if GfC {
            when not GfC then {
                if RadarAlt < 6000 {}
                else {
                    set cAbort to true.
                    set landingzone to offshoreSite.
                    addons:tr:settarget(landingzone).
                    NoGo:hide().
                    if RadarAlt > 18000 {HUDTEXT("Booster offshore divert", 10, 2, 20, red, false).}
                    set ApproachUPVector to (landingzone:position - body:position):normalized.
                    set ApproachVector to vxcl(up:vector, landingzone:position - ship:position):normalized.
                    if (ErrorVector:mag < BoosterGlideDistance or ErrorVector:mag > 1.8*BoosterGlideDistance) and not GfC {
                        if vAng(GSVec,vCrs(north:vector,up:vector)) < 90 and vAng(GSVec,north:vector) < 90 set landingzone to 
                            latlng(addons:tr:impactpos:lat + min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
                                    addons:tr:impactpos:lng - min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
                        else if vAng(GSVec,vCrs(north:vector,up:vector)) < 90 and vAng(GSVec,north:vector) > 90 set landingzone to 
                            latlng(addons:tr:impactpos:lat - min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
                                    addons:tr:impactpos:lng - min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
                        else if vAng(GSVec,vCrs(north:vector,up:vector)) > 90 and vAng(GSVec,north:vector) < 90 set landingzone to 
                            latlng(addons:tr:impactpos:lat - min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
                                    addons:tr:impactpos:lng + min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
                        else set landingzone to 
                            latlng(addons:tr:impactpos:lat + min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
                                    addons:tr:impactpos:lng + min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
                        addons:tr:settarget(landingzone).
                    }
                }
            }
        } else {
            set landingzone to offshoreSite.
            addons:tr:settarget(landingzone).
            NoGo:hide().
            SteeringCorrections().
            if ErrorVector:mag < BoosterGlideDistance {
                if vAng(GSVec,vCrs(north:vector,up:vector)) < 90 and vAng(GSVec,north:vector) < 90 set landingzone to 
                    latlng(addons:tr:impactpos:lat + min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
                            addons:tr:impactpos:lng - min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
                else if vAng(GSVec,vCrs(north:vector,up:vector)) < 90 and vAng(GSVec,north:vector) > 90 set landingzone to 
                    latlng(addons:tr:impactpos:lat - min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
                            addons:tr:impactpos:lng - min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
                else if vAng(GSVec,vCrs(north:vector,up:vector)) > 90 and vAng(GSVec,north:vector) < 90 set landingzone to 
                    latlng(addons:tr:impactpos:lat - min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
                            addons:tr:impactpos:lng + min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
                else set landingzone to 
                    latlng(addons:tr:impactpos:lat + min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
                            addons:tr:impactpos:lng + min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
                addons:tr:settarget(landingzone).
            }
        }

        if (abs(LngError - LngCtrlPID:setpoint) > BoosterGlideDistance) and not GfC {
            set landingzone to addons:tr:IMPACTPOS.
            if ErrorVector:mag < 2*BoosterGlideDistance {
                if vAng(GSVec,vCrs(north:vector,up:vector)) < 90 and vAng(GSVec,north:vector) < 90 set landingzone to 
                    latlng(addons:tr:impactpos:lat + min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
                            addons:tr:impactpos:lng - min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
                else if vAng(GSVec,vCrs(north:vector,up:vector)) < 90 and vAng(GSVec,north:vector) > 90 set landingzone to 
                    latlng(addons:tr:impactpos:lat - min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
                            addons:tr:impactpos:lng - min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
                else if vAng(GSVec,vCrs(north:vector,up:vector)) > 90 and vAng(GSVec,north:vector) < 90 set landingzone to 
                    latlng(addons:tr:impactpos:lat - min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
                            addons:tr:impactpos:lng + min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
                else set landingzone to 
                    latlng(addons:tr:impactpos:lat + min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
                            addons:tr:impactpos:lng + min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
                addons:tr:settarget(landingzone).
            }
            addons:tr:settarget(landingzone).
            set LandSomewhereElse to true.
        }


        wait 0.01.

        
        
        set turnTime to time:seconds.

        if not BoosterSingleEngines CtrGimbMod:doaction("lock gimbal", true).

        set Planet1G to CONSTANT():G * (ship:body:mass / (ship:body:radius * ship:body:radius)).

        set SteeringManager:pitchtorquefactor to 1.
        set SteeringManager:yawtorquefactor to 0.1.
        

        // (слив топлива здесь не включаем - бустер ещё разворачивается)

        if HSRType:contains("Block3") set HSRJet to false.

        if HSRJet set RadarAltOffset to BoosterHeight * 0.6.
        else set RadarAltOffset to BoosterHeight.

        bCH4Tank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 60).
        FWD:getmodule("ModuleRCSFX"):SetField("thrust limiter", 60).
        if BoosterType:contains("Block3") or ship:partsnamed("FNB.BL1.BOOSTERLOX"):length > 0 bCMNDome:getmodule("ModuleRCSFX"):SetField("thrust limiter", 60).

        if not Bl3LndProf {
            set LFBoosterFuelCutOff to LFBoosterFuelCutOff*1.07.
        }

        set FuelDump to false.
        if HSRJet and defined HSR and not BoosterType:contains("Block3") {
            when time:seconds - turnTime > 2 then {
                FWD:getmodule("ModuleDecouple"):DOACTION("Decouple", true).
                set RenameHSR to false.
                wait 0.1.
                if not Block1HSR and kuniverse:activevessel:partsnamed("SEP.25.BOOSTER.CORE"):length = 0 and kuniverse:activevessel:partsnamed("SEP.23.BOOSTER.INTEGRATED"):length = 0 and kuniverse:activevessel:partsnamed("FNB.BL1.BOOSTERLOX"):length = 0 {
                    set RenameHSR to true.
                    kuniverse:forceactive(vessel("Booster Ship")).
                    HUDTEXT("Switching focus back to Booster - " + Block1HSR, 16, 2, 20, yellow, false).
                } 
                HUDTEXT("HSR-Jettison confirmed.. Rotating Booster for re-entry and landing..", 20, 2, 20, green, false).
                set Rotating to true.
                if not Block1HSR and RenameHSR {
                    if vessel("Booster"):partsnamed(HSRpartname):length > 0 set vessel("Booster"):name to "Booster HSR".
                }
                if kuniverse:activevessel:partsnamed(HSRpartname):length = 0 set kuniverse:activevessel:name to "Booster".
                set ShortBurst to time:seconds.
                rcs on.
                when ShortBurst + 1.4 < time:seconds then rcs off.
            }
        }
        else if defined HSR {
            set LFBoosterFuelCutOff to LFBoosterFuelCutOff*1.03.
        }

        if not HSRJet set turnTime to turnTime - 10.
        set CurrentVec to ship:facing:forevector.
        set LeftVector to ship:facing:starvector.

        when time:seconds - turnTime > 1.8 then {
            if ship:partsnamed("FNB.BL1.BOOSTERLOX"):length = 0 and ship:partsnamed("FNB.BL3.BOOSTERLOX"):length = 0 if BoosterCore:thrust > 0 {
                BoosterCore:shutdown.
                set FuelDump to true.
            }
            else if FWD:thrust > 0 {
                for vent in DumpVents if not vent:istype("Boolean") vent:doaction("shutdown engine", true).
                set FuelDump to true.
            }
            wait 0.01.
            // Раннее включение слива убрано: вентиль открывается один раз,
            // после того как бустер уже стабилизировался в позе для glide.
        }
        
        when time:seconds - turnTime > 0.5 then {
            
            if HSRJet rcs off.

            set SteeringManager:maxstoppingtime to 4.
            // Разворот в позу glide переписан.
            //
            // Было: открытый цикл. Нос и опорный "верх" крутились двумя
            // отдельными angleAxis по 2 гр/с вокруг оси, замороженной в момент
            // turnTime, а опорой шёл -ApproachVector. В начале разворота нос
            // стоит РОВНО на цели, то есть вдоль +ApproachVector - опора и нос
            // почти антипараллельны, lookDirUp на таких векторах вырождается и
            // выдаёт крен, какой получится. Плюс множитель времени не имел
            // конца: опора продолжала уезжать и после того, как нос пришёл.
            //
            // Стало: цель сразу конечная - та самая рама, в которой идёт
            // планирование (нос от площадки, "верх" = ApproachVector). Она
            // невырождена (нос почти вертикален, ApproachVector горизонтален),
            // одна и та же до самого glide, и SteeringManager ведёт к ней
            // тангаж и крен ОДНОВРЕМЕННО. Скорость разворота ограничивает
            // maxstoppingtime, как и раньше.
            lock SteeringVector to lookDirUp(BoosterCore:position - landingzone:position, ApproachVector).
            lock steering to SteeringVector.
            unlock SteeringVectorBoostback.
            // Крен ведём с первой секунды разворота. По умолчанию kOS сначала
            // доводит наведение и только у самой цели берётся за крен - это и
            // есть тот отдельный доворот на 90, который видно уже в glide.
            set steeringManager:rollcontrolanglerange to 180.
            set steeringManager:rolltorquefactor to 8.
            set SteeringManager:rollts to 2.
            // Снимаем заморозку принудительно, не дожидаясь, пока ошибка сама
            // опустится ниже порога возврата: с конца буст-бэка она бывает и
            // 175 гр., то есть выше порога, и крен так и остался бы выключен
            // на весь разворот.
            set RollFrozen to false.
            set RollNote to "".
        }
        when vAng(vxcl(vCrs(up:vector, vxcl(up:vector, BoosterCore:position - landingzone:position)),facing:forevector), BoosterCore:position - landingzone:position) < 25 then {
            if RadarAlt > 32000 {
                lock SteeringVector to lookDirUp(BoosterCore:position - landingzone:position, ApproachVector).
            }
        }


        until vang(facing:forevector, up:vector) < 50 or not HSRJet {
            SteeringCorrections().
            PollUpdate().
            SetBoosterActive().
            if time:seconds - turnTime > 5 rcs on.
            if kuniverse:timewarp:warp > 0 {set kuniverse:timewarp:warp to 0.}
            if LFBooster < LFBoosterFuelCutOff {
                if ship:partsnamed("FNB.BL1.BOOSTERLOX"):length = 0 and ship:partsnamed("FNB.BL3.BOOSTERLOX"):length = 0 BoosterCore:shutdown.
                else for vent in DumpVents if not vent:istype("Boolean") vent:doaction("shutdown engine", true).
            }
            wait 0.067.
        }
        HUDTEXT("Booster Coast Phase - Timewarp available", 15, 2, 20, green, false).
        set config:ipu to 1600.
        FWD:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).
        if BoosterType:contains("Block3") or ship:partsnamed("FNB.BL1.BOOSTERLOX"):length > 0 bCMNDome:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).

        
        set SteeringManager:yawtorquefactor to 0.1.
        // Крен к этому моменту уже доведён вместе с разворотом (диапазон 180
        // выставлен там же, где ставится цель). Здесь только не сужаем его
        // обратно, иначе остаток ошибки опять замрёт до самого glide.
        set steeringManager:rollcontrolanglerange to 180.
        set steeringManager:rolltorquefactor to 4.

        set SteeringManager:maxstoppingtime to 2.4.
        if RSS 
            set SteeringManager:maxstoppingtime to 4.2.

        when steeringManager:angleerror < 90 then
            set SteeringManager:yawtorquefactor to 0.3.

        // Выходим из coast только когда доведён И тангаж/рыскание, И КРЕН.
        // Раньше условие смотрело лишь angleerror (это ошибка наведения, крен в
        // неё не входит), поэтому glide начинался с неубранным креном.
        // Жёсткий таймаут 75 с - чтобы цикл не завис, если крен не сходится.
        // verticalspeed < 0 - обязательное условие выхода. Наведение
        // планирования строится от -velocity:surface, а пока бустер идёт вверх,
        // этот вектор смотрит ВНИЗ и вся рама переворачивается на 180.
        // Полёт 04.09: крен сошёлся до 4.6 уже на MET 141.1, цикл вышел, и на
        // 141.6 рама перевернулась - RollErr 178 и заморожен всю верхнюю часть
        // спуска. Раньше это не вылезало только потому, что крен сходился на
        // 20 секунд позже и цикл сам досиживал до апогея.
        until (time:seconds - turnTime > 15 and steeringManager:angleerror < 45 and abs(steeringManager:rollerror) < 10 and verticalspeed < 0) or time:seconds - turnTime > 120 {
            SteeringCorrections().
            PollUpdate().
            SetBoosterActive().
            rcs on.
            if kuniverse:timewarp:warp > 1 {set kuniverse:timewarp:warp to 1.}
            CheckFuel().
            wait 0.067.
        }
        // Coast: двигатели выключены, бустер развёрнут и стабилизирован - вот
        // здесь и сливаем лишнее. Вентиль сам закроется в CheckFuel(), когда
        // остаток дойдёт до LFBoosterFuelCutOff (посадочный резерв).
        // До этого момента CheckFuel() держит вентиль закрытым принудительно.
        // Вентиль открываем ТОЛЬКО когда нос выше горизонта. Слив идёт вперёд,
        // и если бустер смотрит вниз, струя толкает его не в ту сторону.
        // Само разрешение ставим здесь, а открытие/закрытие по тангажу дальше
        // ведёт CheckFuel() - она вызывается в каждом цикле спуска, поэтому
        // вентиль сам закроется, если бустер завалится носом вниз, и снова
        // откроется, когда поднимет нос.
        set VentAllowed to true.
        if LFBooster > LFBoosterFuelCutOff and vdot(ship:facing:forevector, up:vector) > 0 {
            if SinglePartBooster BoosterCore:activate.
            else for vent in DumpVents if not vent:istype("Boolean") vent:doaction("activate engine", true).
        }
        set SteeringManager:yawtorquefactor to 0.6.
        bCH4Tank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).
        set SteeringManager:maxstoppingtime to 2.
        if RSS 
            set SteeringManager:maxstoppingtime to 3.2.

        set switchTime to time:seconds.
        until time:seconds > switchTime + 0.5 {
            SteeringCorrections().
            rcs on.
            SetBoosterActive().
            PollUpdate().
            wait 0.067.
        }

        HUDTEXT("Starship will continue its orbit insertion..", 10, 2, 20, green, false).

        until time:seconds > switchTime + 2 {
            SteeringCorrections().
            rcs on.
            SetBoosterActive().
            PollUpdate().
            wait 0.067.
        }

        bCH4Tank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 15).
        FWD:getmodule("ModuleRCSFX"):SetField("thrust limiter", 15).
        if BoosterType:contains("Block3") or ship:partsnamed("FNB.BL1.BOOSTERLOX"):length > 0 bCMNDome:getmodule("ModuleRCSFX"):SetField("thrust limiter", 15).
    }
    else {
        lock steering to facing:forevector.
        set rebooted to true.
    }
    PollUpdate().
    wait 0.05.

    if GfC and rebooted {
        setLandingZone().
        setTargetOLM().
        SteeringCorrections().
        if verticalSpeed < 0 set BoostBackComplete to true.
        if abs(LngError) > 3*BoosterGlideDistance set GfC to false.
        when not GfC then {
            if RadarAlt < 6000 {}
            else {
                set cAbort to true.
                set landingzone to offshoreSite.
                addons:tr:settarget(landingzone).
                NoGo:hide().
                if RadarAlt > 5000 {HUDTEXT("Booster offshore divert", 10, 2, 20, red, false).}
                set ApproachUPVector to (landingzone:position - body:position):normalized.
                set ApproachVector to vxcl(up:vector, landingzone:position - ship:position):normalized.
            }
        }
    } else if not GfC and rebooted {
        setLandingZone().
        set landingzone to offshoreSite.
        addons:tr:settarget(landingzone).
        NoGo:hide().
        if ErrorVector:mag < BoosterGlideDistance {
            if vAng(GSVec,vCrs(north:vector,up:vector)) < 90 and vAng(GSVec,north:vector) < 90 set landingzone to 
                latlng(addons:tr:impactpos:lat + min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
                        addons:tr:impactpos:lng - min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
            else if vAng(GSVec,vCrs(north:vector,up:vector)) < 90 and vAng(GSVec,north:vector) > 90 set landingzone to 
                latlng(addons:tr:impactpos:lat - min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
                        addons:tr:impactpos:lng - min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
            else if vAng(GSVec,vCrs(north:vector,up:vector)) > 90 and vAng(GSVec,north:vector) < 90 set landingzone to 
                latlng(addons:tr:impactpos:lat - min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
                        addons:tr:impactpos:lng + min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
            else set landingzone to 
                latlng(addons:tr:impactpos:lat + min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
                        addons:tr:impactpos:lng + min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
            addons:tr:settarget(landingzone).
        }
    }
    if rebooted {
        if not Bl3LndProf {
            set LFBoosterFuelCutOff to LFBoosterFuelCutOff*1.07.
        }
        if defined HSR {
            set BoosterReturnMass to BoosterReturnMass + HSR:mass.
            set LFBoosterFuelCutOff to LFBoosterFuelCutOff*1.03.
        }
    }

    if not (starship = "xxx") {
        list targets in tlist.
        for tgt in tlist {
            if tgt:name:contains(starship) {
                if not (devMode) {
                    //KUniverse:forceactive(vessel(starship)).
                }
                set StarshipExists to true.
            }
        }
    }
    else {
        if homeconnection:isconnected {
            if exists("0:/settings.json") {
                set L to readjson("0:/settings.json").
                set starship to L["Ship Name"].
                if not (starship = "xxx") and not (devMode) {
                    //KUniverse:forceactive(vessel(starship)).
                }
                //else {
                    //print "Couldn't find vessel".
                    //wait 2.5.
                //}
            }
        }
    }
    lock GSVec to vxcl(up:vector,velocity:surface).

    //if kuniverse:timewarp:warp > 0 {set kuniverse:timewarp:warp to 0.}

    set OneTime to true.


    if not fullAuto bGUI:show().
    when ((time:seconds > flipStartTime + 45 and RSS) or (time:seconds > flipStartTime + 55 and KSRSS)) or (time:seconds > flipStartTime + 40 and not (RSS or KSRSS)) then {
        if not fullAuto Go:hide().
        set NoGo:text to "<color=red>ABORT</color>".
        if not GfC and not fullAuto {
            NoGo:hide().
        }
    }

    if not TargetOLM = "False" when alt:radar < 42000 * Scale then if not TargetOLM = "False" {
        //hudtext("Loading Tower..",3,2,16,yellow,true).
        set Vessel(TargetOLM):loaddistance:landed:load to 61000*Scale.
        set Vessel(TargetOLM):loaddistance:prelaunch:load to 61000*Scale.
        set Vessel(TargetOLM):loaddistance:landed:unpack to 60000*Scale.
        set Vessel(TargetOLM):loaddistance:prelaunch:unpack to 60000*Scale.
        when Vessel(TargetOLM):loaded then {
            set TgtLandingzone to landingzone.
            if Vessel(TargetOLM):partsnamed("OLM.B2"):length > 0 set PadB to true.
            if PadB set TheTowerHeadingVector to TowerHeadingFrom(Vessel(TargetOLM)).
            else set TheTowerHeadingVector to vxcl(Vessel(TargetOLM):up:vector, Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position - Vessel(TargetOLM):PARTSTITLED("Starship Orbital Launch Integration Tower Base")[0]:position).
            //set TowerHeadDraw to vecDraw(BoosterCore:position,TowerHeadingVector,red,"Tower",2,true,0.2).
            // Насколько новая опора (ориентация детали) разошлась со старой
            // (разность позиций). Ожидаем около 4 гр на Pad B. Ноль означает,
            // что facing совпал с позиционной опорой, 90 - что выбрана не та ось.
            if PadB print "Tower hdg fix: " + round(vAng(TheTowerHeadingVector, vxcl(Vessel(TargetOLM):up:vector, TowerMZpart(Vessel(TargetOLM)):position - TowerBasePart(Vessel(TargetOLM)):position)), 2) + " deg".
            if vAng(TheTowerHeadingVector, Vessel(TargetOLM):north:vector) < 52 set TowerHeading to "North".
            else if vAng(TheTowerHeadingVector, Vessel(TargetOLM):north:vector) > 128 set TowerHeading to "South".
            else if vAng(TheTowerHeadingVector, vCrs(Vessel(TargetOLM):up:vector, Vessel(TargetOLM):north:vector)) < 42 set TowerHeading to "East".
            else set TowerHeading to "West".
            set dbactive to true.
            set Vessel(TargetOLM):loaddistance:landed:unpack to 1200.
            wait 0.
            set Vessel(TargetOLM):loaddistance:landed:pack to 1250.
            wait 0.001.
            set Vessel(TargetOLM):loaddistance:prelaunch:unpack to 1200.
            wait 0.
            set Vessel(TargetOLM):loaddistance:prelaunch:pack to 1250.
            wait 0.001.
            set Vessel(TargetOLM):loaddistance:landed:load to 2200.
            wait 0.
            set Vessel(TargetOLM):loaddistance:landed:unload to 3250.
            wait 0.001.
            set Vessel(TargetOLM):loaddistance:prelaunch:load to 2200.
            wait 0.
            set Vessel(TargetOLM):loaddistance:prelaunch:unload to 3250.
            wait 0.001.
            //hudtext("Unloading Tower.",3,2,16,green,true).
        }
    }

    when altitude < 42000 * Scale then ActivateGridFins().

    until altitude < 40000 and not (RSS or KSRSS) or altitude < 73000 and RSS or altitude < 56000 and KSRSS {
        SteeringCorrections().
        rcs on.
        PollUpdate().
        CheckFuel().
        
        if abs(steeringmanager:angleerror) > 10 {
            SetBoosterActive().
            bCH4Tank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 60).
            FWD:getmodule("ModuleRCSFX"):SetField("thrust limiter", 60).
            if BoosterType:contains("Block3") or ship:partsnamed("FNB.BL1.BOOSTERLOX"):length > 0 bCMNDome:getmodule("ModuleRCSFX"):SetField("thrust limiter", 60).
        }
        else if abs(steeringmanager:angleerror) < 0.25 and KUniverse:activevessel = ship {
            if TimeStabilized = "0" {
                set TimeStabilized to time:seconds.
                SetBoosterActive().
            }
            if time:seconds - TimeStabilized > 5 and OneTime { 
                //if kuniverse:timewarp:warp > 0 {set kuniverse:timewarp:warp to 0.}
                //SetStarshipActive().
                bCH4Tank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 24).
                FWD:getmodule("ModuleRCSFX"):SetField("thrust limiter", 24).
                if BoosterType:contains("Block3") or ship:partsnamed("FNB.BL1.BOOSTERLOX"):length > 0 bCMNDome:getmodule("ModuleRCSFX"):SetField("thrust limiter", 24).
                set TimeStabilized to 0.
                set OneTime to false.
            }
        }
        else {
            set TimeStabilized to 0.
        }
        if STOCK and altitude < 43000 {SetBoosterActive().}
        wait 0.05.
    }
    set steeringManager:rolltorquefactor to 1.
    set SteeringManager:yawtorquefactor to 1.
    when (RadarAlt < 69000 and RSS) or (RadarAlt < 35000 and not (RSS)) then {
        if kuniverse:timewarp:warp > 0 {set kuniverse:timewarp:warp to 1.}
    }
    if RSS 
        set SteeringManager:maxstoppingtime to 2.2.
    
    set steeringManager:rollcontrolanglerange to 15.
    set BoosterReturnMass to ship:mass.
    
    if (ErrorVector:mag < BoosterGlideDistance or ErrorVector:mag > 1.8*BoosterGlideDistance) and not GfC {
        if vAng(GSVec,vCrs(north:vector,up:vector)) < 90 and vAng(GSVec,north:vector) < 90 set landingzone to 
            latlng(addons:tr:impactpos:lat + min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
                    addons:tr:impactpos:lng - min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
        else if vAng(GSVec,vCrs(north:vector,up:vector)) < 90 and vAng(GSVec,north:vector) > 90 set landingzone to 
            latlng(addons:tr:impactpos:lat - min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
                    addons:tr:impactpos:lng - min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
        else if vAng(GSVec,vCrs(north:vector,up:vector)) > 90 and vAng(GSVec,north:vector) < 90 set landingzone to 
            latlng(addons:tr:impactpos:lat - min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
                    addons:tr:impactpos:lng + min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
        else set landingzone to 
            latlng(addons:tr:impactpos:lat + min(ship:altitude/(33000*Scale),1) * vxcl(vCrs(north:vector,up:vector),GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius),
                    addons:tr:impactpos:lng + min(ship:altitude/(33000*Scale),1) * vxcl(north:vector,GSVec):mag/GSVec:mag * BoosterGlideDistance * 360 / (2* constant:pi * ship:body:radius)).
        addons:tr:settarget(landingzone).
    }
    
    SetBoosterActive().
    set SteeringManager:yawtorquefactor to 0.8.
    set steeringManager:rolltorquefactor to 0.8.

    bCH4Tank:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).
    FWD:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).
    if BoosterType:contains("Block3") or ship:partsnamed("FNB.BL1.BOOSTERLOX"):length > 0 bCMNDome:getmodule("ModuleRCSFX"):SetField("thrust limiter", 100).
    
    lock SteeringVector to lookdirup(-velocity:surface * AngleAxis(-BoosterGlideFactor*LngCtrl, lookdirup(-velocity:surface, up:vector):starvector) * AngleAxis(LatCtrl, up:vector), ApproachVector * AngleAxis(2 * LatCtrl, up:vector)).
    
    set steeringManager:pitchpid:kd to 0.4.
    set steeringManager:yawpid:kd to 0.4.
    lock steering to SteeringVector.

    // Боковой канал упирался в потолок (в логе "LatCtrl: 6 / 6" при Lat Error -144),
    // то есть авторитета не хватало и промах по боку рос до самой посадки.
    set maxRoll to 12.

    until alt:radar < 34000 and RSS or alt:radar < 26000 and KSRSS or alt:radar < 21000 {
        SteeringCorrections().
        if altitude > 33000 and RSS or altitude > 28000 and not (RSS) and abs(steeringManager:angleerror) > 1 {
            rcs on.
        }
        else {
            rcs off.
        }
        PollUpdate().
        SetBoosterActive().
        CheckFuel().
        wait 0.05.
    }
    set steeringManager:pitchpid:kd to 0.16*Scale.
    set steeringManager:yawpid:kd to 0.18*Scale.
    set maxRoll to 10.


    lock SteeringVector to lookdirup(-velocity:surface * AngleAxis(-BoosterGlideFactor*0.9*Scale*LngCtrl, lookdirup(-velocity:surface, up:vector):starvector) * AngleAxis(LatCtrl, up:vector), ApproachVector * AngleAxis(2 * LatCtrl, up:vector)).
    when alt:radar < 24000 and RSS or 18000 then lock SteeringVector to lookdirup(-velocity:surface * AngleAxis(-BoosterGlideFactor*LngCtrl, lookdirup(-velocity:surface, up:vector):starvector) * AngleAxis(LatCtrl, up:vector), ApproachVector * AngleAxis(2 * LatCtrl, up:vector)).
    when LngError > -BoosterGlideDistance*0.24 then { 
        if not LandingBurnStarted lock SteeringVector to lookdirup(-velocity:surface * AngleAxis(-(0.6/(Scale^0.7))*BoosterGlideFactor*LngCtrl, lookdirup(-velocity:surface, up:vector):starvector) * AngleAxis(LatCtrl, up:vector), ApproachVector * AngleAxis(2 * LatCtrl, up:vector)).
        when LngError < -50*Scale then {
            if not LandingBurnStarted lock SteeringVector to lookdirup(-velocity:surface * AngleAxis(-(0.7/(Scale^0.5))*BoosterGlideFactor*LngCtrl, lookdirup(-velocity:surface, up:vector):starvector) * AngleAxis(LatCtrl, up:vector), ApproachVector * AngleAxis(2 * LatCtrl, up:vector)).
            when LngError > 12*Scale then {
                if not LandingBurnStarted lock SteeringVector to lookdirup(-velocity:surface * AngleAxis(-0.65*BoosterGlideFactor*LngCtrl, lookdirup(-velocity:surface, up:vector):starvector) * AngleAxis(LatCtrl, up:vector), ApproachVector * AngleAxis(2 * LatCtrl, up:vector)).
            }
        }
    }
    
    lock PositionError to vxcl(up:vector, BoosterCore:position - landingzone:position).


    lock steering to SteeringVector.
    unlock SteerVec1.
    unlock SteerVec2.

    when RadarAlt < 24000 then {
        if Bl3LndProf set LngCtrlPID:setpoint to LngCtrlPID:setpoint - 24*Scale.
        else set LngCtrlPID:setpoint to LngCtrlPID:setpoint - 16*Scale.
        set steeringManager:rolltorquefactor to 1.
        when RadarAlt < 8600*(Scale^0.75) then {
            if Bl3LndProf {
                set LngCtrlPID:setpoint to LngCtrlPID:setpoint + 8*Scale.
                set LngCtrlPID:setpoint to LngCtrlPID:setpoint + vAng(up:vector, ship:position-landingzone:position)*0.69.
            }
            else {
                set LngCtrlPID:setpoint to LngCtrlPID:setpoint + 24/Scale.
                set LngCtrlPID:setpoint to LngCtrlPID:setpoint + vAng(up:vector, ship:position-landingzone:position) * (1.6/Scale)^0.4 * (airspeed/600).
            }
            
            if not (TargetOLM = "false") {
                if PadB {
                    when Vessel(TargetOLM):distance < 2000 then {
                        if Vessel(TargetOLM):partsnamed("OLM.B2"):length > 0 set TowerRotationVector to vxcl(up:vector, Vessel(TargetOLM):partsnamed("OLM.B2")[0]:position - Vessel(TargetOLM):partsnamed("OLIT.2")[0]:position).
                        if Vessel(TargetOLM):partsnamed("OLM.B2"):length > 0 lock PositionError to vxcl(up:vector, BoosterCore:position - Vessel(TargetOLM):partstitled("OLM.B2")[0]:position).
                        if vAng(TowerRotationVector,PositionError) > 42 set HighIncl to true.
                        if not RSS {sendMessage(Vessel(TargetOLM), "MechazillaHeight,"+ 3*Scale + ",0.5").}
                        if not LZchange set MZHeight to vxcl(vCrs(north:vector, up:vector), vxcl(north:vector, landingzone:position - Vessel(TargetOLM):PARTSNAMED("PadB.Chopsticks")[0]:position)):mag.
                    }
                    when Vessel(TargetOLM):distance < 1800 then {
                        set Vessel(TargetOLM):loaddistance:landed:unpack to 1500.
                        set Vessel(TargetOLM):loaddistance:prelaunch:unpack to 1500.
                        if not LZchange set MZHeight to vxcl(vCrs(north:vector, up:vector), vxcl(north:vector, landingzone:position - Vessel(TargetOLM):PARTSNAMED("PadB.Chopsticks")[0]:position)):mag.
                    }
                }
                else {
                    when Vessel(TargetOLM):distance < 2000 then {
                        set TowerRotationVector to vxcl(up:vector, Vessel(TargetOLM):partstitled("Starship Orbital Launch Mount")[0]:position - Vessel(TargetOLM):partstitled("Starship Orbital Launch Integration Tower Base")[0]:position).
                        lock PositionError to vxcl(up:vector, BoosterCore:position - Vessel(TargetOLM):partstitled("Starship Orbital Launch Mount")[0]:position).
                        if vAng(TowerRotationVector,PositionError) > 42 set HighIncl to true.
                        if not RSS {sendMessage(Vessel(TargetOLM), "MechazillaHeight,"+ 3*Scale + ",0.5").}
                        if not LZchange set MZHeight to vxcl(vCrs(north:vector, up:vector), vxcl(north:vector, landingzone:position - Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position)):mag.
                    }
                    when Vessel(TargetOLM):distance < 1800 then {
                        set Vessel(TargetOLM):loaddistance:landed:unpack to 1500.
                        set Vessel(TargetOLM):loaddistance:prelaunch:unpack to 1500.
                        if not LZchange set MZHeight to vxcl(vCrs(north:vector, up:vector), vxcl(north:vector, landingzone:position - Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position)):mag.
                    }
                }
            }
        }
    }
    
    when RadarAlt < LandingBurnAlt * 1.25 then {
        set LngCtrlPID:setpoint to LngCtrlPID:setpoint+(LandingBurnAlt/(950*Scale))^2.
        set steeringManager:pitchpid:kd to 0.25.
        set steeringManager:yawpid:kd to 0.4.
    }

    when RadarAlt < LandingBurnAlt * 1.12 then {
        if dbactive {
            set ApproachAngle to vAng(BoosterCore:position - landingzone:position, TheTowerHeadingVector).
            if vAng(lookDirUp(TheTowerHeadingVector,up:vector):starvector, BoosterCore:position - landingzone:position) > 90 set ApproachAngle to -ApproachAngle.
        }
        else set ApproachAngle to 0.

        lock SteeringVector to lookdirup(-0.47 * velocity:surface * max(1,airspeed/300) + up:vector * max(1,airspeed/12), ApproachVector).
        lock steering to SteeringVector.
    }

    when RadarAlt < LandingBurnAlt * 1.8 then {
        set CorrFactor to vAng(up:vector, BoosterCore:position - landingzone:position)/30.
    }
    
    set once to false.
    until alt:radar < LandingBurnAlt {
        SteeringCorrections().
        if kuniverse:timewarp:warp > 0 {
            set once to true.
        }
        if alt:radar < 6000 and once {
            set kuniverse:timewarp:warp to 0.
            set once to false.
        } else if kuniverse:timewarp:warp > 1 
            set kuniverse:timewarp:warp to 1.
        if altitude > 26000 and RSS or altitude > 20000 and not (RSS) and abs(steeringManager:angleerror) > 1 {
            rcs on.
        }
        else {
            rcs off.
        }
        PollUpdate().
        SetBoosterActive().
        CheckFuel().
        if config:ipu < 1800   set config:ipu to 1800.
        wait 0.05.
    }
    set config:ipu to 2000.
    set fastSticks to false.
    if BoosterSingleEngines {
        for gimbalEng in BoosterSingleEnginesRC {
            if gimbalEng:hassuffix("activate") gimbalEng:getmodule("ModuleGimbal"):SetField("gimbal limit", 32).
        }
    }

    if not GfC {
        set LandSomewhereElse to true.
    } 

    set tgtErrorPID to pidLoop(0.042*(Scale^0.7), 0.0005*(Scale^0.5), 0.075/(Scale), -7, 7).

    if not BoosterSingleEngines {
        until BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):getfield("Mode") = "Center Three" or BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):getfield("Mode") = "Raptor_3_Core" or BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):getfield("Mode") = "Core" {
            BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("next engine mode", true).
            wait 0.01.
        }
    }

    set LandingBurnTime to time:seconds.
    if not BoosterSingleEngines MidGimbMod:doaction("free gimbal", true).
    if not BoosterSingleEngines and Block3Cluster Mid2GimbMod:doaction("free gimbal", true).
    if not BoosterSingleEngines CtrGimbMod:doaction("free gimbal", true).
    lock throttle to max(0.33,LandingThrottle()).

    if BoosterSingleEngines {
        set x to 1.
        until x > 3 {
            if BoosterSingleEnginesRC[x-1]:hassuffix("activate") if random() < LBIgnC/100 {
                BoosterSingleEnginesRC[x-1]:activate.
                set BoosterSingleEnginesRC[x-1]:gimbal:lock to false.
                BoosterSingleEnginesRC[x-1]:getmodule("ModuleGimbal"):SetField("gimbal limit", 60).
            } 
            set x to x + 1.
        }
        set startNumber to 3.
        when time:seconds - LandingBurnTime > 0.1 then {
            set x to 1.
            for eng in BoosterSingleEnginesRC {
                if (x = 4 or x = 6 or x = 8 or x = 10 or x = 12) and eng:hassuffix("activate") {
                    if random() < LBIgnM/100 eng:activate.
                    set eng:gimbal:lock to false.
                }
                if x = 12 set startNumber to 8.
                set x to x + 1.
            }
            wait 0.
            set LandingBurnStarted to true.
            when time:seconds - LandingBurnTime > 0.6 and startNumber = 8 then {
                set x to 1.
                for eng in BoosterSingleEnginesRC {
                    if (x = 5 or x = 7 or x = 9 or x = 11 or x = 13) and eng:hassuffix("activate") {
                        if random() < 0.98*LBIgnM/100 eng:activate.
                        set eng:gimbal:lock to false.
                    }
                    set x to x + 1.
                }
                when time:seconds - LandingBurnTime > 0.8 then
                    set LandingBurnEC to true.
                set GoForCatch to true.
            }
        }
    }
    else {
        when time:seconds - LandingBurnTime > 0.3 then {
            BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("previous engine mode", true).
            wait 0.
            if Block3Cluster BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("previous engine mode", true).
            set GoForCatch to true.
        }
        set LandingBurnStarted to true.
    }
    

    hudtext(throttle, 3, 2, 10, white, false).

    when velocity:surface:mag < 360 or ErrorVector:mag < 0.5 * BoosterHeight or LngError < 0 or RadarAlt < 1000 then {
        set LandingVector to LandingGuidance().
        lock steering to LandingVector.
        unlock SteeringVector.
        wait 0.
        if vAng(-OffsetPosVec,TheTowerHeadingVector) > 24 set fastSticks to true.
    }

    PollUpdate().



    HUDTEXT("Performing Landing Burn..", 3, 2, 20, green, false).

    if GfC when not Gfc then set cAbort to true.

    if not offshoreDivert when cAbort then {
        set GoForCatch to false.
        if not BoosterLanded and (RadarAlt > 5 or PositionError:mag > 10) {
            HUDTEXT("Abort! Landing somewhere else..", 10, 2, 20, red, false).
            set abortTime to time:seconds.
            set LandSomewhereElse to true.
            lock RadarAlt to alt:radar - RadarAltOffset.
            set LZchange to true.
            wait 0.
            when addons:tr:hasimpact then set landingzone to latlng(addons:tr:IMPACTPOS:lat-0.005/(Scale^5),addons:tr:impactpos:lng+0.002/(Scale^5)).
            set LZchange to false.
            wait 0.
            addons:tr:settarget(landingzone).
            lock SteeringVector to lookDirUp(2*up:vector - 0.007*ErrorVector - 0.03 * velocity:surface, facing:topvector).
            lock steering to SteeringVector.
            when time:seconds > abortTime + 4 then {
                if RSS {
                    lock SteeringVector to lookdirup(up:vector - 0.033 * velocity:surface - 0.002 * ErrorVector, facing:topvector).
                }
                else if KSRSS {
                    lock SteeringVector to lookdirup(up:vector - 0.03 * velocity:surface - 0.001 * ErrorVector, facing:topvector).
                }
                else {
                    lock SteeringVector to lookdirup(up:vector - 0.04 * velocity:surface - 0.0003 * ErrorVector, facing:topvector).
                }
                lock steering to SteeringVector.
            }
            if Vessel(TargetOLM):distance < 2000 sendMessage(Vessel(TargetOLM), "MechazillaArms,8.4,24,95,true").
        }
    }

    if (ErrorVector:mag > 4 * BoosterHeight and RadarAlt < 1000) or (ErrorVector:mag > 6 * BoosterHeight and RadarAlt > 1000) and not HSRJet and GfC and not cAbort {
        HUDTEXT("Mechazilla out of range..", 10, 2, 20, red, false).
        HUDTEXT("Abort! Landing somewhere else..", 10, 2, 20, red, false).
        set cAbort to true.
        lock steering to retrograde.
        when airspeed < 30 then lock steering to up.
    }

    if (abs(LngError - LngCtrlPID:setpoint) > 69 * Scale or abs(LatError) > 10) and not GfC and not cAbort {
        set LZchange to true.
        wait 0.
        set landingzone to latlng(addons:tr:IMPACTPOS:lat-0.005,addons:tr:impactpos:lng+0.002).
        set LZchange to false.
        wait 0.
        set LandSomewhereElse to true.
        if highSplash lock RadarAlt to alt:radar - RadarAltOffset - MZHeight.
        else lock RadarAlt to alt:radar - RadarAltOffset.
        addons:tr:settarget(landingzone).
    }

    if not GfC and abs(alt:radar - RadarAlt) > 5*Scale and not offshoreDivert when RadarAlt < 5*BoosterHeight then 
            lock RadarAlt to alt:radar - RadarAltOffset.

    when RadarAlt < 1800 then set LngCtrlPID:setpoint to 10*Scale.

    when RadarAlt < 2000 and not (LandSomewhereElse) then {
        set steeringManager:maxstoppingtime to 1.2.
        if not (TargetOLM = "false") and TowerExists {
            //setTowerHeadingVector().
            PollUpdate().
            addons:tr:settarget(landingzone).
            if GfC when Vessel(TargetOLM):distance < 2200 and Vessel(TargetOLM):loaded then {
                PollUpdate().
                if Vessel(TargetOLM):partsnamed("OLM.B2"):length > 0 set PadB to true.
                if PadB {
                    set MZHeight to vxcl(vCrs(north:vector, up:vector), vxcl(north:vector, landingzone:position - Vessel(TargetOLM):PARTSNAMED("PadB.Chopsticks")[0]:position)):mag.
                    set TowerHeadingVector to TowerHeadingFrom(Vessel(TargetOLM)).
                    if BoosterType:contains("Block3") {
                        if not RSS 
                            lock RadarAlt to vdot(up:vector, GridFins[0]:position - Vessel(TargetOLM):PARTSNAMED("PadB.Chopsticks")[0]:position) - LiftingPointToGridFinDist - 2.8.
                        else 
                            lock RadarAlt to vdot(up:vector, GridFins[0]:position - Vessel(TargetOLM):PARTSNAMED("PadB.Chopsticks")[0]:position) - LiftingPointToGridFinDist - 1.5.
                    }
                    else {
                        if not RSS 
                            lock RadarAlt to vdot(up:vector, GridFins[0]:position - Vessel(TargetOLM):PARTSNAMED("PadB.Chopsticks")[0]:position) - LiftingPointToGridFinDist - 3.8.
                        else 
                            lock RadarAlt to vdot(up:vector, GridFins[0]:position - Vessel(TargetOLM):PARTSNAMED("PadB.Chopsticks")[0]:position) - LiftingPointToGridFinDist - 2.1.
                    }
                }
                else {
                    set MZHeight to vxcl(vCrs(north:vector, up:vector), vxcl(north:vector, landingzone:position - Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position)):mag.
                    set TowerHeadingVector to vxcl(Vessel(TargetOLM):up:vector, Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position - Vessel(TargetOLM):PARTSTITLED("Starship Orbital Launch Integration Tower Base")[0]:position).
                    if BoosterType:contains("Block3") {
                        if not RSS 
                            lock RadarAlt to vdot(up:vector, GridFins[0]:position - Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position) - LiftingPointToGridFinDist - 2.8.
                        else 
                            lock RadarAlt to vdot(up:vector, GridFins[0]:position - Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position) - LiftingPointToGridFinDist - 1.5.
                    }
                    else {
                        if not RSS 
                            lock RadarAlt to vdot(up:vector, GridFins[0]:position - Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position) - LiftingPointToGridFinDist - 3.8.
                        else 
                            lock RadarAlt to vdot(up:vector, GridFins[0]:position - Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position) - LiftingPointToGridFinDist - 2.1.
                    }
                }
                sendMessage(Vessel(TargetOLM), ("RetractSQD")).

                when Vessel(TargetOLM):distance < 1000 then {sendMessage(Vessel(TargetOLM), ("RetractSQD")).}

                when vxcl(up:vector, landingzone:position - BoosterCore:position):mag < BoosterHeight*5 and RadarAlt < 16 * BoosterHeight then {
                    if RSS {
                        sendMessage(Vessel(TargetOLM), ("MechazillaArms,8.4,16,75,true")).
                    } else {
                        sendMessage(Vessel(TargetOLM), ("MechazillaArms,8.4,12,75,true")).
                    }
                    sendMessage(Vessel(TargetOLM), "MechazillaStabilizers,0").
                    sendMessage(Vessel(TargetOLM), ("RetractSQD")).
                    when RadarAlt < 3.4 * BoosterHeight then {
                        sendMessage(Vessel(TargetOLM), "LandingDeluge").
                        NoGo:hide().
                        set steeringManager:rollcontrolanglerange to 32.
                        set steeringManager:rolltorquefactor to 1.6.
                        when RadarAlt < 1.2 * BoosterHeight then {
                            set steeringManager:rolltorquefactor to 2.2.
                            when RadarAlt < 0.5*BoosterHeight then {
                                // Отправка захвата отсюда УБРАНА - она переехала в
                                // цикл отслеживания ниже. Здесь она стояла в шестом
                                // по счёту вложенном when и не успевала выстрелить.
                                for fin in Gridfins fin:getmodule("ModuleControlSurface"):SetField("authority limiter", 0).
                                if GridfinLength = 4 {
                                    for fin in Gridfins fin:getmodule("ModuleControlSurface"):SetField("deploy angle", 10).
                                    Gridfins[1]:getmodule("ModuleControlSurface"):SetField("deploy direction", false). Gridfins[3]:getmodule("ModuleControlSurface"):SetField("deploy direction", false).
                                    Gridfins[0]:getmodule("ModuleControlSurface"):SetField("deploy direction", true). Gridfins[2]:getmodule("ModuleControlSurface"):SetField("deploy direction", true).
                                    for fin in Gridfins fin:getmodule("ModuleControlSurface"):SetField("deploy", true).
                                }
                            }
                        }
                    }
                    set SentTime to time:seconds.
                    // Условие жизни этого триггера было "RadarAlt > 0.05*BoosterHeight",
                    // а в ClosingAngle() зазор в 8 градусов снимается ровно наоборот -
                    // при RadarRatio <= 0.05. Одно было точным дополнением другого:
                    // пока команды шлются, пол в 8 градусов применяется ВСЕГДА, а в тот
                    // момент, когда он мог бы сняться, триггер переставал слать команды.
                    // Руки гарантированно застревали на 8 градусах и не смыкались на
                    // бустере - отсюда несостоявшаяся ловля, NRE стыковочного узла в
                    // Player.log и повторный взлёт на полу тяги.
                    // Порог снят: команды идут до самой посадки, и последний участок
                    // руки закрывают по стоковой кривой, как и задумывалось.
                    when RadarAlt < 12 * BoosterHeight then {
                        if not BoosterLanded and not ArmsCloseSent {
                            set ArmAngle to ClosingAngle().
                            set ArmSpeed to ClosingSpeed().
                            set BoosterRot to GetBoosterRotation().

                            // Захват шлём ОТСЮДА, а не из вложенных when.
                            // Раньше он висел в цепочке из шести одноразовых
                            // триггеров (RA<656 -> 139 -> 49 -> 20 -> 5 -> 2.46),
                            // где каждый регистрирует следующий только когда
                            // сработает сам. Последние два уровня должны были
                            // зарегистрироваться и выстрелить за доли секунды на
                            // скорости 6-13 м/с - и команда до башни не доходила.
                            // Этот же цикл исполняется гарантированно: он писал
                            // ArmA = 0.13 на RadarAlt = 1.
                            // Промах меряем относительно CatchPos - той точки, куда
                            // бустер реально летит, - и только БОКОВУЮ составляющую.
                            //
                            // Было: полное расстояние до landingzone. Это другая точка:
                            // CatchPos смещён от неё офсетами (CatchOffsetAlong = 3 м)
                            // и вкладом heading. В полёте 19:55 расстояние до landingzone
                            // на подходе шло 8 -> 12 -> 15 м при пороге 4 м, то есть
                            // условие не выполнялось НИ РАЗУ и CloseArms не уходил
                            // (ArmsClosed = 0 весь лог, створ схлопывался стоковой
                            // кривой вместо захвата).
                            //
                            // Вдоль оси промах не страшен - руки длинные, и Along там
                            // держит стабильные -5 м как остаточная ошибка контура,
                            // она не обнуляется в принципе. Страшен боковой: в том же
                            // полёте Side был 0.79 / -0.86 / -1.62 / -0.74 м, то есть
                            // проходит с запасом.
                            if RadarAlt < ArmCloseRatio * BoosterHeight
                               and abs(vdot(CatchPos - BoosterCore:position, vCrs(up:vector, TheTowerHeadingVector:normalized):normalized)) < ArmCloseMaxOffset {
                                set ArmsCloseSent to true.
                                sendMessage(Vessel(TargetOLM), ("MechazillaArms," + round(BoosterRot, 1) + "," + ArmSpeed + "," + ArmGripAngle + ",true")).
                                sendMessage(Vessel(TargetOLM), ("CloseArms")).
                            }
                            else if SentTime + 0.1 < time:seconds {
                                sendMessage(Vessel(TargetOLM), ("MechazillaArms," + round(BoosterRot, 1) + "," + ArmSpeed + "," + ArmAngle + ",true")).
                                set SentTime to time:seconds.
                            }
                        }
                        wait 0.
                        if not BoosterLanded return true.
                        else return false.
                    }
                }
            }
        }
    }

    when airspeed < MidShutdownSpeed + 4*Scale then { 
        set MiddleEnginesShutdown to true.
        set MidShutSpeed to airspeed.
        set ShutdownTime to time:seconds.

        if ErrorVector:mag > 2.4 * BoosterHeight and GfC and not cAbort {
            HUDTEXT("Mechazilla out of range..", 10, 2, 20, red, false).
            HUDTEXT("Abort! Landing somewhere else..", 10, 2, 20, red, false).
            set cAbort to true.
            lock steering to retrograde.
            when airspeed < 30 then lock steering to lookDirUp(up:vector - GSVec*0.1,facing:topvector).
        }


        if BoosterSingleEngines {
            set NrMisEng to 0.
            if CounterEngine {
                if BoosterSingleEnginesRC[0]:hassuffix("activate") if BoosterSingleEnginesRC[0]:thrust < 60*Scale {
                    if BoosterSingleEnginesRC[3]:hassuffix("activate") {
                        if BoosterSingleEnginesRC[3]:thrust < 60*Scale NrCounterEngine:add(5).
                        else NrCounterEngine:add(4).
                    }
                    else NrCounterEngine:add(4).
                    set NrMisEng to NrMisEng+1.
                    BoosterSingleEnginesRC[NrCounterEngine[NrMisEng-1]-1]:getmodule("ModuleGimbal"):SetField("gimbal limit", 69).
                }
                if BoosterSingleEnginesRC[1]:hassuffix("activate") if BoosterSingleEnginesRC[1]:thrust < 60*Scale {
                    if BoosterSingleEnginesRC[6]:hassuffix("activate") {
                        if BoosterSingleEnginesRC[6]:thrust < 60*Scale NrCounterEngine:add(8).
                        else NrCounterEngine:add(7).
                    }
                    else NrCounterEngine:add(7).
                    set NrMisEng to NrMisEng+1.
                    BoosterSingleEnginesRC[NrCounterEngine[NrMisEng-1]-1]:getmodule("ModuleGimbal"):SetField("gimbal limit", 69).
                }
                if BoosterSingleEnginesRC[2]:hassuffix("activate") if BoosterSingleEnginesRC[2]:thrust < 60*Scale {
                    if BoosterSingleEnginesRC[10]:hassuffix("activate") {
                        if BoosterSingleEnginesRC[10]:thrust < 60*Scale NrCounterEngine:add(10).
                        else NrCounterEngine:add(11).
                    }
                    else NrCounterEngine:add(11).
                    set NrMisEng to NrMisEng+1.
                    BoosterSingleEnginesRC[NrCounterEngine[NrMisEng-1]-1]:getmodule("ModuleGimbal"):SetField("gimbal limit", 69).
                }
                when airspeed < 6 then {
                    BoosterSingleEnginesRC[NrCounterEngine[0]-1]:shutdown.
                    set BoosterSingleEnginesRC[NrCounterEngine[0]-1]:gimbal:lock to true.
                    if not BoosterType:contains("Block3") BoosterSingleEnginesRC[NrCounterEngine[0]-1]:getmodule("ModuleSEPRaptor"):DoAction("toggle actuate out", true).
                } 
                set MidShutSpeed to MidShutSpeed - 8.
            }
            wait 0.
            when airspeed < MidShutSpeed then {
                if Bl3LndProf {
                    if BoosterType:contains("Block2") set Block2Offset to 1.
                    else set Block2Offset to 0.
                    if BoosterSingleEnginesRC[4]:hassuffix("activate") and not NrCounterEngine:contains(5) BoosterSingleEnginesRC[4]:shutdown. wait 0.
                    if BoosterSingleEnginesRC[9]:hassuffix("activate") and not NrCounterEngine:contains(10) BoosterSingleEnginesRC[9]:shutdown. wait 0.
                    if BoosterSingleEnginesRC[11]:hassuffix("activate") and not NrCounterEngine:contains(12) BoosterSingleEnginesRC[11]:shutdown. wait 0.
                    if BoosterSingleEnginesRC[6-Block2Offset]:hassuffix("activate") and not NrCounterEngine:contains(7-Block2Offset) BoosterSingleEnginesRC[6-Block2Offset]:shutdown.
                    BoosterSingleEnginesRC[5+Block2Offset]:getmodule("ModuleGimbal"):SetField("gimbal limit", 78).
                    BoosterSingleEnginesRC[10]:getmodule("ModuleGimbal"):SetField("gimbal limit", 78).
                    set x to 1.
                    for eng in BoosterSingleEnginesRC {
                        if x = 1 or x = 2 or x = 3 or x = 4 or x = 6+Block2Offset or x = 8 or x = 10 or x = 11 or x = 12 or (NrCounterEngine:contains(x) and CounterEngine) {} 
                        else if eng:hassuffix("activate") and not NrCounterEngine:contains(x) {
                            set eng:gimbal:lock to true.
                            //eng:getmodule("ModuleSEPRaptor"):DoAction("toggle actuate out", true).
                        }
                        set x to x + 1.
                    }
                    set x to 1.
                    when time:seconds > ShutdownTime + 0.08 then {
                        if BoosterSingleEnginesRC[3]:hassuffix("activate") and not NrCounterEngine:contains(4) BoosterSingleEnginesRC[3]:shutdown. wait 0.
                        if BoosterSingleEnginesRC[8]:hassuffix("activate") and not NrCounterEngine:contains(9) BoosterSingleEnginesRC[8]:shutdown. wait 0.
                        if BoosterSingleEnginesRC[12]:hassuffix("activate") and not NrCounterEngine:contains(13) BoosterSingleEnginesRC[12]:shutdown. wait 0.
                        if BoosterSingleEnginesRC[7]:hassuffix("activate") and not NrCounterEngine:contains(8) BoosterSingleEnginesRC[7]:shutdown.
                        for eng in BoosterSingleEnginesRC {
                            if x = 1 or x = 2 or x = 3 or x = 5 or x = 6 or x = 7 or x = 9 or x = 11 or x = 13 or (NrCounterEngine:contains(x) and CounterEngine) {}
                            else if eng:hassuffix("activate") and not NrCounterEngine:contains(x) {
                                set eng:gimbal:lock to true.
                                //eng:getmodule("ModuleSEPRaptor"):DoAction("toggle actuate out", true).
                            }
                            set x to x + 1.
                        }
                    }
                    // ОТКАТ 03.09.2026. Гейт "and stopDist3 < RadarAlt" на обе ветки
                    // сделал только хуже: stopDist3 в этом профиле сам не успевает
                    // стать меньше RadarAlt, ветка A (запасной триггер по времени)
                    // оказалась заблокирована НАВСЕГДА - переход на 3 двигателя не
                    // происходил вообще, 5-двигательная фаза целится в жёстко
                    // зашитые 12 м/с (см. "Decel 5 Engines" ниже) и на этом эффективно
                    // останавливается, а до земли остаётся 10-19 м/с. Настоящая
                    // причина не в приоритете операторов - это ветка A и должна была
                    // остаться безусловным предохранителем. Реальная причина жёсткой
                    // посадки - 5-двигательная фаза не успевает дойти даже до своей
                    // цели 12 м/с к моменту, когда кончается высота (см. память
                    // ksp-booster-landing-profile). Возвращена исходная логика.
                    when not Land5EnginesOnly and (time:seconds > ShutdownTime + 3.08 and airspeed < 14*Scale or verticalSpeed > -12*Scale and stopDist3 < RadarAlt) then {
                        set downToThree to true.
                        if BoosterSingleEnginesRC[5+Block2Offset]:hassuffix("activate") and not NrCounterEngine:contains(6+Block2Offset) {
                            BoosterSingleEnginesRC[5+Block2Offset]:shutdown.
                            set BoosterSingleEnginesRC[5+Block2Offset]:gimbal:lock to true.
                            //BoosterSingleEnginesRC[5+Block2Offset]:getmodule("ModuleSEPRaptor"):DoAction("toggle actuate out", true).
                        }
                        if BoosterSingleEnginesRC[10]:hassuffix("activate") and not NrCounterEngine:contains(11) {
                            BoosterSingleEnginesRC[10]:shutdown.
                            set BoosterSingleEnginesRC[10]:gimbal:lock to true.
                            //BoosterSingleEnginesRC[10]:getmodule("ModuleSEPRaptor"):DoAction("toggle actuate out", true).
                        }
                    }
                }
                else {
                    set downToThree to true.
                    set x to 1.
                    for eng in BoosterSingleEnginesRC {
                        if x = 1 or x = 2 or x = 3 or x = 4 or x = 6 or x = 8 or x = 10 or x = 12 or (NrCounterEngine:contains(x) and CounterEngine) {} 
                        else if eng:hassuffix("activate") and not NrCounterEngine:contains(x) {
                            eng:shutdown.
                            set eng:gimbal:lock to true.
                            eng:getmodule("ModuleSEPRaptor"):DoAction("toggle actuate out", true).
                        }
                        set x to x + 1.
                    }
                    set x to 1.
                    when time:seconds > ShutdownTime + 0.08 then 
                        for eng in BoosterSingleEnginesRC {
                            if x = 1 or x = 2 or x = 3 or x = 5 or x = 7 or x = 9 or x = 11 or x = 13 or (NrCounterEngine:contains(x) and CounterEngine) {}
                            else if eng:hassuffix("activate") and not NrCounterEngine:contains(x) {
                                eng:shutdown.
                                set eng:gimbal:lock to true.
                                eng:getmodule("ModuleSEPRaptor"):DoAction("toggle actuate out", true).
                            }
                            set x to x + 1.
                        }
                }
            }
        }
        else {
            BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("next engine mode", true).
            MidGimbMod:doaction("lock gimbal", true).
            if Block3Cluster { 
                // ОТКАТ 03.09.2026 - см. комментарий у парного триггера выше.
                // Land5EnginesOnly гасит переход на 3 движка ТОЛЬКО для Bl3LndProf
                // (см. TouchdownSpeed выше) - "or not Bl3LndProf" не трогаем, у
                // другого профиля посадки это не тот же самый переход.
                when (time:seconds > ShutdownTime + 3 and airspeed < 14*Scale or verticalSpeed > -12*Scale and stopDist3 < RadarAlt) and not Land5EnginesOnly or not Bl3LndProf then {
                    set downToThree to true.
                    BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("next engine mode", true).
                    Mid2GimbMod:doaction("lock gimbal", true).
                }
            } else 
                set downToThree to true.
        }
        when airspeed < 10 then set EC to false.
    }


    if landingzone:hassuffix("distance") {}
    else {
        HUDTEXT("Landingzone Problem", 10, 2, 20, red, false).
        set landingzone to ship:geoposition.
    }


    until (verticalspeed > CatchVS - 0.5 and RadarAlt < 5) or (verticalspeed > -0.2 and RadarAlt < 100*Scale) or hover {
        SteeringCorrections().
        if GfC and not offshoreDivert and not LZchange {if landingzone:distance < 1500 and Vessel(TargetOLM):loaded {
            if PadB set RollVector to vxcl(up:vector, Vessel(TargetOLM):PARTSNAMED("PadB.Chopsticks")[0]:position - BoosterCore:position).
            else set RollVector to vxcl(up:vector, Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position - BoosterCore:position).
        } else set RollVector to -TowerRotationVector. }
        set LandingVector to LandingGuidance().
        if kuniverse:timewarp:warp > 0 {set kuniverse:timewarp:warp to 0.}
        PollUpdate().
        SetBoosterActive().

        if random() < ifIgn/100 and BoosterSingleEngines and not TFinstalled {
            set failedEngNr to 1+floor(random()*12).
            if BoosterSingleEnginesRC[failedEngNr-1]:hassuffix("activate") BoosterSingleEnginesRC[failedEngNr-1]:shutdown.
            if MiddleEnginesShutdown and RadarAlt > 8*Scale and airspeed > 8
                if failedEngNr = 1 {
                    if BoosterSingleEnginesRC[3]:hassuffix("activate") {
                            BoosterSingleEnginesRC[3]:activate.
                            set BoosterSingleEnginesRC[3]:gimbal:lock to false.
                            if not BoosterType:contains("Block3") BoosterSingleEnginesRC[3]:getmodule("ModuleSEPRaptor"):DoAction("toggle actuate out", true).
                        }
                    }
                else if failedEngNr = 2 {
                    if BoosterSingleEnginesRC[6]:hassuffix("activate") {
                            BoosterSingleEnginesRC[6]:activate.
                            set BoosterSingleEnginesRC[6]:gimbal:lock to false.
                            if not BoosterType:contains("Block3") BoosterSingleEnginesRC[6]:getmodule("ModuleSEPRaptor"):DoAction("toggle actuate out", true).
                        }
                    }
                else if failedEngNr = 3 {
                    if BoosterSingleEnginesRC[10]:hassuffix("activate") {
                            BoosterSingleEnginesRC[10]:activate.
                            set BoosterSingleEnginesRC[10]:gimbal:lock to false.
                            if not BoosterType:contains("Block3") BoosterSingleEnginesRC[10]:getmodule("ModuleSEPRaptor"):DoAction("toggle actuate out", true).
                        }
                    }
        } 

        //set drawRoV to vecDraw(BoosterCore:position,RollVector,yellow,"RollVec",2,true,0.05).
        //if GfC and not offshoreDivert if landingzone:distance < 1500 set drawMZPos to vecDraw(Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position,up:vector,red,"RollVec",30,true,0.004).
        //if GfC and not offshoreDivert if landingzone:distance < 1500 set drawMZPos2 to vecDraw(Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position,-up:vector,red,"RollVec",30,true,0.004).

        if config:ipu < 2000   set config:ipu to 2000.
        wait 0.05.
    }
    when PositionError:mag > 0.5*BoosterHeight or RadarAlt < -1.3*Scale then set cAbort to true.


    until ((ship:status = "LANDED" or ship:status = "SPLASHED") and verticalspeed > -0.1) or (RadarAlt < -1) or (verticalSpeed > -0.3 and RadarAlt < 1) {
        clearScreen.
        print "slowly lowering down booster..".
        if GfC and not offshoreDivert {
            if PadB set RollVector to vxcl(up:vector, Vessel(TargetOLM):PARTSNAMED("PadB.Chopsticks")[0]:position - BoosterCore:position).
            else set RollVector to vxcl(up:vector, Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position - BoosterCore:position).
        }
        set LandingVector to LandingGuidance().
        if kuniverse:timewarp:warp > 0 {set kuniverse:timewarp:warp to 0.}
        if not rcs rcs on.
        SteeringCorrections().
        SetBoosterActive().
        if config:ipu < 2000   set config:ipu to 2000.
        wait 0.05.
    }

    // Касание фиксируем ЗДЕСЬ: выход из этого цикла и ЕСТЬ контакт (условия
    // выхода - status LANDED/SPLASHED, либо RadarAlt ушёл ниже нуля, либо
    // вертикальная скорость погасла у самой земли). Дальше идёт хореография
    // выключения на 5-6 секунд, и веха посадки уезжала на это время вперёд,
    // а при обрыве скрипта не проставлялась вовсе. Тот же класс бага, что
    // чинили для SeparationTime.
    if TouchdownTime = 0 set TouchdownTime to time:seconds.

    lock steering to lookDirUp(up:vector, RollVector).
    set throttleTime to time:seconds.
    set startThrottle to max(minThrottle,throttle).
    clearScreen.
    print ship:control:pilotmainthrottle.
    if not RSS lock throttle to max(startThrottle - (time:seconds-throttleTime)/4,0.4).
    else lock throttle to max(startThrottle - (time:seconds-throttleTime)/6,0.2).
    wait 0.
    when vAng(up:vector,facing:forevector) < 0.5 and angularVel:mag < 0.01 and (time:seconds-throttleTime) > 2 and verticalSpeed > -0.4 then  {
        if not RSS lock throttle to 0.4 - (time:seconds-throttleTime)/4.
        else lock throttle to 0.2 - (time:seconds-throttleTime)/6.
    }
    // Выход из этого цикла требовал angularVel:mag < 0.01 (или < 0.02). Вися в
    // лапах Mechazilla бустер качается с ~0.03 рад/с, условие не выполняется
    // никогда, тяга при этом заперта на полу 0.4 - двигатели горели бесконечно.
    // Аварийный выход по времени: если снижения уже нет, ждём затухание не
    // дольше 8 с и глушим.
    until (ship:control:pilotmainthrottle < 0.2 and vAng(up:vector,facing:forevector) < 0.6 and angularVel:mag < 0.01 and verticalSpeed > -0.5) or vAng(up:vector, facing:forevector) > 42 or (angularVel:mag < 0.02 and ship:control:pilotmainthrottle < 0.04 and verticalSpeed > -0.5) or (time:seconds - throttleTime > 8 and verticalSpeed > -0.5) {
        clearScreen.
        print ship:control:pilotmainthrottle.
        print angularVel:mag.
        print "settle: " + round(time:seconds - throttleTime, 1) + " s / 8".
        // Ловля может не защёлкнуться (у мода башни бывают NRE на стыковочном
        // узле - в Player.log их сотни за посадку). Тогда бустер остаётся
        // висеть на полу тяги 0.4, выгорает, лёгчает - и ВЗЛЕТАЕТ обратно:
        // пять двигателей на 40% при 573 кН дают TWR около единицы, а с каждой
        // секундой массы меньше. В фазе успокоения набор высоты не нужен ни
        // при каком раскладе, поэтому глушим тягу и выходим.
        if verticalspeed > 0.5 {
            lock throttle to 0.
            set ship:control:pilotmainthrottle to 0.
            break.
        }
        wait 0.1.
    }
    wait 0.3.



    if GfC {
        set ship:control:translation to v(0, 0, 0).
        unlock steering.
        lock throttle to 0.
        set ship:control:pilotmainthrottle to 0.
        rcs off.
        clearscreen.
        print "Booster Landed!".
        set BoosterLanded to true.
        wait 0.01.
        if BoosterEngines[0]:hasphysics and not BoosterSingleEngines {BoosterEngines[0]:shutdown.}
        else for eng in BoosterSingleEnginesRC if eng:hassuffix("activate") eng:shutdown.
        wait 0.5.
        sendMessage(Vessel(TargetOLM), "RetractMechazillaRails").
    } else if not GfC {
        lock throttle to 0.
        rcs on.
        set ship:control:pilotmainthrottle to 0.
        if not cAbort set ship:control:pitch to 1.
        wait 5.
        set ship:control:translation to v(0, 0, 0).
        unlock steering.
        rcs off.
        clearscreen.
        print "Booster Landed!".
        set BoosterLanded to true.
        wait 0.01.
        set ship:control:pitch to 0.
        if BoosterEngines[0]:hasphysics and not BoosterSingleEngines {BoosterEngines[0]:shutdown.}
        else for eng in BoosterSingleEnginesRC if eng:hassuffix("activate") eng:shutdown.
    }
    set config:ipu to 1000.
    bGUI:hide().
    
    set LandingTime to time:seconds.
    
    SetLoadDistances("default").
    unlock PositionError.

    DeactivateGridFins().
    if not BoosterSingleEngines BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):DOACTION("next engine mode", true).
    if not BoosterSingleEngines CtrGimbMod:doaction("lock gimbal", true).
    CheckFuel().

    when time:seconds > LandingTime + 3 then {
        if SinglePartBooster BoosterCore:activate.
        else for vent in DumpVents if not vent:istype("Boolean") vent:doaction("activate engine", true).
    }

    if not (LandSomewhereElse) {
        if not (TargetOLM = "false") {
            if RSS {
                HUDTEXT("Booster Landing Confirmed!", 10, 2, 20, green, false).
            }
            else {
                HUDTEXT("Booster Landing Confirmed! Stand by for Mechazilla operation..", 30, 2, 20, green, false).
            }
            set TowerReset to false.
            set RollAngleExceeded to false.
            if not (RSS) {
                //BoosterEngines[0]:getmodule("ModuleDockingNode"):SETFIELD("docking acquire force", 200).
                //sendMessage(Vessel(TargetOLM), "DockingForce,200").
            }
            print "Tower Operation in Progress..".
            sendMessage(Vessel(TargetOLM), "RetractMechazillaRails").
            
            when time:seconds > LandingTime + 4 then {
                if BoosterSingleEngines {
                    for eng in BoosterSingleEnginesRC {
                        eng:shutdown.
                        set eng:gimbal:lock to true.
                        eng:getmodule("ModuleGimbal"):SetField("gimbal limit", 50).
                        if not BoosterType:contains("Block3") if eng:getmodule("ModuleSEPRaptor"):GetField("actuate out") = true
                            eng:getmodule("ModuleSEPRaptor"):DoAction("toggle actuate out", false).
                    }
                }

                lock RadarAlt to alt:radar - RadarAltOffset * 0.6.
                
                        for fin in Gridfins fin:getmodule("ModuleControlSurface"):SetField("authority limiter", 15).
                        for fin in Gridfins fin:getmodule("ModuleControlSurface"):SetField("deploy angle", 0).
                        if GridfinLength = 4 {
                            Gridfins[1]:getmodule("ModuleControlSurface"):SetField("deploy direction", false). Gridfins[3]:getmodule("ModuleControlSurface"):SetField("deploy direction", false).
                            Gridfins[0]:getmodule("ModuleControlSurface"):SetField("deploy direction", true). Gridfins[2]:getmodule("ModuleControlSurface"):SetField("deploy direction", true).
                        }
                        for fin in Gridfins fin:getmodule("ModuleControlSurface"):SetField("deploy", false).
            }

        }
        else {
            print "Booster has been secured".
            HUDTEXT("Booster may now be recovered!", 10, 2, 20, green, false).
        }
    }
    else {
        print "Booster has touched down somewhere".
        HUDTEXT("Booster may now be recovered!", 10, 2, 20, green, false).
    }

    unlock throttle.
    //if BoosterCore:getmodule("ModuleSepPartSwitchAction"):getfield("current decouple system") = "Decoupler" {
    //    BoosterCore:getmodule("ModuleSepPartSwitchAction"):DoAction("next decouple system", true).
    //}
    until time:seconds - LandingTime > 6 and LFBooster < 5 {
        CheckFuel().
        clearScreen.
        print "LF onboard: " + round(LFBooster).
        wait 0.3.
    }

    if ship:partsnamed("FNB.BL1.BOOSTERLOX"):length = 0 and ship:partsnamed("FNB.BL3.BOOSTERLOX"):length = 0 BoosterCore:shutdown.
    else for vent in DumpVents if not vent:istype("Boolean") vent:doaction("shutdown engine", true).

    HUDTEXT("Booster may now be recovered!", 10, 2, 20, green, false).
    clearscreen.
    print "Booster may now be recovered!".
    set Idle to true.


    function ClosingAngle {
        set EarlyAngle to (40/(1+constant:e^(-2.5*((RadarRatio) - 3)))) + 10.
        set LateAngle to (1.5/(1+constant:e^(-10*((RadarRatio) - 0.5)))).

        set angle to LateAngle*EarlyAngle.
        // Пол в 8 градусов убран - откат к стоку. С ним руки приходили к бустеру
        // уже почти сомкнутыми (на экране "Arms: 8"), и садиться было некуда.
        // Пол створа. Стоковая кривая уводит раскрытие почти в ноль уже на
        // RA 14 - это метров четырнадцать до посадочных пинов, то есть на
        // уровне решётчатых рулей. Со стоковой скоростью 10 гр/с руки туда
        // просто НЕ УСПЕВАЛИ, и медленность случайно работала защитой. Как
        // только скорость подняли до 24, они успели - и в логе 04.09 сомкнулись
        // на рулях: RA 14 створ 2.75, дальше LngErr 7 -> 0 -> -9 -> -16 -> -24
        // за полторы секунды. Это удар, а не промах наведения.
        //
        // Пол в 8 градусов, который пробовали раньше, тоже не годился - слишком
        // тесно для рулей, бустеру некуда было сесть. По этому логу граница
        // видна: до створа ~11 бустер проходит чисто (RA 56..24, ArmA
        // 15.9..11.3), ниже начинается контакт. Держим 14, с запасом.
        //
        // Порог снятия пола: RadarRatio 0.1 - около 4 м, примерно 0.8 с на той
        // вертикальной скорости. На 24 гр/с руки успевают пройти 19 градусов.
        if RadarRatio > 0.1 set angle to max(angle, 14).
        if BoosterLanded set angle to 0.
        return round(angle,2).
    }

    function ClosingSpeed {
        // Кривая раскрытия НЕ трогается - она стоковая, и правильно: пока пины
        // не пришли, створ обязан оставаться, иначе бустеру некуда опускаться.
        // Меняется только скорость исполнения. По логу 04.09 башня получает
        // команду закрыть последние 16 градусов на RA 58, то есть примерно за
        // полторы секунды до касания, а идёт со стоковой скоростью 10 гр/с -
        // ровно на грани и не успевает. Поэтому: пока створ большой, идём
        // спокойно (руки не дёргаются за плавающей целью), а последние
        // градусы закрываем на максимуме.
        // tower.ks ограничивает скорость 12 только внутри своей ветки
        // подмены угла; в обычном случае ставит ровно то, что прислали.
        if angle > 20 set speed to 8.
        else if angle > 10 set speed to 14.
        else set speed to 24.
        if HighIncl set speed to speed*2.4.
        else if BoosterRot > 15 or BoosterRot < 2 set speed to speed * 2.
        else if BoosterRot > 12 or BoosterRot < 5 set speed to speed * 1.5.
        if fastSticks set speed to speed * 2.4.

        // Потолок 12, а не 24. Панель башни показала Target Speed 10.00 при
        // том, что мы слали 21-24: поле молча отбрасывает значения выше своего
        // максимума и остаётся прошлое. Не зря и сам tower.ks в своей ветке
        // подмены пишет min(targetspeed*3, 12) - это и есть предел поля.
        return min(max(round(speed,1),8),12).
    }

}



FUNCTION SteeringCorrections {
    // Ограничитель крена. Большая ошибка по крену означает не "надо довернуть",
    // а что опорный "верх" задан не тем: бустер идёт верх ногами (roll 180) -
    // это штатное положение, а доворот прокручивает корпус вокруг своей оси.
    // Поэтому выше MaxRollFix доворот запрещаем совсем (диапазон 0 = крен не
    // трогаем), а возвращаем управление с гистерезисом, чтобы не дребезжало.
    //
    // Порог зависит от фазы. На флипе и буст-бэке опорный верх действительно
    // перевёрнут, доворот там раскручивает корпус - держим жёстко, 20 гр.
    // После буст-бэка наведение на планировании считает, что оси корпуса стоят
    // как надо, и ошибка крена настоящая: при 20 гр. она замораживалась навсегда
    // (доворот выключен - крен сам не уменьшается), бустер приходил на посадку
    // с креном 129 гр. и упёртыми в предел LngCtrl/LatCtrl. Тут морозим только
    // около 180, то есть действительно перевёрнутый опорный верх.
    // Пробовал снимать заморозку сразу после разворота (флаг FlipDone) - не
    // годится. Полёт 04.09: с MET 120.6 по 134 крен болтался +-90...99 со
    // сменой знака каждые полсекунды и не сходился. Пока идёт буст-бэк, нос
    // стоит ровно вдоль ApproachVector, а он же служит опорой "верха" -
    // lookDirUp на почти параллельных векторах вырождается и выдаёт
    // произвольное поперечное направление (CmdTopVsUp 81-88 при горизонтальном
    // носе). Гоняться за такой командой нечем и незачем: 14 секунд RCS впустую.
    // Во время бёрна крен держим замороженным, а разворот в coast снимает
    // заморозку явно (см. триггер turnTime + 0.5) - там опора уже невырождена
    // и крен сходится за 4 секунды.
    if BoostBackComplete { set MaxRollFix to 150. set RollFixReturn to 135. }
    else { set MaxRollFix to 20. set RollFixReturn to 12. }
    if abs(SteeringManager:rollerror) > MaxRollFix and not RollFrozen {
        set RollFrozen to true.
        set RollNote to "  [крен заморожен]".
        // Запоминаем ИМЕННО ТЕКУЩЕЕ значение, а не буст-бэковое: дальше по полёту
        // штатный код ставит свои диапазоны (70 на входе, 90, 15 на планировании,
        // 32 перед посадкой). Раньше разморозка возвращала RollRangeNormal,
        // снятый ещё на флипе (180), и затирала настройку текущего этапа.
        set RollRangeSaved to SteeringManager:ROLLCONTROLANGLERANGE.
        set SteeringManager:ROLLCONTROLANGLERANGE to 0.
    }
    else if abs(SteeringManager:rollerror) < RollFixReturn and RollFrozen {
        set RollFrozen to false.
        set RollNote to "".
        set SteeringManager:ROLLCONTROLANGLERANGE to RollRangeSaved.
    }
    if KUniverse:activevessel = ship {
        set addons:tr:descentmodes to list(true, true, true, true).
        set addons:tr:descentgrades to list(true, true, true, true).
        set addons:tr:descentangles to list(180, 180, 180, 180).
        if not addons:tr:hastarget {
            ADDONS:TR:SETTARGET(landingzone).
        }
        if altitude > LandingBurnAlt * 2 and KUniverse:activevessel = vessel(ship:name) and not cAbort {
            set ApproachVector to vxcl(up:vector, landingzone:position - ship:position):normalized.
        } 
        else if altitude > LandingBurnAlt * 2 and KUniverse:activevessel = vessel(ship:name) and cAbort {
            set ApproachVector to vxcl(up:vector, landingzone:position + ship:position):normalized.
        }
        if addons:tr:hasimpact {
            set ErrorVector to ADDONS:TR:IMPACTPOS:POSITION - landingzone:POSITION.
        } 
        set LatError to vdot(AngleAxis(-90, ApproachUPVector) * ApproachVector, ErrorVector).
        set LngError to vdot(ApproachVector, ErrorVector).


        if altitude < 35000 * Scale and BoostBackComplete { //or KUniverse:activevessel = vessel(ship:name) {
            set GS to groundspeed.

            if InitialError = -9999 and addons:tr:hasimpact {
                set InitialError to LngError.
            }
            // Нижние пределы подняты 2.5 -> 5 и 0.5 -> 1.2.
            // По логу 04.09 (последние 700 м) LngCtrl стоял РОВНО на своём
            // потолке: MaxOut 2, LngCtrl 2.0 на RA 587, 530, 327, 243, 208,
            // 145, 116, 91, 69; ниже RA 50 потолок 2.5 и LngCtrl 2.5. LatCtrl
            // так же упирался в +-0.5 от RA 284 до самой земли. То есть
            // регулятор всю посадку просил больше, чем ему разрешено, и
            // TgtErr не сходился - болтался 1.1 -> 5.8 -> 3.4 м.
            // Это не "тяжело даётся коррекция", это запрет на коррекцию.
            // Верхние ограничения (maxAoA/maxRoll) и спад по высоте не тронуты.
            set LngCtrlPID:maxoutput to max(min(abs(LngError - LngCtrlPID:setpoint) / (PIDFactor), maxAoA), 5) * max(0.8,min(1, abs(LngError - LngCtrlPID:setpoint)*20/max(1,RadarAlt))).
            set LngCtrlPID:minoutput to -LngCtrlPID:maxoutput.
            set LatCtrlPID:maxoutput to max(min(abs(LatError) / (10 * Scale), maxRoll), 1.2).
            set LatCtrlPID:minoutput to -LatCtrlPID:maxoutput.

            set LngCtrl to -LngCtrlPID:UPDATE(time:seconds, LngError).
            set LatCtrl to -LatCtrlPID:UPDATE(time:seconds, LatError).
            if LngCtrl > 0 {
                set LatCtrl to -LatCtrl.
            }

            // maxDecel5/maxDecel3 делились на min(ship:mass, BoosterReturnMass - k):
            // константа из профиля (125 т) и обещанный "к тому моменту станем легче"
            // давали знаменатель ~55 т при реальных 134 т. Модель считала, что пять
            // двигателей дают 50 м/с2, тогда как реально они дают 13.7 - отсюда ранний
            // переход 13->5 и удар. Торможение - величина ТЕКУЩАЯ, делим на ship:mass.
            // Тяга - измеренная (RaptorThrustLive), константа остаётся запасным
            // вариантом на случай, если замер так и не получился.
            set RTeff to BoosterRaptorThrust.
            set RT3eff to BoosterRaptorThrust3.
            if RaptorThrustLive > 0 {
                set RTeff to RaptorThrustLive.
                set RT3eff to RaptorThrustLive.
            }
            if LandingBurnStarted and BoosterSingleEngines and Bl3LndProf {
                set maxDecel to max((ActiveRC * RTeff / ship:mass) - 9.805, 0.00001).
                set maxDecel5 to max((min(ActiveRC,5) * RT3eff / ship:mass) - 9.805, 0.00001).
                set maxDecel3 to max((min(ActiveRC,3) * RT3eff / ship:mass) - 9.805, 0.00001).
            }
            else if LandingBurnStarted and BoosterSingleEngines {
                set maxDecel to max((ActiveRC * RTeff / ship:mass) - 9.805, 0.00001).
                set maxDecel3 to max((min(ActiveRC,3) * RT3eff / ship:mass) - 9.805, 0.00001).
            }
            else if BoosterSingleEngines and Bl3LndProf {
                set maxDecel to max(((13-missingCount) * RTeff / ship:mass) - 9.805, 0.00001).
                set maxDecel5 to (5 * RT3eff / ship:mass) - 9.805.
                set maxDecel3 to (3 * RT3eff / ship:mass) - 9.805.
            }
            else if BoosterSingleEngines {
                set maxDecel to max(((13-missingCount) * RTeff / ship:mass) - 9.805, 0.00001).
                set maxDecel3 to (3 * RT3eff / ship:mass) - 9.805.
            }
            else if Bl3LndProf {
                set maxDecel to max((13 * RTeff / ship:mass) - 9.805, 0.00001).
                set maxDecel5 to (5 * RT3eff / ship:mass) - 9.805.
                set maxDecel3 to (3 * RT3eff / ship:mass) - 9.805.
            }
            else {
                set maxDecel to max((13 * RTeff / ship:mass) - 9.805, 0.00001).
                set maxDecel3 to (3 * RT3eff / ship:mass) - 9.805.
            }

            
            set DragDecel to ((airspeed^2)/9000) * min(1,305/airspeed).

            //Block 3 Landing Profile
            if Bl3LndProf and defined maxDecel5 {
                if LandingBurnStarted {
                    set MidShutdownSpeed to min(max(50, sqrt(max(10, (2*RadarAlt - (airspeed^2)/maxDecel + (12^2)/(maxDecel5*0.75)  - (12^2)/(maxDecel3*0.7)) / (1/(maxDecel5*0.75) - 1/maxDecel) ))) , 150).
                    set stopTime3 to 12 / (maxDecel3*0.7).
                    set stopTime5 to (MidShutdownSpeed-12) / (maxDecel5*0.75).
                    set stopTime13 to (airspeed - MidShutdownSpeed) / maxDecel.
    
                    set TotalstopTime to stopTime3 + stopTime5 + stopTime13.
    
                    set stopDist3 to 6 * stopTime3.
                    set stopDist5 to ((MidShutdownSpeed - 12)/2) * stopTime5.
                    set stopDist13 to ((airspeed - MidShutdownSpeed)/2)*stopTime13.
                    set TargetMidShutdown to (airspeed^2 - 124^2)/(2*maxDecel) + (124^2 - 12^2)/(2*maxDecel5) + (12^2)/(2*maxDecel3).
    
                    set TotalstopDist to stopDist3 + stopDist5 + stopDist13.
                } else {
                    set MidShutdownSpeed to min(sqrt(max(10, (2*RadarAlt - (airspeed^2)/maxDecel + (12^2)/(maxDecel5*0.75)  - (12^2)/(maxDecel3*0.7)) / (1/(maxDecel5*0.75) - 1/maxDecel) )) , 150).
                    set stopTime3 to 12 / (maxDecel3*0.65).
                    set stopTime5 to 112 / (maxDecel5*0.7).
                    set stopTime13 to (airspeed - 124) / maxDecel.

                    set TotalstopTime to stopTime3 + stopTime5 + stopTime13.

                    set stopDist3 to 6 * stopTime3.
                    set stopDist5 to 56 * stopTime5.
                    set stopDist13 to ((airspeed - 124)/2)*stopTime13.
                    set TargetMidShutdown to (airspeed^2 - 124^2)/(2*maxDecel) + (124^2 - 12^2)/(2*maxDecel5) + (12^2)/(2*maxDecel3).

                    set TotalstopDist to stopDist3 + stopDist5 + stopDist13.
                }



                //Decel 13 Engines
                if not MiddleEnginesShutdown and not downToThree {
                    set ReqDecel to (max(MidShutdownSpeed,airspeed)^2 - MidShutdownSpeed^2)/(2*(max(0.1, RadarAlt - (TargetMidShutdown+stopDist3+stopDist5)/2))) - DragDecel.
                    set landingRatio to max(0,  ReqDecel / (maxDecel  * cos(vang(-velocity:surface, up:vector)))) + 0.02.
                }//Decel 5 Engines
                else if not downToThree {
                    // Раньше цель была жёстко "12 м/с" - промежуточная, под
                    // передачу на 3 движка (тот же запас stopDist3*1.5). При
                    // Land5EnginesOnly двигатели больше не переключаются, эта
                    // ветка теперь работает до самой земли - цель ДОЛЖНА быть
                    // TouchdownSpeed, а не устаревший хардкод. Запас по высоте
                    // взят как в 3-двигательной ветке (запас ВРЕМЕНИ, не скорости).
                    set ReqDecel to (max(TouchdownSpeed,airspeed)^2 - TouchdownSpeed^2)/(2*(max(0.1, RadarAlt - 2.0*Scale))) - DragDecel.
                    set landingRatio to max(0,  ReqDecel / (maxDecel5  * cos(vang(-velocity:surface, up:vector)))) - 0.01.
                }//Decel 3 Engines
                else {
                    // Цель TouchdownSpeed (было 1 м/с - слишком жёстко для этого
                    // профиля, часто упирались в нижний предел ReqDecel и не
                    // успевали затормозить). Запас по высоте 2.0*Scale оставлен
                    // как есть - он про запас ВРЕМЕНИ на манёвр, не про скорость.
                    set ReqDecel to (max(TouchdownSpeed,airspeed)^2 - TouchdownSpeed^2)/(2*(max(0.1, RadarAlt - 2.0*Scale))).
                    set landingRatio to max(0,  ReqDecel / (maxDecel3  * cos(vang(-velocity:surface, up:vector)))).
                }

            //Block 2 Landing Profile
            } else {
                if LandingBurnStarted {
                    set MidShutdownSpeed to min(max(12,sqrt(max(0, (2*RadarAlt - airspeed^2/maxDecel)/(1/(maxDecel3*0.85) - 1/maxDecel) ))) , 80).
                    set stopTime3 to MidShutdownSpeed / (maxDecel3*0.85).
                    set stopTime13 to (airspeed - MidShutdownSpeed) / maxDecel.

                    set TotalstopTime to stopTime3 + stopTime13.

                    set stopDist3 to MidShutdownSpeed/2 * (stopTime3).
                    set stopDist13 to ((airspeed - MidShutdownSpeed)/2)*stopTime13.
                    set TargetMidShutdown to (airspeed^2 - 69^2)/(2*maxDecel) + (69^2)/(2*maxDecel3).

                    set TotalstopDist to stopDist3 + stopDist13.
                }
                else {
                    set MidShutdownSpeed to min(sqrt(max(0, (2*RadarAlt - airspeed^2/maxDecel)/(1/(maxDecel3*0.85) - 1/maxDecel) )) , 80).
                    set stopTime3 to 69 / (maxDecel3*0.8).
                    set stopTime13 to (airspeed - 75) / maxDecel.

                    set TotalstopTime to stopTime3 + stopTime13.

                    set stopDist3 to 37.5 * (stopTime3).
                    set stopDist13 to ((airspeed - 75)/2)*stopTime13.
                    set TargetMidShutdown to (airspeed^2 - 69^2)/(2*maxDecel) + (69^2)/(2*maxDecel3).

                    set TotalstopDist to stopDist3 + stopDist13.
                }


                //Decel 13 Engines
                if not MiddleEnginesShutdown {
                    set ReqDecel to (max(MidShutdownSpeed,airspeed)^2 - MidShutdownSpeed^2)/(2*(max(stopDist3+0.1, RadarAlt)-stopDist3)) - DragDecel.
                    set landingRatio to max(0,  ReqDecel / (maxDecel * cos(vang(-velocity:surface, up:vector)))).
                }//Decel 3 Engines
                else {
                    set ReqDecel to (max(1,airspeed)^2 - 1^2)/(2*(max(0.5*Scale+0.1, RadarAlt) - 0.5*Scale)).
                    set landingRatio to max(0,  ReqDecel / (maxDecel3 * cos(vang(-velocity:surface, up:vector)))).
                }
            }
            
            if CorrFactor * groundspeed < LngCtrlPID:setpoint and alt:radar < 8000 and not downToThree {
                set LngCtrlPID:setpoint to CorrFactor * groundspeed.
            }
            else if LandingBurnStarted set LngCtrlPID:setpoint to 0.
            if dbactive and not LandingBurnStarted {
                set LatCtrlPID:setpoint to (vAng(TheTowerHeadingVector,vCrs(up:vector,ApproachVector)) - 90)/2.
            }
            else if LandingBurnStarted set LatCtrlPID:setpoint to 0.
        } 

        clearscreen.
        print "Lng Error: " + round(LngError) + " / " + round(LngCtrlPID:setpoint).
        print "Lat Error: " + round(LatError) + " / " + round(LatCtrlPID:setpoint).
        print "Radar Alt: " + round(RadarAlt) + "m".
        //print " ".

        if not LandingBurnStarted {
            // TotalstopDist считается по ТЕКУЩЕЙ скорости и занижает потребную высоту
            // для профиля 13-5-3: у него фазы на 5 и 3 двигателях очень пологие.
            // Полная потребная дистанция профиля лежит в TargetMidShutdown, поэтому
            // для Bl3LndProf берём максимум из двух. Иначе ожог стартует уже "позади
            // графика" (ReqDecel 110 при MaxDecel 56) и бустер жжёт всё топливо.
            if Bl3LndProf {
                set LandingBurnAlt to min(max(750 + airspeed*IgnitionTime, max(TotalstopDist, TargetMidShutdown)*cos(vang(-velocity:surface, up:vector)) + airspeed*IgnitionTime) , 7000).
            }
            else {
                set LandingBurnAlt to min(max(750 + airspeed*IgnitionTime, TotalstopDist*cos(vang(-velocity:surface, up:vector)) + airspeed*IgnitionTime) , 7000).
            }
        }
        

        if altitude < 30000 and not (RSS) or altitude < 50000 and RSS {
            print "LngCtrl: " + round(LngCtrl, 2) + " / " + round(LngCtrlPID:maxoutput, 1).
            print "LatCtrl: " + round(LatCtrl, 2) + " / " + round(LatCtrlPID:maxoutput, 1).
            if defined TowerHeading print "Tower Heading: " + TowerHeading.
            print " ".
            print "Landing Burn Alt: " + round(LandingBurnAlt, 1) + " m".
            print "MidShutdown: " + round(MidShutdownSpeed,1) + " m/s   | " + TargetMidShutdown.
            if EC and defined missingCount print "Eng: - missing: "+missingCount+" - inactive: "+inactiveCount.
            print " ".
            print "Drag Decel: " + round(DragDecel,1).
            print "Max Decel: " + round(maxDecel, 2).
            if defined ReqDecel print "ReqDecel: " + round(ReqDecel,2).
            print "Stop Time: " + round(TotalstopTime, 2).
            print "Stop Distance: " + round(TotalstopDist, 2).
            if defined stopDist5 print "Stop Distance 5: " + round(stopDist5, 2).
            print "Stop Distance 3: " + round(stopDist3, 2).
            print "Landing Ratio: " + round(landingRatio, 2).
            print " ".
            print "MZ Rotation: " + Round(BoosterRot,1) + "  | Arms: " + round(angle,1).
            print "Booster Mass: " + round(ship:mass,3).
            print "Descent Angle: " + round(vang(-velocity:surface, up:vector), 1).
            print "AoA: " + round(vAng(-velocity:surface,facing:forevector),1).
            print "GS: " + round(groundspeed,2).
            print " ".
            print "Dist.: " + round(landDistance,1) + " m     | " + RadarRatio.
            if defined tgtError print "TgtError: " + round(tgtError,1) + " m".
            print " ".
        }
    }
    else {
        clearscreen.
        print "Booster: Return in Progress..".
        print " ".
        print "Radar Altitude: " + round(RadarAlt).
        //if ShipExists {
        //    print "Ship Distance: " + (round(vessel(starship):distance) / 1000) + "km".
        //}
    }
    if not (LFBooster = 0) {
        print "LF on Board: " + round(LFBooster, 1) + " / " + round(LFBoosterFuelCutOff).
        // Тот же остаток в тоннах LF (по плотности самого ресурса) и, отдельно,
        // полная масса топлива на борту (LF + окислитель).
        print "LF: " + round(LFBooster * LFdensity, 2) + " t / reserve " + round(LFBoosterFuelCutOff) + " ed = " + round(LFBoosterFuelCutOff * LFdensity, 2) + " t".
        print "Prop total: " + round(ship:mass - ship:drymass, 2) + " t".
    }
    print " ".
    // Что реально происходит с двигателями и тягой в фазе посадки: без этих
    // чисел модель торможения и факт расходятся, а по печати не видно, где.
    // ActiveRC - сколько двигателей насчитано горящими, thr - команда на тягу,
    // mid/d3 - флаги переходов 13->5 и 5->3.
    if LandingBurnStarted {
        print "Eng: " + ActiveRC + " act | thr " + round(throttle, 2) + " | thrust " + round(ship:thrust) + " kN".
        print "mid: " + MiddleEnginesShutdown + " | d3: " + downToThree + " | VS: " + round(verticalSpeed, 1).
    }
    print "Steering Error: " + round(SteeringManager:angleerror, 2) + "  | Roll Error: " + round(SteeringManager:rollerror, 2) + RollNote.
    if not BoostBackComplete print " ".
    if not BoostBackComplete print "FlipTime: " + round(FlipTime, 2).
    if FlipRampActive {
        print "Flip cmd: " + round(FlipCmdAngle, 1) + " / act: " + round(vAng(ship:facing:forevector, FlipStartFacing:forevector), 1) + " / total: " + round(FlipTotalAngle, 1).
    }
    // Крен показываем ВСЮ дорогу до конца буст-бэка, а не только на рампе:
    // жалоба была именно на вращение по крену ПОСЛЕ разделения.
    // "top vs up" 180 = верх ногами (как и должно быть), 0 = перевернулся обратно.
    // "cmd top vs up" - тот же угол у КОМАНДЫ: если он тоже гуляет, крутится
    // цель наведения, а не корпус.
    if not BoostBackComplete {
        print "top vs up: " + round(vAng(ship:facing:topvector, up:vector), 1) + " (180 = верх ногами)".
        if not FlipRampActive print "cmd top vs up: " + round(vAng(SteeringVector:topvector, up:vector), 1) + "  | fore vs up: " + round(vAng(SteeringVector:forevector, up:vector), 1).
    }
    if LandingBurnStarted print ship:control:pilotmainthrottle.
    //print " ".
    //local unusedLines to opcodesleft.
    //print "CPU operations: " + (config:ipu-unusedLines):tostring +"/"+config:ipu + " (unused: "+opcodesleft+")".
    //print "CPU speed: " + config:ipu.

    LogBoosterFlightData().
}


function LandingThrottle {
    set minThrottle to 0.33.
    set thro to max(0.33, landingRatio).
    if verticalSpeed > -5 set thro to minThrottle * min(min(3,landingRatio/0.33),verticalSpeed/(CatchVS*1.5)).
    if verticalSpeed > CatchVS*1.5 set thro to minThrottle.
    if thro < 0.24 set thro to 0.24.
    if thro > 1 {
        return 1.
    } else {
        return thro.
    }
}


function LandingGuidance {
    set OffsetPosVec to vxcl(up:vector, landingzone:position-BoosterCore:position).
    set RadarRatio to max(RadarAlt/BoosterHeight,0.001).
    set landDistance to sqrt(RadarAlt^2 + PositionError:mag^2).
    set CatchPins to BoosterCore:position + BoosterHeight*0.4 * facing:forevector.
    set CatchPos to landingzone:position + MZHeight*up:vector + TheTowerHeadingVector:normalized * angleAxis(ApproachAngle/2, up:vector)
        - CatchOffsetAlong*(Scale^0.6)*TheTowerHeadingVector:normalized
        + CatchOffsetSide*(Scale^0.6)*vCrs(up:vector, TheTowerHeadingVector:normalized):normalized.
    set PredictGSVec to GSVec:normalized * min(36.5*Scale,GSVec:mag) 
        + vxcl(up:vector, facing:forevector):normalized*vAng(facing:forevector, up:vector)*min(13,ActiveRC)/(Scale*(min(7,ActiveRC)-2)). 

    // === Future Offset from Target ===
    if addons:tr:hasimpact and RadarAlt > 3*Scale set myFuturePos to addons:tr:impactpos:position + MZHeight*(CatchPins-addons:tr:impactpos:position + velocity:surface/9.81):normalized*1/cos(vAng((CatchPins-addons:tr:impactpos:position + velocity:surface/9.81), up:vector)).
    else set myFuturePos to CatchPos.
    set TargetError to CatchPos - myFuturePos - PredictGSVec.
    if defined TowerHeadingVector set collisionAvoider to min(1,vAng(TargetError,TowerHeadingVector)/69)^4.
    else set collisionAvoider to 1.

    // === Guidance ===
    set MainVector to 
        (CatchPins - CatchPos + 0.5 * OffsetPosVec):normalized * max(0,RadarRatio-2.5) * min(1,airspeed/120)
        + up:vector * 3/max(1,RadarRatio^1.5) * 140/max(140,airspeed).

    set tgtError to max(1.75*Scale,TargetError:mag)/(1.75*Scale) * max(1, 1/max(0.75,abs(RadarRatio-1))).
    if RadarRatio > 0.5 set TargetReachFactor to max(max(-RadarRatio+1.1, -1), 1.06 - OffsetPosVec:mag/max(1,GSVec:mag*max(0.8,TotalstopTime-0.8))).
    else set TargetReachFactor to 1.1.
    set GSCancel to GSVec * 1.2/max(0.6,RadarRatio) * TargetReachFactor.
    set GuidVec to
        TargetError:normalized * tgtError
        - GSCancel
        + PositionError:normalized * min(4,tgtError) * 1/max(1,RadarRatio-4) * min(1,RadarRatio-0.5) * collisionAvoider.

    set FinalVec to MainVector:normalized * BoosterHeight/min(max(0.8,RadarRatio^0.7), 1 * 150/max(150,airspeed)) + GuidVec * 160/max(160,airspeed) + facing:forevector * BoosterHeight/4 - velocity:surface * max(0,airspeed-150)/max(1,airspeed/2).

    // == Debug ==
    //set vMain to vecDraw(BoosterCore:position+facing:forevector*BoosterHeight/2, MainVector, grey, "Main", 1, true, 0.2).
    //set v1 to vecDraw(BoosterCore:position+facing:forevector*BoosterHeight/2, TargetError:normalized * tgtError, blue, "Tgt", 1, true, 0.2).
    //set v2 to vecDraw(BoosterCore:position+facing:forevector*BoosterHeight/2, - GSCancel, red, "GS", 1, true, 0.2).
    //set vGuid to vecDraw(BoosterCore:position+facing:forevector*BoosterHeight/2, GuidVec, green, "Guid", 1, true, 0.2).
    //set vFinal to vecDraw(BoosterCore:position+facing:forevector*BoosterHeight/2, FinalVec, white, "Final", 1, true, 0.2).
    //set vOffset to vecDraw(myFuturePos + PredictGSVec, TargetError, yellow, "Error", 1, true, 0.1).

    return lookDirUp(FinalVec, RollVector).
}


function AfterLandingTowerOperations {
    // <---- Command Template ---->
    // sendMessage(Vessel(TargetOLM), "MechazillaPushers,0,1," + (12.5 * Scale) + ",true").
    // sendMessage(Vessel(TargetOLM), "MechazillaArms,8.4,0.5,24,false").
    // sendMessage(Vessel(TargetOLM), "MechazillaHeight,"+ 3*Scale + ",0.5").
    // sendMessage(Vessel(TargetOLM), "MechazillaStabilizers,0").
    // <-------------------------->
    set Idle to false.

    bGUI:hide().
    set stable to false.
    set PreDockPos to false.
    set procceed to false.
    set BoosterDockingActive to false.
    set stableTime to time:seconds*10.
    set lastMessage to time:seconds-12.
    set ALTOTime to time:seconds.
    when time:seconds - ALTOTime > 20 and airspeed < 0.1 then {StabReset().}
    set PreDockPosTime to time:seconds+280.
    set CenterTime to time:seconds+120.
    set steeringManager:maxstoppingtime to 0.1.
    //if BoosterType:contains("Block3") lock steering to lookDirUp(up:vector, -RollVector). else 
    lock steering to lookDirUp(up:vector, RollVector).
    Stabalize().
    setTowerHeadingVector().
    setTargetOLM().
    wait until stable.
    print TowerExists.
    wait 0.2.

    sendMessage(Vessel(TargetOLM), "MechazillaPushers,0,0.2," + (2 * maxpusherengage) + ",false").
    when velocity:surface:mag > 0.24 then Stabalize().

    lock PosDiff to (vxcl(up:vector, BoosterEngines[0]:position - Vessel(TargetOLM):dockingports[0]:position)):mag.
    lock RollAngle to vang(vxcl(up:vector, facing:topvector), vxcl(up:vector, TowerBasePart(Vessel(TargetOLM)):position - TowerMountPart(Vessel(TargetOLM)):position)).

    // Тот же зазор держался и после посадки, пока бустер стоит в руках.
    when stableTime + 25 < time:seconds then sendMessage(Vessel(TargetOLM), "MechazillaArms,8.4,0.4," + ArmGripAngle + ",false").
    when PosDiff < 2.4 * Scale then {
        sendMessage(Vessel(TargetOLM), "MechazillaStabilizers," + 0.5*maxstabengage).
    }

    when PosDiff < 1.4 * Scale then {
        sendMessage(Vessel(TargetOLM), "MechazillaStabilizers," + maxstabengage).
        sendMessage(Vessel(TargetOLM), "MechazillaPushers,0,0.2," + maxpusherengage + ",false").
        set timer to time:seconds.
        when time:seconds - timer > 2 and PosDiff > 0.5 and time:seconds - stableTime > 20 then {
            if vAng(up:vector, facing:forevector) > 0.5 {
                sendMessage(Vessel(TargetOLM), "MechazillaStabilizers," + 0.3*maxstabengage).
                wait 3.
                sendMessage(Vessel(TargetOLM), "MechazillaStabilizers," + maxstabengage).
            }
        }
    }

    when PosDiff < 0.5 then {
        HUDTEXT("Lowering Booster..", 7, 2, 20, green, false).
        sendMessage(Vessel(TargetOLM), "MechazillaHeight,"+ round(BoosterDockingHeight/2,2) + ",0.4").
        set CenterTime to time:seconds.
    }

    if PosDiff < 0.4 * Scale and velocity:surface:mag < 0.15 and (RadarAlt > 30 and not RSS or RadarAlt > 45 and RSS) and time:seconds < stableTime + 24 {
        if RollAngle > 4 or PosDiff > 0.14 * Scale {
            StabReset().
            wait until not stabResetRunning.
        }
        set PreDockPos to true.
        HUDTEXT("Docking Operations starting..", 7, 2, 20, green, false).
        BoosterDocking().
        return.
    } else set procceed to true.

    wait 0.

    until PreDockPosTime + 10 < time:seconds and procceed {
        clearScreen.
        print PosDiff.
        if vAng(up:vector, facing:forevector) > 0.6 and airspeed < 0.1 StabReset().
        if RadarAlt < 30 and PosDiff < 0.14*Scale and RollAngle < 4 {HUDTEXT("Docking Operations starting..", 7, 2, 20, green, false). BoosterDocking(). return.}
        if CenterTime + 30 < time:seconds and PosDiff < 0.4 * Scale and velocity:surface:mag < 0.15 and (RadarAlt > 30 and not RSS or RadarAlt > 45 and RSS) {
            set PreDockPosTime to time:seconds.
            set PreDockPos to true.
            SetBoosterActive().
            wait until kuniverse:canquicksave.
            kuniverse:quicksaveto("BoosterDocking").
            HUDTEXT("loading Quicksave to avoid kraken during Docking..", 7, 2, 20, yellow, false).
            wait 2.
            kuniverse:quickloadfrom("BoosterDocking").
            wait 0.2.
        }
        wait 0.1.
    }

    if RollAngle > 4 or PosDiff > 0.14 * Scale {
        sendMessage(Vessel(TargetOLM), "MechazillaStabilizers," + 0.2*maxstabengage).
        sendMessage(Vessel(TargetOLM), "MechazillaPushers,0,0.2," + maxpusherengage + ",true").
        HUDTEXT("RollAngle exceeded! re-aligning..", 7, 2, 20, yellow, false).
        wait 5.
        sendMessage(Vessel(TargetOLM), "MechazillaPushers,0,0.2," + maxpusherengage + ",false").
        wait 3.
        sendMessage(Vessel(TargetOLM), "MechazillaStabilizers," + maxstabengage).
        wait 1.
    }

    HUDTEXT("Docking Operations starting..", 7, 2, 20, green, false).

    BoosterDocking().

    function StabReset {
        set stabResetRunning to true.
        sendMessage(Vessel(TargetOLM), "MechazillaStabilizers," + 0.2*maxstabengage).
        sendMessage(Vessel(TargetOLM), "MechazillaPushers,0,0.2," + maxpusherengage + ",true").
        if RadarAlt < 32 {
            if RadarAlt > 20 sendMessage(Vessel(TargetOLM), ("MechazillaHeight," + round(BoosterDockingHeight - 10*Scale, 2) + ",0.4")).
            else sendMessage(Vessel(TargetOLM), ("MechazillaHeight," + round(BoosterDockingHeight - 4*Scale, 2) + ",0.4")).
        }
        HUDTEXT("RollAngle exceeded! re-aligning..", 7, 2, 20, yellow, false).
        wait 5.
        sendMessage(Vessel(TargetOLM), "MechazillaPushers,0,0.2," + maxpusherengage + ",false").
        wait 3.
        sendMessage(Vessel(TargetOLM), "MechazillaStabilizers," + maxstabengage).
        wait 1.
        set stabResetRunning to false.
    }

    function Stabalize {
        set stable to false.
        until stable {
            if velocity:surface:mag > 0.2 {}
            else {
                wait 2.
                if velocity:surface:mag > 0.2 {}
                else {
                    set stableTime to time:seconds.
                    set stable to true.
                    HUDTEXT("Booster stable, continuing Tower Operations..", 7, 2, 20, green, false).
                }
            }
            if lastMessage + 10 < time:seconds {
                HUDTEXT("Waiting for Booster to stabalize...", 8, 2, 20, yellow, false).
                set lastMessage to time:seconds.
            }
            wait 0.5.
        }
    }
    return.
}




function BoosterDocking {
    set BoosterDockingActive to true.
    wait 1.
    set ship:control:pitch to 0.1.
    wait 0.3.
    set ship:control:pitch to 0.
    wait 0.7.
    sendMessage(Vessel(TargetOLM), "MechazillaPushers,0,0.2," + maxpusherengage + ",false").
    setTowerHeadingVector().
    setTargetOLM().
    set t to time:seconds.
    lock RollAngle to vang(vxcl(up:vector, facing:topvector), vxcl(up:vector, TowerBasePart(Vessel(TargetOLM)):position - TowerMountPart(Vessel(TargetOLM)):position)).
    lock PosDiff to vxcl(up:vector, BoosterEngines[0]:position - Vessel(TargetOLM):dockingports[0]:position):mag.
    when not TowerOnShip() then {
        clearscreen.
        print "Roll Angle: " + round(RollAngle,1) + "°".
        print "Position Error: " + round(PosDiff, 2) + "m".
        print "AngleUp: " + round(vAng(up:vector,facing:forevector))+"°".
        wait 0.001.
        if not TowerOnShip() {
            return true.
        } else {
            if not BoosterSingleEngines MidGimbMod:doaction("free gimbal", true).
            if not BoosterSingleEngines and Block3Cluster Mid2GimbMod:doaction("free gimbal", true).
            if not BoosterSingleEngines CtrGimbMod:doaction("free gimbal", true).
            sendMessage(Vessel(TargetOLM), ("ReDock")).
        }
    }
    if abs(RollAngle) < 5 and airspeed < 2 and PosDiff < 0.4 * Scale {
        clearscreen.
        print "Booster recovery in progress..".
        HUDTEXT("Wait for Booster docking to start..", 5, 2, 20, green, false).
        when abs(RollAngle) > 5 and not TowerOnShip() or PosDiff > 1.5 * Scale and not TowerOnShip() then {
            sendMessage(Vessel(TargetOLM), "EmergencyStop").
            print "Emergency Shutdown commanded! Roll Angle exceeded: " + round(RollAngle, 1).
            //print "Continue manually with great care..".
            HUDTEXT("Emergency Reset commanded! Roll Angle exceeded: " + round(RollAngle, 1), 10, 2, 20, red, false).
            //HUDTEXT("Continue manually with great care..", 10, 2, 20, red, false).
            sendMessage(Vessel(TargetOLM), "MechazillaPushers,0,0.2," + maxpusherengage + ",true").
            wait 5.
            sendMessage(Vessel(TargetOLM), "MechazillaPushers,0,0.2," + maxpusherengage + ",false").
            wait 3.
            sendMessage(Vessel(TargetOLM), "MechazillaStabilizers," + maxstabengage).
            wait 1.
            reboot.
        }

        when PosDiff > 0.4 * Scale then {
            HUDTEXT("Wait for Booster to stabilize..", 5, 2, 20, yellow, false).
            set t to time:seconds.
            until time:seconds > t + 5 {wait 0.}
            set t to time:seconds.
            return true.
        }
        until time:seconds > t + 5 {wait 0.}

        sendMessage(Vessel(TargetOLM), ("MechazillaHeight," + round(BoosterDockingHeight, 2) + ",0.4")).
        DeactivateGridFins().
        set LandingTime to time:seconds.
        when LandingTime + 1 < time:seconds then {
            set ship:control:pitch to 0.1.
            wait 0.3.
            set ship:control:pitch to 0.
        }
        clearscreen.
        HUDTEXT("Booster docking in progress..", 50, 2, 20, green, false).

        when time:seconds > LandingTime + 50 * Scale and not (BoosterDocked) then {
            HUDTEXT("Docking Booster..", 10, 2, 20, green, false).
            sendMessage(Vessel(TargetOLM), ("MechazillaHeight," + round(BoosterDockingHeight - 0.3*Scale, 2) + ",0.05")).
            wait 6 * Scale.
            sendMessage(Vessel(TargetOLM), ("MechazillaHeight," + round(BoosterDockingHeight, 2) + ",0.05")).
            wait 6 * Scale.
            return false.
        }
        when TowerOnShip() then {
            set BoosterDocked to true.
        }

        when BoosterDocked then {
            HUDTEXT("Booster Docked! Resetting tower..", 20, 2, 20, green, false).
            sendMessage(Vessel(TargetOLM), ("MechazillaHeight," + round(BoosterDockingHeight + 3*Scale, 2) + ",0.5")).
            sendMessage(Vessel(TargetOLM), "MechazillaArms,8.4,2.5,35,true").
            set DockedTime to time:seconds.
            if ship:partstitled("Starship Orbital Launch Mount"):length > 0 {
                if ship:partstitled("Starship Orbital Launch Mount")[0]:getmodule("ModuleAnimateGeneric"):hasevent("open clamps + qd") {
                    ship:partstitled("Starship Orbital Launch Mount")[0]:getmodule("ModuleAnimateGeneric"):DoAction("toggle clamps + qd", true).
                }
            }
            when time:seconds > DockedTime + 7.5 then {
                sendMessage(Vessel(TargetOLM), "MechazillaHeight,0,0.6").
                sendMessage(Vessel(TargetOLM), "MechazillaArms,8.4,5,35,true").
                sendMessage(Vessel(TargetOLM), ("MechazillaPushers,0,1," + (12.5 * Scale) + ",true")).
                sendMessage(Vessel(TargetOLM), "MechazillaHeight,1,1.2").
                if not oldArms {sendMessage(Vessel(TargetOLM), "MechazillaStabilizers,0").}
                when time:seconds > DockedTime + 20 then {
                    sendMessage(Vessel(TargetOLM), "MechazillaArms,8.4,5,90,true").
                    when time:seconds > DockedTime + 30 then {
                        set TowerReset to true.
                        HUDTEXT("Booster recovery complete, tower has been reset!", 10, 2, 20, green, false).
                        //if BoosterCore:getmodule("ModuleSepPartSwitchAction"):getfield("current decouple system") = "Decoupler" {
                        //BoosterCore:getmodule("ModuleSepPartSwitchAction"):DoAction("next decouple system", true).
                        //}
                        reboot.
                    }
                }
            }
        }
    }
    else {
        clearscreen.
        sendMessage(Vessel(TargetOLM), "EmergencyStop").
        print "Emergency Shutdown commanded! Roll Angle exceeded: " + round(RollAngle, 1).
        //print "Continue manually with great care..".
        HUDTEXT("Emergency Reset commanded! Roll Angle exceeded: " + round(RollAngle, 1), 10, 2, 20, red, false).
        //HUDTEXT("Continue manually with great care..", 10, 2, 20, red, false).
        sendMessage(Vessel(TargetOLM), "MechazillaPushers,0,0.2," + maxpusherengage + ",true").
        wait 5.
        sendMessage(Vessel(TargetOLM), "MechazillaPushers,0,0.2," + maxpusherengage + ",false").
        wait 3.
        sendMessage(Vessel(TargetOLM), "MechazillaStabilizers," + maxstabengage).
        wait 1.
        reboot.
    }
}





function LogBoosterFlightData {
    if not LogData return.
    if not homeconnection:isconnected return.

    // Заголовок пишем один раз, при первом вызове.
    if PrevLogTime = 0 {
        set PrevLogTime to time:seconds.
        LOG "MET,Phase,RadarAlt,Alt,VSpd,Airspeed,DistToTgt_km,LngErr,LatErr,AoA,Throttle,Mass_t,SteerErr,RollErr,RollFrozen,TopVsUp,CmdTopVsUp,FlipCmd,EngAct,EngMask,LF,LFCutoff,EvMaxQ,EvSep,EvSeco,EvLand,LiftoffMass_t,LiftoffTWR,ArmAngle,ArmSpeed,BoosterRot,LandingBurnAlt,TotalstopDist,TargetMidShutdown,MidShutdownSpeed,ReqDecel,LandingRatio,RaptorkN,MaxDecel,MaxDecel5,GS,LngSet,LngCtrl,LatCtrl,LngMaxOut,TgtErr,NoseVsTgt,PredGS,TgtAlong,TgtSide,ArmsClosed,RotRate,Scale,GlideD,BoostH,Ox,OxPct,HdgFix,HdgAz" to "0:/BoosterFlightData.csv".
        return.
    }
    // 0.5 c: флип длится ~9 c, посекундная запись его смазывает.
    if time:seconds < PrevLogTime + 0.5 return.
    set PrevLogTime to time:seconds.

    local met is 0.
    if missionTimer > 0 set met to time:seconds - missionTimer.
    // landingzone глобально не объявлена — до выбора зоны её просто нет
    local dist is -1.
    if defined landingzone set dist to vxcl(up:vector, landingzone:position - ship:position):mag / 1000.
    // Крен корпуса и крен КОМАНДЫ: если гуляет только первый - не хватает
    // управления, если оба - крутится сама цель наведения.
    local topUp is vAng(ship:facing:topvector, up:vector).
    // Раньше здесь стояло vAng(SteeringVector:topvector, up:vector), но во
    // время буст-бэка рулит SteeringVectorBoostback, а SteeringVector лежит
    // с прошлого этапа - колонка показывала не ту команду, что исполнялась.
    // SteeringManager:target - это то, что реально отрабатывается сейчас.
    local cmdUp is vAng(SteeringManager:target:topvector, up:vector).
    local frozen is 0.
    if RollFrozen set frozen to 1.

    // Точные тайминги событий - те же переменные, что WriteTelemetry шлёт в
    // живой telemetry.json (он перезаписывается каждый кадр и после полёта
    // не восстановить). Тут они попадают в CSV на каждой строке, поэтому для
    // калибровки вех в оверлее хватит прочитать любую строку лога.
    local evq is -1.
    if defined MaxQTime set evq to round(MaxQTime - missionTimer, 1).
    local evs is -1.
    // Веха ставилась по HotstagingTime - это момент запуска двигателей корабля
    // при ещё СОЕДИНЁННЫХ ступенях, то есть фактически MECO. Реальное разделение
    // (SeparationTime) наступает позже. Берём его, а горячее разделение
    // оставляем запасным вариантом, если разделения ещё не было.
    if defined SeparationTime set evs to round(SeparationTime - missionTimer, 1).
    else if defined HotstagingTime set evs to round(HotstagingTime - missionTimer, 1).
    local evc is -1.
    if defined SECOTime set evc to round(SECOTime - missionTimer, 1).
    // Масса и тяговооружённость РОВНО в момент отрыва - чтобы со временем
    // (несколько полётов с разной нагрузкой) вывести по факту, как от них
    // зависят MaxQ/Sep, вместо одной цифры на всех.
    local loMass is -1.
    if defined LiftoffMass set loMass to round(LiftoffMass, 2).
    local loTWR is -1.
    if defined LiftoffTWR set loTWR to round(LiftoffTWR, 3).
    local evl is -1.
    if TouchdownTime > 0 set evl to round(TouchdownTime - missionTimer, 1).
    else if BoosterLanded and defined LandingTime set evl to round(LandingTime - missionTimer, 1).

    // Раскрытие/скорость рук и разворот бустера для башни - существуют только
    // с момента первой команды на руки (RadarAlt < 5*BoosterHeight), до этого
    // не defined. Нужны, чтобы увидеть рывки рук и скачки поворота по логу,
    // а не только на глаз в моменте касания.
    local armA is -1.
    if defined ArmAngle set armA to ArmAngle.
    local armS is -1.
    if defined ArmSpeed set armS to ArmSpeed.
    local bRot is -1.
    if defined BoosterRot set bRot to round(BoosterRot, 1).

    // Числа, по которым можно проверить гипотезу "нужно раньше зажигаться":
    // если к моменту, когда 5-двигательная фаза реально доходит до 12 м/с
    // (или обязана по времени/скорости переключиться на 3), запас RadarAlt
    // над TotalstopDist/TargetMidShutdown уже съеден - значит ожог просто
    // стартует поздно относительно того, что модель сама считает нужным.
    local lba is -1.
    if defined LandingBurnAlt set lba to round(LandingBurnAlt, 1).
    local tsd is -1.
    if defined TotalstopDist set tsd to round(TotalstopDist, 1).
    local tms is -1.
    if defined TargetMidShutdown set tms to round(TargetMidShutdown, 1).
    local mss is -1.
    if defined MidShutdownSpeed set mss to round(MidShutdownSpeed, 1).
    local rqd is -1.
    if defined ReqDecel set rqd to round(ReqDecel, 2).
    local lnr is -1.
    if defined landingRatio set lnr to round(landingRatio, 2).
    // Сырой замер тяги (даже отбракованный фильтром) и обе модели торможения:
    // по ним сразу видно, сходится ли модель с фактическим изменением скорости.
    local rkn is -1.
    if RaptorMeasured > 0 set rkn to round(RaptorMeasured, 1).
    local mdc is -1.
    if defined maxDecel set mdc to round(maxDecel, 2).
    local mdc5 is -1.
    if defined maxDecel5 set mdc5 to round(maxDecel5, 2).
    // Горизонтальное наведение целиком: путевая скорость, ЦЕЛЬ регулятора (она
    // уводится от нуля по скорости), сами выходы и потолок отклонения. По логу
    // видно, что ошибка сходится к 3 м на 266 м, а потом растёт до 8 м к земле -
    // без этих полей нельзя отличить увод цели от упора в предел и от толчка
    // вектором тяги при довороте в вертикаль.
    local gsp is round(groundspeed, 2).
    local lset is -1.
    if defined LngCtrlPID set lset to round(LngCtrlPID:setpoint, 2).
    local lctl is -1.
    if defined LngCtrl set lctl to round(LngCtrl, 2).
    local actl is -1.
    if defined LatCtrl set actl to round(LatCtrl, 2).
    local lmax is -1.
    if defined LngCtrlPID set lmax to round(LngCtrlPID:maxoutput, 2).
    local terr is -1.
    if defined tgtError set terr to round(tgtError, 2).
    // Угол "нос против направления на цель" - ровно та величина, по которой
    // решается выход на полную связку в буст-бэке. Без неё порог не настроить.
    local fta is -1.
    if defined ErrorVector set fta to round(vAng(facing:forevector, vxcl(up:vector, -ErrorVector)), 1).
    // PredictGSVec - предсказанное будущее положение бустера внутри стоковой
    // LandingGuidance(). В нём есть множитель min(13,ActiveRC)/(Scale*(min(7,ActiveRC)-2)),
    // который на переключении 13->5 падает скачком 2.6 -> 1.67. В логе 04.09
    // TgtErr начинал расти ровно с того сэмпла, где сменились двигатели.
    // Эта колонка показывает, дёргается ли предсказание на переключении.
    local pgs is -1.
    if defined PredictGSVec set pgs to round(PredictGSVec:mag, 2).
    // Ошибка захвата РАЗЛОЖЕННАЯ по осям башни. Её модуль (TgtErr) говорит
    // только "мимо на 5 метров", но не куда, а промах систематический и лечится
    // смещением точки прицеливания - для этого нужен знак и ось.
    // TgtAlong - вдоль оси башни, плюс = дальше от башни, к краю палок.
    //            это ось CatchOffsetAlong, но у неё знак обратный.
    // TgtSide  - поперёк палок, та же ось и тот же знак, что у CatchOffsetSide.
    local armsCl is 0.
    if ArmsCloseSent set armsCl to 1.
    // Скорость изменения угла поворота башни. По ней сразу видно, работает ли
    // упреждение защёлки: ноль здесь означает, что оно не считается.
    local rrate is 0.
    if defined RotRate set rrate to round(RotRate, 3).
    // Конфигурация, выбранная при старте. Без неё по логу нельзя сказать, какая
    // ветка планеты сработала, и приходится выводить масштаб косвенно.
    local cfgScale is -1.
    local cfgGlide is -1.
    local cfgBH is -1.
    local cfgOxPct is -1.
    if defined Scale set cfgScale to round(Scale, 2).
    if defined BoosterGlideDistance set cfgGlide to round(BoosterGlideDistance).
    if defined BoosterHeight set cfgBH to round(BoosterHeight, 1).
    if OxBoosterCap > 0 set cfgOxPct to round(100 * OxBooster / OxBoosterCap, 1).
    // Куда реально смотрит опора башни (HdgAz, компасный азимут) и насколько
    // она разошлась со старой позиционной опалой (HdgFix). Без этих двух чисел
    // по логу нельзя сказать, применился фикс heading или нет: в самих углах
    // поворота рук разница в 4 градуса неотличима от обычного доворота.
    // Ожидаем HdgFix около 4.15. Ноль означает, что facing совпал с позиционной
    // опорой, около 90 - что выбрана не та ось детали.
    local hfix is -1.
    local haz is -1.
    if not (TargetOLM = "false") and Vessel(TargetOLM):loaded {
        local hv is vxcl(up:vector, TowerHeadingVector).
        if hv:mag > 0.1 {
            set haz to round(mod(360 + arctan2(vdot(hv, vCrs(up:vector, north:vector)), vdot(hv, north:vector)), 360), 1).
            local pref is vxcl(up:vector, TowerMZpart(Vessel(TargetOLM)):position - TowerBasePart(Vessel(TargetOLM)):position).
            if pref:mag > 0.5 set hfix to round(vAng(hv, pref), 2).
        }
    }
    local tgal is -1.
    local tgsd is -1.
    if defined TargetError and defined TheTowerHeadingVector {
        set tgal to round(vdot(TargetError, TheTowerHeadingVector:normalized), 2).
        set tgsd to round(vdot(TargetError, vCrs(up:vector, TheTowerHeadingVector:normalized):normalized), 2).
    }

    LOG (round(met, 1)
        + "," + oPhase
        + "," + round(RadarAlt)
        + "," + round(altitude)
        + "," + round(verticalspeed, 1)
        + "," + round(airspeed, 1)
        + "," + round(dist, 2)
        + "," + round(LngError)
        + "," + round(LatError)
        + "," + round(vAng(ship:facing:forevector, -velocity:surface), 1)
        + "," + round(throttle * 100)
        + "," + round(ship:mass, 2)
        + "," + round(SteeringManager:angleerror, 2)
        + "," + round(SteeringManager:rollerror, 2)
        + "," + frozen
        + "," + round(topUp, 1)
        + "," + round(cmdUp, 1)
        + "," + round(FlipCmdAngle, 1)
        + "," + ActiveRC
        + "," + EngMask
        + "," + round(LFBooster)
        + "," + round(LFBoosterFuelCutOff)
        + "," + evq
        + "," + evs
        + "," + evc
        + "," + evl
        + "," + loMass
        + "," + loTWR
        + "," + armA
        + "," + armS
        + "," + bRot
        + "," + lba
        + "," + tsd
        + "," + tms
        + "," + mss
        + "," + rqd
        + "," + lnr
        + "," + rkn
        + "," + mdc
        + "," + mdc5
        + "," + gsp
        + "," + lset
        + "," + lctl
        + "," + actl
        + "," + lmax
        + "," + terr
        + "," + fta
        + "," + pgs
        + "," + tgal
        + "," + tgsd
        + "," + armsCl
        + "," + rrate
        + "," + cfgScale
        + "," + cfgGlide
        + "," + cfgBH
        + "," + round(OxBooster)
        + "," + cfgOxPct
        + "," + hfix
        + "," + haz) to "0:/BoosterFlightData.csv".
}


function oBool {
    parameter b.
    if b return "true".
    return "false".
}

// <-------- Телеметрия для внешнего оверлея -------->
// Один плоский JSON, перезаписывается ~10 раз в секунду. Всё, что тут есть,
// скрипт и так считает - никакой дополнительной математики.
// Реальное расположение двигателей в сборке. Нужно оверлею: он рисует 33 картинки
// мода, а у Block 3 средний круг повёрнут иначе, чем на них. Отдаём радиус (в % от
// максимального) и угол в собственной системе корпуса: 0 = "верх", по часовой.
// Считается ОДИН раз — в полёте геометрия не меняется.
function BuildEngineGeometry {
    local rl is list().
    local al is list().
    local maxr is 0.001.
    local i is 1.
    until i > 33 {
        local pl is ship:partstagged(i:tostring).
        if pl:length > 0 {
            // ВАЖНО: имя v занято встроенной функцией V(x,y,z) — kOS роняет
            // весь скрипт с "Not allowed to SET ... BUILTIN_FUNCTION 'v'".
            local pv is pl[0]:position.
            local yy is vdot(pv, ship:facing:topvector).
            local xx is vdot(pv, ship:facing:starvector).
            local rr is sqrt(xx*xx + yy*yy).
            local aa is arctan2(xx, yy).
            if aa < 0 set aa to aa + 360.
            rl:add(rr).
            al:add(aa).
            if rr > maxr set maxr to rr.
        }
        else {
            rl:add(-1).
            al:add(0).
        }
        set i to i + 1.
    }
    set EngGeom to "".
    set i to 0.
    until i > 32 {
        if rl[i] < 0 set EngGeom to EngGeom + "-".
        else set EngGeom to EngGeom + round(rl[i] / maxr * 100) + ":" + round(al[i]).
        if i < 32 set EngGeom to EngGeom + ",".
        set i to i + 1.
    }
}

// У кластерного бустера отдельных двигателей нет — есть режим на всю связку.
// Раскладку знает сам мод (см. ветки EngPicBooster*/ ниже по файлу): режимы дают
// 3 / 5 / 13 / 33, причём пятёрка — это НЕ первые пять, а 1,2,3,6,11 у Block 3
// и 1,2,3,7,11 у остальных.
function BuildClusterMask {
    set EngMask to "".
    local i is 1.
    until i > 33 {
        local lit is false.
        if ActiveRC >= 33 set lit to true.
        else if ActiveRC >= 13 set lit to (i <= 13).
        else if ActiveRC >= 5 {
            if BoosterType:contains("Block3") set lit to (i = 1 or i = 2 or i = 3 or i = 6 or i = 11).
            else set lit to (i = 1 or i = 2 or i = 3 or i = 7 or i = 11).
        }
        else if ActiveRC >= 3 set lit to (i <= 3).
        if lit set EngMask to EngMask + "1".
        else set EngMask to EngMask + "0".
        set i to i + 1.
    }
}

function WriteTelemetry {
    if not homeconnection:isconnected return.
    // Без этого до старта LFBooster/LFBoosterCap остаются нулями: CheckFuel()
    // зовётся только из PollUpdate, а тот работает лишь во время возврата.
    CheckFuel().

    set oPhase to "idle".
    if BoosterLanded set oPhase to "landed".
    else if LandingBurnStarted set oPhase to "landing".
    else if BoostBackComplete set oPhase to "descent".
    else if not Idle set oPhase to "boostback".

    if vAng(facing:forevector, vxcl(up:vector, landingzone:position - BoosterCore:position)) < 90
        set oPitch to 360 - vAng(facing:forevector, up:vector).
    else set oPitch to vAng(facing:forevector, up:vector).

    set oTxt to "{".
    set oTxt to oTxt + """t"":" + round(time:seconds, 2).
    // Если missionTimer остался от прошлой сессии, разница выходит в часы -
    // такое время бессмысленно, отдаём ноль.
    set oMet to time:seconds - missionTimer.
    if abs(oMet) > 86400 set oMet to 0.
    set oTxt to oTxt + ",""met"":" + round(oMet, 1).
    set oTxt to oTxt + ",""phase"":""" + oPhase + """".
    set oTxt to oTxt + ",""alt"":" + round(altitude).
    set oTxt to oTxt + ",""radar"":" + round(RadarAlt, 1).
    set oTxt to oTxt + ",""spd"":" + round(airspeed, 1).
    set oTxt to oTxt + ",""vs"":" + round(verticalspeed, 1).
    set oTxt to oTxt + ",""gs"":" + round(groundspeed, 1).
    set oTxt to oTxt + ",""pitch"":" + round(oPitch, 1).
    set oTxt to oTxt + ",""roll"":" + round(SteeringManager:rollerror, 1).
    set oTxt to oTxt + ",""aoa"":" + round(vAng(-velocity:surface, facing:forevector), 1).
    set oTxt to oTxt + ",""thr"":" + round(throttle * 100).
    set oTxt to oTxt + ",""mass"":" + round(ship:mass, 2).
    set oTxt to oTxt + ",""lf"":" + round(LFBooster).
    set oTxt to oTxt + ",""lfres"":" + round(LFBoosterFuelCutOff).
    set oTxt to oTxt + ",""lfpct"":" + round(100 * LFBooster / max(1, LFBoosterCap), 1).
    set oTxt to oTxt + ",""oxpct"":" + round(100 * OxBooster / max(1, OxBoosterCap), 1).
    set oTxt to oTxt + ",""lngerr"":" + round(LngError).
    set oTxt to oTxt + ",""laterr"":" + round(LatError).
    set oTxt to oTxt + ",""lngset"":" + round(LngCtrlPID:setpoint).
    set oTxt to oTxt + ",""steerr"":" + round(SteeringManager:angleerror, 2).
    set oTxt to oTxt + ",""lba"":" + round(LandingBurnAlt).
    set oTxt to oTxt + ",""ratio"":" + round(landingRatio, 2).
    set oTxt to oTxt + ",""engact"":" + (ActiveRC + ActiveRB).
    if not BoosterSingleEngines BuildClusterMask().
    set oTxt to oTxt + ",""engmask"":""" + EngMask + """".
    set oTxt to oTxt + ",""b3"":" + oBool(BoosterType:contains("Block3")).
    set oTxt to oTxt + ",""enggeom"":""" + EngGeom + """".
    set oTxt to oTxt + ",""engmiss"":" + missingCount.
    // Фактическое время вех, чтобы дуга миссии жила по событиям, а не по
    // расписанию. -1 значит "ещё не случилось".
    set evq to -1.
    if defined MaxQTime set evq to round(MaxQTime - missionTimer, 1).
    set evs to -1.
    // Веха ставилась по HotstagingTime - это момент запуска двигателей корабля
    // при ещё СОЕДИНЁННЫХ ступенях, то есть фактически MECO. Реальное разделение
    // (SeparationTime) наступает позже. Берём его, а горячее разделение
    // оставляем запасным вариантом, если разделения ещё не было.
    if defined SeparationTime set evs to round(SeparationTime - missionTimer, 1).
    else if defined HotstagingTime set evs to round(HotstagingTime - missionTimer, 1).
    set evc to -1.
    if defined SECOTime set evc to round(SECOTime - missionTimer, 1).
    set evl to -1.
    if TouchdownTime > 0 set evl to round(TouchdownTime - missionTimer, 1).
    else if BoosterLanded and defined LandingTime set evl to round(LandingTime - missionTimer, 1).
    // Стартовая масса и тяговооружённость: по ним оверлей масштабирует ожидаемое
    // время вех под конкретную загрузку вместо одной средней цифры на все полёты.
    set oTxt to oTxt + ",""lomass"":" + round(LiftoffMass, 1).
    set oTxt to oTxt + ",""lotwr"":" + round(LiftoffTWR, 4).
    set oTxt to oTxt + ",""evmaxq"":" + evq.
    set oTxt to oTxt + ",""evsep"":" + evs.
    set oTxt to oTxt + ",""evseco"":" + evc.
    // Пока не сел — предсказание Trajectories, оно уточняется на спуске.
    // Брать его можно только когда бустер РЕАЛЬНО возвращается: на площадке и
    // на подъёме hasimpact тоже true, а timetillimpact около нуля, и веха
    // «посадка» уезжала прямо на отметку «сейчас».
    set evleta to -1.
    if BoostBackComplete and verticalspeed < 0 and addons:tr:hasimpact and missionTimer > 0 {
        // Было: если до удара осталось меньше 5 с, предсказание выбрасывалось
        // в -1, оверлей падал обратно на априорную оценку (~338 с) и метка
        // "посадка" оказывалась ПОЗАДИ текущей отметки - выглядело как будто
        // веха сработала, хотя события ещё не было. Отсечка от старта уже
        // обеспечена условиями BoostBackComplete и verticalspeed < 0, так что
        // просто не даём предсказанию уехать в прошлое.
        set evleta to round(max(oMet, oMet + addons:tr:timetillimpact), 1).
    }
    set oTxt to oTxt + ",""evland"":" + evl.
    set oTxt to oTxt + ",""evlandeta"":" + evleta.
    set oTxt to oTxt + ",""arms"":" + round(angle, 1).
    set oTxt to oTxt + ",""mzrot"":" + round(BoosterRot, 1).
    if FlipRampActive set oTxt to oTxt + ",""flipcmd"":" + round(FlipCmdAngle, 1).
    else set oTxt to oTxt + ",""flipcmd"":0".
    set oTxt to oTxt + ",""go"":{""d"":" + oBool(GD) + ",""e"":" + oBool(GE) + ",""f"":" + oBool(GF) + ",""t"":" + oBool(GT) + ",""g"":" + oBool(GG) + ",""catch"":" + oBool(GfC) + "}".
    set oTxt to oTxt + "}".

    set oFile to open("0:/telemetry.json").
    if oFile:istype("Boolean") set oFile to create("0:/telemetry.json").
    oFile:clear().
    oFile:write(oTxt).
}


function sendMessage{
    parameter ves, msg.
    set cnx to ves:connection.
    if cnx:isconnected {
        if cnx:sendmessage(msg) {
            print "message sent..(" + msg + ")".
        }
        else {
            print "message could not be sent..".
        }.
    }
    else {
        print "connection could not be established..".
    }
}


function SetBoosterActive {
    if KUniverse:activevessel = vessel("Booster") {}
    else if time:seconds > lastVesselChange + 2 {
        if not (vessel("Booster"):isdead) {
            if RSS {
                SetLoadDistances(1650000).
            }
            else if KSRSS {
                SetLoadDistances(1000000).
            }
            else {
                SetLoadDistances(350000).
            }
            HUDTEXT("Setting focus to Booster..", 3, 2, 20, yellow, false).
            KUniverse:forceactive(vessel("Booster")).
            set lastVesselChange to time:seconds.
        }
    }
}


function SetStarshipActive {
    if KUniverse:activevessel = vessel(ship:name) and time:seconds > lastVesselChange + 2 and StarshipExists {
        if RSS {
            SetLoadDistances(1650000).
        }
        else if KSRSS {
            SetLoadDistances(1000000).
        }
        else {
            SetLoadDistances(350000).
        }
        HUDTEXT("Setting focus to Ship..", 3, 2, 20, yellow, false).
        KUniverse:forceactive(vessel(starship)).
        set lastVesselChange to time:seconds.
    }
    else {}
}

function SetLoadDistances {
    parameter distance.

    if distance = "default" {
        set ship:loaddistance:flying:unload to 22500.
        set ship:loaddistance:flying:load to 2250.
        wait 0.001.
        set ship:loaddistance:flying:pack to 25000.
        set ship:loaddistance:flying:unpack to 2000.
        wait 0.001.
        set ship:loaddistance:suborbital:unload to 15000.
        set ship:loaddistance:suborbital:load to 2250.
        wait 0.001.
        set ship:loaddistance:suborbital:pack to 10000.
        set ship:loaddistance:suborbital:unpack to 200.
        wait 0.001.
        set ship:loaddistance:landed:unload to 2500.
        set ship:loaddistance:landed:load to 2250.
        wait 0.001.
        set ship:loaddistance:landed:pack to 350.
        set ship:loaddistance:landed:unpack to 200.
        wait 0.001.
    }
    else if distance = "low" {
        set ship:loaddistance:flying:unload to 22500.
        set ship:loaddistance:flying:load to 4250.
        wait 0.001.
        set ship:loaddistance:flying:pack to 25000.
        set ship:loaddistance:flying:unpack to 4000.
        wait 0.001.
        set ship:loaddistance:suborbital:unload to 15000.
        set ship:loaddistance:suborbital:load to 4250.
        wait 0.001.
        set ship:loaddistance:suborbital:pack to 10000.
        set ship:loaddistance:suborbital:unpack to 400.
        wait 0.001.
        set ship:loaddistance:landed:unload to 8500.
        set ship:loaddistance:landed:load to 4250.
        wait 0.001.
        set ship:loaddistance:landed:pack to 3500.
        set ship:loaddistance:landed:unpack to 2000.
        wait 0.001.
    }
    else {
        set ship:loaddistance:flying:unload to distance.
        set ship:loaddistance:flying:load to distance - 5000.
        wait 0.001.
        set ship:loaddistance:flying:pack to distance - 2500.
        set ship:loaddistance:flying:unpack to distance - 10000.
        wait 0.001.
        set ship:loaddistance:suborbital:unload to distance.
        set ship:loaddistance:suborbital:load to distance - 5000.
        wait 0.001.
        set ship:loaddistance:suborbital:pack to distance - 2500.
        set ship:loaddistance:suborbital:unpack to distance - 10000.
        wait 0.001.
        set ship:loaddistance:landed:unload to distance.
        set ship:loaddistance:landed:load to distance - 5000.
        wait 0.001.
        set ship:loaddistance:landed:pack to distance - 2500.
        set ship:loaddistance:landed:unpack to distance - 10000.
        wait 0.001.
    }
}


function CheckFuel {
    // Страховка: в полёте вентиль всегда закрыт. Он включается сам (стартовая
    // ступень активирует ModuleEnginesFX ядра), и тогда сливает топливо, которого
    // не хватает на посадку. Открывается только после касания.
    // Нос выше горизонта? Слив направлен вперёд, поэтому носом вниз он толкает
    // бустер не туда - в таком положении вентиль держим закрытым, даже если слив
    // уже разрешён.
    set NoseUp to (vdot(ship:facing:forevector, up:vector) > 0).
    if not BoosterLanded and (not VentAllowed or not NoseUp) {
        if SinglePartBooster and BoosterCore:hassuffix("thrust") {
            if BoosterCore:thrust > 0 BoosterCore:shutdown.
        }
        else if not SinglePartBooster and FWD:hassuffix("thrust") {
            if FWD:thrust > 0 for vent in DumpVents if not vent:istype("Boolean") vent:doaction("shutdown engine", true).
        }
    }
    // Поднял нос обратно, слив разрешён и топливо ещё выше резерва - открываем снова.
    else if not BoosterLanded and VentAllowed and NoseUp and LFBooster > LFBoosterFuelCutOff {
        if SinglePartBooster and BoosterCore:hassuffix("thrust") {
            if BoosterCore:thrust = 0 BoosterCore:activate.
        }
        else if not SinglePartBooster and FWD:hassuffix("thrust") {
            if FWD:thrust = 0 for vent in DumpVents if not vent:istype("Boolean") vent:doaction("activate engine", true).
        }
    }
    for res in bCH4Tank:resources {
        if res:name = "LiquidFuel" {
            set LFBooster to res:amount.
            set LFBoosterCap to res:capacity.
            if LFBooster < LFBoosterFuelCutOff and not BoosterLanded and SinglePartBooster {
                BoosterCore:shutdown.
            } else if LFBooster < (LFBoosterFuelCutOff*1.1) and not BoosterLanded and (ship:partsnamed("FNB.BL1.BOOSTERLOX"):length > 0) DumpVents[1]:doaction("shutdown engine", true).
        }
        if res:name = "LqdMethane" or res:name = "CooledLqdMethane" {
            set LFBooster to res:amount.
            set LFBoosterCap to res:capacity.
            if LFBooster < LFBoosterFuelCutOff and not BoosterLanded and SinglePartBooster {
                BoosterCore:shutdown.
            } else if LFBooster < (LFBoosterFuelCutOff*1.1) and not BoosterLanded and (ship:partsnamed("FNB.BL1.BOOSTERLOX"):length > 0) DumpVents[1]:doaction("shutdown engine", true).
        }
        if res:name = "Oxidizer" or res:name = "LqdOxygen" or res:name = "CooledLqdOxygen" {
            set OxBooster to res:amount.
            set OxBoosterCap to res:capacity.
        }
    }
    if not SinglePartBooster {
        for res in bCMNDome:resources {
            if res:name = "LiquidFuel" {
                set LFBooster to LFBooster + res:amount.
                set LFBoosterCap to LFBoosterCap + res:capacity.
            }
            if res:name = "LqdMethane" {
                set LFBooster to LFBooster+res:amount.
                set LFBoosterCap to LFBoosterCap+res:capacity.
            }
            if res:name = "Oxidizer" or res:name = "LqdOxygen" or res:name = "CooledLqdOxygen" {
                set OxBooster to res:amount.
                set OxBoosterCap to res:capacity.
                if ((LFBoosterFuelCutOff*1.1)/LFBoosterCap) > OxBooster/OxBoosterCap DumpVents[0]:doaction("shutdown engine", true).
            }
        }
        for res in BoosterCore:resources {
            if res:name = "Oxidizer" or res:name = "LqdOxygen" or res:name = "CooledLqdOxygen" {
                set OxBooster to res:amount.
                set OxBoosterCap to res:capacity.
                if ((LFBoosterFuelCutOff*1.1)/LFBoosterCap) > OxBooster/OxBoosterCap DumpVents[0]:doaction("shutdown engine", true).
            }
        }
        if ship:partsnamed("FNB.BL1.BOOSTERLOX"):length = 0 and ship:partsnamed("FNB.BL3.BOOSTERLOX"):length = 0 for res in FWD:resources {
            if res:name = "LqdMethane" or res:name = "CooledLqdMethane" {
                set boosterCH4 to boosterCH4 + res:amount.
                set boosterCH4Cap to boosterCH4Cap + res:capacity.
                set methane to true.
            }
            if res:name = "LiquidFuel" {
                set boosterCH4 to boosterCH4 + res:amount.
                set boosterCH4Cap to boosterCH4Cap + res:capacity.
                set methane to false.
            }
        }
    }
}


function setLandingZone {
    if homeconnection:isconnected {
        if exists("0:/settings.json") {
            set L to readjson("0:/settings.json").
            if L:haskey("Log Data") {
                if L["Log Data"] = "true" {
                    set LogData to true.
                }
            }
            if L:haskey("Launch Coordinates") {
                if RSS {
                    set landingzone to latlng(L["Launch Coordinates"]:split(",")[0]:toscalar(28.6117), L["Launch Coordinates"]:split(",")[1]:toscalar(-80.5864)).
                    set offshoreSite to latlng(L["Launch Coordinates"]:split(",")[0]:toscalar(28.6117)+0.05, L["Launch Coordinates"]:split(",")[1]:toscalar(-80.5864)+0.3).
                }
                else if KSRSS {
                    set landingzone to latlng(L["Launch Coordinates"]:split(",")[0]:toscalar(28.6117), L["Launch Coordinates"]:split(",")[1]:toscalar(-80.5864)).
                    set offshoreSite to latlng(L["Launch Coordinates"]:split(",")[0]:toscalar(28.6117)+0.05, L["Launch Coordinates"]:split(",")[1]:toscalar(-80.5864)+0.5).
                }
                else {
                    set landingzone to latlng(L["Launch Coordinates"]:split(",")[0]:toscalar(-000.0972), L["Launch Coordinates"]:split(",")[1]:toscalar(-074.5577)).
                    set offshoreSite to latlng(L["Launch Coordinates"]:split(",")[0]:toscalar(-000.0972)+0.02, L["Launch Coordinates"]:split(",")[1]:toscalar(-074.5577)+0.9).
                }
            }
            else {
                if RSS {
                    set landingzone to latlng(28.549072,-80.655925).
                }
                else if KSRSS {
                    if Rescale {
                        set landingzone to latlng(-0.0970,-74.5833).
                    }
                    else {
                        set landingzone to latlng(28.497545,-80.535394).
                    }
                }
                else {
                    set landingzone to latlng(-0.0972,-74.5562).
                }
            }
        }
    }
    else {
        if RSS {
            set landingzone to latlng(28.549072,-80.655925).
        }
        else if KSRSS {
            if Rescale {
                set landingzone to latlng(-0.0970,-74.5833).
            }
            else {
                set landingzone to latlng(28.497545,-80.535394).
            }
        }
        else {
            set landingzone to latlng(-0.0972,-74.5562).
        }
        wait 1.
        setLandingZone().
    }
}


function setTargetOLM {
    list targets in OLMTargets.
    if OLMTargets:length > 0 {
        for x in OLMTargets {
            if x:name:contains("OrbitalLaunchMount") {
                set TowerExists to true.
                if vxcl(up:vector, x:position - landingzone:position):mag < 200 or vxcl(up:vector, BoosterCore:position - x:position):mag < 70 {
                    set TargetOLM to x:name.
                }
            }
        }
    }
}


function ActivateGridFins {
    if GG {
    for fin in GridFins {
        if fin:hasmodule("ModuleControlSurface") {
            fin:getmodule("ModuleControlSurface"):DoAction("activate pitch controls", true).
            fin:getmodule("ModuleControlSurface"):DoAction("activate yaw control", true).
            fin:getmodule("ModuleControlSurface"):DoAction("activate roll control", true).
        }
        if fin:hasmodule("SyncModuleControlSurface") {
            fin:getmodule("SyncModuleControlSurface"):DoAction("activate pitch controls", true).
            fin:getmodule("SyncModuleControlSurface"):DoAction("activate yaw control", true).
            fin:getmodule("SyncModuleControlSurface"):DoAction("activate roll control", true).
        }
    }
    }
}


function DeactivateGridFins {
    if GG {
        for fin in GridFins {
            if fin:hasmodule("ModuleControlSurface") {
                fin:getmodule("ModuleControlSurface"):DoAction("deactivate pitch control", true).
                fin:getmodule("ModuleControlSurface"):DoAction("deactivate yaw control", true).
                fin:getmodule("ModuleControlSurface"):DoAction("deactivate roll control", true).
            }
            if fin:hasmodule("SyncModuleControlSurface") {
                fin:getmodule("SyncModuleControlSurface"):DoAction("deactivate pitch control", true).
                fin:getmodule("SyncModuleControlSurface"):DoAction("deactivate yaw control", true).
                fin:getmodule("SyncModuleControlSurface"):DoAction("deactivate roll control", true).
            }
        }
    }
}


//------ детали башни: Pad B (F3's GSE) или SLE-башня ------//
// У Pad B нет ни SLE.SS.OLIT.MZ, ни титулов "...Tower Base"/"...Mount":
// там OLM.B2 / OLIT.2 / "PadB Chopsticks". Обращение по [0] к пустому списку
// роняло весь скрипт ("Index was out of range") сразу после посадки.

function TowerMZpart {
    parameter TowerVsl.
    if TowerVsl:PARTSNAMEDPATTERN("PadB[ .]Chopsticks"):length > 0 { return TowerVsl:PARTSNAMEDPATTERN("PadB[ .]Chopsticks")[0]. }
    if TowerVsl:PARTSTITLED("Pad B Chopsticks"):length > 0 { return TowerVsl:PARTSTITLED("Pad B Chopsticks")[0]. }
    return TowerVsl:PARTSNAMED("SLE.SS.OLIT.MZ")[0].
}

function TowerBasePart {
    parameter TowerVsl.
    if TowerVsl:PARTSNAMED("OLIT.2"):length > 0 { return TowerVsl:PARTSNAMED("OLIT.2")[0]. }
    return TowerVsl:PARTSTITLED("Starship Orbital Launch Integration Tower Base")[0].
}

function TowerMountPart {
    parameter TowerVsl.
    if TowerVsl:PARTSNAMED("OLM.B2"):length > 0 { return TowerVsl:PARTSNAMED("OLM.B2")[0]. }
    return TowerVsl:PARTSTITLED("Starship Orbital Launch Mount")[0].
}

// Опорное направление башни (куда вылетают руки).
//
// Раньше бралась разность позиций: палочки минус основание башни. Плечо там
// всего 7.8 м, а origin детали палочек смещён вбок примерно на 0.65 м - это
// 4.15 гр систематического перекоса. Проверено на двух разных craft разных
// людей, цифра совпала до третьего знака, значит это свойство самой детали,
// а не кривая установка башни. Линия "башня - стол" на тех же craft даёт
// 0.4-0.6 гр, то есть стол стоит ровно, а origin палочек - нет.
//
// Перекос уходил прямо в GetBoosterRotation (угол поворота рук) и в логах не
// был виден вообще: CatchPos и TgtSide считаются в этой же системе координат,
// контур замкнут сам на себя и невязку не показывает. Отсюда посадки на край
// палочек, которые мы правили офсетами вслепую.
//
// Ориентация детали честная: её ось наклонена на 0.43 гр. Руки вращаются
// анимацией костей (mech2.0left/right, ClawBone/MZBone), root-трансформ при
// этом стоит - facing не поедет вслед за руками.
//
// Какая именно ось модели смотрит вдоль вылета рук, зависит от детали, поэтому
// не угадываем: берём ту горизонтальную ось, что совпала с грубой опорой по
// позициям. Грубая опора врёт на 4 гр, но сторону задаёт однозначно, а ошибиться
// в выборе оси она не даёт - остальные кандидаты отстоят на 90 гр и больше.
function TowerHeadingFrom {
    parameter TowerVsl.
    local mz is TowerMZpart(TowerVsl).
    local u is TowerVsl:up:vector.
    local ref is vxcl(u, mz:position - TowerBasePart(TowerVsl):position).
    if ref:mag < 0.5 { return ref. }
    local best is ref.
    local bestDot is 0.
    local axes is list(mz:facing:starvector, -mz:facing:starvector, mz:facing:topvector, -mz:facing:topvector, mz:facing:forevector, -mz:facing:forevector).
    for v in axes {
        local h is vxcl(u, v).
        if h:mag > 0.3 {
            local d is vdot(h:normalized, ref:normalized).
            if d > bestDot {
                set bestDot to d.
                set best to h.
            }
        }
    }
    return best.
}

function TowerOnShip {
    // детали башни принадлежат нашему судну = мы пристыкованы к башне
    return ship:PARTSTITLED("Starship Orbital Launch Integration Tower Base"):length > 0 or ship:PARTSNAMED("OLIT.2"):length > 0.
}

function setTowerHeadingVector {
    if not (LandSomewhereElse) {
        if not (TargetOLM = "false") and not LandSomewhereElse {
            if GfC {
                set ArmCenterVec to TowerMZpart(Vessel(TargetOLM)):position.
                lock RollVector to vxcl(up:vector, ArmCenterVec - BoosterCore:position).
                if Vessel(TargetOLM):distance < 2100 {
                    if PadB set TowerHeadingVector to TowerHeadingFrom(Vessel(TargetOLM)).
                    else set TowerHeadingVector to vxcl(Vessel(TargetOLM):up:vector, Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position - Vessel(TargetOLM):PARTSTITLED("Starship Orbital Launch Integration Tower Base")[0]:position).
                } else set TowerHeadingVector to angleAxis(-6,up:vector) * vCrs(up:vector, north:vector).
            } else {
                lock RollVector to vxcl(up:vector, velocity:surface).
                set TowerHeadingVector to angleAxis(-6,up:vector) * vCrs(up:vector, north:vector).
            }
        }
    }
}


function GetBoosterRotation {
    if not (TargetOLM = "false") and RadarAlt < ArmRotAlt * Scale and GfC and not LandSomewhereElse and not cAbort {
        //set TowerHeadingVector to vxcl(up:vector, Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position - Vessel(TargetOLM):PARTSTITLED("Starship Orbital Launch Integration Tower Base")[0]:position).
        // Опорная точка расчёта угла раньше переключалась СКАЧКОМ на RadarAlt =
        // 0.9*BoosterHeight (~35-65 м, это уже у самой башни): выше - положение
        // двигателей, ниже - проекция от ядра вперёд по курсу. Обе формулы дают
        // разные векторы, и в момент пересечения порога угол на руки Mechazilla
        // прыгал - в игре это видно как "башня опять довернулась" перед самым
        // захватом. Теперь между формулами плавный переход по высоте (полоса
        // 0.7-1.1 от BoosterHeight), скачка больше нет.
        // Полоса перехода между формулами была 0.7...1.1 высоты бустера, то есть
        // 29-45 м. Дальняя формула - просто пеленг на двигатели, наклон корпуса
        // она не учитывает. Ближняя проецирует ВДОЛЬ ОСИ бустера до плоскости
        // рук, то есть считает, куда он реально придёт с текущим наклоном.
        //
        // Пока защёлка стояла на 0.35 высоты, угол успевал уточниться по ближней
        // формуле. Когда её подняли до 3.0 (чтобы башня успевала доворачиваться),
        // фиксация стала происходить ВЫШЕ полосы - по чистой дальней формуле, и
        // наклон корпуса перестал учитываться совсем. Руки вставали мимо.
        //
        // Лечится не защёлкой, а полосой: точную формулу включаем раньше.
        // Ниже 1.5 высоты (~62 м) - чисто ближняя, выше 3.0 (~123 м) - дальняя,
        // между ними плавный переход. Выше 123 м проекция вдоль оси даёт слишком
        // длинное плечо и шумит на маневрах, поэтому там по-прежнему пеленг.
        set RotBlendHi to BoosterHeight * 3.0.
        set RotBlendLo to BoosterHeight * 1.5.
        set RotBlendK to (RadarAlt - RotBlendLo) / max(0.001, RotBlendHi - RotBlendLo).
        if RotBlendK < 0 set RotBlendK to 0.
        if RotBlendK > 1 set RotBlendK to 1.
        // smoothstep, чтобы у краёв полосы производная тоже была гладкой
        set RotBlendK to RotBlendK * RotBlendK * (3 - 2 * RotBlendK).
        if PadB {
            set varVecClose to vxcl(up:vector, BoosterCore:position + BoosterCore:facing:forevector*(BoosterHeight*0.3-RadarAlt) - Vessel(TargetOLM):PARTSNAMED("PadB.Chopsticks")[0]:position).
            set varPredctVecClose to vxcl(up:vector, BoosterCore:position + BoosterCore:facing:forevector*(BoosterHeight*0.4-RadarAlt) - Vessel(TargetOLM):PARTSNAMED("PadB.Chopsticks")[0]:position + min(3,TotalstopTime)*GSVec*0.5).
            set varVecFar to vxcl(up:vector, BoosterEngines[0]:position - Vessel(TargetOLM):PARTSNAMED("PadB.Chopsticks")[0]:position).
            // Горизонт упреждения ограничен 3 с, как в ближней ветке выше.
            // TotalstopTime теперь считается по РЕАЛЬНОМУ торможению и стал
            // в 2.5 раза больше - руки уводило на точку, куда бустер уже не
            // летит, и они сносили его вбок.
            set varPredctVecFar to vxcl(up:vector, BoosterEngines[0]:position - Vessel(TargetOLM):PARTSNAMED("PadB.Chopsticks")[0]:position + min(3,TotalstopTime)*GSVec*0.65).
        } else {
            set varVecClose to vxcl(up:vector, BoosterCore:position + BoosterCore:facing:forevector*(BoosterHeight*0.3-RadarAlt) - Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position).
            set varPredctVecClose to vxcl(up:vector, BoosterCore:position + BoosterCore:facing:forevector*(BoosterHeight*0.4-RadarAlt) - Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position + min(3,TotalstopTime)*GSVec*0.5).
            set varVecFar to vxcl(up:vector, BoosterEngines[0]:position - Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position).
            // Тот же ограниченный горизонт упреждения, что и для PadB.
            set varPredctVecFar to vxcl(up:vector, BoosterEngines[0]:position - Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position + min(3,TotalstopTime)*GSVec*0.65).
        }
        set varVec to varVecFar * RotBlendK + varVecClose * (1 - RotBlendK).
        set varPredctVec to varPredctVecFar * RotBlendK + varPredctVecClose * (1 - RotBlendK).
        set varVecFinal to varVec + varPredctVec/2.
        set varFinal to vang(varVecFinal, TowerHeadingVector).

        if vAng(vCrs(TowerHeadingVector,up:vector),varVecFinal) < 90 set varFinal to -varFinal.

        // Скорость изменения угла, сглаженная. Нужна ровно для одного момента -
        // защёлки ниже: без неё башня фиксируется на значении, которое ещё росло.
        //
        // Первая версия сравнивала шаг с 0.02 через строгое "больше", а функция
        // зовётся каждый физический кадр, и он равен РОВНО 0.02 - условие не
        // выполнялось никогда, скорость оставалась нулём. В полёте 20:00 угол
        // рос по 0.6 гр/с, а защёлка зафиксировала сырые 7.1 без упреждения,
        // и башня встала недоворотом (руки левее бустера).
        //
        // Теперь база измерения задана явно - четверть секунды, независимо от
        // частоты кадров. На таком плече изменение угла заметно больше шума
        // коротких опорных векторов.
        if RotPrevTime = 0 {
            set RotPrevAngle to varFinal.
            set RotPrevTime to time:seconds.
        }
        else if time:seconds - RotPrevTime >= 0.25 {
            if time:seconds - RotPrevTime < 2 {
                set RotRate to RotRate * 0.6 + ((varFinal - RotPrevAngle) / (time:seconds - RotPrevTime)) * 0.4.
            }
            set RotPrevAngle to varFinal.
            set RotPrevTime to time:seconds.
        }

        // Защёлка угла поворота. Две причины, обе из tower.ks:
        //
        // 1) Опорные векторы у земли становятся короткими и шумными: в логе
        //    04.09 команда прыгнула с 10.9 на 5.5 за полсекунды, а башня в этот
        //    момент уже держит бустер - такой доворот тащит его вбок.
        //
        // 2) Главное: MechazillaArms в башне СНАЧАЛА проверяет, много ли ей ещё
        //    доворачиваться, и если запрошенное раскрытие меньше учетверённой
        //    ошибки поворота - подменяет его на angleerror*2.04. То есть пока
        //    башня не довернулась, руки физически не сомкнутся, сколько нулей
        //    им ни шли. Значит поворот обязан закончиться ДО касания.
        //
        // Порог опущен обратно к 1.0 высоты (~41 м, около полутора секунд).
        // Смысл защёлки - убрать дребезг у самой земли, а не подменять расчёт:
        // на 123 м она фиксировала угол по грубой дальней формуле. Теперь к
        // этой высоте угол уже посчитан по точной ближней (полоса перехода
        // поднята выше), башня вела его несколько секунд и осталась в паре
        // градусов, а последнее уточнение добавляет упреждение по RotRate.
        if RadarAlt < 1.0 * BoosterHeight {
            if not RotLatched {
                set RotLatched to true.
                // Фиксируем не последнее значение, а куда угол ПРИДЁТ к касанию.
                // В логе 04.09 защёлка сработала на 8.3, когда тренд шёл вверх
                // по 0.4 за полсекунды, а в предыдущем полёте угол доходил до
                // 9.9 - башня вставала градуса на два позади бустера.
                // Упреждение ограничено 8 градусами: скорость сглажена, но
                // всё равно считается по коротким и шумным векторам у земли.
                set RotTimeLeft to min(6, RadarAlt / max(1, -verticalspeed)).
                set RotLead to RotRate * RotTimeLeft.
                if RotLead > 8 set RotLead to 8.
                if RotLead < -8 set RotLead to -8.
                set RotLatchValue to min(max(varFinal + RotLead, -64), 48).
            }
            return RotLatchValue.
        }

        //set drawMZA to vecDraw(Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position,varVecFinal,yellow,"Arm Angle",2,true,0.05).

        //set drawTHV to vecDraw(Vessel(TargetOLM):PARTSNAMED("SLE.SS.OLIT.MZ")[0]:position,2.1*TowerHeadingVector:normalized,red,"THV",1,true, 0.1).

        return min(max(varFinal, -64), 48).
    }
}


function SetGridFinAuthority {
    parameter x.
    for fin in GridFins {
        if fin:hasmodule("ModuleControlSurface") {
            fin:getmodule("ModuleControlSurface"):SetField("authority limiter", x).
        }
        if fin:hasmodule("SyncModuleControlSurface") {
            fin:getmodule("SyncModuleControlSurface"):SetField("authority limiter", x).
        }
    }
}

function PollUpdate {
    if not AllOnce {set AllSet to true. set AllOnce to true.}
    list targets in OLMTargets.
    if OLMTargets:length > 0 {
        for x in OLMTargets {
            if x:name:contains("OrbitalLaunchMount") {
                set TowerExists to true.
                set GT to true.
            }
        }
    } 
    if not TowerExists {
        set GT to false.
    }

    if BoosterEngines[0]:hasphysics {
        if BoosterSingleEngines and EC {
            set missingCount to 0.
            set inactiveCount to 0.
            //for eng in BoosterSingleEnginesRC {
            //    if eng:hassuffix("activate") {if eng:thrust < 60*Scale set inactiveCount to inactiveCount + 1.}
            //    else set missingCount to missingCount + 1.
            //}
            for eng in BoosterSingleEnginesRC {
                if not eng:hassuffix("activate") set missingCount to missingCount + 1.
                else if eng:getmodule("ModuleEnginesFX"):getfield("Status"):contains("Off") {}
                else if eng:getmodule("ModuleEnginesFX"):getfield("Status"):contains("Nominal") {}
                else if eng:getmodule("ModuleEnginesFX"):getfield("Status"):contains("Failed") set missingCount to missingCount + 1.
                else set inactiveCount to inactiveCount + 1.
                if MiddleEnginesShutdown set inactiveCount to max(0,inactiveCount-10).
            }
            if not BoostBackComplete and ErrorVector:mag > BoosterGlideDistance + 5450 * Scale {
                if (missingCount > 2 and not RSS) or missingCount > 3 set GE to false.
                else if inactiveCount > 3 set GE to false.
                else set GE to true.
            } else if LandingBurnEC and not MiddleEnginesShutdown {
                if (missingCount > 1 and inactiveCount > 1 and not RSS) 
                    or (missingCount > 2 and not RSS) or (missingCount > 2 and inactiveCount < 1) 
                    or (inactiveCount > 1 and missingCount > 2) or missingCount > 3 set GE to false.
                else if (inactiveCount > 2 and not RSS) or inactiveCount > 3 set GE to false.
                else set GE to true.
                if BoosterSingleEnginesRC[0]:hassuffix("activate") and BoosterSingleEnginesRC[1]:hassuffix("activate") and BoosterSingleEnginesRC[2]:hassuffix("activate") {
                    if BoosterSingleEnginesRC[0]:thrust < 60*Scale or BoosterSingleEnginesRC[1]:thrust < 60*Scale or BoosterSingleEnginesRC[2]:thrust < 60*Scale 
                        set CounterEngine to true.
                }
                else set CounterEngine to true.
            } else if MiddleEnginesShutdown {
                if inactiveCount > 0 set GE to false.
                else set GE to true.
            }
        }
        else set GE to true.
    } else {set GE to false.}

    if GridfinsType = "Vista" {
        if ship:partsnamed("Sep.Gridfin"):length < GridfinLength set GG to false.
        else set GG to true.
        if ship:partsnamed("Sep.Gridfin"):length < Gridfins:length and ship:partsnamed("Sep.Gridfin"):length > 0 
            set Gridfins to ship:partsnamed("Sep.Gridfin").
    }
    else if GridfinsType = "Block1" {
        if ship:partsnamed("FNB.BL1.BOOSTERGRIDFIN"):length < GridfinLength set GG to false.
        else set GG to true.
        if ship:partsnamed("FNB.BL1.BOOSTERGRIDFIN"):length < Gridfins:length and ship:partsnamed("FNB.BL1.BOOSTERGRIDFIN"):length > 0 
            set Gridfins to ship:partsnamed("FNB.BL1.BOOSTERGRIDFIN").
    }
    else if GridfinsType = "Block3" {
        if ship:partsnamed("Block.3.Fin"):length < GridfinLength and ship:partsnamed("FNB.BL3.BOOSTERFIN"):length < GridfinLength and ship:partsnamed("FNB.BL3.GRIDFIN"):length < GridfinLength set GG to false.
        else set GG to true.
        if ship:partsnamed("Block.3.Fin"):length < Gridfins:length and ship:partsnamed("Block.3.Fin"):length > 0 
            set Gridfins to ship:partsnamed("Block.3.Fin").
        else if ship:partsnamed("FNB.BL3.BOOSTERFIN"):length < Gridfins:length and ship:partsnamed("FNB.BL3.BOOSTERFIN"):length > 0 
            set Gridfins to ship:partsnamed("FNB.BL3.BOOSTERFIN").
        else if ship:partsnamed("FNB.BL3.GRIDFIN"):length < Gridfins:length and ship:partsnamed("FNB.BL3.GRIDFIN"):length > 0 
            set Gridfins to ship:partsnamed("FNB.BL3.GRIDFIN").
    }
    else {
        if ship:partsnamed("SEP."+GridfinsType+".BOOSTER.GRIDFIN"):length < GridfinLength set GG to false.
        else set GG to true.
        if ship:partsnamed("SEP."+GridfinsType+".BOOSTER.GRIDFIN"):length < Gridfins:length and ship:partsnamed("SEP."+GridfinsType+".BOOSTER.GRIDFIN"):length > 0 
            set Gridfins to ship:partsnamed("SEP."+GridfinsType+".BOOSTER.GRIDFIN").
    }
    
    if not GTn set GTn to true.

    CheckFuel().

    if PollTimer < 0 and not GF and FC and not BoostBackComplete {
        set GFnoGO to true.
        set BoostBackComplete to true.
        unlock throttle.
        lock throttle to 0.
    }

    if (ErrorVector:mag < BoosterGlideDistance + 3600 * Scale) and not BoostBackComplete and not GFnoGO and FC {
        if LFBooster > LFBoosterFuelCutOff * 1.1 {
            if PollTimer > 30 and LFBooster > LFBoosterFuelCutOff * 3.05 set GF to true.
            else if PollTimer > 15 and LFBooster > LFBoosterFuelCutOff * 1.55 set GF to true.
            else if PollTimer > -5 and LFBooster > LFBoosterFuelCutOff * 1.15 set GF to true.
            else if LFBooster > LFBoosterFuelCutOff * 1.12 set GF to true.
        } 
        else set GF to false.
    } 
    else if (ErrorVector:mag > BoosterGlideDistance) and not BoostBackComplete and not GFnoGO and FC {
        if LFBooster > LFBoosterFuelCutOff * 0.95 {
            if PollTimer > -10 and LFBooster > LFBoosterFuelCutOff * 1.15 set GF to true.
            else if PollTimer > -15 and LFBooster > LFBoosterFuelCutOff * 1.05 set GF to true.
        } 
        else if PollTimer > 0 set GF to true. 
        else set GF to false.
    } 
    else if BoostBackComplete and not GFnoGO and FC {
        if LFBooster > LFBoosterFuelCutOff * (0.9 / Scale^0.5) and not LandingBurnStarted set GF to true.
        else if LandingBurnStarted {
            if MiddleEnginesShutdown set GF to true. else set GF to true.
        }
        else set GF to false.
    }
    if rebooted set GF to true.


    if GD and GE and GF and GT and GG and GTn and not cAbort and not offshoreDivert {
        set GfC to true.
    } else {
        set GfC to false.
    }
}


function GUIupdate {

    if vAng(facing:forevector, vxcl(up:vector, landingzone:position - BoosterCore:position)) < 90 set currentPitch to 360-vAng(facing:forevector,up:vector).
    else set currentPitch to vAng(facing:forevector,up:vector).
    if round(currentPitch) = 360 set currentPitch to 0.

    if ShipConnectedToBooster and (ShipType:contains("Block2") or ShipType:contains("Block3")) set bAttitude:style:bg to "starship_img/StackAttitude/Block2/"+round(currentPitch):tostring.
    else if ShipConnectedToBooster set bAttitude:style:bg to "starship_img/StackAttitude/"+round(currentPitch):tostring.
    else set bAttitude:style:bg to "starship_img/BoosterAttitude/"+round(currentPitch):tostring.

    if cAbort set GDlamp:style:bg to "starship_img/telemetry_red".

    if not MaxQ and airspeed > 2 {
        if qCheck = 1 {
            set LastQ to ship:q.
            set qCheck to qCheck + 1.
        } else if qCheck < 10 {
            set qCheck to qCheck + 1.
        }
        else if LastQ > ship:q set MaxQ to true.
        else set qCheck to 1.
    }

    set boosterAltitude to RadarAlt.
    set boosterSpeed to ship:airspeed.
    set boosterThrust to 0.
        set ActiveRB to 0.
        set ActiveRC to 0.

    if BoosterSingleEngines and not findingEngines {
        for eng in BoosterSingleEnginesRB {
            if eng:hassuffix("activate") {
                if eng:thrust > 60*Scale set ActiveRB to ActiveRB + 1.
                set boosterThrust to boosterThrust + eng:thrust.
            }
        }
        for eng in BoosterSingleEnginesRC {
            if eng:hassuffix("activate") {
                if eng:thrust > 60*Scale set ActiveRC to ActiveRC + 1.
                set boosterThrust to boosterThrust + eng:thrust.
            }
        }
        // Оверлею нужен не счётчик, а КАКИЕ именно двигатели работают: он рисует
        // 33 картинки мода, и они пронумерованы теми же тегами 1..33, что и детали
        // в сборке. Порядок: 1-3 центральные, 4-13 средний круг, 14-33 внешний.
        if EngGeom = "" BuildEngineGeometry().
        set EngMask to "".
        set engIdx to 0.
        until engIdx > 12 {
            set engPart to BoosterSingleEnginesRC[engIdx].
            if engPart:hassuffix("activate") and engPart:thrust > 60*Scale set EngMask to EngMask + "1".
            else set EngMask to EngMask + "0".
            set engIdx to engIdx + 1.
        }
        set engIdx to 0.
        until engIdx > 19 {
            set engPart to BoosterSingleEnginesRB[engIdx].
            if engPart:hassuffix("activate") and engPart:thrust > 60*Scale set EngMask to EngMask + "1".
            else set EngMask to EngMask + "0".
            set engIdx to engIdx + 1.
        }
    } 
    else set boosterThrust to BoosterEngines[0]:thrust.

    for res in bLOXTank:resources {
        if res:name = "Oxidizer" or res:name = "LqdOxygen" or res:name = "CooledLqdOxygen" {
            set boosterLOX to res:amount.
            set boosterLOXCap to res:capacity.
        }
    }
    for res in bCH4Tank:resources {
        if res:name = "LqdMethane" or res:name = "CooledLqdMethane" {
            set boosterCH4 to res:amount.
            set boosterCH4Cap to res:capacity.
            set methane to true.
        }
        if res:name = "LiquidFuel" {
            set boosterCH4 to res:amount.
            set boosterCH4Cap to res:capacity.
            set methane to false.
        }
    }
    if not SinglePartBooster {
        for res in BoosterCore:resources {
            if res:name = "Oxidizer" or res:name = "LqdOxygen" or res:name = "CooledLqdOxygen" {
                set boosterLOX to boosterLOX + res:amount.
                set boosterLOXCap to boosterLOXCap + res:capacity.
            }
        }
        for res in FWD:resources {
            if res:name = "LqdMethane" or res:name = "CooledLqdMethane" {
                set boosterCH4 to boosterCH4 + res:amount.
                set boosterCH4Cap to boosterCH4Cap + res:capacity.
                set methane to true.
            }
            if res:name = "LiquidFuel" {
                set boosterCH4 to boosterCH4 + res:amount.
                set boosterCH4Cap to boosterCH4Cap + res:capacity.
                set methane to false.
            }
        }
        for res in bCMNDome:resources {
            if res:name = "Oxidizer" or res:name = "LqdOxygen" or res:name = "CooledLqdOxygen" {
                set boosterLOX to boosterLOX + res:amount.
                set boosterLOXCap to boosterLOXCap + res:capacity.
            }
            if res:name = "LqdMethane" or res:name = "CooledLqdMethane" {
                set boosterCH4 to boosterCH4 + res:amount.
                set boosterCH4Cap to boosterCH4Cap + res:capacity.
                set methane to true.
            }
            if res:name = "LiquidFuel" {
                set boosterCH4 to boosterCH4 + res:amount.
                set boosterCH4Cap to boosterCH4Cap + res:capacity.
                set methane to false.
            }
        }
    }

    set Mode to "NaN".
    if throttle > 0 {
        if not BoosterSingleEngines and boosterThrust > 60*Scale {
            set lastMode to Mode.
            if BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):hasfield("Mode") {
                set Mode to BoosterEngines[0]:getmodule("ModuleSEPEngineSwitch"):getfield("Mode").
            }
            if Mode = lastMode set ModeChanged to false. else set ModeChanged to true.

            if not BoosterType:contains("Block3") {
                if (Mode = "CenterThree" or Mode = "Center Three" or Mode = "Core") and ModeChanged {
                    set ActiveRC to 3.
                    set x to 1.
                    until x > 3 {
                        set EngClusterDisplay[x-1]:style:bg to "starship_img/EngPicBooster/"+x.
                        set x to x+1.
                    }
                    until x > 33 {
                        set EngClusterDisplay[x-1]:style:bg to "starship_img/EngPicBooster/0".
                        set x to x+1.
                    }
                } else if (Mode = "2Inner" or Mode = "MiddleTwo") and ModeChanged {
                    set ActiveRC to 5.
                    set x to 1.
                    until x > 13 {
                        if x = 1 or x = 2 or x = 3 or x = 7 or x = 11 set EngClusterDisplay[x-1]:style:bg to "starship_img/EngPicBooster/"+x.
                        else set EngClusterDisplay[x-1]:style:bg to "starship_img/EngPicBooster/0".
                        set x to x+1.
                    }
                    until x > 33 {
                        set EngClusterDisplay[x-1]:style:bg to "starship_img/EngPicBooster/0".
                        set x to x+1.
                    }
                } else if (Mode = "Middle Inner" or Mode = "Inner" or Mode = "Middle Ten" or Mode = "MiddleEight") and ModeChanged {
                    set ActiveRC to 13.
                    set x to 1.
                    until x > 13 {
                        set EngClusterDisplay[x-1]:style:bg to "starship_img/EngPicBooster/"+x.
                        set x to x+1.
                    }
                    until x > 33 {
                        set EngClusterDisplay[x-1]:style:bg to "starship_img/EngPicBooster/0".
                        set x to x+1.
                    }
                } else if (Mode = "All Engines" or Mode = "All" or Mode = "Outer Twenty" or Mode = "OuterTwenty") and ModeChanged {
                    set ActiveRC to 33.
                    set x to 1.
                    until x > 33 {
                        set EngClusterDisplay[x-1]:style:bg to "starship_img/EngPicBooster/"+x.
                        set x to x+1.
                    }
                }
            } else {
                if (Mode = "CenterThree" or Mode = "Center Three" or Mode = "Core") and ModeChanged {
                    set ActiveRC to 3.
                    set x to 1.
                    until x > 3 {
                        set EngClusterDisplay[x-1]:style:bg to "starship_img/EngPicBooster3/"+x.
                        set x to x+1.
                    }
                    until x > 33 {
                        set EngClusterDisplay[x-1]:style:bg to "starship_img/EngPicBooster3/0".
                        set x to x+1.
                    }
                } else if (Mode = "2Inner" or Mode = "MiddleTwo" or Mode = "Middle Two") and ModeChanged {
                    set ActiveRC to 5.
                    set x to 1.
                    until x > 13 {
                        if x = 1 or x = 2 or x = 3 or x = 6 or x = 11 set EngClusterDisplay[x-1]:style:bg to "starship_img/EngPicBooster3/"+x.
                        else set EngClusterDisplay[x-1]:style:bg to "starship_img/EngPicBooster3/0".
                        set x to x+1.
                    }
                    until x > 33 {
                        set EngClusterDisplay[x-1]:style:bg to "starship_img/EngPicBooster3/0".
                        set x to x+1.
                    }
                } else if (Mode = "Middle Inner" or Mode = "Inner" or Mode = "Middle Ten" or Mode = "MiddleEight" or Mode = "Middle Eight") and ModeChanged {
                    set ActiveRC to 13.
                    set x to 1.
                    until x > 13 {
                        set EngClusterDisplay[x-1]:style:bg to "starship_img/EngPicBooster3/"+x.
                        set x to x+1.
                    }
                    until x > 33 {
                        set EngClusterDisplay[x-1]:style:bg to "starship_img/EngPicBooster3/0".
                        set x to x+1.
                    }
                } else if (Mode = "All Engines" or Mode = "All" or Mode = "Outer Twenty" or Mode = "OuterTwenty") and ModeChanged {
                    set ActiveRC to 33.
                    set x to 1.
                    until x > 33 {
                        set EngClusterDisplay[x-1]:style:bg to "starship_img/EngPicBooster3/"+x.
                        set x to x+1.
                    }
                } else if Mode = "NaN" {
                    print("Mode not found").
                }
            }
        } 
        else if boosterThrust > 60*Scale and not findingEngines {
            set z to 1.
            if ShipConnectedToBooster or BoosterType:contains("Block3") { 
                for uieng in BoosterSingleEnginesRB {
                    if uieng:hassuffix("activate") and not BoosterType:contains("Block3") {
                        if uieng:thrust > 60*Scale set EngClusterDisplay[z+12]:style:bg to "starship_img/EngPicBooster/" + (z+13).
                        else set EngClusterDisplay[z+12]:style:bg to "starship_img/EngPicBooster/0".
                    }
                    else if uieng:hassuffix("activate") {
                        if uieng:thrust > 60*Scale set EngClusterDisplay[z+12]:style:bg to "starship_img/EngPicBooster3/" + (z+13).
                        else set EngClusterDisplay[z+12]:style:bg to "starship_img/EngPicBooster3/0".
                    }
                    set z to z+1.
                }
                set z to 1.
            }
            for uieng in BoosterSingleEnginesRC {
                if uieng:hassuffix("activate") and not BoosterType:contains("Block3") {
                    if uieng:thrust > 60*Scale set EngClusterDisplay[z-1]:style:bg to "starship_img/EngPicBooster/" + (z).
                    else set EngClusterDisplay[z-1]:style:bg to "starship_img/EngPicBooster/0".
                }
                else if uieng:hassuffix("activate") {
                    if uieng:thrust > 60*Scale set EngClusterDisplay[z-1]:style:bg to "starship_img/EngPicBooster3/" + (z).
                    else set EngClusterDisplay[z-1]:style:bg to "starship_img/EngPicBooster3/0".
                }
                set z to z+1.
            }
        } 
        else 
            for EngLbl in EngClusterDisplay {
                set EngLbl:style:bg to "starship_img/EngPicBooster/0".
            }
    }
    else {
        for EngLbl in EngClusterDisplay {
            set EngLbl:style:bg to "starship_img/EngPicBooster/0".
        }
    }
    
    set bSpeed:text to "<b><size=24>SPEED</size>          </b> " + round(boosterSpeed*3.6) + " <size=24>KM/H</size>".
    if boosterAltitude > 99999 {
        set bAltitude:text to "<b><size=24>ALTITUDE</size>       </b> " + round(boosterAltitude/1000) + " <size=24>KM</size>".
    } else if boosterAltitude > 999 {
        set bAltitude:text to "<b><size=24>ALTITUDE</size>       </b> " + round(boosterAltitude/1000,1) + " <size=24>KM</size>".
    } else {
        set bAltitude:text to "<b><size=24>ALTITUDE</size>      </b> " + round(boosterAltitude) + " <size=24>M</size>".
    }
    set bThrust:text to "<b>Thrust: </b> " + round(boosterThrust) + " kN" + "          Throttle: " + max(0,min(round(throttle,2)*100,100)) + "%".

    set boosterLOX to boosterLOX*100/boosterLOXCap.
    set boosterCH4 to boosterCH4*100/boosterCH4Cap.

    set bLOXLabel:text to "<b>LOX</b>   ".// + round(boosterLOX,1) + " %".
    set bLOXSlider:style:overflow:right to -196*TScale + 2*round(boosterLOX,1)*TScale.
    set bLOXNumber:text to round(boosterLOX,1) + "%".

    if methane {
        set bCH4Label:text to "<b>CH4</b>   ".// + round(boosterCH4,1) + " %".
        set bCH4Slider:style:overflow:right to -196*TScale + 2*round(boosterCH4,1)*TScale.
        set bCH4Number:text to round(boosterCH4,1) + "%".
    } else {
        set bCH4Label:text to "<b>Fuel</b>   ".// + round(boosterCH4,1) + " %".
        set bCH4Slider:style:overflow:right to -196*TScale + 2*round(boosterCH4,1)*TScale.
        set bCH4Number:text to round(boosterCH4,1) + "%".
    }

    if boosterLOX < 1 and boosterLOX > 0.5 set bLOXSlider:style:bg to "starship_img/telemetry_fuel_grey".
    else if boosterLOX < 0.5 set bLOXSlider:style:bg to "".
    else set bLOXSlider:style:bg to "starship_img/telemetry_fuel".
    if boosterCH4 < 1 and boosterCH4 > 0.5 set bCH4Slider:style:bg to "starship_img/telemetry_fuel_grey".
    else if boosterCH4 < 0.5 set bCH4Slider:style:bg to "".
    else set bCH4Slider:style:bg to "starship_img/telemetry_fuel".

    set missionTimerNow to time:seconds-missionTimer.
    if missionTimerNow < 0 {
        set missionTimerNow to -missionTimerNow.
        set TMinus to true.
    } 
    else set TMinus to false.

    set hoursV to missionTimerNow/60/60.
    set Thours to round(hoursV).
    if hoursV < Thours set Thours to Thours - 1.

    set minV to missionTimerNow/60 - Thours*60.
    set Tminutes to round(minV).
    if minV < Tminutes set Tminutes to Tminutes - 1.
    
    set Tseconds to missionTimerNow - Thours*60*60 - Tminutes*60.
    set Tseconds to floor(Tseconds).

    if Thours < 9.1 set Thours to "0"+Thours.
    if Tminutes < 9.1 set Tminutes to "0"+Tminutes.
    if Tseconds < 9.1 set Tseconds to "0"+Tseconds.

    if TMinus set missionTimeLabel:text to "T- "+Thours+":"+Tminutes+":"+Tseconds.
    else set missionTimeLabel:text to "T+ "+Thours+":"+Tminutes+":"+Tseconds.
    

    if flipStartTime > 0 {
        if RSS set PollTimer to flipStartTime+45-Block3PollTime-time:seconds.    
        else if KSRSS set PollTimer to flipStartTime+55-Block3PollTime-time:seconds.    
        else set PollTimer to flipStartTime+50-Block3PollTime-time:seconds.
    } 
    if GfC set message4:text to "Current decision: <b><color=green>GO</color></b>".
    else set message4:text to "Current decision: <b><color=red>NOGo</color></b>".

    if GT set data1:text to "Tower: <b><color=green>GO</color></b>".
    else set data1:text to "Tower: <b><color=red>NOGo</color></b>".

    if GE set data2:text to "Engines: <b><color=green>GO</color></b>".
    else set data2:text to "Engines: <b><color=red>NOGo</color></b>".

    if GF set data25:text to "Fuel: <b><color=green>GO</color></b>".
    else set data25:text to "Fuel: <b><color=red>NOGo</color></b>".

    if GG set data3:text to "Gridfins: <b><color=green>GO</color></b>".
    else set data3:text to "Gridfins: <b><color=red>NOGo</color></b>".

    if GTn set data35:text to "Tanks: <b><color=green>GO</color></b>".
    else set data35:text to "Tanks: <b><color=red>NOGo</color></b>".

    if GD set data4:text to "Flight Director: <b><color=green>GO</color></b>".
    else set data4:text to "Flight Director: <b><color=red>NOGo</color></b>".

    if PollTimer < 0 {
        if HSRJet {
            set message3:text to "<size=13>HSR Jettison</size>".
        } else {
            set message3:text to "<size=13><b>NO</b> HSR Jettison</size>".
        }
        if PollTimer < -1.5 {
            set message0:text to "<b>Status:</b>".
            if GfC {
                set message1:text to "<color=green>GO</color> for Catch".
            } else {
                set message1:text to "<color=yellow>Offshore divert</color>".
            }
        }
    } else if PollTimer < 10 {
        set message3:text to "Poll ending in: <color=red>" + round(PollTimer) + "</color>s".
    } else if PollTimer < 20 {
        set message3:text to "Poll ending in: <color=yellow>" + round(PollTimer) + "</color>s".
    } else {
        set message3:text to "Poll ending in: " + round(PollTimer) + "s".
    }

    if cAbort {
        set message1:text to "<b><color=red>ABORT</color></b>".
    }

    // ---- Тяга Раптора по данным игры ----
    // Константы BoosterRaptorThrust* (655/660 кН) завышены: на посадочном ожоге
    // игра отдаёт 573-579 кН, и фактическое торможение по логу сходится именно
    // с этой цифрой. Из-за завышения модель считала торможение на четверть
    // сильнее, чем оно есть, душила тягу и приходила к земле на 30+ м/с.
    // Считаем ИМЕННО ЗДЕСЬ: GUIupdate вызывается таймером каждые 0.03 с с первой
    // секунды полёта, поэтому к моменту расчёта высоты зажигания LandingBurnAlt
    // (а он считается ДО включения двигателей, когда мерить уже нечего)
    // значение уже защёлкнуто на буст-бэке.
    // ship:availablethrust - полная тяга зажжённых двигателей на ТЕКУЩЕМ
    // давлении, от throttle не зависит. Работает и с отдельными двигателями,
    // и с кластером Block 3 (ModuleSEPEngineSwitch), где отдельных деталей нет.
    set RaptorMeasured to 0.
    if ActiveRC >= 3 and ship:availablethrust > 0 {
        set RaptorMeasured to ship:availablethrust / ActiveRC.
    }
    // Кластер может отдать тягу не за те двигатели, что реально горят. Явно
    // бредовое значение в наведение не пускаем: старая константа лучше мусора.
    if RaptorMeasured > 300 and RaptorMeasured < 900 {
        set RaptorThrustLive to RaptorMeasured.
    }
}

