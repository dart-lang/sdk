// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";
import "dart:isolate";

const SERVER_ADDRESS = "127.0.0.1";
const HOST_NAME = "localhost";
const CERTIFICATE = "localhost_cert";

void testArguments() {
  Expect.throws(() =>
      RawSecureServerSocket.bind(SERVER_ADDRESS, 65536, 5, CERTIFICATE));
  Expect.throws(() =>
      RawSecureServerSocket.bind(SERVER_ADDRESS, -1, CERTIFICATE));
  Expect.throws(() =>
      RawSecureServerSocket.bind(SERVER_ADDRESS, 0, -1, CERTIFICATE));
}

void testSimpleBind() {
  ReceivePort port = new ReceivePort();
  RawSecureServerSocket.bind(SERVER_ADDRESS, 0, 5, CERTIFICATE).then((s) {
    Expect.isTrue(s.port > 0);
    s.close();
    port.close();
  });
}

void testInvalidBind() {
  int count = 0;
  ReceivePort port = new ReceivePort();
  port.receive((_, __) { count++; if (count == 3) port.close(); });

  // Bind to a unknown DNS name.
  RawSecureServerSocket.bind("ko.faar.__hest__", 0, 5, CERTIFICATE).then((_) {
    Expect.fail("Failure expected");
  }).catchError((error) {
    Expect.isTrue(error is SocketIOException);
    port.toSendPort().send(1);
  });

  // Bind to an unavaliable IP-address.
  RawSecureServerSocket.bind("8.8.8.8", 0, 5, CERTIFICATE).then((_) {
    Expect.fail("Failure expected");
  }).catchError((error) {
    Expect.isTrue(error is SocketIOException);
    port.toSendPort().send(1);
  });

  // Bind to a port already in use.
  // Either an error or a successful bind is allowed.
  // Windows platforms allow multiple binding to the same socket, with
  // unpredictable results.
  RawSecureServerSocket.bind(SERVER_ADDRESS, 0, 5, CERTIFICATE).then((s) {
    RawSecureServerSocket.bind(SERVER_ADDRESS,
                               s.port,
                               5,
                               CERTIFICATE).then((t) {
      Expect.equals('windows', Platform.operatingSystem);
      Expect.equals(s.port, t.port);
      s.close();
      t.close();
      port.toSendPort().send(1);
    })
    .catchError((error) {
      Expect.notEquals('windows', Platform.operatingSystem);
      Expect.isTrue(error is SocketIOException);
      s.close();
      port.toSendPort().send(1);
    });
  });
}

void testSimpleConnect(String certificate) {
  ReceivePort port = new ReceivePort();
  RawSecureServerSocket.bind(SERVER_ADDRESS, 0, 5, certificate).then((server) {
    var clientEndFuture = RawSecureSocket.connect(HOST_NAME, server.port);
    server.listen((serverEnd) {
      clientEndFuture.then((clientEnd) {
        clientEnd.shutdown(SocketDirection.SEND);
        serverEnd.shutdown(SocketDirection.SEND);
        server.close();
        port.close();
      });
    });
  });
}

void testSimpleConnectFail(String certificate) {
  ReceivePort port = new ReceivePort();
  RawSecureServerSocket.bind(SERVER_ADDRESS, 0, 5, certificate).then((server) {
    var clientEndFuture = RawSecureSocket.connect(HOST_NAME, server.port)
      .then((clientEnd) {
        Expect.fail("No client connection expected.");
      })
      .catchError((error) {
        Expect.isTrue(error is SocketIOException);
      });
    server.listen((serverEnd) {
      Expect.fail("No server connection expected.");
    },
    onError: (error) {
      Expect.isTrue(error is SocketIOException);
      clientEndFuture.then((_) => port.close());
    });
  });
}

