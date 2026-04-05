# AuraPlan AI 🌟

**Your intelligent daily planner — powered by AI**

> Live Demo → **[https://shubhangilokhande123.github.io/Intelligent-Health-Planner/](https://shubhangilokhande123.github.io/Intelligent-Health-Planner/)**

---

## ✨ Features

| Feature | Description |
|---|---|
| 🗓 **AI Schedule** | Add weekday & weekend tasks with smart time sorting |
| 💧 **Hydration Tracker** | Log water intake with a 3D orb visual and smart AI reminders |
| 🤖 **AuraBot Voice Assistant** | Add tasks hands-free via voice or keyboard |
| 🧠 **AI Insights** | Real-time productivity & wellness tips via Groq LLaMA 3.1 |
| 🌙 **Dark / Light / System Mode** | Full theme switching |
| 📊 **Daily Summary** | AI-generated evening wrap-up at 9 PM |
| 🎭 **AI Personality** | Choose from Sage, Coach, Friend, Guru, or Mentor |
| 📍 **Geolocation** | Shows your area in the upcoming schedule card |
| 🔔 **Smart Notifications** | Task alarms + smart hydration nudges |
| 📱 **Fully Responsive** | Mobile, iPad, and Desktop layouts |

---

## 🚀 Tech Stack

- **Frontend** — Pure HTML + CSS + Vanilla JavaScript
- **Styling** — Tailwind CSS (CDN), Google Fonts (Manrope + Inter), Material Symbols
- **AI** — Groq API (LLaMA 3.1 8B) with OpenRouter fallback
- **TTS** — Web Speech API (browser-native)
- **Audio** — Web Audio API (custom alarm sounds synthesized in-browser)
- **Hosting** — GitHub Pages

---

## 📸 Screenshots

| Landing | Home Dashboard | Schedule |
|---|---|---|
| Aurora gradient hero with 3D orb | Bento grid · Water · Goals · AI Insight | Monthly calendar + task cards |

---

## 🏁 Getting Started (Local)

```bash
# Clone the repo
git clone https://github.com/ShubhangiLokhande123/Intelligent-Health-Planner.git
cd Intelligent-Health-Planner

# Serve locally (Python)
python -m http.server 8081
# Open http://localhost:8081
```

---

## 📦 Deploy Updates

```bash
git add -A
git commit -m "update"
git push
```

GitHub Pages auto-deploys from the `main` branch within ~60 seconds.

---

## 🔑 API Keys

The app uses free-tier endpoints. To use your own:

| Key | Location in `index.html` |
|---|---|
| `GROQ_KEY` | `const GROQ_KEY = '...'` |
| `OPENROUTER_KEY` | `const OPENROUTER_KEY = '...'` |

---

## 📄 License

MIT © 2025 ShubhangiLokhande123
