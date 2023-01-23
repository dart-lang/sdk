// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/common/elements.dart' show JElementEnvironment;
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/names.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/js_model/js_world.dart' show JClosedWorld;

ClassEntity findClass(JClosedWorld closedWorld, String name) {
  JElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
  ClassEntity? cls =
      elementEnvironment.lookupClass(elementEnvironment.mainLibrary!, name);
  cls ??= elementEnvironment.lookupClass(
      closedWorld.commonElements.coreLibrary, name);
  cls ??= elementEnvironment.lookupClass(
      closedWorld.commonElements.interceptorsLibrary!, name);
  cls ??= elementEnvironment.lookupClass(
      closedWorld.commonElements.jsHelperLibrary!, name);
  if (cls == null) {
    for (LibraryEntity library in elementEnvironment.libraries) {
      if (!library.canonicalUri.isScheme('dart') &&
          !library.canonicalUri.isScheme('package')) {
        cls = elementEnvironment.lookupClass(library, name);
        if (cls != null) {
          break;
        }
      }
    }
  }
  return cls!;
}

MemberEntity findClassMember(
    JClosedWorld closedWorld, String className, String memberName) {
  return findClassMemberOrNull(closedWorld, className, memberName)!;
}

MemberEntity? findClassMemberOrNull(
    JClosedWorld closedWorld, String className, String memberName) {
  bool isSetter = false;
  if (memberName.endsWith('=')) {
    memberName = memberName.substring(0, memberName.length - 1);
    isSetter = true;
  }
  JElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
  ClassEntity cls = findClass(closedWorld, className);
  MemberEntity? member = elementEnvironment.lookupClassMember(
      cls, Name(memberName, cls.library.canonicalUri, isSetter: isSetter));
  if (member == null && !isSetter) {
    member = elementEnvironment.lookupConstructor(cls, memberName);
  }
  return member;
}

MemberEntity findMember(JClosedWorld closedWorld, String name) {
  bool isSetter = false;
  if (name.endsWith('=')) {
    name = name.substring(0, name.length - 1);
    isSetter = true;
  }
  JElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
  MemberEntity? member = elementEnvironment.lookupLibraryMember(
      elementEnvironment.mainLibrary!, name,
      setter: isSetter);
  member ??= elementEnvironment.lookupLibraryMember(
      closedWorld.commonElements.coreLibrary, name,
      setter: isSetter);
  if (member == null) {
    for (LibraryEntity library in elementEnvironment.libraries) {
      if (!library.canonicalUri.isScheme('dart') &&
          !library.canonicalUri.isScheme('package')) {
        member = elementEnvironment.lookupLibraryMember(library, name,
            setter: isSetter);
        if (member != null) {
          break;
        }
      }
    }
  }
  return member!;
}

FunctionType findFunctionType(JClosedWorld closedWorld, String name) {
  final function = findMember(closedWorld, name) as FunctionEntity;
  return closedWorld.elementEnvironment.getFunctionType(function);
}

DartType findFieldType(JClosedWorld closedWorld, String name) {
  final field = findMember(closedWorld, name) as FieldEntity;
  return closedWorld.elementEnvironment.getFieldType(field);
}
