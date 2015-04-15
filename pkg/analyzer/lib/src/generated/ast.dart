// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.ast;

import 'dart:collection';

import 'constant.dart';
import 'element.dart';
import 'engine.dart' show AnalysisEngine;
import 'java_core.dart';
import 'java_engine.dart';
import 'parser.dart';
import 'scanner.dart';
import 'source.dart' show LineInfo, Source;
import 'utilities_collection.dart' show TokenMap;
import 'utilities_dart.dart';

/**
 * Two or more string literals that are implicitly concatenated because of being
 * adjacent (separated only by whitespace).
 *
 * While the grammar only allows adjacent strings when all of the strings are of
 * the same kind (single line or multi-line), this class doesn't enforce that
 * restriction.
 *
 * > adjacentStrings ::=
 * >     [StringLiteral] [StringLiteral]+
 */
class AdjacentStrings extends StringLiteral {
  /**
   * The strings that are implicitly concatenated.
   */
  NodeList<StringLiteral> _strings;

  /**
   * Initialize a newly created list of adjacent strings. To be syntactically
   * valid, the list of [strings] must contain at least two elements.
   */
  AdjacentStrings(List<StringLiteral> strings) {
    _strings = new NodeList<StringLiteral>(this, strings);
  }

  @override
  Token get beginToken => _strings.beginToken;

  @override
  Iterable get childEntities => new ChildEntities()..addAll(_strings);

  @override
  Token get endToken => _strings.endToken;

  /**
   * Return the strings that are implicitly concatenated.
   */
  NodeList<StringLiteral> get strings => _strings;

  @override
  accept(AstVisitor visitor) => visitor.visitAdjacentStrings(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _strings.accept(visitor);
  }

  @override
  void _appendStringValue(StringBuffer buffer) {
    for (StringLiteral stringLiteral in strings) {
      stringLiteral._appendStringValue(buffer);
    }
  }
}

/**
 * An AST node that can be annotated with both a documentation comment and a
 * list of annotations.
 */
abstract class AnnotatedNode extends AstNode {
  /**
   * The documentation comment associated with this node, or `null` if this node
   * does not have a documentation comment associated with it.
   */
  Comment _comment;

  /**
   * The annotations associated with this node.
   */
  NodeList<Annotation> _metadata;

  /**
   * Initialize a newly created annotated node. Either or both of the [comment]
   * and [metadata] can be `null` if the node does not have the corresponding
   * attribute.
   */
  AnnotatedNode(Comment comment, List<Annotation> metadata) {
    _comment = _becomeParentOf(comment);
    _metadata = new NodeList<Annotation>(this, metadata);
  }

  @override
  Token get beginToken {
    if (_comment == null) {
      if (_metadata.isEmpty) {
        return firstTokenAfterCommentAndMetadata;
      }
      return _metadata.beginToken;
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
   * Return the documentation comment associated with this node, or `null` if
   * this node does not have a documentation comment associated with it.
   */
  Comment get documentationComment => _comment;

  /**
   * Set the documentation comment associated with this node to the given
   * [comment].
   */
  void set documentationComment(Comment comment) {
    _comment = _becomeParentOf(comment);
  }

  /**
   * Return the first token following the comment and metadata.
   */
  Token get firstTokenAfterCommentAndMetadata;

  /**
   * Return the annotations associated with this node.
   */
  NodeList<Annotation> get metadata => _metadata;

  /**
   * Set the metadata associated with this node to the given [metadata].
   */
  @deprecated // Directly modify the list returned by "this.metadata"
  void set metadata(List<Annotation> metadata) {
    _metadata.clear();
    _metadata.addAll(metadata);
  }

  /**
   * Return a list containing the comment and annotations associated with this
   * node, sorted in lexical order.
   */
  List<AstNode> get sortedCommentAndAnnotations {
    return <AstNode>[]
      ..add(_comment)
      ..addAll(_metadata)
      ..sort(AstNode.LEXICAL_ORDER);
  }

  /**
   * Return a holder of child entities that subclasses can add to.
   */
  ChildEntities get _childEntities {
    ChildEntities result = new ChildEntities();
    if (_commentIsBeforeAnnotations()) {
      result
        ..add(_comment)
        ..addAll(_metadata);
    } else {
      result.addAll(sortedCommentAndAnnotations);
    }
    return result;
  }

  @override
  void visitChildren(AstVisitor visitor) {
    if (_commentIsBeforeAnnotations()) {
      _safelyVisitChild(_comment, visitor);
      _metadata.accept(visitor);
    } else {
      for (AstNode child in sortedCommentAndAnnotations) {
        child.accept(visitor);
      }
    }
  }

  /**
   * Return `true` if there are no annotations before the comment. Note that a
   * result of `true` does not imply that there is a comment, nor that there are
   * annotations associated with this node.
   */
  bool _commentIsBeforeAnnotations() {
    // TODO(brianwilkerson) Convert this to a getter.
    if (_comment == null || _metadata.isEmpty) {
      return true;
    }
    Annotation firstAnnotation = _metadata[0];
    return _comment.offset < firstAnnotation.offset;
  }
}

/**
 * An annotation that can be associated with an AST node.
 *
 * > metadata ::=
 * >     annotation*
 * >
 * > annotation ::=
 * >     '@' [Identifier] ('.' [SimpleIdentifier])? [ArgumentList]?
 */
class Annotation extends AstNode {
  /**
   * The at sign that introduced the annotation.
   */
  Token atSign;

  /**
   * The name of the class defining the constructor that is being invoked or the
   * name of the field that is being referenced.
   */
  Identifier _name;

  /**
   * The period before the constructor name, or `null` if this annotation is not
   * the invocation of a named constructor.
   */
  Token period;

  /**
   * The name of the constructor being invoked, or `null` if this annotation is
   * not the invocation of a named constructor.
   */
  SimpleIdentifier _constructorName;

  /**
   * The arguments to the constructor being invoked, or `null` if this
   * annotation is not the invocation of a constructor.
   */
  ArgumentList _arguments;

  /**
   * The element associated with this annotation, or `null` if the AST structure
   * has not been resolved or if this annotation could not be resolved.
   */
  Element _element;

  /**
   * The element annotation representing this annotation in the element model.
   */
  ElementAnnotation elementAnnotation;

  /**
   * Initialize a newly created annotation. Both the [period] and the
   * [constructorName] can be `null` if the annotation is not referencing a
   * named constructor. The [arguments] can be `null` if the annotation is not
   * referencing a constructor.
   */
  Annotation(this.atSign, Identifier name, this.period,
      SimpleIdentifier constructorName, ArgumentList arguments) {
    _name = _becomeParentOf(name);
    _constructorName = _becomeParentOf(constructorName);
    _arguments = _becomeParentOf(arguments);
  }

  /**
   * Return the arguments to the constructor being invoked, or `null` if this
   * annotation is not the invocation of a constructor.
   */
  ArgumentList get arguments => _arguments;

  /**
   * Set the arguments to the constructor being invoked to the given arguments.
   */
  void set arguments(ArgumentList arguments) {
    _arguments = _becomeParentOf(arguments);
  }

  @override
  Token get beginToken => atSign;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(atSign)
    ..add(_name)
    ..add(period)
    ..add(_constructorName)
    ..add(_arguments);

  /**
   * Return the name of the constructor being invoked, or `null` if this
   * annotation is not the invocation of a named constructor.
   */
  SimpleIdentifier get constructorName => _constructorName;

  /**
   * Set the name of the constructor being invoked to the given [name].
   */
  void set constructorName(SimpleIdentifier name) {
    _constructorName = _becomeParentOf(name);
  }

  /**
   * Return the element associated with this annotation, or `null` if the AST
   * structure has not been resolved or if this annotation could not be
   * resolved.
   */
  Element get element {
    if (_element != null) {
      return _element;
    } else if (_name != null) {
      return _name.staticElement;
    }
    return null;
  }

  /**
   * Set the element associated with this annotation to the given [element].
   */
  void set element(Element element) {
    _element = element;
  }

  @override
  Token get endToken {
    if (_arguments != null) {
      return _arguments.endToken;
    } else if (_constructorName != null) {
      return _constructorName.endToken;
    }
    return _name.endToken;
  }

  /**
   * Return the name of the class defining the constructor that is being invoked
   * or the name of the field that is being referenced.
   */
  Identifier get name => _name;

  /**
   * Set the name of the class defining the constructor that is being invoked or
   * the name of the field that is being referenced to the given [name].
   */
  void set name(Identifier name) {
    _name = _becomeParentOf(name);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitAnnotation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_name, visitor);
    _safelyVisitChild(_constructorName, visitor);
    _safelyVisitChild(_arguments, visitor);
  }
}

/**
 * A list of arguments in the invocation of an executable element (that is, a
 * function, method, or constructor).
 *
 * > argumentList ::=
 * >     '(' arguments? ')'
 * >
 * > arguments ::=
 * >     [NamedExpression] (',' [NamedExpression])*
 * >   | [Expression] (',' [Expression])* (',' [NamedExpression])*
 */
class ArgumentList extends AstNode {
  /**
   * The left parenthesis.
   */
  Token leftParenthesis;

  /**
   * The expressions producing the values of the arguments.
   */
  NodeList<Expression> _arguments;

  /**
   * The right parenthesis.
   */
  Token rightParenthesis;

  /**
   * A list containing the elements representing the parameters corresponding to
   * each of the arguments in this list, or `null` if the AST has not been
   * resolved or if the function or method being invoked could not be determined
   * based on static type information. The list must be the same length as the
   * number of arguments, but can contain `null` entries if a given argument
   * does not correspond to a formal parameter.
   */
  List<ParameterElement> _correspondingStaticParameters;

  /**
   * A list containing the elements representing the parameters corresponding to
   * each of the arguments in this list, or `null` if the AST has not been
   * resolved or if the function or method being invoked could not be determined
   * based on propagated type information. The list must be the same length as
   * the number of arguments, but can contain `null` entries if a given argument
   * does not correspond to a formal parameter.
   */
  List<ParameterElement> _correspondingPropagatedParameters;

  /**
   * Initialize a newly created list of arguments. The list of [arguments] can
   * be `null` if there are no arguments.
   */
  ArgumentList(
      this.leftParenthesis, List<Expression> arguments, this.rightParenthesis) {
    _arguments = new NodeList<Expression>(this, arguments);
  }

  /**
   * Return the expressions producing the values of the arguments. Although the
   * language requires that positional arguments appear before named arguments,
   * this class allows them to be intermixed.
   */
  NodeList<Expression> get arguments => _arguments;

  @override
  Token get beginToken => leftParenthesis;

  /**
   * TODO(paulberry): Add commas.
   */
  @override
  Iterable get childEntities => new ChildEntities()
    ..add(leftParenthesis)
    ..addAll(_arguments)
    ..add(rightParenthesis);

  /**
   * Set the parameter elements corresponding to each of the arguments in this
   * list to the given list of [parameters]. The list of parameters must be the
   * same length as the number of arguments, but can contain `null` entries if a
   * given argument does not correspond to a formal parameter.
   */
  void set correspondingPropagatedParameters(
      List<ParameterElement> parameters) {
    if (parameters.length != _arguments.length) {
      throw new IllegalArgumentException(
          "Expected ${_arguments.length} parameters, not ${parameters.length}");
    }
    _correspondingPropagatedParameters = parameters;
  }

  /**
   * Set the parameter elements corresponding to each of the arguments in this
   * list to the given list of parameters. The list of parameters must be the
   * same length as the number of arguments, but can contain `null` entries if a
   * given argument does not correspond to a formal parameter.
   */
  void set correspondingStaticParameters(List<ParameterElement> parameters) {
    if (parameters.length != _arguments.length) {
      throw new IllegalArgumentException(
          "Expected ${_arguments.length} parameters, not ${parameters.length}");
    }
    _correspondingStaticParameters = parameters;
  }

  @override
  Token get endToken => rightParenthesis;

  @override
  accept(AstVisitor visitor) => visitor.visitArgumentList(this);

  /**
   * If
   * * the given [expression] is a child of this list,
   * * the AST structure has been resolved,
   * * the function being invoked is known based on propagated type information,
   *   and
   * * the expression corresponds to one of the parameters of the function being
   *   invoked,
   * then return the parameter element representing the parameter to which the
   * value of the given expression will be bound. Otherwise, return `null`.
   */
  @deprecated // Use "expression.propagatedParameterElement"
  ParameterElement getPropagatedParameterElementFor(Expression expression) {
    return _getPropagatedParameterElementFor(expression);
  }

  /**
   * If
   * * the given [expression] is a child of this list,
   * * the AST structure has been resolved,
   * * the function being invoked is known based on static type information, and
   * * the expression corresponds to one of the parameters of the function being
   *   invoked,
   * then return the parameter element representing the parameter to which the
   * value of the given expression will be bound. Otherwise, return `null`.
   */
  @deprecated // Use "expression.staticParameterElement"
  ParameterElement getStaticParameterElementFor(Expression expression) {
    return _getStaticParameterElementFor(expression);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _arguments.accept(visitor);
  }

  /**
   * If
   * * the given [expression] is a child of this list,
   * * the AST structure has been resolved,
   * * the function being invoked is known based on propagated type information,
   *   and
   * * the expression corresponds to one of the parameters of the function being
   *   invoked,
   * then return the parameter element representing the parameter to which the
   * value of the given expression will be bound. Otherwise, return `null`.
   */
  ParameterElement _getPropagatedParameterElementFor(Expression expression) {
    if (_correspondingPropagatedParameters == null ||
        _correspondingPropagatedParameters.length != _arguments.length) {
      // Either the AST structure has not been resolved, the invocation of which
      // this list is a part could not be resolved, or the argument list was
      // modified after the parameters were set.
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
   * If
   * * the given [expression] is a child of this list,
   * * the AST structure has been resolved,
   * * the function being invoked is known based on static type information, and
   * * the expression corresponds to one of the parameters of the function being
   *   invoked,
   * then return the parameter element representing the parameter to which the
   * value of the given expression will be bound. Otherwise, return `null`.
   */
  ParameterElement _getStaticParameterElementFor(Expression expression) {
    if (_correspondingStaticParameters == null ||
        _correspondingStaticParameters.length != _arguments.length) {
      // Either the AST structure has not been resolved, the invocation of which
      // this list is a part could not be resolved, or the argument list was
      // modified after the parameters were set.
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
 * An as expression.
 *
 * > asExpression ::=
 * >     [Expression] 'as' [TypeName]
 */
class AsExpression extends Expression {
  /**
   * The expression used to compute the value being cast.
   */
  Expression _expression;

  /**
   * The 'as' operator.
   */
  Token asOperator;

  /**
   * The name of the type being cast to.
   */
  TypeName _type;

  /**
   * Initialize a newly created as expression.
   */
  AsExpression(Expression expression, this.asOperator, TypeName type) {
    _expression = _becomeParentOf(expression);
    _type = _becomeParentOf(type);
  }

  @override
  Token get beginToken => _expression.beginToken;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(_expression)
    ..add(asOperator)
    ..add(_type);

  @override
  Token get endToken => _type.endToken;

  /**
   * Return the expression used to compute the value being cast.
   */
  Expression get expression => _expression;

  /**
   * Set the expression used to compute the value being cast to the given
   * [expression].
   */
  void set expression(Expression expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  int get precedence => 7;

  /**
   * Return the name of the type being cast to.
   */
  TypeName get type => _type;

  /**
   * Set the name of the type being cast to to the given [name].
   */
  void set type(TypeName name) {
    _type = _becomeParentOf(name);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitAsExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_expression, visitor);
    _safelyVisitChild(_type, visitor);
  }
}

/**
 * An assert statement.
 *
 * > assertStatement ::=
 * >     'assert' '(' [Expression] ')' ';'
 */
class AssertStatement extends Statement {
  /**
   * The token representing the 'assert' keyword.
   */
  Token assertKeyword;

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
   */
  AssertStatement(this.assertKeyword, this.leftParenthesis,
      Expression condition, this.rightParenthesis, this.semicolon) {
    _condition = _becomeParentOf(condition);
  }

  @override
  Token get beginToken => assertKeyword;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(assertKeyword)
    ..add(leftParenthesis)
    ..add(_condition)
    ..add(rightParenthesis)
    ..add(semicolon);

  /**
   * Return the condition that is being asserted to be `true`.
   */
  Expression get condition => _condition;

  /**
   * Set the condition that is being asserted to be `true` to the given
   * [expression].
   */
  void set condition(Expression condition) {
    _condition = _becomeParentOf(condition);
  }

  @override
  Token get endToken => semicolon;

  /**
   * Return the token representing the 'assert' keyword.
   */
  @deprecated // Use "this.assertKeyword"
  Token get keyword => assertKeyword;

  /**
   * Set the token representing the 'assert' keyword to the given [token].
   */
  @deprecated // Use "this.assertKeyword"
  set keyword(Token token) {
    assertKeyword = token;
  }

  @override
  accept(AstVisitor visitor) => visitor.visitAssertStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_condition, visitor);
  }
}

/**
 * An assignment expression.
 *
 * > assignmentExpression ::=
 * >     [Expression] operator [Expression]
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
   * The element associated with the operator based on the static type of the
   * left-hand-side, or `null` if the AST structure has not been resolved, if
   * the operator is not a compound operator, or if the operator could not be
   * resolved.
   */
  MethodElement staticElement;

  /**
   * The element associated with the operator based on the propagated type of
   * the left-hand-side, or `null` if the AST structure has not been resolved,
   * if the operator is not a compound operator, or if the operator could not be
   * resolved.
   */
  MethodElement propagatedElement;

  /**
   * Initialize a newly created assignment expression.
   */
  AssignmentExpression(
      Expression leftHandSide, this.operator, Expression rightHandSide) {
    if (leftHandSide == null || rightHandSide == null) {
      String message;
      if (leftHandSide == null) {
        if (rightHandSide == null) {
          message = "Both the left-hand and right-hand sides are null";
        } else {
          message = "The left-hand size is null";
        }
      } else {
        message = "The right-hand size is null";
      }
      AnalysisEngine.instance.logger.logError(
          message, new CaughtException(new AnalysisException(message), null));
    }
    _leftHandSide = _becomeParentOf(leftHandSide);
    _rightHandSide = _becomeParentOf(rightHandSide);
  }

  @override
  Token get beginToken => _leftHandSide.beginToken;

  /**
   * Return the best element available for this operator. If resolution was able
   * to find a better element based on type propagation, that element will be
   * returned. Otherwise, the element found using the result of static analysis
   * will be returned. If resolution has not been performed, then `null` will be
   * returned.
   */
  MethodElement get bestElement {
    MethodElement element = propagatedElement;
    if (element == null) {
      element = staticElement;
    }
    return element;
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(_leftHandSide)
    ..add(operator)
    ..add(_rightHandSide);

  @override
  Token get endToken => _rightHandSide.endToken;

  /**
   * Set the expression used to compute the left hand side to the given
   * [expression].
   */
  Expression get leftHandSide => _leftHandSide;

  /**
   * Return the expression used to compute the left hand side.
   */
  void set leftHandSide(Expression expression) {
    _leftHandSide = _becomeParentOf(expression);
  }

  @override
  int get precedence => 1;

  /**
   * If the AST structure has been resolved, and the function being invoked is
   * known based on propagated type information, then return the parameter
   * element representing the parameter to which the value of the right operand
   * will be bound. Otherwise, return `null`.
   */
  @deprecated // Use "expression.propagatedParameterElement"
  ParameterElement get propagatedParameterElementForRightHandSide {
    return _propagatedParameterElementForRightHandSide;
  }

  /**
   * Return the expression used to compute the right hand side.
   */
  Expression get rightHandSide => _rightHandSide;

  /**
   * Set the expression used to compute the left hand side to the given
   * [expression].
   */
  void set rightHandSide(Expression expression) {
    _rightHandSide = _becomeParentOf(expression);
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is
   * known based on static type information, then return the parameter element
   * representing the parameter to which the value of the right operand will be
   * bound. Otherwise, return `null`.
   */
  @deprecated // Use "expression.staticParameterElement"
  ParameterElement get staticParameterElementForRightHandSide {
    return _staticParameterElementForRightHandSide;
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is
   * known based on propagated type information, then return the parameter
   * element representing the parameter to which the value of the right operand
   * will be bound. Otherwise, return `null`.
   */
  ParameterElement get _propagatedParameterElementForRightHandSide {
    ExecutableElement executableElement = null;
    if (propagatedElement != null) {
      executableElement = propagatedElement;
    } else {
      if (_leftHandSide is Identifier) {
        Identifier identifier = _leftHandSide as Identifier;
        Element leftElement = identifier.propagatedElement;
        if (leftElement is ExecutableElement) {
          executableElement = leftElement;
        }
      }
      if (_leftHandSide is PropertyAccess) {
        SimpleIdentifier identifier =
            (_leftHandSide as PropertyAccess).propertyName;
        Element leftElement = identifier.propagatedElement;
        if (leftElement is ExecutableElement) {
          executableElement = leftElement;
        }
      }
    }
    if (executableElement == null) {
      return null;
    }
    List<ParameterElement> parameters = executableElement.parameters;
    if (parameters.length < 1) {
      return null;
    }
    return parameters[0];
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is
   * known based on static type information, then return the parameter element
   * representing the parameter to which the value of the right operand will be
   * bound. Otherwise, return `null`.
   */
  ParameterElement get _staticParameterElementForRightHandSide {
    ExecutableElement executableElement = null;
    if (staticElement != null) {
      executableElement = staticElement;
    } else {
      if (_leftHandSide is Identifier) {
        Element leftElement = (_leftHandSide as Identifier).staticElement;
        if (leftElement is ExecutableElement) {
          executableElement = leftElement;
        }
      }
      if (_leftHandSide is PropertyAccess) {
        Element leftElement =
            (_leftHandSide as PropertyAccess).propertyName.staticElement;
        if (leftElement is ExecutableElement) {
          executableElement = leftElement;
        }
      }
    }
    if (executableElement == null) {
      return null;
    }
    List<ParameterElement> parameters = executableElement.parameters;
    if (parameters.length < 1) {
      return null;
    }
    return parameters[0];
  }

  @override
  accept(AstVisitor visitor) => visitor.visitAssignmentExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_leftHandSide, visitor);
    _safelyVisitChild(_rightHandSide, visitor);
  }
}

/**
 * An AST visitor that will clone any AST structure that it visits. The cloner
 * will only clone the structure, it will not preserve any resolution results or
 * properties associated with the nodes.
 */
class AstCloner implements AstVisitor<AstNode> {
  /**
   * A flag indicating whether tokens should be cloned while cloning an AST
   * structure.
   */
  final bool cloneTokens;

  /**
   * Initialize a newly created AST cloner to optionally clone tokens while
   * cloning AST nodes if [cloneTokens] is `true`.
   */
  AstCloner(
      [this.cloneTokens = false]); // TODO(brianwilkerson) Change this to be a named parameter.

  /**
   * Return a clone of the given [node].
   */
  AstNode cloneNode(AstNode node) {
    if (node == null) {
      return null;
    }
    return node.accept(this) as AstNode;
  }

  /**
   * Return a list containing cloned versions of the nodes in the given list of
   * [nodes].
   */
  List<AstNode> cloneNodeList(NodeList nodes) {
    int count = nodes.length;
    List clonedNodes = new List();
    for (int i = 0; i < count; i++) {
      clonedNodes.add((nodes[i]).accept(this) as AstNode);
    }
    return clonedNodes;
  }

  /**
   * Clone the given [token] if tokens are supposed to be cloned.
   */
  Token cloneToken(Token token) {
    if (cloneTokens) {
      return (token == null ? null : token.copy());
    } else {
      return token;
    }
  }

  /**
   * Clone the given [tokens] if tokens are supposed to be cloned.
   */
  List<Token> cloneTokenList(List<Token> tokens) {
    if (cloneTokens) {
      return tokens.map((Token token) => token.copy()).toList();
    }
    return tokens;
  }

  @override
  AdjacentStrings visitAdjacentStrings(AdjacentStrings node) =>
      new AdjacentStrings(cloneNodeList(node.strings));

  @override
  Annotation visitAnnotation(Annotation node) => new Annotation(
      cloneToken(node.atSign), cloneNode(node.name), cloneToken(node.period),
      cloneNode(node.constructorName), cloneNode(node.arguments));

  @override
  ArgumentList visitArgumentList(ArgumentList node) => new ArgumentList(
      cloneToken(node.leftParenthesis), cloneNodeList(node.arguments),
      cloneToken(node.rightParenthesis));

  @override
  AsExpression visitAsExpression(AsExpression node) => new AsExpression(
      cloneNode(node.expression), cloneToken(node.asOperator),
      cloneNode(node.type));

  @override
  AstNode visitAssertStatement(AssertStatement node) => new AssertStatement(
      cloneToken(node.assertKeyword), cloneToken(node.leftParenthesis),
      cloneNode(node.condition), cloneToken(node.rightParenthesis),
      cloneToken(node.semicolon));

  @override
  AssignmentExpression visitAssignmentExpression(AssignmentExpression node) =>
      new AssignmentExpression(cloneNode(node.leftHandSide),
          cloneToken(node.operator), cloneNode(node.rightHandSide));

  @override
  AwaitExpression visitAwaitExpression(AwaitExpression node) =>
      new AwaitExpression(
          cloneToken(node.awaitKeyword), cloneNode(node.expression));

  @override
  BinaryExpression visitBinaryExpression(BinaryExpression node) =>
      new BinaryExpression(cloneNode(node.leftOperand),
          cloneToken(node.operator), cloneNode(node.rightOperand));

  @override
  Block visitBlock(Block node) => new Block(cloneToken(node.leftBracket),
      cloneNodeList(node.statements), cloneToken(node.rightBracket));

  @override
  BlockFunctionBody visitBlockFunctionBody(
      BlockFunctionBody node) => new BlockFunctionBody(
      cloneToken(node.keyword), cloneToken(node.star), cloneNode(node.block));

  @override
  BooleanLiteral visitBooleanLiteral(BooleanLiteral node) =>
      new BooleanLiteral(cloneToken(node.literal), node.value);

  @override
  BreakStatement visitBreakStatement(BreakStatement node) => new BreakStatement(
      cloneToken(node.breakKeyword), cloneNode(node.label),
      cloneToken(node.semicolon));

  @override
  CascadeExpression visitCascadeExpression(CascadeExpression node) =>
      new CascadeExpression(
          cloneNode(node.target), cloneNodeList(node.cascadeSections));

  @override
  CatchClause visitCatchClause(CatchClause node) => new CatchClause(
      cloneToken(node.onKeyword), cloneNode(node.exceptionType),
      cloneToken(node.catchKeyword), cloneToken(node.leftParenthesis),
      cloneNode(node.exceptionParameter), cloneToken(node.comma),
      cloneNode(node.stackTraceParameter), cloneToken(node.rightParenthesis),
      cloneNode(node.body));

  @override
  ClassDeclaration visitClassDeclaration(ClassDeclaration node) {
    ClassDeclaration copy = new ClassDeclaration(
        cloneNode(node.documentationComment), cloneNodeList(node.metadata),
        cloneToken(node.abstractKeyword), cloneToken(node.classKeyword),
        cloneNode(node.name), cloneNode(node.typeParameters),
        cloneNode(node.extendsClause), cloneNode(node.withClause),
        cloneNode(node.implementsClause), cloneToken(node.leftBracket),
        cloneNodeList(node.members), cloneToken(node.rightBracket));
    copy.nativeClause = cloneNode(node.nativeClause);
    return copy;
  }

  @override
  ClassTypeAlias visitClassTypeAlias(ClassTypeAlias node) => new ClassTypeAlias(
      cloneNode(node.documentationComment), cloneNodeList(node.metadata),
      cloneToken(node.typedefKeyword), cloneNode(node.name),
      cloneNode(node.typeParameters), cloneToken(node.equals),
      cloneToken(node.abstractKeyword), cloneNode(node.superclass),
      cloneNode(node.withClause), cloneNode(node.implementsClause),
      cloneToken(node.semicolon));

  @override
  Comment visitComment(Comment node) {
    if (node.isDocumentation) {
      return Comment.createDocumentationCommentWithReferences(
          cloneTokenList(node.tokens), cloneNodeList(node.references));
    } else if (node.isBlock) {
      return Comment.createBlockComment(cloneTokenList(node.tokens));
    }
    return Comment.createEndOfLineComment(cloneTokenList(node.tokens));
  }

  @override
  CommentReference visitCommentReference(CommentReference node) =>
      new CommentReference(
          cloneToken(node.newKeyword), cloneNode(node.identifier));

  @override
  CompilationUnit visitCompilationUnit(CompilationUnit node) {
    CompilationUnit clone = new CompilationUnit(cloneToken(node.beginToken),
        cloneNode(node.scriptTag), cloneNodeList(node.directives),
        cloneNodeList(node.declarations), cloneToken(node.endToken));
    clone.lineInfo = node.lineInfo;
    return clone;
  }

  @override
  ConditionalExpression visitConditionalExpression(
      ConditionalExpression node) => new ConditionalExpression(
      cloneNode(node.condition), cloneToken(node.question),
      cloneNode(node.thenExpression), cloneToken(node.colon),
      cloneNode(node.elseExpression));

  @override
  ConstructorDeclaration visitConstructorDeclaration(
      ConstructorDeclaration node) => new ConstructorDeclaration(
      cloneNode(node.documentationComment), cloneNodeList(node.metadata),
      cloneToken(node.externalKeyword), cloneToken(node.constKeyword),
      cloneToken(node.factoryKeyword), cloneNode(node.returnType),
      cloneToken(node.period), cloneNode(node.name), cloneNode(node.parameters),
      cloneToken(node.separator), cloneNodeList(node.initializers),
      cloneNode(node.redirectedConstructor), cloneNode(node.body));

  @override
  ConstructorFieldInitializer visitConstructorFieldInitializer(
      ConstructorFieldInitializer node) => new ConstructorFieldInitializer(
      cloneToken(node.thisKeyword), cloneToken(node.period),
      cloneNode(node.fieldName), cloneToken(node.equals),
      cloneNode(node.expression));

  @override
  ConstructorName visitConstructorName(ConstructorName node) =>
      new ConstructorName(
          cloneNode(node.type), cloneToken(node.period), cloneNode(node.name));

  @override
  ContinueStatement visitContinueStatement(ContinueStatement node) =>
      new ContinueStatement(cloneToken(node.continueKeyword),
          cloneNode(node.label), cloneToken(node.semicolon));

  @override
  DeclaredIdentifier visitDeclaredIdentifier(DeclaredIdentifier node) =>
      new DeclaredIdentifier(cloneNode(node.documentationComment),
          cloneNodeList(node.metadata), cloneToken(node.keyword),
          cloneNode(node.type), cloneNode(node.identifier));

  @override
  DefaultFormalParameter visitDefaultFormalParameter(
      DefaultFormalParameter node) => new DefaultFormalParameter(
      cloneNode(node.parameter), node.kind, cloneToken(node.separator),
      cloneNode(node.defaultValue));

  @override
  DoStatement visitDoStatement(DoStatement node) => new DoStatement(
      cloneToken(node.doKeyword), cloneNode(node.body),
      cloneToken(node.whileKeyword), cloneToken(node.leftParenthesis),
      cloneNode(node.condition), cloneToken(node.rightParenthesis),
      cloneToken(node.semicolon));

  @override
  DoubleLiteral visitDoubleLiteral(DoubleLiteral node) =>
      new DoubleLiteral(cloneToken(node.literal), node.value);

  @override
  EmptyFunctionBody visitEmptyFunctionBody(EmptyFunctionBody node) =>
      new EmptyFunctionBody(cloneToken(node.semicolon));

  @override
  EmptyStatement visitEmptyStatement(EmptyStatement node) =>
      new EmptyStatement(cloneToken(node.semicolon));

  @override
  AstNode visitEnumConstantDeclaration(EnumConstantDeclaration node) =>
      new EnumConstantDeclaration(cloneNode(node.documentationComment),
          cloneNodeList(node.metadata), cloneNode(node.name));

  @override
  EnumDeclaration visitEnumDeclaration(EnumDeclaration node) =>
      new EnumDeclaration(cloneNode(node.documentationComment),
          cloneNodeList(node.metadata), cloneToken(node.enumKeyword),
          cloneNode(node.name), cloneToken(node.leftBracket),
          cloneNodeList(node.constants), cloneToken(node.rightBracket));

  @override
  ExportDirective visitExportDirective(ExportDirective node) {
    ExportDirective directive = new ExportDirective(
        cloneNode(node.documentationComment), cloneNodeList(node.metadata),
        cloneToken(node.keyword), cloneNode(node.uri),
        cloneNodeList(node.combinators), cloneToken(node.semicolon));
    directive.source = node.source;
    directive.uriContent = node.uriContent;
    return directive;
  }

  @override
  ExpressionFunctionBody visitExpressionFunctionBody(
      ExpressionFunctionBody node) => new ExpressionFunctionBody(
      cloneToken(node.keyword), cloneToken(node.functionDefinition),
      cloneNode(node.expression), cloneToken(node.semicolon));

  @override
  ExpressionStatement visitExpressionStatement(ExpressionStatement node) =>
      new ExpressionStatement(
          cloneNode(node.expression), cloneToken(node.semicolon));

  @override
  ExtendsClause visitExtendsClause(ExtendsClause node) => new ExtendsClause(
      cloneToken(node.extendsKeyword), cloneNode(node.superclass));

  @override
  FieldDeclaration visitFieldDeclaration(FieldDeclaration node) =>
      new FieldDeclaration(cloneNode(node.documentationComment),
          cloneNodeList(node.metadata), cloneToken(node.staticKeyword),
          cloneNode(node.fields), cloneToken(node.semicolon));

  @override
  FieldFormalParameter visitFieldFormalParameter(FieldFormalParameter node) =>
      new FieldFormalParameter(cloneNode(node.documentationComment),
          cloneNodeList(node.metadata), cloneToken(node.keyword),
          cloneNode(node.type), cloneToken(node.thisKeyword),
          cloneToken(node.period), cloneNode(node.identifier),
          cloneNode(node.parameters));

  @override
  ForEachStatement visitForEachStatement(ForEachStatement node) {
    DeclaredIdentifier loopVariable = node.loopVariable;
    if (loopVariable == null) {
      return new ForEachStatement.con2(cloneToken(node.awaitKeyword),
          cloneToken(node.forKeyword), cloneToken(node.leftParenthesis),
          cloneNode(node.identifier), cloneToken(node.inKeyword),
          cloneNode(node.iterable), cloneToken(node.rightParenthesis),
          cloneNode(node.body));
    }
    return new ForEachStatement.con1(cloneToken(node.awaitKeyword),
        cloneToken(node.forKeyword), cloneToken(node.leftParenthesis),
        cloneNode(loopVariable), cloneToken(node.inKeyword),
        cloneNode(node.iterable), cloneToken(node.rightParenthesis),
        cloneNode(node.body));
  }

  @override
  FormalParameterList visitFormalParameterList(FormalParameterList node) =>
      new FormalParameterList(cloneToken(node.leftParenthesis),
          cloneNodeList(node.parameters), cloneToken(node.leftDelimiter),
          cloneToken(node.rightDelimiter), cloneToken(node.rightParenthesis));

  @override
  ForStatement visitForStatement(ForStatement node) => new ForStatement(
      cloneToken(node.forKeyword), cloneToken(node.leftParenthesis),
      cloneNode(node.variables), cloneNode(node.initialization),
      cloneToken(node.leftSeparator), cloneNode(node.condition),
      cloneToken(node.rightSeparator), cloneNodeList(node.updaters),
      cloneToken(node.rightParenthesis), cloneNode(node.body));

  @override
  FunctionDeclaration visitFunctionDeclaration(FunctionDeclaration node) =>
      new FunctionDeclaration(cloneNode(node.documentationComment),
          cloneNodeList(node.metadata), cloneToken(node.externalKeyword),
          cloneNode(node.returnType), cloneToken(node.propertyKeyword),
          cloneNode(node.name), cloneNode(node.functionExpression));

  @override
  FunctionDeclarationStatement visitFunctionDeclarationStatement(
          FunctionDeclarationStatement node) =>
      new FunctionDeclarationStatement(cloneNode(node.functionDeclaration));

  @override
  FunctionExpression visitFunctionExpression(FunctionExpression node) =>
      new FunctionExpression(cloneNode(node.parameters), cloneNode(node.body));

  @override
  FunctionExpressionInvocation visitFunctionExpressionInvocation(
      FunctionExpressionInvocation node) => new FunctionExpressionInvocation(
      cloneNode(node.function), cloneNode(node.argumentList));

  @override
  FunctionTypeAlias visitFunctionTypeAlias(FunctionTypeAlias node) =>
      new FunctionTypeAlias(cloneNode(node.documentationComment),
          cloneNodeList(node.metadata), cloneToken(node.typedefKeyword),
          cloneNode(node.returnType), cloneNode(node.name),
          cloneNode(node.typeParameters), cloneNode(node.parameters),
          cloneToken(node.semicolon));

  @override
  FunctionTypedFormalParameter visitFunctionTypedFormalParameter(
      FunctionTypedFormalParameter node) => new FunctionTypedFormalParameter(
      cloneNode(node.documentationComment), cloneNodeList(node.metadata),
      cloneNode(node.returnType), cloneNode(node.identifier),
      cloneNode(node.parameters));

  @override
  HideCombinator visitHideCombinator(HideCombinator node) => new HideCombinator(
      cloneToken(node.keyword), cloneNodeList(node.hiddenNames));

  @override
  IfStatement visitIfStatement(IfStatement node) => new IfStatement(
      cloneToken(node.ifKeyword), cloneToken(node.leftParenthesis),
      cloneNode(node.condition), cloneToken(node.rightParenthesis),
      cloneNode(node.thenStatement), cloneToken(node.elseKeyword),
      cloneNode(node.elseStatement));

  @override
  ImplementsClause visitImplementsClause(ImplementsClause node) =>
      new ImplementsClause(
          cloneToken(node.implementsKeyword), cloneNodeList(node.interfaces));

  @override
  ImportDirective visitImportDirective(ImportDirective node) {
    ImportDirective directive = new ImportDirective(
        cloneNode(node.documentationComment), cloneNodeList(node.metadata),
        cloneToken(node.keyword), cloneNode(node.uri),
        cloneToken(node.deferredKeyword), cloneToken(node.asKeyword),
        cloneNode(node.prefix), cloneNodeList(node.combinators),
        cloneToken(node.semicolon));
    directive.source = node.source;
    directive.uriContent = node.uriContent;
    return directive;
  }

  @override
  IndexExpression visitIndexExpression(IndexExpression node) {
    Token period = node.period;
    if (period == null) {
      return new IndexExpression.forTarget(cloneNode(node.target),
          cloneToken(node.leftBracket), cloneNode(node.index),
          cloneToken(node.rightBracket));
    } else {
      return new IndexExpression.forCascade(cloneToken(period),
          cloneToken(node.leftBracket), cloneNode(node.index),
          cloneToken(node.rightBracket));
    }
  }

  @override
  InstanceCreationExpression visitInstanceCreationExpression(
      InstanceCreationExpression node) => new InstanceCreationExpression(
      cloneToken(node.keyword), cloneNode(node.constructorName),
      cloneNode(node.argumentList));

  @override
  IntegerLiteral visitIntegerLiteral(IntegerLiteral node) =>
      new IntegerLiteral(cloneToken(node.literal), node.value);

  @override
  InterpolationExpression visitInterpolationExpression(
      InterpolationExpression node) => new InterpolationExpression(
      cloneToken(node.leftBracket), cloneNode(node.expression),
      cloneToken(node.rightBracket));

  @override
  InterpolationString visitInterpolationString(InterpolationString node) =>
      new InterpolationString(cloneToken(node.contents), node.value);

  @override
  IsExpression visitIsExpression(IsExpression node) => new IsExpression(
      cloneNode(node.expression), cloneToken(node.isOperator),
      cloneToken(node.notOperator), cloneNode(node.type));

  @override
  Label visitLabel(Label node) =>
      new Label(cloneNode(node.label), cloneToken(node.colon));

  @override
  LabeledStatement visitLabeledStatement(LabeledStatement node) =>
      new LabeledStatement(
          cloneNodeList(node.labels), cloneNode(node.statement));

  @override
  LibraryDirective visitLibraryDirective(LibraryDirective node) =>
      new LibraryDirective(cloneNode(node.documentationComment),
          cloneNodeList(node.metadata), cloneToken(node.libraryKeyword),
          cloneNode(node.name), cloneToken(node.semicolon));

  @override
  LibraryIdentifier visitLibraryIdentifier(LibraryIdentifier node) =>
      new LibraryIdentifier(cloneNodeList(node.components));

  @override
  ListLiteral visitListLiteral(ListLiteral node) => new ListLiteral(
      cloneToken(node.constKeyword), cloneNode(node.typeArguments),
      cloneToken(node.leftBracket), cloneNodeList(node.elements),
      cloneToken(node.rightBracket));

  @override
  MapLiteral visitMapLiteral(MapLiteral node) => new MapLiteral(
      cloneToken(node.constKeyword), cloneNode(node.typeArguments),
      cloneToken(node.leftBracket), cloneNodeList(node.entries),
      cloneToken(node.rightBracket));

  @override
  MapLiteralEntry visitMapLiteralEntry(
      MapLiteralEntry node) => new MapLiteralEntry(
      cloneNode(node.key), cloneToken(node.separator), cloneNode(node.value));

  @override
  MethodDeclaration visitMethodDeclaration(MethodDeclaration node) =>
      new MethodDeclaration(cloneNode(node.documentationComment),
          cloneNodeList(node.metadata), cloneToken(node.externalKeyword),
          cloneToken(node.modifierKeyword), cloneNode(node.returnType),
          cloneToken(node.propertyKeyword), cloneToken(node.operatorKeyword),
          cloneNode(node.name), cloneNode(node.parameters),
          cloneNode(node.body));

  @override
  MethodInvocation visitMethodInvocation(MethodInvocation node) =>
      new MethodInvocation(cloneNode(node.target), cloneToken(node.operator),
          cloneNode(node.methodName), cloneNode(node.argumentList));

  @override
  NamedExpression visitNamedExpression(NamedExpression node) =>
      new NamedExpression(cloneNode(node.name), cloneNode(node.expression));

  @override
  AstNode visitNativeClause(NativeClause node) =>
      new NativeClause(cloneToken(node.nativeKeyword), cloneNode(node.name));

  @override
  NativeFunctionBody visitNativeFunctionBody(NativeFunctionBody node) =>
      new NativeFunctionBody(cloneToken(node.nativeKeyword),
          cloneNode(node.stringLiteral), cloneToken(node.semicolon));

  @override
  NullLiteral visitNullLiteral(NullLiteral node) =>
      new NullLiteral(cloneToken(node.literal));

  @override
  ParenthesizedExpression visitParenthesizedExpression(
      ParenthesizedExpression node) => new ParenthesizedExpression(
      cloneToken(node.leftParenthesis), cloneNode(node.expression),
      cloneToken(node.rightParenthesis));

  @override
  PartDirective visitPartDirective(PartDirective node) {
    PartDirective directive = new PartDirective(
        cloneNode(node.documentationComment), cloneNodeList(node.metadata),
        cloneToken(node.partKeyword), cloneNode(node.uri),
        cloneToken(node.semicolon));
    directive.source = node.source;
    directive.uriContent = node.uriContent;
    return directive;
  }

  @override
  PartOfDirective visitPartOfDirective(PartOfDirective node) =>
      new PartOfDirective(cloneNode(node.documentationComment),
          cloneNodeList(node.metadata), cloneToken(node.partKeyword),
          cloneToken(node.ofKeyword), cloneNode(node.libraryName),
          cloneToken(node.semicolon));

  @override
  PostfixExpression visitPostfixExpression(PostfixExpression node) =>
      new PostfixExpression(cloneNode(node.operand), cloneToken(node.operator));

  @override
  PrefixedIdentifier visitPrefixedIdentifier(PrefixedIdentifier node) =>
      new PrefixedIdentifier(cloneNode(node.prefix), cloneToken(node.period),
          cloneNode(node.identifier));

  @override
  PrefixExpression visitPrefixExpression(PrefixExpression node) =>
      new PrefixExpression(cloneToken(node.operator), cloneNode(node.operand));

  @override
  PropertyAccess visitPropertyAccess(PropertyAccess node) => new PropertyAccess(
      cloneNode(node.target), cloneToken(node.operator),
      cloneNode(node.propertyName));

  @override
  RedirectingConstructorInvocation visitRedirectingConstructorInvocation(
          RedirectingConstructorInvocation node) =>
      new RedirectingConstructorInvocation(cloneToken(node.thisKeyword),
          cloneToken(node.period), cloneNode(node.constructorName),
          cloneNode(node.argumentList));

  @override
  RethrowExpression visitRethrowExpression(RethrowExpression node) =>
      new RethrowExpression(cloneToken(node.rethrowKeyword));

  @override
  ReturnStatement visitReturnStatement(ReturnStatement node) =>
      new ReturnStatement(cloneToken(node.returnKeyword),
          cloneNode(node.expression), cloneToken(node.semicolon));

  @override
  ScriptTag visitScriptTag(ScriptTag node) =>
      new ScriptTag(cloneToken(node.scriptTag));

  @override
  ShowCombinator visitShowCombinator(ShowCombinator node) => new ShowCombinator(
      cloneToken(node.keyword), cloneNodeList(node.shownNames));

  @override
  SimpleFormalParameter visitSimpleFormalParameter(
      SimpleFormalParameter node) => new SimpleFormalParameter(
      cloneNode(node.documentationComment), cloneNodeList(node.metadata),
      cloneToken(node.keyword), cloneNode(node.type),
      cloneNode(node.identifier));

  @override
  SimpleIdentifier visitSimpleIdentifier(SimpleIdentifier node) =>
      new SimpleIdentifier(cloneToken(node.token));

  @override
  SimpleStringLiteral visitSimpleStringLiteral(SimpleStringLiteral node) =>
      new SimpleStringLiteral(cloneToken(node.literal), node.value);

  @override
  StringInterpolation visitStringInterpolation(StringInterpolation node) =>
      new StringInterpolation(cloneNodeList(node.elements));

  @override
  SuperConstructorInvocation visitSuperConstructorInvocation(
      SuperConstructorInvocation node) => new SuperConstructorInvocation(
      cloneToken(node.superKeyword), cloneToken(node.period),
      cloneNode(node.constructorName), cloneNode(node.argumentList));

  @override
  SuperExpression visitSuperExpression(SuperExpression node) =>
      new SuperExpression(cloneToken(node.superKeyword));

  @override
  SwitchCase visitSwitchCase(SwitchCase node) => new SwitchCase(
      cloneNodeList(node.labels), cloneToken(node.keyword),
      cloneNode(node.expression), cloneToken(node.colon),
      cloneNodeList(node.statements));

  @override
  SwitchDefault visitSwitchDefault(SwitchDefault node) => new SwitchDefault(
      cloneNodeList(node.labels), cloneToken(node.keyword),
      cloneToken(node.colon), cloneNodeList(node.statements));

  @override
  SwitchStatement visitSwitchStatement(SwitchStatement node) =>
      new SwitchStatement(cloneToken(node.switchKeyword),
          cloneToken(node.leftParenthesis), cloneNode(node.expression),
          cloneToken(node.rightParenthesis), cloneToken(node.leftBracket),
          cloneNodeList(node.members), cloneToken(node.rightBracket));

  @override
  SymbolLiteral visitSymbolLiteral(SymbolLiteral node) => new SymbolLiteral(
      cloneToken(node.poundSign), cloneTokenList(node.components));

  @override
  ThisExpression visitThisExpression(ThisExpression node) =>
      new ThisExpression(cloneToken(node.thisKeyword));

  @override
  ThrowExpression visitThrowExpression(ThrowExpression node) =>
      new ThrowExpression(
          cloneToken(node.throwKeyword), cloneNode(node.expression));

  @override
  TopLevelVariableDeclaration visitTopLevelVariableDeclaration(
      TopLevelVariableDeclaration node) => new TopLevelVariableDeclaration(
      cloneNode(node.documentationComment), cloneNodeList(node.metadata),
      cloneNode(node.variables), cloneToken(node.semicolon));

  @override
  TryStatement visitTryStatement(TryStatement node) => new TryStatement(
      cloneToken(node.tryKeyword), cloneNode(node.body),
      cloneNodeList(node.catchClauses), cloneToken(node.finallyKeyword),
      cloneNode(node.finallyBlock));

  @override
  TypeArgumentList visitTypeArgumentList(TypeArgumentList node) =>
      new TypeArgumentList(cloneToken(node.leftBracket),
          cloneNodeList(node.arguments), cloneToken(node.rightBracket));

  @override
  TypeName visitTypeName(TypeName node) =>
      new TypeName(cloneNode(node.name), cloneNode(node.typeArguments));

  @override
  TypeParameter visitTypeParameter(TypeParameter node) => new TypeParameter(
      cloneNode(node.documentationComment), cloneNodeList(node.metadata),
      cloneNode(node.name), cloneToken(node.extendsKeyword),
      cloneNode(node.bound));

  @override
  TypeParameterList visitTypeParameterList(TypeParameterList node) =>
      new TypeParameterList(cloneToken(node.leftBracket),
          cloneNodeList(node.typeParameters), cloneToken(node.rightBracket));

  @override
  VariableDeclaration visitVariableDeclaration(VariableDeclaration node) =>
      new VariableDeclaration(cloneNode(node.name), cloneToken(node.equals),
          cloneNode(node.initializer));

  @override
  VariableDeclarationList visitVariableDeclarationList(
      VariableDeclarationList node) => new VariableDeclarationList(null,
      cloneNodeList(node.metadata), cloneToken(node.keyword),
      cloneNode(node.type), cloneNodeList(node.variables));

  @override
  VariableDeclarationStatement visitVariableDeclarationStatement(
      VariableDeclarationStatement node) => new VariableDeclarationStatement(
      cloneNode(node.variables), cloneToken(node.semicolon));

  @override
  WhileStatement visitWhileStatement(WhileStatement node) => new WhileStatement(
      cloneToken(node.whileKeyword), cloneToken(node.leftParenthesis),
      cloneNode(node.condition), cloneToken(node.rightParenthesis),
      cloneNode(node.body));

  @override
  WithClause visitWithClause(WithClause node) => new WithClause(
      cloneToken(node.withKeyword), cloneNodeList(node.mixinTypes));

  @override
  YieldStatement visitYieldStatement(YieldStatement node) => new YieldStatement(
      cloneToken(node.yieldKeyword), cloneToken(node.star),
      cloneNode(node.expression), cloneToken(node.semicolon));

  /**
   * Return a clone of the given [node].
   */
  static AstNode clone(AstNode node) {
    return node.accept(new AstCloner());
  }
}

/**
 * An AstVisitor that compares the structure of two AstNodes to see whether they
 * are equal.
 */
class AstComparator implements AstVisitor<bool> {
  /**
   * The AST node with which the node being visited is to be compared. This is
   * only valid at the beginning of each visit method (until [isEqualNodes] is
   * invoked).
   */
  AstNode _other;

  /**
   * Return `true` if the [first] node and the [second] node have the same
   * structure.
   *
   * *Note:* This method is only visible for testing purposes and should not be
   * used by clients.
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
   * Return `true` if the [first] token and the [second] token have the same
   * structure.
   *
   * *Note:* This method is only visible for testing purposes and should not be
   * used by clients.
   */
  bool isEqualTokens(Token first, Token second) {
    if (first == null) {
      return second == null;
    } else if (second == null) {
      return false;
    } else if (identical(first, second)) {
      return true;
    }
    return first.offset == second.offset &&
        first.length == second.length &&
        first.lexeme == second.lexeme;
  }

  @override
  bool visitAdjacentStrings(AdjacentStrings node) {
    AdjacentStrings other = _other as AdjacentStrings;
    return _isEqualNodeLists(node.strings, other.strings);
  }

  @override
  bool visitAnnotation(Annotation node) {
    Annotation other = _other as Annotation;
    return isEqualTokens(node.atSign, other.atSign) &&
        isEqualNodes(node.name, other.name) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.constructorName, other.constructorName) &&
        isEqualNodes(node.arguments, other.arguments);
  }

  @override
  bool visitArgumentList(ArgumentList node) {
    ArgumentList other = _other as ArgumentList;
    return isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        _isEqualNodeLists(node.arguments, other.arguments) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis);
  }

  @override
  bool visitAsExpression(AsExpression node) {
    AsExpression other = _other as AsExpression;
    return isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.asOperator, other.asOperator) &&
        isEqualNodes(node.type, other.type);
  }

  @override
  bool visitAssertStatement(AssertStatement node) {
    AssertStatement other = _other as AssertStatement;
    return isEqualTokens(node.assertKeyword, other.assertKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitAssignmentExpression(AssignmentExpression node) {
    AssignmentExpression other = _other as AssignmentExpression;
    return isEqualNodes(node.leftHandSide, other.leftHandSide) &&
        isEqualTokens(node.operator, other.operator) &&
        isEqualNodes(node.rightHandSide, other.rightHandSide);
  }

  @override
  bool visitAwaitExpression(AwaitExpression node) {
    AwaitExpression other = _other as AwaitExpression;
    return isEqualTokens(node.awaitKeyword, other.awaitKeyword) &&
        isEqualNodes(node.expression, other.expression);
  }

  @override
  bool visitBinaryExpression(BinaryExpression node) {
    BinaryExpression other = _other as BinaryExpression;
    return isEqualNodes(node.leftOperand, other.leftOperand) &&
        isEqualTokens(node.operator, other.operator) &&
        isEqualNodes(node.rightOperand, other.rightOperand);
  }

  @override
  bool visitBlock(Block node) {
    Block other = _other as Block;
    return isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.statements, other.statements) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitBlockFunctionBody(BlockFunctionBody node) {
    BlockFunctionBody other = _other as BlockFunctionBody;
    return isEqualNodes(node.block, other.block);
  }

  @override
  bool visitBooleanLiteral(BooleanLiteral node) {
    BooleanLiteral other = _other as BooleanLiteral;
    return isEqualTokens(node.literal, other.literal) &&
        node.value == other.value;
  }

  @override
  bool visitBreakStatement(BreakStatement node) {
    BreakStatement other = _other as BreakStatement;
    return isEqualTokens(node.breakKeyword, other.breakKeyword) &&
        isEqualNodes(node.label, other.label) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitCascadeExpression(CascadeExpression node) {
    CascadeExpression other = _other as CascadeExpression;
    return isEqualNodes(node.target, other.target) &&
        _isEqualNodeLists(node.cascadeSections, other.cascadeSections);
  }

  @override
  bool visitCatchClause(CatchClause node) {
    CatchClause other = _other as CatchClause;
    return isEqualTokens(node.onKeyword, other.onKeyword) &&
        isEqualNodes(node.exceptionType, other.exceptionType) &&
        isEqualTokens(node.catchKeyword, other.catchKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.exceptionParameter, other.exceptionParameter) &&
        isEqualTokens(node.comma, other.comma) &&
        isEqualNodes(node.stackTraceParameter, other.stackTraceParameter) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualNodes(node.body, other.body);
  }

  @override
  bool visitClassDeclaration(ClassDeclaration node) {
    ClassDeclaration other = _other as ClassDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.abstractKeyword, other.abstractKeyword) &&
        isEqualTokens(node.classKeyword, other.classKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.typeParameters, other.typeParameters) &&
        isEqualNodes(node.extendsClause, other.extendsClause) &&
        isEqualNodes(node.withClause, other.withClause) &&
        isEqualNodes(node.implementsClause, other.implementsClause) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.members, other.members) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitClassTypeAlias(ClassTypeAlias node) {
    ClassTypeAlias other = _other as ClassTypeAlias;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.typedefKeyword, other.typedefKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.typeParameters, other.typeParameters) &&
        isEqualTokens(node.equals, other.equals) &&
        isEqualTokens(node.abstractKeyword, other.abstractKeyword) &&
        isEqualNodes(node.superclass, other.superclass) &&
        isEqualNodes(node.withClause, other.withClause) &&
        isEqualNodes(node.implementsClause, other.implementsClause) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitComment(Comment node) {
    Comment other = _other as Comment;
    return _isEqualNodeLists(node.references, other.references);
  }

  @override
  bool visitCommentReference(CommentReference node) {
    CommentReference other = _other as CommentReference;
    return isEqualTokens(node.newKeyword, other.newKeyword) &&
        isEqualNodes(node.identifier, other.identifier);
  }

  @override
  bool visitCompilationUnit(CompilationUnit node) {
    CompilationUnit other = _other as CompilationUnit;
    return isEqualTokens(node.beginToken, other.beginToken) &&
        isEqualNodes(node.scriptTag, other.scriptTag) &&
        _isEqualNodeLists(node.directives, other.directives) &&
        _isEqualNodeLists(node.declarations, other.declarations) &&
        isEqualTokens(node.endToken, other.endToken);
  }

  @override
  bool visitConditionalExpression(ConditionalExpression node) {
    ConditionalExpression other = _other as ConditionalExpression;
    return isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.question, other.question) &&
        isEqualNodes(node.thenExpression, other.thenExpression) &&
        isEqualTokens(node.colon, other.colon) &&
        isEqualNodes(node.elseExpression, other.elseExpression);
  }

  @override
  bool visitConstructorDeclaration(ConstructorDeclaration node) {
    ConstructorDeclaration other = _other as ConstructorDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.externalKeyword, other.externalKeyword) &&
        isEqualTokens(node.constKeyword, other.constKeyword) &&
        isEqualTokens(node.factoryKeyword, other.factoryKeyword) &&
        isEqualNodes(node.returnType, other.returnType) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.parameters, other.parameters) &&
        isEqualTokens(node.separator, other.separator) &&
        _isEqualNodeLists(node.initializers, other.initializers) &&
        isEqualNodes(node.redirectedConstructor, other.redirectedConstructor) &&
        isEqualNodes(node.body, other.body);
  }

  @override
  bool visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    ConstructorFieldInitializer other = _other as ConstructorFieldInitializer;
    return isEqualTokens(node.thisKeyword, other.thisKeyword) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.fieldName, other.fieldName) &&
        isEqualTokens(node.equals, other.equals) &&
        isEqualNodes(node.expression, other.expression);
  }

  @override
  bool visitConstructorName(ConstructorName node) {
    ConstructorName other = _other as ConstructorName;
    return isEqualNodes(node.type, other.type) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.name, other.name);
  }

  @override
  bool visitContinueStatement(ContinueStatement node) {
    ContinueStatement other = _other as ContinueStatement;
    return isEqualTokens(node.continueKeyword, other.continueKeyword) &&
        isEqualNodes(node.label, other.label) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitDeclaredIdentifier(DeclaredIdentifier node) {
    DeclaredIdentifier other = _other as DeclaredIdentifier;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.type, other.type) &&
        isEqualNodes(node.identifier, other.identifier);
  }

  @override
  bool visitDefaultFormalParameter(DefaultFormalParameter node) {
    DefaultFormalParameter other = _other as DefaultFormalParameter;
    return isEqualNodes(node.parameter, other.parameter) &&
        node.kind == other.kind &&
        isEqualTokens(node.separator, other.separator) &&
        isEqualNodes(node.defaultValue, other.defaultValue);
  }

  @override
  bool visitDoStatement(DoStatement node) {
    DoStatement other = _other as DoStatement;
    return isEqualTokens(node.doKeyword, other.doKeyword) &&
        isEqualNodes(node.body, other.body) &&
        isEqualTokens(node.whileKeyword, other.whileKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitDoubleLiteral(DoubleLiteral node) {
    DoubleLiteral other = _other as DoubleLiteral;
    return isEqualTokens(node.literal, other.literal) &&
        node.value == other.value;
  }

  @override
  bool visitEmptyFunctionBody(EmptyFunctionBody node) {
    EmptyFunctionBody other = _other as EmptyFunctionBody;
    return isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitEmptyStatement(EmptyStatement node) {
    EmptyStatement other = _other as EmptyStatement;
    return isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    EnumConstantDeclaration other = _other as EnumConstantDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualNodes(node.name, other.name);
  }

  @override
  bool visitEnumDeclaration(EnumDeclaration node) {
    EnumDeclaration other = _other as EnumDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.enumKeyword, other.enumKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.constants, other.constants) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitExportDirective(ExportDirective node) {
    ExportDirective other = _other as ExportDirective;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.uri, other.uri) &&
        _isEqualNodeLists(node.combinators, other.combinators) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitExpressionFunctionBody(ExpressionFunctionBody node) {
    ExpressionFunctionBody other = _other as ExpressionFunctionBody;
    return isEqualTokens(node.functionDefinition, other.functionDefinition) &&
        isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitExpressionStatement(ExpressionStatement node) {
    ExpressionStatement other = _other as ExpressionStatement;
    return isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitExtendsClause(ExtendsClause node) {
    ExtendsClause other = _other as ExtendsClause;
    return isEqualTokens(node.extendsKeyword, other.extendsKeyword) &&
        isEqualNodes(node.superclass, other.superclass);
  }

  @override
  bool visitFieldDeclaration(FieldDeclaration node) {
    FieldDeclaration other = _other as FieldDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.staticKeyword, other.staticKeyword) &&
        isEqualNodes(node.fields, other.fields) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitFieldFormalParameter(FieldFormalParameter node) {
    FieldFormalParameter other = _other as FieldFormalParameter;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.type, other.type) &&
        isEqualTokens(node.thisKeyword, other.thisKeyword) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.identifier, other.identifier);
  }

  @override
  bool visitForEachStatement(ForEachStatement node) {
    ForEachStatement other = _other as ForEachStatement;
    return isEqualTokens(node.forKeyword, other.forKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.loopVariable, other.loopVariable) &&
        isEqualTokens(node.inKeyword, other.inKeyword) &&
        isEqualNodes(node.iterable, other.iterable) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualNodes(node.body, other.body);
  }

  @override
  bool visitFormalParameterList(FormalParameterList node) {
    FormalParameterList other = _other as FormalParameterList;
    return isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        _isEqualNodeLists(node.parameters, other.parameters) &&
        isEqualTokens(node.leftDelimiter, other.leftDelimiter) &&
        isEqualTokens(node.rightDelimiter, other.rightDelimiter) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis);
  }

  @override
  bool visitForStatement(ForStatement node) {
    ForStatement other = _other as ForStatement;
    return isEqualTokens(node.forKeyword, other.forKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.variables, other.variables) &&
        isEqualNodes(node.initialization, other.initialization) &&
        isEqualTokens(node.leftSeparator, other.leftSeparator) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.rightSeparator, other.rightSeparator) &&
        _isEqualNodeLists(node.updaters, other.updaters) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualNodes(node.body, other.body);
  }

  @override
  bool visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionDeclaration other = _other as FunctionDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.externalKeyword, other.externalKeyword) &&
        isEqualNodes(node.returnType, other.returnType) &&
        isEqualTokens(node.propertyKeyword, other.propertyKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.functionExpression, other.functionExpression);
  }

  @override
  bool visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    FunctionDeclarationStatement other = _other as FunctionDeclarationStatement;
    return isEqualNodes(node.functionDeclaration, other.functionDeclaration);
  }

  @override
  bool visitFunctionExpression(FunctionExpression node) {
    FunctionExpression other = _other as FunctionExpression;
    return isEqualNodes(node.parameters, other.parameters) &&
        isEqualNodes(node.body, other.body);
  }

  @override
  bool visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    FunctionExpressionInvocation other = _other as FunctionExpressionInvocation;
    return isEqualNodes(node.function, other.function) &&
        isEqualNodes(node.argumentList, other.argumentList);
  }

  @override
  bool visitFunctionTypeAlias(FunctionTypeAlias node) {
    FunctionTypeAlias other = _other as FunctionTypeAlias;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.typedefKeyword, other.typedefKeyword) &&
        isEqualNodes(node.returnType, other.returnType) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.typeParameters, other.typeParameters) &&
        isEqualNodes(node.parameters, other.parameters) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    FunctionTypedFormalParameter other = _other as FunctionTypedFormalParameter;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualNodes(node.returnType, other.returnType) &&
        isEqualNodes(node.identifier, other.identifier) &&
        isEqualNodes(node.parameters, other.parameters);
  }

  @override
  bool visitHideCombinator(HideCombinator node) {
    HideCombinator other = _other as HideCombinator;
    return isEqualTokens(node.keyword, other.keyword) &&
        _isEqualNodeLists(node.hiddenNames, other.hiddenNames);
  }

  @override
  bool visitIfStatement(IfStatement node) {
    IfStatement other = _other as IfStatement;
    return isEqualTokens(node.ifKeyword, other.ifKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualNodes(node.thenStatement, other.thenStatement) &&
        isEqualTokens(node.elseKeyword, other.elseKeyword) &&
        isEqualNodes(node.elseStatement, other.elseStatement);
  }

  @override
  bool visitImplementsClause(ImplementsClause node) {
    ImplementsClause other = _other as ImplementsClause;
    return isEqualTokens(node.implementsKeyword, other.implementsKeyword) &&
        _isEqualNodeLists(node.interfaces, other.interfaces);
  }

  @override
  bool visitImportDirective(ImportDirective node) {
    ImportDirective other = _other as ImportDirective;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.uri, other.uri) &&
        isEqualTokens(node.deferredKeyword, other.deferredKeyword) &&
        isEqualTokens(node.asKeyword, other.asKeyword) &&
        isEqualNodes(node.prefix, other.prefix) &&
        _isEqualNodeLists(node.combinators, other.combinators) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitIndexExpression(IndexExpression node) {
    IndexExpression other = _other as IndexExpression;
    return isEqualNodes(node.target, other.target) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        isEqualNodes(node.index, other.index) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitInstanceCreationExpression(InstanceCreationExpression node) {
    InstanceCreationExpression other = _other as InstanceCreationExpression;
    return isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.constructorName, other.constructorName) &&
        isEqualNodes(node.argumentList, other.argumentList);
  }

  @override
  bool visitIntegerLiteral(IntegerLiteral node) {
    IntegerLiteral other = _other as IntegerLiteral;
    return isEqualTokens(node.literal, other.literal) &&
        (node.value == other.value);
  }

  @override
  bool visitInterpolationExpression(InterpolationExpression node) {
    InterpolationExpression other = _other as InterpolationExpression;
    return isEqualTokens(node.leftBracket, other.leftBracket) &&
        isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitInterpolationString(InterpolationString node) {
    InterpolationString other = _other as InterpolationString;
    return isEqualTokens(node.contents, other.contents) &&
        node.value == other.value;
  }

  @override
  bool visitIsExpression(IsExpression node) {
    IsExpression other = _other as IsExpression;
    return isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.isOperator, other.isOperator) &&
        isEqualTokens(node.notOperator, other.notOperator) &&
        isEqualNodes(node.type, other.type);
  }

  @override
  bool visitLabel(Label node) {
    Label other = _other as Label;
    return isEqualNodes(node.label, other.label) &&
        isEqualTokens(node.colon, other.colon);
  }

  @override
  bool visitLabeledStatement(LabeledStatement node) {
    LabeledStatement other = _other as LabeledStatement;
    return _isEqualNodeLists(node.labels, other.labels) &&
        isEqualNodes(node.statement, other.statement);
  }

  @override
  bool visitLibraryDirective(LibraryDirective node) {
    LibraryDirective other = _other as LibraryDirective;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.libraryKeyword, other.libraryKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitLibraryIdentifier(LibraryIdentifier node) {
    LibraryIdentifier other = _other as LibraryIdentifier;
    return _isEqualNodeLists(node.components, other.components);
  }

  @override
  bool visitListLiteral(ListLiteral node) {
    ListLiteral other = _other as ListLiteral;
    return isEqualTokens(node.constKeyword, other.constKeyword) &&
        isEqualNodes(node.typeArguments, other.typeArguments) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.elements, other.elements) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitMapLiteral(MapLiteral node) {
    MapLiteral other = _other as MapLiteral;
    return isEqualTokens(node.constKeyword, other.constKeyword) &&
        isEqualNodes(node.typeArguments, other.typeArguments) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.entries, other.entries) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitMapLiteralEntry(MapLiteralEntry node) {
    MapLiteralEntry other = _other as MapLiteralEntry;
    return isEqualNodes(node.key, other.key) &&
        isEqualTokens(node.separator, other.separator) &&
        isEqualNodes(node.value, other.value);
  }

  @override
  bool visitMethodDeclaration(MethodDeclaration node) {
    MethodDeclaration other = _other as MethodDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.externalKeyword, other.externalKeyword) &&
        isEqualTokens(node.modifierKeyword, other.modifierKeyword) &&
        isEqualNodes(node.returnType, other.returnType) &&
        isEqualTokens(node.propertyKeyword, other.propertyKeyword) &&
        isEqualTokens(node.propertyKeyword, other.propertyKeyword) &&
        isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.parameters, other.parameters) &&
        isEqualNodes(node.body, other.body);
  }

  @override
  bool visitMethodInvocation(MethodInvocation node) {
    MethodInvocation other = _other as MethodInvocation;
    return isEqualNodes(node.target, other.target) &&
        isEqualTokens(node.operator, other.operator) &&
        isEqualNodes(node.methodName, other.methodName) &&
        isEqualNodes(node.argumentList, other.argumentList);
  }

  @override
  bool visitNamedExpression(NamedExpression node) {
    NamedExpression other = _other as NamedExpression;
    return isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.expression, other.expression);
  }

  @override
  bool visitNativeClause(NativeClause node) {
    NativeClause other = _other as NativeClause;
    return isEqualTokens(node.nativeKeyword, other.nativeKeyword) &&
        isEqualNodes(node.name, other.name);
  }

  @override
  bool visitNativeFunctionBody(NativeFunctionBody node) {
    NativeFunctionBody other = _other as NativeFunctionBody;
    return isEqualTokens(node.nativeKeyword, other.nativeKeyword) &&
        isEqualNodes(node.stringLiteral, other.stringLiteral) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitNullLiteral(NullLiteral node) {
    NullLiteral other = _other as NullLiteral;
    return isEqualTokens(node.literal, other.literal);
  }

  @override
  bool visitParenthesizedExpression(ParenthesizedExpression node) {
    ParenthesizedExpression other = _other as ParenthesizedExpression;
    return isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis);
  }

  @override
  bool visitPartDirective(PartDirective node) {
    PartDirective other = _other as PartDirective;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.partKeyword, other.partKeyword) &&
        isEqualNodes(node.uri, other.uri) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitPartOfDirective(PartOfDirective node) {
    PartOfDirective other = _other as PartOfDirective;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.partKeyword, other.partKeyword) &&
        isEqualTokens(node.ofKeyword, other.ofKeyword) &&
        isEqualNodes(node.libraryName, other.libraryName) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitPostfixExpression(PostfixExpression node) {
    PostfixExpression other = _other as PostfixExpression;
    return isEqualNodes(node.operand, other.operand) &&
        isEqualTokens(node.operator, other.operator);
  }

  @override
  bool visitPrefixedIdentifier(PrefixedIdentifier node) {
    PrefixedIdentifier other = _other as PrefixedIdentifier;
    return isEqualNodes(node.prefix, other.prefix) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.identifier, other.identifier);
  }

  @override
  bool visitPrefixExpression(PrefixExpression node) {
    PrefixExpression other = _other as PrefixExpression;
    return isEqualTokens(node.operator, other.operator) &&
        isEqualNodes(node.operand, other.operand);
  }

  @override
  bool visitPropertyAccess(PropertyAccess node) {
    PropertyAccess other = _other as PropertyAccess;
    return isEqualNodes(node.target, other.target) &&
        isEqualTokens(node.operator, other.operator) &&
        isEqualNodes(node.propertyName, other.propertyName);
  }

  @override
  bool visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    RedirectingConstructorInvocation other =
        _other as RedirectingConstructorInvocation;
    return isEqualTokens(node.thisKeyword, other.thisKeyword) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.constructorName, other.constructorName) &&
        isEqualNodes(node.argumentList, other.argumentList);
  }

  @override
  bool visitRethrowExpression(RethrowExpression node) {
    RethrowExpression other = _other as RethrowExpression;
    return isEqualTokens(node.rethrowKeyword, other.rethrowKeyword);
  }

  @override
  bool visitReturnStatement(ReturnStatement node) {
    ReturnStatement other = _other as ReturnStatement;
    return isEqualTokens(node.returnKeyword, other.returnKeyword) &&
        isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitScriptTag(ScriptTag node) {
    ScriptTag other = _other as ScriptTag;
    return isEqualTokens(node.scriptTag, other.scriptTag);
  }

  @override
  bool visitShowCombinator(ShowCombinator node) {
    ShowCombinator other = _other as ShowCombinator;
    return isEqualTokens(node.keyword, other.keyword) &&
        _isEqualNodeLists(node.shownNames, other.shownNames);
  }

  @override
  bool visitSimpleFormalParameter(SimpleFormalParameter node) {
    SimpleFormalParameter other = _other as SimpleFormalParameter;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.type, other.type) &&
        isEqualNodes(node.identifier, other.identifier);
  }

  @override
  bool visitSimpleIdentifier(SimpleIdentifier node) {
    SimpleIdentifier other = _other as SimpleIdentifier;
    return isEqualTokens(node.token, other.token);
  }

  @override
  bool visitSimpleStringLiteral(SimpleStringLiteral node) {
    SimpleStringLiteral other = _other as SimpleStringLiteral;
    return isEqualTokens(node.literal, other.literal) &&
        (node.value == other.value);
  }

  @override
  bool visitStringInterpolation(StringInterpolation node) {
    StringInterpolation other = _other as StringInterpolation;
    return _isEqualNodeLists(node.elements, other.elements);
  }

  @override
  bool visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    SuperConstructorInvocation other = _other as SuperConstructorInvocation;
    return isEqualTokens(node.superKeyword, other.superKeyword) &&
        isEqualTokens(node.period, other.period) &&
        isEqualNodes(node.constructorName, other.constructorName) &&
        isEqualNodes(node.argumentList, other.argumentList);
  }

  @override
  bool visitSuperExpression(SuperExpression node) {
    SuperExpression other = _other as SuperExpression;
    return isEqualTokens(node.superKeyword, other.superKeyword);
  }

  @override
  bool visitSwitchCase(SwitchCase node) {
    SwitchCase other = _other as SwitchCase;
    return _isEqualNodeLists(node.labels, other.labels) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.colon, other.colon) &&
        _isEqualNodeLists(node.statements, other.statements);
  }

  @override
  bool visitSwitchDefault(SwitchDefault node) {
    SwitchDefault other = _other as SwitchDefault;
    return _isEqualNodeLists(node.labels, other.labels) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualTokens(node.colon, other.colon) &&
        _isEqualNodeLists(node.statements, other.statements);
  }

  @override
  bool visitSwitchStatement(SwitchStatement node) {
    SwitchStatement other = _other as SwitchStatement;
    return isEqualTokens(node.switchKeyword, other.switchKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.members, other.members) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitSymbolLiteral(SymbolLiteral node) {
    SymbolLiteral other = _other as SymbolLiteral;
    return isEqualTokens(node.poundSign, other.poundSign) &&
        _isEqualTokenLists(node.components, other.components);
  }

  @override
  bool visitThisExpression(ThisExpression node) {
    ThisExpression other = _other as ThisExpression;
    return isEqualTokens(node.thisKeyword, other.thisKeyword);
  }

  @override
  bool visitThrowExpression(ThrowExpression node) {
    ThrowExpression other = _other as ThrowExpression;
    return isEqualTokens(node.throwKeyword, other.throwKeyword) &&
        isEqualNodes(node.expression, other.expression);
  }

  @override
  bool visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    TopLevelVariableDeclaration other = _other as TopLevelVariableDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualNodes(node.variables, other.variables) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitTryStatement(TryStatement node) {
    TryStatement other = _other as TryStatement;
    return isEqualTokens(node.tryKeyword, other.tryKeyword) &&
        isEqualNodes(node.body, other.body) &&
        _isEqualNodeLists(node.catchClauses, other.catchClauses) &&
        isEqualTokens(node.finallyKeyword, other.finallyKeyword) &&
        isEqualNodes(node.finallyBlock, other.finallyBlock);
  }

  @override
  bool visitTypeArgumentList(TypeArgumentList node) {
    TypeArgumentList other = _other as TypeArgumentList;
    return isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.arguments, other.arguments) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitTypeName(TypeName node) {
    TypeName other = _other as TypeName;
    return isEqualNodes(node.name, other.name) &&
        isEqualNodes(node.typeArguments, other.typeArguments);
  }

  @override
  bool visitTypeParameter(TypeParameter node) {
    TypeParameter other = _other as TypeParameter;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualNodes(node.name, other.name) &&
        isEqualTokens(node.extendsKeyword, other.extendsKeyword) &&
        isEqualNodes(node.bound, other.bound);
  }

  @override
  bool visitTypeParameterList(TypeParameterList node) {
    TypeParameterList other = _other as TypeParameterList;
    return isEqualTokens(node.leftBracket, other.leftBracket) &&
        _isEqualNodeLists(node.typeParameters, other.typeParameters) &&
        isEqualTokens(node.rightBracket, other.rightBracket);
  }

  @override
  bool visitVariableDeclaration(VariableDeclaration node) {
    VariableDeclaration other = _other as VariableDeclaration;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualNodes(node.name, other.name) &&
        isEqualTokens(node.equals, other.equals) &&
        isEqualNodes(node.initializer, other.initializer);
  }

  @override
  bool visitVariableDeclarationList(VariableDeclarationList node) {
    VariableDeclarationList other = _other as VariableDeclarationList;
    return isEqualNodes(
            node.documentationComment, other.documentationComment) &&
        _isEqualNodeLists(node.metadata, other.metadata) &&
        isEqualTokens(node.keyword, other.keyword) &&
        isEqualNodes(node.type, other.type) &&
        _isEqualNodeLists(node.variables, other.variables);
  }

  @override
  bool visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    VariableDeclarationStatement other = _other as VariableDeclarationStatement;
    return isEqualNodes(node.variables, other.variables) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  @override
  bool visitWhileStatement(WhileStatement node) {
    WhileStatement other = _other as WhileStatement;
    return isEqualTokens(node.whileKeyword, other.whileKeyword) &&
        isEqualTokens(node.leftParenthesis, other.leftParenthesis) &&
        isEqualNodes(node.condition, other.condition) &&
        isEqualTokens(node.rightParenthesis, other.rightParenthesis) &&
        isEqualNodes(node.body, other.body);
  }

  @override
  bool visitWithClause(WithClause node) {
    WithClause other = _other as WithClause;
    return isEqualTokens(node.withKeyword, other.withKeyword) &&
        _isEqualNodeLists(node.mixinTypes, other.mixinTypes);
  }

  @override
  bool visitYieldStatement(YieldStatement node) {
    YieldStatement other = _other as YieldStatement;
    return isEqualTokens(node.yieldKeyword, other.yieldKeyword) &&
        isEqualNodes(node.expression, other.expression) &&
        isEqualTokens(node.semicolon, other.semicolon);
  }

  /**
   * Return `true` if the [first] and [second] lists of AST nodes have the same
   * size and corresponding elements are equal.
   */
  bool _isEqualNodeLists(NodeList first, NodeList second) {
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
   * Return `true` if the [first] and [second] lists of tokens have the same
   * length and corresponding elements are equal.
   */
  bool _isEqualTokenLists(List<Token> first, List<Token> second) {
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
   * Return `true` if the [first] and [second] nodes are equal.
   */
  static bool equalNodes(AstNode first, AstNode second) {
    AstComparator comparator = new AstComparator();
    return comparator.isEqualNodes(first, second);
  }
}

/**
 * A node in the AST structure for a Dart program.
 */
abstract class AstNode {
  /**
   * An empty list of AST nodes.
   */
  @deprecated // Use "AstNode.EMPTY_LIST"
  static const List<AstNode> EMPTY_ARRAY = EMPTY_LIST;

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
      (AstNode first, AstNode second) => second.offset - first.offset;

  /**
   * The parent of the node, or `null` if the node is the root of an AST
   * structure.
   */
  AstNode _parent;

  /**
   * A table mapping the names of properties to their values, or `null` if this
   * node does not have any properties associated with it.
   */
  Map<String, Object> _propertyMap;

  /**
   * Return the first token included in this node's source range.
   */
  Token get beginToken;

  /**
   * Iterate through all the entities (either AST nodes or tokens) which make
   * up the contents of this node, including doc comments but excluding other
   * comments.
   */
  Iterable /*<AstNode | Token>*/ get childEntities;

  /**
   * Return the offset of the character immediately following the last character
   * of this node's source range. This is equivalent to
   * `node.getOffset() + node.getLength()`. For a compilation unit this will be
   * equal to the length of the unit's source. For synthetic nodes this will be
   * equivalent to the node's offset (because the length is zero (0) by
   * definition).
   */
  int get end => offset + length;

  /**
   * Return the last token included in this node's source range.
   */
  Token get endToken;

  /**
   * Return `true` if this node is a synthetic node. A synthetic node is a node
   * that was introduced by the parser in order to recover from an error in the
   * code. Synthetic nodes always have a length of zero (`0`).
   */
  bool get isSynthetic => false;

  /**
   * Return the number of characters in the node's source range.
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
   * Return the offset from the beginning of the file to the first character in
   * the node's source range.
   */
  int get offset {
    Token beginToken = this.beginToken;
    if (beginToken == null) {
      return -1;
    }
    return beginToken.offset;
  }

  /**
   * Return this node's parent node, or `null` if this node is the root of an
   * AST structure.
   *
   * Note that the relationship between an AST node and its parent node may
   * change over the lifetime of a node.
   */
  AstNode get parent => _parent;

  /**
   * Set the parent of this node to the [newParent].
   */
  @deprecated // Never intended for public use.
  void set parent(AstNode newParent) {
    _parent = newParent;
  }

  /**
   * Return the node at the root of this node's AST structure. Note that this
   * method's performance is linear with respect to the depth of the node in the
   * AST structure (O(depth)).
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
   * Use the given [visitor] to visit this node. Return the value returned by
   * the visitor as a result of visiting this node.
   */
  /* <E> E */ accept(AstVisitor /*<E>*/ visitor);

  /**
   * Make this node the parent of the given [child] node. Return the child node.
   */
  @deprecated // Never intended for public use.
  AstNode becomeParentOf(AstNode child) {
    return _becomeParentOf(child);
  }

  /**
   * Return the most immediate ancestor of this node for which the [predicate]
   * returns `true`, or `null` if there is no such ancestor. Note that this node
   * will never be returned.
   */
  AstNode getAncestor(Predicate<AstNode> predicate) {
    // TODO(brianwilkerson) It is a bug that this method can return `this`.
    AstNode node = this;
    while (node != null && !predicate(node)) {
      node = node.parent;
    }
    return node;
  }

  /**
   * Return the value of the property with the given [name], or `null` if this
   * node does not have a property with the given name.
   */
  Object getProperty(String name) {
    if (_propertyMap == null) {
      return null;
    }
    return _propertyMap[name];
  }

  /**
   * If the given [child] is not `null`, use the given [visitor] to visit it.
   */
  @deprecated // Never intended for public use.
  void safelyVisitChild(AstNode child, AstVisitor visitor) {
    if (child != null) {
      child.accept(visitor);
    }
  }

  /**
   * Set the value of the property with the given [name] to the given [value].
   * If the value is `null`, the property will effectively be removed.
   */
  void setProperty(String name, Object value) {
    if (value == null) {
      if (_propertyMap != null) {
        _propertyMap.remove(name);
        if (_propertyMap.isEmpty) {
          _propertyMap = null;
        }
      }
    } else {
      if (_propertyMap == null) {
        _propertyMap = new HashMap<String, Object>();
      }
      _propertyMap[name] = value;
    }
  }

  /**
   * Return a textual description of this node in a form approximating valid
   * source. The returned string will not be valid source primarily in the case
   * where the node itself is not well-formed.
   */
  String toSource() {
    PrintStringWriter writer = new PrintStringWriter();
    accept(new ToSourceVisitor(writer));
    return writer.toString();
  }

  @override
  String toString() => toSource();

  /**
   * Use the given [visitor] to visit all of the children of this node. The
   * children will be visited in lexical order.
   */
  void visitChildren(AstVisitor visitor);

  /**
   * Make this node the parent of the given [child] node. Return the child node.
   */
  AstNode _becomeParentOf(AstNode child) {
    if (child != null) {
      child._parent = this;
    }
    return child;
  }

  /**
   * If the given [child] is not `null`, use the given [visitor] to visit it.
   */
  void _safelyVisitChild(AstNode child, AstVisitor visitor) {
    if (child != null) {
      child.accept(visitor);
    }
  }
}

/**
 * An object that can be used to visit an AST structure.
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
 * > awaitExpression ::=
 * >     'await' [Expression]
 */
class AwaitExpression extends Expression {
  /**
   * The 'await' keyword.
   */
  Token awaitKeyword;

  /**
   * The expression whose value is being waited on.
   */
  Expression _expression;

  /**
   * Initialize a newly created await expression.
   */
  AwaitExpression(this.awaitKeyword, Expression expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Token get beginToken {
    if (awaitKeyword != null) {
      return awaitKeyword;
    }
    return _expression.beginToken;
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(awaitKeyword)
    ..add(_expression);

  @override
  Token get endToken => _expression.endToken;

  /**
   * Return the expression whose value is being waited on.
   */
  Expression get expression => _expression;

  /**
   * Set the expression whose value is being waited on to the given [expression].
   */
  void set expression(Expression expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  int get precedence => 0;

  @override
  accept(AstVisitor visitor) => visitor.visitAwaitExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_expression, visitor);
  }
}

/**
 * A binary (infix) expression.
 *
 * > binaryExpression ::=
 * >     [Expression] [Token] [Expression]
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
   * The element associated with the operator based on the static type of the
   * left operand, or `null` if the AST structure has not been resolved, if the
   * operator is not user definable, or if the operator could not be resolved.
   */
  MethodElement staticElement;

  /**
   * The element associated with the operator based on the propagated type of
   * the left operand, or `null` if the AST structure has not been resolved, if
   * the operator is not user definable, or if the operator could not be
   * resolved.
   */
  MethodElement propagatedElement;

  /**
   * Initialize a newly created binary expression.
   */
  BinaryExpression(
      Expression leftOperand, this.operator, Expression rightOperand) {
    _leftOperand = _becomeParentOf(leftOperand);
    _rightOperand = _becomeParentOf(rightOperand);
  }

  @override
  Token get beginToken => _leftOperand.beginToken;

  /**
   * Return the best element available for this operator. If resolution was able
   * to find a better element based on type propagation, that element will be
   * returned. Otherwise, the element found using the result of static analysis
   * will be returned. If resolution has not been performed, then `null` will be
   * returned.
   */
  MethodElement get bestElement {
    MethodElement element = propagatedElement;
    if (element == null) {
      element = staticElement;
    }
    return element;
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(_leftOperand)
    ..add(operator)
    ..add(_rightOperand);

  @override
  Token get endToken => _rightOperand.endToken;

  /**
   * Return the expression used to compute the left operand.
   */
  Expression get leftOperand => _leftOperand;

  /**
   * Set the expression used to compute the left operand to the given
   * [expression].
   */
  void set leftOperand(Expression expression) {
    _leftOperand = _becomeParentOf(expression);
  }

  @override
  int get precedence => operator.type.precedence;

  /**
   * If the AST structure has been resolved, and the function being invoked is
   * known based on propagated type information, then return the parameter
   * element representing the parameter to which the value of the right operand
   * will be bound. Otherwise, return `null`.
   */
  @deprecated // Use "expression.propagatedParameterElement"
  ParameterElement get propagatedParameterElementForRightOperand {
    return _propagatedParameterElementForRightOperand;
  }

  /**
   * Return the expression used to compute the right operand.
   */
  Expression get rightOperand => _rightOperand;

  /**
   * Set the expression used to compute the right operand to the given
   * [expression].
   */
  void set rightOperand(Expression expression) {
    _rightOperand = _becomeParentOf(expression);
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is
   * known based on static type information, then return the parameter element
   * representing the parameter to which the value of the right operand will be
   * bound. Otherwise, return `null`.
   */
  @deprecated // Use "expression.staticParameterElement"
  ParameterElement get staticParameterElementForRightOperand {
    return _staticParameterElementForRightOperand;
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is
   * known based on propagated type information, then return the parameter
   * element representing the parameter to which the value of the right operand
   * will be bound. Otherwise, return `null`.
   */
  ParameterElement get _propagatedParameterElementForRightOperand {
    if (propagatedElement == null) {
      return null;
    }
    List<ParameterElement> parameters = propagatedElement.parameters;
    if (parameters.length < 1) {
      return null;
    }
    return parameters[0];
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is
   * known based on static type information, then return the parameter element
   * representing the parameter to which the value of the right operand will be
   * bound. Otherwise, return `null`.
   */
  ParameterElement get _staticParameterElementForRightOperand {
    if (staticElement == null) {
      return null;
    }
    List<ParameterElement> parameters = staticElement.parameters;
    if (parameters.length < 1) {
      return null;
    }
    return parameters[0];
  }

  @override
  accept(AstVisitor visitor) => visitor.visitBinaryExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_leftOperand, visitor);
    _safelyVisitChild(_rightOperand, visitor);
  }
}

/**
 * A sequence of statements.
 *
 * > block ::=
 * >     '{' statement* '}'
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
   */
  Block(this.leftBracket, List<Statement> statements, this.rightBracket) {
    _statements = new NodeList<Statement>(this, statements);
  }

  @override
  Token get beginToken => leftBracket;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(leftBracket)
    ..addAll(_statements)
    ..add(rightBracket);

  @override
  Token get endToken => rightBracket;

  /**
   * Return the statements contained in the block.
   */
  NodeList<Statement> get statements => _statements;

  @override
  accept(AstVisitor visitor) => visitor.visitBlock(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _statements.accept(visitor);
  }
}

/**
 * A function body that consists of a block of statements.
 *
 * > blockFunctionBody ::=
 * >     ('async' | 'async' '*' | 'sync' '*')? [Block]
 */
class BlockFunctionBody extends FunctionBody {
  /**
   * The token representing the 'async' or 'sync' keyword, or `null` if there is
   * no such keyword.
   */
  Token keyword;

  /**
   * The star optionally following the 'async' or 'sync' keyword, or `null` if
   * there is wither no such keyword or no star.
   */
  Token star;

  /**
   * The block representing the body of the function.
   */
  Block _block;

  /**
   * Initialize a newly created function body consisting of a block of
   * statements. The [keyword] can be `null` if there is no keyword specified
   * for the block. The [star] can be `null` if there is no star following the
   * keyword (and must be `null` if there is no keyword).
   */
  BlockFunctionBody(this.keyword, this.star, Block block) {
    _block = _becomeParentOf(block);
  }

  @override
  Token get beginToken => _block.beginToken;

  /**
   * Return the block representing the body of the function.
   */
  Block get block => _block;

  /**
   * Set the block representing the body of the function to the given [block].
   */
  void set block(Block block) {
    _block = _becomeParentOf(block);
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(keyword)
    ..add(star)
    ..add(_block);

  @override
  Token get endToken => _block.endToken;

  @override
  bool get isAsynchronous => keyword != null && keyword.lexeme == Parser.ASYNC;

  @override
  bool get isGenerator => star != null;

  @override
  bool get isSynchronous => keyword == null || keyword.lexeme != Parser.ASYNC;

  @override
  accept(AstVisitor visitor) => visitor.visitBlockFunctionBody(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_block, visitor);
  }
}

/**
 * A boolean literal expression.
 *
 * > booleanLiteral ::=
 * >     'false' | 'true'
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
   */
  BooleanLiteral(this.literal, this.value);

  @override
  Token get beginToken => literal;

  @override
  Iterable get childEntities => new ChildEntities()..add(literal);

  @override
  Token get endToken => literal;

  @override
  bool get isSynthetic => literal.isSynthetic;

  @override
  accept(AstVisitor visitor) => visitor.visitBooleanLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/**
 * An AST visitor that will recursively visit all of the nodes in an AST
 * structure, similar to [GeneralizingAstVisitor]. This visitor uses a
 * breadth-first ordering rather than the depth-first ordering of
 * [GeneralizingAstVisitor].
 *
 * Subclasses that override a visit method must either invoke the overridden
 * visit method or explicitly invoke the more general visit method. Failure to
 * do so will cause the visit methods for superclasses of the node to not be
 * invoked and will cause the children of the visited node to not be visited.
 *
 * In addition, subclasses should <b>not</b> explicitly visit the children of a
 * node, but should ensure that the method [visitNode] is used to visit the
 * children (either directly or indirectly). Failure to do will break the order
 * in which nodes are visited.
 */
class BreadthFirstVisitor<R> extends GeneralizingAstVisitor<R> {
  /**
   * A queue holding the nodes that have not yet been visited in the order in
   * which they ought to be visited.
   */
  Queue<AstNode> _queue = new Queue<AstNode>();

  /**
   * A visitor, used to visit the children of the current node, that will add
   * the nodes it visits to the [_queue].
   */
  GeneralizingAstVisitor<Object> _childVisitor;

  /**
   * Initialize a newly created visitor.
   */
  BreadthFirstVisitor() {
    _childVisitor = new GeneralizingAstVisitor_BreadthFirstVisitor(this);
  }

  /**
   * Visit all nodes in the tree starting at the given [root] node, in
   * breadth-first order.
   */
  void visitAllNodes(AstNode root) {
    _queue.add(root);
    while (!_queue.isEmpty) {
      AstNode next = _queue.removeFirst();
      next.accept(this);
    }
  }

  @override
  R visitNode(AstNode node) {
    node.visitChildren(_childVisitor);
    return null;
  }
}

/**
 * A break statement.
 *
 * > breakStatement ::=
 * >     'break' [SimpleIdentifier]? ';'
 */
class BreakStatement extends Statement {
  /**
   * The token representing the 'break' keyword.
   */
  Token breakKeyword;

  /**
   * The label associated with the statement, or `null` if there is no label.
   */
  SimpleIdentifier _label;

  /**
   * The semicolon terminating the statement.
   */
  Token semicolon;

  /**
   * The AstNode which this break statement is breaking from.  This will be
   * either a [Statement] (in the case of breaking out of a loop), a
   * [SwitchMember] (in the case of a labeled break statement whose label
   * matches a label on a switch case in an enclosing switch statement), or
   * `null` if the AST has not yet been resolved or if the target could not be
   * resolved. Note that if the source code has errors, the target might be
   * invalid (e.g. trying to break to a switch case).
   */
  AstNode target;

  /**
   * Initialize a newly created break statement. The [label] can be `null` if
   * there is no label associated with the statement.
   */
  BreakStatement(this.breakKeyword, SimpleIdentifier label, this.semicolon) {
    _label = _becomeParentOf(label);
  }

  @override
  Token get beginToken => breakKeyword;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(breakKeyword)
    ..add(_label)
    ..add(semicolon);

  @override
  Token get endToken => semicolon;

  /**
   * Return the token representing the 'break' keyword.
   */
  @deprecated // Use "this.breakKeyword"
  Token get keyword => breakKeyword;

  /**
   * Sethe token representing the 'break' keyword to the given [token].
   */
  @deprecated // Use "this.breakKeyword"
  void set keyword(Token token) {
    breakKeyword = token;
  }

  /**
   * Return the label associated with the statement, or `null` if there is no
   * label.
   */
  SimpleIdentifier get label => _label;

  /**
   * Set the label associated with the statement to the given [identifier].
   */
  void set label(SimpleIdentifier identifier) {
    _label = _becomeParentOf(identifier);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitBreakStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_label, visitor);
  }
}

/**
 * A sequence of cascaded expressions: expressions that share a common target.
 * There are three kinds of expressions that can be used in a cascade
 * expression: [IndexExpression], [MethodInvocation] and [PropertyAccess].
 *
 * > cascadeExpression ::=
 * >     [Expression] cascadeSection*
 * >
 * > cascadeSection ::=
 * >     '..'  (cascadeSelector arguments*) (assignableSelector arguments*)*
 * >     (assignmentOperator expressionWithoutCascade)?
 * >
 * > cascadeSelector ::=
 * >     '[ ' expression '] '
 * >   | identifier
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
   * Initialize a newly created cascade expression. The list of
   * [cascadeSections] must contain at least one element.
   */
  CascadeExpression(Expression target, List<Expression> cascadeSections) {
    _target = _becomeParentOf(target);
    _cascadeSections = new NodeList<Expression>(this, cascadeSections);
  }

  @override
  Token get beginToken => _target.beginToken;

  /**
   * Return the cascade sections sharing the common target.
   */
  NodeList<Expression> get cascadeSections => _cascadeSections;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(_target)
    ..addAll(_cascadeSections);

  @override
  Token get endToken => _cascadeSections.endToken;

  @override
  int get precedence => 2;

  /**
   * Return the target of the cascade sections.
   */
  Expression get target => _target;

  /**
   * Set the target of the cascade sections to the given [expression].
   */
  void set target(Expression target) {
    _target = _becomeParentOf(target);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitCascadeExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_target, visitor);
    _cascadeSections.accept(visitor);
  }
}

/**
 * A catch clause within a try statement.
 *
 * > onPart ::=
 * >     catchPart [Block]
 * >   | 'on' type catchPart? [Block]
 * >
 * > catchPart ::=
 * >     'catch' '(' [SimpleIdentifier] (',' [SimpleIdentifier])? ')'
 */
class CatchClause extends AstNode {
  /**
   * The token representing the 'on' keyword, or `null` if there is no 'on'
   * keyword.
   */
  Token onKeyword;

  /**
   * The type of exceptions caught by this catch clause, or `null` if this catch
   * clause catches every type of exception.
   */
  TypeName _exceptionType;

  /**
   * The token representing the 'catch' keyword, or `null` if there is no
   * 'catch' keyword.
   */
  Token catchKeyword;

  /**
   * The left parenthesis, or `null` if there is no 'catch' keyword.
   */
  Token leftParenthesis;

  /**
   * The parameter whose value will be the exception that was thrown, or `null`
   * if there is no 'catch' keyword.
   */
  SimpleIdentifier _exceptionParameter;

  /**
   * The comma separating the exception parameter from the stack trace
   * parameter, or `null` if there is no stack trace parameter.
   */
  Token comma;

  /**
   * The parameter whose value will be the stack trace associated with the
   * exception, or `null` if there is no stack trace parameter.
   */
  SimpleIdentifier _stackTraceParameter;

  /**
   * The right parenthesis, or `null` if there is no 'catch' keyword.
   */
  Token rightParenthesis;

  /**
   * The body of the catch block.
   */
  Block _body;

  /**
   * Initialize a newly created catch clause. The [onKeyword] and
   * [exceptionType] can be `null` if the clause will catch all exceptions. The
   * [comma] and [stackTraceParameter] can be `null` if the stack trace is not
   * referencable within the body.
   */
  CatchClause(this.onKeyword, TypeName exceptionType, this.catchKeyword,
      this.leftParenthesis, SimpleIdentifier exceptionParameter, this.comma,
      SimpleIdentifier stackTraceParameter, this.rightParenthesis, Block body) {
    _exceptionType = _becomeParentOf(exceptionType);
    _exceptionParameter = _becomeParentOf(exceptionParameter);
    _stackTraceParameter = _becomeParentOf(stackTraceParameter);
    _body = _becomeParentOf(body);
  }

  @override
  Token get beginToken {
    if (onKeyword != null) {
      return onKeyword;
    }
    return catchKeyword;
  }

  /**
   * Return the body of the catch block.
   */
  Block get body => _body;

  /**
   * Set the body of the catch block to the given [block].
   */
  void set body(Block block) {
    _body = _becomeParentOf(block);
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(onKeyword)
    ..add(_exceptionType)
    ..add(catchKeyword)
    ..add(leftParenthesis)
    ..add(_exceptionParameter)
    ..add(comma)
    ..add(_stackTraceParameter)
    ..add(rightParenthesis)
    ..add(_body);

  @override
  Token get endToken => _body.endToken;

  /**
   * Return the parameter whose value will be the exception that was thrown, or
   * `null` if there is no 'catch' keyword.
   */
  SimpleIdentifier get exceptionParameter => _exceptionParameter;

  /**
   * Set the parameter whose value will be the exception that was thrown to the
   * given [parameter].
   */
  void set exceptionParameter(SimpleIdentifier parameter) {
    _exceptionParameter = _becomeParentOf(parameter);
  }

  /**
   * Return the type of exceptions caught by this catch clause, or `null` if
   * this catch clause catches every type of exception.
   */
  TypeName get exceptionType => _exceptionType;

  /**
   * Set the type of exceptions caught by this catch clause to the given
   * [exceptionType].
   */
  void set exceptionType(TypeName exceptionType) {
    _exceptionType = _becomeParentOf(exceptionType);
  }

  /**
   * Return the parameter whose value will be the stack trace associated with
   * the exception, or `null` if there is no stack trace parameter.
   */
  SimpleIdentifier get stackTraceParameter => _stackTraceParameter;

  /**
   * Set the parameter whose value will be the stack trace associated with the
   * exception to the given [parameter].
   */
  void set stackTraceParameter(SimpleIdentifier parameter) {
    _stackTraceParameter = _becomeParentOf(parameter);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitCatchClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_exceptionType, visitor);
    _safelyVisitChild(_exceptionParameter, visitor);
    _safelyVisitChild(_stackTraceParameter, visitor);
    _safelyVisitChild(_body, visitor);
  }
}

/**
 * Helper class to allow iteration of child entities of an AST node.
 */
class ChildEntities extends Object with IterableMixin implements Iterable {
  /**
   * The list of child entities to be iterated over.
   */
  List _entities = [];

  @override
  Iterator get iterator => _entities.iterator;

  /**
   * Add an AST node or token as the next child entity, if it is not null.
   */
  void add(entity) {
    if (entity != null) {
      assert(entity is Token || entity is AstNode);
      _entities.add(entity);
    }
  }

  /**
   * Add the given items as the next child entities, if [items] is not null.
   */
  void addAll(Iterable items) {
    if (items != null) {
      _entities.addAll(items);
    }
  }
}

/**
 * The declaration of a class.
 *
 * > classDeclaration ::=
 * >     'abstract'? 'class' [SimpleIdentifier] [TypeParameterList]?
 * >     ([ExtendsClause] [WithClause]?)?
 * >     [ImplementsClause]?
 * >     '{' [ClassMember]* '}'
 */
class ClassDeclaration extends NamedCompilationUnitMember {
  /**
   * The 'abstract' keyword, or `null` if the keyword was absent.
   */
  Token abstractKeyword;

  /**
   * The token representing the 'class' keyword.
   */
  Token classKeyword;

  /**
   * The type parameters for the class, or `null` if the class does not have any
   * type parameters.
   */
  TypeParameterList _typeParameters;

  /**
   * The extends clause for the class, or `null` if the class does not extend
   * any other class.
   */
  ExtendsClause _extendsClause;

  /**
   * The with clause for the class, or `null` if the class does not have a with
   * clause.
   */
  WithClause _withClause;

  /**
   * The implements clause for the class, or `null` if the class does not
   * implement any interfaces.
   */
  ImplementsClause _implementsClause;

  /**
   * The native clause for the class, or `null` if the class does not have a
   * native clause.
   */
  NativeClause _nativeClause;

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
   * Initialize a newly created class declaration. Either or both of the
   * [comment] and [metadata] can be `null` if the class does not have the
   * corresponding attribute. The [abstractKeyword] can be `null` if the class
   * is not abstract. The [typeParameters] can be `null` if the class does not
   * have any type parameters. Any or all of the [extendsClause], [withClause],
   * and [implementsClause] can be `null` if the class does not have the
   * corresponding clause. The list of [members] can be `null` if the class does
   * not have any members.
   */
  ClassDeclaration(Comment comment, List<Annotation> metadata,
      this.abstractKeyword, this.classKeyword, SimpleIdentifier name,
      TypeParameterList typeParameters, ExtendsClause extendsClause,
      WithClause withClause, ImplementsClause implementsClause,
      this.leftBracket, List<ClassMember> members, this.rightBracket)
      : super(comment, metadata, name) {
    _typeParameters = _becomeParentOf(typeParameters);
    _extendsClause = _becomeParentOf(extendsClause);
    _withClause = _becomeParentOf(withClause);
    _implementsClause = _becomeParentOf(implementsClause);
    _members = new NodeList<ClassMember>(this, members);
  }

  @override
  Iterable get childEntities => super._childEntities
    ..add(abstractKeyword)
    ..add(classKeyword)
    ..add(_name)
    ..add(_typeParameters)
    ..add(_extendsClause)
    ..add(_withClause)
    ..add(_implementsClause)
    ..add(_nativeClause)
    ..add(leftBracket)
    ..addAll(members)
    ..add(rightBracket);

  @override
  ClassElement get element =>
      _name != null ? (_name.staticElement as ClassElement) : null;

  @override
  Token get endToken => rightBracket;

  /**
   * Return the extends clause for this class, or `null` if the class does not
   * extend any other class.
   */
  ExtendsClause get extendsClause => _extendsClause;

  /**
   * Set the extends clause for this class to the given [extendsClause].
   */
  void set extendsClause(ExtendsClause extendsClause) {
    _extendsClause = _becomeParentOf(extendsClause);
  }

  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (abstractKeyword != null) {
      return abstractKeyword;
    }
    return classKeyword;
  }

  /**
   * Return the implements clause for the class, or `null` if the class does not
   * implement any interfaces.
   */
  ImplementsClause get implementsClause => _implementsClause;

  /**
   * Set the implements clause for the class to the given [implementsClause].
   */
  void set implementsClause(ImplementsClause implementsClause) {
    _implementsClause = _becomeParentOf(implementsClause);
  }

  /**
   * Return `true` if this class is declared to be an abstract class.
   */
  bool get isAbstract => abstractKeyword != null;

  /**
   * Return the members defined by the class.
   */
  NodeList<ClassMember> get members => _members;

  /**
   * Return the native clause for this class, or `null` if the class does not
   * have a native clause.
   */
  NativeClause get nativeClause => _nativeClause;

  /**
   * Set the native clause for this class to the given [nativeClause].
   */
  void set nativeClause(NativeClause nativeClause) {
    _nativeClause = _becomeParentOf(nativeClause);
  }

  /**
   * Return the type parameters for the class, or `null` if the class does not
   * have any type parameters.
   */
  TypeParameterList get typeParameters => _typeParameters;

  /**
   * Set the type parameters for the class to the given list of [typeParameters].
   */
  void set typeParameters(TypeParameterList typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  /**
   * Return the with clause for the class, or `null` if the class does not have
   * a with clause.
   */
  WithClause get withClause => _withClause;

  /**
   * Set the with clause for the class to the given [withClause].
   */
  void set withClause(WithClause withClause) {
    _withClause = _becomeParentOf(withClause);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitClassDeclaration(this);

  /**
   * Return the constructor declared in the class with the given [name], or
   * `null` if there is no such constructor. If the [name] is `null` then the
   * default constructor will be searched for.
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

  /**
   * Return the field declared in the class with the given [name], or `null` if
   * there is no such field.
   */
  VariableDeclaration getField(String name) {
    for (ClassMember classMember in _members) {
      if (classMember is FieldDeclaration) {
        FieldDeclaration fieldDeclaration = classMember;
        NodeList<VariableDeclaration> fields =
            fieldDeclaration.fields.variables;
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
   * Return the method declared in the class with the given [name], or `null` if
   * there is no such method.
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

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_name, visitor);
    _safelyVisitChild(_typeParameters, visitor);
    _safelyVisitChild(_extendsClause, visitor);
    _safelyVisitChild(_withClause, visitor);
    _safelyVisitChild(_implementsClause, visitor);
    _safelyVisitChild(_nativeClause, visitor);
    members.accept(visitor);
  }
}

/**
 * A node that declares a name within the scope of a class.
 */
abstract class ClassMember extends Declaration {
  /**
   * Initialize a newly created member of a class. Either or both of the
   * [comment] and [metadata] can be `null` if the member does not have the
   * corresponding attribute.
   */
  ClassMember(Comment comment, List<Annotation> metadata)
      : super(comment, metadata);
}

/**
 * A class type alias.
 *
 * > classTypeAlias ::=
 * >     [SimpleIdentifier] [TypeParameterList]? '=' 'abstract'? mixinApplication
 * >
 * > mixinApplication ::=
 * >     [TypeName] [WithClause] [ImplementsClause]? ';'
 */
class ClassTypeAlias extends TypeAlias {
  /**
   * The type parameters for the class, or `null` if the class does not have any
   * type parameters.
   */
  TypeParameterList _typeParameters;

  /**
   * The token for the '=' separating the name from the definition.
   */
  Token equals;

  /**
   * The token for the 'abstract' keyword, or `null` if this is not defining an
   * abstract class.
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
   * The implements clause for this class, or `null` if there is no implements
   * clause.
   */
  ImplementsClause _implementsClause;

  /**
   * Initialize a newly created class type alias. Either or both of the
   * [comment] and [metadata] can be `null` if the class type alias does not
   * have the corresponding attribute. The [typeParameters] can be `null` if the
   * class does not have any type parameters. The [abstractKeyword] can be
   * `null` if the class is not abstract. The [implementsClause] can be `null`
   * if the class does not implement any interfaces.
   */
  ClassTypeAlias(Comment comment, List<Annotation> metadata, Token keyword,
      SimpleIdentifier name, TypeParameterList typeParameters, this.equals,
      this.abstractKeyword, TypeName superclass, WithClause withClause,
      ImplementsClause implementsClause, Token semicolon)
      : super(comment, metadata, keyword, name, semicolon) {
    _typeParameters = _becomeParentOf(typeParameters);
    _superclass = _becomeParentOf(superclass);
    _withClause = _becomeParentOf(withClause);
    _implementsClause = _becomeParentOf(implementsClause);
  }

  @override
  Iterable get childEntities => super._childEntities
    ..add(typedefKeyword)
    ..add(_name)
    ..add(_typeParameters)
    ..add(equals)
    ..add(abstractKeyword)
    ..add(_superclass)
    ..add(_withClause)
    ..add(_implementsClause)
    ..add(semicolon);

  @override
  ClassElement get element =>
      _name != null ? (_name.staticElement as ClassElement) : null;

  /**
   * Return the implements clause for this class, or `null` if there is no
   * implements clause.
   */
  ImplementsClause get implementsClause => _implementsClause;

  /**
   * Set the implements clause for this class to the given [implementsClause].
   */
  void set implementsClause(ImplementsClause implementsClause) {
    _implementsClause = _becomeParentOf(implementsClause);
  }

  /**
   * Return `true` if this class is declared to be an abstract class.
   */
  bool get isAbstract => abstractKeyword != null;

  /**
   * Return the name of the superclass of the class being declared.
   */
  TypeName get superclass => _superclass;

  /**
   * Set the name of the superclass of the class being declared to the given
   * [superclass] name.
   */
  void set superclass(TypeName superclass) {
    _superclass = _becomeParentOf(superclass);
  }

  /**
   * Return the type parameters for the class, or `null` if the class does not
   * have any type parameters.
   */
  TypeParameterList get typeParameters => _typeParameters;

  /**
   * Set the type parameters for the class to the given list of [typeParameters].
   */
  void set typeParameters(TypeParameterList typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  /**
   * Return the with clause for this class.
   */
  WithClause get withClause => _withClause;

  /**
   * Set the with clause for this class to the given with [withClause].
   */
  void set withClause(WithClause withClause) {
    _withClause = _becomeParentOf(withClause);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitClassTypeAlias(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_name, visitor);
    _safelyVisitChild(_typeParameters, visitor);
    _safelyVisitChild(_superclass, visitor);
    _safelyVisitChild(_withClause, visitor);
    _safelyVisitChild(_implementsClause, visitor);
  }
}

/**
 * A combinator associated with an import or export directive.
 *
 * > combinator ::=
 * >     [HideCombinator]
 * >   | [ShowCombinator]
 */
abstract class Combinator extends AstNode {
  /**
   * The 'hide' or 'show' keyword specifying what kind of processing is to be
   * done on the names.
   */
  Token keyword;

  /**
   * Initialize a newly created combinator.
   */
  Combinator(this.keyword);

  @override
  Token get beginToken => keyword;
}

/**
 * A comment within the source code.
 *
 * > comment ::=
 * >     endOfLineComment
 * >   | blockComment
 * >   | documentationComment
 * >
 * > endOfLineComment ::=
 * >     '//' (CHARACTER - EOL)* EOL
 * >
 * > blockComment ::=
 * >     '/ *' CHARACTER* '&#42;/'
 * >
 * > documentationComment ::=
 * >     '/ **' (CHARACTER | [CommentReference])* '&#42;/'
 * >   | ('///' (CHARACTER - EOL)* EOL)+
 */
class Comment extends AstNode {
  /**
   * The tokens representing the comment.
   */
  final List<Token> tokens;

  /**
   * The type of the comment.
   */
  final CommentType _type;

  /**
   * The references embedded within the documentation comment. This list will be
   * empty unless this is a documentation comment that has references embedded
   * within it.
   */
  NodeList<CommentReference> _references;

  /**
   * Initialize a newly created comment. The list of [tokens] must contain at
   * least one token. The [type] is the type of the comment. The list of
   * [references] can be empty if the comment does not contain any embedded
   * references.
   */
  Comment(this.tokens, this._type, List<CommentReference> references) {
    _references = new NodeList<CommentReference>(this, references);
  }

  @override
  Token get beginToken => tokens[0];

  @override
  Iterable get childEntities => new ChildEntities()..addAll(tokens);

  @override
  Token get endToken => tokens[tokens.length - 1];

  /**
   * Return `true` if this is a block comment.
   */
  bool get isBlock => _type == CommentType.BLOCK;

  /**
   * Return `true` if this is a documentation comment.
   */
  bool get isDocumentation => _type == CommentType.DOCUMENTATION;

  /**
   * Return `true` if this is an end-of-line comment.
   */
  bool get isEndOfLine => _type == CommentType.END_OF_LINE;

  /**
   * Return the references embedded within the documentation comment.
   */
  NodeList<CommentReference> get references => _references;

  @override
  accept(AstVisitor visitor) => visitor.visitComment(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _references.accept(visitor);
  }

  /**
   * Create a block comment consisting of the given [tokens].
   */
  static Comment createBlockComment(List<Token> tokens) =>
      new Comment(tokens, CommentType.BLOCK, null);

  /**
   * Create a documentation comment consisting of the given [tokens].
   */
  static Comment createDocumentationComment(List<Token> tokens) => new Comment(
      tokens, CommentType.DOCUMENTATION, new List<CommentReference>());

  /**
   * Create a documentation comment consisting of the given [tokens] and having
   * the given [references] embedded within it.
   */
  static Comment createDocumentationCommentWithReferences(
          List<Token> tokens, List<CommentReference> references) =>
      new Comment(tokens, CommentType.DOCUMENTATION, references);

  /**
   * Create an end-of-line comment consisting of the given [tokens].
   */
  static Comment createEndOfLineComment(List<Token> tokens) =>
      new Comment(tokens, CommentType.END_OF_LINE, null);
}

/**
 * A reference to a Dart element that is found within a documentation comment.
 *
 * > commentReference ::=
 * >     '[' 'new'? [Identifier] ']'
 */
class CommentReference extends AstNode {
  /**
   * The token representing the 'new' keyword, or `null` if there was no 'new'
   * keyword.
   */
  Token newKeyword;

  /**
   * The identifier being referenced.
   */
  Identifier _identifier;

  /**
   * Initialize a newly created reference to a Dart element. The [newKeyword]
   * can be `null` if the reference is not to a constructor.
   */
  CommentReference(this.newKeyword, Identifier identifier) {
    _identifier = _becomeParentOf(identifier);
  }

  @override
  Token get beginToken => _identifier.beginToken;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(newKeyword)
    ..add(_identifier);

  @override
  Token get endToken => _identifier.endToken;

  /**
   * Return the identifier being referenced.
   */
  Identifier get identifier => _identifier;

  /**
   * Set the identifier being referenced to the given [identifier].
   */
  void set identifier(Identifier identifier) {
    _identifier = _becomeParentOf(identifier);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitCommentReference(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_identifier, visitor);
  }
}

/**
 * The possible types of comments that are recognized by the parser.
 */
class CommentType {
  /**
   * A block comment.
   */
  static const CommentType BLOCK = const CommentType('BLOCK');

  /**
   * A documentation comment.
   */
  static const CommentType DOCUMENTATION = const CommentType('DOCUMENTATION');

  /**
   * An end-of-line comment.
   */
  static const CommentType END_OF_LINE = const CommentType('END_OF_LINE');

  /**
   * The name of the comment type.
   */
  final String name;

  /**
   * Initialize a newly created comment type to have the given [name].
   */
  const CommentType(this.name);

  @override
  String toString() => name;
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
 * > compilationUnit ::=
 * >     directives declarations
 * >
 * > directives ::=
 * >     [ScriptTag]? [LibraryDirective]? namespaceDirective* [PartDirective]*
 * >   | [PartOfDirective]
 * >
 * > namespaceDirective ::=
 * >     [ImportDirective]
 * >   | [ExportDirective]
 * >
 * > declarations ::=
 * >     [CompilationUnitMember]*
 */
class CompilationUnit extends AstNode {
  /**
   * The first token in the token stream that was parsed to form this
   * compilation unit.
   */
  Token beginToken;

  /**
   * The script tag at the beginning of the compilation unit, or `null` if there
   * is no script tag in this compilation unit.
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
   * The last token in the token stream that was parsed to form this compilation
   * unit. This token should always have a type of [TokenType.EOF].
   */
  final Token endToken;

  /**
   * The element associated with this compilation unit, or `null` if the AST
   * structure has not been resolved.
   */
  CompilationUnitElement element;

  /**
   * The line information for this compilation unit.
   */
  LineInfo lineInfo;

  /**
   * Initialize a newly created compilation unit to have the given directives
   * and declarations. The [scriptTag] can be `null` if there is no script tag
   * in the compilation unit. The list of [directives] can be `null` if there
   * are no directives in the compilation unit. The list of [declarations] can
   * be `null` if there are no declarations in the compilation unit.
   */
  CompilationUnit(this.beginToken, ScriptTag scriptTag,
      List<Directive> directives, List<CompilationUnitMember> declarations,
      this.endToken) {
    _scriptTag = _becomeParentOf(scriptTag);
    _directives = new NodeList<Directive>(this, directives);
    _declarations = new NodeList<CompilationUnitMember>(this, declarations);
  }

  @override
  Iterable get childEntities {
    ChildEntities result = new ChildEntities()..add(_scriptTag);
    if (_directivesAreBeforeDeclarations) {
      result
        ..addAll(_directives)
        ..addAll(_declarations);
    } else {
      result.addAll(sortedDirectivesAndDeclarations);
    }
    return result;
  }

  /**
   * Return the declarations contained in this compilation unit.
   */
  NodeList<CompilationUnitMember> get declarations => _declarations;

  /**
   * Return the directives contained in this compilation unit.
   */
  NodeList<Directive> get directives => _directives;

  @override
  int get length {
    Token endToken = this.endToken;
    if (endToken == null) {
      return 0;
    }
    return endToken.offset + endToken.length;
  }

  @override
  int get offset => 0;

  /**
   * Return the script tag at the beginning of the compilation unit, or `null`
   * if there is no script tag in this compilation unit.
   */
  ScriptTag get scriptTag => _scriptTag;

  /**
   * Set the script tag at the beginning of the compilation unit to the given
   * [scriptTag].
   */
  void set scriptTag(ScriptTag scriptTag) {
    _scriptTag = _becomeParentOf(scriptTag);
  }

  /**
   * Return a list containing all of the directives and declarations in this
   * compilation unit, sorted in lexical order.
   */
  List<AstNode> get sortedDirectivesAndDeclarations {
    return <AstNode>[]
      ..addAll(_directives)
      ..addAll(_declarations)
      ..sort(AstNode.LEXICAL_ORDER);
  }

  /**
   * Return `true` if all of the directives are lexically before any
   * declarations.
   */
  bool get _directivesAreBeforeDeclarations {
    if (_directives.isEmpty || _declarations.isEmpty) {
      return true;
    }
    Directive lastDirective = _directives[_directives.length - 1];
    CompilationUnitMember firstDeclaration = _declarations[0];
    return lastDirective.offset < firstDeclaration.offset;
  }

  @override
  accept(AstVisitor visitor) => visitor.visitCompilationUnit(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_scriptTag, visitor);
    if (_directivesAreBeforeDeclarations) {
      _directives.accept(visitor);
      _declarations.accept(visitor);
    } else {
      for (AstNode child in sortedDirectivesAndDeclarations) {
        child.accept(visitor);
      }
    }
  }
}

/**
 * A node that declares one or more names within the scope of a compilation
 * unit.
 *
 * > compilationUnitMember ::=
 * >     [ClassDeclaration]
 * >   | [TypeAlias]
 * >   | [FunctionDeclaration]
 * >   | [MethodDeclaration]
 * >   | [VariableDeclaration]
 * >   | [VariableDeclaration]
 */
abstract class CompilationUnitMember extends Declaration {
  /**
   * Initialize a newly created generic compilation unit member. Either or both
   * of the [comment] and [metadata] can be `null` if the member does not have
   * the corresponding attribute.
   */
  CompilationUnitMember(Comment comment, List<Annotation> metadata)
      : super(comment, metadata);
}

/**
 * A conditional expression.
 *
 * > conditionalExpression ::=
 * >     [Expression] '?' [Expression] ':' [Expression]
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
   */
  ConditionalExpression(Expression condition, this.question,
      Expression thenExpression, this.colon, Expression elseExpression) {
    _condition = _becomeParentOf(condition);
    _thenExpression = _becomeParentOf(thenExpression);
    _elseExpression = _becomeParentOf(elseExpression);
  }

  @override
  Token get beginToken => _condition.beginToken;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(_condition)
    ..add(question)
    ..add(_thenExpression)
    ..add(colon)
    ..add(_elseExpression);

  /**
   * Return the condition used to determine which of the expressions is executed
   * next.
   */
  Expression get condition => _condition;

  /**
   * Set the condition used to determine which of the expressions is executed
   * next to the given [expression].
   */
  void set condition(Expression expression) {
    _condition = _becomeParentOf(expression);
  }

  /**
   * Return the expression that is executed if the condition evaluates to
   * `false`.
   */
  Expression get elseExpression => _elseExpression;

  /**
   * Set the expression that is executed if the condition evaluates to `false`
   * to the given [expression].
   */
  void set elseExpression(Expression expression) {
    _elseExpression = _becomeParentOf(expression);
  }

  @override
  Token get endToken => _elseExpression.endToken;

  @override
  int get precedence => 3;

  /**
   * Return the expression that is executed if the condition evaluates to
   * `true`.
   */
  Expression get thenExpression => _thenExpression;

  /**
   * Set the expression that is executed if the condition evaluates to `true` to
   * the given [expression].
   */
  void set thenExpression(Expression expression) {
    _thenExpression = _becomeParentOf(expression);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitConditionalExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_condition, visitor);
    _safelyVisitChild(_thenExpression, visitor);
    _safelyVisitChild(_elseExpression, visitor);
  }
}

/**
 * An object that can be used to evaluate constant expressions to produce their
 * compile-time value. According to the Dart Language Specification:
 * <blockquote>
 * A constant expression is one of the following:
 * * A literal number.
 * * A literal boolean.
 * * A literal string where any interpolated expression is a compile-time
 *   constant that evaluates to a numeric, string or boolean value or to `null`.
 * * `null`.
 * * A reference to a static constant variable.
 * * An identifier expression that denotes a constant variable, a class or a
 *   type parameter.
 * * A constant constructor invocation.
 * * A constant list literal.
 * * A constant map literal.
 * * A simple or qualified identifier denoting a top-level function or a static
 *   method.
 * * A parenthesized expression `(e)` where `e` is a constant expression.
 * * An expression of one of the forms `identical(e1, e2)`, `e1 == e2`,
 *   `e1 != e2` where `e1` and `e2` are constant expressions that evaluate to a
 *   numeric, string or boolean value or to `null`.
 * * An expression of one of the forms `!e`, `e1 && e2` or `e1 || e2`, where
 *   `e`, `e1` and `e2` are constant expressions that evaluate to a boolean
 *   value or to `null`.
 * * An expression of one of the forms `~e`, `e1 ^ e2`, `e1 & e2`, `e1 | e2`,
 *   `e1 >> e2` or `e1 << e2`, where `e`, `e1` and `e2` are constant expressions
 *   that evaluate to an integer value or to `null`.
 * * An expression of one of the forms `-e`, `e1 + e2`, `e1 - e2`, `e1 * e2`,
 *   `e1 / e2`, `e1 ~/ e2`, `e1 > e2`, `e1 < e2`, `e1 >= e2`, `e1 <= e2` or
 *   `e1 % e2`, where `e`, `e1` and `e2` are constant expressions that evaluate
 *   to a numeric value or to `null`.
 * </blockquote>
 * The values returned by instances of this class are therefore `null` and
 * instances of the classes `Boolean`, `BigInteger`, `Double`, `String`, and
 * `DartObject`.
 *
 * In addition, this class defines several values that can be returned to
 * indicate various conditions encountered during evaluation. These are
 * documented with the static fields that define those values.
 */
class ConstantEvaluator extends GeneralizingAstVisitor<Object> {
  /**
   * The value returned for expressions (or non-expression nodes) that are not
   * compile-time constant expressions.
   */
  static Object NOT_A_CONSTANT = new Object();

  @override
  Object visitAdjacentStrings(AdjacentStrings node) {
    StringBuffer buffer = new StringBuffer();
    for (StringLiteral string in node.strings) {
      Object value = string.accept(this);
      if (identical(value, NOT_A_CONSTANT)) {
        return value;
      }
      buffer.write(value);
    }
    return buffer.toString();
  }

  @override
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
        } else if (leftOperand is num && rightOperand is num) {
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
          return leftOperand == rightOperand;
        } else if (leftOperand is num && rightOperand is num) {
          return leftOperand == rightOperand;
        } else if (leftOperand is String && rightOperand is String) {
          return leftOperand == rightOperand;
        }
      } else if (node.operator.type == TokenType.GT) {
        // numeric or {@code null}
        if (leftOperand is num && rightOperand is num) {
          return leftOperand.compareTo(rightOperand) > 0;
        }
      } else if (node.operator.type == TokenType.GT_EQ) {
        // numeric or {@code null}
        if (leftOperand is num && rightOperand is num) {
          return leftOperand.compareTo(rightOperand) >= 0;
        }
      } else if (node.operator.type == TokenType.GT_GT) {
        // integer or {@code null}
        if (leftOperand is int && rightOperand is int) {
          return leftOperand >> rightOperand;
        }
      } else if (node.operator.type == TokenType.LT) {
        // numeric or {@code null}
        if (leftOperand is num && rightOperand is num) {
          return leftOperand.compareTo(rightOperand) < 0;
        }
      } else if (node.operator.type == TokenType.LT_EQ) {
        // numeric or {@code null}
        if (leftOperand is num && rightOperand is num) {
          return leftOperand.compareTo(rightOperand) <= 0;
        }
      } else if (node.operator.type == TokenType.LT_LT) {
        // integer or {@code null}
        if (leftOperand is int && rightOperand is int) {
          return leftOperand << rightOperand;
        }
      } else if (node.operator.type == TokenType.MINUS) {
        // numeric or {@code null}
        if (leftOperand is num && rightOperand is num) {
          return leftOperand - rightOperand;
        }
      } else if (node.operator.type == TokenType.PERCENT) {
        // numeric or {@code null}
        if (leftOperand is num && rightOperand is num) {
          return leftOperand.remainder(rightOperand);
        }
      } else if (node.operator.type == TokenType.PLUS) {
        // numeric or {@code null}
        if (leftOperand is num && rightOperand is num) {
          return leftOperand + rightOperand;
        }
      } else if (node.operator.type == TokenType.STAR) {
        // numeric or {@code null}
        if (leftOperand is num && rightOperand is num) {
          return leftOperand * rightOperand;
        }
      } else if (node.operator.type == TokenType.SLASH) {
        // numeric or {@code null}
        if (leftOperand is num && rightOperand is num) {
          return leftOperand / rightOperand;
        }
      } else if (node.operator.type == TokenType.TILDE_SLASH) {
        // numeric or {@code null}
        if (leftOperand is num && rightOperand is num) {
          return leftOperand ~/ rightOperand;
        }
      } else {}
      break;
    }
    // TODO(brianwilkerson) This doesn't handle numeric conversions.
    return visitExpression(node);
  }

  @override
  Object visitBooleanLiteral(BooleanLiteral node) => node.value ? true : false;

  @override
  Object visitDoubleLiteral(DoubleLiteral node) => node.value;

  @override
  Object visitIntegerLiteral(IntegerLiteral node) => node.value;

  @override
  Object visitInterpolationExpression(InterpolationExpression node) {
    Object value = node.expression.accept(this);
    if (value == null || value is bool || value is String || value is num) {
      return value;
    }
    return NOT_A_CONSTANT;
  }

  @override
  Object visitInterpolationString(InterpolationString node) => node.value;

  @override
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

  @override
  Object visitMapLiteral(MapLiteral node) {
    HashMap<String, Object> map = new HashMap<String, Object>();
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

  @override
  Object visitMethodInvocation(MethodInvocation node) => visitNode(node);

  @override
  Object visitNode(AstNode node) => NOT_A_CONSTANT;

  @override
  Object visitNullLiteral(NullLiteral node) => null;

  @override
  Object visitParenthesizedExpression(ParenthesizedExpression node) =>
      node.expression.accept(this);

  @override
  Object visitPrefixedIdentifier(PrefixedIdentifier node) =>
      _getConstantValue(null);

  @override
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
        } else if (operand is num) {
          return -operand;
        }
      } else {}
      break;
    }
    return NOT_A_CONSTANT;
  }

  @override
  Object visitPropertyAccess(PropertyAccess node) => _getConstantValue(null);

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) =>
      _getConstantValue(null);

  @override
  Object visitSimpleStringLiteral(SimpleStringLiteral node) => node.value;

  @override
  Object visitStringInterpolation(StringInterpolation node) {
    StringBuffer buffer = new StringBuffer();
    for (InterpolationElement element in node.elements) {
      Object value = element.accept(this);
      if (identical(value, NOT_A_CONSTANT)) {
        return value;
      }
      buffer.write(value);
    }
    return buffer.toString();
  }

  @override
  Object visitSymbolLiteral(SymbolLiteral node) {
    // TODO(brianwilkerson) This isn't optimal because a Symbol is not a String.
    StringBuffer buffer = new StringBuffer();
    for (Token component in node.components) {
      if (buffer.length > 0) {
        buffer.writeCharCode(0x2E);
      }
      buffer.write(component.lexeme);
    }
    return buffer.toString();
  }

  /**
   * Return the constant value of the static constant represented by the given
   * [element].
   */
  Object _getConstantValue(Element element) {
    // TODO(brianwilkerson) Implement this
    if (element is FieldElement) {
      FieldElement field = element;
      if (field.isStatic && field.isConst) {
        //field.getConstantValue();
      }
      //    } else if (element instanceof VariableElement) {
      //      VariableElement variable = (VariableElement) element;
      //      if (variable.isStatic() && variable.isConst()) {
      //        //variable.getConstantValue();
      //      }
    }
    return NOT_A_CONSTANT;
  }
}

/**
 * Object representing a "const" instance creation expression, and its
 * evaluation result.  This is used as the AnalysisTarget for constant
 * evaluation of instance creation expressions.
 */
class ConstantInstanceCreationHandle {
  /**
   * The result of evaluating the constant.
   */
  EvaluationResultImpl evaluationResult;
}

/**
 * A constructor declaration.
 *
 * > constructorDeclaration ::=
 * >     constructorSignature [FunctionBody]?
 * >   | constructorName formalParameterList ':' 'this' ('.' [SimpleIdentifier])? arguments
 * >
 * > constructorSignature ::=
 * >     'external'? constructorName formalParameterList initializerList?
 * >   | 'external'? 'factory' factoryName formalParameterList initializerList?
 * >   | 'external'? 'const'  constructorName formalParameterList initializerList?
 * >
 * > constructorName ::=
 * >     [SimpleIdentifier] ('.' [SimpleIdentifier])?
 * >
 * > factoryName ::=
 * >     [Identifier] ('.' [SimpleIdentifier])?
 * >
 * > initializerList ::=
 * >     ':' [ConstructorInitializer] (',' [ConstructorInitializer])*
 */
class ConstructorDeclaration extends ClassMember {
  /**
   * The token for the 'external' keyword, or `null` if the constructor is not
   * external.
   */
  Token externalKeyword;

  /**
   * The token for the 'const' keyword, or `null` if the constructor is not a
   * const constructor.
   */
  Token constKeyword;

  /**
   * The token for the 'factory' keyword, or `null` if the constructor is not a
   * factory constructor.
   */
  Token factoryKeyword;

  /**
   * The type of object being created. This can be different than the type in
   * which the constructor is being declared if the constructor is the
   * implementation of a factory constructor.
   */
  Identifier _returnType;

  /**
   * The token for the period before the constructor name, or `null` if the
   * constructor being declared is unnamed.
   */
  Token period;

  /**
   * The name of the constructor, or `null` if the constructor being declared is
   * unnamed.
   */
  SimpleIdentifier _name;

  /**
   * The parameters associated with the constructor.
   */
  FormalParameterList _parameters;

  /**
   * The token for the separator (colon or equals) before the initializer list
   * or redirection, or `null` if there are no initializers.
   */
  Token separator;

  /**
   * The initializers associated with the constructor.
   */
  NodeList<ConstructorInitializer> _initializers;

  /**
   * The name of the constructor to which this constructor will be redirected,
   * or `null` if this is not a redirecting factory constructor.
   */
  ConstructorName _redirectedConstructor;

  /**
   * The body of the constructor, or `null` if the constructor does not have a
   * body.
   */
  FunctionBody _body;

  /**
   * The element associated with this constructor, or `null` if the AST
   * structure has not been resolved or if this constructor could not be
   * resolved.
   */
  ConstructorElement element;

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
  ConstructorDeclaration(Comment comment, List<Annotation> metadata,
      this.externalKeyword, this.constKeyword, this.factoryKeyword,
      Identifier returnType, this.period, SimpleIdentifier name,
      FormalParameterList parameters, this.separator,
      List<ConstructorInitializer> initializers,
      ConstructorName redirectedConstructor, FunctionBody body)
      : super(comment, metadata) {
    _returnType = _becomeParentOf(returnType);
    _name = _becomeParentOf(name);
    _parameters = _becomeParentOf(parameters);
    _initializers = new NodeList<ConstructorInitializer>(this, initializers);
    _redirectedConstructor = _becomeParentOf(redirectedConstructor);
    _body = _becomeParentOf(body);
  }

  /**
   * Return the body of the constructor, or `null` if the constructor does not
   * have a body.
   */
  FunctionBody get body => _body;

  /**
   * Set the body of the constructor to the given [functionBody].
   */
  void set body(FunctionBody functionBody) {
    _body = _becomeParentOf(functionBody);
  }

  @override
  Iterable get childEntities => super._childEntities
    ..add(externalKeyword)
    ..add(constKeyword)
    ..add(factoryKeyword)
    ..add(_returnType)
    ..add(period)
    ..add(_name)
    ..add(_parameters)
    ..add(separator)
    ..addAll(initializers)
    ..add(_redirectedConstructor)
    ..add(_body);

  @override
  Token get endToken {
    if (_body != null) {
      return _body.endToken;
    } else if (!_initializers.isEmpty) {
      return _initializers.endToken;
    }
    return _parameters.endToken;
  }

  @override
  Token get firstTokenAfterCommentAndMetadata {
    Token leftMost =
        Token.lexicallyFirst([externalKeyword, constKeyword, factoryKeyword]);
    if (leftMost != null) {
      return leftMost;
    }
    return _returnType.beginToken;
  }

  /**
   * Return the initializers associated with the constructor.
   */
  NodeList<ConstructorInitializer> get initializers => _initializers;

  /**
   * Return the name of the constructor, or `null` if the constructor being
   * declared is unnamed.
   */
  SimpleIdentifier get name => _name;

  /**
   * Set the name of the constructor to the given [identifier].
   */
  void set name(SimpleIdentifier identifier) {
    _name = _becomeParentOf(identifier);
  }

  /**
   * Return the parameters associated with the constructor.
   */
  FormalParameterList get parameters => _parameters;

  /**
   * Set the parameters associated with the constructor to the given list of
   * [parameters].
   */
  void set parameters(FormalParameterList parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  /**
   * Return the name of the constructor to which this constructor will be
   * redirected, or `null` if this is not a redirecting factory constructor.
   */
  ConstructorName get redirectedConstructor => _redirectedConstructor;

  /**
   * Set the name of the constructor to which this constructor will be
   * redirected to the given [redirectedConstructor] name.
   */
  void set redirectedConstructor(ConstructorName redirectedConstructor) {
    _redirectedConstructor = _becomeParentOf(redirectedConstructor);
  }

  /**
   * Return the type of object being created. This can be different than the
   * type in which the constructor is being declared if the constructor is the
   * implementation of a factory constructor.
   */
  Identifier get returnType => _returnType;

  /**
   * Set the type of object being created to the given [typeName].
   */
  void set returnType(Identifier typeName) {
    _returnType = _becomeParentOf(typeName);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitConstructorDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_returnType, visitor);
    _safelyVisitChild(_name, visitor);
    _safelyVisitChild(_parameters, visitor);
    _initializers.accept(visitor);
    _safelyVisitChild(_redirectedConstructor, visitor);
    _safelyVisitChild(_body, visitor);
  }
}

/**
 * The initialization of a field within a constructor's initialization list.
 *
 * > fieldInitializer ::=
 * >     ('this' '.')? [SimpleIdentifier] '=' [Expression]
 */
class ConstructorFieldInitializer extends ConstructorInitializer {
  /**
   * The token for the 'this' keyword, or `null` if there is no 'this' keyword.
   */
  Token thisKeyword;

  /**
   * The token for the period after the 'this' keyword, or `null` if there is no
   * 'this' keyword.
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
   * Initialize a newly created field initializer to initialize the field with
   * the given name to the value of the given expression. The [thisKeyword] and
   * [period] can be `null` if the 'this' keyword was not specified.
   */
  ConstructorFieldInitializer(this.thisKeyword, this.period,
      SimpleIdentifier fieldName, this.equals, Expression expression) {
    _fieldName = _becomeParentOf(fieldName);
    _expression = _becomeParentOf(expression);
  }

  @override
  Token get beginToken {
    if (thisKeyword != null) {
      return thisKeyword;
    }
    return _fieldName.beginToken;
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(thisKeyword)
    ..add(period)
    ..add(_fieldName)
    ..add(equals)
    ..add(_expression);

  @override
  Token get endToken => _expression.endToken;

  /**
   * Return the expression computing the value to which the field will be
   * initialized.
   */
  Expression get expression => _expression;

  /**
   * Set the expression computing the value to which the field will be
   * initialized to the given [expression].
   */
  void set expression(Expression expression) {
    _expression = _becomeParentOf(expression);
  }

  /**
   * Return the name of the field being initialized.
   */
  SimpleIdentifier get fieldName => _fieldName;

  /**
   * Set the name of the field being initialized to the given [identifier].
   */
  void set fieldName(SimpleIdentifier identifier) {
    _fieldName = _becomeParentOf(identifier);
  }

  /**
   * Return the token for the 'this' keyword, or `null` if there is no 'this'
   * keyword.
   */
  @deprecated // Use "this.thisKeyword"
  Token get keyword => thisKeyword;

  /**
   * Set the token for the 'this' keyword to the given [token].
   */
  @deprecated // Use "this.thisKeyword"
  set keyword(Token token) {
    thisKeyword = token;
  }

  @override
  accept(AstVisitor visitor) => visitor.visitConstructorFieldInitializer(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_fieldName, visitor);
    _safelyVisitChild(_expression, visitor);
  }
}

/**
 * A node that can occur in the initializer list of a constructor declaration.
 *
 * > constructorInitializer ::=
 * >     [SuperConstructorInvocation]
 * >   | [ConstructorFieldInitializer]
 */
abstract class ConstructorInitializer extends AstNode {}

/**
 * The name of the constructor.
 *
 * > constructorName ::=
 * >     type ('.' identifier)?
 */
class ConstructorName extends AstNode {
  /**
   * The name of the type defining the constructor.
   */
  TypeName _type;

  /**
   * The token for the period before the constructor name, or `null` if the
   * specified constructor is the unnamed constructor.
   */
  Token period;

  /**
   * The name of the constructor, or `null` if the specified constructor is the
   * unnamed constructor.
   */
  SimpleIdentifier _name;

  /**
   * The element associated with this constructor name based on static type
   * information, or `null` if the AST structure has not been resolved or if
   * this constructor name could not be resolved.
   */
  ConstructorElement staticElement;

  /**
   * Initialize a newly created constructor name. The [period] and [name] can be
   * `null` if the constructor being named is the unnamed constructor.
   */
  ConstructorName(TypeName type, this.period, SimpleIdentifier name) {
    _type = _becomeParentOf(type);
    _name = _becomeParentOf(name);
  }

  @override
  Token get beginToken => _type.beginToken;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(_type)
    ..add(period)
    ..add(_name);

  @override
  Token get endToken {
    if (_name != null) {
      return _name.endToken;
    }
    return _type.endToken;
  }

  /**
   * Return the name of the constructor, or `null` if the specified constructor
   * is the unnamed constructor.
   */
  SimpleIdentifier get name => _name;

  /**
   * Set the name of the constructor to the given [name].
   */
  void set name(SimpleIdentifier name) {
    _name = _becomeParentOf(name);
  }

  /**
   * Return the name of the type defining the constructor.
   */
  TypeName get type => _type;

  /**
   * Set the name of the type defining the constructor to the given [type] name.
   */
  void set type(TypeName type) {
    _type = _becomeParentOf(type);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitConstructorName(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_type, visitor);
    _safelyVisitChild(_name, visitor);
  }
}

/**
 * A continue statement.
 *
 * > continueStatement ::=
 * >     'continue' [SimpleIdentifier]? ';'
 */
class ContinueStatement extends Statement {
  /**
   * The token representing the 'continue' keyword.
   */
  Token continueKeyword;

  /**
   * The label associated with the statement, or `null` if there is no label.
   */
  SimpleIdentifier _label;

  /**
   * The semicolon terminating the statement.
   */
  Token semicolon;

  /**
   * The AstNode which this continue statement is continuing to.  This will be
   * either a Statement (in the case of continuing a loop) or a SwitchMember
   * (in the case of continuing from one switch case to another).  Null if the
   * AST has not yet been resolved or if the target could not be resolved.
   * Note that if the source code has errors, the target may be invalid (e.g.
   * the target may be in an enclosing function).
   */
  AstNode target;

  /**
   * Initialize a newly created continue statement. The [label] can be `null` if
   * there is no label associated with the statement.
   */
  ContinueStatement(
      this.continueKeyword, SimpleIdentifier label, this.semicolon) {
    _label = _becomeParentOf(label);
  }

  @override
  Token get beginToken => continueKeyword;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(continueKeyword)
    ..add(_label)
    ..add(semicolon);

  @override
  Token get endToken => semicolon;

  /**
   * Return the token for the 'continue' keyword, or `null` if there is no
   * 'continue' keyword.
   */
  @deprecated // Use "this.continueKeyword"
  Token get keyword => continueKeyword;

  /**
   * Set the token for the 'continue' keyword to the given [token].
   */
  @deprecated // Use "this.continueKeyword"
  set keyword(Token token) {
    continueKeyword = token;
  }

  /**
   * Return the label associated with the statement, or `null` if there is no
   * label.
   */
  SimpleIdentifier get label => _label;

  /**
   * Set the label associated with the statement to the given [identifier].
   */
  void set label(SimpleIdentifier identifier) {
    _label = _becomeParentOf(identifier);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitContinueStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_label, visitor);
  }
}

/**
 * A node that represents the declaration of one or more names. Each declared
 * name is visible within a name scope.
 */
abstract class Declaration extends AnnotatedNode {
  /**
   * Initialize a newly created declaration. Either or both of the [comment] and
   * [metadata] can be `null` if the declaration does not have the corresponding
   * attribute.
   */
  Declaration(Comment comment, List<Annotation> metadata)
      : super(comment, metadata);

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
 * > declaredIdentifier ::=
 * >     [Annotation] finalConstVarOrType [SimpleIdentifier]
 */
class DeclaredIdentifier extends Declaration {
  /**
   * The token representing either the 'final', 'const' or 'var' keyword, or
   * `null` if no keyword was used.
   */
  Token keyword;

  /**
   * The name of the declared type of the parameter, or `null` if the parameter
   * does not have a declared type.
   */
  TypeName _type;

  /**
   * The name of the variable being declared.
   */
  SimpleIdentifier _identifier;

  /**
   * Initialize a newly created formal parameter. Either or both of the
   * [comment] and [metadata] can be `null` if the declaration does not have the
   * corresponding attribute. The [keyword] can be `null` if a type name is
   * given. The [type] must be `null` if the keyword is 'var'.
   */
  DeclaredIdentifier(Comment comment, List<Annotation> metadata, this.keyword,
      TypeName type, SimpleIdentifier identifier)
      : super(comment, metadata) {
    _type = _becomeParentOf(type);
    _identifier = _becomeParentOf(identifier);
  }

  @override
  Iterable get childEntities => super._childEntities
    ..add(keyword)
    ..add(_type)
    ..add(_identifier);

  @override
  LocalVariableElement get element {
    if (_identifier == null) {
      return null;
    }
    return _identifier.staticElement as LocalVariableElement;
  }

  @override
  Token get endToken => _identifier.endToken;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (keyword != null) {
      return keyword;
    } else if (_type != null) {
      return _type.beginToken;
    }
    return _identifier.beginToken;
  }

  /**
   * Return the name of the variable being declared.
   */
  SimpleIdentifier get identifier => _identifier;

  /**
   * Set the name of the variable being declared to the given [identifier].
   */
  void set identifier(SimpleIdentifier identifier) {
    _identifier = _becomeParentOf(identifier);
  }

  /**
   * Return `true` if this variable was declared with the 'const' modifier.
   */
  bool get isConst => (keyword is KeywordToken) &&
      (keyword as KeywordToken).keyword == Keyword.CONST;

  /**
   * Return `true` if this variable was declared with the 'final' modifier.
   * Variables that are declared with the 'const' modifier will return `false`
   * even though they are implicitly final.
   */
  bool get isFinal => (keyword is KeywordToken) &&
      (keyword as KeywordToken).keyword == Keyword.FINAL;

  /**
   * Return the name of the declared type of the parameter, or `null` if the
   * parameter does not have a declared type.
   */
  TypeName get type => _type;

  /**
   * Set the name of the declared type of the parameter to the given [typeName].
   */
  void set type(TypeName typeName) {
    _type = _becomeParentOf(typeName);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitDeclaredIdentifier(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_type, visitor);
    _safelyVisitChild(_identifier, visitor);
  }
}

/**
 * A formal parameter with a default value. There are two kinds of parameters
 * that are both represented by this class: named formal parameters and
 * positional formal parameters.
 *
 * > defaultFormalParameter ::=
 * >     [NormalFormalParameter] ('=' [Expression])?
 * >
 * > defaultNamedParameter ::=
 * >     [NormalFormalParameter] (':' [Expression])?
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
   * The token separating the parameter from the default value, or `null` if
   * there is no default value.
   */
  Token separator;

  /**
   * The expression computing the default value for the parameter, or `null` if
   * there is no default value.
   */
  Expression _defaultValue;

  /**
   * Initialize a newly created default formal parameter. The [separator] and
   * [defaultValue] can be `null` if there is no default value.
   */
  DefaultFormalParameter(NormalFormalParameter parameter, this.kind,
      this.separator, Expression defaultValue) {
    _parameter = _becomeParentOf(parameter);
    _defaultValue = _becomeParentOf(defaultValue);
  }

  @override
  Token get beginToken => _parameter.beginToken;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(_parameter)
    ..add(separator)
    ..add(_defaultValue);

  /**
   * Return the expression computing the default value for the parameter, or
   * `null` if there is no default value.
   */
  Expression get defaultValue => _defaultValue;

  /**
   * Set the expression computing the default value for the parameter to the
   * given [expression].
   */
  void set defaultValue(Expression expression) {
    _defaultValue = _becomeParentOf(expression);
  }

  @override
  Token get endToken {
    if (_defaultValue != null) {
      return _defaultValue.endToken;
    }
    return _parameter.endToken;
  }

  @override
  SimpleIdentifier get identifier => _parameter.identifier;

  @override
  bool get isConst => _parameter != null && _parameter.isConst;

  @override
  bool get isFinal => _parameter != null && _parameter.isFinal;

  /**
   * Return the formal parameter with which the default value is associated.
   */
  NormalFormalParameter get parameter => _parameter;

  /**
   * Set the formal parameter with which the default value is associated to the
   * given [formalParameter].
   */
  void set parameter(NormalFormalParameter formalParameter) {
    _parameter = _becomeParentOf(formalParameter);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitDefaultFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_parameter, visitor);
    _safelyVisitChild(_defaultValue, visitor);
  }
}

/**
 * A recursive AST visitor that is used to run over [Expression]s to determine
 * whether the expression is composed by at least one deferred
 * [PrefixedIdentifier].
 *
 * See [PrefixedIdentifier.isDeferred].
 */
class DeferredLibraryReferenceDetector extends RecursiveAstVisitor<Object> {
  /**
   * A flag indicating whether an identifier from a deferred library has been
   * found.
   */
  bool _result = false;

  /**
   * Return `true` if the visitor found a [PrefixedIdentifier] that returned
   * `true` to the [PrefixedIdentifier.isDeferred] query.
   */
  bool get result => _result;

  @override
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (!_result) {
      if (node.isDeferred) {
        _result = true;
      }
    }
    return null;
  }
}

/**
 * A node that represents a directive.
 *
 * > directive ::=
 * >     [ExportDirective]
 * >   | [ImportDirective]
 * >   | [LibraryDirective]
 * >   | [PartDirective]
 * >   | [PartOfDirective]
 */
abstract class Directive extends AnnotatedNode {
  /**
   * The element associated with this directive, or `null` if the AST structure
   * has not been resolved or if this directive could not be resolved.
   */
  Element element;

  /**
   * Initialize a newly create directive. Either or both of the [comment] and
   * [metadata] can be `null` if the directive does not have the corresponding
   * attribute.
   */
  Directive(Comment comment, List<Annotation> metadata)
      : super(comment, metadata);

  /**
   * Return the token representing the keyword that introduces this directive
   * ('import', 'export', 'library' or 'part').
   */
  Token get keyword;
}

/**
 * A do statement.
 *
 * > doStatement ::=
 * >     'do' [Statement] 'while' '(' [Expression] ')' ';'
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
  Token leftParenthesis;

  /**
   * The condition that determines when the loop will terminate.
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
   * Initialize a newly created do loop.
   */
  DoStatement(this.doKeyword, Statement body, this.whileKeyword,
      this.leftParenthesis, Expression condition, this.rightParenthesis,
      this.semicolon) {
    _body = _becomeParentOf(body);
    _condition = _becomeParentOf(condition);
  }

  @override
  Token get beginToken => doKeyword;

  /**
   * Return the body of the loop.
   */
  Statement get body => _body;

  /**
   * Set the body of the loop to the given [statement].
   */
  void set body(Statement statement) {
    _body = _becomeParentOf(statement);
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(doKeyword)
    ..add(_body)
    ..add(whileKeyword)
    ..add(leftParenthesis)
    ..add(_condition)
    ..add(rightParenthesis)
    ..add(semicolon);

  /**
   * Return the condition that determines when the loop will terminate.
   */
  Expression get condition => _condition;

  /**
   * Set the condition that determines when the loop will terminate to the given
   * [expression].
   */
  void set condition(Expression expression) {
    _condition = _becomeParentOf(expression);
  }

  @override
  Token get endToken => semicolon;

  @override
  accept(AstVisitor visitor) => visitor.visitDoStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_body, visitor);
    _safelyVisitChild(_condition, visitor);
  }
}

/**
 * A floating point literal expression.
 *
 * > doubleLiteral ::=
 * >     decimalDigit+ ('.' decimalDigit*)? exponent?
 * >   | '.' decimalDigit+ exponent?
 * >
 * > exponent ::=
 * >     ('e' | 'E') ('+' | '-')? decimalDigit+
 */
class DoubleLiteral extends Literal {
  /**
   * The token representing the literal.
   */
  Token literal;

  /**
   * The value of the literal.
   */
  double value;

  /**
   * Initialize a newly created floating point literal.
   */
  DoubleLiteral(this.literal, this.value);

  @override
  Token get beginToken => literal;

  @override
  Iterable get childEntities => new ChildEntities()..add(literal);

  @override
  Token get endToken => literal;

  @override
  accept(AstVisitor visitor) => visitor.visitDoubleLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/**
 * An object used to locate the [Element] associated with a given [AstNode].
 */
class ElementLocator {
  /**
   * Return the element associated with the given [node], or `null` if there is
   * no element associated with the node.
   */
  static Element locate(AstNode node) {
    if (node == null) {
      return null;
    }
    ElementLocator_ElementMapper mapper = new ElementLocator_ElementMapper();
    return node.accept(mapper);
  }

  /**
   * Return the element associated with the given [node], or `null` if there is
   * no element associated with the node.
   */
  static Element locateWithOffset(AstNode node, int offset) {
    // TODO(brianwilkerson) 'offset' is not used. Figure out what's going on:
    // whether there's a bug or whether this method is unnecessary.
    if (node == null) {
      return null;
    }
    // try to get Element from node
    Element nodeElement = locate(node);
    if (nodeElement != null) {
      return nodeElement;
    }
    // no Element
    return null;
  }
}

/**
 * Visitor that maps nodes to elements.
 */
class ElementLocator_ElementMapper extends GeneralizingAstVisitor<Element> {
  @override
  Element visitAnnotation(Annotation node) => node.element;

  @override
  Element visitAssignmentExpression(AssignmentExpression node) =>
      node.bestElement;

  @override
  Element visitBinaryExpression(BinaryExpression node) => node.bestElement;

  @override
  Element visitClassDeclaration(ClassDeclaration node) => node.element;

  @override
  Element visitCompilationUnit(CompilationUnit node) => node.element;

  @override
  Element visitConstructorDeclaration(ConstructorDeclaration node) =>
      node.element;

  @override
  Element visitFunctionDeclaration(FunctionDeclaration node) => node.element;

  @override
  Element visitIdentifier(Identifier node) {
    AstNode parent = node.parent;
    // Type name in Annotation
    if (parent is Annotation) {
      Annotation annotation = parent;
      if (identical(annotation.name, node) &&
          annotation.constructorName == null) {
        return annotation.element;
      }
    }
    // Extra work to map Constructor Declarations to their associated
    // Constructor Elements
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
    return node.bestElement;
  }

  @override
  Element visitImportDirective(ImportDirective node) => node.element;

  @override
  Element visitIndexExpression(IndexExpression node) => node.bestElement;

  @override
  Element visitInstanceCreationExpression(InstanceCreationExpression node) =>
      node.staticElement;

  @override
  Element visitLibraryDirective(LibraryDirective node) => node.element;

  @override
  Element visitMethodDeclaration(MethodDeclaration node) => node.element;

  @override
  Element visitMethodInvocation(MethodInvocation node) =>
      node.methodName.bestElement;

  @override
  Element visitPostfixExpression(PostfixExpression node) => node.bestElement;

  @override
  Element visitPrefixedIdentifier(PrefixedIdentifier node) => node.bestElement;

  @override
  Element visitPrefixExpression(PrefixExpression node) => node.bestElement;

  @override
  Element visitStringLiteral(StringLiteral node) {
    AstNode parent = node.parent;
    if (parent is UriBasedDirective) {
      return parent.uriElement;
    }
    return null;
  }

  @override
  Element visitVariableDeclaration(VariableDeclaration node) => node.element;
}

/**
 * An empty function body, which can only appear in constructors or abstract
 * methods.
 *
 * > emptyFunctionBody ::=
 * >     ';'
 */
class EmptyFunctionBody extends FunctionBody {
  /**
   * The token representing the semicolon that marks the end of the function
   * body.
   */
  Token semicolon;

  /**
   * Initialize a newly created function body.
   */
  EmptyFunctionBody(this.semicolon);

  @override
  Token get beginToken => semicolon;

  @override
  Iterable get childEntities => new ChildEntities()..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  accept(AstVisitor visitor) => visitor.visitEmptyFunctionBody(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // Empty function bodies have no children.
  }
}

/**
 * An empty statement.
 *
 * > emptyStatement ::=
 * >     ';'
 */
class EmptyStatement extends Statement {
  /**
   * The semicolon terminating the statement.
   */
  Token semicolon;

  /**
   * Initialize a newly created empty statement.
   */
  EmptyStatement(this.semicolon);

  @override
  Token get beginToken => semicolon;

  @override
  Iterable get childEntities => new ChildEntities()..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  accept(AstVisitor visitor) => visitor.visitEmptyStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/**
 * The declaration of an enum constant.
 */
class EnumConstantDeclaration extends Declaration {
  /**
   * The name of the constant.
   */
  SimpleIdentifier _name;

  /**
   * Initialize a newly created enum constant declaration. Either or both of the
   * [comment] and [metadata] can be `null` if the constant does not have the
   * corresponding attribute. (Technically, enum constants cannot have metadata,
   * but we allow it for consistency.)
   */
  EnumConstantDeclaration(
      Comment comment, List<Annotation> metadata, SimpleIdentifier name)
      : super(comment, metadata) {
    _name = _becomeParentOf(name);
  }

  @override
  Iterable get childEntities => super._childEntities..add(_name);

  @override
  FieldElement get element =>
      _name == null ? null : (_name.staticElement as FieldElement);

  @override
  Token get endToken => _name.endToken;

  @override
  Token get firstTokenAfterCommentAndMetadata => _name.beginToken;

  /**
   * Return the name of the constant.
   */
  SimpleIdentifier get name => _name;

  /**
   * Set the name of the constant to the given [name].
   */
  void set name(SimpleIdentifier name) {
    _name = _becomeParentOf(name);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitEnumConstantDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_name, visitor);
  }
}

/**
 * The declaration of an enumeration.
 *
 * > enumType ::=
 * >     metadata 'enum' [SimpleIdentifier] '{' [SimpleIdentifier] (',' [SimpleIdentifier])* (',')? '}'
 */
class EnumDeclaration extends NamedCompilationUnitMember {
  /**
   * The 'enum' keyword.
   */
  Token enumKeyword;

  /**
   * The left curly bracket.
   */
  Token leftBracket;

  /**
   * The enumeration constants being declared.
   */
  NodeList<EnumConstantDeclaration> _constants;

  /**
   * The right curly bracket.
   */
  Token rightBracket;

  /**
   * Initialize a newly created enumeration declaration. Either or both of the
   * [comment] and [metadata] can be `null` if the declaration does not have the
   * corresponding attribute. The list of [constants] must contain at least one
   * value.
   */
  EnumDeclaration(Comment comment, List<Annotation> metadata, this.enumKeyword,
      SimpleIdentifier name, this.leftBracket,
      List<EnumConstantDeclaration> constants, this.rightBracket)
      : super(comment, metadata, name) {
    _constants = new NodeList<EnumConstantDeclaration>(this, constants);
  }

  @override
  // TODO(brianwilkerson) Add commas?
  Iterable get childEntities => super._childEntities
    ..add(enumKeyword)
    ..add(_name)
    ..add(leftBracket)
    ..addAll(_constants)
    ..add(rightBracket);

  /**
   * Return the enumeration constants being declared.
   */
  NodeList<EnumConstantDeclaration> get constants => _constants;

  @override
  ClassElement get element =>
      _name != null ? (_name.staticElement as ClassElement) : null;

  @override
  Token get endToken => rightBracket;

  @override
  Token get firstTokenAfterCommentAndMetadata => enumKeyword;

  /**
   * Return the token for the 'enum' keyword, or `null` if there is no
   * 'enum' keyword.
   */
  @deprecated // Use "this.enumKeyword"
  Token get keyword => enumKeyword;

  /**
   * Set the token for the 'enum' keyword to the given [token].
   */
  @deprecated // Use "this.enumKeyword"
  set keyword(Token token) {
    enumKeyword = token;
  }

  @override
  accept(AstVisitor visitor) => visitor.visitEnumDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_name, visitor);
    _constants.accept(visitor);
  }
}

/**
 * Ephemeral identifiers are created as needed to mimic the presence of an empty
 * identifier.
 */
class EphemeralIdentifier extends SimpleIdentifier {
  EphemeralIdentifier(AstNode parent, int location)
      : super(new StringToken(TokenType.IDENTIFIER, "", location)) {
    parent._becomeParentOf(this);
  }
}

/**
 * An export directive.
 *
 * > exportDirective ::=
 * >     [Annotation] 'export' [StringLiteral] [Combinator]* ';'
 */
class ExportDirective extends NamespaceDirective {
  /**
   * Initialize a newly created export directive. Either or both of the
   * [comment] and [metadata] can be `null` if the directive does not have the
   * corresponding attribute. The list of [combinators] can be `null` if there
   * are no combinators.
   */
  ExportDirective(Comment comment, List<Annotation> metadata, Token keyword,
      StringLiteral libraryUri, List<Combinator> combinators, Token semicolon)
      : super(comment, metadata, keyword, libraryUri, combinators, semicolon);

  @override
  Iterable get childEntities => super._childEntities
    ..add(_uri)
    ..addAll(combinators)
    ..add(semicolon);

  @override
  ExportElement get element => super.element as ExportElement;

  @override
  LibraryElement get uriElement {
    if (element != null) {
      return element.exportedLibrary;
    }
    return null;
  }

  @override
  accept(AstVisitor visitor) => visitor.visitExportDirective(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    combinators.accept(visitor);
  }
}

/**
 * A node that represents an expression.
 *
 * > expression ::=
 * >     [AssignmentExpression]
 * >   | [ConditionalExpression] cascadeSection*
 * >   | [ThrowExpression]
 */
abstract class Expression extends AstNode {
  /**
   * An empty list of expressions.
   */
  @deprecated // Use "Expression.EMPTY_LIST"
  static const List<Expression> EMPTY_ARRAY = EMPTY_LIST;

  /**
   * An empty list of expressions.
   */
  static const List<Expression> EMPTY_LIST = const <Expression>[];

  /**
   * The static type of this expression, or `null` if the AST structure has not
   * been resolved.
   */
  DartType staticType;

  /**
   * The propagated type of this expression, or `null` if type propagation has
   * not been performed on the AST structure.
   */
  DartType propagatedType;

  /**
   * Return the best parameter element information available for this
   * expression. If type propagation was able to find a better parameter element
   * than static analysis, that type will be returned. Otherwise, the result of
   * static analysis will be returned.
   */
  ParameterElement get bestParameterElement {
    ParameterElement propagatedElement = propagatedParameterElement;
    if (propagatedElement != null) {
      return propagatedElement;
    }
    return staticParameterElement;
  }

  /**
   * Return the best type information available for this expression. If type
   * propagation was able to find a better type than static analysis, that type
   * will be returned. Otherwise, the result of static analysis will be
   * returned. If no type analysis has been performed, then the type 'dynamic'
   * will be returned.
   */
  DartType get bestType {
    if (propagatedType != null) {
      return propagatedType;
    } else if (staticType != null) {
      return staticType;
    }
    return DynamicTypeImpl.instance;
  }

  /**
   * Return `true` if this expression is syntactically valid for the LHS of an
   * [AssignmentExpression].
   */
  bool get isAssignable => false;

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
  ParameterElement get propagatedParameterElement {
    AstNode parent = this.parent;
    if (parent is ArgumentList) {
      return parent._getPropagatedParameterElementFor(this);
    } else if (parent is IndexExpression) {
      IndexExpression indexExpression = parent;
      if (identical(indexExpression.index, this)) {
        return indexExpression._propagatedParameterElementForIndex;
      }
    } else if (parent is BinaryExpression) {
      BinaryExpression binaryExpression = parent;
      if (identical(binaryExpression.rightOperand, this)) {
        return binaryExpression._propagatedParameterElementForRightOperand;
      }
    } else if (parent is AssignmentExpression) {
      AssignmentExpression assignmentExpression = parent;
      if (identical(assignmentExpression.rightHandSide, this)) {
        return assignmentExpression._propagatedParameterElementForRightHandSide;
      }
    } else if (parent is PrefixExpression) {
      return parent._propagatedParameterElementForOperand;
    } else if (parent is PostfixExpression) {
      return parent._propagatedParameterElementForOperand;
    }
    return null;
  }

  /**
   * If this expression is an argument to an invocation, and the AST structure
   * has been resolved, and the function being invoked is known based on static
   * type information, and this expression corresponds to one of the parameters
   * of the function being invoked, then return the parameter element
   * representing the parameter to which the value of this expression will be
   * bound. Otherwise, return `null`.
   */
  ParameterElement get staticParameterElement {
    AstNode parent = this.parent;
    if (parent is ArgumentList) {
      return parent._getStaticParameterElementFor(this);
    } else if (parent is IndexExpression) {
      IndexExpression indexExpression = parent;
      if (identical(indexExpression.index, this)) {
        return indexExpression._staticParameterElementForIndex;
      }
    } else if (parent is BinaryExpression) {
      BinaryExpression binaryExpression = parent;
      if (identical(binaryExpression.rightOperand, this)) {
        return binaryExpression._staticParameterElementForRightOperand;
      }
    } else if (parent is AssignmentExpression) {
      AssignmentExpression assignmentExpression = parent;
      if (identical(assignmentExpression.rightHandSide, this)) {
        return assignmentExpression._staticParameterElementForRightHandSide;
      }
    } else if (parent is PrefixExpression) {
      return parent._staticParameterElementForOperand;
    } else if (parent is PostfixExpression) {
      return parent._staticParameterElementForOperand;
    }
    return null;
  }
}

/**
 * A function body consisting of a single expression.
 *
 * > expressionFunctionBody ::=
 * >     'async'? '=>' [Expression] ';'
 */
class ExpressionFunctionBody extends FunctionBody {
  /**
   * The token representing the 'async' keyword, or `null` if there is no such
   * keyword.
   */
  Token keyword;

  /**
   * The token introducing the expression that represents the body of the
   * function.
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
   * Initialize a newly created function body consisting of a block of
   * statements. The [keyword] can be `null` if the function body is not an
   * async function body.
   */
  ExpressionFunctionBody(this.keyword, this.functionDefinition,
      Expression expression, this.semicolon) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Token get beginToken {
    if (keyword != null) {
      return keyword;
    }
    return functionDefinition;
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(keyword)
    ..add(functionDefinition)
    ..add(_expression)
    ..add(semicolon);

  @override
  Token get endToken {
    if (semicolon != null) {
      return semicolon;
    }
    return _expression.endToken;
  }

  /**
   * Return the expression representing the body of the function.
   */
  Expression get expression => _expression;

  /**
   * Set the expression representing the body of the function to the given
   * [expression].
   */
  void set expression(Expression expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  bool get isAsynchronous => keyword != null;

  @override
  bool get isSynchronous => keyword == null;

  @override
  accept(AstVisitor visitor) => visitor.visitExpressionFunctionBody(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_expression, visitor);
  }
}

/**
 * An expression used as a statement.
 *
 * > expressionStatement ::=
 * >     [Expression]? ';'
 */
class ExpressionStatement extends Statement {
  /**
   * The expression that comprises the statement.
   */
  Expression _expression;

  /**
   * The semicolon terminating the statement, or `null` if the expression is a
   * function expression and therefore isn't followed by a semicolon.
   */
  Token semicolon;

  /**
   * Initialize a newly created expression statement.
   */
  ExpressionStatement(Expression expression, this.semicolon) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Token get beginToken => _expression.beginToken;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(_expression)
    ..add(semicolon);

  @override
  Token get endToken {
    if (semicolon != null) {
      return semicolon;
    }
    return _expression.endToken;
  }

  /**
   * Return the expression that comprises the statement.
   */
  Expression get expression => _expression;

  /**
   * Set the expression that comprises the statement to the given [expression].
   */
  void set expression(Expression expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  bool get isSynthetic => _expression.isSynthetic && semicolon.isSynthetic;

  @override
  accept(AstVisitor visitor) => visitor.visitExpressionStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_expression, visitor);
  }
}

/**
 * The "extends" clause in a class declaration.
 *
 * > extendsClause ::=
 * >     'extends' [TypeName]
 */
class ExtendsClause extends AstNode {
  /**
   * The token representing the 'extends' keyword.
   */
  Token extendsKeyword;

  /**
   * The name of the class that is being extended.
   */
  TypeName _superclass;

  /**
   * Initialize a newly created extends clause.
   */
  ExtendsClause(this.extendsKeyword, TypeName superclass) {
    _superclass = _becomeParentOf(superclass);
  }

  @override
  Token get beginToken => extendsKeyword;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(extendsKeyword)
    ..add(_superclass);

  @override
  Token get endToken => _superclass.endToken;

  /**
   * Return the token for the 'extends' keyword.
   */
  @deprecated // Use "this.extendsKeyword"
  Token get keyword => extendsKeyword;

  /**
   * Set the token for the 'extends' keyword to the given [token].
   */
  @deprecated // Use "this.extendsKeyword"
  set keyword(Token token) {
    extendsKeyword = token;
  }

  /**
   * Return the name of the class that is being extended.
   */
  TypeName get superclass => _superclass;

  /**
   * Set the name of the class that is being extended to the given [name].
   */
  void set superclass(TypeName name) {
    _superclass = _becomeParentOf(name);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitExtendsClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_superclass, visitor);
  }
}

/**
 * The declaration of one or more fields of the same type.
 *
 * > fieldDeclaration ::=
 * >     'static'? [VariableDeclarationList] ';'
 */
class FieldDeclaration extends ClassMember {
  /**
   * The token representing the 'static' keyword, or `null` if the fields are
   * not static.
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
   * Initialize a newly created field declaration. Either or both of the
   * [comment] and [metadata] can be `null` if the declaration does not have the
   * corresponding attribute. The [staticKeyword] can be `null` if the field is
   * not a static field.
   */
  FieldDeclaration(Comment comment, List<Annotation> metadata,
      this.staticKeyword, VariableDeclarationList fieldList, this.semicolon)
      : super(comment, metadata) {
    _fieldList = _becomeParentOf(fieldList);
  }

  @override
  Iterable get childEntities => super._childEntities
    ..add(staticKeyword)
    ..add(_fieldList)
    ..add(semicolon);

  @override
  Element get element => null;

  @override
  Token get endToken => semicolon;

  /**
   * Return the fields being declared.
   */
  VariableDeclarationList get fields => _fieldList;

  /**
   * Set the fields being declared to the given list of [fields].
   */
  void set fields(VariableDeclarationList fields) {
    _fieldList = _becomeParentOf(fields);
  }

  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (staticKeyword != null) {
      return staticKeyword;
    }
    return _fieldList.beginToken;
  }

  /**
   * Return `true` if the fields are declared to be static.
   */
  bool get isStatic => staticKeyword != null;

  @override
  accept(AstVisitor visitor) => visitor.visitFieldDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_fieldList, visitor);
  }
}

/**
 * A field formal parameter.
 *
 * > fieldFormalParameter ::=
 * >     ('final' [TypeName] | 'const' [TypeName] | 'var' | [TypeName])?
 * >     'this' '.' [SimpleIdentifier] [FormalParameterList]?
 */
class FieldFormalParameter extends NormalFormalParameter {
  /**
   * The token representing either the 'final', 'const' or 'var' keyword, or
   * `null` if no keyword was used.
   */
  Token keyword;

  /**
   * The name of the declared type of the parameter, or `null` if the parameter
   * does not have a declared type.
   */
  TypeName _type;

  /**
   * The token representing the 'this' keyword.
   */
  Token thisKeyword;

  /**
   * The token representing the period.
   */
  Token period;

  /**
   * The parameters of the function-typed parameter, or `null` if this is not a
   * function-typed field formal parameter.
   */
  FormalParameterList _parameters;

  /**
   * Initialize a newly created formal parameter. Either or both of the
   * [comment] and [metadata] can be `null` if the parameter does not have the
   * corresponding attribute. The [keyword] can be `null` if there is a type.
   * The [type] must be `null` if the keyword is 'var'. The [thisKeyword] and
   * [period] can be `null` if the keyword 'this' was not provided.  The
   * [parameters] can be `null` if this is not a function-typed field formal
   * parameter.
   */
  FieldFormalParameter(Comment comment, List<Annotation> metadata, this.keyword,
      TypeName type, this.thisKeyword, this.period, SimpleIdentifier identifier,
      FormalParameterList parameters)
      : super(comment, metadata, identifier) {
    _type = _becomeParentOf(type);
    _parameters = _becomeParentOf(parameters);
  }

  @override
  Token get beginToken {
    if (keyword != null) {
      return keyword;
    } else if (_type != null) {
      return _type.beginToken;
    }
    return thisKeyword;
  }

  @override
  Iterable get childEntities => super._childEntities
    ..add(keyword)
    ..add(_type)
    ..add(thisKeyword)
    ..add(period)
    ..add(identifier)
    ..add(_parameters);

  @override
  Token get endToken {
    if (_parameters != null) {
      return _parameters.endToken;
    }
    return identifier.endToken;
  }

  @override
  bool get isConst => (keyword is KeywordToken) &&
      (keyword as KeywordToken).keyword == Keyword.CONST;

  @override
  bool get isFinal => (keyword is KeywordToken) &&
      (keyword as KeywordToken).keyword == Keyword.FINAL;

  /**
   * Return the parameters of the function-typed parameter, or `null` if this is
   * not a function-typed field formal parameter.
   */
  FormalParameterList get parameters => _parameters;

  /**
   * Set the parameters of the function-typed parameter to the given
   * [parameters].
   */
  void set parameters(FormalParameterList parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  /**
   * Return the token representing the 'this' keyword.
   */
  @deprecated // Use "this.thisKeyword"
  Token get thisToken => thisKeyword;

  /**
   * Set the token representing the 'this' keyword to the given [token].
   */
  @deprecated // Use "this.thisKeyword"
  set thisToken(Token token) {
    thisKeyword = token;
  }

  /**
   * Return the name of the declared type of the parameter, or `null` if the
   * parameter does not have a declared type. Note that if this is a
   * function-typed field formal parameter this is the return type of the
   * function.
   */
  TypeName get type => _type;

  /**
   * Set the name of the declared type of the parameter to the given [typeName].
   */
  void set type(TypeName typeName) {
    _type = _becomeParentOf(typeName);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitFieldFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_type, visitor);
    _safelyVisitChild(identifier, visitor);
    _safelyVisitChild(_parameters, visitor);
  }
}

/**
 * A for-each statement.
 *
 * > forEachStatement ::=
 * >     'await'? 'for' '(' [DeclaredIdentifier] 'in' [Expression] ')' [Block]
 * >   | 'await'? 'for' '(' [SimpleIdentifier] 'in' [Expression] ')' [Block]
 */
class ForEachStatement extends Statement {
  /**
   * The token representing the 'await' keyword, or `null` if there is no
   * 'await' keyword.
   */
  Token awaitKeyword;

  /**
   * The token representing the 'for' keyword.
   */
  Token forKeyword;

  /**
   * The left parenthesis.
   */
  Token leftParenthesis;

  /**
   * The declaration of the loop variable, or `null` if the loop variable is a
   * simple identifier.
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
  Expression _iterable;

  /**
   * The right parenthesis.
   */
  Token rightParenthesis;

  /**
   * The body of the loop.
   */
  Statement _body;

  /**
   * Initialize a newly created for-each statement. The [awaitKeyword] can be
   * `null` if this is not an asynchronous for loop.
   */
  ForEachStatement.con1(this.awaitKeyword, this.forKeyword,
      this.leftParenthesis, DeclaredIdentifier loopVariable, this.inKeyword,
      Expression iterator, this.rightParenthesis, Statement body) {
    _loopVariable = _becomeParentOf(loopVariable);
    _iterable = _becomeParentOf(iterator);
    _body = _becomeParentOf(body);
  }

  /**
   * Initialize a newly created for-each statement. The [awaitKeyword] can be
   * `null` if this is not an asynchronous for loop.
   */
  ForEachStatement.con2(this.awaitKeyword, this.forKeyword,
      this.leftParenthesis, SimpleIdentifier identifier, this.inKeyword,
      Expression iterator, this.rightParenthesis, Statement body) {
    _identifier = _becomeParentOf(identifier);
    _iterable = _becomeParentOf(iterator);
    _body = _becomeParentOf(body);
  }

  @override
  Token get beginToken => forKeyword;

  /**
   * Return the body of the loop.
   */
  Statement get body => _body;

  /**
   * Set the body of the loop to the given [statement].
   */
  void set body(Statement statement) {
    _body = _becomeParentOf(statement);
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(awaitKeyword)
    ..add(forKeyword)
    ..add(leftParenthesis)
    ..add(_loopVariable)
    ..add(_identifier)
    ..add(inKeyword)
    ..add(_iterable)
    ..add(rightParenthesis)
    ..add(_body);

  @override
  Token get endToken => _body.endToken;

  /**
   * Return the loop variable, or `null` if the loop variable is declared in the
   * 'for'.
   */
  SimpleIdentifier get identifier => _identifier;

  /**
   * Set the loop variable to the given [identifier].
   */
  void set identifier(SimpleIdentifier identifier) {
    _identifier = _becomeParentOf(identifier);
  }

  /**
   * Return the expression evaluated to produce the iterator.
   */
  Expression get iterable => _iterable;

  /**
   * Set the expression evaluated to produce the iterator to the given
   * [expression].
   */
  void set iterable(Expression expression) {
    _iterable = _becomeParentOf(expression);
  }

  /**
   * Return the expression evaluated to produce the iterator.
   */
  @deprecated // Use "this.iterable"
  Expression get iterator => iterable;

  /**
   * Return the declaration of the loop variable, or `null` if the loop variable
   * is a simple identifier.
   */
  DeclaredIdentifier get loopVariable => _loopVariable;

  /**
   * Set the declaration of the loop variable to the given [variable].
   */
  void set loopVariable(DeclaredIdentifier variable) {
    _loopVariable = _becomeParentOf(variable);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitForEachStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_loopVariable, visitor);
    _safelyVisitChild(_identifier, visitor);
    _safelyVisitChild(_iterable, visitor);
    _safelyVisitChild(_body, visitor);
  }
}

/**
 * A node representing a parameter to a function.
 *
 * > formalParameter ::=
 * >     [NormalFormalParameter]
 * >   | [DefaultFormalParameter]
 */
abstract class FormalParameter extends AstNode {
  /**
   * Return the element representing this parameter, or `null` if this parameter
   * has not been resolved.
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
 * > formalParameterList ::=
 * >     '(' ')'
 * >   | '(' normalFormalParameters (',' optionalFormalParameters)? ')'
 * >   | '(' optionalFormalParameters ')'
 * >
 * > normalFormalParameters ::=
 * >     [NormalFormalParameter] (',' [NormalFormalParameter])*
 * >
 * > optionalFormalParameters ::=
 * >     optionalPositionalFormalParameters
 * >   | namedFormalParameters
 * >
 * > optionalPositionalFormalParameters ::=
 * >     '[' [DefaultFormalParameter] (',' [DefaultFormalParameter])* ']'
 * >
 * > namedFormalParameters ::=
 * >     '{' [DefaultFormalParameter] (',' [DefaultFormalParameter])* '}'
 */
class FormalParameterList extends AstNode {
  /**
   * The left parenthesis.
   */
  Token leftParenthesis;

  /**
   * The parameters associated with the method.
   */
  NodeList<FormalParameter> _parameters;

  /**
   * The left square bracket ('[') or left curly brace ('{') introducing the
   * optional parameters, or `null` if there are no optional parameters.
   */
  Token leftDelimiter;

  /**
   * The right square bracket (']') or right curly brace ('}') terminating the
   * optional parameters, or `null` if there are no optional parameters.
   */
  Token rightDelimiter;

  /**
   * The right parenthesis.
   */
  Token rightParenthesis;

  /**
   * Initialize a newly created parameter list. The list of [parameters] can be
   * `null` if there are no parameters. The [leftDelimiter] and [rightDelimiter]
   * can be `null` if there are no optional parameters.
   */
  FormalParameterList(this.leftParenthesis, List<FormalParameter> parameters,
      this.leftDelimiter, this.rightDelimiter, this.rightParenthesis) {
    _parameters = new NodeList<FormalParameter>(this, parameters);
  }

  @override
  Token get beginToken => leftParenthesis;

  @override
  Iterable get childEntities {
    // TODO(paulberry): include commas.
    ChildEntities result = new ChildEntities()..add(leftParenthesis);
    bool leftDelimiterNeeded = leftDelimiter != null;
    for (FormalParameter parameter in _parameters) {
      if (leftDelimiterNeeded && leftDelimiter.offset < parameter.offset) {
        result.add(leftDelimiter);
        leftDelimiterNeeded = false;
      }
      result.add(parameter);
    }
    return result
      ..add(rightDelimiter)
      ..add(rightParenthesis);
  }

  @override
  Token get endToken => rightParenthesis;

  /**
   * Return a list containing the elements representing the parameters in this
   * list. The list will contain `null`s if the parameters in this list have not
   * been resolved.
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
   */
  NodeList<FormalParameter> get parameters => _parameters;

  @override
  accept(AstVisitor visitor) => visitor.visitFormalParameterList(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _parameters.accept(visitor);
  }
}

/**
 * A for statement.
 *
 * > forStatement ::=
 * >     'for' '(' forLoopParts ')' [Statement]
 * >
 * > forLoopParts ::=
 * >     forInitializerStatement ';' [Expression]? ';' [Expression]?
 * >
 * > forInitializerStatement ::=
 * >     [DefaultFormalParameter]
 * >   | [Expression]?
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
   * The declaration of the loop variables, or `null` if there are no variables.
   * Note that a for statement cannot have both a variable list and an
   * initialization expression, but can validly have neither.
   */
  VariableDeclarationList _variableList;

  /**
   * The initialization expression, or `null` if there is no initialization
   * expression. Note that a for statement cannot have both a variable list and
   * an initialization expression, but can validly have neither.
   */
  Expression _initialization;

  /**
   * The semicolon separating the initializer and the condition.
   */
  Token leftSeparator;

  /**
   * The condition used to determine when to terminate the loop, or `null` if
   * there is no condition.
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
   * Initialize a newly created for statement. Either the [variableList] or the
   * [initialization] must be `null`. Either the [condition] and the list of
   * [updaters] can be `null` if the loop does not have the corresponding
   * attribute.
   */
  ForStatement(this.forKeyword, this.leftParenthesis,
      VariableDeclarationList variableList, Expression initialization,
      this.leftSeparator, Expression condition, this.rightSeparator,
      List<Expression> updaters, this.rightParenthesis, Statement body) {
    _variableList = _becomeParentOf(variableList);
    _initialization = _becomeParentOf(initialization);
    _condition = _becomeParentOf(condition);
    _updaters = new NodeList<Expression>(this, updaters);
    _body = _becomeParentOf(body);
  }

  @override
  Token get beginToken => forKeyword;

  /**
   * Return the body of the loop.
   */
  Statement get body => _body;

  /**
   * Set the body of the loop to the given [statement].
   */
  void set body(Statement statement) {
    _body = _becomeParentOf(statement);
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(forKeyword)
    ..add(leftParenthesis)
    ..add(_variableList)
    ..add(_initialization)
    ..add(leftSeparator)
    ..add(_condition)
    ..add(rightSeparator)
    ..addAll(_updaters)
    ..add(rightParenthesis)
    ..add(_body);

  /**
   * Return the condition used to determine when to terminate the loop, or
   * `null` if there is no condition.
   */
  Expression get condition => _condition;

  /**
   * Set the condition used to determine when to terminate the loop to the given
   * [expression].
   */
  void set condition(Expression expression) {
    _condition = _becomeParentOf(expression);
  }

  @override
  Token get endToken => _body.endToken;

  /**
   * Return the initialization expression, or `null` if there is no
   * initialization expression.
   */
  Expression get initialization => _initialization;

  /**
   * Set the initialization expression to the given [expression].
   */
  void set initialization(Expression initialization) {
    _initialization = _becomeParentOf(initialization);
  }

  /**
   * Return the list of expressions run after each execution of the loop body.
   */
  NodeList<Expression> get updaters => _updaters;

  /**
   * Return the declaration of the loop variables, or `null` if there are no
   * variables.
   */
  VariableDeclarationList get variables => _variableList;

  /**
   * Set the declaration of the loop variables to the given [variableList].
   */
  void set variables(VariableDeclarationList variableList) {
    _variableList = _becomeParentOf(variableList);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitForStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_variableList, visitor);
    _safelyVisitChild(_initialization, visitor);
    _safelyVisitChild(_condition, visitor);
    _updaters.accept(visitor);
    _safelyVisitChild(_body, visitor);
  }
}

/**
 * A node representing the body of a function or method.
 *
 * > functionBody ::=
 * >     [BlockFunctionBody]
 * >   | [EmptyFunctionBody]
 * >   | [ExpressionFunctionBody]
 */
abstract class FunctionBody extends AstNode {
  /**
   * Return `true` if this function body is asynchronous.
   */
  bool get isAsynchronous => false;

  /**
   * Return `true` if this function body is a generator.
   */
  bool get isGenerator => false;

  /**
   * Return `true` if this function body is synchronous.
   */
  bool get isSynchronous => true;

  /**
   * Return the token representing the 'async' or 'sync' keyword, or `null` if
   * there is no such keyword.
   */
  Token get keyword => null;

  /**
   * Return the star following the 'async' or 'sync' keyword, or `null` if there
   * is no star.
   */
  Token get star => null;
}

/**
 * A top-level declaration.
 *
 * > functionDeclaration ::=
 * >     'external' functionSignature
 * >   | functionSignature [FunctionBody]
 * >
 * > functionSignature ::=
 * >     [Type]? ('get' | 'set')? [SimpleIdentifier] [FormalParameterList]
 */
class FunctionDeclaration extends NamedCompilationUnitMember {
  /**
   * The token representing the 'external' keyword, or `null` if this is not an
   * external function.
   */
  Token externalKeyword;

  /**
   * The return type of the function, or `null` if no return type was declared.
   */
  TypeName _returnType;

  /**
   * The token representing the 'get' or 'set' keyword, or `null` if this is a
   * function declaration rather than a property declaration.
   */
  Token propertyKeyword;

  /**
   * The function expression being wrapped.
   */
  FunctionExpression _functionExpression;

  /**
   * Initialize a newly created function declaration. Either or both of the
   * [comment] and [metadata] can be `null` if the function does not have the
   * corresponding attribute. The [externalKeyword] can be `null` if the
   * function is not an external function. The [returnType] can be `null` if no
   * return type was specified. The [propertyKeyword] can be `null` if the
   * function is neither a getter or a setter.
   */
  FunctionDeclaration(Comment comment, List<Annotation> metadata,
      this.externalKeyword, TypeName returnType, this.propertyKeyword,
      SimpleIdentifier name, FunctionExpression functionExpression)
      : super(comment, metadata, name) {
    _returnType = _becomeParentOf(returnType);
    _functionExpression = _becomeParentOf(functionExpression);
  }

  @override
  Iterable get childEntities => super._childEntities
    ..add(externalKeyword)
    ..add(_returnType)
    ..add(propertyKeyword)
    ..add(_name)
    ..add(_functionExpression);

  @override
  ExecutableElement get element =>
      _name != null ? (_name.staticElement as ExecutableElement) : null;

  @override
  Token get endToken => _functionExpression.endToken;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (externalKeyword != null) {
      return externalKeyword;
    } else if (_returnType != null) {
      return _returnType.beginToken;
    } else if (propertyKeyword != null) {
      return propertyKeyword;
    } else if (_name != null) {
      return _name.beginToken;
    }
    return _functionExpression.beginToken;
  }

  /**
   * Return the function expression being wrapped.
   */
  FunctionExpression get functionExpression => _functionExpression;

  /**
   * Set the function expression being wrapped to the given
   * [functionExpression].
   */
  void set functionExpression(FunctionExpression functionExpression) {
    _functionExpression = _becomeParentOf(functionExpression);
  }

  /**
   * Return `true` if this function declares a getter.
   */
  bool get isGetter => propertyKeyword != null &&
      (propertyKeyword as KeywordToken).keyword == Keyword.GET;

  /**
   * Return `true` if this function declares a setter.
   */
  bool get isSetter => propertyKeyword != null &&
      (propertyKeyword as KeywordToken).keyword == Keyword.SET;

  /**
   * Return the return type of the function, or `null` if no return type was
   * declared.
   */
  TypeName get returnType => _returnType;

  /**
   * Set the return type of the function to the given [returnType].
   */
  void set returnType(TypeName returnType) {
    _returnType = _becomeParentOf(returnType);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitFunctionDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_returnType, visitor);
    _safelyVisitChild(_name, visitor);
    _safelyVisitChild(_functionExpression, visitor);
  }
}

/**
 * A [FunctionDeclaration] used as a statement.
 */
class FunctionDeclarationStatement extends Statement {
  /**
   * The function declaration being wrapped.
   */
  FunctionDeclaration _functionDeclaration;

  /**
   * Initialize a newly created function declaration statement.
   */
  FunctionDeclarationStatement(FunctionDeclaration functionDeclaration) {
    _functionDeclaration = _becomeParentOf(functionDeclaration);
  }

  @override
  Token get beginToken => _functionDeclaration.beginToken;

  @override
  Iterable get childEntities => new ChildEntities()..add(_functionDeclaration);

  @override
  Token get endToken => _functionDeclaration.endToken;

  /**
   * Return the function declaration being wrapped.
   */
  FunctionDeclaration get functionDeclaration => _functionDeclaration;

  /**
   * Set the function declaration being wrapped to the given
   * [functionDeclaration].
   */
  void set functionDeclaration(FunctionDeclaration functionDeclaration) {
    _functionDeclaration = _becomeParentOf(functionDeclaration);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitFunctionDeclarationStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_functionDeclaration, visitor);
  }
}

/**
 * A function expression.
 *
 * > functionExpression ::=
 * >     [FormalParameterList] [FunctionBody]
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
   * The element associated with the function, or `null` if the AST structure
   * has not been resolved.
   */
  ExecutableElement element;

  /**
   * Initialize a newly created function declaration.
   */
  FunctionExpression(FormalParameterList parameters, FunctionBody body) {
    _parameters = _becomeParentOf(parameters);
    _body = _becomeParentOf(body);
  }

  @override
  Token get beginToken {
    if (_parameters != null) {
      return _parameters.beginToken;
    } else if (_body != null) {
      return _body.beginToken;
    }
    // This should never be reached because external functions must be named,
    // hence either the body or the name should be non-null.
    throw new IllegalStateException("Non-external functions must have a body");
  }

  /**
   * Return the body of the function, or `null` if this is an external function.
   */
  FunctionBody get body => _body;

  /**
   * Set the body of the function to the given [functionBody].
   */
  void set body(FunctionBody functionBody) {
    _body = _becomeParentOf(functionBody);
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(_parameters)
    ..add(_body);

  @override
  Token get endToken {
    if (_body != null) {
      return _body.endToken;
    } else if (_parameters != null) {
      return _parameters.endToken;
    }
    // This should never be reached because external functions must be named,
    // hence either the body or the name should be non-null.
    throw new IllegalStateException("Non-external functions must have a body");
  }

  /**
   * Return the parameters associated with the function.
   */
  FormalParameterList get parameters => _parameters;

  /**
   * Set the parameters associated with the function to the given list of
   * [parameters].
   */
  void set parameters(FormalParameterList parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @override
  int get precedence => 16;

  @override
  accept(AstVisitor visitor) => visitor.visitFunctionExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_parameters, visitor);
    _safelyVisitChild(_body, visitor);
  }
}

/**
 * The invocation of a function resulting from evaluating an expression.
 * Invocations of methods and other forms of functions are represented by
 * [MethodInvocation] nodes. Invocations of getters and setters are represented
 * by either [PrefixedIdentifier] or [PropertyAccess] nodes.
 *
 * > functionExpressionInvoction ::=
 * >     [Expression] [ArgumentList]
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
   * The element associated with the function being invoked based on static type
   * information, or `null` if the AST structure has not been resolved or the
   * function could not be resolved.
   */
  ExecutableElement staticElement;

  /**
   * The element associated with the function being invoked based on propagated
   * type information, or `null` if the AST structure has not been resolved or
   * the function could not be resolved.
   */
  ExecutableElement propagatedElement;

  /**
   * Initialize a newly created function expression invocation.
   */
  FunctionExpressionInvocation(Expression function, ArgumentList argumentList) {
    _function = _becomeParentOf(function);
    _argumentList = _becomeParentOf(argumentList);
  }

  /**
   * Return the list of arguments to the method.
   */
  ArgumentList get argumentList => _argumentList;

  /**
   * Set the list of arguments to the method to the given [argumentList].
   */
  void set argumentList(ArgumentList argumentList) {
    _argumentList = _becomeParentOf(argumentList);
  }

  @override
  Token get beginToken => _function.beginToken;

  /**
   * Return the best element available for the function being invoked. If
   * resolution was able to find a better element based on type propagation,
   * that element will be returned. Otherwise, the element found using the
   * result of static analysis will be returned. If resolution has not been
   * performed, then `null` will be returned.
   */
  ExecutableElement get bestElement {
    ExecutableElement element = propagatedElement;
    if (element == null) {
      element = staticElement;
    }
    return element;
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(_function)
    ..add(_argumentList);

  @override
  Token get endToken => _argumentList.endToken;

  /**
   * Return the expression producing the function being invoked.
   */
  Expression get function => _function;

  /**
   * Set the expression producing the function being invoked to the given
   * [expression].
   */
  void set function(Expression expression) {
    _function = _becomeParentOf(expression);
  }

  @override
  int get precedence => 15;

  @override
  accept(AstVisitor visitor) => visitor.visitFunctionExpressionInvocation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_function, visitor);
    _safelyVisitChild(_argumentList, visitor);
  }
}

/**
 * A function type alias.
 *
 * > functionTypeAlias ::=
 * >     functionPrefix [TypeParameterList]? [FormalParameterList] ';'
 * >
 * > functionPrefix ::=
 * >     [TypeName]? [SimpleIdentifier]
 */
class FunctionTypeAlias extends TypeAlias {
  /**
   * The name of the return type of the function type being defined, or `null`
   * if no return type was given.
   */
  TypeName _returnType;

  /**
   * The type parameters for the function type, or `null` if the function type
   * does not have any type parameters.
   */
  TypeParameterList _typeParameters;

  /**
   * The parameters associated with the function type.
   */
  FormalParameterList _parameters;

  /**
   * Initialize a newly created function type alias. Either or both of the
   * [comment] and [metadata] can be `null` if the function does not have the
   * corresponding attribute. The [returnType] can be `null` if no return type
   * was specified. The [typeParameters] can be `null` if the function has no
   * type parameters.
   */
  FunctionTypeAlias(Comment comment, List<Annotation> metadata, Token keyword,
      TypeName returnType, SimpleIdentifier name,
      TypeParameterList typeParameters, FormalParameterList parameters,
      Token semicolon)
      : super(comment, metadata, keyword, name, semicolon) {
    _returnType = _becomeParentOf(returnType);
    _typeParameters = _becomeParentOf(typeParameters);
    _parameters = _becomeParentOf(parameters);
  }

  @override
  Iterable get childEntities => super._childEntities
    ..add(typedefKeyword)
    ..add(_returnType)
    ..add(_name)
    ..add(_typeParameters)
    ..add(_parameters)
    ..add(semicolon);

  @override
  FunctionTypeAliasElement get element =>
      _name != null ? (_name.staticElement as FunctionTypeAliasElement) : null;

  /**
   * Return the parameters associated with the function type.
   */
  FormalParameterList get parameters => _parameters;

  /**
   * Set the parameters associated with the function type to the given list of
   * [parameters].
   */
  void set parameters(FormalParameterList parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  /**
   * Return the name of the return type of the function type being defined, or
   * `null` if no return type was given.
   */
  TypeName get returnType => _returnType;

  /**
   * Set the name of the return type of the function type being defined to the
   * given [typeName].
   */
  void set returnType(TypeName typeName) {
    _returnType = _becomeParentOf(typeName);
  }

  /**
   * Return the type parameters for the function type, or `null` if the function
   * type does not have any type parameters.
   */
  TypeParameterList get typeParameters => _typeParameters;

  /**
   * Set the type parameters for the function type to the given list of
   * [typeParameters].
   */
  void set typeParameters(TypeParameterList typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitFunctionTypeAlias(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_returnType, visitor);
    _safelyVisitChild(_name, visitor);
    _safelyVisitChild(_typeParameters, visitor);
    _safelyVisitChild(_parameters, visitor);
  }
}

/**
 * A function-typed formal parameter.
 *
 * > functionSignature ::=
 * >     [TypeName]? [SimpleIdentifier] [FormalParameterList]
 */
class FunctionTypedFormalParameter extends NormalFormalParameter {
  /**
   * The return type of the function, or `null` if the function does not have a
   * return type.
   */
  TypeName _returnType;

  /**
   * The parameters of the function-typed parameter.
   */
  FormalParameterList _parameters;

  /**
   * Initialize a newly created formal parameter. Either or both of the
   * [comment] and [metadata] can be `null` if the parameter does not have the
   * corresponding attribute. The [returnType] can be `null` if no return type
   * was specified.
   */
  FunctionTypedFormalParameter(Comment comment, List<Annotation> metadata,
      TypeName returnType, SimpleIdentifier identifier,
      FormalParameterList parameters)
      : super(comment, metadata, identifier) {
    _returnType = _becomeParentOf(returnType);
    _parameters = _becomeParentOf(parameters);
  }

  @override
  Token get beginToken {
    if (_returnType != null) {
      return _returnType.beginToken;
    }
    return identifier.beginToken;
  }

  @override
  Iterable get childEntities => super._childEntities
    ..add(_returnType)
    ..add(identifier)
    ..add(parameters);

  @override
  Token get endToken => _parameters.endToken;

  @override
  bool get isConst => false;

  @override
  bool get isFinal => false;

  /**
   * Return the parameters of the function-typed parameter.
   */
  FormalParameterList get parameters => _parameters;

  /**
   * Set the parameters of the function-typed parameter to the given
   * [parameters].
   */
  void set parameters(FormalParameterList parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  /**
   * Return the return type of the function, or `null` if the function does not
   * have a return type.
   */
  TypeName get returnType => _returnType;

  /**
   * Set the return type of the function to the given [type].
   */
  void set returnType(TypeName type) {
    _returnType = _becomeParentOf(type);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitFunctionTypedFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_returnType, visitor);
    _safelyVisitChild(identifier, visitor);
    _safelyVisitChild(_parameters, visitor);
  }
}

/**
 * An AST visitor that will recursively visit all of the nodes in an AST
 * structure (like instances of the class [RecursiveAstVisitor]). In addition,
 * when a node of a specific type is visited not only will the visit method for
 * that specific type of node be invoked, but additional methods for the
 * superclasses of that node will also be invoked. For example, using an
 * instance of this class to visit a [Block] will cause the method [visitBlock]
 * to be invoked but will also cause the methods [visitStatement] and
 * [visitNode] to be subsequently invoked. This allows visitors to be written
 * that visit all statements without needing to override the visit method for
 * each of the specific subclasses of [Statement].
 *
 * Subclasses that override a visit method must either invoke the overridden
 * visit method or explicitly invoke the more general visit method. Failure to
 * do so will cause the visit methods for superclasses of the node to not be
 * invoked and will cause the children of the visited node to not be visited.
 */
class GeneralizingAstVisitor<R> implements AstVisitor<R> {
  @override
  R visitAdjacentStrings(AdjacentStrings node) => visitStringLiteral(node);

  R visitAnnotatedNode(AnnotatedNode node) => visitNode(node);

  @override
  R visitAnnotation(Annotation node) => visitNode(node);

  @override
  R visitArgumentList(ArgumentList node) => visitNode(node);

  @override
  R visitAsExpression(AsExpression node) => visitExpression(node);

  @override
  R visitAssertStatement(AssertStatement node) => visitStatement(node);

  @override
  R visitAssignmentExpression(AssignmentExpression node) =>
      visitExpression(node);

  @override
  R visitAwaitExpression(AwaitExpression node) => visitExpression(node);

  @override
  R visitBinaryExpression(BinaryExpression node) => visitExpression(node);

  @override
  R visitBlock(Block node) => visitStatement(node);

  @override
  R visitBlockFunctionBody(BlockFunctionBody node) => visitFunctionBody(node);

  @override
  R visitBooleanLiteral(BooleanLiteral node) => visitLiteral(node);

  @override
  R visitBreakStatement(BreakStatement node) => visitStatement(node);

  @override
  R visitCascadeExpression(CascadeExpression node) => visitExpression(node);

  @override
  R visitCatchClause(CatchClause node) => visitNode(node);

  @override
  R visitClassDeclaration(ClassDeclaration node) =>
      visitNamedCompilationUnitMember(node);

  R visitClassMember(ClassMember node) => visitDeclaration(node);

  @override
  R visitClassTypeAlias(ClassTypeAlias node) => visitTypeAlias(node);

  R visitCombinator(Combinator node) => visitNode(node);

  @override
  R visitComment(Comment node) => visitNode(node);

  @override
  R visitCommentReference(CommentReference node) => visitNode(node);

  @override
  R visitCompilationUnit(CompilationUnit node) => visitNode(node);

  R visitCompilationUnitMember(CompilationUnitMember node) =>
      visitDeclaration(node);

  @override
  R visitConditionalExpression(ConditionalExpression node) =>
      visitExpression(node);

  @override
  R visitConstructorDeclaration(ConstructorDeclaration node) =>
      visitClassMember(node);

  @override
  R visitConstructorFieldInitializer(ConstructorFieldInitializer node) =>
      visitConstructorInitializer(node);

  R visitConstructorInitializer(ConstructorInitializer node) => visitNode(node);

  @override
  R visitConstructorName(ConstructorName node) => visitNode(node);

  @override
  R visitContinueStatement(ContinueStatement node) => visitStatement(node);

  R visitDeclaration(Declaration node) => visitAnnotatedNode(node);

  @override
  R visitDeclaredIdentifier(DeclaredIdentifier node) => visitDeclaration(node);

  @override
  R visitDefaultFormalParameter(DefaultFormalParameter node) =>
      visitFormalParameter(node);

  R visitDirective(Directive node) => visitAnnotatedNode(node);

  @override
  R visitDoStatement(DoStatement node) => visitStatement(node);

  @override
  R visitDoubleLiteral(DoubleLiteral node) => visitLiteral(node);

  @override
  R visitEmptyFunctionBody(EmptyFunctionBody node) => visitFunctionBody(node);

  @override
  R visitEmptyStatement(EmptyStatement node) => visitStatement(node);

  @override
  R visitEnumConstantDeclaration(EnumConstantDeclaration node) =>
      visitDeclaration(node);

  @override
  R visitEnumDeclaration(EnumDeclaration node) =>
      visitNamedCompilationUnitMember(node);

  @override
  R visitExportDirective(ExportDirective node) => visitNamespaceDirective(node);

  R visitExpression(Expression node) => visitNode(node);

  @override
  R visitExpressionFunctionBody(ExpressionFunctionBody node) =>
      visitFunctionBody(node);

  @override
  R visitExpressionStatement(ExpressionStatement node) => visitStatement(node);

  @override
  R visitExtendsClause(ExtendsClause node) => visitNode(node);

  @override
  R visitFieldDeclaration(FieldDeclaration node) => visitClassMember(node);

  @override
  R visitFieldFormalParameter(FieldFormalParameter node) =>
      visitNormalFormalParameter(node);

  @override
  R visitForEachStatement(ForEachStatement node) => visitStatement(node);

  R visitFormalParameter(FormalParameter node) => visitNode(node);

  @override
  R visitFormalParameterList(FormalParameterList node) => visitNode(node);

  @override
  R visitForStatement(ForStatement node) => visitStatement(node);

  R visitFunctionBody(FunctionBody node) => visitNode(node);

  @override
  R visitFunctionDeclaration(FunctionDeclaration node) =>
      visitNamedCompilationUnitMember(node);

  @override
  R visitFunctionDeclarationStatement(FunctionDeclarationStatement node) =>
      visitStatement(node);

  @override
  R visitFunctionExpression(FunctionExpression node) => visitExpression(node);

  @override
  R visitFunctionExpressionInvocation(FunctionExpressionInvocation node) =>
      visitExpression(node);

  @override
  R visitFunctionTypeAlias(FunctionTypeAlias node) => visitTypeAlias(node);

  @override
  R visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) =>
      visitNormalFormalParameter(node);

  @override
  R visitHideCombinator(HideCombinator node) => visitCombinator(node);

  R visitIdentifier(Identifier node) => visitExpression(node);

  @override
  R visitIfStatement(IfStatement node) => visitStatement(node);

  @override
  R visitImplementsClause(ImplementsClause node) => visitNode(node);

  @override
  R visitImportDirective(ImportDirective node) => visitNamespaceDirective(node);

  @override
  R visitIndexExpression(IndexExpression node) => visitExpression(node);

  @override
  R visitInstanceCreationExpression(InstanceCreationExpression node) =>
      visitExpression(node);

  @override
  R visitIntegerLiteral(IntegerLiteral node) => visitLiteral(node);

  R visitInterpolationElement(InterpolationElement node) => visitNode(node);

  @override
  R visitInterpolationExpression(InterpolationExpression node) =>
      visitInterpolationElement(node);

  @override
  R visitInterpolationString(InterpolationString node) =>
      visitInterpolationElement(node);

  @override
  R visitIsExpression(IsExpression node) => visitExpression(node);

  @override
  R visitLabel(Label node) => visitNode(node);

  @override
  R visitLabeledStatement(LabeledStatement node) => visitStatement(node);

  @override
  R visitLibraryDirective(LibraryDirective node) => visitDirective(node);

  @override
  R visitLibraryIdentifier(LibraryIdentifier node) => visitIdentifier(node);

  @override
  R visitListLiteral(ListLiteral node) => visitTypedLiteral(node);

  R visitLiteral(Literal node) => visitExpression(node);

  @override
  R visitMapLiteral(MapLiteral node) => visitTypedLiteral(node);

  @override
  R visitMapLiteralEntry(MapLiteralEntry node) => visitNode(node);

  @override
  R visitMethodDeclaration(MethodDeclaration node) => visitClassMember(node);

  @override
  R visitMethodInvocation(MethodInvocation node) => visitExpression(node);

  R visitNamedCompilationUnitMember(NamedCompilationUnitMember node) =>
      visitCompilationUnitMember(node);

  @override
  R visitNamedExpression(NamedExpression node) => visitExpression(node);

  R visitNamespaceDirective(NamespaceDirective node) =>
      visitUriBasedDirective(node);

  @override
  R visitNativeClause(NativeClause node) => visitNode(node);

  @override
  R visitNativeFunctionBody(NativeFunctionBody node) => visitFunctionBody(node);

  R visitNode(AstNode node) {
    node.visitChildren(this);
    return null;
  }

  R visitNormalFormalParameter(NormalFormalParameter node) =>
      visitFormalParameter(node);

  @override
  R visitNullLiteral(NullLiteral node) => visitLiteral(node);

  @override
  R visitParenthesizedExpression(ParenthesizedExpression node) =>
      visitExpression(node);

  @override
  R visitPartDirective(PartDirective node) => visitUriBasedDirective(node);

  @override
  R visitPartOfDirective(PartOfDirective node) => visitDirective(node);

  @override
  R visitPostfixExpression(PostfixExpression node) => visitExpression(node);

  @override
  R visitPrefixedIdentifier(PrefixedIdentifier node) => visitIdentifier(node);

  @override
  R visitPrefixExpression(PrefixExpression node) => visitExpression(node);

  @override
  R visitPropertyAccess(PropertyAccess node) => visitExpression(node);

  @override
  R visitRedirectingConstructorInvocation(
          RedirectingConstructorInvocation node) =>
      visitConstructorInitializer(node);

  @override
  R visitRethrowExpression(RethrowExpression node) => visitExpression(node);

  @override
  R visitReturnStatement(ReturnStatement node) => visitStatement(node);

  @override
  R visitScriptTag(ScriptTag scriptTag) => visitNode(scriptTag);

  @override
  R visitShowCombinator(ShowCombinator node) => visitCombinator(node);

  @override
  R visitSimpleFormalParameter(SimpleFormalParameter node) =>
      visitNormalFormalParameter(node);

  @override
  R visitSimpleIdentifier(SimpleIdentifier node) => visitIdentifier(node);

  @override
  R visitSimpleStringLiteral(SimpleStringLiteral node) =>
      visitSingleStringLiteral(node);

  R visitSingleStringLiteral(SingleStringLiteral node) =>
      visitStringLiteral(node);

  R visitStatement(Statement node) => visitNode(node);

  @override
  R visitStringInterpolation(StringInterpolation node) =>
      visitSingleStringLiteral(node);

  R visitStringLiteral(StringLiteral node) => visitLiteral(node);

  @override
  R visitSuperConstructorInvocation(SuperConstructorInvocation node) =>
      visitConstructorInitializer(node);

  @override
  R visitSuperExpression(SuperExpression node) => visitExpression(node);

  @override
  R visitSwitchCase(SwitchCase node) => visitSwitchMember(node);

  @override
  R visitSwitchDefault(SwitchDefault node) => visitSwitchMember(node);

  R visitSwitchMember(SwitchMember node) => visitNode(node);

  @override
  R visitSwitchStatement(SwitchStatement node) => visitStatement(node);

  @override
  R visitSymbolLiteral(SymbolLiteral node) => visitLiteral(node);

  @override
  R visitThisExpression(ThisExpression node) => visitExpression(node);

  @override
  R visitThrowExpression(ThrowExpression node) => visitExpression(node);

  @override
  R visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) =>
      visitCompilationUnitMember(node);

  @override
  R visitTryStatement(TryStatement node) => visitStatement(node);

  R visitTypeAlias(TypeAlias node) => visitNamedCompilationUnitMember(node);

  @override
  R visitTypeArgumentList(TypeArgumentList node) => visitNode(node);

  R visitTypedLiteral(TypedLiteral node) => visitLiteral(node);

  @override
  R visitTypeName(TypeName node) => visitNode(node);

  @override
  R visitTypeParameter(TypeParameter node) => visitNode(node);

  @override
  R visitTypeParameterList(TypeParameterList node) => visitNode(node);

  R visitUriBasedDirective(UriBasedDirective node) => visitDirective(node);

  @override
  R visitVariableDeclaration(VariableDeclaration node) =>
      visitDeclaration(node);

  @override
  R visitVariableDeclarationList(VariableDeclarationList node) =>
      visitNode(node);

  @override
  R visitVariableDeclarationStatement(VariableDeclarationStatement node) =>
      visitStatement(node);

  @override
  R visitWhileStatement(WhileStatement node) => visitStatement(node);

  @override
  R visitWithClause(WithClause node) => visitNode(node);

  @override
  R visitYieldStatement(YieldStatement node) => visitStatement(node);
}

class GeneralizingAstVisitor_BreadthFirstVisitor
    extends GeneralizingAstVisitor<Object> {
  final BreadthFirstVisitor BreadthFirstVisitor_this;

  GeneralizingAstVisitor_BreadthFirstVisitor(this.BreadthFirstVisitor_this)
      : super();

  @override
  Object visitNode(AstNode node) {
    BreadthFirstVisitor_this._queue.add(node);
    return null;
  }
}

/**
 * A combinator that restricts the names being imported to those that are not in
 * a given list.
 *
 * > hideCombinator ::=
 * >     'hide' [SimpleIdentifier] (',' [SimpleIdentifier])*
 */
class HideCombinator extends Combinator {
  /**
   * The list of names from the library that are hidden by this combinator.
   */
  NodeList<SimpleIdentifier> _hiddenNames;

  /**
   * Initialize a newly created import show combinator.
   */
  HideCombinator(Token keyword, List<SimpleIdentifier> hiddenNames)
      : super(keyword) {
    _hiddenNames = new NodeList<SimpleIdentifier>(this, hiddenNames);
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(keyword)
    ..addAll(_hiddenNames);

  @override
  Token get endToken => _hiddenNames.endToken;

  /**
   * Return the list of names from the library that are hidden by this
   * combinator.
   */
  NodeList<SimpleIdentifier> get hiddenNames => _hiddenNames;

  @override
  accept(AstVisitor visitor) => visitor.visitHideCombinator(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _hiddenNames.accept(visitor);
  }
}

/**
 * A node that represents an identifier.
 *
 * > identifier ::=
 * >     [SimpleIdentifier]
 * >   | [PrefixedIdentifier]
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

  @override
  bool get isAssignable => true;

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
      StringUtilities.startsWithChar(name, 0x5F);
}

/**
 * An if statement.
 *
 * > ifStatement ::=
 * >     'if' '(' [Expression] ')' [Statement] ('else' [Statement])?
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
   * The token representing the 'else' keyword, or `null` if there is no else
   * statement.
   */
  Token elseKeyword;

  /**
   * The statement that is executed if the condition evaluates to `false`, or
   * `null` if there is no else statement.
   */
  Statement _elseStatement;

  /**
   * Initialize a newly created if statement. The [elseKeyword] and
   * [elseStatement] can be `null` if there is no else clause.
   */
  IfStatement(this.ifKeyword, this.leftParenthesis, Expression condition,
      this.rightParenthesis, Statement thenStatement, this.elseKeyword,
      Statement elseStatement) {
    _condition = _becomeParentOf(condition);
    _thenStatement = _becomeParentOf(thenStatement);
    _elseStatement = _becomeParentOf(elseStatement);
  }

  @override
  Token get beginToken => ifKeyword;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(ifKeyword)
    ..add(leftParenthesis)
    ..add(_condition)
    ..add(rightParenthesis)
    ..add(_thenStatement)
    ..add(elseKeyword)
    ..add(_elseStatement);

  /**
   * Return the condition used to determine which of the statements is executed
   * next.
   */
  Expression get condition => _condition;

  /**
   * Set the condition used to determine which of the statements is executed
   * next to the given [expression].
   */
  void set condition(Expression expression) {
    _condition = _becomeParentOf(expression);
  }

  /**
   * Return the statement that is executed if the condition evaluates to
   * `false`, or `null` if there is no else statement.
   */
  Statement get elseStatement => _elseStatement;

  /**
   * Set the statement that is executed if the condition evaluates to `false`
   * to the given [statement].
   */
  void set elseStatement(Statement statement) {
    _elseStatement = _becomeParentOf(statement);
  }

  @override
  Token get endToken {
    if (_elseStatement != null) {
      return _elseStatement.endToken;
    }
    return _thenStatement.endToken;
  }

  /**
   * Return the statement that is executed if the condition evaluates to `true`.
   */
  Statement get thenStatement => _thenStatement;

  /**
   * Set the statement that is executed if the condition evaluates to `true` to
   * the given [statement].
   */
  void set thenStatement(Statement statement) {
    _thenStatement = _becomeParentOf(statement);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitIfStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_condition, visitor);
    _safelyVisitChild(_thenStatement, visitor);
    _safelyVisitChild(_elseStatement, visitor);
  }
}

/**
 * The "implements" clause in an class declaration.
 *
 * > implementsClause ::=
 * >     'implements' [TypeName] (',' [TypeName])*
 */
class ImplementsClause extends AstNode {
  /**
   * The token representing the 'implements' keyword.
   */
  Token implementsKeyword;

  /**
   * The interfaces that are being implemented.
   */
  NodeList<TypeName> _interfaces;

  /**
   * Initialize a newly created implements clause.
   */
  ImplementsClause(this.implementsKeyword, List<TypeName> interfaces) {
    _interfaces = new NodeList<TypeName>(this, interfaces);
  }

  @override
  Token get beginToken => implementsKeyword;

  /**
   * TODO(paulberry): add commas.
   */
  @override
  Iterable get childEntities => new ChildEntities()
    ..add(implementsKeyword)
    ..addAll(interfaces);

  @override
  Token get endToken => _interfaces.endToken;

  /**
   * Return the list of the interfaces that are being implemented.
   */
  NodeList<TypeName> get interfaces => _interfaces;

  /**
   * Return the token representing the 'implements' keyword.
   */
  @deprecated // Use "this.implementsKeyword"
  Token get keyword => implementsKeyword;

  /**
   * Set the token representing the 'implements' keyword to the given [token].
   */
  @deprecated // Use "this.implementsKeyword"
  set keyword(Token token) {
    implementsKeyword = token;
  }

  @override
  accept(AstVisitor visitor) => visitor.visitImplementsClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _interfaces.accept(visitor);
  }
}

/**
 * An import directive.
 *
 * > importDirective ::=
 * >     [Annotation] 'import' [StringLiteral] ('as' identifier)? [Combinator]* ';'
 * >   | [Annotation] 'import' [StringLiteral] 'deferred' 'as' identifier [Combinator]* ';'
 */
class ImportDirective extends NamespaceDirective {
  static Comparator<ImportDirective> COMPARATOR = (ImportDirective import1,
      ImportDirective import2) {
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
        NodeList<SimpleIdentifier> shows =
            (combinator as ShowCombinator).shownNames;
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
        NodeList<SimpleIdentifier> shows =
            (combinator as ShowCombinator).shownNames;
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
   * The token representing the 'deferred' keyword, or `null` if the imported is
   * not deferred.
   */
  Token deferredKeyword;

  /**
   * The token representing the 'as' keyword, or `null` if the imported names are
   * not prefixed.
   */
  Token asKeyword;

  /**
   * The prefix to be used with the imported names, or `null` if the imported
   * names are not prefixed.
   */
  SimpleIdentifier _prefix;

  /**
   * Initialize a newly created import directive. Either or both of the
   * [comment] and [metadata] can be `null` if the function does not have the
   * corresponding attribute. The [deferredKeyword] can be `null` if the import
   * is not deferred. The [asKeyword] and [prefix] can be `null` if the import
   * does not specify a prefix. The list of [combinators] can be `null` if there
   * are no combinators.
   */
  ImportDirective(Comment comment, List<Annotation> metadata, Token keyword,
      StringLiteral libraryUri, this.deferredKeyword, this.asKeyword,
      SimpleIdentifier prefix, List<Combinator> combinators, Token semicolon)
      : super(comment, metadata, keyword, libraryUri, combinators, semicolon) {
    _prefix = _becomeParentOf(prefix);
  }

  /**
   * The token representing the 'as' token, or `null` if the imported names are
   * not prefixed.
   */
  @deprecated // Use "this.asKeyword"
  Token get asToken => asKeyword;

  /**
   * The token representing the 'as' token to the given token.
   */
  @deprecated // Use "this.asKeyword"
  set asToken(Token token) {
    asKeyword = token;
  }

  @override
  Iterable get childEntities => super._childEntities
    ..add(_uri)
    ..add(deferredKeyword)
    ..add(asKeyword)
    ..add(_prefix)
    ..addAll(combinators)
    ..add(semicolon);

  /**
   * Return the token representing the 'deferred' token, or `null` if the
   * imported is not deferred.
   */
  @deprecated // Use "this.deferredKeyword"
  Token get deferredToken => deferredKeyword;

  /**
   * Set the token representing the 'deferred' token to the given token.
   */
  @deprecated // Use "this.deferredKeyword"
  set deferredToken(Token token) {
    deferredKeyword = token;
  }

  @override
  ImportElement get element => super.element as ImportElement;

  /**
   * Return the prefix to be used with the imported names, or `null` if the
   * imported names are not prefixed.
   */
  SimpleIdentifier get prefix => _prefix;

  /**
   * Set the prefix to be used with the imported names to the given [identifier].
   */
  void set prefix(SimpleIdentifier identifier) {
    _prefix = _becomeParentOf(identifier);
  }

  @override
  LibraryElement get uriElement {
    ImportElement element = this.element;
    if (element == null) {
      return null;
    }
    return element.importedLibrary;
  }

  @override
  accept(AstVisitor visitor) => visitor.visitImportDirective(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_prefix, visitor);
    combinators.accept(visitor);
  }
}

/**
 * An object that will clone any AST structure that it visits. The cloner will
 * clone the structure, replacing the specified ASTNode with a new ASTNode,
 * mapping the old token stream to a new token stream, and preserving resolution
 * results.
 */
class IncrementalAstCloner implements AstVisitor<AstNode> {
  /**
   * The node to be replaced during the cloning process.
   */
  final AstNode _oldNode;

  /**
   * The replacement node used during the cloning process.
   */
  final AstNode _newNode;

  /**
   * A mapping of old tokens to new tokens used during the cloning process.
   */
  final TokenMap _tokenMap;

  /**
   * Construct a new instance that will replace the [oldNode] with the [newNode]
   * in the process of cloning an existing AST structure. The [tokenMap] is a
   * mapping of old tokens to new tokens.
   */
  IncrementalAstCloner(this._oldNode, this._newNode, this._tokenMap);

  @override
  AdjacentStrings visitAdjacentStrings(AdjacentStrings node) =>
      new AdjacentStrings(_cloneNodeList(node.strings));

  @override
  Annotation visitAnnotation(Annotation node) {
    Annotation copy = new Annotation(_mapToken(node.atSign),
        _cloneNode(node.name), _mapToken(node.period),
        _cloneNode(node.constructorName), _cloneNode(node.arguments));
    copy.element = node.element;
    return copy;
  }

  @override
  ArgumentList visitArgumentList(ArgumentList node) => new ArgumentList(
      _mapToken(node.leftParenthesis), _cloneNodeList(node.arguments),
      _mapToken(node.rightParenthesis));

  @override
  AsExpression visitAsExpression(AsExpression node) {
    AsExpression copy = new AsExpression(_cloneNode(node.expression),
        _mapToken(node.asOperator), _cloneNode(node.type));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  AstNode visitAssertStatement(AssertStatement node) => new AssertStatement(
      _mapToken(node.assertKeyword), _mapToken(node.leftParenthesis),
      _cloneNode(node.condition), _mapToken(node.rightParenthesis),
      _mapToken(node.semicolon));

  @override
  AssignmentExpression visitAssignmentExpression(AssignmentExpression node) {
    AssignmentExpression copy = new AssignmentExpression(
        _cloneNode(node.leftHandSide), _mapToken(node.operator),
        _cloneNode(node.rightHandSide));
    copy.propagatedElement = node.propagatedElement;
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  AwaitExpression visitAwaitExpression(AwaitExpression node) =>
      new AwaitExpression(
          _mapToken(node.awaitKeyword), _cloneNode(node.expression));

  @override
  BinaryExpression visitBinaryExpression(BinaryExpression node) {
    BinaryExpression copy = new BinaryExpression(_cloneNode(node.leftOperand),
        _mapToken(node.operator), _cloneNode(node.rightOperand));
    copy.propagatedElement = node.propagatedElement;
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  Block visitBlock(Block node) => new Block(_mapToken(node.leftBracket),
      _cloneNodeList(node.statements), _mapToken(node.rightBracket));

  @override
  BlockFunctionBody visitBlockFunctionBody(
      BlockFunctionBody node) => new BlockFunctionBody(
      _mapToken(node.keyword), _mapToken(node.star), _cloneNode(node.block));

  @override
  BooleanLiteral visitBooleanLiteral(BooleanLiteral node) {
    BooleanLiteral copy =
        new BooleanLiteral(_mapToken(node.literal), node.value);
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  BreakStatement visitBreakStatement(BreakStatement node) => new BreakStatement(
      _mapToken(node.breakKeyword), _cloneNode(node.label),
      _mapToken(node.semicolon));

  @override
  CascadeExpression visitCascadeExpression(CascadeExpression node) {
    CascadeExpression copy = new CascadeExpression(
        _cloneNode(node.target), _cloneNodeList(node.cascadeSections));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  CatchClause visitCatchClause(CatchClause node) => new CatchClause(
      _mapToken(node.onKeyword), _cloneNode(node.exceptionType),
      _mapToken(node.catchKeyword), _mapToken(node.leftParenthesis),
      _cloneNode(node.exceptionParameter), _mapToken(node.comma),
      _cloneNode(node.stackTraceParameter), _mapToken(node.rightParenthesis),
      _cloneNode(node.body));

  @override
  ClassDeclaration visitClassDeclaration(ClassDeclaration node) {
    ClassDeclaration copy = new ClassDeclaration(
        _cloneNode(node.documentationComment), _cloneNodeList(node.metadata),
        _mapToken(node.abstractKeyword), _mapToken(node.classKeyword),
        _cloneNode(node.name), _cloneNode(node.typeParameters),
        _cloneNode(node.extendsClause), _cloneNode(node.withClause),
        _cloneNode(node.implementsClause), _mapToken(node.leftBracket),
        _cloneNodeList(node.members), _mapToken(node.rightBracket));
    copy.nativeClause = _cloneNode(node.nativeClause);
    return copy;
  }

  @override
  ClassTypeAlias visitClassTypeAlias(ClassTypeAlias node) => new ClassTypeAlias(
      _cloneNode(node.documentationComment), _cloneNodeList(node.metadata),
      _mapToken(node.typedefKeyword), _cloneNode(node.name),
      _cloneNode(node.typeParameters), _mapToken(node.equals),
      _mapToken(node.abstractKeyword), _cloneNode(node.superclass),
      _cloneNode(node.withClause), _cloneNode(node.implementsClause),
      _mapToken(node.semicolon));

  @override
  Comment visitComment(Comment node) {
    if (node.isDocumentation) {
      return Comment.createDocumentationCommentWithReferences(
          _mapTokens(node.tokens), _cloneNodeList(node.references));
    } else if (node.isBlock) {
      return Comment.createBlockComment(_mapTokens(node.tokens));
    }
    return Comment.createEndOfLineComment(_mapTokens(node.tokens));
  }

  @override
  CommentReference visitCommentReference(CommentReference node) =>
      new CommentReference(
          _mapToken(node.newKeyword), _cloneNode(node.identifier));

  @override
  CompilationUnit visitCompilationUnit(CompilationUnit node) {
    CompilationUnit copy = new CompilationUnit(_mapToken(node.beginToken),
        _cloneNode(node.scriptTag), _cloneNodeList(node.directives),
        _cloneNodeList(node.declarations), _mapToken(node.endToken));
    copy.lineInfo = node.lineInfo;
    copy.element = node.element;
    return copy;
  }

  @override
  ConditionalExpression visitConditionalExpression(ConditionalExpression node) {
    ConditionalExpression copy = new ConditionalExpression(
        _cloneNode(node.condition), _mapToken(node.question),
        _cloneNode(node.thenExpression), _mapToken(node.colon),
        _cloneNode(node.elseExpression));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  ConstructorDeclaration visitConstructorDeclaration(
      ConstructorDeclaration node) {
    ConstructorDeclaration copy = new ConstructorDeclaration(
        _cloneNode(node.documentationComment), _cloneNodeList(node.metadata),
        _mapToken(node.externalKeyword), _mapToken(node.constKeyword),
        _mapToken(node.factoryKeyword), _cloneNode(node.returnType),
        _mapToken(node.period), _cloneNode(node.name),
        _cloneNode(node.parameters), _mapToken(node.separator),
        _cloneNodeList(node.initializers),
        _cloneNode(node.redirectedConstructor), _cloneNode(node.body));
    copy.element = node.element;
    return copy;
  }

  @override
  ConstructorFieldInitializer visitConstructorFieldInitializer(
      ConstructorFieldInitializer node) => new ConstructorFieldInitializer(
      _mapToken(node.thisKeyword), _mapToken(node.period),
      _cloneNode(node.fieldName), _mapToken(node.equals),
      _cloneNode(node.expression));

  @override
  ConstructorName visitConstructorName(ConstructorName node) {
    ConstructorName copy = new ConstructorName(
        _cloneNode(node.type), _mapToken(node.period), _cloneNode(node.name));
    copy.staticElement = node.staticElement;
    return copy;
  }

  @override
  ContinueStatement visitContinueStatement(ContinueStatement node) =>
      new ContinueStatement(_mapToken(node.continueKeyword),
          _cloneNode(node.label), _mapToken(node.semicolon));

  @override
  DeclaredIdentifier visitDeclaredIdentifier(DeclaredIdentifier node) =>
      new DeclaredIdentifier(_cloneNode(node.documentationComment),
          _cloneNodeList(node.metadata), _mapToken(node.keyword),
          _cloneNode(node.type), _cloneNode(node.identifier));

  @override
  DefaultFormalParameter visitDefaultFormalParameter(
      DefaultFormalParameter node) => new DefaultFormalParameter(
      _cloneNode(node.parameter), node.kind, _mapToken(node.separator),
      _cloneNode(node.defaultValue));

  @override
  DoStatement visitDoStatement(DoStatement node) => new DoStatement(
      _mapToken(node.doKeyword), _cloneNode(node.body),
      _mapToken(node.whileKeyword), _mapToken(node.leftParenthesis),
      _cloneNode(node.condition), _mapToken(node.rightParenthesis),
      _mapToken(node.semicolon));

  @override
  DoubleLiteral visitDoubleLiteral(DoubleLiteral node) {
    DoubleLiteral copy = new DoubleLiteral(_mapToken(node.literal), node.value);
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  EmptyFunctionBody visitEmptyFunctionBody(EmptyFunctionBody node) =>
      new EmptyFunctionBody(_mapToken(node.semicolon));

  @override
  EmptyStatement visitEmptyStatement(EmptyStatement node) =>
      new EmptyStatement(_mapToken(node.semicolon));

  @override
  AstNode visitEnumConstantDeclaration(EnumConstantDeclaration node) =>
      new EnumConstantDeclaration(_cloneNode(node.documentationComment),
          _cloneNodeList(node.metadata), _cloneNode(node.name));

  @override
  AstNode visitEnumDeclaration(EnumDeclaration node) => new EnumDeclaration(
      _cloneNode(node.documentationComment), _cloneNodeList(node.metadata),
      _mapToken(node.enumKeyword), _cloneNode(node.name),
      _mapToken(node.leftBracket), _cloneNodeList(node.constants),
      _mapToken(node.rightBracket));

  @override
  ExportDirective visitExportDirective(ExportDirective node) {
    ExportDirective copy = new ExportDirective(
        _cloneNode(node.documentationComment), _cloneNodeList(node.metadata),
        _mapToken(node.keyword), _cloneNode(node.uri),
        _cloneNodeList(node.combinators), _mapToken(node.semicolon));
    copy.element = node.element;
    return copy;
  }

  @override
  ExpressionFunctionBody visitExpressionFunctionBody(
      ExpressionFunctionBody node) => new ExpressionFunctionBody(
      _mapToken(node.keyword), _mapToken(node.functionDefinition),
      _cloneNode(node.expression), _mapToken(node.semicolon));

  @override
  ExpressionStatement visitExpressionStatement(ExpressionStatement node) =>
      new ExpressionStatement(
          _cloneNode(node.expression), _mapToken(node.semicolon));

  @override
  ExtendsClause visitExtendsClause(ExtendsClause node) => new ExtendsClause(
      _mapToken(node.extendsKeyword), _cloneNode(node.superclass));

  @override
  FieldDeclaration visitFieldDeclaration(FieldDeclaration node) =>
      new FieldDeclaration(_cloneNode(node.documentationComment),
          _cloneNodeList(node.metadata), _mapToken(node.staticKeyword),
          _cloneNode(node.fields), _mapToken(node.semicolon));

  @override
  FieldFormalParameter visitFieldFormalParameter(FieldFormalParameter node) =>
      new FieldFormalParameter(_cloneNode(node.documentationComment),
          _cloneNodeList(node.metadata), _mapToken(node.keyword),
          _cloneNode(node.type), _mapToken(node.thisKeyword),
          _mapToken(node.period), _cloneNode(node.identifier),
          _cloneNode(node.parameters));

  @override
  ForEachStatement visitForEachStatement(ForEachStatement node) {
    DeclaredIdentifier loopVariable = node.loopVariable;
    if (loopVariable == null) {
      return new ForEachStatement.con2(_mapToken(node.awaitKeyword),
          _mapToken(node.forKeyword), _mapToken(node.leftParenthesis),
          _cloneNode(node.identifier), _mapToken(node.inKeyword),
          _cloneNode(node.iterable), _mapToken(node.rightParenthesis),
          _cloneNode(node.body));
    }
    return new ForEachStatement.con1(_mapToken(node.awaitKeyword),
        _mapToken(node.forKeyword), _mapToken(node.leftParenthesis),
        _cloneNode(loopVariable), _mapToken(node.inKeyword),
        _cloneNode(node.iterable), _mapToken(node.rightParenthesis),
        _cloneNode(node.body));
  }

  @override
  FormalParameterList visitFormalParameterList(FormalParameterList node) =>
      new FormalParameterList(_mapToken(node.leftParenthesis),
          _cloneNodeList(node.parameters), _mapToken(node.leftDelimiter),
          _mapToken(node.rightDelimiter), _mapToken(node.rightParenthesis));

  @override
  ForStatement visitForStatement(ForStatement node) => new ForStatement(
      _mapToken(node.forKeyword), _mapToken(node.leftParenthesis),
      _cloneNode(node.variables), _cloneNode(node.initialization),
      _mapToken(node.leftSeparator), _cloneNode(node.condition),
      _mapToken(node.rightSeparator), _cloneNodeList(node.updaters),
      _mapToken(node.rightParenthesis), _cloneNode(node.body));

  @override
  FunctionDeclaration visitFunctionDeclaration(FunctionDeclaration node) =>
      new FunctionDeclaration(_cloneNode(node.documentationComment),
          _cloneNodeList(node.metadata), _mapToken(node.externalKeyword),
          _cloneNode(node.returnType), _mapToken(node.propertyKeyword),
          _cloneNode(node.name), _cloneNode(node.functionExpression));

  @override
  FunctionDeclarationStatement visitFunctionDeclarationStatement(
          FunctionDeclarationStatement node) =>
      new FunctionDeclarationStatement(_cloneNode(node.functionDeclaration));

  @override
  FunctionExpression visitFunctionExpression(FunctionExpression node) {
    FunctionExpression copy = new FunctionExpression(
        _cloneNode(node.parameters), _cloneNode(node.body));
    copy.element = node.element;
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  FunctionExpressionInvocation visitFunctionExpressionInvocation(
      FunctionExpressionInvocation node) {
    FunctionExpressionInvocation copy = new FunctionExpressionInvocation(
        _cloneNode(node.function), _cloneNode(node.argumentList));
    copy.propagatedElement = node.propagatedElement;
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  FunctionTypeAlias visitFunctionTypeAlias(FunctionTypeAlias node) =>
      new FunctionTypeAlias(_cloneNode(node.documentationComment),
          _cloneNodeList(node.metadata), _mapToken(node.typedefKeyword),
          _cloneNode(node.returnType), _cloneNode(node.name),
          _cloneNode(node.typeParameters), _cloneNode(node.parameters),
          _mapToken(node.semicolon));

  @override
  FunctionTypedFormalParameter visitFunctionTypedFormalParameter(
      FunctionTypedFormalParameter node) => new FunctionTypedFormalParameter(
      _cloneNode(node.documentationComment), _cloneNodeList(node.metadata),
      _cloneNode(node.returnType), _cloneNode(node.identifier),
      _cloneNode(node.parameters));

  @override
  HideCombinator visitHideCombinator(HideCombinator node) => new HideCombinator(
      _mapToken(node.keyword), _cloneNodeList(node.hiddenNames));

  @override
  IfStatement visitIfStatement(IfStatement node) => new IfStatement(
      _mapToken(node.ifKeyword), _mapToken(node.leftParenthesis),
      _cloneNode(node.condition), _mapToken(node.rightParenthesis),
      _cloneNode(node.thenStatement), _mapToken(node.elseKeyword),
      _cloneNode(node.elseStatement));

  @override
  ImplementsClause visitImplementsClause(ImplementsClause node) =>
      new ImplementsClause(
          _mapToken(node.implementsKeyword), _cloneNodeList(node.interfaces));

  @override
  ImportDirective visitImportDirective(ImportDirective node) =>
      new ImportDirective(_cloneNode(node.documentationComment),
          _cloneNodeList(node.metadata), _mapToken(node.keyword),
          _cloneNode(node.uri), _mapToken(node.deferredKeyword),
          _mapToken(node.asKeyword), _cloneNode(node.prefix),
          _cloneNodeList(node.combinators), _mapToken(node.semicolon));

  @override
  IndexExpression visitIndexExpression(IndexExpression node) {
    Token period = _mapToken(node.period);
    IndexExpression copy;
    if (period == null) {
      copy = new IndexExpression.forTarget(_cloneNode(node.target),
          _mapToken(node.leftBracket), _cloneNode(node.index),
          _mapToken(node.rightBracket));
    } else {
      copy = new IndexExpression.forCascade(period, _mapToken(node.leftBracket),
          _cloneNode(node.index), _mapToken(node.rightBracket));
    }
    copy.auxiliaryElements = node.auxiliaryElements;
    copy.propagatedElement = node.propagatedElement;
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  InstanceCreationExpression visitInstanceCreationExpression(
      InstanceCreationExpression node) {
    InstanceCreationExpression copy = new InstanceCreationExpression(
        _mapToken(node.keyword), _cloneNode(node.constructorName),
        _cloneNode(node.argumentList));
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  IntegerLiteral visitIntegerLiteral(IntegerLiteral node) {
    IntegerLiteral copy =
        new IntegerLiteral(_mapToken(node.literal), node.value);
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  InterpolationExpression visitInterpolationExpression(
      InterpolationExpression node) => new InterpolationExpression(
      _mapToken(node.leftBracket), _cloneNode(node.expression),
      _mapToken(node.rightBracket));

  @override
  InterpolationString visitInterpolationString(InterpolationString node) =>
      new InterpolationString(_mapToken(node.contents), node.value);

  @override
  IsExpression visitIsExpression(IsExpression node) {
    IsExpression copy = new IsExpression(_cloneNode(node.expression),
        _mapToken(node.isOperator), _mapToken(node.notOperator),
        _cloneNode(node.type));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  Label visitLabel(Label node) =>
      new Label(_cloneNode(node.label), _mapToken(node.colon));

  @override
  LabeledStatement visitLabeledStatement(LabeledStatement node) =>
      new LabeledStatement(
          _cloneNodeList(node.labels), _cloneNode(node.statement));

  @override
  LibraryDirective visitLibraryDirective(LibraryDirective node) =>
      new LibraryDirective(_cloneNode(node.documentationComment),
          _cloneNodeList(node.metadata), _mapToken(node.libraryKeyword),
          _cloneNode(node.name), _mapToken(node.semicolon));

  @override
  LibraryIdentifier visitLibraryIdentifier(LibraryIdentifier node) {
    LibraryIdentifier copy =
        new LibraryIdentifier(_cloneNodeList(node.components));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  ListLiteral visitListLiteral(ListLiteral node) {
    ListLiteral copy = new ListLiteral(_mapToken(node.constKeyword),
        _cloneNode(node.typeArguments), _mapToken(node.leftBracket),
        _cloneNodeList(node.elements), _mapToken(node.rightBracket));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  MapLiteral visitMapLiteral(MapLiteral node) {
    MapLiteral copy = new MapLiteral(_mapToken(node.constKeyword),
        _cloneNode(node.typeArguments), _mapToken(node.leftBracket),
        _cloneNodeList(node.entries), _mapToken(node.rightBracket));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  MapLiteralEntry visitMapLiteralEntry(
      MapLiteralEntry node) => new MapLiteralEntry(
      _cloneNode(node.key), _mapToken(node.separator), _cloneNode(node.value));

  @override
  MethodDeclaration visitMethodDeclaration(MethodDeclaration node) =>
      new MethodDeclaration(_cloneNode(node.documentationComment),
          _cloneNodeList(node.metadata), _mapToken(node.externalKeyword),
          _mapToken(node.modifierKeyword), _cloneNode(node.returnType),
          _mapToken(node.propertyKeyword), _mapToken(node.operatorKeyword),
          _cloneNode(node.name), _cloneNode(node.parameters),
          _cloneNode(node.body));

  @override
  MethodInvocation visitMethodInvocation(MethodInvocation node) {
    MethodInvocation copy = new MethodInvocation(_cloneNode(node.target),
        _mapToken(node.operator), _cloneNode(node.methodName),
        _cloneNode(node.argumentList));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  NamedExpression visitNamedExpression(NamedExpression node) {
    NamedExpression copy =
        new NamedExpression(_cloneNode(node.name), _cloneNode(node.expression));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  AstNode visitNativeClause(NativeClause node) =>
      new NativeClause(_mapToken(node.nativeKeyword), _cloneNode(node.name));

  @override
  NativeFunctionBody visitNativeFunctionBody(NativeFunctionBody node) =>
      new NativeFunctionBody(_mapToken(node.nativeKeyword),
          _cloneNode(node.stringLiteral), _mapToken(node.semicolon));

  @override
  NullLiteral visitNullLiteral(NullLiteral node) {
    NullLiteral copy = new NullLiteral(_mapToken(node.literal));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  ParenthesizedExpression visitParenthesizedExpression(
      ParenthesizedExpression node) {
    ParenthesizedExpression copy = new ParenthesizedExpression(
        _mapToken(node.leftParenthesis), _cloneNode(node.expression),
        _mapToken(node.rightParenthesis));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  PartDirective visitPartDirective(PartDirective node) {
    PartDirective copy = new PartDirective(
        _cloneNode(node.documentationComment), _cloneNodeList(node.metadata),
        _mapToken(node.partKeyword), _cloneNode(node.uri),
        _mapToken(node.semicolon));
    copy.element = node.element;
    return copy;
  }

  @override
  PartOfDirective visitPartOfDirective(PartOfDirective node) {
    PartOfDirective copy = new PartOfDirective(
        _cloneNode(node.documentationComment), _cloneNodeList(node.metadata),
        _mapToken(node.partKeyword), _mapToken(node.ofKeyword),
        _cloneNode(node.libraryName), _mapToken(node.semicolon));
    copy.element = node.element;
    return copy;
  }

  @override
  PostfixExpression visitPostfixExpression(PostfixExpression node) {
    PostfixExpression copy = new PostfixExpression(
        _cloneNode(node.operand), _mapToken(node.operator));
    copy.propagatedElement = node.propagatedElement;
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  PrefixedIdentifier visitPrefixedIdentifier(PrefixedIdentifier node) {
    PrefixedIdentifier copy = new PrefixedIdentifier(_cloneNode(node.prefix),
        _mapToken(node.period), _cloneNode(node.identifier));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  PrefixExpression visitPrefixExpression(PrefixExpression node) {
    PrefixExpression copy = new PrefixExpression(
        _mapToken(node.operator), _cloneNode(node.operand));
    copy.propagatedElement = node.propagatedElement;
    copy.propagatedType = node.propagatedType;
    copy.staticElement = node.staticElement;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  PropertyAccess visitPropertyAccess(PropertyAccess node) {
    PropertyAccess copy = new PropertyAccess(_cloneNode(node.target),
        _mapToken(node.operator), _cloneNode(node.propertyName));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  RedirectingConstructorInvocation visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    RedirectingConstructorInvocation copy =
        new RedirectingConstructorInvocation(_mapToken(node.thisKeyword),
            _mapToken(node.period), _cloneNode(node.constructorName),
            _cloneNode(node.argumentList));
    copy.staticElement = node.staticElement;
    return copy;
  }

  @override
  RethrowExpression visitRethrowExpression(RethrowExpression node) {
    RethrowExpression copy =
        new RethrowExpression(_mapToken(node.rethrowKeyword));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  ReturnStatement visitReturnStatement(ReturnStatement node) =>
      new ReturnStatement(_mapToken(node.returnKeyword),
          _cloneNode(node.expression), _mapToken(node.semicolon));

  @override
  ScriptTag visitScriptTag(ScriptTag node) =>
      new ScriptTag(_mapToken(node.scriptTag));

  @override
  ShowCombinator visitShowCombinator(ShowCombinator node) => new ShowCombinator(
      _mapToken(node.keyword), _cloneNodeList(node.shownNames));

  @override
  SimpleFormalParameter visitSimpleFormalParameter(
      SimpleFormalParameter node) => new SimpleFormalParameter(
      _cloneNode(node.documentationComment), _cloneNodeList(node.metadata),
      _mapToken(node.keyword), _cloneNode(node.type),
      _cloneNode(node.identifier));

  @override
  SimpleIdentifier visitSimpleIdentifier(SimpleIdentifier node) {
    Token mappedToken = _mapToken(node.token);
    if (mappedToken == null) {
      // This only happens for SimpleIdentifiers created by the parser as part
      // of scanning documentation comments (the tokens for those identifiers
      // are not in the original token stream and hence do not get copied).
      // This extra check can be removed if the scanner is changed to scan
      // documentation comments for the parser.
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

  @override
  SimpleStringLiteral visitSimpleStringLiteral(SimpleStringLiteral node) {
    SimpleStringLiteral copy =
        new SimpleStringLiteral(_mapToken(node.literal), node.value);
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  StringInterpolation visitStringInterpolation(StringInterpolation node) {
    StringInterpolation copy =
        new StringInterpolation(_cloneNodeList(node.elements));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  SuperConstructorInvocation visitSuperConstructorInvocation(
      SuperConstructorInvocation node) {
    SuperConstructorInvocation copy = new SuperConstructorInvocation(
        _mapToken(node.superKeyword), _mapToken(node.period),
        _cloneNode(node.constructorName), _cloneNode(node.argumentList));
    copy.staticElement = node.staticElement;
    return copy;
  }

  @override
  SuperExpression visitSuperExpression(SuperExpression node) {
    SuperExpression copy = new SuperExpression(_mapToken(node.superKeyword));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  SwitchCase visitSwitchCase(SwitchCase node) => new SwitchCase(
      _cloneNodeList(node.labels), _mapToken(node.keyword),
      _cloneNode(node.expression), _mapToken(node.colon),
      _cloneNodeList(node.statements));

  @override
  SwitchDefault visitSwitchDefault(SwitchDefault node) => new SwitchDefault(
      _cloneNodeList(node.labels), _mapToken(node.keyword),
      _mapToken(node.colon), _cloneNodeList(node.statements));

  @override
  SwitchStatement visitSwitchStatement(SwitchStatement node) =>
      new SwitchStatement(_mapToken(node.switchKeyword),
          _mapToken(node.leftParenthesis), _cloneNode(node.expression),
          _mapToken(node.rightParenthesis), _mapToken(node.leftBracket),
          _cloneNodeList(node.members), _mapToken(node.rightBracket));

  @override
  AstNode visitSymbolLiteral(SymbolLiteral node) {
    SymbolLiteral copy = new SymbolLiteral(
        _mapToken(node.poundSign), _mapTokens(node.components));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  ThisExpression visitThisExpression(ThisExpression node) {
    ThisExpression copy = new ThisExpression(_mapToken(node.thisKeyword));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  ThrowExpression visitThrowExpression(ThrowExpression node) {
    ThrowExpression copy = new ThrowExpression(
        _mapToken(node.throwKeyword), _cloneNode(node.expression));
    copy.propagatedType = node.propagatedType;
    copy.staticType = node.staticType;
    return copy;
  }

  @override
  TopLevelVariableDeclaration visitTopLevelVariableDeclaration(
      TopLevelVariableDeclaration node) => new TopLevelVariableDeclaration(
      _cloneNode(node.documentationComment), _cloneNodeList(node.metadata),
      _cloneNode(node.variables), _mapToken(node.semicolon));

  @override
  TryStatement visitTryStatement(TryStatement node) => new TryStatement(
      _mapToken(node.tryKeyword), _cloneNode(node.body),
      _cloneNodeList(node.catchClauses), _mapToken(node.finallyKeyword),
      _cloneNode(node.finallyBlock));

  @override
  TypeArgumentList visitTypeArgumentList(TypeArgumentList node) =>
      new TypeArgumentList(_mapToken(node.leftBracket),
          _cloneNodeList(node.arguments), _mapToken(node.rightBracket));

  @override
  TypeName visitTypeName(TypeName node) {
    TypeName copy =
        new TypeName(_cloneNode(node.name), _cloneNode(node.typeArguments));
    copy.type = node.type;
    return copy;
  }

  @override
  TypeParameter visitTypeParameter(TypeParameter node) => new TypeParameter(
      _cloneNode(node.documentationComment), _cloneNodeList(node.metadata),
      _cloneNode(node.name), _mapToken(node.extendsKeyword),
      _cloneNode(node.bound));

  @override
  TypeParameterList visitTypeParameterList(TypeParameterList node) =>
      new TypeParameterList(_mapToken(node.leftBracket),
          _cloneNodeList(node.typeParameters), _mapToken(node.rightBracket));

  @override
  VariableDeclaration visitVariableDeclaration(VariableDeclaration node) =>
      new VariableDeclaration(_cloneNode(node.name), _mapToken(node.equals),
          _cloneNode(node.initializer));

  @override
  VariableDeclarationList visitVariableDeclarationList(
      VariableDeclarationList node) => new VariableDeclarationList(null,
      _cloneNodeList(node.metadata), _mapToken(node.keyword),
      _cloneNode(node.type), _cloneNodeList(node.variables));

  @override
  VariableDeclarationStatement visitVariableDeclarationStatement(
      VariableDeclarationStatement node) => new VariableDeclarationStatement(
      _cloneNode(node.variables), _mapToken(node.semicolon));

  @override
  WhileStatement visitWhileStatement(WhileStatement node) => new WhileStatement(
      _mapToken(node.whileKeyword), _mapToken(node.leftParenthesis),
      _cloneNode(node.condition), _mapToken(node.rightParenthesis),
      _cloneNode(node.body));

  @override
  WithClause visitWithClause(WithClause node) => new WithClause(
      _mapToken(node.withKeyword), _cloneNodeList(node.mixinTypes));

  @override
  YieldStatement visitYieldStatement(YieldStatement node) => new YieldStatement(
      _mapToken(node.yieldKeyword), _mapToken(node.star),
      _cloneNode(node.expression), _mapToken(node.semicolon));

  AstNode _cloneNode(AstNode node) {
    if (node == null) {
      return null;
    }
    if (identical(node, _oldNode)) {
      return _newNode;
    }
    return node.accept(this) as AstNode;
  }

  List _cloneNodeList(NodeList nodes) {
    List clonedNodes = new List();
    for (AstNode node in nodes) {
      clonedNodes.add(_cloneNode(node));
    }
    return clonedNodes;
  }

  Token _mapToken(Token oldToken) {
    if (oldToken == null) {
      return null;
    }
    return _tokenMap.get(oldToken);
  }

  List<Token> _mapTokens(List<Token> oldTokens) {
    List<Token> newTokens = new List<Token>(oldTokens.length);
    for (int index = 0; index < newTokens.length; index++) {
      newTokens[index] = _mapToken(oldTokens[index]);
    }
    return newTokens;
  }
}

/**
 * An index expression.
 *
 * > indexExpression ::=
 * >     [Expression] '[' [Expression] ']'
 */
class IndexExpression extends Expression {
  /**
   * The expression used to compute the object being indexed, or `null` if this
   * index expression is part of a cascade expression.
   */
  Expression _target;

  /**
   * The period ("..") before a cascaded index expression, or `null` if this
   * index expression is not part of a cascade expression.
   */
  Token period;

  /**
   * The left square bracket.
   */
  Token leftBracket;

  /**
   * The expression used to compute the index.
   */
  Expression _index;

  /**
   * The right square bracket.
   */
  Token rightBracket;

  /**
   * The element associated with the operator based on the static type of the
   * target, or `null` if the AST structure has not been resolved or if the
   * operator could not be resolved.
   */
  MethodElement staticElement;

  /**
   * The element associated with the operator based on the propagated type of
   * the target, or `null` if the AST structure has not been resolved or if the
   * operator could not be resolved.
   */
  MethodElement propagatedElement;

  /**
   * If this expression is both in a getter and setter context, the
   * [AuxiliaryElements] will be set to hold onto the static and propagated
   * information. The auxiliary element will hold onto the elements from the
   * getter context.
   */
  AuxiliaryElements auxiliaryElements = null;

  /**
   * Initialize a newly created index expression.
   */
  IndexExpression.forCascade(
      this.period, this.leftBracket, Expression index, this.rightBracket) {
    _index = _becomeParentOf(index);
  }

  /**
   * Initialize a newly created index expression.
   */
  IndexExpression.forTarget(Expression target, this.leftBracket,
      Expression index, this.rightBracket) {
    _target = _becomeParentOf(target);
    _index = _becomeParentOf(index);
  }

  @override
  Token get beginToken {
    if (_target != null) {
      return _target.beginToken;
    }
    return period;
  }

  /**
   * Return the best element available for this operator. If resolution was able
   * to find a better element based on type propagation, that element will be
   * returned. Otherwise, the element found using the result of static analysis
   * will be returned. If resolution has not been performed, then `null` will be
   * returned.
   */
  MethodElement get bestElement {
    MethodElement element = propagatedElement;
    if (element == null) {
      element = staticElement;
    }
    return element;
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(_target)
    ..add(period)
    ..add(leftBracket)
    ..add(_index)
    ..add(rightBracket);

  @override
  Token get endToken => rightBracket;

  /**
   * Return the expression used to compute the index.
   */
  Expression get index => _index;

  /**
   * Set the expression used to compute the index to the given [expression].
   */
  void set index(Expression expression) {
    _index = _becomeParentOf(expression);
  }

  @override
  bool get isAssignable => true;

  /**
   * Return `true` if this expression is cascaded. If it is, then the target of
   * this expression is not stored locally but is stored in the nearest ancestor
   * that is a [CascadeExpression].
   */
  bool get isCascaded => period != null;

  @override
  int get precedence => 15;

  /**
   * If the AST structure has been resolved, and the function being invoked is
   * known based on propagated type information, then return the parameter
   * element representing the parameter to which the value of the index
   * expression will be bound. Otherwise, return `null`.
   */
  @deprecated // Use "expression.propagatedParameterElement"
  ParameterElement get propagatedParameterElementForIndex {
    return _propagatedParameterElementForIndex;
  }

  /**
   * Return the expression used to compute the object being indexed. If this
   * index expression is not part of a cascade expression, then this is the same
   * as [target]. If this index expression is part of a cascade expression, then
   * the target expression stored with the cascade expression is returned.
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
   * If the AST structure has been resolved, and the function being invoked is
   * known based on static type information, then return the parameter element
   * representing the parameter to which the value of the index expression will
   * be bound. Otherwise, return `null`.
   */
  @deprecated // Use "expression.propagatedParameterElement"
  ParameterElement get staticParameterElementForIndex {
    return _staticParameterElementForIndex;
  }

  /**
   * Return the expression used to compute the object being indexed, or `null`
   * if this index expression is part of a cascade expression.
   *
   * Use [realTarget] to get the target independent of whether this is part of a
   * cascade expression.
   */
  Expression get target => _target;

  /**
   * Set the expression used to compute the object being indexed to the given
   * [expression].
   */
  void set target(Expression expression) {
    _target = _becomeParentOf(expression);
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is
   * known based on propagated type information, then return the parameter
   * element representing the parameter to which the value of the index
   * expression will be bound. Otherwise, return `null`.
   */
  ParameterElement get _propagatedParameterElementForIndex {
    if (propagatedElement == null) {
      return null;
    }
    List<ParameterElement> parameters = propagatedElement.parameters;
    if (parameters.length < 1) {
      return null;
    }
    return parameters[0];
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is
   * known based on static type information, then return the parameter element
   * representing the parameter to which the value of the index expression will
   * be bound. Otherwise, return `null`.
   */
  ParameterElement get _staticParameterElementForIndex {
    if (staticElement == null) {
      return null;
    }
    List<ParameterElement> parameters = staticElement.parameters;
    if (parameters.length < 1) {
      return null;
    }
    return parameters[0];
  }

  @override
  accept(AstVisitor visitor) => visitor.visitIndexExpression(this);

  /**
   * Return `true` if this expression is computing a right-hand value (that is,
   * if this expression is in a context where the operator '[]' will be
   * invoked).
   *
   * Note that [inGetterContext] and [inSetterContext] are not opposites, nor
   * are they mutually exclusive. In other words, it is possible for both
   * methods to return `true` when invoked on the same node.
   */
  bool inGetterContext() {
    // TODO(brianwilkerson) Convert this to a getter.
    AstNode parent = this.parent;
    if (parent is AssignmentExpression) {
      AssignmentExpression assignment = parent;
      if (identical(assignment.leftHandSide, this) &&
          assignment.operator.type == TokenType.EQ) {
        return false;
      }
    }
    return true;
  }

  /**
   * Return `true` if this expression is computing a left-hand value (that is,
   * if this expression is in a context where the operator '[]=' will be
   * invoked).
   *
   * Note that [inGetterContext] and [inSetterContext] are not opposites, nor
   * are they mutually exclusive. In other words, it is possible for both
   * methods to return `true` when invoked on the same node.
   */
  bool inSetterContext() {
    // TODO(brianwilkerson) Convert this to a getter.
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

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_target, visitor);
    _safelyVisitChild(_index, visitor);
  }
}

/**
 * An instance creation expression.
 *
 * > newExpression ::=
 * >     ('new' | 'const') [TypeName] ('.' [SimpleIdentifier])? [ArgumentList]
 */
class InstanceCreationExpression extends Expression {
  /**
   * The 'new' or 'const' keyword used to indicate how an object should be
   * created.
   */
  Token keyword;

  /**
   * The name of the constructor to be invoked.
   */
  ConstructorName _constructorName;

  /**
   * The list of arguments to the constructor.
   */
  ArgumentList _argumentList;

  /**
   * The element associated with the constructor based on static type
   * information, or `null` if the AST structure has not been resolved or if the
   * constructor could not be resolved.
   */
  ConstructorElement staticElement;

  /**
   * The [ConstantInstanceCreationHandle] holding the result of evaluating this
   * expression, if it is constant.
   */
  ConstantInstanceCreationHandle constantHandle;

  /**
   * Initialize a newly created instance creation expression.
   */
  InstanceCreationExpression(this.keyword, ConstructorName constructorName,
      ArgumentList argumentList) {
    _constructorName = _becomeParentOf(constructorName);
    _argumentList = _becomeParentOf(argumentList);
  }

  /**
   * Return the list of arguments to the constructor.
   */
  ArgumentList get argumentList => _argumentList;

  /**
   * Set the list of arguments to the constructor to the given [argumentList].
   */
  void set argumentList(ArgumentList argumentList) {
    _argumentList = _becomeParentOf(argumentList);
  }

  @override
  Token get beginToken => keyword;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(keyword)
    ..add(_constructorName)
    ..add(_argumentList);

  /**
   * Return the name of the constructor to be invoked.
   */
  ConstructorName get constructorName => _constructorName;

  /**
   * Set the name of the constructor to be invoked to the given [name].
   */
  void set constructorName(ConstructorName name) {
    _constructorName = _becomeParentOf(name);
  }

  @override
  Token get endToken => _argumentList.endToken;

  /**
   * The result of evaluating this expression, if it is constant.
   */
  EvaluationResultImpl get evaluationResult {
    if (constantHandle != null) {
      return constantHandle.evaluationResult;
    }
    return null;
  }

  /**
   * Return `true` if this creation expression is used to invoke a constant
   * constructor.
   */
  bool get isConst => keyword is KeywordToken &&
      (keyword as KeywordToken).keyword == Keyword.CONST;

  @override
  int get precedence => 16;

  @override
  accept(AstVisitor visitor) => visitor.visitInstanceCreationExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_constructorName, visitor);
    _safelyVisitChild(_argumentList, visitor);
  }
}

/**
 * An integer literal expression.
 *
 * > integerLiteral ::=
 * >     decimalIntegerLiteral
 * >   | hexidecimalIntegerLiteral
 * >
 * > decimalIntegerLiteral ::=
 * >     decimalDigit+
 * >
 * > hexidecimalIntegerLiteral ::=
 * >     '0x' hexidecimalDigit+
 * >   | '0X' hexidecimalDigit+
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
   */
  IntegerLiteral(this.literal, this.value);

  @override
  Token get beginToken => literal;

  @override
  Iterable get childEntities => new ChildEntities()..add(literal);

  @override
  Token get endToken => literal;

  @override
  accept(AstVisitor visitor) => visitor.visitIntegerLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/**
 * A node within a [StringInterpolation].
 *
 * > interpolationElement ::=
 * >     [InterpolationExpression]
 * >   | [InterpolationString]
 */
abstract class InterpolationElement extends AstNode {}

/**
 * An expression embedded in a string interpolation.
 *
 * > interpolationExpression ::=
 * >     '$' [SimpleIdentifier]
 * >   | '$' '{' [Expression] '}'
 */
class InterpolationExpression extends InterpolationElement {
  /**
   * The token used to introduce the interpolation expression; either '$' if the
   * expression is a simple identifier or '${' if the expression is a full
   * expression.
   */
  Token leftBracket;

  /**
   * The expression to be evaluated for the value to be converted into a string.
   */
  Expression _expression;

  /**
   * The right curly bracket, or `null` if the expression is an identifier
   * without brackets.
   */
  Token rightBracket;

  /**
   * Initialize a newly created interpolation expression.
   */
  InterpolationExpression(
      this.leftBracket, Expression expression, this.rightBracket) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Token get beginToken => leftBracket;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(leftBracket)
    ..add(_expression)
    ..add(rightBracket);

  @override
  Token get endToken {
    if (rightBracket != null) {
      return rightBracket;
    }
    return _expression.endToken;
  }

  /**
   * Return the expression to be evaluated for the value to be converted into a
   * string.
   */
  Expression get expression => _expression;

  /**
   * Set the expression to be evaluated for the value to be converted into a
   * string to the given [expression].
   */
  void set expression(Expression expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitInterpolationExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_expression, visitor);
  }
}

/**
 * A non-empty substring of an interpolated string.
 *
 * > interpolationString ::=
 * >     characters
 */
class InterpolationString extends InterpolationElement {
  /**
   * The characters that will be added to the string.
   */
  Token contents;

  /**
   * The value of the literal.
   */
  String _value;

  /**
   * Initialize a newly created string of characters that are part of a string
   * interpolation.
   */
  InterpolationString(this.contents, String value) {
    _value = value;
  }

  @override
  Token get beginToken => contents;

  @override
  Iterable get childEntities => new ChildEntities()..add(contents);

  /**
   * Return the offset of the after-last contents character.
   */
  int get contentsEnd {
    String lexeme = contents.lexeme;
    return offset + new StringLexemeHelper(lexeme, true, true).end;
  }

  /**
   * Return the offset of the first contents character.
   */
  int get contentsOffset {
    int offset = contents.offset;
    String lexeme = contents.lexeme;
    return offset + new StringLexemeHelper(lexeme, true, true).start;
  }

  @override
  Token get endToken => contents;

  /**
   * Return the value of the literal.
   */
  String get value => _value;

  /**
   * Set the value of the literal to the given [string].
   */
  void set value(String string) {
    _value = string;
  }

  @override
  accept(AstVisitor visitor) => visitor.visitInterpolationString(this);

  @override
  void visitChildren(AstVisitor visitor) {}
}

/**
 * An is expression.
 *
 * > isExpression ::=
 * >     [Expression] 'is' '!'? [TypeName]
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
   * Initialize a newly created is expression. The [notOperator] can be `null`
   * if the sense of the test is not negated.
   */
  IsExpression(
      Expression expression, this.isOperator, this.notOperator, TypeName type) {
    _expression = _becomeParentOf(expression);
    _type = _becomeParentOf(type);
  }

  @override
  Token get beginToken => _expression.beginToken;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(_expression)
    ..add(isOperator)
    ..add(notOperator)
    ..add(_type);

  @override
  Token get endToken => _type.endToken;

  /**
   * Return the expression used to compute the value whose type is being tested.
   */
  Expression get expression => _expression;

  /**
   * Set the expression used to compute the value whose type is being tested to
   * the given [expression].
   */
  void set expression(Expression expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  int get precedence => 7;

  /**
   * Return the name of the type being tested for.
   */
  TypeName get type => _type;

  /**
   * Set the name of the type being tested for to the given [name].
   */
  void set type(TypeName name) {
    _type = _becomeParentOf(name);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitIsExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_expression, visitor);
    _safelyVisitChild(_type, visitor);
  }
}

/**
 * A label on either a [LabeledStatement] or a [NamedExpression].
 *
 * > label ::=
 * >     [SimpleIdentifier] ':'
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
   */
  Label(SimpleIdentifier label, this.colon) {
    _label = _becomeParentOf(label);
  }

  @override
  Token get beginToken => _label.beginToken;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(_label)
    ..add(colon);

  @override
  Token get endToken => colon;

  /**
   * Return the label being associated with the statement.
   */
  SimpleIdentifier get label => _label;

  /**
   * Set the label being associated with the statement to the given [label].
   */
  void set label(SimpleIdentifier label) {
    _label = _becomeParentOf(label);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitLabel(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_label, visitor);
  }
}

/**
 * A statement that has a label associated with them.
 *
 * > labeledStatement ::=
 * >    [Label]+ [Statement]
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
   */
  LabeledStatement(List<Label> labels, Statement statement) {
    _labels = new NodeList<Label>(this, labels);
    _statement = _becomeParentOf(statement);
  }

  @override
  Token get beginToken {
    if (!_labels.isEmpty) {
      return _labels.beginToken;
    }
    return _statement.beginToken;
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..addAll(_labels)
    ..add(_statement);

  @override
  Token get endToken => _statement.endToken;

  /**
   * Return the labels being associated with the statement.
   */
  NodeList<Label> get labels => _labels;

  /**
   * Return the statement with which the labels are being associated.
   */
  Statement get statement => _statement;

  /**
   * Set the statement with which the labels are being associated to the given
   * [statement].
   */
  void set statement(Statement statement) {
    _statement = _becomeParentOf(statement);
  }

  @override
  Statement get unlabeled => _statement.unlabeled;

  @override
  accept(AstVisitor visitor) => visitor.visitLabeledStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _labels.accept(visitor);
    _safelyVisitChild(_statement, visitor);
  }
}

/**
 * A library directive.
 *
 * > libraryDirective ::=
 * >     [Annotation] 'library' [Identifier] ';'
 */
class LibraryDirective extends Directive {
  /**
   * The token representing the 'library' keyword.
   */
  Token libraryKeyword;

  /**
   * The name of the library being defined.
   */
  LibraryIdentifier _name;

  /**
   * The semicolon terminating the directive.
   */
  Token semicolon;

  /**
   * Initialize a newly created library directive. Either or both of the
   * [comment] and [metadata] can be `null` if the directive does not have the
   * corresponding attribute.
   */
  LibraryDirective(Comment comment, List<Annotation> metadata,
      this.libraryKeyword, LibraryIdentifier name, this.semicolon)
      : super(comment, metadata) {
    _name = _becomeParentOf(name);
  }

  @override
  Iterable get childEntities => super._childEntities
    ..add(libraryKeyword)
    ..add(_name)
    ..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => libraryKeyword;

  @override
  Token get keyword => libraryKeyword;

  /**
   * Return the token representing the 'library' token.
   */
  @deprecated // Use "this.libraryKeyword"
  Token get libraryToken => libraryKeyword;

  /**
   * Set the token representing the 'library' token to the given [token].
   */
  @deprecated // Use "this.libraryKeyword"
  set libraryToken(Token token) {
    libraryKeyword = token;
  }

  /**
   * Return the name of the library being defined.
   */
  LibraryIdentifier get name => _name;

  /**
   * Set the name of the library being defined to the given [name].
   */
  void set name(LibraryIdentifier name) {
    _name = _becomeParentOf(name);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitLibraryDirective(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_name, visitor);
  }
}

/**
 * The identifier for a library.
 *
 * > libraryIdentifier ::=
 * >     [SimpleIdentifier] ('.' [SimpleIdentifier])*
 */
class LibraryIdentifier extends Identifier {
  /**
   * The components of the identifier.
   */
  NodeList<SimpleIdentifier> _components;

  /**
   * Initialize a newly created prefixed identifier.
   */
  LibraryIdentifier(List<SimpleIdentifier> components) {
    _components = new NodeList<SimpleIdentifier>(this, components);
  }

  @override
  Token get beginToken => _components.beginToken;

  @override
  Element get bestElement => staticElement;

  /**
   * TODO(paulberry): add "." tokens.
   */
  @override
  Iterable get childEntities => new ChildEntities()..addAll(_components);

  /**
   * Return the components of the identifier.
   */
  NodeList<SimpleIdentifier> get components => _components;

  @override
  Token get endToken => _components.endToken;

  @override
  String get name {
    StringBuffer buffer = new StringBuffer();
    bool needsPeriod = false;
    for (SimpleIdentifier identifier in _components) {
      if (needsPeriod) {
        buffer.write(".");
      } else {
        needsPeriod = true;
      }
      buffer.write(identifier.name);
    }
    return buffer.toString();
  }

  @override
  int get precedence => 15;

  @override
  Element get propagatedElement => null;

  @override
  Element get staticElement => null;

  @override
  accept(AstVisitor visitor) => visitor.visitLibraryIdentifier(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _components.accept(visitor);
  }
}

/**
 * A list literal.
 *
 * > listLiteral ::=
 * >     'const'? ('<' [TypeName] '>')? '[' ([Expression] ','?)? ']'
 */
class ListLiteral extends TypedLiteral {
  /**
   * The left square bracket.
   */
  Token leftBracket;

  /**
   * The expressions used to compute the elements of the list.
   */
  NodeList<Expression> _elements;

  /**
   * The right square bracket.
   */
  Token rightBracket;

  /**
   * Initialize a newly created list literal. The [constKeyword] can be `null`
   * if the literal is not a constant. The [typeArguments] can be `null` if no
   * type arguments were declared. The list of [elements] can be `null` if the
   * list is empty.
   */
  ListLiteral(Token constKeyword, TypeArgumentList typeArguments,
      this.leftBracket, List<Expression> elements, this.rightBracket)
      : super(constKeyword, typeArguments) {
    _elements = new NodeList<Expression>(this, elements);
  }

  @override
  Token get beginToken {
    if (constKeyword != null) {
      return constKeyword;
    }
    TypeArgumentList typeArguments = this.typeArguments;
    if (typeArguments != null) {
      return typeArguments.beginToken;
    }
    return leftBracket;
  }

  /**
   * TODO(paulberry): add commas.
   */
  @override
  Iterable get childEntities => super._childEntities
    ..add(leftBracket)
    ..addAll(_elements)
    ..add(rightBracket);

  /**
   * Return the expressions used to compute the elements of the list.
   */
  NodeList<Expression> get elements => _elements;

  @override
  Token get endToken => rightBracket;

  @override
  accept(AstVisitor visitor) => visitor.visitListLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _elements.accept(visitor);
  }
}

/**
 * A node that represents a literal expression.
 *
 * > literal ::=
 * >     [BooleanLiteral]
 * >   | [DoubleLiteral]
 * >   | [IntegerLiteral]
 * >   | [ListLiteral]
 * >   | [MapLiteral]
 * >   | [NullLiteral]
 * >   | [StringLiteral]
 */
abstract class Literal extends Expression {
  @override
  int get precedence => 16;
}

/**
 * A literal map.
 *
 * > mapLiteral ::=
 * >     'const'? ('<' [TypeName] (',' [TypeName])* '>')?
 * >     '{' ([MapLiteralEntry] (',' [MapLiteralEntry])* ','?)? '}'
 */
class MapLiteral extends TypedLiteral {
  /**
   * The left curly bracket.
   */
  Token leftBracket;

  /**
   * The entries in the map.
   */
  NodeList<MapLiteralEntry> _entries;

  /**
   * The right curly bracket.
   */
  Token rightBracket;

  /**
   * Initialize a newly created map literal. The [constKeyword] can be `null` if
   * the literal is not a constant. The [typeArguments] can be `null` if no type
   * arguments were declared. The [entries] can be `null` if the map is empty.
   */
  MapLiteral(Token constKeyword, TypeArgumentList typeArguments,
      this.leftBracket, List<MapLiteralEntry> entries, this.rightBracket)
      : super(constKeyword, typeArguments) {
    _entries = new NodeList<MapLiteralEntry>(this, entries);
  }

  @override
  Token get beginToken {
    if (constKeyword != null) {
      return constKeyword;
    }
    TypeArgumentList typeArguments = this.typeArguments;
    if (typeArguments != null) {
      return typeArguments.beginToken;
    }
    return leftBracket;
  }

  /**
   * TODO(paulberry): add commas.
   */
  @override
  Iterable get childEntities => super._childEntities
    ..add(leftBracket)
    ..addAll(entries)
    ..add(rightBracket);

  @override
  Token get endToken => rightBracket;

  /**
   * Return the entries in the map.
   */
  NodeList<MapLiteralEntry> get entries => _entries;

  @override
  accept(AstVisitor visitor) => visitor.visitMapLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _entries.accept(visitor);
  }
}

/**
 * A single key/value pair in a map literal.
 *
 * > mapLiteralEntry ::=
 * >     [Expression] ':' [Expression]
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
   */
  MapLiteralEntry(Expression key, this.separator, Expression value) {
    _key = _becomeParentOf(key);
    _value = _becomeParentOf(value);
  }

  @override
  Token get beginToken => _key.beginToken;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(_key)
    ..add(separator)
    ..add(_value);

  @override
  Token get endToken => _value.endToken;

  /**
   * Return the expression computing the key with which the value will be
   * associated.
   */
  Expression get key => _key;

  /**
   * Set the expression computing the key with which the value will be
   * associated to the given [string].
   */
  void set key(Expression string) {
    _key = _becomeParentOf(string);
  }

  /**
   * Return the expression computing the value that will be associated with the
   * key.
   */
  Expression get value => _value;

  /**
   * Set the expression computing the value that will be associated with the key
   * to the given [expression].
   */
  void set value(Expression expression) {
    _value = _becomeParentOf(expression);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitMapLiteralEntry(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_key, visitor);
    _safelyVisitChild(_value, visitor);
  }
}

/**
 * A method declaration.
 *
 * > methodDeclaration ::=
 * >     methodSignature [FunctionBody]
 * >
 * > methodSignature ::=
 * >     'external'? ('abstract' | 'static')? [Type]? ('get' | 'set')?
 * >     methodName [FormalParameterList]
 * >
 * > methodName ::=
 * >     [SimpleIdentifier]
 * >   | 'operator' [SimpleIdentifier]
 */
class MethodDeclaration extends ClassMember {
  /**
   * The token for the 'external' keyword, or `null` if the constructor is not
   * external.
   */
  Token externalKeyword;

  /**
   * The token representing the 'abstract' or 'static' keyword, or `null` if
   * neither modifier was specified.
   */
  Token modifierKeyword;

  /**
   * The return type of the method, or `null` if no return type was declared.
   */
  TypeName _returnType;

  /**
   * The token representing the 'get' or 'set' keyword, or `null` if this is a
   * method declaration rather than a property declaration.
   */
  Token propertyKeyword;

  /**
   * The token representing the 'operator' keyword, or `null` if this method
   * does not declare an operator.
   */
  Token operatorKeyword;

  /**
   * The name of the method.
   */
  SimpleIdentifier _name;

  /**
   * The parameters associated with the method, or `null` if this method
   * declares a getter.
   */
  FormalParameterList _parameters;

  /**
   * The body of the method.
   */
  FunctionBody _body;

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
  MethodDeclaration(Comment comment, List<Annotation> metadata,
      this.externalKeyword, this.modifierKeyword, TypeName returnType,
      this.propertyKeyword, this.operatorKeyword, SimpleIdentifier name,
      FormalParameterList parameters, FunctionBody body)
      : super(comment, metadata) {
    _returnType = _becomeParentOf(returnType);
    _name = _becomeParentOf(name);
    _parameters = _becomeParentOf(parameters);
    _body = _becomeParentOf(body);
  }

  /**
   * Return the body of the method.
   */
  FunctionBody get body => _body;

  /**
   * Set the body of the method to the given [functionBody].
   */
  void set body(FunctionBody functionBody) {
    _body = _becomeParentOf(functionBody);
  }

  @override
  Iterable get childEntities => super._childEntities
    ..add(externalKeyword)
    ..add(modifierKeyword)
    ..add(_returnType)
    ..add(propertyKeyword)
    ..add(operatorKeyword)
    ..add(_name)
    ..add(_parameters)
    ..add(_body);

  /**
   * Return the element associated with this method, or `null` if the AST
   * structure has not been resolved. The element can either be a
   * [MethodElement], if this represents the declaration of a normal method, or
   * a [PropertyAccessorElement] if this represents the declaration of either a
   * getter or a setter.
   */
  @override
  ExecutableElement get element =>
      _name != null ? (_name.staticElement as ExecutableElement) : null;

  @override
  Token get endToken => _body.endToken;

  @override
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

  /**
   * Return `true` if this method is declared to be an abstract method.
   */
  bool get isAbstract {
    FunctionBody body = _body;
    return externalKeyword == null &&
        (body is EmptyFunctionBody && !body.semicolon.isSynthetic);
  }

  /**
   * Return `true` if this method declares a getter.
   */
  bool get isGetter => propertyKeyword != null &&
      (propertyKeyword as KeywordToken).keyword == Keyword.GET;

  /**
   * Return `true` if this method declares an operator.
   */
  bool get isOperator => operatorKeyword != null;

  /**
   * Return `true` if this method declares a setter.
   */
  bool get isSetter => propertyKeyword != null &&
      (propertyKeyword as KeywordToken).keyword == Keyword.SET;

  /**
   * Return `true` if this method is declared to be a static method.
   */
  bool get isStatic => modifierKeyword != null &&
      (modifierKeyword as KeywordToken).keyword == Keyword.STATIC;

  /**
   * Return the name of the method.
   */
  SimpleIdentifier get name => _name;

  /**
   * Set the name of the method to the given [identifier].
   */
  void set name(SimpleIdentifier identifier) {
    _name = _becomeParentOf(identifier);
  }

  /**
   * Return the parameters associated with the method, or `null` if this method
   * declares a getter.
   */
  FormalParameterList get parameters => _parameters;

  /**
   * Set the parameters associated with the method to the given list of
   * [parameters].
   */
  void set parameters(FormalParameterList parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  /**
   * Return the return type of the method, or `null` if no return type was
   * declared.
   */
  TypeName get returnType => _returnType;

  /**
   * Set the return type of the method to the given [typeName].
   */
  void set returnType(TypeName typeName) {
    _returnType = _becomeParentOf(typeName);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitMethodDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_returnType, visitor);
    _safelyVisitChild(_name, visitor);
    _safelyVisitChild(_parameters, visitor);
    _safelyVisitChild(_body, visitor);
  }
}

/**
 * The invocation of either a function or a method. Invocations of functions
 * resulting from evaluating an expression are represented by
 * [FunctionExpressionInvocation] nodes. Invocations of getters and setters are
 * represented by either [PrefixedIdentifier] or [PropertyAccess] nodes.
 *
 * > methodInvoction ::=
 * >     ([Expression] '.')? [SimpleIdentifier] [ArgumentList]
 */
class MethodInvocation extends Expression {
  /**
   * The expression producing the object on which the method is defined, or
   * `null` if there is no target (that is, the target is implicitly `this`).
   */
  Expression _target;

  /**
   * The operator that separates the target from the method name, or `null`
   * if there is no target. In an ordinary method invocation this will be a
   * period ('.'). In a cascade section this will be the cascade operator
   * ('..').
   */
  Token operator;

  /**
   * The name of the method being invoked.
   */
  SimpleIdentifier _methodName;

  /**
   * The list of arguments to the method.
   */
  ArgumentList _argumentList;

  /**
   * Initialize a newly created method invocation. The [target] and [operator]
   * can be `null` if there is no target.
   */
  MethodInvocation(Expression target, this.operator,
      SimpleIdentifier methodName, ArgumentList argumentList) {
    _target = _becomeParentOf(target);
    _methodName = _becomeParentOf(methodName);
    _argumentList = _becomeParentOf(argumentList);
  }

  /**
   * Return the list of arguments to the method.
   */
  ArgumentList get argumentList => _argumentList;

  /**
   * Set the list of arguments to the method to the given [argumentList].
   */
  void set argumentList(ArgumentList argumentList) {
    _argumentList = _becomeParentOf(argumentList);
  }

  @override
  Token get beginToken {
    if (_target != null) {
      return _target.beginToken;
    } else if (operator != null) {
      return operator;
    }
    return _methodName.beginToken;
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(_target)
    ..add(operator)
    ..add(_methodName)
    ..add(_argumentList);

  @override
  Token get endToken => _argumentList.endToken;

  /**
   * Return `true` if this expression is cascaded. If it is, then the target of
   * this expression is not stored locally but is stored in the nearest ancestor
   * that is a [CascadeExpression].
   */
  bool get isCascaded =>
      operator != null && operator.type == TokenType.PERIOD_PERIOD;

  /**
   * Return the name of the method being invoked.
   */
  SimpleIdentifier get methodName => _methodName;

  /**
   * Set the name of the method being invoked to the given [identifier].
   */
  void set methodName(SimpleIdentifier identifier) {
    _methodName = _becomeParentOf(identifier);
  }

  /**
   * The operator that separates the target from the method name, or `null`
   * if there is no target. In an ordinary method invocation this will be a
   * period ('.'). In a cascade section this will be the cascade operator
   * ('..').
   *
   * Deprecated: use [operator] instead.
   */
  @deprecated
  Token get period => operator;

  /**
   * The operator that separates the target from the method name, or `null`
   * if there is no target. In an ordinary method invocation this will be a
   * period ('.'). In a cascade section this will be the cascade operator
   * ('..').
   *
   * Deprecated: use [operator] instead.
   */
  @deprecated
  void set period(Token value) {
    operator = value;
  }

  @override
  int get precedence => 15;

  /**
   * Return the expression used to compute the receiver of the invocation. If
   * this invocation is not part of a cascade expression, then this is the same
   * as [target]. If this invocation is part of a cascade expression, then the
   * target stored with the cascade expression is returned.
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
   * Return the expression producing the object on which the method is defined,
   * or `null` if there is no target (that is, the target is implicitly `this`)
   * or if this method invocation is part of a cascade expression.
   *
   * Use [realTarget] to get the target independent of whether this is part of a
   * cascade expression.
   */
  Expression get target => _target;

  /**
   * Set the expression producing the object on which the method is defined to
   * the given [expression].
   */
  void set target(Expression expression) {
    _target = _becomeParentOf(expression);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitMethodInvocation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_target, visitor);
    _safelyVisitChild(_methodName, visitor);
    _safelyVisitChild(_argumentList, visitor);
  }
}

/**
 * A node that declares a single name within the scope of a compilation unit.
 */
abstract class NamedCompilationUnitMember extends CompilationUnitMember {
  /**
   * The name of the member being declared.
   */
  SimpleIdentifier _name;

  /**
   * Initialize a newly created compilation unit member with the given [name].
   * Either or both of the [comment] and [metadata] can be `null` if the member
   * does not have the corresponding attribute.
   */
  NamedCompilationUnitMember(
      Comment comment, List<Annotation> metadata, SimpleIdentifier name)
      : super(comment, metadata) {
    _name = _becomeParentOf(name);
  }

  /**
   * Return the name of the member being declared.
   */
  SimpleIdentifier get name => _name;

  /**
   * Set the name of the member being declared to the given [identifier].
   */
  void set name(SimpleIdentifier identifier) {
    _name = _becomeParentOf(identifier);
  }
}

/**
 * An expression that has a name associated with it. They are used in method
 * invocations when there are named parameters.
 *
 * > namedExpression ::=
 * >     [Label] [Expression]
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
   * Initialize a newly created named expression..
   */
  NamedExpression(Label name, Expression expression) {
    _name = _becomeParentOf(name);
    _expression = _becomeParentOf(expression);
  }

  @override
  Token get beginToken => _name.beginToken;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(_name)
    ..add(_expression);

  /**
   * Return the element representing the parameter being named by this
   * expression, or `null` if the AST structure has not been resolved or if
   * there is no parameter with the same name as this expression.
   */
  ParameterElement get element {
    Element element = _name.label.staticElement;
    if (element is ParameterElement) {
      return element;
    }
    return null;
  }

  @override
  Token get endToken => _expression.endToken;

  /**
   * Return the expression with which the name is associated.
   */
  Expression get expression => _expression;

  /**
   * Set the expression with which the name is associated to the given
   * [expression].
   */
  void set expression(Expression expression) {
    _expression = _becomeParentOf(expression);
  }

  /**
   * Return the name associated with the expression.
   */
  Label get name => _name;

  /**
   * Set the name associated with the expression to the given [identifier].
   */
  void set name(Label identifier) {
    _name = _becomeParentOf(identifier);
  }

  @override
  int get precedence => 0;

  @override
  accept(AstVisitor visitor) => visitor.visitNamedExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_name, visitor);
    _safelyVisitChild(_expression, visitor);
  }
}

/**
 * A node that represents a directive that impacts the namespace of a library.
 *
 * > directive ::=
 * >     [ExportDirective]
 * >   | [ImportDirective]
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
   * Initialize a newly created namespace directive. Either or both of the
   * [comment] and [metadata] can be `null` if the directive does not have the
   * corresponding attribute. The list of [combinators] can be `null` if there
   * are no combinators.
   */
  NamespaceDirective(Comment comment, List<Annotation> metadata, this.keyword,
      StringLiteral libraryUri, List<Combinator> combinators, this.semicolon)
      : super(comment, metadata, libraryUri) {
    _combinators = new NodeList<Combinator>(this, combinators);
  }

  /**
   * Return the combinators used to control how names are imported or exported.
   */
  NodeList<Combinator> get combinators => _combinators;

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => keyword;

  @override
  LibraryElement get uriElement;
}

/**
 * The "native" clause in an class declaration.
 *
 * > nativeClause ::=
 * >     'native' [StringLiteral]
 */
class NativeClause extends AstNode {
  /**
   * The token representing the 'native' keyword.
   */
  Token nativeKeyword;

  /**
   * The name of the native object that implements the class.
   */
  StringLiteral _name;

  /**
   * Initialize a newly created native clause.
   */
  NativeClause(this.nativeKeyword, StringLiteral name) {
    _name = _becomeParentOf(name);
  }

  @override
  Token get beginToken => nativeKeyword;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(nativeKeyword)
    ..add(_name);

  @override
  Token get endToken => _name.endToken;

  /**
   * Get the token representing the 'native' keyword.
   */
  @deprecated // Use "this.nativeKeyword"
  Token get keyword => nativeKeyword;

  /**
   * Set the token representing the 'native' keyword to the given [token].
   */
  @deprecated // Use "this.nativeKeyword"
  set keyword(Token token) {
    nativeKeyword = token;
  }

  /**
   * Return the name of the native object that implements the class.
   */
  StringLiteral get name => _name;

  /**
   * Sets the name of the native object that implements the class to the given
   * [name].
   */
  void set name(StringLiteral name) {
    _name = _becomeParentOf(name);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitNativeClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_name, visitor);
  }
}

/**
 * A function body that consists of a native keyword followed by a string
 * literal.
 *
 * > nativeFunctionBody ::=
 * >     'native' [SimpleStringLiteral] ';'
 */
class NativeFunctionBody extends FunctionBody {
  /**
   * The token representing 'native' that marks the start of the function body.
   */
  Token nativeKeyword;

  /**
   * The string literal, after the 'native' token.
   */
  StringLiteral _stringLiteral;

  /**
   * The token representing the semicolon that marks the end of the function
   * body.
   */
  Token semicolon;

  /**
   * Initialize a newly created function body consisting of the 'native' token,
   * a string literal, and a semicolon.
   */
  NativeFunctionBody(
      this.nativeKeyword, StringLiteral stringLiteral, this.semicolon) {
    _stringLiteral = _becomeParentOf(stringLiteral);
  }

  @override
  Token get beginToken => nativeKeyword;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(nativeKeyword)
    ..add(_stringLiteral)
    ..add(semicolon);

  @override
  Token get endToken => semicolon;

  /**
   * Return the token representing 'native' that marks the start of the function
   * body.
   */
  @deprecated // Use "this.nativeKeyword"
  Token get nativeToken => nativeKeyword;

  /**
   * Set the token representing 'native' that marks the start of the function
   * body to the given [token].
   */
  @deprecated // Use "this.nativeKeyword"
  set nativeToken(Token token) {
    nativeKeyword = token;
  }

  /**
   * Return the string literal representing the string after the 'native' token.
   */
  StringLiteral get stringLiteral => _stringLiteral;

  /**
   * Set the string literal representing the string after the 'native' token to
   * the given [stringLiteral].
   */
  void set stringLiteral(StringLiteral stringLiteral) {
    _stringLiteral = _becomeParentOf(stringLiteral);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitNativeFunctionBody(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_stringLiteral, visitor);
  }
}

/**
 * A list of AST nodes that have a common parent.
 */
class NodeList<E extends AstNode> extends Object with ListMixin<E> {
  /**
   * The node that is the parent of each of the elements in the list.
   */
  AstNode owner;

  /**
   * The elements contained in the list.
   */
  List<E> _elements = <E>[];

  /**
   * Initialize a newly created list of nodes such that all of the nodes that
   * are added to the list will have their parent set to the given [owner]. The
   * list will initially be populated with the given [elements].
   */
  NodeList(this.owner, [List<E> elements]) {
    addAll(elements);
  }

  /**
   * Return the first token included in this node list's source range, or `null`
   * if the list is empty.
   */
  Token get beginToken {
    if (_elements.length == 0) {
      return null;
    }
    return _elements[0].beginToken;
  }

  /**
   * Return the last token included in this node list's source range, or `null`
   * if the list is empty.
   */
  Token get endToken {
    int length = _elements.length;
    if (length == 0) {
      return null;
    }
    return _elements[length - 1].endToken;
  }

  int get length => _elements.length;

  @deprecated // Never intended for public use.
  void set length(int value) {
    throw new UnsupportedError("Cannot resize NodeList.");
  }

  E operator [](int index) {
    if (index < 0 || index >= _elements.length) {
      throw new RangeError("Index: $index, Size: ${_elements.length}");
    }
    return _elements[index];
  }

  void operator []=(int index, E node) {
    if (index < 0 || index >= _elements.length) {
      throw new RangeError("Index: $index, Size: ${_elements.length}");
    }
    owner._becomeParentOf(node);
    _elements[index] = node;
  }

  /**
   * Use the given [visitor] to visit each of the nodes in this list.
   */
  accept(AstVisitor visitor) {
    int length = _elements.length;
    for (var i = 0; i < length; i++) {
      _elements[i].accept(visitor);
    }
  }

  @override
  void add(E node) {
    insert(length, node);
  }

  @override
  bool addAll(Iterable<E> nodes) {
    if (nodes != null && !nodes.isEmpty) {
      _elements.addAll(nodes);
      for (E node in nodes) {
        owner._becomeParentOf(node);
      }
      return true;
    }
    return false;
  }

  @override
  void clear() {
    _elements = <E>[];
  }

  @override
  void insert(int index, E node) {
    int length = _elements.length;
    if (index < 0 || index > length) {
      throw new RangeError("Index: $index, Size: ${_elements.length}");
    }
    owner._becomeParentOf(node);
    if (length == 0) {
      _elements.add(node);
    } else {
      _elements.insert(index, node);
    }
  }

  @override
  E removeAt(int index) {
    if (index < 0 || index >= _elements.length) {
      throw new RangeError("Index: $index, Size: ${_elements.length}");
    }
    E removedNode = _elements[index];
    _elements.removeAt(index);
    return removedNode;
  }

  /**
   * Create an empty list with the given [owner].
   */
  @deprecated // Use "new NodeList<E>(owner)"
  static NodeList create(AstNode owner) => new NodeList(owner);
}

/**
 * An object used to locate the [AstNode] associated with a source range, given
 * the AST structure built from the source. More specifically, they will return
 * the [AstNode] with the shortest length whose source range completely
 * encompasses the specified range.
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
   * The element that was found that corresponds to the given source range, or
   * `null` if there is no such element.
   */
  AstNode _foundNode;

  /**
   * Initialize a newly created locator to locate an [AstNode] by locating the
   * node within an AST structure that corresponds to the given [offset] in the
   * source.
   */
  NodeLocator.con1(int offset) : this.con2(offset, offset);

  /**
   * Initialize a newly created locator to locate an [AstNode] by locating the
   * node within an AST structure that corresponds to the given range of
   * characters (between the [startOffset] and [endOffset] in the source.
   */
  NodeLocator.con2(this._startOffset, this._endOffset);

  /**
   * Return the node that was found that corresponds to the given source range
   * or `null` if there is no such node.
   */
  AstNode get foundNode => _foundNode;

  /**
   * Search within the given AST [node] for an identifier representing an
   * element in the specified source range. Return the element that was found,
   * or `null` if no element was found.
   */
  AstNode searchWithin(AstNode node) {
    if (node == null) {
      return null;
    }
    try {
      node.accept(this);
    } on NodeLocator_NodeFoundException {
      // A node with the right source position was found.
    } catch (exception, stackTrace) {
      AnalysisEngine.instance.logger.logInformation(
          "Unable to locate element at offset ($_startOffset - $_endOffset)",
          new CaughtException(exception, stackTrace));
      return null;
    }
    return _foundNode;
  }

  @override
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
    } on NodeLocator_NodeFoundException {
      rethrow;
    } catch (exception, stackTrace) {
      // Ignore the exception and proceed in order to visit the rest of the
      // structure.
      AnalysisEngine.instance.logger.logInformation(
          "Exception caught while traversing an AST structure.",
          new CaughtException(exception, stackTrace));
    }
    if (start <= _startOffset && _endOffset <= end) {
      _foundNode = node;
      throw new NodeLocator_NodeFoundException();
    }
    return null;
  }
}

/**
 * An exception used by [NodeLocator] to cancel visiting after a node has been
 * found.
 */
class NodeLocator_NodeFoundException extends RuntimeException {}

/**
 * An object that will replace one child node in an AST node with another node.
 */
class NodeReplacer implements AstVisitor<bool> {
  /**
   * The node being replaced.
   */
  final AstNode _oldNode;

  /**
   * The node that is replacing the old node.
   */
  final AstNode _newNode;

  /**
   * Initialize a newly created node locator to replace the [_oldNode] with the
   * [_newNode].
   */
  NodeReplacer(this._oldNode, this._newNode);

  @override
  bool visitAdjacentStrings(AdjacentStrings node) {
    if (_replaceInList(node.strings)) {
      return true;
    }
    return visitNode(node);
  }

  bool visitAnnotatedNode(AnnotatedNode node) {
    if (identical(node.documentationComment, _oldNode)) {
      node.documentationComment = _newNode as Comment;
      return true;
    } else if (_replaceInList(node.metadata)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAnnotation(Annotation node) {
    if (identical(node.arguments, _oldNode)) {
      node.arguments = _newNode as ArgumentList;
      return true;
    } else if (identical(node.constructorName, _oldNode)) {
      node.constructorName = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as Identifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitArgumentList(ArgumentList node) {
    if (_replaceInList(node.arguments)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAsExpression(AsExpression node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    } else if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeName;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAssertStatement(AssertStatement node) {
    if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAssignmentExpression(AssignmentExpression node) {
    if (identical(node.leftHandSide, _oldNode)) {
      node.leftHandSide = _newNode as Expression;
      return true;
    } else if (identical(node.rightHandSide, _oldNode)) {
      node.rightHandSide = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitAwaitExpression(AwaitExpression node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
    }
    return visitNode(node);
  }

  @override
  bool visitBinaryExpression(BinaryExpression node) {
    if (identical(node.leftOperand, _oldNode)) {
      node.leftOperand = _newNode as Expression;
      return true;
    } else if (identical(node.rightOperand, _oldNode)) {
      node.rightOperand = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitBlock(Block node) {
    if (_replaceInList(node.statements)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitBlockFunctionBody(BlockFunctionBody node) {
    if (identical(node.block, _oldNode)) {
      node.block = _newNode as Block;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitBooleanLiteral(BooleanLiteral node) => visitNode(node);

  @override
  bool visitBreakStatement(BreakStatement node) {
    if (identical(node.label, _oldNode)) {
      node.label = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitCascadeExpression(CascadeExpression node) {
    if (identical(node.target, _oldNode)) {
      node.target = _newNode as Expression;
      return true;
    } else if (_replaceInList(node.cascadeSections)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitCatchClause(CatchClause node) {
    if (identical(node.exceptionType, _oldNode)) {
      node.exceptionType = _newNode as TypeName;
      return true;
    } else if (identical(node.exceptionParameter, _oldNode)) {
      node.exceptionParameter = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.stackTraceParameter, _oldNode)) {
      node.stackTraceParameter = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitClassDeclaration(ClassDeclaration node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterList;
      return true;
    } else if (identical(node.extendsClause, _oldNode)) {
      node.extendsClause = _newNode as ExtendsClause;
      return true;
    } else if (identical(node.withClause, _oldNode)) {
      node.withClause = _newNode as WithClause;
      return true;
    } else if (identical(node.implementsClause, _oldNode)) {
      node.implementsClause = _newNode as ImplementsClause;
      return true;
    } else if (identical(node.nativeClause, _oldNode)) {
      node.nativeClause = _newNode as NativeClause;
      return true;
    } else if (_replaceInList(node.members)) {
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitClassTypeAlias(ClassTypeAlias node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterList;
      return true;
    } else if (identical(node.superclass, _oldNode)) {
      node.superclass = _newNode as TypeName;
      return true;
    } else if (identical(node.withClause, _oldNode)) {
      node.withClause = _newNode as WithClause;
      return true;
    } else if (identical(node.implementsClause, _oldNode)) {
      node.implementsClause = _newNode as ImplementsClause;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitComment(Comment node) {
    if (_replaceInList(node.references)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitCommentReference(CommentReference node) {
    if (identical(node.identifier, _oldNode)) {
      node.identifier = _newNode as Identifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitCompilationUnit(CompilationUnit node) {
    if (identical(node.scriptTag, _oldNode)) {
      node.scriptTag = _newNode as ScriptTag;
      return true;
    } else if (_replaceInList(node.directives)) {
      return true;
    } else if (_replaceInList(node.declarations)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitConditionalExpression(ConditionalExpression node) {
    if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as Expression;
      return true;
    } else if (identical(node.thenExpression, _oldNode)) {
      node.thenExpression = _newNode as Expression;
      return true;
    } else if (identical(node.elseExpression, _oldNode)) {
      node.elseExpression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitConstructorDeclaration(ConstructorDeclaration node) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as Identifier;
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterList;
      return true;
    } else if (identical(node.redirectedConstructor, _oldNode)) {
      node.redirectedConstructor = _newNode as ConstructorName;
      return true;
    } else if (identical(node.body, _oldNode)) {
      node.body = _newNode as FunctionBody;
      return true;
    } else if (_replaceInList(node.initializers)) {
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    if (identical(node.fieldName, _oldNode)) {
      node.fieldName = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitConstructorName(ConstructorName node) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeName;
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitContinueStatement(ContinueStatement node) {
    if (identical(node.label, _oldNode)) {
      node.label = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitDeclaredIdentifier(DeclaredIdentifier node) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeName;
      return true;
    } else if (identical(node.identifier, _oldNode)) {
      node.identifier = _newNode as SimpleIdentifier;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitDefaultFormalParameter(DefaultFormalParameter node) {
    if (identical(node.parameter, _oldNode)) {
      node.parameter = _newNode as NormalFormalParameter;
      return true;
    } else if (identical(node.defaultValue, _oldNode)) {
      node.defaultValue = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitDoStatement(DoStatement node) {
    if (identical(node.body, _oldNode)) {
      node.body = _newNode as Statement;
      return true;
    } else if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitDoubleLiteral(DoubleLiteral node) => visitNode(node);

  @override
  bool visitEmptyFunctionBody(EmptyFunctionBody node) => visitNode(node);

  @override
  bool visitEmptyStatement(EmptyStatement node) => visitNode(node);

  @override
  bool visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitEnumDeclaration(EnumDeclaration node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (_replaceInList(node.constants)) {
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitExportDirective(ExportDirective node) =>
      visitNamespaceDirective(node);

  @override
  bool visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitExpressionStatement(ExpressionStatement node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitExtendsClause(ExtendsClause node) {
    if (identical(node.superclass, _oldNode)) {
      node.superclass = _newNode as TypeName;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFieldDeclaration(FieldDeclaration node) {
    if (identical(node.fields, _oldNode)) {
      node.fields = _newNode as VariableDeclarationList;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitFieldFormalParameter(FieldFormalParameter node) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeName;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterList;
      return true;
    }
    return visitNormalFormalParameter(node);
  }

  @override
  bool visitForEachStatement(ForEachStatement node) {
    if (identical(node.loopVariable, _oldNode)) {
      node.loopVariable = _newNode as DeclaredIdentifier;
      return true;
    } else if (identical(node.identifier, _oldNode)) {
      node.identifier = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.iterable, _oldNode)) {
      node.iterable = _newNode as Expression;
      return true;
    } else if (identical(node.body, _oldNode)) {
      node.body = _newNode as Statement;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFormalParameterList(FormalParameterList node) {
    if (_replaceInList(node.parameters)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitForStatement(ForStatement node) {
    if (identical(node.variables, _oldNode)) {
      node.variables = _newNode as VariableDeclarationList;
      return true;
    } else if (identical(node.initialization, _oldNode)) {
      node.initialization = _newNode as Expression;
      return true;
    } else if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as Expression;
      return true;
    } else if (identical(node.body, _oldNode)) {
      node.body = _newNode as Statement;
      return true;
    } else if (_replaceInList(node.updaters)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFunctionDeclaration(FunctionDeclaration node) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as TypeName;
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.functionExpression, _oldNode)) {
      node.functionExpression = _newNode as FunctionExpression;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    if (identical(node.functionDeclaration, _oldNode)) {
      node.functionDeclaration = _newNode as FunctionDeclaration;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFunctionExpression(FunctionExpression node) {
    if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterList;
      return true;
    } else if (identical(node.body, _oldNode)) {
      node.body = _newNode as FunctionBody;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (identical(node.function, _oldNode)) {
      node.function = _newNode as Expression;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      node.argumentList = _newNode as ArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as TypeName;
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.typeParameters, _oldNode)) {
      node.typeParameters = _newNode as TypeParameterList;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterList;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as TypeName;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterList;
      return true;
    }
    return visitNormalFormalParameter(node);
  }

  @override
  bool visitHideCombinator(HideCombinator node) {
    if (_replaceInList(node.hiddenNames)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitIfStatement(IfStatement node) {
    if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as Expression;
      return true;
    } else if (identical(node.thenStatement, _oldNode)) {
      node.thenStatement = _newNode as Statement;
      return true;
    } else if (identical(node.elseStatement, _oldNode)) {
      node.elseStatement = _newNode as Statement;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitImplementsClause(ImplementsClause node) {
    if (_replaceInList(node.interfaces)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitImportDirective(ImportDirective node) {
    if (identical(node.prefix, _oldNode)) {
      node.prefix = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNamespaceDirective(node);
  }

  @override
  bool visitIndexExpression(IndexExpression node) {
    if (identical(node.target, _oldNode)) {
      node.target = _newNode as Expression;
      return true;
    } else if (identical(node.index, _oldNode)) {
      node.index = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (identical(node.constructorName, _oldNode)) {
      node.constructorName = _newNode as ConstructorName;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      node.argumentList = _newNode as ArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitIntegerLiteral(IntegerLiteral node) => visitNode(node);

  @override
  bool visitInterpolationExpression(InterpolationExpression node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitInterpolationString(InterpolationString node) => visitNode(node);

  @override
  bool visitIsExpression(IsExpression node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    } else if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeName;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitLabel(Label node) {
    if (identical(node.label, _oldNode)) {
      node.label = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitLabeledStatement(LabeledStatement node) {
    if (identical(node.statement, _oldNode)) {
      node.statement = _newNode as Statement;
      return true;
    } else if (_replaceInList(node.labels)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitLibraryDirective(LibraryDirective node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as LibraryIdentifier;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitLibraryIdentifier(LibraryIdentifier node) {
    if (_replaceInList(node.components)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitListLiteral(ListLiteral node) {
    if (_replaceInList(node.elements)) {
      return true;
    }
    return visitTypedLiteral(node);
  }

  @override
  bool visitMapLiteral(MapLiteral node) {
    if (_replaceInList(node.entries)) {
      return true;
    }
    return visitTypedLiteral(node);
  }

  @override
  bool visitMapLiteralEntry(MapLiteralEntry node) {
    if (identical(node.key, _oldNode)) {
      node.key = _newNode as Expression;
      return true;
    } else if (identical(node.value, _oldNode)) {
      node.value = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitMethodDeclaration(MethodDeclaration node) {
    if (identical(node.returnType, _oldNode)) {
      node.returnType = _newNode as TypeName;
      return true;
    } else if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.parameters, _oldNode)) {
      node.parameters = _newNode as FormalParameterList;
      return true;
    } else if (identical(node.body, _oldNode)) {
      node.body = _newNode as FunctionBody;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitMethodInvocation(MethodInvocation node) {
    if (identical(node.target, _oldNode)) {
      node.target = _newNode as Expression;
      return true;
    } else if (identical(node.methodName, _oldNode)) {
      node.methodName = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      node.argumentList = _newNode as ArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitNamedExpression(NamedExpression node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as Label;
      return true;
    } else if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  bool visitNamespaceDirective(NamespaceDirective node) {
    if (_replaceInList(node.combinators)) {
      return true;
    }
    return visitUriBasedDirective(node);
  }

  @override
  bool visitNativeClause(NativeClause node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as StringLiteral;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitNativeFunctionBody(NativeFunctionBody node) {
    if (identical(node.stringLiteral, _oldNode)) {
      node.stringLiteral = _newNode as StringLiteral;
      return true;
    }
    return visitNode(node);
  }

  bool visitNode(AstNode node) {
    throw new IllegalArgumentException(
        "The old node is not a child of it's parent");
  }

  bool visitNormalFormalParameter(NormalFormalParameter node) {
    if (identical(node.documentationComment, _oldNode)) {
      node.documentationComment = _newNode as Comment;
      return true;
    } else if (identical(node.identifier, _oldNode)) {
      node.identifier = _newNode as SimpleIdentifier;
      return true;
    } else if (_replaceInList(node.metadata)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitNullLiteral(NullLiteral node) => visitNode(node);

  @override
  bool visitParenthesizedExpression(ParenthesizedExpression node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitPartDirective(PartDirective node) => visitUriBasedDirective(node);

  @override
  bool visitPartOfDirective(PartOfDirective node) {
    if (identical(node.libraryName, _oldNode)) {
      node.libraryName = _newNode as LibraryIdentifier;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitPostfixExpression(PostfixExpression node) {
    if (identical(node.operand, _oldNode)) {
      node.operand = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (identical(node.prefix, _oldNode)) {
      node.prefix = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.identifier, _oldNode)) {
      node.identifier = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitPrefixExpression(PrefixExpression node) {
    if (identical(node.operand, _oldNode)) {
      node.operand = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitPropertyAccess(PropertyAccess node) {
    if (identical(node.target, _oldNode)) {
      node.target = _newNode as Expression;
      return true;
    } else if (identical(node.propertyName, _oldNode)) {
      node.propertyName = _newNode as SimpleIdentifier;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    if (identical(node.constructorName, _oldNode)) {
      node.constructorName = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      node.argumentList = _newNode as ArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitRethrowExpression(RethrowExpression node) => visitNode(node);

  @override
  bool visitReturnStatement(ReturnStatement node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitScriptTag(ScriptTag scriptTag) => visitNode(scriptTag);

  @override
  bool visitShowCombinator(ShowCombinator node) {
    if (_replaceInList(node.shownNames)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitSimpleFormalParameter(SimpleFormalParameter node) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeName;
      return true;
    }
    return visitNormalFormalParameter(node);
  }

  @override
  bool visitSimpleIdentifier(SimpleIdentifier node) => visitNode(node);

  @override
  bool visitSimpleStringLiteral(SimpleStringLiteral node) => visitNode(node);

  @override
  bool visitStringInterpolation(StringInterpolation node) {
    if (_replaceInList(node.elements)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    if (identical(node.constructorName, _oldNode)) {
      node.constructorName = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.argumentList, _oldNode)) {
      node.argumentList = _newNode as ArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitSuperExpression(SuperExpression node) => visitNode(node);

  @override
  bool visitSwitchCase(SwitchCase node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitSwitchMember(node);
  }

  @override
  bool visitSwitchDefault(SwitchDefault node) => visitSwitchMember(node);

  bool visitSwitchMember(SwitchMember node) {
    if (_replaceInList(node.labels)) {
      return true;
    } else if (_replaceInList(node.statements)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitSwitchStatement(SwitchStatement node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    } else if (_replaceInList(node.members)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitSymbolLiteral(SymbolLiteral node) => visitNode(node);

  @override
  bool visitThisExpression(ThisExpression node) => visitNode(node);

  @override
  bool visitThrowExpression(ThrowExpression node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (identical(node.variables, _oldNode)) {
      node.variables = _newNode as VariableDeclarationList;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitTryStatement(TryStatement node) {
    if (identical(node.body, _oldNode)) {
      node.body = _newNode as Block;
      return true;
    } else if (identical(node.finallyBlock, _oldNode)) {
      node.finallyBlock = _newNode as Block;
      return true;
    } else if (_replaceInList(node.catchClauses)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitTypeArgumentList(TypeArgumentList node) {
    if (_replaceInList(node.arguments)) {
      return true;
    }
    return visitNode(node);
  }

  bool visitTypedLiteral(TypedLiteral node) {
    if (identical(node.typeArguments, _oldNode)) {
      node.typeArguments = _newNode as TypeArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitTypeName(TypeName node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as Identifier;
      return true;
    } else if (identical(node.typeArguments, _oldNode)) {
      node.typeArguments = _newNode as TypeArgumentList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitTypeParameter(TypeParameter node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.bound, _oldNode)) {
      node.bound = _newNode as TypeName;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitTypeParameterList(TypeParameterList node) {
    if (_replaceInList(node.typeParameters)) {
      return true;
    }
    return visitNode(node);
  }

  bool visitUriBasedDirective(UriBasedDirective node) {
    if (identical(node.uri, _oldNode)) {
      node.uri = _newNode as StringLiteral;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitVariableDeclaration(VariableDeclaration node) {
    if (identical(node.name, _oldNode)) {
      node.name = _newNode as SimpleIdentifier;
      return true;
    } else if (identical(node.initializer, _oldNode)) {
      node.initializer = _newNode as Expression;
      return true;
    }
    return visitAnnotatedNode(node);
  }

  @override
  bool visitVariableDeclarationList(VariableDeclarationList node) {
    if (identical(node.type, _oldNode)) {
      node.type = _newNode as TypeName;
      return true;
    } else if (_replaceInList(node.variables)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    if (identical(node.variables, _oldNode)) {
      node.variables = _newNode as VariableDeclarationList;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitWhileStatement(WhileStatement node) {
    if (identical(node.condition, _oldNode)) {
      node.condition = _newNode as Expression;
      return true;
    } else if (identical(node.body, _oldNode)) {
      node.body = _newNode as Statement;
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitWithClause(WithClause node) {
    if (_replaceInList(node.mixinTypes)) {
      return true;
    }
    return visitNode(node);
  }

  @override
  bool visitYieldStatement(YieldStatement node) {
    if (identical(node.expression, _oldNode)) {
      node.expression = _newNode as Expression;
    }
    return visitNode(node);
  }

  bool _replaceInList(NodeList list) {
    int count = list.length;
    for (int i = 0; i < count; i++) {
      if (identical(_oldNode, list[i])) {
        list[i] = _newNode;
        return true;
      }
    }
    return false;
  }

  /**
   * Replace the [oldNode] with the [newNode] in the AST structure containing
   * the old node. Return `true` if the replacement was successful.
   *
   * Throws an [IllegalArgumentException] if either node is `null`, if the old
   * node does not have a parent node, or if the AST structure has been
   * corrupted.
   */
  static bool replace(AstNode oldNode, AstNode newNode) {
    if (oldNode == null || newNode == null) {
      throw new IllegalArgumentException(
          "The old and new nodes must be non-null");
    } else if (identical(oldNode, newNode)) {
      return true;
    }
    AstNode parent = oldNode.parent;
    if (parent == null) {
      throw new IllegalArgumentException(
          "The old node is not a child of another node");
    }
    NodeReplacer replacer = new NodeReplacer(oldNode, newNode);
    return parent.accept(replacer);
  }
}

/**
 * A formal parameter that is required (is not optional).
 *
 * > normalFormalParameter ::=
 * >     [FunctionTypedFormalParameter]
 * >   | [FieldFormalParameter]
 * >   | [SimpleFormalParameter]
 */
abstract class NormalFormalParameter extends FormalParameter {
  /**
   * The documentation comment associated with this parameter, or `null` if this
   * parameter does not have a documentation comment associated with it.
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
   * Initialize a newly created formal parameter. Either or both of the
   * [comment] and [metadata] can be `null` if the parameter does not have the
   * corresponding attribute.
   */
  NormalFormalParameter(
      Comment comment, List<Annotation> metadata, SimpleIdentifier identifier) {
    _comment = _becomeParentOf(comment);
    _metadata = new NodeList<Annotation>(this, metadata);
    _identifier = _becomeParentOf(identifier);
  }

  /**
   * Return the documentation comment associated with this parameter, or `null`
   * if this parameter does not have a documentation comment associated with it.
   */
  Comment get documentationComment => _comment;

  /**
   * Set the documentation comment associated with this parameter to the given
   * [comment].
   */
  void set documentationComment(Comment comment) {
    _comment = _becomeParentOf(comment);
  }

  @override
  SimpleIdentifier get identifier => _identifier;

  /**
   * Set the name of the parameter being declared to the given [identifier].
   */
  void set identifier(SimpleIdentifier identifier) {
    _identifier = _becomeParentOf(identifier);
  }

  @override
  ParameterKind get kind {
    AstNode parent = this.parent;
    if (parent is DefaultFormalParameter) {
      return parent.kind;
    }
    return ParameterKind.REQUIRED;
  }

  /**
   * Return the annotations associated with this parameter.
   */
  NodeList<Annotation> get metadata => _metadata;

  /**
   * Set the metadata associated with this node to the given [metadata].
   */
  void set metadata(List<Annotation> metadata) {
    _metadata.clear();
    _metadata.addAll(metadata);
  }

  /**
   * Return a list containing the comment and annotations associated with this
   * parameter, sorted in lexical order.
   */
  List<AstNode> get sortedCommentAndAnnotations {
    return <AstNode>[]
      ..add(_comment)
      ..addAll(_metadata)
      ..sort(AstNode.LEXICAL_ORDER);
  }

  ChildEntities get _childEntities {
    ChildEntities result = new ChildEntities();
    if (_commentIsBeforeAnnotations()) {
      result
        ..add(_comment)
        ..addAll(_metadata);
    } else {
      result.addAll(sortedCommentAndAnnotations);
    }
    return result;
  }

  @override
  void visitChildren(AstVisitor visitor) {
    //
    // Note that subclasses are responsible for visiting the identifier because
    // they often need to visit other nodes before visiting the identifier.
    //
    if (_commentIsBeforeAnnotations()) {
      _safelyVisitChild(_comment, visitor);
      _metadata.accept(visitor);
    } else {
      for (AstNode child in sortedCommentAndAnnotations) {
        child.accept(visitor);
      }
    }
  }

  /**
   * Return `true` if the comment is lexically before any annotations.
   */
  bool _commentIsBeforeAnnotations() {
    if (_comment == null || _metadata.isEmpty) {
      return true;
    }
    Annotation firstAnnotation = _metadata[0];
    return _comment.offset < firstAnnotation.offset;
  }
}

/**
 * A null literal expression.
 *
 * > nullLiteral ::=
 * >     'null'
 */
class NullLiteral extends Literal {
  /**
   * The token representing the literal.
   */
  Token literal;

  /**
   * Initialize a newly created null literal.
   */
  NullLiteral(this.literal);

  @override
  Token get beginToken => literal;

  @override
  Iterable get childEntities => new ChildEntities()..add(literal);

  @override
  Token get endToken => literal;

  @override
  accept(AstVisitor visitor) => visitor.visitNullLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/**
 * A parenthesized expression.
 *
 * > parenthesizedExpression ::=
 * >     '(' [Expression] ')'
 */
class ParenthesizedExpression extends Expression {
  /**
   * The left parenthesis.
   */
  Token leftParenthesis;

  /**
   * The expression within the parentheses.
   */
  Expression _expression;

  /**
   * The right parenthesis.
   */
  Token rightParenthesis;

  /**
   * Initialize a newly created parenthesized expression.
   */
  ParenthesizedExpression(
      this.leftParenthesis, Expression expression, this.rightParenthesis) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Token get beginToken => leftParenthesis;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(leftParenthesis)
    ..add(_expression)
    ..add(rightParenthesis);

  @override
  Token get endToken => rightParenthesis;

  /**
   * Return the expression within the parentheses.
   */
  Expression get expression => _expression;

  /**
   * Set the expression within the parentheses to the given [expression].
   */
  void set expression(Expression expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  int get precedence => 15;

  @override
  accept(AstVisitor visitor) => visitor.visitParenthesizedExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_expression, visitor);
  }
}

/**
 * A part directive.
 *
 * > partDirective ::=
 * >     [Annotation] 'part' [StringLiteral] ';'
 */
class PartDirective extends UriBasedDirective {
  /**
   * The token representing the 'part' keyword.
   */
  Token partKeyword;

  /**
   * The semicolon terminating the directive.
   */
  Token semicolon;

  /**
   * Initialize a newly created part directive. Either or both of the [comment]
   * and [metadata] can be `null` if the directive does not have the
   * corresponding attribute.
   */
  PartDirective(Comment comment, List<Annotation> metadata, this.partKeyword,
      StringLiteral partUri, this.semicolon)
      : super(comment, metadata, partUri);

  @override
  Iterable get childEntities => super._childEntities
    ..add(partKeyword)
    ..add(_uri)
    ..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => partKeyword;

  @override
  Token get keyword => partKeyword;

  /**
   * Return the token representing the 'part' token.
   */
  @deprecated // Use "this.partKeyword"
  Token get partToken => partKeyword;

  /**
   * Set the token representing the 'part' token to the given [token].
   */
  @deprecated // Use "this.partKeyword"
  set partToken(Token token) {
    partKeyword = token;
  }

  @override
  CompilationUnitElement get uriElement => element as CompilationUnitElement;

  @override
  accept(AstVisitor visitor) => visitor.visitPartDirective(this);
}

/**
 * A part-of directive.
 *
 * > partOfDirective ::=
 * >     [Annotation] 'part' 'of' [Identifier] ';'
 */
class PartOfDirective extends Directive {
  /**
   * The token representing the 'part' keyword.
   */
  Token partKeyword;

  /**
   * The token representing the 'of' keyword.
   */
  Token ofKeyword;

  /**
   * The name of the library that the containing compilation unit is part of.
   */
  LibraryIdentifier _libraryName;

  /**
   * The semicolon terminating the directive.
   */
  Token semicolon;

  /**
   * Initialize a newly created part-of directive. Either or both of the
   * [comment] and [metadata] can be `null` if the directive does not have the
   * corresponding attribute.
   */
  PartOfDirective(Comment comment, List<Annotation> metadata, this.partKeyword,
      this.ofKeyword, LibraryIdentifier libraryName, this.semicolon)
      : super(comment, metadata) {
    _libraryName = _becomeParentOf(libraryName);
  }

  @override
  Iterable get childEntities => super._childEntities
    ..add(partKeyword)
    ..add(ofKeyword)
    ..add(_libraryName)
    ..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => partKeyword;

  @override
  Token get keyword => partKeyword;

  /**
   * Return the name of the library that the containing compilation unit is part
   * of.
   */
  LibraryIdentifier get libraryName => _libraryName;

  /**
   * Set the name of the library that the containing compilation unit is part of
   * to the given [libraryName].
   */
  void set libraryName(LibraryIdentifier libraryName) {
    _libraryName = _becomeParentOf(libraryName);
  }

  /**
   * Return the token representing the 'of' token.
   */
  @deprecated // Use "this.ofKeyword"
  Token get ofToken => ofKeyword;

  /**
   * Set the token representing the 'of' token to the given [token].
   */
  @deprecated // Use "this.ofKeyword"
  set ofToken(Token token) {
    ofKeyword = token;
  }

  /**
   * Return the token representing the 'part' token.
   */
  @deprecated // Use "this.partKeyword"
  Token get partToken => partKeyword;

  /**
   * Set the token representing the 'part' token to the given [token].
   */
  @deprecated // Use "this.partKeyword"
  set partToken(Token token) {
    partKeyword = token;
  }

  @override
  accept(AstVisitor visitor) => visitor.visitPartOfDirective(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_libraryName, visitor);
  }
}

/**
 * A postfix unary expression.
 *
 * > postfixExpression ::=
 * >     [Expression] [Token]
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
   * The element associated with this the operator based on the propagated type
   * of the operand, or `null` if the AST structure has not been resolved, if
   * the operator is not user definable, or if the operator could not be
   * resolved.
   */
  MethodElement propagatedElement;

  /**
   * The element associated with the operator based on the static type of the
   * operand, or `null` if the AST structure has not been resolved, if the
   * operator is not user definable, or if the operator could not be resolved.
   */
  MethodElement staticElement;

  /**
   * Initialize a newly created postfix expression.
   */
  PostfixExpression(Expression operand, this.operator) {
    _operand = _becomeParentOf(operand);
  }

  @override
  Token get beginToken => _operand.beginToken;

  /**
   * Return the best element available for this operator. If resolution was able
   * to find a better element based on type propagation, that element will be
   * returned. Otherwise, the element found using the result of static analysis
   * will be returned. If resolution has not been performed, then `null` will be
   * returned.
   */
  MethodElement get bestElement {
    MethodElement element = propagatedElement;
    if (element == null) {
      element = staticElement;
    }
    return element;
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(_operand)
    ..add(operator);

  @override
  Token get endToken => operator;

  /**
   * Return the expression computing the operand for the operator.
   */
  Expression get operand => _operand;

  /**
   * Set the expression computing the operand for the operator to the given
   * [expression].
   */
  void set operand(Expression expression) {
    _operand = _becomeParentOf(expression);
  }

  @override
  int get precedence => 15;

  /**
   * If the AST structure has been resolved, and the function being invoked is
   * known based on propagated type information, then return the parameter
   * element representing the parameter to which the value of the operand will
   * be bound. Otherwise, return `null`.
   */
  @deprecated // Use "expression.propagatedParameterElement"
  ParameterElement get propagatedParameterElementForOperand {
    return _propagatedParameterElementForOperand;
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is
   * known based on static type information, then return the parameter element
   * representing the parameter to which the value of the operand will be bound.
   * Otherwise, return `null`.
   */
  @deprecated // Use "expression.propagatedParameterElement"
  ParameterElement get staticParameterElementForOperand {
    return _staticParameterElementForOperand;
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is
   * known based on propagated type information, then return the parameter
   * element representing the parameter to which the value of the operand will
   * be bound. Otherwise, return `null`.
   */
  ParameterElement get _propagatedParameterElementForOperand {
    if (propagatedElement == null) {
      return null;
    }
    List<ParameterElement> parameters = propagatedElement.parameters;
    if (parameters.length < 1) {
      return null;
    }
    return parameters[0];
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is
   * known based on static type information, then return the parameter element
   * representing the parameter to which the value of the operand will be bound.
   * Otherwise, return `null`.
   */
  ParameterElement get _staticParameterElementForOperand {
    if (staticElement == null) {
      return null;
    }
    List<ParameterElement> parameters = staticElement.parameters;
    if (parameters.length < 1) {
      return null;
    }
    return parameters[0];
  }

  @override
  accept(AstVisitor visitor) => visitor.visitPostfixExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_operand, visitor);
  }
}

/**
 * An identifier that is prefixed or an access to an object property where the
 * target of the property access is a simple identifier.
 *
 * > prefixedIdentifier ::=
 * >     [SimpleIdentifier] '.' [SimpleIdentifier]
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
   */
  PrefixedIdentifier(
      SimpleIdentifier prefix, this.period, SimpleIdentifier identifier) {
    _prefix = _becomeParentOf(prefix);
    _identifier = _becomeParentOf(identifier);
  }

  @override
  Token get beginToken => _prefix.beginToken;

  @override
  Element get bestElement {
    if (_identifier == null) {
      return null;
    }
    return _identifier.bestElement;
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(_prefix)
    ..add(period)
    ..add(_identifier);

  @override
  Token get endToken => _identifier.endToken;

  /**
   * Return the identifier being prefixed.
   */
  SimpleIdentifier get identifier => _identifier;

  /**
   * Set the identifier being prefixed to the given [identifier].
   */
  void set identifier(SimpleIdentifier identifier) {
    _identifier = _becomeParentOf(identifier);
  }

  /**
   * Return `true` if this type is a deferred type. If the AST structure has not
   * been resolved, then return `false`.
   *
   * 15.1 Static Types: A type <i>T</i> is deferred iff it is of the form
   * </i>p.T</i> where <i>p</i> is a deferred prefix.
   */
  bool get isDeferred {
    Element element = _prefix.staticElement;
    if (element is! PrefixElement) {
      return false;
    }
    PrefixElement prefixElement = element as PrefixElement;
    List<ImportElement> imports =
        prefixElement.enclosingElement.getImportsWithPrefix(prefixElement);
    if (imports.length != 1) {
      return false;
    }
    return imports[0].isDeferred;
  }

  @override
  String get name => "${_prefix.name}.${_identifier.name}";

  @override
  int get precedence => 15;

  /**
   * Return the prefix associated with the library in which the identifier is
   * defined.
   */
  SimpleIdentifier get prefix => _prefix;

  /**
   * Set the prefix associated with the library in which the identifier is
   * defined to the given [identifier].
   */
  void set prefix(SimpleIdentifier identifier) {
    _prefix = _becomeParentOf(identifier);
  }

  @override
  Element get propagatedElement {
    if (_identifier == null) {
      return null;
    }
    return _identifier.propagatedElement;
  }

  @override
  Element get staticElement {
    if (_identifier == null) {
      return null;
    }
    return _identifier.staticElement;
  }

  @override
  accept(AstVisitor visitor) => visitor.visitPrefixedIdentifier(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_prefix, visitor);
    _safelyVisitChild(_identifier, visitor);
  }
}

/**
 * A prefix unary expression.
 *
 * > prefixExpression ::=
 * >     [Token] [Expression]
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
   * The element associated with the operator based on the static type of the
   * operand, or `null` if the AST structure has not been resolved, if the
   * operator is not user definable, or if the operator could not be resolved.
   */
  MethodElement staticElement;

  /**
   * The element associated with the operator based on the propagated type of
   * the operand, or `null` if the AST structure has not been resolved, if the
   * operator is not user definable, or if the operator could not be resolved.
   */
  MethodElement propagatedElement;

  /**
   * Initialize a newly created prefix expression.
   */
  PrefixExpression(this.operator, Expression operand) {
    _operand = _becomeParentOf(operand);
  }

  @override
  Token get beginToken => operator;

  /**
   * Return the best element available for this operator. If resolution was able
   * to find a better element based on type propagation, that element will be
   * returned. Otherwise, the element found using the result of static analysis
   * will be returned. If resolution has not been performed, then `null` will be
   * returned.
   */
  MethodElement get bestElement {
    MethodElement element = propagatedElement;
    if (element == null) {
      element = staticElement;
    }
    return element;
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(operator)
    ..add(_operand);

  @override
  Token get endToken => _operand.endToken;

  /**
   * Return the expression computing the operand for the operator.
   */
  Expression get operand => _operand;

  /**
   * Set the expression computing the operand for the operator to the given
   * [expression].
   */
  void set operand(Expression expression) {
    _operand = _becomeParentOf(expression);
  }

  @override
  int get precedence => 14;

  /**
   * If the AST structure has been resolved, and the function being invoked is
   * known based on propagated type information, then return the parameter
   * element representing the parameter to which the value of the operand will
   * be bound. Otherwise, return `null`.
   */
  @deprecated // Use "expression.propagatedParameterElement"
  ParameterElement get propagatedParameterElementForOperand {
    return _propagatedParameterElementForOperand;
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is
   * known based on static type information, then return the parameter element
   * representing the parameter to which the value of the operand will be bound.
   * Otherwise, return `null`.
   */
  @deprecated // Use "expression.propagatedParameterElement"
  ParameterElement get staticParameterElementForOperand {
    return _staticParameterElementForOperand;
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is
   * known based on propagated type information, then return the parameter
   * element representing the parameter to which the value of the operand will
   * be bound. Otherwise, return `null`.
   */
  ParameterElement get _propagatedParameterElementForOperand {
    if (propagatedElement == null) {
      return null;
    }
    List<ParameterElement> parameters = propagatedElement.parameters;
    if (parameters.length < 1) {
      return null;
    }
    return parameters[0];
  }

  /**
   * If the AST structure has been resolved, and the function being invoked is
   * known based on static type information, then return the parameter element
   * representing the parameter to which the value of the operand will be bound.
   * Otherwise, return `null`.
   */
  ParameterElement get _staticParameterElementForOperand {
    if (staticElement == null) {
      return null;
    }
    List<ParameterElement> parameters = staticElement.parameters;
    if (parameters.length < 1) {
      return null;
    }
    return parameters[0];
  }

  @override
  accept(AstVisitor visitor) => visitor.visitPrefixExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_operand, visitor);
  }
}

/**
 * The access of a property of an object.
 *
 * Note, however, that accesses to properties of objects can also be represented
 * as [PrefixedIdentifier] nodes in cases where the target is also a simple
 * identifier.
 *
 * > propertyAccess ::=
 * >     [Expression] '.' [SimpleIdentifier]
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
   */
  PropertyAccess(
      Expression target, this.operator, SimpleIdentifier propertyName) {
    _target = _becomeParentOf(target);
    _propertyName = _becomeParentOf(propertyName);
  }

  @override
  Token get beginToken {
    if (_target != null) {
      return _target.beginToken;
    }
    return operator;
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(_target)
    ..add(operator)
    ..add(_propertyName);

  @override
  Token get endToken => _propertyName.endToken;

  @override
  bool get isAssignable => true;

  /**
   * Return `true` if this expression is cascaded. If it is, then the target of
   * this expression is not stored locally but is stored in the nearest ancestor
   * that is a [CascadeExpression].
   */
  bool get isCascaded =>
      operator != null && operator.type == TokenType.PERIOD_PERIOD;

  @override
  int get precedence => 15;

  /**
   * Return the name of the property being accessed.
   */
  SimpleIdentifier get propertyName => _propertyName;

  /**
   * Set the name of the property being accessed to the given [identifier].
   */
  void set propertyName(SimpleIdentifier identifier) {
    _propertyName = _becomeParentOf(identifier);
  }

  /**
   * Return the expression used to compute the receiver of the invocation. If
   * this invocation is not part of a cascade expression, then this is the same
   * as [target]. If this invocation is part of a cascade expression, then the
   * target stored with the cascade expression is returned.
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
   * Return the expression computing the object defining the property being
   * accessed, or `null` if this property access is part of a cascade expression.
   *
   * Use [realTarget] to get the target independent of whether this is part of a
   * cascade expression.
   */
  Expression get target => _target;

  /**
   * Set the expression computing the object defining the property being
   * accessed to the given [expression].
   */
  void set target(Expression expression) {
    _target = _becomeParentOf(expression);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitPropertyAccess(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_target, visitor);
    _safelyVisitChild(_propertyName, visitor);
  }
}

/**
 * An AST visitor that will recursively visit all of the nodes in an AST
 * structure. For example, using an instance of this class to visit a [Block]
 * will also cause all of the statements in the block to be visited.
 *
 * Subclasses that override a visit method must either invoke the overridden
 * visit method or must explicitly ask the visited node to visit its children.
 * Failure to do so will cause the children of the visited node to not be
 * visited.
 */
class RecursiveAstVisitor<R> implements AstVisitor<R> {
  @override
  R visitAdjacentStrings(AdjacentStrings node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitAnnotation(Annotation node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitArgumentList(ArgumentList node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitAsExpression(AsExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitAssertStatement(AssertStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitAssignmentExpression(AssignmentExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitAwaitExpression(AwaitExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitBinaryExpression(BinaryExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitBlock(Block node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitBlockFunctionBody(BlockFunctionBody node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitBooleanLiteral(BooleanLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitBreakStatement(BreakStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitCascadeExpression(CascadeExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitCatchClause(CatchClause node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitClassDeclaration(ClassDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitClassTypeAlias(ClassTypeAlias node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitComment(Comment node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitCommentReference(CommentReference node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitCompilationUnit(CompilationUnit node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitConditionalExpression(ConditionalExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitConstructorDeclaration(ConstructorDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitConstructorName(ConstructorName node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitContinueStatement(ContinueStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitDeclaredIdentifier(DeclaredIdentifier node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitDoStatement(DoStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitDoubleLiteral(DoubleLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitEmptyFunctionBody(EmptyFunctionBody node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitEmptyStatement(EmptyStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitEnumDeclaration(EnumDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitExportDirective(ExportDirective node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitExpressionFunctionBody(ExpressionFunctionBody node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitExpressionStatement(ExpressionStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitExtendsClause(ExtendsClause node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitFieldDeclaration(FieldDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitFieldFormalParameter(FieldFormalParameter node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitForEachStatement(ForEachStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitFormalParameterList(FormalParameterList node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitForStatement(ForStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitFunctionDeclaration(FunctionDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitFunctionExpression(FunctionExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitFunctionTypeAlias(FunctionTypeAlias node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitHideCombinator(HideCombinator node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitIfStatement(IfStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitImplementsClause(ImplementsClause node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitImportDirective(ImportDirective node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitIndexExpression(IndexExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitInstanceCreationExpression(InstanceCreationExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitIntegerLiteral(IntegerLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitInterpolationExpression(InterpolationExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitInterpolationString(InterpolationString node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitIsExpression(IsExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitLabel(Label node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitLabeledStatement(LabeledStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitLibraryDirective(LibraryDirective node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitLibraryIdentifier(LibraryIdentifier node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitListLiteral(ListLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitMapLiteral(MapLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitMapLiteralEntry(MapLiteralEntry node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitMethodDeclaration(MethodDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitMethodInvocation(MethodInvocation node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitNamedExpression(NamedExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitNativeClause(NativeClause node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitNativeFunctionBody(NativeFunctionBody node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitNullLiteral(NullLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitParenthesizedExpression(ParenthesizedExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitPartDirective(PartDirective node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitPartOfDirective(PartOfDirective node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitPostfixExpression(PostfixExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitPrefixedIdentifier(PrefixedIdentifier node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitPrefixExpression(PrefixExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitPropertyAccess(PropertyAccess node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitRethrowExpression(RethrowExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitReturnStatement(ReturnStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitScriptTag(ScriptTag node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitShowCombinator(ShowCombinator node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitSimpleFormalParameter(SimpleFormalParameter node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitSimpleIdentifier(SimpleIdentifier node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitSimpleStringLiteral(SimpleStringLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitSuperExpression(SuperExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitSwitchCase(SwitchCase node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitSwitchDefault(SwitchDefault node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitSwitchStatement(SwitchStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitSymbolLiteral(SymbolLiteral node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitThisExpression(ThisExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitThrowExpression(ThrowExpression node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitTryStatement(TryStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitTypeArgumentList(TypeArgumentList node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitTypeName(TypeName node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitTypeParameter(TypeParameter node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitTypeParameterList(TypeParameterList node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitVariableDeclaration(VariableDeclaration node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitVariableDeclarationList(VariableDeclarationList node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitWhileStatement(WhileStatement node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitWithClause(WithClause node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitYieldStatement(YieldStatement node) {
    node.visitChildren(this);
    return null;
  }
}

/**
 * The invocation of a constructor in the same class from within a constructor's
 * initialization list.
 *
 * > redirectingConstructorInvocation ::=
 * >     'this' ('.' identifier)? arguments
 */
class RedirectingConstructorInvocation extends ConstructorInitializer {
  /**
   * The token for the 'this' keyword.
   */
  Token thisKeyword;

  /**
   * The token for the period before the name of the constructor that is being
   * invoked, or `null` if the unnamed constructor is being invoked.
   */
  Token period;

  /**
   * The name of the constructor that is being invoked, or `null` if the unnamed
   * constructor is being invoked.
   */
  SimpleIdentifier _constructorName;

  /**
   * The list of arguments to the constructor.
   */
  ArgumentList _argumentList;

  /**
   * The element associated with the constructor based on static type
   * information, or `null` if the AST structure has not been resolved or if the
   * constructor could not be resolved.
   */
  ConstructorElement staticElement;

  /**
   * Initialize a newly created redirecting invocation to invoke the constructor
   * with the given name with the given arguments. The [constructorName] can be
   * `null` if the constructor being invoked is the unnamed constructor.
   */
  RedirectingConstructorInvocation(this.thisKeyword, this.period,
      SimpleIdentifier constructorName, ArgumentList argumentList) {
    _constructorName = _becomeParentOf(constructorName);
    _argumentList = _becomeParentOf(argumentList);
  }

  /**
   * Return the list of arguments to the constructor.
   */
  ArgumentList get argumentList => _argumentList;

  /**
   * Set the list of arguments to the constructor to the given [argumentList].
   */
  void set argumentList(ArgumentList argumentList) {
    _argumentList = _becomeParentOf(argumentList);
  }

  @override
  Token get beginToken => thisKeyword;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(thisKeyword)
    ..add(period)
    ..add(_constructorName)
    ..add(_argumentList);

  /**
   * Return the name of the constructor that is being invoked, or `null` if the
   * unnamed constructor is being invoked.
   */
  SimpleIdentifier get constructorName => _constructorName;

  /**
   * Set the name of the constructor that is being invoked to the given
   * [identifier].
   */
  void set constructorName(SimpleIdentifier identifier) {
    _constructorName = _becomeParentOf(identifier);
  }

  @override
  Token get endToken => _argumentList.endToken;

  /**
   * Return the token for the 'this' keyword.
   */
  @deprecated // Use "this.thisKeyword"
  Token get keyword => thisKeyword;

  /**
   * Set the token for the 'this' keyword to the given [token].
   */
  @deprecated // Use "this.thisKeyword"
  set keyword(Token token) {
    thisKeyword = token;
  }

  @override
  accept(AstVisitor visitor) =>
      visitor.visitRedirectingConstructorInvocation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_constructorName, visitor);
    _safelyVisitChild(_argumentList, visitor);
  }
}

/**
 * A rethrow expression.
 *
 * > rethrowExpression ::=
 * >     'rethrow'
 */
class RethrowExpression extends Expression {
  /**
   * The token representing the 'rethrow' keyword.
   */
  Token rethrowKeyword;

  /**
   * Initialize a newly created rethrow expression.
   */
  RethrowExpression(this.rethrowKeyword);

  @override
  Token get beginToken => rethrowKeyword;

  @override
  Iterable get childEntities => new ChildEntities()..add(rethrowKeyword);

  @override
  Token get endToken => rethrowKeyword;

  /**
   * Return the token representing the 'rethrow' keyword.
   */
  @deprecated // Use "this.rethrowKeyword"
  Token get keyword => rethrowKeyword;

  /**
   * Set the token representing the 'rethrow' keyword to the given [token].
   */
  @deprecated // Use "this.rethrowKeyword"
  set keyword(Token token) {
    rethrowKeyword = token;
  }

  @override
  int get precedence => 0;

  @override
  accept(AstVisitor visitor) => visitor.visitRethrowExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/**
 * A return statement.
 *
 * > returnStatement ::=
 * >     'return' [Expression]? ';'
 */
class ReturnStatement extends Statement {
  /**
   * The token representing the 'return' keyword.
   */
  Token returnKeyword;

  /**
   * The expression computing the value to be returned, or `null` if no explicit
   * value was provided.
   */
  Expression _expression;

  /**
   * The semicolon terminating the statement.
   */
  Token semicolon;

  /**
   * Initialize a newly created return statement. The [expression] can be `null`
   * if no explicit value was provided.
   */
  ReturnStatement(this.returnKeyword, Expression expression, this.semicolon) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Token get beginToken => returnKeyword;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(returnKeyword)
    ..add(_expression)
    ..add(semicolon);

  @override
  Token get endToken => semicolon;

  /**
   * Return the expression computing the value to be returned, or `null` if no
   * explicit value was provided.
   */
  Expression get expression => _expression;

  /**
   * Set the expression computing the value to be returned to the given
   * [expression].
   */
  void set expression(Expression expression) {
    _expression = _becomeParentOf(expression);
  }

  /**
   * Return the token representing the 'return' keyword.
   */
  @deprecated // Use "this.returnKeyword"
  Token get keyword => returnKeyword;

  /**
   * Set the token representing the 'return' keyword to the given [token].
   */
  @deprecated // Use "this.returnKeyword"
  set keyword(Token token) {
    returnKeyword = token;
  }

  @override
  accept(AstVisitor visitor) => visitor.visitReturnStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_expression, visitor);
  }
}

/**
 * Traverse the AST from initial child node to successive parents, building a
 * collection of local variable and parameter names visible to the initial child
 * node. In case of name shadowing, the first name seen is the most specific one
 * so names are not redefined.
 *
 * Completion test code coverage is 95%. The two basic blocks that are not
 * executed cannot be executed. They are included for future reference.
 */
class ScopedNameFinder extends GeneralizingAstVisitor<Object> {
  Declaration _declarationNode;

  AstNode _immediateChild;

  Map<String, SimpleIdentifier> _locals =
      new HashMap<String, SimpleIdentifier>();

  final int _position;

  bool _referenceIsWithinLocalFunction = false;

  ScopedNameFinder(this._position);

  Declaration get declaration => _declarationNode;

  Map<String, SimpleIdentifier> get locals => _locals;

  @override
  Object visitBlock(Block node) {
    _checkStatements(node.statements);
    return super.visitBlock(node);
  }

  @override
  Object visitCatchClause(CatchClause node) {
    _addToScope(node.exceptionParameter);
    _addToScope(node.stackTraceParameter);
    return super.visitCatchClause(node);
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    if (!identical(_immediateChild, node.parameters)) {
      _addParameters(node.parameters.parameters);
    }
    _declarationNode = node;
    return null;
  }

  @override
  Object visitFieldDeclaration(FieldDeclaration node) {
    _declarationNode = node;
    return null;
  }

  @override
  Object visitForEachStatement(ForEachStatement node) {
    DeclaredIdentifier loopVariable = node.loopVariable;
    if (loopVariable != null) {
      _addToScope(loopVariable.identifier);
    }
    return super.visitForEachStatement(node);
  }

  @override
  Object visitForStatement(ForStatement node) {
    if (!identical(_immediateChild, node.variables) && node.variables != null) {
      _addVariables(node.variables.variables);
    }
    return super.visitForStatement(node);
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is! FunctionDeclarationStatement) {
      _declarationNode = node;
      return null;
    }
    return super.visitFunctionDeclaration(node);
  }

  @override
  Object visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    _referenceIsWithinLocalFunction = true;
    return super.visitFunctionDeclarationStatement(node);
  }

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    if (node.parameters != null &&
        !identical(_immediateChild, node.parameters)) {
      _addParameters(node.parameters.parameters);
    }
    return super.visitFunctionExpression(node);
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    _declarationNode = node;
    if (node.parameters == null) {
      return null;
    }
    if (!identical(_immediateChild, node.parameters)) {
      _addParameters(node.parameters.parameters);
    }
    return null;
  }

  @override
  Object visitNode(AstNode node) {
    _immediateChild = node;
    AstNode parent = node.parent;
    if (parent != null) {
      parent.accept(this);
    }
    return null;
  }

  @override
  Object visitSwitchMember(SwitchMember node) {
    _checkStatements(node.statements);
    return super.visitSwitchMember(node);
  }

  @override
  Object visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _declarationNode = node;
    return null;
  }

  @override
  Object visitTypeAlias(TypeAlias node) {
    _declarationNode = node;
    return null;
  }

  void _addParameters(NodeList<FormalParameter> vars) {
    for (FormalParameter var2 in vars) {
      _addToScope(var2.identifier);
    }
  }

  void _addToScope(SimpleIdentifier identifier) {
    if (identifier != null && _isInRange(identifier)) {
      String name = identifier.name;
      if (!_locals.containsKey(name)) {
        _locals[name] = identifier;
      }
    }
  }

  void _addVariables(NodeList<VariableDeclaration> variables) {
    for (VariableDeclaration variable in variables) {
      _addToScope(variable.name);
    }
  }

  /**
   * Check the given list of [statements] for any that come before the immediate
   * child and that define a name that would be visible to the immediate child.
   */
  void _checkStatements(List<Statement> statements) {
    for (Statement statement in statements) {
      if (identical(statement, _immediateChild)) {
        return;
      }
      if (statement is VariableDeclarationStatement) {
        _addVariables(statement.variables.variables);
      } else if (statement is FunctionDeclarationStatement &&
          !_referenceIsWithinLocalFunction) {
        _addToScope(statement.functionDeclaration.name);
      }
    }
  }

  bool _isInRange(AstNode node) {
    if (_position < 0) {
      // if source position is not set then all nodes are in range
      return true;
      // not reached
    }
    return node.end < _position;
  }
}

/**
 * A script tag that can optionally occur at the beginning of a compilation unit.
 *
 * > scriptTag ::=
 * >     '#!' (~NEWLINE)* NEWLINE
 */
class ScriptTag extends AstNode {
  /**
   * The token representing this script tag.
   */
  Token scriptTag;

  /**
   * Initialize a newly created script tag.
   */
  ScriptTag(this.scriptTag);

  @override
  Token get beginToken => scriptTag;

  @override
  Iterable get childEntities => new ChildEntities()..add(scriptTag);

  @override
  Token get endToken => scriptTag;

  @override
  accept(AstVisitor visitor) => visitor.visitScriptTag(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/**
 * A combinator that restricts the names being imported to those in a given list.
 *
 * > showCombinator ::=
 * >     'show' [SimpleIdentifier] (',' [SimpleIdentifier])*
 */
class ShowCombinator extends Combinator {
  /**
   * The list of names from the library that are made visible by this combinator.
   */
  NodeList<SimpleIdentifier> _shownNames;

  /**
   * Initialize a newly created import show combinator.
   */
  ShowCombinator(Token keyword, List<SimpleIdentifier> shownNames)
      : super(keyword) {
    _shownNames = new NodeList<SimpleIdentifier>(this, shownNames);
  }

  /**
   * TODO(paulberry): add commas.
   */
  @override
  Iterable get childEntities => new ChildEntities()
    ..add(keyword)
    ..addAll(_shownNames);

  @override
  Token get endToken => _shownNames.endToken;

  /**
   * Return the list of names from the library that are made visible by this
   * combinator.
   */
  NodeList<SimpleIdentifier> get shownNames => _shownNames;

  @override
  accept(AstVisitor visitor) => visitor.visitShowCombinator(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _shownNames.accept(visitor);
  }
}

/**
 * An AST visitor that will do nothing when visiting an AST node. It is intended
 * to be a superclass for classes that use the visitor pattern primarily as a
 * dispatch mechanism (and hence don't need to recursively visit a whole
 * structure) and that only need to visit a small number of node types.
 */
class SimpleAstVisitor<R> implements AstVisitor<R> {
  @override
  R visitAdjacentStrings(AdjacentStrings node) => null;

  @override
  R visitAnnotation(Annotation node) => null;

  @override
  R visitArgumentList(ArgumentList node) => null;

  @override
  R visitAsExpression(AsExpression node) => null;

  @override
  R visitAssertStatement(AssertStatement node) => null;

  @override
  R visitAssignmentExpression(AssignmentExpression node) => null;

  @override
  R visitAwaitExpression(AwaitExpression node) => null;

  @override
  R visitBinaryExpression(BinaryExpression node) => null;

  @override
  R visitBlock(Block node) => null;

  @override
  R visitBlockFunctionBody(BlockFunctionBody node) => null;

  @override
  R visitBooleanLiteral(BooleanLiteral node) => null;

  @override
  R visitBreakStatement(BreakStatement node) => null;

  @override
  R visitCascadeExpression(CascadeExpression node) => null;

  @override
  R visitCatchClause(CatchClause node) => null;

  @override
  R visitClassDeclaration(ClassDeclaration node) => null;

  @override
  R visitClassTypeAlias(ClassTypeAlias node) => null;

  @override
  R visitComment(Comment node) => null;

  @override
  R visitCommentReference(CommentReference node) => null;

  @override
  R visitCompilationUnit(CompilationUnit node) => null;

  @override
  R visitConditionalExpression(ConditionalExpression node) => null;

  @override
  R visitConstructorDeclaration(ConstructorDeclaration node) => null;

  @override
  R visitConstructorFieldInitializer(ConstructorFieldInitializer node) => null;

  @override
  R visitConstructorName(ConstructorName node) => null;

  @override
  R visitContinueStatement(ContinueStatement node) => null;

  @override
  R visitDeclaredIdentifier(DeclaredIdentifier node) => null;

  @override
  R visitDefaultFormalParameter(DefaultFormalParameter node) => null;

  @override
  R visitDoStatement(DoStatement node) => null;

  @override
  R visitDoubleLiteral(DoubleLiteral node) => null;

  @override
  R visitEmptyFunctionBody(EmptyFunctionBody node) => null;

  @override
  R visitEmptyStatement(EmptyStatement node) => null;

  @override
  R visitEnumConstantDeclaration(EnumConstantDeclaration node) => null;

  @override
  R visitEnumDeclaration(EnumDeclaration node) => null;

  @override
  R visitExportDirective(ExportDirective node) => null;

  @override
  R visitExpressionFunctionBody(ExpressionFunctionBody node) => null;

  @override
  R visitExpressionStatement(ExpressionStatement node) => null;

  @override
  R visitExtendsClause(ExtendsClause node) => null;

  @override
  R visitFieldDeclaration(FieldDeclaration node) => null;

  @override
  R visitFieldFormalParameter(FieldFormalParameter node) => null;

  @override
  R visitForEachStatement(ForEachStatement node) => null;

  @override
  R visitFormalParameterList(FormalParameterList node) => null;

  @override
  R visitForStatement(ForStatement node) => null;

  @override
  R visitFunctionDeclaration(FunctionDeclaration node) => null;

  @override
  R visitFunctionDeclarationStatement(FunctionDeclarationStatement node) =>
      null;

  @override
  R visitFunctionExpression(FunctionExpression node) => null;

  @override
  R visitFunctionExpressionInvocation(FunctionExpressionInvocation node) =>
      null;

  @override
  R visitFunctionTypeAlias(FunctionTypeAlias node) => null;

  @override
  R visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) =>
      null;

  @override
  R visitHideCombinator(HideCombinator node) => null;

  @override
  R visitIfStatement(IfStatement node) => null;

  @override
  R visitImplementsClause(ImplementsClause node) => null;

  @override
  R visitImportDirective(ImportDirective node) => null;

  @override
  R visitIndexExpression(IndexExpression node) => null;

  @override
  R visitInstanceCreationExpression(InstanceCreationExpression node) => null;

  @override
  R visitIntegerLiteral(IntegerLiteral node) => null;

  @override
  R visitInterpolationExpression(InterpolationExpression node) => null;

  @override
  R visitInterpolationString(InterpolationString node) => null;

  @override
  R visitIsExpression(IsExpression node) => null;

  @override
  R visitLabel(Label node) => null;

  @override
  R visitLabeledStatement(LabeledStatement node) => null;

  @override
  R visitLibraryDirective(LibraryDirective node) => null;

  @override
  R visitLibraryIdentifier(LibraryIdentifier node) => null;

  @override
  R visitListLiteral(ListLiteral node) => null;

  @override
  R visitMapLiteral(MapLiteral node) => null;

  @override
  R visitMapLiteralEntry(MapLiteralEntry node) => null;

  @override
  R visitMethodDeclaration(MethodDeclaration node) => null;

  @override
  R visitMethodInvocation(MethodInvocation node) => null;

  @override
  R visitNamedExpression(NamedExpression node) => null;

  @override
  R visitNativeClause(NativeClause node) => null;

  @override
  R visitNativeFunctionBody(NativeFunctionBody node) => null;

  @override
  R visitNullLiteral(NullLiteral node) => null;

  @override
  R visitParenthesizedExpression(ParenthesizedExpression node) => null;

  @override
  R visitPartDirective(PartDirective node) => null;

  @override
  R visitPartOfDirective(PartOfDirective node) => null;

  @override
  R visitPostfixExpression(PostfixExpression node) => null;

  @override
  R visitPrefixedIdentifier(PrefixedIdentifier node) => null;

  @override
  R visitPrefixExpression(PrefixExpression node) => null;

  @override
  R visitPropertyAccess(PropertyAccess node) => null;

  @override
  R visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) => null;

  @override
  R visitRethrowExpression(RethrowExpression node) => null;

  @override
  R visitReturnStatement(ReturnStatement node) => null;

  @override
  R visitScriptTag(ScriptTag node) => null;

  @override
  R visitShowCombinator(ShowCombinator node) => null;

  @override
  R visitSimpleFormalParameter(SimpleFormalParameter node) => null;

  @override
  R visitSimpleIdentifier(SimpleIdentifier node) => null;

  @override
  R visitSimpleStringLiteral(SimpleStringLiteral node) => null;

  @override
  R visitStringInterpolation(StringInterpolation node) => null;

  @override
  R visitSuperConstructorInvocation(SuperConstructorInvocation node) => null;

  @override
  R visitSuperExpression(SuperExpression node) => null;

  @override
  R visitSwitchCase(SwitchCase node) => null;

  @override
  R visitSwitchDefault(SwitchDefault node) => null;

  @override
  R visitSwitchStatement(SwitchStatement node) => null;

  @override
  R visitSymbolLiteral(SymbolLiteral node) => null;

  @override
  R visitThisExpression(ThisExpression node) => null;

  @override
  R visitThrowExpression(ThrowExpression node) => null;

  @override
  R visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) => null;

  @override
  R visitTryStatement(TryStatement node) => null;

  @override
  R visitTypeArgumentList(TypeArgumentList node) => null;

  @override
  R visitTypeName(TypeName node) => null;

  @override
  R visitTypeParameter(TypeParameter node) => null;

  @override
  R visitTypeParameterList(TypeParameterList node) => null;

  @override
  R visitVariableDeclaration(VariableDeclaration node) => null;

  @override
  R visitVariableDeclarationList(VariableDeclarationList node) => null;

  @override
  R visitVariableDeclarationStatement(VariableDeclarationStatement node) =>
      null;

  @override
  R visitWhileStatement(WhileStatement node) => null;

  @override
  R visitWithClause(WithClause node) => null;

  @override
  R visitYieldStatement(YieldStatement node) => null;
}

/**
 * A simple formal parameter.
 *
 * > simpleFormalParameter ::=
 * >     ('final' [TypeName] | 'var' | [TypeName])? [SimpleIdentifier]
 */
class SimpleFormalParameter extends NormalFormalParameter {
  /**
   * The token representing either the 'final', 'const' or 'var' keyword, or
   * `null` if no keyword was used.
   */
  Token keyword;

  /**
   * The name of the declared type of the parameter, or `null` if the parameter
   * does not have a declared type.
   */
  TypeName _type;

  /**
   * Initialize a newly created formal parameter. Either or both of the
   * [comment] and [metadata] can be `null` if the parameter does not have the
   * corresponding attribute. The [keyword] can be `null` if a type was
   * specified. The [type] must be `null` if the keyword is 'var'.
   */
  SimpleFormalParameter(Comment comment, List<Annotation> metadata,
      this.keyword, TypeName type, SimpleIdentifier identifier)
      : super(comment, metadata, identifier) {
    _type = _becomeParentOf(type);
  }

  @override
  Token get beginToken {
    NodeList<Annotation> metadata = this.metadata;
    if (!metadata.isEmpty) {
      return metadata.beginToken;
    } else if (keyword != null) {
      return keyword;
    } else if (_type != null) {
      return _type.beginToken;
    }
    return identifier.beginToken;
  }

  @override
  Iterable get childEntities => super._childEntities
    ..add(keyword)
    ..add(_type)
    ..add(identifier);

  @override
  Token get endToken => identifier.endToken;

  @override
  bool get isConst => (keyword is KeywordToken) &&
      (keyword as KeywordToken).keyword == Keyword.CONST;

  @override
  bool get isFinal => (keyword is KeywordToken) &&
      (keyword as KeywordToken).keyword == Keyword.FINAL;

  /**
   * Return the name of the declared type of the parameter, or `null` if the
   * parameter does not have a declared type.
   */
  TypeName get type => _type;

  /**
   * Set the name of the declared type of the parameter to the given [typeName].
   */
  void set type(TypeName typeName) {
    _type = _becomeParentOf(typeName);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitSimpleFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_type, visitor);
    _safelyVisitChild(identifier, visitor);
  }
}

/**
 * A simple identifier.
 *
 * > simpleIdentifier ::=
 * >     initialCharacter internalCharacter*
 * >
 * > initialCharacter ::= '_' | '$' | letter
 * >
 * > internalCharacter ::= '_' | '$' | letter | digit
 */
class SimpleIdentifier extends Identifier {
  /**
   * The token representing the identifier.
   */
  Token token;

  /**
   * The element associated with this identifier based on static type
   * information, or `null` if the AST structure has not been resolved or if
   * this identifier could not be resolved.
   */
  Element _staticElement;

  /**
   * The element associated with this identifier based on propagated type
   * information, or `null` if the AST structure has not been resolved or if
   * this identifier could not be resolved.
   */
  Element _propagatedElement;

  /**
   * If this expression is both in a getter and setter context, the
   * [AuxiliaryElements] will be set to hold onto the static and propagated
   * information. The auxiliary element will hold onto the elements from the
   * getter context.
   */
  AuxiliaryElements auxiliaryElements = null;

  /**
   * Initialize a newly created identifier.
   */
  SimpleIdentifier(this.token);

  @override
  Token get beginToken => token;

  @override
  Element get bestElement {
    if (_propagatedElement == null) {
      return _staticElement;
    }
    return _propagatedElement;
  }

  @override
  Iterable get childEntities => new ChildEntities()..add(token);

  @override
  Token get endToken => token;

  /**
   * Returns `true` if this identifier is the "name" part of a prefixed
   * identifier or a method invocation.
   */
  bool get isQualified {
    AstNode parent = this.parent;
    if (parent is PrefixedIdentifier) {
      return identical(parent.identifier, this);
    }
    if (parent is PropertyAccess) {
      return identical(parent.propertyName, this);
    }
    if (parent is MethodInvocation) {
      MethodInvocation invocation = parent;
      return identical(invocation.methodName, this) &&
          invocation.realTarget != null;
    }
    return false;
  }

  @override
  bool get isSynthetic => token.isSynthetic;

  @override
  String get name => token.lexeme;

  @override
  int get precedence => 16;

  @override
  Element get propagatedElement => _propagatedElement;

  /**
   * Set the element associated with this identifier based on propagated type
   * information to the given [element].
   */
  void set propagatedElement(Element element) {
    _propagatedElement = _validateElement(element);
  }

  @override
  Element get staticElement => _staticElement;

  /**
   * Set the element associated with this identifier based on static type
   * information to the given [element].
   */
  void set staticElement(Element element) {
    _staticElement = _validateElement(element);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitSimpleIdentifier(this);

  /**
   * Return `true` if this identifier is the name being declared in a
   * declaration.
   */
  bool inDeclarationContext() {
    // TODO(brianwilkerson) Convert this to a getter.
    AstNode parent = this.parent;
    if (parent is CatchClause) {
      CatchClause clause = parent;
      return identical(this, clause.exceptionParameter) ||
          identical(this, clause.stackTraceParameter);
    } else if (parent is ClassDeclaration) {
      return identical(this, parent.name);
    } else if (parent is ClassTypeAlias) {
      return identical(this, parent.name);
    } else if (parent is ConstructorDeclaration) {
      return identical(this, parent.name);
    } else if (parent is DeclaredIdentifier) {
      return identical(this, parent.identifier);
    } else if (parent is EnumDeclaration) {
      return identical(this, parent.name);
    } else if (parent is EnumConstantDeclaration) {
      return identical(this, parent.name);
    } else if (parent is FunctionDeclaration) {
      return identical(this, parent.name);
    } else if (parent is FunctionTypeAlias) {
      return identical(this, parent.name);
    } else if (parent is ImportDirective) {
      return identical(this, parent.prefix);
    } else if (parent is Label) {
      return identical(this, parent.label) &&
          (parent.parent is LabeledStatement);
    } else if (parent is MethodDeclaration) {
      return identical(this, parent.name);
    } else if (parent is FunctionTypedFormalParameter ||
        parent is SimpleFormalParameter) {
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
   * Note that [inGetterContext] and [inSetterContext] are not opposites, nor
   * are they mutually exclusive. In other words, it is possible for both
   * methods to return `true` when invoked on the same node.
   */
  bool inGetterContext() {
    // TODO(brianwilkerson) Convert this to a getter.
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
      if (identical(parent.leftHandSide, target) &&
          parent.operator.type == TokenType.EQ) {
        return false;
      }
    }
    if (parent is ForEachStatement) {
      if (identical(parent.identifier, target)) {
        return false;
      }
    }
    return true;
  }

  /**
   * Return `true` if this expression is computing a left-hand value.
   *
   * Note that [inGetterContext] and [inSetterContext] are not opposites, nor
   * are they mutually exclusive. In other words, it is possible for both
   * methods to return `true` when invoked on the same node.
   */
  bool inSetterContext() {
    // TODO(brianwilkerson) Convert this to a getter.
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
      return parent.operator.type.isIncrementOperator;
    } else if (parent is PostfixExpression) {
      return true;
    } else if (parent is AssignmentExpression) {
      return identical(parent.leftHandSide, target);
    } else if (parent is ForEachStatement) {
      return identical(parent.identifier, target);
    }
    return false;
  }

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }

  /**
   * Return the given element if it is valid, or report the problem and return
   * `null` if it is not appropriate.
   *
   * The [parent] is the parent of the element, used for reporting when there is
   * a problem.
   * The [isValid] is `true` if the element is appropriate.
   * The [element] is the element to be associated with this identifier.
   */
  Element _returnOrReportElement(
      AstNode parent, bool isValid, Element element) {
    if (!isValid) {
      AnalysisEngine.instance.logger.logInformation(
          "Internal error: attempting to set the name of a ${parent.runtimeType} to a ${element.runtimeType}",
          new CaughtException(new AnalysisException(), null));
      return null;
    }
    return element;
  }

  /**
   * Return the given [element] if it is an appropriate element based on the
   * parent of this identifier, or `null` if it is not appropriate.
   */
  Element _validateElement(Element element) {
    if (element == null) {
      return null;
    }
    AstNode parent = this.parent;
    if (parent is ClassDeclaration && identical(parent.name, this)) {
      return _returnOrReportElement(parent, element is ClassElement, element);
    } else if (parent is ClassTypeAlias && identical(parent.name, this)) {
      return _returnOrReportElement(parent, element is ClassElement, element);
    } else if (parent is DeclaredIdentifier &&
        identical(parent.identifier, this)) {
      return _returnOrReportElement(
          parent, element is LocalVariableElement, element);
    } else if (parent is FormalParameter &&
        identical(parent.identifier, this)) {
      return _returnOrReportElement(
          parent, element is ParameterElement, element);
    } else if (parent is FunctionDeclaration && identical(parent.name, this)) {
      return _returnOrReportElement(
          parent, element is ExecutableElement, element);
    } else if (parent is FunctionTypeAlias && identical(parent.name, this)) {
      return _returnOrReportElement(
          parent, element is FunctionTypeAliasElement, element);
    } else if (parent is MethodDeclaration && identical(parent.name, this)) {
      return _returnOrReportElement(
          parent, element is ExecutableElement, element);
    } else if (parent is TypeParameter && identical(parent.name, this)) {
      return _returnOrReportElement(
          parent, element is TypeParameterElement, element);
    } else if (parent is VariableDeclaration && identical(parent.name, this)) {
      return _returnOrReportElement(
          parent, element is VariableElement, element);
    }
    return element;
  }
}

/**
 * A string literal expression that does not contain any interpolations.
 *
 * > simpleStringLiteral ::=
 * >     rawStringLiteral
 * >   | basicStringLiteral
 * >
 * > rawStringLiteral ::=
 * >     'r' basicStringLiteral
 * >
 * > simpleStringLiteral ::=
 * >     multiLineStringLiteral
 * >   | singleLineStringLiteral
 * >
 * > multiLineStringLiteral ::=
 * >     "'''" characters "'''"
 * >   | '"""' characters '"""'
 * >
 * > singleLineStringLiteral ::=
 * >     "'" characters "'"
 * >   | '"' characters '"'
 */
class SimpleStringLiteral extends SingleStringLiteral {
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
  @deprecated // No replacement
  Element toolkitElement;

  /**
   * Initialize a newly created simple string literal.
   */
  SimpleStringLiteral(this.literal, String value) {
    _value = StringUtilities.intern(value);
  }

  @override
  Token get beginToken => literal;

  @override
  Iterable get childEntities => new ChildEntities()..add(literal);

  @override
  int get contentsEnd => offset + _helper.end;

  @override
  int get contentsOffset => offset + _helper.start;

  @override
  Token get endToken => literal;

  @override
  bool get isMultiline => _helper.isMultiline;

  @override
  bool get isRaw => _helper.isRaw;

  @override
  bool get isSingleQuoted => _helper.isSingleQuoted;

  @override
  bool get isSynthetic => literal.isSynthetic;

  /**
   * Return the value of the literal.
   */
  String get value => _value;

  /**
   * Set the value of the literal to the given [string].
   */
  void set value(String string) {
    _value = StringUtilities.intern(_value);
  }

  StringLexemeHelper get _helper {
    return new StringLexemeHelper(literal.lexeme, true, true);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitSimpleStringLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }

  @override
  void _appendStringValue(StringBuffer buffer) {
    buffer.write(value);
  }
}

/**
 * A single string literal expression.
 *
 * > singleStringLiteral ::=
 * >     [SimpleStringLiteral]
 * >   | [StringInterpolation]
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
   * Return `true` if this string literal uses single qoutes (' or ''').
   * Return `false` if this string literal uses double qoutes (" or """).
   */
  bool get isSingleQuoted;
}

/**
 * A node that represents a statement.
 *
 * > statement ::=
 * >     [Block]
 * >   | [VariableDeclarationStatement]
 * >   | [ForStatement]
 * >   | [ForEachStatement]
 * >   | [WhileStatement]
 * >   | [DoStatement]
 * >   | [SwitchStatement]
 * >   | [IfStatement]
 * >   | [TryStatement]
 * >   | [BreakStatement]
 * >   | [ContinueStatement]
 * >   | [ReturnStatement]
 * >   | [ExpressionStatement]
 * >   | [FunctionDeclarationStatement]
 */
abstract class Statement extends AstNode {
  /**
   * If this is a labeled statement, return the unlabeled portion of the
   * statement.  Otherwise return the statement itself.
   */
  Statement get unlabeled => this;
}

/**
 * A string interpolation literal.
 *
 * > stringInterpolation ::=
 * >     ''' [InterpolationElement]* '''
 * >   | '"' [InterpolationElement]* '"'
 */
class StringInterpolation extends SingleStringLiteral {
  /**
   * The elements that will be composed to produce the resulting string.
   */
  NodeList<InterpolationElement> _elements;

  /**
   * Initialize a newly created string interpolation expression.
   */
  StringInterpolation(List<InterpolationElement> elements) {
    _elements = new NodeList<InterpolationElement>(this, elements);
  }

  @override
  Token get beginToken => _elements.beginToken;

  @override
  Iterable get childEntities => new ChildEntities()..addAll(_elements);

  @override
  int get contentsEnd {
    InterpolationString element = _elements.last;
    return element.contentsEnd;
  }

  @override
  int get contentsOffset {
    InterpolationString element = _elements.first;
    return element.contentsOffset;
  }

  /**
   * Return the elements that will be composed to produce the resulting string.
   */
  NodeList<InterpolationElement> get elements => _elements;

  @override
  Token get endToken => _elements.endToken;

  @override
  bool get isMultiline => _firstHelper.isMultiline;

  @override
  bool get isRaw => false;

  @override
  bool get isSingleQuoted => _firstHelper.isSingleQuoted;

  StringLexemeHelper get _firstHelper {
    InterpolationString lastString = _elements.first;
    String lexeme = lastString.contents.lexeme;
    return new StringLexemeHelper(lexeme, true, false);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitStringInterpolation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _elements.accept(visitor);
  }

  @override
  void _appendStringValue(StringBuffer buffer) {
    throw new IllegalArgumentException();
  }
}

/**
 * A helper for analyzing string lexemes.
 */
class StringLexemeHelper {
  final String lexeme;
  final bool isFirst;
  final bool isLast;

  bool isRaw = false;
  bool isSingleQuoted = false;
  bool isMultiline = false;
  int start = 0;
  int end;

  StringLexemeHelper(this.lexeme, this.isFirst, this.isLast) {
    if (isFirst) {
      isRaw = StringUtilities.startsWithChar(lexeme, 0x72);
      if (isRaw) {
        start++;
      }
      if (StringUtilities.startsWith3(lexeme, start, 0x27, 0x27, 0x27)) {
        isSingleQuoted = true;
        isMultiline = true;
        start += 3;
        start = _trimInitialWhitespace(start);
      } else if (StringUtilities.startsWith3(lexeme, start, 0x22, 0x22, 0x22)) {
        isSingleQuoted = false;
        isMultiline = true;
        start += 3;
        start = _trimInitialWhitespace(start);
      } else if (start < lexeme.length && lexeme.codeUnitAt(start) == 0x27) {
        isSingleQuoted = true;
        isMultiline = false;
        start++;
      } else if (start < lexeme.length && lexeme.codeUnitAt(start) == 0x22) {
        isSingleQuoted = false;
        isMultiline = false;
        start++;
      }
    }
    end = lexeme.length;
    if (isLast) {
      if (start + 3 <= end &&
          (StringUtilities.endsWith3(lexeme, 0x22, 0x22, 0x22) ||
              StringUtilities.endsWith3(lexeme, 0x27, 0x27, 0x27))) {
        end -= 3;
      } else if (start + 1 <= end &&
          (StringUtilities.endsWithChar(lexeme, 0x22) ||
              StringUtilities.endsWithChar(lexeme, 0x27))) {
        end -= 1;
      }
    }
  }

  /**
   * Given the [lexeme] for a multi-line string whose content begins at the
   * given [start] index, return the index of the first character that is
   * included in the value of the string. According to the specification:
   *
   * If the first line of a multiline string consists solely of the whitespace
   * characters defined by the production WHITESPACE 20.1), possibly prefixed
   * by \, then that line is ignored, including the new line at its end.
   */
  int _trimInitialWhitespace(int start) {
    int length = lexeme.length;
    int index = start;
    while (index < length) {
      int currentChar = lexeme.codeUnitAt(index);
      if (currentChar == 0x0D) {
        if (index + 1 < length && lexeme.codeUnitAt(index + 1) == 0x0A) {
          return index + 2;
        }
        return index + 1;
      } else if (currentChar == 0x0A) {
        return index + 1;
      } else if (currentChar == 0x5C) {
        if (index + 1 >= length) {
          return start;
        }
        currentChar = lexeme.codeUnitAt(index + 1);
        if (currentChar != 0x0D &&
            currentChar != 0x0A &&
            currentChar != 0x09 &&
            currentChar != 0x20) {
          return start;
        }
      } else if (currentChar != 0x09 && currentChar != 0x20) {
        return start;
      }
      index++;
    }
    return start;
  }
}

/**
 * A string literal expression.
 *
 * > stringLiteral ::=
 * >     [SimpleStringLiteral]
 * >   | [AdjacentStrings]
 * >   | [StringInterpolation]
 */
abstract class StringLiteral extends Literal {
  /**
   * Return the value of the string literal, or `null` if the string is not a
   * constant string without any string interpolation.
   */
  String get stringValue {
    StringBuffer buffer = new StringBuffer();
    try {
      _appendStringValue(buffer);
    } on IllegalArgumentException {
      return null;
    }
    return buffer.toString();
  }

  /**
   * Append the value of this string literal to the given [buffer]. Throw an
   * [IllegalArgumentException] if the string is not a constant string without
   * any string interpolation.
   */
  @deprecated // Use "this.stringValue"
  void appendStringValue(StringBuffer buffer) => _appendStringValue(buffer);

  /**
   * Append the value of this string literal to the given [buffer]. Throw an
   * [IllegalArgumentException] if the string is not a constant string without
   * any string interpolation.
   */
  void _appendStringValue(StringBuffer buffer);
}

/**
 * The invocation of a superclass' constructor from within a constructor's
 * initialization list.
 *
 * > superInvocation ::=
 * >     'super' ('.' [SimpleIdentifier])? [ArgumentList]
 */
class SuperConstructorInvocation extends ConstructorInitializer {
  /**
   * The token for the 'super' keyword.
   */
  Token superKeyword;

  /**
   * The token for the period before the name of the constructor that is being
   * invoked, or `null` if the unnamed constructor is being invoked.
   */
  Token period;

  /**
   * The name of the constructor that is being invoked, or `null` if the unnamed
   * constructor is being invoked.
   */
  SimpleIdentifier _constructorName;

  /**
   * The list of arguments to the constructor.
   */
  ArgumentList _argumentList;

  /**
   * The element associated with the constructor based on static type
   * information, or `null` if the AST structure has not been resolved or if the
   * constructor could not be resolved.
   */
  ConstructorElement staticElement;

  /**
   * Initialize a newly created super invocation to invoke the inherited
   * constructor with the given name with the given arguments. The [period] and
   * [constructorName] can be `null` if the constructor being invoked is the
   * unnamed constructor.
   */
  SuperConstructorInvocation(this.superKeyword, this.period,
      SimpleIdentifier constructorName, ArgumentList argumentList) {
    _constructorName = _becomeParentOf(constructorName);
    _argumentList = _becomeParentOf(argumentList);
  }

  /**
   * Return the list of arguments to the constructor.
   */
  ArgumentList get argumentList => _argumentList;

  /**
   * Set the list of arguments to the constructor to the given [argumentList].
   */
  void set argumentList(ArgumentList argumentList) {
    _argumentList = _becomeParentOf(argumentList);
  }

  @override
  Token get beginToken => superKeyword;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(superKeyword)
    ..add(period)
    ..add(_constructorName)
    ..add(_argumentList);

  /**
   * Return the name of the constructor that is being invoked, or `null` if the
   * unnamed constructor is being invoked.
   */
  SimpleIdentifier get constructorName => _constructorName;

  /**
   * Set the name of the constructor that is being invoked to the given
   * [identifier].
   */
  void set constructorName(SimpleIdentifier identifier) {
    _constructorName = _becomeParentOf(identifier);
  }

  @override
  Token get endToken => _argumentList.endToken;

  /**
   * Return the token for the 'super' keyword.
   */
  @deprecated // Use "this.superKeyword"
  Token get keyword => superKeyword;

  /**
   * Set the token for the 'super' keyword to the given [token].
   */
  @deprecated // Use "this.superKeyword"
  set keyword(Token token) {
    superKeyword = token;
  }

  @override
  accept(AstVisitor visitor) => visitor.visitSuperConstructorInvocation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_constructorName, visitor);
    _safelyVisitChild(_argumentList, visitor);
  }
}

/**
 * A super expression.
 *
 * > superExpression ::=
 * >     'super'
 */
class SuperExpression extends Expression {
  /**
   * The token representing the 'super' keyword.
   */
  Token superKeyword;

  /**
   * Initialize a newly created super expression.
   */
  SuperExpression(this.superKeyword);

  @override
  Token get beginToken => superKeyword;

  @override
  Iterable get childEntities => new ChildEntities()..add(superKeyword);

  @override
  Token get endToken => superKeyword;

  /**
   * Return the token for the 'super' keyword.
   */
  @deprecated // Use "this.superKeyword"
  Token get keyword => superKeyword;

  /**
   * Set the token for the 'super' keyword to the given [token].
   */
  @deprecated // Use "this.superKeyword"
  set keyword(Token token) {
    superKeyword = token;
  }

  @override
  int get precedence => 16;

  @override
  accept(AstVisitor visitor) => visitor.visitSuperExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/**
 * A case in a switch statement.
 *
 * > switchCase ::=
 * >     [SimpleIdentifier]* 'case' [Expression] ':' [Statement]*
 */
class SwitchCase extends SwitchMember {
  /**
   * The expression controlling whether the statements will be executed.
   */
  Expression _expression;

  /**
   * Initialize a newly created switch case. The list of [labels] can be `null`
   * if there are no labels.
   */
  SwitchCase(List<Label> labels, Token keyword, Expression expression,
      Token colon, List<Statement> statements)
      : super(labels, keyword, colon, statements) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..addAll(labels)
    ..add(keyword)
    ..add(_expression)
    ..add(colon)
    ..addAll(statements);

  /**
   * Return the expression controlling whether the statements will be executed.
   */
  Expression get expression => _expression;

  /**
   * Set the expression controlling whether the statements will be executed to
   * the given [expression].
   */
  void set expression(Expression expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitSwitchCase(this);

  @override
  void visitChildren(AstVisitor visitor) {
    labels.accept(visitor);
    _safelyVisitChild(_expression, visitor);
    statements.accept(visitor);
  }
}

/**
 * The default case in a switch statement.
 *
 * > switchDefault ::=
 * >     [SimpleIdentifier]* 'default' ':' [Statement]*
 */
class SwitchDefault extends SwitchMember {
  /**
   * Initialize a newly created switch default. The list of [labels] can be
   * `null` if there are no labels.
   */
  SwitchDefault(List<Label> labels, Token keyword, Token colon,
      List<Statement> statements)
      : super(labels, keyword, colon, statements);

  @override
  Iterable get childEntities => new ChildEntities()
    ..addAll(labels)
    ..add(keyword)
    ..add(colon)
    ..addAll(statements);

  @override
  accept(AstVisitor visitor) => visitor.visitSwitchDefault(this);

  @override
  void visitChildren(AstVisitor visitor) {
    labels.accept(visitor);
    statements.accept(visitor);
  }
}

/**
 * An element within a switch statement.
 *
 * > switchMember ::=
 * >     switchCase
 * >   | switchDefault
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
   * Initialize a newly created switch member. The list of [labels] can be
   * `null` if there are no labels.
   */
  SwitchMember(List<Label> labels, this.keyword, this.colon,
      List<Statement> statements) {
    _labels = new NodeList<Label>(this, labels);
    _statements = new NodeList<Statement>(this, statements);
  }

  @override
  Token get beginToken {
    if (!_labels.isEmpty) {
      return _labels.beginToken;
    }
    return keyword;
  }

  @override
  Token get endToken {
    if (!_statements.isEmpty) {
      return _statements.endToken;
    }
    return colon;
  }

  /**
   * Return the labels associated with the switch member.
   */
  NodeList<Label> get labels => _labels;

  /**
   * Return the statements that will be executed if this switch member is
   * selected.
   */
  NodeList<Statement> get statements => _statements;
}

/**
 * A switch statement.
 *
 * > switchStatement ::=
 * >     'switch' '(' [Expression] ')' '{' [SwitchCase]* [SwitchDefault]? '}'
 */
class SwitchStatement extends Statement {
  /**
   * The token representing the 'switch' keyword.
   */
  Token switchKeyword;

  /**
   * The left parenthesis.
   */
  Token leftParenthesis;

  /**
   * The expression used to determine which of the switch members will be
   * selected.
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
   * Initialize a newly created switch statement. The list of [members] can be
   * `null` if there are no switch members.
   */
  SwitchStatement(this.switchKeyword, this.leftParenthesis,
      Expression expression, this.rightParenthesis, this.leftBracket,
      List<SwitchMember> members, this.rightBracket) {
    _expression = _becomeParentOf(expression);
    _members = new NodeList<SwitchMember>(this, members);
  }

  @override
  Token get beginToken => switchKeyword;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(switchKeyword)
    ..add(leftParenthesis)
    ..add(_expression)
    ..add(rightParenthesis)
    ..add(leftBracket)
    ..addAll(_members)
    ..add(rightBracket);

  @override
  Token get endToken => rightBracket;

  /**
   * Return the expression used to determine which of the switch members will be
   * selected.
   */
  Expression get expression => _expression;

  /**
   * Set the expression used to determine which of the switch members will be
   * selected to the given [expression].
   */
  void set expression(Expression expression) {
    _expression = _becomeParentOf(expression);
  }

  /**
   * Return the token representing the 'switch' keyword.
   */
  @deprecated // Use "this.switchKeyword"
  Token get keyword => switchKeyword;

  /**
   * Set the token representing the 'switch' keyword to the given [token].
   */
  @deprecated // Use "this.switchKeyword"
  set keyword(Token token) {
    switchKeyword = token;
  }

  /**
   * Return the switch members that can be selected by the expression.
   */
  NodeList<SwitchMember> get members => _members;

  @override
  accept(AstVisitor visitor) => visitor.visitSwitchStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_expression, visitor);
    _members.accept(visitor);
  }
}

/**
 * A symbol literal expression.
 *
 * > symbolLiteral ::=
 * >     '#' (operator | (identifier ('.' identifier)*))
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
   */
  SymbolLiteral(this.poundSign, this.components);

  @override
  Token get beginToken => poundSign;

  /**
   * TODO(paulberry): add "." tokens.
   */
  @override
  Iterable get childEntities => new ChildEntities()
    ..add(poundSign)
    ..addAll(components);

  @override
  Token get endToken => components[components.length - 1];

  @override
  accept(AstVisitor visitor) => visitor.visitSymbolLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/**
 * A this expression.
 *
 * > thisExpression ::=
 * >     'this'
 */
class ThisExpression extends Expression {
  /**
   * The token representing the 'this' keyword.
   */
  Token thisKeyword;

  /**
   * Initialize a newly created this expression.
   */
  ThisExpression(this.thisKeyword);

  @override
  Token get beginToken => thisKeyword;

  @override
  Iterable get childEntities => new ChildEntities()..add(thisKeyword);

  @override
  Token get endToken => thisKeyword;

  /**
   * Return the token representing the 'this' keyword.
   */
  @deprecated // Use "this.thisKeyword"
  Token get keyword => thisKeyword;

  /**
   * Set the token representing the 'this' keyword to the given [token].
   */
  @deprecated // Use "this.thisKeyword"
  set keyword(Token token) {
    thisKeyword = token;
  }

  @override
  int get precedence => 16;

  @override
  accept(AstVisitor visitor) => visitor.visitThisExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/**
 * A throw expression.
 *
 * > throwExpression ::=
 * >     'throw' [Expression]
 */
class ThrowExpression extends Expression {
  /**
   * The token representing the 'throw' keyword.
   */
  Token throwKeyword;

  /**
   * The expression computing the exception to be thrown.
   */
  Expression _expression;

  /**
   * Initialize a newly created throw expression.
   */
  ThrowExpression(this.throwKeyword, Expression expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Token get beginToken => throwKeyword;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(throwKeyword)
    ..add(_expression);

  @override
  Token get endToken {
    if (_expression != null) {
      return _expression.endToken;
    }
    return throwKeyword;
  }

  /**
   * Return the expression computing the exception to be thrown.
   */
  Expression get expression => _expression;

  /**
   * Set the expression computing the exception to be thrown to the given
   * [expression].
   */
  void set expression(Expression expression) {
    _expression = _becomeParentOf(expression);
  }

  /**
   * Return the token representing the 'throw' keyword.
   */
  @deprecated // Use "this.throwKeyword"
  Token get keyword => throwKeyword;

  /**
   * Set the token representing the 'throw' keyword to the given [token].
   */
  @deprecated // Use "this.throwKeyword"
  set keyword(Token token) {
    throwKeyword = token;
  }

  @override
  int get precedence => 0;

  @override
  accept(AstVisitor visitor) => visitor.visitThrowExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_expression, visitor);
  }
}

/**
 * The declaration of one or more top-level variables of the same type.
 *
 * > topLevelVariableDeclaration ::=
 * >     ('final' | 'const') type? staticFinalDeclarationList ';'
 * >   | variableDeclaration ';'
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
   * Initialize a newly created top-level variable declaration. Either or both
   * of the [comment] and [metadata] can be `null` if the variable does not have
   * the corresponding attribute.
   */
  TopLevelVariableDeclaration(Comment comment, List<Annotation> metadata,
      VariableDeclarationList variableList, this.semicolon)
      : super(comment, metadata) {
    _variableList = _becomeParentOf(variableList);
  }

  @override
  Iterable get childEntities => super._childEntities
    ..add(_variableList)
    ..add(semicolon);

  @override
  Element get element => null;

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => _variableList.beginToken;

  /**
   * Return the top-level variables being declared.
   */
  VariableDeclarationList get variables => _variableList;

  /**
   * Set the top-level variables being declared to the given list of
   * [variables].
   */
  void set variables(VariableDeclarationList variables) {
    _variableList = _becomeParentOf(variables);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitTopLevelVariableDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_variableList, visitor);
  }
}

/**
 * A visitor used to write a source representation of a visited AST node (and
 * all of it's children) to a writer.
 */
class ToSourceVisitor implements AstVisitor<Object> {
  /**
   * The writer to which the source is to be written.
   */
  final PrintWriter _writer;

  /**
   * Initialize a newly created visitor to write source code representing the
   * visited nodes to the given [writer].
   */
  ToSourceVisitor(this._writer);

  @override
  Object visitAdjacentStrings(AdjacentStrings node) {
    _visitNodeListWithSeparator(node.strings, " ");
    return null;
  }

  @override
  Object visitAnnotation(Annotation node) {
    _writer.print('@');
    _visitNode(node.name);
    _visitNodeWithPrefix(".", node.constructorName);
    _visitNode(node.arguments);
    return null;
  }

  @override
  Object visitArgumentList(ArgumentList node) {
    _writer.print('(');
    _visitNodeListWithSeparator(node.arguments, ", ");
    _writer.print(')');
    return null;
  }

  @override
  Object visitAsExpression(AsExpression node) {
    _visitNode(node.expression);
    _writer.print(" as ");
    _visitNode(node.type);
    return null;
  }

  @override
  Object visitAssertStatement(AssertStatement node) {
    _writer.print("assert (");
    _visitNode(node.condition);
    _writer.print(");");
    return null;
  }

  @override
  Object visitAssignmentExpression(AssignmentExpression node) {
    _visitNode(node.leftHandSide);
    _writer.print(' ');
    _writer.print(node.operator.lexeme);
    _writer.print(' ');
    _visitNode(node.rightHandSide);
    return null;
  }

  @override
  Object visitAwaitExpression(AwaitExpression node) {
    _writer.print("await ");
    _visitNode(node.expression);
    _writer.print(";");
    return null;
  }

  @override
  Object visitBinaryExpression(BinaryExpression node) {
    _visitNode(node.leftOperand);
    _writer.print(' ');
    _writer.print(node.operator.lexeme);
    _writer.print(' ');
    _visitNode(node.rightOperand);
    return null;
  }

  @override
  Object visitBlock(Block node) {
    _writer.print('{');
    _visitNodeListWithSeparator(node.statements, " ");
    _writer.print('}');
    return null;
  }

  @override
  Object visitBlockFunctionBody(BlockFunctionBody node) {
    Token keyword = node.keyword;
    if (keyword != null) {
      _writer.print(keyword.lexeme);
      if (node.star != null) {
        _writer.print('*');
      }
      _writer.print(' ');
    }
    _visitNode(node.block);
    return null;
  }

  @override
  Object visitBooleanLiteral(BooleanLiteral node) {
    _writer.print(node.literal.lexeme);
    return null;
  }

  @override
  Object visitBreakStatement(BreakStatement node) {
    _writer.print("break");
    _visitNodeWithPrefix(" ", node.label);
    _writer.print(";");
    return null;
  }

  @override
  Object visitCascadeExpression(CascadeExpression node) {
    _visitNode(node.target);
    _visitNodeList(node.cascadeSections);
    return null;
  }

  @override
  Object visitCatchClause(CatchClause node) {
    _visitNodeWithPrefix("on ", node.exceptionType);
    if (node.catchKeyword != null) {
      if (node.exceptionType != null) {
        _writer.print(' ');
      }
      _writer.print("catch (");
      _visitNode(node.exceptionParameter);
      _visitNodeWithPrefix(", ", node.stackTraceParameter);
      _writer.print(") ");
    } else {
      _writer.print(" ");
    }
    _visitNode(node.body);
    return null;
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _visitTokenWithSuffix(node.abstractKeyword, " ");
    _writer.print("class ");
    _visitNode(node.name);
    _visitNode(node.typeParameters);
    _visitNodeWithPrefix(" ", node.extendsClause);
    _visitNodeWithPrefix(" ", node.withClause);
    _visitNodeWithPrefix(" ", node.implementsClause);
    _writer.print(" {");
    _visitNodeListWithSeparator(node.members, " ");
    _writer.print("}");
    return null;
  }

  @override
  Object visitClassTypeAlias(ClassTypeAlias node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    if (node.abstractKeyword != null) {
      _writer.print("abstract ");
    }
    _writer.print("class ");
    _visitNode(node.name);
    _visitNode(node.typeParameters);
    _writer.print(" = ");
    _visitNode(node.superclass);
    _visitNodeWithPrefix(" ", node.withClause);
    _visitNodeWithPrefix(" ", node.implementsClause);
    _writer.print(";");
    return null;
  }

  @override
  Object visitComment(Comment node) => null;

  @override
  Object visitCommentReference(CommentReference node) => null;

  @override
  Object visitCompilationUnit(CompilationUnit node) {
    ScriptTag scriptTag = node.scriptTag;
    NodeList<Directive> directives = node.directives;
    _visitNode(scriptTag);
    String prefix = scriptTag == null ? "" : " ";
    _visitNodeListWithSeparatorAndPrefix(prefix, directives, " ");
    prefix = scriptTag == null && directives.isEmpty ? "" : " ";
    _visitNodeListWithSeparatorAndPrefix(prefix, node.declarations, " ");
    return null;
  }

  @override
  Object visitConditionalExpression(ConditionalExpression node) {
    _visitNode(node.condition);
    _writer.print(" ? ");
    _visitNode(node.thenExpression);
    _writer.print(" : ");
    _visitNode(node.elseExpression);
    return null;
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _visitTokenWithSuffix(node.externalKeyword, " ");
    _visitTokenWithSuffix(node.constKeyword, " ");
    _visitTokenWithSuffix(node.factoryKeyword, " ");
    _visitNode(node.returnType);
    _visitNodeWithPrefix(".", node.name);
    _visitNode(node.parameters);
    _visitNodeListWithSeparatorAndPrefix(" : ", node.initializers, ", ");
    _visitNodeWithPrefix(" = ", node.redirectedConstructor);
    _visitFunctionWithPrefix(" ", node.body);
    return null;
  }

  @override
  Object visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    _visitTokenWithSuffix(node.thisKeyword, ".");
    _visitNode(node.fieldName);
    _writer.print(" = ");
    _visitNode(node.expression);
    return null;
  }

  @override
  Object visitConstructorName(ConstructorName node) {
    _visitNode(node.type);
    _visitNodeWithPrefix(".", node.name);
    return null;
  }

  @override
  Object visitContinueStatement(ContinueStatement node) {
    _writer.print("continue");
    _visitNodeWithPrefix(" ", node.label);
    _writer.print(";");
    return null;
  }

  @override
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _visitTokenWithSuffix(node.keyword, " ");
    _visitNodeWithSuffix(node.type, " ");
    _visitNode(node.identifier);
    return null;
  }

  @override
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    _visitNode(node.parameter);
    if (node.separator != null) {
      _writer.print(" ");
      _writer.print(node.separator.lexeme);
      _visitNodeWithPrefix(" ", node.defaultValue);
    }
    return null;
  }

  @override
  Object visitDoStatement(DoStatement node) {
    _writer.print("do ");
    _visitNode(node.body);
    _writer.print(" while (");
    _visitNode(node.condition);
    _writer.print(");");
    return null;
  }

  @override
  Object visitDoubleLiteral(DoubleLiteral node) {
    _writer.print(node.literal.lexeme);
    return null;
  }

  @override
  Object visitEmptyFunctionBody(EmptyFunctionBody node) {
    _writer.print(';');
    return null;
  }

  @override
  Object visitEmptyStatement(EmptyStatement node) {
    _writer.print(';');
    return null;
  }

  @override
  Object visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _visitNode(node.name);
    return null;
  }

  @override
  Object visitEnumDeclaration(EnumDeclaration node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _writer.print("enum ");
    _visitNode(node.name);
    _writer.print(" {");
    _visitNodeListWithSeparator(node.constants, ", ");
    _writer.print("}");
    return null;
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _writer.print("export ");
    _visitNode(node.uri);
    _visitNodeListWithSeparatorAndPrefix(" ", node.combinators, " ");
    _writer.print(';');
    return null;
  }

  @override
  Object visitExpressionFunctionBody(ExpressionFunctionBody node) {
    Token keyword = node.keyword;
    if (keyword != null) {
      _writer.print(keyword.lexeme);
      _writer.print(' ');
    }
    _writer.print("=> ");
    _visitNode(node.expression);
    if (node.semicolon != null) {
      _writer.print(';');
    }
    return null;
  }

  @override
  Object visitExpressionStatement(ExpressionStatement node) {
    _visitNode(node.expression);
    _writer.print(';');
    return null;
  }

  @override
  Object visitExtendsClause(ExtendsClause node) {
    _writer.print("extends ");
    _visitNode(node.superclass);
    return null;
  }

  @override
  Object visitFieldDeclaration(FieldDeclaration node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _visitTokenWithSuffix(node.staticKeyword, " ");
    _visitNode(node.fields);
    _writer.print(";");
    return null;
  }

  @override
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    _visitTokenWithSuffix(node.keyword, " ");
    _visitNodeWithSuffix(node.type, " ");
    _writer.print("this.");
    _visitNode(node.identifier);
    _visitNode(node.parameters);
    return null;
  }

  @override
  Object visitForEachStatement(ForEachStatement node) {
    DeclaredIdentifier loopVariable = node.loopVariable;
    if (node.awaitKeyword != null) {
      _writer.print("await ");
    }
    _writer.print("for (");
    if (loopVariable == null) {
      _visitNode(node.identifier);
    } else {
      _visitNode(loopVariable);
    }
    _writer.print(" in ");
    _visitNode(node.iterable);
    _writer.print(") ");
    _visitNode(node.body);
    return null;
  }

  @override
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
        if (parameter.kind == ParameterKind.NAMED) {
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

  @override
  Object visitForStatement(ForStatement node) {
    Expression initialization = node.initialization;
    _writer.print("for (");
    if (initialization != null) {
      _visitNode(initialization);
    } else {
      _visitNode(node.variables);
    }
    _writer.print(";");
    _visitNodeWithPrefix(" ", node.condition);
    _writer.print(";");
    _visitNodeListWithSeparatorAndPrefix(" ", node.updaters, ", ");
    _writer.print(") ");
    _visitNode(node.body);
    return null;
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _visitNodeWithSuffix(node.returnType, " ");
    _visitTokenWithSuffix(node.propertyKeyword, " ");
    _visitNode(node.name);
    _visitNode(node.functionExpression);
    return null;
  }

  @override
  Object visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    _visitNode(node.functionDeclaration);
    return null;
  }

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    _visitNode(node.parameters);
    _writer.print(' ');
    _visitNode(node.body);
    return null;
  }

  @override
  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _visitNode(node.function);
    _visitNode(node.argumentList);
    return null;
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _writer.print("typedef ");
    _visitNodeWithSuffix(node.returnType, " ");
    _visitNode(node.name);
    _visitNode(node.typeParameters);
    _visitNode(node.parameters);
    _writer.print(";");
    return null;
  }

  @override
  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _visitNodeWithSuffix(node.returnType, " ");
    _visitNode(node.identifier);
    _visitNode(node.parameters);
    return null;
  }

  @override
  Object visitHideCombinator(HideCombinator node) {
    _writer.print("hide ");
    _visitNodeListWithSeparator(node.hiddenNames, ", ");
    return null;
  }

  @override
  Object visitIfStatement(IfStatement node) {
    _writer.print("if (");
    _visitNode(node.condition);
    _writer.print(") ");
    _visitNode(node.thenStatement);
    _visitNodeWithPrefix(" else ", node.elseStatement);
    return null;
  }

  @override
  Object visitImplementsClause(ImplementsClause node) {
    _writer.print("implements ");
    _visitNodeListWithSeparator(node.interfaces, ", ");
    return null;
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _writer.print("import ");
    _visitNode(node.uri);
    if (node.deferredKeyword != null) {
      _writer.print(" deferred");
    }
    _visitNodeWithPrefix(" as ", node.prefix);
    _visitNodeListWithSeparatorAndPrefix(" ", node.combinators, " ");
    _writer.print(';');
    return null;
  }

  @override
  Object visitIndexExpression(IndexExpression node) {
    if (node.isCascaded) {
      _writer.print("..");
    } else {
      _visitNode(node.target);
    }
    _writer.print('[');
    _visitNode(node.index);
    _writer.print(']');
    return null;
  }

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    _visitTokenWithSuffix(node.keyword, " ");
    _visitNode(node.constructorName);
    _visitNode(node.argumentList);
    return null;
  }

  @override
  Object visitIntegerLiteral(IntegerLiteral node) {
    _writer.print(node.literal.lexeme);
    return null;
  }

  @override
  Object visitInterpolationExpression(InterpolationExpression node) {
    if (node.rightBracket != null) {
      _writer.print("\${");
      _visitNode(node.expression);
      _writer.print("}");
    } else {
      _writer.print("\$");
      _visitNode(node.expression);
    }
    return null;
  }

  @override
  Object visitInterpolationString(InterpolationString node) {
    _writer.print(node.contents.lexeme);
    return null;
  }

  @override
  Object visitIsExpression(IsExpression node) {
    _visitNode(node.expression);
    if (node.notOperator == null) {
      _writer.print(" is ");
    } else {
      _writer.print(" is! ");
    }
    _visitNode(node.type);
    return null;
  }

  @override
  Object visitLabel(Label node) {
    _visitNode(node.label);
    _writer.print(":");
    return null;
  }

  @override
  Object visitLabeledStatement(LabeledStatement node) {
    _visitNodeListWithSeparatorAndSuffix(node.labels, " ", " ");
    _visitNode(node.statement);
    return null;
  }

  @override
  Object visitLibraryDirective(LibraryDirective node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _writer.print("library ");
    _visitNode(node.name);
    _writer.print(';');
    return null;
  }

  @override
  Object visitLibraryIdentifier(LibraryIdentifier node) {
    _writer.print(node.name);
    return null;
  }

  @override
  Object visitListLiteral(ListLiteral node) {
    if (node.constKeyword != null) {
      _writer.print(node.constKeyword.lexeme);
      _writer.print(' ');
    }
    _visitNodeWithSuffix(node.typeArguments, " ");
    _writer.print("[");
    _visitNodeListWithSeparator(node.elements, ", ");
    _writer.print("]");
    return null;
  }

  @override
  Object visitMapLiteral(MapLiteral node) {
    if (node.constKeyword != null) {
      _writer.print(node.constKeyword.lexeme);
      _writer.print(' ');
    }
    _visitNodeWithSuffix(node.typeArguments, " ");
    _writer.print("{");
    _visitNodeListWithSeparator(node.entries, ", ");
    _writer.print("}");
    return null;
  }

  @override
  Object visitMapLiteralEntry(MapLiteralEntry node) {
    _visitNode(node.key);
    _writer.print(" : ");
    _visitNode(node.value);
    return null;
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _visitTokenWithSuffix(node.externalKeyword, " ");
    _visitTokenWithSuffix(node.modifierKeyword, " ");
    _visitNodeWithSuffix(node.returnType, " ");
    _visitTokenWithSuffix(node.propertyKeyword, " ");
    _visitTokenWithSuffix(node.operatorKeyword, " ");
    _visitNode(node.name);
    if (!node.isGetter) {
      _visitNode(node.parameters);
    }
    _visitFunctionWithPrefix(" ", node.body);
    return null;
  }

  @override
  Object visitMethodInvocation(MethodInvocation node) {
    if (node.isCascaded) {
      _writer.print("..");
    } else {
      if (node.target != null) {
        node.target.accept(this);
        _writer.print(node.operator.lexeme);
      }
    }
    _visitNode(node.methodName);
    _visitNode(node.argumentList);
    return null;
  }

  @override
  Object visitNamedExpression(NamedExpression node) {
    _visitNode(node.name);
    _visitNodeWithPrefix(" ", node.expression);
    return null;
  }

  @override
  Object visitNativeClause(NativeClause node) {
    _writer.print("native ");
    _visitNode(node.name);
    return null;
  }

  @override
  Object visitNativeFunctionBody(NativeFunctionBody node) {
    _writer.print("native ");
    _visitNode(node.stringLiteral);
    _writer.print(';');
    return null;
  }

  @override
  Object visitNullLiteral(NullLiteral node) {
    _writer.print("null");
    return null;
  }

  @override
  Object visitParenthesizedExpression(ParenthesizedExpression node) {
    _writer.print('(');
    _visitNode(node.expression);
    _writer.print(')');
    return null;
  }

  @override
  Object visitPartDirective(PartDirective node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _writer.print("part ");
    _visitNode(node.uri);
    _writer.print(';');
    return null;
  }

  @override
  Object visitPartOfDirective(PartOfDirective node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _writer.print("part of ");
    _visitNode(node.libraryName);
    _writer.print(';');
    return null;
  }

  @override
  Object visitPostfixExpression(PostfixExpression node) {
    _visitNode(node.operand);
    _writer.print(node.operator.lexeme);
    return null;
  }

  @override
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    _visitNode(node.prefix);
    _writer.print('.');
    _visitNode(node.identifier);
    return null;
  }

  @override
  Object visitPrefixExpression(PrefixExpression node) {
    _writer.print(node.operator.lexeme);
    _visitNode(node.operand);
    return null;
  }

  @override
  Object visitPropertyAccess(PropertyAccess node) {
    if (node.isCascaded) {
      _writer.print("..");
    } else {
      _visitNode(node.target);
      _writer.print(node.operator.lexeme);
    }
    _visitNode(node.propertyName);
    return null;
  }

  @override
  Object visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    _writer.print("this");
    _visitNodeWithPrefix(".", node.constructorName);
    _visitNode(node.argumentList);
    return null;
  }

  @override
  Object visitRethrowExpression(RethrowExpression node) {
    _writer.print("rethrow");
    return null;
  }

  @override
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

  @override
  Object visitScriptTag(ScriptTag node) {
    _writer.print(node.scriptTag.lexeme);
    return null;
  }

  @override
  Object visitShowCombinator(ShowCombinator node) {
    _writer.print("show ");
    _visitNodeListWithSeparator(node.shownNames, ", ");
    return null;
  }

  @override
  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    _visitTokenWithSuffix(node.keyword, " ");
    _visitNodeWithSuffix(node.type, " ");
    _visitNode(node.identifier);
    return null;
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    _writer.print(node.token.lexeme);
    return null;
  }

  @override
  Object visitSimpleStringLiteral(SimpleStringLiteral node) {
    _writer.print(node.literal.lexeme);
    return null;
  }

  @override
  Object visitStringInterpolation(StringInterpolation node) {
    _visitNodeList(node.elements);
    return null;
  }

  @override
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    _writer.print("super");
    _visitNodeWithPrefix(".", node.constructorName);
    _visitNode(node.argumentList);
    return null;
  }

  @override
  Object visitSuperExpression(SuperExpression node) {
    _writer.print("super");
    return null;
  }

  @override
  Object visitSwitchCase(SwitchCase node) {
    _visitNodeListWithSeparatorAndSuffix(node.labels, " ", " ");
    _writer.print("case ");
    _visitNode(node.expression);
    _writer.print(": ");
    _visitNodeListWithSeparator(node.statements, " ");
    return null;
  }

  @override
  Object visitSwitchDefault(SwitchDefault node) {
    _visitNodeListWithSeparatorAndSuffix(node.labels, " ", " ");
    _writer.print("default: ");
    _visitNodeListWithSeparator(node.statements, " ");
    return null;
  }

  @override
  Object visitSwitchStatement(SwitchStatement node) {
    _writer.print("switch (");
    _visitNode(node.expression);
    _writer.print(") {");
    _visitNodeListWithSeparator(node.members, " ");
    _writer.print("}");
    return null;
  }

  @override
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

  @override
  Object visitThisExpression(ThisExpression node) {
    _writer.print("this");
    return null;
  }

  @override
  Object visitThrowExpression(ThrowExpression node) {
    _writer.print("throw ");
    _visitNode(node.expression);
    return null;
  }

  @override
  Object visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _visitNodeWithSuffix(node.variables, ";");
    return null;
  }

  @override
  Object visitTryStatement(TryStatement node) {
    _writer.print("try ");
    _visitNode(node.body);
    _visitNodeListWithSeparatorAndPrefix(" ", node.catchClauses, " ");
    _visitNodeWithPrefix(" finally ", node.finallyBlock);
    return null;
  }

  @override
  Object visitTypeArgumentList(TypeArgumentList node) {
    _writer.print('<');
    _visitNodeListWithSeparator(node.arguments, ", ");
    _writer.print('>');
    return null;
  }

  @override
  Object visitTypeName(TypeName node) {
    _visitNode(node.name);
    _visitNode(node.typeArguments);
    return null;
  }

  @override
  Object visitTypeParameter(TypeParameter node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _visitNode(node.name);
    _visitNodeWithPrefix(" extends ", node.bound);
    return null;
  }

  @override
  Object visitTypeParameterList(TypeParameterList node) {
    _writer.print('<');
    _visitNodeListWithSeparator(node.typeParameters, ", ");
    _writer.print('>');
    return null;
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _visitNode(node.name);
    _visitNodeWithPrefix(" = ", node.initializer);
    return null;
  }

  @override
  Object visitVariableDeclarationList(VariableDeclarationList node) {
    _visitNodeListWithSeparatorAndSuffix(node.metadata, " ", " ");
    _visitTokenWithSuffix(node.keyword, " ");
    _visitNodeWithSuffix(node.type, " ");
    _visitNodeListWithSeparator(node.variables, ", ");
    return null;
  }

  @override
  Object visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    _visitNode(node.variables);
    _writer.print(";");
    return null;
  }

  @override
  Object visitWhileStatement(WhileStatement node) {
    _writer.print("while (");
    _visitNode(node.condition);
    _writer.print(") ");
    _visitNode(node.body);
    return null;
  }

  @override
  Object visitWithClause(WithClause node) {
    _writer.print("with ");
    _visitNodeListWithSeparator(node.mixinTypes, ", ");
    return null;
  }

  @override
  Object visitYieldStatement(YieldStatement node) {
    if (node.star != null) {
      _writer.print("yield* ");
    } else {
      _writer.print("yield ");
    }
    _visitNode(node.expression);
    _writer.print(";");
    return null;
  }

  /**
   * Visit the given function [body], printing the [prefix] before if the body
   * is not empty.
   */
  void _visitFunctionWithPrefix(String prefix, FunctionBody body) {
    if (body is! EmptyFunctionBody) {
      _writer.print(prefix);
    }
    _visitNode(body);
  }

  /**
   * Safely visit the given [node].
   */
  void _visitNode(AstNode node) {
    if (node != null) {
      node.accept(this);
    }
  }

  /**
   * Print a list of [nodes] without any separation.
   */
  void _visitNodeList(NodeList<AstNode> nodes) {
    _visitNodeListWithSeparator(nodes, "");
  }

  /**
   * Print a list of [nodes], separated by the given [separator].
   */
  void _visitNodeListWithSeparator(NodeList<AstNode> nodes, String separator) {
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
   * Print a list of [nodes], prefixed by the given [prefix] if the list is not
   * empty, and separated by the given [separator].
   */
  void _visitNodeListWithSeparatorAndPrefix(
      String prefix, NodeList<AstNode> nodes, String separator) {
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
   * Print a list of [nodes], separated by the given [separator], followed by
   * the given [suffix] if the list is not empty.
   */
  void _visitNodeListWithSeparatorAndSuffix(
      NodeList<AstNode> nodes, String separator, String suffix) {
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
   * Safely visit the given [node], printing the [prefix] before the node if it
   * is non-`null`.
   */
  void _visitNodeWithPrefix(String prefix, AstNode node) {
    if (node != null) {
      _writer.print(prefix);
      node.accept(this);
    }
  }

  /**
   * Safely visit the given [node], printing the [suffix] after the node if it
   * is non-`null`.
   */
  void _visitNodeWithSuffix(AstNode node, String suffix) {
    if (node != null) {
      node.accept(this);
      _writer.print(suffix);
    }
  }

  /**
   * Safely visit the given [token], printing the [suffix] after the token if it
   * is non-`null`.
   */
  void _visitTokenWithSuffix(Token token, String suffix) {
    if (token != null) {
      _writer.print(token.lexeme);
      _writer.print(suffix);
    }
  }
}

/**
 * A try statement.
 *
 * > tryStatement ::=
 * >     'try' [Block] ([CatchClause]+ finallyClause? | finallyClause)
 * >
 * > finallyClause ::=
 * >     'finally' [Block]
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
   * The token representing the 'finally' keyword, or `null` if the statement
   * does not contain a finally clause.
   */
  Token finallyKeyword;

  /**
   * The finally block contained in the try statement, or `null` if the
   * statement does not contain a finally clause.
   */
  Block _finallyBlock;

  /**
   * Initialize a newly created try statement. The list of [catchClauses] can be
   * `null` if there are no catch clauses. The [finallyKeyword] and
   * [finallyBlock] can be `null` if there is no finally clause.
   */
  TryStatement(this.tryKeyword, Block body, List<CatchClause> catchClauses,
      this.finallyKeyword, Block finallyBlock) {
    _body = _becomeParentOf(body);
    _catchClauses = new NodeList<CatchClause>(this, catchClauses);
    _finallyBlock = _becomeParentOf(finallyBlock);
  }

  @override
  Token get beginToken => tryKeyword;

  /**
   * Return the body of the statement.
   */
  Block get body => _body;

  /**
   * Set the body of the statement to the given [block].
   */
  void set body(Block block) {
    _body = _becomeParentOf(block);
  }

  /**
   * Return the catch clauses contained in the try statement.
   */
  NodeList<CatchClause> get catchClauses => _catchClauses;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(tryKeyword)
    ..add(_body)
    ..addAll(_catchClauses)
    ..add(finallyKeyword)
    ..add(_finallyBlock);

  @override
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
   * Return the finally block contained in the try statement, or `null` if the
   * statement does not contain a finally clause.
   */
  Block get finallyBlock => _finallyBlock;

  /**
   * Set the finally block contained in the try statement to the given [block].
   */
  void set finallyBlock(Block block) {
    _finallyBlock = _becomeParentOf(block);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitTryStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_body, visitor);
    _catchClauses.accept(visitor);
    _safelyVisitChild(_finallyBlock, visitor);
  }
}

/**
 * The declaration of a type alias.
 *
 * > typeAlias ::=
 * >     'typedef' typeAliasBody
 * >
 * > typeAliasBody ::=
 * >     classTypeAlias
 * >   | functionTypeAlias
 */
abstract class TypeAlias extends NamedCompilationUnitMember {
  /**
   * The token representing the 'typedef' keyword.
   */
  Token typedefKeyword;

  /**
   * The semicolon terminating the declaration.
   */
  Token semicolon;

  /**
   * Initialize a newly created type alias. Either or both of the [comment] and
   * [metadata] can be `null` if the declaration does not have the corresponding
   * attribute.
   */
  TypeAlias(Comment comment, List<Annotation> metadata, this.typedefKeyword,
      SimpleIdentifier name, this.semicolon)
      : super(comment, metadata, name);

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => typedefKeyword;

  /**
   * Return the token representing the 'typedef' keyword.
   */
  @deprecated // Use "this.typedefKeyword"
  Token get keyword => typedefKeyword;

  /**
   * Set the token representing the 'typedef' keyword to the given [token].
   */
  @deprecated // Use "this.typedefKeyword"
  set keyword(Token token) {
    typedefKeyword = token;
  }
}

/**
 * A list of type arguments.
 *
 * > typeArguments ::=
 * >     '<' typeName (',' typeName)* '>'
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
   */
  TypeArgumentList(
      this.leftBracket, List<TypeName> arguments, this.rightBracket) {
    _arguments = new NodeList<TypeName>(this, arguments);
  }

  /**
   * Return the type arguments associated with the type.
   */
  NodeList<TypeName> get arguments => _arguments;

  @override
  Token get beginToken => leftBracket;

  /**
   * TODO(paulberry): Add commas.
   */
  @override
  Iterable get childEntities => new ChildEntities()
    ..add(leftBracket)
    ..addAll(_arguments)
    ..add(rightBracket);

  @override
  Token get endToken => rightBracket;

  @override
  accept(AstVisitor visitor) => visitor.visitTypeArgumentList(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _arguments.accept(visitor);
  }
}

/**
 * A literal that has a type associated with it.
 *
 * > typedLiteral ::=
 * >     [ListLiteral]
 * >   | [MapLiteral]
 */
abstract class TypedLiteral extends Literal {
  /**
   * The token representing the 'const' keyword, or `null` if the literal is not
   * a constant.
   */
  Token constKeyword;

  /**
   * The type argument associated with this literal, or `null` if no type
   * arguments were declared.
   */
  TypeArgumentList _typeArguments;

  /**
   * Initialize a newly created typed literal. The [constKeyword] can be `null`\
   * if the literal is not a constant. The [typeArguments] can be `null` if no
   * type arguments were declared.
   */
  TypedLiteral(this.constKeyword, TypeArgumentList typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  /**
   * Return the type argument associated with this literal, or `null` if no type
   * arguments were declared.
   */
  TypeArgumentList get typeArguments => _typeArguments;

  /**
   * Set the type argument associated with this literal to the given
   * [typeArguments].
   */
  void set typeArguments(TypeArgumentList typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  ChildEntities get _childEntities => new ChildEntities()
    ..add(constKeyword)
    ..add(_typeArguments);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_typeArguments, visitor);
  }
}

/**
 * The name of a type, which can optionally include type arguments.
 *
 * > typeName ::=
 * >     [Identifier] typeArguments?
 */
class TypeName extends AstNode {
  /**
   * The name of the type.
   */
  Identifier _name;

  /**
   * The type arguments associated with the type, or `null` if there are no type
   * arguments.
   */
  TypeArgumentList _typeArguments;

  /**
   * The type being named, or `null` if the AST structure has not been resolved.
   */
  DartType type;

  /**
   * Initialize a newly created type name. The [typeArguments] can be `null` if
   * there are no type arguments.
   */
  TypeName(Identifier name, TypeArgumentList typeArguments) {
    _name = _becomeParentOf(name);
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @override
  Token get beginToken => _name.beginToken;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(_name)
    ..add(_typeArguments);

  @override
  Token get endToken {
    if (_typeArguments != null) {
      return _typeArguments.endToken;
    }
    return _name.endToken;
  }

  /**
   * Return `true` if this type is a deferred type.
   *
   * 15.1 Static Types: A type <i>T</i> is deferred iff it is of the form
   * </i>p.T</i> where <i>p</i> is a deferred prefix.
   */
  bool get isDeferred {
    Identifier identifier = name;
    if (identifier is! PrefixedIdentifier) {
      return false;
    }
    return (identifier as PrefixedIdentifier).isDeferred;
  }

  @override
  bool get isSynthetic => _name.isSynthetic && _typeArguments == null;

  /**
   * Return the name of the type.
   */
  Identifier get name => _name;

  /**
   * Set the name of the type to the given [identifier].
   */
  void set name(Identifier identifier) {
    _name = _becomeParentOf(identifier);
  }

  /**
   * Return the type arguments associated with the type, or `null` if there are
   * no type arguments.
   */
  TypeArgumentList get typeArguments => _typeArguments;

  /**
   * Set the type arguments associated with the type to the given
   * [typeArguments].
   */
  void set typeArguments(TypeArgumentList typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitTypeName(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_name, visitor);
    _safelyVisitChild(_typeArguments, visitor);
  }
}

/**
 * A type parameter.
 *
 * > typeParameter ::=
 * >     [SimpleIdentifier] ('extends' [TypeName])?
 */
class TypeParameter extends Declaration {
  /**
   * The name of the type parameter.
   */
  SimpleIdentifier _name;

  /**
   * The token representing the 'extends' keyword, or `null` if there is no
   * explicit upper bound.
   */
  Token extendsKeyword;

  /**
   * The name of the upper bound for legal arguments, or `null` if there is no
   * explicit upper bound.
   */
  TypeName _bound;

  /**
   * Initialize a newly created type parameter. Either or both of the [comment]
   * and [metadata] can be `null` if the parameter does not have the
   * corresponding attribute. The [extendsKeyword] and [bound] can be `null` if
   * the parameter does not have an upper bound.
   */
  TypeParameter(Comment comment, List<Annotation> metadata,
      SimpleIdentifier name, this.extendsKeyword, TypeName bound)
      : super(comment, metadata) {
    _name = _becomeParentOf(name);
    _bound = _becomeParentOf(bound);
  }

  /**
   * Return the name of the upper bound for legal arguments, or `null` if there
   * is no explicit upper bound.
   */
  TypeName get bound => _bound;

  /**
   * Set the name of the upper bound for legal arguments to the given
   * [typeName].
   */
  void set bound(TypeName typeName) {
    _bound = _becomeParentOf(typeName);
  }

  @override
  Iterable get childEntities => super._childEntities
    ..add(_name)
    ..add(extendsKeyword)
    ..add(_bound);

  @override
  TypeParameterElement get element =>
      _name != null ? (_name.staticElement as TypeParameterElement) : null;

  @override
  Token get endToken {
    if (_bound == null) {
      return _name.endToken;
    }
    return _bound.endToken;
  }

  @override
  Token get firstTokenAfterCommentAndMetadata => _name.beginToken;

  /**
   * Return the token representing the 'extends' keyword, or `null` if there is
   * no explicit upper bound.
   */
  @deprecated // Use "this.extendsKeyword"
  Token get keyword => extendsKeyword;

  /**
   * Set the token representing the 'extends' keyword to the given [token].
   */
  @deprecated // Use "this.extendsKeyword"
  set keyword(Token token) {
    extendsKeyword = token;
  }

  /**
   * Return the name of the type parameter.
   */
  SimpleIdentifier get name => _name;

  /**
   * Set the name of the type parameter to the given [identifier].
   */
  void set name(SimpleIdentifier identifier) {
    _name = _becomeParentOf(identifier);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitTypeParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_name, visitor);
    _safelyVisitChild(_bound, visitor);
  }
}

/**
 * Type parameters within a declaration.
 *
 * > typeParameterList ::=
 * >     '<' [TypeParameter] (',' [TypeParameter])* '>'
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
   */
  TypeParameterList(
      this.leftBracket, List<TypeParameter> typeParameters, this.rightBracket) {
    _typeParameters = new NodeList<TypeParameter>(this, typeParameters);
  }

  @override
  Token get beginToken => leftBracket;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(leftBracket)
    ..addAll(_typeParameters)
    ..add(rightBracket);

  @override
  Token get endToken => rightBracket;

  /**
   * Return the type parameters for the type.
   */
  NodeList<TypeParameter> get typeParameters => _typeParameters;

  @override
  accept(AstVisitor visitor) => visitor.visitTypeParameterList(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _typeParameters.accept(visitor);
  }
}

/**
 * An AST visitor that will recursively visit all of the nodes in an AST
 * structure (like instances of the class [RecursiveAstVisitor]). In addition,
 * every node will also be visited by using a single unified [visitNode] method.
 *
 * Subclasses that override a visit method must either invoke the overridden
 * visit method or explicitly invoke the more general [visitNode] method.
 * Failure to do so will cause the children of the visited node to not be
 * visited.
 */
class UnifyingAstVisitor<R> implements AstVisitor<R> {
  @override
  R visitAdjacentStrings(AdjacentStrings node) => visitNode(node);

  @override
  R visitAnnotation(Annotation node) => visitNode(node);

  @override
  R visitArgumentList(ArgumentList node) => visitNode(node);

  @override
  R visitAsExpression(AsExpression node) => visitNode(node);

  @override
  R visitAssertStatement(AssertStatement node) => visitNode(node);

  @override
  R visitAssignmentExpression(AssignmentExpression node) => visitNode(node);

  @override
  R visitAwaitExpression(AwaitExpression node) => visitNode(node);

  @override
  R visitBinaryExpression(BinaryExpression node) => visitNode(node);

  @override
  R visitBlock(Block node) => visitNode(node);

  @override
  R visitBlockFunctionBody(BlockFunctionBody node) => visitNode(node);

  @override
  R visitBooleanLiteral(BooleanLiteral node) => visitNode(node);

  @override
  R visitBreakStatement(BreakStatement node) => visitNode(node);

  @override
  R visitCascadeExpression(CascadeExpression node) => visitNode(node);

  @override
  R visitCatchClause(CatchClause node) => visitNode(node);

  @override
  R visitClassDeclaration(ClassDeclaration node) => visitNode(node);

  @override
  R visitClassTypeAlias(ClassTypeAlias node) => visitNode(node);

  @override
  R visitComment(Comment node) => visitNode(node);

  @override
  R visitCommentReference(CommentReference node) => visitNode(node);

  @override
  R visitCompilationUnit(CompilationUnit node) => visitNode(node);

  @override
  R visitConditionalExpression(ConditionalExpression node) => visitNode(node);

  @override
  R visitConstructorDeclaration(ConstructorDeclaration node) => visitNode(node);

  @override
  R visitConstructorFieldInitializer(ConstructorFieldInitializer node) =>
      visitNode(node);

  @override
  R visitConstructorName(ConstructorName node) => visitNode(node);

  @override
  R visitContinueStatement(ContinueStatement node) => visitNode(node);

  @override
  R visitDeclaredIdentifier(DeclaredIdentifier node) => visitNode(node);

  @override
  R visitDefaultFormalParameter(DefaultFormalParameter node) => visitNode(node);

  @override
  R visitDoStatement(DoStatement node) => visitNode(node);

  @override
  R visitDoubleLiteral(DoubleLiteral node) => visitNode(node);

  @override
  R visitEmptyFunctionBody(EmptyFunctionBody node) => visitNode(node);

  @override
  R visitEmptyStatement(EmptyStatement node) => visitNode(node);

  @override
  R visitEnumConstantDeclaration(EnumConstantDeclaration node) =>
      visitNode(node);

  @override
  R visitEnumDeclaration(EnumDeclaration node) => visitNode(node);

  @override
  R visitExportDirective(ExportDirective node) => visitNode(node);

  @override
  R visitExpressionFunctionBody(ExpressionFunctionBody node) => visitNode(node);

  @override
  R visitExpressionStatement(ExpressionStatement node) => visitNode(node);

  @override
  R visitExtendsClause(ExtendsClause node) => visitNode(node);

  @override
  R visitFieldDeclaration(FieldDeclaration node) => visitNode(node);

  @override
  R visitFieldFormalParameter(FieldFormalParameter node) => visitNode(node);

  @override
  R visitForEachStatement(ForEachStatement node) => visitNode(node);

  @override
  R visitFormalParameterList(FormalParameterList node) => visitNode(node);

  @override
  R visitForStatement(ForStatement node) => visitNode(node);

  @override
  R visitFunctionDeclaration(FunctionDeclaration node) => visitNode(node);

  @override
  R visitFunctionDeclarationStatement(FunctionDeclarationStatement node) =>
      visitNode(node);

  @override
  R visitFunctionExpression(FunctionExpression node) => visitNode(node);

  @override
  R visitFunctionExpressionInvocation(FunctionExpressionInvocation node) =>
      visitNode(node);

  @override
  R visitFunctionTypeAlias(FunctionTypeAlias node) => visitNode(node);

  @override
  R visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) =>
      visitNode(node);

  @override
  R visitHideCombinator(HideCombinator node) => visitNode(node);

  @override
  R visitIfStatement(IfStatement node) => visitNode(node);

  @override
  R visitImplementsClause(ImplementsClause node) => visitNode(node);

  @override
  R visitImportDirective(ImportDirective node) => visitNode(node);

  @override
  R visitIndexExpression(IndexExpression node) => visitNode(node);

  @override
  R visitInstanceCreationExpression(InstanceCreationExpression node) =>
      visitNode(node);

  @override
  R visitIntegerLiteral(IntegerLiteral node) => visitNode(node);

  @override
  R visitInterpolationExpression(InterpolationExpression node) =>
      visitNode(node);

  @override
  R visitInterpolationString(InterpolationString node) => visitNode(node);

  @override
  R visitIsExpression(IsExpression node) => visitNode(node);

  @override
  R visitLabel(Label node) => visitNode(node);

  @override
  R visitLabeledStatement(LabeledStatement node) => visitNode(node);

  @override
  R visitLibraryDirective(LibraryDirective node) => visitNode(node);

  @override
  R visitLibraryIdentifier(LibraryIdentifier node) => visitNode(node);

  @override
  R visitListLiteral(ListLiteral node) => visitNode(node);

  @override
  R visitMapLiteral(MapLiteral node) => visitNode(node);

  @override
  R visitMapLiteralEntry(MapLiteralEntry node) => visitNode(node);

  @override
  R visitMethodDeclaration(MethodDeclaration node) => visitNode(node);

  @override
  R visitMethodInvocation(MethodInvocation node) => visitNode(node);

  @override
  R visitNamedExpression(NamedExpression node) => visitNode(node);

  @override
  R visitNativeClause(NativeClause node) => visitNode(node);

  @override
  R visitNativeFunctionBody(NativeFunctionBody node) => visitNode(node);

  R visitNode(AstNode node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitNullLiteral(NullLiteral node) => visitNode(node);

  @override
  R visitParenthesizedExpression(ParenthesizedExpression node) =>
      visitNode(node);

  @override
  R visitPartDirective(PartDirective node) => visitNode(node);

  @override
  R visitPartOfDirective(PartOfDirective node) => visitNode(node);

  @override
  R visitPostfixExpression(PostfixExpression node) => visitNode(node);

  @override
  R visitPrefixedIdentifier(PrefixedIdentifier node) => visitNode(node);

  @override
  R visitPrefixExpression(PrefixExpression node) => visitNode(node);

  @override
  R visitPropertyAccess(PropertyAccess node) => visitNode(node);

  @override
  R visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) => visitNode(node);

  @override
  R visitRethrowExpression(RethrowExpression node) => visitNode(node);

  @override
  R visitReturnStatement(ReturnStatement node) => visitNode(node);

  @override
  R visitScriptTag(ScriptTag scriptTag) => visitNode(scriptTag);

  @override
  R visitShowCombinator(ShowCombinator node) => visitNode(node);

  @override
  R visitSimpleFormalParameter(SimpleFormalParameter node) => visitNode(node);

  @override
  R visitSimpleIdentifier(SimpleIdentifier node) => visitNode(node);

  @override
  R visitSimpleStringLiteral(SimpleStringLiteral node) => visitNode(node);

  @override
  R visitStringInterpolation(StringInterpolation node) => visitNode(node);

  @override
  R visitSuperConstructorInvocation(SuperConstructorInvocation node) =>
      visitNode(node);

  @override
  R visitSuperExpression(SuperExpression node) => visitNode(node);

  @override
  R visitSwitchCase(SwitchCase node) => visitNode(node);

  @override
  R visitSwitchDefault(SwitchDefault node) => visitNode(node);

  @override
  R visitSwitchStatement(SwitchStatement node) => visitNode(node);

  @override
  R visitSymbolLiteral(SymbolLiteral node) => visitNode(node);

  @override
  R visitThisExpression(ThisExpression node) => visitNode(node);

  @override
  R visitThrowExpression(ThrowExpression node) => visitNode(node);

  @override
  R visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) =>
      visitNode(node);

  @override
  R visitTryStatement(TryStatement node) => visitNode(node);

  @override
  R visitTypeArgumentList(TypeArgumentList node) => visitNode(node);

  @override
  R visitTypeName(TypeName node) => visitNode(node);

  @override
  R visitTypeParameter(TypeParameter node) => visitNode(node);

  @override
  R visitTypeParameterList(TypeParameterList node) => visitNode(node);

  @override
  R visitVariableDeclaration(VariableDeclaration node) => visitNode(node);

  @override
  R visitVariableDeclarationList(VariableDeclarationList node) =>
      visitNode(node);

  @override
  R visitVariableDeclarationStatement(VariableDeclarationStatement node) =>
      visitNode(node);

  @override
  R visitWhileStatement(WhileStatement node) => visitNode(node);

  @override
  R visitWithClause(WithClause node) => visitNode(node);

  @override
  R visitYieldStatement(YieldStatement node) => visitNode(node);
}

/**
 * A directive that references a URI.
 *
 * > uriBasedDirective ::=
 * >     [ExportDirective]
 * >   | [ImportDirective]
 * >   | [PartDirective]
 */
abstract class UriBasedDirective extends Directive {
  /**
   * The prefix of a URI using the `dart-ext` scheme to reference a native code
   * library.
   */
  static String _DART_EXT_SCHEME = "dart-ext:";

  /**
   * The URI referenced by this directive.
   */
  StringLiteral _uri;

  /**
   * The content of the URI.
   */
  String uriContent;

  /**
   * The source to which the URI was resolved.
   */
  Source source;

  /**
   * Initialize a newly create URI-based directive. Either or both of the
   * [comment] and [metadata] can be `null` if the directive does not have the
   * corresponding attribute.
   */
  UriBasedDirective(
      Comment comment, List<Annotation> metadata, StringLiteral uri)
      : super(comment, metadata) {
    _uri = _becomeParentOf(uri);
  }

  /**
   * Return the URI referenced by this directive.
   */
  StringLiteral get uri => _uri;

  /**
   * Set the URI referenced by this directive to the given [uri].
   */
  void set uri(StringLiteral uri) {
    _uri = _becomeParentOf(uri);
  }

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
  UriValidationCode validate() {
    StringLiteral uriLiteral = uri;
    if (uriLiteral is StringInterpolation) {
      return UriValidationCode.URI_WITH_INTERPOLATION;
    }
    String uriContent = this.uriContent;
    if (uriContent == null) {
      return UriValidationCode.INVALID_URI;
    }
    if (this is ImportDirective && uriContent.startsWith(_DART_EXT_SCHEME)) {
      return UriValidationCode.URI_WITH_DART_EXT_SCHEME;
    }
    try {
      parseUriWithException(Uri.encodeFull(uriContent));
    } on URISyntaxException {
      return UriValidationCode.INVALID_URI;
    }
    return null;
  }

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_uri, visitor);
  }
}

/**
 * Validation codes returned by [UriBasedDirective.validate].
 */
class UriValidationCode {
  static const UriValidationCode INVALID_URI =
      const UriValidationCode('INVALID_URI');

  static const UriValidationCode URI_WITH_INTERPOLATION =
      const UriValidationCode('URI_WITH_INTERPOLATION');

  static const UriValidationCode URI_WITH_DART_EXT_SCHEME =
      const UriValidationCode('URI_WITH_DART_EXT_SCHEME');

  /**
   * The name of the validation code.
   */
  final String name;

  /**
   * Initialize a newly created validation code to have the given [name].
   */
  const UriValidationCode(this.name);

  @override
  String toString() => name;
}

/**
 * An identifier that has an initial value associated with it. Instances of this
 * class are always children of the class [VariableDeclarationList].
 *
 * > variableDeclaration ::=
 * >     [SimpleIdentifier] ('=' [Expression])?
 *
 * TODO(paulberry): the grammar does not allow metadata to be associated with
 * a VariableDeclaration, and currently we don't record comments for it either.
 * Consider changing the class hierarchy so that [VariableDeclaration] does not
 * extend [Declaration].
 */
class VariableDeclaration extends Declaration {
  /**
   * The name of the variable being declared.
   */
  SimpleIdentifier _name;

  /**
   * The equal sign separating the variable name from the initial value, or
   * `null` if the initial value was not specified.
   */
  Token equals;

  /**
   * The expression used to compute the initial value for the variable, or
   * `null` if the initial value was not specified.
   */
  Expression _initializer;

  /**
   * Initialize a newly created variable declaration. The [equals] and
   * [initializer] can be `null` if there is no initializer.
   */
  VariableDeclaration(
      SimpleIdentifier name, this.equals, Expression initializer)
      : super(null, null) {
    _name = _becomeParentOf(name);
    _initializer = _becomeParentOf(initializer);
  }

  @override
  Iterable get childEntities => super._childEntities
    ..add(_name)
    ..add(equals)
    ..add(_initializer);

  /**
   * This overridden implementation of getDocumentationComment() looks in the
   * grandparent node for dartdoc comments if no documentation is specifically
   * available on the node.
   */
  @override
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

  @override
  VariableElement get element =>
      _name != null ? (_name.staticElement as VariableElement) : null;

  @override
  Token get endToken {
    if (_initializer != null) {
      return _initializer.endToken;
    }
    return _name.endToken;
  }

  @override
  Token get firstTokenAfterCommentAndMetadata => _name.beginToken;

  /**
   * Return the expression used to compute the initial value for the variable,
   * or `null` if the initial value was not specified.
   */
  Expression get initializer => _initializer;

  /**
   * Set the expression used to compute the initial value for the variable to
   * the given [expression].
   */
  void set initializer(Expression expression) {
    _initializer = _becomeParentOf(expression);
  }

  /**
   * Return `true` if this variable was declared with the 'const' modifier.
   */
  bool get isConst {
    AstNode parent = this.parent;
    return parent is VariableDeclarationList && parent.isConst;
  }

  /**
   * Return `true` if this variable was declared with the 'final' modifier.
   * Variables that are declared with the 'const' modifier will return `false`
   * even though they are implicitly final.
   */
  bool get isFinal {
    AstNode parent = this.parent;
    return parent is VariableDeclarationList && parent.isFinal;
  }

  /**
   * Return the name of the variable being declared.
   */
  SimpleIdentifier get name => _name;

  /**
   * Set the name of the variable being declared to the given [identifier].
   */
  void set name(SimpleIdentifier identifier) {
    _name = _becomeParentOf(identifier);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitVariableDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_name, visitor);
    _safelyVisitChild(_initializer, visitor);
  }
}

/**
 * The declaration of one or more variables of the same type.
 *
 * > variableDeclarationList ::=
 * >     finalConstVarOrType [VariableDeclaration] (',' [VariableDeclaration])*
 * >
 * > finalConstVarOrType ::=
 * >   | 'final' [TypeName]?
 * >   | 'const' [TypeName]?
 * >   | 'var'
 * >   | [TypeName]
 */
class VariableDeclarationList extends AnnotatedNode {
  /**
   * The token representing the 'final', 'const' or 'var' keyword, or `null` if
   * no keyword was included.
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
   * Initialize a newly created variable declaration list. Either or both of the
   * [comment] and [metadata] can be `null` if the variable list does not have
   * the corresponding attribute. The [keyword] can be `null` if a type was
   * specified. The [type] must be `null` if the keyword is 'var'.
   */
  VariableDeclarationList(Comment comment, List<Annotation> metadata,
      this.keyword, TypeName type, List<VariableDeclaration> variables)
      : super(comment, metadata) {
    _type = _becomeParentOf(type);
    _variables = new NodeList<VariableDeclaration>(this, variables);
  }

  /**
   * TODO(paulberry): include commas.
   */
  @override
  Iterable get childEntities => super._childEntities
    ..add(keyword)
    ..add(_type)
    ..addAll(_variables);

  @override
  Token get endToken => _variables.endToken;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (keyword != null) {
      return keyword;
    } else if (_type != null) {
      return _type.beginToken;
    }
    return _variables.beginToken;
  }

  /**
   * Return `true` if the variables in this list were declared with the 'const'
   * modifier.
   */
  bool get isConst => keyword is KeywordToken &&
      (keyword as KeywordToken).keyword == Keyword.CONST;

  /**
   * Return `true` if the variables in this list were declared with the 'final'
   * modifier. Variables that are declared with the 'const' modifier will return
   * `false` even though they are implicitly final. (In other words, this is a
   * syntactic check rather than a semantic check.)
   */
  bool get isFinal => keyword is KeywordToken &&
      (keyword as KeywordToken).keyword == Keyword.FINAL;

  /**
   * Return the type of the variables being declared, or `null` if no type was
   * provided.
   */
  TypeName get type => _type;

  /**
   * Set the type of the variables being declared to the given [typeName].
   */
  void set type(TypeName typeName) {
    _type = _becomeParentOf(typeName);
  }

  /**
   * Return a list containing the individual variables being declared.
   */
  NodeList<VariableDeclaration> get variables => _variables;

  @override
  accept(AstVisitor visitor) => visitor.visitVariableDeclarationList(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_type, visitor);
    _variables.accept(visitor);
  }
}

/**
 * A list of variables that are being declared in a context where a statement is
 * required.
 *
 * > variableDeclarationStatement ::=
 * >     [VariableDeclarationList] ';'
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
   */
  VariableDeclarationStatement(
      VariableDeclarationList variableList, this.semicolon) {
    _variableList = _becomeParentOf(variableList);
  }

  @override
  Token get beginToken => _variableList.beginToken;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(_variableList)
    ..add(semicolon);

  @override
  Token get endToken => semicolon;

  /**
   * Return the variables being declared.
   */
  VariableDeclarationList get variables => _variableList;

  /**
   * Set the variables being declared to the given list of [variables].
   */
  void set variables(VariableDeclarationList variables) {
    _variableList = _becomeParentOf(variables);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitVariableDeclarationStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_variableList, visitor);
  }
}

/**
 * A while statement.
 *
 * > whileStatement ::=
 * >     'while' '(' [Expression] ')' [Statement]
 */
class WhileStatement extends Statement {
  /**
   * The token representing the 'while' keyword.
   */
  Token whileKeyword;

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
   */
  WhileStatement(this.whileKeyword, this.leftParenthesis, Expression condition,
      this.rightParenthesis, Statement body) {
    _condition = _becomeParentOf(condition);
    _body = _becomeParentOf(body);
  }

  @override
  Token get beginToken => whileKeyword;

  /**
   * Return the body of the loop.
   */
  Statement get body => _body;

  /**
   * Set the body of the loop to the given [statement].
   */
  void set body(Statement statement) {
    _body = _becomeParentOf(statement);
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(whileKeyword)
    ..add(leftParenthesis)
    ..add(_condition)
    ..add(rightParenthesis)
    ..add(_body);

  /**
   * Return the expression used to determine whether to execute the body of the
   * loop.
   */
  Expression get condition => _condition;

  /**
   * Set the expression used to determine whether to execute the body of the
   * loop to the given [expression].
   */
  void set condition(Expression expression) {
    _condition = _becomeParentOf(expression);
  }

  @override
  Token get endToken => _body.endToken;

  /**
   * Return the token representing the 'while' keyword.
   */
  @deprecated // Use "this.whileKeyword"
  Token get keyword => whileKeyword;

  /**
   * Set the token representing the 'while' keyword to the given [token].
   */
  @deprecated // Use "this.whileKeyword"
  set keyword(Token token) {
    whileKeyword = token;
  }

  @override
  accept(AstVisitor visitor) => visitor.visitWhileStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_condition, visitor);
    _safelyVisitChild(_body, visitor);
  }
}

/**
 * The with clause in a class declaration.
 *
 * > withClause ::=
 * >     'with' [TypeName] (',' [TypeName])*
 */
class WithClause extends AstNode {
  /**
   * The token representing the 'with' keyword.
   */
  Token withKeyword;

  /**
   * The names of the mixins that were specified.
   */
  NodeList<TypeName> _mixinTypes;

  /**
   * Initialize a newly created with clause.
   */
  WithClause(this.withKeyword, List<TypeName> mixinTypes) {
    _mixinTypes = new NodeList<TypeName>(this, mixinTypes);
  }

  @override
  Token get beginToken => withKeyword;

  /**
   * TODO(paulberry): add commas.
   */
  @override
  Iterable get childEntities => new ChildEntities()
    ..add(withKeyword)
    ..addAll(_mixinTypes);

  @override
  Token get endToken => _mixinTypes.endToken;

  /**
   * Set the token representing the 'with' keyword to the given [token].
   */
  @deprecated // Use "this.withKeyword"
  void set mixinKeyword(Token token) {
    this.withKeyword = token;
  }

  /**
   * Return the names of the mixins that were specified.
   */
  NodeList<TypeName> get mixinTypes => _mixinTypes;

  @override
  accept(AstVisitor visitor) => visitor.visitWithClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _mixinTypes.accept(visitor);
  }
}

/**
 * A yield statement.
 *
 * > yieldStatement ::=
 * >     'yield' '*'? [Expression] ‘;’
 */
class YieldStatement extends Statement {
  /**
   * The 'yield' keyword.
   */
  Token yieldKeyword;

  /**
   * The star optionally following the 'yield' keyword.
   */
  Token star;

  /**
   * The expression whose value will be yielded.
   */
  Expression _expression;

  /**
   * The semicolon following the expression.
   */
  Token semicolon;

  /**
   * Initialize a newly created yield expression. The [star] can be `null` if no
   * star was provided.
   */
  YieldStatement(
      this.yieldKeyword, this.star, Expression expression, this.semicolon) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Token get beginToken {
    if (yieldKeyword != null) {
      return yieldKeyword;
    }
    return _expression.beginToken;
  }

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(yieldKeyword)
    ..add(star)
    ..add(_expression)
    ..add(semicolon);

  @override
  Token get endToken {
    if (semicolon != null) {
      return semicolon;
    }
    return _expression.endToken;
  }

  /**
   * Return the expression whose value will be yielded.
   */
  Expression get expression => _expression;

  /**
   * Set the expression whose value will be yielded to the given [expression].
   */
  void set expression(Expression expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitYieldStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_expression, visitor);
  }
}
