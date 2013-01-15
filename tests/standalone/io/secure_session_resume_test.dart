// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test tests TLS session resume, by making multiple client connections
// on the same port to the same server, with a delay of 200 ms between them.
// The unmodified secure_server_test creates all sessions simultaneously,
// which means that no handshake completes and caches its keys in the session
// cache in time for other connections to use it.
//
// Session resume is currently disabled - see issue
// https://code.google.com/p/dart/issues/detail?id=7230

import "dart:async";
import "dart:io";
import "dart:isolate";

const SERVER_ADDRESS = "127.0.0.1";
const HOST_NAME = "localhost";

void WriteAndClose(Socket socket, String message) {
  var data = message.charCodes;
  int written = 0;
  void write() {
    written += socket.writeList(data, written, data.length - written);
    if (written < data.length) {
      socket.onWrite = write;
    } else {
      socket.close(true);
    }
  }
  write();
}

class SecureTestServer {
  void onConnection(Socket connection) {
    connection.onConnect = () {
      numConnections++;
    };
    String received = "";
    connection.onData = () {
      received = received.concat(new String.fromCharCodes(connection.read()));
    };
    connection.onClosed = () {
      Expect.isTrue(received.contains("Hello from client "));
      String name = received.substring(received.indexOf("client ") + 7);
      WriteAndClose(connection, "Welcome, client $name");
    };
  }

  void errorHandlerServer(Exception e) {
    Expect.fail("Server socket error $e");
  }

  int start() {
    server = new SecureServerSocket(SERVER_ADDRESS, 0, 10, "CN=$HOST_NAME");
    Expect.isNotNull(server);
    server.onConnection = onConnection;
    server.onError = errorHandlerServer;
    return server.port;
  }

  void stop() {
    server.close();
  }

  int numConnections = 0;
  SecureServerSocket server;
}

class SecureTestClient {
  SecureTestClient(int this.port, String this.name) {
    socket = new SecureSocket(HOST_NAME, port);
    socket.onConnect = this.onConnect;
    socket.onData = () {
      reply = reply.concat(new String.fromCharCodes(socket.read()));
    };
    socket.onClosed = done;
    reply = "";
  }

  void onConnect() {
    numRequests++;
    WriteAndClose(socket, "Hello from client $name");
  }

  void done() {
    Expect.equals("Welcome, client $name", reply);
    numReplies++;
    if (numReplies == CLIENT_NAMES.length) {
      Expect.equals(numRequests, numReplies);
      EndTest();
    }
  }

  static int numRequests = 0;
  static int numReplies = 0;

  int port;
  String name;
  SecureSocket socket;
  String reply;
}

Function EndTest;

const CLIENT_NAMES = const ['able', 'baker'];

void main() {
  ReceivePort keepAlive = new ReceivePort();
  Path scriptDir = new Path(new Options().script).directoryPath;
  Path certificateDatabase = scriptDir.append('pkcert');
  SecureSocket.initialize(database: certificateDatabase.toNativePath(),
                          password: 'dartdart',
                          useBuiltinRoots: false);

  var server = new SecureTestServer();
  int port = server.start();

  EndTest = () {
    Expect.equals(CLIENT_NAMES.length, server.numConnections);
    server.stop();
    keepAlive.close();
  };

  int delay = 0;
  int delay_between_connections = 300;  // Milliseconds.

  for (var x in CLIENT_NAMES) {
    new Timer(delay, (_) {
      new SecureTestClient(port, x);
    });
    delay += delay_between_connections;
  }
}
