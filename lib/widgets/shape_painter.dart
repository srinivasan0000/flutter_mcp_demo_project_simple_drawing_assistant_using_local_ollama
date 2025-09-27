import 'package:flutter/material.dart';
import '../services/mcp_tool_calling_service.dart';

/// Simple coordinate-based shape painter
class ShapePainter extends CustomPainter {
  final List<DrawableShape> shapes;

  ShapePainter({required this.shapes});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all shapes using coordinate paths
    for (final shape in shapes) {
      _drawShape(canvas, shape);
    }
  }

  void _drawShape(Canvas canvas, DrawableShape shape) {
    print('🎨 Painting ${shape.type}: ${shape.description}');
    
    if (shape.coordinatePaths.isNotEmpty) {
      for (final pathPoints in shape.coordinatePaths) {
        if (pathPoints.isNotEmpty) {
          final path = Path();
          path.moveTo(pathPoints[0].dx, pathPoints[0].dy);
          
          for (int i = 1; i < pathPoints.length; i++) {
            path.lineTo(pathPoints[i].dx, pathPoints[i].dy);
          }
          
          // Close the path if it's meant to be filled
          if (shape.filled && pathPoints.length >= 3) {
            path.close();
          }
          
          // Draw filled shape first if filled
          if (shape.filled) {
            final fillPaint = Paint()
              ..color = shape.color
              ..style = PaintingStyle.fill;
            canvas.drawPath(path, fillPaint);
          }
          
          // Draw outline
          final outlinePaint = Paint()
            ..color = shape.outlineColor ?? shape.color
            ..strokeWidth = shape.strokeWidth
            ..style = PaintingStyle.stroke;
          canvas.drawPath(path, outlinePaint);
          
          print('✅ Coordinate path drawn: ${shape.type} with ${pathPoints.length} points');
        }
      }
      
      // Draw shape label
      _drawShapeLabel(canvas, shape);
    } else {
      print('🚨 ${shape.type} has no coordinate paths');
    }
  }

  void _drawShapeLabel(Canvas canvas, DrawableShape shape) {
    if (shape.description.isNotEmpty && shape.coordinatePaths.isNotEmpty) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: shape.description,
          style: TextStyle(
            color: shape.color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      // Calculate center from coordinate paths
      final allPoints = shape.coordinatePaths.expand((path) => path).toList();
      if (allPoints.isNotEmpty) {
        final centerX = allPoints.map((p) => p.dx).reduce((a, b) => a + b) / allPoints.length;
        final minY = allPoints.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
        
        // Position label above the shape
        final labelOffset = Offset(
          centerX - textPainter.width / 2,
          minY - 25,
        );

        textPainter.paint(canvas, labelOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! ShapePainter || oldDelegate.shapes != shapes;
  }
}

/// Simple drawing canvas widget
class DrawingCanvas extends StatelessWidget {
  final List<DrawableShape> shapes;
  final Function() onClearCanvas;

  const DrawingCanvas({
    Key? key,
    required this.shapes,
    required this.onClearCanvas,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      height: 500,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Canvas
          CustomPaint(
            size: Size.infinite,
            painter: ShapePainter(shapes: shapes),
          ),
          
          // Clear button
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: onClearCanvas,
              icon: const Icon(Icons.clear),
              tooltip: 'Clear Canvas',
              style: IconButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          
          // Shape list
          if (shapes.isNotEmpty)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Shapes: ${shapes.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ...shapes.take(3).map((shape) => Text(
                      '• ${shape.description}',
                      style: TextStyle(fontSize: 12, color: shape.color),
                    )),
                    if (shapes.length > 3) Text('... and ${shapes.length - 3} more', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
