// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/analytics/active_request_data.dart';
import 'package:analysis_server/src/analytics/context_structure.dart';
import 'package:analysis_server/src/analytics/notification_data.dart';
import 'package:analysis_server/src/analytics/plugin_data.dart';
import 'package:analysis_server/src/analytics/request_data.dart';
import 'package:analysis_server/src/analytics/session_data.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/status/pages.dart';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:collection/collection.dart';
import 'package:memory_usage/memory_usage.dart';
import 'package:meta/meta.dart';
import 'package:unified_analytics/unified_analytics.dart';

/// An interface for managing and reporting analytics.
///
/// Individual methods can either send an analytics event immediately or can
/// collect and even consolidate information to be reported later. Clients are
/// required to invoke the [shutdown] method before the server shuts down in
/// order to send any cached data.
class AnalyticsManager {
  /// A flag set during development to allow experimental data to be sent to a
  /// development-time analytics account.
  static const bool sendExperimentalData = false;

  static const addedKey = 'added';

  static const removedKey = 'removed';

  static const commandEnumKey = 'command';

  static const openWorkspacePathsKey = 'openWorkspacePaths';

  static const refactoringKindEnumKey = EDIT_REQUEST_GET_REFACTORING_KIND;

  static const includedKey = ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS_INCLUDED;

  static const excludedKey = ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS_EXCLUDED;

  static const filesKey = ANALYSIS_REQUEST_SET_PRIORITY_FILES_FILES;

  /// The object used to send analytics.
  final Analytics analytics;

  /// Data about the current session, or `null` if the [startUp] method has not
  /// been invoked.
  SessionData? _sessionData;

  final PluginData _pluginData = PluginData();

  /// The data about analysis, or `null` if no analysis has been performed.
  ContextStructure? _contextStructure;

  /// A map from the id of a request to data about the request.
  final Map<String, ActiveRequestData> _activeRequests = {};

  /// A map from the name of a request to data about all such requests that have
  /// been responded to.
  final Map<String, RequestData> _completedRequests = {};

  /// A map from the name of a notification to data about all such notifications
  /// that have been handled.
  final Map<String, NotificationData> _completedNotifications = {};

  /// A map from the name of a lint to the number of options files in which the lint
  /// was enabled.
  final Map<String, int> _lintUsageCounts = {};

  /// A map from the name of a diagnostic to a map whose values are the number
  /// of times that the severity of the diagnostic was changed to the severity
  /// represented by the key.
  final Map<String, Map<String, int>> _severityAdjustments = {};

  /// A periodic timer used to send analytics data. This timer should be
  /// cancelled at shutdown.
  Timer? periodicTimer;

  /// Initialize a newly created analytics manager to report to the [analytics]
  /// service.
  AnalyticsManager(this.analytics) {
    if (analytics is! NoOpAnalytics) {
      periodicTimer = Timer.periodic(Duration(minutes: 30), (_) {
        _sendPeriodicData();
      });
    }
  }

  /// Record information about the number of files and the number of lines of
  /// code in those files, for both immediate files, transitive files, the
  /// number of unique transitive files, and the number and sizes of library
  /// cycles.
  void analysisComplete({
    required int numberOfContexts,
    required int immediateFileCount,
    required int immediateFileLineCount,
    required int transitiveFileCount,
    required int transitiveFileLineCount,
    required int transitiveFileUniqueCount,
    required int transitiveFileUniqueLineCount,
    required List<int> libraryCycleLibraryCounts,
    required List<int> libraryCycleLineCounts,
  }) {
    // This is currently keeping the first report of completed analysis, but we
    // might want to consider alternatives, such as keeping the "largest"
    // analysis or keeping all of the data and sending back percentile.
    _contextStructure ??= ContextStructure(
      numberOfContexts: numberOfContexts,
      immediateFileCount: immediateFileCount,
      immediateFileLineCount: immediateFileLineCount,
      transitiveFileCount: transitiveFileCount,
      transitiveFileLineCount: transitiveFileLineCount,
      transitiveFileUniqueCount: transitiveFileUniqueCount,
      transitiveFileUniqueLineCount: transitiveFileUniqueLineCount,
      libraryCycleLibraryCounts: libraryCycleLibraryCounts,
      libraryCycleLineCounts: libraryCycleLineCounts,
    );
  }

  /// Record that the set of plugins known to the [pluginManager] has changed.
  void changedPlugins(PluginManager pluginManager) {
    _pluginData.recordPlugins(pluginManager);
  }

