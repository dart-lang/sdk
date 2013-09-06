// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that static functions are closurized as expected.

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';

main() {
  asyncTest(() => compileAll(r'''main() { print(main); }''').then((code) {
    // At some point, we will have to closurize global functions
    // differently, at which point this test will break. Then it is time
    // to implement a way to call a Dart closure from JS foreign
    // functions.

    // If this test fail, please take a look at the use of
    // toStringWrapper in captureStackTrace in js_helper.dart.
    Expect.isTrue(code.contains(
        new RegExp(r'print\([$a-z]+\.main\$closure\);')));
  }));
}
