# temp_hdd
Dieses Skript habe ich als erstes von hier runtergeladen:
https://github.com/cytopia/freebsd-tools/blob/master/hdd-temp.sh
und dann für meine Zwecke noch etwas erweitert.

Dieses Skript zeigt die Temperatur aller Festplatten im System an und ggf. durch farbliche Kennung auch fehlerhafte Festplatten.

die Temperatur kann 3 Farben annehmen: grün, gelb und rot

Darüber hinaus kann die Bezeichnung noch die Farbe "magenta" oder "rot" annehmen.

Die Farbe Magenta wird verwendet, wenn das Betriebssystem auf der Platte entdeckt aber SMART keinen bedrohlichen Fehler findet.
In soeinem Fall liegt oft ein Wackelkontakt vor und man sollte die Verbindungen überprüfen und ggf. das SATA-Kabel tauschen.

Die Farbe "rot" wird verwendet, wenn SMART bedrohliche Fehler findet.
In dem Fall sollte die Festplatte so schnell wie möglich ausgetauscht werden.
