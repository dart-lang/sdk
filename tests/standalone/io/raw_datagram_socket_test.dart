// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

class FutureExpect {
  static Future check(Future result, check) =>
      result.then((value) => check(value));
  static Future throws(Future result) => result.then((value) {
        throw new ExpectException(
            "FutureExpect.throws received $value instead of an exception");
      }, onError: (_) => null);
}

testDatagramBroadcastOptions() {
  test(address) {
    asyncStart();
    RawDatagramSocket.bind(address, 0).then((socket) {
      Expect.isFalse(socket.broadcastEnabled);
      socket.broadcastEnabled = true;
      if (!Platform.isMacOS) {
        Expect.isTrue(socket.broadcastEnabled);
      }
      socket.broadcastEnabled = false;
      Expect.isFalse(socket.broadcastEnabled);
      asyncEnd();
    });
  }

  test(InternetAddress.LOOPBACK_IP_V4);
  test(InternetAddress.ANY_IP_V4);
}

testDatagramMulticastOptions() {
  test(address) {
    asyncStart();
    RawDatagramSocket.bind(address, 0).then((socket) {
      Expect.isTrue(socket.multicastLoopback);
      Expect.equals(1, socket.multicastHops);
      Expect.throws(() => socket.multicastInterface);

      socket.multicastLoopback = false;
      socket.multicastHops = 4;
      Expect.isFalse(socket.multicastLoopback);
      Expect.equals(4, socket.multicastHops);
      Expect.throws(() => socket.multicastInterface = null);

      socket.multicastLoopback = true;
      socket.multicastHops = 1;
      Expect.isTrue(socket.multicastLoopback);
      Expect.equals(1, socket.multicastHops);
      Expect.throws(() => socket.multicastInterface);

      asyncEnd();
    });
  }

  test(InternetAddress.LOOPBACK_IP_V4);
  test(InternetAddress.ANY_IP_V4);
  test(InternetAddress.LOOPBACK_IP_V6);
  test(InternetAddress.ANY_IP_V6);
}

testDatagramSocketReuseAddress() {
  test(address, reuseAddress) {
    asyncStart();
    RawDatagramSocket
        .bind(address, 0, reuseAddress: reuseAddress)
        .then((socket) {
      if (reuseAddress) {
        RawDatagramSocket
            .bind(address, socket.port)
            .then((s) => Expect.isTrue(s is RawDatagramSocket))
            .then(asyncSuccess);
      } else {
        FutureExpect
            .throws(RawDatagramSocket.bind(address, socket.port))
            .then(asyncSuccess);
      }
    });
  }

  test(InternetAddress.LOOPBACK_IP_V4, true);
  test(InternetAddress.LOOPBACK_IP_V4, false);
  test(InternetAddress.LOOPBACK_IP_V6, true);
  test(InternetAddress.LOOPBACK_IP_V6, false);
}

testBroadcast() {
  test(bindAddress, broadcastAddress, enabled) {
    asyncStart();
    Future.wait([
      RawDatagramSocket.bind(bindAddress, 0, reuseAddress: false),
      RawDatagramSocket.bind(bindAddress, 0, reuseAddress: false)
    ]).then((values) {
      var broadcastTimer;
      var sender = values[0];
      var receiver = values[1];
      // On Windows at least the receiver needs to have broadcast
      // enabled whereas on Linux at least the sender needs to.
      receiver.broadcastEnabled = enabled;
      sender.broadcastEnabled = enabled;
      receiver.listen((event) {
        if (event == RawSocketEvent.READ) {
          Expect.isTrue(enabled);
          sender.close();
          receiver.close();
          broadcastTimer.cancel();
          asyncEnd();
        }
      });

      int sendCount = 0;
      send(_) {
        int bytes =
            sender.send(new Uint8List(1), broadcastAddress, receiver.port);
        Expect.isTrue(bytes == 0 || bytes == 1);
        sendCount++;
        if (!enabled && sendCount == 50) {
          sender.close();
          receiver.close();
          broadcastTimer.cancel();
          asyncEnd();
        }
      }

      broadcastTimer = new Timer.periodic(new Duration(milliseconds: 10), send);
    });
  }

  var broadcast = new InternetAddress("255.255.255.255");
  test(InternetAddress.ANY_IP_V4, broadcast, false);
  test(InternetAddress.ANY_IP_V4, broadcast, true);
}

testLoopbackMulticast() {
  test(bindAddress, multicastAddress, enabled) {
    asyncStart();
    Future.wait([
      RawDatagramSocket.bind(bindAddress, 0, reuseAddress: false),
      RawDatagramSocket.bind(bindAddress, 0, reuseAddress: false)
    ]).then((values) {
      var senderTimer;
      var sender = values[0];
      var receiver = values[1];

      sender.joinMulticast(multicastAddress);
      receiver.joinMulticast(multicastAddress);
      // On Windows at least the receiver needs to have multicast
      // loop enabled whereas on Linux at least the sender needs to.
      receiver.multicastLoopback = enabled;
      sender.multicastLoopback = enabled;

      receiver.listen((event) {
        if (event == RawSocketEvent.READ) {
          if (!enabled) {
            var data = receiver.receive();
            print(data.port);
            print(data.address);
          }
          Expect.isTrue(enabled);
          sender.close();
          receiver.close();
          senderTimer.cancel();
          asyncEnd();
        }
      });

      int sendCount = 0;
      send(_) {
        int bytes =
            sender.send(new Uint8List(1), multicastAddress, receiver.port);
        Expect.isTrue(bytes == 0 || bytes == 1);
        sendCount++;
        if (!enabled && sendCount == 50) {
          sender.close();
          receiver.close();
          senderTimer.cancel();
          asyncEnd();
        }
      }

      senderTimer = new Timer.periodic(new Duration(milliseconds: 10), send);
    });
  }

  test(InternetAddress.ANY_IP_V4, new InternetAddress("228.0.0.4"), true);
  test(InternetAddress.ANY_IP_V4, new InternetAddress("224.0.0.0"), false);
  if (!Platform.isMacOS) {
    test(InternetAddress.ANY_IP_V6, new InternetAddress("ff11::0"), true);
    test(InternetAddress.ANY_IP_V6, new InternetAddress("ff11::0"), false);
  }
}

