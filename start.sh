#!/bin/bash

# Script amélioré pour le transcripteur vidéo
# Supporte toutes les options de video_transcriber.py avec validation des dépendances

set -e  # Arrêter en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration par défaut
DEFAULT_WHISPER_MODEL="turbo"
DEFAULT_LANGUAGE="fr"
DEFAULT_OUTPUT="transcription.txt"
DEFAULT_SUMMARY="resume.txt"
DEFAULT_OLLAMA_MODEL="qwen2.5:7b"
DEFAULT_OLLAMA_URL="http://localhost:11434"

# Variables d'options
URL=""
WHISPER_MODEL="$DEFAULT_WHISPER_MODEL"
LANGUAGE="$DEFAULT_LANGUAGE"
OUTPUT_FILE="$DEFAULT_OUTPUT"
SUMMARY_FILE="$DEFAULT_SUMMARY"
OLLAMA_MODEL="$DEFAULT_OLLAMA_MODEL"
OLLAMA_URL="$DEFAULT_OLLAMA_URL"
TRANSCRIPTION_FILE=""
SKIP_CHECKS=false

# Fonction d'affichage de l'aide
show_help() {
    cat << EOF
${BLUE}Script de transcription vidéo YouTube avec Whisper et Ollama${NC}

${YELLOW}USAGE:${NC}
    $0 [OPTIONS] URL_YOUTUBE
    $0 [OPTIONS] --transcription FICHIER_EXISTANT

${YELLOW}OPTIONS:${NC}
    -h, --help                    Afficher cette aide
    -w, --whisper-model MODEL     Modèle Whisper (tiny, base, small, medium, large, turbo)
                                  Défaut: $DEFAULT_WHISPER_MODEL
    -l, --language LANG           Langue de transcription (code ISO 639-1)
                                  Défaut: $DEFAULT_LANGUAGE
    -o, --output FICHIER          Fichier de sortie pour la transcription
                                  Défaut: $DEFAULT_OUTPUT
    -s, --summary FICHIER         Fichier de sortie pour le résumé
                                  Défaut: $DEFAULT_SUMMARY
    -m, --ollama-model MODEL      Modèle Ollama à utiliser
                                  Défaut: $DEFAULT_OLLAMA_MODEL
    -u, --ollama-url URL          URL du serveur Ollama
                                  Défaut: $DEFAULT_OLLAMA_URL
    -t, --transcription FICHIER   Utiliser un fichier de transcription existant
    --skip-checks                 Ignorer la vérification des dépendances

${YELLOW}EXEMPLES:${NC}
    # Transcription basique
    $0 "https://youtube.com/watch?v=abc123"
    
    # Avec modèle Whisper plus précis
    $0 -w medium "https://youtube.com/watch?v=abc123"
    
    # Résumé depuis transcription existante
    $0 -t ma_transcription.txt -s nouveau_resume.txt
    
    # Configuration complète
    $0 -w large -l en -m "deepseek-r1:latest" -o "en_transcription.txt" "URL"

${YELLOW}MODÈLES WHISPER DISPONIBLES:${NC}
    tiny    - Très rapide, qualité basique
    base    - Bon compromis vitesse/qualité (recommandé)
    small   - Meilleure qualité, plus lent
    medium  - Haute qualité, plus lent
    large   - Qualité maximale, très lent
    turbo   - Optimisé vitesse/qualité

${YELLOW}MODÈLES OLLAMA RECOMMANDÉS:${NC}
    qwen2.5:7b         - Défaut, bon équilibre
    qwen2.5:14b        - Meilleure qualité
    deepseek-r1:latest - Performance maximale
    llama3.2:3b        - Plus léger
EOF
}

# Fonction de log avec couleur
log() {
    local level=$1
    shift
    case $level in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $*" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $*" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $*" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} $*" ;;
    esac
}

