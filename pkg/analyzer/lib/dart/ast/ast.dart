// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Defines the AST model. The AST (Abstract Syntax Tree) model describes the
 * syntactic (as opposed to semantic) structure of Dart code. The semantic
 * structure of the code is modeled by the
 * [element model](../element/element.dart).
 *
 * An AST consists of nodes (instances of a subclass of [AstNode]). The nodes
 * are organized in a tree structure in which the children of a node are the
 * smaller syntactic units from which the node is composed. For example, a
 * binary expression consists of two sub-expressions (the operands) and an
 * operator. The two expressions are represented as nodes. The operator is not
 * represented as a node.
 *
 * The AST is constructed by the parser based on the sequence of tokens produced
 * by the scanner. Most nodes provide direct access to the tokens used to build
 * the node. For example, the token for the operator in a binary expression can
 * be accessed from the node representing the binary expression.
 *
 * While any node can theoretically be the root of an AST structure, almost all
 * of the AST structures known to the analyzer have a [CompilationUnit] as the
 * root of the structure. A compilation unit represents all of the Dart code in
 * a single file.
 *
 * An AST can be either unresolved or resolved. When an AST is unresolved
 * certain properties will not have been computed and the accessors for those
 * properties will return `null`. The documentation for those getters should
 * describe that this is a possibility.
 *
 * When an AST is resolved, the identifiers in the AST will be associated with
 * the elements that they refer to and every expression in the AST will have a
 * type associated with it.
 */
library analyzer.dart.ast.ast;

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart' show AuxiliaryElements;
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart' show LineInfo, Source;
import 'package:analyzer/src/generated/utilities_dart.dart';

/**
 * Two or more string literals that are implicitly concatenated because of being
 * adjacent (separated only by whitespace).
 *
 * While the grammar only allows adjacent strings when all of the strings are of
 * the same kind (single line or multi-line), this class doesn't enforce that
 * restriction.
 *
 *    adjacentStrings ::=
 *        [StringLiteral] [StringLiteral]+
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class AdjacentStrings extends StringLiteral {
  /**
   * Initialize a newly created list of adjacent strings. To be syntactically
   * valid, the list of [strings] must contain at least two elements.
   */
  factory AdjacentStrings(List<StringLiteral> strings) = AdjacentStringsImpl;

  /**
   * Return the strings that are implicitly concatenated.
   */
  NodeList<StringLiteral> get strings;
}

/**
 * An AST node that can be annotated with both a documentation comment and a
 * list of annotations.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class AnnotatedNode extends AstNode {
  /**
   * Return the documentation comment associated with this node, or `null` if
   * this node does not have a documentation comment associated with it.
   */
  Comment get documentationComment;

  /**
   * Set the documentation comment associated with this node to the given
   * [comment].
   */
  void set documentationComment(Comment comment);

  /**
   * Return the first token following the comment and metadata.
   */
  Token get firstTokenAfterCommentAndMetadata;

  /**
   * Return the annotations associated with this node.
   */
  NodeList<Annotation> get metadata;

  /**
   * Return a list containing the comment and annotations associated with this
   * node, sorted in lexical order.
   */
  List<AstNode> get sortedCommentAndAnnotations;
}

/**
 * An annotation that can be associated with an AST node.
 *
 *    metadata ::=
 *        annotation*
 *
 *    annotation ::=
 *        '@' [Identifier] ('.' [SimpleIdentifier])? [ArgumentList]?
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class Annotation extends AstNode {
  /**
   * Initialize a newly created annotation. Both the [period] and the
   * [constructorName] can be `null` if the annotation is not referencing a
   * named constructor. The [arguments] can be `null` if the annotation is not
   * referencing a constructor.
   */
  factory Annotation(Token atSign, Identifier name, Token period,
          SimpleIdentifier constructorName, ArgumentList arguments) =>
      new AnnotationImpl(atSign, name, period, constructorName, arguments);

  /**
   * Return the arguments to the constructor being invoked, or `null` if this
   * annotation is not the invocation of a constructor.
   */
  ArgumentList get arguments;

  /**
   * Set the arguments to the constructor being invoked to the given [arguments].
   */
  void set arguments(ArgumentList arguments);

  /**
   * Return the at sign that introduced the annotation.
   */
  Token get atSign;

  /**
   * Set the at sign that introduced the annotation to the given [token].
   */
  void set atSign(Token token);

  /**
   * Return the name of the constructor being invoked, or `null` if this
   * annotation is not the invocation of a named constructor.
   */
  SimpleIdentifier get constructorName;

  /**
   * Set the name of the constructor being invoked to the given [name].
   */
  void set constructorName(SimpleIdentifier name);

  /**
   * Return the element associated with this annotation, or `null` if the AST
   * structure has not been resolved or if this annotation could not be
   * resolved.
   */
  Element get element;

  /**
   * Set the element associated with this annotation to the given [element].
   */
  void set element(Element element);

  /**
   * Return the element annotation representing this annotation in the element model.
   */
  ElementAnnotation get elementAnnotation;

  /**
   * Set the element annotation representing this annotation in the element
   * model to the given [annotation].
   */
  void set elementAnnotation(ElementAnnotation annotation);

  /**
   * Return the name of the class defining the constructor that is being invoked
   * or the name of the field that is being referenced.
   */
  Identifier get name;

  /**
   * Set the name of the class defining the constructor that is being invoked or
   * the name of the field that is being referenced to the given [name].
   */
  void set name(Identifier name);

  /**
   * Return the period before the constructor name, or `null` if this annotation
   * is not the invocation of a named constructor.
   */
  Token get period;

  /**
   * Set the period before the constructor name to the given [token].
   */
  void set period(Token token);
}

/**
 * A list of arguments in the invocation of an executable element (that is, a
 * function, method, or constructor).
 *
 *    argumentList ::=
 *        '(' arguments? ')'
 *
 *    arguments ::=
 *        [NamedExpression] (',' [NamedExpression])*
 *      | [Expression] (',' [Expression])* (',' [NamedExpression])*
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ArgumentList extends AstNode {
  /**
   * Initialize a newly created list of arguments. The list of [arguments] can
   * be `null` if there are no arguments.
   */
  factory ArgumentList(Token leftParenthesis, List<Expression> arguments,
      Token rightParenthesis) = ArgumentListImpl;

  /**
   * Return the expressions producing the values of the arguments. Although the
   * language requires that positional arguments appear before named arguments,
   * this class allows them to be intermixed.
   */
  NodeList<Expression> get arguments;

  /**
   * Set the parameter elements corresponding to each of the arguments in this
   * list to the given list of [parameters]. The list of parameters must be the
   * same length as the number of arguments, but can contain `null` entries if a
   * given argument does not correspond to a formal parameter.
   */
  void set correspondingPropagatedParameters(List<ParameterElement> parameters);

  /**
   * Set the parameter elements corresponding to each of the arguments in this
   * list to the given list of [parameters]. The list of parameters must be the
   * same length as the number of arguments, but can contain `null` entries if a
   * given argument does not correspond to a formal parameter.
   */
  void set correspondingStaticParameters(List<ParameterElement> parameters);

  /**
   * Return the left parenthesis.
   */
  Token get leftParenthesis;

  /**
   * Set the left parenthesis to the given [token].
   */
  void set leftParenthesis(Token token);

  /**
   * Return the right parenthesis.
   */
  Token get rightParenthesis;

  /**
   * Set the right parenthesis to the given [token].
   */
  void set rightParenthesis(Token token);
}

/**
 * An as expression.
 *
 *    asExpression ::=
 *        [Expression] 'as' [TypeName]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class AsExpression extends Expression {
  /**
   * Initialize a newly created as expression.
   */
  factory AsExpression(
          Expression expression, Token asOperator, TypeName type) =>
      new AsExpressionImpl(expression, asOperator, type);

  /**
   * Return the 'as' operator.
   */
  Token get asOperator;

  /**
   * Set the 'as' operator to the given [token].
   */
  void set asOperator(Token token);

  /**
   * Return the expression used to compute the value being cast.
   */
  Expression get expression;

  /**
   * Set the expression used to compute the value being cast to the given
   * [expression].
   */
  void set expression(Expression expression);

  /**
   * Return the name of the type being cast to.
   */
  TypeName get type;

  /**
   * Set the name of the type being cast to to the given [name].
   */
  void set type(TypeName name);
}

/**
 * An assert statement.
 *
 *    assertStatement ::=
 *        'assert' '(' [Expression] ')' ';'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class AssertStatement extends Statement {
  /**
   * Initialize a newly created assert statement. The [comma] and [message] can
   * be `null` if there is no message.
   */
  factory AssertStatement(
          Token assertKeyword,
          Token leftParenthesis,
          Expression condition,
          Token comma,
          Expression message,
          Token rightParenthesis,
          Token semicolon) =>
      new AssertStatementImpl(assertKeyword, leftParenthesis, condition, comma,
          message, rightParenthesis, semicolon);

  /**
   * Return the token representing the 'assert' keyword.
   */
  Token get assertKeyword;

  /**
   * Set the token representing the 'assert' keyword to the given [token].
   */
  void set assertKeyword(Token token);

  /**
   * Return the comma between the [condition] and the [message], or `null` if no
   * message was supplied.
   */
  Token get comma;

  /**
   * Set the comma between the [condition] and the [message] to the given [token].
   */
  void set comma(Token token);

  /**
   * Return the condition that is being asserted to be `true`.
   */
  Expression get condition;

  /**
   * Set the condition that is being asserted to be `true` to the given
   * [condition].
   */
  void set condition(Expression condition);

  /**
   * Return the left parenthesis.
   */
  Token get leftParenthesis;

  /**
   * Set the left parenthesis to the given [token].
   */
  void set leftParenthesis(Token token);

  /**
   * Return the message to report if the assertion fails, or `null` if no
   * message was supplied.
   */
  Expression get message;

  /**
   * Set the message to report if the assertion fails to the given
   * [expression].
   */
  void set message(Expression expression);

  /**
   *  Return the right parenthesis.
   */
  Token get rightParenthesis;

  /**
   *  Set the right parenthesis to the given [token].
   */
  void set rightParenthesis(Token token);

  /**
   * Return the semicolon terminating the statement.
   */
  Token get semicolon;

  /**
   * Set the semicolon terminating the statement to the given [token].
   */
  void set semicolon(Token token);
}

/**
 * An assignment expression.
 *
 *    assignmentExpression ::=
 *        [Expression] operator [Expression]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class AssignmentExpression extends Expression {
  /**
   * Initialize a newly created assignment expression.
   */
  factory AssignmentExpression(
          Expression leftHandSide, Token operator, Expression rightHandSide) =>
      new AssignmentExpressionImpl(leftHandSide, operator, rightHandSide);

  /**
   * Return the best element available for this operator. If resolution was able
   * to find a better element based on type propagation, that element will be
   * returned. Otherwise, the element found using the result of static analysis
   * will be returned. If resolution has not been performed, then `null` will be
   * returned.
   */
  MethodElement get bestElement;

  /**
   * Return the expression used to compute the left hand side.
   */
  Expression get leftHandSide;

  /**
   * Return the expression used to compute the left hand side.
   */
  void set leftHandSide(Expression expression);

  /**
   * Return the assignment operator being applied.
   */
  Token get operator;

  /**
   * Set the assignment operator being applied to the given [token].
   */
  void set operator(Token token);

  /**
   * Return the element associated with the operator based on the propagated
   * type of the left-hand-side, or `null` if the AST structure has not been
   * resolved, if the operator is not a compound operator, or if the operator
   * could not be resolved.
   */
  MethodElement get propagatedElement;

  /**
   * Set the element associated with the operator based on the propagated
   * type of the left-hand-side to the given [element].
   */
  void set propagatedElement(MethodElement element);

  /**
   * Return the expression used to compute the right hand side.
   */
  Expression get rightHandSide;

  /**
   * Set the expression used to compute the left hand side to the given
   * [expression].
   */
  void set rightHandSide(Expression expression);

  /**
   * Return the element associated with the operator based on the static type of
   * the left-hand-side, or `null` if the AST structure has not been resolved,
   * if the operator is not a compound operator, or if the operator could not be
   * resolved.
   */
  MethodElement get staticElement;

  /**
   * Set the element associated with the operator based on the static type of
   * the left-hand-side to the given [element].
   */
  void set staticElement(MethodElement element);
}

/**
 * A node in the AST structure for a Dart program.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class AstNode {
  /**
   * An empty list of AST nodes.
   */
  static const List<AstNode> EMPTY_LIST = const <AstNode>[];

  /**
   * A comparator that can be used to sort AST nodes in lexical order. In other
   * words, `compare` will return a negative value if the offset of the first
   * node is less than the offset of the second node, zero (0) if the nodes have
   * the same offset, and a positive value if the offset of the first node is
   * greater than the offset of the second node.
   */
  static Comparator<AstNode> LEXICAL_ORDER =
      (AstNode first, AstNode second) => first.offset - second.offset;

  /**
   * Return the first token included in this node's source range.
   */
  Token get beginToken;

  /**
   * Return an iterator that can be used to iterate through all the entities
   * (either AST nodes or tokens) that make up the contents of this node,
   * including doc comments but excluding other comments.
   */
  Iterable /* AstNode | Token */ get childEntities;

  /**
   * Return the offset of the character immediately following the last character
   * of this node's source range. This is equivalent to
   * `node.getOffset() + node.getLength()`. For a compilation unit this will be
   * equal to the length of the unit's source. For synthetic nodes this will be
   * equivalent to the node's offset (because the length is zero (0) by
   * definition).
   */
  int get end;

  /**
   * Return the last token included in this node's source range.
   */
  Token get endToken;

  /**
   * Return `true` if this node is a synthetic node. A synthetic node is a node
   * that was introduced by the parser in order to recover from an error in the
   * code. Synthetic nodes always have a length of zero (`0`).
   */
  bool get isSynthetic;

  /**
   * Return the number of characters in the node's source range.
   */
  int get length;

  /**
   * Return the offset from the beginning of the file to the first character in
   * the node's source range.
   */
  int get offset;

  /**
   * Return this node's parent node, or `null` if this node is the root of an
   * AST structure.
   *
   * Note that the relationship between an AST node and its parent node may
   * change over the lifetime of a node.
   */
  AstNode get parent;

  /**
   * Return the node at the root of this node's AST structure. Note that this
   * method's performance is linear with respect to the depth of the node in the
   * AST structure (O(depth)).
   */
  AstNode get root;

  /**
   * Use the given [visitor] to visit this node. Return the value returned by
   * the visitor as a result of visiting this node.
   */
  dynamic/*=E*/ accept/*<E>*/(AstVisitor/*<E>*/ visitor);

  /**
   * Return the most immediate ancestor of this node for which the [predicate]
   * returns `true`, or `null` if there is no such ancestor. Note that this node
   * will never be returned.
   */
  AstNode/*=E*/ getAncestor/*<E extends AstNode>*/(
      Predicate<AstNode> predicate);

  /**
   * Return the value of the property with the given [name], or `null` if this
   * node does not have a property with the given name.
   */
  Object/*=E*/ getProperty/*<E>*/(String name);

  /**
   * Set the value of the property with the given [name] to the given [value].
   * If the value is `null`, the property will effectively be removed.
   */
  void setProperty(String name, Object value);

  /**
   * Return a textual description of this node in a form approximating valid
   * source. The returned string will not be valid source primarily in the case
   * where the node itself is not well-formed.
   */
  String toSource();

  /**
   * Use the given [visitor] to visit all of the children of this node. The
   * children will be visited in lexical order.
   */
  void visitChildren(AstVisitor visitor);
}

/**
 * An object that can be used to visit an AST structure.
 *
 * Clients may extend or implement this class.
 */
abstract class AstVisitor<R> {
  R visitAdjacentStrings(AdjacentStrings node);

  R visitAnnotation(Annotation node);

  R visitArgumentList(ArgumentList node);

  R visitAsExpression(AsExpression node);

  R visitAssertStatement(AssertStatement assertStatement);

  R visitAssignmentExpression(AssignmentExpression node);

  R visitAwaitExpression(AwaitExpression node);

  R visitBinaryExpression(BinaryExpression node);

  R visitBlock(Block node);

  R visitBlockFunctionBody(BlockFunctionBody node);

  R visitBooleanLiteral(BooleanLiteral node);

  R visitBreakStatement(BreakStatement node);

  R visitCascadeExpression(CascadeExpression node);

  R visitCatchClause(CatchClause node);

  R visitClassDeclaration(ClassDeclaration node);

  R visitClassTypeAlias(ClassTypeAlias node);

  R visitComment(Comment node);

  R visitCommentReference(CommentReference node);

  R visitCompilationUnit(CompilationUnit node);

  R visitConditionalExpression(ConditionalExpression node);

  R visitConfiguration(Configuration node);

  R visitConstructorDeclaration(ConstructorDeclaration node);

  R visitConstructorFieldInitializer(ConstructorFieldInitializer node);

  R visitConstructorName(ConstructorName node);

  R visitContinueStatement(ContinueStatement node);

  R visitDeclaredIdentifier(DeclaredIdentifier node);

  R visitDefaultFormalParameter(DefaultFormalParameter node);

  R visitDoStatement(DoStatement node);

  R visitDottedName(DottedName node);

  R visitDoubleLiteral(DoubleLiteral node);

  R visitEmptyFunctionBody(EmptyFunctionBody node);

  R visitEmptyStatement(EmptyStatement node);

  R visitEnumConstantDeclaration(EnumConstantDeclaration node);

  R visitEnumDeclaration(EnumDeclaration node);

  R visitExportDirective(ExportDirective node);

  R visitExpressionFunctionBody(ExpressionFunctionBody node);

  R visitExpressionStatement(ExpressionStatement node);

  R visitExtendsClause(ExtendsClause node);

  R visitFieldDeclaration(FieldDeclaration node);

  R visitFieldFormalParameter(FieldFormalParameter node);

  R visitForEachStatement(ForEachStatement node);

  R visitFormalParameterList(FormalParameterList node);

  R visitForStatement(ForStatement node);

  R visitFunctionDeclaration(FunctionDeclaration node);

  R visitFunctionDeclarationStatement(FunctionDeclarationStatement node);

  R visitFunctionExpression(FunctionExpression node);

  R visitFunctionExpressionInvocation(FunctionExpressionInvocation node);

  R visitFunctionTypeAlias(FunctionTypeAlias functionTypeAlias);

  R visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node);

  R visitHideCombinator(HideCombinator node);

  R visitIfStatement(IfStatement node);

  R visitImplementsClause(ImplementsClause node);

  R visitImportDirective(ImportDirective node);

  R visitIndexExpression(IndexExpression node);

  R visitInstanceCreationExpression(InstanceCreationExpression node);

  R visitIntegerLiteral(IntegerLiteral node);

  R visitInterpolationExpression(InterpolationExpression node);

  R visitInterpolationString(InterpolationString node);

  R visitIsExpression(IsExpression node);

  R visitLabel(Label node);

  R visitLabeledStatement(LabeledStatement node);

  R visitLibraryDirective(LibraryDirective node);

  R visitLibraryIdentifier(LibraryIdentifier node);

  R visitListLiteral(ListLiteral node);

  R visitMapLiteral(MapLiteral node);

  R visitMapLiteralEntry(MapLiteralEntry node);

  R visitMethodDeclaration(MethodDeclaration node);

  R visitMethodInvocation(MethodInvocation node);

  R visitNamedExpression(NamedExpression node);

  R visitNativeClause(NativeClause node);

  R visitNativeFunctionBody(NativeFunctionBody node);

  R visitNullLiteral(NullLiteral node);

  R visitParenthesizedExpression(ParenthesizedExpression node);

  R visitPartDirective(PartDirective node);

  R visitPartOfDirective(PartOfDirective node);

  R visitPostfixExpression(PostfixExpression node);

  R visitPrefixedIdentifier(PrefixedIdentifier node);

  R visitPrefixExpression(PrefixExpression node);

  R visitPropertyAccess(PropertyAccess node);

  R visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node);

  R visitRethrowExpression(RethrowExpression node);

  R visitReturnStatement(ReturnStatement node);

  R visitScriptTag(ScriptTag node);

  R visitShowCombinator(ShowCombinator node);

  R visitSimpleFormalParameter(SimpleFormalParameter node);

  R visitSimpleIdentifier(SimpleIdentifier node);

  R visitSimpleStringLiteral(SimpleStringLiteral node);

  R visitStringInterpolation(StringInterpolation node);

  R visitSuperConstructorInvocation(SuperConstructorInvocation node);

  R visitSuperExpression(SuperExpression node);

  R visitSwitchCase(SwitchCase node);

  R visitSwitchDefault(SwitchDefault node);

  R visitSwitchStatement(SwitchStatement node);

  R visitSymbolLiteral(SymbolLiteral node);

  R visitThisExpression(ThisExpression node);

  R visitThrowExpression(ThrowExpression node);

  R visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node);

  R visitTryStatement(TryStatement node);

  R visitTypeArgumentList(TypeArgumentList node);

  R visitTypeName(TypeName node);

  R visitTypeParameter(TypeParameter node);

  R visitTypeParameterList(TypeParameterList node);

  R visitVariableDeclaration(VariableDeclaration node);

  R visitVariableDeclarationList(VariableDeclarationList node);

  R visitVariableDeclarationStatement(VariableDeclarationStatement node);

  R visitWhileStatement(WhileStatement node);

  R visitWithClause(WithClause node);

  R visitYieldStatement(YieldStatement node);
}

/**
 * An await expression.
 *
 *    awaitExpression ::=
 *        'await' [Expression]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class AwaitExpression extends Expression {
  /**
   * Initialize a newly created await expression.
   */
  factory AwaitExpression(Token awaitKeyword, Expression expression) =>
      new AwaitExpressionImpl(awaitKeyword, expression);

  /**
   * Return the 'await' keyword.
   */
  Token get awaitKeyword;

  /**
   * Set the 'await' keyword to the given [token].
   */
  void set awaitKeyword(Token token);

  /**
   * Return the expression whose value is being waited on.
   */
  Expression get expression;

  /**
   * Set the expression whose value is being waited on to the given [expression].
   */
  void set expression(Expression expression);
}

/**
 * A binary (infix) expression.
 *
 *    binaryExpression ::=
 *        [Expression] [Token] [Expression]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class BinaryExpression extends Expression {
  /**
   * Initialize a newly created binary expression.
   */
  factory BinaryExpression(
          Expression leftOperand, Token operator, Expression rightOperand) =>
      new BinaryExpressionImpl(leftOperand, operator, rightOperand);

  /**
   * Return the best element available for this operator. If resolution was able
   * to find a better element based on type propagation, that element will be
   * returned. Otherwise, the element found using the result of static analysis
   * will be returned. If resolution has not been performed, then `null` will be
   * returned.
   */
  MethodElement get bestElement;

  /**
   * Return the expression used to compute the left operand.
   */
  Expression get leftOperand;

  /**
   * Set the expression used to compute the left operand to the given
   * [expression].
   */
  void set leftOperand(Expression expression);

  /**
   * Return the binary operator being applied.
   */
  Token get operator;

  /**
   * Set the binary operator being applied to the given [token].
   */
  void set operator(Token token);

  /**
   * Return the element associated with the operator based on the propagated
   * type of the left operand, or `null` if the AST structure has not been
   * resolved, if the operator is not user definable, or if the operator could
   * not be resolved.
   */
  MethodElement get propagatedElement;

  /**
   * Set the element associated with the operator based on the propagated
   * type of the left operand to the given [element].
   */
  void set propagatedElement(MethodElement element);

  /**
   * Return the expression used to compute the right operand.
   */
  Expression get rightOperand;

  /**
   * Set the expression used to compute the right operand to the given
   * [expression].
   */
  void set rightOperand(Expression expression);

  /**
   * Return the element associated with the operator based on the static type of
   * the left operand, or `null` if the AST structure has not been resolved, if
   * the operator is not user definable, or if the operator could not be
   * resolved.
   */
  MethodElement get staticElement;

  /**
   * Set the element associated with the operator based on the static type of
   * the left operand to the given [element].
   */
  void set staticElement(MethodElement element);
}

