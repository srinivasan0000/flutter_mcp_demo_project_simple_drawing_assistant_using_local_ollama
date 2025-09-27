import 'package:flutter/material.dart';
import 'package:ollama_dart/ollama_dart.dart' as ollama;
import '../services/mcp_tool_calling_service.dart';

/// MCP Provider for managing Ollama tool calling and shape generation
class MCPProvider extends ChangeNotifier {
  late final ollama.OllamaClient _ollamaClient;
  final MCPToolCallingService _mcpService = MCPToolCallingService();
  
  // Drawing state
  final List<DrawableShape> _shapes = [];
  
  // UI state
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedModel = 'llama3.1:latest';
  
  // Chat state
  final List<ChatMessage> _messages = [];
  
  // Getters
  List<DrawableShape> get shapes => List.unmodifiable(_shapes);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedModel => _selectedModel;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get hasShapes => _shapes.isNotEmpty;
  
  MCPProvider() {
    _initializeOllama();
  }
  
  /// Initialize Ollama client
  void _initializeOllama() {
    try {
      _ollamaClient = ollama.OllamaClient();
      debugPrint('🦙 Ollama client initialized');
    } catch (e) {
      debugPrint('Failed to initialize Ollama client: $e');
    }
  }
  
  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (!loading) _errorMessage = null;
    notifyListeners();
  }
  
  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }
  
  /// Add chat message
  void _addChatMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }
  
  /// Change selected model
  void changeModel(String model) {
    _selectedModel = model;
    notifyListeners();
  }
  
  /// Generate shapes using Ollama tool calling
  Future<void> generateShapeFromChat(String userInput) async {
    if (_isLoading) return;

    _setLoading(true);
    
    try {
      debugPrint('🔵 USER INPUT: $userInput');
      
      // Add user message
      _addChatMessage(ChatMessage(
        text: userInput,
        isUser: true,
        timestamp: DateTime.now(),
      ));

      // Use universal coordinate-based drawing (no predefined tools needed)
      debugPrint('🔧 USING UNIVERSAL COORDINATE-BASED DRAWING SYSTEM');
      
      // Send request to Ollama for coordinate-based drawing
      debugPrint('🦙 SENDING REQUEST TO OLLAMA MODEL: $_selectedModel');
      final response = await _ollamaClient.generateChatCompletion(
        request: ollama.GenerateChatCompletionRequest(
          model: _selectedModel,
          messages: [
            ollama.Message(
              role: ollama.MessageRole.system,
              content: '''You are a universal AI drawing assistant that can create any visual element using coordinate-based drawing.

Your task: Generate precise coordinate arrays for any requested drawing - shapes, objects, animals, faces, buildings, vehicles, etc.

Coordinate System:
- Canvas size: 400x400 pixels
- Use coordinates between 20-380 for positions
- Provide arrays of [x, y] coordinate pairs
- Connect coordinates to form the requested drawing

Drawing Rules:
- For simple shapes: provide 8-15 coordinate points
- For complex objects: provide 20-50+ coordinate points as needed
- Ensure coordinates form recognizable outlines
- Use smooth curves by placing points close together
- Choose appropriate colors (red, blue, green, yellow, purple, orange, pink, etc.)

Examples:
- Triangle: [[200, 50], [150, 150], [250, 150], [200, 50]]
- House: [[100, 200], [100, 300], [200, 300], [200, 200], [150, 150], [100, 200]]
- Star: [[200, 50], [210, 80], [240, 80], [218, 100], [225, 130], [200, 115], [175, 130], [182, 100], [160, 80], [190, 80], [200, 50]]

Respond with detailed coordinate descriptions for the user's request.''',
            ),
            ollama.Message(
              role: ollama.MessageRole.user,
              content: userInput,
            ),
          ],
        ),
      );

      debugPrint('✅ OLLAMA RESPONSE RECEIVED');
      debugPrint('📝 Response message: ${response.message.content}');
      
      // Use universal coordinate-based drawing system
      debugPrint('🎨 USING UNIVERSAL COORDINATE-BASED DRAWING METHOD');
      final universalShapes = await _mcpService.processToolCallingRequest(userInput);
      
      if (universalShapes.isNotEmpty) {
        _shapes.addAll(universalShapes);
        debugPrint('🎨 ADDED ${universalShapes.length} SHAPES TO CANVAS. Total shapes: ${_shapes.length}');
        
        final shapeDescriptions = universalShapes.map((s) => s.description).join(', ');
        _addChatMessage(ChatMessage(
          text: '🎨 Llama $_selectedModel: Drew $shapeDescriptions using coordinate-based drawing',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      } else {
        debugPrint('⚠️ No shapes were created from the request');
        _addChatMessage(ChatMessage(
          text: '⚠️ Llama $_selectedModel: "${response.message.content}" - Unable to generate drawable coordinates',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      debugPrint('💥 OLLAMA ERROR: $e');
      _setError('Llama tool calling error: $e');
      _addChatMessage(ChatMessage(
        text: 'Llama model error: $e',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      ));
    } finally {
      _setLoading(false);
    }
  }
  

  

  

  
  /// Clear all shapes from canvas
  void clearShapes() {
    _shapes.clear();
    notifyListeners();
  }
  
  /// Remove specific shape
  void removeShape(int index) {
    if (index >= 0 && index < _shapes.length) {
      _shapes.removeAt(index);
      notifyListeners();
    }
  }
  
  /// Clear chat messages
  void clearChat() {
    _messages.clear();
    notifyListeners();
  }
  
  /// Get available models from Ollama
  Future<List<String>> getAvailableModels() async {
    try {
      final response = await _ollamaClient.listModels();
      final models = response.models?.map((m) => m.model ?? '').where((name) => name.isNotEmpty).toList() ?? [];
      return models.isNotEmpty ? models : ['llama3.1:latest', 'mistral:latest', 'gemma3:latest'];
    } catch (e) {
      _setError('Failed to get available models: $e');
      return ['llama3.1:latest', 'mistral:latest', 'gemma3:latest'];
    }
  }
  
  /// Test Ollama connection
  Future<bool> testConnection() async {
    try {
      debugPrint('🔗 Testing Ollama connection...');
      final version = await _ollamaClient.getVersion();
      debugPrint('✅ Ollama connection successful. Version: ${version.version}');
      return true;
    } catch (e) {
      debugPrint('❌ Ollama connection failed: $e');
      _setError('Connection test failed: $e');
      return false;
    }
  }
  

}

/// Data class for chat messages
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });

  String get timeString {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
