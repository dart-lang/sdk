// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test verifies that shuting down receive and send directions separately
// on a socket correctly shuts the socket down instead of leaking it.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:expect/async_helper.dart';

const messageContent = "hello, from the client!";
late RawServerSocket server;
late StreamSubscription clientSubscription;

void handleConnection(RawSocket serverSide) {
  var readClosedReceived = false;

  void serveData(RawSocketEvent event) async {
    switch (event) {
      case RawSocketEvent.read:
        final data = serverSide.read();
        Expect.equals(messageContent, utf8.decode(data!));

        // There might be a read event in flight, wait for microtasks to drain
        // and then shutdown read and write directions separately. This
        // should cause [readClosed] to be dispatched.
        Future.delayed(Duration(milliseconds: 0), () {
          serverSide.shutdown(SocketDirection.receive);
          serverSide.shutdown(SocketDirection.send);
        });
        break;

      case RawSocketEvent.readClosed:
        Expect.isFalse(readClosedReceived);
        readClosedReceived = true;
        break;

      case RawSocketEvent.closed:
        Expect.isTrue(readClosedReceived);
        await clientSubscription.cancel();
        await server.close();
        asyncEnd();
        break;
    }
  }

  serverSide.listen(serveData);
}

Future test() async {
  server = await RawServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  server.listen(handleConnection);

  final client = await RawSocket.connect(
    InternetAddress.loopbackIPv4,
    server.port,
  );
  clientSubscription = client.listen((RawSocketEvent event) {
    switch (event) {
      case RawSocketEvent.write:
        client.write(utf8.encode(messageContent));
        break;
    }
  });
}

void main() {
  asyncStart();
  test();
}
