# =========================================================
#  PanelWindows.ps1  (v5 - Interfaz WPF, Sin bordes nativos, Tema, RGB)
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
    [PSCustomObject]@{ Nombre = "⚡  Winhance (optimizador)"; Comando = 'irm "https://get.winhance.net" | iex' }
)

$AppsDisponibles = @(
    [PSCustomObject]@{ Categoria = "Navegadores";  Nombre = "Google Chrome";        Id = "Google.Chrome" }
    [PSCustomObject]@{ Categoria = "Navegadores";  Nombre = "Mozilla Firefox";      Id = "Mozilla.Firefox" }
    [PSCustomObject]@{ Categoria = "Navegadores";  Nombre = "Brave";                Id = "Brave.Brave" }
    [PSCustomObject]@{ Categoria = "Multimedia";   Nombre = "VLC Media Player";     Id = "VideoLAN.VLC" }
    [PSCustomObject]@{ Categoria = "Multimedia";   Nombre = "Spotify";              Id = "Spotify.Spotify" }
    [PSCustomObject]@{ Categoria = "Multimedia";   Nombre = "OBS Studio";           Id = "OBSProject.OBSStudio" }
    [PSCustomObject]@{ Categoria = "Utilidades";   Nombre = "7-Zip";                Id = "7zip.7zip" }
    [PSCustomObject]@{ Categoria = "Utilidades";   Nombre = "Notepad++";            Id = "Notepad++.Notepad++" }
    [PSCustomObject]@{ Categoria = "Desarrollo";   Nombre = "Visual Studio Code";   Id = "Microsoft.VisualStudioCode" }
    [PSCustomObject]@{ Categoria = "Desarrollo";   Nombre = "Python 3";             Id = "Python.Python.3.12" }
    [PSCustomObject]@{ Categoria = "Comunicacion"; Nombre = "Discord";              Id = "Discord.Discord" }
)
$CategoriasApps = @("Todas") + ($AppsDisponibles.Categoria | Select-Object -Unique)

$TweaksDisponibles = @(
    [PSCustomObject]@{ Categoria = "Personalizacion"; Nombre = "Mostrar extensiones de archivo"; Comando = 'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value 0' }
    [PSCustomObject]@{ Categoria = "Personalizacion"; Nombre = "Mostrar archivos ocultos"; Comando = 'Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Hidden -Value 1' }
    [PSCustomObject]@{ Categoria = "Rendimiento"; Nombre = "Plan de energia: Alto rendimiento"; Comando = 'powercfg /setactive SCHEME_MIN' }
    [PSCustomObject]@{ Categoria = "Rendimiento"; Nombre = "Desactivar animaciones de Windows"; Comando = 'Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name UserPreferencesMask -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00))' }
)
$CategoriasTweaks = @("Todas") + ($TweaksDisponibles.Categoria | Select-Object -Unique)

$checkedAppNames   = New-Object 'System.Collections.Generic.HashSet[string]'
$checkedTweakNames = New-Object 'System.Collections.Generic.HashSet[string]'

