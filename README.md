Attempting to perform the InitializeDefaultDrives operation on the 'FileSystem' provider failed.
# TeamSpeak 3 Server Monitor

Ein POSIX-Shell-Script zur Überwachung und Steuerung eines TeamSpeak-3-Servers. Der Cron-Modus prüft den Server und startet ihn erneut, wenn er nicht mehr läuft. Bei einem normalen Lauf ohne Fehler wird kein Logeintrag erzeugt.

## Installation (Deutsch)

### Voraussetzungen

- Linux und ein Konto `teamspeak`
- Der Server liegt unter `/home/teamspeak/teamspeak/teamspeak3-server`
- Das Startscript `ts3server_startscript.sh` ist dort ausführbar
- `logrotate` ist installiert, damit die Logdatei rotiert wird

### Script auf den Server kopieren

Kopiere `ts3server_monitor.sh` von Windows aus per SCP. Ersetze `SERVER` durch den Hostnamen oder die IP-Adresse deines Servers:

```powershell
scp .\ts3server_monitor.sh teamspeak@SERVER:/home/teamspeak/ts3server_monitor.sh
```

Melde dich anschließend als `teamspeak` per SSH an und setze die Berechtigungen:

```sh
chmod 700 /home/teamspeak/ts3server_monitor.sh
chmod u+x /home/teamspeak/teamspeak/teamspeak3-server/ts3server_startscript.sh
```

Der zweite Befehl ist nur nötig, wenn das TeamSpeak-Startscript noch nicht ausführbar ist.

### Manuell prüfen

```sh
/home/teamspeak/ts3server_monitor.sh status
/home/teamspeak/ts3server_monitor.sh check
```

`start`, `stop` und `status` werden an das TeamSpeak-Startscript weitergegeben. Ohne Argument oder mit `check` prüft das Script den Server und startet ihn bei Bedarf.

### Cronjob einrichten

Führe als Benutzer `teamspeak` aus:

```sh
crontab -e
```

Füge diese Zeile ein, um den Server einmal pro Minute zu prüfen:

```cron
* * * * * /home/teamspeak/ts3server_monitor.sh check >> /home/teamspeak/ts3server-monitor.log 2>&1
```

Prüfe den gespeicherten Eintrag mit:

```sh
crontab -l
```

Bei einem normalen Lauf bleibt die Logdatei unverändert. Fehler und Startversuche werden protokolliert. Beim ersten `check` erzeugt das Script automatisch `/home/teamspeak/ts3server-monitor-logrotate.conf` und rotiert die Logdatei mit `logrotate`. Es behält höchstens fünf Dateien insgesamt (die aktuelle Datei und vier Archive); Dateien ab 1 MB werden rotiert. Die Rotation wird bei jedem Cronlauf geprüft. `logrotate` muss dafür installiert und für den Benutzer `teamspeak` ausführbar sein.

Logdatei: `/home/teamspeak/ts3server-monitor.log`  
Automatisch erzeugte Konfiguration: `/home/teamspeak/ts3server-monitor-logrotate.conf`  
Gespeicherte PID: `/home/teamspeak/.ts3server_monitor.pid`

## Installation (English)

### Requirements

- Linux and a `teamspeak` user account
- The server is installed at `/home/teamspeak/teamspeak/teamspeak3-server`
- The `ts3server_startscript.sh` startup script is executable in that directory
- `logrotate` is installed to rotate the log file

### Copy the script to the server

From Windows, copy `ts3server_monitor.sh` to the server with SCP. Replace `SERVER` with the server hostname or IP address:

```powershell
scp .\ts3server_monitor.sh teamspeak@SERVER:/home/teamspeak/ts3server_monitor.sh
```

Then connect over SSH as `teamspeak` and set the permissions:

```sh
chmod 700 /home/teamspeak/ts3server_monitor.sh
chmod u+x /home/teamspeak/teamspeak/teamspeak3-server/ts3server_startscript.sh
```

The second command is only needed if the TeamSpeak startup script is not already executable.

### Run a manual check

```sh
/home/teamspeak/ts3server_monitor.sh status
/home/teamspeak/ts3server_monitor.sh check
```

`start`, `stop`, and `status` are passed to the TeamSpeak startup script. With no argument, or with `check`, the monitor checks the server and starts it if it is down.

### Set up the cron job

Run this as the `teamspeak` user:

```sh
crontab -e
```

Add this line to check the server once per minute:

```cron
* * * * * /home/teamspeak/ts3server_monitor.sh check >> /home/teamspeak/ts3server-monitor.log 2>&1
```

Verify the saved entry with:

```sh
crontab -l
```

The log file stays unchanged during a normal check. Errors and restart attempts are logged. On its first `check`, the script automatically creates `/home/teamspeak/ts3server-monitor-logrotate.conf` and runs `logrotate` for the log file. It keeps at most five files total (the active log and four archives); files are rotated at 1 MB. Rotation is checked on every cron run. `logrotate` must be installed and executable by the `teamspeak` user.

Log file: `/home/teamspeak/ts3server-monitor.log`  
Automatically created configuration: `/home/teamspeak/ts3server-monitor-logrotate.conf`  
Saved PID: `/home/teamspeak/.ts3server_monitor.pid`

