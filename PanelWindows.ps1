# =========================================================
#  PanelWindows.ps1  (v2 - estilo WinUtil por pestanas)
#  Panel con: Instalar Apps (winget), Tweaks del sistema,
#  Herramientas remotas curadas, e Instaladores locales.
#
#  Se puede ejecutar localmente (doble clic / .\PanelWindows.ps1) o de forma
#  remota con: irm https://raw.githubusercontent.com/LCk1ng/Panel/main/PanelWindows.ps1 | iex
# =========================================================

# URL cruda (raw) de este mismo script en GitHub. Se usa solo para poder
# re-lanzarse a si mismo elevado cuando se ejecuta via "irm ... | iex"
# (en ese caso no existe un archivo local desde el cual reabrir).
$ScriptUrl = "https://raw.githubusercontent.com/LCk1ng/Panel/main/PanelWindows.ps1"

# ---------- 1. Auto-elevacion a Administrador ----------
$esAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $esAdmin) {
    if ($PSCommandPath) {
        # Ejecucion local desde archivo: reabrir el mismo archivo elevado
        $args = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        Start-Process powershell -Verb RunAs -ArgumentList $args
    } else {
        # Ejecucion remota via "irm ... | iex": volver a descargar y ejecutar, ya elevado
        Start-Process powershell -Verb RunAs -ArgumentList `
            "-NoProfile -Command `"irm '$ScriptUrl' | iex`""
    }
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------- 2. Configuracion ----------
# Carpeta base: si se ejecuta desde un archivo local, se usa la carpeta del
# script; si se ejecuta remotamente via iex (no hay archivo local), se usa
# una carpeta fija en el perfil del usuario.
$CarpetaBase = if ($PSScriptRoot) { $PSScriptRoot } else { Join-Path $env:USERPROFILE "PanelWindows" }
if (-not (Test-Path $CarpetaBase)) {
    New-Item -ItemType Directory -Path $CarpetaBase -Force | Out-Null
}
$CarpetaInstaladores = Join-Path $CarpetaBase "Instaladores"
if (-not (Test-Path $CarpetaInstaladores)) {
    New-Item -ItemType Directory -Path $CarpetaInstaladores -Force | Out-Null
}


# Herramientas remotas de confianza (curadas por ti). Para sumar una nueva a
# futuro, revisala primero y agrega una linea aqui.
$HerramientasRemotas = @(
    [PSCustomObject]@{ Nombre = "Chris Titus Tech - WinUtil";  Comando = 'irm https://christitus.com/win | iex' }
    [PSCustomObject]@{ Nombre = "Winhance (optimizador Windows)"; Comando = 'irm "https://get.winhance.net" | iex' }
)

# Catalogo de apps instalables via winget (Id real de winget + nombre visible + categoria)
$AppsDisponibles = @(
    # Navegadores
    [PSCustomObject]@{ Categoria = "Navegadores";  Nombre = "Google Chrome";        Id = "Google.Chrome" }
    [PSCustomObject]@{ Categoria = "Navegadores";  Nombre = "Mozilla Firefox";      Id = "Mozilla.Firefox" }
    [PSCustomObject]@{ Categoria = "Navegadores";  Nombre = "Brave";                Id = "Brave.Brave" }
    [PSCustomObject]@{ Categoria = "Navegadores";  Nombre = "Opera";                Id = "Opera.Opera" }
    # Multimedia
    [PSCustomObject]@{ Categoria = "Multimedia";   Nombre = "VLC Media Player";     Id = "VideoLAN.VLC" }
    [PSCustomObject]@{ Categoria = "Multimedia";   Nombre = "Spotify";              Id = "Spotify.Spotify" }
    [PSCustomObject]@{ Categoria = "Multimedia";   Nombre = "OBS Studio";           Id = "OBSProject.OBSStudio" }
    [PSCustomObject]@{ Categoria = "Multimedia";   Nombre = "Audacity";             Id = "Audacity.Audacity" }
    [PSCustomObject]@{ Categoria = "Multimedia";   Nombre = "HandBrake";            Id = "HandBrake.HandBrake" }
    # Utilidades
    [PSCustomObject]@{ Categoria = "Utilidades";   Nombre = "7-Zip";                Id = "7zip.7zip" }
    [PSCustomObject]@{ Categoria = "Utilidades";   Nombre = "WinRAR";               Id = "RARLab.WinRAR" }
    [PSCustomObject]@{ Categoria = "Utilidades";   Nombre = "Notepad++";            Id = "Notepad++.Notepad++" }
    [PSCustomObject]@{ Categoria = "Utilidades";   Nombre = "Adobe Acrobat Reader"; Id = "Adobe.Acrobat.Reader.64-bit" }
    [PSCustomObject]@{ Categoria = "Utilidades";   Nombre = "PowerToys";            Id = "Microsoft.PowerToys" }
    [PSCustomObject]@{ Categoria = "Utilidades";   Nombre = "Everything (buscador de archivos)"; Id = "voidtools.Everything" }
    # Desarrollo
    [PSCustomObject]@{ Categoria = "Desarrollo";   Nombre = "Visual Studio Code";   Id = "Microsoft.VisualStudioCode" }
    [PSCustomObject]@{ Categoria = "Desarrollo";   Nombre = "Git";                  Id = "Git.Git" }
    [PSCustomObject]@{ Categoria = "Desarrollo";   Nombre = "Python 3";             Id = "Python.Python.3.12" }
    [PSCustomObject]@{ Categoria = "Desarrollo";   Nombre = "Node.js";              Id = "OpenJS.NodeJS.LTS" }
    [PSCustomObject]@{ Categoria = "Desarrollo";   Nombre = "Docker Desktop";       Id = "Docker.DockerDesktop" }
    [PSCustomObject]@{ Categoria = "Desarrollo";   Nombre = "Postman";              Id = "Postman.Postman" }
    # Comunicacion
    [PSCustomObject]@{ Categoria = "Comunicacion"; Nombre = "Discord";              Id = "Discord.Discord" }
    [PSCustomObject]@{ Categoria = "Comunicacion"; Nombre = "Zoom";                 Id = "Zoom.Zoom" }
    [PSCustomObject]@{ Categoria = "Comunicacion"; Nombre = "Telegram Desktop";     Id = "Telegram.TelegramDesktop" }
    [PSCustomObject]@{ Categoria = "Comunicacion"; Nombre = "WhatsApp";             Id = "9NKSQGP7F2NH" }
)
$CategoriasApps = @("Todas") + ($AppsDisponibles.Categoria | Select-Object -Unique)

# Catalogo de tweaks (cada uno es un comando de PowerShell/registro seguro y reversible, con categoria)
$TweaksDisponibles = @(
    # Personalizacion
    [PSCustomObject]@{ Categoria = "Personalizacion"; Nombre = "Mostrar extensiones de archivo"; Comando = `
        'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value 0' }
    [PSCustomObject]@{ Categoria = "Personalizacion"; Nombre = "Mostrar archivos ocultos"; Comando = `
        'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Hidden -Value 1' }
    [PSCustomObject]@{ Categoria = "Personalizacion"; Nombre = "Activar modo oscuro"; Comando = `
        'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -Value 0; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name SystemUsesLightTheme -Value 0' }
    [PSCustomObject]@{ Categoria = "Personalizacion"; Nombre = "Restaurar menu contextual clasico (Windows 11)"; Comando = `
        'New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Force -Value "" | Out-Null; Stop-Process -Name explorer -Force' }
    # Rendimiento
    [PSCustomObject]@{ Categoria = "Rendimiento"; Nombre = "Plan de energia: Alto rendimiento"; Comando = `
        'powercfg /setactive SCHEME_MIN' }
    [PSCustomObject]@{ Categoria = "Rendimiento"; Nombre = "Plan de energia: Equilibrado"; Comando = `
        'powercfg /setactive SCHEME_BALANCED' }
    [PSCustomObject]@{ Categoria = "Rendimiento"; Nombre = "Desactivar animaciones para mejor rendimiento"; Comando = `
        'Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name UserPreferencesMask -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00))' }
    [PSCustomObject]@{ Categoria = "Rendimiento"; Nombre = "Deshabilitar OneDrive (inicio automatico)"; Comando = `
        'Get-CimInstance Win32_StartupCommand | Where-Object { $_.Name -like "*OneDrive*" } | ForEach-Object { Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $_.Name -ErrorAction SilentlyContinue }' }
    # Privacidad
    [PSCustomObject]@{ Categoria = "Privacidad"; Nombre = "Reducir telemetria de Windows (nivel basico)"; Comando = `
        'New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null; Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name AllowTelemetry -Value 0 -Type DWord' }
    [PSCustomObject]@{ Categoria = "Privacidad"; Nombre = "Desactivar sugerencia de busqueda web (Bing) en el menu Inicio"; Comando = `
        'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name BingSearchEnabled -Value 0' }
    [PSCustomObject]@{ Categoria = "Privacidad"; Nombre = "Desactivar anuncios personalizados (ID de publicidad)"; Comando = `
        'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name Enabled -Value 0' }
)
$CategoriasTweaks = @("Todas") + ($TweaksDisponibles.Categoria | Select-Object -Unique)

# ---------- 3. Ventana principal ----------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Panel de Administracion - Windows Toolkit"
$form.Size = New-Object System.Drawing.Size(820, 700)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$lblTitulo = New-Object System.Windows.Forms.Label
$lblTitulo.Text = "Panel de Administracion (ejecutando como Administrador)"
$lblTitulo.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$lblTitulo.AutoSize = $true
$lblTitulo.Location = New-Object System.Drawing.Point(15, 10)
$form.Controls.Add($lblTitulo)

$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Location = New-Object System.Drawing.Point(15, 45)
$tabs.Size = New-Object System.Drawing.Size(775, 400)
$form.Controls.Add($tabs)

# Log comun (debajo de las pestanas, visible siempre)
$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text = "Registro de actividad"
$lblLog.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblLog.AutoSize = $true
$lblLog.Location = New-Object System.Drawing.Point(15, 455)
$form.Controls.Add($lblLog)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.ReadOnly = $true
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$txtLog.Location = New-Object System.Drawing.Point(15, 480)
$txtLog.Size = New-Object System.Drawing.Size(775, 165)
$form.Controls.Add($txtLog)

function Escribir-Log {
    param([string]$Texto)
    $marca = Get-Date -Format "HH:mm:ss"
    $txtLog.AppendText("[$marca] $Texto`r`n")
}

# ---------- 4. Pestana: Instalar Apps (winget) ----------
$tabApps = New-Object System.Windows.Forms.TabPage
$tabApps.Text = "Instalar Apps"
$tabs.TabPages.Add($tabApps)

$cmbCategoriaApps = New-Object System.Windows.Forms.ComboBox
$cmbCategoriaApps.Location = New-Object System.Drawing.Point(10, 10)
$cmbCategoriaApps.Size = New-Object System.Drawing.Size(200, 25)
$cmbCategoriaApps.DropDownStyle = "DropDownList"
foreach ($c in $CategoriasApps) { [void]$cmbCategoriaApps.Items.Add($c) }
$cmbCategoriaApps.SelectedIndex = 0
$tabApps.Controls.Add($cmbCategoriaApps)

$listApps = New-Object System.Windows.Forms.CheckedListBox
$listApps.Location = New-Object System.Drawing.Point(10, 45)
$listApps.Size = New-Object System.Drawing.Size(500, 295)
$listApps.CheckOnClick = $true
$tabApps.Controls.Add($listApps)

function Refrescar-ListaApps {
    $filtro = $cmbCategoriaApps.SelectedItem
    $marcadas = $listApps.CheckedItems | ForEach-Object { $_ }
    $listApps.Items.Clear()
    $apps = if ($filtro -eq "Todas") { $AppsDisponibles } else { $AppsDisponibles | Where-Object { $_.Categoria -eq $filtro } }
    foreach ($app in $apps) {
        $idx = $listApps.Items.Add($app.Nombre)
        if ($marcadas -contains $app.Nombre) { $listApps.SetItemChecked($idx, $true) }
    }
}
$cmbCategoriaApps.Add_SelectedIndexChanged({ Refrescar-ListaApps })
Refrescar-ListaApps

$btnInstalarApps = New-Object System.Windows.Forms.Button
$btnInstalarApps.Text = "Instalar seleccionadas"
$btnInstalarApps.Size = New-Object System.Drawing.Size(220, 40)
$btnInstalarApps.Location = New-Object System.Drawing.Point(530, 10)
$tabApps.Controls.Add($btnInstalarApps)

$lblApps = New-Object System.Windows.Forms.Label
$lblApps.Text = "Requiere tener 'winget' instalado (viene por defecto en Windows 10/11 actualizado). Cada app se instala con 'winget install --id <id> -e --silent'. Usa el filtro de categoria para navegar el catalogo."
$lblApps.Size = New-Object System.Drawing.Size(220, 140)
$lblApps.Location = New-Object System.Drawing.Point(530, 60)
$tabApps.Controls.Add($lblApps)

$btnInstalarApps.Add_Click({
    $seleccionadas = $AppsDisponibles | Where-Object { $listApps.CheckedItems -contains $_.Nombre }
    if ($seleccionadas.Count -eq 0) {
        Escribir-Log "No seleccionaste ninguna app."
        return
    }
    $comandos = $seleccionadas | ForEach-Object {
        "winget install --id $($_.Id) -e --accept-source-agreements --accept-package-agreements"
    }
    $script = $comandos -join " ; "
    Escribir-Log "Instalando apps: $($seleccionadas.Nombre -join ', ')"
    Start-Process powershell -ArgumentList "-NoExit -NoProfile -Command $script"
})

# ---------- 5. Pestana: Tweaks del sistema ----------
$tabTweaks = New-Object System.Windows.Forms.TabPage
$tabTweaks.Text = "Tweaks del Sistema"
$tabs.TabPages.Add($tabTweaks)

$cmbCategoriaTweaks = New-Object System.Windows.Forms.ComboBox
$cmbCategoriaTweaks.Location = New-Object System.Drawing.Point(10, 10)
$cmbCategoriaTweaks.Size = New-Object System.Drawing.Size(200, 25)
$cmbCategoriaTweaks.DropDownStyle = "DropDownList"
foreach ($c in $CategoriasTweaks) { [void]$cmbCategoriaTweaks.Items.Add($c) }
$cmbCategoriaTweaks.SelectedIndex = 0
$tabTweaks.Controls.Add($cmbCategoriaTweaks)

$listTweaks = New-Object System.Windows.Forms.CheckedListBox
$listTweaks.Location = New-Object System.Drawing.Point(10, 45)
$listTweaks.Size = New-Object System.Drawing.Size(500, 295)
$listTweaks.CheckOnClick = $true
$tabTweaks.Controls.Add($listTweaks)

function Refrescar-ListaTweaks {
    $filtro = $cmbCategoriaTweaks.SelectedItem
    $marcados = $listTweaks.CheckedItems | ForEach-Object { $_ }
    $listTweaks.Items.Clear()
    $tw = if ($filtro -eq "Todas") { $TweaksDisponibles } else { $TweaksDisponibles | Where-Object { $_.Categoria -eq $filtro } }
    foreach ($t in $tw) {
        $idx = $listTweaks.Items.Add($t.Nombre)
        if ($marcados -contains $t.Nombre) { $listTweaks.SetItemChecked($idx, $true) }
    }
}
$cmbCategoriaTweaks.Add_SelectedIndexChanged({ Refrescar-ListaTweaks })
Refrescar-ListaTweaks

$btnAplicarTweaks = New-Object System.Windows.Forms.Button
$btnAplicarTweaks.Text = "Aplicar seleccionados"
$btnAplicarTweaks.Size = New-Object System.Drawing.Size(220, 40)
$btnAplicarTweaks.Location = New-Object System.Drawing.Point(530, 10)
$tabTweaks.Controls.Add($btnAplicarTweaks)

$lblTweaks = New-Object System.Windows.Forms.Label
$lblTweaks.Text = "Cada tweak modifica el registro o una configuracion del sistema. Se recomienda crear un punto de restauracion antes de aplicar varios a la vez. Usa el filtro de categoria para navegar el catalogo."
$lblTweaks.Size = New-Object System.Drawing.Size(220, 140)
$lblTweaks.Location = New-Object System.Drawing.Point(530, 60)
$tabTweaks.Controls.Add($lblTweaks)

$btnAplicarTweaks.Add_Click({
    $seleccionados = $TweaksDisponibles | Where-Object { $listTweaks.CheckedItems -contains $_.Nombre }
    if ($seleccionados.Count -eq 0) {
        Escribir-Log "No seleccionaste ningun tweak."
        return
    }
    foreach ($t in $seleccionados) {
        try {
            Invoke-Expression $t.Comando
            Escribir-Log "Tweak aplicado: $($t.Nombre)"
        } catch {
            Escribir-Log "Error aplicando '$($t.Nombre)': $($_.Exception.Message)"
        }
    }
})

# ---------- 6. Pestana: Herramientas remotas ----------
$tabHerr = New-Object System.Windows.Forms.TabPage
$tabHerr.Text = "Herramientas"
$tabs.TabPages.Add($tabHerr)

$panelRemotas = New-Object System.Windows.Forms.FlowLayoutPanel
$panelRemotas.Location = New-Object System.Drawing.Point(10, 10)
$panelRemotas.Size = New-Object System.Drawing.Size(740, 330)
$panelRemotas.AutoScroll = $true
$tabHerr.Controls.Add($panelRemotas)

foreach ($herr in $HerramientasRemotas) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $herr.Nombre
    $btn.Size = New-Object System.Drawing.Size(220, 45)
    $btn.Tag = $herr.Comando
    $btn.Add_Click({
        param($sender, $e)
        $cmd = $sender.Tag
        Escribir-Log "Lanzando: $($sender.Text)"
        Start-Process powershell -ArgumentList "-NoExit -NoProfile -Command $cmd"
    })
    $panelRemotas.Controls.Add($btn)
}

# ---------- 7. Pestana: Instaladores locales ----------
$tabLocales = New-Object System.Windows.Forms.TabPage
$tabLocales.Text = "Instaladores Locales"
$tabs.TabPages.Add($tabLocales)

$btnAgregar = New-Object System.Windows.Forms.Button
$btnAgregar.Text = "+ Agregar instalador..."
$btnAgregar.Size = New-Object System.Drawing.Size(180, 30)
$btnAgregar.Location = New-Object System.Drawing.Point(560, 10)
$tabLocales.Controls.Add($btnAgregar)

$panelLocales = New-Object System.Windows.Forms.FlowLayoutPanel
$panelLocales.Location = New-Object System.Drawing.Point(10, 50)
$panelLocales.Size = New-Object System.Drawing.Size(740, 290)
$panelLocales.AutoScroll = $true
$panelLocales.BorderStyle = "FixedSingle"
$tabLocales.Controls.Add($panelLocales)

function Refrescar-Instaladores {
    $panelLocales.Controls.Clear()
    $archivos = Get-ChildItem -Path $CarpetaInstaladores -Include *.exe, *.msi -File -Recurse -ErrorAction SilentlyContinue

    if ($archivos.Count -eq 0) {
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = "No hay instaladores en la carpeta. Usa 'Agregar instalador...'"
        $lbl.AutoSize = $true
        $lbl.Padding = New-Object System.Windows.Forms.Padding(10)
        $panelLocales.Controls.Add($lbl)
        return
    }

    foreach ($archivo in $archivos) {
        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $archivo.Name
        $btn.Size = New-Object System.Drawing.Size(220, 45)
        $btn.Tag = $archivo.FullName
        $btn.Add_Click({
            param($sender, $e)
            $ruta = $sender.Tag
            Escribir-Log "Ejecutando instalador: $ruta"
            Start-Process -FilePath $ruta -Verb RunAs
        })
        $panelLocales.Controls.Add($btn)
    }
}

$btnAgregar.Add_Click({
    $dialogo = New-Object System.Windows.Forms.OpenFileDialog
    $dialogo.Filter = "Instaladores (*.exe;*.msi)|*.exe;*.msi"
    $dialogo.Multiselect = $true
    if ($dialogo.ShowDialog() -eq "OK") {
        foreach ($origen in $dialogo.FileNames) {
            $destino = Join-Path $CarpetaInstaladores (Split-Path $origen -Leaf)
            Copy-Item -Path $origen -Destination $destino -Force
            Escribir-Log "Agregado a la lista: $(Split-Path $origen -Leaf)"
        }
        Refrescar-Instaladores
    }
})

Refrescar-Instaladores
Escribir-Log "Panel iniciado con privilegios de administrador."

# ---------- 8. Mostrar ----------
[void]$form.ShowDialog()
