// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._http;

/// Collects and manages WebSocket profiling information for DevTools.
abstract final class WebSocketProfiler {
  /// All active and completed WebSocket connections.
  static final _profile = <String, _WebSocketProfileData>{};

  static _WebSocketProfileData? startConnection(
    int connectionId,
    Uri uri, {
    String? protocol,
  }) {
    if (const bool.fromEnvironment("dart.vm.product")) {
      return null;
    }
    if (!HttpClient.enableTimelineLogging) {
      return null;
    }

    final connection = _WebSocketProfileData(
      id: connectionId.toString(),
      uri: uri,
      protocol: protocol,
    );

    _profile[connection.id] = connection;

    connection.recordEvent(
      'WebSocket.Connect',
      arguments: <String, Object?>{
        'uri': uri.toString(),
        'protocol': ?protocol,
      },
    );

    return connection;
  }

  /// Returns a profiled connection by ID.
  static _WebSocketProfileData? getConnection(String id) {
    return _profile[id];
  }

  /// Removes all stored connections.
  static void clear() {
    _profile.clear();
  }

  /// Serializes all WebSocket profile references.
  /// Serializes all WebSocket profile references.
  static List<Map<String, Object?>> serializeConnections(int? updatedSince) {
    Iterable<_WebSocketProfileData> connections = _profile.values;

    if (updatedSince != null) {
      connections = connections.where((e) => e.lastUpdateTime >= updatedSince);
    }

    return connections.map((e) => e.toJson(ref: true)).toList();
  }
}

/// Current lifecycle state of a WebSocket.
enum _WebSocketConnectionState { connecting, open, closing, closed, error }

/// Represents one event occurring during a WebSocket lifetime.
class _WebSocketProfileEvent {
  _WebSocketProfileEvent({
    required this.name,
    this.arguments,
    this.frameNumber,
    this.direction,
    this.opcode,
    this.payloadSize,
    this.errorType,
    this.errorMessage,
  });

  final int timestamp = DateTime.now().microsecondsSinceEpoch;
  final String name;
  final int? frameNumber;
  final String? direction;
  final String? opcode;
  final int? payloadSize;
  final String? errorType;
  final String? errorMessage;
  final Map<String, Object?>? arguments;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'timestamp': timestamp,
      'event': name,

      'frameNumber': ?frameNumber,
      'direction': ?direction,
      'opcode': ?opcode,
      'payloadSize': ?payloadSize,
      'errorType': ?errorType,
      'errorMessage': ?errorMessage,

      'arguments': ?arguments,
    };
  }
}

/// Stores profiling information for a single WebSocket connection.
class _WebSocketProfileData {
  /// Maximum number of events retained per WebSocket connection.
  static const int _maxEventsPerConnection = 10_000;

  _WebSocketProfileData({
    required this.id,
    required this.uri,
    required this.protocol,
  }) : connectTimestamp = DateTime.now().microsecondsSinceEpoch {
    _updated();
  }

  /// Unique identifier.
  final String id;

  /// VM isolate owning this connection.
  static final String isolateId = Service.getIsolateId(Isolate.current)!;

  /// Remote endpoint.
  final Uri uri;

  /// Negotiated protocol.
  final String? protocol;

  /// Lifecycle state.
  _WebSocketConnectionState state = .connecting;

  /// Connection timestamps.
  final int connectTimestamp;

  int? openTimestamp;
  int? closeTimestamp;

  /// Traffic statistics.
  int bytesSent = 0;
  int bytesReceived = 0;
  int framesSent = 0;
  int framesReceived = 0;
  int _nextFrameNumber = 1;
  int pingCount = 0;
  int pongCount = 0;

  /// Close information.
  int? closeCode;
  String? closeReason;

  /// Error description.
  String? error;

  /// Last update timestamp.
  int get lastUpdateTime => _lastUpdated;
  int _lastUpdated = 0;

  /// Event history.
  final List<_WebSocketProfileEvent> events = <_WebSocketProfileEvent>[];

  // Lifecycle
  void connectionOpened() {
    if (state != .connecting) {
      return;
    }

    state = .open;
    openTimestamp = DateTime.now().microsecondsSinceEpoch;

    recordEvent(
      'WebSocket.Open',
      arguments: <String, Object?>{
        'uri': uri.toString(),
        'protocol': ?protocol,
      },
    );
  }

