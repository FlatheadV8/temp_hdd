# temp_hdd
Dieses Skript habe ich als erstes von hier runtergeladen:
https://github.com/cytopia/freebsd-tools/blob/master/hdd-temp.sh
und dann für meine Zwecke noch etwas erweitert.

Es war in seiner Ursprünglichen Form für Linux geschriben, funktioniert aber auch auf FreeBSD.
Ich setzte diese erweiteret Version nur auf FreeBSD ein, sie sollte aber auch auf Linux funktionieren.

Für beide Version (das Original und meine erweiteret Version) benötige ein installiertes "smartctl"!

Dieses Skript zeigt die Temperatur aller Festplatten im System an und ggf. durch farbliche Kennung auch fehlerhafte Festplatten.

die Temperatur kann 3 Farben annehmen: grün, gelb und rot

Darüber hinaus kann die Bezeichnung noch die Farbe "magenta" oder "rot" annehmen.

Die Farbe Magenta wird verwendet, wenn das Betriebssystem auf der Platte entdeckt aber SMART keinen bedrohlichen Fehler findet.
In soeinem Fall liegt oft ein Wackelkontakt vor und man sollte die Verbindungen überprüfen und ggf. das SATA-Kabel tauschen.

Die Farbe "rot" wird verwendet, wenn SMART bedrohliche Fehler findet.
In dem Fall sollte die Festplatte so schnell wie möglich ausgetauscht werden.
