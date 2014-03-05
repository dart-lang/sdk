// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.parser;

import 'java_core.dart';
import 'java_engine.dart';
import 'instrumentation.dart';
import 'error.dart';
import 'source.dart';
import 'scanner.dart';
import 'ast.dart';
import 'utilities_dart.dart';
import 'engine.dart' show AnalysisEngine;
import 'utilities_collection.dart' show TokenMap;

/**
 * Instances of the class `CommentAndMetadata` implement a simple data-holder for a method
 * that needs to return multiple values.
 */
class CommentAndMetadata {
  /**
   * The documentation comment that was parsed, or `null` if none was given.
   */
  final Comment comment;

  /**
   * The metadata that was parsed.
   */
  final List<Annotation> metadata;

  /**
   * Initialize a newly created holder with the given data.
   *
   * @param comment the documentation comment that was parsed
   * @param metadata the metadata that was parsed
   */
  CommentAndMetadata(this.comment, this.metadata);
}

/**
 * Instances of the class `FinalConstVarOrType` implement a simple data-holder for a method
 * that needs to return multiple values.
 */
class FinalConstVarOrType {
  /**
   * The 'final', 'const' or 'var' keyword, or `null` if none was given.
   */
  final Token keyword;

  /**
   * The type, of `null` if no type was specified.
   */
  final TypeName type;

  /**
   * Initialize a newly created holder with the given data.
   *
   * @param keyword the 'final', 'const' or 'var' keyword
   * @param type the type
   */
  FinalConstVarOrType(this.keyword, this.type);
}

/**
 * Instances of the class `Modifiers` implement a simple data-holder for a method that needs
 * to return multiple values.
 */
class Modifiers {
  /**
   * The token representing the keyword 'abstract', or `null` if the keyword was not found.
   */
  Token abstractKeyword;

  /**
   * The token representing the keyword 'const', or `null` if the keyword was not found.
   */
  Token constKeyword;

  /**
   * The token representing the keyword 'external', or `null` if the keyword was not found.
   */
  Token externalKeyword;

  /**
   * The token representing the keyword 'factory', or `null` if the keyword was not found.
   */
  Token factoryKeyword;

  /**
   * The token representing the keyword 'final', or `null` if the keyword was not found.
   */
  Token finalKeyword;

  /**
   * The token representing the keyword 'static', or `null` if the keyword was not found.
   */
  Token staticKeyword;

  /**
   * The token representing the keyword 'var', or `null` if the keyword was not found.
   */
  Token varKeyword;

  String toString() {
    JavaStringBuilder builder = new JavaStringBuilder();
    bool needsSpace = appendKeyword(builder, false, abstractKeyword);
    needsSpace = appendKeyword(builder, needsSpace, constKeyword);
    needsSpace = appendKeyword(builder, needsSpace, externalKeyword);
    needsSpace = appendKeyword(builder, needsSpace, factoryKeyword);
    needsSpace = appendKeyword(builder, needsSpace, finalKeyword);
    needsSpace = appendKeyword(builder, needsSpace, staticKeyword);
    appendKeyword(builder, needsSpace, varKeyword);
    return builder.toString();
  }

  /**
   * If the given keyword is not `null`, append it to the given builder, prefixing it with a
   * space if needed.
   *
   * @param builder the builder to which the keyword will be appended
   * @param needsSpace `true` if the keyword needs to be prefixed with a space
   * @param keyword the keyword to be appended
   * @return `true` if subsequent keywords need to be prefixed with a space
   */
  bool appendKeyword(JavaStringBuilder builder, bool needsSpace, Token keyword) {
    if (keyword != null) {
      if (needsSpace) {
        builder.appendChar(0x20);
      }
      builder.append(keyword.lexeme);
      return true;
    }
    return needsSpace;
  }
}

/**
 * Instances of the class `IncrementalParseDispatcher` implement a dispatcher that will invoke
 * the right parse method when re-parsing a specified child of the visited node. All of the methods
 * in this class assume that the parser is positioned to parse the replacement for the node. All of
 * the methods will throw an [IncrementalParseException] if the node could not be parsed for
 * some reason.
 */
class IncrementalParseDispatcher implements AstVisitor<AstNode> {
  /**
   * The parser used to parse the replacement for the node.
   */
  Parser _parser;

  /**
   * The node that is to be replaced.
   */
  AstNode _oldNode;

  /**
   * Initialize a newly created dispatcher to parse a single node that will replace the given node.
   *
   * @param parser the parser used to parse the replacement for the node
   * @param oldNode the node that is to be replaced
   */
  IncrementalParseDispatcher(Parser parser, AstNode oldNode) {
    this._parser = parser;
    this._oldNode = oldNode;
  }

  AstNode visitAdjacentStrings(AdjacentStrings node) {
    if (node.strings.contains(_oldNode)) {
      return _parser.parseStringLiteral();
    }
    return notAChild(node);
  }

  AstNode visitAnnotation(Annotation node) {
    if (identical(_oldNode, node.name)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.constructorName)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.arguments)) {
      return _parser.parseArgumentList();
    }
    return notAChild(node);
  }

  AstNode visitArgumentDefinitionTest(ArgumentDefinitionTest node) {
    if (identical(_oldNode, node.identifier)) {
      return _parser.parseSimpleIdentifier();
    }
    return notAChild(node);
  }

  AstNode visitArgumentList(ArgumentList node) {
    if (node.arguments.contains(_oldNode)) {
      return _parser.parseArgument();
    }
    return notAChild(node);
  }

  AstNode visitAsExpression(AsExpression node) {
    if (identical(_oldNode, node.expression)) {
      return _parser.parseBitwiseOrExpression();
    } else if (identical(_oldNode, node.type)) {
      return _parser.parseTypeName();
    }
    return notAChild(node);
  }

  AstNode visitAssertStatement(AssertStatement node) {
    if (identical(_oldNode, node.condition)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  AstNode visitAssignmentExpression(AssignmentExpression node) {
    if (identical(_oldNode, node.leftHandSide)) {
      // TODO(brianwilkerson) If the assignment is part of a cascade section, then we don't have a
      // single parse method that will work. Otherwise, we can parse a conditional expression, but
      // need to ensure that the resulting expression is assignable.
      // return parser.parseConditionalExpression();
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.rightHandSide)) {
      if (isCascadeAllowedInAssignment(node)) {
        return _parser.parseExpression2();
      }
      return _parser.parseExpressionWithoutCascade();
    }
    return notAChild(node);
  }

  AstNode visitBinaryExpression(BinaryExpression node) {
    if (identical(_oldNode, node.leftOperand)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.rightOperand)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  AstNode visitBlock(Block node) {
    if (node.statements.contains(_oldNode)) {
      return _parser.parseStatement2();
    }
    return notAChild(node);
  }

  AstNode visitBlockFunctionBody(BlockFunctionBody node) {
    if (identical(_oldNode, node.block)) {
      return _parser.parseBlock();
    }
    return notAChild(node);
  }

  AstNode visitBooleanLiteral(BooleanLiteral node) => notAChild(node);

  AstNode visitBreakStatement(BreakStatement node) {
    if (identical(_oldNode, node.label)) {
      return _parser.parseSimpleIdentifier();
    }
    return notAChild(node);
  }

  AstNode visitCascadeExpression(CascadeExpression node) {
    if (identical(_oldNode, node.target)) {
      return _parser.parseConditionalExpression();
    } else if (node.cascadeSections.contains(_oldNode)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  AstNode visitCatchClause(CatchClause node) {
    if (identical(_oldNode, node.exceptionType)) {
      return _parser.parseTypeName();
    } else if (identical(_oldNode, node.exceptionParameter)) {
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.stackTraceParameter)) {
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.body)) {
      return _parser.parseBlock();
    }
    return notAChild(node);
  }

  AstNode visitClassDeclaration(ClassDeclaration node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.name)) {
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.typeParameters)) {
      return _parser.parseTypeParameterList();
    } else if (identical(_oldNode, node.extendsClause)) {
      return _parser.parseExtendsClause();
    } else if (identical(_oldNode, node.withClause)) {
      return _parser.parseWithClause();
    } else if (identical(_oldNode, node.implementsClause)) {
      return _parser.parseImplementsClause();
    } else if (node.members.contains(_oldNode)) {
      ClassMember member = _parser.parseClassMember(node.name.name);
      if (member == null) {
        throw new InsufficientContextException();
      }
      return member;
    }
    return notAChild(node);
  }

  AstNode visitClassTypeAlias(ClassTypeAlias node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.name)) {
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.typeParameters)) {
      return _parser.parseTypeParameterList();
    } else if (identical(_oldNode, node.superclass)) {
      return _parser.parseTypeName();
    } else if (identical(_oldNode, node.withClause)) {
      return _parser.parseWithClause();
    } else if (identical(_oldNode, node.implementsClause)) {
      return _parser.parseImplementsClause();
    }
    return notAChild(node);
  }

  AstNode visitComment(Comment node) {
    throw new InsufficientContextException();
  }

  AstNode visitCommentReference(CommentReference node) {
    if (identical(_oldNode, node.identifier)) {
      return _parser.parsePrefixedIdentifier();
    }
    return notAChild(node);
  }

  AstNode visitCompilationUnit(CompilationUnit node) {
    throw new InsufficientContextException();
  }

  AstNode visitConditionalExpression(ConditionalExpression node) {
    if (identical(_oldNode, node.condition)) {
      return _parser.parseLogicalOrExpression();
    } else if (identical(_oldNode, node.thenExpression)) {
      return _parser.parseExpressionWithoutCascade();
    } else if (identical(_oldNode, node.elseExpression)) {
      return _parser.parseExpressionWithoutCascade();
    }
    return notAChild(node);
  }

  AstNode visitConstructorDeclaration(ConstructorDeclaration node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.returnType)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.name)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.parameters)) {
      return _parser.parseFormalParameterList();
    } else if (identical(_oldNode, node.redirectedConstructor)) {
      throw new InsufficientContextException();
    } else if (node.initializers.contains(_oldNode)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.body)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  AstNode visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    if (identical(_oldNode, node.fieldName)) {
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.expression)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  AstNode visitConstructorName(ConstructorName node) {
    if (identical(_oldNode, node.type)) {
      return _parser.parseTypeName();
    } else if (identical(_oldNode, node.name)) {
      return _parser.parseSimpleIdentifier();
    }
    return notAChild(node);
  }

  AstNode visitContinueStatement(ContinueStatement node) {
    if (identical(_oldNode, node.label)) {
      return _parser.parseSimpleIdentifier();
    }
    return notAChild(node);
  }

  AstNode visitDeclaredIdentifier(DeclaredIdentifier node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.type)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.identifier)) {
      return _parser.parseSimpleIdentifier();
    }
    return notAChild(node);
  }

  AstNode visitDefaultFormalParameter(DefaultFormalParameter node) {
    if (identical(_oldNode, node.parameter)) {
      return _parser.parseNormalFormalParameter();
    } else if (identical(_oldNode, node.defaultValue)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  AstNode visitDoStatement(DoStatement node) {
    if (identical(_oldNode, node.body)) {
      return _parser.parseStatement2();
    } else if (identical(_oldNode, node.condition)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  AstNode visitDoubleLiteral(DoubleLiteral node) => notAChild(node);

  AstNode visitEmptyFunctionBody(EmptyFunctionBody node) => notAChild(node);

  AstNode visitEmptyStatement(EmptyStatement node) => notAChild(node);

  AstNode visitExportDirective(ExportDirective node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.uri)) {
      return _parser.parseStringLiteral();
    } else if (node.combinators.contains(_oldNode)) {
      throw new IncrementalParseException();
    }
    return notAChild(node);
  }

  AstNode visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (identical(_oldNode, node.expression)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  AstNode visitExpressionStatement(ExpressionStatement node) {
    if (identical(_oldNode, node.expression)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  AstNode visitExtendsClause(ExtendsClause node) {
    if (identical(_oldNode, node.superclass)) {
      return _parser.parseTypeName();
    }
    return notAChild(node);
  }

  AstNode visitFieldDeclaration(FieldDeclaration node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.fields)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  AstNode visitFieldFormalParameter(FieldFormalParameter node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.type)) {
      return _parser.parseTypeName();
    } else if (identical(_oldNode, node.identifier)) {
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.parameters)) {
      return _parser.parseFormalParameterList();
    }
    return notAChild(node);
  }

  AstNode visitForEachStatement(ForEachStatement node) {
    if (identical(_oldNode, node.loopVariable)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.identifier)) {
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.body)) {
      return _parser.parseStatement2();
    }
    return notAChild(node);
  }

  AstNode visitFormalParameterList(FormalParameterList node) {
    // We don't know which kind of parameter to parse.
    throw new InsufficientContextException();
  }

  AstNode visitForStatement(ForStatement node) {
    if (identical(_oldNode, node.variables)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.initialization)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.condition)) {
      return _parser.parseExpression2();
    } else if (node.updaters.contains(_oldNode)) {
      return _parser.parseExpression2();
    } else if (identical(_oldNode, node.body)) {
      return _parser.parseStatement2();
    }
    return notAChild(node);
  }

  AstNode visitFunctionDeclaration(FunctionDeclaration node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.returnType)) {
      return _parser.parseReturnType();
    } else if (identical(_oldNode, node.name)) {
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.functionExpression)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  AstNode visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    if (identical(_oldNode, node.functionDeclaration)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  AstNode visitFunctionExpression(FunctionExpression node) {
    if (identical(_oldNode, node.parameters)) {
      return _parser.parseFormalParameterList();
    } else if (identical(_oldNode, node.body)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  AstNode visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (identical(_oldNode, node.function)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.argumentList)) {
      return _parser.parseArgumentList();
    }
    return notAChild(node);
  }

  AstNode visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.returnType)) {
      return _parser.parseReturnType();
    } else if (identical(_oldNode, node.name)) {
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.typeParameters)) {
      return _parser.parseTypeParameterList();
    } else if (identical(_oldNode, node.parameters)) {
      return _parser.parseFormalParameterList();
    }
    return notAChild(node);
  }

  AstNode visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.returnType)) {
      return _parser.parseReturnType();
    } else if (identical(_oldNode, node.identifier)) {
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.parameters)) {
      return _parser.parseFormalParameterList();
    }
    return notAChild(node);
  }

  AstNode visitHideCombinator(HideCombinator node) {
    if (node.hiddenNames.contains(_oldNode)) {
      return _parser.parseSimpleIdentifier();
    }
    return notAChild(node);
  }

  AstNode visitIfStatement(IfStatement node) {
    if (identical(_oldNode, node.condition)) {
      return _parser.parseExpression2();
    } else if (identical(_oldNode, node.thenStatement)) {
      return _parser.parseStatement2();
    } else if (identical(_oldNode, node.elseStatement)) {
      return _parser.parseStatement2();
    }
    return notAChild(node);
  }

  AstNode visitImplementsClause(ImplementsClause node) {
    if (node.interfaces.contains(node)) {
      return _parser.parseTypeName();
    }
    return notAChild(node);
  }

  AstNode visitImportDirective(ImportDirective node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.uri)) {
      return _parser.parseStringLiteral();
    } else if (identical(_oldNode, node.prefix)) {
      return _parser.parseSimpleIdentifier();
    } else if (node.combinators.contains(_oldNode)) {
      throw new IncrementalParseException();
    }
    return notAChild(node);
  }

  AstNode visitIndexExpression(IndexExpression node) {
    if (identical(_oldNode, node.target)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.index)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  AstNode visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (identical(_oldNode, node.constructorName)) {
      return _parser.parseConstructorName();
    } else if (identical(_oldNode, node.argumentList)) {
      return _parser.parseArgumentList();
    }
    return notAChild(node);
  }

  AstNode visitIntegerLiteral(IntegerLiteral node) => notAChild(node);

  AstNode visitInterpolationExpression(InterpolationExpression node) {
    if (identical(_oldNode, node.expression)) {
      if (node.leftBracket == null) {
        throw new InsufficientContextException();
      }
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  AstNode visitInterpolationString(InterpolationString node) {
    throw new InsufficientContextException();
  }

  AstNode visitIsExpression(IsExpression node) {
    if (identical(_oldNode, node.expression)) {
      return _parser.parseBitwiseOrExpression();
    } else if (identical(_oldNode, node.type)) {
      return _parser.parseTypeName();
    }
    return notAChild(node);
  }

  AstNode visitLabel(Label node) {
    if (identical(_oldNode, node.label)) {
      return _parser.parseSimpleIdentifier();
    }
    return notAChild(node);
  }

  AstNode visitLabeledStatement(LabeledStatement node) {
    if (node.labels.contains(_oldNode)) {
      return _parser.parseLabel();
    } else if (identical(_oldNode, node.statement)) {
      return _parser.parseStatement2();
    }
    return notAChild(node);
  }

  AstNode visitLibraryDirective(LibraryDirective node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.name)) {
      return _parser.parseLibraryIdentifier();
    }
    return notAChild(node);
  }

  AstNode visitLibraryIdentifier(LibraryIdentifier node) {
    if (node.components.contains(_oldNode)) {
      return _parser.parseSimpleIdentifier();
    }
    return notAChild(node);
  }

  AstNode visitListLiteral(ListLiteral node) {
    if (identical(_oldNode, node.typeArguments)) {
      return _parser.parseTypeArgumentList();
    } else if (node.elements.contains(_oldNode)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  AstNode visitMapLiteral(MapLiteral node) {
    if (identical(_oldNode, node.typeArguments)) {
      return _parser.parseTypeArgumentList();
    } else if (node.entries.contains(_oldNode)) {
      return _parser.parseMapLiteralEntry();
    }
    return notAChild(node);
  }

  AstNode visitMapLiteralEntry(MapLiteralEntry node) {
    if (identical(_oldNode, node.key)) {
      return _parser.parseExpression2();
    } else if (identical(_oldNode, node.value)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  AstNode visitMethodDeclaration(MethodDeclaration node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.returnType)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.name)) {
      if (node.operatorKeyword != null) {
        throw new InsufficientContextException();
      }
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.body)) {
      //return parser.parseFunctionBody();
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  AstNode visitMethodInvocation(MethodInvocation node) {
    if (identical(_oldNode, node.target)) {
      throw new IncrementalParseException();
    } else if (identical(_oldNode, node.methodName)) {
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.argumentList)) {
      return _parser.parseArgumentList();
    }
    return notAChild(node);
  }

  AstNode visitNamedExpression(NamedExpression node) {
    if (identical(_oldNode, node.name)) {
      return _parser.parseLabel();
    } else if (identical(_oldNode, node.expression)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  AstNode visitNativeClause(NativeClause node) {
    if (identical(_oldNode, node.name)) {
      return _parser.parseStringLiteral();
    }
    return notAChild(node);
  }

  AstNode visitNativeFunctionBody(NativeFunctionBody node) {
    if (identical(_oldNode, node.stringLiteral)) {
      return _parser.parseStringLiteral();
    }
    return notAChild(node);
  }

  AstNode visitNullLiteral(NullLiteral node) => notAChild(node);

  AstNode visitParenthesizedExpression(ParenthesizedExpression node) {
    if (identical(_oldNode, node.expression)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  AstNode visitPartDirective(PartDirective node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.uri)) {
      return _parser.parseStringLiteral();
    }
    return notAChild(node);
  }

  AstNode visitPartOfDirective(PartOfDirective node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.libraryName)) {
      return _parser.parseLibraryIdentifier();
    }
    return notAChild(node);
  }

  AstNode visitPostfixExpression(PostfixExpression node) {
    if (identical(_oldNode, node.operand)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  AstNode visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (identical(_oldNode, node.prefix)) {
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.identifier)) {
      return _parser.parseSimpleIdentifier();
    }
    return notAChild(node);
  }

  AstNode visitPrefixExpression(PrefixExpression node) {
    if (identical(_oldNode, node.operand)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  AstNode visitPropertyAccess(PropertyAccess node) {
    if (identical(_oldNode, node.target)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.propertyName)) {
      return _parser.parseSimpleIdentifier();
    }
    return notAChild(node);
  }

  AstNode visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    if (identical(_oldNode, node.constructorName)) {
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.argumentList)) {
      return _parser.parseArgumentList();
    }
    return notAChild(node);
  }

  AstNode visitRethrowExpression(RethrowExpression node) => notAChild(node);

  AstNode visitReturnStatement(ReturnStatement node) {
    if (identical(_oldNode, node.expression)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  AstNode visitScriptTag(ScriptTag node) => notAChild(node);

  AstNode visitShowCombinator(ShowCombinator node) {
    if (node.shownNames.contains(_oldNode)) {
      return _parser.parseSimpleIdentifier();
    }
    return notAChild(node);
  }

  AstNode visitSimpleFormalParameter(SimpleFormalParameter node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.type)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.identifier)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  AstNode visitSimpleIdentifier(SimpleIdentifier node) => notAChild(node);

  AstNode visitSimpleStringLiteral(SimpleStringLiteral node) => notAChild(node);

  AstNode visitStringInterpolation(StringInterpolation node) {
    if (node.elements.contains(_oldNode)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  AstNode visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    if (identical(_oldNode, node.constructorName)) {
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.argumentList)) {
      return _parser.parseArgumentList();
    }
    return notAChild(node);
  }

  AstNode visitSuperExpression(SuperExpression node) => notAChild(node);

  AstNode visitSwitchCase(SwitchCase node) {
    if (node.labels.contains(_oldNode)) {
      return _parser.parseLabel();
    } else if (identical(_oldNode, node.expression)) {
      return _parser.parseExpression2();
    } else if (node.statements.contains(_oldNode)) {
      return _parser.parseStatement2();
    }
    return notAChild(node);
  }

  AstNode visitSwitchDefault(SwitchDefault node) {
    if (node.labels.contains(_oldNode)) {
      return _parser.parseLabel();
    } else if (node.statements.contains(_oldNode)) {
      return _parser.parseStatement2();
    }
    return notAChild(node);
  }

  AstNode visitSwitchStatement(SwitchStatement node) {
    if (identical(_oldNode, node.expression)) {
      return _parser.parseExpression2();
    } else if (node.members.contains(_oldNode)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  AstNode visitSymbolLiteral(SymbolLiteral node) => notAChild(node);

  AstNode visitThisExpression(ThisExpression node) => notAChild(node);

  AstNode visitThrowExpression(ThrowExpression node) {
    if (identical(_oldNode, node.expression)) {
      if (isCascadeAllowedInThrow(node)) {
        return _parser.parseExpression2();
      }
      return _parser.parseExpressionWithoutCascade();
    }
    return notAChild(node);
  }

  AstNode visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.variables)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  AstNode visitTryStatement(TryStatement node) {
    if (identical(_oldNode, node.body)) {
      return _parser.parseBlock();
    } else if (node.catchClauses.contains(_oldNode)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.finallyBlock)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  AstNode visitTypeArgumentList(TypeArgumentList node) {
    if (node.arguments.contains(_oldNode)) {
      return _parser.parseTypeName();
    }
    return notAChild(node);
  }

  AstNode visitTypeName(TypeName node) {
    if (identical(_oldNode, node.name)) {
      return _parser.parsePrefixedIdentifier();
    } else if (identical(_oldNode, node.typeArguments)) {
      return _parser.parseTypeArgumentList();
    }
    return notAChild(node);
  }

  AstNode visitTypeParameter(TypeParameter node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.name)) {
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.bound)) {
      return _parser.parseTypeName();
    }
    return notAChild(node);
  }

  AstNode visitTypeParameterList(TypeParameterList node) {
    if (node.typeParameters.contains(node)) {
      return _parser.parseTypeParameter();
    }
    return notAChild(node);
  }

  AstNode visitVariableDeclaration(VariableDeclaration node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.name)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.initializer)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  AstNode visitVariableDeclarationList(VariableDeclarationList node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (node.variables.contains(_oldNode)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  AstNode visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    if (identical(_oldNode, node.variables)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  AstNode visitWhileStatement(WhileStatement node) {
    if (identical(_oldNode, node.condition)) {
      return _parser.parseExpression2();
    } else if (identical(_oldNode, node.body)) {
      return _parser.parseStatement2();
    }
    return notAChild(node);
  }

  AstNode visitWithClause(WithClause node) {
    if (node.mixinTypes.contains(node)) {
      return _parser.parseTypeName();
    }
    return notAChild(node);
  }

  /**
   * Return `true` if the given assignment expression can have a cascade expression on the
   * right-hand side.
   *
   * @param node the assignment expression being tested
   * @return `true` if the right-hand side can be a cascade expression
   */
  bool isCascadeAllowedInAssignment(AssignmentExpression node) {
    // TODO(brianwilkerson) Implement this method.
    throw new InsufficientContextException();
  }

  /**
   * Return `true` if the given throw expression can have a cascade expression.
   *
   * @param node the throw expression being tested
   * @return `true` if the expression can be a cascade expression
   */
  bool isCascadeAllowedInThrow(ThrowExpression node) {
    // TODO(brianwilkerson) Implement this method.
    throw new InsufficientContextException();
  }

  /**
   * Throw an exception indicating that the visited node was not the parent of the node to be
   * replaced.
   *
   * @param visitedNode the visited node that should have been the parent of the node to be replaced
   */
  AstNode notAChild(AstNode visitedNode) {
    throw new IncrementalParseException.con1("Internal error: the visited node (a ${visitedNode.runtimeType.toString()}) was not the parent of the node to be replaced (a ${_oldNode.runtimeType.toString()})");
  }
}

/**
 * Instances of the class `IncrementalParseException` represent an exception that occurred
 * while attempting to parse a replacement for a specified node in an existing AST structure.
 */
class IncrementalParseException extends RuntimeException {
  /**
   * Initialize a newly created exception to have no message and to be its own cause.
   */
  IncrementalParseException() : super();

  /**
   * Initialize a newly created exception to have the given message and to be its own cause.
   *
   * @param message the message describing the reason for the exception
   */
  IncrementalParseException.con1(String message) : super(message: message);

  /**
   * Initialize a newly created exception to have no message and to have the given cause.
   *
   * @param cause the exception that caused this exception
   */
  IncrementalParseException.con2(Exception cause) : super(cause: cause);
}

/**
 * Instances of the class `IncrementalParser` re-parse a single AST structure within a larger
 * AST structure.
 */
class IncrementalParser {
  /**
   * The source being parsed.
   */
  Source _source;

  /**
   * A map from old tokens to new tokens used during the cloning process.
   */
  TokenMap _tokenMap;

  /**
   * The error listener that will be informed of any errors that are found during the parse.
   */
  AnalysisErrorListener _errorListener;

  /**
   * The node in the AST structure that contains the revised content.
   */
  AstNode _updatedNode;

  /**
   * Initialize a newly created incremental parser to parse a portion of the content of the given
   * source.
   *
   * @param source the source being parsed
   * @param tokenMap a map from old tokens to new tokens used during the cloning process
   * @param errorListener the error listener that will be informed of any errors that are found
   *          during the parse
   */
  IncrementalParser(Source source, TokenMap tokenMap, AnalysisErrorListener errorListener) {
    this._source = source;
    this._tokenMap = tokenMap;
    this._errorListener = errorListener;
  }

  /**
   * Return the node in the AST structure that contains the revised content.
   *
   * @return the updated node
   */
  AstNode get updatedNode => _updatedNode;

  /**
   * Given a range of tokens that were re-scanned, re-parse the minimum number of tokens to produce
   * a consistent AST structure. The range is represented by the first and last tokens in the range.
   * The tokens are assumed to be contained in the same token stream.
   *
   * @param leftToken the token in the new token stream immediately to the left of the range of
   *          tokens that were inserted
   * @param rightToken the token in the new token stream immediately to the right of the range of
   *          tokens that were inserted
   * @param originalStart the offset in the original source of the first character that was modified
   * @param originalEnd the offset in the original source of the last character that was modified
   */
  AstNode reparse(AstNode originalStructure, Token leftToken, Token rightToken, int originalStart, int originalEnd) {
    AstNode oldNode = null;
    AstNode newNode = null;
    //
    // Find the first token that needs to be re-parsed.
    //
    Token firstToken = leftToken.next;
    if (identical(firstToken, rightToken)) {
      // If there are no new tokens, then we need to include at least one copied node in the range.
      firstToken = leftToken;
    }
    //
    // Find the smallest AST node that encompasses the range of re-scanned tokens.
    //
    if (originalEnd < originalStart) {
      oldNode = new NodeLocator.con1(originalStart).searchWithin(originalStructure);
    } else {
      oldNode = new NodeLocator.con2(originalStart, originalEnd).searchWithin(originalStructure);
    }
    //
    // Find the token at which parsing is to begin.
    //
    int originalOffset = oldNode.offset;
    Token parseToken = findTokenAt(firstToken, originalOffset);
    if (parseToken == null) {
      return null;
    }
    //
    // Parse the appropriate AST structure starting at the appropriate place.
    //
    Parser parser = new Parser(_source, _errorListener);
    parser.currentToken = parseToken;
    while (newNode == null) {
      AstNode parent = oldNode.parent;
      if (parent == null) {
        parseToken = findFirstToken(parseToken);
        parser.currentToken = parseToken;
        return parser.parseCompilationUnit2();
      }
      bool advanceToParent = false;
      try {
        IncrementalParseDispatcher dispatcher = new IncrementalParseDispatcher(parser, oldNode);
        newNode = parent.accept(dispatcher);
        //
        // Validate that the new node can replace the old node.
        //
        Token mappedToken = _tokenMap.get(oldNode.endToken.next);
        if (mappedToken == null || mappedToken.offset != newNode.endToken.next.offset || newNode.offset != oldNode.offset) {
          advanceToParent = true;
        }
      } on InsufficientContextException catch (exception) {
        advanceToParent = true;
      } on JavaException catch (exception) {
        return null;
      }
      if (advanceToParent) {
        newNode = null;
        oldNode = parent;
        originalOffset = oldNode.offset;
        parseToken = findTokenAt(parseToken, originalOffset);
        parser.currentToken = parseToken;
      }
    }
    _updatedNode = newNode;
    //
    // Replace the old node with the new node in a copy of the original AST structure.
    //
    if (identical(oldNode, originalStructure)) {
      // We ended up re-parsing the whole structure, so there's no need for a copy.
      ResolutionCopier.copyResolutionData(oldNode, newNode);
      return newNode;
    }
    ResolutionCopier.copyResolutionData(oldNode, newNode);
    IncrementalAstCloner cloner = new IncrementalAstCloner(oldNode, newNode, _tokenMap);
    return originalStructure.accept(cloner) as AstNode;
  }

  /**
   * Return the first (non-EOF) token in the token stream containing the given token.
   *
   * @param firstToken the token from which the search is to begin
   * @return the first token in the token stream containing the given token
   */
  Token findFirstToken(Token firstToken) {
    while (firstToken.type != TokenType.EOF) {
      firstToken = firstToken.previous;
    }
    return firstToken.next;
  }

  /**
   * Find the token at or before the given token with the given offset, or `null` if there is
   * no such token.
   *
   * @param firstToken the token from which the search is to begin
   * @param offset the offset of the token to be returned
   * @return the token with the given offset
   */
  Token findTokenAt(Token firstToken, int offset) {
    while (firstToken.offset > offset && firstToken.type != TokenType.EOF) {
      firstToken = firstToken.previous;
    }
    return firstToken;
  }
}

/**
 * Instances of the class `InsufficientContextException` represent a situation in which an AST
 * node cannot be re-parsed because there is not enough context to know how to re-parse the node.
 * Clients can attempt to re-parse the parent of the node.
 */
class InsufficientContextException extends IncrementalParseException {
  /**
   * Initialize a newly created exception to have no message and to be its own cause.
   */
  InsufficientContextException() : super();

  /**
   * Initialize a newly created exception to have the given message and to be its own cause.
   *
   * @param message the message describing the reason for the exception
   */
  InsufficientContextException.con1(String message) : super.con1(message);

  /**
   * Initialize a newly created exception to have no message and to have the given cause.
   *
   * @param cause the exception that caused this exception
   */
  InsufficientContextException.con2(Exception cause) : super.con2(cause);
}

/**
 * Instances of the class `Parser` are used to parse tokens into an AST structure.
 */
class Parser {
  /**
   * The source being parsed.
   */
  Source _source;

  /**
   * The error listener that will be informed of any errors that are found during the parse.
   */
  AnalysisErrorListener _errorListener;

  /**
   * An [errorListener] lock, if more than `0`, then errors are not reported.
   */
  int _errorListenerLock = 0;

  /**
   * A flag indicating whether parser is to parse function bodies.
   */
  bool _parseFunctionBodies = true;

  /**
   * The next token to be parsed.
   */
  Token _currentToken;

  /**
   * A flag indicating whether the parser is currently in the body of a loop.
   */
  bool _inLoop = false;

  /**
   * A flag indicating whether the parser is currently in a switch statement.
   */
  bool _inSwitch = false;

  static String _HIDE = "hide";

  static String _OF = "of";

  static String _ON = "on";

  static String _NATIVE = "native";

  static String _SHOW = "show";

  /**
   * Initialize a newly created parser.
   *
   * @param source the source being parsed
   * @param errorListener the error listener that will be informed of any errors that are found
   *          during the parse
   */
  Parser(Source source, AnalysisErrorListener errorListener) {
    this._source = source;
    this._errorListener = errorListener;
  }

  /**
   * Parse a compilation unit, starting with the given token.
   *
   * @param token the first token of the compilation unit
   * @return the compilation unit that was parsed
   */
  CompilationUnit parseCompilationUnit(Token token) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("dart.engine.Parser.parseCompilationUnit");
    try {
      _currentToken = token;
      return parseCompilationUnit2();
    } finally {
      instrumentation.log2(2);
    }
  }

  /**
   * Parse an expression, starting with the given token.
   *
   * @param token the first token of the expression
   * @return the expression that was parsed, or `null` if the tokens do not represent a
   *         recognizable expression
   */
  Expression parseExpression(Token token) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("dart.engine.Parser.parseExpression");
    try {
      _currentToken = token;
      return parseExpression2();
    } finally {
      instrumentation.log();
    }
  }

  /**
   * Parse a statement, starting with the given token.
   *
   * @param token the first token of the statement
   * @return the statement that was parsed, or `null` if the tokens do not represent a
   *         recognizable statement
   */
  Statement parseStatement(Token token) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("dart.engine.Parser.parseStatement");
    try {
      _currentToken = token;
      return parseStatement2();
    } finally {
      instrumentation.log();
    }
  }

  /**
   * Parse a sequence of statements, starting with the given token.
   *
   * @param token the first token of the sequence of statement
   * @return the statements that were parsed, or `null` if the tokens do not represent a
   *         recognizable sequence of statements
   */
  List<Statement> parseStatements(Token token) {
    InstrumentationBuilder instrumentation = Instrumentation.builder2("dart.engine.Parser.parseStatements");
    try {
      _currentToken = token;
      return parseStatementList();
    } finally {
      instrumentation.log();
    }
  }

  /**
   * Set whether parser is to parse function bodies.
   *
   * @param parseFunctionBodies `true` if parser is to parse function bodies
   */
  void set parseFunctionBodies(bool parseFunctionBodies) {
    this._parseFunctionBodies = parseFunctionBodies;
  }

  /**
   * Parse an annotation.
   *
   * <pre>
   * annotation ::=
   *     '@' qualified ('.' identifier)? arguments?
   * </pre>
   *
   * @return the annotation that was parsed
   */
  Annotation parseAnnotation() {
    Token atSign = expect(TokenType.AT);
    Identifier name = parsePrefixedIdentifier();
    Token period = null;
    SimpleIdentifier constructorName = null;
    if (matches(TokenType.PERIOD)) {
      period = andAdvance;
      constructorName = parseSimpleIdentifier();
    }
    ArgumentList arguments = null;
    if (matches(TokenType.OPEN_PAREN)) {
      arguments = parseArgumentList();
    }
    return new Annotation(atSign, name, period, constructorName, arguments);
  }

  /**
   * Parse an argument.
   *
   * <pre>
   * argument ::=
   *     namedArgument
   *   | expression
   *
   * namedArgument ::=
   *     label expression
   * </pre>
   *
   * @return the argument that was parsed
   */
  Expression parseArgument() {
    //
    // Both namedArgument and expression can start with an identifier, but only namedArgument can
    // have an identifier followed by a colon.
    //
    if (matchesIdentifier() && tokenMatches(peek(), TokenType.COLON)) {
      return new NamedExpression(parseLabel(), parseExpression2());
    } else {
      return parseExpression2();
    }
  }

  /**
   * Parse a list of arguments.
   *
   * <pre>
   * arguments ::=
   *     '(' argumentList? ')'
   *
   * argumentList ::=
   *     namedArgument (',' namedArgument)*
   *   | expressionList (',' namedArgument)*
   * </pre>
   *
   * @return the argument list that was parsed
   */
  ArgumentList parseArgumentList() {
    Token leftParenthesis = expect(TokenType.OPEN_PAREN);
    List<Expression> arguments = new List<Expression>();
    if (matches(TokenType.CLOSE_PAREN)) {
      return new ArgumentList(leftParenthesis, arguments, andAdvance);
    }
    //
    // Even though unnamed arguments must all appear before any named arguments, we allow them to
    // appear in any order so that we can recover faster.
    //
    Expression argument = parseArgument();
    arguments.add(argument);
    bool foundNamedArgument = argument is NamedExpression;
    bool generatedError = false;
    while (optional(TokenType.COMMA)) {
      argument = parseArgument();
      arguments.add(argument);
      if (foundNamedArgument) {
        if (!generatedError && argument is! NamedExpression) {
          // Report the error, once, but allow the arguments to be in any order in the AST.
          reportErrorForCurrentToken(ParserErrorCode.POSITIONAL_AFTER_NAMED_ARGUMENT, []);
          generatedError = true;
        }
      } else if (argument is NamedExpression) {
        foundNamedArgument = true;
      }
    }
    // TODO(brianwilkerson) Recovery: Look at the left parenthesis to see whether there is a
    // matching right parenthesis. If there is, then we're more likely missing a comma and should
    // go back to parsing arguments.
    Token rightParenthesis = expect(TokenType.CLOSE_PAREN);
    return new ArgumentList(leftParenthesis, arguments, rightParenthesis);
  }

  /**
   * Parse a bitwise or expression.
   *
   * <pre>
   * bitwiseOrExpression ::=
   *     bitwiseXorExpression ('|' bitwiseXorExpression)*
   *   | 'super' ('|' bitwiseXorExpression)+
   * </pre>
   *
   * @return the bitwise or expression that was parsed
   */
  Expression parseBitwiseOrExpression() {
    Expression expression;
    if (matchesKeyword(Keyword.SUPER) && tokenMatches(peek(), TokenType.BAR)) {
      expression = new SuperExpression(andAdvance);
    } else {
      expression = parseBitwiseXorExpression();
    }
    while (matches(TokenType.BAR)) {
      Token operator = andAdvance;
      expression = new BinaryExpression(expression, operator, parseBitwiseXorExpression());
    }
    return expression;
  }

  /**
   * Parse a block.
   *
   * <pre>
   * block ::=
   *     '{' statements '}'
   * </pre>
   *
   * @return the block that was parsed
   */
  Block parseBlock() {
    Token leftBracket = expect(TokenType.OPEN_CURLY_BRACKET);
    List<Statement> statements = new List<Statement>();
    Token statementStart = _currentToken;
    while (!matches(TokenType.EOF) && !matches(TokenType.CLOSE_CURLY_BRACKET)) {
      Statement statement = parseStatement2();
      if (statement != null) {
        statements.add(statement);
      }
      if (identical(_currentToken, statementStart)) {
        // Ensure that we are making progress and report an error if we're not.
        reportErrorForToken(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken, [_currentToken.lexeme]);
        advance();
      }
      statementStart = _currentToken;
    }
    Token rightBracket = expect(TokenType.CLOSE_CURLY_BRACKET);
    return new Block(leftBracket, statements, rightBracket);
  }

  /**
   * Parse a class member.
   *
   * <pre>
   * classMemberDefinition ::=
   *     declaration ';'
   *   | methodSignature functionBody
   * </pre>
   *
   * @param className the name of the class containing the member being parsed
   * @return the class member that was parsed, or `null` if what was found was not a valid
   *         class member
   */
  ClassMember parseClassMember(String className) {
    CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
    Modifiers modifiers = parseModifiers();
    if (matchesKeyword(Keyword.VOID)) {
      TypeName returnType = parseReturnType();
      if (matchesKeyword(Keyword.GET) && tokenMatchesIdentifier(peek())) {
        validateModifiersForGetterOrSetterOrMethod(modifiers);
        return parseGetter(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, returnType);
      } else if (matchesKeyword(Keyword.SET) && tokenMatchesIdentifier(peek())) {
        validateModifiersForGetterOrSetterOrMethod(modifiers);
        return parseSetter(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, returnType);
      } else if (matchesKeyword(Keyword.OPERATOR) && isOperator(peek())) {
        validateModifiersForOperator(modifiers);
        return parseOperator(commentAndMetadata, modifiers.externalKeyword, returnType);
      } else if (matchesIdentifier() && matchesAny(peek(), [
          TokenType.OPEN_PAREN,
          TokenType.OPEN_CURLY_BRACKET,
          TokenType.FUNCTION])) {
        validateModifiersForGetterOrSetterOrMethod(modifiers);
        return parseMethodDeclarationAfterReturnType(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, returnType);
      } else {
        //
        // We have found an error of some kind. Try to recover.
        //
        if (matchesIdentifier()) {
          if (matchesAny(peek(), [TokenType.EQ, TokenType.COMMA, TokenType.SEMICOLON])) {
            //
            // We appear to have a variable declaration with a type of "void".
            //
            reportErrorForNode(ParserErrorCode.VOID_VARIABLE, returnType, []);
            return parseInitializedIdentifierList(commentAndMetadata, modifiers.staticKeyword, validateModifiersForField(modifiers), returnType);
          }
        }
        if (isOperator(_currentToken)) {
          //
          // We appear to have found an operator declaration without the 'operator' keyword.
          //
          validateModifiersForOperator(modifiers);
          return parseOperator(commentAndMetadata, modifiers.externalKeyword, returnType);
        }
        reportErrorForToken(ParserErrorCode.EXPECTED_EXECUTABLE, _currentToken, []);
        return null;
      }
    } else if (matchesKeyword(Keyword.GET) && tokenMatchesIdentifier(peek())) {
      validateModifiersForGetterOrSetterOrMethod(modifiers);
      return parseGetter(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, null);
    } else if (matchesKeyword(Keyword.SET) && tokenMatchesIdentifier(peek())) {
      validateModifiersForGetterOrSetterOrMethod(modifiers);
      return parseSetter(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, null);
    } else if (matchesKeyword(Keyword.OPERATOR) && isOperator(peek())) {
      validateModifiersForOperator(modifiers);
      return parseOperator(commentAndMetadata, modifiers.externalKeyword, null);
    } else if (!matchesIdentifier()) {
      if (isOperator(_currentToken)) {
        //
        // We appear to have found an operator declaration without the 'operator' keyword.
        //
        validateModifiersForOperator(modifiers);
        return parseOperator(commentAndMetadata, modifiers.externalKeyword, null);
      }
      reportErrorForToken(ParserErrorCode.EXPECTED_CLASS_MEMBER, _currentToken, []);
      if (commentAndMetadata.comment != null || !commentAndMetadata.metadata.isEmpty) {
        //
        // We appear to have found an incomplete declaration at the end of the class. At this point
        // it consists of a metadata, which we don't want to loose, so we'll treat it as a method
        // declaration with a missing name, parameters and empty body.
        //
        return new MethodDeclaration(commentAndMetadata.comment, commentAndMetadata.metadata, null, null, null, null, null, createSyntheticIdentifier(), new FormalParameterList(null, new List<FormalParameter>(), null, null, null), new EmptyFunctionBody(createSyntheticToken(TokenType.SEMICOLON)));
      }
      return null;
    } else if (tokenMatches(peek(), TokenType.PERIOD) && tokenMatchesIdentifier(peek2(2)) && tokenMatches(peek2(3), TokenType.OPEN_PAREN)) {
      return parseConstructor(commentAndMetadata, modifiers.externalKeyword, validateModifiersForConstructor(modifiers), modifiers.factoryKeyword, parseSimpleIdentifier(), andAdvance, parseSimpleIdentifier(), parseFormalParameterList());
    } else if (tokenMatches(peek(), TokenType.OPEN_PAREN)) {
      SimpleIdentifier methodName = parseSimpleIdentifier();
      FormalParameterList parameters = parseFormalParameterList();
      if (matches(TokenType.COLON) || modifiers.factoryKeyword != null || methodName.name == className) {
        return parseConstructor(commentAndMetadata, modifiers.externalKeyword, validateModifiersForConstructor(modifiers), modifiers.factoryKeyword, methodName, null, null, parameters);
      }
      validateModifiersForGetterOrSetterOrMethod(modifiers);
      validateFormalParameterList(parameters);
      return parseMethodDeclarationAfterParameters(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, null, methodName, parameters);
    } else if (matchesAny(peek(), [TokenType.EQ, TokenType.COMMA, TokenType.SEMICOLON])) {
      if (modifiers.constKeyword == null && modifiers.finalKeyword == null && modifiers.varKeyword == null) {
        reportErrorForCurrentToken(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, []);
      }
      return parseInitializedIdentifierList(commentAndMetadata, modifiers.staticKeyword, validateModifiersForField(modifiers), null);
    }
    TypeName type = parseTypeName();
    if (matchesKeyword(Keyword.GET) && tokenMatchesIdentifier(peek())) {
      validateModifiersForGetterOrSetterOrMethod(modifiers);
      return parseGetter(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, type);
    } else if (matchesKeyword(Keyword.SET) && tokenMatchesIdentifier(peek())) {
      validateModifiersForGetterOrSetterOrMethod(modifiers);
      return parseSetter(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, type);
    } else if (matchesKeyword(Keyword.OPERATOR) && isOperator(peek())) {
      validateModifiersForOperator(modifiers);
      return parseOperator(commentAndMetadata, modifiers.externalKeyword, type);
    } else if (!matchesIdentifier()) {
      if (matches(TokenType.CLOSE_CURLY_BRACKET)) {
        //
        // We appear to have found an incomplete declaration at the end of the class. At this point
        // it consists of a type name, so we'll treat it as a field declaration with a missing
        // field name and semicolon.
        //
        return parseInitializedIdentifierList(commentAndMetadata, modifiers.staticKeyword, validateModifiersForField(modifiers), type);
      }
      if (isOperator(_currentToken)) {
        //
        // We appear to have found an operator declaration without the 'operator' keyword.
        //
        validateModifiersForOperator(modifiers);
        return parseOperator(commentAndMetadata, modifiers.externalKeyword, type);
      }
      //
      // We appear to have found an incomplete declaration before another declaration.
      // At this point it consists of a type name, so we'll treat it as a field declaration
      // with a missing field name and semicolon.
      //
      reportErrorForToken(ParserErrorCode.EXPECTED_CLASS_MEMBER, _currentToken, []);
      try {
        lockErrorListener();
        return parseInitializedIdentifierList(commentAndMetadata, modifiers.staticKeyword, validateModifiersForField(modifiers), type);
      } finally {
        unlockErrorListener();
      }
    } else if (tokenMatches(peek(), TokenType.OPEN_PAREN)) {
      SimpleIdentifier methodName = parseSimpleIdentifier();
      FormalParameterList parameters = parseFormalParameterList();
      if (methodName.name == className) {
        reportErrorForNode(ParserErrorCode.CONSTRUCTOR_WITH_RETURN_TYPE, type, []);
        return parseConstructor(commentAndMetadata, modifiers.externalKeyword, validateModifiersForConstructor(modifiers), modifiers.factoryKeyword, methodName, null, null, parameters);
      }
      validateModifiersForGetterOrSetterOrMethod(modifiers);
      validateFormalParameterList(parameters);
      return parseMethodDeclarationAfterParameters(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, type, methodName, parameters);
    }
    return parseInitializedIdentifierList(commentAndMetadata, modifiers.staticKeyword, validateModifiersForField(modifiers), type);
  }

  /**
   * Parse a compilation unit.
   *
   * Specified:
   *
   * <pre>
   * compilationUnit ::=
   *     scriptTag? directive* topLevelDeclaration*
   * </pre>
   * Actual:
   *
   * <pre>
   * compilationUnit ::=
   *     scriptTag? topLevelElement*
   *
   * topLevelElement ::=
   *     directive
   *   | topLevelDeclaration
   * </pre>
   *
   * @return the compilation unit that was parsed
   */
  CompilationUnit parseCompilationUnit2() {
    Token firstToken = _currentToken;
    ScriptTag scriptTag = null;
    if (matches(TokenType.SCRIPT_TAG)) {
      scriptTag = new ScriptTag(andAdvance);
    }
    //
    // Even though all directives must appear before declarations and must occur in a given order,
    // we allow directives and declarations to occur in any order so that we can recover better.
    //
    bool libraryDirectiveFound = false;
    bool partOfDirectiveFound = false;
    bool partDirectiveFound = false;
    bool directiveFoundAfterDeclaration = false;
    List<Directive> directives = new List<Directive>();
    List<CompilationUnitMember> declarations = new List<CompilationUnitMember>();
    Token memberStart = _currentToken;
    while (!matches(TokenType.EOF)) {
      CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
      if ((matchesKeyword(Keyword.IMPORT) || matchesKeyword(Keyword.EXPORT) || matchesKeyword(Keyword.LIBRARY) || matchesKeyword(Keyword.PART)) && !tokenMatches(peek(), TokenType.PERIOD) && !tokenMatches(peek(), TokenType.LT) && !tokenMatches(peek(), TokenType.OPEN_PAREN)) {
        Directive directive = parseDirective(commentAndMetadata);
        if (declarations.length > 0 && !directiveFoundAfterDeclaration) {
          reportErrorForCurrentToken(ParserErrorCode.DIRECTIVE_AFTER_DECLARATION, []);
          directiveFoundAfterDeclaration = true;
        }
        if (directive is LibraryDirective) {
          if (libraryDirectiveFound) {
            reportErrorForCurrentToken(ParserErrorCode.MULTIPLE_LIBRARY_DIRECTIVES, []);
          } else {
            if (directives.length > 0) {
              reportErrorForToken(ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST, directive.libraryToken, []);
            }
            libraryDirectiveFound = true;
          }
        } else if (directive is PartDirective) {
          partDirectiveFound = true;
        } else if (partDirectiveFound) {
          if (directive is ExportDirective) {
            reportErrorForToken(ParserErrorCode.EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE, directive.keyword, []);
          } else if (directive is ImportDirective) {
            reportErrorForToken(ParserErrorCode.IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE, directive.keyword, []);
          }
        }
        if (directive is PartOfDirective) {
          if (partOfDirectiveFound) {
            reportErrorForCurrentToken(ParserErrorCode.MULTIPLE_PART_OF_DIRECTIVES, []);
          } else {
            int directiveCount = directives.length;
            for (int i = 0; i < directiveCount; i++) {
              reportErrorForToken(ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART, directives[i].keyword, []);
            }
            partOfDirectiveFound = true;
          }
        } else {
          if (partOfDirectiveFound) {
            reportErrorForToken(ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART, directive.keyword, []);
          }
        }
        directives.add(directive);
      } else if (matches(TokenType.SEMICOLON)) {
        reportErrorForToken(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken, [_currentToken.lexeme]);
        advance();
      } else {
        CompilationUnitMember member = parseCompilationUnitMember(commentAndMetadata);
        if (member != null) {
          declarations.add(member);
        }
      }
      if (identical(_currentToken, memberStart)) {
        reportErrorForToken(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken, [_currentToken.lexeme]);
        advance();
        while (!matches(TokenType.EOF) && !couldBeStartOfCompilationUnitMember()) {
          advance();
        }
      }
      memberStart = _currentToken;
    }
    return new CompilationUnit(firstToken, scriptTag, directives, declarations, _currentToken);
  }

  /**
   * Parse a conditional expression.
   *
   * <pre>
   * conditionalExpression ::=
   *     logicalOrExpression ('?' expressionWithoutCascade ':' expressionWithoutCascade)?
   * </pre>
   *
   * @return the conditional expression that was parsed
   */
  Expression parseConditionalExpression() {
    Expression condition = parseLogicalOrExpression();
    if (!matches(TokenType.QUESTION)) {
      return condition;
    }
    Token question = andAdvance;
    Expression thenExpression = parseExpressionWithoutCascade();
    Token colon = expect(TokenType.COLON);
    Expression elseExpression = parseExpressionWithoutCascade();
    return new ConditionalExpression(condition, question, thenExpression, colon, elseExpression);
  }

  /**
   * Parse the name of a constructor.
   *
   * <pre>
   * constructorName:
   *     type ('.' identifier)?
   * </pre>
   *
   * @return the constructor name that was parsed
   */
  ConstructorName parseConstructorName() {
    TypeName type = parseTypeName();
    Token period = null;
    SimpleIdentifier name = null;
    if (matches(TokenType.PERIOD)) {
      period = andAdvance;
      name = parseSimpleIdentifier();
    }
    return new ConstructorName(type, period, name);
  }

  /**
   * Parse an expression that does not contain any cascades.
   *
   * <pre>
   * expression ::=
   *     assignableExpression assignmentOperator expression
   *   | conditionalExpression cascadeSection*
   *   | throwExpression
   * </pre>
   *
   * @return the expression that was parsed
   */
  Expression parseExpression2() {
    if (matchesKeyword(Keyword.THROW)) {
      return parseThrowExpression();
    } else if (matchesKeyword(Keyword.RETHROW)) {
      return parseRethrowExpression();
    }
    //
    // assignableExpression is a subset of conditionalExpression, so we can parse a conditional
    // expression and then determine whether it is followed by an assignmentOperator, checking for
    // conformance to the restricted grammar after making that determination.
    //
    Expression expression = parseConditionalExpression();
    TokenType tokenType = _currentToken.type;
    if (identical(tokenType, TokenType.PERIOD_PERIOD)) {
      List<Expression> cascadeSections = new List<Expression>();
      while (identical(tokenType, TokenType.PERIOD_PERIOD)) {
        Expression section = parseCascadeSection();
        if (section != null) {
          cascadeSections.add(section);
        }
        tokenType = _currentToken.type;
      }
      return new CascadeExpression(expression, cascadeSections);
    } else if (tokenType.isAssignmentOperator) {
      Token operator = andAdvance;
      ensureAssignable(expression);
      return new AssignmentExpression(expression, operator, parseExpression2());
    }
    return expression;
  }

  /**
   * Parse an expression that does not contain any cascades.
   *
   * <pre>
   * expressionWithoutCascade ::=
   *     assignableExpression assignmentOperator expressionWithoutCascade
   *   | conditionalExpression
   *   | throwExpressionWithoutCascade
   * </pre>
   *
   * @return the expression that was parsed
   */
  Expression parseExpressionWithoutCascade() {
    if (matchesKeyword(Keyword.THROW)) {
      return parseThrowExpressionWithoutCascade();
    } else if (matchesKeyword(Keyword.RETHROW)) {
      return parseRethrowExpression();
    }
    //
    // assignableExpression is a subset of conditionalExpression, so we can parse a conditional
    // expression and then determine whether it is followed by an assignmentOperator, checking for
    // conformance to the restricted grammar after making that determination.
    //
    Expression expression = parseConditionalExpression();
    if (_currentToken.type.isAssignmentOperator) {
      Token operator = andAdvance;
      ensureAssignable(expression);
      expression = new AssignmentExpression(expression, operator, parseExpressionWithoutCascade());
    }
    return expression;
  }

  /**
   * Parse a class extends clause.
   *
   * <pre>
   * classExtendsClause ::=
   *     'extends' type
   * </pre>
   *
   * @return the class extends clause that was parsed
   */
  ExtendsClause parseExtendsClause() {
    Token keyword = expectKeyword(Keyword.EXTENDS);
    TypeName superclass = parseTypeName();
    return new ExtendsClause(keyword, superclass);
  }

  /**
   * Parse a list of formal parameters.
   *
   * <pre>
   * formalParameterList ::=
   *     '(' ')'
   *   | '(' normalFormalParameters (',' optionalFormalParameters)? ')'
   *   | '(' optionalFormalParameters ')'
   *
   * normalFormalParameters ::=
   *     normalFormalParameter (',' normalFormalParameter)*
   *
   * optionalFormalParameters ::=
   *     optionalPositionalFormalParameters
   *   | namedFormalParameters
   *
   * optionalPositionalFormalParameters ::=
   *     '[' defaultFormalParameter (',' defaultFormalParameter)* ']'
   *
   * namedFormalParameters ::=
   *     '{' defaultNamedParameter (',' defaultNamedParameter)* '}'
   * </pre>
   *
   * @return the formal parameters that were parsed
   */
  FormalParameterList parseFormalParameterList() {
    Token leftParenthesis = expect(TokenType.OPEN_PAREN);
    if (matches(TokenType.CLOSE_PAREN)) {
      return new FormalParameterList(leftParenthesis, null, null, null, andAdvance);
    }
    //
    // Even though it is invalid to have default parameters outside of brackets, required parameters
    // inside of brackets, or multiple groups of default and named parameters, we allow all of these
    // cases so that we can recover better.
    //
    List<FormalParameter> parameters = new List<FormalParameter>();
    List<FormalParameter> normalParameters = new List<FormalParameter>();
    List<FormalParameter> positionalParameters = new List<FormalParameter>();
    List<FormalParameter> namedParameters = new List<FormalParameter>();
    List<FormalParameter> currentParameters = normalParameters;
    Token leftSquareBracket = null;
    Token rightSquareBracket = null;
    Token leftCurlyBracket = null;
    Token rightCurlyBracket = null;
    ParameterKind kind = ParameterKind.REQUIRED;
    bool firstParameter = true;
    bool reportedMuliplePositionalGroups = false;
    bool reportedMulipleNamedGroups = false;
    bool reportedMixedGroups = false;
    bool wasOptionalParameter = false;
    Token initialToken = null;
    do {
      if (firstParameter) {
        firstParameter = false;
      } else if (!optional(TokenType.COMMA)) {
        // TODO(brianwilkerson) The token is wrong, we need to recover from this case.
        if (getEndToken(leftParenthesis) != null) {
          reportErrorForCurrentToken(ParserErrorCode.EXPECTED_TOKEN, [TokenType.COMMA.lexeme]);
        } else {
          reportErrorForToken(ParserErrorCode.MISSING_CLOSING_PARENTHESIS, _currentToken.previous, []);
          break;
        }
      }
      initialToken = _currentToken;
      //
      // Handle the beginning of parameter groups.
      //
      if (matches(TokenType.OPEN_SQUARE_BRACKET)) {
        wasOptionalParameter = true;
        if (leftSquareBracket != null && !reportedMuliplePositionalGroups) {
          reportErrorForCurrentToken(ParserErrorCode.MULTIPLE_POSITIONAL_PARAMETER_GROUPS, []);
          reportedMuliplePositionalGroups = true;
        }
        if (leftCurlyBracket != null && !reportedMixedGroups) {
          reportErrorForCurrentToken(ParserErrorCode.MIXED_PARAMETER_GROUPS, []);
          reportedMixedGroups = true;
        }
        leftSquareBracket = andAdvance;
        currentParameters = positionalParameters;
        kind = ParameterKind.POSITIONAL;
      } else if (matches(TokenType.OPEN_CURLY_BRACKET)) {
        wasOptionalParameter = true;
        if (leftCurlyBracket != null && !reportedMulipleNamedGroups) {
          reportErrorForCurrentToken(ParserErrorCode.MULTIPLE_NAMED_PARAMETER_GROUPS, []);
          reportedMulipleNamedGroups = true;
        }
        if (leftSquareBracket != null && !reportedMixedGroups) {
          reportErrorForCurrentToken(ParserErrorCode.MIXED_PARAMETER_GROUPS, []);
          reportedMixedGroups = true;
        }
        leftCurlyBracket = andAdvance;
        currentParameters = namedParameters;
        kind = ParameterKind.NAMED;
      }
      //
      // Parse and record the parameter.
      //
      FormalParameter parameter = parseFormalParameter(kind);
      parameters.add(parameter);
      currentParameters.add(parameter);
      if (identical(kind, ParameterKind.REQUIRED) && wasOptionalParameter) {
        reportErrorForNode(ParserErrorCode.NORMAL_BEFORE_OPTIONAL_PARAMETERS, parameter, []);
      }
      //
      // Handle the end of parameter groups.
      //
      // TODO(brianwilkerson) Improve the detection and reporting of missing and mismatched delimiters.
      if (matches(TokenType.CLOSE_SQUARE_BRACKET)) {
        rightSquareBracket = andAdvance;
        currentParameters = normalParameters;
        if (leftSquareBracket == null) {
          if (leftCurlyBracket != null) {
            reportErrorForCurrentToken(ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP, ["}"]);
            rightCurlyBracket = rightSquareBracket;
            rightSquareBracket = null;
          } else {
            reportErrorForCurrentToken(ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP, ["["]);
          }
        }
        kind = ParameterKind.REQUIRED;
      } else if (matches(TokenType.CLOSE_CURLY_BRACKET)) {
        rightCurlyBracket = andAdvance;
        currentParameters = normalParameters;
        if (leftCurlyBracket == null) {
          if (leftSquareBracket != null) {
            reportErrorForCurrentToken(ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP, ["]"]);
            rightSquareBracket = rightCurlyBracket;
            rightCurlyBracket = null;
          } else {
            reportErrorForCurrentToken(ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP, ["{"]);
          }
        }
        kind = ParameterKind.REQUIRED;
      }
    } while (!matches(TokenType.CLOSE_PAREN) && initialToken != _currentToken);
    Token rightParenthesis = expect(TokenType.CLOSE_PAREN);
    //
    // Check that the groups were closed correctly.
    //
    if (leftSquareBracket != null && rightSquareBracket == null) {
      reportErrorForCurrentToken(ParserErrorCode.MISSING_TERMINATOR_FOR_PARAMETER_GROUP, ["]"]);
    }
    if (leftCurlyBracket != null && rightCurlyBracket == null) {
      reportErrorForCurrentToken(ParserErrorCode.MISSING_TERMINATOR_FOR_PARAMETER_GROUP, ["}"]);
    }
    //
    // Build the parameter list.
    //
    if (leftSquareBracket == null) {
      leftSquareBracket = leftCurlyBracket;
    }
    if (rightSquareBracket == null) {
      rightSquareBracket = rightCurlyBracket;
    }
    return new FormalParameterList(leftParenthesis, parameters, leftSquareBracket, rightSquareBracket, rightParenthesis);
  }

  /**
   * Parse a function expression.
   *
   * <pre>
   * functionExpression ::=
   *     formalParameterList functionExpressionBody
   * </pre>
   *
   * @return the function expression that was parsed
   */
  FunctionExpression parseFunctionExpression() {
    FormalParameterList parameters = parseFormalParameterList();
    validateFormalParameterList(parameters);
    FunctionBody body = parseFunctionBody(false, ParserErrorCode.MISSING_FUNCTION_BODY, true);
    return new FunctionExpression(parameters, body);
  }

  /**
   * Parse an implements clause.
   *
   * <pre>
   * implementsClause ::=
   *     'implements' type (',' type)*
   * </pre>
   *
   * @return the implements clause that was parsed
   */
  ImplementsClause parseImplementsClause() {
    Token keyword = expectKeyword(Keyword.IMPLEMENTS);
    List<TypeName> interfaces = new List<TypeName>();
    interfaces.add(parseTypeName());
    while (optional(TokenType.COMMA)) {
      interfaces.add(parseTypeName());
    }
    return new ImplementsClause(keyword, interfaces);
  }

  /**
   * Parse a label.
   *
   * <pre>
   * label ::=
   *     identifier ':'
   * </pre>
   *
   * @return the label that was parsed
   */
  Label parseLabel() {
    SimpleIdentifier label = parseSimpleIdentifier();
    Token colon = expect(TokenType.COLON);
    return new Label(label, colon);
  }

  /**
   * Parse a library identifier.
   *
   * <pre>
   * libraryIdentifier ::=
   *     identifier ('.' identifier)*
   * </pre>
   *
   * @return the library identifier that was parsed
   */
  LibraryIdentifier parseLibraryIdentifier() {
    List<SimpleIdentifier> components = new List<SimpleIdentifier>();
    components.add(parseSimpleIdentifier());
    while (matches(TokenType.PERIOD)) {
      advance();
      components.add(parseSimpleIdentifier());
    }
    return new LibraryIdentifier(components);
  }

  /**
   * Parse a logical or expression.
   *
   * <pre>
   * logicalOrExpression ::=
   *     logicalAndExpression ('||' logicalAndExpression)*
   * </pre>
   *
   * @return the logical or expression that was parsed
   */
  Expression parseLogicalOrExpression() {
    Expression expression = parseLogicalAndExpression();
    while (matches(TokenType.BAR_BAR)) {
      Token operator = andAdvance;
      expression = new BinaryExpression(expression, operator, parseLogicalAndExpression());
    }
    return expression;
  }

  /**
   * Parse a map literal entry.
   *
   * <pre>
   * mapLiteralEntry ::=
   *     expression ':' expression
   * </pre>
   *
   * @return the map literal entry that was parsed
   */
  MapLiteralEntry parseMapLiteralEntry() {
    Expression key = parseExpression2();
    Token separator = expect(TokenType.COLON);
    Expression value = parseExpression2();
    return new MapLiteralEntry(key, separator, value);
  }

  /**
   * Parse a normal formal parameter.
   *
   * <pre>
   * normalFormalParameter ::=
   *     functionSignature
   *   | fieldFormalParameter
   *   | simpleFormalParameter
   *
   * functionSignature:
   *     metadata returnType? identifier formalParameterList
   *
   * fieldFormalParameter ::=
   *     metadata finalConstVarOrType? 'this' '.' identifier
   *
   * simpleFormalParameter ::=
   *     declaredIdentifier
   *   | metadata identifier
   * </pre>
   *
   * @return the normal formal parameter that was parsed
   */
  NormalFormalParameter parseNormalFormalParameter() {
    CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
    FinalConstVarOrType holder = parseFinalConstVarOrType(true);
    Token thisKeyword = null;
    Token period = null;
    if (matchesKeyword(Keyword.THIS)) {
      thisKeyword = andAdvance;
      period = expect(TokenType.PERIOD);
    }
    SimpleIdentifier identifier = parseSimpleIdentifier();
    if (matches(TokenType.OPEN_PAREN)) {
      FormalParameterList parameters = parseFormalParameterList();
      if (thisKeyword == null) {
        if (holder.keyword != null) {
          reportErrorForToken(ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR, holder.keyword, []);
        }
        return new FunctionTypedFormalParameter(commentAndMetadata.comment, commentAndMetadata.metadata, holder.type, identifier, parameters);
      } else {
        return new FieldFormalParameter(commentAndMetadata.comment, commentAndMetadata.metadata, holder.keyword, holder.type, thisKeyword, period, identifier, parameters);
      }
    }
    TypeName type = holder.type;
    if (type != null) {
      if (tokenMatchesKeyword(type.name.beginToken, Keyword.VOID)) {
        reportErrorForToken(ParserErrorCode.VOID_PARAMETER, type.name.beginToken, []);
      } else if (holder.keyword != null && tokenMatchesKeyword(holder.keyword, Keyword.VAR)) {
        reportErrorForToken(ParserErrorCode.VAR_AND_TYPE, holder.keyword, []);
      }
    }
    if (thisKeyword != null) {
      return new FieldFormalParameter(commentAndMetadata.comment, commentAndMetadata.metadata, holder.keyword, holder.type, thisKeyword, period, identifier, null);
    }
    return new SimpleFormalParameter(commentAndMetadata.comment, commentAndMetadata.metadata, holder.keyword, holder.type, identifier);
  }

  /**
   * Parse a prefixed identifier.
   *
   * <pre>
   * prefixedIdentifier ::=
   *     identifier ('.' identifier)?
   * </pre>
   *
   * @return the prefixed identifier that was parsed
   */
  Identifier parsePrefixedIdentifier() {
    SimpleIdentifier qualifier = parseSimpleIdentifier();
    if (!matches(TokenType.PERIOD)) {
      return qualifier;
    }
    Token period = andAdvance;
    SimpleIdentifier qualified = parseSimpleIdentifier();
    return new PrefixedIdentifier(qualifier, period, qualified);
  }

  /**
   * Parse a return type.
   *
   * <pre>
   * returnType ::=
   *     'void'
   *   | type
   * </pre>
   *
   * @return the return type that was parsed
   */
  TypeName parseReturnType() {
    if (matchesKeyword(Keyword.VOID)) {
      return new TypeName(new SimpleIdentifier(andAdvance), null);
    } else {
      return parseTypeName();
    }
  }

  /**
   * Parse a simple identifier.
   *
   * <pre>
   * identifier ::=
   *     IDENTIFIER
   * </pre>
   *
   * @return the simple identifier that was parsed
   */
  SimpleIdentifier parseSimpleIdentifier() {
    if (matchesIdentifier()) {
      return new SimpleIdentifier(andAdvance);
    }
    reportErrorForCurrentToken(ParserErrorCode.MISSING_IDENTIFIER, []);
    return createSyntheticIdentifier();
  }

  /**
   * Parse a statement.
   *
   * <pre>
   * statement ::=
   *     label* nonLabeledStatement
   * </pre>
   *
   * @return the statement that was parsed
   */
  Statement parseStatement2() {
    List<Label> labels = new List<Label>();
    while (matchesIdentifier() && tokenMatches(peek(), TokenType.COLON)) {
      labels.add(parseLabel());
    }
    Statement statement = parseNonLabeledStatement();
    if (labels.isEmpty) {
      return statement;
    }
    return new LabeledStatement(labels, statement);
  }

  /**
   * Parse a string literal.
   *
   * <pre>
   * stringLiteral ::=
   *     MULTI_LINE_STRING+
   *   | SINGLE_LINE_STRING+
   * </pre>
   *
   * @return the string literal that was parsed
   */
  StringLiteral parseStringLiteral() {
    List<StringLiteral> strings = new List<StringLiteral>();
    while (matches(TokenType.STRING)) {
      Token string = andAdvance;
      if (matches(TokenType.STRING_INTERPOLATION_EXPRESSION) || matches(TokenType.STRING_INTERPOLATION_IDENTIFIER)) {
        strings.add(parseStringInterpolation(string));
      } else {
        strings.add(new SimpleStringLiteral(string, computeStringValue(string.lexeme, true, true)));
      }
    }
    if (strings.length < 1) {
      reportErrorForCurrentToken(ParserErrorCode.EXPECTED_STRING_LITERAL, []);
      return createSyntheticStringLiteral();
    } else if (strings.length == 1) {
      return strings[0];
    } else {
      return new AdjacentStrings(strings);
    }
  }

  /**
   * Parse a list of type arguments.
   *
   * <pre>
   * typeArguments ::=
   *     '<' typeList '>'
   *
   * typeList ::=
   *     type (',' type)*
   * </pre>
   *
   * @return the type argument list that was parsed
   */
  TypeArgumentList parseTypeArgumentList() {
    Token leftBracket = expect(TokenType.LT);
    List<TypeName> arguments = new List<TypeName>();
    arguments.add(parseTypeName());
    while (optional(TokenType.COMMA)) {
      arguments.add(parseTypeName());
    }
    Token rightBracket = expect(TokenType.GT);
    return new TypeArgumentList(leftBracket, arguments, rightBracket);
  }

  /**
   * Parse a type name.
   *
   * <pre>
   * type ::=
   *     qualified typeArguments?
   * </pre>
   *
   * @return the type name that was parsed
   */
  TypeName parseTypeName() {
    Identifier typeName;
    if (matchesKeyword(Keyword.VAR)) {
      reportErrorForCurrentToken(ParserErrorCode.VAR_AS_TYPE_NAME, []);
      typeName = new SimpleIdentifier(andAdvance);
    } else if (matchesIdentifier()) {
      typeName = parsePrefixedIdentifier();
    } else {
      typeName = createSyntheticIdentifier();
      reportErrorForCurrentToken(ParserErrorCode.EXPECTED_TYPE_NAME, []);
    }
    TypeArgumentList typeArguments = null;
    if (matches(TokenType.LT)) {
      typeArguments = parseTypeArgumentList();
    }
    return new TypeName(typeName, typeArguments);
  }

  /**
   * Parse a type parameter.
   *
   * <pre>
   * typeParameter ::=
   *     metadata name ('extends' bound)?
   * </pre>
   *
   * @return the type parameter that was parsed
   */
  TypeParameter parseTypeParameter() {
    CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
    SimpleIdentifier name = parseSimpleIdentifier();
    if (matchesKeyword(Keyword.EXTENDS)) {
      Token keyword = andAdvance;
      TypeName bound = parseTypeName();
      return new TypeParameter(commentAndMetadata.comment, commentAndMetadata.metadata, name, keyword, bound);
    }
    return new TypeParameter(commentAndMetadata.comment, commentAndMetadata.metadata, name, null, null);
  }

  /**
   * Parse a list of type parameters.
   *
   * <pre>
   * typeParameterList ::=
   *     '<' typeParameter (',' typeParameter)* '>'
   * </pre>
   *
   * @return the list of type parameters that were parsed
   */
  TypeParameterList parseTypeParameterList() {
    Token leftBracket = expect(TokenType.LT);
    List<TypeParameter> typeParameters = new List<TypeParameter>();
    typeParameters.add(parseTypeParameter());
    while (optional(TokenType.COMMA)) {
      typeParameters.add(parseTypeParameter());
    }
    Token rightBracket = expect(TokenType.GT);
    return new TypeParameterList(leftBracket, typeParameters, rightBracket);
  }

  /**
   * Parse a with clause.
   *
   * <pre>
   * withClause ::=
   *     'with' typeName (',' typeName)*
   * </pre>
   *
   * @return the with clause that was parsed
   */
  WithClause parseWithClause() {
    Token with2 = expectKeyword(Keyword.WITH);
    List<TypeName> types = new List<TypeName>();
    types.add(parseTypeName());
    while (optional(TokenType.COMMA)) {
      types.add(parseTypeName());
    }
    return new WithClause(with2, types);
  }

  void set currentToken(Token currentToken) {
    this._currentToken = currentToken;
  }

  /**
   * Advance to the next token in the token stream.
   */
  void advance() {
    _currentToken = _currentToken.next;
  }

  /**
   * Append the character equivalent of the given scalar value to the given builder. Use the start
   * and end indices to report an error, and don't append anything to the builder, if the scalar
   * value is invalid.
   *
   * @param builder the builder to which the scalar value is to be appended
   * @param escapeSequence the escape sequence that was parsed to produce the scalar value
   * @param scalarValue the value to be appended
   * @param startIndex the index of the first character representing the scalar value
   * @param endIndex the index of the last character representing the scalar value
   */
  void appendScalarValue(JavaStringBuilder builder, String escapeSequence, int scalarValue, int startIndex, int endIndex) {
    if (scalarValue < 0 || scalarValue > Character.MAX_CODE_POINT || (scalarValue >= 0xD800 && scalarValue <= 0xDFFF)) {
      reportErrorForCurrentToken(ParserErrorCode.INVALID_CODE_POINT, [escapeSequence]);
      return;
    }
    if (scalarValue < Character.MAX_VALUE) {
      builder.appendChar(scalarValue);
    } else {
      builder.append(Character.toChars(scalarValue));
    }
  }

  /**
   * Compute the content of a string with the given literal representation.
   *
   * @param lexeme the literal representation of the string
   * @param first `true` if this is the first token in a string literal
   * @param last `true` if this is the last token in a string literal
   * @return the actual value of the string
   */
  String computeStringValue(String lexeme, bool first, bool last) {
    bool isRaw = false;
    int start = 0;
    if (first) {
      if (StringUtilities.startsWith4(lexeme, 0, 0x72, 0x22, 0x22, 0x22) || StringUtilities.startsWith4(lexeme, 0, 0x72, 0x27, 0x27, 0x27)) {
        isRaw = true;
        start += 4;
      } else if (StringUtilities.startsWith2(lexeme, 0, 0x72, 0x22) || StringUtilities.startsWith2(lexeme, 0, 0x72, 0x27)) {
        isRaw = true;
        start += 2;
      } else if (StringUtilities.startsWith3(lexeme, 0, 0x22, 0x22, 0x22) || StringUtilities.startsWith3(lexeme, 0, 0x27, 0x27, 0x27)) {
        start += 3;
      } else if (StringUtilities.startsWithChar(lexeme, 0x22) || StringUtilities.startsWithChar(lexeme, 0x27)) {
        start += 1;
      }
    }
    int end = lexeme.length;
    if (last) {
      if (StringUtilities.endsWith3(lexeme, 0x22, 0x22, 0x22) || StringUtilities.endsWith3(lexeme, 0x27, 0x27, 0x27)) {
        end -= 3;
      } else if (StringUtilities.endsWithChar(lexeme, 0x22) || StringUtilities.endsWithChar(lexeme, 0x27)) {
        end -= 1;
      }
    }
    if (end - start + 1 < 0) {
      AnalysisEngine.instance.logger.logError("Internal error: computeStringValue(${lexeme}, ${first}, ${last})");
      return "";
    }
    if (isRaw) {
      return lexeme.substring(start, end);
    }
    JavaStringBuilder builder = new JavaStringBuilder();
    int index = start;
    while (index < end) {
      index = translateCharacter(builder, lexeme, index);
    }
    return builder.toString();
  }

  /**
   * Convert the given method declaration into the nearest valid top-level function declaration.
   *
   * @param method the method to be converted
   * @return the function declaration that most closely captures the components of the given method
   *         declaration
   */
  FunctionDeclaration convertToFunctionDeclaration(MethodDeclaration method) => new FunctionDeclaration(method.documentationComment, method.metadata, method.externalKeyword, method.returnType, method.propertyKeyword, method.name, new FunctionExpression(method.parameters, method.body));

  /**
   * Return `true` if the current token could be the start of a compilation unit member. This
   * method is used for recovery purposes to decide when to stop skipping tokens after finding an
   * error while parsing a compilation unit member.
   *
   * @return `true` if the current token could be the start of a compilation unit member
   */
  bool couldBeStartOfCompilationUnitMember() {
    if ((matchesKeyword(Keyword.IMPORT) || matchesKeyword(Keyword.EXPORT) || matchesKeyword(Keyword.LIBRARY) || matchesKeyword(Keyword.PART)) && !tokenMatches(peek(), TokenType.PERIOD) && !tokenMatches(peek(), TokenType.LT)) {
      // This looks like the start of a directive
      return true;
    } else if (matchesKeyword(Keyword.CLASS)) {
      // This looks like the start of a class definition
      return true;
    } else if (matchesKeyword(Keyword.TYPEDEF) && !tokenMatches(peek(), TokenType.PERIOD) && !tokenMatches(peek(), TokenType.LT)) {
      // This looks like the start of a typedef
      return true;
    } else if (matchesKeyword(Keyword.VOID) || ((matchesKeyword(Keyword.GET) || matchesKeyword(Keyword.SET)) && tokenMatchesIdentifier(peek())) || (matchesKeyword(Keyword.OPERATOR) && isOperator(peek()))) {
      // This looks like the start of a function
      return true;
    } else if (matchesIdentifier()) {
      if (tokenMatches(peek(), TokenType.OPEN_PAREN)) {
        // This looks like the start of a function
        return true;
      }
      Token token = skipReturnType(_currentToken);
      if (token == null) {
        return false;
      }
      if (matchesKeyword(Keyword.GET) || matchesKeyword(Keyword.SET) || (matchesKeyword(Keyword.OPERATOR) && isOperator(peek())) || matchesIdentifier()) {
        return true;
      }
    }
    return false;
  }

  /**
   * Create a synthetic identifier.
   *
   * @return the synthetic identifier that was created
   */
  SimpleIdentifier createSyntheticIdentifier() {
    Token syntheticToken;
    if (identical(_currentToken.type, TokenType.KEYWORD)) {
      // Consider current keyword token as an identifier.
      // It is not always true, e.g. "^is T" where "^" is place the place for synthetic identifier.
      // By creating SyntheticStringToken we can distinguish a real identifier from synthetic.
      // In the code completion behavior will depend on a cursor position - before or on "is".
      syntheticToken = injectToken(new SyntheticStringToken(TokenType.IDENTIFIER, _currentToken.lexeme, _currentToken.offset));
    } else {
      syntheticToken = createSyntheticToken(TokenType.IDENTIFIER);
    }
    return new SimpleIdentifier(syntheticToken);
  }

  /**
   * Create a synthetic token representing the given keyword.
   *
   * @return the synthetic token that was created
   */
  Token createSyntheticKeyword(Keyword keyword) => injectToken(new Parser_SyntheticKeywordToken(keyword, _currentToken.offset));

  /**
   * Create a synthetic string literal.
   *
   * @return the synthetic string literal that was created
   */
  SimpleStringLiteral createSyntheticStringLiteral() => new SimpleStringLiteral(createSyntheticToken(TokenType.STRING), "");

  /**
   * Create a synthetic token with the given type.
   *
   * @return the synthetic token that was created
   */
  Token createSyntheticToken(TokenType type) => injectToken(new StringToken(type, "", _currentToken.offset));

  /**
   * Check that the given expression is assignable and report an error if it isn't.
   *
   * <pre>
   * assignableExpression ::=
   *     primary (arguments* assignableSelector)+
   *   | 'super' assignableSelector
   *   | identifier
   *
   * assignableSelector ::=
   *     '[' expression ']'
   *   | '.' identifier
   * </pre>
   *
   * @param expression the expression being checked
   */
  void ensureAssignable(Expression expression) {
    if (expression != null && !expression.isAssignable) {
      reportErrorForCurrentToken(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, []);
    }
  }

  /**
   * If the current token has the expected type, return it after advancing to the next token.
   * Otherwise report an error and return the current token without advancing.
   *
   * @param type the type of token that is expected
   * @return the token that matched the given type
   */
  Token expect(TokenType type) {
    if (matches(type)) {
      return andAdvance;
    }
    // Remove uses of this method in favor of matches?
    // Pass in the error code to use to report the error?
    if (identical(type, TokenType.SEMICOLON)) {
      reportErrorForToken(ParserErrorCode.EXPECTED_TOKEN, _currentToken.previous, [type.lexeme]);
    } else {
      reportErrorForCurrentToken(ParserErrorCode.EXPECTED_TOKEN, [type.lexeme]);
    }
    return _currentToken;
  }

  /**
   * If the current token is a keyword matching the given string, return it after advancing to the
   * next token. Otherwise report an error and return the current token without advancing.
   *
   * @param keyword the keyword that is expected
   * @return the token that matched the given type
   */
  Token expectKeyword(Keyword keyword) {
    if (matchesKeyword(keyword)) {
      return andAdvance;
    }
    // Remove uses of this method in favor of matches?
    // Pass in the error code to use to report the error?
    reportErrorForCurrentToken(ParserErrorCode.EXPECTED_TOKEN, [keyword.syntax]);
    return _currentToken;
  }

  /**
   * If [currentToken] is a semicolon, returns it; otherwise reports error and creates a
   * synthetic one.
   *
   * TODO(scheglov) consider pushing this into [expect]
   */
  Token expectSemicolon() {
    if (matches(TokenType.SEMICOLON)) {
      return andAdvance;
    } else {
      reportErrorForToken(ParserErrorCode.EXPECTED_TOKEN, _currentToken.previous, [";"]);
      return createSyntheticToken(TokenType.SEMICOLON);
    }
  }

  /**
   * Search the given list of ranges for a range that contains the given index. Return the range
   * that was found, or `null` if none of the ranges contain the index.
   *
   * @param ranges the ranges to be searched
   * @param index the index contained in the returned range
   * @return the range that was found
   */
  List<int> findRange(List<List<int>> ranges, int index) {
    int rangeCount = ranges.length;
    for (int i = 0; i < rangeCount; i++) {
      List<int> range = ranges[i];
      if (range[0] <= index && index <= range[1]) {
        return range;
      } else if (index < range[0]) {
        return null;
      }
    }
    return null;
  }

  /**
   * Advance to the next token in the token stream, making it the new current token.
   *
   * @return the token that was current before this method was invoked
   */
  Token get andAdvance {
    Token token = _currentToken;
    advance();
    return token;
  }

  /**
   * Return a list of the ranges of characters in the given comment string that should be treated as
   * code blocks.
   *
   * @param comment the comment being processed
   * @return the ranges of characters that should be treated as code blocks
   */
  List<List<int>> getCodeBlockRanges(String comment) {
    List<List<int>> ranges = new List<List<int>>();
    int length = comment.length;
    if (length < 3) {
      return ranges;
    }
    int index = 0;
    int firstChar = comment.codeUnitAt(0);
    if (firstChar == 0x2F) {
      int secondChar = comment.codeUnitAt(1);
      int thirdChar = comment.codeUnitAt(2);
      if ((secondChar == 0x2A && thirdChar == 0x2A) || (secondChar == 0x2F && thirdChar == 0x2F)) {
        index = 3;
      }
    }
    while (index < length) {
      int currentChar = comment.codeUnitAt(index);
      if (currentChar == 0xD || currentChar == 0xA) {
        index = index + 1;
        while (index < length && Character.isWhitespace(comment.codeUnitAt(index))) {
          index = index + 1;
        }
        if (StringUtilities.startsWith6(comment, index, 0x2A, 0x20, 0x20, 0x20, 0x20, 0x20)) {
          int end = index + 6;
          while (end < length && comment.codeUnitAt(end) != 0xD && comment.codeUnitAt(end) != 0xA) {
            end = end + 1;
          }
          ranges.add(<int> [index, end]);
          index = end;
        }
      } else if (index + 1 < length && currentChar == 0x5B && comment.codeUnitAt(index + 1) == 0x3A) {
        int end = StringUtilities.indexOf2(comment, index + 2, 0x3A, 0x5D);
        if (end < 0) {
          end = length;
        }
        ranges.add(<int> [index, end]);
        index = end + 1;
      } else {
        index = index + 1;
      }
    }
    return ranges;
  }

  /**
   * Return the end token associated with the given begin token, or `null` if either the given
   * token is not a begin token or it does not have an end token associated with it.
   *
   * @param beginToken the token that is expected to have an end token associated with it
   * @return the end token associated with the begin token
   */
  Token getEndToken(Token beginToken) {
    if (beginToken is BeginToken) {
      return beginToken.endToken;
    }
    return null;
  }

  /**
   * Return `true` if the current token is the first token of a return type that is followed
   * by an identifier, possibly followed by a list of type parameters, followed by a
   * left-parenthesis. This is used by parseTypeAlias to determine whether or not to parse a return
   * type.
   *
   * @return `true` if we can successfully parse the rest of a type alias if we first parse a
   *         return type.
   */
  bool hasReturnTypeInTypeAlias() {
    Token next = skipReturnType(_currentToken);
    if (next == null) {
      return false;
    }
    return tokenMatchesIdentifier(next);
  }

  /**
   * Inject the given token into the token stream immediately before the current token.
   *
   * @param token the token to be added to the token stream
   * @return the token that was just added to the token stream
   */
  Token injectToken(Token token) {
    Token previous = _currentToken.previous;
    token.setNext(_currentToken);
    previous.setNext(token);
    return token;
  }

  /**
   * Return `true` if the current token appears to be the beginning of a function declaration.
   *
   * @return `true` if the current token appears to be the beginning of a function declaration
   */
  bool isFunctionDeclaration() {
    if (matchesKeyword(Keyword.VOID)) {
      return true;
    }
    Token afterReturnType = skipTypeName(_currentToken);
    if (afterReturnType == null) {
      // There was no return type, but it is optional, so go back to where we started.
      afterReturnType = _currentToken;
    }
    Token afterIdentifier = skipSimpleIdentifier(afterReturnType);
    if (afterIdentifier == null) {
      // It's possible that we parsed the function name as if it were a type name, so see whether
      // it makes sense if we assume that there is no type.
      afterIdentifier = skipSimpleIdentifier(_currentToken);
    }
    if (afterIdentifier == null) {
      return false;
    }
    if (isFunctionExpression(afterIdentifier)) {
      return true;
    }
    // It's possible that we have found a getter. While this isn't valid at this point we test for
    // it in order to recover better.
    if (matchesKeyword(Keyword.GET)) {
      Token afterName = skipSimpleIdentifier(_currentToken.next);
      if (afterName == null) {
        return false;
      }
      return tokenMatches(afterName, TokenType.FUNCTION) || tokenMatches(afterName, TokenType.OPEN_CURLY_BRACKET);
    }
    return false;
  }

  /**
   * Return `true` if the given token appears to be the beginning of a function expression.
   *
   * @param startToken the token that might be the start of a function expression
   * @return `true` if the given token appears to be the beginning of a function expression
   */
  bool isFunctionExpression(Token startToken) {
    Token afterParameters = skipFormalParameterList(startToken);
    if (afterParameters == null) {
      return false;
    }
    return matchesAny(afterParameters, [TokenType.OPEN_CURLY_BRACKET, TokenType.FUNCTION]);
  }

  /**
   * Return `true` if the given character is a valid hexadecimal digit.
   *
   * @param character the character being tested
   * @return `true` if the character is a valid hexadecimal digit
   */
  bool isHexDigit(int character) => (0x30 <= character && character <= 0x39) || (0x41 <= character && character <= 0x46) || (0x61 <= character && character <= 0x66);

  /**
   * Return `true` if the current token is the first token in an initialized variable
   * declaration rather than an expression. This method assumes that we have already skipped past
   * any metadata that might be associated with the declaration.
   *
   * <pre>
   * initializedVariableDeclaration ::=
   *     declaredIdentifier ('=' expression)? (',' initializedIdentifier)*
   *
   * declaredIdentifier ::=
   *     metadata finalConstVarOrType identifier
   *
   * finalConstVarOrType ::=
   *     'final' type?
   *   | 'const' type?
   *   | 'var'
   *   | type
   *
   * type ::=
   *     qualified typeArguments?
   *
   * initializedIdentifier ::=
   *     identifier ('=' expression)?
   * </pre>
   *
   * @return `true` if the current token is the first token in an initialized variable
   *         declaration
   */
  bool isInitializedVariableDeclaration() {
    if (matchesKeyword(Keyword.FINAL) || matchesKeyword(Keyword.VAR)) {
      // An expression cannot start with a keyword other than 'const', 'rethrow', or 'throw'.
      return true;
    }
    if (matchesKeyword(Keyword.CONST)) {
      // Look to see whether we might be at the start of a list or map literal, otherwise this
      // should be the start of a variable declaration.
      return !matchesAny(peek(), [
          TokenType.LT,
          TokenType.OPEN_CURLY_BRACKET,
          TokenType.OPEN_SQUARE_BRACKET,
          TokenType.INDEX]);
    }
    // We know that we have an identifier, and need to see whether it might be a type name.
    Token token = skipTypeName(_currentToken);
    if (token == null) {
      // There was no type name, so this can't be a declaration.
      return false;
    }
    token = skipSimpleIdentifier(token);
    if (token == null) {
      return false;
    }
    TokenType type = token.type;
    return identical(type, TokenType.EQ) || identical(type, TokenType.COMMA) || identical(type, TokenType.SEMICOLON) || tokenMatchesKeyword(token, Keyword.IN);
  }

  /**
   * Given that we have just found bracketed text within a comment, look to see whether that text is
   * (a) followed by a parenthesized link address, (b) followed by a colon, or (c) followed by
   * optional whitespace and another square bracket.
   *
   * This method uses the syntax described by the <a
   * href="http://daringfireball.net/projects/markdown/syntax">markdown</a> project.
   *
   * @param comment the comment text in which the bracketed text was found
   * @param rightIndex the index of the right bracket
   * @return `true` if the bracketed text is followed by a link address
   */
  bool isLinkText(String comment, int rightIndex) {
    int length = comment.length;
    int index = rightIndex + 1;
    if (index >= length) {
      return false;
    }
    int nextChar = comment.codeUnitAt(index);
    if (nextChar == 0x28 || nextChar == 0x3A) {
      return true;
    }
    while (Character.isWhitespace(nextChar)) {
      index = index + 1;
      if (index >= length) {
        return false;
      }
      nextChar = comment.codeUnitAt(index);
    }
    return nextChar == 0x5B;
  }

  /**
   * Return `true` if the given token appears to be the beginning of an operator declaration.
   *
   * @param startToken the token that might be the start of an operator declaration
   * @return `true` if the given token appears to be the beginning of an operator declaration
   */
  bool isOperator(Token startToken) {
    // Accept any operator here, even if it is not user definable.
    if (!startToken.isOperator) {
      return false;
    }
    // Token "=" means that it is actually field initializer.
    if (identical(startToken.type, TokenType.EQ)) {
      return false;
    }
    // Consume all operator tokens.
    Token token = startToken.next;
    while (token.isOperator) {
      token = token.next;
    }
    // Formal parameter list is expect now.
    return tokenMatches(token, TokenType.OPEN_PAREN);
  }

  /**
   * Return `true` if the current token appears to be the beginning of a switch member.
   *
   * @return `true` if the current token appears to be the beginning of a switch member
   */
  bool isSwitchMember() {
    Token token = _currentToken;
    while (tokenMatches(token, TokenType.IDENTIFIER) && tokenMatches(token.next, TokenType.COLON)) {
      token = token.next.next;
    }
    if (identical(token.type, TokenType.KEYWORD)) {
      Keyword keyword = (token as KeywordToken).keyword;
      return identical(keyword, Keyword.CASE) || identical(keyword, Keyword.DEFAULT);
    }
    return false;
  }

  /**
   * Return `true` if the given token appears to be the first token of a type name that is
   * followed by a variable or field formal parameter.
   *
   * @param startToken the first token of the sequence being checked
   * @return `true` if there is a type name and variable starting at the given token
   */
  bool isTypedIdentifier(Token startToken) {
    Token token = skipReturnType(startToken);
    if (token == null) {
      return false;
    } else if (tokenMatchesIdentifier(token)) {
      return true;
    } else if (tokenMatchesKeyword(token, Keyword.THIS) && tokenMatches(token.next, TokenType.PERIOD) && tokenMatchesIdentifier(token.next.next)) {
      return true;
    }
    return false;
  }

  /**
   * Compare the given tokens to find the token that appears first in the source being parsed. That
   * is, return the left-most of all of the tokens. The arguments are allowed to be `null`.
   * Return the token with the smallest offset, or `null` if there are no arguments or if all
   * of the arguments are `null`.
   *
   * @param tokens the tokens being compared
   * @return the token with the smallest offset
   */
  Token lexicallyFirst(List<Token> tokens) {
    Token first = null;
    int firstOffset = 2147483647;
    for (Token token in tokens) {
      if (token != null) {
        int offset = token.offset;
        if (offset < firstOffset) {
          first = token;
          firstOffset = offset;
        }
      }
    }
    return first;
  }

  /**
   * Increments the error reporting lock level. If level is more than `0`, then
   * [reportError] wont report any error.
   */
  void lockErrorListener() {
    _errorListenerLock++;
  }

  /**
   * Return `true` if the current token has the given type. Note that this method, unlike
   * other variants, will modify the token stream if possible to match a wider range of tokens. In
   * particular, if we are attempting to match a '>' and the next token is either a '>>' or '>>>',
   * the token stream will be re-written and `true` will be returned.
   *
   * @param type the type of token that can optionally appear in the current location
   * @return `true` if the current token has the given type
   */
  bool matches(TokenType type) {
    TokenType currentType = _currentToken.type;
    if (currentType != type) {
      if (identical(type, TokenType.GT)) {
        if (identical(currentType, TokenType.GT_GT)) {
          int offset = _currentToken.offset;
          Token first = new Token(TokenType.GT, offset);
          Token second = new Token(TokenType.GT, offset + 1);
          second.setNext(_currentToken.next);
          first.setNext(second);
          _currentToken.previous.setNext(first);
          _currentToken = first;
          return true;
        } else if (identical(currentType, TokenType.GT_EQ)) {
          int offset = _currentToken.offset;
          Token first = new Token(TokenType.GT, offset);
          Token second = new Token(TokenType.EQ, offset + 1);
          second.setNext(_currentToken.next);
          first.setNext(second);
          _currentToken.previous.setNext(first);
          _currentToken = first;
          return true;
        } else if (identical(currentType, TokenType.GT_GT_EQ)) {
          int offset = _currentToken.offset;
          Token first = new Token(TokenType.GT, offset);
          Token second = new Token(TokenType.GT, offset + 1);
          Token third = new Token(TokenType.EQ, offset + 2);
          third.setNext(_currentToken.next);
          second.setNext(third);
          first.setNext(second);
          _currentToken.previous.setNext(first);
          _currentToken = first;
          return true;
        }
      }
      return false;
    }
    return true;
  }

  /**
   * Return `true` if the given token has any one of the given types.
   *
   * @param token the token being tested
   * @param types the types of token that are being tested for
   * @return `true` if the given token has any of the given types
   */
  bool matchesAny(Token token, List<TokenType> types) {
    TokenType actualType = token.type;
    for (TokenType type in types) {
      if (identical(actualType, type)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Return `true` if the current token is a valid identifier. Valid identifiers include
   * built-in identifiers (pseudo-keywords).
   *
   * @return `true` if the current token is a valid identifier
   */
  bool matchesIdentifier() => tokenMatchesIdentifier(_currentToken);

  /**
   * Return `true` if the current token matches the given keyword.
   *
   * @param keyword the keyword that can optionally appear in the current location
   * @return `true` if the current token matches the given keyword
   */
  bool matchesKeyword(Keyword keyword) => tokenMatchesKeyword(_currentToken, keyword);

  /**
   * Return `true` if the current token matches the given identifier.
   *
   * @param identifier the identifier that can optionally appear in the current location
   * @return `true` if the current token matches the given identifier
   */
  bool matchesString(String identifier) => identical(_currentToken.type, TokenType.IDENTIFIER) && _currentToken.lexeme == identifier;

  /**
   * If the current token has the given type, then advance to the next token and return `true`
   * . Otherwise, return `false` without advancing.
   *
   * @param type the type of token that can optionally appear in the current location
   * @return `true` if the current token has the given type
   */
  bool optional(TokenType type) {
    if (matches(type)) {
      advance();
      return true;
    }
    return false;
  }

  /**
   * Parse an additive expression.
   *
   * <pre>
   * additiveExpression ::=
   *     multiplicativeExpression (additiveOperator multiplicativeExpression)*
   *   | 'super' (additiveOperator multiplicativeExpression)+
   * </pre>
   *
   * @return the additive expression that was parsed
   */
  Expression parseAdditiveExpression() {
    Expression expression;
    if (matchesKeyword(Keyword.SUPER) && _currentToken.next.type.isAdditiveOperator) {
      expression = new SuperExpression(andAdvance);
    } else {
      expression = parseMultiplicativeExpression();
    }
    while (_currentToken.type.isAdditiveOperator) {
      Token operator = andAdvance;
      expression = new BinaryExpression(expression, operator, parseMultiplicativeExpression());
    }
    return expression;
  }

  /**
   * Parse an argument definition test.
   *
   * <pre>
   * argumentDefinitionTest ::=
   *     '?' identifier
   * </pre>
   *
   * @return the argument definition test that was parsed
   */
  ArgumentDefinitionTest parseArgumentDefinitionTest() {
    Token question = expect(TokenType.QUESTION);
    SimpleIdentifier identifier = parseSimpleIdentifier();
    reportErrorForToken(ParserErrorCode.DEPRECATED_ARGUMENT_DEFINITION_TEST, question, []);
    return new ArgumentDefinitionTest(question, identifier);
  }

  /**
   * Parse an assert statement.
   *
   * <pre>
   * assertStatement ::=
   *     'assert' '(' conditionalExpression ')' ';'
   * </pre>
   *
   * @return the assert statement
   */
  AssertStatement parseAssertStatement() {
    Token keyword = expectKeyword(Keyword.ASSERT);
    Token leftParen = expect(TokenType.OPEN_PAREN);
    Expression expression = parseExpression2();
    if (expression is AssignmentExpression) {
      reportErrorForNode(ParserErrorCode.ASSERT_DOES_NOT_TAKE_ASSIGNMENT, expression, []);
    } else if (expression is CascadeExpression) {
      reportErrorForNode(ParserErrorCode.ASSERT_DOES_NOT_TAKE_CASCADE, expression, []);
    } else if (expression is ThrowExpression) {
      reportErrorForNode(ParserErrorCode.ASSERT_DOES_NOT_TAKE_THROW, expression, []);
    } else if (expression is RethrowExpression) {
      reportErrorForNode(ParserErrorCode.ASSERT_DOES_NOT_TAKE_RETHROW, expression, []);
    }
    Token rightParen = expect(TokenType.CLOSE_PAREN);
    Token semicolon = expect(TokenType.SEMICOLON);
    return new AssertStatement(keyword, leftParen, expression, rightParen, semicolon);
  }

  /**
   * Parse an assignable expression.
   *
   * <pre>
   * assignableExpression ::=
   *     primary (arguments* assignableSelector)+
   *   | 'super' assignableSelector
   *   | identifier
   * </pre>
   *
   * @param primaryAllowed `true` if the expression is allowed to be a primary without any
   *          assignable selector
   * @return the assignable expression that was parsed
   */
  Expression parseAssignableExpression(bool primaryAllowed) {
    if (matchesKeyword(Keyword.SUPER)) {
      return parseAssignableSelector(new SuperExpression(andAdvance), false);
    }
    //
    // A primary expression can start with an identifier. We resolve the ambiguity by determining
    // whether the primary consists of anything other than an identifier and/or is followed by an
    // assignableSelector.
    //
    Expression expression = parsePrimaryExpression();
    bool isOptional = primaryAllowed || expression is SimpleIdentifier;
    while (true) {
      while (matches(TokenType.OPEN_PAREN)) {
        ArgumentList argumentList = parseArgumentList();
        if (expression is SimpleIdentifier) {
          expression = new MethodInvocation(null, null, expression as SimpleIdentifier, argumentList);
        } else if (expression is PrefixedIdentifier) {
          PrefixedIdentifier identifier = expression as PrefixedIdentifier;
          expression = new MethodInvocation(identifier.prefix, identifier.period, identifier.identifier, argumentList);
        } else if (expression is PropertyAccess) {
          PropertyAccess access = expression as PropertyAccess;
          expression = new MethodInvocation(access.target, access.operator, access.propertyName, argumentList);
        } else {
          expression = new FunctionExpressionInvocation(expression, argumentList);
        }
        if (!primaryAllowed) {
          isOptional = false;
        }
      }
      Expression selectorExpression = parseAssignableSelector(expression, isOptional || (expression is PrefixedIdentifier));
      if (identical(selectorExpression, expression)) {
        if (!isOptional && (expression is PrefixedIdentifier)) {
          PrefixedIdentifier identifier = expression as PrefixedIdentifier;
          expression = new PropertyAccess(identifier.prefix, identifier.period, identifier.identifier);
        }
        return expression;
      }
      expression = selectorExpression;
      isOptional = true;
    }
  }

  /**
   * Parse an assignable selector.
   *
   * <pre>
   * assignableSelector ::=
   *     '[' expression ']'
   *   | '.' identifier
   * </pre>
   *
   * @param prefix the expression preceding the selector
   * @param optional `true` if the selector is optional
   * @return the assignable selector that was parsed
   */
  Expression parseAssignableSelector(Expression prefix, bool optional) {
    if (matches(TokenType.OPEN_SQUARE_BRACKET)) {
      Token leftBracket = andAdvance;
      Expression index = parseExpression2();
      Token rightBracket = expect(TokenType.CLOSE_SQUARE_BRACKET);
      return new IndexExpression.forTarget(prefix, leftBracket, index, rightBracket);
    } else if (matches(TokenType.PERIOD)) {
      Token period = andAdvance;
      return new PropertyAccess(prefix, period, parseSimpleIdentifier());
    } else {
      if (!optional) {
        // Report the missing selector.
        reportErrorForCurrentToken(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, []);
      }
      return prefix;
    }
  }

  /**
   * Parse a bitwise and expression.
   *
   * <pre>
   * bitwiseAndExpression ::=
   *     shiftExpression ('&' shiftExpression)*
   *   | 'super' ('&' shiftExpression)+
   * </pre>
   *
   * @return the bitwise and expression that was parsed
   */
  Expression parseBitwiseAndExpression() {
    Expression expression;
    if (matchesKeyword(Keyword.SUPER) && tokenMatches(peek(), TokenType.AMPERSAND)) {
      expression = new SuperExpression(andAdvance);
    } else {
      expression = parseShiftExpression();
    }
    while (matches(TokenType.AMPERSAND)) {
      Token operator = andAdvance;
      expression = new BinaryExpression(expression, operator, parseShiftExpression());
    }
    return expression;
  }

  /**
   * Parse a bitwise exclusive-or expression.
   *
   * <pre>
   * bitwiseXorExpression ::=
   *     bitwiseAndExpression ('^' bitwiseAndExpression)*
   *   | 'super' ('^' bitwiseAndExpression)+
   * </pre>
   *
   * @return the bitwise exclusive-or expression that was parsed
   */
  Expression parseBitwiseXorExpression() {
    Expression expression;
    if (matchesKeyword(Keyword.SUPER) && tokenMatches(peek(), TokenType.CARET)) {
      expression = new SuperExpression(andAdvance);
    } else {
      expression = parseBitwiseAndExpression();
    }
    while (matches(TokenType.CARET)) {
      Token operator = andAdvance;
      expression = new BinaryExpression(expression, operator, parseBitwiseAndExpression());
    }
    return expression;
  }

  /**
   * Parse a break statement.
   *
   * <pre>
   * breakStatement ::=
   *     'break' identifier? ';'
   * </pre>
   *
   * @return the break statement that was parsed
   */
  Statement parseBreakStatement() {
    Token breakKeyword = expectKeyword(Keyword.BREAK);
    SimpleIdentifier label = null;
    if (matchesIdentifier()) {
      label = parseSimpleIdentifier();
    }
    if (!_inLoop && !_inSwitch && label == null) {
      reportErrorForToken(ParserErrorCode.BREAK_OUTSIDE_OF_LOOP, breakKeyword, []);
    }
    Token semicolon = expect(TokenType.SEMICOLON);
    return new BreakStatement(breakKeyword, label, semicolon);
  }

  /**
   * Parse a cascade section.
   *
   * <pre>
   * cascadeSection ::=
   *     '..' (cascadeSelector arguments*) (assignableSelector arguments*)* cascadeAssignment?
   *
   * cascadeSelector ::=
   *     '[' expression ']'
   *   | identifier
   *
   * cascadeAssignment ::=
   *     assignmentOperator expressionWithoutCascade
   * </pre>
   *
   * @return the expression representing the cascaded method invocation
   */
  Expression parseCascadeSection() {
    Token period = expect(TokenType.PERIOD_PERIOD);
    Expression expression = null;
    SimpleIdentifier functionName = null;
    if (matchesIdentifier()) {
      functionName = parseSimpleIdentifier();
    } else if (identical(_currentToken.type, TokenType.OPEN_SQUARE_BRACKET)) {
      Token leftBracket = andAdvance;
      Expression index = parseExpression2();
      Token rightBracket = expect(TokenType.CLOSE_SQUARE_BRACKET);
      expression = new IndexExpression.forCascade(period, leftBracket, index, rightBracket);
      period = null;
    } else {
      reportErrorForToken(ParserErrorCode.MISSING_IDENTIFIER, _currentToken, [_currentToken.lexeme]);
      functionName = createSyntheticIdentifier();
    }
    if (identical(_currentToken.type, TokenType.OPEN_PAREN)) {
      while (identical(_currentToken.type, TokenType.OPEN_PAREN)) {
        if (functionName != null) {
          expression = new MethodInvocation(expression, period, functionName, parseArgumentList());
          period = null;
          functionName = null;
        } else if (expression == null) {
          // It should not be possible to get here.
          expression = new MethodInvocation(expression, period, createSyntheticIdentifier(), parseArgumentList());
        } else {
          expression = new FunctionExpressionInvocation(expression, parseArgumentList());
        }
      }
    } else if (functionName != null) {
      expression = new PropertyAccess(expression, period, functionName);
      period = null;
    }
    bool progress = true;
    while (progress) {
      progress = false;
      Expression selector = parseAssignableSelector(expression, true);
      if (selector != expression) {
        expression = selector;
        progress = true;
        while (identical(_currentToken.type, TokenType.OPEN_PAREN)) {
          if (expression is PropertyAccess) {
            PropertyAccess propertyAccess = expression as PropertyAccess;
            expression = new MethodInvocation(propertyAccess.target, propertyAccess.operator, propertyAccess.propertyName, parseArgumentList());
          } else {
            expression = new FunctionExpressionInvocation(expression, parseArgumentList());
          }
        }
      }
    }
    if (_currentToken.type.isAssignmentOperator) {
      Token operator = andAdvance;
      ensureAssignable(expression);
      expression = new AssignmentExpression(expression, operator, parseExpressionWithoutCascade());
    }
    return expression;
  }

  /**
   * Parse a class declaration.
   *
   * <pre>
   * classDeclaration ::=
   *     metadata 'abstract'? 'class' name typeParameterList? (extendsClause withClause?)? implementsClause? '{' classMembers '}' |
   *     metadata 'abstract'? 'class' mixinApplicationClass
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the member
   * @param abstractKeyword the token for the keyword 'abstract', or `null` if the keyword was
   *          not given
   * @return the class declaration that was parsed
   */
  CompilationUnitMember parseClassDeclaration(CommentAndMetadata commentAndMetadata, Token abstractKeyword) {
    Token keyword = expectKeyword(Keyword.CLASS);
    if (matchesIdentifier()) {
      Token next = peek();
      if (tokenMatches(next, TokenType.LT)) {
        next = skipTypeParameterList(next);
        if (next != null && tokenMatches(next, TokenType.EQ)) {
          return parseClassTypeAlias(commentAndMetadata, abstractKeyword, keyword);
        }
      } else if (tokenMatches(next, TokenType.EQ)) {
        return parseClassTypeAlias(commentAndMetadata, abstractKeyword, keyword);
      }
    }
    SimpleIdentifier name = parseSimpleIdentifier();
    String className = name.name;
    TypeParameterList typeParameters = null;
    if (matches(TokenType.LT)) {
      typeParameters = parseTypeParameterList();
    }
    //
    // Parse the clauses. The parser accepts clauses in any order, but will generate errors if they
    // are not in the order required by the specification.
    //
    ExtendsClause extendsClause = null;
    WithClause withClause = null;
    ImplementsClause implementsClause = null;
    bool foundClause = true;
    while (foundClause) {
      if (matchesKeyword(Keyword.EXTENDS)) {
        if (extendsClause == null) {
          extendsClause = parseExtendsClause();
          if (withClause != null) {
            reportErrorForToken(ParserErrorCode.WITH_BEFORE_EXTENDS, withClause.withKeyword, []);
          } else if (implementsClause != null) {
            reportErrorForToken(ParserErrorCode.IMPLEMENTS_BEFORE_EXTENDS, implementsClause.keyword, []);
          }
        } else {
          reportErrorForToken(ParserErrorCode.MULTIPLE_EXTENDS_CLAUSES, extendsClause.keyword, []);
          parseExtendsClause();
        }
      } else if (matchesKeyword(Keyword.WITH)) {
        if (withClause == null) {
          withClause = parseWithClause();
          if (implementsClause != null) {
            reportErrorForToken(ParserErrorCode.IMPLEMENTS_BEFORE_WITH, implementsClause.keyword, []);
          }
        } else {
          reportErrorForToken(ParserErrorCode.MULTIPLE_WITH_CLAUSES, withClause.withKeyword, []);
          parseWithClause();
        }
      } else if (matchesKeyword(Keyword.IMPLEMENTS)) {
        if (implementsClause == null) {
          implementsClause = parseImplementsClause();
        } else {
          reportErrorForToken(ParserErrorCode.MULTIPLE_IMPLEMENTS_CLAUSES, implementsClause.keyword, []);
          parseImplementsClause();
        }
      } else {
        foundClause = false;
      }
    }
    if (withClause != null && extendsClause == null) {
      reportErrorForToken(ParserErrorCode.WITH_WITHOUT_EXTENDS, withClause.withKeyword, []);
    }
    //
    // Look for and skip over the extra-lingual 'native' specification.
    //
    NativeClause nativeClause = null;
    if (matchesString(_NATIVE) && tokenMatches(peek(), TokenType.STRING)) {
      nativeClause = parseNativeClause();
    }
    //
    // Parse the body of the class.
    //
    Token leftBracket = null;
    List<ClassMember> members = null;
    Token rightBracket = null;
    if (matches(TokenType.OPEN_CURLY_BRACKET)) {
      leftBracket = expect(TokenType.OPEN_CURLY_BRACKET);
      members = parseClassMembers(className, getEndToken(leftBracket));
      rightBracket = expect(TokenType.CLOSE_CURLY_BRACKET);
    } else {
      leftBracket = createSyntheticToken(TokenType.OPEN_CURLY_BRACKET);
      rightBracket = createSyntheticToken(TokenType.CLOSE_CURLY_BRACKET);
      reportErrorForCurrentToken(ParserErrorCode.MISSING_CLASS_BODY, []);
    }
    ClassDeclaration classDeclaration = new ClassDeclaration(commentAndMetadata.comment, commentAndMetadata.metadata, abstractKeyword, keyword, name, typeParameters, extendsClause, withClause, implementsClause, leftBracket, members, rightBracket);
    classDeclaration.nativeClause = nativeClause;
    return classDeclaration;
  }

  /**
   * Parse a list of class members.
   *
   * <pre>
   * classMembers ::=
   *     (metadata memberDefinition)*
   * </pre>
   *
   * @param className the name of the class whose members are being parsed
   * @param closingBracket the closing bracket for the class, or `null` if the closing bracket
   *          is missing
   * @return the list of class members that were parsed
   */
  List<ClassMember> parseClassMembers(String className, Token closingBracket) {
    List<ClassMember> members = new List<ClassMember>();
    Token memberStart = _currentToken;
    while (!matches(TokenType.EOF) && !matches(TokenType.CLOSE_CURLY_BRACKET) && (closingBracket != null || (!matchesKeyword(Keyword.CLASS) && !matchesKeyword(Keyword.TYPEDEF)))) {
      if (matches(TokenType.SEMICOLON)) {
        reportErrorForToken(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken, [_currentToken.lexeme]);
        advance();
      } else {
        ClassMember member = parseClassMember(className);
        if (member != null) {
          members.add(member);
        }
      }
      if (identical(_currentToken, memberStart)) {
        reportErrorForToken(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken, [_currentToken.lexeme]);
        advance();
      }
      memberStart = _currentToken;
    }
    return members;
  }

  /**
   * Parse a class type alias.
   *
   * <pre>
   * classTypeAlias ::=
   *     identifier typeParameters? '=' 'abstract'? mixinApplication
   *
   * mixinApplication ::=
   *     type withClause implementsClause? ';'
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the member
   * @param abstractKeyword the token representing the 'abstract' keyword
   * @param classKeyword the token representing the 'class' keyword
   * @return the class type alias that was parsed
   */
  ClassTypeAlias parseClassTypeAlias(CommentAndMetadata commentAndMetadata, Token abstractKeyword, Token classKeyword) {
    SimpleIdentifier className = parseSimpleIdentifier();
    TypeParameterList typeParameters = null;
    if (matches(TokenType.LT)) {
      typeParameters = parseTypeParameterList();
    }
    Token equals = expect(TokenType.EQ);
    if (matchesKeyword(Keyword.ABSTRACT)) {
      abstractKeyword = andAdvance;
    }
    TypeName superclass = parseTypeName();
    WithClause withClause = null;
    if (matchesKeyword(Keyword.WITH)) {
      withClause = parseWithClause();
    }
    ImplementsClause implementsClause = null;
    if (matchesKeyword(Keyword.IMPLEMENTS)) {
      implementsClause = parseImplementsClause();
    }
    Token semicolon;
    if (matches(TokenType.SEMICOLON)) {
      semicolon = andAdvance;
    } else {
      if (matches(TokenType.OPEN_CURLY_BRACKET)) {
        reportErrorForCurrentToken(ParserErrorCode.EXPECTED_TOKEN, [TokenType.SEMICOLON.lexeme]);
        Token leftBracket = andAdvance;
        parseClassMembers(className.name, getEndToken(leftBracket));
        expect(TokenType.CLOSE_CURLY_BRACKET);
      } else {
        reportErrorForToken(ParserErrorCode.EXPECTED_TOKEN, _currentToken.previous, [TokenType.SEMICOLON.lexeme]);
      }
      semicolon = createSyntheticToken(TokenType.SEMICOLON);
    }
    return new ClassTypeAlias(commentAndMetadata.comment, commentAndMetadata.metadata, classKeyword, className, typeParameters, equals, abstractKeyword, superclass, withClause, implementsClause, semicolon);
  }

  /**
   * Parse a list of combinators in a directive.
   *
   * <pre>
   * combinator ::=
   *     'show' identifier (',' identifier)*
   *   | 'hide' identifier (',' identifier)*
   * </pre>
   *
   * @return the combinators that were parsed
   */
  List<Combinator> parseCombinators() {
    List<Combinator> combinators = new List<Combinator>();
    while (matchesString(_SHOW) || matchesString(_HIDE)) {
      Token keyword = expect(TokenType.IDENTIFIER);
      if (keyword.lexeme == _SHOW) {
        List<SimpleIdentifier> shownNames = parseIdentifierList();
        combinators.add(new ShowCombinator(keyword, shownNames));
      } else {
        List<SimpleIdentifier> hiddenNames = parseIdentifierList();
        combinators.add(new HideCombinator(keyword, hiddenNames));
      }
    }
    return combinators;
  }

  /**
   * Parse the documentation comment and metadata preceding a declaration. This method allows any
   * number of documentation comments to occur before, after or between the metadata, but only
   * returns the last (right-most) documentation comment that is found.
   *
   * <pre>
   * metadata ::=
   *     annotation*
   * </pre>
   *
   * @return the documentation comment and metadata that were parsed
   */
  CommentAndMetadata parseCommentAndMetadata() {
    Comment comment = parseDocumentationComment();
    List<Annotation> metadata = new List<Annotation>();
    while (matches(TokenType.AT)) {
      metadata.add(parseAnnotation());
      Comment optionalComment = parseDocumentationComment();
      if (optionalComment != null) {
        comment = optionalComment;
      }
    }
    return new CommentAndMetadata(comment, metadata);
  }

  /**
   * Parse a comment reference from the source between square brackets.
   *
   * <pre>
   * commentReference ::=
   *     'new'? prefixedIdentifier
   * </pre>
   *
   * @param referenceSource the source occurring between the square brackets within a documentation
   *          comment
   * @param sourceOffset the offset of the first character of the reference source
   * @return the comment reference that was parsed, or `null` if no reference could be found
   */
  CommentReference parseCommentReference(String referenceSource, int sourceOffset) {
    // TODO(brianwilkerson) The errors are not getting the right offset/length and are being duplicated.
    if (referenceSource.length == 0) {
      Token syntheticToken = new SyntheticStringToken(TokenType.IDENTIFIER, "", sourceOffset);
      return new CommentReference(null, new SimpleIdentifier(syntheticToken));
    }
    try {
      BooleanErrorListener listener = new BooleanErrorListener();
      Scanner scanner = new Scanner(null, new SubSequenceReader(referenceSource, sourceOffset), listener);
      scanner.setSourceStart(1, 1);
      Token firstToken = scanner.tokenize();
      if (listener.errorReported) {
        return null;
      }
      Token newKeyword = null;
      if (tokenMatchesKeyword(firstToken, Keyword.NEW)) {
        newKeyword = firstToken;
        firstToken = firstToken.next;
      }
      if (tokenMatchesIdentifier(firstToken)) {
        Token secondToken = firstToken.next;
        Token thirdToken = secondToken.next;
        Token nextToken;
        Identifier identifier;
        if (tokenMatches(secondToken, TokenType.PERIOD) && tokenMatchesIdentifier(thirdToken)) {
          identifier = new PrefixedIdentifier(new SimpleIdentifier(firstToken), secondToken, new SimpleIdentifier(thirdToken));
          nextToken = thirdToken.next;
        } else {
          identifier = new SimpleIdentifier(firstToken);
          nextToken = firstToken.next;
        }
        if (nextToken.type != TokenType.EOF) {
          return null;
        }
        return new CommentReference(newKeyword, identifier);
      } else if (tokenMatchesKeyword(firstToken, Keyword.THIS) || tokenMatchesKeyword(firstToken, Keyword.NULL) || tokenMatchesKeyword(firstToken, Keyword.TRUE) || tokenMatchesKeyword(firstToken, Keyword.FALSE)) {
        // TODO(brianwilkerson) If we want to support this we will need to extend the definition
        // of CommentReference to take an expression rather than an identifier. For now we just
        // ignore it to reduce the number of errors produced, but that's probably not a valid
        // long term approach.
        return null;
      }
    } on JavaException catch (exception) {
    }
    return null;
  }

  /**
   * Parse all of the comment references occurring in the given array of documentation comments.
   *
   * <pre>
   * commentReference ::=
   *     '[' 'new'? qualified ']' libraryReference?
   *
   * libraryReference ::=
   *      '(' stringLiteral ')'
   * </pre>
   *
   * @param tokens the comment tokens representing the documentation comments to be parsed
   * @return the comment references that were parsed
   */
  List<CommentReference> parseCommentReferences(List<Token> tokens) {
    List<CommentReference> references = new List<CommentReference>();
    for (Token token in tokens) {
      String comment = token.lexeme;
      int length = comment.length;
      List<List<int>> codeBlockRanges = getCodeBlockRanges(comment);
      int leftIndex = comment.indexOf('[');
      while (leftIndex >= 0 && leftIndex + 1 < length) {
        List<int> range = findRange(codeBlockRanges, leftIndex);
        if (range == null) {
          int nameOffset = token.offset + leftIndex + 1;
          int rightIndex = JavaString.indexOf(comment, ']', leftIndex);
          if (rightIndex >= 0) {
            int firstChar = comment.codeUnitAt(leftIndex + 1);
            if (firstChar != 0x27 && firstChar != 0x22) {
              if (isLinkText(comment, rightIndex)) {
              } else {
                CommentReference reference = parseCommentReference(comment.substring(leftIndex + 1, rightIndex), nameOffset);
                if (reference != null) {
                  references.add(reference);
                }
              }
            }
          } else {
            // terminating ']' is not typed yet
            int charAfterLeft = comment.codeUnitAt(leftIndex + 1);
            if (Character.isLetterOrDigit(charAfterLeft)) {
              int nameEnd = StringUtilities.indexOfFirstNotLetterDigit(comment, leftIndex + 1);
              String name = comment.substring(leftIndex + 1, nameEnd);
              Token nameToken = new StringToken(TokenType.IDENTIFIER, name, nameOffset);
              references.add(new CommentReference(null, new SimpleIdentifier(nameToken)));
            } else {
              Token nameToken = new SyntheticStringToken(TokenType.IDENTIFIER, "", nameOffset);
              references.add(new CommentReference(null, new SimpleIdentifier(nameToken)));
            }
            // next character
            rightIndex = leftIndex + 1;
          }
          leftIndex = JavaString.indexOf(comment, '[', rightIndex);
        } else {
          leftIndex = JavaString.indexOf(comment, '[', range[1] + 1);
        }
      }
    }
    return references;
  }

  /**
   * Parse a compilation unit member.
   *
   * <pre>
   * compilationUnitMember ::=
   *     classDefinition
   *   | functionTypeAlias
   *   | external functionSignature
   *   | external getterSignature
   *   | external setterSignature
   *   | functionSignature functionBody
   *   | returnType? getOrSet identifier formalParameterList functionBody
   *   | (final | const) type? staticFinalDeclarationList ';'
   *   | variableDeclaration ';'
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the member
   * @return the compilation unit member that was parsed, or `null` if what was parsed could
   *         not be represented as a compilation unit member
   */
  CompilationUnitMember parseCompilationUnitMember(CommentAndMetadata commentAndMetadata) {
    Modifiers modifiers = parseModifiers();
    if (matchesKeyword(Keyword.CLASS)) {
      return parseClassDeclaration(commentAndMetadata, validateModifiersForClass(modifiers));
    } else if (matchesKeyword(Keyword.TYPEDEF) && !tokenMatches(peek(), TokenType.PERIOD) && !tokenMatches(peek(), TokenType.LT) && !tokenMatches(peek(), TokenType.OPEN_PAREN)) {
      validateModifiersForTypedef(modifiers);
      return parseTypeAlias(commentAndMetadata);
    }
    if (matchesKeyword(Keyword.VOID)) {
      TypeName returnType = parseReturnType();
      if ((matchesKeyword(Keyword.GET) || matchesKeyword(Keyword.SET)) && tokenMatchesIdentifier(peek())) {
        validateModifiersForTopLevelFunction(modifiers);
        return parseFunctionDeclaration(commentAndMetadata, modifiers.externalKeyword, returnType);
      } else if (matchesKeyword(Keyword.OPERATOR) && isOperator(peek())) {
        reportErrorForToken(ParserErrorCode.TOP_LEVEL_OPERATOR, _currentToken, []);
        return convertToFunctionDeclaration(parseOperator(commentAndMetadata, modifiers.externalKeyword, returnType));
      } else if (matchesIdentifier() && matchesAny(peek(), [
          TokenType.OPEN_PAREN,
          TokenType.OPEN_CURLY_BRACKET,
          TokenType.FUNCTION])) {
        validateModifiersForTopLevelFunction(modifiers);
        return parseFunctionDeclaration(commentAndMetadata, modifiers.externalKeyword, returnType);
      } else {
        //
        // We have found an error of some kind. Try to recover.
        //
        if (matchesIdentifier()) {
          if (matchesAny(peek(), [TokenType.EQ, TokenType.COMMA, TokenType.SEMICOLON])) {
            //
            // We appear to have a variable declaration with a type of "void".
            //
            reportErrorForNode(ParserErrorCode.VOID_VARIABLE, returnType, []);
            return new TopLevelVariableDeclaration(commentAndMetadata.comment, commentAndMetadata.metadata, parseVariableDeclarationListAfterType(null, validateModifiersForTopLevelVariable(modifiers), null), expect(TokenType.SEMICOLON));
          }
        }
        reportErrorForToken(ParserErrorCode.EXPECTED_EXECUTABLE, _currentToken, []);
        return null;
      }
    } else if ((matchesKeyword(Keyword.GET) || matchesKeyword(Keyword.SET)) && tokenMatchesIdentifier(peek())) {
      validateModifiersForTopLevelFunction(modifiers);
      return parseFunctionDeclaration(commentAndMetadata, modifiers.externalKeyword, null);
    } else if (matchesKeyword(Keyword.OPERATOR) && isOperator(peek())) {
      reportErrorForToken(ParserErrorCode.TOP_LEVEL_OPERATOR, _currentToken, []);
      return convertToFunctionDeclaration(parseOperator(commentAndMetadata, modifiers.externalKeyword, null));
    } else if (!matchesIdentifier()) {
      reportErrorForToken(ParserErrorCode.EXPECTED_EXECUTABLE, _currentToken, []);
      return null;
    } else if (tokenMatches(peek(), TokenType.OPEN_PAREN)) {
      validateModifiersForTopLevelFunction(modifiers);
      return parseFunctionDeclaration(commentAndMetadata, modifiers.externalKeyword, null);
    } else if (matchesAny(peek(), [TokenType.EQ, TokenType.COMMA, TokenType.SEMICOLON])) {
      if (modifiers.constKeyword == null && modifiers.finalKeyword == null && modifiers.varKeyword == null) {
        reportErrorForCurrentToken(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, []);
      }
      return new TopLevelVariableDeclaration(commentAndMetadata.comment, commentAndMetadata.metadata, parseVariableDeclarationListAfterType(null, validateModifiersForTopLevelVariable(modifiers), null), expect(TokenType.SEMICOLON));
    }
    TypeName returnType = parseReturnType();
    if ((matchesKeyword(Keyword.GET) || matchesKeyword(Keyword.SET)) && tokenMatchesIdentifier(peek())) {
      validateModifiersForTopLevelFunction(modifiers);
      return parseFunctionDeclaration(commentAndMetadata, modifiers.externalKeyword, returnType);
    } else if (matchesKeyword(Keyword.OPERATOR) && isOperator(peek())) {
      reportErrorForToken(ParserErrorCode.TOP_LEVEL_OPERATOR, _currentToken, []);
      return convertToFunctionDeclaration(parseOperator(commentAndMetadata, modifiers.externalKeyword, returnType));
    } else if (matches(TokenType.AT)) {
      return new TopLevelVariableDeclaration(commentAndMetadata.comment, commentAndMetadata.metadata, parseVariableDeclarationListAfterType(null, validateModifiersForTopLevelVariable(modifiers), returnType), expect(TokenType.SEMICOLON));
    } else if (!matchesIdentifier()) {
      // TODO(brianwilkerson) Generalize this error. We could also be parsing a top-level variable at this point.
      reportErrorForToken(ParserErrorCode.EXPECTED_EXECUTABLE, _currentToken, []);
      Token semicolon;
      if (matches(TokenType.SEMICOLON)) {
        semicolon = andAdvance;
      } else {
        semicolon = createSyntheticToken(TokenType.SEMICOLON);
      }
      List<VariableDeclaration> variables = new List<VariableDeclaration>();
      variables.add(new VariableDeclaration(null, null, createSyntheticIdentifier(), null, null));
      return new TopLevelVariableDeclaration(commentAndMetadata.comment, commentAndMetadata.metadata, new VariableDeclarationList(null, null, null, returnType, variables), semicolon);
    }
    if (matchesAny(peek(), [
        TokenType.OPEN_PAREN,
        TokenType.FUNCTION,
        TokenType.OPEN_CURLY_BRACKET])) {
      validateModifiersForTopLevelFunction(modifiers);
      return parseFunctionDeclaration(commentAndMetadata, modifiers.externalKeyword, returnType);
    }
    return new TopLevelVariableDeclaration(commentAndMetadata.comment, commentAndMetadata.metadata, parseVariableDeclarationListAfterType(null, validateModifiersForTopLevelVariable(modifiers), returnType), expect(TokenType.SEMICOLON));
  }

  /**
   * Parse a const expression.
   *
   * <pre>
   * constExpression ::=
   *     instanceCreationExpression
   *   | listLiteral
   *   | mapLiteral
   * </pre>
   *
   * @return the const expression that was parsed
   */
  Expression parseConstExpression() {
    Token keyword = expectKeyword(Keyword.CONST);
    if (matches(TokenType.OPEN_SQUARE_BRACKET) || matches(TokenType.INDEX)) {
      return parseListLiteral(keyword, null);
    } else if (matches(TokenType.OPEN_CURLY_BRACKET)) {
      return parseMapLiteral(keyword, null);
    } else if (matches(TokenType.LT)) {
      return parseListOrMapLiteral(keyword);
    }
    return parseInstanceCreationExpression(keyword);
  }

  ConstructorDeclaration parseConstructor(CommentAndMetadata commentAndMetadata, Token externalKeyword, Token constKeyword, Token factoryKeyword, SimpleIdentifier returnType, Token period, SimpleIdentifier name, FormalParameterList parameters) {
    bool bodyAllowed = externalKeyword == null;
    Token separator = null;
    List<ConstructorInitializer> initializers = null;
    if (matches(TokenType.COLON)) {
      separator = andAdvance;
      initializers = new List<ConstructorInitializer>();
      do {
        if (matchesKeyword(Keyword.THIS)) {
          if (tokenMatches(peek(), TokenType.OPEN_PAREN)) {
            bodyAllowed = false;
            initializers.add(parseRedirectingConstructorInvocation());
          } else if (tokenMatches(peek(), TokenType.PERIOD) && tokenMatches(peek2(3), TokenType.OPEN_PAREN)) {
            bodyAllowed = false;
            initializers.add(parseRedirectingConstructorInvocation());
          } else {
            initializers.add(parseConstructorFieldInitializer());
          }
        } else if (matchesKeyword(Keyword.SUPER)) {
          initializers.add(parseSuperConstructorInvocation());
        } else {
          initializers.add(parseConstructorFieldInitializer());
        }
      } while (optional(TokenType.COMMA));
    }
    ConstructorName redirectedConstructor = null;
    FunctionBody body;
    if (matches(TokenType.EQ)) {
      separator = andAdvance;
      redirectedConstructor = parseConstructorName();
      body = new EmptyFunctionBody(expect(TokenType.SEMICOLON));
      if (factoryKeyword == null) {
        reportErrorForNode(ParserErrorCode.REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR, redirectedConstructor, []);
      }
    } else {
      body = parseFunctionBody(true, ParserErrorCode.MISSING_FUNCTION_BODY, false);
      if (constKeyword != null && factoryKeyword != null && externalKeyword == null) {
        reportErrorForToken(ParserErrorCode.CONST_FACTORY, factoryKeyword, []);
      } else if (body is EmptyFunctionBody) {
        if (factoryKeyword != null && externalKeyword == null) {
          reportErrorForToken(ParserErrorCode.FACTORY_WITHOUT_BODY, factoryKeyword, []);
        }
      } else {
        if (constKeyword != null) {
          reportErrorForNode(ParserErrorCode.CONST_CONSTRUCTOR_WITH_BODY, body, []);
        } else if (!bodyAllowed) {
          reportErrorForNode(ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_BODY, body, []);
        }
      }
    }
    return new ConstructorDeclaration(commentAndMetadata.comment, commentAndMetadata.metadata, externalKeyword, constKeyword, factoryKeyword, returnType, period, name, parameters, separator, initializers, redirectedConstructor, body);
  }

  /**
   * Parse a field initializer within a constructor.
   *
   * <pre>
   * fieldInitializer:
   *     ('this' '.')? identifier '=' conditionalExpression cascadeSection*
   * </pre>
   *
   * @return the field initializer that was parsed
   */
  ConstructorFieldInitializer parseConstructorFieldInitializer() {
    Token keyword = null;
    Token period = null;
    if (matchesKeyword(Keyword.THIS)) {
      keyword = andAdvance;
      period = expect(TokenType.PERIOD);
    }
    SimpleIdentifier fieldName = parseSimpleIdentifier();
    Token equals = expect(TokenType.EQ);
    Expression expression = parseConditionalExpression();
    TokenType tokenType = _currentToken.type;
    if (identical(tokenType, TokenType.PERIOD_PERIOD)) {
      List<Expression> cascadeSections = new List<Expression>();
      while (identical(tokenType, TokenType.PERIOD_PERIOD)) {
        Expression section = parseCascadeSection();
        if (section != null) {
          cascadeSections.add(section);
        }
        tokenType = _currentToken.type;
      }
      expression = new CascadeExpression(expression, cascadeSections);
    }
    return new ConstructorFieldInitializer(keyword, period, fieldName, equals, expression);
  }

  /**
   * Parse a continue statement.
   *
   * <pre>
   * continueStatement ::=
   *     'continue' identifier? ';'
   * </pre>
   *
   * @return the continue statement that was parsed
   */
  Statement parseContinueStatement() {
    Token continueKeyword = expectKeyword(Keyword.CONTINUE);
    if (!_inLoop && !_inSwitch) {
      reportErrorForToken(ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP, continueKeyword, []);
    }
    SimpleIdentifier label = null;
    if (matchesIdentifier()) {
      label = parseSimpleIdentifier();
    }
    if (_inSwitch && !_inLoop && label == null) {
      reportErrorForToken(ParserErrorCode.CONTINUE_WITHOUT_LABEL_IN_CASE, continueKeyword, []);
    }
    Token semicolon = expect(TokenType.SEMICOLON);
    return new ContinueStatement(continueKeyword, label, semicolon);
  }

  /**
   * Parse a directive.
   *
   * <pre>
   * directive ::=
   *     exportDirective
   *   | libraryDirective
   *   | importDirective
   *   | partDirective
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the directive
   * @return the directive that was parsed
   */
  Directive parseDirective(CommentAndMetadata commentAndMetadata) {
    if (matchesKeyword(Keyword.IMPORT)) {
      return parseImportDirective(commentAndMetadata);
    } else if (matchesKeyword(Keyword.EXPORT)) {
      return parseExportDirective(commentAndMetadata);
    } else if (matchesKeyword(Keyword.LIBRARY)) {
      return parseLibraryDirective(commentAndMetadata);
    } else if (matchesKeyword(Keyword.PART)) {
      return parsePartDirective(commentAndMetadata);
    } else {
      // Internal error: this method should not have been invoked if the current token was something
      // other than one of the above.
      throw new IllegalStateException("parseDirective invoked in an invalid state; currentToken = ${_currentToken}");
    }
  }

  /**
   * Parse a documentation comment.
   *
   * <pre>
   * documentationComment ::=
   *     multiLineComment?
   *   | singleLineComment*
   * </pre>
   *
   * @return the documentation comment that was parsed, or `null` if there was no comment
   */
  Comment parseDocumentationComment() {
    List<Token> commentTokens = new List<Token>();
    Token commentToken = _currentToken.precedingComments;
    while (commentToken != null) {
      if (identical(commentToken.type, TokenType.SINGLE_LINE_COMMENT)) {
        if (StringUtilities.startsWith3(commentToken.lexeme, 0, 0x2F, 0x2F, 0x2F)) {
          if (commentTokens.length == 1 && StringUtilities.startsWith3(commentTokens[0].lexeme, 0, 0x2F, 0x2A, 0x2A)) {
            commentTokens.clear();
          }
          commentTokens.add(commentToken);
        }
      } else {
        if (StringUtilities.startsWith3(commentToken.lexeme, 0, 0x2F, 0x2A, 0x2A)) {
          commentTokens.clear();
          commentTokens.add(commentToken);
        }
      }
      commentToken = commentToken.next;
    }
    if (commentTokens.isEmpty) {
      return null;
    }
    List<Token> tokens = new List.from(commentTokens);
    List<CommentReference> references = parseCommentReferences(tokens);
    return Comment.createDocumentationComment2(tokens, references);
  }

  /**
   * Parse a do statement.
   *
   * <pre>
   * doStatement ::=
   *     'do' statement 'while' '(' expression ')' ';'
   * </pre>
   *
   * @return the do statement that was parsed
   */
  Statement parseDoStatement() {
    bool wasInLoop = _inLoop;
    _inLoop = true;
    try {
      Token doKeyword = expectKeyword(Keyword.DO);
      Statement body = parseStatement2();
      Token whileKeyword = expectKeyword(Keyword.WHILE);
      Token leftParenthesis = expect(TokenType.OPEN_PAREN);
      Expression condition = parseExpression2();
      Token rightParenthesis = expect(TokenType.CLOSE_PAREN);
      Token semicolon = expect(TokenType.SEMICOLON);
      return new DoStatement(doKeyword, body, whileKeyword, leftParenthesis, condition, rightParenthesis, semicolon);
    } finally {
      _inLoop = wasInLoop;
    }
  }

  /**
   * Parse an empty statement.
   *
   * <pre>
   * emptyStatement ::=
   *     ';'
   * </pre>
   *
   * @return the empty statement that was parsed
   */
  Statement parseEmptyStatement() => new EmptyStatement(andAdvance);

  /**
   * Parse an equality expression.
   *
   * <pre>
   * equalityExpression ::=
   *     relationalExpression (equalityOperator relationalExpression)?
   *   | 'super' equalityOperator relationalExpression
   * </pre>
   *
   * @return the equality expression that was parsed
   */
  Expression parseEqualityExpression() {
    Expression expression;
    if (matchesKeyword(Keyword.SUPER) && _currentToken.next.type.isEqualityOperator) {
      expression = new SuperExpression(andAdvance);
    } else {
      expression = parseRelationalExpression();
    }
    bool leftEqualityExpression = false;
    while (_currentToken.type.isEqualityOperator) {
      Token operator = andAdvance;
      if (leftEqualityExpression) {
        reportErrorForNode(ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND, expression, []);
      }
      expression = new BinaryExpression(expression, operator, parseRelationalExpression());
      leftEqualityExpression = true;
    }
    return expression;
  }

  /**
   * Parse an export directive.
   *
   * <pre>
   * exportDirective ::=
   *     metadata 'export' stringLiteral combinator*';'
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the directive
   * @return the export directive that was parsed
   */
  ExportDirective parseExportDirective(CommentAndMetadata commentAndMetadata) {
    Token exportKeyword = expectKeyword(Keyword.EXPORT);
    StringLiteral libraryUri = parseStringLiteral();
    List<Combinator> combinators = parseCombinators();
    Token semicolon = expectSemicolon();
    return new ExportDirective(commentAndMetadata.comment, commentAndMetadata.metadata, exportKeyword, libraryUri, combinators, semicolon);
  }

  /**
   * Parse a list of expressions.
   *
   * <pre>
   * expressionList ::=
   *     expression (',' expression)*
   * </pre>
   *
   * @return the expression that was parsed
   */
  List<Expression> parseExpressionList() {
    List<Expression> expressions = new List<Expression>();
    expressions.add(parseExpression2());
    while (optional(TokenType.COMMA)) {
      expressions.add(parseExpression2());
    }
    return expressions;
  }

  /**
   * Parse the 'final', 'const', 'var' or type preceding a variable declaration.
   *
   * <pre>
   * finalConstVarOrType ::=
   *   | 'final' type?
   *   | 'const' type?
   *   | 'var'
   *   | type
   * </pre>
   *
   * @param optional `true` if the keyword and type are optional
   * @return the 'final', 'const', 'var' or type that was parsed
   */
  FinalConstVarOrType parseFinalConstVarOrType(bool optional) {
    Token keyword = null;
    TypeName type = null;
    if (matchesKeyword(Keyword.FINAL) || matchesKeyword(Keyword.CONST)) {
      keyword = andAdvance;
      if (isTypedIdentifier(_currentToken)) {
        type = parseTypeName();
      }
    } else if (matchesKeyword(Keyword.VAR)) {
      keyword = andAdvance;
    } else {
      if (isTypedIdentifier(_currentToken)) {
        type = parseReturnType();
      } else if (!optional) {
        reportErrorForCurrentToken(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, []);
      }
    }
    return new FinalConstVarOrType(keyword, type);
  }

  /**
   * Parse a formal parameter. At most one of `isOptional` and `isNamed` can be
   * `true`.
   *
   * <pre>
   * defaultFormalParameter ::=
   *     normalFormalParameter ('=' expression)?
   *
   * defaultNamedParameter ::=
   *     normalFormalParameter (':' expression)?
   * </pre>
   *
   * @param kind the kind of parameter being expected based on the presence or absence of group
   *          delimiters
   * @return the formal parameter that was parsed
   */
  FormalParameter parseFormalParameter(ParameterKind kind) {
    NormalFormalParameter parameter = parseNormalFormalParameter();
    if (matches(TokenType.EQ)) {
      Token seperator = andAdvance;
      Expression defaultValue = parseExpression2();
      if (identical(kind, ParameterKind.NAMED)) {
        reportErrorForToken(ParserErrorCode.WRONG_SEPARATOR_FOR_NAMED_PARAMETER, seperator, []);
      } else if (identical(kind, ParameterKind.REQUIRED)) {
        reportErrorForNode(ParserErrorCode.POSITIONAL_PARAMETER_OUTSIDE_GROUP, parameter, []);
      }
      return new DefaultFormalParameter(parameter, kind, seperator, defaultValue);
    } else if (matches(TokenType.COLON)) {
      Token seperator = andAdvance;
      Expression defaultValue = parseExpression2();
      if (identical(kind, ParameterKind.POSITIONAL)) {
        reportErrorForToken(ParserErrorCode.WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER, seperator, []);
      } else if (identical(kind, ParameterKind.REQUIRED)) {
        reportErrorForNode(ParserErrorCode.NAMED_PARAMETER_OUTSIDE_GROUP, parameter, []);
      }
      return new DefaultFormalParameter(parameter, kind, seperator, defaultValue);
    } else if (kind != ParameterKind.REQUIRED) {
      return new DefaultFormalParameter(parameter, kind, null, null);
    }
    return parameter;
  }

  /**
   * Parse a for statement.
   *
   * <pre>
   * forStatement ::=
   *     'for' '(' forLoopParts ')' statement
   *
   * forLoopParts ::=
   *     forInitializerStatement expression? ';' expressionList?
   *   | declaredIdentifier 'in' expression
   *   | identifier 'in' expression
   *
   * forInitializerStatement ::=
   *     localVariableDeclaration ';'
   *   | expression? ';'
   * </pre>
   *
   * @return the for statement that was parsed
   */
  Statement parseForStatement() {
    bool wasInLoop = _inLoop;
    _inLoop = true;
    try {
      Token forKeyword = expectKeyword(Keyword.FOR);
      Token leftParenthesis = expect(TokenType.OPEN_PAREN);
      VariableDeclarationList variableList = null;
      Expression initialization = null;
      if (!matches(TokenType.SEMICOLON)) {
        CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
        if (matchesIdentifier() && tokenMatchesKeyword(peek(), Keyword.IN)) {
          List<VariableDeclaration> variables = new List<VariableDeclaration>();
          SimpleIdentifier variableName = parseSimpleIdentifier();
          variables.add(new VariableDeclaration(null, null, variableName, null, null));
          variableList = new VariableDeclarationList(commentAndMetadata.comment, commentAndMetadata.metadata, null, null, variables);
        } else if (isInitializedVariableDeclaration()) {
          variableList = parseVariableDeclarationListAfterMetadata(commentAndMetadata);
        } else {
          initialization = parseExpression2();
        }
        if (matchesKeyword(Keyword.IN)) {
          DeclaredIdentifier loopVariable = null;
          SimpleIdentifier identifier = null;
          if (variableList == null) {
            // We found: <expression> 'in'
            reportErrorForCurrentToken(ParserErrorCode.MISSING_VARIABLE_IN_FOR_EACH, []);
          } else {
            NodeList<VariableDeclaration> variables = variableList.variables;
            if (variables.length > 1) {
              reportErrorForCurrentToken(ParserErrorCode.MULTIPLE_VARIABLES_IN_FOR_EACH, [variables.length.toString()]);
            }
            VariableDeclaration variable = variables[0];
            if (variable.initializer != null) {
              reportErrorForCurrentToken(ParserErrorCode.INITIALIZED_VARIABLE_IN_FOR_EACH, []);
            }
            Token keyword = variableList.keyword;
            TypeName type = variableList.type;
            if (keyword != null || type != null) {
              loopVariable = new DeclaredIdentifier(commentAndMetadata.comment, commentAndMetadata.metadata, keyword, type, variable.name);
            } else {
              if (!commentAndMetadata.metadata.isEmpty) {
              }
              identifier = variable.name;
            }
          }
          Token inKeyword = expectKeyword(Keyword.IN);
          Expression iterator = parseExpression2();
          Token rightParenthesis = expect(TokenType.CLOSE_PAREN);
          Statement body = parseStatement2();
          if (loopVariable == null) {
            return new ForEachStatement.con2(forKeyword, leftParenthesis, identifier, inKeyword, iterator, rightParenthesis, body);
          }
          return new ForEachStatement.con1(forKeyword, leftParenthesis, loopVariable, inKeyword, iterator, rightParenthesis, body);
        }
      }
      Token leftSeparator = expect(TokenType.SEMICOLON);
      Expression condition = null;
      if (!matches(TokenType.SEMICOLON)) {
        condition = parseExpression2();
      }
      Token rightSeparator = expect(TokenType.SEMICOLON);
      List<Expression> updaters = null;
      if (!matches(TokenType.CLOSE_PAREN)) {
        updaters = parseExpressionList();
      }
      Token rightParenthesis = expect(TokenType.CLOSE_PAREN);
      Statement body = parseStatement2();
      return new ForStatement(forKeyword, leftParenthesis, variableList, initialization, leftSeparator, condition, rightSeparator, updaters, rightParenthesis, body);
    } finally {
      _inLoop = wasInLoop;
    }
  }

  /**
   * Parse a function body.
   *
   * <pre>
   * functionBody ::=
   *     '=>' expression ';'
   *   | block
   *
   * functionExpressionBody ::=
   *     '=>' expression
   *   | block
   * </pre>
   *
   * @param mayBeEmpty `true` if the function body is allowed to be empty
   * @param emptyErrorCode the error code to report if function body expected, but not found
   * @param inExpression `true` if the function body is being parsed as part of an expression
   *          and therefore does not have a terminating semicolon
   * @return the function body that was parsed
   */
  FunctionBody parseFunctionBody(bool mayBeEmpty, ParserErrorCode emptyErrorCode, bool inExpression) {
    bool wasInLoop = _inLoop;
    bool wasInSwitch = _inSwitch;
    _inLoop = false;
    _inSwitch = false;
    try {
      if (matches(TokenType.SEMICOLON)) {
        if (!mayBeEmpty) {
          reportErrorForCurrentToken(emptyErrorCode, []);
        }
        return new EmptyFunctionBody(andAdvance);
      } else if (matches(TokenType.FUNCTION)) {
        Token functionDefinition = andAdvance;
        Expression expression = parseExpression2();
        Token semicolon = null;
        if (!inExpression) {
          semicolon = expect(TokenType.SEMICOLON);
        }
        if (!_parseFunctionBodies) {
          return new EmptyFunctionBody(createSyntheticToken(TokenType.SEMICOLON));
        }
        return new ExpressionFunctionBody(functionDefinition, expression, semicolon);
      } else if (matches(TokenType.OPEN_CURLY_BRACKET)) {
        if (!_parseFunctionBodies) {
          skipBlock();
          return new EmptyFunctionBody(createSyntheticToken(TokenType.SEMICOLON));
        }
        return new BlockFunctionBody(parseBlock());
      } else if (matchesString(_NATIVE)) {
        Token nativeToken = andAdvance;
        StringLiteral stringLiteral = null;
        if (matches(TokenType.STRING)) {
          stringLiteral = parseStringLiteral();
        }
        return new NativeFunctionBody(nativeToken, stringLiteral, expect(TokenType.SEMICOLON));
      } else {
        // Invalid function body
        reportErrorForCurrentToken(emptyErrorCode, []);
        return new EmptyFunctionBody(createSyntheticToken(TokenType.SEMICOLON));
      }
    } finally {
      _inLoop = wasInLoop;
      _inSwitch = wasInSwitch;
    }
  }

  /**
   * Parse a function declaration.
   *
   * <pre>
   * functionDeclaration ::=
   *     functionSignature functionBody
   *   | returnType? getOrSet identifier formalParameterList functionBody
   * </pre>
   *
   * @param commentAndMetadata the documentation comment and metadata to be associated with the
   *          declaration
   * @param externalKeyword the 'external' keyword, or `null` if the function is not external
   * @param returnType the return type, or `null` if there is no return type
   * @param isStatement `true` if the function declaration is being parsed as a statement
   * @return the function declaration that was parsed
   */
  FunctionDeclaration parseFunctionDeclaration(CommentAndMetadata commentAndMetadata, Token externalKeyword, TypeName returnType) {
    Token keyword = null;
    bool isGetter = false;
    if (matchesKeyword(Keyword.GET) && !tokenMatches(peek(), TokenType.OPEN_PAREN)) {
      keyword = andAdvance;
      isGetter = true;
    } else if (matchesKeyword(Keyword.SET) && !tokenMatches(peek(), TokenType.OPEN_PAREN)) {
      keyword = andAdvance;
    }
    SimpleIdentifier name = parseSimpleIdentifier();
    FormalParameterList parameters = null;
    if (!isGetter) {
      if (matches(TokenType.OPEN_PAREN)) {
        parameters = parseFormalParameterList();
        validateFormalParameterList(parameters);
      } else {
        reportErrorForCurrentToken(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, []);
      }
    } else if (matches(TokenType.OPEN_PAREN)) {
      reportErrorForCurrentToken(ParserErrorCode.GETTER_WITH_PARAMETERS, []);
      parseFormalParameterList();
    }
    FunctionBody body;
    if (externalKeyword == null) {
      body = parseFunctionBody(false, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    } else {
      body = new EmptyFunctionBody(expect(TokenType.SEMICOLON));
    }
    //    if (!isStatement && matches(TokenType.SEMICOLON)) {
    //      // TODO(brianwilkerson) Improve this error message.
    //      reportError(ParserErrorCode.UNEXPECTED_TOKEN, currentToken.getLexeme());
    //      advance();
    //    }
    return new FunctionDeclaration(commentAndMetadata.comment, commentAndMetadata.metadata, externalKeyword, returnType, keyword, name, new FunctionExpression(parameters, body));
  }

  /**
   * Parse a function declaration statement.
   *
   * <pre>
   * functionDeclarationStatement ::=
   *     functionSignature functionBody
   * </pre>
   *
   * @return the function declaration statement that was parsed
   */
  Statement parseFunctionDeclarationStatement() {
    Modifiers modifiers = parseModifiers();
    validateModifiersForFunctionDeclarationStatement(modifiers);
    return parseFunctionDeclarationStatementAfterReturnType(parseCommentAndMetadata(), parseOptionalReturnType());
  }

  /**
   * Parse a function declaration statement.
   *
   * <pre>
   * functionDeclarationStatement ::=
   *     functionSignature functionBody
   * </pre>
   *
   * @param commentAndMetadata the documentation comment and metadata to be associated with the
   *          declaration
   * @param returnType the return type, or `null` if there is no return type
   * @return the function declaration statement that was parsed
   */
  Statement parseFunctionDeclarationStatementAfterReturnType(CommentAndMetadata commentAndMetadata, TypeName returnType) {
    FunctionDeclaration declaration = parseFunctionDeclaration(commentAndMetadata, null, returnType);
    Token propertyKeyword = declaration.propertyKeyword;
    if (propertyKeyword != null) {
      if (identical((propertyKeyword as KeywordToken).keyword, Keyword.GET)) {
        reportErrorForToken(ParserErrorCode.GETTER_IN_FUNCTION, propertyKeyword, []);
      } else {
        reportErrorForToken(ParserErrorCode.SETTER_IN_FUNCTION, propertyKeyword, []);
      }
    }
    return new FunctionDeclarationStatement(declaration);
  }

  /**
   * Parse a function type alias.
   *
   * <pre>
   * functionTypeAlias ::=
   *     functionPrefix typeParameterList? formalParameterList ';'
   *
   * functionPrefix ::=
   *     returnType? name
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the member
   * @param keyword the token representing the 'typedef' keyword
   * @return the function type alias that was parsed
   */
  FunctionTypeAlias parseFunctionTypeAlias(CommentAndMetadata commentAndMetadata, Token keyword) {
    TypeName returnType = null;
    if (hasReturnTypeInTypeAlias()) {
      returnType = parseReturnType();
    }
    SimpleIdentifier name = parseSimpleIdentifier();
    TypeParameterList typeParameters = null;
    if (matches(TokenType.LT)) {
      typeParameters = parseTypeParameterList();
    }
    if (matches(TokenType.SEMICOLON) || matches(TokenType.EOF)) {
      reportErrorForCurrentToken(ParserErrorCode.MISSING_TYPEDEF_PARAMETERS, []);
      FormalParameterList parameters = new FormalParameterList(createSyntheticToken(TokenType.OPEN_PAREN), null, null, null, createSyntheticToken(TokenType.CLOSE_PAREN));
      Token semicolon = expect(TokenType.SEMICOLON);
      return new FunctionTypeAlias(commentAndMetadata.comment, commentAndMetadata.metadata, keyword, returnType, name, typeParameters, parameters, semicolon);
    } else if (!matches(TokenType.OPEN_PAREN)) {
      reportErrorForCurrentToken(ParserErrorCode.MISSING_TYPEDEF_PARAMETERS, []);
      // TODO(brianwilkerson) Recover from this error. At the very least we should skip to the start
      // of the next valid compilation unit member, allowing for the possibility of finding the
      // typedef parameters before that point.
      return new FunctionTypeAlias(commentAndMetadata.comment, commentAndMetadata.metadata, keyword, returnType, name, typeParameters, new FormalParameterList(createSyntheticToken(TokenType.OPEN_PAREN), null, null, null, createSyntheticToken(TokenType.CLOSE_PAREN)), createSyntheticToken(TokenType.SEMICOLON));
    }
    FormalParameterList parameters = parseFormalParameterList();
    validateFormalParameterList(parameters);
    Token semicolon = expect(TokenType.SEMICOLON);
    return new FunctionTypeAlias(commentAndMetadata.comment, commentAndMetadata.metadata, keyword, returnType, name, typeParameters, parameters, semicolon);
  }

  /**
   * Parse a getter.
   *
   * <pre>
   * getter ::=
   *     getterSignature functionBody?
   *
   * getterSignature ::=
   *     'external'? 'static'? returnType? 'get' identifier
   * </pre>
   *
   * @param commentAndMetadata the documentation comment and metadata to be associated with the
   *          declaration
   * @param externalKeyword the 'external' token
   * @param staticKeyword the static keyword, or `null` if the getter is not static
   * @param the return type that has already been parsed, or `null` if there was no return
   *          type
   * @return the getter that was parsed
   */
  MethodDeclaration parseGetter(CommentAndMetadata commentAndMetadata, Token externalKeyword, Token staticKeyword, TypeName returnType) {
    Token propertyKeyword = expectKeyword(Keyword.GET);
    SimpleIdentifier name = parseSimpleIdentifier();
    if (matches(TokenType.OPEN_PAREN) && tokenMatches(peek(), TokenType.CLOSE_PAREN)) {
      reportErrorForCurrentToken(ParserErrorCode.GETTER_WITH_PARAMETERS, []);
      advance();
      advance();
    }
    FunctionBody body = parseFunctionBody(externalKeyword != null || staticKeyword == null, ParserErrorCode.STATIC_GETTER_WITHOUT_BODY, false);
    if (externalKeyword != null && body is! EmptyFunctionBody) {
      reportErrorForCurrentToken(ParserErrorCode.EXTERNAL_GETTER_WITH_BODY, []);
    }
    return new MethodDeclaration(commentAndMetadata.comment, commentAndMetadata.metadata, externalKeyword, staticKeyword, returnType, propertyKeyword, null, name, null, body);
  }

  /**
   * Parse a list of identifiers.
   *
   * <pre>
   * identifierList ::=
   *     identifier (',' identifier)*
   * </pre>
   *
   * @return the list of identifiers that were parsed
   */
  List<SimpleIdentifier> parseIdentifierList() {
    List<SimpleIdentifier> identifiers = new List<SimpleIdentifier>();
    identifiers.add(parseSimpleIdentifier());
    while (matches(TokenType.COMMA)) {
      advance();
      identifiers.add(parseSimpleIdentifier());
    }
    return identifiers;
  }

  /**
   * Parse an if statement.
   *
   * <pre>
   * ifStatement ::=
   *     'if' '(' expression ')' statement ('else' statement)?
   * </pre>
   *
   * @return the if statement that was parsed
   */
  Statement parseIfStatement() {
    Token ifKeyword = expectKeyword(Keyword.IF);
    Token leftParenthesis = expect(TokenType.OPEN_PAREN);
    Expression condition = parseExpression2();
    Token rightParenthesis = expect(TokenType.CLOSE_PAREN);
    Statement thenStatement = parseStatement2();
    Token elseKeyword = null;
    Statement elseStatement = null;
    if (matchesKeyword(Keyword.ELSE)) {
      elseKeyword = andAdvance;
      elseStatement = parseStatement2();
    }
    return new IfStatement(ifKeyword, leftParenthesis, condition, rightParenthesis, thenStatement, elseKeyword, elseStatement);
  }

  /**
   * Parse an import directive.
   *
   * <pre>
   * importDirective ::=
   *     metadata 'import' stringLiteral ('as' identifier)? combinator*';'
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the directive
   * @return the import directive that was parsed
   */
  ImportDirective parseImportDirective(CommentAndMetadata commentAndMetadata) {
    Token importKeyword = expectKeyword(Keyword.IMPORT);
    StringLiteral libraryUri = parseStringLiteral();
    Token asToken = null;
    SimpleIdentifier prefix = null;
    if (matchesKeyword(Keyword.AS)) {
      asToken = andAdvance;
      prefix = parseSimpleIdentifier();
    }
    List<Combinator> combinators = parseCombinators();
    Token semicolon = expectSemicolon();
    return new ImportDirective(commentAndMetadata.comment, commentAndMetadata.metadata, importKeyword, libraryUri, asToken, prefix, combinators, semicolon);
  }

  /**
   * Parse a list of initialized identifiers.
   *
   * <pre>
   * ?? ::=
   *     'static'? ('var' | type) initializedIdentifierList ';'
   *   | 'final' type? initializedIdentifierList ';'
   *
   * initializedIdentifierList ::=
   *     initializedIdentifier (',' initializedIdentifier)*
   *
   * initializedIdentifier ::=
   *     identifier ('=' expression)?
   * </pre>
   *
   * @param commentAndMetadata the documentation comment and metadata to be associated with the
   *          declaration
   * @param staticKeyword the static keyword, or `null` if the getter is not static
   * @param keyword the token representing the 'final', 'const' or 'var' keyword, or `null` if
   *          there is no keyword
   * @param type the type that has already been parsed, or `null` if 'var' was provided
   * @return the getter that was parsed
   */
  FieldDeclaration parseInitializedIdentifierList(CommentAndMetadata commentAndMetadata, Token staticKeyword, Token keyword, TypeName type) {
    VariableDeclarationList fieldList = parseVariableDeclarationListAfterType(null, keyword, type);
    return new FieldDeclaration(commentAndMetadata.comment, commentAndMetadata.metadata, staticKeyword, fieldList, expect(TokenType.SEMICOLON));
  }

  /**
   * Parse an instance creation expression.
   *
   * <pre>
   * instanceCreationExpression ::=
   *     ('new' | 'const') type ('.' identifier)? argumentList
   * </pre>
   *
   * @param keyword the 'new' or 'const' keyword that introduces the expression
   * @return the instance creation expression that was parsed
   */
  InstanceCreationExpression parseInstanceCreationExpression(Token keyword) {
    ConstructorName constructorName = parseConstructorName();
    ArgumentList argumentList = parseArgumentList();
    return new InstanceCreationExpression(keyword, constructorName, argumentList);
  }

  /**
   * Parse a library directive.
   *
   * <pre>
   * libraryDirective ::=
   *     metadata 'library' identifier ';'
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the directive
   * @return the library directive that was parsed
   */
  LibraryDirective parseLibraryDirective(CommentAndMetadata commentAndMetadata) {
    Token keyword = expectKeyword(Keyword.LIBRARY);
    LibraryIdentifier libraryName = parseLibraryName(ParserErrorCode.MISSING_NAME_IN_LIBRARY_DIRECTIVE, keyword);
    Token semicolon = expect(TokenType.SEMICOLON);
    return new LibraryDirective(commentAndMetadata.comment, commentAndMetadata.metadata, keyword, libraryName, semicolon);
  }

  /**
   * Parse a library name.
   *
   * <pre>
   * libraryName ::=
   *     libraryIdentifier
   * </pre>
   *
   * @param missingNameError the error code to be used if the library name is missing
   * @param missingNameToken the token associated with the error produced if the library name is
   *          missing
   * @return the library name that was parsed
   */
  LibraryIdentifier parseLibraryName(ParserErrorCode missingNameError, Token missingNameToken) {
    if (matchesIdentifier()) {
      return parseLibraryIdentifier();
    } else if (matches(TokenType.STRING)) {
      // TODO(brianwilkerson) Recovery: This should be extended to handle arbitrary tokens until we
      // can find a token that can start a compilation unit member.
      StringLiteral string = parseStringLiteral();
      reportErrorForNode(ParserErrorCode.NON_IDENTIFIER_LIBRARY_NAME, string, []);
    } else {
      reportErrorForToken(missingNameError, missingNameToken, []);
    }
    List<SimpleIdentifier> components = new List<SimpleIdentifier>();
    components.add(createSyntheticIdentifier());
    return new LibraryIdentifier(components);
  }

  /**
   * Parse a list literal.
   *
   * <pre>
   * listLiteral ::=
   *     'const'? typeArguments? '[' (expressionList ','?)? ']'
   * </pre>
   *
   * @param modifier the 'const' modifier appearing before the literal, or `null` if there is
   *          no modifier
   * @param typeArguments the type arguments appearing before the literal, or `null` if there
   *          are no type arguments
   * @return the list literal that was parsed
   */
  ListLiteral parseListLiteral(Token modifier, TypeArgumentList typeArguments) {
    // may be empty list literal
    if (matches(TokenType.INDEX)) {
      BeginToken leftBracket = new BeginToken(TokenType.OPEN_SQUARE_BRACKET, _currentToken.offset);
      Token rightBracket = new Token(TokenType.CLOSE_SQUARE_BRACKET, _currentToken.offset + 1);
      leftBracket.endToken = rightBracket;
      rightBracket.setNext(_currentToken.next);
      leftBracket.setNext(rightBracket);
      _currentToken.previous.setNext(leftBracket);
      _currentToken = _currentToken.next;
      return new ListLiteral(modifier, typeArguments, leftBracket, null, rightBracket);
    }
    // open
    Token leftBracket = expect(TokenType.OPEN_SQUARE_BRACKET);
    if (matches(TokenType.CLOSE_SQUARE_BRACKET)) {
      return new ListLiteral(modifier, typeArguments, leftBracket, null, andAdvance);
    }
    List<Expression> elements = new List<Expression>();
    elements.add(parseExpression2());
    while (optional(TokenType.COMMA)) {
      if (matches(TokenType.CLOSE_SQUARE_BRACKET)) {
        return new ListLiteral(modifier, typeArguments, leftBracket, elements, andAdvance);
      }
      elements.add(parseExpression2());
    }
    Token rightBracket = expect(TokenType.CLOSE_SQUARE_BRACKET);
    return new ListLiteral(modifier, typeArguments, leftBracket, elements, rightBracket);
  }

  /**
   * Parse a list or map literal.
   *
   * <pre>
   * listOrMapLiteral ::=
   *     listLiteral
   *   | mapLiteral
   * </pre>
   *
   * @param modifier the 'const' modifier appearing before the literal, or `null` if there is
   *          no modifier
   * @return the list or map literal that was parsed
   */
  TypedLiteral parseListOrMapLiteral(Token modifier) {
    TypeArgumentList typeArguments = null;
    if (matches(TokenType.LT)) {
      typeArguments = parseTypeArgumentList();
    }
    if (matches(TokenType.OPEN_CURLY_BRACKET)) {
      return parseMapLiteral(modifier, typeArguments);
    } else if (matches(TokenType.OPEN_SQUARE_BRACKET) || matches(TokenType.INDEX)) {
      return parseListLiteral(modifier, typeArguments);
    }
    reportErrorForCurrentToken(ParserErrorCode.EXPECTED_LIST_OR_MAP_LITERAL, []);
    return new ListLiteral(modifier, typeArguments, createSyntheticToken(TokenType.OPEN_SQUARE_BRACKET), null, createSyntheticToken(TokenType.CLOSE_SQUARE_BRACKET));
  }

  /**
   * Parse a logical and expression.
   *
   * <pre>
   * logicalAndExpression ::=
   *     equalityExpression ('&&' equalityExpression)*
   * </pre>
   *
   * @return the logical and expression that was parsed
   */
  Expression parseLogicalAndExpression() {
    Expression expression = parseEqualityExpression();
    while (matches(TokenType.AMPERSAND_AMPERSAND)) {
      Token operator = andAdvance;
      expression = new BinaryExpression(expression, operator, parseEqualityExpression());
    }
    return expression;
  }

  /**
   * Parse a map literal.
   *
   * <pre>
   * mapLiteral ::=
   *     'const'? typeArguments? '{' (mapLiteralEntry (',' mapLiteralEntry)* ','?)? '}'
   * </pre>
   *
   * @param modifier the 'const' modifier appearing before the literal, or `null` if there is
   *          no modifier
   * @param typeArguments the type arguments that were declared, or `null` if there are no
   *          type arguments
   * @return the map literal that was parsed
   */
  MapLiteral parseMapLiteral(Token modifier, TypeArgumentList typeArguments) {
    Token leftBracket = expect(TokenType.OPEN_CURLY_BRACKET);
    List<MapLiteralEntry> entries = new List<MapLiteralEntry>();
    if (matches(TokenType.CLOSE_CURLY_BRACKET)) {
      return new MapLiteral(modifier, typeArguments, leftBracket, entries, andAdvance);
    }
    entries.add(parseMapLiteralEntry());
    while (optional(TokenType.COMMA)) {
      if (matches(TokenType.CLOSE_CURLY_BRACKET)) {
        return new MapLiteral(modifier, typeArguments, leftBracket, entries, andAdvance);
      }
      entries.add(parseMapLiteralEntry());
    }
    Token rightBracket = expect(TokenType.CLOSE_CURLY_BRACKET);
    return new MapLiteral(modifier, typeArguments, leftBracket, entries, rightBracket);
  }

  /**
   * Parse a method declaration.
   *
   * <pre>
   * functionDeclaration ::=
   *     ('external' 'static'?)? functionSignature functionBody
   *   | 'external'? functionSignature ';'
   * </pre>
   *
   * @param commentAndMetadata the documentation comment and metadata to be associated with the
   *          declaration
   * @param externalKeyword the 'external' token
   * @param staticKeyword the static keyword, or `null` if the getter is not static
   * @param returnType the return type of the method
   * @param name the name of the method
   * @param parameters the parameters to the method
   * @return the method declaration that was parsed
   */
  MethodDeclaration parseMethodDeclarationAfterParameters(CommentAndMetadata commentAndMetadata, Token externalKeyword, Token staticKeyword, TypeName returnType, SimpleIdentifier name, FormalParameterList parameters) {
    FunctionBody body = parseFunctionBody(externalKeyword != null || staticKeyword == null, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    if (externalKeyword != null) {
      if (body is! EmptyFunctionBody) {
        reportErrorForNode(ParserErrorCode.EXTERNAL_METHOD_WITH_BODY, body, []);
      }
    } else if (staticKeyword != null) {
      if (body is EmptyFunctionBody) {
        reportErrorForNode(ParserErrorCode.ABSTRACT_STATIC_METHOD, body, []);
      }
    }
    return new MethodDeclaration(commentAndMetadata.comment, commentAndMetadata.metadata, externalKeyword, staticKeyword, returnType, null, null, name, parameters, body);
  }

  /**
   * Parse a method declaration.
   *
   * <pre>
   * functionDeclaration ::=
   *     'external'? 'static'? functionSignature functionBody
   *   | 'external'? functionSignature ';'
   * </pre>
   *
   * @param commentAndMetadata the documentation comment and metadata to be associated with the
   *          declaration
   * @param externalKeyword the 'external' token
   * @param staticKeyword the static keyword, or `null` if the getter is not static
   * @param returnType the return type of the method
   * @return the method declaration that was parsed
   */
  MethodDeclaration parseMethodDeclarationAfterReturnType(CommentAndMetadata commentAndMetadata, Token externalKeyword, Token staticKeyword, TypeName returnType) {
    SimpleIdentifier methodName = parseSimpleIdentifier();
    FormalParameterList parameters = parseFormalParameterList();
    validateFormalParameterList(parameters);
    return parseMethodDeclarationAfterParameters(commentAndMetadata, externalKeyword, staticKeyword, returnType, methodName, parameters);
  }

  /**
   * Parse the modifiers preceding a declaration. This method allows the modifiers to appear in any
   * order but does generate errors for duplicated modifiers. Checks for other problems, such as
   * having the modifiers appear in the wrong order or specifying both 'const' and 'final', are
   * reported in one of the methods whose name is prefixed with `validateModifiersFor`.
   *
   * <pre>
   * modifiers ::=
   *     ('abstract' | 'const' | 'external' | 'factory' | 'final' | 'static' | 'var')*
   * </pre>
   *
   * @return the modifiers that were parsed
   */
  Modifiers parseModifiers() {
    Modifiers modifiers = new Modifiers();
    bool progress = true;
    while (progress) {
      if (tokenMatches(peek(), TokenType.PERIOD) || tokenMatches(peek(), TokenType.LT) || tokenMatches(peek(), TokenType.OPEN_PAREN)) {
        return modifiers;
      }
      if (matchesKeyword(Keyword.ABSTRACT)) {
        if (modifiers.abstractKeyword != null) {
          reportErrorForCurrentToken(ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          advance();
        } else {
          modifiers.abstractKeyword = andAdvance;
        }
      } else if (matchesKeyword(Keyword.CONST)) {
        if (modifiers.constKeyword != null) {
          reportErrorForCurrentToken(ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          advance();
        } else {
          modifiers.constKeyword = andAdvance;
        }
      } else if (matchesKeyword(Keyword.EXTERNAL) && !tokenMatches(peek(), TokenType.PERIOD) && !tokenMatches(peek(), TokenType.LT)) {
        if (modifiers.externalKeyword != null) {
          reportErrorForCurrentToken(ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          advance();
        } else {
          modifiers.externalKeyword = andAdvance;
        }
      } else if (matchesKeyword(Keyword.FACTORY) && !tokenMatches(peek(), TokenType.PERIOD) && !tokenMatches(peek(), TokenType.LT)) {
        if (modifiers.factoryKeyword != null) {
          reportErrorForCurrentToken(ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          advance();
        } else {
          modifiers.factoryKeyword = andAdvance;
        }
      } else if (matchesKeyword(Keyword.FINAL)) {
        if (modifiers.finalKeyword != null) {
          reportErrorForCurrentToken(ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          advance();
        } else {
          modifiers.finalKeyword = andAdvance;
        }
      } else if (matchesKeyword(Keyword.STATIC) && !tokenMatches(peek(), TokenType.PERIOD) && !tokenMatches(peek(), TokenType.LT)) {
        if (modifiers.staticKeyword != null) {
          reportErrorForCurrentToken(ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          advance();
        } else {
          modifiers.staticKeyword = andAdvance;
        }
      } else if (matchesKeyword(Keyword.VAR)) {
        if (modifiers.varKeyword != null) {
          reportErrorForCurrentToken(ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          advance();
        } else {
          modifiers.varKeyword = andAdvance;
        }
      } else {
        progress = false;
      }
    }
    return modifiers;
  }

  /**
   * Parse a multiplicative expression.
   *
   * <pre>
   * multiplicativeExpression ::=
   *     unaryExpression (multiplicativeOperator unaryExpression)*
   *   | 'super' (multiplicativeOperator unaryExpression)+
   * </pre>
   *
   * @return the multiplicative expression that was parsed
   */
  Expression parseMultiplicativeExpression() {
    Expression expression;
    if (matchesKeyword(Keyword.SUPER) && _currentToken.next.type.isMultiplicativeOperator) {
      expression = new SuperExpression(andAdvance);
    } else {
      expression = parseUnaryExpression();
    }
    while (_currentToken.type.isMultiplicativeOperator) {
      Token operator = andAdvance;
      expression = new BinaryExpression(expression, operator, parseUnaryExpression());
    }
    return expression;
  }

  /**
   * Parse a class native clause.
   *
   * <pre>
   * classNativeClause ::=
   *     'native' name
   * </pre>
   *
   * @return the class native clause that was parsed
   */
  NativeClause parseNativeClause() {
    Token keyword = andAdvance;
    StringLiteral name = parseStringLiteral();
    return new NativeClause(keyword, name);
  }

  /**
   * Parse a new expression.
   *
   * <pre>
   * newExpression ::=
   *     instanceCreationExpression
   * </pre>
   *
   * @return the new expression that was parsed
   */
  InstanceCreationExpression parseNewExpression() => parseInstanceCreationExpression(expectKeyword(Keyword.NEW));

  /**
   * Parse a non-labeled statement.
   *
   * <pre>
   * nonLabeledStatement ::=
   *     block
   *   | assertStatement
   *   | breakStatement
   *   | continueStatement
   *   | doStatement
   *   | forStatement
   *   | ifStatement
   *   | returnStatement
   *   | switchStatement
   *   | tryStatement
   *   | whileStatement
   *   | variableDeclarationList ';'
   *   | expressionStatement
   *   | functionSignature functionBody
   * </pre>
   *
   * @return the non-labeled statement that was parsed
   */
  Statement parseNonLabeledStatement() {
    // TODO(brianwilkerson) Pass the comment and metadata on where appropriate.
    CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
    if (matches(TokenType.OPEN_CURLY_BRACKET)) {
      if (tokenMatches(peek(), TokenType.STRING)) {
        Token afterString = skipStringLiteral(_currentToken.next);
        if (afterString != null && identical(afterString.type, TokenType.COLON)) {
          return new ExpressionStatement(parseExpression2(), expect(TokenType.SEMICOLON));
        }
      }
      return parseBlock();
    } else if (matches(TokenType.KEYWORD) && !(_currentToken as KeywordToken).keyword.isPseudoKeyword) {
      Keyword keyword = (_currentToken as KeywordToken).keyword;
      // TODO(jwren) compute some metrics to figure out a better order for this if-then sequence to optimize performance
      if (identical(keyword, Keyword.ASSERT)) {
        return parseAssertStatement();
      } else if (identical(keyword, Keyword.BREAK)) {
        return parseBreakStatement();
      } else if (identical(keyword, Keyword.CONTINUE)) {
        return parseContinueStatement();
      } else if (identical(keyword, Keyword.DO)) {
        return parseDoStatement();
      } else if (identical(keyword, Keyword.FOR)) {
        return parseForStatement();
      } else if (identical(keyword, Keyword.IF)) {
        return parseIfStatement();
      } else if (identical(keyword, Keyword.RETHROW)) {
        return new ExpressionStatement(parseRethrowExpression(), expect(TokenType.SEMICOLON));
      } else if (identical(keyword, Keyword.RETURN)) {
        return parseReturnStatement();
      } else if (identical(keyword, Keyword.SWITCH)) {
        return parseSwitchStatement();
      } else if (identical(keyword, Keyword.THROW)) {
        return new ExpressionStatement(parseThrowExpression(), expect(TokenType.SEMICOLON));
      } else if (identical(keyword, Keyword.TRY)) {
        return parseTryStatement();
      } else if (identical(keyword, Keyword.WHILE)) {
        return parseWhileStatement();
      } else if (identical(keyword, Keyword.VAR) || identical(keyword, Keyword.FINAL)) {
        return parseVariableDeclarationStatementAfterMetadata(commentAndMetadata);
      } else if (identical(keyword, Keyword.VOID)) {
        TypeName returnType = parseReturnType();
        if (matchesIdentifier() && matchesAny(peek(), [
            TokenType.OPEN_PAREN,
            TokenType.OPEN_CURLY_BRACKET,
            TokenType.FUNCTION])) {
          return parseFunctionDeclarationStatementAfterReturnType(commentAndMetadata, returnType);
        } else {
          //
          // We have found an error of some kind. Try to recover.
          //
          if (matchesIdentifier()) {
            if (matchesAny(peek(), [TokenType.EQ, TokenType.COMMA, TokenType.SEMICOLON])) {
              //
              // We appear to have a variable declaration with a type of "void".
              //
              reportErrorForNode(ParserErrorCode.VOID_VARIABLE, returnType, []);
              return parseVariableDeclarationStatementAfterMetadata(commentAndMetadata);
            }
          } else if (matches(TokenType.CLOSE_CURLY_BRACKET)) {
            //
            // We appear to have found an incomplete statement at the end of a block. Parse it as a
            // variable declaration.
            //
            return parseVariableDeclarationStatementAfterType(commentAndMetadata, null, returnType);
          }
          reportErrorForCurrentToken(ParserErrorCode.MISSING_STATEMENT, []);
          // TODO(brianwilkerson) Recover from this error.
          return new EmptyStatement(createSyntheticToken(TokenType.SEMICOLON));
        }
      } else if (identical(keyword, Keyword.CONST)) {
        if (matchesAny(peek(), [
            TokenType.LT,
            TokenType.OPEN_CURLY_BRACKET,
            TokenType.OPEN_SQUARE_BRACKET,
            TokenType.INDEX])) {
          return new ExpressionStatement(parseExpression2(), expect(TokenType.SEMICOLON));
        } else if (tokenMatches(peek(), TokenType.IDENTIFIER)) {
          Token afterType = skipTypeName(peek());
          if (afterType != null) {
            if (tokenMatches(afterType, TokenType.OPEN_PAREN) || (tokenMatches(afterType, TokenType.PERIOD) && tokenMatches(afterType.next, TokenType.IDENTIFIER) && tokenMatches(afterType.next.next, TokenType.OPEN_PAREN))) {
              return new ExpressionStatement(parseExpression2(), expect(TokenType.SEMICOLON));
            }
          }
        }
        return parseVariableDeclarationStatementAfterMetadata(commentAndMetadata);
      } else if (identical(keyword, Keyword.NEW) || identical(keyword, Keyword.TRUE) || identical(keyword, Keyword.FALSE) || identical(keyword, Keyword.NULL) || identical(keyword, Keyword.SUPER) || identical(keyword, Keyword.THIS)) {
        return new ExpressionStatement(parseExpression2(), expect(TokenType.SEMICOLON));
      } else {
        //
        // We have found an error of some kind. Try to recover.
        //
        reportErrorForCurrentToken(ParserErrorCode.MISSING_STATEMENT, []);
        return new EmptyStatement(createSyntheticToken(TokenType.SEMICOLON));
      }
    } else if (matches(TokenType.SEMICOLON)) {
      return parseEmptyStatement();
    } else if (isInitializedVariableDeclaration()) {
      return parseVariableDeclarationStatementAfterMetadata(commentAndMetadata);
    } else if (isFunctionDeclaration()) {
      return parseFunctionDeclarationStatement();
    } else if (matches(TokenType.CLOSE_CURLY_BRACKET)) {
      reportErrorForCurrentToken(ParserErrorCode.MISSING_STATEMENT, []);
      return new EmptyStatement(createSyntheticToken(TokenType.SEMICOLON));
    } else {
      return new ExpressionStatement(parseExpression2(), expect(TokenType.SEMICOLON));
    }
  }

  /**
   * Parse an operator declaration.
   *
   * <pre>
   * operatorDeclaration ::=
   *     operatorSignature (';' | functionBody)
   *
   * operatorSignature ::=
   *     'external'? returnType? 'operator' operator formalParameterList
   * </pre>
   *
   * @param commentAndMetadata the documentation comment and metadata to be associated with the
   *          declaration
   * @param externalKeyword the 'external' token
   * @param the return type that has already been parsed, or `null` if there was no return
   *          type
   * @return the operator declaration that was parsed
   */
  MethodDeclaration parseOperator(CommentAndMetadata commentAndMetadata, Token externalKeyword, TypeName returnType) {
    Token operatorKeyword;
    if (matchesKeyword(Keyword.OPERATOR)) {
      operatorKeyword = andAdvance;
    } else {
      reportErrorForToken(ParserErrorCode.MISSING_KEYWORD_OPERATOR, _currentToken, []);
      operatorKeyword = createSyntheticKeyword(Keyword.OPERATOR);
    }
    if (!_currentToken.isUserDefinableOperator) {
      reportErrorForCurrentToken(ParserErrorCode.NON_USER_DEFINABLE_OPERATOR, [_currentToken.lexeme]);
    }
    SimpleIdentifier name = new SimpleIdentifier(andAdvance);
    if (matches(TokenType.EQ)) {
      Token previous = _currentToken.previous;
      if ((tokenMatches(previous, TokenType.EQ_EQ) || tokenMatches(previous, TokenType.BANG_EQ)) && _currentToken.offset == previous.offset + 2) {
        reportErrorForCurrentToken(ParserErrorCode.INVALID_OPERATOR, ["${previous.lexeme}${_currentToken.lexeme}"]);
        advance();
      }
    }
    FormalParameterList parameters = parseFormalParameterList();
    validateFormalParameterList(parameters);
    FunctionBody body = parseFunctionBody(true, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    if (externalKeyword != null && body is! EmptyFunctionBody) {
      reportErrorForCurrentToken(ParserErrorCode.EXTERNAL_OPERATOR_WITH_BODY, []);
    }
    return new MethodDeclaration(commentAndMetadata.comment, commentAndMetadata.metadata, externalKeyword, null, returnType, null, operatorKeyword, name, parameters, body);
  }

  /**
   * Parse a return type if one is given, otherwise return `null` without advancing.
   *
   * @return the return type that was parsed
   */
  TypeName parseOptionalReturnType() {
    if (matchesKeyword(Keyword.VOID)) {
      return parseReturnType();
    } else if (matchesIdentifier() && !matchesKeyword(Keyword.GET) && !matchesKeyword(Keyword.SET) && !matchesKeyword(Keyword.OPERATOR) && (tokenMatchesIdentifier(peek()) || tokenMatches(peek(), TokenType.LT))) {
      return parseReturnType();
    } else if (matchesIdentifier() && tokenMatches(peek(), TokenType.PERIOD) && tokenMatchesIdentifier(peek2(2)) && (tokenMatchesIdentifier(peek2(3)) || tokenMatches(peek2(3), TokenType.LT))) {
      return parseReturnType();
    }
    return null;
  }

  /**
   * Parse a part or part-of directive.
   *
   * <pre>
   * partDirective ::=
   *     metadata 'part' stringLiteral ';'
   *
   * partOfDirective ::=
   *     metadata 'part' 'of' identifier ';'
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the directive
   * @return the part or part-of directive that was parsed
   */
  Directive parsePartDirective(CommentAndMetadata commentAndMetadata) {
    Token partKeyword = expectKeyword(Keyword.PART);
    if (matchesString(_OF)) {
      Token ofKeyword = andAdvance;
      LibraryIdentifier libraryName = parseLibraryName(ParserErrorCode.MISSING_NAME_IN_PART_OF_DIRECTIVE, ofKeyword);
      Token semicolon = expect(TokenType.SEMICOLON);
      return new PartOfDirective(commentAndMetadata.comment, commentAndMetadata.metadata, partKeyword, ofKeyword, libraryName, semicolon);
    }
    StringLiteral partUri = parseStringLiteral();
    Token semicolon = expect(TokenType.SEMICOLON);
    return new PartDirective(commentAndMetadata.comment, commentAndMetadata.metadata, partKeyword, partUri, semicolon);
  }

  /**
   * Parse a postfix expression.
   *
   * <pre>
   * postfixExpression ::=
   *     assignableExpression postfixOperator
   *   | primary selector*
   *
   * selector ::=
   *     assignableSelector
   *   | argumentList
   * </pre>
   *
   * @return the postfix expression that was parsed
   */
  Expression parsePostfixExpression() {
    Expression operand = parseAssignableExpression(true);
    if (matches(TokenType.OPEN_SQUARE_BRACKET) || matches(TokenType.PERIOD) || matches(TokenType.OPEN_PAREN)) {
      do {
        if (matches(TokenType.OPEN_PAREN)) {
          ArgumentList argumentList = parseArgumentList();
          if (operand is PropertyAccess) {
            PropertyAccess access = operand as PropertyAccess;
            operand = new MethodInvocation(access.target, access.operator, access.propertyName, argumentList);
          } else {
            operand = new FunctionExpressionInvocation(operand, argumentList);
          }
        } else {
          operand = parseAssignableSelector(operand, true);
        }
      } while (matches(TokenType.OPEN_SQUARE_BRACKET) || matches(TokenType.PERIOD) || matches(TokenType.OPEN_PAREN));
      return operand;
    }
    if (!_currentToken.type.isIncrementOperator) {
      return operand;
    }
    ensureAssignable(operand);
    Token operator = andAdvance;
    return new PostfixExpression(operand, operator);
  }

  /**
   * Parse a primary expression.
   *
   * <pre>
   * primary ::=
   *     thisExpression
   *   | 'super' assignableSelector
   *   | functionExpression
   *   | literal
   *   | identifier
   *   | newExpression
   *   | constObjectExpression
   *   | '(' expression ')'
   *   | argumentDefinitionTest
   *
   * literal ::=
   *     nullLiteral
   *   | booleanLiteral
   *   | numericLiteral
   *   | stringLiteral
   *   | symbolLiteral
   *   | mapLiteral
   *   | listLiteral
   * </pre>
   *
   * @return the primary expression that was parsed
   */
  Expression parsePrimaryExpression() {
    if (matchesKeyword(Keyword.THIS)) {
      return new ThisExpression(andAdvance);
    } else if (matchesKeyword(Keyword.SUPER)) {
      return parseAssignableSelector(new SuperExpression(andAdvance), false);
    } else if (matchesKeyword(Keyword.NULL)) {
      return new NullLiteral(andAdvance);
    } else if (matchesKeyword(Keyword.FALSE)) {
      return new BooleanLiteral(andAdvance, false);
    } else if (matchesKeyword(Keyword.TRUE)) {
      return new BooleanLiteral(andAdvance, true);
    } else if (matches(TokenType.DOUBLE)) {
      Token token = andAdvance;
      double value = 0.0;
      try {
        value = double.parse(token.lexeme);
      } on FormatException catch (exception) {
      }
      return new DoubleLiteral(token, value);
    } else if (matches(TokenType.HEXADECIMAL)) {
      Token token = andAdvance;
      int value = null;
      try {
        value = int.parse(token.lexeme.substring(2), radix: 16);
      } on FormatException catch (exception) {
      }
      return new IntegerLiteral(token, value);
    } else if (matches(TokenType.INT)) {
      Token token = andAdvance;
      int value = null;
      try {
        value = int.parse(token.lexeme);
      } on FormatException catch (exception) {
      }
      return new IntegerLiteral(token, value);
    } else if (matches(TokenType.STRING)) {
      return parseStringLiteral();
    } else if (matches(TokenType.OPEN_CURLY_BRACKET)) {
      return parseMapLiteral(null, null);
    } else if (matches(TokenType.OPEN_SQUARE_BRACKET) || matches(TokenType.INDEX)) {
      return parseListLiteral(null, null);
    } else if (matchesIdentifier()) {
      // TODO(brianwilkerson) The code below was an attempt to recover from an error case, but it
      // needs to be applied as a recovery only after we know that parsing it as an identifier
      // doesn't work. Leaving the code as a reminder of how to recover.
      //      if (isFunctionExpression(peek())) {
      //        //
      //        // Function expressions were allowed to have names at one point, but this is now illegal.
      //        //
      //        reportError(ParserErrorCode.NAMED_FUNCTION_EXPRESSION, getAndAdvance());
      //        return parseFunctionExpression();
      //      }
      return parsePrefixedIdentifier();
    } else if (matchesKeyword(Keyword.NEW)) {
      return parseNewExpression();
    } else if (matchesKeyword(Keyword.CONST)) {
      return parseConstExpression();
    } else if (matches(TokenType.OPEN_PAREN)) {
      if (isFunctionExpression(_currentToken)) {
        return parseFunctionExpression();
      }
      Token leftParenthesis = andAdvance;
      Expression expression = parseExpression2();
      Token rightParenthesis = expect(TokenType.CLOSE_PAREN);
      return new ParenthesizedExpression(leftParenthesis, expression, rightParenthesis);
    } else if (matches(TokenType.LT)) {
      return parseListOrMapLiteral(null);
    } else if (matches(TokenType.QUESTION)) {
      return parseArgumentDefinitionTest();
    } else if (matchesKeyword(Keyword.VOID)) {
      //
      // Recover from having a return type of "void" where a return type is not expected.
      //
      // TODO(brianwilkerson) Improve this error message.
      reportErrorForCurrentToken(ParserErrorCode.UNEXPECTED_TOKEN, [_currentToken.lexeme]);
      advance();
      return parsePrimaryExpression();
    } else if (matches(TokenType.HASH)) {
      return parseSymbolLiteral();
    } else {
      reportErrorForCurrentToken(ParserErrorCode.MISSING_IDENTIFIER, []);
      return createSyntheticIdentifier();
    }
  }

  /**
   * Parse a redirecting constructor invocation.
   *
   * <pre>
   * redirectingConstructorInvocation ::=
   *     'this' ('.' identifier)? arguments
   * </pre>
   *
   * @return the redirecting constructor invocation that was parsed
   */
  RedirectingConstructorInvocation parseRedirectingConstructorInvocation() {
    Token keyword = expectKeyword(Keyword.THIS);
    Token period = null;
    SimpleIdentifier constructorName = null;
    if (matches(TokenType.PERIOD)) {
      period = andAdvance;
      constructorName = parseSimpleIdentifier();
    }
    ArgumentList argumentList = parseArgumentList();
    return new RedirectingConstructorInvocation(keyword, period, constructorName, argumentList);
  }

  /**
   * Parse a relational expression.
   *
   * <pre>
   * relationalExpression ::=
   *     bitwiseOrExpression ('is' '!'? type | 'as' type | relationalOperator bitwiseOrExpression)?
   *   | 'super' relationalOperator bitwiseOrExpression
   * </pre>
   *
   * @return the relational expression that was parsed
   */
  Expression parseRelationalExpression() {
    if (matchesKeyword(Keyword.SUPER) && _currentToken.next.type.isRelationalOperator) {
      Expression expression = new SuperExpression(andAdvance);
      Token operator = andAdvance;
      expression = new BinaryExpression(expression, operator, parseBitwiseOrExpression());
      return expression;
    }
    Expression expression = parseBitwiseOrExpression();
    if (matchesKeyword(Keyword.AS)) {
      Token asOperator = andAdvance;
      expression = new AsExpression(expression, asOperator, parseTypeName());
    } else if (matchesKeyword(Keyword.IS)) {
      Token isOperator = andAdvance;
      Token notOperator = null;
      if (matches(TokenType.BANG)) {
        notOperator = andAdvance;
      }
      expression = new IsExpression(expression, isOperator, notOperator, parseTypeName());
    } else if (_currentToken.type.isRelationalOperator) {
      Token operator = andAdvance;
      expression = new BinaryExpression(expression, operator, parseBitwiseOrExpression());
    }
    return expression;
  }

  /**
   * Parse a rethrow expression.
   *
   * <pre>
   * rethrowExpression ::=
   *     'rethrow'
   * </pre>
   *
   * @return the rethrow expression that was parsed
   */
  Expression parseRethrowExpression() => new RethrowExpression(expectKeyword(Keyword.RETHROW));

  /**
   * Parse a return statement.
   *
   * <pre>
   * returnStatement ::=
   *     'return' expression? ';'
   * </pre>
   *
   * @return the return statement that was parsed
   */
  Statement parseReturnStatement() {
    Token returnKeyword = expectKeyword(Keyword.RETURN);
    if (matches(TokenType.SEMICOLON)) {
      return new ReturnStatement(returnKeyword, null, andAdvance);
    }
    Expression expression = parseExpression2();
    Token semicolon = expect(TokenType.SEMICOLON);
    return new ReturnStatement(returnKeyword, expression, semicolon);
  }

  /**
   * Parse a setter.
   *
   * <pre>
   * setter ::=
   *     setterSignature functionBody?
   *
   * setterSignature ::=
   *     'external'? 'static'? returnType? 'set' identifier formalParameterList
   * </pre>
   *
   * @param commentAndMetadata the documentation comment and metadata to be associated with the
   *          declaration
   * @param externalKeyword the 'external' token
   * @param staticKeyword the static keyword, or `null` if the setter is not static
   * @param the return type that has already been parsed, or `null` if there was no return
   *          type
   * @return the setter that was parsed
   */
  MethodDeclaration parseSetter(CommentAndMetadata commentAndMetadata, Token externalKeyword, Token staticKeyword, TypeName returnType) {
    Token propertyKeyword = expectKeyword(Keyword.SET);
    SimpleIdentifier name = parseSimpleIdentifier();
    FormalParameterList parameters = parseFormalParameterList();
    validateFormalParameterList(parameters);
    FunctionBody body = parseFunctionBody(externalKeyword != null || staticKeyword == null, ParserErrorCode.STATIC_SETTER_WITHOUT_BODY, false);
    if (externalKeyword != null && body is! EmptyFunctionBody) {
      reportErrorForCurrentToken(ParserErrorCode.EXTERNAL_SETTER_WITH_BODY, []);
    }
    return new MethodDeclaration(commentAndMetadata.comment, commentAndMetadata.metadata, externalKeyword, staticKeyword, returnType, propertyKeyword, null, name, parameters, body);
  }

  /**
   * Parse a shift expression.
   *
   * <pre>
   * shiftExpression ::=
   *     additiveExpression (shiftOperator additiveExpression)*
   *   | 'super' (shiftOperator additiveExpression)+
   * </pre>
   *
   * @return the shift expression that was parsed
   */
  Expression parseShiftExpression() {
    Expression expression;
    if (matchesKeyword(Keyword.SUPER) && _currentToken.next.type.isShiftOperator) {
      expression = new SuperExpression(andAdvance);
    } else {
      expression = parseAdditiveExpression();
    }
    while (_currentToken.type.isShiftOperator) {
      Token operator = andAdvance;
      expression = new BinaryExpression(expression, operator, parseAdditiveExpression());
    }
    return expression;
  }

  /**
   * Parse a list of statements within a switch statement.
   *
   * <pre>
   * statements ::=
   *     statement*
   * </pre>
   *
   * @return the statements that were parsed
   */
  List<Statement> parseStatementList() {
    List<Statement> statements = new List<Statement>();
    Token statementStart = _currentToken;
    while (!matches(TokenType.EOF) && !matches(TokenType.CLOSE_CURLY_BRACKET) && !isSwitchMember()) {
      statements.add(parseStatement2());
      if (identical(_currentToken, statementStart)) {
        reportErrorForToken(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken, [_currentToken.lexeme]);
        advance();
      }
      statementStart = _currentToken;
    }
    return statements;
  }

  /**
   * Parse a string literal that contains interpolations.
   *
   * @return the string literal that was parsed
   */
  StringInterpolation parseStringInterpolation(Token string) {
    List<InterpolationElement> elements = new List<InterpolationElement>();
    bool hasMore = matches(TokenType.STRING_INTERPOLATION_EXPRESSION) || matches(TokenType.STRING_INTERPOLATION_IDENTIFIER);
    elements.add(new InterpolationString(string, computeStringValue(string.lexeme, true, !hasMore)));
    while (hasMore) {
      if (matches(TokenType.STRING_INTERPOLATION_EXPRESSION)) {
        Token openToken = andAdvance;
        Expression expression = parseExpression2();
        Token rightBracket = expect(TokenType.CLOSE_CURLY_BRACKET);
        elements.add(new InterpolationExpression(openToken, expression, rightBracket));
      } else {
        Token openToken = andAdvance;
        Expression expression = null;
        if (matchesKeyword(Keyword.THIS)) {
          expression = new ThisExpression(andAdvance);
        } else {
          expression = parseSimpleIdentifier();
        }
        elements.add(new InterpolationExpression(openToken, expression, null));
      }
      if (matches(TokenType.STRING)) {
        string = andAdvance;
        hasMore = matches(TokenType.STRING_INTERPOLATION_EXPRESSION) || matches(TokenType.STRING_INTERPOLATION_IDENTIFIER);
        elements.add(new InterpolationString(string, computeStringValue(string.lexeme, false, !hasMore)));
      }
    }
    return new StringInterpolation(elements);
  }

  /**
   * Parse a super constructor invocation.
   *
   * <pre>
   * superConstructorInvocation ::=
   *     'super' ('.' identifier)? arguments
   * </pre>
   *
   * @return the super constructor invocation that was parsed
   */
  SuperConstructorInvocation parseSuperConstructorInvocation() {
    Token keyword = expectKeyword(Keyword.SUPER);
    Token period = null;
    SimpleIdentifier constructorName = null;
    if (matches(TokenType.PERIOD)) {
      period = andAdvance;
      constructorName = parseSimpleIdentifier();
    }
    ArgumentList argumentList = parseArgumentList();
    return new SuperConstructorInvocation(keyword, period, constructorName, argumentList);
  }

  /**
   * Parse a switch statement.
   *
   * <pre>
   * switchStatement ::=
   *     'switch' '(' expression ')' '{' switchCase* defaultCase? '}'
   *
   * switchCase ::=
   *     label* ('case' expression ':') statements
   *
   * defaultCase ::=
   *     label* 'default' ':' statements
   * </pre>
   *
   * @return the switch statement that was parsed
   */
  SwitchStatement parseSwitchStatement() {
    bool wasInSwitch = _inSwitch;
    _inSwitch = true;
    try {
      Set<String> definedLabels = new Set<String>();
      Token keyword = expectKeyword(Keyword.SWITCH);
      Token leftParenthesis = expect(TokenType.OPEN_PAREN);
      Expression expression = parseExpression2();
      Token rightParenthesis = expect(TokenType.CLOSE_PAREN);
      Token leftBracket = expect(TokenType.OPEN_CURLY_BRACKET);
      Token defaultKeyword = null;
      List<SwitchMember> members = new List<SwitchMember>();
      while (!matches(TokenType.EOF) && !matches(TokenType.CLOSE_CURLY_BRACKET)) {
        List<Label> labels = new List<Label>();
        while (matchesIdentifier() && tokenMatches(peek(), TokenType.COLON)) {
          SimpleIdentifier identifier = parseSimpleIdentifier();
          String label = identifier.token.lexeme;
          if (definedLabels.contains(label)) {
            reportErrorForToken(ParserErrorCode.DUPLICATE_LABEL_IN_SWITCH_STATEMENT, identifier.token, [label]);
          } else {
            definedLabels.add(label);
          }
          Token colon = expect(TokenType.COLON);
          labels.add(new Label(identifier, colon));
        }
        if (matchesKeyword(Keyword.CASE)) {
          Token caseKeyword = andAdvance;
          Expression caseExpression = parseExpression2();
          Token colon = expect(TokenType.COLON);
          members.add(new SwitchCase(labels, caseKeyword, caseExpression, colon, parseStatementList()));
          if (defaultKeyword != null) {
            reportErrorForToken(ParserErrorCode.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE, caseKeyword, []);
          }
        } else if (matchesKeyword(Keyword.DEFAULT)) {
          if (defaultKeyword != null) {
            reportErrorForToken(ParserErrorCode.SWITCH_HAS_MULTIPLE_DEFAULT_CASES, peek(), []);
          }
          defaultKeyword = andAdvance;
          Token colon = expect(TokenType.COLON);
          members.add(new SwitchDefault(labels, defaultKeyword, colon, parseStatementList()));
        } else {
          // We need to advance, otherwise we could end up in an infinite loop, but this could be a
          // lot smarter about recovering from the error.
          reportErrorForCurrentToken(ParserErrorCode.EXPECTED_CASE_OR_DEFAULT, []);
          while (!matches(TokenType.EOF) && !matches(TokenType.CLOSE_CURLY_BRACKET) && !matchesKeyword(Keyword.CASE) && !matchesKeyword(Keyword.DEFAULT)) {
            advance();
          }
        }
      }
      Token rightBracket = expect(TokenType.CLOSE_CURLY_BRACKET);
      return new SwitchStatement(keyword, leftParenthesis, expression, rightParenthesis, leftBracket, members, rightBracket);
    } finally {
      _inSwitch = wasInSwitch;
    }
  }

  /**
   * Parse a symbol literal.
   *
   * <pre>
   * symbolLiteral ::=
   *     '#' identifier ('.' identifier)*
   * </pre>
   *
   * @return the symbol literal that was parsed
   */
  SymbolLiteral parseSymbolLiteral() {
    Token poundSign = andAdvance;
    List<Token> components = new List<Token>();
    if (matchesIdentifier()) {
      components.add(andAdvance);
      while (matches(TokenType.PERIOD)) {
        advance();
        if (matchesIdentifier()) {
          components.add(andAdvance);
        } else {
          reportErrorForCurrentToken(ParserErrorCode.MISSING_IDENTIFIER, []);
          components.add(createSyntheticToken(TokenType.IDENTIFIER));
          break;
        }
      }
    } else if (_currentToken.isOperator) {
      components.add(andAdvance);
    } else {
      reportErrorForCurrentToken(ParserErrorCode.MISSING_IDENTIFIER, []);
      components.add(createSyntheticToken(TokenType.IDENTIFIER));
    }
    return new SymbolLiteral(poundSign, new List.from(components));
  }

  /**
   * Parse a throw expression.
   *
   * <pre>
   * throwExpression ::=
   *     'throw' expression
   * </pre>
   *
   * @return the throw expression that was parsed
   */
  Expression parseThrowExpression() {
    Token keyword = expectKeyword(Keyword.THROW);
    if (matches(TokenType.SEMICOLON) || matches(TokenType.CLOSE_PAREN)) {
      reportErrorForToken(ParserErrorCode.MISSING_EXPRESSION_IN_THROW, _currentToken, []);
      return new ThrowExpression(keyword, createSyntheticIdentifier());
    }
    Expression expression = parseExpression2();
    return new ThrowExpression(keyword, expression);
  }

  /**
   * Parse a throw expression.
   *
   * <pre>
   * throwExpressionWithoutCascade ::=
   *     'throw' expressionWithoutCascade
   * </pre>
   *
   * @return the throw expression that was parsed
   */
  Expression parseThrowExpressionWithoutCascade() {
    Token keyword = expectKeyword(Keyword.THROW);
    if (matches(TokenType.SEMICOLON) || matches(TokenType.CLOSE_PAREN)) {
      reportErrorForToken(ParserErrorCode.MISSING_EXPRESSION_IN_THROW, _currentToken, []);
      return new ThrowExpression(keyword, createSyntheticIdentifier());
    }
    Expression expression = parseExpressionWithoutCascade();
    return new ThrowExpression(keyword, expression);
  }

  /**
   * Parse a try statement.
   *
   * <pre>
   * tryStatement ::=
   *     'try' block (onPart+ finallyPart? | finallyPart)
   *
   * onPart ::=
   *     catchPart block
   *   | 'on' type catchPart? block
   *
   * catchPart ::=
   *     'catch' '(' identifier (',' identifier)? ')'
   *
   * finallyPart ::=
   *     'finally' block
   * </pre>
   *
   * @return the try statement that was parsed
   */
  Statement parseTryStatement() {
    Token tryKeyword = expectKeyword(Keyword.TRY);
    Block body = parseBlock();
    List<CatchClause> catchClauses = new List<CatchClause>();
    Block finallyClause = null;
    while (matchesString(_ON) || matchesKeyword(Keyword.CATCH)) {
      Token onKeyword = null;
      TypeName exceptionType = null;
      if (matchesString(_ON)) {
        onKeyword = andAdvance;
        exceptionType = parseTypeName();
      }
      Token catchKeyword = null;
      Token leftParenthesis = null;
      SimpleIdentifier exceptionParameter = null;
      Token comma = null;
      SimpleIdentifier stackTraceParameter = null;
      Token rightParenthesis = null;
      if (matchesKeyword(Keyword.CATCH)) {
        catchKeyword = andAdvance;
        leftParenthesis = expect(TokenType.OPEN_PAREN);
        exceptionParameter = parseSimpleIdentifier();
        if (matches(TokenType.COMMA)) {
          comma = andAdvance;
          stackTraceParameter = parseSimpleIdentifier();
        }
        rightParenthesis = expect(TokenType.CLOSE_PAREN);
      }
      Block catchBody = parseBlock();
      catchClauses.add(new CatchClause(onKeyword, exceptionType, catchKeyword, leftParenthesis, exceptionParameter, comma, stackTraceParameter, rightParenthesis, catchBody));
    }
    Token finallyKeyword = null;
    if (matchesKeyword(Keyword.FINALLY)) {
      finallyKeyword = andAdvance;
      finallyClause = parseBlock();
    } else {
      if (catchClauses.isEmpty) {
        reportErrorForCurrentToken(ParserErrorCode.MISSING_CATCH_OR_FINALLY, []);
      }
    }
    return new TryStatement(tryKeyword, body, catchClauses, finallyKeyword, finallyClause);
  }

  /**
   * Parse a type alias.
   *
   * <pre>
   * typeAlias ::=
   *     'typedef' typeAliasBody
   *
   * typeAliasBody ::=
   *     classTypeAlias
   *   | functionTypeAlias
   *
   * classTypeAlias ::=
   *     identifier typeParameters? '=' 'abstract'? mixinApplication
   *
   * mixinApplication ::=
   *     qualified withClause implementsClause? ';'
   *
   * functionTypeAlias ::=
   *     functionPrefix typeParameterList? formalParameterList ';'
   *
   * functionPrefix ::=
   *     returnType? name
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the member
   * @return the type alias that was parsed
   */
  TypeAlias parseTypeAlias(CommentAndMetadata commentAndMetadata) {
    Token keyword = expectKeyword(Keyword.TYPEDEF);
    if (matchesIdentifier()) {
      Token next = peek();
      if (tokenMatches(next, TokenType.LT)) {
        next = skipTypeParameterList(next);
        if (next != null && tokenMatches(next, TokenType.EQ)) {
          TypeAlias typeAlias = parseClassTypeAlias(commentAndMetadata, null, keyword);
          reportErrorForToken(ParserErrorCode.DEPRECATED_CLASS_TYPE_ALIAS, keyword, []);
          return typeAlias;
        }
      } else if (tokenMatches(next, TokenType.EQ)) {
        TypeAlias typeAlias = parseClassTypeAlias(commentAndMetadata, null, keyword);
        reportErrorForToken(ParserErrorCode.DEPRECATED_CLASS_TYPE_ALIAS, keyword, []);
        return typeAlias;
      }
    }
    return parseFunctionTypeAlias(commentAndMetadata, keyword);
  }

  /**
   * Parse a unary expression.
   *
   * <pre>
   * unaryExpression ::=
   *     prefixOperator unaryExpression
   *   | postfixExpression
   *   | unaryOperator 'super'
   *   | '-' 'super'
   *   | incrementOperator assignableExpression
   * </pre>
   *
   * @return the unary expression that was parsed
   */
  Expression parseUnaryExpression() {
    if (matches(TokenType.MINUS) || matches(TokenType.BANG) || matches(TokenType.TILDE)) {
      Token operator = andAdvance;
      if (matchesKeyword(Keyword.SUPER)) {
        if (tokenMatches(peek(), TokenType.OPEN_SQUARE_BRACKET) || tokenMatches(peek(), TokenType.PERIOD)) {
          //     "prefixOperator unaryExpression"
          // --> "prefixOperator postfixExpression"
          // --> "prefixOperator primary                    selector*"
          // --> "prefixOperator 'super' assignableSelector selector*"
          return new PrefixExpression(operator, parseUnaryExpression());
        }
        return new PrefixExpression(operator, new SuperExpression(andAdvance));
      }
      return new PrefixExpression(operator, parseUnaryExpression());
    } else if (_currentToken.type.isIncrementOperator) {
      Token operator = andAdvance;
      if (matchesKeyword(Keyword.SUPER)) {
        if (tokenMatches(peek(), TokenType.OPEN_SQUARE_BRACKET) || tokenMatches(peek(), TokenType.PERIOD)) {
          // --> "prefixOperator 'super' assignableSelector selector*"
          return new PrefixExpression(operator, parseUnaryExpression());
        }
        //
        // Even though it is not valid to use an incrementing operator ('++' or '--') before 'super',
        // we can (and therefore must) interpret "--super" as semantically equivalent to "-(-super)".
        // Unfortunately, we cannot do the same for "++super" because "+super" is also not valid.
        //
        if (identical(operator.type, TokenType.MINUS_MINUS)) {
          int offset = operator.offset;
          Token firstOperator = new Token(TokenType.MINUS, offset);
          Token secondOperator = new Token(TokenType.MINUS, offset + 1);
          secondOperator.setNext(_currentToken);
          firstOperator.setNext(secondOperator);
          operator.previous.setNext(firstOperator);
          return new PrefixExpression(firstOperator, new PrefixExpression(secondOperator, new SuperExpression(andAdvance)));
        } else {
          // Invalid operator before 'super'
          reportErrorForCurrentToken(ParserErrorCode.INVALID_OPERATOR_FOR_SUPER, [operator.lexeme]);
          return new PrefixExpression(operator, new SuperExpression(andAdvance));
        }
      }
      return new PrefixExpression(operator, parseAssignableExpression(false));
    } else if (matches(TokenType.PLUS)) {
      reportErrorForCurrentToken(ParserErrorCode.MISSING_IDENTIFIER, []);
      return createSyntheticIdentifier();
    }
    return parsePostfixExpression();
  }

  /**
   * Parse a variable declaration.
   *
   * <pre>
   * variableDeclaration ::=
   *     identifier ('=' expression)?
   * </pre>
   *
   * @return the variable declaration that was parsed
   */
  VariableDeclaration parseVariableDeclaration() {
    CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
    SimpleIdentifier name = parseSimpleIdentifier();
    Token equals = null;
    Expression initializer = null;
    if (matches(TokenType.EQ)) {
      equals = andAdvance;
      initializer = parseExpression2();
    }
    return new VariableDeclaration(commentAndMetadata.comment, commentAndMetadata.metadata, name, equals, initializer);
  }

  /**
   * Parse a variable declaration list.
   *
   * <pre>
   * variableDeclarationList ::=
   *     finalConstVarOrType variableDeclaration (',' variableDeclaration)*
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the variable declaration list
   * @return the variable declaration list that was parsed
   */
  VariableDeclarationList parseVariableDeclarationListAfterMetadata(CommentAndMetadata commentAndMetadata) {
    FinalConstVarOrType holder = parseFinalConstVarOrType(false);
    return parseVariableDeclarationListAfterType(commentAndMetadata, holder.keyword, holder.type);
  }

  /**
   * Parse a variable declaration list.
   *
   * <pre>
   * variableDeclarationList ::=
   *     finalConstVarOrType variableDeclaration (',' variableDeclaration)*
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the variable declaration list, or
   *          `null` if there is no attempt at parsing the comment and metadata
   * @param keyword the token representing the 'final', 'const' or 'var' keyword, or `null` if
   *          there is no keyword
   * @param type the type of the variables in the list
   * @return the variable declaration list that was parsed
   */
  VariableDeclarationList parseVariableDeclarationListAfterType(CommentAndMetadata commentAndMetadata, Token keyword, TypeName type) {
    if (type != null && keyword != null && tokenMatchesKeyword(keyword, Keyword.VAR)) {
      reportErrorForToken(ParserErrorCode.VAR_AND_TYPE, keyword, []);
    }
    List<VariableDeclaration> variables = new List<VariableDeclaration>();
    variables.add(parseVariableDeclaration());
    while (matches(TokenType.COMMA)) {
      advance();
      variables.add(parseVariableDeclaration());
    }
    return new VariableDeclarationList(commentAndMetadata != null ? commentAndMetadata.comment : null, commentAndMetadata != null ? commentAndMetadata.metadata : null, keyword, type, variables);
  }

  /**
   * Parse a variable declaration statement.
   *
   * <pre>
   * variableDeclarationStatement ::=
   *     variableDeclarationList ';'
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the variable declaration
   *          statement, or `null` if there is no attempt at parsing the comment and metadata
   * @return the variable declaration statement that was parsed
   */
  VariableDeclarationStatement parseVariableDeclarationStatementAfterMetadata(CommentAndMetadata commentAndMetadata) {
    //    Token startToken = currentToken;
    VariableDeclarationList variableList = parseVariableDeclarationListAfterMetadata(commentAndMetadata);
    //    if (!matches(TokenType.SEMICOLON)) {
    //      if (matches(startToken, Keyword.VAR) && isTypedIdentifier(startToken.getNext())) {
    //        // TODO(brianwilkerson) This appears to be of the form "var type variable". We should do
    //        // a better job of recovering in this case.
    //      }
    //    }
    Token semicolon = expect(TokenType.SEMICOLON);
    return new VariableDeclarationStatement(variableList, semicolon);
  }

  /**
   * Parse a variable declaration statement.
   *
   * <pre>
   * variableDeclarationStatement ::=
   *     variableDeclarationList ';'
   * </pre>
   *
   * @param commentAndMetadata the metadata to be associated with the variable declaration
   *          statement, or `null` if there is no attempt at parsing the comment and metadata
   * @param keyword the token representing the 'final', 'const' or 'var' keyword, or `null` if
   *          there is no keyword
   * @param type the type of the variables in the list
   * @return the variable declaration statement that was parsed
   */
  VariableDeclarationStatement parseVariableDeclarationStatementAfterType(CommentAndMetadata commentAndMetadata, Token keyword, TypeName type) {
    VariableDeclarationList variableList = parseVariableDeclarationListAfterType(commentAndMetadata, keyword, type);
    Token semicolon = expect(TokenType.SEMICOLON);
    return new VariableDeclarationStatement(variableList, semicolon);
  }

  /**
   * Parse a while statement.
   *
   * <pre>
   * whileStatement ::=
   *     'while' '(' expression ')' statement
   * </pre>
   *
   * @return the while statement that was parsed
   */
  Statement parseWhileStatement() {
    bool wasInLoop = _inLoop;
    _inLoop = true;
    try {
      Token keyword = expectKeyword(Keyword.WHILE);
      Token leftParenthesis = expect(TokenType.OPEN_PAREN);
      Expression condition = parseExpression2();
      Token rightParenthesis = expect(TokenType.CLOSE_PAREN);
      Statement body = parseStatement2();
      return new WhileStatement(keyword, leftParenthesis, condition, rightParenthesis, body);
    } finally {
      _inLoop = wasInLoop;
    }
  }

  /**
   * Return the token that is immediately after the current token. This is equivalent to
   * [peek].
   *
   * @return the token that is immediately after the current token
   */
  Token peek() => _currentToken.next;

  /**
   * Return the token that is the given distance after the current token.
   *
   * @param distance the number of tokens to look ahead, where `0` is the current token,
   *          `1` is the next token, etc.
   * @return the token that is the given distance after the current token
   */
  Token peek2(int distance) {
    Token token = _currentToken;
    for (int i = 0; i < distance; i++) {
      token = token.next;
    }
    return token;
  }

  /**
   * Report the given [AnalysisError].
   *
   * @param error the error to be reported
   */
  void reportError(AnalysisError error) {
    if (_errorListenerLock != 0) {
      return;
    }
    _errorListener.onError(error);
  }

  /**
   * Report an error with the given error code and arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportErrorForCurrentToken(ParserErrorCode errorCode, List<Object> arguments) {
    reportErrorForToken(errorCode, _currentToken, arguments);
  }

  /**
   * Report an error with the given error code and arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param node the node specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportErrorForNode(ParserErrorCode errorCode, AstNode node, List<Object> arguments) {
    reportError(new AnalysisError.con2(_source, node.offset, node.length, errorCode, arguments));
  }

  /**
   * Report an error with the given error code and arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param token the token specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportErrorForToken(ParserErrorCode errorCode, Token token, List<Object> arguments) {
    reportError(new AnalysisError.con2(_source, token.offset, token.length, errorCode, arguments));
  }

  /**
   * Skips a block with all containing blocks.
   */
  void skipBlock() {
    _currentToken = (_currentToken as BeginToken).endToken.next;
  }

  /**
   * Parse the 'final', 'const', 'var' or type preceding a variable declaration, starting at the
   * given token, without actually creating a type or changing the current token. Return the token
   * following the type that was parsed, or `null` if the given token is not the first token
   * in a valid type.
   *
   * <pre>
   * finalConstVarOrType ::=
   *   | 'final' type?
   *   | 'const' type?
   *   | 'var'
   *   | type
   * </pre>
   *
   * @param startToken the token at which parsing is to begin
   * @return the token following the type that was parsed
   */
  Token skipFinalConstVarOrType(Token startToken) {
    if (tokenMatchesKeyword(startToken, Keyword.FINAL) || tokenMatchesKeyword(startToken, Keyword.CONST)) {
      Token next = startToken.next;
      if (tokenMatchesIdentifier(next)) {
        Token next2 = next.next;
        // "Type parameter" or "Type<" or "prefix.Type"
        if (tokenMatchesIdentifier(next2) || tokenMatches(next2, TokenType.LT) || tokenMatches(next2, TokenType.PERIOD)) {
          return skipTypeName(next);
        }
        // "parameter"
        return next;
      }
    } else if (tokenMatchesKeyword(startToken, Keyword.VAR)) {
      return startToken.next;
    } else if (tokenMatchesIdentifier(startToken)) {
      Token next = startToken.next;
      if (tokenMatchesIdentifier(next) || tokenMatches(next, TokenType.LT) || tokenMatchesKeyword(next, Keyword.THIS) || (tokenMatches(next, TokenType.PERIOD) && tokenMatchesIdentifier(next.next) && (tokenMatchesIdentifier(next.next.next) || tokenMatches(next.next.next, TokenType.LT) || tokenMatchesKeyword(next.next.next, Keyword.THIS)))) {
        return skipReturnType(startToken);
      }
    }
    return null;
  }

  /**
   * Parse a list of formal parameters, starting at the given token, without actually creating a
   * formal parameter list or changing the current token. Return the token following the formal
   * parameter list that was parsed, or `null` if the given token is not the first token in a
   * valid list of formal parameter.
   *
   * Note that unlike other skip methods, this method uses a heuristic. In the worst case, the
   * parameters could be prefixed by metadata, which would require us to be able to skip arbitrary
   * expressions. Rather than duplicate the logic of most of the parse methods we simply look for
   * something that is likely to be a list of parameters and then skip to returning the token after
   * the closing parenthesis.
   *
   * This method must be kept in sync with [parseFormalParameterList].
   *
   * <pre>
   * formalParameterList ::=
   *     '(' ')'
   *   | '(' normalFormalParameters (',' optionalFormalParameters)? ')'
   *   | '(' optionalFormalParameters ')'
   *
   * normalFormalParameters ::=
   *     normalFormalParameter (',' normalFormalParameter)*
   *
   * optionalFormalParameters ::=
   *     optionalPositionalFormalParameters
   *   | namedFormalParameters
   *
   * optionalPositionalFormalParameters ::=
   *     '[' defaultFormalParameter (',' defaultFormalParameter)* ']'
   *
   * namedFormalParameters ::=
   *     '{' defaultNamedParameter (',' defaultNamedParameter)* '}'
   * </pre>
   *
   * @param startToken the token at which parsing is to begin
   * @return the token following the formal parameter list that was parsed
   */
  Token skipFormalParameterList(Token startToken) {
    if (!tokenMatches(startToken, TokenType.OPEN_PAREN)) {
      return null;
    }
    Token next = startToken.next;
    if (tokenMatches(next, TokenType.CLOSE_PAREN)) {
      return next.next;
    }
    //
    // Look to see whether the token after the open parenthesis is something that should only occur
    // at the beginning of a parameter list.
    //
    if (matchesAny(next, [
        TokenType.AT,
        TokenType.OPEN_SQUARE_BRACKET,
        TokenType.OPEN_CURLY_BRACKET]) || tokenMatchesKeyword(next, Keyword.VOID) || (tokenMatchesIdentifier(next) && (matchesAny(next.next, [TokenType.COMMA, TokenType.CLOSE_PAREN])))) {
      return skipPastMatchingToken(startToken);
    }
    //
    // Look to see whether the first parameter is a function typed parameter without a return type.
    //
    if (tokenMatchesIdentifier(next) && tokenMatches(next.next, TokenType.OPEN_PAREN)) {
      Token afterParameters = skipFormalParameterList(next.next);
      if (afterParameters != null && (matchesAny(afterParameters, [TokenType.COMMA, TokenType.CLOSE_PAREN]))) {
        return skipPastMatchingToken(startToken);
      }
    }
    //
    // Look to see whether the first parameter has a type or is a function typed parameter with a
    // return type.
    //
    Token afterType = skipFinalConstVarOrType(next);
    if (afterType == null) {
      return null;
    }
    if (skipSimpleIdentifier(afterType) == null) {
      return null;
    }
    return skipPastMatchingToken(startToken);
  }

  /**
   * If the given token is a begin token with an associated end token, then return the token
   * following the end token. Otherwise, return `null`.
   *
   * @param startToken the token that is assumed to be a being token
   * @return the token following the matching end token
   */
  Token skipPastMatchingToken(Token startToken) {
    if (startToken is! BeginToken) {
      return null;
    }
    Token closeParen = (startToken as BeginToken).endToken;
    if (closeParen == null) {
      return null;
    }
    return closeParen.next;
  }

  /**
   * Parse a prefixed identifier, starting at the given token, without actually creating a prefixed
   * identifier or changing the current token. Return the token following the prefixed identifier
   * that was parsed, or `null` if the given token is not the first token in a valid prefixed
   * identifier.
   *
   * This method must be kept in sync with [parsePrefixedIdentifier].
   *
   * <pre>
   * prefixedIdentifier ::=
   *     identifier ('.' identifier)?
   * </pre>
   *
   * @param startToken the token at which parsing is to begin
   * @return the token following the prefixed identifier that was parsed
   */
  Token skipPrefixedIdentifier(Token startToken) {
    Token token = skipSimpleIdentifier(startToken);
    if (token == null) {
      return null;
    } else if (!tokenMatches(token, TokenType.PERIOD)) {
      return token;
    }
    return skipSimpleIdentifier(token.next);
  }

  /**
   * Parse a return type, starting at the given token, without actually creating a return type or
   * changing the current token. Return the token following the return type that was parsed, or
   * `null` if the given token is not the first token in a valid return type.
   *
   * This method must be kept in sync with [parseReturnType].
   *
   * <pre>
   * returnType ::=
   *     'void'
   *   | type
   * </pre>
   *
   * @param startToken the token at which parsing is to begin
   * @return the token following the return type that was parsed
   */
  Token skipReturnType(Token startToken) {
    if (tokenMatchesKeyword(startToken, Keyword.VOID)) {
      return startToken.next;
    } else {
      return skipTypeName(startToken);
    }
  }

  /**
   * Parse a simple identifier, starting at the given token, without actually creating a simple
   * identifier or changing the current token. Return the token following the simple identifier that
   * was parsed, or `null` if the given token is not the first token in a valid simple
   * identifier.
   *
   * This method must be kept in sync with [parseSimpleIdentifier].
   *
   * <pre>
   * identifier ::=
   *     IDENTIFIER
   * </pre>
   *
   * @param startToken the token at which parsing is to begin
   * @return the token following the simple identifier that was parsed
   */
  Token skipSimpleIdentifier(Token startToken) {
    if (tokenMatches(startToken, TokenType.IDENTIFIER) || (tokenMatches(startToken, TokenType.KEYWORD) && (startToken as KeywordToken).keyword.isPseudoKeyword)) {
      return startToken.next;
    }
    return null;
  }

  /**
   * Parse a string literal that contains interpolations, starting at the given token, without
   * actually creating a string literal or changing the current token. Return the token following
   * the string literal that was parsed, or `null` if the given token is not the first token
   * in a valid string literal.
   *
   * This method must be kept in sync with [parseStringInterpolation].
   *
   * @param startToken the token at which parsing is to begin
   * @return the string literal that was parsed
   */
  Token skipStringInterpolation(Token startToken) {
    Token token = startToken;
    TokenType type = token.type;
    while (identical(type, TokenType.STRING_INTERPOLATION_EXPRESSION) || identical(type, TokenType.STRING_INTERPOLATION_IDENTIFIER)) {
      if (identical(type, TokenType.STRING_INTERPOLATION_EXPRESSION)) {
        token = token.next;
        type = token.type;
        //
        // Rather than verify that the following tokens represent a valid expression, we simply skip
        // tokens until we reach the end of the interpolation, being careful to handle nested string
        // literals.
        //
        int bracketNestingLevel = 1;
        while (bracketNestingLevel > 0) {
          if (identical(type, TokenType.EOF)) {
            return null;
          } else if (identical(type, TokenType.OPEN_CURLY_BRACKET)) {
            bracketNestingLevel++;
          } else if (identical(type, TokenType.CLOSE_CURLY_BRACKET)) {
            bracketNestingLevel--;
          } else if (identical(type, TokenType.STRING)) {
            token = skipStringLiteral(token);
            if (token == null) {
              return null;
            }
          } else {
            token = token.next;
          }
          type = token.type;
        }
        token = token.next;
        type = token.type;
      } else {
        token = token.next;
        if (token.type != TokenType.IDENTIFIER) {
          return null;
        }
        token = token.next;
      }
      type = token.type;
      if (identical(type, TokenType.STRING)) {
        token = token.next;
        type = token.type;
      }
    }
    return token;
  }

  /**
   * Parse a string literal, starting at the given token, without actually creating a string literal
   * or changing the current token. Return the token following the string literal that was parsed,
   * or `null` if the given token is not the first token in a valid string literal.
   *
   * This method must be kept in sync with [parseStringLiteral].
   *
   * <pre>
   * stringLiteral ::=
   *     MULTI_LINE_STRING+
   *   | SINGLE_LINE_STRING+
   * </pre>
   *
   * @param startToken the token at which parsing is to begin
   * @return the token following the string literal that was parsed
   */
  Token skipStringLiteral(Token startToken) {
    Token token = startToken;
    while (token != null && tokenMatches(token, TokenType.STRING)) {
      token = token.next;
      TokenType type = token.type;
      if (identical(type, TokenType.STRING_INTERPOLATION_EXPRESSION) || identical(type, TokenType.STRING_INTERPOLATION_IDENTIFIER)) {
        token = skipStringInterpolation(token);
      }
    }
    if (identical(token, startToken)) {
      return null;
    }
    return token;
  }

  /**
   * Parse a list of type arguments, starting at the given token, without actually creating a type argument list
   * or changing the current token. Return the token following the type argument list that was parsed,
   * or `null` if the given token is not the first token in a valid type argument list.
   *
   * This method must be kept in sync with [parseTypeArgumentList].
   *
   * <pre>
   * typeArguments ::=
   *     '<' typeList '>'
   *
   * typeList ::=
   *     type (',' type)*
   * </pre>
   *
   * @param startToken the token at which parsing is to begin
   * @return the token following the type argument list that was parsed
   */
  Token skipTypeArgumentList(Token startToken) {
    Token token = startToken;
    if (!tokenMatches(token, TokenType.LT)) {
      return null;
    }
    token = skipTypeName(token.next);
    if (token == null) {
      return null;
    }
    while (tokenMatches(token, TokenType.COMMA)) {
      token = skipTypeName(token.next);
      if (token == null) {
        return null;
      }
    }
    if (identical(token.type, TokenType.GT)) {
      return token.next;
    } else if (identical(token.type, TokenType.GT_GT)) {
      Token second = new Token(TokenType.GT, token.offset + 1);
      second.setNextWithoutSettingPrevious(token.next);
      return second;
    }
    return null;
  }

  /**
   * Parse a type name, starting at the given token, without actually creating a type name or
   * changing the current token. Return the token following the type name that was parsed, or
   * `null` if the given token is not the first token in a valid type name.
   *
   * This method must be kept in sync with [parseTypeName].
   *
   * <pre>
   * type ::=
   *     qualified typeArguments?
   * </pre>
   *
   * @param startToken the token at which parsing is to begin
   * @return the token following the type name that was parsed
   */
  Token skipTypeName(Token startToken) {
    Token token = skipPrefixedIdentifier(startToken);
    if (token == null) {
      return null;
    }
    if (tokenMatches(token, TokenType.LT)) {
      token = skipTypeArgumentList(token);
    }
    return token;
  }

  /**
   * Parse a list of type parameters, starting at the given token, without actually creating a type
   * parameter list or changing the current token. Return the token following the type parameter
   * list that was parsed, or `null` if the given token is not the first token in a valid type
   * parameter list.
   *
   * This method must be kept in sync with [parseTypeParameterList].
   *
   * <pre>
   * typeParameterList ::=
   *     '<' typeParameter (',' typeParameter)* '>'
   * </pre>
   *
   * @param startToken the token at which parsing is to begin
   * @return the token following the type parameter list that was parsed
   */
  Token skipTypeParameterList(Token startToken) {
    if (!tokenMatches(startToken, TokenType.LT)) {
      return null;
    }
    //
    // We can't skip a type parameter because it can be preceeded by metadata, so we just assume
    // that everything before the matching end token is valid.
    //
    int depth = 1;
    Token next = startToken.next;
    while (depth > 0) {
      if (tokenMatches(next, TokenType.EOF)) {
        return null;
      } else if (tokenMatches(next, TokenType.LT)) {
        depth++;
      } else if (tokenMatches(next, TokenType.GT)) {
        depth--;
      } else if (tokenMatches(next, TokenType.GT_EQ)) {
        if (depth == 1) {
          Token fakeEquals = new Token(TokenType.EQ, next.offset + 2);
          fakeEquals.setNextWithoutSettingPrevious(next.next);
          return fakeEquals;
        }
        depth--;
      } else if (tokenMatches(next, TokenType.GT_GT)) {
        depth -= 2;
      } else if (tokenMatches(next, TokenType.GT_GT_EQ)) {
        if (depth < 2) {
          return null;
        } else if (depth == 2) {
          Token fakeEquals = new Token(TokenType.EQ, next.offset + 2);
          fakeEquals.setNextWithoutSettingPrevious(next.next);
          return fakeEquals;
        }
        depth -= 2;
      }
      next = next.next;
    }
    return next;
  }

  /**
   * Return `true` if the given token has the given type.
   *
   * @param token the token being tested
   * @param type the type of token that is being tested for
   * @return `true` if the given token has the given type
   */
  bool tokenMatches(Token token, TokenType type) => identical(token.type, type);

  /**
   * Return `true` if the given token is a valid identifier. Valid identifiers include
   * built-in identifiers (pseudo-keywords).
   *
   * @return `true` if the given token is a valid identifier
   */
  bool tokenMatchesIdentifier(Token token) => tokenMatches(token, TokenType.IDENTIFIER) || (tokenMatches(token, TokenType.KEYWORD) && (token as KeywordToken).keyword.isPseudoKeyword);

  /**
   * Return `true` if the given token matches the given keyword.
   *
   * @param token the token being tested
   * @param keyword the keyword that is being tested for
   * @return `true` if the given token matches the given keyword
   */
  bool tokenMatchesKeyword(Token token, Keyword keyword) => identical(token.type, TokenType.KEYWORD) && identical((token as KeywordToken).keyword, keyword);

  /**
   * Translate the characters at the given index in the given string, appending the translated
   * character to the given builder. The index is assumed to be valid.
   *
   * @param builder the builder to which the translated character is to be appended
   * @param lexeme the string containing the character(s) to be translated
   * @param index the index of the character to be translated
   * @return the index of the next character to be translated
   */
  int translateCharacter(JavaStringBuilder builder, String lexeme, int index) {
    int currentChar = lexeme.codeUnitAt(index);
    if (currentChar != 0x5C) {
      builder.appendChar(currentChar);
      return index + 1;
    }
    //
    // We have found an escape sequence, so we parse the string to determine what kind of escape
    // sequence and what character to add to the builder.
    //
    int length = lexeme.length;
    int currentIndex = index + 1;
    if (currentIndex >= length) {
      // Illegal escape sequence: no char after escape
      // This cannot actually happen because it would require the escape character to be the last
      // character in the string, but if it were it would escape the closing quote, leaving the
      // string unclosed.
      // reportError(ParserErrorCode.MISSING_CHAR_IN_ESCAPE_SEQUENCE);
      return length;
    }
    currentChar = lexeme.codeUnitAt(currentIndex);
    if (currentChar == 0x6E) {
      builder.appendChar(0xA);
    } else if (currentChar == 0x72) {
      builder.appendChar(0xD);
    } else if (currentChar == 0x66) {
      builder.appendChar(0xC);
    } else if (currentChar == 0x62) {
      builder.appendChar(0x8);
    } else if (currentChar == 0x74) {
      builder.appendChar(0x9);
    } else if (currentChar == 0x76) {
      builder.appendChar(0xB);
    } else if (currentChar == 0x78) {
      if (currentIndex + 2 >= length) {
        // Illegal escape sequence: not enough hex digits
        reportErrorForCurrentToken(ParserErrorCode.INVALID_HEX_ESCAPE, []);
        return length;
      }
      int firstDigit = lexeme.codeUnitAt(currentIndex + 1);
      int secondDigit = lexeme.codeUnitAt(currentIndex + 2);
      if (!isHexDigit(firstDigit) || !isHexDigit(secondDigit)) {
        // Illegal escape sequence: invalid hex digit
        reportErrorForCurrentToken(ParserErrorCode.INVALID_HEX_ESCAPE, []);
      } else {
        builder.appendChar(((Character.digit(firstDigit, 16) << 4) + Character.digit(secondDigit, 16)));
      }
      return currentIndex + 3;
    } else if (currentChar == 0x75) {
      currentIndex++;
      if (currentIndex >= length) {
        // Illegal escape sequence: not enough hex digits
        reportErrorForCurrentToken(ParserErrorCode.INVALID_UNICODE_ESCAPE, []);
        return length;
      }
      currentChar = lexeme.codeUnitAt(currentIndex);
      if (currentChar == 0x7B) {
        currentIndex++;
        if (currentIndex >= length) {
          // Illegal escape sequence: incomplete escape
          reportErrorForCurrentToken(ParserErrorCode.INVALID_UNICODE_ESCAPE, []);
          return length;
        }
        currentChar = lexeme.codeUnitAt(currentIndex);
        int digitCount = 0;
        int value = 0;
        while (currentChar != 0x7D) {
          if (!isHexDigit(currentChar)) {
            // Illegal escape sequence: invalid hex digit
            reportErrorForCurrentToken(ParserErrorCode.INVALID_UNICODE_ESCAPE, []);
            currentIndex++;
            while (currentIndex < length && lexeme.codeUnitAt(currentIndex) != 0x7D) {
              currentIndex++;
            }
            return currentIndex + 1;
          }
          digitCount++;
          value = (value << 4) + Character.digit(currentChar, 16);
          currentIndex++;
          if (currentIndex >= length) {
            // Illegal escape sequence: incomplete escape
            reportErrorForCurrentToken(ParserErrorCode.INVALID_UNICODE_ESCAPE, []);
            return length;
          }
          currentChar = lexeme.codeUnitAt(currentIndex);
        }
        if (digitCount < 1 || digitCount > 6) {
          // Illegal escape sequence: not enough or too many hex digits
          reportErrorForCurrentToken(ParserErrorCode.INVALID_UNICODE_ESCAPE, []);
        }
        appendScalarValue(builder, lexeme.substring(index, currentIndex + 1), value, index, currentIndex);
        return currentIndex + 1;
      } else {
        if (currentIndex + 3 >= length) {
          // Illegal escape sequence: not enough hex digits
          reportErrorForCurrentToken(ParserErrorCode.INVALID_UNICODE_ESCAPE, []);
          return length;
        }
        int firstDigit = currentChar;
        int secondDigit = lexeme.codeUnitAt(currentIndex + 1);
        int thirdDigit = lexeme.codeUnitAt(currentIndex + 2);
        int fourthDigit = lexeme.codeUnitAt(currentIndex + 3);
        if (!isHexDigit(firstDigit) || !isHexDigit(secondDigit) || !isHexDigit(thirdDigit) || !isHexDigit(fourthDigit)) {
          // Illegal escape sequence: invalid hex digits
          reportErrorForCurrentToken(ParserErrorCode.INVALID_UNICODE_ESCAPE, []);
        } else {
          appendScalarValue(builder, lexeme.substring(index, currentIndex + 1), (((((Character.digit(firstDigit, 16) << 4) + Character.digit(secondDigit, 16)) << 4) + Character.digit(thirdDigit, 16)) << 4) + Character.digit(fourthDigit, 16), index, currentIndex + 3);
        }
        return currentIndex + 4;
      }
    } else {
      builder.appendChar(currentChar);
    }
    return currentIndex + 1;
  }

  /**
   * Decrements the error reporting lock level. If level is more than `0`, then
   * [reportError] wont report any error.
   */
  void unlockErrorListener() {
    if (_errorListenerLock == 0) {
      throw new IllegalStateException("Attempt to unlock not locked error listener.");
    }
    _errorListenerLock--;
  }

  /**
   * Validate that the given parameter list does not contain any field initializers.
   *
   * @param parameterList the parameter list to be validated
   */
  void validateFormalParameterList(FormalParameterList parameterList) {
    for (FormalParameter parameter in parameterList.parameters) {
      if (parameter is FieldFormalParameter) {
        reportErrorForNode(ParserErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, parameter.identifier, []);
      }
    }
  }

  /**
   * Validate that the given set of modifiers is appropriate for a class and return the 'abstract'
   * keyword if there is one.
   *
   * @param modifiers the modifiers being validated
   */
  Token validateModifiersForClass(Modifiers modifiers) {
    validateModifiersForTopLevelDeclaration(modifiers);
    if (modifiers.constKeyword != null) {
      reportErrorForToken(ParserErrorCode.CONST_CLASS, modifiers.constKeyword, []);
    }
    if (modifiers.externalKeyword != null) {
      reportErrorForToken(ParserErrorCode.EXTERNAL_CLASS, modifiers.externalKeyword, []);
    }
    if (modifiers.finalKeyword != null) {
      reportErrorForToken(ParserErrorCode.FINAL_CLASS, modifiers.finalKeyword, []);
    }
    if (modifiers.varKeyword != null) {
      reportErrorForToken(ParserErrorCode.VAR_CLASS, modifiers.varKeyword, []);
    }
    return modifiers.abstractKeyword;
  }

  /**
   * Validate that the given set of modifiers is appropriate for a constructor and return the
   * 'const' keyword if there is one.
   *
   * @param modifiers the modifiers being validated
   * @return the 'const' or 'final' keyword associated with the constructor
   */
  Token validateModifiersForConstructor(Modifiers modifiers) {
    if (modifiers.abstractKeyword != null) {
      reportErrorForToken(ParserErrorCode.ABSTRACT_CLASS_MEMBER, modifiers.abstractKeyword, []);
    }
    if (modifiers.finalKeyword != null) {
      reportErrorForToken(ParserErrorCode.FINAL_CONSTRUCTOR, modifiers.finalKeyword, []);
    }
    if (modifiers.staticKeyword != null) {
      reportErrorForToken(ParserErrorCode.STATIC_CONSTRUCTOR, modifiers.staticKeyword, []);
    }
    if (modifiers.varKeyword != null) {
      reportErrorForToken(ParserErrorCode.CONSTRUCTOR_WITH_RETURN_TYPE, modifiers.varKeyword, []);
    }
    Token externalKeyword = modifiers.externalKeyword;
    Token constKeyword = modifiers.constKeyword;
    Token factoryKeyword = modifiers.factoryKeyword;
    if (externalKeyword != null && constKeyword != null && constKeyword.offset < externalKeyword.offset) {
      reportErrorForToken(ParserErrorCode.EXTERNAL_AFTER_CONST, externalKeyword, []);
    }
    if (externalKeyword != null && factoryKeyword != null && factoryKeyword.offset < externalKeyword.offset) {
      reportErrorForToken(ParserErrorCode.EXTERNAL_AFTER_FACTORY, externalKeyword, []);
    }
    return constKeyword;
  }

  /**
   * Validate that the given set of modifiers is appropriate for a field and return the 'final',
   * 'const' or 'var' keyword if there is one.
   *
   * @param modifiers the modifiers being validated
   * @return the 'final', 'const' or 'var' keyword associated with the field
   */
  Token validateModifiersForField(Modifiers modifiers) {
    if (modifiers.abstractKeyword != null) {
      reportErrorForCurrentToken(ParserErrorCode.ABSTRACT_CLASS_MEMBER, []);
    }
    if (modifiers.externalKeyword != null) {
      reportErrorForToken(ParserErrorCode.EXTERNAL_FIELD, modifiers.externalKeyword, []);
    }
    if (modifiers.factoryKeyword != null) {
      reportErrorForToken(ParserErrorCode.NON_CONSTRUCTOR_FACTORY, modifiers.factoryKeyword, []);
    }
    Token staticKeyword = modifiers.staticKeyword;
    Token constKeyword = modifiers.constKeyword;
    Token finalKeyword = modifiers.finalKeyword;
    Token varKeyword = modifiers.varKeyword;
    if (constKeyword != null) {
      if (finalKeyword != null) {
        reportErrorForToken(ParserErrorCode.CONST_AND_FINAL, finalKeyword, []);
      }
      if (varKeyword != null) {
        reportErrorForToken(ParserErrorCode.CONST_AND_VAR, varKeyword, []);
      }
      if (staticKeyword != null && constKeyword.offset < staticKeyword.offset) {
        reportErrorForToken(ParserErrorCode.STATIC_AFTER_CONST, staticKeyword, []);
      }
    } else if (finalKeyword != null) {
      if (varKeyword != null) {
        reportErrorForToken(ParserErrorCode.FINAL_AND_VAR, varKeyword, []);
      }
      if (staticKeyword != null && finalKeyword.offset < staticKeyword.offset) {
        reportErrorForToken(ParserErrorCode.STATIC_AFTER_FINAL, staticKeyword, []);
      }
    } else if (varKeyword != null && staticKeyword != null && varKeyword.offset < staticKeyword.offset) {
      reportErrorForToken(ParserErrorCode.STATIC_AFTER_VAR, staticKeyword, []);
    }
    return lexicallyFirst([constKeyword, finalKeyword, varKeyword]);
  }

  /**
   * Validate that the given set of modifiers is appropriate for a local function.
   *
   * @param modifiers the modifiers being validated
   */
  void validateModifiersForFunctionDeclarationStatement(Modifiers modifiers) {
    if (modifiers.abstractKeyword != null || modifiers.constKeyword != null || modifiers.externalKeyword != null || modifiers.factoryKeyword != null || modifiers.finalKeyword != null || modifiers.staticKeyword != null || modifiers.varKeyword != null) {
      reportErrorForCurrentToken(ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER, []);
    }
  }

  /**
   * Validate that the given set of modifiers is appropriate for a getter, setter, or method.
   *
   * @param modifiers the modifiers being validated
   */
  void validateModifiersForGetterOrSetterOrMethod(Modifiers modifiers) {
    if (modifiers.abstractKeyword != null) {
      reportErrorForCurrentToken(ParserErrorCode.ABSTRACT_CLASS_MEMBER, []);
    }
    if (modifiers.constKeyword != null) {
      reportErrorForToken(ParserErrorCode.CONST_METHOD, modifiers.constKeyword, []);
    }
    if (modifiers.factoryKeyword != null) {
      reportErrorForToken(ParserErrorCode.NON_CONSTRUCTOR_FACTORY, modifiers.factoryKeyword, []);
    }
    if (modifiers.finalKeyword != null) {
      reportErrorForToken(ParserErrorCode.FINAL_METHOD, modifiers.finalKeyword, []);
    }
    if (modifiers.varKeyword != null) {
      reportErrorForToken(ParserErrorCode.VAR_RETURN_TYPE, modifiers.varKeyword, []);
    }
    Token externalKeyword = modifiers.externalKeyword;
    Token staticKeyword = modifiers.staticKeyword;
    if (externalKeyword != null && staticKeyword != null && staticKeyword.offset < externalKeyword.offset) {
      reportErrorForToken(ParserErrorCode.EXTERNAL_AFTER_STATIC, externalKeyword, []);
    }
  }

  /**
   * Validate that the given set of modifiers is appropriate for a getter, setter, or method.
   *
   * @param modifiers the modifiers being validated
   */
  void validateModifiersForOperator(Modifiers modifiers) {
    if (modifiers.abstractKeyword != null) {
      reportErrorForCurrentToken(ParserErrorCode.ABSTRACT_CLASS_MEMBER, []);
    }
    if (modifiers.constKeyword != null) {
      reportErrorForToken(ParserErrorCode.CONST_METHOD, modifiers.constKeyword, []);
    }
    if (modifiers.factoryKeyword != null) {
      reportErrorForToken(ParserErrorCode.NON_CONSTRUCTOR_FACTORY, modifiers.factoryKeyword, []);
    }
    if (modifiers.finalKeyword != null) {
      reportErrorForToken(ParserErrorCode.FINAL_METHOD, modifiers.finalKeyword, []);
    }
    if (modifiers.staticKeyword != null) {
      reportErrorForToken(ParserErrorCode.STATIC_OPERATOR, modifiers.staticKeyword, []);
    }
    if (modifiers.varKeyword != null) {
      reportErrorForToken(ParserErrorCode.VAR_RETURN_TYPE, modifiers.varKeyword, []);
    }
  }

  /**
   * Validate that the given set of modifiers is appropriate for a top-level declaration.
   *
   * @param modifiers the modifiers being validated
   */
  void validateModifiersForTopLevelDeclaration(Modifiers modifiers) {
    if (modifiers.factoryKeyword != null) {
      reportErrorForToken(ParserErrorCode.FACTORY_TOP_LEVEL_DECLARATION, modifiers.factoryKeyword, []);
    }
    if (modifiers.staticKeyword != null) {
      reportErrorForToken(ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION, modifiers.staticKeyword, []);
    }
  }

  /**
   * Validate that the given set of modifiers is appropriate for a top-level function.
   *
   * @param modifiers the modifiers being validated
   */
  void validateModifiersForTopLevelFunction(Modifiers modifiers) {
    validateModifiersForTopLevelDeclaration(modifiers);
    if (modifiers.abstractKeyword != null) {
      reportErrorForCurrentToken(ParserErrorCode.ABSTRACT_TOP_LEVEL_FUNCTION, []);
    }
    if (modifiers.constKeyword != null) {
      reportErrorForToken(ParserErrorCode.CONST_CLASS, modifiers.constKeyword, []);
    }
    if (modifiers.finalKeyword != null) {
      reportErrorForToken(ParserErrorCode.FINAL_CLASS, modifiers.finalKeyword, []);
    }
    if (modifiers.varKeyword != null) {
      reportErrorForToken(ParserErrorCode.VAR_RETURN_TYPE, modifiers.varKeyword, []);
    }
  }

  /**
   * Validate that the given set of modifiers is appropriate for a field and return the 'final',
   * 'const' or 'var' keyword if there is one.
   *
   * @param modifiers the modifiers being validated
   * @return the 'final', 'const' or 'var' keyword associated with the field
   */
  Token validateModifiersForTopLevelVariable(Modifiers modifiers) {
    validateModifiersForTopLevelDeclaration(modifiers);
    if (modifiers.abstractKeyword != null) {
      reportErrorForCurrentToken(ParserErrorCode.ABSTRACT_TOP_LEVEL_VARIABLE, []);
    }
    if (modifiers.externalKeyword != null) {
      reportErrorForToken(ParserErrorCode.EXTERNAL_FIELD, modifiers.externalKeyword, []);
    }
    Token constKeyword = modifiers.constKeyword;
    Token finalKeyword = modifiers.finalKeyword;
    Token varKeyword = modifiers.varKeyword;
    if (constKeyword != null) {
      if (finalKeyword != null) {
        reportErrorForToken(ParserErrorCode.CONST_AND_FINAL, finalKeyword, []);
      }
      if (varKeyword != null) {
        reportErrorForToken(ParserErrorCode.CONST_AND_VAR, varKeyword, []);
      }
    } else if (finalKeyword != null) {
      if (varKeyword != null) {
        reportErrorForToken(ParserErrorCode.FINAL_AND_VAR, varKeyword, []);
      }
    }
    return lexicallyFirst([constKeyword, finalKeyword, varKeyword]);
  }

  /**
   * Validate that the given set of modifiers is appropriate for a class and return the 'abstract'
   * keyword if there is one.
   *
   * @param modifiers the modifiers being validated
   */
  void validateModifiersForTypedef(Modifiers modifiers) {
    validateModifiersForTopLevelDeclaration(modifiers);
    if (modifiers.abstractKeyword != null) {
      reportErrorForToken(ParserErrorCode.ABSTRACT_TYPEDEF, modifiers.abstractKeyword, []);
    }
    if (modifiers.constKeyword != null) {
      reportErrorForToken(ParserErrorCode.CONST_TYPEDEF, modifiers.constKeyword, []);
    }
    if (modifiers.externalKeyword != null) {
      reportErrorForToken(ParserErrorCode.EXTERNAL_TYPEDEF, modifiers.externalKeyword, []);
    }
    if (modifiers.finalKeyword != null) {
      reportErrorForToken(ParserErrorCode.FINAL_TYPEDEF, modifiers.finalKeyword, []);
    }
    if (modifiers.varKeyword != null) {
      reportErrorForToken(ParserErrorCode.VAR_TYPEDEF, modifiers.varKeyword, []);
    }
  }
}

/**
 * Instances of the class `SyntheticKeywordToken` implement a synthetic keyword token.
 */
class Parser_SyntheticKeywordToken extends KeywordToken {
  /**
   * Initialize a newly created token to represent the given keyword.
   *
   * @param keyword the keyword being represented by this token
   * @param offset the offset from the beginning of the file to the first character in the token
   */
  Parser_SyntheticKeywordToken(Keyword keyword, int offset) : super(keyword, offset);

  Token copy() => new Parser_SyntheticKeywordToken(keyword, offset);

  int get length => 0;
}

/**
 * The enumeration `ParserErrorCode` defines the error codes used for errors detected by the
 * parser. The convention for this class is for the name of the error code to indicate the problem
 * that caused the error to be generated and for the error message to explain what is wrong and,
 * when appropriate, how the problem can be corrected.
 */
class ParserErrorCode extends Enum<ParserErrorCode> implements ErrorCode {
  static final ParserErrorCode ABSTRACT_CLASS_MEMBER = new ParserErrorCode.con3('ABSTRACT_CLASS_MEMBER', 0, "Members of classes cannot be declared to be 'abstract'");

  static final ParserErrorCode ABSTRACT_STATIC_METHOD = new ParserErrorCode.con3('ABSTRACT_STATIC_METHOD', 1, "Static methods cannot be declared to be 'abstract'");

  static final ParserErrorCode ABSTRACT_TOP_LEVEL_FUNCTION = new ParserErrorCode.con3('ABSTRACT_TOP_LEVEL_FUNCTION', 2, "Top-level functions cannot be declared to be 'abstract'");

  static final ParserErrorCode ABSTRACT_TOP_LEVEL_VARIABLE = new ParserErrorCode.con3('ABSTRACT_TOP_LEVEL_VARIABLE', 3, "Top-level variables cannot be declared to be 'abstract'");

  static final ParserErrorCode ABSTRACT_TYPEDEF = new ParserErrorCode.con3('ABSTRACT_TYPEDEF', 4, "Type aliases cannot be declared to be 'abstract'");

  static final ParserErrorCode ASSERT_DOES_NOT_TAKE_ASSIGNMENT = new ParserErrorCode.con3('ASSERT_DOES_NOT_TAKE_ASSIGNMENT', 5, "Assert cannot be called on an assignment");

  static final ParserErrorCode ASSERT_DOES_NOT_TAKE_CASCADE = new ParserErrorCode.con3('ASSERT_DOES_NOT_TAKE_CASCADE', 6, "Assert cannot be called on cascade");

  static final ParserErrorCode ASSERT_DOES_NOT_TAKE_THROW = new ParserErrorCode.con3('ASSERT_DOES_NOT_TAKE_THROW', 7, "Assert cannot be called on throws");

  static final ParserErrorCode ASSERT_DOES_NOT_TAKE_RETHROW = new ParserErrorCode.con3('ASSERT_DOES_NOT_TAKE_RETHROW', 8, "Assert cannot be called on rethrows");

  static final ParserErrorCode BREAK_OUTSIDE_OF_LOOP = new ParserErrorCode.con3('BREAK_OUTSIDE_OF_LOOP', 9, "A break statement cannot be used outside of a loop or switch statement");

  static final ParserErrorCode CONST_AND_FINAL = new ParserErrorCode.con3('CONST_AND_FINAL', 10, "Members cannot be declared to be both 'const' and 'final'");

  static final ParserErrorCode CONST_AND_VAR = new ParserErrorCode.con3('CONST_AND_VAR', 11, "Members cannot be declared to be both 'const' and 'var'");

  static final ParserErrorCode CONST_CLASS = new ParserErrorCode.con3('CONST_CLASS', 12, "Classes cannot be declared to be 'const'");

  static final ParserErrorCode CONST_CONSTRUCTOR_WITH_BODY = new ParserErrorCode.con3('CONST_CONSTRUCTOR_WITH_BODY', 13, "'const' constructors cannot have a body");

  static final ParserErrorCode CONST_FACTORY = new ParserErrorCode.con3('CONST_FACTORY', 14, "Only redirecting factory constructors can be declared to be 'const'");

  static final ParserErrorCode CONST_METHOD = new ParserErrorCode.con3('CONST_METHOD', 15, "Getters, setters and methods cannot be declared to be 'const'");

  static final ParserErrorCode CONST_TYPEDEF = new ParserErrorCode.con3('CONST_TYPEDEF', 16, "Type aliases cannot be declared to be 'const'");

  static final ParserErrorCode CONSTRUCTOR_WITH_RETURN_TYPE = new ParserErrorCode.con3('CONSTRUCTOR_WITH_RETURN_TYPE', 17, "Constructors cannot have a return type");

  static final ParserErrorCode CONTINUE_OUTSIDE_OF_LOOP = new ParserErrorCode.con3('CONTINUE_OUTSIDE_OF_LOOP', 18, "A continue statement cannot be used outside of a loop or switch statement");

  static final ParserErrorCode CONTINUE_WITHOUT_LABEL_IN_CASE = new ParserErrorCode.con3('CONTINUE_WITHOUT_LABEL_IN_CASE', 19, "A continue statement in a switch statement must have a label as a target");

  static final ParserErrorCode DEPRECATED_ARGUMENT_DEFINITION_TEST = new ParserErrorCode.con3('DEPRECATED_ARGUMENT_DEFINITION_TEST', 20, "The argument definition test ('?' operator) has been deprecated");

  static final ParserErrorCode DEPRECATED_CLASS_TYPE_ALIAS = new ParserErrorCode.con3('DEPRECATED_CLASS_TYPE_ALIAS', 21, "The 'typedef' mixin application was replaced with 'class'");

  static final ParserErrorCode DIRECTIVE_AFTER_DECLARATION = new ParserErrorCode.con3('DIRECTIVE_AFTER_DECLARATION', 22, "Directives must appear before any declarations");

  static final ParserErrorCode DUPLICATE_LABEL_IN_SWITCH_STATEMENT = new ParserErrorCode.con3('DUPLICATE_LABEL_IN_SWITCH_STATEMENT', 23, "The label %s was already used in this switch statement");

  static final ParserErrorCode DUPLICATED_MODIFIER = new ParserErrorCode.con3('DUPLICATED_MODIFIER', 24, "The modifier '%s' was already specified.");

  static final ParserErrorCode EQUALITY_CANNOT_BE_EQUALITY_OPERAND = new ParserErrorCode.con3('EQUALITY_CANNOT_BE_EQUALITY_OPERAND', 25, "Equality expression cannot be operand of another equality expression.");

  static final ParserErrorCode EXPECTED_CASE_OR_DEFAULT = new ParserErrorCode.con3('EXPECTED_CASE_OR_DEFAULT', 26, "Expected 'case' or 'default'");

  static final ParserErrorCode EXPECTED_CLASS_MEMBER = new ParserErrorCode.con3('EXPECTED_CLASS_MEMBER', 27, "Expected a class member");

  static final ParserErrorCode EXPECTED_EXECUTABLE = new ParserErrorCode.con3('EXPECTED_EXECUTABLE', 28, "Expected a method, getter, setter or operator declaration");

  static final ParserErrorCode EXPECTED_LIST_OR_MAP_LITERAL = new ParserErrorCode.con3('EXPECTED_LIST_OR_MAP_LITERAL', 29, "Expected a list or map literal");

  static final ParserErrorCode EXPECTED_STRING_LITERAL = new ParserErrorCode.con3('EXPECTED_STRING_LITERAL', 30, "Expected a string literal");

  static final ParserErrorCode EXPECTED_TOKEN = new ParserErrorCode.con3('EXPECTED_TOKEN', 31, "Expected to find '%s'");

  static final ParserErrorCode EXPECTED_TYPE_NAME = new ParserErrorCode.con3('EXPECTED_TYPE_NAME', 32, "Expected a type name");

  static final ParserErrorCode EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE = new ParserErrorCode.con3('EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE', 33, "Export directives must preceed part directives");

  static final ParserErrorCode EXTERNAL_AFTER_CONST = new ParserErrorCode.con3('EXTERNAL_AFTER_CONST', 34, "The modifier 'external' should be before the modifier 'const'");

  static final ParserErrorCode EXTERNAL_AFTER_FACTORY = new ParserErrorCode.con3('EXTERNAL_AFTER_FACTORY', 35, "The modifier 'external' should be before the modifier 'factory'");

  static final ParserErrorCode EXTERNAL_AFTER_STATIC = new ParserErrorCode.con3('EXTERNAL_AFTER_STATIC', 36, "The modifier 'external' should be before the modifier 'static'");

  static final ParserErrorCode EXTERNAL_CLASS = new ParserErrorCode.con3('EXTERNAL_CLASS', 37, "Classes cannot be declared to be 'external'");

  static final ParserErrorCode EXTERNAL_CONSTRUCTOR_WITH_BODY = new ParserErrorCode.con3('EXTERNAL_CONSTRUCTOR_WITH_BODY', 38, "External constructors cannot have a body");

  static final ParserErrorCode EXTERNAL_FIELD = new ParserErrorCode.con3('EXTERNAL_FIELD', 39, "Fields cannot be declared to be 'external'");

  static final ParserErrorCode EXTERNAL_GETTER_WITH_BODY = new ParserErrorCode.con3('EXTERNAL_GETTER_WITH_BODY', 40, "External getters cannot have a body");

  static final ParserErrorCode EXTERNAL_METHOD_WITH_BODY = new ParserErrorCode.con3('EXTERNAL_METHOD_WITH_BODY', 41, "External methods cannot have a body");

  static final ParserErrorCode EXTERNAL_OPERATOR_WITH_BODY = new ParserErrorCode.con3('EXTERNAL_OPERATOR_WITH_BODY', 42, "External operators cannot have a body");

  static final ParserErrorCode EXTERNAL_SETTER_WITH_BODY = new ParserErrorCode.con3('EXTERNAL_SETTER_WITH_BODY', 43, "External setters cannot have a body");

  static final ParserErrorCode EXTERNAL_TYPEDEF = new ParserErrorCode.con3('EXTERNAL_TYPEDEF', 44, "Type aliases cannot be declared to be 'external'");

  static final ParserErrorCode FACTORY_TOP_LEVEL_DECLARATION = new ParserErrorCode.con3('FACTORY_TOP_LEVEL_DECLARATION', 45, "Top-level declarations cannot be declared to be 'factory'");

  static final ParserErrorCode FACTORY_WITHOUT_BODY = new ParserErrorCode.con3('FACTORY_WITHOUT_BODY', 46, "A non-redirecting 'factory' constructor must have a body");

  static final ParserErrorCode FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR = new ParserErrorCode.con3('FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR', 47, "Field initializers can only be used in a constructor");

  static final ParserErrorCode FINAL_AND_VAR = new ParserErrorCode.con3('FINAL_AND_VAR', 48, "Members cannot be declared to be both 'final' and 'var'");

  static final ParserErrorCode FINAL_CLASS = new ParserErrorCode.con3('FINAL_CLASS', 49, "Classes cannot be declared to be 'final'");

  static final ParserErrorCode FINAL_CONSTRUCTOR = new ParserErrorCode.con3('FINAL_CONSTRUCTOR', 50, "A constructor cannot be declared to be 'final'");

  static final ParserErrorCode FINAL_METHOD = new ParserErrorCode.con3('FINAL_METHOD', 51, "Getters, setters and methods cannot be declared to be 'final'");

  static final ParserErrorCode FINAL_TYPEDEF = new ParserErrorCode.con3('FINAL_TYPEDEF', 52, "Type aliases cannot be declared to be 'final'");

  static final ParserErrorCode FUNCTION_TYPED_PARAMETER_VAR = new ParserErrorCode.con3('FUNCTION_TYPED_PARAMETER_VAR', 53, "Function typed parameters cannot specify 'const', 'final' or 'var' instead of return type");

  static final ParserErrorCode GETTER_IN_FUNCTION = new ParserErrorCode.con3('GETTER_IN_FUNCTION', 54, "Getters cannot be defined within methods or functions");

  static final ParserErrorCode GETTER_WITH_PARAMETERS = new ParserErrorCode.con3('GETTER_WITH_PARAMETERS', 55, "Getter should be declared without a parameter list");

  static final ParserErrorCode ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE = new ParserErrorCode.con3('ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE', 56, "Illegal assignment to non-assignable expression");

  static final ParserErrorCode IMPLEMENTS_BEFORE_EXTENDS = new ParserErrorCode.con3('IMPLEMENTS_BEFORE_EXTENDS', 57, "The extends clause must be before the implements clause");

  static final ParserErrorCode IMPLEMENTS_BEFORE_WITH = new ParserErrorCode.con3('IMPLEMENTS_BEFORE_WITH', 58, "The with clause must be before the implements clause");

  static final ParserErrorCode IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE = new ParserErrorCode.con3('IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE', 59, "Import directives must preceed part directives");

  static final ParserErrorCode INITIALIZED_VARIABLE_IN_FOR_EACH = new ParserErrorCode.con3('INITIALIZED_VARIABLE_IN_FOR_EACH', 60, "The loop variable in a for-each loop cannot be initialized");

  static final ParserErrorCode INVALID_CODE_POINT = new ParserErrorCode.con3('INVALID_CODE_POINT', 61, "The escape sequence '%s' is not a valid code point");

  static final ParserErrorCode INVALID_COMMENT_REFERENCE = new ParserErrorCode.con3('INVALID_COMMENT_REFERENCE', 62, "Comment references should contain a possibly prefixed identifier and can start with 'new', but should not contain anything else");

  static final ParserErrorCode INVALID_HEX_ESCAPE = new ParserErrorCode.con3('INVALID_HEX_ESCAPE', 63, "An escape sequence starting with '\\x' must be followed by 2 hexidecimal digits");

  static final ParserErrorCode INVALID_OPERATOR = new ParserErrorCode.con3('INVALID_OPERATOR', 64, "The string '%s' is not a valid operator");

  static final ParserErrorCode INVALID_OPERATOR_FOR_SUPER = new ParserErrorCode.con3('INVALID_OPERATOR_FOR_SUPER', 65, "The operator '%s' cannot be used with 'super'");

  static final ParserErrorCode INVALID_UNICODE_ESCAPE = new ParserErrorCode.con3('INVALID_UNICODE_ESCAPE', 66, "An escape sequence starting with '\\u' must be followed by 4 hexidecimal digits or from 1 to 6 digits between '{' and '}'");

  static final ParserErrorCode LIBRARY_DIRECTIVE_NOT_FIRST = new ParserErrorCode.con3('LIBRARY_DIRECTIVE_NOT_FIRST', 67, "The library directive must appear before all other directives");

  static final ParserErrorCode LOCAL_FUNCTION_DECLARATION_MODIFIER = new ParserErrorCode.con3('LOCAL_FUNCTION_DECLARATION_MODIFIER', 68, "Local function declarations cannot specify any modifier");

  static final ParserErrorCode MISSING_ASSIGNABLE_SELECTOR = new ParserErrorCode.con3('MISSING_ASSIGNABLE_SELECTOR', 69, "Missing selector such as \".<identifier>\" or \"[0]\"");

  static final ParserErrorCode MISSING_CATCH_OR_FINALLY = new ParserErrorCode.con3('MISSING_CATCH_OR_FINALLY', 70, "A try statement must have either a catch or finally clause");

  static final ParserErrorCode MISSING_CLASS_BODY = new ParserErrorCode.con3('MISSING_CLASS_BODY', 71, "A class definition must have a body, even if it is empty");

  static final ParserErrorCode MISSING_CLOSING_PARENTHESIS = new ParserErrorCode.con3('MISSING_CLOSING_PARENTHESIS', 72, "The closing parenthesis is missing");

  static final ParserErrorCode MISSING_CONST_FINAL_VAR_OR_TYPE = new ParserErrorCode.con3('MISSING_CONST_FINAL_VAR_OR_TYPE', 73, "Variables must be declared using the keywords 'const', 'final', 'var' or a type name");

  static final ParserErrorCode MISSING_EXPRESSION_IN_THROW = new ParserErrorCode.con3('MISSING_EXPRESSION_IN_THROW', 74, "Throw expressions must compute the object to be thrown");

  static final ParserErrorCode MISSING_FUNCTION_BODY = new ParserErrorCode.con3('MISSING_FUNCTION_BODY', 75, "A function body must be provided");

  static final ParserErrorCode MISSING_FUNCTION_PARAMETERS = new ParserErrorCode.con3('MISSING_FUNCTION_PARAMETERS', 76, "Functions must have an explicit list of parameters");

  static final ParserErrorCode MISSING_IDENTIFIER = new ParserErrorCode.con3('MISSING_IDENTIFIER', 77, "Expected an identifier");

  static final ParserErrorCode MISSING_KEYWORD_OPERATOR = new ParserErrorCode.con3('MISSING_KEYWORD_OPERATOR', 78, "Operator declarations must be preceeded by the keyword 'operator'");

  static final ParserErrorCode MISSING_NAME_IN_LIBRARY_DIRECTIVE = new ParserErrorCode.con3('MISSING_NAME_IN_LIBRARY_DIRECTIVE', 79, "Library directives must include a library name");

  static final ParserErrorCode MISSING_NAME_IN_PART_OF_DIRECTIVE = new ParserErrorCode.con3('MISSING_NAME_IN_PART_OF_DIRECTIVE', 80, "Library directives must include a library name");

  static final ParserErrorCode MISSING_STATEMENT = new ParserErrorCode.con3('MISSING_STATEMENT', 81, "Expected a statement");

  static final ParserErrorCode MISSING_TERMINATOR_FOR_PARAMETER_GROUP = new ParserErrorCode.con3('MISSING_TERMINATOR_FOR_PARAMETER_GROUP', 82, "There is no '%s' to close the parameter group");

  static final ParserErrorCode MISSING_TYPEDEF_PARAMETERS = new ParserErrorCode.con3('MISSING_TYPEDEF_PARAMETERS', 83, "Type aliases for functions must have an explicit list of parameters");

  static final ParserErrorCode MISSING_VARIABLE_IN_FOR_EACH = new ParserErrorCode.con3('MISSING_VARIABLE_IN_FOR_EACH', 84, "A loop variable must be declared in a for-each loop before the 'in', but none were found");

  static final ParserErrorCode MIXED_PARAMETER_GROUPS = new ParserErrorCode.con3('MIXED_PARAMETER_GROUPS', 85, "Cannot have both positional and named parameters in a single parameter list");

  static final ParserErrorCode MULTIPLE_EXTENDS_CLAUSES = new ParserErrorCode.con3('MULTIPLE_EXTENDS_CLAUSES', 86, "Each class definition can have at most one extends clause");

  static final ParserErrorCode MULTIPLE_IMPLEMENTS_CLAUSES = new ParserErrorCode.con3('MULTIPLE_IMPLEMENTS_CLAUSES', 87, "Each class definition can have at most one implements clause");

  static final ParserErrorCode MULTIPLE_LIBRARY_DIRECTIVES = new ParserErrorCode.con3('MULTIPLE_LIBRARY_DIRECTIVES', 88, "Only one library directive may be declared in a file");

  static final ParserErrorCode MULTIPLE_NAMED_PARAMETER_GROUPS = new ParserErrorCode.con3('MULTIPLE_NAMED_PARAMETER_GROUPS', 89, "Cannot have multiple groups of named parameters in a single parameter list");

  static final ParserErrorCode MULTIPLE_PART_OF_DIRECTIVES = new ParserErrorCode.con3('MULTIPLE_PART_OF_DIRECTIVES', 90, "Only one part-of directive may be declared in a file");

  static final ParserErrorCode MULTIPLE_POSITIONAL_PARAMETER_GROUPS = new ParserErrorCode.con3('MULTIPLE_POSITIONAL_PARAMETER_GROUPS', 91, "Cannot have multiple groups of positional parameters in a single parameter list");

  static final ParserErrorCode MULTIPLE_VARIABLES_IN_FOR_EACH = new ParserErrorCode.con3('MULTIPLE_VARIABLES_IN_FOR_EACH', 92, "A single loop variable must be declared in a for-each loop before the 'in', but %s were found");

  static final ParserErrorCode MULTIPLE_WITH_CLAUSES = new ParserErrorCode.con3('MULTIPLE_WITH_CLAUSES', 93, "Each class definition can have at most one with clause");

  static final ParserErrorCode NAMED_FUNCTION_EXPRESSION = new ParserErrorCode.con3('NAMED_FUNCTION_EXPRESSION', 94, "Function expressions cannot be named");

  static final ParserErrorCode NAMED_PARAMETER_OUTSIDE_GROUP = new ParserErrorCode.con3('NAMED_PARAMETER_OUTSIDE_GROUP', 95, "Named parameters must be enclosed in curly braces ('{' and '}')");

  static final ParserErrorCode NATIVE_CLAUSE_IN_NON_SDK_CODE = new ParserErrorCode.con3('NATIVE_CLAUSE_IN_NON_SDK_CODE', 96, "Native clause can only be used in the SDK and code that is loaded through native extensions");

  static final ParserErrorCode NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE = new ParserErrorCode.con3('NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE', 97, "Native functions can only be declared in the SDK and code that is loaded through native extensions");

  static final ParserErrorCode NON_CONSTRUCTOR_FACTORY = new ParserErrorCode.con3('NON_CONSTRUCTOR_FACTORY', 98, "Only constructors can be declared to be a 'factory'");

  static final ParserErrorCode NON_IDENTIFIER_LIBRARY_NAME = new ParserErrorCode.con3('NON_IDENTIFIER_LIBRARY_NAME', 99, "The name of a library must be an identifier");

  static final ParserErrorCode NON_PART_OF_DIRECTIVE_IN_PART = new ParserErrorCode.con3('NON_PART_OF_DIRECTIVE_IN_PART', 100, "The part-of directive must be the only directive in a part");

  static final ParserErrorCode NON_USER_DEFINABLE_OPERATOR = new ParserErrorCode.con3('NON_USER_DEFINABLE_OPERATOR', 101, "The operator '%s' is not user definable");

  static final ParserErrorCode NORMAL_BEFORE_OPTIONAL_PARAMETERS = new ParserErrorCode.con3('NORMAL_BEFORE_OPTIONAL_PARAMETERS', 102, "Normal parameters must occur before optional parameters");

  static final ParserErrorCode POSITIONAL_AFTER_NAMED_ARGUMENT = new ParserErrorCode.con3('POSITIONAL_AFTER_NAMED_ARGUMENT', 103, "Positional arguments must occur before named arguments");

  static final ParserErrorCode POSITIONAL_PARAMETER_OUTSIDE_GROUP = new ParserErrorCode.con3('POSITIONAL_PARAMETER_OUTSIDE_GROUP', 104, "Positional parameters must be enclosed in square brackets ('[' and ']')");

  static final ParserErrorCode REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR = new ParserErrorCode.con3('REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR', 105, "Only factory constructor can specify '=' redirection.");

  static final ParserErrorCode SETTER_IN_FUNCTION = new ParserErrorCode.con3('SETTER_IN_FUNCTION', 106, "Setters cannot be defined within methods or functions");

  static final ParserErrorCode STATIC_AFTER_CONST = new ParserErrorCode.con3('STATIC_AFTER_CONST', 107, "The modifier 'static' should be before the modifier 'const'");

  static final ParserErrorCode STATIC_AFTER_FINAL = new ParserErrorCode.con3('STATIC_AFTER_FINAL', 108, "The modifier 'static' should be before the modifier 'final'");

  static final ParserErrorCode STATIC_AFTER_VAR = new ParserErrorCode.con3('STATIC_AFTER_VAR', 109, "The modifier 'static' should be before the modifier 'var'");

  static final ParserErrorCode STATIC_CONSTRUCTOR = new ParserErrorCode.con3('STATIC_CONSTRUCTOR', 110, "Constructors cannot be static");

  static final ParserErrorCode STATIC_GETTER_WITHOUT_BODY = new ParserErrorCode.con3('STATIC_GETTER_WITHOUT_BODY', 111, "A 'static' getter must have a body");

  static final ParserErrorCode STATIC_OPERATOR = new ParserErrorCode.con3('STATIC_OPERATOR', 112, "Operators cannot be static");

  static final ParserErrorCode STATIC_SETTER_WITHOUT_BODY = new ParserErrorCode.con3('STATIC_SETTER_WITHOUT_BODY', 113, "A 'static' setter must have a body");

  static final ParserErrorCode STATIC_TOP_LEVEL_DECLARATION = new ParserErrorCode.con3('STATIC_TOP_LEVEL_DECLARATION', 114, "Top-level declarations cannot be declared to be 'static'");

  static final ParserErrorCode SWITCH_HAS_CASE_AFTER_DEFAULT_CASE = new ParserErrorCode.con3('SWITCH_HAS_CASE_AFTER_DEFAULT_CASE', 115, "The 'default' case should be the last case in a switch statement");

  static final ParserErrorCode SWITCH_HAS_MULTIPLE_DEFAULT_CASES = new ParserErrorCode.con3('SWITCH_HAS_MULTIPLE_DEFAULT_CASES', 116, "The 'default' case can only be declared once");

  static final ParserErrorCode TOP_LEVEL_OPERATOR = new ParserErrorCode.con3('TOP_LEVEL_OPERATOR', 117, "Operators must be declared within a class");

  static final ParserErrorCode UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP = new ParserErrorCode.con3('UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP', 118, "There is no '%s' to open a parameter group");

  static final ParserErrorCode UNEXPECTED_TOKEN = new ParserErrorCode.con3('UNEXPECTED_TOKEN', 119, "Unexpected token '%s'");

  static final ParserErrorCode WITH_BEFORE_EXTENDS = new ParserErrorCode.con3('WITH_BEFORE_EXTENDS', 120, "The extends clause must be before the with clause");

  static final ParserErrorCode WITH_WITHOUT_EXTENDS = new ParserErrorCode.con3('WITH_WITHOUT_EXTENDS', 121, "The with clause cannot be used without an extends clause");

  static final ParserErrorCode WRONG_SEPARATOR_FOR_NAMED_PARAMETER = new ParserErrorCode.con3('WRONG_SEPARATOR_FOR_NAMED_PARAMETER', 122, "The default value of a named parameter should be preceeded by ':'");

  static final ParserErrorCode WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER = new ParserErrorCode.con3('WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER', 123, "The default value of a positional parameter should be preceeded by '='");

  static final ParserErrorCode WRONG_TERMINATOR_FOR_PARAMETER_GROUP = new ParserErrorCode.con3('WRONG_TERMINATOR_FOR_PARAMETER_GROUP', 124, "Expected '%s' to close parameter group");

  static final ParserErrorCode VAR_AND_TYPE = new ParserErrorCode.con3('VAR_AND_TYPE', 125, "Variables cannot be declared using both 'var' and a type name; remove the 'var'");

  static final ParserErrorCode VAR_AS_TYPE_NAME = new ParserErrorCode.con3('VAR_AS_TYPE_NAME', 126, "The keyword 'var' cannot be used as a type name");

  static final ParserErrorCode VAR_CLASS = new ParserErrorCode.con3('VAR_CLASS', 127, "Classes cannot be declared to be 'var'");

  static final ParserErrorCode VAR_RETURN_TYPE = new ParserErrorCode.con3('VAR_RETURN_TYPE', 128, "The return type cannot be 'var'");

  static final ParserErrorCode VAR_TYPEDEF = new ParserErrorCode.con3('VAR_TYPEDEF', 129, "Type aliases cannot be declared to be 'var'");

  static final ParserErrorCode VOID_PARAMETER = new ParserErrorCode.con3('VOID_PARAMETER', 130, "Parameters cannot have a type of 'void'");

  static final ParserErrorCode VOID_VARIABLE = new ParserErrorCode.con3('VOID_VARIABLE', 131, "Variables cannot have a type of 'void'");

  static final List<ParserErrorCode> values = [
      ABSTRACT_CLASS_MEMBER,
      ABSTRACT_STATIC_METHOD,
      ABSTRACT_TOP_LEVEL_FUNCTION,
      ABSTRACT_TOP_LEVEL_VARIABLE,
      ABSTRACT_TYPEDEF,
      ASSERT_DOES_NOT_TAKE_ASSIGNMENT,
      ASSERT_DOES_NOT_TAKE_CASCADE,
      ASSERT_DOES_NOT_TAKE_THROW,
      ASSERT_DOES_NOT_TAKE_RETHROW,
      BREAK_OUTSIDE_OF_LOOP,
      CONST_AND_FINAL,
      CONST_AND_VAR,
      CONST_CLASS,
      CONST_CONSTRUCTOR_WITH_BODY,
      CONST_FACTORY,
      CONST_METHOD,
      CONST_TYPEDEF,
      CONSTRUCTOR_WITH_RETURN_TYPE,
      CONTINUE_OUTSIDE_OF_LOOP,
      CONTINUE_WITHOUT_LABEL_IN_CASE,
      DEPRECATED_ARGUMENT_DEFINITION_TEST,
      DEPRECATED_CLASS_TYPE_ALIAS,
      DIRECTIVE_AFTER_DECLARATION,
      DUPLICATE_LABEL_IN_SWITCH_STATEMENT,
      DUPLICATED_MODIFIER,
      EQUALITY_CANNOT_BE_EQUALITY_OPERAND,
      EXPECTED_CASE_OR_DEFAULT,
      EXPECTED_CLASS_MEMBER,
      EXPECTED_EXECUTABLE,
      EXPECTED_LIST_OR_MAP_LITERAL,
      EXPECTED_STRING_LITERAL,
      EXPECTED_TOKEN,
      EXPECTED_TYPE_NAME,
      EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE,
      EXTERNAL_AFTER_CONST,
      EXTERNAL_AFTER_FACTORY,
      EXTERNAL_AFTER_STATIC,
      EXTERNAL_CLASS,
      EXTERNAL_CONSTRUCTOR_WITH_BODY,
      EXTERNAL_FIELD,
      EXTERNAL_GETTER_WITH_BODY,
      EXTERNAL_METHOD_WITH_BODY,
      EXTERNAL_OPERATOR_WITH_BODY,
      EXTERNAL_SETTER_WITH_BODY,
      EXTERNAL_TYPEDEF,
      FACTORY_TOP_LEVEL_DECLARATION,
      FACTORY_WITHOUT_BODY,
      FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR,
      FINAL_AND_VAR,
      FINAL_CLASS,
      FINAL_CONSTRUCTOR,
      FINAL_METHOD,
      FINAL_TYPEDEF,
      FUNCTION_TYPED_PARAMETER_VAR,
      GETTER_IN_FUNCTION,
      GETTER_WITH_PARAMETERS,
      ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE,
      IMPLEMENTS_BEFORE_EXTENDS,
      IMPLEMENTS_BEFORE_WITH,
      IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE,
      INITIALIZED_VARIABLE_IN_FOR_EACH,
      INVALID_CODE_POINT,
      INVALID_COMMENT_REFERENCE,
      INVALID_HEX_ESCAPE,
      INVALID_OPERATOR,
      INVALID_OPERATOR_FOR_SUPER,
      INVALID_UNICODE_ESCAPE,
      LIBRARY_DIRECTIVE_NOT_FIRST,
      LOCAL_FUNCTION_DECLARATION_MODIFIER,
      MISSING_ASSIGNABLE_SELECTOR,
      MISSING_CATCH_OR_FINALLY,
      MISSING_CLASS_BODY,
      MISSING_CLOSING_PARENTHESIS,
      MISSING_CONST_FINAL_VAR_OR_TYPE,
      MISSING_EXPRESSION_IN_THROW,
      MISSING_FUNCTION_BODY,
      MISSING_FUNCTION_PARAMETERS,
      MISSING_IDENTIFIER,
      MISSING_KEYWORD_OPERATOR,
      MISSING_NAME_IN_LIBRARY_DIRECTIVE,
      MISSING_NAME_IN_PART_OF_DIRECTIVE,
      MISSING_STATEMENT,
      MISSING_TERMINATOR_FOR_PARAMETER_GROUP,
      MISSING_TYPEDEF_PARAMETERS,
      MISSING_VARIABLE_IN_FOR_EACH,
      MIXED_PARAMETER_GROUPS,
      MULTIPLE_EXTENDS_CLAUSES,
      MULTIPLE_IMPLEMENTS_CLAUSES,
      MULTIPLE_LIBRARY_DIRECTIVES,
      MULTIPLE_NAMED_PARAMETER_GROUPS,
      MULTIPLE_PART_OF_DIRECTIVES,
      MULTIPLE_POSITIONAL_PARAMETER_GROUPS,
      MULTIPLE_VARIABLES_IN_FOR_EACH,
      MULTIPLE_WITH_CLAUSES,
      NAMED_FUNCTION_EXPRESSION,
      NAMED_PARAMETER_OUTSIDE_GROUP,
      NATIVE_CLAUSE_IN_NON_SDK_CODE,
      NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE,
      NON_CONSTRUCTOR_FACTORY,
      NON_IDENTIFIER_LIBRARY_NAME,
      NON_PART_OF_DIRECTIVE_IN_PART,
      NON_USER_DEFINABLE_OPERATOR,
      NORMAL_BEFORE_OPTIONAL_PARAMETERS,
      POSITIONAL_AFTER_NAMED_ARGUMENT,
      POSITIONAL_PARAMETER_OUTSIDE_GROUP,
      REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR,
      SETTER_IN_FUNCTION,
      STATIC_AFTER_CONST,
      STATIC_AFTER_FINAL,
      STATIC_AFTER_VAR,
      STATIC_CONSTRUCTOR,
      STATIC_GETTER_WITHOUT_BODY,
      STATIC_OPERATOR,
      STATIC_SETTER_WITHOUT_BODY,
      STATIC_TOP_LEVEL_DECLARATION,
      SWITCH_HAS_CASE_AFTER_DEFAULT_CASE,
      SWITCH_HAS_MULTIPLE_DEFAULT_CASES,
      TOP_LEVEL_OPERATOR,
      UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP,
      UNEXPECTED_TOKEN,
      WITH_BEFORE_EXTENDS,
      WITH_WITHOUT_EXTENDS,
      WRONG_SEPARATOR_FOR_NAMED_PARAMETER,
      WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER,
      WRONG_TERMINATOR_FOR_PARAMETER_GROUP,
      VAR_AND_TYPE,
      VAR_AS_TYPE_NAME,
      VAR_CLASS,
      VAR_RETURN_TYPE,
      VAR_TYPEDEF,
      VOID_PARAMETER,
      VOID_VARIABLE];

  /**
   * The severity of this error.
   */
  ErrorSeverity _severity;

  /**
   * The template used to create the message to be displayed for this error.
   */
  String _message;

  /**
   * The template used to create the correction to be displayed for this error, or `null` if
   * there is no correction information for this error.
   */
  String correction8;

  /**
   * Initialize a newly created error code to have the given severity and message.
   *
   * @param severity the severity of the error
   * @param message the message template used to create the message to be displayed for the error
   */
  ParserErrorCode.con1(String name, int ordinal, ErrorSeverity severity, String message) : super(name, ordinal) {
    this._severity = severity;
    this._message = message;
  }

  /**
   * Initialize a newly created error code to have the given severity, message and correction.
   *
   * @param severity the severity of the error
   * @param message the template used to create the message to be displayed for the error
   * @param correction the template used to create the correction to be displayed for the error
   */
  ParserErrorCode.con2(String name, int ordinal, ErrorSeverity severity, String message, String correction) : super(name, ordinal) {
    this._severity = severity;
    this._message = message;
    this.correction8 = correction;
  }

  /**
   * Initialize a newly created error code to have the given message and a severity of ERROR.
   *
   * @param message the message template used to create the message to be displayed for the error
   */
  ParserErrorCode.con3(String name, int ordinal, String message) : this.con1(name, ordinal, ErrorSeverity.ERROR, message);

  String get correction => correction8;

  ErrorSeverity get errorSeverity => _severity;

  String get message => _message;

  ErrorType get type => ErrorType.SYNTACTIC_ERROR;
}

/**
 * Instances of the class `ResolutionCopier` copies resolution information from one AST
 * structure to another as long as the structures of the corresponding children of a pair of nodes
 * are the same.
 */
class ResolutionCopier implements AstVisitor<bool> {
  /**
   * Copy resolution data from one node to another.
   *
   * @param fromNode the node from which resolution information will be copied
   * @param toNode the node to which resolution information will be copied
   */
  static void copyResolutionData(AstNode fromNode, AstNode toNode) {
    ResolutionCopier copier = new ResolutionCopier();
    copier.isEqualNodes(fromNode, toNode);
  }

  /**
   * The AST node with which the node being visited is to be compared. This is only valid at the
   * beginning of each visit method (until [isEqualNodes] is invoked).
   */
  AstNode _toNode;

  bool visitAdjacentStrings(AdjacentStrings node) {
    AdjacentStrings toNode = this._toNode as AdjacentStrings;
    return isEqualNodeLists(node.strings, toNode.strings);
  }

  bool visitAnnotation(Annotation node) {
    Annotation toNode = this._toNode as Annotation;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.atSign, toNode.atSign), isEqualNodes(node.name, toNode.name)), isEqualTokens(node.period, toNode.period)), isEqualNodes(node.constructorName, toNode.constructorName)), isEqualNodes(node.arguments, toNode.arguments))) {
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  bool visitArgumentDefinitionTest(ArgumentDefinitionTest node) {
    ArgumentDefinitionTest toNode = this._toNode as ArgumentDefinitionTest;
    if (javaBooleanAnd(isEqualTokens(node.question, toNode.question), isEqualNodes(node.identifier, toNode.identifier))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitArgumentList(ArgumentList node) {
    ArgumentList toNode = this._toNode as ArgumentList;
    return javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.leftParenthesis, toNode.leftParenthesis), isEqualNodeLists(node.arguments, toNode.arguments)), isEqualTokens(node.rightParenthesis, toNode.rightParenthesis));
  }

  bool visitAsExpression(AsExpression node) {
    AsExpression toNode = this._toNode as AsExpression;
    if (javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.expression, toNode.expression), isEqualTokens(node.asOperator, toNode.asOperator)), isEqualNodes(node.type, toNode.type))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitAssertStatement(AssertStatement node) {
    AssertStatement toNode = this._toNode as AssertStatement;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.keyword, toNode.keyword), isEqualTokens(node.leftParenthesis, toNode.leftParenthesis)), isEqualNodes(node.condition, toNode.condition)), isEqualTokens(node.rightParenthesis, toNode.rightParenthesis)), isEqualTokens(node.semicolon, toNode.semicolon));
  }

  bool visitAssignmentExpression(AssignmentExpression node) {
    AssignmentExpression toNode = this._toNode as AssignmentExpression;
    if (javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.leftHandSide, toNode.leftHandSide), isEqualTokens(node.operator, toNode.operator)), isEqualNodes(node.rightHandSide, toNode.rightHandSide))) {
      toNode.propagatedElement = node.propagatedElement;
      toNode.propagatedType = node.propagatedType;
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitBinaryExpression(BinaryExpression node) {
    BinaryExpression toNode = this._toNode as BinaryExpression;
    if (javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.leftOperand, toNode.leftOperand), isEqualTokens(node.operator, toNode.operator)), isEqualNodes(node.rightOperand, toNode.rightOperand))) {
      toNode.propagatedElement = node.propagatedElement;
      toNode.propagatedType = node.propagatedType;
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitBlock(Block node) {
    Block toNode = this._toNode as Block;
    return javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.leftBracket, toNode.leftBracket), isEqualNodeLists(node.statements, toNode.statements)), isEqualTokens(node.rightBracket, toNode.rightBracket));
  }

  bool visitBlockFunctionBody(BlockFunctionBody node) {
    BlockFunctionBody toNode = this._toNode as BlockFunctionBody;
    return isEqualNodes(node.block, toNode.block);
  }

  bool visitBooleanLiteral(BooleanLiteral node) {
    BooleanLiteral toNode = this._toNode as BooleanLiteral;
    if (javaBooleanAnd(isEqualTokens(node.literal, toNode.literal), identical(node.value, toNode.value))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitBreakStatement(BreakStatement node) {
    BreakStatement toNode = this._toNode as BreakStatement;
    return javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.keyword, toNode.keyword), isEqualNodes(node.label, toNode.label)), isEqualTokens(node.semicolon, toNode.semicolon));
  }

  bool visitCascadeExpression(CascadeExpression node) {
    CascadeExpression toNode = this._toNode as CascadeExpression;
    if (javaBooleanAnd(isEqualNodes(node.target, toNode.target), isEqualNodeLists(node.cascadeSections, toNode.cascadeSections))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitCatchClause(CatchClause node) {
    CatchClause toNode = this._toNode as CatchClause;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.onKeyword, toNode.onKeyword), isEqualNodes(node.exceptionType, toNode.exceptionType)), isEqualTokens(node.catchKeyword, toNode.catchKeyword)), isEqualTokens(node.leftParenthesis, toNode.leftParenthesis)), isEqualNodes(node.exceptionParameter, toNode.exceptionParameter)), isEqualTokens(node.comma, toNode.comma)), isEqualNodes(node.stackTraceParameter, toNode.stackTraceParameter)), isEqualTokens(node.rightParenthesis, toNode.rightParenthesis)), isEqualNodes(node.body, toNode.body));
  }

  bool visitClassDeclaration(ClassDeclaration node) {
    ClassDeclaration toNode = this._toNode as ClassDeclaration;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.documentationComment, toNode.documentationComment), isEqualNodeLists(node.metadata, toNode.metadata)), isEqualTokens(node.abstractKeyword, toNode.abstractKeyword)), isEqualTokens(node.classKeyword, toNode.classKeyword)), isEqualNodes(node.name, toNode.name)), isEqualNodes(node.typeParameters, toNode.typeParameters)), isEqualNodes(node.extendsClause, toNode.extendsClause)), isEqualNodes(node.withClause, toNode.withClause)), isEqualNodes(node.implementsClause, toNode.implementsClause)), isEqualTokens(node.leftBracket, toNode.leftBracket)), isEqualNodeLists(node.members, toNode.members)), isEqualTokens(node.rightBracket, toNode.rightBracket));
  }

  bool visitClassTypeAlias(ClassTypeAlias node) {
    ClassTypeAlias toNode = this._toNode as ClassTypeAlias;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.documentationComment, toNode.documentationComment), isEqualNodeLists(node.metadata, toNode.metadata)), isEqualTokens(node.keyword, toNode.keyword)), isEqualNodes(node.name, toNode.name)), isEqualNodes(node.typeParameters, toNode.typeParameters)), isEqualTokens(node.equals, toNode.equals)), isEqualTokens(node.abstractKeyword, toNode.abstractKeyword)), isEqualNodes(node.superclass, toNode.superclass)), isEqualNodes(node.withClause, toNode.withClause)), isEqualNodes(node.implementsClause, toNode.implementsClause)), isEqualTokens(node.semicolon, toNode.semicolon));
  }

  bool visitComment(Comment node) {
    Comment toNode = this._toNode as Comment;
    return isEqualNodeLists(node.references, toNode.references);
  }

  bool visitCommentReference(CommentReference node) {
    CommentReference toNode = this._toNode as CommentReference;
    return javaBooleanAnd(isEqualTokens(node.newKeyword, toNode.newKeyword), isEqualNodes(node.identifier, toNode.identifier));
  }

  bool visitCompilationUnit(CompilationUnit node) {
    CompilationUnit toNode = this._toNode as CompilationUnit;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.beginToken, toNode.beginToken), isEqualNodes(node.scriptTag, toNode.scriptTag)), isEqualNodeLists(node.directives, toNode.directives)), isEqualNodeLists(node.declarations, toNode.declarations)), isEqualTokens(node.endToken, toNode.endToken))) {
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  bool visitConditionalExpression(ConditionalExpression node) {
    ConditionalExpression toNode = this._toNode as ConditionalExpression;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.condition, toNode.condition), isEqualTokens(node.question, toNode.question)), isEqualNodes(node.thenExpression, toNode.thenExpression)), isEqualTokens(node.colon, toNode.colon)), isEqualNodes(node.elseExpression, toNode.elseExpression))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitConstructorDeclaration(ConstructorDeclaration node) {
    ConstructorDeclaration toNode = this._toNode as ConstructorDeclaration;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.documentationComment, toNode.documentationComment), isEqualNodeLists(node.metadata, toNode.metadata)), isEqualTokens(node.externalKeyword, toNode.externalKeyword)), isEqualTokens(node.constKeyword, toNode.constKeyword)), isEqualTokens(node.factoryKeyword, toNode.factoryKeyword)), isEqualNodes(node.returnType, toNode.returnType)), isEqualTokens(node.period, toNode.period)), isEqualNodes(node.name, toNode.name)), isEqualNodes(node.parameters, toNode.parameters)), isEqualTokens(node.separator, toNode.separator)), isEqualNodeLists(node.initializers, toNode.initializers)), isEqualNodes(node.redirectedConstructor, toNode.redirectedConstructor)), isEqualNodes(node.body, toNode.body))) {
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  bool visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    ConstructorFieldInitializer toNode = this._toNode as ConstructorFieldInitializer;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.keyword, toNode.keyword), isEqualTokens(node.period, toNode.period)), isEqualNodes(node.fieldName, toNode.fieldName)), isEqualTokens(node.equals, toNode.equals)), isEqualNodes(node.expression, toNode.expression));
  }

  bool visitConstructorName(ConstructorName node) {
    ConstructorName toNode = this._toNode as ConstructorName;
    if (javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.type, toNode.type), isEqualTokens(node.period, toNode.period)), isEqualNodes(node.name, toNode.name))) {
      toNode.staticElement = node.staticElement;
      return true;
    }
    return false;
  }

  bool visitContinueStatement(ContinueStatement node) {
    ContinueStatement toNode = this._toNode as ContinueStatement;
    return javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.keyword, toNode.keyword), isEqualNodes(node.label, toNode.label)), isEqualTokens(node.semicolon, toNode.semicolon));
  }

  bool visitDeclaredIdentifier(DeclaredIdentifier node) {
    DeclaredIdentifier toNode = this._toNode as DeclaredIdentifier;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.documentationComment, toNode.documentationComment), isEqualNodeLists(node.metadata, toNode.metadata)), isEqualTokens(node.keyword, toNode.keyword)), isEqualNodes(node.type, toNode.type)), isEqualNodes(node.identifier, toNode.identifier));
  }

  bool visitDefaultFormalParameter(DefaultFormalParameter node) {
    DefaultFormalParameter toNode = this._toNode as DefaultFormalParameter;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.parameter, toNode.parameter), identical(node.kind, toNode.kind)), isEqualTokens(node.separator, toNode.separator)), isEqualNodes(node.defaultValue, toNode.defaultValue));
  }

  bool visitDoStatement(DoStatement node) {
    DoStatement toNode = this._toNode as DoStatement;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.doKeyword, toNode.doKeyword), isEqualNodes(node.body, toNode.body)), isEqualTokens(node.whileKeyword, toNode.whileKeyword)), isEqualTokens(node.leftParenthesis, toNode.leftParenthesis)), isEqualNodes(node.condition, toNode.condition)), isEqualTokens(node.rightParenthesis, toNode.rightParenthesis)), isEqualTokens(node.semicolon, toNode.semicolon));
  }

  bool visitDoubleLiteral(DoubleLiteral node) {
    DoubleLiteral toNode = this._toNode as DoubleLiteral;
    if (javaBooleanAnd(isEqualTokens(node.literal, toNode.literal), node.value == toNode.value)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitEmptyFunctionBody(EmptyFunctionBody node) {
    EmptyFunctionBody toNode = this._toNode as EmptyFunctionBody;
    return isEqualTokens(node.semicolon, toNode.semicolon);
  }

  bool visitEmptyStatement(EmptyStatement node) {
    EmptyStatement toNode = this._toNode as EmptyStatement;
    return isEqualTokens(node.semicolon, toNode.semicolon);
  }

  bool visitExportDirective(ExportDirective node) {
    ExportDirective toNode = this._toNode as ExportDirective;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.documentationComment, toNode.documentationComment), isEqualNodeLists(node.metadata, toNode.metadata)), isEqualTokens(node.keyword, toNode.keyword)), isEqualNodes(node.uri, toNode.uri)), isEqualNodeLists(node.combinators, toNode.combinators)), isEqualTokens(node.semicolon, toNode.semicolon))) {
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  bool visitExpressionFunctionBody(ExpressionFunctionBody node) {
    ExpressionFunctionBody toNode = this._toNode as ExpressionFunctionBody;
    return javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.functionDefinition, toNode.functionDefinition), isEqualNodes(node.expression, toNode.expression)), isEqualTokens(node.semicolon, toNode.semicolon));
  }

  bool visitExpressionStatement(ExpressionStatement node) {
    ExpressionStatement toNode = this._toNode as ExpressionStatement;
    return javaBooleanAnd(isEqualNodes(node.expression, toNode.expression), isEqualTokens(node.semicolon, toNode.semicolon));
  }

  bool visitExtendsClause(ExtendsClause node) {
    ExtendsClause toNode = this._toNode as ExtendsClause;
    return javaBooleanAnd(isEqualTokens(node.keyword, toNode.keyword), isEqualNodes(node.superclass, toNode.superclass));
  }

  bool visitFieldDeclaration(FieldDeclaration node) {
    FieldDeclaration toNode = this._toNode as FieldDeclaration;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.documentationComment, toNode.documentationComment), isEqualNodeLists(node.metadata, toNode.metadata)), isEqualTokens(node.staticKeyword, toNode.staticKeyword)), isEqualNodes(node.fields, toNode.fields)), isEqualTokens(node.semicolon, toNode.semicolon));
  }

  bool visitFieldFormalParameter(FieldFormalParameter node) {
    FieldFormalParameter toNode = this._toNode as FieldFormalParameter;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.documentationComment, toNode.documentationComment), isEqualNodeLists(node.metadata, toNode.metadata)), isEqualTokens(node.keyword, toNode.keyword)), isEqualNodes(node.type, toNode.type)), isEqualTokens(node.thisToken, toNode.thisToken)), isEqualTokens(node.period, toNode.period)), isEqualNodes(node.identifier, toNode.identifier));
  }

  bool visitForEachStatement(ForEachStatement node) {
    ForEachStatement toNode = this._toNode as ForEachStatement;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.forKeyword, toNode.forKeyword), isEqualTokens(node.leftParenthesis, toNode.leftParenthesis)), isEqualNodes(node.loopVariable, toNode.loopVariable)), isEqualTokens(node.inKeyword, toNode.inKeyword)), isEqualNodes(node.iterator, toNode.iterator)), isEqualTokens(node.rightParenthesis, toNode.rightParenthesis)), isEqualNodes(node.body, toNode.body));
  }

  bool visitFormalParameterList(FormalParameterList node) {
    FormalParameterList toNode = this._toNode as FormalParameterList;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.leftParenthesis, toNode.leftParenthesis), isEqualNodeLists(node.parameters, toNode.parameters)), isEqualTokens(node.leftDelimiter, toNode.leftDelimiter)), isEqualTokens(node.rightDelimiter, toNode.rightDelimiter)), isEqualTokens(node.rightParenthesis, toNode.rightParenthesis));
  }

  bool visitForStatement(ForStatement node) {
    ForStatement toNode = this._toNode as ForStatement;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.forKeyword, toNode.forKeyword), isEqualTokens(node.leftParenthesis, toNode.leftParenthesis)), isEqualNodes(node.variables, toNode.variables)), isEqualNodes(node.initialization, toNode.initialization)), isEqualTokens(node.leftSeparator, toNode.leftSeparator)), isEqualNodes(node.condition, toNode.condition)), isEqualTokens(node.rightSeparator, toNode.rightSeparator)), isEqualNodeLists(node.updaters, toNode.updaters)), isEqualTokens(node.rightParenthesis, toNode.rightParenthesis)), isEqualNodes(node.body, toNode.body));
  }

  bool visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionDeclaration toNode = this._toNode as FunctionDeclaration;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.documentationComment, toNode.documentationComment), isEqualNodeLists(node.metadata, toNode.metadata)), isEqualTokens(node.externalKeyword, toNode.externalKeyword)), isEqualNodes(node.returnType, toNode.returnType)), isEqualTokens(node.propertyKeyword, toNode.propertyKeyword)), isEqualNodes(node.name, toNode.name)), isEqualNodes(node.functionExpression, toNode.functionExpression));
  }

  bool visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    FunctionDeclarationStatement toNode = this._toNode as FunctionDeclarationStatement;
    return isEqualNodes(node.functionDeclaration, toNode.functionDeclaration);
  }

  bool visitFunctionExpression(FunctionExpression node) {
    FunctionExpression toNode = this._toNode as FunctionExpression;
    if (javaBooleanAnd(isEqualNodes(node.parameters, toNode.parameters), isEqualNodes(node.body, toNode.body))) {
      toNode.element = node.element;
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    FunctionExpressionInvocation toNode = this._toNode as FunctionExpressionInvocation;
    if (javaBooleanAnd(isEqualNodes(node.function, toNode.function), isEqualNodes(node.argumentList, toNode.argumentList))) {
      toNode.propagatedElement = node.propagatedElement;
      toNode.propagatedType = node.propagatedType;
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitFunctionTypeAlias(FunctionTypeAlias node) {
    FunctionTypeAlias toNode = this._toNode as FunctionTypeAlias;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.documentationComment, toNode.documentationComment), isEqualNodeLists(node.metadata, toNode.metadata)), isEqualTokens(node.keyword, toNode.keyword)), isEqualNodes(node.returnType, toNode.returnType)), isEqualNodes(node.name, toNode.name)), isEqualNodes(node.typeParameters, toNode.typeParameters)), isEqualNodes(node.parameters, toNode.parameters)), isEqualTokens(node.semicolon, toNode.semicolon));
  }

  bool visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    FunctionTypedFormalParameter toNode = this._toNode as FunctionTypedFormalParameter;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.documentationComment, toNode.documentationComment), isEqualNodeLists(node.metadata, toNode.metadata)), isEqualNodes(node.returnType, toNode.returnType)), isEqualNodes(node.identifier, toNode.identifier)), isEqualNodes(node.parameters, toNode.parameters));
  }

  bool visitHideCombinator(HideCombinator node) {
    HideCombinator toNode = this._toNode as HideCombinator;
    return javaBooleanAnd(isEqualTokens(node.keyword, toNode.keyword), isEqualNodeLists(node.hiddenNames, toNode.hiddenNames));
  }

  bool visitIfStatement(IfStatement node) {
    IfStatement toNode = this._toNode as IfStatement;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.ifKeyword, toNode.ifKeyword), isEqualTokens(node.leftParenthesis, toNode.leftParenthesis)), isEqualNodes(node.condition, toNode.condition)), isEqualTokens(node.rightParenthesis, toNode.rightParenthesis)), isEqualNodes(node.thenStatement, toNode.thenStatement)), isEqualTokens(node.elseKeyword, toNode.elseKeyword)), isEqualNodes(node.elseStatement, toNode.elseStatement));
  }

  bool visitImplementsClause(ImplementsClause node) {
    ImplementsClause toNode = this._toNode as ImplementsClause;
    return javaBooleanAnd(isEqualTokens(node.keyword, toNode.keyword), isEqualNodeLists(node.interfaces, toNode.interfaces));
  }

  bool visitImportDirective(ImportDirective node) {
    ImportDirective toNode = this._toNode as ImportDirective;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.documentationComment, toNode.documentationComment), isEqualNodeLists(node.metadata, toNode.metadata)), isEqualTokens(node.keyword, toNode.keyword)), isEqualNodes(node.uri, toNode.uri)), isEqualTokens(node.asToken, toNode.asToken)), isEqualNodes(node.prefix, toNode.prefix)), isEqualNodeLists(node.combinators, toNode.combinators)), isEqualTokens(node.semicolon, toNode.semicolon))) {
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  bool visitIndexExpression(IndexExpression node) {
    IndexExpression toNode = this._toNode as IndexExpression;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.target, toNode.target), isEqualTokens(node.leftBracket, toNode.leftBracket)), isEqualNodes(node.index, toNode.index)), isEqualTokens(node.rightBracket, toNode.rightBracket))) {
      toNode.auxiliaryElements = node.auxiliaryElements;
      toNode.propagatedElement = node.propagatedElement;
      toNode.propagatedType = node.propagatedType;
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitInstanceCreationExpression(InstanceCreationExpression node) {
    InstanceCreationExpression toNode = this._toNode as InstanceCreationExpression;
    if (javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.keyword, toNode.keyword), isEqualNodes(node.constructorName, toNode.constructorName)), isEqualNodes(node.argumentList, toNode.argumentList))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitIntegerLiteral(IntegerLiteral node) {
    IntegerLiteral toNode = this._toNode as IntegerLiteral;
    if (javaBooleanAnd(isEqualTokens(node.literal, toNode.literal), identical(node.value, toNode.value))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitInterpolationExpression(InterpolationExpression node) {
    InterpolationExpression toNode = this._toNode as InterpolationExpression;
    return javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.leftBracket, toNode.leftBracket), isEqualNodes(node.expression, toNode.expression)), isEqualTokens(node.rightBracket, toNode.rightBracket));
  }

  bool visitInterpolationString(InterpolationString node) {
    InterpolationString toNode = this._toNode as InterpolationString;
    return javaBooleanAnd(isEqualTokens(node.contents, toNode.contents), node.value == toNode.value);
  }

  bool visitIsExpression(IsExpression node) {
    IsExpression toNode = this._toNode as IsExpression;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.expression, toNode.expression), isEqualTokens(node.isOperator, toNode.isOperator)), isEqualTokens(node.notOperator, toNode.notOperator)), isEqualNodes(node.type, toNode.type))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitLabel(Label node) {
    Label toNode = this._toNode as Label;
    return javaBooleanAnd(isEqualNodes(node.label, toNode.label), isEqualTokens(node.colon, toNode.colon));
  }

  bool visitLabeledStatement(LabeledStatement node) {
    LabeledStatement toNode = this._toNode as LabeledStatement;
    return javaBooleanAnd(isEqualNodeLists(node.labels, toNode.labels), isEqualNodes(node.statement, toNode.statement));
  }

  bool visitLibraryDirective(LibraryDirective node) {
    LibraryDirective toNode = this._toNode as LibraryDirective;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.documentationComment, toNode.documentationComment), isEqualNodeLists(node.metadata, toNode.metadata)), isEqualTokens(node.libraryToken, toNode.libraryToken)), isEqualNodes(node.name, toNode.name)), isEqualTokens(node.semicolon, toNode.semicolon));
  }

  bool visitLibraryIdentifier(LibraryIdentifier node) {
    LibraryIdentifier toNode = this._toNode as LibraryIdentifier;
    if (isEqualNodeLists(node.components, toNode.components)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitListLiteral(ListLiteral node) {
    ListLiteral toNode = this._toNode as ListLiteral;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.constKeyword, toNode.constKeyword), isEqualNodes(node.typeArguments, toNode.typeArguments)), isEqualTokens(node.leftBracket, toNode.leftBracket)), isEqualNodeLists(node.elements, toNode.elements)), isEqualTokens(node.rightBracket, toNode.rightBracket))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitMapLiteral(MapLiteral node) {
    MapLiteral toNode = this._toNode as MapLiteral;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.constKeyword, toNode.constKeyword), isEqualNodes(node.typeArguments, toNode.typeArguments)), isEqualTokens(node.leftBracket, toNode.leftBracket)), isEqualNodeLists(node.entries, toNode.entries)), isEqualTokens(node.rightBracket, toNode.rightBracket))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitMapLiteralEntry(MapLiteralEntry node) {
    MapLiteralEntry toNode = this._toNode as MapLiteralEntry;
    return javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.key, toNode.key), isEqualTokens(node.separator, toNode.separator)), isEqualNodes(node.value, toNode.value));
  }

  bool visitMethodDeclaration(MethodDeclaration node) {
    MethodDeclaration toNode = this._toNode as MethodDeclaration;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.documentationComment, toNode.documentationComment), isEqualNodeLists(node.metadata, toNode.metadata)), isEqualTokens(node.externalKeyword, toNode.externalKeyword)), isEqualTokens(node.modifierKeyword, toNode.modifierKeyword)), isEqualNodes(node.returnType, toNode.returnType)), isEqualTokens(node.propertyKeyword, toNode.propertyKeyword)), isEqualTokens(node.propertyKeyword, toNode.propertyKeyword)), isEqualNodes(node.name, toNode.name)), isEqualNodes(node.parameters, toNode.parameters)), isEqualNodes(node.body, toNode.body));
  }

  bool visitMethodInvocation(MethodInvocation node) {
    MethodInvocation toNode = this._toNode as MethodInvocation;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.target, toNode.target), isEqualTokens(node.period, toNode.period)), isEqualNodes(node.methodName, toNode.methodName)), isEqualNodes(node.argumentList, toNode.argumentList))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitNamedExpression(NamedExpression node) {
    NamedExpression toNode = this._toNode as NamedExpression;
    if (javaBooleanAnd(isEqualNodes(node.name, toNode.name), isEqualNodes(node.expression, toNode.expression))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitNativeClause(NativeClause node) {
    NativeClause toNode = this._toNode as NativeClause;
    return javaBooleanAnd(isEqualTokens(node.keyword, toNode.keyword), isEqualNodes(node.name, toNode.name));
  }

  bool visitNativeFunctionBody(NativeFunctionBody node) {
    NativeFunctionBody toNode = this._toNode as NativeFunctionBody;
    return javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.nativeToken, toNode.nativeToken), isEqualNodes(node.stringLiteral, toNode.stringLiteral)), isEqualTokens(node.semicolon, toNode.semicolon));
  }

  bool visitNullLiteral(NullLiteral node) {
    NullLiteral toNode = this._toNode as NullLiteral;
    if (isEqualTokens(node.literal, toNode.literal)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitParenthesizedExpression(ParenthesizedExpression node) {
    ParenthesizedExpression toNode = this._toNode as ParenthesizedExpression;
    if (javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.leftParenthesis, toNode.leftParenthesis), isEqualNodes(node.expression, toNode.expression)), isEqualTokens(node.rightParenthesis, toNode.rightParenthesis))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitPartDirective(PartDirective node) {
    PartDirective toNode = this._toNode as PartDirective;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.documentationComment, toNode.documentationComment), isEqualNodeLists(node.metadata, toNode.metadata)), isEqualTokens(node.partToken, toNode.partToken)), isEqualNodes(node.uri, toNode.uri)), isEqualTokens(node.semicolon, toNode.semicolon))) {
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  bool visitPartOfDirective(PartOfDirective node) {
    PartOfDirective toNode = this._toNode as PartOfDirective;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.documentationComment, toNode.documentationComment), isEqualNodeLists(node.metadata, toNode.metadata)), isEqualTokens(node.partToken, toNode.partToken)), isEqualTokens(node.ofToken, toNode.ofToken)), isEqualNodes(node.libraryName, toNode.libraryName)), isEqualTokens(node.semicolon, toNode.semicolon))) {
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  bool visitPostfixExpression(PostfixExpression node) {
    PostfixExpression toNode = this._toNode as PostfixExpression;
    if (javaBooleanAnd(isEqualNodes(node.operand, toNode.operand), isEqualTokens(node.operator, toNode.operator))) {
      toNode.propagatedElement = node.propagatedElement;
      toNode.propagatedType = node.propagatedType;
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitPrefixedIdentifier(PrefixedIdentifier node) {
    PrefixedIdentifier toNode = this._toNode as PrefixedIdentifier;
    if (javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.prefix, toNode.prefix), isEqualTokens(node.period, toNode.period)), isEqualNodes(node.identifier, toNode.identifier))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitPrefixExpression(PrefixExpression node) {
    PrefixExpression toNode = this._toNode as PrefixExpression;
    if (javaBooleanAnd(isEqualTokens(node.operator, toNode.operator), isEqualNodes(node.operand, toNode.operand))) {
      toNode.propagatedElement = node.propagatedElement;
      toNode.propagatedType = node.propagatedType;
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitPropertyAccess(PropertyAccess node) {
    PropertyAccess toNode = this._toNode as PropertyAccess;
    if (javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.target, toNode.target), isEqualTokens(node.operator, toNode.operator)), isEqualNodes(node.propertyName, toNode.propertyName))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    RedirectingConstructorInvocation toNode = this._toNode as RedirectingConstructorInvocation;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.keyword, toNode.keyword), isEqualTokens(node.period, toNode.period)), isEqualNodes(node.constructorName, toNode.constructorName)), isEqualNodes(node.argumentList, toNode.argumentList))) {
      toNode.staticElement = node.staticElement;
      return true;
    }
    return false;
  }

  bool visitRethrowExpression(RethrowExpression node) {
    RethrowExpression toNode = this._toNode as RethrowExpression;
    if (isEqualTokens(node.keyword, toNode.keyword)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitReturnStatement(ReturnStatement node) {
    ReturnStatement toNode = this._toNode as ReturnStatement;
    return javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.keyword, toNode.keyword), isEqualNodes(node.expression, toNode.expression)), isEqualTokens(node.semicolon, toNode.semicolon));
  }

  bool visitScriptTag(ScriptTag node) {
    ScriptTag toNode = this._toNode as ScriptTag;
    return isEqualTokens(node.scriptTag, toNode.scriptTag);
  }

  bool visitShowCombinator(ShowCombinator node) {
    ShowCombinator toNode = this._toNode as ShowCombinator;
    return javaBooleanAnd(isEqualTokens(node.keyword, toNode.keyword), isEqualNodeLists(node.shownNames, toNode.shownNames));
  }

  bool visitSimpleFormalParameter(SimpleFormalParameter node) {
    SimpleFormalParameter toNode = this._toNode as SimpleFormalParameter;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.documentationComment, toNode.documentationComment), isEqualNodeLists(node.metadata, toNode.metadata)), isEqualTokens(node.keyword, toNode.keyword)), isEqualNodes(node.type, toNode.type)), isEqualNodes(node.identifier, toNode.identifier));
  }

  bool visitSimpleIdentifier(SimpleIdentifier node) {
    SimpleIdentifier toNode = this._toNode as SimpleIdentifier;
    if (isEqualTokens(node.token, toNode.token)) {
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      toNode.propagatedElement = node.propagatedElement;
      toNode.propagatedType = node.propagatedType;
      toNode.auxiliaryElements = node.auxiliaryElements;
      return true;
    }
    return false;
  }

  bool visitSimpleStringLiteral(SimpleStringLiteral node) {
    SimpleStringLiteral toNode = this._toNode as SimpleStringLiteral;
    if (javaBooleanAnd(isEqualTokens(node.literal, toNode.literal), identical(node.value, toNode.value))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitStringInterpolation(StringInterpolation node) {
    StringInterpolation toNode = this._toNode as StringInterpolation;
    if (isEqualNodeLists(node.elements, toNode.elements)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    SuperConstructorInvocation toNode = this._toNode as SuperConstructorInvocation;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.keyword, toNode.keyword), isEqualTokens(node.period, toNode.period)), isEqualNodes(node.constructorName, toNode.constructorName)), isEqualNodes(node.argumentList, toNode.argumentList))) {
      toNode.staticElement = node.staticElement;
      return true;
    }
    return false;
  }

  bool visitSuperExpression(SuperExpression node) {
    SuperExpression toNode = this._toNode as SuperExpression;
    if (isEqualTokens(node.keyword, toNode.keyword)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitSwitchCase(SwitchCase node) {
    SwitchCase toNode = this._toNode as SwitchCase;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodeLists(node.labels, toNode.labels), isEqualTokens(node.keyword, toNode.keyword)), isEqualNodes(node.expression, toNode.expression)), isEqualTokens(node.colon, toNode.colon)), isEqualNodeLists(node.statements, toNode.statements));
  }

  bool visitSwitchDefault(SwitchDefault node) {
    SwitchDefault toNode = this._toNode as SwitchDefault;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodeLists(node.labels, toNode.labels), isEqualTokens(node.keyword, toNode.keyword)), isEqualTokens(node.colon, toNode.colon)), isEqualNodeLists(node.statements, toNode.statements));
  }

  bool visitSwitchStatement(SwitchStatement node) {
    SwitchStatement toNode = this._toNode as SwitchStatement;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.keyword, toNode.keyword), isEqualTokens(node.leftParenthesis, toNode.leftParenthesis)), isEqualNodes(node.expression, toNode.expression)), isEqualTokens(node.rightParenthesis, toNode.rightParenthesis)), isEqualTokens(node.leftBracket, toNode.leftBracket)), isEqualNodeLists(node.members, toNode.members)), isEqualTokens(node.rightBracket, toNode.rightBracket));
  }

  bool visitSymbolLiteral(SymbolLiteral node) {
    SymbolLiteral toNode = this._toNode as SymbolLiteral;
    if (javaBooleanAnd(isEqualTokens(node.poundSign, toNode.poundSign), isEqualTokenLists(node.components, toNode.components))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitThisExpression(ThisExpression node) {
    ThisExpression toNode = this._toNode as ThisExpression;
    if (isEqualTokens(node.keyword, toNode.keyword)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitThrowExpression(ThrowExpression node) {
    ThrowExpression toNode = this._toNode as ThrowExpression;
    if (javaBooleanAnd(isEqualTokens(node.keyword, toNode.keyword), isEqualNodes(node.expression, toNode.expression))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    TopLevelVariableDeclaration toNode = this._toNode as TopLevelVariableDeclaration;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.documentationComment, toNode.documentationComment), isEqualNodeLists(node.metadata, toNode.metadata)), isEqualNodes(node.variables, toNode.variables)), isEqualTokens(node.semicolon, toNode.semicolon));
  }

  bool visitTryStatement(TryStatement node) {
    TryStatement toNode = this._toNode as TryStatement;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.tryKeyword, toNode.tryKeyword), isEqualNodes(node.body, toNode.body)), isEqualNodeLists(node.catchClauses, toNode.catchClauses)), isEqualTokens(node.finallyKeyword, toNode.finallyKeyword)), isEqualNodes(node.finallyBlock, toNode.finallyBlock));
  }

  bool visitTypeArgumentList(TypeArgumentList node) {
    TypeArgumentList toNode = this._toNode as TypeArgumentList;
    return javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.leftBracket, toNode.leftBracket), isEqualNodeLists(node.arguments, toNode.arguments)), isEqualTokens(node.rightBracket, toNode.rightBracket));
  }

  bool visitTypeName(TypeName node) {
    TypeName toNode = this._toNode as TypeName;
    if (javaBooleanAnd(isEqualNodes(node.name, toNode.name), isEqualNodes(node.typeArguments, toNode.typeArguments))) {
      toNode.type = node.type;
      return true;
    }
    return false;
  }

  bool visitTypeParameter(TypeParameter node) {
    TypeParameter toNode = this._toNode as TypeParameter;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.documentationComment, toNode.documentationComment), isEqualNodeLists(node.metadata, toNode.metadata)), isEqualNodes(node.name, toNode.name)), isEqualTokens(node.keyword, toNode.keyword)), isEqualNodes(node.bound, toNode.bound));
  }

  bool visitTypeParameterList(TypeParameterList node) {
    TypeParameterList toNode = this._toNode as TypeParameterList;
    return javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.leftBracket, toNode.leftBracket), isEqualNodeLists(node.typeParameters, toNode.typeParameters)), isEqualTokens(node.rightBracket, toNode.rightBracket));
  }

  bool visitVariableDeclaration(VariableDeclaration node) {
    VariableDeclaration toNode = this._toNode as VariableDeclaration;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.documentationComment, toNode.documentationComment), isEqualNodeLists(node.metadata, toNode.metadata)), isEqualNodes(node.name, toNode.name)), isEqualTokens(node.equals, toNode.equals)), isEqualNodes(node.initializer, toNode.initializer));
  }

  bool visitVariableDeclarationList(VariableDeclarationList node) {
    VariableDeclarationList toNode = this._toNode as VariableDeclarationList;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualNodes(node.documentationComment, toNode.documentationComment), isEqualNodeLists(node.metadata, toNode.metadata)), isEqualTokens(node.keyword, toNode.keyword)), isEqualNodes(node.type, toNode.type)), isEqualNodeLists(node.variables, toNode.variables));
  }

  bool visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    VariableDeclarationStatement toNode = this._toNode as VariableDeclarationStatement;
    return javaBooleanAnd(isEqualNodes(node.variables, toNode.variables), isEqualTokens(node.semicolon, toNode.semicolon));
  }

  bool visitWhileStatement(WhileStatement node) {
    WhileStatement toNode = this._toNode as WhileStatement;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqualTokens(node.keyword, toNode.keyword), isEqualTokens(node.leftParenthesis, toNode.leftParenthesis)), isEqualNodes(node.condition, toNode.condition)), isEqualTokens(node.rightParenthesis, toNode.rightParenthesis)), isEqualNodes(node.body, toNode.body));
  }

  bool visitWithClause(WithClause node) {
    WithClause toNode = this._toNode as WithClause;
    return javaBooleanAnd(isEqualTokens(node.withKeyword, toNode.withKeyword), isEqualNodeLists(node.mixinTypes, toNode.mixinTypes));
  }

  /**
   * Return `true` if the given lists of AST nodes have the same size and corresponding
   * elements are equal.
   *
   * @param first the first node being compared
   * @param second the second node being compared
   * @return `true` if the given AST nodes have the same size and corresponding elements are
   *         equal
   */
  bool isEqualNodeLists(NodeList first, NodeList second) {
    if (first == null) {
      return second == null;
    } else if (second == null) {
      return false;
    }
    int size = first.length;
    if (second.length != size) {
      return false;
    }
    bool equal = true;
    for (int i = 0; i < size; i++) {
      if (!isEqualNodes(first[i], second[i])) {
        equal = false;
      }
    }
    return equal;
  }

  /**
   * Return `true` if the given AST nodes have the same structure. As a side-effect, if the
   * nodes do have the same structure, any resolution data from the first node will be copied to the
   * second node.
   *
   * @param fromNode the node from which resolution information will be copied
   * @param toNode the node to which resolution information will be copied
   * @return `true` if the given AST nodes have the same structure
   */
  bool isEqualNodes(AstNode fromNode, AstNode toNode) {
    if (fromNode == null) {
      return toNode == null;
    } else if (toNode == null) {
      return false;
    } else if (fromNode.runtimeType == toNode.runtimeType) {
      this._toNode = toNode;
      return fromNode.accept(this);
    }
    //
    // Check for a simple transformation caused by entering a period.
    //
    if (toNode is PrefixedIdentifier) {
      SimpleIdentifier prefix = toNode.prefix;
      if (fromNode.runtimeType == prefix.runtimeType) {
        this._toNode = prefix;
        return fromNode.accept(this);
      }
    } else if (toNode is PropertyAccess) {
      Expression target = toNode.target;
      if (fromNode.runtimeType == target.runtimeType) {
        this._toNode = target;
        return fromNode.accept(this);
      }
    }
    return false;
  }

  /**
   * Return `true` if the given arrays of tokens have the same length and corresponding
   * elements are equal.
   *
   * @param first the first node being compared
   * @param second the second node being compared
   * @return `true` if the given arrays of tokens have the same length and corresponding
   *         elements are equal
   */
  bool isEqualTokenLists(List<Token> first, List<Token> second) {
    int length = first.length;
    if (second.length != length) {
      return false;
    }
    for (int i = 0; i < length; i++) {
      if (!isEqualTokens(first[i], second[i])) {
        return false;
      }
    }
    return true;
  }

  /**
   * Return `true` if the given tokens have the same structure.
   *
   * @param first the first node being compared
   * @param second the second node being compared
   * @return `true` if the given tokens have the same structure
   */
  bool isEqualTokens(Token first, Token second) {
    if (first == null) {
      return second == null;
    } else if (second == null) {
      return false;
    }
    return first.lexeme == second.lexeme;
  }
}

/**
 * Instances of the class {link ToFormattedSourceVisitor} write a source representation of a visited
 * AST node (and all of it's children) to a writer.
 */
class ToFormattedSourceVisitor implements AstVisitor<Object> {
  static String COMMENTS_KEY = "List of comments before statement";

  /**
   * The writer to which the source is to be written.
   */
  PrintWriter _writer;

  int _indentLevel = 0;

  String _indentString = "";

  /**
   * Initialize a newly created visitor to write source code representing the visited nodes to the
   * given writer.
   *
   * @param writer the writer to which the source is to be written
   */
  ToFormattedSourceVisitor(PrintWriter writer) {
    this._writer = writer;
  }

  Object visitAdjacentStrings(AdjacentStrings node) {
    visitNodeListWithSeparator(node.strings, " ");
    return null;
  }

  Object visitAnnotation(Annotation node) {
    _writer.print('@');
    visitNode(node.name);
    visitNodeWithPrefix(".", node.constructorName);
    visitNode(node.arguments);
    return null;
  }

  Object visitArgumentDefinitionTest(ArgumentDefinitionTest node) {
    _writer.print('?');
    visitNode(node.identifier);
    return null;
  }

  Object visitArgumentList(ArgumentList node) {
    _writer.print('(');
    visitNodeListWithSeparator(node.arguments, ", ");
    _writer.print(')');
    return null;
  }

  Object visitAsExpression(AsExpression node) {
    visitNode(node.expression);
    _writer.print(" as ");
    visitNode(node.type);
    return null;
  }

  Object visitAssertStatement(AssertStatement node) {
    _writer.print("assert(");
    visitNode(node.condition);
    _writer.print(");");
    return null;
  }

  Object visitAssignmentExpression(AssignmentExpression node) {
    visitNode(node.leftHandSide);
    _writer.print(' ');
    _writer.print(node.operator.lexeme);
    _writer.print(' ');
    visitNode(node.rightHandSide);
    return null;
  }

  Object visitBinaryExpression(BinaryExpression node) {
    visitNode(node.leftOperand);
    _writer.print(' ');
    _writer.print(node.operator.lexeme);
    _writer.print(' ');
    visitNode(node.rightOperand);
    return null;
  }

  Object visitBlock(Block node) {
    _writer.print('{');
    {
      indentInc();
      visitNodeListWithSeparatorAndPrefix("\n", node.statements, "\n");
      indentDec();
    }
    nl2();
    _writer.print('}');
    return null;
  }

  Object visitBlockFunctionBody(BlockFunctionBody node) {
    visitNode(node.block);
    return null;
  }

  Object visitBooleanLiteral(BooleanLiteral node) {
    _writer.print(node.literal.lexeme);
    return null;
  }

  Object visitBreakStatement(BreakStatement node) {
    _writer.print("break");
    visitNodeWithPrefix(" ", node.label);
    _writer.print(";");
    return null;
  }

  Object visitCascadeExpression(CascadeExpression node) {
    visitNode(node.target);
    visitNodeList(node.cascadeSections);
    return null;
  }

  Object visitCatchClause(CatchClause node) {
    visitNodeWithPrefix("on ", node.exceptionType);
    if (node.catchKeyword != null) {
      if (node.exceptionType != null) {
        _writer.print(' ');
      }
      _writer.print("catch (");
      visitNode(node.exceptionParameter);
      visitNodeWithPrefix(", ", node.stackTraceParameter);
      _writer.print(") ");
    } else {
      _writer.print(" ");
    }
    visitNode(node.body);
    return null;
  }

  Object visitClassDeclaration(ClassDeclaration node) {
    visitNode(node.documentationComment);
    visitTokenWithSuffix(node.abstractKeyword, " ");
    _writer.print("class ");
    visitNode(node.name);
    visitNode(node.typeParameters);
    visitNodeWithPrefix(" ", node.extendsClause);
    visitNodeWithPrefix(" ", node.withClause);
    visitNodeWithPrefix(" ", node.implementsClause);
    _writer.print(" {");
    {
      indentInc();
      visitNodeListWithSeparatorAndPrefix("\n", node.members, "\n\n");
      indentDec();
    }
    nl2();
    _writer.print("}");
    return null;
  }

  Object visitClassTypeAlias(ClassTypeAlias node) {
    _writer.print("typedef ");
    visitNode(node.name);
    visitNode(node.typeParameters);
    _writer.print(" = ");
    if (node.abstractKeyword != null) {
      _writer.print("abstract ");
    }
    visitNode(node.superclass);
    visitNodeWithPrefix(" ", node.withClause);
    visitNodeWithPrefix(" ", node.implementsClause);
    _writer.print(";");
    return null;
  }

  Object visitComment(Comment node) {
    Token token = node.beginToken;
    while (token != null) {
      bool firstLine = true;
      for (String line in StringUtils.split(token.lexeme, "\n")) {
        if (firstLine) {
          firstLine = false;
        } else {
          line = " ${line.trim()}";
          line = StringUtils.replace(line, "/*", "/ *");
        }
        _writer.print(line);
        nl2();
      }
      if (identical(token, node.endToken)) {
        break;
      }
    }
    return null;
  }

  Object visitCommentReference(CommentReference node) => null;

  Object visitCompilationUnit(CompilationUnit node) {
    ScriptTag scriptTag = node.scriptTag;
    NodeList<Directive> directives = node.directives;
    visitNode(scriptTag);
    // directives
    String prefix = scriptTag == null ? "" : " ";
    visitNodeListWithSeparatorAndPrefix(prefix, directives, "\n");
    nl();
    // declarations
    prefix = scriptTag == null && directives.isEmpty ? "" : "\n";
    visitNodeListWithSeparatorAndPrefix(prefix, node.declarations, "\n\n");
    return null;
  }

  Object visitConditionalExpression(ConditionalExpression node) {
    visitNode(node.condition);
    _writer.print(" ? ");
    visitNode(node.thenExpression);
    _writer.print(" : ");
    visitNode(node.elseExpression);
    return null;
  }

  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    visitNode(node.documentationComment);
    visitTokenWithSuffix(node.externalKeyword, " ");
    visitTokenWithSuffix(node.constKeyword, " ");
    visitTokenWithSuffix(node.factoryKeyword, " ");
    visitNode(node.returnType);
    visitNodeWithPrefix(".", node.name);
    visitNode(node.parameters);
    visitNodeListWithSeparatorAndPrefix(" : ", node.initializers, ", ");
    visitNodeWithPrefix(" = ", node.redirectedConstructor);
    if (node.body is! EmptyFunctionBody) {
      _writer.print(' ');
    }
    visitNode(node.body);
    return null;
  }

  Object visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    visitTokenWithSuffix(node.keyword, ".");
    visitNode(node.fieldName);
    _writer.print(" = ");
    visitNode(node.expression);
    return null;
  }

  Object visitConstructorName(ConstructorName node) {
    visitNode(node.type);
    visitNodeWithPrefix(".", node.name);
    return null;
  }

  Object visitContinueStatement(ContinueStatement node) {
    _writer.print("continue");
    visitNodeWithPrefix(" ", node.label);
    _writer.print(";");
    return null;
  }

  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    visitTokenWithSuffix(node.keyword, " ");
    visitNodeWithSuffix(node.type, " ");
    visitNode(node.identifier);
    return null;
  }

  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    visitNode(node.parameter);
    if (node.separator != null) {
      _writer.print(" ");
      _writer.print(node.separator.lexeme);
      visitNodeWithPrefix(" ", node.defaultValue);
    }
    return null;
  }

  Object visitDoStatement(DoStatement node) {
    _writer.print("do ");
    visitNode(node.body);
    _writer.print(" while (");
    visitNode(node.condition);
    _writer.print(");");
    return null;
  }

  Object visitDoubleLiteral(DoubleLiteral node) {
    _writer.print(node.literal.lexeme);
    return null;
  }

  Object visitEmptyFunctionBody(EmptyFunctionBody node) {
    _writer.print(';');
    return null;
  }

  Object visitEmptyStatement(EmptyStatement node) {
    _writer.print(';');
    return null;
  }

  Object visitExportDirective(ExportDirective node) {
    _writer.print("export ");
    visitNode(node.uri);
    visitNodeListWithSeparatorAndPrefix(" ", node.combinators, " ");
    _writer.print(';');
    return null;
  }

  Object visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _writer.print("=> ");
    visitNode(node.expression);
    if (node.semicolon != null) {
      _writer.print(';');
    }
    return null;
  }

  Object visitExpressionStatement(ExpressionStatement node) {
    visitNode(node.expression);
    _writer.print(';');
    return null;
  }

  Object visitExtendsClause(ExtendsClause node) {
    _writer.print("extends ");
    visitNode(node.superclass);
    return null;
  }

  Object visitFieldDeclaration(FieldDeclaration node) {
    visitNode(node.documentationComment);
    visitTokenWithSuffix(node.staticKeyword, " ");
    visitNode(node.fields);
    _writer.print(";");
    return null;
  }

  Object visitFieldFormalParameter(FieldFormalParameter node) {
    visitTokenWithSuffix(node.keyword, " ");
    visitNodeWithSuffix(node.type, " ");
    _writer.print("this.");
    visitNode(node.identifier);
    visitNode(node.parameters);
    return null;
  }

  Object visitForEachStatement(ForEachStatement node) {
    DeclaredIdentifier loopVariable = node.loopVariable;
    _writer.print("for (");
    if (loopVariable == null) {
      visitNode(node.identifier);
    } else {
      visitNode(loopVariable);
    }
    _writer.print(" in ");
    visitNode(node.iterator);
    _writer.print(") ");
    visitNode(node.body);
    return null;
  }

  Object visitFormalParameterList(FormalParameterList node) {
    String groupEnd = null;
    _writer.print('(');
    NodeList<FormalParameter> parameters = node.parameters;
    int size = parameters.length;
    for (int i = 0; i < size; i++) {
      FormalParameter parameter = parameters[i];
      if (i > 0) {
        _writer.print(", ");
      }
      if (groupEnd == null && parameter is DefaultFormalParameter) {
        if (identical(parameter.kind, ParameterKind.NAMED)) {
          groupEnd = "}";
          _writer.print('{');
        } else {
          groupEnd = "]";
          _writer.print('[');
        }
      }
      parameter.accept(this);
    }
    if (groupEnd != null) {
      _writer.print(groupEnd);
    }
    _writer.print(')');
    return null;
  }

  Object visitForStatement(ForStatement node) {
    Expression initialization = node.initialization;
    _writer.print("for (");
    if (initialization != null) {
      visitNode(initialization);
    } else {
      visitNode(node.variables);
    }
    _writer.print(";");
    visitNodeWithPrefix(" ", node.condition);
    _writer.print(";");
    visitNodeListWithSeparatorAndPrefix(" ", node.updaters, ", ");
    _writer.print(") ");
    visitNode(node.body);
    return null;
  }

  Object visitFunctionDeclaration(FunctionDeclaration node) {
    visitNodeWithSuffix(node.returnType, " ");
    visitTokenWithSuffix(node.propertyKeyword, " ");
    visitNode(node.name);
    visitNode(node.functionExpression);
    return null;
  }

  Object visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    visitNode(node.functionDeclaration);
    _writer.print(';');
    return null;
  }

  Object visitFunctionExpression(FunctionExpression node) {
    visitNode(node.parameters);
    _writer.print(' ');
    visitNode(node.body);
    return null;
  }

  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    visitNode(node.function);
    visitNode(node.argumentList);
    return null;
  }

  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    _writer.print("typedef ");
    visitNodeWithSuffix(node.returnType, " ");
    visitNode(node.name);
    visitNode(node.typeParameters);
    visitNode(node.parameters);
    _writer.print(";");
    return null;
  }

  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    visitNodeWithSuffix(node.returnType, " ");
    visitNode(node.identifier);
    visitNode(node.parameters);
    return null;
  }

  Object visitHideCombinator(HideCombinator node) {
    _writer.print("hide ");
    visitNodeListWithSeparator(node.hiddenNames, ", ");
    return null;
  }

  Object visitIfStatement(IfStatement node) {
    _writer.print("if (");
    visitNode(node.condition);
    _writer.print(") ");
    visitNode(node.thenStatement);
    visitNodeWithPrefix(" else ", node.elseStatement);
    return null;
  }

  Object visitImplementsClause(ImplementsClause node) {
    _writer.print("implements ");
    visitNodeListWithSeparator(node.interfaces, ", ");
    return null;
  }

  Object visitImportDirective(ImportDirective node) {
    _writer.print("import ");
    visitNode(node.uri);
    visitNodeWithPrefix(" as ", node.prefix);
    visitNodeListWithSeparatorAndPrefix(" ", node.combinators, " ");
    _writer.print(';');
    return null;
  }

  Object visitIndexExpression(IndexExpression node) {
    if (node.isCascaded) {
      _writer.print("..");
    } else {
      visitNode(node.target);
    }
    _writer.print('[');
    visitNode(node.index);
    _writer.print(']');
    return null;
  }

  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    visitTokenWithSuffix(node.keyword, " ");
    visitNode(node.constructorName);
    visitNode(node.argumentList);
    return null;
  }

  Object visitIntegerLiteral(IntegerLiteral node) {
    _writer.print(node.literal.lexeme);
    return null;
  }

  Object visitInterpolationExpression(InterpolationExpression node) {
    if (node.rightBracket != null) {
      _writer.print("\${");
      visitNode(node.expression);
      _writer.print("}");
    } else {
      _writer.print("\$");
      visitNode(node.expression);
    }
    return null;
  }

  Object visitInterpolationString(InterpolationString node) {
    _writer.print(node.contents.lexeme);
    return null;
  }

  Object visitIsExpression(IsExpression node) {
    visitNode(node.expression);
    if (node.notOperator == null) {
      _writer.print(" is ");
    } else {
      _writer.print(" is! ");
    }
    visitNode(node.type);
    return null;
  }

  Object visitLabel(Label node) {
    visitNode(node.label);
    _writer.print(":");
    return null;
  }

  Object visitLabeledStatement(LabeledStatement node) {
    visitNodeListWithSeparatorAndSuffix(node.labels, " ", " ");
    visitNode(node.statement);
    return null;
  }

  Object visitLibraryDirective(LibraryDirective node) {
    _writer.print("library ");
    visitNode(node.name);
    _writer.print(';');
    nl();
    return null;
  }

  Object visitLibraryIdentifier(LibraryIdentifier node) {
    _writer.print(node.name);
    return null;
  }

  Object visitListLiteral(ListLiteral node) {
    if (node.constKeyword != null) {
      _writer.print(node.constKeyword.lexeme);
      _writer.print(' ');
    }
    visitNodeWithSuffix(node.typeArguments, " ");
    _writer.print("[");
    {
      NodeList<Expression> elements = node.elements;
      if (elements.length < 2 || elements.toString().length < 60) {
        visitNodeListWithSeparator(elements, ", ");
      } else {
        String elementIndent = "${_indentString}    ";
        _writer.print("\n");
        _writer.print(elementIndent);
        visitNodeListWithSeparator(elements, ",\n${elementIndent}");
      }
    }
    _writer.print("]");
    return null;
  }

  Object visitMapLiteral(MapLiteral node) {
    if (node.constKeyword != null) {
      _writer.print(node.constKeyword.lexeme);
      _writer.print(' ');
    }
    visitNodeWithSuffix(node.typeArguments, " ");
    _writer.print("{");
    visitNodeListWithSeparator(node.entries, ", ");
    _writer.print("}");
    return null;
  }

  Object visitMapLiteralEntry(MapLiteralEntry node) {
    visitNode(node.key);
    _writer.print(" : ");
    visitNode(node.value);
    return null;
  }

  Object visitMethodDeclaration(MethodDeclaration node) {
    visitNode(node.documentationComment);
    visitTokenWithSuffix(node.externalKeyword, " ");
    visitTokenWithSuffix(node.modifierKeyword, " ");
    visitNodeWithSuffix(node.returnType, " ");
    visitTokenWithSuffix(node.propertyKeyword, " ");
    visitTokenWithSuffix(node.operatorKeyword, " ");
    visitNode(node.name);
    if (!node.isGetter) {
      visitNode(node.parameters);
    }
    if (node.body is! EmptyFunctionBody) {
      _writer.print(' ');
    }
    visitNode(node.body);
    return null;
  }

  Object visitMethodInvocation(MethodInvocation node) {
    if (node.isCascaded) {
      _writer.print("..");
    } else {
      visitNodeWithSuffix(node.target, ".");
    }
    visitNode(node.methodName);
    visitNode(node.argumentList);
    return null;
  }

  Object visitNamedExpression(NamedExpression node) {
    visitNode(node.name);
    visitNodeWithPrefix(" ", node.expression);
    return null;
  }

  Object visitNativeClause(NativeClause node) {
    _writer.print("native ");
    visitNode(node.name);
    return null;
  }

  Object visitNativeFunctionBody(NativeFunctionBody node) {
    _writer.print("native ");
    visitNode(node.stringLiteral);
    _writer.print(';');
    return null;
  }

  Object visitNullLiteral(NullLiteral node) {
    _writer.print("null");
    return null;
  }

  Object visitParenthesizedExpression(ParenthesizedExpression node) {
    _writer.print('(');
    visitNode(node.expression);
    _writer.print(')');
    return null;
  }

  Object visitPartDirective(PartDirective node) {
    _writer.print("part ");
    visitNode(node.uri);
    _writer.print(';');
    return null;
  }

  Object visitPartOfDirective(PartOfDirective node) {
    _writer.print("part of ");
    visitNode(node.libraryName);
    _writer.print(';');
    return null;
  }

  Object visitPostfixExpression(PostfixExpression node) {
    visitNode(node.operand);
    _writer.print(node.operator.lexeme);
    return null;
  }

  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    visitNode(node.prefix);
    _writer.print('.');
    visitNode(node.identifier);
    return null;
  }

  Object visitPrefixExpression(PrefixExpression node) {
    _writer.print(node.operator.lexeme);
    visitNode(node.operand);
    return null;
  }

  Object visitPropertyAccess(PropertyAccess node) {
    if (node.isCascaded) {
      _writer.print("..");
    } else {
      visitNodeWithSuffix(node.target, ".");
    }
    visitNode(node.propertyName);
    return null;
  }

  Object visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    _writer.print("this");
    visitNodeWithPrefix(".", node.constructorName);
    visitNode(node.argumentList);
    return null;
  }

  Object visitRethrowExpression(RethrowExpression node) {
    _writer.print("rethrow");
    return null;
  }

  Object visitReturnStatement(ReturnStatement node) {
    Expression expression = node.expression;
    if (expression == null) {
      _writer.print("return;");
    } else {
      _writer.print("return ");
      expression.accept(this);
      _writer.print(";");
    }
    return null;
  }

  Object visitScriptTag(ScriptTag node) {
    _writer.print(node.scriptTag.lexeme);
    return null;
  }

  Object visitShowCombinator(ShowCombinator node) {
    _writer.print("show ");
    visitNodeListWithSeparator(node.shownNames, ", ");
    return null;
  }

  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    visitTokenWithSuffix(node.keyword, " ");
    visitNodeWithSuffix(node.type, " ");
    visitNode(node.identifier);
    return null;
  }

  Object visitSimpleIdentifier(SimpleIdentifier node) {
    _writer.print(node.token.lexeme);
    return null;
  }

  Object visitSimpleStringLiteral(SimpleStringLiteral node) {
    _writer.print(node.literal.lexeme);
    return null;
  }

  Object visitStringInterpolation(StringInterpolation node) {
    visitNodeList(node.elements);
    return null;
  }

  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _writer.print("super");
    visitNodeWithPrefix(".", node.constructorName);
    visitNode(node.argumentList);
    return null;
  }

  Object visitSuperExpression(SuperExpression node) {
    _writer.print("super");
    return null;
  }

  Object visitSwitchCase(SwitchCase node) {
    visitNodeListWithSeparatorAndSuffix(node.labels, " ", " ");
    _writer.print("case ");
    visitNode(node.expression);
    _writer.print(": ");
    {
      indentInc();
      visitNodeListWithSeparator(node.statements, "\n");
      indentDec();
    }
    return null;
  }

  Object visitSwitchDefault(SwitchDefault node) {
    visitNodeListWithSeparatorAndSuffix(node.labels, " ", " ");
    _writer.print("default: ");
    {
      indentInc();
      visitNodeListWithSeparator(node.statements, "\n");
      indentDec();
    }
    return null;
  }

  Object visitSwitchStatement(SwitchStatement node) {
    _writer.print("switch (");
    visitNode(node.expression);
    _writer.print(") {");
    {
      indentInc();
      visitNodeListWithSeparator(node.members, "\n");
      indentDec();
    }
    nl2();
    _writer.print('}');
    return null;
  }

  Object visitSymbolLiteral(SymbolLiteral node) {
    _writer.print("#");
    visitTokenListWithSeparator(node.components, ".");
    return null;
  }

  Object visitThisExpression(ThisExpression node) {
    _writer.print("this");
    return null;
  }

  Object visitThrowExpression(ThrowExpression node) {
    _writer.print("throw ");
    visitNode(node.expression);
    return null;
  }

  Object visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    visitNodeWithSuffix(node.variables, ";");
    return null;
  }

  Object visitTryStatement(TryStatement node) {
    _writer.print("try ");
    visitNode(node.body);
    visitNodeListWithSeparatorAndPrefix(" ", node.catchClauses, " ");
    visitNodeWithPrefix(" finally ", node.finallyBlock);
    return null;
  }

  Object visitTypeArgumentList(TypeArgumentList node) {
    _writer.print('<');
    visitNodeListWithSeparator(node.arguments, ", ");
    _writer.print('>');
    return null;
  }

  Object visitTypeName(TypeName node) {
    visitNode(node.name);
    visitNode(node.typeArguments);
    return null;
  }

  Object visitTypeParameter(TypeParameter node) {
    visitNode(node.name);
    visitNodeWithPrefix(" extends ", node.bound);
    return null;
  }

  Object visitTypeParameterList(TypeParameterList node) {
    _writer.print('<');
    visitNodeListWithSeparator(node.typeParameters, ", ");
    _writer.print('>');
    return null;
  }

  Object visitVariableDeclaration(VariableDeclaration node) {
    visitNode(node.name);
    visitNodeWithPrefix(" = ", node.initializer);
    return null;
  }

  Object visitVariableDeclarationList(VariableDeclarationList node) {
    visitTokenWithSuffix(node.keyword, " ");
    visitNodeWithSuffix(node.type, " ");
    visitNodeListWithSeparator(node.variables, ", ");
    return null;
  }

  Object visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    visitNode(node.variables);
    _writer.print(";");
    return null;
  }

  Object visitWhileStatement(WhileStatement node) {
    _writer.print("while (");
    visitNode(node.condition);
    _writer.print(") ");
    visitNode(node.body);
    return null;
  }

  Object visitWithClause(WithClause node) {
    _writer.print("with ");
    visitNodeListWithSeparator(node.mixinTypes, ", ");
    return null;
  }

  void indent() {
    _writer.print(_indentString);
  }

  void indentDec() {
    _indentLevel -= 2;
    _indentString = StringUtils.repeat(" ", _indentLevel);
  }

  void indentInc() {
    _indentLevel += 2;
    _indentString = StringUtils.repeat(" ", _indentLevel);
  }

  void nl() {
    _writer.print("\n");
  }

  void nl2() {
    nl();
    indent();
  }

  void printLeadingComments(Statement statement) {
    List<String> comments = statement.getProperty(COMMENTS_KEY) as List<String>;
    if (comments == null) {
      return;
    }
    for (String comment in comments) {
      _writer.print(comment);
      _writer.print("\n");
      indent();
    }
  }

  /**
   * Safely visit the given node.
   *
   * @param node the node to be visited
   */
  void visitNode(AstNode node) {
    if (node != null) {
      node.accept(this);
    }
  }

  /**
   * Print a list of nodes without any separation.
   *
   * @param nodes the nodes to be printed
   * @param separator the separator to be printed between adjacent nodes
   */
  void visitNodeList(NodeList<AstNode> nodes) {
    visitNodeListWithSeparator(nodes, "");
  }

  /**
   * Print a list of nodes, separated by the given separator.
   *
   * @param nodes the nodes to be printed
   * @param separator the separator to be printed between adjacent nodes
   */
  void visitNodeListWithSeparator(NodeList<AstNode> nodes, String separator) {
    visitNodeListWithSeparatorPrefixAndSuffix("", nodes, separator, "");
  }

  /**
   * Print a list of nodes, separated by the given separator.
   *
   * @param prefix the prefix to be printed if the list is not empty
   * @param nodes the nodes to be printed
   * @param separator the separator to be printed between adjacent nodes
   */
  void visitNodeListWithSeparatorAndPrefix(String prefix, NodeList<AstNode> nodes, String separator) {
    visitNodeListWithSeparatorPrefixAndSuffix(prefix, nodes, separator, "");
  }

  /**
   * Print a list of nodes, separated by the given separator.
   *
   * @param nodes the nodes to be printed
   * @param separator the separator to be printed between adjacent nodes
   * @param suffix the suffix to be printed if the list is not empty
   */
  void visitNodeListWithSeparatorAndSuffix(NodeList<AstNode> nodes, String separator, String suffix) {
    visitNodeListWithSeparatorPrefixAndSuffix("", nodes, separator, suffix);
  }

  /**
   * Print a list of nodes, separated by the given separator.
   *
   * @param prefix the prefix to be printed if the list is not empty
   * @param nodes the nodes to be printed
   * @param separator the separator to be printed between adjacent nodes
   * @param suffix the suffix to be printed if the list is not empty
   */
  void visitNodeListWithSeparatorPrefixAndSuffix(String prefix, NodeList<AstNode> nodes, String separator, String suffix) {
    if (nodes != null) {
      int size = nodes.length;
      if (size != 0) {
        // prefix
        _writer.print(prefix);
        if (prefix.endsWith("\n")) {
          indent();
        }
        // nodes
        bool newLineSeparator = separator.endsWith("\n");
        for (int i = 0; i < size; i++) {
          if (i > 0) {
            _writer.print(separator);
            if (newLineSeparator) {
              indent();
            }
          }
          AstNode node = nodes[i];
          if (node is Statement) {
            printLeadingComments(node);
          }
          node.accept(this);
        }
        // suffix
        _writer.print(suffix);
      }
    }
  }

  /**
   * Safely visit the given node, printing the prefix before the node if it is non-<code>null</code>
   * .
   *
   * @param prefix the prefix to be printed if there is a node to visit
   * @param node the node to be visited
   */
  void visitNodeWithPrefix(String prefix, AstNode node) {
    if (node != null) {
      _writer.print(prefix);
      node.accept(this);
    }
  }

  /**
   * Safely visit the given node, printing the suffix after the node if it is non-<code>null</code>.
   *
   * @param suffix the suffix to be printed if there is a node to visit
   * @param node the node to be visited
   */
  void visitNodeWithSuffix(AstNode node, String suffix) {
    if (node != null) {
      node.accept(this);
      _writer.print(suffix);
    }
  }

  /**
   * Print a list of tokens, separated by the given separator.
   *
   * @param tokens the tokens to be printed
   * @param separator the separator to be printed between adjacent tokens
   */
  void visitTokenListWithSeparator(List<Token> tokens, String separator) {
    int size = tokens.length;
    for (int i = 0; i < size; i++) {
      if ("\n" == separator) {
        _writer.print("\n");
        indent();
      } else if (i > 0) {
        _writer.print(separator);
      }
      _writer.print(tokens[i].lexeme);
    }
  }

  /**
   * Safely visit the given node, printing the suffix after the node if it is non-<code>null</code>.
   *
   * @param suffix the suffix to be printed if there is a node to visit
   * @param node the node to be visited
   */
  void visitTokenWithSuffix(Token token, String suffix) {
    if (token != null) {
      _writer.print(token.lexeme);
      _writer.print(suffix);
    }
  }
}