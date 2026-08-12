# 🤖 RAFIKI APP — Companion Robot for Children

Welcome to the **Rafiki Companion Robot Application** repository.  
Rafiki is an intelligent robot for children. This repository contains the **Flutter Mobile App** (which acts as Rafiki's **Mouth & Ears**) and the **FastAPI Backend Server** (central brain & owner management).

---

## 📐 Architecture Stack

- **Frontend Mobile:** Flutter (Dart 3+)
  - **Mouth Output (TTS):** `flutter_tts` playing speech over the smartphone speaker with customizable pitch & rate.
  - **Ears Input (STT):** `speech_to_text` capturing voice microphone input from children.
  - **Animated Avatar:** Glowing pulse mouth UI reacting in real-time to voice output.
- **Backend Server:** FastAPI (Python 3.11+)
  - **AI Dialog Engine:** Process child voice input, generate friendly responses and physical robot movement instructions.
  - **WebSocket Hardware Bridge:** Bi-directional sync between App, FastAPI, and Raspberry Pi.
  - **Owner & Child Management:** Parent authentication, child profile switcher, and safety controls.
- **Hardware Body:** Raspberry Pi
  - Connects via WebSocket / HTTP to receive physical movement actions (wave hands, tilt head, LED matrix, battery level).

---

## 📁 Repository Structure

- [`CONTEXT.md`](file:///C:/Users/Salem/Documents/projet/rafiki%20app/CONTEXT.md) — Continuous feature & action traceability log.
- [`VIBE_RULES.md`](file:///C:/Users/Salem/Documents/projet/rafiki%20app/VIBE_RULES.md) — Vibe coding rules and engineering standards.
- [`backend/`](file:///C:/Users/Salem/Documents/projet/rafiki%20app/backend/) — FastAPI Python backend server.
- [`mobile/`](file:///C:/Users/Salem/Documents/projet/rafiki%20app/mobile/) — Flutter mobile application.

---

## 🚀 Getting Started

### 1. Launch FastAPI Backend Server

```bash
cd backend
pip install -r requirements.txt
python -m app.main
```
*Backend runs on `http://localhost:8000` (API Docs at `http://localhost:8000/docs`).*

### 2. Launch Flutter Mobile App

```bash
cd mobile
flutter pub get
flutter run
```

---

## 🛡️ Vibe Rules & Traceability
As defined in [`VIBE_RULES.md`](file:///C:/Users/Salem/Documents/projet/rafiki%20app/VIBE_RULES.md), every modification is recorded in [`CONTEXT.md`](file:///C:/Users/Salem/Documents/projet/rafiki%20app/CONTEXT.md) to guarantee complete development history and architectural clarity.
