# Fl## 📸 App Screenshots

<div align="center">
  <img src="https://raw.githubusercontent.com/srinivasan0000/flutter_mcp_demo_project_simple_drawing_assistant_using_local_ollama/main/screenshots/Screenshot%202025-09-28%20at%205.54.00%E2%80%AFPM.png" alt="Flutter MCP Demo " width="700"/>
  <p><em>Main app interface with canvas and chat functionality</em></p>
</div>

<div align="center">
  <img src="https://raw.githubusercontent.com/srinivasan0000/flutter_mcp_demo_project_simple_drawing_assistant_using_local_ollama/main/screenshots/Screenshot%202025-09-28%20at%205.55.22%E2%80%AFPM.png" alt="Flutter MCP Demo" width="700"/>
  <p><em>AI-powered shape generation in action</em></p>
</div>emo 🎨

A Flutter app demonstrating **AI tool calling** with local **Ollama** models. Draw shapes on canvas using natural language commands.

## � App Screenshots

<div align="center">
  <img src="screenshots/Screenshot 2025-09-28 at 5.54.00 PM.png" alt="Flutter MCP Demo - Main Interface" width="700"/>
  <p><em>Main app interface with canvas and chat functionality</em></p>
</div>

<div align="center">
  <img src="screenshots/Screenshot 2025-09-28 at 5.55.22 PM.png" alt="Flutter MCP Demo - Shape Generation" width="700"/>
  <p><em>AI-powered shape generation in action</em></p>
</div>

## �📦 Packages Used

- **`ollama_dart: ^0.2.5`** - Ollama integration for local LLM
- **`provider: ^6.1.1`** - State management
- **`flutter`** - UI framework

## � Quick Start

### 1. Setup Ollama
```bash
brew install ollama
ollama pull llama3.1:latest  
ollama serve
```

### 2. Run App
```bash
flutter pub get
flutter run
```

### 3. Try Commands
- "draw a green circle"
- "draw a red square"
- "draw a blue triangle"

## 🎯 How It Works

1. User types shape request
2. Ollama AI calls `draw_coordinates` tool 
3. Coordinates parsed and rendered on canvas

## 🎨 Supported Shapes

Circle, Square, Triangle, Rectangle, Heart, Star, Oval

**Colors**: red, blue, green, orange, purple, pink, yellow

## � Troubleshooting

**Ollama not running?**
```bash
ollama serve
```

**Model missing?**
```bash
ollama pull llama3.1:latest
```

---

**Built with Flutter & Ollama**
