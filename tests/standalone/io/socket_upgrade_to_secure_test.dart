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

const HOST_NAME = "localhost";
const CERTIFICATE = "localhost_cert";

// This test creates a server and a client connects. After connecting
// and an optional initial handshake the connection is secured by
// upgrading to a secure connection The client then writes and the
// server echos. When the server has finished its echo it
// half-closes. When the client gets the close event is closes fully.
//
// The test can be run in different configurations based on
// the boolean arguments:
//
// handshakeBeforeSecure
// When this argument is true some initial clear text handshake is done
// between client and server before the connection is secured. This argument
// only makes sense when both listenSecure and connectSecure are false.
//
// postponeSecure
// When this argument is false the securing of the server end will
// happen as soon as the last byte of the handshake before securing
// has been written. When this argument is true the securing of the
// server will not happen until the first TLS handshake data has been
// received from the client. This argument only takes effect when
// handshakeBeforeSecure is true.
void test(bool hostnameInConnect,
          bool handshakeBeforeSecure,
          [bool postponeSecure = false]) {
  ReceivePort port = new ReceivePort();

  const messageSize = 1000;
  const handshakeMessageSize = 100;

  List<int> createTestData() {
    List<int> data = new List<int>(messageSize);
    for (int i = 0; i < messageSize; i++) {
      data[i] = i & 0xff;
    }
    return data;
  }

  List<int> createHandshakeTestData() {
    List<int> data = new List<int>(handshakeMessageSize);
    for (int i = 0; i < handshakeMessageSize; i++) {
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

  void verifyHandshakeTestData(List<int> data) {
    Expect.equals(handshakeMessageSize, data.length);
    List<int> expected = createHandshakeTestData();
    for (int i = 0; i < handshakeMessageSize; i++) {
      Expect.equals(expected[i], data[i]);
    }
  }

  Future runServer(Socket client) {
    var completer = new Completer();
    var dataReceived = [];
    client.listen(
        (data) {
          dataReceived.addAll(data);
          if (dataReceived.length == messageSize) {
            verifyTestData(dataReceived);
            client.add(dataReceived);
            client.close();
          }
        },
        onDone: () => completer.complete(null));
    return completer.future;
  }

  Future<RawSocket> runClient(Socket socket) {
    var completer = new Completer();
    var dataReceived = [];
    socket.listen(
        (data) {
          dataReceived.addAll(data);
        },
        onDone: () {
          Expect.equals(messageSize, dataReceived.length);
          verifyTestData(dataReceived);
          socket.close();
          completer.complete(null);
        });
    socket.add(createTestData());
    return completer.future;
  }

  Future runServerHandshake(Socket client) {
    var completer = new Completer();
    var dataReceived = [];
    var subscription;
    subscription = client.listen(
        (data) {
          if (dataReceived.length == handshakeMessageSize) {
            Expect.isTrue(postponeSecure);
            subscription.pause();
            completer.complete(data);
          }
          dataReceived.addAll(data);
          if (dataReceived.length == handshakeMessageSize) {
            verifyHandshakeTestData(dataReceived);
            client.add(dataReceived);
            if (!postponeSecure) {
              completer.complete(null);
            }
          }
        },
        onDone: () => completer.complete(null));
    return completer.future;
  }

  Future<Socket> runClientHandshake(Socket socket) {
    var completer = new Completer();
    var dataReceived = [];
    socket.listen(
        (data) {
          dataReceived.addAll(data);
          if (dataReceived.length == handshakeMessageSize) {
            verifyHandshakeTestData(dataReceived);
            completer.complete(null);
          }
        },
        onDone: () => Expect.fail("Should not be called")
    );
    socket.add(createHandshakeTestData());
    return completer.future;
  }

  Future<SecureSocket> connectClient(int port) {
    if (!handshakeBeforeSecure) {
      return Socket.connect(HOST_NAME, port).then((socket) {
        var future;
        if (hostnameInConnect) {
          future = SecureSocket.secure(socket);
        } else {
          future = SecureSocket.secure(socket, host: HOST_NAME);
        }
        return future.then((secureSocket) {
          Expect.throws(() => socket.add([0]));
          return secureSocket;
        });
      });
    } else {
      return Socket.connect(HOST_NAME, port).then((socket) {
        return runClientHandshake(socket).then((_) {
            var future;
            if (hostnameInConnect) {
              future = SecureSocket.secure(socket);
            } else {
              future = SecureSocket.secure(socket, host: HOST_NAME);
            }
            return future.then((secureSocket) {
              Expect.throws(() => socket.add([0]));
              return secureSocket;
            });
        });
      });
    }
  }

  serverReady(server) {
    server.listen((client) {
      if (!handshakeBeforeSecure) {
        SecureSocket.secureServer(client, CERTIFICATE).then((secureClient) {
          Expect.throws(() => client.add([0]));
          runServer(secureClient).then((_) => server.close());
        });
      } else {
        runServerHandshake(client).then((carryOverData) {
          SecureSocket.secureServer(
              client,
              CERTIFICATE,
              bufferedData: carryOverData).then((secureClient) {
            Expect.throws(() => client.add([0]));
            runServer(secureClient).then((_) => server.close());
          });
        });
      }
    });

    connectClient(server.port).then(runClient).then((socket) {
      port.close();
    });
  }

  ServerSocket.bind(HOST_NAME, 0).then(serverReady);
}

main() {
  Path scriptDir = new Path(Platform.script).directoryPath;
  Path certificateDatabase = scriptDir.append('pkcert');
  SecureSocket.initialize(database: certificateDatabase.toNativePath(),
                          password: 'dartdart',
                          useBuiltinRoots: false);
  test(false, false);
  test(true, false);
  test(false, true);
  test(true, true);
  test(false, true, true);
  test(true, true, true);
}
