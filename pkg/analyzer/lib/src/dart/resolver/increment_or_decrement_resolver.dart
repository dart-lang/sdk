// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/assignment_expression_resolver.dart';
import 'package:analyzer/src/dart/resolver/invocation_inferrer.dart';
import 'package:analyzer/src/dart/resolver/resolution_result.dart';
import 'package:analyzer/src/dart/resolver/type_analyzer.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/generated/error_detection_helpers.dart';

/// Helper for resolving prefix and postfix increment and decrement expressions.
class IncrementOrDecrementResolver {
  final TypeAnalyzer _typeAnalyzer;
  final TypePropertyResolver _typePropertyResolver;
  final AssignmentExpressionResolver _assignmentResolver;

  new({required TypeAnalyzer typeAnalyzer})
    : _typeAnalyzer = typeAnalyzer,
      _typePropertyResolver = typeAnalyzer.typePropertyResolver,
      _assignmentResolver = AssignmentExpressionResolver(
        typeAnalyzer: typeAnalyzer,
      );

  DiagnosticReporter get _diagnosticReporter =>
      _typeAnalyzer.diagnosticReporter;

  TypeProviderImpl get _typeProvider => _typeAnalyzer.typeProvider;

  TypeSystemImpl get _typeSystem => _typeAnalyzer.typeSystem;

  void resolve(IncrementOrDecrementExpressionImpl node) {
    var isPrefix = node.position == IncrementOrDecrementPosition.prefix;
    var target = node.target;

    if (target
        case CascadeIndexAssignmentTargetImpl() ||
            CascadePropertyAssignmentTargetImpl()) {
      throw StateError(
        'A cascade section cannot be an increment or decrement target',
      );
    }

    TypeImpl readType;
    TypeImpl writeAcceptedType;
    InternalVariableElement? variableElement;
    switch (_assignmentResolver.resolveReadWriteTarget(node, target)) {
      case ResolvedReadWriteTarget result:
        readType = result.readType;
        writeAcceptedType = result.writeAcceptedType;
        variableElement = result.variableElement;
      case UnresolvedReadWriteTarget():
        node.operatorResultType = NeverTypeImpl.instance;
        node.recordStaticType(
          NeverTypeImpl.instance,
          typeAnalyzer: _typeAnalyzer,
        );
        return;
      case InvalidReadWriteTarget():
        // Keep the target's resolution, but don't expose a partially resolved
        // read-modify-write operation for a target that can't be written.
        node.operatorResultType = InvalidTypeImpl.instance;
        node.recordStaticType(
          InvalidTypeImpl.instance,
          typeAnalyzer: _typeAnalyzer,
        );
        return;
    }

    _resolveOperator(
      node,
      isPrefix: isPrefix,
      readType: readType,
      errorEntity: target,
    );
    _checkOperatorArgument(node);
    _resolveResult(
      node,
      isPrefix: isPrefix,
      readType: readType,
      writeAcceptedType: writeAcceptedType,
      variableElement: variableElement,
    );
  }

  /// Check that the result [type] of a `++` or `--` expression is assignable
  /// to the write type of the operand.
  void _checkForInvalidAssignmentIncDec(
    IncrementOrDecrementExpressionImpl node,
    TypeImpl type,
    TypeImpl operandWriteType,
  ) {
    if (!_typeSystem.isAssignableTo(
      type,
      operandWriteType,
      strictCasts: _typeAnalyzer.analysisOptions.strictCasts,
    )) {
      _typeAnalyzer.diagnosticReporter.report(
        // An index increment or decrement invokes `operator []=`, so a
        // non-assignable result is reported as an argument error.
        (node.target is IndexAssignmentTargetImpl
                ? const NonAssignabilityReporterForArgument().createDiagnostic(
                    expectedStaticType: operandWriteType,
                    actualStaticType: type,
                  )
                : diag.invalidAssignment.withArguments(
                    actualStaticType: type,
                    expectedStaticType: operandWriteType,
                  ))
            .at(node),
      );
    }
  }

