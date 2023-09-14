// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/services/user_prompts/survey_manager.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unified_analytics/unified_analytics.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SurveyManagerTest);
  });
}

@reflectiveTest
class SurveyManagerTest with ResourceProviderMixin {
  final instrumentationService = NoopInstrumentationService();
  final analytics = TestAnalytics();
  late final TestServer server;
  late final TestSurveyManager manager;
  int nextSurveyNum = 1;

  void setUp() {
    server = TestServer(instrumentationService);
  }

  void tearDown() {
    manager.shutdown();
  }

  Future<void> test_frequency_waitsForInitialDelay() async {
    _createManager(
      initialDelay: const Duration(seconds: 10),
      checkFrequency: Duration.zero,
    );
    await pumpEventQueue(times: 5000);
    expect(manager.numberOfChecksPerformed, isZero);
  }

  Future<void> test_frequency_waitsForSubsequentDelay() async {
    // Default values are 0 initial delay, 1m frequency.
    _createManager();
    await pumpEventQueue(times: 5000);
    // Expect the first check and no more.
    expect(manager.numberOfChecksPerformed, 1);
  }

  Future<void> test_survey_response() async {
    analytics.surveys = [
      _survey(
        'Which letter?',
        [
          _button('A', url: 'a'),
          _button('B', url: 'b'),
          _button('C'),
        ],
      )
    ];
    server.respondWithButton = 'C';
    _createManager();
    await pumpEventQueue(times: 5000);

    expect(manager.numberOfChecksPerformed, 1);
    expect(analytics.shownSurveys, [analytics.surveys.single.uniqueId]);
    expect(server.openedUris, isEmpty);
    expect(analytics.recordedInteractions, ['C']);
  }

  Future<void> test_survey_responseWithUrl() async {
    analytics.surveys = [
      _survey(
        'Which letter?',
        [
          _button('A', url: 'a'),
          _button('B', url: 'b'),
          _button('C'),
        ],
      )
    ];
    server.respondWithButton = 'B';
    _createManager();
    await pumpEventQueue(times: 5000);

    expect(manager.numberOfChecksPerformed, 1);
    expect(analytics.shownSurveys, [analytics.surveys.single.uniqueId]);
    expect(server.openedUris, [Uri.parse('b')]);
    expect(analytics.recordedInteractions, ['B']);
  }

  Future<void> test_unavailable_noOpenUriSupport() async {
    server.supportsOpenUri = false;
    analytics.surveys = [
      _survey('Which letter?', [_button('A')])
    ];
    server.respondWithButton = 'A';
    _createManager();
    await pumpEventQueue(times: 5000);

    expect(manager.numberOfChecksPerformed, 1);
    expect(analytics.shownSurveys, isEmpty);
    expect(server.openedUris, isEmpty);
    expect(analytics.recordedInteractions, isEmpty);
  }

  Future<void> test_unavailable_noShowMessageRequestSupport() async {
    server.supportsShowMessageRequest = false;
    analytics.surveys = [
      _survey('Which letter?', [_button('A')])
    ];
    server.respondWithButton = 'A';
    _createManager();
    await pumpEventQueue(times: 5000);

    expect(manager.numberOfChecksPerformed, 1);
    expect(analytics.shownSurveys, isEmpty);
    expect(server.openedUris, isEmpty);
    expect(analytics.recordedInteractions, isEmpty);
  }

  SurveyButton _button(String text, {String? url}) {
    return SurveyButton(
      buttonText: text,
      url: url,
      action: '',
      promptRemainsVisible: false,
    );
  }

  void _createManager({
    Duration initialDelay = Duration.zero,
    Duration checkFrequency = const Duration(minutes: 1),
  }) {
    manager = TestSurveyManager(
      server,
      instrumentationService,
      analytics,
      initialDelay: initialDelay,
      checkFrequency: checkFrequency,
    );
  }

  Survey _survey(String description, List<SurveyButton> buttons) {
    return Survey(
      uniqueId: 'survey${nextSurveyNum++}',
      buttonList: buttons,
      startDate: DateTime.now(),
      endDate: DateTime.now(),
      description: description,
      samplingRate: 1,
      snoozeForMinutes: 1,
      conditionList: [],
    );
  }
}

class TestAnalytics implements Analytics {
  List<Survey> surveys = [];

  /// The interactions that were recorded via [surveyInteracted].
  final List<String> recordedInteractions = [];

  /// The IDs of surveys that were shown.
  final List<String> shownSurveys = [];

  @override
  Future<List<Survey>> fetchAvailableSurveys() async {
    return surveys;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void surveyInteracted({
    required Survey survey,
    required SurveyButton surveyButton,
  }) {
    recordedInteractions.add(surveyButton.buttonText);
  }

  @override
  void surveyShown(Survey survey) {
    shownSurveys.add(survey.uniqueId);
  }
}

class TestServer implements AnalysisServer {
  @override
  final InstrumentationService instrumentationService;

  /// The URIs that the server sent to be opened by the client.
  final List<Uri> openedUris = [];

  /// Text text of the button to simulate clicking.
  String? respondWithButton;

  @override
  bool supportsShowMessageRequest = true;

  bool supportsOpenUri = true;

  TestServer(this.instrumentationService);

  @override
  OpenUriNotificationSender? get openUriNotificationSender =>
      supportsOpenUri ? (uri) async => openedUris.add(uri) : null;

  @override
  UserPromptSender? get userPromptSender =>
      supportsShowMessageRequest ? _handlePrompt : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  /// Handle a prompt by returning the text from the button matching
  /// [respondWithButton].
  Future<String?> _handlePrompt(
      MessageType type, String message, List<String> actionLabels) async {
    return actionLabels.where((s) => s == respondWithButton).firstOrNull;
  }
}

class TestSurveyManager extends SurveyManager {
  int numberOfChecksPerformed = 0;

  TestSurveyManager(
    super.server,
    super.instrumentationService,
    super.analytics, {
    super.initialDelay,
    super.checkFrequency,
  });

  @override
  Future<void> checkForSurveys() async {
    numberOfChecksPerformed++;
    return super.checkForSurveys();
  }
}
