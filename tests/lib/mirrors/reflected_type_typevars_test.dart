// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.reflected_type_type_variables;

import 'dart:mirrors';

import 'reflected_type_helper.dart';

class Class<T> {}

typedef bool Predicate<S>(S t);

main() {
  TypeVariableMirror tFromClass = reflectClass(Class).typeVariables[0];
  TypeVariableMirror sFromPredicate = reflectType(Predicate).typeVariables[0];

  expectReflectedType(tFromClass, null);
  expectReflectedType(sFromPredicate, null);
}
