// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.immutable_collections;

import 'dart:mirrors';
import 'package:expect/expect.dart';

someException(e) => e is Exception || e is Error;

checkList(Iterable l, String reason) {
  Expect.throws(() => l[0] = 'value', someException, reason);
  Expect.throws(() => l.add('value'), someException, reason);
  Expect.throws(() => l.clear(), someException, reason);
}

checkMap(Map m, String reason) {
  Expect.throws(() => m[#key] = 'value', someException, reason);
  checkList(m.keys, '$reason keys');
  checkList(m.values, '$reason values');
}

checkVariable(VariableMirror vm) {
  checkList(vm.metadata, 'VariableMirror.metadata');
}

checkTypeVariable(TypeVariableMirror tvm) {
  checkList(tvm.metadata, 'TypeVariableMirror.metadata');
}

checkParameter(ParameterMirror pm) {
  checkList(pm.metadata, 'ParameterMirror.metadata');
}

checkMethod(MethodMirror mm) {
  checkList(mm.parameters, 'MethodMirror.parameters');
  checkList(mm.metadata, 'MethodMirror.metadata');

  mm.parameters.forEach(checkParameter);
}

checkClass(ClassMirror cm) {
  checkMap(cm.members, 'ClassMirror.members');
  checkMap(cm.variables, 'ClassMirror.variables');
  checkMap(cm.methods, 'ClassMirror.methods');
  checkMap(cm.getters, 'ClassMirror.getters');
  checkMap(cm.setters, 'ClassMirror.setters');
  checkMap(cm.constructors, 'ClassMirror.constructors');
  checkList(cm.metadata, 'ClassMirror.metadata');
  checkList(cm.superinterfaces, 'ClassMirror.superinterfaces');
  checkList(cm.typeArguments, 'ClassMirror.typeArguments');
  checkList(cm.typeVariables, 'ClassMirror.typeVariables');

  cm.methods.values.forEach(checkMethod);
  cm.getters.values.forEach(checkMethod);
  cm.setters.values.forEach(checkMethod);
  cm.constructors.values.forEach(checkMethod);
  cm.variables.values.forEach(checkVariable);
  cm.typeVariables.forEach(checkTypeVariable);
}

checkLibrary(LibraryMirror lm) {
  checkMap(lm.members, 'LibraryMirror.members');
  checkMap(lm.variables, 'LibraryMirror.variables');
  checkMap(lm.classes, 'LibraryMirror.classes');
  // TODO(rmacnak): Revisit after members hoisted to TypeMirror.
  // checkMap(lm.types, 'LibraryMirror.types');
  checkMap(lm.functions, 'LibraryMirror.functions');
  checkMap(lm.getters, 'LibraryMirror.getters');
  checkMap(lm.setters, 'LibraryMirror.setters');
  checkList(lm.metadata, 'LibraryMirror.metadata');

  // lm.types.forEach(checkType);
  lm.classes.values.forEach(checkClass);
  lm.functions.values.forEach(checkMethod);
  lm.getters.values.forEach(checkMethod);
  lm.setters.values.forEach(checkMethod);
  lm.variables.values.forEach(checkVariable);
}

main() {
  currentMirrorSystem().libraries.values.forEach(checkLibrary);
  // checkType(currentMirrorSystem().voidType);
  // checkType(currentMirrorSystem().dynamicType);
}
