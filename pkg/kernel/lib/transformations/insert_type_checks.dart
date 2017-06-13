// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.transformations.insert_type_checks;

import '../ast.dart';
import '../class_hierarchy.dart';
import '../core_types.dart';
import '../log.dart';
import '../type_checker.dart';

/// Inserts implicit downcasts in method bodies to ensure type safety.
///
/// This does not deal with covariant override and covariant use of type
/// parameters.
///
/// Ideally this should be done when initially generating kernel IR, but this
/// is not practical at the moment.
class InsertTypeChecks {
  final CoreTypes coreTypes;
  ClassHierarchy hierarchy;

  InsertTypeChecks(this.coreTypes, this.hierarchy);

  void transformProgram(Program program) {
    new CheckInsertingTypeChecker(coreTypes, hierarchy).checkProgram(program);
  }
}

class CheckInsertingTypeChecker extends TypeChecker {
  CheckInsertingTypeChecker(CoreTypes coreTypes, ClassHierarchy hierarchy)
      : super(coreTypes, hierarchy);

  @override
  void fail(TreeNode where, String message) {
    log.severe('${where.location}: $message');
  }

  @override
  void checkAssignable(TreeNode where, DartType from, DartType to) {
    if (!environment.isSubtypeOf(from, to)) {
      fail(where, '$from cannot be assigned to $to');
    }
  }

  @override
  Expression checkAndDowncastExpression(
      Expression expression, DartType from, DartType to) {
    if (!environment.isSubtypeOf(from, to)) {
      return new AsExpression(expression, to)
        ..fileOffset = expression.fileOffset;
    } else {
      return expression;
    }
  }
}
