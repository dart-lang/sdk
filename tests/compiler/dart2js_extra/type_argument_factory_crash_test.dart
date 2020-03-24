// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// A regression test for a dart2js crash.
library type.argument.factory.crash.test;

import "package:expect/expect.dart";
import 'dart:collection' show LinkedHashMap;

void main() {
  // This constructor call causes a crash in dart2js.
  var o = new LinkedHashMap<int, int>();

  // Comment out this line, the compiler doesn't crash.
  Expect.isFalse(o is List<int>);

  // Enable these two lines, the compiler doesn't crash.
  // Expect.isTrue(o.keys is Iterable<int>);
  // Expect.isFalse(o.keys is Iterable<String>);
}