/**
 * A sequence of statements.
 *
 *    block ::=
 *        '{' statement* '}'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class Block extends Statement {
  /**
   * Initialize a newly created block of code.
   */
  factory Block(
          Token leftBracket, List<Statement> statements, Token rightBracket) =>
      new BlockImpl(leftBracket, statements, rightBracket);

  /**
   * Return the left curly bracket.
   */
  Token get leftBracket;

  /**
   * Set the left curly bracket to the given [token].
   */
  void set leftBracket(Token token);

  /**
   * Return the right curly bracket.
   */
  Token get rightBracket;

  /**
   * Set the right curly bracket to the given [token].
   */
  void set rightBracket(Token token);

  /**
   * Return the statements contained in the block.
   */
  NodeList<Statement> get statements;
}

/**
 * A function body that consists of a block of statements.
 *
 *    blockFunctionBody ::=
 *        ('async' | 'async' '*' | 'sync' '*')? [Block]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class BlockFunctionBody extends FunctionBody {
  /**
   * Initialize a newly created function body consisting of a block of
   * statements. The [keyword] can be `null` if there is no keyword specified
   * for the block. The [star] can be `null` if there is no star following the
   * keyword (and must be `null` if there is no keyword).
   */
  factory BlockFunctionBody(Token keyword, Token star, Block block) =>
      new BlockFunctionBodyImpl(keyword, star, block);

  /**
   * Return the block representing the body of the function.
   */
  Block get block;

  /**
   * Set the block representing the body of the function to the given [block].
   */
  void set block(Block block);

  /**
   * Set token representing the 'async' or 'sync' keyword to the given [token].
   */
  void set keyword(Token token);

  /**
   * Set the star following the 'async' or 'sync' keyword to the given [token].
   */
  void set star(Token token);
}

/**
 * A boolean literal expression.
 *
 *    booleanLiteral ::=
 *        'false' | 'true'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class BooleanLiteral extends Literal {
  /**
   * Initialize a newly created boolean literal.
   */
  factory BooleanLiteral(Token literal, bool value) = BooleanLiteralImpl;

  /**
   * Return the token representing the literal.
   */
  Token get literal;

  /**
   * Set the token representing the literal to the given [token].
   */
  void set literal(Token token);

  /**
   * Return the value of the literal.
   */
  bool get value;
}

/**
 * A break statement.
 *
 *    breakStatement ::=
 *        'break' [SimpleIdentifier]? ';'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class BreakStatement extends Statement {
  /**
   * Initialize a newly created break statement. The [label] can be `null` if
   * there is no label associated with the statement.
   */
  factory BreakStatement(
          Token breakKeyword, SimpleIdentifier label, Token semicolon) =>
      new BreakStatementImpl(breakKeyword, label, semicolon);

  /**
   * Return the token representing the 'break' keyword.
   */
  Token get breakKeyword;

  /**
   * Set the token representing the 'break' keyword to the given [token].
   */
  void set breakKeyword(Token token);

  /**
   * Return the label associated with the statement, or `null` if there is no
   * label.
   */
  SimpleIdentifier get label;

  /**
   * Set the label associated with the statement to the given [identifier].
   */
  void set label(SimpleIdentifier identifier);

  /**
   * Return the semicolon terminating the statement.
   */
  Token get semicolon;

  /**
   * Set the semicolon terminating the statement to the given [token].
   */
  void set semicolon(Token token);

  /**
   * Return the node from which this break statement is breaking. This will be
   * either a [Statement] (in the case of breaking out of a loop), a
   * [SwitchMember] (in the case of a labeled break statement whose label
   * matches a label on a switch case in an enclosing switch statement), or
   * `null` if the AST has not yet been resolved or if the target could not be
   * resolved. Note that if the source code has errors, the target might be
   * invalid (e.g. trying to break to a switch case).
   */
  AstNode get target;

  /**
   * Set the node from which this break statement is breaking to the given
   * [node].
   */
  void set target(AstNode node);
}

/**
 * A sequence of cascaded expressions: expressions that share a common target.
 * There are three kinds of expressions that can be used in a cascade
 * expression: [IndexExpression], [MethodInvocation] and [PropertyAccess].
 *
 *    cascadeExpression ::=
 *        [Expression] cascadeSection*
 *
 *    cascadeSection ::=
 *        '..'  (cascadeSelector arguments*) (assignableSelector arguments*)*
 *        (assignmentOperator expressionWithoutCascade)?
 *
 *    cascadeSelector ::=
 *        '[ ' expression '] '
 *      | identifier
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class CascadeExpression extends Expression {
  /**
   * Initialize a newly created cascade expression. The list of
   * [cascadeSections] must contain at least one element.
   */
  factory CascadeExpression(
          Expression target, List<Expression> cascadeSections) =>
      new CascadeExpressionImpl(target, cascadeSections);

  /**
   * Return the cascade sections sharing the common target.
   */
  NodeList<Expression> get cascadeSections;

  /**
   * Return the target of the cascade sections.
   */
  Expression get target;

  /**
   * Set the target of the cascade sections to the given [target].
   */
  void set target(Expression target);
}

/**
 * A catch clause within a try statement.
 *
 *    onPart ::=
 *        catchPart [Block]
 *      | 'on' type catchPart? [Block]
 *
 *    catchPart ::=
 *        'catch' '(' [SimpleIdentifier] (',' [SimpleIdentifier])? ')'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class CatchClause extends AstNode {
  /**
   * Initialize a newly created catch clause. The [onKeyword] and
   * [exceptionType] can be `null` if the clause will catch all exceptions. The
   * [comma] and [stackTraceParameter] can be `null` if the stack trace
   * parameter is not defined.
   */
  factory CatchClause(
          Token onKeyword,
          TypeName exceptionType,
          Token catchKeyword,
          Token leftParenthesis,
          SimpleIdentifier exceptionParameter,
          Token comma,
          SimpleIdentifier stackTraceParameter,
          Token rightParenthesis,
          Block body) =>
      new CatchClauseImpl(
          onKeyword,
          exceptionType,
          catchKeyword,
          leftParenthesis,
          exceptionParameter,
          comma,
          stackTraceParameter,
          rightParenthesis,
          body);

  /**
   * Return the body of the catch block.
   */
  Block get body;

  /**
   * Set the body of the catch block to the given [block].
   */
  void set body(Block block);

  /**
   * Return the token representing the 'catch' keyword, or `null` if there is no
   * 'catch' keyword.
   */
  Token get catchKeyword;

  /**
   * Set the token representing the 'catch' keyword to the given [token].
   */
  void set catchKeyword(Token token);

  /**
   * Return the comma separating the exception parameter from the stack trace
   * parameter, or `null` if there is no stack trace parameter.
   */
  Token get comma;

  /**
   * Set the comma separating the exception parameter from the stack trace
   * parameter to the given [token].
   */
  void set comma(Token token);

  /**
   * Return the parameter whose value will be the exception that was thrown, or
   * `null` if there is no 'catch' keyword.
   */
  SimpleIdentifier get exceptionParameter;

  /**
   * Set the parameter whose value will be the exception that was thrown to the
   * given [parameter].
   */
  void set exceptionParameter(SimpleIdentifier parameter);

  /**
   * Return the type of exceptions caught by this catch clause, or `null` if
   * this catch clause catches every type of exception.
   */
  TypeName get exceptionType;

  /**
   * Set the type of exceptions caught by this catch clause to the given
   * [exceptionType].
   */
  void set exceptionType(TypeName exceptionType);

  /**
   * Return the left parenthesis, or `null` if there is no 'catch' keyword.
   */
  Token get leftParenthesis;

  /**
   * Set the left parenthesis to the given [token].
   */
  void set leftParenthesis(Token token);

  /**
   * Return the token representing the 'on' keyword, or `null` if there is no 'on'
   * keyword.
   */
  Token get onKeyword;

  /**
   * Set the token representing the 'on' keyword to the given [token].
   */
  void set onKeyword(Token token);

  /**
   * Return the right parenthesis, or `null` if there is no 'catch' keyword.
   */
  Token get rightParenthesis;

  /**
   * Set the right parenthesis to the given [token].
   */
  void set rightParenthesis(Token token);

  /**
   * Return the parameter whose value will be the stack trace associated with
   * the exception, or `null` if there is no stack trace parameter.
   */
  SimpleIdentifier get stackTraceParameter;

  /**
   * Set the parameter whose value will be the stack trace associated with the
   * exception to the given [parameter].
   */
  void set stackTraceParameter(SimpleIdentifier parameter);
}

/**
 * The declaration of a class.
 *
 *    classDeclaration ::=
 *        'abstract'? 'class' [SimpleIdentifier] [TypeParameterList]?
 *        ([ExtendsClause] [WithClause]?)?
 *        [ImplementsClause]?
 *        '{' [ClassMember]* '}'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ClassDeclaration extends NamedCompilationUnitMember {
  /**
   * Initialize a newly created class declaration. Either or both of the
   * [comment] and [metadata] can be `null` if the class does not have the
   * corresponding attribute. The [abstractKeyword] can be `null` if the class
   * is not abstract. The [typeParameters] can be `null` if the class does not
   * have any type parameters. Any or all of the [extendsClause], [withClause],
   * and [implementsClause] can be `null` if the class does not have the
   * corresponding clause. The list of [members] can be `null` if the class does
   * not have any members.
   */
  factory ClassDeclaration(
          Comment comment,
          List<Annotation> metadata,
          Token abstractKeyword,
          Token classKeyword,
          SimpleIdentifier name,
          TypeParameterList typeParameters,
          ExtendsClause extendsClause,
          WithClause withClause,
          ImplementsClause implementsClause,
          Token leftBracket,
          List<ClassMember> members,
          Token rightBracket) =>
      new ClassDeclarationImpl(
          comment,
          metadata,
          abstractKeyword,
          classKeyword,
          name,
          typeParameters,
          extendsClause,
          withClause,
          implementsClause,
          leftBracket,
          members,
          rightBracket);

  /**
   * Return the 'abstract' keyword, or `null` if the keyword was absent.
   */
  Token get abstractKeyword;

  /**
   * Set the 'abstract' keyword to the given [token].
   */
  void set abstractKeyword(Token token);

  /**
   * Return the token representing the 'class' keyword.
   */
  Token get classKeyword;

  /**
   * Set the token representing the 'class' keyword.
   */
  void set classKeyword(Token token);

  @override
  ClassElement get element;

  /**
   * Return the extends clause for this class, or `null` if the class does not
   * extend any other class.
   */
  ExtendsClause get extendsClause;

  /**
   * Set the extends clause for this class to the given [extendsClause].
   */
  void set extendsClause(ExtendsClause extendsClause);

  /**
   * Return the implements clause for the class, or `null` if the class does not
   * implement any interfaces.
   */
  ImplementsClause get implementsClause;

  /**
   * Set the implements clause for the class to the given [implementsClause].
   */
  void set implementsClause(ImplementsClause implementsClause);

  /**
   * Return `true` if this class is declared to be an abstract class.
   */
  bool get isAbstract;

  /**
   * Return the left curly bracket.
   */
  Token get leftBracket;

  /**
   * Set the left curly bracket to the given [token].
   */
  void set leftBracket(Token token);

  /**
   * Return the members defined by the class.
   */
  NodeList<ClassMember> get members;

  /**
   * Return the native clause for this class, or `null` if the class does not
   * have a native clause.
   */
  NativeClause get nativeClause;

  /**
   * Set the native clause for this class to the given [nativeClause].
   */
  void set nativeClause(NativeClause nativeClause);

  /**
   * Return the right curly bracket.
   */
  Token get rightBracket;

  /**
   * Set the right curly bracket to the given [token].
   */
  void set rightBracket(Token token);

  /**
   * Return the type parameters for the class, or `null` if the class does not
   * have any type parameters.
   */
  TypeParameterList get typeParameters;

  /**
   * Set the type parameters for the class to the given list of [typeParameters].
   */
  void set typeParameters(TypeParameterList typeParameters);

  /**
   * Return the with clause for the class, or `null` if the class does not have
   * a with clause.
   */
  WithClause get withClause;

  /**
   * Set the with clause for the class to the given [withClause].
   */
  void set withClause(WithClause withClause);

  /**
   * Return the constructor declared in the class with the given [name], or
   * `null` if there is no such constructor. If the [name] is `null` then the
   * default constructor will be searched for.
   */
  ConstructorDeclaration getConstructor(String name);

  /**
   * Return the field declared in the class with the given [name], or `null` if
   * there is no such field.
   */
  VariableDeclaration getField(String name);

  /**
   * Return the method declared in the class with the given [name], or `null` if
   * there is no such method.
   */
  MethodDeclaration getMethod(String name);
}

/**
 * A node that declares a name within the scope of a class.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ClassMember extends Declaration {}

/**
 * A class type alias.
 *
 *    classTypeAlias ::=
 *        [SimpleIdentifier] [TypeParameterList]? '=' 'abstract'? mixinApplication
 *
 *    mixinApplication ::=
 *        [TypeName] [WithClause] [ImplementsClause]? ';'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ClassTypeAlias extends TypeAlias {
  /**
   * Initialize a newly created class type alias. Either or both of the
   * [comment] and [metadata] can be `null` if the class type alias does not
   * have the corresponding attribute. The [typeParameters] can be `null` if the
   * class does not have any type parameters. The [abstractKeyword] can be
   * `null` if the class is not abstract. The [implementsClause] can be `null`
   * if the class does not implement any interfaces.
   */
  factory ClassTypeAlias(
          Comment comment,
          List<Annotation> metadata,
          Token keyword,
          SimpleIdentifier name,
          TypeParameterList typeParameters,
          Token equals,
          Token abstractKeyword,
          TypeName superclass,
          WithClause withClause,
          ImplementsClause implementsClause,
          Token semicolon) =>
      new ClassTypeAliasImpl(
          comment,
          metadata,
          keyword,
          name,
          typeParameters,
          equals,
          abstractKeyword,
          superclass,
          withClause,
          implementsClause,
          semicolon);

  /**
   * Return the token for the 'abstract' keyword, or `null` if this is not
   * defining an abstract class.
   */
  Token get abstractKeyword;

  /**
   * Set the token for the 'abstract' keyword to the given [token].
   */
  void set abstractKeyword(Token token);

  /**
   * Return the token for the '=' separating the name from the definition.
   */
  Token get equals;

  /**
   * Set the token for the '=' separating the name from the definition to the
   * given [token].
   */
  void set equals(Token token);

  /**
   * Return the implements clause for this class, or `null` if there is no
   * implements clause.
   */
  ImplementsClause get implementsClause;

  /**
   * Set the implements clause for this class to the given [implementsClause].
   */
  void set implementsClause(ImplementsClause implementsClause);

  /**
   * Return `true` if this class is declared to be an abstract class.
   */
  bool get isAbstract;

  /**
   * Return the name of the superclass of the class being declared.
   */
  TypeName get superclass;

  /**
   * Set the name of the superclass of the class being declared to the given
   * [superclass] name.
   */
  void set superclass(TypeName superclass);

  /**
   * Return the type parameters for the class, or `null` if the class does not
   * have any type parameters.
   */
  TypeParameterList get typeParameters;

  /**
   * Set the type parameters for the class to the given list of [typeParameters].
   */
  void set typeParameters(TypeParameterList typeParameters);

  /**
   * Return the with clause for this class.
   */
  WithClause get withClause;

  /**
   * Set the with clause for this class to the given with [withClause].
   */
  void set withClause(WithClause withClause);
}

/**
 * A combinator associated with an import or export directive.
 *
 *    combinator ::=
 *        [HideCombinator]
 *      | [ShowCombinator]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class Combinator extends AstNode {
  /**
   * Return the 'hide' or 'show' keyword specifying what kind of processing is
   * to be done on the names.
   */
  Token get keyword;

  /**
   * Set the 'hide' or 'show' keyword specifying what kind of processing is
   * to be done on the names to the given [token].
   */
  void set keyword(Token token);
}

/**
 * A comment within the source code.
 *
 *    comment ::=
 *        endOfLineComment
 *      | blockComment
 *      | documentationComment
 *
 *    endOfLineComment ::=
 *        '//' (CHARACTER - EOL)* EOL
 *
 *    blockComment ::=
 *        '/ *' CHARACTER* '&#42;/'
 *
 *    documentationComment ::=
 *        '/ **' (CHARACTER | [CommentReference])* '&#42;/'
 *      | ('///' (CHARACTER - EOL)* EOL)+
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class Comment extends AstNode {
  /**
   * Initialize a newly created comment. The list of [tokens] must contain at
   * least one token. The [type] is the type of the comment. The list of
   * [references] can be empty if the comment does not contain any embedded
   * references.
   */
  factory Comment(List<Token> tokens, CommentType type,
      List<CommentReference> references) = CommentImpl;

  /**
   * Return `true` if this is a block comment.
   */
  bool get isBlock;

  /**
   * Return `true` if this is a documentation comment.
   */
  bool get isDocumentation;

  /**
   * Return `true` if this is an end-of-line comment.
   */
  bool get isEndOfLine;

  /**
   * Return the references embedded within the documentation comment.
   */
  NodeList<CommentReference> get references;

  /**
   * Return the tokens representing the comment.
   */
  List<Token> get tokens;

  /**
   * Create a block comment consisting of the given [tokens].
   */
  static Comment createBlockComment(List<Token> tokens) =>
      CommentImpl.createBlockComment(tokens);

  /**
   * Create a documentation comment consisting of the given [tokens].
   */
  static Comment createDocumentationComment(List<Token> tokens) =>
      CommentImpl.createDocumentationComment(tokens);

  /**
   * Create a documentation comment consisting of the given [tokens] and having
   * the given [references] embedded within it.
   */
  static Comment createDocumentationCommentWithReferences(
          List<Token> tokens, List<CommentReference> references) =>
      CommentImpl.createDocumentationCommentWithReferences(tokens, references);

  /**
   * Create an end-of-line comment consisting of the given [tokens].
   */
  static Comment createEndOfLineComment(List<Token> tokens) =>
      CommentImpl.createEndOfLineComment(tokens);
}

/**
 * A reference to a Dart element that is found within a documentation comment.
 *
 *    commentReference ::=
 *        '[' 'new'? [Identifier] ']'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class CommentReference extends AstNode {
  /**
   * Initialize a newly created reference to a Dart element. The [newKeyword]
   * can be `null` if the reference is not to a constructor.
   */
  factory CommentReference(Token newKeyword, Identifier identifier) =>
      new CommentReferenceImpl(newKeyword, identifier);

  /**
   * Return the identifier being referenced.
   */
  Identifier get identifier;

  /**
   * Set the identifier being referenced to the given [identifier].
   */
  void set identifier(Identifier identifier);

  /**
   * Return the token representing the 'new' keyword, or `null` if there was no
   * 'new' keyword.
   */
  Token get newKeyword;

  /**
   * Set the token representing the 'new' keyword to the given [token].
   */
  void set newKeyword(Token token);
}

/**
 * A compilation unit.
 *
 * While the grammar restricts the order of the directives and declarations
 * within a compilation unit, this class does not enforce those restrictions.
 * In particular, the children of a compilation unit will be visited in lexical
 * order even if lexical order does not conform to the restrictions of the
 * grammar.
 *
 *    compilationUnit ::=
 *        directives declarations
 *
 *    directives ::=
 *        [ScriptTag]? [LibraryDirective]? namespaceDirective* [PartDirective]*
 *      | [PartOfDirective]
 *
 *    namespaceDirective ::=
 *        [ImportDirective]
 *      | [ExportDirective]
 *
 *    declarations ::=
 *        [CompilationUnitMember]*
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class CompilationUnit extends AstNode {
  /**
   * Initialize a newly created compilation unit to have the given directives
   * and declarations. The [scriptTag] can be `null` if there is no script tag
   * in the compilation unit. The list of [directives] can be `null` if there
   * are no directives in the compilation unit. The list of [declarations] can
   * be `null` if there are no declarations in the compilation unit.
   */
  factory CompilationUnit(
          Token beginToken,
          ScriptTag scriptTag,
          List<Directive> directives,
          List<CompilationUnitMember> declarations,
          Token endToken) =>
      new CompilationUnitImpl(
          beginToken, scriptTag, directives, declarations, endToken);

  /**
   * Set the first token included in this node's source range to the given
   * [token].
   */
  void set beginToken(Token token);

  /**
   * Return the declarations contained in this compilation unit.
   */
  NodeList<CompilationUnitMember> get declarations;

  /**
   * Return the directives contained in this compilation unit.
   */
  NodeList<Directive> get directives;

  /**
   * Return the element associated with this compilation unit, or `null` if the
   * AST structure has not been resolved.
   */
  CompilationUnitElement get element;

  /**
   * Set the element associated with this compilation unit to the given
   * [element].
   */
  void set element(CompilationUnitElement element);

  /**
   * Set the last token included in this node's source range to the given
   * [token].
   */
  void set endToken(Token token);

  /**
   * Return the line information for this compilation unit.
   */
  LineInfo get lineInfo;

  /**
   * Set the line information for this compilation unit to the given [info].
   */
  void set lineInfo(LineInfo info);

  /**
   * Return the script tag at the beginning of the compilation unit, or `null`
   * if there is no script tag in this compilation unit.
   */
  ScriptTag get scriptTag;

  /**
   * Set the script tag at the beginning of the compilation unit to the given
   * [scriptTag].
   */
  void set scriptTag(ScriptTag scriptTag);

  /**
   * Return a list containing all of the directives and declarations in this
   * compilation unit, sorted in lexical order.
   */
  List<AstNode> get sortedDirectivesAndDeclarations;
}

/**
 * A node that declares one or more names within the scope of a compilation
 * unit.
 *
 *    compilationUnitMember ::=
 *        [ClassDeclaration]
 *      | [TypeAlias]
 *      | [FunctionDeclaration]
 *      | [MethodDeclaration]
 *      | [VariableDeclaration]
 *      | [VariableDeclaration]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class CompilationUnitMember extends Declaration {}

/**
 * A conditional expression.
 *
 *    conditionalExpression ::=
 *        [Expression] '?' [Expression] ':' [Expression]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ConditionalExpression extends Expression {
  /**
   * Initialize a newly created conditional expression.
   */
  factory ConditionalExpression(Expression condition, Token question,
          Expression thenExpression, Token colon, Expression elseExpression) =>
      new ConditionalExpressionImpl(
          condition, question, thenExpression, colon, elseExpression);

  /**
   * Return the token used to separate the then expression from the else
   * expression.
   */
  Token get colon;

  /**
   * Set the token used to separate the then expression from the else expression
   * to the given [token].
   */
  void set colon(Token token);

  /**
   * Return the condition used to determine which of the expressions is executed
   * next.
   */
  Expression get condition;

  /**
   * Set the condition used to determine which of the expressions is executed
   * next to the given [expression].
   */
  void set condition(Expression expression);

  /**
   * Return the expression that is executed if the condition evaluates to
   * `false`.
   */
  Expression get elseExpression;

  /**
   * Set the expression that is executed if the condition evaluates to `false`
   * to the given [expression].
   */
  void set elseExpression(Expression expression);

  /**
   * Return the token used to separate the condition from the then expression.
   */
  Token get question;

  /**
   * Set the token used to separate the condition from the then expression to
   * the given [token].
   */
  void set question(Token token);

  /**
   * Return the expression that is executed if the condition evaluates to
   * `true`.
   */
  Expression get thenExpression;

  /**
   * Set the expression that is executed if the condition evaluates to `true` to
   * the given [expression].
   */
  void set thenExpression(Expression expression);
}

