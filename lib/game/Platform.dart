// ────────────────────────────────────────────────────────────
// Platform
// ────────────────────────────────────────────────────────────
class Platform {
  final double x;
  final double y;
  final double width;

  const Platform({required this.x, required this.y, required this.width});

  double get left => x - width / 2;
  double get right => x + width / 2;
  double get top => y;
}