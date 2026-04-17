# PSVR2 & VR Integration - Virtual Art Museum

## AI Summary (Kurzzusammenfassung für AI)
- **Startup System**: `startup.tscn` und `startup.gd` hinzugefügt, um zwischen 2D Desktop- und VR-Modus zu wählen (analog zum Labyrinth Projekt). Setzt VSync, FPS Limit und OpenXR Initialisierung.
- **Project Settings**: `project.godot` aktualisiert, sodass `startup.tscn` beim Start lädt. `[xr]` Sektion hinzugefügt, jedoch `openxr/enabled=false` belassen, da die Initialisierung dynamisch via GDScript erfolgt.
- **Settings Manager**: Parameter `vr_scale` implementiert. Initialwert ist `1.0`. Evaluiert bei Laufzeit, ob `is_vr == true` und wendet den Faktor auf `vp.scaling_3d_scale` an.
- **UI Settings**: VR Render Scale Slider (0.5x - 2.0x) in `SettingsUI.gd` eingefügt (unter Graphics).
- **Player Controller**: `Player.gd` modifiziert. Fügt dynamisch `XROrigin3D` und `XRCamera3D` hinzu, wenn `SettingsManager.is_vr == true`. Maus-Pitch auf Headset übertragen, Bewegungsvektor an die Blickrichtung des Headsets angepasst (`h_rot`). Raycast für Interaktion hängt sich an die aktive Kamera.

---

## Benutzerdokumentation

### Einführung
Dieses Dokument beschreibt die Nutzung des neu implementierten **PSVR2 / SteamVR** Modus im Virtual Art Museum. Durch die Integration können Sie das Museum in voller stereoskopischer 3D-Ansicht betreten und immersiv erkunden.

### Wie starte ich den VR-Modus?
1. **Vorbereitung:**
   - Schalten Sie Ihre PlayStation VR2 (oder ein anderes kompatibles Headset) an.
   - Starten Sie **SteamVR** (die PlayStation VR2 App, sofern sie installiert ist, wird auf dem PC automatisch als Bridge dienen).
   - Vergewissern Sie sich, dass SteamVR Ihr Headset und die Controller korrekt erkennt und Status "Bereit" anzeigt.
2. **Museum starten:**
   - Wenn Sie das Godot-Projekt starten, öffnet sich nun zuerst ein **Startmenü** (`startup.tscn`).
   - Wählen Sie den Punkt **"Play 3D VR (PSVR2 / SteamVR)"**.
3. **VR Umgebung:**
   - Das Museum wird in Ihr Headset geladen.
   - Die Bewegungssteuerung (WASD / Pfeiltasten) bleibt erhalten, richtet sich jedoch nun nach der Blickrichtung Ihres Headsets aus, sodass Sie intuitiv in die Richtung laufen können, in die Sie schauen.

### Den VR Render Faktor einstellen
VR-Anwendungen können auf einigen Grafikkarten sehr rechenintensiv sein. Wir haben **1.0x Render Scale** als Standard gesetzt, damit die Performance von nativ berechneter VR sofort mit den Einstellungen skaliert.
Sollten Sie jedoch Performance-Einbrüche (Stottern / Ruckeln) bemerken oder im Gegenteil ein schärferes Bild wünschen:

1. Rufen Sie im aktiven Projekt das **Einstellungsmenü** auf (bewegen Sie die Maus in der Desktop-Vorschau oder drücken Sie "Esc", um das UI sichtbar zu machen).
2. Suchen Sie nach dem Regler **"VR Render Scale"**.
3. Sie können den Schieberegler von **0.50x bis 2.00x** einstellen.
    - **< 1.0 (z.B. 0.8)**: Das Bild wird leicht unschärfer (verkleinerte Auflösung), dafür steigt die Bildrate und Performance erheblich.
    - **1.0**: Native Auflösung Ihres Headsets / der eingestellten VR Render Engine.
    - **> 1.0 (z.B. 1.2)**: "Supersampling". Die Grafikkarte berechnet das Bild noch größer, was feine Linien glättet, benötigt aber stark Hardware-Ressourcen.

### Troubleshooting (Fehlerbehebung)
* **Klick auf "Play 3D VR" bewirkt nichts oder gibt einen "OpenXR initialization failed" Fehler:**
  Dies bedeutet, dass die Kommunikation zwischen Engine und SteamVR fehlgeschlagen ist. Stellen Sie sicher, dass das SteamVR-Fenster auf Ihrem Desktop geöffnet ist und das Headset als "Grün/Bereit" markiert wird. 
* **Das Bild im Museum zittert beim Umsehen (Z-Fighting/Lag):**
  Reduzieren Sie im Settings-Menü den "VR Render Scale" oder drehen Sie zusätzliche Effekte wie SDFGI (Software Raytracing) ab. In der VR Umgebung werden Bilder für jedes Auge einzeln gerendert, was die doppelte Leistung benötigt.
* **Mausbewegungen stören das VR Tracking:**
  Das Drehen mit der Maus ist weiterhin für Debugging/Testing freigeschaltet, übersteuert aber das reine Headtracking nicht, sondern dreht die Basisfigur mit. Zum sauberen Erleben in VR bitte Maus/Tastatur zum Steuern, aber nicht für schnelle Kopfdrehungen verwenden.
