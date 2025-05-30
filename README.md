# Video Transcriber

Un outil Python pour télécharger, transcrire et résumer automatiquement des vidéos YouTube en français.

## Fonctionnalités

- **Téléchargement audio** : Extraction automatique de l'audio depuis YouTube
- **Transcription** : Conversion audio-texte avec Whisper
- **Résumé intelligent** : Génération de résumés structurés via Ollama
- **Interface simple** : Script bash pour une utilisation facile

## Prérequis

### Outils système requis

1. **Python 3.7+**
2. **yt-dlp** : Pour télécharger l'audio depuis YouTube
   ```bash
   pip install yt-dlp
   ```
3. **FFmpeg** : Pour la conversion audio
   ```bash
   # Ubuntu/Debian
   sudo apt install ffmpeg
   
   # macOS
   brew install ffmpeg
   
   # Windows
   # Télécharger depuis https://ffmpeg.org/download.html
   ```

### Dépendances Python

Installez les dépendances avec pip :

```bash
pip install whisper pydub requests
```

**Détail des dépendances :**
- `whisper` : Modèle de transcription OpenAI
- `pydub` : Manipulation de fichiers audio
- `requests` : Communication avec l'API Ollama

### Ollama (requis pour les résumés)

1. **Installation d'Ollama :**
   ```bash
   # Linux/macOS
   curl -fsSL https://ollama.ai/install.sh | sh
   
   # Ou télécharger depuis https://ollama.ai/
   ```

2. **Démarrage du serveur :**
   ```bash
   ollama serve
   ```

3. **Installation d'un modèle :**
   ```bash
   # Modèles recommandés
   ollama pull deepseek-r1:latest     # Performance élevée
   ollama pull qwen2.5:14b           # Bon compromis
   ollama pull llama3.2:3b           # Plus léger
   ```

## Utilisation

### Méthode 1 : Script bash (recommandé)

```bash
chmod +x start.sh
./start.sh "https://youtube.com/watch?v=VIDEO_ID"
```

### Méthode 2 : Script Python direct

```bash
# Transcription complète
python3 video_transcriber.py "https://youtube.com/watch?v=VIDEO_ID"

# Avec options personnalisées
python3 video_transcriber.py "URL" \
  --whisper-model base \
  --language fr \
  --output ma_transcription.txt \
  --summary mon_resume.txt \
  --ollama-model "qwen2.5:14b"
```

### Résumé depuis transcription existante

Si vous avez déjà un fichier de transcription :

```bash
python3 video_transcriber.py "URL_FICTIVE" \
  --transcription transcription_existante.txt \
  --summary nouveau_resume.txt
```

## Options disponibles

| Option | Défaut | Description |
|--------|--------|-------------|
| `--whisper-model` | `base` | Modèle Whisper (tiny, base, small, medium, large) |
| `--language` | `fr` | Code langue ISO 639-1 |
| `--output` | `transcription.txt` | Fichier de transcription |
| `--summary` | `resume.txt` | Fichier de résumé |
| `--ollama-model` | `qwen3:8b` | Modèle Ollama |
| `--ollama-url` | `http://localhost:11434` | URL du serveur Ollama |
| `--transcription` | `transcription.txt` | Fichier de transcription existant |

## Structure des fichiers

```
video transcriber/
├── video_transcriber.py    # Script principal
├── start.sh                # Script de lancement bash
├── transcription.txt       # Sortie transcription
├── resume.txt             # Sortie résumé
└── README.md              # Ce fichier
```

## Recommandations

### Choix du modèle Whisper
- **tiny** : Très rapide, qualité basique
- **base** : Bon compromis vitesse/qualité (recommandé)
- **small** : Meilleure qualité, plus lent
- **medium/large** : Qualité maximale, très lent

### Choix du modèle Ollama
- **deepseek-r1:latest** : Excellence pour le raisonnement
- **qwen2.5:14b** : Très bon équilibre performance/ressources
- **llama3.2:3b** : Plus léger, moins de RAM requise

## Dépannage

### Erreurs communes

1. **"yt-dlp non trouvé"**
   ```bash
   pip install yt-dlp
   ```

2. **"FFmpeg non trouvé"**
   ```bash
   sudo apt install ffmpeg  # Linux
   brew install ffmpeg      # macOS
   ```

3. **"Impossible d'accéder à Ollama"**
   ```bash
   ollama serve  # Démarrer le serveur
   ```

4. **"Modèle Whisper non trouvé"**
   ```bash
   # Les modèles se téléchargent automatiquement au premier usage
   ```

### Performance

- Pour des vidéos longues (>1h), utilisez le modèle Whisper `base` ou `small`
- Assurez-vous d'avoir au moins 4GB de RAM libre pour les gros modèles
- Le résumé Ollama peut prendre plusieurs minutes selon le modèle choisi

## Exemples d'usage

```bash
# Transcription rapide avec résumé
./start.sh "https://youtube.com/watch?v=abc123"

# Transcription haute qualité
python3 video_transcriber.py "URL" --whisper-model large

# Résumé depuis fichier existant
python3 video_transcriber.py "" --transcription mon_fichier.txt

# Utilisation avec un modèle Ollama spécifique
python3 video_transcriber.py "URL" --ollama-model "mistral:7b"
```

## Licence

Ce projet est fourni tel quel à des fins éducatives et de démonstration.