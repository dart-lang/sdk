// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/reference.dart';

/// Deserializer of fully resolved ASTs from flat buffers.
class AstBinaryReader {
  final Reference _nameRoot;
  final LinkedNodeReference _linkedReferences;
  final List<Reference> _references;

  final UnlinkedTokens _tokensBinary;
  final List<Token> _tokens;

  AstBinaryReader(this._nameRoot, this._linkedReferences, this._tokensBinary)
      : _references = List<Reference>(_linkedReferences.name.length),
        _tokens = List<Token>(_tokensBinary.type.length);

  AstNode readNode(LinkedNode data) {
    if (data == null) return null;

    switch (data.kind) {
      case LinkedNodeKind.annotation:
        return astFactory.annotation(
          _getToken(data.annotation_atSign),
          readNode(data.annotation_name),
          _getToken(data.annotation_period),
          readNode(data.annotation_constructorName),
          readNode(data.annotation_arguments),
        );
      case LinkedNodeKind.binaryExpression:
        return astFactory.binaryExpression(
          readNode(data.binaryExpression_leftOperand),
          _getToken(data.binaryExpression_operator),
          readNode(data.binaryExpression_rightOperand),
        )
          ..staticElement = _getElement(data.binaryExpression_element)
          ..staticType = _readType(data.expression_type);
      case LinkedNodeKind.block:
        return astFactory.block(
          _getToken(data.block_leftBracket),
          _readNodeList(data.block_statements),
          _getToken(data.block_rightBracket),
        );
      case LinkedNodeKind.blockFunctionBody:
        return astFactory.blockFunctionBody(
          _getToken(data.blockFunctionBody_keyword),
          _getToken(data.blockFunctionBody_star),
          readNode(data.blockFunctionBody_block),
        );
      case LinkedNodeKind.classDeclaration:
        return astFactory.classDeclaration(
          readNode(data.annotatedNode_comment),
          _readNodeList(data.annotatedNode_metadata),
          _getToken(data.classDeclaration_abstractKeyword),
          _getToken(data.classDeclaration_classKeyword),
          readNode(data.namedCompilationUnitMember_name),
          readNode(data.classOrMixinDeclaration_typeParameters),
          readNode(data.classDeclaration_extendsClause),
          readNode(data.classDeclaration_withClause),
          readNode(data.classOrMixinDeclaration_implementsClause),
          _getToken(data.classOrMixinDeclaration_leftBracket),
          _readNodeList(data.classOrMixinDeclaration_members),
          _getToken(data.classOrMixinDeclaration_rightBracket),
        );
      case LinkedNodeKind.comment:
        // TODO(scheglov) type
        return astFactory.endOfLineComment(
          _getTokens(data.comment_tokens),
        );
      case LinkedNodeKind.compilationUnit:
        return astFactory.compilationUnit(
          _getToken(data.compilationUnit_beginToken),
          readNode(data.compilationUnit_scriptTag),
          _readNodeList(data.compilationUnit_directives),
          _readNodeList(data.compilationUnit_declarations),
          _getToken(data.compilationUnit_endToken),
        );
      case LinkedNodeKind.doubleLiteral:
        return astFactory.doubleLiteral(
          _getToken(data.doubleLiteral_literal),
          data.doubleLiteral_value,
        )..staticType = _readType(data.expression_type);
      case LinkedNodeKind.expressionStatement:
        return astFactory.expressionStatement(
          readNode(data.expressionStatement_expression),
          _getToken(data.expressionStatement_semicolon),
        );
      case LinkedNodeKind.extendsClause:
        return astFactory.extendsClause(
          _getToken(data.extendsClause_extendsKeyword),
          readNode(data.extendsClause_superclass),
        );
      case LinkedNodeKind.formalParameterList:
        return astFactory.formalParameterList(
          _getToken(data.formalParameterList_leftParenthesis),
          _readNodeList(data.formalParameterList_parameters),
          _getToken(data.formalParameterList_leftDelimiter),
          _getToken(data.formalParameterList_rightDelimiter),
          _getToken(data.formalParameterList_rightParenthesis),
        );
      case LinkedNodeKind.functionDeclaration:
        return astFactory.functionDeclaration(
          readNode(data.annotatedNode_comment),
          _readNodeList(data.annotatedNode_metadata),
          _getToken(data.functionDeclaration_externalKeyword),
          readNode(data.functionDeclaration_returnType),
          _getToken(data.functionDeclaration_propertyKeyword),
          readNode(data.namedCompilationUnitMember_name),
          readNode(data.functionDeclaration_functionExpression),
        );
      case LinkedNodeKind.functionExpression:
        return astFactory.functionExpression(
          readNode(data.functionExpression_typeParameters),
          readNode(data.functionExpression_formalParameters),
          readNode(data.functionExpression_body),
        );
      case LinkedNodeKind.integerLiteral:
        return astFactory.integerLiteral(
          _getToken(data.integerLiteral_literal),
          data.integerLiteral_value,
        )..staticType = _readType(data.expression_type);
      case LinkedNodeKind.listLiteral:
        return astFactory.listLiteral(
          _getToken(data.typedLiteral_constKeyword),
          readNode(data.typedLiteral_typeArguments),
          _getToken(data.listLiteral_leftBracket),
          _readNodeList(data.listLiteral_elements),
          _getToken(data.listLiteral_rightBracket),
        )..staticType = _readType(data.expression_type);
      case LinkedNodeKind.simpleIdentifier:
        return astFactory.simpleIdentifier(
          _getToken(data.simpleIdentifier_token),
        )
          ..staticElement = _getElement(data.simpleIdentifier_element)
          ..staticType = _readType(data.expression_type);
      case LinkedNodeKind.topLevelVariableDeclaration:
        return astFactory.topLevelVariableDeclaration(
          readNode(data.annotatedNode_comment),
          _readNodeList(data.annotatedNode_metadata),
          readNode(data.topLevelVariableDeclaration_variableList),
          _getToken(data.topLevelVariableDeclaration_semicolon),
        );
      case LinkedNodeKind.typeArgumentList:
        return astFactory.typeArgumentList(
          _getToken(data.typeArgumentList_leftBracket),
          _readNodeList(data.typeArgumentList_arguments),
          _getToken(data.typeArgumentList_rightBracket),
        );
      case LinkedNodeKind.typeName:
        return astFactory.typeName(
          readNode(data.typeName_name),
          readNode(data.typeName_typeArguments),
          question: _getToken(data.typeName_question),
        )..type = _readType(data.typeName_type);
      case LinkedNodeKind.typeParameter:
        return astFactory.typeParameter(
          readNode(data.annotatedNode_comment),
          _readNodeList(data.annotatedNode_metadata),
          readNode(data.typeParameter_name),
          _getToken(data.typeParameter_extendsKeyword),
          readNode(data.typeParameter_bound),
        );
      case LinkedNodeKind.typeParameterList:
        return astFactory.typeParameterList(
          _getToken(data.typeParameterList_leftBracket),
          _readNodeList(data.typeParameterList_typeParameters),
          _getToken(data.typeParameterList_rightBracket),
        );
      case LinkedNodeKind.variableDeclaration:
        return astFactory.variableDeclaration(
          readNode(data.variableDeclaration_name),
          _getToken(data.variableDeclaration_equals),
          readNode(data.variableDeclaration_initializer),
        );
      case LinkedNodeKind.variableDeclarationList:
        return astFactory.variableDeclarationList(
          readNode(data.annotatedNode_comment),
          _readNodeList(data.annotatedNode_metadata),
          _getToken(data.variableDeclarationList_keyword),
          readNode(data.variableDeclarationList_type),
          _readNodeList(data.variableDeclarationList_variables),
        );
      default:
        throw UnimplementedError('Expression kind: ${data.kind}');
    }
  }

