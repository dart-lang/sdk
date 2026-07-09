// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:expect/expect.dart';

class Class {
  var instanceNonConst = 2;
  static const staticConst = 3;
  static var staticNonConst = 4;
}

const topLevelConst = 5;
var topLevelNonConst = 6;

void main() {
  bool isConst(Map<Symbol, DeclarationMirror> m, Symbol s) =>
      (m[s] as VariableMirror).isConst;

  ClassMirror cm = reflectClass(Class);
  Map<Symbol, DeclarationMirror> cd = cm.declarations;
  Expect.isFalse(isConst(cd, #instanceNonConst));
  Expect.isTrue(isConst(cd, #staticConst));
  Expect.isFalse(isConst(cd, #staticNonConst));

  Map<Symbol, DeclarationMirror> ld = (cm.owner as LibraryMirror).declarations;
  Expect.isTrue(isConst(ld, #topLevelConst));
  Expect.isFalse(isConst(ld, #topLevelNonConst));
}
