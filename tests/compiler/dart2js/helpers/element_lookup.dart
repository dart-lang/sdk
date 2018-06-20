// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/common_elements.dart' show ElementEnvironment;
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/world.dart' show JClosedWorld;

ClassEntity findClass(JClosedWorld closedWorld, String name) {
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
  ClassEntity cls =
      elementEnvironment.lookupClass(elementEnvironment.mainLibrary, name);
  cls ??= elementEnvironment.lookupClass(
      closedWorld.commonElements.coreLibrary, name);
  cls ??= elementEnvironment.lookupClass(
      closedWorld.commonElements.interceptorsLibrary, name);
  cls ??= elementEnvironment.lookupClass(
      closedWorld.commonElements.jsHelperLibrary, name);
  assert(cls != null, "Class '$name' not found.");
  return cls;
}

MemberEntity findClassMember(
    JClosedWorld closedWorld, String className, String memberName,
    {bool required: true}) {
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
  ClassEntity cls = findClass(closedWorld, className);
  assert(cls != null, "Class '$className' not found.");
  MemberEntity member = elementEnvironment.lookupClassMember(cls, memberName);
  assert(
      !required || member != null, "Member '$memberName' not found in $cls.");
  return member;
}

MemberEntity findMember(JClosedWorld closedWorld, String name) {
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
  MemberEntity member = elementEnvironment.lookupLibraryMember(
      elementEnvironment.mainLibrary, name);
  member ??= elementEnvironment.lookupLibraryMember(
      closedWorld.commonElements.coreLibrary, name);
  assert(member != null, "Member '$name' not found.");
  return member;
}

FunctionType findFunctionType(JClosedWorld closedWorld, String name) {
  FunctionEntity function = findMember(closedWorld, name);
  return closedWorld.elementEnvironment.getFunctionType(function);
}

DartType findFieldType(JClosedWorld closedWorld, String name) {
  FieldEntity field = findMember(closedWorld, name);
  return closedWorld.elementEnvironment.getFieldType(field);
}
