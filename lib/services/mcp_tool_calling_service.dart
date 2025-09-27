import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ollama_dart/ollama_dart.dart';

/// Universal MCP Tool Calling Service for coordinate-based drawing using ollama_dart
class MCPToolCallingService {
  late final OllamaClient _client;
  static const String defaultModel = 'llama3.1:latest';
  
  MCPToolCallingService() {
    _client = OllamaClient(
      baseUrl: 'http://localhost:11434/api',
    );
  }

  /// Generate tool calling request with user input
  Future<List<DrawableShape>> processToolCallingRequest(String userInput) async {
    try {
      print('🔵 USER INPUT: "$userInput"');
      print('🦙 SENDING REQUEST TO OLLAMA MODEL: $defaultModel');
      
      // Define the drawing tool
      final drawTool = Tool(
        function: ToolFunction(
          name: 'draw_coordinates',
          description: 'Draw any shape or object by providing coordinate arrays. Can create ANY visual element - geometric shapes, complex objects, symbols, characters, animals, buildings, vehicles, faces, or abstract designs.',
          parameters: {
            'type': 'object',
            'properties': {
              'description': {
                'type': 'string',
                'description': 'What is being drawn (e.g., "triangle", "house", "car", "face", "tree", "heart", "star", "flower")'
              },
              'paths': {
                'type': 'array',
                'description': 'Array of coordinate paths. Each path is an array of [x,y] coordinate pairs that define lines, curves, or shapes to draw',
                'items': {'type': 'array'}
              },
              'color': {
                'type': 'string',
                'description': 'Primary color as hex code (e.g., #FF0000, #00FF00, #0000FF)'
              },
              'strokeWidth': {
                'type': 'number',
                'description': 'Line thickness (1-8)',
                'default': 2
              },
              'filled': {
                'type': 'boolean',
                'description': 'Whether to fill closed shapes',
                'default': true
              },
              'fillColor': {
                'type': 'string',
                'description': 'Fill color if different from stroke color (optional)'
              },
            },
            'required': ['description', 'paths', 'color'],
          },
        ),
      );

      // Create system message with drawing instructions
      final systemMessage = Message(
        role: MessageRole.system,
        content: '''You are an AI drawing assistant that creates ANY visual element by generating precise coordinate paths. You must provide actual coordinate arrays to draw shapes, objects, symbols, or any visual element.

COORDINATE DRAWING SYSTEM:
- Canvas bounds: x: 50-550, y: 50-450
- Provide coordinate arrays [x,y] that define the exact paths to draw
- Each path is an array of coordinate pairs that will be connected with lines
- For closed shapes, ensure the last point connects back to the first
- For complex objects, use multiple paths

DRAWING CAPABILITIES:
✓ Basic shapes: triangles, squares, circles, stars, hearts, arrows
✓ Objects: houses, cars, trees, flowers, faces, animals
✓ Symbols: logos, icons, mathematical symbols, letters
✓ Complex drawings: buildings, vehicles, characters, abstract art

COLOR CODES:
red: #FF0000, blue: #0000FF, green: #00FF00, yellow: #FFFF00
purple: #800080, orange: #FFA500, pink: #FF69B4, brown: #8B4513
black: #000000, white: #FFFFFF, gray: #808080, cyan: #00FFFF

EXAMPLES:
- triangle: paths: [[[300,150], [200,350], [400,350], [300,150]]]
- heart: paths: [[[300,320], [280,290], [250,260], [250,230], [270,210], [300,230], [330,210], [350,230], [350,260], [320,290], [300,320]]]
- star: paths: [[[300,150], [315,200], [370,200], [330,235], [345,290], [300,260], [255,290], [270,235], [230,200], [285,200], [300,150]]]
- house: paths: [[[200,350], [400,350], [400,250], [200,250], [200,350]], [[200,250], [300,150], [400,250]]]

Always use the draw_coordinates tool to respond.''',
      );

      // Create user message
      final userMessage = Message(
        role: MessageRole.user,
        content: userInput,
      );

      // Generate response with tool calling
      final response = await _client.generateChatCompletion(
        request: GenerateChatCompletionRequest(
          model: defaultModel,
          messages: [systemMessage, userMessage],
          tools: [drawTool],
          options: const RequestOptions(
            temperature: 0.1,
            topP: 0.9,
            topK: 40,
          ),
        ),
      );
      
      print('✅ OLLAMA RESPONSE RECEIVED');
      print('📝 Tool calls count: ${response.message.toolCalls?.length ?? 0}');
      
      final shapes = <DrawableShape>[];
      
      // Process tool calls
      if (response.message.toolCalls != null) {
        for (final toolCall in response.message.toolCalls!) {
          if (toolCall.function != null) {
            print('🔧 Processing tool call: ${toolCall.function!.name}');
            print('📋 Arguments: ${toolCall.function!.arguments}');
            
            if (toolCall.function!.name == 'draw_coordinates') {
              final shape = _createFromCoordinates(toolCall.function!.arguments);
              if (shape != null) {
                shapes.add(shape);
              }
            }
          }
        }
      }
      
      print('🎨 ADDED ${shapes.length} SHAPES TO CANVAS');
      
      return shapes;
    } catch (e) {
      debugPrint('Error processing tool calling request: $e');
      return [];
    }
  }

