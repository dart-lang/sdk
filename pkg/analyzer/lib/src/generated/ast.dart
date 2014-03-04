// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.ast;

import 'dart:collection';
import 'java_core.dart';
import 'java_engine.dart';
import 'source.dart' show LineInfo;
import 'scanner.dart';
import 'engine.dart' show AnalysisEngine;
import 'utilities_dart.dart';
import 'utilities_collection.dart' show TokenMap;
import 'element.dart';

/**
 * Instances of the class `AdjacentStrings` represents two or more string literals that are
 * implicitly concatenated because of being adjacent (separated only by whitespace).
 *
 * While the grammar only allows adjacent strings when all of the strings are of the same kind
 * (single line or multi-line), this class doesn't enforce that restriction.
 *
 * <pre>
 * adjacentStrings ::=
 *     [StringLiteral] [StringLiteral]+
 * </pre>
 */
class AdjacentStrings extends StringLiteral {
  /**
   * The strings that are implicitly concatenated.
   */
  NodeList<StringLiteral> _strings;

  /**
   * Initialize a newly created list of adjacent strings.
   *
   * @param strings the strings that are implicitly concatenated
   */
  AdjacentStrings(List<StringLiteral> strings) {
    this._strings = new NodeList<StringLiteral>(this);
    this._strings.addAll(strings);
  }

  accept(AstVisitor visitor) => visitor.visitAdjacentStrings(this);

  Token get beginToken => _strings.beginToken;

  Token get endToken => _strings.endToken;

  /**
   * Return the strings that are implicitly concatenated.
   *
   * @return the strings that are implicitly concatenated
   */
  NodeList<StringLiteral> get strings => _strings;

  void visitChildren(AstVisitor visitor) {
    _strings.accept(visitor);
  }

  void appendStringValue(JavaStringBuilder builder) {
    for (StringLiteral stringLiteral in strings) {
      stringLiteral.appendStringValue(builder);
    }
  }
}

/**
 * The abstract class `AnnotatedNode` defines the behavior of nodes that can be annotated with
 * both a comment and metadata.
 */
abstract class AnnotatedNode extends AstNode {
  /**
   * The documentation comment associated with this node, or `null` if this node does not have
   * a documentation comment associated with it.
   */
  Comment _comment;

  /**
   * The annotations associated with this node.
   */
  NodeList<Annotation> _metadata;

  /**
   * Initialize a newly created node.
   *
   * @param comment the documentation comment associated with this node
   * @param metadata the annotations associated with this node
   */
  AnnotatedNode(Comment comment, List<Annotation> metadata) {
    this._metadata = new NodeList<Annotation>(this);
    this._comment = becomeParentOf(comment);
    this._metadata.addAll(metadata);
  }

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
   * Return the documentation comment associated with this node, or `null` if this node does
   * not have a documentation comment associated with it.
   *
   * @return the documentation comment associated with this node
   */
  Comment get documentationComment => _comment;

  /**
   * Return the annotations associated with this node.
   *
   * @return the annotations associated with this node
   */
  NodeList<Annotation> get metadata => _metadata;

  /**
   * Set the documentation comment associated with this node to the given comment.
   *
   * @param comment the documentation comment to be associated with this node
   */
  void set documentationComment(Comment comment) {
    this._comment = becomeParentOf(comment);
  }

  /**
   * Set the metadata associated with this node to the given metadata.
   *
   * @param metadata the metadata to be associated with this node
   */
  void set metadata(List<Annotation> metadata) {
    this._metadata.clear();
    this._metadata.addAll(metadata);
  }

  void visitChildren(AstVisitor visitor) {
    if (commentIsBeforeAnnotations()) {
      safelyVisitChild(_comment, visitor);
      _metadata.accept(visitor);
    } else {
      for (AstNode child in sortedCommentAndAnnotations) {
        child.accept(visitor);
      }
    }
  }

  /**
   * Return the first token following the comment and metadata.
   *
   * @return the first token following the comment and metadata
   */
  Token get firstTokenAfterCommentAndMetadata;

  /**
   * Return `true` if the comment is lexically before any annotations.
   *
   * @return `true` if the comment is lexically before any annotations
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
   *
   * @return the comment and annotations associated with this node in the order in which they
   *         appeared in the original source
   */
  List<AstNode> get sortedCommentAndAnnotations {
    List<AstNode> childList = new List<AstNode>();
    childList.add(_comment);
    childList.addAll(_metadata);
    List<AstNode> children = new List.from(childList);
    children.sort(AstNode.LEXICAL_ORDER);
    return children;
  }
}

/**
 * Instances of the class `Annotation` represent an annotation that can be associated with an
 * AST node.
 *
 * <pre>
 * metadata ::=
 *     annotation*
 *
 * annotation ::=
 *     '@' [Identifier] ('.' [SimpleIdentifier])? [ArgumentList]?
 * </pre>
 */
class Annotation extends AstNode {
  /**
   * The at sign that introduced the annotation.
   */
  Token atSign;

  /**
   * The name of the class defining the constructor that is being invoked or the name of the field
   * that is being referenced.
   */
  Identifier _name;

  /**
   * The period before the constructor name, or `null` if this annotation is not the
   * invocation of a named constructor.
   */
  Token period;

  /**
   * The name of the constructor being invoked, or `null` if this annotation is not the
   * invocation of a named constructor.
   */
  SimpleIdentifier _constructorName;

  /**
   * The arguments to the constructor being invoked, or `null` if this annotation is not the
   * invocation of a constructor.
   */
  ArgumentList _arguments;

  /**
   * The element associated with this annotation, or `null` if the AST structure has not been
   * resolved or if this annotation could not be resolved.
   */
  Element _element;

  /**
   * Initialize a newly created annotation.
   *
   * @param atSign the at sign that introduced the annotation
   * @param name the name of the class defining the constructor that is being invoked or the name of
   *          the field that is being referenced
   * @param period the period before the constructor name, or `null` if this annotation is not
   *          the invocation of a named constructor
   * @param constructorName the name of the constructor being invoked, or `null` if this
   *          annotation is not the invocation of a named constructor
   * @param arguments the arguments to the constructor being invoked, or `null` if this
   *          annotation is not the invocation of a constructor
   */
  Annotation(this.atSign, Identifier name, this.period, SimpleIdentifier constructorName, ArgumentList arguments) {
    this._name = becomeParentOf(name);
    this._constructorName = becomeParentOf(constructorName);
    this._arguments = becomeParentOf(arguments);
  }

  accept(AstVisitor visitor) => visitor.visitAnnotation(this);

  /**
   * Return the arguments to the constructor being invoked, or `null` if this annotation is
   * not the invocation of a constructor.
   *
   * @return the arguments to the constructor being invoked
   */
  ArgumentList get arguments => _arguments;

  Token get beginToken => atSign;

  /**
   * Return the name of the constructor being invoked, or `null` if this annotation is not the
   * invocation of a named constructor.
   *
   * @return the name of the constructor being invoked
   */
  SimpleIdentifier get constructorName => _constructorName;

  /**
   * Return the element associated with this annotation, or `null` if the AST structure has
   * not been resolved or if this annotation could not be resolved.
   *
   * @return the element associated with this annotation
   */
  Element get element {
    if (_element != null) {
      return _element;
    }
    if (_name != null) {
      return _name.staticElement;
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
   *
   * @return the name of the constructor being invoked or the name of the field being referenced
   */
  Identifier get name => _name;

  /**
   * Set the arguments to the constructor being invoked to the given arguments.
   *
   * @param arguments the arguments to the constructor being invoked
   */
  void set arguments(ArgumentList arguments) {
    this._arguments = becomeParentOf(arguments);
  }

  /**
   * Set the name of the constructor being invoked to the given name.
   *
   * @param constructorName the name of the constructor being invoked
   */
  void set constructorName(SimpleIdentifier constructorName) {
    this._constructorName = becomeParentOf(constructorName);
  }

  /**
   * Set the element associated with this annotation based.
   *
   * @param element the element to be associated with this identifier
   */
  void set element(Element element) {
    this._element = element;
  }

  /**
   * Set the name of the class defining the constructor that is being invoked or the name of the
   * field that is being referenced to the given name.
   *
   * @param name the name of the constructor being invoked or the name of the field being referenced
   */
  void set name(Identifier name) {
    this._name = becomeParentOf(name);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_name, visitor);
    safelyVisitChild(_constructorName, visitor);
    safelyVisitChild(_arguments, visitor);
  }
}

/**
 * Instances of the class `ArgumentDefinitionTest` represent an argument definition test.
 *
 * <pre>
 * argumentDefinitionTest ::=
 *     '?' [SimpleIdentifier]
 * </pre>
 */
class ArgumentDefinitionTest extends Expression {
  /**
   * The token representing the question mark.
   */
  Token question;

  /**
   * The identifier representing the argument being tested.
   */
  SimpleIdentifier _identifier;

  /**
   * Initialize a newly created argument definition test.
   *
   * @param question the token representing the question mark
   * @param identifier the identifier representing the argument being tested
   */
  ArgumentDefinitionTest(this.question, SimpleIdentifier identifier) {
    this._identifier = becomeParentOf(identifier);
  }

  accept(AstVisitor visitor) => visitor.visitArgumentDefinitionTest(this);

  Token get beginToken => question;

  Token get endToken => _identifier.endToken;

  /**
   * Return the identifier representing the argument being tested.
   *
   * @return the identifier representing the argument being tested
   */
  SimpleIdentifier get identifier => _identifier;

  int get precedence => 15;

  /**
   * Set the identifier representing the argument being tested to the given identifier.
   *
   * @param identifier the identifier representing the argument being tested
   */
  void set identifier(SimpleIdentifier identifier) {
    this._identifier = becomeParentOf(identifier);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_identifier, visitor);
  }
}

/**
 * Instances of the class `ArgumentList` represent a list of arguments in the invocation of a
 * executable element: a function, method, or constructor.
 *
 * <pre>
 * argumentList ::=
 *     '(' arguments? ')'
 *
 * arguments ::=
 *     [NamedExpression] (',' [NamedExpression])*
 *   | [Expression] (',' [NamedExpression])*
 * </pre>
 */
class ArgumentList extends AstNode {
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
   * arguments in this list, or `null` if the AST has not been resolved or if the function or
   * method being invoked could not be determined based on static type information. The array must
   * be the same length as the number of arguments, but can contain `null` entries if a given
   * argument does not correspond to a formal parameter.
   */
  List<ParameterElement> _correspondingStaticParameters;

  /**
   * An array containing the elements representing the parameters corresponding to each of the
   * arguments in this list, or `null` if the AST has not been resolved or if the function or
   * method being invoked could not be determined based on propagated type information. The array
   * must be the same length as the number of arguments, but can contain `null` entries if a
   * given argument does not correspond to a formal parameter.
   */
  List<ParameterElement> _correspondingPropagatedParameters;

  /**
   * Initialize a newly created list of arguments.
   *
   * @param leftParenthesis the left parenthesis
   * @param arguments the expressions producing the values of the arguments
   * @param rightParenthesis the right parenthesis
   */
  ArgumentList(Token leftParenthesis, List<Expression> arguments, Token rightParenthesis) {
    this._arguments = new NodeList<Expression>(this);
    this._leftParenthesis = leftParenthesis;
    this._arguments.addAll(arguments);
    this._rightParenthesis = rightParenthesis;
  }

  accept(AstVisitor visitor) => visitor.visitArgumentList(this);

  /**
   * Return the expressions producing the values of the arguments. Although the language requires
   * that positional arguments appear before named arguments, this class allows them to be
   * intermixed.
   *
   * @return the expressions producing the values of the arguments
   */
  NodeList<Expression> get arguments => _arguments;

  Token get beginToken => _leftParenthesis;

  Token get endToken => _rightParenthesis;

  /**
   * Return the left parenthesis.
   *
   * @return the left parenthesis
   */
  Token get leftParenthesis => _leftParenthesis;

  /**
   * Return the right parenthesis.
   *
   * @return the right parenthesis
   */
  Token get rightParenthesis => _rightParenthesis;

  /**
   * Set the parameter elements corresponding to each of the arguments in this list to the given
   * array of parameters. The array of parameters must be the same length as the number of
   * arguments, but can contain `null` entries if a given argument does not correspond to a
   * formal parameter.
   *
   * @param parameters the parameter elements corresponding to the arguments
   */
  void set correspondingPropagatedParameters(List<ParameterElement> parameters) {
    if (parameters.length != _arguments.length) {
      throw new IllegalArgumentException("Expected ${_arguments.length} parameters, not ${parameters.length}");
    }
    _correspondingPropagatedParameters = parameters;
  }

  /**
   * Set the parameter elements corresponding to each of the arguments in this list to the given
   * array of parameters. The array of parameters must be the same length as the number of
   * arguments, but can contain `null` entries if a given argument does not correspond to a
   * formal parameter.
   *
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
   *
   * @param parenthesis the left parenthesis
   */
  void set leftParenthesis(Token parenthesis) {
    _leftParenthesis = parenthesis;
  }

  /**
   * Set the right parenthesis to the given token.
   *
   * @param parenthesis the right parenthesis
   */
  void set rightParenthesis(Token parenthesis) {
    _rightParenthesis = parenthesis;
  }

  void visitChildren(AstVisitor visitor) {
    _arguments.accept(visitor);
  }

  /**
   * If the given expression is a child of this list, and the AST structure has been resolved, and
   * the function being invoked is known based on propagated type information, and the expression
   * corresponds to one of the parameters of the function being invoked, then return the parameter
   * element representing the parameter to which the value of the given expression will be bound.
   * Otherwise, return `null`.
   *
   * This method is only intended to be used by [Expression#getPropagatedParameterElement].
   *
   * @param expression the expression corresponding to the parameter to be returned
   * @return the parameter element representing the parameter to which the value of the expression
   *         will be bound
   */
  ParameterElement getPropagatedParameterElementFor(Expression expression) {
    if (_correspondingPropagatedParameters == null) {
      // Either the AST structure has not been resolved or the invocation of which this list is a
      // part could not be resolved.
      return null;
    }
    int index = _arguments.indexOf(expression);
    if (index < 0) {
      // The expression isn't a child of this node.
      return null;
    }
    return _correspondingPropagatedParameters[index];
  }

  /**
   * If the given expression is a child of this list, and the AST structure has been resolved, and
   * the function being invoked is known based on static type information, and the expression
   * corresponds to one of the parameters of the function being invoked, then return the parameter
   * element representing the parameter to which the value of the given expression will be bound.
   * Otherwise, return `null`.
   *
   * This method is only intended to be used by [Expression#getStaticParameterElement].
   *
   * @param expression the expression corresponding to the parameter to be returned
   * @return the parameter element representing the parameter to which the value of the expression
   *         will be bound
   */
  ParameterElement getStaticParameterElementFor(Expression expression) {
    if (_correspondingStaticParameters == null) {
      // Either the AST structure has not been resolved or the invocation of which this list is a
      // part could not be resolved.
      return null;
    }
    int index = _arguments.indexOf(expression);
    if (index < 0) {
      // The expression isn't a child of this node.
      return null;
    }
    return _correspondingStaticParameters[index];
  }
}

/**
 * Instances of the class `AsExpression` represent an 'as' expression.
 *
 * <pre>
 * asExpression ::=
 *     [Expression] 'as' [TypeName]
 * </pre>
 */
class AsExpression extends Expression {
  /**
   * The expression used to compute the value being cast.
   */
  Expression _expression;

  /**
   * The as operator.
   */
  Token asOperator;

  /**
   * The name of the type being cast to.
   */
  TypeName _type;

  /**
   * Initialize a newly created as expression.
   *
   * @param expression the expression used to compute the value being cast
   * @param isOperator the is operator
   * @param type the name of the type being cast to
   */
  AsExpression(Expression expression, Token isOperator, TypeName type) {
    this._expression = becomeParentOf(expression);
    this.asOperator = isOperator;
    this._type = becomeParentOf(type);
  }

  accept(AstVisitor visitor) => visitor.visitAsExpression(this);

  Token get beginToken => _expression.beginToken;

  Token get endToken => _type.endToken;

  /**
   * Return the expression used to compute the value being cast.
   *
   * @return the expression used to compute the value being cast
   */
  Expression get expression => _expression;

  int get precedence => 7;

  /**
   * Return the name of the type being cast to.
   *
   * @return the name of the type being cast to
   */
  TypeName get type => _type;

  /**
   * Set the expression used to compute the value being cast to the given expression.
   *
   * @param expression the expression used to compute the value being cast
   */
  void set expression(Expression expression) {
    this._expression = becomeParentOf(expression);
  }

  /**
   * Set the name of the type being cast to to the given name.
   *
   * @param name the name of the type being cast to
   */
  void set type(TypeName name) {
    this._type = becomeParentOf(name);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_expression, visitor);
    safelyVisitChild(_type, visitor);
  }
}

/**
 * Instances of the class `AssertStatement` represent an assert statement.
 *
 * <pre>
 * assertStatement ::=
 *     'assert' '(' [Expression] ')' ';'
 * </pre>
 */
class AssertStatement extends Statement {
  /**
   * The token representing the 'assert' keyword.
   */
  Token keyword;

  /**
   * The left parenthesis.
   */
  Token leftParenthesis;

  /**
   * The condition that is being asserted to be `true`.
   */
  Expression _condition;

  /**
   * The right parenthesis.
   */
  Token rightParenthesis;

  /**
   * The semicolon terminating the statement.
   */
  Token semicolon;

  /**
   * Initialize a newly created assert statement.
   *
   * @param keyword the token representing the 'assert' keyword
   * @param leftParenthesis the left parenthesis
   * @param condition the condition that is being asserted to be `true`
   * @param rightParenthesis the right parenthesis
   * @param semicolon the semicolon terminating the statement
   */
  AssertStatement(this.keyword, this.leftParenthesis, Expression condition, this.rightParenthesis, this.semicolon) {
    this._condition = becomeParentOf(condition);
  }

  accept(AstVisitor visitor) => visitor.visitAssertStatement(this);

  Token get beginToken => keyword;

  /**
   * Return the condition that is being asserted to be `true`.
   *
   * @return the condition that is being asserted to be `true`
   */
  Expression get condition => _condition;

  Token get endToken => semicolon;

  /**
   * Set the condition that is being asserted to be `true` to the given expression.
   *
   * @param the condition that is being asserted to be `true`
   */
  void set condition(Expression condition) {
    this._condition = becomeParentOf(condition);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_condition, visitor);
  }
}

/**
 * Instances of the class `AssignmentExpression` represent an assignment expression.
 *
 * <pre>
 * assignmentExpression ::=
 *     [Expression] [Token] [Expression]
 * </pre>
 */
class AssignmentExpression extends Expression {
  /**
   * The expression used to compute the left hand side.
   */
  Expression _leftHandSide;

  /**
   * The assignment operator being applied.
   */
  Token operator;

  /**
   * The expression used to compute the right hand side.
   */
  Expression _rightHandSide;

  /**
   * The element associated with the operator based on the static type of the left-hand-side, or
   * `null` if the AST structure has not been resolved, if the operator is not a compound
   * operator, or if the operator could not be resolved.
   */
  MethodElement _staticElement;

  /**
   * The element associated with the operator based on the propagated type of the left-hand-side, or
   * `null` if the AST structure has not been resolved, if the operator is not a compound
   * operator, or if the operator could not be resolved.
   */
  MethodElement _propagatedElement;

  /**
   * Initialize a newly created assignment expression.
   *
   * @param leftHandSide the expression used to compute the left hand side
   * @param operator the assignment operator being applied
   * @param rightHandSide the expression used to compute the right hand side
   */
  AssignmentExpression(Expression leftHandSide, this.operator, Expression rightHandSide) {
    this._leftHandSide = becomeParentOf(leftHandSide);
    this._rightHandSide = becomeParentOf(rightHandSide);
  }

  accept(AstVisitor visitor) => visitor.visitAssignmentExpression(this);

  Token get beginToken => _leftHandSide.beginToken;

  /**
   * Return the best element available for this operator. If resolution was able to find a better
   * element based on type propagation, that element will be returned. Otherwise, the element found
   * using the result of static analysis will be returned. If resolution has not been performed,
   * then `null` will be returned.
   *
   * @return the best element available for this operator
   */
  MethodElement get bestElement {
    MethodElement element = propagatedElement;
    if (element == null) {
      element = staticElement;
    }
    return element;
  }

  Token get endToken => _rightHandSide.endToken;

  /**
   * Set the expression used to compute the left hand side to the given expression.
   *
   * @return the expression used to compute the left hand side
   */
  Expression get leftHandSide => _leftHandSide;

  int get precedence => 1;

  /**
   * Return the element associated with the operator based on the propagated type of the
   * left-hand-side, or `null` if the AST structure has not been resolved, if the operator is
   * not a compound operator, or if the operator could not be resolved. One example of the latter
   * case is an operator that is not defined for the type of the left-hand operand.
   *
   * @return the element associated with the operator
   */
  MethodElement get propagatedElement => _propagatedElement;

  /**
   * Return the expression used to compute the right hand side.
   *
   * @return the expression used to compute the right hand side
   */
  Expression get rightHandSide => _rightHandSide;

  /**
   * Return the element associated with the operator based on the static type of the left-hand-side,
   * or `null` if the AST structure has not been resolved, if the operator is not a compound
   * operator, or if the operator could not be resolved. One example of the latter case is an
   * operator that is not defined for the type of the left-hand operand.
   *
   * @return the element associated with the operator
   */
  MethodElement get staticElement => _staticElement;

  /**
   * Return the expression used to compute the left hand side.
   *
   * @param expression the expression used to compute the left hand side
   */
  void set leftHandSide(Expression expression) {
    _leftHandSide = becomeParentOf(expression);
  }

  /**
   * Set the element associated with the operator based on the propagated type of the left-hand-side
   * to the given element.
   *
   * @param element the element to be associated with the operator
   */
  void set propagatedElement(MethodElement element) {
    _propagatedElement = element;
  }

  /**
   * Set the expression used to compute the left hand side to the given expression.
   *
   * @param expression the expression used to compute the left hand side
   */
  void set rightHandSide(Expression expression) {
    _rightHandSide = becomeParentOf(expression);
  }

  /**
   * Set the element associated with the operator based on the static type of the left-hand-side to
   * the given element.
   *
   * @param element the static element to be associated with the operator
   */
  void set staticElement(MethodElement element) {
    _staticElement = element;
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_leftHandSide, visitor);
    safelyVisitChild(_rightHandSide, visitor);
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is known based on
   * propagated type information, then return the parameter element representing the parameter to
   * which the value of the right operand will be bound. Otherwise, return `null`.
   *
   * This method is only intended to be used by [Expression#getPropagatedParameterElement].
   *
   * @return the parameter element representing the parameter to which the value of the right
   *         operand will be bound
   */
  ParameterElement get propagatedParameterElementForRightHandSide {
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
   * value of the right operand will be bound. Otherwise, return `null`.
   *
   * This method is only intended to be used by [Expression#getStaticParameterElement].
   *
   * @return the parameter element representing the parameter to which the value of the right
   *         operand will be bound
   */
  ParameterElement get staticParameterElementForRightHandSide {
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
 * The abstract class `AstNode` defines the behavior common to all nodes in the AST structure
 * for a Dart program.
 */
abstract class AstNode {
  /**
   * An empty array of ast nodes.
   */
  static List<AstNode> EMPTY_ARRAY = new List<AstNode>(0);

  /**
   * The parent of the node, or `null` if the node is the root of an AST structure.
   */
  AstNode _parent;

  /**
   * A table mapping the names of properties to their values, or `null` if this node does not
   * have any properties associated with it.
   */
  Map<String, Object> _propertyMap;

  /**
   * A comparator that can be used to sort AST nodes in lexical order. In other words,
   * `compare` will return a negative value if the offset of the first node is less than the
   * offset of the second node, zero (0) if the nodes have the same offset, and a positive value if
   * if the offset of the first node is greater than the offset of the second node.
   */
  static Comparator<AstNode> LEXICAL_ORDER = (AstNode first, AstNode second) => second.offset - first.offset;

  /**
   * Use the given visitor to visit this node.
   *
   * @param visitor the visitor that will visit this node
   * @return the value returned by the visitor as a result of visiting this node
   */
  accept(AstVisitor visitor);

  /**
   * Return the node of the given class that most immediately encloses this node, or `null` if
   * there is no enclosing node of the given class.
   *
   * @param nodeClass the class of the node to be returned
   * @return the node of the given type that encloses this node
   */
  AstNode getAncestor(Predicate<AstNode> predicate) {
    AstNode node = this;
    while (node != null && !predicate(node)) {
      node = node.parent;
    }
    return node;
  }

  /**
   * Return the first token included in this node's source range.
   *
   * @return the first token included in this node's source range
   */
  Token get beginToken;

  /**
   * Return the offset of the character immediately following the last character of this node's
   * source range. This is equivalent to `node.getOffset() + node.getLength()`. For a
   * compilation unit this will be equal to the length of the unit's source. For synthetic nodes
   * this will be equivalent to the node's offset (because the length is zero (0) by definition).
   *
   * @return the offset of the character just past the node's source range
   */
  int get end => offset + length;

  /**
   * Return the last token included in this node's source range.
   *
   * @return the last token included in this node's source range
   */
  Token get endToken;

  /**
   * Return the number of characters in the node's source range.
   *
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
   *
   * @return the offset from the beginning of the file to the first character in the node's source
   *         range
   */
  int get offset {
    Token beginToken = this.beginToken;
    if (beginToken == null) {
      return -1;
    }
    return beginToken.offset;
  }

  /**
   * Return this node's parent node, or `null` if this node is the root of an AST structure.
   *
   * Note that the relationship between an AST node and its parent node may change over the lifetime
   * of a node.
   *
   * @return the parent of this node, or `null` if none
   */
  AstNode get parent => _parent;

  /**
   * Return the value of the property with the given name, or `null` if this node does not
   * have a property with the given name.
   *
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
   *
   * @return the node at the root of this node's AST structure
   */
  AstNode get root {
    AstNode root = this;
    AstNode parent = this.parent;
    while (parent != null) {
      root = parent;
      parent = root.parent;
    }
    return root;
  }

  /**
   * Return `true` if this node is a synthetic node. A synthetic node is a node that was
   * introduced by the parser in order to recover from an error in the code. Synthetic nodes always
   * have a length of zero (`0`).
   *
   * @return `true` if this node is a synthetic node
   */
  bool get isSynthetic => false;

  /**
   * Set the value of the property with the given name to the given value. If the value is
   * `null`, the property will effectively be removed.
   *
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
   *
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
   *
   * @param visitor the visitor that will be used to visit the children of this node
   */
  void visitChildren(AstVisitor visitor);

  /**
   * Make this node the parent of the given child node.
   *
   * @param child the node that will become a child of this node
   * @return the node that was made a child of this node
   */
  AstNode becomeParentOf(AstNode child) {
    if (child != null) {
      AstNode node = child;
      node.parent = this;
    }
    return child;
  }

  /**
   * If the given child is not `null`, use the given visitor to visit it.
   *
   * @param child the child to be visited
   * @param visitor the visitor that will be used to visit the child
   */
  void safelyVisitChild(AstNode child, AstVisitor visitor) {
    if (child != null) {
      child.accept(visitor);
    }
  }

  /**
   * Set the parent of this node to the given node.
   *
   * @param newParent the node that is to be made the parent of this node
   */
  void set parent(AstNode newParent) {
    _parent = newParent;
  }
}

/**
 * The interface `AstVisitor` defines the behavior of objects that can be used to visit an AST
 * structure.
 */
abstract class AstVisitor<R> {
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
}

/**
 * Instances of the class `BinaryExpression` represent a binary (infix) expression.
 *
 * <pre>
 * binaryExpression ::=
 *     [Expression] [Token] [Expression]
 * </pre>
 */
class BinaryExpression extends Expression {
  /**
   * The expression used to compute the left operand.
   */
  Expression _leftOperand;

  /**
   * The binary operator being applied.
   */
  Token operator;

  /**
   * The expression used to compute the right operand.
   */
  Expression _rightOperand;

  /**
   * The element associated with the operator based on the static type of the left operand, or
   * `null` if the AST structure has not been resolved, if the operator is not user definable,
   * or if the operator could not be resolved.
   */
  MethodElement _staticElement;

  /**
   * The element associated with the operator based on the propagated type of the left operand, or
   * `null` if the AST structure has not been resolved, if the operator is not user definable,
   * or if the operator could not be resolved.
   */
  MethodElement _propagatedElement;

  /**
   * Initialize a newly created binary expression.
   *
   * @param leftOperand the expression used to compute the left operand
   * @param operator the binary operator being applied
   * @param rightOperand the expression used to compute the right operand
   */
  BinaryExpression(Expression leftOperand, this.operator, Expression rightOperand) {
    this._leftOperand = becomeParentOf(leftOperand);
    this._rightOperand = becomeParentOf(rightOperand);
  }

  accept(AstVisitor visitor) => visitor.visitBinaryExpression(this);

  Token get beginToken => _leftOperand.beginToken;

  /**
   * Return the best element available for this operator. If resolution was able to find a better
   * element based on type propagation, that element will be returned. Otherwise, the element found
   * using the result of static analysis will be returned. If resolution has not been performed,
   * then `null` will be returned.
   *
   * @return the best element available for this operator
   */
  MethodElement get bestElement {
    MethodElement element = propagatedElement;
    if (element == null) {
      element = staticElement;
    }
    return element;
  }

  Token get endToken => _rightOperand.endToken;

  /**
   * Return the expression used to compute the left operand.
   *
   * @return the expression used to compute the left operand
   */
  Expression get leftOperand => _leftOperand;

  int get precedence => operator.type.precedence;

  /**
   * Return the element associated with the operator based on the propagated type of the left
   * operand, or `null` if the AST structure has not been resolved, if the operator is not
   * user definable, or if the operator could not be resolved. One example of the latter case is an
   * operator that is not defined for the type of the left-hand operand.
   *
   * @return the element associated with the operator
   */
  MethodElement get propagatedElement => _propagatedElement;

  /**
   * Return the expression used to compute the right operand.
   *
   * @return the expression used to compute the right operand
   */
  Expression get rightOperand => _rightOperand;

  /**
   * Return the element associated with the operator based on the static type of the left operand,
   * or `null` if the AST structure has not been resolved, if the operator is not user
   * definable, or if the operator could not be resolved. One example of the latter case is an
   * operator that is not defined for the type of the left operand.
   *
   * @return the element associated with the operator
   */
  MethodElement get staticElement => _staticElement;

  /**
   * Set the expression used to compute the left operand to the given expression.
   *
   * @param expression the expression used to compute the left operand
   */
  void set leftOperand(Expression expression) {
    _leftOperand = becomeParentOf(expression);
  }

  /**
   * Set the element associated with the operator based on the propagated type of the left operand
   * to the given element.
   *
   * @param element the element to be associated with the operator
   */
  void set propagatedElement(MethodElement element) {
    _propagatedElement = element;
  }

  /**
   * Set the expression used to compute the right operand to the given expression.
   *
   * @param expression the expression used to compute the right operand
   */
  void set rightOperand(Expression expression) {
    _rightOperand = becomeParentOf(expression);
  }

  /**
   * Set the element associated with the operator based on the static type of the left operand to
   * the given element.
   *
   * @param element the static element to be associated with the operator
   */
  void set staticElement(MethodElement element) {
    _staticElement = element;
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_leftOperand, visitor);
    safelyVisitChild(_rightOperand, visitor);
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is known based on
   * propagated type information, then return the parameter element representing the parameter to
   * which the value of the right operand will be bound. Otherwise, return `null`.
   *
   * This method is only intended to be used by [Expression#getPropagatedParameterElement].
   *
   * @return the parameter element representing the parameter to which the value of the right
   *         operand will be bound
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
   * value of the right operand will be bound. Otherwise, return `null`.
   *
   * This method is only intended to be used by [Expression#getStaticParameterElement].
   *
   * @return the parameter element representing the parameter to which the value of the right
   *         operand will be bound
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
 * Instances of the class `Block` represent a sequence of statements.
 *
 * <pre>
 * block ::=
 *     '{' statement* '}'
 * </pre>
 */
class Block extends Statement {
  /**
   * The left curly bracket.
   */
  Token leftBracket;

  /**
   * The statements contained in the block.
   */
  NodeList<Statement> _statements;

  /**
   * The right curly bracket.
   */
  Token rightBracket;

  /**
   * Initialize a newly created block of code.
   *
   * @param leftBracket the left curly bracket
   * @param statements the statements contained in the block
   * @param rightBracket the right curly bracket
   */
  Block(this.leftBracket, List<Statement> statements, this.rightBracket) {
    this._statements = new NodeList<Statement>(this);
    this._statements.addAll(statements);
  }

  accept(AstVisitor visitor) => visitor.visitBlock(this);

  Token get beginToken => leftBracket;

  Token get endToken => rightBracket;

  /**
   * Return the statements contained in the block.
   *
   * @return the statements contained in the block
   */
  NodeList<Statement> get statements => _statements;

  void visitChildren(AstVisitor visitor) {
    _statements.accept(visitor);
  }
}

/**
 * Instances of the class `BlockFunctionBody` represent a function body that consists of a
 * block of statements.
 *
 * <pre>
 * blockFunctionBody ::=
 *     [Block]
 * </pre>
 */
class BlockFunctionBody extends FunctionBody {
  /**
   * The block representing the body of the function.
   */
  Block _block;

  /**
   * Initialize a newly created function body consisting of a block of statements.
   *
   * @param block the block representing the body of the function
   */
  BlockFunctionBody(Block block) {
    this._block = becomeParentOf(block);
  }

  accept(AstVisitor visitor) => visitor.visitBlockFunctionBody(this);

  Token get beginToken => _block.beginToken;

  /**
   * Return the block representing the body of the function.
   *
   * @return the block representing the body of the function
   */
  Block get block => _block;

  Token get endToken => _block.endToken;

  /**
   * Set the block representing the body of the function to the given block.
   *
   * @param block the block representing the body of the function
   */
  void set block(Block block) {
    this._block = becomeParentOf(block);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_block, visitor);
  }
}

/**
 * Instances of the class `BooleanLiteral` represent a boolean literal expression.
 *
 * <pre>
 * booleanLiteral ::=
 *     'false' | 'true'
 * </pre>
 */
class BooleanLiteral extends Literal {
  /**
   * The token representing the literal.
   */
  Token literal;

  /**
   * The value of the literal.
   */
  bool value = false;

  /**
   * Initialize a newly created boolean literal.
   *
   * @param literal the token representing the literal
   * @param value the value of the literal
   */
  BooleanLiteral(this.literal, this.value);

  accept(AstVisitor visitor) => visitor.visitBooleanLiteral(this);

  Token get beginToken => literal;

  Token get endToken => literal;

  bool get isSynthetic => literal.isSynthetic;

  void visitChildren(AstVisitor visitor) {
  }
}

/**
 * Instances of the class `BreakStatement` represent a break statement.
 *
 * <pre>
 * breakStatement ::=
 *     'break' [SimpleIdentifier]? ';'
 * </pre>
 */
class BreakStatement extends Statement {
  /**
   * The token representing the 'break' keyword.
   */
  Token keyword;

  /**
   * The label associated with the statement, or `null` if there is no label.
   */
  SimpleIdentifier _label;

  /**
   * The semicolon terminating the statement.
   */
  Token semicolon;

  /**
   * Initialize a newly created break statement.
   *
   * @param keyword the token representing the 'break' keyword
   * @param label the label associated with the statement
   * @param semicolon the semicolon terminating the statement
   */
  BreakStatement(this.keyword, SimpleIdentifier label, this.semicolon) {
    this._label = becomeParentOf(label);
  }

  accept(AstVisitor visitor) => visitor.visitBreakStatement(this);

  Token get beginToken => keyword;

  Token get endToken => semicolon;

  /**
   * Return the label associated with the statement, or `null` if there is no label.
   *
   * @return the label associated with the statement
   */
  SimpleIdentifier get label => _label;

  /**
   * Set the label associated with the statement to the given identifier.
   *
   * @param identifier the label associated with the statement
   */
  void set label(SimpleIdentifier identifier) {
    _label = becomeParentOf(identifier);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_label, visitor);
  }
}

/**
 * Instances of the class `CascadeExpression` represent a sequence of cascaded expressions:
 * expressions that share a common target. There are three kinds of expressions that can be used in
 * a cascade expression: [IndexExpression], [MethodInvocation] and
 * [PropertyAccess].
 *
 * <pre>
 * cascadeExpression ::=
 *     [Expression] cascadeSection*
 *
 * cascadeSection ::=
 *     '..'  (cascadeSelector arguments*) (assignableSelector arguments*)* (assignmentOperator expressionWithoutCascade)?
 *
 * cascadeSelector ::=
 *     '[ ' expression '] '
 *   | identifier
 * </pre>
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
   *
   * @param target the target of the cascade sections
   * @param cascadeSections the cascade sections sharing the common target
   */
  CascadeExpression(Expression target, List<Expression> cascadeSections) {
    this._cascadeSections = new NodeList<Expression>(this);
    this._target = becomeParentOf(target);
    this._cascadeSections.addAll(cascadeSections);
  }

  accept(AstVisitor visitor) => visitor.visitCascadeExpression(this);

  Token get beginToken => _target.beginToken;

  /**
   * Return the cascade sections sharing the common target.
   *
   * @return the cascade sections sharing the common target
   */
  NodeList<Expression> get cascadeSections => _cascadeSections;

  Token get endToken => _cascadeSections.endToken;

  int get precedence => 2;

  /**
   * Return the target of the cascade sections.
   *
   * @return the target of the cascade sections
   */
  Expression get target => _target;

  /**
   * Set the target of the cascade sections to the given expression.
   *
   * @param target the target of the cascade sections
   */
  void set target(Expression target) {
    this._target = becomeParentOf(target);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_target, visitor);
    _cascadeSections.accept(visitor);
  }
}

/**
 * Instances of the class `CatchClause` represent a catch clause within a try statement.
 *
 * <pre>
 * onPart ::=
 *     catchPart [Block]
 *   | 'on' type catchPart? [Block]
 *
 * catchPart ::=
 *     'catch' '(' [SimpleIdentifier] (',' [SimpleIdentifier])? ')'
 * </pre>
 */
class CatchClause extends AstNode {
  /**
   * The token representing the 'on' keyword, or `null` if there is no 'on' keyword.
   */
  Token onKeyword;

  /**
   * The type of exceptions caught by this catch clause, or `null` if this catch clause
   * catches every type of exception.
   */
  TypeName exceptionType;

  /**
   * The token representing the 'catch' keyword, or `null` if there is no 'catch' keyword.
   */
  Token catchKeyword;

  /**
   * The left parenthesis.
   */
  Token _leftParenthesis;

  /**
   * The parameter whose value will be the exception that was thrown.
   */
  SimpleIdentifier _exceptionParameter;

  /**
   * The comma separating the exception parameter from the stack trace parameter, or `null` if
   * there is no stack trace parameter.
   */
  Token comma;

  /**
   * The parameter whose value will be the stack trace associated with the exception, or
   * `null` if there is no stack trace parameter.
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
   *
   * @param onKeyword the token representing the 'on' keyword
   * @param exceptionType the type of exceptions caught by this catch clause
   * @param leftParenthesis the left parenthesis
   * @param exceptionParameter the parameter whose value will be the exception that was thrown
   * @param comma the comma separating the exception parameter from the stack trace parameter
   * @param stackTraceParameter the parameter whose value will be the stack trace associated with
   *          the exception
   * @param rightParenthesis the right parenthesis
   * @param body the body of the catch block
   */
  CatchClause(this.onKeyword, TypeName exceptionType, this.catchKeyword, Token leftParenthesis, SimpleIdentifier exceptionParameter, this.comma, SimpleIdentifier stackTraceParameter, Token rightParenthesis, Block body) {
    this.exceptionType = becomeParentOf(exceptionType);
    this._leftParenthesis = leftParenthesis;
    this._exceptionParameter = becomeParentOf(exceptionParameter);
    this._stackTraceParameter = becomeParentOf(stackTraceParameter);
    this._rightParenthesis = rightParenthesis;
    this._body = becomeParentOf(body);
  }

  accept(AstVisitor visitor) => visitor.visitCatchClause(this);

  Token get beginToken {
    if (onKeyword != null) {
      return onKeyword;
    }
    return catchKeyword;
  }

  /**
   * Return the body of the catch block.
   *
   * @return the body of the catch block
   */
  Block get body => _body;

  Token get endToken => _body.endToken;

  /**
   * Return the parameter whose value will be the exception that was thrown.
   *
   * @return the parameter whose value will be the exception that was thrown
   */
  SimpleIdentifier get exceptionParameter => _exceptionParameter;

  /**
   * Return the left parenthesis.
   *
   * @return the left parenthesis
   */
  Token get leftParenthesis => _leftParenthesis;

  /**
   * Return the right parenthesis.
   *
   * @return the right parenthesis
   */
  Token get rightParenthesis => _rightParenthesis;

  /**
   * Return the parameter whose value will be the stack trace associated with the exception, or
   * `null` if there is no stack trace parameter.
   *
   * @return the parameter whose value will be the stack trace associated with the exception
   */
  SimpleIdentifier get stackTraceParameter => _stackTraceParameter;

  /**
   * Set the body of the catch block to the given block.
   *
   * @param block the body of the catch block
   */
  void set body(Block block) {
    _body = becomeParentOf(block);
  }

  /**
   * Set the parameter whose value will be the exception that was thrown to the given parameter.
   *
   * @param parameter the parameter whose value will be the exception that was thrown
   */
  void set exceptionParameter(SimpleIdentifier parameter) {
    _exceptionParameter = becomeParentOf(parameter);
  }

  /**
   * Set the left parenthesis to the given token.
   *
   * @param parenthesis the left parenthesis
   */
  void set leftParenthesis(Token parenthesis) {
    _leftParenthesis = parenthesis;
  }

  /**
   * Set the right parenthesis to the given token.
   *
   * @param parenthesis the right parenthesis
   */
  void set rightParenthesis(Token parenthesis) {
    _rightParenthesis = parenthesis;
  }

  /**
   * Set the parameter whose value will be the stack trace associated with the exception to the
   * given parameter.
   *
   * @param parameter the parameter whose value will be the stack trace associated with the
   *          exception
   */
  void set stackTraceParameter(SimpleIdentifier parameter) {
    _stackTraceParameter = becomeParentOf(parameter);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(exceptionType, visitor);
    safelyVisitChild(_exceptionParameter, visitor);
    safelyVisitChild(_stackTraceParameter, visitor);
    safelyVisitChild(_body, visitor);
  }
}

/**
 * Instances of the class `ClassDeclaration` represent the declaration of a class.
 *
 * <pre>
 * classDeclaration ::=
 *     'abstract'? 'class' [SimpleIdentifier] [TypeParameterList]?
 *     ([ExtendsClause] [WithClause]?)?
 *     [ImplementsClause]?
 *     '{' [ClassMember]* '}'
 * </pre>
 */
class ClassDeclaration extends CompilationUnitMember {
  /**
   * The 'abstract' keyword, or `null` if the keyword was absent.
   */
  Token abstractKeyword;

  /**
   * The token representing the 'class' keyword.
   */
  Token classKeyword;

  /**
   * The name of the class being declared.
   */
  SimpleIdentifier _name;

  /**
   * The type parameters for the class, or `null` if the class does not have any type
   * parameters.
   */
  TypeParameterList typeParameters;

  /**
   * The extends clause for the class, or `null` if the class does not extend any other class.
   */
  ExtendsClause _extendsClause;

  /**
   * The with clause for the class, or `null` if the class does not have a with clause.
   */
  WithClause _withClause;

  /**
   * The implements clause for the class, or `null` if the class does not implement any
   * interfaces.
   */
  ImplementsClause _implementsClause;

  /**
   * The native clause for the class, or `null` if the class does not have a native clause.
   */
  NativeClause nativeClause;

  /**
   * The left curly bracket.
   */
  Token leftBracket;

  /**
   * The members defined by the class.
   */
  NodeList<ClassMember> _members;

  /**
   * The right curly bracket.
   */
  Token rightBracket;

  /**
   * Initialize a newly created class declaration.
   *
   * @param comment the documentation comment associated with this class
   * @param metadata the annotations associated with this class
   * @param abstractKeyword the 'abstract' keyword, or `null` if the keyword was absent
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
  ClassDeclaration(Comment comment, List<Annotation> metadata, this.abstractKeyword, this.classKeyword, SimpleIdentifier name, TypeParameterList typeParameters, ExtendsClause extendsClause, WithClause withClause, ImplementsClause implementsClause, this.leftBracket, List<ClassMember> members, this.rightBracket) : super(comment, metadata) {
    this._members = new NodeList<ClassMember>(this);
    this._name = becomeParentOf(name);
    this.typeParameters = becomeParentOf(typeParameters);
    this._extendsClause = becomeParentOf(extendsClause);
    this._withClause = becomeParentOf(withClause);
    this._implementsClause = becomeParentOf(implementsClause);
    this._members.addAll(members);
  }

  accept(AstVisitor visitor) => visitor.visitClassDeclaration(this);

  /**
   * Return the constructor declared in the class with the given name.
   *
   * @param name the name of the constructor to find, `null` for default
   * @return the found constructor or `null` if not found
   */
  ConstructorDeclaration getConstructor(String name) {
    for (ClassMember classMember in _members) {
      if (classMember is ConstructorDeclaration) {
        ConstructorDeclaration constructor = classMember;
        SimpleIdentifier constructorName = constructor.name;
        if (name == null && constructorName == null) {
          return constructor;
        }
        if (constructorName != null && constructorName.name == name) {
          return constructor;
        }
      }
    }
    return null;
  }

  ClassElement get element => _name != null ? (_name.staticElement as ClassElement) : null;

  Token get endToken => rightBracket;

  /**
   * Return the extends clause for this class, or `null` if the class does not extend any
   * other class.
   *
   * @return the extends clause for this class
   */
  ExtendsClause get extendsClause => _extendsClause;

  /**
   * Return the field declared in the class with the given name.
   *
   * @param name the name of the field to find
   * @return the found field or `null` if not found
   */
  VariableDeclaration getField(String name) {
    for (ClassMember classMember in _members) {
      if (classMember is FieldDeclaration) {
        FieldDeclaration fieldDeclaration = classMember;
        NodeList<VariableDeclaration> fields = fieldDeclaration.fields.variables;
        for (VariableDeclaration field in fields) {
          SimpleIdentifier fieldName = field.name;
          if (fieldName != null && name == fieldName.name) {
            return field;
          }
        }
      }
    }
    return null;
  }

  /**
   * Return the implements clause for the class, or `null` if the class does not implement any
   * interfaces.
   *
   * @return the implements clause for the class
   */
  ImplementsClause get implementsClause => _implementsClause;

  /**
   * Return the members defined by the class.
   *
   * @return the members defined by the class
   */
  NodeList<ClassMember> get members => _members;

  /**
   * Return the method declared in the class with the given name.
   *
   * @param name the name of the method to find
   * @return the found method or `null` if not found
   */
  MethodDeclaration getMethod(String name) {
    for (ClassMember classMember in _members) {
      if (classMember is MethodDeclaration) {
        MethodDeclaration method = classMember;
        SimpleIdentifier methodName = method.name;
        if (methodName != null && name == methodName.name) {
          return method;
        }
      }
    }
    return null;
  }

  /**
   * Return the name of the class being declared.
   *
   * @return the name of the class being declared
   */
  SimpleIdentifier get name => _name;

  /**
   * Return the with clause for the class, or `null` if the class does not have a with clause.
   *
   * @return the with clause for the class
   */
  WithClause get withClause => _withClause;

  /**
   * Set the extends clause for this class to the given clause.
   *
   * @param extendsClause the extends clause for this class
   */
  void set extendsClause(ExtendsClause extendsClause) {
    this._extendsClause = becomeParentOf(extendsClause);
  }

  /**
   * Set the implements clause for the class to the given clause.
   *
   * @param implementsClause the implements clause for the class
   */
  void set implementsClause(ImplementsClause implementsClause) {
    this._implementsClause = becomeParentOf(implementsClause);
  }

  /**
   * Set the name of the class being declared to the given identifier.
   *
   * @param identifier the name of the class being declared
   */
  void set name(SimpleIdentifier identifier) {
    _name = becomeParentOf(identifier);
  }

  /**
   * Set the with clause for the class to the given clause.
   *
   * @param withClause the with clause for the class
   */
  void set withClause(WithClause withClause) {
    this._withClause = becomeParentOf(withClause);
  }

  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_name, visitor);
    safelyVisitChild(typeParameters, visitor);
    safelyVisitChild(_extendsClause, visitor);
    safelyVisitChild(_withClause, visitor);
    safelyVisitChild(_implementsClause, visitor);
    safelyVisitChild(nativeClause, visitor);
    members.accept(visitor);
  }

  Token get firstTokenAfterCommentAndMetadata {
    if (abstractKeyword != null) {
      return abstractKeyword;
    }
    return classKeyword;
  }
}

/**
 * The abstract class `ClassMember` defines the behavior common to nodes that declare a name
 * within the scope of a class.
 */
abstract class ClassMember extends Declaration {
  /**
   * Initialize a newly created member of a class.
   *
   * @param comment the documentation comment associated with this member
   * @param metadata the annotations associated with this member
   */
  ClassMember(Comment comment, List<Annotation> metadata) : super(comment, metadata);
}

/**
 * Instances of the class `ClassTypeAlias` represent a class type alias.
 *
 * <pre>
 * classTypeAlias ::=
 *     [SimpleIdentifier] [TypeParameterList]? '=' 'abstract'? mixinApplication
 *
 * mixinApplication ::=
 *     [TypeName] [WithClause] [ImplementsClause]? ';'
 * </pre>
 */
class ClassTypeAlias extends TypeAlias {
  /**
   * The name of the class being declared.
   */
  SimpleIdentifier _name;

  /**
   * The type parameters for the class, or `null` if the class does not have any type
   * parameters.
   */
  TypeParameterList _typeParameters;

  /**
   * The token for the '=' separating the name from the definition.
   */
  Token equals;

  /**
   * The token for the 'abstract' keyword, or `null` if this is not defining an abstract
   * class.
   */
  Token abstractKeyword;

  /**
   * The name of the superclass of the class being declared.
   */
  TypeName _superclass;

  /**
   * The with clause for this class.
   */
  WithClause _withClause;

  /**
   * The implements clause for this class, or `null` if there is no implements clause.
   */
  ImplementsClause _implementsClause;

  /**
   * Initialize a newly created class type alias.
   *
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
  ClassTypeAlias(Comment comment, List<Annotation> metadata, Token keyword, SimpleIdentifier name, TypeParameterList typeParameters, this.equals, this.abstractKeyword, TypeName superclass, WithClause withClause, ImplementsClause implementsClause, Token semicolon) : super(comment, metadata, keyword, semicolon) {
    this._name = becomeParentOf(name);
    this._typeParameters = becomeParentOf(typeParameters);
    this._superclass = becomeParentOf(superclass);
    this._withClause = becomeParentOf(withClause);
    this._implementsClause = becomeParentOf(implementsClause);
  }

  accept(AstVisitor visitor) => visitor.visitClassTypeAlias(this);

  ClassElement get element => _name != null ? (_name.staticElement as ClassElement) : null;

  /**
   * Return the implements clause for this class, or `null` if there is no implements clause.
   *
   * @return the implements clause for this class
   */
  ImplementsClause get implementsClause => _implementsClause;

  /**
   * Return the name of the class being declared.
   *
   * @return the name of the class being declared
   */
  SimpleIdentifier get name => _name;

  /**
   * Return the name of the superclass of the class being declared.
   *
   * @return the name of the superclass of the class being declared
   */
  TypeName get superclass => _superclass;

  /**
   * Return the type parameters for the class, or `null` if the class does not have any type
   * parameters.
   *
   * @return the type parameters for the class
   */
  TypeParameterList get typeParameters => _typeParameters;

  /**
   * Return the with clause for this class.
   *
   * @return the with clause for this class
   */
  WithClause get withClause => _withClause;

  /**
   * Set the implements clause for this class to the given implements clause.
   *
   * @param implementsClause the implements clause for this class
   */
  void set implementsClause(ImplementsClause implementsClause) {
    this._implementsClause = becomeParentOf(implementsClause);
  }

  /**
   * Set the name of the class being declared to the given identifier.
   *
   * @param name the name of the class being declared
   */
  void set name(SimpleIdentifier name) {
    this._name = becomeParentOf(name);
  }

  /**
   * Set the name of the superclass of the class being declared to the given name.
   *
   * @param superclass the name of the superclass of the class being declared
   */
  void set superclass(TypeName superclass) {
    this._superclass = becomeParentOf(superclass);
  }

  /**
   * Set the type parameters for the class to the given list of parameters.
   *
   * @param typeParameters the type parameters for the class
   */
  void set typeParameters(TypeParameterList typeParameters) {
    this._typeParameters = becomeParentOf(typeParameters);
  }

  /**
   * Set the with clause for this class to the given with clause.
   *
   * @param withClause the with clause for this class
   */
  void set withClause(WithClause withClause) {
    this._withClause = becomeParentOf(withClause);
  }

  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_name, visitor);
    safelyVisitChild(_typeParameters, visitor);
    safelyVisitChild(_superclass, visitor);
    safelyVisitChild(_withClause, visitor);
    safelyVisitChild(_implementsClause, visitor);
  }
}

/**
 * Instances of the class `Combinator` represent the combinator associated with an import
 * directive.
 *
 * <pre>
 * combinator ::=
 *     [HideCombinator]
 *   | [ShowCombinator]
 * </pre>
 */
abstract class Combinator extends AstNode {
  /**
   * The keyword specifying what kind of processing is to be done on the imported names.
   */
  Token keyword;

  /**
   * Initialize a newly created import combinator.
   *
   * @param keyword the keyword specifying what kind of processing is to be done on the imported
   *          names
   */
  Combinator(this.keyword);

  Token get beginToken => keyword;
}

/**
 * Instances of the class `Comment` represent a comment within the source code.
 *
 * <pre>
 * comment ::=
 *     endOfLineComment
 *   | blockComment
 *   | documentationComment
 *
 * endOfLineComment ::=
 *     '//' (CHARACTER - EOL)* EOL
 *
 * blockComment ::=
 *     '/ *' CHARACTER* '&#42;/'
 *
 * documentationComment ::=
 *     '/ **' (CHARACTER | [CommentReference])* '&#42;/'
 *   | ('///' (CHARACTER - EOL)* EOL)+
 * </pre>
 */
class Comment extends AstNode {
  /**
   * Create a block comment.
   *
   * @param tokens the tokens representing the comment
   * @return the block comment that was created
   */
  static Comment createBlockComment(List<Token> tokens) => new Comment(tokens, CommentType.BLOCK, null);

  /**
   * Create a documentation comment.
   *
   * @param tokens the tokens representing the comment
   * @return the documentation comment that was created
   */
  static Comment createDocumentationComment(List<Token> tokens) => new Comment(tokens, CommentType.DOCUMENTATION, new List<CommentReference>());

  /**
   * Create a documentation comment.
   *
   * @param tokens the tokens representing the comment
   * @param references the references embedded within the documentation comment
   * @return the documentation comment that was created
   */
  static Comment createDocumentationComment2(List<Token> tokens, List<CommentReference> references) => new Comment(tokens, CommentType.DOCUMENTATION, references);

  /**
   * Create an end-of-line comment.
   *
   * @param tokens the tokens representing the comment
   * @return the end-of-line comment that was created
   */
  static Comment createEndOfLineComment(List<Token> tokens) => new Comment(tokens, CommentType.END_OF_LINE, null);

  /**
   * The tokens representing the comment.
   */
  final List<Token> tokens;

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
   *
   * @param tokens the tokens representing the comment
   * @param type the type of the comment
   * @param references the references embedded within the documentation comment
   */
  Comment(this.tokens, CommentType type, List<CommentReference> references) {
    this._references = new NodeList<CommentReference>(this);
    this._type = type;
    this._references.addAll(references);
  }

  accept(AstVisitor visitor) => visitor.visitComment(this);

  Token get beginToken => tokens[0];

  Token get endToken => tokens[tokens.length - 1];

  /**
   * Return the references embedded within the documentation comment.
   *
   * @return the references embedded within the documentation comment
   */
  NodeList<CommentReference> get references => _references;

  /**
   * Return `true` if this is a block comment.
   *
   * @return `true` if this is a block comment
   */
  bool get isBlock => identical(_type, CommentType.BLOCK);

  /**
   * Return `true` if this is a documentation comment.
   *
   * @return `true` if this is a documentation comment
   */
  bool get isDocumentation => identical(_type, CommentType.DOCUMENTATION);

  /**
   * Return `true` if this is an end-of-line comment.
   *
   * @return `true` if this is an end-of-line comment
   */
  bool get isEndOfLine => identical(_type, CommentType.END_OF_LINE);

  void visitChildren(AstVisitor visitor) {
    _references.accept(visitor);
  }
}

/**
 * The enumeration `CommentType` encodes all the different types of comments that are
 * recognized by the parser.
 */
class CommentType extends Enum<CommentType> {
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

  CommentType(String name, int ordinal) : super(name, ordinal);
}

/**
 * Instances of the class `CommentReference` represent a reference to a Dart element that is
 * found within a documentation comment.
 *
 * <pre>
 * commentReference ::=
 *     '[' 'new'? [Identifier] ']'
 * </pre>
 */
class CommentReference extends AstNode {
  /**
   * The token representing the 'new' keyword, or `null` if there was no 'new' keyword.
   */
  Token newKeyword;

  /**
   * The identifier being referenced.
   */
  Identifier _identifier;

  /**
   * Initialize a newly created reference to a Dart element.
   *
   * @param newKeyword the token representing the 'new' keyword
   * @param identifier the identifier being referenced
   */
  CommentReference(this.newKeyword, Identifier identifier) {
    this._identifier = becomeParentOf(identifier);
  }

  accept(AstVisitor visitor) => visitor.visitCommentReference(this);

  Token get beginToken => _identifier.beginToken;

  Token get endToken => _identifier.endToken;

  /**
   * Return the identifier being referenced.
   *
   * @return the identifier being referenced
   */
  Identifier get identifier => _identifier;

  /**
   * Set the identifier being referenced to the given identifier.
   *
   * @param identifier the identifier being referenced
   */
  void set identifier(Identifier identifier) {
    identifier = becomeParentOf(identifier);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_identifier, visitor);
  }
}

/**
 * Instances of the class `CompilationUnit` represent a compilation unit.
 *
 * While the grammar restricts the order of the directives and declarations within a compilation
 * unit, this class does not enforce those restrictions. In particular, the children of a
 * compilation unit will be visited in lexical order even if lexical order does not conform to the
 * restrictions of the grammar.
 *
 * <pre>
 * compilationUnit ::=
 *     directives declarations
 *
 * directives ::=
 *     [ScriptTag]? [LibraryDirective]? namespaceDirective* [PartDirective]*
 *   | [PartOfDirective]
 *
 * namespaceDirective ::=
 *     [ImportDirective]
 *   | [ExportDirective]
 *
 * declarations ::=
 *     [CompilationUnitMember]*
 * </pre>
 */
class CompilationUnit extends AstNode {
  /**
   * The first token in the token stream that was parsed to form this compilation unit.
   */
  final Token beginToken;

  /**
   * The script tag at the beginning of the compilation unit, or `null` if there is no script
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
   * should always have a type of [TokenType.EOF].
   */
  final Token endToken;

  /**
   * The element associated with this compilation unit, or `null` if the AST structure has not
   * been resolved.
   */
  CompilationUnitElement element;

  /**
   * The line information for this compilation unit.
   */
  LineInfo lineInfo;

  /**
   * Initialize a newly created compilation unit to have the given directives and declarations.
   *
   * @param beginToken the first token in the token stream
   * @param scriptTag the script tag at the beginning of the compilation unit
   * @param directives the directives contained in this compilation unit
   * @param declarations the declarations contained in this compilation unit
   * @param endToken the last token in the token stream
   */
  CompilationUnit(this.beginToken, ScriptTag scriptTag, List<Directive> directives, List<CompilationUnitMember> declarations, this.endToken) {
    this._directives = new NodeList<Directive>(this);
    this._declarations = new NodeList<CompilationUnitMember>(this);
    this._scriptTag = becomeParentOf(scriptTag);
    this._directives.addAll(directives);
    this._declarations.addAll(declarations);
  }

  accept(AstVisitor visitor) => visitor.visitCompilationUnit(this);

  /**
   * Return the declarations contained in this compilation unit.
   *
   * @return the declarations contained in this compilation unit
   */
  NodeList<CompilationUnitMember> get declarations => _declarations;

  /**
   * Return the directives contained in this compilation unit.
   *
   * @return the directives contained in this compilation unit
   */
  NodeList<Directive> get directives => _directives;

  int get length {
    Token endToken = this.endToken;
    if (endToken == null) {
      return 0;
    }
    return endToken.offset + endToken.length;
  }

  int get offset => 0;

  /**
   * Return the script tag at the beginning of the compilation unit, or `null` if there is no
   * script tag in this compilation unit.
   *
   * @return the script tag at the beginning of the compilation unit
   */
  ScriptTag get scriptTag => _scriptTag;

  /**
   * Set the script tag at the beginning of the compilation unit to the given script tag.
   *
   * @param scriptTag the script tag at the beginning of the compilation unit
   */
  void set scriptTag(ScriptTag scriptTag) {
    this._scriptTag = becomeParentOf(scriptTag);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_scriptTag, visitor);
    if (directivesAreBeforeDeclarations()) {
      _directives.accept(visitor);
      _declarations.accept(visitor);
    } else {
      for (AstNode child in sortedDirectivesAndDeclarations) {
        child.accept(visitor);
      }
    }
  }

  /**
   * Return `true` if all of the directives are lexically before any declarations.
   *
   * @return `true` if all of the directives are lexically before any declarations
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
   *
   * @return the directives and declarations in this compilation unit in the order in which they
   *         appeared in the original source
   */
  List<AstNode> get sortedDirectivesAndDeclarations {
    List<AstNode> childList = new List<AstNode>();
    childList.addAll(_directives);
    childList.addAll(_declarations);
    List<AstNode> children = new List.from(childList);
    children.sort(AstNode.LEXICAL_ORDER);
    return children;
  }
}

/**
 * Instances of the class `CompilationUnitMember` defines the behavior common to nodes that
 * declare a name within the scope of a compilation unit.
 *
 * <pre>
 * compilationUnitMember ::=
 *     [ClassDeclaration]
 *   | [TypeAlias]
 *   | [FunctionDeclaration]
 *   | [MethodDeclaration]
 *   | [VariableDeclaration]
 *   | [VariableDeclaration]
 * </pre>
 */
abstract class CompilationUnitMember extends Declaration {
  /**
   * Initialize a newly created generic compilation unit member.
   *
   * @param comment the documentation comment associated with this member
   * @param metadata the annotations associated with this member
   */
  CompilationUnitMember(Comment comment, List<Annotation> metadata) : super(comment, metadata);
}

/**
 * Instances of the class `ConditionalExpression` represent a conditional expression.
 *
 * <pre>
 * conditionalExpression ::=
 *     [Expression] '?' [Expression] ':' [Expression]
 * </pre>
 */
class ConditionalExpression extends Expression {
  /**
   * The condition used to determine which of the expressions is executed next.
   */
  Expression _condition;

  /**
   * The token used to separate the condition from the then expression.
   */
  Token question;

  /**
   * The expression that is executed if the condition evaluates to `true`.
   */
  Expression _thenExpression;

  /**
   * The token used to separate the then expression from the else expression.
   */
  Token colon;

  /**
   * The expression that is executed if the condition evaluates to `false`.
   */
  Expression _elseExpression;

  /**
   * Initialize a newly created conditional expression.
   *
   * @param condition the condition used to determine which expression is executed next
   * @param question the token used to separate the condition from the then expression
   * @param thenExpression the expression that is executed if the condition evaluates to
   *          `true`
   * @param colon the token used to separate the then expression from the else expression
   * @param elseExpression the expression that is executed if the condition evaluates to
   *          `false`
   */
  ConditionalExpression(Expression condition, this.question, Expression thenExpression, this.colon, Expression elseExpression) {
    this._condition = becomeParentOf(condition);
    this._thenExpression = becomeParentOf(thenExpression);
    this._elseExpression = becomeParentOf(elseExpression);
  }

  accept(AstVisitor visitor) => visitor.visitConditionalExpression(this);

  Token get beginToken => _condition.beginToken;

  /**
   * Return the condition used to determine which of the expressions is executed next.
   *
   * @return the condition used to determine which expression is executed next
   */
  Expression get condition => _condition;

  /**
   * Return the expression that is executed if the condition evaluates to `false`.
   *
   * @return the expression that is executed if the condition evaluates to `false`
   */
  Expression get elseExpression => _elseExpression;

  Token get endToken => _elseExpression.endToken;

  int get precedence => 3;

  /**
   * Return the expression that is executed if the condition evaluates to `true`.
   *
   * @return the expression that is executed if the condition evaluates to `true`
   */
  Expression get thenExpression => _thenExpression;

  /**
   * Set the condition used to determine which of the expressions is executed next to the given
   * expression.
   *
   * @param expression the condition used to determine which expression is executed next
   */
  void set condition(Expression expression) {
    _condition = becomeParentOf(expression);
  }

  /**
   * Set the expression that is executed if the condition evaluates to `false` to the given
   * expression.
   *
   * @param expression the expression that is executed if the condition evaluates to `false`
   */
  void set elseExpression(Expression expression) {
    _elseExpression = becomeParentOf(expression);
  }

  /**
   * Set the expression that is executed if the condition evaluates to `true` to the given
   * expression.
   *
   * @param expression the expression that is executed if the condition evaluates to `true`
   */
  void set thenExpression(Expression expression) {
    _thenExpression = becomeParentOf(expression);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_condition, visitor);
    safelyVisitChild(_thenExpression, visitor);
    safelyVisitChild(_elseExpression, visitor);
  }
}

/**
 * Instances of the class `ConstructorDeclaration` represent a constructor declaration.
 *
 * <pre>
 * constructorDeclaration ::=
 *     constructorSignature [FunctionBody]?
 *   | constructorName formalParameterList ':' 'this' ('.' [SimpleIdentifier])? arguments
 *
 * constructorSignature ::=
 *     'external'? constructorName formalParameterList initializerList?
 *   | 'external'? 'factory' factoryName formalParameterList initializerList?
 *   | 'external'? 'const'  constructorName formalParameterList initializerList?
 *
 * constructorName ::=
 *     [SimpleIdentifier] ('.' [SimpleIdentifier])?
 *
 * factoryName ::=
 *     [Identifier] ('.' [SimpleIdentifier])?
 *
 * initializerList ::=
 *     ':' [ConstructorInitializer] (',' [ConstructorInitializer])*
 * </pre>
 */
class ConstructorDeclaration extends ClassMember {
  /**
   * The token for the 'external' keyword, or `null` if the constructor is not external.
   */
  Token externalKeyword;

  /**
   * The token for the 'const' keyword, or `null` if the constructor is not a const
   * constructor.
   */
  Token constKeyword;

  /**
   * The token for the 'factory' keyword, or `null` if the constructor is not a factory
   * constructor.
   */
  Token factoryKeyword;

  /**
   * The type of object being created. This can be different than the type in which the constructor
   * is being declared if the constructor is the implementation of a factory constructor.
   */
  Identifier _returnType;

  /**
   * The token for the period before the constructor name, or `null` if the constructor being
   * declared is unnamed.
   */
  Token period;

  /**
   * The name of the constructor, or `null` if the constructor being declared is unnamed.
   */
  SimpleIdentifier _name;

  /**
   * The parameters associated with the constructor.
   */
  FormalParameterList _parameters;

  /**
   * The token for the separator (colon or equals) before the initializer list or redirection, or
   * `null` if there are no initializers.
   */
  Token separator;

  /**
   * The initializers associated with the constructor.
   */
  NodeList<ConstructorInitializer> _initializers;

  /**
   * The name of the constructor to which this constructor will be redirected, or `null` if
   * this is not a redirecting factory constructor.
   */
  ConstructorName _redirectedConstructor;

  /**
   * The body of the constructor, or `null` if the constructor does not have a body.
   */
  FunctionBody _body;

  /**
   * The element associated with this constructor, or `null` if the AST structure has not been
   * resolved or if this constructor could not be resolved.
   */
  ConstructorElement element;

  /**
   * Initialize a newly created constructor declaration.
   *
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
   *          redirected
   * @param body the body of the constructor
   */
  ConstructorDeclaration(Comment comment, List<Annotation> metadata, this.externalKeyword, this.constKeyword, this.factoryKeyword, Identifier returnType, this.period, SimpleIdentifier name, FormalParameterList parameters, this.separator, List<ConstructorInitializer> initializers, ConstructorName redirectedConstructor, FunctionBody body) : super(comment, metadata) {
    this._initializers = new NodeList<ConstructorInitializer>(this);
    this._returnType = becomeParentOf(returnType);
    this._name = becomeParentOf(name);
    this._parameters = becomeParentOf(parameters);
    this._initializers.addAll(initializers);
    this._redirectedConstructor = becomeParentOf(redirectedConstructor);
    this._body = becomeParentOf(body);
  }

  accept(AstVisitor visitor) => visitor.visitConstructorDeclaration(this);

  /**
   * Return the body of the constructor, or `null` if the constructor does not have a body.
   *
   * @return the body of the constructor
   */
  FunctionBody get body => _body;

  Token get endToken {
    if (_body != null) {
      return _body.endToken;
    } else if (!_initializers.isEmpty) {
      return _initializers.endToken;
    }
    return _parameters.endToken;
  }

  /**
   * Return the initializers associated with the constructor.
   *
   * @return the initializers associated with the constructor
   */
  NodeList<ConstructorInitializer> get initializers => _initializers;

  /**
   * Return the name of the constructor, or `null` if the constructor being declared is
   * unnamed.
   *
   * @return the name of the constructor
   */
  SimpleIdentifier get name => _name;

  /**
   * Return the parameters associated with the constructor.
   *
   * @return the parameters associated with the constructor
   */
  FormalParameterList get parameters => _parameters;

  /**
   * Return the name of the constructor to which this constructor will be redirected, or
   * `null` if this is not a redirecting factory constructor.
   *
   * @return the name of the constructor to which this constructor will be redirected
   */
  ConstructorName get redirectedConstructor => _redirectedConstructor;

  /**
   * Return the type of object being created. This can be different than the type in which the
   * constructor is being declared if the constructor is the implementation of a factory
   * constructor.
   *
   * @return the type of object being created
   */
  Identifier get returnType => _returnType;

  /**
   * Set the body of the constructor to the given function body.
   *
   * @param functionBody the body of the constructor
   */
  void set body(FunctionBody functionBody) {
    _body = becomeParentOf(functionBody);
  }

  /**
   * Set the name of the constructor to the given identifier.
   *
   * @param identifier the name of the constructor
   */
  void set name(SimpleIdentifier identifier) {
    _name = becomeParentOf(identifier);
  }

  /**
   * Set the parameters associated with the constructor to the given list of parameters.
   *
   * @param parameters the parameters associated with the constructor
   */
  void set parameters(FormalParameterList parameters) {
    this._parameters = becomeParentOf(parameters);
  }

  /**
   * Set the name of the constructor to which this constructor will be redirected to the given
   * constructor name.
   *
   * @param redirectedConstructor the name of the constructor to which this constructor will be
   *          redirected
   */
  void set redirectedConstructor(ConstructorName redirectedConstructor) {
    this._redirectedConstructor = becomeParentOf(redirectedConstructor);
  }

  /**
   * Set the type of object being created to the given type name.
   *
   * @param typeName the type of object being created
   */
  void set returnType(Identifier typeName) {
    _returnType = becomeParentOf(typeName);
  }

  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_returnType, visitor);
    safelyVisitChild(_name, visitor);
    safelyVisitChild(_parameters, visitor);
    _initializers.accept(visitor);
    safelyVisitChild(_redirectedConstructor, visitor);
    safelyVisitChild(_body, visitor);
  }

  Token get firstTokenAfterCommentAndMetadata {
    Token leftMost = this.leftMost([externalKeyword, constKeyword, factoryKeyword]);
    if (leftMost != null) {
      return leftMost;
    }
    return _returnType.beginToken;
  }

  /**
   * Return the left-most of the given tokens, or `null` if there are no tokens given or if
   * all of the given tokens are `null`.
   *
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
 * Instances of the class `ConstructorFieldInitializer` represent the initialization of a
 * field within a constructor's initialization list.
 *
 * <pre>
 * fieldInitializer ::=
 *     ('this' '.')? [SimpleIdentifier] '=' [Expression]
 * </pre>
 */
class ConstructorFieldInitializer extends ConstructorInitializer {
  /**
   * The token for the 'this' keyword, or `null` if there is no 'this' keyword.
   */
  Token keyword;

  /**
   * The token for the period after the 'this' keyword, or `null` if there is no 'this'
   * keyword.
   */
  Token period;

  /**
   * The name of the field being initialized.
   */
  SimpleIdentifier _fieldName;

  /**
   * The token for the equal sign between the field name and the expression.
   */
  Token equals;

  /**
   * The expression computing the value to which the field will be initialized.
   */
  Expression _expression;

  /**
   * Initialize a newly created field initializer to initialize the field with the given name to the
   * value of the given expression.
   *
   * @param keyword the token for the 'this' keyword
   * @param period the token for the period after the 'this' keyword
   * @param fieldName the name of the field being initialized
   * @param equals the token for the equal sign between the field name and the expression
   * @param expression the expression computing the value to which the field will be initialized
   */
  ConstructorFieldInitializer(this.keyword, this.period, SimpleIdentifier fieldName, this.equals, Expression expression) {
    this._fieldName = becomeParentOf(fieldName);
    this._expression = becomeParentOf(expression);
  }

  accept(AstVisitor visitor) => visitor.visitConstructorFieldInitializer(this);

  Token get beginToken {
    if (keyword != null) {
      return keyword;
    }
    return _fieldName.beginToken;
  }

  Token get endToken => _expression.endToken;

  /**
   * Return the expression computing the value to which the field will be initialized.
   *
   * @return the expression computing the value to which the field will be initialized
   */
  Expression get expression => _expression;

  /**
   * Return the name of the field being initialized.
   *
   * @return the name of the field being initialized
   */
  SimpleIdentifier get fieldName => _fieldName;

  /**
   * Set the expression computing the value to which the field will be initialized to the given
   * expression.
   *
   * @param expression the expression computing the value to which the field will be initialized
   */
  void set expression(Expression expression) {
    this._expression = becomeParentOf(expression);
  }

  /**
   * Set the name of the field being initialized to the given identifier.
   *
   * @param identifier the name of the field being initialized
   */
  void set fieldName(SimpleIdentifier identifier) {
    _fieldName = becomeParentOf(identifier);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_fieldName, visitor);
    safelyVisitChild(_expression, visitor);
  }
}

/**
 * Instances of the class `ConstructorInitializer` defines the behavior of nodes that can
 * occur in the initializer list of a constructor declaration.
 *
 * <pre>
 * constructorInitializer ::=
 *     [SuperConstructorInvocation]
 *   | [ConstructorFieldInitializer]
 * </pre>
 */
abstract class ConstructorInitializer extends AstNode {
}

/**
 * Instances of the class `ConstructorName` represent the name of the constructor.
 *
 * <pre>
 * constructorName:
 *     type ('.' identifier)?
 * </pre>
 */
class ConstructorName extends AstNode {
  /**
   * The name of the type defining the constructor.
   */
  TypeName _type;

  /**
   * The token for the period before the constructor name, or `null` if the specified
   * constructor is the unnamed constructor.
   */
  Token period;

  /**
   * The name of the constructor, or `null` if the specified constructor is the unnamed
   * constructor.
   */
  SimpleIdentifier _name;

  /**
   * The element associated with this constructor name based on static type information, or
   * `null` if the AST structure has not been resolved or if this constructor name could not
   * be resolved.
   */
  ConstructorElement _staticElement;

  /**
   * Initialize a newly created constructor name.
   *
   * @param type the name of the type defining the constructor
   * @param period the token for the period before the constructor name
   * @param name the name of the constructor
   */
  ConstructorName(TypeName type, this.period, SimpleIdentifier name) {
    this._type = becomeParentOf(type);
    this._name = becomeParentOf(name);
  }

  accept(AstVisitor visitor) => visitor.visitConstructorName(this);

  Token get beginToken => _type.beginToken;

  Token get endToken {
    if (_name != null) {
      return _name.endToken;
    }
    return _type.endToken;
  }

  /**
   * Return the name of the constructor, or `null` if the specified constructor is the unnamed
   * constructor.
   *
   * @return the name of the constructor
   */
  SimpleIdentifier get name => _name;

  /**
   * Return the element associated with this constructor name based on static type information, or
   * `null` if the AST structure has not been resolved or if this constructor name could not
   * be resolved.
   *
   * @return the element associated with this constructor name
   */
  ConstructorElement get staticElement => _staticElement;

  /**
   * Return the name of the type defining the constructor.
   *
   * @return the name of the type defining the constructor
   */
  TypeName get type => _type;

  /**
   * Set the name of the constructor to the given name.
   *
   * @param name the name of the constructor
   */
  void set name(SimpleIdentifier name) {
    this._name = becomeParentOf(name);
  }

  /**
   * Set the element associated with this constructor name based on static type information to the
   * given element.
   *
   * @param element the element to be associated with this constructor name
   */
  void set staticElement(ConstructorElement element) {
    _staticElement = element;
  }

  /**
   * Set the name of the type defining the constructor to the given type name.
   *
   * @param type the name of the type defining the constructor
   */
  void set type(TypeName type) {
    this._type = becomeParentOf(type);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_type, visitor);
    safelyVisitChild(_name, visitor);
  }
}

/**
 * Instances of the class `ContinueStatement` represent a continue statement.
 *
 * <pre>
 * continueStatement ::=
 *     'continue' [SimpleIdentifier]? ';'
 * </pre>
 */
class ContinueStatement extends Statement {
  /**
   * The token representing the 'continue' keyword.
   */
  Token keyword;

  /**
   * The label associated with the statement, or `null` if there is no label.
   */
  SimpleIdentifier _label;

  /**
   * The semicolon terminating the statement.
   */
  Token semicolon;

  /**
   * Initialize a newly created continue statement.
   *
   * @param keyword the token representing the 'continue' keyword
   * @param label the label associated with the statement
   * @param semicolon the semicolon terminating the statement
   */
  ContinueStatement(this.keyword, SimpleIdentifier label, this.semicolon) {
    this._label = becomeParentOf(label);
  }

  accept(AstVisitor visitor) => visitor.visitContinueStatement(this);

  Token get beginToken => keyword;

  Token get endToken => semicolon;

  /**
   * Return the label associated with the statement, or `null` if there is no label.
   *
   * @return the label associated with the statement
   */
  SimpleIdentifier get label => _label;

  /**
   * Set the label associated with the statement to the given label.
   *
   * @param identifier the label associated with the statement
   */
  void set label(SimpleIdentifier identifier) {
    _label = becomeParentOf(identifier);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_label, visitor);
  }
}

/**
 * The abstract class `Declaration` defines the behavior common to nodes that represent the
 * declaration of a name. Each declared name is visible within a name scope.
 */
abstract class Declaration extends AnnotatedNode {
  /**
   * Initialize a newly created declaration.
   *
   * @param comment the documentation comment associated with this declaration
   * @param metadata the annotations associated with this declaration
   */
  Declaration(Comment comment, List<Annotation> metadata) : super(comment, metadata);

  /**
   * Return the element associated with this declaration, or `null` if either this node
   * corresponds to a list of declarations or if the AST structure has not been resolved.
   *
   * @return the element associated with this declaration
   */
  Element get element;
}

/**
 * Instances of the class `DeclaredIdentifier` represent the declaration of a single
 * identifier.
 *
 * <pre>
 * declaredIdentifier ::=
 *     ([Annotation] finalConstVarOrType [SimpleIdentifier]
 * </pre>
 */
class DeclaredIdentifier extends Declaration {
  /**
   * The token representing either the 'final', 'const' or 'var' keyword, or `null` if no
   * keyword was used.
   */
  Token keyword;

  /**
   * The name of the declared type of the parameter, or `null` if the parameter does not have
   * a declared type.
   */
  TypeName _type;

  /**
   * The name of the variable being declared.
   */
  SimpleIdentifier _identifier;

  /**
   * Initialize a newly created formal parameter.
   *
   * @param comment the documentation comment associated with this parameter
   * @param metadata the annotations associated with this parameter
   * @param keyword the token representing either the 'final', 'const' or 'var' keyword
   * @param type the name of the declared type of the parameter
   * @param identifier the name of the parameter being declared
   */
  DeclaredIdentifier(Comment comment, List<Annotation> metadata, this.keyword, TypeName type, SimpleIdentifier identifier) : super(comment, metadata) {
    this._type = becomeParentOf(type);
    this._identifier = becomeParentOf(identifier);
  }

  accept(AstVisitor visitor) => visitor.visitDeclaredIdentifier(this);

  LocalVariableElement get element {
    SimpleIdentifier identifier = this.identifier;
    if (identifier == null) {
      return null;
    }
    return identifier.staticElement as LocalVariableElement;
  }

  Token get endToken => _identifier.endToken;

  /**
   * Return the name of the variable being declared.
   *
   * @return the name of the variable being declared
   */
  SimpleIdentifier get identifier => _identifier;

  /**
   * Return the name of the declared type of the parameter, or `null` if the parameter does
   * not have a declared type.
   *
   * @return the name of the declared type of the parameter
   */
  TypeName get type => _type;

  /**
   * Return `true` if this variable was declared with the 'const' modifier.
   *
   * @return `true` if this variable was declared with the 'const' modifier
   */
  bool get isConst => (keyword is KeywordToken) && identical((keyword as KeywordToken).keyword, Keyword.CONST);

  /**
   * Return `true` if this variable was declared with the 'final' modifier. Variables that are
   * declared with the 'const' modifier will return `false` even though they are implicitly
   * final.
   *
   * @return `true` if this variable was declared with the 'final' modifier
   */
  bool get isFinal => (keyword is KeywordToken) && identical((keyword as KeywordToken).keyword, Keyword.FINAL);

  /**
   * Set the name of the declared type of the parameter to the given type name.
   *
   * @param typeName the name of the declared type of the parameter
   */
  void set type(TypeName typeName) {
    _type = becomeParentOf(typeName);
  }

  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_type, visitor);
    safelyVisitChild(_identifier, visitor);
  }

  Token get firstTokenAfterCommentAndMetadata {
    if (keyword != null) {
      return keyword;
    } else if (_type != null) {
      return _type.beginToken;
    }
    return _identifier.beginToken;
  }
}

/**
 * Instances of the class `DefaultFormalParameter` represent a formal parameter with a default
 * value. There are two kinds of parameters that are both represented by this class: named formal
 * parameters and positional formal parameters.
 *
 * <pre>
 * defaultFormalParameter ::=
 *     [NormalFormalParameter] ('=' [Expression])?
 *
 * defaultNamedParameter ::=
 *     [NormalFormalParameter] (':' [Expression])?
 * </pre>
 */
class DefaultFormalParameter extends FormalParameter {
  /**
   * The formal parameter with which the default value is associated.
   */
  NormalFormalParameter _parameter;

  /**
   * The kind of this parameter.
   */
  ParameterKind kind;

  /**
   * The token separating the parameter from the default value, or `null` if there is no
   * default value.
   */
  Token separator;

  /**
   * The expression computing the default value for the parameter, or `null` if there is no
   * default value.
   */
  Expression _defaultValue;

  /**
   * Initialize a newly created default formal parameter.
   *
   * @param parameter the formal parameter with which the default value is associated
   * @param kind the kind of this parameter
   * @param separator the token separating the parameter from the default value
   * @param defaultValue the expression computing the default value for the parameter
   */
  DefaultFormalParameter(NormalFormalParameter parameter, this.kind, this.separator, Expression defaultValue) {
    this._parameter = becomeParentOf(parameter);
    this._defaultValue = becomeParentOf(defaultValue);
  }

  accept(AstVisitor visitor) => visitor.visitDefaultFormalParameter(this);

  Token get beginToken => _parameter.beginToken;

  /**
   * Return the expression computing the default value for the parameter, or `null` if there
   * is no default value.
   *
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

  /**
   * Return the formal parameter with which the default value is associated.
   *
   * @return the formal parameter with which the default value is associated
   */
  NormalFormalParameter get parameter => _parameter;

  bool get isConst => _parameter != null && _parameter.isConst;

  bool get isFinal => _parameter != null && _parameter.isFinal;

  /**
   * Set the expression computing the default value for the parameter to the given expression.
   *
   * @param expression the expression computing the default value for the parameter
   */
  void set defaultValue(Expression expression) {
    _defaultValue = becomeParentOf(expression);
  }

  /**
   * Set the formal parameter with which the default value is associated to the given parameter.
   *
   * @param formalParameter the formal parameter with which the default value is associated
   */
  void set parameter(NormalFormalParameter formalParameter) {
    _parameter = becomeParentOf(formalParameter);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_parameter, visitor);
    safelyVisitChild(_defaultValue, visitor);
  }
}

/**
 * The abstract class `Directive` defines the behavior common to nodes that represent a
 * directive.
 *
 * <pre>
 * directive ::=
 *     [ExportDirective]
 *   | [ImportDirective]
 *   | [LibraryDirective]
 *   | [PartDirective]
 *   | [PartOfDirective]
 * </pre>
 */
abstract class Directive extends AnnotatedNode {
  /**
   * The element associated with this directive, or `null` if the AST structure has not been
   * resolved or if this directive could not be resolved.
   */
  Element _element;

  /**
   * Initialize a newly create directive.
   *
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   */
  Directive(Comment comment, List<Annotation> metadata) : super(comment, metadata);

  /**
   * Return the element associated with this directive, or `null` if the AST structure has not
   * been resolved or if this directive could not be resolved. Examples of the latter case include a
   * directive that contains an invalid URL or a URL that does not exist.
   *
   * @return the element associated with this directive
   */
  Element get element => _element;

  /**
   * Return the token representing the keyword that introduces this directive ('import', 'export',
   * 'library' or 'part').
   *
   * @return the token representing the keyword that introduces this directive
   */
  Token get keyword;

  /**
   * Set the element associated with this directive to the given element.
   *
   * @param element the element associated with this directive
   */
  void set element(Element element) {
    this._element = element;
  }
}

/**
 * Instances of the class `DoStatement` represent a do statement.
 *
 * <pre>
 * doStatement ::=
 *     'do' [Statement] 'while' '(' [Expression] ')' ';'
 * </pre>
 */
class DoStatement extends Statement {
  /**
   * The token representing the 'do' keyword.
   */
  Token doKeyword;

  /**
   * The body of the loop.
   */
  Statement _body;

  /**
   * The token representing the 'while' keyword.
   */
  Token whileKeyword;

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
  Token semicolon;

  /**
   * Initialize a newly created do loop.
   *
   * @param doKeyword the token representing the 'do' keyword
   * @param body the body of the loop
   * @param whileKeyword the token representing the 'while' keyword
   * @param leftParenthesis the left parenthesis
   * @param condition the condition that determines when the loop will terminate
   * @param rightParenthesis the right parenthesis
   * @param semicolon the semicolon terminating the statement
   */
  DoStatement(this.doKeyword, Statement body, this.whileKeyword, Token leftParenthesis, Expression condition, Token rightParenthesis, this.semicolon) {
    this._body = becomeParentOf(body);
    this._leftParenthesis = leftParenthesis;
    this._condition = becomeParentOf(condition);
    this._rightParenthesis = rightParenthesis;
  }

  accept(AstVisitor visitor) => visitor.visitDoStatement(this);

  Token get beginToken => doKeyword;

  /**
   * Return the body of the loop.
   *
   * @return the body of the loop
   */
  Statement get body => _body;

  /**
   * Return the condition that determines when the loop will terminate.
   *
   * @return the condition that determines when the loop will terminate
   */
  Expression get condition => _condition;

  Token get endToken => semicolon;

  /**
   * Return the left parenthesis.
   *
   * @return the left parenthesis
   */
  Token get leftParenthesis => _leftParenthesis;

  /**
   * Return the right parenthesis.
   *
   * @return the right parenthesis
   */
  Token get rightParenthesis => _rightParenthesis;

  /**
   * Set the body of the loop to the given statement.
   *
   * @param statement the body of the loop
   */
  void set body(Statement statement) {
    _body = becomeParentOf(statement);
  }

  /**
   * Set the condition that determines when the loop will terminate to the given expression.
   *
   * @param expression the condition that determines when the loop will terminate
   */
  void set condition(Expression expression) {
    _condition = becomeParentOf(expression);
  }

  /**
   * Set the left parenthesis to the given token.
   *
   * @param parenthesis the left parenthesis
   */
  void set leftParenthesis(Token parenthesis) {
    _leftParenthesis = parenthesis;
  }

  /**
   * Set the right parenthesis to the given token.
   *
   * @param parenthesis the right parenthesis
   */
  void set rightParenthesis(Token parenthesis) {
    _rightParenthesis = parenthesis;
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_body, visitor);
    safelyVisitChild(_condition, visitor);
  }
}

/**
 * Instances of the class `DoubleLiteral` represent a floating point literal expression.
 *
 * <pre>
 * doubleLiteral ::=
 *     decimalDigit+ ('.' decimalDigit*)? exponent?
 *   | '.' decimalDigit+ exponent?
 *
 * exponent ::=
 *     ('e' | 'E') ('+' | '-')? decimalDigit+
 * </pre>
 */
class DoubleLiteral extends Literal {
  /**
   * The token representing the literal.
   */
  Token literal;

  /**
   * The value of the literal.
   */
  double value = 0.0;

  /**
   * Initialize a newly created floating point literal.
   *
   * @param literal the token representing the literal
   * @param value the value of the literal
   */
  DoubleLiteral(this.literal, this.value);

  accept(AstVisitor visitor) => visitor.visitDoubleLiteral(this);

  Token get beginToken => literal;

  Token get endToken => literal;

  void visitChildren(AstVisitor visitor) {
  }
}

/**
 * Instances of the class `EmptyFunctionBody` represent an empty function body, which can only
 * appear in constructors or abstract methods.
 *
 * <pre>
 * emptyFunctionBody ::=
 *     ';'
 * </pre>
 */
class EmptyFunctionBody extends FunctionBody {
  /**
   * The token representing the semicolon that marks the end of the function body.
   */
  Token semicolon;

  /**
   * Initialize a newly created function body.
   *
   * @param semicolon the token representing the semicolon that marks the end of the function body
   */
  EmptyFunctionBody(this.semicolon);

  accept(AstVisitor visitor) => visitor.visitEmptyFunctionBody(this);

  Token get beginToken => semicolon;

  Token get endToken => semicolon;

  void visitChildren(AstVisitor visitor) {
  }
}

/**
 * Instances of the class `EmptyStatement` represent an empty statement.
 *
 * <pre>
 * emptyStatement ::=
 *     ';'
 * </pre>
 */
class EmptyStatement extends Statement {
  /**
   * The semicolon terminating the statement.
   */
  Token semicolon;

  /**
   * Initialize a newly created empty statement.
   *
   * @param semicolon the semicolon terminating the statement
   */
  EmptyStatement(this.semicolon);

  accept(AstVisitor visitor) => visitor.visitEmptyStatement(this);

  Token get beginToken => semicolon;

  Token get endToken => semicolon;

  void visitChildren(AstVisitor visitor) {
  }
}

/**
 * Ephemeral identifiers are created as needed to mimic the presence of an empty identifier.
 */
class EphemeralIdentifier extends SimpleIdentifier {
  EphemeralIdentifier(AstNode parent, int location) : super(new StringToken(TokenType.IDENTIFIER, "", location)) {
    parent.becomeParentOf(this);
  }
}

/**
 * Instances of the class `ExportDirective` represent an export directive.
 *
 * <pre>
 * exportDirective ::=
 *     [Annotation] 'export' [StringLiteral] [Combinator]* ';'
 * </pre>
 */
class ExportDirective extends NamespaceDirective {
  /**
   * Initialize a newly created export directive.
   *
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   * @param keyword the token representing the 'export' keyword
   * @param libraryUri the URI of the library being exported
   * @param combinators the combinators used to control which names are exported
   * @param semicolon the semicolon terminating the directive
   */
  ExportDirective(Comment comment, List<Annotation> metadata, Token keyword, StringLiteral libraryUri, List<Combinator> combinators, Token semicolon) : super(comment, metadata, keyword, libraryUri, combinators, semicolon);

  accept(AstVisitor visitor) => visitor.visitExportDirective(this);

  LibraryElement get uriElement {
    Element element = this.element;
    if (element is ExportElement) {
      return element.exportedLibrary;
    }
    return null;
  }

  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    combinators.accept(visitor);
  }
}

/**
 * Instances of the class `Expression` defines the behavior common to nodes that represent an
 * expression.
 *
 * <pre>
 * expression ::=
 *     [AssignmentExpression]
 *   | [ConditionalExpression] cascadeSection*
 *   | [ThrowExpression]
 * </pre>
 */
abstract class Expression extends AstNode {
  /**
   * An empty array of expressions.
   */
  static List<Expression> EMPTY_ARRAY = new List<Expression>(0);

  /**
   * The static type of this expression, or `null` if the AST structure has not been resolved.
   */
  Type2 staticType;

  /**
   * The propagated type of this expression, or `null` if type propagation has not been
   * performed on the AST structure.
   */
  Type2 propagatedType;

  /**
   * Return the best parameter element information available for this expression. If type
   * propagation was able to find a better parameter element than static analysis, that type will be
   * returned. Otherwise, the result of static analysis will be returned.
   *
   * @return the parameter element representing the parameter to which the value of this expression
   *         will be bound
   */
  ParameterElement get bestParameterElement {
    ParameterElement propagatedElement = propagatedParameterElement;
    if (propagatedElement != null) {
      return propagatedElement;
    }
    return staticParameterElement;
  }

  /**
   * Return the best type information available for this expression. If type propagation was able to
   * find a better type than static analysis, that type will be returned. Otherwise, the result of
   * static analysis will be returned. If no type analysis has been performed, then the type
   * 'dynamic' will be returned.
   *
   * @return the best type information available for this expression
   */
  Type2 get bestType {
    if (propagatedType != null) {
      return propagatedType;
    } else if (staticType != null) {
      return staticType;
    }
    return DynamicTypeImpl.instance;
  }

  /**
   * Return the precedence of this expression. The precedence is a positive integer value that
   * defines how the source code is parsed into an AST. For example `a * b + c` is parsed as
   * `(a * b) + c` because the precedence of `*` is greater than the precedence of
   * `+`.
   *
   * You should not assume that returned values will stay the same, they might change as result of
   * specification change. Only relative order should be used.
   *
   * @return the precedence of this expression
   */
  int get precedence;

  /**
   * If this expression is an argument to an invocation, and the AST structure has been resolved,
   * and the function being invoked is known based on propagated type information, and this
   * expression corresponds to one of the parameters of the function being invoked, then return the
   * parameter element representing the parameter to which the value of this expression will be
   * bound. Otherwise, return `null`.
   *
   * @return the parameter element representing the parameter to which the value of this expression
   *         will be bound
   */
  ParameterElement get propagatedParameterElement {
    AstNode parent = this.parent;
    if (parent is ArgumentList) {
      return parent.getPropagatedParameterElementFor(this);
    } else if (parent is IndexExpression) {
      IndexExpression indexExpression = parent;
      if (identical(indexExpression.index, this)) {
        return indexExpression.propagatedParameterElementForIndex;
      }
    } else if (parent is BinaryExpression) {
      BinaryExpression binaryExpression = parent;
      if (identical(binaryExpression.rightOperand, this)) {
        return binaryExpression.propagatedParameterElementForRightOperand;
      }
    } else if (parent is AssignmentExpression) {
      AssignmentExpression assignmentExpression = parent;
      if (identical(assignmentExpression.rightHandSide, this)) {
        return assignmentExpression.propagatedParameterElementForRightHandSide;
      }
    } else if (parent is PrefixExpression) {
      return parent.propagatedParameterElementForOperand;
    } else if (parent is PostfixExpression) {
      return parent.propagatedParameterElementForOperand;
    }
    return null;
  }

  /**
   * If this expression is an argument to an invocation, and the AST structure has been resolved,
   * and the function being invoked is known based on static type information, and this expression
   * corresponds to one of the parameters of the function being invoked, then return the parameter
   * element representing the parameter to which the value of this expression will be bound.
   * Otherwise, return `null`.
   *
   * @return the parameter element representing the parameter to which the value of this expression
   *         will be bound
   */
  ParameterElement get staticParameterElement {
    AstNode parent = this.parent;
    if (parent is ArgumentList) {
      return parent.getStaticParameterElementFor(this);
    } else if (parent is IndexExpression) {
      IndexExpression indexExpression = parent;
      if (identical(indexExpression.index, this)) {
        return indexExpression.staticParameterElementForIndex;
      }
    } else if (parent is BinaryExpression) {
      BinaryExpression binaryExpression = parent;
      if (identical(binaryExpression.rightOperand, this)) {
        return binaryExpression.staticParameterElementForRightOperand;
      }
    } else if (parent is AssignmentExpression) {
      AssignmentExpression assignmentExpression = parent;
      if (identical(assignmentExpression.rightHandSide, this)) {
        return assignmentExpression.staticParameterElementForRightHandSide;
      }
    } else if (parent is PrefixExpression) {
      return parent.staticParameterElementForOperand;
    } else if (parent is PostfixExpression) {
      return parent.staticParameterElementForOperand;
    }
    return null;
  }

  /**
   * Return `true` if this expression is syntactically valid for the LHS of an
   * [AssignmentExpression].
   *
   * @return `true` if this expression matches the `assignableExpression` production
   */
  bool get isAssignable => false;
}

/**
 * Instances of the class `ExpressionFunctionBody` represent a function body consisting of a
 * single expression.
 *
 * <pre>
 * expressionFunctionBody ::=
 *     '=>' [Expression] ';'
 * </pre>
 */
class ExpressionFunctionBody extends FunctionBody {
  /**
   * The token introducing the expression that represents the body of the function.
   */
  Token functionDefinition;

  /**
   * The expression representing the body of the function.
   */
  Expression _expression;

  /**
   * The semicolon terminating the statement.
   */
  Token semicolon;

  /**
   * Initialize a newly created function body consisting of a block of statements.
   *
   * @param functionDefinition the token introducing the expression that represents the body of the
   *          function
   * @param expression the expression representing the body of the function
   * @param semicolon the semicolon terminating the statement
   */
  ExpressionFunctionBody(this.functionDefinition, Expression expression, this.semicolon) {
    this._expression = becomeParentOf(expression);
  }

  accept(AstVisitor visitor) => visitor.visitExpressionFunctionBody(this);

  Token get beginToken => functionDefinition;

  Token get endToken {
    if (semicolon != null) {
      return semicolon;
    }
    return _expression.endToken;
  }

  /**
   * Return the expression representing the body of the function.
   *
   * @return the expression representing the body of the function
   */
  Expression get expression => _expression;

  /**
   * Set the expression representing the body of the function to the given expression.
   *
   * @param expression the expression representing the body of the function
   */
  void set expression(Expression expression) {
    this._expression = becomeParentOf(expression);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_expression, visitor);
  }
}

/**
 * Instances of the class `ExpressionStatement` wrap an expression as a statement.
 *
 * <pre>
 * expressionStatement ::=
 *     [Expression]? ';'
 * </pre>
 */
class ExpressionStatement extends Statement {
  /**
   * The expression that comprises the statement.
   */
  Expression _expression;

  /**
   * The semicolon terminating the statement, or `null` if the expression is a function
   * expression and therefore isn't followed by a semicolon.
   */
  Token semicolon;

  /**
   * Initialize a newly created expression statement.
   *
   * @param expression the expression that comprises the statement
   * @param semicolon the semicolon terminating the statement
   */
  ExpressionStatement(Expression expression, this.semicolon) {
    this._expression = becomeParentOf(expression);
  }

  accept(AstVisitor visitor) => visitor.visitExpressionStatement(this);

  Token get beginToken => _expression.beginToken;

  Token get endToken {
    if (semicolon != null) {
      return semicolon;
    }
    return _expression.endToken;
  }

  /**
   * Return the expression that comprises the statement.
   *
   * @return the expression that comprises the statement
   */
  Expression get expression => _expression;

  bool get isSynthetic => _expression.isSynthetic && semicolon.isSynthetic;

  /**
   * Set the expression that comprises the statement to the given expression.
   *
   * @param expression the expression that comprises the statement
   */
  void set expression(Expression expression) {
    this._expression = becomeParentOf(expression);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_expression, visitor);
  }
}

/**
 * Instances of the class `ExtendsClause` represent the "extends" clause in a class
 * declaration.
 *
 * <pre>
 * extendsClause ::=
 *     'extends' [TypeName]
 * </pre>
 */
class ExtendsClause extends AstNode {
  /**
   * The token representing the 'extends' keyword.
   */
  Token keyword;

  /**
   * The name of the class that is being extended.
   */
  TypeName _superclass;

  /**
   * Initialize a newly created extends clause.
   *
   * @param keyword the token representing the 'extends' keyword
   * @param superclass the name of the class that is being extended
   */
  ExtendsClause(this.keyword, TypeName superclass) {
    this._superclass = becomeParentOf(superclass);
  }

  accept(AstVisitor visitor) => visitor.visitExtendsClause(this);

  Token get beginToken => keyword;

  Token get endToken => _superclass.endToken;

  /**
   * Return the name of the class that is being extended.
   *
   * @return the name of the class that is being extended
   */
  TypeName get superclass => _superclass;

  /**
   * Set the name of the class that is being extended to the given name.
   *
   * @param name the name of the class that is being extended
   */
  void set superclass(TypeName name) {
    _superclass = becomeParentOf(name);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_superclass, visitor);
  }
}

/**
 * Instances of the class `FieldDeclaration` represent the declaration of one or more fields
 * of the same type.
 *
 * <pre>
 * fieldDeclaration ::=
 *     'static'? [VariableDeclarationList] ';'
 * </pre>
 */
class FieldDeclaration extends ClassMember {
  /**
   * The token representing the 'static' keyword, or `null` if the fields are not static.
   */
  Token staticKeyword;

  /**
   * The fields being declared.
   */
  VariableDeclarationList _fieldList;

  /**
   * The semicolon terminating the declaration.
   */
  Token semicolon;

  /**
   * Initialize a newly created field declaration.
   *
   * @param comment the documentation comment associated with this field
   * @param metadata the annotations associated with this field
   * @param staticKeyword the token representing the 'static' keyword
   * @param fieldList the fields being declared
   * @param semicolon the semicolon terminating the declaration
   */
  FieldDeclaration(Comment comment, List<Annotation> metadata, this.staticKeyword, VariableDeclarationList fieldList, this.semicolon) : super(comment, metadata) {
    this._fieldList = becomeParentOf(fieldList);
  }

  accept(AstVisitor visitor) => visitor.visitFieldDeclaration(this);

  Element get element => null;

  Token get endToken => semicolon;

  /**
   * Return the fields being declared.
   *
   * @return the fields being declared
   */
  VariableDeclarationList get fields => _fieldList;

  /**
   * Return `true` if the fields are static.
   *
   * @return `true` if the fields are declared to be static
   */
  bool get isStatic => staticKeyword != null;

  /**
   * Set the fields being declared to the given list of variables.
   *
   * @param fieldList the fields being declared
   */
  void set fields(VariableDeclarationList fieldList) {
    fieldList = becomeParentOf(fieldList);
  }

  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_fieldList, visitor);
  }

  Token get firstTokenAfterCommentAndMetadata {
    if (staticKeyword != null) {
      return staticKeyword;
    }
    return _fieldList.beginToken;
  }
}

/**
 * Instances of the class `FieldFormalParameter` represent a field formal parameter.
 *
 * <pre>
 * fieldFormalParameter ::=
 *     ('final' [TypeName] | 'const' [TypeName] | 'var' | [TypeName])? 'this' '.' [SimpleIdentifier] [FormalParameterList]?
 * </pre>
 */
class FieldFormalParameter extends NormalFormalParameter {
  /**
   * The token representing either the 'final', 'const' or 'var' keyword, or `null` if no
   * keyword was used.
   */
  Token keyword;

  /**
   * The name of the declared type of the parameter, or `null` if the parameter does not have
   * a declared type.
   */
  TypeName _type;

  /**
   * The token representing the 'this' keyword.
   */
  Token thisToken;

  /**
   * The token representing the period.
   */
  Token period;

  /**
   * The parameters of the function-typed parameter, or `null` if this is not a function-typed
   * field formal parameter.
   */
  FormalParameterList _parameters;

  /**
   * Initialize a newly created formal parameter.
   *
   * @param comment the documentation comment associated with this parameter
   * @param metadata the annotations associated with this parameter
   * @param keyword the token representing either the 'final', 'const' or 'var' keyword
   * @param type the name of the declared type of the parameter
   * @param thisToken the token representing the 'this' keyword
   * @param period the token representing the period
   * @param identifier the name of the parameter being declared
   * @param parameters the parameters of the function-typed parameter, or `null` if this is
   *          not a function-typed field formal parameter
   */
  FieldFormalParameter(Comment comment, List<Annotation> metadata, this.keyword, TypeName type, this.thisToken, this.period, SimpleIdentifier identifier, FormalParameterList parameters) : super(comment, metadata, identifier) {
    this._type = becomeParentOf(type);
    this._parameters = becomeParentOf(parameters);
  }

  accept(AstVisitor visitor) => visitor.visitFieldFormalParameter(this);

  Token get beginToken {
    if (keyword != null) {
      return keyword;
    } else if (_type != null) {
      return _type.beginToken;
    }
    return thisToken;
  }

  Token get endToken => identifier.endToken;

  /**
   * Return the parameters of the function-typed parameter, or `null` if this is not a
   * function-typed field formal parameter.
   *
   * @return the parameters of the function-typed parameter
   */
  FormalParameterList get parameters => _parameters;

  /**
   * Return the name of the declared type of the parameter, or `null` if the parameter does
   * not have a declared type. Note that if this is a function-typed field formal parameter this is
   * the return type of the function.
   *
   * @return the name of the declared type of the parameter
   */
  TypeName get type => _type;

  bool get isConst => (keyword is KeywordToken) && identical((keyword as KeywordToken).keyword, Keyword.CONST);

  bool get isFinal => (keyword is KeywordToken) && identical((keyword as KeywordToken).keyword, Keyword.FINAL);

  /**
   * Set the parameters of the function-typed parameter to the given parameters.
   *
   * @param parameters the parameters of the function-typed parameter
   */
  void set parameters(FormalParameterList parameters) {
    this._parameters = becomeParentOf(parameters);
  }

  /**
   * Set the name of the declared type of the parameter to the given type name.
   *
   * @param typeName the name of the declared type of the parameter
   */
  void set type(TypeName typeName) {
    _type = becomeParentOf(typeName);
  }

  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_type, visitor);
    safelyVisitChild(identifier, visitor);
    safelyVisitChild(_parameters, visitor);
  }
}

/**
 * Instances of the class `ForEachStatement` represent a for-each statement.
 *
 * <pre>
 * forEachStatement ::=
 *     'for' '(' [DeclaredIdentifier] 'in' [Expression] ')' [Block]
 *   | 'for' '(' [SimpleIdentifier] 'in' [Expression] ')' [Block]
 * </pre>
 */
class ForEachStatement extends Statement {
  /**
   * The token representing the 'for' keyword.
   */
  Token forKeyword;

  /**
   * The left parenthesis.
   */
  Token leftParenthesis;

  /**
   * The declaration of the loop variable, or `null` if the loop variable is a simple
   * identifier.
   */
  DeclaredIdentifier _loopVariable;

  /**
   * The loop variable, or `null` if the loop variable is declared in the 'for'.
   */
  SimpleIdentifier _identifier;

  /**
   * The token representing the 'in' keyword.
   */
  Token inKeyword;

  /**
   * The expression evaluated to produce the iterator.
   */
  Expression _iterator;

  /**
   * The right parenthesis.
   */
  Token rightParenthesis;

  /**
   * The body of the loop.
   */
  Statement _body;

  /**
   * Initialize a newly created for-each statement.
   *
   * @param forKeyword the token representing the 'for' keyword
   * @param leftParenthesis the left parenthesis
   * @param loopVariable the declaration of the loop variable
   * @param iterator the expression evaluated to produce the iterator
   * @param rightParenthesis the right parenthesis
   * @param body the body of the loop
   */
  ForEachStatement.con1(this.forKeyword, this.leftParenthesis, DeclaredIdentifier loopVariable, this.inKeyword, Expression iterator, this.rightParenthesis, Statement body) {
    this._loopVariable = becomeParentOf(loopVariable);
    this._iterator = becomeParentOf(iterator);
    this._body = becomeParentOf(body);
  }

  /**
   * Initialize a newly created for-each statement.
   *
   * @param forKeyword the token representing the 'for' keyword
   * @param leftParenthesis the left parenthesis
   * @param identifier the loop variable
   * @param iterator the expression evaluated to produce the iterator
   * @param rightParenthesis the right parenthesis
   * @param body the body of the loop
   */
  ForEachStatement.con2(this.forKeyword, this.leftParenthesis, SimpleIdentifier identifier, this.inKeyword, Expression iterator, this.rightParenthesis, Statement body) {
    this._identifier = becomeParentOf(identifier);
    this._iterator = becomeParentOf(iterator);
    this._body = becomeParentOf(body);
  }

  accept(AstVisitor visitor) => visitor.visitForEachStatement(this);

  Token get beginToken => forKeyword;

  /**
   * Return the body of the loop.
   *
   * @return the body of the loop
   */
  Statement get body => _body;

  Token get endToken => _body.endToken;

  /**
   * Return the loop variable, or `null` if the loop variable is declared in the 'for'.
   *
   * @return the loop variable
   */
  SimpleIdentifier get identifier => _identifier;

  /**
   * Return the expression evaluated to produce the iterator.
   *
   * @return the expression evaluated to produce the iterator
   */
  Expression get iterator => _iterator;

  /**
   * Return the declaration of the loop variable, or `null` if the loop variable is a simple
   * identifier.
   *
   * @return the declaration of the loop variable
   */
  DeclaredIdentifier get loopVariable => _loopVariable;

  /**
   * Set the body of the loop to the given block.
   *
   * @param body the body of the loop
   */
  void set body(Statement body) {
    this._body = becomeParentOf(body);
  }

  /**
   * Set the loop variable to the given variable.
   *
   * @param identifier the loop variable
   */
  void set identifier(SimpleIdentifier identifier) {
    this._identifier = becomeParentOf(identifier);
  }

  /**
   * Set the expression evaluated to produce the iterator to the given expression.
   *
   * @param expression the expression evaluated to produce the iterator
   */
  void set iterator(Expression expression) {
    _iterator = becomeParentOf(expression);
  }

  /**
   * Set the declaration of the loop variable to the given variable.
   *
   * @param variable the declaration of the loop variable
   */
  void set loopVariable(DeclaredIdentifier variable) {
    _loopVariable = becomeParentOf(variable);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_loopVariable, visitor);
    safelyVisitChild(_identifier, visitor);
    safelyVisitChild(_iterator, visitor);
    safelyVisitChild(_body, visitor);
  }
}

/**
 * Instances of the class `ForStatement` represent a for statement.
 *
 * <pre>
 * forStatement ::=
 *     'for' '(' forLoopParts ')' [Statement]
 *
 * forLoopParts ::=
 *     forInitializerStatement ';' [Expression]? ';' [Expression]?
 *
 * forInitializerStatement ::=
 *     [DefaultFormalParameter]
 *   | [Expression]?
 * </pre>
 */
class ForStatement extends Statement {
  /**
   * The token representing the 'for' keyword.
   */
  Token forKeyword;

  /**
   * The left parenthesis.
   */
  Token leftParenthesis;

  /**
   * The declaration of the loop variables, or `null` if there are no variables. Note that a
   * for statement cannot have both a variable list and an initialization expression, but can
   * validly have neither.
   */
  VariableDeclarationList _variableList;

  /**
   * The initialization expression, or `null` if there is no initialization expression. Note
   * that a for statement cannot have both a variable list and an initialization expression, but can
   * validly have neither.
   */
  Expression _initialization;

  /**
   * The semicolon separating the initializer and the condition.
   */
  Token leftSeparator;

  /**
   * The condition used to determine when to terminate the loop, or `null` if there is no
   * condition.
   */
  Expression _condition;

  /**
   * The semicolon separating the condition and the updater.
   */
  Token rightSeparator;

  /**
   * The list of expressions run after each execution of the loop body.
   */
  NodeList<Expression> _updaters;

  /**
   * The right parenthesis.
   */
  Token rightParenthesis;

  /**
   * The body of the loop.
   */
  Statement _body;

  /**
   * Initialize a newly created for statement.
   *
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
  ForStatement(this.forKeyword, this.leftParenthesis, VariableDeclarationList variableList, Expression initialization, this.leftSeparator, Expression condition, this.rightSeparator, List<Expression> updaters, this.rightParenthesis, Statement body) {
    this._updaters = new NodeList<Expression>(this);
    this._variableList = becomeParentOf(variableList);
    this._initialization = becomeParentOf(initialization);
    this._condition = becomeParentOf(condition);
    this._updaters.addAll(updaters);
    this._body = becomeParentOf(body);
  }

  accept(AstVisitor visitor) => visitor.visitForStatement(this);

  Token get beginToken => forKeyword;

  /**
   * Return the body of the loop.
   *
   * @return the body of the loop
   */
  Statement get body => _body;

  /**
   * Return the condition used to determine when to terminate the loop, or `null` if there is
   * no condition.
   *
   * @return the condition used to determine when to terminate the loop
   */
  Expression get condition => _condition;

  Token get endToken => _body.endToken;

  /**
   * Return the initialization expression, or `null` if there is no initialization expression.
   *
   * @return the initialization expression
   */
  Expression get initialization => _initialization;

  /**
   * Return the list of expressions run after each execution of the loop body.
   *
   * @return the list of expressions run after each execution of the loop body
   */
  NodeList<Expression> get updaters => _updaters;

  /**
   * Return the declaration of the loop variables, or `null` if there are no variables.
   *
   * @return the declaration of the loop variables, or `null` if there are no variables
   */
  VariableDeclarationList get variables => _variableList;

  /**
   * Set the body of the loop to the given statement.
   *
   * @param body the body of the loop
   */
  void set body(Statement body) {
    this._body = becomeParentOf(body);
  }

  /**
   * Set the condition used to determine when to terminate the loop to the given expression.
   *
   * @param expression the condition used to determine when to terminate the loop
   */
  void set condition(Expression expression) {
    _condition = becomeParentOf(expression);
  }

  /**
   * Set the initialization expression to the given expression.
   *
   * @param initialization the initialization expression
   */
  void set initialization(Expression initialization) {
    this._initialization = becomeParentOf(initialization);
  }

  /**
   * Set the declaration of the loop variables to the given parameter.
   *
   * @param variableList the declaration of the loop variables
   */
  void set variables(VariableDeclarationList variableList) {
    variableList = becomeParentOf(variableList);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_variableList, visitor);
    safelyVisitChild(_initialization, visitor);
    safelyVisitChild(_condition, visitor);
    _updaters.accept(visitor);
    safelyVisitChild(_body, visitor);
  }
}

/**
 * The abstract class `FormalParameter` defines the behavior of objects representing a
 * parameter to a function.
 *
 * <pre>
 * formalParameter ::=
 *     [NormalFormalParameter]
 *   | [DefaultFormalParameter]
 *   | [DefaultFormalParameter]
 * </pre>
 */
abstract class FormalParameter extends AstNode {
  /**
   * Return the element representing this parameter, or `null` if this parameter has not been
   * resolved.
   *
   * @return the element representing this parameter
   */
  ParameterElement get element {
    SimpleIdentifier identifier = this.identifier;
    if (identifier == null) {
      return null;
    }
    return identifier.staticElement as ParameterElement;
  }

  /**
   * Return the name of the parameter being declared.
   *
   * @return the name of the parameter being declared
   */
  SimpleIdentifier get identifier;

  /**
   * Return the kind of this parameter.
   *
   * @return the kind of this parameter
   */
  ParameterKind get kind;

  /**
   * Return `true` if this parameter was declared with the 'const' modifier.
   *
   * @return `true` if this parameter was declared with the 'const' modifier
   */
  bool get isConst;

  /**
   * Return `true` if this parameter was declared with the 'final' modifier. Parameters that
   * are declared with the 'const' modifier will return `false` even though they are
   * implicitly final.
   *
   * @return `true` if this parameter was declared with the 'final' modifier
   */
  bool get isFinal;
}

/**
 * Instances of the class `FormalParameterList` represent the formal parameter list of a
 * method declaration, function declaration, or function type alias.
 *
 * While the grammar requires all optional formal parameters to follow all of the normal formal
 * parameters and at most one grouping of optional formal parameters, this class does not enforce
 * those constraints. All parameters are flattened into a single list, which can have any or all
 * kinds of parameters (normal, named, and positional) in any order.
 *
 * <pre>
 * formalParameterList ::=
 *     '(' ')'
 *   | '(' normalFormalParameters (',' optionalFormalParameters)? ')'
 *   | '(' optionalFormalParameters ')'
 *
 * normalFormalParameters ::=
 *     [NormalFormalParameter] (',' [NormalFormalParameter])*
 *
 * optionalFormalParameters ::=
 *     optionalPositionalFormalParameters
 *   | namedFormalParameters
 *
 * optionalPositionalFormalParameters ::=
 *     '[' [DefaultFormalParameter] (',' [DefaultFormalParameter])* ']'
 *
 * namedFormalParameters ::=
 *     '{' [DefaultFormalParameter] (',' [DefaultFormalParameter])* '}'
 * </pre>
 */
class FormalParameterList extends AstNode {
  /**
   * The left parenthesis.
   */
  Token _leftParenthesis;

  /**
   * The parameters associated with the method.
   */
  NodeList<FormalParameter> _parameters;

  /**
   * The left square bracket ('[') or left curly brace ('{') introducing the optional parameters, or
   * `null` if there are no optional parameters.
   */
  Token _leftDelimiter;

  /**
   * The right square bracket (']') or right curly brace ('}') introducing the optional parameters,
   * or `null` if there are no optional parameters.
   */
  Token _rightDelimiter;

  /**
   * The right parenthesis.
   */
  Token _rightParenthesis;

  /**
   * Initialize a newly created parameter list.
   *
   * @param leftParenthesis the left parenthesis
   * @param parameters the parameters associated with the method
   * @param leftDelimiter the left delimiter introducing the optional parameters
   * @param rightDelimiter the right delimiter introducing the optional parameters
   * @param rightParenthesis the right parenthesis
   */
  FormalParameterList(Token leftParenthesis, List<FormalParameter> parameters, Token leftDelimiter, Token rightDelimiter, Token rightParenthesis) {
    this._parameters = new NodeList<FormalParameter>(this);
    this._leftParenthesis = leftParenthesis;
    this._parameters.addAll(parameters);
    this._leftDelimiter = leftDelimiter;
    this._rightDelimiter = rightDelimiter;
    this._rightParenthesis = rightParenthesis;
  }

  accept(AstVisitor visitor) => visitor.visitFormalParameterList(this);

  Token get beginToken => _leftParenthesis;

  Token get endToken => _rightParenthesis;

  /**
   * Return the left square bracket ('[') or left curly brace ('{') introducing the optional
   * parameters, or `null` if there are no optional parameters.
   *
   * @return the left square bracket ('[') or left curly brace ('{') introducing the optional
   *         parameters
   */
  Token get leftDelimiter => _leftDelimiter;

  /**
   * Return the left parenthesis.
   *
   * @return the left parenthesis
   */
  Token get leftParenthesis => _leftParenthesis;

  /**
   * Return an array containing the elements representing the parameters in this list. The array
   * will contain `null`s if the parameters in this list have not been resolved.
   *
   * @return the elements representing the parameters in this list
   */
  List<ParameterElement> get parameterElements {
    int count = _parameters.length;
    List<ParameterElement> types = new List<ParameterElement>(count);
    for (int i = 0; i < count; i++) {
      types[i] = _parameters[i].element;
    }
    return types;
  }

  /**
   * Return the parameters associated with the method.
   *
   * @return the parameters associated with the method
   */
  NodeList<FormalParameter> get parameters => _parameters;

  /**
   * Return the right square bracket (']') or right curly brace ('}') introducing the optional
   * parameters, or `null` if there are no optional parameters.
   *
   * @return the right square bracket (']') or right curly brace ('}') introducing the optional
   *         parameters
   */
  Token get rightDelimiter => _rightDelimiter;

  /**
   * Return the right parenthesis.
   *
   * @return the right parenthesis
   */
  Token get rightParenthesis => _rightParenthesis;

  /**
   * Set the left square bracket ('[') or left curly brace ('{') introducing the optional parameters
   * to the given token.
   *
   * @param bracket the left delimiter introducing the optional parameters
   */
  void set leftDelimiter(Token bracket) {
    _leftDelimiter = bracket;
  }

  /**
   * Set the left parenthesis to the given token.
   *
   * @param parenthesis the left parenthesis
   */
  void set leftParenthesis(Token parenthesis) {
    _leftParenthesis = parenthesis;
  }

  /**
   * Set the right square bracket (']') or right curly brace ('}') introducing the optional
   * parameters to the given token.
   *
   * @param bracket the right delimiter introducing the optional parameters
   */
  void set rightDelimiter(Token bracket) {
    _rightDelimiter = bracket;
  }

  /**
   * Set the right parenthesis to the given token.
   *
   * @param parenthesis the right parenthesis
   */
  void set rightParenthesis(Token parenthesis) {
    _rightParenthesis = parenthesis;
  }

  void visitChildren(AstVisitor visitor) {
    _parameters.accept(visitor);
  }
}

/**
 * The abstract class `FunctionBody` defines the behavior common to objects representing the
 * body of a function or method.
 *
 * <pre>
 * functionBody ::=
 *     [BlockFunctionBody]
 *   | [EmptyFunctionBody]
 *   | [ExpressionFunctionBody]
 * </pre>
 */
abstract class FunctionBody extends AstNode {
}

/**
 * Instances of the class `FunctionDeclaration` wrap a [FunctionExpression] as a top-level declaration.
 *
 * <pre>
 * functionDeclaration ::=
 *     'external' functionSignature
 *   | functionSignature [FunctionBody]
 *
 * functionSignature ::=
 *     [Type]? ('get' | 'set')? [SimpleIdentifier] [FormalParameterList]
 * </pre>
 */
class FunctionDeclaration extends CompilationUnitMember {
  /**
   * The token representing the 'external' keyword, or `null` if this is not an external
   * function.
   */
  Token externalKeyword;

  /**
   * The return type of the function, or `null` if no return type was declared.
   */
  TypeName _returnType;

  /**
   * The token representing the 'get' or 'set' keyword, or `null` if this is a function
   * declaration rather than a property declaration.
   */
  Token propertyKeyword;

  /**
   * The name of the function, or `null` if the function is not named.
   */
  SimpleIdentifier _name;

  /**
   * The function expression being wrapped.
   */
  FunctionExpression _functionExpression;

  /**
   * Initialize a newly created function declaration.
   *
   * @param comment the documentation comment associated with this function
   * @param metadata the annotations associated with this function
   * @param externalKeyword the token representing the 'external' keyword
   * @param returnType the return type of the function
   * @param propertyKeyword the token representing the 'get' or 'set' keyword
   * @param name the name of the function
   * @param functionExpression the function expression being wrapped
   */
  FunctionDeclaration(Comment comment, List<Annotation> metadata, this.externalKeyword, TypeName returnType, this.propertyKeyword, SimpleIdentifier name, FunctionExpression functionExpression) : super(comment, metadata) {
    this._returnType = becomeParentOf(returnType);
    this._name = becomeParentOf(name);
    this._functionExpression = becomeParentOf(functionExpression);
  }

  accept(AstVisitor visitor) => visitor.visitFunctionDeclaration(this);

  ExecutableElement get element => _name != null ? (_name.staticElement as ExecutableElement) : null;

  Token get endToken => _functionExpression.endToken;

  /**
   * Return the function expression being wrapped.
   *
   * @return the function expression being wrapped
   */
  FunctionExpression get functionExpression => _functionExpression;

  /**
   * Return the name of the function, or `null` if the function is not named.
   *
   * @return the name of the function
   */
  SimpleIdentifier get name => _name;

  /**
   * Return the return type of the function, or `null` if no return type was declared.
   *
   * @return the return type of the function
   */
  TypeName get returnType => _returnType;

  /**
   * Return `true` if this function declares a getter.
   *
   * @return `true` if this function declares a getter
   */
  bool get isGetter => propertyKeyword != null && identical((propertyKeyword as KeywordToken).keyword, Keyword.GET);

  /**
   * Return `true` if this function declares a setter.
   *
   * @return `true` if this function declares a setter
   */
  bool get isSetter => propertyKeyword != null && identical((propertyKeyword as KeywordToken).keyword, Keyword.SET);

  /**
   * Set the function expression being wrapped to the given function expression.
   *
   * @param functionExpression the function expression being wrapped
   */
  void set functionExpression(FunctionExpression functionExpression) {
    functionExpression = becomeParentOf(functionExpression);
  }

  /**
   * Set the name of the function to the given identifier.
   *
   * @param identifier the name of the function
   */
  void set name(SimpleIdentifier identifier) {
    _name = becomeParentOf(identifier);
  }

  /**
   * Set the return type of the function to the given name.
   *
   * @param name the return type of the function
   */
  void set returnType(TypeName name) {
    _returnType = becomeParentOf(name);
  }

  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_returnType, visitor);
    safelyVisitChild(_name, visitor);
    safelyVisitChild(_functionExpression, visitor);
  }

  Token get firstTokenAfterCommentAndMetadata {
    if (externalKeyword != null) {
      return externalKeyword;
    }
    if (_returnType != null) {
      return _returnType.beginToken;
    } else if (propertyKeyword != null) {
      return propertyKeyword;
    } else if (_name != null) {
      return _name.beginToken;
    }
    return _functionExpression.beginToken;
  }
}

/**
 * Instances of the class `FunctionDeclarationStatement` wrap a [FunctionDeclaration
 ] as a statement.
 */
class FunctionDeclarationStatement extends Statement {
  /**
   * The function declaration being wrapped.
   */
  FunctionDeclaration _functionDeclaration;

  /**
   * Initialize a newly created function declaration statement.
   *
   * @param functionDeclaration the the function declaration being wrapped
   */
  FunctionDeclarationStatement(FunctionDeclaration functionDeclaration) {
    this._functionDeclaration = becomeParentOf(functionDeclaration);
  }

  accept(AstVisitor visitor) => visitor.visitFunctionDeclarationStatement(this);

  Token get beginToken => _functionDeclaration.beginToken;

  Token get endToken => _functionDeclaration.endToken;

  /**
   * Return the function declaration being wrapped.
   *
   * @return the function declaration being wrapped
   */
  FunctionDeclaration get functionDeclaration => _functionDeclaration;

  /**
   * Set the function declaration being wrapped to the given function declaration.
   *
   * @param functionDeclaration the function declaration being wrapped
   */
  void set functionExpression(FunctionDeclaration functionDeclaration) {
    this._functionDeclaration = becomeParentOf(functionDeclaration);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_functionDeclaration, visitor);
  }
}

/**
 * Instances of the class `FunctionExpression` represent a function expression.
 *
 * <pre>
 * functionExpression ::=
 *     [FormalParameterList] [FunctionBody]
 * </pre>
 */
class FunctionExpression extends Expression {
  /**
   * The parameters associated with the function.
   */
  FormalParameterList _parameters;

  /**
   * The body of the function, or `null` if this is an external function.
   */
  FunctionBody _body;

  /**
   * The element associated with the function, or `null` if the AST structure has not been
   * resolved.
   */
  ExecutableElement element;

  /**
   * Initialize a newly created function declaration.
   *
   * @param parameters the parameters associated with the function
   * @param body the body of the function
   */
  FunctionExpression(FormalParameterList parameters, FunctionBody body) {
    this._parameters = becomeParentOf(parameters);
    this._body = becomeParentOf(body);
  }

  accept(AstVisitor visitor) => visitor.visitFunctionExpression(this);

  Token get beginToken {
    if (_parameters != null) {
      return _parameters.beginToken;
    } else if (_body != null) {
      return _body.beginToken;
    }
    // This should never be reached because external functions must be named, hence either the body
    // or the name should be non-null.
    throw new IllegalStateException("Non-external functions must have a body");
  }

  /**
   * Return the body of the function, or `null` if this is an external function.
   *
   * @return the body of the function
   */
  FunctionBody get body => _body;

  Token get endToken {
    if (_body != null) {
      return _body.endToken;
    } else if (_parameters != null) {
      return _parameters.endToken;
    }
    // This should never be reached because external functions must be named, hence either the body
    // or the name should be non-null.
    throw new IllegalStateException("Non-external functions must have a body");
  }

  /**
   * Return the parameters associated with the function.
   *
   * @return the parameters associated with the function
   */
  FormalParameterList get parameters => _parameters;

  int get precedence => 16;

  /**
   * Set the body of the function to the given function body.
   *
   * @param functionBody the body of the function
   */
  void set body(FunctionBody functionBody) {
    _body = becomeParentOf(functionBody);
  }

  /**
   * Set the parameters associated with the function to the given list of parameters.
   *
   * @param parameters the parameters associated with the function
   */
  void set parameters(FormalParameterList parameters) {
    this._parameters = becomeParentOf(parameters);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_parameters, visitor);
    safelyVisitChild(_body, visitor);
  }
}

/**
 * Instances of the class `FunctionExpressionInvocation` represent the invocation of a
 * function resulting from evaluating an expression. Invocations of methods and other forms of
 * functions are represented by [MethodInvocation] nodes. Invocations of
 * getters and setters are represented by either [PrefixedIdentifier] or
 * [PropertyAccess] nodes.
 *
 * <pre>
 * functionExpressionInvoction ::=
 *     [Expression] [ArgumentList]
 * </pre>
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
   * The element associated with the function being invoked based on static type information, or
   * `null` if the AST structure has not been resolved or the function could not be resolved.
   */
  ExecutableElement staticElement;

  /**
   * The element associated with the function being invoked based on propagated type information, or
   * `null` if the AST structure has not been resolved or the function could not be resolved.
   */
  ExecutableElement _propagatedElement;

  /**
   * Initialize a newly created function expression invocation.
   *
   * @param function the expression producing the function being invoked
   * @param argumentList the list of arguments to the method
   */
  FunctionExpressionInvocation(Expression function, ArgumentList argumentList) {
    this._function = becomeParentOf(function);
    this._argumentList = becomeParentOf(argumentList);
  }

  accept(AstVisitor visitor) => visitor.visitFunctionExpressionInvocation(this);

  /**
   * Return the list of arguments to the method.
   *
   * @return the list of arguments to the method
   */
  ArgumentList get argumentList => _argumentList;

  Token get beginToken => _function.beginToken;

  /**
   * Return the best element available for the function being invoked. If resolution was able to
   * find a better element based on type propagation, that element will be returned. Otherwise, the
   * element found using the result of static analysis will be returned. If resolution has not been
   * performed, then `null` will be returned.
   *
   * @return the best element available for this function
   */
  ExecutableElement get bestElement {
    ExecutableElement element = propagatedElement;
    if (element == null) {
      element = staticElement;
    }
    return element;
  }

  Token get endToken => _argumentList.endToken;

  /**
   * Return the expression producing the function being invoked.
   *
   * @return the expression producing the function being invoked
   */
  Expression get function => _function;

  int get precedence => 15;

  /**
   * Return the element associated with the function being invoked based on propagated type
   * information, or `null` if the AST structure has not been resolved or the function could
   * not be resolved. One common example of the latter case is an expression whose value can change
   * over time.
   *
   * @return the element associated with the function being invoked
   */
  ExecutableElement get propagatedElement => _propagatedElement;

  /**
   * Set the list of arguments to the method to the given list.
   *
   * @param argumentList the list of arguments to the method
   */
  void set argumentList(ArgumentList argumentList) {
    this._argumentList = becomeParentOf(argumentList);
  }

  /**
   * Set the expression producing the function being invoked to the given expression.
   *
   * @param function the expression producing the function being invoked
   */
  void set function(Expression function) {
    function = becomeParentOf(function);
  }

  /**
   * Set the element associated with the function being invoked based on propagated type information
   * to the given element.
   *
   * @param element the element to be associated with the function being invoked
   */
  void set propagatedElement(ExecutableElement element) {
    _propagatedElement = element;
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_function, visitor);
    safelyVisitChild(_argumentList, visitor);
  }
}

/**
 * Instances of the class `FunctionTypeAlias` represent a function type alias.
 *
 * <pre>
 * functionTypeAlias ::=
 *      functionPrefix [TypeParameterList]? [FormalParameterList] ';'
 *
 * functionPrefix ::=
 *     [TypeName]? [SimpleIdentifier]
 * </pre>
 */
class FunctionTypeAlias extends TypeAlias {
  /**
   * The name of the return type of the function type being defined, or `null` if no return
   * type was given.
   */
  TypeName _returnType;

  /**
   * The name of the function type being declared.
   */
  SimpleIdentifier _name;

  /**
   * The type parameters for the function type, or `null` if the function type does not have
   * any type parameters.
   */
  TypeParameterList _typeParameters;

  /**
   * The parameters associated with the function type.
   */
  FormalParameterList _parameters;

  /**
   * Initialize a newly created function type alias.
   *
   * @param comment the documentation comment associated with this type alias
   * @param metadata the annotations associated with this type alias
   * @param keyword the token representing the 'typedef' keyword
   * @param returnType the name of the return type of the function type being defined
   * @param name the name of the type being declared
   * @param typeParameters the type parameters for the type
   * @param parameters the parameters associated with the function
   * @param semicolon the semicolon terminating the declaration
   */
  FunctionTypeAlias(Comment comment, List<Annotation> metadata, Token keyword, TypeName returnType, SimpleIdentifier name, TypeParameterList typeParameters, FormalParameterList parameters, Token semicolon) : super(comment, metadata, keyword, semicolon) {
    this._returnType = becomeParentOf(returnType);
    this._name = becomeParentOf(name);
    this._typeParameters = becomeParentOf(typeParameters);
    this._parameters = becomeParentOf(parameters);
  }

  accept(AstVisitor visitor) => visitor.visitFunctionTypeAlias(this);

  FunctionTypeAliasElement get element => _name != null ? (_name.staticElement as FunctionTypeAliasElement) : null;

  /**
   * Return the name of the function type being declared.
   *
   * @return the name of the function type being declared
   */
  SimpleIdentifier get name => _name;

  /**
   * Return the parameters associated with the function type.
   *
   * @return the parameters associated with the function type
   */
  FormalParameterList get parameters => _parameters;

  /**
   * Return the name of the return type of the function type being defined, or `null` if no
   * return type was given.
   *
   * @return the name of the return type of the function type being defined
   */
  TypeName get returnType => _returnType;

  /**
   * Return the type parameters for the function type, or `null` if the function type does not
   * have any type parameters.
   *
   * @return the type parameters for the function type
   */
  TypeParameterList get typeParameters => _typeParameters;

  /**
   * Set the name of the function type being declared to the given identifier.
   *
   * @param name the name of the function type being declared
   */
  void set name(SimpleIdentifier name) {
    this._name = becomeParentOf(name);
  }

  /**
   * Set the parameters associated with the function type to the given list of parameters.
   *
   * @param parameters the parameters associated with the function type
   */
  void set parameters(FormalParameterList parameters) {
    this._parameters = becomeParentOf(parameters);
  }

  /**
   * Set the name of the return type of the function type being defined to the given type name.
   *
   * @param typeName the name of the return type of the function type being defined
   */
  void set returnType(TypeName typeName) {
    _returnType = becomeParentOf(typeName);
  }

  /**
   * Set the type parameters for the function type to the given list of parameters.
   *
   * @param typeParameters the type parameters for the function type
   */
  void set typeParameters(TypeParameterList typeParameters) {
    this._typeParameters = becomeParentOf(typeParameters);
  }

  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_returnType, visitor);
    safelyVisitChild(_name, visitor);
    safelyVisitChild(_typeParameters, visitor);
    safelyVisitChild(_parameters, visitor);
  }
}

/**
 * Instances of the class `FunctionTypedFormalParameter` represent a function-typed formal
 * parameter.
 *
 * <pre>
 * functionSignature ::=
 *     [TypeName]? [SimpleIdentifier] [FormalParameterList]
 * </pre>
 */
class FunctionTypedFormalParameter extends NormalFormalParameter {
  /**
   * The return type of the function, or `null` if the function does not have a return type.
   */
  TypeName _returnType;

  /**
   * The parameters of the function-typed parameter.
   */
  FormalParameterList _parameters;

  /**
   * Initialize a newly created formal parameter.
   *
   * @param comment the documentation comment associated with this parameter
   * @param metadata the annotations associated with this parameter
   * @param returnType the return type of the function, or `null` if the function does not
   *          have a return type
   * @param identifier the name of the function-typed parameter
   * @param parameters the parameters of the function-typed parameter
   */
  FunctionTypedFormalParameter(Comment comment, List<Annotation> metadata, TypeName returnType, SimpleIdentifier identifier, FormalParameterList parameters) : super(comment, metadata, identifier) {
    this._returnType = becomeParentOf(returnType);
    this._parameters = becomeParentOf(parameters);
  }

  accept(AstVisitor visitor) => visitor.visitFunctionTypedFormalParameter(this);

  Token get beginToken {
    if (_returnType != null) {
      return _returnType.beginToken;
    }
    return identifier.beginToken;
  }

  Token get endToken => _parameters.endToken;

  /**
   * Return the parameters of the function-typed parameter.
   *
   * @return the parameters of the function-typed parameter
   */
  FormalParameterList get parameters => _parameters;

  /**
   * Return the return type of the function, or `null` if the function does not have a return
   * type.
   *
   * @return the return type of the function
   */
  TypeName get returnType => _returnType;

  bool get isConst => false;

  bool get isFinal => false;

  /**
   * Set the parameters of the function-typed parameter to the given parameters.
   *
   * @param parameters the parameters of the function-typed parameter
   */
  void set parameters(FormalParameterList parameters) {
    this._parameters = becomeParentOf(parameters);
  }

  /**
   * Set the return type of the function to the given type.
   *
   * @param returnType the return type of the function
   */
  void set returnType(TypeName returnType) {
    this._returnType = becomeParentOf(returnType);
  }

  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_returnType, visitor);
    safelyVisitChild(identifier, visitor);
    safelyVisitChild(_parameters, visitor);
  }
}

/**
 * Instances of the class `HideCombinator` represent a combinator that restricts the names
 * being imported to those that are not in a given list.
 *
 * <pre>
 * hideCombinator ::=
 *     'hide' [SimpleIdentifier] (',' [SimpleIdentifier])*
 * </pre>
 */
class HideCombinator extends Combinator {
  /**
   * The list of names from the library that are hidden by this combinator.
   */
  NodeList<SimpleIdentifier> _hiddenNames;

  /**
   * Initialize a newly created import show combinator.
   *
   * @param keyword the comma introducing the combinator
   * @param hiddenNames the list of names from the library that are hidden by this combinator
   */
  HideCombinator(Token keyword, List<SimpleIdentifier> hiddenNames) : super(keyword) {
    this._hiddenNames = new NodeList<SimpleIdentifier>(this);
    this._hiddenNames.addAll(hiddenNames);
  }

  accept(AstVisitor visitor) => visitor.visitHideCombinator(this);

  Token get endToken => _hiddenNames.endToken;

  /**
   * Return the list of names from the library that are hidden by this combinator.
   *
   * @return the list of names from the library that are hidden by this combinator
   */
  NodeList<SimpleIdentifier> get hiddenNames => _hiddenNames;

  void visitChildren(AstVisitor visitor) {
    _hiddenNames.accept(visitor);
  }
}

/**
 * The abstract class `Identifier` defines the behavior common to nodes that represent an
 * identifier.
 *
 * <pre>
 * identifier ::=
 *     [SimpleIdentifier]
 *   | [PrefixedIdentifier]
 * </pre>
 */
abstract class Identifier extends Expression {
  /**
   * Return `true` if the given name is visible only within the library in which it is
   * declared.
   *
   * @param name the name being tested
   * @return `true` if the given name is private
   */
  static bool isPrivateName(String name) => StringUtilities.startsWithChar(name, 0x5F);

  /**
   * Return the best element available for this operator. If resolution was able to find a better
   * element based on type propagation, that element will be returned. Otherwise, the element found
   * using the result of static analysis will be returned. If resolution has not been performed,
   * then `null` will be returned.
   *
   * @return the best element available for this operator
   */
  Element get bestElement;

  /**
   * Return the lexical representation of the identifier.
   *
   * @return the lexical representation of the identifier
   */
  String get name;

  /**
   * Return the element associated with this identifier based on propagated type information, or
   * `null` if the AST structure has not been resolved or if this identifier could not be
   * resolved. One example of the latter case is an identifier that is not defined within the scope
   * in which it appears.
   *
   * @return the element associated with this identifier
   */
  Element get propagatedElement;

  /**
   * Return the element associated with this identifier based on static type information, or
   * `null` if the AST structure has not been resolved or if this identifier could not be
   * resolved. One example of the latter case is an identifier that is not defined within the scope
   * in which it appears
   *
   * @return the element associated with the operator
   */
  Element get staticElement;

  bool get isAssignable => true;
}

/**
 * Instances of the class `IfStatement` represent an if statement.
 *
 * <pre>
 * ifStatement ::=
 *     'if' '(' [Expression] ')' [Statement] ('else' [Statement])?
 * </pre>
 */
class IfStatement extends Statement {
  /**
   * The token representing the 'if' keyword.
   */
  Token ifKeyword;

  /**
   * The left parenthesis.
   */
  Token leftParenthesis;

  /**
   * The condition used to determine which of the statements is executed next.
   */
  Expression _condition;

  /**
   * The right parenthesis.
   */
  Token rightParenthesis;

  /**
   * The statement that is executed if the condition evaluates to `true`.
   */
  Statement _thenStatement;

  /**
   * The token representing the 'else' keyword, or `null` if there is no else statement.
   */
  Token elseKeyword;

  /**
   * The statement that is executed if the condition evaluates to `false`, or `null` if
   * there is no else statement.
   */
  Statement _elseStatement;

  /**
   * Initialize a newly created if statement.
   *
   * @param ifKeyword the token representing the 'if' keyword
   * @param leftParenthesis the left parenthesis
   * @param condition the condition used to determine which of the statements is executed next
   * @param rightParenthesis the right parenthesis
   * @param thenStatement the statement that is executed if the condition evaluates to `true`
   * @param elseKeyword the token representing the 'else' keyword
   * @param elseStatement the statement that is executed if the condition evaluates to `false`
   */
  IfStatement(this.ifKeyword, this.leftParenthesis, Expression condition, this.rightParenthesis, Statement thenStatement, this.elseKeyword, Statement elseStatement) {
    this._condition = becomeParentOf(condition);
    this._thenStatement = becomeParentOf(thenStatement);
    this._elseStatement = becomeParentOf(elseStatement);
  }

  accept(AstVisitor visitor) => visitor.visitIfStatement(this);

  Token get beginToken => ifKeyword;

  /**
   * Return the condition used to determine which of the statements is executed next.
   *
   * @return the condition used to determine which statement is executed next
   */
  Expression get condition => _condition;

  /**
   * Return the statement that is executed if the condition evaluates to `false`, or
   * `null` if there is no else statement.
   *
   * @return the statement that is executed if the condition evaluates to `false`
   */
  Statement get elseStatement => _elseStatement;

  Token get endToken {
    if (_elseStatement != null) {
      return _elseStatement.endToken;
    }
    return _thenStatement.endToken;
  }

  /**
   * Return the statement that is executed if the condition evaluates to `true`.
   *
   * @return the statement that is executed if the condition evaluates to `true`
   */
  Statement get thenStatement => _thenStatement;

  /**
   * Set the condition used to determine which of the statements is executed next to the given
   * expression.
   *
   * @param expression the condition used to determine which statement is executed next
   */
  void set condition(Expression expression) {
    _condition = becomeParentOf(expression);
  }

  /**
   * Set the statement that is executed if the condition evaluates to `false` to the given
   * statement.
   *
   * @param statement the statement that is executed if the condition evaluates to `false`
   */
  void set elseStatement(Statement statement) {
    _elseStatement = becomeParentOf(statement);
  }

  /**
   * Set the statement that is executed if the condition evaluates to `true` to the given
   * statement.
   *
   * @param statement the statement that is executed if the condition evaluates to `true`
   */
  void set thenStatement(Statement statement) {
    _thenStatement = becomeParentOf(statement);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_condition, visitor);
    safelyVisitChild(_thenStatement, visitor);
    safelyVisitChild(_elseStatement, visitor);
  }
}

/**
 * Instances of the class `ImplementsClause` represent the "implements" clause in an class
 * declaration.
 *
 * <pre>
 * implementsClause ::=
 *     'implements' [TypeName] (',' [TypeName])*
 * </pre>
 */
class ImplementsClause extends AstNode {
  /**
   * The token representing the 'implements' keyword.
   */
  Token keyword;

  /**
   * The interfaces that are being implemented.
   */
  NodeList<TypeName> _interfaces;

  /**
   * Initialize a newly created implements clause.
   *
   * @param keyword the token representing the 'implements' keyword
   * @param interfaces the interfaces that are being implemented
   */
  ImplementsClause(this.keyword, List<TypeName> interfaces) {
    this._interfaces = new NodeList<TypeName>(this);
    this._interfaces.addAll(interfaces);
  }

  accept(AstVisitor visitor) => visitor.visitImplementsClause(this);

  Token get beginToken => keyword;

  Token get endToken => _interfaces.endToken;

  /**
   * Return the list of the interfaces that are being implemented.
   *
   * @return the list of the interfaces that are being implemented
   */
  NodeList<TypeName> get interfaces => _interfaces;

  void visitChildren(AstVisitor visitor) {
    _interfaces.accept(visitor);
  }
}

/**
 * Instances of the class `ImportDirective` represent an import directive.
 *
 * <pre>
 * importDirective ::=
 *     [Annotation] 'import' [StringLiteral] ('as' identifier)? [Combinator]* ';'
 * </pre>
 */
class ImportDirective extends NamespaceDirective {
  static Comparator<ImportDirective> COMPARATOR = (ImportDirective import1, ImportDirective import2) {
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
    String prefixStr1 = prefix1 != null ? prefix1.name : null;
    String prefixStr2 = prefix2 != null ? prefix2.name : null;
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
    for (Combinator combinator in combinators1) {
      if (combinator is HideCombinator) {
        NodeList<SimpleIdentifier> hides = combinator.hiddenNames;
        for (SimpleIdentifier simpleIdentifier in hides) {
          allHides1.add(simpleIdentifier.name);
        }
      } else {
        NodeList<SimpleIdentifier> shows = (combinator as ShowCombinator).shownNames;
        for (SimpleIdentifier simpleIdentifier in shows) {
          allShows1.add(simpleIdentifier.name);
        }
      }
    }
    NodeList<Combinator> combinators2 = import2.combinators;
    List<String> allHides2 = new List<String>();
    List<String> allShows2 = new List<String>();
    for (Combinator combinator in combinators2) {
      if (combinator is HideCombinator) {
        NodeList<SimpleIdentifier> hides = combinator.hiddenNames;
        for (SimpleIdentifier simpleIdentifier in hides) {
          allHides2.add(simpleIdentifier.name);
        }
      } else {
        NodeList<SimpleIdentifier> shows = (combinator as ShowCombinator).shownNames;
        for (SimpleIdentifier simpleIdentifier in shows) {
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
    if (!javaCollectionContainsAll(allHides1, allHides2)) {
      return -1;
    }
    if (!javaCollectionContainsAll(allShows1, allShows2)) {
      return -1;
    }
    return 0;
  };

  /**
   * The token representing the 'as' token, or `null` if the imported names are not prefixed.
   */
  Token asToken;

  /**
   * The prefix to be used with the imported names, or `null` if the imported names are not
   * prefixed.
   */
  SimpleIdentifier _prefix;

  /**
   * Initialize a newly created import directive.
   *
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   * @param keyword the token representing the 'import' keyword
   * @param libraryUri the URI of the library being imported
   * @param asToken the token representing the 'as' token
   * @param prefix the prefix to be used with the imported names
   * @param combinators the combinators used to control how names are imported
   * @param semicolon the semicolon terminating the directive
   */
  ImportDirective(Comment comment, List<Annotation> metadata, Token keyword, StringLiteral libraryUri, this.asToken, SimpleIdentifier prefix, List<Combinator> combinators, Token semicolon) : super(comment, metadata, keyword, libraryUri, combinators, semicolon) {
    this._prefix = becomeParentOf(prefix);
  }

  accept(AstVisitor visitor) => visitor.visitImportDirective(this);

  ImportElement get element => super.element as ImportElement;

  /**
   * Return the prefix to be used with the imported names, or `null` if the imported names are
   * not prefixed.
   *
   * @return the prefix to be used with the imported names
   */
  SimpleIdentifier get prefix => _prefix;

  LibraryElement get uriElement {
    ImportElement element = this.element;
    if (element == null) {
      return null;
    }
    return element.importedLibrary;
  }

  /**
   * Set the prefix to be used with the imported names to the given identifier.
   *
   * @param prefix the prefix to be used with the imported names
   */
  void set prefix(SimpleIdentifier prefix) {
    this._prefix = becomeParentOf(prefix);
  }

  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_prefix, visitor);
    combinators.accept(visitor);
  }
}

/**
 * Instances of the class `IndexExpression` represent an index expression.
 *
 * <pre>
 * indexExpression ::=
 *     [Expression] '[' [Expression] ']'
 * </pre>
 */
class IndexExpression extends Expression {
  /**
   * The expression used to compute the object being indexed, or `null` if this index
   * expression is part of a cascade expression.
   */
  Expression _target;

  /**
   * The period ("..") before a cascaded index expression, or `null` if this index expression
   * is not part of a cascade expression.
   */
  Token period;

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
   * The element associated with the operator based on the static type of the target, or
   * `null` if the AST structure has not been resolved or if the operator could not be
   * resolved.
   */
  MethodElement _staticElement;

  /**
   * The element associated with the operator based on the propagated type of the target, or
   * `null` if the AST structure has not been resolved or if the operator could not be
   * resolved.
   */
  MethodElement _propagatedElement;

  /**
   * If this expression is both in a getter and setter context, the [AuxiliaryElements] will
   * be set to hold onto the static and propagated information. The auxiliary element will hold onto
   * the elements from the getter context.
   */
  AuxiliaryElements auxiliaryElements = null;

  /**
   * Initialize a newly created index expression.
   *
   * @param target the expression used to compute the object being indexed
   * @param leftBracket the left square bracket
   * @param index the expression used to compute the index
   * @param rightBracket the right square bracket
   */
  IndexExpression.forTarget(Expression target, Token leftBracket, Expression index, Token rightBracket) {
    this._target = becomeParentOf(target);
    this._leftBracket = leftBracket;
    this._index = becomeParentOf(index);
    this._rightBracket = rightBracket;
  }

  /**
   * Initialize a newly created index expression.
   *
   * @param period the period ("..") before a cascaded index expression
   * @param leftBracket the left square bracket
   * @param index the expression used to compute the index
   * @param rightBracket the right square bracket
   */
  IndexExpression.forCascade(this.period, Token leftBracket, Expression index, Token rightBracket) {
    this._leftBracket = leftBracket;
    this._index = becomeParentOf(index);
    this._rightBracket = rightBracket;
  }

  accept(AstVisitor visitor) => visitor.visitIndexExpression(this);

  Token get beginToken {
    if (_target != null) {
      return _target.beginToken;
    }
    return period;
  }

  /**
   * Return the best element available for this operator. If resolution was able to find a better
   * element based on type propagation, that element will be returned. Otherwise, the element found
   * using the result of static analysis will be returned. If resolution has not been performed,
   * then `null` will be returned.
   *
   * @return the best element available for this operator
   */
  MethodElement get bestElement {
    MethodElement element = propagatedElement;
    if (element == null) {
      element = staticElement;
    }
    return element;
  }

  Token get endToken => _rightBracket;

  /**
   * Return the expression used to compute the index.
   *
   * @return the expression used to compute the index
   */
  Expression get index => _index;

  /**
   * Return the left square bracket.
   *
   * @return the left square bracket
   */
  Token get leftBracket => _leftBracket;

  int get precedence => 15;

  /**
   * Return the element associated with the operator based on the propagated type of the target, or
   * `null` if the AST structure has not been resolved or if the operator could not be
   * resolved. One example of the latter case is an operator that is not defined for the type of the
   * target.
   *
   * @return the element associated with this operator
   */
  MethodElement get propagatedElement => _propagatedElement;

  /**
   * Return the expression used to compute the object being indexed. If this index expression is not
   * part of a cascade expression, then this is the same as [getTarget]. If this index
   * expression is part of a cascade expression, then the target expression stored with the cascade
   * expression is returned.
   *
   * @return the expression used to compute the object being indexed
   * @see #getTarget()
   */
  Expression get realTarget {
    if (isCascaded) {
      AstNode ancestor = parent;
      while (ancestor is! CascadeExpression) {
        if (ancestor == null) {
          return _target;
        }
        ancestor = ancestor.parent;
      }
      return (ancestor as CascadeExpression).target;
    }
    return _target;
  }

  /**
   * Return the right square bracket.
   *
   * @return the right square bracket
   */
  Token get rightBracket => _rightBracket;

  /**
   * Return the element associated with the operator based on the static type of the target, or
   * `null` if the AST structure has not been resolved or if the operator could not be
   * resolved. One example of the latter case is an operator that is not defined for the type of the
   * target.
   *
   * @return the element associated with the operator
   */
  MethodElement get staticElement => _staticElement;

  /**
   * Return the expression used to compute the object being indexed, or `null` if this index
   * expression is part of a cascade expression.
   *
   * @return the expression used to compute the object being indexed
   * @see #getRealTarget()
   */
  Expression get target => _target;

  /**
   * Return `true` if this expression is computing a right-hand value.
   *
   * Note that [inGetterContext] and [inSetterContext] are not opposites, nor are
   * they mutually exclusive. In other words, it is possible for both methods to return `true`
   * when invoked on the same node.
   *
   * @return `true` if this expression is in a context where the operator '[]' will be invoked
   */
  bool inGetterContext() {
    AstNode parent = this.parent;
    if (parent is AssignmentExpression) {
      AssignmentExpression assignment = parent;
      if (identical(assignment.leftHandSide, this) && identical(assignment.operator.type, TokenType.EQ)) {
        return false;
      }
    }
    return true;
  }

  /**
   * Return `true` if this expression is computing a left-hand value.
   *
   * Note that [inGetterContext] and [inSetterContext] are not opposites, nor are
   * they mutually exclusive. In other words, it is possible for both methods to return `true`
   * when invoked on the same node.
   *
   * @return `true` if this expression is in a context where the operator '[]=' will be
   *         invoked
   */
  bool inSetterContext() {
    AstNode parent = this.parent;
    if (parent is PrefixExpression) {
      return parent.operator.type.isIncrementOperator;
    } else if (parent is PostfixExpression) {
      return true;
    } else if (parent is AssignmentExpression) {
      return identical(parent.leftHandSide, this);
    }
    return false;
  }

  bool get isAssignable => true;

  /**
   * Return `true` if this expression is cascaded. If it is, then the target of this
   * expression is not stored locally but is stored in the nearest ancestor that is a
   * [CascadeExpression].
   *
   * @return `true` if this expression is cascaded
   */
  bool get isCascaded => period != null;

  /**
   * Set the expression used to compute the index to the given expression.
   *
   * @param expression the expression used to compute the index
   */
  void set index(Expression expression) {
    _index = becomeParentOf(expression);
  }

  /**
   * Set the left square bracket to the given token.
   *
   * @param bracket the left square bracket
   */
  void set leftBracket(Token bracket) {
    _leftBracket = bracket;
  }

  /**
   * Set the element associated with the operator based on the propagated type of the target to the
   * given element.
   *
   * @param element the element to be associated with this operator
   */
  void set propagatedElement(MethodElement element) {
    _propagatedElement = element;
  }

  /**
   * Set the right square bracket to the given token.
   *
   * @param bracket the right square bracket
   */
  void set rightBracket(Token bracket) {
    _rightBracket = bracket;
  }

  /**
   * Set the element associated with the operator based on the static type of the target to the
   * given element.
   *
   * @param element the static element to be associated with the operator
   */
  void set staticElement(MethodElement element) {
    _staticElement = element;
  }

  /**
   * Set the expression used to compute the object being indexed to the given expression.
   *
   * @param expression the expression used to compute the object being indexed
   */
  void set target(Expression expression) {
    _target = becomeParentOf(expression);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_target, visitor);
    safelyVisitChild(_index, visitor);
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is known based on
   * propagated type information, then return the parameter element representing the parameter to
   * which the value of the index expression will be bound. Otherwise, return `null`.
   *
   * This method is only intended to be used by [Expression#getPropagatedParameterElement].
   *
   * @return the parameter element representing the parameter to which the value of the index
   *         expression will be bound
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
   * value of the index expression will be bound. Otherwise, return `null`.
   *
   * This method is only intended to be used by [Expression#getStaticParameterElement].
   *
   * @return the parameter element representing the parameter to which the value of the index
   *         expression will be bound
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
 * Instances of the class `InstanceCreationExpression` represent an instance creation
 * expression.
 *
 * <pre>
 * newExpression ::=
 *     ('new' | 'const') [TypeName] ('.' [SimpleIdentifier])? [ArgumentList]
 * </pre>
 */
class InstanceCreationExpression extends Expression {
  /**
   * The keyword used to indicate how an object should be created.
   */
  Token keyword;

  /**
   * The name of the constructor to be invoked.
   */
  ConstructorName constructorName;

  /**
   * The list of arguments to the constructor.
   */
  ArgumentList _argumentList;

  /**
   * The element associated with the constructor based on static type information, or `null`
   * if the AST structure has not been resolved or if the constructor could not be resolved.
   */
  ConstructorElement staticElement;

  /**
   * Initialize a newly created instance creation expression.
   *
   * @param keyword the keyword used to indicate how an object should be created
   * @param constructorName the name of the constructor to be invoked
   * @param argumentList the list of arguments to the constructor
   */
  InstanceCreationExpression(this.keyword, ConstructorName constructorName, ArgumentList argumentList) {
    this.constructorName = becomeParentOf(constructorName);
    this._argumentList = becomeParentOf(argumentList);
  }

  accept(AstVisitor visitor) => visitor.visitInstanceCreationExpression(this);

  /**
   * Return the list of arguments to the constructor.
   *
   * @return the list of arguments to the constructor
   */
  ArgumentList get argumentList => _argumentList;

  Token get beginToken => keyword;

  Token get endToken => _argumentList.endToken;

  int get precedence => 15;

  /**
   * Return `true` if this creation expression is used to invoke a constant constructor.
   *
   * @return `true` if this creation expression is used to invoke a constant constructor
   */
  bool get isConst => keyword is KeywordToken && identical((keyword as KeywordToken).keyword, Keyword.CONST);

  /**
   * Set the list of arguments to the constructor to the given list.
   *
   * @param argumentList the list of arguments to the constructor
   */
  void set argumentList(ArgumentList argumentList) {
    this._argumentList = becomeParentOf(argumentList);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(constructorName, visitor);
    safelyVisitChild(_argumentList, visitor);
  }
}

/**
 * Instances of the class `IntegerLiteral` represent an integer literal expression.
 *
 * <pre>
 * integerLiteral ::=
 *     decimalIntegerLiteral
 *   | hexidecimalIntegerLiteral
 *
 * decimalIntegerLiteral ::=
 *     decimalDigit+
 *
 * hexidecimalIntegerLiteral ::=
 *     '0x' hexidecimalDigit+
 *   | '0X' hexidecimalDigit+
 * </pre>
 */
class IntegerLiteral extends Literal {
  /**
   * The token representing the literal.
   */
  Token literal;

  /**
   * The value of the literal.
   */
  int value = 0;

  /**
   * Initialize a newly created integer literal.
   *
   * @param literal the token representing the literal
   * @param value the value of the literal
   */
  IntegerLiteral(this.literal, this.value);

  accept(AstVisitor visitor) => visitor.visitIntegerLiteral(this);

  Token get beginToken => literal;

  Token get endToken => literal;

  void visitChildren(AstVisitor visitor) {
  }
}

/**
 * The abstract class `InterpolationElement` defines the behavior common to elements within a
 * [StringInterpolation].
 *
 * <pre>
 * interpolationElement ::=
 *     [InterpolationExpression]
 *   | [InterpolationString]
 * </pre>
 */
abstract class InterpolationElement extends AstNode {
}

/**
 * Instances of the class `InterpolationExpression` represent an expression embedded in a
 * string interpolation.
 *
 * <pre>
 * interpolationExpression ::=
 *     '$' [SimpleIdentifier]
 *   | '$' '{' [Expression] '}'
 * </pre>
 */
class InterpolationExpression extends InterpolationElement {
  /**
   * The token used to introduce the interpolation expression; either '$' if the expression is a
   * simple identifier or '${' if the expression is a full expression.
   */
  Token leftBracket;

  /**
   * The expression to be evaluated for the value to be converted into a string.
   */
  Expression _expression;

  /**
   * The right curly bracket, or `null` if the expression is an identifier without brackets.
   */
  Token rightBracket;

  /**
   * Initialize a newly created interpolation expression.
   *
   * @param leftBracket the left curly bracket
   * @param expression the expression to be evaluated for the value to be converted into a string
   * @param rightBracket the right curly bracket
   */
  InterpolationExpression(this.leftBracket, Expression expression, this.rightBracket) {
    this._expression = becomeParentOf(expression);
  }

  accept(AstVisitor visitor) => visitor.visitInterpolationExpression(this);

  Token get beginToken => leftBracket;

  Token get endToken {
    if (rightBracket != null) {
      return rightBracket;
    }
    return _expression.endToken;
  }

  /**
   * Return the expression to be evaluated for the value to be converted into a string.
   *
   * @return the expression to be evaluated for the value to be converted into a string
   */
  Expression get expression => _expression;

  /**
   * Set the expression to be evaluated for the value to be converted into a string to the given
   * expression.
   *
   * @param expression the expression to be evaluated for the value to be converted into a string
   */
  void set expression(Expression expression) {
    this._expression = becomeParentOf(expression);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_expression, visitor);
  }
}

/**
 * Instances of the class `InterpolationString` represent a non-empty substring of an
 * interpolated string.
 *
 * <pre>
 * interpolationString ::=
 *     characters
 * </pre>
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
   *
   * @param the characters that will be added to the string
   * @param value the value of the literal
   */
  InterpolationString(Token contents, String value) {
    this._contents = contents;
    this._value = value;
  }

  accept(AstVisitor visitor) => visitor.visitInterpolationString(this);

  Token get beginToken => _contents;

  /**
   * Return the characters that will be added to the string.
   *
   * @return the characters that will be added to the string
   */
  Token get contents => _contents;

  Token get endToken => _contents;

  /**
   * Return the value of the literal.
   *
   * @return the value of the literal
   */
  String get value => _value;

  /**
   * Set the characters that will be added to the string to those in the given string.
   *
   * @param string the characters that will be added to the string
   */
  void set contents(Token string) {
    _contents = string;
  }

  /**
   * Set the value of the literal to the given string.
   *
   * @param string the value of the literal
   */
  void set value(String string) {
    _value = string;
  }

  void visitChildren(AstVisitor visitor) {
  }
}

/**
 * Instances of the class `IsExpression` represent an is expression.
 *
 * <pre>
 * isExpression ::=
 *     [Expression] 'is' '!'? [TypeName]
 * </pre>
 */
class IsExpression extends Expression {
  /**
   * The expression used to compute the value whose type is being tested.
   */
  Expression _expression;

  /**
   * The is operator.
   */
  Token isOperator;

  /**
   * The not operator, or `null` if the sense of the test is not negated.
   */
  Token notOperator;

  /**
   * The name of the type being tested for.
   */
  TypeName _type;

  /**
   * Initialize a newly created is expression.
   *
   * @param expression the expression used to compute the value whose type is being tested
   * @param isOperator the is operator
   * @param notOperator the not operator, or `null` if the sense of the test is not negated
   * @param type the name of the type being tested for
   */
  IsExpression(Expression expression, this.isOperator, this.notOperator, TypeName type) {
    this._expression = becomeParentOf(expression);
    this._type = becomeParentOf(type);
  }

  accept(AstVisitor visitor) => visitor.visitIsExpression(this);

  Token get beginToken => _expression.beginToken;

  Token get endToken => _type.endToken;

  /**
   * Return the expression used to compute the value whose type is being tested.
   *
   * @return the expression used to compute the value whose type is being tested
   */
  Expression get expression => _expression;

  int get precedence => 7;

  /**
   * Return the name of the type being tested for.
   *
   * @return the name of the type being tested for
   */
  TypeName get type => _type;

  /**
   * Set the expression used to compute the value whose type is being tested to the given
   * expression.
   *
   * @param expression the expression used to compute the value whose type is being tested
   */
  void set expression(Expression expression) {
    this._expression = becomeParentOf(expression);
  }

  /**
   * Set the name of the type being tested for to the given name.
   *
   * @param name the name of the type being tested for
   */
  void set type(TypeName name) {
    this._type = becomeParentOf(name);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_expression, visitor);
    safelyVisitChild(_type, visitor);
  }
}

/**
 * Instances of the class `Label` represent a label.
 *
 * <pre>
 * label ::=
 *     [SimpleIdentifier] ':'
 * </pre>
 */
class Label extends AstNode {
  /**
   * The label being associated with the statement.
   */
  SimpleIdentifier _label;

  /**
   * The colon that separates the label from the statement.
   */
  Token colon;

  /**
   * Initialize a newly created label.
   *
   * @param label the label being applied
   * @param colon the colon that separates the label from whatever follows
   */
  Label(SimpleIdentifier label, this.colon) {
    this._label = becomeParentOf(label);
  }

  accept(AstVisitor visitor) => visitor.visitLabel(this);

  Token get beginToken => _label.beginToken;

  Token get endToken => colon;

  /**
   * Return the label being associated with the statement.
   *
   * @return the label being associated with the statement
   */
  SimpleIdentifier get label => _label;

  /**
   * Set the label being associated with the statement to the given label.
   *
   * @param label the label being associated with the statement
   */
  void set label(SimpleIdentifier label) {
    this._label = becomeParentOf(label);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_label, visitor);
  }
}

/**
 * Instances of the class `LabeledStatement` represent a statement that has a label associated
 * with them.
 *
 * <pre>
 * labeledStatement ::=
 *    [Label]+ [Statement]
 * </pre>
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
   *
   * @param labels the labels being associated with the statement
   * @param statement the statement with which the labels are being associated
   */
  LabeledStatement(List<Label> labels, Statement statement) {
    this._labels = new NodeList<Label>(this);
    this._labels.addAll(labels);
    this._statement = becomeParentOf(statement);
  }

  accept(AstVisitor visitor) => visitor.visitLabeledStatement(this);

  Token get beginToken {
    if (!_labels.isEmpty) {
      return _labels.beginToken;
    }
    return _statement.beginToken;
  }

  Token get endToken => _statement.endToken;

  /**
   * Return the labels being associated with the statement.
   *
   * @return the labels being associated with the statement
   */
  NodeList<Label> get labels => _labels;

  /**
   * Return the statement with which the labels are being associated.
   *
   * @return the statement with which the labels are being associated
   */
  Statement get statement => _statement;

  /**
   * Set the statement with which the labels are being associated to the given statement.
   *
   * @param statement the statement with which the labels are being associated
   */
  void set statement(Statement statement) {
    this._statement = becomeParentOf(statement);
  }

  void visitChildren(AstVisitor visitor) {
    _labels.accept(visitor);
    safelyVisitChild(_statement, visitor);
  }
}

/**
 * Instances of the class `LibraryDirective` represent a library directive.
 *
 * <pre>
 * libraryDirective ::=
 *     [Annotation] 'library' [Identifier] ';'
 * </pre>
 */
class LibraryDirective extends Directive {
  /**
   * The token representing the 'library' token.
   */
  Token libraryToken;

  /**
   * The name of the library being defined.
   */
  LibraryIdentifier _name;

  /**
   * The semicolon terminating the directive.
   */
  Token semicolon;

  /**
   * Initialize a newly created library directive.
   *
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   * @param libraryToken the token representing the 'library' token
   * @param name the name of the library being defined
   * @param semicolon the semicolon terminating the directive
   */
  LibraryDirective(Comment comment, List<Annotation> metadata, this.libraryToken, LibraryIdentifier name, this.semicolon) : super(comment, metadata) {
    this._name = becomeParentOf(name);
  }

  accept(AstVisitor visitor) => visitor.visitLibraryDirective(this);

  Token get endToken => semicolon;

  Token get keyword => libraryToken;

  /**
   * Return the name of the library being defined.
   *
   * @return the name of the library being defined
   */
  LibraryIdentifier get name => _name;

  /**
   * Set the name of the library being defined to the given name.
   *
   * @param name the name of the library being defined
   */
  void set name(LibraryIdentifier name) {
    this._name = becomeParentOf(name);
  }

  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_name, visitor);
  }

  Token get firstTokenAfterCommentAndMetadata => libraryToken;
}

/**
 * Instances of the class `LibraryIdentifier` represent the identifier for a library.
 *
 * <pre>
 * libraryIdentifier ::=
 *     [SimpleIdentifier] ('.' [SimpleIdentifier])*
 * </pre>
 */
class LibraryIdentifier extends Identifier {
  /**
   * The components of the identifier.
   */
  NodeList<SimpleIdentifier> _components;

  /**
   * Initialize a newly created prefixed identifier.
   *
   * @param components the components of the identifier
   */
  LibraryIdentifier(List<SimpleIdentifier> components) {
    this._components = new NodeList<SimpleIdentifier>(this);
    this._components.addAll(components);
  }

  accept(AstVisitor visitor) => visitor.visitLibraryIdentifier(this);

  Token get beginToken => _components.beginToken;

  Element get bestElement => staticElement;

  /**
   * Return the components of the identifier.
   *
   * @return the components of the identifier
   */
  NodeList<SimpleIdentifier> get components => _components;

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

  int get precedence => 15;

  Element get propagatedElement => null;

  Element get staticElement => null;

  void visitChildren(AstVisitor visitor) {
    _components.accept(visitor);
  }
}

/**
 * Instances of the class `ListLiteral` represent a list literal.
 *
 * <pre>
 * listLiteral ::=
 *     'const'? ('<' [TypeName] '>')? '[' ([Expression] ','?)? ']'
 * </pre>
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
   *
   * @param constKeyword the token representing the 'const' keyword
   * @param typeArguments the type argument associated with this literal, or `null` if no type
   *          arguments were declared
   * @param leftBracket the left square bracket
   * @param elements the expressions used to compute the elements of the list
   * @param rightBracket the right square bracket
   */
  ListLiteral(Token constKeyword, TypeArgumentList typeArguments, Token leftBracket, List<Expression> elements, Token rightBracket) : super(constKeyword, typeArguments) {
    this._elements = new NodeList<Expression>(this);
    this._leftBracket = leftBracket;
    this._elements.addAll(elements);
    this._rightBracket = rightBracket;
  }

  accept(AstVisitor visitor) => visitor.visitListLiteral(this);

  Token get beginToken {
    Token token = constKeyword;
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
   *
   * @return the expressions used to compute the elements of the list
   */
  NodeList<Expression> get elements => _elements;

  Token get endToken => _rightBracket;

  /**
   * Return the left square bracket.
   *
   * @return the left square bracket
   */
  Token get leftBracket => _leftBracket;

  /**
   * Return the right square bracket.
   *
   * @return the right square bracket
   */
  Token get rightBracket => _rightBracket;

  /**
   * Set the left square bracket to the given token.
   *
   * @param bracket the left square bracket
   */
  void set leftBracket(Token bracket) {
    _leftBracket = bracket;
  }

  /**
   * Set the right square bracket to the given token.
   *
   * @param bracket the right square bracket
   */
  void set rightBracket(Token bracket) {
    _rightBracket = bracket;
  }

  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _elements.accept(visitor);
  }
}

/**
 * The abstract class `Literal` defines the behavior common to nodes that represent a literal
 * expression.
 *
 * <pre>
 * literal ::=
 *     [BooleanLiteral]
 *   | [DoubleLiteral]
 *   | [IntegerLiteral]
 *   | [ListLiteral]
 *   | [MapLiteral]
 *   | [NullLiteral]
 *   | [StringLiteral]
 * </pre>
 */
abstract class Literal extends Expression {
  int get precedence => 16;
}

/**
 * Instances of the class `MapLiteral` represent a literal map.
 *
 * <pre>
 * mapLiteral ::=
 *     'const'? ('<' [TypeName] (',' [TypeName])* '>')? '{' ([MapLiteralEntry] (',' [MapLiteralEntry])* ','?)? '}'
 * </pre>
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
   *
   * @param constKeyword the token representing the 'const' keyword
   * @param typeArguments the type argument associated with this literal, or `null` if no type
   *          arguments were declared
   * @param leftBracket the left curly bracket
   * @param entries the entries in the map
   * @param rightBracket the right curly bracket
   */
  MapLiteral(Token constKeyword, TypeArgumentList typeArguments, Token leftBracket, List<MapLiteralEntry> entries, Token rightBracket) : super(constKeyword, typeArguments) {
    this._entries = new NodeList<MapLiteralEntry>(this);
    this._leftBracket = leftBracket;
    this._entries.addAll(entries);
    this._rightBracket = rightBracket;
  }

  accept(AstVisitor visitor) => visitor.visitMapLiteral(this);

  Token get beginToken {
    Token token = constKeyword;
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
   *
   * @return the entries in the map
   */
  NodeList<MapLiteralEntry> get entries => _entries;

  /**
   * Return the left curly bracket.
   *
   * @return the left curly bracket
   */
  Token get leftBracket => _leftBracket;

  /**
   * Return the right curly bracket.
   *
   * @return the right curly bracket
   */
  Token get rightBracket => _rightBracket;

  /**
   * Set the left curly bracket to the given token.
   *
   * @param bracket the left curly bracket
   */
  void set leftBracket(Token bracket) {
    _leftBracket = bracket;
  }

  /**
   * Set the right curly bracket to the given token.
   *
   * @param bracket the right curly bracket
   */
  void set rightBracket(Token bracket) {
    _rightBracket = bracket;
  }

  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _entries.accept(visitor);
  }
}

/**
 * Instances of the class `MapLiteralEntry` represent a single key/value pair in a map
 * literal.
 *
 * <pre>
 * mapLiteralEntry ::=
 *     [Expression] ':' [Expression]
 * </pre>
 */
class MapLiteralEntry extends AstNode {
  /**
   * The expression computing the key with which the value will be associated.
   */
  Expression _key;

  /**
   * The colon that separates the key from the value.
   */
  Token separator;

  /**
   * The expression computing the value that will be associated with the key.
   */
  Expression _value;

  /**
   * Initialize a newly created map literal entry.
   *
   * @param key the expression computing the key with which the value will be associated
   * @param separator the colon that separates the key from the value
   * @param value the expression computing the value that will be associated with the key
   */
  MapLiteralEntry(Expression key, this.separator, Expression value) {
    this._key = becomeParentOf(key);
    this._value = becomeParentOf(value);
  }

  accept(AstVisitor visitor) => visitor.visitMapLiteralEntry(this);

  Token get beginToken => _key.beginToken;

  Token get endToken => _value.endToken;

  /**
   * Return the expression computing the key with which the value will be associated.
   *
   * @return the expression computing the key with which the value will be associated
   */
  Expression get key => _key;

  /**
   * Return the expression computing the value that will be associated with the key.
   *
   * @return the expression computing the value that will be associated with the key
   */
  Expression get value => _value;

  /**
   * Set the expression computing the key with which the value will be associated to the given
   * string.
   *
   * @param string the expression computing the key with which the value will be associated
   */
  void set key(Expression string) {
    _key = becomeParentOf(string);
  }

  /**
   * Set the expression computing the value that will be associated with the key to the given
   * expression.
   *
   * @param expression the expression computing the value that will be associated with the key
   */
  void set value(Expression expression) {
    _value = becomeParentOf(expression);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_key, visitor);
    safelyVisitChild(_value, visitor);
  }
}

/**
 * Instances of the class `MethodDeclaration` represent a method declaration.
 *
 * <pre>
 * methodDeclaration ::=
 *     methodSignature [FunctionBody]
 *
 * methodSignature ::=
 *     'external'? ('abstract' | 'static')? [Type]? ('get' | 'set')? methodName
 *     [FormalParameterList]
 *
 * methodName ::=
 *     [SimpleIdentifier]
 *   | 'operator' [SimpleIdentifier]
 * </pre>
 */
class MethodDeclaration extends ClassMember {
  /**
   * The token for the 'external' keyword, or `null` if the constructor is not external.
   */
  Token externalKeyword;

  /**
   * The token representing the 'abstract' or 'static' keyword, or `null` if neither modifier
   * was specified.
   */
  Token modifierKeyword;

  /**
   * The return type of the method, or `null` if no return type was declared.
   */
  TypeName _returnType;

  /**
   * The token representing the 'get' or 'set' keyword, or `null` if this is a method
   * declaration rather than a property declaration.
   */
  Token propertyKeyword;

  /**
   * The token representing the 'operator' keyword, or `null` if this method does not declare
   * an operator.
   */
  Token operatorKeyword;

  /**
   * The name of the method.
   */
  SimpleIdentifier _name;

  /**
   * The parameters associated with the method, or `null` if this method declares a getter.
   */
  FormalParameterList _parameters;

  /**
   * The body of the method.
   */
  FunctionBody _body;

  /**
   * Initialize a newly created method declaration.
   *
   * @param externalKeyword the token for the 'external' keyword
   * @param comment the documentation comment associated with this method
   * @param metadata the annotations associated with this method
   * @param modifierKeyword the token representing the 'abstract' or 'static' keyword
   * @param returnType the return type of the method
   * @param propertyKeyword the token representing the 'get' or 'set' keyword
   * @param operatorKeyword the token representing the 'operator' keyword
   * @param name the name of the method
   * @param parameters the parameters associated with the method, or `null` if this method
   *          declares a getter
   * @param body the body of the method
   */
  MethodDeclaration(Comment comment, List<Annotation> metadata, this.externalKeyword, this.modifierKeyword, TypeName returnType, this.propertyKeyword, this.operatorKeyword, SimpleIdentifier name, FormalParameterList parameters, FunctionBody body) : super(comment, metadata) {
    this._returnType = becomeParentOf(returnType);
    this._name = becomeParentOf(name);
    this._parameters = becomeParentOf(parameters);
    this._body = becomeParentOf(body);
  }

  accept(AstVisitor visitor) => visitor.visitMethodDeclaration(this);

  /**
   * Return the body of the method.
   *
   * @return the body of the method
   */
  FunctionBody get body => _body;

  /**
   * Return the element associated with this method, or `null` if the AST structure has not
   * been resolved. The element can either be a [MethodElement], if this represents the
   * declaration of a normal method, or a [PropertyAccessorElement] if this represents the
   * declaration of either a getter or a setter.
   *
   * @return the element associated with this method
   */
  ExecutableElement get element => _name != null ? (_name.staticElement as ExecutableElement) : null;

  Token get endToken => _body.endToken;

  /**
   * Return the name of the method.
   *
   * @return the name of the method
   */
  SimpleIdentifier get name => _name;

  /**
   * Return the parameters associated with the method, or `null` if this method declares a
   * getter.
   *
   * @return the parameters associated with the method
   */
  FormalParameterList get parameters => _parameters;

  /**
   * Return the return type of the method, or `null` if no return type was declared.
   *
   * @return the return type of the method
   */
  TypeName get returnType => _returnType;

  /**
   * Return `true` if this method is declared to be an abstract method.
   *
   * @return `true` if this method is declared to be an abstract method
   */
  bool get isAbstract => externalKeyword == null && (_body is EmptyFunctionBody);

  /**
   * Return `true` if this method declares a getter.
   *
   * @return `true` if this method declares a getter
   */
  bool get isGetter => propertyKeyword != null && identical((propertyKeyword as KeywordToken).keyword, Keyword.GET);

  /**
   * Return `true` if this method declares an operator.
   *
   * @return `true` if this method declares an operator
   */
  bool get isOperator => operatorKeyword != null;

  /**
   * Return `true` if this method declares a setter.
   *
   * @return `true` if this method declares a setter
   */
  bool get isSetter => propertyKeyword != null && identical((propertyKeyword as KeywordToken).keyword, Keyword.SET);

  /**
   * Return `true` if this method is declared to be a static method.
   *
   * @return `true` if this method is declared to be a static method
   */
  bool get isStatic => modifierKeyword != null && identical((modifierKeyword as KeywordToken).keyword, Keyword.STATIC);

  /**
   * Set the body of the method to the given function body.
   *
   * @param functionBody the body of the method
   */
  void set body(FunctionBody functionBody) {
    _body = becomeParentOf(functionBody);
  }

  /**
   * Set the name of the method to the given identifier.
   *
   * @param identifier the name of the method
   */
  void set name(SimpleIdentifier identifier) {
    _name = becomeParentOf(identifier);
  }

  /**
   * Set the parameters associated with the method to the given list of parameters.
   *
   * @param parameters the parameters associated with the method
   */
  void set parameters(FormalParameterList parameters) {
    this._parameters = becomeParentOf(parameters);
  }

  /**
   * Set the return type of the method to the given type name.
   *
   * @param typeName the return type of the method
   */
  void set returnType(TypeName typeName) {
    _returnType = becomeParentOf(typeName);
  }

  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_returnType, visitor);
    safelyVisitChild(_name, visitor);
    safelyVisitChild(_parameters, visitor);
    safelyVisitChild(_body, visitor);
  }

  Token get firstTokenAfterCommentAndMetadata {
    if (modifierKeyword != null) {
      return modifierKeyword;
    } else if (_returnType != null) {
      return _returnType.beginToken;
    } else if (propertyKeyword != null) {
      return propertyKeyword;
    } else if (operatorKeyword != null) {
      return operatorKeyword;
    }
    return _name.beginToken;
  }
}

/**
 * Instances of the class `MethodInvocation` represent the invocation of either a function or
 * a method. Invocations of functions resulting from evaluating an expression are represented by
 * [FunctionExpressionInvocation] nodes. Invocations of getters
 * and setters are represented by either [PrefixedIdentifier] or
 * [PropertyAccess] nodes.
 *
 * <pre>
 * methodInvoction ::=
 *     ([Expression] '.')? [SimpleIdentifier] [ArgumentList]
 * </pre>
 */
class MethodInvocation extends Expression {
  /**
   * The expression producing the object on which the method is defined, or `null` if there is
   * no target (that is, the target is implicitly `this`).
   */
  Expression _target;

  /**
   * The period that separates the target from the method name, or `null` if there is no
   * target.
   */
  Token period;

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
   *
   * @param target the expression producing the object on which the method is defined
   * @param period the period that separates the target from the method name
   * @param methodName the name of the method being invoked
   * @param argumentList the list of arguments to the method
   */
  MethodInvocation(Expression target, this.period, SimpleIdentifier methodName, ArgumentList argumentList) {
    this._target = becomeParentOf(target);
    this._methodName = becomeParentOf(methodName);
    this._argumentList = becomeParentOf(argumentList);
  }

  accept(AstVisitor visitor) => visitor.visitMethodInvocation(this);

  /**
   * Return the list of arguments to the method.
   *
   * @return the list of arguments to the method
   */
  ArgumentList get argumentList => _argumentList;

  Token get beginToken {
    if (_target != null) {
      return _target.beginToken;
    } else if (period != null) {
      return period;
    }
    return _methodName.beginToken;
  }

  Token get endToken => _argumentList.endToken;

  /**
   * Return the name of the method being invoked.
   *
   * @return the name of the method being invoked
   */
  SimpleIdentifier get methodName => _methodName;

  int get precedence => 15;

  /**
   * Return the expression used to compute the receiver of the invocation. If this invocation is not
   * part of a cascade expression, then this is the same as [getTarget]. If this invocation
   * is part of a cascade expression, then the target stored with the cascade expression is
   * returned.
   *
   * @return the expression used to compute the receiver of the invocation
   * @see #getTarget()
   */
  Expression get realTarget {
    if (isCascaded) {
      AstNode ancestor = parent;
      while (ancestor is! CascadeExpression) {
        if (ancestor == null) {
          return _target;
        }
        ancestor = ancestor.parent;
      }
      return (ancestor as CascadeExpression).target;
    }
    return _target;
  }

  /**
   * Return the expression producing the object on which the method is defined, or `null` if
   * there is no target (that is, the target is implicitly `this`) or if this method
   * invocation is part of a cascade expression.
   *
   * @return the expression producing the object on which the method is defined
   * @see #getRealTarget()
   */
  Expression get target => _target;

  /**
   * Return `true` if this expression is cascaded. If it is, then the target of this
   * expression is not stored locally but is stored in the nearest ancestor that is a
   * [CascadeExpression].
   *
   * @return `true` if this expression is cascaded
   */
  bool get isCascaded => period != null && identical(period.type, TokenType.PERIOD_PERIOD);

  /**
   * Set the list of arguments to the method to the given list.
   *
   * @param argumentList the list of arguments to the method
   */
  void set argumentList(ArgumentList argumentList) {
    this._argumentList = becomeParentOf(argumentList);
  }

  /**
   * Set the name of the method being invoked to the given identifier.
   *
   * @param identifier the name of the method being invoked
   */
  void set methodName(SimpleIdentifier identifier) {
    _methodName = becomeParentOf(identifier);
  }

  /**
   * Set the expression producing the object on which the method is defined to the given expression.
   *
   * @param expression the expression producing the object on which the method is defined
   */
  void set target(Expression expression) {
    _target = becomeParentOf(expression);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_target, visitor);
    safelyVisitChild(_methodName, visitor);
    safelyVisitChild(_argumentList, visitor);
  }
}

/**
 * Instances of the class `NamedExpression` represent an expression that has a name associated
 * with it. They are used in method invocations when there are named parameters.
 *
 * <pre>
 * namedExpression ::=
 *     [Label] [Expression]
 * </pre>
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
   *
   * @param name the name associated with the expression
   * @param expression the expression with which the name is associated
   */
  NamedExpression(Label name, Expression expression) {
    this._name = becomeParentOf(name);
    this._expression = becomeParentOf(expression);
  }

  accept(AstVisitor visitor) => visitor.visitNamedExpression(this);

  Token get beginToken => _name.beginToken;

  /**
   * Return the element representing the parameter being named by this expression, or `null`
   * if the AST structure has not been resolved or if there is no parameter with the same name as
   * this expression.
   *
   * @return the element representing the parameter being named by this expression
   */
  ParameterElement get element {
    Element element = _name.label.staticElement;
    if (element is ParameterElement) {
      return element;
    }
    return null;
  }

  Token get endToken => _expression.endToken;

  /**
   * Return the expression with which the name is associated.
   *
   * @return the expression with which the name is associated
   */
  Expression get expression => _expression;

  /**
   * Return the name associated with the expression.
   *
   * @return the name associated with the expression
   */
  Label get name => _name;

  int get precedence => 0;

  /**
   * Set the expression with which the name is associated to the given expression.
   *
   * @param expression the expression with which the name is associated
   */
  void set expression(Expression expression) {
    this._expression = becomeParentOf(expression);
  }

  /**
   * Set the name associated with the expression to the given identifier.
   *
   * @param identifier the name associated with the expression
   */
  void set name(Label identifier) {
    _name = becomeParentOf(identifier);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_name, visitor);
    safelyVisitChild(_expression, visitor);
  }
}

/**
 * The abstract class `NamespaceDirective` defines the behavior common to nodes that represent
 * a directive that impacts the namespace of a library.
 *
 * <pre>
 * directive ::=
 *     [ExportDirective]
 *   | [ImportDirective]
 * </pre>
 */
abstract class NamespaceDirective extends UriBasedDirective {
  /**
   * The token representing the 'import' or 'export' keyword.
   */
  Token keyword;

  /**
   * The combinators used to control which names are imported or exported.
   */
  NodeList<Combinator> _combinators;

  /**
   * The semicolon terminating the directive.
   */
  Token semicolon;

  /**
   * Initialize a newly created namespace directive.
   *
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   * @param keyword the token representing the 'import' or 'export' keyword
   * @param libraryUri the URI of the library being imported or exported
   * @param combinators the combinators used to control which names are imported or exported
   * @param semicolon the semicolon terminating the directive
   */
  NamespaceDirective(Comment comment, List<Annotation> metadata, this.keyword, StringLiteral libraryUri, List<Combinator> combinators, this.semicolon) : super(comment, metadata, libraryUri) {
    this._combinators = new NodeList<Combinator>(this);
    this._combinators.addAll(combinators);
  }

  /**
   * Return the combinators used to control how names are imported or exported.
   *
   * @return the combinators used to control how names are imported or exported
   */
  NodeList<Combinator> get combinators => _combinators;

  Token get endToken => semicolon;

  LibraryElement get uriElement;

  Token get firstTokenAfterCommentAndMetadata => keyword;
}

/**
 * Instances of the class `NativeClause` represent the "native" clause in an class
 * declaration.
 *
 * <pre>
 * nativeClause ::=
 *     'native' [StringLiteral]
 * </pre>
 */
class NativeClause extends AstNode {
  /**
   * The token representing the 'native' keyword.
   */
  Token keyword;

  /**
   * The name of the native object that implements the class.
   */
  StringLiteral name;

  /**
   * Initialize a newly created native clause.
   *
   * @param keyword the token representing the 'native' keyword
   * @param name the name of the native object that implements the class.
   */
  NativeClause(this.keyword, this.name);

  accept(AstVisitor visitor) => visitor.visitNativeClause(this);

  Token get beginToken => keyword;

  Token get endToken => name.endToken;

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(name, visitor);
  }
}

/**
 * Instances of the class `NativeFunctionBody` represent a function body that consists of a
 * native keyword followed by a string literal.
 *
 * <pre>
 * nativeFunctionBody ::=
 *     'native' [SimpleStringLiteral] ';'
 * </pre>
 */
class NativeFunctionBody extends FunctionBody {
  /**
   * The token representing 'native' that marks the start of the function body.
   */
  final Token nativeToken;

  /**
   * The string literal, after the 'native' token.
   */
  StringLiteral _stringLiteral;

  /**
   * The token representing the semicolon that marks the end of the function body.
   */
  final Token semicolon;

  /**
   * Initialize a newly created function body consisting of the 'native' token, a string literal,
   * and a semicolon.
   *
   * @param nativeToken the token representing 'native' that marks the start of the function body
   * @param stringLiteral the string literal
   * @param semicolon the token representing the semicolon that marks the end of the function body
   */
  NativeFunctionBody(this.nativeToken, StringLiteral stringLiteral, this.semicolon) {
    this._stringLiteral = becomeParentOf(stringLiteral);
  }

  accept(AstVisitor visitor) => visitor.visitNativeFunctionBody(this);

  Token get beginToken => nativeToken;

  Token get endToken => semicolon;

  /**
   * Return the string literal representing the string after the 'native' token.
   *
   * @return the string literal representing the string after the 'native' token
   */
  StringLiteral get stringLiteral => _stringLiteral;

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_stringLiteral, visitor);
  }
}

/**
 * The abstract class `NormalFormalParameter` defines the behavior common to formal parameters
 * that are required (are not optional).
 *
 * <pre>
 * normalFormalParameter ::=
 *     [FunctionTypedFormalParameter]
 *   | [FieldFormalParameter]
 *   | [SimpleFormalParameter]
 * </pre>
 */
abstract class NormalFormalParameter extends FormalParameter {
  /**
   * The documentation comment associated with this parameter, or `null` if this parameter
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
   *
   * @param comment the documentation comment associated with this parameter
   * @param metadata the annotations associated with this parameter
   * @param identifier the name of the parameter being declared
   */
  NormalFormalParameter(Comment comment, List<Annotation> metadata, SimpleIdentifier identifier) {
    this._metadata = new NodeList<Annotation>(this);
    this._comment = becomeParentOf(comment);
    this._metadata.addAll(metadata);
    this._identifier = becomeParentOf(identifier);
  }

  /**
   * Return the documentation comment associated with this parameter, or `null` if this
   * parameter does not have a documentation comment associated with it.
   *
   * @return the documentation comment associated with this parameter
   */
  Comment get documentationComment => _comment;

  SimpleIdentifier get identifier => _identifier;

  ParameterKind get kind {
    AstNode parent = this.parent;
    if (parent is DefaultFormalParameter) {
      return parent.kind;
    }
    return ParameterKind.REQUIRED;
  }

  /**
   * Return the annotations associated with this parameter.
   *
   * @return the annotations associated with this parameter
   */
  NodeList<Annotation> get metadata => _metadata;

  /**
   * Set the documentation comment associated with this parameter to the given comment
   *
   * @param comment the documentation comment to be associated with this parameter
   */
  void set documentationComment(Comment comment) {
    this._comment = becomeParentOf(comment);
  }

  /**
   * Set the name of the parameter being declared to the given identifier.
   *
   * @param identifier the name of the parameter being declared
   */
  void set identifier(SimpleIdentifier identifier) {
    this._identifier = becomeParentOf(identifier);
  }

  void visitChildren(AstVisitor visitor) {
    //
    // Note that subclasses are responsible for visiting the identifier because they often need to
    // visit other nodes before visiting the identifier.
    //
    if (commentIsBeforeAnnotations()) {
      safelyVisitChild(_comment, visitor);
      _metadata.accept(visitor);
    } else {
      for (AstNode child in sortedCommentAndAnnotations) {
        child.accept(visitor);
      }
    }
  }

  /**
   * Return `true` if the comment is lexically before any annotations.
   *
   * @return `true` if the comment is lexically before any annotations
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
   *
   * @return the comment and annotations associated with this parameter in the order in which they
   *         appeared in the original source
   */
  List<AstNode> get sortedCommentAndAnnotations {
    List<AstNode> childList = new List<AstNode>();
    childList.add(_comment);
    childList.addAll(_metadata);
    List<AstNode> children = new List.from(childList);
    children.sort(AstNode.LEXICAL_ORDER);
    return children;
  }
}

/**
 * Instances of the class `NullLiteral` represent a null literal expression.
 *
 * <pre>
 * nullLiteral ::=
 *     'null'
 * </pre>
 */
class NullLiteral extends Literal {
  /**
   * The token representing the literal.
   */
  Token literal;

  /**
   * Initialize a newly created null literal.
   *
   * @param token the token representing the literal
   */
  NullLiteral(Token token) {
    this.literal = token;
  }

  accept(AstVisitor visitor) => visitor.visitNullLiteral(this);

  Token get beginToken => literal;

  Token get endToken => literal;

  void visitChildren(AstVisitor visitor) {
  }
}

/**
 * Instances of the class `ParenthesizedExpression` represent a parenthesized expression.
 *
 * <pre>
 * parenthesizedExpression ::=
 *     '(' [Expression] ')'
 * </pre>
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
   *
   * @param leftParenthesis the left parenthesis
   * @param expression the expression within the parentheses
   * @param rightParenthesis the right parenthesis
   */
  ParenthesizedExpression(Token leftParenthesis, Expression expression, Token rightParenthesis) {
    this._leftParenthesis = leftParenthesis;
    this._expression = becomeParentOf(expression);
    this._rightParenthesis = rightParenthesis;
  }

  accept(AstVisitor visitor) => visitor.visitParenthesizedExpression(this);

  Token get beginToken => _leftParenthesis;

  Token get endToken => _rightParenthesis;

  /**
   * Return the expression within the parentheses.
   *
   * @return the expression within the parentheses
   */
  Expression get expression => _expression;

  /**
   * Return the left parenthesis.
   *
   * @return the left parenthesis
   */
  Token get leftParenthesis => _leftParenthesis;

  int get precedence => 15;

  /**
   * Return the right parenthesis.
   *
   * @return the right parenthesis
   */
  Token get rightParenthesis => _rightParenthesis;

  /**
   * Set the expression within the parentheses to the given expression.
   *
   * @param expression the expression within the parentheses
   */
  void set expression(Expression expression) {
    this._expression = becomeParentOf(expression);
  }

  /**
   * Set the left parenthesis to the given token.
   *
   * @param parenthesis the left parenthesis
   */
  void set leftParenthesis(Token parenthesis) {
    _leftParenthesis = parenthesis;
  }

  /**
   * Set the right parenthesis to the given token.
   *
   * @param parenthesis the right parenthesis
   */
  void set rightParenthesis(Token parenthesis) {
    _rightParenthesis = parenthesis;
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_expression, visitor);
  }
}

/**
 * Instances of the class `PartDirective` represent a part directive.
 *
 * <pre>
 * partDirective ::=
 *     [Annotation] 'part' [StringLiteral] ';'
 * </pre>
 */
class PartDirective extends UriBasedDirective {
  /**
   * The token representing the 'part' token.
   */
  Token partToken;

  /**
   * The semicolon terminating the directive.
   */
  Token semicolon;

  /**
   * Initialize a newly created part directive.
   *
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   * @param partToken the token representing the 'part' token
   * @param partUri the URI of the part being included
   * @param semicolon the semicolon terminating the directive
   */
  PartDirective(Comment comment, List<Annotation> metadata, this.partToken, StringLiteral partUri, this.semicolon) : super(comment, metadata, partUri);

  accept(AstVisitor visitor) => visitor.visitPartDirective(this);

  Token get endToken => semicolon;

  Token get keyword => partToken;

  CompilationUnitElement get uriElement => element as CompilationUnitElement;

  Token get firstTokenAfterCommentAndMetadata => partToken;
}

/**
 * Instances of the class `PartOfDirective` represent a part-of directive.
 *
 * <pre>
 * partOfDirective ::=
 *     [Annotation] 'part' 'of' [Identifier] ';'
 * </pre>
 */
class PartOfDirective extends Directive {
  /**
   * The token representing the 'part' token.
   */
  Token partToken;

  /**
   * The token representing the 'of' token.
   */
  Token ofToken;

  /**
   * The name of the library that the containing compilation unit is part of.
   */
  LibraryIdentifier _libraryName;

  /**
   * The semicolon terminating the directive.
   */
  Token semicolon;

  /**
   * Initialize a newly created part-of directive.
   *
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   * @param partToken the token representing the 'part' token
   * @param ofToken the token representing the 'of' token
   * @param libraryName the name of the library that the containing compilation unit is part of
   * @param semicolon the semicolon terminating the directive
   */
  PartOfDirective(Comment comment, List<Annotation> metadata, this.partToken, this.ofToken, LibraryIdentifier libraryName, this.semicolon) : super(comment, metadata) {
    this._libraryName = becomeParentOf(libraryName);
  }

  accept(AstVisitor visitor) => visitor.visitPartOfDirective(this);

  Token get endToken => semicolon;

  Token get keyword => partToken;

  /**
   * Return the name of the library that the containing compilation unit is part of.
   *
   * @return the name of the library that the containing compilation unit is part of
   */
  LibraryIdentifier get libraryName => _libraryName;

  /**
   * Set the name of the library that the containing compilation unit is part of to the given name.
   *
   * @param libraryName the name of the library that the containing compilation unit is part of
   */
  void set libraryName(LibraryIdentifier libraryName) {
    this._libraryName = becomeParentOf(libraryName);
  }

  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_libraryName, visitor);
  }

  Token get firstTokenAfterCommentAndMetadata => partToken;
}

/**
 * Instances of the class `PostfixExpression` represent a postfix unary expression.
 *
 * <pre>
 * postfixExpression ::=
 *     [Expression] [Token]
 * </pre>
 */
class PostfixExpression extends Expression {
  /**
   * The expression computing the operand for the operator.
   */
  Expression _operand;

  /**
   * The postfix operator being applied to the operand.
   */
  Token operator;

  /**
   * The element associated with this the operator based on the propagated type of the operand, or
   * `null` if the AST structure has not been resolved, if the operator is not user definable,
   * or if the operator could not be resolved.
   */
  MethodElement _propagatedElement;

  /**
   * The element associated with the operator based on the static type of the operand, or
   * `null` if the AST structure has not been resolved, if the operator is not user definable,
   * or if the operator could not be resolved.
   */
  MethodElement _staticElement;

  /**
   * Initialize a newly created postfix expression.
   *
   * @param operand the expression computing the operand for the operator
   * @param operator the postfix operator being applied to the operand
   */
  PostfixExpression(Expression operand, this.operator) {
    this._operand = becomeParentOf(operand);
  }

  accept(AstVisitor visitor) => visitor.visitPostfixExpression(this);

  Token get beginToken => _operand.beginToken;

  /**
   * Return the best element available for this operator. If resolution was able to find a better
   * element based on type propagation, that element will be returned. Otherwise, the element found
   * using the result of static analysis will be returned. If resolution has not been performed,
   * then `null` will be returned.
   *
   * @return the best element available for this operator
   */
  MethodElement get bestElement {
    MethodElement element = propagatedElement;
    if (element == null) {
      element = staticElement;
    }
    return element;
  }

  Token get endToken => operator;

  /**
   * Return the expression computing the operand for the operator.
   *
   * @return the expression computing the operand for the operator
   */
  Expression get operand => _operand;

  int get precedence => 15;

  /**
   * Return the element associated with the operator based on the propagated type of the operand, or
   * `null` if the AST structure has not been resolved, if the operator is not user definable,
   * or if the operator could not be resolved. One example of the latter case is an operator that is
   * not defined for the type of the operand.
   *
   * @return the element associated with the operator
   */
  MethodElement get propagatedElement => _propagatedElement;

  /**
   * Return the element associated with the operator based on the static type of the operand, or
   * `null` if the AST structure has not been resolved, if the operator is not user definable,
   * or if the operator could not be resolved. One example of the latter case is an operator that is
   * not defined for the type of the operand.
   *
   * @return the element associated with the operator
   */
  MethodElement get staticElement => _staticElement;

  /**
   * Set the expression computing the operand for the operator to the given expression.
   *
   * @param expression the expression computing the operand for the operator
   */
  void set operand(Expression expression) {
    _operand = becomeParentOf(expression);
  }

  /**
   * Set the element associated with the operator based on the propagated type of the operand to the
   * given element.
   *
   * @param element the element to be associated with the operator
   */
  void set propagatedElement(MethodElement element) {
    _propagatedElement = element;
  }

  /**
   * Set the element associated with the operator based on the static type of the operand to the
   * given element.
   *
   * @param element the element to be associated with the operator
   */
  void set staticElement(MethodElement element) {
    _staticElement = element;
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_operand, visitor);
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is known based on
   * propagated type information, then return the parameter element representing the parameter to
   * which the value of the operand will be bound. Otherwise, return `null`.
   *
   * This method is only intended to be used by [Expression#getPropagatedParameterElement].
   *
   * @return the parameter element representing the parameter to which the value of the right
   *         operand will be bound
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
   * value of the operand will be bound. Otherwise, return `null`.
   *
   * This method is only intended to be used by [Expression#getStaticParameterElement].
   *
   * @return the parameter element representing the parameter to which the value of the right
   *         operand will be bound
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
 * Instances of the class `PrefixExpression` represent a prefix unary expression.
 *
 * <pre>
 * prefixExpression ::=
 *     [Token] [Expression]
 * </pre>
 */
class PrefixExpression extends Expression {
  /**
   * The prefix operator being applied to the operand.
   */
  Token operator;

  /**
   * The expression computing the operand for the operator.
   */
  Expression _operand;

  /**
   * The element associated with the operator based on the static type of the operand, or
   * `null` if the AST structure has not been resolved, if the operator is not user definable,
   * or if the operator could not be resolved.
   */
  MethodElement _staticElement;

  /**
   * The element associated with the operator based on the propagated type of the operand, or
   * `null` if the AST structure has not been resolved, if the operator is not user definable,
   * or if the operator could not be resolved.
   */
  MethodElement _propagatedElement;

  /**
   * Initialize a newly created prefix expression.
   *
   * @param operator the prefix operator being applied to the operand
   * @param operand the expression computing the operand for the operator
   */
  PrefixExpression(this.operator, Expression operand) {
    this._operand = becomeParentOf(operand);
  }

  accept(AstVisitor visitor) => visitor.visitPrefixExpression(this);

  Token get beginToken => operator;

  /**
   * Return the best element available for this operator. If resolution was able to find a better
   * element based on type propagation, that element will be returned. Otherwise, the element found
   * using the result of static analysis will be returned. If resolution has not been performed,
   * then `null` will be returned.
   *
   * @return the best element available for this operator
   */
  MethodElement get bestElement {
    MethodElement element = propagatedElement;
    if (element == null) {
      element = staticElement;
    }
    return element;
  }

  Token get endToken => _operand.endToken;

  /**
   * Return the expression computing the operand for the operator.
   *
   * @return the expression computing the operand for the operator
   */
  Expression get operand => _operand;

  int get precedence => 14;

  /**
   * Return the element associated with the operator based on the propagated type of the operand, or
   * `null` if the AST structure has not been resolved, if the operator is not user definable,
   * or if the operator could not be resolved. One example of the latter case is an operator that is
   * not defined for the type of the operand.
   *
   * @return the element associated with the operator
   */
  MethodElement get propagatedElement => _propagatedElement;

  /**
   * Return the element associated with the operator based on the static type of the operand, or
   * `null` if the AST structure has not been resolved, if the operator is not user definable,
   * or if the operator could not be resolved. One example of the latter case is an operator that is
   * not defined for the type of the operand.
   *
   * @return the element associated with the operator
   */
  MethodElement get staticElement => _staticElement;

  /**
   * Set the expression computing the operand for the operator to the given expression.
   *
   * @param expression the expression computing the operand for the operator
   */
  void set operand(Expression expression) {
    _operand = becomeParentOf(expression);
  }

  /**
   * Set the element associated with the operator based on the propagated type of the operand to the
   * given element.
   *
   * @param element the element to be associated with the operator
   */
  void set propagatedElement(MethodElement element) {
    _propagatedElement = element;
  }

  /**
   * Set the element associated with the operator based on the static type of the operand to the
   * given element.
   *
   * @param element the static element to be associated with the operator
   */
  void set staticElement(MethodElement element) {
    _staticElement = element;
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_operand, visitor);
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is known based on
   * propagated type information, then return the parameter element representing the parameter to
   * which the value of the operand will be bound. Otherwise, return `null`.
   *
   * This method is only intended to be used by [Expression#getPropagatedParameterElement].
   *
   * @return the parameter element representing the parameter to which the value of the right
   *         operand will be bound
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
   * value of the operand will be bound. Otherwise, return `null`.
   *
   * This method is only intended to be used by [Expression#getStaticParameterElement].
   *
   * @return the parameter element representing the parameter to which the value of the right
   *         operand will be bound
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
 * Instances of the class `PrefixedIdentifier` represent either an identifier that is prefixed
 * or an access to an object property where the target of the property access is a simple
 * identifier.
 *
 * <pre>
 * prefixedIdentifier ::=
 *     [SimpleIdentifier] '.' [SimpleIdentifier]
 * </pre>
 */
class PrefixedIdentifier extends Identifier {
  /**
   * The prefix associated with the library in which the identifier is defined.
   */
  SimpleIdentifier _prefix;

  /**
   * The period used to separate the prefix from the identifier.
   */
  Token period;

  /**
   * The identifier being prefixed.
   */
  SimpleIdentifier _identifier;

  /**
   * Initialize a newly created prefixed identifier.
   *
   * @param prefix the identifier being prefixed
   * @param period the period used to separate the prefix from the identifier
   * @param identifier the prefix associated with the library in which the identifier is defined
   */
  PrefixedIdentifier(SimpleIdentifier prefix, this.period, SimpleIdentifier identifier) {
    this._prefix = becomeParentOf(prefix);
    this._identifier = becomeParentOf(identifier);
  }

  accept(AstVisitor visitor) => visitor.visitPrefixedIdentifier(this);

  Token get beginToken => _prefix.beginToken;

  Element get bestElement {
    if (_identifier == null) {
      return null;
    }
    return _identifier.bestElement;
  }

  Token get endToken => _identifier.endToken;

  /**
   * Return the identifier being prefixed.
   *
   * @return the identifier being prefixed
   */
  SimpleIdentifier get identifier => _identifier;

  String get name => "${_prefix.name}.${_identifier.name}";

  int get precedence => 15;

  /**
   * Return the prefix associated with the library in which the identifier is defined.
   *
   * @return the prefix associated with the library in which the identifier is defined
   */
  SimpleIdentifier get prefix => _prefix;

  Element get propagatedElement {
    if (_identifier == null) {
      return null;
    }
    return _identifier.propagatedElement;
  }

  Element get staticElement {
    if (_identifier == null) {
      return null;
    }
    return _identifier.staticElement;
  }

  /**
   * Set the identifier being prefixed to the given identifier.
   *
   * @param identifier the identifier being prefixed
   */
  void set identifier(SimpleIdentifier identifier) {
    this._identifier = becomeParentOf(identifier);
  }

  /**
   * Set the prefix associated with the library in which the identifier is defined to the given
   * identifier.
   *
   * @param identifier the prefix associated with the library in which the identifier is defined
   */
  void set prefix(SimpleIdentifier identifier) {
    _prefix = becomeParentOf(identifier);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_prefix, visitor);
    safelyVisitChild(_identifier, visitor);
  }
}

/**
 * Instances of the class `PropertyAccess` represent the access of a property of an object.
 *
 * Note, however, that accesses to properties of objects can also be represented as
 * [PrefixedIdentifier] nodes in cases where the target is also a simple
 * identifier.
 *
 * <pre>
 * propertyAccess ::=
 *     [Expression] '.' [SimpleIdentifier]
 * </pre>
 */
class PropertyAccess extends Expression {
  /**
   * The expression computing the object defining the property being accessed.
   */
  Expression _target;

  /**
   * The property access operator.
   */
  Token operator;

  /**
   * The name of the property being accessed.
   */
  SimpleIdentifier _propertyName;

  /**
   * Initialize a newly created property access expression.
   *
   * @param target the expression computing the object defining the property being accessed
   * @param operator the property access operator
   * @param propertyName the name of the property being accessed
   */
  PropertyAccess(Expression target, this.operator, SimpleIdentifier propertyName) {
    this._target = becomeParentOf(target);
    this._propertyName = becomeParentOf(propertyName);
  }

  accept(AstVisitor visitor) => visitor.visitPropertyAccess(this);

  Token get beginToken {
    if (_target != null) {
      return _target.beginToken;
    }
    return operator;
  }

  Token get endToken => _propertyName.endToken;

  int get precedence => 15;

  /**
   * Return the name of the property being accessed.
   *
   * @return the name of the property being accessed
   */
  SimpleIdentifier get propertyName => _propertyName;

  /**
   * Return the expression used to compute the receiver of the invocation. If this invocation is not
   * part of a cascade expression, then this is the same as [getTarget]. If this invocation
   * is part of a cascade expression, then the target stored with the cascade expression is
   * returned.
   *
   * @return the expression used to compute the receiver of the invocation
   * @see #getTarget()
   */
  Expression get realTarget {
    if (isCascaded) {
      AstNode ancestor = parent;
      while (ancestor is! CascadeExpression) {
        if (ancestor == null) {
          return _target;
        }
        ancestor = ancestor.parent;
      }
      return (ancestor as CascadeExpression).target;
    }
    return _target;
  }

  /**
   * Return the expression computing the object defining the property being accessed, or
   * `null` if this property access is part of a cascade expression.
   *
   * @return the expression computing the object defining the property being accessed
   * @see #getRealTarget()
   */
  Expression get target => _target;

  bool get isAssignable => true;

  /**
   * Return `true` if this expression is cascaded. If it is, then the target of this
   * expression is not stored locally but is stored in the nearest ancestor that is a
   * [CascadeExpression].
   *
   * @return `true` if this expression is cascaded
   */
  bool get isCascaded => operator != null && identical(operator.type, TokenType.PERIOD_PERIOD);

  /**
   * Set the name of the property being accessed to the given identifier.
   *
   * @param identifier the name of the property being accessed
   */
  void set propertyName(SimpleIdentifier identifier) {
    _propertyName = becomeParentOf(identifier);
  }

  /**
   * Set the expression computing the object defining the property being accessed to the given
   * expression.
   *
   * @param expression the expression computing the object defining the property being accessed
   */
  void set target(Expression expression) {
    _target = becomeParentOf(expression);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_target, visitor);
    safelyVisitChild(_propertyName, visitor);
  }
}

/**
 * Instances of the class `RedirectingConstructorInvocation` represent the invocation of a
 * another constructor in the same class from within a constructor's initialization list.
 *
 * <pre>
 * redirectingConstructorInvocation ::=
 *     'this' ('.' identifier)? arguments
 * </pre>
 */
class RedirectingConstructorInvocation extends ConstructorInitializer {
  /**
   * The token for the 'this' keyword.
   */
  Token keyword;

  /**
   * The token for the period before the name of the constructor that is being invoked, or
   * `null` if the unnamed constructor is being invoked.
   */
  Token period;

  /**
   * The name of the constructor that is being invoked, or `null` if the unnamed constructor
   * is being invoked.
   */
  SimpleIdentifier _constructorName;

  /**
   * The list of arguments to the constructor.
   */
  ArgumentList _argumentList;

  /**
   * The element associated with the constructor based on static type information, or `null`
   * if the AST structure has not been resolved or if the constructor could not be resolved.
   */
  ConstructorElement staticElement;

  /**
   * Initialize a newly created redirecting invocation to invoke the constructor with the given name
   * with the given arguments.
   *
   * @param keyword the token for the 'this' keyword
   * @param period the token for the period before the name of the constructor that is being invoked
   * @param constructorName the name of the constructor that is being invoked
   * @param argumentList the list of arguments to the constructor
   */
  RedirectingConstructorInvocation(this.keyword, this.period, SimpleIdentifier constructorName, ArgumentList argumentList) {
    this._constructorName = becomeParentOf(constructorName);
    this._argumentList = becomeParentOf(argumentList);
  }

  accept(AstVisitor visitor) => visitor.visitRedirectingConstructorInvocation(this);

  /**
   * Return the list of arguments to the constructor.
   *
   * @return the list of arguments to the constructor
   */
  ArgumentList get argumentList => _argumentList;

  Token get beginToken => keyword;

  /**
   * Return the name of the constructor that is being invoked, or `null` if the unnamed
   * constructor is being invoked.
   *
   * @return the name of the constructor that is being invoked
   */
  SimpleIdentifier get constructorName => _constructorName;

  Token get endToken => _argumentList.endToken;

  /**
   * Set the list of arguments to the constructor to the given list.
   *
   * @param argumentList the list of arguments to the constructor
   */
  void set argumentList(ArgumentList argumentList) {
    this._argumentList = becomeParentOf(argumentList);
  }

  /**
   * Set the name of the constructor that is being invoked to the given identifier.
   *
   * @param identifier the name of the constructor that is being invoked
   */
  void set constructorName(SimpleIdentifier identifier) {
    _constructorName = becomeParentOf(identifier);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_constructorName, visitor);
    safelyVisitChild(_argumentList, visitor);
  }
}

/**
 * Instances of the class `RethrowExpression` represent a rethrow expression.
 *
 * <pre>
 * rethrowExpression ::=
 *     'rethrow'
 * </pre>
 */
class RethrowExpression extends Expression {
  /**
   * The token representing the 'rethrow' keyword.
   */
  Token keyword;

  /**
   * Initialize a newly created rethrow expression.
   *
   * @param keyword the token representing the 'rethrow' keyword
   */
  RethrowExpression(this.keyword);

  accept(AstVisitor visitor) => visitor.visitRethrowExpression(this);

  Token get beginToken => keyword;

  Token get endToken => keyword;

  int get precedence => 0;

  void visitChildren(AstVisitor visitor) {
  }
}

/**
 * Instances of the class `ReturnStatement` represent a return statement.
 *
 * <pre>
 * returnStatement ::=
 *     'return' [Expression]? ';'
 * </pre>
 */
class ReturnStatement extends Statement {
  /**
   * The token representing the 'return' keyword.
   */
  Token keyword;

  /**
   * The expression computing the value to be returned, or `null` if no explicit value was
   * provided.
   */
  Expression _expression;

  /**
   * The semicolon terminating the statement.
   */
  Token semicolon;

  /**
   * Initialize a newly created return statement.
   *
   * @param keyword the token representing the 'return' keyword
   * @param expression the expression computing the value to be returned
   * @param semicolon the semicolon terminating the statement
   */
  ReturnStatement(this.keyword, Expression expression, this.semicolon) {
    this._expression = becomeParentOf(expression);
  }

  accept(AstVisitor visitor) => visitor.visitReturnStatement(this);

  Token get beginToken => keyword;

  Token get endToken => semicolon;

  /**
   * Return the expression computing the value to be returned, or `null` if no explicit value
   * was provided.
   *
   * @return the expression computing the value to be returned
   */
  Expression get expression => _expression;

  /**
   * Set the expression computing the value to be returned to the given expression.
   *
   * @param expression the expression computing the value to be returned
   */
  void set expression(Expression expression) {
    this._expression = becomeParentOf(expression);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_expression, visitor);
  }
}

/**
 * Instances of the class `ScriptTag` represent the script tag that can optionally occur at
 * the beginning of a compilation unit.
 *
 * <pre>
 * scriptTag ::=
 *     '#!' (~NEWLINE)* NEWLINE
 * </pre>
 */
class ScriptTag extends AstNode {
  /**
   * The token representing this script tag.
   */
  Token scriptTag;

  /**
   * Initialize a newly created script tag.
   *
   * @param scriptTag the token representing this script tag
   */
  ScriptTag(this.scriptTag);

  accept(AstVisitor visitor) => visitor.visitScriptTag(this);

  Token get beginToken => scriptTag;

  Token get endToken => scriptTag;

  void visitChildren(AstVisitor visitor) {
  }
}

/**
 * Instances of the class `ShowCombinator` represent a combinator that restricts the names
 * being imported to those in a given list.
 *
 * <pre>
 * showCombinator ::=
 *     'show' [SimpleIdentifier] (',' [SimpleIdentifier])*
 * </pre>
 */
class ShowCombinator extends Combinator {
  /**
   * The list of names from the library that are made visible by this combinator.
   */
  NodeList<SimpleIdentifier> _shownNames;

  /**
   * Initialize a newly created import show combinator.
   *
   * @param keyword the comma introducing the combinator
   * @param shownNames the list of names from the library that are made visible by this combinator
   */
  ShowCombinator(Token keyword, List<SimpleIdentifier> shownNames) : super(keyword) {
    this._shownNames = new NodeList<SimpleIdentifier>(this);
    this._shownNames.addAll(shownNames);
  }

  accept(AstVisitor visitor) => visitor.visitShowCombinator(this);

  Token get endToken => _shownNames.endToken;

  /**
   * Return the list of names from the library that are made visible by this combinator.
   *
   * @return the list of names from the library that are made visible by this combinator
   */
  NodeList<SimpleIdentifier> get shownNames => _shownNames;

  void visitChildren(AstVisitor visitor) {
    _shownNames.accept(visitor);
  }
}

/**
 * Instances of the class `SimpleFormalParameter` represent a simple formal parameter.
 *
 * <pre>
 * simpleFormalParameter ::=
 *     ('final' [TypeName] | 'var' | [TypeName])? [SimpleIdentifier]
 * </pre>
 */
class SimpleFormalParameter extends NormalFormalParameter {
  /**
   * The token representing either the 'final', 'const' or 'var' keyword, or `null` if no
   * keyword was used.
   */
  Token keyword;

  /**
   * The name of the declared type of the parameter, or `null` if the parameter does not have
   * a declared type.
   */
  TypeName _type;

  /**
   * Initialize a newly created formal parameter.
   *
   * @param comment the documentation comment associated with this parameter
   * @param metadata the annotations associated with this parameter
   * @param keyword the token representing either the 'final', 'const' or 'var' keyword
   * @param type the name of the declared type of the parameter
   * @param identifier the name of the parameter being declared
   */
  SimpleFormalParameter(Comment comment, List<Annotation> metadata, this.keyword, TypeName type, SimpleIdentifier identifier) : super(comment, metadata, identifier) {
    this._type = becomeParentOf(type);
  }

  accept(AstVisitor visitor) => visitor.visitSimpleFormalParameter(this);

  Token get beginToken {
    if (keyword != null) {
      return keyword;
    } else if (_type != null) {
      return _type.beginToken;
    }
    return identifier.beginToken;
  }

  Token get endToken => identifier.endToken;

  /**
   * Return the name of the declared type of the parameter, or `null` if the parameter does
   * not have a declared type.
   *
   * @return the name of the declared type of the parameter
   */
  TypeName get type => _type;

  bool get isConst => (keyword is KeywordToken) && identical((keyword as KeywordToken).keyword, Keyword.CONST);

  bool get isFinal => (keyword is KeywordToken) && identical((keyword as KeywordToken).keyword, Keyword.FINAL);

  /**
   * Set the name of the declared type of the parameter to the given type name.
   *
   * @param typeName the name of the declared type of the parameter
   */
  void set type(TypeName typeName) {
    _type = becomeParentOf(typeName);
  }

  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_type, visitor);
    safelyVisitChild(identifier, visitor);
  }
}

/**
 * Instances of the class `SimpleIdentifier` represent a simple identifier.
 *
 * <pre>
 * simpleIdentifier ::=
 *     initialCharacter internalCharacter*
 *
 * initialCharacter ::= '_' | '$' | letter
 *
 * internalCharacter ::= '_' | '$' | letter | digit
 * </pre>
 */
class SimpleIdentifier extends Identifier {
  /**
   * The token representing the identifier.
   */
  Token token;

  /**
   * The element associated with this identifier based on static type information, or `null`
   * if the AST structure has not been resolved or if this identifier could not be resolved.
   */
  Element _staticElement;

  /**
   * The element associated with this identifier based on propagated type information, or
   * `null` if the AST structure has not been resolved or if this identifier could not be
   * resolved.
   */
  Element _propagatedElement;

  /**
   * If this expression is both in a getter and setter context, the [AuxiliaryElements] will
   * be set to hold onto the static and propagated information. The auxiliary element will hold onto
   * the elements from the getter context.
   */
  AuxiliaryElements auxiliaryElements = null;

  /**
   * Initialize a newly created identifier.
   *
   * @param token the token representing the identifier
   */
  SimpleIdentifier(this.token);

  accept(AstVisitor visitor) => visitor.visitSimpleIdentifier(this);

  Token get beginToken => token;

  Element get bestElement {
    if (_propagatedElement == null) {
      return _staticElement;
    }
    return _propagatedElement;
  }

  Token get endToken => token;

  String get name => token.lexeme;

  int get precedence => 16;

  Element get propagatedElement => _propagatedElement;

  Element get staticElement => _staticElement;

  /**
   * Return `true` if this identifier is the name being declared in a declaration.
   *
   * @return `true` if this identifier is the name being declared in a declaration
   */
  bool inDeclarationContext() {
    AstNode parent = this.parent;
    if (parent is CatchClause) {
      CatchClause clause = parent;
      return identical(this, clause.exceptionParameter) || identical(this, clause.stackTraceParameter);
    } else if (parent is ClassDeclaration) {
      return identical(this, parent.name);
    } else if (parent is ClassTypeAlias) {
      return identical(this, parent.name);
    } else if (parent is ConstructorDeclaration) {
      return identical(this, parent.name);
    } else if (parent is DeclaredIdentifier) {
      return identical(this, parent.identifier);
    } else if (parent is FunctionDeclaration) {
      return identical(this, parent.name);
    } else if (parent is FunctionTypeAlias) {
      return identical(this, parent.name);
    } else if (parent is Label) {
      return identical(this, parent.label) && (parent.parent is LabeledStatement);
    } else if (parent is MethodDeclaration) {
      return identical(this, parent.name);
    } else if (parent is FunctionTypedFormalParameter || parent is SimpleFormalParameter) {
      return identical(this, (parent as NormalFormalParameter).identifier);
    } else if (parent is TypeParameter) {
      return identical(this, parent.name);
    } else if (parent is VariableDeclaration) {
      return identical(this, parent.name);
    }
    return false;
  }

  /**
   * Return `true` if this expression is computing a right-hand value.
   *
   * Note that [inGetterContext] and [inSetterContext] are not opposites, nor are
   * they mutually exclusive. In other words, it is possible for both methods to return `true`
   * when invoked on the same node.
   *
   * @return `true` if this expression is in a context where a getter will be invoked
   */
  bool inGetterContext() {
    AstNode parent = this.parent;
    AstNode target = this;
    // skip prefix
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
    // skip label
    if (parent is Label) {
      return false;
    }
    // analyze usage
    if (parent is AssignmentExpression) {
      AssignmentExpression expr = parent as AssignmentExpression;
      if (identical(expr.leftHandSide, target) && identical(expr.operator.type, TokenType.EQ)) {
        return false;
      }
    }
    return true;
  }

  /**
   * Return `true` if this expression is computing a left-hand value.
   *
   * Note that [inGetterContext] and [inSetterContext] are not opposites, nor are
   * they mutually exclusive. In other words, it is possible for both methods to return `true`
   * when invoked on the same node.
   *
   * @return `true` if this expression is in a context where a setter will be invoked
   */
  bool inSetterContext() {
    AstNode parent = this.parent;
    AstNode target = this;
    // skip prefix
    if (parent is PrefixedIdentifier) {
      PrefixedIdentifier prefixed = parent as PrefixedIdentifier;
      // if this is the prefix, then return false
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
    // analyze usage
    if (parent is PrefixExpression) {
      return (parent as PrefixExpression).operator.type.isIncrementOperator;
    } else if (parent is PostfixExpression) {
      return true;
    } else if (parent is AssignmentExpression) {
      return identical((parent as AssignmentExpression).leftHandSide, target);
    }
    return false;
  }

  bool get isSynthetic => token.isSynthetic;

  /**
   * Set the element associated with this identifier based on propagated type information to the
   * given element.
   *
   * @param element the element to be associated with this identifier
   */
  void set propagatedElement(Element element) {
    _propagatedElement = validateElement(element);
  }

  /**
   * Set the element associated with this identifier based on static type information to the given
   * element.
   *
   * @param element the element to be associated with this identifier
   */
  void set staticElement(Element element) {
    _staticElement = validateElement(element);
  }

  void visitChildren(AstVisitor visitor) {
  }

  /**
   * Return the given element if it is valid, or report the problem and return `null` if it is
   * not appropriate.
   *
   * @param parent the parent of the element, used for reporting when there is a problem
   * @param isValid `true` if the element is appropriate
   * @param element the element to be associated with this identifier
   * @return the element to be associated with this identifier
   */
  Element returnOrReportElement(AstNode parent, bool isValid, Element element) {
    if (!isValid) {
      AnalysisEngine.instance.logger.logInformation3("Internal error: attempting to set the name of a ${parent.runtimeType.toString()} to a ${element.runtimeType.toString()}", new JavaException());
      return null;
    }
    return element;
  }

  /**
   * Return the given element if it is an appropriate element based on the parent of this
   * identifier, or `null` if it is not appropriate.
   *
   * @param element the element to be associated with this identifier
   * @return the element to be associated with this identifier
   */
  Element validateElement(Element element) {
    if (element == null) {
      return null;
    }
    AstNode parent = this.parent;
    if (parent is ClassDeclaration && identical(parent.name, this)) {
      return returnOrReportElement(parent, element is ClassElement, element);
    } else if (parent is ClassTypeAlias && identical(parent.name, this)) {
      return returnOrReportElement(parent, element is ClassElement, element);
    } else if (parent is DeclaredIdentifier && identical(parent.identifier, this)) {
      return returnOrReportElement(parent, element is LocalVariableElement, element);
    } else if (parent is FormalParameter && identical(parent.identifier, this)) {
      return returnOrReportElement(parent, element is ParameterElement, element);
    } else if (parent is FunctionDeclaration && identical(parent.name, this)) {
      return returnOrReportElement(parent, element is ExecutableElement, element);
    } else if (parent is FunctionTypeAlias && identical(parent.name, this)) {
      return returnOrReportElement(parent, element is FunctionTypeAliasElement, element);
    } else if (parent is MethodDeclaration && identical(parent.name, this)) {
      return returnOrReportElement(parent, element is ExecutableElement, element);
    } else if (parent is TypeParameter && identical(parent.name, this)) {
      return returnOrReportElement(parent, element is TypeParameterElement, element);
    } else if (parent is VariableDeclaration && identical(parent.name, this)) {
      return returnOrReportElement(parent, element is VariableElement, element);
    }
    return element;
  }
}

/**
 * Instances of the class `SimpleStringLiteral` represent a string literal expression that
 * does not contain any interpolations.
 *
 * <pre>
 * simpleStringLiteral ::=
 *     rawStringLiteral
 *   | basicStringLiteral
 *
 * rawStringLiteral ::=
 *     'r' basicStringLiteral
 *
 * simpleStringLiteral ::=
 *     multiLineStringLiteral
 *   | singleLineStringLiteral
 *
 * multiLineStringLiteral ::=
 *     "'''" characters "'''"
 *   | '"""' characters '"""'
 *
 * singleLineStringLiteral ::=
 *     "'" characters "'"
 *     '"' characters '"'
 * </pre>
 */
class SimpleStringLiteral extends StringLiteral {
  /**
   * The token representing the literal.
   */
  Token literal;

  /**
   * The value of the literal.
   */
  String _value;

  /**
   * The toolkit specific element associated with this literal, or `null`.
   */
  Element _toolkitElement;

  /**
   * Initialize a newly created simple string literal.
   *
   * @param literal the token representing the literal
   * @param value the value of the literal
   */
  SimpleStringLiteral(this.literal, String value) {
    this._value = StringUtilities.intern(value);
  }

  accept(AstVisitor visitor) => visitor.visitSimpleStringLiteral(this);

  Token get beginToken => literal;

  Token get endToken => literal;

  /**
   * Return the toolkit specific, non-Dart, element associated with this literal, or `null`.
   *
   * @return the element associated with this literal
   */
  Element get toolkitElement => _toolkitElement;

  /**
   * Return the value of the literal.
   *
   * @return the value of the literal
   */
  String get value => _value;

  /**
   * Return the offset of the first value character.
   *
   * @return the offset of the first value character
   */
  int get valueOffset {
    int valueOffset = 0;
    if (isRaw) {
      valueOffset += 1;
    }
    if (isMultiline) {
      valueOffset += 3;
    } else {
      valueOffset += 1;
    }
    return offset + valueOffset;
  }

  /**
   * Return `true` if this string literal is a multi-line string.
   *
   * @return `true` if this string literal is a multi-line string
   */
  bool get isMultiline {
    String lexeme = literal.lexeme;
    if (lexeme.length < 6) {
      return false;
    }
    return StringUtilities.endsWith3(lexeme, 0x22, 0x22, 0x22) || StringUtilities.endsWith3(lexeme, 0x27, 0x27, 0x27);
  }

  /**
   * Return `true` if this string literal is a raw string.
   *
   * @return `true` if this string literal is a raw string
   */
  bool get isRaw => literal.lexeme.codeUnitAt(0) == 0x72;

  bool get isSynthetic => literal.isSynthetic;

  /**
   * Set the toolkit specific, non-Dart, element associated with this literal.
   *
   * @param element the toolkit specific element to be associated with this literal
   */
  void set toolkitElement(Element element) {
    _toolkitElement = element;
  }

  /**
   * Set the value of the literal to the given string.
   *
   * @param string the value of the literal
   */
  void set value(String string) {
    _value = StringUtilities.intern(_value);
  }

  void visitChildren(AstVisitor visitor) {
  }

  void appendStringValue(JavaStringBuilder builder) {
    builder.append(value);
  }
}

/**
 * Instances of the class `Statement` defines the behavior common to nodes that represent a
 * statement.
 *
 * <pre>
 * statement ::=
 *     [Block]
 *   | [VariableDeclarationStatement]
 *   | [ForStatement]
 *   | [ForEachStatement]
 *   | [WhileStatement]
 *   | [DoStatement]
 *   | [SwitchStatement]
 *   | [IfStatement]
 *   | [TryStatement]
 *   | [BreakStatement]
 *   | [ContinueStatement]
 *   | [ReturnStatement]
 *   | [ExpressionStatement]
 *   | [FunctionDeclarationStatement]
 * </pre>
 */
abstract class Statement extends AstNode {
}

/**
 * Instances of the class `StringInterpolation` represent a string interpolation literal.
 *
 * <pre>
 * stringInterpolation ::=
 *     ''' [InterpolationElement]* '''
 *   | '"' [InterpolationElement]* '"'
 * </pre>
 */
class StringInterpolation extends StringLiteral {
  /**
   * The elements that will be composed to produce the resulting string.
   */
  NodeList<InterpolationElement> _elements;

  /**
   * Initialize a newly created string interpolation expression.
   *
   * @param elements the elements that will be composed to produce the resulting string
   */
  StringInterpolation(List<InterpolationElement> elements) {
    this._elements = new NodeList<InterpolationElement>(this);
    this._elements.addAll(elements);
  }

  accept(AstVisitor visitor) => visitor.visitStringInterpolation(this);

  Token get beginToken => _elements.beginToken;

  /**
   * Return the elements that will be composed to produce the resulting string.
   *
   * @return the elements that will be composed to produce the resulting string
   */
  NodeList<InterpolationElement> get elements => _elements;

  Token get endToken => _elements.endToken;

  void visitChildren(AstVisitor visitor) {
    _elements.accept(visitor);
  }

  void appendStringValue(JavaStringBuilder builder) {
    throw new IllegalArgumentException();
  }
}

/**
 * Instances of the class `StringLiteral` represent a string literal expression.
 *
 * <pre>
 * stringLiteral ::=
 *     [SimpleStringLiteral]
 *   | [AdjacentStrings]
 *   | [StringInterpolation]
 * </pre>
 */
abstract class StringLiteral extends Literal {
  /**
   * Return the value of the string literal, or `null` if the string is not a constant string
   * without any string interpolation.
   *
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
   *
   * @param builder the builder to which the string's value is to be appended
   * @throws IllegalArgumentException if the string is not a constant string without any string
   *           interpolation
   */
  void appendStringValue(JavaStringBuilder builder);
}

/**
 * Instances of the class `SuperConstructorInvocation` represent the invocation of a
 * superclass' constructor from within a constructor's initialization list.
 *
 * <pre>
 * superInvocation ::=
 *     'super' ('.' [SimpleIdentifier])? [ArgumentList]
 * </pre>
 */
class SuperConstructorInvocation extends ConstructorInitializer {
  /**
   * The token for the 'super' keyword.
   */
  Token keyword;

  /**
   * The token for the period before the name of the constructor that is being invoked, or
   * `null` if the unnamed constructor is being invoked.
   */
  Token period;

  /**
   * The name of the constructor that is being invoked, or `null` if the unnamed constructor
   * is being invoked.
   */
  SimpleIdentifier _constructorName;

  /**
   * The list of arguments to the constructor.
   */
  ArgumentList _argumentList;

  /**
   * The element associated with the constructor based on static type information, or `null`
   * if the AST structure has not been resolved or if the constructor could not be resolved.
   */
  ConstructorElement staticElement;

  /**
   * Initialize a newly created super invocation to invoke the inherited constructor with the given
   * name with the given arguments.
   *
   * @param keyword the token for the 'super' keyword
   * @param period the token for the period before the name of the constructor that is being invoked
   * @param constructorName the name of the constructor that is being invoked
   * @param argumentList the list of arguments to the constructor
   */
  SuperConstructorInvocation(this.keyword, this.period, SimpleIdentifier constructorName, ArgumentList argumentList) {
    this._constructorName = becomeParentOf(constructorName);
    this._argumentList = becomeParentOf(argumentList);
  }

  accept(AstVisitor visitor) => visitor.visitSuperConstructorInvocation(this);

  /**
   * Return the list of arguments to the constructor.
   *
   * @return the list of arguments to the constructor
   */
  ArgumentList get argumentList => _argumentList;

  Token get beginToken => keyword;

  /**
   * Return the name of the constructor that is being invoked, or `null` if the unnamed
   * constructor is being invoked.
   *
   * @return the name of the constructor that is being invoked
   */
  SimpleIdentifier get constructorName => _constructorName;

  Token get endToken => _argumentList.endToken;

  /**
   * Set the list of arguments to the constructor to the given list.
   *
   * @param argumentList the list of arguments to the constructor
   */
  void set argumentList(ArgumentList argumentList) {
    this._argumentList = becomeParentOf(argumentList);
  }

  /**
   * Set the name of the constructor that is being invoked to the given identifier.
   *
   * @param identifier the name of the constructor that is being invoked
   */
  void set constructorName(SimpleIdentifier identifier) {
    _constructorName = becomeParentOf(identifier);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_constructorName, visitor);
    safelyVisitChild(_argumentList, visitor);
  }
}

/**
 * Instances of the class `SuperExpression` represent a super expression.
 *
 * <pre>
 * superExpression ::=
 *     'super'
 * </pre>
 */
class SuperExpression extends Expression {
  /**
   * The token representing the keyword.
   */
  Token keyword;

  /**
   * Initialize a newly created super expression.
   *
   * @param keyword the token representing the keyword
   */
  SuperExpression(this.keyword);

  accept(AstVisitor visitor) => visitor.visitSuperExpression(this);

  Token get beginToken => keyword;

  Token get endToken => keyword;

  int get precedence => 16;

  void visitChildren(AstVisitor visitor) {
  }
}

/**
 * Instances of the class `SwitchCase` represent the case in a switch statement.
 *
 * <pre>
 * switchCase ::=
 *     [SimpleIdentifier]* 'case' [Expression] ':' [Statement]*
 * </pre>
 */
class SwitchCase extends SwitchMember {
  /**
   * The expression controlling whether the statements will be executed.
   */
  Expression _expression;

  /**
   * Initialize a newly created switch case.
   *
   * @param labels the labels associated with the switch member
   * @param keyword the token representing the 'case' or 'default' keyword
   * @param expression the expression controlling whether the statements will be executed
   * @param colon the colon separating the keyword or the expression from the statements
   * @param statements the statements that will be executed if this switch member is selected
   */
  SwitchCase(List<Label> labels, Token keyword, Expression expression, Token colon, List<Statement> statements) : super(labels, keyword, colon, statements) {
    this._expression = becomeParentOf(expression);
  }

  accept(AstVisitor visitor) => visitor.visitSwitchCase(this);

  /**
   * Return the expression controlling whether the statements will be executed.
   *
   * @return the expression controlling whether the statements will be executed
   */
  Expression get expression => _expression;

  /**
   * Set the expression controlling whether the statements will be executed to the given expression.
   *
   * @param expression the expression controlling whether the statements will be executed
   */
  void set expression(Expression expression) {
    this._expression = becomeParentOf(expression);
  }

  void visitChildren(AstVisitor visitor) {
    labels.accept(visitor);
    safelyVisitChild(_expression, visitor);
    statements.accept(visitor);
  }
}

/**
 * Instances of the class `SwitchDefault` represent the default case in a switch statement.
 *
 * <pre>
 * switchDefault ::=
 *     [SimpleIdentifier]* 'default' ':' [Statement]*
 * </pre>
 */
class SwitchDefault extends SwitchMember {
  /**
   * Initialize a newly created switch default.
   *
   * @param labels the labels associated with the switch member
   * @param keyword the token representing the 'case' or 'default' keyword
   * @param colon the colon separating the keyword or the expression from the statements
   * @param statements the statements that will be executed if this switch member is selected
   */
  SwitchDefault(List<Label> labels, Token keyword, Token colon, List<Statement> statements) : super(labels, keyword, colon, statements);

  accept(AstVisitor visitor) => visitor.visitSwitchDefault(this);

  void visitChildren(AstVisitor visitor) {
    labels.accept(visitor);
    statements.accept(visitor);
  }
}

/**
 * The abstract class `SwitchMember` defines the behavior common to objects representing
 * elements within a switch statement.
 *
 * <pre>
 * switchMember ::=
 *     switchCase
 *   | switchDefault
 * </pre>
 */
abstract class SwitchMember extends AstNode {
  /**
   * The labels associated with the switch member.
   */
  NodeList<Label> _labels;

  /**
   * The token representing the 'case' or 'default' keyword.
   */
  Token keyword;

  /**
   * The colon separating the keyword or the expression from the statements.
   */
  Token colon;

  /**
   * The statements that will be executed if this switch member is selected.
   */
  NodeList<Statement> _statements;

  /**
   * Initialize a newly created switch member.
   *
   * @param labels the labels associated with the switch member
   * @param keyword the token representing the 'case' or 'default' keyword
   * @param colon the colon separating the keyword or the expression from the statements
   * @param statements the statements that will be executed if this switch member is selected
   */
  SwitchMember(List<Label> labels, this.keyword, this.colon, List<Statement> statements) {
    this._labels = new NodeList<Label>(this);
    this._statements = new NodeList<Statement>(this);
    this._labels.addAll(labels);
    this._statements.addAll(statements);
  }

  Token get beginToken {
    if (!_labels.isEmpty) {
      return _labels.beginToken;
    }
    return keyword;
  }

  Token get endToken {
    if (!_statements.isEmpty) {
      return _statements.endToken;
    }
    return colon;
  }

  /**
   * Return the labels associated with the switch member.
   *
   * @return the labels associated with the switch member
   */
  NodeList<Label> get labels => _labels;

  /**
   * Return the statements that will be executed if this switch member is selected.
   *
   * @return the statements that will be executed if this switch member is selected
   */
  NodeList<Statement> get statements => _statements;
}

/**
 * Instances of the class `SwitchStatement` represent a switch statement.
 *
 * <pre>
 * switchStatement ::=
 *     'switch' '(' [Expression] ')' '{' [SwitchCase]* [SwitchDefault]? '}'
 * </pre>
 */
class SwitchStatement extends Statement {
  /**
   * The token representing the 'switch' keyword.
   */
  Token keyword;

  /**
   * The left parenthesis.
   */
  Token leftParenthesis;

  /**
   * The expression used to determine which of the switch members will be selected.
   */
  Expression _expression;

  /**
   * The right parenthesis.
   */
  Token rightParenthesis;

  /**
   * The left curly bracket.
   */
  Token leftBracket;

  /**
   * The switch members that can be selected by the expression.
   */
  NodeList<SwitchMember> _members;

  /**
   * The right curly bracket.
   */
  Token rightBracket;

  /**
   * Initialize a newly created switch statement.
   *
   * @param keyword the token representing the 'switch' keyword
   * @param leftParenthesis the left parenthesis
   * @param expression the expression used to determine which of the switch members will be selected
   * @param rightParenthesis the right parenthesis
   * @param leftBracket the left curly bracket
   * @param members the switch members that can be selected by the expression
   * @param rightBracket the right curly bracket
   */
  SwitchStatement(this.keyword, this.leftParenthesis, Expression expression, this.rightParenthesis, this.leftBracket, List<SwitchMember> members, this.rightBracket) {
    this._members = new NodeList<SwitchMember>(this);
    this._expression = becomeParentOf(expression);
    this._members.addAll(members);
  }

  accept(AstVisitor visitor) => visitor.visitSwitchStatement(this);

  Token get beginToken => keyword;

  Token get endToken => rightBracket;

  /**
   * Return the expression used to determine which of the switch members will be selected.
   *
   * @return the expression used to determine which of the switch members will be selected
   */
  Expression get expression => _expression;

  /**
   * Return the switch members that can be selected by the expression.
   *
   * @return the switch members that can be selected by the expression
   */
  NodeList<SwitchMember> get members => _members;

  /**
   * Set the expression used to determine which of the switch members will be selected to the given
   * expression.
   *
   * @param expression the expression used to determine which of the switch members will be selected
   */
  void set expression(Expression expression) {
    this._expression = becomeParentOf(expression);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_expression, visitor);
    _members.accept(visitor);
  }
}

/**
 * Instances of the class `SymbolLiteral` represent a symbol literal expression.
 *
 * <pre>
 * symbolLiteral ::=
 *     '#' (operator | (identifier ('.' identifier)*))
 * </pre>
 */
class SymbolLiteral extends Literal {
  /**
   * The token introducing the literal.
   */
  Token poundSign;

  /**
   * The components of the literal.
   */
  final List<Token> components;

  /**
   * Initialize a newly created symbol literal.
   *
   * @param poundSign the token introducing the literal
   * @param components the components of the literal
   */
  SymbolLiteral(this.poundSign, this.components);

  accept(AstVisitor visitor) => visitor.visitSymbolLiteral(this);

  Token get beginToken => poundSign;

  Token get endToken => components[components.length - 1];

  void visitChildren(AstVisitor visitor) {
  }
}

/**
 * Instances of the class `ThisExpression` represent a this expression.
 *
 * <pre>
 * thisExpression ::=
 *     'this'
 * </pre>
 */
class ThisExpression extends Expression {
  /**
   * The token representing the keyword.
   */
  Token keyword;

  /**
   * Initialize a newly created this expression.
   *
   * @param keyword the token representing the keyword
   */
  ThisExpression(this.keyword);

  accept(AstVisitor visitor) => visitor.visitThisExpression(this);

  Token get beginToken => keyword;

  Token get endToken => keyword;

  int get precedence => 16;

  void visitChildren(AstVisitor visitor) {
  }
}

/**
 * Instances of the class `ThrowExpression` represent a throw expression.
 *
 * <pre>
 * throwExpression ::=
 *     'throw' [Expression]
 * </pre>
 */
class ThrowExpression extends Expression {
  /**
   * The token representing the 'throw' keyword.
   */
  Token keyword;

  /**
   * The expression computing the exception to be thrown.
   */
  Expression _expression;

  /**
   * Initialize a newly created throw expression.
   *
   * @param keyword the token representing the 'throw' keyword
   * @param expression the expression computing the exception to be thrown
   */
  ThrowExpression(this.keyword, Expression expression) {
    this._expression = becomeParentOf(expression);
  }

  accept(AstVisitor visitor) => visitor.visitThrowExpression(this);

  Token get beginToken => keyword;

  Token get endToken {
    if (_expression != null) {
      return _expression.endToken;
    }
    return keyword;
  }

  /**
   * Return the expression computing the exception to be thrown.
   *
   * @return the expression computing the exception to be thrown
   */
  Expression get expression => _expression;

  int get precedence => 0;

  /**
   * Set the expression computing the exception to be thrown to the given expression.
   *
   * @param expression the expression computing the exception to be thrown
   */
  void set expression(Expression expression) {
    this._expression = becomeParentOf(expression);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_expression, visitor);
  }
}

/**
 * Instances of the class `TopLevelVariableDeclaration` represent the declaration of one or
 * more top-level variables of the same type.
 *
 * <pre>
 * topLevelVariableDeclaration ::=
 *     ('final' | 'const') type? staticFinalDeclarationList ';'
 *   | variableDeclaration ';'
 * </pre>
 */
class TopLevelVariableDeclaration extends CompilationUnitMember {
  /**
   * The top-level variables being declared.
   */
  VariableDeclarationList _variableList;

  /**
   * The semicolon terminating the declaration.
   */
  Token semicolon;

  /**
   * Initialize a newly created top-level variable declaration.
   *
   * @param comment the documentation comment associated with this variable
   * @param metadata the annotations associated with this variable
   * @param variableList the top-level variables being declared
   * @param semicolon the semicolon terminating the declaration
   */
  TopLevelVariableDeclaration(Comment comment, List<Annotation> metadata, VariableDeclarationList variableList, this.semicolon) : super(comment, metadata) {
    this._variableList = becomeParentOf(variableList);
  }

  accept(AstVisitor visitor) => visitor.visitTopLevelVariableDeclaration(this);

  Element get element => null;

  Token get endToken => semicolon;

  /**
   * Return the top-level variables being declared.
   *
   * @return the top-level variables being declared
   */
  VariableDeclarationList get variables => _variableList;

  /**
   * Set the top-level variables being declared to the given list of variables.
   *
   * @param variableList the top-level variables being declared
   */
  void set variables(VariableDeclarationList variableList) {
    variableList = becomeParentOf(variableList);
  }

  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_variableList, visitor);
  }

  Token get firstTokenAfterCommentAndMetadata => _variableList.beginToken;
}

/**
 * Instances of the class `TryStatement` represent a try statement.
 *
 * <pre>
 * tryStatement ::=
 *     'try' [Block] ([CatchClause]+ finallyClause? | finallyClause)
 *
 * finallyClause ::=
 *     'finally' [Block]
 * </pre>
 */
class TryStatement extends Statement {
  /**
   * The token representing the 'try' keyword.
   */
  Token tryKeyword;

  /**
   * The body of the statement.
   */
  Block _body;

  /**
   * The catch clauses contained in the try statement.
   */
  NodeList<CatchClause> _catchClauses;

  /**
   * The token representing the 'finally' keyword, or `null` if the statement does not contain
   * a finally clause.
   */
  Token finallyKeyword;

  /**
   * The finally block contained in the try statement, or `null` if the statement does not
   * contain a finally clause.
   */
  Block _finallyBlock;

  /**
   * Initialize a newly created try statement.
   *
   * @param tryKeyword the token representing the 'try' keyword
   * @param body the body of the statement
   * @param catchClauses the catch clauses contained in the try statement
   * @param finallyKeyword the token representing the 'finally' keyword
   * @param finallyBlock the finally block contained in the try statement
   */
  TryStatement(this.tryKeyword, Block body, List<CatchClause> catchClauses, this.finallyKeyword, Block finallyBlock) {
    this._catchClauses = new NodeList<CatchClause>(this);
    this._body = becomeParentOf(body);
    this._catchClauses.addAll(catchClauses);
    this._finallyBlock = becomeParentOf(finallyBlock);
  }

  accept(AstVisitor visitor) => visitor.visitTryStatement(this);

  Token get beginToken => tryKeyword;

  /**
   * Return the body of the statement.
   *
   * @return the body of the statement
   */
  Block get body => _body;

  /**
   * Return the catch clauses contained in the try statement.
   *
   * @return the catch clauses contained in the try statement
   */
  NodeList<CatchClause> get catchClauses => _catchClauses;

  Token get endToken {
    if (_finallyBlock != null) {
      return _finallyBlock.endToken;
    } else if (finallyKeyword != null) {
      return finallyKeyword;
    } else if (!_catchClauses.isEmpty) {
      return _catchClauses.endToken;
    }
    return _body.endToken;
  }

  /**
   * Return the finally block contained in the try statement, or `null` if the statement does
   * not contain a finally clause.
   *
   * @return the finally block contained in the try statement
   */
  Block get finallyBlock => _finallyBlock;

  /**
   * Set the body of the statement to the given block.
   *
   * @param block the body of the statement
   */
  void set body(Block block) {
    _body = becomeParentOf(block);
  }

  /**
   * Set the finally block contained in the try statement to the given block.
   *
   * @param block the finally block contained in the try statement
   */
  void set finallyBlock(Block block) {
    _finallyBlock = becomeParentOf(block);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_body, visitor);
    _catchClauses.accept(visitor);
    safelyVisitChild(_finallyBlock, visitor);
  }
}

/**
 * The abstract class `TypeAlias` defines the behavior common to declarations of type aliases.
 *
 * <pre>
 * typeAlias ::=
 *     'typedef' typeAliasBody
 *
 * typeAliasBody ::=
 *     classTypeAlias
 *   | functionTypeAlias
 * </pre>
 */
abstract class TypeAlias extends CompilationUnitMember {
  /**
   * The token representing the 'typedef' keyword.
   */
  Token keyword;

  /**
   * The semicolon terminating the declaration.
   */
  Token semicolon;

  /**
   * Initialize a newly created type alias.
   *
   * @param comment the documentation comment associated with this type alias
   * @param metadata the annotations associated with this type alias
   * @param keyword the token representing the 'typedef' keyword
   * @param semicolon the semicolon terminating the declaration
   */
  TypeAlias(Comment comment, List<Annotation> metadata, this.keyword, this.semicolon) : super(comment, metadata);

  Token get endToken => semicolon;

  Token get firstTokenAfterCommentAndMetadata => keyword;
}

/**
 * Instances of the class `TypeArgumentList` represent a list of type arguments.
 *
 * <pre>
 * typeArguments ::=
 *     '<' typeName (',' typeName)* '>'
 * </pre>
 */
class TypeArgumentList extends AstNode {
  /**
   * The left bracket.
   */
  Token leftBracket;

  /**
   * The type arguments associated with the type.
   */
  NodeList<TypeName> _arguments;

  /**
   * The right bracket.
   */
  Token rightBracket;

  /**
   * Initialize a newly created list of type arguments.
   *
   * @param leftBracket the left bracket
   * @param arguments the type arguments associated with the type
   * @param rightBracket the right bracket
   */
  TypeArgumentList(this.leftBracket, List<TypeName> arguments, this.rightBracket) {
    this._arguments = new NodeList<TypeName>(this);
    this._arguments.addAll(arguments);
  }

  accept(AstVisitor visitor) => visitor.visitTypeArgumentList(this);

  /**
   * Return the type arguments associated with the type.
   *
   * @return the type arguments associated with the type
   */
  NodeList<TypeName> get arguments => _arguments;

  Token get beginToken => leftBracket;

  Token get endToken => rightBracket;

  void visitChildren(AstVisitor visitor) {
    _arguments.accept(visitor);
  }
}

/**
 * Instances of the class `TypeName` represent the name of a type, which can optionally
 * include type arguments.
 *
 * <pre>
 * typeName ::=
 *     [Identifier] typeArguments?
 * </pre>
 */
class TypeName extends AstNode {
  /**
   * The name of the type.
   */
  Identifier _name;

  /**
   * The type arguments associated with the type, or `null` if there are no type arguments.
   */
  TypeArgumentList _typeArguments;

  /**
   * The type being named, or `null` if the AST structure has not been resolved.
   */
  Type2 type;

  /**
   * Initialize a newly created type name.
   *
   * @param name the name of the type
   * @param typeArguments the type arguments associated with the type, or `null` if there are
   *          no type arguments
   */
  TypeName(Identifier name, TypeArgumentList typeArguments) {
    this._name = becomeParentOf(name);
    this._typeArguments = becomeParentOf(typeArguments);
  }

  accept(AstVisitor visitor) => visitor.visitTypeName(this);

  Token get beginToken => _name.beginToken;

  Token get endToken {
    if (_typeArguments != null) {
      return _typeArguments.endToken;
    }
    return _name.endToken;
  }

  /**
   * Return the name of the type.
   *
   * @return the name of the type
   */
  Identifier get name => _name;

  /**
   * Return the type arguments associated with the type, or `null` if there are no type
   * arguments.
   *
   * @return the type arguments associated with the type
   */
  TypeArgumentList get typeArguments => _typeArguments;

  bool get isSynthetic => _name.isSynthetic && _typeArguments == null;

  /**
   * Set the name of the type to the given identifier.
   *
   * @param identifier the name of the type
   */
  void set name(Identifier identifier) {
    _name = becomeParentOf(identifier);
  }

  /**
   * Set the type arguments associated with the type to the given type arguments.
   *
   * @param typeArguments the type arguments associated with the type
   */
  void set typeArguments(TypeArgumentList typeArguments) {
    this._typeArguments = becomeParentOf(typeArguments);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_name, visitor);
    safelyVisitChild(_typeArguments, visitor);
  }
}

/**
 * Instances of the class `TypeParameter` represent a type parameter.
 *
 * <pre>
 * typeParameter ::=
 *     [SimpleIdentifier] ('extends' [TypeName])?
 * </pre>
 */
class TypeParameter extends Declaration {
  /**
   * The name of the type parameter.
   */
  SimpleIdentifier _name;

  /**
   * The token representing the 'extends' keyword, or `null` if there was no explicit upper
   * bound.
   */
  Token keyword;

  /**
   * The name of the upper bound for legal arguments, or `null` if there was no explicit upper
   * bound.
   */
  TypeName _bound;

  /**
   * Initialize a newly created type parameter.
   *
   * @param comment the documentation comment associated with the type parameter
   * @param metadata the annotations associated with the type parameter
   * @param name the name of the type parameter
   * @param keyword the token representing the 'extends' keyword
   * @param bound the name of the upper bound for legal arguments
   */
  TypeParameter(Comment comment, List<Annotation> metadata, SimpleIdentifier name, this.keyword, TypeName bound) : super(comment, metadata) {
    this._name = becomeParentOf(name);
    this._bound = becomeParentOf(bound);
  }

  accept(AstVisitor visitor) => visitor.visitTypeParameter(this);

  /**
   * Return the name of the upper bound for legal arguments, or `null` if there was no
   * explicit upper bound.
   *
   * @return the name of the upper bound for legal arguments
   */
  TypeName get bound => _bound;

  TypeParameterElement get element => _name != null ? (_name.staticElement as TypeParameterElement) : null;

  Token get endToken {
    if (_bound == null) {
      return _name.endToken;
    }
    return _bound.endToken;
  }

  /**
   * Return the name of the type parameter.
   *
   * @return the name of the type parameter
   */
  SimpleIdentifier get name => _name;

  /**
   * Set the name of the upper bound for legal arguments to the given type name.
   *
   * @param typeName the name of the upper bound for legal arguments
   */
  void set bound(TypeName typeName) {
    _bound = becomeParentOf(typeName);
  }

  /**
   * Set the name of the type parameter to the given identifier.
   *
   * @param identifier the name of the type parameter
   */
  void set name(SimpleIdentifier identifier) {
    _name = becomeParentOf(identifier);
  }

  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_name, visitor);
    safelyVisitChild(_bound, visitor);
  }

  Token get firstTokenAfterCommentAndMetadata => _name.beginToken;
}

/**
 * Instances of the class `TypeParameterList` represent type parameters within a declaration.
 *
 * <pre>
 * typeParameterList ::=
 *     '<' [TypeParameter] (',' [TypeParameter])* '>'
 * </pre>
 */
class TypeParameterList extends AstNode {
  /**
   * The left angle bracket.
   */
  final Token leftBracket;

  /**
   * The type parameters in the list.
   */
  NodeList<TypeParameter> _typeParameters;

  /**
   * The right angle bracket.
   */
  final Token rightBracket;

  /**
   * Initialize a newly created list of type parameters.
   *
   * @param leftBracket the left angle bracket
   * @param typeParameters the type parameters in the list
   * @param rightBracket the right angle bracket
   */
  TypeParameterList(this.leftBracket, List<TypeParameter> typeParameters, this.rightBracket) {
    this._typeParameters = new NodeList<TypeParameter>(this);
    this._typeParameters.addAll(typeParameters);
  }

  accept(AstVisitor visitor) => visitor.visitTypeParameterList(this);

  Token get beginToken => leftBracket;

  Token get endToken => rightBracket;

  /**
   * Return the type parameters for the type.
   *
   * @return the type parameters for the type
   */
  NodeList<TypeParameter> get typeParameters => _typeParameters;

  void visitChildren(AstVisitor visitor) {
    _typeParameters.accept(visitor);
  }
}

/**
 * The abstract class `TypedLiteral` defines the behavior common to literals that have a type
 * associated with them.
 *
 * <pre>
 * listLiteral ::=
 *     [ListLiteral]
 *   | [MapLiteral]
 * </pre>
 */
abstract class TypedLiteral extends Literal {
  /**
   * The token representing the 'const' keyword, or `null` if the literal is not a constant.
   */
  Token constKeyword;

  /**
   * The type argument associated with this literal, or `null` if no type arguments were
   * declared.
   */
  TypeArgumentList typeArguments;

  /**
   * Initialize a newly created typed literal.
   *
   * @param constKeyword the token representing the 'const' keyword
   * @param typeArguments the type argument associated with this literal, or `null` if no type
   *          arguments were declared
   */
  TypedLiteral(this.constKeyword, TypeArgumentList typeArguments) {
    this.typeArguments = becomeParentOf(typeArguments);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(typeArguments, visitor);
  }
}

/**
 * The abstract class `UriBasedDirective` defines the behavior common to nodes that represent
 * a directive that references a URI.
 *
 * <pre>
 * uriBasedDirective ::=
 *     [ExportDirective]
 *   | [ImportDirective]
 *   | [PartDirective]
 * </pre>
 */
abstract class UriBasedDirective extends Directive {
  /**
   * The URI referenced by this directive.
   */
  StringLiteral _uri;

  /**
   * Initialize a newly create URI-based directive.
   *
   * @param comment the documentation comment associated with this directive
   * @param metadata the annotations associated with the directive
   * @param uri the URI referenced by this directive
   */
  UriBasedDirective(Comment comment, List<Annotation> metadata, StringLiteral uri) : super(comment, metadata) {
    this._uri = becomeParentOf(uri);
  }

  /**
   * Return the URI referenced by this directive.
   *
   * @return the URI referenced by this directive
   */
  StringLiteral get uri => _uri;

  /**
   * Return the element associated with the URI of this directive, or `null` if the AST
   * structure has not been resolved or if this URI could not be resolved. Examples of the latter
   * case include a directive that contains an invalid URL or a URL that does not exist.
   *
   * @return the element associated with this directive
   */
  Element get uriElement;

  /**
   * Set the URI referenced by this directive to the given URI.
   *
   * @param uri the URI referenced by this directive
   */
  void set uri(StringLiteral uri) {
    this._uri = becomeParentOf(uri);
  }

  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_uri, visitor);
  }
}

/**
 * Instances of the class `VariableDeclaration` represent an identifier that has an initial
 * value associated with it. Instances of this class are always children of the class
 * [VariableDeclarationList].
 *
 * <pre>
 * variableDeclaration ::=
 *     [SimpleIdentifier] ('=' [Expression])?
 * </pre>
 */
class VariableDeclaration extends Declaration {
  /**
   * The name of the variable being declared.
   */
  SimpleIdentifier _name;

  /**
   * The equal sign separating the variable name from the initial value, or `null` if the
   * initial value was not specified.
   */
  Token equals;

  /**
   * The expression used to compute the initial value for the variable, or `null` if the
   * initial value was not specified.
   */
  Expression _initializer;

  /**
   * Initialize a newly created variable declaration.
   *
   * @param comment the documentation comment associated with this declaration
   * @param metadata the annotations associated with this member
   * @param name the name of the variable being declared
   * @param equals the equal sign separating the variable name from the initial value
   * @param initializer the expression used to compute the initial value for the variable
   */
  VariableDeclaration(Comment comment, List<Annotation> metadata, SimpleIdentifier name, this.equals, Expression initializer) : super(comment, metadata) {
    this._name = becomeParentOf(name);
    this._initializer = becomeParentOf(initializer);
  }

  accept(AstVisitor visitor) => visitor.visitVariableDeclaration(this);

  /**
   * This overridden implementation of getDocumentationComment() looks in the grandparent node for
   * dartdoc comments if no documentation is specifically available on the node.
   */
  Comment get documentationComment {
    Comment comment = super.documentationComment;
    if (comment == null) {
      if (parent != null && parent.parent != null) {
        AstNode node = parent.parent;
        if (node is AnnotatedNode) {
          return node.documentationComment;
        }
      }
    }
    return comment;
  }

  VariableElement get element => _name != null ? (_name.staticElement as VariableElement) : null;

  Token get endToken {
    if (_initializer != null) {
      return _initializer.endToken;
    }
    return _name.endToken;
  }

  /**
   * Return the expression used to compute the initial value for the variable, or `null` if
   * the initial value was not specified.
   *
   * @return the expression used to compute the initial value for the variable
   */
  Expression get initializer => _initializer;

  /**
   * Return the name of the variable being declared.
   *
   * @return the name of the variable being declared
   */
  SimpleIdentifier get name => _name;

  /**
   * Return `true` if this variable was declared with the 'const' modifier.
   *
   * @return `true` if this variable was declared with the 'const' modifier
   */
  bool get isConst {
    AstNode parent = this.parent;
    return parent is VariableDeclarationList && parent.isConst;
  }

  /**
   * Return `true` if this variable was declared with the 'final' modifier. Variables that are
   * declared with the 'const' modifier will return `false` even though they are implicitly
   * final.
   *
   * @return `true` if this variable was declared with the 'final' modifier
   */
  bool get isFinal {
    AstNode parent = this.parent;
    return parent is VariableDeclarationList && parent.isFinal;
  }

  /**
   * Set the expression used to compute the initial value for the variable to the given expression.
   *
   * @param initializer the expression used to compute the initial value for the variable
   */
  void set initializer(Expression initializer) {
    this._initializer = becomeParentOf(initializer);
  }

  /**
   * Set the name of the variable being declared to the given identifier.
   *
   * @param name the name of the variable being declared
   */
  void set name(SimpleIdentifier name) {
    this._name = becomeParentOf(name);
  }

  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChild(_name, visitor);
    safelyVisitChild(_initializer, visitor);
  }

  Token get firstTokenAfterCommentAndMetadata => _name.beginToken;
}

/**
 * Instances of the class `VariableDeclarationList` represent the declaration of one or more
 * variables of the same type.
 *
 * <pre>
 * variableDeclarationList ::=
 *     finalConstVarOrType [VariableDeclaration] (',' [VariableDeclaration])*
 *
 * finalConstVarOrType ::=
 *   | 'final' [TypeName]?
 *   | 'const' [TypeName]?
 *   | 'var'
 *   | [TypeName]
 * </pre>
 */
class VariableDeclarationList extends AnnotatedNode {
  /**
   * The token representing the 'final', 'const' or 'var' keyword, or `null` if no keyword was
   * included.
   */
  Token keyword;

  /**
   * The type of the variables being declared, or `null` if no type was provided.
   */
  TypeName _type;

  /**
   * A list containing the individual variables being declared.
   */
  NodeList<VariableDeclaration> _variables;

  /**
   * Initialize a newly created variable declaration list.
   *
   * @param comment the documentation comment associated with this declaration list
   * @param metadata the annotations associated with this declaration list
   * @param keyword the token representing the 'final', 'const' or 'var' keyword
   * @param type the type of the variables being declared
   * @param variables a list containing the individual variables being declared
   */
  VariableDeclarationList(Comment comment, List<Annotation> metadata, this.keyword, TypeName type, List<VariableDeclaration> variables) : super(comment, metadata) {
    this._variables = new NodeList<VariableDeclaration>(this);
    this._type = becomeParentOf(type);
    this._variables.addAll(variables);
  }

  accept(AstVisitor visitor) => visitor.visitVariableDeclarationList(this);

  Token get endToken => _variables.endToken;

  /**
   * Return the type of the variables being declared, or `null` if no type was provided.
   *
   * @return the type of the variables being declared
   */
  TypeName get type => _type;

  /**
   * Return a list containing the individual variables being declared.
   *
   * @return a list containing the individual variables being declared
   */
  NodeList<VariableDeclaration> get variables => _variables;

  /**
   * Return `true` if the variables in this list were declared with the 'const' modifier.
   *
   * @return `true` if the variables in this list were declared with the 'const' modifier
   */
  bool get isConst => keyword is KeywordToken && identical((keyword as KeywordToken).keyword, Keyword.CONST);

  /**
   * Return `true` if the variables in this list were declared with the 'final' modifier.
   * Variables that are declared with the 'const' modifier will return `false` even though
   * they are implicitly final.
   *
   * @return `true` if the variables in this list were declared with the 'final' modifier
   */
  bool get isFinal => keyword is KeywordToken && identical((keyword as KeywordToken).keyword, Keyword.FINAL);

  /**
   * Set the type of the variables being declared to the given type name.
   *
   * @param typeName the type of the variables being declared
   */
  void set type(TypeName typeName) {
    _type = becomeParentOf(typeName);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_type, visitor);
    _variables.accept(visitor);
  }

  Token get firstTokenAfterCommentAndMetadata {
    if (keyword != null) {
      return keyword;
    } else if (_type != null) {
      return _type.beginToken;
    }
    return _variables.beginToken;
  }
}

/**
 * Instances of the class `VariableDeclarationStatement` represent a list of variables that
 * are being declared in a context where a statement is required.
 *
 * <pre>
 * variableDeclarationStatement ::=
 *     [VariableDeclarationList] ';'
 * </pre>
 */
class VariableDeclarationStatement extends Statement {
  /**
   * The variables being declared.
   */
  VariableDeclarationList _variableList;

  /**
   * The semicolon terminating the statement.
   */
  Token semicolon;

  /**
   * Initialize a newly created variable declaration statement.
   *
   * @param variableList the fields being declared
   * @param semicolon the semicolon terminating the statement
   */
  VariableDeclarationStatement(VariableDeclarationList variableList, this.semicolon) {
    this._variableList = becomeParentOf(variableList);
  }

  accept(AstVisitor visitor) => visitor.visitVariableDeclarationStatement(this);

  Token get beginToken => _variableList.beginToken;

  Token get endToken => semicolon;

  /**
   * Return the variables being declared.
   *
   * @return the variables being declared
   */
  VariableDeclarationList get variables => _variableList;

  /**
   * Set the variables being declared to the given list of variables.
   *
   * @param variableList the variables being declared
   */
  void set variables(VariableDeclarationList variableList) {
    this._variableList = becomeParentOf(variableList);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_variableList, visitor);
  }
}

/**
 * Instances of the class `WhileStatement` represent a while statement.
 *
 * <pre>
 * whileStatement ::=
 *     'while' '(' [Expression] ')' [Statement]
 * </pre>
 */
class WhileStatement extends Statement {
  /**
   * The token representing the 'while' keyword.
   */
  Token keyword;

  /**
   * The left parenthesis.
   */
  Token leftParenthesis;

  /**
   * The expression used to determine whether to execute the body of the loop.
   */
  Expression _condition;

  /**
   * The right parenthesis.
   */
  Token rightParenthesis;

  /**
   * The body of the loop.
   */
  Statement _body;

  /**
   * Initialize a newly created while statement.
   *
   * @param keyword the token representing the 'while' keyword
   * @param leftParenthesis the left parenthesis
   * @param condition the expression used to determine whether to execute the body of the loop
   * @param rightParenthesis the right parenthesis
   * @param body the body of the loop
   */
  WhileStatement(this.keyword, this.leftParenthesis, Expression condition, this.rightParenthesis, Statement body) {
    this._condition = becomeParentOf(condition);
    this._body = becomeParentOf(body);
  }

  accept(AstVisitor visitor) => visitor.visitWhileStatement(this);

  Token get beginToken => keyword;

  /**
   * Return the body of the loop.
   *
   * @return the body of the loop
   */
  Statement get body => _body;

  /**
   * Return the expression used to determine whether to execute the body of the loop.
   *
   * @return the expression used to determine whether to execute the body of the loop
   */
  Expression get condition => _condition;

  Token get endToken => _body.endToken;

  /**
   * Set the body of the loop to the given statement.
   *
   * @param statement the body of the loop
   */
  void set body(Statement statement) {
    _body = becomeParentOf(statement);
  }

  /**
   * Set the expression used to determine whether to execute the body of the loop to the given
   * expression.
   *
   * @param expression the expression used to determine whether to execute the body of the loop
   */
  void set condition(Expression expression) {
    _condition = becomeParentOf(expression);
  }

  void visitChildren(AstVisitor visitor) {
    safelyVisitChild(_condition, visitor);
    safelyVisitChild(_body, visitor);
  }
}

/**
 * Instances of the class `WithClause` represent the with clause in a class declaration.
 *
 * <pre>
 * withClause ::=
 *     'with' [TypeName] (',' [TypeName])*
 * </pre>
 */
class WithClause extends AstNode {
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
   *
   * @param withKeyword the token representing the 'with' keyword
   * @param mixinTypes the names of the mixins that were specified
   */
  WithClause(Token withKeyword, List<TypeName> mixinTypes) {
    this._mixinTypes = new NodeList<TypeName>(this);
    this._withKeyword = withKeyword;
    this._mixinTypes.addAll(mixinTypes);
  }

  accept(AstVisitor visitor) => visitor.visitWithClause(this);

  Token get beginToken => _withKeyword;

  Token get endToken => _mixinTypes.endToken;

  /**
   * Return the names of the mixins that were specified.
   *
   * @return the names of the mixins that were specified
   */
  NodeList<TypeName> get mixinTypes => _mixinTypes;

  /**
   * Return the token representing the 'with' keyword.
   *
   * @return the token representing the 'with' keyword
   */
  Token get withKeyword => _withKeyword;

  /**
   * Set the token representing the 'with' keyword to the given token.
   *
   * @param withKeyword the token representing the 'with' keyword
   */
  void set mixinKeyword(Token withKeyword) {
    this._withKeyword = withKeyword;
  }

  void visitChildren(AstVisitor visitor) {
    _mixinTypes.accept(visitor);
  }
}

/**
 * Instances of the class `BreadthFirstVisitor` implement an AST visitor that will recursively
 * visit all of the nodes in an AST structure, similar to [GeneralizingAstVisitor]. This
 * visitor uses a breadth-first ordering rather than the depth-first ordering of
 * [GeneralizingAstVisitor].
 *
 * Subclasses that override a visit method must either invoke the overridden visit method or
 * explicitly invoke the more general visit method. Failure to do so will cause the visit methods
 * for superclasses of the node to not be invoked and will cause the children of the visited node to
 * not be visited.
 *
 * In addition, subclasses should <b>not</b> explicitly visit the children of a node, but should
 * ensure that the method [visitNode] is used to visit the children (either directly
 * or indirectly). Failure to do will break the order in which nodes are visited.
 */
class BreadthFirstVisitor<R> extends GeneralizingAstVisitor<R> {
  /**
   * A queue holding the nodes that have not yet been visited in the order in which they ought to be
   * visited.
   */
  Queue<AstNode> _queue = new Queue<AstNode>();

  /**
   * A visitor, used to visit the children of the current node, that will add the nodes it visits to
   * the [queue].
   */
  GeneralizingAstVisitor<Object> _childVisitor;

  /**
   * Visit all nodes in the tree starting at the given `root` node, in breadth-first order.
   *
   * @param root the root of the AST structure to be visited
   */
  void visitAllNodes(AstNode root) {
    _queue.add(root);
    while (!_queue.isEmpty) {
      AstNode next = _queue.removeFirst();
      next.accept(this);
    }
  }

  R visitNode(AstNode node) {
    node.visitChildren(_childVisitor);
    return null;
  }

  BreadthFirstVisitor() {
    this._childVisitor = new GeneralizingAstVisitor_BreadthFirstVisitor(this);
  }
}

class GeneralizingAstVisitor_BreadthFirstVisitor extends GeneralizingAstVisitor<Object> {
  final BreadthFirstVisitor BreadthFirstVisitor_this;

  GeneralizingAstVisitor_BreadthFirstVisitor(this.BreadthFirstVisitor_this) : super();

  Object visitNode(AstNode node) {
    BreadthFirstVisitor_this._queue.add(node);
    return null;
  }
}

/**
 * Instances of the class `ConstantEvaluator` evaluate constant expressions to produce their
 * compile-time value. According to the Dart Language Specification: <blockquote> A constant
 * expression is one of the following:
 * * A literal number.
 * * A literal boolean.
 * * A literal string where any interpolated expression is a compile-time constant that evaluates
 * to a numeric, string or boolean value or to `null`.
 * * `null`.
 * * A reference to a static constant variable.
 * * An identifier expression that denotes a constant variable, a class or a type parameter.
 * * A constant constructor invocation.
 * * A constant list literal.
 * * A constant map literal.
 * * A simple or qualified identifier denoting a top-level function or a static method.
 * * A parenthesized expression `(e)` where `e` is a constant expression.
 * * An expression of one of the forms `identical(e1, e2)`, `e1 == e2`,
 * `e1 != e2` where `e1` and `e2` are constant expressions that evaluate to a
 * numeric, string or boolean value or to `null`.
 * * An expression of one of the forms `!e`, `e1 && e2` or `e1 || e2`, where
 * `e`, `e1` and `e2` are constant expressions that evaluate to a boolean value or
 * to `null`.
 * * An expression of one of the forms `~e`, `e1 ^ e2`, `e1 & e2`,
 * `e1 | e2`, `e1 >> e2` or `e1 << e2`, where `e`, `e1` and `e2`
 * are constant expressions that evaluate to an integer value or to `null`.
 * * An expression of one of the forms `-e`, `e1 + e2`, `e1 - e2`,
 * `e1 * e2`, `e1 / e2`, `e1 ~/ e2`, `e1 > e2`, `e1 < e2`,
 * `e1 >= e2`, `e1 <= e2` or `e1 % e2`, where `e`, `e1` and `e2`
 * are constant expressions that evaluate to a numeric value or to `null`.
 * </blockquote> The values returned by instances of this class are therefore `null` and
 * instances of the classes `Boolean`, `BigInteger`, `Double`, `String`, and
 * `DartObject`.
 *
 * In addition, this class defines several values that can be returned to indicate various
 * conditions encountered during evaluation. These are documented with the static field that define
 * those values.
 */
class ConstantEvaluator extends GeneralizingAstVisitor<Object> {
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
        // integer or {@code null}
        if (leftOperand is int && rightOperand is int) {
          return leftOperand & rightOperand;
        }
      } else if (node.operator.type == TokenType.AMPERSAND_AMPERSAND) {
        // boolean or {@code null}
        if (leftOperand is bool && rightOperand is bool) {
          return leftOperand && rightOperand;
        }
      } else if (node.operator.type == TokenType.BANG_EQ) {
        // numeric, string, boolean, or {@code null}
        if (leftOperand is bool && rightOperand is bool) {
          return leftOperand != rightOperand;
        } else if (leftOperand is int && rightOperand is int) {
          return leftOperand != rightOperand;
        } else if (leftOperand is double && rightOperand is double) {
          return leftOperand != rightOperand;
        } else if (leftOperand is String && rightOperand is String) {
          return leftOperand != rightOperand;
        }
      } else if (node.operator.type == TokenType.BAR) {
        // integer or {@code null}
        if (leftOperand is int && rightOperand is int) {
          return leftOperand | rightOperand;
        }
      } else if (node.operator.type == TokenType.BAR_BAR) {
        // boolean or {@code null}
        if (leftOperand is bool && rightOperand is bool) {
          return leftOperand || rightOperand;
        }
      } else if (node.operator.type == TokenType.CARET) {
        // integer or {@code null}
        if (leftOperand is int && rightOperand is int) {
          return leftOperand ^ rightOperand;
        }
      } else if (node.operator.type == TokenType.EQ_EQ) {
        // numeric, string, boolean, or {@code null}
        if (leftOperand is bool && rightOperand is bool) {
          return identical(leftOperand, rightOperand);
        } else if (leftOperand is int && rightOperand is int) {
          return leftOperand == rightOperand;
        } else if (leftOperand is double && rightOperand is double) {
          return leftOperand == rightOperand;
        } else if (leftOperand is String && rightOperand is String) {
          return leftOperand == rightOperand;
        }
      } else if (node.operator.type == TokenType.GT) {
        // numeric or {@code null}
        if (leftOperand is int && rightOperand is int) {
          return leftOperand.compareTo(rightOperand) > 0;
        } else if (leftOperand is double && rightOperand is double) {
          return leftOperand.compareTo(rightOperand) > 0;
        }
      } else if (node.operator.type == TokenType.GT_EQ) {
        // numeric or {@code null}
        if (leftOperand is int && rightOperand is int) {
          return leftOperand.compareTo(rightOperand) >= 0;
        } else if (leftOperand is double && rightOperand is double) {
          return leftOperand.compareTo(rightOperand) >= 0;
        }
      } else if (node.operator.type == TokenType.GT_GT) {
        // integer or {@code null}
        if (leftOperand is int && rightOperand is int) {
          return leftOperand >> rightOperand;
        }
      } else if (node.operator.type == TokenType.LT) {
        // numeric or {@code null}
        if (leftOperand is int && rightOperand is int) {
          return leftOperand.compareTo(rightOperand) < 0;
        } else if (leftOperand is double && rightOperand is double) {
          return leftOperand.compareTo(rightOperand) < 0;
        }
      } else if (node.operator.type == TokenType.LT_EQ) {
        // numeric or {@code null}
        if (leftOperand is int && rightOperand is int) {
          return leftOperand.compareTo(rightOperand) <= 0;
        } else if (leftOperand is double && rightOperand is double) {
          return leftOperand.compareTo(rightOperand) <= 0;
        }
      } else if (node.operator.type == TokenType.LT_LT) {
        // integer or {@code null}
        if (leftOperand is int && rightOperand is int) {
          return leftOperand << rightOperand;
        }
      } else if (node.operator.type == TokenType.MINUS) {
        // numeric or {@code null}
        if (leftOperand is int && rightOperand is int) {
          return leftOperand - rightOperand;
        } else if (leftOperand is double && rightOperand is double) {
          return leftOperand - rightOperand;
        }
      } else if (node.operator.type == TokenType.PERCENT) {
        // numeric or {@code null}
        if (leftOperand is int && rightOperand is int) {
          return leftOperand.remainder(rightOperand);
        } else if (leftOperand is double && rightOperand is double) {
          return leftOperand % rightOperand;
        }
      } else if (node.operator.type == TokenType.PLUS) {
        // numeric or {@code null}
        if (leftOperand is int && rightOperand is int) {
          return leftOperand + rightOperand;
        } else if (leftOperand is double && rightOperand is double) {
          return leftOperand + rightOperand;
        }
      } else if (node.operator.type == TokenType.STAR) {
        // numeric or {@code null}
        if (leftOperand is int && rightOperand is int) {
          return leftOperand * rightOperand;
        } else if (leftOperand is double && rightOperand is double) {
          return leftOperand * rightOperand;
        }
      } else if (node.operator.type == TokenType.SLASH) {
        // numeric or {@code null}
        if (leftOperand is int && rightOperand is int) {
          if (rightOperand != 0) {
            return leftOperand ~/ rightOperand;
          } else {
            return leftOperand.toDouble() / rightOperand.toDouble();
          }
        } else if (leftOperand is double && rightOperand is double) {
          return leftOperand / rightOperand;
        }
      } else if (node.operator.type == TokenType.TILDE_SLASH) {
        // numeric or {@code null}
        if (leftOperand is int && rightOperand is int) {
          if (rightOperand != 0) {
            return leftOperand ~/ rightOperand;
          } else {
            return 0;
          }
        } else if (leftOperand is double && rightOperand is double) {
          return leftOperand ~/ rightOperand;
        }
      } else {
      }
      break;
    }
    // TODO(brianwilkerson) This doesn't handle numeric conversions.
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

  Object visitNode(AstNode node) => NOT_A_CONSTANT;

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
          return ~operand;
        }
      } else if (node.operator.type == TokenType.MINUS) {
        if (operand == null) {
          return null;
        } else if (operand is int) {
          return -operand;
        } else if (operand is double) {
          return -operand;
        }
      } else {
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

  Object visitSymbolLiteral(SymbolLiteral node) {
    // TODO(brianwilkerson) This isn't optimal because a Symbol is not a String.
    JavaStringBuilder builder = new JavaStringBuilder();
    for (Token component in node.components) {
      if (builder.length > 0) {
        builder.appendChar(0x2E);
      }
      builder.append(component.lexeme);
    }
    return builder.toString();
  }

  /**
   * Return the constant value of the static constant represented by the given element.
   *
   * @param element the element whose value is to be returned
   * @return the constant value of the static constant
   */
  Object getConstantValue(Element element) {
    // TODO(brianwilkerson) Implement this
    if (element is FieldElement) {
      FieldElement field = element;
      if (field.isStatic && field.isConst) {
      }
    }
    return NOT_A_CONSTANT;
  }
}

/**
 * Instances of the class `ElementLocator` locate the [Element]
 * associated with a given [AstNode].
 */
class ElementLocator {
  /**
   * Locate the [Element] associated with the given [AstNode].
   *
   * @param node the node (not `null`)
   * @return the associated element, or `null` if none is found
   */
  static Element locate(AstNode node) {
    ElementLocator_ElementMapper mapper = new ElementLocator_ElementMapper();
    return node.accept(mapper);
  }

  /**
   * Locate the [Element] associated with the given [AstNode] and offset.
   *
   * @param node the node (not `null`)
   * @param offset the offset relative to source
   * @return the associated element, or `null` if none is found
   */
  static Element locate2(AstNode node, int offset) {
    // try to get Element from node
    {
      Element nodeElement = locate(node);
      if (nodeElement != null) {
        return nodeElement;
      }
    }
    // try to get Angular specific Element
    {
      Element element = null;
      if (element != null) {
        return element;
      }
    }
    // no Element
    return null;
  }
}

/**
 * Visitor that maps nodes to elements.
 */
class ElementLocator_ElementMapper extends GeneralizingAstVisitor<Element> {
  Element visitAssignmentExpression(AssignmentExpression node) => node.bestElement;

  Element visitBinaryExpression(BinaryExpression node) => node.bestElement;

  Element visitClassDeclaration(ClassDeclaration node) => node.element;

  Element visitCompilationUnit(CompilationUnit node) => node.element;

  Element visitConstructorDeclaration(ConstructorDeclaration node) => node.element;

  Element visitFunctionDeclaration(FunctionDeclaration node) => node.element;

  Element visitIdentifier(Identifier node) {
    AstNode parent = node.parent;
    // Type name in InstanceCreationExpression
    {
      AstNode typeNameCandidate = parent;
      // new prefix.node[.constructorName]()
      if (typeNameCandidate is PrefixedIdentifier) {
        PrefixedIdentifier prefixedIdentifier = typeNameCandidate as PrefixedIdentifier;
        if (identical(prefixedIdentifier.identifier, node)) {
          typeNameCandidate = prefixedIdentifier.parent;
        }
      }
      // new typeName[.constructorName]()
      if (typeNameCandidate is TypeName) {
        TypeName typeName = typeNameCandidate as TypeName;
        if (typeName.parent is ConstructorName) {
          ConstructorName constructorName = typeName.parent as ConstructorName;
          return constructorName.staticElement;
        }
      }
    }
    // Extra work to map Constructor Declarations to their associated Constructor Elements
    if (parent is ConstructorDeclaration) {
      ConstructorDeclaration decl = parent;
      Identifier returnType = decl.returnType;
      if (identical(returnType, node)) {
        SimpleIdentifier name = decl.name;
        if (name != null) {
          return name.bestElement;
        }
        Element element = node.bestElement;
        if (element is ClassElement) {
          return element.unnamedConstructor;
        }
      }
    }
    if (parent is LibraryIdentifier) {
      AstNode grandParent = parent.parent;
      if (grandParent is PartOfDirective) {
        Element element = grandParent.element;
        if (element is LibraryElement) {
          return element.definingCompilationUnit;
        }
      }
    }
    Element element = node.bestElement;
    if (element == null) {
      element = node.staticElement;
    }
    return element;
  }

  Element visitImportDirective(ImportDirective node) => node.element;

  Element visitIndexExpression(IndexExpression node) => node.bestElement;

  Element visitInstanceCreationExpression(InstanceCreationExpression node) => node.staticElement;

  Element visitLibraryDirective(LibraryDirective node) => node.element;

  Element visitMethodDeclaration(MethodDeclaration node) => node.element;

  Element visitMethodInvocation(MethodInvocation node) => node.methodName.bestElement;

  Element visitPostfixExpression(PostfixExpression node) => node.bestElement;

  Element visitPrefixedIdentifier(PrefixedIdentifier node) => node.bestElement;

  Element visitPrefixExpression(PrefixExpression node) => node.bestElement;

  Element visitStringLiteral(StringLiteral node) {
    AstNode parent = node.parent;
    if (parent is UriBasedDirective) {
      return parent.uriElement;
    }
    return null;
  }

  Element visitVariableDeclaration(VariableDeclaration node) => node.element;
}

/**
 * Instances of the class `GeneralizingAstVisitor` implement an AST visitor that will
 * recursively visit all of the nodes in an AST structure (like instances of the class
 * [RecursiveAstVisitor]). In addition, when a node of a specific type is visited not only
 * will the visit method for that specific type of node be invoked, but additional methods for the
 * superclasses of that node will also be invoked. For example, using an instance of this class to
 * visit a [Block] will cause the method [visitBlock] to be invoked but will
 * also cause the methods [visitStatement] and [visitNode] to be
 * subsequently invoked. This allows visitors to be written that visit all statements without
 * needing to override the visit method for each of the specific subclasses of [Statement].
 *
 * Subclasses that override a visit method must either invoke the overridden visit method or
 * explicitly invoke the more general visit method. Failure to do so will cause the visit methods
 * for superclasses of the node to not be invoked and will cause the children of the visited node to
 * not be visited.
 */
class GeneralizingAstVisitor<R> implements AstVisitor<R> {
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

  R visitNativeClause(NativeClause node) => visitNode(node);

  R visitNativeFunctionBody(NativeFunctionBody node) => visitFunctionBody(node);

  R visitNode(AstNode node) {
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

  R visitSymbolLiteral(SymbolLiteral node) => visitLiteral(node);

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
 * Instances of the class `NodeLocator` locate the [AstNode] associated with a
 * source range, given the AST structure built from the source. More specifically, they will return
 * the [AstNode] with the shortest length whose source range completely encompasses
 * the specified range.
 */
class NodeLocator extends UnifyingAstVisitor<Object> {
  /**
   * The start offset of the range used to identify the node.
   */
  int _startOffset = 0;

  /**
   * The end offset of the range used to identify the node.
   */
  int _endOffset = 0;

  /**
   * The element that was found that corresponds to the given source range, or `null` if there
   * is no such element.
   */
  AstNode _foundNode;

  /**
   * Initialize a newly created locator to locate one or more [AstNode] by locating
   * the node within an AST structure that corresponds to the given offset in the source.
   *
   * @param offset the offset used to identify the node
   */
  NodeLocator.con1(int offset) : this.con2(offset, offset);

  /**
   * Initialize a newly created locator to locate one or more [AstNode] by locating
   * the node within an AST structure that corresponds to the given range of characters in the
   * source.
   *
   * @param start the start offset of the range used to identify the node
   * @param end the end offset of the range used to identify the node
   */
  NodeLocator.con2(int start, int end) {
    this._startOffset = start;
    this._endOffset = end;
  }

  /**
   * Return the node that was found that corresponds to the given source range, or `null` if
   * there is no such node.
   *
   * @return the node that was found
   */
  AstNode get foundNode => _foundNode;

  /**
   * Search within the given AST node for an identifier representing a [DartElement] in the specified source range. Return the element that was found, or `null` if
   * no element was found.
   *
   * @param node the AST node within which to search
   * @return the element that was found
   */
  AstNode searchWithin(AstNode node) {
    if (node == null) {
      return null;
    }
    try {
      node.accept(this);
    } on NodeLocator_NodeFoundException catch (exception) {
    } on JavaException catch (exception) {
      AnalysisEngine.instance.logger.logInformation3("Unable to locate element at offset (${_startOffset} - ${_endOffset})", exception);
      return null;
    }
    return _foundNode;
  }

  Object visitNode(AstNode node) {
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
    } on JavaException catch (exception) {
      // Ignore the exception and proceed in order to visit the rest of the structure.
      AnalysisEngine.instance.logger.logInformation3("Exception caught while traversing an AST structure.", exception);
    }
    if (start <= _startOffset && _endOffset <= end) {
      _foundNode = node;
      throw new NodeLocator_NodeFoundException();
    }
    return null;
  }
}

/**
 * Instances of the class `NodeFoundException` are used to cancel visiting after a node has
 * been found.
 */
class NodeLocator_NodeFoundException extends RuntimeException {
  static int _serialVersionUID = 1;
}

/**
 * Instances of the class `RecursiveAstVisitor` implement an AST visitor that will recursively
 * visit all of the nodes in an AST structure. For example, using an instance of this class to visit
 * a [Block] will also cause all of the statements in the block to be visited.
 *
 * Subclasses that override a visit method must either invoke the overridden visit method or must
 * explicitly ask the visited node to visit its children. Failure to do so will cause the children
 * of the visited node to not be visited.
 */
class RecursiveAstVisitor<R> implements AstVisitor<R> {
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

  R visitNativeClause(NativeClause node) {
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

  R visitSymbolLiteral(SymbolLiteral node) {
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
 * Instances of the class `SimpleAstVisitor` implement an AST visitor that will do nothing
 * when visiting an AST node. It is intended to be a superclass for classes that use the visitor
 * pattern primarily as a dispatch mechanism (and hence don't need to recursively visit a whole
 * structure) and that only need to visit a small number of node types.
 */
class SimpleAstVisitor<R> implements AstVisitor<R> {
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

  R visitNativeClause(NativeClause node) => null;

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

  R visitSymbolLiteral(SymbolLiteral node) => null;

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
 * Instances of the class `ToSourceVisitor` write a source representation of a visited AST
 * node (and all of it's children) to a writer.
 */
class ToSourceVisitor implements AstVisitor<Object> {
  /**
   * The writer to which the source is to be written.
   */
  PrintWriter _writer;

  /**
   * Initialize a newly created visitor to write source code representing the visited nodes to the
   * given writer.
   *
   * @param writer the writer to which the source is to be written
   */
  ToSourceVisitor(PrintWriter writer) {
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
    _writer.print("assert (");
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
    visitNodeListWithSeparator(node.statements, " ");
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
    visitTokenWithSuffix(node.abstractKeyword, " ");
    _writer.print("class ");
    visitNode(node.name);
    visitNode(node.typeParameters);
    visitNodeWithPrefix(" ", node.extendsClause);
    visitNodeWithPrefix(" ", node.withClause);
    visitNodeWithPrefix(" ", node.implementsClause);
    _writer.print(" {");
    visitNodeListWithSeparator(node.members, " ");
    _writer.print("}");
    return null;
  }

  Object visitClassTypeAlias(ClassTypeAlias node) {
    if (node.abstractKeyword != null) {
      _writer.print("abstract ");
    }
    _writer.print("class ");
    visitNode(node.name);
    visitNode(node.typeParameters);
    _writer.print(" = ");
    visitNode(node.superclass);
    visitNodeWithPrefix(" ", node.withClause);
    visitNodeWithPrefix(" ", node.implementsClause);
    _writer.print(";");
    return null;
  }

  Object visitComment(Comment node) => null;

  Object visitCommentReference(CommentReference node) => null;

  Object visitCompilationUnit(CompilationUnit node) {
    ScriptTag scriptTag = node.scriptTag;
    NodeList<Directive> directives = node.directives;
    visitNode(scriptTag);
    String prefix = scriptTag == null ? "" : " ";
    visitNodeListWithSeparatorAndPrefix(prefix, directives, " ");
    prefix = scriptTag == null && directives.isEmpty ? "" : " ";
    visitNodeListWithSeparatorAndPrefix(prefix, node.declarations, " ");
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
    visitTokenWithSuffix(node.externalKeyword, " ");
    visitTokenWithSuffix(node.constKeyword, " ");
    visitTokenWithSuffix(node.factoryKeyword, " ");
    visitNode(node.returnType);
    visitNodeWithPrefix(".", node.name);
    visitNode(node.parameters);
    visitNodeListWithSeparatorAndPrefix(" : ", node.initializers, ", ");
    visitNodeWithPrefix(" = ", node.redirectedConstructor);
    visitFunctionWithPrefix(" ", node.body);
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
    visitNodeListWithSeparator(node.elements, ", ");
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
    visitTokenWithSuffix(node.externalKeyword, " ");
    visitTokenWithSuffix(node.modifierKeyword, " ");
    visitNodeWithSuffix(node.returnType, " ");
    visitTokenWithSuffix(node.propertyKeyword, " ");
    visitTokenWithSuffix(node.operatorKeyword, " ");
    visitNode(node.name);
    if (!node.isGetter) {
      visitNode(node.parameters);
    }
    visitFunctionWithPrefix(" ", node.body);
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
      visitNode(node.target);
      _writer.print('.');
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
    visitNodeListWithSeparator(node.statements, " ");
    return null;
  }

  Object visitSwitchDefault(SwitchDefault node) {
    visitNodeListWithSeparatorAndSuffix(node.labels, " ", " ");
    _writer.print("default: ");
    visitNodeListWithSeparator(node.statements, " ");
    return null;
  }

  Object visitSwitchStatement(SwitchStatement node) {
    _writer.print("switch (");
    visitNode(node.expression);
    _writer.print(") {");
    visitNodeListWithSeparator(node.members, " ");
    _writer.print("}");
    return null;
  }

  Object visitSymbolLiteral(SymbolLiteral node) {
    _writer.print("#");
    List<Token> components = node.components;
    for (int i = 0; i < components.length; i++) {
      if (i > 0) {
        _writer.print(".");
      }
      _writer.print(components[i].lexeme);
    }
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

  /**
   * Visit the given function body, printing the prefix before if given body is not empty.
   *
   * @param prefix the prefix to be printed if there is a node to visit
   * @param body the function body to be visited
   */
  void visitFunctionWithPrefix(String prefix, FunctionBody body) {
    if (body is! EmptyFunctionBody) {
      _writer.print(prefix);
    }
    visitNode(body);
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
   *
   * @param prefix the prefix to be printed if the list is not empty
   * @param nodes the nodes to be printed
   * @param separator the separator to be printed between adjacent nodes
   */
  void visitNodeListWithSeparatorAndPrefix(String prefix, NodeList<AstNode> nodes, String separator) {
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

  /**
   * Print a list of nodes, separated by the given separator.
   *
   * @param nodes the nodes to be printed
   * @param separator the separator to be printed between adjacent nodes
   * @param suffix the suffix to be printed if the list is not empty
   */
  void visitNodeListWithSeparatorAndSuffix(NodeList<AstNode> nodes, String separator, String suffix) {
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
   * Safely visit the given node, printing the prefix before the node if it is non-`null`.
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
   * Safely visit the given node, printing the suffix after the node if it is non-`null`.
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
   * Safely visit the given node, printing the suffix after the node if it is non-`null`.
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

/**
 * Instances of the class `UnifyingAstVisitor` implement an AST visitor that will recursively
 * visit all of the nodes in an AST structure (like instances of the class
 * [RecursiveAstVisitor]). In addition, every node will also be visited by using a single
 * unified [visitNode] method.
 *
 * Subclasses that override a visit method must either invoke the overridden visit method or
 * explicitly invoke the more general [visitNode] method. Failure to do so will
 * cause the children of the visited node to not be visited.
 */
class UnifyingAstVisitor<R> implements AstVisitor<R> {
  R visitAdjacentStrings(AdjacentStrings node) => visitNode(node);

  R visitAnnotation(Annotation node) => visitNode(node);

  R visitArgumentDefinitionTest(ArgumentDefinitionTest node) => visitNode(node);

  R visitArgumentList(ArgumentList node) => visitNode(node);

  R visitAsExpression(AsExpression node) => visitNode(node);

  R visitAssertStatement(AssertStatement node) => visitNode(node);

  R visitAssignmentExpression(AssignmentExpression node) => visitNode(node);

  R visitBinaryExpression(BinaryExpression node) => visitNode(node);

  R visitBlock(Block node) => visitNode(node);

  R visitBlockFunctionBody(BlockFunctionBody node) => visitNode(node);

  R visitBooleanLiteral(BooleanLiteral node) => visitNode(node);

  R visitBreakStatement(BreakStatement node) => visitNode(node);

  R visitCascadeExpression(CascadeExpression node) => visitNode(node);

  R visitCatchClause(CatchClause node) => visitNode(node);

  R visitClassDeclaration(ClassDeclaration node) => visitNode(node);

  R visitClassTypeAlias(ClassTypeAlias node) => visitNode(node);

  R visitComment(Comment node) => visitNode(node);

  R visitCommentReference(CommentReference node) => visitNode(node);

  R visitCompilationUnit(CompilationUnit node) => visitNode(node);

  R visitConditionalExpression(ConditionalExpression node) => visitNode(node);

  R visitConstructorDeclaration(ConstructorDeclaration node) => visitNode(node);

  R visitConstructorFieldInitializer(ConstructorFieldInitializer node) => visitNode(node);

  R visitConstructorName(ConstructorName node) => visitNode(node);

  R visitContinueStatement(ContinueStatement node) => visitNode(node);

  R visitDeclaredIdentifier(DeclaredIdentifier node) => visitNode(node);

  R visitDefaultFormalParameter(DefaultFormalParameter node) => visitNode(node);

  R visitDoStatement(DoStatement node) => visitNode(node);

  R visitDoubleLiteral(DoubleLiteral node) => visitNode(node);

  R visitEmptyFunctionBody(EmptyFunctionBody node) => visitNode(node);

  R visitEmptyStatement(EmptyStatement node) => visitNode(node);

  R visitExportDirective(ExportDirective node) => visitNode(node);

  R visitExpressionFunctionBody(ExpressionFunctionBody node) => visitNode(node);

  R visitExpressionStatement(ExpressionStatement node) => visitNode(node);

  R visitExtendsClause(ExtendsClause node) => visitNode(node);

  R visitFieldDeclaration(FieldDeclaration node) => visitNode(node);

  R visitFieldFormalParameter(FieldFormalParameter node) => visitNode(node);

  R visitForEachStatement(ForEachStatement node) => visitNode(node);

  R visitFormalParameterList(FormalParameterList node) => visitNode(node);

  R visitForStatement(ForStatement node) => visitNode(node);

  R visitFunctionDeclaration(FunctionDeclaration node) => visitNode(node);

  R visitFunctionDeclarationStatement(FunctionDeclarationStatement node) => visitNode(node);

  R visitFunctionExpression(FunctionExpression node) => visitNode(node);

  R visitFunctionExpressionInvocation(FunctionExpressionInvocation node) => visitNode(node);

  R visitFunctionTypeAlias(FunctionTypeAlias node) => visitNode(node);

  R visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) => visitNode(node);

  R visitHideCombinator(HideCombinator node) => visitNode(node);

  R visitIfStatement(IfStatement node) => visitNode(node);

  R visitImplementsClause(ImplementsClause node) => visitNode(node);

  R visitImportDirective(ImportDirective node) => visitNode(node);

  R visitIndexExpression(IndexExpression node) => visitNode(node);

  R visitInstanceCreationExpression(InstanceCreationExpression node) => visitNode(node);

  R visitIntegerLiteral(IntegerLiteral node) => visitNode(node);

  R visitInterpolationExpression(InterpolationExpression node) => visitNode(node);

  R visitInterpolationString(InterpolationString node) => visitNode(node);

  R visitIsExpression(IsExpression node) => visitNode(node);

  R visitLabel(Label node) => visitNode(node);

  R visitLabeledStatement(LabeledStatement node) => visitNode(node);

  R visitLibraryDirective(LibraryDirective node) => visitNode(node);

  R visitLibraryIdentifier(LibraryIdentifier node) => visitNode(node);

  R visitListLiteral(ListLiteral node) => visitNode(node);

  R visitMapLiteral(MapLiteral node) => visitNode(node);

  R visitMapLiteralEntry(MapLiteralEntry node) => visitNode(node);

  R visitMethodDeclaration(MethodDeclaration node) => visitNode(node);

  R visitMethodInvocation(MethodInvocation node) => visitNode(node);

  R visitNamedExpression(NamedExpression node) => visitNode(node);

  R visitNativeClause(NativeClause node) => visitNode(node);

  R visitNativeFunctionBody(NativeFunctionBody node) => visitNode(node);

  R visitNode(AstNode node) {
    node.visitChildren(this);
    return null;
  }

  R visitNullLiteral(NullLiteral node) => visitNode(node);

  R visitParenthesizedExpression(ParenthesizedExpression node) => visitNode(node);

  R visitPartDirective(PartDirective node) => visitNode(node);

  R visitPartOfDirective(PartOfDirective node) => visitNode(node);

  R visitPostfixExpression(PostfixExpression node) => visitNode(node);

  R visitPrefixedIdentifier(PrefixedIdentifier node) => visitNode(node);

  R visitPrefixExpression(PrefixExpression node) => visitNode(node);

  R visitPropertyAccess(PropertyAccess node) => visitNode(node);

  R visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) => visitNode(node);

  R visitRethrowExpression(RethrowExpression node) => visitNode(node);

  R visitReturnStatement(ReturnStatement node) => visitNode(node);

  R visitScriptTag(ScriptTag scriptTag) => visitNode(scriptTag);

  R visitShowCombinator(ShowCombinator node) => visitNode(node);

  R visitSimpleFormalParameter(SimpleFormalParameter node) => visitNode(node);

  R visitSimpleIdentifier(SimpleIdentifier node) => visitNode(node);

  R visitSimpleStringLiteral(SimpleStringLiteral node) => visitNode(node);

  R visitStringInterpolation(StringInterpolation node) => visitNode(node);

  R visitSuperConstructorInvocation(SuperConstructorInvocation node) => visitNode(node);

  R visitSuperExpression(SuperExpression node) => visitNode(node);

  R visitSwitchCase(SwitchCase node) => visitNode(node);

  R visitSwitchDefault(SwitchDefault node) => visitNode(node);

  R visitSwitchStatement(SwitchStatement node) => visitNode(node);

  R visitSymbolLiteral(SymbolLiteral node) => visitNode(node);

  R visitThisExpression(ThisExpression node) => visitNode(node);

  R visitThrowExpression(ThrowExpression node) => visitNode(node);

  R visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) => visitNode(node);

  R visitTryStatement(TryStatement node) => visitNode(node);

  R visitTypeArgumentList(TypeArgumentList node) => visitNode(node);

  R visitTypeName(TypeName node) => visitNode(node);

  R visitTypeParameter(TypeParameter node) => visitNode(node);

  R visitTypeParameterList(TypeParameterList node) => visitNode(node);

  R visitVariableDeclaration(VariableDeclaration node) => visitNode(node);

  R visitVariableDeclarationList(VariableDeclarationList node) => visitNode(node);

  R visitVariableDeclarationStatement(VariableDeclarationStatement node) => visitNode(node);

  R visitWhileStatement(WhileStatement node) => visitNode(node);

  R visitWithClause(WithClause node) => visitNode(node);
}

/**
 * Instances of the class `AstCloner` implement an object that will clone any AST structure
 * that it visits. The cloner will only clone the structure, it will not preserve any resolution
 * results or properties associated with the nodes.
 */
class AstCloner implements AstVisitor<AstNode> {
  AdjacentStrings visitAdjacentStrings(AdjacentStrings node) => new AdjacentStrings(cloneNodeList(node.strings));

  Annotation visitAnnotation(Annotation node) => new Annotation(node.atSign, cloneNode(node.name), node.period, cloneNode(node.constructorName), cloneNode(node.arguments));

  ArgumentDefinitionTest visitArgumentDefinitionTest(ArgumentDefinitionTest node) => new ArgumentDefinitionTest(node.question, cloneNode(node.identifier));

  ArgumentList visitArgumentList(ArgumentList node) => new ArgumentList(node.leftParenthesis, cloneNodeList(node.arguments), node.rightParenthesis);

  AsExpression visitAsExpression(AsExpression node) => new AsExpression(cloneNode(node.expression), node.asOperator, cloneNode(node.type));

  AstNode visitAssertStatement(AssertStatement node) => new AssertStatement(node.keyword, node.leftParenthesis, cloneNode(node.condition), node.rightParenthesis, node.semicolon);

  AssignmentExpression visitAssignmentExpression(AssignmentExpression node) => new AssignmentExpression(cloneNode(node.leftHandSide), node.operator, cloneNode(node.rightHandSide));

  BinaryExpression visitBinaryExpression(BinaryExpression node) => new BinaryExpression(cloneNode(node.leftOperand), node.operator, cloneNode(node.rightOperand));

  Block visitBlock(Block node) => new Block(node.leftBracket, cloneNodeList(node.statements), node.rightBracket);

  BlockFunctionBody visitBlockFunctionBody(BlockFunctionBody node) => new BlockFunctionBody(cloneNode(node.block));

  BooleanLiteral visitBooleanLiteral(BooleanLiteral node) => new BooleanLiteral(node.literal, node.value);

  BreakStatement visitBreakStatement(BreakStatement node) => new BreakStatement(node.keyword, cloneNode(node.label), node.semicolon);

  CascadeExpression visitCascadeExpression(CascadeExpression node) => new CascadeExpression(cloneNode(node.target), cloneNodeList(node.cascadeSections));

  CatchClause visitCatchClause(CatchClause node) => new CatchClause(node.onKeyword, cloneNode(node.exceptionType), node.catchKeyword, node.leftParenthesis, cloneNode(node.exceptionParameter), node.comma, cloneNode(node.stackTraceParameter), node.rightParenthesis, cloneNode(node.body));

  ClassDeclaration visitClassDeclaration(ClassDeclaration node) {
    ClassDeclaration copy = new ClassDeclaration(cloneNode(node.documentationComment), cloneNodeList(node.metadata), node.abstractKeyword, node.classKeyword, cloneNode(node.name), cloneNode(node.typeParameters), cloneNode(node.extendsClause), cloneNode(node.withClause), cloneNode(node.implementsClause), node.leftBracket, cloneNodeList(node.members), node.rightBracket);
    copy.nativeClause = cloneNode(node.nativeClause);
    return copy;
  }

  ClassTypeAlias visitClassTypeAlias(ClassTypeAlias node) => new ClassTypeAlias(cloneNode(node.documentationComment), cloneNodeList(node.metadata), node.keyword, cloneNode(node.name), cloneNode(node.typeParameters), node.equals, node.abstractKeyword, cloneNode(node.superclass), cloneNode(node.withClause), cloneNode(node.implementsClause), node.semicolon);

  Comment visitComment(Comment node) {
    if (node.isDocumentation) {
      return Comment.createDocumentationComment2(node.tokens, cloneNodeList(node.references));
    } else if (node.isBlock) {
      return Comment.createBlockComment(node.tokens);
    }
    return Comment.createEndOfLineComment(node.tokens);
  }

  CommentReference visitCommentReference(CommentReference node) => new CommentReference(node.newKeyword, cloneNode(node.identifier));

  CompilationUnit visitCompilationUnit(CompilationUnit node) {
    CompilationUnit clone = new CompilationUnit(node.beginToken, cloneNode(node.scriptTag), cloneNodeList(node.directives), cloneNodeList(node.declarations), node.endToken);
    clone.lineInfo = node.lineInfo;
    return clone;
  }

  ConditionalExpression visitConditionalExpression(ConditionalExpression node) => new ConditionalExpression(cloneNode(node.condition), node.question, cloneNode(node.thenExpression), node.colon, cloneNode(node.elseExpression));

  ConstructorDeclaration visitConstructorDeclaration(ConstructorDeclaration node) => new ConstructorDeclaration(cloneNode(node.documentationComment), cloneNodeList(node.metadata), node.externalKeyword, node.constKeyword, node.factoryKeyword, cloneNode(node.returnType), node.period, cloneNode(node.name), cloneNode(node.parameters), node.separator, cloneNodeList(node.initializers), cloneNode(node.redirectedConstructor), cloneNode(node.body));

  ConstructorFieldInitializer visitConstructorFieldInitializer(ConstructorFieldInitializer node) => new ConstructorFieldInitializer(node.keyword, node.period, cloneNode(node.fieldName), node.equals, cloneNode(node.expression));

  ConstructorName visitConstructorName(ConstructorName node) => new ConstructorName(cloneNode(node.type), node.period, cloneNode(node.name));

  ContinueStatement visitContinueStatement(ContinueStatement node) => new ContinueStatement(node.keyword, cloneNode(node.label), node.semicolon);

  DeclaredIdentifier visitDeclaredIdentifier(DeclaredIdentifier node) => new DeclaredIdentifier(cloneNode(node.documentationComment), cloneNodeList(node.metadata), node.keyword, cloneNode(node.type), cloneNode(node.identifier));

  DefaultFormalParameter visitDefaultFormalParameter(DefaultFormalParameter node) => new DefaultFormalParameter(cloneNode(node.parameter), node.kind, node.separator, cloneNode(node.defaultValue));

  DoStatement visitDoStatement(DoStatement node) => new DoStatement(node.doKeyword, cloneNode(node.body), node.whileKeyword, node.leftParenthesis, cloneNode(node.condition), node.rightParenthesis, node.semicolon);

  DoubleLiteral visitDoubleLiteral(DoubleLiteral node) => new DoubleLiteral(node.literal, node.value);

  EmptyFunctionBody visitEmptyFunctionBody(EmptyFunctionBody node) => new EmptyFunctionBody(node.semicolon);

  EmptyStatement visitEmptyStatement(EmptyStatement node) => new EmptyStatement(node.semicolon);

  ExportDirective visitExportDirective(ExportDirective node) => new ExportDirective(cloneNode(node.documentationComment), cloneNodeList(node.metadata), node.keyword, cloneNode(node.uri), cloneNodeList(node.combinators), node.semicolon);

  ExpressionFunctionBody visitExpressionFunctionBody(ExpressionFunctionBody node) => new ExpressionFunctionBody(node.functionDefinition, cloneNode(node.expression), node.semicolon);

  ExpressionStatement visitExpressionStatement(ExpressionStatement node) => new ExpressionStatement(cloneNode(node.expression), node.semicolon);

  ExtendsClause visitExtendsClause(ExtendsClause node) => new ExtendsClause(node.keyword, cloneNode(node.superclass));

  FieldDeclaration visitFieldDeclaration(FieldDeclaration node) => new FieldDeclaration(cloneNode(node.documentationComment), cloneNodeList(node.metadata), node.staticKeyword, cloneNode(node.fields), node.semicolon);

  FieldFormalParameter visitFieldFormalParameter(FieldFormalParameter node) => new FieldFormalParameter(cloneNode(node.documentationComment), cloneNodeList(node.metadata), node.keyword, cloneNode(node.type), node.thisToken, node.period, cloneNode(node.identifier), cloneNode(node.parameters));

  ForEachStatement visitForEachStatement(ForEachStatement node) {
    DeclaredIdentifier loopVariable = node.loopVariable;
    if (loopVariable == null) {
      return new ForEachStatement.con2(node.forKeyword, node.leftParenthesis, cloneNode(node.identifier), node.inKeyword, cloneNode(node.iterator), node.rightParenthesis, cloneNode(node.body));
    }
    return new ForEachStatement.con1(node.forKeyword, node.leftParenthesis, cloneNode(loopVariable), node.inKeyword, cloneNode(node.iterator), node.rightParenthesis, cloneNode(node.body));
  }

  FormalParameterList visitFormalParameterList(FormalParameterList node) => new FormalParameterList(node.leftParenthesis, cloneNodeList(node.parameters), node.leftDelimiter, node.rightDelimiter, node.rightParenthesis);

  ForStatement visitForStatement(ForStatement node) => new ForStatement(node.forKeyword, node.leftParenthesis, cloneNode(node.variables), cloneNode(node.initialization), node.leftSeparator, cloneNode(node.condition), node.rightSeparator, cloneNodeList(node.updaters), node.rightParenthesis, cloneNode(node.body));

  FunctionDeclaration visitFunctionDeclaration(FunctionDeclaration node) => new FunctionDeclaration(cloneNode(node.documentationComment), cloneNodeList(node.metadata), node.externalKeyword, cloneNode(node.returnType), node.propertyKeyword, cloneNode(node.name), cloneNode(node.functionExpression));

  FunctionDeclarationStatement visitFunctionDeclarationStatement(FunctionDeclarationStatement node) => new FunctionDeclarationStatement(cloneNode(node.functionDeclaration));

  FunctionExpression visitFunctionExpression(FunctionExpression node) => new FunctionExpression(cloneNode(node.parameters), cloneNode(node.body));

  FunctionExpressionInvocation visitFunctionExpressionInvocation(FunctionExpressionInvocation node) => new FunctionExpressionInvocation(cloneNode(node.function), cloneNode(node.argumentList));

  FunctionTypeAlias visitFunctionTypeAlias(FunctionTypeAlias node) => new FunctionTypeAlias(cloneNode(node.documentationComment), cloneNodeList(node.metadata), node.keyword, cloneNode(node.returnType), cloneNode(node.name), cloneNode(node.typeParameters), cloneNode(node.parameters), node.semicolon);

  FunctionTypedFormalParameter visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) => new FunctionTypedFormalParameter(cloneNode(node.documentationComment), cloneNodeList(node.metadata), cloneNode(node.returnType), cloneNode(node.identifier), cloneNode(node.parameters));

  HideCombinator visitHideCombinator(HideCombinator node) => new HideCombinator(node.keyword, cloneNodeList(node.hiddenNames));

  IfStatement visitIfStatement(IfStatement node) => new IfStatement(node.ifKeyword, node.leftParenthesis, cloneNode(node.condition), node.rightParenthesis, cloneNode(node.thenStatement), node.elseKeyword, cloneNode(node.elseStatement));

  ImplementsClause visitImplementsClause(ImplementsClause node) => new ImplementsClause(node.keyword, cloneNodeList(node.interfaces));

  ImportDirective visitImportDirective(ImportDirective node) => new ImportDirective(cloneNode(node.documentationComment), cloneNodeList(node.metadata), node.keyword, cloneNode(node.uri), node.asToken, cloneNode(node.prefix), cloneNodeList(node.combinators), node.semicolon);

  IndexExpression visitIndexExpression(IndexExpression node) {
    Token period = node.period;
    if (period == null) {
      return new IndexExpression.forTarget(cloneNode(node.target), node.leftBracket, cloneNode(node.index), node.rightBracket);
    } else {
      return new IndexExpression.forCascade(period, node.leftBracket, cloneNode(node.index), node.rightBracket);
    }
  }

  InstanceCreationExpression visitInstanceCreationExpression(InstanceCreationExpression node) => new InstanceCreationExpression(node.keyword, cloneNode(node.constructorName), cloneNode(node.argumentList));

  IntegerLiteral visitIntegerLiteral(IntegerLiteral node) => new IntegerLiteral(node.literal, node.value);

  InterpolationExpression visitInterpolationExpression(InterpolationExpression node) => new InterpolationExpression(node.leftBracket, cloneNode(node.expression), node.rightBracket);

  InterpolationString visitInterpolationString(InterpolationString node) => new InterpolationString(node.contents, node.value);

  IsExpression visitIsExpression(IsExpression node) => new IsExpression(cloneNode(node.expression), node.isOperator, node.notOperator, cloneNode(node.type));

  Label visitLabel(Label node) => new Label(cloneNode(node.label), node.colon);

  LabeledStatement visitLabeledStatement(LabeledStatement node) => new LabeledStatement(cloneNodeList(node.labels), cloneNode(node.statement));

  LibraryDirective visitLibraryDirective(LibraryDirective node) => new LibraryDirective(cloneNode(node.documentationComment), cloneNodeList(node.metadata), node.libraryToken, cloneNode(node.name), node.semicolon);

  LibraryIdentifier visitLibraryIdentifier(LibraryIdentifier node) => new LibraryIdentifier(cloneNodeList(node.components));

  ListLiteral visitListLiteral(ListLiteral node) => new ListLiteral(node.constKeyword, cloneNode(node.typeArguments), node.leftBracket, cloneNodeList(node.elements), node.rightBracket);

  MapLiteral visitMapLiteral(MapLiteral node) => new MapLiteral(node.constKeyword, cloneNode(node.typeArguments), node.leftBracket, cloneNodeList(node.entries), node.rightBracket);

  MapLiteralEntry visitMapLiteralEntry(MapLiteralEntry node) => new MapLiteralEntry(cloneNode(node.key), node.separator, cloneNode(node.value));

  MethodDeclaration visitMethodDeclaration(MethodDeclaration node) => new MethodDeclaration(cloneNode(node.documentationComment), cloneNodeList(node.metadata), node.externalKeyword, node.modifierKeyword, cloneNode(node.returnType), node.propertyKeyword, node.operatorKeyword, cloneNode(node.name), cloneNode(node.parameters), cloneNode(node.body));

  MethodInvocation visitMethodInvocation(MethodInvocation node) => new MethodInvocation(cloneNode(node.target), node.period, cloneNode(node.methodName), cloneNode(node.argumentList));

  NamedExpression visitNamedExpression(NamedExpression node) => new NamedExpression(cloneNode(node.name), cloneNode(node.expression));

  AstNode visitNativeClause(NativeClause node) => new NativeClause(node.keyword, cloneNode(node.name));

  NativeFunctionBody visitNativeFunctionBody(NativeFunctionBody node) => new NativeFunctionBody(node.nativeToken, cloneNode(node.stringLiteral), node.semicolon);

  NullLiteral visitNullLiteral(NullLiteral node) => new NullLiteral(node.literal);

  ParenthesizedExpression visitParenthesizedExpression(ParenthesizedExpression node) => new ParenthesizedExpression(node.leftParenthesis, cloneNode(node.expression), node.rightParenthesis);

  PartDirective visitPartDirective(PartDirective node) => new PartDirective(cloneNode(node.documentationComment), cloneNodeList(node.metadata), node.partToken, cloneNode(node.uri), node.semicolon);

  PartOfDirective visitPartOfDirective(PartOfDirective node) => new PartOfDirective(cloneNode(node.documentationComment), cloneNodeList(node.metadata), node.partToken, node.ofToken, cloneNode(node.libraryName), node.semicolon);

  PostfixExpression visitPostfixExpression(PostfixExpression node) => new PostfixExpression(cloneNode(node.operand), node.operator);

  PrefixedIdentifier visitPrefixedIdentifier(PrefixedIdentifier node) => new PrefixedIdentifier(cloneNode(node.prefix), node.period, cloneNode(node.identifier));

  PrefixExpression visitPrefixExpression(PrefixExpression node) => new PrefixExpression(node.operator, cloneNode(node.operand));

  PropertyAccess visitPropertyAccess(PropertyAccess node) => new PropertyAccess(cloneNode(node.target), node.operator, cloneNode(node.propertyName));

  RedirectingConstructorInvocation visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) => new RedirectingConstructorInvocation(node.keyword, node.period, cloneNode(node.constructorName), cloneNode(node.argumentList));

  RethrowExpression visitRethrowExpression(RethrowExpression node) => new RethrowExpression(node.keyword);

  ReturnStatement visitReturnStatement(ReturnStatement node) => new ReturnStatement(node.keyword, cloneNode(node.expression), node.semicolon);

  ScriptTag visitScriptTag(ScriptTag node) => new ScriptTag(node.scriptTag);

  ShowCombinator visitShowCombinator(ShowCombinator node) => new ShowCombinator(node.keyword, cloneNodeList(node.shownNames));

  SimpleFormalParameter visitSimpleFormalParameter(SimpleFormalParameter node) => new SimpleFormalParameter(cloneNode(node.documentationComment), cloneNodeList(node.metadata), node.keyword, cloneNode(node.type), cloneNode(node.identifier));

  SimpleIdentifier visitSimpleIdentifier(SimpleIdentifier node) => new SimpleIdentifier(node.token);

  SimpleStringLiteral visitSimpleStringLiteral(SimpleStringLiteral node) => new SimpleStringLiteral(node.literal, node.value);

  StringInterpolation visitStringInterpolation(StringInterpolation node) => new StringInterpolation(cloneNodeList(node.elements));

  SuperConstructorInvocation visitSuperConstructorInvocation(SuperConstructorInvocation node) => new SuperConstructorInvocation(node.keyword, node.period, cloneNode(node.constructorName), cloneNode(node.argumentList));

  SuperExpression visitSuperExpression(SuperExpression node) => new SuperExpression(node.keyword);

  SwitchCase visitSwitchCase(SwitchCase node) => new SwitchCase(cloneNodeList(node.labels), node.keyword, cloneNode(node.expression), node.colon, cloneNodeList(node.statements));

  SwitchDefault visitSwitchDefault(SwitchDefault node) => new SwitchDefault(cloneNodeList(node.labels), node.keyword, node.colon, cloneNodeList(node.statements));

  SwitchStatement visitSwitchStatement(SwitchStatement node) => new SwitchStatement(node.keyword, node.leftParenthesis, cloneNode(node.expression), node.rightParenthesis, node.leftBracket, cloneNodeList(node.members), node.rightBracket);

  AstNode visitSymbolLiteral(SymbolLiteral node) => new SymbolLiteral(node.poundSign, node.components);

  ThisExpression visitThisExpression(ThisExpression node) => new ThisExpression(node.keyword);

  ThrowExpression visitThrowExpression(ThrowExpression node) => new ThrowExpression(node.keyword, cloneNode(node.expression));

  TopLevelVariableDeclaration visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) => new TopLevelVariableDeclaration(cloneNode(node.documentationComment), cloneNodeList(node.metadata), cloneNode(node.variables), node.semicolon);

  TryStatement visitTryStatement(TryStatement node) => new TryStatement(node.tryKeyword, cloneNode(node.body), cloneNodeList(node.catchClauses), node.finallyKeyword, cloneNode(node.finallyBlock));

  TypeArgumentList visitTypeArgumentList(TypeArgumentList node) => new TypeArgumentList(node.leftBracket, cloneNodeList(node.arguments), node.rightBracket);

  TypeName visitTypeName(TypeName node) => new TypeName(cloneNode(node.name), cloneNode(node.typeArguments));

  TypeParameter visitTypeParameter(TypeParameter node) => new TypeParameter(cloneNode(node.documentationComment), cloneNodeList(node.metadata), cloneNode(node.name), node.keyword, cloneNode(node.bound));

  TypeParameterList visitTypeParameterList(TypeParameterList node) => new TypeParameterList(node.leftBracket, cloneNodeList(node.typeParameters), node.rightBracket);

  VariableDeclaration visitVariableDeclaration(VariableDeclaration node) => new VariableDeclaration(null, cloneNodeList(node.metadata), cloneNode(node.name), node.equals, cloneNode(node.initializer));

  VariableDeclarationList visitVariableDeclarationList(VariableDeclarationList node) => new VariableDeclarationList(null, cloneNodeList(node.metadata), node.keyword, cloneNode(node.type), cloneNodeList(node.variables));

  VariableDeclarationStatement visitVariableDeclarationStatement(VariableDeclarationStatement node) => new VariableDeclarationStatement(cloneNode(node.variables), node.semicolon);

  WhileStatement visitWhileStatement(WhileStatement node) => new WhileStatement(node.keyword, node.leftParenthesis, cloneNode(node.condition), node.rightParenthesis, cloneNode(node.body));

  WithClause visitWithClause(WithClause node) => new WithClause(node.withKeyword, cloneNodeList(node.mixinTypes));

  AstNode cloneNode(AstNode node) {
    if (node == null) {
      return null;
    }
    return node.accept(this) as AstNode;
  }

  List cloneNodeList(NodeList nodes) {
    int count = nodes.length;
    List clonedNodes = new List();
    for (int i = 0; i < count; i++) {
      clonedNodes.add((nodes[i]).accept(this) as AstNode);
    }
    return clonedNodes;
  }
}

/**
 * Instances of the class `AstComparator` compare the structure of two ASTNodes to see whether
 * they are equal.
 */
class AstComparator implements AstVisitor<bool> {
  /**
   * Return `true` if the two AST nodes are equal.
   *
   * @param first the first node being compared
   * @param second the second node being compared
   * @return `true` if the two AST nodes are equal
   */
  static bool equals4(CompilationUnit first, CompilationUnit second) {
    AstComparator comparator = new AstComparator();
    return comparator.isEqualNodes(first, second);
  }

  /**
   * The AST node with which the node being visited is to be compared. This is only valid at the
   * beginning of each visit method (until [isEqualNodes] is invoked).
   */
  AstNode _other;

  bool visitAdjacentStrings(AdjacentStrings node) {
    AdjacentStrings other = this._other as AdjacentStrings;
    return isEqualNodeLists(node.strings, other.strings);
  }

  bool visitAnnotation(Annotation node) {
    Annotation other = this._other as Annotation;
    return isEqualTokens(node.atSign, other.atSign) && isEqualNodes(node.name, other.name) && isEqualTokens(node.period, other.period) && isEqualNodes(node.constructorName, other.constructorName) && isEqualNodes(node.arguments, other.arguments);
  }

  bool visitArgumentDefinitionTest(ArgumentDefinitionTest node) {
    ArgumentDefinitionTest other = this._other as ArgumentDefinitionTest;
    return isEqualTokens(node.question, other.question) && isEqualNodes(node.identifier, other.identifier);
  }

  bool visitArgumentList(ArgumentList node) {
    ArgumentList other = this._other as ArgumentList;
    return isEqualTokens(node.leftParenthesis, other.leftParenthesis) && isEqualNodeLists(node.arguments, other.arguments) && isEqualTokens(node.rightParenthesis, other.rightParenthesis);
  }

  bool visitAsExpression(AsExpression node) {
    AsExpression other = this._other as AsExpression;
    return isEqualNodes(node.expression, other.expression) && isEqualTokens(node.asOperator, other.asOperator) && isEqualNodes(node.type, other.type);
  }

  bool visitAssertStatement(AssertStatement node) {
    AssertStatement other = this._other as AssertStatement;
    return isEqualTokens(node.keyword, other.keyword) && isEqualTokens(node.leftParenthesis, other.leftParenthesis) && isEqualNodes(node.condition, other.condition) && isEqualTokens(node.rightParenthesis, other.rightParenthesis) && isEqualTokens(node.semicolon, other.semicolon);
  }

  bool visitAssignmentExpression(AssignmentExpression node) {
    AssignmentExpression other = this._other as AssignmentExpression;
    return isEqualNodes(node.leftHandSide, other.leftHandSide) && isEqualTokens(node.operator, other.operator) && isEqualNodes(node.rightHandSide, other.rightHandSide);
  }

  bool visitBinaryExpression(BinaryExpression node) {
    BinaryExpression other = this._other as BinaryExpression;
    return isEqualNodes(node.leftOperand, other.leftOperand) && isEqualTokens(node.operator, other.operator) && isEqualNodes(node.rightOperand, other.rightOperand);
  }

  bool visitBlock(Block node) {
    Block other = this._other as Block;
    return isEqualTokens(node.leftBracket, other.leftBracket) && isEqualNodeLists(node.statements, other.statements) && isEqualTokens(node.rightBracket, other.rightBracket);
  }

  bool visitBlockFunctionBody(BlockFunctionBody node) {
    BlockFunctionBody other = this._other as BlockFunctionBody;
    return isEqualNodes(node.block, other.block);
  }

  bool visitBooleanLiteral(BooleanLiteral node) {
    BooleanLiteral other = this._other as BooleanLiteral;
    return isEqualTokens(node.literal, other.literal) && identical(node.value, other.value);
  }

  bool visitBreakStatement(BreakStatement node) {
    BreakStatement other = this._other as BreakStatement;
    return isEqualTokens(node.keyword, other.keyword) && isEqualNodes(node.label, other.label) && isEqualTokens(node.semicolon, other.semicolon);
  }

  bool visitCascadeExpression(CascadeExpression node) {
    CascadeExpression other = this._other as CascadeExpression;
    return isEqualNodes(node.target, other.target) && isEqualNodeLists(node.cascadeSections, other.cascadeSections);
  }

  bool visitCatchClause(CatchClause node) {
    CatchClause other = this._other as CatchClause;
    return isEqualTokens(node.onKeyword, other.onKeyword) && isEqualNodes(node.exceptionType, other.exceptionType) && isEqualTokens(node.catchKeyword, other.catchKeyword) && isEqualTokens(node.leftParenthesis, other.leftParenthesis) && isEqualNodes(node.exceptionParameter, other.exceptionParameter) && isEqualTokens(node.comma, other.comma) && isEqualNodes(node.stackTraceParameter, other.stackTraceParameter) && isEqualTokens(node.rightParenthesis, other.rightParenthesis) && isEqualNodes(node.body, other.body);
  }

  bool visitClassDeclaration(ClassDeclaration node) {
    ClassDeclaration other = this._other as ClassDeclaration;
    return isEqualNodes(node.documentationComment, other.documentationComment) && isEqualNodeLists(node.metadata, other.metadata) && isEqualTokens(node.abstractKeyword, other.abstractKeyword) && isEqualTokens(node.classKeyword, other.classKeyword) && isEqualNodes(node.name, other.name) && isEqualNodes(node.typeParameters, other.typeParameters) && isEqualNodes(node.extendsClause, other.extendsClause) && isEqualNodes(node.withClause, other.withClause) && isEqualNodes(node.implementsClause, other.implementsClause) && isEqualTokens(node.leftBracket, other.leftBracket) && isEqualNodeLists(node.members, other.members) && isEqualTokens(node.rightBracket, other.rightBracket);
  }

  bool visitClassTypeAlias(ClassTypeAlias node) {
    ClassTypeAlias other = this._other as ClassTypeAlias;
    return isEqualNodes(node.documentationComment, other.documentationComment) && isEqualNodeLists(node.metadata, other.metadata) && isEqualTokens(node.keyword, other.keyword) && isEqualNodes(node.name, other.name) && isEqualNodes(node.typeParameters, other.typeParameters) && isEqualTokens(node.equals, other.equals) && isEqualTokens(node.abstractKeyword, other.abstractKeyword) && isEqualNodes(node.superclass, other.superclass) && isEqualNodes(node.withClause, other.withClause) && isEqualNodes(node.implementsClause, other.implementsClause) && isEqualTokens(node.semicolon, other.semicolon);
  }

  bool visitComment(Comment node) {
    Comment other = this._other as Comment;
    return isEqualNodeLists(node.references, other.references);
  }

  bool visitCommentReference(CommentReference node) {
    CommentReference other = this._other as CommentReference;
    return isEqualTokens(node.newKeyword, other.newKeyword) && isEqualNodes(node.identifier, other.identifier);
  }

  bool visitCompilationUnit(CompilationUnit node) {
    CompilationUnit other = this._other as CompilationUnit;
    return isEqualTokens(node.beginToken, other.beginToken) && isEqualNodes(node.scriptTag, other.scriptTag) && isEqualNodeLists(node.directives, other.directives) && isEqualNodeLists(node.declarations, other.declarations) && isEqualTokens(node.endToken, other.endToken);
  }

  bool visitConditionalExpression(ConditionalExpression node) {
    ConditionalExpression other = this._other as ConditionalExpression;
    return isEqualNodes(node.condition, other.condition) && isEqualTokens(node.question, other.question) && isEqualNodes(node.thenExpression, other.thenExpression) && isEqualTokens(node.colon, other.colon) && isEqualNodes(node.elseExpression, other.elseExpression);
  }

  bool visitConstructorDeclaration(ConstructorDeclaration node) {
    ConstructorDeclaration other = this._other as ConstructorDeclaration;
    return isEqualNodes(node.documentationComment, other.documentationComment) && isEqualNodeLists(node.metadata, other.metadata) && isEqualTokens(node.externalKeyword, other.externalKeyword) && isEqualTokens(node.constKeyword, other.constKeyword) && isEqualTokens(node.factoryKeyword, other.factoryKeyword) && isEqualNodes(node.returnType, other.returnType) && isEqualTokens(node.period, other.period) && isEqualNodes(node.name, other.name) && isEqualNodes(node.parameters, other.parameters) && isEqualTokens(node.separator, other.separator) && isEqualNodeLists(node.initializers, other.initializers) && isEqualNodes(node.redirectedConstructor, other.redirectedConstructor) && isEqualNodes(node.body, other.body);
  }

  bool visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    ConstructorFieldInitializer other = this._other as ConstructorFieldInitializer;
    return isEqualTokens(node.keyword, other.keyword) && isEqualTokens(node.period, other.period) && isEqualNodes(node.fieldName, other.fieldName) && isEqualTokens(node.equals, other.equals) && isEqualNodes(node.expression, other.expression);
  }

  bool visitConstructorName(ConstructorName node) {
    ConstructorName other = this._other as ConstructorName;
    return isEqualNodes(node.type, other.type) && isEqualTokens(node.period, other.period) && isEqualNodes(node.name, other.name);
  }

  bool visitContinueStatement(ContinueStatement node) {
    ContinueStatement other = this._other as ContinueStatement;
    return isEqualTokens(node.keyword, other.keyword) && isEqualNodes(node.label, other.label) && isEqualTokens(node.semicolon, other.semicolon);
  }

  bool visitDeclaredIdentifier(DeclaredIdentifier node) {
    DeclaredIdentifier other = this._other as DeclaredIdentifier;
    return isEqualNodes(node.documentationComment, other.documentationComment) && isEqualNodeLists(node.metadata, other.metadata) && isEqualTokens(node.keyword, other.keyword) && isEqualNodes(node.type, other.type) && isEqualNodes(node.identifier, other.identifier);
  }

  bool visitDefaultFormalParameter(DefaultFormalParameter node) {
    DefaultFormalParameter other = this._other as DefaultFormalParameter;
    return isEqualNodes(node.parameter, other.parameter) && identical(node.kind, other.kind) && isEqualTokens(node.separator, other.separator) && isEqualNodes(node.defaultValue, other.defaultValue);
  }

  bool visitDoStatement(DoStatement node) {
    DoStatement other = this._other as DoStatement;
    return isEqualTokens(node.doKeyword, other.doKeyword) && isEqualNodes(node.body, other.body) && isEqualTokens(node.whileKeyword, other.whileKeyword) && isEqualTokens(node.leftParenthesis, other.leftParenthesis) && isEqualNodes(node.condition, other.condition) && isEqualTokens(node.rightParenthesis, other.rightParenthesis) && isEqualTokens(node.semicolon, other.semicolon);
  }

  bool visitDoubleLiteral(DoubleLiteral node) {
    DoubleLiteral other = this._other as DoubleLiteral;
    return isEqualTokens(node.literal, other.literal) && node.value == other.value;
  }

  bool visitEmptyFunctionBody(EmptyFunctionBody node) {
    EmptyFunctionBody other = this._other as EmptyFunctionBody;
    return isEqualTokens(node.semicolon, other.semicolon);
  }

  bool visitEmptyStatement(EmptyStatement node) {
    EmptyStatement other = this._other as EmptyStatement;
    return isEqualTokens(node.semicolon, other.semicolon);
  }

  bool visitExportDirective(ExportDirective node) {
    ExportDirective other = this._other as ExportDirective;
    return isEqualNodes(node.documentationComment, other.documentationComment) && isEqualNodeLists(node.metadata, other.metadata) && isEqualTokens(node.keyword, other.keyword) && isEqualNodes(node.uri, other.uri) && isEqualNodeLists(node.combinators, other.combinators) && isEqualTokens(node.semicolon, other.semicolon);
  }

  bool visitExpressionFunctionBody(ExpressionFunctionBody node) {
    ExpressionFunctionBody other = this._other as ExpressionFunctionBody;
    return isEqualTokens(node.functionDefinition, other.functionDefinition) && isEqualNodes(node.expression, other.expression) && isEqualTokens(node.semicolon, other.semicolon);
  }

  bool visitExpressionStatement(ExpressionStatement node) {
    ExpressionStatement other = this._other as ExpressionStatement;
    return isEqualNodes(node.expression, other.expression) && isEqualTokens(node.semicolon, other.semicolon);
  }

  bool visitExtendsClause(ExtendsClause node) {
    ExtendsClause other = this._other as ExtendsClause;
    return isEqualTokens(node.keyword, other.keyword) && isEqualNodes(node.superclass, other.superclass);
  }

  bool visitFieldDeclaration(FieldDeclaration node) {
    FieldDeclaration other = this._other as FieldDeclaration;
    return isEqualNodes(node.documentationComment, other.documentationComment) && isEqualNodeLists(node.metadata, other.metadata) && isEqualTokens(node.staticKeyword, other.staticKeyword) && isEqualNodes(node.fields, other.fields) && isEqualTokens(node.semicolon, other.semicolon);
  }

  bool visitFieldFormalParameter(FieldFormalParameter node) {
    FieldFormalParameter other = this._other as FieldFormalParameter;
    return isEqualNodes(node.documentationComment, other.documentationComment) && isEqualNodeLists(node.metadata, other.metadata) && isEqualTokens(node.keyword, other.keyword) && isEqualNodes(node.type, other.type) && isEqualTokens(node.thisToken, other.thisToken) && isEqualTokens(node.period, other.period) && isEqualNodes(node.identifier, other.identifier);
  }

  bool visitForEachStatement(ForEachStatement node) {
    ForEachStatement other = this._other as ForEachStatement;
    return isEqualTokens(node.forKeyword, other.forKeyword) && isEqualTokens(node.leftParenthesis, other.leftParenthesis) && isEqualNodes(node.loopVariable, other.loopVariable) && isEqualTokens(node.inKeyword, other.inKeyword) && isEqualNodes(node.iterator, other.iterator) && isEqualTokens(node.rightParenthesis, other.rightParenthesis) && isEqualNodes(node.body, other.body);
  }

  bool visitFormalParameterList(FormalParameterList node) {
    FormalParameterList other = this._other as FormalParameterList;
    return isEqualTokens(node.leftParenthesis, other.leftParenthesis) && isEqualNodeLists(node.parameters, other.parameters) && isEqualTokens(node.leftDelimiter, other.leftDelimiter) && isEqualTokens(node.rightDelimiter, other.rightDelimiter) && isEqualTokens(node.rightParenthesis, other.rightParenthesis);
  }

  bool visitForStatement(ForStatement node) {
    ForStatement other = this._other as ForStatement;
    return isEqualTokens(node.forKeyword, other.forKeyword) && isEqualTokens(node.leftParenthesis, other.leftParenthesis) && isEqualNodes(node.variables, other.variables) && isEqualNodes(node.initialization, other.initialization) && isEqualTokens(node.leftSeparator, other.leftSeparator) && isEqualNodes(node.condition, other.condition) && isEqualTokens(node.rightSeparator, other.rightSeparator) && isEqualNodeLists(node.updaters, other.updaters) && isEqualTokens(node.rightParenthesis, other.rightParenthesis) && isEqualNodes(node.body, other.body);
  }

  bool visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionDeclaration other = this._other as FunctionDeclaration;
    return isEqualNodes(node.documentationComment, other.documentationComment) && isEqualNodeLists(node.metadata, other.metadata) && isEqualTokens(node.externalKeyword, other.externalKeyword) && isEqualNodes(node.returnType, other.returnType) && isEqualTokens(node.propertyKeyword, other.propertyKeyword) && isEqualNodes(node.name, other.name) && isEqualNodes(node.functionExpression, other.functionExpression);
  }

  bool visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    FunctionDeclarationStatement other = this._other as FunctionDeclarationStatement;
    return isEqualNodes(node.functionDeclaration, other.functionDeclaration);
  }

  bool visitFunctionExpression(FunctionExpression node) {
    FunctionExpression other = this._other as FunctionExpression;
    return isEqualNodes(node.parameters, other.parameters) && isEqualNodes(node.body, other.body);
  }

  bool visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    FunctionExpressionInvocation other = this._other as FunctionExpressionInvocation;
    return isEqualNodes(node.function, other.function) && isEqualNodes(node.argumentList, other.argumentList);
  }

  bool visitFunctionTypeAlias(FunctionTypeAlias node) {
    FunctionTypeAlias other = this._other as FunctionTypeAlias;
    return isEqualNodes(node.documentationComment, other.documentationComment) && isEqualNodeLists(node.metadata, other.metadata) && isEqualTokens(node.keyword, other.keyword) && isEqualNodes(node.returnType, other.returnType) && isEqualNodes(node.name, other.name) && isEqualNodes(node.typeParameters, other.typeParameters) && isEqualNodes(node.parameters, other.parameters) && isEqualTokens(node.semicolon, other.semicolon);
  }

  bool visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    FunctionTypedFormalParameter other = this._other as FunctionTypedFormalParameter;
    return isEqualNodes(node.documentationComment, other.documentationComment) && isEqualNodeLists(node.metadata, other.metadata) && isEqualNodes(node.returnType, other.returnType) && isEqualNodes(node.identifier, other.identifier) && isEqualNodes(node.parameters, other.parameters);
  }

  bool visitHideCombinator(HideCombinator node) {
    HideCombinator other = this._other as HideCombinator;
    return isEqualTokens(node.keyword, other.keyword) && isEqualNodeLists(node.hiddenNames, other.hiddenNames);
  }

  bool visitIfStatement(IfStatement node) {
    IfStatement other = this._other as IfStatement;
    return isEqualTokens(node.ifKeyword, other.ifKeyword) && isEqualTokens(node.leftParenthesis, other.leftParenthesis) && isEqualNodes(node.condition, other.condition) && isEqualTokens(node.rightParenthesis, other.rightParenthesis) && isEqualNodes(node.thenStatement, other.thenStatement) && isEqualTokens(node.elseKeyword, other.elseKeyword) && isEqualNodes(node.elseStatement, other.elseStatement);
  }

  bool visitImplementsClause(ImplementsClause node) {
    ImplementsClause other = this._other as ImplementsClause;
    return isEqualTokens(node.keyword, other.keyword) && isEqualNodeLists(node.interfaces, other.interfaces);
  }

  bool visitImportDirective(ImportDirective node) {
    ImportDirective other = this._other as ImportDirective;
    return isEqualNodes(node.documentationComment, other.documentationComment) && isEqualNodeLists(node.metadata, other.metadata) && isEqualTokens(node.keyword, other.keyword) && isEqualNodes(node.uri, other.uri) && isEqualTokens(node.asToken, other.asToken) && isEqualNodes(node.prefix, other.prefix) && isEqualNodeLists(node.combinators, other.combinators) && isEqualTokens(node.semicolon, other.semicolon);
  }

  bool visitIndexExpression(IndexExpression node) {
    IndexExpression other = this._other as IndexExpression;
    return isEqualNodes(node.target, other.target) && isEqualTokens(node.leftBracket, other.leftBracket) && isEqualNodes(node.index, other.index) && isEqualTokens(node.rightBracket, other.rightBracket);
  }

  bool visitInstanceCreationExpression(InstanceCreationExpression node) {
    InstanceCreationExpression other = this._other as InstanceCreationExpression;
    return isEqualTokens(node.keyword, other.keyword) && isEqualNodes(node.constructorName, other.constructorName) && isEqualNodes(node.argumentList, other.argumentList);
  }

  bool visitIntegerLiteral(IntegerLiteral node) {
    IntegerLiteral other = this._other as IntegerLiteral;
    return isEqualTokens(node.literal, other.literal) && (node.value == other.value);
  }

  bool visitInterpolationExpression(InterpolationExpression node) {
    InterpolationExpression other = this._other as InterpolationExpression;
    return isEqualTokens(node.leftBracket, other.leftBracket) && isEqualNodes(node.expression, other.expression) && isEqualTokens(node.rightBracket, other.rightBracket);
  }

  bool visitInterpolationString(InterpolationString node) {
    InterpolationString other = this._other as InterpolationString;
    return isEqualTokens(node.contents, other.contents) && node.value == other.value;
  }

  bool visitIsExpression(IsExpression node) {
    IsExpression other = this._other as IsExpression;
    return isEqualNodes(node.expression, other.expression) && isEqualTokens(node.isOperator, other.isOperator) && isEqualTokens(node.notOperator, other.notOperator) && isEqualNodes(node.type, other.type);
  }

  bool visitLabel(Label node) {
    Label other = this._other as Label;
    return isEqualNodes(node.label, other.label) && isEqualTokens(node.colon, other.colon);
  }

  bool visitLabeledStatement(LabeledStatement node) {
    LabeledStatement other = this._other as LabeledStatement;
    return isEqualNodeLists(node.labels, other.labels) && isEqualNodes(node.statement, other.statement);
  }

  bool visitLibraryDirective(LibraryDirective node) {
    LibraryDirective other = this._other as LibraryDirective;
    return isEqualNodes(node.documentationComment, other.documentationComment) && isEqualNodeLists(node.metadata, other.metadata) && isEqualTokens(node.libraryToken, other.libraryToken) && isEqualNodes(node.name, other.name) && isEqualTokens(node.semicolon, other.semicolon);
  }

  bool visitLibraryIdentifier(LibraryIdentifier node) {
    LibraryIdentifier other = this._other as LibraryIdentifier;
    return isEqualNodeLists(node.components, other.components);
  }

  bool visitListLiteral(ListLiteral node) {
    ListLiteral other = this._other as ListLiteral;
    return isEqualTokens(node.constKeyword, other.constKeyword) && isEqualNodes(node.typeArguments, other.typeArguments) && isEqualTokens(node.leftBracket, other.leftBracket) && isEqualNodeLists(node.elements, other.elements) && isEqualTokens(node.rightBracket, other.rightBracket);
  }

  bool visitMapLiteral(MapLiteral node) {
    MapLiteral other = this._other as MapLiteral;
    return isEqualTokens(node.constKeyword, other.constKeyword) && isEqualNodes(node.typeArguments, other.typeArguments) && isEqualTokens(node.leftBracket, other.leftBracket) && isEqualNodeLists(node.entries, other.entries) && isEqualTokens(node.rightBracket, other.rightBracket);
  }

  bool visitMapLiteralEntry(MapLiteralEntry node) {
    MapLiteralEntry other = this._other as MapLiteralEntry;
    return isEqualNodes(node.key, other.key) && isEqualTokens(node.separator, other.separator) && isEqualNodes(node.value, other.value);
  }

  bool visitMethodDeclaration(MethodDeclaration node) {
    MethodDeclaration other = this._other as MethodDeclaration;
    return isEqualNodes(node.documentationComment, other.documentationComment) && isEqualNodeLists(node.metadata, other.metadata) && isEqualTokens(node.externalKeyword, other.externalKeyword) && isEqualTokens(node.modifierKeyword, other.modifierKeyword) && isEqualNodes(node.returnType, other.returnType) && isEqualTokens(node.propertyKeyword, other.propertyKeyword) && isEqualTokens(node.propertyKeyword, other.propertyKeyword) && isEqualNodes(node.name, other.name) && isEqualNodes(node.parameters, other.parameters) && isEqualNodes(node.body, other.body);
  }

  bool visitMethodInvocation(MethodInvocation node) {
    MethodInvocation other = this._other as MethodInvocation;
    return isEqualNodes(node.target, other.target) && isEqualTokens(node.period, other.period) && isEqualNodes(node.methodName, other.methodName) && isEqualNodes(node.argumentList, other.argumentList);
  }

  bool visitNamedExpression(NamedExpression node) {
    NamedExpression other = this._other as NamedExpression;
    return isEqualNodes(node.name, other.name) && isEqualNodes(node.expression, other.expression);
  }

  bool visitNativeClause(NativeClause node) {
    NativeClause other = this._other as NativeClause;
    return isEqualTokens(node.keyword, other.keyword) && isEqualNodes(node.name, other.name);
  }

  bool visitNativeFunctionBody(NativeFunctionBody node) {
    NativeFunctionBody other = this._other as NativeFunctionBody;
    return isEqualTokens(node.nativeToken, other.nativeToken) && isEqualNodes(node.stringLiteral, other.stringLiteral) && isEqualTokens(node.semicolon, other.semicolon);
  }

  bool visitNullLiteral(NullLiteral node) {
    NullLiteral other = this._other as NullLiteral;
    return isEqualTokens(node.literal, other.literal);
  }

  bool visitParenthesizedExpression(ParenthesizedExpression node) {
    ParenthesizedExpression other = this._other as ParenthesizedExpression;
    return isEqualTokens(node.leftParenthesis, other.leftParenthesis) && isEqualNodes(node.expression, other.expression) && isEqualTokens(node.rightParenthesis, other.rightParenthesis);
  }

  bool visitPartDirective(PartDirective node) {
    PartDirective other = this._other as PartDirective;
    return isEqualNodes(node.documentationComment, other.documentationComment) && isEqualNodeLists(node.metadata, other.metadata) && isEqualTokens(node.partToken, other.partToken) && isEqualNodes(node.uri, other.uri) && isEqualTokens(node.semicolon, other.semicolon);
  }

  bool visitPartOfDirective(PartOfDirective node) {
    PartOfDirective other = this._other as PartOfDirective;
    return isEqualNodes(node.documentationComment, other.documentationComment) && isEqualNodeLists(node.metadata, other.metadata) && isEqualTokens(node.partToken, other.partToken) && isEqualTokens(node.ofToken, other.ofToken) && isEqualNodes(node.libraryName, other.libraryName) && isEqualTokens(node.semicolon, other.semicolon);
  }

  bool visitPostfixExpression(PostfixExpression node) {
    PostfixExpression other = this._other as PostfixExpression;
    return isEqualNodes(node.operand, other.operand) && isEqualTokens(node.operator, other.operator);
  }

  bool visitPrefixedIdentifier(PrefixedIdentifier node) {
    PrefixedIdentifier other = this._other as PrefixedIdentifier;
    return isEqualNodes(node.prefix, other.prefix) && isEqualTokens(node.period, other.period) && isEqualNodes(node.identifier, other.identifier);
  }

  bool visitPrefixExpression(PrefixExpression node) {
    PrefixExpression other = this._other as PrefixExpression;
    return isEqualTokens(node.operator, other.operator) && isEqualNodes(node.operand, other.operand);
  }

  bool visitPropertyAccess(PropertyAccess node) {
    PropertyAccess other = this._other as PropertyAccess;
    return isEqualNodes(node.target, other.target) && isEqualTokens(node.operator, other.operator) && isEqualNodes(node.propertyName, other.propertyName);
  }

  bool visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    RedirectingConstructorInvocation other = this._other as RedirectingConstructorInvocation;
    return isEqualTokens(node.keyword, other.keyword) && isEqualTokens(node.period, other.period) && isEqualNodes(node.constructorName, other.constructorName) && isEqualNodes(node.argumentList, other.argumentList);
  }

  bool visitRethrowExpression(RethrowExpression node) {
    RethrowExpression other = this._other as RethrowExpression;
    return isEqualTokens(node.keyword, other.keyword);
  }

  bool visitReturnStatement(ReturnStatement node) {
    ReturnStatement other = this._other as ReturnStatement;
    return isEqualTokens(node.keyword, other.keyword) && isEqualNodes(node.expression, other.expression) && isEqualTokens(node.semicolon, other.semicolon);
  }

  bool visitScriptTag(ScriptTag node) {
    ScriptTag other = this._other as ScriptTag;
    return isEqualTokens(node.scriptTag, other.scriptTag);
  }

  bool visitShowCombinator(ShowCombinator node) {
    ShowCombinator other = this._other as ShowCombinator;
    return isEqualTokens(node.keyword, other.keyword) && isEqualNodeLists(node.shownNames, other.shownNames);
  }

  bool visitSimpleFormalParameter(SimpleFormalParameter node) {
    SimpleFormalParameter other = this._other as SimpleFormalParameter;
    return isEqualNodes(node.documentationComment, other.documentationComment) && isEqualNodeLists(node.metadata, other.metadata) && isEqualTokens(node.keyword, other.keyword) && isEqualNodes(node.type, other.type) && isEqualNodes(node.identifier, other.identifier);
  }

  bool visitSimpleIdentifier(SimpleIdentifier node) {
    SimpleIdentifier other = this._other as SimpleIdentifier;
    return isEqualTokens(node.token, other.token);
  }

  bool visitSimpleStringLiteral(SimpleStringLiteral node) {
    SimpleStringLiteral other = this._other as SimpleStringLiteral;
    return isEqualTokens(node.literal, other.literal) && (node.value == other.value);
  }

  bool visitStringInterpolation(StringInterpolation node) {
    StringInterpolation other = this._other as StringInterpolation;
    return isEqualNodeLists(node.elements, other.elements);
  }

  bool visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    SuperConstructorInvocation other = this._other as SuperConstructorInvocation;
    return isEqualTokens(node.keyword, other.keyword) && isEqualTokens(node.period, other.period) && isEqualNodes(node.constructorName, other.constructorName) && isEqualNodes(node.argumentList, other.argumentList);
  }

  bool visitSuperExpression(SuperExpression node) {
    SuperExpression other = this._other as SuperExpression;
    return isEqualTokens(node.keyword, other.keyword);
  }

  bool visitSwitchCase(SwitchCase node) {
    SwitchCase other = this._other as SwitchCase;
    return isEqualNodeLists(node.labels, other.labels) && isEqualTokens(node.keyword, other.keyword) && isEqualNodes(node.expression, other.expression) && isEqualTokens(node.colon, other.colon) && isEqualNodeLists(node.statements, other.statements);
  }

  bool visitSwitchDefault(SwitchDefault node) {
    SwitchDefault other = this._other as SwitchDefault;
    return isEqualNodeLists(node.labels, other.labels) && isEqualTokens(node.keyword, other.keyword) && isEqualTokens(node.colon, other.colon) && isEqualNodeLists(node.statements, other.statements);
  }

  bool visitSwitchStatement(SwitchStatement node) {
    SwitchStatement other = this._other as SwitchStatement;
    return isEqualTokens(node.keyword, other.keyword) && isEqualTokens(node.leftParenthesis, other.leftParenthesis) && isEqualNodes(node.expression, other.expression) && isEqualTokens(node.rightParenthesis, other.rightParenthesis) && isEqualTokens(node.leftBracket, other.leftBracket) && isEqualNodeLists(node.members, other.members) && isEqualTokens(node.rightBracket, other.rightBracket);
  }

  bool visitSymbolLiteral(SymbolLiteral node) {
    SymbolLiteral other = this._other as SymbolLiteral;
    return isEqualTokens(node.poundSign, other.poundSign) && isEqualTokenLists(node.components, other.components);
  }

  bool visitThisExpression(ThisExpression node) {
    ThisExpression other = this._other as ThisExpression;
    return isEqualTokens(node.keyword, other.keyword);
  }

  bool visitThrowExpression(ThrowExpression node) {
    ThrowExpression other = this._other as ThrowExpression;
    return isEqualTokens(node.keyword, other.keyword) && isEqualNodes(node.expression, other.expression);
  }

  bool visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    TopLevelVariableDeclaration other = this._other as TopLevelVariableDeclaration;
    return isEqualNodes(node.documentationComment, other.documentationComment) && isEqualNodeLists(node.metadata, other.metadata) && isEqualNodes(node.variables, other.variables) && isEqualTokens(node.semicolon, other.semicolon);
  }

  bool visitTryStatement(TryStatement node) {
    TryStatement other = this._other as TryStatement;
    return isEqualTokens(node.tryKeyword, other.tryKeyword) && isEqualNodes(node.body, other.body) && isEqualNodeLists(node.catchClauses, other.catchClauses) && isEqualTokens(node.finallyKeyword, other.finallyKeyword) && isEqualNodes(node.finallyBlock, other.finallyBlock);
  }

  bool visitTypeArgumentList(TypeArgumentList node) {
    TypeArgumentList other = this._other as TypeArgumentList;
    return isEqualTokens(node.leftBracket, other.leftBracket) && isEqualNodeLists(node.arguments, other.arguments) && isEqualTokens(node.rightBracket, other.rightBracket);
  }

  bool visitTypeName(TypeName node) {
    TypeName other = this._other as TypeName;
    return isEqualNodes(node.name, other.name) && isEqualNodes(node.typeArguments, other.typeArguments);
  }

  bool visitTypeParameter(TypeParameter node) {
    TypeParameter other = this._other as TypeParameter;
    return isEqualNodes(node.documentationComment, other.documentationComment) && isEqualNodeLists(node.metadata, other.metadata) && isEqualNodes(node.name, other.name) && isEqualTokens(node.keyword, other.keyword) && isEqualNodes(node.bound, other.bound);
  }

  bool visitTypeParameterList(TypeParameterList node) {
    TypeParameterList other = this._other as TypeParameterList;
    return isEqualTokens(node.leftBracket, other.leftBracket) && isEqualNodeLists(node.typeParameters, other.typeParameters) && isEqualTokens(node.rightBracket, other.rightBracket);
  }

  bool visitVariableDeclaration(VariableDeclaration node) {
    VariableDeclaration other = this._other as VariableDeclaration;
    return isEqualNodes(node.documentationComment, other.documentationComment) && isEqualNodeLists(node.metadata, other.metadata) && isEqualNodes(node.name, other.name) && isEqualTokens(node.equals, other.equals) && isEqualNodes(node.initializer, other.initializer);
  }

  bool visitVariableDeclarationList(VariableDeclarationList node) {
    VariableDeclarationList other = this._other as VariableDeclarationList;
    return isEqualNodes(node.documentationComment, other.documentationComment) && isEqualNodeLists(node.metadata, other.metadata) && isEqualTokens(node.keyword, other.keyword) && isEqualNodes(node.type, other.type) && isEqualNodeLists(node.variables, other.variables);
  }

  bool visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    VariableDeclarationStatement other = this._other as VariableDeclarationStatement;
    return isEqualNodes(node.variables, other.variables) && isEqualTokens(node.semicolon, other.semicolon);
  }

  bool visitWhileStatement(WhileStatement node) {
    WhileStatement other = this._other as WhileStatement;
    return isEqualTokens(node.keyword, other.keyword) && isEqualTokens(node.leftParenthesis, other.leftParenthesis) && isEqualNodes(node.condition, other.condition) && isEqualTokens(node.rightParenthesis, other.rightParenthesis) && isEqualNodes(node.body, other.body);
  }

  bool visitWithClause(WithClause node) {
    WithClause other = this._other as WithClause;
    return isEqualTokens(node.withKeyword, other.withKeyword) && isEqualNodeLists(node.mixinTypes, other.mixinTypes);
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
    for (int i = 0; i < size; i++) {
      if (!isEqualNodes(first[i], second[i])) {
        return false;
      }
    }
    return true;
  }

  /**
   * Return `true` if the given AST nodes have the same structure.
   *
   * @param first the first node being compared
   * @param second the second node being compared
   * @return `true` if the given AST nodes have the same structure
   */
  bool isEqualNodes(AstNode first, AstNode second) {
    if (first == null) {
      return second == null;
    } else if (second == null) {
      return false;
    } else if (first.runtimeType != second.runtimeType) {
      return false;
    }
    _other = second;
    return first.accept(this);
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
      if (isEqualTokens(first[i], second[i])) {
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
    return first.offset == second.offset && first.length == second.length && first.lexeme == second.lexeme;
  }
}

/**
 * Instances of the class `IncrementalAstCloner` implement an object that will clone any AST
 * structure that it visits. The cloner will clone the structure, replacing the specified ASTNode
 * with a new ASTNode, mapping the old token stream to a new token stream, and preserving resolution
 * results.
 */
class IncrementalAstCloner implements AstVisitor<AstNode> {
  /**
   * The node to be replaced during the cloning process.
   */
  AstNode _oldNode;

  /**
   * The replacement node used during the cloning process.
   */
  AstNode _newNode;

  /**
   * A mapping of old tokens to new tokens used during the cloning process.
   */
  TokenMap _tokenMap;

  /**
   * Construct a new instance that will replace `oldNode` with `newNode` in the process
   * of cloning an existing AST structure.
   *
   * @param oldNode the node to be replaced
   * @param newNode the replacement node
   * @param tokenMap a mapping of old tokens to new tokens (not `null`)
   */
  IncrementalAstCloner(AstNode oldNode, AstNode newNode, TokenMap tokenMap) {
    this._oldNode = oldNode;
    this._newNode = newNode;
    this._tokenMap = tokenMap;
  }

  AdjacentStrings visitAdjacentStrings(AdjacentStrings node) => new AdjacentStrings(cloneNodeList(node.strings));

  Annotation visitAnnotation(Annotation node) {
    Annotation copy = new Annotation(mapToken(node.atSign), cloneNode(node.name), mapToken(node.period), cloneNode(node.constructorName), cloneNode(node.arguments));
    copy.element = node.element;
    return copy;
  }

  ArgumentDefinitionTest visitArgumentDefinitionTest(ArgumentDefinitionTest node) {
    ArgumentDefinitionTest copy = new ArgumentDefinitionTest(mapToken(node.question), cloneNode(node.identifier));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  ArgumentList visitArgumentList(ArgumentList node) => new ArgumentList(mapToken(node.leftParenthesis), cloneNodeList(node.arguments), mapToken(node.rightParenthesis));

  AsExpression visitAsExpression(AsExpression node) {
    AsExpression copy = new AsExpression(cloneNode(node.expression), mapToken(node.asOperator), cloneNode(node.type));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  AstNode visitAssertStatement(AssertStatement node) => new AssertStatement(mapToken(node.keyword), mapToken(node.leftParenthesis), cloneNode(node.condition), mapToken(node.rightParenthesis), mapToken(node.semicolon));

  AssignmentExpression visitAssignmentExpression(AssignmentExpression node) {
    AssignmentExpression copy = new AssignmentExpression(cloneNode(node.leftHandSide), mapToken(node.operator), cloneNode(node.rightHandSide));
    copy.propagatedElement = node.propagatedElement;
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  BinaryExpression visitBinaryExpression(BinaryExpression node) {
    BinaryExpression copy = new BinaryExpression(cloneNode(node.leftOperand), mapToken(node.operator), cloneNode(node.rightOperand));
    copy.propagatedElement = node.propagatedElement;
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  Block visitBlock(Block node) => new Block(mapToken(node.leftBracket), cloneNodeList(node.statements), mapToken(node.rightBracket));

  BlockFunctionBody visitBlockFunctionBody(BlockFunctionBody node) => new BlockFunctionBody(cloneNode(node.block));

  BooleanLiteral visitBooleanLiteral(BooleanLiteral node) {
    BooleanLiteral copy = new BooleanLiteral(mapToken(node.literal), node.value);
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  BreakStatement visitBreakStatement(BreakStatement node) => new BreakStatement(mapToken(node.keyword), cloneNode(node.label), mapToken(node.semicolon));

  CascadeExpression visitCascadeExpression(CascadeExpression node) {
    CascadeExpression copy = new CascadeExpression(cloneNode(node.target), cloneNodeList(node.cascadeSections));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  CatchClause visitCatchClause(CatchClause node) => new CatchClause(mapToken(node.onKeyword), cloneNode(node.exceptionType), mapToken(node.catchKeyword), mapToken(node.leftParenthesis), cloneNode(node.exceptionParameter), mapToken(node.comma), cloneNode(node.stackTraceParameter), mapToken(node.rightParenthesis), cloneNode(node.body));

  ClassDeclaration visitClassDeclaration(ClassDeclaration node) {
    ClassDeclaration copy = new ClassDeclaration(cloneNode(node.documentationComment), cloneNodeList(node.metadata), mapToken(node.abstractKeyword), mapToken(node.classKeyword), cloneNode(node.name), cloneNode(node.typeParameters), cloneNode(node.extendsClause), cloneNode(node.withClause), cloneNode(node.implementsClause), mapToken(node.leftBracket), cloneNodeList(node.members), mapToken(node.rightBracket));
    copy.nativeClause = cloneNode(node.nativeClause);
    return copy;
  }

  ClassTypeAlias visitClassTypeAlias(ClassTypeAlias node) => new ClassTypeAlias(cloneNode(node.documentationComment), cloneNodeList(node.metadata), mapToken(node.keyword), cloneNode(node.name), cloneNode(node.typeParameters), mapToken(node.equals), mapToken(node.abstractKeyword), cloneNode(node.superclass), cloneNode(node.withClause), cloneNode(node.implementsClause), mapToken(node.semicolon));

  Comment visitComment(Comment node) {
    if (node.isDocumentation) {
      return Comment.createDocumentationComment2(mapTokens(node.tokens), cloneNodeList(node.references));
    } else if (node.isBlock) {
      return Comment.createBlockComment(mapTokens(node.tokens));
    }
    return Comment.createEndOfLineComment(mapTokens(node.tokens));
  }

  CommentReference visitCommentReference(CommentReference node) => new CommentReference(mapToken(node.newKeyword), cloneNode(node.identifier));

  CompilationUnit visitCompilationUnit(CompilationUnit node) {
    CompilationUnit copy = new CompilationUnit(mapToken(node.beginToken), cloneNode(node.scriptTag), cloneNodeList(node.directives), cloneNodeList(node.declarations), mapToken(node.endToken));
    copy.lineInfo = node.lineInfo;
    copy.element = node.element;
    return copy;
  }

  ConditionalExpression visitConditionalExpression(ConditionalExpression node) {
    ConditionalExpression copy = new ConditionalExpression(cloneNode(node.condition), mapToken(node.question), cloneNode(node.thenExpression), mapToken(node.colon), cloneNode(node.elseExpression));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  ConstructorDeclaration visitConstructorDeclaration(ConstructorDeclaration node) {
    ConstructorDeclaration copy = new ConstructorDeclaration(cloneNode(node.documentationComment), cloneNodeList(node.metadata), mapToken(node.externalKeyword), mapToken(node.constKeyword), mapToken(node.factoryKeyword), cloneNode(node.returnType), mapToken(node.period), cloneNode(node.name), cloneNode(node.parameters), mapToken(node.separator), cloneNodeList(node.initializers), cloneNode(node.redirectedConstructor), cloneNode(node.body));
    copy.element = node.element;
    return copy;
  }

  ConstructorFieldInitializer visitConstructorFieldInitializer(ConstructorFieldInitializer node) => new ConstructorFieldInitializer(mapToken(node.keyword), mapToken(node.period), cloneNode(node.fieldName), mapToken(node.equals), cloneNode(node.expression));

  ConstructorName visitConstructorName(ConstructorName node) {
    ConstructorName copy = new ConstructorName(cloneNode(node.type), mapToken(node.period), cloneNode(node.name));
    copy.staticElement = node.staticElement;
    return copy;
  }

  ContinueStatement visitContinueStatement(ContinueStatement node) => new ContinueStatement(mapToken(node.keyword), cloneNode(node.label), mapToken(node.semicolon));

  DeclaredIdentifier visitDeclaredIdentifier(DeclaredIdentifier node) => new DeclaredIdentifier(cloneNode(node.documentationComment), cloneNodeList(node.metadata), mapToken(node.keyword), cloneNode(node.type), cloneNode(node.identifier));

  DefaultFormalParameter visitDefaultFormalParameter(DefaultFormalParameter node) => new DefaultFormalParameter(cloneNode(node.parameter), node.kind, mapToken(node.separator), cloneNode(node.defaultValue));

  DoStatement visitDoStatement(DoStatement node) => new DoStatement(mapToken(node.doKeyword), cloneNode(node.body), mapToken(node.whileKeyword), mapToken(node.leftParenthesis), cloneNode(node.condition), mapToken(node.rightParenthesis), mapToken(node.semicolon));

  DoubleLiteral visitDoubleLiteral(DoubleLiteral node) {
    DoubleLiteral copy = new DoubleLiteral(mapToken(node.literal), node.value);
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  EmptyFunctionBody visitEmptyFunctionBody(EmptyFunctionBody node) => new EmptyFunctionBody(mapToken(node.semicolon));

  EmptyStatement visitEmptyStatement(EmptyStatement node) => new EmptyStatement(mapToken(node.semicolon));

  ExportDirective visitExportDirective(ExportDirective node) {
    ExportDirective copy = new ExportDirective(cloneNode(node.documentationComment), cloneNodeList(node.metadata), mapToken(node.keyword), cloneNode(node.uri), cloneNodeList(node.combinators), mapToken(node.semicolon));
    copy.element = node.element;
    return copy;
  }

  ExpressionFunctionBody visitExpressionFunctionBody(ExpressionFunctionBody node) => new ExpressionFunctionBody(mapToken(node.functionDefinition), cloneNode(node.expression), mapToken(node.semicolon));

  ExpressionStatement visitExpressionStatement(ExpressionStatement node) => new ExpressionStatement(cloneNode(node.expression), mapToken(node.semicolon));

  ExtendsClause visitExtendsClause(ExtendsClause node) => new ExtendsClause(mapToken(node.keyword), cloneNode(node.superclass));

  FieldDeclaration visitFieldDeclaration(FieldDeclaration node) => new FieldDeclaration(cloneNode(node.documentationComment), cloneNodeList(node.metadata), mapToken(node.staticKeyword), cloneNode(node.fields), mapToken(node.semicolon));

  FieldFormalParameter visitFieldFormalParameter(FieldFormalParameter node) => new FieldFormalParameter(cloneNode(node.documentationComment), cloneNodeList(node.metadata), mapToken(node.keyword), cloneNode(node.type), mapToken(node.thisToken), mapToken(node.period), cloneNode(node.identifier), cloneNode(node.parameters));

  ForEachStatement visitForEachStatement(ForEachStatement node) {
    DeclaredIdentifier loopVariable = node.loopVariable;
    if (loopVariable == null) {
      return new ForEachStatement.con2(mapToken(node.forKeyword), mapToken(node.leftParenthesis), cloneNode(node.identifier), mapToken(node.inKeyword), cloneNode(node.iterator), mapToken(node.rightParenthesis), cloneNode(node.body));
    }
    return new ForEachStatement.con1(mapToken(node.forKeyword), mapToken(node.leftParenthesis), cloneNode(loopVariable), mapToken(node.inKeyword), cloneNode(node.iterator), mapToken(node.rightParenthesis), cloneNode(node.body));
  }

  FormalParameterList visitFormalParameterList(FormalParameterList node) => new FormalParameterList(mapToken(node.leftParenthesis), cloneNodeList(node.parameters), mapToken(node.leftDelimiter), mapToken(node.rightDelimiter), mapToken(node.rightParenthesis));

  ForStatement visitForStatement(ForStatement node) => new ForStatement(mapToken(node.forKeyword), mapToken(node.leftParenthesis), cloneNode(node.variables), cloneNode(node.initialization), mapToken(node.leftSeparator), cloneNode(node.condition), mapToken(node.rightSeparator), cloneNodeList(node.updaters), mapToken(node.rightParenthesis), cloneNode(node.body));

  FunctionDeclaration visitFunctionDeclaration(FunctionDeclaration node) => new FunctionDeclaration(cloneNode(node.documentationComment), cloneNodeList(node.metadata), mapToken(node.externalKeyword), cloneNode(node.returnType), mapToken(node.propertyKeyword), cloneNode(node.name), cloneNode(node.functionExpression));

  FunctionDeclarationStatement visitFunctionDeclarationStatement(FunctionDeclarationStatement node) => new FunctionDeclarationStatement(cloneNode(node.functionDeclaration));

  FunctionExpression visitFunctionExpression(FunctionExpression node) {
    FunctionExpression copy = new FunctionExpression(cloneNode(node.parameters), cloneNode(node.body));
    copy.element = node.element;
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  FunctionExpressionInvocation visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    FunctionExpressionInvocation copy = new FunctionExpressionInvocation(cloneNode(node.function), cloneNode(node.argumentList));
    copy.propagatedElement = node.propagatedElement;
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  FunctionTypeAlias visitFunctionTypeAlias(FunctionTypeAlias node) => new FunctionTypeAlias(cloneNode(node.documentationComment), cloneNodeList(node.metadata), mapToken(node.keyword), cloneNode(node.returnType), cloneNode(node.name), cloneNode(node.typeParameters), cloneNode(node.parameters), mapToken(node.semicolon));

  FunctionTypedFormalParameter visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) => new FunctionTypedFormalParameter(cloneNode(node.documentationComment), cloneNodeList(node.metadata), cloneNode(node.returnType), cloneNode(node.identifier), cloneNode(node.parameters));

  HideCombinator visitHideCombinator(HideCombinator node) => new HideCombinator(mapToken(node.keyword), cloneNodeList(node.hiddenNames));

  IfStatement visitIfStatement(IfStatement node) => new IfStatement(mapToken(node.ifKeyword), mapToken(node.leftParenthesis), cloneNode(node.condition), mapToken(node.rightParenthesis), cloneNode(node.thenStatement), mapToken(node.elseKeyword), cloneNode(node.elseStatement));

  ImplementsClause visitImplementsClause(ImplementsClause node) => new ImplementsClause(mapToken(node.keyword), cloneNodeList(node.interfaces));

  ImportDirective visitImportDirective(ImportDirective node) => new ImportDirective(cloneNode(node.documentationComment), cloneNodeList(node.metadata), mapToken(node.keyword), cloneNode(node.uri), mapToken(node.asToken), cloneNode(node.prefix), cloneNodeList(node.combinators), mapToken(node.semicolon));

  IndexExpression visitIndexExpression(IndexExpression node) {
    Token period = mapToken(node.period);
    IndexExpression copy;
    if (period == null) {
      copy = new IndexExpression.forTarget(cloneNode(node.target), mapToken(node.leftBracket), cloneNode(node.index), mapToken(node.rightBracket));
    } else {
      copy = new IndexExpression.forCascade(period, mapToken(node.leftBracket), cloneNode(node.index), mapToken(node.rightBracket));
    }
    copy.auxiliaryElements = node.auxiliaryElements;
    copy.propagatedElement = node.propagatedElement;
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  InstanceCreationExpression visitInstanceCreationExpression(InstanceCreationExpression node) {
    InstanceCreationExpression copy = new InstanceCreationExpression(mapToken(node.keyword), cloneNode(node.constructorName), cloneNode(node.argumentList));
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  IntegerLiteral visitIntegerLiteral(IntegerLiteral node) {
    IntegerLiteral copy = new IntegerLiteral(mapToken(node.literal), node.value);
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  InterpolationExpression visitInterpolationExpression(InterpolationExpression node) => new InterpolationExpression(mapToken(node.leftBracket), cloneNode(node.expression), mapToken(node.rightBracket));

  InterpolationString visitInterpolationString(InterpolationString node) => new InterpolationString(mapToken(node.contents), node.value);

  IsExpression visitIsExpression(IsExpression node) {
    IsExpression copy = new IsExpression(cloneNode(node.expression), mapToken(node.isOperator), mapToken(node.notOperator), cloneNode(node.type));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  Label visitLabel(Label node) => new Label(cloneNode(node.label), mapToken(node.colon));

  LabeledStatement visitLabeledStatement(LabeledStatement node) => new LabeledStatement(cloneNodeList(node.labels), cloneNode(node.statement));

  LibraryDirective visitLibraryDirective(LibraryDirective node) => new LibraryDirective(cloneNode(node.documentationComment), cloneNodeList(node.metadata), mapToken(node.libraryToken), cloneNode(node.name), mapToken(node.semicolon));

  LibraryIdentifier visitLibraryIdentifier(LibraryIdentifier node) {
    LibraryIdentifier copy = new LibraryIdentifier(cloneNodeList(node.components));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  ListLiteral visitListLiteral(ListLiteral node) {
    ListLiteral copy = new ListLiteral(mapToken(node.constKeyword), cloneNode(node.typeArguments), mapToken(node.leftBracket), cloneNodeList(node.elements), mapToken(node.rightBracket));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  MapLiteral visitMapLiteral(MapLiteral node) {
    MapLiteral copy = new MapLiteral(mapToken(node.constKeyword), cloneNode(node.typeArguments), mapToken(node.leftBracket), cloneNodeList(node.entries), mapToken(node.rightBracket));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  MapLiteralEntry visitMapLiteralEntry(MapLiteralEntry node) => new MapLiteralEntry(cloneNode(node.key), mapToken(node.separator), cloneNode(node.value));

  MethodDeclaration visitMethodDeclaration(MethodDeclaration node) => new MethodDeclaration(cloneNode(node.documentationComment), cloneNodeList(node.metadata), mapToken(node.externalKeyword), mapToken(node.modifierKeyword), cloneNode(node.returnType), mapToken(node.propertyKeyword), mapToken(node.operatorKeyword), cloneNode(node.name), cloneNode(node.parameters), cloneNode(node.body));

  MethodInvocation visitMethodInvocation(MethodInvocation node) {
    MethodInvocation copy = new MethodInvocation(cloneNode(node.target), mapToken(node.period), cloneNode(node.methodName), cloneNode(node.argumentList));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  NamedExpression visitNamedExpression(NamedExpression node) {
    NamedExpression copy = new NamedExpression(cloneNode(node.name), cloneNode(node.expression));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  AstNode visitNativeClause(NativeClause node) => new NativeClause(mapToken(node.keyword), cloneNode(node.name));

  NativeFunctionBody visitNativeFunctionBody(NativeFunctionBody node) => new NativeFunctionBody(mapToken(node.nativeToken), cloneNode(node.stringLiteral), mapToken(node.semicolon));

  NullLiteral visitNullLiteral(NullLiteral node) {
    NullLiteral copy = new NullLiteral(mapToken(node.literal));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  ParenthesizedExpression visitParenthesizedExpression(ParenthesizedExpression node) {
    ParenthesizedExpression copy = new ParenthesizedExpression(mapToken(node.leftParenthesis), cloneNode(node.expression), mapToken(node.rightParenthesis));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  PartDirective visitPartDirective(PartDirective node) {
    PartDirective copy = new PartDirective(cloneNode(node.documentationComment), cloneNodeList(node.metadata), mapToken(node.partToken), cloneNode(node.uri), mapToken(node.semicolon));
    copy.element = node.element;
    return copy;
  }

  PartOfDirective visitPartOfDirective(PartOfDirective node) {
    PartOfDirective copy = new PartOfDirective(cloneNode(node.documentationComment), cloneNodeList(node.metadata), mapToken(node.partToken), mapToken(node.ofToken), cloneNode(node.libraryName), mapToken(node.semicolon));
    copy.element = node.element;
    return copy;
  }

  PostfixExpression visitPostfixExpression(PostfixExpression node) {
    PostfixExpression copy = new PostfixExpression(cloneNode(node.operand), mapToken(node.operator));
    copy.propagatedElement = node.propagatedElement;
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  PrefixedIdentifier visitPrefixedIdentifier(PrefixedIdentifier node) {
    PrefixedIdentifier copy = new PrefixedIdentifier(cloneNode(node.prefix), mapToken(node.period), cloneNode(node.identifier));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  PrefixExpression visitPrefixExpression(PrefixExpression node) {
    PrefixExpression copy = new PrefixExpression(mapToken(node.operator), cloneNode(node.operand));
    copy.propagatedElement = node.propagatedElement;
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  PropertyAccess visitPropertyAccess(PropertyAccess node) {
    PropertyAccess copy = new PropertyAccess(cloneNode(node.target), mapToken(node.operator), cloneNode(node.propertyName));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  RedirectingConstructorInvocation visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    RedirectingConstructorInvocation copy = new RedirectingConstructorInvocation(mapToken(node.keyword), mapToken(node.period), cloneNode(node.constructorName), cloneNode(node.argumentList));
    copy.staticElement = node.staticElement;
    return copy;
  }

  RethrowExpression visitRethrowExpression(RethrowExpression node) {
    RethrowExpression copy = new RethrowExpression(mapToken(node.keyword));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  ReturnStatement visitReturnStatement(ReturnStatement node) => new ReturnStatement(mapToken(node.keyword), cloneNode(node.expression), mapToken(node.semicolon));

  ScriptTag visitScriptTag(ScriptTag node) => new ScriptTag(mapToken(node.scriptTag));

  ShowCombinator visitShowCombinator(ShowCombinator node) => new ShowCombinator(mapToken(node.keyword), cloneNodeList(node.shownNames));

  SimpleFormalParameter visitSimpleFormalParameter(SimpleFormalParameter node) => new SimpleFormalParameter(cloneNode(node.documentationComment), cloneNodeList(node.metadata), mapToken(node.keyword), cloneNode(node.type), cloneNode(node.identifier));

  SimpleIdentifier visitSimpleIdentifier(SimpleIdentifier node) {
    Token mappedToken = mapToken(node.token);
    if (mappedToken == null) {
      // This only happens for SimpleIdentifiers created by the parser as part of scanning
      // documentation comments (the tokens for those identifiers are not in the original token
      // stream and hence do not get copied). This extra check can be removed if the scanner is
      // changed to scan documentation comments for the parser.
      mappedToken = node.token;
    }
    SimpleIdentifier copy = new SimpleIdentifier(mappedToken);
    copy.auxiliaryElements = node.auxiliaryElements;
    copy.propagatedElement = node.propagatedElement;
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  SimpleStringLiteral visitSimpleStringLiteral(SimpleStringLiteral node) {
    SimpleStringLiteral copy = new SimpleStringLiteral(mapToken(node.literal), node.value);
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  StringInterpolation visitStringInterpolation(StringInterpolation node) {
    StringInterpolation copy = new StringInterpolation(cloneNodeList(node.elements));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  SuperConstructorInvocation visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    SuperConstructorInvocation copy = new SuperConstructorInvocation(mapToken(node.keyword), mapToken(node.period), cloneNode(node.constructorName), cloneNode(node.argumentList));
    copy.staticElement = node.staticElement;
    return copy;
  }

  SuperExpression visitSuperExpression(SuperExpression node) {
    SuperExpression copy = new SuperExpression(mapToken(node.keyword));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  SwitchCase visitSwitchCase(SwitchCase node) => new SwitchCase(cloneNodeList(node.labels), mapToken(node.keyword), cloneNode(node.expression), mapToken(node.colon), cloneNodeList(node.statements));

  SwitchDefault visitSwitchDefault(SwitchDefault node) => new SwitchDefault(cloneNodeList(node.labels), mapToken(node.keyword), mapToken(node.colon), cloneNodeList(node.statements));

  SwitchStatement visitSwitchStatement(SwitchStatement node) => new SwitchStatement(mapToken(node.keyword), mapToken(node.leftParenthesis), cloneNode(node.expression), mapToken(node.rightParenthesis), mapToken(node.leftBracket), cloneNodeList(node.members), mapToken(node.rightBracket));

  AstNode visitSymbolLiteral(SymbolLiteral node) {
    SymbolLiteral copy = new SymbolLiteral(mapToken(node.poundSign), mapTokens(node.components));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  ThisExpression visitThisExpression(ThisExpression node) {
    ThisExpression copy = new ThisExpression(mapToken(node.keyword));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  ThrowExpression visitThrowExpression(ThrowExpression node) {
    ThrowExpression copy = new ThrowExpression(mapToken(node.keyword), cloneNode(node.expression));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  TopLevelVariableDeclaration visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) => new TopLevelVariableDeclaration(cloneNode(node.documentationComment), cloneNodeList(node.metadata), cloneNode(node.variables), mapToken(node.semicolon));

  TryStatement visitTryStatement(TryStatement node) => new TryStatement(mapToken(node.tryKeyword), cloneNode(node.body), cloneNodeList(node.catchClauses), mapToken(node.finallyKeyword), cloneNode(node.finallyBlock));

  TypeArgumentList visitTypeArgumentList(TypeArgumentList node) => new TypeArgumentList(mapToken(node.leftBracket), cloneNodeList(node.arguments), mapToken(node.rightBracket));

  TypeName visitTypeName(TypeName node) {
    TypeName copy = new TypeName(cloneNode(node.name), cloneNode(node.typeArguments));
    copy.type = node.type;
    return copy;
  }

  TypeParameter visitTypeParameter(TypeParameter node) => new TypeParameter(cloneNode(node.documentationComment), cloneNodeList(node.metadata), cloneNode(node.name), mapToken(node.keyword), cloneNode(node.bound));

  TypeParameterList visitTypeParameterList(TypeParameterList node) => new TypeParameterList(mapToken(node.leftBracket), cloneNodeList(node.typeParameters), mapToken(node.rightBracket));

  VariableDeclaration visitVariableDeclaration(VariableDeclaration node) => new VariableDeclaration(null, cloneNodeList(node.metadata), cloneNode(node.name), mapToken(node.equals), cloneNode(node.initializer));

  VariableDeclarationList visitVariableDeclarationList(VariableDeclarationList node) => new VariableDeclarationList(null, cloneNodeList(node.metadata), mapToken(node.keyword), cloneNode(node.type), cloneNodeList(node.variables));

  VariableDeclarationStatement visitVariableDeclarationStatement(VariableDeclarationStatement node) => new VariableDeclarationStatement(cloneNode(node.variables), mapToken(node.semicolon));

  WhileStatement visitWhileStatement(WhileStatement node) => new WhileStatement(mapToken(node.keyword), mapToken(node.leftParenthesis), cloneNode(node.condition), mapToken(node.rightParenthesis), cloneNode(node.body));

  WithClause visitWithClause(WithClause node) => new WithClause(mapToken(node.withKeyword), cloneNodeList(node.mixinTypes));

  AstNode cloneNode(AstNode node) {
    if (node == null) {
      return null;
    }
    if (identical(node, _oldNode)) {
      return _newNode;
    }
    return node.accept(this) as AstNode;
  }

  List cloneNodeList(NodeList nodes) {
    List clonedNodes = new List();
    for (AstNode node in nodes) {
      clonedNodes.add(cloneNode(node));
    }
    return clonedNodes;
  }

  Token mapToken(Token oldToken) {
    if (oldToken == null) {
      return null;
    }
    return _tokenMap.get(oldToken);
  }

  List<Token> mapTokens(List<Token> oldTokens) {
    List<Token> newTokens = new List<Token>(oldTokens.length);
    for (int index = 0; index < newTokens.length; index++) {
      newTokens[index] = mapToken(oldTokens[index]);
    }
    return newTokens;
  }
}

/**
 * Traverse the AST from initial child node to successive parents, building a collection of local
 * variable and parameter names visible to the initial child node. In case of name shadowing, the
 * first name seen is the most specific one so names are not redefined.
 *
 * Completion test code coverage is 95%. The two basic blocks that are not executed cannot be
 * executed. They are included for future reference.
 */
class ScopedNameFinder extends GeneralizingAstVisitor<Object> {
  Declaration _declarationNode;

  AstNode _immediateChild;

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
    DeclaredIdentifier loopVariable = node.loopVariable;
    if (loopVariable != null) {
      addToScope(loopVariable.identifier);
    }
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
    if (node.parameters != null && _immediateChild != node.parameters) {
      addParameters(node.parameters.parameters);
    }
    return super.visitFunctionExpression(node);
  }

  Object visitMethodDeclaration(MethodDeclaration node) {
    _declarationNode = node;
    if (node.parameters == null) {
      return null;
    }
    if (_immediateChild != node.parameters) {
      addParameters(node.parameters.parameters);
    }
    return null;
  }

  Object visitNode(AstNode node) {
    _immediateChild = node;
    AstNode parent = node.parent;
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
   *
   * @param statements the list of statements to check for name definitions
   */
  void checkStatements(List<Statement> statements) {
    for (Statement stmt in statements) {
      if (identical(stmt, _immediateChild)) {
        return;
      }
      if (stmt is VariableDeclarationStatement) {
        addVariables(stmt.variables.variables);
      } else if (stmt is FunctionDeclarationStatement && !_referenceIsWithinLocalFunction) {
        addToScope(stmt.functionDeclaration.name);
      }
    }
  }

  bool isInRange(AstNode node) {
    if (_position < 0) {
      // if source position is not set then all nodes are in range
      return true;
    }
    return node.end < _position;
  }
}
/**
 * Instances of the class {@code NodeList} represent a list of AST nodes that have a common parent.
 */
class NodeList<E extends AstNode> extends Object with ListMixin<E> {
  /**
   * Create an empty list with the given owner. This is a convenience method that allows the
   * compiler to determine the correct value of the type argument [E] without needing to
   * explicitly specify it.
   *
   * @param owner the node that is the parent of each of the elements in the list
   * @return the list that was created
   */
  static NodeList create(AstNode owner) => new NodeList(owner);

  /**
   * The node that is the parent of each of the elements in the list.
   */
  AstNode owner;

  /**
   * The elements contained in the list.
   */
  List<E> _elements = <E> [];

  /**
   * Initialize a newly created list of nodes to be empty.
   *
   * @param owner the node that is the parent of each of the elements in the list
   */
  NodeList(this.owner);

  /**
   * Use the given visitor to visit each of the nodes in this list.
   *
   * @param visitor the visitor to be used to visit the elements of this list
   */
  accept(AstVisitor visitor) {
    var length = _elements.length;
    for (var i = 0; i < length; i++) {
      _elements[i].accept(visitor);
    }
  }
  void add(E node) {
    insert(length, node);
  }
  void insert(int index, E node) {
    int length = _elements.length;
    if (index < 0 || index > length) {
      throw new RangeError("Index: ${index}, Size: ${_elements.length}");
    }
    owner.becomeParentOf(node);
    if (length == 0) {
      _elements = <E> [node];
    } else {
      _elements.insert(index, node);
    }
  }
  bool addAll(Iterable<E> nodes) {
    if (nodes != null && !nodes.isEmpty) {
      _elements.addAll(nodes);
      for (E node in nodes) {
        owner.becomeParentOf(node);
      }
      return true;
    }
    return false;
  }
  E operator[](int index) {
    if (index < 0 || index >= _elements.length) {
      throw new RangeError("Index: ${index}, Size: ${_elements.length}");
    }
    return _elements[index] as E;
  }

  /**
   * Return the first token included in this node's source range.
   *
   * @return the first token included in this node's source range
   */
  Token get beginToken {
    if (_elements.length == 0) {
      return null;
    }
    return _elements[0].beginToken;
  }

  /**
   * Return the last token included in this node list's source range.
   *
   * @return the last token included in this node list's source range
   */
  Token get endToken {
    if (_elements.length == 0) {
      return null;
    }
    return _elements[_elements.length - 1].endToken;
  }
  E removeAt(int index) {
    if (index < 0 || index >= _elements.length) {
      throw new RangeError("Index: ${index}, Size: ${_elements.length}");
    }
    E removedNode = _elements[index] as E;
    int length = _elements.length;
    if (length == 1) {
      _elements = AstNode.EMPTY_ARRAY;
      return removedNode;
    }
    _elements.removeAt(index);
    return removedNode;
  }
  void operator[]=(int index, E node) {
    if (index < 0 || index >= _elements.length) {
      throw new RangeError("Index: ${index}, Size: ${_elements.length}");
    }
    owner.becomeParentOf(node);
    _elements[index] = node;
  }
  int get length => _elements.length;
  void set length(int value) {
    throw new UnsupportedError("Cannot resize NodeList.");
  }
}
