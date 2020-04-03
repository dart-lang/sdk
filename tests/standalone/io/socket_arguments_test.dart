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

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void main() {
  Expect.throws(() => ServerSocket.bind("127.0.0.1", 65536));
  Expect.throws(() => ServerSocket.bind("127.0.0.1", -1));
  Expect.throws(() => ServerSocket.bind("127.0.0.1", 0, backlog: -1));
}
