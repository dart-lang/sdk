// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Handling of static weak references.

import 'package:front_end/src/api_unstable/vm.dart'
    show
        messageWeakReferenceNotStatic,
        messageWeakReferenceNotOneArgument,
        messageWeakReferenceReturnTypeNotNullable,
        messageWeakReferenceMismatchReturnAndArgumentTypes,
        messageWeakReferenceTargetNotStaticTearoff,
        messageWeakReferenceTargetHasParameters;
import 'package:kernel/ast.dart';
import 'package:kernel/target/targets.dart' show DiagnosticReporter;
import 'package:vm/transformations/pragma.dart'
    show ParsedWeakTearoffReference, PragmaAnnotationParser;

/// Recognizes and validates static weak references.
class StaticWeakReferences {
  final PragmaAnnotationParser _annotationParser;

  StaticWeakReferences(this._annotationParser);

  bool isWeakReference(StaticInvocation node) =>
      _isAnnotatedWithWeakReferencePragma(node.target);

  bool isWeakReferenceDeclaration(Member node) =>
      _isAnnotatedWithWeakReferencePragma(node);

  bool _isAnnotatedWithWeakReferencePragma(Member m) {
    for (final annotation in m.annotations) {
      if (_annotationParser.parsePragma(annotation)
          is ParsedWeakTearoffReference) {
        return true;
      }
    }
    return false;
  }

  void validateWeakReference(
      StaticInvocation node, DiagnosticReporter diagnosticReporter) {
    assert(isWeakReference(node));

    final arguments = node.arguments;
    if (arguments.positional.length != 1 || arguments.named.isNotEmpty) {
      diagnosticReporter.report(messageWeakReferenceNotOneArgument,
          node.fileOffset, 1, node.location?.file);
      return;
    }
    final arg = arguments.positional.single;
    if (arg is ConstantExpression) {
      final constant = arg.constant;
      if (constant is StaticTearOffConstant) {
        final target = constant.target;
        if (target.isStatic) {
          final function = target.function;
          if (function.positionalParameters.isNotEmpty ||
              function.namedParameters.isNotEmpty ||
              function.typeParameters.isNotEmpty) {
            diagnosticReporter.report(messageWeakReferenceTargetHasParameters,
                node.fileOffset, 1, node.location?.file);
          }
          return;
        }
      }
    }
    diagnosticReporter.report(messageWeakReferenceTargetNotStaticTearoff,
        node.fileOffset, 1, node.location?.file);
  }

  void validateWeakReferenceDeclaration(
      Member node, DiagnosticReporter diagnosticReporter) {
    assert(isWeakReferenceDeclaration(node));

    if (node is! Procedure ||
        !node.isStatic ||
        node.kind != ProcedureKind.Method) {
      diagnosticReporter.report(messageWeakReferenceNotStatic, node.fileOffset,
          1, node.location?.file);
      return;
    }
    final function = node.function;
    if (function.positionalParameters.length != 1 ||
        function.requiredParameterCount != 1 ||
        function.namedParameters.isNotEmpty) {
      diagnosticReporter.report(messageWeakReferenceNotOneArgument,
          node.fileOffset, 1, node.location?.file);
      return;
    }
    final returnType = function.returnType;
    if (returnType.nullability != Nullability.nullable) {
      diagnosticReporter.report(messageWeakReferenceReturnTypeNotNullable,
          node.fileOffset, 1, node.location?.file);
    }
    if (returnType != function.positionalParameters.single.type) {
      diagnosticReporter.report(
          messageWeakReferenceMismatchReturnAndArgumentTypes,
          node.fileOffset,
          1,
          node.location?.file);
    }
  }

  // Returns argument expression of the weak reference.
  // Assumes weak reference is valid.
  Expression getWeakReferenceArgument(StaticInvocation node) {
    assert(isWeakReference(node));
    return node.arguments.positional.single;
  }

  // Returns target method of the weak reference.
  // Assumes weak reference is valid.
  Procedure getWeakReferenceTarget(StaticInvocation node) {
    final arg = getWeakReferenceArgument(node);
    return ((arg as ConstantExpression).constant as StaticTearOffConstant)
        .target;
  }
}
