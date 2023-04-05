/* GSolone 29/3/23
   Credits:
    https://nsis-dev.github.io/NSIS-Forums/html/t-262613.html (Write DWORD)
    https://documentation.help/CTRE-NSIS/Section4.4.html (Relative Jumps)
    https://stackoverflow.com/a/11194024/2220346 (Parametro aggiuntivo da riga di comando)
    https://stackoverflow.com/a/55118751/2220346
    https://stackoverflow.com/q/73543253/2220346
   Icon:
    https://www.flaticon.com/free-icon/windows_5969316 Logo icons created by Freepik - Flaticon
   Modifiche:
    31/3/23- Minor change: non faccio chiudere più la finestra automaticamente (così da lasciare un feedback all'utilizzatore dell'eseguibile).
             Improve: ho costruito tutto il blocco di rollback. Lanciare il programma con parametro -r da riga di comando per chiedere il rollback e permettere alle notifiche di Windows 11 di ricomparire.
             Fix: ho incluso dei Goto più precisi e non salti di righe che hanno creato problemi.
    29/3/23- Fix: correggo gli StrCmp per saltare all'azione giusta per Product Versione e Major Release in target. Sposto Product Version tra i Define per
                  gestire senza dover entrare nel vivo del codice delle Section.
                  Next step: possibilità di fare "rollback" eliminando le chiavi direttamente da installer.
             Hello World: eredito codice della MinReq Notice Remover e lo piego all'uso del blocco aggiornamento a Win11.
*/

!define PRODUCT_NAME "Windows 11 Upgrade Block"
!define PRODUCT_VERSION "0.1"
!define PRODUCT_VERSION_MINOR "3.0"
!define PRODUCT_PUBLISHER "Emmelibri S.r.l."
!define PRODUCT_WEB_SITE "https://www.emmelibri.it"
!define PRODUCT_BUILD "${PRODUCT_NAME} ${PRODUCT_VERSION}.${PRODUCT_VERSION_MINOR} (build ${MyTIMESTAMP})"

!define WIN_PRODUCT "Windows 10"
!define WIN_VERSION "22H2"

!include "MUI.nsh"
!include "FileFunc.nsh"

!define MUI_ABORTWARNING
!define MUI_ICON "include\icon-windows.ico"
!define MUI_COMPONENTSPAGE_NODESC
!define /date MYTIMESTAMP "%Y%m%d-%H%M%S"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_LANGUAGE "Italian"
!define /date MyTIMESTAMP_Yr "%Y"

!define MUI_PAGE_HEADER_TEXT "${PRODUCT_BUILD}"
!define MUI_INSTFILESPAGE_FINISHHEADER_TEXT "${PRODUCT_BUILD}"
!define MUI_INSTFILESPAGE_FINISHHEADER_SUBTEXT "Operations completed."
!define MUI_FINISHPAGE_TITLE "${PRODUCT_BUILD}"
!define MUI_FINISHPAGE_TEXT "Operations ended."

VIProductVersion "${PRODUCT_VERSION}.${PRODUCT_VERSION_MINOR}"
VIAddVersionKey ProductName "${PRODUCT_NAME}"
VIAddVersionKey Comments "${PRODUCT_NAME}"
VIAddVersionKey CompanyName "Emmelibri S.r.l."
VIAddVersionKey LegalCopyright GSolone
VIAddVersionKey FileDescription "Prevents Windows 11 from installing itself, keeping Windows 10."
VIAddVersionKey FileVersion ${PRODUCT_VERSION}
VIAddVersionKey ProductVersion ${PRODUCT_VERSION}
VIAddVersionKey InternalName "${PRODUCT_VERSION}"
VIAddVersionKey LegalTrademarks "GSolone, 2023"
VIAddVersionKey OriginalFilename "Win11UpgradeBlock-${PRODUCT_VERSION}.exe"

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "Win11UpgradeBlock_${PRODUCT_VERSION}.exe"
InstallDir "$TEMP"
ShowInstDetails show
BrandingText "Emmelibri S.r.l. - GSolone ${MyTIMESTAMP_Yr}"

RequestExecutionLevel Admin
SpaceTexts none
Caption "${PRODUCT_BUILD}"

