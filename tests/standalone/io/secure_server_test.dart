// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

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

const CLIENT_NAMES = const ['able', 'baker', 'camera', 'donut', 'echo'];

void main() {
  Path scriptDir = new Path.fromNative(new Options().script).directoryPath;
  Path certificateDatabase = scriptDir.append('pkcert');
  SecureSocket.setCertificateDatabase(certificateDatabase.toNativePath(),
                                   'dartdart');

  var server = new SecureTestServer();
  int port = server.start();

  EndTest = () {
    Expect.equals(CLIENT_NAMES.length, server.numConnections);
    server.stop();
  };

  for (var x in CLIENT_NAMES) {
    new SecureTestClient(port, x);
  }
}
