// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dds/dds.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:pedantic/pedantic.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'common/fakes.dart';

class StreamCancelDisconnectPeer extends FakePeer {
  @override
  Future<dynamic> sendRequest(String method, [args]) async {
    final completer = Completer<dynamic>();
    switch (method) {
      case 'streamCancel':
        completer.completeError(
          StateError('The client closed with pending request "streamCancel".'),
        );
        // Notify listeners that this client is closed.
        doneCompleter.complete();
        break;
      default:
        completer.complete(await super.sendRequest(method, args));
    }
    return completer.future;
  }
}

void main() {
  webSocketBuilder = (Uri _) => null;
  peerBuilder =
      (WebSocketChannel _, dynamic __) async => StreamCancelDisconnectPeer();

  test('StateError handled by _StreamManager.clientDisconnect', () async {
    final dds = await DartDevelopmentService.startDartDevelopmentService(
        Uri(scheme: 'http'));
    final ws = await WebSocketChannel.connect(dds.uri.replace(scheme: 'ws'));

    // Create a VM service client that connects to DDS.
    final client = json_rpc.Client(ws.cast<String>());
    unawaited(client.listen());

    // Listen to a non-core DDS stream so that DDS will cancel it once the
    // client disconnects.
    await client.sendRequest('streamListen', {
      'streamId': 'Service',
    });

    // Closing the client should result in DDS cleaning up stream subscriptions
    // with no more clients subscribed to them. This will result in
    // streamCancel being invoked, which StreamCancelDisconnectPeer overrides
    // to act as if the VM service has shutdown with the request in flight
    // which would result in a StateError being thrown by sendRequest. This
    // test ensures that this exception is handled and doesn't escape outside
    // of DDS.
    await client.close();
    await dds.done;
  });
}
