import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/mcp_provider.dart';
import 'screens/mcp_drawing_screen.dart';

void main() {
  runApp(const MCPApp());
}

class MCPApp extends StatelessWidget {
  const MCPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MCPProvider(),
      child: MaterialApp(
        title: 'MCP Shape Drawing Assistant',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 2,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        home: const MCPDrawingScreen(),
      ),
    );
  }
}
