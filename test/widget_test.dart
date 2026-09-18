import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dhacss_creek_campus_app/src/app.dart';
import 'package:dhacss_creek_campus_app/src/data.dart';
import 'package:dhacss_creek_campus_app/src/screens.dart';
import 'package:dhacss_creek_campus_app/src/theme.dart';

void main() {
  Future<void> enterDemo(WidgetTester tester) async {
    await tester.pumpWidget(const CreekCampusApp());
    await tester.ensureVisible(find.byKey(const Key('enter-demo')));
    await tester.tap(find.byKey(const Key('enter-demo')));
    await tester.pumpAndSettle();
  }

  testWidgets('welcome enters the parent dashboard', (tester) async {
    await enterDemo(tester);
    expect(find.text('Hello, Ahmed family'), findsOneWidget);
    expect(find.text('Ayan Ahmed'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('student switcher selects the second child', (tester) async {
    await enterDemo(tester);
    await tester.tap(find.text('Ayan Ahmed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sara Ahmed'));
    await tester.pumpAndSettle();
    expect(find.text('Sara Ahmed'), findsOneWidget);
    expect(find.text('Grade 4 · Section B'), findsOneWidget);
  });

  testWidgets('all bottom destinations open', (tester) async {
    await enterDemo(tester);
    for (final item in <String, String>{
      'Academics': 'Room to flourish',
      'Services': 'Your school essentials',
      'Messages': 'Good conversations\nstart here.',
      'Profile': 'Your little school world',
      'Home': 'Hello, Ahmed family',
    }.entries) {
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(item.key)));
      await tester.pumpAndSettle();
      expect(find.text(item.value), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('homework can be marked complete locally', (tester) async {
    final state = CampusState();
    await tester.pumpWidget(MaterialApp(theme: campusTheme(), home: HomeworkPage(state: state)));
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(state.homeworkDone('math'), isTrue);
    expect(find.text('Done locally'), findsOneWidget);
    state.dispose();
  });

  testWidgets('demo payment requires confirmation and shows a receipt', (tester) async {
    final state = CampusState();
    await tester.pumpWidget(MaterialApp(theme: campusTheme(), home: FeesPage(state: state)));
    await tester.ensureVisible(find.text('Simulate payment'));
    await tester.tap(find.text('Simulate payment'));
    await tester.pumpAndSettle();
    expect(state.feesPaid, isFalse);
    await tester.tap(find.text('Confirm demo payment'));
    await tester.pumpAndSettle();
    expect(state.feesPaid, isTrue);
    expect(find.text('Demo receipt'), findsOneWidget);
    state.dispose();
  });

  testWidgets('leave request validates the reason', (tester) async {
    final state = CampusState();
    await tester.pumpWidget(MaterialApp(theme: campusTheme(), home: LeavePage(state: state)));
    await tester.ensureVisible(find.text('Save demo request'));
    await tester.tap(find.text('Save demo request'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter a reason of at least 10 characters.'), findsOneWidget);
    expect(state.leaveRequests, isEmpty);
    state.dispose();
  });

  testWidgets('dashboard fits a narrow phone without layout exceptions', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previousHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details, forceReport: true);
      previousHandler?.call(details);
    };
    await enterDemo(tester);
    FlutterError.onError = previousHandler;
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -550));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard fits a tablet viewport', (tester) async {
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await enterDemo(tester);
    expect(tester.takeException(), isNull);
  });
}
