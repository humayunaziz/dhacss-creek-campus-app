import 'package:flutter/material.dart';
import 'app.dart' show LessonRow, showStudentPicker;
import 'data.dart';
import 'theme.dart';
import 'widgets.dart';

class AcademicsPage extends StatelessWidget {
  const AcademicsPage({super.key, required this.state});
  final CampusState state;
  @override
  Widget build(BuildContext context) => PageContent(children: [
    Text('Room to flourish', style: Theme.of(context).textTheme.headlineMedium),
    Text('${state.student.name} · Learning at a glance', style: const TextStyle(color: CampusColors.muted)),
    const SizedBox(height: 20),
    FeatureLink('Attendance', 'Every school day counts', Icons.fact_check_outlined, CampusColors.mint, () => openPage(context, AttendancePage(state: state))),
    FeatureLink('Timetable', 'A little structure for a big day', Icons.calendar_month_outlined, CampusColors.lavender, () => openPage(context, TimetablePage(state: state))),
    FeatureLink('Homework', 'Small challenges, growing confidence', Icons.edit_note_rounded, CampusColors.peach, () => openPage(context, HomeworkPage(state: state))),
    FeatureLink('Results', 'Celebrate progress, together', Icons.emoji_events_outlined, const Color(0xFFE5EFFB), () => openPage(context, ResultsPage(state: state))),
    const DemoNote(),
  ]);
}

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key, required this.state});
  final CampusState state;
  @override
  Widget build(BuildContext context) => PageContent(children: [
    Text('Your school essentials', style: Theme.of(context).textTheme.headlineMedium),
    const Text('A little less admin. A little more peace of mind.', style: TextStyle(color: CampusColors.muted)),
    const SizedBox(height: 20),
    FeatureLink('Fees & payments', 'Invoices, payment demo and receipts', Icons.account_balance_wallet_outlined, CampusColors.peach, () => openPage(context, FeesPage(state: state))),
    FeatureLink('Transport', 'Your child’s sample school route', Icons.directions_bus_outlined, CampusColors.mint, () => openPage(context, TransportPage(state: state))),
    FeatureLink('Leave request', 'Keep your class teacher informed', Icons.event_available_outlined, CampusColors.lavender, () => openPage(context, LeavePage(state: state))),
    FeatureLink('Explore campus', 'Discover the Creek Campus experience', Icons.school_outlined, const Color(0xFFE5EFFB), () => openPage(context, const CampusInfoPage())),
    const DemoNote(),
  ]);
}