# ---------- 4. XAML: Interfaz sin bordes ----------
[xml]$xamlNode = $null
$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Panel de Administracion"
        Height="780" Width="920" MinHeight="650" MinWidth="820"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent" 
        FontFamily="Segoe UI">
    
    <Window.Resources>
        <SolidColorBrush x:Key="WindowBg" Color="#0D0D0F"/>
        <SolidColorBrush x:Key="CardBg" Color="#111114"/>
        <SolidColorBrush x:Key="ButtonBg" Color="#17171B"/>
        <SolidColorBrush x:Key="TextPrimary" Color="#F2F2F2"/>
        <SolidColorBrush x:Key="TextSecondary" Color="#9A9AA2"/>
        <SolidColorBrush x:Key="AccentBg" Color="#2D2D63"/>

        <LinearGradientBrush x:Key="RgbBrush" StartPoint="0,0" EndPoint="1,0">
            <GradientStop x:Name="Stop0" Offset="0"   Color="#FF0055"/>
            <GradientStop x:Name="Stop1" Offset="0.5" Color="#00E0FF"/>
            <GradientStop x:Name="Stop2" Offset="1"   Color="#B000FF"/>
        </LinearGradientBrush>

        <Style x:Key="TileButton" TargetType="Button">
            <Setter Property="Background" Value="{DynamicResource ButtonBg}"/>
            <Setter Property="Foreground" Value="{DynamicResource TextPrimary}"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Margin" Value="6"/>
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
                    <Setter Property="Opacity" Value="0.8"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style x:Key="AccentButton" TargetType="Button" BasedOn="{StaticResource TileButton}">
            <Setter Property="Background" Value="{DynamicResource AccentBg}"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Foreground" Value="#F2F2F2"/>
        </Style>

        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="{DynamicResource TextPrimary}"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Margin" Value="4,5"/>
        </Style>

        <Style TargetType="ComboBox">
            <Setter Property="Background" Value="{DynamicResource CardBg}"/>
            <Setter Property="Foreground" Value="{DynamicResource TextPrimary}"/>
            <Setter Property="Padding" Value="8,5"/>
        </Style>

        <Style TargetType="TabItem">
            <Setter Property="Foreground" Value="{DynamicResource TextSecondary}"/>
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
                                <Setter TargetName="tbd" Property="Background" Value="{DynamicResource ButtonBg}"/>
                                <Setter Property="Foreground" Value="{DynamicResource TextPrimary}"/>
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

    <Border Background="{DynamicResource WindowBg}" CornerRadius="12" BorderThickness="1" BorderBrush="#333333">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="35"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <!-- Barra Superior Arrastrable -->
            <Grid x:Name="CustomTitleBar" Grid.Row="0" Background="Transparent" Cursor="Hand">
                <TextBlock Text="Panel de Administracion - Toolkit" Foreground="{DynamicResource TextPrimary}" FontWeight="Bold" VerticalAlignment="Center" Margin="15,0,0,0"/>
                <Button x:Name="BtnCerrar" Content="✕" HorizontalAlignment="Right" Width="40" Background="Transparent" Foreground="{DynamicResource TextPrimary}" BorderThickness="0" FontSize="14" Cursor="Hand">
                    <Button.Style>
                        <Style TargetType="Button">
                            <Setter Property="Template">
                                <Setter.Value>
                                    <ControlTemplate TargetType="Button">
                                        <Border Background="{TemplateBinding Background}">
                                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        </Border>
                                    </ControlTemplate>
                                </Setter.Value>
                            </Setter>
                            <Style.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter Property="Background" Value="#E81123"/>
                                    <Setter Property="Foreground" Value="White"/>
                                </Trigger>
                            </Style.Triggers>
                        </Style>
                    </Button.Style>
                </Button>
            </Grid>

            <!-- Contenido Principal -->
            <Grid Grid.Row="1" Margin="22,0,22,22">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="8"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="150"/>
                    <RowDefinition Height="8"/>
                </Grid.RowDefinitions>

                <Grid Grid.Row="0" Margin="0,0,0,12">
                    <StackPanel Orientation="Horizontal">
                        <TextBlock Text="Panel de Administracion" FontSize="24" FontWeight="Bold" Foreground="{DynamicResource TextPrimary}"/>
                        <TextBlock Text="  (Administrador)" FontSize="13" Foreground="{DynamicResource TextSecondary}" VerticalAlignment="Bottom" Margin="10,0,0,4"/>
                    </StackPanel>
                    <Button x:Name="BtnTema" Content="☀️ Modo Claro" Style="{StaticResource AccentButton}" HorizontalAlignment="Right" Padding="15,5" Height="35"/>
                </Grid>

                <Border Grid.Row="1" CornerRadius="4" Margin="0,0,0,14" Background="{StaticResource RgbBrush}"/>

                <TabControl x:Name="MainTabs" Grid.Row="2" Background="Transparent" BorderThickness="0">
                    <TabItem Header="Instalar Apps">
                        <Grid Margin="0,10,0,0">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="230"/>
                            </Grid.ColumnDefinitions>
                            <Border Grid.Column="0" Background="{DynamicResource CardBg}" CornerRadius="12" Padding="10">
                                <DockPanel>
                                    <ComboBox x:Name="CmbCategoriaApps" DockPanel.Dock="Top" Margin="4,0,4,10" Width="220" HorizontalAlignment="Left"/>
                                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                                        <StackPanel x:Name="PanelListApps"/>
                                    </ScrollViewer>
                                </DockPanel>
                            </Border>
                            <StackPanel Grid.Column="1" Margin="14,10,0,0">
                                <Button x:Name="BtnInstalarApps" Content="Instalar seleccionadas" Style="{StaticResource AccentButton}" Height="46"/>
                                <TextBlock Foreground="{DynamicResource TextSecondary}" FontSize="12" TextWrapping="Wrap" Margin="6,16,6,0"
                                           Text="Requiere winget instalado en el sistema."/>
                            </StackPanel>
                        </Grid>
                    </TabItem>

                    <TabItem Header="Tweaks del Sistema">
                        <Grid Margin="0,10,0,0">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="230"/>
                            </Grid.ColumnDefinitions>
                            <Border Grid.Column="0" Background="{DynamicResource CardBg}" CornerRadius="12" Padding="10">
                                <DockPanel>
                                    <ComboBox x:Name="CmbCategoriaTweaks" DockPanel.Dock="Top" Margin="4,0,4,10" Width="220" HorizontalAlignment="Left"/>
                                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                                        <StackPanel x:Name="PanelListTweaks"/>
                                    </ScrollViewer>
                                </DockPanel>
                            </Border>
                            <StackPanel Grid.Column="1" Margin="14,10,0,0">
                                <Button x:Name="BtnAplicarTweaks" Content="Aplicar seleccionados" Style="{StaticResource AccentButton}" Height="46"/>
                            </StackPanel>
                        </Grid>
                    </TabItem>

                    <TabItem Header="Herramientas">
                        <Border Background="{DynamicResource CardBg}" CornerRadius="12" Padding="14" Margin="0,10,0,0">
                            <ScrollViewer VerticalScrollBarVisibility="Auto">
                                <WrapPanel x:Name="PanelHerramientas"/>
                            </ScrollViewer>
                        </Border>
                    </TabItem>
                </TabControl>

                <TextBlock Grid.Row="3" Text="Registro de actividad" FontWeight="Bold" Foreground="{DynamicResource TextPrimary}" Margin="0,14,0,6"/>
                <Border Grid.Row="4" Background="{DynamicResource CardBg}" CornerRadius="12" Padding="12">
                    <ScrollViewer x:Name="LogScroll" VerticalScrollBarVisibility="Auto">
                        <TextBlock x:Name="LogText" Foreground="#8CFFA0" FontFamily="Consolas" FontSize="12" TextWrapping="Wrap"/>
                    </ScrollViewer>
                </Border>
                
                <Border Grid.Row="5" CornerRadius="4" Margin="0,14,0,0" Background="{StaticResource RgbBrush}"/>
            </Grid>
        </Grid>
    </Border>