  CommentToken _getCommentToken(int index) {
    var result = _getToken(index);
    var token = result;
    while (true) {
      index = _tokensBinary.next[index];
      if (index == 0) return result;

      var nextToken = _getToken(index);
      token.next = nextToken;
      token = nextToken;
    }
  }

  T _getElement<T extends Element>(int index) {
    return _getReferenceByIndex(index)?.element;
  }

  List<T> _getElements<T extends Element>(List<int> indexList) {
    var result = List<T>(indexList.length);
    for (var i = 0; i < indexList.length; ++i) {
      var index = indexList[i];
      result[i] = _getElement(index);
    }
    return result;
  }

  Reference _getReferenceByIndex(int index) {
    var reference = _references[index];
    if (reference != null) return reference;

    if (index == 0) {
      _references[index] = _nameRoot;
      return _nameRoot;
    }

    var parentIndex = _linkedReferences.parent[index];
    var parent = _getReferenceByIndex(parentIndex);
    if (parent == null) return null;

    var name = _linkedReferences.name[index];
    reference = parent[name];
    _references[index] = reference;

    return reference;
  }

  Token _getToken(int index) {
    var token = _tokens[index];
    if (token == null) {
      var kind = _tokensBinary.kind[index];
      switch (kind) {
        case UnlinkedTokenKind.nothing:
          return null;
        case UnlinkedTokenKind.comment:
          return CommentToken(
            _binaryToAstTokenType(_tokensBinary.type[index]),
            _tokensBinary.lexeme[index],
            _tokensBinary.offset[index],
          );
        case UnlinkedTokenKind.keyword:
          return KeywordToken(
            _binaryToAstTokenType(_tokensBinary.type[index]),
            _tokensBinary.offset[index],
            _getCommentToken(_tokensBinary.precedingComment[index]),
          );
        case UnlinkedTokenKind.simple:
          return SimpleToken(
            _binaryToAstTokenType(_tokensBinary.type[index]),
            _tokensBinary.offset[index],
            _getCommentToken(_tokensBinary.precedingComment[index]),
          );
        case UnlinkedTokenKind.string:
          return StringToken(
            _binaryToAstTokenType(_tokensBinary.type[index]),
            _tokensBinary.lexeme[index],
            _tokensBinary.offset[index],
            _getCommentToken(_tokensBinary.precedingComment[index]),
          );
        default:
          throw UnimplementedError('Token kind: $kind');
      }
    }
    return token;
  }