Section "Target Release Version Enable" TargetReleaseVersion_ENABLE
 ReadRegDword $0 HKLM "SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "TargetReleaseVersion"
 IfErrors TargetDoesntExist TargetExists
  TargetDoesntExist:
   ClearErrors
   DetailPrint "TargetReleaseVersion not found, I create the registry key now."
   WriteRegDword HKLM "SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "TargetReleaseVersion" 0x00000001
   ReadRegDword $0 HKLM "SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "TargetReleaseVersion"
   DetailPrint "TargetReleaseVersion value: $0"
   Goto TargetReleaseVersion_end
  TargetExists:
   DetailPrint "TargetReleaseVersion already found, value $0."
   StrCmp $0 0 0 +3
    DetailPrint "I'm changing the value of the key to 1."
    WriteRegDword HKLM "SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "TargetReleaseVersion" 0x00000001
    Goto TargetReleaseVersion_end
   DetailPrint "TargetReleaseVersion value: $0"
 TargetReleaseVersion_end:
SectionEnd

Section "Stay on Windows 10" ProductVersion_ENABLE
 ReadRegStr $0 HKLM "SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "ProductVersion"
 IfErrors PVersionDoesntExist PVersionExists
  PVersionDoesntExist:
   ClearErrors
   DetailPrint "ProductVersion not found, I create the registry key now."
   WriteRegStr HKLM "SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "ProductVersion" "${WIN_PRODUCT}"
   ReadRegStr $0 HKLM "SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "ProductVersion"
   DetailPrint "ProductVersion value: $0"
   Goto ProductVersion_end
  PVersionExists:
   DetailPrint "ProductVersion already found, value $0."
   StrCmp $0 "${WIN_PRODUCT}" +3 0
    DetailPrint "I'm changing the value of the key to Windows 10."
    WriteRegStr HKLM "SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "ProductVersion" "${WIN_PRODUCT}"
    Goto ProductVersion_end
   DetailPrint "ProductVersion value: $0"
 ProductVersion_end:
SectionEnd

Section "Target Windows 10 Major Version" TargetReleaseVersionInfo_ENABLE
 ReadRegStr $0 HKLM "SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "TargetReleaseVersionInfo"
 IfErrors TargetVersionDoesntExist TargetVersionExists
  TargetVersionDoesntExist:
   ClearErrors
   DetailPrint "TargetReleaseVersionInfo not found, I create the registry key now."
   WriteRegStr HKLM "SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "TargetReleaseVersionInfo" "${WIN_VERSION}"
   ReadRegStr $0 HKLM "SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "TargetReleaseVersionInfo"
   DetailPrint "TargetReleaseVersionInfo value: $0"
   Goto TargetReleaseVersionInfo_end
  TargetVersionExists:
   DetailPrint "TargetReleaseVersionInfo already found, value $0."
   StrCmp $0 "${WIN_VERSION}" +3 0
    DetailPrint "I'm changing the value of the key to 22H2."
    WriteRegStr HKLM "SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "TargetReleaseVersionInfo" "${WIN_VERSION}"
    Goto TargetReleaseVersionInfo_end
   DetailPrint "TargetReleaseVersionInfo value: $0"
 TargetReleaseVersionInfo_end:
SectionEnd

Section "Rollback (enable Windows 11 upgrade)" Win11Upgrade_ENABLE
 ${GetOptions} $CMDLINE "-r" $0
 ${IfNot} ${Errors}
  DetailPrint "Configuration rollback, unlock Windows 11 upgrade notification"
  DeleteRegValue HKLM "SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "TargetReleaseVersion"
  DeleteRegValue HKLM "SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "ProductVersion"
  DeleteRegValue HKLM "SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "TargetReleaseVersionInfo"
 ${EndIF}
SectionEnd

Function .onInit
  SetShellVarContext All
  ClearErrors
  ${GetOptions} $CMDLINE "-r" $0
  ${IfNot} ${Errors}
    ; Sblocco notifiche Windows 11
    SectionSetFlags ${TargetReleaseVersion_ENABLE} ${SF_RO}
    SectionSetFlags ${ProductVersion_ENABLE} ${SF_RO}
    SectionSetFlags ${TargetReleaseVersionInfo_ENABLE} ${SF_RO}
    IntOp $0 ${SF_SELECTED} | ${SF_RO}
    SectionSetFlags ${Win11Upgrade_ENABLE} $0
  ${Else}
    ; Blocco notifiche Windows 11
    SectionSetFlags ${Win11Upgrade_ENABLE} ${SF_RO}
    IntOp $0 ${SF_SELECTED} | ${SF_RO}
    SectionSetFlags ${TargetReleaseVersion_ENABLE} $0
    SectionSetFlags ${ProductVersion_ENABLE} $0
    SectionSetFlags ${TargetReleaseVersionInfo_ENABLE} $0
  ${EndIF}
FunctionEnd

Section -Post
  SetAutoClose False
SectionEnd