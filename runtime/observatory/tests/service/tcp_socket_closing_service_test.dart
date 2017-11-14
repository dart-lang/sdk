// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

/// Test that we correctly remove sockets that have been closed from the list
/// of open sockets. We explicitly leave one socket open.

Future setup() async {
  var serverSocket = await io.ServerSocket.bind('127.0.0.1', 0);
  serverSocket.listen((s) {
    s.drain();
    s.close();
  });
  var socket = await io.Socket.connect("127.0.0.1", serverSocket.port);
  socket.write("foobar");
  socket.write("foobar");

  await socket.flush();
  await socket.close();
  await socket.drain();

  var socket2 = await io.Socket.connect("127.0.0.1", serverSocket.port);
  socket2.write("foobarfoobar");
  await socket2.flush();
  await socket2.close();
  await socket2.drain();
  await serverSocket.close();

  var server = await io.RawDatagramSocket.bind('127.0.0.1', 0);
  server.listen((io.RawSocketEvent event) {
    if (event == io.RawSocketEvent.READ) {
      io.Datagram dg = server.receive();
      dg.data.forEach((x) => true);
      server.close();
    }
  });
  var client = await io.RawDatagramSocket.bind('127.0.0.1', 0);
  client.send(UTF8.encoder.convert('foobar'),
      new io.InternetAddress('127.0.0.1'), server.port);
  client.close();

  // The one socket to expect.
  await io.ServerSocket.bind('127.0.0.1', 0);
}

var tests = [
  // Initial.
  (Isolate isolate) async {
    var result =
        await isolate.invokeRpcNoUpgrade('ext.dart.io.getOpenSockets', {});
    expect(result['type'], equals('_opensockets'));
    // We expect only one socket to be open, the server socket create at the
    // end of test.
    expect(result['data'].length, equals(1));
    var server = await isolate.invokeRpcNoUpgrade(
        'ext.dart.io.getSocketByID', {'id': result['data'][0]['id']});
    expect(server['listening'], isTrue);
    expect(server['lastRead'], equals(0));
    expect(server['totalRead'], equals(0));
    expect(server['lastWrite'], equals(0));
    expect(server['totalWritten'], equals(0));
    expect(server['writeCount'], equals(0));
    expect(server['readCount'], equals(0));
  },
];

main(args) async => runIsolateTests(args, tests, testeeBefore: setup);
