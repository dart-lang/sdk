// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/fasta/resolution_applier.dart';
import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart';
import 'package:front_end/src/fasta/kernel/kernel_type_variable_builder.dart';
import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart';
import 'package:front_end/src/scanner/token.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/type_algebra.dart';

class ResolutionData {
  final List<DartType> argumentTypes;
  final Node combiner;
  final int declaration;
  final DartType inferredType;
  final DartType invokeType;
  final bool isExplicitCall;
  final bool isImplicitCall;
  final bool isOutline;
  final bool isPrefixReference;
  final bool isTypeReference;
  final bool isWriteReference;
  final Node loadLibrary;
  final int prefixInfo;
  final DartType receiverType;
  final Node reference;
  final DartType writeContext;

  ResolutionData(
      {this.argumentTypes,
      this.combiner,
      this.declaration,
      this.inferredType,
      this.invokeType,
      this.isExplicitCall = false,
      this.isImplicitCall = false,
      this.isOutline = false,
      this.isPrefixReference = false,
      this.isTypeReference = false,
      this.isWriteReference = false,
      this.loadLibrary,
      this.prefixInfo,
      this.receiverType,
      this.reference,
      this.writeContext});
}

/// Type inference listener that records inferred types for later use by
/// [ResolutionApplier].
class ResolutionStorer
    implements TypeInferenceListener<int, Node, int>, TypeInferenceTokensSaver {
  final Map<int, ResolutionData> _data;

  final Map<TypeParameter, int> _typeVariableDeclarations;

  ResolutionStorer(Map<int, ResolutionData> data,
      Map<TypeParameter, int> typeVariableDeclarations)
      : _data = data,
        _typeVariableDeclarations = typeVariableDeclarations;

  @override
  TypeInferenceTokensSaver get typeInferenceTokensSaver => this;

  @override
  AsExpressionTokens asExpressionTokens(Token asOperator) {
    return new AsExpressionTokens(asOperator);
  }

  void asExpression(ExpressionJudgment judgment, int location, void expression,
      AsExpressionTokens tokens, void literalType, DartType inferredType) {
    _store(location, inferredType: inferredType);
  }

  @override
  AssertInitializerTokens assertInitializerTokens(Token assertKeyword,
      Token leftParenthesis, Token comma, Token rightParenthesis) {
    return new AssertInitializerTokens(
        assertKeyword, leftParenthesis, comma, rightParenthesis);
  }

  void assertInitializer(InitializerJudgment judgment, int location,
      AssertInitializerTokens tokens, void condition, void message) {}

  @override
  AssertStatementTokens assertStatementTokens(
      Token assertKeyword,
      Token leftParenthesis,
      Token comma,
      Token rightParenthesis,
      Token semicolon) {
    return new AssertStatementTokens(
        assertKeyword, leftParenthesis, comma, rightParenthesis, semicolon);
  }

  void assertStatement(StatementJudgment judgment, int location,
      AssertStatementTokens Tokens, void condition, void message) {}

  AwaitExpressionTokens awaitExpressionTokens(Token awaitKeyword) {
    return new AwaitExpressionTokens(awaitKeyword);
  }

  void awaitExpression(
          ExpressionJudgment judgment,
          int location,
          AwaitExpressionTokens tokens,
          void expression,
          DartType inferredType) =>
      genericExpression("awaitExpression", location, inferredType);

  Object binderForFunctionDeclaration(
      StatementJudgment judgment, int fileOffset, String name) {
    return new VariableDeclarationBinder(fileOffset, false);
  }

  void binderForStatementLabel(
      StatementJudgment judgment, int fileOffset, String name) {}

  void binderForSwitchLabel(
      SwitchCaseJudgment judgment, int fileOffset, String name) {}

  TypeVariableBinder binderForTypeVariable(
      KernelTypeVariableBuilder builder, int fileOffset, String name) {
    return new TypeVariableBinder(fileOffset);
  }

  Object binderForVariableDeclaration(StatementJudgment judgment,
      int fileOffset, String name, bool forSyntheticToken) {
    return new VariableDeclarationBinder(fileOffset, forSyntheticToken);
  }

  BlockTokens blockTokens(Token leftBracket, Token rightBracket) {
    return new BlockTokens(leftBracket, rightBracket);
  }

  void block(StatementJudgment judgment, int location, BlockTokens tokens,
      List<void> statements) {}

  BoolLiteralTokens boolLiteralTokens(Token literal) {
    return new BoolLiteralTokens(literal);
  }

  void boolLiteral(ExpressionJudgment judgment, int location,
          BoolLiteralTokens tokens, bool value, DartType inferredType) =>
      genericExpression("boolLiteral", location, inferredType);

  BreakStatementTokens breakStatementTokens(
      Token breakKeyword, Token semicolon) {
    return new BreakStatementTokens(breakKeyword, semicolon);
  }

  void breakStatement(StatementJudgment judgment, int location,
      BreakStatementTokens tokens, void label, covariant Object labelBinder) {}

  void cascadeExpression(
      ExpressionJudgment judgment, int location, DartType inferredType) {
    // Overridden so that the type of the expression will not be recorded. We
    // don't need to record the type because the type is always the same as the
    // type of the target, and we don't have the appropriate offset so we can't
    // correctly apply the type even if we recorded it.
  }

  CatchStatementTokens catchStatementTokens(Token onKeyword, Token catchKeyword,
      Token leftParenthesis, Token comma, Token rightParenthesis) {
    return new CatchStatementTokens(
        onKeyword, catchKeyword, leftParenthesis, comma, rightParenthesis);
  }

  void catchStatement(
      Catch judgment,
      int location,
      CatchStatementTokens tokens,
      void type,
      void body,
      covariant VariableDeclarationBinder exceptionBinder,
      DartType exceptionType,
      covariant VariableDeclarationBinder stackTraceBinder,
      DartType stackTraceType) {
    if (exceptionBinder != null) {
      _store(exceptionBinder.fileOffset,
          inferredType: exceptionType,
          isSynthetic: exceptionBinder.isSynthetic);
    }

    if (stackTraceBinder != null) {
      _store(stackTraceBinder.fileOffset, inferredType: stackTraceType);
    }
  }

  ConditionalExpressionTokens conditionalExpressionTokens(
      Token question, Token colon) {
    return new ConditionalExpressionTokens(question, colon);
  }

  void conditionalExpression(
          ExpressionJudgment judgment,
          int location,
          void condition,
          ConditionalExpressionTokens tokens,
          void thenExpression,
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

  ContinueStatementTokens continueStatementTokens(
      Token continueKeyword, Token semicolon) {
    return new ContinueStatementTokens(continueKeyword, semicolon);
  }

  void continueStatement(
      StatementJudgment judgment,
      int location,
      ContinueStatementTokens tokens,
      void label,
      covariant Object labelBinder) {}

  ContinueSwitchStatementTokens continueSwitchStatementTokens(
      Token continueKeyword, Token semicolon) {
    return new ContinueSwitchStatementTokens(continueKeyword, semicolon);
  }

  void continueSwitchStatement(
      StatementJudgment judgment,
      int location,
      ContinueSwitchStatementTokens tokens,
      void label,
      covariant Object labelBinder) {}

  void deferredCheck(
      ExpressionJudgment judgment, int location, DartType inferredType) {
    // This judgment has no semantic value for Analyzer.
  }

  DoStatementTokens doStatementTokens(Token doKeyword, Token whileKeyword,
      Token leftParenthesis, Token rightParenthesis, Token semicolon) {
    return new DoStatementTokens(
        doKeyword, whileKeyword, leftParenthesis, rightParenthesis, semicolon);
  }

  void doStatement(StatementJudgment judgment, int location,
      DoStatementTokens tokens, void body, void condition) {}

  DoubleLiteralTokens doubleLiteralTokens(Token literal) {
    return new DoubleLiteralTokens(literal);
  }

  void doubleLiteral(ExpressionJudgment judgment, int location,
          DoubleLiteralTokens tokens, double value, DartType inferredType) =>
      genericExpression("doubleLiteral", location, inferredType);

  EmptyStatementTokens emptyStatementTokens(Token semicolon) {
    return new EmptyStatementTokens(semicolon);
  }

  void emptyStatement(EmptyStatementTokens tokens) {}

  ExpressionStatementTokens expressionStatementTokens(Token semicolon) {
    return new ExpressionStatementTokens(semicolon);
  }

  void expressionStatement(StatementJudgment judgment, int location,
      void expression, ExpressionStatementTokens tokens) {}

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

  ForInStatementTokens forInStatementTokens(
      Token awaitKeyword,
      Token forKeyword,
      Token leftParenthesis,
      Token inKeyword,
      Token rightParenthesis) {
    return new ForInStatementTokens(
        awaitKeyword, forKeyword, leftParenthesis, inKeyword, rightParenthesis);
  }

  void forInStatement(
      StatementJudgment judgment,
      int location,
      ForInStatementTokens tokens,
      Object loopVariable,
      void iterator,
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

  ForStatementTokens forStatementTokens(
    Token forKeyword,
    Token leftParenthesis,
    Token leftSeparator,
    Token rightSeparator,
    Token rightParenthesis,
  ) {
    return new ForStatementTokens(forKeyword, leftParenthesis, leftSeparator,
        rightSeparator, rightParenthesis);
  }

  void forStatement(
      StatementJudgment judgment,
      int location,
      ForStatementTokens tokens,
      void variableDeclarationList,
      void initialization,
      void condition,
      void updaters,
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

  IfNullTokens ifNullTokens(Token operator) {
    return new IfNullTokens(operator);
  }

  void ifNull(ExpressionJudgment judgment, int location, void leftOperand,
          IfNullTokens tokens, void rightOperand, DartType inferredType) =>
      genericExpression('ifNull', location, inferredType);

  IfStatementTokens ifStatementTokens(Token ifKeyword, Token leftParenthesis,
      Token rightParenthesis, Token elseKeyword) {
    return new IfStatementTokens(
        ifKeyword, leftParenthesis, rightParenthesis, elseKeyword);
  }

  void ifStatement(
      StatementJudgment judgment,
      int location,
      IfStatementTokens tokens,
      void condition,
      void thenStatement,
      void elseStatement) {}

  void indexAssign(
      ExpressionJudgment judgment,
      int location,
      DartType receiverType,
      Node writeMember,
      Node combiner,
      DartType inferredType) {
    _store(location,
        reference: writeMember,
        inferredType: inferredType,
        combiner: combiner,
        receiverType: receiverType);
  }

  IntLiteralTokens intLiteralTokens(Token literal) {
    return new IntLiteralTokens(literal);
  }

  void intLiteral(ExpressionJudgment judgment, int location,
          IntLiteralTokens tokens, num value, DartType inferredType) =>
      genericExpression("intLiteral", location, inferredType);

  @override
  void invalidAssignment(ExpressionJudgment judgment, int location) {
    _store(location, inferredType: const DynamicType());
  }

  void invalidInitializer(InitializerJudgment judgment, int location) {}

  IsExpressionTokens isExpressionTokens(Token isOperator) {
    return new IsExpressionTokens(isOperator);
  }

  void isExpression(ExpressionJudgment judgment, int location, void expression,
      IsExpressionTokens tokens, void literalType, DartType inferredType) {
    _store(location, inferredType: inferredType);
  }

  IsNotExpressionTokens isNotExpressionTokens(
      Token isOperator, Token notOperator) {
    return new IsNotExpressionTokens(isOperator, notOperator);
  }

  void isNotExpression(
      ExpressionJudgment judgment,
      int location,
      void expression,
      IsNotExpressionTokens tokens,
      void literalType,
      DartType inferredType) {
    _store(location, inferredType: inferredType);
  }

  void labeledStatement(List<Object> labels, void statement) {}

  ListLiteralTokens listLiteralTokens(
      Token constKeyword, Token leftBracket, Token rightBracket) {
    return new ListLiteralTokens(constKeyword, leftBracket, rightBracket);
  }

  void listLiteral(
          ExpressionJudgment judgment,
          int location,
          ListLiteralTokens tokens,
          Object typeArguments,
          void elements,
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

  LogicalExpressionTokens logicalExpressionTokens(Token operatorToken) {
    return new LogicalExpressionTokens(operatorToken);
  }

  void logicalExpression(
          ExpressionJudgment judgment,
          int location,
          void leftOperand,
          LogicalExpressionTokens tokens,
          void rightOperand,
          DartType inferredType) =>
      genericExpression("logicalExpression", location, inferredType);

  MapLiteralTokens mapLiteralTokens(
      Token constKeyword, Token leftBracket, Token rightBracket) {
    return new MapLiteralTokens(constKeyword, leftBracket, rightBracket);
  }

  void mapLiteral(
          ExpressionJudgment judgment,
          int location,
          MapLiteralTokens tokens,
          Object typeArguments,
          List<Object> entries,
          DartType inferredType) =>
      genericExpression("mapLiteral", location, inferredType);

  void mapLiteralEntry(
      Object judgment, int fileOffset, void key, Token separator, void value) {
    // TODO(brianwilkerson) Implement this.
  }

  void methodInvocation(
      ExpressionJudgment judgment,
      int resultOffset,
      DartType receiverType,
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
        receiverType: receiverType,
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

  NotTokens notTokens(Token operator) {
    return new NotTokens(operator);
  }

  void not(ExpressionJudgment judgment, int location, NotTokens tokens,
          void operand, DartType inferredType) =>
      genericExpression("not", location, inferredType);

  NullLiteralTokens nullLiteralTokens(Token literal) {
    return new NullLiteralTokens(literal);
  }

  void nullLiteral(ExpressionJudgment judgment, int location,
      NullLiteralTokens tokens, bool isSynthetic, DartType inferredType) {
    if (isSynthetic) return null;
    genericExpression("nullLiteral", location, inferredType);
  }

  void propertyAssign(
      ExpressionJudgment judgment,
      int location,
      DartType receiverType,
      Node writeMember,
      DartType writeContext,
      Node combiner,
      DartType inferredType) {
    _store(location,
        isWriteReference: true,
        reference: writeMember,
        writeContext: writeContext,
        combiner: combiner,
        inferredType: inferredType,
        receiverType: receiverType);
  }

  void propertyGet(
      ExpressionJudgment judgment,
      int location,
      bool forSyntheticToken,
      DartType receiverType,
      Node member,
      DartType inferredType) {
    _store(location,
        reference: member,
        inferredType: inferredType,
        isSynthetic: forSyntheticToken,
        receiverType: receiverType);
  }

  void propertyGetCall(
      ExpressionJudgment judgment, int location, DartType inferredType) {
    _store(location, isExplicitCall: true);
  }

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

  RethrowTokens rethrowTokens(Token rethrowKeyword) {
    return new RethrowTokens(rethrowKeyword);
  }

  void rethrow_(ExpressionJudgment judgment, int location, RethrowTokens tokens,
          DartType inferredType) =>
      genericExpression('rethrow', location, inferredType);

  ReturnStatementTokens returnStatementTokens(
      Token returnKeyword, Token semicolon) {
    return new ReturnStatementTokens(returnKeyword, semicolon);
  }

  void returnStatement(StatementJudgment judgment, int location,
      ReturnStatementTokenstokens, void expression) {}

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

  @override
  void storeUnresolved(int location) {
    _unstore(location);
    _store(location, inferredType: const DynamicType());
  }

  void stringConcatenation(
      ExpressionJudgment judgment, int location, DartType inferredType) {
    // We don't need the type - we already know that it is String.
    // Moreover, the file offset for StringConcatenation is `-1`.
  }

  StringLiteralTokens stringLiteralTokens(Token literal) {
    return new StringLiteralTokens(literal);
  }

  void stringLiteral(ExpressionJudgment judgment, int location,
          StringLiteralTokens tokens, String value, DartType inferredType) =>
      genericExpression("StringLiteral", location, inferredType);

  SuperInitializerTokens superInitializerTokens(
      Token superKeyword, Token period, Token constructorName) {
    return new SuperInitializerTokens(superKeyword, period, constructorName);
  }

  void superInitializer(InitializerJudgment judgment, int location,
      SuperInitializerTokens tokens, covariant Object argumentList) {}

  SwitchCaseTokens switchCaseTokens(Token keyword, Token colon) {
    return new SwitchCaseTokens(keyword, colon);
  }

  void switchCase(SwitchCaseJudgment judgment, List<Object> labels,
      Token keyword, void expression, Token colon, List<void> statements) {}

  void switchLabel(covariant void binder, Token label, Token colon) {}

  SwitchStatementTokens switchStatementTokens(
      Token switchKeyword,
      Token leftParenthesis,
      Token rightParenthesis,
      Token leftBracket,
      Token rightBracket) {
    return new SwitchStatementTokens(switchKeyword, leftParenthesis,
        rightParenthesis, leftBracket, rightBracket);
  }

  void switchStatement(StatementJudgment judgment, int location,
      SwitchStatementTokens tokens, void expression, void members) {}

  void symbolLiteral(ExpressionJudgment judgment, int location, Token poundSign,
          List<Token> components, String value, DartType inferredType) =>
      genericExpression("symbolLiteral", location, inferredType);

  ThisExpressionTokens thisExpressionTokens(Token thisKeyword) {
    return new ThisExpressionTokens(thisKeyword);
  }

  void thisExpression(ExpressionJudgment judgment, int location,
      ThisExpressionTokens token, DartType inferredType) {}

  ThrowTokens throwTokens(Token throwKeyword) {
    return new ThrowTokens(throwKeyword);
  }

  void throw_(ExpressionJudgment judgment, int location, ThrowTokens tokens,
          void expression, DartType inferredType) =>
      genericExpression('throw', location, inferredType);

  void tryCatch(StatementJudgment judgment, int location) {}

  TryFinallyTokens tryFinallyTokens(Token tryKeyword, Token finallyKeyword) {
    return new TryFinallyTokens(tryKeyword, finallyKeyword);
  }

  void tryFinally(
      StatementJudgment judgment,
      int location,
      TryFinallyTokens tokens,
      void body,
      void catchClauses,
      void finallyBlock) {}

  void typeLiteral(ExpressionJudgment judgment, int location,
      Node expressionType, DartType inferredType) {
    _store(location, reference: expressionType, inferredType: inferredType);
  }

  void typeReference(
      int location,
      bool forSyntheticToken,
      Token leftBracket,
      List<void> typeArguments,
      Token rightBracket,
      Node reference,
      covariant TypeVariableBinder binder,
      DartType type) {
    _store(location,
        isSynthetic: forSyntheticToken,
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

  void variableDeclaration(
      covariant VariableDeclarationBinder binder, DartType inferredType) {
    _store(binder.fileOffset,
        inferredType: inferredType, isSynthetic: binder.isSynthetic);
  }

  void variableGet(
      ExpressionJudgment judgment,
      int location,
      bool forSyntheticToken,
      bool isInCascade,
      covariant VariableDeclarationBinder variableBinder,
      DartType inferredType) {
    if (isInCascade) {
      return;
    }
    _store(location,
        isSynthetic: forSyntheticToken,
        declaration: variableBinder?.fileOffset,
        inferredType: inferredType);
  }

  void voidType(int location, Token token, DartType type) {
    _store(location, inferredType: type);
  }

  WhileStatementTokens whileStatementTokens(
      Token whileKeyword, Token leftParenthesis, Token rightParenthesis) {
    return new WhileStatementTokens(
        whileKeyword, leftParenthesis, rightParenthesis);
  }

  void whileStatement(StatementJudgment judgment, int location,
      WhileStatementTokens tokens, void condition, void body) {}

  YieldStatementTokens yieldStatementTokens(
      Token yieldKeyword, Token star, Token semicolon) {
    return new YieldStatementTokens(yieldKeyword, star, semicolon);
  }

  void yieldStatement(StatementJudgment judgment, int location,
      YieldStatementTokens tokens, void expression) {}

  void _store(int location,
      {List<DartType> argumentTypes,
      Node combiner,
      int declaration,
      DartType inferredType,
      DartType invokeType,
      bool isExplicitCall = false,
      bool isImplicitCall = false,
      bool isPrefixReference = false,
      bool isSynthetic = false,
      bool isTypeReference = false,
      bool isWriteReference = false,
      Node loadLibrary,
      int prefixInfo,
      DartType receiverType,
      Node reference,
      bool replace = false,
      DartType writeContext}) {
    _validateLocation(location);
    var encodedLocation = 2 * location + (isSynthetic ? 1 : 0);
    if (!replace) {
      var existing = _data[encodedLocation];
      if (existing != null) {
        if (existing.isOutline) {
          return;
        }
        throw new StateError('Data already stored for (offset=$location, '
            'isSynthetic=$isSynthetic)');
      }
    }
    _data[encodedLocation] = new ResolutionData(
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
        loadLibrary: loadLibrary,
        prefixInfo: prefixInfo,
        receiverType: receiverType,
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

  void _unstore(int location, {bool isSynthetic: false}) {
    var encodedLocation = 2 * location + (isSynthetic ? 1 : 0);
    _data.remove(encodedLocation) == null;
  }

  void _validateLocation(int location) {
    if (location < 0) {
      throw new StateError('Invalid location: $location');
    }
  }

  NamedExpressionTokens namedExpressionTokens(Token nameToken, Token colon) {
    return new NamedExpressionTokens(nameToken, colon);
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
  final bool isSynthetic;

  VariableDeclarationBinder(this.fileOffset, this.isSynthetic);
}
