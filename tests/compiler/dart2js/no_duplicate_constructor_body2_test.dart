// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'compiler_helper.dart';
import "package:async_helper/async_helper.dart";

const String CODE = """
var x = 0;
class A {
  A() { x++; }
}

class B extends A {
  B();
}

main() {
  new B();
  new A();
}
""";

main() {
  asyncTest(() => compileAll(CODE).then((generated) {
        RegExp regexp = new RegExp(r'A\$0: function');
        Iterator<Match> matches = regexp.allMatches(generated).iterator;
        checkNumberOfMatches(matches, 1);
      }));
}
