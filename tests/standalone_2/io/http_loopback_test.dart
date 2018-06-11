// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "package:expect/expect.dart";

RawServerSocket server;
RawSocket client;

serverListen(RawSocket serverSide) {
  serveData(RawSocketEvent event) {
    serverSide.shutdown(SocketDirection.send);
  }

  serverSide.listen(serveData);
}

IPv4ToIPv6FailureTest() async {
  server = await RawServerSocket.bind(InternetAddress.loopbackIPv6, 0);
  server.listen(serverListen);
  bool testFailure = false;
  try {
    client = await RawSocket.connect(InternetAddress.loopbackIPv4, server.port);
    await client.close();
    testFailure = true;
  } on SocketException catch (e) {
    // We shouldn't be able to connect to the IPv6 loopback adapter using the
    // IPv4 loopback address.
  } catch (e) {
    testFailure = true;
  } finally {
    Expect.equals(testFailure, false);
    await server.close();
  }
}

IPv6ToIPv4FailureTest() async {
  server = await RawServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  server.listen(serverListen);
  bool testFailure = false;
  try {
    client = await RawSocket.connect(InternetAddress.loopbackIPv6, server.port);
    await client.close();
    testFailure = true;
  } on SocketException catch (e) {
    // We shouldn't be able to connect to the IPv4 loopback adapter using the
    // IPv6 loopback address.
  } catch (e) {
    testFailure = true;
  } finally {
    Expect.equals(testFailure, false);
    await server.close();
  }
}

loopbackSuccessTest(InternetAddress address) async {
  server = await RawServerSocket.bind(address, 0);
  server.listen(serverListen);
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
  await IPv4ToIPv6FailureTest();
  await IPv6ToIPv4FailureTest();
  await loopbackSuccessTest(InternetAddress.loopbackIPv4);
  await loopbackSuccessTest(InternetAddress.loopbackIPv6);
}
