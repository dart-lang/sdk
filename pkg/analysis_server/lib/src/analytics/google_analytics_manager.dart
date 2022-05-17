// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/src/analytics/analytics_manager.dart';
import 'package:analysis_server/src/analytics/percentile_calculator.dart';
import 'package:telemetry/telemetry.dart';

/// An implementation of [AnalyticsManager] that's appropriate to use when
/// analytics have been enabled.
class GoogleAnalyticsManager implements AnalyticsManager {
  /// The object used to send analytics.
  final Analytics analytics;

  /// Data about the current session, or `null` if the [startUp] method has not
  /// been invoked.
  _SessionData? sessionData;

  /// A map from the id of a request to data about the request.
  Map<String, _ActiveRequestData> activeRequests = {};

  /// A map from the name of a request to data about all such requests that have
  /// been responded to.
  Map<String, _RequestData> completedRequests = {};

  /// Initialize a newly created analytics manager to report to the [analytics]
  /// service.
  GoogleAnalyticsManager(this.analytics);

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
    final sessionData = this.sessionData;
    if (sessionData == null) {
      return;
    }
    // Send session data.
    var endTime = DateTime.now().millisecondsSinceEpoch;
    var duration = endTime - sessionData.startTime;
    analytics.sendEvent('language_server', 'session', parameters: {
      'flags': sessionData.commandLineArguments,
      'clientId': sessionData.clientId,
      'sdkVersion': sessionData.sdkVersion,
      'duration': duration.toString(),
      // TODO(brianwilkerson) Report a list of the names of the plugins that
      //  were loaded, or possibly a map from plugin names to the number of
      //  analysis roots in which the plugins were loaded.
      'plugins': '',
    });
    // Send response data.
    for (var data in completedRequests.values) {
      analytics.sendEvent('language_server', 'request', parameters: {
        'latency': data.latencyTimes.toAnalyticsString(),
        'name': data.requestName,
        'duration': data.responseTimes.toAnalyticsString(),
        // TODO(brianwilkerson) Report the latencies for each of the plugins,
        //  probably as a map from plugin name to latency information.
        'plugins': '',
      });
    }
    analytics.waitForLastPing(timeout: Duration(milliseconds: 200)).then((_) {
      analytics.close();
    });
  }

  @override
  void startedRequest({required Request request, required DateTime startTime}) {
    activeRequests[request.id] = _ActiveRequestData(request.method,
        request.clientRequestTime, startTime.millisecondsSinceEpoch);
  }

  @override
  void startedRequestMessage(
      {required RequestMessage request, required DateTime startTime}) {
    activeRequests[request.id.asString] = _ActiveRequestData(
        request.method.toString(),
        request.clientRequestTime,
        startTime.millisecondsSinceEpoch);
  }

  @override
  void startUp(
      {required DateTime time,
      required List<String> arguments,
      required String clientId,
      required String? clientVersion,
      required String sdkVersion}) {
    sessionData = _SessionData(
        startTime: time.millisecondsSinceEpoch,
        commandLineArguments: arguments.join(' '),
        clientId: clientId,
        clientVersion: clientVersion ?? '',
        sdkVersion: sdkVersion);
  }

  /// Record that the request with the given [id] was responded to at the given
  /// [sendTime].
  void _recordResponseData(String id, DateTime sendTime) {
    var data = activeRequests.remove(id);
    if (data == null) {
      return;
    }

    var requestName = data.requestName;
    var clientRequestTime = data.clientRequestTime;
    var startTime = data.startTime;

    var requestData = completedRequests.putIfAbsent(
        requestName, () => _RequestData(requestName));

    if (clientRequestTime >= 0) {
      var latencyTime = startTime - clientRequestTime;
      requestData.latencyTimes.addValue(latencyTime);
    }

    var responseTime = sendTime.millisecondsSinceEpoch - startTime;
    requestData.responseTimes.addValue(responseTime);
  }
}

/// Data about a request that was received and is being handled.
class _ActiveRequestData {
  /// The name of the request that was received.
  final String requestName;

  /// The time at which the client sent the request.
  final int clientRequestTime;

  /// The time at which the request was received.
  final int startTime;

  /// Initialize a newly created data holder.
  _ActiveRequestData(this.requestName, int? clientRequestTime, this.startTime)
      : clientRequestTime = clientRequestTime ?? -1;
}

/// Data about the requests that have been responded to that have the same name.
class _RequestData {
  /// The name of the requests.
  final String requestName;

  /// The percentile calculator for latency times. The _latency time_ is the
  /// time from when the client sent the request until the time the server
  /// started processing the request.
  PercentileCalculator latencyTimes = PercentileCalculator();

  /// The percentile calculator for response times. The _response time_ is the
  /// time from when the server started processing the request until the time
  /// the response was sent.
  PercentileCalculator responseTimes = PercentileCalculator();

  /// Initialize a newly create data holder for requests with the given
  /// [requestName].
  _RequestData(this.requestName);
}

/// Data about the current session.
class _SessionData {
  /// The time at which the current session started.
  int startTime;

  /// The command-line arguments passed to the server on startup.
  String commandLineArguments;

  /// The name of the client that started the server.
  String clientId;

  /// The version of the client that started the server, or an empty string if
  /// no version information was provided.
  String clientVersion;

  /// The version of the SDK from which the server was started.
  String sdkVersion;

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
