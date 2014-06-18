// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'compiler_helper.dart';

// Test that the compiler handles string literals containing line terminators.

Future<String> compileExpression(String expression) {
  var source = "foo() { return $expression; }";
  return compile(source, entry: "foo");
}

main() {
  asyncTest(() => Future.wait([
    compileExpression("''' \n\r\u2028\u2029'''").then((String generated) {
      Expect.isTrue(generated.contains(r'"\r\u2028\u2029"') ||
                    generated.contains(r"'\r\u2028\u2029'"));
    }),
    compileExpression("r''' \n\r\u2028\u2029'''").then((String generated) {
      Expect.isTrue(generated.contains(r'"\r\u2028\u2029"') ||
                    generated.contains(r"'\r\u2028\u2029'"));
    }),
    compileExpression("r''' \r\n\u2028\u2029'''").then((String generated) {
      Expect.isTrue(generated.contains(r'"\u2028\u2029"') ||
                    generated.contains(r"'\u2028\u2029'"));
    }),
    compileExpression("r''' \r\u2028\u2029'''").then((String generated) {
      Expect.isTrue(generated.contains(r'"\u2028\u2029"') ||
                    generated.contains(r"'\u2028\u2029'"));
    }),
    compileExpression("r''' \n\u2028\u2029'''").then((String generated) {
      Expect.isTrue(generated.contains(r'"\u2028\u2029"') ||
                    generated.contains(r"'\u2028\u2029'"));
    }),
    compileExpression("r'''\t\t      \t\t  \t\t  \t \t \n\r\u2028\u2029'''")
        .then((String generated) {
      Expect.isTrue(generated.contains(r'"\r\u2028\u2029"') ||
                    generated.contains(r"'\r\u2028\u2029'"));
    }),
    compileExpression("r'''\\\t\\\t \\   \\  \t\\\t  \t \\\n\r\u2028\u2029'''")
        .then((String generated) {
      Expect.isTrue(generated.contains(r'"\r\u2028\u2029"') ||
                    generated.contains(r"'\r\u2028\u2029'"));
    }),
    compileExpression("r'''\t\t      \t\t  \t\t  \t \t \\\n\r\u2028\u2029'''")
        .then((String generated) {
      Expect.isTrue(generated.contains(r'"\r\u2028\u2029"') ||
                    generated.contains(r"'\r\u2028\u2029'"));
    }),
    compileExpression("r'''\\\t\\\t \\   \\  \t\\\t   \\\r\n\u2028\u2029'''")
        .then((String generated) {
      Expect.isTrue(generated.contains(r'"\u2028\u2029"') ||
                    generated.contains(r"'\u2028\u2029'"));
    }),
    compileExpression("r'''\\\t\\\t \\   \\  \t\\\t   \\\r\u2028\u2029'''")
        .then((String generated) {
      Expect.isTrue(generated.contains(r'"\u2028\u2029"') ||
                    generated.contains(r"'\u2028\u2029'"));
    }),
    compileExpression("'\u2028\u2029'").then((String generated) {
      Expect.isTrue(generated.contains(r'"\u2028\u2029"') ||
                    generated.contains(r"'\u2028\u2029'"));
    }),
  ]));
}
