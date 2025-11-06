// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';
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
    DiagnosticCode diagnosticCode,
    Expression expression, {
    DartType? type,
  }) {
    type ??= expression.typeOrThrow;
    return _check(diagnosticCode, expression, type);
  }

  void report(
    DiagnosticCode diagnosticCode,
    SyntacticEntity errorEntity,
    DartType receiverType, {
    List<String> arguments = const <String>[],
    List<DiagnosticMessage>? messages,
  }) {
    if (receiverType == _typeSystem.typeProvider.nullType) {
      diagnosticCode = CompileTimeErrorCode.invalidUseOfNullValue;
      arguments = [];
    }
    if (errorEntity is AstNode) {
      _diagnosticReporter.atNode(
        errorEntity,
        diagnosticCode,
        arguments: arguments,
        contextMessages: messages,
      );
    } else if (errorEntity is Token) {
      _diagnosticReporter.atToken(
        errorEntity,
        diagnosticCode,
        arguments: arguments,
        contextMessages: messages,
      );
    } else {
      throw StateError('Syntactic entity must be AstNode or Token to report.');
    }
  }

  /// If the [receiverType] is potentially nullable, report it.
  ///
  /// The [errorNode] is usually the receiver of the invocation, but if the
  /// receiver is the implicit `this`, the name of the invocation.
  ///
  /// Returns whether [receiverType] was reported.
  bool _check(
    DiagnosticCode diagnosticCode,
    AstNode errorNode,
    DartType receiverType,
  ) {
    if (receiverType is DynamicType ||
        receiverType is InvalidType ||
        !_typeSystem.isPotentiallyNullable(receiverType)) {
      return false;
    }

    List<DiagnosticMessage>? messages;
    if (errorNode is ExpressionImpl) {
      messages = _resolver.computeWhyNotPromotedMessages(
        errorNode,
        _resolver.flowAnalysis.flow?.whyNotPromoted(errorNode)(),
      );
    }
    report(diagnosticCode, errorNode, receiverType, messages: messages);
    return true;
  }
}