/**
 * A configuration in either an import or export directive.
 *
 *    configuration ::=
 *        'if' '(' test ')' uri
 *
 *    test ::=
 *        dottedName ('==' stringLiteral)?
 *
 *    dottedName ::=
 *        identifier ('.' identifier)*
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class Configuration extends AstNode {
  /**
   * Initialize a newly created configuration.
   */
  factory Configuration(
          Token ifKeyword,
          Token leftParenthesis,
          DottedName name,
          Token equalToken,
          StringLiteral value,
          Token rightParenthesis,
          StringLiteral libraryUri) =>
      new ConfigurationImpl(ifKeyword, leftParenthesis, name, equalToken, value,
          rightParenthesis, libraryUri);

  /**
   * Return the token for the equal operator, or `null` if the condition does
   * not include an equality test.
   */
  Token get equalToken;

  /**
   * Set the token for the equal operator to the given [token].
   */
  void set equalToken(Token token);

  /**
   * Return the token for the 'if' keyword.
   */
  Token get ifKeyword;

  /**
   * Set the token for the 'if' keyword to the given [token].
   */
  void set ifKeyword(Token token);

  /**
   * Return the token for the left parenthesis.
   */
  Token get leftParenthesis;

  /**
   * Set the token for the left parenthesis to the given [token].
   */
  void set leftParenthesis(Token token);

  /**
   * Return the URI of the implementation library to be used if the condition is
   * true.
   */
  StringLiteral get libraryUri;

  /**
   * Set the URI of the implementation library to be used if the condition is
   * true to the given [uri].
   */
  void set libraryUri(StringLiteral uri);

  /**
   * Return the name of the declared variable whose value is being used in the
   * condition.
   */
  DottedName get name;

  /**
   * Set the name of the declared variable whose value is being used in the
   * condition to the given [name].
   */
  void set name(DottedName name);

  /**
   * Return the token for the right parenthesis.
   */
  Token get rightParenthesis;

  /**
   * Set the token for the right parenthesis to the given [token].
   */
  void set rightParenthesis(Token token);

  /**
   * Return the value to which the value of the declared variable will be
   * compared, or `null` if the condition does not include an equality test.
   */
  StringLiteral get value;

  /**
   * Set the value to which the value of the declared variable will be
   * compared to the given [value].
   */
  void set value(StringLiteral value);
}

/**
 * A constructor declaration.
 *
 *    constructorDeclaration ::=
 *        constructorSignature [FunctionBody]?
 *      | constructorName formalParameterList ':' 'this' ('.' [SimpleIdentifier])? arguments
 *
 *    constructorSignature ::=
 *        'external'? constructorName formalParameterList initializerList?
 *      | 'external'? 'factory' factoryName formalParameterList initializerList?
 *      | 'external'? 'const'  constructorName formalParameterList initializerList?
 *
 *    constructorName ::=
 *        [SimpleIdentifier] ('.' [SimpleIdentifier])?
 *
 *    factoryName ::=
 *        [Identifier] ('.' [SimpleIdentifier])?
 *
 *    initializerList ::=
 *        ':' [ConstructorInitializer] (',' [ConstructorInitializer])*
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ConstructorDeclaration extends ClassMember {
  /**
   * Initialize a newly created constructor declaration. The [externalKeyword]
   * can be `null` if the constructor is not external. Either or both of the
   * [comment] and [metadata] can be `null` if the constructor does not have the
   * corresponding attribute. The [constKeyword] can be `null` if the
   * constructor cannot be used to create a constant. The [factoryKeyword] can
   * be `null` if the constructor is not a factory. The [period] and [name] can
   * both be `null` if the constructor is not a named constructor. The
   * [separator] can be `null` if the constructor does not have any initializers
   * and does not redirect to a different constructor. The list of
   * [initializers] can be `null` if the constructor does not have any
   * initializers. The [redirectedConstructor] can be `null` if the constructor
   * does not redirect to a different constructor. The [body] can be `null` if
   * the constructor does not have a body.
   */
  factory ConstructorDeclaration(
          Comment comment,
          List<Annotation> metadata,
          Token externalKeyword,
          Token constKeyword,
          Token factoryKeyword,
          Identifier returnType,
          Token period,
          SimpleIdentifier name,
          FormalParameterList parameters,
          Token separator,
          List<ConstructorInitializer> initializers,
          ConstructorName redirectedConstructor,
          FunctionBody body) =>
      new ConstructorDeclarationImpl(
          comment,
          metadata,
          externalKeyword,
          constKeyword,
          factoryKeyword,
          returnType,
          period,
          name,
          parameters,
          separator,
          initializers,
          redirectedConstructor,
          body);

  /**
   * Return the body of the constructor, or `null` if the constructor does not
   * have a body.
   */
  FunctionBody get body;

  /**
   * Set the body of the constructor to the given [functionBody].
   */
  void set body(FunctionBody functionBody);

  /**
   * Return the token for the 'const' keyword, or `null` if the constructor is
   * not a const constructor.
   */
  Token get constKeyword;

  /**
   * Set the token for the 'const' keyword to the given [token].
   */
  void set constKeyword(Token token);

  @override
  ConstructorElement get element;

  /**
   * Set the element associated with this constructor to the given [element].
   */
  void set element(ConstructorElement element);

  /**
   * Return the token for the 'external' keyword to the given [token].
   */
  Token get externalKeyword;

  /**
   * Set the token for the 'external' keyword, or `null` if the constructor
   * is not external.
   */
  void set externalKeyword(Token token);

  /**
   * Return the token for the 'factory' keyword, or `null` if the constructor is
   * not a factory constructor.
   */
  Token get factoryKeyword;

  /**
   * Set the token for the 'factory' keyword to the given [token].
   */
  void set factoryKeyword(Token token);

  /**
   * Return the initializers associated with the constructor.
   */
  NodeList<ConstructorInitializer> get initializers;

  /**
   * Return the name of the constructor, or `null` if the constructor being
   * declared is unnamed.
   */
  SimpleIdentifier get name;

  /**
   * Set the name of the constructor to the given [identifier].
   */
  void set name(SimpleIdentifier identifier);

  /**
   * Return the parameters associated with the constructor.
   */
  FormalParameterList get parameters;

  /**
   * Set the parameters associated with the constructor to the given list of
   * [parameters].
   */
  void set parameters(FormalParameterList parameters);

  /**
   * Return the token for the period before the constructor name, or `null` if
   * the constructor being declared is unnamed.
   */
  Token get period;

  /**
   * Set the token for the period before the constructor name to the given
   * [token].
   */
  void set period(Token token);

  /**
   * Return the name of the constructor to which this constructor will be
   * redirected, or `null` if this is not a redirecting factory constructor.
   */
  ConstructorName get redirectedConstructor;

  /**
   * Set the name of the constructor to which this constructor will be
   * redirected to the given [redirectedConstructor] name.
   */
  void set redirectedConstructor(ConstructorName redirectedConstructor);

  /**
   * Return the type of object being created. This can be different than the
   * type in which the constructor is being declared if the constructor is the
   * implementation of a factory constructor.
   */
  Identifier get returnType;

  /**
   * Set the type of object being created to the given [typeName].
   */
  void set returnType(Identifier typeName);

  /**
   * Return the token for the separator (colon or equals) before the initializer
   * list or redirection, or `null` if there are no initializers.
   */
  Token get separator;

  /**
   * Set the token for the separator (colon or equals) before the initializer
   * list or redirection to the given [token].
   */
  void set separator(Token token);
}

/**
 * The initialization of a field within a constructor's initialization list.
 *
 *    fieldInitializer ::=
 *        ('this' '.')? [SimpleIdentifier] '=' [Expression]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ConstructorFieldInitializer extends ConstructorInitializer {
  /**
   * Initialize a newly created field initializer to initialize the field with
   * the given name to the value of the given expression. The [thisKeyword] and
   * [period] can be `null` if the 'this' keyword was not specified.
   */
  factory ConstructorFieldInitializer(Token thisKeyword, Token period,
          SimpleIdentifier fieldName, Token equals, Expression expression) =>
      new ConstructorFieldInitializerImpl(
          thisKeyword, period, fieldName, equals, expression);

  /**
   * Return the token for the equal sign between the field name and the
   * expression.
   */
  Token get equals;

  /**
   * Set the token for the equal sign between the field name and the
   * expression to the given [token].
   */
  void set equals(Token token);

  /**
   * Return the expression computing the value to which the field will be
   * initialized.
   */
  Expression get expression;

  /**
   * Set the expression computing the value to which the field will be
   * initialized to the given [expression].
   */
  void set expression(Expression expression);

  /**
   * Return the name of the field being initialized.
   */
  SimpleIdentifier get fieldName;

  /**
   * Set the name of the field being initialized to the given [identifier].
   */
  void set fieldName(SimpleIdentifier identifier);

  /**
   * Return the token for the period after the 'this' keyword, or `null` if
   * there is no 'this' keyword.
   */
  Token get period;

  /**
   * Set the token for the period after the 'this' keyword to the given [token].
   */
  void set period(Token token);

  /**
   * Return the token for the 'this' keyword, or `null` if there is no 'this'
   * keyword.
   */
  Token get thisKeyword;

  /**
   * Set the token for the 'this' keyword to the given [token].
   */
  void set thisKeyword(Token token);
}

/**
 * A node that can occur in the initializer list of a constructor declaration.
 *
 *    constructorInitializer ::=
 *        [SuperConstructorInvocation]
 *      | [ConstructorFieldInitializer]
 *      | [RedirectingConstructorInvocation]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ConstructorInitializer extends AstNode {}

/**
 * The name of a constructor.
 *
 *    constructorName ::=
 *        type ('.' identifier)?
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ConstructorName extends AstNode {
  /**
   * Initialize a newly created constructor name. The [period] and [name] can be
   * `null` if the constructor being named is the unnamed constructor.
   */
  factory ConstructorName(TypeName type, Token period, SimpleIdentifier name) =>
      new ConstructorNameImpl(type, period, name);

  /**
   * Return the name of the constructor, or `null` if the specified constructor
   * is the unnamed constructor.
   */
  SimpleIdentifier get name;

  /**
   * Set the name of the constructor to the given [name].
   */
  void set name(SimpleIdentifier name);

  /**
   * Return the token for the period before the constructor name, or `null` if
   * the specified constructor is the unnamed constructor.
   */
  Token get period;

  /**
   * Set the token for the period before the constructor name to the given
   * [token].
   */
  void set period(Token token);

  /**
   * Return the element associated with this constructor name based on static
   * type information, or `null` if the AST structure has not been resolved or
   * if this constructor name could not be resolved.
   */
  ConstructorElement get staticElement;

  /**
   * Set the element associated with this constructor name based on static type
   * information to the given [element].
   */
  void set staticElement(ConstructorElement element);

  /**
   * Return the name of the type defining the constructor.
   */
  TypeName get type;

  /**
   * Set the name of the type defining the constructor to the given [type] name.
   */
  void set type(TypeName type);
}

/**
 * A continue statement.
 *
 *    continueStatement ::=
 *        'continue' [SimpleIdentifier]? ';'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ContinueStatement extends Statement {
  /**
   * Initialize a newly created continue statement. The [label] can be `null` if
   * there is no label associated with the statement.
   */
  factory ContinueStatement(
          Token continueKeyword, SimpleIdentifier label, Token semicolon) =>
      new ContinueStatementImpl(continueKeyword, label, semicolon);

  /**
   * Return the token representing the 'continue' keyword.
   */
  Token get continueKeyword;

  /**
   * Set the token representing the 'continue' keyword to the given [token].
   */
  void set continueKeyword(Token token);

  /**
   * Return the label associated with the statement, or `null` if there is no
   * label.
   */
  SimpleIdentifier get label;

  /**
   * Set the label associated with the statement to the given [identifier].
   */
  void set label(SimpleIdentifier identifier);

  /**
   * Return the semicolon terminating the statement.
   */
  Token get semicolon;

  /**
   * Set the semicolon terminating the statement to the given [token].
   */
  void set semicolon(Token token);

  /**
   * Return the node to which this continue statement is continuing. This will
   * be either a [Statement] (in the case of continuing a loop), a
   * [SwitchMember] (in the case of continuing from one switch case to another),
   * or `null` if the AST has not yet been resolved or if the target could not
   * be resolved. Note that if the source code has errors, the target might be
   * invalid (e.g. the target may be in an enclosing function).
   */
  AstNode get target;

  /**
   * Set the node to which this continue statement is continuing to the given
   * [node].
   */
  void set target(AstNode node);
}

/**
 * A node that represents the declaration of one or more names. Each declared
 * name is visible within a name scope.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class Declaration extends AnnotatedNode {
  /**
   * Return the element associated with this declaration, or `null` if either
   * this node corresponds to a list of declarations or if the AST structure has
   * not been resolved.
   */
  Element get element;
}

/**
 * The declaration of a single identifier.
 *
 *    declaredIdentifier ::=
 *        [Annotation] finalConstVarOrType [SimpleIdentifier]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DeclaredIdentifier extends Declaration {
  /**
   * Initialize a newly created formal parameter. Either or both of the
   * [comment] and [metadata] can be `null` if the declaration does not have the
   * corresponding attribute. The [keyword] can be `null` if a type name is
   * given. The [type] must be `null` if the keyword is 'var'.
   */
  factory DeclaredIdentifier(Comment comment, List<Annotation> metadata,
          Token keyword, TypeName type, SimpleIdentifier identifier) =>
      new DeclaredIdentifierImpl(comment, metadata, keyword, type, identifier);

  @override
  LocalVariableElement get element;

  /**
   * Return the name of the variable being declared.
   */
  SimpleIdentifier get identifier;

  /**
   * Set the name of the variable being declared to the given [identifier].
   */
  void set identifier(SimpleIdentifier identifier);

  /**
   * Return `true` if this variable was declared with the 'const' modifier.
   */
  bool get isConst;

  /**
   * Return `true` if this variable was declared with the 'final' modifier.
   * Variables that are declared with the 'const' modifier will return `false`
   * even though they are implicitly final.
   */
  bool get isFinal;

  /**
   * Return the token representing either the 'final', 'const' or 'var' keyword,
   * or `null` if no keyword was used.
   */
  Token get keyword;

  /**
   * Set the token representing either the 'final', 'const' or 'var' keyword to
   * the given [token].
   */
  void set keyword(Token token);

  /**
   * Return the name of the declared type of the parameter, or `null` if the
   * parameter does not have a declared type.
   */
  TypeName get type;

  /**
   * Set the name of the declared type of the parameter to the given [typeName].
   */
  void set type(TypeName typeName);
}

/**
 * A formal parameter with a default value. There are two kinds of parameters
 * that are both represented by this class: named formal parameters and
 * positional formal parameters.
 *
 *    defaultFormalParameter ::=
 *        [NormalFormalParameter] ('=' [Expression])?
 *
 *    defaultNamedParameter ::=
 *        [NormalFormalParameter] (':' [Expression])?
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DefaultFormalParameter extends FormalParameter {
  /**
   * Initialize a newly created default formal parameter. The [separator] and
   * [defaultValue] can be `null` if there is no default value.
   */
  factory DefaultFormalParameter(NormalFormalParameter parameter,
          ParameterKind kind, Token separator, Expression defaultValue) =>
      new DefaultFormalParameterImpl(parameter, kind, separator, defaultValue);

  /**
   * Return the expression computing the default value for the parameter, or
   * `null` if there is no default value.
   */
  Expression get defaultValue;

  /**
   * Set the expression computing the default value for the parameter to the
   * given [expression].
   */
  void set defaultValue(Expression expression);

  /**
   * Set the kind of this parameter to the given [kind].
   */
  void set kind(ParameterKind kind);

  /**
   * Return the formal parameter with which the default value is associated.
   */
  NormalFormalParameter get parameter;

  /**
   * Set the formal parameter with which the default value is associated to the
   * given [formalParameter].
   */
  void set parameter(NormalFormalParameter formalParameter);

  /**
   * Return the token separating the parameter from the default value, or `null`
   * if there is no default value.
   */
  Token get separator;

  /**
   * Set the token separating the parameter from the default value to the given
   * [token].
   */
  void set separator(Token token);
}

/**
 * A node that represents a directive.
 *
 *    directive ::=
 *        [ExportDirective]
 *      | [ImportDirective]
 *      | [LibraryDirective]
 *      | [PartDirective]
 *      | [PartOfDirective]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class Directive extends AnnotatedNode {
  /**
   * Return the element associated with this directive, or `null` if the AST
   * structure has not been resolved or if this directive could not be resolved.
   */
  Element get element;

  /**
   * Set the element associated with this directive to the given [element].
   */
  void set element(Element element);

  /**
   * Return the token representing the keyword that introduces this directive
   * ('import', 'export', 'library' or 'part').
   */
  Token get keyword;
}

/**
 * A do statement.
 *
 *    doStatement ::=
 *        'do' [Statement] 'while' '(' [Expression] ')' ';'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DoStatement extends Statement {
  /**
   * Initialize a newly created do loop.
   */
  factory DoStatement(
          Token doKeyword,
          Statement body,
          Token whileKeyword,
          Token leftParenthesis,
          Expression condition,
          Token rightParenthesis,
          Token semicolon) =>
      new DoStatementImpl(doKeyword, body, whileKeyword, leftParenthesis,
          condition, rightParenthesis, semicolon);

  /**
   * Return the body of the loop.
   */
  Statement get body;

  /**
   * Set the body of the loop to the given [statement].
   */
  void set body(Statement statement);

  /**
   * Return the condition that determines when the loop will terminate.
   */
  Expression get condition;

  /**
   * Set the condition that determines when the loop will terminate to the given
   * [expression].
   */
  void set condition(Expression expression);

  /**
   * Return the token representing the 'do' keyword.
   */
  Token get doKeyword;

  /**
   * Set the token representing the 'do' keyword to the given [token].
   */
  void set doKeyword(Token token);

  /**
   * Return the left parenthesis.
   */
  Token get leftParenthesis;

  /**
   * Set the left parenthesis to the given [token].
   */
  void set leftParenthesis(Token token);

  /**
   * Return the right parenthesis.
   */
  Token get rightParenthesis;

  /**
   * Set the right parenthesis to the given [token].
   */
  void set rightParenthesis(Token token);

  /**
   * Return the semicolon terminating the statement.
   */
  Token get semicolon;

  /**
   * Set the semicolon terminating the statement to the given [token].
   */
  void set semicolon(Token token);

  /**
   * Return the token representing the 'while' keyword.
   */
  Token get whileKeyword;

  /**
   * Set the token representing the 'while' keyword to the given [token].
   */
  void set whileKeyword(Token token);
}

/**
 * A dotted name, used in a configuration within an import or export directive.
 *
 *    dottedName ::=
 *        [SimpleIdentifier] ('.' [SimpleIdentifier])*
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DottedName extends AstNode {
  /**
   * Initialize a newly created dotted name.
   */
  factory DottedName(List<SimpleIdentifier> components) = DottedNameImpl;

  /**
   * Return the components of the identifier.
   */
  NodeList<SimpleIdentifier> get components;
}

/**
 * A floating point literal expression.
 *
 *    doubleLiteral ::=
 *        decimalDigit+ ('.' decimalDigit*)? exponent?
 *      | '.' decimalDigit+ exponent?
 *
 *    exponent ::=
 *        ('e' | 'E') ('+' | '-')? decimalDigit+
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class DoubleLiteral extends Literal {
  /**
   * Initialize a newly created floating point literal.
   */
  factory DoubleLiteral(Token literal, double value) = DoubleLiteralImpl;

  /**
   * Return the token representing the literal.
   */
  Token get literal;

  /**
   * Set the token representing the literal to the given [token].
   */
  void set literal(Token token);

  /**
   * Return the value of the literal.
   */
  double get value;

  /**
   * Set the value of the literal to the given [value].
   */
  void set value(double value);
}

/**
 * An empty function body, which can only appear in constructors or abstract
 * methods.
 *
 *    emptyFunctionBody ::=
 *        ';'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class EmptyFunctionBody extends FunctionBody {
  /**
   * Initialize a newly created function body.
   */
  factory EmptyFunctionBody(Token semicolon) = EmptyFunctionBodyImpl;

  /**
   * Return the token representing the semicolon that marks the end of the
   * function body.
   */
  Token get semicolon;

  /**
   * Set the token representing the semicolon that marks the end of the
   * function body to the given [token].
   */
  void set semicolon(Token token);
}

/**
 * An empty statement.
 *
 *    emptyStatement ::=
 *        ';'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class EmptyStatement extends Statement {
  /**
   * Initialize a newly created empty statement.
   */
  factory EmptyStatement(Token semicolon) = EmptyStatementImpl;

  /**
   * Return the semicolon terminating the statement.
   */
  Token get semicolon;

  /**
   * Set the semicolon terminating the statement to the given [token].
   */
  void set semicolon(Token token);
}

/**
 * The declaration of an enum constant.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class EnumConstantDeclaration extends Declaration {
  /**
   * Initialize a newly created enum constant declaration. Either or both of the
   * [comment] and [metadata] can be `null` if the constant does not have the
   * corresponding attribute. (Technically, enum constants cannot have metadata,
   * but we allow it for consistency.)
   */
  factory EnumConstantDeclaration(
          Comment comment, List<Annotation> metadata, SimpleIdentifier name) =>
      new EnumConstantDeclarationImpl(comment, metadata, name);

  /**
   * Return the name of the constant.
   */
  SimpleIdentifier get name;

  /**
   * Set the name of the constant to the given [name].
   */
  void set name(SimpleIdentifier name);
}

/**
 * The declaration of an enumeration.
 *
 *    enumType ::=
 *        metadata 'enum' [SimpleIdentifier] '{' [SimpleIdentifier] (',' [SimpleIdentifier])* (',')? '}'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class EnumDeclaration extends NamedCompilationUnitMember {
  /**
   * Initialize a newly created enumeration declaration. Either or both of the
   * [comment] and [metadata] can be `null` if the declaration does not have the
   * corresponding attribute. The list of [constants] must contain at least one
   * value.
   */
  factory EnumDeclaration(
          Comment comment,
          List<Annotation> metadata,
          Token enumKeyword,
          SimpleIdentifier name,
          Token leftBracket,
          List<EnumConstantDeclaration> constants,
          Token rightBracket) =>
      new EnumDeclarationImpl(comment, metadata, enumKeyword, name, leftBracket,
          constants, rightBracket);

  /**
   * Return the enumeration constants being declared.
   */
  NodeList<EnumConstantDeclaration> get constants;

  @override
  ClassElement get element;

  /**
   * Return the 'enum' keyword.
   */
  Token get enumKeyword;

  /**
   * Set the 'enum' keyword to the given [token].
   */
  void set enumKeyword(Token token);

  /**
   * Return the left curly bracket.
   */
  Token get leftBracket;

  /**
   * Set the left curly bracket to the given [token].
   */
  void set leftBracket(Token token);

  /**
   * Return the right curly bracket.
   */
  Token get rightBracket;

  /**
   * Set the right curly bracket to the given [token].
   */
  void set rightBracket(Token token);
}

/**
 * An export directive.
 *
 *    exportDirective ::=
 *        [Annotation] 'export' [StringLiteral] [Combinator]* ';'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ExportDirective extends NamespaceDirective {
  /**
   * Initialize a newly created export directive. Either or both of the
   * [comment] and [metadata] can be `null` if the directive does not have the
   * corresponding attribute. The list of [combinators] can be `null` if there
   * are no combinators.
   */
  factory ExportDirective(
          Comment comment,
          List<Annotation> metadata,
          Token keyword,
          StringLiteral libraryUri,
          List<Configuration> configurations,
          List<Combinator> combinators,
          Token semicolon) =>
      new ExportDirectiveImpl(comment, metadata, keyword, libraryUri,
          configurations, combinators, semicolon);
}

/**
 * A node that represents an expression.
 *
 *    expression ::=
 *        [AssignmentExpression]
 *      | [ConditionalExpression] cascadeSection*
 *      | [ThrowExpression]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class Expression extends AstNode {
  /**
   * An empty list of expressions.
   */
  static const List<Expression> EMPTY_LIST = const <Expression>[];

  /**
   * Return the best parameter element information available for this
   * expression. If type propagation was able to find a better parameter element
   * than static analysis, that type will be returned. Otherwise, the result of
   * static analysis will be returned.
   */
  ParameterElement get bestParameterElement;

  /**
   * Return the best type information available for this expression. If type
   * propagation was able to find a better type than static analysis, that type
   * will be returned. Otherwise, the result of static analysis will be
   * returned. If no type analysis has been performed, then the type 'dynamic'
   * will be returned.
   */
  DartType get bestType;

  /**
   * Return `true` if this expression is syntactically valid for the LHS of an
   * [AssignmentExpression].
   */
  bool get isAssignable;

  /**
   * Return the precedence of this expression. The precedence is a positive
   * integer value that defines how the source code is parsed into an AST. For
   * example `a * b + c` is parsed as `(a * b) + c` because the precedence of
   * `*` is greater than the precedence of `+`.
   *
   * Clients should not assume that returned values will stay the same, they
   * might change as result of specification change. Only relative order should
   * be used.
   */
  int get precedence;

  /**
   * If this expression is an argument to an invocation, and the AST structure
   * has been resolved, and the function being invoked is known based on
   * propagated type information, and this expression corresponds to one of the
   * parameters of the function being invoked, then return the parameter element
   * representing the parameter to which the value of this expression will be
   * bound. Otherwise, return `null`.
   */
  ParameterElement get propagatedParameterElement;

  /**
   * Return the propagated type of this expression, or `null` if type
   * propagation has not been performed on the AST structure.
   */
  DartType get propagatedType;

  /**
   * Set the propagated type of this expression to the given [type].
   */
  void set propagatedType(DartType type);

  /**
   * If this expression is an argument to an invocation, and the AST structure
   * has been resolved, and the function being invoked is known based on static
   * type information, and this expression corresponds to one of the parameters
   * of the function being invoked, then return the parameter element
   * representing the parameter to which the value of this expression will be
   * bound. Otherwise, return `null`.
   */
  ParameterElement get staticParameterElement;

  /**
   * Return the static type of this expression, or `null` if the AST structure
   * has not been resolved.
   */
  DartType get staticType;

  /**
   * Set the static type of this expression to the given [type].
   */
  void set staticType(DartType type);

  /**
   * If this expression is a parenthesized expression, return the result of
   * unwrapping the expression inside the parentheses. Otherwise, return this
   * expression.
   */
  Expression get unParenthesized;
}

