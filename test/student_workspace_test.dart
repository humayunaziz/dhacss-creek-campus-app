import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dhacss_creek_campus_app/src/backend.dart';
import 'package:dhacss_creek_campus_app/src/student_workspace.dart';

class FakeServices implements StudentServices {
  @override
  String? get userId => 'parent1';
  List<Record> rows = [];
  bool fail = false;
  Record? written;
  @override
  Future<List<Record>> records(String table, Record student) async {
    if (fail) throw Exception('offline');
    return rows;
  }

  @override
  Future<void> insert(String table, Record values) async {
    written = values;
  }

  @override
  Future<void> update(String table, String id, Record values) async {
    written = values;
  }

  @override
  Future<void> remove(String table, String id) async {}
  @override
  Future<void> reviewLeave(String id, String decision, String note) async {}
  @override
  Future<void> attendance(String studentId, String date, String status) async {}
}

const student = {
  'id': 's1',
  'campus_id': 'c1',
  'full_name': 'Test child',
  'class_name': 'One',
  'admission_number': '001',
  'status': 'active',
};
Widget records(FakeServices service, String table, {bool staff = false}) =>
    MaterialApp(
      home: SchoolRecordsPage(
        services: service,
        student: student,
        title: 'Records',
        table: table,
        isAdmin: staff,
        canTeach: false,
        isFamily: !staff,
      ),
    );
void main() {
  testWidgets('empty live data never shows demo information', (tester) async {
    await tester.pumpWidget(records(FakeServices(), 'monthly_fee_bills'));
    await tester.pumpAndSettle();
    expect(find.text('No records published yet.'), findsOneWidget);
    expect(
      find.textContaining('Online payment is not connected'),
      findsOneWidget,
    );
    expect(find.byType(FloatingActionButton), findsNothing);
  });
  testWidgets('parent sees homework but cannot publish or edit it', (
    tester,
  ) async {
    final service = FakeServices()
      ..rows = [
        {
          'id': 'h1',
          'subject': 'Math',
          'title': 'Fractions',
          'due_date': '2026-10-01',
          'instructions': 'Complete exercise 1',
          'created_at': '2026-09-25',
        },
      ];
    await tester.pumpWidget(records(service, 'homework'));
    await tester.pumpAndSettle();
    expect(find.text('Math · Fractions'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });
  testWidgets('staff can publish homework', (tester) async {
    await tester.pumpWidget(records(FakeServices(), 'homework', staff: true));
    await tester.pumpAndSettle();
    expect(find.text('Add record'), findsOneWidget);
  });
  testWidgets('retry recovers without showing stale content', (tester) async {
    final service = FakeServices()..fail = true;
    await tester.pumpWidget(records(service, 'homework'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load records.'), findsOneWidget);
    service.fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('No records published yet.'), findsOneWidget);
  });
  testWidgets('pending family leave cannot be self approved', (tester) async {
    final service = FakeServices()
      ..rows = [
        {
          'id': 'l1',
          'requested_by': 'parent1',
          'status': 'pending',
          'starts_on': '2026-10-01',
          'ends_on': '2026-10-02',
          'reason': 'Family event',
          'response': '',
          'created_at': '2026-09-25',
        },
      ];
    await tester.pumpWidget(records(service, 'leave_requests'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel request'), findsOneWidget);
    expect(find.text('Approve'), findsNothing);
    expect(find.text('Reject'), findsNothing);
  });
  testWidgets('result editor rejects marks above total', (tester) async {
    final service = FakeServices();
    await tester.pumpWidget(
      MaterialApp(
        home: SchoolRecordEditor(
          services: service,
          student: student,
          table: 'student_results',
        ),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Exam name'),
      'Term 1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Subject'),
      'Math',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Marks obtained'),
      '101',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Total marks'),
      '100',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('marks cannot exceed'), findsOneWidget);
    expect(service.written, isNull);
  });
}
