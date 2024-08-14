// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart'
    show ExecuteCommandParams;
import 'package:analysis_server/src/analysis_server.dart'
    show
        AnalysisServer,
        MessageType,
        OpenUriNotificationSender,
        UserPromptSender;
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handler_execute_command.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server/src/services/user_prompts/user_prompts.dart';
import 'package:analysis_server_plugin/src/correction/dart_change_workspace.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Handles prompting the user to run "dart fix" when they have diagnostics that
/// it can fix.
class DartFixPromptManager {
  /// The minimum frequency we will attempt to detect if we can bulk fix
  /// diagnostics.
  ///
  /// Although we will only prompt once per session, if we never show a prompt
  /// (because there are no fixable items) we might still be caused to search
  /// multiple times (eg. the user keeps running "pub get").
  ///
  /// Since the check is expensive, after any check we will "sleep" for this
  /// period before any more checks.
  static const _sleepTime = Duration(minutes: 10);

  static const externalFixPromptText =
      'Your project contains issues that can be fixed by running "dart fix" from the command line.';

  static const inEditorPromptText =
      'Your project contains issues that can be fixed automatically.';

  static const learnMoreActionText = 'Learn More';

  static const previewFixesActionText = 'Preview Fixes';

  static const applyFixesActionText = 'Apply Fixes';

  static final learnMoreUri = Uri.parse('https://dart.dev/tools/dart-fix');

  static const doNotShowAgainActionText = "Don't Show Again";

  AnalysisServer server;

  /// Used for reading/writing preferences such as not to prompt again.
  UserPromptPreferences preferences;

  /// The last time we ran the check to see if we should prompt.
  @visibleForTesting
  DateTime? lastCheck;

  /// Whether we've already prompted the user about "dart fix" in this session.
  ///
  /// Set on the first prompt, and used to avoid prompting again.
  bool _hasPromptedThisSession = false;

  /// A map of context root paths to their version constraint strings the last
  /// time we checked for fixes.
  ///
  /// Usually checks are throttled but when constraints change (or the set of
  /// context paths) additional checks are allowed.
  Map<String, List<String?>> _lastContextSdkVersionConstraints = {};

  CancelableToken? _inProgressCheckCancellationToken;

  DartFixPromptManager(this.server, this.preferences);

  /// Gets a map of context root paths to a list of associated sdk version
  /// constraints.
  @visibleForTesting
  Map<String, List<String?>> get currentContextSdkConstraints {
    var constraintMap = <String, List<String?>>{};
    for (var context in server.contextManager.analysisContexts) {
      var workspace = context.contextRoot.workspace;
      var sdkConstraints = workspace is PackageConfigWorkspace
          ? workspace.allPackages
              .whereType<PubPackage>()
              .map((p) => p.sdkVersionConstraint?.toString())
              .toList()
          : <String>[];
      constraintMap[context.contextRoot.root.path] = sdkConstraints;
    }
    return constraintMap;
  }

  bool get hasCheckedRecently {
    var lastCheck = this.lastCheck;
    return lastCheck != null &&
        DateTime.now().difference(lastCheck) <= _sleepTime;
  }

  /// Whether to use in-editor fixes (by executing commands).
  ///
  /// This is only allowed if the client supports applyEdit and
  /// changeAnnotations.
  bool get useInEditorFixes {
    var server = this.server;
    return (server.lspClientCapabilities?.applyEdit ?? false) &&
        (server.lspClientCapabilities?.changeAnnotations ?? false) &&
        // Temporary flag.
        server is LspAnalysisServer &&
        (server.initializationOptions?.useInEditorDartFixPrompt ?? false);
  }

  /// Whether or not "dart fix" may be able to fix diagnostics in the project.
  ///
  /// This method is exposed to allow tests to override the results. It should
  /// only be called by [performCheck]. Other callers interested in the results
  /// should call [performCheck] which handles cancelling other in-progress
  /// checks.
  @visibleForTesting
  Future<bool> bulkFixesAvailable(CancellationToken token) async {
    var sessions = await server.currentSessions;
    if (token.isCancellationRequested) {
      return false;
    }

    var workspace = DartChangeWorkspace(sessions);
    var processor = BulkFixProcessor(server.instrumentationService, workspace,
        cancellationToken: token);

    return processor.hasFixes(server.contextManager.analysisContexts);
  }

