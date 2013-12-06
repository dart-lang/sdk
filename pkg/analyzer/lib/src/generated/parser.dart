// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.parser;

import 'dart:collection';
import 'java_core.dart';
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
 *
 * @coverage dart.engine.parser
 */
class CommentAndMetadata {
  /**
   * The documentation comment that was parsed, or `null` if none was given.
   */
  Comment comment;

  /**
   * The metadata that was parsed.
   */
  List<Annotation> metadata;

  /**
   * Initialize a newly created holder with the given data.
   *
   * @param comment the documentation comment that was parsed
   * @param metadata the metadata that was parsed
   */
  CommentAndMetadata(Comment comment, List<Annotation> metadata) {
    this.comment = comment;
    this.metadata = metadata;
  }
}

/**
 * Instances of the class `FinalConstVarOrType` implement a simple data-holder for a method
 * that needs to return multiple values.
 *
 * @coverage dart.engine.parser
 */
class FinalConstVarOrType {
  /**
   * The 'final', 'const' or 'var' keyword, or `null` if none was given.
   */
  Token keyword;

  /**
   * The type, of `null` if no type was specified.
   */
  TypeName type;

  /**
   * Initialize a newly created holder with the given data.
   *
   * @param keyword the 'final', 'const' or 'var' keyword
   * @param type the type
   */
  FinalConstVarOrType(Token keyword, TypeName type) {
    this.keyword = keyword;
    this.type = type;
  }
}

