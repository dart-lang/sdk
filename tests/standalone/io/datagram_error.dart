// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing error path in datagram bind call.

import 'dart:io';

import "package:expect/expect.dart";

void main() async {
  try {
    final socket = await RawDatagramSocket.bind(
      InternetAddress('/tmp/test_socket', type: InternetAddressType.unix),
      0,
    );
    Expect.fail(
      "Should not reach this: "
      "the bind call above should have failed",
    );
    socket.listen((data) {
      print(data);
    });
  } catch (e) {
    Expect.fail(
      "Should not reach this: "
      "the bind call above throws unhandled exception",
    );
  }
}
