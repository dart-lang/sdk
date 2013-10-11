// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensure that objects handled specially by dart2js can be reflected on.

library test.intercepted_object_test;

import 'dart:mirrors';

import 'stringify.dart' show stringify, expect;

import 'intercepted_class_test.dart' show checkClassMirror;

checkObject(object, String name) {
  checkClassMirror(reflect(object).type, name);
}

main() {
  checkObject('', 'String');
  checkObject(1, 'int');
  checkObject(1.5, 'double');
  checkObject(true, 'bool');
  checkObject(false, 'bool');
  checkObject([], 'List');
}
