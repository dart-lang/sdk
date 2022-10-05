// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:meta/meta.dart';

/// The class `AstTestFactory` defines utility methods that can be used to
/// create AST nodes. The nodes that are created are complete in the sense that
/// all of the tokens that would have been
/// associated with the nodes by a parser are also created, but the token stream
/// is not constructed. None of the nodes are resolved.
///
/// The general pattern is for the name of the factory method to be the same as
/// the name of the class of AST node being created. There are two notable
/// exceptions. The first is for methods creating nodes that are part of a
/// cascade expression. These methods are all prefixed with 'cascaded'. The
/// second is places where a shorter name seemed unambiguous and easier to read,
/// such as using 'identifier' rather than 'prefixedIdentifier', or 'integer'
/// rather than 'integerLiteral'.
@internal
class AstTestFactory {
  static AssignmentExpressionImpl assignmentExpression(Expression leftHandSide,
          TokenType operator, Expression rightHandSide) =>
      AssignmentExpressionImpl(
        leftHandSide: leftHandSide as ExpressionImpl,
        operator: TokenFactory.tokenFromType(operator),
        rightHandSide: rightHandSide as ExpressionImpl,
      );

  static ConstructorDeclarationImpl constructorDeclaration(
          Identifier returnType,
          String? name,
          FormalParameterList parameters,
          List<ConstructorInitializer> initializers) =>
      ConstructorDeclarationImpl(
        comment: null,
        metadata: null,
        externalKeyword: TokenFactory.tokenFromKeyword(Keyword.EXTERNAL),
        constKeyword: null,
        factoryKeyword: null,
        returnType: returnType as IdentifierImpl,
        period:
            name == null ? null : TokenFactory.tokenFromType(TokenType.PERIOD),
        name: name == null ? null : identifier3(name).token,
        parameters: parameters as FormalParameterListImpl,
        separator: initializers.isEmpty
            ? null
            : TokenFactory.tokenFromType(TokenType.PERIOD),
        initializers: initializers,
        redirectedConstructor: null,
        body: EmptyFunctionBodyImpl(
          semicolon: TokenFactory.tokenFromType(TokenType.SEMICOLON),
        ),
      );

  static CommentImpl documentationComment(
      List<Token> tokens, List<CommentReference> references) {
    return astFactory.documentationComment(tokens, references);
  }

  static ExportDirectiveImpl exportDirective(
          List<Annotation> metadata, String uri,
          [List<Combinator> combinators = const []]) =>
      ExportDirectiveImpl(
        comment: null,
        metadata: metadata,
        exportKeyword: TokenFactory.tokenFromKeyword(Keyword.EXPORT),
        uri: string2(uri),
        configurations: null,
        combinators: combinators,
        semicolon: TokenFactory.tokenFromType(TokenType.SEMICOLON),
      );

  static ExportDirectiveImpl exportDirective2(String uri,
          [List<Combinator> combinators = const []]) =>
      exportDirective([], uri, combinators);

