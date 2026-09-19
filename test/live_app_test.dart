import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dhacss_creek_campus_app/src/backend.dart';
import 'package:dhacss_creek_campus_app/src/live_app.dart';

class FakeSchoolRepository implements SchoolRepository {
  FakeSchoolRepository(this.snapshot);
  final SchoolSnapshot snapshot;
  bool fail = false;
  @override
  Future<SchoolSnapshot> load() async {
    if (fail) throw Exception('offline');
    return snapshot;
  }
  @override
  Future<void> createCampus(String name, String code) async {}
  @override
  Future<void> createStudent(String campusId, String name, String admission, String className) async {}
  @override
  Future<void> linkParent(String parentId, String studentId) async {}
}

const parentData = SchoolSnapshot(campuses: [{'id': 'c1', 'name': 'Test Campus', 'code': 'TC'}],
  students: [{'id': 's1', 'campus_id': 'c1', 'full_name': 'Test Child', 'admission_number': 'A001', 'class_name': 'Grade 1'}],
  memberships: [], links: []);

void main() {
  testWidgets('unconfigured build offers explicit demo and return path', (tester) async {
    await tester.pumpWidget(const SchoolApp());
    expect(find.textContaining('not connected'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
    await tester.tap(find.text('Explore offline demo'));
    await tester.pumpAndSettle();
    expect(find.text('Offline demo'), findsOneWidget);
    await tester.tap(find.byType(BackButton).first);
    await tester.pumpAndSettle();
    expect(find.text('Explore offline demo'), findsOneWidget);
  });

  testWidgets('parent sees real returned child without staff actions or fake balances', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SchoolDashboard(
      repository: FakeSchoolRepository(parentData), onLogout: () async {}, email: 'parent@example.test')));
    await tester.pumpAndSettle();
    expect(find.text('Test Child'), findsOneWidget);
    expect(find.text('Test Campus'), findsOneWidget);
    expect(find.text('Add campus'), findsNothing);
    expect(find.text('Add student'), findsNothing);
    expect(find.text('Ayan Ahmed'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed data request shows retry and can recover', (tester) async {
    final repository = FakeSchoolRepository(parentData)..fail = true;
    await tester.pumpWidget(MaterialApp(home: SchoolDashboard(
      repository: repository, onLogout: () async {}, email: 'parent@example.test')));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Test Child'), findsNothing);
    repository.fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Test Child'), findsOneWidget);
  });

  testWidgets('unlinked parent receives honest empty state', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SchoolDashboard(
      repository: FakeSchoolRepository(const SchoolSnapshot(campuses: [], students: [], memberships: [], links: [])),
      onLogout: () async {}, email: 'parent@example.test')));
    await tester.pumpAndSettle();
    expect(find.textContaining('No children are linked'), findsOneWidget);
  });

  testWidgets('campus admin cannot create campuses in UI', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SchoolDashboard(
      repository: FakeSchoolRepository(const SchoolSnapshot(campuses: [], students: [],
        memberships: [{'role': 'campus_admin', 'campus_id': 'c1'}], links: [])),
      onLogout: () async {}, email: 'admin@example.test')));
    await tester.pumpAndSettle();
    expect(find.text('Add campus'), findsNothing);
    expect(find.text('Add student'), findsOneWidget);
  });
}
