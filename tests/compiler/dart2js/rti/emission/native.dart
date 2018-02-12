// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
// ignore: import_internal_library
import 'dart:_js_helper' show Native;
// ignore: import_internal_library
import 'dart:_foreign_helper' show JS;

/*class: Purple:checks=[$isPurple]*/
@Native('PPPP')
class Purple {}

@Native('QQQQ')
class Q {}

@NoInline()
makeP() => JS('returns:;creates:Purple', 'null');

@NoInline()
makeQ() => JS('Q', 'null');

@NoInline()
testNative() {
  var x = makeP();
  Expect.isTrue(x is Purple);
  x = makeQ();
  Expect.isFalse(x is Purple);
}

main() {
  testNative();
}