  /// Create shape from coordinate arguments
  DrawableShape? _createFromCoordinates(Map<String, dynamic> args) {
    try {
      print('🎨 Creating from coordinates: $args');
      
      final description = args['description'] as String;
      var pathsData = args['paths'];
      final color = _parseColor(args['color'] as String);
      final strokeWidth = (args['strokeWidth'] as num?)?.toDouble() ?? 2.0;
      final filled = args['filled'] as bool? ?? true;
      final fillColor = args['fillColor'] != null ? _parseColor(args['fillColor'] as String) : color;
      
      // Convert coordinate arrays to Offset points
      List<List<Offset>> paths = [];
      
      // Handle different formats of paths data
      if (pathsData is String) {
        // If paths is a string, try to parse it as JSON
        try {
          final parsedPaths = jsonDecode(pathsData) as List;
          pathsData = parsedPaths;
        } catch (e) {
          print('Could not parse paths string: $pathsData');
          return null;
        }
      }
      
      if (pathsData is List) {
        for (final pathData in pathsData) {
          List<Offset> points = [];
          if (pathData is List) {
            for (final coord in pathData) {
              if (coord is List && coord.length >= 2) {
                points.add(Offset(
                  (coord[0] as num).toDouble(),
                  (coord[1] as num).toDouble(),
                ));
              }
            }
          }
          if (points.isNotEmpty) {
            paths.add(points);
          }
        }
      }
      
      print('🎨 Converted to ${paths.length} paths with ${paths.fold(0, (sum, path) => sum + path.length)} total points');
      
      if (paths.isEmpty) {
        print('🚨 No valid paths found!');
        return null;
      }
      
      return DrawableShape(
        type: description,
        coordinatePaths: paths,
        color: filled ? fillColor : color,
        strokeWidth: strokeWidth,
        description: description,
        filled: filled,
        outlineColor: color,
      );
    } catch (e) {
      debugPrint('Error creating shape from coordinates: $e');
      return null;
    }
  }

  /// Parse color string to Color object
  Color _parseColor(String colorStr) {
    final cleanColor = colorStr.trim().toLowerCase();
    
    // Handle hex colors
    if (cleanColor.startsWith('#')) {
      String hex = cleanColor.substring(1);
      if (hex.length == 6) {
        return Color(int.parse('ff$hex', radix: 16));
      }
    }
    
    // Handle named colors
    switch (cleanColor) {
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'yellow': return Colors.yellow;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      case 'pink': return Colors.pink;
      case 'brown': return Colors.brown;
      case 'black': return Colors.black;
      case 'white': return Colors.white;
      case 'gray': case 'grey': return Colors.grey;
      default: return Colors.blue; // Default fallback
    }
  }

  /// Dispose resources
  void dispose() {
    _client.endSession();
  }
}

/// Dynamic drawable shape class for coordinate-based drawing
class DrawableShape {
  final String type; // Dynamic type - can be any description: "triangle", "house", "star", etc.
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
}
