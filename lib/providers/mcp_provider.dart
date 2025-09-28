import 'package:flutter/material.dart';
import 'package:ollama_dart/ollama_dart.dart' as ollama;
import '../services/mcp_tool_calling_service.dart';

/// MCP Provider for managing Ollama tool calling and shape generation
class MCPProvider extends ChangeNotifier {
  late final ollama.OllamaClient _ollamaClient;
  final MCPToolCallingService _mcpService = MCPToolCallingService();

  final List<DrawableShape> _shapes = [];

  bool _isLoading = false;
  String? _errorMessage;
  String _selectedModel = 'llama3.1:latest';

  final List<ChatMessage> _messages = [];

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

  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  void _addChatMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  void changeModel(String model) {
    _selectedModel = model;
    notifyListeners();
  }

  Future<void> generateShapeFromChat(String userInput) async {
    if (_isLoading) return;

    _setLoading(true);

    try {
      debugPrint('🔵 USER INPUT: $userInput');

      _addChatMessage(
        ChatMessage(text: userInput, isUser: true, timestamp: DateTime.now()),
      );

      debugPrint('🔧 USING MCP TOOL CALLING SERVICE WITH CURVE SUPPORT');

      final shapes = await _mcpService.processToolCallingRequest(userInput);

      if (shapes.isNotEmpty) {
        _shapes.addAll(shapes);
        debugPrint(
          '🎨 ADDED ${shapes.length} SHAPES TO CANVAS. Total shapes: ${_shapes.length}',
        );

        final shapeDescriptions = shapes.map((s) => s.description).join(', ');

        _addChatMessage(
          ChatMessage(
            text: '✅ Created: $shapeDescriptions',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      } else {
        debugPrint('⚠️ No shapes were created from the request');
        _addChatMessage(
          ChatMessage(
            text:
                '⚠️ AI responded but no shapes could be parsed. Please check debug logs.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      debugPrint('💥 MCP TOOL CALLING ERROR: $e');
      _setError('MCP tool calling error: $e');
      _addChatMessage(
        ChatMessage(
          text: '❌ Error: $e',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ),
      );
    } finally {
      _setLoading(false);
    }
  }

  void clearShapes() {
    _shapes.clear();
    notifyListeners();
  }

  void removeShape(int index) {
    if (index >= 0 && index < _shapes.length) {
      _shapes.removeAt(index);
      notifyListeners();
    }
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }

  Future<List<String>> getAvailableModels() async {
    try {
      final response = await _ollamaClient.listModels();
      final models =
          response.models
              ?.map((m) => m.model ?? '')
              .where((name) => name.isNotEmpty)
              .toList() ??
          [];
      return models.isNotEmpty
          ? models
          : ['llama3.1:latest', 'mistral:latest', 'gemma3:latest'];
    } catch (e) {
      _setError('Failed to get available models: $e');
      return ['llama3.1:latest', 'mistral:latest', 'gemma3:latest'];
    }
  }

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
