import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'backend.dart';
import 'theme.dart';
import 'student_workspace.dart';

class SchoolApp extends StatelessWidget {
  const SchoolApp({super.key, this.client, this.setupError});
  final SupabaseClient? client;
  final String? setupError;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DHACSS Connect',
    debugShowCheckedModeBanner: false,
    theme: campusTheme(),
    home: client == null
        ? LoginPage(
            message:
                setupError ??
                'School login is not connected in this build. You can explore the demo below.',
          )
        : StreamBuilder<AuthState>(
            stream: client!.auth.onAuthStateChange,
            builder: (context, snapshot) {
              final user = client!.auth.currentUser;
              if (user == null) return LoginPage(client: client);
              return AuthenticatedSchool(
                key: ValueKey(user.id),
                client: client!,
                email: user.email ?? 'School account',
              );
            },
          ),
  );
}

class AuthenticatedSchool extends StatefulWidget {
  const AuthenticatedSchool({
    super.key,
    required this.client,
    required this.email,
  });
  final SupabaseClient client;
  final String email;
  @override
  State<AuthenticatedSchool> createState() => _AuthenticatedSchoolState();
}

class _AuthenticatedSchoolState extends State<AuthenticatedSchool> {
  final navigator = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) => NavigatorPopHandler<void>(
    onPopWithResult: (_) => navigator.currentState!.pop(),
    child: Navigator(
      key: navigator,
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => SchoolDashboard(
          repository: SupabaseSchoolRepository(widget.client),
          services: SupabaseStudentServices(widget.client),
          onLogout: () => widget.client.auth.signOut(),
          email: widget.email,
        ),
      ),
    ),
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
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.client!.auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text,
      );
    } catch (_) {
      if (mounted)
        {
        setState(
          () => error =
              'Could not sign in. Check your email, password and connection, then try again.',
        );
        }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.school_rounded,
                    size: 64,
                    color: CampusColors.teal,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'DHACSS Connect',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your school community, together.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (widget.message != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(widget.message!),
                    ),
                  if (widget.client != null) ...[
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) => v != null && v.contains('@')
                          ? null
                          : 'Enter your email address',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter your password' : null,
                      onFieldSubmitted: (_) {
                        if (!busy) login();
                      },
                    ),
                    const SizedBox(height: 20),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(error!),
                      ),
                    FilledButton(
                      onPressed: busy ? null : login,
                      child: Text(busy ? 'Signing in…' : 'Sign in'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Use the account provided by your school. Contact the school office if you need access or a password reset.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const DemoHost(),
                            ),
                          ),
                    child: const Text('Explore offline demo'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Demo uses sample information only.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class DemoHost extends StatelessWidget {
  const DemoHost({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Offline demo'),
      leading: BackButton(onPressed: () => Navigator.of(context).pop()),
    ),
    body: const CreekCampusApp(),
  );
}

class SchoolDashboard extends StatefulWidget {
  const SchoolDashboard({
    super.key,
    required this.repository,
    required this.onLogout,
    required this.email,
    this.services,
  });
  final SchoolRepository repository;
  final StudentServices? services;
  final Future<void> Function() onLogout;
  final String email;
  @override
  State<SchoolDashboard> createState() => _SchoolDashboardState();
}

class _SchoolDashboardState extends State<SchoolDashboard> {
  late Future<SchoolSnapshot> data;
  bool signingOut = false;
  String search = '';
  String selectedCampus = '';
  @override
  void initState() {
    super.initState();
    data = widget.repository.load();
  }

  Future<void> refresh() async {
    final next = widget.repository.load();
    setState(() {
      data = next;
    });
    try {
      await next;
    } catch (_) {
      /* FutureBuilder presents the retry state. */
    }
  }

  Future<void> logout() async {
    setState(() => signingOut = true);
    try {
      await widget.onLogout();
    } catch (_) {
      if (mounted)
        {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not sign out. Please try again.'),
          ),
        );
        }
    } finally {
      if (mounted) setState(() => signingOut = false);
    }
  }

  Future<void> openEditor(SchoolSnapshot snapshot, String kind) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SchoolEditor(
          repository: widget.repository,
          snapshot: snapshot,
          kind: kind,
          services: widget.services,
        ),
      ),
    );
    if (saved == true && mounted) await refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('DHACSS Connect'),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: refresh,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: signingOut ? null : logout,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: FutureBuilder<SchoolSnapshot>(
      future: data,
      builder: (context, result) {
        if (result.connectionState != ConnectionState.done)
          {
          return const Center(child: CircularProgressIndicator());
          }
        if (result.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'We could not load your school information. Check your connection and try again.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: refresh,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        }
        final snapshot = result.data!;
        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        snapshot.isStaff
                            ? 'School administration'
                            : snapshot.assignments.isNotEmpty
                            ? 'Your students'
                            : 'Your students & children',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(widget.email),
                      const SizedBox(height: 24),
                      if (snapshot.isStaff) ...[
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            if (snapshot.isHeadOffice)
                              FilledButton.icon(
                                onPressed: () => openEditor(snapshot, 'campus'),
                                icon: const Icon(Icons.add_business),
                                label: const Text('Add campus'),
                              ),
                            FilledButton.icon(
                              onPressed: snapshot.campuses.isEmpty
                                  ? null
                                  : () => openEditor(snapshot, 'student'),
                              icon: const Icon(Icons.person_add),
                              label: const Text('Add student'),
                            ),
                            OutlinedButton.icon(
                              onPressed: snapshot.students.isEmpty
                                  ? null
                                  : () => openEditor(snapshot, 'link'),
                              icon: const Icon(Icons.link),
                              label: const Text('Link parent'),
                            ),
                            if (widget.services != null)
                              OutlinedButton.icon(
                                onPressed: snapshot.students.isEmpty
                                    ? null
                                    : () =>
                                          openEditor(snapshot, 'student_login'),
                                icon: const Icon(Icons.badge_outlined),
                                label: const Text('Link student login'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Campuses',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        for (final campus in snapshot.campuses)
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.school_outlined),
                              title: Text(campus['name'] as String),
                              subtitle: Text(campus['code'] as String),
                            ),
                          ),
                        if (snapshot.campuses.isEmpty)
                          const Text(
                            'No campuses yet. Add your first campus to begin.',
                          ),
                        const SizedBox(height: 24),
                        Text(
                          'Students',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                      if (snapshot.students.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              snapshot.isStaff
                                  ? 'No students yet. Add a student to begin.'
                                  : 'No children are linked to your account yet. Please contact your school office.',
                            ),
                          ),
                        ),
                      if (snapshot.students.isNotEmpty) ...[
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Find student',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (v) =>
                              setState(() => search = v.toLowerCase()),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCampus,
                          decoration: const InputDecoration(
                            labelText: 'Campus',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('All campuses'),
                            ),
                            ...snapshot.campuses.map(
                              (c) => DropdownMenuItem(
                                value: c['id'] as String,
                                child: Text(c['name'] as String),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => selectedCampus = v ?? ''),
                        ),
                        const SizedBox(height: 16),
                      ],
                      for (final student in snapshot.students.where(
                        (s) =>
                            (selectedCampus.isEmpty ||
                                s['campus_id'] == selectedCampus) &&
                            '${s['full_name']} ${s['admission_number']} ${s['class_name']}'
                                .toLowerCase()
                                .contains(search),
                      ))
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student['full_name'] as String,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  snapshot.campusName(
                                    student['campus_id'] as String,
                                  ),
                                ),
                                Text(
                                  '${student['class_name']} · Admission ${student['admission_number']}',
                                ),
                                if (snapshot.isStaff)
                                  Text(
                                    '${snapshot.links.where((l) => l['student_id'] == student['id']).length} parent account(s) linked',
                                  ),
                                const SizedBox(height: 12),
                                if (widget.services != null)
                                  FilledButton.icon(
                                    icon: const Icon(Icons.arrow_forward),
                                    label: const Text('Open school services'),
                                    onPressed: () {
                                      final today = schoolToday();
                                      final admin = snapshot.memberships.any(
                                        (m) =>
                                            m['role'] == 'head_office' ||
                                            m['campus_id'] ==
                                                student['campus_id'],
                                      );
                                      final teacher = snapshot.assignments.any(
                                        (a) =>
                                            a['user_id'] ==
                                                widget.services!.userId &&
                                            a['campus_id'] ==
                                                student['campus_id'] &&
                                            a['class_name'] ==
                                                student['class_name'] &&
                                            '${a['starts_on']}'.compareTo(
                                                  today,
                                                ) <=
                                                0 &&
                                            '${a['ends_on']}'.compareTo(
                                                  today,
                                                ) >=
                                                0,
                                      );
                                      final family =
                                          snapshot.links.any(
                                            (l) =>
                                                l['parent_id'] ==
                                                    widget.services!.userId &&
                                                l['student_id'] ==
                                                    student['id'],
                                          ) ||
                                          (!admin && !teacher);
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => StudentWorkspace(
                                            services: widget.services!,
                                            student: student,
                                            campus: snapshot.campusName(
                                              student['campus_id'],
                                            ),
                                            isAdmin: admin,
                                            canTeach: teacher,
                                            isFamily: family,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Text(
                        'Choose a student to open their school services. Pull down to refresh school records.',
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

class SchoolEditor extends StatefulWidget {
  const SchoolEditor({
    super.key,
    required this.repository,
    required this.snapshot,
    required this.kind,
    this.services,
  });
  final SchoolRepository repository;
  final SchoolSnapshot snapshot;
  final StudentServices? services;
  final String kind;
  @override
  State<SchoolEditor> createState() => _SchoolEditorState();
}

class _SchoolEditorState extends State<SchoolEditor> {
  final form = GlobalKey<FormState>();
  final first = TextEditingController(),
      second = TextEditingController(),
      third = TextEditingController();
  String? selected;
  bool busy = false;
  String? error;
  @override
  void dispose() {
    first.dispose();
    second.dispose();
    third.dispose();
    super.dispose();
  }

  String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;
  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      switch (widget.kind) {
        case 'campus':
          await widget.repository.createCampus(
            first.text.trim(),
            second.text.trim(),
          );
        case 'student':
          await widget.repository.createStudent(
            selected!,
            first.text.trim(),
            second.text.trim(),
            third.text.trim(),
          );
        case 'link':
          await widget.repository.linkParent(first.text.trim(), selected!);
        case 'student_login':
          await widget.services!.insert('student_accounts', {
            'user_id': first.text.trim(),
            'student_id': selected!,
          });
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted)
        {
        setState(
          () => error =
              'Could not save. Check for duplicate details, confirm the parent account exists, and make sure your access is still active.',
        );
        }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final linking = kind == 'link' || kind == 'student_login';
    final choices = linking
        ? widget.snapshot.students
        : widget.snapshot.campuses;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          kind == 'campus'
              ? 'Add campus'
              : kind == 'student'
              ? 'Add student'
              : kind == 'student_login'
              ? 'Link student login'
              : 'Link parent',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (kind != 'campus') ...[
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selected,
                        decoration: InputDecoration(
                          labelText: linking ? 'Student' : 'Campus',
                        ),
                        items: choices
                            .map(
                              (item) => DropdownMenuItem(
                                value: item['id'] as String,
                                child: Text(
                                  linking
                                      ? '${item['full_name']} · ${item['admission_number']}'
                                      : item['name'] as String,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: busy
                            ? null
                            : (value) => setState(() => selected = value),
                        validator: requiredText,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (linking)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Enter the existing ${kind == 'student_login' ? 'student' : 'parent'} account ID provided by the school administrator. Check the selected student carefully: this grants account access to their school records.',
                        ),
                      ),
                    TextFormField(
                      controller: first,
                      enabled: !busy,
                      decoration: InputDecoration(
                        labelText: kind == 'campus'
                            ? 'Campus name'
                            : kind == 'student'
                            ? 'Student full name'
                            : 'Account UUID',
                      ),
                      validator: (value) {
                        if (requiredText(value) != null)
                          {
                          return requiredText(value);
                          }
                        if (linking &&
                            !RegExp(
                              r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
                            ).hasMatch(value!.trim()))
                          {
                          return 'Enter a valid account UUID';
                          }
                        return null;
                      },
                    ),
                    if (!linking) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: second,
                        enabled: !busy,
                        decoration: InputDecoration(
                          labelText: kind == 'campus'
                              ? 'Campus code'
                              : 'Admission number',
                        ),
                        validator: requiredText,
                      ),
                    ],
                    if (kind == 'student') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: third,
                        enabled: !busy,
                        decoration: const InputDecoration(
                          labelText: 'Class and section',
                        ),
                        validator: requiredText,
                      ),
                    ],
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(error!),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: busy ? null : save,
                      child: Text(
                        busy
                            ? 'Saving…'
                            : linking
                            ? 'Grant account access'
                            : 'Save',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
