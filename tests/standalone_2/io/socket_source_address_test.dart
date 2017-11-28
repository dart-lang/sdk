// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

import 'test_utils.dart' show freeIPv4AndIPv6Port, retry;

Future throws(Function f, Function check) async {
  try {
    await f();
    Expect.fail('Did not throw');
  } catch (e) {
    if (check != null) {
      if (!check(e)) {
        Expect.fail('Unexpected: $e');
      }
    }
  }
}

Future testArguments(connectFunction) async {
  int freePort = await freeIPv4AndIPv6Port();

  var sourceAddress;
  asyncStart();
  var server =
      await ServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, freePort);
  server.listen((_) {
    throw 'Unexpected connection from address $sourceAddress';
  }, onDone: () => asyncEnd());

  asyncStart();
  // Illegal type for sourceAddress.
  for (sourceAddress in ['www.google.com', 'abc']) {
    await throws(() => connectFunction('127.0.0.1', server.port,
            sourceAddress: sourceAddress),
        (e) => e is ArgumentError);
  }
  // Unsupported local address.
  for (sourceAddress in ['8.8.8.8', new InternetAddress('8.8.8.8')]) {
    await throws(
        () => connectFunction('127.0.0.1', server.port,
            sourceAddress: sourceAddress),
        (e) =>
            e is SocketException &&
            e.address == new InternetAddress('8.8.8.8'));
  }
  // Address family mismatch.
  for (sourceAddress in ['::1', InternetAddress.LOOPBACK_IP_V6]) {
    await throws(
        () => connectFunction('127.0.0.1', server.port,
            sourceAddress: sourceAddress),
        (e) => e is SocketException);
  }
  asyncEnd();
  server.close();
}

// IPv4 addresses to use as source address when connecting locally.
var ipV4SourceAddresses = [
  InternetAddress.LOOPBACK_IP_V4,
  InternetAddress.ANY_IP_V4,
  '127.0.0.1',
  '0.0.0.0'
];

// IPv6 addresses to use as source address when connecting locally.
var ipV6SourceAddresses = [
  InternetAddress.LOOPBACK_IP_V6,
  InternetAddress.ANY_IP_V6,
  '::1',
  '::'
];

Future testConnect(InternetAddress bindAddress, bool v6Only,
    Function connectFunction, Function closeDestroyFunction) async {
  int freePort = await freeIPv4AndIPv6Port();

  var successCount = 0;
  if (!v6Only) successCount += ipV4SourceAddresses.length;
  if (bindAddress.type == InternetAddressType.IP_V6) {
    successCount += ipV6SourceAddresses.length;
  }
  var count = 0;
  var allConnected = new Completer();
  if (successCount == 0) allConnected.complete();

  asyncStart();
  var server = await ServerSocket.bind(bindAddress, freePort, v6Only: v6Only);
  server.listen((s) {
    s.destroy();
    count++;
    if (count == successCount) allConnected.complete();
  }, onDone: () => asyncEnd());

  asyncStart();

  // Connect with IPv4 source addesses.
  for (var sourceAddress in ipV4SourceAddresses) {
    if (!v6Only) {
      var s = await connectFunction(InternetAddress.LOOPBACK_IP_V4, server.port,
          sourceAddress: sourceAddress);
      closeDestroyFunction(s);
    } else {
      // Cannot use an IPv4 source address to connect to IPv6 if
      // v6Only is specified.
      await throws(
          () => connectFunction(InternetAddress.LOOPBACK_IP_V6, server.port,
              sourceAddress: sourceAddress),
          (e) => e is SocketException);
    }
  }

  // Connect with IPv6 source addesses.
  for (var sourceAddress in ipV6SourceAddresses) {
    if (bindAddress.type == InternetAddressType.IP_V6) {
      var s = await connectFunction(InternetAddress.LOOPBACK_IP_V6, server.port,
          sourceAddress: sourceAddress);
      closeDestroyFunction(s);
    } else {
      // Cannot use an IPv6 source address to connect to IPv4.
      await throws(
          () => connectFunction(InternetAddress.LOOPBACK_IP_V4, server.port,
              sourceAddress: sourceAddress),
          (e) => e is SocketException);
    }
  }

  await allConnected.future;
  await server.close();
  asyncEnd();
}

main() async {
  asyncStart();

  await retry(() async {
    await testArguments(RawSocket.connect);
  });
  await retry(() async {
    await testArguments(Socket.connect);
  });

  await retry(() async {
    await testConnect(
        InternetAddress.ANY_IP_V4, false, RawSocket.connect, (s) => s.close());
  });
  await retry(() async {
    await testConnect(
        InternetAddress.ANY_IP_V4, false, Socket.connect, (s) => s.destroy());
  });
  await retry(() async {
    await testConnect(
        InternetAddress.ANY_IP_V6, false, RawSocket.connect, (s) => s.close());
  });
  await retry(() async {
    await testConnect(
        InternetAddress.ANY_IP_V6, false, Socket.connect, (s) => s.destroy());
  });
  await retry(() async {
    await testConnect(
        InternetAddress.ANY_IP_V6, true, RawSocket.connect, (s) => s.close());
  });
  await retry(() async {
    await testConnect(
        InternetAddress.ANY_IP_V6, true, Socket.connect, (s) => s.destroy());
  });

  asyncEnd();
}
