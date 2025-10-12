import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ollama_dart/ollama_dart.dart';

class MCPToolCallingService {
  late final OllamaClient _client;
  static const String defaultModel = 'llama3.1:latest';

  MCPToolCallingService() {
    _client = OllamaClient(baseUrl: 'http://localhost:11434/api');
  }

  Future<List<DrawableShape>> processToolCallingRequest(
    String userInput,
  ) async {
    try {
      debugPrint('🔵 USER INPUT: "$userInput"');
      debugPrint('🦙 SENDING REQUEST TO OLLAMA MODEL: $defaultModel');

      // Define the drawing tool
      final drawTool = Tool(
        function: ToolFunction(
          name: 'draw_coordinates',
          description:
              'REQUIRED TOOL: Draw shapes using coordinate arrays. MUST be called for ANY drawing request. Supports curves for organic shapes and lines for geometric shapes.',
          parameters: {
            'type': 'object',
            'properties': {
              'description': {
                'type': 'string',
                'description':
                    'Name of what is being drawn: "Oval", "Circle", "Triangle", "Square", "Heart", etc.',
                'examples': [
                  'Oval',
                  'Circle',
                  'Triangle',
                  'Rectangle',
                  'Heart',
                  'Star',
                ],
              },
              'paths': {
                'type': 'array',
                'description':
                    'REQUIRED: Array of coordinate paths. Each path contains [x,y] coordinate pairs. For ovals/circles, use 20+ points for smoothness.',
                'items': {
                  'type': 'array',
                  'items': {'type': 'array', 'minItems': 2, 'maxItems': 2},
                },
                'minItems': 1,
              },
              'pathTypes': {
                'type': 'array',
                'description':
                    'CRITICAL: Specify drawing method for each path. Use "curve" for ovals/circles/hearts. Use "line" for triangles/squares.',
                'items': {
                  'type': 'string',
                  'enum': ['line', 'curve', 'mixed'],
                },
                'examples': [
                  ['curve'],
                  ['line'],
                  ['curve', 'line'],
                ],
              },
              'color': {
                'type': 'string',
                'description':
                    'Color as hex code: #FF0000 (red), #0000FF (blue), #00FF00 (green), #FFFF00 (yellow), #800080 (purple), #FFA500 (orange)',
                'default': '#0000FF',
              },
              'smoothness': {
                'type': 'number',
                'description':
                    'Curve smoothness: 0.1-1.0. Use 0.5-0.8 for ovals/circles, 0.3-0.5 for hearts',
                'minimum': 0.1,
                'maximum': 1.0,
                'default': 0.5,
              },
              'strokeWidth': {
                'type': 'number',
                'description': 'Line thickness (1-5)',
                'minimum': 1,
                'maximum': 5,
                'default': 2,
              },
              'filled': {
                'type': 'boolean',
                'description': 'Whether to fill the shape',
                'default': true,
              },
            },
            'required': ['description', 'paths', 'pathTypes', 'color'],
            'additionalProperties': false,
          },
        ),
      );

      final systemMessage = Message(
        role: MessageRole.system,
        content:
            '''You MUST call draw_coordinates for ALL shape requests. COPY coordinates EXACTLY - DO NOT MODIFY.

🎯 CANVAS: 600x500 pixels. Safe zone: x=100-500, y=100-400

� CRITICAL: COPY the entire coordinate array EXACTLY as written. DO NOT change any numbers.

📐 CIRCLE - COPY THIS EXACT ARRAY (starts with [380,250]):
{
  "description": "Circle",
  "paths": [[[380,250],[377,269],[368,287],[354,303],[336,317],[314,328],[290,335],[265,339],[239,339],[214,335],[190,328],[168,317],[150,303],[136,287],[127,269],[124,250],[127,231],[136,213],[150,197],[168,183],[190,172],[214,165],[239,161],[265,161],[290,165],[314,172],[336,183],[354,197],[368,213],[377,231],[380,250]]],
  "pathTypes": ["curve"],
  "color": "#00FF00",
  "filled": true,
  "strokeWidth": 2
}

🔺 TRIANGLE - Use EXACT coordinates:
{
  "description": "Triangle", 
  "paths": [[[300,150], [200,350], [400,350], [300,150]]],
  "pathTypes": ["line"],
  "color": "#FF0000",
  "filled": true,
  "strokeWidth": 2
}

🔲 SQUARE - Use EXACT coordinates:
{
  "description": "Square",
  "paths": [[[200,200], [400,200], [400,400], [200,400], [200,200]]],
  "pathTypes": ["line"], 
  "color": "#0000FF",
  "filled": true,
  "strokeWidth": 2
}

📐 RECTANGLE - Use EXACT coordinates:
{
  "description": "Rectangle",
  "paths": [[[150,200], [450,200], [450,350], [150,350], [150,200]]],
  "pathTypes": ["line"],
  "color": "#FFA500",
  "filled": true,
  "strokeWidth": 2
}

💖 HEART - Use EXACT coordinates:
{
  "description": "Heart",
  "paths": [[[300,200], [285,180], [260,170], [235,180], [220,200], [220,220], [235,240], [260,260], [285,280], [300,300], [315,280], [340,260], [365,240], [380,220], [380,200], [365,180], [340,170], [315,180], [300,200]]],
  "pathTypes": ["curve"],
  "color": "#FF69B4",
  "filled": true,
  "strokeWidth": 2
}

⭐ STAR - Use EXACT coordinates:
{
  "description": "Star",
  "paths": [[[300,150], [320,220], [390,220], [335,270], [355,340], [300,300], [245,340], [265,270], [210,220], [280,220], [300,150]]],
  "pathTypes": ["line"],
  "color": "#FFD700",
  "filled": true,
  "strokeWidth": 2
}

🔵 OVAL - Use EXACT coordinates:
{
  "description": "Oval",
  "paths": [[[400,250], [395,275], [380,297], [358,315], [330,328], [300,333], [270,328], [242,315], [220,297], [205,275], [200,250], [205,225], [220,203], [242,185], [270,172], [300,167], [330,172], [358,185], [380,203], [395,225], [400,250]]],
  "pathTypes": ["curve"],
  "color": "#9932CC",
  "filled": true,
  "strokeWidth": 2
}

🚨 CRITICAL RULES:
1. COPY coordinates exactly from examples above
2. DO NOT calculate new coordinates - use provided ones
3. For color requests: red=#FF0000, blue=#0000FF, green=#00FF00, orange=#FFA500, purple=#9932CC, pink=#FF69B4, yellow=#FFD700
4. Always set "filled": true and "strokeWidth": 2

Triangle:
{
  "description": "Triangle", 
  "paths": [[[300,100], [200,300], [400,300], [300,100]]],
  "pathTypes": ["line"],
  "color": "#FF0000",
  "strokeWidth": 2,
  "filled": true
}

Rectangle:
{
  "description": "Rectangle",
  "paths": [[[200,150], [400,150], [400,300], [200,300], [200,150]]],
  "pathTypes": ["line"], 
  "color": "#00FF00",
  "strokeWidth": 2,
  "filled": true
}

Heart (CRITICAL EXAMPLE):
{
  "description": "Heart",
  "paths": [[[300,140], [290,130], [275,125], [258,125], [245,135], [240,150], [245,170], [260,190], [280,210], [300,240], [320,210], [340,190], [355,170], [360,150], [355,135], [342,125], [325,125], [310,130], [300,140]]],
  "pathTypes": ["curve"],
  "color": "#FF0000",
  "smoothness": 0.5,
  "strokeWidth": 2,
  "filled": true
}

🚨 COORDINATE VALIDATION REQUIREMENTS:
✅ ALL x coordinates: 50 ≤ x ≤ 550 (integers only)
✅ ALL y coordinates: 50 ≤ y ≤ 450 (integers only)  
✅ NO negative coordinates: x ≥ 0, y ≥ 0
✅ NO decimal values: use Math.round() if needed
✅ Shape size: minimum 50x50 pixels for visibility
✅ Center shapes around (300, 250) when possible

📐 SCALING GUIDELINES:
- Mathematical formulas often need scaling
- Hearts: scale by 8-12x, then center
- Stars: use radius 50-100 pixels  
- Circles: radius 40-120 pixels
- All shapes must fit within safe bounds

⚠️ CRITICAL ERRORS TO AVOID:
❌ Coordinates outside canvas: x > 550, y > 450
❌ Negative coordinates: x < 0, y < 0
❌ Decimal coordinates: [300.5, 250.7]
❌ Tiny shapes: radius < 20 pixels
❌ String coordinates: ["300", "250"]
❌ Wrong array structure: [[300,250,400,300]]

🎯 MANDATORY: For ANY drawing request, call draw_coordinates tool with mathematically precise coordinates!''',
      );

      final userMessage = Message(role: MessageRole.user, content: userInput);

      final response = await _client.generateChatCompletion(
        request: GenerateChatCompletionRequest(
          model: defaultModel,
          messages: [systemMessage, userMessage],
          tools: [drawTool],
          options: const RequestOptions(temperature: 0.1, topP: 0.9, topK: 40),
        ),
      );

      debugPrint('✅ OLLAMA RESPONSE RECEIVED');
      debugPrint(
        '📝 Tool calls count: ${response.message.toolCalls?.length ?? 0}',
      );

      final shapes = <DrawableShape>[];

      if (response.message.toolCalls != null) {
        for (final toolCall in response.message.toolCalls!) {
          if (toolCall.function != null) {
            debugPrint('🔧 Processing tool call: ${toolCall.function!.name}');
            debugPrint('📋 Arguments: ${toolCall.function!.arguments}');

            if (toolCall.function!.name == 'draw_coordinates') {
              final shape = _createFromCoordinates(
                toolCall.function!.arguments,
              );
              if (shape != null) {
                shapes.add(shape);
              }
            }
          }
        }
      }

      debugPrint('🎨 ADDED ${shapes.length} SHAPES TO CANVAS');

      return shapes;
    } catch (e) {
      debugPrint('Error processing tool calling request: $e');
      return [];
    }
  }

