// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/ast.dart';

/// The instance of [AstFactoryImpl].
final AstFactoryImpl astFactory = AstFactoryImpl();

class AstFactoryImpl {
  CommentImpl blockComment(List<Token> tokens) =>
      CommentImpl.createBlockComment(tokens);

  CompilationUnitImpl compilationUnit(
          {required Token beginToken,
          ScriptTag? scriptTag,
          List<Directive>? directives,
          List<CompilationUnitMember>? declarations,
          required Token endToken,
          required FeatureSet featureSet,
          // TODO(dantup): LineInfo should be made required and non-nullable
          //   when breaking API changes can be made. Callers that do not
          //   provide lineInfos may have offsets incorrectly mapped to line/col
          //   for LSP.
          LineInfo? lineInfo}) =>
      CompilationUnitImpl(beginToken, scriptTag as ScriptTagImpl?, directives,
          declarations, endToken, featureSet, lineInfo ?? LineInfo([0]));

  CommentImpl documentationComment(List<Token> tokens,
          [List<CommentReference>? references]) =>
      CommentImpl.createDocumentationCommentWithReferences(
          tokens, references ?? <CommentReference>[]);

  CommentImpl endOfLineComment(List<Token> tokens) =>
      CommentImpl.createEndOfLineComment(tokens);

  ExtensionOverrideImpl extensionOverride(
          {required Identifier extensionName,
          TypeArgumentList? typeArguments,
          required ArgumentList argumentList}) =>
      ExtensionOverrideImpl(
          extensionName as IdentifierImpl,
          typeArguments as TypeArgumentListImpl?,
          argumentList as ArgumentListImpl);

  FieldFormalParameterImpl fieldFormalParameter2(
          {Comment? comment,
          List<Annotation>? metadata,
          Token? covariantKeyword,
          Token? requiredKeyword,
          Token? keyword,
          TypeAnnotation? type,
          required Token thisKeyword,
          required Token period,
          required Token name,
          TypeParameterList? typeParameters,
          FormalParameterList? parameters,
          Token? question}) =>
      FieldFormalParameterImpl(
          comment as CommentImpl?,
          metadata,
          covariantKeyword,
          requiredKeyword,
          keyword,
          type as TypeAnnotationImpl?,
          thisKeyword,
          period,
          name,
          typeParameters as TypeParameterListImpl?,
          parameters as FormalParameterListImpl?,
          question);

  FormalParameterListImpl formalParameterList(
          Token leftParenthesis,
          List<FormalParameter> parameters,
          Token? leftDelimiter,
          Token? rightDelimiter,
          Token rightParenthesis) =>
      FormalParameterListImpl(leftParenthesis, parameters, leftDelimiter,
          rightDelimiter, rightParenthesis);

  FunctionTypedFormalParameterImpl functionTypedFormalParameter2(
          {Comment? comment,
          List<Annotation>? metadata,
          Token? covariantKeyword,
          Token? requiredKeyword,
          TypeAnnotation? returnType,
          required Token name,
          TypeParameterList? typeParameters,
          required FormalParameterList parameters,
          Token? question}) =>
      FunctionTypedFormalParameterImpl(
          comment as CommentImpl?,
          metadata,
          covariantKeyword,
          requiredKeyword,
          returnType as TypeAnnotationImpl?,
          name,
          typeParameters as TypeParameterListImpl?,
          parameters as FormalParameterListImpl,
          question);

  ImplicitCallReferenceImpl implicitCallReference({
    required Expression expression,
    required MethodElement staticElement,
    required TypeArgumentList? typeArguments,
    required List<DartType> typeArgumentTypes,
  }) =>
      ImplicitCallReferenceImpl(expression as ExpressionImpl,
          staticElement: staticElement,
          typeArguments: typeArguments as TypeArgumentListImpl?,
          typeArgumentTypes: typeArgumentTypes);

  IndexExpressionImpl indexExpressionForCascade2(
          {required Token period,
          Token? question,
          required Token leftBracket,
          required Expression index,
          required Token rightBracket}) =>
      IndexExpressionImpl.forCascade(
          period, question, leftBracket, index as ExpressionImpl, rightBracket);

  IndexExpressionImpl indexExpressionForTarget2(
          {required Expression target,
          Token? question,
          required Token leftBracket,
          required Expression index,
          required Token rightBracket}) =>
      IndexExpressionImpl.forTarget(target as ExpressionImpl, question,
          leftBracket, index as ExpressionImpl, rightBracket);

  InstanceCreationExpressionImpl instanceCreationExpression(Token? keyword,
          ConstructorName constructorName, ArgumentList argumentList,
          {TypeArgumentList? typeArguments}) =>
      InstanceCreationExpressionImpl(
          keyword,
          constructorName as ConstructorNameImpl,
          argumentList as ArgumentListImpl,
          typeArguments: typeArguments as TypeArgumentListImpl?);

