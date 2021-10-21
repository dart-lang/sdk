// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

// @dart = 2.9

import "dart:async";
import "dart:io";

import 'test_utils.dart' show retry, throws, withTempDir;

Future testArguments(connectFunction) async {
  var sourceAddress;
  final serverIPv4 = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  serverIPv4.listen((_) {
    throw 'Unexpected connection from address $sourceAddress';
  });

  final serverIPv6 = await ServerSocket.bind(InternetAddress.loopbackIPv6, 0);
  serverIPv6.listen((_) {
    throw 'Unexpected connection from address $sourceAddress';
  });

  // Illegal type for sourceAddress.
  for (sourceAddress in ['www.google.com', 'abc']) {
    await throws(
        () => connectFunction('127.0.0.1', serverIPv4.port,
            sourceAddress: sourceAddress),
        (e) => e is ArgumentError);
  }
  // Unsupported local address.
  for (sourceAddress in ['8.8.8.8', new InternetAddress('8.8.8.8')]) {
    await throws(
        () => connectFunction('127.0.0.1', serverIPv4.port,
            sourceAddress: sourceAddress),
        (e) =>
            e is SocketException &&
            e.address == new InternetAddress('8.8.8.8'));
  }
  // Address family mismatch for IPv4.
  for (sourceAddress in [
    '::1',
    InternetAddress.loopbackIPv6,
    InternetAddress('sock', type: InternetAddressType.unix)
  ]) {
    await throws(
        () => connectFunction('127.0.0.1', serverIPv4.port,
            sourceAddress: sourceAddress),
        (e) => e is SocketException);
  }
  // Address family mismatch for IPv6.
  for (sourceAddress in [
    '127.0.0.1',
    InternetAddress.loopbackIPv4,
    InternetAddress('sock', type: InternetAddressType.unix)
  ]) {
    await throws(
        () => connectFunction('::1', serverIPv6.port,
            sourceAddress: sourceAddress),
        (e) => e is SocketException);
  }

  await serverIPv4.close();
  await serverIPv6.close();
}

Future testUnixDomainArguments(connectFunction, String socketDir) async {
  var sourceAddress;
  final serverUnix = await ServerSocket.bind(
      InternetAddress('$socketDir/sock', type: InternetAddressType.unix), 0);
  serverUnix.listen((_) {
    throw 'Unexpected connection from address $sourceAddress';
  });

  // Address family mismatch for Unix domain sockets.
  for (sourceAddress in [
    '127.0.0.1',
    InternetAddress.loopbackIPv4,
    '::1',
    InternetAddress.loopbackIPv6,
  ]) {
    await throws(
        () => connectFunction(
            InternetAddress("$socketDir/sock", type: InternetAddressType.unix),
            serverUnix.port,
            sourceAddress: sourceAddress),
        (e) =>
            e is SocketException &&
            e.toString().contains('Address family not supported'));
  }
  await serverUnix.close();
}

// IPv4 addresses to use as source address when connecting locally.
var ipV4SourceAddresses = [
  InternetAddress.loopbackIPv4,
  InternetAddress.anyIPv4,
  '127.0.0.1',
  '0.0.0.0'
];

// IPv6 addresses to use as source address when connecting locally.
var ipV6SourceAddresses = [
  InternetAddress.loopbackIPv6,
  InternetAddress.anyIPv6,
  '::1',
  '::'
];

Future testConnect(InternetAddress bindAddress, bool v6Only,
    Function connectFunction, Function closeDestroyFunction) async {
  var successCount = 0;
  if (!v6Only) successCount += ipV4SourceAddresses.length;
  if (bindAddress.type == InternetAddressType.IPv6) {
    successCount += ipV6SourceAddresses.length;
  }
  var count = 0;
  var allConnected = new Completer();
  if (successCount == 0) allConnected.complete();

  var server = await ServerSocket.bind(bindAddress, 0, v6Only: v6Only);
  server.listen((s) {
    s.destroy();
    count++;
    if (count == successCount) allConnected.complete();
  });

  // Connect with IPv4 source addresses.
  for (var sourceAddress in ipV4SourceAddresses) {
    if (!v6Only) {
      var s = await connectFunction(InternetAddress.loopbackIPv4, server.port,
          sourceAddress: sourceAddress);
      closeDestroyFunction(s);
    } else {
      // Cannot use an IPv4 source address to connect to IPv6 if
      // v6Only is specified.
      await throws(
          () => connectFunction(InternetAddress.loopbackIPv6, server.port,
              sourceAddress: sourceAddress),
          (e) => e is SocketException);
    }
  }

  // Connect with IPv6 source addresses.
  for (var sourceAddress in ipV6SourceAddresses) {
    if (bindAddress.type == InternetAddressType.IPv6) {
      var s = await connectFunction(InternetAddress.loopbackIPv6, server.port,
          sourceAddress: sourceAddress);
      closeDestroyFunction(s);
    } else {
      // Cannot use an IPv6 source address to connect to IPv4.
      await throws(
          () => connectFunction(InternetAddress.loopbackIPv4, server.port,
              sourceAddress: sourceAddress),
          (e) => e is SocketException);
    }
  }

  await allConnected.future;
  await server.close();
}

main() async {
  await retry(() async {
    await testArguments(RawSocket.connect);
  });
  await retry(() async {
    await testArguments(Socket.connect);
  });

  if (Platform.isMacOS || Platform.isLinux || Platform.isAndroid) {
    await retry(() async {
      await withTempDir('unix_socket_test', (Directory dir) async {
        await testUnixDomainArguments(RawSocket.connect, "${dir.path}");
      });
    });
    await retry(() async {
      await withTempDir('unix_socket_test', (Directory dir) async {
        await testUnixDomainArguments(Socket.connect, "${dir.path}");
      });
    });
  }
  await retry(() async {
    await testConnect(
        InternetAddress.anyIPv4, false, RawSocket.connect, (s) => s.close());
  });
  await retry(() async {
    await testConnect(
        InternetAddress.anyIPv4, false, Socket.connect, (s) => s.destroy());
  });
  await retry(() async {
    await testConnect(
        InternetAddress.anyIPv6, false, RawSocket.connect, (s) => s.close());
  });
  await retry(() async {
    await testConnect(
        InternetAddress.anyIPv6, false, Socket.connect, (s) => s.destroy());
  });
  await retry(() async {
    await testConnect(
        InternetAddress.anyIPv6, true, RawSocket.connect, (s) => s.close());
  });
  await retry(() async {
    await testConnect(
        InternetAddress.anyIPv6, true, Socket.connect, (s) => s.destroy());
  });
}
