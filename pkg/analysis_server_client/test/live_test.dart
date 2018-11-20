// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_client/listener/server_listener.dart';
import 'package:analysis_server_client/handler/notification_handler.dart';
import 'package:analysis_server_client/handler/connection_handler.dart';
import 'package:analysis_server_client/protocol.dart';
import 'package:analysis_server_client/server.dart';
import 'package:test/test.dart';

const _debug = false;

void main() {
  test('live', () async {
    final server = new Server(listener: _debug ? new TestListener() : null);
    await server.start(clientId: 'test', suppressAnalytics: true);

    TestHandler handler = new TestHandler(server);
    server.listenToOutput(notificationProcessor: handler.handleEvent);
    if (!await handler.serverConnected(
        timeLimit: const Duration(seconds: 15))) {
      fail('failed to connect to server');
    }

    Map<String, dynamic> json = await server.send(
        SERVER_REQUEST_GET_VERSION, new ServerGetVersionParams().toJson());
    final result = ServerGetVersionResult.fromJson(
        new ResponseDecoder(null), 'result', json);
    await server.stop();

    expect(result.version, isNotEmpty);
  });
}

class TestHandler with NotificationHandler, ConnectionHandler {
  final Server server;

  TestHandler(this.server);
}

class TestListener with ServerListener {
  @override
  void log(String prefix, String details) {
    print('$prefix $details');
  }
}