  /// Record the number of [added] folders and [removed] folders.
  void changedWorkspaceFolders({
    required List<String> added,
    required List<String> removed,
  }) {
    var requestData = getRequestData(
      Method.workspace_didChangeWorkspaceFolders.toString(),
    );
    requestData.addValue(addedKey, added.length);
    requestData.addValue(removedKey, removed.length);
  }

  /// Record that the [contexts] have been created.
  void createdAnalysisContexts(List<AnalysisContext> contexts) {
    for (var context in contexts) {
      var allOptions =
          (context as DriverBasedAnalysisContext).allAnalysisOptions;
      for (var analysisOptions in allOptions) {
        for (var rule in analysisOptions.lintRules) {
          var name = rule.name;
          _lintUsageCounts[name] = (_lintUsageCounts[name] ?? 0) + 1;
        }

        for (var processor in analysisOptions.errorProcessors) {
          var severity = processor.severity?.name ?? 'ignore';
          var severityCounts = _severityAdjustments.putIfAbsent(
            processor.code,
            () => {},
          );
          severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
        }
      }
    }
  }

  /// Record that the given [command] was executed.
  void executedCommand(String command) {
    var requestData = getRequestData(
      Method.workspace_executeCommand.toString(),
    );
    requestData.addEnumValue(commandEnumKey, command);
  }

  /// Return the request data for requests that have the given [method].
  @visibleForTesting
  RequestData getRequestData(String method) {
    return _completedRequests.putIfAbsent(method, () => RequestData(method));
  }

