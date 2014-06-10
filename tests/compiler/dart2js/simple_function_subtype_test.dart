// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that simple function subtype checks use predicates.

library simple_function_subtype_test;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

const String TEST = r"""
typedef Args0();
typedef Args1(a);
typedef Args2(a, b);
typedef Args3(a, b, c);
typedef Args4(a, b, c, d);
typedef Args5(a, b, c, d, e);
typedef Args6(a, b, c, d, e, f);
typedef Args7(a, b, c, d, e, f, g);
typedef Args8(a, b, c, d, e, f, g, h);
typedef Args9(a, b, c, d, e, f, g, h, i);
typedef Args10(a, b, c, d, e, f, g, h, i, j);
typedef Args11(a, b, c, d, e, f, g, h, i, j, k);
typedef Args12(a, b, c, d, e, f, g, h, i, j, k, l);
typedef Args13(a, b, c, d, e, f, g, h, i, j, k, l, m);
typedef Args14(a, b, c, d, e, f, g, h, i, j, k, l, m, n);
typedef Args15(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o);

args5_10(a, b, c, d, e, [f, g, h, i, j]) {}

foo() {
  print(args5_10 is Args0);
  print(args5_10 is Args1);
  print(args5_10 is Args2);
  print(args5_10 is Args3);
  print(args5_10 is Args4);
  print(args5_10 is Args5);
  print(args5_10 is Args6);
  print(args5_10 is Args7);
  print(args5_10 is Args8);
  print(args5_10 is Args9);
  print(args5_10 is Args10);
  print(args5_10 is Args11);
  print(args5_10 is Args12);
  print(args5_10 is Args13);
  print(args5_10 is Args14);
  print(args5_10 is Args15);
}
""";

main() {
  asyncTest(() => compile(TEST, entry: 'foo', check: (String generated) {
    for (int i = 0 ; i <= 15  ; i++) {
      String predicateCheck = '.\$is_args$i';
      Expect.isTrue(generated.contains(predicateCheck),
        'Expected predicate check $predicateCheck');
    }
    Expect.isFalse(generated.contains('checkFunctionSubtype'),
      'Unexpected use of checkFunctionSubtype');
  }));
}