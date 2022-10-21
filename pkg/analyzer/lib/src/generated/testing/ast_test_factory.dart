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

  static SimpleIdentifierImpl identifier3(String lexeme) =>
      astFactory.simpleIdentifier(
          TokenFactory.tokenFromTypeAndString(TokenType.IDENTIFIER, lexeme));

  static List<SimpleIdentifier> identifierList(List<String> identifiers) {
    return identifiers
        .map((String identifier) => identifier3(identifier))
        .toList();
  }

  static LibraryDirectiveImpl libraryDirective(
          List<Annotation> metadata, LibraryIdentifier? libraryName) =>
      LibraryDirectiveImpl(
        comment: null,
        metadata: metadata,
        libraryKeyword: TokenFactory.tokenFromKeyword(Keyword.LIBRARY),
        name: libraryName as LibraryIdentifierImpl?,
        semicolon: TokenFactory.tokenFromType(TokenType.SEMICOLON),
      );

  static List list(List<Object> elements) {
    return elements;
  }

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
}
