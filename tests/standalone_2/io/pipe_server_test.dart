// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// OtherResources=readline_test1.dat
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

library ServerTest;

import "dart:async";
import "dart:io";
import "dart:isolate";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

part "testing_server.dart";

String getDataFilename(String path) =>
    Platform.script.resolve(path).toFilePath();

bool compareFileContent(String fileName1, String fileName2) {
  var contents1 = new File(fileName1).readAsStringSync();
  var contents2 = new File(fileName2).readAsStringSync();
  return contents1 == contents2;
}

// This test does:
//  1. Opens a socket to the testing server.
//  2. Pipes the content of a file to that sockets input stream.
//  3. Creates a temp file.
//  4. Pipes the socket output stream to the temp file.
//  5. Expects the original file and the temp file to be equal.
class PipeServerGame {
  int count = 0;

  PipeServerGame.start() : _messages = 0 {
    initialize();
  }

  void runTest() {
    void connectHandler() {
      String srcFileName = getDataFilename("readline_test1.dat");
      Stream fileInput = new File(srcFileName).openRead();
      fileInput.pipe(_socket).then((_) {
        var tempDir = Directory.systemTemp.createTempSync('dart_pipe_server');
        var dstFileName = tempDir.path + "/readline_test1.dat";
        var dstFile = new File(dstFileName);
        dstFile.createSync();
        var fileOutput = dstFile.openWrite();
        _socket.pipe(fileOutput).then((_) {
          // Check that the resulting file is equal to the initial
          // file.
          bool result = compareFileContent(srcFileName, dstFileName);
          new File(dstFileName).deleteSync();
          tempDir.deleteSync();
          Expect.isTrue(result);

          // Run this twice.
          if (count++ < 2) {
            runTest();
          } else {
            shutdown();
          }
        });
      });
    }

    // Connect to the server.
    Socket.connect(TestingServer.HOST, _port).then((s) {
      _socket = s;
      connectHandler();
    });
  }

  void initialize() {
    var receivePort = new ReceivePort();
    var remote = Isolate.spawn(startPipeServer, receivePort.sendPort);
    receivePort.first.then((msg) {
      this._port = msg[0];
      this._closeSendPort = msg[1];
      runTest();
    });
  }

  void shutdown() {
    _closeSendPort.send(null);
    asyncEnd();
  }

  int _port;
  SendPort _closeSendPort;
  Socket _socket;
  int _messages;
}

void startPipeServer(Object replyPortObj) {
  SendPort replyPort = replyPortObj;
  var server = new PipeServer();
  server.init().then((port) {
    replyPort.send([port, server.closeSendPort]);
  });
}

// The testing server will simply pipe each connecting sockets input
// stream to its output stream.
class PipeServer extends TestingServer {
  void onConnection(Socket connection) {
    connection.pipe(connection);
  }
}

main() {
  asyncStart();
  PipeServerGame echoServerGame = new PipeServerGame.start();
}