/**
 * A function body consisting of a single expression.
 *
 *    expressionFunctionBody ::=
 *        'async'? '=>' [Expression] ';'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ExpressionFunctionBody extends FunctionBody {
  /**
   * Initialize a newly created function body consisting of a block of
   * statements. The [keyword] can be `null` if the function body is not an
   * async function body.
   */
  factory ExpressionFunctionBody(Token keyword, Token functionDefinition,
          Expression expression, Token semicolon) =>
      new ExpressionFunctionBodyImpl(
          keyword, functionDefinition, expression, semicolon);

  /**
   * Return the expression representing the body of the function.
   */
  Expression get expression;

  /**
   * Set the expression representing the body of the function to the given
   * [expression].
   */
  void set expression(Expression expression);

  /**
   * Return the token introducing the expression that represents the body of the
   * function.
   */
  Token get functionDefinition;

  /**
   * Set the token introducing the expression that represents the body of the
   * function to the given [token].
   */
  void set functionDefinition(Token token);

  /**
   * Set token representing the 'async' or 'sync' keyword to the given [token].
   */
  void set keyword(Token token);

  /**
   * Return the semicolon terminating the statement.
   */
  Token get semicolon;

  /**
   * Set the semicolon terminating the statement to the given [token].
   */
  void set semicolon(Token token);
}

/**
 * An expression used as a statement.
 *
 *    expressionStatement ::=
 *        [Expression]? ';'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ExpressionStatement extends Statement {
  /**
   * Initialize a newly created expression statement.
   */
  factory ExpressionStatement(Expression expression, Token semicolon) =>
      new ExpressionStatementImpl(expression, semicolon);

  /**
   * Return the expression that comprises the statement.
   */
  Expression get expression;

  /**
   * Set the expression that comprises the statement to the given [expression].
   */
  void set expression(Expression expression);

  /**
   * Return the semicolon terminating the statement, or `null` if the expression is a
   * function expression and therefore isn't followed by a semicolon.
   */
  Token get semicolon;

  /**
   * Set the semicolon terminating the statement to the given [token].
   */
  void set semicolon(Token token);
}

/**
 * The "extends" clause in a class declaration.
 *
 *    extendsClause ::=
 *        'extends' [TypeName]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ExtendsClause extends AstNode {
  /**
   * Initialize a newly created extends clause.
   */
  factory ExtendsClause(Token extendsKeyword, TypeName superclass) =>
      new ExtendsClauseImpl(extendsKeyword, superclass);

  /**
   * Return the token representing the 'extends' keyword.
   */
  Token get extendsKeyword;

  /**
   * Set the token representing the 'extends' keyword to the given [token].
   */
  void set extendsKeyword(Token token);

  /**
   * Return the name of the class that is being extended.
   */
  TypeName get superclass;

  /**
   * Set the name of the class that is being extended to the given [name].
   */
  void set superclass(TypeName name);
}

/**
 * The declaration of one or more fields of the same type.
 *
 *    fieldDeclaration ::=
 *        'static'? [VariableDeclarationList] ';'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FieldDeclaration extends ClassMember {
  /**
   * Initialize a newly created field declaration. Either or both of the
   * [comment] and [metadata] can be `null` if the declaration does not have the
   * corresponding attribute. The [staticKeyword] can be `null` if the field is
   * not a static field.
   */
  factory FieldDeclaration(
          Comment comment,
          List<Annotation> metadata,
          Token staticKeyword,
          VariableDeclarationList fieldList,
          Token semicolon) =>
      new FieldDeclarationImpl(
          comment, metadata, staticKeyword, fieldList, semicolon);

  /**
   * Return the fields being declared.
   */
  VariableDeclarationList get fields;

  /**
   * Set the fields being declared to the given list of [fields].
   */
  void set fields(VariableDeclarationList fields);

  /**
   * Return `true` if the fields are declared to be static.
   */
  bool get isStatic;

  /**
   * Return the semicolon terminating the declaration.
   */
  Token get semicolon;

  /**
   * Set the semicolon terminating the declaration to the given [token].
   */
  void set semicolon(Token token);

  /**
   * Return the token representing the 'static' keyword, or `null` if the fields
   * are not static.
   */
  Token get staticKeyword;

  /**
   * Set the token representing the 'static' keyword to the given [token].
   */
  void set staticKeyword(Token token);
}

/**
 * A field formal parameter.
 *
 *    fieldFormalParameter ::=
 *        ('final' [TypeName] | 'const' [TypeName] | 'var' | [TypeName])?
 *        'this' '.' [SimpleIdentifier] ([TypeParameterList]? [FormalParameterList])?
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FieldFormalParameter extends NormalFormalParameter {
  /**
   * Initialize a newly created formal parameter. Either or both of the
   * [comment] and [metadata] can be `null` if the parameter does not have the
   * corresponding attribute. The [keyword] can be `null` if there is a type.
   * The [type] must be `null` if the keyword is 'var'. The [thisKeyword] and
   * [period] can be `null` if the keyword 'this' was not provided.  The
   * [parameters] can be `null` if this is not a function-typed field formal
   * parameter.
   */
  factory FieldFormalParameter(
          Comment comment,
          List<Annotation> metadata,
          Token keyword,
          TypeName type,
          Token thisKeyword,
          Token period,
          SimpleIdentifier identifier,
          TypeParameterList typeParameters,
          FormalParameterList parameters) =>
      new FieldFormalParameterImpl(comment, metadata, keyword, type,
          thisKeyword, period, identifier, typeParameters, parameters);

  /**
   * Return the token representing either the 'final', 'const' or 'var' keyword,
   * or `null` if no keyword was used.
   */
  Token get keyword;

  /**
   * Set the token representing either the 'final', 'const' or 'var' keyword to
   * the given [token].
   */
  void set keyword(Token token);

  /**
   * Return the parameters of the function-typed parameter, or `null` if this is
   * not a function-typed field formal parameter.
   */
  FormalParameterList get parameters;

  /**
   * Set the parameters of the function-typed parameter to the given
   * [parameters].
   */
  void set parameters(FormalParameterList parameters);

  /**
   * Return the token representing the period.
   */
  Token get period;

  /**
   * Set the token representing the period to the given [token].
   */
  void set period(Token token);

  /**
   * Return the token representing the 'this' keyword.
   */
  Token get thisKeyword;

  /**
   * Set the token representing the 'this' keyword to the given [token].
   */
  void set thisKeyword(Token token);

  /**
   * Return the name of the declared type of the parameter, or `null` if the
   * parameter does not have a declared type. Note that if this is a
   * function-typed field formal parameter this is the return type of the
   * function.
   */
  TypeName get type;

  /**
   * Set the name of the declared type of the parameter to the given [typeName].
   */
  void set type(TypeName typeName);

  /**
   * Return the type parameters associated with this method, or `null` if this
   * method is not a generic method.
   */
  TypeParameterList get typeParameters;

  /**
   * Set the type parameters associated with this method to the given
   * [typeParameters].
   */
  void set typeParameters(TypeParameterList typeParameters);
}

/**
 * A for-each statement.
 *
 *    forEachStatement ::=
 *        'await'? 'for' '(' [DeclaredIdentifier] 'in' [Expression] ')' [Block]
 *      | 'await'? 'for' '(' [SimpleIdentifier] 'in' [Expression] ')' [Block]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ForEachStatement extends Statement {
  /**
   * Initialize a newly created for-each statement whose loop control variable
   * is declared internally (in the for-loop part). The [awaitKeyword] can be
   * `null` if this is not an asynchronous for loop.
   */
  factory ForEachStatement.withDeclaration(
          Token awaitKeyword,
          Token forKeyword,
          Token leftParenthesis,
          DeclaredIdentifier loopVariable,
          Token inKeyword,
          Expression iterator,
          Token rightParenthesis,
          Statement body) =>
      new ForEachStatementImpl.withDeclaration(
          awaitKeyword,
          forKeyword,
          leftParenthesis,
          loopVariable,
          inKeyword,
          iterator,
          rightParenthesis,
          body);

  /**
   * Initialize a newly created for-each statement whose loop control variable
   * is declared outside the for loop. The [awaitKeyword] can be `null` if this
   * is not an asynchronous for loop.
   */
  factory ForEachStatement.withReference(
          Token awaitKeyword,
          Token forKeyword,
          Token leftParenthesis,
          SimpleIdentifier identifier,
          Token inKeyword,
          Expression iterator,
          Token rightParenthesis,
          Statement body) =>
      new ForEachStatementImpl.withReference(
          awaitKeyword,
          forKeyword,
          leftParenthesis,
          identifier,
          inKeyword,
          iterator,
          rightParenthesis,
          body);

  /**
   * Return the token representing the 'await' keyword, or `null` if there is no
   * 'await' keyword.
   */
  Token get awaitKeyword;

  /**
   * Set the token representing the 'await' keyword to the given [token].
   */
  void set awaitKeyword(Token token);

  /**
   * Return the body of the loop.
   */
  Statement get body;

  /**
   * Set the body of the loop to the given [statement].
   */
  void set body(Statement statement);

  /**
   * Return the token representing the 'for' keyword.
   */
  Token get forKeyword;

  /**
   * Set the token representing the 'for' keyword to the given [token].
   */
  void set forKeyword(Token token);

  /**
   * Return the loop variable, or `null` if the loop variable is declared in the
   * 'for'.
   */
  SimpleIdentifier get identifier;

  /**
   * Set the loop variable to the given [identifier].
   */
  void set identifier(SimpleIdentifier identifier);

  /**
   * Return the token representing the 'in' keyword.
   */
  Token get inKeyword;

  /**
   * Set the token representing the 'in' keyword to the given [token].
   */
  void set inKeyword(Token token);

  /**
   * Return the expression evaluated to produce the iterator.
   */
  Expression get iterable;

  /**
   * Set the expression evaluated to produce the iterator to the given
   * [expression].
   */
  void set iterable(Expression expression);

  /**
   * Return the left parenthesis.
   */
  Token get leftParenthesis;

  /**
   * Set the left parenthesis to the given [token].
   */
  void set leftParenthesis(Token token);

  /**
   * Return the declaration of the loop variable, or `null` if the loop variable
   * is a simple identifier.
   */
  DeclaredIdentifier get loopVariable;

  /**
   * Set the declaration of the loop variable to the given [variable].
   */
  void set loopVariable(DeclaredIdentifier variable);

  /**
   * Return the right parenthesis.
   */
  Token get rightParenthesis;

  /**
   * Set the right parenthesis to the given [token].
   */
  void set rightParenthesis(Token token);
}

/**
 * A node representing a parameter to a function.
 *
 *    formalParameter ::=
 *        [NormalFormalParameter]
 *      | [DefaultFormalParameter]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FormalParameter extends AstNode {
  /**
   * Return the element representing this parameter, or `null` if this parameter
   * has not been resolved.
   */
  ParameterElement get element;

  /**
   * Return the name of the parameter being declared.
   */
  SimpleIdentifier get identifier;

  /**
   * Return `true` if this parameter was declared with the 'const' modifier.
   */
  bool get isConst;

  /**
   * Return `true` if this parameter was declared with the 'final' modifier.
   * Parameters that are declared with the 'const' modifier will return `false`
   * even though they are implicitly final.
   */
  bool get isFinal;

  /**
   * Return the kind of this parameter.
   */
  ParameterKind get kind;

  /**
   * Return the annotations associated with this parameter.
   */
  NodeList<Annotation> get metadata;
}

/**
 * The formal parameter list of a method declaration, function declaration, or
 * function type alias.
 *
 * While the grammar requires all optional formal parameters to follow all of
 * the normal formal parameters and at most one grouping of optional formal
 * parameters, this class does not enforce those constraints. All parameters are
 * flattened into a single list, which can have any or all kinds of parameters
 * (normal, named, and positional) in any order.
 *
 *    formalParameterList ::=
 *        '(' ')'
 *      | '(' normalFormalParameters (',' optionalFormalParameters)? ')'
 *      | '(' optionalFormalParameters ')'
 *
 *    normalFormalParameters ::=
 *        [NormalFormalParameter] (',' [NormalFormalParameter])*
 *
 *    optionalFormalParameters ::=
 *        optionalPositionalFormalParameters
 *      | namedFormalParameters
 *
 *    optionalPositionalFormalParameters ::=
 *        '[' [DefaultFormalParameter] (',' [DefaultFormalParameter])* ']'
 *
 *    namedFormalParameters ::=
 *        '{' [DefaultFormalParameter] (',' [DefaultFormalParameter])* '}'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FormalParameterList extends AstNode {
  /**
   * Initialize a newly created parameter list. The list of [parameters] can be
   * `null` if there are no parameters. The [leftDelimiter] and [rightDelimiter]
   * can be `null` if there are no optional parameters.
   */
  factory FormalParameterList(
      Token leftParenthesis,
      List<FormalParameter> parameters,
      Token leftDelimiter,
      Token rightDelimiter,
      Token rightParenthesis) = FormalParameterListImpl;

  /**
   * Return the left square bracket ('[') or left curly brace ('{') introducing
   * the optional parameters, or `null` if there are no optional parameters.
   */
  Token get leftDelimiter;

  /**
   * Set the left square bracket ('[') or left curly brace ('{') introducing
   * the optional parameters to the given [token].
   */
  void set leftDelimiter(Token token);

  /**
   * Return the left parenthesis.
   */
  Token get leftParenthesis;

  /**
   * Set the left parenthesis to the given [token].
   */
  void set leftParenthesis(Token token);

  /**
   * Return a list containing the elements representing the parameters in this
   * list. The list will contain `null`s if the parameters in this list have not
   * been resolved.
   */
  List<ParameterElement> get parameterElements;

  /**
   * Return the parameters associated with the method.
   */
  NodeList<FormalParameter> get parameters;

  /**
   * Return the right square bracket (']') or right curly brace ('}') terminating the
   * optional parameters, or `null` if there are no optional parameters.
   */
  Token get rightDelimiter;

  /**
   * Set the right square bracket (']') or right curly brace ('}') terminating the
   * optional parameters to the given [token].
   */
  void set rightDelimiter(Token token);

  /**
   * Return the right parenthesis.
   */
  Token get rightParenthesis;

  /**
   * Set the right parenthesis to the given [token].
   */
  void set rightParenthesis(Token token);
}

/**
 * A for statement.
 *
 *    forStatement ::=
 *        'for' '(' forLoopParts ')' [Statement]
 *
 *    forLoopParts ::=
 *        forInitializerStatement ';' [Expression]? ';' [Expression]?
 *
 *    forInitializerStatement ::=
 *        [DefaultFormalParameter]
 *      | [Expression]?
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ForStatement extends Statement {
  /**
   * Initialize a newly created for statement. Either the [variableList] or the
   * [initialization] must be `null`. Either the [condition] and the list of
   * [updaters] can be `null` if the loop does not have the corresponding
   * attribute.
   */
  factory ForStatement(
          Token forKeyword,
          Token leftParenthesis,
          VariableDeclarationList variableList,
          Expression initialization,
          Token leftSeparator,
          Expression condition,
          Token rightSeparator,
          List<Expression> updaters,
          Token rightParenthesis,
          Statement body) =>
      new ForStatementImpl(
          forKeyword,
          leftParenthesis,
          variableList,
          initialization,
          leftSeparator,
          condition,
          rightSeparator,
          updaters,
          rightParenthesis,
          body);

  /**
   * Return the body of the loop.
   */
  Statement get body;

  /**
   * Set the body of the loop to the given [statement].
   */
  void set body(Statement statement);

  /**
   * Return the condition used to determine when to terminate the loop, or
   * `null` if there is no condition.
   */
  Expression get condition;

  /**
   * Set the condition used to determine when to terminate the loop to the given
   * [expression].
   */
  void set condition(Expression expression);

  /**
   * Return the token representing the 'for' keyword.
   */
  Token get forKeyword;

  /**
   * Set the token representing the 'for' keyword to the given [token].
   */
  void set forKeyword(Token token);

  /**
   * Return the initialization expression, or `null` if there is no
   * initialization expression.
   */
  Expression get initialization;

  /**
   * Set the initialization expression to the given [expression].
   */
  void set initialization(Expression initialization);

  /**
   * Return the left parenthesis.
   */
  Token get leftParenthesis;

  /**
   * Set the left parenthesis to the given [token].
   */
  void set leftParenthesis(Token token);

  /**
   * Return the semicolon separating the initializer and the condition.
   */
  Token get leftSeparator;

  /**
   * Set the semicolon separating the initializer and the condition to the given
   * [token].
   */
  void set leftSeparator(Token token);

  /**
   * Return the right parenthesis.
   */
  Token get rightParenthesis;

  /**
   * Set the right parenthesis to the given [token].
   */
  void set rightParenthesis(Token token);

  /**
   * Return the semicolon separating the condition and the updater.
   */
  Token get rightSeparator;

  /**
   * Set the semicolon separating the condition and the updater to the given
   * [token].
   */
  void set rightSeparator(Token token);

  /**
   * Return the list of expressions run after each execution of the loop body.
   */
  NodeList<Expression> get updaters;

  /**
   * Return the declaration of the loop variables, or `null` if there are no
   * variables.
   */
  VariableDeclarationList get variables;

  /**
   * Set the declaration of the loop variables to the given [variableList].
   */
  void set variables(VariableDeclarationList variableList);
}

/**
 * A node representing the body of a function or method.
 *
 *    functionBody ::=
 *        [BlockFunctionBody]
 *      | [EmptyFunctionBody]
 *      | [ExpressionFunctionBody]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FunctionBody extends AstNode {
  /**
   * Return `true` if this function body is asynchronous.
   */
  bool get isAsynchronous;

  /**
   * Return `true` if this function body is a generator.
   */
  bool get isGenerator;

  /**
   * Return `true` if this function body is synchronous.
   */
  bool get isSynchronous;

  /**
   * Return the token representing the 'async' or 'sync' keyword, or `null` if
   * there is no such keyword.
   */
  Token get keyword;

  /**
   * Return the star following the 'async' or 'sync' keyword, or `null` if there
   * is no star.
   */
  Token get star;

  /**
   * If [variable] is a local variable or parameter declared anywhere within
   * the top level function or method containing this [FunctionBody], return a
   * boolean indicating whether [variable] is potentially mutated within a
   * local function other than the function in which it is declared.
   *
   * If [variable] is not a local variable or parameter declared within the top
   * level function or method containing this [FunctionBody], return `false`.
   *
   * Throws an exception if resolution has not yet been performed.
   */
  bool isPotentiallyMutatedInClosure(VariableElement variable);

  /**
   * If [variable] is a local variable or parameter declared anywhere within
   * the top level function or method containing this [FunctionBody], return a
   * boolean indicating whether [variable] is potentially mutated within the
   * scope of its declaration.
   *
   * If [variable] is not a local variable or parameter declared within the top
   * level function or method containing this [FunctionBody], return `false`.
   *
   * Throws an exception if resolution has not yet been performed.
   */
  bool isPotentiallyMutatedInScope(VariableElement variable);
}

/**
 * A top-level declaration.
 *
 *    functionDeclaration ::=
 *        'external' functionSignature
 *      | functionSignature [FunctionBody]
 *
 *    functionSignature ::=
 *        [Type]? ('get' | 'set')? [SimpleIdentifier] [FormalParameterList]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FunctionDeclaration extends NamedCompilationUnitMember {
  /**
   * Initialize a newly created function declaration. Either or both of the
   * [comment] and [metadata] can be `null` if the function does not have the
   * corresponding attribute. The [externalKeyword] can be `null` if the
   * function is not an external function. The [returnType] can be `null` if no
   * return type was specified. The [propertyKeyword] can be `null` if the
   * function is neither a getter or a setter.
   */
  factory FunctionDeclaration(
          Comment comment,
          List<Annotation> metadata,
          Token externalKeyword,
          TypeName returnType,
          Token propertyKeyword,
          SimpleIdentifier name,
          FunctionExpression functionExpression) =>
      new FunctionDeclarationImpl(comment, metadata, externalKeyword,
          returnType, propertyKeyword, name, functionExpression);

  @override
  ExecutableElement get element;

  /**
   * Return the token representing the 'external' keyword, or `null` if this is
   * not an external function.
   */
  Token get externalKeyword;

  /**
   * Set the token representing the 'external' keyword to the given [token].
   */
  void set externalKeyword(Token token);

  /**
   * Return the function expression being wrapped.
   */
  FunctionExpression get functionExpression;

  /**
   * Set the function expression being wrapped to the given
   * [functionExpression].
   */
  void set functionExpression(FunctionExpression functionExpression);

  /**
   * Return `true` if this function declares a getter.
   */
  bool get isGetter;

  /**
   * Return `true` if this function declares a setter.
   */
  bool get isSetter;

  /**
   * Return the token representing the 'get' or 'set' keyword, or `null` if this
   * is a function declaration rather than a property declaration.
   */
  Token get propertyKeyword;

  /**
   * Set the token representing the 'get' or 'set' keyword to the given [token].
   */
  void set propertyKeyword(Token token);

  /**
   * Return the return type of the function, or `null` if no return type was
   * declared.
   */
  TypeName get returnType;

  /**
   * Set the return type of the function to the given [returnType].
   */
  void set returnType(TypeName returnType);
}

/**
 * A [FunctionDeclaration] used as a statement.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FunctionDeclarationStatement extends Statement {
  /**
   * Initialize a newly created function declaration statement.
   */
  factory FunctionDeclarationStatement(
          FunctionDeclaration functionDeclaration) =
      FunctionDeclarationStatementImpl;

  /**
   * Return the function declaration being wrapped.
   */
  FunctionDeclaration get functionDeclaration;

  /**
   * Set the function declaration being wrapped to the given
   * [functionDeclaration].
   */
  void set functionDeclaration(FunctionDeclaration functionDeclaration);
}

/**
 * A function expression.
 *
 *    functionExpression ::=
 *        [TypeParameterList]? [FormalParameterList] [FunctionBody]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FunctionExpression extends Expression {
  /**
   * Initialize a newly created function declaration.
   */
  factory FunctionExpression(TypeParameterList typeParameters,
          FormalParameterList parameters, FunctionBody body) =>
      new FunctionExpressionImpl(typeParameters, parameters, body);

  /**
   * Return the body of the function, or `null` if this is an external function.
   */
  FunctionBody get body;

  /**
   * Set the body of the function to the given [functionBody].
   */
  void set body(FunctionBody functionBody);

  /**
   * Return the element associated with the function, or `null` if the AST
   * structure has not been resolved.
   */
  ExecutableElement get element;

  /**
   * Set the element associated with the function to the given [element].
   */
  void set element(ExecutableElement element);

  /**
   * Return the parameters associated with the function.
   */
  FormalParameterList get parameters;

  /**
   * Set the parameters associated with the function to the given list of
   * [parameters].
   */
  void set parameters(FormalParameterList parameters);

  /**
   * Return the type parameters associated with this method, or `null` if this
   * method is not a generic method.
   */
  TypeParameterList get typeParameters;

  /**
   * Set the type parameters associated with this method to the given
   * [typeParameters].
   */
  void set typeParameters(TypeParameterList typeParameters);
}

