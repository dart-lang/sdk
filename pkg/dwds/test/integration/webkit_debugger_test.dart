// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dwds/src/debugging/webkit_debugger.dart';
import 'package:test/test.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

const retryInterval = Duration(milliseconds: 50);

/// Longer than any test runs to detect bad resends.
const longDuration = Duration(minutes: 1);

/// Reasonable timeout for an immediate event.
const shortDuration = Duration(seconds: 10);

void main() {
  late FakeChrome chrome;
  final debuggers = <WebkitDebugger>[];

  setUp(() async {
    chrome = await FakeChrome.start();
  });

  tearDown(() async {
    for (final debugger in debuggers) {
      await debugger.close();
    }
    debuggers.clear();
    await chrome.close();
  });

  Future<WebkitDebugger> connect({
    Duration enableRetryInterval = retryInterval,
    Duration enableTimeout = const Duration(seconds: 30),
  }) async {
    final debugger = WebkitDebugger(
      WipDebugger(await WipConnection.connect(chrome.url)),
      enableRetryInterval: enableRetryInterval,
      enableTimeout: enableTimeout,
    );
    debuggers.add(debugger);
    return debugger;
  }

  /// Expects that no more `Debugger.enable` requests are sent.
  Future<void> expectNoMoreRequests() async {
    // Wait for requests that are already in flight.
    await Future<void>.delayed(retryInterval);
    final requests = chrome.enableRequests;
    await Future<void>.delayed(retryInterval * 3);
    expect(chrome.enableRequests, requests);
  }

  group('enable', () {
    test('completes when Chrome responds', () async {
      final debugger = await connect(
        enableRetryInterval: const Duration(seconds: 30),
      );
      await debugger.enable();
      expect(chrome.enableRequests, 1);
    });

    test('waits for a slow response to the first request', () async {
      // Only respond to the first request after it has been resent.
      chrome.onEnable = (request) {
        if (request.count == 1) Timer(retryInterval * 5, request.respond);
      };
      final debugger = await connect();
      await debugger.enable();
      expect(chrome.enableRequests, greaterThan(1));
    });

    test('resends requests that are not answered', () async {
      chrome.onEnable = (request) {
        if (request.count > 1) request.respond();
      };
      final debugger = await connect();
      await debugger.enable();
      expect(chrome.enableRequests, greaterThan(1));
    });

    test('resends requests after reconnecting', () async {
      // Requests sent on a closed connection never complete, so it must be
      // resent on a new connection. Use a long retry interval so a reconnect
      // happens before resending the request.
      chrome.onEnable = (request) {
        if (request.count == 1) {
          unawaited(request.closeConnection());
        } else {
          request.respond();
        }
      };
      final debugger = await connect(
        enableRetryInterval: const Duration(milliseconds: 500),
      );
      await debugger.enable();
      expect(chrome.connections, 2);
      expect(chrome.enableRequests, 2);
    });

    test('throws errors from Chrome', () async {
      chrome.onEnable = (request) => request.respond(error: 'Failed');
      final debugger = await connect();
      await expectLater(debugger.enable(), throwsA(isA<WipError>()));
      await expectNoMoreRequests();
    });

    test('throws a TimeoutException if Chrome never responds', () async {
      chrome.onEnable = (_) {};
      final debugger = await connect(enableTimeout: retryInterval * 4);
      await expectLater(debugger.enable(), throwsA(isA<TimeoutException>()));
      expect(chrome.enableRequests, greaterThan(1));
      await expectNoMoreRequests();
    });

    test('throws if the debugger is closed', () async {
      final debugger = await connect();
      await debugger.close();
      await expectLater(debugger.enable(), throwsA(isA<WebSocketException>()));
      expect(chrome.enableRequests, 0);
    });

    test('throws when the debugger is closed while waiting', () async {
      final requested = Completer<void>();
      chrome.onEnable = (_) => requested.complete();
      final debugger = await connect(enableRetryInterval: longDuration);
      final enabled = expectLater(
        debugger.enable().timeout(shortDuration),
        throwsA(isA<WebSocketException>()),
      );
      await requested.future;
      await debugger.close();
      await enabled;
    });

    test('throws when the connection is lost', () async {
      final requested = Completer<void>();
      chrome.onEnable = (_) => requested.complete();
      final debugger = await connect(enableRetryInterval: longDuration);
      final enabled = expectLater(
        debugger.enable().timeout(shortDuration),
        throwsA(isA<WebSocketException>()),
      );
      await requested.future;
      // Like closing the tab: the connection is closed, and can't be
      // reestablished.
      await chrome.close();
      await enabled;
    });
  });

  group('close', () {
    test('stops reconnecting', () async {
      final reconnecting = Completer<void>();
      final acceptReconnect = Completer<void>();
      chrome
        ..onReconnect = () {
          reconnecting.complete();
          return acceptReconnect.future;
        }
        ..onEnable = (request) => unawaited(request.closeConnection());
      final debugger = await connect(enableRetryInterval: longDuration);
      final enabled = expectLater(
        debugger.enable().timeout(shortDuration),
        throwsA(isA<WebSocketException>()),
      );
      final closed = debugger.onClose.first;
      await reconnecting.future;
      await debugger.close();
      await enabled;
      // The new connection is closed instead of being used.
      acceptReconnect.complete();
      await closed.timeout(shortDuration);
      await chrome.connectionsClosed.timeout(shortDuration);
      expect(chrome.connections, 2);
    });
  });
}

