// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.generics_special_types;

@MirrorsUsed(targets: "test.generics_special_types")
import 'dart:mirrors';
import 'package:expect/expect.dart';

main() {
  TypeMirror dynamicMirror = currentMirrorSystem().dynamicType;
  Expect.isTrue(dynamicMirror.isOriginalDeclaration);
  Expect.equals(dynamicMirror, dynamicMirror.originalDeclaration);
  Expect.listEquals([], dynamicMirror.typeVariables);
  Expect.listEquals([], dynamicMirror.typeArguments);

  TypeMirror voidMirror = currentMirrorSystem().voidType;
  Expect.isTrue(voidMirror.isOriginalDeclaration);
  Expect.equals(voidMirror, voidMirror.originalDeclaration);
  Expect.listEquals([], voidMirror.typeVariables);
  Expect.listEquals([], voidMirror.typeArguments);

  TypeMirror dynamicMirror2 = reflectType(dynamic);
  Expect.equals(dynamicMirror, dynamicMirror2);
  Expect.isTrue(dynamicMirror2.isOriginalDeclaration);
  Expect.equals(dynamicMirror2, dynamicMirror2.originalDeclaration);
  Expect.listEquals([], dynamicMirror2.typeVariables);
  Expect.listEquals([], dynamicMirror2.typeArguments);
}