</Window>
'@

$window = [Windows.Markup.XamlReader]::Parse($xaml)

# ---------- 5. Referencias a controles ----------
$CustomTitleBar      = $window.FindName("CustomTitleBar")
$BtnCerrar           = $window.FindName("BtnCerrar")
$CmbCategoriaApps    = $window.FindName("CmbCategoriaApps")
$PanelListApps       = $window.FindName("PanelListApps")
$BtnInstalarApps     = $window.FindName("BtnInstalarApps")
$CmbCategoriaTweaks  = $window.FindName("CmbCategoriaTweaks")
$PanelListTweaks     = $window.FindName("PanelListTweaks")
$BtnAplicarTweaks    = $window.FindName("BtnAplicarTweaks")
$PanelHerramientas   = $window.FindName("PanelHerramientas")
$LogText             = $window.FindName("LogText")
$LogScroll           = $window.FindName("LogScroll")
$BtnTema             = $window.FindName("BtnTema")

# ---------- 6. Logica Barra Superior Arrastrable ----------
$CustomTitleBar.Add_MouseLeftButtonDown({
    $window.DragMove()
})

$BtnCerrar.Add_Click({
    $window.Close()
})

function Escribir-Log {
    param([string]$Texto)
    $marca = Get-Date -Format "HH:mm:ss"
    $LogText.Text += "[$marca] $Texto`n"
    $LogScroll.ScrollToBottom()
}

# ---------- 7. Logica Cambio de Tema ----------
$script:esOscuro = $true$BrushConv = [System.Windows.Media.BrushConverter]::new()

