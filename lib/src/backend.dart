import 'package:supabase_flutter/supabase_flutter.dart';

typedef Record = Map<String, dynamic>;

class SchoolSnapshot {
  const SchoolSnapshot({
    required this.campuses,
    required this.students,
    required this.memberships,
    required this.links,
    this.assignments = const [],
  });
  final List<Record> campuses, students, memberships, links, assignments;
  bool get isHeadOffice => memberships.any((m) => m['role'] == 'head_office');
  bool get isStaff => memberships.isNotEmpty;
  String campusName(String id) =>
      campuses
          .where((c) => c['id'] == id)
          .map((c) => c['name'] as String)
          .firstOrNull ??
      'Campus';
}

abstract class SchoolRepository {
  Future<SchoolSnapshot> load();
  Future<void> createCampus(String name, String code);
  Future<void> createStudent(
    String campusId,
    String name,
    String admission,
    String className,
  );
  Future<void> linkParent(String parentId, String studentId);
}

class SupabaseSchoolRepository implements SchoolRepository {
  SupabaseSchoolRepository(this.client);
  final SupabaseClient client;
  @override
  Future<SchoolSnapshot> load() async {
    // RLS is authoritative; no unrestricted privileged key exists in this app.
    final results = await Future.wait([
      _all('campuses'),
      _all('students'),
      _all('staff_memberships'),
      _all('parent_student_links', link: true),
      _all('teacher_assignments'),
    ]);
    return SchoolSnapshot(
      campuses: results[0],
      students: results[1],
      memberships: results[2],
      links: results[3],
      assignments: results[4],
    );
  }

  Future<List<Record>> _all(String table, {bool link = false}) async {
    final rows = <Record>[];
    for (var start = 0; ; start += 500) {
      final base = client
          .from(table)
          .select()
          .order(link ? 'student_id' : 'id');
      final page = await (link ? base.order('parent_id') : base).range(
        start,
        start + 499,
      );
      rows.addAll(page);
      if (page.length < 500) return rows;
    }
  }

  @override
  Future<void> createCampus(String name, String code) async {
    await client.from('campuses').insert({'name': name, 'code': code});
  }

  @override
  Future<void> createStudent(
    String campusId,
    String name,
    String admission,
    String className,
  ) async {
    await client.from('students').insert({
      'campus_id': campusId,
      'full_name': name,
      'admission_number': admission,
      'class_name': className,
    });
  }

  @override
  Future<void> linkParent(String parentId, String studentId) async {
    await client.from('parent_student_links').insert({
      'parent_id': parentId,
      'student_id': studentId,
    });
  }
}

/// Live services use the signed-in user's client and database row policies.
abstract class StudentServices {
  String? get userId;
  Future<List<Record>> records(String table, Record student);
  Future<void> insert(String table, Record values);
  Future<void> update(String table, String id, Record values);
  Future<void> remove(String table, String id);
  Future<void> reviewLeave(String id, String decision, String note);
  Future<void> attendance(String studentId, String date, String status);
}

class SupabaseStudentServices implements StudentServices {
  SupabaseStudentServices(this.client);
  final SupabaseClient client;
  @override
  String? get userId => client.auth.currentUser?.id;
  @override
  Future<List<Record>> records(String table, Record student) async {
    final all = <Record>[];
    // Page deterministically so classes with large histories are not truncated.
    for (var start = 0; ; start += 500) {
      var query = client.from(table).select();
      if (table == 'homework' || table == 'school_publications') {
        query = query.eq('campus_id', student['campus_id']);
        if (table == 'homework')
          {
          query = query.eq('class_name', student['class_name']);
          }
      } else {
        query = query.eq('student_id', student['id']);
      }
      final rows = await query
          .order(table == 'attendance' ? 'attendance_date' : 'id')
          .range(start, start + 499);
      all.addAll(rows);
      if (rows.length < 500) break;
    }
    return table == 'school_publications'
        ? all
              .where(
                (r) =>
                    r['class_name'] == null ||
                    r['class_name'] == student['class_name'],
              )
              .toList()
        : all;
  }

  @override
  Future<void> insert(String table, Record values) async {
    await client.from(table).insert(values);
  }

  @override
  Future<void> update(String table, String id, Record values) async {
    await client.from(table).update(values).eq('id', id).select().single();
  }

  @override
  Future<void> remove(String table, String id) async {
    await client.from(table).delete().eq('id', id).select().single();
  }

  @override
  Future<void> reviewLeave(String id, String decision, String note) async {
    await client.rpc(
      'review_school_leave',
      params: {'request_id': id, 'decision': decision, 'note': note},
    );
  }

  @override
  Future<void> attendance(String studentId, String date, String status) async {
    await client.rpc(
      'record_attendance',
      params: {
        'day': date,
        'entries': [
          {'student_id': studentId, 'status': status},
        ],
      },
    );
  }
}
