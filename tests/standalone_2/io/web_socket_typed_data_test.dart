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
import "dart:typed_data";

Future<HttpServer> createServer() => HttpServer.bind("127.0.0.1", 0);

Future<WebSocket> createClient(int port, bool compression) => compression
    ? WebSocket.connect('ws://127.0.0.1:$port/')
    : WebSocket.connect('ws://127.0.0.1:$port/',
        compression: CompressionOptions.OFF);

void test(expected, testData, compression) {
  createServer().then((server) {
    var messageCount = 0;
    var transformer = compression
        ? new WebSocketTransformer()
        : new WebSocketTransformer(compression: CompressionOptions.OFF);
    server.transform(transformer).listen((webSocket) {
      webSocket.listen((message) {
        Expect.listEquals(expected, message);
        webSocket.add(testData[messageCount]);
        messageCount++;
      }, onDone: () => Expect.equals(testData.length, messageCount));
    });

    createClient(server.port, compression).then((webSocket) {
      var messageCount = 0;
      webSocket.listen((message) {
        Expect.listEquals(expected, message);
        messageCount++;
        if (messageCount == testData.length) webSocket.close();
      }, onDone: server.close);
      testData.forEach(webSocket.add);
    });
  });
}

testUintLists({bool compression: false}) {
  var fillData = new List.generate(256, (index) => index);
  var testData = [
    new Uint8List(256),
    new Uint8ClampedList(256),
    new Uint16List(256),
    new Uint32List(256),
    new Uint64List(256),
  ];
  testData.forEach((list) => list.setAll(0, fillData));
  test(fillData, testData, compression);
}

testIntLists({bool compression: false}) {
  var fillData = new List.generate(128, (index) => index);
  var testData = [
    new Int8List(128),
    new Int16List(128),
    new Int32List(128),
    new Int64List(128),
  ];
  testData.forEach((list) => list.setAll(0, fillData));
  test(fillData, testData, compression);
}

void testOutOfRangeClient({bool compression: false}) {
  createServer().then((server) {
    var messageCount = 0;
    var transformer = compression
        ? new WebSocketTransformer()
        : new WebSocketTransformer(compression: CompressionOptions.OFF);
    server.transform(transformer).listen((webSocket) {
      webSocket.listen((message) => Expect.fail("No message expected"));
    });

    Future clientError(data) {
      return createClient(server.port, compression).then((webSocket) {
        var messageCount = 0;
        webSocket.listen((message) => Expect.fail("No message expected"));
        webSocket.add(data);
        webSocket.close();
        return webSocket.done;
      });
    }

    Future expectError(data) {
      var completer = new Completer();
      clientError(data)
          .then((_) => completer.completeError("Message $data did not fail"))
          .catchError((e) => completer.complete(true));
      return completer.future;
    }

    var futures = <Future>[];
    var data;
    data = new Uint16List(1);
    data[0] = 256;
    futures.add(expectError(data));
    data = new Uint32List(1);
    data[0] = 256;
    futures.add(expectError(data));
    data = new Uint64List(1);
    data[0] = 256;
    futures.add(expectError(data));
    data = new Int16List(1);
    data[0] = 256;
    futures.add(expectError(data));
    data[0] = -1;
    futures.add(expectError(data));
    data = new Int32List(1);
    data[0] = 256;
    futures.add(expectError(data));
    data[0] = -1;
    futures.add(expectError(data));
    data = new Int64List(1);
    data[0] = 256;
    futures.add(expectError(data));
    data[0] = -1;
    futures.add(expectError(data));
    futures.add(expectError([-1]));
    futures.add(expectError([256]));

    Future.wait(futures).then((_) => server.close());
  });
}

void testOutOfRangeServer({bool compression: false}) {
  var futures = <Future>[];
  var testData = [];
  var data;
  data = new Uint16List(1);
  data[0] = 256;
  testData.add(data);
  data = new Uint32List(1);
  data[0] = 256;
  testData.add(data);
  data = new Uint64List(1);
  data[0] = 256;
  testData.add(data);
  data = new Int16List(1);
  data[0] = 256;
  testData.add(data);
  data = new Int16List(1);
  data[0] = -1;
  testData.add(data);
  data = new Int32List(1);
  data[0] = 256;
  testData.add(data);
  data = new Int32List(1);
  data[0] = -1;
  testData.add(data);
  data = new Int64List(1);
  data[0] = 256;
  testData.add(data);
  data = new Int64List(1);
  data[0] = -1;
  testData.add(data);
  testData.add([-1]);
  testData.add([256]);

  var allDone = new Completer();

  Future expectError(future) {
    var completer = new Completer();
    future
        .then((_) => completer.completeError("Message $data did not fail"))
        .catchError((e) => completer.complete(true));
    return completer.future;
  }

  createServer().then((server) {
    var messageCount = 0;
    var transformer = compression
        ? new WebSocketTransformer()
        : new WebSocketTransformer(compression: CompressionOptions.OFF);
    server.transform(transformer).listen((webSocket) {
      webSocket.listen((message) {
        messageCount++;
        webSocket.add(testData[message[0]]);
        webSocket.close();
        futures.add(expectError(webSocket.done));
        if (messageCount == testData.length) allDone.complete(true);
      });
    });

    Future x(int i) {
      var completer = new Completer();
      createClient(server.port, compression).then((webSocket) {
        webSocket.listen((message) => Expect.fail("No message expected"),
            onDone: () => completer.complete(true),
            onError: (e) => completer.completeError(e));
        webSocket.add(new List()..add(i));
      });
      return completer.future;
    }

    for (int i = 0; i < testData.length; i++) futures.add(x(i));
    allDone.future
        .then((_) => Future.wait(futures).then((_) => server.close()));
  });
}

main() {
  testUintLists();
  testUintLists(compression: true);
  testIntLists();
  testIntLists(compression: true);
  testOutOfRangeClient();
  testOutOfRangeClient(compression: true);
  // testOutOfRangeServer();
  // testOutOfRangeServer(compression: true);
}
