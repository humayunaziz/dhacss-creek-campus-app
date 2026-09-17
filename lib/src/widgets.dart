import 'package:flutter/material.dart';
import 'theme.dart';

class CampusCard extends StatelessWidget {
  const CampusCard({super.key, required this.child, this.color = Colors.white, this.padding = const EdgeInsets.all(20), this.onTap});
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(26),
    clipBehavior: Clip.antiAlias,
    child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(children: [
      Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
      if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
    ]),
  );
}

class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.color = CampusColors.mint, this.size = 48});
  final IconData icon;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
    child: Icon(icon, color: CampusColors.ink, size: size * .48),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.text, {super.key, this.color = CampusColors.mint});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CampusColors.ink)),
  );
}

class PageContent extends StatelessWidget {
  const PageContent({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
    child: Align(alignment: Alignment.topCenter, child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    )),
  );
}

class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(child: PageContent(children: children)),
  );
}

class DemoNote extends StatelessWidget {
  const DemoNote({super.key, this.text = 'DEMO · Sample data. No school systems are connected.'});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: CampusColors.muted)),
  );
}

void openPage(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

String shortDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
