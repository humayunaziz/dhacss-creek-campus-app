import 'package:supabase_flutter/supabase_flutter.dart';

typedef Record = Map<String, dynamic>;

class SchoolSnapshot {
  const SchoolSnapshot({required this.campuses, required this.students,
    required this.memberships, required this.links});
  final List<Record> campuses, students, memberships, links;
  bool get isHeadOffice => memberships.any((m) => m['role'] == 'head_office');
  bool get isStaff => memberships.isNotEmpty;
  String campusName(String id) => campuses.where((c) => c['id'] == id)
      .map((c) => c['name'] as String).firstOrNull ?? 'Campus';
}

abstract class SchoolRepository {
  Future<SchoolSnapshot> load();
  Future<void> createCampus(String name, String code);
  Future<void> createStudent(String campusId, String name, String admission, String className);
  Future<void> linkParent(String parentId, String studentId);
}

class SupabaseSchoolRepository implements SchoolRepository {
  SupabaseSchoolRepository(this.client);
  final SupabaseClient client;
  @override
  Future<SchoolSnapshot> load() async {
    // RLS is authoritative; no unrestricted privileged key exists in this app.
    final results = await Future.wait([
      client.from('campuses').select().order('name'),
      client.from('students').select().order('full_name'),
      client.from('staff_memberships').select(),
      client.from('parent_student_links').select(),
    ]);
    return SchoolSnapshot(campuses: results[0], students: results[1],
      memberships: results[2], links: results[3]);
  }
  @override
  Future<void> createCampus(String name, String code) async {
    await client.from('campuses').insert({'name': name, 'code': code});
  }
  @override
  Future<void> createStudent(String campusId, String name, String admission, String className) async {
    await client.from('students').insert({'campus_id': campusId,
      'full_name': name, 'admission_number': admission, 'class_name': className});
  }
  @override
  Future<void> linkParent(String parentId, String studentId) async {
    await client.from('parent_student_links').insert({'parent_id': parentId, 'student_id': studentId});
  }
}
