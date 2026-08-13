// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/f34a2ed99fc1b34cedbd974a5801f8d922121126/runtime/vm/isolate_reload_test.cc#L4181

var a, hash1, hash2;

class A {
  var x;
}

void helper() {
  a = new A();
  hash1 = a.hashCode;
}

Future<void> main() async {
  helper();
  await hotReload();
  helper();
  Expect.equals(hash1, hash2);
}
