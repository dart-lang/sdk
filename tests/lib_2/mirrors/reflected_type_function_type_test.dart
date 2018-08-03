// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.reflected_type_function_types;

import 'dart:mirrors';

import 'reflected_type_helper.dart';

typedef bool Predicate(num n);

bool somePredicate(num n) => n < 0;

main() {
  FunctionTypeMirror numToBool1 = reflect(somePredicate).type;
  FunctionTypeMirror numToBool2 =
      (reflectType(Predicate) as TypedefMirror).referent;

  expectReflectedType(numToBool1, somePredicate.runtimeType);
  expectReflectedType(numToBool2, Predicate);
}
