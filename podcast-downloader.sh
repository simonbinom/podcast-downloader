#!/bin/bash

# Podcast-Downloader für macOS
# Dieses Script lädt alle Podcast-Episoden aus einem RSS-Feed herunter

# Prüfen, ob curl installiert ist
if ! command -v curl &> /dev/null; then
    echo "Error: curl ist nicht installiert. Bitte installiere curl."
    exit 1
fi

# Prüfen, ob xmllint installiert ist
if ! command -v xmllint &> /dev/null; then
    echo "Error: xmllint ist nicht installiert. Es ist Teil des libxml2-Pakets."
    echo "Installiere es mit: brew install libxml2"
    exit 1
fi

# Funktion zur Anzeige der Hilfe
show_help() {
    echo "Podcast-Downloader für macOS"
    echo "Verwendung: $0 [OPTIONEN]"
    echo ""
    echo "Optionen:"
    echo "  -u, --url URL       RSS-Feed-URL des Podcasts (erforderlich)"
    echo "  -d, --dir VERZEICHNIS  Zielverzeichnis für die Downloads (Standard: aktuelles Verzeichnis)"
    echo "  -l, --limit ANZAHL  Maximale Anzahl der herunterzuladenden Folgen (Standard: alle)"
    echo "  -h, --help          Diese Hilfemeldung anzeigen"
    echo ""
    echo "Beispiel: $0 -u https://beispiel.com/podcast.rss -d ~/Podcasts -l 5"
    exit 0
}

# Standardwerte
DOWNLOAD_DIR="."
LIMIT=0  # 0 bedeutet keine Begrenzung

# Parameter verarbeiten
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -u|--url)
            RSS_URL="$2"
            shift
            shift
            ;;
        -d|--dir)
            DOWNLOAD_DIR="$2"
            shift
            shift
            ;;
        -l|--limit)
            LIMIT="$2"
            shift
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unbekannte Option: $1"
            show_help
            ;;
    esac
done

# Prüfen, ob die URL angegeben wurde
if [ -z "$RSS_URL" ]; then
    echo "Error: Bitte gib eine RSS-Feed-URL an."
    show_help
fi

# Prüfen, ob das Zielverzeichnis existiert, wenn nicht, erstellen
if [ ! -d "$DOWNLOAD_DIR" ]; then
    mkdir -p "$DOWNLOAD_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Konnte Zielverzeichnis nicht erstellen: $DOWNLOAD_DIR"
        exit 1
    fi
fi

echo "Lade RSS-Feed herunter und verarbeite ihn..."

# RSS-Feed herunterladen und die Medien-URLs extrahieren
# Mit xmllint: wir extrahieren die enclosure-URLs mit dem Attribut type, das "audio" enthält
TEMP_RSS_FILE=$(mktemp)
curl -s "$RSS_URL" > "$TEMP_RSS_FILE"

# Extrahiere Episodentitel und Audio-URLs mit xmllint
echo "Extrahiere Podcast-Episoden..."

# Verwende xmllint, um alle Audio-Enclosures zu finden
EPISODE_DATA=$(xmllint --xpath '//item[enclosure[contains(@type, "audio")]]' "$TEMP_RSS_FILE" 2>/dev/null)

# Wenn keine Episoden gefunden wurden, versuche es ohne Typfilter
if [ -z "$EPISODE_DATA" ]; then
    EPISODE_DATA=$(xmllint --xpath '//item[enclosure]' "$TEMP_RSS_FILE" 2>/dev/null)
    if [ -z "$EPISODE_DATA" ]; then
        echo "Error: Keine Podcast-Episoden im Feed gefunden."
        rm "$TEMP_RSS_FILE"
        exit 1
    fi
fi

# Extrahiere Titels und URLs in temporäre Dateien
TITLES_FILE=$(mktemp)
URLS_FILE=$(mktemp)

xmllint --xpath '//item[enclosure]/title/text()' "$TEMP_RSS_FILE" 2>/dev/null | sed 's/&amp;/\&/g' | sed 's/&lt;/</g' | sed 's/&gt;/>/g' > "$TITLES_FILE"
xmllint --xpath '//item[enclosure]/enclosure/@url' "$TEMP_RSS_FILE" 2>/dev/null | grep -o '"[^"]*"' | sed 's/"//g' > "$URLS_FILE"

# Zähle die Anzahl der gefundenen Episoden
TOTAL_EPISODES=$(wc -l < "$URLS_FILE")
echo "Gefundene Episoden: $TOTAL_EPISODES"

# Begrenze die Anzahl der Episoden, wenn gewünscht
if [ "$LIMIT" -gt 0 ] && [ "$LIMIT" -lt "$TOTAL_EPISODES" ]; then
    TOTAL_EPISODES=$LIMIT
    echo "Lade die ersten $LIMIT Episoden herunter..."
else
    echo "Lade alle Episoden herunter..."
fi

# Durchlaufe die Listen und lade die Dateien herunter
COUNTER=0
while IFS= read -r TITLE && IFS= read -r URL <&3; do
    COUNTER=$((COUNTER + 1))
    
    # Limit überprüfen
    if [ "$LIMIT" -gt 0 ] && [ "$COUNTER" -gt "$LIMIT" ]; then
        break
    fi
    
    # Bereinige den Titel für die Verwendung als Dateiname
    SAFE_TITLE=$(echo "$TITLE" | tr -dc '[:alnum:][:space:]._-' | tr -s ' ' '_')
    
    # Bestimme die Dateierweiterung aus der URL
    EXTENSION="${URL##*.}"
    if [[ "$EXTENSION" == *"?"* ]]; then
        EXTENSION=$(echo "$EXTENSION" | cut -d'?' -f1)
    fi
    
    # Falls keine Erweiterung erkennbar ist, verwende mp3 als Standard
    if [ ${#EXTENSION} -gt 4 ] || [ ${#EXTENSION} -eq 0 ]; then
        EXTENSION="mp3"
    fi
    
    FILE_PATH="$DOWNLOAD_DIR/${SAFE_TITLE}.${EXTENSION}"
    
    echo "[$COUNTER/$TOTAL_EPISODES] Lade herunter: $TITLE"
    curl -L -o "$FILE_PATH" "$URL"
    
    if [ $? -eq 0 ]; then
        echo "  √ Erfolgreich heruntergeladen: $FILE_PATH"
    else
        echo "  × Fehler beim Herunterladen: $URL"
    fi
    
done < "$TITLES_FILE" 3< "$URLS_FILE"

# Temporäre Dateien bereinigen
rm "$TEMP_RSS_FILE" "$TITLES_FILE" "$URLS_FILE"

echo "Download abgeschlossen. $COUNTER Episoden wurden in '$DOWNLOAD_DIR' gespeichert."
