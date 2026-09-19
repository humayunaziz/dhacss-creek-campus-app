import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'backend.dart';
import 'theme.dart';

class SchoolApp extends StatelessWidget {
  const SchoolApp({super.key, this.client, this.setupError});
  final SupabaseClient? client;
  final String? setupError;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DHACSS Connect', debugShowCheckedModeBanner: false,
    theme: campusTheme(), home: client == null
      ? LoginPage(message: setupError ?? 'School login is not connected in this build. You can explore the demo below.')
      : StreamBuilder<AuthState>(stream: client!.auth.onAuthStateChange,
          builder: (context, snapshot) {
            final user = client!.auth.currentUser;
            if (user == null) return LoginPage(client: client);
            return SchoolDashboard(key: ValueKey(user.id),
              repository: SupabaseSchoolRepository(client!),
              onLogout: () => client!.auth.signOut(), email: user.email ?? 'School account');
          }),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.client, this.message});
  final SupabaseClient? client;
  final String? message;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool busy = false;
  String? error;
  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }
  Future<void> login() async {
    if (!form.currentState!.validate()) return;
    setState(() { busy = true; error = null; });
    try {
      await widget.client!.auth.signInWithPassword(email: email.text.trim(), password: password.text);
    } catch (_) {
      if (mounted) setState(() => error = 'Could not sign in. Check your email, password and connection, then try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(
    child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460), child: Form(key: form, child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Icon(Icons.school_rounded, size: 64, color: CampusColors.teal),
          const SizedBox(height: 24),
          Text('DHACSS Connect', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Your school community, together.', textAlign: TextAlign.center),
          const SizedBox(height: 32),
          if (widget.message != null) Padding(padding: const EdgeInsets.only(bottom: 20), child: Text(widget.message!)),
          if (widget.client != null) ...[
            TextFormField(controller: email, keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username], decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) => v != null && v.contains('@') ? null : 'Enter your email address'),
            const SizedBox(height: 14),
            TextFormField(controller: password, obscureText: true,
              autofillHints: const [AutofillHints.password], decoration: const InputDecoration(labelText: 'Password'),
              validator: (v) => v == null || v.isEmpty ? 'Enter your password' : null,
              onFieldSubmitted: (_) { if (!busy) login(); }),
            const SizedBox(height: 20),
            if (error != null) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(error!)),
            FilledButton(onPressed: busy ? null : login, child: Text(busy ? 'Signing in…' : 'Sign in')),
            const SizedBox(height: 16),
            const Text('Use the account provided by your school. Contact the school office if you need access or a password reset.', textAlign: TextAlign.center),
          ],
          const SizedBox(height: 24),
          OutlinedButton(onPressed: busy ? null : () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const DemoHost())), child: const Text('Explore offline demo')),
          const SizedBox(height: 8),
          const Text('Demo uses sample information only.', textAlign: TextAlign.center),
        ],
      )),
    )),
  )));
}

class DemoHost extends StatelessWidget {
  const DemoHost({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Offline demo'), leading: BackButton(onPressed: () => Navigator.of(context).pop())),
    body: const CreekCampusApp(),
  );
}

class SchoolDashboard extends StatefulWidget {
  const SchoolDashboard({super.key, required this.repository, required this.onLogout, required this.email});
  final SchoolRepository repository;
  final Future<void> Function() onLogout;
  final String email;
  @override
  State<SchoolDashboard> createState() => _SchoolDashboardState();
}

class _SchoolDashboardState extends State<SchoolDashboard> {
  late Future<SchoolSnapshot> data;
  bool signingOut = false;
  @override
  void initState() { super.initState(); data = widget.repository.load(); }
  Future<void> refresh() async {
    final next = widget.repository.load();
    setState(() => data = next);
    try { await next; } catch (_) { /* FutureBuilder presents the retry state. */ }
  }
  Future<void> logout() async {
    setState(() => signingOut = true);
    try { await widget.onLogout(); } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not sign out. Please try again.')));
    } finally { if (mounted) setState(() => signingOut = false); }
  }
  Future<void> openEditor(SchoolSnapshot snapshot, String kind) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => SchoolEditor(
      repository: widget.repository, snapshot: snapshot, kind: kind)));
    if (saved == true && mounted) await refresh();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('DHACSS Connect'), actions: [
      IconButton(tooltip: 'Refresh', onPressed: refresh, icon: const Icon(Icons.refresh)),
      IconButton(tooltip: 'Sign out', onPressed: signingOut ? null : logout, icon: const Icon(Icons.logout)),
    ]),
    body: FutureBuilder<SchoolSnapshot>(future: data, builder: (context, result) {
      if (result.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (result.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
        mainAxisSize: MainAxisSize.min, children: [
          const Text('We could not load your school information. Check your connection and try again.'),
          const SizedBox(height: 16), FilledButton(onPressed: refresh, child: const Text('Try again')),
        ],
      )));
      final snapshot = result.data!;
      return RefreshIndicator(onRefresh: refresh, child: ListView(padding: const EdgeInsets.all(24), children: [
        Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(snapshot.isStaff ? 'School administration' : 'Your children', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8), Text(widget.email), const SizedBox(height: 24),
            if (snapshot.isStaff) ...[
              Wrap(spacing: 12, runSpacing: 12, children: [
                if (snapshot.isHeadOffice) FilledButton.icon(onPressed: () => openEditor(snapshot, 'campus'), icon: const Icon(Icons.add_business), label: const Text('Add campus')),
                FilledButton.icon(onPressed: snapshot.campuses.isEmpty ? null : () => openEditor(snapshot, 'student'), icon: const Icon(Icons.person_add), label: const Text('Add student')),
                OutlinedButton.icon(onPressed: snapshot.students.isEmpty ? null : () => openEditor(snapshot, 'link'), icon: const Icon(Icons.link), label: const Text('Link parent')),
              ]),
              const SizedBox(height: 24),
              Text('Campuses', style: Theme.of(context).textTheme.titleLarge),
              for (final campus in snapshot.campuses) Card(child: ListTile(leading: const Icon(Icons.school_outlined), title: Text(campus['name'] as String), subtitle: Text(campus['code'] as String))),
              if (snapshot.campuses.isEmpty) const Text('No campuses yet. Add your first campus to begin.'),
              const SizedBox(height: 24), Text('Students', style: Theme.of(context).textTheme.titleLarge),
            ],
            if (snapshot.students.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(24), child: Text(
              snapshot.isStaff ? 'No students yet. Add a student to begin.' : 'No children are linked to your account yet. Please contact your school office.'))),
            for (final student in snapshot.students) Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(student['full_name'] as String, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8), Text(snapshot.campusName(student['campus_id'] as String)),
              Text('${student['class_name']} · Admission ${student['admission_number']}'),
              if (snapshot.isStaff) Text('${snapshot.links.where((l) => l['student_id'] == student['id']).length} parent account(s) linked'),
            ]))),
            const SizedBox(height: 20),
            const Text('Attendance, homework, fees and messages will appear here as those school services are connected.'),
          ],
        ))),
      ]));
    }),
  );
}

