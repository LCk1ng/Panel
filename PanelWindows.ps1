# =========================================================
#  PanelWindows.ps1  (v3 - interfaz WPF, tema oscuro, RGB animado)
#  Panel con: Instalar Apps (winget), Tweaks del sistema,
#  Herramientas remotas curadas, e Instaladores locales.
#
#  Ejecucion local:  .\PanelWindows.ps1
#  Ejecucion remota: irm https://raw.githubusercontent.com/LCk1ng/Panel/main/PanelWindows.ps1 | iex
# =========================================================

$ScriptUrl = "https://raw.githubusercontent.com/LCk1ng/Panel/main/PanelWindows.ps1"

# ---------- 1. Auto-elevacion a Administrador ----------
$esAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $esAdmin) {
    if ($PSCommandPath) {
        Start-Process powershell -Verb RunAs -ArgumentList `
            "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    } else {
        Start-Process powershell -Verb RunAs -ArgumentList `
            "-NoProfile -Command `"irm '$ScriptUrl' | iex`""
    }
    exit
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

# ---------- 2. Configuracion de carpetas ----------
$CarpetaBase = if ($PSScriptRoot) { $PSScriptRoot } else { Join-Path $env:USERPROFILE "PanelWindows" }
if (-not (Test-Path $CarpetaBase)) { New-Item -ItemType Directory -Path $CarpetaBase -Force | Out-Null }
$CarpetaInstaladores = Join-Path $CarpetaBase "Instaladores"
if (-not (Test-Path $CarpetaInstaladores)) { New-Item -ItemType Directory -Path $CarpetaInstaladores -Force | Out-Null }

# ---------- 3. Catalogos ----------
$HerramientasRemotas = @(
    [PSCustomObject]@{ Nombre = "🧰  Chris Titus Tech - WinUtil";  Comando = 'irm https://christitus.com/win | iex' }
    [PSCustomObject]@{ Nombre = "⚡  Winhance (optimizador Windows)"; Comando = 'irm "https://get.winhance.net" | iex' }
)

$AppsDisponibles = @(
    [PSCustomObject]@{ Categoria = "Navegadores";  Nombre = "Google Chrome";        Id = "Google.Chrome" }
    [PSCustomObject]@{ Categoria = "Navegadores";  Nombre = "Mozilla Firefox";      Id = "Mozilla.Firefox" }
    [PSCustomObject]@{ Categoria = "Navegadores";  Nombre = "Brave";                Id = "Brave.Brave" }
    [PSCustomObject]@{ Categoria = "Navegadores";  Nombre = "Opera";                Id = "Opera.Opera" }
    [PSCustomObject]@{ Categoria = "Multimedia";   Nombre = "VLC Media Player";     Id = "VideoLAN.VLC" }
    [PSCustomObject]@{ Categoria = "Multimedia";   Nombre = "Spotify";              Id = "Spotify.Spotify" }
    [PSCustomObject]@{ Categoria = "Multimedia";   Nombre = "OBS Studio";           Id = "OBSProject.OBSStudio" }
    [PSCustomObject]@{ Categoria = "Multimedia";   Nombre = "Audacity";             Id = "Audacity.Audacity" }
    [PSCustomObject]@{ Categoria = "Multimedia";   Nombre = "HandBrake";            Id = "HandBrake.HandBrake" }
    [PSCustomObject]@{ Categoria = "Utilidades";   Nombre = "7-Zip";                Id = "7zip.7zip" }
    [PSCustomObject]@{ Categoria = "Utilidades";   Nombre = "WinRAR";               Id = "RARLab.WinRAR" }
    [PSCustomObject]@{ Categoria = "Utilidades";   Nombre = "Notepad++";            Id = "Notepad++.Notepad++" }
    [PSCustomObject]@{ Categoria = "Utilidades";   Nombre = "Adobe Acrobat Reader"; Id = "Adobe.Acrobat.Reader.64-bit" }
    [PSCustomObject]@{ Categoria = "Utilidades";   Nombre = "PowerToys";            Id = "Microsoft.PowerToys" }
    [PSCustomObject]@{ Categoria = "Utilidades";   Nombre = "Everything (buscador)"; Id = "voidtools.Everything" }
    [PSCustomObject]@{ Categoria = "Desarrollo";   Nombre = "Visual Studio Code";   Id = "Microsoft.VisualStudioCode" }
    [PSCustomObject]@{ Categoria = "Desarrollo";   Nombre = "Git";                  Id = "Git.Git" }
    [PSCustomObject]@{ Categoria = "Desarrollo";   Nombre = "Python 3";             Id = "Python.Python.3.12" }
    [PSCustomObject]@{ Categoria = "Desarrollo";   Nombre = "Node.js";              Id = "OpenJS.NodeJS.LTS" }
    [PSCustomObject]@{ Categoria = "Desarrollo";   Nombre = "Docker Desktop";       Id = "Docker.DockerDesktop" }
    [PSCustomObject]@{ Categoria = "Desarrollo";   Nombre = "Postman";              Id = "Postman.Postman" }
    [PSCustomObject]@{ Categoria = "Comunicacion"; Nombre = "Discord";              Id = "Discord.Discord" }
    [PSCustomObject]@{ Categoria = "Comunicacion"; Nombre = "Zoom";                 Id = "Zoom.Zoom" }
    [PSCustomObject]@{ Categoria = "Comunicacion"; Nombre = "Telegram Desktop";     Id = "Telegram.TelegramDesktop" }
)
$CategoriasApps = @("Todas") + ($AppsDisponibles.Categoria | Select-Object -Unique)

$TweaksDisponibles = @(
    [PSCustomObject]@{ Categoria = "Personalizacion"; Nombre = "Mostrar extensiones de archivo"; Comando = `
        'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value 0' }
    [PSCustomObject]@{ Categoria = "Personalizacion"; Nombre = "Mostrar archivos ocultos"; Comando = `
        'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Hidden -Value 1' }
    [PSCustomObject]@{ Categoria = "Personalizacion"; Nombre = "Activar modo oscuro"; Comando = `
        'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -Value 0; Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name SystemUsesLightTheme -Value 0' }
    [PSCustomObject]@{ Categoria = "Rendimiento"; Nombre = "Plan de energia: Alto rendimiento"; Comando = `
        'powercfg /setactive SCHEME_MIN' }
    [PSCustomObject]@{ Categoria = "Rendimiento"; Nombre = "Plan de energia: Equilibrado"; Comando = `
        'powercfg /setactive SCHEME_BALANCED' }
    [PSCustomObject]@{ Categoria = "Rendimiento"; Nombre = "Desactivar animaciones de Windows"; Comando = `
        'Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name UserPreferencesMask -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00))' }
    [PSCustomObject]@{ Categoria = "Privacidad"; Nombre = "Reducir telemetria de Windows"; Comando = `
        'New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null; Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name AllowTelemetry -Value 0 -Type DWord' }
    [PSCustomObject]@{ Categoria = "Privacidad"; Nombre = "Desactivar busqueda web (Bing) en Inicio"; Comando = `
        'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name BingSearchEnabled -Value 0' }
    [PSCustomObject]@{ Categoria = "Privacidad"; Nombre = "Desactivar ID de publicidad"; Comando = `
        'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name Enabled -Value 0' }
)
$CategoriasTweaks = @("Todas") + ($TweaksDisponibles.Categoria | Select-Object -Unique)

