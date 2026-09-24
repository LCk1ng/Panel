# Panel de Administracion - Windows Toolkit

Panel grafico en PowerShell (WinForms) para gestionar tareas comunes de
administracion en Windows: instalar apps via `winget`, aplicar tweaks del
sistema, lanzar herramientas de terceros de confianza, e instalar tus
propios ejecutables locales.

## Caracteristicas

- **Auto-elevacion**: se ejecuta automaticamente como Administrador.
- **Instalar Apps**: catalogo de programas via `winget`, organizado por
  categoria (Navegadores, Multimedia, Utilidades, Desarrollo, Comunicacion).
- **Tweaks del Sistema**: ajustes de registro/configuracion reversibles,
  organizados por categoria (Personalizacion, Rendimiento, Privacidad).
- **Herramientas**: botones para scripts remotos curados (ej. Chris Titus
  Tech WinUtil, Winhance). Puedes agregar los tuyos propios.
- **Instaladores Locales**: coloca tus `.exe`/`.msi` en la carpeta
  `Instaladores/` (o usa el boton "Agregar instalador...") y se genera un
  boton por cada uno automaticamente.
- **Registro de actividad**: log en vivo de todo lo que se ejecuta.

## Requisitos

- Windows 10/11
- PowerShell 5.1 o superior (incluido en Windows)
- [winget](https://learn.microsoft.com/windows/package-manager/winget/) para
  la pestana de instalacion de apps (viene por defecto en Windows actualizado)

## Uso

1. Clona o descarga este repositorio.
2. (Opcional) Copia tus propios instaladores `.exe`/`.msi` dentro de la
   carpeta `Instaladores/`.
3. Haz clic derecho sobre `PanelWindows.ps1` → **Ejecutar con PowerShell**.
   - Si es la primera vez que ejecutas scripts locales, puede que necesites
     desbloquear el archivo (si lo descargaste de internet) y permitir la
     ejecucion de scripts:

     ```powershell
     Unblock-File -Path .\PanelWindows.ps1
     Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
     ```

4. Acepta el aviso de Control de Cuentas de Usuario (UAC); el panel se abre
   con privilegios de administrador.

## Agregar tus propias herramientas remotas

Dentro de `PanelWindows.ps1`, edita el arreglo `$HerramientasRemotas` y
agrega una linea con el nombre y el comando (revisa siempre la fuente antes
de agregar un script de terceros):

```powershell
$HerramientasRemotas = @(
    [PSCustomObject]@{ Nombre = "Chris Titus Tech - WinUtil";  Comando = 'irm https://christitus.com/win | iex' }
    [PSCustomObject]@{ Nombre = "Mi Script Personal"; Comando = 'irm "https://tu-url-aqui" | iex' }
)
```

## Nota sobre antivirus

Es normal que Windows Security / Microsoft Defender marque alguno de estos
scripts remotos como sospechoso: la deteccion heuristica se dispara por el
patron "descargar y ejecutar codigo con privilegios de administrador", no
necesariamente porque el contenido sea malicioso. Verifica siempre la fuente
oficial del script antes de confiar en el.

## Licencia

Este proyecto es tuyo para modificar y compartir como prefieras. Si incluyes
codigo o listas de terceros (por ejemplo, IDs de `winget` inspirados en
proyectos como [WinUtil](https://github.com/ChrisTitusTech/winutil)), revisa
sus licencias respectivas.
