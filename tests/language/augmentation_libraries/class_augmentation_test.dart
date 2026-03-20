// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=macros

import 'package:expect/expect.dart';

import augment 'class_augmentation.dart';

void main() {
  var a = A();
  dynamic dynamicA = a;

  Expect.listEquals(a.ints, [1, 2, 3]);
  Expect.equals(a.funcWithoutBody(), 'ab');

  Expect.equals(a.getterWithoutBody, 'a');
  a.setterWithoutBody = 'x';
  Expect.equals(a.getterWithoutBody, 'x');

  Expect.equals(dynamicA.newFunction(), 'new');
}

class A {
  String _value = 'a';

  List<int> get ints;
  String funcWithoutBody();
  String get getterWithoutBody;
  set setterWithoutBody(String value);
}