$checkedAppNames   = New-Object 'System.Collections.Generic.HashSet[string]'
$checkedTweakNames = New-Object 'System.Collections.Generic.HashSet[string]'

# ---------- 4. XAML: interfaz oscura con RGB animado ----------
[xml]$xamlNode = $null
$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Panel de Administracion - Windows Toolkit"
        Height="780" Width="920" MinHeight="650" MinWidth="820"
        WindowStartupLocation="CenterScreen"
        Background="#0D0D0F" FontFamily="Segoe UI">
    <Window.Resources>
        <SolidColorBrush x:Key="Card" Color="#17171B"/>
        <SolidColorBrush x:Key="Text1" Color="#F2F2F2"/>
        <SolidColorBrush x:Key="Text2" Color="#9A9AA2"/>

        <Style x:Key="TileButton" TargetType="Button">
            <Setter Property="Background" Value="#17171B"/>
            <Setter Property="Foreground" Value="#F2F2F2"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Margin" Value="6"/>
            <Setter Property="RenderTransformOrigin" Value="0.5,0.5"/>
            <Setter Property="RenderTransform">
                <Setter.Value><ScaleTransform ScaleX="1" ScaleY="1"/></Setter.Value>
            </Setter>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="12">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="10"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Trigger.EnterActions>
                        <BeginStoryboard>
                            <Storyboard>
                                <ColorAnimation Storyboard.TargetProperty="Background.Color" To="#26262E" Duration="0:0:0.15"/>
                                <DoubleAnimation Storyboard.TargetProperty="RenderTransform.ScaleX" To="1.04" Duration="0:0:0.15"/>
                                <DoubleAnimation Storyboard.TargetProperty="RenderTransform.ScaleY" To="1.04" Duration="0:0:0.15"/>
                            </Storyboard>
                        </BeginStoryboard>
                    </Trigger.EnterActions>
                    <Trigger.ExitActions>
                        <BeginStoryboard>
                            <Storyboard>
                                <ColorAnimation Storyboard.TargetProperty="Background.Color" To="#17171B" Duration="0:0:0.15"/>
                                <DoubleAnimation Storyboard.TargetProperty="RenderTransform.ScaleX" To="1" Duration="0:0:0.15"/>
                                <DoubleAnimation Storyboard.TargetProperty="RenderTransform.ScaleY" To="1" Duration="0:0:0.15"/>
                            </Storyboard>
                        </BeginStoryboard>
                    </Trigger.ExitActions>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style x:Key="AccentButton" TargetType="Button" BasedOn="{StaticResource TileButton}">
            <Setter Property="Background" Value="#2D2D63"/>
            <Setter Property="FontWeight" Value="Bold"/>
        </Style>

        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#F2F2F2"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Margin" Value="4,5"/>
        </Style>

        <Style TargetType="ComboBox">
            <Setter Property="Background" Value="#17171B"/>
            <Setter Property="Foreground" Value="#F2F2F2"/>
            <Setter Property="Padding" Value="8,5"/>
        </Style>

        <Style TargetType="TabItem">
            <Setter Property="Foreground" Value="#9A9AA2"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Padding" Value="16,10"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Border x:Name="tbd" Background="Transparent" CornerRadius="8,8,0,0" Margin="0,0,4,0">
                            <ContentPresenter ContentSource="Header" Margin="14,8"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="tbd" Property="Background" Value="#17171B"/>
                                <Setter Property="Foreground" Value="#F2F2F2"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Window.Triggers>
        <EventTrigger RoutedEvent="FrameworkElement.Loaded">
            <BeginStoryboard>
                <Storyboard RepeatBehavior="Forever">
                    <ColorAnimationUsingKeyFrames Storyboard.TargetName="Stop0" Storyboard.TargetProperty="Color">
                        <LinearColorKeyFrame KeyTime="0:0:0" Value="#FF0055"/>
                        <LinearColorKeyFrame KeyTime="0:0:2" Value="#00E0FF"/>
                        <LinearColorKeyFrame KeyTime="0:0:4" Value="#B000FF"/>
                        <LinearColorKeyFrame KeyTime="0:0:6" Value="#FF0055"/>
                    </ColorAnimationUsingKeyFrames>
                    <ColorAnimationUsingKeyFrames Storyboard.TargetName="Stop1" Storyboard.TargetProperty="Color" BeginTime="0:0:1">
                        <LinearColorKeyFrame KeyTime="0:0:0" Value="#00E0FF"/>
                        <LinearColorKeyFrame KeyTime="0:0:2" Value="#B000FF"/>
                        <LinearColorKeyFrame KeyTime="0:0:4" Value="#FF0055"/>
                        <LinearColorKeyFrame KeyTime="0:0:6" Value="#00E0FF"/>
                    </ColorAnimationUsingKeyFrames>
                    <ColorAnimationUsingKeyFrames Storyboard.TargetName="Stop2" Storyboard.TargetProperty="Color" BeginTime="0:0:2">
                        <LinearColorKeyFrame KeyTime="0:0:0" Value="#B000FF"/>
                        <LinearColorKeyFrame KeyTime="0:0:2" Value="#FF0055"/>
                        <LinearColorKeyFrame KeyTime="0:0:4" Value="#00E0FF"/>
                        <LinearColorKeyFrame KeyTime="0:0:6" Value="#B000FF"/>
                    </ColorAnimationUsingKeyFrames>
                </Storyboard>
            </BeginStoryboard>
        </EventTrigger>
    </Window.Triggers>

    <Grid Margin="22">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="6"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="150"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,12">
            <TextBlock Text="Panel de Administracion" FontSize="24" FontWeight="Bold" Foreground="#F2F2F2"/>
            <TextBlock Text="  ejecutando como Administrador" FontSize="13" Foreground="#9A9AA2" VerticalAlignment="Bottom" Margin="10,0,0,4"/>
        </StackPanel>

        <Border Grid.Row="1" CornerRadius="3" Margin="0,0,0,14">
            <Border.Background>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                    <GradientStop x:Name="Stop0" Offset="0"   Color="#FF0055"/>
                    <GradientStop x:Name="Stop1" Offset="0.5" Color="#00E0FF"/>
                    <GradientStop x:Name="Stop2" Offset="1"   Color="#B000FF"/>
                </LinearGradientBrush>
            </Border.Background>
        </Border>

        <TabControl x:Name="MainTabs" Grid.Row="2" Background="Transparent" BorderThickness="0">
            <TabItem Header="Instalar Apps">
                <Grid Margin="0,10,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="230"/>
                    </Grid.ColumnDefinitions>
                    <Border Grid.Column="0" Background="#111114" CornerRadius="12" Padding="10">
                        <DockPanel>
                            <ComboBox x:Name="CmbCategoriaApps" DockPanel.Dock="Top" Margin="4,0,4,10" Width="220" HorizontalAlignment="Left"/>
                            <ScrollViewer VerticalScrollBarVisibility="Auto">
                                <StackPanel x:Name="PanelListApps"/>
                            </ScrollViewer>
                        </DockPanel>
                    </Border>
                    <StackPanel Grid.Column="1" Margin="14,10,0,0">
                        <Button x:Name="BtnInstalarApps" Content="Instalar seleccionadas" Style="{StaticResource AccentButton}" Height="46"/>
                        <TextBlock Foreground="#9A9AA2" FontSize="12" TextWrapping="Wrap" Margin="6,16,6,0"
                                   Text="Requiere winget (incluido en Windows 10/11 actualizado). Filtra por categoria y marca lo que quieras instalar."/>
                    </StackPanel>
                </Grid>
            </TabItem>

            <TabItem Header="Tweaks del Sistema">
                <Grid Margin="0,10,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="230"/>
                    </Grid.ColumnDefinitions>
                    <Border Grid.Column="0" Background="#111114" CornerRadius="12" Padding="10">
                        <DockPanel>
                            <ComboBox x:Name="CmbCategoriaTweaks" DockPanel.Dock="Top" Margin="4,0,4,10" Width="220" HorizontalAlignment="Left"/>
                            <ScrollViewer VerticalScrollBarVisibility="Auto">
                                <StackPanel x:Name="PanelListTweaks"/>
                            </ScrollViewer>
                        </DockPanel>
                    </Border>
                    <StackPanel Grid.Column="1" Margin="14,10,0,0">
                        <Button x:Name="BtnAplicarTweaks" Content="Aplicar seleccionados" Style="{StaticResource AccentButton}" Height="46"/>
                        <TextBlock Foreground="#9A9AA2" FontSize="12" TextWrapping="Wrap" Margin="6,16,6,0"
                                   Text="Cada tweak modifica registro/configuracion. Se recomienda un punto de restauracion antes de aplicar varios."/>
                    </StackPanel>
                </Grid>
            </TabItem>

            <TabItem Header="Herramientas">
                <Border Background="#111114" CornerRadius="12" Padding="14" Margin="0,10,0,0">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <WrapPanel x:Name="PanelHerramientas"/>
                    </ScrollViewer>
                </Border>
            </TabItem>

            <TabItem Header="Instaladores Locales">
                <DockPanel Margin="0,10,0,0">
                    <Button x:Name="BtnAgregarInstalador" DockPanel.Dock="Top" Content="+ Agregar instalador..."
                            Style="{StaticResource AccentButton}" HorizontalAlignment="Right" Width="200" Height="38" Margin="0,0,0,10"/>
                    <Border Background="#111114" CornerRadius="12" Padding="14">
                        <ScrollViewer VerticalScrollBarVisibility="Auto">
                            <WrapPanel x:Name="PanelInstaladores"/>
                        </ScrollViewer>
                    </Border>
                </DockPanel>
            </TabItem>
        </TabControl>

        <TextBlock Grid.Row="3" Text="Registro de actividad" FontWeight="Bold" Foreground="#F2F2F2" Margin="0,14,0,6"/>
        <Border Grid.Row="4" Background="#111114" CornerRadius="12" Padding="12">
            <ScrollViewer x:Name="LogScroll" VerticalScrollBarVisibility="Auto">
                <TextBlock x:Name="LogText" Foreground="#8CFFA0" FontFamily="Consolas" FontSize="12" TextWrapping="Wrap"/>
            </ScrollViewer>
        </Border>
    </Grid>
