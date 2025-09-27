import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ollama_dart/ollama_dart.dart' as ollama;

class MCPService {
  static const String _ollamaBaseUrl = 'http://localhost:11434';
  late final ollama.OllamaClient _ollamaClient;
  
  // Available models from your Ollama instance
  static const String defaultModel = 'llama3.1:latest';
  static const List<String> availableModels = [
    'llama3.1:latest',
    'mistral:latest', 
    'gemma3:latest',
  ];

  MCPService() {
    _initializeClients();
  }

  void _initializeClients() {
    // Initialize Ollama client (default to localhost:11434)
    _ollamaClient = ollama.OllamaClient(
      baseUrl: 'http://localhost:11434',
    );
  }

  /// Generate shape drawing instructions from chat input using Ollama
  Future<ShapeInstruction> generateShapeFromChat(String userInput) async {
    try {
      // Create a structured prompt for shape generation
      final prompt = _buildShapeGenerationPrompt(userInput);
      
      // Send request to Ollama
      final response = await _ollamaClient.generateCompletion(
        request: ollama.GenerateCompletionRequest(
          model: defaultModel,
          prompt: prompt,
          options: const ollama.RequestOptions(
            temperature: 0.7,
            topP: 0.9,
            topK: 40,
          ),
        ),
      );

      // Parse the response to extract shape instructions
      return _parseShapeInstructions(response.response ?? '');
    } catch (e) {
      // Return default shape on error
      return ShapeInstruction.defaultCircle();
    }
  }

  /// Stream-based chat for real-time interaction
  Stream<String> chatStream(String message) async* {
    try {
      final prompt = _buildConversationalPrompt(message);
      
      final stream = _ollamaClient.generateCompletionStream(
        request: ollama.GenerateCompletionRequest(
          model: defaultModel,
          prompt: prompt,
          options: const ollama.RequestOptions(
            temperature: 0.8,
            topP: 0.9,
          ),
        ),
      );

      await for (final response in stream) {
        if (response.response != null) {
          yield response.response!;
        }
      }
    } catch (e) {
      yield 'Error: $e';
    }
  }

  /// Check available models on Ollama instance
  Future<List<String>> getAvailableModels() async {
    try {
      final response = await _ollamaClient.listModels();
      return response.models?.map((model) => model.model ?? '').toList() ?? availableModels;
    } catch (e) {
      // Return fallback models on error
      return availableModels;
    }
  }

  String _buildShapeGenerationPrompt(String userInput) {
    return '''
You are an AI assistant that converts natural language descriptions into shape drawing instructions.
Given the user input, respond ONLY with a JSON object containing shape instructions.

User input: "$userInput"

Respond with a JSON object in this exact format:
{
  "type": "circle|rectangle|triangle|line|polygon|path",
  "properties": {
    "x": number (center x or start x),
    "y": number (center y or start y),
    "width": number (for rectangle) or "radius": number (for circle),
    "height": number (for rectangle only),
    "color": "hex color code (e.g., #FF0000)",
    "strokeWidth": number,
    "points": [{"x": number, "y": number}] (for polygon/path only)
  },
  "description": "Brief description of what was drawn"
}

Examples:
- "Draw a red circle" -> {"type": "circle", "properties": {"x": 200, "y": 200, "radius": 50, "color": "#FF0000", "strokeWidth": 2}, "description": "Red circle"}
- "Make a blue rectangle" -> {"type": "rectangle", "properties": {"x": 150, "y": 150, "width": 100, "height": 60, "color": "#0000FF", "strokeWidth": 2}, "description": "Blue rectangle"}
- "Draw a green triangle" -> {"type": "triangle", "properties": {"x": 200, "y": 150, "width": 80, "height": 80, "color": "#00FF00", "strokeWidth": 2}, "description": "Green triangle"}

Respond ONLY with valid JSON, no additional text.
''';
  }

  String _buildConversationalPrompt(String message) {
    return '''
You are a helpful AI assistant in a drawing application. The user can ask you to:
1. Draw shapes (circle, rectangle, triangle, line, etc.)
2. Change colors or properties of shapes
3. Ask questions about drawing or the application
4. Get help with shape creation

User message: "$message"

Respond naturally and helpfully. If the user wants to draw something, acknowledge it and explain what will be drawn.
''';
  }

  ShapeInstruction _parseShapeInstructions(String response) {
    try {
      // Try to extract JSON from the response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch == null) {
        return ShapeInstruction.defaultCircle();
      }

      final jsonStr = jsonMatch.group(0)!;
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      return ShapeInstruction.fromJson(json);
    } catch (e) {
      // Return default shape if parsing fails
      return ShapeInstruction.defaultCircle();
    }
  }

  void dispose() {
    // Clean up resources if needed
  }
}

/// Data class for shape drawing instructions
class ShapeInstruction {
  final String type;
  final Map<String, dynamic> properties;
  final String description;

  ShapeInstruction({
    required this.type,
    required this.properties,
    required this.description,
  });

  factory ShapeInstruction.fromJson(Map<String, dynamic> json) {
    return ShapeInstruction(
      type: json['type'] ?? 'circle',
      properties: json['properties'] ?? {},
      description: json['description'] ?? 'Shape',
    );
  }