void testServerListenAfterConnect() {
  ReceivePort port = new ReceivePort();
  RawSecureServerSocket.bind(SERVER_ADDRESS, 0, 5, CERTIFICATE).then((server) {
    Expect.isTrue(server.port > 0);
    var clientEndFuture = RawSecureSocket.connect(HOST_NAME, server.port);
    new Timer(const Duration(milliseconds: 500), () {
      server.listen((serverEnd) {
        clientEndFuture.then((clientEnd) {
          clientEnd.shutdown(SocketDirection.SEND);
          serverEnd.shutdown(SocketDirection.SEND);
          server.close();
          port.close();
        });
      });
    });
  });
}

void testSimpleReadWrite() {
  // This test creates a server and a client connects. The client then
  // writes and the server echos. When the server has finished its
  // echo it half-closes. When the client gets the close event is
  // closes fully.
  ReceivePort port = new ReceivePort();

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

  RawSecureServerSocket.bind(SERVER_ADDRESS, 0, 5, CERTIFICATE).then((server) {
    server.listen((client) {
      int bytesRead = 0;
      int bytesWritten = 0;
      List<int> data = new List<int>(messageSize);

      client.writeEventsEnabled = false;
      client.listen((event) {
        switch (event) {
          case RawSocketEvent.READ:
            Expect.isTrue(bytesWritten == 0);
            Expect.isTrue(client.available() > 0);
            var buffer = client.read();
            if (buffer != null) {
              data.setRange(bytesRead, bytesRead + buffer.length, buffer);
              bytesRead += buffer.length;
              for (var value in buffer) {
                Expect.isTrue(value is int);
                Expect.isTrue(value < 256 && value >= 0);
              }
            }
            if (bytesRead == data.length) {
              verifyTestData(data);
              client.writeEventsEnabled = true;
            }
            break;
          case RawSocketEvent.WRITE:
            Expect.isFalse(client.writeEventsEnabled);
            Expect.equals(bytesRead, data.length);
            for (int i = bytesWritten; i < data.length; ++i) {
              Expect.isTrue(data[i] is int);
              Expect.isTrue(data[i] < 256 && data[i] >= 0);
            }
            bytesWritten += client.write(
                data, bytesWritten, data.length - bytesWritten);
            if (bytesWritten < data.length) {
              client.writeEventsEnabled = true;
            }
            if (bytesWritten == data.length) {
              client.shutdown(SocketDirection.SEND);
            }
            break;
          case RawSocketEvent.READ_CLOSED:
            server.close();
            break;
          default: throw "Unexpected event $event";
        }
      });
    });

    RawSecureSocket.connect(HOST_NAME, server.port).then((socket) {
      int bytesRead = 0;
      int bytesWritten = 0;
      List<int> dataSent = createTestData();
      List<int> dataReceived = new List<int>(dataSent.length);
      socket.listen((event) {
        switch (event) {
          case RawSocketEvent.READ:
            Expect.isTrue(socket.available() > 0);
            var buffer = socket.read();
            if (buffer != null) {
              int endIndex = bytesRead + buffer.length;
              dataReceived.setRange(bytesRead, endIndex, buffer);
              bytesRead += buffer.length;
            }
            break;
          case RawSocketEvent.WRITE:
            Expect.isTrue(bytesRead == 0);
            Expect.isFalse(socket.writeEventsEnabled);
            bytesWritten += socket.write(
                dataSent, bytesWritten, dataSent.length - bytesWritten);
            if (bytesWritten < dataSent.length) {
              socket.writeEventsEnabled = true;
            }
            break;
          case RawSocketEvent.READ_CLOSED:
            verifyTestData(dataReceived);
            socket.close();
            port.close();
            break;
          default: throw "Unexpected event $event";
        }
      });
    });
  });
}

main() {
  Path scriptDir = new Path(new Options().script).directoryPath;
  Path certificateDatabase = scriptDir.append('pkcert');
  SecureSocket.initialize(database: certificateDatabase.toNativePath(),
                          password: 'dartdart',
                          useBuiltinRoots: false);
  testArguments();
  testSimpleBind();
  testInvalidBind();
  testSimpleConnect(CERTIFICATE);
  testSimpleConnect("CN=localhost");
  testSimpleConnectFail("not_a_nickname");
  testSimpleConnectFail("CN=notARealDistinguishedName");
  testServerListenAfterConnect();
  testSimpleReadWrite();
}
