// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/fasta/resolution_applier.dart';
import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/type_algebra.dart';

class ResolutionData<Type, Declaration, Reference, PrefixInfo> {
  final List<Type> argumentTypes;
  final Reference combiner;
  final Declaration declaration;
  final Type inferredType;
  final Type invokeType;
  final bool isExplicitCall;
  final bool isImplicitCall;
  final bool isWriteReference;
  final Type literalType;
  final PrefixInfo prefixInfo;
  final Reference reference;
  final Type writeContext;

  ResolutionData(
      {this.argumentTypes,
      this.combiner,
      this.declaration,
      this.inferredType,
      this.invokeType,
      this.isExplicitCall = false,
      this.isImplicitCall = false,
      this.isWriteReference = false,
      this.literalType,
      this.prefixInfo,
      this.reference,
      this.writeContext});
}

/// Type inference listener that records inferred types for later use by
/// [ResolutionApplier].
class ResolutionStorer extends _ResolutionStorer<int, int, Node, int> {
  ResolutionStorer(Map<int, ResolutionData<DartType, int, Node, int>> data)
      : super(data);
}

/// Implementation of [ResolutionStorer], with types parameterized to avoid
/// accidentally peeking into kernel internals.
///
/// TODO(paulberry): when the time is right, fuse this with [ResolutionStorer].
class _ResolutionStorer<Location, Declaration, Reference, PrefixInfo>
    implements
        TypeInferenceListener<Location, Declaration, Reference, PrefixInfo> {
  final Map<Location,
      ResolutionData<DartType, Declaration, Reference, PrefixInfo>> _data;

  _ResolutionStorer(this._data);

  void _store(Location location,
      {List<DartType> argumentTypes,
      Reference combiner,
      Declaration declaration,
      DartType inferredType,
      DartType invokeType,
      bool isExplicitCall = false,
      bool isImplicitCall = false,
      bool isWriteReference = false,
      DartType literalType,
      PrefixInfo prefixInfo,
      Reference reference,
      bool replace = false,
      DartType writeContext}) {
    if (!replace && _data.containsKey(location)) {
      throw new StateError('Data already stored for offset $location');
    }
    _data[location] = new ResolutionData(
        argumentTypes: argumentTypes,
        combiner: combiner,
        declaration: declaration,
        inferredType: inferredType,
        invokeType: invokeType,
        isExplicitCall: isExplicitCall,
        isImplicitCall: isImplicitCall,
        isWriteReference: isWriteReference,
        literalType: literalType,
        prefixInfo: prefixInfo,
        reference: reference,
        writeContext: writeContext);
  }

  void _unstore(Location location) {
    _data.remove(location) == null;
  }

  @override
  void asExpression(
      ExpressionJudgment judgment, Location location, DartType inferredType) {
    _store(location, literalType: inferredType, inferredType: inferredType);
  }

  @override
  void assertInitializer(InitializerJudgment judgment, Location location) {}

  @override
  void assertStatement(StatementJudgment judgment, Location location) {}

  @override
  void awaitExpression(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression("awaitExpression", location, inferredType);

  @override
  void block(StatementJudgment judgment, Location location) {}

  @override
  void boolLiteral(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression("boolLiteral", location, inferredType);

  @override
  void breakStatement(StatementJudgment judgment, Location location) {}

  @override
  void cascadeExpression(
      ExpressionJudgment judgment, Location location, DartType inferredType) {
    // Overridden so that the type of the expression will not be recorded. We
    // don't need to record the type because the type is always the same as the
    // type of the target, and we don't have the appropriate offset so we can't
    // correctly apply the type even if we recorded it.
  }

  @override
  void catchStatement(
      Catch judgment,
      Location location,
      DartType guardType,
      Location exceptionLocation,
      DartType exceptionType,
      Location stackTraceLocation,
      DartType stackTraceType) {
    _store(location, literalType: guardType);

    if (exceptionLocation != null) {
      _store(exceptionLocation, literalType: exceptionType);
    }

    if (stackTraceLocation != null) {
      _store(stackTraceLocation, literalType: stackTraceType);
    }
  }

  @override
  void conditionalExpression(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression("conditionalExpression", location, inferredType);

  @override
  void constructorInvocation(ExpressionJudgment judgment, Location location,
      Reference expressionTarget, DartType inferredType) {
    // A class reference may have already been stored at this location by
    // storeClassReference.  We want to replace it with a constructor
    // reference.
    _unstore(location);
    _store(location, inferredType: inferredType, reference: expressionTarget);
  }

  @override
  void continueSwitchStatement(StatementJudgment judgment, Location location) {}

  @override
  void deferredCheck(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression("deferredCheck", location, inferredType);

  @override
  void doStatement(StatementJudgment judgment, Location location) {}

  @override
  void doubleLiteral(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression("doubleLiteral", location, inferredType);

  @override
  void expressionStatement(StatementJudgment judgment, Location location) {}

  @override
  void fieldInitializer(InitializerJudgment judgment, Location location,
      Reference initializerField) {
    _store(location, reference: initializerField);
  }

  @override
  void forInStatement(
      StatementJudgment judgment,
      Location location,
      Location variableLocation,
      DartType variableType,
      Location writeLocation,
      DartType writeType,
      Declaration writeVariable,
      Reference writeTarget) {
    if (variableLocation != null) {
      _store(variableLocation, inferredType: variableType);
    } else {
      if (writeVariable != null) {
        _store(writeLocation,
            declaration: writeVariable, inferredType: writeType);
      } else {
        _store(writeLocation,
            reference: writeTarget,
            isWriteReference: true,
            writeContext: writeType);
      }
    }
  }

  @override
  void forStatement(StatementJudgment judgment, Location location) {}

  @override
  void functionDeclaration(StatementJudgment judgment, Location location,
      FunctionType inferredType) {
    _store(location, inferredType: inferredType);
  }

  @override
  void functionExpression(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression("functionExpression", location, inferredType);

  void genericExpression(
      String expressionType, Location location, DartType inferredType) {
    _store(location, inferredType: inferredType);
  }

  @override
  void ifNull(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression('ifNull', location, inferredType);

  @override
  void ifStatement(StatementJudgment judgment, Location location) {}

  @override
  void intLiteral(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression("intLiteral", location, inferredType);

  @override
  void invalidInitializer(InitializerJudgment judgment, Location location) {}

  @override
  void labeledStatement(StatementJudgment judgment, Location location) {}

  @override
  void listLiteral(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression("listLiteral", location, inferredType);

  @override
  void logicalExpression(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression("logicalExpression", location, inferredType);

  @override
  void mapLiteral(ExpressionJudgment judgment, Location location,
          DartType typeContext) =>
      genericExpression("mapLiteral", location, typeContext);

  @override
  void namedFunctionExpression(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression("namedFunctionExpression", location, inferredType);

  @override
  void not(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression("not", location, inferredType);

  @override
  void nullLiteral(ExpressionJudgment judgment, Location location,
      bool isSynthetic, DartType inferredType) {
    if (isSynthetic) return null;
    genericExpression("nullLiteral", location, inferredType);
  }

  @override
  void indexAssign(ExpressionJudgment judgment, Location location,
      Reference writeMember, Reference combiner, DartType inferredType) {
    _store(location,
        reference: writeMember, inferredType: inferredType, combiner: combiner);
  }

  @override
  void isExpression(ExpressionJudgment judgment, Location location,
      DartType testedType, DartType inferredType) {
    _store(location, literalType: testedType, inferredType: inferredType);
  }

  void isNotExpression(ExpressionJudgment judgment, Location location,
      DartType type, DartType inferredType) {
    _store(location, literalType: type, inferredType: inferredType);
  }

  @override
  void methodInvocation(
      ExpressionJudgment judgment,
      Location resultOffset,
      List<DartType> argumentsTypes,
      bool isImplicitCall,
      Reference interfaceMember,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {
    FunctionType invokeType = substitution == null
        ? calleeType
        : substitution.substituteType(calleeType.withoutTypeParameters);

    _store(resultOffset,
        inferredType: inferredType,
        argumentTypes: argumentsTypes,
        invokeType: invokeType,
        isImplicitCall: isImplicitCall,
        reference: interfaceMember);
  }

  @override
  void methodInvocationCall(
      ExpressionJudgment judgment,
      Location resultOffset,
      List<DartType> argumentsTypes,
      bool isImplicitCall,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {
    FunctionType invokeType = substitution == null
        ? calleeType
        : substitution.substituteType(calleeType.withoutTypeParameters);

    _store(resultOffset,
        inferredType: inferredType,
        argumentTypes: argumentsTypes,
        invokeType: invokeType,
        isImplicitCall: isImplicitCall);
  }

  @override
  void propertyAssign(
      ExpressionJudgment judgment,
      Location location,
      Reference writeMember,
      DartType writeContext,
      Reference combiner,
      DartType inferredType) {
    _store(location,
        isWriteReference: true,
        reference: writeMember,
        writeContext: writeContext,
        combiner: combiner,
        inferredType: inferredType);
  }

  @override
  void propertySet(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression("propertySet", location, inferredType);

  @override
  void propertyGet(ExpressionJudgment judgment, Location location,
      Reference member, DartType inferredType) {
    _store(location, reference: member, inferredType: inferredType);
  }

  @override
  void propertyGetCall(
      ExpressionJudgment judgment, Location location, DartType inferredType) {
    _store(location, isExplicitCall: true);
  }

  @override
  void redirectingInitializer(InitializerJudgment judgment, Location location,
      Reference initializerTarget) {
    _store(location, reference: initializerTarget);
  }

  @override
  void rethrow_(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression('rethrow', location, inferredType);

  @override
  void returnStatement(StatementJudgment judgment, Location location) {}

  @override
  void staticAssign(
      ExpressionJudgment judgment,
      Location location,
      Reference writeMember,
      DartType writeContext,
      Reference combiner,
      DartType inferredType) {
    _store(location,
        reference: writeMember,
        isWriteReference: true,
        writeContext: writeContext,
        combiner: combiner,
        inferredType: inferredType);
  }

  @override
  void staticGet(ExpressionJudgment judgment, Location location,
      Reference expressionTarget, DartType inferredType) {
    _store(location, reference: expressionTarget, inferredType: inferredType);
  }

  @override
  void staticInvocation(
      ExpressionJudgment judgment,
      Location location,
      Reference expressionTarget,
      List<DartType> expressionArgumentsTypes,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {
    FunctionType invokeType = substitution == null
        ? calleeType
        : substitution.substituteType(calleeType.withoutTypeParameters);
    _store(location,
        invokeType: invokeType,
        argumentTypes: expressionArgumentsTypes,
        reference: expressionTarget,
        inferredType: inferredType);
  }

  @override
  void stringConcatenation(
      ExpressionJudgment judgment, Location location, DartType inferredType) {
    // We don't need the type - we already know that it is String.
    // Moreover, the file offset for StringConcatenation is `-1`.
  }

  @override
  void stringLiteral(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression("StringLiteral", location, inferredType);

  @override
  void superInitializer(InitializerJudgment judgment, Location location) {}

  @override
  void switchStatement(StatementJudgment judgment, Location location) {}

  @override
  void symbolLiteral(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression("symbolLiteral", location, inferredType);

  @override
  void thisExpression(
      ExpressionJudgment judgment, Location location, DartType inferredType) {}

  @override
  void throw_(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression('throw', location, inferredType);

  @override
  void tryCatch(StatementJudgment judgment, Location location) {}

  @override
  void tryFinally(StatementJudgment judgment, Location location) {}

  void typeLiteral(ExpressionJudgment judgment, Location location,
      Reference expressionType, DartType inferredType) {
    _store(location, reference: expressionType, inferredType: inferredType);
  }

  @override
  void variableAssign(
      ExpressionJudgment judgment,
      Location location,
      DartType writeContext,
      Declaration writeVariable,
      Reference combiner,
      DartType inferredType) {
    _store(location,
        declaration: writeVariable,
        isWriteReference: true,
        writeContext: writeContext,
        combiner: combiner,
        inferredType: inferredType);
  }

  @override
  void variableDeclaration(StatementJudgment judgment, Location location,
      DartType statementType, DartType inferredType) {
    _store(location, literalType: statementType, inferredType: inferredType);
  }

  @override
  void variableGet(ExpressionJudgment judgment, Location location,
      bool isInCascade, Declaration expressionVariable, DartType inferredType) {
    if (isInCascade) {
      return;
    }
    _store(location,
        declaration: expressionVariable, inferredType: inferredType);
  }

  @override
  void variableSet(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression("variableSet", location, inferredType);

  @override
  void whileStatement(StatementJudgment judgment, Location location) {}

  @override
  void yieldStatement(StatementJudgment judgment, Location location) {}

  @override
  void storePrefixInfo(Location location, PrefixInfo prefixInfo) {
    _store(location, prefixInfo: prefixInfo);
  }

  @override
  void storeClassReference(
      Location location, Reference reference, DartType rawType) {
    // TODO(paulberry): would it be better to use literalType?
    _store(location, reference: reference, inferredType: rawType);
  }
}

/// A [DartType] wrapper around invocation type arguments.
class TypeArgumentsDartType implements DartType {
  final List<DartType> types;

  TypeArgumentsDartType(this.types);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() {
    return '<${types.join(', ')}>';
  }
}
