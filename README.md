**Project README**

**Disclaimer / Exoneration of Liability (Technical)**

- **English (Technical):** These scripts are provided "as-is" to automate Debian release upgrades. They perform system-level operations (editing apt sources, package upgrades, service restarts, and optional package installs) that can cause data loss, downtime, or configuration changes. Use them only after you have:
  - reviewed and understood the script contents,
  - tested the procedure in a non-production environment, and
  - created full backups (system image or snapshots, `/etc`, and package selections).

  You execute these scripts at your own risk. The author and contributors expressly disclaim liability for any damages, data loss, or service interruption resulting from their use. There is no warranty—express or implied—of fitness for a particular purpose or merchantability. If you require guaranteed outcomes, perform the upgrade using your standard maintenance procedures or consult a qualified system administrator.

  Technical notes:
  - The scripts include a release-codename validation to reduce the risk of jumping releases, but they cannot cover every custom repository or third-party packaging scenario.
  - Review and, if necessary, adapt entries in `/etc/apt/sources.list` and `/etc/apt/sources.list.d/` for vendor repositories (Docker, etc.), adding `signed-by` keyrings when required.
  - Rollbacks are not automated. Ensure snapshots or reliable backups (LVM, filesystem or VM snapshots, or full disk images) are available before proceeding.

- **Español (Técnico):** Estos scripts se proporcionan "tal cual" para automatizar actualizaciones de release de Debian. Ejecutan operaciones a nivel de sistema (editar fuentes de apt, actualizar paquetes, reiniciar servicios e instalaciones opcionales) que pueden provocar pérdida de datos, indisponibilidad o cambios de configuración. Úsalos sólo después de:
  - revisar y comprender el contenido de los scripts,
  - probar el procedimiento en un entorno no productivo, y
  - realizar copias de seguridad completas (imagen/snapshots del sistema, `/etc` y selección de paquetes).

  Ejecutas estos scripts bajo tu propia responsabilidad. El autor y los colaboradores renuncian expresamente a cualquier responsabilidad por daños, pérdida de datos o interrupciones de servicio derivadas de su uso. No existe garantía—explícita ni implícita—sobre idoneidad para un propósito concreto o comerciabilidad. Si necesitas resultados garantizados, realiza la actualización mediante tus procedimientos de mantenimiento habituales o consulta a un administrador de sistemas cualificado.

  Notas técnicas:
  - Los scripts incluyen una validación del nombre de la release para reducir el riesgo de saltos de versión, pero no pueden cubrir todos los escenarios con repositorios personalizados o paquetes de terceros.
  - Revisa y adapta, si es necesario, las entradas en `/etc/apt/sources.list` y `/etc/apt/sources.list.d/` para repositorios de proveedores (Docker, etc.), añadiendo keyrings `signed-by` cuando correspondan.
  - No hay un mecanismo de reversión automatizado. Asegúrate de disponer de snapshots o copias fiables (LVM, snapshots de sistema de archivos, snapshots de VM o imágenes completas) antes de proceder.

**Overview / Resumen**
- **English:** This repository contains shell scripts to upgrade Debian systems step-by-step from 10 (Buster) → 11 (Bullseye) → 12 (Bookworm) → 13 (Trixie). It also includes notes about a recent fix applied to the scripts.
- **Español:** Este repositorio contiene scripts shell para actualizar Debian paso a paso de 10 (Buster) → 11 (Bullseye) → 12 (Bookworm) → 13 (Trixie). También incluye notas sobre una corrección reciente aplicada a los scripts.

**Files**
- `upgrade_10_to_11.sh` — Upgrade script for 10 → 11.
- `upgrade_11_to_12.sh` — Upgrade script for 11 → 12.
- `upgrade_12_to_13.sh` — Upgrade script for 12 → 13.

**Download scripts with curl / Descargar los scripts con curl**

- **English:** If you want to fetch the scripts directly with `curl` from this repository (example using GitHub raw URL), replace `<USER>` and `<REPO>` and run:

```bash
# Download only the 10 -> 11 upgrade script
curl -fsSL -o upgrade_10_to_11.sh https://raw.githubusercontent.com/tomasecastro/Update-Debian-10-a-13/main/upgrade_10_to_11.sh
chmod +x upgrade_10_to_11.sh
```

```bash
# Download only the 11 -> 12 upgrade script
curl -fsSL -o upgrade_11_to_12.sh https://raw.githubusercontent.com/tomasecastro/Update-Debian-10-a-13/main/upgrade_11_to_12.sh
chmod +x upgrade_11_to_12.sh
```

```bash
# Download only the 12 -> 13 upgrade script
curl -fsSL -o upgrade_12_to_13.sh https://raw.githubusercontent.com/tomasecastro/Update-Debian-10-a-13/main/upgrade_12_to_13.sh
chmod +x upgrade_12_to_13.sh
```

Verify the downloaded script and run it as root. The scripts include a built-in check that ensures you are on the correct Debian release before attempting the upgrade, so they will abort if you try to jump versions (for example, running the 12→13 script on a Debian 10 host).

- **Español:** Si prefieres descargar los scripts con `curl` (ejemplo usando la URL raw de GitHub), sustituye `<USER>` y `<REPO>` y ejecuta:

```bash
# Descargar solo el script 10 -> 11
curl -fsSL -o upgrade_10_to_11.sh https://raw.githubusercontent.com/tomasecastro/Update-Debian-10-a-13/main/upgrade_10_to_11.sh
chmod +x upgrade_10_to_11.sh
```

