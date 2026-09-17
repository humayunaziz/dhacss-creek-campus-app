import 'package:flutter/material.dart';

class Student {
  const Student(this.id, this.name, this.grade, this.initials, this.attendance);
  final String id;
  final String name;
  final String grade;
  final String initials;
  final int attendance;
}

const students = [
  Student('CC-24018', 'Ayan Ahmed', 'Grade 7 · Section A', 'AA', 96),
  Student('CC-25042', 'Sara Ahmed', 'Grade 4 · Section B', 'SA', 98),
];

class Lesson {
  const Lesson(this.time, this.subject, this.detail, this.icon, this.color);
  final String time;
  final String subject;
  final String detail;
  final IconData icon;
  final Color color;
}

const lessons = [
  Lesson('08:00', 'Mathematics', 'Ms. Fatima · Room 12', Icons.functions_rounded, Color(0xFFEDE8F7)),
  Lesson('08:45', 'English', 'Ms. Sana · Room 12', Icons.auto_stories_rounded, Color(0xFFFFEEE0)),
  Lesson('09:30', 'Science', 'Mr. Hassan · Science lab', Icons.science_outlined, Color(0xFFE3F2E9)),
  Lesson('10:45', 'Urdu', 'Ms. Ayesha · Room 12', Icons.menu_book_rounded, Color(0xFFE5EFFB)),
  Lesson('11:30', 'Computer studies', 'Mr. Ali · Computer lab', Icons.computer_rounded, Color(0xFFFFEEE0)),
];

class Assignment {
  const Assignment(this.id, this.subject, this.title, this.description, this.due);
  final String id;
  final String subject;
  final String title;
  final String description;
  final String due;
}

const assignments = [
  Assignment('math', 'Mathematics', 'Fractions, made simple', 'Complete exercises 4.1 and 4.2 in your notebook. Show your working for each answer.', 'Due tomorrow'),
  Assignment('science', 'Science', 'Our solar system', 'Draw and label the planets. Write three interesting facts about your favourite planet.', 'Due Friday'),
  Assignment('english', 'English', 'A place I love', 'Write a short descriptive paragraph about a place that makes you happy.', 'Due Monday'),
];

class CampusMessage {
  const CampusMessage(this.name, this.role, this.initials, this.preview, this.time);
  final String name;
  final String role;
  final String initials;
  final String preview;
  final String time;
}

const campusMessages = [
  CampusMessage('Ms. Fatima Khan', 'Class teacher', 'FK', 'Ayan did a wonderful job in class today!', '9:41 AM'),
  CampusMessage('School office', 'Administration', 'SO', 'Parent–teacher meeting: sample invitation inside.', 'Yesterday'),
  CampusMessage('Transport desk', 'Campus transport', 'TD', 'Your route information is ready to view.', 'Tuesday'),
];

class LeaveEntry {
  LeaveEntry(this.studentId, this.type, this.start, this.end, this.reason);
  final String studentId;
  final String type;
  final DateTime start;
  final DateTime end;
  final String reason;
}

/// Demo state is intentionally local and resets when the application restarts.
class CampusState extends ChangeNotifier {
  int selectedStudent = 0;
  bool signedIn = false;
  final Set<String> completedHomework = {};
  final Set<String> paidStudents = {};
  final List<LeaveEntry> leaveRequests = [];
  final Map<String, List<String>> sentMessages = {};
  Student get student => students[selectedStudent];
  bool get feesPaid => paidStudents.contains(student.id);
  bool homeworkDone(String id) => completedHomework.contains('${student.id}:$id');
  void enterDemo() { signedIn = true; notifyListeners(); }
  void signOut() { signedIn = false; notifyListeners(); }
  void selectStudent(int index) { selectedStudent = index; notifyListeners(); }
  void toggleHomework(String id) {
    final key = '${student.id}:$id';
    if (!completedHomework.remove(key)) { completedHomework.add(key); }
    notifyListeners();
  }
  void payDemoFee() { paidStudents.add(student.id); notifyListeners(); }
  void requestLeave(LeaveEntry entry) { leaveRequests.add(entry); notifyListeners(); }
  void sendMessage(String recipient, String text) {
    (sentMessages['${student.id}:$recipient'] ??= []).add(text);
    notifyListeners();
  }
  List<String> replies(String recipient) => sentMessages['${student.id}:$recipient'] ?? [];
}