testLoopbackMulticastError() {
  var bindAddress = InternetAddress.ANY_IP_V4;
  var multicastAddress = new InternetAddress("228.0.0.4");
  asyncStart();
  Future.wait([
    RawDatagramSocket.bind(bindAddress, 0, reuseAddress: false),
    RawDatagramSocket.bind(bindAddress, 0, reuseAddress: false)
  ]).then((values) {
    var sender = values[0];
    var receiver = values[1];
    Expect.throws(() {
      sender.joinMulticast(new InternetAddress("127.0.0.1"));
    }, (e) => e is! TypeError);
    sender.close();
    receiver.close();
    asyncEnd();
  });
}

testSendReceive(InternetAddress bindAddress, int dataSize) {
  asyncStart();

  var total = 1000;

  int receivedSeq = 0;

  var ackSeq = 0;
  Timer ackTimer;

  Future.wait([
    RawDatagramSocket.bind(bindAddress, 0, reuseAddress: false),
    RawDatagramSocket.bind(bindAddress, 0, reuseAddress: false)
  ]).then((values) {
    var sender = values[0];
    var receiver = values[1];
    if (bindAddress.isMulticast) {
      sender.multicastLoopback = true;
      receiver.multicastLoopback = true;
      sender.joinMulticast(bindAddress);
      receiver.joinMulticast(bindAddress);
    }

    Uint8List createDataPackage(int seq) {
      var data = new Uint8List(dataSize);
      (new ByteData.view(data.buffer, 0, 4)).setUint32(0, seq);
      return data;
    }

    Uint8List createAckPackage(int seq) {
      var data = new Uint8List(4);
      new ByteData.view(data.buffer, 0, 4).setUint32(0, seq);
      return data;
    }

    int packageSeq(Datagram datagram) =>
        new ByteData.view((datagram.data as Uint8List).buffer).getUint32(0);

    void sendData(int seq) {
      // Send a datagram acknowledging the received sequence.
      int bytes =
          sender.send(createDataPackage(seq), bindAddress, receiver.port);
      Expect.isTrue(bytes == 0 || bytes == dataSize);
    }

    void sendAck(address, port) {
      // Send a datagram acknowledging the received sequence.
      int bytes = receiver.send(createAckPackage(receivedSeq), address, port);
      Expect.isTrue(bytes == 0 || bytes == 4);
      // Start a "long" timer for more data.
      if (ackTimer != null) ackTimer.cancel();
      ackTimer = new Timer.periodic(
          new Duration(milliseconds: 100), (_) => sendAck(address, port));
    }

    sender.listen((event) {
      switch (event) {
        case RawSocketEvent.READ:
          var datagram = sender.receive();
          if (datagram != null) {
            Expect.equals(datagram.port, receiver.port);
            if (!bindAddress.isMulticast) {
              Expect.equals(receiver.address, datagram.address);
            }
            ackSeq = packageSeq(datagram);
            if (ackSeq < total) {
              sender.writeEventsEnabled = true;
            } else {
              sender.close();
              receiver.close();
              ackTimer.cancel();
              asyncEnd();
            }
          }
          break;
        case RawSocketEvent.WRITE:
          // Send the next package.
          sendData(ackSeq + 1);
          break;
        case RawSocketEvent.CLOSED:
          break;
        default:
          throw "Unexpected event $event";
      }
    });

    receiver.writeEventsEnabled = false;
    receiver.listen((event) {
      switch (event) {
        case RawSocketEvent.READ:
          var datagram = receiver.receive();
          if (datagram != null) {
            Expect.equals(datagram.port, sender.port);
            Expect.equals(dataSize, datagram.data.length);
            if (!bindAddress.isMulticast) {
              Expect.equals(receiver.address, datagram.address);
            }
            var seq = packageSeq(datagram);
            if (seq == receivedSeq + 1) {
              receivedSeq = seq;
              sendAck(bindAddress, sender.port);
            }
          }
          break;
        case RawSocketEvent.WRITE:
          throw "Unexpected WRITE";
          break;
        case RawSocketEvent.CLOSED:
          break;
        default:
          throw "Unexpected event $event";
      }
    });
  });
}

main() {
  testDatagramBroadcastOptions();
  testDatagramMulticastOptions();
  if (!Platform.isMacOS) {
    testDatagramSocketReuseAddress();
  }
  testBroadcast();
  testLoopbackMulticast();
  testLoopbackMulticastError();
  testSendReceive(InternetAddress.LOOPBACK_IP_V4, 1000);
  testSendReceive(InternetAddress.LOOPBACK_IP_V6, 1000);
  if (!Platform.isMacOS) {
    testSendReceive(InternetAddress.LOOPBACK_IP_V4, 32 * 1024);
    testSendReceive(InternetAddress.LOOPBACK_IP_V6, 32 * 1024);
    testSendReceive(InternetAddress.LOOPBACK_IP_V4, 64 * 1024 - 32);
    testSendReceive(InternetAddress.LOOPBACK_IP_V6, 64 * 1024 - 32);
  }
}
