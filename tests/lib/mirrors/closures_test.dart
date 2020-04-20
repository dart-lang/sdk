// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';
import 'package:expect/expect.dart';
import 'stringify.dart';

testIntercepted() {
  var instance = [];
  var closureMirror = reflect(instance.toString) as ClosureMirror;
  var methodMirror = closureMirror.function;
  Expect.equals(#toString, methodMirror.simpleName);
  Expect.equals('[]', closureMirror.apply([]).reflectee);
}

testNonIntercepted() {
  var closure = new Map().containsKey;
  var closureMirror = reflect(closure) as ClosureMirror;
  var methodMirror = closureMirror.function;
  Expect.equals(#containsKey, methodMirror.simpleName);
  Expect.isFalse(closureMirror.apply([7]).reflectee);
}

main() {
  testIntercepted();
  testNonIntercepted();
}
