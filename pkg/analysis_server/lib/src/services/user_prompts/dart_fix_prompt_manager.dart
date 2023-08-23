// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart'
    show
        AnalysisServer,
        MessageType,
        OpenUriNotificationSender,
        UserPromptSender;
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/user_prompts/user_prompts.dart';
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

  static const promptText =
      'Your project contains issues that can be fixed by running "dart fix" from the command line.';

  static const learnMoreActionText = 'Learn More';

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
  Map<String, String?> _lastContextSdkVersionConstraints = {};

  CancelableToken? _inProgressCheckCancellationToken;

  DartFixPromptManager(this.server, this.preferences);

  /// Gets a map of context root paths to their version constraint strings.
  @visibleForTesting
  Map<String, String?> get currentContextSdkConstraints {
    return {
      for (final context in server.contextManager.analysisContexts)
        context.contextRoot.root.path:
            context.analysisOptions.sdkVersionConstraint?.toString(),
    };
  }

  bool get hasCheckedRecently {
    final lastCheck = this.lastCheck;
    return lastCheck != null &&
        DateTime.now().difference(lastCheck) <= _sleepTime;
  }

  /// Whether or not "dart fix" may be able to fix diagnostics in the project.
  ///
  /// This method is exposed to allow tests to override the results. It should
  /// only be called by [performCheck]. Other callers interested in the results
  /// should call [performCheck] which handles cancelling other in-progress
  /// checks.
  @visibleForTesting
  Future<bool> bulkFixesAvailable(CancellationToken token) async {
    final sessions = await server.currentSessions;
    if (token.isCancellationRequested) {
      return false;
    }

    final workspace = DartChangeWorkspace(sessions);
    final processor = BulkFixProcessor(server.instrumentationService, workspace,
        cancellationToken: token);

    return processor.hasFixes(server.contextManager.analysisContexts);
  }

  /// Performs a check for bulk fixes, cancelling any other in-progress checks.
  Future<bool> performCheck() async {
    // Signal that any in-progress check should abort.
    _inProgressCheckCancellationToken?.cancel();

    // Assign a new token for this check.
    final token = _inProgressCheckCancellationToken = CancelableToken();
    final sw = Stopwatch()..start();
    final fixesAvailable = await bulkFixesAvailable(token);
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

    // Note: It's possible the user never responds to this until we shut down
    //  so handle the request throwing due to server shutting down.
    final response = await userPromptSender(
      MessageType.info,
      promptText,
      [
        learnMoreActionText,
        doNotShowAgainActionText,
      ],
    ).then((value) => value, onError: (_) => null);

    switch (response) {
      case learnMoreActionText:
        unawaited(openUriNotificationSender(learnMoreUri));
      case doNotShowAgainActionText:
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

  /// Performs a check to see if "dart fix" may be able to fix diagnostics in
  /// the project and if so, prompts the user.
  ///
  /// The check/prompt may be skipped if not supported or the check has been run
  /// recently. If an existing check is in-progress, it will be aborted.
  Future<void> _performCheckAndPrompt() async {
    final userPromptSender = server.userPromptSender;
    final openUriNotificationSender = server.openUriNotificationSender;

    if (_hasPromptedThisSession ||
        userPromptSender == null ||
        openUriNotificationSender == null ||
        !preferences.showDartFixPrompts) {
      return;
    }

    // Don't show if we've recently shown unless our roots or their SDK
    // constraints have changed.
    final newConstraints = currentContextSdkConstraints;
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
