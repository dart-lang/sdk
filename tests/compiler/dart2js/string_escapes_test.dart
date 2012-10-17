// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("compiler_helper.dart");

// Test that the compiler handles string literals containing line terminators.

String compileExpression(String expression) {
  var source = "foo() { return $expression; }";
  return compile(source, entry: "foo");
}

main() {
  String generated = compileExpression("''' \n\r\u2028\u2029'''");
  Expect.isTrue(generated.contains(r"\n\r\u2028\u2029"));

  generated = compileExpression("r''' \n\r\u2028\u2029'''");
  Expect.isTrue(generated.contains(r"\n\r\u2028\u2029"));

  generated = compileExpression("'\u2028\u2029'");
  Expect.isTrue(generated.contains(r"\u2028\u2029"));
}
