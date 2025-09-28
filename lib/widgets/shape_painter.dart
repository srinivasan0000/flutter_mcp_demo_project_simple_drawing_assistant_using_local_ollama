import 'package:flutter/material.dart';
import '../services/mcp_tool_calling_service.dart';

class ShapePainter extends CustomPainter {
  final List<DrawableShape> shapes;

  ShapePainter({required this.shapes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final shape in shapes) {
      _drawShape(canvas, shape);
    }
  }

  void _drawShape(Canvas canvas, DrawableShape shape) {
    debugPrint('🎨 Painting ${shape.type}: ${shape.description}');

    if (shape.coordinatePaths.isNotEmpty) {
      for (
        int pathIndex = 0;
        pathIndex < shape.coordinatePaths.length;
        pathIndex++
      ) {
        final pathPoints = shape.coordinatePaths[pathIndex];
        if (pathPoints.isNotEmpty) {
          final path = Path();

          String pathType = "line"; // default
          if (pathIndex < shape.pathTypes.length) {
            pathType = shape.pathTypes[pathIndex];
          } else if (shape.pathTypes.isNotEmpty) {
            pathType = shape.pathTypes[0];
          }

          switch (pathType) {
            case "curve":
              _buildCurvePath(path, pathPoints, shape.smoothness);
              break;
            case "mixed":
              _buildMixedPath(path, pathPoints, shape.smoothness);
              break;
            case "line":
            default:
              _buildLinePath(path, pathPoints);
              break;
          }

          if (shape.filled && pathPoints.length >= 3) {
            path.close();
          }

          if (shape.filled) {
            final fillPaint = Paint()
              ..color = shape.color
              ..style = PaintingStyle.fill;
            canvas.drawPath(path, fillPaint);
          }

          final outlinePaint = Paint()
            ..color = shape.outlineColor ?? shape.color
            ..strokeWidth = shape.strokeWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;
          canvas.drawPath(path, outlinePaint);

          debugPrint(
            '✅ $pathType path drawn: ${shape.type} with ${pathPoints.length} points',
          );
        }
      }

      _drawShapeLabel(canvas, shape);
    } else {
      debugPrint('🚨 ${shape.type} has no coordinate paths');
    }
  }

  void _buildLinePath(Path path, List<Offset> points) {
    if (points.isEmpty) return;

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
  }

  void _buildCurvePath(Path path, List<Offset> points, double smoothness) {
    if (points.isEmpty) return;

    if (points.length < 3) {
      _buildLinePath(path, points);
      return;
    }

    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];

      final controlPoint1 = Offset(
        current.dx + (next.dx - points[i - 1].dx) * smoothness * 0.5,
        current.dy + (next.dy - points[i - 1].dy) * smoothness * 0.5,
      );

      final controlPoint2 = Offset(
        next.dx -
            (points[(i + 2).clamp(0, points.length - 1)].dx - current.dx) *
                smoothness *
                0.5,
        next.dy -
            (points[(i + 2).clamp(0, points.length - 1)].dy - current.dy) *
                smoothness *
                0.5,
      );

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        next.dx,
        next.dy,
      );
    }

    if (points.length >= 2) {
      final lastPoint = points.last;
      path.lineTo(lastPoint.dx, lastPoint.dy);
    }
  }

  void _buildMixedPath(Path path, List<Offset> points, double smoothness) {
    if (points.isEmpty) return;

    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      if (i % 2 == 0 && i < points.length - 1) {
        final current = points[i];
        final next = points[i + 1];
        final prev = points[i - 1];

        final controlPoint = Offset(
          current.dx + (next.dx - prev.dx) * smoothness * 0.3,
          current.dy + (next.dy - prev.dy) * smoothness * 0.3,
        );

        path.quadraticBezierTo(
          controlPoint.dx,
          controlPoint.dy,
          next.dx,
          next.dy,
        );
        i++;
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
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

      final allPoints = shape.coordinatePaths.expand((path) => path).toList();
      if (allPoints.isNotEmpty) {
        final centerX =
            allPoints.map((p) => p.dx).reduce((a, b) => a + b) /
            allPoints.length;
        final minY = allPoints.map((p) => p.dy).reduce((a, b) => a < b ? a : b);

        final labelOffset = Offset(centerX - textPainter.width / 2, minY - 25);

        textPainter.paint(canvas, labelOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! ShapePainter || oldDelegate.shapes != shapes;
  }
}

class DrawingCanvas extends StatelessWidget {
  final List<DrawableShape> shapes;
  final Function() onClearCanvas;

  const DrawingCanvas({
    super.key,
    required this.shapes,
    required this.onClearCanvas,
  });

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
          CustomPaint(
            size: Size.infinite,
            painter: ShapePainter(shapes: shapes),
          ),

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
                    Text(
                      'Shapes: ${shapes.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...shapes.take(3).map((shape) {
                      final pathType = shape.pathTypes.isNotEmpty
                          ? shape.pathTypes[0]
                          : 'line';
                      final curveIcon = pathType == 'curve'
                          ? '🌊'
                          : pathType == 'mixed'
                          ? '🔀'
                          : '📏';
                      return Text(
                        '$curveIcon ${shape.description}',
                        style: TextStyle(fontSize: 12, color: shape.color),
                      );
                    }),
                    if (shapes.length > 3)
                      Text(
                        '... and ${shapes.length - 3} more',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
