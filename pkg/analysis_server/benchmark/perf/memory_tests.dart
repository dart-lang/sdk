// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';

import '../../test/integration/support/integration_tests.dart';

/// Base class for analysis server memory usage tests.
class AnalysisServerMemoryUsageTest
    extends AbstractAnalysisServerIntegrationTest {
  int _vmServicePort;

  Future<int> getMemoryUsage() async {
    var uri = Uri.parse('ws://127.0.0.1:$_vmServicePort/ws');
    var service = await ServiceProtocol.connect(uri);
    var vm = await service.call('getVM');

    var total = 0;

    List isolateRefs = vm['isolates'];
    for (Map isolateRef in isolateRefs) {
      var isolate =
          await service.call('getIsolate', {'isolateId': isolateRef['id']});

      Map _heaps = isolate['_heaps'];
      total += _heaps['new']['used'] + _heaps['new']['external'];
      total += _heaps['old']['used'] + _heaps['old']['external'];
    }

    service.dispose();

    return total;
  }

  /// Send the server an 'analysis.setAnalysisRoots' command directing it to
  /// analyze [sourceDirectory].
  Future setAnalysisRoot() =>
      sendAnalysisSetAnalysisRoots([sourceDirectory.path], []);

  /// The server is automatically started before every test.
  @override
  Future setUp() async {
    _vmServicePort = await _findAvailableSocketPort();

    onAnalysisErrors.listen((AnalysisErrorsParams params) {
      currentAnalysisErrors[params.file] = params.errors;
    });
    onServerError.listen((ServerErrorParams params) {
      // A server error should never happen during an integration test.
      fail('${params.message}\n${params.stackTrace}');
    });
    var serverConnected = Completer();
    onServerConnected.listen((_) {
      outOfTestExpect(serverConnected.isCompleted, isFalse);
      serverConnected.complete();
    });
    return startServer(servicesPort: _vmServicePort).then((_) {
      server.listenToOutput(dispatchNotification);
      server.exitCode.then((_) {
        skipShutdown = true;
      });
      return serverConnected.future;
    });
  }

  /// After every test, the server is stopped.
  Future shutdown() async => await shutdownIfNeeded();

  /// Enable [ServerService.STATUS] notifications so that [analysisFinished]
  /// can be used.
  Future subscribeToStatusNotifications() async {
    await sendServerSetSubscriptions([ServerService.STATUS]);
  }

  static Future<int> _findAvailableSocketPort() async {
    var socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    try {
      return socket.port;
    } finally {
      await socket.close();
    }
  }
}

class ServiceProtocol {
  final WebSocket socket;

  int _id = 0;
  final Map<String, Completer<Map>> _completers = {};

  ServiceProtocol._(this.socket) {
    socket.listen(_handleMessage);
  }

  Future<Map> call(String method, [Map args = const {}]) {
    var id = '${++_id}';
    var completer = Completer<Map>();
    _completers[id] = completer;
    var m = <String, dynamic>{
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'args': args
    };
    if (args != null) m['params'] = args;
    var message = jsonEncode(m);
    socket.add(message);
    return completer.future;
  }

  Future dispose() => socket.close();

  void _handleMessage(dynamic message) {
    if (message is! String) {
      return;
    }

    try {
      dynamic json = jsonDecode(message);
      if (json.containsKey('id')) {
        dynamic id = json['id'];
        _completers[id]?.complete(json['result']);
        _completers.remove(id);
      }
    } catch (e) {
      // ignore
    }
  }

  static Future<ServiceProtocol> connect(Uri uri) async {
    var socket = await WebSocket.connect(uri.toString());
    return ServiceProtocol._(socket);
  }
}
