# DemoGdotMuseum - Architektur & Projektdokumentation

Dieses Dokument dient als technischer Leitfaden und Übersicht für das `DemoGdotMuseum` Projekt. Es ist ein dynamisch und prozedural generiertes 3D-Museum in Godot 4, das VR-Unterstützung (inklusive PSVR2), Echtzeit-Grafiksettings und maßgeschneiderte Umgebungen bietet.

## 1. Kern-Features
- **Prozedurale Generierung**: Fast die gesamte Architektur (Wände, Säulen, Dächer, Außenanlagen) wird zur Laufzeit über GDScript generiert. Dadurch bleibt das Projekt extrem leichtgewichtig.
- **Hybrider Startmodus**: Das Museum kann wahlweise im klassischen Desktop-Modus (Maus + Tastatur) oder im immersiven 3D VR-Modus (OpenXR/SteamVR) direkt über ein Startmenü gestartet werden.
- **Dynamisches Settings-System**: Über ein In-Game Menü lassen sich Auflösung, V-Sync, Raytracing (SDFGI), Multisample Anti-Aliasing (MSAA) und sogar die gesamte Lichtstimmung des Museums in Echtzeit verändern.
- **Interaktiver "Drop"-Moment**: Ein Teleporter an der zentralen Obsidiansäule entführt den Spieler in einer rasanten Schlauchboot-Animation in ein "Universe Room" (Weltraum-Level).

## 2. Code-Architektur & Wichtige Skripte

### 2.1 `startup.gd` & `startup.tscn`
Das Einstiegsfenster der Applikation. Bevor das eigentliche 3D-Szenario instanziiert wird, entscheidet diese Szene, ob der VR-Modus initialisiert (OpenXR Binding) oder der normale Bildschirm genutzt wird. Nach der Auswahl wechselt die Szene fließend in die `main.tscn`.

### 2.2 `MuseumGenerator.gd`
Das Herzstück des Repositories. Dieses Skript ist hunderte Zeilen lang und zuständig für:
- **`generate_exterior()`**: Baut die Vorplätze, den großen Wasser-Pool, die massive Portico-Eingangshalle (die von 4 quadratförmigen dicken Obsidian-Blöcken getragen wird) und die Dachstruktur auf.
- **`generate_hub()`**: Generiert den sternförmigen Innenraum mit detaillierter Marmor- und Goldbodengestaltung.
- **`build_corridor(artist)`**: Liest Metadaten der jeweiligen "Künstler" (Knoten für Picasse, Monero, etc.) aus, liest deren JPG/PNG-Bilder aus dem Dateisystem und platziert Wände, Teppiche sowie Spotlights für die Gemälde.
- **`place_pillar()`**: Ergänzt die Freiräume zwischen den Galerien mit riesigen interaktiven leuchtenden Obsidian-Vitrinen.
- **`trigger_drop()`**: Führt die rasante Teleport-Animation aus dem Hub hinunter zum Universe Room durch.

### 2.3 `Chandelier.gd`
Ein separates Skript für ein in jedem Gang platziertes prozedurales Deko-Element. Es instanziiert Ringe, Halterungen, Kerzen und entsprechende omnidirektionale Lichter, um die dunklen Gänge majestätischer wirken zu lassen.

### 2.4 `SettingsManager.gd` (Autoload / Singleton)
Verwaltet globale Variablen des Spiels und kommuniziert direkt mit dem Rendering-Server und der OS-Umgebung.
- Handhabt das saubere Beenden per `NOTIFICATION_WM_CLOSE_REQUEST`.
- Regelt das Skalieren der VR-Render-Auflösung, um ggf. auf leistungsschwächeren oder extrem hochauflösenden HMDs (wie der PSVR2) die Performance zu sichern.

### 2.5 `Player.tscn` & `Player.gd`
Das Ego-Perspektiven-Rig des Museums.
Integrierte Kollisionsabfragen und Bewegungslogiken. Im VR-Modus werden die Tracker-Daten des Headsets und Controllers übermittelt und entsprechend berücksichtigt, während im Desktop-Modus `Input.is_action_pressed` (WASD) ausgelesen wird.

## 3. Workflow & Erweiterungen

### Neue Bilder hinzufügen
Das System greift dynamisch auf das `artists/`-Verzeichnis zurück. Um einen neuen Flügel anzubauen:
1. Erstelle einen Unterordner in `artists/` (z.B. `artists/vangoth/`).
2. Füge dem Code-Array in `MuseumGenerator.gd` das entsprechende ID/Metadaten-Dictionary hinzu.
3. Lege die entsprechenden JPG/PNG Bilder dort ab. Der Code platziert eigenständig die Bilderahmen und positioniert die Spots im neu erzeugten Flur.

### Git Ignore
Achtung: Aufgrund der Größenlimitierung bei Git-Plattformen sind große Dateien, Videos (z.B. der `videos/`-Ordner) und Raw-Image Binaries (`*.jpg`, `*.png`, `*.webp`) vorsätzlich aus dem Remote-Git ausgeschlossen. Das Repository umfasst im Wesentlichen die pure Logik und Szeneriestruktur.