$BtnTema.Add_Click({
    $script:esOscuro = -not$script:esOscuro
    if ($script:esOscuro) {
        $window.Resources["WindowBg"]     = $BrushConv.ConvertFromString("#0D0D0F")
        $window.Resources["CardBg"]       = $BrushConv.ConvertFromString("#111114")
        $window.Resources["ButtonBg"]     = $BrushConv.ConvertFromString("#17171B")
        $window.Resources["TextPrimary"]  = $BrushConv.ConvertFromString("#F2F2F2")
        $window.Resources["TextSecondary"]= $BrushConv.ConvertFromString("#9A9AA2")
        $BtnTema.Content = "☀️ Modo Claro"
        $BtnCerrar.Foreground =$BrushConv.ConvertFromString("#F2F2F2")
        Escribir-Log "Tema cambiado a Modo Oscuro."
    } else {
        $window.Resources["WindowBg"]     = $BrushConv.ConvertFromString("#F3F4F6")
        $window.Resources["CardBg"]       = $BrushConv.ConvertFromString("#FFFFFF")
        $window.Resources["ButtonBg"]     = $BrushConv.ConvertFromString("#E5E7EB")
        $window.Resources["TextPrimary"]  = $BrushConv.ConvertFromString("#111827")
        $window.Resources["TextSecondary"]= $BrushConv.ConvertFromString("#4B5563")
        $BtnTema.Content = "🌙 Modo Oscuro"
        $BtnCerrar.Foreground =$BrushConv.ConvertFromString("#111827")
        Escribir-Log "Tema cambiado a Modo Claro."
    }
})

# ---------- 8. Pestana Apps ----------
foreach ($c in $CategoriasApps) { [void]$CmbCategoriaApps.Items.Add($c) }$CmbCategoriaApps.SelectedIndex = 0

function Refrescar-ListaApps {
    $PanelListApps.Children.Clear()
    $filtro =$CmbCategoriaApps.SelectedItem
    $apps = if ($filtro -eq "Todas") { $AppsDisponibles } else {$AppsDisponibles | Where-Object { $_.Categoria -eq$filtro } }
    foreach ($app in $apps) {$cb = New-Object System.Windows.Controls.CheckBox
        $cb.Content =$app.Nombre
        $cb.Tag = $app$cb.IsChecked = $checkedAppNames.Contains($app.Nombre)
        $cb.Add_Checked({ param($s,$e) [void]$checkedAppNames.Add($s.Tag.Nombre) })$cb.Add_Unchecked({ param($s,$e) [void]$checkedAppNames.Remove($s.Tag.Nombre) })
        [void]$PanelListApps.Children.Add($cb)
    }
}
$CmbCategoriaApps.Add_SelectionChanged({ Refrescar-ListaApps })
Refrescar-ListaApps

# ---------- 9. Pestana Tweaks ----------
foreach ($c in $CategoriasTweaks) { [void]$CmbCategoriaTweaks.Items.Add($c) }$CmbCategoriaTweaks.SelectedIndex = 0

function Refrescar-ListaTweaks {
    $PanelListTweaks.Children.Clear()
    $filtro =$CmbCategoriaTweaks.SelectedItem
    $tw = if ($filtro -eq "Todas") { $TweaksDisponibles } else {$TweaksDisponibles | Where-Object { $_.Categoria -eq$filtro } }
    foreach ($t in $tw) {$cb = New-Object System.Windows.Controls.CheckBox
        $cb.Content =$t.Nombre
        $cb.Tag = $t$cb.IsChecked = $checkedTweakNames.Contains($t.Nombre)
        $cb.Add_Checked({ param($s,$e) [void]$checkedTweakNames.Add($s.Tag.Nombre) })$cb.Add_Unchecked({ param($s,$e) [void]$checkedTweakNames.Remove($s.Tag.Nombre) })
        [void]$PanelListTweaks.Children.Add($cb)
    }
}
$CmbCategoriaTweaks.Add_SelectionChanged({ Refrescar-ListaTweaks })
Refrescar-ListaTweaks

$BtnAplicarTweaks.Add_Click({
    $seleccionados =$TweaksDisponibles | Where-Object { $checkedTweakNames.Contains($_.Nombre) }
    if ($seleccionados.Count -eq 0) { Escribir-Log "No seleccionaste ningun tweak."; return }
    foreach ($t in$seleccionados) {
        try { Invoke-Expression $t.Comando; Escribir-Log "Tweak aplicado: $($t.Nombre)" }
        catch { Escribir-Log "Error aplicando '$($t.Nombre)': $($_.Exception.Message)" }
    }
})

# ---------- 10. Mostrar ----------
Escribir-Log "Panel iniciado."
[void]$window.ShowDialog()