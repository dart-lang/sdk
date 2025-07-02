// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void main() async {
  SocketException? error;
  try {
    await RawDatagramSocket.bind(
      InternetAddress('/tmp/test_socket', type: InternetAddressType.unix),
      0,
    );
  } on SocketException catch (e) {
    error = e;
  }
  Expect.contains(
    'Cannot bind datagram socket on non-IPv4/IPv6 address',
    '$error',
  );
}
