// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String TEST = """
foo() {
  var a = {};
  var index = foo(); // Make sure we want to optimize this method.
  while (true) a[index] = 1;
}
""";

main() {
  asyncTest(() => compile(TEST, entry: 'foo', check: (String generated) {
    // Make sure we have all the type information we need.
    Expect.isFalse(generated.contains('bailout'));
    Expect.isFalse(generated.contains('interceptor'));
    // Make sure we don't go through an interceptor.
    Expect.isTrue(
        generated.contains(r'a.$indexSet(a') ||
        generated.contains(r'.$indexSet(0'));
  }));
}