  factory ShapeInstruction.defaultCircle() {
    return ShapeInstruction(
      type: 'circle',
      properties: {
        'x': 200.0,
        'y': 200.0,
        'radius': 50.0,
        'color': '#2196F3',
        'strokeWidth': 2.0,
      },
      description: 'Default blue circle',
    );
  }

  // Convert to drawable shape data using coordinate-based approach
  DrawableShape toDrawableShape() {
    final color = _parseColor(properties['color'] ?? '#2196F3');
    final strokeWidth = (properties['strokeWidth'] ?? 2.0).toDouble();
    
    // Extract coordinate points from properties
    List<List<double>> coordinatePaths = [];
    
    if (properties.containsKey('points') && properties['points'] is List) {
      // If points are provided as array of coordinate pairs
      final points = properties['points'] as List;
      final coords = <double>[];
      for (var point in points) {
        if (point is Map) {
          coords.add((point['x'] ?? 0.0).toDouble());
          coords.add((point['y'] ?? 0.0).toDouble());
        }
      }
      if (coords.isNotEmpty) {
        coordinatePaths.add(coords);
      }
    } else {
      // Generate basic coordinates for simple shapes
      coordinatePaths = _generateBasicShapeCoordinates();
    }
    
    return DrawableShape(
      type: type,
      coordinatePaths: coordinatePaths,
      color: color,
      strokeWidth: strokeWidth,
      description: description,
      filled: true,
    );
  }
  
  // Generate basic coordinates for simple shapes when no points provided
  List<List<double>> _generateBasicShapeCoordinates() {
    final x = (properties['x'] ?? 200.0).toDouble();
    final y = (properties['y'] ?? 200.0).toDouble();
    
    switch (type.toLowerCase()) {
      case 'circle':
        final radius = (properties['radius'] ?? 50.0).toDouble();
        return [_generateCircleCoordinates(x, y, radius)];
      
      case 'rectangle':
        final width = (properties['width'] ?? 100.0).toDouble();
        final height = (properties['height'] ?? 60.0).toDouble();
        return [[
          x - width/2, y - height/2,
          x + width/2, y - height/2,
          x + width/2, y + height/2,
          x - width/2, y + height/2,
          x - width/2, y - height/2,
        ]];
      
      case 'triangle':
        final size = (properties['width'] ?? 80.0).toDouble();
        return [[
          x, y - size/2,
          x - size/2, y + size/2,
          x + size/2, y + size/2,
          x, y - size/2,
        ]];
      
      default:
        // Default to a simple circle
        return [_generateCircleCoordinates(x, y, 50.0)];
    }
  }
  
  // Generate circle coordinates as a polygon approximation
  List<double> _generateCircleCoordinates(double centerX, double centerY, double radius) {
    List<double> coords = [];
    const int segments = 20; // Number of segments to approximate circle
    
    for (int i = 0; i <= segments; i++) {
      final angle = (i * 2 * 3.14159) / segments;
      final x = centerX + radius * cos(angle);
      final y = centerY + radius * sin(angle);
      coords.addAll([x, y]);
    }
    return coords;
  }
  
  double cos(double angle) => _cos(angle);
  double sin(double angle) => _sin(angle);
  
  double _cos(double angle) {
    // Simple cosine approximation
    while (angle > 3.14159) angle -= 2 * 3.14159;
    while (angle < -3.14159) angle += 2 * 3.14159;
    
    if (angle.abs() < 0.01) return 1.0;
    if ((angle - 3.14159/2).abs() < 0.01) return 0.0;
    if ((angle - 3.14159).abs() < 0.01) return -1.0;
    if ((angle + 3.14159/2).abs() < 0.01) return 0.0;
    
    // Taylor series approximation for cos(x)
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i < 10; i++) {
      term *= -angle * angle / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }
  
  double _sin(double angle) {
    // Simple sine approximation using cos(x - π/2) = sin(x)
    return _cos(angle - 3.14159/2);
  }

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
      }
      return Colors.blue; // fallback
    } catch (e) {
      return Colors.blue; // fallback
    }
  }
}



/// Data class for drawable shapes - dynamic coordinate-based drawing
class DrawableShape {
  final String type; // Dynamic type - can be anything: "triangle", "house", "star", "face", etc.
  final List<List<double>> coordinatePaths; // Array of coordinate arrays for any shape
  final Color color;
  final double strokeWidth;
  final String description;
  final bool filled;

  DrawableShape({
    required this.type,
    required this.coordinatePaths,
    required this.color,
    required this.strokeWidth,
    required this.description,
    this.filled = true,
  });

  /// Create a copy with modified properties
  DrawableShape copyWith({
    String? type,
    List<List<double>>? coordinatePaths,
    Color? color,
    double? strokeWidth,
    String? description,
    bool? filled,
  }) {
    return DrawableShape(
      type: type ?? this.type,
      coordinatePaths: coordinatePaths ?? this.coordinatePaths,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      description: description ?? this.description,
      filled: filled ?? this.filled,
    );
  }
}