  /// Record that the given [notification] was received and has been handled.
  void handledNotificationMessage({
    required NotificationMessage notification,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    var method = notification.method.toString();
    var requestTime = notification.clientRequestTime;
    var start = startTime.millisecondsSinceEpoch;
    var end = endTime.millisecondsSinceEpoch;
    var data = _completedNotifications.putIfAbsent(
      method,
      () => NotificationData(method),
    );
    if (requestTime != null) {
      data.latencyTimes.addValue(start - requestTime);
    }
    data.handlingTimes.addValue(end - start);
  }

  /// Record the parameters passed on initialize.
  void initialize(InitializeParams params) {
    var options = LspInitializationOptions(params.initializationOptions);
    var paramNames = <String>[
      if (options.closingLabels) 'closingLabels',
      if (options.completionBudgetMilliseconds != null)
        'completionBudgetMilliseconds',
      if (options.flutterOutline) 'flutterOutline',
      if (options.onlyAnalyzeProjectsWithOpenFiles)
        'onlyAnalyzeProjectsWithOpenFiles',
      if (options.outline) 'outline',
      if (options.suggestFromUnimportedLibraries)
        'suggestFromUnimportedLibraries',
    ];
    _sessionData?.initializeParams = paramNames.join(',');
  }

  /// Record the number of [openWorkspacePaths].
  void initialized({required List<String> openWorkspacePaths}) {
    var requestData = getRequestData(Method.initialized.toString());
    requestData.addValue(openWorkspacePathsKey, openWorkspacePaths.length);
  }

  bool needsAnslysisCompleteCall() => _contextStructure == null;

  Future<void> sendMemoryUsage(MemoryUsageEvent event) async {
    var delta = event.delta;
    var seconds = event.period?.inSeconds;

    assert((event.delta == null) == (event.period == null));

    if (delta == null || seconds == null) {
      analytics.send(Event.memoryInfo(rss: event.rss));
      return;
    }

    if (seconds == 0) seconds = 1;

    analytics.send(
      Event.memoryInfo(
        rss: event.rss,
        periodSec: seconds,
        mbPerSec: delta / seconds,
      ),
    );
  }

  /// Record that the given [response] was sent to the client.
  void sentResponse({required Response response}) {
    var sendTime = DateTime.now();
    _recordResponseData(response.id, sendTime);
  }

  /// Record that the given [response] was sent to the client.
  void sentResponseMessage({required ResponseMessage response}) {
    var sendTime = DateTime.now();
    var id = response.id?.asLspIdString;
    if (id == null) {
      return;
    }
    _recordResponseData(id, sendTime);
  }

  /// The server is shutting down. Report any accumulated analytics data.
  Future<void> shutdown() async {
    var sessionData = _sessionData;
    if (sessionData == null) {
      return;
    }
    await _sendSessionData(sessionData);
    await _sendPeriodicData();
    await _sendAnalysisData();

    periodicTimer?.cancel();
    periodicTimer = null;
    await analytics.close();
  }

  /// Record data from the given [params].
  void startedGetRefactoring(EditGetRefactoringParams params) {
    var requestData = getRequestData(EDIT_REQUEST_GET_REFACTORING);
    requestData.addEnumValue(refactoringKindEnumKey, params.kind.name);
  }

  /// Record that the server started working on the give [request] at the given
  /// [startTime].
  void startedRequest({required Request request, required DateTime startTime}) {
    var method = request.method;
    _activeRequests[request.id] = ActiveRequestData(
      method,
      request.clientRequestTime,
      startTime,
    );
  }

  /// Record that the server started working on the give [request] at the given
  /// [startTime].
  void startedRequestMessage({
    required RequestMessage request,
    required DateTime startTime,
  }) {
    _activeRequests[request.id.asLspIdString] = ActiveRequestData(
      request.method.toString(),
      request.clientRequestTime,
      startTime,
    );
  }

  /// Record data from the given [params].
  void startedSetAnalysisRoots(AnalysisSetAnalysisRootsParams params) {
    var requestData = getRequestData(ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS);
    requestData.addValue(includedKey, params.included.length);
    requestData.addValue(excludedKey, params.excluded.length);
  }

  /// Record data from the given [params].
  void startedSetPriorityFiles(AnalysisSetPriorityFilesParams params) {
    var requestData = getRequestData(ANALYSIS_REQUEST_SET_PRIORITY_FILES);
    requestData.addValue(
      ANALYSIS_REQUEST_SET_PRIORITY_FILES_FILES,
      params.files.length,
    );
  }

  /// Record that the server was started at the given [time], that it was passed
  /// the given command-line [arguments], that it was started by the client with
  /// the given [clientId] and [clientVersion].
  void startUp({
    required DateTime time,
    required List<String> arguments,
    required String clientId,
    required String? clientVersion,
  }) {
    _sessionData = SessionData(
      startTime: time,
      commandLineArguments: arguments.join(','),
      clientId: clientId,
      clientVersion: clientVersion ?? '',
    );
  }

  /// Return an HTML representation of the data that has been recorded.
  String? toHtml(StringBuffer buffer) {
    var sessionData = _sessionData;
    if (sessionData == null) {
      return null;
    }

    void h3(String title) {
      buffer.writeln('<h3>${escape(title)}</h3>');
    }

    void h4(String title) {
      buffer.writeln('<h4>${escape(title)}</h4>');
    }

    void h5(String title) {
      buffer.writeln('<h5>${escape(title)}</h5>');
    }

    void li(String item) {
      buffer.writeln('<li>${escape(item)}</li>');
    }

    List<MapEntry<String, V>> sorted<V>(
      Iterable<MapEntry<String, V>> entries,
    ) => entries.sortedBy((entry) => entry.key);

    buffer.writeln('<hr>');

    var endTime = DateTime.now().millisecondsSinceEpoch;
    var duration = endTime - sessionData.startTime.millisecondsSinceEpoch;
    h3('Session data');
    buffer.writeln('<ul>');
    li('clientId: ${sessionData.clientId}');
    li('clientVersion: ${sessionData.clientVersion}');
    li('duration: ${duration.toString()}');
    li('flags: ${sessionData.commandLineArguments}');
    li('parameters: ${sessionData.initializeParams}');
    li('plugins: ${_pluginData.usageCountData}');
    buffer.writeln('</ul>');

    if (_completedRequests.isNotEmpty) {
      h3('Server response times');
      var entries = sorted(_completedRequests.entries);
      for (var entry in entries) {
        var data = entry.value;
        h4(data.method);
        buffer.writeln('<ul>');
        li('latency: ${data.latencyTimes.toAnalyticsString()}');
        li('duration: ${data.responseTimes.toAnalyticsString()}');
        for (var field in data.additionalPercentiles.entries) {
          li('${field.key}: ${field.value.toAnalyticsString()}');
        }
        for (var field in data.additionalEnumCounts.entries) {
          li('${field.key}: ${json.encode(field.value)}');
        }
        buffer.writeln('</ul>');
      }
    }

    var responseTimes = PluginManager.pluginResponseTimes;
    if (responseTimes.isNotEmpty) {
      h3('Plugin response times');
      for (var pluginEntry in responseTimes.entries) {
        h4(pluginEntry.key.safePluginId);
        var entries = sorted(pluginEntry.value.entries);
        for (var responseEntry in entries) {
          h5(responseEntry.key);
          buffer.writeln('<ul>');
          li('duration: ${responseEntry.value.toAnalyticsString()}');
          buffer.writeln('</ul>');
        }
      }
    }

    if (_completedNotifications.isNotEmpty) {
      h3('Notification handling times');
      buffer.writeln('<ul>');
      var entries = sorted(_completedNotifications.entries);
      for (var entry in entries) {
        var data = entry.value;
        li('latency: ${data.latencyTimes.toAnalyticsString()}');
        li('method: ${data.method}');
        li('duration: ${data.handlingTimes.toAnalyticsString()}');
      }
      buffer.writeln('</ul>');
    }

    if (_lintUsageCounts.isNotEmpty) {
      h3('Lint usage counts');
      buffer.writeln('<ul>');
      li('usageCounts: ${json.encode(_lintUsageCounts)}');
      buffer.writeln('</ul>');
    }

    if (_severityAdjustments.isNotEmpty) {
      h3('Severity adjustments');
      buffer.writeln('<ul>');
      li('adjustmentCounts: ${json.encode(_severityAdjustments)}');
      buffer.writeln('</ul>');
    }

    var analysisData = _contextStructure;
    if (analysisData != null) {
      h3('Analysis data');
      buffer.writeln('<ul>');
      li('numberOfContexts: ${json.encode(analysisData.numberOfContexts)}');
      li('immediateFileCount: ${json.encode(analysisData.immediateFileCount)}');
      li(
        'immediateFileLineCount: ${json.encode(analysisData.immediateFileLineCount)}',
      );
      li(
        'transitiveFileCount: ${json.encode(analysisData.transitiveFileCount)}',
      );
      li(
        'transitiveFileLineCount: ${json.encode(analysisData.transitiveFileLineCount)}',
      );
      li(
        'transitiveFileUniqueCount: ${json.encode(analysisData.transitiveFileUniqueCount)}',
      );
      li(
        'transitiveFileUniqueLineCount: ${json.encode(analysisData.transitiveFileUniqueLineCount)}',
      );
      li(
        'libraryCycleLibraryCounts: ${analysisData.libraryCycleLibraryCounts.toAnalyticsString()}',
      );
      li(
        'libraryCycleLineCounts: ${analysisData.libraryCycleLineCounts.toAnalyticsString()}',
      );
      buffer.writeln('</ul>');
    }

    return buffer.toString();
  }

  /// Record that the request with the given [id] was responded to at the given
  /// [sendTime].
  void _recordResponseData(String id, DateTime sendTime) {
    var data = _activeRequests.remove(id);
    if (data == null) {
      return;
    }

    var method = data.method;
    var clientRequestTime = data.clientRequestTime;
    var startTime = data.startTime.millisecondsSinceEpoch;

    var requestData = getRequestData(method);

    if (clientRequestTime != null) {
      var latencyTime = startTime - clientRequestTime;
      requestData.latencyTimes.addValue(latencyTime);
    }

    var responseTime = sendTime.millisecondsSinceEpoch - startTime;
    requestData.responseTimes.addValue(responseTime);
  }

  /// Send information about the number of files and the number of lines of code
  /// in those files.
  Future<void> _sendAnalysisData() async {
    var contextStructure = _contextStructure;
    if (contextStructure != null) {
      analytics.send(
        Event.contextStructure(
          numberOfContexts: contextStructure.numberOfContexts,
          immediateFileCount: contextStructure.immediateFileCount,
          immediateFileLineCount: contextStructure.immediateFileLineCount,
          transitiveFileCount: contextStructure.transitiveFileCount,
          transitiveFileLineCount: contextStructure.transitiveFileLineCount,
          transitiveFileUniqueCount: contextStructure.transitiveFileUniqueCount,
          transitiveFileUniqueLineCount:
              contextStructure.transitiveFileUniqueLineCount,
          libraryCycleLibraryCounts:
              contextStructure.libraryCycleLibraryCounts.toAnalyticsString(),
          libraryCycleLineCounts:
              contextStructure.libraryCycleLineCounts.toAnalyticsString(),
        ),
      );
    }
  }

  /// Send information about the number of times each lint is enabled in an
  /// analysis options file.
  Future<void> _sendLintUsageCounts() async {
    if (_lintUsageCounts.isNotEmpty) {
      var entries = _lintUsageCounts.entries.toList();
      _lintUsageCounts.clear();
      for (var entry in entries) {
        analytics.send(
          Event.lintUsageCount(count: entry.value, name: entry.key),
        );
      }
    }
  }

  /// Send information about the notifications handled by the server.
  Future<void> _sendNotificationHandlingTimes() async {
    if (_completedNotifications.isNotEmpty) {
      var completedNotifications = _completedNotifications.values.toList();
      _completedNotifications.clear();
      for (var data in completedNotifications) {
        analytics.send(
          Event.clientNotification(
            latency: data.latencyTimes.toAnalyticsString(),
            method: data.method,
            duration: data.handlingTimes.toAnalyticsString(),
          ),
        );
      }
    }
  }

  /// Send the information that is sent periodically, which is everything other
  /// than the session data.
  Future<void> _sendPeriodicData() async {
    await _sendServerResponseTimes();
    await _sendPluginResponseTimes();
    await _sendNotificationHandlingTimes();
    await _sendLintUsageCounts();
    await _sendSeverityAdjustments();
  }

  /// Send information about the response times of plugins.
  Future<void> _sendPluginResponseTimes() async {
    var responseTimes = PluginManager.pluginResponseTimes;
    if (responseTimes.isNotEmpty) {
      var entries = responseTimes.entries.toList();
      responseTimes.clear();
      for (var pluginEntry in entries) {
        for (var responseEntry in pluginEntry.value.entries) {
          analytics.send(
            Event.pluginRequest(
              pluginId: pluginEntry.key.safePluginId,
              method: responseEntry.key,
              duration: responseEntry.value.toAnalyticsString(),
            ),
          );
        }
      }
    }
  }

  /// Send information about the response times of server.
  Future<void> _sendServerResponseTimes() async {
    if (_completedRequests.isNotEmpty) {
      var completedRequests = _completedRequests.values.toList();
      _completedRequests.clear();
      for (var data in completedRequests) {
        analytics.send(
          Event.clientRequest(
            latency: data.latencyTimes.toAnalyticsString(),
            method: data.method,
            duration: data.responseTimes.toAnalyticsString(),
            added: data.additionalPercentiles[addedKey]?.toAnalyticsString(),
            excluded:
                data.additionalPercentiles[excludedKey]?.toAnalyticsString(),
            files: data.additionalPercentiles[filesKey]?.toAnalyticsString(),
            included:
                data.additionalPercentiles[includedKey]?.toAnalyticsString(),
            openWorkspacePaths:
                data.additionalPercentiles[openWorkspacePathsKey]
                    ?.toAnalyticsString(),
            removed:
                data.additionalPercentiles[removedKey]?.toAnalyticsString(),
          ),
        );
        var commandMap = data.additionalEnumCounts[commandEnumKey];
        if (commandMap != null) {
          for (var entry in commandMap.entries) {
            analytics.send(
              Event.commandExecuted(count: entry.value, name: entry.key),
            );
          }
        }
        // TODO(brianwilkerson): We don't appear to have an event defined that we
        //  can use to send analytics about how often old-style refactorings are
        //  being invoked.
        // var refactoringMap = data.additionalEnumCounts[refactoringKindEnumKey];
      }
    }
  }

  /// Send information about the session.
  Future<void> _sendSessionData(SessionData sessionData) async {
    var endTime = DateTime.now().millisecondsSinceEpoch;
    var duration = endTime - sessionData.startTime.millisecondsSinceEpoch;
    analytics.send(
      Event.serverSession(
        flags: sessionData.commandLineArguments,
        parameters: sessionData.initializeParams,
        clientId: sessionData.clientId,
        clientVersion: sessionData.clientVersion,
        duration: duration,
      ),
    );
    for (var entry in _pluginData.usageCounts.entries) {
      analytics.send(
        Event.pluginUse(
          count: _pluginData.recordCount,
          enabled: entry.value.toAnalyticsString(),
          pluginId: entry.key,
        ),
      );
    }
  }

  /// Send information about the number of times that the severity of a
  /// diagnostic is changed in an analysis options file.
  Future<void> _sendSeverityAdjustments() async {
    if (_severityAdjustments.isNotEmpty) {
      var entries = _severityAdjustments.entries.toList();
      _severityAdjustments.clear();
      for (var entry in entries) {
        analytics.send(
          Event.severityAdjustment(
            adjustments: json.encode(entry.value),
            diagnostic: entry.key,
          ),
        );
      }
    }
  }
}

extension on Either2<int, String> {
  /// Returns a String ID for this LSP request ID.
  ///
  /// Prefixes with "LSP:" to avoid collisions with legacy IDs when both kinds
  /// of requests are being used (and may have independent/overlapping IDs).
  String get asLspIdString {
    var idString = map((value) => value.toString(), (value) => value);
    return 'LSP:$idString';
  }
}
