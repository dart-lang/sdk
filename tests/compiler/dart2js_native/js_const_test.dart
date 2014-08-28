// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'dart:_foreign_helper' show JS, JS_CONST;

test1() {
  var re = const JS_CONST(r'/-([\da-z])/ig');
  var fToUpper = const JS_CONST(
      r'function(_, letter){return letter.toUpperCase()}');
  var s1 = '-hello-world';
  var s2 = JS('String', r'#.replace(#, #)', s1, re, fToUpper);
  Expect.equals('HelloWorld', s2);

  s1 = 'hello-world';
  s2 = JS('String', r'#.replace(#, #)', s1, re, fToUpper);
  Expect.equals('helloWorld', s2);
}

main() {
  test1();
}
