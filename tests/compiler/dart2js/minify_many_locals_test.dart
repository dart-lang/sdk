// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that parameters keep their names in the output.

import 'compiler_helper.dart';

main() {
  var buffer = new StringBuffer();
  buffer.add("var foo(");
  for (int i = 0; i < 2000; i++) {
    buffer.add("x$i, ");
  }
  buffer.add("x) { int i = ");
  for (int i = 0; i < 2000; i++) {
    buffer.add("x$i+");
  }
  buffer.add("2000; return i; }");
  var generated = compile(buffer.toString(), 'foo', minify: true);
  RegExp re = const RegExp(r"\(a,b,c");
  Expect.isTrue(re.hasMatch(generated));

  re = const RegExp(r"x,y,z,A,B,C");
  Expect.isTrue(re.hasMatch(generated));
  
  re = const RegExp(r"Y,Z,a0,a1,a2,a3,a4,a5,a6");
  Expect.isTrue(re.hasMatch(generated));

  re = const RegExp(r"g8,g9,h0,h1");
  Expect.isTrue(re.hasMatch(generated));

  re = const RegExp(r"Z8,Z9,aa0,aa1,aa2");
  Expect.isTrue(re.hasMatch(generated));

  re = const RegExp(r"aa9,ab0,ab1");
  Expect.isTrue(re.hasMatch(generated));

  re = const RegExp(r"aZ9,ba0,ba1");
  Expect.isTrue(re.hasMatch(generated));
}
