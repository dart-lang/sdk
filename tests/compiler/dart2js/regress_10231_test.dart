// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/10231.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'codegen_helper.dart';

void main() {
  asyncTest(() => generate(SOURCE).then((result) {
    var code = result['test'];
    Expect.isNotNull(code);
    Expect.equals(0, new RegExp('add').allMatches(code).length);
    Expect.equals(3, new RegExp('\\+').allMatches(code).length);
  }));
}

const String SOURCE = """
test(a, b, c, d) {
  if (a is !num) throw 'a not num';
  if (b is !num) throw 'b not num';
  if (c is !num) throw 'c not num';
  if (d is !num) throw 'd not num';
  return a + b + c + d;
}

main() {
  test(1, 2, 3, 4);
  test('x', 'y', 'z', 'w');
  test([], {}, [], {});
}
""";
