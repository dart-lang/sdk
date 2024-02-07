// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'static_type_base.dart';

/// Enum values for how the target of a static type should be interpreted.
enum ClassRelation {
  /// The target is any subtype of the static type.
  subtype,

  /// The target is a subclass or mixin application of the static type.
  ///
  /// This corresponds to accessing a member through a this expression.
  thisExpression,

  /// The target is an exact instance of the static type.
  exact,
}

ClassRelation computeClassRelationFromType(ir.DartType type) {
  if (type is ThisInterfaceType) {
    return ClassRelation.thisExpression;
  } else if (type is ExactInterfaceType) {
    return ClassRelation.exact;
  } else {
    return ClassRelation.subtype;
  }
}
