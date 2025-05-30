import sys
import os
import json
import subprocess
import whisper
import argparse
from pydub import AudioSegment
import requests
import time

def download_audio(url, output_file="audio.wav"):
    """Télécharge l'audio d'une vidéo YouTube et le convertit directement en WAV optimisé"""
    try:
        # Option 1: Conversion directe avec yt-dlp + ffmpeg (plus efficace)
        command = [
            "yt-dlp", 
            "-x",                                    # Extraire audio seulement
            "--audio-format", "wav",                 # Format de sortie WAV
            "--audio-quality", "0",                  # Meilleure qualité
            "--postprocessor-args", 
            "ffmpeg:-ar 16000 -ac 1 -sample_fmt s16", # 16kHz, mono, 16-bit directement
            "-o", output_file.replace('.wav', '.%(ext)s'),  # Template de sortie
            url
        ]
        
        print("Téléchargement et conversion audio en cours...")
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        
        # yt-dlp ajoute automatiquement l'extension, on vérifie le fichier créé
        expected_file = output_file.replace('.wav', '.wav')  # Le fichier final
        if os.path.exists(expected_file):
            return expected_file
        
        # Si le fichier n'existe pas avec le nom attendu, chercher le fichier créé
        base_name = output_file.replace('.wav', '')
        for ext in ['.wav', '.m4a', '.mp3']:
            test_file = base_name + ext
            if os.path.exists(test_file):
                if ext != '.wav':
                    # Si ce n'est pas déjà en WAV, convertir
                    return _convert_to_wav(test_file, output_file)
                return test_file
            return None

    except subprocess.CalledProcessError as e:
        print(f"Erreur avec yt-dlp: {e}")
        print("Tentative avec méthode de fallback...")
        return _download_audio_fallback(url, output_file)
    except FileNotFoundError:
        print("yt-dlp non trouvé, tentative avec méthode de fallback...")
        return _download_audio_fallback(url, output_file)

def _convert_to_wav(input_file, output_file):
    """Convertit un fichier audio en WAV avec les bonnes spécifications"""
    try:
        audio = AudioSegment.from_file(input_file)
        audio = audio.set_channels(1).set_frame_rate(16000).set_sample_width(2)
        audio.export(output_file, format="wav")
        os.remove(input_file)  # Nettoyer le fichier temporaire
        return output_file
    except Exception as e:
        print(f"Erreur lors de la conversion: {e}")
        return None

def _download_audio_fallback(url, output_file):
    """Méthode de fallback si la conversion directe échoue"""
    temp_file = "temp_audio"
    
    try:
        # Télécharger dans le meilleur format audio disponible
        command = [
            "yt-dlp", 
            "-x", 
            "--audio-format", "best",
            "-o", f"{temp_file}.%(ext)s",
            url
        ]
        
        subprocess.run(command, check=True)
        
        # Trouver le fichier téléchargé
        downloaded_file = None
        for ext in ['.m4a', '.mp3', '.webm', '.wav', '.ogg']:
            test_file = f"{temp_file}{ext}"
            if os.path.exists(test_file):
                downloaded_file = test_file
                break
        
        if not downloaded_file:
            raise FileNotFoundError("Fichier audio téléchargé non trouvé")
        
        # Convertir avec pydub
        return _convert_to_wav(downloaded_file, output_file)
        
    except Exception as e:
        print(f"Erreur dans la méthode de fallback: {e}")
        return None

def transcribe_audio(audio_file, model_name="base", language="fr"):
    """Transcrit un fichier audio en utilisant Whisper"""
    try:
        print(f"Chargement du modèle Whisper '{model_name}'...")
        model = whisper.load_model(model_name)
        
        print("Transcription en cours...")
        result = model.transcribe(audio_file,
                                  language=language,
                                  verbose=True)
        
        return result["text"].strip()
        
    except Exception as e:
        print(f"Erreur lors de la transcription avec Whisper: {e}")
        sys.exit(1)