  /// Checks the implicit `1` passed to the `+` or `-` operator.
  void _checkOperatorArgument(IncrementOrDecrementExpressionImpl node) {
    var element = node.element;
    if (element == null || element.formalParameters.length != 1) {
      return;
    }

    var expectedType = element.formalParameters.single.type;
    var strictCasts = _typeAnalyzer.analysisOptions.strictCasts;
    var intType = _typeProvider.intType;
    var doubleType = _typeProvider.doubleType;
    // The implicit argument is the integer literal `1`. Like an explicit
    // integer literal, it has type `double` when `int` is not accepted by the
    // context but `double` is.
    var actualType =
        !_typeSystem.isAssignableTo(
              intType,
              expectedType,
              strictCasts: strictCasts,
            ) &&
            _typeSystem.isAssignableTo(
              doubleType,
              expectedType,
              strictCasts: strictCasts,
            )
        ? doubleType
        : intType;
    if (!_typeSystem.isAssignableTo(
      actualType,
      expectedType,
      strictCasts: strictCasts,
    )) {
      _diagnosticReporter.report(
        const NonAssignabilityReporterForArgument()
            .createDiagnostic(
              actualStaticType: actualType,
              expectedStaticType: expectedType,
            )
            .at(node.operator),
      );
    }
  }

  /// Compute the static return type of the method or function represented by
  /// [element].
  TypeImpl _computeStaticReturnType(Element? element, TypeImpl fallback) {
    if (element is PropertyAccessorElement) {
      // This is a function invocation expression disguised as something else.
      // We are invoking a getter and then invoking the returned function.
      var propertyType = element.type;
      return InvocationInferrer.computeInvokeReturnType(
        propertyType.returnType,
      );
    } else if (element is ExecutableElement) {
      return InvocationInferrer.computeInvokeReturnType(element.type);
    }
    return fallback;
  }

  void _resolveOperator(
    IncrementOrDecrementExpressionImpl node, {
    required bool isPrefix,
    required TypeImpl readType,
    required AstNode errorEntity,
  }) {
    var operator = node.operator;
    var methodName = node.operation.binaryOperatorName;

    // TODO(scheglov): Review why an invalid read type stops operator lookup
    // only for prefix increment and decrement.
    if (isPrefix && readType is InvalidType) {
      return;
    }
    if (identical(readType, NeverTypeImpl.instance)) {
      _typeAnalyzer.diagnosticReporter.report(
        diag.receiverOfTypeNever.at(errorEntity),
      );
      return;
    }

    var result = _typePropertyResolver.resolve(
      receiver: node,
      receiverType: readType,
      name: methodName,
      hasRead: true,
      hasWrite: false,
      propertyErrorEntity: node.operator,
      nameErrorEntity: errorEntity,
      parentNode: node,
    );
    node.element = result.getter2 as InternalMethodElement?;
    if (result.getterOutcome == LookupOutcome.notFound) {
      _diagnosticReporter.report(
        diag.undefinedOperator
            .withArguments(operator: methodName, type: readType)
            .at(operator),
      );
    }
  }

  void _resolveResult(
    IncrementOrDecrementExpressionImpl node, {
    required bool isPrefix,
    required TypeImpl readType,
    required TypeImpl writeAcceptedType,
    required InternalVariableElement? variableElement,
  }) {
    _typeAnalyzer.checkWriteOfAssignedFinalLocalVariable(node.target);

    if (identical(readType, NeverTypeImpl.instance)) {
      node.operatorResultType = NeverTypeImpl.instance;
      node.recordStaticType(
        NeverTypeImpl.instance,
        typeAnalyzer: _typeAnalyzer,
      );
      return;
    }

    TypeImpl operatorResultType;
    if (isPrefix && readType is DynamicType) {
      operatorResultType = DynamicTypeImpl.instance;
    } else if (isPrefix && readType is InvalidType) {
      operatorResultType = InvalidTypeImpl.instance;
    } else if (readType.isDartCoreInt) {
      operatorResultType = isPrefix ? _typeProvider.intType : readType;
    } else {
      // TODO(scheglov): Review why a missing operator element produces an
      // invalid type for prefix expressions but `dynamic` for postfix ones.
      var fallback = isPrefix
          ? InvalidTypeImpl.instance
          : DynamicTypeImpl.instance;
      operatorResultType = _computeStaticReturnType(node.element, fallback);
    }

    _checkForInvalidAssignmentIncDec(
      node,
      operatorResultType,
      writeAcceptedType,
    );
    if (variableElement is PromotableElementImpl) {
      if (isPrefix) {
        _typeAnalyzer.flowAnalysis.storeExpressionInfo(
          node,
          _typeAnalyzer.flowAnalysis.flow?.write(
            node,
            variableElement,
            SharedTypeView(operatorResultType),
            null,
            offset: node.end,
          ),
        );
      } else {
        _typeAnalyzer.flowAnalysis.flow?.postIncDec(
          node,
          variableElement,
          SharedTypeView(operatorResultType),
          offset: node.operator.offset,
        );
      }
    }

    node.operatorResultType = operatorResultType;
    node.recordStaticType(
      isPrefix ? operatorResultType : readType,
      typeAnalyzer: _typeAnalyzer,
    );
  }
}
