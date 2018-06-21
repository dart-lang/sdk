// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/fasta/resolution_applier.dart';
import 'package:front_end/src/fasta/kernel/factory.dart';
import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart';
import 'package:front_end/src/scanner/token.dart';
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
class ResolutionStorer extends _ResolutionStorer<int, int, Node, int>
    implements
        TypeInferenceListener<int, int, Node, int>,
        Factory<void, void, void, void> {
  ResolutionStorer(Map<int, ResolutionData<DartType, int, Node, int>> data)
      : super(data);
}

/// Implementation of [ResolutionStorer], with types parameterized to avoid
/// accidentally peeking into kernel internals.
///
/// TODO(paulberry): when the time is right, fuse this with [ResolutionStorer].
class _ResolutionStorer<Location, Declaration, Reference, PrefixInfo> {
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

  void asExpression(
      ExpressionJudgment judgment,
      Location location,
      void expression,
      Token asOperator,
      void literalType,
      DartType inferredType) {
    _store(location, literalType: inferredType, inferredType: inferredType);
  }

  void assertInitializer(
      InitializerJudgment judgment,
      Location location,
      Token assertKeyword,
      Token leftParenthesis,
      void condition,
      Token comma,
      void message,
      Token rightParenthesis) {}

  void assertStatement(
      StatementJudgment judgment,
      Location location,
      Token assertKeyword,
      Token leftParenthesis,
      void condition,
      Token comma,
      void message,
      Token rightParenthesis,
      Token semicolon) {}

  void awaitExpression(ExpressionJudgment judgment, Location location,
          Token awaitKeyword, void expression, DartType inferredType) =>
      genericExpression("awaitExpression", location, inferredType);

  void block(StatementJudgment judgment, Location location, Token leftBracket,
      List<void> statements, Token rightBracket) {}

  void boolLiteral(ExpressionJudgment judgment, Location location,
          Token literal, bool value, DartType inferredType) =>
      genericExpression("boolLiteral", location, inferredType);

  void breakStatement(StatementJudgment judgment, Location location,
      Token breakKeyword, void label, Token semicolon) {}

  void cascadeExpression(
      ExpressionJudgment judgment, Location location, DartType inferredType) {
    // Overridden so that the type of the expression will not be recorded. We
    // don't need to record the type because the type is always the same as the
    // type of the target, and we don't have the appropriate offset so we can't
    // correctly apply the type even if we recorded it.
  }

