// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";
import "package:expect/expect.dart";

RawServerSocket server;
RawSocket client;

/// Creates a callback that listens for incomming connections.
/// If [remotePorts] is not null then callback would add remote port of each
/// new connection to the given list.
makeListener([List<int> remotePorts]) {
  return (RawSocket serverSide) {
    serveData(RawSocketEvent event) {
      serverSide.shutdown(SocketDirection.send);
    }

    remotePorts?.add(serverSide.remotePort);
    serverSide.listen(serveData);
  };
}

/// Verify that you can't connect to loopback via mismatching protocol, e.g.
/// if the server is listening to IPv4 then you can't connect via IPv6.
Future<void> failureTest(
    InternetAddress serverAddr, InternetAddress clientAddr) async {
  final remotePorts = <int>[];
  server = await RawServerSocket.bind(serverAddr, 0);
  server.listen(makeListener(remotePorts));

  bool success = false;
  try {
    client = await RawSocket.connect(clientAddr, server.port);
    final clientPort = client.port;

    // We might actually succeed in connecting somewhere (e.g. to another test
    // which by chance started listening to the same port).
    // To make this test more robust we add a check that verifies that we did
    // not connect to our server by checking if clientPort is within
    // the list of remotePorts observed by the server. It should not be there.
    await Future.delayed(Duration(seconds: 2));
    success = !remotePorts.contains(clientPort);
    await client.close();
  } on SocketException catch (e) {
    // We expect that we fail to connect to IPv4 server via IPv6 client and
    // vice versa.
    success = true;
  } catch (e) {
    Expect.fail('Unexpected exception: $e');
  } finally {
    Expect.isTrue(success,
        'Unexpected connection to $serverAddr via $clientAddr address!');
    await server.close();
  }
}

Future<void> successTest(InternetAddress address) async {
  server = await RawServerSocket.bind(address, 0);
  server.listen(makeListener());
  bool testFailure = false;
  try {
    client = await RawSocket.connect(address, server.port);
    await client.close();
  } catch (e) {
    testFailure = true;
  } finally {
    Expect.equals(testFailure, false);
    await server.close();
  }
}

main() async {
  await failureTest(InternetAddress.loopbackIPv4, InternetAddress.loopbackIPv6);
  await failureTest(InternetAddress.loopbackIPv6, InternetAddress.loopbackIPv4);
  await successTest(InternetAddress.loopbackIPv4);
  await successTest(InternetAddress.loopbackIPv6);
}
