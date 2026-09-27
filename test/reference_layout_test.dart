import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dhacss_creek_campus_app/src/brand.dart';
import 'package:dhacss_creek_campus_app/src/theme.dart';
import 'package:dhacss_creek_campus_app/src/student_workspace.dart';
import 'package:dhacss_creek_campus_app/src/live_app.dart';
import 'student_workspace_test.dart' show FakeServices, student;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final font = File('${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf');
    final loader = FontLoader('Roboto')..addFont(font.readAsBytes().then((bytes) => ByteData.sublistView(bytes)));
    await loader.load();
    final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  testWidgets('reference home layout preserves live exams and results navigation', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(CampusArtwork.prepare);
    final service = FakeServices();
    await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, theme: campusTheme(), home: StudentWorkspace(
      services: service, student: student, campus: 'Creek Campus', isAdmin: false, canTeach: false, isFamily: true,
    )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/connected-home.png'));
    await tester.ensureVisible(find.text('Results'));
    await tester.tap(find.text('Results'));
    await tester.pumpAndSettle();
    expect(find.text('No records published yet.'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Exam schedule'));
    await tester.tap(find.text('Exam schedule'));
    await tester.pumpAndSettle();
    expect(find.text('No records published yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('narrow home supports enlarged text', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(CampusArtwork.prepare);
    await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, theme: campusTheme(), builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.6)), child: child!,
    ), home: StudentWorkspace(services: FakeServices(), student: student,
      campus: 'Creek Campus', isAdmin: false, canTeach: false, isFamily: true)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView).first, const Offset(0, -550));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('reference login layout', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(CampusArtwork.prepare);
    await tester.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, theme: campusTheme(), home: const LoginPage()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/login.png'));
  });
}
