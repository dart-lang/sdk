// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/fasta/resolution_applier.dart';
import 'package:front_end/src/fasta/kernel/factory.dart';
import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart';
import 'package:front_end/src/fasta/kernel/kernel_type_variable_builder.dart';
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
  final bool isPrefixReference;
  final bool isTypeReference;
  final bool isWriteReference;
  final Type literalType;
  final Reference loadLibrary;
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
      this.isPrefixReference = false,
      this.isTypeReference = false,
      this.isWriteReference = false,
      this.literalType,
      this.loadLibrary,
      this.prefixInfo,
      this.reference,
      this.writeContext});
}

/// Type inference listener that records inferred types for later use by
/// [ResolutionApplier].
class ResolutionStorer
    implements
        TypeInferenceListener<int, Node, int>,
        Factory<void, void, void, void> {
  final Map<int, ResolutionData<DartType, int, Node, int>> _data;

  final Map<TypeParameter, int> _typeVariableDeclarations;

  ResolutionStorer(Map<int, ResolutionData<DartType, int, Node, int>> data,
      Map<TypeParameter, int> typeVariableDeclarations)
      : _data = data,
        _typeVariableDeclarations = typeVariableDeclarations;

  void asExpression(ExpressionJudgment judgment, int location, void expression,
      Token asOperator, void literalType, DartType inferredType) {
    _store(location, literalType: inferredType, inferredType: inferredType);
  }

  void assertInitializer(
      InitializerJudgment judgment,
      int location,
      Token assertKeyword,
      Token leftParenthesis,
      void condition,
      Token comma,
      void message,
      Token rightParenthesis) {}

  void assertStatement(
      StatementJudgment judgment,
      int location,
      Token assertKeyword,
      Token leftParenthesis,
      void condition,
      Token comma,
      void message,
      Token rightParenthesis,
      Token semicolon) {}

  void awaitExpression(ExpressionJudgment judgment, int location,
          Token awaitKeyword, void expression, DartType inferredType) =>
      genericExpression("awaitExpression", location, inferredType);

  Object binderForFunctionDeclaration(
      StatementJudgment judgment, int fileOffset, String name) {
    return new VariableDeclarationBinder(fileOffset);
  }

  void binderForStatementLabel(
      StatementJudgment judgment, int fileOffset, String name) {}

  void binderForSwitchLabel(
      SwitchCaseJudgment judgment, int fileOffset, String name) {}

  TypeVariableBinder binderForTypeVariable(
      KernelTypeVariableBuilder builder, int fileOffset, String name) {
    return new TypeVariableBinder(fileOffset);
  }

  Object binderForVariableDeclaration(
      StatementJudgment judgment, int fileOffset, String name) {
    return new VariableDeclarationBinder(fileOffset);
  }

  void block(StatementJudgment judgment, int location, Token leftBracket,
      List<void> statements, Token rightBracket) {}

  void boolLiteral(ExpressionJudgment judgment, int location, Token literal,
          bool value, DartType inferredType) =>
      genericExpression("boolLiteral", location, inferredType);

  void breakStatement(
      StatementJudgment judgment,
      int location,
      Token breakKeyword,
      void label,
      Token semicolon,
      covariant Object labelBinder) {}

  void cascadeExpression(
      ExpressionJudgment judgment, int location, DartType inferredType) {
    // Overridden so that the type of the expression will not be recorded. We
    // don't need to record the type because the type is always the same as the
    // type of the target, and we don't have the appropriate offset so we can't
    // correctly apply the type even if we recorded it.
  }

  void catchStatement(
      Catch judgment,
      int location,
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
      covariant VariableDeclarationBinder exceptionBinder,
      DartType exceptionType,
      covariant VariableDeclarationBinder stackTraceBinder,
      DartType stackTraceType) {
    _store(location, literalType: guardType);

    if (exceptionBinder != null) {
      _store(exceptionBinder.fileOffset, literalType: exceptionType);
    }

    if (stackTraceBinder != null) {
      _store(stackTraceBinder.fileOffset, literalType: stackTraceType);
    }
  }

  void conditionalExpression(
          ExpressionJudgment judgment,
          int location,
          void condition,
          Token question,
          void thenExpression,
          Token colon,
          void elseExpression,
          DartType inferredType) =>
      genericExpression("conditionalExpression", location, inferredType);

  void constructorInvocation(ExpressionJudgment judgment, int location,
      Node expressionTarget, DartType inferredType) {
    // A class reference may have already been stored at this location by
    // storeClassReference.  We want to replace it with a constructor
    // reference.
    _unstore(location);
    _store(location, inferredType: inferredType, reference: expressionTarget);
  }

  void continueStatement(
      StatementJudgment judgment,
      int location,
      Token continueKeyword,
      void label,
      Token semicolon,
      covariant Object labelBinder) {}

  void continueSwitchStatement(
      StatementJudgment judgment,
      int location,
      Token continueKeyword,
      void label,
      Token semicolon,
      covariant Object labelBinder) {}

  void deferredCheck(
      ExpressionJudgment judgment, int location, DartType inferredType) {
    // This judgment has no semantic value for Analyzer.
  }

  void doStatement(
      StatementJudgment judgment,
      int location,
      Token doKeyword,
      void body,
      Token whileKeyword,
      Token leftParenthesis,
      void condition,
      Token rightParenthesis,
      Token semicolon) {}

  void doubleLiteral(ExpressionJudgment judgment, int location, Token literal,
          double value, DartType inferredType) =>
      genericExpression("doubleLiteral", location, inferredType);

  void emptyStatement(Token semicolon) {}

  void expressionStatement(StatementJudgment judgment, int location,
      void expression, Token semicolon) {}

  void fieldInitializer(
      InitializerJudgment judgment,
      int location,
      Token thisKeyword,
      Token period,
      Token fieldName,
      Token equals,
      void expression,
      Node initializerField) {
    _store(location, reference: initializerField);
  }

  void forInStatement(
      StatementJudgment judgment,
      int location,
      Token awaitKeyword,
      Token forKeyword,
      Token leftParenthesis,
      Object loopVariable,
      Token identifier,
      Token inKeyword,
      void iterator,
      Token rightParenthesis,
      void body,
      covariant VariableDeclarationBinder loopVariableBinder,
      DartType loopVariableType,
      int writeLocation,
      DartType writeType,
      covariant VariableDeclarationBinder writeVariableBinder,
      Node writeTarget) {
    if (loopVariableBinder != null) {
      _store(loopVariableBinder.fileOffset, inferredType: loopVariableType);
    } else {
      if (writeVariableBinder != null) {
        _store(writeLocation,
            declaration: writeVariableBinder.fileOffset,
            inferredType: writeType);
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
      int location,
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

  void functionDeclaration(
      covariant VariableDeclarationBinder binder, FunctionType inferredType) {
    _store(binder.fileOffset, inferredType: inferredType);
  }

  void functionExpression(
          ExpressionJudgment judgment, int location, DartType inferredType) =>
      genericExpression("functionExpression", location, inferredType);

  @override
  void functionType(int location, DartType type) {
    _store(location, inferredType: type);
  }

  @override
  void functionTypedFormalParameter(int location, DartType type) {
    _store(location, inferredType: type);
  }

  void genericExpression(
      String expressionType, int location, DartType inferredType) {
    _store(location, inferredType: inferredType);
  }

  void ifNull(ExpressionJudgment judgment, int location, void leftOperand,
          Token operator, void rightOperand, DartType inferredType) =>
      genericExpression('ifNull', location, inferredType);

  void ifStatement(
      StatementJudgment judgment,
      int location,
      Token ifKeyword,
      Token leftParenthesis,
      void condition,
      Token rightParenthesis,
      void thenStatement,
      Token elseKeyword,
      void elseStatement) {}

  void indexAssign(ExpressionJudgment judgment, int location, Node writeMember,
      Node combiner, DartType inferredType) {
    _store(location,
        reference: writeMember, inferredType: inferredType, combiner: combiner);
  }

  void intLiteral(ExpressionJudgment judgment, int location, Token literal,
          num value, DartType inferredType) =>
      genericExpression("intLiteral", location, inferredType);

  void invalidInitializer(InitializerJudgment judgment, int location) {}

  void isExpression(
      ExpressionJudgment judgment,
      int location,
      void expression,
      Token isOperator,
      void literalType,
      DartType testedType,
      DartType inferredType) {
    _store(location, literalType: testedType, inferredType: inferredType);
  }

  void isNotExpression(
      ExpressionJudgment judgment,
      int location,
      void expression,
      Token isOperator,
      Token notOperator,
      void literalType,
      DartType type,
      DartType inferredType) {
    _store(location, literalType: type, inferredType: inferredType);
  }

  void labeledStatement(List<Object> labels, void statement) {}

  void listLiteral(
          ExpressionJudgment judgment,
          int location,
          Token constKeyword,
          Object typeArguments,
          Token leftBracket,
          void elements,
          Token rightBracket,
          DartType inferredType) =>
      genericExpression("listLiteral", location, inferredType);

  @override
  void loadLibrary(LoadLibraryJudgment judgment, int location, Node library,
      FunctionType calleeType, DartType inferredType) {
    _store(location,
        loadLibrary: library,
        invokeType: calleeType,
        inferredType: inferredType);
  }

  @override
  void loadLibraryTearOff(LoadLibraryTearOffJudgment judgment, int location,
      Node library, DartType inferredType) {
    _store(location, loadLibrary: library, inferredType: inferredType);
  }

  void logicalExpression(
          ExpressionJudgment judgment,
          int location,
          void leftOperand,
          Token operator,
          void rightOperand,
          DartType inferredType) =>
      genericExpression("logicalExpression", location, inferredType);

  void mapLiteral(
          ExpressionJudgment judgment,
          int location,
          Token constKeyword,
          Object typeArguments,
          Token leftBracket,
          List<Object> entries,
          Token rightBracket,
          DartType inferredType) =>
      genericExpression("mapLiteral", location, inferredType);

  void mapLiteralEntry(
      Object judgment, int fileOffset, void key, Token separator, void value) {
    // TODO(brianwilkerson) Implement this.
  }

  void methodInvocation(
      ExpressionJudgment judgment,
      int resultOffset,
      List<DartType> argumentsTypes,
      bool isImplicitCall,
      Node interfaceMember,
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
      int resultOffset,
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

  void namedFunctionExpression(ExpressionJudgment judgment,
          covariant VariableDeclarationBinder binder, DartType inferredType) =>
      genericExpression(
          "namedFunctionExpression", binder.fileOffset, inferredType);

  void not(ExpressionJudgment judgment, int location, Token operator,
          void operand, DartType inferredType) =>
      genericExpression("not", location, inferredType);

  void nullLiteral(ExpressionJudgment judgment, int location, Token literal,
      bool isSynthetic, DartType inferredType) {
    if (isSynthetic) return null;
    genericExpression("nullLiteral", location, inferredType);
  }

  void propertyAssign(
      ExpressionJudgment judgment,
      int location,
      Node writeMember,
      DartType writeContext,
      Node combiner,
      DartType inferredType) {
    _store(location,
        isWriteReference: true,
        reference: writeMember,
        writeContext: writeContext,
        combiner: combiner,
        inferredType: inferredType);
  }

  void propertyGet(ExpressionJudgment judgment, int location, Node member,
      DartType inferredType) {
    _store(location, reference: member, inferredType: inferredType);
  }

  void propertyGetCall(
      ExpressionJudgment judgment, int location, DartType inferredType) {
    _store(location, isExplicitCall: true);
  }

  void propertySet(
          ExpressionJudgment judgment, int location, DartType inferredType) =>
      genericExpression("propertySet", location, inferredType);

  void redirectingInitializer(
      InitializerJudgment judgment,
      int location,
      Token thisKeyword,
      Token period,
      Token constructorName,
      covariant Object argumentList,
      Node initializerTarget) {
    _store(location, reference: initializerTarget);
  }

  void rethrow_(ExpressionJudgment judgment, int location, Token rethrowKeyword,
          DartType inferredType) =>
      genericExpression('rethrow', location, inferredType);

  void returnStatement(StatementJudgment judgment, int location,
      Token returnKeyword, void expression, Token semicolon) {}

  void statementLabel(covariant void binder, Token label, Token colon) {}

  void staticAssign(ExpressionJudgment judgment, int location, Node writeMember,
      DartType writeContext, Node combiner, DartType inferredType) {
    _store(location,
        reference: writeMember,
        isWriteReference: true,
        writeContext: writeContext,
        combiner: combiner,
        inferredType: inferredType);
  }

  void staticGet(ExpressionJudgment judgment, int location,
      Node expressionTarget, DartType inferredType) {
    _store(location, reference: expressionTarget, inferredType: inferredType);
  }

  void staticInvocation(
      ExpressionJudgment judgment,
      int location,
      Node expressionTarget,
      List<DartType> expressionArgumentsTypes,
      FunctionType calleeType,
      Substitution substitution,
      DartType inferredType) {
    FunctionType invokeType = substitution == null
        ? calleeType
        : substitution.substituteType(calleeType.withoutTypeParameters);
    _store(location,
        invokeType: invokeType ?? const DynamicType(),
        argumentTypes: expressionArgumentsTypes,
        reference: expressionTarget,
        inferredType: inferredType);
  }

  void storeClassReference(int location, Node reference, DartType rawType) {
    // TODO(paulberry): would it be better to use literalType?
    _store(location, reference: reference, inferredType: rawType);
  }

  void storePrefixInfo(int location, int prefixInfo) {
    _store(location, isPrefixReference: true, prefixInfo: prefixInfo);
  }

  void stringConcatenation(
      ExpressionJudgment judgment, int location, DartType inferredType) {
    // We don't need the type - we already know that it is String.
    // Moreover, the file offset for StringConcatenation is `-1`.
  }

  void stringLiteral(ExpressionJudgment judgment, int location, Token literal,
          String value, DartType inferredType) =>
      genericExpression("StringLiteral", location, inferredType);

  void superInitializer(
      InitializerJudgment judgment,
      int location,
      Token superKeyword,
      Token period,
      Token constructorName,
      covariant Object argumentList) {}

  void switchCase(SwitchCaseJudgment judgment, List<Object> labels,
      Token keyword, void expression, Token colon, List<void> statements) {}

  void switchLabel(covariant void binder, Token label, Token colon) {}

  void switchStatement(
      StatementJudgment judgment,
      int location,
      Token switchKeyword,
      Token leftParenthesis,
      void expression,
      Token rightParenthesis,
      Token leftBracket,
      void members,
      Token rightBracket) {}

  void symbolLiteral(ExpressionJudgment judgment, int location, Token poundSign,
          List<Token> components, String value, DartType inferredType) =>
      genericExpression("symbolLiteral", location, inferredType);

  void thisExpression(ExpressionJudgment judgment, int location,
      Token thisKeyword, DartType inferredType) {}

  void throw_(ExpressionJudgment judgment, int location, Token throwKeyword,
          void expression, DartType inferredType) =>
      genericExpression('throw', location, inferredType);

  void tryCatch(StatementJudgment judgment, int location) {}

  void tryFinally(StatementJudgment judgment, int location, Token tryKeyword,
      void body, void catchClauses, Token finallyKeyword, void finallyBlock) {}

  void typeLiteral(ExpressionJudgment judgment, int location,
      Node expressionType, DartType inferredType) {
    _store(location, reference: expressionType, inferredType: inferredType);
  }

  void typeReference(
      int location,
      Token leftBracket,
      List<void> typeArguments,
      Token rightBracket,
      Node reference,
      covariant TypeVariableBinder binder,
      DartType type) {
    _store(location,
        reference: reference,
        declaration: binder?.fileOffset,
        inferredType: type,
        isTypeReference: true);
  }

  void typeVariableDeclaration(int location,
      covariant TypeVariableBinder binder, TypeParameter typeParameter) {
    _storeTypeVariableDeclaration(binder.fileOffset, typeParameter);
    _store(location, declaration: binder.fileOffset);
  }

  void variableAssign(
      ExpressionJudgment judgment,
      int location,
      DartType writeContext,
      covariant VariableDeclarationBinder writeVariableBinder,
      Node combiner,
      DartType inferredType) {
    _store(location,
        declaration: writeVariableBinder?.fileOffset,
        isWriteReference: true,
        writeContext: writeContext,
        combiner: combiner,
        inferredType: inferredType);
  }

  void variableDeclaration(covariant VariableDeclarationBinder binder,
      DartType statementType, DartType inferredType) {
    _store(binder.fileOffset,
        literalType: statementType, inferredType: inferredType);
  }

  void variableGet(
      ExpressionJudgment judgment,
      int location,
      bool isInCascade,
      covariant VariableDeclarationBinder variableBinder,
      DartType inferredType) {
    if (isInCascade) {
      return;
    }
    _store(location,
        declaration: variableBinder?.fileOffset, inferredType: inferredType);
  }

  void voidType(int location, Token token, DartType type) {
    _store(location, inferredType: type);
  }

  void whileStatement(
      StatementJudgment judgment,
      int location,
      Token whileKeyword,
      Token leftParenthesis,
      void condition,
      Token rightParenthesis,
      void body) {}

  void yieldStatement(StatementJudgment judgment, int location,
      Token yieldKeyword, Token star, void expression, Token semicolon) {}

  void _store(int location,
      {List<DartType> argumentTypes,
      Node combiner,
      int declaration,
      DartType inferredType,
      DartType invokeType,
      bool isExplicitCall = false,
      bool isImplicitCall = false,
      bool isPrefixReference = false,
      bool isTypeReference = false,
      bool isWriteReference = false,
      DartType literalType,
      Node loadLibrary,
      int prefixInfo,
      Node reference,
      bool replace = false,
      DartType writeContext}) {
    _validateLocation(location);
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
        isPrefixReference: isPrefixReference,
        isTypeReference: isTypeReference,
        isWriteReference: isWriteReference,
        literalType: literalType,
        loadLibrary: loadLibrary,
        prefixInfo: prefixInfo,
        reference: reference,
        writeContext: writeContext);
  }

  void _storeTypeVariableDeclaration(
      int fileOffset, TypeParameter typeParameter) {
    if (_typeVariableDeclarations.containsKey(fileOffset)) {
      throw new StateError(
          'Type declaration already stored for offset $fileOffset');
    }
    _typeVariableDeclarations[typeParameter] = fileOffset;
  }

  void _unstore(int location) {
    _data.remove(location) == null;
  }

  void _validateLocation(int location) {
    if (location < 0) {
      throw new StateError('Invalid location: $location');
    }
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

/// TODO(paulberry): eventually just use the element directly.
class TypeVariableBinder {
  final int fileOffset;

  TypeVariableBinder(this.fileOffset);
}

/// TODO(paulberry): eventually just use the element directly.
class VariableDeclarationBinder {
  final int fileOffset;

  VariableDeclarationBinder(this.fileOffset);
}