  List<Token> _getTokens(List<int> indexList) {
    var result = List<Token>(indexList.length);
    for (var i = 0; i < indexList.length; ++i) {
      var index = indexList[i];
      result[i] = _getToken(index);
    }
    return result;
  }

  List<T> _readNodeList<T>(List<LinkedNode> nodeList) {
    var result = List<T>.filled(nodeList.length, null);
    for (var i = 0; i < nodeList.length; ++i) {
      var linkedNode = nodeList[i];
      result[i] = readNode(linkedNode) as T;
    }
    return result;
  }

  DartType _readType(LinkedNodeType data) {
    if (data == null) return null;

    switch (data.kind) {
      case LinkedNodeTypeKind.function:
        return FunctionTypeImpl.synthetic(
          _readType(data.functionReturnType),
          _getElements(data.functionTypeParameters),
          _getElements(data.functionFormalParameters),
        );
      case LinkedNodeTypeKind.interface:
        var element = _getElement(data.interfaceClass);
        if (element != null) {
          return InterfaceTypeImpl.explicit(
            element,
            _readTypes(
              data.interfaceTypeArguments,
              const <InterfaceType>[],
            ),
          );
        }
        return DynamicTypeImpl.instance;
      case LinkedNodeTypeKind.void_:
        return VoidTypeImpl.instance;
      default:
        throw UnimplementedError('Type kind: ${data.kind}');
    }
  }

  List<T> _readTypes<T extends DartType>(
    List<LinkedNodeType> dataList,
    List<T> ifEmpty,
  ) {
    if (dataList.isEmpty) return ifEmpty;

    var result = List<T>(dataList.length);
    for (var i = 0; i < dataList.length; ++i) {
      var data = dataList[i];
      result[i] = _readType(data);
    }
    return result;
  }

