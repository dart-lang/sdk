// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_client/handler/connection_handler.dart';
import 'package:analysis_server_client/handler/notification_handler.dart';
import 'package:analysis_server_client/listener/server_listener.dart';
import 'package:analysis_server_client/protocol.dart';
import 'package:analysis_server_client/server.dart';
import 'package:test/test.dart';

void main() {
  test('live', () async {
    final server = Server(listener: _debug ? TestListener() : null);
    await server.start(clientId: 'test', suppressAnalytics: true);

    var handler = TestHandler(server);
    server.listenToOutput(notificationProcessor: handler.handleEvent);
    if (!await handler.serverConnected(
        timeLimit: const Duration(seconds: 15))) {
      fail('failed to connect to server');
    }

    var json = await server.send(
        SERVER_REQUEST_GET_VERSION, ServerGetVersionParams().toJson());
    final result =
        ServerGetVersionResult.fromJson(ResponseDecoder(null), 'result', json);
    await server.stop();

    expect(result.version, isNotEmpty);
  });
}

const _debug = false;

class TestHandler with NotificationHandler, ConnectionHandler {
  @override
  final Server server;

  TestHandler(this.server);
}

class TestListener with ServerListener {
  @override
  void log(String prefix, String details) {
    print('$prefix $details');
  }
}
