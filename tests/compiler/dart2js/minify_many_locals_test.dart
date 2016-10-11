// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that parameters keep their names in the output.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'compiler_helper.dart';

// TODO(johnniwinther): This value is some what arbitrary. With the old
// [ResolvedVisitor] we could handle 2000, with the new [ResolvedVisitor] build
// upon the [SemanticVisitor] we can handle <=1000. Update (increase) the value
// when the [SssBuilder] is no longer build upon the [ResolvedVisitor] .
const int NUMBER_OF_PARAMETERS = 1000;

main() {
  var buffer = new StringBuffer();
  buffer.write("foo(");
  for (int i = 0; i < NUMBER_OF_PARAMETERS; i++) {
    buffer.write("x$i, ");
  }
  buffer.write("x) { int i = ");
  for (int i = 0; i < NUMBER_OF_PARAMETERS; i++) {
    buffer.write("x$i+");
  }
  buffer.write("$NUMBER_OF_PARAMETERS; return i; }");
  String code = buffer.toString();

  asyncTest(
      () => compile(code, entry: 'foo', minify: true).then((String generated) {
            RegExp re = new RegExp(r"\(a,b,c");
            Expect.isTrue(re.hasMatch(generated));

            re = new RegExp(r"x,y,z,a0,a1,a2");
            Expect.isTrue(re.hasMatch(generated));

            re = new RegExp(r"y,z,a0,a1,a2,a3,a4,a5,a6");
            Expect.isTrue(re.hasMatch(generated));

            re = new RegExp(r"g8,g9,h0,h1");
            Expect.isTrue(re.hasMatch(generated));

            re = new RegExp(r"z8,z9,aa0,aa1,aa2");
            Expect.isTrue(re.hasMatch(generated));

            re = new RegExp(r"aa9,ab0,ab1");
            Expect.isTrue(re.hasMatch(generated));

            re = new RegExp(r"az9,ba0,ba1");
            Expect.isTrue(re.hasMatch(generated));
          }));
}
