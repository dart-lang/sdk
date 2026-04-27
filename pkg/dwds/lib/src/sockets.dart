// Copyright 2021 The Dart Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:sse/client/sse_client.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket/web_socket.dart';

abstract class SocketClient {
  StreamSink<dynamic> get sink;
  Stream<String> get stream;
  void close();
}

class SseSocketClient extends SocketClient {
  final SseClient _client;
  SseSocketClient(this._client);

  @override
  StreamSink<dynamic> get sink => _client.sink;

  @override
  Stream<String> get stream => _client.stream;

  @override
  void close() => _client.close();
}

class WebSocketClient extends SocketClient {
  final StreamChannelMixin<dynamic> _channel;

  WebSocketClient(this._channel);

  @override
  StreamSink<dynamic> get sink => _channel.sink;
  @override
  Stream<String> get stream => _channel.stream.map((dynamic o) => o.toString());

  @override
  void close() => _channel.sink.close();
}

typedef ReconnectCallback = FutureOr<void> Function(StreamSink);

/// A [WebSocket] wrapper that can automatically re-establish a connection
/// when a connection is lost (e.g., upon entering "sleep" mode, flaky network
/// connections, etc.).
class PersistentWebSocket with StreamChannelMixin<dynamic> {
  PersistentWebSocket._(
    this.uri,
    this._ws, {
    required this.exponentialBackoffDelayMs,
    required this.maxRetryAttempts,
    required this.debugName,
    this.onReconnect,
    this.logger,
  });

  /// Creates a [PersistentWebSocket] instance connected to [uri].
  ///
  /// [debugName] is a string included in logs written by this class to provide
  /// additional information about the purpose of this connection.
  ///
  /// [maxRetryAttempts] sets the maximum number of retry attempts that can be
  /// made before giving up.
  ///
  /// [exponentialBackoffDelayMs] is the length of the initial delay before
  /// attempting to retry the connection in milliseconds. This delay doubles
  /// after each unsuccessful retry attempt.
  ///
  /// If [logger] is provided, messages will be logged when attempting to
  /// re-establish a connection.
  ///
  /// No retries are attempted when making the initial web socket connection,
  /// so callers must be prepared to handle both `SocketException`s and
  /// [WebSocketException] thrown if the connection to [uri] fails.
  static Future<PersistentWebSocket> connect(
    Uri uri, {
    String debugName = kDefaultDebugName,
    int maxRetryAttempts = kDefaultMaxRetryAttempts,
    int exponentialBackoffDelayMs = kDefaultBackoffDelayMs,
    ReconnectCallback? onReconnect,
    Logger? logger,
  }) {
    return WebSocket.connect(uri).then((socket) {
      return PersistentWebSocket._(
        uri,
        socket,
        exponentialBackoffDelayMs: exponentialBackoffDelayMs,
        maxRetryAttempts: maxRetryAttempts,
        logger: logger,
        onReconnect: onReconnect,
        debugName: debugName,
      );
    });
  }

  final Logger? logger;

  static const kDefaultDebugName = 'Unknown';

  /// The debug name associated with this connection.
  ///
  /// Useful when trying to identify the context of a given connection. If
  /// [logger] is set, this name will be output as part of messages output
  /// while attempting to re-establish connections.
  final String debugName;

  static const kDefaultMaxRetryAttempts = 3;

  /// The number of retry attempts to make before giving up.
  final int maxRetryAttempts;

  static const kDefaultBackoffDelayMs = 100;

  /// The amount of time to wait before attempting to retry the connection.
  ///
  /// The retry delay is calculated using exponential backoff, where each
  /// successive delay before a retry attempt is twice as long as the last
  /// delay.
  final int exponentialBackoffDelayMs;

  /// Completes when the web socket connection is disposed of.
  Future<void> get done => _doneCompleter.future;
  final _doneCompleter = Completer<void>();

  /// The URI used to establish the web socket connection.
  final Uri uri;

  ReconnectCallback? onReconnect;

  WebSocket _ws;

  late final _incomingStreamController = StreamController<dynamic>()
    ..onListen = _listenWithRetry;
  final _outgoingStreamController = StreamController<dynamic>();

  /// Used to indicate that the web socket was closed after [close] was
  /// invoked.
  var _closedManually = false;

  void _writeToWebSocket(dynamic data) {
    if (data is String) {
      _ws.sendText(data);
    } else if (data is Uint8List) {
      _ws.sendBytes(data);
    } else {
      throw UnsupportedError('Unexpected data type: ${data.runtimeType}');
    }
  }

  /// Close the web socket connection.
  Future<void> close() async {
    if (_closedManually) {
      return;
    }
    _closedManually = true;
    await _incomingStreamController.close();
    await _outgoingStreamController.close();
    await _ws.close();
  }

  Future<void> _listenWithRetry() async {
    var retry = false;
    var retryCount = 0;

    _outgoingStreamController.stream.listen(_writeToWebSocket);

    Future<void> attemptRetry(String message) async {
      await Future<void>.delayed(Duration(milliseconds: 100 << retryCount));
      retryCount++;
      retry = !_closedManually;
      if (!_closedManually) {
        logger?.info('$message. Retrying ($retryCount / $maxRetryAttempts)');
      }
    }

    do {
      final wsOnDoneCompleter = Completer<void>();

      // Check if the connection has been closed during an asynchronous gap.
      if (_closedManually) {
        break;
      }
      final retried = retry;
      if (retry) {
        try {
          _ws = await WebSocket.connect(uri);
          // Reset the retry counter on a successful reconnection.
          retryCount = 0;
        } on Exception {
          await attemptRetry(
            'Failed to establish connection to $uri ($debugName).',
          );
          continue;
        }
        retry = false;
      }

      // If the last web socket connection closed unexpected, try to
      // re-establish the connection.
      late StreamSubscription<WebSocketEvent> eventsSub;
      eventsSub = _ws.events.listen((e) async {
        switch (e) {
          case TextDataReceived(:final text):
            _incomingStreamController.sink.add(text);
          case BinaryDataReceived(:final data):
            _incomingStreamController.sink.add(data);
          case CloseReceived(:final code):
            if (code == 1006) {
              await attemptRetry('Lost connection to $uri ($debugName).');
              await eventsSub.cancel();
            }
            wsOnDoneCompleter.complete();
        }
      });

      if (retried) {
        await onReconnect?.call(sink);
      }

      // Wait for the web socket's onDone handler to run before attempting to
      // retry. Waiting on _ws.done can result in a race condition.
      await wsOnDoneCompleter.future;
    } while (retry && retryCount < maxRetryAttempts);

    _doneCompleter.complete();
    if (!_incomingStreamController.isClosed) {
      await _incomingStreamController.sink.close();
    }
  }

  @override
  StreamSink<dynamic> get sink => _outgoingStreamController.sink;

  @override
  Stream<String> get stream => _incomingStreamController.stream.cast<String>();
}