  static TokenType _binaryToAstTokenType(UnlinkedTokenType type) {
    switch (type) {
      case UnlinkedTokenType.ABSTRACT:
        return Keyword.ABSTRACT;
      case UnlinkedTokenType.AMPERSAND:
        return TokenType.AMPERSAND;
      case UnlinkedTokenType.AMPERSAND_AMPERSAND:
        return TokenType.AMPERSAND_AMPERSAND;
      case UnlinkedTokenType.AMPERSAND_EQ:
        return TokenType.AMPERSAND_EQ;
      case UnlinkedTokenType.AS:
        return TokenType.AS;
      case UnlinkedTokenType.ASSERT:
        return Keyword.ASSERT;
      case UnlinkedTokenType.ASYNC:
        return Keyword.ASYNC;
      case UnlinkedTokenType.AT:
        return TokenType.AT;
      case UnlinkedTokenType.AWAIT:
        return Keyword.AWAIT;
      case UnlinkedTokenType.BACKPING:
        return TokenType.BACKPING;
      case UnlinkedTokenType.BACKSLASH:
        return TokenType.BACKSLASH;
      case UnlinkedTokenType.BANG:
        return TokenType.BANG;
      case UnlinkedTokenType.BANG_EQ:
        return TokenType.BANG_EQ;
      case UnlinkedTokenType.BAR:
        return TokenType.BAR;
      case UnlinkedTokenType.BAR_BAR:
        return TokenType.BAR_BAR;
      case UnlinkedTokenType.BAR_EQ:
        return TokenType.BAR_EQ;
      case UnlinkedTokenType.BREAK:
        return Keyword.BREAK;
      case UnlinkedTokenType.CARET:
        return TokenType.CARET;
      case UnlinkedTokenType.CARET_EQ:
        return TokenType.CARET_EQ;
      case UnlinkedTokenType.CASE:
        return Keyword.CASE;
      case UnlinkedTokenType.CATCH:
        return Keyword.CATCH;
      case UnlinkedTokenType.CLASS:
        return Keyword.CLASS;
      case UnlinkedTokenType.CLOSE_CURLY_BRACKET:
        return TokenType.CLOSE_CURLY_BRACKET;
      case UnlinkedTokenType.CLOSE_PAREN:
        return TokenType.CLOSE_PAREN;
      case UnlinkedTokenType.CLOSE_SQUARE_BRACKET:
        return TokenType.CLOSE_SQUARE_BRACKET;
      case UnlinkedTokenType.COLON:
        return TokenType.COLON;
      case UnlinkedTokenType.COMMA:
        return TokenType.COMMA;
      case UnlinkedTokenType.CONST:
        return Keyword.CONST;
      case UnlinkedTokenType.CONTINUE:
        return Keyword.CONTINUE;
      case UnlinkedTokenType.COVARIANT:
        return Keyword.COVARIANT;
      case UnlinkedTokenType.DEFAULT:
        return Keyword.DEFAULT;
      case UnlinkedTokenType.DEFERRED:
        return Keyword.DEFERRED;
      case UnlinkedTokenType.DO:
        return Keyword.DO;
      case UnlinkedTokenType.DOUBLE:
        return TokenType.DOUBLE;
      case UnlinkedTokenType.DYNAMIC:
        return Keyword.DYNAMIC;
      case UnlinkedTokenType.ELSE:
        return Keyword.ELSE;
      case UnlinkedTokenType.ENUM:
        return Keyword.ENUM;
      case UnlinkedTokenType.EOF:
        return TokenType.EOF;
      case UnlinkedTokenType.EQ:
        return TokenType.EQ;
      case UnlinkedTokenType.EQ_EQ:
        return TokenType.EQ_EQ;
      case UnlinkedTokenType.EXPORT:
        return Keyword.EXPORT;
      case UnlinkedTokenType.EXTENDS:
        return Keyword.EXTENDS;
      case UnlinkedTokenType.EXTERNAL:
        return Keyword.EXTERNAL;
      case UnlinkedTokenType.FACTORY:
        return Keyword.FACTORY;
      case UnlinkedTokenType.FALSE:
        return Keyword.FALSE;
      case UnlinkedTokenType.FINAL:
        return Keyword.FINAL;
      case UnlinkedTokenType.FINALLY:
        return Keyword.FINALLY;
      case UnlinkedTokenType.FOR:
        return Keyword.FOR;
      case UnlinkedTokenType.FUNCTION:
        return TokenType.FUNCTION;
      case UnlinkedTokenType.GET:
        return Keyword.GET;
      case UnlinkedTokenType.GT:
        return TokenType.GT;
      case UnlinkedTokenType.GT_EQ:
        return TokenType.GT_EQ;
      case UnlinkedTokenType.GT_GT:
        return TokenType.GT_GT;
      case UnlinkedTokenType.GT_GT_EQ:
        return TokenType.GT_GT_EQ;
      case UnlinkedTokenType.HASH:
        return TokenType.HASH;
      case UnlinkedTokenType.HEXADECIMAL:
        return TokenType.HEXADECIMAL;
      case UnlinkedTokenType.HIDE:
        return Keyword.HIDE;
      case UnlinkedTokenType.IDENTIFIER:
        return TokenType.IDENTIFIER;
      case UnlinkedTokenType.IF:
        return Keyword.IF;
      case UnlinkedTokenType.IMPLEMENTS:
        return Keyword.IMPLEMENTS;
      case UnlinkedTokenType.IMPORT:
        return Keyword.IMPORT;
      case UnlinkedTokenType.IN:
        return Keyword.IN;
      case UnlinkedTokenType.INDEX:
        return TokenType.INDEX;
      case UnlinkedTokenType.INDEX_EQ:
        return TokenType.INDEX_EQ;
      case UnlinkedTokenType.INT:
        return TokenType.INT;
      case UnlinkedTokenType.INTERFACE:
        return Keyword.INTERFACE;
      case UnlinkedTokenType.IS:
        return TokenType.IS;
      case UnlinkedTokenType.LIBRARY:
        return Keyword.LIBRARY;
      case UnlinkedTokenType.LT:
        return TokenType.LT;
      case UnlinkedTokenType.LT_EQ:
        return TokenType.LT_EQ;
      case UnlinkedTokenType.LT_LT:
        return TokenType.LT_LT;
      case UnlinkedTokenType.LT_LT_EQ:
        return TokenType.LT_LT_EQ;
      case UnlinkedTokenType.MINUS:
        return TokenType.MINUS;
      case UnlinkedTokenType.MINUS_EQ:
        return TokenType.MINUS_EQ;
      case UnlinkedTokenType.MINUS_MINUS:
        return TokenType.MINUS_MINUS;
      case UnlinkedTokenType.MIXIN:
        return Keyword.MIXIN;
      case UnlinkedTokenType.MULTI_LINE_COMMENT:
        return TokenType.MULTI_LINE_COMMENT;
      case UnlinkedTokenType.NATIVE:
        return Keyword.NATIVE;
      case UnlinkedTokenType.NEW:
        return Keyword.NEW;
      case UnlinkedTokenType.NULL:
        return Keyword.NULL;
      case UnlinkedTokenType.OF:
        return Keyword.OF;
      case UnlinkedTokenType.ON:
        return Keyword.ON;
      case UnlinkedTokenType.OPEN_CURLY_BRACKET:
        return TokenType.OPEN_CURLY_BRACKET;
      case UnlinkedTokenType.OPEN_PAREN:
        return TokenType.OPEN_PAREN;
      case UnlinkedTokenType.OPEN_SQUARE_BRACKET:
        return TokenType.OPEN_SQUARE_BRACKET;
      case UnlinkedTokenType.OPERATOR:
        return Keyword.OPERATOR;
      case UnlinkedTokenType.PART:
        return Keyword.PART;
      case UnlinkedTokenType.PATCH:
        return Keyword.PATCH;
      case UnlinkedTokenType.PERCENT:
        return TokenType.PERCENT;
      case UnlinkedTokenType.PERCENT_EQ:
        return TokenType.PERCENT_EQ;
      case UnlinkedTokenType.PERIOD:
        return TokenType.PERIOD;
      case UnlinkedTokenType.PERIOD_PERIOD:
        return TokenType.PERIOD_PERIOD;
      case UnlinkedTokenType.PERIOD_PERIOD_PERIOD:
        return TokenType.PERIOD_PERIOD_PERIOD;
      case UnlinkedTokenType.PERIOD_PERIOD_PERIOD_QUESTION:
        return TokenType.PERIOD_PERIOD_PERIOD_QUESTION;
      case UnlinkedTokenType.PLUS:
        return TokenType.PLUS;
      case UnlinkedTokenType.PLUS_EQ:
        return TokenType.PLUS_EQ;
      case UnlinkedTokenType.PLUS_PLUS:
        return TokenType.PLUS_PLUS;
      case UnlinkedTokenType.QUESTION:
        return TokenType.QUESTION;
      case UnlinkedTokenType.QUESTION_PERIOD:
        return TokenType.QUESTION_PERIOD;
      case UnlinkedTokenType.QUESTION_QUESTION:
        return TokenType.QUESTION_QUESTION;
      case UnlinkedTokenType.QUESTION_QUESTION_EQ:
        return TokenType.QUESTION_QUESTION_EQ;
      case UnlinkedTokenType.RETHROW:
        return Keyword.RETHROW;
      case UnlinkedTokenType.RETURN:
        return Keyword.RETURN;
      case UnlinkedTokenType.SCRIPT_TAG:
        return TokenType.SCRIPT_TAG;
      case UnlinkedTokenType.SEMICOLON:
        return TokenType.SEMICOLON;
      case UnlinkedTokenType.SET:
        return Keyword.SET;
      case UnlinkedTokenType.SHOW:
        return Keyword.SHOW;
      case UnlinkedTokenType.SINGLE_LINE_COMMENT:
        return TokenType.SINGLE_LINE_COMMENT;
      case UnlinkedTokenType.SLASH:
        return TokenType.SLASH;
      case UnlinkedTokenType.SLASH_EQ:
        return TokenType.SLASH_EQ;
      case UnlinkedTokenType.SOURCE:
        return Keyword.SOURCE;
      case UnlinkedTokenType.STAR:
        return TokenType.STAR;
      case UnlinkedTokenType.STAR_EQ:
        return TokenType.STAR_EQ;
      case UnlinkedTokenType.STATIC:
        return Keyword.STATIC;
      case UnlinkedTokenType.STRING:
        return TokenType.STRING;
      case UnlinkedTokenType.STRING_INTERPOLATION_EXPRESSION:
        return TokenType.STRING_INTERPOLATION_EXPRESSION;
      case UnlinkedTokenType.STRING_INTERPOLATION_IDENTIFIER:
        return TokenType.STRING_INTERPOLATION_IDENTIFIER;
      case UnlinkedTokenType.SUPER:
        return Keyword.SUPER;
      case UnlinkedTokenType.SWITCH:
        return Keyword.SWITCH;
      case UnlinkedTokenType.SYNC:
        return Keyword.SYNC;
      case UnlinkedTokenType.THIS:
        return Keyword.THIS;
      case UnlinkedTokenType.THROW:
        return Keyword.THROW;
      case UnlinkedTokenType.TILDE:
        return TokenType.TILDE;
      case UnlinkedTokenType.TILDE_SLASH:
        return TokenType.TILDE_SLASH;
      case UnlinkedTokenType.TILDE_SLASH_EQ:
        return TokenType.TILDE_SLASH_EQ;
      case UnlinkedTokenType.TRUE:
        return Keyword.TRUE;
      case UnlinkedTokenType.TRY:
        return Keyword.TRY;
      case UnlinkedTokenType.TYPEDEF:
        return Keyword.TYPEDEF;
      case UnlinkedTokenType.VAR:
        return Keyword.VAR;
      case UnlinkedTokenType.VOID:
        return Keyword.VOID;
      case UnlinkedTokenType.WHILE:
        return Keyword.WHILE;
      case UnlinkedTokenType.WITH:
        return Keyword.WITH;
      case UnlinkedTokenType.YIELD:
        return Keyword.YIELD;
      default:
        throw StateError('Unexpected type: $type');
    }
  }
}