  InterpolationExpressionImpl interpolationExpression(
          Token leftBracket, Expression expression, Token? rightBracket) =>
      InterpolationExpressionImpl(
          leftBracket, expression as ExpressionImpl, rightBracket);

  IsExpressionImpl isExpression(Expression expression, Token isOperator,
          Token? notOperator, TypeAnnotation type) =>
      IsExpressionImpl(expression as ExpressionImpl, isOperator, notOperator,
          type as TypeAnnotationImpl);

  LabeledStatementImpl labeledStatement(
          List<Label> labels, Statement statement) =>
      LabeledStatementImpl(labels, statement as StatementImpl);

  LibraryIdentifierImpl libraryIdentifier(List<SimpleIdentifier> components) =>
      LibraryIdentifierImpl(components);

  ListLiteralImpl listLiteral(
      Token? constKeyword,
      TypeArgumentList? typeArguments,
      Token leftBracket,
      List<CollectionElement> elements,
      Token rightBracket) {
    if (elements is List<Expression>) {
      return ListLiteralImpl(
          constKeyword,
          typeArguments as TypeArgumentListImpl?,
          leftBracket,
          elements,
          rightBracket);
    }
    return ListLiteralImpl.experimental(
        constKeyword,
        typeArguments as TypeArgumentListImpl?,
        leftBracket,
        elements,
        rightBracket);
  }

  NativeFunctionBodyImpl nativeFunctionBody(
          Token nativeKeyword, StringLiteral? stringLiteral, Token semicolon) =>
      NativeFunctionBodyImpl(
          nativeKeyword, stringLiteral as StringLiteralImpl?, semicolon);

  NodeListImpl<E> nodeList<E extends AstNode>(AstNode owner) =>
      NodeListImpl<E>(owner as AstNodeImpl);

  ParenthesizedExpressionImpl parenthesizedExpression(Token leftParenthesis,
          Expression expression, Token rightParenthesis) =>
      ParenthesizedExpressionImpl(
          leftParenthesis, expression as ExpressionImpl, rightParenthesis);

  PostfixExpressionImpl postfixExpression(Expression operand, Token operator) =>
      PostfixExpressionImpl(operand as ExpressionImpl, operator);

  PrefixedIdentifierImpl prefixedIdentifier(
          SimpleIdentifier prefix, Token period, SimpleIdentifier identifier) =>
      PrefixedIdentifierImpl(prefix as SimpleIdentifierImpl, period,
          identifier as SimpleIdentifierImpl);

  PrefixExpressionImpl prefixExpression(Token operator, Expression operand) =>
      PrefixExpressionImpl(operator, operand as ExpressionImpl);

  PropertyAccessImpl propertyAccess(
          Expression? target, Token operator, SimpleIdentifier propertyName) =>
      PropertyAccessImpl(target as ExpressionImpl?, operator,
          propertyName as SimpleIdentifierImpl);

  RedirectingConstructorInvocationImpl redirectingConstructorInvocation(
          Token thisKeyword,
          Token? period,
          SimpleIdentifier? constructorName,
          ArgumentList argumentList) =>
      RedirectingConstructorInvocationImpl(
          thisKeyword,
          period,
          constructorName as SimpleIdentifierImpl?,
          argumentList as ArgumentListImpl);

  RethrowExpressionImpl rethrowExpression(Token rethrowKeyword) =>
      RethrowExpressionImpl(rethrowKeyword);

  ReturnStatementImpl returnStatement(
          Token returnKeyword, Expression? expression, Token semicolon) =>
      ReturnStatementImpl(
          returnKeyword, expression as ExpressionImpl?, semicolon);

  ScriptTagImpl scriptTag(Token scriptTag) => ScriptTagImpl(scriptTag);

  SetOrMapLiteralImpl setOrMapLiteral(
          {Token? constKeyword,
          TypeArgumentList? typeArguments,
          required Token leftBracket,
          required List<CollectionElement> elements,
          required Token rightBracket}) =>
      SetOrMapLiteralImpl(constKeyword, typeArguments as TypeArgumentListImpl?,
          leftBracket, elements, rightBracket);

  ShowClauseImpl showClause(
          {required Token showKeyword,
          required List<ShowHideClauseElement> elements}) =>
      ShowClauseImpl(showKeyword, elements);

  ShowHideElementImpl showHideElement(
          {required Token? modifier, required SimpleIdentifier name}) =>
      ShowHideElementImpl(modifier, name);

  SimpleFormalParameterImpl simpleFormalParameter2(
          {Comment? comment,
          List<Annotation>? metadata,
          Token? covariantKeyword,
          Token? requiredKeyword,
          Token? keyword,
          TypeAnnotation? type,
          required Token? name}) =>
      SimpleFormalParameterImpl(
          comment as CommentImpl?,
          metadata,
          covariantKeyword,
          requiredKeyword,
          keyword,
          type as TypeAnnotationImpl?,
          name);

