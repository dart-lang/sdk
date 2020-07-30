// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=-Ddart.library.io.domain_network_policies=[["notallowed.domain.invalid",true,false]]

import 'dart:io';

import "package:async_helper/async_helper.dart";

void testDisallowedConnection() {
  asyncExpectThrows(
      () async => await Socket.connect("foo.notallowed.domain.invalid", 12345),
      (e) {
    print((e as SocketException).message);
    return e is SocketException &&
        e.message.startsWith(
            "Insecure socket connections are disallowed by platform");
  });
}

void testAllowedConnection() {
  asyncExpectThrows(
      () async => await Socket.connect("allowed.domain.invalid", 12345),
      (e) =>
          e is SocketException &&
          !e.message.startsWith(
              "Insecure socket connections are disallowed by platform"));
}

void main() {
  testDisallowedConnection();
  testAllowedConnection();
}
