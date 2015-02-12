// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

testBindShared(String host, bool v6Only) {
  asyncStart();
  ServerSocket.bind(
      host, 0, v6Only: v6Only, shared: true).then((socket) {
    Expect.isTrue(socket.port > 0);

    asyncStart();
    return ServerSocket.bind(
        host, socket.port, v6Only: v6Only, shared: true).then((socket2) {
      Expect.equals(socket.address.address, socket2.address.address);
      Expect.equals(socket.port, socket2.port);
      socket.close().whenComplete(asyncEnd);
      socket2.close().whenComplete(asyncEnd);
    });
  });
}

negTestBindSharedMismatch(String host, bool v6Only) {
  asyncStart();
  ServerSocket.bind(host, 0, v6Only: v6Only).then((ServerSocket socket) {
    Expect.isTrue(socket.port > 0);

    asyncStart();
    return ServerSocket.bind(
        host, socket.port, v6Only: v6Only).catchError((error) {
      Expect.isTrue(error is SocketException);
      Expect.isTrue('$error'.contains('shared flag'));
      socket.close().whenComplete(asyncEnd);
      asyncEnd();
    });
  });
}

negTestBindV6OnlyMismatch(String host, bool v6Only) {
  asyncStart();
  ServerSocket.bind(
      host, 0, v6Only: v6Only, shared: true).then((ServerSocket socket) {
    Expect.isTrue(socket.port > 0);

    asyncStart();
    return ServerSocket.bind(
        host, socket.port, v6Only: !v6Only, shared: true)
        .catchError((error) {
      Expect.isTrue(error is SocketException);
      Expect.isTrue('$error'.contains('v6Only flag'));
      socket.close().whenComplete(asyncEnd);
      asyncEnd();
    });
  });
}

Future testBindDifferentAddresses(InternetAddress addr1,
                                  InternetAddress addr2,
                                  bool addr1V6Only,
                                  bool addr2V6Only) {
  asyncStart();
  return ServerSocket.bind(
      addr1, 0, v6Only: addr1V6Only, shared: false).then((socket) {
    Expect.isTrue(socket.port > 0);

    asyncStart();
    return ServerSocket.bind(
        addr2, socket.port, v6Only: addr2V6Only, shared: false).then((socket2) {
      Expect.equals(socket.port, socket2.port);

      return Future.wait([
          socket.close().whenComplete(asyncEnd),
          socket2.close().whenComplete(asyncEnd),
      ]);
    });
  });
}

testSocketReferenceInteroperability(String host) {
  asyncStart();
    ServerSocket.bind(host, 0).then((ServerSocket socket) {
      Expect.isTrue(socket.port > 0);

      asyncStart();
      socket.reference.create().then((socket2) {
        bool gotResponseFrom1;
        bool gotResponseFrom2;

        Expect.isTrue(socket.port > 0);
        Expect.equals(socket.port, socket2.port);

        asyncStart();
        asyncStart();
        asyncStart();
        socket.listen((client) {
          client.drain().whenComplete(asyncEnd);
          client.write('1: hello world');
          client.close().whenComplete(asyncEnd);
          // NOTE: Closing the socket un-subscribes as well, which means the
          // other client connection must go to the other socket.
          socket.close().whenComplete(asyncEnd);
        }, onDone: asyncEnd);

        asyncStart();
        asyncStart();
        asyncStart();
        socket2.listen((client) {
          client.drain().whenComplete(asyncEnd);
          client.write('2: hello world');
          client.close().whenComplete(asyncEnd);
          // NOTE: Closing the socket un-subscribes as well, which means the
          // other client connection must go to the other socket.
          socket2.close().whenComplete(asyncEnd);
        }, onDone: asyncEnd);

        var futures = [];
        for (int i = 0; i < 2; i++) {
          asyncStart();
          futures.add(
              Socket.connect(socket.address, socket.port).then((Socket socket) {
            socket.close().whenComplete(asyncEnd);
            asyncStart();
            return socket
                .transform(ASCII.decoder).join('').then((String result) {
                if (result == '1: hello world') gotResponseFrom1 = true;
                else if (result == '2: hello world') gotResponseFrom2 = true;
                else throw 'Unexpected result from server: $result';
                asyncEnd();
             });
          }));
        }
        asyncStart();
        Future.wait(futures).then((_) {
          Expect.isTrue(gotResponseFrom1);
          Expect.isTrue(gotResponseFrom2);
          asyncEnd();
        });
      });
   });
}

testListenCloseListenClose(String host) async {
  asyncStart();

  ServerSocket socket =
      await ServerSocket.bind(host, 0, shared: true);
  ServerSocket socket2 =
      await ServerSocket.bind(host, socket.port, shared: true);

  var subscription = socket.listen((_) { throw 'error'; });
  subscription.cancel();
  await socket.close();

  // The second socket should have kept the OS socket alive. We can therefore
  // test if it is working correctly.
  asyncStart();
  socket2.first.then((socket) async {
    await socket.drain();
    await socket.close();
    asyncEnd();
  });

  Socket client = await Socket.connect(host, socket2.port);
  await client.close();
  await client.drain();

  asyncEnd();
}

void main() {
  for (var host in ['127.0.0.1', '::1']) {
    testBindShared(host, false);
    testBindShared(host, true);

    negTestBindSharedMismatch(host, false);
    negTestBindSharedMismatch(host, true);

    negTestBindV6OnlyMismatch(host, true);
    negTestBindV6OnlyMismatch(host, false);

    testSocketReferenceInteroperability(host);

    testListenCloseListenClose(host);
  }

  asyncStart();
  testBindDifferentAddresses(InternetAddress.ANY_IP_V6,
                             InternetAddress.ANY_IP_V4,
                             true,
                             false).then((_) {
    testBindDifferentAddresses(InternetAddress.ANY_IP_V4,
                               InternetAddress.ANY_IP_V6,
                               false,
                               true);
    asyncEnd();
  });
}
