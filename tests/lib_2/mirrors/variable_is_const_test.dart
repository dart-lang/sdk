// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.variable_is_const;

@MirrorsUsed(targets: "test.variable_is_const")
import 'dart:mirrors';

import 'package:expect/expect.dart';

class Class {
  const //# 01: compile-time error
      int instanceWouldBeConst = 1;
  var instanceNonConst = 2;

  static const staticConst = 3;
  static var staticNonConst = 4;
}

const topLevelConst = 5;
var topLevelNonConst = 6;

main() {
  bool isConst(m, Symbol s) => (m.declarations[s] as VariableMirror).isConst;

  ClassMirror cm = reflectClass(Class);
  Expect.isFalse(isConst(cm, #instanceWouldBeConst));
  Expect.isFalse(isConst(cm, #instanceNonConst));
  Expect.isTrue(isConst(cm, #staticConst));
  Expect.isFalse(isConst(cm, #staticNonConst));

  LibraryMirror lm = cm.owner;
  Expect.isTrue(isConst(lm, #topLevelConst));
  Expect.isFalse(isConst(lm, #topLevelNonConst));
}
