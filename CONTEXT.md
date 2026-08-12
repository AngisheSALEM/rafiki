# 📑 CONTEXT & TRACEABILITY LOG — RAFIKI ROBOT APP

> **Document Status:** Active & Continuously Updated  
> **Last Update:** 2026-08-11 17:55 (UTC+1)  
> **Project Name:** Rafiki App (Companion Robot for Children)

---

## 🎯 1. Project Overview & Vision

**Rafiki** is an intelligent companion robot designed for children.  
The Mobile Application acts as the **"Mouth and Ears"** of Rafiki, while communicating with Rafiki's **Rafiki Robot** (physical body) and the **FastAPI Server** (central brain & administration backend).

---

## 🎤 2. Hardware Microphone Opening & Direct Whisper Capture Flow

- **Ouverture Directe du Microphone Physique :** Appel de `requestMicrophonePermission()` via la Web MediaStream API (`navigator.mediaDevices.getUserMedia`) et `SpeechToText`.
- **Suppression Totale de la Boîte de Dialogue :** Aucun popup de texte. Le clic sur le bouton microphone enclenche **directement le matériel du microphone du téléphone/navigateur**.
- **Fenêtrage 30s & Spectrogramme Log-Mel [80x3000] :** Traitement audio standardisé par le modèle OpenAI Whisper avec les balises spécialisées (`<|startoftranscript|>`, `<|fr|>`, `<|transcribe|>`, `<|notimestamps|>`, `<|endoftext|>`).

---

## 📊 3. Feature Traceability Matrix

| Feature ID | Feature Name | Layer | Status | Affected Files | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **FEAT-001** | Vibe Rules & Traceability | Docs | ✅ COMPLETED | [`VIBE_RULES.md`](file:///C:/Users/Salem/Documents/projet/rafiki%20app/VIBE_RULES.md), [`CONTEXT.md`](file:///C:/Users/Salem/Documents/projet/rafiki%20app/CONTEXT.md) | Standard defined |
| **FEAT-020** | Direct Hardware Mic Access | Mobile | ✅ COMPLETED | [`mobile/lib/services/stt_service.dart`](file:///C:/Users/Salem/Documents/projet/rafiki%20app/mobile/lib/services/stt_service.dart), [`mobile/lib/features/voice_interaction/screens/rafiki_mouth_screen.dart`](file:///C:/Users/Salem/Documents/projet/rafiki%20app/mobile/lib/features/voice_interaction/screens/rafiki_mouth_screen.dart) | Demande directe de permission matérielle du microphone téléphone/navigateur au clic sur le bouton mic, sans popup de texte. |

---

## 📝 4. Action Execution Log

- **[2026-08-11 17:55] Action 26 - Hardware Mic Access Fix:**
  - Integrated `requestMicrophonePermission()` in `STTService` using `getUserMedia({'audio': true})`.
  - Linked mic tap directly to opening hardware microphone stream without any dialog.