class FeatureLink extends StatelessWidget {
  const FeatureLink(this.title, this.subtitle, this.icon, this.color, this.onTap, {super.key});
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: CampusCard(onTap: onTap, padding: const EdgeInsets.all(16), child: Row(children: [IconTile(icon, color: color), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(fontSize: 12, color: CampusColors.muted))])), const Icon(Icons.chevron_right_rounded)])));
}

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key, required this.state});
  final CampusState state;
  @override
  Widget build(BuildContext context) => DetailPage(title: 'Attendance', children: [
    Text(state.student.name, style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 16),
    CampusCard(color: CampusColors.mint, child: Row(children: [
      SizedBox(width: 90, height: 90, child: Stack(alignment: Alignment.center, children: [SizedBox.expand(child: CircularProgressIndicator(value: state.student.attendance / 100, strokeWidth: 8, backgroundColor: Colors.white)), Text('${state.student.attendance}%', style: Theme.of(context).textTheme.titleLarge)])),
      const SizedBox(width: 24), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Showing up,\ngrowing stronger.', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)), SizedBox(height: 8), Text('Sample term attendance', style: TextStyle(fontSize: 12))])),
    ])),
    const SectionTitle('September 2026 · Sample month'),
    CampusCard(child: Column(children: [
      Row(children: [for (final day in const ['M', 'T', 'W', 'T', 'F', 'S', 'S']) Expanded(child: Center(child: Text(day, style: const TextStyle(color: CampusColors.muted))))]),
      const SizedBox(height: 12),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: 35, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 6, crossAxisSpacing: 6), itemBuilder: (_, index) {
        final day = index;
        if (day < 1 || day > 30) { return const SizedBox.shrink(); }
        final weekend = index % 7 >= 5;
        final color = weekend || day > 17 ? const Color(0xFFF4F5F2) : day == 9 ? CampusColors.peach : CampusColors.mint;
        return Container(alignment: Alignment.center, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(11)), child: Text('$day', style: TextStyle(fontSize: 12, color: day > 17 ? CampusColors.muted : CampusColors.ink)));
      }),
      const SizedBox(height: 20), const Wrap(spacing: 8, runSpacing: 8, children: [StatusPill('Present'), StatusPill('Absent', color: CampusColors.peach), StatusPill('Off / upcoming', color: Color(0xFFF4F5F2))]),
    ])),
    const DemoNote(text: 'Static September preview. Term percentage is sample data,\nnot calculated from this partial-month calendar.'),
  ]);
}

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key, required this.state});
  final CampusState state;
  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  int day = 0;
  @override
  Widget build(BuildContext context) => DetailPage(title: 'Timetable', children: [
    Text(widget.state.student.grade, style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 16),
    Wrap(spacing: 8, children: [for (var i = 0; i < 5; i++) ChoiceChip(label: Text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri'][i]), selected: day == i, onSelected: (_) => setState(() => day = i))]),
    const SizedBox(height: 20),
    for (var i = 0; i < lessons.length; i++) ...[
      if (i == 3) const Padding(padding: EdgeInsets.only(bottom: 12), child: CampusCard(color: CampusColors.peach, child: Row(children: [Icon(Icons.restaurant_outlined), SizedBox(width: 12), Expanded(child: Text('10:15 – 10:45 · Recharge & recess'))]))),
      Padding(padding: const EdgeInsets.only(bottom: 12), child: CampusCard(child: LessonRow(lesson: Lesson(lessons[i].time, lessons[(i + day) % lessons.length].subject, lessons[(i + day) % lessons.length].detail, lessons[(i + day) % lessons.length].icon, lessons[(i + day) % lessons.length].color)))),
    ],
    const DemoNote(text: 'Sample timetable · 08:00–12:15 · Campus local time'),
  ]);
}

class HomeworkPage extends StatelessWidget {
  const HomeworkPage({super.key, required this.state});
  final CampusState state;
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: state, builder: (_, _) => DetailPage(title: 'Homework', children: [
    Text('A little learning, every day.', style: Theme.of(context).textTheme.headlineMedium),
    const SizedBox(height: 8), Text(state.student.name, style: const TextStyle(color: CampusColors.muted)),
    const SizedBox(height: 20),
    for (final assignment in assignments) Padding(padding: const EdgeInsets.only(bottom: 16), child: CampusCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(assignment.subject, style: const TextStyle(color: CampusColors.teal, fontWeight: FontWeight.w700))), StatusPill(state.homeworkDone(assignment.id) ? 'Done locally' : assignment.due, color: state.homeworkDone(assignment.id) ? CampusColors.mint : CampusColors.peach)]),
      const SizedBox(height: 14), Text(assignment.title, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), Text(assignment.description), const SizedBox(height: 14),
      CheckboxListTile(contentPadding: EdgeInsets.zero, title: const Text('Mark complete on this device', style: TextStyle(fontSize: 13)), value: state.homeworkDone(assignment.id), onChanged: (_) => state.toggleHomework(assignment.id), controlAffinity: ListTileControlAffinity.leading),
    ]))),
    const DemoNote(text: 'Completion is stored in memory only.\nNo homework is submitted to a teacher.'),
  ]));
}

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key, required this.state});
  final CampusState state;
  @override
  Widget build(BuildContext context) {
    final scores = state.selectedStudent == 0 ? [92, 88, 95, 86, 94] : [96, 90, 92, 94, 98];
    final average = scores.reduce((a, b) => a + b) / scores.length;
    return DetailPage(title: 'Results', children: [
      Text(state.student.name, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16),
      CampusCard(color: CampusColors.lavender, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const StatusPill('SAMPLE TERM REPORT', color: Colors.white), const SizedBox(height: 16), Text('${average.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.headlineLarge), const Text('Wonderful progress. Keep that curiosity growing!')])),
      const SectionTitle('Subject snapshot'),
      for (var i = 0; i < scores.length; i++) Padding(padding: const EdgeInsets.only(bottom: 12), child: CampusCard(child: Column(children: [Row(children: [Expanded(child: Text(lessons[i].subject, style: Theme.of(context).textTheme.titleMedium)), Text('${scores[i]} / 100', style: const TextStyle(fontWeight: FontWeight.w700))]), const SizedBox(height: 14), LinearProgressIndicator(value: scores[i] / 100, minHeight: 7, borderRadius: BorderRadius.circular(8), backgroundColor: CampusColors.mint)]))),
      const DemoNote(),
    ]);
  }
}

class FeesPage extends StatelessWidget {
  const FeesPage({super.key, required this.state});
  final CampusState state;
  Future<void> _pay(BuildContext context) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Try the payment flow'),
      content: const Text('This marks the sample invoice as paid on this device. No bank connection, card details or real money are involved.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirm demo payment'))],
    ));
    if (confirmed == true) { state.payDemoFee(); }
  }
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: state, builder: (_, _) => DetailPage(title: 'Fees & payments', children: [
    Text(state.student.name, style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 16),
    CampusCard(color: state.feesPaid ? CampusColors.mint : CampusColors.peach, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      StatusPill(state.feesPaid ? 'DEMO PAYMENT COMPLETE' : 'SAMPLE INVOICE', color: Colors.white), const SizedBox(height: 16),
      Text(state.feesPaid ? 'PKR 0' : 'PKR 18,500', style: Theme.of(context).textTheme.headlineLarge),
      const Text('Outstanding balance · September 2026'),
    ])),
    const SectionTitle('Invoice breakdown'),
    const CampusCard(child: Column(children: [AmountRow('Tuition fee', '16,000'), AmountRow('Activity fee', '1,000'), AmountRow('Transport', '1,500'), Divider(), AmountRow('Total · PKR', '18,500', emphasis: true)])),
    const SizedBox(height: 20),
    if (!state.feesPaid) FilledButton.icon(onPressed: () => _pay(context), icon: const Icon(Icons.lock_outline_rounded), label: const Text('Simulate payment')),
    if (state.feesPaid) CampusCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.verified_outlined, color: CampusColors.teal, size: 36), const SizedBox(height: 12), Text('Demo receipt', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), Text('Reference: DEMO-${state.student.id}\nAmount: PKR 18,500\nMethod: simulation only\nStatus: paid in this session'), const SizedBox(height: 10), const Text('Not a valid financial receipt.', style: TextStyle(color: CampusColors.muted))])),
    const DemoNote(text: 'No payment gateway is connected.\nAmounts are illustrative and are not official campus fees.'),
  ]));
}