/**
 * The invocation of a function resulting from evaluating an expression.
 * Invocations of methods and other forms of functions are represented by
 * [MethodInvocation] nodes. Invocations of getters and setters are represented
 * by either [PrefixedIdentifier] or [PropertyAccess] nodes.
 *
 *    functionExpressionInvocation ::=
 *        [Expression] [TypeArgumentList]? [ArgumentList]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FunctionExpressionInvocation extends InvocationExpression {
  /**
   * Initialize a newly created function expression invocation.
   */
  factory FunctionExpressionInvocation(Expression function,
          TypeArgumentList typeArguments, ArgumentList argumentList) =>
      new FunctionExpressionInvocationImpl(
          function, typeArguments, argumentList);

  /**
   * Set the list of arguments to the method to the given [argumentList].
   */
  void set argumentList(ArgumentList argumentList);

  /**
   * Return the best element available for the function being invoked. If
   * resolution was able to find a better element based on type propagation,
   * that element will be returned. Otherwise, the element found using the
   * result of static analysis will be returned. If resolution has not been
   * performed, then `null` will be returned.
   */
  ExecutableElement get bestElement;

  /**
   * Return the expression producing the function being invoked.
   */
  @override
  Expression get function;

  /**
   * Set the expression producing the function being invoked to the given
   * [expression].
   */
  void set function(Expression expression);

  /**
   * Return the element associated with the function being invoked based on
   * propagated type information, or `null` if the AST structure has not been
   * resolved or the function could not be resolved.
   */
  ExecutableElement get propagatedElement;

  /**
   * Set the element associated with the function being invoked based on
   * propagated type information to the given [element].
   */
  void set propagatedElement(ExecutableElement element);

  /**
   * Return the function type of the method invocation based on the propagated
   * type information, or `null` if the AST structure has not been resolved, or
   * if the invoke could not be resolved.
   *
   * This will usually be a [FunctionType], but it can also be an
   * [InterfaceType] with a `call` method, `dynamic`, `Function`, or a `@proxy`
   * interface type that implements `Function`.
   */
  @override
  DartType get propagatedInvokeType;

  /**
   * Set the function type of the method invocation based on the propagated type
   * information to the given [type].
   */
  @override
  void set propagatedInvokeType(DartType type);

  /**
   * Return the element associated with the function being invoked based on
   * static type information, or `null` if the AST structure has not been
   * resolved or the function could not be resolved.
   */
  ExecutableElement get staticElement;

  /**
   * Set the element associated with the function being invoked based on static
   * type information to the given [element].
   */
  void set staticElement(ExecutableElement element);

  /**
   * Return the function type of the method invocation based on the static type
   * information, or `null` if the AST structure has not been resolved, or if
   * the invoke could not be resolved.
   *
   * This will usually be a [FunctionType], but it can also be an
   * [InterfaceType] with a `call` method, `dynamic`, `Function`, or a `@proxy`
   * interface type that implements `Function`.
   */
  @override
  DartType get staticInvokeType;

  /**
   * Set the function type of the method invocation based on the static type
   * information to the given [type].
   */
  @override
  void set staticInvokeType(DartType type);

  /**
   * Set the type arguments to be applied to the method being invoked to the
   * given [typeArguments].
   */
  void set typeArguments(TypeArgumentList typeArguments);
}

/**
 * A function type alias.
 *
 *    functionTypeAlias ::=
 *        functionPrefix [TypeParameterList]? [FormalParameterList] ';'
 *
 *    functionPrefix ::=
 *        [TypeName]? [SimpleIdentifier]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FunctionTypeAlias extends TypeAlias {
  /**
   * Initialize a newly created function type alias. Either or both of the
   * [comment] and [metadata] can be `null` if the function does not have the
   * corresponding attribute. The [returnType] can be `null` if no return type
   * was specified. The [typeParameters] can be `null` if the function has no
   * type parameters.
   */
  factory FunctionTypeAlias(
          Comment comment,
          List<Annotation> metadata,
          Token keyword,
          TypeName returnType,
          SimpleIdentifier name,
          TypeParameterList typeParameters,
          FormalParameterList parameters,
          Token semicolon) =>
      new FunctionTypeAliasImpl(comment, metadata, keyword, returnType, name,
          typeParameters, parameters, semicolon);

  /**
   * Return the parameters associated with the function type.
   */
  FormalParameterList get parameters;

  /**
   * Set the parameters associated with the function type to the given list of
   * [parameters].
   */
  void set parameters(FormalParameterList parameters);

  /**
   * Return the name of the return type of the function type being defined, or
   * `null` if no return type was given.
   */
  TypeName get returnType;

  /**
   * Set the name of the return type of the function type being defined to the
   * given [typeName].
   */
  void set returnType(TypeName typeName);

  /**
   * Return the type parameters for the function type, or `null` if the function
   * type does not have any type parameters.
   */
  TypeParameterList get typeParameters;

  /**
   * Set the type parameters for the function type to the given list of
   * [typeParameters].
   */
  void set typeParameters(TypeParameterList typeParameters);
}

/**
 * A function-typed formal parameter.
 *
 *    functionSignature ::=
 *        [TypeName]? [SimpleIdentifier] [TypeParameterList]? [FormalParameterList]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FunctionTypedFormalParameter extends NormalFormalParameter {
  /**
   * Initialize a newly created formal parameter. Either or both of the
   * [comment] and [metadata] can be `null` if the parameter does not have the
   * corresponding attribute. The [returnType] can be `null` if no return type
   * was specified.
   */
  factory FunctionTypedFormalParameter(
          Comment comment,
          List<Annotation> metadata,
          TypeName returnType,
          SimpleIdentifier identifier,
          TypeParameterList typeParameters,
          FormalParameterList parameters) =>
      new FunctionTypedFormalParameterImpl(comment, metadata, returnType,
          identifier, typeParameters, parameters);

  /**
   * Return the parameters of the function-typed parameter.
   */
  FormalParameterList get parameters;

  /**
   * Set the parameters of the function-typed parameter to the given
   * [parameters].
   */
  void set parameters(FormalParameterList parameters);

  /**
   * Return the return type of the function, or `null` if the function does not
   * have a return type.
   */
  TypeName get returnType;

  /**
   * Set the return type of the function to the given [type].
   */
  void set returnType(TypeName type);

  /**
   * Return the type parameters associated with this function, or `null` if
   * this function is not a generic function.
   */
  TypeParameterList get typeParameters;

  /**
   * Set the type parameters associated with this method to the given
   * [typeParameters].
   */
  void set typeParameters(TypeParameterList typeParameters);
}

/**
 * A combinator that restricts the names being imported to those that are not in
 * a given list.
 *
 *    hideCombinator ::=
 *        'hide' [SimpleIdentifier] (',' [SimpleIdentifier])*
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class HideCombinator extends Combinator {
  /**
   * Initialize a newly created import show combinator.
   */
  factory HideCombinator(Token keyword, List<SimpleIdentifier> hiddenNames) =
      HideCombinatorImpl;

  /**
   * Return the list of names from the library that are hidden by this
   * combinator.
   */
  NodeList<SimpleIdentifier> get hiddenNames;
}

/**
 * A node that represents an identifier.
 *
 *    identifier ::=
 *        [SimpleIdentifier]
 *      | [PrefixedIdentifier]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class Identifier extends Expression {
  /**
   * Return the best element available for this operator. If resolution was able
   * to find a better element based on type propagation, that element will be
   * returned. Otherwise, the element found using the result of static analysis
   * will be returned. If resolution has not been performed, then `null` will be
   * returned.
   */
  Element get bestElement;

  /**
   * Return the lexical representation of the identifier.
   */
  String get name;

  /**
   * Return the element associated with this identifier based on propagated type
   * information, or `null` if the AST structure has not been resolved or if
   * this identifier could not be resolved. One example of the latter case is an
   * identifier that is not defined within the scope in which it appears.
   */
  Element get propagatedElement;

  /**
   * Return the element associated with this identifier based on static type
   * information, or `null` if the AST structure has not been resolved or if
   * this identifier could not be resolved. One example of the latter case is an
   * identifier that is not defined within the scope in which it appears
   */
  Element get staticElement;

  /**
   * Return `true` if the given [name] is visible only within the library in
   * which it is declared.
   */
  static bool isPrivateName(String name) =>
      StringUtilities.startsWithChar(name, 0x5F); // '_'
}

/**
 * An if statement.
 *
 *    ifStatement ::=
 *        'if' '(' [Expression] ')' [Statement] ('else' [Statement])?
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class IfStatement extends Statement {
  /**
   * Initialize a newly created if statement. The [elseKeyword] and
   * [elseStatement] can be `null` if there is no else clause.
   */
  factory IfStatement(
          Token ifKeyword,
          Token leftParenthesis,
          Expression condition,
          Token rightParenthesis,
          Statement thenStatement,
          Token elseKeyword,
          Statement elseStatement) =>
      new IfStatementImpl(ifKeyword, leftParenthesis, condition,
          rightParenthesis, thenStatement, elseKeyword, elseStatement);

  /**
   * Return the condition used to determine which of the statements is executed
   * next.
   */
  Expression get condition;

  /**
   * Set the condition used to determine which of the statements is executed
   * next to the given [expression].
   */
  void set condition(Expression expression);

  /**
   * Return the token representing the 'else' keyword, or `null` if there is no
   * else statement.
   */
  Token get elseKeyword;

  /**
   * Set the token representing the 'else' keyword to the given [token].
   */
  void set elseKeyword(Token token);

  /**
   * Return the statement that is executed if the condition evaluates to
   * `false`, or `null` if there is no else statement.
   */
  Statement get elseStatement;

  /**
   * Set the statement that is executed if the condition evaluates to `false`
   * to the given [statement].
   */
  void set elseStatement(Statement statement);

  /**
   * Return the token representing the 'if' keyword.
   */
  Token get ifKeyword;

  /**
   * Set the token representing the 'if' keyword to the given [token].
   */
  void set ifKeyword(Token token);

  /**
   * Return the left parenthesis.
   */
  Token get leftParenthesis;

  /**
   * Set the left parenthesis to the given [token].
   */
  void set leftParenthesis(Token token);

  /**
   * Return the right parenthesis.
   */
  Token get rightParenthesis;

  /**
   * Set the right parenthesis to the given [token].
   */
  void set rightParenthesis(Token token);

  /**
   * Return the statement that is executed if the condition evaluates to `true`.
   */
  Statement get thenStatement;

  /**
   * Set the statement that is executed if the condition evaluates to `true` to
   * the given [statement].
   */
  void set thenStatement(Statement statement);
}

/**
 * The "implements" clause in an class declaration.
 *
 *    implementsClause ::=
 *        'implements' [TypeName] (',' [TypeName])*
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ImplementsClause extends AstNode {
  /**
   * Initialize a newly created implements clause.
   */
  factory ImplementsClause(Token implementsKeyword, List<TypeName> interfaces) =
      ImplementsClauseImpl;

  /**
   * Return the token representing the 'implements' keyword.
   */
  Token get implementsKeyword;

  /**
   * Set the token representing the 'implements' keyword to the given [token].
   */
  void set implementsKeyword(Token token);

  /**
   * Return the list of the interfaces that are being implemented.
   */
  NodeList<TypeName> get interfaces;
}

/**
 * An import directive.
 *
 *    importDirective ::=
 *        [Annotation] 'import' [StringLiteral] ('as' identifier)? [Combinator]* ';'
 *      | [Annotation] 'import' [StringLiteral] 'deferred' 'as' identifier [Combinator]* ';'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ImportDirective extends NamespaceDirective {
  static Comparator<ImportDirective> COMPARATOR =
      (ImportDirective import1, ImportDirective import2) {
    //
    // uri
    //
    StringLiteral uri1 = import1.uri;
    StringLiteral uri2 = import2.uri;
    String uriStr1 = uri1.stringValue;
    String uriStr2 = uri2.stringValue;
    if (uriStr1 != null || uriStr2 != null) {
      if (uriStr1 == null) {
        return -1;
      } else if (uriStr2 == null) {
        return 1;
      } else {
        int compare = uriStr1.compareTo(uriStr2);
        if (compare != 0) {
          return compare;
        }
      }
    }
    //
    // as
    //
    SimpleIdentifier prefix1 = import1.prefix;
    SimpleIdentifier prefix2 = import2.prefix;
    String prefixStr1 = prefix1?.name;
    String prefixStr2 = prefix2?.name;
    if (prefixStr1 != null || prefixStr2 != null) {
      if (prefixStr1 == null) {
        return -1;
      } else if (prefixStr2 == null) {
        return 1;
      } else {
        int compare = prefixStr1.compareTo(prefixStr2);
        if (compare != 0) {
          return compare;
        }
      }
    }
    //
    // hides and shows
    //
    NodeList<Combinator> combinators1 = import1.combinators;
    List<String> allHides1 = new List<String>();
    List<String> allShows1 = new List<String>();
    int length1 = combinators1.length;
    for (int i = 0; i < length1; i++) {
      Combinator combinator = combinators1[i];
      if (combinator is HideCombinator) {
        NodeList<SimpleIdentifier> hides = combinator.hiddenNames;
        int hideLength = hides.length;
        for (int j = 0; j < hideLength; j++) {
          SimpleIdentifier simpleIdentifier = hides[j];
          allHides1.add(simpleIdentifier.name);
        }
      } else {
        NodeList<SimpleIdentifier> shows =
            (combinator as ShowCombinator).shownNames;
        int showLength = shows.length;
        for (int j = 0; j < showLength; j++) {
          SimpleIdentifier simpleIdentifier = shows[j];
          allShows1.add(simpleIdentifier.name);
        }
      }
    }
    NodeList<Combinator> combinators2 = import2.combinators;
    List<String> allHides2 = new List<String>();
    List<String> allShows2 = new List<String>();
    int length2 = combinators2.length;
    for (int i = 0; i < length2; i++) {
      Combinator combinator = combinators2[i];
      if (combinator is HideCombinator) {
        NodeList<SimpleIdentifier> hides = combinator.hiddenNames;
        int hideLength = hides.length;
        for (int j = 0; j < hideLength; j++) {
          SimpleIdentifier simpleIdentifier = hides[j];
          allHides2.add(simpleIdentifier.name);
        }
      } else {
        NodeList<SimpleIdentifier> shows =
            (combinator as ShowCombinator).shownNames;
        int showLength = shows.length;
        for (int j = 0; j < showLength; j++) {
          SimpleIdentifier simpleIdentifier = shows[j];
          allShows2.add(simpleIdentifier.name);
        }
      }
    }
    // test lengths of combinator lists first
    if (allHides1.length != allHides2.length) {
      return allHides1.length - allHides2.length;
    }
    if (allShows1.length != allShows2.length) {
      return allShows1.length - allShows2.length;
    }
    // next ensure that the lists are equivalent
    if (!allHides1.toSet().containsAll(allHides2)) {
      return -1;
    }
    if (!allShows1.toSet().containsAll(allShows2)) {
      return -1;
    }
    return 0;
  };

  /**
   * Initialize a newly created import directive. Either or both of the
   * [comment] and [metadata] can be `null` if the function does not have the
   * corresponding attribute. The [deferredKeyword] can be `null` if the import
   * is not deferred. The [asKeyword] and [prefix] can be `null` if the import
   * does not specify a prefix. The list of [combinators] can be `null` if there
   * are no combinators.
   */
  factory ImportDirective(
          Comment comment,
          List<Annotation> metadata,
          Token keyword,
          StringLiteral libraryUri,
          List<Configuration> configurations,
          Token deferredKeyword,
          Token asKeyword,
          SimpleIdentifier prefix,
          List<Combinator> combinators,
          Token semicolon) =>
      new ImportDirectiveImpl(
          comment,
          metadata,
          keyword,
          libraryUri,
          configurations,
          deferredKeyword,
          asKeyword,
          prefix,
          combinators,
          semicolon);

  /**
   * Return the token representing the 'as' keyword, or `null` if the imported
   * names are not prefixed.
   */
  Token get asKeyword;

  /**
   * Set the token representing the 'as' keyword to the given [token].
   */
  void set asKeyword(Token token);

  /**
   * Return the token representing the 'deferred' keyword, or `null` if the
   * imported URI is not deferred.
   */
  Token get deferredKeyword;

  /**
   * Set the token representing the 'deferred' keyword to the given [token].
   */
  void set deferredKeyword(Token token);

  /**
   * Return the prefix to be used with the imported names, or `null` if the
   * imported names are not prefixed.
   */
  SimpleIdentifier get prefix;

  /**
   * Set the prefix to be used with the imported names to the given [identifier].
   */
  void set prefix(SimpleIdentifier identifier);
}

/**
 * An index expression.
 *
 *    indexExpression ::=
 *        [Expression] '[' [Expression] ']'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class IndexExpression extends Expression {
  /**
   * Initialize a newly created index expression.
   */
  factory IndexExpression.forCascade(Token period, Token leftBracket,
          Expression index, Token rightBracket) =>
      new IndexExpressionImpl.forCascade(
          period, leftBracket, index, rightBracket);

  /**
   * Initialize a newly created index expression.
   */
  factory IndexExpression.forTarget(Expression target, Token leftBracket,
          Expression index, Token rightBracket) =>
      new IndexExpressionImpl.forTarget(
          target, leftBracket, index, rightBracket);

  /**
   * Return the auxiliary elements associated with this identifier, or `null` if
   * this identifier is not in both a getter and setter context. The auxiliary
   * elements hold the static and propagated elements associated with the getter
   * context.
   */
  // TODO(brianwilkerson) Replace this API.
  AuxiliaryElements get auxiliaryElements;

  /**
   * Set the auxiliary elements associated with this identifier to the given
   * [elements].
   */
  // TODO(brianwilkerson) Replace this API.
  void set auxiliaryElements(AuxiliaryElements elements);

  /**
   * Return the best element available for this operator. If resolution was able
   * to find a better element based on type propagation, that element will be
   * returned. Otherwise, the element found using the result of static analysis
   * will be returned. If resolution has not been performed, then `null` will be
   * returned.
   */
  MethodElement get bestElement;

  /**
   * Return the expression used to compute the index.
   */
  Expression get index;

  /**
   * Set the expression used to compute the index to the given [expression].
   */
  void set index(Expression expression);

  /**
   * Return `true` if this expression is cascaded. If it is, then the target of
   * this expression is not stored locally but is stored in the nearest ancestor
   * that is a [CascadeExpression].
   */
  bool get isCascaded;

  /**
   * Return the left square bracket.
   */
  Token get leftBracket;

  /**
   * Set the left square bracket to the given [token].
   */
  void set leftBracket(Token token);

  /**
   * Return the period ("..") before a cascaded index expression, or `null` if
   * this index expression is not part of a cascade expression.
   */
  Token get period;

  /**
   * Set the period ("..") before a cascaded index expression to the given
   * [token].
   */
  void set period(Token token);

  /**
   * Return the element associated with the operator based on the propagated
   * type of the target, or `null` if the AST structure has not been resolved or
   * if the operator could not be resolved.
   */
  MethodElement get propagatedElement;

  /**
   * Set the element associated with the operator based on the propagated
   * type of the target to the given [element].
   */
  void set propagatedElement(MethodElement element);

  /**
   * Return the expression used to compute the object being indexed. If this
   * index expression is not part of a cascade expression, then this is the same
   * as [target]. If this index expression is part of a cascade expression, then
   * the target expression stored with the cascade expression is returned.
   */
  Expression get realTarget;

  /**
   * Return the right square bracket.
   */
  Token get rightBracket;

  /**
   * Return the element associated with the operator based on the static type of
   * the target, or `null` if the AST structure has not been resolved or if the
   * operator could not be resolved.
   */
  MethodElement get staticElement;

  /**
   * Set the element associated with the operator based on the static type of
   * the target to the given [element].
   */
  void set staticElement(MethodElement element);

  /**
   * Return the expression used to compute the object being indexed, or `null`
   * if this index expression is part of a cascade expression.
   *
   * Use [realTarget] to get the target independent of whether this is part of a
   * cascade expression.
   */
  Expression get target;

  /**
   * Set the expression used to compute the object being indexed to the given
   * [expression].
   */
  void set target(Expression expression);

  /**
   * Return `true` if this expression is computing a right-hand value (that is,
   * if this expression is in a context where the operator '[]' will be
   * invoked).
   *
   * Note that [inGetterContext] and [inSetterContext] are not opposites, nor
   * are they mutually exclusive. In other words, it is possible for both
   * methods to return `true` when invoked on the same node.
   */
  // TODO(brianwilkerson) Convert this to a getter.
  bool inGetterContext();

  /**
   * Return `true` if this expression is computing a left-hand value (that is,
   * if this expression is in a context where the operator '[]=' will be
   * invoked).
   *
   * Note that [inGetterContext] and [inSetterContext] are not opposites, nor
   * are they mutually exclusive. In other words, it is possible for both
   * methods to return `true` when invoked on the same node.
   */
  // TODO(brianwilkerson) Convert this to a getter.
  bool inSetterContext();
}

/**
 * An instance creation expression.
 *
 *    newExpression ::=
 *        ('new' | 'const') [TypeName] ('.' [SimpleIdentifier])? [ArgumentList]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class InstanceCreationExpression extends Expression {
  /**
   * Initialize a newly created instance creation expression.
   */
  factory InstanceCreationExpression(Token keyword,
          ConstructorName constructorName, ArgumentList argumentList) =>
      new InstanceCreationExpressionImpl(
          keyword, constructorName, argumentList);

  /**
   * Return the list of arguments to the constructor.
   */
  ArgumentList get argumentList;

  /**
   * Set the list of arguments to the constructor to the given [argumentList].
   */
  void set argumentList(ArgumentList argumentList);

  /**
   * Return the name of the constructor to be invoked.
   */
  ConstructorName get constructorName;

  /**
   * Set the name of the constructor to be invoked to the given [name].
   */
  void set constructorName(ConstructorName name);

  /**
   * Return `true` if this creation expression is used to invoke a constant
   * constructor.
   */
  bool get isConst;

  /**
   * Return the 'new' or 'const' keyword used to indicate how an object should
   * be created.
   */
  Token get keyword;

  /**
   * Set the 'new' or 'const' keyword used to indicate how an object should be
   * created to the given [token].
   */
  void set keyword(Token token);

  /**
   * Return the element associated with the constructor based on static type
   * information, or `null` if the AST structure has not been resolved or if the
   * constructor could not be resolved.
   */
  ConstructorElement get staticElement;

  /**
   * Set the element associated with the constructor based on static type
   * information to the given [element].
   */
  void set staticElement(ConstructorElement element);
}

/**
 * An integer literal expression.
 *
 *    integerLiteral ::=
 *        decimalIntegerLiteral
 *      | hexadecimalIntegerLiteral
 *
 *    decimalIntegerLiteral ::=
 *        decimalDigit+
 *
 *    hexadecimalIntegerLiteral ::=
 *        '0x' hexadecimalDigit+
 *      | '0X' hexadecimalDigit+
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class IntegerLiteral extends Literal {
  /**
   * Initialize a newly created integer literal.
   */
  factory IntegerLiteral(Token literal, int value) = IntegerLiteralImpl;

  /**
   * Return the token representing the literal.
   */
  Token get literal;

  /**
   * Set the token representing the literal to the given [token].
   */
  void set literal(Token token);

  /**
   * Return the value of the literal.
   */
  int get value;

  /**
   * Set the value of the literal to the given [value].
   */
  void set value(int value);
}

/**
 * A node within a [StringInterpolation].
 *
 *    interpolationElement ::=
 *        [InterpolationExpression]
 *      | [InterpolationString]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class InterpolationElement extends AstNode {}

/**
 * An expression embedded in a string interpolation.
 *
 *    interpolationExpression ::=
 *        '$' [SimpleIdentifier]
 *      | '$' '{' [Expression] '}'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class InterpolationExpression extends InterpolationElement {
  /**
   * Initialize a newly created interpolation expression.
   */
  factory InterpolationExpression(
          Token leftBracket, Expression expression, Token rightBracket) =>
      new InterpolationExpressionImpl(leftBracket, expression, rightBracket);

  /**
   * Return the expression to be evaluated for the value to be converted into a
   * string.
   */
  Expression get expression;

  /**
   * Set the expression to be evaluated for the value to be converted into a
   * string to the given [expression].
   */
  void set expression(Expression expression);

  /**
   * Return the token used to introduce the interpolation expression; either '$'
   * if the expression is a simple identifier or '${' if the expression is a
   * full expression.
   */
  Token get leftBracket;

  /**
   * Set the token used to introduce the interpolation expression; either '$'
   * if the expression is a simple identifier or '${' if the expression is a
   * full expression to the given [token].
   */
  void set leftBracket(Token token);

  /**
   * Return the right curly bracket, or `null` if the expression is an
   * identifier without brackets.
   */
  Token get rightBracket;

  /**
   * Set the right curly bracket to the given [token].
   */
  void set rightBracket(Token token);
}

