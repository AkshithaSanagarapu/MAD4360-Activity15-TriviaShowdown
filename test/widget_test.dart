import 'dart:async';
import 'dart:convert';

import 'package:activity15_api_cloud_trivia/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

http.Response sampleRound() => http.Response(
      jsonEncode({
        'response_code': 0,
        'results': List.generate(5, (i) => {
          'question': 'Test question ${i + 1} &amp; friends?',
          'correct_answer': 'Correct ${i + 1}',
          'incorrect_answers': ['Wrong A $i', 'Wrong B $i', 'Wrong C $i'],
        }),
      }),
      200,
    );

Future<void> startApp(
  WidgetTester tester,
  Future<http.Response> Function(Uri) fetch,
) async {
  tester.view.physicalSize = const Size(1100, 1500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: TriviaScreen(fetchQuestions: fetch)));
}

Future<void> answerAndAdvance(WidgetTester tester, int n) async {
  await tester.tap(find.text('Correct $n'));
  await tester.pump();
  expect(find.text('Correct answer!'), findsOneWidget);
  await tester.tap(find.text(n == 5 ? 'View final score' : 'Next question'));
  await tester.pump();
}

void main() {
  testWidgets('Loading shows until the request finishes; questions decode HTML', (tester) async {
    final pending = Completer<http.Response>();
    await startApp(tester, (_) => pending.future);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Fetching five live trivia questions...'), findsOneWidget);
    pending.complete(sampleRound());
    await tester.pumpAndSettle();
    expect(find.text('Question 1 of 5'), findsOneWidget);
    expect(find.text('Test question 1 & friends?'), findsOneWidget);
  });

  testWidgets('HTTP failure displays an error and Retry recovers', (tester) async {
    var requests = 0;
    await startApp(tester, (_) async {
      requests++;
      return requests == 1 ? http.Response('Unavailable', 503) : sampleRound();
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('Unable to load questions'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Question 1 of 5'), findsOneWidget);
    expect(requests, 2);
  });

  testWidgets('API-level failure shows retry instead of incomplete questions', (tester) async {
    await startApp(tester, (_) async => http.Response(
      jsonEncode({'response_code': 1, 'results': []}), 200));
    await tester.pumpAndSettle();
    expect(find.textContaining('Unable to load questions'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Question 1 of 5'), findsNothing);
  });

  testWidgets('Only first answer counts, then replay resets and fetches again', (tester) async {
    var requests = 0;
    await startApp(tester, (_) async {
      requests++;
      return sampleRound();
    });
    await tester.pumpAndSettle();
    await tester.tap(find.text('Correct 1'));
    await tester.pump();
    expect(find.text('Score: 1'), findsOneWidget);
    // All answer buttons become disabled after the first selection.
    final wrong = tester.widget<FilledButton>(
      find.ancestor(of: find.text('Wrong A 0'), matching: find.byType(FilledButton)));
    expect(wrong.onPressed, isNull);
    final correct = tester.widget<FilledButton>(
      find.ancestor(of: find.text('Correct 1'), matching: find.byType(FilledButton)));
    expect(correct.onPressed, isNull);
    expect(find.text('Score: 1'), findsOneWidget);
    await tester.tap(find.text('Next question'));
    await tester.pump();
    for (var n = 2; n <= 5; n++) {
      await answerAndAdvance(tester, n);
    }
    expect(find.text('Final score: 5 / 5'), findsOneWidget);
    await tester.tap(find.text('Play again'));
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(find.text('Question 1 of 5'), findsOneWidget);
    expect(find.text('Score: 0'), findsOneWidget);
  });
}