/**
 * Instances of the class `Modifiers` implement a simple data-holder for a method that needs
 * to return multiple values.
 *
 * @coverage dart.engine.parser
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
class IncrementalParseDispatcher implements ASTVisitor<ASTNode> {
  /**
   * The parser used to parse the replacement for the node.
   */
  Parser _parser;

  /**
   * The node that is to be replaced.
   */
  ASTNode _oldNode;

  /**
   * Initialize a newly created dispatcher to parse a single node that will replace the given node.
   *
   * @param parser the parser used to parse the replacement for the node
   * @param oldNode the node that is to be replaced
   */
  IncrementalParseDispatcher(Parser parser, ASTNode oldNode) {
    this._parser = parser;
    this._oldNode = oldNode;
  }

  ASTNode visitAdjacentStrings(AdjacentStrings node) {
    if (node.strings.contains(_oldNode)) {
      return _parser.parseStringLiteral();
    }
    return notAChild(node);
  }

  ASTNode visitAnnotation(Annotation node) {
    if (identical(_oldNode, node.name)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.constructorName)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.arguments)) {
      return _parser.parseArgumentList();
    }
    return notAChild(node);
  }

  ASTNode visitArgumentDefinitionTest(ArgumentDefinitionTest node) {
    if (identical(_oldNode, node.identifier)) {
      return _parser.parseSimpleIdentifier();
    }
    return notAChild(node);
  }

  ASTNode visitArgumentList(ArgumentList node) {
    if (node.arguments.contains(_oldNode)) {
      return _parser.parseArgument();
    }
    return notAChild(node);
  }

  ASTNode visitAsExpression(AsExpression node) {
    if (identical(_oldNode, node.expression)) {
      return _parser.parseBitwiseOrExpression();
    } else if (identical(_oldNode, node.type)) {
      return _parser.parseTypeName();
    }
    return notAChild(node);
  }

  ASTNode visitAssertStatement(AssertStatement node) {
    if (identical(_oldNode, node.condition)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  ASTNode visitAssignmentExpression(AssignmentExpression node) {
    if (identical(_oldNode, node.leftHandSide)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.rightHandSide)) {
      if (isCascadeAllowed(node)) {
        return _parser.parseExpression2();
      }
      return _parser.parseExpressionWithoutCascade();
    }
    return notAChild(node);
  }

  ASTNode visitBinaryExpression(BinaryExpression node) {
    if (identical(_oldNode, node.leftOperand)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.rightOperand)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  ASTNode visitBlock(Block node) {
    if (node.statements.contains(_oldNode)) {
      return _parser.parseStatement2();
    }
    return notAChild(node);
  }

  ASTNode visitBlockFunctionBody(BlockFunctionBody node) {
    if (identical(_oldNode, node.block)) {
      return _parser.parseBlock();
    }
    return notAChild(node);
  }

  ASTNode visitBooleanLiteral(BooleanLiteral node) => notAChild(node);

  ASTNode visitBreakStatement(BreakStatement node) {
    if (identical(_oldNode, node.label)) {
      return _parser.parseSimpleIdentifier();
    }
    return notAChild(node);
  }

  ASTNode visitCascadeExpression(CascadeExpression node) {
    if (identical(_oldNode, node.target)) {
      return _parser.parseConditionalExpression();
    } else if (node.cascadeSections.contains(_oldNode)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  ASTNode visitCatchClause(CatchClause node) {
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

  ASTNode visitClassDeclaration(ClassDeclaration node) {
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
      return _parser.parseClassMember(node.name.name);
    }
    return notAChild(node);
  }

  ASTNode visitClassTypeAlias(ClassTypeAlias node) {
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

  ASTNode visitComment(Comment node) {
    throw new InsufficientContextException();
  }

  ASTNode visitCommentReference(CommentReference node) {
    if (identical(_oldNode, node.identifier)) {
      return _parser.parsePrefixedIdentifier();
    }
    return notAChild(node);
  }

  ASTNode visitCompilationUnit(CompilationUnit node) {
    throw new InsufficientContextException();
  }

  ASTNode visitConditionalExpression(ConditionalExpression node) {
    if (identical(_oldNode, node.condition)) {
      return _parser.parseLogicalOrExpression();
    } else if (identical(_oldNode, node.thenExpression)) {
      return _parser.parseExpressionWithoutCascade();
    } else if (identical(_oldNode, node.elseExpression)) {
      return _parser.parseExpressionWithoutCascade();
    }
    return notAChild(node);
  }

  ASTNode visitConstructorDeclaration(ConstructorDeclaration node) {
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

  ASTNode visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    if (identical(_oldNode, node.fieldName)) {
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.expression)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  ASTNode visitConstructorName(ConstructorName node) {
    if (identical(_oldNode, node.type)) {
      return _parser.parseTypeName();
    } else if (identical(_oldNode, node.name)) {
      return _parser.parseSimpleIdentifier();
    }
    return notAChild(node);
  }

  ASTNode visitContinueStatement(ContinueStatement node) {
    if (identical(_oldNode, node.label)) {
      return _parser.parseSimpleIdentifier();
    }
    return notAChild(node);
  }

  ASTNode visitDeclaredIdentifier(DeclaredIdentifier node) {
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

  ASTNode visitDefaultFormalParameter(DefaultFormalParameter node) {
    if (identical(_oldNode, node.parameter)) {
      return _parser.parseNormalFormalParameter();
    } else if (identical(_oldNode, node.defaultValue)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  ASTNode visitDoStatement(DoStatement node) {
    if (identical(_oldNode, node.body)) {
      return _parser.parseStatement2();
    } else if (identical(_oldNode, node.condition)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  ASTNode visitDoubleLiteral(DoubleLiteral node) => notAChild(node);

  ASTNode visitEmptyFunctionBody(EmptyFunctionBody node) => notAChild(node);

  ASTNode visitEmptyStatement(EmptyStatement node) => notAChild(node);

  ASTNode visitExportDirective(ExportDirective node) {
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

  ASTNode visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (identical(_oldNode, node.expression)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  ASTNode visitExpressionStatement(ExpressionStatement node) {
    if (identical(_oldNode, node.expression)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  ASTNode visitExtendsClause(ExtendsClause node) {
    if (identical(_oldNode, node.superclass)) {
      return _parser.parseTypeName();
    }
    return notAChild(node);
  }

  ASTNode visitFieldDeclaration(FieldDeclaration node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.fields)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  ASTNode visitFieldFormalParameter(FieldFormalParameter node) {
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

  ASTNode visitForEachStatement(ForEachStatement node) {
    if (identical(_oldNode, node.loopVariable)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.identifier)) {
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.body)) {
      return _parser.parseStatement2();
    }
    return notAChild(node);
  }

  ASTNode visitFormalParameterList(FormalParameterList node) {
    throw new InsufficientContextException();
  }

  ASTNode visitForStatement(ForStatement node) {
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

  ASTNode visitFunctionDeclaration(FunctionDeclaration node) {
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

  ASTNode visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    if (identical(_oldNode, node.functionDeclaration)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  ASTNode visitFunctionExpression(FunctionExpression node) {
    if (identical(_oldNode, node.parameters)) {
      return _parser.parseFormalParameterList();
    } else if (identical(_oldNode, node.body)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  ASTNode visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (identical(_oldNode, node.function)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.argumentList)) {
      return _parser.parseArgumentList();
    }
    return notAChild(node);
  }

  ASTNode visitFunctionTypeAlias(FunctionTypeAlias node) {
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

  ASTNode visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
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

  ASTNode visitHideCombinator(HideCombinator node) {
    if (node.hiddenNames.contains(_oldNode)) {
      return _parser.parseSimpleIdentifier();
    }
    return notAChild(node);
  }

  ASTNode visitIfStatement(IfStatement node) {
    if (identical(_oldNode, node.condition)) {
      return _parser.parseExpression2();
    } else if (identical(_oldNode, node.thenStatement)) {
      return _parser.parseStatement2();
    } else if (identical(_oldNode, node.elseStatement)) {
      return _parser.parseStatement2();
    }
    return notAChild(node);
  }

  ASTNode visitImplementsClause(ImplementsClause node) {
    if (node.interfaces.contains(node)) {
      return _parser.parseTypeName();
    }
    return notAChild(node);
  }

  ASTNode visitImportDirective(ImportDirective node) {
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

  ASTNode visitIndexExpression(IndexExpression node) {
    if (identical(_oldNode, node.target)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.index)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  ASTNode visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (identical(_oldNode, node.constructorName)) {
      return _parser.parseConstructorName();
    } else if (identical(_oldNode, node.argumentList)) {
      return _parser.parseArgumentList();
    }
    return notAChild(node);
  }

  ASTNode visitIntegerLiteral(IntegerLiteral node) => notAChild(node);

  ASTNode visitInterpolationExpression(InterpolationExpression node) {
    if (identical(_oldNode, node.expression)) {
      if (node.leftBracket == null) {
        throw new InsufficientContextException();
      }
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  ASTNode visitInterpolationString(InterpolationString node) {
    throw new InsufficientContextException();
  }

  ASTNode visitIsExpression(IsExpression node) {
    if (identical(_oldNode, node.expression)) {
      return _parser.parseBitwiseOrExpression();
    } else if (identical(_oldNode, node.type)) {
      return _parser.parseTypeName();
    }
    return notAChild(node);
  }

  ASTNode visitLabel(Label node) {
    if (identical(_oldNode, node.label)) {
      return _parser.parseSimpleIdentifier();
    }
    return notAChild(node);
  }

  ASTNode visitLabeledStatement(LabeledStatement node) {
    if (node.labels.contains(_oldNode)) {
      return _parser.parseLabel();
    } else if (identical(_oldNode, node.statement)) {
      return _parser.parseStatement2();
    }
    return notAChild(node);
  }

  ASTNode visitLibraryDirective(LibraryDirective node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.name)) {
      return _parser.parseLibraryIdentifier();
    }
    return notAChild(node);
  }

  ASTNode visitLibraryIdentifier(LibraryIdentifier node) {
    if (node.components.contains(_oldNode)) {
      return _parser.parseSimpleIdentifier();
    }
    return notAChild(node);
  }

  ASTNode visitListLiteral(ListLiteral node) {
    if (identical(_oldNode, node.typeArguments)) {
      return _parser.parseTypeArgumentList();
    } else if (node.elements.contains(_oldNode)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  ASTNode visitMapLiteral(MapLiteral node) {
    if (identical(_oldNode, node.typeArguments)) {
      return _parser.parseTypeArgumentList();
    } else if (node.entries.contains(_oldNode)) {
      return _parser.parseMapLiteralEntry();
    }
    return notAChild(node);
  }

  ASTNode visitMapLiteralEntry(MapLiteralEntry node) {
    if (identical(_oldNode, node.key)) {
      return _parser.parseExpression2();
    } else if (identical(_oldNode, node.value)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  ASTNode visitMethodDeclaration(MethodDeclaration node) {
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
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  ASTNode visitMethodInvocation(MethodInvocation node) {
    if (identical(_oldNode, node.target)) {
      throw new IncrementalParseException();
    } else if (identical(_oldNode, node.methodName)) {
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.argumentList)) {
      return _parser.parseArgumentList();
    }
    return notAChild(node);
  }

  ASTNode visitNamedExpression(NamedExpression node) {
    if (identical(_oldNode, node.name)) {
      return _parser.parseLabel();
    } else if (identical(_oldNode, node.expression)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  ASTNode visitNativeClause(NativeClause node) {
    if (identical(_oldNode, node.name)) {
      return _parser.parseStringLiteral();
    }
    return notAChild(node);
  }

  ASTNode visitNativeFunctionBody(NativeFunctionBody node) {
    if (identical(_oldNode, node.stringLiteral)) {
      return _parser.parseStringLiteral();
    }
    return notAChild(node);
  }

  ASTNode visitNullLiteral(NullLiteral node) => notAChild(node);

  ASTNode visitParenthesizedExpression(ParenthesizedExpression node) {
    if (identical(_oldNode, node.expression)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  ASTNode visitPartDirective(PartDirective node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.uri)) {
      return _parser.parseStringLiteral();
    }
    return notAChild(node);
  }

  ASTNode visitPartOfDirective(PartOfDirective node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.libraryName)) {
      return _parser.parseLibraryIdentifier();
    }
    return notAChild(node);
  }

  ASTNode visitPostfixExpression(PostfixExpression node) {
    if (identical(_oldNode, node.operand)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  ASTNode visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (identical(_oldNode, node.prefix)) {
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.identifier)) {
      return _parser.parseSimpleIdentifier();
    }
    return notAChild(node);
  }

  ASTNode visitPrefixExpression(PrefixExpression node) {
    if (identical(_oldNode, node.operand)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  ASTNode visitPropertyAccess(PropertyAccess node) {
    if (identical(_oldNode, node.target)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.propertyName)) {
      return _parser.parseSimpleIdentifier();
    }
    return notAChild(node);
  }

  ASTNode visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    if (identical(_oldNode, node.constructorName)) {
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.argumentList)) {
      return _parser.parseArgumentList();
    }
    return notAChild(node);
  }

  ASTNode visitRethrowExpression(RethrowExpression node) => notAChild(node);

  ASTNode visitReturnStatement(ReturnStatement node) {
    if (identical(_oldNode, node.expression)) {
      return _parser.parseExpression2();
    }
    return notAChild(node);
  }

  ASTNode visitScriptTag(ScriptTag node) => notAChild(node);

  ASTNode visitShowCombinator(ShowCombinator node) {
    if (node.shownNames.contains(_oldNode)) {
      return _parser.parseSimpleIdentifier();
    }
    return notAChild(node);
  }

  ASTNode visitSimpleFormalParameter(SimpleFormalParameter node) {
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

  ASTNode visitSimpleIdentifier(SimpleIdentifier node) => notAChild(node);

  ASTNode visitSimpleStringLiteral(SimpleStringLiteral node) => notAChild(node);

  ASTNode visitStringInterpolation(StringInterpolation node) {
    if (node.elements.contains(_oldNode)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  ASTNode visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    if (identical(_oldNode, node.constructorName)) {
      return _parser.parseSimpleIdentifier();
    } else if (identical(_oldNode, node.argumentList)) {
      return _parser.parseArgumentList();
    }
    return notAChild(node);
  }

  ASTNode visitSuperExpression(SuperExpression node) => notAChild(node);

  ASTNode visitSwitchCase(SwitchCase node) {
    if (node.labels.contains(_oldNode)) {
      return _parser.parseLabel();
    } else if (identical(_oldNode, node.expression)) {
      return _parser.parseExpression2();
    } else if (node.statements.contains(_oldNode)) {
      return _parser.parseStatement2();
    }
    return notAChild(node);
  }

  ASTNode visitSwitchDefault(SwitchDefault node) {
    if (node.labels.contains(_oldNode)) {
      return _parser.parseLabel();
    } else if (node.statements.contains(_oldNode)) {
      return _parser.parseStatement2();
    }
    return notAChild(node);
  }

  ASTNode visitSwitchStatement(SwitchStatement node) {
    if (identical(_oldNode, node.expression)) {
      return _parser.parseExpression2();
    } else if (node.members.contains(_oldNode)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  ASTNode visitSymbolLiteral(SymbolLiteral node) => notAChild(node);

  ASTNode visitThisExpression(ThisExpression node) => notAChild(node);

  ASTNode visitThrowExpression(ThrowExpression node) {
    if (identical(_oldNode, node.expression)) {
      if (isCascadeAllowed2(node)) {
        return _parser.parseExpression2();
      }
      return _parser.parseExpressionWithoutCascade();
    }
    return notAChild(node);
  }

  ASTNode visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (identical(_oldNode, node.variables)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  ASTNode visitTryStatement(TryStatement node) {
    if (identical(_oldNode, node.body)) {
      return _parser.parseBlock();
    } else if (node.catchClauses.contains(_oldNode)) {
      throw new InsufficientContextException();
    } else if (identical(_oldNode, node.finallyBlock)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  ASTNode visitTypeArgumentList(TypeArgumentList node) {
    if (node.arguments.contains(_oldNode)) {
      return _parser.parseTypeName();
    }
    return notAChild(node);
  }

  ASTNode visitTypeName(TypeName node) {
    if (identical(_oldNode, node.name)) {
      return _parser.parsePrefixedIdentifier();
    } else if (identical(_oldNode, node.typeArguments)) {
      return _parser.parseTypeArgumentList();
    }
    return notAChild(node);
  }

  ASTNode visitTypeParameter(TypeParameter node) {
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

  ASTNode visitTypeParameterList(TypeParameterList node) {
    if (node.typeParameters.contains(node)) {
      return _parser.parseTypeParameter();
    }
    return notAChild(node);
  }

  ASTNode visitVariableDeclaration(VariableDeclaration node) {
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

  ASTNode visitVariableDeclarationList(VariableDeclarationList node) {
    if (identical(_oldNode, node.documentationComment)) {
      throw new InsufficientContextException();
    } else if (node.metadata.contains(_oldNode)) {
      return _parser.parseAnnotation();
    } else if (node.variables.contains(_oldNode)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  ASTNode visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    if (identical(_oldNode, node.variables)) {
      throw new InsufficientContextException();
    }
    return notAChild(node);
  }

  ASTNode visitWhileStatement(WhileStatement node) {
    if (identical(_oldNode, node.condition)) {
      return _parser.parseExpression2();
    } else if (identical(_oldNode, node.body)) {
      return _parser.parseStatement2();
    }
    return notAChild(node);
  }

  ASTNode visitWithClause(WithClause node) {
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
  bool isCascadeAllowed(AssignmentExpression node) {
    throw new InsufficientContextException();
  }

  /**
   * Return `true` if the given throw expression can have a cascade expression.
   *
   * @param node the throw expression being tested
   * @return `true` if the expression can be a cascade expression
   */
  bool isCascadeAllowed2(ThrowExpression node) {
    throw new InsufficientContextException();
  }

  /**
   * Throw an exception indicating that the visited node was not the parent of the node to be
   * replaced.
   *
   * @param visitedNode the visited node that should have been the parent of the node to be replaced
   */
  ASTNode notAChild(ASTNode visitedNode) {
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
  ASTNode reparse(ASTNode originalStructure, Token leftToken, Token rightToken, int originalStart, int originalEnd) {
    ASTNode oldNode = null;
    ASTNode newNode = null;
    Token firstToken = leftToken.next;
    if (identical(firstToken, rightToken)) {
      firstToken = leftToken;
    }
    if (originalEnd < originalStart) {
      oldNode = new NodeLocator.con1(originalStart).searchWithin(originalStructure);
    } else {
      oldNode = new NodeLocator.con2(originalStart, originalEnd).searchWithin(originalStructure);
    }
    int originalOffset = oldNode.offset;
    Token parseToken = findTokenAt(firstToken, originalOffset);
    if (parseToken == null) {
      return null;
    }
    Parser parser = new Parser(_source, _errorListener);
    parser.currentToken = parseToken;
    while (newNode == null) {
      ASTNode parent = oldNode.parent;
      if (parent == null) {
        parseToken = findFirstToken(parseToken);
        parser.currentToken = parseToken;
        return parser.parseCompilationUnit2() as ASTNode;
      }
      bool advanceToParent = false;
      try {
        IncrementalParseDispatcher dispatcher = new IncrementalParseDispatcher(parser, oldNode);
        newNode = parent.accept(dispatcher);
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
    if (identical(oldNode, originalStructure)) {
      ResolutionCopier.copyResolutionData(oldNode, newNode);
      return newNode as ASTNode;
    }
    ResolutionCopier.copyResolutionData(oldNode, newNode);
    IncrementalASTCloner cloner = new IncrementalASTCloner(oldNode, newNode, _tokenMap);
    return originalStructure.accept(cloner) as ASTNode;
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
    if (firstToken.offset == offset) {
      return firstToken;
    }
    return null;
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
 *
 * @coverage dart.engine.parser
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
      return parseStatements2();
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
    Token atSign = expect2(TokenType.AT);
    Identifier name = parsePrefixedIdentifier();
    Token period = null;
    SimpleIdentifier constructorName = null;
    if (matches5(TokenType.PERIOD)) {
      period = andAdvance;
      constructorName = parseSimpleIdentifier();
    }
    ArgumentList arguments = null;
    if (matches5(TokenType.OPEN_PAREN)) {
      arguments = parseArgumentList();
    }
    return new Annotation.full(atSign, name, period, constructorName, arguments);
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
    if (matchesIdentifier() && matches4(peek(), TokenType.COLON)) {
      return new NamedExpression.full(parseLabel(), parseExpression2());
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
    Token leftParenthesis = expect2(TokenType.OPEN_PAREN);
    List<Expression> arguments = new List<Expression>();
    if (matches5(TokenType.CLOSE_PAREN)) {
      return new ArgumentList.full(leftParenthesis, arguments, andAdvance);
    }
    Expression argument = parseArgument();
    arguments.add(argument);
    bool foundNamedArgument = argument is NamedExpression;
    bool generatedError = false;
    while (optional(TokenType.COMMA)) {
      argument = parseArgument();
      arguments.add(argument);
      if (foundNamedArgument) {
        if (!generatedError && argument is! NamedExpression) {
          reportError10(ParserErrorCode.POSITIONAL_AFTER_NAMED_ARGUMENT, []);
          generatedError = true;
        }
      } else if (argument is NamedExpression) {
        foundNamedArgument = true;
      }
    }
    Token rightParenthesis = expect2(TokenType.CLOSE_PAREN);
    return new ArgumentList.full(leftParenthesis, arguments, rightParenthesis);
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
    if (matches(Keyword.SUPER) && matches4(peek(), TokenType.BAR)) {
      expression = new SuperExpression.full(andAdvance);
    } else {
      expression = parseBitwiseXorExpression();
    }
    while (matches5(TokenType.BAR)) {
      Token operator = andAdvance;
      expression = new BinaryExpression.full(expression, operator, parseBitwiseXorExpression());
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
    Token leftBracket = expect2(TokenType.OPEN_CURLY_BRACKET);
    List<Statement> statements = new List<Statement>();
    Token statementStart = _currentToken;
    while (!matches5(TokenType.EOF) && !matches5(TokenType.CLOSE_CURLY_BRACKET)) {
      Statement statement = parseStatement2();
      if (statement != null) {
        statements.add(statement);
      }
      if (identical(_currentToken, statementStart)) {
        reportError11(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken, [_currentToken.lexeme]);
        advance();
      }
      statementStart = _currentToken;
    }
    Token rightBracket = expect2(TokenType.CLOSE_CURLY_BRACKET);
    return new Block.full(leftBracket, statements, rightBracket);
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
    if (matches(Keyword.VOID)) {
      TypeName returnType = parseReturnType();
      if (matches(Keyword.GET) && matchesIdentifier2(peek())) {
        validateModifiersForGetterOrSetterOrMethod(modifiers);
        return parseGetter(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, returnType);
      } else if (matches(Keyword.SET) && matchesIdentifier2(peek())) {
        validateModifiersForGetterOrSetterOrMethod(modifiers);
        return parseSetter(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, returnType);
      } else if (matches(Keyword.OPERATOR) && isOperator(peek())) {
        validateModifiersForOperator(modifiers);
        return parseOperator(commentAndMetadata, modifiers.externalKeyword, returnType);
      } else if (matchesIdentifier() && matchesAny(peek(), [
          TokenType.OPEN_PAREN,
          TokenType.OPEN_CURLY_BRACKET,
          TokenType.FUNCTION])) {
        validateModifiersForGetterOrSetterOrMethod(modifiers);
        return parseMethodDeclaration(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, returnType);
      } else {
        if (matchesIdentifier()) {
          if (matchesAny(peek(), [TokenType.EQ, TokenType.COMMA, TokenType.SEMICOLON])) {
            reportError9(ParserErrorCode.VOID_VARIABLE, returnType, []);
            return parseInitializedIdentifierList(commentAndMetadata, modifiers.staticKeyword, validateModifiersForField(modifiers), returnType);
          }
        }
        if (isOperator(_currentToken)) {
          validateModifiersForOperator(modifiers);
          return parseOperator(commentAndMetadata, modifiers.externalKeyword, returnType);
        }
        reportError11(ParserErrorCode.EXPECTED_EXECUTABLE, _currentToken, []);
        return null;
      }
    } else if (matches(Keyword.GET) && matchesIdentifier2(peek())) {
      validateModifiersForGetterOrSetterOrMethod(modifiers);
      return parseGetter(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, null);
    } else if (matches(Keyword.SET) && matchesIdentifier2(peek())) {
      validateModifiersForGetterOrSetterOrMethod(modifiers);
      return parseSetter(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, null);
    } else if (matches(Keyword.OPERATOR) && isOperator(peek())) {
      validateModifiersForOperator(modifiers);
      return parseOperator(commentAndMetadata, modifiers.externalKeyword, null);
    } else if (!matchesIdentifier()) {
      if (isOperator(_currentToken)) {
        validateModifiersForOperator(modifiers);
        return parseOperator(commentAndMetadata, modifiers.externalKeyword, null);
      }
      reportError11(ParserErrorCode.EXPECTED_CLASS_MEMBER, _currentToken, []);
      return null;
    } else if (matches4(peek(), TokenType.PERIOD) && matchesIdentifier2(peek2(2)) && matches4(peek2(3), TokenType.OPEN_PAREN)) {
      return parseConstructor(commentAndMetadata, modifiers.externalKeyword, validateModifiersForConstructor(modifiers), modifiers.factoryKeyword, parseSimpleIdentifier(), andAdvance, parseSimpleIdentifier(), parseFormalParameterList());
    } else if (matches4(peek(), TokenType.OPEN_PAREN)) {
      SimpleIdentifier methodName = parseSimpleIdentifier();
      FormalParameterList parameters = parseFormalParameterList();
      if (matches5(TokenType.COLON) || modifiers.factoryKeyword != null || methodName.name == className) {
        return parseConstructor(commentAndMetadata, modifiers.externalKeyword, validateModifiersForConstructor(modifiers), modifiers.factoryKeyword, methodName, null, null, parameters);
      }
      validateModifiersForGetterOrSetterOrMethod(modifiers);
      validateFormalParameterList(parameters);
      return parseMethodDeclaration2(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, null, methodName, parameters);
    } else if (matchesAny(peek(), [TokenType.EQ, TokenType.COMMA, TokenType.SEMICOLON])) {
      if (modifiers.constKeyword == null && modifiers.finalKeyword == null && modifiers.varKeyword == null) {
        reportError10(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, []);
      }
      return parseInitializedIdentifierList(commentAndMetadata, modifiers.staticKeyword, validateModifiersForField(modifiers), null);
    }
    TypeName type = parseTypeName();
    if (matches(Keyword.GET) && matchesIdentifier2(peek())) {
      validateModifiersForGetterOrSetterOrMethod(modifiers);
      return parseGetter(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, type);
    } else if (matches(Keyword.SET) && matchesIdentifier2(peek())) {
      validateModifiersForGetterOrSetterOrMethod(modifiers);
      return parseSetter(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, type);
    } else if (matches(Keyword.OPERATOR) && isOperator(peek())) {
      validateModifiersForOperator(modifiers);
      return parseOperator(commentAndMetadata, modifiers.externalKeyword, type);
    } else if (!matchesIdentifier()) {
      if (matches5(TokenType.CLOSE_CURLY_BRACKET)) {
        return parseInitializedIdentifierList(commentAndMetadata, modifiers.staticKeyword, validateModifiersForField(modifiers), type);
      }
      if (isOperator(_currentToken)) {
        validateModifiersForOperator(modifiers);
        return parseOperator(commentAndMetadata, modifiers.externalKeyword, type);
      }
      reportError11(ParserErrorCode.EXPECTED_CLASS_MEMBER, _currentToken, []);
      try {
        lockErrorListener();
        return parseInitializedIdentifierList(commentAndMetadata, modifiers.staticKeyword, validateModifiersForField(modifiers), type);
      } finally {
        unlockErrorListener();
      }
    } else if (matches4(peek(), TokenType.OPEN_PAREN)) {
      SimpleIdentifier methodName = parseSimpleIdentifier();
      FormalParameterList parameters = parseFormalParameterList();
      if (methodName.name == className) {
        reportError9(ParserErrorCode.CONSTRUCTOR_WITH_RETURN_TYPE, type, []);
        return parseConstructor(commentAndMetadata, modifiers.externalKeyword, validateModifiersForConstructor(modifiers), modifiers.factoryKeyword, methodName, null, null, parameters);
      }
      validateModifiersForGetterOrSetterOrMethod(modifiers);
      validateFormalParameterList(parameters);
      return parseMethodDeclaration2(commentAndMetadata, modifiers.externalKeyword, modifiers.staticKeyword, type, methodName, parameters);
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
    if (matches5(TokenType.SCRIPT_TAG)) {
      scriptTag = new ScriptTag.full(andAdvance);
    }
    bool libraryDirectiveFound = false;
    bool partOfDirectiveFound = false;
    bool partDirectiveFound = false;
    bool directiveFoundAfterDeclaration = false;
    List<Directive> directives = new List<Directive>();
    List<CompilationUnitMember> declarations = new List<CompilationUnitMember>();
    Token memberStart = _currentToken;
    while (!matches5(TokenType.EOF)) {
      CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
      if ((matches(Keyword.IMPORT) || matches(Keyword.EXPORT) || matches(Keyword.LIBRARY) || matches(Keyword.PART)) && !matches4(peek(), TokenType.PERIOD) && !matches4(peek(), TokenType.LT) && !matches4(peek(), TokenType.OPEN_PAREN)) {
        Directive directive = parseDirective(commentAndMetadata);
        if (declarations.length > 0 && !directiveFoundAfterDeclaration) {
          reportError10(ParserErrorCode.DIRECTIVE_AFTER_DECLARATION, []);
          directiveFoundAfterDeclaration = true;
        }
        if (directive is LibraryDirective) {
          if (libraryDirectiveFound) {
            reportError10(ParserErrorCode.MULTIPLE_LIBRARY_DIRECTIVES, []);
          } else {
            if (directives.length > 0) {
              reportError10(ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST, []);
            }
            libraryDirectiveFound = true;
          }
        } else if (directive is PartDirective) {
          partDirectiveFound = true;
        } else if (partDirectiveFound) {
          if (directive is ExportDirective) {
            reportError11(ParserErrorCode.EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE, (directive as NamespaceDirective).keyword, []);
          } else if (directive is ImportDirective) {
            reportError11(ParserErrorCode.IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE, (directive as NamespaceDirective).keyword, []);
          }
        }
        if (directive is PartOfDirective) {
          if (partOfDirectiveFound) {
            reportError10(ParserErrorCode.MULTIPLE_PART_OF_DIRECTIVES, []);
          } else {
            int directiveCount = directives.length;
            for (int i = 0; i < directiveCount; i++) {
              reportError11(ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART, directives[i].keyword, []);
            }
            partOfDirectiveFound = true;
          }
        } else {
          if (partOfDirectiveFound) {
            reportError11(ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART, directive.keyword, []);
          }
        }
        directives.add(directive);
      } else if (matches5(TokenType.SEMICOLON)) {
        reportError11(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken, [_currentToken.lexeme]);
        advance();
      } else {
        CompilationUnitMember member = parseCompilationUnitMember(commentAndMetadata);
        if (member != null) {
          declarations.add(member);
        }
      }
      if (identical(_currentToken, memberStart)) {
        reportError11(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken, [_currentToken.lexeme]);
        advance();
        while (!matches5(TokenType.EOF) && !couldBeStartOfCompilationUnitMember()) {
          advance();
        }
      }
      memberStart = _currentToken;
    }
    return new CompilationUnit.full(firstToken, scriptTag, directives, declarations, _currentToken);
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
    if (!matches5(TokenType.QUESTION)) {
      return condition;
    }
    Token question = andAdvance;
    Expression thenExpression = parseExpressionWithoutCascade();
    Token colon = expect2(TokenType.COLON);
    Expression elseExpression = parseExpressionWithoutCascade();
    return new ConditionalExpression.full(condition, question, thenExpression, colon, elseExpression);
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
    if (matches5(TokenType.PERIOD)) {
      period = andAdvance;
      name = parseSimpleIdentifier();
    }
    return new ConstructorName.full(type, period, name);
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
    if (matches(Keyword.THROW)) {
      return parseThrowExpression();
    } else if (matches(Keyword.RETHROW)) {
      return parseRethrowExpression();
    }
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
      return new CascadeExpression.full(expression, cascadeSections);
    } else if (tokenType.isAssignmentOperator) {
      Token operator = andAdvance;
      ensureAssignable(expression);
      return new AssignmentExpression.full(expression, operator, parseExpression2());
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
    if (matches(Keyword.THROW)) {
      return parseThrowExpressionWithoutCascade();
    } else if (matches(Keyword.RETHROW)) {
      return parseRethrowExpression();
    }
    Expression expression = parseConditionalExpression();
    if (_currentToken.type.isAssignmentOperator) {
      Token operator = andAdvance;
      ensureAssignable(expression);
      expression = new AssignmentExpression.full(expression, operator, parseExpressionWithoutCascade());
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
    Token keyword = expect(Keyword.EXTENDS);
    TypeName superclass = parseTypeName();
    return new ExtendsClause.full(keyword, superclass);
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
    Token leftParenthesis = expect2(TokenType.OPEN_PAREN);
    if (matches5(TokenType.CLOSE_PAREN)) {
      return new FormalParameterList.full(leftParenthesis, null, null, null, andAdvance);
    }
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
        if (getEndToken(leftParenthesis) != null) {
          reportError10(ParserErrorCode.EXPECTED_TOKEN, [TokenType.COMMA.lexeme]);
        } else {
          reportError11(ParserErrorCode.MISSING_CLOSING_PARENTHESIS, _currentToken.previous, []);
          break;
        }
      }
      initialToken = _currentToken;
      if (matches5(TokenType.OPEN_SQUARE_BRACKET)) {
        wasOptionalParameter = true;
        if (leftSquareBracket != null && !reportedMuliplePositionalGroups) {
          reportError10(ParserErrorCode.MULTIPLE_POSITIONAL_PARAMETER_GROUPS, []);
          reportedMuliplePositionalGroups = true;
        }
        if (leftCurlyBracket != null && !reportedMixedGroups) {
          reportError10(ParserErrorCode.MIXED_PARAMETER_GROUPS, []);
          reportedMixedGroups = true;
        }
        leftSquareBracket = andAdvance;
        currentParameters = positionalParameters;
        kind = ParameterKind.POSITIONAL;
      } else if (matches5(TokenType.OPEN_CURLY_BRACKET)) {
        wasOptionalParameter = true;
        if (leftCurlyBracket != null && !reportedMulipleNamedGroups) {
          reportError10(ParserErrorCode.MULTIPLE_NAMED_PARAMETER_GROUPS, []);
          reportedMulipleNamedGroups = true;
        }
        if (leftSquareBracket != null && !reportedMixedGroups) {
          reportError10(ParserErrorCode.MIXED_PARAMETER_GROUPS, []);
          reportedMixedGroups = true;
        }
        leftCurlyBracket = andAdvance;
        currentParameters = namedParameters;
        kind = ParameterKind.NAMED;
      }
      FormalParameter parameter = parseFormalParameter(kind);
      parameters.add(parameter);
      currentParameters.add(parameter);
      if (identical(kind, ParameterKind.REQUIRED) && wasOptionalParameter) {
        reportError9(ParserErrorCode.NORMAL_BEFORE_OPTIONAL_PARAMETERS, parameter, []);
      }
      if (matches5(TokenType.CLOSE_SQUARE_BRACKET)) {
        rightSquareBracket = andAdvance;
        currentParameters = normalParameters;
        if (leftSquareBracket == null) {
          if (leftCurlyBracket != null) {
            reportError10(ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP, ["}"]);
            rightCurlyBracket = rightSquareBracket;
            rightSquareBracket = null;
          } else {
            reportError10(ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP, ["["]);
          }
        }
        kind = ParameterKind.REQUIRED;
      } else if (matches5(TokenType.CLOSE_CURLY_BRACKET)) {
        rightCurlyBracket = andAdvance;
        currentParameters = normalParameters;
        if (leftCurlyBracket == null) {
          if (leftSquareBracket != null) {
            reportError10(ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP, ["]"]);
            rightSquareBracket = rightCurlyBracket;
            rightCurlyBracket = null;
          } else {
            reportError10(ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP, ["{"]);
          }
        }
        kind = ParameterKind.REQUIRED;
      }
    } while (!matches5(TokenType.CLOSE_PAREN) && initialToken != _currentToken);
    Token rightParenthesis = expect2(TokenType.CLOSE_PAREN);
    if (leftSquareBracket != null && rightSquareBracket == null) {
      reportError10(ParserErrorCode.MISSING_TERMINATOR_FOR_PARAMETER_GROUP, ["]"]);
    }
    if (leftCurlyBracket != null && rightCurlyBracket == null) {
      reportError10(ParserErrorCode.MISSING_TERMINATOR_FOR_PARAMETER_GROUP, ["}"]);
    }
    if (leftSquareBracket == null) {
      leftSquareBracket = leftCurlyBracket;
    }
    if (rightSquareBracket == null) {
      rightSquareBracket = rightCurlyBracket;
    }
    return new FormalParameterList.full(leftParenthesis, parameters, leftSquareBracket, rightSquareBracket, rightParenthesis);
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
    return new FunctionExpression.full(parameters, body);
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
    Token keyword = expect(Keyword.IMPLEMENTS);
    List<TypeName> interfaces = new List<TypeName>();
    interfaces.add(parseTypeName());
    while (optional(TokenType.COMMA)) {
      interfaces.add(parseTypeName());
    }
    return new ImplementsClause.full(keyword, interfaces);
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
    Token colon = expect2(TokenType.COLON);
    return new Label.full(label, colon);
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
    while (matches5(TokenType.PERIOD)) {
      advance();
      components.add(parseSimpleIdentifier());
    }
    return new LibraryIdentifier.full(components);
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
    while (matches5(TokenType.BAR_BAR)) {
      Token operator = andAdvance;
      expression = new BinaryExpression.full(expression, operator, parseLogicalAndExpression());
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
    Token separator = expect2(TokenType.COLON);
    Expression value = parseExpression2();
    return new MapLiteralEntry.full(key, separator, value);
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
    if (matches(Keyword.THIS)) {
      thisKeyword = andAdvance;
      period = expect2(TokenType.PERIOD);
    }
    SimpleIdentifier identifier = parseSimpleIdentifier();
    if (matches5(TokenType.OPEN_PAREN)) {
      FormalParameterList parameters = parseFormalParameterList();
      if (thisKeyword == null) {
        if (holder.keyword != null) {
          reportError11(ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR, holder.keyword, []);
        }
        return new FunctionTypedFormalParameter.full(commentAndMetadata.comment, commentAndMetadata.metadata, holder.type, identifier, parameters);
      } else {
        return new FieldFormalParameter.full(commentAndMetadata.comment, commentAndMetadata.metadata, holder.keyword, holder.type, thisKeyword, period, identifier, parameters);
      }
    }
    TypeName type = holder.type;
    if (type != null) {
      if (matches3(type.name.beginToken, Keyword.VOID)) {
        reportError11(ParserErrorCode.VOID_PARAMETER, type.name.beginToken, []);
      } else if (holder.keyword != null && matches3(holder.keyword, Keyword.VAR)) {
        reportError11(ParserErrorCode.VAR_AND_TYPE, holder.keyword, []);
      }
    }
    if (thisKeyword != null) {
      return new FieldFormalParameter.full(commentAndMetadata.comment, commentAndMetadata.metadata, holder.keyword, holder.type, thisKeyword, period, identifier, null);
    }
    return new SimpleFormalParameter.full(commentAndMetadata.comment, commentAndMetadata.metadata, holder.keyword, holder.type, identifier);
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
    if (!matches5(TokenType.PERIOD)) {
      return qualifier;
    }
    Token period = andAdvance;
    SimpleIdentifier qualified = parseSimpleIdentifier();
    return new PrefixedIdentifier.full(qualifier, period, qualified);
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
    if (matches(Keyword.VOID)) {
      return new TypeName.full(new SimpleIdentifier.full(andAdvance), null);
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
      return new SimpleIdentifier.full(andAdvance);
    }
    reportError10(ParserErrorCode.MISSING_IDENTIFIER, []);
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
    while (matchesIdentifier() && matches4(peek(), TokenType.COLON)) {
      labels.add(parseLabel());
    }
    Statement statement = parseNonLabeledStatement();
    if (labels.isEmpty) {
      return statement;
    }
    return new LabeledStatement.full(labels, statement);
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
    while (matches5(TokenType.STRING)) {
      Token string = andAdvance;
      if (matches5(TokenType.STRING_INTERPOLATION_EXPRESSION) || matches5(TokenType.STRING_INTERPOLATION_IDENTIFIER)) {
        strings.add(parseStringInterpolation(string));
      } else {
        strings.add(new SimpleStringLiteral.full(string, computeStringValue(string.lexeme, true, true)));
      }
    }
    if (strings.length < 1) {
      reportError10(ParserErrorCode.EXPECTED_STRING_LITERAL, []);
      return createSyntheticStringLiteral();
    } else if (strings.length == 1) {
      return strings[0];
    } else {
      return new AdjacentStrings.full(strings);
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
    Token leftBracket = expect2(TokenType.LT);
    List<TypeName> arguments = new List<TypeName>();
    arguments.add(parseTypeName());
    while (optional(TokenType.COMMA)) {
      arguments.add(parseTypeName());
    }
    Token rightBracket = expect2(TokenType.GT);
    return new TypeArgumentList.full(leftBracket, arguments, rightBracket);
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
    if (matches(Keyword.VAR)) {
      reportError10(ParserErrorCode.VAR_AS_TYPE_NAME, []);
      typeName = new SimpleIdentifier.full(andAdvance);
    } else if (matchesIdentifier()) {
      typeName = parsePrefixedIdentifier();
    } else {
      typeName = createSyntheticIdentifier();
      reportError10(ParserErrorCode.EXPECTED_TYPE_NAME, []);
    }
    TypeArgumentList typeArguments = null;
    if (matches5(TokenType.LT)) {
      typeArguments = parseTypeArgumentList();
    }
    return new TypeName.full(typeName, typeArguments);
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
    if (matches(Keyword.EXTENDS)) {
      Token keyword = andAdvance;
      TypeName bound = parseTypeName();
      return new TypeParameter.full(commentAndMetadata.comment, commentAndMetadata.metadata, name, keyword, bound);
    }
    return new TypeParameter.full(commentAndMetadata.comment, commentAndMetadata.metadata, name, null, null);
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
    Token leftBracket = expect2(TokenType.LT);
    List<TypeParameter> typeParameters = new List<TypeParameter>();
    typeParameters.add(parseTypeParameter());
    while (optional(TokenType.COMMA)) {
      typeParameters.add(parseTypeParameter());
    }
    Token rightBracket = expect2(TokenType.GT);
    return new TypeParameterList.full(leftBracket, typeParameters, rightBracket);
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
    Token with2 = expect(Keyword.WITH);
    List<TypeName> types = new List<TypeName>();
    types.add(parseTypeName());
    while (optional(TokenType.COMMA)) {
      types.add(parseTypeName());
    }
    return new WithClause.full(with2, types);
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
      reportError10(ParserErrorCode.INVALID_CODE_POINT, [escapeSequence]);
      return;
    }
    if (scalarValue < Character.MAX_VALUE) {
      builder.appendChar(scalarValue as int);
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
      if (lexeme.startsWith("r\"\"\"") || lexeme.startsWith("r'''")) {
        isRaw = true;
        start += 4;
      } else if (lexeme.startsWith("r\"") || lexeme.startsWith("r'")) {
        isRaw = true;
        start += 2;
      } else if (lexeme.startsWith("\"\"\"") || lexeme.startsWith("'''")) {
        start += 3;
      } else if (lexeme.startsWith("\"") || lexeme.startsWith("'")) {
        start += 1;
      }
    }
    int end = lexeme.length;
    if (last) {
      if (lexeme.endsWith("\"\"\"") || lexeme.endsWith("'''")) {
        end -= 3;
      } else if (lexeme.endsWith("\"") || lexeme.endsWith("'")) {
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
  FunctionDeclaration convertToFunctionDeclaration(MethodDeclaration method) => new FunctionDeclaration.full(method.documentationComment, method.metadata, method.externalKeyword, method.returnType, method.propertyKeyword, method.name, new FunctionExpression.full(method.parameters, method.body));

  /**
   * Return `true` if the current token could be the start of a compilation unit member. This
   * method is used for recovery purposes to decide when to stop skipping tokens after finding an
   * error while parsing a compilation unit member.
   *
   * @return `true` if the current token could be the start of a compilation unit member
   */
  bool couldBeStartOfCompilationUnitMember() {
    if ((matches(Keyword.IMPORT) || matches(Keyword.EXPORT) || matches(Keyword.LIBRARY) || matches(Keyword.PART)) && !matches4(peek(), TokenType.PERIOD) && !matches4(peek(), TokenType.LT)) {
      return true;
    } else if (matches(Keyword.CLASS)) {
      return true;
    } else if (matches(Keyword.TYPEDEF) && !matches4(peek(), TokenType.PERIOD) && !matches4(peek(), TokenType.LT)) {
      return true;
    } else if (matches(Keyword.VOID) || ((matches(Keyword.GET) || matches(Keyword.SET)) && matchesIdentifier2(peek())) || (matches(Keyword.OPERATOR) && isOperator(peek()))) {
      return true;
    } else if (matchesIdentifier()) {
      if (matches4(peek(), TokenType.OPEN_PAREN)) {
        return true;
      }
      Token token = skipReturnType(_currentToken);
      if (token == null) {
        return false;
      }
      if (matches(Keyword.GET) || matches(Keyword.SET) || (matches(Keyword.OPERATOR) && isOperator(peek())) || matchesIdentifier()) {
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
      syntheticToken = injectToken(new SyntheticStringToken(TokenType.IDENTIFIER, _currentToken.lexeme, _currentToken.offset));
    } else {
      syntheticToken = createSyntheticToken2(TokenType.IDENTIFIER);
    }
    return new SimpleIdentifier.full(syntheticToken);
  }

  /**
   * Create a synthetic string literal.
   *
   * @return the synthetic string literal that was created
   */
  SimpleStringLiteral createSyntheticStringLiteral() => new SimpleStringLiteral.full(createSyntheticToken2(TokenType.STRING), "");

  /**
   * Create a synthetic token representing the given keyword.
   *
   * @return the synthetic token that was created
   */
  Token createSyntheticToken(Keyword keyword) => injectToken(new Parser_SyntheticKeywordToken(keyword, _currentToken.offset));

  /**
   * Create a synthetic token with the given type.
   *
   * @return the synthetic token that was created
   */
  Token createSyntheticToken2(TokenType type) => injectToken(new StringToken(type, "", _currentToken.offset));

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
      reportError10(ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE, []);
    }
  }

  /**
   * If the current token is a keyword matching the given string, return it after advancing to the
   * next token. Otherwise report an error and return the current token without advancing.
   *
   * @param keyword the keyword that is expected
   * @return the token that matched the given type
   */
  Token expect(Keyword keyword) {
    if (matches(keyword)) {
      return andAdvance;
    }
    reportError10(ParserErrorCode.EXPECTED_TOKEN, [keyword.syntax]);
    return _currentToken;
  }

  /**
   * If the current token has the expected type, return it after advancing to the next token.
   * Otherwise report an error and return the current token without advancing.
   *
   * @param type the type of token that is expected
   * @return the token that matched the given type
   */
  Token expect2(TokenType type) {
    if (matches5(type)) {
      return andAdvance;
    }
    if (identical(type, TokenType.SEMICOLON)) {
      reportError11(ParserErrorCode.EXPECTED_TOKEN, _currentToken.previous, [type.lexeme]);
    } else {
      reportError10(ParserErrorCode.EXPECTED_TOKEN, [type.lexeme]);
    }
    return _currentToken;
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
    int index = 0;
    if (comment.startsWith("/**") || comment.startsWith("///")) {
      index = 3;
    }
    while (index < length) {
      int currentChar = comment.codeUnitAt(index);
      if (currentChar == 0xD || currentChar == 0xA) {
        index = index + 1;
        while (index < length && Character.isWhitespace(comment.codeUnitAt(index))) {
          index = index + 1;
        }
        if (JavaString.startsWithBefore(comment, "*     ", index)) {
          int end = index + 6;
          while (end < length && comment.codeUnitAt(end) != 0xD && comment.codeUnitAt(end) != 0xA) {
            end = end + 1;
          }
          ranges.add(<int> [index, end]);
          index = end;
        }
      } else if (JavaString.startsWithBefore(comment, "[:", index)) {
        int end = JavaString.indexOf(comment, ":]", index + 2);
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
      return (beginToken as BeginToken).endToken;
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
    return matchesIdentifier2(next);
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
    if (matches(Keyword.VOID)) {
      return true;
    }
    Token afterReturnType = skipTypeName(_currentToken);
    if (afterReturnType == null) {
      afterReturnType = _currentToken;
    }
    Token afterIdentifier = skipSimpleIdentifier(afterReturnType);
    if (afterIdentifier == null) {
      afterIdentifier = skipSimpleIdentifier(_currentToken);
    }
    if (afterIdentifier == null) {
      return false;
    }
    if (isFunctionExpression(afterIdentifier)) {
      return true;
    }
    if (matches(Keyword.GET)) {
      Token afterName = skipSimpleIdentifier(_currentToken.next);
      if (afterName == null) {
        return false;
      }
      return matches4(afterName, TokenType.FUNCTION) || matches4(afterName, TokenType.OPEN_CURLY_BRACKET);
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
    if (matches(Keyword.FINAL) || matches(Keyword.VAR)) {
      return true;
    }
    if (matches(Keyword.CONST)) {
      return !matchesAny(peek(), [
          TokenType.LT,
          TokenType.OPEN_CURLY_BRACKET,
          TokenType.OPEN_SQUARE_BRACKET,
          TokenType.INDEX]);
    }
    Token token = skipTypeName(_currentToken);
    if (token == null) {
      return false;
    }
    token = skipSimpleIdentifier(token);
    if (token == null) {
      return false;
    }
    TokenType type = token.type;
    return identical(type, TokenType.EQ) || identical(type, TokenType.COMMA) || identical(type, TokenType.SEMICOLON) || matches3(token, Keyword.IN);
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
    if (!startToken.isOperator) {
      return false;
    }
    if (identical(startToken.type, TokenType.EQ)) {
      return false;
    }
    Token token = startToken.next;
    while (token.isOperator) {
      token = token.next;
    }
    return matches4(token, TokenType.OPEN_PAREN);
  }

  /**
   * Return `true` if the current token appears to be the beginning of a switch member.
   *
   * @return `true` if the current token appears to be the beginning of a switch member
   */
  bool isSwitchMember() {
    Token token = _currentToken;
    while (matches4(token, TokenType.IDENTIFIER) && matches4(token.next, TokenType.COLON)) {
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
    } else if (matchesIdentifier2(token)) {
      return true;
    } else if (matches3(token, Keyword.THIS) && matches4(token.next, TokenType.PERIOD) && matchesIdentifier2(token.next.next)) {
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
   * Return `true` if the current token matches the given keyword.
   *
   * @param keyword the keyword that can optionally appear in the current location
   * @return `true` if the current token matches the given keyword
   */
  bool matches(Keyword keyword) => matches3(_currentToken, keyword);

  /**
   * Return `true` if the current token matches the given identifier.
   *
   * @param identifier the identifier that can optionally appear in the current location
   * @return `true` if the current token matches the given identifier
   */
  bool matches2(String identifier) => identical(_currentToken.type, TokenType.IDENTIFIER) && _currentToken.lexeme == identifier;

  /**
   * Return `true` if the given token matches the given keyword.
   *
   * @param token the token being tested
   * @param keyword the keyword that is being tested for
   * @return `true` if the given token matches the given keyword
   */
  bool matches3(Token token, Keyword keyword) => identical(token.type, TokenType.KEYWORD) && identical((token as KeywordToken).keyword, keyword);

  /**
   * Return `true` if the given token has the given type.
   *
   * @param token the token being tested
   * @param type the type of token that is being tested for
   * @return `true` if the given token has the given type
   */
  bool matches4(Token token, TokenType type) => identical(token.type, type);

  /**
   * Return `true` if the current token has the given type. Note that this method, unlike
   * other variants, will modify the token stream if possible to match a wider range of tokens. In
   * particular, if we are attempting to match a '>' and the next token is either a '>>' or '>>>',
   * the token stream will be re-written and `true` will be returned.
   *
   * @param type the type of token that can optionally appear in the current location
   * @return `true` if the current token has the given type
   */
  bool matches5(TokenType type) {
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
  bool matchesIdentifier() => matchesIdentifier2(_currentToken);

  /**
   * Return `true` if the given token is a valid identifier. Valid identifiers include
   * built-in identifiers (pseudo-keywords).
   *
   * @return `true` if the given token is a valid identifier
   */
  bool matchesIdentifier2(Token token) => matches4(token, TokenType.IDENTIFIER) || (matches4(token, TokenType.KEYWORD) && (token as KeywordToken).keyword.isPseudoKeyword);

  /**
   * If the current token has the given type, then advance to the next token and return `true`
   * . Otherwise, return `false` without advancing.
   *
   * @param type the type of token that can optionally appear in the current location
   * @return `true` if the current token has the given type
   */
  bool optional(TokenType type) {
    if (matches5(type)) {
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
    if (matches(Keyword.SUPER) && _currentToken.next.type.isAdditiveOperator) {
      expression = new SuperExpression.full(andAdvance);
    } else {
      expression = parseMultiplicativeExpression();
    }
    while (_currentToken.type.isAdditiveOperator) {
      Token operator = andAdvance;
      expression = new BinaryExpression.full(expression, operator, parseMultiplicativeExpression());
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
    Token question = expect2(TokenType.QUESTION);
    SimpleIdentifier identifier = parseSimpleIdentifier();
    reportError11(ParserErrorCode.DEPRECATED_ARGUMENT_DEFINITION_TEST, question, []);
    return new ArgumentDefinitionTest.full(question, identifier);
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
    Token keyword = expect(Keyword.ASSERT);
    Token leftParen = expect2(TokenType.OPEN_PAREN);
    Expression expression = parseExpression2();
    if (expression is AssignmentExpression) {
      reportError9(ParserErrorCode.ASSERT_DOES_NOT_TAKE_ASSIGNMENT, expression, []);
    } else if (expression is CascadeExpression) {
      reportError9(ParserErrorCode.ASSERT_DOES_NOT_TAKE_CASCADE, expression, []);
    } else if (expression is ThrowExpression) {
      reportError9(ParserErrorCode.ASSERT_DOES_NOT_TAKE_THROW, expression, []);
    } else if (expression is RethrowExpression) {
      reportError9(ParserErrorCode.ASSERT_DOES_NOT_TAKE_RETHROW, expression, []);
    }
    Token rightParen = expect2(TokenType.CLOSE_PAREN);
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new AssertStatement.full(keyword, leftParen, expression, rightParen, semicolon);
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
    if (matches(Keyword.SUPER)) {
      return parseAssignableSelector(new SuperExpression.full(andAdvance), false);
    }
    Expression expression = parsePrimaryExpression();
    bool isOptional = primaryAllowed || expression is SimpleIdentifier;
    while (true) {
      while (matches5(TokenType.OPEN_PAREN)) {
        ArgumentList argumentList = parseArgumentList();
        if (expression is SimpleIdentifier) {
          expression = new MethodInvocation.full(null, null, expression as SimpleIdentifier, argumentList);
        } else if (expression is PrefixedIdentifier) {
          PrefixedIdentifier identifier = expression as PrefixedIdentifier;
          expression = new MethodInvocation.full(identifier.prefix, identifier.period, identifier.identifier, argumentList);
        } else if (expression is PropertyAccess) {
          PropertyAccess access = expression as PropertyAccess;
          expression = new MethodInvocation.full(access.target, access.operator, access.propertyName, argumentList);
        } else {
          expression = new FunctionExpressionInvocation.full(expression, argumentList);
        }
        if (!primaryAllowed) {
          isOptional = false;
        }
      }
      Expression selectorExpression = parseAssignableSelector(expression, isOptional || (expression is PrefixedIdentifier));
      if (identical(selectorExpression, expression)) {
        if (!isOptional && (expression is PrefixedIdentifier)) {
          PrefixedIdentifier identifier = expression as PrefixedIdentifier;
          expression = new PropertyAccess.full(identifier.prefix, identifier.period, identifier.identifier);
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
    if (matches5(TokenType.OPEN_SQUARE_BRACKET)) {
      Token leftBracket = andAdvance;
      Expression index = parseExpression2();
      Token rightBracket = expect2(TokenType.CLOSE_SQUARE_BRACKET);
      return new IndexExpression.forTarget_full(prefix, leftBracket, index, rightBracket);
    } else if (matches5(TokenType.PERIOD)) {
      Token period = andAdvance;
      return new PropertyAccess.full(prefix, period, parseSimpleIdentifier());
    } else {
      if (!optional) {
        reportError10(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, []);
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
    if (matches(Keyword.SUPER) && matches4(peek(), TokenType.AMPERSAND)) {
      expression = new SuperExpression.full(andAdvance);
    } else {
      expression = parseShiftExpression();
    }
    while (matches5(TokenType.AMPERSAND)) {
      Token operator = andAdvance;
      expression = new BinaryExpression.full(expression, operator, parseShiftExpression());
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
    if (matches(Keyword.SUPER) && matches4(peek(), TokenType.CARET)) {
      expression = new SuperExpression.full(andAdvance);
    } else {
      expression = parseBitwiseAndExpression();
    }
    while (matches5(TokenType.CARET)) {
      Token operator = andAdvance;
      expression = new BinaryExpression.full(expression, operator, parseBitwiseAndExpression());
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
    Token breakKeyword = expect(Keyword.BREAK);
    SimpleIdentifier label = null;
    if (matchesIdentifier()) {
      label = parseSimpleIdentifier();
    }
    if (!_inLoop && !_inSwitch && label == null) {
      reportError11(ParserErrorCode.BREAK_OUTSIDE_OF_LOOP, breakKeyword, []);
    }
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new BreakStatement.full(breakKeyword, label, semicolon);
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
    Token period = expect2(TokenType.PERIOD_PERIOD);
    Expression expression = null;
    SimpleIdentifier functionName = null;
    if (matchesIdentifier()) {
      functionName = parseSimpleIdentifier();
    } else if (identical(_currentToken.type, TokenType.OPEN_SQUARE_BRACKET)) {
      Token leftBracket = andAdvance;
      Expression index = parseExpression2();
      Token rightBracket = expect2(TokenType.CLOSE_SQUARE_BRACKET);
      expression = new IndexExpression.forCascade_full(period, leftBracket, index, rightBracket);
      period = null;
    } else {
      reportError11(ParserErrorCode.MISSING_IDENTIFIER, _currentToken, [_currentToken.lexeme]);
      functionName = createSyntheticIdentifier();
    }
    if (identical(_currentToken.type, TokenType.OPEN_PAREN)) {
      while (identical(_currentToken.type, TokenType.OPEN_PAREN)) {
        if (functionName != null) {
          expression = new MethodInvocation.full(expression, period, functionName, parseArgumentList());
          period = null;
          functionName = null;
        } else if (expression == null) {
          expression = new MethodInvocation.full(expression, period, createSyntheticIdentifier(), parseArgumentList());
        } else {
          expression = new FunctionExpressionInvocation.full(expression, parseArgumentList());
        }
      }
    } else if (functionName != null) {
      expression = new PropertyAccess.full(expression, period, functionName);
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
            expression = new MethodInvocation.full(propertyAccess.target, propertyAccess.operator, propertyAccess.propertyName, parseArgumentList());
          } else {
            expression = new FunctionExpressionInvocation.full(expression, parseArgumentList());
          }
        }
      }
    }
    if (_currentToken.type.isAssignmentOperator) {
      Token operator = andAdvance;
      ensureAssignable(expression);
      expression = new AssignmentExpression.full(expression, operator, parseExpressionWithoutCascade());
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
    Token keyword = expect(Keyword.CLASS);
    if (matchesIdentifier()) {
      Token next = peek();
      if (matches4(next, TokenType.LT)) {
        next = skipTypeParameterList(next);
        if (next != null && matches4(next, TokenType.EQ)) {
          return parseClassTypeAlias(commentAndMetadata, keyword);
        }
      } else if (matches4(next, TokenType.EQ)) {
        return parseClassTypeAlias(commentAndMetadata, keyword);
      }
    }
    SimpleIdentifier name = parseSimpleIdentifier();
    String className = name.name;
    TypeParameterList typeParameters = null;
    if (matches5(TokenType.LT)) {
      typeParameters = parseTypeParameterList();
    }
    ExtendsClause extendsClause = null;
    WithClause withClause = null;
    ImplementsClause implementsClause = null;
    bool foundClause = true;
    while (foundClause) {
      if (matches(Keyword.EXTENDS)) {
        if (extendsClause == null) {
          extendsClause = parseExtendsClause();
          if (withClause != null) {
            reportError11(ParserErrorCode.WITH_BEFORE_EXTENDS, withClause.withKeyword, []);
          } else if (implementsClause != null) {
            reportError11(ParserErrorCode.IMPLEMENTS_BEFORE_EXTENDS, implementsClause.keyword, []);
          }
        } else {
          reportError11(ParserErrorCode.MULTIPLE_EXTENDS_CLAUSES, extendsClause.keyword, []);
          parseExtendsClause();
        }
      } else if (matches(Keyword.WITH)) {
        if (withClause == null) {
          withClause = parseWithClause();
          if (implementsClause != null) {
            reportError11(ParserErrorCode.IMPLEMENTS_BEFORE_WITH, implementsClause.keyword, []);
          }
        } else {
          reportError11(ParserErrorCode.MULTIPLE_WITH_CLAUSES, withClause.withKeyword, []);
          parseWithClause();
        }
      } else if (matches(Keyword.IMPLEMENTS)) {
        if (implementsClause == null) {
          implementsClause = parseImplementsClause();
        } else {
          reportError11(ParserErrorCode.MULTIPLE_IMPLEMENTS_CLAUSES, implementsClause.keyword, []);
          parseImplementsClause();
        }
      } else {
        foundClause = false;
      }
    }
    if (withClause != null && extendsClause == null) {
      reportError11(ParserErrorCode.WITH_WITHOUT_EXTENDS, withClause.withKeyword, []);
    }
    NativeClause nativeClause = null;
    if (matches2(_NATIVE) && matches4(peek(), TokenType.STRING)) {
      nativeClause = parseNativeClause();
    }
    Token leftBracket = null;
    List<ClassMember> members = null;
    Token rightBracket = null;
    if (matches5(TokenType.OPEN_CURLY_BRACKET)) {
      leftBracket = expect2(TokenType.OPEN_CURLY_BRACKET);
      members = parseClassMembers(className, getEndToken(leftBracket));
      rightBracket = expect2(TokenType.CLOSE_CURLY_BRACKET);
    } else {
      leftBracket = createSyntheticToken2(TokenType.OPEN_CURLY_BRACKET);
      rightBracket = createSyntheticToken2(TokenType.CLOSE_CURLY_BRACKET);
      reportError10(ParserErrorCode.MISSING_CLASS_BODY, []);
    }
    ClassDeclaration classDeclaration = new ClassDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, abstractKeyword, keyword, name, typeParameters, extendsClause, withClause, implementsClause, leftBracket, members, rightBracket);
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
    while (!matches5(TokenType.EOF) && !matches5(TokenType.CLOSE_CURLY_BRACKET) && (closingBracket != null || (!matches(Keyword.CLASS) && !matches(Keyword.TYPEDEF)))) {
      if (matches5(TokenType.SEMICOLON)) {
        reportError11(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken, [_currentToken.lexeme]);
        advance();
      } else {
        ClassMember member = parseClassMember(className);
        if (member != null) {
          members.add(member);
        }
      }
      if (identical(_currentToken, memberStart)) {
        reportError11(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken, [_currentToken.lexeme]);
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
   * @param keyword the token representing the 'typedef' keyword
   * @return the class type alias that was parsed
   */
  ClassTypeAlias parseClassTypeAlias(CommentAndMetadata commentAndMetadata, Token keyword) {
    SimpleIdentifier className = parseSimpleIdentifier();
    TypeParameterList typeParameters = null;
    if (matches5(TokenType.LT)) {
      typeParameters = parseTypeParameterList();
    }
    Token equals = expect2(TokenType.EQ);
    Token abstractKeyword = null;
    if (matches(Keyword.ABSTRACT)) {
      abstractKeyword = andAdvance;
    }
    TypeName superclass = parseTypeName();
    WithClause withClause = null;
    if (matches(Keyword.WITH)) {
      withClause = parseWithClause();
    }
    ImplementsClause implementsClause = null;
    if (matches(Keyword.IMPLEMENTS)) {
      implementsClause = parseImplementsClause();
    }
    Token semicolon;
    if (matches5(TokenType.SEMICOLON)) {
      semicolon = andAdvance;
    } else {
      if (matches5(TokenType.OPEN_CURLY_BRACKET)) {
        reportError10(ParserErrorCode.EXPECTED_TOKEN, [TokenType.SEMICOLON.lexeme]);
        Token leftBracket = andAdvance;
        parseClassMembers(className.name, getEndToken(leftBracket));
        expect2(TokenType.CLOSE_CURLY_BRACKET);
      } else {
        reportError11(ParserErrorCode.EXPECTED_TOKEN, _currentToken.previous, [TokenType.SEMICOLON.lexeme]);
      }
      semicolon = createSyntheticToken2(TokenType.SEMICOLON);
    }
    return new ClassTypeAlias.full(commentAndMetadata.comment, commentAndMetadata.metadata, keyword, className, typeParameters, equals, abstractKeyword, superclass, withClause, implementsClause, semicolon);
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
    while (matches2(_SHOW) || matches2(_HIDE)) {
      Token keyword = expect2(TokenType.IDENTIFIER);
      if (keyword.lexeme == _SHOW) {
        List<SimpleIdentifier> shownNames = parseIdentifierList();
        combinators.add(new ShowCombinator.full(keyword, shownNames));
      } else {
        List<SimpleIdentifier> hiddenNames = parseIdentifierList();
        combinators.add(new HideCombinator.full(keyword, hiddenNames));
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
    while (matches5(TokenType.AT)) {
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
    if (referenceSource.length == 0) {
      return null;
    }
    try {
      BooleanErrorListener listener = new BooleanErrorListener();
      Scanner scanner = new Scanner(null, new SubSequenceReader(new CharSequence(referenceSource), sourceOffset), listener);
      scanner.setSourceStart(1, 1);
      Token firstToken = scanner.tokenize();
      if (listener.errorReported) {
        return null;
      }
      Token newKeyword = null;
      if (matches3(firstToken, Keyword.NEW)) {
        newKeyword = firstToken;
        firstToken = firstToken.next;
      }
      if (matchesIdentifier2(firstToken)) {
        Token secondToken = firstToken.next;
        Token thirdToken = secondToken.next;
        Token nextToken;
        Identifier identifier;
        if (matches4(secondToken, TokenType.PERIOD) && matchesIdentifier2(thirdToken)) {
          identifier = new PrefixedIdentifier.full(new SimpleIdentifier.full(firstToken), secondToken, new SimpleIdentifier.full(thirdToken));
          nextToken = thirdToken.next;
        } else {
          identifier = new SimpleIdentifier.full(firstToken);
          nextToken = firstToken.next;
        }
        if (nextToken.type != TokenType.EOF) {
          return null;
        }
        return new CommentReference.full(newKeyword, identifier);
      } else if (matches3(firstToken, Keyword.THIS) || matches3(firstToken, Keyword.NULL) || matches3(firstToken, Keyword.TRUE) || matches3(firstToken, Keyword.FALSE)) {
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
          int rightIndex = JavaString.indexOf(comment, ']', leftIndex);
          if (rightIndex >= 0) {
            int firstChar = comment.codeUnitAt(leftIndex + 1);
            if (firstChar != 0x27 && firstChar != 0x22) {
              if (isLinkText(comment, rightIndex)) {
              } else {
                CommentReference reference = parseCommentReference(comment.substring(leftIndex + 1, rightIndex), token.offset + leftIndex + 1);
                if (reference != null) {
                  references.add(reference);
                }
              }
            }
          } else {
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
    if (matches(Keyword.CLASS)) {
      return parseClassDeclaration(commentAndMetadata, validateModifiersForClass(modifiers));
    } else if (matches(Keyword.TYPEDEF) && !matches4(peek(), TokenType.PERIOD) && !matches4(peek(), TokenType.LT) && !matches4(peek(), TokenType.OPEN_PAREN)) {
      validateModifiersForTypedef(modifiers);
      return parseTypeAlias(commentAndMetadata);
    }
    if (matches(Keyword.VOID)) {
      TypeName returnType = parseReturnType();
      if ((matches(Keyword.GET) || matches(Keyword.SET)) && matchesIdentifier2(peek())) {
        validateModifiersForTopLevelFunction(modifiers);
        return parseFunctionDeclaration(commentAndMetadata, modifiers.externalKeyword, null);
      } else if (matches(Keyword.OPERATOR) && isOperator(peek())) {
        reportError11(ParserErrorCode.TOP_LEVEL_OPERATOR, _currentToken, []);
        return convertToFunctionDeclaration(parseOperator(commentAndMetadata, modifiers.externalKeyword, returnType));
      } else if (matchesIdentifier() && matchesAny(peek(), [
          TokenType.OPEN_PAREN,
          TokenType.OPEN_CURLY_BRACKET,
          TokenType.FUNCTION])) {
        validateModifiersForTopLevelFunction(modifiers);
        return parseFunctionDeclaration(commentAndMetadata, modifiers.externalKeyword, returnType);
      } else {
        if (matchesIdentifier()) {
          if (matchesAny(peek(), [TokenType.EQ, TokenType.COMMA, TokenType.SEMICOLON])) {
            reportError9(ParserErrorCode.VOID_VARIABLE, returnType, []);
            return new TopLevelVariableDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, parseVariableDeclarationList2(null, validateModifiersForTopLevelVariable(modifiers), null), expect2(TokenType.SEMICOLON));
          }
        }
        reportError11(ParserErrorCode.EXPECTED_EXECUTABLE, _currentToken, []);
        return null;
      }
    } else if ((matches(Keyword.GET) || matches(Keyword.SET)) && matchesIdentifier2(peek())) {
      validateModifiersForTopLevelFunction(modifiers);
      return parseFunctionDeclaration(commentAndMetadata, modifiers.externalKeyword, null);
    } else if (matches(Keyword.OPERATOR) && isOperator(peek())) {
      reportError11(ParserErrorCode.TOP_LEVEL_OPERATOR, _currentToken, []);
      return convertToFunctionDeclaration(parseOperator(commentAndMetadata, modifiers.externalKeyword, null));
    } else if (!matchesIdentifier()) {
      reportError11(ParserErrorCode.EXPECTED_EXECUTABLE, _currentToken, []);
      return null;
    } else if (matches4(peek(), TokenType.OPEN_PAREN)) {
      validateModifiersForTopLevelFunction(modifiers);
      return parseFunctionDeclaration(commentAndMetadata, modifiers.externalKeyword, null);
    } else if (matchesAny(peek(), [TokenType.EQ, TokenType.COMMA, TokenType.SEMICOLON])) {
      if (modifiers.constKeyword == null && modifiers.finalKeyword == null && modifiers.varKeyword == null) {
        reportError10(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, []);
      }
      return new TopLevelVariableDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, parseVariableDeclarationList2(null, validateModifiersForTopLevelVariable(modifiers), null), expect2(TokenType.SEMICOLON));
    }
    TypeName returnType = parseReturnType();
    if ((matches(Keyword.GET) || matches(Keyword.SET)) && matchesIdentifier2(peek())) {
      validateModifiersForTopLevelFunction(modifiers);
      return parseFunctionDeclaration(commentAndMetadata, modifiers.externalKeyword, returnType);
    } else if (matches(Keyword.OPERATOR) && isOperator(peek())) {
      reportError11(ParserErrorCode.TOP_LEVEL_OPERATOR, _currentToken, []);
      return convertToFunctionDeclaration(parseOperator(commentAndMetadata, modifiers.externalKeyword, returnType));
    } else if (matches5(TokenType.AT)) {
      return new TopLevelVariableDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, parseVariableDeclarationList2(null, validateModifiersForTopLevelVariable(modifiers), returnType), expect2(TokenType.SEMICOLON));
    } else if (!matchesIdentifier()) {
      reportError11(ParserErrorCode.EXPECTED_EXECUTABLE, _currentToken, []);
      Token semicolon;
      if (matches5(TokenType.SEMICOLON)) {
        semicolon = andAdvance;
      } else {
        semicolon = createSyntheticToken2(TokenType.SEMICOLON);
      }
      List<VariableDeclaration> variables = new List<VariableDeclaration>();
      variables.add(new VariableDeclaration.full(null, null, createSyntheticIdentifier(), null, null));
      return new TopLevelVariableDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, new VariableDeclarationList.full(null, null, null, returnType, variables), semicolon);
    }
    if (matchesAny(peek(), [
        TokenType.OPEN_PAREN,
        TokenType.FUNCTION,
        TokenType.OPEN_CURLY_BRACKET])) {
      validateModifiersForTopLevelFunction(modifiers);
      return parseFunctionDeclaration(commentAndMetadata, modifiers.externalKeyword, returnType);
    }
    return new TopLevelVariableDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, parseVariableDeclarationList2(null, validateModifiersForTopLevelVariable(modifiers), returnType), expect2(TokenType.SEMICOLON));
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
    Token keyword = expect(Keyword.CONST);
    if (matches5(TokenType.OPEN_SQUARE_BRACKET) || matches5(TokenType.INDEX)) {
      return parseListLiteral(keyword, null);
    } else if (matches5(TokenType.OPEN_CURLY_BRACKET)) {
      return parseMapLiteral(keyword, null);
    } else if (matches5(TokenType.LT)) {
      return parseListOrMapLiteral(keyword);
    }
    return parseInstanceCreationExpression(keyword);
  }

  ConstructorDeclaration parseConstructor(CommentAndMetadata commentAndMetadata, Token externalKeyword, Token constKeyword, Token factoryKeyword, SimpleIdentifier returnType, Token period, SimpleIdentifier name, FormalParameterList parameters) {
    bool bodyAllowed = externalKeyword == null;
    Token separator = null;
    List<ConstructorInitializer> initializers = null;
    if (matches5(TokenType.COLON)) {
      separator = andAdvance;
      initializers = new List<ConstructorInitializer>();
      do {
        if (matches(Keyword.THIS)) {
          if (matches4(peek(), TokenType.OPEN_PAREN)) {
            bodyAllowed = false;
            initializers.add(parseRedirectingConstructorInvocation());
          } else if (matches4(peek(), TokenType.PERIOD) && matches4(peek2(3), TokenType.OPEN_PAREN)) {
            bodyAllowed = false;
            initializers.add(parseRedirectingConstructorInvocation());
          } else {
            initializers.add(parseConstructorFieldInitializer());
          }
        } else if (matches(Keyword.SUPER)) {
          initializers.add(parseSuperConstructorInvocation());
        } else {
          initializers.add(parseConstructorFieldInitializer());
        }
      } while (optional(TokenType.COMMA));
    }
    ConstructorName redirectedConstructor = null;
    FunctionBody body;
    if (matches5(TokenType.EQ)) {
      separator = andAdvance;
      redirectedConstructor = parseConstructorName();
      body = new EmptyFunctionBody.full(expect2(TokenType.SEMICOLON));
      if (factoryKeyword == null) {
        reportError9(ParserErrorCode.REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR, redirectedConstructor, []);
      }
    } else {
      body = parseFunctionBody(true, ParserErrorCode.MISSING_FUNCTION_BODY, false);
      if (constKeyword != null && factoryKeyword != null && externalKeyword == null) {
        reportError11(ParserErrorCode.CONST_FACTORY, factoryKeyword, []);
      } else if (body is EmptyFunctionBody) {
        if (factoryKeyword != null && externalKeyword == null) {
          reportError11(ParserErrorCode.FACTORY_WITHOUT_BODY, factoryKeyword, []);
        }
      } else {
        if (constKeyword != null) {
          reportError9(ParserErrorCode.CONST_CONSTRUCTOR_WITH_BODY, body, []);
        } else if (!bodyAllowed) {
          reportError9(ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_BODY, body, []);
        }
      }
    }
    return new ConstructorDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, externalKeyword, constKeyword, factoryKeyword, returnType, period, name, parameters, separator, initializers, redirectedConstructor, body);
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
    if (matches(Keyword.THIS)) {
      keyword = andAdvance;
      period = expect2(TokenType.PERIOD);
    }
    SimpleIdentifier fieldName = parseSimpleIdentifier();
    Token equals = expect2(TokenType.EQ);
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
      expression = new CascadeExpression.full(expression, cascadeSections);
    }
    return new ConstructorFieldInitializer.full(keyword, period, fieldName, equals, expression);
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
    Token continueKeyword = expect(Keyword.CONTINUE);
    if (!_inLoop && !_inSwitch) {
      reportError11(ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP, continueKeyword, []);
    }
    SimpleIdentifier label = null;
    if (matchesIdentifier()) {
      label = parseSimpleIdentifier();
    }
    if (_inSwitch && !_inLoop && label == null) {
      reportError11(ParserErrorCode.CONTINUE_WITHOUT_LABEL_IN_CASE, continueKeyword, []);
    }
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new ContinueStatement.full(continueKeyword, label, semicolon);
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
    if (matches(Keyword.IMPORT)) {
      return parseImportDirective(commentAndMetadata);
    } else if (matches(Keyword.EXPORT)) {
      return parseExportDirective(commentAndMetadata);
    } else if (matches(Keyword.LIBRARY)) {
      return parseLibraryDirective(commentAndMetadata);
    } else if (matches(Keyword.PART)) {
      return parsePartDirective(commentAndMetadata);
    } else {
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
        if (commentToken.lexeme.startsWith("///")) {
          if (commentTokens.length == 1 && commentTokens[0].lexeme.startsWith("/**")) {
            commentTokens.clear();
          }
          commentTokens.add(commentToken);
        }
      } else {
        if (commentToken.lexeme.startsWith("/**")) {
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
      Token doKeyword = expect(Keyword.DO);
      Statement body = parseStatement2();
      Token whileKeyword = expect(Keyword.WHILE);
      Token leftParenthesis = expect2(TokenType.OPEN_PAREN);
      Expression condition = parseExpression2();
      Token rightParenthesis = expect2(TokenType.CLOSE_PAREN);
      Token semicolon = expect2(TokenType.SEMICOLON);
      return new DoStatement.full(doKeyword, body, whileKeyword, leftParenthesis, condition, rightParenthesis, semicolon);
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
  Statement parseEmptyStatement() => new EmptyStatement.full(andAdvance);

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
    if (matches(Keyword.SUPER) && _currentToken.next.type.isEqualityOperator) {
      expression = new SuperExpression.full(andAdvance);
    } else {
      expression = parseRelationalExpression();
    }
    bool leftEqualityExpression = false;
    while (_currentToken.type.isEqualityOperator) {
      Token operator = andAdvance;
      if (leftEqualityExpression) {
        reportError9(ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND, expression, []);
      }
      expression = new BinaryExpression.full(expression, operator, parseRelationalExpression());
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
    Token exportKeyword = expect(Keyword.EXPORT);
    StringLiteral libraryUri = parseStringLiteral();
    List<Combinator> combinators = parseCombinators();
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new ExportDirective.full(commentAndMetadata.comment, commentAndMetadata.metadata, exportKeyword, libraryUri, combinators, semicolon);
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
    if (matches(Keyword.FINAL) || matches(Keyword.CONST)) {
      keyword = andAdvance;
      if (isTypedIdentifier(_currentToken)) {
        type = parseTypeName();
      }
    } else if (matches(Keyword.VAR)) {
      keyword = andAdvance;
    } else {
      if (isTypedIdentifier(_currentToken)) {
        type = parseReturnType();
      } else if (!optional) {
        reportError10(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, []);
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
    if (matches5(TokenType.EQ)) {
      Token seperator = andAdvance;
      Expression defaultValue = parseExpression2();
      if (identical(kind, ParameterKind.NAMED)) {
        reportError11(ParserErrorCode.WRONG_SEPARATOR_FOR_NAMED_PARAMETER, seperator, []);
      } else if (identical(kind, ParameterKind.REQUIRED)) {
        reportError9(ParserErrorCode.POSITIONAL_PARAMETER_OUTSIDE_GROUP, parameter, []);
      }
      return new DefaultFormalParameter.full(parameter, kind, seperator, defaultValue);
    } else if (matches5(TokenType.COLON)) {
      Token seperator = andAdvance;
      Expression defaultValue = parseExpression2();
      if (identical(kind, ParameterKind.POSITIONAL)) {
        reportError11(ParserErrorCode.WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER, seperator, []);
      } else if (identical(kind, ParameterKind.REQUIRED)) {
        reportError9(ParserErrorCode.NAMED_PARAMETER_OUTSIDE_GROUP, parameter, []);
      }
      return new DefaultFormalParameter.full(parameter, kind, seperator, defaultValue);
    } else if (kind != ParameterKind.REQUIRED) {
      return new DefaultFormalParameter.full(parameter, kind, null, null);
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
      Token forKeyword = expect(Keyword.FOR);
      Token leftParenthesis = expect2(TokenType.OPEN_PAREN);
      VariableDeclarationList variableList = null;
      Expression initialization = null;
      if (!matches5(TokenType.SEMICOLON)) {
        CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
        if (matchesIdentifier() && matches3(peek(), Keyword.IN)) {
          List<VariableDeclaration> variables = new List<VariableDeclaration>();
          SimpleIdentifier variableName = parseSimpleIdentifier();
          variables.add(new VariableDeclaration.full(null, null, variableName, null, null));
          variableList = new VariableDeclarationList.full(commentAndMetadata.comment, commentAndMetadata.metadata, null, null, variables);
        } else if (isInitializedVariableDeclaration()) {
          variableList = parseVariableDeclarationList(commentAndMetadata);
        } else {
          initialization = parseExpression2();
        }
        if (matches(Keyword.IN)) {
          DeclaredIdentifier loopVariable = null;
          SimpleIdentifier identifier = null;
          if (variableList == null) {
            reportError10(ParserErrorCode.MISSING_VARIABLE_IN_FOR_EACH, []);
          } else {
            NodeList<VariableDeclaration> variables = variableList.variables;
            if (variables.length > 1) {
              reportError10(ParserErrorCode.MULTIPLE_VARIABLES_IN_FOR_EACH, [variables.length.toString()]);
            }
            VariableDeclaration variable = variables[0];
            if (variable.initializer != null) {
              reportError10(ParserErrorCode.INITIALIZED_VARIABLE_IN_FOR_EACH, []);
            }
            Token keyword = variableList.keyword;
            TypeName type = variableList.type;
            if (keyword != null || type != null) {
              loopVariable = new DeclaredIdentifier.full(commentAndMetadata.comment, commentAndMetadata.metadata, keyword, type, variable.name);
            } else {
              if (!commentAndMetadata.metadata.isEmpty) {
              }
              identifier = variable.name;
            }
          }
          Token inKeyword = expect(Keyword.IN);
          Expression iterator = parseExpression2();
          Token rightParenthesis = expect2(TokenType.CLOSE_PAREN);
          Statement body = parseStatement2();
          if (loopVariable == null) {
            return new ForEachStatement.con2_full(forKeyword, leftParenthesis, identifier, inKeyword, iterator, rightParenthesis, body);
          }
          return new ForEachStatement.con1_full(forKeyword, leftParenthesis, loopVariable, inKeyword, iterator, rightParenthesis, body);
        }
      }
      Token leftSeparator = expect2(TokenType.SEMICOLON);
      Expression condition = null;
      if (!matches5(TokenType.SEMICOLON)) {
        condition = parseExpression2();
      }
      Token rightSeparator = expect2(TokenType.SEMICOLON);
      List<Expression> updaters = null;
      if (!matches5(TokenType.CLOSE_PAREN)) {
        updaters = parseExpressionList();
      }
      Token rightParenthesis = expect2(TokenType.CLOSE_PAREN);
      Statement body = parseStatement2();
      return new ForStatement.full(forKeyword, leftParenthesis, variableList, initialization, leftSeparator, condition, rightSeparator, updaters, rightParenthesis, body);
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
      if (matches5(TokenType.SEMICOLON)) {
        if (!mayBeEmpty) {
          reportError10(emptyErrorCode, []);
        }
        return new EmptyFunctionBody.full(andAdvance);
      } else if (matches5(TokenType.FUNCTION)) {
        Token functionDefinition = andAdvance;
        Expression expression = parseExpression2();
        Token semicolon = null;
        if (!inExpression) {
          semicolon = expect2(TokenType.SEMICOLON);
        }
        if (!_parseFunctionBodies) {
          return new EmptyFunctionBody.full(createSyntheticToken2(TokenType.SEMICOLON));
        }
        return new ExpressionFunctionBody.full(functionDefinition, expression, semicolon);
      } else if (matches5(TokenType.OPEN_CURLY_BRACKET)) {
        if (!_parseFunctionBodies) {
          skipBlock();
          return new EmptyFunctionBody.full(createSyntheticToken2(TokenType.SEMICOLON));
        }
        return new BlockFunctionBody.full(parseBlock());
      } else if (matches2(_NATIVE)) {
        Token nativeToken = andAdvance;
        StringLiteral stringLiteral = null;
        if (matches5(TokenType.STRING)) {
          stringLiteral = parseStringLiteral();
        }
        return new NativeFunctionBody.full(nativeToken, stringLiteral, expect2(TokenType.SEMICOLON));
      } else {
        reportError10(emptyErrorCode, []);
        return new EmptyFunctionBody.full(createSyntheticToken2(TokenType.SEMICOLON));
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
    if (matches(Keyword.GET) && !matches4(peek(), TokenType.OPEN_PAREN)) {
      keyword = andAdvance;
      isGetter = true;
    } else if (matches(Keyword.SET) && !matches4(peek(), TokenType.OPEN_PAREN)) {
      keyword = andAdvance;
    }
    SimpleIdentifier name = parseSimpleIdentifier();
    FormalParameterList parameters = null;
    if (!isGetter) {
      if (matches5(TokenType.OPEN_PAREN)) {
        parameters = parseFormalParameterList();
        validateFormalParameterList(parameters);
      } else {
        reportError10(ParserErrorCode.MISSING_FUNCTION_PARAMETERS, []);
      }
    } else if (matches5(TokenType.OPEN_PAREN)) {
      reportError10(ParserErrorCode.GETTER_WITH_PARAMETERS, []);
      parseFormalParameterList();
    }
    FunctionBody body;
    if (externalKeyword == null) {
      body = parseFunctionBody(false, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    } else {
      body = new EmptyFunctionBody.full(expect2(TokenType.SEMICOLON));
    }
    return new FunctionDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, externalKeyword, returnType, keyword, name, new FunctionExpression.full(parameters, body));
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
    return parseFunctionDeclarationStatement2(parseCommentAndMetadata(), parseOptionalReturnType());
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
  Statement parseFunctionDeclarationStatement2(CommentAndMetadata commentAndMetadata, TypeName returnType) {
    FunctionDeclaration declaration = parseFunctionDeclaration(commentAndMetadata, null, returnType);
    Token propertyKeyword = declaration.propertyKeyword;
    if (propertyKeyword != null) {
      if (identical((propertyKeyword as KeywordToken).keyword, Keyword.GET)) {
        reportError11(ParserErrorCode.GETTER_IN_FUNCTION, propertyKeyword, []);
      } else {
        reportError11(ParserErrorCode.SETTER_IN_FUNCTION, propertyKeyword, []);
      }
    }
    return new FunctionDeclarationStatement.full(declaration);
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
    if (matches5(TokenType.LT)) {
      typeParameters = parseTypeParameterList();
    }
    if (matches5(TokenType.SEMICOLON) || matches5(TokenType.EOF)) {
      reportError10(ParserErrorCode.MISSING_TYPEDEF_PARAMETERS, []);
      FormalParameterList parameters = new FormalParameterList.full(createSyntheticToken2(TokenType.OPEN_PAREN), null, null, null, createSyntheticToken2(TokenType.CLOSE_PAREN));
      Token semicolon = expect2(TokenType.SEMICOLON);
      return new FunctionTypeAlias.full(commentAndMetadata.comment, commentAndMetadata.metadata, keyword, returnType, name, typeParameters, parameters, semicolon);
    } else if (!matches5(TokenType.OPEN_PAREN)) {
      reportError10(ParserErrorCode.MISSING_TYPEDEF_PARAMETERS, []);
      return new FunctionTypeAlias.full(commentAndMetadata.comment, commentAndMetadata.metadata, keyword, returnType, name, typeParameters, new FormalParameterList.full(createSyntheticToken2(TokenType.OPEN_PAREN), null, null, null, createSyntheticToken2(TokenType.CLOSE_PAREN)), createSyntheticToken2(TokenType.SEMICOLON));
    }
    FormalParameterList parameters = parseFormalParameterList();
    validateFormalParameterList(parameters);
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new FunctionTypeAlias.full(commentAndMetadata.comment, commentAndMetadata.metadata, keyword, returnType, name, typeParameters, parameters, semicolon);
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
    Token propertyKeyword = expect(Keyword.GET);
    SimpleIdentifier name = parseSimpleIdentifier();
    if (matches5(TokenType.OPEN_PAREN) && matches4(peek(), TokenType.CLOSE_PAREN)) {
      reportError10(ParserErrorCode.GETTER_WITH_PARAMETERS, []);
      advance();
      advance();
    }
    FunctionBody body = parseFunctionBody(externalKeyword != null || staticKeyword == null, ParserErrorCode.STATIC_GETTER_WITHOUT_BODY, false);
    if (externalKeyword != null && body is! EmptyFunctionBody) {
      reportError10(ParserErrorCode.EXTERNAL_GETTER_WITH_BODY, []);
    }
    return new MethodDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, externalKeyword, staticKeyword, returnType, propertyKeyword, null, name, null, body);
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
    while (matches5(TokenType.COMMA)) {
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
    Token ifKeyword = expect(Keyword.IF);
    Token leftParenthesis = expect2(TokenType.OPEN_PAREN);
    Expression condition = parseExpression2();
    Token rightParenthesis = expect2(TokenType.CLOSE_PAREN);
    Statement thenStatement = parseStatement2();
    Token elseKeyword = null;
    Statement elseStatement = null;
    if (matches(Keyword.ELSE)) {
      elseKeyword = andAdvance;
      elseStatement = parseStatement2();
    }
    return new IfStatement.full(ifKeyword, leftParenthesis, condition, rightParenthesis, thenStatement, elseKeyword, elseStatement);
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
    Token importKeyword = expect(Keyword.IMPORT);
    StringLiteral libraryUri = parseStringLiteral();
    Token asToken = null;
    SimpleIdentifier prefix = null;
    if (matches(Keyword.AS)) {
      asToken = andAdvance;
      prefix = parseSimpleIdentifier();
    }
    List<Combinator> combinators = parseCombinators();
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new ImportDirective.full(commentAndMetadata.comment, commentAndMetadata.metadata, importKeyword, libraryUri, asToken, prefix, combinators, semicolon);
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
    VariableDeclarationList fieldList = parseVariableDeclarationList2(null, keyword, type);
    return new FieldDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, staticKeyword, fieldList, expect2(TokenType.SEMICOLON));
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
    return new InstanceCreationExpression.full(keyword, constructorName, argumentList);
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
    Token keyword = expect(Keyword.LIBRARY);
    LibraryIdentifier libraryName = parseLibraryName(ParserErrorCode.MISSING_NAME_IN_LIBRARY_DIRECTIVE, keyword);
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new LibraryDirective.full(commentAndMetadata.comment, commentAndMetadata.metadata, keyword, libraryName, semicolon);
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
    } else if (matches5(TokenType.STRING)) {
      StringLiteral string = parseStringLiteral();
      reportError9(ParserErrorCode.NON_IDENTIFIER_LIBRARY_NAME, string, []);
    } else {
      reportError11(missingNameError, missingNameToken, []);
    }
    List<SimpleIdentifier> components = new List<SimpleIdentifier>();
    components.add(createSyntheticIdentifier());
    return new LibraryIdentifier.full(components);
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
    if (matches5(TokenType.INDEX)) {
      BeginToken leftBracket = new BeginToken(TokenType.OPEN_SQUARE_BRACKET, _currentToken.offset);
      Token rightBracket = new Token(TokenType.CLOSE_SQUARE_BRACKET, _currentToken.offset + 1);
      leftBracket.endToken = rightBracket;
      rightBracket.setNext(_currentToken.next);
      leftBracket.setNext(rightBracket);
      _currentToken.previous.setNext(leftBracket);
      _currentToken = _currentToken.next;
      return new ListLiteral.full(modifier, typeArguments, leftBracket, null, rightBracket);
    }
    Token leftBracket = expect2(TokenType.OPEN_SQUARE_BRACKET);
    if (matches5(TokenType.CLOSE_SQUARE_BRACKET)) {
      return new ListLiteral.full(modifier, typeArguments, leftBracket, null, andAdvance);
    }
    List<Expression> elements = new List<Expression>();
    elements.add(parseExpression2());
    while (optional(TokenType.COMMA)) {
      if (matches5(TokenType.CLOSE_SQUARE_BRACKET)) {
        return new ListLiteral.full(modifier, typeArguments, leftBracket, elements, andAdvance);
      }
      elements.add(parseExpression2());
    }
    Token rightBracket = expect2(TokenType.CLOSE_SQUARE_BRACKET);
    return new ListLiteral.full(modifier, typeArguments, leftBracket, elements, rightBracket);
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
    if (matches5(TokenType.LT)) {
      typeArguments = parseTypeArgumentList();
    }
    if (matches5(TokenType.OPEN_CURLY_BRACKET)) {
      return parseMapLiteral(modifier, typeArguments);
    } else if (matches5(TokenType.OPEN_SQUARE_BRACKET) || matches5(TokenType.INDEX)) {
      return parseListLiteral(modifier, typeArguments);
    }
    reportError10(ParserErrorCode.EXPECTED_LIST_OR_MAP_LITERAL, []);
    return new ListLiteral.full(modifier, typeArguments, createSyntheticToken2(TokenType.OPEN_SQUARE_BRACKET), null, createSyntheticToken2(TokenType.CLOSE_SQUARE_BRACKET));
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
    while (matches5(TokenType.AMPERSAND_AMPERSAND)) {
      Token operator = andAdvance;
      expression = new BinaryExpression.full(expression, operator, parseEqualityExpression());
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
    Token leftBracket = expect2(TokenType.OPEN_CURLY_BRACKET);
    List<MapLiteralEntry> entries = new List<MapLiteralEntry>();
    if (matches5(TokenType.CLOSE_CURLY_BRACKET)) {
      return new MapLiteral.full(modifier, typeArguments, leftBracket, entries, andAdvance);
    }
    entries.add(parseMapLiteralEntry());
    while (optional(TokenType.COMMA)) {
      if (matches5(TokenType.CLOSE_CURLY_BRACKET)) {
        return new MapLiteral.full(modifier, typeArguments, leftBracket, entries, andAdvance);
      }
      entries.add(parseMapLiteralEntry());
    }
    Token rightBracket = expect2(TokenType.CLOSE_CURLY_BRACKET);
    return new MapLiteral.full(modifier, typeArguments, leftBracket, entries, rightBracket);
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
  MethodDeclaration parseMethodDeclaration(CommentAndMetadata commentAndMetadata, Token externalKeyword, Token staticKeyword, TypeName returnType) {
    SimpleIdentifier methodName = parseSimpleIdentifier();
    FormalParameterList parameters = parseFormalParameterList();
    validateFormalParameterList(parameters);
    return parseMethodDeclaration2(commentAndMetadata, externalKeyword, staticKeyword, returnType, methodName, parameters);
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
  MethodDeclaration parseMethodDeclaration2(CommentAndMetadata commentAndMetadata, Token externalKeyword, Token staticKeyword, TypeName returnType, SimpleIdentifier name, FormalParameterList parameters) {
    FunctionBody body = parseFunctionBody(externalKeyword != null || staticKeyword == null, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    if (externalKeyword != null) {
      if (body is! EmptyFunctionBody) {
        reportError9(ParserErrorCode.EXTERNAL_METHOD_WITH_BODY, body, []);
      }
    } else if (staticKeyword != null) {
      if (body is EmptyFunctionBody) {
        reportError9(ParserErrorCode.ABSTRACT_STATIC_METHOD, body, []);
      }
    }
    return new MethodDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, externalKeyword, staticKeyword, returnType, null, null, name, parameters, body);
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
      if (matches4(peek(), TokenType.PERIOD) || matches4(peek(), TokenType.LT) || matches4(peek(), TokenType.OPEN_PAREN)) {
        return modifiers;
      }
      if (matches(Keyword.ABSTRACT)) {
        if (modifiers.abstractKeyword != null) {
          reportError10(ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          advance();
        } else {
          modifiers.abstractKeyword = andAdvance;
        }
      } else if (matches(Keyword.CONST)) {
        if (modifiers.constKeyword != null) {
          reportError10(ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          advance();
        } else {
          modifiers.constKeyword = andAdvance;
        }
      } else if (matches(Keyword.EXTERNAL) && !matches4(peek(), TokenType.PERIOD) && !matches4(peek(), TokenType.LT)) {
        if (modifiers.externalKeyword != null) {
          reportError10(ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          advance();
        } else {
          modifiers.externalKeyword = andAdvance;
        }
      } else if (matches(Keyword.FACTORY) && !matches4(peek(), TokenType.PERIOD) && !matches4(peek(), TokenType.LT)) {
        if (modifiers.factoryKeyword != null) {
          reportError10(ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          advance();
        } else {
          modifiers.factoryKeyword = andAdvance;
        }
      } else if (matches(Keyword.FINAL)) {
        if (modifiers.finalKeyword != null) {
          reportError10(ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          advance();
        } else {
          modifiers.finalKeyword = andAdvance;
        }
      } else if (matches(Keyword.STATIC) && !matches4(peek(), TokenType.PERIOD) && !matches4(peek(), TokenType.LT)) {
        if (modifiers.staticKeyword != null) {
          reportError10(ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
          advance();
        } else {
          modifiers.staticKeyword = andAdvance;
        }
      } else if (matches(Keyword.VAR)) {
        if (modifiers.varKeyword != null) {
          reportError10(ParserErrorCode.DUPLICATED_MODIFIER, [_currentToken.lexeme]);
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
    if (matches(Keyword.SUPER) && _currentToken.next.type.isMultiplicativeOperator) {
      expression = new SuperExpression.full(andAdvance);
    } else {
      expression = parseUnaryExpression();
    }
    while (_currentToken.type.isMultiplicativeOperator) {
      Token operator = andAdvance;
      expression = new BinaryExpression.full(expression, operator, parseUnaryExpression());
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
    return new NativeClause.full(keyword, name);
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
  InstanceCreationExpression parseNewExpression() => parseInstanceCreationExpression(expect(Keyword.NEW));

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
    CommentAndMetadata commentAndMetadata = parseCommentAndMetadata();
    if (matches5(TokenType.OPEN_CURLY_BRACKET)) {
      if (matches4(peek(), TokenType.STRING)) {
        Token afterString = skipStringLiteral(_currentToken.next);
        if (afterString != null && identical(afterString.type, TokenType.COLON)) {
          return new ExpressionStatement.full(parseExpression2(), expect2(TokenType.SEMICOLON));
        }
      }
      return parseBlock();
    } else if (matches5(TokenType.KEYWORD) && !(_currentToken as KeywordToken).keyword.isPseudoKeyword) {
      Keyword keyword = (_currentToken as KeywordToken).keyword;
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
        return new ExpressionStatement.full(parseRethrowExpression(), expect2(TokenType.SEMICOLON));
      } else if (identical(keyword, Keyword.RETURN)) {
        return parseReturnStatement();
      } else if (identical(keyword, Keyword.SWITCH)) {
        return parseSwitchStatement();
      } else if (identical(keyword, Keyword.THROW)) {
        return new ExpressionStatement.full(parseThrowExpression(), expect2(TokenType.SEMICOLON));
      } else if (identical(keyword, Keyword.TRY)) {
        return parseTryStatement();
      } else if (identical(keyword, Keyword.WHILE)) {
        return parseWhileStatement();
      } else if (identical(keyword, Keyword.VAR) || identical(keyword, Keyword.FINAL)) {
        return parseVariableDeclarationStatement(commentAndMetadata);
      } else if (identical(keyword, Keyword.VOID)) {
        TypeName returnType = parseReturnType();
        if (matchesIdentifier() && matchesAny(peek(), [
            TokenType.OPEN_PAREN,
            TokenType.OPEN_CURLY_BRACKET,
            TokenType.FUNCTION])) {
          return parseFunctionDeclarationStatement2(commentAndMetadata, returnType);
        } else {
          if (matchesIdentifier()) {
            if (matchesAny(peek(), [TokenType.EQ, TokenType.COMMA, TokenType.SEMICOLON])) {
              reportError9(ParserErrorCode.VOID_VARIABLE, returnType, []);
              return parseVariableDeclarationStatement(commentAndMetadata);
            }
          } else if (matches5(TokenType.CLOSE_CURLY_BRACKET)) {
            return parseVariableDeclarationStatement2(commentAndMetadata, null, returnType);
          }
          reportError10(ParserErrorCode.MISSING_STATEMENT, []);
          return new EmptyStatement.full(createSyntheticToken2(TokenType.SEMICOLON));
        }
      } else if (identical(keyword, Keyword.CONST)) {
        if (matchesAny(peek(), [
            TokenType.LT,
            TokenType.OPEN_CURLY_BRACKET,
            TokenType.OPEN_SQUARE_BRACKET,
            TokenType.INDEX])) {
          return new ExpressionStatement.full(parseExpression2(), expect2(TokenType.SEMICOLON));
        } else if (matches4(peek(), TokenType.IDENTIFIER)) {
          Token afterType = skipTypeName(peek());
          if (afterType != null) {
            if (matches4(afterType, TokenType.OPEN_PAREN) || (matches4(afterType, TokenType.PERIOD) && matches4(afterType.next, TokenType.IDENTIFIER) && matches4(afterType.next.next, TokenType.OPEN_PAREN))) {
              return new ExpressionStatement.full(parseExpression2(), expect2(TokenType.SEMICOLON));
            }
          }
        }
        return parseVariableDeclarationStatement(commentAndMetadata);
      } else if (identical(keyword, Keyword.NEW) || identical(keyword, Keyword.TRUE) || identical(keyword, Keyword.FALSE) || identical(keyword, Keyword.NULL) || identical(keyword, Keyword.SUPER) || identical(keyword, Keyword.THIS)) {
        return new ExpressionStatement.full(parseExpression2(), expect2(TokenType.SEMICOLON));
      } else {
        reportError10(ParserErrorCode.MISSING_STATEMENT, []);
        return new EmptyStatement.full(createSyntheticToken2(TokenType.SEMICOLON));
      }
    } else if (matches5(TokenType.SEMICOLON)) {
      return parseEmptyStatement();
    } else if (isInitializedVariableDeclaration()) {
      return parseVariableDeclarationStatement(commentAndMetadata);
    } else if (isFunctionDeclaration()) {
      return parseFunctionDeclarationStatement();
    } else if (matches5(TokenType.CLOSE_CURLY_BRACKET)) {
      reportError10(ParserErrorCode.MISSING_STATEMENT, []);
      return new EmptyStatement.full(createSyntheticToken2(TokenType.SEMICOLON));
    } else {
      return new ExpressionStatement.full(parseExpression2(), expect2(TokenType.SEMICOLON));
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
    if (matches(Keyword.OPERATOR)) {
      operatorKeyword = andAdvance;
    } else {
      reportError11(ParserErrorCode.MISSING_KEYWORD_OPERATOR, _currentToken, []);
      operatorKeyword = createSyntheticToken(Keyword.OPERATOR);
    }
    if (!_currentToken.isUserDefinableOperator) {
      reportError10(ParserErrorCode.NON_USER_DEFINABLE_OPERATOR, [_currentToken.lexeme]);
    }
    SimpleIdentifier name = new SimpleIdentifier.full(andAdvance);
    if (matches5(TokenType.EQ)) {
      Token previous = _currentToken.previous;
      if ((matches4(previous, TokenType.EQ_EQ) || matches4(previous, TokenType.BANG_EQ)) && _currentToken.offset == previous.offset + 2) {
        reportError10(ParserErrorCode.INVALID_OPERATOR, ["${previous.lexeme}${_currentToken.lexeme}"]);
        advance();
      }
    }
    FormalParameterList parameters = parseFormalParameterList();
    validateFormalParameterList(parameters);
    FunctionBody body = parseFunctionBody(true, ParserErrorCode.MISSING_FUNCTION_BODY, false);
    if (externalKeyword != null && body is! EmptyFunctionBody) {
      reportError10(ParserErrorCode.EXTERNAL_OPERATOR_WITH_BODY, []);
    }
    return new MethodDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, externalKeyword, null, returnType, null, operatorKeyword, name, parameters, body);
  }

  /**
   * Parse a return type if one is given, otherwise return `null` without advancing.
   *
   * @return the return type that was parsed
   */
  TypeName parseOptionalReturnType() {
    if (matches(Keyword.VOID)) {
      return parseReturnType();
    } else if (matchesIdentifier() && !matches(Keyword.GET) && !matches(Keyword.SET) && !matches(Keyword.OPERATOR) && (matchesIdentifier2(peek()) || matches4(peek(), TokenType.LT))) {
      return parseReturnType();
    } else if (matchesIdentifier() && matches4(peek(), TokenType.PERIOD) && matchesIdentifier2(peek2(2)) && (matchesIdentifier2(peek2(3)) || matches4(peek2(3), TokenType.LT))) {
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
    Token partKeyword = expect(Keyword.PART);
    if (matches2(_OF)) {
      Token ofKeyword = andAdvance;
      LibraryIdentifier libraryName = parseLibraryName(ParserErrorCode.MISSING_NAME_IN_PART_OF_DIRECTIVE, ofKeyword);
      Token semicolon = expect2(TokenType.SEMICOLON);
      return new PartOfDirective.full(commentAndMetadata.comment, commentAndMetadata.metadata, partKeyword, ofKeyword, libraryName, semicolon);
    }
    StringLiteral partUri = parseStringLiteral();
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new PartDirective.full(commentAndMetadata.comment, commentAndMetadata.metadata, partKeyword, partUri, semicolon);
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
    if (matches5(TokenType.OPEN_SQUARE_BRACKET) || matches5(TokenType.PERIOD) || matches5(TokenType.OPEN_PAREN)) {
      do {
        if (matches5(TokenType.OPEN_PAREN)) {
          ArgumentList argumentList = parseArgumentList();
          if (operand is PropertyAccess) {
            PropertyAccess access = operand as PropertyAccess;
            operand = new MethodInvocation.full(access.target, access.operator, access.propertyName, argumentList);
          } else {
            operand = new FunctionExpressionInvocation.full(operand, argumentList);
          }
        } else {
          operand = parseAssignableSelector(operand, true);
        }
      } while (matches5(TokenType.OPEN_SQUARE_BRACKET) || matches5(TokenType.PERIOD) || matches5(TokenType.OPEN_PAREN));
      return operand;
    }
    if (!_currentToken.type.isIncrementOperator) {
      return operand;
    }
    if (operand is Literal || operand is FunctionExpressionInvocation) {
      reportError10(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, []);
    }
    Token operator = andAdvance;
    return new PostfixExpression.full(operand, operator);
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
    if (matches(Keyword.THIS)) {
      return new ThisExpression.full(andAdvance);
    } else if (matches(Keyword.SUPER)) {
      return parseAssignableSelector(new SuperExpression.full(andAdvance), false);
    } else if (matches(Keyword.NULL)) {
      return new NullLiteral.full(andAdvance);
    } else if (matches(Keyword.FALSE)) {
      return new BooleanLiteral.full(andAdvance, false);
    } else if (matches(Keyword.TRUE)) {
      return new BooleanLiteral.full(andAdvance, true);
    } else if (matches5(TokenType.DOUBLE)) {
      Token token = andAdvance;
      double value = 0.0;
      try {
        value = double.parse(token.lexeme);
      } on FormatException catch (exception) {
      }
      return new DoubleLiteral.full(token, value);
    } else if (matches5(TokenType.HEXADECIMAL)) {
      Token token = andAdvance;
      int value = null;
      try {
        value = int.parse(token.lexeme.substring(2), radix: 16);
      } on FormatException catch (exception) {
      }
      return new IntegerLiteral.full(token, value);
    } else if (matches5(TokenType.INT)) {
      Token token = andAdvance;
      int value = null;
      try {
        value = int.parse(token.lexeme);
      } on FormatException catch (exception) {
      }
      return new IntegerLiteral.full(token, value);
    } else if (matches5(TokenType.STRING)) {
      return parseStringLiteral();
    } else if (matches5(TokenType.OPEN_CURLY_BRACKET)) {
      return parseMapLiteral(null, null);
    } else if (matches5(TokenType.OPEN_SQUARE_BRACKET) || matches5(TokenType.INDEX)) {
      return parseListLiteral(null, null);
    } else if (matchesIdentifier()) {
      return parsePrefixedIdentifier();
    } else if (matches(Keyword.NEW)) {
      return parseNewExpression();
    } else if (matches(Keyword.CONST)) {
      return parseConstExpression();
    } else if (matches5(TokenType.OPEN_PAREN)) {
      if (isFunctionExpression(_currentToken)) {
        return parseFunctionExpression();
      }
      Token leftParenthesis = andAdvance;
      Expression expression = parseExpression2();
      Token rightParenthesis = expect2(TokenType.CLOSE_PAREN);
      return new ParenthesizedExpression.full(leftParenthesis, expression, rightParenthesis);
    } else if (matches5(TokenType.LT)) {
      return parseListOrMapLiteral(null);
    } else if (matches5(TokenType.QUESTION)) {
      return parseArgumentDefinitionTest();
    } else if (matches(Keyword.VOID)) {
      reportError10(ParserErrorCode.UNEXPECTED_TOKEN, [_currentToken.lexeme]);
      advance();
      return parsePrimaryExpression();
    } else if (matches5(TokenType.HASH)) {
      return parseSymbolLiteral();
    } else {
      reportError10(ParserErrorCode.MISSING_IDENTIFIER, []);
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
    Token keyword = expect(Keyword.THIS);
    Token period = null;
    SimpleIdentifier constructorName = null;
    if (matches5(TokenType.PERIOD)) {
      period = andAdvance;
      constructorName = parseSimpleIdentifier();
    }
    ArgumentList argumentList = parseArgumentList();
    return new RedirectingConstructorInvocation.full(keyword, period, constructorName, argumentList);
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
    if (matches(Keyword.SUPER) && _currentToken.next.type.isRelationalOperator) {
      Expression expression = new SuperExpression.full(andAdvance);
      Token operator = andAdvance;
      expression = new BinaryExpression.full(expression, operator, parseBitwiseOrExpression());
      return expression;
    }
    Expression expression = parseBitwiseOrExpression();
    if (matches(Keyword.AS)) {
      Token asOperator = andAdvance;
      expression = new AsExpression.full(expression, asOperator, parseTypeName());
    } else if (matches(Keyword.IS)) {
      Token isOperator = andAdvance;
      Token notOperator = null;
      if (matches5(TokenType.BANG)) {
        notOperator = andAdvance;
      }
      expression = new IsExpression.full(expression, isOperator, notOperator, parseTypeName());
    } else if (_currentToken.type.isRelationalOperator) {
      Token operator = andAdvance;
      expression = new BinaryExpression.full(expression, operator, parseBitwiseOrExpression());
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
  Expression parseRethrowExpression() => new RethrowExpression.full(expect(Keyword.RETHROW));

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
    Token returnKeyword = expect(Keyword.RETURN);
    if (matches5(TokenType.SEMICOLON)) {
      return new ReturnStatement.full(returnKeyword, null, andAdvance);
    }
    Expression expression = parseExpression2();
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new ReturnStatement.full(returnKeyword, expression, semicolon);
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
    Token propertyKeyword = expect(Keyword.SET);
    SimpleIdentifier name = parseSimpleIdentifier();
    FormalParameterList parameters = parseFormalParameterList();
    validateFormalParameterList(parameters);
    FunctionBody body = parseFunctionBody(externalKeyword != null || staticKeyword == null, ParserErrorCode.STATIC_SETTER_WITHOUT_BODY, false);
    if (externalKeyword != null && body is! EmptyFunctionBody) {
      reportError10(ParserErrorCode.EXTERNAL_SETTER_WITH_BODY, []);
    }
    return new MethodDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, externalKeyword, staticKeyword, returnType, propertyKeyword, null, name, parameters, body);
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
    if (matches(Keyword.SUPER) && _currentToken.next.type.isShiftOperator) {
      expression = new SuperExpression.full(andAdvance);
    } else {
      expression = parseAdditiveExpression();
    }
    while (_currentToken.type.isShiftOperator) {
      Token operator = andAdvance;
      expression = new BinaryExpression.full(expression, operator, parseAdditiveExpression());
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
  List<Statement> parseStatements2() {
    List<Statement> statements = new List<Statement>();
    Token statementStart = _currentToken;
    while (!matches5(TokenType.EOF) && !matches5(TokenType.CLOSE_CURLY_BRACKET) && !isSwitchMember()) {
      statements.add(parseStatement2());
      if (identical(_currentToken, statementStart)) {
        reportError11(ParserErrorCode.UNEXPECTED_TOKEN, _currentToken, [_currentToken.lexeme]);
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
    bool hasMore = matches5(TokenType.STRING_INTERPOLATION_EXPRESSION) || matches5(TokenType.STRING_INTERPOLATION_IDENTIFIER);
    elements.add(new InterpolationString.full(string, computeStringValue(string.lexeme, true, !hasMore)));
    while (hasMore) {
      if (matches5(TokenType.STRING_INTERPOLATION_EXPRESSION)) {
        Token openToken = andAdvance;
        Expression expression = parseExpression2();
        Token rightBracket = expect2(TokenType.CLOSE_CURLY_BRACKET);
        elements.add(new InterpolationExpression.full(openToken, expression, rightBracket));
      } else {
        Token openToken = andAdvance;
        Expression expression = null;
        if (matches(Keyword.THIS)) {
          expression = new ThisExpression.full(andAdvance);
        } else {
          expression = parseSimpleIdentifier();
        }
        elements.add(new InterpolationExpression.full(openToken, expression, null));
      }
      if (matches5(TokenType.STRING)) {
        string = andAdvance;
        hasMore = matches5(TokenType.STRING_INTERPOLATION_EXPRESSION) || matches5(TokenType.STRING_INTERPOLATION_IDENTIFIER);
        elements.add(new InterpolationString.full(string, computeStringValue(string.lexeme, false, !hasMore)));
      }
    }
    return new StringInterpolation.full(elements);
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
    Token keyword = expect(Keyword.SUPER);
    Token period = null;
    SimpleIdentifier constructorName = null;
    if (matches5(TokenType.PERIOD)) {
      period = andAdvance;
      constructorName = parseSimpleIdentifier();
    }
    ArgumentList argumentList = parseArgumentList();
    return new SuperConstructorInvocation.full(keyword, period, constructorName, argumentList);
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
      Token keyword = expect(Keyword.SWITCH);
      Token leftParenthesis = expect2(TokenType.OPEN_PAREN);
      Expression expression = parseExpression2();
      Token rightParenthesis = expect2(TokenType.CLOSE_PAREN);
      Token leftBracket = expect2(TokenType.OPEN_CURLY_BRACKET);
      Token defaultKeyword = null;
      List<SwitchMember> members = new List<SwitchMember>();
      while (!matches5(TokenType.EOF) && !matches5(TokenType.CLOSE_CURLY_BRACKET)) {
        List<Label> labels = new List<Label>();
        while (matchesIdentifier() && matches4(peek(), TokenType.COLON)) {
          SimpleIdentifier identifier = parseSimpleIdentifier();
          String label = identifier.token.lexeme;
          if (definedLabels.contains(label)) {
            reportError11(ParserErrorCode.DUPLICATE_LABEL_IN_SWITCH_STATEMENT, identifier.token, [label]);
          } else {
            definedLabels.add(label);
          }
          Token colon = expect2(TokenType.COLON);
          labels.add(new Label.full(identifier, colon));
        }
        if (matches(Keyword.CASE)) {
          Token caseKeyword = andAdvance;
          Expression caseExpression = parseExpression2();
          Token colon = expect2(TokenType.COLON);
          members.add(new SwitchCase.full(labels, caseKeyword, caseExpression, colon, parseStatements2()));
          if (defaultKeyword != null) {
            reportError11(ParserErrorCode.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE, caseKeyword, []);
          }
        } else if (matches(Keyword.DEFAULT)) {
          if (defaultKeyword != null) {
            reportError11(ParserErrorCode.SWITCH_HAS_MULTIPLE_DEFAULT_CASES, peek(), []);
          }
          defaultKeyword = andAdvance;
          Token colon = expect2(TokenType.COLON);
          members.add(new SwitchDefault.full(labels, defaultKeyword, colon, parseStatements2()));
        } else {
          reportError10(ParserErrorCode.EXPECTED_CASE_OR_DEFAULT, []);
          while (!matches5(TokenType.EOF) && !matches5(TokenType.CLOSE_CURLY_BRACKET) && !matches(Keyword.CASE) && !matches(Keyword.DEFAULT)) {
            advance();
          }
        }
      }
      Token rightBracket = expect2(TokenType.CLOSE_CURLY_BRACKET);
      return new SwitchStatement.full(keyword, leftParenthesis, expression, rightParenthesis, leftBracket, members, rightBracket);
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
      while (matches5(TokenType.PERIOD)) {
        advance();
        if (matchesIdentifier()) {
          components.add(andAdvance);
        } else {
          reportError10(ParserErrorCode.MISSING_IDENTIFIER, []);
          components.add(createSyntheticToken2(TokenType.IDENTIFIER));
          break;
        }
      }
    } else if (_currentToken.isOperator) {
      components.add(andAdvance);
    } else {
      reportError10(ParserErrorCode.MISSING_IDENTIFIER, []);
      components.add(createSyntheticToken2(TokenType.IDENTIFIER));
    }
    return new SymbolLiteral.full(poundSign, new List.from(components));
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
    Token keyword = expect(Keyword.THROW);
    if (matches5(TokenType.SEMICOLON) || matches5(TokenType.CLOSE_PAREN)) {
      reportError11(ParserErrorCode.MISSING_EXPRESSION_IN_THROW, _currentToken, []);
      return new ThrowExpression.full(keyword, createSyntheticIdentifier());
    }
    Expression expression = parseExpression2();
    return new ThrowExpression.full(keyword, expression);
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
    Token keyword = expect(Keyword.THROW);
    if (matches5(TokenType.SEMICOLON) || matches5(TokenType.CLOSE_PAREN)) {
      reportError11(ParserErrorCode.MISSING_EXPRESSION_IN_THROW, _currentToken, []);
      return new ThrowExpression.full(keyword, createSyntheticIdentifier());
    }
    Expression expression = parseExpressionWithoutCascade();
    return new ThrowExpression.full(keyword, expression);
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
    Token tryKeyword = expect(Keyword.TRY);
    Block body = parseBlock();
    List<CatchClause> catchClauses = new List<CatchClause>();
    Block finallyClause = null;
    while (matches2(_ON) || matches(Keyword.CATCH)) {
      Token onKeyword = null;
      TypeName exceptionType = null;
      if (matches2(_ON)) {
        onKeyword = andAdvance;
        exceptionType = parseTypeName();
      }
      Token catchKeyword = null;
      Token leftParenthesis = null;
      SimpleIdentifier exceptionParameter = null;
      Token comma = null;
      SimpleIdentifier stackTraceParameter = null;
      Token rightParenthesis = null;
      if (matches(Keyword.CATCH)) {
        catchKeyword = andAdvance;
        leftParenthesis = expect2(TokenType.OPEN_PAREN);
        exceptionParameter = parseSimpleIdentifier();
        if (matches5(TokenType.COMMA)) {
          comma = andAdvance;
          stackTraceParameter = parseSimpleIdentifier();
        }
        rightParenthesis = expect2(TokenType.CLOSE_PAREN);
      }
      Block catchBody = parseBlock();
      catchClauses.add(new CatchClause.full(onKeyword, exceptionType, catchKeyword, leftParenthesis, exceptionParameter, comma, stackTraceParameter, rightParenthesis, catchBody));
    }
    Token finallyKeyword = null;
    if (matches(Keyword.FINALLY)) {
      finallyKeyword = andAdvance;
      finallyClause = parseBlock();
    } else {
      if (catchClauses.isEmpty) {
        reportError10(ParserErrorCode.MISSING_CATCH_OR_FINALLY, []);
      }
    }
    return new TryStatement.full(tryKeyword, body, catchClauses, finallyKeyword, finallyClause);
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
    Token keyword = expect(Keyword.TYPEDEF);
    if (matchesIdentifier()) {
      Token next = peek();
      if (matches4(next, TokenType.LT)) {
        next = skipTypeParameterList(next);
        if (next != null && matches4(next, TokenType.EQ)) {
          TypeAlias typeAlias = parseClassTypeAlias(commentAndMetadata, keyword);
          reportError11(ParserErrorCode.DEPRECATED_CLASS_TYPE_ALIAS, keyword, []);
          return typeAlias;
        }
      } else if (matches4(next, TokenType.EQ)) {
        TypeAlias typeAlias = parseClassTypeAlias(commentAndMetadata, keyword);
        reportError11(ParserErrorCode.DEPRECATED_CLASS_TYPE_ALIAS, keyword, []);
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
    if (matches5(TokenType.MINUS) || matches5(TokenType.BANG) || matches5(TokenType.TILDE)) {
      Token operator = andAdvance;
      if (matches(Keyword.SUPER)) {
        if (matches4(peek(), TokenType.OPEN_SQUARE_BRACKET) || matches4(peek(), TokenType.PERIOD)) {
          return new PrefixExpression.full(operator, parseUnaryExpression());
        }
        return new PrefixExpression.full(operator, new SuperExpression.full(andAdvance));
      }
      return new PrefixExpression.full(operator, parseUnaryExpression());
    } else if (_currentToken.type.isIncrementOperator) {
      Token operator = andAdvance;
      if (matches(Keyword.SUPER)) {
        if (matches4(peek(), TokenType.OPEN_SQUARE_BRACKET) || matches4(peek(), TokenType.PERIOD)) {
          return new PrefixExpression.full(operator, parseUnaryExpression());
        }
        if (identical(operator.type, TokenType.MINUS_MINUS)) {
          int offset = operator.offset;
          Token firstOperator = new Token(TokenType.MINUS, offset);
          Token secondOperator = new Token(TokenType.MINUS, offset + 1);
          secondOperator.setNext(_currentToken);
          firstOperator.setNext(secondOperator);
          operator.previous.setNext(firstOperator);
          return new PrefixExpression.full(firstOperator, new PrefixExpression.full(secondOperator, new SuperExpression.full(andAdvance)));
        } else {
          reportError10(ParserErrorCode.INVALID_OPERATOR_FOR_SUPER, [operator.lexeme]);
          return new PrefixExpression.full(operator, new SuperExpression.full(andAdvance));
        }
      }
      return new PrefixExpression.full(operator, parseAssignableExpression(false));
    } else if (matches5(TokenType.PLUS)) {
      reportError10(ParserErrorCode.MISSING_IDENTIFIER, []);
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
    if (matches5(TokenType.EQ)) {
      equals = andAdvance;
      initializer = parseExpression2();
    }
    return new VariableDeclaration.full(commentAndMetadata.comment, commentAndMetadata.metadata, name, equals, initializer);
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
  VariableDeclarationList parseVariableDeclarationList(CommentAndMetadata commentAndMetadata) {
    FinalConstVarOrType holder = parseFinalConstVarOrType(false);
    return parseVariableDeclarationList2(commentAndMetadata, holder.keyword, holder.type);
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
  VariableDeclarationList parseVariableDeclarationList2(CommentAndMetadata commentAndMetadata, Token keyword, TypeName type) {
    if (type != null && keyword != null && matches3(keyword, Keyword.VAR)) {
      reportError11(ParserErrorCode.VAR_AND_TYPE, keyword, []);
    }
    List<VariableDeclaration> variables = new List<VariableDeclaration>();
    variables.add(parseVariableDeclaration());
    while (matches5(TokenType.COMMA)) {
      advance();
      variables.add(parseVariableDeclaration());
    }
    return new VariableDeclarationList.full(commentAndMetadata != null ? commentAndMetadata.comment : null, commentAndMetadata != null ? commentAndMetadata.metadata : null, keyword, type, variables);
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
  VariableDeclarationStatement parseVariableDeclarationStatement(CommentAndMetadata commentAndMetadata) {
    VariableDeclarationList variableList = parseVariableDeclarationList(commentAndMetadata);
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new VariableDeclarationStatement.full(variableList, semicolon);
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
  VariableDeclarationStatement parseVariableDeclarationStatement2(CommentAndMetadata commentAndMetadata, Token keyword, TypeName type) {
    VariableDeclarationList variableList = parseVariableDeclarationList2(commentAndMetadata, keyword, type);
    Token semicolon = expect2(TokenType.SEMICOLON);
    return new VariableDeclarationStatement.full(variableList, semicolon);
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
      Token keyword = expect(Keyword.WHILE);
      Token leftParenthesis = expect2(TokenType.OPEN_PAREN);
      Expression condition = parseExpression2();
      Token rightParenthesis = expect2(TokenType.CLOSE_PAREN);
      Statement body = parseStatement2();
      return new WhileStatement.full(keyword, leftParenthesis, condition, rightParenthesis, body);
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
   * @param node the node specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportError9(ParserErrorCode errorCode, ASTNode node, List<Object> arguments) {
    reportError(new AnalysisError.con2(_source, node.offset, node.length, errorCode, arguments));
  }

  /**
   * Report an error with the given error code and arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportError10(ParserErrorCode errorCode, List<Object> arguments) {
    reportError11(errorCode, _currentToken, arguments);
  }

  /**
   * Report an error with the given error code and arguments.
   *
   * @param errorCode the error code of the error to be reported
   * @param token the token specifying the location of the error
   * @param arguments the arguments to the error, used to compose the error message
   */
  void reportError11(ParserErrorCode errorCode, Token token, List<Object> arguments) {
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
    if (matches3(startToken, Keyword.FINAL) || matches3(startToken, Keyword.CONST)) {
      Token next = startToken.next;
      if (matchesIdentifier2(next)) {
        Token next2 = next.next;
        if (matchesIdentifier2(next2) || matches4(next2, TokenType.LT) || matches4(next2, TokenType.PERIOD)) {
          return skipTypeName(next);
        }
        return next;
      }
    } else if (matches3(startToken, Keyword.VAR)) {
      return startToken.next;
    } else if (matchesIdentifier2(startToken)) {
      Token next = startToken.next;
      if (matchesIdentifier2(next) || matches4(next, TokenType.LT) || matches3(next, Keyword.THIS) || (matches4(next, TokenType.PERIOD) && matchesIdentifier2(next.next) && (matchesIdentifier2(next.next.next) || matches4(next.next.next, TokenType.LT) || matches3(next.next.next, Keyword.THIS)))) {
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
    if (!matches4(startToken, TokenType.OPEN_PAREN)) {
      return null;
    }
    Token next = startToken.next;
    if (matches4(next, TokenType.CLOSE_PAREN)) {
      return next.next;
    }
    if (matchesAny(next, [
        TokenType.AT,
        TokenType.OPEN_SQUARE_BRACKET,
        TokenType.OPEN_CURLY_BRACKET]) || matches3(next, Keyword.VOID) || (matchesIdentifier2(next) && (matchesAny(next.next, [TokenType.COMMA, TokenType.CLOSE_PAREN])))) {
      return skipPastMatchingToken(startToken);
    }
    if (matchesIdentifier2(next) && matches4(next.next, TokenType.OPEN_PAREN)) {
      Token afterParameters = skipFormalParameterList(next.next);
      if (afterParameters != null && (matchesAny(afterParameters, [TokenType.COMMA, TokenType.CLOSE_PAREN]))) {
        return skipPastMatchingToken(startToken);
      }
    }
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
    } else if (!matches4(token, TokenType.PERIOD)) {
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
    if (matches3(startToken, Keyword.VOID)) {
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
    if (matches4(startToken, TokenType.IDENTIFIER) || (matches4(startToken, TokenType.KEYWORD) && (startToken as KeywordToken).keyword.isPseudoKeyword)) {
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
    while (token != null && matches4(token, TokenType.STRING)) {
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
    if (!matches4(token, TokenType.LT)) {
      return null;
    }
    token = skipTypeName(token.next);
    if (token == null) {
      return null;
    }
    while (matches4(token, TokenType.COMMA)) {
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
    if (matches4(token, TokenType.LT)) {
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
    if (!matches4(startToken, TokenType.LT)) {
      return null;
    }
    int depth = 1;
    Token next = startToken.next;
    while (depth > 0) {
      if (matches4(next, TokenType.EOF)) {
        return null;
      } else if (matches4(next, TokenType.LT)) {
        depth++;
      } else if (matches4(next, TokenType.GT)) {
        depth--;
      } else if (matches4(next, TokenType.GT_EQ)) {
        if (depth == 1) {
          Token fakeEquals = new Token(TokenType.EQ, next.offset + 2);
          fakeEquals.setNextWithoutSettingPrevious(next.next);
          return fakeEquals;
        }
        depth--;
      } else if (matches4(next, TokenType.GT_GT)) {
        depth -= 2;
      } else if (matches4(next, TokenType.GT_GT_EQ)) {
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
    int length = lexeme.length;
    int currentIndex = index + 1;
    if (currentIndex >= length) {
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
        reportError10(ParserErrorCode.INVALID_HEX_ESCAPE, []);
        return length;
      }
      int firstDigit = lexeme.codeUnitAt(currentIndex + 1);
      int secondDigit = lexeme.codeUnitAt(currentIndex + 2);
      if (!isHexDigit(firstDigit) || !isHexDigit(secondDigit)) {
        reportError10(ParserErrorCode.INVALID_HEX_ESCAPE, []);
      } else {
        builder.appendChar(((Character.digit(firstDigit, 16) << 4) + Character.digit(secondDigit, 16)) as int);
      }
      return currentIndex + 3;
    } else if (currentChar == 0x75) {
      currentIndex++;
      if (currentIndex >= length) {
        reportError10(ParserErrorCode.INVALID_UNICODE_ESCAPE, []);
        return length;
      }
      currentChar = lexeme.codeUnitAt(currentIndex);
      if (currentChar == 0x7B) {
        currentIndex++;
        if (currentIndex >= length) {
          reportError10(ParserErrorCode.INVALID_UNICODE_ESCAPE, []);
          return length;
        }
        currentChar = lexeme.codeUnitAt(currentIndex);
        int digitCount = 0;
        int value = 0;
        while (currentChar != 0x7D) {
          if (!isHexDigit(currentChar)) {
            reportError10(ParserErrorCode.INVALID_UNICODE_ESCAPE, []);
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
            reportError10(ParserErrorCode.INVALID_UNICODE_ESCAPE, []);
            return length;
          }
          currentChar = lexeme.codeUnitAt(currentIndex);
        }
        if (digitCount < 1 || digitCount > 6) {
          reportError10(ParserErrorCode.INVALID_UNICODE_ESCAPE, []);
        }
        appendScalarValue(builder, lexeme.substring(index, currentIndex + 1), value, index, currentIndex);
        return currentIndex + 1;
      } else {
        if (currentIndex + 3 >= length) {
          reportError10(ParserErrorCode.INVALID_UNICODE_ESCAPE, []);
          return length;
        }
        int firstDigit = currentChar;
        int secondDigit = lexeme.codeUnitAt(currentIndex + 1);
        int thirdDigit = lexeme.codeUnitAt(currentIndex + 2);
        int fourthDigit = lexeme.codeUnitAt(currentIndex + 3);
        if (!isHexDigit(firstDigit) || !isHexDigit(secondDigit) || !isHexDigit(thirdDigit) || !isHexDigit(fourthDigit)) {
          reportError10(ParserErrorCode.INVALID_UNICODE_ESCAPE, []);
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
        reportError9(ParserErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, (parameter as FieldFormalParameter).identifier, []);
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
      reportError11(ParserErrorCode.CONST_CLASS, modifiers.constKeyword, []);
    }
    if (modifiers.externalKeyword != null) {
      reportError11(ParserErrorCode.EXTERNAL_CLASS, modifiers.externalKeyword, []);
    }
    if (modifiers.finalKeyword != null) {
      reportError11(ParserErrorCode.FINAL_CLASS, modifiers.finalKeyword, []);
    }
    if (modifiers.varKeyword != null) {
      reportError11(ParserErrorCode.VAR_CLASS, modifiers.varKeyword, []);
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
      reportError10(ParserErrorCode.ABSTRACT_CLASS_MEMBER, []);
    }
    if (modifiers.finalKeyword != null) {
      reportError11(ParserErrorCode.FINAL_CONSTRUCTOR, modifiers.finalKeyword, []);
    }
    if (modifiers.staticKeyword != null) {
      reportError11(ParserErrorCode.STATIC_CONSTRUCTOR, modifiers.staticKeyword, []);
    }
    if (modifiers.varKeyword != null) {
      reportError11(ParserErrorCode.CONSTRUCTOR_WITH_RETURN_TYPE, modifiers.varKeyword, []);
    }
    Token externalKeyword = modifiers.externalKeyword;
    Token constKeyword = modifiers.constKeyword;
    Token factoryKeyword = modifiers.factoryKeyword;
    if (externalKeyword != null && constKeyword != null && constKeyword.offset < externalKeyword.offset) {
      reportError11(ParserErrorCode.EXTERNAL_AFTER_CONST, externalKeyword, []);
    }
    if (externalKeyword != null && factoryKeyword != null && factoryKeyword.offset < externalKeyword.offset) {
      reportError11(ParserErrorCode.EXTERNAL_AFTER_FACTORY, externalKeyword, []);
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
      reportError10(ParserErrorCode.ABSTRACT_CLASS_MEMBER, []);
    }
    if (modifiers.externalKeyword != null) {
      reportError11(ParserErrorCode.EXTERNAL_FIELD, modifiers.externalKeyword, []);
    }
    if (modifiers.factoryKeyword != null) {
      reportError11(ParserErrorCode.NON_CONSTRUCTOR_FACTORY, modifiers.factoryKeyword, []);
    }
    Token staticKeyword = modifiers.staticKeyword;
    Token constKeyword = modifiers.constKeyword;
    Token finalKeyword = modifiers.finalKeyword;
    Token varKeyword = modifiers.varKeyword;
    if (constKeyword != null) {
      if (finalKeyword != null) {
        reportError11(ParserErrorCode.CONST_AND_FINAL, finalKeyword, []);
      }
      if (varKeyword != null) {
        reportError11(ParserErrorCode.CONST_AND_VAR, varKeyword, []);
      }
      if (staticKeyword != null && constKeyword.offset < staticKeyword.offset) {
        reportError11(ParserErrorCode.STATIC_AFTER_CONST, staticKeyword, []);
      }
    } else if (finalKeyword != null) {
      if (varKeyword != null) {
        reportError11(ParserErrorCode.FINAL_AND_VAR, varKeyword, []);
      }
      if (staticKeyword != null && finalKeyword.offset < staticKeyword.offset) {
        reportError11(ParserErrorCode.STATIC_AFTER_FINAL, staticKeyword, []);
      }
    } else if (varKeyword != null && staticKeyword != null && varKeyword.offset < staticKeyword.offset) {
      reportError11(ParserErrorCode.STATIC_AFTER_VAR, staticKeyword, []);
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
      reportError10(ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER, []);
    }
  }

  /**
   * Validate that the given set of modifiers is appropriate for a getter, setter, or method.
   *
   * @param modifiers the modifiers being validated
   */
  void validateModifiersForGetterOrSetterOrMethod(Modifiers modifiers) {
    if (modifiers.abstractKeyword != null) {
      reportError10(ParserErrorCode.ABSTRACT_CLASS_MEMBER, []);
    }
    if (modifiers.constKeyword != null) {
      reportError11(ParserErrorCode.CONST_METHOD, modifiers.constKeyword, []);
    }
    if (modifiers.factoryKeyword != null) {
      reportError11(ParserErrorCode.NON_CONSTRUCTOR_FACTORY, modifiers.factoryKeyword, []);
    }
    if (modifiers.finalKeyword != null) {
      reportError11(ParserErrorCode.FINAL_METHOD, modifiers.finalKeyword, []);
    }
    if (modifiers.varKeyword != null) {
      reportError11(ParserErrorCode.VAR_RETURN_TYPE, modifiers.varKeyword, []);
    }
    Token externalKeyword = modifiers.externalKeyword;
    Token staticKeyword = modifiers.staticKeyword;
    if (externalKeyword != null && staticKeyword != null && staticKeyword.offset < externalKeyword.offset) {
      reportError11(ParserErrorCode.EXTERNAL_AFTER_STATIC, externalKeyword, []);
    }
  }

  /**
   * Validate that the given set of modifiers is appropriate for a getter, setter, or method.
   *
   * @param modifiers the modifiers being validated
   */
  void validateModifiersForOperator(Modifiers modifiers) {
    if (modifiers.abstractKeyword != null) {
      reportError10(ParserErrorCode.ABSTRACT_CLASS_MEMBER, []);
    }
    if (modifiers.constKeyword != null) {
      reportError11(ParserErrorCode.CONST_METHOD, modifiers.constKeyword, []);
    }
    if (modifiers.factoryKeyword != null) {
      reportError11(ParserErrorCode.NON_CONSTRUCTOR_FACTORY, modifiers.factoryKeyword, []);
    }
    if (modifiers.finalKeyword != null) {
      reportError11(ParserErrorCode.FINAL_METHOD, modifiers.finalKeyword, []);
    }
    if (modifiers.staticKeyword != null) {
      reportError11(ParserErrorCode.STATIC_OPERATOR, modifiers.staticKeyword, []);
    }
    if (modifiers.varKeyword != null) {
      reportError11(ParserErrorCode.VAR_RETURN_TYPE, modifiers.varKeyword, []);
    }
  }

  /**
   * Validate that the given set of modifiers is appropriate for a top-level declaration.
   *
   * @param modifiers the modifiers being validated
   */
  void validateModifiersForTopLevelDeclaration(Modifiers modifiers) {
    if (modifiers.factoryKeyword != null) {
      reportError11(ParserErrorCode.FACTORY_TOP_LEVEL_DECLARATION, modifiers.factoryKeyword, []);
    }
    if (modifiers.staticKeyword != null) {
      reportError11(ParserErrorCode.STATIC_TOP_LEVEL_DECLARATION, modifiers.staticKeyword, []);
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
      reportError10(ParserErrorCode.ABSTRACT_TOP_LEVEL_FUNCTION, []);
    }
    if (modifiers.constKeyword != null) {
      reportError11(ParserErrorCode.CONST_CLASS, modifiers.constKeyword, []);
    }
    if (modifiers.finalKeyword != null) {
      reportError11(ParserErrorCode.FINAL_CLASS, modifiers.finalKeyword, []);
    }
    if (modifiers.varKeyword != null) {
      reportError11(ParserErrorCode.VAR_RETURN_TYPE, modifiers.varKeyword, []);
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
      reportError10(ParserErrorCode.ABSTRACT_TOP_LEVEL_VARIABLE, []);
    }
    if (modifiers.externalKeyword != null) {
      reportError11(ParserErrorCode.EXTERNAL_FIELD, modifiers.externalKeyword, []);
    }
    Token constKeyword = modifiers.constKeyword;
    Token finalKeyword = modifiers.finalKeyword;
    Token varKeyword = modifiers.varKeyword;
    if (constKeyword != null) {
      if (finalKeyword != null) {
        reportError11(ParserErrorCode.CONST_AND_FINAL, finalKeyword, []);
      }
      if (varKeyword != null) {
        reportError11(ParserErrorCode.CONST_AND_VAR, varKeyword, []);
      }
    } else if (finalKeyword != null) {
      if (varKeyword != null) {
        reportError11(ParserErrorCode.FINAL_AND_VAR, varKeyword, []);
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
      reportError11(ParserErrorCode.ABSTRACT_TYPEDEF, modifiers.abstractKeyword, []);
    }
    if (modifiers.constKeyword != null) {
      reportError11(ParserErrorCode.CONST_TYPEDEF, modifiers.constKeyword, []);
    }
    if (modifiers.externalKeyword != null) {
      reportError11(ParserErrorCode.EXTERNAL_TYPEDEF, modifiers.externalKeyword, []);
    }
    if (modifiers.finalKeyword != null) {
      reportError11(ParserErrorCode.FINAL_TYPEDEF, modifiers.finalKeyword, []);
    }
    if (modifiers.varKeyword != null) {
      reportError11(ParserErrorCode.VAR_TYPEDEF, modifiers.varKeyword, []);
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
 *
 * @coverage dart.engine.parser
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
class ResolutionCopier implements ASTVisitor<bool> {
  /**
   * Copy resolution data from one node to another.
   *
   * @param fromNode the node from which resolution information will be copied
   * @param toNode the node to which resolution information will be copied
   */
  static void copyResolutionData(ASTNode fromNode, ASTNode toNode) {
    ResolutionCopier copier = new ResolutionCopier();
    copier.isEqual(fromNode, toNode);
  }

  /**
   * The AST node with which the node being visited is to be compared. This is only valid at the
   * beginning of each visit method (until [isEqual] is invoked).
   */
  ASTNode _toNode;

  bool visitAdjacentStrings(AdjacentStrings node) {
    AdjacentStrings toNode = this._toNode as AdjacentStrings;
    return isEqual2(node.strings, toNode.strings);
  }

  bool visitAnnotation(Annotation node) {
    Annotation toNode = this._toNode as Annotation;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual3(node.atSign, toNode.atSign), isEqual(node.name, toNode.name)), isEqual3(node.period, toNode.period)), isEqual(node.constructorName, toNode.constructorName)), isEqual(node.arguments, toNode.arguments))) {
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  bool visitArgumentDefinitionTest(ArgumentDefinitionTest node) {
    ArgumentDefinitionTest toNode = this._toNode as ArgumentDefinitionTest;
    if (javaBooleanAnd(isEqual3(node.question, toNode.question), isEqual(node.identifier, toNode.identifier))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitArgumentList(ArgumentList node) {
    ArgumentList toNode = this._toNode as ArgumentList;
    return javaBooleanAnd(javaBooleanAnd(isEqual3(node.leftParenthesis, toNode.leftParenthesis), isEqual2(node.arguments, toNode.arguments)), isEqual3(node.rightParenthesis, toNode.rightParenthesis));
  }

  bool visitAsExpression(AsExpression node) {
    AsExpression toNode = this._toNode as AsExpression;
    if (javaBooleanAnd(javaBooleanAnd(isEqual(node.expression, toNode.expression), isEqual3(node.asOperator, toNode.asOperator)), isEqual(node.type, toNode.type))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitAssertStatement(AssertStatement node) {
    AssertStatement toNode = this._toNode as AssertStatement;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual3(node.keyword, toNode.keyword), isEqual3(node.leftParenthesis, toNode.leftParenthesis)), isEqual(node.condition, toNode.condition)), isEqual3(node.rightParenthesis, toNode.rightParenthesis)), isEqual3(node.semicolon, toNode.semicolon));
  }

  bool visitAssignmentExpression(AssignmentExpression node) {
    AssignmentExpression toNode = this._toNode as AssignmentExpression;
    if (javaBooleanAnd(javaBooleanAnd(isEqual(node.leftHandSide, toNode.leftHandSide), isEqual3(node.operator, toNode.operator)), isEqual(node.rightHandSide, toNode.rightHandSide))) {
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
    if (javaBooleanAnd(javaBooleanAnd(isEqual(node.leftOperand, toNode.leftOperand), isEqual3(node.operator, toNode.operator)), isEqual(node.rightOperand, toNode.rightOperand))) {
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
    return javaBooleanAnd(javaBooleanAnd(isEqual3(node.leftBracket, toNode.leftBracket), isEqual2(node.statements, toNode.statements)), isEqual3(node.rightBracket, toNode.rightBracket));
  }

  bool visitBlockFunctionBody(BlockFunctionBody node) {
    BlockFunctionBody toNode = this._toNode as BlockFunctionBody;
    return isEqual(node.block, toNode.block);
  }

  bool visitBooleanLiteral(BooleanLiteral node) {
    BooleanLiteral toNode = this._toNode as BooleanLiteral;
    if (javaBooleanAnd(isEqual3(node.literal, toNode.literal), identical(node.value, toNode.value))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitBreakStatement(BreakStatement node) {
    BreakStatement toNode = this._toNode as BreakStatement;
    return javaBooleanAnd(javaBooleanAnd(isEqual3(node.keyword, toNode.keyword), isEqual(node.label, toNode.label)), isEqual3(node.semicolon, toNode.semicolon));
  }

  bool visitCascadeExpression(CascadeExpression node) {
    CascadeExpression toNode = this._toNode as CascadeExpression;
    if (javaBooleanAnd(isEqual(node.target, toNode.target), isEqual2(node.cascadeSections, toNode.cascadeSections))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitCatchClause(CatchClause node) {
    CatchClause toNode = this._toNode as CatchClause;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual3(node.onKeyword, toNode.onKeyword), isEqual(node.exceptionType, toNode.exceptionType)), isEqual3(node.catchKeyword, toNode.catchKeyword)), isEqual3(node.leftParenthesis, toNode.leftParenthesis)), isEqual(node.exceptionParameter, toNode.exceptionParameter)), isEqual3(node.comma, toNode.comma)), isEqual(node.stackTraceParameter, toNode.stackTraceParameter)), isEqual3(node.rightParenthesis, toNode.rightParenthesis)), isEqual(node.body, toNode.body));
  }

  bool visitClassDeclaration(ClassDeclaration node) {
    ClassDeclaration toNode = this._toNode as ClassDeclaration;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.documentationComment, toNode.documentationComment), isEqual2(node.metadata, toNode.metadata)), isEqual3(node.abstractKeyword, toNode.abstractKeyword)), isEqual3(node.classKeyword, toNode.classKeyword)), isEqual(node.name, toNode.name)), isEqual(node.typeParameters, toNode.typeParameters)), isEqual(node.extendsClause, toNode.extendsClause)), isEqual(node.withClause, toNode.withClause)), isEqual(node.implementsClause, toNode.implementsClause)), isEqual3(node.leftBracket, toNode.leftBracket)), isEqual2(node.members, toNode.members)), isEqual3(node.rightBracket, toNode.rightBracket));
  }

  bool visitClassTypeAlias(ClassTypeAlias node) {
    ClassTypeAlias toNode = this._toNode as ClassTypeAlias;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.documentationComment, toNode.documentationComment), isEqual2(node.metadata, toNode.metadata)), isEqual3(node.keyword, toNode.keyword)), isEqual(node.name, toNode.name)), isEqual(node.typeParameters, toNode.typeParameters)), isEqual3(node.equals, toNode.equals)), isEqual3(node.abstractKeyword, toNode.abstractKeyword)), isEqual(node.superclass, toNode.superclass)), isEqual(node.withClause, toNode.withClause)), isEqual(node.implementsClause, toNode.implementsClause)), isEqual3(node.semicolon, toNode.semicolon));
  }

  bool visitComment(Comment node) {
    Comment toNode = this._toNode as Comment;
    return isEqual2(node.references, toNode.references);
  }

  bool visitCommentReference(CommentReference node) {
    CommentReference toNode = this._toNode as CommentReference;
    return javaBooleanAnd(isEqual3(node.newKeyword, toNode.newKeyword), isEqual(node.identifier, toNode.identifier));
  }

  bool visitCompilationUnit(CompilationUnit node) {
    CompilationUnit toNode = this._toNode as CompilationUnit;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual3(node.beginToken, toNode.beginToken), isEqual(node.scriptTag, toNode.scriptTag)), isEqual2(node.directives, toNode.directives)), isEqual2(node.declarations, toNode.declarations)), isEqual3(node.endToken, toNode.endToken))) {
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  bool visitConditionalExpression(ConditionalExpression node) {
    ConditionalExpression toNode = this._toNode as ConditionalExpression;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.condition, toNode.condition), isEqual3(node.question, toNode.question)), isEqual(node.thenExpression, toNode.thenExpression)), isEqual3(node.colon, toNode.colon)), isEqual(node.elseExpression, toNode.elseExpression))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitConstructorDeclaration(ConstructorDeclaration node) {
    ConstructorDeclaration toNode = this._toNode as ConstructorDeclaration;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.documentationComment, toNode.documentationComment), isEqual2(node.metadata, toNode.metadata)), isEqual3(node.externalKeyword, toNode.externalKeyword)), isEqual3(node.constKeyword, toNode.constKeyword)), isEqual3(node.factoryKeyword, toNode.factoryKeyword)), isEqual(node.returnType, toNode.returnType)), isEqual3(node.period, toNode.period)), isEqual(node.name, toNode.name)), isEqual(node.parameters, toNode.parameters)), isEqual3(node.separator, toNode.separator)), isEqual2(node.initializers, toNode.initializers)), isEqual(node.redirectedConstructor, toNode.redirectedConstructor)), isEqual(node.body, toNode.body))) {
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  bool visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    ConstructorFieldInitializer toNode = this._toNode as ConstructorFieldInitializer;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual3(node.keyword, toNode.keyword), isEqual3(node.period, toNode.period)), isEqual(node.fieldName, toNode.fieldName)), isEqual3(node.equals, toNode.equals)), isEqual(node.expression, toNode.expression));
  }

  bool visitConstructorName(ConstructorName node) {
    ConstructorName toNode = this._toNode as ConstructorName;
    if (javaBooleanAnd(javaBooleanAnd(isEqual(node.type, toNode.type), isEqual3(node.period, toNode.period)), isEqual(node.name, toNode.name))) {
      toNode.staticElement = node.staticElement;
      return true;
    }
    return false;
  }

  bool visitContinueStatement(ContinueStatement node) {
    ContinueStatement toNode = this._toNode as ContinueStatement;
    return javaBooleanAnd(javaBooleanAnd(isEqual3(node.keyword, toNode.keyword), isEqual(node.label, toNode.label)), isEqual3(node.semicolon, toNode.semicolon));
  }

  bool visitDeclaredIdentifier(DeclaredIdentifier node) {
    DeclaredIdentifier toNode = this._toNode as DeclaredIdentifier;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.documentationComment, toNode.documentationComment), isEqual2(node.metadata, toNode.metadata)), isEqual3(node.keyword, toNode.keyword)), isEqual(node.type, toNode.type)), isEqual(node.identifier, toNode.identifier));
  }

  bool visitDefaultFormalParameter(DefaultFormalParameter node) {
    DefaultFormalParameter toNode = this._toNode as DefaultFormalParameter;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.parameter, toNode.parameter), identical(node.kind, toNode.kind)), isEqual3(node.separator, toNode.separator)), isEqual(node.defaultValue, toNode.defaultValue));
  }

  bool visitDoStatement(DoStatement node) {
    DoStatement toNode = this._toNode as DoStatement;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual3(node.doKeyword, toNode.doKeyword), isEqual(node.body, toNode.body)), isEqual3(node.whileKeyword, toNode.whileKeyword)), isEqual3(node.leftParenthesis, toNode.leftParenthesis)), isEqual(node.condition, toNode.condition)), isEqual3(node.rightParenthesis, toNode.rightParenthesis)), isEqual3(node.semicolon, toNode.semicolon));
  }

  bool visitDoubleLiteral(DoubleLiteral node) {
    DoubleLiteral toNode = this._toNode as DoubleLiteral;
    if (javaBooleanAnd(isEqual3(node.literal, toNode.literal), node.value == toNode.value)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitEmptyFunctionBody(EmptyFunctionBody node) {
    EmptyFunctionBody toNode = this._toNode as EmptyFunctionBody;
    return isEqual3(node.semicolon, toNode.semicolon);
  }

  bool visitEmptyStatement(EmptyStatement node) {
    EmptyStatement toNode = this._toNode as EmptyStatement;
    return isEqual3(node.semicolon, toNode.semicolon);
  }

  bool visitExportDirective(ExportDirective node) {
    ExportDirective toNode = this._toNode as ExportDirective;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.documentationComment, toNode.documentationComment), isEqual2(node.metadata, toNode.metadata)), isEqual3(node.keyword, toNode.keyword)), isEqual(node.uri, toNode.uri)), isEqual2(node.combinators, toNode.combinators)), isEqual3(node.semicolon, toNode.semicolon))) {
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  bool visitExpressionFunctionBody(ExpressionFunctionBody node) {
    ExpressionFunctionBody toNode = this._toNode as ExpressionFunctionBody;
    return javaBooleanAnd(javaBooleanAnd(isEqual3(node.functionDefinition, toNode.functionDefinition), isEqual(node.expression, toNode.expression)), isEqual3(node.semicolon, toNode.semicolon));
  }

  bool visitExpressionStatement(ExpressionStatement node) {
    ExpressionStatement toNode = this._toNode as ExpressionStatement;
    return javaBooleanAnd(isEqual(node.expression, toNode.expression), isEqual3(node.semicolon, toNode.semicolon));
  }

  bool visitExtendsClause(ExtendsClause node) {
    ExtendsClause toNode = this._toNode as ExtendsClause;
    return javaBooleanAnd(isEqual3(node.keyword, toNode.keyword), isEqual(node.superclass, toNode.superclass));
  }

  bool visitFieldDeclaration(FieldDeclaration node) {
    FieldDeclaration toNode = this._toNode as FieldDeclaration;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.documentationComment, toNode.documentationComment), isEqual2(node.metadata, toNode.metadata)), isEqual3(node.staticKeyword, toNode.staticKeyword)), isEqual(node.fields, toNode.fields)), isEqual3(node.semicolon, toNode.semicolon));
  }

  bool visitFieldFormalParameter(FieldFormalParameter node) {
    FieldFormalParameter toNode = this._toNode as FieldFormalParameter;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.documentationComment, toNode.documentationComment), isEqual2(node.metadata, toNode.metadata)), isEqual3(node.keyword, toNode.keyword)), isEqual(node.type, toNode.type)), isEqual3(node.thisToken, toNode.thisToken)), isEqual3(node.period, toNode.period)), isEqual(node.identifier, toNode.identifier));
  }

  bool visitForEachStatement(ForEachStatement node) {
    ForEachStatement toNode = this._toNode as ForEachStatement;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual3(node.forKeyword, toNode.forKeyword), isEqual3(node.leftParenthesis, toNode.leftParenthesis)), isEqual(node.loopVariable, toNode.loopVariable)), isEqual3(node.inKeyword, toNode.inKeyword)), isEqual(node.iterator, toNode.iterator)), isEqual3(node.rightParenthesis, toNode.rightParenthesis)), isEqual(node.body, toNode.body));
  }

  bool visitFormalParameterList(FormalParameterList node) {
    FormalParameterList toNode = this._toNode as FormalParameterList;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual3(node.leftParenthesis, toNode.leftParenthesis), isEqual2(node.parameters, toNode.parameters)), isEqual3(node.leftDelimiter, toNode.leftDelimiter)), isEqual3(node.rightDelimiter, toNode.rightDelimiter)), isEqual3(node.rightParenthesis, toNode.rightParenthesis));
  }

  bool visitForStatement(ForStatement node) {
    ForStatement toNode = this._toNode as ForStatement;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual3(node.forKeyword, toNode.forKeyword), isEqual3(node.leftParenthesis, toNode.leftParenthesis)), isEqual(node.variables, toNode.variables)), isEqual(node.initialization, toNode.initialization)), isEqual3(node.leftSeparator, toNode.leftSeparator)), isEqual(node.condition, toNode.condition)), isEqual3(node.rightSeparator, toNode.rightSeparator)), isEqual2(node.updaters, toNode.updaters)), isEqual3(node.rightParenthesis, toNode.rightParenthesis)), isEqual(node.body, toNode.body));
  }

  bool visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionDeclaration toNode = this._toNode as FunctionDeclaration;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.documentationComment, toNode.documentationComment), isEqual2(node.metadata, toNode.metadata)), isEqual3(node.externalKeyword, toNode.externalKeyword)), isEqual(node.returnType, toNode.returnType)), isEqual3(node.propertyKeyword, toNode.propertyKeyword)), isEqual(node.name, toNode.name)), isEqual(node.functionExpression, toNode.functionExpression));
  }

  bool visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    FunctionDeclarationStatement toNode = this._toNode as FunctionDeclarationStatement;
    return isEqual(node.functionDeclaration, toNode.functionDeclaration);
  }

  bool visitFunctionExpression(FunctionExpression node) {
    FunctionExpression toNode = this._toNode as FunctionExpression;
    if (javaBooleanAnd(isEqual(node.parameters, toNode.parameters), isEqual(node.body, toNode.body))) {
      toNode.element = node.element;
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    FunctionExpressionInvocation toNode = this._toNode as FunctionExpressionInvocation;
    if (javaBooleanAnd(isEqual(node.function, toNode.function), isEqual(node.argumentList, toNode.argumentList))) {
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
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.documentationComment, toNode.documentationComment), isEqual2(node.metadata, toNode.metadata)), isEqual3(node.keyword, toNode.keyword)), isEqual(node.returnType, toNode.returnType)), isEqual(node.name, toNode.name)), isEqual(node.typeParameters, toNode.typeParameters)), isEqual(node.parameters, toNode.parameters)), isEqual3(node.semicolon, toNode.semicolon));
  }

  bool visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    FunctionTypedFormalParameter toNode = this._toNode as FunctionTypedFormalParameter;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.documentationComment, toNode.documentationComment), isEqual2(node.metadata, toNode.metadata)), isEqual(node.returnType, toNode.returnType)), isEqual(node.identifier, toNode.identifier)), isEqual(node.parameters, toNode.parameters));
  }

  bool visitHideCombinator(HideCombinator node) {
    HideCombinator toNode = this._toNode as HideCombinator;
    return javaBooleanAnd(isEqual3(node.keyword, toNode.keyword), isEqual2(node.hiddenNames, toNode.hiddenNames));
  }

  bool visitIfStatement(IfStatement node) {
    IfStatement toNode = this._toNode as IfStatement;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual3(node.ifKeyword, toNode.ifKeyword), isEqual3(node.leftParenthesis, toNode.leftParenthesis)), isEqual(node.condition, toNode.condition)), isEqual3(node.rightParenthesis, toNode.rightParenthesis)), isEqual(node.thenStatement, toNode.thenStatement)), isEqual3(node.elseKeyword, toNode.elseKeyword)), isEqual(node.elseStatement, toNode.elseStatement));
  }

  bool visitImplementsClause(ImplementsClause node) {
    ImplementsClause toNode = this._toNode as ImplementsClause;
    return javaBooleanAnd(isEqual3(node.keyword, toNode.keyword), isEqual2(node.interfaces, toNode.interfaces));
  }

  bool visitImportDirective(ImportDirective node) {
    ImportDirective toNode = this._toNode as ImportDirective;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.documentationComment, toNode.documentationComment), isEqual2(node.metadata, toNode.metadata)), isEqual3(node.keyword, toNode.keyword)), isEqual(node.uri, toNode.uri)), isEqual3(node.asToken, toNode.asToken)), isEqual(node.prefix, toNode.prefix)), isEqual2(node.combinators, toNode.combinators)), isEqual3(node.semicolon, toNode.semicolon))) {
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  bool visitIndexExpression(IndexExpression node) {
    IndexExpression toNode = this._toNode as IndexExpression;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.target, toNode.target), isEqual3(node.leftBracket, toNode.leftBracket)), isEqual(node.index, toNode.index)), isEqual3(node.rightBracket, toNode.rightBracket))) {
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
    if (javaBooleanAnd(javaBooleanAnd(isEqual3(node.keyword, toNode.keyword), isEqual(node.constructorName, toNode.constructorName)), isEqual(node.argumentList, toNode.argumentList))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticElement = node.staticElement;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitIntegerLiteral(IntegerLiteral node) {
    IntegerLiteral toNode = this._toNode as IntegerLiteral;
    if (javaBooleanAnd(isEqual3(node.literal, toNode.literal), identical(node.value, toNode.value))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitInterpolationExpression(InterpolationExpression node) {
    InterpolationExpression toNode = this._toNode as InterpolationExpression;
    return javaBooleanAnd(javaBooleanAnd(isEqual3(node.leftBracket, toNode.leftBracket), isEqual(node.expression, toNode.expression)), isEqual3(node.rightBracket, toNode.rightBracket));
  }

  bool visitInterpolationString(InterpolationString node) {
    InterpolationString toNode = this._toNode as InterpolationString;
    return javaBooleanAnd(isEqual3(node.contents, toNode.contents), node.value == toNode.value);
  }

  bool visitIsExpression(IsExpression node) {
    IsExpression toNode = this._toNode as IsExpression;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.expression, toNode.expression), isEqual3(node.isOperator, toNode.isOperator)), isEqual3(node.notOperator, toNode.notOperator)), isEqual(node.type, toNode.type))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitLabel(Label node) {
    Label toNode = this._toNode as Label;
    return javaBooleanAnd(isEqual(node.label, toNode.label), isEqual3(node.colon, toNode.colon));
  }

  bool visitLabeledStatement(LabeledStatement node) {
    LabeledStatement toNode = this._toNode as LabeledStatement;
    return javaBooleanAnd(isEqual2(node.labels, toNode.labels), isEqual(node.statement, toNode.statement));
  }

  bool visitLibraryDirective(LibraryDirective node) {
    LibraryDirective toNode = this._toNode as LibraryDirective;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.documentationComment, toNode.documentationComment), isEqual2(node.metadata, toNode.metadata)), isEqual3(node.libraryToken, toNode.libraryToken)), isEqual(node.name, toNode.name)), isEqual3(node.semicolon, toNode.semicolon));
  }

  bool visitLibraryIdentifier(LibraryIdentifier node) {
    LibraryIdentifier toNode = this._toNode as LibraryIdentifier;
    if (isEqual2(node.components, toNode.components)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitListLiteral(ListLiteral node) {
    ListLiteral toNode = this._toNode as ListLiteral;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual3(node.constKeyword, toNode.constKeyword), isEqual(node.typeArguments, toNode.typeArguments)), isEqual3(node.leftBracket, toNode.leftBracket)), isEqual2(node.elements, toNode.elements)), isEqual3(node.rightBracket, toNode.rightBracket))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitMapLiteral(MapLiteral node) {
    MapLiteral toNode = this._toNode as MapLiteral;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual3(node.constKeyword, toNode.constKeyword), isEqual(node.typeArguments, toNode.typeArguments)), isEqual3(node.leftBracket, toNode.leftBracket)), isEqual2(node.entries, toNode.entries)), isEqual3(node.rightBracket, toNode.rightBracket))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitMapLiteralEntry(MapLiteralEntry node) {
    MapLiteralEntry toNode = this._toNode as MapLiteralEntry;
    return javaBooleanAnd(javaBooleanAnd(isEqual(node.key, toNode.key), isEqual3(node.separator, toNode.separator)), isEqual(node.value, toNode.value));
  }

  bool visitMethodDeclaration(MethodDeclaration node) {
    MethodDeclaration toNode = this._toNode as MethodDeclaration;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.documentationComment, toNode.documentationComment), isEqual2(node.metadata, toNode.metadata)), isEqual3(node.externalKeyword, toNode.externalKeyword)), isEqual3(node.modifierKeyword, toNode.modifierKeyword)), isEqual(node.returnType, toNode.returnType)), isEqual3(node.propertyKeyword, toNode.propertyKeyword)), isEqual3(node.propertyKeyword, toNode.propertyKeyword)), isEqual(node.name, toNode.name)), isEqual(node.parameters, toNode.parameters)), isEqual(node.body, toNode.body));
  }

  bool visitMethodInvocation(MethodInvocation node) {
    MethodInvocation toNode = this._toNode as MethodInvocation;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.target, toNode.target), isEqual3(node.period, toNode.period)), isEqual(node.methodName, toNode.methodName)), isEqual(node.argumentList, toNode.argumentList))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitNamedExpression(NamedExpression node) {
    NamedExpression toNode = this._toNode as NamedExpression;
    if (javaBooleanAnd(isEqual(node.name, toNode.name), isEqual(node.expression, toNode.expression))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitNativeClause(NativeClause node) {
    NativeClause toNode = this._toNode as NativeClause;
    return javaBooleanAnd(isEqual3(node.keyword, toNode.keyword), isEqual(node.name, toNode.name));
  }

  bool visitNativeFunctionBody(NativeFunctionBody node) {
    NativeFunctionBody toNode = this._toNode as NativeFunctionBody;
    return javaBooleanAnd(javaBooleanAnd(isEqual3(node.nativeToken, toNode.nativeToken), isEqual(node.stringLiteral, toNode.stringLiteral)), isEqual3(node.semicolon, toNode.semicolon));
  }

  bool visitNullLiteral(NullLiteral node) {
    NullLiteral toNode = this._toNode as NullLiteral;
    if (isEqual3(node.literal, toNode.literal)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitParenthesizedExpression(ParenthesizedExpression node) {
    ParenthesizedExpression toNode = this._toNode as ParenthesizedExpression;
    if (javaBooleanAnd(javaBooleanAnd(isEqual3(node.leftParenthesis, toNode.leftParenthesis), isEqual(node.expression, toNode.expression)), isEqual3(node.rightParenthesis, toNode.rightParenthesis))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitPartDirective(PartDirective node) {
    PartDirective toNode = this._toNode as PartDirective;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.documentationComment, toNode.documentationComment), isEqual2(node.metadata, toNode.metadata)), isEqual3(node.partToken, toNode.partToken)), isEqual(node.uri, toNode.uri)), isEqual3(node.semicolon, toNode.semicolon))) {
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  bool visitPartOfDirective(PartOfDirective node) {
    PartOfDirective toNode = this._toNode as PartOfDirective;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.documentationComment, toNode.documentationComment), isEqual2(node.metadata, toNode.metadata)), isEqual3(node.partToken, toNode.partToken)), isEqual3(node.ofToken, toNode.ofToken)), isEqual(node.libraryName, toNode.libraryName)), isEqual3(node.semicolon, toNode.semicolon))) {
      toNode.element = node.element;
      return true;
    }
    return false;
  }

  bool visitPostfixExpression(PostfixExpression node) {
    PostfixExpression toNode = this._toNode as PostfixExpression;
    if (javaBooleanAnd(isEqual(node.operand, toNode.operand), isEqual3(node.operator, toNode.operator))) {
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
    if (javaBooleanAnd(javaBooleanAnd(isEqual(node.prefix, toNode.prefix), isEqual3(node.period, toNode.period)), isEqual(node.identifier, toNode.identifier))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitPrefixExpression(PrefixExpression node) {
    PrefixExpression toNode = this._toNode as PrefixExpression;
    if (javaBooleanAnd(isEqual3(node.operator, toNode.operator), isEqual(node.operand, toNode.operand))) {
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
    if (javaBooleanAnd(javaBooleanAnd(isEqual(node.target, toNode.target), isEqual3(node.operator, toNode.operator)), isEqual(node.propertyName, toNode.propertyName))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    RedirectingConstructorInvocation toNode = this._toNode as RedirectingConstructorInvocation;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual3(node.keyword, toNode.keyword), isEqual3(node.period, toNode.period)), isEqual(node.constructorName, toNode.constructorName)), isEqual(node.argumentList, toNode.argumentList))) {
      toNode.staticElement = node.staticElement;
      return true;
    }
    return false;
  }

  bool visitRethrowExpression(RethrowExpression node) {
    RethrowExpression toNode = this._toNode as RethrowExpression;
    if (isEqual3(node.keyword, toNode.keyword)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitReturnStatement(ReturnStatement node) {
    ReturnStatement toNode = this._toNode as ReturnStatement;
    return javaBooleanAnd(javaBooleanAnd(isEqual3(node.keyword, toNode.keyword), isEqual(node.expression, toNode.expression)), isEqual3(node.semicolon, toNode.semicolon));
  }

  bool visitScriptTag(ScriptTag node) {
    ScriptTag toNode = this._toNode as ScriptTag;
    return isEqual3(node.scriptTag, toNode.scriptTag);
  }

  bool visitShowCombinator(ShowCombinator node) {
    ShowCombinator toNode = this._toNode as ShowCombinator;
    return javaBooleanAnd(isEqual3(node.keyword, toNode.keyword), isEqual2(node.shownNames, toNode.shownNames));
  }

  bool visitSimpleFormalParameter(SimpleFormalParameter node) {
    SimpleFormalParameter toNode = this._toNode as SimpleFormalParameter;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.documentationComment, toNode.documentationComment), isEqual2(node.metadata, toNode.metadata)), isEqual3(node.keyword, toNode.keyword)), isEqual(node.type, toNode.type)), isEqual(node.identifier, toNode.identifier));
  }

  bool visitSimpleIdentifier(SimpleIdentifier node) {
    SimpleIdentifier toNode = this._toNode as SimpleIdentifier;
    if (isEqual3(node.token, toNode.token)) {
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
    if (javaBooleanAnd(isEqual3(node.literal, toNode.literal), identical(node.value, toNode.value))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitStringInterpolation(StringInterpolation node) {
    StringInterpolation toNode = this._toNode as StringInterpolation;
    if (isEqual2(node.elements, toNode.elements)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    SuperConstructorInvocation toNode = this._toNode as SuperConstructorInvocation;
    if (javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual3(node.keyword, toNode.keyword), isEqual3(node.period, toNode.period)), isEqual(node.constructorName, toNode.constructorName)), isEqual(node.argumentList, toNode.argumentList))) {
      toNode.staticElement = node.staticElement;
      return true;
    }
    return false;
  }

  bool visitSuperExpression(SuperExpression node) {
    SuperExpression toNode = this._toNode as SuperExpression;
    if (isEqual3(node.keyword, toNode.keyword)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitSwitchCase(SwitchCase node) {
    SwitchCase toNode = this._toNode as SwitchCase;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual2(node.labels, toNode.labels), isEqual3(node.keyword, toNode.keyword)), isEqual(node.expression, toNode.expression)), isEqual3(node.colon, toNode.colon)), isEqual2(node.statements, toNode.statements));
  }

  bool visitSwitchDefault(SwitchDefault node) {
    SwitchDefault toNode = this._toNode as SwitchDefault;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual2(node.labels, toNode.labels), isEqual3(node.keyword, toNode.keyword)), isEqual3(node.colon, toNode.colon)), isEqual2(node.statements, toNode.statements));
  }

  bool visitSwitchStatement(SwitchStatement node) {
    SwitchStatement toNode = this._toNode as SwitchStatement;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual3(node.keyword, toNode.keyword), isEqual3(node.leftParenthesis, toNode.leftParenthesis)), isEqual(node.expression, toNode.expression)), isEqual3(node.rightParenthesis, toNode.rightParenthesis)), isEqual3(node.leftBracket, toNode.leftBracket)), isEqual2(node.members, toNode.members)), isEqual3(node.rightBracket, toNode.rightBracket));
  }

  bool visitSymbolLiteral(SymbolLiteral node) {
    SymbolLiteral toNode = this._toNode as SymbolLiteral;
    if (javaBooleanAnd(isEqual3(node.poundSign, toNode.poundSign), isEqual4(node.components, toNode.components))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitThisExpression(ThisExpression node) {
    ThisExpression toNode = this._toNode as ThisExpression;
    if (isEqual3(node.keyword, toNode.keyword)) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitThrowExpression(ThrowExpression node) {
    ThrowExpression toNode = this._toNode as ThrowExpression;
    if (javaBooleanAnd(isEqual3(node.keyword, toNode.keyword), isEqual(node.expression, toNode.expression))) {
      toNode.propagatedType = node.propagatedType;
      toNode.staticType = node.staticType;
      return true;
    }
    return false;
  }

  bool visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    TopLevelVariableDeclaration toNode = this._toNode as TopLevelVariableDeclaration;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.documentationComment, toNode.documentationComment), isEqual2(node.metadata, toNode.metadata)), isEqual(node.variables, toNode.variables)), isEqual3(node.semicolon, toNode.semicolon));
  }

  bool visitTryStatement(TryStatement node) {
    TryStatement toNode = this._toNode as TryStatement;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual3(node.tryKeyword, toNode.tryKeyword), isEqual(node.body, toNode.body)), isEqual2(node.catchClauses, toNode.catchClauses)), isEqual3(node.finallyKeyword, toNode.finallyKeyword)), isEqual(node.finallyBlock, toNode.finallyBlock));
  }

  bool visitTypeArgumentList(TypeArgumentList node) {
    TypeArgumentList toNode = this._toNode as TypeArgumentList;
    return javaBooleanAnd(javaBooleanAnd(isEqual3(node.leftBracket, toNode.leftBracket), isEqual2(node.arguments, toNode.arguments)), isEqual3(node.rightBracket, toNode.rightBracket));
  }

  bool visitTypeName(TypeName node) {
    TypeName toNode = this._toNode as TypeName;
    if (javaBooleanAnd(isEqual(node.name, toNode.name), isEqual(node.typeArguments, toNode.typeArguments))) {
      toNode.type = node.type;
      return true;
    }
    return false;
  }

  bool visitTypeParameter(TypeParameter node) {
    TypeParameter toNode = this._toNode as TypeParameter;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.documentationComment, toNode.documentationComment), isEqual2(node.metadata, toNode.metadata)), isEqual(node.name, toNode.name)), isEqual3(node.keyword, toNode.keyword)), isEqual(node.bound, toNode.bound));
  }

  bool visitTypeParameterList(TypeParameterList node) {
    TypeParameterList toNode = this._toNode as TypeParameterList;
    return javaBooleanAnd(javaBooleanAnd(isEqual3(node.leftBracket, toNode.leftBracket), isEqual2(node.typeParameters, toNode.typeParameters)), isEqual3(node.rightBracket, toNode.rightBracket));
  }

  bool visitVariableDeclaration(VariableDeclaration node) {
    VariableDeclaration toNode = this._toNode as VariableDeclaration;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.documentationComment, toNode.documentationComment), isEqual2(node.metadata, toNode.metadata)), isEqual(node.name, toNode.name)), isEqual3(node.equals, toNode.equals)), isEqual(node.initializer, toNode.initializer));
  }

  bool visitVariableDeclarationList(VariableDeclarationList node) {
    VariableDeclarationList toNode = this._toNode as VariableDeclarationList;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual(node.documentationComment, toNode.documentationComment), isEqual2(node.metadata, toNode.metadata)), isEqual3(node.keyword, toNode.keyword)), isEqual(node.type, toNode.type)), isEqual2(node.variables, toNode.variables));
  }

  bool visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    VariableDeclarationStatement toNode = this._toNode as VariableDeclarationStatement;
    return javaBooleanAnd(isEqual(node.variables, toNode.variables), isEqual3(node.semicolon, toNode.semicolon));
  }

  bool visitWhileStatement(WhileStatement node) {
    WhileStatement toNode = this._toNode as WhileStatement;
    return javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(javaBooleanAnd(isEqual3(node.keyword, toNode.keyword), isEqual3(node.leftParenthesis, toNode.leftParenthesis)), isEqual(node.condition, toNode.condition)), isEqual3(node.rightParenthesis, toNode.rightParenthesis)), isEqual(node.body, toNode.body));
  }

  bool visitWithClause(WithClause node) {
    WithClause toNode = this._toNode as WithClause;
    return javaBooleanAnd(isEqual3(node.withKeyword, toNode.withKeyword), isEqual2(node.mixinTypes, toNode.mixinTypes));
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
  bool isEqual(ASTNode fromNode, ASTNode toNode) {
    if (fromNode == null) {
      return toNode == null;
    } else if (toNode == null) {
      return false;
    } else if (fromNode.runtimeType == toNode.runtimeType) {
      this._toNode = toNode;
      return fromNode.accept(this);
    }
    if (toNode is PrefixedIdentifier) {
      SimpleIdentifier prefix = (toNode as PrefixedIdentifier).prefix;
      if (fromNode.runtimeType == prefix.runtimeType) {
        this._toNode = prefix;
        return fromNode.accept(this);
      }
    } else if (toNode is PropertyAccess) {
      Expression target = (toNode as PropertyAccess).target;
      if (fromNode.runtimeType == target.runtimeType) {
        this._toNode = target;
        return fromNode.accept(this);
      }
    }
    return false;
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
  bool isEqual2(NodeList first, NodeList second) {
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
      if (!isEqual(first[i], second[i])) {
        equal = false;
      }
    }
    return equal;
  }

  /**
   * Return `true` if the given tokens have the same structure.
   *
   * @param first the first node being compared
   * @param second the second node being compared
   * @return `true` if the given tokens have the same structure
   */
  bool isEqual3(Token first, Token second) {
    if (first == null) {
      return second == null;
    } else if (second == null) {
      return false;
    }
    return first.lexeme == second.lexeme;
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
  bool isEqual4(List<Token> first, List<Token> second) {
    int length = first.length;
    if (second.length != length) {
      return false;
    }
    for (int i = 0; i < length; i++) {
      if (!isEqual3(first[i], second[i])) {
        return false;
      }
    }
    return true;
  }
}

/**
 * Instances of the class {link ToFormattedSourceVisitor} write a source representation of a visited
 * AST node (and all of it's children) to a writer.
 */
class ToFormattedSourceVisitor implements ASTVisitor<Object> {
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
    visitList5(node.strings, " ");
    return null;
  }

  Object visitAnnotation(Annotation node) {
    _writer.print('@');
    visit(node.name);
    visit7(".", node.constructorName);
    visit(node.arguments);
    return null;
  }

  Object visitArgumentDefinitionTest(ArgumentDefinitionTest node) {
    _writer.print('?');
    visit(node.identifier);
    return null;
  }

  Object visitArgumentList(ArgumentList node) {
    _writer.print('(');
    visitList5(node.arguments, ", ");
    _writer.print(')');
    return null;
  }

  Object visitAsExpression(AsExpression node) {
    visit(node.expression);
    _writer.print(" as ");
    visit(node.type);
    return null;
  }

  Object visitAssertStatement(AssertStatement node) {
    _writer.print("assert(");
    visit(node.condition);
    _writer.print(");");
    return null;
  }

  Object visitAssignmentExpression(AssignmentExpression node) {
    visit(node.leftHandSide);
    _writer.print(' ');
    _writer.print(node.operator.lexeme);
    _writer.print(' ');
    visit(node.rightHandSide);
    return null;
  }

  Object visitBinaryExpression(BinaryExpression node) {
    visit(node.leftOperand);
    _writer.print(' ');
    _writer.print(node.operator.lexeme);
    _writer.print(' ');
    visit(node.rightOperand);
    return null;
  }

  Object visitBlock(Block node) {
    _writer.print('{');
    {
      indentInc();
      visitList7("\n", node.statements, "\n");
      indentDec();
    }
    nl2();
    _writer.print('}');
    return null;
  }

  Object visitBlockFunctionBody(BlockFunctionBody node) {
    visit(node.block);
    return null;
  }

  Object visitBooleanLiteral(BooleanLiteral node) {
    _writer.print(node.literal.lexeme);
    return null;
  }

  Object visitBreakStatement(BreakStatement node) {
    _writer.print("break");
    visit7(" ", node.label);
    _writer.print(";");
    return null;
  }

  Object visitCascadeExpression(CascadeExpression node) {
    visit(node.target);
    visitList(node.cascadeSections);
    return null;
  }

  Object visitCatchClause(CatchClause node) {
    visit7("on ", node.exceptionType);
    if (node.catchKeyword != null) {
      if (node.exceptionType != null) {
        _writer.print(' ');
      }
      _writer.print("catch (");
      visit(node.exceptionParameter);
      visit7(", ", node.stackTraceParameter);
      _writer.print(") ");
    } else {
      _writer.print(" ");
    }
    visit(node.body);
    return null;
  }

  Object visitClassDeclaration(ClassDeclaration node) {
    visit(node.documentationComment);
    visit8(node.abstractKeyword, " ");
    _writer.print("class ");
    visit(node.name);
    visit(node.typeParameters);
    visit7(" ", node.extendsClause);
    visit7(" ", node.withClause);
    visit7(" ", node.implementsClause);
    _writer.print(" {");
    {
      indentInc();
      visitList7("\n", node.members, "\n\n");
      indentDec();
    }
    nl2();
    _writer.print("}");
    return null;
  }

  Object visitClassTypeAlias(ClassTypeAlias node) {
    _writer.print("typedef ");
    visit(node.name);
    visit(node.typeParameters);
    _writer.print(" = ");
    if (node.abstractKeyword != null) {
      _writer.print("abstract ");
    }
    visit(node.superclass);
    visit7(" ", node.withClause);
    visit7(" ", node.implementsClause);
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
    visit(scriptTag);
    String prefix = scriptTag == null ? "" : " ";
    visitList7(prefix, directives, "\n");
    nl();
    prefix = scriptTag == null && directives.isEmpty ? "" : "\n";
    visitList7(prefix, node.declarations, "\n\n");
    return null;
  }

  Object visitConditionalExpression(ConditionalExpression node) {
    visit(node.condition);
    _writer.print(" ? ");
    visit(node.thenExpression);
    _writer.print(" : ");
    visit(node.elseExpression);
    return null;
  }

  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    visit(node.documentationComment);
    visit8(node.externalKeyword, " ");
    visit8(node.constKeyword, " ");
    visit8(node.factoryKeyword, " ");
    visit(node.returnType);
    visit7(".", node.name);
    visit(node.parameters);
    visitList7(" : ", node.initializers, ", ");
    visit7(" = ", node.redirectedConstructor);
    if (node.body is! EmptyFunctionBody) {
      _writer.print(' ');
    }
    visit(node.body);
    return null;
  }

  Object visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    visit8(node.keyword, ".");
    visit(node.fieldName);
    _writer.print(" = ");
    visit(node.expression);
    return null;
  }

  Object visitConstructorName(ConstructorName node) {
    visit(node.type);
    visit7(".", node.name);
    return null;
  }

  Object visitContinueStatement(ContinueStatement node) {
    _writer.print("continue");
    visit7(" ", node.label);
    _writer.print(";");
    return null;
  }

  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    visit8(node.keyword, " ");
    visit6(node.type, " ");
    visit(node.identifier);
    return null;
  }

  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    visit(node.parameter);
    if (node.separator != null) {
      _writer.print(" ");
      _writer.print(node.separator.lexeme);
      visit7(" ", node.defaultValue);
    }
    return null;
  }

  Object visitDoStatement(DoStatement node) {
    _writer.print("do ");
    visit(node.body);
    _writer.print(" while (");
    visit(node.condition);
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
    visit(node.uri);
    visitList7(" ", node.combinators, " ");
    _writer.print(';');
    return null;
  }

  Object visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _writer.print("=> ");
    visit(node.expression);
    if (node.semicolon != null) {
      _writer.print(';');
    }
    return null;
  }

  Object visitExpressionStatement(ExpressionStatement node) {
    visit(node.expression);
    _writer.print(';');
    return null;
  }

  Object visitExtendsClause(ExtendsClause node) {
    _writer.print("extends ");
    visit(node.superclass);
    return null;
  }

  Object visitFieldDeclaration(FieldDeclaration node) {
    visit(node.documentationComment);
    visit8(node.staticKeyword, " ");
    visit(node.fields);
    _writer.print(";");
    return null;
  }

  Object visitFieldFormalParameter(FieldFormalParameter node) {
    visit8(node.keyword, " ");
    visit6(node.type, " ");
    _writer.print("this.");
    visit(node.identifier);
    visit(node.parameters);
    return null;
  }

  Object visitForEachStatement(ForEachStatement node) {
    DeclaredIdentifier loopVariable = node.loopVariable;
    _writer.print("for (");
    if (loopVariable == null) {
      visit(node.identifier);
    } else {
      visit(loopVariable);
    }
    _writer.print(" in ");
    visit(node.iterator);
    _writer.print(") ");
    visit(node.body);
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
      visit(initialization);
    } else {
      visit(node.variables);
    }
    _writer.print(";");
    visit7(" ", node.condition);
    _writer.print(";");
    visitList7(" ", node.updaters, ", ");
    _writer.print(") ");
    visit(node.body);
    return null;
  }

  Object visitFunctionDeclaration(FunctionDeclaration node) {
    visit6(node.returnType, " ");
    visit8(node.propertyKeyword, " ");
    visit(node.name);
    visit(node.functionExpression);
    return null;
  }

  Object visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    visit(node.functionDeclaration);
    _writer.print(';');
    return null;
  }

  Object visitFunctionExpression(FunctionExpression node) {
    visit(node.parameters);
    _writer.print(' ');
    visit(node.body);
    return null;
  }

  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    visit(node.function);
    visit(node.argumentList);
    return null;
  }

  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    _writer.print("typedef ");
    visit6(node.returnType, " ");
    visit(node.name);
    visit(node.typeParameters);
    visit(node.parameters);
    _writer.print(";");
    return null;
  }

  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    visit6(node.returnType, " ");
    visit(node.identifier);
    visit(node.parameters);
    return null;
  }

  Object visitHideCombinator(HideCombinator node) {
    _writer.print("hide ");
    visitList5(node.hiddenNames, ", ");
    return null;
  }

  Object visitIfStatement(IfStatement node) {
    _writer.print("if (");
    visit(node.condition);
    _writer.print(") ");
    visit(node.thenStatement);
    visit7(" else ", node.elseStatement);
    return null;
  }

  Object visitImplementsClause(ImplementsClause node) {
    _writer.print("implements ");
    visitList5(node.interfaces, ", ");
    return null;
  }

  Object visitImportDirective(ImportDirective node) {
    _writer.print("import ");
    visit(node.uri);
    visit7(" as ", node.prefix);
    visitList7(" ", node.combinators, " ");
    _writer.print(';');
    return null;
  }

  Object visitIndexExpression(IndexExpression node) {
    if (node.isCascaded) {
      _writer.print("..");
    } else {
      visit(node.target);
    }
    _writer.print('[');
    visit(node.index);
    _writer.print(']');
    return null;
  }

  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    visit8(node.keyword, " ");
    visit(node.constructorName);
    visit(node.argumentList);
    return null;
  }

  Object visitIntegerLiteral(IntegerLiteral node) {
    _writer.print(node.literal.lexeme);
    return null;
  }

  Object visitInterpolationExpression(InterpolationExpression node) {
    if (node.rightBracket != null) {
      _writer.print("\${");
      visit(node.expression);
      _writer.print("}");
    } else {
      _writer.print("\$");
      visit(node.expression);
    }
    return null;
  }

  Object visitInterpolationString(InterpolationString node) {
    _writer.print(node.contents.lexeme);
    return null;
  }

  Object visitIsExpression(IsExpression node) {
    visit(node.expression);
    if (node.notOperator == null) {
      _writer.print(" is ");
    } else {
      _writer.print(" is! ");
    }
    visit(node.type);
    return null;
  }

  Object visitLabel(Label node) {
    visit(node.label);
    _writer.print(":");
    return null;
  }

  Object visitLabeledStatement(LabeledStatement node) {
    visitList6(node.labels, " ", " ");
    visit(node.statement);
    return null;
  }

  Object visitLibraryDirective(LibraryDirective node) {
    _writer.print("library ");
    visit(node.name);
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
    visit6(node.typeArguments, " ");
    _writer.print("[");
    {
      NodeList<Expression> elements = node.elements;
      if (elements.length < 2 || elements.toString().length < 60) {
        visitList5(elements, ", ");
      } else {
        String elementIndent = "${_indentString}    ";
        _writer.print("\n");
        _writer.print(elementIndent);
        visitList5(elements, ",\n${elementIndent}");
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
    visit6(node.typeArguments, " ");
    _writer.print("{");
    visitList5(node.entries, ", ");
    _writer.print("}");
    return null;
  }

  Object visitMapLiteralEntry(MapLiteralEntry node) {
    visit(node.key);
    _writer.print(" : ");
    visit(node.value);
    return null;
  }

  Object visitMethodDeclaration(MethodDeclaration node) {
    visit(node.documentationComment);
    visit8(node.externalKeyword, " ");
    visit8(node.modifierKeyword, " ");
    visit6(node.returnType, " ");
    visit8(node.propertyKeyword, " ");
    visit8(node.operatorKeyword, " ");
    visit(node.name);
    if (!node.isGetter) {
      visit(node.parameters);
    }
    if (node.body is! EmptyFunctionBody) {
      _writer.print(' ');
    }
    visit(node.body);
    return null;
  }

  Object visitMethodInvocation(MethodInvocation node) {
    if (node.isCascaded) {
      _writer.print("..");
    } else {
      visit6(node.target, ".");
    }
    visit(node.methodName);
    visit(node.argumentList);
    return null;
  }

  Object visitNamedExpression(NamedExpression node) {
    visit(node.name);
    visit7(" ", node.expression);
    return null;
  }

  Object visitNativeClause(NativeClause node) {
    _writer.print("native ");
    visit(node.name);
    return null;
  }

  Object visitNativeFunctionBody(NativeFunctionBody node) {
    _writer.print("native ");
    visit(node.stringLiteral);
    _writer.print(';');
    return null;
  }

  Object visitNullLiteral(NullLiteral node) {
    _writer.print("null");
    return null;
  }

  Object visitParenthesizedExpression(ParenthesizedExpression node) {
    _writer.print('(');
    visit(node.expression);
    _writer.print(')');
    return null;
  }

  Object visitPartDirective(PartDirective node) {
    _writer.print("part ");
    visit(node.uri);
    _writer.print(';');
    return null;
  }

  Object visitPartOfDirective(PartOfDirective node) {
    _writer.print("part of ");
    visit(node.libraryName);
    _writer.print(';');
    return null;
  }

  Object visitPostfixExpression(PostfixExpression node) {
    visit(node.operand);
    _writer.print(node.operator.lexeme);
    return null;
  }

  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    visit(node.prefix);
    _writer.print('.');
    visit(node.identifier);
    return null;
  }

  Object visitPrefixExpression(PrefixExpression node) {
    _writer.print(node.operator.lexeme);
    visit(node.operand);
    return null;
  }

  Object visitPropertyAccess(PropertyAccess node) {
    if (node.isCascaded) {
      _writer.print("..");
    } else {
      visit6(node.target, ".");
    }
    visit(node.propertyName);
    return null;
  }

  Object visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    _writer.print("this");
    visit7(".", node.constructorName);
    visit(node.argumentList);
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
    visitList5(node.shownNames, ", ");
    return null;
  }

  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    visit8(node.keyword, " ");
    visit6(node.type, " ");
    visit(node.identifier);
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
    visitList(node.elements);
    return null;
  }

  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _writer.print("super");
    visit7(".", node.constructorName);
    visit(node.argumentList);
    return null;
  }

  Object visitSuperExpression(SuperExpression node) {
    _writer.print("super");
    return null;
  }

  Object visitSwitchCase(SwitchCase node) {
    visitList6(node.labels, " ", " ");
    _writer.print("case ");
    visit(node.expression);
    _writer.print(": ");
    {
      indentInc();
      visitList5(node.statements, "\n");
      indentDec();
    }
    return null;
  }

  Object visitSwitchDefault(SwitchDefault node) {
    visitList6(node.labels, " ", " ");
    _writer.print("default: ");
    {
      indentInc();
      visitList5(node.statements, "\n");
      indentDec();
    }
    return null;
  }

  Object visitSwitchStatement(SwitchStatement node) {
    _writer.print("switch (");
    visit(node.expression);
    _writer.print(") {");
    {
      indentInc();
      visitList5(node.members, "\n");
      indentDec();
    }
    nl2();
    _writer.print('}');
    return null;
  }

  Object visitSymbolLiteral(SymbolLiteral node) {
    _writer.print("#");
    visitList9(node.components, ".");
    return null;
  }

  Object visitThisExpression(ThisExpression node) {
    _writer.print("this");
    return null;
  }

  Object visitThrowExpression(ThrowExpression node) {
    _writer.print("throw ");
    visit(node.expression);
    return null;
  }

  Object visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    visit6(node.variables, ";");
    return null;
  }

  Object visitTryStatement(TryStatement node) {
    _writer.print("try ");
    visit(node.body);
    visitList7(" ", node.catchClauses, " ");
    visit7(" finally ", node.finallyBlock);
    return null;
  }

  Object visitTypeArgumentList(TypeArgumentList node) {
    _writer.print('<');
    visitList5(node.arguments, ", ");
    _writer.print('>');
    return null;
  }

  Object visitTypeName(TypeName node) {
    visit(node.name);
    visit(node.typeArguments);
    return null;
  }

  Object visitTypeParameter(TypeParameter node) {
    visit(node.name);
    visit7(" extends ", node.bound);
    return null;
  }

  Object visitTypeParameterList(TypeParameterList node) {
    _writer.print('<');
    visitList5(node.typeParameters, ", ");
    _writer.print('>');
    return null;
  }

  Object visitVariableDeclaration(VariableDeclaration node) {
    visit(node.name);
    visit7(" = ", node.initializer);
    return null;
  }

  Object visitVariableDeclarationList(VariableDeclarationList node) {
    visit8(node.keyword, " ");
    visit6(node.type, " ");
    visitList5(node.variables, ", ");
    return null;
  }

  Object visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    visit(node.variables);
    _writer.print(";");
    return null;
  }

  Object visitWhileStatement(WhileStatement node) {
    _writer.print("while (");
    visit(node.condition);
    _writer.print(") ");
    visit(node.body);
    return null;
  }

  Object visitWithClause(WithClause node) {
    _writer.print("with ");
    visitList5(node.mixinTypes, ", ");
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

  /**
   * Safely visit the given node.
   *
   * @param node the node to be visited
   */
  void visit(ASTNode node) {
    if (node != null) {
      node.accept(this);
    }
  }

  /**
   * Safely visit the given node, printing the suffix after the node if it is non-<code>null</code>.
   *
   * @param suffix the suffix to be printed if there is a node to visit
   * @param node the node to be visited
   */
  void visit6(ASTNode node, String suffix) {
    if (node != null) {
      node.accept(this);
      _writer.print(suffix);
    }
  }

  /**
   * Safely visit the given node, printing the prefix before the node if it is non-<code>null</code>
   * .
   *
   * @param prefix the prefix to be printed if there is a node to visit
   * @param node the node to be visited
   */
  void visit7(String prefix, ASTNode node) {
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
  void visit8(Token token, String suffix) {
    if (token != null) {
      _writer.print(token.lexeme);
      _writer.print(suffix);
    }
  }

  /**
   * Print a list of nodes without any separation.
   *
   * @param nodes the nodes to be printed
   * @param separator the separator to be printed between adjacent nodes
   */
  void visitList(NodeList<ASTNode> nodes) {
    visitList5(nodes, "");
  }

  /**
   * Print a list of nodes, separated by the given separator.
   *
   * @param nodes the nodes to be printed
   * @param separator the separator to be printed between adjacent nodes
   */
  void visitList5(NodeList<ASTNode> nodes, String separator) {
    visitList8("", nodes, separator, "");
  }

  /**
   * Print a list of nodes, separated by the given separator.
   *
   * @param nodes the nodes to be printed
   * @param separator the separator to be printed between adjacent nodes
   * @param suffix the suffix to be printed if the list is not empty
   */
  void visitList6(NodeList<ASTNode> nodes, String separator, String suffix) {
    visitList8("", nodes, separator, suffix);
  }

  /**
   * Print a list of nodes, separated by the given separator.
   *
   * @param prefix the prefix to be printed if the list is not empty
   * @param nodes the nodes to be printed
   * @param separator the separator to be printed between adjacent nodes
   */
  void visitList7(String prefix, NodeList<ASTNode> nodes, String separator) {
    visitList8(prefix, nodes, separator, "");
  }

  /**
   * Print a list of nodes, separated by the given separator.
   *
   * @param prefix the prefix to be printed if the list is not empty
   * @param nodes the nodes to be printed
   * @param separator the separator to be printed between adjacent nodes
   * @param suffix the suffix to be printed if the list is not empty
   */
  void visitList8(String prefix, NodeList<ASTNode> nodes, String separator, String suffix) {
    if (nodes != null) {
      int size = nodes.length;
      if (size != 0) {
        _writer.print(prefix);
        if (prefix.endsWith("\n")) {
          indent();
        }
        bool newLineSeparator = separator.endsWith("\n");
        for (int i = 0; i < size; i++) {
          if (i > 0) {
            _writer.print(separator);
            if (newLineSeparator) {
              indent();
            }
          }
          nodes[i].accept(this);
        }
        _writer.print(suffix);
      }
    }
  }

  /**
   * Print a list of tokens, separated by the given separator.
   *
   * @param tokens the tokens to be printed
   * @param separator the separator to be printed between adjacent tokens
   */
  void visitList9(List<Token> tokens, String separator) {
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
}