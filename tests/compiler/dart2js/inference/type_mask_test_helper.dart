// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_mask_test_helper;

import 'package:compiler/src/common_elements.dart' show ElementEnvironment;
import 'package:compiler/src/elements/entities.dart'
    show ClassEntity, MemberEntity;
import 'package:compiler/src/types/types.dart';
import 'package:compiler/src/world.dart' show ClosedWorld;

export 'package:compiler/src/types/types.dart';

TypeMask simplify(TypeMask mask, ClosedWorld closedWorld) {
  if (mask is ForwardingTypeMask) {
    return simplify(mask.forwardTo, closedWorld);
  } else if (mask is UnionTypeMask) {
    return UnionTypeMask.flatten(mask.disjointMasks, closedWorld);
  } else {
    return mask;
  }
}

TypeMask interceptorOrComparable(ClosedWorld closedWorld,
    {bool nullable: false}) {
  // TODO(johnniwinther): The mock libraries are missing 'Comparable' and
  // therefore consider the union of for instance 'String' and 'num' to be
  // 'Interceptor' and not 'Comparable'. Maybe the union mask should be changed
  // to favor 'Interceptor' when flattening.
  if (nullable) {
    return new TypeMask.subtype(
        closedWorld.elementEnvironment
            .lookupClass(closedWorld.commonElements.coreLibrary, 'Comparable'),
        closedWorld);
  } else {
    return new TypeMask.nonNullSubtype(
        closedWorld.elementEnvironment
            .lookupClass(closedWorld.commonElements.coreLibrary, 'Comparable'),
        closedWorld);
  }
}

ClassEntity findClass(ClosedWorld closedWorld, String name) {
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
  ClassEntity cls =
      elementEnvironment.lookupClass(elementEnvironment.mainLibrary, name);
  assert(cls != null, "Class '$name' not found.");
  return cls;
}

MemberEntity findClassMember(
    ClosedWorld closedWorld, String className, String memberName) {
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
  ClassEntity cls =
      elementEnvironment.lookupClass(elementEnvironment.mainLibrary, className);
  assert(cls != null, "Class '$className' not found.");
  MemberEntity member = elementEnvironment.lookupClassMember(cls, memberName);
  assert(member != null, "Member '$memberName' not found in $cls.");
  return member;
}

MemberEntity findMember(ClosedWorld closedWorld, String name) {
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
  MemberEntity member = elementEnvironment.lookupLibraryMember(
      elementEnvironment.mainLibrary, name);
  assert(member != null, "Member '$name' not found.");
  return member;
}