```bash
# Descargar solo el script 11 -> 12
curl -fsSL -o upgrade_11_to_12.sh https://raw.githubusercontent.com/tomasecastro/Update-Debian-10-a-13/main/upgrade_11_to_12.sh
chmod +x upgrade_11_to_12.sh
```

```bash
# Descargar solo el script 12 -> 13
curl -fsSL -o upgrade_12_to_13.sh https://raw.githubusercontent.com/tomasecastro/Update-Debian-10-a-13/main/upgrade_12_to_13.sh
chmod +x upgrade_12_to_13.sh
```

Comprueba el script descargado y ejecútalo como root. Los scripts incluyen una comprobación que valida la release actual de Debian antes de continuar y abortarán si intentas saltar versiones (por ejemplo, ejecutar el script 12→13 en un equipo con Debian 10).

**How to use / Cómo usar**

- **English:**
  - Prepare: ensure you have backups and a maintenance window. Run the script on the machine you want to upgrade (not on a production server without testing).
  - Basic run (example for 10→11):

```bash
sudo bash ./upgrade_10_to_11.sh --apply-upgrade
```

  - If you prefer to run as root:

```bash
sudo -i
bash ./upgrade_10_to_11.sh --apply-upgrade
```

  - From Windows using WSL or SSH:

```powershell
# Using WSL
wsl -d ubuntu -- bash -lc "sudo bash /mnt/c/path/to/repo/upgrade_10_to_11.sh --apply-upgrade"

# Or SSH into the Debian host and run the same bash command
ssh root@debian-host 'bash -s' < ./upgrade_10_to_11.sh --apply-upgrade
```

- **Español:**
  - Preparación: asegúrate de disponer de copias de seguridad y una ventana de mantenimiento. Ejecuta el script en la máquina objetivo (no lo hagas en producción sin probarlo primero).
  - Ejemplo de ejecución (10→11):

```bash
sudo bash ./upgrade_10_to_11.sh --apply-upgrade
```

  - Desde Windows con WSL o SSH:

```powershell
# Usando WSL
wsl -d ubuntu -- bash -lc "sudo bash /mnt/c/path/to/repo/upgrade_10_to_11.sh --apply-upgrade"

# O conectar por SSH al host Debian y ejecutar el script
ssh root@debian-host 'bash -s' < ./upgrade_10_to_11.sh --apply-upgrade
```

**Recent change / Cambio reciente**

- **Issue:** Running the scripts produced this error when the script attempted a minimal upgrade:

```
E: No tiene sentido la opción de línea de órdenes --without-new-pkgs combinada con las otras opciones
```

- **Cause:** The scripts used `apt full-upgrade --without-new-pkgs` which mixes incompatible options.

- **Fix applied:** Replaced the problematic step in all three scripts:

```
- apt full-upgrade --without-new-pkgs
+ apt-get upgrade -y
```

This uses `apt-get upgrade -y` to perform a minimal upgrade (it upgrades installed packages without installing new packages) and avoids the incompatible option combination.

**What to do now / Qué hacer ahora**

- Re-run the script you need. Example (10→11):

```bash
sudo bash ./upgrade_10_to_11.sh --apply-upgrade
```

- If you get another error, please paste the complete output here and it will be adjusted.

**Troubleshooting tips / Consejos de resolución**

- If `apt` prompts about held or broken packages, inspect `apt list --upgradable` and `apt-mark showhold`, and resolve holds before continuing.
- If network or repository errors show up, check `/etc/apt/sources.list` and files under `/etc/apt/sources.list.d/`.
- If third-party repositories (Docker, Microsoft, etc.) are required, consider adding their signed keyrings and `signed-by` entries before running the upgrade.

**Suggested optional improvements / Mejora opcional (recomendada)**

- Save apt logs to the backup directory created by the scripts (recommended).
- Add automatic adjustments for third-party repositories: add keyrings and `signed-by` attributes.
- Add a post-upgrade verification step: kernel, services, Docker, PHP extensions, etc.

**Example excerpt (script output) / Ejemplo de salida del script**

```
root@server:# bash upgrade_10_to_11.sh --apply-upgrade
[+] Backup dir: /root/upgrade-bbuster-to-bullseye-20251122-033227
[+] Backing up /etc
[+] Saving package selections
[+] Available on /: 12811008 KB (12 GB)
Proceed to change apt sources from buster to bullseye and upgrade? [y/N]: y
[+] Replacing 'buster' with 'bullseye' in apt sources
[+] Updating indexes
[+] Normalizing security repository entries (-> bullseye-security)
Obj:1 http://security.debian.org/debian-security bullseye-security InRelease
Obj:2 http://ftp.us.debian.org/debian bullseye InRelease
Obj:3 http://ftp.us.debian.org/debian bullseye-updates InRelease
Leyendo lista de paquetes... Hecho
Creando árbol de dependencias
Leyendo la información de estado... Hecho
Se pueden actualizar 508 paquetes. Ejecute «apt list --upgradable» para verlos.
[+] Performing minimal upgrade (without new packages)
```

**If things still fail / Si sigue fallando**

- Paste the full output here. Include any lines that indicate which apt command caused the problem.
- Optionally rerun the failed part manually to get more detail, for example:

```bash
apt-get update; apt-get upgrade -y
```

**Contact / Soporte**
- If you want, I can add:
  - apt log capturing to the backup dir,
  - automated handling for common third-party repos,
  - a post-upgrade check script.

--
Generated instructions: English + Español. If you want the README expanded (more Git examples, branching, commit workflows), tell me which topics to include.
