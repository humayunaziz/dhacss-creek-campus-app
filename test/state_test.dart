import 'package:flutter_test/flutter_test.dart';
import 'package:dhacss_creek_campus_app/src/data.dart';

void main() {
  test('homework and fee state are isolated per student', () {
    final state = CampusState();
    state.toggleHomework('math');
    state.payDemoFee();
    expect(state.homeworkDone('math'), isTrue);
    expect(state.feesPaid, isTrue);
    state.selectStudent(1);
    expect(state.homeworkDone('math'), isFalse);
    expect(state.feesPaid, isFalse);
    state.selectStudent(0);
    expect(state.feesPaid, isTrue);
    state.toggleHomework('math');
    expect(state.homeworkDone('math'), isFalse);
    state.dispose();
  });

  test('chat messages are isolated per student and recipient', () {
    final state = CampusState();
    state.sendMessage('Teacher', 'Thank you');
    expect(state.replies('Teacher'), ['Thank you']);
    expect(state.replies('Office'), isEmpty);
    state.selectStudent(1);
    expect(state.replies('Teacher'), isEmpty);
    state.dispose();
  });

  test('leaves retain student ownership and session does not require credentials', () {
    final state = CampusState();
    state.enterDemo();
    expect(state.signedIn, isTrue);
    final entry = LeaveEntry(state.student.id, 'Medical', DateTime(2026, 9, 20), DateTime(2026, 9, 21), 'Sample leave reason');
    state.requestLeave(entry);
    expect(state.leaveRequests.single.studentId, students.first.id);
    state.signOut();
    expect(state.signedIn, isFalse);
    state.dispose();
  });
}