/**
 * A non-empty substring of an interpolated string.
 *
 *    interpolationString ::=
 *        characters
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class InterpolationString extends InterpolationElement {
  /**
   * Initialize a newly created string of characters that are part of a string
   * interpolation.
   */
  factory InterpolationString(Token contents, String value) =
      InterpolationStringImpl;

  /**
   * Return the characters that will be added to the string.
   */
  Token get contents;

  /**
   * Set the characters that will be added to the string to the given [token].
   */
  void set contents(Token token);

  /**
   * Return the offset of the after-last contents character.
   */
  int get contentsEnd;

  /**
   * Return the offset of the first contents character.
   */
  int get contentsOffset;

  /**
   * Return the value of the literal.
   */
  String get value;

  /**
   * Set the value of the literal to the given [value].
   */
  void set value(String value);
}

/**
 * The invocation of a function or method; either a
 * [FunctionExpressionInvocation] or a [MethodInvocation].
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class InvocationExpression extends Expression {
  /**
   * Return the list of arguments to the method.
   */
  ArgumentList get argumentList;

  /**
   * The expression that identifies the function or method being invoked.
   * For example:
   *
   *     (o.m)<TArgs>(args); // target will be `o.m`
   *     o.m<TArgs>(args);   // target will be `m`
   *
   * In either case, the [function.staticType] will be the
   * [staticInvokeType] before applying type arguments `TArgs`. Similarly,
   * [function.propagatedType] will be the [propagatedInvokeType]
   * before applying type arguments `TArgs`.
   */
  Expression get function;

  /**
   * Return the function type of the invocation based on the propagated type
   * information, or `null` if the AST structure has not been resolved, or if
   * the invoke could not be resolved.
   *
   * This will usually be a [FunctionType], but it can also be an
   * [InterfaceType] with a `call` method, `dynamic`, `Function`, or a `@proxy`
   * interface type that implements `Function`.
   */
  DartType get propagatedInvokeType;

  /**
   * Sets the function type of the invocation based on the propagated type
   * information.
   */
  void set propagatedInvokeType(DartType value);

  /**
   * Return the function type of the invocation based on the static type
   * information, or `null` if the AST structure has not been resolved, or if
   * the invoke could not be resolved.
   *
   * This will usually be a [FunctionType], but it can also be an
   * [InterfaceType] with a `call` method, `dynamic`, `Function`, or a `@proxy`
   * interface type that implements `Function`.
   */
  DartType get staticInvokeType;

  /**
   * Sets the function type of the invocation based on the static type
   * information.
   */
  void set staticInvokeType(DartType value);

  /**
   * Return the type arguments to be applied to the method being invoked, or
   * `null` if no type arguments were provided.
   */
  TypeArgumentList get typeArguments;
}

/**
 * An is expression.
 *
 *    isExpression ::=
 *        [Expression] 'is' '!'? [TypeName]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class IsExpression extends Expression {
  /**
   * Initialize a newly created is expression. The [notOperator] can be `null`
   * if the sense of the test is not negated.
   */
  factory IsExpression(Expression expression, Token isOperator,
          Token notOperator, TypeName type) =>
      new IsExpressionImpl(expression, isOperator, notOperator, type);

  /**
   * Return the expression used to compute the value whose type is being tested.
   */
  Expression get expression;

  /**
   * Set the expression used to compute the value whose type is being tested to
   * the given [expression].
   */
  void set expression(Expression expression);

  /**
   * Return the is operator.
   */
  Token get isOperator;

  /**
   * Set the is operator to the given [token].
   */
  void set isOperator(Token token);

  /**
   * Return the not operator, or `null` if the sense of the test is not negated.
   */
  Token get notOperator;

  /**
   * Set the not operator to the given [token].
   */
  void set notOperator(Token token);

  /**
   * Return the name of the type being tested for.
   */
  TypeName get type;

  /**
   * Set the name of the type being tested for to the given [name].
   */
  void set type(TypeName name);
}

/**
 * A label on either a [LabeledStatement] or a [NamedExpression].
 *
 *    label ::=
 *        [SimpleIdentifier] ':'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class Label extends AstNode {
  /**
   * Initialize a newly created label.
   */
  factory Label(SimpleIdentifier label, Token colon) =>
      new LabelImpl(label, colon);

  /**
   * Return the colon that separates the label from the statement.
   */
  Token get colon;

  /**
   * Set the colon that separates the label from the statement to the given
   * [token].
   */
  void set colon(Token token);

  /**
   * Return the label being associated with the statement.
   */
  SimpleIdentifier get label;

  /**
   * Set the label being associated with the statement to the given [label].
   */
  void set label(SimpleIdentifier label);
}

/**
 * A statement that has a label associated with them.
 *
 *    labeledStatement ::=
 *       [Label]+ [Statement]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class LabeledStatement extends Statement {
  /**
   * Initialize a newly created labeled statement.
   */
  factory LabeledStatement(List<Label> labels, Statement statement) =>
      new LabeledStatementImpl(labels, statement);

  /**
   * Return the labels being associated with the statement.
   */
  NodeList<Label> get labels;

  /**
   * Return the statement with which the labels are being associated.
   */
  Statement get statement;

  /**
   * Set the statement with which the labels are being associated to the given
   * [statement].
   */
  void set statement(Statement statement);
}

/**
 * A library directive.
 *
 *    libraryDirective ::=
 *        [Annotation] 'library' [Identifier] ';'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class LibraryDirective extends Directive {
  /**
   * Initialize a newly created library directive. Either or both of the
   * [comment] and [metadata] can be `null` if the directive does not have the
   * corresponding attribute.
   */
  factory LibraryDirective(Comment comment, List<Annotation> metadata,
          Token libraryKeyword, LibraryIdentifier name, Token semicolon) =>
      new LibraryDirectiveImpl(
          comment, metadata, libraryKeyword, name, semicolon);

  /**
   * Return the token representing the 'library' keyword.
   */
  Token get libraryKeyword;

  /**
   * Set the token representing the 'library' keyword to the given [token].
   */
  void set libraryKeyword(Token token);

  /**
   * Return the name of the library being defined.
   */
  LibraryIdentifier get name;

  /**
   * Set the name of the library being defined to the given [name].
   */
  void set name(LibraryIdentifier name);

  /**
   * Return the semicolon terminating the directive.
   */
  Token get semicolon;

  /**
   * Set the semicolon terminating the directive to the given [token].
   */
  void set semicolon(Token token);
}

/**
 * The identifier for a library.
 *
 *    libraryIdentifier ::=
 *        [SimpleIdentifier] ('.' [SimpleIdentifier])*
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class LibraryIdentifier extends Identifier {
  /**
   * Initialize a newly created prefixed identifier.
   */
  factory LibraryIdentifier(List<SimpleIdentifier> components) =
      LibraryIdentifierImpl;

  /**
   * Return the components of the identifier.
   */
  NodeList<SimpleIdentifier> get components;
}

/**
 * A list literal.
 *
 *    listLiteral ::=
 *        'const'? ('<' [TypeName] '>')? '[' ([Expression] ','?)? ']'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ListLiteral extends TypedLiteral {
  /**
   * Initialize a newly created list literal. The [constKeyword] can be `null`
   * if the literal is not a constant. The [typeArguments] can be `null` if no
   * type arguments were declared. The list of [elements] can be `null` if the
   * list is empty.
   */
  factory ListLiteral(
      Token constKeyword,
      TypeArgumentList typeArguments,
      Token leftBracket,
      List<Expression> elements,
      Token rightBracket) = ListLiteralImpl;

  /**
   * Return the expressions used to compute the elements of the list.
   */
  NodeList<Expression> get elements;

  /**
   * Return the left square bracket.
   */
  Token get leftBracket;

  /**
   * Set the left square bracket to the given [token].
   */
  void set leftBracket(Token token);

  /**
   * Return the right square bracket.
   */
  Token get rightBracket;

  /**
   * Set the right square bracket to the given [token].
   */
  void set rightBracket(Token token);
}

/**
 * A node that represents a literal expression.
 *
 *    literal ::=
 *        [BooleanLiteral]
 *      | [DoubleLiteral]
 *      | [IntegerLiteral]
 *      | [ListLiteral]
 *      | [MapLiteral]
 *      | [NullLiteral]
 *      | [StringLiteral]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class Literal extends Expression {}

/**
 * A literal map.
 *
 *    mapLiteral ::=
 *        'const'? ('<' [TypeName] (',' [TypeName])* '>')?
 *        '{' ([MapLiteralEntry] (',' [MapLiteralEntry])* ','?)? '}'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class MapLiteral extends TypedLiteral {
  /**
   * Initialize a newly created map literal. The [constKeyword] can be `null` if
   * the literal is not a constant. The [typeArguments] can be `null` if no type
   * arguments were declared. The [entries] can be `null` if the map is empty.
   */
  factory MapLiteral(
      Token constKeyword,
      TypeArgumentList typeArguments,
      Token leftBracket,
      List<MapLiteralEntry> entries,
      Token rightBracket) = MapLiteralImpl;

  /**
   * Return the entries in the map.
   */
  NodeList<MapLiteralEntry> get entries;

  /**
   * Return the left curly bracket.
   */
  Token get leftBracket;

  /**
   * Set the left curly bracket to the given [token].
   */
  void set leftBracket(Token token);

  /**
   * Return the right curly bracket.
   */
  Token get rightBracket;

  /**
   * Set the right curly bracket to the given [token].
   */
  void set rightBracket(Token token);
}

/**
 * A single key/value pair in a map literal.
 *
 *    mapLiteralEntry ::=
 *        [Expression] ':' [Expression]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class MapLiteralEntry extends AstNode {
  /**
   * Initialize a newly created map literal entry.
   */
  factory MapLiteralEntry(Expression key, Token separator, Expression value) =>
      new MapLiteralEntryImpl(key, separator, value);

  /**
   * Return the expression computing the key with which the value will be
   * associated.
   */
  Expression get key;

  /**
   * Set the expression computing the key with which the value will be
   * associated to the given [string].
   */
  void set key(Expression string);

  /**
   * Return the colon that separates the key from the value.
   */
  Token get separator;

  /**
   * Set the colon that separates the key from the value to the given [token].
   */
  void set separator(Token token);

  /**
   * Return the expression computing the value that will be associated with the
   * key.
   */
  Expression get value;

  /**
   * Set the expression computing the value that will be associated with the key
   * to the given [expression].
   */
  void set value(Expression expression);
}

/**
 * A method declaration.
 *
 *    methodDeclaration ::=
 *        methodSignature [FunctionBody]
 *
 *    methodSignature ::=
 *        'external'? ('abstract' | 'static')? [Type]? ('get' | 'set')?
 *        methodName [TypeParameterList] [FormalParameterList]
 *
 *    methodName ::=
 *        [SimpleIdentifier]
 *      | 'operator' [SimpleIdentifier]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class MethodDeclaration extends ClassMember {
  /**
   * Initialize a newly created method declaration. Either or both of the
   * [comment] and [metadata] can be `null` if the declaration does not have the
   * corresponding attribute. The [externalKeyword] can be `null` if the method
   * is not external. The [modifierKeyword] can be `null` if the method is
   * neither abstract nor static. The [returnType] can be `null` if no return
   * type was specified. The [propertyKeyword] can be `null` if the method is
   * neither a getter or a setter. The [operatorKeyword] can be `null` if the
   * method does not implement an operator. The [parameters] must be `null` if
   * this method declares a getter.
   */
  factory MethodDeclaration(
          Comment comment,
          List<Annotation> metadata,
          Token externalKeyword,
          Token modifierKeyword,
          TypeName returnType,
          Token propertyKeyword,
          Token operatorKeyword,
          SimpleIdentifier name,
          TypeParameterList typeParameters,
          FormalParameterList parameters,
          FunctionBody body) =>
      new MethodDeclarationImpl(
          comment,
          metadata,
          externalKeyword,
          modifierKeyword,
          returnType,
          propertyKeyword,
          operatorKeyword,
          name,
          typeParameters,
          parameters,
          body);

  /**
   * Return the body of the method.
   */
  FunctionBody get body;

  /**
   * Set the body of the method to the given [functionBody].
   */
  void set body(FunctionBody functionBody);

  @override
  ExecutableElement get element;

  /**
   * Return the token for the 'external' keyword, or `null` if the constructor
   * is not external.
   */
  Token get externalKeyword;

  /**
   * Set the token for the 'external' keyword to the given [token].
   */
  void set externalKeyword(Token token);

  /**
   * Return `true` if this method is declared to be an abstract method.
   */
  bool get isAbstract;

  /**
   * Return `true` if this method declares a getter.
   */
  bool get isGetter;

  /**
   * Return `true` if this method declares an operator.
   */
  bool get isOperator;

  /**
   * Return `true` if this method declares a setter.
   */
  bool get isSetter;

  /**
   * Return `true` if this method is declared to be a static method.
   */
  bool get isStatic;

  /**
   * Return the token representing the 'abstract' or 'static' keyword, or `null`
   * if neither modifier was specified.
   */
  Token get modifierKeyword;

  /**
   * Set the token representing the 'abstract' or 'static' keyword to the given
   * [token].
   */
  void set modifierKeyword(Token token);

  /**
   * Return the name of the method.
   */
  SimpleIdentifier get name;

  /**
   * Set the name of the method to the given [identifier].
   */
  void set name(SimpleIdentifier identifier);

  /**
   * Return the token representing the 'operator' keyword, or `null` if this
   * method does not declare an operator.
   */
  Token get operatorKeyword;

  /**
   * Set the token representing the 'operator' keyword to the given [token].
   */
  void set operatorKeyword(Token token);

  /**
   * Return the parameters associated with the method, or `null` if this method
   * declares a getter.
   */
  FormalParameterList get parameters;

  /**
   * Set the parameters associated with the method to the given list of
   * [parameters].
   */
  void set parameters(FormalParameterList parameters);

  /**
   * Return the token representing the 'get' or 'set' keyword, or `null` if this
   * is a method declaration rather than a property declaration.
   */
  Token get propertyKeyword;

  /**
   * Set the token representing the 'get' or 'set' keyword to the given [token].
   */
  void set propertyKeyword(Token token);

  /**
   * Return the return type of the method, or `null` if no return type was
   * declared.
   */
  TypeName get returnType;

  /**
   * Set the return type of the method to the given [typeName].
   */
  void set returnType(TypeName typeName);

  /**
   * Return the type parameters associated with this method, or `null` if this
   * method is not a generic method.
   */
  TypeParameterList get typeParameters;

  /**
   * Set the type parameters associated with this method to the given
   * [typeParameters].
   */
  void set typeParameters(TypeParameterList typeParameters);
}

/**
 * The invocation of either a function or a method. Invocations of functions
 * resulting from evaluating an expression are represented by
 * [FunctionExpressionInvocation] nodes. Invocations of getters and setters are
 * represented by either [PrefixedIdentifier] or [PropertyAccess] nodes.
 *
 *    methodInvocation ::=
 *        ([Expression] '.')? [SimpleIdentifier] [TypeArgumentList]? [ArgumentList]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class MethodInvocation extends InvocationExpression {
  /**
   * Initialize a newly created method invocation. The [target] and [operator]
   * can be `null` if there is no target.
   */
  factory MethodInvocation(
          Expression target,
          Token operator,
          SimpleIdentifier methodName,
          TypeArgumentList typeArguments,
          ArgumentList argumentList) =>
      new MethodInvocationImpl(
          target, operator, methodName, typeArguments, argumentList);

  /**
   * Set the list of arguments to the method to the given [argumentList].
   */
  void set argumentList(ArgumentList argumentList);

  /**
   * Return `true` if this expression is cascaded. If it is, then the target of
   * this expression is not stored locally but is stored in the nearest ancestor
   * that is a [CascadeExpression].
   */
  bool get isCascaded;

  /**
   * Return the name of the method being invoked.
   */
  SimpleIdentifier get methodName;

  /**
   * Set the name of the method being invoked to the given [identifier].
   */
  void set methodName(SimpleIdentifier identifier);

  /**
   * Return the operator that separates the target from the method name, or
   * `null` if there is no target. In an ordinary method invocation this will be
   *  * period ('.'). In a cascade section this will be the cascade operator
   * ('..').
   */
  Token get operator;

  /**
   * Set the operator that separates the target from the method name to the
   * given [token].
   */
  void set operator(Token token);

  /**
   * Return the function type of the method invocation based on the propagated
   * type information, or `null` if the AST structure has not been resolved, or
   * if the invoke could not be resolved.
   *
   * This will usually be a [FunctionType], but it can also be an
   * [InterfaceType] with a `call` method, `dynamic`, `Function`, or a `@proxy`
   * interface type that implements `Function`.
   */
  @override
  DartType get propagatedInvokeType;

  /**
   * Set the function type of the method invocation based on the propagated type
   * information to the given [type].
   */
  @override
  void set propagatedInvokeType(DartType type);

  /**
   * Return the expression used to compute the receiver of the invocation. If
   * this invocation is not part of a cascade expression, then this is the same
   * as [target]. If this invocation is part of a cascade expression, then the
   * target stored with the cascade expression is returned.
   */
  Expression get realTarget;

  /**
   * Return the function type of the method invocation based on the static type
   * information, or `null` if the AST structure has not been resolved, or if
   * the invoke could not be resolved.
   *
   * This will usually be a [FunctionType], but it can also be an
   * [InterfaceType] with a `call` method, `dynamic`, `Function`, or a `@proxy`
   * interface type that implements `Function`.
   */
  @override
  DartType get staticInvokeType;

  /**
   * Set the function type of the method invocation based on the static type
   * information to the given [type].
   */
  @override
  void set staticInvokeType(DartType type);

  /**
   * Return the expression producing the object on which the method is defined,
   * or `null` if there is no target (that is, the target is implicitly `this`)
   * or if this method invocation is part of a cascade expression.
   *
   * Use [realTarget] to get the target independent of whether this is part of a
   * cascade expression.
   */
  Expression get target;

  /**
   * Set the expression producing the object on which the method is defined to
   * the given [expression].
   */
  void set target(Expression expression);

  /**
   * Set the type arguments to be applied to the method being invoked to the
   * given [typeArguments].
   */
  void set typeArguments(TypeArgumentList typeArguments);
}

/**
 * A node that declares a single name within the scope of a compilation unit.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class NamedCompilationUnitMember extends CompilationUnitMember {
  /**
   * Return the name of the member being declared.
   */
  SimpleIdentifier get name;

  /**
   * Set the name of the member being declared to the given [identifier].
   */
  void set name(SimpleIdentifier identifier);
}

/**
 * An expression that has a name associated with it. They are used in method
 * invocations when there are named parameters.
 *
 *    namedExpression ::=
 *        [Label] [Expression]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class NamedExpression extends Expression {
  /**
   * Initialize a newly created named expression..
   */
  factory NamedExpression(Label name, Expression expression) =>
      new NamedExpressionImpl(name, expression);

  /**
   * Return the element representing the parameter being named by this
   * expression, or `null` if the AST structure has not been resolved or if
   * there is no parameter with the same name as this expression.
   */
  ParameterElement get element;

  /**
   * Return the expression with which the name is associated.
   */
  Expression get expression;

  /**
   * Set the expression with which the name is associated to the given
   * [expression].
   */
  void set expression(Expression expression);

  /**
   * Return the name associated with the expression.
   */
  Label get name;

  /**
   * Set the name associated with the expression to the given [identifier].
   */
  void set name(Label identifier);
}

/**
 * A node that represents a directive that impacts the namespace of a library.
 *
 *    directive ::=
 *        [ExportDirective]
 *      | [ImportDirective]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class NamespaceDirective extends UriBasedDirective {
  /**
   * Return the combinators used to control how names are imported or exported.
   */
  NodeList<Combinator> get combinators;

  /**
   * Return the configurations used to control which library will actually be
   * loaded at run-time.
   */
  NodeList<Configuration> get configurations;

  /**
   * Set the token representing the keyword that introduces this directive
   * ('import', 'export', 'library' or 'part') to the given [token].
   */
  void set keyword(Token token);

  /**
   * Return the semicolon terminating the directive.
   */
  Token get semicolon;

  /**
   * Set the semicolon terminating the directive to the given [token].
   */
  void set semicolon(Token token);
}

/**
 * The "native" clause in an class declaration.
 *
 *    nativeClause ::=
 *        'native' [StringLiteral]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class NativeClause extends AstNode {
  /**
   * Initialize a newly created native clause.
   */
  factory NativeClause(Token nativeKeyword, StringLiteral name) =>
      new NativeClauseImpl(nativeKeyword, name);

  /**
   * Return the name of the native object that implements the class.
   */
  StringLiteral get name;

  /**
   * Set the name of the native object that implements the class to the given
   * [name].
   */
  void set name(StringLiteral name);

  /**
   * Return the token representing the 'native' keyword.
   */
  Token get nativeKeyword;

  /**
   * Set the token representing the 'native' keyword to the given [token].
   */
  void set nativeKeyword(Token token);
}

/**
 * A function body that consists of a native keyword followed by a string
 * literal.
 *
 *    nativeFunctionBody ::=
 *        'native' [SimpleStringLiteral] ';'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class NativeFunctionBody extends FunctionBody {
  /**
   * Initialize a newly created function body consisting of the 'native' token,
   * a string literal, and a semicolon.
   */
  factory NativeFunctionBody(
          Token nativeKeyword, StringLiteral stringLiteral, Token semicolon) =>
      new NativeFunctionBodyImpl(nativeKeyword, stringLiteral, semicolon);

  /**
   * Return the token representing 'native' that marks the start of the function
   * body.
   */
  Token get nativeKeyword;

  /**
   * Set the token representing 'native' that marks the start of the function
   * body to the given [token].
   */
  void set nativeKeyword(Token token);

  /**
   * Return the token representing the semicolon that marks the end of the
   * function body.
   */
  Token get semicolon;

  /**
   * Set the token representing the semicolon that marks the end of the
   * function body to the given [token].
   */
  void set semicolon(Token token);

  /**
   * Return the string literal representing the string after the 'native' token.
   */
  StringLiteral get stringLiteral;

  /**
   * Set the string literal representing the string after the 'native' token to
   * the given [stringLiteral].
   */
  void set stringLiteral(StringLiteral stringLiteral);
}

/**
 * A list of AST nodes that have a common parent.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class NodeList<E extends AstNode> implements List<E> {
  /**
   * Initialize a newly created list of nodes such that all of the nodes that
   * are added to the list will have their parent set to the given [owner]. The
   * list will initially be populated with the given [elements].
   */
  factory NodeList(AstNode owner, [List<E> elements]) =>
      new NodeListImpl<E>(owner as AstNodeImpl, elements);

  /**
   * Return the first token included in this node list's source range, or `null`
   * if the list is empty.
   */
  Token get beginToken;

  /**
   * Return the last token included in this node list's source range, or `null`
   * if the list is empty.
   */
  Token get endToken;

  /**
   * Return the node that is the parent of each of the elements in the list.
   */
  AstNode get owner;

  /**
   * Set the node that is the parent of each of the elements in the list to the
   * given [node].
   */
  @deprecated // Never intended for public use.
  void set owner(AstNode node);

  /**
   * Return the node at the given [index] in the list or throw a [RangeError] if
   * [index] is out of bounds.
   */
  @override
  E operator [](int index);

  /**
   * Set the node at the given [index] in the list to the given [node] or throw
   * a [RangeError] if [index] is out of bounds.
   */
  @override
  void operator []=(int index, E node);

  /**
   * Use the given [visitor] to visit each of the nodes in this list.
   */
  accept(AstVisitor visitor);
}