  void catchStatement(
      Catch judgment,
      Location location,
      Token onKeyword,
      void type,
      Token catchKeyword,
      Token leftParenthesis,
      Token exceptionParameter,
      Token comma,
      Token stackTraceParameter,
      Token rightParenthesis,
      void body,
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

  void conditionalExpression(
          ExpressionJudgment judgment,
          Location location,
          void condition,
          Token question,
          void thenExpression,
          Token colon,
          void elseExpression,
          DartType inferredType) =>
      genericExpression("conditionalExpression", location, inferredType);

  void constructorInvocation(ExpressionJudgment judgment, Location location,
      Reference expressionTarget, DartType inferredType) {
    // A class reference may have already been stored at this location by
    // storeClassReference.  We want to replace it with a constructor
    // reference.
    _unstore(location);
    _store(location, inferredType: inferredType, reference: expressionTarget);
  }

  void continueStatement(StatementJudgment judgment, Location location,
      Token continueKeyword, void label, Token semicolon) {}

  void continueSwitchStatement(StatementJudgment judgment, Location location,
      Token continueKeyword, void label, Token semicolon) {}

  void deferredCheck(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression("deferredCheck", location, inferredType);

  void doStatement(
      StatementJudgment judgment,
      Location location,
      Token doKeyword,
      void body,
      Token whileKeyword,
      Token leftParenthesis,
      void condition,
      Token rightParenthesis,
      Token semicolon) {}

  void doubleLiteral(ExpressionJudgment judgment, Location location,
          Token literal, double value, DartType inferredType) =>
      genericExpression("doubleLiteral", location, inferredType);

  void expressionStatement(StatementJudgment judgment, Location location,
      void expression, Token semicolon) {}

  void fieldInitializer(
      InitializerJudgment judgment,
      Location location,
      Token thisKeyword,
      Token period,
      Token fieldName,
      Token equals,
      void expression,
      Reference initializerField) {
    _store(location, reference: initializerField);
  }

  void forInStatement(
      StatementJudgment judgment,
      Location location,
      Token awaitKeyword,
      Token forKeyword,
      Token leftParenthesis,
      Object loopVariable,
      Token identifier,
      Token inKeyword,
      void iterator,
      Token rightParenthesis,
      void body,
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

  void forStatement(
      StatementJudgment judgment,
      Location location,
      Token forKeyword,
      Token leftParenthesis,
      void variableDeclarationList,
      void initialization,
      Token leftSeparator,
      void condition,
      Token rightSeparator,
      void updaters,
      Token rightParenthesis,
      void body) {}

  void functionDeclaration(StatementJudgment judgment, Location location,
      FunctionType inferredType) {
    _store(location, inferredType: inferredType);
  }

  void functionExpression(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression("functionExpression", location, inferredType);

  void genericExpression(
      String expressionType, Location location, DartType inferredType) {
    _store(location, inferredType: inferredType);
  }

  void ifNull(ExpressionJudgment judgment, Location location, void leftOperand,
          Token operator, void rightOperand, DartType inferredType) =>
      genericExpression('ifNull', location, inferredType);

  void ifStatement(
      StatementJudgment judgment,
      Location location,
      Token ifKeyword,
      Token leftParenthesis,
      void condition,
      Token rightParenthesis,
      void thenStatement,
      Token elseKeyword,
      void elseStatement) {}

  void intLiteral(ExpressionJudgment judgment, Location location, Token literal,
          num value, DartType inferredType) =>
      genericExpression("intLiteral", location, inferredType);

  void invalidInitializer(InitializerJudgment judgment, Location location) {}

  void labeledStatement(StatementJudgment judgment, Location location) {}

  void listLiteral(
          ExpressionJudgment judgment,
          Location location,
          Token constKeyword,
          Object typeArguments,
          Token leftBracket,
          void elements,
          Token rightBracket,
          DartType inferredType) =>
      genericExpression("listLiteral", location, inferredType);

  void logicalExpression(
          ExpressionJudgment judgment,
          Location location,
          void leftOperand,
          Token operator,
          void rightOperand,
          DartType inferredType) =>
      genericExpression("logicalExpression", location, inferredType);

  void mapLiteral(
          ExpressionJudgment judgment,
          Location location,
          Token constKeyword,
          Object typeArguments,
          Token leftBracket,
          List<Object> entries,
          Token rightBracket,
          DartType typeContext) =>
      genericExpression("mapLiteral", location, typeContext);

  void mapLiteralEntry(
      Object judgment, int fileOffset, void key, Token separator, void value) {
    // TODO(brianwilkerson) Implement this.
  }

  void namedFunctionExpression(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression("namedFunctionExpression", location, inferredType);

  void not(ExpressionJudgment judgment, Location location, Token operator,
          void operand, DartType inferredType) =>
      genericExpression("not", location, inferredType);

  void nullLiteral(ExpressionJudgment judgment, Location location,
      Token literal, bool isSynthetic, DartType inferredType) {
    if (isSynthetic) return null;
    genericExpression("nullLiteral", location, inferredType);
  }

  void indexAssign(ExpressionJudgment judgment, Location location,
      Reference writeMember, Reference combiner, DartType inferredType) {
    _store(location,
        reference: writeMember, inferredType: inferredType, combiner: combiner);
  }

  void isExpression(
      ExpressionJudgment judgment,
      Location location,
      void expression,
      Token isOperator,
      void literalType,
      DartType testedType,
      DartType inferredType) {
    _store(location, literalType: testedType, inferredType: inferredType);
  }

  void isNotExpression(
      ExpressionJudgment judgment,
      Location location,
      void expression,
      Token isOperator,
      Token notOperator,
      void literalType,
      DartType type,
      DartType inferredType) {
    _store(location, literalType: type, inferredType: inferredType);
  }

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

  void propertySet(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression("propertySet", location, inferredType);

  void propertyGet(ExpressionJudgment judgment, Location location,
      Reference member, DartType inferredType) {
    _store(location, reference: member, inferredType: inferredType);
  }

  void propertyGetCall(
      ExpressionJudgment judgment, Location location, DartType inferredType) {
    _store(location, isExplicitCall: true);
  }

  void redirectingInitializer(
      InitializerJudgment judgment,
      Location location,
      Token thisKeyword,
      Token period,
      Token constructorName,
      covariant Object argumentList,
      Reference initializerTarget) {
    _store(location, reference: initializerTarget);
  }

  void rethrow_(ExpressionJudgment judgment, Location location,
          Token rethrowKeyword, DartType inferredType) =>
      genericExpression('rethrow', location, inferredType);

  void returnStatement(StatementJudgment judgment, Location location,
      Token returnKeyword, void expression, Token semicolon) {}

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

  void staticGet(ExpressionJudgment judgment, Location location,
      Reference expressionTarget, DartType inferredType) {
    _store(location, reference: expressionTarget, inferredType: inferredType);
  }

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

  void stringConcatenation(
      ExpressionJudgment judgment, Location location, DartType inferredType) {
    // We don't need the type - we already know that it is String.
    // Moreover, the file offset for StringConcatenation is `-1`.
  }

  void stringLiteral(ExpressionJudgment judgment, Location location,
          Token literal, String value, DartType inferredType) =>
      genericExpression("StringLiteral", location, inferredType);

  void superInitializer(
      InitializerJudgment judgment,
      Location location,
      Token superKeyword,
      Token period,
      Token constructorName,
      covariant Object argumentList) {}

  void switchStatement(
      StatementJudgment judgment,
      Location location,
      Token switchKeyword,
      Token leftParenthesis,
      void expression,
      Token rightParenthesis,
      Token leftBracket,
      void members,
      Token rightBracket) {}

  void symbolLiteral(
          ExpressionJudgment judgment,
          Location location,
          Token poundSign,
          List<Token> components,
          String value,
          DartType inferredType) =>
      genericExpression("symbolLiteral", location, inferredType);

  void thisExpression(ExpressionJudgment judgment, Location location,
      Token thisKeyword, DartType inferredType) {}

  void throw_(ExpressionJudgment judgment, Location location,
          Token throwKeyword, void expression, DartType inferredType) =>
      genericExpression('throw', location, inferredType);

  void tryCatch(StatementJudgment judgment, Location location) {}

  void tryFinally(
      StatementJudgment judgment,
      Location location,
      Token tryKeyword,
      void body,
      void catchClauses,
      Token finallyKeyword,
      void finallyBlock) {}

  void typeLiteral(ExpressionJudgment judgment, Location location,
      Reference expressionType, DartType inferredType) {
    _store(location, reference: expressionType, inferredType: inferredType);
  }

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

  void variableDeclaration(StatementJudgment judgment, Location location,
      DartType statementType, DartType inferredType) {
    _store(location, literalType: statementType, inferredType: inferredType);
  }

  void variableGet(ExpressionJudgment judgment, Location location,
      bool isInCascade, Declaration expressionVariable, DartType inferredType) {
    if (isInCascade) {
      return;
    }
    _store(location,
        declaration: expressionVariable, inferredType: inferredType);
  }

  void variableSet(ExpressionJudgment judgment, Location location,
          DartType inferredType) =>
      genericExpression("variableSet", location, inferredType);

  void whileStatement(
      StatementJudgment judgment,
      Location location,
      Token whileKeyword,
      Token leftParenthesis,
      void condition,
      Token rightParenthesis,
      void body) {}

  void yieldStatement(StatementJudgment judgment, Location location,
      Token yieldKeyword, Token star, void expression, Token semicolon) {}

  void storePrefixInfo(Location location, PrefixInfo prefixInfo) {
    _store(location, prefixInfo: prefixInfo);
  }

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
