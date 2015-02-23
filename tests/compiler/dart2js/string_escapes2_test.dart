// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'compiler_helper.dart';

// Test that the compiler doesn't escape too many characters.

Future<String> compileExpression(String expression) {
  var source = "foo() { return $expression; }";
  return compile(source, entry: "foo");
}

Future runTest() {
  return compileExpression(r"'Тест на Кирилица - great.\n"
                           r'Next "line".\u2028'
                           r'And another one.\u2029'
                           r"and the last one'")
      .then((String generated) {
    Expect.isTrue(
        generated.contains(r'"Тест на Кирилица - great.\n'
                           r'Next \"line\".\u2028'
                           r'And another one.\u2029'
                           r'and the last one"') ||
        generated.contains(r"'Тест на Кирилица - great.\n"
                           r'Next "line".\u2028'
                           r'And another one.\u2029'
                           r"and the last one'"));
  });
}

main() {
  asyncTest(runTest);
}
