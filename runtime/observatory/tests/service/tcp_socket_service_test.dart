// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

Future setupTCP() async {
  // Note that we don't close after us, by design we leave the sockets opens
  // to allow us to query them from the other isolate.
  var serverSocket = await io.ServerSocket.bind('127.0.0.1', 0);
  serverSocket.listen((s) {
    s.transform(UTF8.decoder).listen(print);
    s.close();
  });
  var socket = await io.Socket.connect("127.0.0.1", serverSocket.port);
  socket.write("foobar");
  socket.write("foobar");
  await socket.flush();

  var socket2 = await io.Socket.connect("127.0.0.1", serverSocket.port);
  socket2.write("foobarfoobar");
  await socket2.flush();
}

var tcpTests = [
  // Initial.
  (Isolate isolate) async {
    var result =
        await isolate.invokeRpcNoUpgrade('ext.dart.io.getOpenSockets', {});
    expect(result['type'], equals('_opensockets'));
    // We expect 3 sockets to be open (in this order):
    //   The server socket accepting connections, on port X
    //   The accepted connection on the client, on port Y
    //   The client connection, on port X
    if (result['data'].length != 5) {
      print(result['data']);
    }
    expect(result['data'].length, equals(5));
    // The first socket will have a name like listening:127.0.0.1:X
    // The second will have a name like 127.0.0.1:Y
    // The third will have a name like 127.0.0.1:X
    expect(result['data'][0]['name'].startsWith('listening:127.0.0.1'), isTrue);
    expect(result['data'][1]['name'].startsWith('127.0.0.1:'), isTrue);
    expect(result['data'][2]['name'].startsWith('127.0.0.1:'), isTrue);

    var listening = await isolate.invokeRpcNoUpgrade(
        'ext.dart.io.getSocketByID', {'id': result['data'][0]['id']});
    expect(listening['id'], equals(result['data'][0]['id']));
    expect(listening['listening'], isTrue);
    expect(listening['socketType'], equals('TCP'));
    expect(listening['port'], greaterThanOrEqualTo(1024));
    expect(listening['lastRead'], greaterThan(0));

    expect(listening['totalRead'], equals(2));
    expect(listening['lastWrite'], equals(0));
    expect(listening['totalWritten'], equals(0));
    expect(listening['writeCount'], equals(0));
    expect(listening['readCount'], equals(2));
    expect(listening['remoteHost'], equals('NA'));
    expect(listening['remotePort'], equals('NA'));

    var client = await isolate.invokeRpcNoUpgrade(
        'ext.dart.io.getSocketByID', {'id': result['data'][1]['id']});
    expect(client['id'], equals(result['data'][1]['id']));

    var server = await isolate.invokeRpcNoUpgrade(
        'ext.dart.io.getSocketByID', {'id': result['data'][2]['id']});
    expect(server['id'], equals(result['data'][2]['id']));

    // We expect the client to be connected on the port and
    // host of the listening socket.
    expect(client['remotePort'], equals(listening['port']));
    expect(client['remoteHost'], equals(listening['host']));
    // We expect the third socket (accepted server) to be connected to the
    // same port and host as the listening socket (the listening one).
    expect(server['port'], equals(listening['port']));
    expect(server['host'], equals(listening['host']));

    expect(client['listening'], isFalse);
    expect(server['listening'], isFalse);

    expect(client['socketType'], equals('TCP'));
    expect(server['socketType'], equals('TCP'));

    // We are using no reserved ports.
    expect(client['port'], greaterThanOrEqualTo(1024));
    expect(server['port'], greaterThanOrEqualTo(1024));

    // The client and server "mirror" each other in reads and writes, and the
    // timestamps are in correct order.
    expect(client['lastRead'], equals(0));
    expect(server['lastRead'], greaterThan(0));
    expect(client['totalRead'], equals(0));
    expect(server['totalRead'], equals(12));
    expect(client['readCount'], equals(0));
    expect(server['readCount'], greaterThanOrEqualTo(1));

    expect(client['lastWrite'], greaterThan(0));
    expect(server['lastWrite'], equals(0));
    expect(client['totalWritten'], equals(12));
    expect(server['totalWritten'], equals(0));
    expect(client['writeCount'], greaterThanOrEqualTo(2));
    expect(server['writeCount'], equals(0));

    // Order
    // Stopwatch resolution on windows can make us have the same timestamp.
    if (io.Platform.isWindows) {
      expect(server['lastRead'], greaterThanOrEqualTo(client['lastWrite']));
    } else {
      expect(server['lastRead'], greaterThan(client['lastWrite']));
    }

    var secondClient = await isolate.invokeRpcNoUpgrade(
        'ext.dart.io.getSocketByID', {'id': result['data'][3]['id']});
    expect(secondClient['id'], equals(result['data'][3]['id']));
    var secondServer = await isolate.invokeRpcNoUpgrade(
        'ext.dart.io.getSocketByID', {'id': result['data'][4]['id']});
    expect(secondServer['id'], equals(result['data'][4]['id']));

    // We expect the client to be connected on the port and
    // host of the listening socket.
    expect(secondClient['remotePort'], equals(listening['port']));
    expect(secondClient['remoteHost'], equals(listening['host']));
    // We expect the third socket (accepted server) to be connected to the
    // same port and host as the listening socket (the listening one).
    expect(secondServer['port'], equals(listening['port']));
    expect(secondServer['host'], equals(listening['host']));

    expect(secondClient['listening'], isFalse);
    expect(secondServer['listening'], isFalse);

    expect(secondClient['socketType'], equals('TCP'));
    expect(secondServer['socketType'], equals('TCP'));

    // We are using no reserved ports.
    expect(secondClient['port'], greaterThanOrEqualTo(1024));
    expect(secondServer['port'], greaterThanOrEqualTo(1024));

    // The client and server "mirror" each other in reads and writes, and the
    // timestamps are in correct order.
    expect(secondClient['lastRead'], equals(0));
    expect(secondServer['lastRead'], greaterThan(0));
    expect(secondClient['totalRead'], equals(0));
    expect(secondServer['totalRead'], equals(12));
    expect(secondClient['readCount'], equals(0));
    expect(secondServer['readCount'], greaterThanOrEqualTo(1));

    expect(secondClient['lastWrite'], greaterThan(0));
    expect(secondServer['lastWrite'], equals(0));
    expect(secondClient['totalWritten'], equals(12));
    expect(secondServer['totalWritten'], equals(0));
    expect(secondClient['writeCount'], greaterThanOrEqualTo(1));
    expect(secondServer['writeCount'], equals(0));

    // Order
    // Stopwatch resolution on windows make us sometimes report the same value.
    if (io.Platform.isWindows) {
      expect(server['lastRead'], greaterThanOrEqualTo(client['lastWrite']));
    } else {
      expect(server['lastRead'], greaterThan(client['lastWrite']));
    }
  },
];

main(args) async => runIsolateTests(args, tcpTests, testeeBefore: setupTCP);