</Window>
'@

$window = [Windows.Markup.XamlReader]::Parse($xaml)

# ---------- 5. Referencias a controles ----------
$CmbCategoriaApps    = $window.FindName("CmbCategoriaApps")
$PanelListApps       = $window.FindName("PanelListApps")
$BtnInstalarApps     = $window.FindName("BtnInstalarApps")
$CmbCategoriaTweaks  = $window.FindName("CmbCategoriaTweaks")
$PanelListTweaks     = $window.FindName("PanelListTweaks")
$BtnAplicarTweaks    = $window.FindName("BtnAplicarTweaks")
$PanelHerramientas   = $window.FindName("PanelHerramientas")
$PanelInstaladores   = $window.FindName("PanelInstaladores")
$BtnAgregarInstalador= $window.FindName("BtnAgregarInstalador")
$LogText             = $window.FindName("LogText")
$LogScroll           = $window.FindName("LogScroll")

function Escribir-Log {
    param([string]$Texto)
    $marca = Get-Date -Format "HH:mm:ss"
    $LogText.Text += "[$marca] $Texto`n"
    $LogScroll.ScrollToBottom()
}

# ---------- 6. Pestana Apps ----------
foreach ($c in $CategoriasApps) { [void]$CmbCategoriaApps.Items.Add($c) }
$CmbCategoriaApps.SelectedIndex = 0

