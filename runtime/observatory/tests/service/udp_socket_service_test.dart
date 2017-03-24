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
    if (event == io.RawSocketEvent.READ) {
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
    var result =
        await isolate.invokeRpcNoUpgrade('ext.dart.io.getOpenSockets', {});
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
        'ext.dart.io.getSocketByID', {'id': result['data'][0]['id']});
    expect(server['id'], equals(result['data'][0]['id']));
    expect(server['remotePort'], equals('NA'));
    expect(server['remoteHost'], equals('NA'));
    expect(server['listening'], isFalse);
    expect(server['socketType'], equals('UDP'));
    expect(server['port'], greaterThanOrEqualTo(1024));
    // Stopwatch resolution on windows makes us sometimes report 0;
    if (io.Platform.isWindows) {
      expect(server['lastRead'], greaterThanOrEqualTo(0));
    } else {
      expect(server['lastRead'], greaterThan(0));
    }
    expect(server['totalRead'], equals(6));
    expect(server['lastWrite'], equals(0));
    expect(server['totalWritten'], equals(0));
    expect(server['writeCount'], equals(0));
    expect(server['readCount'], greaterThanOrEqualTo(1));

    var client = await isolate.invokeRpcNoUpgrade(
        'ext.dart.io.getSocketByID', {'id': result['data'][1]['id']});
    expect(client['id'], equals(result['data'][1]['id']));
    expect(client['remotePort'], equals('NA'));
    expect(client['remoteHost'], equals('NA'));
    expect(client['listening'], isFalse);
    expect(client['socketType'], equals('UDP'));
    expect(client['port'], greaterThanOrEqualTo(1024));
    expect(client['lastRead'], equals(0));
    expect(client['totalRead'], equals(0));
    // Stopwatch resolution on windows makes us sometimes report 0;
    if (io.Platform.isWindows) {
      expect(client['lastWrite'], greaterThanOrEqualTo(0));
    } else {
      expect(client['lastWrite'], greaterThan(0));
    }
    expect(client['totalWritten'], equals(6));
    expect(client['writeCount'], greaterThanOrEqualTo(1));
    expect(client['readCount'], equals(0));
  },
];

main(args) async => runIsolateTests(args, udpTests, testeeBefore: setupUDP);
