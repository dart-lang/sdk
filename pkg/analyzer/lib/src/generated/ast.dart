// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.ast;

import 'dart:collection';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart' show LineInfo, Source;
import 'package:analyzer/src/generated/utilities_dart.dart';

export 'package:analyzer/dart/ast/visitor.dart';
export 'package:analyzer/src/dart/ast/utilities.dart';

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

  @override
  // TODO(paulberry): Add commas.
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
  Iterable get childEntities =>
      new ChildEntities()..add(_expression)..add(asOperator)..add(_type);

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
   * The comma, if a message expression was supplied.  Otherwise `null`.
   */
  Token comma;

  /**
   * The message to report if the assertion fails.  `null` if no message was
   * supplied.
   */
  Expression _message;

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
  AssertStatement(
      this.assertKeyword,
      this.leftParenthesis,
      Expression condition,
      this.comma,
      Expression message,
      this.rightParenthesis,
      this.semicolon) {
    _condition = _becomeParentOf(condition);
    _message = _becomeParentOf(message);
  }

  @override
  Token get beginToken => assertKeyword;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(assertKeyword)
    ..add(leftParenthesis)
    ..add(_condition)
    ..add(comma)
    ..add(_message)
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
   * Return the message to report if the assertion fails.
   */
  Expression get message => _message;

  /**
   * Set the message to report if the assertion fails to the given
   * [expression].
   */
  void set message(Expression expression) {
    _message = _becomeParentOf(expression);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitAssertStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_condition, visitor);
    _safelyVisitChild(message, visitor);
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
 * A node in the AST structure for a Dart program.
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
  dynamic /*=E*/ accept /*<E>*/ (AstVisitor /*<E>*/ visitor);

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
  Iterable get childEntities =>
      new ChildEntities()..add(awaitKeyword)..add(_expression);

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
  Iterable get childEntities =>
      new ChildEntities()..add(_leftOperand)..add(operator)..add(_rightOperand);

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
  Token get beginToken {
    if (keyword != null) {
      return keyword;
    }
    return _block.beginToken;
  }

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
  Iterable get childEntities =>
      new ChildEntities()..add(keyword)..add(star)..add(_block);

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
  Iterable get childEntities =>
      new ChildEntities()..add(breakKeyword)..add(_label)..add(semicolon);

  @override
  Token get endToken => semicolon;

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
  CatchClause(
      this.onKeyword,
      TypeName exceptionType,
      this.catchKeyword,
      this.leftParenthesis,
      SimpleIdentifier exceptionParameter,
      this.comma,
      SimpleIdentifier stackTraceParameter,
      this.rightParenthesis,
      Block body) {
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
  ClassDeclaration(
      Comment comment,
      List<Annotation> metadata,
      this.abstractKeyword,
      this.classKeyword,
      SimpleIdentifier name,
      TypeParameterList typeParameters,
      ExtendsClause extendsClause,
      WithClause withClause,
      ImplementsClause implementsClause,
      this.leftBracket,
      List<ClassMember> members,
      this.rightBracket)
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
  ClassTypeAlias(
      Comment comment,
      List<Annotation> metadata,
      Token keyword,
      SimpleIdentifier name,
      TypeParameterList typeParameters,
      this.equals,
      this.abstractKeyword,
      TypeName superclass,
      WithClause withClause,
      ImplementsClause implementsClause,
      Token semicolon)
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
  Iterable get childEntities =>
      new ChildEntities()..add(newKeyword)..add(_identifier);

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
  Token endToken;

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
  CompilationUnit(
      this.beginToken,
      ScriptTag scriptTag,
      List<Directive> directives,
      List<CompilationUnitMember> declarations,
      this.endToken) {
    _scriptTag = _becomeParentOf(scriptTag);
    _directives = new NodeList<Directive>(this, directives);
    _declarations = new NodeList<CompilationUnitMember>(this, declarations);
  }

  @override
  Iterable get childEntities {
    ChildEntities result = new ChildEntities()..add(_scriptTag);
    if (_directivesAreBeforeDeclarations) {
      result..addAll(_directives)..addAll(_declarations);
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
 * A configuration in either an import or export directive.
 *
 *     configuration ::=
 *         'if' '(' test ')' uri
 *
 *     test ::=
 *         dottedName ('==' stringLiteral)?
 *
 *     dottedName ::=
 *         identifier ('.' identifier)*
 */
class Configuration extends AstNode {
  Token ifKeyword;
  Token leftParenthesis;
  DottedName _name;
  Token equalToken;
  StringLiteral _value;
  Token rightParenthesis;
  StringLiteral _libraryUri;

  Configuration(
      this.ifKeyword,
      this.leftParenthesis,
      DottedName name,
      this.equalToken,
      StringLiteral value,
      this.rightParenthesis,
      StringLiteral libraryUri) {
    _name = _becomeParentOf(name);
    _value = _becomeParentOf(value);
    _libraryUri = _becomeParentOf(libraryUri);
  }

  @override
  Token get beginToken => ifKeyword;

  @override
  Iterable get childEntities => new ChildEntities()
    ..add(ifKeyword)
    ..add(leftParenthesis)
    ..add(_name)
    ..add(equalToken)
    ..add(_value)
    ..add(rightParenthesis)
    ..add(_libraryUri);

  @override
  Token get endToken => _libraryUri.endToken;

  StringLiteral get libraryUri => _libraryUri;

  void set libraryUri(StringLiteral libraryUri) {
    _libraryUri = _becomeParentOf(libraryUri);
  }

  DottedName get name => _name;

  void set name(DottedName name) {
    _name = _becomeParentOf(name);
  }

  StringLiteral get value => _value;

  void set value(StringLiteral value) {
    _value = _becomeParentOf(value);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitConfiguration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_name, visitor);
    _safelyVisitChild(_value, visitor);
    _safelyVisitChild(_libraryUri, visitor);
  }
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
  ConstructorDeclaration(
      Comment comment,
      List<Annotation> metadata,
      this.externalKeyword,
      this.constKeyword,
      this.factoryKeyword,
      Identifier returnType,
      this.period,
      SimpleIdentifier name,
      FormalParameterList parameters,
      this.separator,
      List<ConstructorInitializer> initializers,
      ConstructorName redirectedConstructor,
      FunctionBody body)
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
 * >   | [RedirectingConstructorInvocation]
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
  Iterable get childEntities =>
      new ChildEntities()..add(_type)..add(period)..add(_name);

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
  Iterable get childEntities =>
      new ChildEntities()..add(continueKeyword)..add(_label)..add(semicolon);

  @override
  Token get endToken => semicolon;

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
  Iterable get childEntities =>
      super._childEntities..add(keyword)..add(_type)..add(_identifier);

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
  bool get isConst =>
      (keyword is KeywordToken) &&
      (keyword as KeywordToken).keyword == Keyword.CONST;

  /**
   * Return `true` if this variable was declared with the 'final' modifier.
   * Variables that are declared with the 'const' modifier will return `false`
   * even though they are implicitly final.
   */
  bool get isFinal =>
      (keyword is KeywordToken) &&
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
  Iterable get childEntities =>
      new ChildEntities()..add(_parameter)..add(separator)..add(_defaultValue);

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

  @override
  NodeList<Annotation> get metadata => _parameter.metadata;

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
  DoStatement(
      this.doKeyword,
      Statement body,
      this.whileKeyword,
      this.leftParenthesis,
      Expression condition,
      this.rightParenthesis,
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
 * A dotted name, used in a configuration within an import or export directive.
 *
 * > dottedName ::=
 * >     [SimpleIdentifier] ('.' [SimpleIdentifier])*
 */
class DottedName extends AstNode {
  /**
   * The components of the identifier.
   */
  NodeList<SimpleIdentifier> _components;

  /**
   * Initialize a newly created dotted name.
   */
  DottedName(List<SimpleIdentifier> components) {
    _components = new NodeList<SimpleIdentifier>(this, components);
  }

  @override
  Token get beginToken => _components.beginToken;

  @override
  // TODO(paulberry): add "." tokens.
  Iterable get childEntities => new ChildEntities()..addAll(_components);

  /**
   * Return the components of the identifier.
   */
  NodeList<SimpleIdentifier> get components => _components;

  @override
  Token get endToken => _components.endToken;

  @override
  accept(AstVisitor visitor) => visitor.visitDottedName(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _components.accept(visitor);
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
  EnumDeclaration(
      Comment comment,
      List<Annotation> metadata,
      this.enumKeyword,
      SimpleIdentifier name,
      this.leftBracket,
      List<EnumConstantDeclaration> constants,
      this.rightBracket)
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
  ExportDirective(
      Comment comment,
      List<Annotation> metadata,
      Token keyword,
      StringLiteral libraryUri,
      List<Configuration> configurations,
      List<Combinator> combinators,
      Token semicolon)
      : super(comment, metadata, keyword, libraryUri, configurations,
            combinators, semicolon);

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
  Iterable get childEntities =>
      new ChildEntities()..add(_expression)..add(semicolon);

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
  Iterable get childEntities =>
      new ChildEntities()..add(extendsKeyword)..add(_superclass);

  @override
  Token get endToken => _superclass.endToken;

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
  Iterable get childEntities =>
      super._childEntities..add(staticKeyword)..add(_fieldList)..add(semicolon);

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
 * >     'this' '.' [SimpleIdentifier] ([TypeParameterList]? [FormalParameterList])?
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
   * The type parameters associated with the method, or `null` if the method is
   * not a generic method.
   */
  TypeParameterList _typeParameters;

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
  FieldFormalParameter(
      Comment comment,
      List<Annotation> metadata,
      this.keyword,
      TypeName type,
      this.thisKeyword,
      this.period,
      SimpleIdentifier identifier,
      TypeParameterList typeParameters,
      FormalParameterList parameters)
      : super(comment, metadata, identifier) {
    _type = _becomeParentOf(type);
    _typeParameters = _becomeParentOf(typeParameters);
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
  bool get isConst =>
      (keyword is KeywordToken) &&
      (keyword as KeywordToken).keyword == Keyword.CONST;

  @override
  bool get isFinal =>
      (keyword is KeywordToken) &&
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

  /**
   * Return the type parameters associated with this method, or `null` if this
   * method is not a generic method.
   */
  TypeParameterList get typeParameters => _typeParameters;

  /**
   * Set the type parameters associated with this method to the given
   * [typeParameters].
   */
  void set typeParameters(TypeParameterList typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitFieldFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_type, visitor);
    _safelyVisitChild(identifier, visitor);
    _safelyVisitChild(_typeParameters, visitor);
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
   * Initialize a newly created for-each statement whose loop control variable
   * is declared internally (in the for-loop part). The [awaitKeyword] can be
   * `null` if this is not an asynchronous for loop.
   */
  ForEachStatement.withDeclaration(
      this.awaitKeyword,
      this.forKeyword,
      this.leftParenthesis,
      DeclaredIdentifier loopVariable,
      this.inKeyword,
      Expression iterator,
      this.rightParenthesis,
      Statement body) {
    _loopVariable = _becomeParentOf(loopVariable);
    _iterable = _becomeParentOf(iterator);
    _body = _becomeParentOf(body);
  }

  /**
   * Initialize a newly created for-each statement whose loop control variable
   * is declared outside the for loop. The [awaitKeyword] can be `null` if this
   * is not an asynchronous for loop.
   */
  ForEachStatement.withReference(
      this.awaitKeyword,
      this.forKeyword,
      this.leftParenthesis,
      SimpleIdentifier identifier,
      this.inKeyword,
      Expression iterator,
      this.rightParenthesis,
      Statement body) {
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
    return result..add(rightDelimiter)..add(rightParenthesis);
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
  ForStatement(
      this.forKeyword,
      this.leftParenthesis,
      VariableDeclarationList variableList,
      Expression initialization,
      this.leftSeparator,
      Expression condition,
      this.rightSeparator,
      List<Expression> updaters,
      this.rightParenthesis,
      Statement body) {
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
  FunctionDeclaration(
      Comment comment,
      List<Annotation> metadata,
      this.externalKeyword,
      TypeName returnType,
      this.propertyKeyword,
      SimpleIdentifier name,
      FunctionExpression functionExpression)
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
  bool get isGetter =>
      propertyKeyword != null &&
      (propertyKeyword as KeywordToken).keyword == Keyword.GET;

  /**
   * Return `true` if this function declares a setter.
   */
  bool get isSetter =>
      propertyKeyword != null &&
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
 * >     [TypeParameterList]? [FormalParameterList] [FunctionBody]
 */
class FunctionExpression extends Expression {
  /**
   * The type parameters associated with the method, or `null` if the method is
   * not a generic method.
   */
  TypeParameterList _typeParameters;

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
  FunctionExpression(TypeParameterList typeParameters,
      FormalParameterList parameters, FunctionBody body) {
    _typeParameters = _becomeParentOf(typeParameters);
    _parameters = _becomeParentOf(parameters);
    _body = _becomeParentOf(body);
  }

  @override
  Token get beginToken {
    if (_typeParameters != null) {
      return _typeParameters.beginToken;
    } else if (_parameters != null) {
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
  Iterable get childEntities =>
      new ChildEntities()..add(_parameters)..add(_body);

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

  /**
   * Return the type parameters associated with this method, or `null` if this
   * method is not a generic method.
   */
  TypeParameterList get typeParameters => _typeParameters;

  /**
   * Set the type parameters associated with this method to the given
   * [typeParameters].
   */
  void set typeParameters(TypeParameterList typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitFunctionExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_typeParameters, visitor);
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
 * > functionExpressionInvocation ::=
 * >     [Expression] [TypeArgumentList]? [ArgumentList]
 */
class FunctionExpressionInvocation extends Expression {
  /**
   * The expression producing the function being invoked.
   */
  Expression _function;

  /**
   * The type arguments to be applied to the method being invoked, or `null` if
   * no type arguments were provided.
   */
  TypeArgumentList _typeArguments;

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
  FunctionExpressionInvocation(Expression function,
      TypeArgumentList typeArguments, ArgumentList argumentList) {
    _function = _becomeParentOf(function);
    _typeArguments = _becomeParentOf(typeArguments);
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
  Iterable get childEntities =>
      new ChildEntities()..add(_function)..add(_argumentList);

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

  /**
   * Return the type arguments to be applied to the method being invoked, or
   * `null` if no type arguments were provided.
   */
  TypeArgumentList get typeArguments => _typeArguments;

  /**
   * Set the type arguments to be applied to the method being invoked to the
   * given [typeArguments].
   */
  void set typeArguments(TypeArgumentList typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitFunctionExpressionInvocation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_function, visitor);
    _safelyVisitChild(_typeArguments, visitor);
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
  FunctionTypeAlias(
      Comment comment,
      List<Annotation> metadata,
      Token keyword,
      TypeName returnType,
      SimpleIdentifier name,
      TypeParameterList typeParameters,
      FormalParameterList parameters,
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
 * >     [TypeName]? [SimpleIdentifier] [TypeParameterList]? [FormalParameterList]
 */
class FunctionTypedFormalParameter extends NormalFormalParameter {
  /**
   * The return type of the function, or `null` if the function does not have a
   * return type.
   */
  TypeName _returnType;

  /**
   * The type parameters associated with the function, or `null` if the function
   * is not a generic function.
   */
  TypeParameterList _typeParameters;

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
  FunctionTypedFormalParameter(
      Comment comment,
      List<Annotation> metadata,
      TypeName returnType,
      SimpleIdentifier identifier,
      TypeParameterList typeParameters,
      FormalParameterList parameters)
      : super(comment, metadata, identifier) {
    _returnType = _becomeParentOf(returnType);
    _typeParameters = _becomeParentOf(typeParameters);
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
  Iterable get childEntities =>
      super._childEntities..add(_returnType)..add(identifier)..add(parameters);

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

  /**
   * Return the type parameters associated with this function, or `null` if
   * this function is not a generic function.
   */
  TypeParameterList get typeParameters => _typeParameters;

  /**
   * Set the type parameters associated with this method to the given
   * [typeParameters].
   */
  void set typeParameters(TypeParameterList typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitFunctionTypedFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_returnType, visitor);
    _safelyVisitChild(identifier, visitor);
    _safelyVisitChild(_typeParameters, visitor);
    _safelyVisitChild(_parameters, visitor);
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
  IfStatement(
      this.ifKeyword,
      this.leftParenthesis,
      Expression condition,
      this.rightParenthesis,
      Statement thenStatement,
      this.elseKeyword,
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

  @override
  // TODO(paulberry): add commas.
  Iterable get childEntities => new ChildEntities()
    ..add(implementsKeyword)
    ..addAll(interfaces);

  @override
  Token get endToken => _interfaces.endToken;

  /**
   * Return the list of the interfaces that are being implemented.
   */
  NodeList<TypeName> get interfaces => _interfaces;

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
  ImportDirective(
      Comment comment,
      List<Annotation> metadata,
      Token keyword,
      StringLiteral libraryUri,
      List<Configuration> configurations,
      this.deferredKeyword,
      this.asKeyword,
      SimpleIdentifier prefix,
      List<Combinator> combinators,
      Token semicolon)
      : super(comment, metadata, keyword, libraryUri, configurations,
            combinators, semicolon) {
    _prefix = _becomeParentOf(prefix);
  }

  @override
  Iterable get childEntities => super._childEntities
    ..add(_uri)
    ..add(deferredKeyword)
    ..add(asKeyword)
    ..add(_prefix)
    ..addAll(combinators)
    ..add(semicolon);

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
   * Return `true` if this creation expression is used to invoke a constant
   * constructor.
   */
  bool get isConst =>
      keyword is KeywordToken &&
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
 * >   | hexadecimalIntegerLiteral
 * >
 * > decimalIntegerLiteral ::=
 * >     decimalDigit+
 * >
 * > hexadecimalIntegerLiteral ::=
 * >     '0x' hexadecimalDigit+
 * >   | '0X' hexadecimalDigit+
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
  String value;

  /**
   * Initialize a newly created string of characters that are part of a string
   * interpolation.
   */
  InterpolationString(this.contents, this.value);

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
  Iterable get childEntities => new ChildEntities()..add(_label)..add(colon);

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
  Iterable get childEntities =>
      super._childEntities..add(libraryKeyword)..add(_name)..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => libraryKeyword;

  @override
  Token get keyword => libraryKeyword;

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

  @override
  // TODO(paulberry): add "." tokens.
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

  @override
  // TODO(paulberry): add commas.
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

  @override
  // TODO(paulberry): add commas.
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
  Iterable get childEntities =>
      new ChildEntities()..add(_key)..add(separator)..add(_value);

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
 * >     methodName [TypeParameterList] [FormalParameterList]
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
   * The type parameters associated with the method, or `null` if the method is
   * not a generic method.
   */
  TypeParameterList _typeParameters;

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
  MethodDeclaration(
      Comment comment,
      List<Annotation> metadata,
      this.externalKeyword,
      this.modifierKeyword,
      TypeName returnType,
      this.propertyKeyword,
      this.operatorKeyword,
      SimpleIdentifier name,
      TypeParameterList typeParameters,
      FormalParameterList parameters,
      FunctionBody body)
      : super(comment, metadata) {
    _returnType = _becomeParentOf(returnType);
    _name = _becomeParentOf(name);
    _typeParameters = _becomeParentOf(typeParameters);
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
  bool get isGetter =>
      propertyKeyword != null &&
      (propertyKeyword as KeywordToken).keyword == Keyword.GET;

  /**
   * Return `true` if this method declares an operator.
   */
  bool get isOperator => operatorKeyword != null;

  /**
   * Return `true` if this method declares a setter.
   */
  bool get isSetter =>
      propertyKeyword != null &&
      (propertyKeyword as KeywordToken).keyword == Keyword.SET;

  /**
   * Return `true` if this method is declared to be a static method.
   */
  bool get isStatic =>
      modifierKeyword != null &&
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

  /**
   * Return the type parameters associated with this method, or `null` if this
   * method is not a generic method.
   */
  TypeParameterList get typeParameters => _typeParameters;

  /**
   * Set the type parameters associated with this method to the given
   * [typeParameters].
   */
  void set typeParameters(TypeParameterList typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitMethodDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _safelyVisitChild(_returnType, visitor);
    _safelyVisitChild(_name, visitor);
    _safelyVisitChild(_typeParameters, visitor);
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
 * > methodInvocation ::=
 * >     ([Expression] '.')? [SimpleIdentifier] [TypeArgumentList]? [ArgumentList]
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
   * The type arguments to be applied to the method being invoked, or `null` if
   * no type arguments were provided.
   */
  TypeArgumentList _typeArguments;

  /**
   * The list of arguments to the method.
   */
  ArgumentList _argumentList;

  /**
   * Initialize a newly created method invocation. The [target] and [operator]
   * can be `null` if there is no target.
   */
  MethodInvocation(
      Expression target,
      this.operator,
      SimpleIdentifier methodName,
      TypeArgumentList typeArguments,
      ArgumentList argumentList) {
    _target = _becomeParentOf(target);
    _methodName = _becomeParentOf(methodName);
    _typeArguments = _becomeParentOf(typeArguments);
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

  /**
   * Return the type arguments to be applied to the method being invoked, or
   * `null` if no type arguments were provided.
   */
  TypeArgumentList get typeArguments => _typeArguments;

  /**
   * Set the type arguments to be applied to the method being invoked to the
   * given [typeArguments].
   */
  void set typeArguments(TypeArgumentList typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @override
  accept(AstVisitor visitor) => visitor.visitMethodInvocation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_target, visitor);
    _safelyVisitChild(_methodName, visitor);
    _safelyVisitChild(_typeArguments, visitor);
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
  Iterable get childEntities =>
      new ChildEntities()..add(_name)..add(_expression);

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
   * The configurations used to control which library will actually be loaded at
   * run-time.
   */
  NodeList<Configuration> _configurations;

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
  NamespaceDirective(
      Comment comment,
      List<Annotation> metadata,
      this.keyword,
      StringLiteral libraryUri,
      List<Configuration> configurations,
      List<Combinator> combinators,
      this.semicolon)
      : super(comment, metadata, libraryUri) {
    _configurations = new NodeList<Configuration>(this, configurations);
    _combinators = new NodeList<Combinator>(this, combinators);
  }

  /**
   * Return the combinators used to control how names are imported or exported.
   */
  NodeList<Combinator> get combinators => _combinators;

  /**
   * Return the configurations used to control which library will actually be
   * loaded at run-time.
   */
  NodeList<Configuration> get configurations => _configurations;

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
  Iterable get childEntities =>
      new ChildEntities()..add(nativeKeyword)..add(_name);

  @override
  Token get endToken => _name.endToken;

  /**
   * Return the name of the native object that implements the class.
   */
  StringLiteral get name => _name;

  /**
   * Set the name of the native object that implements the class to the given
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
  @override
  void set length(int newLength) {
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

  @override
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
  Iterable get childEntities =>
      super._childEntities..add(partKeyword)..add(_uri)..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => partKeyword;

  @override
  Token get keyword => partKeyword;

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
  Iterable get childEntities =>
      new ChildEntities()..add(_operand)..add(operator);

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
  Iterable get childEntities =>
      new ChildEntities()..add(_prefix)..add(period)..add(_identifier);

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
  Iterable get childEntities =>
      new ChildEntities()..add(operator)..add(_operand);

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
  Iterable get childEntities =>
      new ChildEntities()..add(_target)..add(operator)..add(_propertyName);

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
  Iterable get childEntities =>
      new ChildEntities()..add(returnKeyword)..add(_expression)..add(semicolon);

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

  @override
  accept(AstVisitor visitor) => visitor.visitReturnStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _safelyVisitChild(_expression, visitor);
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

  @override
  // TODO(paulberry): add commas.
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
  Iterable get childEntities =>
      super._childEntities..add(keyword)..add(_type)..add(identifier);

  @override
  Token get endToken => identifier.endToken;

  @override
  bool get isConst =>
      (keyword is KeywordToken) &&
      (keyword as KeywordToken).keyword == Keyword.CONST;

  @override
  bool get isFinal =>
      (keyword is KeywordToken) &&
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
   * Return `true` if this identifier is the "name" part of a prefixed
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
   * Return `true` if this string literal uses single quotes (' or ''').
   * Return `false` if this string literal uses double quotes (" or """).
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
  SwitchStatement(
      this.switchKeyword,
      this.leftParenthesis,
      Expression expression,
      this.rightParenthesis,
      this.leftBracket,
      List<SwitchMember> members,
      this.rightBracket) {
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

  @override
  // TODO(paulberry): add "." tokens.
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
  Iterable get childEntities =>
      new ChildEntities()..add(throwKeyword)..add(_expression);

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
  Iterable get childEntities =>
      super._childEntities..add(_variableList)..add(semicolon);

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

  @override
  // TODO(paulberry): Add commas.
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

  ChildEntities get _childEntities =>
      new ChildEntities()..add(constKeyword)..add(_typeArguments);

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
  Iterable get childEntities =>
      new ChildEntities()..add(_name)..add(_typeArguments);

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
  Iterable get childEntities =>
      super._childEntities..add(_name)..add(extendsKeyword)..add(_bound);

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
  Iterable get childEntities =>
      super._childEntities..add(_name)..add(equals)..add(_initializer);

  /**
   * This overridden implementation of getDocumentationComment() looks in the
   * grandparent node for Dartdoc comments if no documentation is specifically
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

  @override
  // TODO(paulberry): include commas.
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
  bool get isConst =>
      keyword is KeywordToken &&
      (keyword as KeywordToken).keyword == Keyword.CONST;

  /**
   * Return `true` if the variables in this list were declared with the 'final'
   * modifier. Variables that are declared with the 'const' modifier will return
   * `false` even though they are implicitly final. (In other words, this is a
   * syntactic check rather than a semantic check.)
   */
  bool get isFinal =>
      keyword is KeywordToken &&
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
  Iterable get childEntities =>
      new ChildEntities()..add(_variableList)..add(semicolon);

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

  @override
  // TODO(paulberry): add commas.
  Iterable get childEntities => new ChildEntities()
    ..add(withKeyword)
    ..addAll(_mixinTypes);

  @override
  Token get endToken => _mixinTypes.endToken;

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