function Refrescar-ListaApps {
    $PanelListApps.Children.Clear()
    $filtro = $CmbCategoriaApps.SelectedItem
    $apps = if ($filtro -eq "Todas") { $AppsDisponibles } else { $AppsDisponibles | Where-Object { $_.Categoria -eq $filtro } }
    foreach ($app in $apps) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Content = $app.Nombre
        $cb.Tag = $app
        $cb.IsChecked = $checkedAppNames.Contains($app.Nombre)
        $cb.Add_Checked({ param($s,$e) [void]$checkedAppNames.Add($s.Tag.Nombre) })
        $cb.Add_Unchecked({ param($s,$e) [void]$checkedAppNames.Remove($s.Tag.Nombre) })
        [void]$PanelListApps.Children.Add($cb)
    }
}
$CmbCategoriaApps.Add_SelectionChanged({ Refrescar-ListaApps })
Refrescar-ListaApps

$BtnInstalarApps.Add_Click({
    $seleccionadas = $AppsDisponibles | Where-Object { $checkedAppNames.Contains($_.Nombre) }
    if ($seleccionadas.Count -eq 0) { Escribir-Log "No seleccionaste ninguna app."; return }
    $comandos = $seleccionadas | ForEach-Object { "winget install --id $($_.Id) -e --accept-source-agreements --accept-package-agreements" }
    $script = $comandos -join " ; "
    Escribir-Log "Instalando apps: $($seleccionadas.Nombre -join ', ')"
    Start-Process powershell -ArgumentList "-NoExit -NoProfile -Command $script"
})

