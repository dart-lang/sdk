// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library type_mask_test_helper;

import 'package:compiler/src/inferrer/typemasks/masks.dart';
import 'package:compiler/src/world.dart' show JClosedWorld;

export 'package:compiler/src/inferrer/types.dart';

TypeMask simplify(TypeMask mask, JClosedWorld closedWorld) {
  if (mask is ForwardingTypeMask) {
    return simplify(mask.forwardTo, closedWorld);
  } else if (mask is UnionTypeMask) {
    return UnionTypeMask.flatten(
        mask.disjointMasks, mask.isNullable, closedWorld);
  } else {
    return mask;
  }
}

TypeMask interceptorOrComparable(JClosedWorld closedWorld,
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