  DrawableShape? _createFromCoordinates(Map<String, dynamic> args) {
    try {
      debugPrint('🎨 Creating from coordinates: $args');

      final description = args['description'] as String;
      var pathsData = args['paths'];
      final color = _parseColor(args['color'] as String);
      final strokeWidth = (args['strokeWidth'] as num?)?.toDouble() ?? 2.0;
      final filled = args['filled'] as bool? ?? true;
      final fillColor = args['fillColor'] != null
          ? _parseColor(args['fillColor'] as String)
          : color;
      final smoothness = (args['smoothness'] as num?)?.toDouble() ?? 0.3;

      // Get path types and curves data
      List<String> pathTypes = [];
      if (args['pathTypes'] is List) {
        pathTypes = (args['pathTypes'] as List)
            .map((e) => e.toString())
            .toList();
      }

      List<List<double>> curves = [];
      if (args['curves'] is List) {
        for (final curveData in args['curves'] as List) {
          if (curveData is List && curveData.length >= 8) {
            curves.add(curveData.map((e) => (e as num).toDouble()).toList());
          }
        }
      }

      // Convert coordinate arrays to Offset points
      List<List<Offset>> paths = [];

      // Debug: Check the actual type and content of pathsData
      debugPrint('🔍 pathsData type: ${pathsData.runtimeType}');
      debugPrint('🔍 pathsData content: $pathsData');

      // Handle different formats of paths data
      if (pathsData is String) {
        debugPrint('🔍 pathsData is String, attempting JSON parse...');
        // Fix malformed JSON string - add missing closing bracket if needed
        String jsonStr = pathsData.toString().trim();
        if (!jsonStr.endsWith(']]')) {
          if (jsonStr.endsWith(']')) {
            jsonStr += ']'; // Add one more closing bracket
          } else if (jsonStr.endsWith('[')) {
            jsonStr += ']]'; // Add two closing brackets
          }
        }

        // If paths is a string, try to parse it as JSON
        try {
          final parsedPaths = jsonDecode(jsonStr) as List;
          pathsData = parsedPaths;
          debugPrint('✅ Successfully parsed JSON string to List');
        } catch (e) {
          debugPrint('❌ Could not parse paths string: $jsonStr');
          debugPrint('❌ Error: $e');

          // Try alternative parsing - extract coordinates manually
          try {
            debugPrint('🔧 Attempting manual coordinate extraction...');
            final RegExp coordRegex = RegExp(r'\[(\d+),(\d+)\]');
            final matches = coordRegex.allMatches(jsonStr);

            if (matches.isNotEmpty) {
              List<List<int>> coordinates = [];
              for (final match in matches) {
                final x = int.parse(match.group(1)!);
                final y = int.parse(match.group(2)!);
                coordinates.add([x, y]);
              }
              pathsData = [coordinates]; // Wrap in array for paths format
              debugPrint(
                '✅ Manual extraction successful: ${coordinates.length} points',
              );
            } else {
              debugPrint('❌ Manual extraction failed - no coordinate matches');
              return null;
            }
          } catch (manualError) {
            debugPrint('❌ Manual extraction error: $manualError');
            return null;
          }
        }
      } else if (pathsData is List) {
        debugPrint(
          '✅ pathsData is already a List with ${pathsData.length} items',
        );
      } else {
        debugPrint('❌ pathsData is unexpected type: ${pathsData.runtimeType}');
        return null;
      }

      if (pathsData is List) {
        try {
          if (pathsData.isNotEmpty) {
            bool allNums = true;
            for (final e in pathsData) {
              if (e is! num) {
                allNums = false;
                break;
              }
            }
            if (allNums) {
              List<List<num>> coords = [];
              for (int k = 0; k + 1 < pathsData.length; k += 2) {
                final a = pathsData[k];
                final b = pathsData[k + 1];
                if (a is num && b is num) coords.add([a, b]);
              }
              pathsData = [coords];
              debugPrint(
                '🔧 Normalized flat numeric array into single path with ${coords.length} points (robust)',
              );
            } else if (pathsData.every((p) => p is List)) {
              bool everyElemIsPair = true;
              for (final p in pathsData) {
                if (p is! List) {
                  everyElemIsPair = false;
                  break;
                }
                if (p.length < 2 || p[0] is! num || p[1] is! num) {
                  everyElemIsPair = false;
                  break;
                }
              }
              if (everyElemIsPair) {
                // pathsData is a single path represented as list of pairs -> wrap
                pathsData = [pathsData];
                debugPrint(
                  '🔧 Detected single path as list of coordinate pairs; wrapped into outer list',
                );
              } else {
                // Possibly already a list of paths (each path is list of pairs), keep as-is
                debugPrint(
                  '🔧 pathsData appears to be a list of paths or mixed structure; leaving as-is',
                );
              }
            }
          }
        } catch (e) {
          debugPrint('🔧 Robust normalization error: $e');
        }
        try {
          if (pathsData.isNotEmpty) {
            final first = pathsData[0];
            if (first is List && first.isNotEmpty && first[0] is num) {
              // but ensure we are not already in the form [[ [x,y], ... ]]
              if (!(first[0] is List)) {
                pathsData = [pathsData];
                debugPrint(
                  '🔧 Final wrap: converted list-of-pairs into list-of-paths',
                );
              }
            }
          }
        } catch (e) {
          debugPrint('🔧 Final wrap check error: $e');
        }

        try {
          if (pathsData is List && pathsData.isNotEmpty) {
            final maybePair = pathsData[0];
            bool looksLikeListOfPairs = true;
            if (maybePair is List &&
                maybePair.isNotEmpty &&
                maybePair[0] is num) {
              for (final e in pathsData) {
                if (e is! List) {
                  looksLikeListOfPairs = false;
                  break;
                }
                if (e.length < 2 || e[0] is! num || e[1] is! num) {
                  looksLikeListOfPairs = false;
                  break;
                }
              }
              if (looksLikeListOfPairs) {
                pathsData = [pathsData];
                debugPrint(
                  '🔧 Final normalization: wrapped list-of-pairs into list-of-paths',
                );
              }
            }
          }
        } catch (e) {
          debugPrint('🔧 Final normalization error: $e');
        }

        debugPrint('🔍 Processing paths data with ${pathsData.length} path(s)');
        for (int i = 0; i < pathsData.length; i++) {
          final pathData = pathsData[i];
          debugPrint('🔍 Processing path $i: ${pathData.runtimeType}');

          List<Offset> points = [];
          if (pathData is List) {
            debugPrint(
              '✅ Path $i contains ${pathData.length} coordinate pairs',
            );
            for (int j = 0; j < pathData.length; j++) {
              final coord = pathData[j];
              debugPrint('🔍 Coordinate $j: $coord (${coord.runtimeType})');

              if (coord is List && coord.length >= 2) {
                try {
                  var x = (coord[0] as num).toDouble();
                  var y = (coord[1] as num).toDouble();

                  debugPrint('✅ Parsed coordinate: ($x, $y)');

                  if (x < 0 || y < 0 || x > 600 || y > 500) {
                    debugPrint(
                      '⚠️ Coordinate ($x, $y) outside canvas bounds, clamping...',
                    );
                  }

                  x = x.clamp(50.0, 550.0);
                  y = y.clamp(50.0, 450.0);

                  points.add(Offset(x, y));
                  debugPrint(
                    '✅ Added valid coordinate: (${x.toInt()}, ${y.toInt()})',
                  );
                } catch (e) {
                  debugPrint('❌ Could not parse coordinate $j: $coord - $e');
                }
              } else {
                debugPrint(
                  '❌ Invalid coordinate format at $j: $coord (expected List with 2+ elements)',
                );
              }
            }
          } else {
            debugPrint('❌ Path data is not a List: ${pathData.runtimeType}');
          }

          if (points.isNotEmpty) {
            paths.add(points);
            debugPrint('✅ Added path $i with ${points.length} points');
          } else {
            debugPrint('❌ No valid points found for path $i');
          }
        }
      } else {
        debugPrint('❌ Paths data is not a List: ${pathsData.runtimeType}');
      }

      final totalPoints = paths.fold(0, (sum, path) => sum + path.length);
      debugPrint(
        '✅ Successfully converted to ${paths.length} path(s) with $totalPoints total points',
      );
      debugPrint('✅ Path types: $pathTypes, Smoothness: $smoothness');

      if (paths.isEmpty) {
        debugPrint(
          '❌ CRITICAL ERROR: No valid paths found! Cannot create shape.',
        );
        return null;
      }

      if (totalPoints < 3) {
        debugPrint(
          '❌ CRITICAL ERROR: Not enough points ($totalPoints) to create a valid shape.',
        );
        return null;
      }

      final shape = DrawableShape(
        type: description,
        coordinatePaths: paths,
        color: filled ? fillColor : color,
        strokeWidth: strokeWidth,
        description: description,
        filled: filled,
        outlineColor: color,
        pathTypes: pathTypes,
        curves: curves,
        smoothness: smoothness,
      );

      debugPrint(
        '🎉 SUCCESS: Created $description shape with ${paths.length} path(s) and $totalPoints points',
      );
      return shape;
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
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'brown':
        return Colors.brown;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'gray':
      case 'grey':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  void dispose() {
    _client.endSession();
  }
}

class DrawableShape {
  final String type;
  final List<List<Offset>> coordinatePaths;
  final Color color;
  final double strokeWidth;
  final String description;
  final bool filled;
  final Color? outlineColor;
  final List<String> pathTypes;
  final List<List<double>> curves;
  final double smoothness;

  DrawableShape({
    required this.type,
    required this.coordinatePaths,
    required this.color,
    required this.strokeWidth,
    required this.description,
    this.filled = true,
    this.outlineColor,
    this.pathTypes = const [],
    this.curves = const [],
    this.smoothness = 0.3,
  });
}
