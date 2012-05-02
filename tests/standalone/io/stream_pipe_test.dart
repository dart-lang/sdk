// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

#import("dart:io");
#import("dart:isolate");
#source("testing_server.dart");

// Helper method to be able to run the test from the runtime
// directory, or the top directory.
String getDataFilename(String path) =>
    new File(path).existsSync() ? path : '../' + path;


bool compareFileContent(String fileName1,
                        String fileName2,
                        [int file1Offset = 0,
                         int file2Offset = 0,
                         int count]) {
  var file1 = new File(fileName1).openSync();
  var file2 = new File(fileName2).openSync();
  var length1 = file1.lengthSync();
  var length2 = file2.lengthSync();
  if (file1Offset == 0 && file2Offset == 0 && count == null) {
    if (length1 != length2) {
      file1.closeSync();
      file2.closeSync();
      return false;
    }
  }
  if (count == null) count = length1;
  var data1 = new List<int>(count);
  var data2 = new List<int>(count);
  if (file1Offset != 0) file1.setPositionSync(file1Offset);
  if (file2Offset != 0) file2.setPositionSync(file2Offset);
  var read1 = file1.readListSync(data1, 0, count);
  Expect.equals(count, read1);
  var read2 = file2.readListSync(data2, 0, count);
  Expect.equals(count, read2);
  for (var i = 0; i < count; i++) {
    if (data1[i] != data2[i]) {
      file1.closeSync();
      file2.closeSync();
      return false;
    }
  }
  file1.closeSync();
  file2.closeSync();
  return true;
}


// This test does:
//  1. Opens a socket to the testing server.
//  2. Pipes the content of a file to that sockets input stream.
//  3. Creates a temp file.
//  4. Pipes the socket output stream to the temp file.
//  5. Expects the original file and the temp file to be equal.
class PipeServerGame {
  int count = 0;

  PipeServerGame.start()
      : _receivePort = new ReceivePort(),
        _sendPort = null,
        _messages = 0 {
    new PipeServer().spawn().then((SendPort port) {
      _sendPort = port;
      start();
    });
  }

  void runTest() {

    void connectHandler() {
      String srcFileName =
          getDataFilename("tests/standalone/io/readline_test1.dat");

      SocketOutputStream socketOutput = _socket.outputStream;
      InputStream fileInput = new File(srcFileName).openInputStream();

      fileInput.onClosed = () {
        SocketInputStream socketInput = _socket.inputStream;
        var tempDir = new Directory('');
        tempDir.createTempSync();
        var dstFileName = tempDir.path + "/readline_test1.dat";
        var dstFile = new File(dstFileName);
        dstFile.createSync();
        var fileOutput = dstFile.openOutputStream();

        socketInput.onClosed = () {
          // Check that the resulting file is equal to the initial
          // file.
          fileOutput.onClosed = () {
            bool result = compareFileContent(srcFileName, dstFileName);
            new File(dstFileName).deleteSync();
            tempDir.deleteSync();
            Expect.isTrue(result);

            _socket.close();

            // Run this twice.
            if (count++ < 2) {
              runTest();
            } else {
              shutdown();
            }
          };
        };

        socketInput.pipe(fileOutput);
      };

      fileInput.pipe(socketOutput);
    }

    // Connect to the server.
    _socket = new Socket(TestingServer.HOST, _port);
    if (_socket !== null) {
      _socket.onConnect = connectHandler;
    } else {
      Expect.fail("socket creation failed");
    }
  }

  void start() {
    _receivePort.receive((var message, SendPort replyTo) {
      _port = message;
      runTest();
    });
    _sendPort.send(TestingServer.INIT, _receivePort.toSendPort());
  }

  void shutdown() {
    _sendPort.send(TestingServer.SHUTDOWN, _receivePort.toSendPort());
    _receivePort.close();
  }

  int _port;
  ReceivePort _receivePort;
  SendPort _sendPort;
  Socket _socket;
  int _messages;
}


// The testing server will simply pipe each connecting sockets input
// stream to its output stream.
class PipeServer extends TestingServer {
  void onConnection(Socket connection) {
    connection.onError = (Exception e) { Expect.fail("Socket error $e"); };
    connection.inputStream.pipe(connection.outputStream);
  }
}