# Fonction de vérification des dépendances système
check_system_dependencies() {
    log "INFO" "Vérification des dépendances système..."
    
    local missing_deps=()
    
    # Vérifier Python 3
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    else
        local python_version=$(python3 --version 2>&1 | grep -oP '\d+\.\d+')
        local major=$(echo $python_version | cut -d. -f1)
        local minor=$(echo $python_version | cut -d. -f2)
        if [ "$major" -lt 3 ] || ([ "$major" -eq 3 ] && [ "$minor" -lt 7 ]); then
            log "ERROR" "Python 3.7+ requis, version détectée: $python_version"
            exit 1
        fi
        log "DEBUG" "Python OK: $(python3 --version)"
    fi
    
    # Vérifier yt-dlp
    if ! command -v yt-dlp &> /dev/null; then
        missing_deps+=("yt-dlp")
    else
        log "DEBUG" "yt-dlp OK: $(yt-dlp --version)"
    fi
    
    # Vérifier FFmpeg
    if ! command -v ffmpeg &> /dev/null; then
        missing_deps+=("ffmpeg")
    else
        log "DEBUG" "FFmpeg OK"
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log "ERROR" "Dépendances manquantes: ${missing_deps[*]}"
        log "INFO" "Installation suggérée:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                "python3") echo "  sudo apt install python3 python3-pip" ;;
                "yt-dlp")  echo "  pip install yt-dlp" ;;
                "ffmpeg") echo "  sudo apt install ffmpeg" ;;
            esac
        done
        exit 1
    fi
}

# Fonction de vérification des dépendances Python
check_python_dependencies() {
    log "INFO" "Vérification des dépendances Python..."
    
    local missing_deps=()
    local required_packages=("whisper" "pydub" "requests")
    
    for package in "${required_packages[@]}"; do
        if ! python3 -c "import $package" &> /dev/null; then
            missing_deps+=("$package")
        else
            log "DEBUG" "Package Python OK: $package"
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log "ERROR" "Packages Python manquants: ${missing_deps[*]}"
        log "INFO" "Installation suggérée:"
        echo "  pip install ${missing_deps[*]}"
        exit 1
    fi
}

# Fonction de vérification d'Ollama
check_ollama() {
    log "INFO" "Vérification d'Ollama..."
    
    # Vérifier si Ollama est installé
    if ! command -v ollama &> /dev/null; then
        log "WARN" "Ollama non trouvé dans le PATH"
        log "INFO" "Installation suggérée: curl -fsSL https://ollama.ai/install.sh | sh"
    else
        log "DEBUG" "Ollama installé"
    fi
    
    # Vérifier si le serveur Ollama répond
    if ! curl -s "$OLLAMA_URL/api/tags" &> /dev/null; then
        log "WARN" "Serveur Ollama non accessible sur $OLLAMA_URL"
        log "INFO" "Démarrage suggéré: ollama serve"
        log "INFO" "Le script peut continuer, mais la génération de résumé échouera"
    else
        log "DEBUG" "Serveur Ollama accessible"
        
        # Vérifier si le modèle est disponible
        local available_models=$(curl -s "$OLLAMA_URL/api/tags" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
        if echo "$available_models" | grep -q "^$OLLAMA_MODEL$"; then
            log "DEBUG" "Modèle Ollama OK: $OLLAMA_MODEL"
        else
            log "WARN" "Modèle Ollama '$OLLAMA_MODEL' non trouvé"
            log "INFO" "Installation suggérée: ollama pull $OLLAMA_MODEL"
            log "INFO" "Modèles disponibles:"
            echo "$available_models" | sed 's/^/  - /'
        fi
    fi
}

# Fonction de validation des paramètres
validate_parameters() {
    # Vérifier le modèle Whisper
    local valid_whisper_models=("tiny" "base" "small" "medium" "large" "turbo")
    if [[ ! " ${valid_whisper_models[@]} " =~ " ${WHISPER_MODEL} " ]]; then
        log "ERROR" "Modèle Whisper invalide: $WHISPER_MODEL"
        log "INFO" "Modèles valides: ${valid_whisper_models[*]}"
        exit 1
    fi
    
    # Vérifier que l'URL ou le fichier de transcription est fourni
    if [[ -z "$URL" && -z "$TRANSCRIPTION_FILE" ]]; then
        log "ERROR" "URL YouTube ou fichier de transcription requis"
        show_help
        exit 1
    fi
    
    # Vérifier l'existence du fichier de transcription si spécifié
    if [[ -n "$TRANSCRIPTION_FILE" && ! -f "$TRANSCRIPTION_FILE" ]]; then
        log "ERROR" "Fichier de transcription non trouvé: $TRANSCRIPTION_FILE"
        exit 1
    fi
    
    # Vérifier que l'URL est valide si fournie
    if [[ -n "$URL" && ! "$URL" =~ ^https?://(www\.)?(youtube\.com|youtu\.be) ]]; then
        log "WARN" "L'URL ne semble pas être une URL YouTube valide"
        log "INFO" "Tentative de traitement quand même..."
    fi
}

# Analyse des arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -w|--whisper-model)
                WHISPER_MODEL="$2"
                shift 2
                ;;
            -l|--language)
                LANGUAGE="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -s|--summary)
                SUMMARY_FILE="$2"
                shift 2
                ;;
            -m|--ollama-model)
                OLLAMA_MODEL="$2"
                shift 2
                ;;
            -u|--ollama-url)
                OLLAMA_URL="$2"
                shift 2
                ;;
            -t|--transcription)
                TRANSCRIPTION_FILE="$2"
                shift 2
                ;;
            --skip-checks)
                SKIP_CHECKS=true
                shift
                ;;
            -*)
                log "ERROR" "Option inconnue: $1"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$URL" ]]; then
                    URL="$1"
                else
                    log "ERROR" "Trop d'arguments positionnels"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
}