class SchoolEditor extends StatefulWidget {
  const SchoolEditor({super.key, required this.repository, required this.snapshot, required this.kind});
  final SchoolRepository repository;
  final SchoolSnapshot snapshot;
  final String kind;
  @override
  State<SchoolEditor> createState() => _SchoolEditorState();
}

class _SchoolEditorState extends State<SchoolEditor> {
  final form = GlobalKey<FormState>();
  final first = TextEditingController(), second = TextEditingController(), third = TextEditingController();
  String? selected;
  bool busy = false;
  String? error;
  @override
  void dispose() { first.dispose(); second.dispose(); third.dispose(); super.dispose(); }
  String? requiredText(String? value) => value == null || value.trim().isEmpty ? 'This field is required' : null;
  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() { busy = true; error = null; });
    try {
      switch (widget.kind) {
        case 'campus': await widget.repository.createCampus(first.text.trim(), second.text.trim());
        case 'student': await widget.repository.createStudent(selected!, first.text.trim(), second.text.trim(), third.text.trim());
        case 'link': await widget.repository.linkParent(first.text.trim(), selected!);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => error = 'Could not save. Check for duplicate details, confirm the parent account exists, and make sure your access is still active.');
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final choices = kind == 'link' ? widget.snapshot.students : widget.snapshot.campuses;
    return Scaffold(appBar: AppBar(title: Text(kind == 'campus' ? 'Add campus' : kind == 'student' ? 'Add student' : 'Link parent')),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: ListView(padding: const EdgeInsets.all(24), children: [
        Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (kind != 'campus') ...[
            DropdownButtonFormField<String>(isExpanded: true, initialValue: selected,
              decoration: InputDecoration(labelText: kind == 'link' ? 'Student' : 'Campus'),
              items: choices.map((item) => DropdownMenuItem(value: item['id'] as String,
                child: Text(kind == 'link' ? '${item['full_name']} · ${item['admission_number']}' : item['name'] as String, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: busy ? null : (value) => setState(() => selected = value), validator: requiredText),
            const SizedBox(height: 16),
          ],
          if (kind == 'link') const Padding(padding: EdgeInsets.only(bottom: 16), child: Text('Enter the existing parent account ID provided by the school administrator. This grants that parent access to this student.')),
          TextFormField(controller: first, enabled: !busy,
            decoration: InputDecoration(labelText: kind == 'campus' ? 'Campus name' : kind == 'student' ? 'Student full name' : 'Parent account UUID'),
            validator: (value) {
              if (requiredText(value) != null) return requiredText(value);
              if (kind == 'link' && !RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(value!.trim())) return 'Enter a valid account UUID';
              return null;
            }),
          if (kind != 'link') ...[
            const SizedBox(height: 16), TextFormField(controller: second, enabled: !busy,
              decoration: InputDecoration(labelText: kind == 'campus' ? 'Campus code' : 'Admission number'), validator: requiredText),
          ],
          if (kind == 'student') ...[
            const SizedBox(height: 16), TextFormField(controller: third, enabled: !busy,
              decoration: const InputDecoration(labelText: 'Class and section'), validator: requiredText),
          ],
          if (error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(error!)),
          const SizedBox(height: 24), FilledButton(onPressed: busy ? null : save, child: Text(busy ? 'Saving…' : kind == 'link' ? 'Grant parent access' : 'Save')),
        ])),
      ]))),
    );
  }
}
