// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:unified_analytics/unified_analytics.dart';

/// An interface for interacting with surveys via the unified_analytics package.
class SurveyManager {
  /// The period to wait after startup before first checking for surveys.
  ///
  /// This delay avoids showing too many prompts at startup (the IDE may prompt
  /// to fetch packages and the server may prompt for analytics or "dart fix").
  final Duration _initialDelay;

  /// The period to wait between checks for surveys.
  ///
  /// We check periodically (instead of only once) so that users who keep their
  /// IDEs open for long periods will still have survey checks periodically.
  final Duration _checkFrequency;

  /// The analytics object that provides access to surveys.
  final Analytics _analytics;

  final InstrumentationService _instrumentationService;

  /// The timer for triggering the next survey check.
  Timer? _timer;

  /// The analysis server that can show prompts to the user.
  final AnalysisServer _server;

  /// Tracks whether we've been asked to shutdown.
  ///
  /// This is used to prevent an in-progress async check from starting another
  /// timer if cancellation occurred while it was running.
  bool _isShutdown = false;

  SurveyManager(
    this._server,
    this._instrumentationService,
    this._analytics, {
    // Delay the first check slightly because there are other prompts that
    // may appear at startup (fetching packages, analytics, "dart fix") that
    // we aren't coordinated with.
    Duration initialDelay = const Duration(minutes: 5),
    Duration checkFrequency = const Duration(hours: 24),
  })  : _initialDelay = initialDelay,
        _checkFrequency = checkFrequency {
    _timer = Timer(_initialDelay, checkForSurveys);
  }

  Future<void> checkForSurveys() async {
    try {
      // Ensure we can prompt the user and open web pages.
      final prompt = _server.userPromptSender;
      final uriOpener = _server.openUriNotificationSender;
      if (prompt == null || uriOpener == null) return;

      // Find the first survey to show.
      final surveys = await _analytics.fetchAvailableSurveys();
      final survey = surveys.firstOrNull;
      if (survey == null) return;

      // If we were shutdown during the above async request, skip any further
      // processing. We don't want to mark a survey as shown if we're shutting
      // down.
      if (_isShutdown) return;

      // Create a map of buttons by text because we only get the button text
      // back and we need the button to read the URL and record the interaction.
      final buttonMap = {
        for (final button in survey.buttonList) button.buttonText: button,
      };

      _analytics.surveyShown(survey);
      final clickedButtonText = await prompt(
        MessageType.info,
        survey.description,
        buttonMap.keys.toList(),
      );
      final clickedButton = buttonMap[clickedButtonText];
      if (clickedButton == null) return;

      // Record that ths survey was interacted with so it's not shown again.
      _analytics.surveyInteracted(survey: survey, surveyButton: clickedButton);

      // If this button had a URL, open it. If not, it was probably a dismiss
      // or snooze button.
      final url = clickedButton.url;
      if (url != null) {
        await uriOpener(Uri.parse(url));
      }
    } catch (e) {
      _instrumentationService.logError('Failed to perform survey checks: $e');
    } finally {
      // Wait for the usual check period before checking again.
      if (!_isShutdown) {
        _timer = Timer(_checkFrequency, checkForSurveys);
      }
    }
  }

  void shutdown() {
    _isShutdown = true;
    _timer?.cancel();
  }
}
