import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mcp_provider.dart';
import '../widgets/shape_painter.dart';

class MCPDrawingScreen extends StatefulWidget {
  const MCPDrawingScreen({super.key});

  @override
  State<MCPDrawingScreen> createState() => _MCPDrawingScreenState();
}

class _MCPDrawingScreenState extends State<MCPDrawingScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  @override
  void dispose() {
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Drawing Assistant'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Consumer<MCPProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(
                    children: [
                      DrawingCanvas(
                        shapes: provider.shapes,
                        onClearCanvas: provider.clearShapes,
                      ),
                      if (provider.isLoading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(strokeWidth: 3),
                                  SizedBox(height: 16),
                                  Text(
                                    'AI is creating your drawing...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              Expanded(flex: 2, child: _buildChatInterface(provider)),
            ],
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.chat),
                SizedBox(width: 8),
                Text('Ask AI to draw shapes'),
              ],
            ),
          ),

          Expanded(
            child: provider.messages.isEmpty
                ? const Center(
                    child: Text(
                      'Type a message to start drawing!\nExample: "draw a red circle"',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _chatScrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: provider.messages.length,
                    itemBuilder: (context, index) {
                      return _buildChatMessage(provider.messages[index]);
                    },
                  ),
          ),

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
              child: const Icon(Icons.person, size: 16, color: Colors.white),
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
                hintText:
                    'Type your drawing request... (e.g., "draw a red circle")',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSubmitted: (text) => _sendMessage(provider, text),
              enabled: !provider.isLoading,
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey,
                    ),
                  )
                : const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: provider.isLoading
                  ? Colors.grey.shade200
                  : Theme.of(context).colorScheme.primary,
              foregroundColor: provider.isLoading ? Colors.grey : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(MCPProvider provider, String text) {
    if (text.trim().isEmpty) return;

    provider.clearChat();
    provider.clearShapes();

    provider.generateShapeFromChat(text);

    _chatController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
