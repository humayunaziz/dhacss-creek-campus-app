import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'backend.dart';
import 'theme.dart';

String schoolToday() => DateTime.now()
    .toUtc()
    .add(const Duration(hours: 5))
    .toIso8601String()
    .substring(0, 10);
String money(Object? value) =>
    'PKR ${num.tryParse('$value')?.toStringAsFixed(2) ?? '0.00'}';
String readable(Object? value) => '$value'.replaceAll('_', ' ');

class StudentWorkspace extends StatefulWidget {
  const StudentWorkspace({
    super.key,
    required this.services,
    required this.student,
    required this.campus,
    required this.isAdmin,
    required this.canTeach,
    required this.isFamily,
  });
  final StudentServices services;
  final Record student;
  final String campus;
  final bool isAdmin, canTeach, isFamily;
  @override
  State<StudentWorkspace> createState() => _StudentWorkspaceState();
}

class _StudentWorkspaceState extends State<StudentWorkspace> {
  int tab = 0;
  bool get staff => widget.isAdmin || widget.canTeach;
  void open(String title, String table, {String? kind}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SchoolRecordsPage(
            services: widget.services,
            student: widget.student,
            title: title,
            table: table,
            kind: kind,
            isAdmin: widget.isAdmin,
            canTeach: widget.canTeach,
            isFamily: widget.isFamily,
          ),
        ),
      );
  Widget tile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback action,
  ) => Card(
    color: color,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      leading: Icon(icon, color: CampusColors.ink),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: action,
    ),
  );
  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    return Scaffold(
      appBar: AppBar(title: Text(s['full_name'] as String)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Academics',
          ),
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Services'),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            label: 'Updates',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (tab == 0) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CampusColors.teal,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR SCHOOL DAY',
                    style: TextStyle(color: Colors.white70, letterSpacing: 2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hello, ${s['full_name']}',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.campus}\n${s['class_name']}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            tile(
              'Attendance',
              'Recorded attendance and monthly summary',
              Icons.fact_check_outlined,
              CampusColors.mint,
              () => open('Attendance', 'attendance'),
            ),
            tile(
              'Homework',
              'Assignments and due dates',
              Icons.edit_note,
              CampusColors.lavender,
              () => open('Homework', 'homework'),
            ),
            tile(
              'Monthly fees',
              'Your school’s generated bills',
              Icons.receipt_long_outlined,
              CampusColors.peach,
              () => open('Monthly fees', 'monthly_fee_bills'),
            ),
            tile(
              'School notices',
              'Latest announcements',
              Icons.campaign_outlined,
              CampusColors.mint,
              () =>
                  open('School notices', 'school_publications', kind: 'notice'),
            ),
          ],
          if (tab == 1) ...[
            Text(
              'Learning, every day',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            tile(
              'Attendance',
              'Browse attendance by month',
              Icons.calendar_month,
              CampusColors.mint,
              () => open('Attendance', 'attendance'),
            ),
            tile(
              'Timetable',
              'Class schedule published by your school',
              Icons.schedule,
              CampusColors.lavender,
              () => open('Timetable', 'school_publications', kind: 'timetable'),
            ),
            tile(
              'Homework',
              'Class assignments',
              Icons.edit_note,
              CampusColors.peach,
              () => open('Homework', 'homework'),
            ),
            tile(
              'Exam schedule',
              'Dates and examination instructions',
              Icons.event_note,
              CampusColors.mint,
              () => open('Exam schedule', 'school_publications', kind: 'exam'),
            ),
            tile(
              'Results',
              'Subject marks and teacher remarks',
              Icons.assessment_outlined,
              CampusColors.lavender,
              () => open('Results', 'student_results'),
            ),
          ],
          if (tab == 2) ...[
            Text(
              'School services',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            tile(
              'Monthly fees',
              'Bill details and copyable challan information',
              Icons.receipt_long,
              CampusColors.peach,
              () => open('Monthly fees', 'monthly_fee_bills'),
            ),
            tile(
              'Leave requests',
              staff
                  ? 'Review student leave requests'
                  : 'Apply and track decisions',
              Icons.event_available,
              CampusColors.mint,
              () => open('Leave requests', 'leave_requests'),
            ),
            tile(
              'Transport',
              'School-published routes, stops and contacts',
              Icons.directions_bus_outlined,
              CampusColors.lavender,
              () => open('Transport', 'school_publications', kind: 'transport'),
            ),
            tile(
              'Documents',
              'School-published document instructions',
              Icons.folder_outlined,
              CampusColors.peach,
              () => open('Documents', 'school_publications', kind: 'document'),
            ),
          ],
          if (tab == 3) ...[
            Text(
              'Stay connected',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            tile(
              'School notices',
              'Announcements from the school office',
              Icons.notifications_outlined,
              CampusColors.peach,
              () =>
                  open('School notices', 'school_publications', kind: 'notice'),
            ),
            tile(
              'Messages',
              'Shared with linked family and assigned school staff',
              Icons.forum_outlined,
              CampusColors.mint,
              () => open('Messages', 'school_messages'),
            ),
            tile(
              'School calendar',
              'Upcoming events and activities',
              Icons.event,
              CampusColors.lavender,
              () =>
                  open('School calendar', 'school_publications', kind: 'event'),
            ),
          ],
          if (tab == 4) ...[
            const CircleAvatar(radius: 40, child: Icon(Icons.school, size: 42)),
            const SizedBox(height: 20),
            for (final item in {
              'Student': s['full_name'],
              'Campus': widget.campus,
              'Class': s['class_name'],
              'Admission number': s['admission_number'],
              'Status': s['status'] ?? 'active',
            }.entries)
              Card(
                child: ListTile(
                  title: Text(item.key),
                  subtitle: Text('${item.value}'),
                ),
              ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Contact the school office to correct profile information. Return to the student list to switch children or campuses.',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SchoolRecordsPage extends StatefulWidget {
  const SchoolRecordsPage({
    super.key,
    required this.services,
    required this.student,
    required this.title,
    required this.table,
    this.kind,
    required this.isAdmin,
    required this.canTeach,
    required this.isFamily,
  });
  final StudentServices services;
  final Record student;
  final String title, table;
  final String? kind;
  final bool isAdmin, canTeach, isFamily;
  @override
  State<SchoolRecordsPage> createState() => _SchoolRecordsPageState();
}

class _SchoolRecordsPageState extends State<SchoolRecordsPage> {
  late Future<List<Record>> future;
  bool busy = false;
  String month = schoolToday().substring(0, 7);
  bool get staff => widget.isAdmin || widget.canTeach;
  bool get canCreate => widget.table == 'school_publications'
      ? widget.isAdmin
      : widget.table == 'leave_requests'
      ? widget.isFamily
      : widget.table == 'school_messages'
      ? (staff || widget.isFamily)
      : ['homework', 'attendance', 'student_results'].contains(widget.table) &&
            staff;
  @override
  void initState() {
    super.initState();
    future = widget.services.records(widget.table, widget.student);
  }

  Future<void> refresh() async {
    final next = widget.services.records(widget.table, widget.student);
    setState(() {
      future = next;
    });
    try {
      await next;
    } catch (_) {}
  }

  Future<void> work(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
      if (mounted) await refresh();
    } catch (_) {
      if (mounted)
        {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save. Check the details, connection and your school access, then retry.',
            ),
          ),
        );
        }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> editor({Record? row}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SchoolRecordEditor(
          services: widget.services,
          student: widget.student,
          table: widget.table,
          kind: widget.kind,
          existing: row,
        ),
      ),
    );
    if (saved == true && mounted) await refresh();
  }

  Future<void> delete(Record row) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this record?'),
        content: const Text(
          'This removes it from the school records for everyone with access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true)
      {
      await work(
        () => widget.services.remove(widget.table, row['id'] as String),
      );
      }
  }

  Future<void> decision(Record row, String status) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          status == 'cancelled'
              ? 'Cancel request?'
              : '${status == 'approved' ? 'Approve' : 'Reject'} leave?',
        ),
        content: TextField(
          controller: controller,
          maxLength: 2000,
          decoration: InputDecoration(
            labelText: status == 'rejected'
                ? 'Reason (required)'
                : 'Response (optional)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () {
              if (status == 'rejected' && controller.text.trim().length < 3)
                {
                return;
                }
              Navigator.pop(context, true);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    final note = controller.text.trim();
    controller.dispose();
    if (confirmed == true)
      {
      await work(() => widget.services.reviewLeave(row['id'], status, note));
      }
  }

  String title(Record r) => switch (widget.table) {
    'attendance' => '${r['attendance_date']} · ${readable(r['status'])}',
    'homework' => '${r['subject']} · ${r['title']}',
    'monthly_fee_bills' => 'FEE-${r['bill_number']} · ${money(r['amount'])}',
    'student_results' => '${r['exam_name']} · ${r['subject']}',
    'leave_requests' => '${r['starts_on']} → ${r['ends_on']}',
    'school_messages' =>
      r['sender_id'] == widget.services.userId ? 'You' : 'School / family',
    _ => '${r['title']}',
  };
  String body(Record r) => switch (widget.table) {
    'attendance' => 'Recorded attendance',
    'homework' => 'Due ${r['due_date']}\n\n${r['instructions']}',
    'monthly_fee_bills' =>
      '${r['description']}\nBilling month: ${r['billing_month']}\nDue: ${r['due_date']}\n${r['voided_at'] != null ? 'Voided: ${r['void_reason']}' : 'Generated bill · payment status not available'}',
    'student_results' =>
      '${r['marks']} / ${r['total']} (${(num.parse('${r['marks']}') / num.parse('${r['total']}') * 100).toStringAsFixed(1)}%)\n${r['exam_date']}\n${r['remarks']}',
    'leave_requests' =>
      '${readable(r['status'])}\n${r['reason']}\n${r['response'] ?? ''}',
    'school_messages' => '${r['body']}\n\n${r['created_at']}',
    _ =>
      '${r['starts_on'] == null ? '' : '${r['starts_on']}${r['ends_on'] == null ? '' : ' → ${r['ends_on']}'}\n'}${r['body']}',
  };
  Future<void> chooseMonth() async {
    final initial = DateTime.tryParse('$month-01') ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted)
      {
      setState(() => month = date.toIso8601String().substring(0, 7));
      }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: busy ? null : refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    floatingActionButton: canCreate
        ? FloatingActionButton.extended(
            onPressed: busy ? null : () => editor(),
            icon: const Icon(Icons.add),
            label: Text(
              widget.table == 'school_messages'
                  ? 'Write message'
                  : widget.table == 'leave_requests'
                  ? 'Apply for leave'
                  : 'Add record',
            ),
          )
        : null,
    body: FutureBuilder<List<Record>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          {
          return const Center(child: CircularProgressIndicator());
          }
        if (snapshot.hasError)
          {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load records.'),
                FilledButton(
                  onPressed: refresh,
                  child: const Text('Try again'),
                ),
              ],
            ),
          );
          }
        final records = snapshot.data!
            .where(
              (r) =>
                  (widget.kind == null || r['kind'] == widget.kind) &&
                  (widget.table != 'attendance' ||
                      '${r['attendance_date']}'.startsWith(month)),
            )
            .toList();
        records.sort(
          (
            a,
            b,
          ) => '${b[widget.table == 'attendance' ? 'attendance_date' : 'created_at']}'
              .compareTo(
                '${a[widget.table == 'attendance' ? 'attendance_date' : 'created_at']}',
              ),
        );
        final editable = widget.table == 'school_publications'
            ? widget.isAdmin
            : ['homework', 'student_results'].contains(widget.table) && staff;
        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              if (busy) const LinearProgressIndicator(),
              if (widget.table == 'attendance') ...[
                OutlinedButton.icon(
                  onPressed: chooseMonth,
                  icon: const Icon(Icons.calendar_month),
                  label: Text('Month: $month'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    '${records.length} recorded days · ${records.where((r) => r['status'] == 'present').length} present · ${records.where((r) => r['status'] == 'absent').length} absent · ${records.where((r) => r['status'] == 'late').length} late · ${records.where((r) => r['status'] == 'excused').length} excused\nDays with no entry are not counted.',
                  ),
                ),
              ],
              if (widget.table == 'monthly_fee_bills')
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'These are bills generated by your school. Contact the school accounts office for payment instructions or a receipt. Online payment is not connected.',
                    ),
                  ),
                ),
              if (widget.table == 'school_messages')
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'This student’s conversation is shared with their linked family and assigned school staff. Pull down to check for new messages.',
                  ),
                ),
              if (records.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Text(
                    'No records published yet.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final r in records)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title(r),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        SelectableText(body(r)),
                        if (widget.table == 'monthly_fee_bills')
                          TextButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(
                                  text:
                                      '${widget.student['full_name']} · Admission ${widget.student['admission_number']}\n${title(r)}\n${body(r)}',
                                ),
                              );
                              if (context.mounted)
                                {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Bill details copied.'),
                                  ),
                                );
                                }
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy bill details'),
                          ),
                        if (editable)
                          Wrap(
                            children: [
                              TextButton(
                                onPressed: busy ? null : () => editor(row: r),
                                child: const Text('Edit'),
                              ),
                              TextButton(
                                onPressed: busy ? null : () => delete(r),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        if (widget.table == 'leave_requests' &&
                            r['status'] == 'pending')
                          Wrap(
                            children: [
                              if (staff) ...[
                                TextButton(
                                  onPressed: busy
                                      ? null
                                      : () => decision(r, 'approved'),
                                  child: const Text('Approve'),
                                ),
                                TextButton(
                                  onPressed: busy
                                      ? null
                                      : () => decision(r, 'rejected'),
                                  child: const Text('Reject'),
                                ),
                              ],
                              if (r['requested_by'] == widget.services.userId)
                                TextButton(
                                  onPressed: busy
                                      ? null
                                      : () => decision(r, 'cancelled'),
                                  child: const Text('Cancel request'),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class SchoolRecordEditor extends StatefulWidget {
  const SchoolRecordEditor({
    super.key,
    required this.services,
    required this.student,
    required this.table,
    this.kind,
    this.existing,
  });
  final StudentServices services;
  final Record student;
  final String table;
  final String? kind;
  final Record? existing;
  @override
  State<SchoolRecordEditor> createState() => _SchoolRecordEditorState();
}

class _SchoolRecordEditorState extends State<SchoolRecordEditor> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  bool busy = false, campusWide = false;
  String status = 'present';
  String? error;
  @override
  void initState() {
    super.initState();
    for (final key in [
      'title',
      'body',
      'subject',
      'instructions',
      'due_date',
      'exam_name',
      'exam_date',
      'marks',
      'total',
      'remarks',
      'starts_on',
      'ends_on',
      'reason',
      'attendance_date',
    ]) {
      fields[key] = TextEditingController(
        text:
            '${widget.existing?[key] ?? (['due_date', 'exam_date', 'starts_on', 'ends_on', 'attendance_date'].contains(key) ? schoolToday() : '')}',
      );
    }
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  String value(String key) => fields[key]!.text.trim();
  Widget field(
    String key,
    String label, {
    bool multiline = false,
    bool optional = false,
    bool number = false,
    int max = 200,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: fields[key],
      enabled: !busy,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : multiline
          ? TextInputType.multiline
          : TextInputType.text,
      minLines: multiline ? 3 : 1,
      maxLines: multiline ? 6 : 1,
      maxLength: max,
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        if (!optional && (v == null || v.trim().isEmpty)) return 'Required';
        if (number &&
            (num.tryParse(v ?? '') == null ||
                !num.parse(v!).isFinite ||
                num.parse(v) < 0))
          {
          return 'Enter a valid positive number or zero';
          }
        return null;
      },
    ),
  );
  Widget date(String key, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: fields[key],
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_month),
      ),
      onTap: busy
          ? null
          : () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: DateTime.tryParse(value(key)) ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (selected != null && mounted)
                {
                setState(
                  () => fields[key]!.text = selected
                      .toIso8601String()
                      .substring(0, 10),
                );
                }
            },
      validator: (v) =>
          DateTime.tryParse(v ?? '') == null ? 'Select a date' : null,
    ),
  );
  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final s = widget.student;
      final table = widget.table;
      final existing = widget.existing;
      final Record data;
      switch (table) {
        case 'attendance':
          if (value('attendance_date').compareTo(schoolToday()) > 0)
            {
            throw const FormatException('Attendance cannot be in the future.');
            }
          await widget.services.attendance(
            s['id'],
            value('attendance_date'),
            status,
          );
          if (mounted) Navigator.pop(context, true);
          return;
        case 'school_publications':
          if (value('ends_on').compareTo(value('starts_on')) < 0)
            {
            throw const FormatException(
              'End date must be on or after start date.',
            );
            }
          data = {
            'title': value('title'),
            'body': value('body'),
            'starts_on': value('starts_on'),
            'ends_on': value('ends_on'),
          };
          if (existing == null)
            {
            data.addAll({
              'campus_id': s['campus_id'],
              'class_name': campusWide ? null : s['class_name'],
              'kind': widget.kind,
            });
            }
        case 'homework':
          data = {
            'subject': value('subject'),
            'title': value('title'),
            'instructions': value('instructions'),
            'due_date': value('due_date'),
          };
          if (existing == null)
            {
            data.addAll({
              'campus_id': s['campus_id'],
              'class_name': s['class_name'],
            });
            }
        case 'student_results':
          final marks = num.parse(value('marks')),
              total = num.parse(value('total'));
          if (total <= 0 || marks > total)
            {
            throw const FormatException(
              'Total must be greater than zero and marks cannot exceed it.',
            );
            }
          data = {'marks': marks, 'total': total, 'remarks': value('remarks')};
          if (existing == null)
            {
            data.addAll({
              'student_id': s['id'],
              'exam_name': value('exam_name'),
              'subject': value('subject'),
              'exam_date': value('exam_date'),
            });
            }
        case 'leave_requests':
          final start = DateTime.parse(value('starts_on')),
              end = DateTime.parse(value('ends_on'));
          if (value('starts_on').compareTo(schoolToday()) < 0 ||
              end.isBefore(start) ||
              end.difference(start).inDays > 90 ||
              value('reason').length < 3)
            {
            throw const FormatException(
              'Choose today or a future start, an end within 90 days, and a reason of at least 3 characters.',
            );
            }
          data = {
            'student_id': s['id'],
            'starts_on': value('starts_on'),
            'ends_on': value('ends_on'),
            'reason': value('reason'),
          };
        case 'school_messages':
          data = {'student_id': s['id'], 'body': value('body')};
        default:
          throw const FormatException('Unsupported record.');
      }
      if (existing == null) {
        await widget.services.insert(table, data);
      } else {
        await widget.services.update(table, existing['id'], data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        {
        setState(
          () => error = e is FormatException
              ? e.message
              : 'Could not save. Check your details and connection. A matching record may already exist, or your access may have changed.',
        );
        }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final table = widget.table;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? 'New ${readable(widget.kind ?? table)}'
              : 'Edit record',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${widget.student['full_name']} · ${widget.student['class_name']}',
                ),
                const SizedBox(height: 20),
                if (table == 'school_publications') ...[
                  if (widget.existing == null)
                    SwitchListTile(
                      value: campusWide,
                      onChanged: busy
                          ? null
                          : (v) => setState(() => campusWide = v),
                      title: const Text('Publish to entire campus'),
                      subtitle: const Text(
                        'Otherwise visible to this class only.',
                      ),
                    ),
                  field('title', 'Title'),
                  field('body', 'Details', multiline: true, max: 10000),
                  date('starts_on', 'Start / effective date'),
                  date('ends_on', 'End date'),
                ],
                if (table == 'homework') ...[
                  field('subject', 'Subject', max: 100),
                  field('title', 'Title'),
                  field(
                    'instructions',
                    'Instructions',
                    multiline: true,
                    max: 10000,
                  ),
                  date('due_date', 'Due date'),
                ],
                if (table == 'student_results') ...[
                  if (widget.existing == null) ...[
                    field('exam_name', 'Exam name', max: 120),
                    field('subject', 'Subject', max: 100),
                    date('exam_date', 'Exam date'),
                  ],
                  field('marks', 'Marks obtained', number: true),
                  field('total', 'Total marks', number: true),
                  field(
                    'remarks',
                    'Remarks',
                    optional: true,
                    multiline: true,
                    max: 2000,
                  ),
                ],
                if (table == 'leave_requests') ...[
                  date('starts_on', 'From'),
                  date('ends_on', 'To'),
                  field('reason', 'Reason', multiline: true, max: 2000),
                ],
                if (table == 'school_messages')
                  field('body', 'Message', multiline: true, max: 4000),
                if (table == 'attendance') ...[
                  date('attendance_date', 'Attendance date'),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    items: ['present', 'absent', 'late', 'excused']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: busy ? null : (v) => status = v!,
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                  const SizedBox(height: 16),
                ],
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                FilledButton(
                  onPressed: busy ? null : save,
                  child: Text(busy ? 'Saving…' : 'Save'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
