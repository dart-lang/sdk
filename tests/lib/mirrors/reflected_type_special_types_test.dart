// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.reflected_type_special_types;

import 'dart:mirrors';

import 'reflected_type_helper.dart';

main() {
  TypeMirror dynamicMirror = currentMirrorSystem().dynamicType;
  TypeMirror dynamicMirror2 = reflectType(dynamic);
  TypeMirror voidMirror = currentMirrorSystem().voidType;

  expectReflectedType(dynamicMirror, dynamic);
  expectReflectedType(dynamicMirror2, dynamic);
  expectReflectedType(voidMirror, null);
}