# ---------- 7. Pestana Tweaks ----------
foreach ($c in $CategoriasTweaks) { [void]$CmbCategoriaTweaks.Items.Add($c) }
$CmbCategoriaTweaks.SelectedIndex = 0

function Refrescar-ListaTweaks {
    $PanelListTweaks.Children.Clear()
    $filtro = $CmbCategoriaTweaks.SelectedItem
    $tw = if ($filtro -eq "Todas") { $TweaksDisponibles } else { $TweaksDisponibles | Where-Object { $_.Categoria -eq $filtro } }
    foreach ($t in $tw) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Content = $t.Nombre
        $cb.Tag = $t
        $cb.IsChecked = $checkedTweakNames.Contains($t.Nombre)
        $cb.Add_Checked({ param($s,$e) [void]$checkedTweakNames.Add($s.Tag.Nombre) })
        $cb.Add_Unchecked({ param($s,$e) [void]$checkedTweakNames.Remove($s.Tag.Nombre) })
        [void]$PanelListTweaks.Children.Add($cb)
    }
}
$CmbCategoriaTweaks.Add_SelectionChanged({ Refrescar-ListaTweaks })
Refrescar-ListaTweaks

$BtnAplicarTweaks.Add_Click({
    $seleccionados = $TweaksDisponibles | Where-Object { $checkedTweakNames.Contains($_.Nombre) }
    if ($seleccionados.Count -eq 0) { Escribir-Log "No seleccionaste ningun tweak."; return }
    foreach ($t in $seleccionados) {
        try { Invoke-Expression $t.Comando; Escribir-Log "Tweak aplicado: $($t.Nombre)" }
        catch { Escribir-Log "Error aplicando '$($t.Nombre)': $($_.Exception.Message)" }
    }
})

