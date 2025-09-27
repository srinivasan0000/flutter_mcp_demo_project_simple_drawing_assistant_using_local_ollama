import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MCPService {
  static const String _ollamaBaseUrl = 'http://localhost:11434';
  
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
    // No initialization needed for HTTP-based approach
  }

  /// Generate shape drawing instructions from chat input using Ollama
  Future<ShapeInstruction> generateShapeFromChat(String userInput) async {
    try {
      // Create a structured prompt for shape generation
      final prompt = _buildShapeGenerationPrompt(userInput);
      
      // Send request to Ollama via HTTP
      final response = await _sendOllamaRequest(prompt);

      // Parse the response to extract shape instructions
      return _parseShapeInstructions(response);
    } catch (e) {
      debugPrint('Error generating shape from chat: $e');
      return ShapeInstruction.defaultCircle();
    }
  }

  /// Stream-based chat for real-time interaction
  Stream<String> chatStream(String message) async* {
    try {
      final prompt = _buildConversationalPrompt(message);
      
      // For web compatibility, we'll use a single request instead of streaming
      final response = await _sendOllamaRequest(prompt);
      yield response;
      
    } catch (e) {
      yield 'Error: $e';
    }
  }

  /// Check available models on Ollama instance
  Future<List<String>> getAvailableModels() async {
    try {
      if (kIsWeb) {
        // For web, return the static list due to CORS limitations
        return availableModels;
      }
      
      final response = await http.get(Uri.parse('$_ollamaBaseUrl/api/tags'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List?;
        return models?.map((model) => model['name'] as String).toList() ?? availableModels;
      }
      return availableModels;
    } catch (e) {
      debugPrint('Error getting available models: $e');
      return availableModels;
    }
  }

  /// Send request to Ollama API
  Future<String> _sendOllamaRequest(String prompt) async {
    if (kIsWeb) {
      // For web demo, return a mock response to avoid CORS issues
      return _getMockResponse(prompt);
    }

    try {
      final response = await http.post(
        Uri.parse('$_ollamaBaseUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': defaultModel,
          'prompt': prompt,
          'stream': false,
          'options': {
            'temperature': 0.7,
            'top_p': 0.9,
            'top_k': 40,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? '';
      } else {
        throw Exception('Ollama request failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending Ollama request: $e');
      return _getMockResponse(prompt);
    }
  }

  /// Get mock response for web or when Ollama is not available
  String _getMockResponse(String prompt) {
    // Enhanced pattern matching for demo purposes
    final input = prompt.toLowerCase();
    
    // Extract color from input
    String color = "#2196F3"; // Default blue
    String colorName = "blue";
    
    if (input.contains('red')) {
      color = "#FF0000";
      colorName = "red";
    } else if (input.contains('blue')) {
      color = "#0000FF";
      colorName = "blue";
    } else if (input.contains('green')) {
      color = "#00FF00";
      colorName = "green";
    } else if (input.contains('yellow')) {
      color = "#FFFF00";
      colorName = "yellow";
    } else if (input.contains('purple')) {
      color = "#800080";
      colorName = "purple";
    } else if (input.contains('orange')) {
      color = "#FFA500";
      colorName = "orange";
    } else if (input.contains('pink')) {
      color = "#FFC0CB";
      colorName = "pink";
    } else if (input.contains('black')) {
      color = "#000000";
      colorName = "black";
    } else if (input.contains('white')) {
      color = "#FFFFFF";
      colorName = "white";
    }
    
    // Extract size modifiers
    double sizeMultiplier = 1.0;
    if (input.contains('small') || input.contains('tiny')) {
      sizeMultiplier = 0.6;
    } else if (input.contains('large') || input.contains('big')) {
      sizeMultiplier = 1.5;
    }
    
    // Generate random position to avoid overlapping
    final x = 150 + (DateTime.now().millisecondsSinceEpoch % 300);
    final y = 150 + (DateTime.now().microsecondsSinceEpoch % 200);
    
    // Determine shape type and generate response
    if (input.contains('circle')) {
      final radius = (50 * sizeMultiplier).round();
      return '''
{
  "type": "circle",
  "properties": {
    "x": $x,
    "y": $y,
    "radius": $radius,
    "color": "$color",
    "strokeWidth": 2
  },
  "description": "${colorName.substring(0, 1).toUpperCase() + colorName.substring(1)} circle"
}''';
    } else if (input.contains('rectangle') || input.contains('square')) {
      final width = (100 * sizeMultiplier).round();
      final height = input.contains('square') ? width : (60 * sizeMultiplier).round();
      final shapeType = input.contains('square') ? 'square' : 'rectangle';
      return '''
{
  "type": "rectangle",
  "properties": {
    "x": $x,
    "y": $y,
    "width": $width,
    "height": $height,
    "color": "$color",
    "strokeWidth": 2
  },
  "description": "${colorName.substring(0, 1).toUpperCase() + colorName.substring(1)} $shapeType"
}''';
    } else if (input.contains('triangle')) {
      final size = (80 * sizeMultiplier).round();
      return '''
{
  "type": "triangle",
  "properties": {
    "x": $x,
    "y": $y,
    "width": $size,
    "height": $size,
    "color": "$color",
    "strokeWidth": 2
  },
  "description": "${colorName.substring(0, 1).toUpperCase() + colorName.substring(1)} triangle"
}''';
    } else {
      // Default response for conversational prompts
      return "I understand you want to draw something. Try asking me to 'draw a red circle', 'create a blue rectangle', 'make a green triangle', or specify colors like yellow, purple, orange!";
    }
  }

  String _buildShapeGenerationPrompt(String userInput) {
    return '''
You are an AI assistant that converts natural language descriptions into shape drawing instructions.
Given the user input, respond ONLY with a JSON object containing shape instructions.

User input: "$userInput"

Extract colors, sizes, and shapes from the input. Use these color mappings:
- red: #FF0000, blue: #0000FF, green: #00FF00, yellow: #FFFF00
- purple: #800080, orange: #FFA500, pink: #FFC0CB, black: #000000
- white: #FFFFFF, gray: #808080

For sizes: small (0.6x), normal (1x), large (1.5x)
Vary positions slightly to avoid overlap: x: 150-450, y: 150-350

Respond with a JSON object in this exact format:
{
  "type": "circle|rectangle|triangle|square",
  "properties": {
    "x": number (center x: 150-450),
    "y": number (center y: 150-350),
    "width": number (for rectangle) or "radius": number (for circle),
    "height": number (for rectangle only),
    "color": "hex color code based on user input",
    "strokeWidth": 2,
  },
  "description": "Color and shape name from input"
}

Examples:
- "Draw a red circle" -> {"type": "circle", "properties": {"x": 250, "y": 200, "radius": 50, "color": "#FF0000", "strokeWidth": 2}, "description": "Red circle"}
- "Make a blue rectangle" -> {"type": "rectangle", "properties": {"x": 300, "y": 250, "width": 100, "height": 60, "color": "#0000FF", "strokeWidth": 2}, "description": "Blue rectangle"}
- "Draw a small green triangle" -> {"type": "triangle", "properties": {"x": 200, "y": 180, "width": 48, "height": 48, "color": "#00FF00", "strokeWidth": 2}, "description": "Small green triangle"}
- "Create a large yellow square" -> {"type": "rectangle", "properties": {"x": 350, "y": 220, "width": 120, "height": 120, "color": "#FFFF00", "strokeWidth": 2}, "description": "Large yellow square"}

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
      debugPrint('Error parsing shape instructions: $e');
      debugPrint('Raw response: $response');
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
    
    // Generate coordinates for any shape type dynamically
    final coordinatePaths = _generateCoordinatePaths();
    
    return DrawableShape(
      type: type,
      coordinatePaths: coordinatePaths,
      color: color,
      strokeWidth: strokeWidth,
      description: description,
      filled: true,
    );
  }
  
  // Generate coordinate paths for any shape type
  List<List<Offset>> _generateCoordinatePaths() {
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
          Offset(x - width/2, y - height/2),
          Offset(x + width/2, y - height/2),
          Offset(x + width/2, y + height/2),
          Offset(x - width/2, y + height/2),
          Offset(x - width/2, y - height/2),
        ]];
      
      case 'triangle':
        final size = (properties['width'] ?? 80.0).toDouble();
        return [[
          Offset(x, y - size/2),
          Offset(x - size/2, y + size/2),
          Offset(x + size/2, y + size/2),
          Offset(x, y - size/2),
        ]];
      
      default:
        // Default to a simple circle
        return [_generateCircleCoordinates(x, y, 50.0)];
    }
  }
  
  // Generate circle coordinates as a polygon approximation
  List<Offset> _generateCircleCoordinates(double centerX, double centerY, double radius) {
    List<Offset> coords = [];
    const int segments = 20; // Number of segments to approximate circle
    
    for (int i = 0; i <= segments; i++) {
      final angle = (i * 2 * 3.14159) / segments;
      final x = centerX + radius * _cos(angle);
      final y = centerY + radius * _sin(angle);
      coords.add(Offset(x, y));
    }
    return coords;
  }
  
  // Simple cosine approximation
  double _cos(double angle) {
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
  
  // Simple sine approximation using cos(x - π/2) = sin(x)
  double _sin(double angle) {
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
  final List<List<Offset>> coordinatePaths; // Coordinate arrays for drawing any shape
  final Color color;
  final double strokeWidth;
  final String description;
  final bool filled; // Whether to fill the shape
  final Color? outlineColor; // Separate outline color

  DrawableShape({
    required this.type,
    required this.coordinatePaths,
    required this.color,
    required this.strokeWidth,
    required this.description,
    this.filled = true,
    this.outlineColor,
  });

  /// Create a copy with modified properties
  DrawableShape copyWith({
    String? type,
    List<List<Offset>>? coordinatePaths,
    Color? color,
    double? strokeWidth,
    String? description,
    bool? filled,
    Color? outlineColor,
  }) {
    return DrawableShape(
      type: type ?? this.type,
      coordinatePaths: coordinatePaths ?? this.coordinatePaths,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      description: description ?? this.description,
      filled: filled ?? this.filled,
      outlineColor: outlineColor ?? this.outlineColor,
    );
  }
}
