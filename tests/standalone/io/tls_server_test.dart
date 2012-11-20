// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

const SERVER_ADDRESS = "127.0.0.1";
const HOST_NAME = "localhost";

class TlsTestServer {
  void onConnection(Socket connection) {
    connection.onConnect = () {
      numConnections++;
    };
    connection.onData = () {
      var data = connection.read();
      var received = new String.fromCharCodes(data);
      Expect.isTrue(received.contains("Hello from client "));
      string name = received.substring(received.indexOf("client ") + 7);
      var reply_bytes = "Welcome, client $name".charCodes;
      connection.writeList(reply_bytes, 0, reply_bytes.length);
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
    socket.onConnect = this.onConnect;
    socket.onData = this.onData;
    reply = "";
  }

  void onConnect() {
    numRequests++;
    var request_bytes =
        "Hello from client $name".charCodes;
    socket.writeList(request_bytes, 0, request_bytes.length);
  }

  void onData() {
    var data = socket.read();
    var received = new String.fromCharCodes(data);
    reply = reply.concat(received);
    if (reply.contains("Welcome") && reply.contains(name)) {
      done();
    }
  }

  void done() {
    Expect.equals("Welcome, client $name", reply);
    socket.close(true);
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