class AmountRow extends StatelessWidget {
  const AmountRow(this.label, this.amount, {super.key, this.emphasis = false});
  final String label;
  final String amount;
  final bool emphasis;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Expanded(child: Text(label, style: TextStyle(fontWeight: emphasis ? FontWeight.w700 : FontWeight.w400))), Text(amount, style: const TextStyle(fontWeight: FontWeight.w700))]));
}

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key, required this.state});
  final CampusState state;
  @override
  Widget build(BuildContext context) => PageContent(children: [
    Text('Good conversations\nstart here.', style: Theme.of(context).textTheme.headlineMedium),
    const SizedBox(height: 8), const Text('Stay close to the people who help your child grow.', style: TextStyle(color: CampusColors.muted)),
    const SizedBox(height: 24),
    for (final message in campusMessages) Padding(padding: const EdgeInsets.only(bottom: 12), child: CampusCard(onTap: () => openPage(context, ConversationPage(state: state, message: message)), padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CircleAvatar(backgroundColor: CampusColors.lavender, child: Text(message.initials)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(message.name, style: Theme.of(context).textTheme.titleMedium), Text(message.role, style: const TextStyle(color: CampusColors.teal, fontSize: 11)), const SizedBox(height: 8), Text(message.preview, style: const TextStyle(fontSize: 13)), const SizedBox(height: 8), Text(message.time, style: const TextStyle(fontSize: 10, color: CampusColors.muted))])),
    ]))),
    const DemoNote(text: 'Sample conversations · Replies stay on this device.'),
  ]);
}

class ConversationPage extends StatefulWidget {
  const ConversationPage({super.key, required this.state, required this.message});
  final CampusState state;
  final CampusMessage message;
  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final controller = TextEditingController();
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  void send() {
    final text = controller.text.trim();
    if (text.isEmpty) { return; }
    widget.state.sendMessage(widget.message.name, text);
    controller.clear();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.message.name)),
    body: SafeArea(child: Column(children: [
      const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: DemoNote(text: 'DEMO CHAT · Messages are not sent to school.')),
      Expanded(child: ListenableBuilder(listenable: widget.state, builder: (_, _) => ListView(padding: const EdgeInsets.all(20), children: [
        Align(alignment: Alignment.centerLeft, child: CampusCard(child: Text(widget.message.preview))),
        for (final reply in widget.state.replies(widget.message.name)) Padding(padding: const EdgeInsets.only(top: 16, left: 44), child: Align(alignment: Alignment.centerRight, child: CampusCard(color: CampusColors.mint, child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(reply), const SizedBox(height: 4), const Text('Stored locally', style: TextStyle(fontSize: 10, color: CampusColors.muted))])))),
      ]))),
      Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: Row(children: [Expanded(child: TextField(controller: controller, minLines: 1, maxLines: 4, maxLength: 1000, decoration: const InputDecoration(hintText: 'Write a demo message…', counterText: ''), onSubmitted: (_) => send())), const SizedBox(width: 8), IconButton.filled(tooltip: 'Send demo message', onPressed: send, icon: const Icon(Icons.send_rounded))])),
    ])),
  );
}

