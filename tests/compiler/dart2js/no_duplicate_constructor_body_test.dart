// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  String generated = compileAll(CODE);
  RegExp regexp = new RegExp(r'\$.A = {"":"[A-za-z]+;"');
  Iterator<Match> matches = regexp.allMatches(generated).iterator();
  checkNumberOfMatches(matches, 1);
}