# ---------- 8. Pestana Herramientas ----------
foreach ($herr in $HerramientasRemotas) {
    $btn = New-Object System.Windows.Controls.Button
    $btn.Content = $herr.Nombre
    $btn.Style = $window.FindResource("TileButton")
    $btn.Width = 260; $btn.Height = 60
    $btn.Tag = $herr.Comando
    $btn.Add_Click({
        param($sender, $e)
        Escribir-Log "Lanzando: $($sender.Content)"
        Start-Process powershell -ArgumentList "-NoExit -NoProfile -Command $($sender.Tag)"
    })
    [void]$PanelHerramientas.Children.Add($btn)
}

# ---------- 9. Pestana Instaladores locales ----------
function Refrescar-Instaladores {
    $PanelInstaladores.Children.Clear()
    $archivos = Get-ChildItem -Path $CarpetaInstaladores -Include *.exe, *.msi -File -Recurse -ErrorAction SilentlyContinue
    if ($archivos.Count -eq 0) {
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Text = "No hay instaladores en la carpeta. Usa '+ Agregar instalador...'"
        $tb.Foreground = "#9A9AA2"
        $tb.Margin = 10
        [void]$PanelInstaladores.Children.Add($tb)
        return
    }
    foreach ($archivo in $archivos) {
        $btn = New-Object System.Windows.Controls.Button
        $btn.Content = "💽  $($archivo.Name)"
        $btn.Style = $window.FindResource("TileButton")
        $btn.Width = 260; $btn.Height = 60
        $btn.Tag = $archivo.FullName
        $btn.Add_Click({
            param($sender, $e)
            Escribir-Log "Ejecutando instalador: $($sender.Tag)"
            Start-Process -FilePath $sender.Tag -Verb RunAs
        })
        [void]$PanelInstaladores.Children.Add($btn)
    }
}

$BtnAgregarInstalador.Add_Click({
    $dialogo = New-Object Microsoft.Win32.OpenFileDialog
    $dialogo.Filter = "Instaladores (*.exe;*.msi)|*.exe;*.msi"
    $dialogo.Multiselect = $true
    if ($dialogo.ShowDialog()) {
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

# ---------- 10. Mostrar ----------
[void]$window.ShowDialog()
