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

void expectTimeBiggerThanZero(time) {
   // Stopwatch resolution on windows makes us sometimes report 0;
  if (io.Platform.isWindows) {
    expect(time, greaterThanOrEqualTo(0));
  } else {
    expect(time, greaterThan(0));
  }
}

var tcpTests = [
  // Initial.
  (Isolate isolate) async {
    var result = await isolate.invokeRpcNoUpgrade('__getOpenSockets', {});
    expect(result['type'], equals('_opensockets'));
    // We expect 3 sockets to be open (in this order):
    //   The server socket accepting connections, on port X
    //   The accepted connection on the client, on port Y
    //   The client connection, on port X
    expect(result['data'].length, equals(5));
    // The first socket will have a name like listening:127.0.0.1:X
    // The second will have a name like 127.0.0.1:Y
    // The third will have a name like 127.0.0.1:X
    expect(result['data'][0]['name'].startsWith('listening:127.0.0.1'), isTrue);
    expect(result['data'][1]['name'].startsWith('127.0.0.1:'), isTrue);
    expect(result['data'][2]['name'].startsWith('127.0.0.1:'), isTrue);

    var listening = await isolate.invokeRpcNoUpgrade(
        '__getSocketByID', { 'id' : result['data'][0]['id'] });
    expect(listening['id'], equals(result['data'][0]['id']));
    expect(listening['listening'], isTrue);
    expect(listening['socket_type'], equals('TCP'));
    expect(listening['port'], greaterThanOrEqualTo(1024));
    expectTimeBiggerThanZero(listening['last_read']);

    expect(listening['total_read'], equals(2));
    expect(listening['last_write'], equals(0));
    expect(listening['total_written'], equals(0));
    expect(listening['write_count'], equals(0));
    expect(listening['read_count'], equals(0));
    expect(listening['remote_host'], equals('NA'));
    expect(listening['remote_port'], equals('NA'));

    var client = await isolate.invokeRpcNoUpgrade(
        '__getSocketByID', { 'id' : result['data'][1]['id'] });
    expect(client['id'], equals(result['data'][1]['id']));

    var server = await isolate.invokeRpcNoUpgrade(
        '__getSocketByID', { 'id' : result['data'][2]['id'] });
    expect(server['id'], equals(result['data'][2]['id']));

    // We expect the client to be connected on the port and
    // host of the listening socket.
    expect(client['remote_port'], equals(listening['port']));
    expect(client['remote_host'], equals(listening['host']));
    // We expect the third socket (accepted server) to be connected to the
    // same port and host as the listening socket (the listening one).
    expect(server['port'], equals(listening['port']));
    expect(server['host'], equals(listening['host']));

    expect(client['listening'], isFalse);
    expect(server['listening'], isFalse);

    expect(client['socket_type'], equals('TCP'));
    expect(server['socket_type'], equals('TCP'));

    // We are using no reserved ports.
    expect(client['port'], greaterThanOrEqualTo(1024));
    expect(server['port'], greaterThanOrEqualTo(1024));

    // The client and server "mirror" each other in reads and writes, and the
    // timestamps are in correct order.
    expect(client['last_read'], equals(0));
    expectTimeBiggerThanZero(server['last_read']);
    expect(client['total_read'], equals(0));
    expect(server['total_read'], equals(12));
    expect(client['read_count'], equals(0));
    expect(server['read_count'], greaterThanOrEqualTo(1));

    expectTimeBiggerThanZero(client['last_write']);
    expect(server['last_write'], equals(0));
    expect(client['total_written'], equals(12));
    expect(server['total_written'], equals(0));
    expect(client['write_count'], greaterThanOrEqualTo(2));
    expect(server['write_count'], equals(0));

    // Order
    // Stopwatch resolution on windows can make us have the same timestamp.
    if (io.Platform.isWindows) {
      expect(server['last_read'], greaterThanOrEqualTo(client['last_write']));
    } else {
      expect(server['last_read'], greaterThan(client['last_write']));
    }

    var second_client = await isolate.invokeRpcNoUpgrade(
        '__getSocketByID', { 'id' : result['data'][3]['id'] });
    expect(second_client['id'], equals(result['data'][3]['id']));
    var second_server = await isolate.invokeRpcNoUpgrade(
        '__getSocketByID', { 'id' : result['data'][4]['id'] });
    expect(second_server['id'], equals(result['data'][4]['id']));

    // We expect the client to be connected on the port and
    // host of the listening socket.
    expect(second_client['remote_port'], equals(listening['port']));
    expect(second_client['remote_host'], equals(listening['host']));
    // We expect the third socket (accepted server) to be connected to the
    // same port and host as the listening socket (the listening one).
    expect(second_server['port'], equals(listening['port']));
    expect(second_server['host'], equals(listening['host']));

    expect(second_client['listening'], isFalse);
    expect(second_server['listening'], isFalse);

    expect(second_client['socket_type'], equals('TCP'));
    expect(second_server['socket_type'], equals('TCP'));

    // We are using no reserved ports.
    expect(second_client['port'], greaterThanOrEqualTo(1024));
    expect(second_server['port'], greaterThanOrEqualTo(1024));

    // The client and server "mirror" each other in reads and writes, and the
    // timestamps are in correct order.
    expect(second_client['last_read'], equals(0));
    expectTimeBiggerThanZero(second_server['last_read']);
    expect(second_client['total_read'], equals(0));
    expect(second_server['total_read'], equals(12));
    expect(second_client['read_count'], equals(0));
    expect(second_server['read_count'], greaterThanOrEqualTo(1));

    expectTimeBiggerThanZero(second_client['last_write']);
    expect(second_server['last_write'], equals(0));
    expect(second_client['total_written'], equals(12));
    expect(second_server['total_written'], equals(0));
    expect(second_client['write_count'], greaterThanOrEqualTo(1));
    expect(second_server['write_count'], equals(0));

    // Order
    // Stopwatch resolution on windows make us sometimes report the same value.
    if (io.Platform.isWindows) {
      expect(server['last_read'], greaterThanOrEqualTo(client['last_write']));
    } else {
      expect(server['last_read'], greaterThan(client['last_write']));
    }
  },
];

main(args) async => runIsolateTests(args, tcpTests, testeeBefore:setupTCP);
