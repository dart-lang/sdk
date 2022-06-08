// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/analytics/analytics_manager.dart';
import 'package:analysis_server/src/analytics/percentile_calculator.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:telemetry/telemetry.dart';

/// An implementation of [AnalyticsManager] that's appropriate to use when
/// analytics have been enabled.
class GoogleAnalyticsManager implements AnalyticsManager {
  /// The object used to send analytics.
  final Analytics analytics;

  /// Data about the current session, or `null` if the [startUp] method has not
  /// been invoked.
  _SessionData? _sessionData;

  final _PluginData _pluginData = _PluginData();

  /// A map from the id of a request to data about the request.
  final Map<String, _ActiveRequestData> _activeRequests = {};

  /// A map from the name of a request to data about all such requests that have
  /// been responded to.
  final Map<String, _RequestData> _completedRequests = {};

  /// A map from the name of a notification to data about all such notifications
  /// that have been handled.
  final Map<String, _NotificationData> _completedNotifications = {};

  /// Initialize a newly created analytics manager to report to the [analytics]
  /// service.
  GoogleAnalyticsManager(this.analytics);

  @override
  void changedPlugins(PluginManager pluginManager) {
    _pluginData.recordPlugins(pluginManager);
  }

  @override
  void handledNotificationMessage(
      {required NotificationMessage notification,
      required DateTime startTime,
      required DateTime endTime}) {
    var method = notification.method.toString();
    var requestTime = notification.clientRequestTime;
    var start = startTime.millisecondsSinceEpoch;
    var end = endTime.millisecondsSinceEpoch;
    var data = _completedNotifications.putIfAbsent(
        method, () => _NotificationData(method));
    if (requestTime != null) {
      data.latencyTimes.addValue(start - requestTime);
    }
    data.handlingTimes.addValue(end - start);
  }

  @override
  void sentResponse({required Response response}) {
    var sendTime = DateTime.now();
    _recordResponseData(response.id, sendTime);
  }

  @override
  void sentResponseMessage({required ResponseMessage response}) {
    var sendTime = DateTime.now();
    var id = response.id?.asString;
    if (id == null) {
      return;
    }
    _recordResponseData(id, sendTime);
  }

  @override
  void shutdown() {
    final sessionData = _sessionData;
    if (sessionData == null) {
      return;
    }
    _sendSessionData(sessionData);
    _sendServerResponseTimes();
    _sendPluginResponseTimes();
    _sendNotificationHandlingTimes();

    analytics.waitForLastPing(timeout: Duration(milliseconds: 200)).then((_) {
      analytics.close();
    });
  }

  @override
  void startedGetRefactoring(EditGetRefactoringParams params) {
    var requestData = _completedRequests.putIfAbsent(
        EDIT_REQUEST_GET_REFACTORING,
        () => _RequestData(EDIT_REQUEST_GET_REFACTORING));
    requestData.addEnumValue(
        EDIT_REQUEST_GET_REFACTORING_KIND, params.kind.name);
  }

  @override
  void startedRequest({required Request request, required DateTime startTime}) {
    var method = request.method;
    _activeRequests[request.id] =
        _ActiveRequestData(method, request.clientRequestTime, startTime);
  }

  @override
  void startedRequestMessage(
      {required RequestMessage request, required DateTime startTime}) {
    _activeRequests[request.id.asString] = _ActiveRequestData(
        request.method.toString(), request.clientRequestTime, startTime);
  }

  @override
  void startedSetAnalysisRoots(AnalysisSetAnalysisRootsParams params) {
    var requestData = _completedRequests.putIfAbsent(
        ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS,
        () => _RequestData(ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS));
    requestData.addValue(
        ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS_INCLUDED, params.included.length);
    requestData.addValue(
        ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS_EXCLUDED, params.excluded.length);
  }

  @override
  void startedSetPriorityFiles(AnalysisSetPriorityFilesParams params) {
    var requestData = _completedRequests.putIfAbsent(
        ANALYSIS_REQUEST_SET_PRIORITY_FILES,
        () => _RequestData(ANALYSIS_REQUEST_SET_PRIORITY_FILES));
    requestData.addValue(
        ANALYSIS_REQUEST_SET_PRIORITY_FILES_FILES, params.files.length);
  }

  @override
  void startUp(
      {required DateTime time,
      required List<String> arguments,
      required String clientId,
      required String? clientVersion,
      required String sdkVersion}) {
    _sessionData = _SessionData(
        startTime: time,
        commandLineArguments: arguments.join(' '),
        clientId: clientId,
        clientVersion: clientVersion ?? '',
        sdkVersion: sdkVersion);
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

    var requestData =
        _completedRequests.putIfAbsent(method, () => _RequestData(method));

    if (clientRequestTime != null) {
      var latencyTime = startTime - clientRequestTime;
      requestData.latencyTimes.addValue(latencyTime);
    }

    var responseTime = sendTime.millisecondsSinceEpoch - startTime;
    requestData.responseTimes.addValue(responseTime);
  }

  /// Send information about the notifications handled by the server.
  void _sendNotificationHandlingTimes() {
    for (var data in _completedNotifications.values) {
      analytics.sendEvent('language_server', 'notification', parameters: {
        'latency': data.latencyTimes.toAnalyticsString(),
        'method': data.method,
        'duration': data.handlingTimes.toAnalyticsString(),
      });
    }
  }

  /// Send information about the response times of plugins.
  void _sendPluginResponseTimes() {
    var responseTimes = PluginManager.pluginResponseTimes;
    for (var pluginEntry in responseTimes.entries) {
      for (var responseEntry in pluginEntry.value.entries) {
        analytics.sendEvent('language_server', 'pluginRequest', parameters: {
          'pluginId': pluginEntry.key.pluginId,
          'method': responseEntry.key,
          'duration': responseEntry.value.toAnalyticsString(),
        });
      }
    }
  }

