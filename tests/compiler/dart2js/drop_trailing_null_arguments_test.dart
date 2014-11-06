// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that parameters keep their names in the output.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'compiler_helper.dart';

main() {
  // If a function call has trailing 'null' arguments, we can safely skip
  // them as JavaScript will fill missing arguments with 'undefined'.
  asyncTest(() => compile(r"""
      class It<A, B> {
        It([a, b, c]) : super;
      }

      foo(a,b,c) => a;
      test() {
        foo(1, null, null);
        foo(2, 3, null);
        new It();
        new It(null, 1);
      }
      """,
      entry: 'test', minify: false).then((String generated) {
    Expect.isTrue(generated.contains(r"foo(1)"));
    Expect.isTrue(generated.contains(r"foo(2, 3)"));
    Expect.isTrue(generated.contains(r"It$()"));
    Expect.isTrue(generated.contains(r"It$(null, 1)"));
  }));
}
