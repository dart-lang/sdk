// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7
// Test constant folding on numbers.

import 'package:async_helper/async_helper.dart';
import '../helpers/compiler_helper.dart';

const String CODE = """
class A {
  var _link;
  get link => _link;
}
foo(x) {
  if (new DateTime.now().millisecondsSinceEpoch == 42) return null;
  var a = new A();
  if (new DateTime.now().millisecondsSinceEpoch == 42) return a;
  a._link = a;
  return a;
}
main() {
  A x = foo(0);
  return x == x.link;
}
""";

main() {
  asyncTest(() async {
    // The `==` is strengthened to a HIdentity instruction. The HIdentity
    // follows `x.link`, so x cannot be `null`.
    var compare = new RegExp(r'x === x\.get\$link\(\)');
    await compileAndMatch(CODE, 'main', compare);
  });
}
