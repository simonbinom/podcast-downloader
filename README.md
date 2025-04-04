# Podcast-Downloader

Ein Bash-Script für macOS zum automatischen Herunterladen aller Episoden eines Podcasts über dessen RSS-Feed.

## Funktionen

- Herunterladung aller Audio-Dateien aus einem Podcast-RSS-Feed
- Verwendung der Episodentitel als Dateinamen
- Optionale Begrenzung der Anzahl heruntergeladener Episoden
- Wählbares Zielverzeichnis für die Downloads
- Automatische Erkennung der Dateitypen

## Voraussetzungen

Das Script benötigt folgende Tools:

- `bash` (vorinstalliert auf macOS)
- `curl` (vorinstalliert auf macOS)
- `xmllint` (Teil des libxml2-Pakets)

### Installation der Abhängigkeiten

Falls `xmllint` noch nicht installiert ist, kann es über Homebrew installiert werden:

```bash
brew install libxml2
```

## Installation

1. Klone dieses Repository oder lade die Datei `podcast-downloader.sh` herunter
2. Mache das Script ausführbar:

```bash
chmod +x podcast-downloader.sh
```

## Verwendung

### Grundlegende Syntax

```bash
./podcast-downloader.sh -u RSS_URL [OPTIONEN]
```

### Optionen

- `-u, --url URL`: Die URL des Podcast-RSS-Feeds (erforderlich)
- `-d, --dir VERZEICHNIS`: Zielverzeichnis für die Downloads (Standard: aktuelles Verzeichnis)
- `-l, --limit ANZAHL`: Maximale Anzahl der herunterzuladenden Folgen (Standard: alle)
- `-h, --help`: Zeigt die Hilfe-Seite an

### Beispiele

Alle Episoden eines Podcasts herunterladen:
```bash
./podcast-downloader.sh -u https://beispiel.com/podcast.rss
```

Nur die neuesten 5 Episoden herunterladen:
```bash
./podcast-downloader.sh -u https://beispiel.com/podcast.rss -l 5
```

In ein bestimmtes Verzeichnis herunterladen:
```bash
./podcast-downloader.sh -u https://beispiel.com/podcast.rss -d ~/Podcasts
```

Kombinieren mehrerer Optionen:
```bash
./podcast-downloader.sh -u https://beispiel.com/podcast.rss -d ~/Podcasts/MeinPodcast -l 10
```

## Wie es funktioniert

1. Das Script lädt den RSS-Feed herunter
2. Es extrahiert alle Episoden-Titel und Audio-URLs mit xmllint
3. Die Dateien werden der Reihe nach mit curl heruntergeladen
4. Die Episodentitel werden als Dateinamen verwendet (mit Bereinigung ungültiger Zeichen)

## Fehlerbehebung

Falls beim Herunterladen Probleme auftreten:

- Stelle sicher, dass die RSS-Feed-URL korrekt ist
- Überprüfe, ob das Zielverzeichnis existiert und beschreibbar ist
- Bei Problemen mit der Extraktion der Episoden-URLs kann der Feed ein ungewöhnliches Format haben

## Beitragen

Beiträge zum Projekt sind willkommen! Bitte erstelle einen Fork des Repositories und reiche deine Änderungen als Pull Request ein.

## Lizenz

Dieses Projekt ist unter der MIT-Lizenz veröffentlicht. Siehe [LICENSE](LICENSE) für Details.