class LeavePage extends StatefulWidget {
  const LeavePage({super.key, required this.state});
  final CampusState state;
  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  final formKey = GlobalKey<FormState>();
  final reason = TextEditingController();
  String type = 'Medical';
  DateTime? start;
  DateTime? end;
  @override
  void dispose() { reason.dispose(); super.dispose(); }
  Future<void> pickDate(bool isStart) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final earliest = isStart ? today : start ?? today;
    final result = await showDatePicker(context: context, initialDate: isStart ? start ?? today : end ?? earliest, firstDate: earliest, lastDate: today.add(const Duration(days: 365)));
    if (result != null && mounted) { setState(() { if (isStart) { start = result; if (end == null || end!.isBefore(result)) { end = result; } } else { end = result; } }); }
  }
  void submit() {
    if (!formKey.currentState!.validate()) { return; }
    if (start == null || end == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select the leave dates.'))); return; }
    widget.state.requestLeave(LeaveEntry(widget.state.student.id, type, start!, end!, reason.text.trim()));
    reason.clear();
    setState(() { start = null; end = null; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo request saved locally. Nothing was sent to school.')));
  }
  @override
  Widget build(BuildContext context) => DetailPage(title: 'Leave request', children: [
    Text('A heads-up helps.', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 8), Text('For ${widget.state.student.name}', style: const TextStyle(color: CampusColors.muted)), const SizedBox(height: 20),
    Form(key: formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      DropdownButtonFormField<String>(initialValue: type, decoration: const InputDecoration(labelText: 'Leave type'), items: ['Medical', 'Family commitment', 'Other'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: (value) => setState(() => type = value!)),
      const SizedBox(height: 16),
      Wrap(spacing: 10, runSpacing: 10, children: [OutlinedButton.icon(onPressed: () => pickDate(true), icon: const Icon(Icons.calendar_today_outlined), label: Text(start == null ? 'Start date' : shortDate(start!))), OutlinedButton.icon(onPressed: () => pickDate(false), icon: const Icon(Icons.event_outlined), label: Text(end == null ? 'End date' : shortDate(end!)))]),
      const SizedBox(height: 16),
      TextFormField(controller: reason, maxLines: 4, maxLength: 500, decoration: const InputDecoration(labelText: 'Reason', alignLabelWithHint: true, hintText: 'Let the teacher know a little more…'), validator: (value) => (value?.trim().length ?? 0) < 10 ? 'Please enter a reason of at least 10 characters.' : null),
      const SizedBox(height: 16), FilledButton(onPressed: submit, child: const Text('Save demo request')),
    ])),
    const SectionTitle('Your requests'),
    if (widget.state.leaveRequests.where((entry) => entry.studentId == widget.state.student.id).isEmpty) const CampusCard(child: Text('No requests yet. Your sample requests will appear here.')),
    for (final entry in widget.state.leaveRequests.where((entry) => entry.studentId == widget.state.student.id)) Padding(padding: const EdgeInsets.only(bottom: 12), child: CampusCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(entry.type, style: Theme.of(context).textTheme.titleMedium)), const StatusPill('Local draft')]), const SizedBox(height: 8), Text('${shortDate(entry.start)} – ${shortDate(entry.end)}'), const SizedBox(height: 8), Text(entry.reason)]))),
    const DemoNote(text: 'Requests are demo-only and reset when the app restarts.'),
  ]);
}

class TransportPage extends StatelessWidget {
  const TransportPage({super.key, required this.state});
  final CampusState state;
  @override
  Widget build(BuildContext context) => DetailPage(title: 'Transport', children: [
    Text('A calmer school run.', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 8), Text(state.student.name, style: const TextStyle(color: CampusColors.muted)), const SizedBox(height: 20),
    const CampusCard(color: CampusColors.mint, child: Row(children: [IconTile(Icons.directions_bus_rounded, color: Colors.white, size: 68), SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [StatusPill('SAMPLE ROUTE', color: Colors.white), SizedBox(height: 10), Text('Route 04 · Bus 12', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)), Text('DHA → Creek Campus')]))])),
    const SectionTitle('Morning journey'),
    const CampusCard(child: Column(children: [RouteStop('07:10', 'Sample pickup point', 'Please arrive five minutes early', Icons.home_outlined), RouteStop('07:25', 'Sample second stop', 'Scheduled pickup', Icons.location_on_outlined), RouteStop('07:45', 'Creek Campus', 'Scheduled arrival', Icons.school_outlined)])),
    const SizedBox(height: 16), const CampusCard(color: CampusColors.peach, child: Row(children: [Icon(Icons.info_outline_rounded), SizedBox(width: 12), Expanded(child: Text('This is a route preview, not a live map. GPS tracking and verified transport contacts need a backend integration.'))])),
    const DemoNote(text: 'No real bus location, driver details or pickup address is used.'),
  ]);
}

