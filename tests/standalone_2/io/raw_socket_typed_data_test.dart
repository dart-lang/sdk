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
import "dart:typed_data";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

testOutOfRange() {
  asyncStart();
  RawServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0).then((server) {
    server.listen((client) {
      client.writeEventsEnabled = false;
      client.listen((event) {
        switch (event) {
          case RawSocketEvent.READ:
            Expect.fail("No data expected");
            break;
          case RawSocketEvent.WRITE:
            break;
          case RawSocketEvent.READ_CLOSED:
            client.close();
            server.close();
            break;
          case RawSocketEvent.CLOSED:
            break;
          default:
            throw "Unexpected event $event";
        }
      });
    });

    RawSocket.connect("127.0.0.1", server.port).then((socket) {
      socket.listen((event) {
        switch (event) {
          case RawSocketEvent.READ:
            break;
          case RawSocketEvent.WRITE:
            Expect.isFalse(socket.writeEventsEnabled);
            var data;
            data = new Uint16List(1);
            data[0] = 256;
            Expect.throws(() => socket.write(data));
            data = new Uint32List(1);
            data[0] = 256;
            Expect.throws(() => socket.write(data));
            data = new Uint64List(1);
            data[0] = 256;
            Expect.throws(() => socket.write(data));
            data = new Int16List(1);
            data[0] = 256;
            Expect.throws(() => socket.write(data));
            data[0] = -1;
            Expect.throws(() => socket.write(data));
            data = new Int32List(1);
            data[0] = 256;
            Expect.throws(() => socket.write(data));
            data[0] = -1;
            Expect.throws(() => socket.write(data));
            data = new Int64List(1);
            data[0] = 256;
            Expect.throws(() => socket.write(data));
            data[0] = -1;
            Expect.throws(() => socket.write(data));
            Expect.throws(() => socket.write([-1]));
            Expect.throws(() => socket.write([256]));
            socket.close();
            break;
          case RawSocketEvent.READ_CLOSED:
            break;
          case RawSocketEvent.CLOSED:
            break;
          default:
            throw "Unexpected event $event";
        }
      }, onDone: asyncEnd);
    });
  });
}

void testSimpleReadWrite() {
  // This test creates a server and a client connects. The client then
  // writes and the server echos. When the server has finished its
  // echo it half-closes. When the client gets the close event is
  // closes fully.
  asyncStart();

  // The test data to send is 5 times 256 bytes and 4 times 128
  // bytes. This is all the legal byte values from the integer typed
  // data.
  const messageSize = 256 * 5 + 128 * 4;
  var fillData128 = new List.generate(128, (index) => index);
  var fillData256 = new List.generate(256, (index) => index);
  List<List<int>> createTestData() {
    return [
      new Uint8List(256)..setAll(0, fillData256),
      new Uint8ClampedList(256)..setAll(0, fillData256),
      new Uint16List(256)..setAll(0, fillData256),
      new Uint32List(256)..setAll(0, fillData256),
      new Uint64List(256)..setAll(0, fillData256),
      new Int8List(128)..setAll(0, fillData128),
      new Int16List(128)..setAll(0, fillData128),
      new Int32List(128)..setAll(0, fillData128),
      new Int64List(128)..setAll(0, fillData128),
    ];
  }

  void verifyTestData(List<int> data) {
    var testData = createTestData();
    var expected = [];
    testData.forEach((list) => expected.addAll(list));
    Expect.listEquals(expected, data);
  }

  RawServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0).then((server) {
    server.listen((client) {
      int bytesRead = 0;
      int bytesWritten = 0;
      int index = 0;
      List<List<int>> data = createTestData();
      List<int> received = new List<int>(messageSize);

      client.writeEventsEnabled = false;
      client.listen((event) {
        switch (event) {
          case RawSocketEvent.READ:
            Expect.isTrue(bytesWritten == 0);
            Expect.isTrue(client.available() > 0);
            var buffer = client.read();
            received.setRange(bytesRead, bytesRead + buffer.length, buffer);
            bytesRead += buffer.length;
            if (bytesRead == messageSize) {
              verifyTestData(received);
              client.writeEventsEnabled = true;
            }
            break;
          case RawSocketEvent.WRITE:
            Expect.isTrue(bytesRead == messageSize);
            Expect.isFalse(client.writeEventsEnabled);
            bytesWritten += client.write(
                data[index], bytesWritten, data[index].length - bytesWritten);
            if (bytesWritten < data[index].length) {
              client.writeEventsEnabled = true;
            } else {
              index++;
              bytesWritten = 0;
              if (index < data.length) {
                client.writeEventsEnabled = true;
              } else {
                client.shutdown(SocketDirection.SEND);
              }
            }
            break;
          case RawSocketEvent.READ_CLOSED:
            server.close();
            break;
          case RawSocketEvent.CLOSED:
            break;
          default:
            throw "Unexpected event $event";
        }
      });
    });

    RawSocket.connect("127.0.0.1", server.port).then((socket) {
      int bytesRead = 0;
      int bytesWritten = 0;
      int index = 0;
      List<List<int>> data = createTestData();
      List<int> received = new List<int>(messageSize);

      socket.listen((event) {
        switch (event) {
          case RawSocketEvent.READ:
            Expect.isTrue(socket.available() > 0);
            var buffer = socket.read();
            received.setRange(bytesRead, bytesRead + buffer.length, buffer);
            bytesRead += buffer.length;
            break;
          case RawSocketEvent.WRITE:
            Expect.isTrue(bytesRead == 0);
            Expect.isFalse(socket.writeEventsEnabled);
            bytesWritten += socket.write(
                data[index], bytesWritten, data[index].length - bytesWritten);
            if (bytesWritten < data[index].length) {
              socket.writeEventsEnabled = true;
            } else {
              index++;
              bytesWritten = 0;
              if (index < data.length) {
                socket.writeEventsEnabled = true;
              }
            }
            break;
          case RawSocketEvent.READ_CLOSED:
            verifyTestData(received);
            socket.close();
            break;
          case RawSocketEvent.CLOSED:
            break;
          default:
            throw "Unexpected event $event";
        }
      }, onDone: asyncEnd);
    });
  });
}

main() {
  // testOutOfRange();
  testSimpleReadWrite();
}
