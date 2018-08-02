// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/20122
// Verifies that identityHashCode for strings does not interfere
// with normal hashCode.

import 'package:expect/expect.dart';

var prefix = 'x';

make(v) => '${prefix}${v}'; // to inhibit constant folding.

void main() {
  final x = make('test');
  final y = make('test');
  // On 64-bit platforms there is a field in the header that is used to cache
  // hash value for both Object.get:hashCode and identityHashCode(...).
  // Which means that implementation of these two methods should match
  // otherwise you will get different hash codes for otherwise identical objects.
  identityHashCode(y);
  Expect.equals(x.hashCode, y.hashCode);
}
