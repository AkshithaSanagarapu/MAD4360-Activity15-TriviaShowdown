import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const TriviaApp());

class TriviaApp extends StatelessWidget {
  const TriviaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'API-to-Cloud Trivia',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const TriviaScreen(),
      );
}

class TriviaQuestion {
  TriviaQuestion({required this.prompt, required this.correct, required this.options});
  final String prompt;
  final String correct;
  final List<String> options;

  factory TriviaQuestion.fromJson(Map<String, dynamic> json) {
    final unescape = HtmlUnescape();
    final correct = unescape.convert(json['correct_answer'] as String);
    final incorrect = (json['incorrect_answers'] as List<dynamic>)
        .map((item) => unescape.convert(item as String))
        .toList();
    final options = [...incorrect, correct]..shuffle(Random());
    return TriviaQuestion(
      prompt: unescape.convert(json['question'] as String),
      correct: correct,
      options: options,
    );
  }
}

class TriviaScreen extends StatefulWidget {
  const TriviaScreen({super.key});
  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  static final Uri _api = Uri.parse(
    'https://opentdb.com/api.php?amount=5&category=9&difficulty=easy&type=multiple',
  );
  List<TriviaQuestion> _questions = [];
  bool _loading = true;
  bool _syncing = false;
  bool _synced = false;
  String? _error;
  String? _selected;
  int _index = 0;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _error = null;
      _questions = [];
      _index = 0;
      _score = 0;
      _selected = null;
      _synced = false;
      _syncing = false;
    });
    try {
      final response = await http.get(_api).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('Server returned HTTP ${response.statusCode}.');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['response_code'] != 0) {
        throw Exception('Trivia API response code: ${data['response_code']}.');
      }
      final results = data['results'] as List<dynamic>;
      if (results.length != 5) {
        throw const FormatException('Expected five trivia questions.');
      }
      final questions = results
          .map((item) => TriviaQuestion.fromJson(item as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() => _questions = questions);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Unable to load questions. Check your internet connection and try again.\n\n$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _answer(String option) {
    if (_selected != null) return;
    setState(() {
      _selected = option;
      if (option == _questions[_index].correct) _score++;
    });
  }

  void _next() {
    if (_selected == null) return;
    setState(() {
      _index++;
      _selected = null;
    });
  }

  Future<void> _simulateSync() async {
    if (_syncing || _synced) return;
    setState(() => _syncing = true);
    final payload = {
      'activity': 'API-to-Cloud Trivia Showdown',
      'score': _score,
      'totalQuestions': _questions.length,
      'submittedAt': DateTime.now().toUtc().toIso8601String(),
    };
    // Classroom simulation only. No POST request or cloud persistence occurs.
    debugPrint('SIMULATED leaderboard payload: ${jsonEncode(payload)}');
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _syncing = false;
      _synced = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Score submission simulated (not saved to cloud).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading) {
      content = const Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(),
        SizedBox(height: 20),
        Text('Fetching five live trivia questions...'),
      ]);
    } else if (_error != null) {
      content = Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off, size: 48),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        FilledButton(onPressed: _loadQuestions, child: const Text('Try again')),
      ]);
    } else if (_index >= _questions.length) {
      content = Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.emoji_events, size: 70, color: Colors.deepPurple),
        const SizedBox(height: 12),
        const Text('Round complete!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Final score: $_score / ${_questions.length}', style: const TextStyle(fontSize: 23)),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _syncing || _synced ? null : _simulateSync,
          icon: _syncing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.cloud_upload),
          label: Text(_synced ? 'Simulation complete' : _syncing ? 'Simulating...' : 'Simulate Score Sync'),
        ),
        const SizedBox(height: 8),
        const Text('Classroom simulation only — no real cloud write.', textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: _loadQuestions, icon: const Icon(Icons.replay), label: const Text('Play again')),
      ]);
    } else {
      final question = _questions[_index];
      content = Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        Text('Question ${_index + 1} of ${_questions.length}', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: (_index + 1) / _questions.length),
        const SizedBox(height: 12),
        Text('Score: $_score', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Text(question.prompt, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        for (final option in question.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FilledButton.tonal(
              onPressed: _selected == null ? () => _answer(option) : null,
              style: FilledButton.styleFrom(
                disabledBackgroundColor: _selected == null
                    ? null
                    : option == question.correct
                        ? Colors.green.shade200
                        : option == _selected
                            ? Colors.red.shade200
                            : Colors.grey.shade200,
                disabledForegroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              ),
              child: Text(option, textAlign: TextAlign.center),
            ),
          ),
        if (_selected != null) ...[
          const SizedBox(height: 8),
          Text(_selected == question.correct ? 'Correct answer!' : 'Incorrect. Correct answer: ${question.correct}',
              style: TextStyle(fontWeight: FontWeight.bold, color: _selected == question.correct ? Colors.green.shade800 : Colors.red.shade800)),
          const SizedBox(height: 14),
          FilledButton(onPressed: _next, child: Text(_index == _questions.length - 1 ? 'View final score' : 'Next question')),
        ],
      ]);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('API-to-Cloud Trivia Showdown')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(child: Padding(padding: const EdgeInsets.all(22), child: content)),
            ),
          ),
        ),
      ),
    );
  }
}
