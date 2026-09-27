import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

// Display only the campus photograph / crest regions of the supplied reference.
// Reference interface text and phone chrome are never used as interactive UI.
class CampusArtwork extends StatelessWidget {
  const CampusArtwork({super.key, this.crest = false});
  final bool crest;
  static ui.Image? _decoded;
  static final Future<ui.Image> _image = _load();
  static Future<void> prepare() async { await _image; }
  static Future<ui.Image> _load() async {
    final bytes = await rootBundle.load('assets/campus-reference.jpg');
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    _decoded = frame.image;
    return frame.image;
  }
  @override
  Widget build(BuildContext context) => ExcludeSemantics(child: _decoded != null
      ? CustomPaint(painter: _ArtworkPainter(_decoded!, crest), size: Size.infinite)
      : FutureBuilder<ui.Image>(
    future: _image,
    builder: (context, snapshot) => snapshot.hasData
        ? CustomPaint(painter: _ArtworkPainter(snapshot.data!, crest), size: Size.infinite)
        : ColoredBox(color: crest ? CampusColors.canvas : CampusColors.blue),
  ));
}
class _ArtworkPainter extends CustomPainter {
  _ArtworkPainter(this.image, this.crest);
  final ui.Image image;
  final bool crest;
  @override
  void paint(Canvas canvas, Size size) {
    final region = crest ? const Rect.fromLTRB(.037, .042, .229, .128)
        : const Rect.fromLTRB(.56, .322, .988, .471);
    final source = Rect.fromLTRB(region.left * image.width, region.top * image.height,
        region.right * image.width, region.bottom * image.height);
    final fitted = applyBoxFit(BoxFit.cover, source.size, size);
    final crop = Alignment.center.inscribe(fitted.source, source);
    canvas.drawImageRect(image, crop, Offset.zero & size, Paint()..filterQuality = FilterQuality.high);
  }
  @override
  bool shouldRepaint(_ArtworkPainter oldDelegate) => oldDelegate.image != image || oldDelegate.crest != crest;
}
class CampusBrand extends StatelessWidget {
  const CampusBrand({super.key, this.campus = 'CREEK CAMPUS'});
  final String campus;
  @override
  Widget build(BuildContext context) => Row(children: [
    const SizedBox(width: 48, height: 54, child: CampusArtwork(crest: true)),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      const Text('DHACSS', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: CampusColors.ink)),
      Text(campus, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, letterSpacing: 1.5, color: CampusColors.ink)),
    ])),
  ]);
}
class CampusHero extends StatelessWidget {
  const CampusHero({super.key, required this.title, required this.subtitle,
    this.eyebrow = 'LEARN. GROW. BELONG.', this.action, this.actionLabel, this.showCampus = true});
  final String title, subtitle, eyebrow;
  final VoidCallback? action;
  final String? actionLabel;
  final bool showCampus;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), boxShadow: [
      BoxShadow(color: CampusColors.blue.withValues(alpha: .12), blurRadius: 22, offset: const Offset(0, 10)),
    ]),
    child: Stack(children: [
      if (showCampus) const Positioned.fill(child: CampusArtwork()),
      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.centerLeft, end: Alignment.centerRight,
        colors: [const Color(0xFF006F76), const Color(0xFF007EA6).withValues(alpha: .95), CampusColors.blue.withValues(alpha: .18)],
        stops: const [0, .5, 1],
      )))),
      Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(eyebrow, style: const TextStyle(color: Color(0xFFDCFFF1), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 30, height: 1.13, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
        if (action != null) ...[
          const SizedBox(height: 18),
          FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: CampusColors.mint, foregroundColor: const Color(0xFF006855), minimumSize: const Size(48, 46)), onPressed: action, icon: const Icon(Icons.arrow_forward_rounded, size: 20), label: Text(actionLabel ?? 'Explore campus')),
        ],
      ])),
    ]),
  );
}
class CampusShortcut extends StatelessWidget {
  const CampusShortcut({super.key, required this.title, required this.icon, required this.color, required this.onTap});
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(button: true, child: InkWell(
    borderRadius: BorderRadius.circular(22), onTap: onTap,
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Column(children: [
      Container(height: 70, width: double.infinity, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(22)),
        child: Icon(icon, size: 34, color: accentFor(color))),
      const SizedBox(height: 8), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    ])),
  ));
}
Color accentFor(Color color) {
  if (color == CampusColors.lavender) { return const Color(0xFF7935C5); }
  if (color == CampusColors.peach) { return const Color(0xFFCB6112); }
  if (color == CampusColors.rose) { return const Color(0xFFD93265); }
  if (color == CampusColors.sky) { return const Color(0xFF007ACE); }
  if (color == CampusColors.sunshine) { return const Color(0xFFB78200); }
  return CampusColors.teal;
}