def get_ollama_summary(transcription, model="qwen2.5:7b", ollama_url="http://localhost:11434"):
    """Envoie la transcription à Ollama et obtient un résumé optimisé"""
    
    # Vérifier si Ollama est accessible
    try:
        response = requests.get(f"{ollama_url}/api/tags")
        if response.status_code != 200:
            print(f"Erreur: Impossible d'accéder à Ollama sur {ollama_url}")
            return None
    except requests.exceptions.RequestException as e:
        print(f"Erreur de connexion à Ollama: {str(e)}")
        print("Assurez-vous qu'Ollama est démarré avec 'ollama serve'")
        return None
    
    # Prompt optimisé pour de meilleurs résumés
    prompt = f"""
        # RÔLE
        Tu es un expert en analyse et synthèse de contenu audio transcrit.
        
        # CONTEXTE
        La transcription suivante provient d'un enregistrement audio et peut contenir :
        - Erreurs de transcription automatique
        - Fautes d'orthographe ou de frappe
        - Mots mal interprétés ou déformés
        - Phrases incomplètes ou mal structurées
        
        # TRANSCRIPTION À ANALYSER
        {transcription}
        
        # TÂCHE
        Produis une synthèse structurée en corrigeant les erreurs de transcription et en extrayant l'information pertinente.
        
        # CONTRAINTES
        - Langue : français exclusivement
        - Longueur : 300-500 mots (adapter selon la richesse du contenu)
        - Ton : objectif et professionnel
        - Structure : sections claires avec hiérarchie
        
        # FORMAT DE SORTIE OBLIGATOIRE
        ## [Titre principal du sujet traité]
        
        ### 🎯 Points clés
        - [Point essentiel 1]
        - [Point essentiel 2] 
        - [Point essentiel 3]
        
        ### 📋 Informations importantes
        [Développement des éléments factuels, données, exemples concrets mentionnés]
        
        ### 💡 Analyse et implications
        [Interprétation des enjeux, conséquences, liens logiques entre les idées]
        
        ### ✅ Synthèse finale
        [Résumé condensé des messages principaux et conclusion]
        
        # INSTRUCTIONS SPÉCIFIQUES
        1. Corrige automatiquement les erreurs évidentes de transcription
        2. Ignore les répétitions et hésitations typiques de l'oral
        3. Identifie le fil conducteur principal du discours
        4. Privilégie les faits et arguments concrets
        5. Maintiens la nuance et les subtilités du propos original"""
    
    payload = {
        "model": model,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": 0.4,
            "top_p": 0.9,
            "top_k": 25,
            "repeat_penalty": 1.2,
            "num_predict": 3000,
            "num_ctx": 16384,
            "num_thread": 6,
            "num_gpu": 0,
            "mirostat": 2,
            "mirostat_tau": 4.0,
            "mirostat_eta": 0.08,
            "tfs_z": 1.0,
            "typical_p": 0.95
        }
    }
    
    try:
        print(f"Envoi de la requête à Ollama (modèle: {model})...")
        response = requests.post(
            f"{ollama_url}/api/generate",
            json=payload,
            timeout=3600  # Timeout de 50 minutes
        )
        
        if response.status_code == 200:
            result = response.json()
            return result.get("response", "")
        else:
            print(f"Erreur HTTP {response.status_code}: {response.text}")
            return None
            
    except requests.exceptions.Timeout:
        print("Timeout: La génération du résumé prend trop de temps")
        return None
    except requests.exceptions.RequestException as e:
        print(f"Erreur lors de l'appel à Ollama: {str(e)}")
        return None
    except json.JSONDecodeError as e:
        print(f"Erreur de décodage JSON: {str(e)}")
        return None

def check_ollama_model(model, ollama_url="http://localhost:11434"):
    """Vérifie si le modèle est disponible dans Ollama"""
    try:
        response = requests.get(f"{ollama_url}/api/tags")
        if response.status_code == 200:
            models_data = response.json()
            available_models = [m["name"] for m in models_data.get("models", [])]
            
            if model not in available_models:
                print(f"Modèle '{model}' non trouvé.")
                print("Modèles disponibles:")
                for m in available_models:
                    print(f"  - {m}")
                print(f"\nPour installer DeepSeek, utilisez: ollama pull {model}")
                return False
            return True
        return None
    except Exception as e:
        print(f"Erreur lors de la vérification du modèle: {str(e)}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Télécharge, transcrit et résume une vidéo YouTube avec Ollama")
    parser.add_argument("url", help="URL de la vidéo YouTube")
    parser.add_argument("--whisper-model", default="turbo", choices=["medium", "large", "turbo"], help="Modèle Whisper à utiliser")
    parser.add_argument("--language", default="fr", help="Langue de transcription (code ISO 639-1)")
    parser.add_argument("--output", default="transcription.txt", help="Fichier de sortie pour la transcription")
    parser.add_argument("--summary", default="resume.txt", help="Fichier de sortie pour le résumé")
    parser.add_argument("--ollama-model", default="qwen2.5:7b", help="Modèle Ollama à utiliser (recommandé: qwen2.5:14b, llama3.2:3b, mistral:7b)")
    parser.add_argument("--ollama-url", default="http://localhost:11434", help="URL du serveur Ollama")
    parser.add_argument("--transcription", default="transcription.txt", help="Fichier de transcription existant")
    
    args = parser.parse_args()
    
    # Vérifier que le modèle Ollama est disponible
    if not check_ollama_model(args.ollama_model, args.ollama_url):
        sys.exit(1)

    if os.path.exists(args.transcription):
        with open(args.transcription, 'r') as f:
            existing_transcription = f.read()
        # Obtenir un résumé via Ollama
        print("Génération du résumé avec Ollama...")
        summary = get_ollama_summary(existing_transcription, args.ollama_model, args.ollama_url)

        if summary:
            # Enregistrer le résumé dans un fichier
            with open(args.summary, "w", encoding="utf-8") as f:
                f.write(summary)
            print(f"Résumé terminé et enregistré dans: {args.summary}")
        else:
            print("Échec de l'obtention du résumé depuis Ollama")

    else:
        print(f"Téléchargement de la vidéo: {args.url}")
        audio_file = download_audio(args.url)

        print(f"Transcription en cours avec Whisper modèle: {args.whisper_model}")
        transcription = transcribe_audio(audio_file, args.whisper_model, args.language)

        # Enregistrer la transcription dans un fichier
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(transcription)

        print(f"Transcription terminée et enregistrée dans: {args.output}")

        # Obtenir un résumé via Ollama
        print("Génération du résumé avec Ollama...")
        summary = get_ollama_summary(transcription, args.ollama_model, args.ollama_url)

        if summary:
            # Enregistrer le résumé dans un fichier
            with open(args.summary, "w", encoding="utf-8") as f:
                f.write(summary)
            print(f"Résumé terminé et enregistré dans: {args.summary}")
        else:
            print("Échec de l'obtention du résumé depuis Ollama")

        # Nettoyer le fichier audio
        os.remove(audio_file)

    sys.exit(0)

if __name__ == "__main__":
    main()