  static ExtensionDeclarationImpl extensionDeclaration(
          {required String name,
          required bool isExtensionTypeDeclaration,
          TypeParameterList? typeParameters,
          required TypeAnnotation extendedType,
          ShowClause? showClause,
          HideClause? hideClause,
          List<ClassMember> members = const []}) =>
      ExtensionDeclarationImpl(
        comment: null,
        metadata: null,
        extensionKeyword: TokenFactory.tokenFromKeyword(Keyword.EXTENSION),
        typeKeyword: isExtensionTypeDeclaration
            ? TokenFactory.tokenFromString('type')
            : null,
        name: identifier3(name).token,
        typeParameters: typeParameters as TypeParameterListImpl?,
        onKeyword: TokenFactory.tokenFromKeyword(Keyword.ON),
        extendedType: extendedType as TypeAnnotationImpl,
        showClause: showClause as ShowClauseImpl?,
        hideClause: hideClause as HideClauseImpl?,
        leftBracket: TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET),
        members: members,
        rightBracket: TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET),
      );

  static ExtensionOverrideImpl extensionOverride(
          {required Identifier extensionName,
          TypeArgumentList? typeArguments,
          required ArgumentList argumentList}) =>
      astFactory.extensionOverride(
          extensionName: extensionName,
          typeArguments: typeArguments,
          argumentList: argumentList);

  static FieldDeclarationImpl fieldDeclaration(bool isStatic, Keyword? keyword,
          TypeAnnotation? type, List<VariableDeclaration> variables,
          {bool isAbstract = false, bool isExternal = false}) =>
      FieldDeclarationImpl(
        comment: null,
        metadata: null,
        augmentKeyword: null,
        covariantKeyword: null,
        abstractKeyword:
            isAbstract ? TokenFactory.tokenFromKeyword(Keyword.ABSTRACT) : null,
        externalKeyword:
            isExternal ? TokenFactory.tokenFromKeyword(Keyword.EXTERNAL) : null,
        staticKeyword:
            isStatic ? TokenFactory.tokenFromKeyword(Keyword.STATIC) : null,
        fieldList: variableDeclarationList(keyword, type, variables),
        semicolon: TokenFactory.tokenFromType(TokenType.SEMICOLON),
      );

  static FieldDeclarationImpl fieldDeclaration2(bool isStatic, Keyword? keyword,
          List<VariableDeclaration> variables) =>
      fieldDeclaration(isStatic, keyword, null, variables);

  static FormalParameterListImpl formalParameterList(
          [List<FormalParameter> parameters = const []]) =>
      astFactory.formalParameterList(
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          parameters,
          null,
          null,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN));

  static SimpleIdentifierImpl identifier3(String lexeme) =>
      astFactory.simpleIdentifier(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, lexeme));

  static List<SimpleIdentifier> identifierList(List<String> identifiers) {
    return identifiers
        .map((String identifier) => identifier3(identifier))
        .toList();
  }

  static ImportDirectiveImpl importDirective(List<Annotation> metadata,
          String uri, bool isDeferred, String? prefix,
          [List<Combinator> combinators = const []]) =>
      ImportDirectiveImpl(
        comment: null,
        metadata: metadata,
        importKeyword: TokenFactory.tokenFromKeyword(Keyword.IMPORT),
        uri: string2(uri),
        configurations: null,
        deferredKeyword: !isDeferred
            ? null
            : TokenFactory.tokenFromKeyword(Keyword.DEFERRED),
        asKeyword:
            prefix == null ? null : TokenFactory.tokenFromKeyword(Keyword.AS),
        prefix: prefix == null ? null : identifier3(prefix),
        combinators: combinators,
        semicolon: TokenFactory.tokenFromType(TokenType.SEMICOLON),
      );

  static ImportDirectiveImpl importDirective2(
          String uri, bool isDeferred, String prefix,
          [List<Combinator> combinators = const []]) =>
      importDirective([], uri, isDeferred, prefix, combinators);

  static ImportDirectiveImpl importDirective3(String uri, String? prefix,
          [List<Combinator> combinators = const []]) =>
      importDirective([], uri, false, prefix, combinators);

  static InterpolationExpressionImpl interpolationExpression(
          Expression expression) =>
      astFactory.interpolationExpression(
          TokenFactory.tokenFromType(TokenType.STRING_INTERPOLATION_EXPRESSION),
          expression,
          TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));

  static InterpolationExpressionImpl interpolationExpression2(
          String identifier) =>
      astFactory.interpolationExpression(
          TokenFactory.tokenFromType(TokenType.STRING_INTERPOLATION_IDENTIFIER),
          identifier3(identifier),
          null);

  static IsExpressionImpl isExpression(
          Expression expression, bool negated, TypeAnnotation type) =>
      astFactory.isExpression(
          expression,
          TokenFactory.tokenFromKeyword(Keyword.IS),
          negated ? TokenFactory.tokenFromType(TokenType.BANG) : null,
          type);

  static LabeledStatementImpl labeledStatement(
          List<Label> labels, Statement statement) =>
      astFactory.labeledStatement(labels, statement);

  static LibraryDirectiveImpl libraryDirective(
          List<Annotation> metadata, LibraryIdentifier? libraryName) =>
      LibraryDirectiveImpl(
        comment: null,
        metadata: metadata,
        libraryKeyword: TokenFactory.tokenFromKeyword(Keyword.LIBRARY),
        name: libraryName as LibraryIdentifierImpl?,
        semicolon: TokenFactory.tokenFromType(TokenType.SEMICOLON),
      );

  static LibraryDirectiveImpl libraryDirective2(String? libraryName) =>
      libraryDirective(
        <Annotation>[],
        libraryName == null ? null : libraryIdentifier2([libraryName]),
      );

  static LibraryIdentifierImpl libraryIdentifier(
          List<SimpleIdentifier> components) =>
      astFactory.libraryIdentifier(components);

  static LibraryIdentifierImpl libraryIdentifier2(List<String> components) {
    return astFactory.libraryIdentifier(identifierList(components));
  }

  static List list(List<Object> elements) {
    return elements;
  }

  static ListLiteralImpl listLiteral([List<Expression> elements = const []]) =>
      listLiteral2(null, null, elements);

  static ListLiteralImpl listLiteral2(
          Keyword? keyword, TypeArgumentList? typeArguments,
          [List<CollectionElement> elements = const []]) =>
      astFactory.listLiteral(
          keyword == null ? null : TokenFactory.tokenFromKeyword(keyword),
          typeArguments,
          TokenFactory.tokenFromType(TokenType.OPEN_SQUARE_BRACKET),
          elements,
          TokenFactory.tokenFromType(TokenType.CLOSE_SQUARE_BRACKET));

  static MethodDeclarationImpl methodDeclaration(
          Keyword? modifier,
          TypeAnnotation? returnType,
          Keyword? property,
          Keyword? operator,
          SimpleIdentifier name,
          FormalParameterList? parameters) =>
      MethodDeclarationImpl(
        comment: null,
        metadata: null,
        externalKeyword: TokenFactory.tokenFromKeyword(Keyword.EXTERNAL),
        modifierKeyword:
            modifier == null ? null : TokenFactory.tokenFromKeyword(modifier),
        returnType: returnType as TypeAnnotationImpl?,
        propertyKeyword:
            property == null ? null : TokenFactory.tokenFromKeyword(property),
        operatorKeyword:
            operator == null ? null : TokenFactory.tokenFromKeyword(operator),
        name: name.token,
        typeParameters: null,
        parameters: parameters as FormalParameterListImpl?,
        body: EmptyFunctionBodyImpl(
          semicolon: TokenFactory.tokenFromType(TokenType.SEMICOLON),
        ),
      );

  static NativeFunctionBodyImpl nativeFunctionBody(String nativeMethodName) =>
      astFactory.nativeFunctionBody(
          TokenFactory.tokenFromString("native"),
          string2(nativeMethodName),
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static ParenthesizedExpressionImpl parenthesizedExpression(
          Expression expression) =>
      astFactory.parenthesizedExpression(
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          expression,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN));

  static PartDirectiveImpl partDirective(
          List<Annotation> metadata, String url) =>
      PartDirectiveImpl(
        comment: null,
        metadata: metadata,
        partKeyword: TokenFactory.tokenFromKeyword(Keyword.PART),
        uri: string2(url),
        semicolon: TokenFactory.tokenFromType(TokenType.SEMICOLON),
      );

  static PartDirectiveImpl partDirective2(String url) =>
      partDirective(<Annotation>[], url);

  static PartOfDirectiveImpl partOfDirective(LibraryIdentifier libraryName) =>
      partOfDirective2(<Annotation>[], libraryName);

  static PartOfDirectiveImpl partOfDirective2(
          List<Annotation> metadata, LibraryIdentifier libraryName) =>
      PartOfDirectiveImpl(
        comment: null,
        metadata: metadata,
        partKeyword: TokenFactory.tokenFromKeyword(Keyword.PART),
        ofKeyword: TokenFactory.tokenFromString("of"),
        uri: null,
        libraryName: libraryName as LibraryIdentifierImpl,
        semicolon: TokenFactory.tokenFromType(TokenType.SEMICOLON),
      );

  static SetOrMapLiteralImpl setOrMapLiteral(
          Keyword? keyword, TypeArgumentList? typeArguments,
          [List<CollectionElement> elements = const []]) =>
      astFactory.setOrMapLiteral(
        constKeyword:
            keyword == null ? null : TokenFactory.tokenFromKeyword(keyword),
        typeArguments: typeArguments,
        leftBracket: TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET),
        elements: elements,
        rightBracket: TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET),
      );

  static ShowClauseImpl showClause(List<ShowHideClauseElement> elements) =>
      astFactory.showClause(
          showKeyword: TokenFactory.tokenFromString("show"),
          elements: elements);

  static ShowHideElementImpl showHideElement(String name) =>
      astFactory.showHideElement(modifier: null, name: identifier3(name));

  static ShowHideElementImpl showHideElementGetter(String name) =>
      astFactory.showHideElement(
          modifier: TokenFactory.tokenFromString("get"),
          name: identifier3(name));

  static ShowHideElementImpl showHideElementOperator(String name) =>
      astFactory.showHideElement(
          modifier: TokenFactory.tokenFromString("operator"),
          name: identifier3(name));

  static ShowHideElementImpl showHideElementSetter(String name) =>
      astFactory.showHideElement(
          modifier: TokenFactory.tokenFromString("set"),
          name: identifier3(name));

  static SpreadElementImpl spreadElement(
          TokenType operator, Expression expression) =>
      astFactory.spreadElement(
          spreadOperator: TokenFactory.tokenFromType(operator),
          expression: expression);

  static StringInterpolationImpl string(
          [List<InterpolationElement> elements = const []]) =>
      astFactory.stringInterpolation(elements);

  static SimpleStringLiteralImpl string2(String content) => astFactory
      .simpleStringLiteral(TokenFactory.tokenFromString("'$content'"), content);

  static SuperExpressionImpl superExpression() =>
      astFactory.superExpression(TokenFactory.tokenFromKeyword(Keyword.SUPER));

  static SwitchCaseImpl switchCase(
          Expression expression, List<Statement> statements) =>
      switchCase2(<Label>[], expression, statements);

  static SwitchCaseImpl switchCase2(List<Label> labels, Expression expression,
          List<Statement> statements) =>
      astFactory.switchCase(labels, TokenFactory.tokenFromKeyword(Keyword.CASE),
          expression, TokenFactory.tokenFromType(TokenType.COLON), statements);

  static SwitchDefaultImpl switchDefault(
          List<Label> labels, List<Statement> statements) =>
      astFactory.switchDefault(
          labels,
          TokenFactory.tokenFromKeyword(Keyword.DEFAULT),
          TokenFactory.tokenFromType(TokenType.COLON),
          statements);

  static SwitchDefaultImpl switchDefault2(List<Statement> statements) =>
      switchDefault(<Label>[], statements);

  static SwitchStatementImpl switchStatement(
          Expression expression, List<SwitchMember> members) =>
      astFactory.switchStatement(
          TokenFactory.tokenFromKeyword(Keyword.SWITCH),
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          expression,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
          TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET),
          members,
          TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));

  static SymbolLiteralImpl symbolLiteral(List<String> components) {
    List<Token> identifierList = <Token>[];
    for (String component in components) {
      identifierList.add(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, component));
    }
    return astFactory.symbolLiteral(
        TokenFactory.tokenFromType(TokenType.HASH), identifierList);
  }

  static ThisExpressionImpl thisExpression() =>
      astFactory.thisExpression(TokenFactory.tokenFromKeyword(Keyword.THIS));

  static ThrowExpressionImpl throwExpression2(Expression expression) =>
      astFactory.throwExpression(
          TokenFactory.tokenFromKeyword(Keyword.THROW), expression);

  static TopLevelVariableDeclarationImpl topLevelVariableDeclaration(
          Keyword? keyword,
          TypeAnnotation? type,
          List<VariableDeclaration> variables) =>
      TopLevelVariableDeclarationImpl(
        comment: null,
        metadata: null,
        externalKeyword: null,
        variableList: variableDeclarationList(keyword, type, variables),
        semicolon: TokenFactory.tokenFromType(TokenType.SEMICOLON),
      );

  static TopLevelVariableDeclarationImpl topLevelVariableDeclaration2(
          Keyword? keyword, List<VariableDeclaration> variables,
          {bool isExternal = false}) =>
      TopLevelVariableDeclarationImpl(
        comment: null,
        metadata: null,
        variableList: variableDeclarationList(keyword, null, variables),
        semicolon: TokenFactory.tokenFromType(TokenType.SEMICOLON),
        externalKeyword:
            isExternal ? TokenFactory.tokenFromKeyword(Keyword.EXTERNAL) : null,
      );

  static TryStatementImpl tryStatement(Block body, Block finallyClause) =>
      tryStatement3(body, <CatchClause>[], finallyClause);

  static TryStatementImpl tryStatement2(
          Block body, List<CatchClause> catchClauses) =>
      tryStatement3(body, catchClauses, null);

  static TryStatementImpl tryStatement3(
          Block body, List<CatchClause> catchClauses, Block? finallyClause) =>
      astFactory.tryStatement(
          TokenFactory.tokenFromKeyword(Keyword.TRY),
          body,
          catchClauses,
          finallyClause == null
              ? null
              : TokenFactory.tokenFromKeyword(Keyword.FINALLY),
          finallyClause);

  static TypeArgumentList? typeArgumentList(List<TypeAnnotation>? types) {
    if (types == null || types.isEmpty) {
      return null;
    }
    return typeArgumentList2(types);
  }

  static TypeArgumentListImpl typeArgumentList2(List<TypeAnnotation> types) {
    return astFactory.typeArgumentList(TokenFactory.tokenFromType(TokenType.LT),
        types, TokenFactory.tokenFromType(TokenType.GT));
  }

  static TypeParameterImpl typeParameter(String name) => TypeParameterImpl(
        comment: null,
        metadata: null,
        name: identifier3(name).token,
        extendsKeyword: null,
        bound: null,
      );

  static TypeParameterImpl typeParameter3(String name, String varianceLexeme) =>
      // TODO (kallentu) : Clean up AstFactoryImpl casting once variance is
      // added to the interface.
      TypeParameterImpl(
        comment: null,
        metadata: null,
        name: identifier3(name).token,
        extendsKeyword: null,
        bound: null,
        varianceKeyword: TokenFactory.tokenFromString(varianceLexeme),
      );

  static TypeParameterList? typeParameterList([List<String>? typeNames]) {
    if (typeNames == null || typeNames.isEmpty) {
      return null;
    }
    return typeParameterList2(typeNames);
  }

  static TypeParameterListImpl typeParameterList2(List<String> typeNames) {
    var typeParameters = <TypeParameter>[];
    for (String typeName in typeNames) {
      typeParameters.add(typeParameter(typeName));
    }

    return astFactory.typeParameterList(
        TokenFactory.tokenFromType(TokenType.LT),
        typeParameters,
        TokenFactory.tokenFromType(TokenType.GT));
  }

  static VariableDeclarationImpl variableDeclaration(String name) =>
      VariableDeclarationImpl(
        name: identifier3(name).token,
        equals: null,
        initializer: null,
      );

  static VariableDeclarationImpl variableDeclaration2(
          String name, Expression initializer) =>
      VariableDeclarationImpl(
        name: identifier3(name).token,
        equals: TokenFactory.tokenFromType(TokenType.EQ),
        initializer: initializer as ExpressionImpl,
      );

  static VariableDeclarationListImpl variableDeclarationList(Keyword? keyword,
          TypeAnnotation? type, List<VariableDeclaration> variables) =>
      VariableDeclarationListImpl(
        comment: null,
        metadata: null,
        lateKeyword: null,
        keyword:
            keyword == null ? null : TokenFactory.tokenFromKeyword(keyword),
        type: type as TypeAnnotationImpl?,
        variables: variables,
      );

  static VariableDeclarationListImpl variableDeclarationList2(
          Keyword? keyword, List<VariableDeclaration> variables) =>
      variableDeclarationList(keyword, null, variables);

  static VariableDeclarationStatementImpl variableDeclarationStatement(
          Keyword? keyword,
          TypeAnnotation? type,
          List<VariableDeclaration> variables) =>
      astFactory.variableDeclarationStatement(
          variableDeclarationList(keyword, type, variables),
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static VariableDeclarationStatementImpl variableDeclarationStatement2(
          Keyword keyword, List<VariableDeclaration> variables) =>
      variableDeclarationStatement(keyword, null, variables);

  static WhileStatementImpl whileStatement(
          Expression condition, Statement body) =>
      astFactory.whileStatement(
          TokenFactory.tokenFromKeyword(Keyword.WHILE),
          TokenFactory.tokenFromType(TokenType.OPEN_PAREN),
          condition,
          TokenFactory.tokenFromType(TokenType.CLOSE_PAREN),
          body);

  static WithClauseImpl withClause(List<NamedType> types) =>
      astFactory.withClause(TokenFactory.tokenFromKeyword(Keyword.WITH), types);

  static YieldStatementImpl yieldEachStatement(Expression expression) =>
      astFactory.yieldStatement(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "yield"),
          TokenFactory.tokenFromType(TokenType.STAR),
          expression,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));

  static YieldStatementImpl yieldStatement(Expression expression) =>
      astFactory.yieldStatement(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, "yield"),
          null,
          expression,
          TokenFactory.tokenFromType(TokenType.SEMICOLON));
}