/// A fake Chrome DevTools Protocol endpoint.
///
/// Handles `Debugger.enable` requests with [onEnable], and responds to all
/// other commands immediately.
class FakeChrome {
  final HttpServer _server;
  final _sockets = <WebSocket>[];
  final _socketsDone = <Future<void>>[];
  var _connectionAttempts = 0;
  Future<void>? _closed;

  /// Handles a `Debugger.enable` request.
  ///
  /// Responds immediately by default.
  void Function(EnableRequest request) onEnable = (request) =>
      request.respond();

  /// Called for each connection attempt after the first one, which is
  /// accepted once the returned future completes.
  Future<void> Function()? onReconnect;

  /// The number of `Debugger.enable` requests received.
  int enableRequests = 0;

  FakeChrome._(this._server) {
    _server.listen((request) async {
      if (_connectionAttempts++ > 0) await onReconnect?.call();
      final socket = await WebSocketTransformer.upgrade(request);
      final done = Completer<void>();
      _sockets.add(socket);
      _socketsDone.add(done.future);
      socket.listen((data) {
        final command = jsonDecode(data as String) as Map<String, Object?>;
        final id = command['id'] as int;
        if (command['method'] == 'Debugger.enable') {
          onEnable(EnableRequest._(++enableRequests, socket, id));
        } else {
          socket.add(jsonEncode({'id': id, 'result': <String, Object?>{}}));
        }
      }, onDone: done.complete);
    });
  }

  static Future<FakeChrome> start() async =>
      FakeChrome._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  String get url => 'ws://${_server.address.address}:${_server.port}';

  /// The number of connections made to this endpoint.
  int get connections => _sockets.length;

  /// Completes when all connections made so far are closed.
  Future<void> get connectionsClosed => Future.wait(_socketsDone);

  /// Closes all connections, and stops accepting new ones.
  Future<void> close() => _closed ??= () async {
    await Future.wait([for (final socket in _sockets) socket.close()]);
    await _server.close(force: true);
  }();
}

/// A `Debugger.enable` request received by [FakeChrome].
class EnableRequest {
  /// The number of `Debugger.enable` requests received so far, including this
  /// one.
  final int count;

  final WebSocket _socket;
  final int _id;

  EnableRequest._(this.count, this._socket, this._id);

  /// Responds to this request, with an error response if [error] is given.
  void respond({String? error}) {
    _socket.add(
      jsonEncode({
        'id': _id,
        if (error == null)
          'result': {'debuggerId': 'fake-debugger-id'}
        else
          'error': {'code': -32000, 'message': error},
      }),
    );
  }

  /// Closes the connection this request was received on.
  Future<void> closeConnection() => _socket.close();
}
