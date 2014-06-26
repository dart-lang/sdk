// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String TEST_ONE = r"""
class A {}
bool foo(bar) {
  var x = new A();
  var y = new A();
  return identical(x, y);
}
""";

main() {
  asyncTest(() => compile(TEST_ONE, entry: 'foo', check: (String generated) {

    // Check that no boolify code is generated.
    RegExp regexp = new RegExp("=== true");
    Iterator matches = regexp.allMatches(generated).iterator;
    Expect.isFalse(matches.moveNext());

    regexp = new RegExp("===");
    matches = regexp.allMatches(generated).iterator;
    Expect.isTrue(matches.moveNext());
    Expect.isFalse(matches.moveNext());
  }));
}
