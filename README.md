# Video Transcriber

Un outil Python robuste pour télécharger, transcrire et résumer automatiquement des vidéos YouTube avec Whisper et Ollama.

## Fonctionnalités

- **Téléchargement audio intelligent** : Extraction optimisée avec yt-dlp et conversion automatique
- **Transcription précise** : Multiple modèles Whisper (tiny à turbo) avec optimisations audio
- **Résumés structurés** : Génération intelligente via Ollama avec prompts optimisés
- **Interface complète** : Script bash avancé avec validation des dépendances
- **Gestion d'erreurs** : Stratégies de fallback et récupération automatique
- **Optimisations performance** : Traitement audio 16kHz mono pour Whisper

## Architecture et pipeline

Le transcripteur suit un pipeline linéaire optimisé :

1. **Extraction audio** : yt-dlp avec conversion directe WAV ou fallback multi-format
2. **Préparation audio** : Conversion 16kHz, mono, 16-bit via FFmpeg/pydub
3. **Transcription** : Whisper avec choix de modèle (tiny/base/small/medium/large/turbo)
4. **Génération résumé** : Ollama avec prompt engineering avancé
5. **Sortie structurée** : Fichiers texte avec formatage Markdown

## Prérequis système

### Outils système requis

```bash
# Python 3.7+ (vérifié automatiquement)
python3 --version

# yt-dlp pour extraction YouTube
pip install yt-dlp

# FFmpeg pour conversion audio
# Ubuntu/Debian
sudo apt install ffmpeg

# macOS
brew install ffmpeg

# Windows
# Télécharger depuis https://ffmpeg.org/download.html
```

### Dépendances Python

```bash
# Installation des packages requis
pip install whisper pydub requests

# Vérification des versions
python3 -c "import whisper, pydub, requests; print('✓ Toutes les dépendances sont installées')"
```

**Détail des dépendances :**
- `whisper` : Modèles de transcription OpenAI (auto-download)
- `pydub` : Manipulation et conversion audio
- `requests` : Communication API Ollama

### Configuration Ollama

```bash
# 1. Installation Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# 2. Démarrage serveur (terminal séparé)
ollama serve

# 3. Installation modèles recommandés
ollama pull qwen2.5:7b        # Défaut (équilibré)
ollama pull deepseek-r1:latest # Performance maximale
ollama pull llama3.2:3b       # Plus léger (3GB RAM)
ollama pull qwen2.5:14b       # Haute qualité

# 4. Vérification
curl http://localhost:11434/api/tags
```

## Utilisation

### Démarrage rapide

```bash
# Rendre le script exécutable
chmod +x start.sh

# Transcription basique avec résumé
./start.sh "https://youtube.com/watch?v=VIDEO_ID"
```

### Options avancées du script bash

```bash
# Usage complet avec toutes les options
./start.sh [OPTIONS] URL_YOUTUBE

# Options disponibles :
-h, --help                    # Aide détaillée
-w, --whisper-model MODEL     # turbo (défaut), tiny, base, small, medium, large
-l, --language LANG           # fr (défaut), en, es, de, it...
-o, --output FICHIER          # transcription.txt (défaut)
-s, --summary FICHIER         # resume.txt (défaut)
-m, --ollama-model MODEL      # qwen2.5:7b (défaut)
-u, --ollama-url URL          # http://localhost:11434 (défaut)
-t, --transcription FICHIER   # Utiliser transcription existante
--skip-checks                 # Ignorer vérifications dépendances
```

### Exemples d'utilisation

```bash
# 1. Transcription rapide (modèle turbo par défaut)
./start.sh "https://youtube.com/watch?v=abc123"

# 2. Haute qualité avec modèle medium
./start.sh -w medium "https://youtube.com/watch?v=abc123"

# 3. Contenu anglais avec modèle performant
./start.sh -w large -l en -m "deepseek-r1:latest" "URL_ANGLAISE"

# 4. Résumé depuis transcription existante
./start.sh -t ma_transcription.txt -s nouveau_resume.txt

# 5. Configuration complète personnalisée
./start.sh -w small -l fr -o "sortie_custom.txt" -s "resume_custom.txt" -m "qwen2.5:14b" "URL"
```

### Utilisation Python directe

```bash
# Transcription complète avec options par défaut
python3 video_transcriber.py "https://youtube.com/watch?v=VIDEO_ID"

# Options personnalisées
python3 video_transcriber.py "URL" \
  --whisper-model turbo \
  --language fr \
  --output ma_transcription.txt \
  --summary mon_resume.txt \
  --ollama-model "qwen2.5:7b" \
  --ollama-url "http://localhost:11434"

# Génération résumé depuis transcription existante
python3 video_transcriber.py "" \
  --transcription transcription_existante.txt \
  --summary nouveau_resume.txt \
  --ollama-model "deepseek-r1:latest"
```

## Configuration et options

### Modèles Whisper disponibles

