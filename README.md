# Flutter MCP Demo 🎨

A Flutter app demonstrating **AI tool calling** with local **Ollama** models. Draw shapes on canvas using natural language commands.

## 📦 Packages Used

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
