// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/channel/byte_stream_channel.dart';

/// Helper for tracking request handling statistics.
///
/// All [DateTime] are local, not UTC.
class RequestStatisticsHelper {
  final String _sdkVersion = Platform.version.split(' ').first;

  final Map<String, _RequestStatistics> _statisticsMap = {};

  /// The [StringSink] to which performance logger should copy its output.
  _ServerLogStringSink _perfLoggerStringSink;

  /// The channel to send 'server.log' notifications to.
  ByteStreamServerChannel _serverChannel;

  /// Is `true` if the client subscribed for "server.log" notification.
  bool _isNotificationSubscribed = false;

  RequestStatisticsHelper() {
    _perfLoggerStringSink = _ServerLogStringSink(this);
  }

  /// Set whether the client subscribed for "server.log" notification.
  set isNotificationSubscribed(bool value) {
    _isNotificationSubscribed = value;
  }

  /// The [StringSink] to which performance logger should copy its output.
  StringSink get perfLoggerStringSink => _perfLoggerStringSink;

  /// The channel sets itself using this method.
  set serverChannel(ByteStreamServerChannel serverChannel) {
    _serverChannel = serverChannel;
  }

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
    if (!_isNotificationSubscribed) return;
    if (_serverChannel == null) return;

    var id = response.id;
    var stat = _statisticsMap.remove(id);
    if (stat != null) {
      stat.responseTime = DateTime.now();
      _sendLogEntry(ServerLogEntryKind.RESPONSE, stat.toJson());
    }
  }

  void logNotification(Notification notification) {
    if (!_isNotificationSubscribed) return;
    if (_serverChannel == null) return;

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

    _sendLogEntry(ServerLogEntryKind.NOTIFICATION, map);
  }

  void _logRequest(Request request) {
    if (!_isNotificationSubscribed) return;
    if (_serverChannel == null) return;

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

    _sendLogEntry(ServerLogEntryKind.REQUEST, map);
  }

  void _sendLogEntry(ServerLogEntryKind kind, Object data) {
    if (!_isNotificationSubscribed) return;
    if (_serverChannel == null) return;

    _serverChannel.sendNotification(
      Notification(
        'server.log',
        <String, Object>{
          'time': DateTime.now().millisecondsSinceEpoch,
          'kind': kind.toJson(),
          'data': data,
          'sdkVersion': _sdkVersion,
        },
      ),
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
    var map = {
      'id': id,
      'method': method,
      'clientRequestTime': clientRequestTime.millisecondsSinceEpoch,
      'serverRequestTime': serverRequestTime.millisecondsSinceEpoch,
      'responseTime': responseTime.millisecondsSinceEpoch,
    };
    if (items.isNotEmpty) {
      map['items'] = items.map((item) => item.toJson()).toList();
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

  Map<String, Object> toJson() {
    if (timeValue != null) {
      return {
        'name': name,
        'timeValue': timeValue.millisecondsSinceEpoch,
      };
    }
    throw StateError('Unknown value: $name');
  }
}

class _ServerLogStringSink implements StringSink {
  final RequestStatisticsHelper helper;

  _ServerLogStringSink(this.helper);

  @override
  void write(Object obj) {
    throw UnimplementedError();
  }

  @override
  void writeAll(Iterable objects, [String separator = '']) {
    throw UnimplementedError();
  }

  @override
  void writeCharCode(int charCode) {
    throw UnimplementedError();
  }

  @override
  void writeln([Object obj = '']) {
    helper._sendLogEntry(ServerLogEntryKind.RAW, '$obj');
  }
}
