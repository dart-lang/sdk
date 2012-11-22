// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

const SERVER_ADDRESS = "127.0.0.1";
const HOST_NAME = "localhost";

class TlsTestServer {
  void onConnection(Socket connection) {
    numConnections++;
    var input = connection.inputStream;
    String received = "";
    input.onData = () {
      received = received.concat(new String.fromCharCodes(input.read()));
    };
    input.onClosed = () {
      Expect.isTrue(received.contains("Hello from client "));
      String name = received.substring(received.indexOf("client ") + 7);
      connection.outputStream.write("Welcome, client $name".charCodes);
      connection.outputStream.close();
    };
  }

  void errorHandlerServer(Exception e) {
    Expect.fail("Server socket error $e");
  }

  int start() {
    server = new TlsServerSocket(SERVER_ADDRESS, 0, 10, "CN=$HOST_NAME");
    Expect.isNotNull(server);
    server.onConnection = onConnection;
    server.onError = errorHandlerServer;
    return server.port;
  }

  void stop() {
    server.close();
  }

  int numConnections = 0;
  TlsServerSocket server;
}

class TlsTestClient {
  TlsTestClient(int this.port, String this.name) {
    socket = new TlsSocket(HOST_NAME, port);
    numRequests++;
    socket.outputStream.write("Hello from client $name".charCodes);
    socket.outputStream.close();
    socket.inputStream.onData = () {
      reply = reply.concat(new String.fromCharCodes(socket.inputStream.read()));
    };
    socket.inputStream.onClosed = this.done;
    reply = "";
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
  TlsSocket socket;
  String reply;
}

Function EndTest;

const CLIENT_NAMES = const ['able', 'baker', 'camera', 'donut', 'echo'];

void main() {
  Path scriptDir = new Path.fromNative(new Options().script).directoryPath;
  Path certificateDatabase = scriptDir.append('pkcert');
  TlsSocket.setCertificateDatabase(certificateDatabase.toNativePath(),
                                   'dartdart');

  var server = new TlsTestServer();
  int port = server.start();

  EndTest = () {
    Expect.equals(CLIENT_NAMES.length, server.numConnections);
    server.stop();
  };

  for (var x in CLIENT_NAMES) {
    new TlsTestClient(port, x);
  }
}