  /// Performs a check for bulk fixes, cancelling any other in-progress checks.
  Future<bool> performCheck() async {
    // Signal that any in-progress check should abort.
    _inProgressCheckCancellationToken?.cancel();

    // Assign a new token for this check.
    var token = _inProgressCheckCancellationToken = CancelableToken();
    var sw = Stopwatch()..start();
    var fixesAvailable = await bulkFixesAvailable(token);
    sw.stop();
    server.instrumentationService.logInfo(
        'Checking whether to prompt about "dart fix" took ${sw.elapsed}');

    // If we were cancelled since the last cancellation check inside
    // bulkFixesAvailable, still return false because another check is now in
    // progress and our results are stale.
    return fixesAvailable && !token.isCancellationRequested;
  }

  @visibleForTesting
  Future<void> showPrompt({
    required UserPromptSender userPromptSender,
    required OpenUriNotificationSender openUriNotificationSender,
  }) async {
    _hasPromptedThisSession = true;

    var executeCommandHandler = server.executeCommandHandler;
    String prompt;
    List<String> actions;

    // Depending on capabilities, use an in-editor prompt/command buttons or a
    // simple prompt that jumps to "dart fix" on the website.
    if (useInEditorFixes && executeCommandHandler != null) {
      prompt = inEditorPromptText;
      actions = [
        previewFixesActionText,
        applyFixesActionText,
        doNotShowAgainActionText,
      ];
    } else {
      prompt = externalFixPromptText;
      actions = [
        learnMoreActionText,
        doNotShowAgainActionText,
      ];
    }

    // Note: It's possible the user never responds to this until we shut down
    //  so handle the request throwing due to server shutting down.
    var response = await userPromptSender(
      MessageType.info,
      prompt,
      actions,
    ).then((value) => value, onError: (_) => null);

    switch ((response, executeCommandHandler)) {
      case (learnMoreActionText, _):
        unawaited(openUriNotificationSender(learnMoreUri));

      case (previewFixesActionText, ExecuteCommandHandler execHandler):
      case (applyFixesActionText, ExecuteCommandHandler execHandler):
        var command = response == applyFixesActionText
            ? Commands.fixAllInWorkspace
            : Commands.previewFixAllInWorkspace;
        unawaited(_executeCommand(execHandler, userPromptSender, command));

      case (doNotShowAgainActionText, _):
        preferences.showDartFixPrompts = false;

      default:
      // User closed prompt without clicking a button, or request failed
      // due to shutdown. Do nothing.
    }
  }

  /// Triggers a check to see if "dart fix" may be able to fix diagnostics in
  /// the project.
  ///
  /// This check can be expensive should only be triggered infrequently, such as
  /// after initial analysis has completed (or the first analysis after a
  /// context rebuild).
  void triggerCheck() {
    unawaited(
      _performCheckAndPrompt().catchError((e) {
        server.instrumentationService
            .logError('Failed to perform bulk "dart fix" check: $e');
      }),
    );
  }

  /// Executes the server command [command] with no parameters and handles
  /// showing any error to the user.
  Future<void> _executeCommand(
    ExecuteCommandHandler handler,
    UserPromptSender userPromptSender,
    String command,
  ) async {
    // Go through the main handle method so that things like analytics are
    // recorded the same.
    // TODO(dantup): Should we distinguish between command executions that came
    //  from this prompt versus from the command palette?
    var result = await handler.handle(
      ExecuteCommandParams(command: command),
      MessageInfo(performance: OperationPerformanceImpl('')),
      NotCancelableToken(),
    );

    result.ifError(
      (error) {
        unawaited(userPromptSender(
          MessageType.error,
          "Failed to execute '$command': ${error.message}",
          [],
        ));
      },
    );
  }

  /// Performs a check to see if "dart fix" may be able to fix diagnostics in
  /// the project and if so, prompts the user.
  ///
  /// The check/prompt may be skipped if not supported or the check has been run
  /// recently. If an existing check is in-progress, it will be aborted.
  Future<void> _performCheckAndPrompt() async {
    var userPromptSender = server.userPromptSender;
    var openUriNotificationSender = server.openUriNotificationSender;

    if (_hasPromptedThisSession ||
        userPromptSender == null ||
        openUriNotificationSender == null ||
        !preferences.showDartFixPrompts) {
      return;
    }

    // Don't show if we've recently shown unless our roots or their SDK
    // constraints have changed.
    var newConstraints = currentContextSdkConstraints;
    if (hasCheckedRecently &&
        const MapEquality()
            .equals(newConstraints, _lastContextSdkVersionConstraints)) {
      return;
    }
    _lastContextSdkVersionConstraints = newConstraints;

    // Perform the (potentially expensive) check.
    lastCheck = DateTime.now();
    if (!(await performCheck())) {
      return;
    }

    await showPrompt(
      userPromptSender: userPromptSender,
      openUriNotificationSender: openUriNotificationSender,
    );
  }
}
