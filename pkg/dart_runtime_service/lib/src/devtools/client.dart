// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:meta/meta.dart';
import 'package:sse/server/sse_handler.dart';
import 'package:stream_channel/stream_channel.dart';

/// A [StreamSink] wrapper that logs events and errors.
class LoggingMiddlewareSink<S> implements StreamSink<S> {
  LoggingMiddlewareSink(this.sink);

  @override
  void add(S event) {
    print('DevTools SSE response: $event');
    sink.add(event);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    print('DevTools SSE error response: $error');
    sink.addError(error, stackTrace);
  }

  @override
  Future<void> addStream(Stream<S> stream) {
    return sink.addStream(stream);
  }

  @override
  Future<void> close() => sink.close();

  @override
  Future<void> get done => sink.done;

  final StreamSink<dynamic> sink;
}

/// A connection between a DevTools front-end app and the DevTools server.
class DevToolsClientManager {
  DevToolsClientManager({required this.requestNotificationPermissions});

  /// The timeout to wait for a ping when verifying a client is still
  /// responsive.
  static const _clientResponsivenessTimeout = Duration(milliseconds: 500);

  /// Whether to immediately request notification permissions when a client
  /// connects.
  final bool requestNotificationPermissions;
  final List<DevToolsClient> _clients = [];

  void acceptClient(SseConnection connection, {bool enableLogging = false}) {
    final client = DevToolsClient.fromSSEConnection(connection, enableLogging);
    if (requestNotificationPermissions) {
      client.enableNotifications();
    }
    _clients.add(client);
    connection.sink.done.then((_) => _clients.remove(client));
  }

  /// Finds a DevTools client that is connected to the given VM service URI, or
  /// returns a reusable client if no client is currently connected.
  Future<DevToolsClient?> findReusableClient() {
    final availableClients = _clients.where((c) => c.reusable).toList();
    return _firstResponsiveClient(availableClients);
  }

  /// Finds an existing DevTools client connected to the given VM service.
  Future<DevToolsClient?> findExistingConnectedReusableClient(
    Uri vmServiceUri,
  ) {
    final matchingClients = _clients
        .where(
          (c) => c.reusable && _areSameVmServices(c.vmServiceUri, vmServiceUri),
        )
        .toList();
    return _firstResponsiveClient(matchingClients);
  }

  Future<DevToolsClient?> _firstResponsiveClient(
    List<DevToolsClient> candidateClients,
  ) async {
    for (final client in candidateClients) {
      try {
        await client.ping().timeout(_clientResponsivenessTimeout);
        return client;
      } on TimeoutException {
        _clients.remove(client);
      }
    }
    return null;
  }

  /// Returns whether [uri1] and [uri2] point to the same VM service instance.
  ///
  /// If either URI is null (e.g., when a DevTools client is connected to
  /// DevTools but has not yet connected to a VM service), returns false since
  /// an unconnected client cannot be reused for a specific VM service.
  static bool _areSameVmServices(Uri? uri1, Uri? uri2) {
    if (uri1 == null || uri2 == null) return false;
    return uri1.host == uri2.host &&
        uri1.port == uri2.port &&
        uri1.pathSegments.isNotEmpty &&
        uri2.pathSegments.isNotEmpty &&
        uri1.pathSegments[0] == uri2.pathSegments[0];
  }

  @override
  String toString() {
    return _clients
        .map((c) {
          return '${c.hasConnection.toString().padRight(5)} '
              '${c.currentPage?.padRight(12)} ${c.vmServiceUri.toString()}';
        })
        .join('\n');
  }

  Map<String, dynamic> toJson(dynamic id) => {
    'id': id,
    'result': {'clients': _clients.map((e) => e.toJson()).toList()},
  };
}

/// Represents a DevTools client connection to the DevTools server API.
class DevToolsClient {
  @visibleForTesting
  DevToolsClient({
    required Stream<String> stream,
    required StreamSink<dynamic> sink,
    bool loggingEnabled = false,
  }) {
    var outputSink = sink;
    if (loggingEnabled) {
      stream = stream.map<String>((String e) {
        print('DevTools SSE request: $e');
        return e;
      });
      outputSink = LoggingMiddlewareSink<dynamic>(sink);
    }

    final controller = StreamController<String>();
    controller.stream.listen((data) => outputSink.add(data));

    _devToolsPeer = json_rpc.Peer(
      StreamChannel(stream, controller.sink),
      strictProtocolChecks: false,
    );
    _registerJsonRpcMethods();
    _devToolsPeer.listen();
  }

  factory DevToolsClient.fromSSEConnection(
    SseConnection sse,
    bool loggingEnabled,
  ) {
    final stream = sse.stream;
    final StreamSink<dynamic> sink = sse.sink;
    return DevToolsClient(
      stream: stream,
      sink: sink,
      loggingEnabled: loggingEnabled,
    );
  }

  void _registerJsonRpcMethods() {
    _devToolsPeer.registerMethod('connected', (json_rpc.Parameters parameters) {
      _vmServiceUri = Uri.parse(parameters['uri'].asString);
    });

    _devToolsPeer.registerMethod('disconnected', (
      json_rpc.Parameters parameters,
    ) {
      _vmServiceUri = null;
    });

    _devToolsPeer.registerMethod('currentPage', (
      json_rpc.Parameters parameters,
    ) {
      _initialized = true;
      _currentPage = parameters['id'].asString;
      _embedded = parameters['embedded'].asBool;
    });

    _devToolsPeer.registerMethod('pingResponse', (
      json_rpc.Parameters parameters,
    ) {
      _nextPingResponse.complete();
      _nextPingResponse = Completer();
    });
  }

  Completer<void> _nextPingResponse = Completer();

  void connectToVmService(Uri uri, bool notifyUser) {
    _devToolsPeer.sendNotification('connectToVm', {
      'uri': uri.toString(),
      'notify': notifyUser,
    });
  }

  void notify() => _devToolsPeer.sendNotification('notify');

  Future<void> ping() {
    _devToolsPeer.sendNotification('ping');
    return _nextPingResponse.future;
  }

  void enableNotifications() =>
      _devToolsPeer.sendNotification('enableNotifications');

  void showPage(String pageId) {
    _devToolsPeer.sendNotification('showPage', {'page': pageId});
  }

  Map<String, dynamic> toJson() => {
    'hasConnection': hasConnection,
    'currentPage': currentPage,
    'embedded': embedded,
    'vmServiceUri': vmServiceUri?.toString(),
  };

  bool get initialized => _initialized;
  bool _initialized = false;

  String? get currentPage => _currentPage;
  String? _currentPage;

  bool get embedded => _embedded;
  bool _embedded = false;

  Uri? get vmServiceUri => _vmServiceUri;
  Uri? _vmServiceUri;

  bool get reusable => initialized && !embedded;

  bool get hasConnection => _vmServiceUri != null;

  late json_rpc.Peer _devToolsPeer;
}