  SimpleIdentifierImpl simpleIdentifier(Token token,
      {bool isDeclaration = false}) {
    if (isDeclaration) {
      return DeclaredSimpleIdentifier(token);
    }
    return SimpleIdentifierImpl(token);
  }

  SimpleStringLiteralImpl simpleStringLiteral(Token literal, String value) =>
      SimpleStringLiteralImpl(literal, value);

  SpreadElementImpl spreadElement(
          {required Token spreadOperator, required Expression expression}) =>
      SpreadElementImpl(spreadOperator, expression as ExpressionImpl);

  StringInterpolationImpl stringInterpolation(
          List<InterpolationElement> elements) =>
      StringInterpolationImpl(elements);

  SuperConstructorInvocationImpl superConstructorInvocation(
          Token superKeyword,
          Token? period,
          SimpleIdentifier? constructorName,
          ArgumentList argumentList) =>
      SuperConstructorInvocationImpl(
          superKeyword,
          period,
          constructorName as SimpleIdentifierImpl?,
          argumentList as ArgumentListImpl);

  SuperExpressionImpl superExpression(Token superKeyword) =>
      SuperExpressionImpl(superKeyword);

  SuperFormalParameterImpl superFormalParameter(
          {Comment? comment,
          List<Annotation>? metadata,
          Token? covariantKeyword,
          Token? requiredKeyword,
          Token? keyword,
          TypeAnnotation? type,
          required Token superKeyword,
          required Token period,
          required Token name,
          TypeParameterList? typeParameters,
          FormalParameterList? parameters,
          Token? question}) =>
      SuperFormalParameterImpl(
          comment as CommentImpl?,
          metadata,
          covariantKeyword,
          requiredKeyword,
          keyword,
          type as TypeAnnotationImpl?,
          superKeyword,
          period,
          name,
          typeParameters as TypeParameterListImpl?,
          parameters as FormalParameterListImpl?,
          question);

  SwitchCaseImpl switchCase(List<Label> labels, Token keyword,
          Expression expression, Token colon, List<Statement> statements) =>
      SwitchCaseImpl(
          labels, keyword, expression as ExpressionImpl, colon, statements);

  SwitchDefaultImpl switchDefault(List<Label> labels, Token keyword,
          Token colon, List<Statement> statements) =>
      SwitchDefaultImpl(labels, keyword, colon, statements);

  SwitchStatementImpl switchStatement(
          Token switchKeyword,
          Token leftParenthesis,
          Expression expression,
          Token rightParenthesis,
          Token leftBracket,
          List<SwitchMember> members,
          Token rightBracket) =>
      SwitchStatementImpl(
          switchKeyword,
          leftParenthesis,
          expression as ExpressionImpl,
          rightParenthesis,
          leftBracket,
          members,
          rightBracket);

  SymbolLiteralImpl symbolLiteral(Token poundSign, List<Token> components) =>
      SymbolLiteralImpl(poundSign, components);

  ThisExpressionImpl thisExpression(Token thisKeyword) =>
      ThisExpressionImpl(thisKeyword);

  ThrowExpressionImpl throwExpression(
          Token throwKeyword, Expression expression) =>
      ThrowExpressionImpl(throwKeyword, expression as ExpressionImpl);

  TryStatementImpl tryStatement(
          Token tryKeyword,
          Block body,
          List<CatchClause> catchClauses,
          Token? finallyKeyword,
          Block? finallyBlock) =>
      TryStatementImpl(tryKeyword, body as BlockImpl, catchClauses,
          finallyKeyword, finallyBlock as BlockImpl?);

  TypeArgumentListImpl typeArgumentList(Token leftBracket,
          List<TypeAnnotation> arguments, Token rightBracket) =>
      TypeArgumentListImpl(leftBracket, arguments, rightBracket);

  TypeLiteralImpl typeLiteral({required NamedType typeName}) =>
      TypeLiteralImpl(typeName as NamedTypeImpl);

  TypeParameterListImpl typeParameterList(Token leftBracket,
          List<TypeParameter> typeParameters, Token rightBracket) =>
      TypeParameterListImpl(leftBracket, typeParameters, rightBracket);

  VariableDeclarationStatementImpl variableDeclarationStatement(
          VariableDeclarationList variableList, Token semicolon) =>
      VariableDeclarationStatementImpl(
          variableList as VariableDeclarationListImpl, semicolon);

  WhileStatementImpl whileStatement(Token whileKeyword, Token leftParenthesis,
          Expression condition, Token rightParenthesis, Statement body) =>
      WhileStatementImpl(whileKeyword, leftParenthesis,
          condition as ExpressionImpl, rightParenthesis, body as StatementImpl);

  WithClauseImpl withClause(Token withKeyword, List<NamedType> mixinTypes) =>
      WithClauseImpl(withKeyword, mixinTypes);

  YieldStatementImpl yieldStatement(Token yieldKeyword, Token? star,
          Expression expression, Token semicolon) =>
      YieldStatementImpl(
          yieldKeyword, star, expression as ExpressionImpl, semicolon);
}