  /// Send information about the response times of server.
  void _sendServerResponseTimes() {
    for (var data in _completedRequests.values) {
      analytics.sendEvent('language_server', 'request', parameters: {
        'latency': data.latencyTimes.toAnalyticsString(),
        'method': data.method,
        'duration': data.responseTimes.toAnalyticsString(),
        for (var field in data.additionalPercentiles.entries)
          field.key: field.value.toAnalyticsString(),
        for (var field in data.additionalEnumCounts.entries)
          field.key: json.encode(field.value),
      });
    }
  }

  /// Send information about the session.
  void _sendSessionData(_SessionData sessionData) {
    var endTime = DateTime.now().millisecondsSinceEpoch;
    var duration = endTime - sessionData.startTime.millisecondsSinceEpoch;
    analytics.sendEvent('language_server', 'session', parameters: {
      'flags': sessionData.commandLineArguments,
      'clientId': sessionData.clientId,
      'clientVersion': sessionData.clientVersion,
      'sdkVersion': sessionData.sdkVersion,
      'duration': duration.toString(),
      'plugins': _pluginData.usageCountData,
    });
  }
}

/// Data about a request that was received and is being handled.
class _ActiveRequestData {
  /// The name of the request that was received.
  final String method;

  /// The time at which the client sent the request.
  final int? clientRequestTime;

  /// The time at which the request was received.
  final DateTime startTime;

  /// Initialize a newly created data holder.
  _ActiveRequestData(this.method, this.clientRequestTime, this.startTime);
}

/// Data about the notifications that have been handled that have the same
/// method.
class _NotificationData {
  /// The name of the notifications.
  final String method;

  /// The percentile calculator for latency times. The _latency time_ is the
  /// time from when the client sent the request until the time the server
  /// started processing the request.
  final PercentileCalculator latencyTimes = PercentileCalculator();

  /// The percentile calculator for handling times. The _handling time_ is the
  /// time from when the server started processing the notification until the
  /// handling was complete.
  final PercentileCalculator handlingTimes = PercentileCalculator();

  /// Initialize a newly create data holder for notifications with the given
  /// [method].
  _NotificationData(this.method);
}

/// Data about the plugins associated with the context roots.
class _PluginData {
  /// The number of times that plugin information has been recorded.
  int recordCount = 0;

  /// A table mapping the ids of running plugins to the number of context roots
  /// associated with each of the plugins.
  Map<String, PercentileCalculator> usageCounts = {};

  /// Initialize a newly created holder of plugin data.
  _PluginData();

  String get usageCountData {
    return json.encode({
      'recordCount': recordCount,
      'rootCounts': _encodeUsageCounts(),
    });
  }

  /// Use the [pluginManager] to record data about the plugins that are
  /// currently running.
  void recordPlugins(PluginManager pluginManager) {
    recordCount++;
    var plugins = pluginManager.plugins;
    for (var i = 0; i < plugins.length; i++) {
      var info = plugins[i];
      usageCounts
          .putIfAbsent(info.pluginId, () => PercentileCalculator())
          .addValue(info.contextRoots.length);
    }
  }

  /// Return an encoding of the [usageCounts].
  Map<String, Object> _encodeUsageCounts() {
    var encoded = <String, Object>{};
    for (var entry in usageCounts.entries) {
      encoded[entry.key] = entry.value.toJson();
    }
    return encoded;
  }
}

/// Data about the requests that have been responded to that have the same
/// method.
class _RequestData {
  /// The name of the requests.
  final String method;

  /// The percentile calculator for latency times. The _latency time_ is the
  /// time from when the client sent the request until the time the server
  /// started processing the request.
  final PercentileCalculator latencyTimes = PercentileCalculator();

  /// The percentile calculator for response times. The _response time_ is the
  /// time from when the server started processing the request until the time
  /// the response was sent.
  final PercentileCalculator responseTimes = PercentileCalculator();

  /// A table mapping the names of fields in a request's parameters to the
  /// percentile calculators related to the value of the parameter (such as the
  /// length of a list).
  final Map<String, PercentileCalculator> additionalPercentiles = {};

  /// A table mapping the name of a field in a request's parameters and the name
  /// of an enum constant to the number of times that the given constant was
  /// used as the value of the field.
  final Map<String, Map<String, int>> additionalEnumCounts = {};

  /// Initialize a newly create data holder for requests with the given
  /// [method].
  _RequestData(this.method);

  /// Record the occurrence of the enum constant with the given [enumName] for
  /// the field with the given [name].
  void addEnumValue<E>(String name, String enumName) {
    var counts = additionalEnumCounts.putIfAbsent(name, () => {});
    counts[enumName] = (counts[enumName] ?? 0) + 1;
  }

  /// Record a [value] for the field with the given [name].
  void addValue(String name, int value) {
    additionalPercentiles
        .putIfAbsent(name, PercentileCalculator.new)
        .addValue(value);
  }
}

/// Data about the current session.
class _SessionData {
  /// The time at which the current session started.
  final DateTime startTime;

  /// The command-line arguments passed to the server on startup.
  final String commandLineArguments;

  /// The name of the client that started the server.
  final String clientId;

  /// The version of the client that started the server, or an empty string if
  /// no version information was provided.
  final String clientVersion;

  /// The version of the SDK from which the server was started.
  final String sdkVersion;

  /// Initialize a newly created data holder.
  _SessionData(
      {required this.startTime,
      required this.commandLineArguments,
      required this.clientId,
      required this.clientVersion,
      required this.sdkVersion});
}

extension on Either2<int, String> {
  String get asString {
    return map((value) => value.toString(), (value) => value);
  }
}
