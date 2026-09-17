import 'package:flutter/material.dart';
import 'data.dart';
import 'screens.dart';
import 'theme.dart';
import 'widgets.dart';

class CreekCampusApp extends StatefulWidget {
  const CreekCampusApp({super.key});
  @override
  State<CreekCampusApp> createState() => _CreekCampusAppState();
}

class _CreekCampusAppState extends State<CreekCampusApp> {
  final state = CampusState();
  @override
  void dispose() { state.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Creek Campus', debugShowCheckedModeBanner: false, theme: campusTheme(),
    home: ListenableBuilder(listenable: state, builder: (_, _) =>
      state.signedIn ? CampusShell(state: state) : WelcomeScreen(onEnter: state.enterDemo)),
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onEnter});
  final VoidCallback onEnter;
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: PageContent(children: [
    const SizedBox(height: 24),
    const Row(children: [IconTile(Icons.school_rounded, size: 56), SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('DHACSS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
      Text('CREEK CAMPUS', style: TextStyle(fontSize: 11, letterSpacing: 2.2)),
    ]))]),
    const SizedBox(height: 32),
    Container(
      height: 240,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(36), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF174B46), Color(0xFF398B7C)])),
      child: Stack(children: [
        Positioned(right: -32, top: -30, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .07)))),
        const Positioned(right: 28, bottom: 34, child: Icon(Icons.school_outlined, size: 140, color: Color(0xFFB6D6B8))),
        const Padding(padding: EdgeInsets.all(28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          StatusPill('GROW. LEARN. BELONG.'), Spacer(),
          Text('A little closer\nto their world.', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.15, color: Colors.white)),
        ])),
      ]),
    ),
    const SizedBox(height: 28),
    Text('School life,\nbeautifully connected.', style: Theme.of(context).textTheme.headlineLarge),
    const SizedBox(height: 14),
    const Text('Every small win. Every important update. A calmer way to stay connected with your child’s school day.', style: TextStyle(color: CampusColors.muted, fontSize: 16, height: 1.6)),
    const SizedBox(height: 24),
    const Wrap(spacing: 8, runSpacing: 8, children: [StatusPill('Academics'), StatusPill('School updates', color: CampusColors.lavender), StatusPill('Fees & services', color: CampusColors.peach)]),
    const SizedBox(height: 32),
    FilledButton.icon(key: const Key('enter-demo'), onPressed: onEnter, icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Explore parent demo')),
    const DemoNote(text: 'Interactive prototype · No login or real student data required.\nOfficial authentication will be added during API integration.'),
  ])));
}

class CampusShell extends StatefulWidget {
  const CampusShell({super.key, required this.state});
  final CampusState state;
  @override
  State<CampusShell> createState() => _CampusShellState();
}

class _CampusShellState extends State<CampusShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final pages = [
      Dashboard(state: state),
      AcademicsPage(state: state),
      ServicesPage(state: state),
      MessagesPage(state: state),
      ProfilePage(state: state),
    ];
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: const Row(children: [IconTile(Icons.school_rounded, size: 40), SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('DHACSS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.7)),
          Text('CREEK CAMPUS', style: TextStyle(fontSize: 9, letterSpacing: 1.8)),
        ])]),
        actions: [IconButton(tooltip: 'Notifications', onPressed: () => openPage(context, const NotificationsPage()), icon: const Badge(smallSize: 7, child: Icon(Icons.notifications_none_rounded))), const SizedBox(width: 8)],
      ),
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab, onDestinationSelected: (index) => setState(() => tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories), label: 'Academics'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Services'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