class RouteStop extends StatelessWidget {
  const RouteStop(this.time, this.title, this.detail, this.icon, {super.key});
  final String time;
  final String title;
  final String detail;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [Text(time, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(width: 16), Icon(icon, color: CampusColors.teal), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium), Text(detail, style: const TextStyle(fontSize: 12, color: CampusColors.muted))]))]));
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => const DetailPage(title: 'Notifications', children: [
    CampusCard(color: CampusColors.mint, child: Text('A little nudge, just when it matters.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
    SectionTitle('Sample updates'),
    CampusCard(child: Column(children: [
      ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.edit_note_rounded), title: Text('A new learning adventure'), subtitle: Text('Sample homework has been added to Mathematics.')),
      Divider(),
      ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.event_outlined), title: Text('Let’s talk progress'), subtitle: Text('Sample parent–teacher meeting invitation. Date to be confirmed.')),
      Divider(),
      ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.receipt_long_outlined), title: Text('Your sample invoice is ready'), subtitle: Text('See the Fees section to try a demo payment.')),
    ])),
    DemoNote(text: 'Static preview · Push notifications are not connected.'),
  ]);
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.state});
  final CampusState state;
  @override
  Widget build(BuildContext context) => PageContent(children: [
    Text('Your little school world', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 24),
    CampusCard(child: Column(children: [CircleAvatar(radius: 42, backgroundColor: CampusColors.lavender, child: Text(state.student.initials, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800))), const SizedBox(height: 16), Text(state.student.name, style: Theme.of(context).textTheme.titleLarge), Text(state.student.grade), const SizedBox(height: 8), Text('Student ID · ${state.student.id}', style: const TextStyle(color: CampusColors.muted)), const SizedBox(height: 16), OutlinedButton.icon(onPressed: () => showStudentPicker(context, state), icon: const Icon(Icons.swap_horiz_rounded), label: const Text('Switch child'))])),
    const SectionTitle('Parent account'),
    const CampusCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Ahmed family', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), SizedBox(height: 6), Text('Demo parent account'), SizedBox(height: 12), Text('All names and student records in this prototype are fictional. No personal information is collected.')])),
    const SizedBox(height: 20),
    OutlinedButton.icon(onPressed: state.signOut, icon: const Icon(Icons.logout_rounded), label: const Text('Exit demo')),
    const DemoNote(text: 'Creek Campus prototype · v0.1.0\nSession changes reset when the application restarts.'),
  ]);
}

class CampusInfoPage extends StatelessWidget {
  const CampusInfoPage({super.key});
  @override
  Widget build(BuildContext context) => DetailPage(title: 'Explore Creek Campus', children: [
    CampusCard(color: CampusColors.ink, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.school_outlined, size: 64, color: Color(0xFFCADEB2)), const SizedBox(height: 24), Text('A place to learn.\nA place to belong.', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)), const SizedBox(height: 12), const Text('DHACSS Creek Campus', style: TextStyle(color: Colors.white70))])),
    const SectionTitle('A world of possibilities'),
    const CampusCard(child: Column(children: [
      ListTile(contentPadding: EdgeInsets.zero, leading: IconTile(Icons.auto_stories_outlined, color: CampusColors.lavender), title: Text('Learning & discovery'), subtitle: Text('Space for academic updates and classroom stories.')),
      SizedBox(height: 12),
      ListTile(contentPadding: EdgeInsets.zero, leading: IconTile(Icons.sports_soccer_rounded, color: CampusColors.peach), title: Text('Beyond the classroom'), subtitle: Text('Space for activities, sports and student achievements.')),
      SizedBox(height: 12),
      ListTile(contentPadding: EdgeInsets.zero, leading: IconTile(Icons.groups_outlined), title: Text('A connected community'), subtitle: Text('Space for parent events and campus announcements.')),
    ])),
    const SizedBox(height: 20), const CampusCard(child: SelectableText('Official campus website\nhttps://creekcampus.dhacsskarachi.edu.pk/')),
    const DemoNote(text: 'Editorial placeholder content, not verified campus announcements.\nSchool-approved copy and assets can replace these cards.'),
  ]);
}