| Modèle | Taille | Vitesse | Qualité | RAM requise | Recommandation |
|--------|--------|---------|---------|-------------|----------------|
| `tiny` | 39 MB | ⚡⚡⚡⚡ | ⭐⭐ | ~1 GB | Tests rapides |
| `base` | 74 MB | ⚡⚡⚡ | ⭐⭐⭐ | ~1 GB | Bon compromis |
| `small` | 244 MB | ⚡⚡ | ⭐⭐⭐⭐ | ~2 GB | Qualité/vitesse |
| `medium` | 769 MB | ⚡ | ⭐⭐⭐⭐⭐ | ~5 GB | Haute qualité |
| `large` | 1550 MB | ⚡ | ⭐⭐⭐⭐⭐ | ~10 GB | Qualité max |
| `turbo` | 809 MB | ⚡⚡⚡ | ⭐⭐⭐⭐ | ~6 GB | **Défaut optimisé** |

### Modèles Ollama recommandés

| Modèle | Taille | RAM | Performance | Usage |
|--------|--------|-----|-------------|-------|
| `qwen2.5:7b` | 4.7 GB | 8 GB | ⭐⭐⭐⭐ | **Défaut équilibré** |
| `deepseek-r1:latest` | 8.9 GB | 16 GB | ⭐⭐⭐⭐⭐ | Performance maximale |
| `llama3.2:3b` | 2.0 GB | 4 GB | ⭐⭐⭐ | Environnements contraints |
| `qwen2.5:14b` | 8.2 GB | 16 GB | ⭐⭐⭐⭐⭐ | Haute qualité |

### Structure de projet

```
video transcriber/
├── video_transcriber.py    # Script principal Python
├── start.sh                # Wrapper bash avec validations
└── README.md              # Documentation (ce fichier)
```

## Fonctionnalités avancées

### Gestion d'erreurs et fallbacks

Le système implémente plusieurs stratégies de récupération :

1. **Audio Download** : yt-dlp direct → fallback format optimal → conversion pydub
2. **Format Detection** : Auto-détection .m4a, .mp3, .webm, .wav, .ogg
3. **Model Validation** : Vérification modèles Whisper et Ollama
4. **Connection Check** : Test connectivité serveur Ollama
5. **Dependency Check** : Validation complète dépendances système

### Optimisations performance

- **Audio Processing** : Conversion directe 16kHz mono pour Whisper
- **Memory Management** : Nettoyage automatique fichiers temporaires
- **Model Caching** : Réutilisation modèles Whisper chargés
- **Timeout Handling** : Timeout 3600s pour contenu long Ollama
- **Parallel Processing** : Traitement audio optimisé

### Prompt engineering Ollama

Le système utilise un prompt sophistiqué pour générer des résumés structurés :

- **Correction automatique** des erreurs de transcription
- **Filtrage** répétitions et hésitations orales
- **Structure Markdown** avec sections hiérarchiques
- **Analyse contextuelle** et extraction points clés
- **Format standardisé** : Points clés, Informations, Analyse, Synthèse

## Dépannage

### Diagnostic automatique

Le script bash `start.sh` inclut un diagnostic complet :

```bash
# Lancer avec vérifications détaillées
./start.sh --help

# Ignorer vérifications (mode expert)
./start.sh --skip-checks "URL"
```

### Erreurs fréquentes et solutions

#### 1. Problèmes d'installation

```bash
# Python version insuffisante
# Solution : Installer Python 3.7+
sudo apt update && sudo apt install python3.8

# yt-dlp manquant
pip install --upgrade yt-dlp

# FFmpeg manquant
sudo apt install ffmpeg  # Ubuntu/Debian
brew install ffmpeg      # macOS
```

#### 2. Problèmes Ollama

```bash
# Serveur non démarré
ollama serve  # Terminal séparé

# Modèle manquant
ollama list  # Voir modèles installés
ollama pull qwen2.5:7b  # Installer modèle par défaut

# Port occupé
# Changer port : --ollama-url "http://localhost:11435"
```

#### 3. Problèmes audio

```bash
# Erreur téléchargement YouTube
# Vérifier URL et connectivité
# Mettre à jour yt-dlp : pip install --upgrade yt-dlp

# Erreur conversion audio
# Vérifier installation FFmpeg
ffmpeg -version
```

#### 4. Problèmes mémoire

```bash
# RAM insuffisante pour modèle Whisper
# Utiliser modèle plus léger : --whisper-model tiny/base

# RAM insuffisante pour Ollama
# Utiliser modèle plus léger : --ollama-model llama3.2:3b
```

### Optimisation performances

#### Pour vidéos courtes (<15 min)
```bash
./start.sh -w turbo -m "qwen2.5:7b" "URL"
```

#### Pour vidéos longues (>1h)
```bash
./start.sh -w base -m "llama3.2:3b" "URL"
```

#### Pour qualité maximale
```bash
./start.sh -w large -m "deepseek-r1:latest" "URL"
```

## Cas d'usage

### Workflow typique

1. **Préparation** : Vérifier dépendances avec `./start.sh --help`
2. **Transcription** : `./start.sh "URL_YOUTUBE"`
3. **Vérification** : Contrôler `transcription.txt` et `resume.txt`
4. **Personnalisation** : Régénérer résumé si nécessaire avec modèle différent

### Intégration dans scripts

```bash
#!/bin/bash
# Script d'automatisation batch

URLS=(
  "https://youtube.com/watch?v=abc123"
  "https://youtube.com/watch?v=def456"
)

for url in "${URLS[@]}"; do
  ./start.sh -w base -o "transcription_$(date +%s).txt" "$url"
done
```

## Licence et contribution

Ce projet est fourni à des fins éducatives et de démonstration. Contributions bienvenues via issues et pull requests.