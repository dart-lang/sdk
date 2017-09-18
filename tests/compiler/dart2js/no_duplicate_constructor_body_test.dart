// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';

const String CODE = """
class A {
  A(String b) { b.length; }
}

main() {
  new A("foo");
}
""";

main() {
  asyncTest(() => compileAll(CODE).then((generated) {
        RegExp regexp = new RegExp(r'\A: {[ \n]*"\^": "[A-Za-z]+;"');
        Iterator<Match> matches = regexp.allMatches(generated).iterator;
        checkNumberOfMatches(matches, 1);
      }));
}
