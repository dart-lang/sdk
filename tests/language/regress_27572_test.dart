// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test static noSuchMethod with a prefix.

import "package:expect/expect.dart";

import 'dart:collection' as col;

main() {
  try {
    col.foobar(1234567);
  } catch (e) {
    Expect.isTrue(e.toString().contains("1234567"));
  }
}
