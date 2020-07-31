// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import '../helpers/compiler_helper.dart';

const String TEST1 = r"""
aNonInstanceMethod(x) { print(x); }
const f = aNonInstanceMethod;
foo() {
  f(1);
  // Closure call is reduced to a direct static call.
  // present: '.aNonInstanceMethod(1)'
  // absent: '.call$1(1)'
}
""";

const String TEST2 = r"""
aNonInstanceMethod([x]) { print(x); }
final f = aNonInstanceMethod;
foo() {
  f(1);
  // Closure call is reduced to a direct static call.
  // present: '.aNonInstanceMethod(1)'
  // absent: '.call$1(1)'
}
""";

const String TEST3 = r"""
aNonInstanceMethod([x]) { print(x); }
const f = aNonInstanceMethod;
foo() {
  f();
  // Closure call is not reduced to a direct static call due to not wanting to
  // add default arguments. This may change.
  // absent: '.aNonInstanceMethod('
  // present: '.call$0()'
}
""";

// TODO(29147): Add tests like above where 'f' is local. The above tests fail if
// 'f' is local due to static function references sometimes being represented by
// HConstant (as above) and other times being referenced as HStatic.

main() {
  runTests() async {
    Future check(String test) {
      return compile(test, entry: 'foo', check: checkerForAbsentPresent(test));
    }

    await check(TEST1);
    await check(TEST2);
    await check(TEST3);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