// Test piping from one file to another and closing both streams
// after wards.
testFileToFilePipe1() {
  // Force test to timeout if one of the handlers is
  // not called.
  ReceivePort donePort = new ReceivePort();
  donePort.receive((message, ignore) { donePort.close(); });

  String srcFileName =
      getDataFilename("tests/standalone/io/readline_test1.dat");
  var srcStream = new File(srcFileName).openInputStream();

  var tempDir = new Directory('');
  tempDir.createTempSync();
  String dstFileName = tempDir.path + "/readline_test1.dat";
  new File(dstFileName).createSync();
  var dstStream = new File(dstFileName).openOutputStream();

  dstStream.onClosed = () {
    bool result = compareFileContent(srcFileName, dstFileName);
    new File(dstFileName).deleteSync();
    tempDir.deleteSync();
    Expect.isTrue(result);
    donePort.toSendPort().send(null);
  };

  srcStream.pipe(dstStream);
}


// Test piping from one file to another and write additional data to
// the output stream after piping finished.
testFileToFilePipe2() {
  // Force test to timeout if one of the handlers is
  // not called.
  ReceivePort donePort = new ReceivePort();
  donePort.receive((message, ignore) { donePort.close(); });

  String srcFileName =
      getDataFilename("tests/standalone/io/readline_test1.dat");
  var srcFile = new File(srcFileName);
  var srcStream = srcFile.openInputStream();

  var tempDir = new Directory('');
  tempDir.createTempSync();
  var dstFileName = tempDir.path + "/readline_test1.dat";
  var dstFile = new File(dstFileName);
  dstFile.createSync();
  var dstStream = dstFile.openOutputStream();

  srcStream.onClosed = () {
    dstStream.write([32]);
    dstStream.close();
    dstStream.onClosed = () {
      var src = srcFile.openSync();
      var dst = dstFile.openSync();
      var srcLength = src.lengthSync();
      var dstLength = dst.lengthSync();
      Expect.equals(srcLength + 1, dstLength);
      Expect.isTrue(compareFileContent(srcFileName,
                                       dstFileName,
                                       count: srcLength));
      dst.setPositionSync(srcLength);
      var data = new List<int>(1);
      var read2 = dst.readListSync(data, 0, 1);
      Expect.equals(32, data[0]);
      src.closeSync();
      dst.closeSync();
      dstFile.deleteSync();
      tempDir.deleteSync();
      donePort.toSendPort().send(null);
    };
  };

  srcStream.pipe(dstStream, close: false);
}


// Test piping two copies of one file to another.
testFileToFilePipe3() {
  // Force test to timeout if one of the handlers is
  // not called.
  ReceivePort donePort = new ReceivePort();
  donePort.receive((message, ignore) { donePort.close(); });

  String srcFileName =
      getDataFilename("tests/standalone/io/readline_test1.dat");
  var srcFile = new File(srcFileName);
  var srcStream = srcFile.openInputStream();

  var tempDir = new Directory('');
  tempDir.createTempSync();
  var dstFileName = tempDir.path + "/readline_test1.dat";
  var dstFile = new File(dstFileName);
  dstFile.createSync();
  var dstStream = dstFile.openOutputStream();

  srcStream.onClosed = () {
    var srcStream2 = srcFile.openInputStream();

    dstStream.onClosed = () {
      var src = srcFile.openSync();
      var dst = dstFile.openSync();
      var srcLength = src.lengthSync();
      var dstLength = dst.lengthSync();
      Expect.equals(srcLength * 2, dstLength);
      Expect.isTrue(compareFileContent(srcFileName,
                                       dstFileName,
                                       count: srcLength));
      Expect.isTrue(compareFileContent(srcFileName,
                                       dstFileName,
                                       file2Offset: srcLength,
                                       count: srcLength));
      src.closeSync();
      dst.closeSync();
      dstFile.deleteSync();
      tempDir.deleteSync();
      donePort.toSendPort().send(null);
    };

    // Pipe another copy of the source file.
    srcStream2.pipe(dstStream);
  };

  srcStream.pipe(dstStream, close: false);
}


main() {
  testFileToFilePipe1();
  testFileToFilePipe2();
  testFileToFilePipe3();
  PipeServerGame echoServerGame = new PipeServerGame.start();
}
