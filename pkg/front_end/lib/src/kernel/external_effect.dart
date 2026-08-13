// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:front_end/src/api_prototype/constant_evaluator.dart';
import 'package:front_end/src/kernel/utils.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';

class ExternalEffect {
  static const String pragmaName = 'external-effect';

  // Coverage-ignore(suite): Not run.
  static bool isExternalEffect(StaticInvocation node) {
    return node.target.hasExternalEffectPragma;
  }

  static bool isOutlineAnnotatedWithExternalEffect(
    Annotatable node,
    CoreTypes coreTypes,
  ) {
    return isOutlineAnnotatedWithPragma(node, coreTypes, pragmaName);
  }

  static bool isAnnotatedWithExternalEffect(
    Annotatable node,
    CoreTypes coreTypes,
  ) {
    return isAnnotatedWithPragma(node, coreTypes, pragmaName);
  }

  static void validatePragma(
    Annotatable node,
    CoreTypes coreTypes,
    ErrorReporter errorReporter, {
    required bool checkHasFlag,
  }) {
    if (node is! Procedure || node.kind != ProcedureKind.Method) {
      errorReporter.report(
        diag.dartExternalEffectNotMethod.withLocation(
          node.location!.file,
          node.fileOffset,
          1,
        ),
      );
      return;
    }

    if (node.isInstanceMember) {
      errorReporter.report(
        diag.dartExternalEffectNotStatic.withLocation(
          node.location!.file,
          node.fileOffset,
          1,
        ),
      );
      return;
    }

    if (!node.isExternal) {
      errorReporter.report(
        diag.dartExternalEffectNotExternal.withLocation(
          node.location!.file,
          node.fileOffset,
          1,
        ),
      );
      return;
    }

    FunctionNode function = node.function;

    if (function.computeFunctionType(Nullability.nonNullable) !=
        new FunctionType(
          [coreTypes.objectNullableRawType],
          const VoidType(),
          Nullability.nonNullable,
        )) {
      errorReporter.report(
        diag.dartExternalEffectIncorrectType.withLocation(
          node.location!.file,
          node.fileOffset,
          1,
        ),
      );
      return;
    }

    if (checkHasFlag && !node.hasExternalEffectPragma) {
      errorReporter.report(
        diag.dartExternalEffectMalformedPragma.withLocation(
          node.location!.file,
          node.fileOffset,
          1,
        ),
      );
    }
    node.hasExternalEffectPragma = true;
  }
}
