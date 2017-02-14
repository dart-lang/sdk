// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_mask_test_helper;

import 'package:compiler/src/types/types.dart';
import 'package:compiler/src/world.dart' show ClosedWorld;

TypeMask simplify(TypeMask mask, ClosedWorld closedWorld) {
  if (mask is ForwardingTypeMask) {
    return simplify(mask.forwardTo, closedWorld);
  } else if (mask is UnionTypeMask) {
    return UnionTypeMask.flatten(mask.disjointMasks, closedWorld);
  } else {
    return mask;
  }
}
