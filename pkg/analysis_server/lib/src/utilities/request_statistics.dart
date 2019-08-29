// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/protocol/protocol.dart';

/// Helper for tracking request handling statistics.
///
/// All [DateTime] are local, not UTC.
class RequestStatisticsHelper {
  final Map<String, _RequestStatistics> _statisticsMap = {};

  /// The sink to write statistics to.
  /// It is set externally when we get to `AnalysisServer` instance.
  StringSink sink;

  /// Add a time marker item to the data associated with the [request].
  void addItemTimeNow(Request request, String name) {
    var id = request.id;
    var stat = _statisticsMap[id];
    if (stat != null) {
      stat.items.add(
        _RequestStatisticsItem(
          name,
          timeValue: DateTime.now(),
        ),
      );
    }
  }

  /// The new [request] was received. Record the time when the client sent it,
  /// and the time when the server received it (now).
  void addRequest(Request request) {
    _logRequest(request);

    var id = request.id;

    var clientRequestMilliseconds = request.clientRequestTime;
    if (clientRequestMilliseconds == null) {
      return;
    }
    var clientRequestTime = DateTime.fromMillisecondsSinceEpoch(
      clientRequestMilliseconds,
    );

    var serverRequestTime = DateTime.now();

    _statisticsMap[id] = _RequestStatistics(
      id,
      request.method,
      clientRequestTime,
      serverRequestTime,
    );
  }

  /// The server finished processing a request, and sends the [response].
  /// Record the time when the response is about to be sent to the client.
  void addResponse(Response response) {
    var id = response.id;
    var stat = _statisticsMap.remove(id);
    if (stat != null) {
      stat.responseTime = DateTime.now();

      if (sink != null) {
        sink.writeln(
          json.encode(
            {
              'requestStatistics': stat.toJson(),
            },
          ),
        );
      }
    }
  }

  void logNotification(Notification notification) {
    if (sink == null) return;

    var event = notification.event;

    // Don't log large and often notifications.
    if (event == 'analysis.errors' ||
        event == 'completion.availableSuggestions') {
      return;
    }

    var map = <String, Object>{
      'event': event,
    };

    if (event == 'analysis.highlights' ||
        event == 'analysis.implemented' ||
        event == 'analysis.navigation' ||
        event == 'analysis.outline' ||
        event == 'analysis.overrides') {
      map['file'] = notification.params['file'];
    }

    if (event == 'server.status') {
      var analysis = notification.params['analysis'];
      if (analysis is Map<String, Object>) {
        map['isAnalyzing'] = analysis['isAnalyzing'];
      }
    }

    sink.writeln(
      json.encode({
        'notification': map,
      }),
    );
  }

  void _logRequest(Request request) {
    if (sink == null) return;

    var method = request.method;
    var map = <String, Object>{
      'id': request.id,
      'method': method,
    };

    {
      var clientRequestTime = request.clientRequestTime;
      if (clientRequestTime != null) {
        map['clientRequestTime'] = clientRequestTime;
      }
    }

    if (method == 'analysis.updateContent') {
      var filesMap = request.params['files'];
      if (filesMap is Map<String, Object>) {
        map['files'] = filesMap.keys.toList();
      }
    } else {
      map = request.toJson();
    }

    sink.writeln(
      json.encode({
        'request': map,
      }),
    );
  }
}

class _RequestStatistics {
  final String id;
  final String method;
  final DateTime clientRequestTime;
  final DateTime serverRequestTime;
  final List<_RequestStatisticsItem> items = [];
  DateTime responseTime;

  _RequestStatistics(
    this.id,
    this.method,
    this.clientRequestTime,
    this.serverRequestTime,
  );

  Map<String, Object> toJson() {
    var baseTime = clientRequestTime.millisecondsSinceEpoch;
    var map = {
      'id': id,
      'method': method,
      'clientRequestTime': baseTime,
      'serverRequestTime': serverRequestTime.millisecondsSinceEpoch - baseTime,
      'responseTime': responseTime.millisecondsSinceEpoch - baseTime,
    };
    if (items.isNotEmpty) {
      map['items'] = items.map((item) => item.toJson(baseTime)).toList();
    }
    return map;
  }

  @override
  String toString() {
    var map = toJson();
    return json.encode(map);
  }
}

class _RequestStatisticsItem {
  final String name;
  final DateTime timeValue;

  _RequestStatisticsItem(this.name, {this.timeValue});

  Map<String, Object> toJson(int baseTimeMillis) {
    if (timeValue != null) {
      return {
        'name': name,
        'timeValue': timeValue.millisecondsSinceEpoch - baseTimeMillis,
      };
    }
    throw StateError('Unknown value: $name');
  }
}
