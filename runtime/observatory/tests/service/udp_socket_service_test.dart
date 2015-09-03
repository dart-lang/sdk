// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

Future setupUDP() async {
  var server = await io.RawDatagramSocket.bind('127.0.0.1', 0);
  server.listen((io.RawSocketEvent event) {
    if(event == io.RawSocketEvent.READ) {
      io.Datagram dg = server.receive();
      dg.data.forEach((x) => true);
    }
  });
  var client = await io.RawDatagramSocket.bind('127.0.0.1', 0);
  client.send(UTF8.encoder.convert('foobar'),
              new io.InternetAddress('127.0.0.1'), server.port);
}

var udpTests = [
  // Initial.
  (Isolate isolate) async {
    var result = await isolate.invokeRpcNoUpgrade('__getOpenSockets', {});
    expect(result['type'], equals('_opensockets'));
    // We expect 2 sockets to be open (in this order):
    //   The server socket accepting connections, on port X
    //   The client socket on port Y
    expect(result['data'].length, equals(2));
    // The first socket will have a name like listening:127.0.0.1:X
    // The second will have a name like 127.0.0.1:Y
    // The third will have a name like 127.0.0.1:X
    expect(result['data'][0]['name'].startsWith('127.0.0.1'), isTrue);
    expect(result['data'][1]['name'].startsWith('127.0.0.1:'), isTrue);

    var server = await isolate.invokeRpcNoUpgrade(
        '__getSocketByID', { 'id' : result['data'][0]['id'] });
    expect(server['id'], equals(result['data'][0]['id']));
    expect(server['remote_port'], equals('NA'));
    expect(server['remote_host'], equals('NA'));
    expect(server['listening'], isFalse);
    expect(server['socket_type'], equals('UDP'));
    expect(server['port'], greaterThanOrEqualTo(1024));
    // Stopwatch resolution on windows makes us sometimes report 0;
    if (io.Platform.isWindows) {
      expect(server['last_read'], greaterThanOrEqualTo(0));
    } else {
      expect(server['last_read'], greaterThan(0));
    }
    expect(server['total_read'], equals(6));
    expect(server['last_write'], equals(0));
    expect(server['total_written'], equals(0));
    expect(server['write_count'], equals(0));
    expect(server['read_count'], greaterThanOrEqualTo(1));

    var client = await isolate.invokeRpcNoUpgrade(
        '__getSocketByID', { 'id' : result['data'][1]['id'] });
    expect(client['id'], equals(result['data'][1]['id']));
    expect(client['remote_port'], equals('NA'));
    expect(client['remote_host'], equals('NA'));
    expect(client['listening'], isFalse);
    expect(client['socket_type'], equals('UDP'));
    expect(client['port'], greaterThanOrEqualTo(1024));
    expect(client['last_read'], equals(0));
    expect(client['total_read'], equals(0));
    // Stopwatch resolution on windows makes us sometimes report 0;
    if (io.Platform.isWindows) {
      expect(client['last_write'], greaterThanOrEqualTo(0));
    } else {
      expect(client['last_write'], greaterThan(0));
    }
    expect(client['total_written'], equals(6));
    expect(client['write_count'], greaterThanOrEqualTo(1));
    expect(client['read_count'], equals(0));
  },
];

main(args) async => runIsolateTests(args, udpTests, testeeBefore:setupUDP);