/**
 * A formal parameter that is required (is not optional).
 *
 *    normalFormalParameter ::=
 *        [FunctionTypedFormalParameter]
 *      | [FieldFormalParameter]
 *      | [SimpleFormalParameter]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class NormalFormalParameter extends FormalParameter {
  /**
   * Return the documentation comment associated with this parameter, or `null`
   * if this parameter does not have a documentation comment associated with it.
   */
  Comment get documentationComment;

  /**
   * Set the documentation comment associated with this parameter to the given
   * [comment].
   */
  void set documentationComment(Comment comment);

  /**
   * Set the name of the parameter being declared to the given [identifier].
   */
  void set identifier(SimpleIdentifier identifier);

  /**
   * Set the metadata associated with this node to the given [metadata].
   */
  void set metadata(List<Annotation> metadata);

  /**
   * Return a list containing the comment and annotations associated with this
   * parameter, sorted in lexical order.
   */
  List<AstNode> get sortedCommentAndAnnotations;
}

/**
 * A null literal expression.
 *
 *    nullLiteral ::=
 *        'null'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class NullLiteral extends Literal {
  /**
   * Initialize a newly created null literal.
   */
  factory NullLiteral(Token literal) = NullLiteralImpl;

  /**
   * Return the token representing the literal.
   */
  Token get literal;

  /**
   * Set the token representing the literal to the given [token].
   */
  void set literal(Token token);
}

/**
 * A parenthesized expression.
 *
 *    parenthesizedExpression ::=
 *        '(' [Expression] ')'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ParenthesizedExpression extends Expression {
  /**
   * Initialize a newly created parenthesized expression.
   */
  factory ParenthesizedExpression(Token leftParenthesis, Expression expression,
          Token rightParenthesis) =>
      new ParenthesizedExpressionImpl(
          leftParenthesis, expression, rightParenthesis);

  /**
   * Return the expression within the parentheses.
   */
  Expression get expression;

  /**
   * Set the expression within the parentheses to the given [expression].
   */
  void set expression(Expression expression);

  /**
   * Return the left parenthesis.
   */
  Token get leftParenthesis;

  /**
   * Set the left parenthesis to the given [token].
   */
  void set leftParenthesis(Token token);

  /**
   * Return the right parenthesis.
   */
  Token get rightParenthesis;

  /**
   * Set the right parenthesis to the given [token].
   */
  void set rightParenthesis(Token token);
}

/**
 * A part directive.
 *
 *    partDirective ::=
 *        [Annotation] 'part' [StringLiteral] ';'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class PartDirective extends UriBasedDirective {
  /**
   * Initialize a newly created part directive. Either or both of the [comment]
   * and [metadata] can be `null` if the directive does not have the
   * corresponding attribute.
   */
  factory PartDirective(
      Comment comment,
      List<Annotation> metadata,
      Token partKeyword,
      StringLiteral partUri,
      Token semicolon) = PartDirectiveImpl;

  /**
   * Return the token representing the 'part' keyword.
   */
  Token get partKeyword;

  /**
   * Set the token representing the 'part' keyword to the given [token].
   */
  void set partKeyword(Token token);

  /**
   * Return the semicolon terminating the directive.
   */
  Token get semicolon;

  /**
   * Set the semicolon terminating the directive to the given [token].
   */
  void set semicolon(Token token);
}

/**
 * A part-of directive.
 *
 *    partOfDirective ::=
 *        [Annotation] 'part' 'of' [Identifier] ';'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class PartOfDirective extends Directive {
  /**
   * Initialize a newly created part-of directive. Either or both of the
   * [comment] and [metadata] can be `null` if the directive does not have the
   * corresponding attribute.
   */
  factory PartOfDirective(
          Comment comment,
          List<Annotation> metadata,
          Token partKeyword,
          Token ofKeyword,
          LibraryIdentifier libraryName,
          Token semicolon) =>
      new PartOfDirectiveImpl(
          comment, metadata, partKeyword, ofKeyword, libraryName, semicolon);

  /**
   * Return the name of the library that the containing compilation unit is part
   * of.
   */
  LibraryIdentifier get libraryName;

  /**
   * Set the name of the library that the containing compilation unit is part of
   * to the given [libraryName].
   */
  void set libraryName(LibraryIdentifier libraryName);

  /**
   * Return the token representing the 'of' keyword.
   */
  Token get ofKeyword;

  /**
   * Set the token representing the 'of' keyword to the given [token].
   */
  void set ofKeyword(Token token);

  /**
   * Return the token representing the 'part' keyword.
   */
  Token get partKeyword;

  /**
   * Set the token representing the 'part' keyword to the given [token].
   */
  void set partKeyword(Token token);

  /**
   * Return the semicolon terminating the directive.
   */
  Token get semicolon;

  /**
   * Set the semicolon terminating the directive to the given [token].
   */
  void set semicolon(Token token);
}

/**
 * A postfix unary expression.
 *
 *    postfixExpression ::=
 *        [Expression] [Token]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class PostfixExpression extends Expression {
  /**
   * Initialize a newly created postfix expression.
   */
  factory PostfixExpression(Expression operand, Token operator) =>
      new PostfixExpressionImpl(operand, operator);

  /**
   * Return the best element available for this operator. If resolution was able
   * to find a better element based on type propagation, that element will be
   * returned. Otherwise, the element found using the result of static analysis
   * will be returned. If resolution has not been performed, then `null` will be
   * returned.
   */
  MethodElement get bestElement;

  /**
   * Return the expression computing the operand for the operator.
   */
  Expression get operand;

  /**
   * Set the expression computing the operand for the operator to the given
   * [expression].
   */
  void set operand(Expression expression);

  /**
   * Return the postfix operator being applied to the operand.
   */
  Token get operator;

  /**
   * Set the postfix operator being applied to the operand to the given [token].
   */
  void set operator(Token token);

  /**
   * Return the element associated with this the operator based on the
   * propagated type of the operand, or `null` if the AST structure has not been
   * resolved, if the operator is not user definable, or if the operator could
   * not be resolved.
   */
  MethodElement get propagatedElement;

  /**
   * Set the element associated with this the operator based on the propagated
   * type of the operand to the given [element].
   */
  void set propagatedElement(MethodElement element);

  /**
   * Return the element associated with the operator based on the static type of
   * the operand, or `null` if the AST structure has not been resolved, if the
   * operator is not user definable, or if the operator could not be resolved.
   */
  MethodElement get staticElement;

  /**
   * Set the element associated with the operator based on the static type of
   * the operand to the given [element].
   */
  void set staticElement(MethodElement element);
}

/**
 * An identifier that is prefixed or an access to an object property where the
 * target of the property access is a simple identifier.
 *
 *    prefixedIdentifier ::=
 *        [SimpleIdentifier] '.' [SimpleIdentifier]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class PrefixedIdentifier extends Identifier {
  /**
   * Initialize a newly created prefixed identifier.
   */
  factory PrefixedIdentifier(
          SimpleIdentifier prefix, Token period, SimpleIdentifier identifier) =>
      new PrefixedIdentifierImpl(prefix, period, identifier);

  /**
   * Return the identifier being prefixed.
   */
  SimpleIdentifier get identifier;

  /**
   * Set the identifier being prefixed to the given [identifier].
   */
  void set identifier(SimpleIdentifier identifier);

  /**
   * Return `true` if this type is a deferred type. If the AST structure has not
   * been resolved, then return `false`.
   *
   * 15.1 Static Types: A type <i>T</i> is deferred iff it is of the form
   * </i>p.T</i> where <i>p</i> is a deferred prefix.
   */
  bool get isDeferred;

  /**
   * Return the period used to separate the prefix from the identifier.
   */
  Token get period;

  /**
   * Set the period used to separate the prefix from the identifier to the given
   * [token].
   */
  void set period(Token token);

  /**
   * Return the prefix associated with the library in which the identifier is
   * defined.
   */
  SimpleIdentifier get prefix;

  /**
   * Set the prefix associated with the library in which the identifier is
   * defined to the given [identifier].
   */
  void set prefix(SimpleIdentifier identifier);
}

/**
 * A prefix unary expression.
 *
 *    prefixExpression ::=
 *        [Token] [Expression]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class PrefixExpression extends Expression {
  /**
   * Initialize a newly created prefix expression.
   */
  factory PrefixExpression(Token operator, Expression operand) =>
      new PrefixExpressionImpl(operator, operand);

  /**
   * Return the best element available for this operator. If resolution was able
   * to find a better element based on type propagation, that element will be
   * returned. Otherwise, the element found using the result of static analysis
   * will be returned. If resolution has not been performed, then `null` will be
   * returned.
   */
  MethodElement get bestElement;

  /**
   * Return the expression computing the operand for the operator.
   */
  Expression get operand;

  /**
   * Set the expression computing the operand for the operator to the given
   * [expression].
   */
  void set operand(Expression expression);

  /**
   * Return the prefix operator being applied to the operand.
   */
  Token get operator;

  /**
   * Set the prefix operator being applied to the operand to the given [token].
   */
  void set operator(Token token);

  /**
   * Return the element associated with the operator based on the propagated
   * type of the operand, or `null` if the AST structure has not been resolved,
   * if the operator is not user definable, or if the operator could not be
   * resolved.
   */
  MethodElement get propagatedElement;

  /**
   * Set the element associated with the operator based on the propagated type
   * of the operand to the given [element].
   */
  void set propagatedElement(MethodElement element);

  /**
   * Return the element associated with the operator based on the static type of
   * the operand, or `null` if the AST structure has not been resolved, if the
   * operator is not user definable, or if the operator could not be resolved.
   */
  MethodElement get staticElement;

  /**
   * Set the element associated with the operator based on the static type of
   * the operand to the given [element].
   */
  void set staticElement(MethodElement element);
}

/**
 * The access of a property of an object.
 *
 * Note, however, that accesses to properties of objects can also be represented
 * as [PrefixedIdentifier] nodes in cases where the target is also a simple
 * identifier.
 *
 *    propertyAccess ::=
 *        [Expression] '.' [SimpleIdentifier]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class PropertyAccess extends Expression {
  /**
   * Initialize a newly created property access expression.
   */
  factory PropertyAccess(
          Expression target, Token operator, SimpleIdentifier propertyName) =>
      new PropertyAccessImpl(target, operator, propertyName);

  /**
   * Return `true` if this expression is cascaded. If it is, then the target of
   * this expression is not stored locally but is stored in the nearest ancestor
   * that is a [CascadeExpression].
   */
  bool get isCascaded;

  /**
   * Return the property access operator.
   */
  Token get operator;

  /**
   * Set the property access operator to the given [token].
   */
  void set operator(Token token);

  /**
   * Return the name of the property being accessed.
   */
  SimpleIdentifier get propertyName;

  /**
   * Set the name of the property being accessed to the given [identifier].
   */
  void set propertyName(SimpleIdentifier identifier);

  /**
   * Return the expression used to compute the receiver of the invocation. If
   * this invocation is not part of a cascade expression, then this is the same
   * as [target]. If this invocation is part of a cascade expression, then the
   * target stored with the cascade expression is returned.
   */
  Expression get realTarget;

  /**
   * Return the expression computing the object defining the property being
   * accessed, or `null` if this property access is part of a cascade expression.
   *
   * Use [realTarget] to get the target independent of whether this is part of a
   * cascade expression.
   */
  Expression get target;

  /**
   * Set the expression computing the object defining the property being
   * accessed to the given [expression].
   */
  void set target(Expression expression);
}

/**
 * The invocation of a constructor in the same class from within a constructor's
 * initialization list.
 *
 *    redirectingConstructorInvocation ::=
 *        'this' ('.' identifier)? arguments
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class RedirectingConstructorInvocation extends ConstructorInitializer {
  /**
   * Initialize a newly created redirecting invocation to invoke the constructor
   * with the given name with the given arguments. The [constructorName] can be
   * `null` if the constructor being invoked is the unnamed constructor.
   */
  factory RedirectingConstructorInvocation(Token thisKeyword, Token period,
          SimpleIdentifier constructorName, ArgumentList argumentList) =>
      new RedirectingConstructorInvocationImpl(
          thisKeyword, period, constructorName, argumentList);

  /**
   * Return the list of arguments to the constructor.
   */
  ArgumentList get argumentList;

  /**
   * Set the list of arguments to the constructor to the given [argumentList].
   */
  void set argumentList(ArgumentList argumentList);

  /**
   * Return the name of the constructor that is being invoked, or `null` if the
   * unnamed constructor is being invoked.
   */
  SimpleIdentifier get constructorName;

  /**
   * Set the name of the constructor that is being invoked to the given
   * [identifier].
   */
  void set constructorName(SimpleIdentifier identifier);

  /**
   * Return the token for the period before the name of the constructor that is
   * being invoked, or `null` if the unnamed constructor is being invoked.
   */
  Token get period;

  /**
   * Set the token for the period before the name of the constructor that is
   * being invoked to the given [token].
   */
  void set period(Token token);

  /**
   * Return the element associated with the constructor based on static type
   * information, or `null` if the AST structure has not been resolved or if the
   * constructor could not be resolved.
   */
  ConstructorElement get staticElement;

  /**
   * Set the element associated with the constructor based on static type
   * information to the given [element].
   */
  void set staticElement(ConstructorElement element);

  /**
   * Return the token for the 'this' keyword.
   */
  Token get thisKeyword;

  /**
   * Set the token for the 'this' keyword to the given [token].
   */
  void set thisKeyword(Token token);
}

/**
 * A rethrow expression.
 *
 *    rethrowExpression ::=
 *        'rethrow'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class RethrowExpression extends Expression {
  /**
   * Initialize a newly created rethrow expression.
   */
  factory RethrowExpression(Token rethrowKeyword) = RethrowExpressionImpl;

  /**
   * Return the token representing the 'rethrow' keyword.
   */
  Token get rethrowKeyword;

  /**
   * Set the token representing the 'rethrow' keyword to the given [token].
   */
  void set rethrowKeyword(Token token);
}

/**
 * A return statement.
 *
 *    returnStatement ::=
 *        'return' [Expression]? ';'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ReturnStatement extends Statement {
  /**
   * Initialize a newly created return statement. The [expression] can be `null`
   * if no explicit value was provided.
   */
  factory ReturnStatement(
          Token returnKeyword, Expression expression, Token semicolon) =>
      new ReturnStatementImpl(returnKeyword, expression, semicolon);

  /**
   * Return the expression computing the value to be returned, or `null` if no
   * explicit value was provided.
   */
  Expression get expression;

  /**
   * Set the expression computing the value to be returned to the given
   * [expression].
   */
  void set expression(Expression expression);

  /**
   * Return the token representing the 'return' keyword.
   */
  Token get returnKeyword;

  /**
   * Set the token representing the 'return' keyword to the given [token].
   */
  void set returnKeyword(Token token);

  /**
   * Return the semicolon terminating the statement.
   */
  Token get semicolon;

  /**
   * Set the semicolon terminating the statement to the given [token].
   */
  void set semicolon(Token token);
}

/**
 * A script tag that can optionally occur at the beginning of a compilation unit.
 *
 *    scriptTag ::=
 *        '#!' (~NEWLINE)* NEWLINE
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ScriptTag extends AstNode {
  /**
   * Initialize a newly created script tag.
   */
  factory ScriptTag(Token scriptTag) = ScriptTagImpl;

  /**
   * Return the token representing this script tag.
   */
  Token get scriptTag;

  /**
   * Set the token representing this script tag to the given [token].
   */
  void set scriptTag(Token token);
}

/**
 * A combinator that restricts the names being imported to those in a given list.
 *
 *    showCombinator ::=
 *        'show' [SimpleIdentifier] (',' [SimpleIdentifier])*
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ShowCombinator extends Combinator {
  /**
   * Initialize a newly created import show combinator.
   */
  factory ShowCombinator(Token keyword, List<SimpleIdentifier> shownNames) =
      ShowCombinatorImpl;

  /**
   * Return the list of names from the library that are made visible by this
   * combinator.
   */
  NodeList<SimpleIdentifier> get shownNames;
}

/**
 * A simple formal parameter.
 *
 *    simpleFormalParameter ::=
 *        ('final' [TypeName] | 'var' | [TypeName])? [SimpleIdentifier]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class SimpleFormalParameter extends NormalFormalParameter {
  /**
   * Initialize a newly created formal parameter. Either or both of the
   * [comment] and [metadata] can be `null` if the parameter does not have the
   * corresponding attribute. The [keyword] can be `null` if a type was
   * specified. The [type] must be `null` if the keyword is 'var'.
   */
  factory SimpleFormalParameter(Comment comment, List<Annotation> metadata,
          Token keyword, TypeName type, SimpleIdentifier identifier) =>
      new SimpleFormalParameterImpl(
          comment, metadata, keyword, type, identifier);

  /**
   * Return the token representing either the 'final', 'const' or 'var' keyword,
   * or `null` if no keyword was used.
   */
  Token get keyword;

  /**
   * Set the token representing either the 'final', 'const' or 'var' keyword to
   * the given [token].
   */
  void set keyword(Token token);

  /**
   * Return the name of the declared type of the parameter, or `null` if the
   * parameter does not have a declared type.
   */
  TypeName get type;

  /**
   * Set the name of the declared type of the parameter to the given [typeName].
   */
  void set type(TypeName typeName);
}

/**
 * A simple identifier.
 *
 *    simpleIdentifier ::=
 *        initialCharacter internalCharacter*
 *
 *    initialCharacter ::= '_' | '$' | letter
 *
 *    internalCharacter ::= '_' | '$' | letter | digit
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class SimpleIdentifier extends Identifier {
  /**
   * Initialize a newly created identifier.
   */
  factory SimpleIdentifier(Token token, {bool isDeclaration: false}) {
    if (isDeclaration) {
      return new DeclaredSimpleIdentifier(token);
    }
    return new SimpleIdentifierImpl(token);
  }

  /**
   * Return the auxiliary elements associated with this identifier, or `null` if
   * this identifier is not in both a getter and setter context. The auxiliary
   * elements hold the static and propagated elements associated with the getter
   * context.
   */
  // TODO(brianwilkerson) Replace this API.
  AuxiliaryElements get auxiliaryElements;

  /**
   * Set the auxiliary elements associated with this identifier to the given
   * [elements].
   */
  // TODO(brianwilkerson) Replace this API.
  void set auxiliaryElements(AuxiliaryElements elements);

  /**
   * Return `true` if this identifier is the "name" part of a prefixed
   * identifier or a method invocation.
   */
  bool get isQualified;

  /**
   * Set the element associated with this identifier based on propagated type
   * information to the given [element].
   */
  void set propagatedElement(Element element);

  /**
   * Set the element associated with this identifier based on static type
   * information to the given [element].
   */
  void set staticElement(Element element);

  /**
   * Return the token representing the identifier.
   */
  Token get token;

  /**
   * Set the token representing the identifier to the given [token].
   */
  void set token(Token token);

  /**
   * Return `true` if this identifier is the name being declared in a
   * declaration.
   */
  // TODO(brianwilkerson) Convert this to a getter.
  bool inDeclarationContext();

  /**
   * Return `true` if this expression is computing a right-hand value.
   *
   * Note that [inGetterContext] and [inSetterContext] are not opposites, nor
   * are they mutually exclusive. In other words, it is possible for both
   * methods to return `true` when invoked on the same node.
   */
  // TODO(brianwilkerson) Convert this to a getter.
  bool inGetterContext();

  /**
   * Return `true` if this expression is computing a left-hand value.
   *
   * Note that [inGetterContext] and [inSetterContext] are not opposites, nor
   * are they mutually exclusive. In other words, it is possible for both
   * methods to return `true` when invoked on the same node.
   */
  // TODO(brianwilkerson) Convert this to a getter.
  bool inSetterContext();
}

/**
 * A string literal expression that does not contain any interpolations.
 *
 *    simpleStringLiteral ::=
 *        rawStringLiteral
 *      | basicStringLiteral
 *
 *    rawStringLiteral ::=
 *        'r' basicStringLiteral
 *
 *    simpleStringLiteral ::=
 *        multiLineStringLiteral
 *      | singleLineStringLiteral
 *
 *    multiLineStringLiteral ::=
 *        "'''" characters "'''"
 *      | '"""' characters '"""'
 *
 *    singleLineStringLiteral ::=
 *        "'" characters "'"
 *      | '"' characters '"'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class SimpleStringLiteral extends SingleStringLiteral {
  /**
   * Initialize a newly created simple string literal.
   */
  factory SimpleStringLiteral(Token literal, String value) =
      SimpleStringLiteralImpl;

  /**
   * Return the token representing the literal.
   */
  Token get literal;

  /**
   * Set the token representing the literal to the given [token].
   */
  void set literal(Token token);

  /**
   * Return the value of the literal.
   */
  String get value;

  /**
   * Set the value of the literal to the given [string].
   */
  void set value(String string);
}

/**
 * A single string literal expression.
 *
 *    singleStringLiteral ::=
 *        [SimpleStringLiteral]
 *      | [StringInterpolation]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class SingleStringLiteral extends StringLiteral {
  /**
   * Return the offset of the after-last contents character.
   */
  int get contentsEnd;

  /**
   * Return the offset of the first contents character.
   * If the string is multiline, then leading whitespaces are skipped.
   */
  int get contentsOffset;

  /**
   * Return `true` if this string literal is a multi-line string.
   */
  bool get isMultiline;

  /**
   * Return `true` if this string literal is a raw string.
   */
  bool get isRaw;

  /**
   * Return `true` if this string literal uses single quotes (' or ''').
   * Return `false` if this string literal uses double quotes (" or """).
   */
  bool get isSingleQuoted;
}

/**
 * A node that represents a statement.
 *
 *    statement ::=
 *        [Block]
 *      | [VariableDeclarationStatement]
 *      | [ForStatement]
 *      | [ForEachStatement]
 *      | [WhileStatement]
 *      | [DoStatement]
 *      | [SwitchStatement]
 *      | [IfStatement]
 *      | [TryStatement]
 *      | [BreakStatement]
 *      | [ContinueStatement]
 *      | [ReturnStatement]
 *      | [ExpressionStatement]
 *      | [FunctionDeclarationStatement]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class Statement extends AstNode {
  /**
   * If this is a labeled statement, return the unlabeled portion of the
   * statement, otherwise return the statement itself.
   */
  Statement get unlabeled;
}

/**
 * A string interpolation literal.
 *
 *    stringInterpolation ::=
 *        ''' [InterpolationElement]* '''
 *      | '"' [InterpolationElement]* '"'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class StringInterpolation extends SingleStringLiteral {
  /**
   * Initialize a newly created string interpolation expression.
   */
  factory StringInterpolation(List<InterpolationElement> elements) =
      StringInterpolationImpl;

  /**
   * Return the elements that will be composed to produce the resulting string.
   */
  NodeList<InterpolationElement> get elements;
}

/**
 * A string literal expression.
 *
 *    stringLiteral ::=
 *        [SimpleStringLiteral]
 *      | [AdjacentStrings]
 *      | [StringInterpolation]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class StringLiteral extends Literal {
  /**
   * Return the value of the string literal, or `null` if the string is not a
   * constant string without any string interpolation.
   */
  String get stringValue;
}

/**
 * The invocation of a superclass' constructor from within a constructor's
 * initialization list.
 *
 *    superInvocation ::=
 *        'super' ('.' [SimpleIdentifier])? [ArgumentList]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class SuperConstructorInvocation extends ConstructorInitializer {
  /**
   * Initialize a newly created super invocation to invoke the inherited
   * constructor with the given name with the given arguments. The [period] and
   * [constructorName] can be `null` if the constructor being invoked is the
   * unnamed constructor.
   */
  factory SuperConstructorInvocation(Token superKeyword, Token period,
          SimpleIdentifier constructorName, ArgumentList argumentList) =>
      new SuperConstructorInvocationImpl(
          superKeyword, period, constructorName, argumentList);

  /**
   * Return the list of arguments to the constructor.
   */
  ArgumentList get argumentList;

  /**
   * Set the list of arguments to the constructor to the given [argumentList].
   */
  void set argumentList(ArgumentList argumentList);

  /**
   * Return the name of the constructor that is being invoked, or `null` if the
   * unnamed constructor is being invoked.
   */
  SimpleIdentifier get constructorName;

  /**
   * Set the name of the constructor that is being invoked to the given
   * [identifier].
   */
  void set constructorName(SimpleIdentifier identifier);

  /**
   * Return the token for the period before the name of the constructor that is
   * being invoked, or `null` if the unnamed constructor is being invoked.
   */
  Token get period;

  /**
   * Set the token for the period before the name of the constructor that is
   * being invoked to the given [token].
   */
  void set period(Token token);

  /**
   * Return the element associated with the constructor based on static type
   * information, or `null` if the AST structure has not been resolved or if the
   * constructor could not be resolved.
   */
  ConstructorElement get staticElement;

  /**
   * Set the element associated with the constructor based on static type
   * information to the given [element].
   */
  void set staticElement(ConstructorElement element);

  /**
   * Return the token for the 'super' keyword.
   */
  Token get superKeyword;

  /**
   * Set the token for the 'super' keyword to the given [token].
   */
  void set superKeyword(Token token);
}

