// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library type_mask_test_helper;

import 'package:compiler/src/types/types.dart';
import 'package:compiler/src/dart2jslib.dart'
    show Compiler;

TypeMask simplify(TypeMask mask, Compiler compiler) {
  if (mask is ForwardingTypeMask) {
    return simplify(mask.forwardTo, compiler);
  } else if (mask is UnionTypeMask) {
    return UnionTypeMask.flatten(mask.disjointMasks, compiler.world);
  } else {
    return mask;
  }
}