# Fonction principale d'exécution
run_transcriber() {
    log "INFO" "Démarrage du transcripteur vidéo..."
    
    # Construire la commande Python
    local python_cmd=(python3 video_transcriber.py)
    
    if [[ -n "$TRANSCRIPTION_FILE" ]]; then
        python_cmd+=("" "--transcription" "$TRANSCRIPTION_FILE")
    else
        python_cmd+=("$URL")
    fi
    
    python_cmd+=(
        "--whisper-model" "$WHISPER_MODEL"
        "--language" "$LANGUAGE"
        "--output" "$OUTPUT_FILE"
        "--summary" "$SUMMARY_FILE"
        "--ollama-model" "$OLLAMA_MODEL"
        "--ollama-url" "$OLLAMA_URL"
    )
    
    log "INFO" "Commande: ${python_cmd[*]}"
    log "INFO" "Configuration:"
    log "INFO" "  - Modèle Whisper: $WHISPER_MODEL"
    log "INFO" "  - Langue: $LANGUAGE"
    log "INFO" "  - Sortie transcription: $OUTPUT_FILE"
    log "INFO" "  - Sortie résumé: $SUMMARY_FILE"
    log "INFO" "  - Modèle Ollama: $OLLAMA_MODEL"
    
    # Exécuter la commande
    if "${python_cmd[@]}"; then
        log "INFO" "Traitement terminé avec succès!"
        log "INFO" "Fichiers générés:"
        [[ -f "$OUTPUT_FILE" ]] && log "INFO" "  - Transcription: $OUTPUT_FILE"
        [[ -f "$SUMMARY_FILE" ]] && log "INFO" "  - Résumé: $SUMMARY_FILE"
    else
        log "ERROR" "Une erreur s'est produite lors du traitement"
        exit 1
    fi
}

# Point d'entrée principal
main() {
    # Si aucun argument, afficher l'aide
    if [[ $# -eq 0 ]]; then
        show_help
        exit 1
    fi
    
    # Parser les arguments
    parse_arguments "$@"
    
    # Valider les paramètres
    validate_parameters
    
    # Vérifier les dépendances (sauf si --skip-checks)
    if [[ "$SKIP_CHECKS" != true ]]; then
        check_system_dependencies
        check_python_dependencies
        check_ollama
    else
        log "WARN" "Vérification des dépendances ignorée"
    fi
    
    # Exécuter le transcripteur
    run_transcriber
}

# Exécuter le script principal avec tous les arguments
main "$@"
