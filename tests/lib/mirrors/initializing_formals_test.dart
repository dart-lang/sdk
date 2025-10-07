// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';
import 'package:expect/expect.dart';

class Class<T> {
  late num numField;
  late bool boolField;
  late String stringField;
  late T tField;
  late dynamic _privateField;

  Class.nongeneric(this.numField);
  Class.named({this.boolField = false});
  Class.optPos([this.stringField = 'default']);
  Class.generic(this.tField);
  Class.private(this._privateField);

  Class.explicitType(num this.numField);
  Class.withVar(var this.numField);
  Class.withSubtype(int this.numField);
}

class Constant {
  final num value;
  const Constant(this.value);
  const Constant.marked(final this.value);
}

void main() {
  MethodMirror mm;
  ParameterMirror pm;

  mm = reflectClass(Class).declarations[#Class.nongeneric] as MethodMirror;
  pm = mm.parameters.single;
  Expect.equals(#numField, pm.simpleName);
  Expect.equals(reflectClass(num), pm.type);
  Expect.isFalse(pm.isNamed);
  Expect.isFalse(pm.isFinal);
  Expect.isFalse(pm.isOptional);
  Expect.isFalse(pm.hasDefaultValue);
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);

  mm = reflectClass(Class).declarations[#Class.named] as MethodMirror;
  pm = mm.parameters.single;
  Expect.equals(#boolField, pm.simpleName);
  Expect.equals(reflectClass(bool), pm.type);
  Expect.isTrue(pm.isNamed);
  Expect.isFalse(pm.isFinal);
  Expect.isTrue(pm.isOptional);
  Expect.isTrue(pm.hasDefaultValue);
  Expect.equals(false, pm.defaultValue!.reflectee);
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);

  mm = reflectClass(Class).declarations[#Class.optPos] as MethodMirror;
  pm = mm.parameters.single;
  Expect.equals(#stringField, pm.simpleName);
  Expect.equals(reflectClass(String), pm.type);
  Expect.isFalse(pm.isNamed);
  Expect.isFalse(pm.isFinal);
  Expect.isTrue(pm.isOptional);
  Expect.isTrue(pm.hasDefaultValue);
  Expect.equals('default', pm.defaultValue!.reflectee);
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);

  mm = reflectClass(Class).declarations[#Class.generic] as MethodMirror;
  pm = mm.parameters.single;
  Expect.equals(#tField, pm.simpleName);
  Expect.equals(reflectClass(Class).typeVariables.single, pm.type);
  Expect.isFalse(pm.isNamed);
  Expect.isFalse(pm.isFinal);
  Expect.isFalse(pm.isOptional);
  Expect.isFalse(pm.hasDefaultValue);
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);

  mm = reflectClass(Class).declarations[#Class.private] as MethodMirror;
  pm = mm.parameters.single;
  Expect.equals(#_privateField, pm.simpleName);
  Expect.equals(currentMirrorSystem().dynamicType, pm.type);
  Expect.isFalse(pm.isNamed);
  Expect.isFalse(pm.isFinal);
  Expect.isFalse(pm.isOptional);
  Expect.isFalse(pm.hasDefaultValue);
  Expect.isTrue(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);

  mm = reflectClass(Class).declarations[#Class.explicitType] as MethodMirror;
  pm = mm.parameters.single;
  Expect.equals(#numField, pm.simpleName);
  Expect.equals(reflectClass(num), pm.type);
  Expect.isFalse(pm.isNamed);
  Expect.isFalse(pm.isFinal);
  Expect.isFalse(pm.isOptional);
  Expect.isFalse(pm.hasDefaultValue);
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);

  mm = reflectClass(Class).declarations[#Class.withVar] as MethodMirror;
  pm = mm.parameters.single;
  Expect.equals(#numField, pm.simpleName);
  Expect.equals(reflectClass(num), pm.type);
  Expect.isFalse(pm.isNamed);
  Expect.isFalse(pm.isFinal);
  Expect.isFalse(pm.isOptional);
  Expect.isFalse(pm.hasDefaultValue);
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);

  mm = reflectClass(Class).declarations[#Class.withSubtype] as MethodMirror;
  pm = mm.parameters.single;
  Expect.equals(#numField, pm.simpleName);
  Expect.equals(reflectClass(int), pm.type);
  Expect.isFalse(pm.isNamed);
  Expect.isFalse(pm.isFinal);
  Expect.isFalse(pm.isOptional);
  Expect.isFalse(pm.hasDefaultValue);
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);

  mm = reflectClass(Constant).declarations[#Constant] as MethodMirror;
  pm = mm.parameters.single;
  Expect.equals(#value, pm.simpleName);
  Expect.equals(reflectClass(num), pm.type);
  Expect.isFalse(pm.isNamed);
  Expect.isFalse(pm.isFinal); // N.B.
  Expect.isFalse(pm.isOptional);
  Expect.isFalse(pm.hasDefaultValue);
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);

  mm = reflectClass(Constant).declarations[#Constant.marked] as MethodMirror;
  pm = mm.parameters.single;
  Expect.equals(#value, pm.simpleName);
  Expect.equals(reflectClass(num), pm.type);
  Expect.isFalse(pm.isNamed);
  Expect.isTrue(pm.isFinal); // N.B.
  Expect.isFalse(pm.isOptional);
  Expect.isFalse(pm.hasDefaultValue);
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);
}
