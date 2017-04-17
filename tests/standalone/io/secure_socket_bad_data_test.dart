// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

InternetAddress HOST;
const CERTIFICATE = "localhost_cert";

// This test sends corrupt data in the middle of a secure network connection.
// This tests the error handling of RawSecureSocket.
// A RawSocket connection is upgraded to a secure connection, so that we
// have a reference to the underlying socket.  Then we send some
// unencrypted data on it, in the middle of an encrypted data transfer.

// This test creates a server and then connects a client to the server.
// After connecting, the connection is upgraded to a secure connection.
// The client writes data to the server, then writes unencrypted data
// on the underlying socket.  When the server gets the unencrypted data,
// this causes an error in the NSS code.  When the NSS code is in debug
// mode, bad data on the connection can cause an assertion failure, rather
// than an exception.

const messageSize = 1000;

List<int> createTestData() {
  List<int> data = new List<int>(messageSize);
  for (int i = 0; i < messageSize; i++) {
    data[i] = i & 0xff;
  }
  return data;
}

void verifyTestData(List<int> data) {
  Expect.equals(messageSize, data.length);
  List<int> expected = createTestData();
  for (int i = 0; i < messageSize; i++) {
    Expect.equals(expected[i], data[i]);
  }
}

Future runServer(RawSocket client) {
  final completer = new Completer();
  final dataReceived = new List<int>(messageSize);
  int bytesRead = 0;
  client.writeEventsEnabled = false;
  client.listen((event) {
    switch (event) {
      case RawSocketEvent.READ:
        Expect.isTrue(client.available() > 0);
        var buffer = client.read(200);
        dataReceived.setRange(bytesRead, bytesRead + buffer.length, buffer);
        bytesRead += buffer.length;
        if (bytesRead == dataReceived.length) {
          verifyTestData(dataReceived);
        }
        break;
      case RawSocketEvent.WRITE:
        Expect.fail('WRITE event received');
        break;
      case RawSocketEvent.READ_CLOSED:
        Expect.fail('READ_CLOSED event received');
        client.shutdown(SocketDirection.SEND);
        completer.complete(null);
        break;
    }
  }, onError: (e) {
    Expect.isTrue(e is TlsException);
    Expect.isTrue(e.toString().contains(
        'received a record with an incorrect Message Authentication Code'));
    completer.complete(null);
  });
  return completer.future;
}

Future<RawSocket> runClient(List sockets) {
  final RawSocket baseSocket = sockets[0];
  final RawSecureSocket socket = sockets[1];
  final data = createTestData();
  var completer = new Completer();
  void tryComplete() {
    if (completer != null) {
      completer.complete(null);
      completer = null;
    }
  }

  int bytesWritten = 0;
  socket.listen((event) {
    switch (event) {
      case RawSocketEvent.READ:
        Expect.fail('READ event received');
        break;
      case RawSocketEvent.WRITE:
        if (bytesWritten < data.length) {
          bytesWritten += socket.write(data, bytesWritten);
        }
        if (bytesWritten < data.length) {
          socket.writeEventsEnabled = true;
        }
        if (bytesWritten == data.length) {
          baseSocket.write(data, 0, 300);
          socket.shutdown(SocketDirection.SEND);
        }
        break;
      case RawSocketEvent.READ_CLOSED:
        tryComplete();
        break;
    }
  }, onError: (e) {
    Expect.isTrue(e is IOException);
    tryComplete();
  });
  return completer.future;
}

Future<List> connectClient(int port, bool hostnameInConnect) =>
    RawSocket.connect(HOST, port).then((socket) => (hostnameInConnect
            ? RawSecureSocket.secure(socket)
            : RawSecureSocket.secure(socket, host: HOST))
        .then((secureSocket) => [socket, secureSocket]));

Future test(bool hostnameInConnect) {
  return RawServerSocket.bind(HOST, 0).then((server) {
    server.listen((client) {
      RawSecureSocket.secureServer(client, CERTIFICATE).then((secureClient) {
        Expect.throws(() => client.add([0]));
        return runServer(secureClient);
      }, onError: (e) {
        Expect.isTrue(e is HandshakeException);
      }).whenComplete(server.close);
    });
    return connectClient(server.port, hostnameInConnect).then(runClient);
  });
}

main() {
  asyncStart();
  InternetAddress.lookup("localhost").then((hosts) {
    HOST = hosts.first;
    return Future.wait([test(false), test(true)]);
  }).then((_) => asyncEnd());
}
