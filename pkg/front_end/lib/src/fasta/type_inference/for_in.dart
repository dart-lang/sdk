// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../../base/instrumentation.dart' show InstrumentationValueForMember;
import '../fasta_codes.dart';
import '../kernel/internal_ast.dart';
import 'inference_results.dart';
import 'inference_visitor.dart';
import 'inference_visitor_base.dart';
import 'object_access_target.dart';
import 'type_schema.dart' show UnknownType;

class ForInResult {
  final VariableDeclaration variable;
  final Expression iterable;
  final Expression? syntheticAssignment;
  final Statement? expressionSideEffects;

  ForInResult(this.variable, this.iterable, this.syntheticAssignment,
      this.expressionSideEffects);

  @override
  String toString() => 'ForInResult($variable,$iterable,'
      '$syntheticAssignment,$expressionSideEffects)';
}

abstract class ForInVariable {
  /// Computes the type of the elements expected for this for-in variable.
  DartType computeElementType(InferenceVisitorBase visitor);

  /// Infers the assignment to this for-in variable with a value of type
  /// [rhsType]. The resulting expression is returned.
  Expression? inferAssignment(InferenceVisitorBase visitor, DartType rhsType);
}

class LocalForInVariable implements ForInVariable {
  VariableSet variableSet;

  LocalForInVariable(this.variableSet);

  @override
  DartType computeElementType(InferenceVisitorBase visitor) {
    VariableDeclaration variable = variableSet.variable;
    DartType? promotedType;
    if (visitor.isNonNullableByDefault) {
      promotedType = visitor.flowAnalysis.promotedType(variable);
    }
    return promotedType ?? variable.type;
  }

  @override
  Expression inferAssignment(InferenceVisitorBase visitor, DartType rhsType) {
    DartType variableType =
        visitor.computeGreatestClosure(variableSet.variable.type);
    Expression rhs = visitor.ensureAssignable(
        variableType, rhsType, variableSet.value,
        errorTemplate: templateForInLoopElementTypeNotAssignable,
        nullabilityErrorTemplate:
            templateForInLoopElementTypeNotAssignableNullability,
        nullabilityPartErrorTemplate:
            templateForInLoopElementTypeNotAssignablePartNullability,
        isVoidAllowed: true);

    variableSet.value = rhs..parent = variableSet;
    visitor.flowAnalysis
        .write(variableSet, variableSet.variable, rhsType, null);
    return variableSet;
  }
}

class PatternVariableDeclarationForInVariable implements ForInVariable {
  PatternVariableDeclaration patternVariableDeclaration;

  PatternVariableDeclarationForInVariable(this.patternVariableDeclaration);

  @override
  DartType computeElementType(InferenceVisitorBase visitor) {
    return (patternVariableDeclaration.initializer as VariableGet)
        .variable
        .type;
  }

  @override
  Expression? inferAssignment(InferenceVisitorBase visitor, DartType rhsType) {
    return null;
  }
}

class PropertyForInVariable implements ForInVariable {
  final PropertySet propertySet;

  DartType? _writeType;

  Expression? _rhs;

  PropertyForInVariable(this.propertySet);

  @override
  DartType computeElementType(InferenceVisitorBase visitor) {
    ExpressionInferenceResult receiverResult =
        visitor.inferExpression(propertySet.receiver, const UnknownType());
    propertySet.receiver = receiverResult.expression..parent = propertySet;
    DartType receiverType = receiverResult.inferredType;
    ObjectAccessTarget writeTarget = visitor.findInterfaceMember(
        receiverType, propertySet.name, propertySet.fileOffset,
        isSetter: true, instrumented: true, includeExtensionMethods: true);
    DartType elementType = _writeType = writeTarget.getSetterType(visitor);
    Expression? error = visitor.reportMissingInterfaceMember(
        writeTarget,
        receiverType,
        propertySet.name,
        propertySet.fileOffset,
        templateUndefinedSetter);
    if (error != null) {
      _rhs = error;
    } else {
      if (writeTarget.isInstanceMember || writeTarget.isObjectMember) {
        if (visitor.instrumentation != null &&
            receiverType == const DynamicType()) {
          visitor.instrumentation!.record(
              visitor.uriForInstrumentation,
              propertySet.fileOffset,
              'target',
              new InstrumentationValueForMember(writeTarget.member!));
        }
      }
      _rhs = propertySet.value;
    }
    return elementType;
  }

