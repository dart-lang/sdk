// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.
library engine.ast;
import 'dart:collection';
import 'java_core.dart';
import 'java_engine.dart';
import 'error.dart';
import 'source.dart' show LineInfo;
import 'scanner.dart';
import 'engine.dart' show AnalysisEngine;
import 'utilities_dart.dart';
import 'element.dart';
/**
 * The abstract class {@code ASTNode} defines the behavior common to all nodes in the AST structure
 * for a Dart program.
 * @coverage dart.engine.ast
 */
abstract class ASTNode {

  /**
   * The parent of the node, or {@code null} if the node is the root of an AST structure.
   */
  ASTNode _parent;

  /**
   * A table mapping the names of properties to their values, or {@code null} if this node does not
   * have any properties associated with it.
   */
  Map<String, Object> _propertyMap;

  /**
   * A comparator that can be used to sort AST nodes in lexical order. In other words,{@code compare} will return a negative value if the offset of the first node is less than the
   * offset of the second node, zero (0) if the nodes have the same offset, and a positive value if
   * if the offset of the first node is greater than the offset of the second node.
   */
  static Comparator<ASTNode> LEXICAL_ORDER = (ASTNode first, ASTNode second) => second.offset - first.offset;

  /**
   * Use the given visitor to visit this node.
   * @param visitor the visitor that will visit this node
   * @return the value returned by the visitor as a result of visiting this node
   */
  accept(ASTVisitor visitor);

  /**
   * @return the {@link ASTNode} of given {@link Class} which is {@link ASTNode} itself, or one of
   * its parents.
   */
  ASTNode getAncestor(Type enclosingClass) {
    ASTNode node = this;
    while (node != null && !isInstanceOf(node, enclosingClass)) {
      node = node.parent;
    }
    ;
    return node as ASTNode;
  }

  /**
   * Return the first token included in this node's source range.
   * @return the first token included in this node's source range
   */
  Token get beginToken;

  /**
   * Return the offset of the character immediately following the last character of this node's
   * source range. This is equivalent to {@code node.getOffset() + node.getLength()}. For a
   * compilation unit this will be equal to the length of the unit's source. For synthetic nodes
   * this will be equivalent to the node's offset (because the length is zero (0) by definition).
   * @return the offset of the character just past the node's source range
   */
  int get end => offset + length;

  /**
   * Return the last token included in this node's source range.
   * @return the last token included in this node's source range
   */
  Token get endToken;

  /**
   * Return the number of characters in the node's source range.
   * @return the number of characters in the node's source range
   */
  int get length {
    Token beginToken = this.beginToken;
    Token endToken = this.endToken;
    if (beginToken == null || endToken == null) {
      return -1;
    }
    return endToken.offset + endToken.length - beginToken.offset;
  }

  /**
   * Return the offset from the beginning of the file to the first character in the node's source
   * range.
   * @return the offset from the beginning of the file to the first character in the node's source
   * range
   */
  int get offset {
    Token beginToken = this.beginToken;
    if (beginToken == null) {
      return -1;
    }
    return beginToken.offset;
  }

  /**
   * Return this node's parent node, or {@code null} if this node is the root of an AST structure.
   * <p>
   * Note that the relationship between an AST node and its parent node may change over the lifetime
   * of a node.
   * @return the parent of this node, or {@code null} if none
   */
  ASTNode get parent => _parent;

  /**
   * Return the value of the property with the given name, or {@code null} if this node does not
   * have a property with the given name.
   * @return the value of the property with the given name
   */
  Object getProperty(String propertyName) {
    if (_propertyMap == null) {
      return null;
    }
    return _propertyMap[propertyName];
  }

  /**
   * Return the node at the root of this node's AST structure. Note that this method's performance
   * is linear with respect to the depth of the node in the AST structure (O(depth)).
   * @return the node at the root of this node's AST structure
   */
  ASTNode get root {
    ASTNode root = this;
    ASTNode parent = this.parent;
    while (parent != null) {
      root = parent;
      parent = root.parent;
    }
    return root;
  }

  /**
   * Return {@code true} if this node is a synthetic node. A synthetic node is a node that was
   * introduced by the parser in order to recover from an error in the code. Synthetic nodes always
   * have a length of zero ({@code 0}).
   * @return {@code true} if this node is a synthetic node
   */
  bool isSynthetic() => false;

  /**
   * Set the value of the property with the given name to the given value. If the value is{@code null}, the property will effectively be removed.
   * @param propertyName the name of the property whose value is to be set
   * @param propertyValue the new value of the property
   */
  void setProperty(String propertyName, Object propertyValue) {
    if (propertyValue == null) {
      if (_propertyMap != null) {
        _propertyMap.remove(propertyName);
        if (_propertyMap.isEmpty) {
          _propertyMap = null;
        }
      }
    } else {
      if (_propertyMap == null) {
        _propertyMap = new Map<String, Object>();
      }
      _propertyMap[propertyName] = propertyValue;
    }
  }

  /**
   * Return a textual description of this node in a form approximating valid source. The returned
   * string will not be valid source primarily in the case where the node itself is not well-formed.
   * @return the source code equivalent of this node
   */
  String toSource() {
    PrintStringWriter writer = new PrintStringWriter();
    accept(new ToSourceVisitor(writer));
    return writer.toString();
  }
  String toString() => toSource();

  /**
   * Use the given visitor to visit all of the children of this node. The children will be visited
   * in source order.
   * @param visitor the visitor that will be used to visit the children of this node
   */
  void visitChildren(ASTVisitor<Object> visitor);

  /**
   * Make this node the parent of the given child node.
   * @param child the node that will become a child of this node
   * @return the node that was made a child of this node
   */
  ASTNode becomeParentOf(ASTNode child) {
    if (child != null) {
      ASTNode node = child;
      node.parent = this;
    }
    return child;
  }

  /**
   * If the given child is not {@code null}, use the given visitor to visit it.
   * @param child the child to be visited
   * @param visitor the visitor that will be used to visit the child
   */
  void safelyVisitChild(ASTNode child, ASTVisitor<Object> visitor) {
    if (child != null) {
      child.accept(visitor);
    }
  }

  /**
   * Set the parent of this node to the given node.
   * @param newParent the node that is to be made the parent of this node
   */
  void set parent(ASTNode newParent) {
    _parent = newParent;
  }
  static int _hashCodeGenerator = 0;
  final int hashCode = ++_hashCodeGenerator;
}
/**
 * The interface {@code ASTVisitor} defines the behavior of objects that can be used to visit an AST
 * structure.
 * @coverage dart.engine.ast
 */
abstract class ASTVisitor<R> {
  R visitAdjacentStrings(AdjacentStrings node);
  R visitAnnotation(Annotation node);
  R visitArgumentDefinitionTest(ArgumentDefinitionTest node);
  R visitArgumentList(ArgumentList node);
  R visitAsExpression(AsExpression node);
  R visitAssertStatement(AssertStatement assertStatement);
  R visitAssignmentExpression(AssignmentExpression node);
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
  R visitConstructorDeclaration(ConstructorDeclaration node);
  R visitConstructorFieldInitializer(ConstructorFieldInitializer node);
  R visitConstructorName(ConstructorName node);
  R visitContinueStatement(ContinueStatement node);
  R visitDeclaredIdentifier(DeclaredIdentifier node);
  R visitDefaultFormalParameter(DefaultFormalParameter node);
  R visitDoStatement(DoStatement node);
  R visitDoubleLiteral(DoubleLiteral node);
  R visitEmptyFunctionBody(EmptyFunctionBody node);
  R visitEmptyStatement(EmptyStatement node);
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
  R visitNativeFunctionBody(NativeFunctionBody node);
  R visitNullLiteral(NullLiteral node);
  R visitParenthesizedExpression(ParenthesizedExpression node);
  R visitPartDirective(PartDirective node);
  R visitPartOfDirective(PartOfDirective node);
  R visitPostfixExpression(PostfixExpression node);
  R visitPrefixedIdentifier(PrefixedIdentifier node);
  R visitPrefixExpression(PrefixExpression node);
  R visitPropertyAccess(PropertyAccess node);
  R visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node);
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
}
/**
 * Instances of the class {@code AdjacentStrings} represents two or more string literals that are
 * implicitly concatenated because of being adjacent (separated only by whitespace).
 * <p>
 * While the grammar only allows adjacent strings when all of the strings are of the same kind
 * (single line or multi-line), this class doesn't enforce that restriction.
 * <pre>
 * adjacentStrings ::={@link StringLiteral string} {@link StringLiteral string}+
 * </pre>
 * @coverage dart.engine.ast
 */
class AdjacentStrings extends StringLiteral {

  /**
   * The strings that are implicitly concatenated.
   */
  NodeList<StringLiteral> _strings;

  /**
   * Initialize a newly created list of adjacent strings.
   * @param strings the strings that are implicitly concatenated
   */
  AdjacentStrings.full(List<StringLiteral> strings) {
    this._strings = new NodeList<StringLiteral>(this);
    this._strings.addAll(strings);
  }

  /**
   * Initialize a newly created list of adjacent strings.
   * @param strings the strings that are implicitly concatenated
   */
  AdjacentStrings({List<StringLiteral> strings}) : this.full(strings);
  accept(ASTVisitor visitor) => visitor.visitAdjacentStrings(this);
  Token get beginToken => _strings.beginToken;
  Token get endToken => _strings.endToken;

  /**
   * Return the strings that are implicitly concatenated.
   * @return the strings that are implicitly concatenated
   */
  NodeList<StringLiteral> get strings => _strings;
  void visitChildren(ASTVisitor<Object> visitor) {
    _strings.accept(visitor);
  }
  void appendStringValue(JavaStringBuilder builder) {
    for (StringLiteral stringLiteral in strings) {
      stringLiteral.appendStringValue(builder);
    }
  }
}
/**
 * The abstract class {@code AnnotatedNode} defines the behavior of nodes that can be annotated with
 * both a comment and metadata.
 * @coverage dart.engine.ast
 */
abstract class AnnotatedNode extends ASTNode {

  /**
   * The documentation comment associated with this node, or {@code null} if this node does not have
   * a documentation comment associated with it.
   */
  Comment _comment;

  /**
   * The annotations associated with this node.
   */
  NodeList<Annotation> _metadata;

  /**
   * Initialize a newly created node.
   * @param comment the documentation comment associated with this node
   * @param metadata the annotations associated with this node
   */
  AnnotatedNode.full(Comment comment, List<Annotation> metadata) {
    this._metadata = new NodeList<Annotation>(this);
    this._comment = becomeParentOf(comment);
    this._metadata.addAll(metadata);
  }

  /**
   * Initialize a newly created node.
   * @param comment the documentation comment associated with this node
   * @param metadata the annotations associated with this node
   */
  AnnotatedNode({Comment comment, List<Annotation> metadata}) : this.full(comment, metadata);
  Token get beginToken {
    if (_comment == null) {
      if (_metadata.isEmpty) {
        return firstTokenAfterCommentAndMetadata;
      } else {
        return _metadata.beginToken;
      }
    } else if (_metadata.isEmpty) {
      return _comment.beginToken;
    }
    Token commentToken = _comment.beginToken;
    Token metadataToken = _metadata.beginToken;
    if (commentToken.offset < metadataToken.offset) {
      return commentToken;
    }
    return metadataToken;
  }

  /**
   * Return the documentation comment associated with this node, or {@code null} if this node does
   * not have a documentation comment associated with it.
   * @return the documentation comment associated with this node
   */
  Comment get documentationComment => _comment;

  /**
   * Return the annotations associated with this node.
   * @return the annotations associated with this node
   */
  NodeList<Annotation> get metadata => _metadata;

  /**
   * Set the documentation comment associated with this node to the given comment.
   * @param comment the documentation comment to be associated with this node
   */
  void set documentationComment(Comment comment2) {
    this._comment = becomeParentOf(comment2);
  }

  /**
   * Set the metadata associated with this node to the given metadata.
   * @param metadata the metadata to be associated with this node
   */
  void set metadata(List<Annotation> metadata2) {
    this._metadata.clear();
    this._metadata.addAll(metadata2);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    if (commentIsBeforeAnnotations()) {
      safelyVisitChild(_comment, visitor);
      _metadata.accept(visitor);
    } else {
      for (ASTNode child in sortedCommentAndAnnotations) {
        child.accept(visitor);
      }
    }
  }

  /**
   * Return the first token following the comment and metadata.
   * @return the first token following the comment and metadata
   */
  Token get firstTokenAfterCommentAndMetadata;

  /**
   * Return {@code true} if the comment is lexically before any annotations.
   * @return {@code true} if the comment is lexically before any annotations
   */
  bool commentIsBeforeAnnotations() {
    if (_comment == null || _metadata.isEmpty) {
      return true;
    }
    Annotation firstAnnotation = _metadata[0];
    return _comment.offset < firstAnnotation.offset;
  }

  /**
   * Return an array containing the comment and annotations associated with this node, sorted in
   * lexical order.
   * @return the comment and annotations associated with this node in the order in which they
   * appeared in the original source
   */
  List<ASTNode> get sortedCommentAndAnnotations {
    List<ASTNode> childList = new List<ASTNode>();
    childList.add(_comment);
    childList.addAll(_metadata);
    List<ASTNode> children = new List.from(childList);
    children.sort(ASTNode.LEXICAL_ORDER);
    return children;
  }
}
/**
 * Instances of the class {@code Annotation} represent an annotation that can be associated with an
 * AST node.
 * <pre>
 * metadata ::=
 * annotation
 * annotation ::=
 * '@' {@link Identifier qualified} ('.' {@link SimpleIdentifier identifier})? {@link ArgumentList arguments}?
 * </pre>
 * @coverage dart.engine.ast
 */
class Annotation extends ASTNode {

  /**
   * The at sign that introduced the annotation.
   */
  Token _atSign;

  /**
   * The name of the class defining the constructor that is being invoked or the name of the field
   * that is being referenced.
   */
  Identifier _name;

  /**
   * The period before the constructor name, or {@code null} if this annotation is not the
   * invocation of a named constructor.
   */
  Token _period;

  /**
   * The name of the constructor being invoked, or {@code null} if this annotation is not the
   * invocation of a named constructor.
   */
  SimpleIdentifier _constructorName;

  /**
   * The arguments to the constructor being invoked, or {@code null} if this annotation is not the
   * invocation of a constructor.
   */
  ArgumentList _arguments;

  /**
   * Initialize a newly created annotation.
   * @param atSign the at sign that introduced the annotation
   * @param name the name of the class defining the constructor that is being invoked or the name of
   * the field that is being referenced
   * @param period the period before the constructor name, or {@code null} if this annotation is not
   * the invocation of a named constructor
   * @param constructorName the name of the constructor being invoked, or {@code null} if this
   * annotation is not the invocation of a named constructor
   * @param arguments the arguments to the constructor being invoked, or {@code null} if this
   * annotation is not the invocation of a constructor
   */
  Annotation.full(Token atSign, Identifier name, Token period, SimpleIdentifier constructorName, ArgumentList arguments) {
    this._atSign = atSign;
    this._name = becomeParentOf(name);
    this._period = period;
    this._constructorName = becomeParentOf(constructorName);
    this._arguments = becomeParentOf(arguments);
  }

  /**
   * Initialize a newly created annotation.
   * @param atSign the at sign that introduced the annotation
   * @param name the name of the class defining the constructor that is being invoked or the name of
   * the field that is being referenced
   * @param period the period before the constructor name, or {@code null} if this annotation is not
   * the invocation of a named constructor
   * @param constructorName the name of the constructor being invoked, or {@code null} if this
   * annotation is not the invocation of a named constructor
   * @param arguments the arguments to the constructor being invoked, or {@code null} if this
   * annotation is not the invocation of a constructor
   */
  Annotation({Token atSign, Identifier name, Token period, SimpleIdentifier constructorName, ArgumentList arguments}) : this.full(atSign, name, period, constructorName, arguments);
  accept(ASTVisitor visitor) => visitor.visitAnnotation(this);

  /**
   * Return the arguments to the constructor being invoked, or {@code null} if this annotation is
   * not the invocation of a constructor.
   * @return the arguments to the constructor being invoked
   */
  ArgumentList get arguments => _arguments;

  /**
   * Return the at sign that introduced the annotation.
   * @return the at sign that introduced the annotation
   */
  Token get atSign => _atSign;
  Token get beginToken => _atSign;

  /**
   * Return the name of the constructor being invoked, or {@code null} if this annotation is not the
   * invocation of a named constructor.
   * @return the name of the constructor being invoked
   */
  SimpleIdentifier get constructorName => _constructorName;

  /**
   * Return the element associated with this annotation, or {@code null} if the AST structure has
   * not been resolved or if this annotation could not be resolved.
   * @return the element associated with this annotation
   */
  Element get element {
    if (_constructorName != null) {
      return _constructorName.element;
    } else if (_name != null) {
      return _name.element;
    }
    return null;
  }
  Token get endToken {
    if (_arguments != null) {
      return _arguments.endToken;
    } else if (_constructorName != null) {
      return _constructorName.endToken;
    }
    return _name.endToken;
  }

  /**
   * Return the name of the class defining the constructor that is being invoked or the name of the
   * field that is being referenced.
   * @return the name of the constructor being invoked or the name of the field being referenced
   */
  Identifier get name => _name;

  /**
   * Return the period before the constructor name, or {@code null} if this annotation is not the
   * invocation of a named constructor.
   * @return the period before the constructor name
   */
  Token get period => _period;

  /**
   * Set the arguments to the constructor being invoked to the given arguments.
   * @param arguments the arguments to the constructor being invoked
   */
  void set arguments(ArgumentList arguments2) {
    this._arguments = becomeParentOf(arguments2);
  }

  /**
   * Set the at sign that introduced the annotation to the given token.
   * @param atSign the at sign that introduced the annotation
   */
  void set atSign(Token atSign2) {
    this._atSign = atSign2;
  }

  /**
   * Set the name of the constructor being invoked to the given name.
   * @param constructorName the name of the constructor being invoked
   */
  void set constructorName(SimpleIdentifier constructorName2) {
    this._constructorName = becomeParentOf(constructorName2);
  }

  /**
   * Set the name of the class defining the constructor that is being invoked or the name of the
   * field that is being referenced to the given name.
   * @param name the name of the constructor being invoked or the name of the field being referenced
   */
  void set name(Identifier name2) {
    this._name = becomeParentOf(name2);
  }

  /**
   * Set the period before the constructor name to the given token.
   * @param period the period before the constructor name
   */
  void set period(Token period2) {
    this._period = period2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_name, visitor);
    safelyVisitChild(_constructorName, visitor);
    safelyVisitChild(_arguments, visitor);
  }
}
/**
 * Instances of the class {@code ArgumentDefinitionTest} represent an argument definition test.
 * <pre>
 * argumentDefinitionTest ::=
 * '?' {@link SimpleIdentifier identifier}</pre>
 * @coverage dart.engine.ast
 */
class ArgumentDefinitionTest extends Expression {

  /**
   * The token representing the question mark.
   */
  Token _question;

  /**
   * The identifier representing the argument being tested.
   */
  SimpleIdentifier _identifier;

  /**
   * Initialize a newly created argument definition test.
   * @param question the token representing the question mark
   * @param identifier the identifier representing the argument being tested
   */
  ArgumentDefinitionTest.full(Token question, SimpleIdentifier identifier) {
    this._question = question;
    this._identifier = becomeParentOf(identifier);
  }

  /**
   * Initialize a newly created argument definition test.
   * @param question the token representing the question mark
   * @param identifier the identifier representing the argument being tested
   */
  ArgumentDefinitionTest({Token question, SimpleIdentifier identifier}) : this.full(question, identifier);
  accept(ASTVisitor visitor) => visitor.visitArgumentDefinitionTest(this);
  Token get beginToken => _question;
  Token get endToken => _identifier.endToken;

  /**
   * Return the identifier representing the argument being tested.
   * @return the identifier representing the argument being tested
   */
  SimpleIdentifier get identifier => _identifier;

  /**
   * Return the token representing the question mark.
   * @return the token representing the question mark
   */
  Token get question => _question;

  /**
   * Set the identifier representing the argument being tested to the given identifier.
   * @param identifier the identifier representing the argument being tested
   */
  void set identifier(SimpleIdentifier identifier2) {
    this._identifier = becomeParentOf(identifier2);
  }

  /**
   * Set the token representing the question mark to the given token.
   * @param question the token representing the question mark
   */
  void set question(Token question2) {
    this._question = question2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_identifier, visitor);
  }
}
/**
 * Instances of the class {@code ArgumentList} represent a list of arguments in the invocation of a
 * executable element: a function, method, or constructor.
 * <pre>
 * argumentList ::=
 * '(' arguments? ')'
 * arguments ::={@link NamedExpression namedArgument} (',' {@link NamedExpression namedArgument})
 * | {@link Expression expressionList} (',' {@link NamedExpression namedArgument})
 * </pre>
 * @coverage dart.engine.ast
 */
class ArgumentList extends ASTNode {

  /**
   * The left parenthesis.
   */
  Token _leftParenthesis;

  /**
   * The expressions producing the values of the arguments.
   */
  NodeList<Expression> _arguments;

  /**
   * The right parenthesis.
   */
  Token _rightParenthesis;

  /**
   * An array containing the elements representing the parameters corresponding to each of the
   * arguments in this list, or {@code null} if the AST has not been resolved or if the function or
   * method being invoked could not be determined based on static type information. The array must
   * be the same length as the number of arguments, but can contain {@code null} entries if a given
   * argument does not correspond to a formal parameter.
   */
  List<ParameterElement> _correspondingStaticParameters;

  /**
   * An array containing the elements representing the parameters corresponding to each of the
   * arguments in this list, or {@code null} if the AST has not been resolved or if the function or
   * method being invoked could not be determined based on propagated type information. The array
   * must be the same length as the number of arguments, but can contain {@code null} entries if a
   * given argument does not correspond to a formal parameter.
   */
  List<ParameterElement> _correspondingPropagatedParameters;

  /**
   * Initialize a newly created list of arguments.
   * @param leftParenthesis the left parenthesis
   * @param arguments the expressions producing the values of the arguments
   * @param rightParenthesis the right parenthesis
   */
  ArgumentList.full(Token leftParenthesis, List<Expression> arguments, Token rightParenthesis) {
    this._arguments = new NodeList<Expression>(this);
    this._leftParenthesis = leftParenthesis;
    this._arguments.addAll(arguments);
    this._rightParenthesis = rightParenthesis;
  }

  /**
   * Initialize a newly created list of arguments.
   * @param leftParenthesis the left parenthesis
   * @param arguments the expressions producing the values of the arguments
   * @param rightParenthesis the right parenthesis
   */
  ArgumentList({Token leftParenthesis, List<Expression> arguments, Token rightParenthesis}) : this.full(leftParenthesis, arguments, rightParenthesis);
  accept(ASTVisitor visitor) => visitor.visitArgumentList(this);

  /**
   * Return the expressions producing the values of the arguments. Although the language requires
   * that positional arguments appear before named arguments, this class allows them to be
   * intermixed.
   * @return the expressions producing the values of the arguments
   */
  NodeList<Expression> get arguments => _arguments;
  Token get beginToken => _leftParenthesis;
  Token get endToken => _rightParenthesis;

  /**
   * Return the left parenthesis.
   * @return the left parenthesis
   */
  Token get leftParenthesis => _leftParenthesis;

  /**
   * Return the right parenthesis.
   * @return the right parenthesis
   */
  Token get rightParenthesis => _rightParenthesis;

  /**
   * Set the parameter elements corresponding to each of the arguments in this list to the given
   * array of parameters. The array of parameters must be the same length as the number of
   * arguments, but can contain {@code null} entries if a given argument does not correspond to a
   * formal parameter.
   * @param parameters the parameter elements corresponding to the arguments
   */
  void set correspondingParameters(List<ParameterElement> parameters) {
    if (parameters.length != _arguments.length) {
      throw new IllegalArgumentException("Expected ${_arguments.length} parameters, not ${parameters.length}");
    }
    _correspondingPropagatedParameters = parameters;
  }

  /**
   * Set the parameter elements corresponding to each of the arguments in this list to the given
   * array of parameters. The array of parameters must be the same length as the number of
   * arguments, but can contain {@code null} entries if a given argument does not correspond to a
   * formal parameter.
   * @param parameters the parameter elements corresponding to the arguments
   */
  void set correspondingStaticParameters(List<ParameterElement> parameters) {
    if (parameters.length != _arguments.length) {
      throw new IllegalArgumentException("Expected ${_arguments.length} parameters, not ${parameters.length}");
    }
    _correspondingStaticParameters = parameters;
  }

  /**
   * Set the left parenthesis to the given token.
   * @param parenthesis the left parenthesis
   */
  void set leftParenthesis(Token parenthesis) {
    _leftParenthesis = parenthesis;
  }

  /**
   * Set the right parenthesis to the given token.
   * @param parenthesis the right parenthesis
   */
  void set rightParenthesis(Token parenthesis) {
    _rightParenthesis = parenthesis;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    _arguments.accept(visitor);
  }

  /**
   * If the given expression is a child of this list, and the AST structure has been resolved, and
   * the function being invoked is known based on propagated type information, and the expression
   * corresponds to one of the parameters of the function being invoked, then return the parameter
   * element representing the parameter to which the value of the given expression will be bound.
   * Otherwise, return {@code null}.
   * <p>
   * This method is only intended to be used by {@link Expression#getParameterElement()}.
   * @param expression the expression corresponding to the parameter to be returned
   * @return the parameter element representing the parameter to which the value of the expression
   * will be bound
   */
  ParameterElement getPropagatedParameterElementFor(Expression expression) {
    if (_correspondingPropagatedParameters == null) {
      return null;
    }
    int index = _arguments.indexOf(expression);
    if (index < 0) {
      return null;
    }
    return _correspondingPropagatedParameters[index];
  }

  /**
   * If the given expression is a child of this list, and the AST structure has been resolved, and
   * the function being invoked is known based on static type information, and the expression
   * corresponds to one of the parameters of the function being invoked, then return the parameter
   * element representing the parameter to which the value of the given expression will be bound.
   * Otherwise, return {@code null}.
   * <p>
   * This method is only intended to be used by {@link Expression#getStaticParameterElement()}.
   * @param expression the expression corresponding to the parameter to be returned
   * @return the parameter element representing the parameter to which the value of the expression
   * will be bound
   */
  ParameterElement getStaticParameterElementFor(Expression expression) {
    if (_correspondingStaticParameters == null) {
      return null;
    }
    int index = _arguments.indexOf(expression);
    if (index < 0) {
      return null;
    }
    return _correspondingStaticParameters[index];
  }
}
/**
 * Instances of the class {@code AsExpression} represent an 'as' expression.
 * <pre>
 * asExpression ::={@link Expression expression} 'as' {@link TypeName type}</pre>
 * @coverage dart.engine.ast
 */
class AsExpression extends Expression {

  /**
   * The expression used to compute the value being cast.
   */
  Expression _expression;

  /**
   * The as operator.
   */
  Token _asOperator;

  /**
   * The name of the type being cast to.
   */
  TypeName _type;

  /**
   * Initialize a newly created as expression.
   * @param expression the expression used to compute the value being cast
   * @param isOperator the is operator
   * @param type the name of the type being cast to
   */
  AsExpression.full(Expression expression, Token isOperator, TypeName type) {
    this._expression = becomeParentOf(expression);
    this._asOperator = isOperator;
    this._type = becomeParentOf(type);
  }

  /**
   * Initialize a newly created as expression.
   * @param expression the expression used to compute the value being cast
   * @param isOperator the is operator
   * @param type the name of the type being cast to
   */
  AsExpression({Expression expression, Token isOperator, TypeName type}) : this.full(expression, isOperator, type);
  accept(ASTVisitor visitor) => visitor.visitAsExpression(this);

  /**
   * Return the is operator being applied.
   * @return the is operator being applied
   */
  Token get asOperator => _asOperator;
  Token get beginToken => _expression.beginToken;
  Token get endToken => _type.endToken;

  /**
   * Return the expression used to compute the value being cast.
   * @return the expression used to compute the value being cast
   */
  Expression get expression => _expression;

  /**
   * Return the name of the type being cast to.
   * @return the name of the type being cast to
   */
  TypeName get type => _type;

  /**
   * Set the is operator being applied to the given operator.
   * @param asOperator the is operator being applied
   */
  void set asOperator(Token asOperator2) {
    this._asOperator = asOperator2;
  }

  /**
   * Set the expression used to compute the value being cast to the given expression.
   * @param expression the expression used to compute the value being cast
   */
  void set expression(Expression expression2) {
    this._expression = becomeParentOf(expression2);
  }

  /**
   * Set the name of the type being cast to to the given name.
   * @param name the name of the type being cast to
   */
  void set type(TypeName name) {
    this._type = becomeParentOf(name);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_expression, visitor);
    safelyVisitChild(_type, visitor);
  }
}
/**
 * Instances of the class {@code AssertStatement} represent an assert statement.
 * <pre>
 * assertStatement ::=
 * 'assert' '(' {@link Expression conditionalExpression} ')' ';'
 * </pre>
 * @coverage dart.engine.ast
 */
class AssertStatement extends Statement {

  /**
   * The token representing the 'assert' keyword.
   */
  Token _keyword;

  /**
   * The left parenthesis.
   */
  Token _leftParenthesis;

  /**
   * The condition that is being asserted to be {@code true}.
   */
  Expression _condition;

  /**
   * The right parenthesis.
   */
  Token _rightParenthesis;

  /**
   * The semicolon terminating the statement.
   */
  Token _semicolon;

  /**
   * Initialize a newly created assert statement.
   * @param keyword the token representing the 'assert' keyword
   * @param leftParenthesis the left parenthesis
   * @param condition the condition that is being asserted to be {@code true}
   * @param rightParenthesis the right parenthesis
   * @param semicolon the semicolon terminating the statement
   */
  AssertStatement.full(Token keyword, Token leftParenthesis, Expression condition, Token rightParenthesis, Token semicolon) {
    this._keyword = keyword;
    this._leftParenthesis = leftParenthesis;
    this._condition = becomeParentOf(condition);
    this._rightParenthesis = rightParenthesis;
    this._semicolon = semicolon;
  }

  /**
   * Initialize a newly created assert statement.
   * @param keyword the token representing the 'assert' keyword
   * @param leftParenthesis the left parenthesis
   * @param condition the condition that is being asserted to be {@code true}
   * @param rightParenthesis the right parenthesis
   * @param semicolon the semicolon terminating the statement
   */
  AssertStatement({Token keyword, Token leftParenthesis, Expression condition, Token rightParenthesis, Token semicolon}) : this.full(keyword, leftParenthesis, condition, rightParenthesis, semicolon);
  accept(ASTVisitor visitor) => visitor.visitAssertStatement(this);
  Token get beginToken => _keyword;

  /**
   * Return the condition that is being asserted to be {@code true}.
   * @return the condition that is being asserted to be {@code true}
   */
  Expression get condition => _condition;
  Token get endToken => _semicolon;

  /**
   * Return the token representing the 'assert' keyword.
   * @return the token representing the 'assert' keyword
   */
  Token get keyword => _keyword;

  /**
   * Return the left parenthesis.
   * @return the left parenthesis
   */
  Token get leftParenthesis => _leftParenthesis;

  /**
   * Return the right parenthesis.
   * @return the right parenthesis
   */
  Token get rightParenthesis => _rightParenthesis;

  /**
   * Return the semicolon terminating the statement.
   * @return the semicolon terminating the statement
   */
  Token get semicolon => _semicolon;

  /**
   * Set the condition that is being asserted to be {@code true} to the given expression.
   * @param the condition that is being asserted to be {@code true}
   */
  void set condition(Expression condition2) {
    this._condition = becomeParentOf(condition2);
  }

  /**
   * Set the token representing the 'assert' keyword to the given token.
   * @param keyword the token representing the 'assert' keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }

  /**
   * Set the left parenthesis to the given token.
   * @param the left parenthesis
   */
  void set leftParenthesis(Token leftParenthesis2) {
    this._leftParenthesis = leftParenthesis2;
  }

  /**
   * Set the right parenthesis to the given token.
   * @param rightParenthesis the right parenthesis
   */
  void set rightParenthesis(Token rightParenthesis2) {
    this._rightParenthesis = rightParenthesis2;
  }

  /**
   * Set the semicolon terminating the statement to the given token.
   * @param semicolon the semicolon terminating the statement
   */
  void set semicolon(Token semicolon2) {
    this._semicolon = semicolon2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_condition, visitor);
  }
}
/**
 * Instances of the class {@code AssignmentExpression} represent an assignment expression.
 * <pre>
 * assignmentExpression ::={@link Expression leftHandSide} {@link Token operator} {@link Expression rightHandSide}</pre>
 * @coverage dart.engine.ast
 */
class AssignmentExpression extends Expression {

  /**
   * The expression used to compute the left hand side.
   */
  Expression _leftHandSide;

  /**
   * The assignment operator being applied.
   */
  Token _operator;

  /**
   * The expression used to compute the right hand side.
   */
  Expression _rightHandSide;

  /**
   * The element associated with the operator based on the static type of the left-hand-side, or{@code null} if the AST structure has not been resolved, if the operator is not a compound
   * operator, or if the operator could not be resolved.
   */
  MethodElement _staticElement;

  /**
   * The element associated with the operator based on the propagated type of the left-hand-side, or{@code null} if the AST structure has not been resolved, if the operator is not a compound
   * operator, or if the operator could not be resolved.
   */
  MethodElement _propagatedElement;

  /**
   * Initialize a newly created assignment expression.
   * @param leftHandSide the expression used to compute the left hand side
   * @param operator the assignment operator being applied
   * @param rightHandSide the expression used to compute the right hand side
   */
  AssignmentExpression.full(Expression leftHandSide, Token operator, Expression rightHandSide) {
    this._leftHandSide = becomeParentOf(leftHandSide);
    this._operator = operator;
    this._rightHandSide = becomeParentOf(rightHandSide);
  }

  /**
   * Initialize a newly created assignment expression.
   * @param leftHandSide the expression used to compute the left hand side
   * @param operator the assignment operator being applied
   * @param rightHandSide the expression used to compute the right hand side
   */
  AssignmentExpression({Expression leftHandSide, Token operator, Expression rightHandSide}) : this.full(leftHandSide, operator, rightHandSide);
  accept(ASTVisitor visitor) => visitor.visitAssignmentExpression(this);
  Token get beginToken => _leftHandSide.beginToken;

  /**
   * Return the element associated with the operator based on the propagated type of the
   * left-hand-side, or {@code null} if the AST structure has not been resolved, if the operator is
   * not a compound operator, or if the operator could not be resolved. One example of the latter
   * case is an operator that is not defined for the type of the left-hand operand.
   * @return the element associated with the operator
   */
  MethodElement get element => _propagatedElement;
  Token get endToken => _rightHandSide.endToken;

  /**
   * Set the expression used to compute the left hand side to the given expression.
   * @return the expression used to compute the left hand side
   */
  Expression get leftHandSide => _leftHandSide;

  /**
   * Return the assignment operator being applied.
   * @return the assignment operator being applied
   */
  Token get operator => _operator;

  /**
   * Return the expression used to compute the right hand side.
   * @return the expression used to compute the right hand side
   */
  Expression get rightHandSide => _rightHandSide;

  /**
   * Return the element associated with the operator based on the static type of the left-hand-side,
   * or {@code null} if the AST structure has not been resolved, if the operator is not a compound
   * operator, or if the operator could not be resolved. One example of the latter case is an
   * operator that is not defined for the type of the left-hand operand.
   * @return the element associated with the operator
   */
  MethodElement get staticElement => _staticElement;

  /**
   * Set the element associated with the operator based on the propagated type of the left-hand-side
   * to the given element.
   * @param element the element to be associated with the operator
   */
  void set element(MethodElement element2) {
    _propagatedElement = element2;
  }

  /**
   * Return the expression used to compute the left hand side.
   * @param expression the expression used to compute the left hand side
   */
  void set leftHandSide(Expression expression) {
    _leftHandSide = becomeParentOf(expression);
  }

  /**
   * Set the assignment operator being applied to the given operator.
   * @param operator the assignment operator being applied
   */
  void set operator(Token operator2) {
    this._operator = operator2;
  }

  /**
   * Set the expression used to compute the left hand side to the given expression.
   * @param expression the expression used to compute the left hand side
   */
  void set rightHandSide(Expression expression) {
    _rightHandSide = becomeParentOf(expression);
  }

  /**
   * Set the element associated with the operator based on the static type of the left-hand-side to
   * the given element.
   * @param element the static element to be associated with the operator
   */
  void set staticElement(MethodElement element) {
    _staticElement = element;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_leftHandSide, visitor);
    safelyVisitChild(_rightHandSide, visitor);
  }
}
/**
 * Instances of the class {@code BinaryExpression} represent a binary (infix) expression.
 * <pre>
 * binaryExpression ::={@link Expression leftOperand} {@link Token operator} {@link Expression rightOperand}</pre>
 * @coverage dart.engine.ast
 */
class BinaryExpression extends Expression {

  /**
   * The expression used to compute the left operand.
   */
  Expression _leftOperand;

  /**
   * The binary operator being applied.
   */
  Token _operator;

  /**
   * The expression used to compute the right operand.
   */
  Expression _rightOperand;

  /**
   * The element associated with the operator based on the static type of the left operand, or{@code null} if the AST structure has not been resolved, if the operator is not user definable,
   * or if the operator could not be resolved.
   */
  MethodElement _staticElement;

  /**
   * The element associated with the operator based on the propagated type of the left operand, or{@code null} if the AST structure has not been resolved, if the operator is not user definable,
   * or if the operator could not be resolved.
   */
  MethodElement _propagatedElement;

  /**
   * Initialize a newly created binary expression.
   * @param leftOperand the expression used to compute the left operand
   * @param operator the binary operator being applied
   * @param rightOperand the expression used to compute the right operand
   */
  BinaryExpression.full(Expression leftOperand, Token operator, Expression rightOperand) {
    this._leftOperand = becomeParentOf(leftOperand);
    this._operator = operator;
    this._rightOperand = becomeParentOf(rightOperand);
  }

  /**
   * Initialize a newly created binary expression.
   * @param leftOperand the expression used to compute the left operand
   * @param operator the binary operator being applied
   * @param rightOperand the expression used to compute the right operand
   */
  BinaryExpression({Expression leftOperand, Token operator, Expression rightOperand}) : this.full(leftOperand, operator, rightOperand);
  accept(ASTVisitor visitor) => visitor.visitBinaryExpression(this);
  Token get beginToken => _leftOperand.beginToken;

  /**
   * Return the element associated with the operator based on the propagated type of the left
   * operand, or {@code null} if the AST structure has not been resolved, if the operator is not
   * user definable, or if the operator could not be resolved. One example of the latter case is an
   * operator that is not defined for the type of the left-hand operand.
   * @return the element associated with the operator
   */
  MethodElement get element => _propagatedElement;
  Token get endToken => _rightOperand.endToken;

  /**
   * Return the expression used to compute the left operand.
   * @return the expression used to compute the left operand
   */
  Expression get leftOperand => _leftOperand;

  /**
   * Return the binary operator being applied.
   * @return the binary operator being applied
   */
  Token get operator => _operator;

  /**
   * Return the expression used to compute the right operand.
   * @return the expression used to compute the right operand
   */
  Expression get rightOperand => _rightOperand;

  /**
   * Return the element associated with the operator based on the static type of the left operand,
   * or {@code null} if the AST structure has not been resolved, if the operator is not user
   * definable, or if the operator could not be resolved. One example of the latter case is an
   * operator that is not defined for the type of the left operand.
   * @return the element associated with the operator
   */
  MethodElement get staticElement => _staticElement;

  /**
   * Set the element associated with the operator based on the propagated type of the left operand
   * to the given element.
   * @param element the element to be associated with the operator
   */
  void set element(MethodElement element2) {
    _propagatedElement = element2;
  }

  /**
   * Set the expression used to compute the left operand to the given expression.
   * @param expression the expression used to compute the left operand
   */
  void set leftOperand(Expression expression) {
    _leftOperand = becomeParentOf(expression);
  }

  /**
   * Set the binary operator being applied to the given operator.
   * @return the binary operator being applied
   */
  void set operator(Token operator2) {
    this._operator = operator2;
  }

  /**
   * Set the expression used to compute the right operand to the given expression.
   * @param expression the expression used to compute the right operand
   */
  void set rightOperand(Expression expression) {
    _rightOperand = becomeParentOf(expression);
  }

  /**
   * Set the element associated with the operator based on the static type of the left operand to
   * the given element.
   * @param element the static element to be associated with the operator
   */
  void set staticElement(MethodElement element) {
    _staticElement = element;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_leftOperand, visitor);
    safelyVisitChild(_rightOperand, visitor);
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is known based on
   * propagated type information, then return the parameter element representing the parameter to
   * which the value of the right operand will be bound. Otherwise, return {@code null}.
   * <p>
   * This method is only intended to be used by {@link Expression#getParameterElement()}.
   * @return the parameter element representing the parameter to which the value of the right
   * operand will be bound
   */
  ParameterElement get propagatedParameterElementForRightOperand {
    if (_propagatedElement == null) {
      return null;
    }
    List<ParameterElement> parameters = _propagatedElement.parameters;
    if (parameters.length < 1) {
      return null;
    }
    return parameters[0];
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is known based on static
   * type information, then return the parameter element representing the parameter to which the
   * value of the right operand will be bound. Otherwise, return {@code null}.
   * <p>
   * This method is only intended to be used by {@link Expression#getStaticParameterElement()}.
   * @return the parameter element representing the parameter to which the value of the right
   * operand will be bound
   */
  ParameterElement get staticParameterElementForRightOperand {
    if (_staticElement == null) {
      return null;
    }
    List<ParameterElement> parameters = _staticElement.parameters;
    if (parameters.length < 1) {
      return null;
    }
    return parameters[0];
  }
}
/**
 * Instances of the class {@code Block} represent a sequence of statements.
 * <pre>
 * block ::=
 * '{' statement* '}'
 * </pre>
 * @coverage dart.engine.ast
 */
class Block extends Statement {

  /**
   * The left curly bracket.
   */
  Token _leftBracket;

  /**
   * The statements contained in the block.
   */
  NodeList<Statement> _statements;

  /**
   * The right curly bracket.
   */
  Token _rightBracket;

  /**
   * Initialize a newly created block of code.
   * @param leftBracket the left curly bracket
   * @param statements the statements contained in the block
   * @param rightBracket the right curly bracket
   */
  Block.full(Token leftBracket, List<Statement> statements, Token rightBracket) {
    this._statements = new NodeList<Statement>(this);
    this._leftBracket = leftBracket;
    this._statements.addAll(statements);
    this._rightBracket = rightBracket;
  }

  /**
   * Initialize a newly created block of code.
   * @param leftBracket the left curly bracket
   * @param statements the statements contained in the block
   * @param rightBracket the right curly bracket
   */
  Block({Token leftBracket, List<Statement> statements, Token rightBracket}) : this.full(leftBracket, statements, rightBracket);
  accept(ASTVisitor visitor) => visitor.visitBlock(this);
  Token get beginToken => _leftBracket;
  Token get endToken => _rightBracket;

  /**
   * Return the left curly bracket.
   * @return the left curly bracket
   */
  Token get leftBracket => _leftBracket;

  /**
   * Return the right curly bracket.
   * @return the right curly bracket
   */
  Token get rightBracket => _rightBracket;

  /**
   * Return the statements contained in the block.
   * @return the statements contained in the block
   */
  NodeList<Statement> get statements => _statements;

  /**
   * Set the left curly bracket to the given token.
   * @param leftBracket the left curly bracket
   */
  void set leftBracket(Token leftBracket2) {
    this._leftBracket = leftBracket2;
  }

  /**
   * Set the right curly bracket to the given token.
   * @param rightBracket the right curly bracket
   */
  void set rightBracket(Token rightBracket2) {
    this._rightBracket = rightBracket2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    _statements.accept(visitor);
  }
}
/**
 * Instances of the class {@code BlockFunctionBody} represent a function body that consists of a
 * block of statements.
 * <pre>
 * blockFunctionBody ::={@link Block block}</pre>
 * @coverage dart.engine.ast
 */
class BlockFunctionBody extends FunctionBody {

  /**
   * The block representing the body of the function.
   */
  Block _block;

  /**
   * Initialize a newly created function body consisting of a block of statements.
   * @param block the block representing the body of the function
   */
  BlockFunctionBody.full(Block block) {
    this._block = becomeParentOf(block);
  }

  /**
   * Initialize a newly created function body consisting of a block of statements.
   * @param block the block representing the body of the function
   */
  BlockFunctionBody({Block block}) : this.full(block);
  accept(ASTVisitor visitor) => visitor.visitBlockFunctionBody(this);
  Token get beginToken => _block.beginToken;

  /**
   * Return the block representing the body of the function.
   * @return the block representing the body of the function
   */
  Block get block => _block;
  Token get endToken => _block.endToken;

  /**
   * Set the block representing the body of the function to the given block.
   * @param block the block representing the body of the function
   */
  void set block(Block block2) {
    this._block = becomeParentOf(block2);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_block, visitor);
  }
}
/**
 * Instances of the class {@code BooleanLiteral} represent a boolean literal expression.
 * <pre>
 * booleanLiteral ::=
 * 'false' | 'true'
 * </pre>
 * @coverage dart.engine.ast
 */
class BooleanLiteral extends Literal {

  /**
   * The token representing the literal.
   */
  Token _literal;

  /**
   * The value of the literal.
   */
  bool _value = false;

  /**
   * Initialize a newly created boolean literal.
   * @param literal the token representing the literal
   * @param value the value of the literal
   */
  BooleanLiteral.full(Token literal, bool value) {
    this._literal = literal;
    this._value = value;
  }

  /**
   * Initialize a newly created boolean literal.
   * @param literal the token representing the literal
   * @param value the value of the literal
   */
  BooleanLiteral({Token literal, bool value}) : this.full(literal, value);
  accept(ASTVisitor visitor) => visitor.visitBooleanLiteral(this);
  Token get beginToken => _literal;
  Token get endToken => _literal;

  /**
   * Return the token representing the literal.
   * @return the token representing the literal
   */
  Token get literal => _literal;

  /**
   * Return the value of the literal.
   * @return the value of the literal
   */
  bool get value => _value;
  bool isSynthetic() => _literal.isSynthetic();

  /**
   * Set the token representing the literal to the given token.
   * @param literal the token representing the literal
   */
  void set literal(Token literal2) {
    this._literal = literal2;
  }

  /**
   * Set the value of the literal to the given value.
   * @param value the value of the literal
   */
  void set value(bool value2) {
    this._value = value2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
  }
}
/**
 * Instances of the class {@code BreakStatement} represent a break statement.
 * <pre>
 * breakStatement ::=
 * 'break' {@link SimpleIdentifier label}? ';'
 * </pre>
 * @coverage dart.engine.ast
 */
class BreakStatement extends Statement {

  /**
   * The token representing the 'break' keyword.
   */
  Token _keyword;

  /**
   * The label associated with the statement, or {@code null} if there is no label.
   */
  SimpleIdentifier _label;

  /**
   * The semicolon terminating the statement.
   */
  Token _semicolon;

  /**
   * Initialize a newly created break statement.
   * @param keyword the token representing the 'break' keyword
   * @param label the label associated with the statement
   * @param semicolon the semicolon terminating the statement
   */
  BreakStatement.full(Token keyword, SimpleIdentifier label, Token semicolon) {
    this._keyword = keyword;
    this._label = becomeParentOf(label);
    this._semicolon = semicolon;
  }

  /**
   * Initialize a newly created break statement.
   * @param keyword the token representing the 'break' keyword
   * @param label the label associated with the statement
   * @param semicolon the semicolon terminating the statement
   */
  BreakStatement({Token keyword, SimpleIdentifier label, Token semicolon}) : this.full(keyword, label, semicolon);
  accept(ASTVisitor visitor) => visitor.visitBreakStatement(this);
  Token get beginToken => _keyword;
  Token get endToken => _semicolon;

  /**
   * Return the token representing the 'break' keyword.
   * @return the token representing the 'break' keyword
   */
  Token get keyword => _keyword;

  /**
   * Return the label associated with the statement, or {@code null} if there is no label.
   * @return the label associated with the statement
   */
  SimpleIdentifier get label => _label;

  /**
   * Return the semicolon terminating the statement.
   * @return the semicolon terminating the statement
   */
  Token get semicolon => _semicolon;

  /**
   * Set the token representing the 'break' keyword to the given token.
   * @param keyword the token representing the 'break' keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }

  /**
   * Set the label associated with the statement to the given identifier.
   * @param identifier the label associated with the statement
   */
  void set label(SimpleIdentifier identifier) {
    _label = becomeParentOf(identifier);
  }

  /**
   * Set the semicolon terminating the statement to the given token.
   * @param semicolon the semicolon terminating the statement
   */
  void set semicolon(Token semicolon2) {
    this._semicolon = semicolon2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_label, visitor);
  }
}
/**
 * Instances of the class {@code CascadeExpression} represent a sequence of cascaded expressions:
 * expressions that share a common target. There are three kinds of expressions that can be used in
 * a cascade expression: {@link IndexExpression}, {@link MethodInvocation} and{@link PropertyAccess}.
 * <pre>
 * cascadeExpression ::={@link Expression conditionalExpression} cascadeSection
 * cascadeSection ::=
 * '..'  (cascadeSelector arguments*) (assignableSelector arguments*)* (assignmentOperator expressionWithoutCascade)?
 * cascadeSelector ::=
 * '\[ ' expression '\] '
 * | identifier
 * </pre>
 * @coverage dart.engine.ast
 */
class CascadeExpression extends Expression {

  /**
   * The target of the cascade sections.
   */
  Expression _target;

  /**
   * The cascade sections sharing the common target.
   */
  NodeList<Expression> _cascadeSections;

  /**
   * Initialize a newly created cascade expression.
   * @param target the target of the cascade sections
   * @param cascadeSections the cascade sections sharing the common target
   */
  CascadeExpression.full(Expression target, List<Expression> cascadeSections) {
    this._cascadeSections = new NodeList<Expression>(this);
    this._target = becomeParentOf(target);
    this._cascadeSections.addAll(cascadeSections);
  }

  /**
   * Initialize a newly created cascade expression.
   * @param target the target of the cascade sections
   * @param cascadeSections the cascade sections sharing the common target
   */
  CascadeExpression({Expression target, List<Expression> cascadeSections}) : this.full(target, cascadeSections);
  accept(ASTVisitor visitor) => visitor.visitCascadeExpression(this);
  Token get beginToken => _target.beginToken;

  /**
   * Return the cascade sections sharing the common target.
   * @return the cascade sections sharing the common target
   */
  NodeList<Expression> get cascadeSections => _cascadeSections;
  Token get endToken => _cascadeSections.endToken;

  /**
   * Return the target of the cascade sections.
   * @return the target of the cascade sections
   */
  Expression get target => _target;

  /**
   * Set the target of the cascade sections to the given expression.
   * @param target the target of the cascade sections
   */
  void set target(Expression target2) {
    this._target = becomeParentOf(target2);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_target, visitor);
    _cascadeSections.accept(visitor);
  }
}
/**
 * Instances of the class {@code CatchClause} represent a catch clause within a try statement.
 * <pre>
 * onPart ::=
 * catchPart {@link Block block}| 'on' type catchPart? {@link Block block}catchPart ::=
 * 'catch' '(' {@link SimpleIdentifier exceptionParameter} (',' {@link SimpleIdentifier stackTraceParameter})? ')'
 * </pre>
 * @coverage dart.engine.ast
 */
class CatchClause extends ASTNode {

  /**
   * The token representing the 'on' keyword, or {@code null} if there is no 'on' keyword.
   */
  Token _onKeyword;

  /**
   * The type of exceptions caught by this catch clause, or {@code null} if this catch clause
   * catches every type of exception.
   */
  TypeName _exceptionType;

  /**
   * The token representing the 'catch' keyword, or {@code null} if there is no 'catch' keyword.
   */
  Token _catchKeyword;

  /**
   * The left parenthesis.
   */
  Token _leftParenthesis;

  /**
   * The parameter whose value will be the exception that was thrown.
   */
  SimpleIdentifier _exceptionParameter;

  /**
   * The comma separating the exception parameter from the stack trace parameter.
   */
  Token _comma;

  /**
   * The parameter whose value will be the stack trace associated with the exception.
   */
  SimpleIdentifier _stackTraceParameter;

  /**
   * The right parenthesis.
   */
  Token _rightParenthesis;

  /**
   * The body of the catch block.
   */
  Block _body;

  /**
   * Initialize a newly created catch clause.
   * @param onKeyword the token representing the 'on' keyword
   * @param exceptionType the type of exceptions caught by this catch clause
   * @param leftParenthesis the left parenthesis
   * @param exceptionParameter the parameter whose value will be the exception that was thrown
   * @param comma the comma separating the exception parameter from the stack trace parameter
   * @param stackTraceParameter the parameter whose value will be the stack trace associated with
   * the exception
   * @param rightParenthesis the right parenthesis
   * @param body the body of the catch block
   */
  CatchClause.full(Token onKeyword, TypeName exceptionType, Token catchKeyword, Token leftParenthesis, SimpleIdentifier exceptionParameter, Token comma, SimpleIdentifier stackTraceParameter, Token rightParenthesis, Block body) {
    this._onKeyword = onKeyword;
    this._exceptionType = becomeParentOf(exceptionType);
    this._catchKeyword = catchKeyword;
    this._leftParenthesis = leftParenthesis;
    this._exceptionParameter = becomeParentOf(exceptionParameter);
    this._comma = comma;
    this._stackTraceParameter = becomeParentOf(stackTraceParameter);
    this._rightParenthesis = rightParenthesis;
    this._body = becomeParentOf(body);
  }

  /**
   * Initialize a newly created catch clause.
   * @param onKeyword the token representing the 'on' keyword
   * @param exceptionType the type of exceptions caught by this catch clause
   * @param leftParenthesis the left parenthesis
   * @param exceptionParameter the parameter whose value will be the exception that was thrown
   * @param comma the comma separating the exception parameter from the stack trace parameter
   * @param stackTraceParameter the parameter whose value will be the stack trace associated with
   * the exception
   * @param rightParenthesis the right parenthesis
   * @param body the body of the catch block
   */
  CatchClause({Token onKeyword, TypeName exceptionType, Token catchKeyword, Token leftParenthesis, SimpleIdentifier exceptionParameter, Token comma, SimpleIdentifier stackTraceParameter, Token rightParenthesis, Block body}) : this.full(onKeyword, exceptionType, catchKeyword, leftParenthesis, exceptionParameter, comma, stackTraceParameter, rightParenthesis, body);
  accept(ASTVisitor visitor) => visitor.visitCatchClause(this);
  Token get beginToken {
    if (_onKeyword != null) {
      return _onKeyword;
    }
    return _catchKeyword;
  }

  /**
   * Return the body of the catch block.
   * @return the body of the catch block
   */
  Block get body => _body;

  /**
   * Return the token representing the 'catch' keyword, or {@code null} if there is no 'catch'
   * keyword.
   * @return the token representing the 'catch' keyword
   */
  Token get catchKeyword => _catchKeyword;

  /**
   * Return the comma.
   * @return the comma
   */
  Token get comma => _comma;
  Token get endToken => _body.endToken;

  /**
   * Return the parameter whose value will be the exception that was thrown.
   * @return the parameter whose value will be the exception that was thrown
   */
  SimpleIdentifier get exceptionParameter => _exceptionParameter;

  /**
   * Return the type of exceptions caught by this catch clause, or {@code null} if this catch clause
   * catches every type of exception.
   * @return the type of exceptions caught by this catch clause
   */
  TypeName get exceptionType => _exceptionType;

  /**
   * Return the left parenthesis.
   * @return the left parenthesis
   */
  Token get leftParenthesis => _leftParenthesis;

  /**
   * Return the token representing the 'on' keyword, or {@code null} if there is no 'on' keyword.
   * @return the token representing the 'on' keyword
   */
  Token get onKeyword => _onKeyword;

  /**
   * Return the right parenthesis.
   * @return the right parenthesis
   */
  Token get rightParenthesis => _rightParenthesis;

  /**
   * Return the parameter whose value will be the stack trace associated with the exception.
   * @return the parameter whose value will be the stack trace associated with the exception
   */
  SimpleIdentifier get stackTraceParameter => _stackTraceParameter;

  /**
   * Set the body of the catch block to the given block.
   * @param block the body of the catch block
   */
  void set body(Block block) {
    _body = becomeParentOf(block);
  }

  /**
   * Set the token representing the 'catch' keyword to the given token.
   * @param catchKeyword the token representing the 'catch' keyword
   */
  void set catchKeyword(Token catchKeyword2) {
    this._catchKeyword = catchKeyword2;
  }

  /**
   * Set the comma to the given token.
   * @param comma the comma
   */
  void set comma(Token comma2) {
    this._comma = comma2;
  }

  /**
   * Set the parameter whose value will be the exception that was thrown to the given parameter.
   * @param parameter the parameter whose value will be the exception that was thrown
   */
  void set exceptionParameter(SimpleIdentifier parameter) {
    _exceptionParameter = becomeParentOf(parameter);
  }

  /**
   * Set the type of exceptions caught by this catch clause to the given type.
   * @param exceptionType the type of exceptions caught by this catch clause
   */
  void set exceptionType(TypeName exceptionType2) {
    this._exceptionType = exceptionType2;
  }

  /**
   * Set the left parenthesis to the given token.
   * @param parenthesis the left parenthesis
   */
  void set leftParenthesis(Token parenthesis) {
    _leftParenthesis = parenthesis;
  }

  /**
   * Set the token representing the 'on' keyword to the given keyword.
   * @param onKeyword the token representing the 'on' keyword
   */
  void set onKeyword(Token onKeyword2) {
    this._onKeyword = onKeyword2;
  }

  /**
   * Set the right parenthesis to the given token.
   * @param parenthesis the right parenthesis
   */
  void set rightParenthesis(Token parenthesis) {
    _rightParenthesis = parenthesis;
  }

  /**
   * Set the parameter whose value will be the stack trace associated with the exception to the
   * given parameter.
   * @param parameter the parameter whose value will be the stack trace associated with the
   * exception
   */
  void set stackTraceParameter(SimpleIdentifier parameter) {
    _stackTraceParameter = becomeParentOf(parameter);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_exceptionType, visitor);
    safelyVisitChild(_exceptionParameter, visitor);
    safelyVisitChild(_stackTraceParameter, visitor);
    safelyVisitChild(_body, visitor);
  }
}
/**
 * Instances of the class {@code ClassDeclaration} represent the declaration of a class.
 * <pre>
 * classDeclaration ::=
 * 'abstract'? 'class' {@link SimpleIdentifier name} {@link TypeParameterList typeParameterList}?
 * ({@link ExtendsClause extendsClause} {@link WithClause withClause}?)?{@link ImplementsClause implementsClause}?
 * '{' {@link ClassMember classMember}* '}'
 * </pre>
 * @coverage dart.engine.ast
 */
class ClassDeclaration extends CompilationUnitMember {

  /**
   * The 'abstract' keyword, or {@code null} if the keyword was absent.
   */
  Token _abstractKeyword;

  /**
   * The token representing the 'class' keyword.
   */
  Token _classKeyword;

  /**
   * The name of the class being declared.
   */
  SimpleIdentifier _name;

  /**
   * The type parameters for the class, or {@code null} if the class does not have any type
   * parameters.
   */
  TypeParameterList _typeParameters;

  /**
   * The extends clause for the class, or {@code null} if the class does not extend any other class.
   */
  ExtendsClause _extendsClause;

  /**
   * The with clause for the class, or {@code null} if the class does not have a with clause.
   */
  WithClause _withClause;

  /**
   * The implements clause for the class, or {@code null} if the class does not implement any
   * interfaces.
   */
  ImplementsClause _implementsClause;

  /**
   * The left curly bracket.
   */
  Token _leftBracket;

  /**
   * The members defined by the class.
   */
  NodeList<ClassMember> _members;

  /**
   * The right curly bracket.
   */
  Token _rightBracket;

  /**
   * Initialize a newly created class declaration.
   * @param comment the documentation comment associated with this class
   * @param metadata the annotations associated with this class
   * @param abstractKeyword the 'abstract' keyword, or {@code null} if the keyword was absent
   * @param classKeyword the token representing the 'class' keyword
   * @param name the name of the class being declared
   * @param typeParameters the type parameters for the class
   * @param extendsClause the extends clause for the class
   * @param withClause the with clause for the class
   * @param implementsClause the implements clause for the class
   * @param leftBracket the left curly bracket
   * @param members the members defined by the class
   * @param rightBracket the right curly bracket
   */
  ClassDeclaration.full(Comment comment, List<Annotation> metadata, Token abstractKeyword, Token classKeyword, SimpleIdentifier name, TypeParameterList typeParameters, ExtendsClause extendsClause, WithClause withClause, ImplementsClause implementsClause, Token leftBracket, List<ClassMember> members, Token rightBracket) : super.full(comment, metadata) {
    this._members = new NodeList<ClassMember>(this);
    this._abstractKeyword = abstractKeyword;
    this._classKeyword = classKeyword;
    this._name = becomeParentOf(name);
    this._typeParameters = becomeParentOf(typeParameters);
    this._extendsClause = becomeParentOf(extendsClause);
    this._withClause = becomeParentOf(withClause);
    this._implementsClause = becomeParentOf(implementsClause);
    this._leftBracket = leftBracket;
    this._members.addAll(members);
    this._rightBracket = rightBracket;
  }

  /**
   * Initialize a newly created class declaration.
   * @param comment the documentation comment associated with this class
   * @param metadata the annotations associated with this class
   * @param abstractKeyword the 'abstract' keyword, or {@code null} if the keyword was absent
   * @param classKeyword the token representing the 'class' keyword
   * @param name the name of the class being declared
   * @param typeParameters the type parameters for the class
   * @param extendsClause the extends clause for the class
   * @param withClause the with clause for the class
   * @param implementsClause the implements clause for the class
   * @param leftBracket the left curly bracket
   * @param members the members defined by the class
   * @param rightBracket the right curly bracket
   */
  ClassDeclaration({Comment comment, List<Annotation> metadata, Token abstractKeyword, Token classKeyword, SimpleIdentifier name, TypeParameterList typeParameters, ExtendsClause extendsClause, WithClause withClause, ImplementsClause implementsClause, Token leftBracket, List<ClassMember> members, Token rightBracket}) : this.full(comment, metadata, abstractKeyword, classKeyword, name, typeParameters, extendsClause, withClause, implementsClause, leftBracket, members, rightBracket);
  accept(ASTVisitor visitor) => visitor.visitClassDeclaration(this);

  /**
   * Return the 'abstract' keyword, or {@code null} if the keyword was absent.
   * @return the 'abstract' keyword
   */
  Token get abstractKeyword => _abstractKeyword;

  /**
   * Return the token representing the 'class' keyword.
   * @return the token representing the 'class' keyword
   */
  Token get classKeyword => _classKeyword;
  ClassElement get element => _name != null ? (_name.element as ClassElement) : null;
  Token get endToken => _rightBracket;

  /**
   * Return the extends clause for this class, or {@code null} if the class does not extend any
   * other class.
   * @return the extends clause for this class
   */
  ExtendsClause get extendsClause => _extendsClause;

  /**
   * Return the implements clause for the class, or {@code null} if the class does not implement any
   * interfaces.
   * @return the implements clause for the class
   */
  ImplementsClause get implementsClause => _implementsClause;

  /**
   * Return the left curly bracket.
   * @return the left curly bracket
   */
  Token get leftBracket => _leftBracket;

  /**
   * Return the members defined by the class.
   * @return the members defined by the class
   */
  NodeList<ClassMember> get members => _members;

  /**
   * Return the name of the class being declared.
   * @return the name of the class being declared
   */
  SimpleIdentifier get name => _name;

  /**
   * Return the right curly bracket.
   * @return the right curly bracket
   */
  Token get rightBracket => _rightBracket;

  /**
   * Return the type parameters for the class, or {@code null} if the class does not have any type
   * parameters.
   * @return the type parameters for the class
   */
  TypeParameterList get typeParameters => _typeParameters;

  /**
   * Return the with clause for the class, or {@code null} if the class does not have a with clause.
   * @return the with clause for the class
   */
  WithClause get withClause => _withClause;

  /**
   * Set the 'abstract' keyword to the given keyword.
   * @param abstractKeyword the 'abstract' keyword
   */
  void set abstractKeyword(Token abstractKeyword2) {
    this._abstractKeyword = abstractKeyword2;
  }

  /**
   * Set the token representing the 'class' keyword to the given token.
   * @param classKeyword the token representing the 'class' keyword
   */
  void set classKeyword(Token classKeyword2) {
    this._classKeyword = classKeyword2;
  }

  /**
   * Set the extends clause for this class to the given clause.
   * @param extendsClause the extends clause for this class
   */
  void set extendsClause(ExtendsClause extendsClause2) {
    this._extendsClause = becomeParentOf(extendsClause2);
  }

  /**
   * Set the implements clause for the class to the given clause.
   * @param implementsClause the implements clause for the class
   */
  void set implementsClause(ImplementsClause implementsClause2) {
    this._implementsClause = becomeParentOf(implementsClause2);
  }

  /**
   * Set the left curly bracket to the given token.
   * @param leftBracket the left curly bracket
   */
  void set leftBracket(Token leftBracket2) {
    this._leftBracket = leftBracket2;
  }

  /**
   * Set the name of the class being declared to the given identifier.
   * @param identifier the name of the class being declared
   */
  void set name(SimpleIdentifier identifier) {
    _name = becomeParentOf(identifier);
  }

  /**
   * Set the right curly bracket to the given token.
   * @param rightBracket the right curly bracket
   */
  void set rightBracket(Token rightBracket2) {
    this._rightBracket = rightBracket2;
  }

  /**
   * Set the type parameters for the class to the given list of type parameters.
   * @param typeParameters the type parameters for the class
   */
  void set typeParameters(TypeParameterList typeParameters2) {
    this._typeParameters = typeParameters2;
  }

  /**
   * Set the with clause for the class to the given clause.
   * @param withClause the with clause for the class
   */
  void set withClause(WithClause withClause2) {
    this._withClause = becomeParentOf(withClause2);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_name, visitor);
    safelyVisitChild(_typeParameters, visitor);
    safelyVisitChild(_extendsClause, visitor);
    safelyVisitChild(_withClause, visitor);
    safelyVisitChild(_implementsClause, visitor);
    members.accept(visitor);
  }
  Token get firstTokenAfterCommentAndMetadata {
    if (_abstractKeyword != null) {
      return _abstractKeyword;
    }
    return _classKeyword;
  }
}
/**
 * The abstract class {@code ClassMember} defines the behavior common to nodes that declare a name
 * within the scope of a class.
 * @coverage dart.engine.ast
 */
abstract class ClassMember extends Declaration {

  /**
   * Initialize a newly created member of a class.
   * @param comment the documentation comment associated with this member
   * @param metadata the annotations associated with this member
   */
  ClassMember.full(Comment comment, List<Annotation> metadata) : super.full(comment, metadata) {
  }

  /**
   * Initialize a newly created member of a class.
   * @param comment the documentation comment associated with this member
   * @param metadata the annotations associated with this member
   */
  ClassMember({Comment comment, List<Annotation> metadata}) : this.full(comment, metadata);
}
/**
 * Instances of the class {@code ClassTypeAlias} represent a class type alias.
 * <pre>
 * classTypeAlias ::={@link SimpleIdentifier identifier} {@link TypeParameterList typeParameters}? '=' 'abstract'? mixinApplication
 * mixinApplication ::={@link TypeName superclass} {@link WithClause withClause} {@link ImplementsClause implementsClause}? ';'
 * </pre>
 * @coverage dart.engine.ast
 */
class ClassTypeAlias extends TypeAlias {

  /**
   * The name of the class being declared.
   */
  SimpleIdentifier _name;

  /**
   * The type parameters for the class, or {@code null} if the class does not have any type
   * parameters.
   */
  TypeParameterList _typeParameters;

  /**
   * The token for the '=' separating the name from the definition.
   */
  Token _equals;

  /**
   * The token for the 'abstract' keyword, or {@code null} if this is not defining an abstract
   * class.
   */
  Token _abstractKeyword;

  /**
   * The name of the superclass of the class being declared.
   */
  TypeName _superclass;

  /**
   * The with clause for this class.
   */
  WithClause _withClause;

  /**
   * The implements clause for this class, or {@code null} if there is no implements clause.
   */
  ImplementsClause _implementsClause;

  /**
   * Initialize a newly created class type alias.
   * @param comment the documentation comment associated with this type alias
   * @param metadata the annotations associated with this type alias
   * @param keyword the token representing the 'typedef' keyword
   * @param name the name of the class being declared
   * @param typeParameters the type parameters for the class
   * @param equals the token for the '=' separating the name from the definition
   * @param abstractKeyword the token for the 'abstract' keyword
   * @param superclass the name of the superclass of the class being declared
   * @param withClause the with clause for this class
   * @param implementsClause the implements clause for this class
   * @param semicolon the semicolon terminating the declaration
   */
  ClassTypeAlias.full(Comment comment, List<Annotation> metadata, Token keyword, SimpleIdentifier name, TypeParameterList typeParameters, Token equals, Token abstractKeyword, TypeName superclass, WithClause withClause, ImplementsClause implementsClause, Token semicolon) : super.full(comment, metadata, keyword, semicolon) {
    this._name = becomeParentOf(name);
    this._typeParameters = becomeParentOf(typeParameters);
    this._equals = equals;
    this._abstractKeyword = abstractKeyword;
    this._superclass = becomeParentOf(superclass);
    this._withClause = becomeParentOf(withClause);
    this._implementsClause = becomeParentOf(implementsClause);
  }

  /**
   * Initialize a newly created class type alias.
   * @param comment the documentation comment associated with this type alias
   * @param metadata the annotations associated with this type alias
   * @param keyword the token representing the 'typedef' keyword
   * @param name the name of the class being declared
   * @param typeParameters the type parameters for the class
   * @param equals the token for the '=' separating the name from the definition
   * @param abstractKeyword the token for the 'abstract' keyword
   * @param superclass the name of the superclass of the class being declared
   * @param withClause the with clause for this class
   * @param implementsClause the implements clause for this class
   * @param semicolon the semicolon terminating the declaration
   */
  ClassTypeAlias({Comment comment, List<Annotation> metadata, Token keyword, SimpleIdentifier name, TypeParameterList typeParameters, Token equals, Token abstractKeyword, TypeName superclass, WithClause withClause, ImplementsClause implementsClause, Token semicolon}) : this.full(comment, metadata, keyword, name, typeParameters, equals, abstractKeyword, superclass, withClause, implementsClause, semicolon);
  accept(ASTVisitor visitor) => visitor.visitClassTypeAlias(this);

  /**
   * Return the token for the 'abstract' keyword, or {@code null} if this is not defining an
   * abstract class.
   * @return the token for the 'abstract' keyword
   */
  Token get abstractKeyword => _abstractKeyword;
  ClassElement get element => _name != null ? (_name.element as ClassElement) : null;

  /**
   * Return the token for the '=' separating the name from the definition.
   * @return the token for the '=' separating the name from the definition
   */
  Token get equals => _equals;

  /**
   * Return the implements clause for this class, or {@code null} if there is no implements clause.
   * @return the implements clause for this class
   */
  ImplementsClause get implementsClause => _implementsClause;

  /**
   * Return the name of the class being declared.
   * @return the name of the class being declared
   */
  SimpleIdentifier get name => _name;

  /**
   * Return the name of the superclass of the class being declared.
   * @return the name of the superclass of the class being declared
   */
  TypeName get superclass => _superclass;

  /**
   * Return the type parameters for the class, or {@code null} if the class does not have any type
   * parameters.
   * @return the type parameters for the class
   */
  TypeParameterList get typeParameters => _typeParameters;

  /**
   * Return the with clause for this class.
   * @return the with clause for this class
   */
  WithClause get withClause => _withClause;

  /**
   * Set the token for the 'abstract' keyword to the given token.
   * @param abstractKeyword the token for the 'abstract' keyword
   */
  void set abstractKeyword(Token abstractKeyword2) {
    this._abstractKeyword = abstractKeyword2;
  }

  /**
   * Set the token for the '=' separating the name from the definition to the given token.
   * @param equals the token for the '=' separating the name from the definition
   */
  void set equals(Token equals2) {
    this._equals = equals2;
  }

  /**
   * Set the implements clause for this class to the given implements clause.
   * @param implementsClause the implements clause for this class
   */
  void set implementsClause(ImplementsClause implementsClause2) {
    this._implementsClause = becomeParentOf(implementsClause2);
  }

  /**
   * Set the name of the class being declared to the given identifier.
   * @param name the name of the class being declared
   */
  void set name(SimpleIdentifier name2) {
    this._name = becomeParentOf(name2);
  }

  /**
   * Set the name of the superclass of the class being declared to the given name.
   * @param superclass the name of the superclass of the class being declared
   */
  void set superclass(TypeName superclass2) {
    this._superclass = becomeParentOf(superclass2);
  }

  /**
   * Set the type parameters for the class to the given list of parameters.
   * @param typeParameters the type parameters for the class
   */
  void set typeParameters(TypeParameterList typeParameters2) {
    this._typeParameters = becomeParentOf(typeParameters2);
  }

  /**
   * Set the with clause for this class to the given with clause.
   * @param withClause the with clause for this class
   */
  void set withClause(WithClause withClause2) {
    this._withClause = becomeParentOf(withClause2);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_name, visitor);
    safelyVisitChild(_typeParameters, visitor);
    safelyVisitChild(_superclass, visitor);
    safelyVisitChild(_withClause, visitor);
    safelyVisitChild(_implementsClause, visitor);
  }
}
/**
 * Instances of the class {@code Combinator} represent the combinator associated with an import
 * directive.
 * <pre>
 * combinator ::={@link HideCombinator hideCombinator}| {@link ShowCombinator showCombinator}</pre>
 * @coverage dart.engine.ast
 */
abstract class Combinator extends ASTNode {

  /**
   * The keyword specifying what kind of processing is to be done on the imported names.
   */
  Token _keyword;

  /**
   * Initialize a newly created import combinator.
   * @param keyword the keyword specifying what kind of processing is to be done on the imported
   * names
   */
  Combinator.full(Token keyword) {
    this._keyword = keyword;
  }

  /**
   * Initialize a newly created import combinator.
   * @param keyword the keyword specifying what kind of processing is to be done on the imported
   * names
   */
  Combinator({Token keyword}) : this.full(keyword);
  Token get beginToken => _keyword;

  /**
   * Return the keyword specifying what kind of processing is to be done on the imported names.
   * @return the keyword specifying what kind of processing is to be done on the imported names
   */
  Token get keyword => _keyword;

  /**
   * Set the keyword specifying what kind of processing is to be done on the imported names to the
   * given token.
   * @param keyword the keyword specifying what kind of processing is to be done on the imported
   * names
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }
}
/**
 * Instances of the class {@code Comment} represent a comment within the source code.
 * <pre>
 * comment ::=
 * endOfLineComment
 * | blockComment
 * | documentationComment
 * endOfLineComment ::=
 * '//' (CHARACTER - EOL)* EOL
 * blockComment ::=
 * '/ *' CHARACTER* '&#42;/'
 * documentationComment ::=
 * '/ **' (CHARACTER | {@link CommentReference commentReference})* '&#42;/'
 * | ('///' (CHARACTER - EOL)* EOL)+
 * </pre>
 * @coverage dart.engine.ast
 */
class Comment extends ASTNode {

  /**
   * Create a block comment.
   * @param tokens the tokens representing the comment
   * @return the block comment that was created
   */
  static Comment createBlockComment(List<Token> tokens) => new Comment.full(tokens, CommentType.BLOCK, null);

  /**
   * Create a documentation comment.
   * @param tokens the tokens representing the comment
   * @return the documentation comment that was created
   */
  static Comment createDocumentationComment(List<Token> tokens) => new Comment.full(tokens, CommentType.DOCUMENTATION, new List<CommentReference>());

  /**
   * Create a documentation comment.
   * @param tokens the tokens representing the comment
   * @param references the references embedded within the documentation comment
   * @return the documentation comment that was created
   */
  static Comment createDocumentationComment2(List<Token> tokens, List<CommentReference> references) => new Comment.full(tokens, CommentType.DOCUMENTATION, references);

  /**
   * Create an end-of-line comment.
   * @param tokens the tokens representing the comment
   * @return the end-of-line comment that was created
   */
  static Comment createEndOfLineComment(List<Token> tokens) => new Comment.full(tokens, CommentType.END_OF_LINE, null);

  /**
   * The tokens representing the comment.
   */
  List<Token> _tokens;

  /**
   * The type of the comment.
   */
  CommentType _type;

  /**
   * The references embedded within the documentation comment. This list will be empty unless this
   * is a documentation comment that has references embedded within it.
   */
  NodeList<CommentReference> _references;

  /**
   * Initialize a newly created comment.
   * @param tokens the tokens representing the comment
   * @param type the type of the comment
   * @param references the references embedded within the documentation comment
   */
  Comment.full(List<Token> tokens, CommentType type, List<CommentReference> references) {
    this._references = new NodeList<CommentReference>(this);
    this._tokens = tokens;
    this._type = type;
    this._references.addAll(references);
  }

  /**
   * Initialize a newly created comment.
   * @param tokens the tokens representing the comment
   * @param type the type of the comment
   * @param references the references embedded within the documentation comment
   */
  Comment({List<Token> tokens, CommentType type, List<CommentReference> references}) : this.full(tokens, type, references);
  accept(ASTVisitor visitor) => visitor.visitComment(this);
  Token get beginToken => _tokens[0];
  Token get endToken => _tokens[_tokens.length - 1];

  /**
   * Return the references embedded within the documentation comment.
   * @return the references embedded within the documentation comment
   */
  NodeList<CommentReference> get references => _references;

  /**
   * Return the tokens representing the comment.
   * @return the tokens representing the comment
   */
  List<Token> get tokens => _tokens;

  /**
   * Return {@code true} if this is a block comment.
   * @return {@code true} if this is a block comment
   */
  bool isBlock() => identical(_type, CommentType.BLOCK);

  /**
   * Return {@code true} if this is a documentation comment.
   * @return {@code true} if this is a documentation comment
   */
  bool isDocumentation() => identical(_type, CommentType.DOCUMENTATION);

  /**
   * Return {@code true} if this is an end-of-line comment.
   * @return {@code true} if this is an end-of-line comment
   */
  bool isEndOfLine() => identical(_type, CommentType.END_OF_LINE);
  void visitChildren(ASTVisitor<Object> visitor) {
    _references.accept(visitor);
  }
}
/**
 * The enumeration {@code CommentType} encodes all the different types of comments that are
 * recognized by the parser.
 */
class CommentType implements Comparable<CommentType> {

  /**
   * An end-of-line comment.
   */
  static final CommentType END_OF_LINE = new CommentType('END_OF_LINE', 0);

  /**
   * A block comment.
   */
  static final CommentType BLOCK = new CommentType('BLOCK', 1);

  /**
   * A documentation comment.
   */
  static final CommentType DOCUMENTATION = new CommentType('DOCUMENTATION', 2);
  static final List<CommentType> values = [END_OF_LINE, BLOCK, DOCUMENTATION];

  /// The name of this enum constant, as declared in the enum declaration.
  final String name;

  /// The position in the enum declaration.
  final int ordinal;
  CommentType(this.name, this.ordinal) {
  }
  int compareTo(CommentType other) => ordinal - other.ordinal;
  int get hashCode => ordinal;
  String toString() => name;
}
/**
 * Instances of the class {@code CommentReference} represent a reference to a Dart element that is
 * found within a documentation comment.
 * <pre>
 * commentReference ::=
 * '\[' 'new'? {@link Identifier identifier} '\]'
 * </pre>
 * @coverage dart.engine.ast
 */
class CommentReference extends ASTNode {

  /**
   * The token representing the 'new' keyword, or {@code null} if there was no 'new' keyword.
   */
  Token _newKeyword;

  /**
   * The identifier being referenced.
   */
  Identifier _identifier;

  /**
   * Initialize a newly created reference to a Dart element.
   * @param newKeyword the token representing the 'new' keyword
   * @param identifier the identifier being referenced
   */
  CommentReference.full(Token newKeyword, Identifier identifier) {
    this._newKeyword = newKeyword;
    this._identifier = becomeParentOf(identifier);
  }

  /**
   * Initialize a newly created reference to a Dart element.
   * @param newKeyword the token representing the 'new' keyword
   * @param identifier the identifier being referenced
   */
  CommentReference({Token newKeyword, Identifier identifier}) : this.full(newKeyword, identifier);
  accept(ASTVisitor visitor) => visitor.visitCommentReference(this);
  Token get beginToken => _identifier.beginToken;
  Token get endToken => _identifier.endToken;

  /**
   * Return the identifier being referenced.
   * @return the identifier being referenced
   */
  Identifier get identifier => _identifier;

  /**
   * Return the token representing the 'new' keyword, or {@code null} if there was no 'new' keyword.
   * @return the token representing the 'new' keyword
   */
  Token get newKeyword => _newKeyword;

  /**
   * Set the identifier being referenced to the given identifier.
   * @param identifier the identifier being referenced
   */
  void set identifier(Identifier identifier2) {
    identifier2 = becomeParentOf(identifier2);
  }

  /**
   * Set the token representing the 'new' keyword to the given token.
   * @param newKeyword the token representing the 'new' keyword
   */
  void set newKeyword(Token newKeyword2) {
    this._newKeyword = newKeyword2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_identifier, visitor);
  }
}
/**
 * Instances of the class {@code CompilationUnit} represent a compilation unit.
 * <p>
 * While the grammar restricts the order of the directives and declarations within a compilation
 * unit, this class does not enforce those restrictions. In particular, the children of a
 * compilation unit will be visited in lexical order even if lexical order does not conform to the
 * restrictions of the grammar.
 * <pre>
 * compilationUnit ::=
 * directives declarations
 * directives ::={@link ScriptTag scriptTag}? {@link LibraryDirective libraryDirective}? namespaceDirective* {@link PartDirective partDirective}| {@link PartOfDirective partOfDirective}namespaceDirective ::={@link ImportDirective importDirective}| {@link ExportDirective exportDirective}declarations ::={@link CompilationUnitMember compilationUnitMember}</pre>
 * @coverage dart.engine.ast
 */
class CompilationUnit extends ASTNode {

  /**
   * The first token in the token stream that was parsed to form this compilation unit.
   */
  Token _beginToken;

  /**
   * The script tag at the beginning of the compilation unit, or {@code null} if there is no script
   * tag in this compilation unit.
   */
  ScriptTag _scriptTag;

  /**
   * The directives contained in this compilation unit.
   */
  NodeList<Directive> _directives;

  /**
   * The declarations contained in this compilation unit.
   */
  NodeList<CompilationUnitMember> _declarations;

  /**
   * The last token in the token stream that was parsed to form this compilation unit. This token
   * should always have a type of {@link TokenType.EOF}.
   */
  Token _endToken;

  /**
   * The element associated with this compilation unit, or {@code null} if the AST structure has not
   * been resolved.
   */
  CompilationUnitElement _element;

  /**
   * The {@link LineInfo} for this {@link CompilationUnit}.
   */
  LineInfo _lineInfo;

  /**
   * The parsing errors encountered when the receiver was parsed.
   */
  List<AnalysisError> _parsingErrors = AnalysisError.NO_ERRORS;

  /**
   * The resolution errors encountered when the receiver was resolved.
   */
  List<AnalysisError> _resolutionErrors = AnalysisError.NO_ERRORS;

  /**
   * Initialize a newly created compilation unit to have the given directives and declarations.
   * @param beginToken the first token in the token stream
   * @param scriptTag the script tag at the beginning of the compilation unit
   * @param directives the directives contained in this compilation unit
   * @param declarations the declarations contained in this compilation unit
   * @param endToken the last token in the token stream
   */
  CompilationUnit.full(Token beginToken, ScriptTag scriptTag, List<Directive> directives, List<CompilationUnitMember> declarations, Token endToken) {
    this._directives = new NodeList<Directive>(this);
    this._declarations = new NodeList<CompilationUnitMember>(this);
    this._beginToken = beginToken;
    this._scriptTag = becomeParentOf(scriptTag);
    this._directives.addAll(directives);
    this._declarations.addAll(declarations);
    this._endToken = endToken;
  }

  /**
   * Initialize a newly created compilation unit to have the given directives and declarations.
   * @param beginToken the first token in the token stream
   * @param scriptTag the script tag at the beginning of the compilation unit
   * @param directives the directives contained in this compilation unit
   * @param declarations the declarations contained in this compilation unit
   * @param endToken the last token in the token stream
   */
  CompilationUnit({Token beginToken, ScriptTag scriptTag, List<Directive> directives, List<CompilationUnitMember> declarations, Token endToken}) : this.full(beginToken, scriptTag, directives, declarations, endToken);
  accept(ASTVisitor visitor) => visitor.visitCompilationUnit(this);
  Token get beginToken => _beginToken;

  /**
   * Return the declarations contained in this compilation unit.
   * @return the declarations contained in this compilation unit
   */
  NodeList<CompilationUnitMember> get declarations => _declarations;

  /**
   * Return the directives contained in this compilation unit.
   * @return the directives contained in this compilation unit
   */
  NodeList<Directive> get directives => _directives;

  /**
   * Return the element associated with this compilation unit, or {@code null} if the AST structure
   * has not been resolved.
   * @return the element associated with this compilation unit
   */
  CompilationUnitElement get element => _element;
  Token get endToken => _endToken;

  /**
   * Return an array containing all of the errors associated with the receiver. If the receiver has
   * not been resolved, then return {@code null}.
   * @return an array of errors (contains no {@code null}s) or {@code null} if the receiver has not
   * been resolved
   */
  List<AnalysisError> get errors {
    List<AnalysisError> parserErrors = parsingErrors;
    List<AnalysisError> resolverErrors = resolutionErrors;
    if (resolverErrors.length == 0) {
      return parserErrors;
    } else if (parserErrors.length == 0) {
      return resolverErrors;
    } else {
      List<AnalysisError> allErrors = new List<AnalysisError>(parserErrors.length + resolverErrors.length);
      JavaSystem.arraycopy(parserErrors, 0, allErrors, 0, parserErrors.length);
      JavaSystem.arraycopy(resolverErrors, 0, allErrors, parserErrors.length, resolverErrors.length);
      return allErrors;
    }
  }
  int get length {
    Token endToken = this.endToken;
    if (endToken == null) {
      return 0;
    }
    return endToken.offset + endToken.length;
  }

  /**
   * Get the {@link LineInfo} object for this compilation unit.
   * @return the associated {@link LineInfo}
   */
  LineInfo get lineInfo => _lineInfo;
  int get offset => 0;

  /**
   * Return an array containing all of the parsing errors associated with the receiver.
   * @return an array of errors (not {@code null}, contains no {@code null}s).
   */
  List<AnalysisError> get parsingErrors => _parsingErrors;

  /**
   * Return an array containing all of the resolution errors associated with the receiver. If the
   * receiver has not been resolved, then return {@code null}.
   * @return an array of errors (contains no {@code null}s) or {@code null} if the receiver has not
   * been resolved
   */
  List<AnalysisError> get resolutionErrors => _resolutionErrors;

  /**
   * Return the script tag at the beginning of the compilation unit, or {@code null} if there is no
   * script tag in this compilation unit.
   * @return the script tag at the beginning of the compilation unit
   */
  ScriptTag get scriptTag => _scriptTag;

  /**
   * Set the element associated with this compilation unit to the given element.
   * @param element the element associated with this compilation unit
   */
  void set element(CompilationUnitElement element2) {
    this._element = element2;
  }

  /**
   * Set the {@link LineInfo} object for this compilation unit.
   * @param errors LineInfo to associate with this compilation unit
   */
  void set lineInfo(LineInfo lineInfo2) {
    this._lineInfo = lineInfo2;
  }

  /**
   * Called to cache the parsing errors when the unit is parsed.
   * @param errors an array of parsing errors, if {@code null} is passed, the error array is set to
   * an empty array, {@link AnalysisError#NO_ERRORS}
   */
  void set parsingErrors(List<AnalysisError> errors) {
    _parsingErrors = errors == null ? AnalysisError.NO_ERRORS : errors;
  }

  /**
   * Called to cache the resolution errors when the unit is resolved.
   * @param errors an array of resolution errors, if {@code null} is passed, the error array is set
   * to an empty array, {@link AnalysisError#NO_ERRORS}
   */
  void set resolutionErrors(List<AnalysisError> errors) {
    _resolutionErrors = errors == null ? AnalysisError.NO_ERRORS : errors;
  }

  /**
   * Set the script tag at the beginning of the compilation unit to the given script tag.
   * @param scriptTag the script tag at the beginning of the compilation unit
   */
  void set scriptTag(ScriptTag scriptTag2) {
    this._scriptTag = becomeParentOf(scriptTag2);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_scriptTag, visitor);
    if (directivesAreBeforeDeclarations()) {
      _directives.accept(visitor);
      _declarations.accept(visitor);
    } else {
      for (ASTNode child in sortedDirectivesAndDeclarations) {
        child.accept(visitor);
      }
    }
  }

  /**
   * Return {@code true} if all of the directives are lexically before any declarations.
   * @return {@code true} if all of the directives are lexically before any declarations
   */
  bool directivesAreBeforeDeclarations() {
    if (_directives.isEmpty || _declarations.isEmpty) {
      return true;
    }
    Directive lastDirective = _directives[_directives.length - 1];
    CompilationUnitMember firstDeclaration = _declarations[0];
    return lastDirective.offset < firstDeclaration.offset;
  }

  /**
   * Return an array containing all of the directives and declarations in this compilation unit,
   * sorted in lexical order.
   * @return the directives and declarations in this compilation unit in the order in which they
   * appeared in the original source
   */
  List<ASTNode> get sortedDirectivesAndDeclarations {
    List<ASTNode> childList = new List<ASTNode>();
    childList.addAll(_directives);
    childList.addAll(_declarations);
    List<ASTNode> children = new List.from(childList);
    children.sort(ASTNode.LEXICAL_ORDER);
    return children;
  }
}
/**
 * Instances of the class {@code CompilationUnitMember} defines the behavior common to nodes that
 * declare a name within the scope of a compilation unit.
 * <pre>
 * compilationUnitMember ::={@link ClassDeclaration classDeclaration}| {@link TypeAlias typeAlias}| {@link FunctionDeclaration functionDeclaration}| {@link MethodDeclaration getOrSetDeclaration}| {@link VariableDeclaration constantsDeclaration}| {@link VariableDeclaration variablesDeclaration}</pre>
 * @coverage dart.engine.ast
 */
abstract class CompilationUnitMember extends Declaration {

  /**
   * Initialize a newly created generic compilation unit member.
   * @param comment the documentation comment associated with this member
   * @param metadata the annotations associated with this member
   */
  CompilationUnitMember.full(Comment comment, List<Annotation> metadata) : super.full(comment, metadata) {
  }

  /**
   * Initialize a newly created generic compilation unit member.
   * @param comment the documentation comment associated with this member
   * @param metadata the annotations associated with this member
   */
  CompilationUnitMember({Comment comment, List<Annotation> metadata}) : this.full(comment, metadata);
}
/**
 * Instances of the class {@code ConditionalExpression} represent a conditional expression.
 * <pre>
 * conditionalExpression ::={@link Expression condition} '?' {@link Expression thenExpression} ':' {@link Expression elseExpression}</pre>
 * @coverage dart.engine.ast
 */
class ConditionalExpression extends Expression {

  /**
   * The condition used to determine which of the expressions is executed next.
   */
  Expression _condition;

  /**
   * The token used to separate the condition from the then expression.
   */
  Token _question;

  /**
   * The expression that is executed if the condition evaluates to {@code true}.
   */
  Expression _thenExpression;

  /**
   * The token used to separate the then expression from the else expression.
   */
  Token _colon;

  /**
   * The expression that is executed if the condition evaluates to {@code false}.
   */
  Expression _elseExpression;

  /**
   * Initialize a newly created conditional expression.
   * @param condition the condition used to determine which expression is executed next
   * @param question the token used to separate the condition from the then expression
   * @param thenExpression the expression that is executed if the condition evaluates to{@code true}
   * @param colon the token used to separate the then expression from the else expression
   * @param elseExpression the expression that is executed if the condition evaluates to{@code false}
   */
  ConditionalExpression.full(Expression condition, Token question, Expression thenExpression, Token colon, Expression elseExpression) {
    this._condition = becomeParentOf(condition);
    this._question = question;
    this._thenExpression = becomeParentOf(thenExpression);
    this._colon = colon;
    this._elseExpression = becomeParentOf(elseExpression);
  }

  /**
   * Initialize a newly created conditional expression.
   * @param condition the condition used to determine which expression is executed next
   * @param question the token used to separate the condition from the then expression
   * @param thenExpression the expression that is executed if the condition evaluates to{@code true}
   * @param colon the token used to separate the then expression from the else expression
   * @param elseExpression the expression that is executed if the condition evaluates to{@code false}
   */
  ConditionalExpression({Expression condition, Token question, Expression thenExpression, Token colon, Expression elseExpression}) : this.full(condition, question, thenExpression, colon, elseExpression);
  accept(ASTVisitor visitor) => visitor.visitConditionalExpression(this);
  Token get beginToken => _condition.beginToken;

  /**
   * Return the token used to separate the then expression from the else expression.
   * @return the token used to separate the then expression from the else expression
   */
  Token get colon => _colon;

  /**
   * Return the condition used to determine which of the expressions is executed next.
   * @return the condition used to determine which expression is executed next
   */
  Expression get condition => _condition;

  /**
   * Return the expression that is executed if the condition evaluates to {@code false}.
   * @return the expression that is executed if the condition evaluates to {@code false}
   */
  Expression get elseExpression => _elseExpression;
  Token get endToken => _elseExpression.endToken;

  /**
   * Return the token used to separate the condition from the then expression.
   * @return the token used to separate the condition from the then expression
   */
  Token get question => _question;

  /**
   * Return the expression that is executed if the condition evaluates to {@code true}.
   * @return the expression that is executed if the condition evaluates to {@code true}
   */
  Expression get thenExpression => _thenExpression;

  /**
   * Set the token used to separate the then expression from the else expression to the given token.
   * @param colon the token used to separate the then expression from the else expression
   */
  void set colon(Token colon2) {
    this._colon = colon2;
  }

  /**
   * Set the condition used to determine which of the expressions is executed next to the given
   * expression.
   * @param expression the condition used to determine which expression is executed next
   */
  void set condition(Expression expression) {
    _condition = becomeParentOf(expression);
  }

  /**
   * Set the expression that is executed if the condition evaluates to {@code false} to the given
   * expression.
   * @param expression the expression that is executed if the condition evaluates to {@code false}
   */
  void set elseExpression(Expression expression) {
    _elseExpression = becomeParentOf(expression);
  }

  /**
   * Set the token used to separate the condition from the then expression to the given token.
   * @param question the token used to separate the condition from the then expression
   */
  void set question(Token question2) {
    this._question = question2;
  }

  /**
   * Set the expression that is executed if the condition evaluates to {@code true} to the given
   * expression.
   * @param expression the expression that is executed if the condition evaluates to {@code true}
   */
  void set thenExpression(Expression expression) {
    _thenExpression = becomeParentOf(expression);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_condition, visitor);
    safelyVisitChild(_thenExpression, visitor);
    safelyVisitChild(_elseExpression, visitor);
  }
}
/**
 * Instances of the class {@code ConstructorDeclaration} represent a constructor declaration.
 * <pre>
 * constructorDeclaration ::=
 * constructorSignature {@link FunctionBody body}?
 * | constructorName formalParameterList ':' 'this' ('.' {@link SimpleIdentifier name})? arguments
 * constructorSignature ::=
 * 'external'? constructorName formalParameterList initializerList?
 * | 'external'? 'factory' factoryName formalParameterList initializerList?
 * | 'external'? 'const'  constructorName formalParameterList initializerList?
 * constructorName ::={@link SimpleIdentifier returnType} ('.' {@link SimpleIdentifier name})?
 * factoryName ::={@link Identifier returnType} ('.' {@link SimpleIdentifier name})?
 * initializerList ::=
 * ':' {@link ConstructorInitializer initializer} (',' {@link ConstructorInitializer initializer})
 * </pre>
 * @coverage dart.engine.ast
 */
class ConstructorDeclaration extends ClassMember {

  /**
   * The token for the 'external' keyword, or {@code null} if the constructor is not external.
   */
  Token _externalKeyword;

  /**
   * The token for the 'const' keyword, or {@code null} if the constructor is not a const
   * constructor.
   */
  Token _constKeyword;

  /**
   * The token for the 'factory' keyword, or {@code null} if the constructor is not a factory
   * constructor.
   */
  Token _factoryKeyword;

  /**
   * The type of object being created. This can be different than the type in which the constructor
   * is being declared if the constructor is the implementation of a factory constructor.
   */
  Identifier _returnType;

  /**
   * The token for the period before the constructor name, or {@code null} if the constructor being
   * declared is unnamed.
   */
  Token _period;

  /**
   * The name of the constructor, or {@code null} if the constructor being declared is unnamed.
   */
  SimpleIdentifier _name;

  /**
   * The element associated with this constructor, or {@code null} if the AST structure has not been
   * resolved or if this constructor could not be resolved.
   */
  ConstructorElement _element;

  /**
   * The parameters associated with the constructor.
   */
  FormalParameterList _parameters;

  /**
   * The token for the separator (colon or equals) before the initializers, or {@code null} if there
   * are no initializers.
   */
  Token _separator;

  /**
   * The initializers associated with the constructor.
   */
  NodeList<ConstructorInitializer> _initializers;

  /**
   * The name of the constructor to which this constructor will be redirected, or {@code null} if
   * this is not a redirecting factory constructor.
   */
  ConstructorName _redirectedConstructor;

  /**
   * The body of the constructor, or {@code null} if the constructor does not have a body.
   */
  FunctionBody _body;

  /**
   * Initialize a newly created constructor declaration.
   * @param externalKeyword the token for the 'external' keyword
   * @param comment the documentation comment associated with this constructor
   * @param metadata the annotations associated with this constructor
   * @param constKeyword the token for the 'const' keyword
   * @param factoryKeyword the token for the 'factory' keyword
   * @param returnType the return type of the constructor
   * @param period the token for the period before the constructor name
   * @param name the name of the constructor
   * @param parameters the parameters associated with the constructor
   * @param separator the token for the colon or equals before the initializers
   * @param initializers the initializers associated with the constructor
   * @param redirectedConstructor the name of the constructor to which this constructor will be
   * redirected
   * @param body the body of the constructor
   */
  ConstructorDeclaration.full(Comment comment, List<Annotation> metadata, Token externalKeyword, Token constKeyword, Token factoryKeyword, Identifier returnType, Token period, SimpleIdentifier name, FormalParameterList parameters, Token separator, List<ConstructorInitializer> initializers, ConstructorName redirectedConstructor, FunctionBody body) : super.full(comment, metadata) {
    this._initializers = new NodeList<ConstructorInitializer>(this);
    this._externalKeyword = externalKeyword;
    this._constKeyword = constKeyword;
    this._factoryKeyword = factoryKeyword;
    this._returnType = becomeParentOf(returnType);
    this._period = period;
    this._name = becomeParentOf(name);
    this._parameters = becomeParentOf(parameters);
    this._separator = separator;
    this._initializers.addAll(initializers);
    this._redirectedConstructor = becomeParentOf(redirectedConstructor);
    this._body = becomeParentOf(body);
  }

  /**
   * Initialize a newly created constructor declaration.
   * @param externalKeyword the token for the 'external' keyword
   * @param comment the documentation comment associated with this constructor
   * @param metadata the annotations associated with this constructor
   * @param constKeyword the token for the 'const' keyword
   * @param factoryKeyword the token for the 'factory' keyword
   * @param returnType the return type of the constructor
   * @param period the token for the period before the constructor name
   * @param name the name of the constructor
   * @param parameters the parameters associated with the constructor
   * @param separator the token for the colon or equals before the initializers
   * @param initializers the initializers associated with the constructor
   * @param redirectedConstructor the name of the constructor to which this constructor will be
   * redirected
   * @param body the body of the constructor
   */
  ConstructorDeclaration({Comment comment, List<Annotation> metadata, Token externalKeyword, Token constKeyword, Token factoryKeyword, Identifier returnType, Token period, SimpleIdentifier name, FormalParameterList parameters, Token separator, List<ConstructorInitializer> initializers, ConstructorName redirectedConstructor, FunctionBody body}) : this.full(comment, metadata, externalKeyword, constKeyword, factoryKeyword, returnType, period, name, parameters, separator, initializers, redirectedConstructor, body);
  accept(ASTVisitor visitor) => visitor.visitConstructorDeclaration(this);

  /**
   * Return the body of the constructor, or {@code null} if the constructor does not have a body.
   * @return the body of the constructor
   */
  FunctionBody get body => _body;

  /**
   * Return the token for the 'const' keyword.
   * @return the token for the 'const' keyword
   */
  Token get constKeyword => _constKeyword;
  ConstructorElement get element => _element;
  Token get endToken {
    if (_body != null) {
      return _body.endToken;
    } else if (!_initializers.isEmpty) {
      return _initializers.endToken;
    }
    return _parameters.endToken;
  }

  /**
   * Return the token for the 'external' keyword, or {@code null} if the constructor is not
   * external.
   * @return the token for the 'external' keyword
   */
  Token get externalKeyword => _externalKeyword;

  /**
   * Return the token for the 'factory' keyword.
   * @return the token for the 'factory' keyword
   */
  Token get factoryKeyword => _factoryKeyword;

  /**
   * Return the initializers associated with the constructor.
   * @return the initializers associated with the constructor
   */
  NodeList<ConstructorInitializer> get initializers => _initializers;

  /**
   * Return the name of the constructor, or {@code null} if the constructor being declared is
   * unnamed.
   * @return the name of the constructor
   */
  SimpleIdentifier get name => _name;

  /**
   * Return the parameters associated with the constructor.
   * @return the parameters associated with the constructor
   */
  FormalParameterList get parameters => _parameters;

  /**
   * Return the token for the period before the constructor name, or {@code null} if the constructor
   * being declared is unnamed.
   * @return the token for the period before the constructor name
   */
  Token get period => _period;

  /**
   * Return the name of the constructor to which this constructor will be redirected, or{@code null} if this is not a redirecting factory constructor.
   * @return the name of the constructor to which this constructor will be redirected
   */
  ConstructorName get redirectedConstructor => _redirectedConstructor;

  /**
   * Return the type of object being created. This can be different than the type in which the
   * constructor is being declared if the constructor is the implementation of a factory
   * constructor.
   * @return the type of object being created
   */
  Identifier get returnType => _returnType;

  /**
   * Return the token for the separator (colon or equals) before the initializers, or {@code null}if there are no initializers.
   * @return the token for the separator (colon or equals) before the initializers
   */
  Token get separator => _separator;

  /**
   * Set the body of the constructor to the given function body.
   * @param functionBody the body of the constructor
   */
  void set body(FunctionBody functionBody) {
    _body = becomeParentOf(functionBody);
  }

  /**
   * Set the token for the 'const' keyword to the given token.
   * @param constKeyword the token for the 'const' keyword
   */
  void set constKeyword(Token constKeyword2) {
    this._constKeyword = constKeyword2;
  }

  /**
   * Set the element associated with this constructor to the given element.
   * @param element the element associated with this constructor
   */
  void set element(ConstructorElement element2) {
    this._element = element2;
  }

  /**
   * Set the token for the 'external' keyword to the given token.
   * @param externalKeyword the token for the 'external' keyword
   */
  void set externalKeyword(Token externalKeyword2) {
    this._externalKeyword = externalKeyword2;
  }

  /**
   * Set the token for the 'factory' keyword to the given token.
   * @param factoryKeyword the token for the 'factory' keyword
   */
  void set factoryKeyword(Token factoryKeyword2) {
    this._factoryKeyword = factoryKeyword2;
  }

  /**
   * Set the name of the constructor to the given identifier.
   * @param identifier the name of the constructor
   */
  void set name(SimpleIdentifier identifier) {
    _name = becomeParentOf(identifier);
  }

  /**
   * Set the parameters associated with the constructor to the given list of parameters.
   * @param parameters the parameters associated with the constructor
   */
  void set parameters(FormalParameterList parameters2) {
    this._parameters = becomeParentOf(parameters2);
  }

  /**
   * Set the token for the period before the constructor name to the given token.
   * @param period the token for the period before the constructor name
   */
  void set period(Token period2) {
    this._period = period2;
  }

  /**
   * Set the name of the constructor to which this constructor will be redirected to the given
   * constructor name.
   * @param redirectedConstructor the name of the constructor to which this constructor will be
   * redirected
   */
  void set redirectedConstructor(ConstructorName redirectedConstructor2) {
    this._redirectedConstructor = becomeParentOf(redirectedConstructor2);
  }

  /**
   * Set the type of object being created to the given type name.
   * @param typeName the type of object being created
   */
  void set returnType(Identifier typeName) {
    _returnType = becomeParentOf(typeName);
  }

  /**
   * Set the token for the separator (colon or equals) before the initializers to the given token.
   * @param separator the token for the separator (colon or equals) before the initializers
   */
  void set separator(Token separator2) {
    this._separator = separator2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_returnType, visitor);
    safelyVisitChild(_name, visitor);
    safelyVisitChild(_parameters, visitor);
    _initializers.accept(visitor);
    safelyVisitChild(_redirectedConstructor, visitor);
    safelyVisitChild(_body, visitor);
  }
  Token get firstTokenAfterCommentAndMetadata {
    Token leftMost2 = leftMost([_externalKeyword, _constKeyword, _factoryKeyword]);
    if (leftMost2 != null) {
      return leftMost2;
    }
    return _returnType.beginToken;
  }

  /**
   * Return the left-most of the given tokens, or {@code null} if there are no tokens given or if
   * all of the given tokens are {@code null}.
   * @param tokens the tokens being compared to find the left-most token
   * @return the left-most of the given tokens
   */
  Token leftMost(List<Token> tokens) {
    Token leftMost = null;
    int offset = 2147483647;
    for (Token token in tokens) {
      if (token != null && token.offset < offset) {
        leftMost = token;
      }
    }
    return leftMost;
  }
}
/**
 * Instances of the class {@code ConstructorFieldInitializer} represent the initialization of a
 * field within a constructor's initialization list.
 * <pre>
 * fieldInitializer ::=
 * ('this' '.')? {@link SimpleIdentifier fieldName} '=' {@link Expression conditionalExpression cascadeSection*}</pre>
 * @coverage dart.engine.ast
 */
class ConstructorFieldInitializer extends ConstructorInitializer {

  /**
   * The token for the 'this' keyword, or {@code null} if there is no 'this' keyword.
   */
  Token _keyword;

  /**
   * The token for the period after the 'this' keyword, or {@code null} if there is no 'this'
   * keyword.
   */
  Token _period;

  /**
   * The name of the field being initialized.
   */
  SimpleIdentifier _fieldName;

  /**
   * The token for the equal sign between the field name and the expression.
   */
  Token _equals;

  /**
   * The expression computing the value to which the field will be initialized.
   */
  Expression _expression;

  /**
   * Initialize a newly created field initializer to initialize the field with the given name to the
   * value of the given expression.
   * @param keyword the token for the 'this' keyword
   * @param period the token for the period after the 'this' keyword
   * @param fieldName the name of the field being initialized
   * @param equals the token for the equal sign between the field name and the expression
   * @param expression the expression computing the value to which the field will be initialized
   */
  ConstructorFieldInitializer.full(Token keyword, Token period, SimpleIdentifier fieldName, Token equals, Expression expression) {
    this._keyword = keyword;
    this._period = period;
    this._fieldName = becomeParentOf(fieldName);
    this._equals = equals;
    this._expression = becomeParentOf(expression);
  }

  /**
   * Initialize a newly created field initializer to initialize the field with the given name to the
   * value of the given expression.
   * @param keyword the token for the 'this' keyword
   * @param period the token for the period after the 'this' keyword
   * @param fieldName the name of the field being initialized
   * @param equals the token for the equal sign between the field name and the expression
   * @param expression the expression computing the value to which the field will be initialized
   */
  ConstructorFieldInitializer({Token keyword, Token period, SimpleIdentifier fieldName, Token equals, Expression expression}) : this.full(keyword, period, fieldName, equals, expression);
  accept(ASTVisitor visitor) => visitor.visitConstructorFieldInitializer(this);
  Token get beginToken {
    if (_keyword != null) {
      return _keyword;
    }
    return _fieldName.beginToken;
  }
  Token get endToken => _expression.endToken;

  /**
   * Return the token for the equal sign between the field name and the expression.
   * @return the token for the equal sign between the field name and the expression
   */
  Token get equals => _equals;

  /**
   * Return the expression computing the value to which the field will be initialized.
   * @return the expression computing the value to which the field will be initialized
   */
  Expression get expression => _expression;

  /**
   * Return the name of the field being initialized.
   * @return the name of the field being initialized
   */
  SimpleIdentifier get fieldName => _fieldName;

  /**
   * Return the token for the 'this' keyword, or {@code null} if there is no 'this' keyword.
   * @return the token for the 'this' keyword
   */
  Token get keyword => _keyword;

  /**
   * Return the token for the period after the 'this' keyword, or {@code null} if there is no 'this'
   * keyword.
   * @return the token for the period after the 'this' keyword
   */
  Token get period => _period;

  /**
   * Set the token for the equal sign between the field name and the expression to the given token.
   * @param equals the token for the equal sign between the field name and the expression
   */
  void set equals(Token equals2) {
    this._equals = equals2;
  }

  /**
   * Set the expression computing the value to which the field will be initialized to the given
   * expression.
   * @param expression the expression computing the value to which the field will be initialized
   */
  void set expression(Expression expression2) {
    this._expression = becomeParentOf(expression2);
  }

  /**
   * Set the name of the field being initialized to the given identifier.
   * @param identifier the name of the field being initialized
   */
  void set fieldName(SimpleIdentifier identifier) {
    _fieldName = becomeParentOf(identifier);
  }

  /**
   * Set the token for the 'this' keyword to the given token.
   * @param keyword the token for the 'this' keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }

  /**
   * Set the token for the period after the 'this' keyword to the given token.
   * @param period the token for the period after the 'this' keyword
   */
  void set period(Token period2) {
    this._period = period2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_fieldName, visitor);
    safelyVisitChild(_expression, visitor);
  }
}
/**
 * Instances of the class {@code ConstructorInitializer} defines the behavior of nodes that can
 * occur in the initializer list of a constructor declaration.
 * <pre>
 * constructorInitializer ::={@link SuperConstructorInvocation superInvocation}| {@link ConstructorFieldInitializer fieldInitializer}</pre>
 * @coverage dart.engine.ast
 */
abstract class ConstructorInitializer extends ASTNode {
}
/**
 * Instances of the class {@code ConstructorName} represent the name of the constructor.
 * <pre>
 * constructorName:
 * type ('.' identifier)?
 * </pre>
 * @coverage dart.engine.ast
 */
class ConstructorName extends ASTNode {

  /**
   * The name of the type defining the constructor.
   */
  TypeName _type;

  /**
   * The token for the period before the constructor name, or {@code null} if the specified
   * constructor is the unnamed constructor.
   */
  Token _period;

  /**
   * The name of the constructor, or {@code null} if the specified constructor is the unnamed
   * constructor.
   */
  SimpleIdentifier _name;

  /**
   * The element associated with this constructor name based on static type information, or{@code null} if the AST structure has not been resolved or if this constructor name could not
   * be resolved.
   */
  ConstructorElement _staticElement;

  /**
   * The element associated with this constructor name based on propagated type information, or{@code null} if the AST structure has not been resolved or if this constructor name could not
   * be resolved.
   */
  ConstructorElement _propagatedElement;

  /**
   * Initialize a newly created constructor name.
   * @param type the name of the type defining the constructor
   * @param period the token for the period before the constructor name
   * @param name the name of the constructor
   */
  ConstructorName.full(TypeName type, Token period, SimpleIdentifier name) {
    this._type = becomeParentOf(type);
    this._period = period;
    this._name = becomeParentOf(name);
  }

  /**
   * Initialize a newly created constructor name.
   * @param type the name of the type defining the constructor
   * @param period the token for the period before the constructor name
   * @param name the name of the constructor
   */
  ConstructorName({TypeName type, Token period, SimpleIdentifier name}) : this.full(type, period, name);
  accept(ASTVisitor visitor) => visitor.visitConstructorName(this);
  Token get beginToken => _type.beginToken;

  /**
   * Return the element associated with this constructor name based on propagated type information,
   * or {@code null} if the AST structure has not been resolved or if this constructor name could
   * not be resolved.
   * @return the element associated with this constructor name
   */
  ConstructorElement get element => _propagatedElement;
  Token get endToken {
    if (_name != null) {
      return _name.endToken;
    }
    return _type.endToken;
  }

  /**
   * Return the name of the constructor, or {@code null} if the specified constructor is the unnamed
   * constructor.
   * @return the name of the constructor
   */
  SimpleIdentifier get name => _name;

  /**
   * Return the token for the period before the constructor name, or {@code null} if the specified
   * constructor is the unnamed constructor.
   * @return the token for the period before the constructor name
   */
  Token get period => _period;

  /**
   * Return the element associated with this constructor name based on static type information, or{@code null} if the AST structure has not been resolved or if this constructor name could not
   * be resolved.
   * @return the element associated with this constructor name
   */
  ConstructorElement get staticElement => _staticElement;

  /**
   * Return the name of the type defining the constructor.
   * @return the name of the type defining the constructor
   */
  TypeName get type => _type;

  /**
   * Set the element associated with this constructor name based on propagated type information to
   * the given element.
   * @param element the element to be associated with this constructor name
   */
  void set element(ConstructorElement element2) {
    _propagatedElement = element2;
  }

  /**
   * Set the name of the constructor to the given name.
   * @param name the name of the constructor
   */
  void set name(SimpleIdentifier name2) {
    this._name = becomeParentOf(name2);
  }

  /**
   * Return the token for the period before the constructor name to the given token.
   * @param period the token for the period before the constructor name
   */
  void set period(Token period2) {
    this._period = period2;
  }

  /**
   * Set the element associated with this constructor name based on static type information to the
   * given element.
   * @param element the element to be associated with this constructor name
   */
  void set staticElement(ConstructorElement element) {
    _staticElement = element;
  }

  /**
   * Set the name of the type defining the constructor to the given type name.
   * @param type the name of the type defining the constructor
   */
  void set type(TypeName type2) {
    this._type = becomeParentOf(type2);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_type, visitor);
    safelyVisitChild(_name, visitor);
  }
}
/**
 * Instances of the class {@code ContinueStatement} represent a continue statement.
 * <pre>
 * continueStatement ::=
 * 'continue' {@link SimpleIdentifier label}? ';'
 * </pre>
 * @coverage dart.engine.ast
 */
class ContinueStatement extends Statement {

  /**
   * The token representing the 'continue' keyword.
   */
  Token _keyword;

  /**
   * The label associated with the statement, or {@code null} if there is no label.
   */
  SimpleIdentifier _label;

  /**
   * The semicolon terminating the statement.
   */
  Token _semicolon;

  /**
   * Initialize a newly created continue statement.
   * @param keyword the token representing the 'continue' keyword
   * @param label the label associated with the statement
   * @param semicolon the semicolon terminating the statement
   */
  ContinueStatement.full(Token keyword, SimpleIdentifier label, Token semicolon) {
    this._keyword = keyword;
    this._label = becomeParentOf(label);
    this._semicolon = semicolon;
  }

  /**
   * Initialize a newly created continue statement.
   * @param keyword the token representing the 'continue' keyword
   * @param label the label associated with the statement
   * @param semicolon the semicolon terminating the statement
   */
  ContinueStatement({Token keyword, SimpleIdentifier label, Token semicolon}) : this.full(keyword, label, semicolon);
  accept(ASTVisitor visitor) => visitor.visitContinueStatement(this);
  Token get beginToken => _keyword;
  Token get endToken => _semicolon;

  /**
   * Return the token representing the 'continue' keyword.
   * @return the token representing the 'continue' keyword
   */
  Token get keyword => _keyword;

  /**
   * Return the label associated with the statement, or {@code null} if there is no label.
   * @return the label associated with the statement
   */
  SimpleIdentifier get label => _label;

  /**
   * Return the semicolon terminating the statement.
   * @return the semicolon terminating the statement
   */
  Token get semicolon => _semicolon;

  /**
   * Set the token representing the 'continue' keyword to the given token.
   * @param keyword the token representing the 'continue' keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }

  /**
   * Set the label associated with the statement to the given label.
   * @param identifier the label associated with the statement
   */
  void set label(SimpleIdentifier identifier) {
    _label = becomeParentOf(identifier);
  }

  /**
   * Set the semicolon terminating the statement to the given token.
   * @param semicolon the semicolon terminating the statement
   */
  void set semicolon(Token semicolon2) {
    this._semicolon = semicolon2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_label, visitor);
  }
}
/**
 * The abstract class {@code Declaration} defines the behavior common to nodes that represent the
 * declaration of a name. Each declared name is visible within a name scope.
 * @coverage dart.engine.ast
 */
abstract class Declaration extends AnnotatedNode {

  /**
   * Initialize a newly created declaration.
   * @param comment the documentation comment associated with this declaration
   * @param metadata the annotations associated with this declaration
   */
  Declaration.full(Comment comment, List<Annotation> metadata) : super.full(comment, metadata) {
  }

  /**
   * Initialize a newly created declaration.
   * @param comment the documentation comment associated with this declaration
   * @param metadata the annotations associated with this declaration
   */
  Declaration({Comment comment, List<Annotation> metadata}) : this.full(comment, metadata);

  /**
   * Return the element associated with this declaration, or {@code null} if either this node
   * corresponds to a list of declarations or if the AST structure has not been resolved.
   * @return the element associated with this declaration
   */
  Element get element;
}
/**
 * Instances of the class {@code DeclaredIdentifier} represent the declaration of a single
 * identifier.
 * <pre>
 * declaredIdentifier ::=
 * ({@link Annotation metadata} finalConstVarOrType {@link SimpleIdentifier identifier}</pre>
 * @coverage dart.engine.ast
 */
class DeclaredIdentifier extends Declaration {

  /**
   * The token representing either the 'final', 'const' or 'var' keyword, or {@code null} if no
   * keyword was used.
   */
  Token _keyword;

  /**
   * The name of the declared type of the parameter, or {@code null} if the parameter does not have
   * a declared type.
   */
  TypeName _type;

  /**
   * The name of the variable being declared.
   */
  SimpleIdentifier _identifier;

  /**
   * Initialize a newly created formal parameter.
   * @param comment the documentation comment associated with this parameter
   * @param metadata the annotations associated with this parameter
   * @param keyword the token representing either the 'final', 'const' or 'var' keyword
   * @param type the name of the declared type of the parameter
   * @param identifier the name of the parameter being declared
   */
  DeclaredIdentifier.full(Comment comment, List<Annotation> metadata, Token keyword, TypeName type, SimpleIdentifier identifier) : super.full(comment, metadata) {
    this._keyword = keyword;
    this._type = becomeParentOf(type);
    this._identifier = becomeParentOf(identifier);
  }

  /**
   * Initialize a newly created formal parameter.
   * @param comment the documentation comment associated with this parameter
   * @param metadata the annotations associated with this parameter
   * @param keyword the token representing either the 'final', 'const' or 'var' keyword
   * @param type the name of the declared type of the parameter
   * @param identifier the name of the parameter being declared
   */
  DeclaredIdentifier({Comment comment, List<Annotation> metadata, Token keyword, TypeName type, SimpleIdentifier identifier}) : this.full(comment, metadata, keyword, type, identifier);
  accept(ASTVisitor visitor) => visitor.visitDeclaredIdentifier(this);
  LocalVariableElement get element {
    SimpleIdentifier identifier = this.identifier;
    if (identifier == null) {
      return null;
    }
    return identifier.element as LocalVariableElement;
  }
  Token get endToken => _identifier.endToken;

  /**
   * Return the name of the variable being declared.
   * @return the name of the variable being declared
   */
  SimpleIdentifier get identifier => _identifier;

  /**
   * Return the token representing either the 'final', 'const' or 'var' keyword.
   * @return the token representing either the 'final', 'const' or 'var' keyword
   */
  Token get keyword => _keyword;

  /**
   * Return the name of the declared type of the parameter, or {@code null} if the parameter does
   * not have a declared type.
   * @return the name of the declared type of the parameter
   */
  TypeName get type => _type;

  /**
   * Return {@code true} if this variable was declared with the 'const' modifier.
   * @return {@code true} if this variable was declared with the 'const' modifier
   */
  bool isConst() => (_keyword is KeywordToken) && identical(((_keyword as KeywordToken)).keyword, Keyword.CONST);

  /**
   * Return {@code true} if this variable was declared with the 'final' modifier. Variables that are
   * declared with the 'const' modifier will return {@code false} even though they are implicitly
   * final.
   * @return {@code true} if this variable was declared with the 'final' modifier
   */
  bool isFinal() => (_keyword is KeywordToken) && identical(((_keyword as KeywordToken)).keyword, Keyword.FINAL);

  /**
   * Set the token representing either the 'final', 'const' or 'var' keyword to the given token.
   * @param keyword the token representing either the 'final', 'const' or 'var' keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }

  /**
   * Set the name of the declared type of the parameter to the given type name.
   * @param typeName the name of the declared type of the parameter
   */
  void set type(TypeName typeName) {
    _type = becomeParentOf(typeName);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_type, visitor);
    safelyVisitChild(_identifier, visitor);
  }
  Token get firstTokenAfterCommentAndMetadata {
    if (_keyword != null) {
      return _keyword;
    } else if (_type != null) {
      return _type.beginToken;
    }
    return _identifier.beginToken;
  }
}
/**
 * Instances of the class {@code DefaultFormalParameter} represent a formal parameter with a default
 * value. There are two kinds of parameters that are both represented by this class: named formal
 * parameters and positional formal parameters.
 * <pre>
 * defaultFormalParameter ::={@link NormalFormalParameter normalFormalParameter} ('=' {@link Expression defaultValue})?
 * defaultNamedParameter ::={@link NormalFormalParameter normalFormalParameter} (':' {@link Expression defaultValue})?
 * </pre>
 * @coverage dart.engine.ast
 */
class DefaultFormalParameter extends FormalParameter {

  /**
   * The formal parameter with which the default value is associated.
   */
  NormalFormalParameter _parameter;

  /**
   * The kind of this parameter.
   */
  ParameterKind _kind;

  /**
   * The token separating the parameter from the default value, or {@code null} if there is no
   * default value.
   */
  Token _separator;

  /**
   * The expression computing the default value for the parameter, or {@code null} if there is no
   * default value.
   */
  Expression _defaultValue;

  /**
   * Initialize a newly created default formal parameter.
   * @param parameter the formal parameter with which the default value is associated
   * @param kind the kind of this parameter
   * @param separator the token separating the parameter from the default value
   * @param defaultValue the expression computing the default value for the parameter
   */
  DefaultFormalParameter.full(NormalFormalParameter parameter, ParameterKind kind, Token separator, Expression defaultValue) {
    this._parameter = becomeParentOf(parameter);
    this._kind = kind;
    this._separator = separator;
    this._defaultValue = becomeParentOf(defaultValue);
  }

  /**
   * Initialize a newly created default formal parameter.
   * @param parameter the formal parameter with which the default value is associated
   * @param kind the kind of this parameter
   * @param separator the token separating the parameter from the default value
   * @param defaultValue the expression computing the default value for the parameter
   */
  DefaultFormalParameter({NormalFormalParameter parameter, ParameterKind kind, Token separator, Expression defaultValue}) : this.full(parameter, kind, separator, defaultValue);
  accept(ASTVisitor visitor) => visitor.visitDefaultFormalParameter(this);
  Token get beginToken => _parameter.beginToken;

  /**
   * Return the expression computing the default value for the parameter, or {@code null} if there
   * is no default value.
   * @return the expression computing the default value for the parameter
   */
  Expression get defaultValue => _defaultValue;
  Token get endToken {
    if (_defaultValue != null) {
      return _defaultValue.endToken;
    }
    return _parameter.endToken;
  }
  SimpleIdentifier get identifier => _parameter.identifier;
  ParameterKind get kind => _kind;

  /**
   * Return the formal parameter with which the default value is associated.
   * @return the formal parameter with which the default value is associated
   */
  NormalFormalParameter get parameter => _parameter;

  /**
   * Return the token separating the parameter from the default value, or {@code null} if there is
   * no default value.
   * @return the token separating the parameter from the default value
   */
  Token get separator => _separator;

  /**
   * Return {@code true} if this parameter was declared with the 'const' modifier.
   * @return {@code true} if this parameter was declared with the 'const' modifier
   */
  bool isConst() => _parameter != null && _parameter.isConst();

  /**
   * Return {@code true} if this parameter was declared with the 'final' modifier. Parameters that
   * are declared with the 'const' modifier will return {@code false} even though they are
   * implicitly final.
   * @return {@code true} if this parameter was declared with the 'final' modifier
   */
  bool isFinal() => _parameter != null && _parameter.isFinal();

  /**
   * Set the expression computing the default value for the parameter to the given expression.
   * @param expression the expression computing the default value for the parameter
   */
  void set defaultValue(Expression expression) {
    _defaultValue = becomeParentOf(expression);
  }

  /**
   * Set the kind of this parameter to the given kind.
   * @param kind the kind of this parameter
   */
  void set kind(ParameterKind kind2) {
    this._kind = kind2;
  }

  /**
   * Set the formal parameter with which the default value is associated to the given parameter.
   * @param formalParameter the formal parameter with which the default value is associated
   */
  void set parameter(NormalFormalParameter formalParameter) {
    _parameter = becomeParentOf(formalParameter);
  }

  /**
   * Set the token separating the parameter from the default value to the given token.
   * @param separator the token separating the parameter from the default value
   */
  void set separator(Token separator2) {
    this._separator = separator2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_parameter, visitor);
    safelyVisitChild(_defaultValue, visitor);
  }
}
/**
 * The abstract class {@code Directive} defines the behavior common to nodes that represent a
 * directive.
 * <pre>
 * directive ::={@link ExportDirective exportDirective}| {@link ImportDirective importDirective}| {@link LibraryDirective libraryDirective}| {@link PartDirective partDirective}| {@link PartOfDirective partOfDirective}</pre>
 * @coverage dart.engine.ast
 */
abstract class Directive extends AnnotatedNode {

  /**
   * The element associated with this directive, or {@code null} if the AST structure has not been
   * resolved or if this directive could not be resolved.
   */
  Element _element;

  /**
   * Initialize a newly create directive.
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   */
  Directive.full(Comment comment, List<Annotation> metadata) : super.full(comment, metadata) {
  }

  /**
   * Initialize a newly create directive.
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   */
  Directive({Comment comment, List<Annotation> metadata}) : this.full(comment, metadata);

  /**
   * Return the element associated with this directive, or {@code null} if the AST structure has not
   * been resolved or if this directive could not be resolved. Examples of the latter case include a
   * directive that contains an invalid URL or a URL that does not exist.
   * @return the element associated with this directive
   */
  Element get element => _element;

  /**
   * Return the token representing the keyword that introduces this directive ('import', 'export',
   * 'library' or 'part').
   * @return the token representing the keyword that introduces this directive
   */
  Token get keyword;

  /**
   * Set the element associated with this directive to the given element.
   * @param element the element associated with this directive
   */
  void set element(Element element2) {
    this._element = element2;
  }
}
/**
 * Instances of the class {@code DoStatement} represent a do statement.
 * <pre>
 * doStatement ::=
 * 'do' {@link Statement body} 'while' '(' {@link Expression condition} ')' ';'
 * </pre>
 * @coverage dart.engine.ast
 */
class DoStatement extends Statement {

  /**
   * The token representing the 'do' keyword.
   */
  Token _doKeyword;

  /**
   * The body of the loop.
   */
  Statement _body;

  /**
   * The token representing the 'while' keyword.
   */
  Token _whileKeyword;

  /**
   * The left parenthesis.
   */
  Token _leftParenthesis;

  /**
   * The condition that determines when the loop will terminate.
   */
  Expression _condition;

  /**
   * The right parenthesis.
   */
  Token _rightParenthesis;

  /**
   * The semicolon terminating the statement.
   */
  Token _semicolon;

  /**
   * Initialize a newly created do loop.
   * @param doKeyword the token representing the 'do' keyword
   * @param body the body of the loop
   * @param whileKeyword the token representing the 'while' keyword
   * @param leftParenthesis the left parenthesis
   * @param condition the condition that determines when the loop will terminate
   * @param rightParenthesis the right parenthesis
   * @param semicolon the semicolon terminating the statement
   */
  DoStatement.full(Token doKeyword, Statement body, Token whileKeyword, Token leftParenthesis, Expression condition, Token rightParenthesis, Token semicolon) {
    this._doKeyword = doKeyword;
    this._body = becomeParentOf(body);
    this._whileKeyword = whileKeyword;
    this._leftParenthesis = leftParenthesis;
    this._condition = becomeParentOf(condition);
    this._rightParenthesis = rightParenthesis;
    this._semicolon = semicolon;
  }

  /**
   * Initialize a newly created do loop.
   * @param doKeyword the token representing the 'do' keyword
   * @param body the body of the loop
   * @param whileKeyword the token representing the 'while' keyword
   * @param leftParenthesis the left parenthesis
   * @param condition the condition that determines when the loop will terminate
   * @param rightParenthesis the right parenthesis
   * @param semicolon the semicolon terminating the statement
   */
  DoStatement({Token doKeyword, Statement body, Token whileKeyword, Token leftParenthesis, Expression condition, Token rightParenthesis, Token semicolon}) : this.full(doKeyword, body, whileKeyword, leftParenthesis, condition, rightParenthesis, semicolon);
  accept(ASTVisitor visitor) => visitor.visitDoStatement(this);
  Token get beginToken => _doKeyword;

  /**
   * Return the body of the loop.
   * @return the body of the loop
   */
  Statement get body => _body;

  /**
   * Return the condition that determines when the loop will terminate.
   * @return the condition that determines when the loop will terminate
   */
  Expression get condition => _condition;

  /**
   * Return the token representing the 'do' keyword.
   * @return the token representing the 'do' keyword
   */
  Token get doKeyword => _doKeyword;
  Token get endToken => _semicolon;

  /**
   * Return the left parenthesis.
   * @return the left parenthesis
   */
  Token get leftParenthesis => _leftParenthesis;

  /**
   * Return the right parenthesis.
   * @return the right parenthesis
   */
  Token get rightParenthesis => _rightParenthesis;

  /**
   * Return the semicolon terminating the statement.
   * @return the semicolon terminating the statement
   */
  Token get semicolon => _semicolon;

  /**
   * Return the token representing the 'while' keyword.
   * @return the token representing the 'while' keyword
   */
  Token get whileKeyword => _whileKeyword;

  /**
   * Set the body of the loop to the given statement.
   * @param statement the body of the loop
   */
  void set body(Statement statement) {
    _body = becomeParentOf(statement);
  }

  /**
   * Set the condition that determines when the loop will terminate to the given expression.
   * @param expression the condition that determines when the loop will terminate
   */
  void set condition(Expression expression) {
    _condition = becomeParentOf(expression);
  }

  /**
   * Set the token representing the 'do' keyword to the given token.
   * @param doKeyword the token representing the 'do' keyword
   */
  void set doKeyword(Token doKeyword2) {
    this._doKeyword = doKeyword2;
  }

  /**
   * Set the left parenthesis to the given token.
   * @param parenthesis the left parenthesis
   */
  void set leftParenthesis(Token parenthesis) {
    _leftParenthesis = parenthesis;
  }

  /**
   * Set the right parenthesis to the given token.
   * @param parenthesis the right parenthesis
   */
  void set rightParenthesis(Token parenthesis) {
    _rightParenthesis = parenthesis;
  }

  /**
   * Set the semicolon terminating the statement to the given token.
   * @param semicolon the semicolon terminating the statement
   */
  void set semicolon(Token semicolon2) {
    this._semicolon = semicolon2;
  }

  /**
   * Set the token representing the 'while' keyword to the given token.
   * @param whileKeyword the token representing the 'while' keyword
   */
  void set whileKeyword(Token whileKeyword2) {
    this._whileKeyword = whileKeyword2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_body, visitor);
    safelyVisitChild(_condition, visitor);
  }
}
/**
 * Instances of the class {@code DoubleLiteral} represent a floating point literal expression.
 * <pre>
 * doubleLiteral ::=
 * decimalDigit+ ('.' decimalDigit*)? exponent?
 * | '.' decimalDigit+ exponent?
 * exponent ::=
 * ('e' | 'E') ('+' | '-')? decimalDigit+
 * </pre>
 * @coverage dart.engine.ast
 */
class DoubleLiteral extends Literal {

  /**
   * The token representing the literal.
   */
  Token _literal;

  /**
   * The value of the literal.
   */
  double _value = 0.0;

  /**
   * Initialize a newly created floating point literal.
   * @param literal the token representing the literal
   * @param value the value of the literal
   */
  DoubleLiteral.full(Token literal, double value) {
    this._literal = literal;
    this._value = value;
  }

  /**
   * Initialize a newly created floating point literal.
   * @param literal the token representing the literal
   * @param value the value of the literal
   */
  DoubleLiteral({Token literal, double value}) : this.full(literal, value);
  accept(ASTVisitor visitor) => visitor.visitDoubleLiteral(this);
  Token get beginToken => _literal;
  Token get endToken => _literal;

  /**
   * Return the token representing the literal.
   * @return the token representing the literal
   */
  Token get literal => _literal;

  /**
   * Return the value of the literal.
   * @return the value of the literal
   */
  double get value => _value;

  /**
   * Set the token representing the literal to the given token.
   * @param literal the token representing the literal
   */
  void set literal(Token literal2) {
    this._literal = literal2;
  }

  /**
   * Set the value of the literal to the given value.
   * @param value the value of the literal
   */
  void set value(double value2) {
    this._value = value2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
  }
}
/**
 * Instances of the class {@code EmptyFunctionBody} represent an empty function body, which can only
 * appear in constructors or abstract methods.
 * <pre>
 * emptyFunctionBody ::=
 * ';'
 * </pre>
 * @coverage dart.engine.ast
 */
class EmptyFunctionBody extends FunctionBody {

  /**
   * The token representing the semicolon that marks the end of the function body.
   */
  Token _semicolon;

  /**
   * Initialize a newly created function body.
   * @param semicolon the token representing the semicolon that marks the end of the function body
   */
  EmptyFunctionBody.full(Token semicolon) {
    this._semicolon = semicolon;
  }

  /**
   * Initialize a newly created function body.
   * @param semicolon the token representing the semicolon that marks the end of the function body
   */
  EmptyFunctionBody({Token semicolon}) : this.full(semicolon);
  accept(ASTVisitor visitor) => visitor.visitEmptyFunctionBody(this);
  Token get beginToken => _semicolon;
  Token get endToken => _semicolon;

  /**
   * Return the token representing the semicolon that marks the end of the function body.
   * @return the token representing the semicolon that marks the end of the function body
   */
  Token get semicolon => _semicolon;

  /**
   * Set the token representing the semicolon that marks the end of the function body to the given
   * token.
   * @param semicolon the token representing the semicolon that marks the end of the function body
   */
  void set semicolon(Token semicolon2) {
    this._semicolon = semicolon2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
  }
}
/**
 * Instances of the class {@code EmptyStatement} represent an empty statement.
 * <pre>
 * emptyStatement ::=
 * ';'
 * </pre>
 * @coverage dart.engine.ast
 */
class EmptyStatement extends Statement {

  /**
   * The semicolon terminating the statement.
   */
  Token _semicolon;

  /**
   * Initialize a newly created empty statement.
   * @param semicolon the semicolon terminating the statement
   */
  EmptyStatement.full(Token semicolon) {
    this._semicolon = semicolon;
  }

  /**
   * Initialize a newly created empty statement.
   * @param semicolon the semicolon terminating the statement
   */
  EmptyStatement({Token semicolon}) : this.full(semicolon);
  accept(ASTVisitor visitor) => visitor.visitEmptyStatement(this);
  Token get beginToken => _semicolon;
  Token get endToken => _semicolon;

  /**
   * Return the semicolon terminating the statement.
   * @return the semicolon terminating the statement
   */
  Token get semicolon => _semicolon;

  /**
   * Set the semicolon terminating the statement to the given token.
   * @param semicolon the semicolon terminating the statement
   */
  void set semicolon(Token semicolon2) {
    this._semicolon = semicolon2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
  }
}
/**
 * Ephemeral identifiers are created as needed to mimic the presence of an empty identifier.
 * @coverage dart.engine.ast
 */
class EphemeralIdentifier extends SimpleIdentifier {
  EphemeralIdentifier.full(ASTNode parent, int location) : super.full(new Token(TokenType.IDENTIFIER, location)) {
    parent.becomeParentOf(this);
  }
  EphemeralIdentifier({ASTNode parent, int location}) : this.full(parent, location);
}
/**
 * Instances of the class {@code ExportDirective} represent an export directive.
 * <pre>
 * exportDirective ::={@link Annotation metadata} 'export' {@link StringLiteral libraryUri} {@link Combinator combinator}* ';'
 * </pre>
 * @coverage dart.engine.ast
 */
class ExportDirective extends NamespaceDirective {

  /**
   * Initialize a newly created export directive.
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   * @param keyword the token representing the 'export' keyword
   * @param libraryUri the URI of the library being exported
   * @param combinators the combinators used to control which names are exported
   * @param semicolon the semicolon terminating the directive
   */
  ExportDirective.full(Comment comment, List<Annotation> metadata, Token keyword, StringLiteral libraryUri, List<Combinator> combinators, Token semicolon) : super.full(comment, metadata, keyword, libraryUri, combinators, semicolon) {
  }

  /**
   * Initialize a newly created export directive.
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   * @param keyword the token representing the 'export' keyword
   * @param libraryUri the URI of the library being exported
   * @param combinators the combinators used to control which names are exported
   * @param semicolon the semicolon terminating the directive
   */
  ExportDirective({Comment comment, List<Annotation> metadata, Token keyword, StringLiteral libraryUri, List<Combinator> combinators, Token semicolon}) : this.full(comment, metadata, keyword, libraryUri, combinators, semicolon);
  accept(ASTVisitor visitor) => visitor.visitExportDirective(this);
  LibraryElement get uriElement {
    Element element = this.element;
    if (element is ExportElement) {
      return ((element as ExportElement)).exportedLibrary;
    }
    return null;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    super.visitChildren(visitor);
    combinators.accept(visitor);
  }
}
/**
 * Instances of the class {@code Expression} defines the behavior common to nodes that represent an
 * expression.
 * <pre>
 * expression ::={@link AssignmentExpression assignmentExpression}| {@link ConditionalExpression conditionalExpression} cascadeSection
 * | {@link ThrowExpression throwExpression}</pre>
 * @coverage dart.engine.ast
 */
abstract class Expression extends ASTNode {

  /**
   * The static type of this expression, or {@code null} if the AST structure has not been resolved.
   */
  Type2 _staticType;

  /**
   * The propagated type of this expression, or {@code null} if type propagation has not been
   * performed on the AST structure.
   */
  Type2 _propagatedType;

  /**
   * If this expression is an argument to an invocation, and the AST structure has been resolved,
   * and the function being invoked is known based on propagated type information, and this
   * expression corresponds to one of the parameters of the function being invoked, then return the
   * parameter element representing the parameter to which the value of this expression will be
   * bound. Otherwise, return {@code null}.
   * @return the parameter element representing the parameter to which the value of this expression
   * will be bound
   */
  ParameterElement get parameterElement {
    ASTNode parent = this.parent;
    if (parent is ArgumentList) {
      return ((parent as ArgumentList)).getPropagatedParameterElementFor(this);
    } else if (parent is IndexExpression) {
      IndexExpression indexExpression = parent as IndexExpression;
      if (identical(indexExpression.index, this)) {
        return indexExpression.propagatedParameterElementForIndex;
      }
    } else if (parent is BinaryExpression) {
      BinaryExpression binaryExpression = parent as BinaryExpression;
      if (identical(binaryExpression.rightOperand, this)) {
        return binaryExpression.propagatedParameterElementForRightOperand;
      }
    } else if (parent is PrefixExpression) {
      return ((parent as PrefixExpression)).propagatedParameterElementForOperand;
    } else if (parent is PostfixExpression) {
      return ((parent as PostfixExpression)).propagatedParameterElementForOperand;
    }
    return null;
  }

  /**
   * Return the propagated type of this expression, or {@code null} if type propagation has not been
   * performed on the AST structure.
   * @return the propagated type of this expression
   */
  Type2 get propagatedType => _propagatedType;

  /**
   * If this expression is an argument to an invocation, and the AST structure has been resolved,
   * and the function being invoked is known based on static type information, and this expression
   * corresponds to one of the parameters of the function being invoked, then return the parameter
   * element representing the parameter to which the value of this expression will be bound.
   * Otherwise, return {@code null}.
   * @return the parameter element representing the parameter to which the value of this expression
   * will be bound
   */
  ParameterElement get staticParameterElement {
    ASTNode parent = this.parent;
    if (parent is ArgumentList) {
      return ((parent as ArgumentList)).getStaticParameterElementFor(this);
    } else if (parent is IndexExpression) {
      IndexExpression indexExpression = parent as IndexExpression;
      if (identical(indexExpression.index, this)) {
        return indexExpression.staticParameterElementForIndex;
      }
    } else if (parent is BinaryExpression) {
      BinaryExpression binaryExpression = parent as BinaryExpression;
      if (identical(binaryExpression.rightOperand, this)) {
        return binaryExpression.staticParameterElementForRightOperand;
      }
    } else if (parent is PrefixExpression) {
      return ((parent as PrefixExpression)).staticParameterElementForOperand;
    } else if (parent is PostfixExpression) {
      return ((parent as PostfixExpression)).staticParameterElementForOperand;
    }
    return null;
  }

  /**
   * Return the static type of this expression, or {@code null} if the AST structure has not been
   * resolved.
   * @return the static type of this expression
   */
  Type2 get staticType => _staticType;

  /**
   * Return {@code true} if this expression is syntactically valid for the LHS of an{@link AssignmentExpression assignment expression}.
   * @return {@code true} if this expression matches the {@code assignableExpression} production
   */
  bool isAssignable() => false;

  /**
   * Set the propagated type of this expression to the given type.
   * @param propagatedType the propagated type of this expression
   */
  void set propagatedType(Type2 propagatedType2) {
    this._propagatedType = propagatedType2;
  }

  /**
   * Set the static type of this expression to the given type.
   * @param staticType the static type of this expression
   */
  void set staticType(Type2 staticType2) {
    this._staticType = staticType2;
  }
}
/**
 * Instances of the class {@code ExpressionFunctionBody} represent a function body consisting of a
 * single expression.
 * <pre>
 * expressionFunctionBody ::=
 * '=>' {@link Expression expression} ';'
 * </pre>
 * @coverage dart.engine.ast
 */
class ExpressionFunctionBody extends FunctionBody {

  /**
   * The token introducing the expression that represents the body of the function.
   */
  Token _functionDefinition;

  /**
   * The expression representing the body of the function.
   */
  Expression _expression;

  /**
   * The semicolon terminating the statement.
   */
  Token _semicolon;

  /**
   * Initialize a newly created function body consisting of a block of statements.
   * @param functionDefinition the token introducing the expression that represents the body of the
   * function
   * @param expression the expression representing the body of the function
   * @param semicolon the semicolon terminating the statement
   */
  ExpressionFunctionBody.full(Token functionDefinition, Expression expression, Token semicolon) {
    this._functionDefinition = functionDefinition;
    this._expression = becomeParentOf(expression);
    this._semicolon = semicolon;
  }

  /**
   * Initialize a newly created function body consisting of a block of statements.
   * @param functionDefinition the token introducing the expression that represents the body of the
   * function
   * @param expression the expression representing the body of the function
   * @param semicolon the semicolon terminating the statement
   */
  ExpressionFunctionBody({Token functionDefinition, Expression expression, Token semicolon}) : this.full(functionDefinition, expression, semicolon);
  accept(ASTVisitor visitor) => visitor.visitExpressionFunctionBody(this);
  Token get beginToken => _functionDefinition;
  Token get endToken {
    if (_semicolon != null) {
      return _semicolon;
    }
    return _expression.endToken;
  }

  /**
   * Return the expression representing the body of the function.
   * @return the expression representing the body of the function
   */
  Expression get expression => _expression;

  /**
   * Return the token introducing the expression that represents the body of the function.
   * @return the function definition token
   */
  Token get functionDefinition => _functionDefinition;

  /**
   * Return the semicolon terminating the statement.
   * @return the semicolon terminating the statement
   */
  Token get semicolon => _semicolon;

  /**
   * Set the expression representing the body of the function to the given expression.
   * @param expression the expression representing the body of the function
   */
  void set expression(Expression expression2) {
    this._expression = becomeParentOf(expression2);
  }

  /**
   * Set the token introducing the expression that represents the body of the function to the given
   * token.
   * @param functionDefinition the function definition token
   */
  void set functionDefinition(Token functionDefinition2) {
    this._functionDefinition = functionDefinition2;
  }

  /**
   * Set the semicolon terminating the statement to the given token.
   * @param semicolon the semicolon terminating the statement
   */
  void set semicolon(Token semicolon2) {
    this._semicolon = semicolon2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_expression, visitor);
  }
}
/**
 * Instances of the class {@code ExpressionStatement} wrap an expression as a statement.
 * <pre>
 * expressionStatement ::={@link Expression expression}? ';'
 * </pre>
 * @coverage dart.engine.ast
 */
class ExpressionStatement extends Statement {

  /**
   * The expression that comprises the statement.
   */
  Expression _expression;

  /**
   * The semicolon terminating the statement, or {@code null} if the expression is a function
   * expression and isn't followed by a semicolon.
   */
  Token _semicolon;

  /**
   * Initialize a newly created expression statement.
   * @param expression the expression that comprises the statement
   * @param semicolon the semicolon terminating the statement
   */
  ExpressionStatement.full(Expression expression, Token semicolon) {
    this._expression = becomeParentOf(expression);
    this._semicolon = semicolon;
  }

  /**
   * Initialize a newly created expression statement.
   * @param expression the expression that comprises the statement
   * @param semicolon the semicolon terminating the statement
   */
  ExpressionStatement({Expression expression, Token semicolon}) : this.full(expression, semicolon);
  accept(ASTVisitor visitor) => visitor.visitExpressionStatement(this);
  Token get beginToken => _expression.beginToken;
  Token get endToken {
    if (_semicolon != null) {
      return _semicolon;
    }
    return _expression.endToken;
  }

  /**
   * Return the expression that comprises the statement.
   * @return the expression that comprises the statement
   */
  Expression get expression => _expression;

  /**
   * Return the semicolon terminating the statement.
   * @return the semicolon terminating the statement
   */
  Token get semicolon => _semicolon;
  bool isSynthetic() => _expression.isSynthetic() && _semicolon.isSynthetic();

  /**
   * Set the expression that comprises the statement to the given expression.
   * @param expression the expression that comprises the statement
   */
  void set expression(Expression expression2) {
    this._expression = becomeParentOf(expression2);
  }

  /**
   * Set the semicolon terminating the statement to the given token.
   * @param semicolon the semicolon terminating the statement
   */
  void set semicolon(Token semicolon2) {
    this._semicolon = semicolon2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_expression, visitor);
  }
}
/**
 * Instances of the class {@code ExtendsClause} represent the "extends" clause in a class
 * declaration.
 * <pre>
 * extendsClause ::=
 * 'extends' {@link TypeName superclass}</pre>
 * @coverage dart.engine.ast
 */
class ExtendsClause extends ASTNode {

  /**
   * The token representing the 'extends' keyword.
   */
  Token _keyword;

  /**
   * The name of the class that is being extended.
   */
  TypeName _superclass;

  /**
   * Initialize a newly created extends clause.
   * @param keyword the token representing the 'extends' keyword
   * @param superclass the name of the class that is being extended
   */
  ExtendsClause.full(Token keyword, TypeName superclass) {
    this._keyword = keyword;
    this._superclass = becomeParentOf(superclass);
  }

  /**
   * Initialize a newly created extends clause.
   * @param keyword the token representing the 'extends' keyword
   * @param superclass the name of the class that is being extended
   */
  ExtendsClause({Token keyword, TypeName superclass}) : this.full(keyword, superclass);
  accept(ASTVisitor visitor) => visitor.visitExtendsClause(this);
  Token get beginToken => _keyword;
  Token get endToken => _superclass.endToken;

  /**
   * Return the token representing the 'extends' keyword.
   * @return the token representing the 'extends' keyword
   */
  Token get keyword => _keyword;

  /**
   * Return the name of the class that is being extended.
   * @return the name of the class that is being extended
   */
  TypeName get superclass => _superclass;

  /**
   * Set the token representing the 'extends' keyword to the given token.
   * @param keyword the token representing the 'extends' keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }

  /**
   * Set the name of the class that is being extended to the given name.
   * @param name the name of the class that is being extended
   */
  void set superclass(TypeName name) {
    _superclass = becomeParentOf(name);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_superclass, visitor);
  }
}
/**
 * Instances of the class {@code FieldDeclaration} represent the declaration of one or more fields
 * of the same type.
 * <pre>
 * fieldDeclaration ::=
 * 'static'? {@link VariableDeclarationList fieldList} ';'
 * </pre>
 * @coverage dart.engine.ast
 */
class FieldDeclaration extends ClassMember {

  /**
   * The token representing the 'static' keyword, or {@code null} if the fields are not static.
   */
  Token _keyword;

  /**
   * The fields being declared.
   */
  VariableDeclarationList _fieldList;

  /**
   * The semicolon terminating the declaration.
   */
  Token _semicolon;

  /**
   * Initialize a newly created field declaration.
   * @param comment the documentation comment associated with this field
   * @param metadata the annotations associated with this field
   * @param keyword the token representing the 'static' keyword
   * @param fieldList the fields being declared
   * @param semicolon the semicolon terminating the declaration
   */
  FieldDeclaration.full(Comment comment, List<Annotation> metadata, Token keyword, VariableDeclarationList fieldList, Token semicolon) : super.full(comment, metadata) {
    this._keyword = keyword;
    this._fieldList = becomeParentOf(fieldList);
    this._semicolon = semicolon;
  }

  /**
   * Initialize a newly created field declaration.
   * @param comment the documentation comment associated with this field
   * @param metadata the annotations associated with this field
   * @param keyword the token representing the 'static' keyword
   * @param fieldList the fields being declared
   * @param semicolon the semicolon terminating the declaration
   */
  FieldDeclaration({Comment comment, List<Annotation> metadata, Token keyword, VariableDeclarationList fieldList, Token semicolon}) : this.full(comment, metadata, keyword, fieldList, semicolon);
  accept(ASTVisitor visitor) => visitor.visitFieldDeclaration(this);
  Element get element => null;
  Token get endToken => _semicolon;

  /**
   * Return the fields being declared.
   * @return the fields being declared
   */
  VariableDeclarationList get fields => _fieldList;

  /**
   * Return the token representing the 'static' keyword, or {@code null} if the fields are not
   * static.
   * @return the token representing the 'static' keyword
   */
  Token get keyword => _keyword;

  /**
   * Return the semicolon terminating the declaration.
   * @return the semicolon terminating the declaration
   */
  Token get semicolon => _semicolon;

  /**
   * Return {@code true} if the fields are static.
   * @return {@code true} if the fields are declared to be static
   */
  bool isStatic() => _keyword != null;

  /**
   * Set the fields being declared to the given list of variables.
   * @param fieldList the fields being declared
   */
  void set fields(VariableDeclarationList fieldList) {
    fieldList = becomeParentOf(fieldList);
  }

  /**
   * Set the token representing the 'static' keyword to the given token.
   * @param keyword the token representing the 'static' keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }

  /**
   * Set the semicolon terminating the declaration to the given token.
   * @param semicolon the semicolon terminating the declaration
   */
  void set semicolon(Token semicolon2) {
    this._semicolon = semicolon2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_fieldList, visitor);
  }
  Token get firstTokenAfterCommentAndMetadata {
    if (_keyword != null) {
      return _keyword;
    }
    return _fieldList.beginToken;
  }
}
/**
 * Instances of the class {@code FieldFormalParameter} represent a field formal parameter.
 * <pre>
 * fieldFormalParameter ::=
 * ('final' {@link TypeName type} | 'const' {@link TypeName type} | 'var' | {@link TypeName type})? 'this' '.' {@link SimpleIdentifier identifier}</pre>
 * @coverage dart.engine.ast
 */
class FieldFormalParameter extends NormalFormalParameter {

  /**
   * The token representing either the 'final', 'const' or 'var' keyword, or {@code null} if no
   * keyword was used.
   */
  Token _keyword;

  /**
   * The name of the declared type of the parameter, or {@code null} if the parameter does not have
   * a declared type.
   */
  TypeName _type;

  /**
   * The token representing the 'this' keyword.
   */
  Token _thisToken;

  /**
   * The token representing the period.
   */
  Token _period;

  /**
   * Initialize a newly created formal parameter.
   * @param comment the documentation comment associated with this parameter
   * @param metadata the annotations associated with this parameter
   * @param keyword the token representing either the 'final', 'const' or 'var' keyword
   * @param type the name of the declared type of the parameter
   * @param thisToken the token representing the 'this' keyword
   * @param period the token representing the period
   * @param identifier the name of the parameter being declared
   */
  FieldFormalParameter.full(Comment comment, List<Annotation> metadata, Token keyword, TypeName type, Token thisToken, Token period, SimpleIdentifier identifier) : super.full(comment, metadata, identifier) {
    this._keyword = keyword;
    this._type = becomeParentOf(type);
    this._thisToken = thisToken;
    this._period = period;
  }

  /**
   * Initialize a newly created formal parameter.
   * @param comment the documentation comment associated with this parameter
   * @param metadata the annotations associated with this parameter
   * @param keyword the token representing either the 'final', 'const' or 'var' keyword
   * @param type the name of the declared type of the parameter
   * @param thisToken the token representing the 'this' keyword
   * @param period the token representing the period
   * @param identifier the name of the parameter being declared
   */
  FieldFormalParameter({Comment comment, List<Annotation> metadata, Token keyword, TypeName type, Token thisToken, Token period, SimpleIdentifier identifier}) : this.full(comment, metadata, keyword, type, thisToken, period, identifier);
  accept(ASTVisitor visitor) => visitor.visitFieldFormalParameter(this);
  Token get beginToken {
    if (_keyword != null) {
      return _keyword;
    } else if (_type != null) {
      return _type.beginToken;
    }
    return _thisToken;
  }
  Token get endToken => identifier.endToken;

  /**
   * Return the token representing either the 'final', 'const' or 'var' keyword.
   * @return the token representing either the 'final', 'const' or 'var' keyword
   */
  Token get keyword => _keyword;

  /**
   * Return the token representing the period.
   * @return the token representing the period
   */
  Token get period => _period;

  /**
   * Return the token representing the 'this' keyword.
   * @return the token representing the 'this' keyword
   */
  Token get thisToken => _thisToken;

  /**
   * Return the name of the declared type of the parameter, or {@code null} if the parameter does
   * not have a declared type.
   * @return the name of the declared type of the parameter
   */
  TypeName get type => _type;
  bool isConst() => (_keyword is KeywordToken) && identical(((_keyword as KeywordToken)).keyword, Keyword.CONST);
  bool isFinal() => (_keyword is KeywordToken) && identical(((_keyword as KeywordToken)).keyword, Keyword.FINAL);

  /**
   * Set the token representing either the 'final', 'const' or 'var' keyword to the given token.
   * @param keyword the token representing either the 'final', 'const' or 'var' keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }

  /**
   * Set the token representing the period to the given token.
   * @param period the token representing the period
   */
  void set period(Token period2) {
    this._period = period2;
  }

  /**
   * Set the token representing the 'this' keyword to the given token.
   * @param thisToken the token representing the 'this' keyword
   */
  void set thisToken(Token thisToken2) {
    this._thisToken = thisToken2;
  }

  /**
   * Set the name of the declared type of the parameter to the given type name.
   * @param typeName the name of the declared type of the parameter
   */
  void set type(TypeName typeName) {
    _type = becomeParentOf(typeName);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_type, visitor);
    safelyVisitChild(identifier, visitor);
  }
}
/**
 * Instances of the class {@code ForEachStatement} represent a for-each statement.
 * <pre>
 * forEachStatement ::=
 * 'for' '(' {@link SimpleFormalParameter loopParameter} 'in' {@link Expression iterator} ')' {@link Block body}</pre>
 * @coverage dart.engine.ast
 */
class ForEachStatement extends Statement {

  /**
   * The token representing the 'for' keyword.
   */
  Token _forKeyword;

  /**
   * The left parenthesis.
   */
  Token _leftParenthesis;

  /**
   * The declaration of the loop variable.
   */
  DeclaredIdentifier _loopVariable;

  /**
   * The token representing the 'in' keyword.
   */
  Token _inKeyword;

  /**
   * The expression evaluated to produce the iterator.
   */
  Expression _iterator;

  /**
   * The right parenthesis.
   */
  Token _rightParenthesis;

  /**
   * The body of the loop.
   */
  Statement _body;

  /**
   * Initialize a newly created for-each statement.
   * @param forKeyword the token representing the 'for' keyword
   * @param leftParenthesis the left parenthesis
   * @param loopVariable the declaration of the loop variable
   * @param iterator the expression evaluated to produce the iterator
   * @param rightParenthesis the right parenthesis
   * @param body the body of the loop
   */
  ForEachStatement.full(Token forKeyword, Token leftParenthesis, DeclaredIdentifier loopVariable, Token inKeyword, Expression iterator, Token rightParenthesis, Statement body) {
    this._forKeyword = forKeyword;
    this._leftParenthesis = leftParenthesis;
    this._loopVariable = becomeParentOf(loopVariable);
    this._inKeyword = inKeyword;
    this._iterator = becomeParentOf(iterator);
    this._rightParenthesis = rightParenthesis;
    this._body = becomeParentOf(body);
  }

  /**
   * Initialize a newly created for-each statement.
   * @param forKeyword the token representing the 'for' keyword
   * @param leftParenthesis the left parenthesis
   * @param loopVariable the declaration of the loop variable
   * @param iterator the expression evaluated to produce the iterator
   * @param rightParenthesis the right parenthesis
   * @param body the body of the loop
   */
  ForEachStatement({Token forKeyword, Token leftParenthesis, DeclaredIdentifier loopVariable, Token inKeyword, Expression iterator, Token rightParenthesis, Statement body}) : this.full(forKeyword, leftParenthesis, loopVariable, inKeyword, iterator, rightParenthesis, body);
  accept(ASTVisitor visitor) => visitor.visitForEachStatement(this);
  Token get beginToken => _forKeyword;

  /**
   * Return the body of the loop.
   * @return the body of the loop
   */
  Statement get body => _body;
  Token get endToken => _body.endToken;

  /**
   * Return the token representing the 'for' keyword.
   * @return the token representing the 'for' keyword
   */
  Token get forKeyword => _forKeyword;

  /**
   * Return the token representing the 'in' keyword.
   * @return the token representing the 'in' keyword
   */
  Token get inKeyword => _inKeyword;

  /**
   * Return the expression evaluated to produce the iterator.
   * @return the expression evaluated to produce the iterator
   */
  Expression get iterator => _iterator;

  /**
   * Return the left parenthesis.
   * @return the left parenthesis
   */
  Token get leftParenthesis => _leftParenthesis;

  /**
   * Return the declaration of the loop variable.
   * @return the declaration of the loop variable
   */
  DeclaredIdentifier get loopVariable => _loopVariable;

  /**
   * Return the right parenthesis.
   * @return the right parenthesis
   */
  Token get rightParenthesis => _rightParenthesis;

  /**
   * Set the body of the loop to the given block.
   * @param body the body of the loop
   */
  void set body(Statement body2) {
    this._body = becomeParentOf(body2);
  }

  /**
   * Set the token representing the 'for' keyword to the given token.
   * @param forKeyword the token representing the 'for' keyword
   */
  void set forKeyword(Token forKeyword2) {
    this._forKeyword = forKeyword2;
  }

  /**
   * Set the token representing the 'in' keyword to the given token.
   * @param inKeyword the token representing the 'in' keyword
   */
  void set inKeyword(Token inKeyword2) {
    this._inKeyword = inKeyword2;
  }

  /**
   * Set the expression evaluated to produce the iterator to the given expression.
   * @param expression the expression evaluated to produce the iterator
   */
  void set iterator(Expression expression) {
    _iterator = becomeParentOf(expression);
  }

  /**
   * Set the left parenthesis to the given token.
   * @param leftParenthesis the left parenthesis
   */
  void set leftParenthesis(Token leftParenthesis2) {
    this._leftParenthesis = leftParenthesis2;
  }

  /**
   * Set the declaration of the loop variable to the given variable.
   * @param variable the declaration of the loop variable
   */
  void set loopVariable(DeclaredIdentifier variable) {
    _loopVariable = becomeParentOf(variable);
  }

  /**
   * Set the right parenthesis to the given token.
   * @param rightParenthesis the right parenthesis
   */
  void set rightParenthesis(Token rightParenthesis2) {
    this._rightParenthesis = rightParenthesis2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_loopVariable, visitor);
    safelyVisitChild(_iterator, visitor);
    safelyVisitChild(_body, visitor);
  }
}
/**
 * Instances of the class {@code ForStatement} represent a for statement.
 * <pre>
 * forStatement ::=
 * 'for' '(' forLoopParts ')' {@link Statement statement}forLoopParts ::=
 * forInitializerStatement ';' {@link Expression expression}? ';' {@link Expression expressionList}?
 * forInitializerStatement ::={@link DefaultFormalParameter initializedVariableDeclaration}| {@link Expression expression}?
 * </pre>
 * @coverage dart.engine.ast
 */
class ForStatement extends Statement {

  /**
   * The token representing the 'for' keyword.
   */
  Token _forKeyword;

  /**
   * The left parenthesis.
   */
  Token _leftParenthesis;

  /**
   * The declaration of the loop variables, or {@code null} if there are no variables. Note that a
   * for statement cannot have both a variable list and an initialization expression, but can
   * validly have neither.
   */
  VariableDeclarationList _variableList;

  /**
   * The initialization expression, or {@code null} if there is no initialization expression. Note
   * that a for statement cannot have both a variable list and an initialization expression, but can
   * validly have neither.
   */
  Expression _initialization;

  /**
   * The semicolon separating the initializer and the condition.
   */
  Token _leftSeparator;

  /**
   * The condition used to determine when to terminate the loop.
   */
  Expression _condition;

  /**
   * The semicolon separating the condition and the updater.
   */
  Token _rightSeparator;

  /**
   * The list of expressions run after each execution of the loop body.
   */
  NodeList<Expression> _updaters;

  /**
   * The right parenthesis.
   */
  Token _rightParenthesis;

  /**
   * The body of the loop.
   */
  Statement _body;

  /**
   * Initialize a newly created for statement.
   * @param forKeyword the token representing the 'for' keyword
   * @param leftParenthesis the left parenthesis
   * @param variableList the declaration of the loop variables
   * @param initialization the initialization expression
   * @param leftSeparator the semicolon separating the initializer and the condition
   * @param condition the condition used to determine when to terminate the loop
   * @param rightSeparator the semicolon separating the condition and the updater
   * @param updaters the list of expressions run after each execution of the loop body
   * @param rightParenthesis the right parenthesis
   * @param body the body of the loop
   */
  ForStatement.full(Token forKeyword, Token leftParenthesis, VariableDeclarationList variableList, Expression initialization, Token leftSeparator, Expression condition, Token rightSeparator, List<Expression> updaters, Token rightParenthesis, Statement body) {
    this._updaters = new NodeList<Expression>(this);
    this._forKeyword = forKeyword;
    this._leftParenthesis = leftParenthesis;
    this._variableList = becomeParentOf(variableList);
    this._initialization = becomeParentOf(initialization);
    this._leftSeparator = leftSeparator;
    this._condition = becomeParentOf(condition);
    this._rightSeparator = rightSeparator;
    this._updaters.addAll(updaters);
    this._rightParenthesis = rightParenthesis;
    this._body = becomeParentOf(body);
  }

  /**
   * Initialize a newly created for statement.
   * @param forKeyword the token representing the 'for' keyword
   * @param leftParenthesis the left parenthesis
   * @param variableList the declaration of the loop variables
   * @param initialization the initialization expression
   * @param leftSeparator the semicolon separating the initializer and the condition
   * @param condition the condition used to determine when to terminate the loop
   * @param rightSeparator the semicolon separating the condition and the updater
   * @param updaters the list of expressions run after each execution of the loop body
   * @param rightParenthesis the right parenthesis
   * @param body the body of the loop
   */
  ForStatement({Token forKeyword, Token leftParenthesis, VariableDeclarationList variableList, Expression initialization, Token leftSeparator, Expression condition, Token rightSeparator, List<Expression> updaters, Token rightParenthesis, Statement body}) : this.full(forKeyword, leftParenthesis, variableList, initialization, leftSeparator, condition, rightSeparator, updaters, rightParenthesis, body);
  accept(ASTVisitor visitor) => visitor.visitForStatement(this);
  Token get beginToken => _forKeyword;

  /**
   * Return the body of the loop.
   * @return the body of the loop
   */
  Statement get body => _body;

  /**
   * Return the condition used to determine when to terminate the loop.
   * @return the condition used to determine when to terminate the loop
   */
  Expression get condition => _condition;
  Token get endToken => _body.endToken;

  /**
   * Return the token representing the 'for' keyword.
   * @return the token representing the 'for' keyword
   */
  Token get forKeyword => _forKeyword;

  /**
   * Return the initialization expression, or {@code null} if there is no initialization expression.
   * @return the initialization expression
   */
  Expression get initialization => _initialization;

  /**
   * Return the left parenthesis.
   * @return the left parenthesis
   */
  Token get leftParenthesis => _leftParenthesis;

  /**
   * Return the semicolon separating the initializer and the condition.
   * @return the semicolon separating the initializer and the condition
   */
  Token get leftSeparator => _leftSeparator;

  /**
   * Return the right parenthesis.
   * @return the right parenthesis
   */
  Token get rightParenthesis => _rightParenthesis;

  /**
   * Return the semicolon separating the condition and the updater.
   * @return the semicolon separating the condition and the updater
   */
  Token get rightSeparator => _rightSeparator;

  /**
   * Return the list of expressions run after each execution of the loop body.
   * @return the list of expressions run after each execution of the loop body
   */
  NodeList<Expression> get updaters => _updaters;

  /**
   * Return the declaration of the loop variables, or {@code null} if there are no variables.
   * @return the declaration of the loop variables, or {@code null} if there are no variables
   */
  VariableDeclarationList get variables => _variableList;

  /**
   * Set the body of the loop to the given statement.
   * @param body the body of the loop
   */
  void set body(Statement body2) {
    this._body = becomeParentOf(body2);
  }

  /**
   * Set the condition used to determine when to terminate the loop to the given expression.
   * @param expression the condition used to determine when to terminate the loop
   */
  void set condition(Expression expression) {
    _condition = becomeParentOf(expression);
  }

  /**
   * Set the token representing the 'for' keyword to the given token.
   * @param forKeyword the token representing the 'for' keyword
   */
  void set forKeyword(Token forKeyword2) {
    this._forKeyword = forKeyword2;
  }

  /**
   * Set the initialization expression to the given expression.
   * @param initialization the initialization expression
   */
  void set initialization(Expression initialization2) {
    this._initialization = becomeParentOf(initialization2);
  }

  /**
   * Set the left parenthesis to the given token.
   * @param leftParenthesis the left parenthesis
   */
  void set leftParenthesis(Token leftParenthesis2) {
    this._leftParenthesis = leftParenthesis2;
  }

  /**
   * Set the semicolon separating the initializer and the condition to the given token.
   * @param leftSeparator the semicolon separating the initializer and the condition
   */
  void set leftSeparator(Token leftSeparator2) {
    this._leftSeparator = leftSeparator2;
  }

  /**
   * Set the right parenthesis to the given token.
   * @param rightParenthesis the right parenthesis
   */
  void set rightParenthesis(Token rightParenthesis2) {
    this._rightParenthesis = rightParenthesis2;
  }

  /**
   * Set the semicolon separating the condition and the updater to the given token.
   * @param rightSeparator the semicolon separating the condition and the updater
   */
  void set rightSeparator(Token rightSeparator2) {
    this._rightSeparator = rightSeparator2;
  }

  /**
   * Set the declaration of the loop variables to the given parameter.
   * @param variableList the declaration of the loop variables
   */
  void set variables(VariableDeclarationList variableList) {
    variableList = becomeParentOf(variableList);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_variableList, visitor);
    safelyVisitChild(_initialization, visitor);
    safelyVisitChild(_condition, visitor);
    _updaters.accept(visitor);
    safelyVisitChild(_body, visitor);
  }
}
/**
 * The abstract class {@code FormalParameter} defines the behavior of objects representing a
 * parameter to a function.
 * <pre>
 * formalParameter ::={@link NormalFormalParameter normalFormalParameter}| {@link DefaultFormalParameter namedFormalParameter}| {@link DefaultFormalParameter optionalFormalParameter}</pre>
 * @coverage dart.engine.ast
 */
abstract class FormalParameter extends ASTNode {

  /**
   * Return the element representing this parameter, or {@code null} if this parameter has not been
   * resolved.
   * @return the element representing this parameter
   */
  ParameterElement get element {
    SimpleIdentifier identifier = this.identifier;
    if (identifier == null) {
      return null;
    }
    return identifier.element as ParameterElement;
  }

  /**
   * Return the name of the parameter being declared.
   * @return the name of the parameter being declared
   */
  SimpleIdentifier get identifier;

  /**
   * Return the kind of this parameter.
   * @return the kind of this parameter
   */
  ParameterKind get kind;
}
/**
 * Instances of the class {@code FormalParameterList} represent the formal parameter list of a
 * method declaration, function declaration, or function type alias.
 * <p>
 * While the grammar requires all optional formal parameters to follow all of the normal formal
 * parameters and at most one grouping of optional formal parameters, this class does not enforce
 * those constraints. All parameters are flattened into a single list, which can have any or all
 * kinds of parameters (normal, named, and positional) in any order.
 * <pre>
 * formalParameterList ::=
 * '(' ')'
 * | '(' normalFormalParameters (',' optionalFormalParameters)? ')'
 * | '(' optionalFormalParameters ')'
 * normalFormalParameters ::={@link NormalFormalParameter normalFormalParameter} (',' {@link NormalFormalParameter normalFormalParameter})
 * optionalFormalParameters ::=
 * optionalPositionalFormalParameters
 * | namedFormalParameters
 * optionalPositionalFormalParameters ::=
 * '\[' {@link DefaultFormalParameter positionalFormalParameter} (',' {@link DefaultFormalParameter positionalFormalParameter})* '\]'
 * namedFormalParameters ::=
 * '{' {@link DefaultFormalParameter namedFormalParameter} (',' {@link DefaultFormalParameter namedFormalParameter})* '}'
 * </pre>
 * @coverage dart.engine.ast
 */
class FormalParameterList extends ASTNode {

  /**
   * The left parenthesis.
   */
  Token _leftParenthesis;

  /**
   * The parameters associated with the method.
   */
  NodeList<FormalParameter> _parameters;

  /**
   * The left square bracket ('\[') or left curly brace ('{') introducing the optional parameters.
   */
  Token _leftDelimiter;

  /**
   * The right square bracket ('\]') or right curly brace ('}') introducing the optional parameters.
   */
  Token _rightDelimiter;

  /**
   * The right parenthesis.
   */
  Token _rightParenthesis;

  /**
   * Initialize a newly created parameter list.
   * @param leftParenthesis the left parenthesis
   * @param parameters the parameters associated with the method
   * @param leftDelimiter the left delimiter introducing the optional parameters
   * @param rightDelimiter the right delimiter introducing the optional parameters
   * @param rightParenthesis the right parenthesis
   */
  FormalParameterList.full(Token leftParenthesis, List<FormalParameter> parameters, Token leftDelimiter, Token rightDelimiter, Token rightParenthesis) {
    this._parameters = new NodeList<FormalParameter>(this);
    this._leftParenthesis = leftParenthesis;
    this._parameters.addAll(parameters);
    this._leftDelimiter = leftDelimiter;
    this._rightDelimiter = rightDelimiter;
    this._rightParenthesis = rightParenthesis;
  }

  /**
   * Initialize a newly created parameter list.
   * @param leftParenthesis the left parenthesis
   * @param parameters the parameters associated with the method
   * @param leftDelimiter the left delimiter introducing the optional parameters
   * @param rightDelimiter the right delimiter introducing the optional parameters
   * @param rightParenthesis the right parenthesis
   */
  FormalParameterList({Token leftParenthesis, List<FormalParameter> parameters, Token leftDelimiter, Token rightDelimiter, Token rightParenthesis}) : this.full(leftParenthesis, parameters, leftDelimiter, rightDelimiter, rightParenthesis);
  accept(ASTVisitor visitor) => visitor.visitFormalParameterList(this);
  Token get beginToken => _leftParenthesis;

  /**
   * Return an array containing the elements representing the parameters in this list. The array
   * will contain {@code null}s if the parameters in this list have not been resolved.
   * @return the elements representing the parameters in this list
   */
  List<ParameterElement> get elements {
    int count = _parameters.length;
    List<ParameterElement> types = new List<ParameterElement>(count);
    for (int i = 0; i < count; i++) {
      types[i] = _parameters[i].element;
    }
    return types;
  }
  Token get endToken => _rightParenthesis;

  /**
   * Return the left square bracket ('\[') or left curly brace ('{') introducing the optional
   * parameters.
   * @return the left square bracket ('\[') or left curly brace ('{') introducing the optional
   * parameters
   */
  Token get leftDelimiter => _leftDelimiter;

  /**
   * Return the left parenthesis.
   * @return the left parenthesis
   */
  Token get leftParenthesis => _leftParenthesis;

  /**
   * Return the parameters associated with the method.
   * @return the parameters associated with the method
   */
  NodeList<FormalParameter> get parameters => _parameters;

  /**
   * Return the right square bracket ('\]') or right curly brace ('}') introducing the optional
   * parameters.
   * @return the right square bracket ('\]') or right curly brace ('}') introducing the optional
   * parameters
   */
  Token get rightDelimiter => _rightDelimiter;

  /**
   * Return the right parenthesis.
   * @return the right parenthesis
   */
  Token get rightParenthesis => _rightParenthesis;

  /**
   * Set the left square bracket ('\[') or left curly brace ('{') introducing the optional parameters
   * to the given token.
   * @param bracket the left delimiter introducing the optional parameters
   */
  void set leftDelimiter(Token bracket) {
    _leftDelimiter = bracket;
  }

  /**
   * Set the left parenthesis to the given token.
   * @param parenthesis the left parenthesis
   */
  void set leftParenthesis(Token parenthesis) {
    _leftParenthesis = parenthesis;
  }

  /**
   * Set the right square bracket ('\]') or right curly brace ('}') introducing the optional
   * parameters to the given token.
   * @param bracket the right delimiter introducing the optional parameters
   */
  void set rightDelimiter(Token bracket) {
    _rightDelimiter = bracket;
  }

  /**
   * Set the right parenthesis to the given token.
   * @param parenthesis the right parenthesis
   */
  void set rightParenthesis(Token parenthesis) {
    _rightParenthesis = parenthesis;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    _parameters.accept(visitor);
  }
}
/**
 * The abstract class {@code FunctionBody} defines the behavior common to objects representing the
 * body of a function or method.
 * <pre>
 * functionBody ::={@link BlockFunctionBody blockFunctionBody}| {@link EmptyFunctionBody emptyFunctionBody}| {@link ExpressionFunctionBody expressionFunctionBody}</pre>
 * @coverage dart.engine.ast
 */
abstract class FunctionBody extends ASTNode {
}
/**
 * Instances of the class {@code FunctionDeclaration} wrap a {@link FunctionExpression function
 * expression} as a top-level declaration.
 * <pre>
 * functionDeclaration ::=
 * 'external' functionSignature
 * | functionSignature {@link FunctionBody functionBody}functionSignature ::={@link Type returnType}? ('get' | 'set')? {@link SimpleIdentifier functionName} {@link FormalParameterList formalParameterList}</pre>
 * @coverage dart.engine.ast
 */
class FunctionDeclaration extends CompilationUnitMember {

  /**
   * The token representing the 'external' keyword, or {@code null} if this is not an external
   * function.
   */
  Token _externalKeyword;

  /**
   * The return type of the function, or {@code null} if no return type was declared.
   */
  TypeName _returnType;

  /**
   * The token representing the 'get' or 'set' keyword, or {@code null} if this is a function
   * declaration rather than a property declaration.
   */
  Token _propertyKeyword;

  /**
   * The name of the function, or {@code null} if the function is not named.
   */
  SimpleIdentifier _name;

  /**
   * The function expression being wrapped.
   */
  FunctionExpression _functionExpression;

  /**
   * Initialize a newly created function declaration.
   * @param comment the documentation comment associated with this function
   * @param metadata the annotations associated with this function
   * @param externalKeyword the token representing the 'external' keyword
   * @param returnType the return type of the function
   * @param propertyKeyword the token representing the 'get' or 'set' keyword
   * @param name the name of the function
   * @param functionExpression the function expression being wrapped
   */
  FunctionDeclaration.full(Comment comment, List<Annotation> metadata, Token externalKeyword, TypeName returnType, Token propertyKeyword, SimpleIdentifier name, FunctionExpression functionExpression) : super.full(comment, metadata) {
    this._externalKeyword = externalKeyword;
    this._returnType = becomeParentOf(returnType);
    this._propertyKeyword = propertyKeyword;
    this._name = becomeParentOf(name);
    this._functionExpression = becomeParentOf(functionExpression);
  }

  /**
   * Initialize a newly created function declaration.
   * @param comment the documentation comment associated with this function
   * @param metadata the annotations associated with this function
   * @param externalKeyword the token representing the 'external' keyword
   * @param returnType the return type of the function
   * @param propertyKeyword the token representing the 'get' or 'set' keyword
   * @param name the name of the function
   * @param functionExpression the function expression being wrapped
   */
  FunctionDeclaration({Comment comment, List<Annotation> metadata, Token externalKeyword, TypeName returnType, Token propertyKeyword, SimpleIdentifier name, FunctionExpression functionExpression}) : this.full(comment, metadata, externalKeyword, returnType, propertyKeyword, name, functionExpression);
  accept(ASTVisitor visitor) => visitor.visitFunctionDeclaration(this);
  ExecutableElement get element => _name != null ? (_name.element as ExecutableElement) : null;
  Token get endToken => _functionExpression.endToken;

  /**
   * Return the token representing the 'external' keyword, or {@code null} if this is not an
   * external function.
   * @return the token representing the 'external' keyword
   */
  Token get externalKeyword => _externalKeyword;

  /**
   * Return the function expression being wrapped.
   * @return the function expression being wrapped
   */
  FunctionExpression get functionExpression => _functionExpression;

  /**
   * Return the name of the function, or {@code null} if the function is not named.
   * @return the name of the function
   */
  SimpleIdentifier get name => _name;

  /**
   * Return the token representing the 'get' or 'set' keyword, or {@code null} if this is a function
   * declaration rather than a property declaration.
   * @return the token representing the 'get' or 'set' keyword
   */
  Token get propertyKeyword => _propertyKeyword;

  /**
   * Return the return type of the function, or {@code null} if no return type was declared.
   * @return the return type of the function
   */
  TypeName get returnType => _returnType;

  /**
   * Return {@code true} if this function declares a getter.
   * @return {@code true} if this function declares a getter
   */
  bool isGetter() => _propertyKeyword != null && identical(((_propertyKeyword as KeywordToken)).keyword, Keyword.GET);

  /**
   * Return {@code true} if this function declares a setter.
   * @return {@code true} if this function declares a setter
   */
  bool isSetter() => _propertyKeyword != null && identical(((_propertyKeyword as KeywordToken)).keyword, Keyword.SET);

  /**
   * Set the token representing the 'external' keyword to the given token.
   * @param externalKeyword the token representing the 'external' keyword
   */
  void set externalKeyword(Token externalKeyword2) {
    this._externalKeyword = externalKeyword2;
  }

  /**
   * Set the function expression being wrapped to the given function expression.
   * @param functionExpression the function expression being wrapped
   */
  void set functionExpression(FunctionExpression functionExpression2) {
    functionExpression2 = becomeParentOf(functionExpression2);
  }

  /**
   * Set the name of the function to the given identifier.
   * @param identifier the name of the function
   */
  void set name(SimpleIdentifier identifier) {
    _name = becomeParentOf(identifier);
  }

  /**
   * Set the token representing the 'get' or 'set' keyword to the given token.
   * @param propertyKeyword the token representing the 'get' or 'set' keyword
   */
  void set propertyKeyword(Token propertyKeyword2) {
    this._propertyKeyword = propertyKeyword2;
  }

  /**
   * Set the return type of the function to the given name.
   * @param name the return type of the function
   */
  void set returnType(TypeName name) {
    _returnType = becomeParentOf(name);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_returnType, visitor);
    safelyVisitChild(_name, visitor);
    safelyVisitChild(_functionExpression, visitor);
  }
  Token get firstTokenAfterCommentAndMetadata {
    if (_externalKeyword != null) {
      return _externalKeyword;
    }
    if (_returnType != null) {
      return _returnType.beginToken;
    } else if (_propertyKeyword != null) {
      return _propertyKeyword;
    } else if (_name != null) {
      return _name.beginToken;
    }
    return _functionExpression.beginToken;
  }
}
/**
 * Instances of the class {@code FunctionDeclarationStatement} wrap a {@link FunctionDeclarationfunction declaration} as a statement.
 * @coverage dart.engine.ast
 */
class FunctionDeclarationStatement extends Statement {

  /**
   * The function declaration being wrapped.
   */
  FunctionDeclaration _functionDeclaration;

  /**
   * Initialize a newly created function declaration statement.
   * @param functionDeclaration the the function declaration being wrapped
   */
  FunctionDeclarationStatement.full(FunctionDeclaration functionDeclaration) {
    this._functionDeclaration = becomeParentOf(functionDeclaration);
  }

  /**
   * Initialize a newly created function declaration statement.
   * @param functionDeclaration the the function declaration being wrapped
   */
  FunctionDeclarationStatement({FunctionDeclaration functionDeclaration}) : this.full(functionDeclaration);
  accept(ASTVisitor visitor) => visitor.visitFunctionDeclarationStatement(this);
  Token get beginToken => _functionDeclaration.beginToken;
  Token get endToken => _functionDeclaration.endToken;

  /**
   * Return the function declaration being wrapped.
   * @return the function declaration being wrapped
   */
  FunctionDeclaration get functionDeclaration => _functionDeclaration;

  /**
   * Set the function declaration being wrapped to the given function declaration.
   * @param functionDeclaration the function declaration being wrapped
   */
  void set functionExpression(FunctionDeclaration functionDeclaration2) {
    this._functionDeclaration = becomeParentOf(functionDeclaration2);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_functionDeclaration, visitor);
  }
}
/**
 * Instances of the class {@code FunctionExpression} represent a function expression.
 * <pre>
 * functionExpression ::={@link FormalParameterList formalParameterList} {@link FunctionBody functionBody}</pre>
 * @coverage dart.engine.ast
 */
class FunctionExpression extends Expression {

  /**
   * The parameters associated with the function.
   */
  FormalParameterList _parameters;

  /**
   * The body of the function, or {@code null} if this is an external function.
   */
  FunctionBody _body;

  /**
   * The element associated with the function, or {@code null} if the AST structure has not been
   * resolved.
   */
  ExecutableElement _element;

  /**
   * Initialize a newly created function declaration.
   * @param parameters the parameters associated with the function
   * @param body the body of the function
   */
  FunctionExpression.full(FormalParameterList parameters, FunctionBody body) {
    this._parameters = becomeParentOf(parameters);
    this._body = becomeParentOf(body);
  }

  /**
   * Initialize a newly created function declaration.
   * @param parameters the parameters associated with the function
   * @param body the body of the function
   */
  FunctionExpression({FormalParameterList parameters, FunctionBody body}) : this.full(parameters, body);
  accept(ASTVisitor visitor) => visitor.visitFunctionExpression(this);
  Token get beginToken {
    if (_parameters != null) {
      return _parameters.beginToken;
    } else if (_body != null) {
      return _body.beginToken;
    }
    throw new IllegalStateException("Non-external functions must have a body");
  }

  /**
   * Return the body of the function, or {@code null} if this is an external function.
   * @return the body of the function
   */
  FunctionBody get body => _body;

  /**
   * Return the element associated with this function, or {@code null} if the AST structure has not
   * been resolved.
   * @return the element associated with this function
   */
  ExecutableElement get element => _element;
  Token get endToken {
    if (_body != null) {
      return _body.endToken;
    } else if (_parameters != null) {
      return _parameters.endToken;
    }
    throw new IllegalStateException("Non-external functions must have a body");
  }

  /**
   * Return the parameters associated with the function.
   * @return the parameters associated with the function
   */
  FormalParameterList get parameters => _parameters;

  /**
   * Set the body of the function to the given function body.
   * @param functionBody the body of the function
   */
  void set body(FunctionBody functionBody) {
    _body = becomeParentOf(functionBody);
  }

  /**
   * Set the element associated with this function to the given element.
   * @param element the element associated with this function
   */
  void set element(ExecutableElement element2) {
    this._element = element2;
  }

  /**
   * Set the parameters associated with the function to the given list of parameters.
   * @param parameters the parameters associated with the function
   */
  void set parameters(FormalParameterList parameters2) {
    this._parameters = becomeParentOf(parameters2);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_parameters, visitor);
    safelyVisitChild(_body, visitor);
  }
}
/**
 * Instances of the class {@code FunctionExpressionInvocation} represent the invocation of a
 * function resulting from evaluating an expression. Invocations of methods and other forms of
 * functions are represented by {@link MethodInvocation method invocation} nodes. Invocations of
 * getters and setters are represented by either {@link PrefixedIdentifier prefixed identifier} or{@link PropertyAccess property access} nodes.
 * <pre>
 * functionExpressionInvoction ::={@link Expression function} {@link ArgumentList argumentList}</pre>
 * @coverage dart.engine.ast
 */
class FunctionExpressionInvocation extends Expression {

  /**
   * The expression producing the function being invoked.
   */
  Expression _function;

  /**
   * The list of arguments to the function.
   */
  ArgumentList _argumentList;

  /**
   * The element associated with the function being invoked based on static type information, or{@code null} if the AST structure has not been resolved or the function could not be resolved.
   */
  ExecutableElement _staticElement;

  /**
   * The element associated with the function being invoked based on propagated type information, or{@code null} if the AST structure has not been resolved or the function could not be resolved.
   */
  ExecutableElement _propagatedElement;

  /**
   * Initialize a newly created function expression invocation.
   * @param function the expression producing the function being invoked
   * @param argumentList the list of arguments to the method
   */
  FunctionExpressionInvocation.full(Expression function, ArgumentList argumentList) {
    this._function = becomeParentOf(function);
    this._argumentList = becomeParentOf(argumentList);
  }

  /**
   * Initialize a newly created function expression invocation.
   * @param function the expression producing the function being invoked
   * @param argumentList the list of arguments to the method
   */
  FunctionExpressionInvocation({Expression function, ArgumentList argumentList}) : this.full(function, argumentList);
  accept(ASTVisitor visitor) => visitor.visitFunctionExpressionInvocation(this);

  /**
   * Return the list of arguments to the method.
   * @return the list of arguments to the method
   */
  ArgumentList get argumentList => _argumentList;
  Token get beginToken => _function.beginToken;

  /**
   * Return the element associated with the function being invoked based on propagated type
   * information, or {@code null} if the AST structure has not been resolved or the function could
   * not be resolved. One common example of the latter case is an expression whose value can change
   * over time.
   * @return the element associated with the function being invoked
   */
  ExecutableElement get element => _propagatedElement;
  Token get endToken => _argumentList.endToken;

  /**
   * Return the expression producing the function being invoked.
   * @return the expression producing the function being invoked
   */
  Expression get function => _function;

  /**
   * Return the element associated with the function being invoked based on static type information,
   * or {@code null} if the AST structure has not been resolved or the function could not be
   * resolved. One common example of the latter case is an expression whose value can change over
   * time.
   * @return the element associated with the function
   */
  ExecutableElement get staticElement => _staticElement;

  /**
   * Set the list of arguments to the method to the given list.
   * @param argumentList the list of arguments to the method
   */
  void set argumentList(ArgumentList argumentList2) {
    this._argumentList = becomeParentOf(argumentList2);
  }

  /**
   * Set the element associated with the function being invoked based on propagated type information
   * to the given element.
   * @param element the element to be associated with the function being invoked
   */
  void set element(ExecutableElement element2) {
    _propagatedElement = element2;
  }

  /**
   * Set the expression producing the function being invoked to the given expression.
   * @param function the expression producing the function being invoked
   */
  void set function(Expression function2) {
    function2 = becomeParentOf(function2);
  }

  /**
   * Set the element associated with the function being invoked based on static type information to
   * the given element.
   * @param element the element to be associated with the function
   */
  void set staticElement(ExecutableElement element) {
    this._staticElement = element;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_function, visitor);
    safelyVisitChild(_argumentList, visitor);
  }
}
/**
 * Instances of the class {@code FunctionTypeAlias} represent a function type alias.
 * <pre>
 * functionTypeAlias ::=
 * functionPrefix {@link TypeParameterList typeParameterList}? {@link FormalParameterList formalParameterList} ';'
 * functionPrefix ::={@link TypeName returnType}? {@link SimpleIdentifier name}</pre>
 * @coverage dart.engine.ast
 */
class FunctionTypeAlias extends TypeAlias {

  /**
   * The name of the return type of the function type being defined, or {@code null} if no return
   * type was given.
   */
  TypeName _returnType;

  /**
   * The name of the function type being declared.
   */
  SimpleIdentifier _name;

  /**
   * The type parameters for the function type, or {@code null} if the function type does not have
   * any type parameters.
   */
  TypeParameterList _typeParameters;

  /**
   * The parameters associated with the function type.
   */
  FormalParameterList _parameters;

  /**
   * Initialize a newly created function type alias.
   * @param comment the documentation comment associated with this type alias
   * @param metadata the annotations associated with this type alias
   * @param keyword the token representing the 'typedef' keyword
   * @param returnType the name of the return type of the function type being defined
   * @param name the name of the type being declared
   * @param typeParameters the type parameters for the type
   * @param parameters the parameters associated with the function
   * @param semicolon the semicolon terminating the declaration
   */
  FunctionTypeAlias.full(Comment comment, List<Annotation> metadata, Token keyword, TypeName returnType, SimpleIdentifier name, TypeParameterList typeParameters, FormalParameterList parameters, Token semicolon) : super.full(comment, metadata, keyword, semicolon) {
    this._returnType = becomeParentOf(returnType);
    this._name = becomeParentOf(name);
    this._typeParameters = becomeParentOf(typeParameters);
    this._parameters = becomeParentOf(parameters);
  }

  /**
   * Initialize a newly created function type alias.
   * @param comment the documentation comment associated with this type alias
   * @param metadata the annotations associated with this type alias
   * @param keyword the token representing the 'typedef' keyword
   * @param returnType the name of the return type of the function type being defined
   * @param name the name of the type being declared
   * @param typeParameters the type parameters for the type
   * @param parameters the parameters associated with the function
   * @param semicolon the semicolon terminating the declaration
   */
  FunctionTypeAlias({Comment comment, List<Annotation> metadata, Token keyword, TypeName returnType, SimpleIdentifier name, TypeParameterList typeParameters, FormalParameterList parameters, Token semicolon}) : this.full(comment, metadata, keyword, returnType, name, typeParameters, parameters, semicolon);
  accept(ASTVisitor visitor) => visitor.visitFunctionTypeAlias(this);
  FunctionTypeAliasElement get element => _name != null ? (_name.element as FunctionTypeAliasElement) : null;

  /**
   * Return the name of the function type being declared.
   * @return the name of the function type being declared
   */
  SimpleIdentifier get name => _name;

  /**
   * Return the parameters associated with the function type.
   * @return the parameters associated with the function type
   */
  FormalParameterList get parameters => _parameters;

  /**
   * Return the name of the return type of the function type being defined, or {@code null} if no
   * return type was given.
   * @return the name of the return type of the function type being defined
   */
  TypeName get returnType => _returnType;

  /**
   * Return the type parameters for the function type, or {@code null} if the function type does not
   * have any type parameters.
   * @return the type parameters for the function type
   */
  TypeParameterList get typeParameters => _typeParameters;

  /**
   * Set the name of the function type being declared to the given identifier.
   * @param name the name of the function type being declared
   */
  void set name(SimpleIdentifier name2) {
    this._name = becomeParentOf(name2);
  }

  /**
   * Set the parameters associated with the function type to the given list of parameters.
   * @param parameters the parameters associated with the function type
   */
  void set parameters(FormalParameterList parameters2) {
    this._parameters = becomeParentOf(parameters2);
  }

  /**
   * Set the name of the return type of the function type being defined to the given type name.
   * @param typeName the name of the return type of the function type being defined
   */
  void set returnType(TypeName typeName) {
    _returnType = becomeParentOf(typeName);
  }

  /**
   * Set the type parameters for the function type to the given list of parameters.
   * @param typeParameters the type parameters for the function type
   */
  void set typeParameters(TypeParameterList typeParameters2) {
    this._typeParameters = becomeParentOf(typeParameters2);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_returnType, visitor);
    safelyVisitChild(_name, visitor);
    safelyVisitChild(_typeParameters, visitor);
    safelyVisitChild(_parameters, visitor);
  }
}
/**
 * Instances of the class {@code FunctionTypedFormalParameter} represent a function-typed formal
 * parameter.
 * <pre>
 * functionSignature ::={@link TypeName returnType}? {@link SimpleIdentifier identifier} {@link FormalParameterList formalParameterList}</pre>
 * @coverage dart.engine.ast
 */
class FunctionTypedFormalParameter extends NormalFormalParameter {

  /**
   * The return type of the function, or {@code null} if the function does not have a return type.
   */
  TypeName _returnType;

  /**
   * The parameters of the function-typed parameter.
   */
  FormalParameterList _parameters;

  /**
   * Initialize a newly created formal parameter.
   * @param comment the documentation comment associated with this parameter
   * @param metadata the annotations associated with this parameter
   * @param returnType the return type of the function, or {@code null} if the function does not
   * have a return type
   * @param identifier the name of the function-typed parameter
   * @param parameters the parameters of the function-typed parameter
   */
  FunctionTypedFormalParameter.full(Comment comment, List<Annotation> metadata, TypeName returnType, SimpleIdentifier identifier, FormalParameterList parameters) : super.full(comment, metadata, identifier) {
    this._returnType = becomeParentOf(returnType);
    this._parameters = becomeParentOf(parameters);
  }

  /**
   * Initialize a newly created formal parameter.
   * @param comment the documentation comment associated with this parameter
   * @param metadata the annotations associated with this parameter
   * @param returnType the return type of the function, or {@code null} if the function does not
   * have a return type
   * @param identifier the name of the function-typed parameter
   * @param parameters the parameters of the function-typed parameter
   */
  FunctionTypedFormalParameter({Comment comment, List<Annotation> metadata, TypeName returnType, SimpleIdentifier identifier, FormalParameterList parameters}) : this.full(comment, metadata, returnType, identifier, parameters);
  accept(ASTVisitor visitor) => visitor.visitFunctionTypedFormalParameter(this);
  Token get beginToken {
    if (_returnType != null) {
      return _returnType.beginToken;
    }
    return identifier.beginToken;
  }
  Token get endToken => _parameters.endToken;

  /**
   * Return the parameters of the function-typed parameter.
   * @return the parameters of the function-typed parameter
   */
  FormalParameterList get parameters => _parameters;

  /**
   * Return the return type of the function, or {@code null} if the function does not have a return
   * type.
   * @return the return type of the function
   */
  TypeName get returnType => _returnType;
  bool isConst() => false;
  bool isFinal() => false;

  /**
   * Set the parameters of the function-typed parameter to the given parameters.
   * @param parameters the parameters of the function-typed parameter
   */
  void set parameters(FormalParameterList parameters2) {
    this._parameters = becomeParentOf(parameters2);
  }

  /**
   * Set the return type of the function to the given type.
   * @param returnType the return type of the function
   */
  void set returnType(TypeName returnType2) {
    this._returnType = becomeParentOf(returnType2);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_returnType, visitor);
    safelyVisitChild(identifier, visitor);
    safelyVisitChild(_parameters, visitor);
  }
}
/**
 * Instances of the class {@code HideCombinator} represent a combinator that restricts the names
 * being imported to those that are not in a given list.
 * <pre>
 * hideCombinator ::=
 * 'hide' {@link SimpleIdentifier identifier} (',' {@link SimpleIdentifier identifier})
 * </pre>
 * @coverage dart.engine.ast
 */
class HideCombinator extends Combinator {

  /**
   * The list of names from the library that are hidden by this combinator.
   */
  NodeList<SimpleIdentifier> _hiddenNames;

  /**
   * Initialize a newly created import show combinator.
   * @param keyword the comma introducing the combinator
   * @param hiddenNames the list of names from the library that are hidden by this combinator
   */
  HideCombinator.full(Token keyword, List<SimpleIdentifier> hiddenNames) : super.full(keyword) {
    this._hiddenNames = new NodeList<SimpleIdentifier>(this);
    this._hiddenNames.addAll(hiddenNames);
  }

  /**
   * Initialize a newly created import show combinator.
   * @param keyword the comma introducing the combinator
   * @param hiddenNames the list of names from the library that are hidden by this combinator
   */
  HideCombinator({Token keyword, List<SimpleIdentifier> hiddenNames}) : this.full(keyword, hiddenNames);
  accept(ASTVisitor visitor) => visitor.visitHideCombinator(this);
  Token get endToken => _hiddenNames.endToken;

  /**
   * Return the list of names from the library that are hidden by this combinator.
   * @return the list of names from the library that are hidden by this combinator
   */
  NodeList<SimpleIdentifier> get hiddenNames => _hiddenNames;
  void visitChildren(ASTVisitor<Object> visitor) {
    _hiddenNames.accept(visitor);
  }
}
/**
 * The abstract class {@code Identifier} defines the behavior common to nodes that represent an
 * identifier.
 * <pre>
 * identifier ::={@link SimpleIdentifier simpleIdentifier}| {@link PrefixedIdentifier prefixedIdentifier}</pre>
 * @coverage dart.engine.ast
 */
abstract class Identifier extends Expression {

  /**
   * Return {@code true} if the given name is visible only within the library in which it is
   * declared.
   * @param name the name being tested
   * @return {@code true} if the given name is private
   */
  static bool isPrivateName(String name) => name.startsWith("_");

  /**
   * Return the element associated with this identifier based on propagated type information, or{@code null} if the AST structure has not been resolved or if this identifier could not be
   * resolved. One example of the latter case is an identifier that is not defined within the scope
   * in which it appears.
   * @return the element associated with this identifier
   */
  Element get element;

  /**
   * Return the lexical representation of the identifier.
   * @return the lexical representation of the identifier
   */
  String get name;

  /**
   * Return the element associated with this identifier based on static type information, or{@code null} if the AST structure has not been resolved or if this identifier could not be
   * resolved. One example of the latter case is an identifier that is not defined within the scope
   * in which it appears
   * @return the element associated with the operator
   */
  Element get staticElement;
  bool isAssignable() => true;
}
/**
 * Instances of the class {@code IfStatement} represent an if statement.
 * <pre>
 * ifStatement ::=
 * 'if' '(' {@link Expression expression} ')' {@link Statement thenStatement} ('else' {@link Statement elseStatement})?
 * </pre>
 * @coverage dart.engine.ast
 */
class IfStatement extends Statement {

  /**
   * The token representing the 'if' keyword.
   */
  Token _ifKeyword;

  /**
   * The left parenthesis.
   */
  Token _leftParenthesis;

  /**
   * The condition used to determine which of the statements is executed next.
   */
  Expression _condition;

  /**
   * The right parenthesis.
   */
  Token _rightParenthesis;

  /**
   * The statement that is executed if the condition evaluates to {@code true}.
   */
  Statement _thenStatement;

  /**
   * The token representing the 'else' keyword.
   */
  Token _elseKeyword;

  /**
   * The statement that is executed if the condition evaluates to {@code false}, or {@code null} if
   * there is no else statement.
   */
  Statement _elseStatement;

  /**
   * Initialize a newly created if statement.
   * @param ifKeyword the token representing the 'if' keyword
   * @param leftParenthesis the left parenthesis
   * @param condition the condition used to determine which of the statements is executed next
   * @param rightParenthesis the right parenthesis
   * @param thenStatement the statement that is executed if the condition evaluates to {@code true}
   * @param elseKeyword the token representing the 'else' keyword
   * @param elseStatement the statement that is executed if the condition evaluates to {@code false}
   */
  IfStatement.full(Token ifKeyword, Token leftParenthesis, Expression condition, Token rightParenthesis, Statement thenStatement, Token elseKeyword, Statement elseStatement) {
    this._ifKeyword = ifKeyword;
    this._leftParenthesis = leftParenthesis;
    this._condition = becomeParentOf(condition);
    this._rightParenthesis = rightParenthesis;
    this._thenStatement = becomeParentOf(thenStatement);
    this._elseKeyword = elseKeyword;
    this._elseStatement = becomeParentOf(elseStatement);
  }

  /**
   * Initialize a newly created if statement.
   * @param ifKeyword the token representing the 'if' keyword
   * @param leftParenthesis the left parenthesis
   * @param condition the condition used to determine which of the statements is executed next
   * @param rightParenthesis the right parenthesis
   * @param thenStatement the statement that is executed if the condition evaluates to {@code true}
   * @param elseKeyword the token representing the 'else' keyword
   * @param elseStatement the statement that is executed if the condition evaluates to {@code false}
   */
  IfStatement({Token ifKeyword, Token leftParenthesis, Expression condition, Token rightParenthesis, Statement thenStatement, Token elseKeyword, Statement elseStatement}) : this.full(ifKeyword, leftParenthesis, condition, rightParenthesis, thenStatement, elseKeyword, elseStatement);
  accept(ASTVisitor visitor) => visitor.visitIfStatement(this);
  Token get beginToken => _ifKeyword;

  /**
   * Return the condition used to determine which of the statements is executed next.
   * @return the condition used to determine which statement is executed next
   */
  Expression get condition => _condition;

  /**
   * Return the token representing the 'else' keyword.
   * @return the token representing the 'else' keyword
   */
  Token get elseKeyword => _elseKeyword;

  /**
   * Return the statement that is executed if the condition evaluates to {@code false}, or{@code null} if there is no else statement.
   * @return the statement that is executed if the condition evaluates to {@code false}
   */
  Statement get elseStatement => _elseStatement;
  Token get endToken {
    if (_elseStatement != null) {
      return _elseStatement.endToken;
    }
    return _thenStatement.endToken;
  }

  /**
   * Return the token representing the 'if' keyword.
   * @return the token representing the 'if' keyword
   */
  Token get ifKeyword => _ifKeyword;

  /**
   * Return the left parenthesis.
   * @return the left parenthesis
   */
  Token get leftParenthesis => _leftParenthesis;

  /**
   * Return the right parenthesis.
   * @return the right parenthesis
   */
  Token get rightParenthesis => _rightParenthesis;

  /**
   * Return the statement that is executed if the condition evaluates to {@code true}.
   * @return the statement that is executed if the condition evaluates to {@code true}
   */
  Statement get thenStatement => _thenStatement;

  /**
   * Set the condition used to determine which of the statements is executed next to the given
   * expression.
   * @param expression the condition used to determine which statement is executed next
   */
  void set condition(Expression expression) {
    _condition = becomeParentOf(expression);
  }

  /**
   * Set the token representing the 'else' keyword to the given token.
   * @param elseKeyword the token representing the 'else' keyword
   */
  void set elseKeyword(Token elseKeyword2) {
    this._elseKeyword = elseKeyword2;
  }

  /**
   * Set the statement that is executed if the condition evaluates to {@code false} to the given
   * statement.
   * @param statement the statement that is executed if the condition evaluates to {@code false}
   */
  void set elseStatement(Statement statement) {
    _elseStatement = becomeParentOf(statement);
  }

  /**
   * Set the token representing the 'if' keyword to the given token.
   * @param ifKeyword the token representing the 'if' keyword
   */
  void set ifKeyword(Token ifKeyword2) {
    this._ifKeyword = ifKeyword2;
  }

  /**
   * Set the left parenthesis to the given token.
   * @param leftParenthesis the left parenthesis
   */
  void set leftParenthesis(Token leftParenthesis2) {
    this._leftParenthesis = leftParenthesis2;
  }

  /**
   * Set the right parenthesis to the given token.
   * @param rightParenthesis the right parenthesis
   */
  void set rightParenthesis(Token rightParenthesis2) {
    this._rightParenthesis = rightParenthesis2;
  }

  /**
   * Set the statement that is executed if the condition evaluates to {@code true} to the given
   * statement.
   * @param statement the statement that is executed if the condition evaluates to {@code true}
   */
  void set thenStatement(Statement statement) {
    _thenStatement = becomeParentOf(statement);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_condition, visitor);
    safelyVisitChild(_thenStatement, visitor);
    safelyVisitChild(_elseStatement, visitor);
  }
}
/**
 * Instances of the class {@code ImplementsClause} represent the "implements" clause in an class
 * declaration.
 * <pre>
 * implementsClause ::=
 * 'implements' {@link TypeName superclass} (',' {@link TypeName superclass})
 * </pre>
 * @coverage dart.engine.ast
 */
class ImplementsClause extends ASTNode {

  /**
   * The token representing the 'implements' keyword.
   */
  Token _keyword;

  /**
   * The interfaces that are being implemented.
   */
  NodeList<TypeName> _interfaces;

  /**
   * Initialize a newly created extends clause.
   * @param keyword the token representing the 'implements' keyword
   * @param interfaces the interfaces that are being implemented
   */
  ImplementsClause.full(Token keyword, List<TypeName> interfaces) {
    this._interfaces = new NodeList<TypeName>(this);
    this._keyword = keyword;
    this._interfaces.addAll(interfaces);
  }

  /**
   * Initialize a newly created extends clause.
   * @param keyword the token representing the 'implements' keyword
   * @param interfaces the interfaces that are being implemented
   */
  ImplementsClause({Token keyword, List<TypeName> interfaces}) : this.full(keyword, interfaces);
  accept(ASTVisitor visitor) => visitor.visitImplementsClause(this);
  Token get beginToken => _keyword;
  Token get endToken => _interfaces.endToken;

  /**
   * Return the list of the interfaces that are being implemented.
   * @return the list of the interfaces that are being implemented
   */
  NodeList<TypeName> get interfaces => _interfaces;

  /**
   * Return the token representing the 'implements' keyword.
   * @return the token representing the 'implements' keyword
   */
  Token get keyword => _keyword;

  /**
   * Set the token representing the 'implements' keyword to the given token.
   * @param keyword the token representing the 'implements' keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    _interfaces.accept(visitor);
  }
}
/**
 * Instances of the class {@code ImportDirective} represent an import directive.
 * <pre>
 * importDirective ::={@link Annotation metadata} 'import' {@link StringLiteral libraryUri} ('as' identifier)? {@link Combinator combinator}* ';'
 * </pre>
 * @coverage dart.engine.ast
 */
class ImportDirective extends NamespaceDirective {

  /**
   * The token representing the 'as' token, or {@code null} if the imported names are not prefixed.
   */
  Token _asToken;

  /**
   * The prefix to be used with the imported names, or {@code null} if the imported names are not
   * prefixed.
   */
  SimpleIdentifier _prefix;

  /**
   * Initialize a newly created import directive.
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   * @param keyword the token representing the 'import' keyword
   * @param libraryUri the URI of the library being imported
   * @param asToken the token representing the 'as' token
   * @param prefix the prefix to be used with the imported names
   * @param combinators the combinators used to control how names are imported
   * @param semicolon the semicolon terminating the directive
   */
  ImportDirective.full(Comment comment, List<Annotation> metadata, Token keyword, StringLiteral libraryUri, Token asToken, SimpleIdentifier prefix, List<Combinator> combinators, Token semicolon) : super.full(comment, metadata, keyword, libraryUri, combinators, semicolon) {
    this._asToken = asToken;
    this._prefix = becomeParentOf(prefix);
  }

  /**
   * Initialize a newly created import directive.
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   * @param keyword the token representing the 'import' keyword
   * @param libraryUri the URI of the library being imported
   * @param asToken the token representing the 'as' token
   * @param prefix the prefix to be used with the imported names
   * @param combinators the combinators used to control how names are imported
   * @param semicolon the semicolon terminating the directive
   */
  ImportDirective({Comment comment, List<Annotation> metadata, Token keyword, StringLiteral libraryUri, Token asToken, SimpleIdentifier prefix, List<Combinator> combinators, Token semicolon}) : this.full(comment, metadata, keyword, libraryUri, asToken, prefix, combinators, semicolon);
  accept(ASTVisitor visitor) => visitor.visitImportDirective(this);

  /**
   * Return the token representing the 'as' token, or {@code null} if the imported names are not
   * prefixed.
   * @return the token representing the 'as' token
   */
  Token get asToken => _asToken;

  /**
   * Return the prefix to be used with the imported names, or {@code null} if the imported names are
   * not prefixed.
   * @return the prefix to be used with the imported names
   */
  SimpleIdentifier get prefix => _prefix;
  LibraryElement get uriElement {
    Element element = this.element;
    if (element is ImportElement) {
      return ((element as ImportElement)).importedLibrary;
    }
    return null;
  }

  /**
   * Set the token representing the 'as' token to the given token.
   * @param asToken the token representing the 'as' token
   */
  void set asToken(Token asToken2) {
    this._asToken = asToken2;
  }

  /**
   * Set the prefix to be used with the imported names to the given identifier.
   * @param prefix the prefix to be used with the imported names
   */
  void set prefix(SimpleIdentifier prefix2) {
    this._prefix = becomeParentOf(prefix2);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_prefix, visitor);
    combinators.accept(visitor);
  }
}
/**
 * Instances of the class {@code IndexExpression} represent an index expression.
 * <pre>
 * indexExpression ::={@link Expression target} '\[' {@link Expression index} '\]'
 * </pre>
 * @coverage dart.engine.ast
 */
class IndexExpression extends Expression {

  /**
   * The expression used to compute the object being indexed, or {@code null} if this index
   * expression is part of a cascade expression.
   */
  Expression _target;

  /**
   * The period ("..") before a cascaded index expression, or {@code null} if this index expression
   * is not part of a cascade expression.
   */
  Token _period;

  /**
   * The left square bracket.
   */
  Token _leftBracket;

  /**
   * The expression used to compute the index.
   */
  Expression _index;

  /**
   * The right square bracket.
   */
  Token _rightBracket;

  /**
   * The element associated with the operator based on the static type of the target, or{@code null} if the AST structure has not been resolved or if the operator could not be
   * resolved.
   */
  MethodElement _staticElement;

  /**
   * The element associated with the operator based on the propagated type of the target, or{@code null} if the AST structure has not been resolved or if the operator could not be
   * resolved.
   */
  MethodElement _propagatedElement;

  /**
   * Initialize a newly created index expression.
   * @param target the expression used to compute the object being indexed
   * @param leftBracket the left square bracket
   * @param index the expression used to compute the index
   * @param rightBracket the right square bracket
   */
  IndexExpression.forTarget_full(Expression target2, Token leftBracket2, Expression index2, Token rightBracket2) {
    _jtd_constructor_58_impl(target2, leftBracket2, index2, rightBracket2);
  }

  /**
   * Initialize a newly created index expression.
   * @param target the expression used to compute the object being indexed
   * @param leftBracket the left square bracket
   * @param index the expression used to compute the index
   * @param rightBracket the right square bracket
   */
  IndexExpression.forTarget({Expression target2, Token leftBracket2, Expression index2, Token rightBracket2}) : this.forTarget_full(target2, leftBracket2, index2, rightBracket2);
  _jtd_constructor_58_impl(Expression target2, Token leftBracket2, Expression index2, Token rightBracket2) {
    this._target = becomeParentOf(target2);
    this._leftBracket = leftBracket2;
    this._index = becomeParentOf(index2);
    this._rightBracket = rightBracket2;
  }

  /**
   * Initialize a newly created index expression.
   * @param period the period ("..") before a cascaded index expression
   * @param leftBracket the left square bracket
   * @param index the expression used to compute the index
   * @param rightBracket the right square bracket
   */
  IndexExpression.forCascade_full(Token period2, Token leftBracket2, Expression index2, Token rightBracket2) {
    _jtd_constructor_59_impl(period2, leftBracket2, index2, rightBracket2);
  }

  /**
   * Initialize a newly created index expression.
   * @param period the period ("..") before a cascaded index expression
   * @param leftBracket the left square bracket
   * @param index the expression used to compute the index
   * @param rightBracket the right square bracket
   */
  IndexExpression.forCascade({Token period2, Token leftBracket2, Expression index2, Token rightBracket2}) : this.forCascade_full(period2, leftBracket2, index2, rightBracket2);
  _jtd_constructor_59_impl(Token period2, Token leftBracket2, Expression index2, Token rightBracket2) {
    this._period = period2;
    this._leftBracket = leftBracket2;
    this._index = becomeParentOf(index2);
    this._rightBracket = rightBracket2;
  }
  accept(ASTVisitor visitor) => visitor.visitIndexExpression(this);

  /**
   * Return the expression used to compute the object being indexed, or {@code null} if this index
   * expression is part of a cascade expression.
   * @return the expression used to compute the object being indexed
   * @see #getRealTarget()
   */
  Expression get array => _target;
  Token get beginToken {
    if (_target != null) {
      return _target.beginToken;
    }
    return _period;
  }

  /**
   * Return the element associated with the operator based on the propagated type of the target, or{@code null} if the AST structure has not been resolved or if the operator could not be
   * resolved. One example of the latter case is an operator that is not defined for the type of the
   * target.
   * @return the element associated with this operator
   */
  MethodElement get element => _propagatedElement;
  Token get endToken => _rightBracket;

  /**
   * Return the expression used to compute the index.
   * @return the expression used to compute the index
   */
  Expression get index => _index;

  /**
   * Return the left square bracket.
   * @return the left square bracket
   */
  Token get leftBracket => _leftBracket;

  /**
   * Return the period ("..") before a cascaded index expression, or {@code null} if this index
   * expression is not part of a cascade expression.
   * @return the period ("..") before a cascaded index expression
   */
  Token get period => _period;

  /**
   * Return the expression used to compute the object being indexed. If this index expression is not
   * part of a cascade expression, then this is the same as {@link #getArray()}. If this index
   * expression is part of a cascade expression, then the target expression stored with the cascade
   * expression is returned.
   * @return the expression used to compute the object being indexed
   * @see #getArray()
   */
  Expression get realTarget {
    if (isCascaded()) {
      ASTNode ancestor = parent;
      while (ancestor is! CascadeExpression) {
        if (ancestor == null) {
          return _target;
        }
        ancestor = ancestor.parent;
      }
      return ((ancestor as CascadeExpression)).target;
    }
    return _target;
  }

  /**
   * Return the right square bracket.
   * @return the right square bracket
   */
  Token get rightBracket => _rightBracket;

  /**
   * Return the element associated with the operator based on the static type of the target, or{@code null} if the AST structure has not been resolved or if the operator could not be
   * resolved. One example of the latter case is an operator that is not defined for the type of the
   * target.
   * @return the element associated with the operator
   */
  MethodElement get staticElement => _staticElement;

  /**
   * Return {@code true} if this expression is computing a right-hand value.
   * <p>
   * Note that {@link #inGetterContext()} and {@link #inSetterContext()} are not opposites, nor are
   * they mutually exclusive. In other words, it is possible for both methods to return {@code true}when invoked on the same node.
   * @return {@code true} if this expression is in a context where the operator '\[\]' will be invoked
   */
  bool inGetterContext() {
    ASTNode parent = this.parent;
    if (parent is AssignmentExpression) {
      AssignmentExpression assignment = parent as AssignmentExpression;
      if (identical(assignment.leftHandSide, this) && identical(assignment.operator.type, TokenType.EQ)) {
        return false;
      }
    }
    return true;
  }

  /**
   * Return {@code true} if this expression is computing a left-hand value.
   * <p>
   * Note that {@link #inGetterContext()} and {@link #inSetterContext()} are not opposites, nor are
   * they mutually exclusive. In other words, it is possible for both methods to return {@code true}when invoked on the same node.
   * @return {@code true} if this expression is in a context where the operator '\[\]=' will be
   * invoked
   */
  bool inSetterContext() {
    ASTNode parent = this.parent;
    if (parent is PrefixExpression) {
      return ((parent as PrefixExpression)).operator.type.isIncrementOperator();
    } else if (parent is PostfixExpression) {
      return true;
    } else if (parent is AssignmentExpression) {
      return identical(((parent as AssignmentExpression)).leftHandSide, this);
    }
    return false;
  }
  bool isAssignable() => true;

  /**
   * Return {@code true} if this expression is cascaded. If it is, then the target of this
   * expression is not stored locally but is stored in the nearest ancestor that is a{@link CascadeExpression}.
   * @return {@code true} if this expression is cascaded
   */
  bool isCascaded() => _period != null;

  /**
   * Set the expression used to compute the object being indexed to the given expression.
   * @param expression the expression used to compute the object being indexed
   */
  void set array(Expression expression) {
    _target = becomeParentOf(expression);
  }

  /**
   * Set the element associated with the operator based on the propagated type of the target to the
   * given element.
   * @param element the element to be associated with this operator
   */
  void set element(MethodElement element2) {
    _propagatedElement = element2;
  }

  /**
   * Set the expression used to compute the index to the given expression.
   * @param expression the expression used to compute the index
   */
  void set index(Expression expression) {
    _index = becomeParentOf(expression);
  }

  /**
   * Set the left square bracket to the given token.
   * @param bracket the left square bracket
   */
  void set leftBracket(Token bracket) {
    _leftBracket = bracket;
  }

  /**
   * Set the period ("..") before a cascaded index expression to the given token.
   * @param period the period ("..") before a cascaded index expression
   */
  void set period(Token period2) {
    this._period = period2;
  }

  /**
   * Set the right square bracket to the given token.
   * @param bracket the right square bracket
   */
  void set rightBracket(Token bracket) {
    _rightBracket = bracket;
  }

  /**
   * Set the element associated with the operator based on the static type of the target to the
   * given element.
   * @param element the static element to be associated with the operator
   */
  void set staticElement(MethodElement element) {
    _staticElement = element;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_target, visitor);
    safelyVisitChild(_index, visitor);
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is known based on
   * propagated type information, then return the parameter element representing the parameter to
   * which the value of the index expression will be bound. Otherwise, return {@code null}.
   * <p>
   * This method is only intended to be used by {@link Expression#getParameterElement()}.
   * @return the parameter element representing the parameter to which the value of the index
   * expression will be bound
   */
  ParameterElement get propagatedParameterElementForIndex {
    if (_propagatedElement == null) {
      return null;
    }
    List<ParameterElement> parameters = _propagatedElement.parameters;
    if (parameters.length < 1) {
      return null;
    }
    return parameters[0];
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is known based on static
   * type information, then return the parameter element representing the parameter to which the
   * value of the index expression will be bound. Otherwise, return {@code null}.
   * <p>
   * This method is only intended to be used by {@link Expression#getStaticParameterElement()}.
   * @return the parameter element representing the parameter to which the value of the index
   * expression will be bound
   */
  ParameterElement get staticParameterElementForIndex {
    if (_staticElement == null) {
      return null;
    }
    List<ParameterElement> parameters = _staticElement.parameters;
    if (parameters.length < 1) {
      return null;
    }
    return parameters[0];
  }
}
/**
 * Instances of the class {@code InstanceCreationExpression} represent an instance creation
 * expression.
 * <pre>
 * newExpression ::=
 * ('new' | 'const') {@link TypeName type} ('.' {@link SimpleIdentifier identifier})? {@link ArgumentList argumentList}</pre>
 * @coverage dart.engine.ast
 */
class InstanceCreationExpression extends Expression {

  /**
   * The keyword used to indicate how an object should be created.
   */
  Token _keyword;

  /**
   * The name of the constructor to be invoked.
   */
  ConstructorName _constructorName;

  /**
   * The list of arguments to the constructor.
   */
  ArgumentList _argumentList;

  /**
   * The element associated with the constructor based on static type information, or {@code null}if the AST structure has not been resolved or if the constructor could not be resolved.
   */
  ConstructorElement _staticElement;

  /**
   * The element associated with the constructor based on propagated type information, or{@code null} if the AST structure has not been resolved or if the constructor could not be
   * resolved.
   */
  ConstructorElement _propagatedElement;

  /**
   * Initialize a newly created instance creation expression.
   * @param keyword the keyword used to indicate how an object should be created
   * @param constructorName the name of the constructor to be invoked
   * @param argumentList the list of arguments to the constructor
   */
  InstanceCreationExpression.full(Token keyword, ConstructorName constructorName, ArgumentList argumentList) {
    this._keyword = keyword;
    this._constructorName = becomeParentOf(constructorName);
    this._argumentList = becomeParentOf(argumentList);
  }

  /**
   * Initialize a newly created instance creation expression.
   * @param keyword the keyword used to indicate how an object should be created
   * @param constructorName the name of the constructor to be invoked
   * @param argumentList the list of arguments to the constructor
   */
  InstanceCreationExpression({Token keyword, ConstructorName constructorName, ArgumentList argumentList}) : this.full(keyword, constructorName, argumentList);
  accept(ASTVisitor visitor) => visitor.visitInstanceCreationExpression(this);

  /**
   * Return the list of arguments to the constructor.
   * @return the list of arguments to the constructor
   */
  ArgumentList get argumentList => _argumentList;
  Token get beginToken => _keyword;

  /**
   * Return the name of the constructor to be invoked.
   * @return the name of the constructor to be invoked
   */
  ConstructorName get constructorName => _constructorName;

  /**
   * Return the element associated with the constructor based on propagated type information, or{@code null} if the AST structure has not been resolved or if the constructor could not be
   * resolved.
   * @return the element associated with the constructor
   */
  ConstructorElement get element => _propagatedElement;
  Token get endToken => _argumentList.endToken;

  /**
   * Return the keyword used to indicate how an object should be created.
   * @return the keyword used to indicate how an object should be created
   */
  Token get keyword => _keyword;

  /**
   * Return the element associated with the constructor based on static type information, or{@code null} if the AST structure has not been resolved or if the constructor could not be
   * resolved.
   * @return the element associated with the constructor
   */
  ConstructorElement get staticElement => _staticElement;

  /**
   * Return {@code true} if this creation expression is used to invoke a constant constructor.
   * @return {@code true} if this creation expression is used to invoke a constant constructor
   */
  bool isConst() => _keyword is KeywordToken && identical(((_keyword as KeywordToken)).keyword, Keyword.CONST);

  /**
   * Set the list of arguments to the constructor to the given list.
   * @param argumentList the list of arguments to the constructor
   */
  void set argumentList(ArgumentList argumentList2) {
    this._argumentList = becomeParentOf(argumentList2);
  }

  /**
   * Set the name of the constructor to be invoked to the given name.
   * @param constructorName the name of the constructor to be invoked
   */
  void set constructorName(ConstructorName constructorName2) {
    this._constructorName = constructorName2;
  }

  /**
   * Set the element associated with the constructor based on propagated type information to the
   * given element.
   * @param element the element to be associated with the constructor
   */
  void set element(ConstructorElement element2) {
    this._propagatedElement = element2;
  }

  /**
   * Set the keyword used to indicate how an object should be created to the given keyword.
   * @param keyword the keyword used to indicate how an object should be created
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }

  /**
   * Set the element associated with the constructor based on static type information to the given
   * element.
   * @param element the element to be associated with the constructor
   */
  void set staticElement(ConstructorElement element) {
    this._staticElement = element;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_constructorName, visitor);
    safelyVisitChild(_argumentList, visitor);
  }
}
/**
 * Instances of the class {@code IntegerLiteral} represent an integer literal expression.
 * <pre>
 * integerLiteral ::=
 * decimalIntegerLiteral
 * | hexidecimalIntegerLiteral
 * decimalIntegerLiteral ::=
 * decimalDigit+
 * hexidecimalIntegerLiteral ::=
 * '0x' hexidecimalDigit+
 * | '0X' hexidecimalDigit+
 * </pre>
 * @coverage dart.engine.ast
 */
class IntegerLiteral extends Literal {

  /**
   * The token representing the literal.
   */
  Token _literal;

  /**
   * The value of the literal.
   */
  int _value = 0;

  /**
   * Initialize a newly created integer literal.
   * @param literal the token representing the literal
   * @param value the value of the literal
   */
  IntegerLiteral.full(Token literal, int value) {
    this._literal = literal;
    this._value = value;
  }

  /**
   * Initialize a newly created integer literal.
   * @param literal the token representing the literal
   * @param value the value of the literal
   */
  IntegerLiteral({Token literal, int value}) : this.full(literal, value);
  accept(ASTVisitor visitor) => visitor.visitIntegerLiteral(this);
  Token get beginToken => _literal;
  Token get endToken => _literal;

  /**
   * Return the token representing the literal.
   * @return the token representing the literal
   */
  Token get literal => _literal;

  /**
   * Return the value of the literal.
   * @return the value of the literal
   */
  int get value => _value;

  /**
   * Set the token representing the literal to the given token.
   * @param literal the token representing the literal
   */
  void set literal(Token literal2) {
    this._literal = literal2;
  }

  /**
   * Set the value of the literal to the given value.
   * @param value the value of the literal
   */
  void set value(int value2) {
    this._value = value2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
  }
}
/**
 * The abstract class {@code InterpolationElement} defines the behavior common to elements within a{@link StringInterpolation string interpolation}.
 * <pre>
 * interpolationElement ::={@link InterpolationExpression interpolationExpression}| {@link InterpolationString interpolationString}</pre>
 * @coverage dart.engine.ast
 */
abstract class InterpolationElement extends ASTNode {
}
/**
 * Instances of the class {@code InterpolationExpression} represent an expression embedded in a
 * string interpolation.
 * <pre>
 * interpolationExpression ::=
 * '$' {@link SimpleIdentifier identifier}| '$' '{' {@link Expression expression} '}'
 * </pre>
 * @coverage dart.engine.ast
 */
class InterpolationExpression extends InterpolationElement {

  /**
   * The token used to introduce the interpolation expression; either '$' if the expression is a
   * simple identifier or '${' if the expression is a full expression.
   */
  Token _leftBracket;

  /**
   * The expression to be evaluated for the value to be converted into a string.
   */
  Expression _expression;

  /**
   * The right curly bracket, or {@code null} if the expression is an identifier without brackets.
   */
  Token _rightBracket;

  /**
   * Initialize a newly created interpolation expression.
   * @param leftBracket the left curly bracket
   * @param expression the expression to be evaluated for the value to be converted into a string
   * @param rightBracket the right curly bracket
   */
  InterpolationExpression.full(Token leftBracket, Expression expression, Token rightBracket) {
    this._leftBracket = leftBracket;
    this._expression = becomeParentOf(expression);
    this._rightBracket = rightBracket;
  }

  /**
   * Initialize a newly created interpolation expression.
   * @param leftBracket the left curly bracket
   * @param expression the expression to be evaluated for the value to be converted into a string
   * @param rightBracket the right curly bracket
   */
  InterpolationExpression({Token leftBracket, Expression expression, Token rightBracket}) : this.full(leftBracket, expression, rightBracket);
  accept(ASTVisitor visitor) => visitor.visitInterpolationExpression(this);
  Token get beginToken => _leftBracket;
  Token get endToken {
    if (_rightBracket != null) {
      return _rightBracket;
    }
    return _expression.endToken;
  }

  /**
   * Return the expression to be evaluated for the value to be converted into a string.
   * @return the expression to be evaluated for the value to be converted into a string
   */
  Expression get expression => _expression;

  /**
   * Return the left curly bracket.
   * @return the left curly bracket
   */
  Token get leftBracket => _leftBracket;

  /**
   * Return the right curly bracket.
   * @return the right curly bracket
   */
  Token get rightBracket => _rightBracket;

  /**
   * Set the expression to be evaluated for the value to be converted into a string to the given
   * expression.
   * @param expression the expression to be evaluated for the value to be converted into a string
   */
  void set expression(Expression expression2) {
    this._expression = becomeParentOf(expression2);
  }

  /**
   * Set the left curly bracket to the given token.
   * @param leftBracket the left curly bracket
   */
  void set leftBracket(Token leftBracket2) {
    this._leftBracket = leftBracket2;
  }

  /**
   * Set the right curly bracket to the given token.
   * @param rightBracket the right curly bracket
   */
  void set rightBracket(Token rightBracket2) {
    this._rightBracket = rightBracket2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_expression, visitor);
  }
}
/**
 * Instances of the class {@code InterpolationString} represent a non-empty substring of an
 * interpolated string.
 * <pre>
 * interpolationString ::=
 * characters
 * </pre>
 * @coverage dart.engine.ast
 */
class InterpolationString extends InterpolationElement {

  /**
   * The characters that will be added to the string.
   */
  Token _contents;

  /**
   * The value of the literal.
   */
  String _value;

  /**
   * Initialize a newly created string of characters that are part of a string interpolation.
   * @param the characters that will be added to the string
   * @param value the value of the literal
   */
  InterpolationString.full(Token contents, String value) {
    this._contents = contents;
    this._value = value;
  }

  /**
   * Initialize a newly created string of characters that are part of a string interpolation.
   * @param the characters that will be added to the string
   * @param value the value of the literal
   */
  InterpolationString({Token contents, String value}) : this.full(contents, value);
  accept(ASTVisitor visitor) => visitor.visitInterpolationString(this);
  Token get beginToken => _contents;

  /**
   * Return the characters that will be added to the string.
   * @return the characters that will be added to the string
   */
  Token get contents => _contents;
  Token get endToken => _contents;

  /**
   * Return the value of the literal.
   * @return the value of the literal
   */
  String get value => _value;

  /**
   * Set the characters that will be added to the string to those in the given string.
   * @param string the characters that will be added to the string
   */
  void set contents(Token string) {
    _contents = string;
  }

  /**
   * Set the value of the literal to the given string.
   * @param string the value of the literal
   */
  void set value(String string) {
    _value = string;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
  }
}
/**
 * Instances of the class {@code IsExpression} represent an is expression.
 * <pre>
 * isExpression ::={@link Expression expression} 'is' '!'? {@link TypeName type}</pre>
 * @coverage dart.engine.ast
 */
class IsExpression extends Expression {

  /**
   * The expression used to compute the value whose type is being tested.
   */
  Expression _expression;

  /**
   * The is operator.
   */
  Token _isOperator;

  /**
   * The not operator, or {@code null} if the sense of the test is not negated.
   */
  Token _notOperator;

  /**
   * The name of the type being tested for.
   */
  TypeName _type;

  /**
   * Initialize a newly created is expression.
   * @param expression the expression used to compute the value whose type is being tested
   * @param isOperator the is operator
   * @param notOperator the not operator, or {@code null} if the sense of the test is not negated
   * @param type the name of the type being tested for
   */
  IsExpression.full(Expression expression, Token isOperator, Token notOperator, TypeName type) {
    this._expression = becomeParentOf(expression);
    this._isOperator = isOperator;
    this._notOperator = notOperator;
    this._type = becomeParentOf(type);
  }

  /**
   * Initialize a newly created is expression.
   * @param expression the expression used to compute the value whose type is being tested
   * @param isOperator the is operator
   * @param notOperator the not operator, or {@code null} if the sense of the test is not negated
   * @param type the name of the type being tested for
   */
  IsExpression({Expression expression, Token isOperator, Token notOperator, TypeName type}) : this.full(expression, isOperator, notOperator, type);
  accept(ASTVisitor visitor) => visitor.visitIsExpression(this);
  Token get beginToken => _expression.beginToken;
  Token get endToken => _type.endToken;

  /**
   * Return the expression used to compute the value whose type is being tested.
   * @return the expression used to compute the value whose type is being tested
   */
  Expression get expression => _expression;

  /**
   * Return the is operator being applied.
   * @return the is operator being applied
   */
  Token get isOperator => _isOperator;

  /**
   * Return the not operator being applied.
   * @return the not operator being applied
   */
  Token get notOperator => _notOperator;

  /**
   * Return the name of the type being tested for.
   * @return the name of the type being tested for
   */
  TypeName get type => _type;

  /**
   * Set the expression used to compute the value whose type is being tested to the given
   * expression.
   * @param expression the expression used to compute the value whose type is being tested
   */
  void set expression(Expression expression2) {
    this._expression = becomeParentOf(expression2);
  }

  /**
   * Set the is operator being applied to the given operator.
   * @param isOperator the is operator being applied
   */
  void set isOperator(Token isOperator2) {
    this._isOperator = isOperator2;
  }

  /**
   * Set the not operator being applied to the given operator.
   * @param notOperator the is operator being applied
   */
  void set notOperator(Token notOperator2) {
    this._notOperator = notOperator2;
  }

  /**
   * Set the name of the type being tested for to the given name.
   * @param name the name of the type being tested for
   */
  void set type(TypeName name) {
    this._type = becomeParentOf(name);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_expression, visitor);
    safelyVisitChild(_type, visitor);
  }
}
/**
 * Instances of the class {@code Label} represent a label.
 * <pre>
 * label ::={@link SimpleIdentifier label} ':'
 * </pre>
 * @coverage dart.engine.ast
 */
class Label extends ASTNode {

  /**
   * The label being associated with the statement.
   */
  SimpleIdentifier _label;

  /**
   * The colon that separates the label from the statement.
   */
  Token _colon;

  /**
   * Initialize a newly created label.
   * @param label the label being applied
   * @param colon the colon that separates the label from whatever follows
   */
  Label.full(SimpleIdentifier label, Token colon) {
    this._label = becomeParentOf(label);
    this._colon = colon;
  }

  /**
   * Initialize a newly created label.
   * @param label the label being applied
   * @param colon the colon that separates the label from whatever follows
   */
  Label({SimpleIdentifier label, Token colon}) : this.full(label, colon);
  accept(ASTVisitor visitor) => visitor.visitLabel(this);
  Token get beginToken => _label.beginToken;

  /**
   * Return the colon that separates the label from the statement.
   * @return the colon that separates the label from the statement
   */
  Token get colon => _colon;
  Token get endToken => _colon;

  /**
   * Return the label being associated with the statement.
   * @return the label being associated with the statement
   */
  SimpleIdentifier get label => _label;

  /**
   * Set the colon that separates the label from the statement to the given token.
   * @param colon the colon that separates the label from the statement
   */
  void set colon(Token colon2) {
    this._colon = colon2;
  }

  /**
   * Set the label being associated with the statement to the given label.
   * @param label the label being associated with the statement
   */
  void set label(SimpleIdentifier label2) {
    this._label = becomeParentOf(label2);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_label, visitor);
  }
}
/**
 * Instances of the class {@code LabeledStatement} represent a statement that has a label associated
 * with them.
 * <pre>
 * labeledStatement ::={@link Label label}+ {@link Statement statement}</pre>
 * @coverage dart.engine.ast
 */
class LabeledStatement extends Statement {

  /**
   * The labels being associated with the statement.
   */
  NodeList<Label> _labels;

  /**
   * The statement with which the labels are being associated.
   */
  Statement _statement;

  /**
   * Initialize a newly created labeled statement.
   * @param labels the labels being associated with the statement
   * @param statement the statement with which the labels are being associated
   */
  LabeledStatement.full(List<Label> labels, Statement statement) {
    this._labels = new NodeList<Label>(this);
    this._labels.addAll(labels);
    this._statement = becomeParentOf(statement);
  }

  /**
   * Initialize a newly created labeled statement.
   * @param labels the labels being associated with the statement
   * @param statement the statement with which the labels are being associated
   */
  LabeledStatement({List<Label> labels, Statement statement}) : this.full(labels, statement);
  accept(ASTVisitor visitor) => visitor.visitLabeledStatement(this);
  Token get beginToken {
    if (!_labels.isEmpty) {
      return _labels.beginToken;
    }
    return _statement.beginToken;
  }
  Token get endToken => _statement.endToken;

  /**
   * Return the labels being associated with the statement.
   * @return the labels being associated with the statement
   */
  NodeList<Label> get labels => _labels;

  /**
   * Return the statement with which the labels are being associated.
   * @return the statement with which the labels are being associated
   */
  Statement get statement => _statement;

  /**
   * Set the statement with which the labels are being associated to the given statement.
   * @param statement the statement with which the labels are being associated
   */
  void set statement(Statement statement2) {
    this._statement = becomeParentOf(statement2);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    _labels.accept(visitor);
    safelyVisitChild(_statement, visitor);
  }
}
/**
 * Instances of the class {@code LibraryDirective} represent a library directive.
 * <pre>
 * libraryDirective ::={@link Annotation metadata} 'library' {@link Identifier name} ';'
 * </pre>
 * @coverage dart.engine.ast
 */
class LibraryDirective extends Directive {

  /**
   * The token representing the 'library' token.
   */
  Token _libraryToken;

  /**
   * The name of the library being defined.
   */
  LibraryIdentifier _name;

  /**
   * The semicolon terminating the directive.
   */
  Token _semicolon;

  /**
   * Initialize a newly created library directive.
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   * @param libraryToken the token representing the 'library' token
   * @param name the name of the library being defined
   * @param semicolon the semicolon terminating the directive
   */
  LibraryDirective.full(Comment comment, List<Annotation> metadata, Token libraryToken, LibraryIdentifier name, Token semicolon) : super.full(comment, metadata) {
    this._libraryToken = libraryToken;
    this._name = becomeParentOf(name);
    this._semicolon = semicolon;
  }

  /**
   * Initialize a newly created library directive.
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   * @param libraryToken the token representing the 'library' token
   * @param name the name of the library being defined
   * @param semicolon the semicolon terminating the directive
   */
  LibraryDirective({Comment comment, List<Annotation> metadata, Token libraryToken, LibraryIdentifier name, Token semicolon}) : this.full(comment, metadata, libraryToken, name, semicolon);
  accept(ASTVisitor visitor) => visitor.visitLibraryDirective(this);
  Token get endToken => _semicolon;
  Token get keyword => _libraryToken;

  /**
   * Return the token representing the 'library' token.
   * @return the token representing the 'library' token
   */
  Token get libraryToken => _libraryToken;

  /**
   * Return the name of the library being defined.
   * @return the name of the library being defined
   */
  LibraryIdentifier get name => _name;

  /**
   * Return the semicolon terminating the directive.
   * @return the semicolon terminating the directive
   */
  Token get semicolon => _semicolon;

  /**
   * Set the token representing the 'library' token to the given token.
   * @param libraryToken the token representing the 'library' token
   */
  void set libraryToken(Token libraryToken2) {
    this._libraryToken = libraryToken2;
  }

  /**
   * Set the name of the library being defined to the given name.
   * @param name the name of the library being defined
   */
  void set name(LibraryIdentifier name2) {
    this._name = becomeParentOf(name2);
  }

  /**
   * Set the semicolon terminating the directive to the given token.
   * @param semicolon the semicolon terminating the directive
   */
  void set semicolon(Token semicolon2) {
    this._semicolon = semicolon2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_name, visitor);
  }
  Token get firstTokenAfterCommentAndMetadata => _libraryToken;
}
/**
 * Instances of the class {@code LibraryIdentifier} represent the identifier for a library.
 * <pre>
 * libraryIdentifier ::={@link SimpleIdentifier component} ('.' {@link SimpleIdentifier component})
 * </pre>
 * @coverage dart.engine.ast
 */
class LibraryIdentifier extends Identifier {

  /**
   * The components of the identifier.
   */
  NodeList<SimpleIdentifier> _components;

  /**
   * Initialize a newly created prefixed identifier.
   * @param components the components of the identifier
   */
  LibraryIdentifier.full(List<SimpleIdentifier> components) {
    this._components = new NodeList<SimpleIdentifier>(this);
    this._components.addAll(components);
  }

  /**
   * Initialize a newly created prefixed identifier.
   * @param components the components of the identifier
   */
  LibraryIdentifier({List<SimpleIdentifier> components}) : this.full(components);
  accept(ASTVisitor visitor) => visitor.visitLibraryIdentifier(this);
  Token get beginToken => _components.beginToken;

  /**
   * Return the components of the identifier.
   * @return the components of the identifier
   */
  NodeList<SimpleIdentifier> get components => _components;
  Element get element => null;
  Token get endToken => _components.endToken;
  String get name {
    JavaStringBuilder builder = new JavaStringBuilder();
    bool needsPeriod = false;
    for (SimpleIdentifier identifier in _components) {
      if (needsPeriod) {
        builder.append(".");
      } else {
        needsPeriod = true;
      }
      builder.append(identifier.name);
    }
    return builder.toString();
  }
  Element get staticElement => null;
  void visitChildren(ASTVisitor<Object> visitor) {
    _components.accept(visitor);
  }
}
/**
 * Instances of the class {@code ListLiteral} represent a list literal.
 * <pre>
 * listLiteral ::=
 * 'const'? ('<' {@link TypeName type} '>')? '\[' ({@link Expression expressionList} ','?)? '\]'
 * </pre>
 * @coverage dart.engine.ast
 */
class ListLiteral extends TypedLiteral {

  /**
   * The left square bracket.
   */
  Token _leftBracket;

  /**
   * The expressions used to compute the elements of the list.
   */
  NodeList<Expression> _elements;

  /**
   * The right square bracket.
   */
  Token _rightBracket;

  /**
   * Initialize a newly created list literal.
   * @param modifier the const modifier associated with this literal
   * @param typeArguments the type argument associated with this literal, or {@code null} if no type
   * arguments were declared
   * @param leftBracket the left square bracket
   * @param elements the expressions used to compute the elements of the list
   * @param rightBracket the right square bracket
   */
  ListLiteral.full(Token modifier, TypeArgumentList typeArguments, Token leftBracket, List<Expression> elements, Token rightBracket) : super.full(modifier, typeArguments) {
    this._elements = new NodeList<Expression>(this);
    this._leftBracket = leftBracket;
    this._elements.addAll(elements);
    this._rightBracket = rightBracket;
  }

  /**
   * Initialize a newly created list literal.
   * @param modifier the const modifier associated with this literal
   * @param typeArguments the type argument associated with this literal, or {@code null} if no type
   * arguments were declared
   * @param leftBracket the left square bracket
   * @param elements the expressions used to compute the elements of the list
   * @param rightBracket the right square bracket
   */
  ListLiteral({Token modifier, TypeArgumentList typeArguments, Token leftBracket, List<Expression> elements, Token rightBracket}) : this.full(modifier, typeArguments, leftBracket, elements, rightBracket);
  accept(ASTVisitor visitor) => visitor.visitListLiteral(this);
  Token get beginToken {
    Token token = modifier;
    if (token != null) {
      return token;
    }
    TypeArgumentList typeArguments = this.typeArguments;
    if (typeArguments != null) {
      return typeArguments.beginToken;
    }
    return _leftBracket;
  }

  /**
   * Return the expressions used to compute the elements of the list.
   * @return the expressions used to compute the elements of the list
   */
  NodeList<Expression> get elements => _elements;
  Token get endToken => _rightBracket;

  /**
   * Return the left square bracket.
   * @return the left square bracket
   */
  Token get leftBracket => _leftBracket;

  /**
   * Return the right square bracket.
   * @return the right square bracket
   */
  Token get rightBracket => _rightBracket;

  /**
   * Set the left square bracket to the given token.
   * @param bracket the left square bracket
   */
  void set leftBracket(Token bracket) {
    _leftBracket = bracket;
  }

  /**
   * Set the right square bracket to the given token.
   * @param bracket the right square bracket
   */
  void set rightBracket(Token bracket) {
    _rightBracket = bracket;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    super.visitChildren(visitor);
    _elements.accept(visitor);
  }
}
/**
 * The abstract class {@code Literal} defines the behavior common to nodes that represent a literal
 * expression.
 * <pre>
 * literal ::={@link BooleanLiteral booleanLiteral}| {@link DoubleLiteral doubleLiteral}| {@link IntegerLiteral integerLiteral}| {@link ListLiteral listLiteral}| {@link MapLiteral mapLiteral}| {@link NullLiteral nullLiteral}| {@link StringLiteral stringLiteral}</pre>
 * @coverage dart.engine.ast
 */
abstract class Literal extends Expression {
}
/**
 * Instances of the class {@code MapLiteral} represent a literal map.
 * <pre>
 * mapLiteral ::=
 * 'const'? ('<' {@link TypeName type} (',' {@link TypeName type})* '>')? '{' ({@link MapLiteralEntry entry} (',' {@link MapLiteralEntry entry})* ','?)? '}'
 * </pre>
 * @coverage dart.engine.ast
 */
class MapLiteral extends TypedLiteral {

  /**
   * The left curly bracket.
   */
  Token _leftBracket;

  /**
   * The entries in the map.
   */
  NodeList<MapLiteralEntry> _entries;

  /**
   * The right curly bracket.
   */
  Token _rightBracket;

  /**
   * Initialize a newly created map literal.
   * @param modifier the const modifier associated with this literal
   * @param typeArguments the type argument associated with this literal, or {@code null} if no type
   * arguments were declared
   * @param leftBracket the left curly bracket
   * @param entries the entries in the map
   * @param rightBracket the right curly bracket
   */
  MapLiteral.full(Token modifier, TypeArgumentList typeArguments, Token leftBracket, List<MapLiteralEntry> entries, Token rightBracket) : super.full(modifier, typeArguments) {
    this._entries = new NodeList<MapLiteralEntry>(this);
    this._leftBracket = leftBracket;
    this._entries.addAll(entries);
    this._rightBracket = rightBracket;
  }

  /**
   * Initialize a newly created map literal.
   * @param modifier the const modifier associated with this literal
   * @param typeArguments the type argument associated with this literal, or {@code null} if no type
   * arguments were declared
   * @param leftBracket the left curly bracket
   * @param entries the entries in the map
   * @param rightBracket the right curly bracket
   */
  MapLiteral({Token modifier, TypeArgumentList typeArguments, Token leftBracket, List<MapLiteralEntry> entries, Token rightBracket}) : this.full(modifier, typeArguments, leftBracket, entries, rightBracket);
  accept(ASTVisitor visitor) => visitor.visitMapLiteral(this);
  Token get beginToken {
    Token token = modifier;
    if (token != null) {
      return token;
    }
    TypeArgumentList typeArguments = this.typeArguments;
    if (typeArguments != null) {
      return typeArguments.beginToken;
    }
    return _leftBracket;
  }
  Token get endToken => _rightBracket;

  /**
   * Return the entries in the map.
   * @return the entries in the map
   */
  NodeList<MapLiteralEntry> get entries => _entries;

  /**
   * Return the left curly bracket.
   * @return the left curly bracket
   */
  Token get leftBracket => _leftBracket;

  /**
   * Return the right curly bracket.
   * @return the right curly bracket
   */
  Token get rightBracket => _rightBracket;

  /**
   * Set the left curly bracket to the given token.
   * @param bracket the left curly bracket
   */
  void set leftBracket(Token bracket) {
    _leftBracket = bracket;
  }

  /**
   * Set the right curly bracket to the given token.
   * @param bracket the right curly bracket
   */
  void set rightBracket(Token bracket) {
    _rightBracket = bracket;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    super.visitChildren(visitor);
    _entries.accept(visitor);
  }
}
/**
 * Instances of the class {@code MapLiteralEntry} represent a single key/value pair in a map
 * literal.
 * <pre>
 * mapLiteralEntry ::={@link Expression key} ':' {@link Expression value}</pre>
 * @coverage dart.engine.ast
 */
class MapLiteralEntry extends ASTNode {

  /**
   * The expression computing the key with which the value will be associated.
   */
  Expression _key;

  /**
   * The colon that separates the key from the value.
   */
  Token _separator;

  /**
   * The expression computing the value that will be associated with the key.
   */
  Expression _value;

  /**
   * Initialize a newly created map literal entry.
   * @param key the expression computing the key with which the value will be associated
   * @param separator the colon that separates the key from the value
   * @param value the expression computing the value that will be associated with the key
   */
  MapLiteralEntry.full(Expression key, Token separator, Expression value) {
    this._key = becomeParentOf(key);
    this._separator = separator;
    this._value = becomeParentOf(value);
  }

  /**
   * Initialize a newly created map literal entry.
   * @param key the expression computing the key with which the value will be associated
   * @param separator the colon that separates the key from the value
   * @param value the expression computing the value that will be associated with the key
   */
  MapLiteralEntry({Expression key, Token separator, Expression value}) : this.full(key, separator, value);
  accept(ASTVisitor visitor) => visitor.visitMapLiteralEntry(this);
  Token get beginToken => _key.beginToken;
  Token get endToken => _value.endToken;

  /**
   * Return the expression computing the key with which the value will be associated.
   * @return the expression computing the key with which the value will be associated
   */
  Expression get key => _key;

  /**
   * Return the colon that separates the key from the value.
   * @return the colon that separates the key from the value
   */
  Token get separator => _separator;

  /**
   * Return the expression computing the value that will be associated with the key.
   * @return the expression computing the value that will be associated with the key
   */
  Expression get value => _value;

  /**
   * Set the expression computing the key with which the value will be associated to the given
   * string.
   * @param string the expression computing the key with which the value will be associated
   */
  void set key(Expression string) {
    _key = becomeParentOf(string);
  }

  /**
   * Set the colon that separates the key from the value to the given token.
   * @param separator the colon that separates the key from the value
   */
  void set separator(Token separator2) {
    this._separator = separator2;
  }

  /**
   * Set the expression computing the value that will be associated with the key to the given
   * expression.
   * @param expression the expression computing the value that will be associated with the key
   */
  void set value(Expression expression) {
    _value = becomeParentOf(expression);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_key, visitor);
    safelyVisitChild(_value, visitor);
  }
}
/**
 * Instances of the class {@code MethodDeclaration} represent a method declaration.
 * <pre>
 * methodDeclaration ::=
 * methodSignature {@link FunctionBody body}methodSignature ::=
 * 'external'? ('abstract' | 'static')? {@link Type returnType}? ('get' | 'set')? methodName{@link FormalParameterList formalParameterList}methodName ::={@link SimpleIdentifier name}| 'operator' {@link SimpleIdentifier operator}</pre>
 * @coverage dart.engine.ast
 */
class MethodDeclaration extends ClassMember {

  /**
   * The token for the 'external' keyword, or {@code null} if the constructor is not external.
   */
  Token _externalKeyword;

  /**
   * The token representing the 'abstract' or 'static' keyword, or {@code null} if neither modifier
   * was specified.
   */
  Token _modifierKeyword;

  /**
   * The return type of the method, or {@code null} if no return type was declared.
   */
  TypeName _returnType;

  /**
   * The token representing the 'get' or 'set' keyword, or {@code null} if this is a method
   * declaration rather than a property declaration.
   */
  Token _propertyKeyword;

  /**
   * The token representing the 'operator' keyword, or {@code null} if this method does not declare
   * an operator.
   */
  Token _operatorKeyword;

  /**
   * The name of the method.
   */
  SimpleIdentifier _name;

  /**
   * The parameters associated with the method, or {@code null} if this method declares a getter.
   */
  FormalParameterList _parameters;

  /**
   * The body of the method.
   */
  FunctionBody _body;

  /**
   * Initialize a newly created method declaration.
   * @param externalKeyword the token for the 'external' keyword
   * @param comment the documentation comment associated with this method
   * @param metadata the annotations associated with this method
   * @param modifierKeyword the token representing the 'abstract' or 'static' keyword
   * @param returnType the return type of the method
   * @param propertyKeyword the token representing the 'get' or 'set' keyword
   * @param operatorKeyword the token representing the 'operator' keyword
   * @param name the name of the method
   * @param parameters the parameters associated with the method, or {@code null} if this method
   * declares a getter
   * @param body the body of the method
   */
  MethodDeclaration.full(Comment comment, List<Annotation> metadata, Token externalKeyword, Token modifierKeyword, TypeName returnType, Token propertyKeyword, Token operatorKeyword, SimpleIdentifier name, FormalParameterList parameters, FunctionBody body) : super.full(comment, metadata) {
    this._externalKeyword = externalKeyword;
    this._modifierKeyword = modifierKeyword;
    this._returnType = becomeParentOf(returnType);
    this._propertyKeyword = propertyKeyword;
    this._operatorKeyword = operatorKeyword;
    this._name = becomeParentOf(name);
    this._parameters = becomeParentOf(parameters);
    this._body = becomeParentOf(body);
  }

  /**
   * Initialize a newly created method declaration.
   * @param externalKeyword the token for the 'external' keyword
   * @param comment the documentation comment associated with this method
   * @param metadata the annotations associated with this method
   * @param modifierKeyword the token representing the 'abstract' or 'static' keyword
   * @param returnType the return type of the method
   * @param propertyKeyword the token representing the 'get' or 'set' keyword
   * @param operatorKeyword the token representing the 'operator' keyword
   * @param name the name of the method
   * @param parameters the parameters associated with the method, or {@code null} if this method
   * declares a getter
   * @param body the body of the method
   */
  MethodDeclaration({Comment comment, List<Annotation> metadata, Token externalKeyword, Token modifierKeyword, TypeName returnType, Token propertyKeyword, Token operatorKeyword, SimpleIdentifier name, FormalParameterList parameters, FunctionBody body}) : this.full(comment, metadata, externalKeyword, modifierKeyword, returnType, propertyKeyword, operatorKeyword, name, parameters, body);
  accept(ASTVisitor visitor) => visitor.visitMethodDeclaration(this);

  /**
   * Return the body of the method.
   * @return the body of the method
   */
  FunctionBody get body => _body;

  /**
   * Return the element associated with this method, or {@code null} if the AST structure has not
   * been resolved. The element can either be a {@link MethodElement}, if this represents the
   * declaration of a normal method, or a {@link PropertyAccessorElement} if this represents the
   * declaration of either a getter or a setter.
   * @return the element associated with this method
   */
  ExecutableElement get element => _name != null ? (_name.element as ExecutableElement) : null;
  Token get endToken => _body.endToken;

  /**
   * Return the token for the 'external' keyword, or {@code null} if the constructor is not
   * external.
   * @return the token for the 'external' keyword
   */
  Token get externalKeyword => _externalKeyword;

  /**
   * Return the token representing the 'abstract' or 'static' keyword, or {@code null} if neither
   * modifier was specified.
   * @return the token representing the 'abstract' or 'static' keyword
   */
  Token get modifierKeyword => _modifierKeyword;

  /**
   * Return the name of the method.
   * @return the name of the method
   */
  SimpleIdentifier get name => _name;

  /**
   * Return the token representing the 'operator' keyword, or {@code null} if this method does not
   * declare an operator.
   * @return the token representing the 'operator' keyword
   */
  Token get operatorKeyword => _operatorKeyword;

  /**
   * Return the parameters associated with the method, or {@code null} if this method declares a
   * getter.
   * @return the parameters associated with the method
   */
  FormalParameterList get parameters => _parameters;

  /**
   * Return the token representing the 'get' or 'set' keyword, or {@code null} if this is a method
   * declaration rather than a property declaration.
   * @return the token representing the 'get' or 'set' keyword
   */
  Token get propertyKeyword => _propertyKeyword;

  /**
   * Return the return type of the method, or {@code null} if no return type was declared.
   * @return the return type of the method
   */
  TypeName get returnType => _returnType;

  /**
   * Return {@code true} if this method is declared to be an abstract method.
   * @return {@code true} if this method is declared to be an abstract method
   */
  bool isAbstract() => _externalKeyword == null && (_body is EmptyFunctionBody);

  /**
   * Return {@code true} if this method declares a getter.
   * @return {@code true} if this method declares a getter
   */
  bool isGetter() => _propertyKeyword != null && identical(((_propertyKeyword as KeywordToken)).keyword, Keyword.GET);

  /**
   * Return {@code true} if this method declares an operator.
   * @return {@code true} if this method declares an operator
   */
  bool isOperator() => _operatorKeyword != null;

  /**
   * Return {@code true} if this method declares a setter.
   * @return {@code true} if this method declares a setter
   */
  bool isSetter() => _propertyKeyword != null && identical(((_propertyKeyword as KeywordToken)).keyword, Keyword.SET);

  /**
   * Return {@code true} if this method is declared to be a static method.
   * @return {@code true} if this method is declared to be a static method
   */
  bool isStatic() => _modifierKeyword != null && identical(((_modifierKeyword as KeywordToken)).keyword, Keyword.STATIC);

  /**
   * Set the body of the method to the given function body.
   * @param functionBody the body of the method
   */
  void set body(FunctionBody functionBody) {
    _body = becomeParentOf(functionBody);
  }

  /**
   * Set the token for the 'external' keyword to the given token.
   * @param externalKeyword the token for the 'external' keyword
   */
  void set externalKeyword(Token externalKeyword2) {
    this._externalKeyword = externalKeyword2;
  }

  /**
   * Set the token representing the 'abstract' or 'static' keyword to the given token.
   * @param modifierKeyword the token representing the 'abstract' or 'static' keyword
   */
  void set modifierKeyword(Token modifierKeyword2) {
    this._modifierKeyword = modifierKeyword2;
  }

  /**
   * Set the name of the method to the given identifier.
   * @param identifier the name of the method
   */
  void set name(SimpleIdentifier identifier) {
    _name = becomeParentOf(identifier);
  }

  /**
   * Set the token representing the 'operator' keyword to the given token.
   * @param operatorKeyword the token representing the 'operator' keyword
   */
  void set operatorKeyword(Token operatorKeyword2) {
    this._operatorKeyword = operatorKeyword2;
  }

  /**
   * Set the parameters associated with the method to the given list of parameters.
   * @param parameters the parameters associated with the method
   */
  void set parameters(FormalParameterList parameters2) {
    this._parameters = becomeParentOf(parameters2);
  }

  /**
   * Set the token representing the 'get' or 'set' keyword to the given token.
   * @param propertyKeyword the token representing the 'get' or 'set' keyword
   */
  void set propertyKeyword(Token propertyKeyword2) {
    this._propertyKeyword = propertyKeyword2;
  }

  /**
   * Set the return type of the method to the given type name.
   * @param typeName the return type of the method
   */
  void set returnType(TypeName typeName) {
    _returnType = becomeParentOf(typeName);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_returnType, visitor);
    safelyVisitChild(_name, visitor);
    safelyVisitChild(_parameters, visitor);
    safelyVisitChild(_body, visitor);
  }
  Token get firstTokenAfterCommentAndMetadata {
    if (_modifierKeyword != null) {
      return _modifierKeyword;
    } else if (_returnType != null) {
      return _returnType.beginToken;
    } else if (_propertyKeyword != null) {
      return _propertyKeyword;
    } else if (_operatorKeyword != null) {
      return _operatorKeyword;
    }
    return _name.beginToken;
  }
}
/**
 * Instances of the class {@code MethodInvocation} represent the invocation of either a function or
 * a method. Invocations of functions resulting from evaluating an expression are represented by{@link FunctionExpressionInvocation function expression invocation} nodes. Invocations of getters
 * and setters are represented by either {@link PrefixedIdentifier prefixed identifier} or{@link PropertyAccess property access} nodes.
 * <pre>
 * methodInvoction ::=
 * ({@link Expression target} '.')? {@link SimpleIdentifier methodName} {@link ArgumentList argumentList}</pre>
 * @coverage dart.engine.ast
 */
class MethodInvocation extends Expression {

  /**
   * The expression producing the object on which the method is defined, or {@code null} if there is
   * no target (that is, the target is implicitly {@code this}).
   */
  Expression _target;

  /**
   * The period that separates the target from the method name, or {@code null} if there is no
   * target.
   */
  Token _period;

  /**
   * The name of the method being invoked.
   */
  SimpleIdentifier _methodName;

  /**
   * The list of arguments to the method.
   */
  ArgumentList _argumentList;

  /**
   * Initialize a newly created method invocation.
   * @param target the expression producing the object on which the method is defined
   * @param period the period that separates the target from the method name
   * @param methodName the name of the method being invoked
   * @param argumentList the list of arguments to the method
   */
  MethodInvocation.full(Expression target, Token period, SimpleIdentifier methodName, ArgumentList argumentList) {
    this._target = becomeParentOf(target);
    this._period = period;
    this._methodName = becomeParentOf(methodName);
    this._argumentList = becomeParentOf(argumentList);
  }

  /**
   * Initialize a newly created method invocation.
   * @param target the expression producing the object on which the method is defined
   * @param period the period that separates the target from the method name
   * @param methodName the name of the method being invoked
   * @param argumentList the list of arguments to the method
   */
  MethodInvocation({Expression target, Token period, SimpleIdentifier methodName, ArgumentList argumentList}) : this.full(target, period, methodName, argumentList);
  accept(ASTVisitor visitor) => visitor.visitMethodInvocation(this);

  /**
   * Return the list of arguments to the method.
   * @return the list of arguments to the method
   */
  ArgumentList get argumentList => _argumentList;
  Token get beginToken {
    if (_target != null) {
      return _target.beginToken;
    } else if (_period != null) {
      return _period;
    }
    return _methodName.beginToken;
  }
  Token get endToken => _argumentList.endToken;

  /**
   * Return the name of the method being invoked.
   * @return the name of the method being invoked
   */
  SimpleIdentifier get methodName => _methodName;

  /**
   * Return the period that separates the target from the method name, or {@code null} if there is
   * no target.
   * @return the period that separates the target from the method name
   */
  Token get period => _period;

  /**
   * Return the expression used to compute the receiver of the invocation. If this invocation is not
   * part of a cascade expression, then this is the same as {@link #getTarget()}. If this invocation
   * is part of a cascade expression, then the target stored with the cascade expression is
   * returned.
   * @return the expression used to compute the receiver of the invocation
   * @see #getTarget()
   */
  Expression get realTarget {
    if (isCascaded()) {
      ASTNode ancestor = parent;
      while (ancestor is! CascadeExpression) {
        if (ancestor == null) {
          return _target;
        }
        ancestor = ancestor.parent;
      }
      return ((ancestor as CascadeExpression)).target;
    }
    return _target;
  }

  /**
   * Return the expression producing the object on which the method is defined, or {@code null} if
   * there is no target (that is, the target is implicitly {@code this}) or if this method
   * invocation is part of a cascade expression.
   * @return the expression producing the object on which the method is defined
   * @see #getRealTarget()
   */
  Expression get target => _target;

  /**
   * Return {@code true} if this expression is cascaded. If it is, then the target of this
   * expression is not stored locally but is stored in the nearest ancestor that is a{@link CascadeExpression}.
   * @return {@code true} if this expression is cascaded
   */
  bool isCascaded() => _period != null && identical(_period.type, TokenType.PERIOD_PERIOD);

  /**
   * Set the list of arguments to the method to the given list.
   * @param argumentList the list of arguments to the method
   */
  void set argumentList(ArgumentList argumentList2) {
    this._argumentList = becomeParentOf(argumentList2);
  }

  /**
   * Set the name of the method being invoked to the given identifier.
   * @param identifier the name of the method being invoked
   */
  void set methodName(SimpleIdentifier identifier) {
    _methodName = becomeParentOf(identifier);
  }

  /**
   * Set the period that separates the target from the method name to the given token.
   * @param period the period that separates the target from the method name
   */
  void set period(Token period2) {
    this._period = period2;
  }

  /**
   * Set the expression producing the object on which the method is defined to the given expression.
   * @param expression the expression producing the object on which the method is defined
   */
  void set target(Expression expression) {
    _target = becomeParentOf(expression);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_target, visitor);
    safelyVisitChild(_methodName, visitor);
    safelyVisitChild(_argumentList, visitor);
  }
}
/**
 * Instances of the class {@code NamedExpression} represent an expression that has a name associated
 * with it. They are used in method invocations when there are named parameters.
 * <pre>
 * namedExpression ::={@link Label name} {@link Expression expression}</pre>
 * @coverage dart.engine.ast
 */
class NamedExpression extends Expression {

  /**
   * The name associated with the expression.
   */
  Label _name;

  /**
   * The expression with which the name is associated.
   */
  Expression _expression;

  /**
   * Initialize a newly created named expression.
   * @param name the name associated with the expression
   * @param expression the expression with which the name is associated
   */
  NamedExpression.full(Label name, Expression expression) {
    this._name = becomeParentOf(name);
    this._expression = becomeParentOf(expression);
  }

  /**
   * Initialize a newly created named expression.
   * @param name the name associated with the expression
   * @param expression the expression with which the name is associated
   */
  NamedExpression({Label name, Expression expression}) : this.full(name, expression);
  accept(ASTVisitor visitor) => visitor.visitNamedExpression(this);
  Token get beginToken => _name.beginToken;

  /**
   * Return the element representing the parameter being named by this expression, or {@code null}if the AST structure has not been resolved or if there is no parameter with the same name as
   * this expression.
   * @return the element representing the parameter being named by this expression
   */
  ParameterElement get element {
    Element element = _name.label.element;
    if (element is ParameterElement) {
      return element as ParameterElement;
    }
    return null;
  }
  Token get endToken => _expression.endToken;

  /**
   * Return the expression with which the name is associated.
   * @return the expression with which the name is associated
   */
  Expression get expression => _expression;

  /**
   * Return the name associated with the expression.
   * @return the name associated with the expression
   */
  Label get name => _name;

  /**
   * Set the expression with which the name is associated to the given expression.
   * @param expression the expression with which the name is associated
   */
  void set expression(Expression expression2) {
    this._expression = becomeParentOf(expression2);
  }

  /**
   * Set the name associated with the expression to the given identifier.
   * @param identifier the name associated with the expression
   */
  void set name(Label identifier) {
    _name = becomeParentOf(identifier);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_name, visitor);
    safelyVisitChild(_expression, visitor);
  }
}
/**
 * The abstract class {@code NamespaceDirective} defines the behavior common to nodes that represent
 * a directive that impacts the namespace of a library.
 * <pre>
 * directive ::={@link ExportDirective exportDirective}| {@link ImportDirective importDirective}</pre>
 * @coverage dart.engine.ast
 */
abstract class NamespaceDirective extends UriBasedDirective {

  /**
   * The token representing the 'import' or 'export' keyword.
   */
  Token _keyword;

  /**
   * The combinators used to control which names are imported or exported.
   */
  NodeList<Combinator> _combinators;

  /**
   * The semicolon terminating the directive.
   */
  Token _semicolon;

  /**
   * Initialize a newly created namespace directive.
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   * @param keyword the token representing the 'import' or 'export' keyword
   * @param libraryUri the URI of the library being imported or exported
   * @param combinators the combinators used to control which names are imported or exported
   * @param semicolon the semicolon terminating the directive
   */
  NamespaceDirective.full(Comment comment, List<Annotation> metadata, Token keyword, StringLiteral libraryUri, List<Combinator> combinators, Token semicolon) : super.full(comment, metadata, libraryUri) {
    this._combinators = new NodeList<Combinator>(this);
    this._keyword = keyword;
    this._combinators.addAll(combinators);
    this._semicolon = semicolon;
  }

  /**
   * Initialize a newly created namespace directive.
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   * @param keyword the token representing the 'import' or 'export' keyword
   * @param libraryUri the URI of the library being imported or exported
   * @param combinators the combinators used to control which names are imported or exported
   * @param semicolon the semicolon terminating the directive
   */
  NamespaceDirective({Comment comment, List<Annotation> metadata, Token keyword, StringLiteral libraryUri, List<Combinator> combinators, Token semicolon}) : this.full(comment, metadata, keyword, libraryUri, combinators, semicolon);

  /**
   * Return the combinators used to control how names are imported or exported.
   * @return the combinators used to control how names are imported or exported
   */
  NodeList<Combinator> get combinators => _combinators;
  Token get endToken => _semicolon;
  Token get keyword => _keyword;

  /**
   * Return the semicolon terminating the directive.
   * @return the semicolon terminating the directive
   */
  Token get semicolon => _semicolon;
  LibraryElement get uriElement;

  /**
   * Set the token representing the 'import' or 'export' keyword to the given token.
   * @param exportToken the token representing the 'import' or 'export' keyword
   */
  void set keyword(Token exportToken) {
    this._keyword = exportToken;
  }

  /**
   * Set the semicolon terminating the directive to the given token.
   * @param semicolon the semicolon terminating the directive
   */
  void set semicolon(Token semicolon2) {
    this._semicolon = semicolon2;
  }
  Token get firstTokenAfterCommentAndMetadata => _keyword;
}
/**
 * Instances of the class {@code NativeFunctionBody} represent a function body that consists of a
 * native keyword followed by a string literal.
 * <pre>
 * nativeFunctionBody ::=
 * 'native' {@link SimpleStringLiteral simpleStringLiteral} ';'
 * </pre>
 * @coverage dart.engine.ast
 */
class NativeFunctionBody extends FunctionBody {

  /**
   * The token representing 'native' that marks the start of the function body.
   */
  Token _nativeToken;

  /**
   * The string literal, after the 'native' token.
   */
  StringLiteral _stringLiteral;

  /**
   * The token representing the semicolon that marks the end of the function body.
   */
  Token _semicolon;

  /**
   * Initialize a newly created function body consisting of the 'native' token, a string literal,
   * and a semicolon.
   * @param nativeToken the token representing 'native' that marks the start of the function body
   * @param stringLiteral the string literal
   * @param semicolon the token representing the semicolon that marks the end of the function body
   */
  NativeFunctionBody.full(Token nativeToken, StringLiteral stringLiteral, Token semicolon) {
    this._nativeToken = nativeToken;
    this._stringLiteral = becomeParentOf(stringLiteral);
    this._semicolon = semicolon;
  }

  /**
   * Initialize a newly created function body consisting of the 'native' token, a string literal,
   * and a semicolon.
   * @param nativeToken the token representing 'native' that marks the start of the function body
   * @param stringLiteral the string literal
   * @param semicolon the token representing the semicolon that marks the end of the function body
   */
  NativeFunctionBody({Token nativeToken, StringLiteral stringLiteral, Token semicolon}) : this.full(nativeToken, stringLiteral, semicolon);
  accept(ASTVisitor visitor) => visitor.visitNativeFunctionBody(this);
  Token get beginToken => _nativeToken;
  Token get endToken => _semicolon;

  /**
   * Return the simple identifier representing the 'native' token.
   * @return the simple identifier representing the 'native' token
   */
  Token get nativeToken => _nativeToken;

  /**
   * Return the token representing the semicolon that marks the end of the function body.
   * @return the token representing the semicolon that marks the end of the function body
   */
  Token get semicolon => _semicolon;

  /**
   * Return the string literal representing the string after the 'native' token.
   * @return the string literal representing the string after the 'native' token
   */
  StringLiteral get stringLiteral => _stringLiteral;
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_stringLiteral, visitor);
  }
}
/**
 * The abstract class {@code NormalFormalParameter} defines the behavior common to formal parameters
 * that are required (are not optional).
 * <pre>
 * normalFormalParameter ::={@link FunctionTypedFormalParameter functionSignature}| {@link FieldFormalParameter fieldFormalParameter}| {@link SimpleFormalParameter simpleFormalParameter}</pre>
 * @coverage dart.engine.ast
 */
abstract class NormalFormalParameter extends FormalParameter {

  /**
   * The documentation comment associated with this parameter, or {@code null} if this parameter
   * does not have a documentation comment associated with it.
   */
  Comment _comment;

  /**
   * The annotations associated with this parameter.
   */
  NodeList<Annotation> _metadata;

  /**
   * The name of the parameter being declared.
   */
  SimpleIdentifier _identifier;

  /**
   * Initialize a newly created formal parameter.
   * @param comment the documentation comment associated with this parameter
   * @param metadata the annotations associated with this parameter
   * @param identifier the name of the parameter being declared
   */
  NormalFormalParameter.full(Comment comment, List<Annotation> metadata, SimpleIdentifier identifier) {
    this._metadata = new NodeList<Annotation>(this);
    this._comment = becomeParentOf(comment);
    this._metadata.addAll(metadata);
    this._identifier = becomeParentOf(identifier);
  }

  /**
   * Initialize a newly created formal parameter.
   * @param comment the documentation comment associated with this parameter
   * @param metadata the annotations associated with this parameter
   * @param identifier the name of the parameter being declared
   */
  NormalFormalParameter({Comment comment, List<Annotation> metadata, SimpleIdentifier identifier}) : this.full(comment, metadata, identifier);

  /**
   * Return the documentation comment associated with this parameter, or {@code null} if this
   * parameter does not have a documentation comment associated with it.
   * @return the documentation comment associated with this parameter
   */
  Comment get documentationComment => _comment;
  SimpleIdentifier get identifier => _identifier;
  ParameterKind get kind {
    ASTNode parent = this.parent;
    if (parent is DefaultFormalParameter) {
      return ((parent as DefaultFormalParameter)).kind;
    }
    return ParameterKind.REQUIRED;
  }

  /**
   * Return the annotations associated with this parameter.
   * @return the annotations associated with this parameter
   */
  NodeList<Annotation> get metadata => _metadata;

  /**
   * Return {@code true} if this parameter was declared with the 'const' modifier.
   * @return {@code true} if this parameter was declared with the 'const' modifier
   */
  bool isConst();

  /**
   * Return {@code true} if this parameter was declared with the 'final' modifier. Parameters that
   * are declared with the 'const' modifier will return {@code false} even though they are
   * implicitly final.
   * @return {@code true} if this parameter was declared with the 'final' modifier
   */
  bool isFinal();

  /**
   * Set the documentation comment associated with this parameter to the given comment
   * @param comment the documentation comment to be associated with this parameter
   */
  void set documentationComment(Comment comment2) {
    this._comment = becomeParentOf(comment2);
  }

  /**
   * Set the name of the parameter being declared to the given identifier.
   * @param identifier the name of the parameter being declared
   */
  void set identifier(SimpleIdentifier identifier2) {
    this._identifier = becomeParentOf(identifier2);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    if (commentIsBeforeAnnotations()) {
      safelyVisitChild(_comment, visitor);
      _metadata.accept(visitor);
    } else {
      for (ASTNode child in sortedCommentAndAnnotations) {
        child.accept(visitor);
      }
    }
  }

  /**
   * Return {@code true} if the comment is lexically before any annotations.
   * @return {@code true} if the comment is lexically before any annotations
   */
  bool commentIsBeforeAnnotations() {
    if (_comment == null || _metadata.isEmpty) {
      return true;
    }
    Annotation firstAnnotation = _metadata[0];
    return _comment.offset < firstAnnotation.offset;
  }

  /**
   * Return an array containing the comment and annotations associated with this parameter, sorted
   * in lexical order.
   * @return the comment and annotations associated with this parameter in the order in which they
   * appeared in the original source
   */
  List<ASTNode> get sortedCommentAndAnnotations {
    List<ASTNode> childList = new List<ASTNode>();
    childList.add(_comment);
    childList.addAll(_metadata);
    List<ASTNode> children = new List.from(childList);
    children.sort(ASTNode.LEXICAL_ORDER);
    return children;
  }
}
/**
 * Instances of the class {@code NullLiteral} represent a null literal expression.
 * <pre>
 * nullLiteral ::=
 * 'null'
 * </pre>
 * @coverage dart.engine.ast
 */
class NullLiteral extends Literal {

  /**
   * The token representing the literal.
   */
  Token _literal;

  /**
   * Initialize a newly created null literal.
   * @param token the token representing the literal
   */
  NullLiteral.full(Token token) {
    this._literal = token;
  }

  /**
   * Initialize a newly created null literal.
   * @param token the token representing the literal
   */
  NullLiteral({Token token}) : this.full(token);
  accept(ASTVisitor visitor) => visitor.visitNullLiteral(this);
  Token get beginToken => _literal;
  Token get endToken => _literal;

  /**
   * Return the token representing the literal.
   * @return the token representing the literal
   */
  Token get literal => _literal;

  /**
   * Set the token representing the literal to the given token.
   * @param literal the token representing the literal
   */
  void set literal(Token literal2) {
    this._literal = literal2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
  }
}
/**
 * Instances of the class {@code ParenthesizedExpression} represent a parenthesized expression.
 * <pre>
 * parenthesizedExpression ::=
 * '(' {@link Expression expression} ')'
 * </pre>
 * @coverage dart.engine.ast
 */
class ParenthesizedExpression extends Expression {

  /**
   * The left parenthesis.
   */
  Token _leftParenthesis;

  /**
   * The expression within the parentheses.
   */
  Expression _expression;

  /**
   * The right parenthesis.
   */
  Token _rightParenthesis;

  /**
   * Initialize a newly created parenthesized expression.
   * @param leftParenthesis the left parenthesis
   * @param expression the expression within the parentheses
   * @param rightParenthesis the right parenthesis
   */
  ParenthesizedExpression.full(Token leftParenthesis, Expression expression, Token rightParenthesis) {
    this._leftParenthesis = leftParenthesis;
    this._expression = becomeParentOf(expression);
    this._rightParenthesis = rightParenthesis;
  }

  /**
   * Initialize a newly created parenthesized expression.
   * @param leftParenthesis the left parenthesis
   * @param expression the expression within the parentheses
   * @param rightParenthesis the right parenthesis
   */
  ParenthesizedExpression({Token leftParenthesis, Expression expression, Token rightParenthesis}) : this.full(leftParenthesis, expression, rightParenthesis);
  accept(ASTVisitor visitor) => visitor.visitParenthesizedExpression(this);
  Token get beginToken => _leftParenthesis;
  Token get endToken => _rightParenthesis;

  /**
   * Return the expression within the parentheses.
   * @return the expression within the parentheses
   */
  Expression get expression => _expression;

  /**
   * Return the left parenthesis.
   * @return the left parenthesis
   */
  Token get leftParenthesis => _leftParenthesis;

  /**
   * Return the right parenthesis.
   * @return the right parenthesis
   */
  Token get rightParenthesis => _rightParenthesis;

  /**
   * Set the expression within the parentheses to the given expression.
   * @param expression the expression within the parentheses
   */
  void set expression(Expression expression2) {
    this._expression = becomeParentOf(expression2);
  }

  /**
   * Set the left parenthesis to the given token.
   * @param parenthesis the left parenthesis
   */
  void set leftParenthesis(Token parenthesis) {
    _leftParenthesis = parenthesis;
  }

  /**
   * Set the right parenthesis to the given token.
   * @param parenthesis the right parenthesis
   */
  void set rightParenthesis(Token parenthesis) {
    _rightParenthesis = parenthesis;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_expression, visitor);
  }
}
/**
 * Instances of the class {@code PartDirective} represent a part directive.
 * <pre>
 * partDirective ::={@link Annotation metadata} 'part' {@link StringLiteral partUri} ';'
 * </pre>
 * @coverage dart.engine.ast
 */
class PartDirective extends UriBasedDirective {

  /**
   * The token representing the 'part' token.
   */
  Token _partToken;

  /**
   * The semicolon terminating the directive.
   */
  Token _semicolon;

  /**
   * Initialize a newly created part directive.
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   * @param partToken the token representing the 'part' token
   * @param partUri the URI of the part being included
   * @param semicolon the semicolon terminating the directive
   */
  PartDirective.full(Comment comment, List<Annotation> metadata, Token partToken, StringLiteral partUri, Token semicolon) : super.full(comment, metadata, partUri) {
    this._partToken = partToken;
    this._semicolon = semicolon;
  }

  /**
   * Initialize a newly created part directive.
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   * @param partToken the token representing the 'part' token
   * @param partUri the URI of the part being included
   * @param semicolon the semicolon terminating the directive
   */
  PartDirective({Comment comment, List<Annotation> metadata, Token partToken, StringLiteral partUri, Token semicolon}) : this.full(comment, metadata, partToken, partUri, semicolon);
  accept(ASTVisitor visitor) => visitor.visitPartDirective(this);
  Token get endToken => _semicolon;
  Token get keyword => _partToken;

  /**
   * Return the token representing the 'part' token.
   * @return the token representing the 'part' token
   */
  Token get partToken => _partToken;

  /**
   * Return the semicolon terminating the directive.
   * @return the semicolon terminating the directive
   */
  Token get semicolon => _semicolon;
  CompilationUnitElement get uriElement => element as CompilationUnitElement;

  /**
   * Set the token representing the 'part' token to the given token.
   * @param partToken the token representing the 'part' token
   */
  void set partToken(Token partToken2) {
    this._partToken = partToken2;
  }

  /**
   * Set the semicolon terminating the directive to the given token.
   * @param semicolon the semicolon terminating the directive
   */
  void set semicolon(Token semicolon2) {
    this._semicolon = semicolon2;
  }
  Token get firstTokenAfterCommentAndMetadata => _partToken;
}
/**
 * Instances of the class {@code PartOfDirective} represent a part-of directive.
 * <pre>
 * partOfDirective ::={@link Annotation metadata} 'part' 'of' {@link Identifier libraryName} ';'
 * </pre>
 * @coverage dart.engine.ast
 */
class PartOfDirective extends Directive {

  /**
   * The token representing the 'part' token.
   */
  Token _partToken;

  /**
   * The token representing the 'of' token.
   */
  Token _ofToken;

  /**
   * The name of the library that the containing compilation unit is part of.
   */
  LibraryIdentifier _libraryName;

  /**
   * The semicolon terminating the directive.
   */
  Token _semicolon;

  /**
   * Initialize a newly created part-of directive.
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   * @param partToken the token representing the 'part' token
   * @param ofToken the token representing the 'of' token
   * @param libraryName the name of the library that the containing compilation unit is part of
   * @param semicolon the semicolon terminating the directive
   */
  PartOfDirective.full(Comment comment, List<Annotation> metadata, Token partToken, Token ofToken, LibraryIdentifier libraryName, Token semicolon) : super.full(comment, metadata) {
    this._partToken = partToken;
    this._ofToken = ofToken;
    this._libraryName = becomeParentOf(libraryName);
    this._semicolon = semicolon;
  }

  /**
   * Initialize a newly created part-of directive.
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   * @param partToken the token representing the 'part' token
   * @param ofToken the token representing the 'of' token
   * @param libraryName the name of the library that the containing compilation unit is part of
   * @param semicolon the semicolon terminating the directive
   */
  PartOfDirective({Comment comment, List<Annotation> metadata, Token partToken, Token ofToken, LibraryIdentifier libraryName, Token semicolon}) : this.full(comment, metadata, partToken, ofToken, libraryName, semicolon);
  accept(ASTVisitor visitor) => visitor.visitPartOfDirective(this);
  Token get endToken => _semicolon;
  Token get keyword => _partToken;

  /**
   * Return the name of the library that the containing compilation unit is part of.
   * @return the name of the library that the containing compilation unit is part of
   */
  LibraryIdentifier get libraryName => _libraryName;

  /**
   * Return the token representing the 'of' token.
   * @return the token representing the 'of' token
   */
  Token get ofToken => _ofToken;

  /**
   * Return the token representing the 'part' token.
   * @return the token representing the 'part' token
   */
  Token get partToken => _partToken;

  /**
   * Return the semicolon terminating the directive.
   * @return the semicolon terminating the directive
   */
  Token get semicolon => _semicolon;

  /**
   * Set the name of the library that the containing compilation unit is part of to the given name.
   * @param libraryName the name of the library that the containing compilation unit is part of
   */
  void set libraryName(LibraryIdentifier libraryName2) {
    this._libraryName = becomeParentOf(libraryName2);
  }

  /**
   * Set the token representing the 'of' token to the given token.
   * @param ofToken the token representing the 'of' token
   */
  void set ofToken(Token ofToken2) {
    this._ofToken = ofToken2;
  }

  /**
   * Set the token representing the 'part' token to the given token.
   * @param partToken the token representing the 'part' token
   */
  void set partToken(Token partToken2) {
    this._partToken = partToken2;
  }

  /**
   * Set the semicolon terminating the directive to the given token.
   * @param semicolon the semicolon terminating the directive
   */
  void set semicolon(Token semicolon2) {
    this._semicolon = semicolon2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_libraryName, visitor);
  }
  Token get firstTokenAfterCommentAndMetadata => _partToken;
}
/**
 * Instances of the class {@code PostfixExpression} represent a postfix unary expression.
 * <pre>
 * postfixExpression ::={@link Expression operand} {@link Token operator}</pre>
 * @coverage dart.engine.ast
 */
class PostfixExpression extends Expression {

  /**
   * The expression computing the operand for the operator.
   */
  Expression _operand;

  /**
   * The postfix operator being applied to the operand.
   */
  Token _operator;

  /**
   * The element associated with this the operator based on the propagated type of the operand, or{@code null} if the AST structure has not been resolved, if the operator is not user definable,
   * or if the operator could not be resolved.
   */
  MethodElement _propagatedElement;

  /**
   * The element associated with the operator based on the static type of the operand, or{@code null} if the AST structure has not been resolved, if the operator is not user definable,
   * or if the operator could not be resolved.
   */
  MethodElement _staticElement;

  /**
   * Initialize a newly created postfix expression.
   * @param operand the expression computing the operand for the operator
   * @param operator the postfix operator being applied to the operand
   */
  PostfixExpression.full(Expression operand, Token operator) {
    this._operand = becomeParentOf(operand);
    this._operator = operator;
  }

  /**
   * Initialize a newly created postfix expression.
   * @param operand the expression computing the operand for the operator
   * @param operator the postfix operator being applied to the operand
   */
  PostfixExpression({Expression operand, Token operator}) : this.full(operand, operator);
  accept(ASTVisitor visitor) => visitor.visitPostfixExpression(this);
  Token get beginToken => _operand.beginToken;

  /**
   * Return the element associated with the operator based on the propagated type of the operand, or{@code null} if the AST structure has not been resolved, if the operator is not user definable,
   * or if the operator could not be resolved. One example of the latter case is an operator that is
   * not defined for the type of the operand.
   * @return the element associated with the operator
   */
  MethodElement get element => _propagatedElement;
  Token get endToken => _operator;

  /**
   * Return the expression computing the operand for the operator.
   * @return the expression computing the operand for the operator
   */
  Expression get operand => _operand;

  /**
   * Return the postfix operator being applied to the operand.
   * @return the postfix operator being applied to the operand
   */
  Token get operator => _operator;

  /**
   * Return the element associated with the operator based on the static type of the operand, or{@code null} if the AST structure has not been resolved, if the operator is not user definable,
   * or if the operator could not be resolved. One example of the latter case is an operator that is
   * not defined for the type of the operand.
   * @return the element associated with the operator
   */
  MethodElement get staticElement => _staticElement;

  /**
   * Set the element associated with the operator based on the propagated type of the operand to the
   * given element.
   * @param element the element to be associated with the operator
   */
  void set element(MethodElement element2) {
    _propagatedElement = element2;
  }

  /**
   * Set the expression computing the operand for the operator to the given expression.
   * @param expression the expression computing the operand for the operator
   */
  void set operand(Expression expression) {
    _operand = becomeParentOf(expression);
  }

  /**
   * Set the postfix operator being applied to the operand to the given operator.
   * @param operator the postfix operator being applied to the operand
   */
  void set operator(Token operator2) {
    this._operator = operator2;
  }

  /**
   * Set the element associated with the operator based on the static type of the operand to the
   * given element.
   * @param element the element to be associated with the operator
   */
  void set staticElement(MethodElement element) {
    _staticElement = element;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_operand, visitor);
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is known based on
   * propagated type information, then return the parameter element representing the parameter to
   * which the value of the operand will be bound. Otherwise, return {@code null}.
   * <p>
   * This method is only intended to be used by {@link Expression#getParameterElement()}.
   * @return the parameter element representing the parameter to which the value of the right
   * operand will be bound
   */
  ParameterElement get propagatedParameterElementForOperand {
    if (_propagatedElement == null) {
      return null;
    }
    List<ParameterElement> parameters = _propagatedElement.parameters;
    if (parameters.length < 1) {
      return null;
    }
    return parameters[0];
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is known based on static
   * type information, then return the parameter element representing the parameter to which the
   * value of the operand will be bound. Otherwise, return {@code null}.
   * <p>
   * This method is only intended to be used by {@link Expression#getStaticParameterElement()}.
   * @return the parameter element representing the parameter to which the value of the right
   * operand will be bound
   */
  ParameterElement get staticParameterElementForOperand {
    if (_staticElement == null) {
      return null;
    }
    List<ParameterElement> parameters = _staticElement.parameters;
    if (parameters.length < 1) {
      return null;
    }
    return parameters[0];
  }
}
/**
 * Instances of the class {@code PrefixExpression} represent a prefix unary expression.
 * <pre>
 * prefixExpression ::={@link Token operator} {@link Expression operand}</pre>
 * @coverage dart.engine.ast
 */
class PrefixExpression extends Expression {

  /**
   * The prefix operator being applied to the operand.
   */
  Token _operator;

  /**
   * The expression computing the operand for the operator.
   */
  Expression _operand;

  /**
   * The element associated with the operator based on the static type of the operand, or{@code null} if the AST structure has not been resolved, if the operator is not user definable,
   * or if the operator could not be resolved.
   */
  MethodElement _staticElement;

  /**
   * The element associated with the operator based on the propagated type of the operand, or{@code null} if the AST structure has not been resolved, if the operator is not user definable,
   * or if the operator could not be resolved.
   */
  MethodElement _propagatedElement;

  /**
   * Initialize a newly created prefix expression.
   * @param operator the prefix operator being applied to the operand
   * @param operand the expression computing the operand for the operator
   */
  PrefixExpression.full(Token operator, Expression operand) {
    this._operator = operator;
    this._operand = becomeParentOf(operand);
  }

  /**
   * Initialize a newly created prefix expression.
   * @param operator the prefix operator being applied to the operand
   * @param operand the expression computing the operand for the operator
   */
  PrefixExpression({Token operator, Expression operand}) : this.full(operator, operand);
  accept(ASTVisitor visitor) => visitor.visitPrefixExpression(this);
  Token get beginToken => _operator;

  /**
   * Return the element associated with the operator based on the propagated type of the operand, or{@code null} if the AST structure has not been resolved, if the operator is not user definable,
   * or if the operator could not be resolved. One example of the latter case is an operator that is
   * not defined for the type of the operand.
   * @return the element associated with the operator
   */
  MethodElement get element => _propagatedElement;
  Token get endToken => _operand.endToken;

  /**
   * Return the expression computing the operand for the operator.
   * @return the expression computing the operand for the operator
   */
  Expression get operand => _operand;

  /**
   * Return the prefix operator being applied to the operand.
   * @return the prefix operator being applied to the operand
   */
  Token get operator => _operator;

  /**
   * Return the element associated with the operator based on the static type of the operand, or{@code null} if the AST structure has not been resolved, if the operator is not user definable,
   * or if the operator could not be resolved. One example of the latter case is an operator that is
   * not defined for the type of the operand.
   * @return the element associated with the operator
   */
  MethodElement get staticElement => _staticElement;

  /**
   * Set the element associated with the operator based on the propagated type of the operand to the
   * given element.
   * @param element the element to be associated with the operator
   */
  void set element(MethodElement element2) {
    _propagatedElement = element2;
  }

  /**
   * Set the expression computing the operand for the operator to the given expression.
   * @param expression the expression computing the operand for the operator
   */
  void set operand(Expression expression) {
    _operand = becomeParentOf(expression);
  }

  /**
   * Set the prefix operator being applied to the operand to the given operator.
   * @param operator the prefix operator being applied to the operand
   */
  void set operator(Token operator2) {
    this._operator = operator2;
  }

  /**
   * Set the element associated with the operator based on the static type of the operand to the
   * given element.
   * @param element the static element to be associated with the operator
   */
  void set staticElement(MethodElement element) {
    _staticElement = element;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_operand, visitor);
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is known based on
   * propagated type information, then return the parameter element representing the parameter to
   * which the value of the operand will be bound. Otherwise, return {@code null}.
   * <p>
   * This method is only intended to be used by {@link Expression#getParameterElement()}.
   * @return the parameter element representing the parameter to which the value of the right
   * operand will be bound
   */
  ParameterElement get propagatedParameterElementForOperand {
    if (_propagatedElement == null) {
      return null;
    }
    List<ParameterElement> parameters = _propagatedElement.parameters;
    if (parameters.length < 1) {
      return null;
    }
    return parameters[0];
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is known based on static
   * type information, then return the parameter element representing the parameter to which the
   * value of the operand will be bound. Otherwise, return {@code null}.
   * <p>
   * This method is only intended to be used by {@link Expression#getStaticParameterElement()}.
   * @return the parameter element representing the parameter to which the value of the right
   * operand will be bound
   */
  ParameterElement get staticParameterElementForOperand {
    if (_staticElement == null) {
      return null;
    }
    List<ParameterElement> parameters = _staticElement.parameters;
    if (parameters.length < 1) {
      return null;
    }
    return parameters[0];
  }
}
/**
 * Instances of the class {@code PrefixedIdentifier} represent either an identifier that is prefixed
 * or an access to an object property where the target of the property access is a simple
 * identifier.
 * <pre>
 * prefixedIdentifier ::={@link SimpleIdentifier prefix} '.' {@link SimpleIdentifier identifier}</pre>
 * @coverage dart.engine.ast
 */
class PrefixedIdentifier extends Identifier {

  /**
   * The prefix associated with the library in which the identifier is defined.
   */
  SimpleIdentifier _prefix;

  /**
   * The period used to separate the prefix from the identifier.
   */
  Token _period;

  /**
   * The identifier being prefixed.
   */
  SimpleIdentifier _identifier;

  /**
   * Initialize a newly created prefixed identifier.
   * @param prefix the identifier being prefixed
   * @param period the period used to separate the prefix from the identifier
   * @param identifier the prefix associated with the library in which the identifier is defined
   */
  PrefixedIdentifier.full(SimpleIdentifier prefix, Token period, SimpleIdentifier identifier) {
    this._prefix = becomeParentOf(prefix);
    this._period = period;
    this._identifier = becomeParentOf(identifier);
  }

  /**
   * Initialize a newly created prefixed identifier.
   * @param prefix the identifier being prefixed
   * @param period the period used to separate the prefix from the identifier
   * @param identifier the prefix associated with the library in which the identifier is defined
   */
  PrefixedIdentifier({SimpleIdentifier prefix, Token period, SimpleIdentifier identifier}) : this.full(prefix, period, identifier);
  accept(ASTVisitor visitor) => visitor.visitPrefixedIdentifier(this);
  Token get beginToken => _prefix.beginToken;
  Element get element {
    if (_identifier == null) {
      return null;
    }
    return _identifier.element;
  }
  Token get endToken => _identifier.endToken;

  /**
   * Return the identifier being prefixed.
   * @return the identifier being prefixed
   */
  SimpleIdentifier get identifier => _identifier;
  String get name => "${_prefix.name}.${_identifier.name}";

  /**
   * Return the period used to separate the prefix from the identifier.
   * @return the period used to separate the prefix from the identifier
   */
  Token get period => _period;

  /**
   * Return the prefix associated with the library in which the identifier is defined.
   * @return the prefix associated with the library in which the identifier is defined
   */
  SimpleIdentifier get prefix => _prefix;
  Element get staticElement {
    if (_identifier == null) {
      return null;
    }
    return _identifier.staticElement;
  }

  /**
   * Set the identifier being prefixed to the given identifier.
   * @param identifier the identifier being prefixed
   */
  void set identifier(SimpleIdentifier identifier2) {
    this._identifier = becomeParentOf(identifier2);
  }

  /**
   * Set the period used to separate the prefix from the identifier to the given token.
   * @param period the period used to separate the prefix from the identifier
   */
  void set period(Token period2) {
    this._period = period2;
  }

  /**
   * Set the prefix associated with the library in which the identifier is defined to the given
   * identifier.
   * @param identifier the prefix associated with the library in which the identifier is defined
   */
  void set prefix(SimpleIdentifier identifier) {
    _prefix = becomeParentOf(identifier);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_prefix, visitor);
    safelyVisitChild(_identifier, visitor);
  }
}
/**
 * Instances of the class {@code PropertyAccess} represent the access of a property of an object.
 * <p>
 * Note, however, that accesses to properties of objects can also be represented as{@link PrefixedIdentifier prefixed identifier} nodes in cases where the target is also a simple
 * identifier.
 * <pre>
 * propertyAccess ::={@link Expression target} '.' {@link SimpleIdentifier propertyName}</pre>
 * @coverage dart.engine.ast
 */
class PropertyAccess extends Expression {

  /**
   * The expression computing the object defining the property being accessed.
   */
  Expression _target;

  /**
   * The property access operator.
   */
  Token _operator;

  /**
   * The name of the property being accessed.
   */
  SimpleIdentifier _propertyName;

  /**
   * Initialize a newly created property access expression.
   * @param target the expression computing the object defining the property being accessed
   * @param operator the property access operator
   * @param propertyName the name of the property being accessed
   */
  PropertyAccess.full(Expression target, Token operator, SimpleIdentifier propertyName) {
    this._target = becomeParentOf(target);
    this._operator = operator;
    this._propertyName = becomeParentOf(propertyName);
  }

  /**
   * Initialize a newly created property access expression.
   * @param target the expression computing the object defining the property being accessed
   * @param operator the property access operator
   * @param propertyName the name of the property being accessed
   */
  PropertyAccess({Expression target, Token operator, SimpleIdentifier propertyName}) : this.full(target, operator, propertyName);
  accept(ASTVisitor visitor) => visitor.visitPropertyAccess(this);
  Token get beginToken {
    if (_target != null) {
      return _target.beginToken;
    }
    return _operator;
  }
  Token get endToken => _propertyName.endToken;

  /**
   * Return the property access operator.
   * @return the property access operator
   */
  Token get operator => _operator;

  /**
   * Return the name of the property being accessed.
   * @return the name of the property being accessed
   */
  SimpleIdentifier get propertyName => _propertyName;

  /**
   * Return the expression used to compute the receiver of the invocation. If this invocation is not
   * part of a cascade expression, then this is the same as {@link #getTarget()}. If this invocation
   * is part of a cascade expression, then the target stored with the cascade expression is
   * returned.
   * @return the expression used to compute the receiver of the invocation
   * @see #getTarget()
   */
  Expression get realTarget {
    if (isCascaded()) {
      ASTNode ancestor = parent;
      while (ancestor is! CascadeExpression) {
        if (ancestor == null) {
          return _target;
        }
        ancestor = ancestor.parent;
      }
      return ((ancestor as CascadeExpression)).target;
    }
    return _target;
  }

  /**
   * Return the expression computing the object defining the property being accessed, or{@code null} if this property access is part of a cascade expression.
   * @return the expression computing the object defining the property being accessed
   * @see #getRealTarget()
   */
  Expression get target => _target;
  bool isAssignable() => true;

  /**
   * Return {@code true} if this expression is cascaded. If it is, then the target of this
   * expression is not stored locally but is stored in the nearest ancestor that is a{@link CascadeExpression}.
   * @return {@code true} if this expression is cascaded
   */
  bool isCascaded() => _operator != null && identical(_operator.type, TokenType.PERIOD_PERIOD);

  /**
   * Set the property access operator to the given token.
   * @param operator the property access operator
   */
  void set operator(Token operator2) {
    this._operator = operator2;
  }

  /**
   * Set the name of the property being accessed to the given identifier.
   * @param identifier the name of the property being accessed
   */
  void set propertyName(SimpleIdentifier identifier) {
    _propertyName = becomeParentOf(identifier);
  }

  /**
   * Set the expression computing the object defining the property being accessed to the given
   * expression.
   * @param expression the expression computing the object defining the property being accessed
   */
  void set target(Expression expression) {
    _target = becomeParentOf(expression);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_target, visitor);
    safelyVisitChild(_propertyName, visitor);
  }
}
/**
 * Instances of the class {@code RedirectingConstructorInvocation} represent the invocation of a
 * another constructor in the same class from within a constructor's initialization list.
 * <pre>
 * redirectingConstructorInvocation ::=
 * 'this' ('.' identifier)? arguments
 * </pre>
 * @coverage dart.engine.ast
 */
class RedirectingConstructorInvocation extends ConstructorInitializer {

  /**
   * The token for the 'this' keyword.
   */
  Token _keyword;

  /**
   * The token for the period before the name of the constructor that is being invoked, or{@code null} if the unnamed constructor is being invoked.
   */
  Token _period;

  /**
   * The name of the constructor that is being invoked, or {@code null} if the unnamed constructor
   * is being invoked.
   */
  SimpleIdentifier _constructorName;

  /**
   * The list of arguments to the constructor.
   */
  ArgumentList _argumentList;

  /**
   * The element associated with the constructor based on static type information, or {@code null}if the AST structure has not been resolved or if the constructor could not be resolved.
   */
  ConstructorElement _staticElement;

  /**
   * The element associated with the constructor based on propagated type information, or{@code null} if the AST structure has not been resolved or if the constructor could not be
   * resolved.
   */
  ConstructorElement _propagatedElement;

  /**
   * Initialize a newly created redirecting invocation to invoke the constructor with the given name
   * with the given arguments.
   * @param keyword the token for the 'this' keyword
   * @param period the token for the period before the name of the constructor that is being invoked
   * @param constructorName the name of the constructor that is being invoked
   * @param argumentList the list of arguments to the constructor
   */
  RedirectingConstructorInvocation.full(Token keyword, Token period, SimpleIdentifier constructorName, ArgumentList argumentList) {
    this._keyword = keyword;
    this._period = period;
    this._constructorName = becomeParentOf(constructorName);
    this._argumentList = becomeParentOf(argumentList);
  }

  /**
   * Initialize a newly created redirecting invocation to invoke the constructor with the given name
   * with the given arguments.
   * @param keyword the token for the 'this' keyword
   * @param period the token for the period before the name of the constructor that is being invoked
   * @param constructorName the name of the constructor that is being invoked
   * @param argumentList the list of arguments to the constructor
   */
  RedirectingConstructorInvocation({Token keyword, Token period, SimpleIdentifier constructorName, ArgumentList argumentList}) : this.full(keyword, period, constructorName, argumentList);
  accept(ASTVisitor visitor) => visitor.visitRedirectingConstructorInvocation(this);

  /**
   * Return the list of arguments to the constructor.
   * @return the list of arguments to the constructor
   */
  ArgumentList get argumentList => _argumentList;
  Token get beginToken => _keyword;

  /**
   * Return the name of the constructor that is being invoked, or {@code null} if the unnamed
   * constructor is being invoked.
   * @return the name of the constructor that is being invoked
   */
  SimpleIdentifier get constructorName => _constructorName;

  /**
   * Return the element associated with the constructor based on propagated type information, or{@code null} if the AST structure has not been resolved or if the constructor could not be
   * resolved.
   * @return the element associated with the super constructor
   */
  ConstructorElement get element => _propagatedElement;
  Token get endToken => _argumentList.endToken;

  /**
   * Return the token for the 'this' keyword.
   * @return the token for the 'this' keyword
   */
  Token get keyword => _keyword;

  /**
   * Return the token for the period before the name of the constructor that is being invoked, or{@code null} if the unnamed constructor is being invoked.
   * @return the token for the period before the name of the constructor that is being invoked
   */
  Token get period => _period;

  /**
   * Return the element associated with the constructor based on static type information, or{@code null} if the AST structure has not been resolved or if the constructor could not be
   * resolved.
   * @return the element associated with the constructor
   */
  ConstructorElement get staticElement => _staticElement;

  /**
   * Set the list of arguments to the constructor to the given list.
   * @param argumentList the list of arguments to the constructor
   */
  void set argumentList(ArgumentList argumentList2) {
    this._argumentList = becomeParentOf(argumentList2);
  }

  /**
   * Set the name of the constructor that is being invoked to the given identifier.
   * @param identifier the name of the constructor that is being invoked
   */
  void set constructorName(SimpleIdentifier identifier) {
    _constructorName = becomeParentOf(identifier);
  }

  /**
   * Set the element associated with the constructor based on propagated type information to the
   * given element.
   * @param element the element to be associated with the constructor
   */
  void set element(ConstructorElement element2) {
    _propagatedElement = element2;
  }

  /**
   * Set the token for the 'this' keyword to the given token.
   * @param keyword the token for the 'this' keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }

  /**
   * Set the token for the period before the name of the constructor that is being invoked to the
   * given token.
   * @param period the token for the period before the name of the constructor that is being invoked
   */
  void set period(Token period2) {
    this._period = period2;
  }

  /**
   * Set the element associated with the constructor based on static type information to the given
   * element.
   * @param element the element to be associated with the constructor
   */
  void set staticElement(ConstructorElement element) {
    this._staticElement = element;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_constructorName, visitor);
    safelyVisitChild(_argumentList, visitor);
  }
}
/**
 * Instances of the class {@code RethrowExpression} represent a rethrow expression.
 * <pre>
 * rethrowExpression ::=
 * 'rethrow'
 * </pre>
 * @coverage dart.engine.ast
 */
class RethrowExpression extends Expression {

  /**
   * The token representing the 'rethrow' keyword.
   */
  Token _keyword;

  /**
   * Initialize a newly created rethrow expression.
   * @param keyword the token representing the 'rethrow' keyword
   */
  RethrowExpression.full(Token keyword) {
    this._keyword = keyword;
  }

  /**
   * Initialize a newly created rethrow expression.
   * @param keyword the token representing the 'rethrow' keyword
   */
  RethrowExpression({Token keyword}) : this.full(keyword);
  accept(ASTVisitor visitor) => visitor.visitRethrowExpression(this);
  Token get beginToken => _keyword;
  Token get endToken => _keyword;

  /**
   * Return the token representing the 'rethrow' keyword.
   * @return the token representing the 'rethrow' keyword
   */
  Token get keyword => _keyword;

  /**
   * Set the token representing the 'rethrow' keyword to the given token.
   * @param keyword the token representing the 'rethrow' keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
  }
}
/**
 * Instances of the class {@code ReturnStatement} represent a return statement.
 * <pre>
 * returnStatement ::=
 * 'return' {@link Expression expression}? ';'
 * </pre>
 * @coverage dart.engine.ast
 */
class ReturnStatement extends Statement {

  /**
   * The token representing the 'return' keyword.
   */
  Token _keyword;

  /**
   * The expression computing the value to be returned, or {@code null} if no explicit value was
   * provided.
   */
  Expression _expression;

  /**
   * The semicolon terminating the statement.
   */
  Token _semicolon;

  /**
   * Initialize a newly created return statement.
   * @param keyword the token representing the 'return' keyword
   * @param expression the expression computing the value to be returned
   * @param semicolon the semicolon terminating the statement
   */
  ReturnStatement.full(Token keyword, Expression expression, Token semicolon) {
    this._keyword = keyword;
    this._expression = becomeParentOf(expression);
    this._semicolon = semicolon;
  }

  /**
   * Initialize a newly created return statement.
   * @param keyword the token representing the 'return' keyword
   * @param expression the expression computing the value to be returned
   * @param semicolon the semicolon terminating the statement
   */
  ReturnStatement({Token keyword, Expression expression, Token semicolon}) : this.full(keyword, expression, semicolon);
  accept(ASTVisitor visitor) => visitor.visitReturnStatement(this);
  Token get beginToken => _keyword;
  Token get endToken => _semicolon;

  /**
   * Return the expression computing the value to be returned, or {@code null} if no explicit value
   * was provided.
   * @return the expression computing the value to be returned
   */
  Expression get expression => _expression;

  /**
   * Return the token representing the 'return' keyword.
   * @return the token representing the 'return' keyword
   */
  Token get keyword => _keyword;

  /**
   * Return the semicolon terminating the statement.
   * @return the semicolon terminating the statement
   */
  Token get semicolon => _semicolon;

  /**
   * Set the expression computing the value to be returned to the given expression.
   * @param expression the expression computing the value to be returned
   */
  void set expression(Expression expression2) {
    this._expression = becomeParentOf(expression2);
  }

  /**
   * Set the token representing the 'return' keyword to the given token.
   * @param keyword the token representing the 'return' keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }

  /**
   * Set the semicolon terminating the statement to the given token.
   * @param semicolon the semicolon terminating the statement
   */
  void set semicolon(Token semicolon2) {
    this._semicolon = semicolon2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_expression, visitor);
  }
}
/**
 * Instances of the class {@code ScriptTag} represent the script tag that can optionally occur at
 * the beginning of a compilation unit.
 * <pre>
 * scriptTag ::=
 * '#!' (~NEWLINE)* NEWLINE
 * </pre>
 * @coverage dart.engine.ast
 */
class ScriptTag extends ASTNode {

  /**
   * The token representing this script tag.
   */
  Token _scriptTag;

  /**
   * Initialize a newly created script tag.
   * @param scriptTag the token representing this script tag
   */
  ScriptTag.full(Token scriptTag) {
    this._scriptTag = scriptTag;
  }

  /**
   * Initialize a newly created script tag.
   * @param scriptTag the token representing this script tag
   */
  ScriptTag({Token scriptTag}) : this.full(scriptTag);
  accept(ASTVisitor visitor) => visitor.visitScriptTag(this);
  Token get beginToken => _scriptTag;
  Token get endToken => _scriptTag;

  /**
   * Return the token representing this script tag.
   * @return the token representing this script tag
   */
  Token get scriptTag => _scriptTag;

  /**
   * Set the token representing this script tag to the given script tag.
   * @param scriptTag the token representing this script tag
   */
  void set scriptTag(Token scriptTag2) {
    this._scriptTag = scriptTag2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
  }
}
/**
 * Instances of the class {@code ShowCombinator} represent a combinator that restricts the names
 * being imported to those in a given list.
 * <pre>
 * showCombinator ::=
 * 'show' {@link SimpleIdentifier identifier} (',' {@link SimpleIdentifier identifier})
 * </pre>
 * @coverage dart.engine.ast
 */
class ShowCombinator extends Combinator {

  /**
   * The list of names from the library that are made visible by this combinator.
   */
  NodeList<SimpleIdentifier> _shownNames;

  /**
   * Initialize a newly created import show combinator.
   * @param keyword the comma introducing the combinator
   * @param shownNames the list of names from the library that are made visible by this combinator
   */
  ShowCombinator.full(Token keyword, List<SimpleIdentifier> shownNames) : super.full(keyword) {
    this._shownNames = new NodeList<SimpleIdentifier>(this);
    this._shownNames.addAll(shownNames);
  }

  /**
   * Initialize a newly created import show combinator.
   * @param keyword the comma introducing the combinator
   * @param shownNames the list of names from the library that are made visible by this combinator
   */
  ShowCombinator({Token keyword, List<SimpleIdentifier> shownNames}) : this.full(keyword, shownNames);
  accept(ASTVisitor visitor) => visitor.visitShowCombinator(this);
  Token get endToken => _shownNames.endToken;

  /**
   * Return the list of names from the library that are made visible by this combinator.
   * @return the list of names from the library that are made visible by this combinator
   */
  NodeList<SimpleIdentifier> get shownNames => _shownNames;
  void visitChildren(ASTVisitor<Object> visitor) {
    _shownNames.accept(visitor);
  }
}
/**
 * Instances of the class {@code SimpleFormalParameter} represent a simple formal parameter.
 * <pre>
 * simpleFormalParameter ::=
 * ('final' {@link TypeName type} | 'var' | {@link TypeName type})? {@link SimpleIdentifier identifier}</pre>
 * @coverage dart.engine.ast
 */
class SimpleFormalParameter extends NormalFormalParameter {

  /**
   * The token representing either the 'final', 'const' or 'var' keyword, or {@code null} if no
   * keyword was used.
   */
  Token _keyword;

  /**
   * The name of the declared type of the parameter, or {@code null} if the parameter does not have
   * a declared type.
   */
  TypeName _type;

  /**
   * Initialize a newly created formal parameter.
   * @param comment the documentation comment associated with this parameter
   * @param metadata the annotations associated with this parameter
   * @param keyword the token representing either the 'final', 'const' or 'var' keyword
   * @param type the name of the declared type of the parameter
   * @param identifier the name of the parameter being declared
   */
  SimpleFormalParameter.full(Comment comment, List<Annotation> metadata, Token keyword, TypeName type, SimpleIdentifier identifier) : super.full(comment, metadata, identifier) {
    this._keyword = keyword;
    this._type = becomeParentOf(type);
  }

  /**
   * Initialize a newly created formal parameter.
   * @param comment the documentation comment associated with this parameter
   * @param metadata the annotations associated with this parameter
   * @param keyword the token representing either the 'final', 'const' or 'var' keyword
   * @param type the name of the declared type of the parameter
   * @param identifier the name of the parameter being declared
   */
  SimpleFormalParameter({Comment comment, List<Annotation> metadata, Token keyword, TypeName type, SimpleIdentifier identifier}) : this.full(comment, metadata, keyword, type, identifier);
  accept(ASTVisitor visitor) => visitor.visitSimpleFormalParameter(this);
  Token get beginToken {
    if (_keyword != null) {
      return _keyword;
    } else if (_type != null) {
      return _type.beginToken;
    }
    return identifier.beginToken;
  }
  Token get endToken => identifier.endToken;

  /**
   * Return the token representing either the 'final', 'const' or 'var' keyword.
   * @return the token representing either the 'final', 'const' or 'var' keyword
   */
  Token get keyword => _keyword;

  /**
   * Return the name of the declared type of the parameter, or {@code null} if the parameter does
   * not have a declared type.
   * @return the name of the declared type of the parameter
   */
  TypeName get type => _type;
  bool isConst() => (_keyword is KeywordToken) && identical(((_keyword as KeywordToken)).keyword, Keyword.CONST);
  bool isFinal() => (_keyword is KeywordToken) && identical(((_keyword as KeywordToken)).keyword, Keyword.FINAL);

  /**
   * Set the token representing either the 'final', 'const' or 'var' keyword to the given token.
   * @param keyword the token representing either the 'final', 'const' or 'var' keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }

  /**
   * Set the name of the declared type of the parameter to the given type name.
   * @param typeName the name of the declared type of the parameter
   */
  void set type(TypeName typeName) {
    _type = becomeParentOf(typeName);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_type, visitor);
    safelyVisitChild(identifier, visitor);
  }
}
/**
 * Instances of the class {@code SimpleIdentifier} represent a simple identifier.
 * <pre>
 * simpleIdentifier ::=
 * initialCharacter internalCharacter
 * initialCharacter ::= '_' | '$' | letter
 * internalCharacter ::= '_' | '$' | letter | digit
 * </pre>
 * @coverage dart.engine.ast
 */
class SimpleIdentifier extends Identifier {

  /**
   * The token representing the identifier.
   */
  Token _token;

  /**
   * The element associated with this identifier based on static type information, or {@code null}if the AST structure has not been resolved or if this identifier could not be resolved.
   */
  Element _staticElement;

  /**
   * The element associated with this identifier based on propagated type information, or{@code null} if the AST structure has not been resolved or if this identifier could not be
   * resolved.
   */
  Element _propagatedElement;

  /**
   * Initialize a newly created identifier.
   * @param token the token representing the identifier
   */
  SimpleIdentifier.full(Token token) {
    this._token = token;
  }

  /**
   * Initialize a newly created identifier.
   * @param token the token representing the identifier
   */
  SimpleIdentifier({Token token}) : this.full(token);
  accept(ASTVisitor visitor) => visitor.visitSimpleIdentifier(this);
  Token get beginToken => _token;
  Element get element => _propagatedElement;
  Token get endToken => _token;
  String get name => _token.lexeme;
  Element get staticElement => _staticElement;

  /**
   * Return the token representing the identifier.
   * @return the token representing the identifier
   */
  Token get token => _token;

  /**
   * Return {@code true} if this identifier is the name being declared in a declaration.
   * @return {@code true} if this identifier is the name being declared in a declaration
   */
  bool inDeclarationContext() {
    ASTNode parent = this.parent;
    if (parent is CatchClause) {
      CatchClause clause = parent as CatchClause;
      return identical(this, clause.exceptionParameter) || identical(this, clause.stackTraceParameter);
    } else if (parent is ClassDeclaration) {
      return identical(this, ((parent as ClassDeclaration)).name);
    } else if (parent is ClassTypeAlias) {
      return identical(this, ((parent as ClassTypeAlias)).name);
    } else if (parent is ConstructorDeclaration) {
      return identical(this, ((parent as ConstructorDeclaration)).name);
    } else if (parent is FunctionDeclaration) {
      return identical(this, ((parent as FunctionDeclaration)).name);
    } else if (parent is FunctionTypeAlias) {
      return identical(this, ((parent as FunctionTypeAlias)).name);
    } else if (parent is Label) {
      return identical(this, ((parent as Label)).label) && (parent.parent is LabeledStatement);
    } else if (parent is MethodDeclaration) {
      return identical(this, ((parent as MethodDeclaration)).name);
    } else if (parent is FunctionTypedFormalParameter || parent is SimpleFormalParameter) {
      return identical(this, ((parent as NormalFormalParameter)).identifier);
    } else if (parent is TypeParameter) {
      return identical(this, ((parent as TypeParameter)).name);
    } else if (parent is VariableDeclaration) {
      return identical(this, ((parent as VariableDeclaration)).name);
    }
    return false;
  }

  /**
   * Return {@code true} if this expression is computing a right-hand value.
   * <p>
   * Note that {@link #inGetterContext()} and {@link #inSetterContext()} are not opposites, nor are
   * they mutually exclusive. In other words, it is possible for both methods to return {@code true}when invoked on the same node.
   * @return {@code true} if this expression is in a context where a getter will be invoked
   */
  bool inGetterContext() {
    ASTNode parent = this.parent;
    ASTNode target = this;
    if (parent is PrefixedIdentifier) {
      PrefixedIdentifier prefixed = parent as PrefixedIdentifier;
      if (identical(prefixed.prefix, this)) {
        return true;
      }
      parent = prefixed.parent;
      target = prefixed;
    } else if (parent is PropertyAccess) {
      PropertyAccess access = parent as PropertyAccess;
      if (identical(access.target, this)) {
        return true;
      }
      parent = access.parent;
      target = access;
    }
    if (parent is Label) {
      return false;
    }
    if (parent is AssignmentExpression) {
      AssignmentExpression expr = parent as AssignmentExpression;
      if (identical(expr.leftHandSide, target) && identical(expr.operator.type, TokenType.EQ)) {
        return false;
      }
    }
    return true;
  }

  /**
   * Return {@code true} if this expression is computing a left-hand value.
   * <p>
   * Note that {@link #inGetterContext()} and {@link #inSetterContext()} are not opposites, nor are
   * they mutually exclusive. In other words, it is possible for both methods to return {@code true}when invoked on the same node.
   * @return {@code true} if this expression is in a context where a setter will be invoked
   */
  bool inSetterContext() {
    ASTNode parent = this.parent;
    ASTNode target = this;
    if (parent is PrefixedIdentifier) {
      PrefixedIdentifier prefixed = parent as PrefixedIdentifier;
      if (identical(prefixed.prefix, this)) {
        return false;
      }
      parent = prefixed.parent;
      target = prefixed;
    } else if (parent is PropertyAccess) {
      PropertyAccess access = parent as PropertyAccess;
      if (identical(access.target, this)) {
        return false;
      }
      parent = access.parent;
      target = access;
    }
    if (parent is PrefixExpression) {
      return ((parent as PrefixExpression)).operator.type.isIncrementOperator();
    } else if (parent is PostfixExpression) {
      return true;
    } else if (parent is AssignmentExpression) {
      return identical(((parent as AssignmentExpression)).leftHandSide, target);
    }
    return false;
  }
  bool isSynthetic() => _token.isSynthetic();

  /**
   * Set the element associated with this identifier based on propagated type information to the
   * given element.
   * @param element the element to be associated with this identifier
   */
  void set element(Element element2) {
    _propagatedElement = element2;
  }

  /**
   * Set the element associated with this identifier based on static type information to the given
   * element.
   * @param element the element to be associated with this identifier
   */
  void set staticElement(Element element) {
    _staticElement = element;
  }

  /**
   * Set the token representing the identifier to the given token.
   * @param token the token representing the literal
   */
  void set token(Token token2) {
    this._token = token2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
  }
}
/**
 * Instances of the class {@code SimpleStringLiteral} represent a string literal expression that
 * does not contain any interpolations.
 * <pre>
 * simpleStringLiteral ::=
 * rawStringLiteral
 * | basicStringLiteral
 * rawStringLiteral ::=
 * '@' basicStringLiteral
 * simpleStringLiteral ::=
 * multiLineStringLiteral
 * | singleLineStringLiteral
 * multiLineStringLiteral ::=
 * "'''" characters "'''"
 * | '"""' characters '"""'
 * singleLineStringLiteral ::=
 * "'" characters "'"
 * '"' characters '"'
 * </pre>
 * @coverage dart.engine.ast
 */
class SimpleStringLiteral extends StringLiteral {

  /**
   * The token representing the literal.
   */
  Token _literal;

  /**
   * The value of the literal.
   */
  String _value;

  /**
   * Initialize a newly created simple string literal.
   * @param literal the token representing the literal
   * @param value the value of the literal
   */
  SimpleStringLiteral.full(Token literal, String value) {
    this._literal = literal;
    this._value = StringUtilities.intern(value);
  }

  /**
   * Initialize a newly created simple string literal.
   * @param literal the token representing the literal
   * @param value the value of the literal
   */
  SimpleStringLiteral({Token literal, String value}) : this.full(literal, value);
  accept(ASTVisitor visitor) => visitor.visitSimpleStringLiteral(this);
  Token get beginToken => _literal;
  Token get endToken => _literal;

  /**
   * Return the token representing the literal.
   * @return the token representing the literal
   */
  Token get literal => _literal;

  /**
   * Return the value of the literal.
   * @return the value of the literal
   */
  String get value => _value;

  /**
   * Return {@code true} if this string literal is a multi-line string.
   * @return {@code true} if this string literal is a multi-line string
   */
  bool isMultiline() {
    if (_value.length < 6) {
      return false;
    }
    return _value.endsWith("\"\"\"") || _value.endsWith("'''");
  }

  /**
   * Return {@code true} if this string literal is a raw string.
   * @return {@code true} if this string literal is a raw string
   */
  bool isRaw() => _value.codeUnitAt(0) == 0x40;
  bool isSynthetic() => _literal.isSynthetic();

  /**
   * Set the token representing the literal to the given token.
   * @param literal the token representing the literal
   */
  void set literal(Token literal2) {
    this._literal = literal2;
  }

  /**
   * Set the value of the literal to the given string.
   * @param string the value of the literal
   */
  void set value(String string) {
    _value = StringUtilities.intern(_value);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
  }
  void appendStringValue(JavaStringBuilder builder) {
    builder.append(value);
  }
}
/**
 * Instances of the class {@code Statement} defines the behavior common to nodes that represent a
 * statement.
 * <pre>
 * statement ::={@link Block block}| {@link VariableDeclarationStatement initializedVariableDeclaration ';'}| {@link ForStatement forStatement}| {@link ForEachStatement forEachStatement}| {@link WhileStatement whileStatement}| {@link DoStatement doStatement}| {@link SwitchStatement switchStatement}| {@link IfStatement ifStatement}| {@link TryStatement tryStatement}| {@link BreakStatement breakStatement}| {@link ContinueStatement continueStatement}| {@link ReturnStatement returnStatement}| {@link ExpressionStatement expressionStatement}| {@link FunctionDeclarationStatement functionSignature functionBody}</pre>
 * @coverage dart.engine.ast
 */
abstract class Statement extends ASTNode {
}
/**
 * Instances of the class {@code StringInterpolation} represent a string interpolation literal.
 * <pre>
 * stringInterpolation ::=
 * ''' {@link InterpolationElement interpolationElement}* '''
 * | '"' {@link InterpolationElement interpolationElement}* '"'
 * </pre>
 * @coverage dart.engine.ast
 */
class StringInterpolation extends StringLiteral {

  /**
   * The elements that will be composed to produce the resulting string.
   */
  NodeList<InterpolationElement> _elements;

  /**
   * Initialize a newly created string interpolation expression.
   * @param elements the elements that will be composed to produce the resulting string
   */
  StringInterpolation.full(List<InterpolationElement> elements) {
    this._elements = new NodeList<InterpolationElement>(this);
    this._elements.addAll(elements);
  }

  /**
   * Initialize a newly created string interpolation expression.
   * @param elements the elements that will be composed to produce the resulting string
   */
  StringInterpolation({List<InterpolationElement> elements}) : this.full(elements);
  accept(ASTVisitor visitor) => visitor.visitStringInterpolation(this);
  Token get beginToken => _elements.beginToken;

  /**
   * Return the elements that will be composed to produce the resulting string.
   * @return the elements that will be composed to produce the resulting string
   */
  NodeList<InterpolationElement> get elements => _elements;
  Token get endToken => _elements.endToken;
  void visitChildren(ASTVisitor<Object> visitor) {
    _elements.accept(visitor);
  }
  void appendStringValue(JavaStringBuilder builder) {
    throw new IllegalArgumentException();
  }
}
/**
 * Instances of the class {@code StringLiteral} represent a string literal expression.
 * <pre>
 * stringLiteral ::={@link SimpleStringLiteral simpleStringLiteral}| {@link AdjacentStrings adjacentStrings}| {@link StringInterpolation stringInterpolation}</pre>
 * @coverage dart.engine.ast
 */
abstract class StringLiteral extends Literal {

  /**
   * Return the value of the string literal, or {@code null} if the string is not a constant string
   * without any string interpolation.
   * @return the value of the string literal
   */
  String get stringValue {
    JavaStringBuilder builder = new JavaStringBuilder();
    try {
      appendStringValue(builder);
    } on IllegalArgumentException catch (exception) {
      return null;
    }
    return builder.toString();
  }

  /**
   * Append the value of the given string literal to the given string builder.
   * @param builder the builder to which the string's value is to be appended
   * @throws IllegalArgumentException if the string is not a constant string without any string
   * interpolation
   */
  void appendStringValue(JavaStringBuilder builder);
}
/**
 * Instances of the class {@code SuperConstructorInvocation} represent the invocation of a
 * superclass' constructor from within a constructor's initialization list.
 * <pre>
 * superInvocation ::=
 * 'super' ('.' {@link SimpleIdentifier name})? {@link ArgumentList argumentList}</pre>
 * @coverage dart.engine.ast
 */
class SuperConstructorInvocation extends ConstructorInitializer {

  /**
   * The token for the 'super' keyword.
   */
  Token _keyword;

  /**
   * The token for the period before the name of the constructor that is being invoked, or{@code null} if the unnamed constructor is being invoked.
   */
  Token _period;

  /**
   * The name of the constructor that is being invoked, or {@code null} if the unnamed constructor
   * is being invoked.
   */
  SimpleIdentifier _constructorName;

  /**
   * The list of arguments to the constructor.
   */
  ArgumentList _argumentList;

  /**
   * The element associated with the constructor based on static type information, or {@code null}if the AST structure has not been resolved or if the constructor could not be resolved.
   */
  ConstructorElement _staticElement;

  /**
   * The element associated with the constructor based on propagated type information, or {@code null} if the AST structure has not been
   * resolved or if the constructor could not be resolved.
   */
  ConstructorElement _propagatedElement;

  /**
   * Initialize a newly created super invocation to invoke the inherited constructor with the given
   * name with the given arguments.
   * @param keyword the token for the 'super' keyword
   * @param period the token for the period before the name of the constructor that is being invoked
   * @param constructorName the name of the constructor that is being invoked
   * @param argumentList the list of arguments to the constructor
   */
  SuperConstructorInvocation.full(Token keyword, Token period, SimpleIdentifier constructorName, ArgumentList argumentList) {
    this._keyword = keyword;
    this._period = period;
    this._constructorName = becomeParentOf(constructorName);
    this._argumentList = becomeParentOf(argumentList);
  }

  /**
   * Initialize a newly created super invocation to invoke the inherited constructor with the given
   * name with the given arguments.
   * @param keyword the token for the 'super' keyword
   * @param period the token for the period before the name of the constructor that is being invoked
   * @param constructorName the name of the constructor that is being invoked
   * @param argumentList the list of arguments to the constructor
   */
  SuperConstructorInvocation({Token keyword, Token period, SimpleIdentifier constructorName, ArgumentList argumentList}) : this.full(keyword, period, constructorName, argumentList);
  accept(ASTVisitor visitor) => visitor.visitSuperConstructorInvocation(this);

  /**
   * Return the list of arguments to the constructor.
   * @return the list of arguments to the constructor
   */
  ArgumentList get argumentList => _argumentList;
  Token get beginToken => _keyword;

  /**
   * Return the name of the constructor that is being invoked, or {@code null} if the unnamed
   * constructor is being invoked.
   * @return the name of the constructor that is being invoked
   */
  SimpleIdentifier get constructorName => _constructorName;

  /**
   * Return the element associated with the constructor based on propagated type information, or{@code null} if the AST structure has not been resolved or if the constructor could not be
   * resolved.
   * @return the element associated with the super constructor
   */
  ConstructorElement get element => _propagatedElement;
  Token get endToken => _argumentList.endToken;

  /**
   * Return the token for the 'super' keyword.
   * @return the token for the 'super' keyword
   */
  Token get keyword => _keyword;

  /**
   * Return the token for the period before the name of the constructor that is being invoked, or{@code null} if the unnamed constructor is being invoked.
   * @return the token for the period before the name of the constructor that is being invoked
   */
  Token get period => _period;

  /**
   * Return the element associated with the constructor based on static type information, or{@code null} if the AST structure has not been resolved or if the constructor could not be
   * resolved.
   * @return the element associated with the constructor
   */
  ConstructorElement get staticElement => _staticElement;

  /**
   * Set the list of arguments to the constructor to the given list.
   * @param argumentList the list of arguments to the constructor
   */
  void set argumentList(ArgumentList argumentList2) {
    this._argumentList = becomeParentOf(argumentList2);
  }

  /**
   * Set the name of the constructor that is being invoked to the given identifier.
   * @param identifier the name of the constructor that is being invoked
   */
  void set constructorName(SimpleIdentifier identifier) {
    _constructorName = becomeParentOf(identifier);
  }

  /**
   * Set the element associated with the constructor based on propagated type information to the
   * given element.
   * @param element the element to be associated with the constructor
   */
  void set element(ConstructorElement element2) {
    _propagatedElement = element2;
  }

  /**
   * Set the token for the 'super' keyword to the given token.
   * @param keyword the token for the 'super' keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }

  /**
   * Set the token for the period before the name of the constructor that is being invoked to the
   * given token.
   * @param period the token for the period before the name of the constructor that is being invoked
   */
  void set period(Token period2) {
    this._period = period2;
  }

  /**
   * Set the element associated with the constructor based on static type information to the given
   * element.
   * @param element the element to be associated with the constructor
   */
  void set staticElement(ConstructorElement element) {
    this._staticElement = element;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_constructorName, visitor);
    safelyVisitChild(_argumentList, visitor);
  }
}
/**
 * Instances of the class {@code SuperExpression} represent a super expression.
 * <pre>
 * superExpression ::=
 * 'super'
 * </pre>
 * @coverage dart.engine.ast
 */
class SuperExpression extends Expression {

  /**
   * The token representing the keyword.
   */
  Token _keyword;

  /**
   * Initialize a newly created super expression.
   * @param keyword the token representing the keyword
   */
  SuperExpression.full(Token keyword) {
    this._keyword = keyword;
  }

  /**
   * Initialize a newly created super expression.
   * @param keyword the token representing the keyword
   */
  SuperExpression({Token keyword}) : this.full(keyword);
  accept(ASTVisitor visitor) => visitor.visitSuperExpression(this);
  Token get beginToken => _keyword;
  Token get endToken => _keyword;

  /**
   * Return the token representing the keyword.
   * @return the token representing the keyword
   */
  Token get keyword => _keyword;

  /**
   * Set the token representing the keyword to the given token.
   * @param keyword the token representing the keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
  }
}
/**
 * Instances of the class {@code SwitchCase} represent the case in a switch statement.
 * <pre>
 * switchCase ::={@link SimpleIdentifier label}* 'case' {@link Expression expression} ':' {@link Statement statement}</pre>
 * @coverage dart.engine.ast
 */
class SwitchCase extends SwitchMember {

  /**
   * The expression controlling whether the statements will be executed.
   */
  Expression _expression;

  /**
   * Initialize a newly created switch case.
   * @param labels the labels associated with the switch member
   * @param keyword the token representing the 'case' or 'default' keyword
   * @param expression the expression controlling whether the statements will be executed
   * @param colon the colon separating the keyword or the expression from the statements
   * @param statements the statements that will be executed if this switch member is selected
   */
  SwitchCase.full(List<Label> labels, Token keyword, Expression expression, Token colon, List<Statement> statements) : super.full(labels, keyword, colon, statements) {
    this._expression = becomeParentOf(expression);
  }

  /**
   * Initialize a newly created switch case.
   * @param labels the labels associated with the switch member
   * @param keyword the token representing the 'case' or 'default' keyword
   * @param expression the expression controlling whether the statements will be executed
   * @param colon the colon separating the keyword or the expression from the statements
   * @param statements the statements that will be executed if this switch member is selected
   */
  SwitchCase({List<Label> labels, Token keyword, Expression expression, Token colon, List<Statement> statements}) : this.full(labels, keyword, expression, colon, statements);
  accept(ASTVisitor visitor) => visitor.visitSwitchCase(this);

  /**
   * Return the expression controlling whether the statements will be executed.
   * @return the expression controlling whether the statements will be executed
   */
  Expression get expression => _expression;

  /**
   * Set the expression controlling whether the statements will be executed to the given expression.
   * @param expression the expression controlling whether the statements will be executed
   */
  void set expression(Expression expression2) {
    this._expression = becomeParentOf(expression2);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    labels.accept(visitor);
    safelyVisitChild(_expression, visitor);
    statements.accept(visitor);
  }
}
/**
 * Instances of the class {@code SwitchDefault} represent the default case in a switch statement.
 * <pre>
 * switchDefault ::={@link SimpleIdentifier label}* 'default' ':' {@link Statement statement}</pre>
 * @coverage dart.engine.ast
 */
class SwitchDefault extends SwitchMember {

  /**
   * Initialize a newly created switch default.
   * @param labels the labels associated with the switch member
   * @param keyword the token representing the 'case' or 'default' keyword
   * @param colon the colon separating the keyword or the expression from the statements
   * @param statements the statements that will be executed if this switch member is selected
   */
  SwitchDefault.full(List<Label> labels, Token keyword, Token colon, List<Statement> statements) : super.full(labels, keyword, colon, statements) {
  }

  /**
   * Initialize a newly created switch default.
   * @param labels the labels associated with the switch member
   * @param keyword the token representing the 'case' or 'default' keyword
   * @param colon the colon separating the keyword or the expression from the statements
   * @param statements the statements that will be executed if this switch member is selected
   */
  SwitchDefault({List<Label> labels, Token keyword, Token colon, List<Statement> statements}) : this.full(labels, keyword, colon, statements);
  accept(ASTVisitor visitor) => visitor.visitSwitchDefault(this);
  void visitChildren(ASTVisitor<Object> visitor) {
    labels.accept(visitor);
    statements.accept(visitor);
  }
}
/**
 * The abstract class {@code SwitchMember} defines the behavior common to objects representing
 * elements within a switch statement.
 * <pre>
 * switchMember ::=
 * switchCase
 * | switchDefault
 * </pre>
 * @coverage dart.engine.ast
 */
abstract class SwitchMember extends ASTNode {

  /**
   * The labels associated with the switch member.
   */
  NodeList<Label> _labels;

  /**
   * The token representing the 'case' or 'default' keyword.
   */
  Token _keyword;

  /**
   * The colon separating the keyword or the expression from the statements.
   */
  Token _colon;

  /**
   * The statements that will be executed if this switch member is selected.
   */
  NodeList<Statement> _statements;

  /**
   * Initialize a newly created switch member.
   * @param labels the labels associated with the switch member
   * @param keyword the token representing the 'case' or 'default' keyword
   * @param colon the colon separating the keyword or the expression from the statements
   * @param statements the statements that will be executed if this switch member is selected
   */
  SwitchMember.full(List<Label> labels, Token keyword, Token colon, List<Statement> statements) {
    this._labels = new NodeList<Label>(this);
    this._statements = new NodeList<Statement>(this);
    this._labels.addAll(labels);
    this._keyword = keyword;
    this._colon = colon;
    this._statements.addAll(statements);
  }

  /**
   * Initialize a newly created switch member.
   * @param labels the labels associated with the switch member
   * @param keyword the token representing the 'case' or 'default' keyword
   * @param colon the colon separating the keyword or the expression from the statements
   * @param statements the statements that will be executed if this switch member is selected
   */
  SwitchMember({List<Label> labels, Token keyword, Token colon, List<Statement> statements}) : this.full(labels, keyword, colon, statements);
  Token get beginToken {
    if (!_labels.isEmpty) {
      return _labels.beginToken;
    }
    return _keyword;
  }

  /**
   * Return the colon separating the keyword or the expression from the statements.
   * @return the colon separating the keyword or the expression from the statements
   */
  Token get colon => _colon;
  Token get endToken {
    if (!_statements.isEmpty) {
      return _statements.endToken;
    }
    return _colon;
  }

  /**
   * Return the token representing the 'case' or 'default' keyword.
   * @return the token representing the 'case' or 'default' keyword
   */
  Token get keyword => _keyword;

  /**
   * Return the labels associated with the switch member.
   * @return the labels associated with the switch member
   */
  NodeList<Label> get labels => _labels;

  /**
   * Return the statements that will be executed if this switch member is selected.
   * @return the statements that will be executed if this switch member is selected
   */
  NodeList<Statement> get statements => _statements;

  /**
   * Set the colon separating the keyword or the expression from the statements to the given token.
   * @param colon the colon separating the keyword or the expression from the statements
   */
  void set colon(Token colon2) {
    this._colon = colon2;
  }

  /**
   * Set the token representing the 'case' or 'default' keyword to the given token.
   * @param keyword the token representing the 'case' or 'default' keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }
}
/**
 * Instances of the class {@code SwitchStatement} represent a switch statement.
 * <pre>
 * switchStatement ::=
 * 'switch' '(' {@link Expression expression} ')' '{' {@link SwitchCase switchCase}* {@link SwitchDefault defaultCase}? '}'
 * </pre>
 * @coverage dart.engine.ast
 */
class SwitchStatement extends Statement {

  /**
   * The token representing the 'switch' keyword.
   */
  Token _keyword;

  /**
   * The left parenthesis.
   */
  Token _leftParenthesis;

  /**
   * The expression used to determine which of the switch members will be selected.
   */
  Expression _expression;

  /**
   * The right parenthesis.
   */
  Token _rightParenthesis;

  /**
   * The left curly bracket.
   */
  Token _leftBracket;

  /**
   * The switch members that can be selected by the expression.
   */
  NodeList<SwitchMember> _members;

  /**
   * The right curly bracket.
   */
  Token _rightBracket;

  /**
   * Initialize a newly created switch statement.
   * @param keyword the token representing the 'switch' keyword
   * @param leftParenthesis the left parenthesis
   * @param expression the expression used to determine which of the switch members will be selected
   * @param rightParenthesis the right parenthesis
   * @param leftBracket the left curly bracket
   * @param members the switch members that can be selected by the expression
   * @param rightBracket the right curly bracket
   */
  SwitchStatement.full(Token keyword, Token leftParenthesis, Expression expression, Token rightParenthesis, Token leftBracket, List<SwitchMember> members, Token rightBracket) {
    this._members = new NodeList<SwitchMember>(this);
    this._keyword = keyword;
    this._leftParenthesis = leftParenthesis;
    this._expression = becomeParentOf(expression);
    this._rightParenthesis = rightParenthesis;
    this._leftBracket = leftBracket;
    this._members.addAll(members);
    this._rightBracket = rightBracket;
  }

  /**
   * Initialize a newly created switch statement.
   * @param keyword the token representing the 'switch' keyword
   * @param leftParenthesis the left parenthesis
   * @param expression the expression used to determine which of the switch members will be selected
   * @param rightParenthesis the right parenthesis
   * @param leftBracket the left curly bracket
   * @param members the switch members that can be selected by the expression
   * @param rightBracket the right curly bracket
   */
  SwitchStatement({Token keyword, Token leftParenthesis, Expression expression, Token rightParenthesis, Token leftBracket, List<SwitchMember> members, Token rightBracket}) : this.full(keyword, leftParenthesis, expression, rightParenthesis, leftBracket, members, rightBracket);
  accept(ASTVisitor visitor) => visitor.visitSwitchStatement(this);
  Token get beginToken => _keyword;
  Token get endToken => _rightBracket;

  /**
   * Return the expression used to determine which of the switch members will be selected.
   * @return the expression used to determine which of the switch members will be selected
   */
  Expression get expression => _expression;

  /**
   * Return the token representing the 'switch' keyword.
   * @return the token representing the 'switch' keyword
   */
  Token get keyword => _keyword;

  /**
   * Return the left curly bracket.
   * @return the left curly bracket
   */
  Token get leftBracket => _leftBracket;

  /**
   * Return the left parenthesis.
   * @return the left parenthesis
   */
  Token get leftParenthesis => _leftParenthesis;

  /**
   * Return the switch members that can be selected by the expression.
   * @return the switch members that can be selected by the expression
   */
  NodeList<SwitchMember> get members => _members;

  /**
   * Return the right curly bracket.
   * @return the right curly bracket
   */
  Token get rightBracket => _rightBracket;

  /**
   * Return the right parenthesis.
   * @return the right parenthesis
   */
  Token get rightParenthesis => _rightParenthesis;

  /**
   * Set the expression used to determine which of the switch members will be selected to the given
   * expression.
   * @param expression the expression used to determine which of the switch members will be selected
   */
  void set expression(Expression expression2) {
    this._expression = becomeParentOf(expression2);
  }

  /**
   * Set the token representing the 'switch' keyword to the given token.
   * @param keyword the token representing the 'switch' keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }

  /**
   * Set the left curly bracket to the given token.
   * @param leftBracket the left curly bracket
   */
  void set leftBracket(Token leftBracket2) {
    this._leftBracket = leftBracket2;
  }

  /**
   * Set the left parenthesis to the given token.
   * @param leftParenthesis the left parenthesis
   */
  void set leftParenthesis(Token leftParenthesis2) {
    this._leftParenthesis = leftParenthesis2;
  }

  /**
   * Set the right curly bracket to the given token.
   * @param rightBracket the right curly bracket
   */
  void set rightBracket(Token rightBracket2) {
    this._rightBracket = rightBracket2;
  }

  /**
   * Set the right parenthesis to the given token.
   * @param rightParenthesis the right parenthesis
   */
  void set rightParenthesis(Token rightParenthesis2) {
    this._rightParenthesis = rightParenthesis2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_expression, visitor);
    _members.accept(visitor);
  }
}
/**
 * Instances of the class {@code ThisExpression} represent a this expression.
 * <pre>
 * thisExpression ::=
 * 'this'
 * </pre>
 * @coverage dart.engine.ast
 */
class ThisExpression extends Expression {

  /**
   * The token representing the keyword.
   */
  Token _keyword;

  /**
   * Initialize a newly created this expression.
   * @param keyword the token representing the keyword
   */
  ThisExpression.full(Token keyword) {
    this._keyword = keyword;
  }

  /**
   * Initialize a newly created this expression.
   * @param keyword the token representing the keyword
   */
  ThisExpression({Token keyword}) : this.full(keyword);
  accept(ASTVisitor visitor) => visitor.visitThisExpression(this);
  Token get beginToken => _keyword;
  Token get endToken => _keyword;

  /**
   * Return the token representing the keyword.
   * @return the token representing the keyword
   */
  Token get keyword => _keyword;

  /**
   * Set the token representing the keyword to the given token.
   * @param keyword the token representing the keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
  }
}
/**
 * Instances of the class {@code ThrowExpression} represent a throw expression.
 * <pre>
 * throwExpression ::=
 * 'throw' {@link Expression expression}</pre>
 * @coverage dart.engine.ast
 */
class ThrowExpression extends Expression {

  /**
   * The token representing the 'throw' keyword.
   */
  Token _keyword;

  /**
   * The expression computing the exception to be thrown.
   */
  Expression _expression;

  /**
   * Initialize a newly created throw expression.
   * @param keyword the token representing the 'throw' keyword
   * @param expression the expression computing the exception to be thrown
   */
  ThrowExpression.full(Token keyword, Expression expression) {
    this._keyword = keyword;
    this._expression = becomeParentOf(expression);
  }

  /**
   * Initialize a newly created throw expression.
   * @param keyword the token representing the 'throw' keyword
   * @param expression the expression computing the exception to be thrown
   */
  ThrowExpression({Token keyword, Expression expression}) : this.full(keyword, expression);
  accept(ASTVisitor visitor) => visitor.visitThrowExpression(this);
  Token get beginToken => _keyword;
  Token get endToken {
    if (_expression != null) {
      return _expression.endToken;
    }
    return _keyword;
  }

  /**
   * Return the expression computing the exception to be thrown.
   * @return the expression computing the exception to be thrown
   */
  Expression get expression => _expression;

  /**
   * Return the token representing the 'throw' keyword.
   * @return the token representing the 'throw' keyword
   */
  Token get keyword => _keyword;

  /**
   * Set the expression computing the exception to be thrown to the given expression.
   * @param expression the expression computing the exception to be thrown
   */
  void set expression(Expression expression2) {
    this._expression = becomeParentOf(expression2);
  }

  /**
   * Set the token representing the 'throw' keyword to the given token.
   * @param keyword the token representing the 'throw' keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_expression, visitor);
  }
}
/**
 * Instances of the class {@code TopLevelVariableDeclaration} represent the declaration of one or
 * more top-level variables of the same type.
 * <pre>
 * topLevelVariableDeclaration ::=
 * ('final' | 'const') type? staticFinalDeclarationList ';'
 * | variableDeclaration ';'
 * </pre>
 * @coverage dart.engine.ast
 */
class TopLevelVariableDeclaration extends CompilationUnitMember {

  /**
   * The top-level variables being declared.
   */
  VariableDeclarationList _variableList;

  /**
   * The semicolon terminating the declaration.
   */
  Token _semicolon;

  /**
   * Initialize a newly created top-level variable declaration.
   * @param comment the documentation comment associated with this variable
   * @param metadata the annotations associated with this variable
   * @param variableList the top-level variables being declared
   * @param semicolon the semicolon terminating the declaration
   */
  TopLevelVariableDeclaration.full(Comment comment, List<Annotation> metadata, VariableDeclarationList variableList, Token semicolon) : super.full(comment, metadata) {
    this._variableList = becomeParentOf(variableList);
    this._semicolon = semicolon;
  }

  /**
   * Initialize a newly created top-level variable declaration.
   * @param comment the documentation comment associated with this variable
   * @param metadata the annotations associated with this variable
   * @param variableList the top-level variables being declared
   * @param semicolon the semicolon terminating the declaration
   */
  TopLevelVariableDeclaration({Comment comment, List<Annotation> metadata, VariableDeclarationList variableList, Token semicolon}) : this.full(comment, metadata, variableList, semicolon);
  accept(ASTVisitor visitor) => visitor.visitTopLevelVariableDeclaration(this);
  Element get element => null;
  Token get endToken => _semicolon;

  /**
   * Return the semicolon terminating the declaration.
   * @return the semicolon terminating the declaration
   */
  Token get semicolon => _semicolon;

  /**
   * Return the top-level variables being declared.
   * @return the top-level variables being declared
   */
  VariableDeclarationList get variables => _variableList;

  /**
   * Set the semicolon terminating the declaration to the given token.
   * @param semicolon the semicolon terminating the declaration
   */
  void set semicolon(Token semicolon2) {
    this._semicolon = semicolon2;
  }

  /**
   * Set the top-level variables being declared to the given list of variables.
   * @param variableList the top-level variables being declared
   */
  void set variables(VariableDeclarationList variableList) {
    variableList = becomeParentOf(variableList);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_variableList, visitor);
  }
  Token get firstTokenAfterCommentAndMetadata => _variableList.beginToken;
}
/**
 * Instances of the class {@code TryStatement} represent a try statement.
 * <pre>
 * tryStatement ::=
 * 'try' {@link Block block} ({@link CatchClause catchClause}+ finallyClause? | finallyClause)
 * finallyClause ::=
 * 'finally' {@link Block block}</pre>
 * @coverage dart.engine.ast
 */
class TryStatement extends Statement {

  /**
   * The token representing the 'try' keyword.
   */
  Token _tryKeyword;

  /**
   * The body of the statement.
   */
  Block _body;

  /**
   * The catch clauses contained in the try statement.
   */
  NodeList<CatchClause> _catchClauses;

  /**
   * The token representing the 'finally' keyword, or {@code null} if the statement does not contain
   * a finally clause.
   */
  Token _finallyKeyword;

  /**
   * The finally clause contained in the try statement, or {@code null} if the statement does not
   * contain a finally clause.
   */
  Block _finallyClause;

  /**
   * Initialize a newly created try statement.
   * @param tryKeyword the token representing the 'try' keyword
   * @param body the body of the statement
   * @param catchClauses the catch clauses contained in the try statement
   * @param finallyKeyword the token representing the 'finally' keyword
   * @param finallyClause the finally clause contained in the try statement
   */
  TryStatement.full(Token tryKeyword, Block body, List<CatchClause> catchClauses, Token finallyKeyword, Block finallyClause) {
    this._catchClauses = new NodeList<CatchClause>(this);
    this._tryKeyword = tryKeyword;
    this._body = becomeParentOf(body);
    this._catchClauses.addAll(catchClauses);
    this._finallyKeyword = finallyKeyword;
    this._finallyClause = becomeParentOf(finallyClause);
  }

  /**
   * Initialize a newly created try statement.
   * @param tryKeyword the token representing the 'try' keyword
   * @param body the body of the statement
   * @param catchClauses the catch clauses contained in the try statement
   * @param finallyKeyword the token representing the 'finally' keyword
   * @param finallyClause the finally clause contained in the try statement
   */
  TryStatement({Token tryKeyword, Block body, List<CatchClause> catchClauses, Token finallyKeyword, Block finallyClause}) : this.full(tryKeyword, body, catchClauses, finallyKeyword, finallyClause);
  accept(ASTVisitor visitor) => visitor.visitTryStatement(this);
  Token get beginToken => _tryKeyword;

  /**
   * Return the body of the statement.
   * @return the body of the statement
   */
  Block get body => _body;

  /**
   * Return the catch clauses contained in the try statement.
   * @return the catch clauses contained in the try statement
   */
  NodeList<CatchClause> get catchClauses => _catchClauses;
  Token get endToken {
    if (_finallyClause != null) {
      return _finallyClause.endToken;
    } else if (_finallyKeyword != null) {
      return _finallyKeyword;
    } else if (!_catchClauses.isEmpty) {
      return _catchClauses.endToken;
    }
    return _body.endToken;
  }

  /**
   * Return the finally clause contained in the try statement, or {@code null} if the statement does
   * not contain a finally clause.
   * @return the finally clause contained in the try statement
   */
  Block get finallyClause => _finallyClause;

  /**
   * Return the token representing the 'finally' keyword, or {@code null} if the statement does not
   * contain a finally clause.
   * @return the token representing the 'finally' keyword
   */
  Token get finallyKeyword => _finallyKeyword;

  /**
   * Return the token representing the 'try' keyword.
   * @return the token representing the 'try' keyword
   */
  Token get tryKeyword => _tryKeyword;

  /**
   * Set the body of the statement to the given block.
   * @param block the body of the statement
   */
  void set body(Block block) {
    _body = becomeParentOf(block);
  }

  /**
   * Set the finally clause contained in the try statement to the given block.
   * @param block the finally clause contained in the try statement
   */
  void set finallyClause(Block block) {
    _finallyClause = becomeParentOf(block);
  }

  /**
   * Set the token representing the 'finally' keyword to the given token.
   * @param finallyKeyword the token representing the 'finally' keyword
   */
  void set finallyKeyword(Token finallyKeyword2) {
    this._finallyKeyword = finallyKeyword2;
  }

  /**
   * Set the token representing the 'try' keyword to the given token.
   * @param tryKeyword the token representing the 'try' keyword
   */
  void set tryKeyword(Token tryKeyword2) {
    this._tryKeyword = tryKeyword2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_body, visitor);
    _catchClauses.accept(visitor);
    safelyVisitChild(_finallyClause, visitor);
  }
}
/**
 * The abstract class {@code TypeAlias} defines the behavior common to declarations of type aliases.
 * <pre>
 * typeAlias ::=
 * 'typedef' typeAliasBody
 * typeAliasBody ::=
 * classTypeAlias
 * | functionTypeAlias
 * </pre>
 * @coverage dart.engine.ast
 */
abstract class TypeAlias extends CompilationUnitMember {

  /**
   * The token representing the 'typedef' keyword.
   */
  Token _keyword;

  /**
   * The semicolon terminating the declaration.
   */
  Token _semicolon;

  /**
   * Initialize a newly created type alias.
   * @param comment the documentation comment associated with this type alias
   * @param metadata the annotations associated with this type alias
   * @param keyword the token representing the 'typedef' keyword
   * @param semicolon the semicolon terminating the declaration
   */
  TypeAlias.full(Comment comment, List<Annotation> metadata, Token keyword, Token semicolon) : super.full(comment, metadata) {
    this._keyword = keyword;
    this._semicolon = semicolon;
  }

  /**
   * Initialize a newly created type alias.
   * @param comment the documentation comment associated with this type alias
   * @param metadata the annotations associated with this type alias
   * @param keyword the token representing the 'typedef' keyword
   * @param semicolon the semicolon terminating the declaration
   */
  TypeAlias({Comment comment, List<Annotation> metadata, Token keyword, Token semicolon}) : this.full(comment, metadata, keyword, semicolon);
  Token get endToken => _semicolon;

  /**
   * Return the token representing the 'typedef' keyword.
   * @return the token representing the 'typedef' keyword
   */
  Token get keyword => _keyword;

  /**
   * Return the semicolon terminating the declaration.
   * @return the semicolon terminating the declaration
   */
  Token get semicolon => _semicolon;

  /**
   * Set the token representing the 'typedef' keyword to the given token.
   * @param keyword the token representing the 'typedef' keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }

  /**
   * Set the semicolon terminating the declaration to the given token.
   * @param semicolon the semicolon terminating the declaration
   */
  void set semicolon(Token semicolon2) {
    this._semicolon = semicolon2;
  }
  Token get firstTokenAfterCommentAndMetadata => _keyword;
}
/**
 * Instances of the class {@code TypeArgumentList} represent a list of type arguments.
 * <pre>
 * typeArguments ::=
 * '<' typeName (',' typeName)* '>'
 * </pre>
 * @coverage dart.engine.ast
 */
class TypeArgumentList extends ASTNode {

  /**
   * The left bracket.
   */
  Token _leftBracket;

  /**
   * The type arguments associated with the type.
   */
  NodeList<TypeName> _arguments;

  /**
   * The right bracket.
   */
  Token _rightBracket;

  /**
   * Initialize a newly created list of type arguments.
   * @param leftBracket the left bracket
   * @param arguments the type arguments associated with the type
   * @param rightBracket the right bracket
   */
  TypeArgumentList.full(Token leftBracket, List<TypeName> arguments, Token rightBracket) {
    this._arguments = new NodeList<TypeName>(this);
    this._leftBracket = leftBracket;
    this._arguments.addAll(arguments);
    this._rightBracket = rightBracket;
  }

  /**
   * Initialize a newly created list of type arguments.
   * @param leftBracket the left bracket
   * @param arguments the type arguments associated with the type
   * @param rightBracket the right bracket
   */
  TypeArgumentList({Token leftBracket, List<TypeName> arguments, Token rightBracket}) : this.full(leftBracket, arguments, rightBracket);
  accept(ASTVisitor visitor) => visitor.visitTypeArgumentList(this);

  /**
   * Return the type arguments associated with the type.
   * @return the type arguments associated with the type
   */
  NodeList<TypeName> get arguments => _arguments;
  Token get beginToken => _leftBracket;
  Token get endToken => _rightBracket;

  /**
   * Return the left bracket.
   * @return the left bracket
   */
  Token get leftBracket => _leftBracket;

  /**
   * Return the right bracket.
   * @return the right bracket
   */
  Token get rightBracket => _rightBracket;

  /**
   * Set the left bracket to the given token.
   * @param leftBracket the left bracket
   */
  void set leftBracket(Token leftBracket2) {
    this._leftBracket = leftBracket2;
  }

  /**
   * Set the right bracket to the given token.
   * @param rightBracket the right bracket
   */
  void set rightBracket(Token rightBracket2) {
    this._rightBracket = rightBracket2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    _arguments.accept(visitor);
  }
}
/**
 * Instances of the class {@code TypeName} represent the name of a type, which can optionally
 * include type arguments.
 * <pre>
 * typeName ::={@link Identifier identifier} typeArguments?
 * </pre>
 * @coverage dart.engine.ast
 */
class TypeName extends ASTNode {

  /**
   * The name of the type.
   */
  Identifier _name;

  /**
   * The type arguments associated with the type, or {@code null} if there are no type arguments.
   */
  TypeArgumentList _typeArguments;

  /**
   * The type being named, or {@code null} if the AST structure has not been resolved.
   */
  Type2 _type;

  /**
   * Initialize a newly created type name.
   * @param name the name of the type
   * @param typeArguments the type arguments associated with the type, or {@code null} if there are
   * no type arguments
   */
  TypeName.full(Identifier name, TypeArgumentList typeArguments) {
    this._name = becomeParentOf(name);
    this._typeArguments = becomeParentOf(typeArguments);
  }

  /**
   * Initialize a newly created type name.
   * @param name the name of the type
   * @param typeArguments the type arguments associated with the type, or {@code null} if there are
   * no type arguments
   */
  TypeName({Identifier name, TypeArgumentList typeArguments}) : this.full(name, typeArguments);
  accept(ASTVisitor visitor) => visitor.visitTypeName(this);
  Token get beginToken => _name.beginToken;
  Token get endToken {
    if (_typeArguments != null) {
      return _typeArguments.endToken;
    }
    return _name.endToken;
  }

  /**
   * Return the name of the type.
   * @return the name of the type
   */
  Identifier get name => _name;

  /**
   * Return the type being named, or {@code null} if the AST structure has not been resolved.
   * @return the type being named
   */
  Type2 get type => _type;

  /**
   * Return the type arguments associated with the type, or {@code null} if there are no type
   * arguments.
   * @return the type arguments associated with the type
   */
  TypeArgumentList get typeArguments => _typeArguments;
  bool isSynthetic() => _name.isSynthetic() && _typeArguments == null;

  /**
   * Set the name of the type to the given identifier.
   * @param identifier the name of the type
   */
  void set name(Identifier identifier) {
    _name = becomeParentOf(identifier);
  }

  /**
   * Set the type being named to the given type.
   * @param type the type being named
   */
  void set type(Type2 type2) {
    this._type = type2;
  }

  /**
   * Set the type arguments associated with the type to the given type arguments.
   * @param typeArguments the type arguments associated with the type
   */
  void set typeArguments(TypeArgumentList typeArguments2) {
    this._typeArguments = becomeParentOf(typeArguments2);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_name, visitor);
    safelyVisitChild(_typeArguments, visitor);
  }
}
/**
 * Instances of the class {@code TypeParameter} represent a type parameter.
 * <pre>
 * typeParameter ::={@link SimpleIdentifier name} ('extends' {@link TypeName bound})?
 * </pre>
 * @coverage dart.engine.ast
 */
class TypeParameter extends Declaration {

  /**
   * The name of the type parameter.
   */
  SimpleIdentifier _name;

  /**
   * The token representing the 'extends' keyword, or {@code null} if there was no explicit upper
   * bound.
   */
  Token _keyword;

  /**
   * The name of the upper bound for legal arguments, or {@code null} if there was no explicit upper
   * bound.
   */
  TypeName _bound;

  /**
   * Initialize a newly created type parameter.
   * @param comment the documentation comment associated with the type parameter
   * @param metadata the annotations associated with the type parameter
   * @param name the name of the type parameter
   * @param keyword the token representing the 'extends' keyword
   * @param bound the name of the upper bound for legal arguments
   */
  TypeParameter.full(Comment comment, List<Annotation> metadata, SimpleIdentifier name, Token keyword, TypeName bound) : super.full(comment, metadata) {
    this._name = becomeParentOf(name);
    this._keyword = keyword;
    this._bound = becomeParentOf(bound);
  }

  /**
   * Initialize a newly created type parameter.
   * @param comment the documentation comment associated with the type parameter
   * @param metadata the annotations associated with the type parameter
   * @param name the name of the type parameter
   * @param keyword the token representing the 'extends' keyword
   * @param bound the name of the upper bound for legal arguments
   */
  TypeParameter({Comment comment, List<Annotation> metadata, SimpleIdentifier name, Token keyword, TypeName bound}) : this.full(comment, metadata, name, keyword, bound);
  accept(ASTVisitor visitor) => visitor.visitTypeParameter(this);

  /**
   * Return the name of the upper bound for legal arguments, or {@code null} if there was no
   * explicit upper bound.
   * @return the name of the upper bound for legal arguments
   */
  TypeName get bound => _bound;
  TypeVariableElement get element => _name != null ? (_name.element as TypeVariableElement) : null;
  Token get endToken {
    if (_bound == null) {
      return _name.endToken;
    }
    return _bound.endToken;
  }

  /**
   * Return the token representing the 'assert' keyword.
   * @return the token representing the 'assert' keyword
   */
  Token get keyword => _keyword;

  /**
   * Return the name of the type parameter.
   * @return the name of the type parameter
   */
  SimpleIdentifier get name => _name;

  /**
   * Set the name of the upper bound for legal arguments to the given type name.
   * @param typeName the name of the upper bound for legal arguments
   */
  void set bound(TypeName typeName) {
    _bound = becomeParentOf(typeName);
  }

  /**
   * Set the token representing the 'assert' keyword to the given token.
   * @param keyword the token representing the 'assert' keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }

  /**
   * Set the name of the type parameter to the given identifier.
   * @param identifier the name of the type parameter
   */
  void set name(SimpleIdentifier identifier) {
    _name = becomeParentOf(identifier);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_name, visitor);
    safelyVisitChild(_bound, visitor);
  }
  Token get firstTokenAfterCommentAndMetadata => _name.beginToken;
}
/**
 * Instances of the class {@code TypeParameterList} represent type parameters within a declaration.
 * <pre>
 * typeParameterList ::=
 * '<' {@link TypeParameter typeParameter} (',' {@link TypeParameter typeParameter})* '>'
 * </pre>
 * @coverage dart.engine.ast
 */
class TypeParameterList extends ASTNode {

  /**
   * The left angle bracket.
   */
  Token _leftBracket;

  /**
   * The type parameters in the list.
   */
  NodeList<TypeParameter> _typeParameters;

  /**
   * The right angle bracket.
   */
  Token _rightBracket;

  /**
   * Initialize a newly created list of type parameters.
   * @param leftBracket the left angle bracket
   * @param typeParameters the type parameters in the list
   * @param rightBracket the right angle bracket
   */
  TypeParameterList.full(Token leftBracket, List<TypeParameter> typeParameters, Token rightBracket) {
    this._typeParameters = new NodeList<TypeParameter>(this);
    this._leftBracket = leftBracket;
    this._typeParameters.addAll(typeParameters);
    this._rightBracket = rightBracket;
  }

  /**
   * Initialize a newly created list of type parameters.
   * @param leftBracket the left angle bracket
   * @param typeParameters the type parameters in the list
   * @param rightBracket the right angle bracket
   */
  TypeParameterList({Token leftBracket, List<TypeParameter> typeParameters, Token rightBracket}) : this.full(leftBracket, typeParameters, rightBracket);
  accept(ASTVisitor visitor) => visitor.visitTypeParameterList(this);
  Token get beginToken => _leftBracket;
  Token get endToken => _rightBracket;

  /**
   * Return the left angle bracket.
   * @return the left angle bracket
   */
  Token get leftBracket => _leftBracket;

  /**
   * Return the right angle bracket.
   * @return the right angle bracket
   */
  Token get rightBracket => _rightBracket;

  /**
   * Return the type parameters for the type.
   * @return the type parameters for the type
   */
  NodeList<TypeParameter> get typeParameters => _typeParameters;
  void visitChildren(ASTVisitor<Object> visitor) {
    _typeParameters.accept(visitor);
  }
}
/**
 * The abstract class {@code TypedLiteral} defines the behavior common to literals that have a type
 * associated with them.
 * <pre>
 * listLiteral ::={@link ListLiteral listLiteral}| {@link MapLiteral mapLiteral}</pre>
 * @coverage dart.engine.ast
 */
abstract class TypedLiteral extends Literal {

  /**
   * The const modifier associated with this literal, or {@code null} if the literal is not a
   * constant.
   */
  Token _modifier;

  /**
   * The type argument associated with this literal, or {@code null} if no type arguments were
   * declared.
   */
  TypeArgumentList _typeArguments;

  /**
   * Initialize a newly created typed literal.
   * @param modifier the const modifier associated with this literal
   * @param typeArguments the type argument associated with this literal, or {@code null} if no type
   * arguments were declared
   */
  TypedLiteral.full(Token modifier, TypeArgumentList typeArguments) {
    this._modifier = modifier;
    this._typeArguments = becomeParentOf(typeArguments);
  }

  /**
   * Initialize a newly created typed literal.
   * @param modifier the const modifier associated with this literal
   * @param typeArguments the type argument associated with this literal, or {@code null} if no type
   * arguments were declared
   */
  TypedLiteral({Token modifier, TypeArgumentList typeArguments}) : this.full(modifier, typeArguments);

  /**
   * Return the const modifier associated with this literal.
   * @return the const modifier associated with this literal
   */
  Token get modifier => _modifier;

  /**
   * Return the type argument associated with this literal, or {@code null} if no type arguments
   * were declared.
   * @return the type argument associated with this literal
   */
  TypeArgumentList get typeArguments => _typeArguments;

  /**
   * Set the modifiers associated with this literal to the given modifiers.
   * @param modifiers the modifiers associated with this literal
   */
  void set modifier(Token modifier2) {
    this._modifier = modifier2;
  }

  /**
   * Set the type argument associated with this literal to the given arguments.
   * @param typeArguments the type argument associated with this literal
   */
  void set typeArguments(TypeArgumentList typeArguments2) {
    this._typeArguments = typeArguments2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_typeArguments, visitor);
  }
}
/**
 * The abstract class {@code UriBasedDirective} defines the behavior common to nodes that represent
 * a directive that references a URI.
 * <pre>
 * uriBasedDirective ::={@link ExportDirective exportDirective}| {@link ImportDirective importDirective}| {@link PartDirective partDirective}</pre>
 * @coverage dart.engine.ast
 */
abstract class UriBasedDirective extends Directive {

  /**
   * The URI referenced by this directive.
   */
  StringLiteral _uri;

  /**
   * Initialize a newly create URI-based directive.
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   * @param uri the URI referenced by this directive
   */
  UriBasedDirective.full(Comment comment, List<Annotation> metadata, StringLiteral uri) : super.full(comment, metadata) {
    this._uri = becomeParentOf(uri);
  }

  /**
   * Initialize a newly create URI-based directive.
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   * @param uri the URI referenced by this directive
   */
  UriBasedDirective({Comment comment, List<Annotation> metadata, StringLiteral uri}) : this.full(comment, metadata, uri);

  /**
   * Return the URI referenced by this directive.
   * @return the URI referenced by this directive
   */
  StringLiteral get uri => _uri;

  /**
   * Return the element associated with the URI of this directive, or {@code null} if the AST
   * structure has not been resolved or if this URI could not be resolved. Examples of the latter
   * case include a directive that contains an invalid URL or a URL that does not exist.
   * @return the element associated with this directive
   */
  Element get uriElement;

  /**
   * Set the URI referenced by this directive to the given URI.
   * @param uri the URI referenced by this directive
   */
  void set uri(StringLiteral uri2) {
    this._uri = becomeParentOf(uri2);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_uri, visitor);
  }
}
/**
 * Instances of the class {@code VariableDeclaration} represent an identifier that has an initial
 * value associated with it. Instances of this class are always children of the class{@link VariableDeclarationList}.
 * <pre>
 * variableDeclaration ::={@link SimpleIdentifier identifier} ('=' {@link Expression initialValue})?
 * </pre>
 * @coverage dart.engine.ast
 */
class VariableDeclaration extends Declaration {

  /**
   * The name of the variable being declared.
   */
  SimpleIdentifier _name;

  /**
   * The equal sign separating the variable name from the initial value, or {@code null} if the
   * initial value was not specified.
   */
  Token _equals;

  /**
   * The expression used to compute the initial value for the variable, or {@code null} if the
   * initial value was not specified.
   */
  Expression _initializer;

  /**
   * Initialize a newly created variable declaration.
   * @param comment the documentation comment associated with this declaration
   * @param metadata the annotations associated with this member
   * @param name the name of the variable being declared
   * @param equals the equal sign separating the variable name from the initial value
   * @param initializer the expression used to compute the initial value for the variable
   */
  VariableDeclaration.full(Comment comment, List<Annotation> metadata, SimpleIdentifier name, Token equals, Expression initializer) : super.full(comment, metadata) {
    this._name = becomeParentOf(name);
    this._equals = equals;
    this._initializer = becomeParentOf(initializer);
  }

  /**
   * Initialize a newly created variable declaration.
   * @param comment the documentation comment associated with this declaration
   * @param metadata the annotations associated with this member
   * @param name the name of the variable being declared
   * @param equals the equal sign separating the variable name from the initial value
   * @param initializer the expression used to compute the initial value for the variable
   */
  VariableDeclaration({Comment comment, List<Annotation> metadata, SimpleIdentifier name, Token equals, Expression initializer}) : this.full(comment, metadata, name, equals, initializer);
  accept(ASTVisitor visitor) => visitor.visitVariableDeclaration(this);

  /**
   * This overridden implementation of getDocumentationComment() looks in the grandparent node for
   * dartdoc comments if no documentation is specifically available on the node.
   */
  Comment get documentationComment {
    Comment comment = super.documentationComment;
    if (comment == null) {
      if (parent != null && parent.parent != null) {
        ASTNode node = parent.parent;
        if (node is AnnotatedNode) {
          return ((node as AnnotatedNode)).documentationComment;
        }
      }
    }
    return comment;
  }
  VariableElement get element => _name != null ? (_name.element as VariableElement) : null;
  Token get endToken {
    if (_initializer != null) {
      return _initializer.endToken;
    }
    return _name.endToken;
  }

  /**
   * Return the equal sign separating the variable name from the initial value, or {@code null} if
   * the initial value was not specified.
   * @return the equal sign separating the variable name from the initial value
   */
  Token get equals => _equals;

  /**
   * Return the expression used to compute the initial value for the variable, or {@code null} if
   * the initial value was not specified.
   * @return the expression used to compute the initial value for the variable
   */
  Expression get initializer => _initializer;

  /**
   * Return the name of the variable being declared.
   * @return the name of the variable being declared
   */
  SimpleIdentifier get name => _name;

  /**
   * Return {@code true} if this variable was declared with the 'const' modifier.
   * @return {@code true} if this variable was declared with the 'const' modifier
   */
  bool isConst() {
    ASTNode parent = this.parent;
    return parent is VariableDeclarationList && ((parent as VariableDeclarationList)).isConst();
  }

  /**
   * Return {@code true} if this variable was declared with the 'final' modifier. Variables that are
   * declared with the 'const' modifier will return {@code false} even though they are implicitly
   * final.
   * @return {@code true} if this variable was declared with the 'final' modifier
   */
  bool isFinal() {
    ASTNode parent = this.parent;
    return parent is VariableDeclarationList && ((parent as VariableDeclarationList)).isFinal();
  }

  /**
   * Set the equal sign separating the variable name from the initial value to the given token.
   * @param equals the equal sign separating the variable name from the initial value
   */
  void set equals(Token equals2) {
    this._equals = equals2;
  }

  /**
   * Set the expression used to compute the initial value for the variable to the given expression.
   * @param initializer the expression used to compute the initial value for the variable
   */
  void set initializer(Expression initializer2) {
    this._initializer = becomeParentOf(initializer2);
  }

  /**
   * Set the name of the variable being declared to the given identifier.
   * @param name the name of the variable being declared
   */
  void set name(SimpleIdentifier name2) {
    this._name = becomeParentOf(name2);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_name, visitor);
    safelyVisitChild(_initializer, visitor);
  }
  Token get firstTokenAfterCommentAndMetadata => _name.beginToken;
}
/**
 * Instances of the class {@code VariableDeclarationList} represent the declaration of one or more
 * variables of the same type.
 * <pre>
 * variableDeclarationList ::=
 * finalConstVarOrType {@link VariableDeclaration variableDeclaration} (',' {@link VariableDeclaration variableDeclaration})
 * finalConstVarOrType ::=
 * | 'final' {@link TypeName type}?
 * | 'const' {@link TypeName type}?
 * | 'var'
 * | {@link TypeName type}</pre>
 * @coverage dart.engine.ast
 */
class VariableDeclarationList extends AnnotatedNode {

  /**
   * The token representing the 'final', 'const' or 'var' keyword, or {@code null} if no keyword was
   * included.
   */
  Token _keyword;

  /**
   * The type of the variables being declared, or {@code null} if no type was provided.
   */
  TypeName _type;

  /**
   * A list containing the individual variables being declared.
   */
  NodeList<VariableDeclaration> _variables;

  /**
   * Initialize a newly created variable declaration list.
   * @param comment the documentation comment associated with this declaration list
   * @param metadata the annotations associated with this declaration list
   * @param keyword the token representing the 'final', 'const' or 'var' keyword
   * @param type the type of the variables being declared
   * @param variables a list containing the individual variables being declared
   */
  VariableDeclarationList.full(Comment comment, List<Annotation> metadata, Token keyword, TypeName type, List<VariableDeclaration> variables) : super.full(comment, metadata) {
    this._variables = new NodeList<VariableDeclaration>(this);
    this._keyword = keyword;
    this._type = becomeParentOf(type);
    this._variables.addAll(variables);
  }

  /**
   * Initialize a newly created variable declaration list.
   * @param comment the documentation comment associated with this declaration list
   * @param metadata the annotations associated with this declaration list
   * @param keyword the token representing the 'final', 'const' or 'var' keyword
   * @param type the type of the variables being declared
   * @param variables a list containing the individual variables being declared
   */
  VariableDeclarationList({Comment comment, List<Annotation> metadata, Token keyword, TypeName type, List<VariableDeclaration> variables}) : this.full(comment, metadata, keyword, type, variables);
  accept(ASTVisitor visitor) => visitor.visitVariableDeclarationList(this);
  Token get endToken => _variables.endToken;

  /**
   * Return the token representing the 'final', 'const' or 'var' keyword, or {@code null} if no
   * keyword was included.
   * @return the token representing the 'final', 'const' or 'var' keyword
   */
  Token get keyword => _keyword;

  /**
   * Return the type of the variables being declared, or {@code null} if no type was provided.
   * @return the type of the variables being declared
   */
  TypeName get type => _type;

  /**
   * Return a list containing the individual variables being declared.
   * @return a list containing the individual variables being declared
   */
  NodeList<VariableDeclaration> get variables => _variables;

  /**
   * Return {@code true} if the variables in this list were declared with the 'const' modifier.
   * @return {@code true} if the variables in this list were declared with the 'const' modifier
   */
  bool isConst() => _keyword is KeywordToken && identical(((_keyword as KeywordToken)).keyword, Keyword.CONST);

  /**
   * Return {@code true} if the variables in this list were declared with the 'final' modifier.
   * Variables that are declared with the 'const' modifier will return {@code false} even though
   * they are implicitly final.
   * @return {@code true} if the variables in this list were declared with the 'final' modifier
   */
  bool isFinal() => _keyword is KeywordToken && identical(((_keyword as KeywordToken)).keyword, Keyword.FINAL);

  /**
   * Set the token representing the 'final', 'const' or 'var' keyword to the given token.
   * @param keyword the token representing the 'final', 'const' or 'var' keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }

  /**
   * Set the type of the variables being declared to the given type name.
   * @param typeName the type of the variables being declared
   */
  void set type(TypeName typeName) {
    _type = becomeParentOf(typeName);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_type, visitor);
    _variables.accept(visitor);
  }
  Token get firstTokenAfterCommentAndMetadata {
    if (_keyword != null) {
      return _keyword;
    } else if (_type != null) {
      return _type.beginToken;
    }
    return _variables.beginToken;
  }
}
/**
 * Instances of the class {@code VariableDeclarationStatement} represent a list of variables that
 * are being declared in a context where a statement is required.
 * <pre>
 * variableDeclarationStatement ::={@link VariableDeclarationList variableList} ';'
 * </pre>
 * @coverage dart.engine.ast
 */
class VariableDeclarationStatement extends Statement {

  /**
   * The variables being declared.
   */
  VariableDeclarationList _variableList;

  /**
   * The semicolon terminating the statement.
   */
  Token _semicolon;

  /**
   * Initialize a newly created variable declaration statement.
   * @param variableList the fields being declared
   * @param semicolon the semicolon terminating the statement
   */
  VariableDeclarationStatement.full(VariableDeclarationList variableList, Token semicolon) {
    this._variableList = becomeParentOf(variableList);
    this._semicolon = semicolon;
  }

  /**
   * Initialize a newly created variable declaration statement.
   * @param variableList the fields being declared
   * @param semicolon the semicolon terminating the statement
   */
  VariableDeclarationStatement({VariableDeclarationList variableList, Token semicolon}) : this.full(variableList, semicolon);
  accept(ASTVisitor visitor) => visitor.visitVariableDeclarationStatement(this);
  Token get beginToken => _variableList.beginToken;
  Token get endToken => _semicolon;

  /**
   * Return the semicolon terminating the statement.
   * @return the semicolon terminating the statement
   */
  Token get semicolon => _semicolon;

  /**
   * Return the variables being declared.
   * @return the variables being declared
   */
  VariableDeclarationList get variables => _variableList;

  /**
   * Set the semicolon terminating the statement to the given token.
   * @param semicolon the semicolon terminating the statement
   */
  void set semicolon(Token semicolon2) {
    this._semicolon = semicolon2;
  }

  /**
   * Set the variables being declared to the given list of variables.
   * @param variableList the variables being declared
   */
  void set variables(VariableDeclarationList variableList2) {
    this._variableList = becomeParentOf(variableList2);
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_variableList, visitor);
  }
}
/**
 * Instances of the class {@code WhileStatement} represent a while statement.
 * <pre>
 * whileStatement ::=
 * 'while' '(' {@link Expression condition} ')' {@link Statement body}</pre>
 * @coverage dart.engine.ast
 */
class WhileStatement extends Statement {

  /**
   * The token representing the 'while' keyword.
   */
  Token _keyword;

  /**
   * The left parenthesis.
   */
  Token _leftParenthesis;

  /**
   * The expression used to determine whether to execute the body of the loop.
   */
  Expression _condition;

  /**
   * The right parenthesis.
   */
  Token _rightParenthesis;

  /**
   * The body of the loop.
   */
  Statement _body;

  /**
   * Initialize a newly created while statement.
   * @param keyword the token representing the 'while' keyword
   * @param leftParenthesis the left parenthesis
   * @param condition the expression used to determine whether to execute the body of the loop
   * @param rightParenthesis the right parenthesis
   * @param body the body of the loop
   */
  WhileStatement.full(Token keyword, Token leftParenthesis, Expression condition, Token rightParenthesis, Statement body) {
    this._keyword = keyword;
    this._leftParenthesis = leftParenthesis;
    this._condition = becomeParentOf(condition);
    this._rightParenthesis = rightParenthesis;
    this._body = becomeParentOf(body);
  }

  /**
   * Initialize a newly created while statement.
   * @param keyword the token representing the 'while' keyword
   * @param leftParenthesis the left parenthesis
   * @param condition the expression used to determine whether to execute the body of the loop
   * @param rightParenthesis the right parenthesis
   * @param body the body of the loop
   */
  WhileStatement({Token keyword, Token leftParenthesis, Expression condition, Token rightParenthesis, Statement body}) : this.full(keyword, leftParenthesis, condition, rightParenthesis, body);
  accept(ASTVisitor visitor) => visitor.visitWhileStatement(this);
  Token get beginToken => _keyword;

  /**
   * Return the body of the loop.
   * @return the body of the loop
   */
  Statement get body => _body;

  /**
   * Return the expression used to determine whether to execute the body of the loop.
   * @return the expression used to determine whether to execute the body of the loop
   */
  Expression get condition => _condition;
  Token get endToken => _body.endToken;

  /**
   * Return the token representing the 'while' keyword.
   * @return the token representing the 'while' keyword
   */
  Token get keyword => _keyword;

  /**
   * Return the left parenthesis.
   * @return the left parenthesis
   */
  Token get leftParenthesis => _leftParenthesis;

  /**
   * Return the right parenthesis.
   * @return the right parenthesis
   */
  Token get rightParenthesis => _rightParenthesis;

  /**
   * Set the body of the loop to the given statement.
   * @param statement the body of the loop
   */
  void set body(Statement statement) {
    _body = becomeParentOf(statement);
  }

  /**
   * Set the expression used to determine whether to execute the body of the loop to the given
   * expression.
   * @param expression the expression used to determine whether to execute the body of the loop
   */
  void set condition(Expression expression) {
    _condition = becomeParentOf(expression);
  }

  /**
   * Set the token representing the 'while' keyword to the given token.
   * @param keyword the token representing the 'while' keyword
   */
  void set keyword(Token keyword2) {
    this._keyword = keyword2;
  }

  /**
   * Set the left parenthesis to the given token.
   * @param leftParenthesis the left parenthesis
   */
  void set leftParenthesis(Token leftParenthesis2) {
    this._leftParenthesis = leftParenthesis2;
  }

  /**
   * Set the right parenthesis to the given token.
   * @param rightParenthesis the right parenthesis
   */
  void set rightParenthesis(Token rightParenthesis2) {
    this._rightParenthesis = rightParenthesis2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    safelyVisitChild(_condition, visitor);
    safelyVisitChild(_body, visitor);
  }
}
/**
 * Instances of the class {@code WithClause} represent the with clause in a class declaration.
 * <pre>
 * withClause ::=
 * 'with' {@link TypeName mixin} (',' {@link TypeName mixin})
 * </pre>
 * @coverage dart.engine.ast
 */
class WithClause extends ASTNode {

  /**
   * The token representing the 'with' keyword.
   */
  Token _withKeyword;

  /**
   * The names of the mixins that were specified.
   */
  NodeList<TypeName> _mixinTypes;

  /**
   * Initialize a newly created with clause.
   * @param withKeyword the token representing the 'with' keyword
   * @param mixinTypes the names of the mixins that were specified
   */
  WithClause.full(Token withKeyword, List<TypeName> mixinTypes) {
    this._mixinTypes = new NodeList<TypeName>(this);
    this._withKeyword = withKeyword;
    this._mixinTypes.addAll(mixinTypes);
  }

  /**
   * Initialize a newly created with clause.
   * @param withKeyword the token representing the 'with' keyword
   * @param mixinTypes the names of the mixins that were specified
   */
  WithClause({Token withKeyword, List<TypeName> mixinTypes}) : this.full(withKeyword, mixinTypes);
  accept(ASTVisitor visitor) => visitor.visitWithClause(this);
  Token get beginToken => _withKeyword;
  Token get endToken => _mixinTypes.endToken;

  /**
   * Return the names of the mixins that were specified.
   * @return the names of the mixins that were specified
   */
  NodeList<TypeName> get mixinTypes => _mixinTypes;

  /**
   * Return the token representing the 'with' keyword.
   * @return the token representing the 'with' keyword
   */
  Token get withKeyword => _withKeyword;

  /**
   * Set the token representing the 'with' keyword to the given token.
   * @param withKeyword the token representing the 'with' keyword
   */
  void set mixinKeyword(Token withKeyword2) {
    this._withKeyword = withKeyword2;
  }
  void visitChildren(ASTVisitor<Object> visitor) {
    _mixinTypes.accept(visitor);
  }
}
/**
 * Instances of the class {@code BreadthFirstVisitor} implement an AST visitor that will recursively
 * visit all of the nodes in an AST structure, similar to {@link GeneralizingASTVisitor}. This
 * visitor uses a breadth-first ordering rather than the depth-first ordering of{@link GeneralizingASTVisitor}.
 * @coverage dart.engine.ast
 */
class BreadthFirstVisitor<R> extends GeneralizingASTVisitor<R> {
  Queue<ASTNode> _queue = new Queue<ASTNode>();
  GeneralizingASTVisitor<Object> _childVisitor;

  /**
   * Visit all nodes in the tree starting at the given {@code root} node, in depth-first order.
   * @param root the root of the ASTNode tree
   */
  void visitAllNodes(ASTNode root) {
    _queue.add(root);
    while (!_queue.isEmpty) {
      ASTNode next = _queue.removeFirst();
      next.accept(this);
    }
  }
  R visitNode(ASTNode node) {
    node.visitChildren(_childVisitor);
    return null;
  }
  BreadthFirstVisitor() {
    this._childVisitor = new GeneralizingASTVisitor_1(this);
  }
}
class GeneralizingASTVisitor_1 extends GeneralizingASTVisitor<Object> {
  final BreadthFirstVisitor BreadthFirstVisitor_this;
  GeneralizingASTVisitor_1(this.BreadthFirstVisitor_this) : super();
  Object visitNode(ASTNode node) {
    BreadthFirstVisitor_this._queue.add(node);
    return null;
  }
}
/**
 * Instances of the class {@code ConstantEvaluator} evaluate constant expressions to produce their
 * compile-time value. According to the Dart Language Specification: <blockquote> A constant
 * expression is one of the following:
 * <ul>
 * <li>A literal number.</li>
 * <li>A literal boolean.</li>
 * <li>A literal string where any interpolated expression is a compile-time constant that evaluates
 * to a numeric, string or boolean value or to {@code null}.</li>
 * <li>{@code null}.</li>
 * <li>A reference to a static constant variable.</li>
 * <li>An identifier expression that denotes a constant variable, a class or a type variable.</li>
 * <li>A constant constructor invocation.</li>
 * <li>A constant list literal.</li>
 * <li>A constant map literal.</li>
 * <li>A simple or qualified identifier denoting a top-level function or a static method.</li>
 * <li>A parenthesized expression {@code (e)} where {@code e} is a constant expression.</li>
 * <li>An expression of one of the forms {@code identical(e1, e2)}, {@code e1 == e2},{@code e1 != e2} where {@code e1} and {@code e2} are constant expressions that evaluate to a
 * numeric, string or boolean value or to {@code null}.</li>
 * <li>An expression of one of the forms {@code !e}, {@code e1 && e2} or {@code e1 || e2}, where{@code e}, {@code e1} and {@code e2} are constant expressions that evaluate to a boolean value or
 * to {@code null}.</li>
 * <li>An expression of one of the forms {@code ~e}, {@code e1 ^ e2}, {@code e1 & e2},{@code e1 | e2}, {@code e1 >> e2} or {@code e1 << e2}, where {@code e}, {@code e1} and {@code e2}are constant expressions that evaluate to an integer value or to {@code null}.</li>
 * <li>An expression of one of the forms {@code -e}, {@code e1 + e2}, {@code e1 - e2},{@code e1 * e2}, {@code e1 / e2}, {@code e1 ~/ e2}, {@code e1 > e2}, {@code e1 < e2},{@code e1 >= e2}, {@code e1 <= e2} or {@code e1 % e2}, where {@code e}, {@code e1} and {@code e2}are constant expressions that evaluate to a numeric value or to {@code null}.</li>
 * </ul>
 * </blockquote> The values returned by instances of this class are therefore {@code null} and
 * instances of the classes {@code Boolean}, {@code BigInteger}, {@code Double}, {@code String}, and{@code DartObject}.
 * <p>
 * In addition, this class defines several values that can be returned to indicate various
 * conditions encountered during evaluation. These are documented with the static field that define
 * those values.
 * @coverage dart.engine.ast
 */
class ConstantEvaluator extends GeneralizingASTVisitor<Object> {

  /**
   * The value returned for expressions (or non-expression nodes) that are not compile-time constant
   * expressions.
   */
  static Object NOT_A_CONSTANT = new Object();
  Object visitAdjacentStrings(AdjacentStrings node) {
    JavaStringBuilder builder = new JavaStringBuilder();
    for (StringLiteral string in node.strings) {
      Object value = string.accept(this);
      if (identical(value, NOT_A_CONSTANT)) {
        return value;
      }
      builder.append(value);
    }
    return builder.toString();
  }
  Object visitBinaryExpression(BinaryExpression node) {
    Object leftOperand = node.leftOperand.accept(this);
    if (identical(leftOperand, NOT_A_CONSTANT)) {
      return leftOperand;
    }
    Object rightOperand = node.rightOperand.accept(this);
    if (identical(rightOperand, NOT_A_CONSTANT)) {
      return rightOperand;
    }
    while (true) {
      if (node.operator.type == TokenType.AMPERSAND) {
        if (leftOperand is int && rightOperand is int) {
          return ((leftOperand as int)) & (rightOperand as int);
        }
      } else if (node.operator.type == TokenType.AMPERSAND_AMPERSAND) {
        if (leftOperand is bool && rightOperand is bool) {
          return ((leftOperand as bool)) && ((rightOperand as bool));
        }
      } else if (node.operator.type == TokenType.BANG_EQ) {
        if (leftOperand is bool && rightOperand is bool) {
          return ((leftOperand as bool)) != ((rightOperand as bool));
        } else if (leftOperand is int && rightOperand is int) {
          return ((leftOperand as int)) != rightOperand;
        } else if (leftOperand is double && rightOperand is double) {
          return ((leftOperand as double)) != rightOperand;
        } else if (leftOperand is String && rightOperand is String) {
          return ((leftOperand as String)) != rightOperand;
        }
      } else if (node.operator.type == TokenType.BAR) {
        if (leftOperand is int && rightOperand is int) {
          return ((leftOperand as int)) | (rightOperand as int);
        }
      } else if (node.operator.type == TokenType.BAR_BAR) {
        if (leftOperand is bool && rightOperand is bool) {
          return ((leftOperand as bool)) || ((rightOperand as bool));
        }
      } else if (node.operator.type == TokenType.CARET) {
        if (leftOperand is int && rightOperand is int) {
          return ((leftOperand as int)) ^ (rightOperand as int);
        }
      } else if (node.operator.type == TokenType.EQ_EQ) {
        if (leftOperand is bool && rightOperand is bool) {
          return identical(((leftOperand as bool)), ((rightOperand as bool)));
        } else if (leftOperand is int && rightOperand is int) {
          return ((leftOperand as int)) == rightOperand;
        } else if (leftOperand is double && rightOperand is double) {
          return ((leftOperand as double)) == rightOperand;
        } else if (leftOperand is String && rightOperand is String) {
          return ((leftOperand as String)) == rightOperand;
        }
      } else if (node.operator.type == TokenType.GT) {
        if (leftOperand is int && rightOperand is int) {
          return ((leftOperand as int)).compareTo((rightOperand as int)) > 0;
        } else if (leftOperand is double && rightOperand is double) {
          return ((leftOperand as double)).compareTo((rightOperand as double)) > 0;
        }
      } else if (node.operator.type == TokenType.GT_EQ) {
        if (leftOperand is int && rightOperand is int) {
          return ((leftOperand as int)).compareTo((rightOperand as int)) >= 0;
        } else if (leftOperand is double && rightOperand is double) {
          return ((leftOperand as double)).compareTo((rightOperand as double)) >= 0;
        }
      } else if (node.operator.type == TokenType.GT_GT) {
        if (leftOperand is int && rightOperand is int) {
          return ((leftOperand as int)) >> ((rightOperand as int));
        }
      } else if (node.operator.type == TokenType.LT) {
        if (leftOperand is int && rightOperand is int) {
          return ((leftOperand as int)).compareTo((rightOperand as int)) < 0;
        } else if (leftOperand is double && rightOperand is double) {
          return ((leftOperand as double)).compareTo((rightOperand as double)) < 0;
        }
      } else if (node.operator.type == TokenType.LT_EQ) {
        if (leftOperand is int && rightOperand is int) {
          return ((leftOperand as int)).compareTo((rightOperand as int)) <= 0;
        } else if (leftOperand is double && rightOperand is double) {
          return ((leftOperand as double)).compareTo((rightOperand as double)) <= 0;
        }
      } else if (node.operator.type == TokenType.LT_LT) {
        if (leftOperand is int && rightOperand is int) {
          return ((leftOperand as int)) << ((rightOperand as int));
        }
      } else if (node.operator.type == TokenType.MINUS) {
        if (leftOperand is int && rightOperand is int) {
          return ((leftOperand as int)) - (rightOperand as int);
        } else if (leftOperand is double && rightOperand is double) {
          return ((leftOperand as double)) - ((rightOperand as double));
        }
      } else if (node.operator.type == TokenType.PERCENT) {
        if (leftOperand is int && rightOperand is int) {
          return ((leftOperand as int)).remainder((rightOperand as int));
        } else if (leftOperand is double && rightOperand is double) {
          return ((leftOperand as double)) % ((rightOperand as double));
        }
      } else if (node.operator.type == TokenType.PLUS) {
        if (leftOperand is int && rightOperand is int) {
          return ((leftOperand as int)) + (rightOperand as int);
        } else if (leftOperand is double && rightOperand is double) {
          return ((leftOperand as double)) + ((rightOperand as double));
        }
      } else if (node.operator.type == TokenType.STAR) {
        if (leftOperand is int && rightOperand is int) {
          return ((leftOperand as int)) * (rightOperand as int);
        } else if (leftOperand is double && rightOperand is double) {
          return ((leftOperand as double)) * ((rightOperand as double));
        }
      } else if (node.operator.type == TokenType.SLASH) {
        if (leftOperand is int && rightOperand is int) {
          if (rightOperand != 0) {
            return ((leftOperand as int)) ~/ (rightOperand as int);
          } else {
            return ((leftOperand as int)).toDouble() / ((rightOperand as int)).toDouble();
          }
        } else if (leftOperand is double && rightOperand is double) {
          return ((leftOperand as double)) / ((rightOperand as double));
        }
      } else if (node.operator.type == TokenType.TILDE_SLASH) {
        if (leftOperand is int && rightOperand is int) {
          if (rightOperand != 0) {
            return ((leftOperand as int)) ~/ (rightOperand as int);
          } else {
            return 0;
          }
        } else if (leftOperand is double && rightOperand is double) {
          return ((leftOperand as double)) ~/ ((rightOperand as double));
        }
      }
      break;
    }
    return visitExpression(node);
  }
  Object visitBooleanLiteral(BooleanLiteral node) => node.value ? true : false;
  Object visitDoubleLiteral(DoubleLiteral node) => node.value;
  Object visitIntegerLiteral(IntegerLiteral node) => node.value;
  Object visitInterpolationExpression(InterpolationExpression node) {
    Object value = node.expression.accept(this);
    if (value == null || value is bool || value is String || value is int || value is double) {
      return value;
    }
    return NOT_A_CONSTANT;
  }
  Object visitInterpolationString(InterpolationString node) => node.value;
  Object visitListLiteral(ListLiteral node) {
    List<Object> list = new List<Object>();
    for (Expression element in node.elements) {
      Object value = element.accept(this);
      if (identical(value, NOT_A_CONSTANT)) {
        return value;
      }
      list.add(value);
    }
    return list;
  }
  Object visitMapLiteral(MapLiteral node) {
    Map<String, Object> map = new Map<String, Object>();
    for (MapLiteralEntry entry in node.entries) {
      Object key = entry.key.accept(this);
      Object value = entry.value.accept(this);
      if (key is! String || identical(value, NOT_A_CONSTANT)) {
        return NOT_A_CONSTANT;
      }
      map[(key as String)] = value;
    }
    return map;
  }
  Object visitMethodInvocation(MethodInvocation node) => visitNode(node);
  Object visitNode(ASTNode node) => NOT_A_CONSTANT;
  Object visitNullLiteral(NullLiteral node) => null;
  Object visitParenthesizedExpression(ParenthesizedExpression node) => node.expression.accept(this);
  Object visitPrefixedIdentifier(PrefixedIdentifier node) => getConstantValue(null);
  Object visitPrefixExpression(PrefixExpression node) {
    Object operand = node.operand.accept(this);
    if (identical(operand, NOT_A_CONSTANT)) {
      return operand;
    }
    while (true) {
      if (node.operator.type == TokenType.BANG) {
        if (identical(operand, true)) {
          return false;
        } else if (identical(operand, false)) {
          return true;
        }
      } else if (node.operator.type == TokenType.TILDE) {
        if (operand is int) {
          return ~((operand as int));
        }
      } else if (node.operator.type == TokenType.MINUS) {
        if (operand == null) {
          return null;
        } else if (operand is int) {
          return -((operand as int));
        } else if (operand is double) {
          return -((operand as double));
        }
      }
      break;
    }
    return NOT_A_CONSTANT;
  }
  Object visitPropertyAccess(PropertyAccess node) => getConstantValue(null);
  Object visitSimpleIdentifier(SimpleIdentifier node) => getConstantValue(null);
  Object visitSimpleStringLiteral(SimpleStringLiteral node) => node.value;
  Object visitStringInterpolation(StringInterpolation node) {
    JavaStringBuilder builder = new JavaStringBuilder();
    for (InterpolationElement element in node.elements) {
      Object value = element.accept(this);
      if (identical(value, NOT_A_CONSTANT)) {
        return value;
      }
      builder.append(value);
    }
    return builder.toString();
  }

  /**
   * Return the constant value of the static constant represented by the given element.
   * @param element the element whose value is to be returned
   * @return the constant value of the static constant
   */
  Object getConstantValue(Element element) {
    if (element is FieldElement) {
      FieldElement field = element as FieldElement;
      if (field.isStatic() && field.isConst()) {
      }
    }
    return NOT_A_CONSTANT;
  }
}
/**
 * Instances of the class {@code ElementLocator} locate the {@link Element Dart model element}associated with a given {@link ASTNode AST node}.
 * @coverage dart.engine.ast
 */
class ElementLocator {

  /**
   * Locate the {@link Element Dart model element} associated with the given {@link ASTNode AST
   * node}.
   * @param node the node (not {@code null})
   * @return the associated element, or {@code null} if none is found
   */
  static Element locate(ASTNode node) {
    ElementLocator_ElementMapper mapper = new ElementLocator_ElementMapper();
    return node.accept(mapper);
  }
}
/**
 * Visitor that maps nodes to elements.
 */
class ElementLocator_ElementMapper extends GeneralizingASTVisitor<Element> {
  Element visitBinaryExpression(BinaryExpression node) => node.element;
  Element visitClassDeclaration(ClassDeclaration node) => node.element;
  Element visitCompilationUnit(CompilationUnit node) => node.element;
  Element visitConstructorDeclaration(ConstructorDeclaration node) => node.element;
  Element visitFunctionDeclaration(FunctionDeclaration node) => node.element;
  Element visitIdentifier(Identifier node) {
    ASTNode parent = node.parent;
    if (parent is ConstructorDeclaration) {
      ConstructorDeclaration decl = parent as ConstructorDeclaration;
      Identifier returnType = decl.returnType;
      if (identical(returnType, node)) {
        SimpleIdentifier name = decl.name;
        if (name != null) {
          return name.element;
        }
        Element element = node.element;
        if (element is ClassElement) {
          return ((element as ClassElement)).unnamedConstructor;
        }
      }
    }
    if (parent is LibraryIdentifier) {
      ASTNode grandParent = ((parent as LibraryIdentifier)).parent;
      if (grandParent is PartOfDirective) {
        Element element = ((grandParent as PartOfDirective)).element;
        if (element is LibraryElement) {
          return ((element as LibraryElement)).definingCompilationUnit;
        }
      }
    }
    return node.element;
  }
  Element visitImportDirective(ImportDirective node) => node.element;
  Element visitIndexExpression(IndexExpression node) => node.element;
  Element visitInstanceCreationExpression(InstanceCreationExpression node) => node.element;
  Element visitLibraryDirective(LibraryDirective node) => node.element;
  Element visitMethodDeclaration(MethodDeclaration node) => node.element;
  Element visitMethodInvocation(MethodInvocation node) => node.methodName.element;
  Element visitPostfixExpression(PostfixExpression node) => node.element;
  Element visitPrefixedIdentifier(PrefixedIdentifier node) => node.element;
  Element visitPrefixExpression(PrefixExpression node) => node.element;
  Element visitStringLiteral(StringLiteral node) {
    ASTNode parent = node.parent;
    if (parent is UriBasedDirective) {
      return ((parent as UriBasedDirective)).uriElement;
    }
    return null;
  }
  Element visitVariableDeclaration(VariableDeclaration node) => node.element;
}
/**
 * Instances of the class {@code GeneralizingASTVisitor} implement an AST visitor that will
 * recursively visit all of the nodes in an AST structure (like instances of the class{@link RecursiveASTVisitor}). In addition, when a node of a specific type is visited not only
 * will the visit method for that specific type of node be invoked, but additional methods for the
 * superclasses of that node will also be invoked. For example, using an instance of this class to
 * visit a {@link Block} will cause the method {@link #visitBlock(Block)} to be invoked but will
 * also cause the methods {@link #visitStatement(Statement)} and {@link #visitNode(ASTNode)} to be
 * subsequently invoked. This allows visitors to be written that visit all statements without
 * needing to override the visit method for each of the specific subclasses of {@link Statement}.
 * <p>
 * Subclasses that override a visit method must either invoke the overridden visit method or
 * explicitly invoke the more general visit method. Failure to do so will cause the visit methods
 * for superclasses of the node to not be invoked and will cause the children of the visited node to
 * not be visited.
 * @coverage dart.engine.ast
 */
class GeneralizingASTVisitor<R> implements ASTVisitor<R> {
  R visitAdjacentStrings(AdjacentStrings node) => visitStringLiteral(node);
  R visitAnnotatedNode(AnnotatedNode node) => visitNode(node);
  R visitAnnotation(Annotation node) => visitNode(node);
  R visitArgumentDefinitionTest(ArgumentDefinitionTest node) => visitExpression(node);
  R visitArgumentList(ArgumentList node) => visitNode(node);
  R visitAsExpression(AsExpression node) => visitExpression(node);
  R visitAssertStatement(AssertStatement node) => visitStatement(node);
  R visitAssignmentExpression(AssignmentExpression node) => visitExpression(node);
  R visitBinaryExpression(BinaryExpression node) => visitExpression(node);
  R visitBlock(Block node) => visitStatement(node);
  R visitBlockFunctionBody(BlockFunctionBody node) => visitFunctionBody(node);
  R visitBooleanLiteral(BooleanLiteral node) => visitLiteral(node);
  R visitBreakStatement(BreakStatement node) => visitStatement(node);
  R visitCascadeExpression(CascadeExpression node) => visitExpression(node);
  R visitCatchClause(CatchClause node) => visitNode(node);
  R visitClassDeclaration(ClassDeclaration node) => visitCompilationUnitMember(node);
  R visitClassMember(ClassMember node) => visitDeclaration(node);
  R visitClassTypeAlias(ClassTypeAlias node) => visitTypeAlias(node);
  R visitCombinator(Combinator node) => visitNode(node);
  R visitComment(Comment node) => visitNode(node);
  R visitCommentReference(CommentReference node) => visitNode(node);
  R visitCompilationUnit(CompilationUnit node) => visitNode(node);
  R visitCompilationUnitMember(CompilationUnitMember node) => visitDeclaration(node);
  R visitConditionalExpression(ConditionalExpression node) => visitExpression(node);
  R visitConstructorDeclaration(ConstructorDeclaration node) => visitClassMember(node);
  R visitConstructorFieldInitializer(ConstructorFieldInitializer node) => visitConstructorInitializer(node);
  R visitConstructorInitializer(ConstructorInitializer node) => visitNode(node);
  R visitConstructorName(ConstructorName node) => visitNode(node);
  R visitContinueStatement(ContinueStatement node) => visitStatement(node);
  R visitDeclaration(Declaration node) => visitAnnotatedNode(node);
  R visitDeclaredIdentifier(DeclaredIdentifier node) => visitDeclaration(node);
  R visitDefaultFormalParameter(DefaultFormalParameter node) => visitFormalParameter(node);
  R visitDirective(Directive node) => visitAnnotatedNode(node);
  R visitDoStatement(DoStatement node) => visitStatement(node);
  R visitDoubleLiteral(DoubleLiteral node) => visitLiteral(node);
  R visitEmptyFunctionBody(EmptyFunctionBody node) => visitFunctionBody(node);
  R visitEmptyStatement(EmptyStatement node) => visitStatement(node);
  R visitExportDirective(ExportDirective node) => visitNamespaceDirective(node);
  R visitExpression(Expression node) => visitNode(node);
  R visitExpressionFunctionBody(ExpressionFunctionBody node) => visitFunctionBody(node);
  R visitExpressionStatement(ExpressionStatement node) => visitStatement(node);
  R visitExtendsClause(ExtendsClause node) => visitNode(node);
  R visitFieldDeclaration(FieldDeclaration node) => visitClassMember(node);
  R visitFieldFormalParameter(FieldFormalParameter node) => visitNormalFormalParameter(node);
  R visitForEachStatement(ForEachStatement node) => visitStatement(node);
  R visitFormalParameter(FormalParameter node) => visitNode(node);
  R visitFormalParameterList(FormalParameterList node) => visitNode(node);
  R visitForStatement(ForStatement node) => visitStatement(node);
  R visitFunctionBody(FunctionBody node) => visitNode(node);
  R visitFunctionDeclaration(FunctionDeclaration node) => visitCompilationUnitMember(node);
  R visitFunctionDeclarationStatement(FunctionDeclarationStatement node) => visitStatement(node);
  R visitFunctionExpression(FunctionExpression node) => visitExpression(node);
  R visitFunctionExpressionInvocation(FunctionExpressionInvocation node) => visitExpression(node);
  R visitFunctionTypeAlias(FunctionTypeAlias node) => visitTypeAlias(node);
  R visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) => visitNormalFormalParameter(node);
  R visitHideCombinator(HideCombinator node) => visitCombinator(node);
  R visitIdentifier(Identifier node) => visitExpression(node);
  R visitIfStatement(IfStatement node) => visitStatement(node);
  R visitImplementsClause(ImplementsClause node) => visitNode(node);
  R visitImportDirective(ImportDirective node) => visitNamespaceDirective(node);
  R visitIndexExpression(IndexExpression node) => visitExpression(node);
  R visitInstanceCreationExpression(InstanceCreationExpression node) => visitExpression(node);
  R visitIntegerLiteral(IntegerLiteral node) => visitLiteral(node);
  R visitInterpolationElement(InterpolationElement node) => visitNode(node);
  R visitInterpolationExpression(InterpolationExpression node) => visitInterpolationElement(node);
  R visitInterpolationString(InterpolationString node) => visitInterpolationElement(node);
  R visitIsExpression(IsExpression node) => visitExpression(node);
  R visitLabel(Label node) => visitNode(node);
  R visitLabeledStatement(LabeledStatement node) => visitStatement(node);
  R visitLibraryDirective(LibraryDirective node) => visitDirective(node);
  R visitLibraryIdentifier(LibraryIdentifier node) => visitIdentifier(node);
  R visitListLiteral(ListLiteral node) => visitTypedLiteral(node);
  R visitLiteral(Literal node) => visitExpression(node);
  R visitMapLiteral(MapLiteral node) => visitTypedLiteral(node);
  R visitMapLiteralEntry(MapLiteralEntry node) => visitNode(node);
  R visitMethodDeclaration(MethodDeclaration node) => visitClassMember(node);
  R visitMethodInvocation(MethodInvocation node) => visitExpression(node);
  R visitNamedExpression(NamedExpression node) => visitExpression(node);
  R visitNamespaceDirective(NamespaceDirective node) => visitUriBasedDirective(node);
  R visitNativeFunctionBody(NativeFunctionBody node) => visitFunctionBody(node);
  R visitNode(ASTNode node) {
    node.visitChildren(this);
    return null;
  }
  R visitNormalFormalParameter(NormalFormalParameter node) => visitFormalParameter(node);
  R visitNullLiteral(NullLiteral node) => visitLiteral(node);
  R visitParenthesizedExpression(ParenthesizedExpression node) => visitExpression(node);
  R visitPartDirective(PartDirective node) => visitUriBasedDirective(node);
  R visitPartOfDirective(PartOfDirective node) => visitDirective(node);
  R visitPostfixExpression(PostfixExpression node) => visitExpression(node);
  R visitPrefixedIdentifier(PrefixedIdentifier node) => visitIdentifier(node);
  R visitPrefixExpression(PrefixExpression node) => visitExpression(node);
  R visitPropertyAccess(PropertyAccess node) => visitExpression(node);
  R visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) => visitConstructorInitializer(node);
  R visitRethrowExpression(RethrowExpression node) => visitExpression(node);
  R visitReturnStatement(ReturnStatement node) => visitStatement(node);
  R visitScriptTag(ScriptTag scriptTag) => visitNode(scriptTag);
  R visitShowCombinator(ShowCombinator node) => visitCombinator(node);
  R visitSimpleFormalParameter(SimpleFormalParameter node) => visitNormalFormalParameter(node);
  R visitSimpleIdentifier(SimpleIdentifier node) => visitIdentifier(node);
  R visitSimpleStringLiteral(SimpleStringLiteral node) => visitStringLiteral(node);
  R visitStatement(Statement node) => visitNode(node);
  R visitStringInterpolation(StringInterpolation node) => visitStringLiteral(node);
  R visitStringLiteral(StringLiteral node) => visitLiteral(node);
  R visitSuperConstructorInvocation(SuperConstructorInvocation node) => visitConstructorInitializer(node);
  R visitSuperExpression(SuperExpression node) => visitExpression(node);
  R visitSwitchCase(SwitchCase node) => visitSwitchMember(node);
  R visitSwitchDefault(SwitchDefault node) => visitSwitchMember(node);
  R visitSwitchMember(SwitchMember node) => visitNode(node);
  R visitSwitchStatement(SwitchStatement node) => visitStatement(node);
  R visitThisExpression(ThisExpression node) => visitExpression(node);
  R visitThrowExpression(ThrowExpression node) => visitExpression(node);
  R visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) => visitCompilationUnitMember(node);
  R visitTryStatement(TryStatement node) => visitStatement(node);
  R visitTypeAlias(TypeAlias node) => visitCompilationUnitMember(node);
  R visitTypeArgumentList(TypeArgumentList node) => visitNode(node);
  R visitTypedLiteral(TypedLiteral node) => visitLiteral(node);
  R visitTypeName(TypeName node) => visitNode(node);
  R visitTypeParameter(TypeParameter node) => visitNode(node);
  R visitTypeParameterList(TypeParameterList node) => visitNode(node);
  R visitUriBasedDirective(UriBasedDirective node) => visitDirective(node);
  R visitVariableDeclaration(VariableDeclaration node) => visitDeclaration(node);
  R visitVariableDeclarationList(VariableDeclarationList node) => visitNode(node);
  R visitVariableDeclarationStatement(VariableDeclarationStatement node) => visitStatement(node);
  R visitWhileStatement(WhileStatement node) => visitStatement(node);
  R visitWithClause(WithClause node) => visitNode(node);
}
/**
 * Instances of the class {@code NodeLocator} locate the {@link ASTNode AST node} associated with a
 * source range, given the AST structure built from the source. More specifically, they will return
 * the {@link ASTNode AST node} with the shortest length whose source range completely encompasses
 * the specified range.
 * @coverage dart.engine.ast
 */
class NodeLocator extends GeneralizingASTVisitor<Object> {

  /**
   * The start offset of the range used to identify the node.
   */
  int _startOffset = 0;

  /**
   * The end offset of the range used to identify the node.
   */
  int _endOffset = 0;

  /**
   * The element that was found that corresponds to the given source range, or {@code null} if there
   * is no such element.
   */
  ASTNode _foundNode;

  /**
   * Initialize a newly created locator to locate one or more {@link ASTNode AST nodes} by locating
   * the node within an AST structure that corresponds to the given offset in the source.
   * @param offset the offset used to identify the node
   */
  NodeLocator.con1(int offset) {
    _jtd_constructor_120_impl(offset);
  }
  _jtd_constructor_120_impl(int offset) {
    _jtd_constructor_121_impl(offset, offset);
  }

  /**
   * Initialize a newly created locator to locate one or more {@link ASTNode AST nodes} by locating
   * the node within an AST structure that corresponds to the given range of characters in the
   * source.
   * @param start the start offset of the range used to identify the node
   * @param end the end offset of the range used to identify the node
   */
  NodeLocator.con2(int start, int end) {
    _jtd_constructor_121_impl(start, end);
  }
  _jtd_constructor_121_impl(int start, int end) {
    this._startOffset = start;
    this._endOffset = end;
  }

  /**
   * Return the node that was found that corresponds to the given source range, or {@code null} if
   * there is no such node.
   * @return the node that was found
   */
  ASTNode get foundNode => _foundNode;

  /**
   * Search within the given AST node for an identifier representing a {@link DartElement Dart
   * element} in the specified source range. Return the element that was found, or {@code null} if
   * no element was found.
   * @param node the AST node within which to search
   * @return the element that was found
   */
  ASTNode searchWithin(ASTNode node) {
    try {
      node.accept(this);
    } on NodeLocator_NodeFoundException catch (exception) {
    } catch (exception) {
      AnalysisEngine.instance.logger.logInformation2("Unable to locate element at offset (${_startOffset} - ${_endOffset})", exception);
      return null;
    }
    return _foundNode;
  }
  Object visitNode(ASTNode node) {
    int start = node.offset;
    int end = start + node.length;
    if (end < _startOffset) {
      return null;
    }
    if (start > _endOffset) {
      return null;
    }
    try {
      node.visitChildren(this);
    } on NodeLocator_NodeFoundException catch (exception) {
      throw exception;
    } catch (exception) {
      AnalysisEngine.instance.logger.logInformation2("Exception caught while traversing an AST structure.", exception);
    }
    if (start <= _startOffset && _endOffset <= end) {
      _foundNode = node;
      throw new NodeLocator_NodeFoundException();
    }
    return null;
  }
}
/**
 * Instances of the class {@code NodeFoundException} are used to cancel visiting after a node has
 * been found.
 */
class NodeLocator_NodeFoundException extends RuntimeException {
  static int _serialVersionUID = 1;
}
/**
 * Instances of the class {@code RecursiveASTVisitor} implement an AST visitor that will recursively
 * visit all of the nodes in an AST structure. For example, using an instance of this class to visit
 * a {@link Block} will also cause all of the statements in the block to be visited.
 * <p>
 * Subclasses that override a visit method must either invoke the overridden visit method or must
 * explicitly ask the visited node to visit its children. Failure to do so will cause the children
 * of the visited node to not be visited.
 * @coverage dart.engine.ast
 */
class RecursiveASTVisitor<R> implements ASTVisitor<R> {
  R visitAdjacentStrings(AdjacentStrings node) {
    node.visitChildren(this);
    return null;
  }
  R visitAnnotation(Annotation node) {
    node.visitChildren(this);
    return null;
  }
  R visitArgumentDefinitionTest(ArgumentDefinitionTest node) {
    node.visitChildren(this);
    return null;
  }
  R visitArgumentList(ArgumentList node) {
    node.visitChildren(this);
    return null;
  }
  R visitAsExpression(AsExpression node) {
    node.visitChildren(this);
    return null;
  }
  R visitAssertStatement(AssertStatement node) {
    node.visitChildren(this);
    return null;
  }
  R visitAssignmentExpression(AssignmentExpression node) {
    node.visitChildren(this);
    return null;
  }
  R visitBinaryExpression(BinaryExpression node) {
    node.visitChildren(this);
    return null;
  }
  R visitBlock(Block node) {
    node.visitChildren(this);
    return null;
  }
  R visitBlockFunctionBody(BlockFunctionBody node) {
    node.visitChildren(this);
    return null;
  }
  R visitBooleanLiteral(BooleanLiteral node) {
    node.visitChildren(this);
    return null;
  }
  R visitBreakStatement(BreakStatement node) {
    node.visitChildren(this);
    return null;
  }
  R visitCascadeExpression(CascadeExpression node) {
    node.visitChildren(this);
    return null;
  }
  R visitCatchClause(CatchClause node) {
    node.visitChildren(this);
    return null;
  }
  R visitClassDeclaration(ClassDeclaration node) {
    node.visitChildren(this);
    return null;
  }
  R visitClassTypeAlias(ClassTypeAlias node) {
    node.visitChildren(this);
    return null;
  }
  R visitComment(Comment node) {
    node.visitChildren(this);
    return null;
  }
  R visitCommentReference(CommentReference node) {
    node.visitChildren(this);
    return null;
  }
  R visitCompilationUnit(CompilationUnit node) {
    node.visitChildren(this);
    return null;
  }
  R visitConditionalExpression(ConditionalExpression node) {
    node.visitChildren(this);
    return null;
  }
  R visitConstructorDeclaration(ConstructorDeclaration node) {
    node.visitChildren(this);
    return null;
  }
  R visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    node.visitChildren(this);
    return null;
  }
  R visitConstructorName(ConstructorName node) {
    node.visitChildren(this);
    return null;
  }
  R visitContinueStatement(ContinueStatement node) {
    node.visitChildren(this);
    return null;
  }
  R visitDeclaredIdentifier(DeclaredIdentifier node) {
    node.visitChildren(this);
    return null;
  }
  R visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.visitChildren(this);
    return null;
  }
  R visitDoStatement(DoStatement node) {
    node.visitChildren(this);
    return null;
  }
  R visitDoubleLiteral(DoubleLiteral node) {
    node.visitChildren(this);
    return null;
  }
  R visitEmptyFunctionBody(EmptyFunctionBody node) {
    node.visitChildren(this);
    return null;
  }
  R visitEmptyStatement(EmptyStatement node) {
    node.visitChildren(this);
    return null;
  }
  R visitExportDirective(ExportDirective node) {
    node.visitChildren(this);
    return null;
  }
  R visitExpressionFunctionBody(ExpressionFunctionBody node) {
    node.visitChildren(this);
    return null;
  }
  R visitExpressionStatement(ExpressionStatement node) {
    node.visitChildren(this);
    return null;
  }
  R visitExtendsClause(ExtendsClause node) {
    node.visitChildren(this);
    return null;
  }
  R visitFieldDeclaration(FieldDeclaration node) {
    node.visitChildren(this);
    return null;
  }
  R visitFieldFormalParameter(FieldFormalParameter node) {
    node.visitChildren(this);
    return null;
  }
  R visitForEachStatement(ForEachStatement node) {
    node.visitChildren(this);
    return null;
  }
  R visitFormalParameterList(FormalParameterList node) {
    node.visitChildren(this);
    return null;
  }
  R visitForStatement(ForStatement node) {
    node.visitChildren(this);
    return null;
  }
  R visitFunctionDeclaration(FunctionDeclaration node) {
    node.visitChildren(this);
    return null;
  }
  R visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    node.visitChildren(this);
    return null;
  }
  R visitFunctionExpression(FunctionExpression node) {
    node.visitChildren(this);
    return null;
  }
  R visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.visitChildren(this);
    return null;
  }
  R visitFunctionTypeAlias(FunctionTypeAlias node) {
    node.visitChildren(this);
    return null;
  }
  R visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    node.visitChildren(this);
    return null;
  }
  R visitHideCombinator(HideCombinator node) {
    node.visitChildren(this);
    return null;
  }
  R visitIfStatement(IfStatement node) {
    node.visitChildren(this);
    return null;
  }
  R visitImplementsClause(ImplementsClause node) {
    node.visitChildren(this);
    return null;
  }
  R visitImportDirective(ImportDirective node) {
    node.visitChildren(this);
    return null;
  }
  R visitIndexExpression(IndexExpression node) {
    node.visitChildren(this);
    return null;
  }
  R visitInstanceCreationExpression(InstanceCreationExpression node) {
    node.visitChildren(this);
    return null;
  }
  R visitIntegerLiteral(IntegerLiteral node) {
    node.visitChildren(this);
    return null;
  }
  R visitInterpolationExpression(InterpolationExpression node) {
    node.visitChildren(this);
    return null;
  }
  R visitInterpolationString(InterpolationString node) {
    node.visitChildren(this);
    return null;
  }
  R visitIsExpression(IsExpression node) {
    node.visitChildren(this);
    return null;
  }
  R visitLabel(Label node) {
    node.visitChildren(this);
    return null;
  }
  R visitLabeledStatement(LabeledStatement node) {
    node.visitChildren(this);
    return null;
  }
  R visitLibraryDirective(LibraryDirective node) {
    node.visitChildren(this);
    return null;
  }
  R visitLibraryIdentifier(LibraryIdentifier node) {
    node.visitChildren(this);
    return null;
  }
  R visitListLiteral(ListLiteral node) {
    node.visitChildren(this);
    return null;
  }
  R visitMapLiteral(MapLiteral node) {
    node.visitChildren(this);
    return null;
  }
  R visitMapLiteralEntry(MapLiteralEntry node) {
    node.visitChildren(this);
    return null;
  }
  R visitMethodDeclaration(MethodDeclaration node) {
    node.visitChildren(this);
    return null;
  }
  R visitMethodInvocation(MethodInvocation node) {
    node.visitChildren(this);
    return null;
  }
  R visitNamedExpression(NamedExpression node) {
    node.visitChildren(this);
    return null;
  }
  R visitNativeFunctionBody(NativeFunctionBody node) {
    node.visitChildren(this);
    return null;
  }
  R visitNullLiteral(NullLiteral node) {
    node.visitChildren(this);
    return null;
  }
  R visitParenthesizedExpression(ParenthesizedExpression node) {
    node.visitChildren(this);
    return null;
  }
  R visitPartDirective(PartDirective node) {
    node.visitChildren(this);
    return null;
  }
  R visitPartOfDirective(PartOfDirective node) {
    node.visitChildren(this);
    return null;
  }
  R visitPostfixExpression(PostfixExpression node) {
    node.visitChildren(this);
    return null;
  }
  R visitPrefixedIdentifier(PrefixedIdentifier node) {
    node.visitChildren(this);
    return null;
  }
  R visitPrefixExpression(PrefixExpression node) {
    node.visitChildren(this);
    return null;
  }
  R visitPropertyAccess(PropertyAccess node) {
    node.visitChildren(this);
    return null;
  }
  R visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    node.visitChildren(this);
    return null;
  }
  R visitRethrowExpression(RethrowExpression node) {
    node.visitChildren(this);
    return null;
  }
  R visitReturnStatement(ReturnStatement node) {
    node.visitChildren(this);
    return null;
  }
  R visitScriptTag(ScriptTag node) {
    node.visitChildren(this);
    return null;
  }
  R visitShowCombinator(ShowCombinator node) {
    node.visitChildren(this);
    return null;
  }
  R visitSimpleFormalParameter(SimpleFormalParameter node) {
    node.visitChildren(this);
    return null;
  }
  R visitSimpleIdentifier(SimpleIdentifier node) {
    node.visitChildren(this);
    return null;
  }
  R visitSimpleStringLiteral(SimpleStringLiteral node) {
    node.visitChildren(this);
    return null;
  }
  R visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
    return null;
  }
  R visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    node.visitChildren(this);
    return null;
  }
  R visitSuperExpression(SuperExpression node) {
    node.visitChildren(this);
    return null;
  }
  R visitSwitchCase(SwitchCase node) {
    node.visitChildren(this);
    return null;
  }
  R visitSwitchDefault(SwitchDefault node) {
    node.visitChildren(this);
    return null;
  }
  R visitSwitchStatement(SwitchStatement node) {
    node.visitChildren(this);
    return null;
  }
  R visitThisExpression(ThisExpression node) {
    node.visitChildren(this);
    return null;
  }
  R visitThrowExpression(ThrowExpression node) {
    node.visitChildren(this);
    return null;
  }
  R visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    node.visitChildren(this);
    return null;
  }
  R visitTryStatement(TryStatement node) {
    node.visitChildren(this);
    return null;
  }
  R visitTypeArgumentList(TypeArgumentList node) {
    node.visitChildren(this);
    return null;
  }
  R visitTypeName(TypeName node) {
    node.visitChildren(this);
    return null;
  }
  R visitTypeParameter(TypeParameter node) {
    node.visitChildren(this);
    return null;
  }
  R visitTypeParameterList(TypeParameterList node) {
    node.visitChildren(this);
    return null;
  }
  R visitVariableDeclaration(VariableDeclaration node) {
    node.visitChildren(this);
    return null;
  }
  R visitVariableDeclarationList(VariableDeclarationList node) {
    node.visitChildren(this);
    return null;
  }
  R visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    node.visitChildren(this);
    return null;
  }
  R visitWhileStatement(WhileStatement node) {
    node.visitChildren(this);
    return null;
  }
  R visitWithClause(WithClause node) {
    node.visitChildren(this);
    return null;
  }
}
/**
 * Instances of the class {@code SimpleASTVisitor} implement an AST visitor that will do nothing
 * when visiting an AST node. It is intended to be a superclass for classes that use the visitor
 * pattern primarily as a dispatch mechanism (and hence don't need to recursively visit a whole
 * structure) and that only need to visit a small number of node types.
 * @coverage dart.engine.ast
 */
class SimpleASTVisitor<R> implements ASTVisitor<R> {
  R visitAdjacentStrings(AdjacentStrings node) => null;
  R visitAnnotation(Annotation node) => null;
  R visitArgumentDefinitionTest(ArgumentDefinitionTest node) => null;
  R visitArgumentList(ArgumentList node) => null;
  R visitAsExpression(AsExpression node) => null;
  R visitAssertStatement(AssertStatement node) => null;
  R visitAssignmentExpression(AssignmentExpression node) => null;
  R visitBinaryExpression(BinaryExpression node) => null;
  R visitBlock(Block node) => null;
  R visitBlockFunctionBody(BlockFunctionBody node) => null;
  R visitBooleanLiteral(BooleanLiteral node) => null;
  R visitBreakStatement(BreakStatement node) => null;
  R visitCascadeExpression(CascadeExpression node) => null;
  R visitCatchClause(CatchClause node) => null;
  R visitClassDeclaration(ClassDeclaration node) => null;
  R visitClassTypeAlias(ClassTypeAlias node) => null;
  R visitComment(Comment node) => null;
  R visitCommentReference(CommentReference node) => null;
  R visitCompilationUnit(CompilationUnit node) => null;
  R visitConditionalExpression(ConditionalExpression node) => null;
  R visitConstructorDeclaration(ConstructorDeclaration node) => null;
  R visitConstructorFieldInitializer(ConstructorFieldInitializer node) => null;
  R visitConstructorName(ConstructorName node) => null;
  R visitContinueStatement(ContinueStatement node) => null;
  R visitDeclaredIdentifier(DeclaredIdentifier node) => null;
  R visitDefaultFormalParameter(DefaultFormalParameter node) => null;
  R visitDoStatement(DoStatement node) => null;
  R visitDoubleLiteral(DoubleLiteral node) => null;
  R visitEmptyFunctionBody(EmptyFunctionBody node) => null;
  R visitEmptyStatement(EmptyStatement node) => null;
  R visitExportDirective(ExportDirective node) => null;
  R visitExpressionFunctionBody(ExpressionFunctionBody node) => null;
  R visitExpressionStatement(ExpressionStatement node) => null;
  R visitExtendsClause(ExtendsClause node) => null;
  R visitFieldDeclaration(FieldDeclaration node) => null;
  R visitFieldFormalParameter(FieldFormalParameter node) => null;
  R visitForEachStatement(ForEachStatement node) => null;
  R visitFormalParameterList(FormalParameterList node) => null;
  R visitForStatement(ForStatement node) => null;
  R visitFunctionDeclaration(FunctionDeclaration node) => null;
  R visitFunctionDeclarationStatement(FunctionDeclarationStatement node) => null;
  R visitFunctionExpression(FunctionExpression node) => null;
  R visitFunctionExpressionInvocation(FunctionExpressionInvocation node) => null;
  R visitFunctionTypeAlias(FunctionTypeAlias node) => null;
  R visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) => null;
  R visitHideCombinator(HideCombinator node) => null;
  R visitIfStatement(IfStatement node) => null;
  R visitImplementsClause(ImplementsClause node) => null;
  R visitImportDirective(ImportDirective node) => null;
  R visitIndexExpression(IndexExpression node) => null;
  R visitInstanceCreationExpression(InstanceCreationExpression node) => null;
  R visitIntegerLiteral(IntegerLiteral node) => null;
  R visitInterpolationExpression(InterpolationExpression node) => null;
  R visitInterpolationString(InterpolationString node) => null;
  R visitIsExpression(IsExpression node) => null;
  R visitLabel(Label node) => null;
  R visitLabeledStatement(LabeledStatement node) => null;
  R visitLibraryDirective(LibraryDirective node) => null;
  R visitLibraryIdentifier(LibraryIdentifier node) => null;
  R visitListLiteral(ListLiteral node) => null;
  R visitMapLiteral(MapLiteral node) => null;
  R visitMapLiteralEntry(MapLiteralEntry node) => null;
  R visitMethodDeclaration(MethodDeclaration node) => null;
  R visitMethodInvocation(MethodInvocation node) => null;
  R visitNamedExpression(NamedExpression node) => null;
  R visitNativeFunctionBody(NativeFunctionBody node) => null;
  R visitNullLiteral(NullLiteral node) => null;
  R visitParenthesizedExpression(ParenthesizedExpression node) => null;
  R visitPartDirective(PartDirective node) => null;
  R visitPartOfDirective(PartOfDirective node) => null;
  R visitPostfixExpression(PostfixExpression node) => null;
  R visitPrefixedIdentifier(PrefixedIdentifier node) => null;
  R visitPrefixExpression(PrefixExpression node) => null;
  R visitPropertyAccess(PropertyAccess node) => null;
  R visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) => null;
  R visitRethrowExpression(RethrowExpression node) => null;
  R visitReturnStatement(ReturnStatement node) => null;
  R visitScriptTag(ScriptTag node) => null;
  R visitShowCombinator(ShowCombinator node) => null;
  R visitSimpleFormalParameter(SimpleFormalParameter node) => null;
  R visitSimpleIdentifier(SimpleIdentifier node) => null;
  R visitSimpleStringLiteral(SimpleStringLiteral node) => null;
  R visitStringInterpolation(StringInterpolation node) => null;
  R visitSuperConstructorInvocation(SuperConstructorInvocation node) => null;
  R visitSuperExpression(SuperExpression node) => null;
  R visitSwitchCase(SwitchCase node) => null;
  R visitSwitchDefault(SwitchDefault node) => null;
  R visitSwitchStatement(SwitchStatement node) => null;
  R visitThisExpression(ThisExpression node) => null;
  R visitThrowExpression(ThrowExpression node) => null;
  R visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) => null;
  R visitTryStatement(TryStatement node) => null;
  R visitTypeArgumentList(TypeArgumentList node) => null;
  R visitTypeName(TypeName node) => null;
  R visitTypeParameter(TypeParameter node) => null;
  R visitTypeParameterList(TypeParameterList node) => null;
  R visitVariableDeclaration(VariableDeclaration node) => null;
  R visitVariableDeclarationList(VariableDeclarationList node) => null;
  R visitVariableDeclarationStatement(VariableDeclarationStatement node) => null;
  R visitWhileStatement(WhileStatement node) => null;
  R visitWithClause(WithClause node) => null;
}
/**
 * Instances of the class {@code ToSourceVisitor} write a source representation of a visited AST
 * node (and all of it's children) to a writer.
 * @coverage dart.engine.ast
 */
class ToSourceVisitor implements ASTVisitor<Object> {

  /**
   * The writer to which the source is to be written.
   */
  PrintWriter _writer;

  /**
   * Initialize a newly created visitor to write source code representing the visited nodes to the
   * given writer.
   * @param writer the writer to which the source is to be written
   */
  ToSourceVisitor(PrintWriter writer) {
    this._writer = writer;
  }
  Object visitAdjacentStrings(AdjacentStrings node) {
    visitList2(node.strings, " ");
    return null;
  }
  Object visitAnnotation(Annotation node) {
    _writer.print('@');
    visit(node.name);
    visit3(".", node.constructorName);
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
    visitList2(node.arguments, ", ");
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
    _writer.print("assert (");
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
    visitList2(node.statements, " ");
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
    visit3(" ", node.label);
    _writer.print(";");
    return null;
  }
  Object visitCascadeExpression(CascadeExpression node) {
    visit(node.target);
    visitList(node.cascadeSections);
    return null;
  }
  Object visitCatchClause(CatchClause node) {
    visit3("on ", node.exceptionType);
    if (node.catchKeyword != null) {
      if (node.exceptionType != null) {
        _writer.print(' ');
      }
      _writer.print("catch (");
      visit(node.exceptionParameter);
      visit3(", ", node.stackTraceParameter);
      _writer.print(") ");
    } else {
      _writer.print(" ");
    }
    visit(node.body);
    return null;
  }
  Object visitClassDeclaration(ClassDeclaration node) {
    visit5(node.abstractKeyword, " ");
    _writer.print("class ");
    visit(node.name);
    visit(node.typeParameters);
    visit3(" ", node.extendsClause);
    visit3(" ", node.withClause);
    visit3(" ", node.implementsClause);
    _writer.print(" {");
    visitList2(node.members, " ");
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
    visit3(" ", node.withClause);
    visit3(" ", node.implementsClause);
    _writer.print(";");
    return null;
  }
  Object visitComment(Comment node) => null;
  Object visitCommentReference(CommentReference node) => null;
  Object visitCompilationUnit(CompilationUnit node) {
    ScriptTag scriptTag = node.scriptTag;
    NodeList<Directive> directives = node.directives;
    visit(scriptTag);
    String prefix = scriptTag == null ? "" : " ";
    visitList4(prefix, directives, " ");
    prefix = scriptTag == null && directives.isEmpty ? "" : " ";
    visitList4(prefix, node.declarations, " ");
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
    visit5(node.externalKeyword, " ");
    visit5(node.constKeyword, " ");
    visit5(node.factoryKeyword, " ");
    visit(node.returnType);
    visit3(".", node.name);
    visit(node.parameters);
    visitList4(" : ", node.initializers, ", ");
    visit3(" = ", node.redirectedConstructor);
    visit4(" ", node.body);
    return null;
  }
  Object visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    visit5(node.keyword, ".");
    visit(node.fieldName);
    _writer.print(" = ");
    visit(node.expression);
    return null;
  }
  Object visitConstructorName(ConstructorName node) {
    visit(node.type);
    visit3(".", node.name);
    return null;
  }
  Object visitContinueStatement(ContinueStatement node) {
    _writer.print("continue");
    visit3(" ", node.label);
    _writer.print(";");
    return null;
  }
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    visit5(node.keyword, " ");
    visit2(node.type, " ");
    visit(node.identifier);
    return null;
  }
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    visit(node.parameter);
    if (node.separator != null) {
      _writer.print(" ");
      _writer.print(node.separator.lexeme);
      visit3(" ", node.defaultValue);
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
    visitList4(" ", node.combinators, " ");
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
    visit5(node.keyword, " ");
    visit(node.fields);
    _writer.print(";");
    return null;
  }
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    visit5(node.keyword, " ");
    visit2(node.type, " ");
    _writer.print("this.");
    visit(node.identifier);
    return null;
  }
  Object visitForEachStatement(ForEachStatement node) {
    _writer.print("for (");
    visit(node.loopVariable);
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
    visit3(" ", node.condition);
    _writer.print(";");
    visitList4(" ", node.updaters, ", ");
    _writer.print(") ");
    visit(node.body);
    return null;
  }
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    visit2(node.returnType, " ");
    visit5(node.propertyKeyword, " ");
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
    visit2(node.returnType, " ");
    visit(node.name);
    visit(node.typeParameters);
    visit(node.parameters);
    _writer.print(";");
    return null;
  }
  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    visit2(node.returnType, " ");
    visit(node.identifier);
    visit(node.parameters);
    return null;
  }
  Object visitHideCombinator(HideCombinator node) {
    _writer.print("hide ");
    visitList2(node.hiddenNames, ", ");
    return null;
  }
  Object visitIfStatement(IfStatement node) {
    _writer.print("if (");
    visit(node.condition);
    _writer.print(") ");
    visit(node.thenStatement);
    visit3(" else ", node.elseStatement);
    return null;
  }
  Object visitImplementsClause(ImplementsClause node) {
    _writer.print("implements ");
    visitList2(node.interfaces, ", ");
    return null;
  }
  Object visitImportDirective(ImportDirective node) {
    _writer.print("import ");
    visit(node.uri);
    visit3(" as ", node.prefix);
    visitList4(" ", node.combinators, " ");
    _writer.print(';');
    return null;
  }
  Object visitIndexExpression(IndexExpression node) {
    if (node.isCascaded()) {
      _writer.print("..");
    } else {
      visit(node.array);
    }
    _writer.print('[');
    visit(node.index);
    _writer.print(']');
    return null;
  }
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    visit5(node.keyword, " ");
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
    visitList3(node.labels, " ", " ");
    visit(node.statement);
    return null;
  }
  Object visitLibraryDirective(LibraryDirective node) {
    _writer.print("library ");
    visit(node.name);
    _writer.print(';');
    return null;
  }
  Object visitLibraryIdentifier(LibraryIdentifier node) {
    _writer.print(node.name);
    return null;
  }
  Object visitListLiteral(ListLiteral node) {
    if (node.modifier != null) {
      _writer.print(node.modifier.lexeme);
      _writer.print(' ');
    }
    visit2(node.typeArguments, " ");
    _writer.print("[");
    visitList2(node.elements, ", ");
    _writer.print("]");
    return null;
  }
  Object visitMapLiteral(MapLiteral node) {
    if (node.modifier != null) {
      _writer.print(node.modifier.lexeme);
      _writer.print(' ');
    }
    visit2(node.typeArguments, " ");
    _writer.print("{");
    visitList2(node.entries, ", ");
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
    visit5(node.externalKeyword, " ");
    visit5(node.modifierKeyword, " ");
    visit2(node.returnType, " ");
    visit5(node.propertyKeyword, " ");
    visit5(node.operatorKeyword, " ");
    visit(node.name);
    if (!node.isGetter()) {
      visit(node.parameters);
    }
    visit4(" ", node.body);
    return null;
  }
  Object visitMethodInvocation(MethodInvocation node) {
    if (node.isCascaded()) {
      _writer.print("..");
    } else {
      visit2(node.target, ".");
    }
    visit(node.methodName);
    visit(node.argumentList);
    return null;
  }
  Object visitNamedExpression(NamedExpression node) {
    visit(node.name);
    visit3(" ", node.expression);
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
    if (node.isCascaded()) {
      _writer.print("..");
    } else {
      visit(node.target);
      _writer.print('.');
    }
    visit(node.propertyName);
    return null;
  }
  Object visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    _writer.print("this");
    visit3(".", node.constructorName);
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
    visitList2(node.shownNames, ", ");
    return null;
  }
  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    visit5(node.keyword, " ");
    visit2(node.type, " ");
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
    visit3(".", node.constructorName);
    visit(node.argumentList);
    return null;
  }
  Object visitSuperExpression(SuperExpression node) {
    _writer.print("super");
    return null;
  }
  Object visitSwitchCase(SwitchCase node) {
    visitList3(node.labels, " ", " ");
    _writer.print("case ");
    visit(node.expression);
    _writer.print(": ");
    visitList2(node.statements, " ");
    return null;
  }
  Object visitSwitchDefault(SwitchDefault node) {
    visitList3(node.labels, " ", " ");
    _writer.print("default: ");
    visitList2(node.statements, " ");
    return null;
  }
  Object visitSwitchStatement(SwitchStatement node) {
    _writer.print("switch (");
    visit(node.expression);
    _writer.print(") {");
    visitList2(node.members, " ");
    _writer.print("}");
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
    visit2(node.variables, ";");
    return null;
  }
  Object visitTryStatement(TryStatement node) {
    _writer.print("try ");
    visit(node.body);
    visitList4(" ", node.catchClauses, " ");
    visit3(" finally ", node.finallyClause);
    return null;
  }
  Object visitTypeArgumentList(TypeArgumentList node) {
    _writer.print('<');
    visitList2(node.arguments, ", ");
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
    visit3(" extends ", node.bound);
    return null;
  }
  Object visitTypeParameterList(TypeParameterList node) {
    _writer.print('<');
    visitList2(node.typeParameters, ", ");
    _writer.print('>');
    return null;
  }
  Object visitVariableDeclaration(VariableDeclaration node) {
    visit(node.name);
    visit3(" = ", node.initializer);
    return null;
  }
  Object visitVariableDeclarationList(VariableDeclarationList node) {
    visit5(node.keyword, " ");
    visit2(node.type, " ");
    visitList2(node.variables, ", ");
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
    visitList2(node.mixinTypes, ", ");
    return null;
  }

  /**
   * Safely visit the given node.
   * @param node the node to be visited
   */
  void visit(ASTNode node) {
    if (node != null) {
      node.accept(this);
    }
  }

  /**
   * Safely visit the given node, printing the suffix after the node if it is non-{@code null}.
   * @param suffix the suffix to be printed if there is a node to visit
   * @param node the node to be visited
   */
  void visit2(ASTNode node, String suffix) {
    if (node != null) {
      node.accept(this);
      _writer.print(suffix);
    }
  }

  /**
   * Safely visit the given node, printing the prefix before the node if it is non-{@code null}.
   * @param prefix the prefix to be printed if there is a node to visit
   * @param node the node to be visited
   */
  void visit3(String prefix, ASTNode node) {
    if (node != null) {
      _writer.print(prefix);
      node.accept(this);
    }
  }

  /**
   * Visit the given function body, printing the prefix before if given body is not empty.
   * @param prefix the prefix to be printed if there is a node to visit
   * @param body the function body to be visited
   */
  void visit4(String prefix, FunctionBody body) {
    if (body is! EmptyFunctionBody) {
      _writer.print(prefix);
    }
    visit(body);
  }

  /**
   * Safely visit the given node, printing the suffix after the node if it is non-{@code null}.
   * @param suffix the suffix to be printed if there is a node to visit
   * @param node the node to be visited
   */
  void visit5(Token token, String suffix) {
    if (token != null) {
      _writer.print(token.lexeme);
      _writer.print(suffix);
    }
  }

  /**
   * Print a list of nodes without any separation.
   * @param nodes the nodes to be printed
   * @param separator the separator to be printed between adjacent nodes
   */
  void visitList(NodeList<ASTNode> nodes) {
    visitList2(nodes, "");
  }

  /**
   * Print a list of nodes, separated by the given separator.
   * @param nodes the nodes to be printed
   * @param separator the separator to be printed between adjacent nodes
   */
  void visitList2(NodeList<ASTNode> nodes, String separator) {
    if (nodes != null) {
      int size = nodes.length;
      for (int i = 0; i < size; i++) {
        if (i > 0) {
          _writer.print(separator);
        }
        nodes[i].accept(this);
      }
    }
  }

  /**
   * Print a list of nodes, separated by the given separator.
   * @param nodes the nodes to be printed
   * @param separator the separator to be printed between adjacent nodes
   * @param suffix the suffix to be printed if the list is not empty
   */
  void visitList3(NodeList<ASTNode> nodes, String separator, String suffix) {
    if (nodes != null) {
      int size = nodes.length;
      if (size > 0) {
        for (int i = 0; i < size; i++) {
          if (i > 0) {
            _writer.print(separator);
          }
          nodes[i].accept(this);
        }
        _writer.print(suffix);
      }
    }
  }

  /**
   * Print a list of nodes, separated by the given separator.
   * @param prefix the prefix to be printed if the list is not empty
   * @param nodes the nodes to be printed
   * @param separator the separator to be printed between adjacent nodes
   */
  void visitList4(String prefix, NodeList<ASTNode> nodes, String separator) {
    if (nodes != null) {
      int size = nodes.length;
      if (size > 0) {
        _writer.print(prefix);
        for (int i = 0; i < size; i++) {
          if (i > 0) {
            _writer.print(separator);
          }
          nodes[i].accept(this);
        }
      }
    }
  }
}
/**
 * Instances of the class {@code ASTCloner} implement an object that will clone any AST structure
 * that it visits. The cloner will only clone the structure, it will not preserve any resolution
 * results or properties associated with the nodes.
 */
class ASTCloner implements ASTVisitor<ASTNode> {
  AdjacentStrings visitAdjacentStrings(AdjacentStrings node) => new AdjacentStrings.full(clone3(node.strings));
  Annotation visitAnnotation(Annotation node) => new Annotation.full(node.atSign, clone2(node.name), node.period, clone2(node.constructorName), clone2(node.arguments));
  ArgumentDefinitionTest visitArgumentDefinitionTest(ArgumentDefinitionTest node) => new ArgumentDefinitionTest.full(node.question, clone2(node.identifier));
  ArgumentList visitArgumentList(ArgumentList node) => new ArgumentList.full(node.leftParenthesis, clone3(node.arguments), node.rightParenthesis);
  AsExpression visitAsExpression(AsExpression node) => new AsExpression.full(clone2(node.expression), node.asOperator, clone2(node.type));
  ASTNode visitAssertStatement(AssertStatement node) => new AssertStatement.full(node.keyword, node.leftParenthesis, clone2(node.condition), node.rightParenthesis, node.semicolon);
  AssignmentExpression visitAssignmentExpression(AssignmentExpression node) => new AssignmentExpression.full(clone2(node.leftHandSide), node.operator, clone2(node.rightHandSide));
  BinaryExpression visitBinaryExpression(BinaryExpression node) => new BinaryExpression.full(clone2(node.leftOperand), node.operator, clone2(node.rightOperand));
  Block visitBlock(Block node) => new Block.full(node.leftBracket, clone3(node.statements), node.rightBracket);
  BlockFunctionBody visitBlockFunctionBody(BlockFunctionBody node) => new BlockFunctionBody.full(clone2(node.block));
  BooleanLiteral visitBooleanLiteral(BooleanLiteral node) => new BooleanLiteral.full(node.literal, node.value);
  BreakStatement visitBreakStatement(BreakStatement node) => new BreakStatement.full(node.keyword, clone2(node.label), node.semicolon);
  CascadeExpression visitCascadeExpression(CascadeExpression node) => new CascadeExpression.full(clone2(node.target), clone3(node.cascadeSections));
  CatchClause visitCatchClause(CatchClause node) => new CatchClause.full(node.onKeyword, clone2(node.exceptionType), node.catchKeyword, node.leftParenthesis, clone2(node.exceptionParameter), node.comma, clone2(node.stackTraceParameter), node.rightParenthesis, clone2(node.body));
  ClassDeclaration visitClassDeclaration(ClassDeclaration node) => new ClassDeclaration.full(clone2(node.documentationComment), clone3(node.metadata), node.abstractKeyword, node.classKeyword, clone2(node.name), clone2(node.typeParameters), clone2(node.extendsClause), clone2(node.withClause), clone2(node.implementsClause), node.leftBracket, clone3(node.members), node.rightBracket);
  ClassTypeAlias visitClassTypeAlias(ClassTypeAlias node) => new ClassTypeAlias.full(clone2(node.documentationComment), clone3(node.metadata), node.keyword, clone2(node.name), clone2(node.typeParameters), node.equals, node.abstractKeyword, clone2(node.superclass), clone2(node.withClause), clone2(node.implementsClause), node.semicolon);
  Comment visitComment(Comment node) {
    if (node.isDocumentation()) {
      return Comment.createDocumentationComment2(node.tokens, clone3(node.references));
    } else if (node.isBlock()) {
      return Comment.createBlockComment(node.tokens);
    }
    return Comment.createEndOfLineComment(node.tokens);
  }
  CommentReference visitCommentReference(CommentReference node) => new CommentReference.full(node.newKeyword, clone2(node.identifier));
  CompilationUnit visitCompilationUnit(CompilationUnit node) {
    CompilationUnit clone = new CompilationUnit.full(node.beginToken, clone2(node.scriptTag), clone3(node.directives), clone3(node.declarations), node.endToken);
    clone.lineInfo = node.lineInfo;
    clone.parsingErrors = node.parsingErrors;
    clone.resolutionErrors = node.resolutionErrors;
    return clone;
  }
  ConditionalExpression visitConditionalExpression(ConditionalExpression node) => new ConditionalExpression.full(clone2(node.condition), node.question, clone2(node.thenExpression), node.colon, clone2(node.elseExpression));
  ConstructorDeclaration visitConstructorDeclaration(ConstructorDeclaration node) => new ConstructorDeclaration.full(clone2(node.documentationComment), clone3(node.metadata), node.externalKeyword, node.constKeyword, node.factoryKeyword, clone2(node.returnType), node.period, clone2(node.name), clone2(node.parameters), node.separator, clone3(node.initializers), clone2(node.redirectedConstructor), clone2(node.body));
  ConstructorFieldInitializer visitConstructorFieldInitializer(ConstructorFieldInitializer node) => new ConstructorFieldInitializer.full(node.keyword, node.period, clone2(node.fieldName), node.equals, clone2(node.expression));
  ConstructorName visitConstructorName(ConstructorName node) => new ConstructorName.full(clone2(node.type), node.period, clone2(node.name));
  ContinueStatement visitContinueStatement(ContinueStatement node) => new ContinueStatement.full(node.keyword, clone2(node.label), node.semicolon);
  DeclaredIdentifier visitDeclaredIdentifier(DeclaredIdentifier node) => new DeclaredIdentifier.full(clone2(node.documentationComment), clone3(node.metadata), node.keyword, clone2(node.type), clone2(node.identifier));
  DefaultFormalParameter visitDefaultFormalParameter(DefaultFormalParameter node) => new DefaultFormalParameter.full(clone2(node.parameter), node.kind, node.separator, clone2(node.defaultValue));
  DoStatement visitDoStatement(DoStatement node) => new DoStatement.full(node.doKeyword, clone2(node.body), node.whileKeyword, node.leftParenthesis, clone2(node.condition), node.rightParenthesis, node.semicolon);
  DoubleLiteral visitDoubleLiteral(DoubleLiteral node) => new DoubleLiteral.full(node.literal, node.value);
  EmptyFunctionBody visitEmptyFunctionBody(EmptyFunctionBody node) => new EmptyFunctionBody.full(node.semicolon);
  EmptyStatement visitEmptyStatement(EmptyStatement node) => new EmptyStatement.full(node.semicolon);
  ExportDirective visitExportDirective(ExportDirective node) => new ExportDirective.full(clone2(node.documentationComment), clone3(node.metadata), node.keyword, clone2(node.uri), clone3(node.combinators), node.semicolon);
  ExpressionFunctionBody visitExpressionFunctionBody(ExpressionFunctionBody node) => new ExpressionFunctionBody.full(node.functionDefinition, clone2(node.expression), node.semicolon);
  ExpressionStatement visitExpressionStatement(ExpressionStatement node) => new ExpressionStatement.full(clone2(node.expression), node.semicolon);
  ExtendsClause visitExtendsClause(ExtendsClause node) => new ExtendsClause.full(node.keyword, clone2(node.superclass));
  FieldDeclaration visitFieldDeclaration(FieldDeclaration node) => new FieldDeclaration.full(clone2(node.documentationComment), clone3(node.metadata), node.keyword, clone2(node.fields), node.semicolon);
  FieldFormalParameter visitFieldFormalParameter(FieldFormalParameter node) => new FieldFormalParameter.full(clone2(node.documentationComment), clone3(node.metadata), node.keyword, clone2(node.type), node.thisToken, node.period, clone2(node.identifier));
  ForEachStatement visitForEachStatement(ForEachStatement node) => new ForEachStatement.full(node.forKeyword, node.leftParenthesis, clone2(node.loopVariable), node.inKeyword, clone2(node.iterator), node.rightParenthesis, clone2(node.body));
  FormalParameterList visitFormalParameterList(FormalParameterList node) => new FormalParameterList.full(node.leftParenthesis, clone3(node.parameters), node.leftDelimiter, node.rightDelimiter, node.rightParenthesis);
  ForStatement visitForStatement(ForStatement node) => new ForStatement.full(node.forKeyword, node.leftParenthesis, clone2(node.variables), clone2(node.initialization), node.leftSeparator, clone2(node.condition), node.rightSeparator, clone3(node.updaters), node.rightParenthesis, clone2(node.body));
  FunctionDeclaration visitFunctionDeclaration(FunctionDeclaration node) => new FunctionDeclaration.full(clone2(node.documentationComment), clone3(node.metadata), node.externalKeyword, clone2(node.returnType), node.propertyKeyword, clone2(node.name), clone2(node.functionExpression));
  FunctionDeclarationStatement visitFunctionDeclarationStatement(FunctionDeclarationStatement node) => new FunctionDeclarationStatement.full(clone2(node.functionDeclaration));
  FunctionExpression visitFunctionExpression(FunctionExpression node) => new FunctionExpression.full(clone2(node.parameters), clone2(node.body));
  FunctionExpressionInvocation visitFunctionExpressionInvocation(FunctionExpressionInvocation node) => new FunctionExpressionInvocation.full(clone2(node.function), clone2(node.argumentList));
  FunctionTypeAlias visitFunctionTypeAlias(FunctionTypeAlias node) => new FunctionTypeAlias.full(clone2(node.documentationComment), clone3(node.metadata), node.keyword, clone2(node.returnType), clone2(node.name), clone2(node.typeParameters), clone2(node.parameters), node.semicolon);
  FunctionTypedFormalParameter visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) => new FunctionTypedFormalParameter.full(clone2(node.documentationComment), clone3(node.metadata), clone2(node.returnType), clone2(node.identifier), clone2(node.parameters));
  HideCombinator visitHideCombinator(HideCombinator node) => new HideCombinator.full(node.keyword, clone3(node.hiddenNames));
  IfStatement visitIfStatement(IfStatement node) => new IfStatement.full(node.ifKeyword, node.leftParenthesis, clone2(node.condition), node.rightParenthesis, clone2(node.thenStatement), node.elseKeyword, clone2(node.elseStatement));
  ImplementsClause visitImplementsClause(ImplementsClause node) => new ImplementsClause.full(node.keyword, clone3(node.interfaces));
  ImportDirective visitImportDirective(ImportDirective node) => new ImportDirective.full(clone2(node.documentationComment), clone3(node.metadata), node.keyword, clone2(node.uri), node.asToken, clone2(node.prefix), clone3(node.combinators), node.semicolon);
  IndexExpression visitIndexExpression(IndexExpression node) {
    Token period = node.period;
    if (period == null) {
      return new IndexExpression.forTarget_full(clone2(node.array), node.leftBracket, clone2(node.index), node.rightBracket);
    } else {
      return new IndexExpression.forCascade_full(period, node.leftBracket, clone2(node.index), node.rightBracket);
    }
  }
  InstanceCreationExpression visitInstanceCreationExpression(InstanceCreationExpression node) => new InstanceCreationExpression.full(node.keyword, clone2(node.constructorName), clone2(node.argumentList));
  IntegerLiteral visitIntegerLiteral(IntegerLiteral node) => new IntegerLiteral.full(node.literal, node.value);
  InterpolationExpression visitInterpolationExpression(InterpolationExpression node) => new InterpolationExpression.full(node.leftBracket, clone2(node.expression), node.rightBracket);
  InterpolationString visitInterpolationString(InterpolationString node) => new InterpolationString.full(node.contents, node.value);
  IsExpression visitIsExpression(IsExpression node) => new IsExpression.full(clone2(node.expression), node.isOperator, node.notOperator, clone2(node.type));
  Label visitLabel(Label node) => new Label.full(clone2(node.label), node.colon);
  LabeledStatement visitLabeledStatement(LabeledStatement node) => new LabeledStatement.full(clone3(node.labels), clone2(node.statement));
  LibraryDirective visitLibraryDirective(LibraryDirective node) => new LibraryDirective.full(clone2(node.documentationComment), clone3(node.metadata), node.libraryToken, clone2(node.name), node.semicolon);
  LibraryIdentifier visitLibraryIdentifier(LibraryIdentifier node) => new LibraryIdentifier.full(clone3(node.components));
  ListLiteral visitListLiteral(ListLiteral node) => new ListLiteral.full(node.modifier, clone2(node.typeArguments), node.leftBracket, clone3(node.elements), node.rightBracket);
  MapLiteral visitMapLiteral(MapLiteral node) => new MapLiteral.full(node.modifier, clone2(node.typeArguments), node.leftBracket, clone3(node.entries), node.rightBracket);
  MapLiteralEntry visitMapLiteralEntry(MapLiteralEntry node) => new MapLiteralEntry.full(clone2(node.key), node.separator, clone2(node.value));
  MethodDeclaration visitMethodDeclaration(MethodDeclaration node) => new MethodDeclaration.full(clone2(node.documentationComment), clone3(node.metadata), node.externalKeyword, node.modifierKeyword, clone2(node.returnType), node.propertyKeyword, node.operatorKeyword, clone2(node.name), clone2(node.parameters), clone2(node.body));
  MethodInvocation visitMethodInvocation(MethodInvocation node) => new MethodInvocation.full(clone2(node.target), node.period, clone2(node.methodName), clone2(node.argumentList));
  NamedExpression visitNamedExpression(NamedExpression node) => new NamedExpression.full(clone2(node.name), clone2(node.expression));
  NativeFunctionBody visitNativeFunctionBody(NativeFunctionBody node) => new NativeFunctionBody.full(node.nativeToken, clone2(node.stringLiteral), node.semicolon);
  NullLiteral visitNullLiteral(NullLiteral node) => new NullLiteral.full(node.literal);
  ParenthesizedExpression visitParenthesizedExpression(ParenthesizedExpression node) => new ParenthesizedExpression.full(node.leftParenthesis, clone2(node.expression), node.rightParenthesis);
  PartDirective visitPartDirective(PartDirective node) => new PartDirective.full(clone2(node.documentationComment), clone3(node.metadata), node.partToken, clone2(node.uri), node.semicolon);
  PartOfDirective visitPartOfDirective(PartOfDirective node) => new PartOfDirective.full(clone2(node.documentationComment), clone3(node.metadata), node.partToken, node.ofToken, clone2(node.libraryName), node.semicolon);
  PostfixExpression visitPostfixExpression(PostfixExpression node) => new PostfixExpression.full(clone2(node.operand), node.operator);
  PrefixedIdentifier visitPrefixedIdentifier(PrefixedIdentifier node) => new PrefixedIdentifier.full(clone2(node.prefix), node.period, clone2(node.identifier));
  PrefixExpression visitPrefixExpression(PrefixExpression node) => new PrefixExpression.full(node.operator, clone2(node.operand));
  PropertyAccess visitPropertyAccess(PropertyAccess node) => new PropertyAccess.full(clone2(node.target), node.operator, clone2(node.propertyName));
  RedirectingConstructorInvocation visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) => new RedirectingConstructorInvocation.full(node.keyword, node.period, clone2(node.constructorName), clone2(node.argumentList));
  RethrowExpression visitRethrowExpression(RethrowExpression node) => new RethrowExpression.full(node.keyword);
  ReturnStatement visitReturnStatement(ReturnStatement node) => new ReturnStatement.full(node.keyword, clone2(node.expression), node.semicolon);
  ScriptTag visitScriptTag(ScriptTag node) => new ScriptTag.full(node.scriptTag);
  ShowCombinator visitShowCombinator(ShowCombinator node) => new ShowCombinator.full(node.keyword, clone3(node.shownNames));
  SimpleFormalParameter visitSimpleFormalParameter(SimpleFormalParameter node) => new SimpleFormalParameter.full(clone2(node.documentationComment), clone3(node.metadata), node.keyword, clone2(node.type), clone2(node.identifier));
  SimpleIdentifier visitSimpleIdentifier(SimpleIdentifier node) => new SimpleIdentifier.full(node.token);
  SimpleStringLiteral visitSimpleStringLiteral(SimpleStringLiteral node) => new SimpleStringLiteral.full(node.literal, node.value);
  StringInterpolation visitStringInterpolation(StringInterpolation node) => new StringInterpolation.full(clone3(node.elements));
  SuperConstructorInvocation visitSuperConstructorInvocation(SuperConstructorInvocation node) => new SuperConstructorInvocation.full(node.keyword, node.period, clone2(node.constructorName), clone2(node.argumentList));
  SuperExpression visitSuperExpression(SuperExpression node) => new SuperExpression.full(node.keyword);
  SwitchCase visitSwitchCase(SwitchCase node) => new SwitchCase.full(clone3(node.labels), node.keyword, clone2(node.expression), node.colon, clone3(node.statements));
  SwitchDefault visitSwitchDefault(SwitchDefault node) => new SwitchDefault.full(clone3(node.labels), node.keyword, node.colon, clone3(node.statements));
  SwitchStatement visitSwitchStatement(SwitchStatement node) => new SwitchStatement.full(node.keyword, node.leftParenthesis, clone2(node.expression), node.rightParenthesis, node.leftBracket, clone3(node.members), node.rightBracket);
  ThisExpression visitThisExpression(ThisExpression node) => new ThisExpression.full(node.keyword);
  ThrowExpression visitThrowExpression(ThrowExpression node) => new ThrowExpression.full(node.keyword, clone2(node.expression));
  TopLevelVariableDeclaration visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) => new TopLevelVariableDeclaration.full(clone2(node.documentationComment), clone3(node.metadata), clone2(node.variables), node.semicolon);
  TryStatement visitTryStatement(TryStatement node) => new TryStatement.full(node.tryKeyword, clone2(node.body), clone3(node.catchClauses), node.finallyKeyword, clone2(node.finallyClause));
  TypeArgumentList visitTypeArgumentList(TypeArgumentList node) => new TypeArgumentList.full(node.leftBracket, clone3(node.arguments), node.rightBracket);
  TypeName visitTypeName(TypeName node) => new TypeName.full(clone2(node.name), clone2(node.typeArguments));
  TypeParameter visitTypeParameter(TypeParameter node) => new TypeParameter.full(clone2(node.documentationComment), clone3(node.metadata), clone2(node.name), node.keyword, clone2(node.bound));
  TypeParameterList visitTypeParameterList(TypeParameterList node) => new TypeParameterList.full(node.leftBracket, clone3(node.typeParameters), node.rightBracket);
  VariableDeclaration visitVariableDeclaration(VariableDeclaration node) => new VariableDeclaration.full(clone2(node.documentationComment), clone3(node.metadata), clone2(node.name), node.equals, clone2(node.initializer));
  VariableDeclarationList visitVariableDeclarationList(VariableDeclarationList node) => new VariableDeclarationList.full(clone2(node.documentationComment), clone3(node.metadata), node.keyword, clone2(node.type), clone3(node.variables));
  VariableDeclarationStatement visitVariableDeclarationStatement(VariableDeclarationStatement node) => new VariableDeclarationStatement.full(clone2(node.variables), node.semicolon);
  WhileStatement visitWhileStatement(WhileStatement node) => new WhileStatement.full(node.keyword, node.leftParenthesis, clone2(node.condition), node.rightParenthesis, clone2(node.body));
  WithClause visitWithClause(WithClause node) => new WithClause.full(node.withKeyword, clone3(node.mixinTypes));
  ASTNode clone2(ASTNode node) {
    if (node == null) {
      return null;
    }
    return node.accept(this) as ASTNode;
  }
  List clone3(NodeList nodes) {
    List clonedNodes = new List();
    for (ASTNode node in nodes) {
      clonedNodes.add((node.accept(this) as ASTNode));
    }
    return clonedNodes;
  }
}
/**
 * Traverse the AST from initial child node to successive parents, building a collection of local
 * variable and parameter names visible to the initial child node. In case of name shadowing, the
 * first name seen is the most specific one so names are not redefined.
 * <p>
 * Completion test code coverage is 95%. The two basic blocks that are not executed cannot be
 * executed. They are included for future reference.
 * @coverage com.google.dart.engine.services.completion
 */
class ScopedNameFinder extends GeneralizingASTVisitor<Object> {
  Declaration _declarationNode;
  ASTNode _immediateChild;
  Map<String, SimpleIdentifier> _locals = new Map<String, SimpleIdentifier>();
  int _position = 0;
  bool _referenceIsWithinLocalFunction = false;
  ScopedNameFinder(int position) {
    this._position = position;
  }
  Declaration get declaration => _declarationNode;
  Map<String, SimpleIdentifier> get locals => _locals;
  Object visitBlock(Block node) {
    checkStatements(node.statements);
    return super.visitBlock(node);
  }
  Object visitCatchClause(CatchClause node) {
    addToScope(node.exceptionParameter);
    addToScope(node.stackTraceParameter);
    return super.visitCatchClause(node);
  }
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    if (_immediateChild != node.parameters) {
      addParameters(node.parameters.parameters);
    }
    _declarationNode = node;
    return null;
  }
  Object visitFieldDeclaration(FieldDeclaration node) {
    _declarationNode = node;
    return null;
  }
  Object visitForEachStatement(ForEachStatement node) {
    addToScope(node.loopVariable.identifier);
    return super.visitForEachStatement(node);
  }
  Object visitForStatement(ForStatement node) {
    if (_immediateChild != node.variables && node.variables != null) {
      addVariables(node.variables.variables);
    }
    return super.visitForStatement(node);
  }
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is! FunctionDeclarationStatement) {
      _declarationNode = node;
      return null;
    }
    return super.visitFunctionDeclaration(node);
  }
  Object visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    _referenceIsWithinLocalFunction = true;
    return super.visitFunctionDeclarationStatement(node);
  }
  Object visitFunctionExpression(FunctionExpression node) {
    if (_immediateChild != node.parameters) {
      addParameters(node.parameters.parameters);
    }
    return super.visitFunctionExpression(node);
  }
  Object visitMethodDeclaration(MethodDeclaration node) {
    if (node.parameters == null) {
      return null;
    }
    if (_immediateChild != node.parameters) {
      addParameters(node.parameters.parameters);
    }
    _declarationNode = node;
    return null;
  }
  Object visitNode(ASTNode node) {
    _immediateChild = node;
    ASTNode parent = node.parent;
    if (parent != null) {
      parent.accept(this);
    }
    return null;
  }
  Object visitSwitchMember(SwitchMember node) {
    checkStatements(node.statements);
    return super.visitSwitchMember(node);
  }
  Object visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _declarationNode = node;
    return null;
  }
  Object visitTypeAlias(TypeAlias node) {
    _declarationNode = node;
    return null;
  }
  void addParameters(NodeList<FormalParameter> vars) {
    for (FormalParameter var2 in vars) {
      addToScope(var2.identifier);
    }
  }
  void addToScope(SimpleIdentifier identifier) {
    if (identifier != null && isInRange(identifier)) {
      String name = identifier.name;
      if (!_locals.containsKey(name)) {
        _locals[name] = identifier;
      }
    }
  }
  void addVariables(NodeList<VariableDeclaration> vars) {
    for (VariableDeclaration var2 in vars) {
      addToScope(var2.name);
    }
  }

  /**
   * Some statements define names that are visible downstream. There aren't many of these.
   * @param statements the list of statements to check for name definitions
   */
  void checkStatements(List<Statement> statements) {
    for (Statement stmt in statements) {
      if (identical(stmt, _immediateChild)) {
        return;
      }
      if (stmt is VariableDeclarationStatement) {
        addVariables(((stmt as VariableDeclarationStatement)).variables.variables);
      } else if (stmt is FunctionDeclarationStatement && !_referenceIsWithinLocalFunction) {
        addToScope(((stmt as FunctionDeclarationStatement)).functionDeclaration.name);
      }
    }
  }
  bool isInRange(ASTNode node) {
    if (_position < 0) {
      return true;
    }
    return node.end < _position;
  }
}
/**
 * Instances of the class {@code NodeList} represent a list of AST nodes that have a common parent.
 */
class NodeList<E extends ASTNode> extends ListWrapper<E> {
  /**
   * The node that is the parent of each of the elements in the list.
   */
  ASTNode owner;
  /**
   * The elements of the list.
   */
  List<E> elements = new List<E>();
  /**
   * Initialize a newly created list of nodes to be empty.
   * @param owner the node that is the parent of each of the elements in the list
   */
  NodeList(ASTNode this.owner);
  /**
   * Use the given visitor to visit each of the nodes in this list.
   * @param visitor the visitor to be used to visit the elements of this list
   */
  accept(ASTVisitor visitor) {
    for (E element in elements) {
      element.accept(visitor);
    }
  }
  void add(E node) {
    owner.becomeParentOf(node);
    elements.add(node);
  }
  bool addAll(Iterable<E> nodes) {
    if (nodes != null) {
      for (E node in nodes) {
        add(node);
      }
      return true;
    }
    return false;
  }
  /**
   * Return the first token included in this node's source range.
   * @return the first token included in this node's source range
   */
  Token get beginToken {
    if (elements.isEmpty) {
      return null;
    }
    return elements[0].beginToken;
  }
  /**
   * Return the last token included in this node list's source range.
   * @return the last token included in this node list's source range
   */
  Token get endToken {
    if (elements.isEmpty) {
      return null;
    }
    return elements[elements.length - 1].endToken;
  }
  /**
   * Return the node that is the parent of each of the elements in the list.
   * @return the node that is the parent of each of the elements in the list
   */
  ASTNode getOwner() {
    return owner;
  }
}
