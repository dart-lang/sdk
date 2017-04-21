// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:expect/expect.dart";

void testIllegalArguments() {
  var args = [
    null,
    1,
    1.1,
    new Object(),
    [],
    {'a': '127.0.0.1'},
    "",
    ".",
    ":",
    ":::"
  ];
  args.forEach((arg) {
    Expect.throws(() => new InternetAddress(arg), (e) => e is ArgumentError);
  });
}

void main() {
  testIllegalArguments();
}
