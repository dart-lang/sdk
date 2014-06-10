// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String TEST_ONE = r"""
foo(j) {
  var array = [1, 2, 3];
  if (j < 0) j = 0;
  for (var i = j; i < 3; i++) {
    array[i];
  }
}
""";

main() {
  asyncTest(() => compile(TEST_ONE, entry: 'foo', check: (String generated) {

    // Test for absence of an illegal argument exception. This means that the
    // arguments are known to be integers.
    Expect.isFalse(generated.contains('iae'));
    // Also make sure that we are not just in bailout mode without speculative
    // types by grepping for the integer-bailout check on argument j.
    RegExp regexp = new RegExp(getIntTypeCheck('[aji]'));
    Expect.isTrue(regexp.hasMatch(generated));
  }));
}
