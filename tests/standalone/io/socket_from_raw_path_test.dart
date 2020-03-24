// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:expect/expect.dart';

Future testAddress(Uint8List name, String addr,
    {InternetAddressType? type}) async {
  var address = InternetAddress.fromRawAddress(name, type: type);
  Expect.equals(address.address, addr);
  var server = await ServerSocket.bind(address, 0);
  var client = await Socket.connect(address, server.port);
  var completer = Completer();
  server.listen((socket) async {
    Expect.equals(socket.port, server.port);
    Expect.equals(client.port, socket.remotePort);
    Expect.equals(client.remotePort, socket.port);

    Expect.equals(client.remoteAddress, address);
    socket.destroy();
    client.destroy();
    await server.close();
    completer.complete();
  });
  await completer.future;
}

Future<void> testUnixAddress() async {
  Directory dir = Directory.systemTemp.createTempSync();
  var name = 'raw_path_test';
  try {
    final file = File('${dir.path}/$name');
    Uint8List path = Uint8List.fromList(utf8.encode(file.path));
    var address =
        InternetAddress.fromRawAddress(path, type: InternetAddressType.unix);
    Expect.isTrue(address.address.toString().endsWith(name));

    // Test socket
    var server = await ServerSocket.bind(address, 0);
    var client = await Socket.connect(address, server.port);
    var completer = Completer<void>();
    server.listen((socket) async {
      Expect.equals(socket.port, server.port);
      Expect.equals(client.port, socket.remotePort);
      Expect.equals(client.remotePort, socket.port);

      Expect.equals(client.remoteAddress, address);
      socket.destroy();
      client.destroy();
      await server.close();
      completer.complete();
    });
    await completer.future;
  } finally {
    dir.deleteSync(recursive: true);
  }
}

void main() async {
  // Test for internet address ipv4 ('127.0.0.1').
  Uint8List addr = Uint8List.fromList([127, 0, 0, 1]);
  await testAddress(addr, '127.0.0.1');

  // Test unix socket
  if (Platform.isMacOS || Platform.isLinux || Platform.isAndroid) {
    await testUnixAddress();
  }
}
