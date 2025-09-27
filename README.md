# MCP Flutter Drawing Assistant

A Flutter application that demonstrates Model Context Protocol (MCP) integration with Ollama local AI models to generate and draw shapes based on natural language chat input.

## Overview

This application combines the power of local AI models (via Ollama) with Flutter's drawing capabilities to create an intelligent shape drawing assistant. Users can chat with an AI assistant to create various shapes on a canvas.

## Features

- 🤖 **AI-Powered Shape Generation**: Use natural language to describe shapes you want to draw
- 🎨 **Interactive Canvas**: Draw shapes manually or via AI instructions
- 💬 **Chat Interface**: Real-time conversation with AI assistant
- 🔧 **Local AI Models**: Uses Ollama for completely offline AI processing
- 📱 **Cross-Platform**: Runs on iOS, Android, macOS, Windows, Linux, and Web
- 🎭 **Multiple Shapes**: Supports circles, rectangles, triangles, and more
- 🎨 **Customizable**: Different colors, sizes, and stroke widths
- 📋 **Shape Management**: View, list, and delete created shapes

## Architecture

### Key Components

1. **MCPService** (`lib/services/mcp_service.dart`)
   - Integrates with Ollama API using `ollama_dart` package
   - Converts natural language to shape instructions
   - Handles streaming chat conversations

2. **MCPProvider** (`lib/providers/mcp_provider.dart`)
   - State management using Provider pattern
   - Manages drawing canvas state and chat history
   - Coordinates between UI and MCP service

3. **ShapePainter** (`lib/widgets/shape_painter.dart`)
   - Custom Flutter painter for rendering shapes
   - Handles touch interactions for manual drawing
   - Supports various shape types and styling

4. **MCPDrawingScreen** (`lib/screens/mcp_drawing_screen.dart`)
   - Main UI combining canvas and chat interface
   - Responsive layout with collapsible panels
   - Real-time shape and chat management

## Chosen Packages

Based on research from pub.dev, the following packages were selected:

### Core MCP Integration
- **`mcp_dart: ^0.6.2`** - Dart implementation of Model Context Protocol SDK
  - Most actively maintained (updated 5 days ago)
  - 47 likes, verified publisher
  - Full MCP standard compliance

### Ollama Integration
- **`ollama_dart: ^0.2.5`** - Ollama client for Dart/Flutter
  - 77 likes, verified publisher (langchaindart.dev)
  - Recent updates (26 days ago)
  - Supports streaming and various model types

### Drawing and Canvas
- **`flutter_drawing_board: ^0.9.8`** - Drawing board implementation
  - 245 likes, verified publisher (fluttercandies.com)
  - Comprehensive drawing tools and canvas operations
  - Image data acquisition capabilities

- **`path_drawing: ^1.0.1`** - Path creation and manipulation
  - 216 likes, verified publisher
  - Essential for complex shape drawing

### Additional Packages
- **`provider: ^6.1.1`** - State management
- **`http: ^1.1.0`** - HTTP requests
- **`json_annotation: ^4.8.1`** - JSON serialization

## Prerequisites

1. **Flutter**: Ensure Flutter is installed on your system
2. **Ollama**: Install and set up Ollama with desired models

### Available Models (detected in your system)

Your Ollama instance has the following models available:
- `llama3.1:latest` (4.9 GB) - **Default model used**
- `mistral:latest` (4.4 GB)
- `gemma3:latest` (3.3 GB)
- `mxbai-embed-large:latest` (669 MB) - Embedding model
- `all-minilm:latest` (45 MB) - Lightweight embedding model
- `nomic-embed-text:latest` (274 MB) - Text embedding model

## Installation & Setup

1. **Start Ollama service**:
```bash
ollama serve
```

2. **Install dependencies**:
```bash
flutter pub get
```

3. **Run the application**:
```bash
flutter run
```

## Usage Guide

### Basic Usage

1. **Start the Application**: Launch the Flutter app
2. **Ensure Ollama is Running**: The app connects to `http://localhost:11434`
3. **Chat with AI**: Use the chat interface at the bottom of the screen

### Example Commands

Try these natural language commands:

```
"Draw a red circle"
"Create a blue rectangle" 
"Make a green triangle"
"Add a yellow square with thick borders"
"Draw a small purple circle in the center"
"Create a large orange rectangle"
```

### Manual Drawing

- **Drag on Canvas**: Create rectangles manually by dragging
- **Shape Panel**: Toggle the shapes list to see all created shapes
- **Delete Shapes**: Use the delete button on individual shapes
- **Clear Canvas**: Use the clear button to remove all shapes

### Advanced Features

- **Real-time Chat**: The AI responds in real-time to questions and requests
- **Shape Customization**: Specify colors, sizes, and positions in natural language
- **Export Data**: Shape data can be exported as JSON (feature in provider)
- **Multiple Models**: Easily switch between different Ollama models

## Technical Implementation

### Shape Generation Flow

1. **User Input**: Natural language description via chat
2. **AI Processing**: Ollama processes the request using LLaMA 3.1
3. **JSON Parsing**: AI response is parsed into shape instructions
4. **Shape Creation**: Instructions converted to `DrawableShape` objects
5. **Canvas Rendering**: Custom painter renders shapes on Flutter canvas

### MCP Integration

The application implements MCP (Model Context Protocol) concepts:

- **Client-Server Communication**: Flutter app acts as MCP client
- **Tool Integration**: Shape drawing as an AI tool/capability
- **Context Management**: Chat history and canvas state as context
- **Structured Responses**: JSON-based shape instructions

## Troubleshooting

### Common Issues

1. **Ollama Connection Failed**
   - Ensure Ollama is running: `ollama serve`
   - Check if models are available: `ollama list`
   - Verify port 11434 is accessible

2. **AI Responses Not Parsed**
   - Check console for JSON parsing errors
   - Ensure model is compatible with structured outputs
   - Try simpler shape descriptions

## Future Enhancements

- [ ] **Advanced Shape Types**: Bezier curves, polygons, paths
- [ ] **Shape Animation**: Animate shape creation and transformations
- [ ] **Voice Input**: Voice-to-text for hands-free drawing
- [ ] **Collaborative Drawing**: Multi-user canvas sharing
- [ ] **Export Formats**: SVG, PDF, PNG export capabilities

---

**Powered by**: Flutter 🚀 | Ollama 🤖 | Model Context Protocol 🔗