void showStudentPicker(BuildContext context, CampusState state) {
  showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (sheetContext) => SafeArea(child: Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Your children', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16),
      for (var i = 0; i < students.length; i++) ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(backgroundColor: i == 0 ? CampusColors.mint : CampusColors.lavender, child: Text(students[i].initials)),
        title: Text(students[i].name), subtitle: Text(students[i].grade),
        trailing: state.selectedStudent == i ? const Icon(Icons.check_circle, color: CampusColors.teal) : const Icon(Icons.circle_outlined),
        onTap: () { state.selectStudent(i); Navigator.pop(sheetContext); },
      ),
    ]),
  )));
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key, required this.state});
  final CampusState state;
  @override
  Widget build(BuildContext context) {
    final student = state.student;
    final actions = <(String, IconData, Color, Widget)>[
      ('Attendance', Icons.fact_check_outlined, CampusColors.mint, AttendancePage(state: state)),
      ('Timetable', Icons.calendar_today_outlined, CampusColors.lavender, TimetablePage(state: state)),
      ('Homework', Icons.edit_note_rounded, CampusColors.peach, HomeworkPage(state: state)),
      ('Fees', Icons.account_balance_wallet_outlined, const Color(0xFFE5EFFB), FeesPage(state: state)),
      ('Results', Icons.emoji_events_outlined, CampusColors.peach, ResultsPage(state: state)),
      ('Transport', Icons.directions_bus_outlined, CampusColors.mint, TransportPage(state: state)),
      ('Leave', Icons.event_available_outlined, const Color(0xFFE5EFFB), LeavePage(state: state)),
      ('Messages', Icons.forum_outlined, CampusColors.lavender, Scaffold(appBar: AppBar(title: const Text('Messages')), body: MessagesPage(state: state))),
    ];
    return PageContent(children: [
      const Text('A good day to grow ☀', style: TextStyle(fontSize: 13, color: CampusColors.muted)),
      const SizedBox(height: 4),
      Text('Hello, Ahmed family', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 20),
      CampusCard(padding: const EdgeInsets.all(16), onTap: () => showStudentPicker(context, state), child: Row(children: [
        CircleAvatar(radius: 26, backgroundColor: CampusColors.lavender, child: Text(student.initials, style: const TextStyle(fontWeight: FontWeight.w800))),
        const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(student.name, style: Theme.of(context).textTheme.titleMedium), Text(student.grade, style: const TextStyle(color: CampusColors.muted, fontSize: 12))])),
        const Icon(Icons.unfold_more_rounded),
      ])),
      const SizedBox(height: 16),
      CampusCard(color: CampusColors.ink, child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('EVERY DAY, A NEW POSSIBILITY', style: TextStyle(color: Color(0xFFBFD7C5), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 12),
          const Text('Little steps.\nBright futures.', style: TextStyle(fontSize: 29, height: 1.12, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 16),
          TextButton.icon(style: TextButton.styleFrom(foregroundColor: Colors.white, padding: EdgeInsets.zero), onPressed: () => openPage(context, const CampusInfoPage()), label: const Text('Discover our campus'), icon: const Icon(Icons.arrow_forward_rounded, size: 18)),
        ])),
        const SizedBox(width: 8),
        const Icon(Icons.local_florist_outlined, color: Color(0xFFCDE0A7), size: 76),
      ])),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: CampusCard(color: CampusColors.mint, padding: const EdgeInsets.all(16), onTap: () => openPage(context, AttendancePage(state: state)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle_outline_rounded, size: 22), const SizedBox(height: 12), Text('${student.attendance}%', style: Theme.of(context).textTheme.headlineMedium), const Text('Attendance', style: TextStyle(fontSize: 12))]))),
        const SizedBox(width: 12),
        Expanded(child: CampusCard(color: CampusColors.lavender, padding: const EdgeInsets.all(16), onTap: () => openPage(context, HomeworkPage(state: state)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.edit_note_rounded, size: 22), const SizedBox(height: 12), Text('${assignments.where((a) => !state.homeworkDone(a.id)).length}', style: Theme.of(context).textTheme.headlineMedium), const Text('Tasks to explore', style: TextStyle(fontSize: 12))]))),
      ]),
      const SectionTitle('At your fingertips'),
      LayoutBuilder(builder: (context, constraints) => Wrap(spacing: 10, runSpacing: 12, children: [
        for (final action in actions) SizedBox(width: (constraints.maxWidth - 30) / 4, child: Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(18), onTap: () => openPage(context, action.$4), child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(children: [IconTile(action.$2, color: action.$3, size: 54), const SizedBox(height: 8), Text(action.$1, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center)]))))),
      ])),
      SectionTitle('Today’s rhythm', action: 'Full schedule', onTap: () => openPage(context, TimetablePage(state: state))),
      CampusCard(child: Column(children: [for (var i = 0; i < 2; i++) ...[
        LessonRow(lesson: lessons[i]), if (i == 0) const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1)),
      ]])),
      const SectionTitle('One less thing to remember'),
      CampusCard(color: CampusColors.peach, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.account_balance_wallet_outlined), const SizedBox(width: 10), Expanded(child: Text('September fee', style: Theme.of(context).textTheme.titleMedium)), StatusPill(state.feesPaid ? 'Demo paid' : 'Sample due', color: Colors.white)]),
        const SizedBox(height: 16), Text(state.feesPaid ? 'All caught up!' : 'PKR 18,500', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6), const Text('Demo invoice · No real payment will be taken', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 14), FilledButton(onPressed: () => openPage(context, FeesPage(state: state)), child: Text(state.feesPaid ? 'View receipt' : 'View fee details')),
      ])),
      SectionTitle('Around campus', action: 'Explore', onTap: () => openPage(context, const CampusInfoPage())),
      CampusCard(onTap: () => openPage(context, const CampusInfoPage()), color: CampusColors.lavender, child: const Row(children: [IconTile(Icons.science_outlined, color: Colors.white, size: 64), SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [StatusPill('SAMPLE CAMPUS STORY', color: Colors.white), SizedBox(height: 10), Text('Curious minds, big discoveries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), SizedBox(height: 6), Text('A glimpse into learning beyond the classroom.', style: TextStyle(fontSize: 12))]))])),
      const DemoNote(),
    ]);
  }
}

class LessonRow extends StatelessWidget {
  const LessonRow({super.key, required this.lesson});
  final Lesson lesson;
  @override
  Widget build(BuildContext context) => Row(children: [
    IconTile(lesson.icon, color: lesson.color), const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(lesson.subject, style: Theme.of(context).textTheme.titleMedium), Text(lesson.detail, style: const TextStyle(fontSize: 11, color: CampusColors.muted))])),
    const SizedBox(width: 6), Text(lesson.time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
  ]);
}
