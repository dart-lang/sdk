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

  test(InternetAddress.loopbackIPv4);
  test(InternetAddress.anyIPv4);
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

  test(InternetAddress.loopbackIPv4);
  test(InternetAddress.anyIPv4);
  test(InternetAddress.loopbackIPv6);
  test(InternetAddress.anyIPv6);
}

testDatagramSocketReuseAddress() {
  test(address, reuseAddress) {
    asyncStart();
    RawDatagramSocket.bind(address, 0,
            reuseAddress: reuseAddress,
            reusePort: Platform.isMacOS && reuseAddress)
        .then((socket) async {
      if (reuseAddress) {
        RawDatagramSocket.bind(address, socket.port,
                reusePort: Platform.isMacOS)
            .then((s) => Expect.isTrue(s is RawDatagramSocket))
            .then(asyncSuccess);
      } else {
        await FutureExpect.throws(RawDatagramSocket.bind(address, socket.port))
            .then(asyncSuccess);
      }
    });
  }

  test(InternetAddress.loopbackIPv4, true);
  test(InternetAddress.loopbackIPv4, false);
  test(InternetAddress.loopbackIPv6, true);
  test(InternetAddress.loopbackIPv6, false);
}

testDatagramSocketTtl() {
  test(address, ttl, shouldSucceed) {
    asyncStart();
    if (shouldSucceed) {
      RawDatagramSocket.bind(address, 0, ttl: ttl).then(asyncSuccess);
    } else {
      Expect.throws(() => RawDatagramSocket.bind(address, 0, ttl: ttl));
      asyncEnd();
    }
  }

  test(InternetAddress.loopbackIPv4, 1, true);
  test(InternetAddress.loopbackIPv4, 255, true);
  test(InternetAddress.loopbackIPv4, 256, false);
  test(InternetAddress.loopbackIPv4, 0, false);
  test(InternetAddress.loopbackIPv4, null, false);

  test(InternetAddress.loopbackIPv6, 1, true);
  test(InternetAddress.loopbackIPv6, 255, true);
  test(InternetAddress.loopbackIPv6, 256, false);
  test(InternetAddress.loopbackIPv6, 0, false);
  test(InternetAddress.loopbackIPv6, null, false);
}

testDatagramSocketMulticastIf() {
  test(address) async {
    asyncStart();
    final socket = await RawDatagramSocket.bind(address, 0);
    RawSocketOption option;
    int idx;
    if (address.type == InternetAddressType.IPv4) {
      option = RawSocketOption(RawSocketOption.levelIPv4,
          RawSocketOption.IPv4MulticastInterface, address.rawAddress);
    } else {
      if (!NetworkInterface.listSupported) {
        asyncEnd();
        return;
      }
      var interface = await NetworkInterface.list();
      if (interface.length == 0) {
        asyncEnd();
        return;
      }
      idx = interface[0].index;
      option = RawSocketOption.fromInt(RawSocketOption.levelIPv6,
          RawSocketOption.IPv6MulticastInterface, idx);
    }

    socket.setRawOption(option);
    final getResult = socket.getRawOption(option);

    if (address.type == InternetAddressType.IPv4) {
      Expect.listEquals(getResult, address.rawAddress);
    } else {
      // RawSocketOption.fromInt() will create a Uint8List(4).
      Expect.equals(
          getResult.buffer.asByteData().getUint32(0, Endian.host), idx);
    }

    asyncSuccess(socket);
  }

  test(InternetAddress.loopbackIPv4);
  test(InternetAddress.anyIPv4);
  test(InternetAddress.loopbackIPv6);
  test(InternetAddress.anyIPv6);
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
        if (event == RawSocketEvent.read) {
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
  test(InternetAddress.anyIPv4, broadcast, false);
  test(InternetAddress.anyIPv4, broadcast, true);
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
        if (event == RawSocketEvent.read) {
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

  test(InternetAddress.anyIPv4, new InternetAddress("228.0.0.4"), true);
  test(InternetAddress.anyIPv4, new InternetAddress("224.0.0.0"), false);
  // TODO(30306): Reenable for Linux
  if (!Platform.isMacOS && !Platform.isLinux) {
    test(InternetAddress.anyIPv6, new InternetAddress("ff11::0"), true);
    test(InternetAddress.anyIPv6, new InternetAddress("ff11::0"), false);
  }
}

testLoopbackMulticastError() {
  var bindAddress = InternetAddress.anyIPv4;
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
        case RawSocketEvent.read:
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
        case RawSocketEvent.write:
          // Send the next package.
          sendData(ackSeq + 1);
          break;
        case RawSocketEvent.closed:
          break;
        default:
          throw "Unexpected event $event";
      }
    });

    receiver.writeEventsEnabled = false;
    receiver.listen((event) {
      switch (event) {
        case RawSocketEvent.read:
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
        case RawSocketEvent.write:
          throw "Unexpected.write";
          break;
        case RawSocketEvent.closed:
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
  testDatagramSocketReuseAddress();
  testDatagramSocketTtl();
  testDatagramSocketMulticastIf();
  testBroadcast();
  testLoopbackMulticast();
  testLoopbackMulticastError();
  testSendReceive(InternetAddress.loopbackIPv4, 1000);
  testSendReceive(InternetAddress.loopbackIPv6, 1000);
  if (!Platform.isMacOS) {
    testSendReceive(InternetAddress.loopbackIPv4, 32 * 1024);
    testSendReceive(InternetAddress.loopbackIPv6, 32 * 1024);
    testSendReceive(InternetAddress.loopbackIPv4, 64 * 1024 - 32);
    testSendReceive(InternetAddress.loopbackIPv6, 64 * 1024 - 32);
  }
}
