// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Helper for checking potentially nullable dereferences.
class NullableDereferenceVerifier {
  final TypeSystemImpl _typeSystem;
  final DiagnosticReporter _diagnosticReporter;

  /// The resolver driving this participant.
  final ResolverVisitor _resolver;

  NullableDereferenceVerifier({
    required TypeSystemImpl typeSystem,
    required DiagnosticReporter diagnosticReporter,
    required ResolverVisitor resolver,
  }) : _typeSystem = typeSystem,
       _diagnosticReporter = diagnosticReporter,
       _resolver = resolver;

  bool expression(
    LocatableDiagnostic locatableDiagnostic,
    Expression expression, {
    DartType? type,
  }) {
    type ??= expression.typeOrThrow;
    return _check(locatableDiagnostic, expression, type);
  }

  void report(
    LocatableDiagnostic locatableDiagnostic,
    SyntacticEntity errorEntity,
    DartType receiverType, {
    List<DiagnosticMessage> messages = const [],
  }) {
    if (receiverType == _typeSystem.typeProvider.nullType) {
      locatableDiagnostic = diag.invalidUseOfNullValue;
    }
    _diagnosticReporter.report(
      locatableDiagnostic.withContextMessages(messages).at(errorEntity),
    );
  }

  /// If the [receiverType] is potentially nullable, report it.
  ///
  /// The [errorNode] is usually the receiver of the invocation, but if the
  /// receiver is the implicit `this`, the name of the invocation.
  ///
  /// Returns whether [receiverType] was reported.
  bool _check(
    LocatableDiagnostic locatableDiagnostic,
    AstNode errorNode,
    DartType receiverType,
  ) {
    if (receiverType is DynamicType ||
        receiverType is InvalidType ||
        !_typeSystem.isPotentiallyNullable(receiverType)) {
      return false;
    }

    List<DiagnosticMessage> messages = const [];
    if (errorNode is ExpressionImpl) {
      messages = _resolver.computeWhyNotPromotedMessages(
        errorNode,
        _resolver.flowAnalysis.flow?.whyNotPromoted(
          _resolver.flowAnalysis.flow?.getExpressionInfo(errorNode),
        )(),
      );
    }
    report(locatableDiagnostic, errorNode, receiverType, messages: messages);
    return true;
  }
}
