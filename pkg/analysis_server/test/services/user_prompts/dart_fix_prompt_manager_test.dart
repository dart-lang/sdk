// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/services/user_prompts/dart_fix_prompt_manager.dart';
import 'package:analysis_server/src/services/user_prompts/user_prompts.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartFixPromptTest);
  });
}

@reflectiveTest
class DartFixPromptTest with ResourceProviderMixin {
  late TestServer server;
  late TestDartFixPromptManager promptManager;
  late UserPromptPreferences preferences;
  void setUp() {
    final instrumentationService = NoopInstrumentationService();
    server = TestServer(instrumentationService);
    preferences = UserPromptPreferences(
      resourceProvider,
      instrumentationService,
    );
    promptManager = TestDartFixPromptManager(server, preferences);
  }

  Future<void> test_check_ifCheckedRecently_contextConstraintsChanged() async {
    // Always say there are no fixes (to allow multiple checks).
    promptManager.bulkFixesAvailableOverride = Future.value(false);

    // First trigger should work.
    promptManager.currentContextSdkConstraints = {
      'dummy-path': '>=2.19.0',
    };
    promptManager.triggerCheck();
    await pumpEventQueue(times: 5000);
    expect(promptManager.checksPerformed, 1);

    // Second trigger should also work because we changed the version constraint.
    promptManager.currentContextSdkConstraints = {
      'dummy-path': '>=3.0.0',
    };
    promptManager.triggerCheck();
    await pumpEventQueue(times: 5000);
    expect(promptManager.checksPerformed, 2);
  }

  Future<void> test_check_ifCheckedRecently_contextPathsChanged() async {
    // Always say there are no fixes (to allow multiple checks).
    promptManager.bulkFixesAvailableOverride = Future.value(false);

    // First trigger should work.
    promptManager.triggerCheck();
    await pumpEventQueue(times: 5000);
    expect(promptManager.checksPerformed, 1);

    // Second trigger should also work because we changed the context roots.
    promptManager.currentContextSdkConstraints = {
      'dummy-path': '>=2.19.0',
    };
    promptManager.triggerCheck();
    await pumpEventQueue(times: 5000);
    expect(promptManager.checksPerformed, 2);
  }

  Future<void> test_check_ifLastCheckedLongAgo() async {
    // Always say there are no fixes (to allow multiple checks).
    promptManager.bulkFixesAvailableOverride = Future.value(false);

    // First trigger should work.
    promptManager.triggerCheck();
    await pumpEventQueue(times: 5000);
    expect(promptManager.checksPerformed, 1);

    // Move the last check to an hour ago and ensure we check again.
    promptManager.lastCheck = DateTime.now().add(Duration(hours: -1));
    promptManager.triggerCheck();
    await pumpEventQueue(times: 5000);
    expect(promptManager.checksPerformed, 2);
  }

  Future<void> test_check_notIfCheckedRecently() async {
    // Always say there are no fixes (to allow multiple checks).
    promptManager.bulkFixesAvailableOverride = Future.value(false);

    // First trigger should work.
    promptManager.triggerCheck();
    await pumpEventQueue(times: 5000);
    expect(promptManager.checksPerformed, 1);

    // Second trigger should do nothing because we checked recently.
    promptManager.triggerCheck();
    await pumpEventQueue(times: 5000);
    expect(promptManager.checksPerformed, 1);
  }

  Future<void> test_check_notIfNoMessageRequestSupport() async {
    server.supportsShowMessageRequest = false;
    promptManager.triggerCheck();
    await pumpEventQueue(times: 5000);
    expect(promptManager.checksPerformed, 0);
  }

  Future<void> test_check_notIfNoOpenUriSupport() async {
    server.openUriNotificationSender = null;
    promptManager.triggerCheck();
    await pumpEventQueue(times: 5000);
    expect(promptManager.checksPerformed, 0);
  }

  Future<void> test_check_notIOptedOut() async {
    preferences.showDartFixPrompts = false;
    promptManager.triggerCheck();
    await pumpEventQueue(times: 5000);
    expect(promptManager.checksPerformed, 0);
  }

  Future<void> test_check_oncePerSession() async {
    // First trigger should work.
    promptManager.triggerCheck();
    await pumpEventQueue(times: 5000);
    expect(promptManager.checksPerformed, 1);

    // Second trigger should do nothing because we'd already triggered a prompt.
    promptManager.lastCheck = null; // bypass "recent" check
    promptManager.triggerCheck();
    await pumpEventQueue(times: 5000);
    expect(promptManager.checksPerformed, 1);
  }

  Future<void> test_check_returnsFalseIfCancelled() async {
    // Trigger 50 checks at once. Each one should cancel the previous, with only
    // the final one completing.
    final futures = List.generate(50, (_) => promptManager.performCheck());
    await pumpEventQueue(times: 5000);
    final results = await Future.wait(futures);

    // Expect the first 49 to be false, the last to be true.
    expect(results.sublist(0, 49), everyElement(isFalse));
    expect(results.last, isTrue);
  }

  Future<void> test_prompt_ifFixes() async {
    promptManager.triggerCheck();
    await pumpEventQueue(times: 5000);
    expect(promptManager.promptsShown, 1);
  }

  Future<void> test_prompt_notIfNoFixes() async {
    promptManager.bulkFixesAvailableOverride = Future.value(false);
    promptManager.triggerCheck();
    await pumpEventQueue(times: 5000);
    expect(promptManager.promptsShown, 0);
  }

  Future<void> test_prompt_notIfNoMessageRequestSupport() async {
    server.supportsShowMessageRequest = false;
    promptManager.triggerCheck();
    await pumpEventQueue(times: 5000);
    expect(promptManager.promptsShown, 0);
  }

  Future<void> test_prompt_notIfNoOpenUriSupport() async {
    server.openUriNotificationSender = null;
    promptManager.triggerCheck();
    await pumpEventQueue(times: 5000);
    expect(promptManager.promptsShown, 0);
  }

  Future<void> test_prompt_notIfOptedOut() async {
    preferences.showDartFixPrompts = false;
    promptManager.triggerCheck();
    await pumpEventQueue(times: 5000);
    expect(promptManager.promptsShown, 0);
  }
}

class TestDartFixPromptManager extends DartFixPromptManager {
  int checksPerformed = 0;
  int promptsShown = 0;

  @override
  Map<String, String?> currentContextSdkConstraints = {};

  Future<bool> bulkFixesAvailableOverride = Future.value(true);

  TestDartFixPromptManager(super.server, super.preferences);

  @override
  Future<bool> bulkFixesAvailable(CancellationToken token) {
    checksPerformed++;
    return bulkFixesAvailableOverride;
  }

  @override
  Future<void> showPrompt({
    required UserPromptSender userPromptSender,
    required OpenUriNotificationSender openUriNotificationSender,
  }) {
    promptsShown++;
    return super.showPrompt(
      userPromptSender: userPromptSender,
      openUriNotificationSender: openUriNotificationSender,
    );
  }
}

class TestServer implements LspAnalysisServer {
  @override
  final InstrumentationService instrumentationService;

  @override
  bool supportsShowMessageRequest = true;

  @override
  OpenUriNotificationSender? openUriNotificationSender = (_) async {};

  TestServer(this.instrumentationService);

  @override
  UserPromptSender? get userPromptSender =>
      supportsShowMessageRequest ? (_, __, ___) async => null : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