  @override
  Expression inferAssignment(InferenceVisitorBase visitor, DartType rhsType) {
    Expression rhs = visitor.ensureAssignable(
        visitor.computeGreatestClosure(_writeType!), rhsType, _rhs!,
        errorTemplate: templateForInLoopElementTypeNotAssignable,
        nullabilityErrorTemplate:
            templateForInLoopElementTypeNotAssignableNullability,
        nullabilityPartErrorTemplate:
            templateForInLoopElementTypeNotAssignablePartNullability,
        isVoidAllowed: true);

    propertySet.value = rhs..parent = propertySet;
    ExpressionInferenceResult result = visitor
        .inferExpression(propertySet, const UnknownType(), isVoidAllowed: true);
    return result.expression;
  }
}

class AbstractSuperPropertyForInVariable implements ForInVariable {
  final AbstractSuperPropertySet superPropertySet;

  DartType? _writeType;

  AbstractSuperPropertyForInVariable(this.superPropertySet);

  @override
  DartType computeElementType(InferenceVisitorBase visitor) {
    DartType receiverType = visitor.thisType!;
    ObjectAccessTarget writeTarget = visitor.findInterfaceMember(
        receiverType, superPropertySet.name, superPropertySet.fileOffset,
        isSetter: true, instrumented: true);
    assert(writeTarget.isInstanceMember || writeTarget.isObjectMember);
    return _writeType = writeTarget.getSetterType(visitor);
  }

  @override
  Expression inferAssignment(InferenceVisitorBase visitor, DartType rhsType) {
    Expression rhs = visitor.ensureAssignable(
        visitor.computeGreatestClosure(_writeType!),
        rhsType,
        superPropertySet.value,
        errorTemplate: templateForInLoopElementTypeNotAssignable,
        nullabilityErrorTemplate:
            templateForInLoopElementTypeNotAssignableNullability,
        nullabilityPartErrorTemplate:
            templateForInLoopElementTypeNotAssignablePartNullability,
        isVoidAllowed: true);
    superPropertySet.value = rhs..parent = superPropertySet;
    ExpressionInferenceResult result = visitor.inferExpression(
        superPropertySet, const UnknownType(),
        isVoidAllowed: true);
    return result.expression;
  }
}

class SuperPropertyForInVariable implements ForInVariable {
  final SuperPropertySet superPropertySet;

  DartType? _writeType;

  SuperPropertyForInVariable(this.superPropertySet);

  @override
  DartType computeElementType(InferenceVisitorBase visitor) {
    DartType receiverType = visitor.thisType!;
    ObjectAccessTarget writeTarget = visitor.findInterfaceMember(
        receiverType, superPropertySet.name, superPropertySet.fileOffset,
        isSetter: true, instrumented: true);
    assert(writeTarget.isInstanceMember || writeTarget.isObjectMember);
    return _writeType = writeTarget.getSetterType(visitor);
  }

  @override
  Expression inferAssignment(InferenceVisitorBase visitor, DartType rhsType) {
    Expression rhs = visitor.ensureAssignable(
        visitor.computeGreatestClosure(_writeType!),
        rhsType,
        superPropertySet.value,
        errorTemplate: templateForInLoopElementTypeNotAssignable,
        nullabilityErrorTemplate:
            templateForInLoopElementTypeNotAssignableNullability,
        nullabilityPartErrorTemplate:
            templateForInLoopElementTypeNotAssignablePartNullability,
        isVoidAllowed: true);
    superPropertySet.value = rhs..parent = superPropertySet;
    ExpressionInferenceResult result = visitor.inferExpression(
        superPropertySet, const UnknownType(),
        isVoidAllowed: true);
    return result.expression;
  }
}

class StaticForInVariable implements ForInVariable {
  final StaticSet staticSet;

  StaticForInVariable(this.staticSet);

  @override
  DartType computeElementType(InferenceVisitorBase visitor) =>
      staticSet.target.setterType;

  @override
  Expression inferAssignment(InferenceVisitorBase visitor, DartType rhsType) {
    DartType setterType =
        visitor.computeGreatestClosure(staticSet.target.setterType);
    Expression rhs = visitor.ensureAssignable(
        setterType, rhsType, staticSet.value,
        errorTemplate: templateForInLoopElementTypeNotAssignable,
        nullabilityErrorTemplate:
            templateForInLoopElementTypeNotAssignableNullability,
        nullabilityPartErrorTemplate:
            templateForInLoopElementTypeNotAssignablePartNullability,
        isVoidAllowed: true);

    staticSet.value = rhs..parent = staticSet;
    ExpressionInferenceResult result = visitor
        .inferExpression(staticSet, const UnknownType(), isVoidAllowed: true);
    return result.expression;
  }
}

class InvalidForInVariable implements ForInVariable {
  final Expression? expression;

  InvalidForInVariable(this.expression);

  @override
  DartType computeElementType(InferenceVisitor visitor) => const UnknownType();

  @override
  Expression? inferAssignment(InferenceVisitor visitor, DartType rhsType) =>
      expression;
}
