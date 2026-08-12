# 🎨 VIBE CODING & ENGINEERING RULES — RAFIKI ROBOT APP

Welcome to the official **Vibe Coding Rules** for the **Rafiki Companion Robot Application**.
This guide establishes engineering principles, security rules, workflow conventions, and context tracking standards for both Frontend (Flutter) and Backend (FastAPI).

---

## 📜 1. Core Rule: Continuous Context & Feature Traceability

> **MANDATORY RULE:** Every time an action is taken or a feature is implemented, updated, or refactored, the file [`CONTEXT.md`](file:///C:/Users/Salem/Documents/projet/rafiki%20app/CONTEXT.md) **MUST** be updated immediately.

### Rules for `CONTEXT.md`:
1. **Real-time Updates:** Document feature additions, structural changes, API updates, and hardware protocol shifts as they happen.
2. **Action History:** Maintain a chronological log of actions taken with timestamps, status, affected files, and rationale.
3. **Architecture Mapping:** Keep the current architectural status of the Flutter app, FastAPI server, Raspberry Pi bridge, and STT/TTS modules up to date.
4. **Feature Matrix:** Maintain the status of each user story and feature (e.g. `[PLANNED]`, `[IN_PROGRESS]`, `[DONE]`).

---

## 🤖 2. Rafiki Concept & Technical Architecture

### 🎙️ Core Concept: App as Rafiki's "Mouth & Ears"
- **Mouth (Speaker):** The smartphone speaker plays Rafiki's voice responses outputted by the TTS engine (Text-to-Speech).
- **Ears / User Input (Microphone):** The smartphone microphone listens to the child/user speaking, transcribed via STT (Speech-to-Text).
- **Brain & Core Server (FastAPI):** Orchestrates AI responses, context memory, parent configurations, and story generation.
- **Body & Motion (Raspberry Pi):** Controls physical movements (motors, expressiveness LEDs, sensors) and syncs state with the Mobile App via WebSockets/MQTT/mDNS.
- **Owners / Parents Portal:** Manage children's profiles, monitor interaction metrics, adjust screen/voice parameters, set safety filters, and pair with the Raspberry Pi.

---

## 🛠️ 3. Full Technology Stack

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Mobile Frontend** | **Flutter (Dart 3+)** | Cross-platform (iOS/Android), high-framerate animated voice avatar UI, audio streaming |
| **Backend Server** | **FastAPI (Python 3.11+)** | High-performance asynchronous REST API, WebSockets, AI conversation engine |
| **STT Engine (Ears)** | **`speech_to_text` / Whisper Lite** | On-device microphone listening & speech recognition for ultra-low latency |
| **TTS Engine (Mouth)** | **`flutter_tts` / Piper TTS** | On-device voice synthesis (or server-backed cached neural TTS) producing child-friendly natural voice |
| **Hardware Bridge** | **WebSockets / HTTP REST / mDNS** | Low-latency bi-directional sync between App and Rafiki's Raspberry Pi (movement, battery, status) |
| **State & Storage** | **Flutter Riverpod / Bloc + SQLite (Mobile) & PostgreSQL/SQLite (FastAPI)** | Clean reactive state management & persistent owner/child data |

---

## 📐 4. Code Quality & Architectural Principles

1. **Clean Separation of Concerns (SoC):**
   - **Flutter:** Feature-first directory structure (`features/voice_interaction`, `features/raspberry_connect`, `features/owner_dashboard`). Decouple UI Widgets from Services and Repositories.
   - **FastAPI:** Clean API Router split (`api/v1/endpoints/`), Services for AI/Audio processing, and Pydantic validation schemas.
2. **Type Safety & Zero Secrets in Code:**
   - All environment variables (`SECRET_KEY`, `RAFIKI_PI_IP`, `API_KEYS`) must be loaded from `.env`. Zero hardcoded credentials.
3. **Resilient Hardware Connectivity:**
   - Auto-reconnect mechanisms for WebSocket & mDNS discovery of the Raspberry Pi.
   - Graceful offline fallback (app can still play cached TTS or basic local voice responses if offline).
4. **Child Safety & UX Polish:**
   - Soft, playful, and responsive visual design (glassmorphism/vibrant friendly aesthetics).
   - Audio feedback for all touch interactions.
