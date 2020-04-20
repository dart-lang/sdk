// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.immutable_collections;

import 'dart:mirrors';
import 'package:expect/expect.dart';

bool someException(e) => e is Exception || e is Error;

checkList(dynamic l, String reason) {
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
  checkMap(cm.declarations, 'ClassMirror.declarations');
  checkMap(cm.instanceMembers, 'ClassMirror.instanceMembers');
  checkMap(cm.staticMembers, 'ClassMirror.staticMembers');
  checkList(cm.metadata, 'ClassMirror.metadata');
  checkList(cm.superinterfaces, 'ClassMirror.superinterfaces');
  checkList(cm.typeArguments, 'ClassMirror.typeArguments');
  checkList(cm.typeVariables, 'ClassMirror.typeVariables');

  cm.declarations.values.forEach(checkDeclaration);
  cm.instanceMembers.values.forEach(checkDeclaration);
  cm.staticMembers.values.forEach(checkDeclaration);
  cm.typeVariables.forEach(checkTypeVariable);
}

checkType(TypeMirror tm) {
  checkList(tm.metadata, 'TypeMirror.metadata');
}

checkDeclaration(DeclarationMirror dm) {
  if (dm is MethodMirror) checkMethod(dm);
  if (dm is ClassMirror) checkClass(dm);
  if (dm is TypeMirror) checkType(dm);
  if (dm is VariableMirror) checkVariable(dm);
  if (dm is TypeVariableMirror) checkTypeVariable(dm);
}

checkLibrary(LibraryMirror lm) {
  checkMap(lm.declarations, 'LibraryMirror.declarations');
  checkList(lm.metadata, 'LibraryMirror.metadata');

  lm.declarations.values.forEach(checkDeclaration);
}

main() {
  currentMirrorSystem().libraries.values.forEach(checkLibrary);
  checkType(currentMirrorSystem().voidType);
  checkType(currentMirrorSystem().dynamicType);
}
