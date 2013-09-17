// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';
import 'package:expect/expect.dart';
import 'stringify.dart';

testIntercepted() {
  var instance = [];
  var methodMirror = reflect(instance.toString);
  String rest = ' in s(List)';
  rest = ''; /// 01: ok
  expect('Method(s(toString)$rest)', methodMirror.function);
  Expect.equals('[]', methodMirror.apply([]).reflectee);
}

testNonIntercepted() {
  var closure = new Map().containsKey;
  var mirror = reflect(closure);
  String rest = ' in s(_HashMap)'; // Might become Map instead.
  rest = ''; /// 01: ok
  expect('Method(s(containsKey)$rest)', mirror.function);
  Expect.isFalse(mirror.apply([7]).reflectee);
}

main() {
  testIntercepted();
  testNonIntercepted();
}
