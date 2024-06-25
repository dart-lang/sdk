// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Handling of static weak references.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;

import '../codes/cfe_codes.dart'
    show
        messageWeakReferenceNotStatic,
        messageWeakReferenceNotOneArgument,
        messageWeakReferenceReturnTypeNotNullable,
        messageWeakReferenceMismatchReturnAndArgumentTypes,
        messageWeakReferenceTargetNotStaticTearoff,
        messageWeakReferenceTargetHasParameters;
import 'constant_evaluator.dart' show ErrorReporter;

/// Recognizes and validates static weak references.
/// Intrinsic method for static weak references can be
/// declared using `@pragma('weak-tearoff-reference')`.
class StaticWeakReferences {
  static const String weakTearoffReferencePragma = 'weak-tearoff-reference';

  static bool isWeakReference(StaticInvocation node) =>
      node.target.hasWeakTearoffReferencePragma;

  static bool isAnnotatedWithWeakReferencePragma(
      Annotatable node, CoreTypes coreTypes) {
    for (Expression annotation in node.annotations) {
      if (annotation is ConstantExpression) {
        Constant constant = annotation.constant;
        if (constant is InstanceConstant) {
          if (constant.classNode == coreTypes.pragmaClass) {
            Constant? name =
                constant.fieldValues[coreTypes.pragmaName.fieldReference];
            if (name is StringConstant) {
              if (name.value == weakTearoffReferencePragma) {
                return true;
              }
            }
          }
        }
      }
    }
    return false;
  }

  static void validateWeakReferenceUse(
      StaticInvocation node, ErrorReporter errorReporter) {
    final Arguments arguments = node.arguments;
    if (arguments.positional.length != 1 || arguments.named.isNotEmpty) {
      errorReporter.report(messageWeakReferenceNotOneArgument.withLocation(
          node.location!.file, node.fileOffset, 1));
      return;
    }
    final Expression arg = arguments.positional.single;
    if (arg is ConstantExpression) {
      final Constant constant = arg.constant;
      if (constant is StaticTearOffConstant) {
        final Procedure target = constant.target;
        if (target.isStatic) {
          final FunctionNode function = target.function;
          if (function.positionalParameters.isNotEmpty ||
              function.namedParameters.isNotEmpty ||
              function.typeParameters.isNotEmpty) {
            errorReporter.report(messageWeakReferenceTargetHasParameters
                .withLocation(node.location!.file, node.fileOffset, 1));
          }
          return;
        }
      }
    }
    errorReporter.report(messageWeakReferenceTargetNotStaticTearoff
        .withLocation(node.location!.file, node.fileOffset, 1));
  }

  static void validateWeakReferenceDeclaration(
      Annotatable node, ErrorReporter errorReporter) {
    if (node is! Procedure ||
        !node.isStatic ||
        node.kind != ProcedureKind.Method) {
      errorReporter.report(messageWeakReferenceNotStatic.withLocation(
          node.location!.file, node.fileOffset, 1));
      return;
    }
    final FunctionNode function = node.function;
    if (function.positionalParameters.length != 1 ||
        function.requiredParameterCount != 1 ||
        function.namedParameters.isNotEmpty) {
      errorReporter.report(messageWeakReferenceNotOneArgument.withLocation(
          node.location!.file, node.fileOffset, 1));
      return;
    }
    final DartType returnType = function.returnType;
    if (returnType.nullability != Nullability.nullable) {
      errorReporter.report(messageWeakReferenceReturnTypeNotNullable
          .withLocation(node.location!.file, node.fileOffset, 1));
    }
    if (returnType != function.positionalParameters.single.type) {
      errorReporter.report(messageWeakReferenceMismatchReturnAndArgumentTypes
          .withLocation(node.location!.file, node.fileOffset, 1));
    }
    node.hasWeakTearoffReferencePragma = true;
  }

  // Returns argument expression of the weak reference.
  // Assumes weak reference is valid.
  static Expression getWeakReferenceArgument(StaticInvocation node) {
    assert(isWeakReference(node));
    return node.arguments.positional.single;
  }

  // Returns target method of the weak reference.
  // Assumes weak reference is valid.
  static Procedure getWeakReferenceTarget(StaticInvocation node) {
    final Expression arg = getWeakReferenceArgument(node);
    return ((arg as ConstantExpression).constant as StaticTearOffConstant)
        .target;
  }
}
