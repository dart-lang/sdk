// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.initializing_formals;

import 'dart:mirrors';
import 'package:expect/expect.dart';

class Class<T> {
  int intField;
  bool boolField;
  String stringField;
  T tField;
  dynamic _privateField;

  Class.nongeneric(this.intField);
  Class.named({this.boolField});
  Class.optPos([this.stringField = 'default']);
  Class.generic(this.tField);
  Class.private(this._privateField);
}

class Constant {
  final value;
  const Constant(this.value);
  const Constant.marked(final this.value);
}

main() {
  ParameterMirror pm;

  pm = reflectClass(Class).constructors[#Class.nongeneric].parameters.single;
  Expect.equals(#intField, pm.simpleName);
  Expect.equals(reflectClass(int), pm.type);  /// 01: ok
  Expect.isFalse(pm.isNamed);
  Expect.isFalse(pm.isFinal);
  Expect.isFalse(pm.isOptional);
  Expect.isFalse(pm.hasDefaultValue);
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);
  
  pm = reflectClass(Class).constructors[#Class.named].parameters.single;
  Expect.equals(#boolField, pm.simpleName);
  Expect.equals(reflectClass(bool), pm.type);  /// 01: ok
  Expect.isTrue(pm.isNamed);
  Expect.isFalse(pm.isFinal);
  Expect.isTrue(pm.isOptional);
  Expect.isFalse(pm.hasDefaultValue);
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);
  
  pm = reflectClass(Class).constructors[#Class.optPos].parameters.single;
  Expect.equals(#stringField, pm.simpleName);
  Expect.equals(reflectClass(String), pm.type);  /// 01: ok
  Expect.isFalse(pm.isNamed);
  Expect.isFalse(pm.isFinal);
  Expect.isTrue(pm.isOptional);
  Expect.isTrue(pm.hasDefaultValue);
  Expect.equals('default', pm.defaultValue.reflectee);
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);
  
  pm = reflectClass(Class).constructors[#Class.generic].parameters.single;
  Expect.equals(#tField, pm.simpleName);
  Expect.equals(reflectClass(Class).typeVariables.single, pm.type);  /// 01: ok
  Expect.isFalse(pm.isNamed);
  Expect.isFalse(pm.isFinal);
  Expect.isFalse(pm.isOptional);
  Expect.isFalse(pm.hasDefaultValue);
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);

  pm = reflectClass(Class).constructors[#Class.private].parameters.single;
  Expect.equals(#_privateField, pm.simpleName);
  Expect.equals(currentMirrorSystem().dynamicType, pm.type);
  Expect.isFalse(pm.isNamed);
  Expect.isFalse(pm.isFinal);
  Expect.isFalse(pm.isOptional);
  Expect.isFalse(pm.hasDefaultValue);
  Expect.isTrue(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);

  pm = reflectClass(Constant).constructors[#Constant].parameters.single;
  Expect.equals(#value, pm.simpleName);
  Expect.equals(currentMirrorSystem().dynamicType, pm.type);
  Expect.isFalse(pm.isNamed);
  Expect.isFalse(pm.isFinal);  // N.B.
  Expect.isFalse(pm.isOptional);
  Expect.isFalse(pm.hasDefaultValue);
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);

  pm = reflectClass(Constant).constructors[#Constant.marked].parameters.single;
  Expect.equals(#value, pm.simpleName);
  Expect.equals(currentMirrorSystem().dynamicType, pm.type);
  Expect.isFalse(pm.isNamed);
  Expect.isTrue(pm.isFinal);  // N.B.
  Expect.isFalse(pm.isOptional);
  Expect.isFalse(pm.hasDefaultValue);
  Expect.isFalse(pm.isPrivate);
  Expect.isFalse(pm.isStatic);
  Expect.isFalse(pm.isTopLevel);
}