  void finishConnection({
    required _WebSocketTrafficDirection direction,
    int? closeCode,
    String? reason,
  }) {
    if (state case .closed || .error) {
      return;
    }

    state = .closed;

    closeTimestamp = DateTime.now().microsecondsSinceEpoch;

    this.closeCode = closeCode;
    closeReason = reason;

    recordEvent(
      'WebSocket.Close',
      frameNumber: _nextFrameNumber++,
      direction: direction.value,
      opcode: _WebSocketTimelineLogger.opcodeName(_WebSocketOpcode.CLOSE),
      payloadSize: 0,
      arguments: <String, Object?>{?'closeCode': closeCode, ?'reason': reason},
    );
  }

  void finishWithError(Object error) {
    if (state case .closed || .error) {
      return;
    }

    state = .error;

    closeTimestamp = DateTime.now().microsecondsSinceEpoch;

    this.error = error.toString();

    recordEvent(
      'WebSocket.Error',
      arguments: <String, Object?>{'error': this.error},
    );
  }

  // Traffic
  void recordSend({required int payloadSize, required int opcode}) {
    if (state != .open) {
      return;
    }

    framesSent++;
    bytesSent += payloadSize;

    recordEvent(
      'WebSocket.Send',
      frameNumber: _nextFrameNumber++,
      direction: 'out',
      opcode: _WebSocketTimelineLogger.opcodeName(opcode),
      payloadSize: payloadSize,
      arguments: <String, Object?>{
        'opcode': opcode,
        'payloadSize': payloadSize,
        'framesSent': framesSent,
        'bytesSent': bytesSent,
      },
    );
  }

  void recordReceive({required int payloadSize, required int opcode}) {
    if (state != .open) {
      return;
    }

    framesReceived++;
    bytesReceived += payloadSize;

    recordEvent(
      'WebSocket.Receive',
      frameNumber: _nextFrameNumber++,
      direction: 'in',
      opcode: _WebSocketTimelineLogger.opcodeName(opcode),
      payloadSize: payloadSize,
      arguments: <String, Object?>{
        'opcode': opcode,
        'payloadSize': payloadSize,
        'framesReceived': framesReceived,
        'bytesReceived': bytesReceived,
      },
    );
  }

  void recordPing({
    int payloadSize = 0,
    required _WebSocketTrafficDirection direction,
  }) {
    if (state != .open) {
      return;
    }

    pingCount++;

    recordEvent(
      'WebSocket.Ping',
      frameNumber: _nextFrameNumber++,
      direction: direction.value,
      opcode: _WebSocketTimelineLogger.opcodeName(_WebSocketOpcode.PING),
      payloadSize: 0,
      arguments: <String, Object?>{'pingCount': pingCount},
    );
  }

  void recordPong({
    int payloadSize = 0,
    required _WebSocketTrafficDirection direction,
  }) {
    if (state != .open) {
      return;
    }

    pongCount++;

    recordEvent(
      'WebSocket.Pong',
      frameNumber: _nextFrameNumber++,
      direction: direction.value,
      opcode: _WebSocketTimelineLogger.opcodeName(_WebSocketOpcode.PONG),
      payloadSize: 0,
      arguments: <String, Object?>{'pongCount': pongCount},
    );
  }

  // Events
  void recordEvent(
    String name, {
    Map<String, Object?>? arguments,
    int? frameNumber,
    String? direction,
    String? opcode,
    int? payloadSize,
    String? errorType,
    String? errorMessage,
  }) {
    events.add(
      _WebSocketProfileEvent(
        name: name,
        arguments: arguments,
        frameNumber: frameNumber,
        direction: direction,
        opcode: opcode,
        payloadSize: payloadSize,
        errorType: errorType,
        errorMessage: errorMessage,
      ),
    );

    // Prevent unbounded memory growth for long-lived connections.
    if (events.length > _maxEventsPerConnection) {
      events.removeAt(0);
    }

    _updated();
  }

  // Serialization
  Map<String, Object?> toJson({bool ref = false}) {
    final json = <String, Object?>{
      'type': '${ref ? '@' : ''}WebSocketConnection',
      'id': id,
      'isolateId': isolateId,
      'uri': uri.toString(),
      'state': state.name,
    };

    if (ref) {
      return json;
    }

    json.addAll(<String, Object?>{
      'protocol': protocol,
      'connectTimestamp': connectTimestamp,
      'openTimestamp': openTimestamp,
      'closeTimestamp': closeTimestamp,

      'bytesSent': bytesSent,
      'bytesReceived': bytesReceived,

      'framesSent': framesSent,
      'framesReceived': framesReceived,

      'pingCount': pingCount,
      'pongCount': pongCount,

      'closeCode': closeCode,
      'closeReason': closeReason,

      'error': error,

      'events': events.map((event) => event.toJson()).toList(growable: false),
      'lastUpdated': _lastUpdated,
    });

    return json;
  }

  void _updated() {
    _lastUpdated = DateTime.now().microsecondsSinceEpoch;
  }
}