/**
 * A super expression.
 *
 *    superExpression ::=
 *        'super'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class SuperExpression extends Expression {
  /**
   * Initialize a newly created super expression.
   */
  factory SuperExpression(Token superKeyword) = SuperExpressionImpl;

  /**
   * Return the token representing the 'super' keyword.
   */
  Token get superKeyword;

  /**
   * Set the token representing the 'super' keyword to the given [token].
   */
  void set superKeyword(Token token);
}

/**
 * A case in a switch statement.
 *
 *    switchCase ::=
 *        [SimpleIdentifier]* 'case' [Expression] ':' [Statement]*
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class SwitchCase extends SwitchMember {
  /**
   * Initialize a newly created switch case. The list of [labels] can be `null`
   * if there are no labels.
   */
  factory SwitchCase(List<Label> labels, Token keyword, Expression expression,
          Token colon, List<Statement> statements) =>
      new SwitchCaseImpl(labels, keyword, expression, colon, statements);

  /**
   * Return the expression controlling whether the statements will be executed.
   */
  Expression get expression;

  /**
   * Set the expression controlling whether the statements will be executed to
   * the given [expression].
   */
  void set expression(Expression expression);
}

/**
 * The default case in a switch statement.
 *
 *    switchDefault ::=
 *        [SimpleIdentifier]* 'default' ':' [Statement]*
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class SwitchDefault extends SwitchMember {
  /**
   * Initialize a newly created switch default. The list of [labels] can be
   * `null` if there are no labels.
   */
  factory SwitchDefault(List<Label> labels, Token keyword, Token colon,
      List<Statement> statements) = SwitchDefaultImpl;
}

/**
 * An element within a switch statement.
 *
 *    switchMember ::=
 *        switchCase
 *      | switchDefault
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class SwitchMember extends AstNode {
  /**
   * Return the colon separating the keyword or the expression from the
   * statements.
   */
  Token get colon;

  /**
   * Set the colon separating the keyword or the expression from the
   * statements to the given [token].
   */
  void set colon(Token token);

  /**
   * Return the token representing the 'case' or 'default' keyword.
   */
  Token get keyword;

  /**
   * Set the token representing the 'case' or 'default' keyword to the given
   * [token].
   */
  void set keyword(Token token);

  /**
   * Return the labels associated with the switch member.
   */
  NodeList<Label> get labels;

  /**
   * Return the statements that will be executed if this switch member is
   * selected.
   */
  NodeList<Statement> get statements;
}

/**
 * A switch statement.
 *
 *    switchStatement ::=
 *        'switch' '(' [Expression] ')' '{' [SwitchCase]* [SwitchDefault]? '}'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class SwitchStatement extends Statement {
  /**
   * Initialize a newly created switch statement. The list of [members] can be
   * `null` if there are no switch members.
   */
  factory SwitchStatement(
          Token switchKeyword,
          Token leftParenthesis,
          Expression expression,
          Token rightParenthesis,
          Token leftBracket,
          List<SwitchMember> members,
          Token rightBracket) =>
      new SwitchStatementImpl(switchKeyword, leftParenthesis, expression,
          rightParenthesis, leftBracket, members, rightBracket);

  /**
   * Return the expression used to determine which of the switch members will be
   * selected.
   */
  Expression get expression;

  /**
   * Set the expression used to determine which of the switch members will be
   * selected to the given [expression].
   */
  void set expression(Expression expression);

  /**
   * Return the left curly bracket.
   */
  Token get leftBracket;

  /**
   * Set the left curly bracket to the given [token].
   */
  void set leftBracket(Token token);

  /**
   * Return the left parenthesis.
   */
  Token get leftParenthesis;

  /**
   * Set the left parenthesis to the given [token].
   */
  void set leftParenthesis(Token token);

  /**
   * Return the switch members that can be selected by the expression.
   */
  NodeList<SwitchMember> get members;

  /**
   * Return the right curly bracket.
   */
  Token get rightBracket;

  /**
   * Set the right curly bracket to the given [token].
   */
  void set rightBracket(Token token);

  /**
   * Return the right parenthesis.
   */
  Token get rightParenthesis;

  /**
   * Set the right parenthesis to the given [token].
   */
  void set rightParenthesis(Token token);

  /**
   * Return the token representing the 'switch' keyword.
   */
  Token get switchKeyword;

  /**
   * Set the token representing the 'switch' keyword to the given [token].
   */
  void set switchKeyword(Token token);
}

/**
 * A symbol literal expression.
 *
 *    symbolLiteral ::=
 *        '#' (operator | (identifier ('.' identifier)*))
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class SymbolLiteral extends Literal {
  /**
   * Initialize a newly created symbol literal.
   */
  factory SymbolLiteral(Token poundSign, List<Token> components) =
      SymbolLiteralImpl;

  /**
   * Return the components of the literal.
   */
  List<Token> get components;

  /**
   * Return the token introducing the literal.
   */
  Token get poundSign;

  /**
   * Set the token introducing the literal to the given [token].
   */
  void set poundSign(Token token);
}

/**
 * A this expression.
 *
 *    thisExpression ::=
 *        'this'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ThisExpression extends Expression {
  /**
   * Initialize a newly created this expression.
   */
  factory ThisExpression(Token thisKeyword) = ThisExpressionImpl;

  /**
   * Return the token representing the 'this' keyword.
   */
  Token get thisKeyword;

  /**
   * Set the token representing the 'this' keyword to the given [token].
   */
  void set thisKeyword(Token token);
}

/**
 * A throw expression.
 *
 *    throwExpression ::=
 *        'throw' [Expression]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class ThrowExpression extends Expression {
  /**
   * Initialize a newly created throw expression.
   */
  factory ThrowExpression(Token throwKeyword, Expression expression) =>
      new ThrowExpressionImpl(throwKeyword, expression);

  /**
   * Return the expression computing the exception to be thrown.
   */
  Expression get expression;

  /**
   * Set the expression computing the exception to be thrown to the given
   * [expression].
   */
  void set expression(Expression expression);

  /**
   * Return the token representing the 'throw' keyword.
   */
  Token get throwKeyword;

  /**
   * Set the token representing the 'throw' keyword to the given [token].
   */
  void set throwKeyword(Token token);
}

/**
 * The declaration of one or more top-level variables of the same type.
 *
 *    topLevelVariableDeclaration ::=
 *        ('final' | 'const') type? staticFinalDeclarationList ';'
 *      | variableDeclaration ';'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class TopLevelVariableDeclaration extends CompilationUnitMember {
  /**
   * Initialize a newly created top-level variable declaration. Either or both
   * of the [comment] and [metadata] can be `null` if the variable does not have
   * the corresponding attribute.
   */
  factory TopLevelVariableDeclaration(
          Comment comment,
          List<Annotation> metadata,
          VariableDeclarationList variableList,
          Token semicolon) =>
      new TopLevelVariableDeclarationImpl(
          comment, metadata, variableList, semicolon);

  /**
   * Return the semicolon terminating the declaration.
   */
  Token get semicolon;

  /**
   * Set the semicolon terminating the declaration to the given [token].
   */
  void set semicolon(Token token);

  /**
   * Return the top-level variables being declared.
   */
  VariableDeclarationList get variables;

  /**
   * Set the top-level variables being declared to the given list of
   * [variables].
   */
  void set variables(VariableDeclarationList variables);
}

/**
 * A try statement.
 *
 *    tryStatement ::=
 *        'try' [Block] ([CatchClause]+ finallyClause? | finallyClause)
 *
 *    finallyClause ::=
 *        'finally' [Block]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class TryStatement extends Statement {
  /**
   * Initialize a newly created try statement. The list of [catchClauses] can be
   * `null` if there are no catch clauses. The [finallyKeyword] and
   * [finallyBlock] can be `null` if there is no finally clause.
   */
  factory TryStatement(
          Token tryKeyword,
          Block body,
          List<CatchClause> catchClauses,
          Token finallyKeyword,
          Block finallyBlock) =>
      new TryStatementImpl(
          tryKeyword, body, catchClauses, finallyKeyword, finallyBlock);

  /**
   * Return the body of the statement.
   */
  Block get body;

  /**
   * Set the body of the statement to the given [block].
   */
  void set body(Block block);

  /**
   * Return the catch clauses contained in the try statement.
   */
  NodeList<CatchClause> get catchClauses;

  /**
   * Return the finally block contained in the try statement, or `null` if the
   * statement does not contain a finally clause.
   */
  Block get finallyBlock;

  /**
   * Set the finally block contained in the try statement to the given [block].
   */
  void set finallyBlock(Block block);

  /**
   * Return the token representing the 'finally' keyword, or `null` if the
   * statement does not contain a finally clause.
   */
  Token get finallyKeyword;

  /**
   * Set the token representing the 'finally' keyword to the given [token].
   */
  void set finallyKeyword(Token token);

  /**
   * Return the token representing the 'try' keyword.
   */
  Token get tryKeyword;

  /**
   * Set the token representing the 'try' keyword to the given [token].
   */
  void set tryKeyword(Token token);
}

/**
 * The declaration of a type alias.
 *
 *    typeAlias ::=
 *        'typedef' typeAliasBody
 *
 *    typeAliasBody ::=
 *        classTypeAlias
 *      | functionTypeAlias
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class TypeAlias extends NamedCompilationUnitMember {
  /**
   * Return the semicolon terminating the declaration.
   */
  Token get semicolon;

  /**
   * Set the semicolon terminating the declaration to the given [token].
   */
  void set semicolon(Token token);

  /**
   * Return the token representing the 'typedef' keyword.
   */
  Token get typedefKeyword;

  /**
   * Set the token representing the 'typedef' keyword to the given [token].
   */
  void set typedefKeyword(Token token);
}

/**
 * A list of type arguments.
 *
 *    typeArguments ::=
 *        '<' typeName (',' typeName)* '>'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class TypeArgumentList extends AstNode {
  /**
   * Initialize a newly created list of type arguments.
   */
  factory TypeArgumentList(
          Token leftBracket, List<TypeName> arguments, Token rightBracket) =
      TypeArgumentListImpl;

  /**
   * Return the type arguments associated with the type.
   */
  NodeList<TypeName> get arguments;

  /**
   * Return the left bracket.
   */
  Token get leftBracket;

  /**
   * Set the left bracket to the given [token].
   */
  void set leftBracket(Token token);

  /**
   * Return the right bracket.
   */
  Token get rightBracket;

  /**
   * Set the right bracket to the given [token].
   */
  void set rightBracket(Token token);
}

/**
 * A literal that has a type associated with it.
 *
 *    typedLiteral ::=
 *        [ListLiteral]
 *      | [MapLiteral]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class TypedLiteral extends Literal {
  /**
   * Return the token representing the 'const' keyword, or `null` if the literal
   * is not a constant.
   */
  Token get constKeyword;

  /**
   * Set the token representing the 'const' keyword to the given [token].
   */
  void set constKeyword(Token token);

  /**
   * Return the type argument associated with this literal, or `null` if no type
   * arguments were declared.
   */
  TypeArgumentList get typeArguments;

  /**
   * Set the type argument associated with this literal to the given
   * [typeArguments].
   */
  void set typeArguments(TypeArgumentList typeArguments);
}

/**
 * The name of a type, which can optionally include type arguments.
 *
 *    typeName ::=
 *        [Identifier] typeArguments?
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class TypeName extends AstNode {
  /**
   * Initialize a newly created type name. The [typeArguments] can be `null` if
   * there are no type arguments.
   */
  factory TypeName(Identifier name, TypeArgumentList typeArguments) =>
      new TypeNameImpl(name, typeArguments);

  /**
   * Return `true` if this type is a deferred type.
   *
   * 15.1 Static Types: A type <i>T</i> is deferred iff it is of the form
   * </i>p.T</i> where <i>p</i> is a deferred prefix.
   */
  bool get isDeferred;

  /**
   * Return the name of the type.
   */
  Identifier get name;

  /**
   * Set the name of the type to the given [identifier].
   */
  void set name(Identifier identifier);

  /**
   * Return the type being named, or `null` if the AST structure has not been
   * resolved.
   */
  DartType get type;

  /**
   * Set the type being named to the given [type].
   */
  void set type(DartType type);

  /**
   * Return the type arguments associated with the type, or `null` if there are
   * no type arguments.
   */
  TypeArgumentList get typeArguments;

  /**
   * Set the type arguments associated with the type to the given
   * [typeArguments].
   */
  void set typeArguments(TypeArgumentList typeArguments);
}

/**
 * A type parameter.
 *
 *    typeParameter ::=
 *        [SimpleIdentifier] ('extends' [TypeName])?
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class TypeParameter extends Declaration {
  /**
   * Initialize a newly created type parameter. Either or both of the [comment]
   * and [metadata] can be `null` if the parameter does not have the
   * corresponding attribute. The [extendsKeyword] and [bound] can be `null` if
   * the parameter does not have an upper bound.
   */
  factory TypeParameter(Comment comment, List<Annotation> metadata,
          SimpleIdentifier name, Token extendsKeyword, TypeName bound) =>
      new TypeParameterImpl(comment, metadata, name, extendsKeyword, bound);

  /**
   * Return the name of the upper bound for legal arguments, or `null` if there
   * is no explicit upper bound.
   */
  TypeName get bound;

  /**
   * Set the name of the upper bound for legal arguments to the given
   * [typeName].
   */
  void set bound(TypeName typeName);

  /**
   * Return the token representing the 'extends' keyword, or `null` if there is
   * no explicit upper bound.
   */
  Token get extendsKeyword;

  /**
   * Set the token representing the 'extends' keyword to the given [token].
   */
  void set extendsKeyword(Token token);

  /**
   * Return the name of the type parameter.
   */
  SimpleIdentifier get name;

  /**
   * Set the name of the type parameter to the given [identifier].
   */
  void set name(SimpleIdentifier identifier);
}

/**
 * Type parameters within a declaration.
 *
 *    typeParameterList ::=
 *        '<' [TypeParameter] (',' [TypeParameter])* '>'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class TypeParameterList extends AstNode {
  /**
   * Initialize a newly created list of type parameters.
   */
  factory TypeParameterList(
      Token leftBracket,
      List<TypeParameter> typeParameters,
      Token rightBracket) = TypeParameterListImpl;

  /**
   * Return the left angle bracket.
   */
  Token get leftBracket;

  /**
   * Return the right angle bracket.
   */
  Token get rightBracket;

  /**
   * Return the type parameters for the type.
   */
  NodeList<TypeParameter> get typeParameters;
}

/**
 * A directive that references a URI.
 *
 *    uriBasedDirective ::=
 *        [ExportDirective]
 *      | [ImportDirective]
 *      | [PartDirective]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class UriBasedDirective extends Directive {
  /**
   * Return the source to which the URI was resolved.
   */
  Source get source;

  /**
   * Set the source to which the URI was resolved to the given [source].
   */
  void set source(Source source);

  /**
   * Return the URI referenced by this directive.
   */
  StringLiteral get uri;

  /**
   * Set the URI referenced by this directive to the given [uri].
   */
  void set uri(StringLiteral uri);

  /**
   * Return the content of the URI.
   */
  String get uriContent;

  /**
   * Set the content of the URI to the given [content].
   */
  void set uriContent(String content);

  /**
   * Return the element associated with the URI of this directive, or `null` if
   * the AST structure has not been resolved or if the URI could not be
   * resolved. Examples of the latter case include a directive that contains an
   * invalid URL or a URL that does not exist.
   */
  Element get uriElement;

  /**
   * Validate this directive, but do not check for existence. Return a code
   * indicating the problem if there is one, or `null` no problem
   */
  UriValidationCode validate();
}

/**
 * Validation codes returned by [UriBasedDirective.validate].
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class UriValidationCode {
  static const UriValidationCode INVALID_URI =
      UriValidationCodeImpl.INVALID_URI;

  static const UriValidationCode URI_WITH_INTERPOLATION =
      UriValidationCodeImpl.URI_WITH_INTERPOLATION;

  static const UriValidationCode URI_WITH_DART_EXT_SCHEME =
      UriValidationCodeImpl.URI_WITH_DART_EXT_SCHEME;
}

/**
 * An identifier that has an initial value associated with it. Instances of this
 * class are always children of the class [VariableDeclarationList].
 *
 *    variableDeclaration ::=
 *        [SimpleIdentifier] ('=' [Expression])?
 *
 * TODO(paulberry): the grammar does not allow metadata to be associated with
 * a VariableDeclaration, and currently we don't record comments for it either.
 * Consider changing the class hierarchy so that [VariableDeclaration] does not
 * extend [Declaration].
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class VariableDeclaration extends Declaration {
  /**
   * Initialize a newly created variable declaration. The [equals] and
   * [initializer] can be `null` if there is no initializer.
   */
  factory VariableDeclaration(
          SimpleIdentifier name, Token equals, Expression initializer) =>
      new VariableDeclarationImpl(name, equals, initializer);

  @override
  VariableElement get element;

  /**
   * Return the equal sign separating the variable name from the initial value,
   * or `null` if the initial value was not specified.
   */
  Token get equals;

  /**
   * Set the equal sign separating the variable name from the initial value to
   * the given [token].
   */
  void set equals(Token token);

  /**
   * Return the expression used to compute the initial value for the variable,
   * or `null` if the initial value was not specified.
   */
  Expression get initializer;

  /**
   * Set the expression used to compute the initial value for the variable to
   * the given [expression].
   */
  void set initializer(Expression expression);

  /**
   * Return `true` if this variable was declared with the 'const' modifier.
   */
  bool get isConst;

  /**
   * Return `true` if this variable was declared with the 'final' modifier.
   * Variables that are declared with the 'const' modifier will return `false`
   * even though they are implicitly final.
   */
  bool get isFinal;

  /**
   * Return the name of the variable being declared.
   */
  SimpleIdentifier get name;

  /**
   * Set the name of the variable being declared to the given [identifier].
   */
  void set name(SimpleIdentifier identifier);
}

/**
 * The declaration of one or more variables of the same type.
 *
 *    variableDeclarationList ::=
 *        finalConstVarOrType [VariableDeclaration] (',' [VariableDeclaration])*
 *
 *    finalConstVarOrType ::=
 *      | 'final' [TypeName]?
 *      | 'const' [TypeName]?
 *      | 'var'
 *      | [TypeName]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class VariableDeclarationList extends AnnotatedNode {
  /**
   * Initialize a newly created variable declaration list. Either or both of the
   * [comment] and [metadata] can be `null` if the variable list does not have
   * the corresponding attribute. The [keyword] can be `null` if a type was
   * specified. The [type] must be `null` if the keyword is 'var'.
   */
  factory VariableDeclarationList(Comment comment, List<Annotation> metadata,
          Token keyword, TypeName type, List<VariableDeclaration> variables) =>
      new VariableDeclarationListImpl(
          comment, metadata, keyword, type, variables);

  /**
   * Return `true` if the variables in this list were declared with the 'const'
   * modifier.
   */
  bool get isConst;

  /**
   * Return `true` if the variables in this list were declared with the 'final'
   * modifier. Variables that are declared with the 'const' modifier will return
   * `false` even though they are implicitly final. (In other words, this is a
   * syntactic check rather than a semantic check.)
   */
  bool get isFinal;

  /**
   * Return the token representing the 'final', 'const' or 'var' keyword, or
   * `null` if no keyword was included.
   */
  Token get keyword;

  /**
   * Set the token representing the 'final', 'const' or 'var' keyword to the
   * given [token].
   */
  void set keyword(Token token);

  /**
   * Return the type of the variables being declared, or `null` if no type was
   * provided.
   */
  TypeName get type;

  /**
   * Set the type of the variables being declared to the given [typeName].
   */
  void set type(TypeName typeName);

  /**
   * Return a list containing the individual variables being declared.
   */
  NodeList<VariableDeclaration> get variables;
}

/**
 * A list of variables that are being declared in a context where a statement is
 * required.
 *
 *    variableDeclarationStatement ::=
 *        [VariableDeclarationList] ';'
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class VariableDeclarationStatement extends Statement {
  /**
   * Initialize a newly created variable declaration statement.
   */
  factory VariableDeclarationStatement(
          VariableDeclarationList variableList, Token semicolon) =>
      new VariableDeclarationStatementImpl(variableList, semicolon);

  /**
   * Return the semicolon terminating the statement.
   */
  Token get semicolon;

  /**
   * Set the semicolon terminating the statement to the given [token].
   */
  void set semicolon(Token token);

  /**
   * Return the variables being declared.
   */
  VariableDeclarationList get variables;

  /**
   * Set the variables being declared to the given list of [variables].
   */
  void set variables(VariableDeclarationList variables);
}

/**
 * A while statement.
 *
 *    whileStatement ::=
 *        'while' '(' [Expression] ')' [Statement]
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class WhileStatement extends Statement {
  /**
   * Initialize a newly created while statement.
   */
  factory WhileStatement(Token whileKeyword, Token leftParenthesis,
          Expression condition, Token rightParenthesis, Statement body) =>
      new WhileStatementImpl(
          whileKeyword, leftParenthesis, condition, rightParenthesis, body);

  /**
   * Return the body of the loop.
   */
  Statement get body;

  /**
   * Set the body of the loop to the given [statement].
   */
  void set body(Statement statement);

  /**
   * Return the expression used to determine whether to execute the body of the
   * loop.
   */
  Expression get condition;

  /**
   * Set the expression used to determine whether to execute the body of the
   * loop to the given [expression].
   */
  void set condition(Expression expression);

  /**
   * Return the left parenthesis.
   */
  Token get leftParenthesis;

  /**
   * Set the left parenthesis to the given [token].
   */
  void set leftParenthesis(Token token);

  /**
   * Return the right parenthesis.
   */
  Token get rightParenthesis;

  /**
   * Set the right parenthesis to the given [token].
   */
  void set rightParenthesis(Token token);

  /**
   * Return the token representing the 'while' keyword.
   */
  Token get whileKeyword;

  /**
   * Set the token representing the 'while' keyword to the given [token].
   */
  void set whileKeyword(Token token);
}

/**
 * The with clause in a class declaration.
 *
 *    withClause ::=
 *        'with' [TypeName] (',' [TypeName])*
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class WithClause extends AstNode {
  /**
   * Initialize a newly created with clause.
   */
  factory WithClause(Token withKeyword, List<TypeName> mixinTypes) =
      WithClauseImpl;

  /**
   * Return the names of the mixins that were specified.
   */
  NodeList<TypeName> get mixinTypes;

  /**
   * Return the token representing the 'with' keyword.
   */
  Token get withKeyword;

  /**
   * Set the token representing the 'with' keyword to the given [token].
   */
  void set withKeyword(Token token);
}

/**
 * A yield statement.
 *
 *    yieldStatement ::=
 *        'yield' '*'? [Expression] ‘;’
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class YieldStatement extends Statement {
  /**
   * Initialize a newly created yield expression. The [star] can be `null` if no
   * star was provided.
   */
  factory YieldStatement(Token yieldKeyword, Token star, Expression expression,
          Token semicolon) =>
      new YieldStatementImpl(yieldKeyword, star, expression, semicolon);

  /**
   * Return the expression whose value will be yielded.
   */
  Expression get expression;

  /**
   * Set the expression whose value will be yielded to the given [expression].
   */
  void set expression(Expression expression);

  /**
   * Return the semicolon following the expression.
   */
  Token get semicolon;

  /**
   * Return the semicolon following the expression to the given [token].
   */
  void set semicolon(Token token);

  /**
   * Return the star optionally following the 'yield' keyword.
   */
  Token get star;

  /**
   * Return the star optionally following the 'yield' keyword to the given [token].
   */
  void set star(Token token);

  /**
   * Return the 'yield' keyword.
   */
  Token get yieldKeyword;

  /**
   * Return the 'yield' keyword to the given [token].
   */
  void set yieldKeyword(Token token);
}
