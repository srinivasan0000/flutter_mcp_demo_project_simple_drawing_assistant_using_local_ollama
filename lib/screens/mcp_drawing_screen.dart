import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mcp_provider.dart';
import '../widgets/shape_painter.dart';

class MCPDrawingScreen extends StatefulWidget {
  const MCPDrawingScreen({super.key});

  @override
  State<MCPDrawingScreen> createState() => _MCPDrawingScreenState();
}

class _MCPDrawingScreenState extends State<MCPDrawingScreen> 
    with TickerProviderStateMixin {
  
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  bool _showShapesList = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MCP Shape Drawing Assistant'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_showShapesList ? Icons.visibility_off : Icons.list),
            onPressed: () {
              setState(() {
                _showShapesList = !_showShapesList;
                if (_showShapesList) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              });
            },
          ),
          Consumer<MCPProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: provider.shapes.isNotEmpty
                    ? () => _showClearDialog(context, provider)
                    : null,
              );
            },
          ),
        ],
      ),
      body: Consumer<MCPProvider>(
        builder: (context, provider, child) {
          return Row(
            children: [
              // Main drawing area
              Expanded(
                flex: _showShapesList ? 3 : 1,
                child: Column(
                  children: [
                    // Canvas area
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DrawingCanvas(
                          shapes: provider.shapes,
                          onClearCanvas: provider.clearShapes,
                        ),
                      ),
                    ),
                    
                    // Chat interface
                    Expanded(
                      flex: 2,
                      child: _buildChatInterface(provider),
                    ),
                  ],
                ),
              ),
              
              // Shapes list panel (animated)
              if (_showShapesList)
                AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    return SizedBox(
                      width: 300 * _slideAnimation.value,
                      child: _buildShapesListPanel(provider),
                    );
                  },
                ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<MCPProvider>(
        builder: (context, provider, child) {
          return FloatingActionButton(
            onPressed: provider.isLoading ? null : () => provider.generateShapeFromChat('draw a colorful star'),
            child: provider.isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildChatInterface(MCPProvider provider) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Chat header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat),
                const SizedBox(width: 8),
                const Text('Chat with AI Assistant'),
                const Spacer(),
                if (provider.messages.isNotEmpty)
                  TextButton(
                    onPressed: provider.clearChat,
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ),
          
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _chatScrollController,
              padding: const EdgeInsets.all(8),
              itemCount: provider.messages.length,
              itemBuilder: (context, index) {
                return _buildChatMessage(provider.messages[index]);
              },
            ),
          ),
          
          // Chat input
          _buildChatInput(provider),
        ],
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: message.isError ? Colors.red : Colors.blue,
              child: Icon(
                message.isError ? Icons.error : Icons.smart_toy,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? Theme.of(context).colorScheme.primary
                    : message.isError 
                        ? Colors.red.shade100
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.timeString,
                    style: TextStyle(
                      fontSize: 10,
                      color: message.isUser 
                          ? Colors.white70 
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatInput(MCPProvider provider) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: InputDecoration(
                hintText: 'Ask me to draw shapes (e.g., "draw a red circle")',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSubmitted: (text) => _sendMessage(provider, text),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: provider.isLoading 
                ? null 
                : () => _sendMessage(provider, _chatController.text),
            icon: provider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  Widget _buildShapesListPanel(MCPProvider provider) {
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey.shade300)),
        color: Colors.grey.shade50,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Shapes (${provider.shapes.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: provider.shapes.length,
              itemBuilder: (context, index) {
                final shape = provider.shapes[index];
                return Card(
                  margin: const EdgeInsets.all(4),
                  child: ListTile(
                    leading: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: shape.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(shape.type),
                    subtitle: Text(shape.description),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => provider.removeShape(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(MCPProvider provider, String text) {
    if (text.trim().isEmpty) return;
    
    // Check if the message is asking to draw a shape
    if (_isDrawingRequest(text)) {
      provider.generateShapeFromChat(text);
    } else {
      // Start chat stream for general conversation
            provider.generateShapeFromChat(text);
    }
    
    _chatController.clear();
  }

  bool _isDrawingRequest(String text) {
    final drawingKeywords = [
      'draw', 'create', 'make', 'add', 'show',
      'circle', 'rectangle', 'triangle', 'square',
      'line', 'shape', 'polygon'
    ];
    
    final lowerText = text.toLowerCase();
    return drawingKeywords.any((keyword) => lowerText.contains(keyword));
  }



  void _showClearDialog(BuildContext context, MCPProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Canvas'),
        content: const Text('Are you sure you want to clear all shapes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.clearShapes();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
