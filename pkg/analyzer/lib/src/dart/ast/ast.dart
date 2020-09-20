// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/dart/ast/to_source_visitor.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/fasta/token_utils.dart' as util show findPrevious;
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart' show LineInfo, Source;
import 'package:analyzer/src/generated/utilities_dart.dart';

/// Two or more string literals that are implicitly concatenated because of
/// being adjacent (separated only by whitespace).
///
/// While the grammar only allows adjacent strings when all of the strings are
/// of the same kind (single line or multi-line), this class doesn't enforce
/// that restriction.
///
///    adjacentStrings ::=
///        [StringLiteral] [StringLiteral]+
class AdjacentStringsImpl extends StringLiteralImpl implements AdjacentStrings {
  /// The strings that are implicitly concatenated.
  NodeList<StringLiteral> _strings;

  /// Initialize a newly created list of adjacent strings. To be syntactically
  /// valid, the list of [strings] must contain at least two elements.
  AdjacentStringsImpl(List<StringLiteral> strings) {
    _strings = NodeListImpl<StringLiteral>(this, strings);
  }

  @override
  Token get beginToken => _strings.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..addAll(_strings);

  @override
  Token get endToken => _strings.endToken;

  @override
  NodeList<StringLiteral> get strings => _strings;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitAdjacentStrings(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _strings.accept(visitor);
  }

  @override
  void _appendStringValue(StringBuffer buffer) {
    int length = strings.length;
    for (int i = 0; i < length; i++) {
      StringLiteralImpl stringLiteral = strings[i];
      stringLiteral._appendStringValue(buffer);
    }
  }
}

/// An AST node that can be annotated with both a documentation comment and a
/// list of annotations.
abstract class AnnotatedNodeImpl extends AstNodeImpl implements AnnotatedNode {
  /// The documentation comment associated with this node, or `null` if this
  /// node does not have a documentation comment associated with it.
  CommentImpl _comment;

  /// The annotations associated with this node.
  NodeList<Annotation> _metadata;

  /// Initialize a newly created annotated node. Either or both of the [comment]
  /// and [metadata] can be `null` if the node does not have the corresponding
  /// attribute.
  AnnotatedNodeImpl(CommentImpl comment, List<Annotation> metadata) {
    _comment = _becomeParentOf(comment);
    _metadata = NodeListImpl<Annotation>(this, metadata);
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

  @override
  Comment get documentationComment => _comment;

  @override
  set documentationComment(Comment comment) {
    _comment = _becomeParentOf(comment as CommentImpl);
  }

  @override
  NodeList<Annotation> get metadata => _metadata;

  @override
  List<AstNode> get sortedCommentAndAnnotations {
    return <AstNode>[]
      ..add(_comment)
      ..addAll(_metadata)
      ..sort(AstNode.LEXICAL_ORDER);
  }

  /// Return a holder of child entities that subclasses can add to.
  ChildEntities get _childEntities {
    ChildEntities result = ChildEntities();
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
      _comment?.accept(visitor);
      _metadata.accept(visitor);
    } else {
      List<AstNode> children = sortedCommentAndAnnotations;
      int length = children.length;
      for (int i = 0; i < length; i++) {
        children[i].accept(visitor);
      }
    }
  }

  /// Return `true` if there are no annotations before the comment. Note that a
  /// result of `true` does not imply that there is a comment, nor that there
  /// are annotations associated with this node.
  bool _commentIsBeforeAnnotations() {
    if (_comment == null || _metadata.isEmpty) {
      return true;
    }
    Annotation firstAnnotation = _metadata[0];
    return _comment.offset < firstAnnotation.offset;
  }
}

/// An annotation that can be associated with an AST node.
///
///    metadata ::=
///        annotation*
///
///    annotation ::=
///        '@' [Identifier] ('.' [SimpleIdentifier])? [ArgumentList]?
class AnnotationImpl extends AstNodeImpl implements Annotation {
  /// The at sign that introduced the annotation.
  @override
  Token atSign;

  /// The name of the class defining the constructor that is being invoked or
  /// the name of the field that is being referenced.
  IdentifierImpl _name;

  /// The period before the constructor name, or `null` if this annotation is
  /// not the invocation of a named constructor.
  @override
  Token period;

  /// The name of the constructor being invoked, or `null` if this annotation is
  /// not the invocation of a named constructor.
  SimpleIdentifierImpl _constructorName;

  /// The arguments to the constructor being invoked, or `null` if this
  /// annotation is not the invocation of a constructor.
  ArgumentListImpl _arguments;

  /// The element associated with this annotation, or `null` if the AST
  /// structure has not been resolved or if this annotation could not be
  /// resolved.
  Element _element;

  /// The element annotation representing this annotation in the element model.
  @override
  ElementAnnotation elementAnnotation;

  /// Initialize a newly created annotation. Both the [period] and the
  /// [constructorName] can be `null` if the annotation is not referencing a
  /// named constructor. The [arguments] can be `null` if the annotation is not
  /// referencing a constructor.
  AnnotationImpl(this.atSign, IdentifierImpl name, this.period,
      SimpleIdentifierImpl constructorName, ArgumentListImpl arguments) {
    _name = _becomeParentOf(name);
    _constructorName = _becomeParentOf(constructorName);
    _arguments = _becomeParentOf(arguments);
  }

  @override
  ArgumentList get arguments => _arguments;

  @override
  set arguments(ArgumentList arguments) {
    _arguments = _becomeParentOf(arguments as ArgumentListImpl);
  }

  @override
  Token get beginToken => atSign;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(atSign)
    ..add(_name)
    ..add(period)
    ..add(_constructorName)
    ..add(_arguments);

  @override
  SimpleIdentifier get constructorName => _constructorName;

  @override
  set constructorName(SimpleIdentifier name) {
    _constructorName = _becomeParentOf(name as SimpleIdentifierImpl);
  }

  @override
  Element get element {
    if (_element != null) {
      return _element;
    } else if (_constructorName == null && _name != null) {
      return _name.staticElement;
    }
    return null;
  }

  @override
  set element(Element element) {
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

  @override
  Identifier get name => _name;

  @override
  set name(Identifier name) {
    _name = _becomeParentOf(name as IdentifierImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitAnnotation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _name?.accept(visitor);
    _constructorName?.accept(visitor);
    _arguments?.accept(visitor);
  }
}

/// A list of arguments in the invocation of an executable element (that is, a
/// function, method, or constructor).
///
///    argumentList ::=
///        '(' arguments? ')'
///
///    arguments ::=
///        [NamedExpression] (',' [NamedExpression])*
///      | [Expression] (',' [Expression])* (',' [NamedExpression])*
class ArgumentListImpl extends AstNodeImpl implements ArgumentList {
  /// The left parenthesis.
  @override
  Token leftParenthesis;

  /// The expressions producing the values of the arguments.
  NodeList<Expression> _arguments;

  /// The right parenthesis.
  @override
  Token rightParenthesis;

  /// A list containing the elements representing the parameters corresponding
  /// to each of the arguments in this list, or `null` if the AST has not been
  /// resolved or if the function or method being invoked could not be
  /// determined based on static type information. The list must be the same
  /// length as the number of arguments, but can contain `null` entries if a
  /// given argument does not correspond to a formal parameter.
  List<ParameterElement> _correspondingStaticParameters;

  /// Initialize a newly created list of arguments. The list of [arguments] can
  /// be `null` if there are no arguments.
  ArgumentListImpl(
      this.leftParenthesis, List<Expression> arguments, this.rightParenthesis) {
    _arguments = NodeListImpl<Expression>(this, arguments);
  }

  @override
  NodeList<Expression> get arguments => _arguments;

  @override
  Token get beginToken => leftParenthesis;

  @override
  // TODO(paulberry): Add commas.
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(leftParenthesis)
    ..addAll(_arguments)
    ..add(rightParenthesis);

  List<ParameterElement> get correspondingStaticParameters =>
      _correspondingStaticParameters;

  @override
  set correspondingStaticParameters(List<ParameterElement> parameters) {
    if (parameters != null && parameters.length != _arguments.length) {
      throw ArgumentError(
          "Expected ${_arguments.length} parameters, not ${parameters.length}");
    }
    _correspondingStaticParameters = parameters;
  }

  @override
  Token get endToken => rightParenthesis;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitArgumentList(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _arguments.accept(visitor);
  }

  /// If
  /// * the given [expression] is a child of this list,
  /// * the AST structure has been resolved,
  /// * the function being invoked is known based on static type information,
  ///   and
  /// * the expression corresponds to one of the parameters of the function
  ///   being invoked,
  /// then return the parameter element representing the parameter to which the
  /// value of the given expression will be bound. Otherwise, return `null`.
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

/// An as expression.
///
///    asExpression ::=
///        [Expression] 'as' [TypeName]
class AsExpressionImpl extends ExpressionImpl implements AsExpression {
  /// The expression used to compute the value being cast.
  ExpressionImpl _expression;

  /// The 'as' operator.
  @override
  Token asOperator;

  /// The type being cast to.
  TypeAnnotationImpl _type;

  /// Initialize a newly created as expression.
  AsExpressionImpl(
      ExpressionImpl expression, this.asOperator, TypeAnnotationImpl type) {
    _expression = _becomeParentOf(expression);
    _type = _becomeParentOf(type);
  }

  @override
  Token get beginToken => _expression.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(_expression)..add(asOperator)..add(_type);

  @override
  Token get endToken => _type.endToken;

  @override
  Expression get expression => _expression;

  @override
  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Precedence get precedence => Precedence.relational;

  @override
  TypeAnnotation get type => _type;

  @override
  set type(TypeAnnotation type) {
    _type = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitAsExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression?.accept(visitor);
    _type?.accept(visitor);
  }
}

/// An assert in the initializer list of a constructor.
///
///    assertInitializer ::=
///        'assert' '(' [Expression] (',' [Expression])? ')'
class AssertInitializerImpl extends ConstructorInitializerImpl
    implements AssertInitializer {
  @override
  Token assertKeyword;

  @override
  Token leftParenthesis;

  /// The condition that is being asserted to be `true`.
  ExpressionImpl _condition;

  @override
  Token comma;

  /// The message to report if the assertion fails, or `null` if no message was
  /// supplied.
  ExpressionImpl _message;

  @override
  Token rightParenthesis;

  /// Initialize a newly created assert initializer.
  AssertInitializerImpl(
      this.assertKeyword,
      this.leftParenthesis,
      ExpressionImpl condition,
      this.comma,
      ExpressionImpl message,
      this.rightParenthesis) {
    _condition = _becomeParentOf(condition);
    _message = _becomeParentOf(message);
  }

  @override
  Token get beginToken => assertKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(assertKeyword)
    ..add(leftParenthesis)
    ..add(_condition)
    ..add(comma)
    ..add(_message)
    ..add(rightParenthesis);

  @override
  Expression get condition => _condition;

  @override
  set condition(Expression condition) {
    _condition = _becomeParentOf(condition as ExpressionImpl);
  }

  @override
  Token get endToken => rightParenthesis;

  @override
  Expression get message => _message;

  @override
  set message(Expression expression) {
    _message = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitAssertInitializer(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _condition?.accept(visitor);
    message?.accept(visitor);
  }
}

/// An assert statement.
///
///    assertStatement ::=
///        'assert' '(' [Expression] ')' ';'
class AssertStatementImpl extends StatementImpl implements AssertStatement {
  @override
  Token assertKeyword;

  @override
  Token leftParenthesis;

  /// The condition that is being asserted to be `true`.
  ExpressionImpl _condition;

  @override
  Token comma;

  /// The message to report if the assertion fails, or `null` if no message was
  /// supplied.
  ExpressionImpl _message;

  @override
  Token rightParenthesis;

  @override
  Token semicolon;

  /// Initialize a newly created assert statement.
  AssertStatementImpl(
      this.assertKeyword,
      this.leftParenthesis,
      ExpressionImpl condition,
      this.comma,
      ExpressionImpl message,
      this.rightParenthesis,
      this.semicolon) {
    _condition = _becomeParentOf(condition);
    _message = _becomeParentOf(message);
  }

  @override
  Token get beginToken => assertKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(assertKeyword)
    ..add(leftParenthesis)
    ..add(_condition)
    ..add(comma)
    ..add(_message)
    ..add(rightParenthesis)
    ..add(semicolon);

  @override
  Expression get condition => _condition;

  @override
  set condition(Expression condition) {
    _condition = _becomeParentOf(condition as ExpressionImpl);
  }

  @override
  Token get endToken => semicolon;

  @override
  Expression get message => _message;

  @override
  set message(Expression expression) {
    _message = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitAssertStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _condition?.accept(visitor);
    message?.accept(visitor);
  }
}

/// An assignment expression.
///
///    assignmentExpression ::=
///        [Expression] operator [Expression]
class AssignmentExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl, CompoundAssignmentExpressionImpl
    implements AssignmentExpression {
  /// The expression used to compute the left hand side.
  ExpressionImpl _leftHandSide;

  /// The assignment operator being applied.
  @override
  Token operator;

  /// The expression used to compute the right hand side.
  ExpressionImpl _rightHandSide;

  /// The element associated with the operator based on the static type of the
  /// left-hand-side, or `null` if the AST structure has not been resolved, if
  /// the operator is not a compound operator, or if the operator could not be
  /// resolved.
  @override
  MethodElement staticElement;

  /// Initialize a newly created assignment expression.
  AssignmentExpressionImpl(ExpressionImpl leftHandSide, this.operator,
      ExpressionImpl rightHandSide) {
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
      // TODO(39284): should this exception be silent?
      AnalysisEngine.instance.instrumentationService.logException(
          SilentException(message, AnalysisException(message), null),
          StackTrace.current);
    }
    _leftHandSide = _becomeParentOf(leftHandSide);
    _rightHandSide = _becomeParentOf(rightHandSide);
  }

  @override
  Token get beginToken => _leftHandSide.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(_leftHandSide)..add(operator)..add(_rightHandSide);

  @override
  Token get endToken => _rightHandSide.endToken;

  @override
  Expression get leftHandSide => _leftHandSide;

  @override
  set leftHandSide(Expression expression) {
    _leftHandSide = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Precedence get precedence => Precedence.assignment;

  @override
  Expression get rightHandSide => _rightHandSide;

  @override
  set rightHandSide(Expression expression) {
    _rightHandSide = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  AstNode get _nullShortingExtensionCandidate => parent;

  /// If the AST structure has been resolved, and the function being invoked is
  /// known based on static type information, then return the parameter element
  /// representing the parameter to which the value of the right operand will be
  /// bound. Otherwise, return `null`.
  ParameterElement get _staticParameterElementForRightHandSide {
    ExecutableElement executableElement;
    if (staticElement != null) {
      executableElement = staticElement;
    } else {
      Expression left = _leftHandSide;
      if (left is Identifier) {
        Element leftElement = left.staticElement;
        if (leftElement is ExecutableElement) {
          executableElement = leftElement;
        }
      } else if (left is PropertyAccess) {
        Element leftElement = left.propertyName.staticElement;
        if (leftElement is ExecutableElement) {
          executableElement = leftElement;
        }
      }
    }
    if (executableElement == null) {
      return null;
    }
    List<ParameterElement> parameters = executableElement.parameters;
    if (parameters.isEmpty) {
      return null;
    }
    return parameters[0];
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitAssignmentExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _leftHandSide?.accept(visitor);
    _rightHandSide?.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression child) =>
      identical(child, _leftHandSide);
}

/// A node in the AST structure for a Dart program.
abstract class AstNodeImpl implements AstNode {
  /// The parent of the node, or `null` if the node is the root of an AST
  /// structure.
  AstNode _parent;

  /// A table mapping the names of properties to their values, or `null` if this
  /// node does not have any properties associated with it.
  Map<String, Object> _propertyMap;

  @override
  int get end => offset + length;

  @override
  bool get isSynthetic => false;

  @override
  int get length {
    Token beginToken = this.beginToken;
    Token endToken = this.endToken;
    if (beginToken == null || endToken == null) {
      return -1;
    }
    return endToken.offset + endToken.length - beginToken.offset;
  }

  @override
  int get offset {
    Token beginToken = this.beginToken;
    if (beginToken == null) {
      return -1;
    }
    return beginToken.offset;
  }

  @override
  AstNode get parent => _parent;

  @override
  AstNode get root {
    AstNode root = this;
    AstNode parent = this.parent;
    while (parent != null) {
      root = parent;
      parent = root.parent;
    }
    return root;
  }

  @override
  Token findPrevious(Token target) =>
      util.findPrevious(beginToken, target) ?? parent?.findPrevious(target);

  @override
  E getProperty<E>(String name) {
    if (_propertyMap == null) {
      return null;
    }
    return _propertyMap[name] as E;
  }

  @override
  void setProperty(String name, Object value) {
    if (value == null) {
      if (_propertyMap != null) {
        _propertyMap.remove(name);
        if (_propertyMap.isEmpty) {
          _propertyMap = null;
        }
      }
    } else {
      _propertyMap ??= HashMap<String, Object>();
      _propertyMap[name] = value;
    }
  }

  @override
  E thisOrAncestorMatching<E extends AstNode>(Predicate<AstNode> predicate) {
    AstNode node = this;
    while (node != null && !predicate(node)) {
      node = node.parent;
    }
    return node as E;
  }

  @override
  E thisOrAncestorOfType<E extends AstNode>() {
    AstNode node = this;
    while (node != null && node is! E) {
      node = node.parent;
    }
    return node as E;
  }

  @override
  String toSource() {
    StringBuffer buffer = StringBuffer();
    accept(ToSourceVisitor(buffer));
    return buffer.toString();
  }

  @override
  String toString() => toSource();

  /// Make this node the parent of the given [child] node. Return the child
  /// node.
  T _becomeParentOf<T extends AstNodeImpl>(T child) {
    if (child != null) {
      child._parent = this;
    }
    return child;
  }
}

/// An await expression.
///
///    awaitExpression ::=
///        'await' [Expression]
class AwaitExpressionImpl extends ExpressionImpl implements AwaitExpression {
  /// The 'await' keyword.
  @override
  Token awaitKeyword;

  /// The expression whose value is being waited on.
  ExpressionImpl _expression;

  /// Initialize a newly created await expression.
  AwaitExpressionImpl(this.awaitKeyword, ExpressionImpl expression) {
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
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(awaitKeyword)..add(_expression);

  @override
  Token get endToken => _expression.endToken;

  @override
  Expression get expression => _expression;

  @override
  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Precedence get precedence => Precedence.prefix;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitAwaitExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression?.accept(visitor);
  }
}

/// A binary (infix) expression.
///
///    binaryExpression ::=
///        [Expression] [Token] [Expression]
class BinaryExpressionImpl extends ExpressionImpl implements BinaryExpression {
  /// The expression used to compute the left operand.
  ExpressionImpl _leftOperand;

  /// The binary operator being applied.
  @override
  Token operator;

  /// The expression used to compute the right operand.
  ExpressionImpl _rightOperand;

  /// The element associated with the operator based on the static type of the
  /// left operand, or `null` if the AST structure has not been resolved, if the
  /// operator is not user definable, or if the operator could not be resolved.
  @override
  MethodElement staticElement;

  @override
  FunctionType staticInvokeType;

  /// Initialize a newly created binary expression.
  BinaryExpressionImpl(
      ExpressionImpl leftOperand, this.operator, ExpressionImpl rightOperand) {
    _leftOperand = _becomeParentOf(leftOperand);
    _rightOperand = _becomeParentOf(rightOperand);
  }

  @override
  Token get beginToken => _leftOperand.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(_leftOperand)..add(operator)..add(_rightOperand);

  @override
  Token get endToken => _rightOperand.endToken;

  @override
  Expression get leftOperand => _leftOperand;

  @override
  set leftOperand(Expression expression) {
    _leftOperand = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Precedence get precedence => Precedence.forTokenType(operator.type);

  @override
  Expression get rightOperand => _rightOperand;

  @override
  set rightOperand(Expression expression) {
    _rightOperand = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitBinaryExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _leftOperand?.accept(visitor);
    _rightOperand?.accept(visitor);
  }
}

/// A function body that consists of a block of statements.
///
///    blockFunctionBody ::=
///        ('async' | 'async' '*' | 'sync' '*')? [Block]
class BlockFunctionBodyImpl extends FunctionBodyImpl
    implements BlockFunctionBody {
  /// The token representing the 'async' or 'sync' keyword, or `null` if there
  /// is no such keyword.
  @override
  Token keyword;

  /// The star optionally following the 'async' or 'sync' keyword, or `null` if
  /// there is wither no such keyword or no star.
  @override
  Token star;

  /// The block representing the body of the function.
  BlockImpl _block;

  /// Initialize a newly created function body consisting of a block of
  /// statements. The [keyword] can be `null` if there is no keyword specified
  /// for the block. The [star] can be `null` if there is no star following the
  /// keyword (and must be `null` if there is no keyword).
  BlockFunctionBodyImpl(this.keyword, this.star, BlockImpl block) {
    _block = _becomeParentOf(block);
  }

  @override
  Token get beginToken {
    if (keyword != null) {
      return keyword;
    }
    return _block.beginToken;
  }

  @override
  Block get block => _block;

  @override
  set block(Block block) {
    _block = _becomeParentOf(block as BlockImpl);
  }

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(keyword)..add(star)..add(_block);

  @override
  Token get endToken => _block.endToken;

  @override
  bool get isAsynchronous => keyword != null && keyword.lexeme == Parser.ASYNC;

  @override
  bool get isGenerator => star != null;

  @override
  bool get isSynchronous => keyword == null || keyword.lexeme != Parser.ASYNC;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitBlockFunctionBody(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _block?.accept(visitor);
  }
}

/// A sequence of statements.
///
///    block ::=
///        '{' statement* '}'
class BlockImpl extends StatementImpl implements Block {
  /// The left curly bracket.
  @override
  Token leftBracket;

  /// The statements contained in the block.
  NodeList<Statement> _statements;

  /// The right curly bracket.
  @override
  Token rightBracket;

  /// Initialize a newly created block of code.
  BlockImpl(this.leftBracket, List<Statement> statements, this.rightBracket) {
    _statements = NodeListImpl<Statement>(this, statements);
  }

  @override
  Token get beginToken => leftBracket;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(leftBracket)
    ..addAll(_statements)
    ..add(rightBracket);

  @override
  Token get endToken => rightBracket;

  @override
  NodeList<Statement> get statements => _statements;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitBlock(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _statements.accept(visitor);
  }
}

/// A boolean literal expression.
///
///    booleanLiteral ::=
///        'false' | 'true'
class BooleanLiteralImpl extends LiteralImpl implements BooleanLiteral {
  /// The token representing the literal.
  @override
  Token literal;

  /// The value of the literal.
  @override
  bool value = false;

  /// Initialize a newly created boolean literal.
  BooleanLiteralImpl(this.literal, this.value);

  @override
  Token get beginToken => literal;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()..add(literal);

  @override
  Token get endToken => literal;

  @override
  bool get isSynthetic => literal.isSynthetic;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitBooleanLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// A break statement.
///
///    breakStatement ::=
///        'break' [SimpleIdentifier]? ';'
class BreakStatementImpl extends StatementImpl implements BreakStatement {
  /// The token representing the 'break' keyword.
  @override
  Token breakKeyword;

  /// The label associated with the statement, or `null` if there is no label.
  SimpleIdentifierImpl _label;

  /// The semicolon terminating the statement.
  @override
  Token semicolon;

  /// The AstNode which this break statement is breaking from.  This will be
  /// either a [Statement] (in the case of breaking out of a loop), a
  /// [SwitchMember] (in the case of a labeled break statement whose label
  /// matches a label on a switch case in an enclosing switch statement), or
  /// `null` if the AST has not yet been resolved or if the target could not be
  /// resolved. Note that if the source code has errors, the target might be
  /// invalid (e.g. trying to break to a switch case).
  @override
  AstNode target;

  /// Initialize a newly created break statement. The [label] can be `null` if
  /// there is no label associated with the statement.
  BreakStatementImpl(
      this.breakKeyword, SimpleIdentifierImpl label, this.semicolon) {
    _label = _becomeParentOf(label);
  }

  @override
  Token get beginToken => breakKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(breakKeyword)..add(_label)..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  SimpleIdentifier get label => _label;

  @override
  set label(SimpleIdentifier identifier) {
    _label = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitBreakStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _label?.accept(visitor);
  }
}

/// A sequence of cascaded expressions: expressions that share a common target.
/// There are three kinds of expressions that can be used in a cascade
/// expression: [IndexExpression], [MethodInvocation] and [PropertyAccess].
///
///    cascadeExpression ::=
///        [Expression] cascadeSection*
///
///    cascadeSection ::=
///        '..'  (cascadeSelector arguments*) (assignableSelector arguments*)*
///        (assignmentOperator expressionWithoutCascade)?
///
///    cascadeSelector ::=
///        '[ ' expression '] '
///      | identifier
class CascadeExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl
    implements CascadeExpression {
  /// The target of the cascade sections.
  ExpressionImpl _target;

  /// The cascade sections sharing the common target.
  NodeList<Expression> _cascadeSections;

  /// Initialize a newly created cascade expression. The list of
  /// [cascadeSections] must contain at least one element.
  CascadeExpressionImpl(
      ExpressionImpl target, List<Expression> cascadeSections) {
    _target = _becomeParentOf(target);
    _cascadeSections = NodeListImpl<Expression>(this, cascadeSections);
  }

  @override
  Token get beginToken => _target.beginToken;

  @override
  NodeList<Expression> get cascadeSections => _cascadeSections;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_target)
    ..addAll(_cascadeSections);

  @override
  Token get endToken => _cascadeSections.endToken;

  @override
  bool get isNullAware {
    return target.endToken.next.type == TokenType.QUESTION_PERIOD_PERIOD;
  }

  @override
  Precedence get precedence => Precedence.cascade;

  @override
  Expression get target => _target;

  @override
  set target(Expression target) {
    _target = _becomeParentOf(target as ExpressionImpl);
  }

  @override
  AstNode get _nullShortingExtensionCandidate => null;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitCascadeExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _target?.accept(visitor);
    _cascadeSections.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression descendant) {
    return _cascadeSections.contains(descendant);
  }
}

/// A catch clause within a try statement.
///
///    onPart ::=
///        catchPart [Block]
///      | 'on' type catchPart? [Block]
///
///    catchPart ::=
///        'catch' '(' [SimpleIdentifier] (',' [SimpleIdentifier])? ')'
class CatchClauseImpl extends AstNodeImpl implements CatchClause {
  /// The token representing the 'on' keyword, or `null` if there is no 'on'
  /// keyword.
  @override
  Token onKeyword;

  /// The type of exceptions caught by this catch clause, or `null` if this
  /// catch clause catches every type of exception.
  TypeAnnotationImpl _exceptionType;

  /// The token representing the 'catch' keyword, or `null` if there is no
  /// 'catch' keyword.
  @override
  Token catchKeyword;

  /// The left parenthesis, or `null` if there is no 'catch' keyword.
  @override
  Token leftParenthesis;

  /// The parameter whose value will be the exception that was thrown, or `null`
  /// if there is no 'catch' keyword.
  SimpleIdentifierImpl _exceptionParameter;

  /// The comma separating the exception parameter from the stack trace
  /// parameter, or `null` if there is no stack trace parameter.
  @override
  Token comma;

  /// The parameter whose value will be the stack trace associated with the
  /// exception, or `null` if there is no stack trace parameter.
  SimpleIdentifierImpl _stackTraceParameter;

  /// The right parenthesis, or `null` if there is no 'catch' keyword.
  @override
  Token rightParenthesis;

  /// The body of the catch block.
  BlockImpl _body;

  /// Initialize a newly created catch clause. The [onKeyword] and
  /// [exceptionType] can be `null` if the clause will catch all exceptions. The
  /// [comma] and [stackTraceParameter] can be `null` if the stack trace
  /// parameter is not defined.
  CatchClauseImpl(
      this.onKeyword,
      TypeAnnotationImpl exceptionType,
      this.catchKeyword,
      this.leftParenthesis,
      SimpleIdentifierImpl exceptionParameter,
      this.comma,
      SimpleIdentifierImpl stackTraceParameter,
      this.rightParenthesis,
      BlockImpl body) {
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

  @override
  Block get body => _body;

  @override
  set body(Block block) {
    _body = _becomeParentOf(block as BlockImpl);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
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

  @override
  SimpleIdentifier get exceptionParameter => _exceptionParameter;

  @override
  set exceptionParameter(SimpleIdentifier parameter) {
    _exceptionParameter = _becomeParentOf(parameter as SimpleIdentifierImpl);
  }

  @override
  TypeAnnotation get exceptionType => _exceptionType;

  @override
  set exceptionType(TypeAnnotation exceptionType) {
    _exceptionType = _becomeParentOf(exceptionType as TypeAnnotationImpl);
  }

  @override
  SimpleIdentifier get stackTraceParameter => _stackTraceParameter;

  @override
  set stackTraceParameter(SimpleIdentifier parameter) {
    _stackTraceParameter = _becomeParentOf(parameter as SimpleIdentifierImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitCatchClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _exceptionType?.accept(visitor);
    _exceptionParameter?.accept(visitor);
    _stackTraceParameter?.accept(visitor);
    _body?.accept(visitor);
  }
}

/// Helper class to allow iteration of child entities of an AST node.
class ChildEntities
    with IterableMixin<SyntacticEntity>
    implements Iterable<SyntacticEntity> {
  /// The list of child entities to be iterated over.
  final List<SyntacticEntity> _entities = [];

  @override
  Iterator<SyntacticEntity> get iterator => _entities.iterator;

  /// Add an AST node or token as the next child entity, if it is not `null`.
  void add(SyntacticEntity entity) {
    if (entity != null) {
      _entities.add(entity);
    }
  }

  /// Add the given items as the next child entities, if [items] is not `null`.
  void addAll(Iterable<SyntacticEntity> items) {
    if (items != null) {
      _entities.addAll(items);
    }
  }
}

/// The declaration of a class.
///
///    classDeclaration ::=
///        'abstract'? 'class' [SimpleIdentifier] [TypeParameterList]?
///        ([ExtendsClause] [WithClause]?)?
///        [ImplementsClause]?
///        '{' [ClassMember]* '}'
class ClassDeclarationImpl extends ClassOrMixinDeclarationImpl
    implements ClassDeclaration {
  /// The 'abstract' keyword, or `null` if the keyword was absent.
  @override
  Token abstractKeyword;

  /// The token representing the 'class' keyword.
  @override
  Token classKeyword;

  /// The extends clause for the class, or `null` if the class does not extend
  /// any other class.
  ExtendsClauseImpl _extendsClause;

  /// The with clause for the class, or `null` if the class does not have a with
  /// clause.
  WithClauseImpl _withClause;

  /// The native clause for the class, or `null` if the class does not have a
  /// native clause.
  NativeClauseImpl _nativeClause;

  /// Initialize a newly created class declaration. Either or both of the
  /// [comment] and [metadata] can be `null` if the class does not have the
  /// corresponding attribute. The [abstractKeyword] can be `null` if the class
  /// is not abstract. The [typeParameters] can be `null` if the class does not
  /// have any type parameters. Any or all of the [extendsClause], [withClause],
  /// and [implementsClause] can be `null` if the class does not have the
  /// corresponding clause. The list of [members] can be `null` if the class
  /// does not have any members.
  ClassDeclarationImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      this.abstractKeyword,
      this.classKeyword,
      SimpleIdentifierImpl name,
      TypeParameterListImpl typeParameters,
      ExtendsClauseImpl extendsClause,
      WithClauseImpl withClause,
      ImplementsClauseImpl implementsClause,
      Token leftBracket,
      List<ClassMember> members,
      Token rightBracket)
      : super(comment, metadata, name, typeParameters, implementsClause,
            leftBracket, members, rightBracket) {
    _extendsClause = _becomeParentOf(extendsClause);
    _withClause = _becomeParentOf(withClause);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
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
  ClassElement get declaredElement => _name?.staticElement as ClassElement;

  @override
  ExtendsClause get extendsClause => _extendsClause;

  @override
  set extendsClause(ExtendsClause extendsClause) {
    _extendsClause = _becomeParentOf(extendsClause as ExtendsClauseImpl);
  }

  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (abstractKeyword != null) {
      return abstractKeyword;
    }
    return classKeyword;
  }

  @override
  bool get isAbstract => abstractKeyword != null;

  @override
  NativeClause get nativeClause => _nativeClause;

  @override
  set nativeClause(NativeClause nativeClause) {
    _nativeClause = _becomeParentOf(nativeClause as NativeClauseImpl);
  }

  @override
  WithClause get withClause => _withClause;

  @override
  set withClause(WithClause withClause) {
    _withClause = _becomeParentOf(withClause as WithClauseImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitClassDeclaration(this);

  @override
  ConstructorDeclaration getConstructor(String name) {
    int length = _members.length;
    for (int i = 0; i < length; i++) {
      ClassMember classMember = _members[i];
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

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _name?.accept(visitor);
    _typeParameters?.accept(visitor);
    _extendsClause?.accept(visitor);
    _withClause?.accept(visitor);
    _implementsClause?.accept(visitor);
    _nativeClause?.accept(visitor);
    members.accept(visitor);
  }
}

/// A node that declares a name within the scope of a class.
abstract class ClassMemberImpl extends DeclarationImpl implements ClassMember {
  /// Initialize a newly created member of a class. Either or both of the
  /// [comment] and [metadata] can be `null` if the member does not have the
  /// corresponding attribute.
  ClassMemberImpl(CommentImpl comment, List<Annotation> metadata)
      : super(comment, metadata);
}

abstract class ClassOrMixinDeclarationImpl
    extends NamedCompilationUnitMemberImpl implements ClassOrMixinDeclaration {
  /// The type parameters for the class or mixin,
  /// or `null` if the declaration does not have any type parameters.
  TypeParameterListImpl _typeParameters;

  /// The implements clause for the class or mixin,
  /// or `null` if the declaration does not implement any interfaces.
  ImplementsClauseImpl _implementsClause;

  /// The left curly bracket.
  @override
  Token leftBracket;

  /// The members defined by the class or mixin.
  NodeList<ClassMember> _members;

  /// The right curly bracket.
  @override
  Token rightBracket;

  ClassOrMixinDeclarationImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      SimpleIdentifierImpl name,
      TypeParameterListImpl typeParameters,
      ImplementsClauseImpl implementsClause,
      this.leftBracket,
      List<ClassMember> members,
      this.rightBracket)
      : super(comment, metadata, name) {
    _typeParameters = _becomeParentOf(typeParameters);
    _implementsClause = _becomeParentOf(implementsClause);
    _members = NodeListImpl<ClassMember>(this, members);
  }

  @override
  Token get endToken => rightBracket;

  @override
  ImplementsClause get implementsClause => _implementsClause;

  set implementsClause(ImplementsClause implementsClause) {
    _implementsClause =
        _becomeParentOf(implementsClause as ImplementsClauseImpl);
  }

  @override
  NodeList<ClassMember> get members => _members;

  @override
  TypeParameterList get typeParameters => _typeParameters;

  set typeParameters(TypeParameterList typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl);
  }

  @override
  VariableDeclaration getField(String name) {
    int memberLength = _members.length;
    for (int i = 0; i < memberLength; i++) {
      ClassMember classMember = _members[i];
      if (classMember is FieldDeclaration) {
        FieldDeclaration fieldDeclaration = classMember;
        NodeList<VariableDeclaration> fields =
            fieldDeclaration.fields.variables;
        int fieldLength = fields.length;
        for (int i = 0; i < fieldLength; i++) {
          VariableDeclaration field = fields[i];
          SimpleIdentifier fieldName = field.name;
          if (fieldName != null && name == fieldName.name) {
            return field;
          }
        }
      }
    }
    return null;
  }

  @override
  MethodDeclaration getMethod(String name) {
    int length = _members.length;
    for (int i = 0; i < length; i++) {
      ClassMember classMember = _members[i];
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
}

/// A class type alias.
///
///    classTypeAlias ::=
///        [SimpleIdentifier] [TypeParameterList]? '=' 'abstract'?
///        mixinApplication
///
///    mixinApplication ::=
///        [TypeName] [WithClause] [ImplementsClause]? ';'
class ClassTypeAliasImpl extends TypeAliasImpl implements ClassTypeAlias {
  /// The type parameters for the class, or `null` if the class does not have
  /// any type parameters.
  TypeParameterListImpl _typeParameters;

  /// The token for the '=' separating the name from the definition.
  @override
  Token equals;

  /// The token for the 'abstract' keyword, or `null` if this is not defining an
  /// abstract class.
  @override
  Token abstractKeyword;

  /// The name of the superclass of the class being declared.
  TypeNameImpl _superclass;

  /// The with clause for this class.
  WithClauseImpl _withClause;

  /// The implements clause for this class, or `null` if there is no implements
  /// clause.
  ImplementsClauseImpl _implementsClause;

  /// Initialize a newly created class type alias. Either or both of the
  /// [comment] and [metadata] can be `null` if the class type alias does not
  /// have the corresponding attribute. The [typeParameters] can be `null` if
  /// the class does not have any type parameters. The [abstractKeyword] can be
  /// `null` if the class is not abstract. The [implementsClause] can be `null`
  /// if the class does not implement any interfaces.
  ClassTypeAliasImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      Token keyword,
      SimpleIdentifierImpl name,
      TypeParameterListImpl typeParameters,
      this.equals,
      this.abstractKeyword,
      TypeNameImpl superclass,
      WithClauseImpl withClause,
      ImplementsClauseImpl implementsClause,
      Token semicolon)
      : super(comment, metadata, keyword, name, semicolon) {
    _typeParameters = _becomeParentOf(typeParameters);
    _superclass = _becomeParentOf(superclass);
    _withClause = _becomeParentOf(withClause);
    _implementsClause = _becomeParentOf(implementsClause);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
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
  ClassElement get declaredElement => _name?.staticElement as ClassElement;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (abstractKeyword != null) {
      return abstractKeyword;
    }
    return typedefKeyword;
  }

  @override
  ImplementsClause get implementsClause => _implementsClause;

  @override
  set implementsClause(ImplementsClause implementsClause) {
    _implementsClause =
        _becomeParentOf(implementsClause as ImplementsClauseImpl);
  }

  @override
  bool get isAbstract => abstractKeyword != null;

  @override
  TypeName get superclass => _superclass;

  @override
  set superclass(TypeName superclass) {
    _superclass = _becomeParentOf(superclass as TypeNameImpl);
  }

  @override
  TypeParameterList get typeParameters => _typeParameters;

  @override
  set typeParameters(TypeParameterList typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl);
  }

  @override
  WithClause get withClause => _withClause;

  @override
  set withClause(WithClause withClause) {
    _withClause = _becomeParentOf(withClause as WithClauseImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitClassTypeAlias(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _name?.accept(visitor);
    _typeParameters?.accept(visitor);
    _superclass?.accept(visitor);
    _withClause?.accept(visitor);
    _implementsClause?.accept(visitor);
  }
}

abstract class CollectionElementImpl extends AstNodeImpl
    implements CollectionElement {}

/// A combinator associated with an import or export directive.
///
///    combinator ::=
///        [HideCombinator]
///      | [ShowCombinator]
abstract class CombinatorImpl extends AstNodeImpl implements Combinator {
  /// The 'hide' or 'show' keyword specifying what kind of processing is to be
  /// done on the names.
  @override
  Token keyword;

  /// Initialize a newly created combinator.
  CombinatorImpl(this.keyword);

  @override
  Token get beginToken => keyword;
}

/// A comment within the source code.
///
///    comment ::=
///        endOfLineComment
///      | blockComment
///      | documentationComment
///
///    endOfLineComment ::=
///        '//' (CHARACTER - EOL)* EOL
///
///    blockComment ::=
///        '/ *' CHARACTER* '&#42;/'
///
///    documentationComment ::=
///        '/ **' (CHARACTER | [CommentReference])* '&#42;/'
///      | ('///' (CHARACTER - EOL)* EOL)+
class CommentImpl extends AstNodeImpl implements Comment {
  /// The tokens representing the comment.
  @override
  final List<Token> tokens;

  /// The type of the comment.
  final CommentType _type;

  /// The references embedded within the documentation comment. This list will
  /// be empty unless this is a documentation comment that has references embedded
  /// within it.
  NodeList<CommentReference> _references;

  /// Initialize a newly created comment. The list of [tokens] must contain at
  /// least one token. The [_type] is the type of the comment. The list of
  /// [references] can be empty if the comment does not contain any embedded
  /// references.
  CommentImpl(this.tokens, this._type, List<CommentReference> references) {
    _references = NodeListImpl<CommentReference>(this, references);
  }

  @override
  Token get beginToken => tokens[0];

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..addAll(tokens);

  @override
  Token get endToken => tokens[tokens.length - 1];

  @override
  bool get isBlock => _type == CommentType.BLOCK;

  @override
  bool get isDocumentation => _type == CommentType.DOCUMENTATION;

  @override
  bool get isEndOfLine => _type == CommentType.END_OF_LINE;

  @override
  NodeList<CommentReference> get references => _references;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitComment(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _references.accept(visitor);
  }

  /// Create a block comment consisting of the given [tokens].
  static Comment createBlockComment(List<Token> tokens) =>
      CommentImpl(tokens, CommentType.BLOCK, null);

  /// Create a documentation comment consisting of the given [tokens].
  static Comment createDocumentationComment(List<Token> tokens) =>
      CommentImpl(tokens, CommentType.DOCUMENTATION, <CommentReference>[]);

  /// Create a documentation comment consisting of the given [tokens] and having
  /// the given [references] embedded within it.
  static Comment createDocumentationCommentWithReferences(
          List<Token> tokens, List<CommentReference> references) =>
      CommentImpl(tokens, CommentType.DOCUMENTATION, references);

  /// Create an end-of-line comment consisting of the given [tokens].
  static Comment createEndOfLineComment(List<Token> tokens) =>
      CommentImpl(tokens, CommentType.END_OF_LINE, null);
}

/// A reference to a Dart element that is found within a documentation comment.
///
///    commentReference ::=
///        '[' 'new'? [Identifier] ']'
class CommentReferenceImpl extends AstNodeImpl implements CommentReference {
  /// The token representing the 'new' keyword, or `null` if there was no 'new'
  /// keyword.
  @override
  Token newKeyword;

  /// The identifier being referenced.
  IdentifierImpl _identifier;

  /// Initialize a newly created reference to a Dart element. The [newKeyword]
  /// can be `null` if the reference is not to a constructor.
  CommentReferenceImpl(this.newKeyword, IdentifierImpl identifier) {
    _identifier = _becomeParentOf(identifier);
  }

  @override
  Token get beginToken => newKeyword ?? _identifier.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(newKeyword)..add(_identifier);

  @override
  Token get endToken => _identifier.endToken;

  @override
  Identifier get identifier => _identifier;

  @override
  set identifier(Identifier identifier) {
    _identifier = _becomeParentOf(identifier as IdentifierImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitCommentReference(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _identifier?.accept(visitor);
  }
}

/// The possible types of comments that are recognized by the parser.
class CommentType {
  /// A block comment.
  static const CommentType BLOCK = CommentType('BLOCK');

  /// A documentation comment.
  static const CommentType DOCUMENTATION = CommentType('DOCUMENTATION');

  /// An end-of-line comment.
  static const CommentType END_OF_LINE = CommentType('END_OF_LINE');

  /// The name of the comment type.
  final String name;

  /// Initialize a newly created comment type to have the given [name].
  const CommentType(this.name);

  @override
  String toString() => name;
}

/// A compilation unit.
///
/// While the grammar restricts the order of the directives and declarations
/// within a compilation unit, this class does not enforce those restrictions.
/// In particular, the children of a compilation unit will be visited in lexical
/// order even if lexical order does not conform to the restrictions of the
/// grammar.
///
///    compilationUnit ::=
///        directives declarations
///
///    directives ::=
///        [ScriptTag]? [LibraryDirective]? namespaceDirective* [PartDirective]*
///      | [PartOfDirective]
///
///    namespaceDirective ::=
///        [ImportDirective]
///      | [ExportDirective]
///
///    declarations ::=
///        [CompilationUnitMember]*
class CompilationUnitImpl extends AstNodeImpl implements CompilationUnit {
  /// The first token in the token stream that was parsed to form this
  /// compilation unit.
  @override
  Token beginToken;

  /// The script tag at the beginning of the compilation unit, or `null` if
  /// there is no script tag in this compilation unit.
  ScriptTagImpl _scriptTag;

  /// The directives contained in this compilation unit.
  NodeList<Directive> _directives;

  /// The declarations contained in this compilation unit.
  NodeList<CompilationUnitMember> _declarations;

  /// The last token in the token stream that was parsed to form this
  /// compilation unit. This token should always have a type of [TokenType.EOF].
  @override
  Token endToken;

  /// The element associated with this compilation unit, or `null` if the AST
  /// structure has not been resolved.
  @override
  CompilationUnitElement declaredElement;

  /// The line information for this compilation unit.
  @override
  LineInfo lineInfo;

  /// The language version information.
  LibraryLanguageVersion languageVersion;

  @override
  final FeatureSet featureSet;

  /// Initialize a newly created compilation unit to have the given directives
  /// and declarations. The [scriptTag] can be `null` if there is no script tag
  /// in the compilation unit. The list of [directives] can be `null` if there
  /// are no directives in the compilation unit. The list of [declarations] can
  /// be `null` if there are no declarations in the compilation unit.
  CompilationUnitImpl(
      this.beginToken,
      ScriptTagImpl scriptTag,
      List<Directive> directives,
      List<CompilationUnitMember> declarations,
      this.endToken,
      this.featureSet) {
    _scriptTag = _becomeParentOf(scriptTag);
    _directives = NodeListImpl<Directive>(this, directives);
    _declarations = NodeListImpl<CompilationUnitMember>(this, declarations);
  }

  @override
  Iterable<SyntacticEntity> get childEntities {
    ChildEntities result = ChildEntities()..add(_scriptTag);
    if (_directivesAreBeforeDeclarations) {
      result..addAll(_directives)..addAll(_declarations);
    } else {
      result.addAll(sortedDirectivesAndDeclarations);
    }
    return result;
  }

  @override
  NodeList<CompilationUnitMember> get declarations => _declarations;

  @override
  NodeList<Directive> get directives => _directives;

  @override
  set element(CompilationUnitElement element) {
    declaredElement = element;
  }

  @override
  LanguageVersionToken get languageVersionToken {
    CommentToken comment = beginToken.precedingComments;
    while (comment != null) {
      if (comment is LanguageVersionToken) {
        return comment;
      }
      comment = comment.next;
    }
    return null;
  }

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

  @override
  ScriptTag get scriptTag => _scriptTag;

  @override
  set scriptTag(ScriptTag scriptTag) {
    _scriptTag = _becomeParentOf(scriptTag as ScriptTagImpl);
  }

  @override
  List<AstNode> get sortedDirectivesAndDeclarations {
    return <AstNode>[
      ..._directives,
      ..._declarations,
    ]..sort(AstNode.LEXICAL_ORDER);
  }

  /// Return `true` if all of the directives are lexically before any
  /// declarations.
  bool get _directivesAreBeforeDeclarations {
    if (_directives.isEmpty || _declarations.isEmpty) {
      return true;
    }
    Directive lastDirective = _directives[_directives.length - 1];
    CompilationUnitMember firstDeclaration = _declarations[0];
    return lastDirective.offset < firstDeclaration.offset;
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitCompilationUnit(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _scriptTag?.accept(visitor);
    if (_directivesAreBeforeDeclarations) {
      _directives.accept(visitor);
      _declarations.accept(visitor);
    } else {
      List<AstNode> sortedMembers = sortedDirectivesAndDeclarations;
      int length = sortedMembers.length;
      for (int i = 0; i < length; i++) {
        AstNode child = sortedMembers[i];
        child.accept(visitor);
      }
    }
  }
}

/// A node that declares one or more names within the scope of a compilation
/// unit.
///
///    compilationUnitMember ::=
///        [ClassDeclaration]
///      | [MixinDeclaration]
///      | [ExtensionDeclaration]
///      | [EnumDeclaration]
///      | [TypeAlias]
///      | [FunctionDeclaration]
///      | [TopLevelVariableDeclaration]
abstract class CompilationUnitMemberImpl extends DeclarationImpl
    implements CompilationUnitMember {
  /// Initialize a newly created generic compilation unit member. Either or both
  /// of the [comment] and [metadata] can be `null` if the member does not have
  /// the corresponding attribute.
  CompilationUnitMemberImpl(CommentImpl comment, List<Annotation> metadata)
      : super(comment, metadata);
}

mixin CompoundAssignmentExpressionImpl implements CompoundAssignmentExpression {
  @override
  Element readElement;

  @override
  Element writeElement;

  @override
  DartType readType;

  @override
  DartType writeType;
}

/// A conditional expression.
///
///    conditionalExpression ::=
///        [Expression] '?' [Expression] ':' [Expression]
class ConditionalExpressionImpl extends ExpressionImpl
    implements ConditionalExpression {
  /// The condition used to determine which of the expressions is executed next.
  ExpressionImpl _condition;

  /// The token used to separate the condition from the then expression.
  @override
  Token question;

  /// The expression that is executed if the condition evaluates to `true`.
  ExpressionImpl _thenExpression;

  /// The token used to separate the then expression from the else expression.
  @override
  Token colon;

  /// The expression that is executed if the condition evaluates to `false`.
  ExpressionImpl _elseExpression;

  /// Initialize a newly created conditional expression.
  ConditionalExpressionImpl(
      ExpressionImpl condition,
      this.question,
      ExpressionImpl thenExpression,
      this.colon,
      ExpressionImpl elseExpression) {
    _condition = _becomeParentOf(condition);
    _thenExpression = _becomeParentOf(thenExpression);
    _elseExpression = _becomeParentOf(elseExpression);
  }

  @override
  Token get beginToken => _condition.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_condition)
    ..add(question)
    ..add(_thenExpression)
    ..add(colon)
    ..add(_elseExpression);

  @override
  Expression get condition => _condition;

  @override
  set condition(Expression expression) {
    _condition = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Expression get elseExpression => _elseExpression;

  @override
  set elseExpression(Expression expression) {
    _elseExpression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Token get endToken => _elseExpression.endToken;

  @override
  Precedence get precedence => Precedence.conditional;

  @override
  Expression get thenExpression => _thenExpression;

  @override
  set thenExpression(Expression expression) {
    _thenExpression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitConditionalExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _condition?.accept(visitor);
    _thenExpression?.accept(visitor);
    _elseExpression?.accept(visitor);
  }
}

/// A configuration in either an import or export directive.
///
///     configuration ::=
///         'if' '(' test ')' uri
///
///     test ::=
///         dottedName ('==' stringLiteral)?
///
///     dottedName ::=
///         identifier ('.' identifier)*
class ConfigurationImpl extends AstNodeImpl implements Configuration {
  @override
  Token ifKeyword;

  @override
  Token leftParenthesis;

  DottedNameImpl _name;

  @override
  Token equalToken;

  StringLiteralImpl _value;

  @override
  Token rightParenthesis;

  StringLiteralImpl _uri;

  @override
  Source uriSource;

  ConfigurationImpl(
      this.ifKeyword,
      this.leftParenthesis,
      DottedNameImpl name,
      this.equalToken,
      StringLiteralImpl value,
      this.rightParenthesis,
      StringLiteralImpl libraryUri) {
    _name = _becomeParentOf(name);
    _value = _becomeParentOf(value);
    _uri = _becomeParentOf(libraryUri);
  }

  @override
  Token get beginToken => ifKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(ifKeyword)
    ..add(leftParenthesis)
    ..add(_name)
    ..add(equalToken)
    ..add(_value)
    ..add(rightParenthesis)
    ..add(_uri);

  @override
  Token get endToken => _uri.endToken;

  @override
  DottedName get name => _name;

  @override
  set name(DottedName name) {
    _name = _becomeParentOf(name as DottedNameImpl);
  }

  @override
  StringLiteral get uri => _uri;

  @override
  set uri(StringLiteral uri) {
    _uri = _becomeParentOf(uri as StringLiteralImpl);
  }

  @override
  StringLiteral get value => _value;

  @override
  set value(StringLiteral value) {
    _value = _becomeParentOf(value as StringLiteralImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitConfiguration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _name?.accept(visitor);
    _value?.accept(visitor);
    _uri?.accept(visitor);
  }
}

/// A constructor declaration.
///
///    constructorDeclaration ::=
///        constructorSignature [FunctionBody]?
///      | constructorName formalParameterList ':' 'this'
///        ('.' [SimpleIdentifier])? arguments
///
///    constructorSignature ::=
///        'external'? constructorName formalParameterList initializerList?
///      | 'external'? 'factory' factoryName formalParameterList
///        initializerList?
///      | 'external'? 'const'  constructorName formalParameterList
///        initializerList?
///
///    constructorName ::=
///        [SimpleIdentifier] ('.' [SimpleIdentifier])?
///
///    factoryName ::=
///        [Identifier] ('.' [SimpleIdentifier])?
///
///    initializerList ::=
///        ':' [ConstructorInitializer] (',' [ConstructorInitializer])*
class ConstructorDeclarationImpl extends ClassMemberImpl
    implements ConstructorDeclaration {
  /// The token for the 'external' keyword, or `null` if the constructor is not
  /// external.
  @override
  Token externalKeyword;

  /// The token for the 'const' keyword, or `null` if the constructor is not a
  /// const constructor.
  @override
  Token constKeyword;

  /// The token for the 'factory' keyword, or `null` if the constructor is not a
  /// factory constructor.
  @override
  Token factoryKeyword;

  /// The type of object being created. This can be different than the type in
  /// which the constructor is being declared if the constructor is the
  /// implementation of a factory constructor.
  IdentifierImpl _returnType;

  /// The token for the period before the constructor name, or `null` if the
  /// constructor being declared is unnamed.
  @override
  Token period;

  /// The name of the constructor, or `null` if the constructor being declared
  /// is unnamed.
  SimpleIdentifierImpl _name;

  /// The parameters associated with the constructor.
  FormalParameterListImpl _parameters;

  /// The token for the separator (colon or equals) before the initializer list
  /// or redirection, or `null` if there are no initializers.
  @override
  Token separator;

  /// The initializers associated with the constructor.
  NodeList<ConstructorInitializer> _initializers;

  /// The name of the constructor to which this constructor will be redirected,
  /// or `null` if this is not a redirecting factory constructor.
  ConstructorNameImpl _redirectedConstructor;

  /// The body of the constructor, or `null` if the constructor does not have a
  /// body.
  FunctionBodyImpl _body;

  /// The element associated with this constructor, or `null` if the AST
  /// structure has not been resolved or if this constructor could not be
  /// resolved.
  @override
  ConstructorElement declaredElement;

  /// Initialize a newly created constructor declaration. The [externalKeyword]
  /// can be `null` if the constructor is not external. Either or both of the
  /// [comment] and [metadata] can be `null` if the constructor does not have
  /// the corresponding attribute. The [constKeyword] can be `null` if the
  /// constructor cannot be used to create a constant. The [factoryKeyword] can
  /// be `null` if the constructor is not a factory. The [period] and [name] can
  /// both be `null` if the constructor is not a named constructor. The
  /// [separator] can be `null` if the constructor does not have any
  /// initializers and does not redirect to a different constructor. The list of
  /// [initializers] can be `null` if the constructor does not have any
  /// initializers. The [redirectedConstructor] can be `null` if the constructor
  /// does not redirect to a different constructor. The [body] can be `null` if
  /// the constructor does not have a body.
  ConstructorDeclarationImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      this.externalKeyword,
      this.constKeyword,
      this.factoryKeyword,
      IdentifierImpl returnType,
      this.period,
      SimpleIdentifierImpl name,
      FormalParameterListImpl parameters,
      this.separator,
      List<ConstructorInitializer> initializers,
      ConstructorNameImpl redirectedConstructor,
      FunctionBodyImpl body)
      : super(comment, metadata) {
    _returnType = _becomeParentOf(returnType);
    _name = _becomeParentOf(name);
    _parameters = _becomeParentOf(parameters);
    _initializers = NodeListImpl<ConstructorInitializer>(this, initializers);
    _redirectedConstructor = _becomeParentOf(redirectedConstructor);
    _body = _becomeParentOf(body);
  }

  @override
  FunctionBody get body => _body;

  @override
  set body(FunctionBody functionBody) {
    _body = _becomeParentOf(functionBody as FunctionBodyImpl);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
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
    } else if (_initializers.isNotEmpty) {
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

  @override
  NodeList<ConstructorInitializer> get initializers => _initializers;

  @override
  SimpleIdentifier get name => _name;

  @override
  set name(SimpleIdentifier identifier) {
    _name = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  FormalParameterList get parameters => _parameters;

  @override
  set parameters(FormalParameterList parameters) {
    _parameters = _becomeParentOf(parameters as FormalParameterListImpl);
  }

  @override
  ConstructorName get redirectedConstructor => _redirectedConstructor;

  @override
  set redirectedConstructor(ConstructorName redirectedConstructor) {
    _redirectedConstructor =
        _becomeParentOf(redirectedConstructor as ConstructorNameImpl);
  }

  @override
  Identifier get returnType => _returnType;

  @override
  set returnType(Identifier typeName) {
    _returnType = _becomeParentOf(typeName as IdentifierImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitConstructorDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _returnType?.accept(visitor);
    _name?.accept(visitor);
    _parameters?.accept(visitor);
    _initializers.accept(visitor);
    _redirectedConstructor?.accept(visitor);
    _body?.accept(visitor);
  }
}

/// The initialization of a field within a constructor's initialization list.
///
///    fieldInitializer ::=
///        ('this' '.')? [SimpleIdentifier] '=' [Expression]
class ConstructorFieldInitializerImpl extends ConstructorInitializerImpl
    implements ConstructorFieldInitializer {
  /// The token for the 'this' keyword, or `null` if there is no 'this' keyword.
  @override
  Token thisKeyword;

  /// The token for the period after the 'this' keyword, or `null` if there is
  /// no'this' keyword.
  @override
  Token period;

  /// The name of the field being initialized.
  SimpleIdentifierImpl _fieldName;

  /// The token for the equal sign between the field name and the expression.
  @override
  Token equals;

  /// The expression computing the value to which the field will be initialized.
  ExpressionImpl _expression;

  /// Initialize a newly created field initializer to initialize the field with
  /// the given name to the value of the given expression. The [thisKeyword] and
  /// [period] can be `null` if the 'this' keyword was not specified.
  ConstructorFieldInitializerImpl(this.thisKeyword, this.period,
      SimpleIdentifierImpl fieldName, this.equals, ExpressionImpl expression) {
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
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(thisKeyword)
    ..add(period)
    ..add(_fieldName)
    ..add(equals)
    ..add(_expression);

  @override
  Token get endToken => _expression.endToken;

  @override
  Expression get expression => _expression;

  @override
  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  SimpleIdentifier get fieldName => _fieldName;

  @override
  set fieldName(SimpleIdentifier identifier) {
    _fieldName = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitConstructorFieldInitializer(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _fieldName?.accept(visitor);
    _expression?.accept(visitor);
  }
}

/// A node that can occur in the initializer list of a constructor declaration.
///
///    constructorInitializer ::=
///        [SuperConstructorInvocation]
///      | [ConstructorFieldInitializer]
///      | [RedirectingConstructorInvocation]
abstract class ConstructorInitializerImpl extends AstNodeImpl
    implements ConstructorInitializer {}

/// The name of the constructor.
///
///    constructorName ::=
///        type ('.' identifier)?
class ConstructorNameImpl extends AstNodeImpl implements ConstructorName {
  /// The name of the type defining the constructor.
  TypeNameImpl _type;

  /// The token for the period before the constructor name, or `null` if the
  /// specified constructor is the unnamed constructor.
  @override
  Token period;

  /// The name of the constructor, or `null` if the specified constructor is the
  /// unnamed constructor.
  SimpleIdentifierImpl _name;

  /// The element associated with this constructor name based on static type
  /// information, or `null` if the AST structure has not been resolved or if
  /// this constructor name could not be resolved.
  @override
  ConstructorElement staticElement;

  /// Initialize a newly created constructor name. The [period] and [name] can
  /// be`null` if the constructor being named is the unnamed constructor.
  ConstructorNameImpl(
      TypeNameImpl type, this.period, SimpleIdentifierImpl name) {
    _type = _becomeParentOf(type);
    _name = _becomeParentOf(name);
  }

  @override
  Token get beginToken => _type.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(_type)..add(period)..add(_name);

  @override
  Token get endToken {
    if (_name != null) {
      return _name.endToken;
    }
    return _type.endToken;
  }

  @override
  SimpleIdentifier get name => _name;

  @override
  set name(SimpleIdentifier name) {
    _name = _becomeParentOf(name as SimpleIdentifierImpl);
  }

  @override
  TypeName get type => _type;

  @override
  set type(TypeName type) {
    _type = _becomeParentOf(type as TypeNameImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitConstructorName(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _type?.accept(visitor);
    _name?.accept(visitor);
  }
}

/// A continue statement.
///
///    continueStatement ::=
///        'continue' [SimpleIdentifier]? ';'
class ContinueStatementImpl extends StatementImpl implements ContinueStatement {
  /// The token representing the 'continue' keyword.
  @override
  Token continueKeyword;

  /// The label associated with the statement, or `null` if there is no label.
  SimpleIdentifierImpl _label;

  /// The semicolon terminating the statement.
  @override
  Token semicolon;

  /// The AstNode which this continue statement is continuing to.  This will be
  /// either a Statement (in the case of continuing a loop) or a SwitchMember
  /// (in the case of continuing from one switch case to another).  Null if the
  /// AST has not yet been resolved or if the target could not be resolved.
  /// Note that if the source code has errors, the target may be invalid (e.g.
  /// the target may be in an enclosing function).
  @override
  AstNode target;

  /// Initialize a newly created continue statement. The [label] can be `null`
  /// if there is no label associated with the statement.
  ContinueStatementImpl(
      this.continueKeyword, SimpleIdentifierImpl label, this.semicolon) {
    _label = _becomeParentOf(label);
  }

  @override
  Token get beginToken => continueKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(continueKeyword)..add(_label)..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  SimpleIdentifier get label => _label;

  @override
  set label(SimpleIdentifier identifier) {
    _label = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitContinueStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _label?.accept(visitor);
  }
}

/// A node that represents the declaration of one or more names. Each declared
/// name is visible within a name scope.
abstract class DeclarationImpl extends AnnotatedNodeImpl
    implements Declaration {
  /// Initialize a newly created declaration. Either or both of the [comment]
  /// and [metadata] can be `null` if the declaration does not have the
  /// corresponding attribute.
  DeclarationImpl(CommentImpl comment, List<Annotation> metadata)
      : super(comment, metadata);
}

/// The declaration of a single identifier.
///
///    declaredIdentifier ::=
///        [Annotation] finalConstVarOrType [SimpleIdentifier]
class DeclaredIdentifierImpl extends DeclarationImpl
    implements DeclaredIdentifier {
  /// The token representing either the 'final', 'const' or 'var' keyword, or
  /// `null` if no keyword was used.
  @override
  Token keyword;

  /// The name of the declared type of the parameter, or `null` if the parameter
  /// does not have a declared type.
  TypeAnnotationImpl _type;

  /// The name of the variable being declared.
  SimpleIdentifierImpl _identifier;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the declaration does not have
  /// the corresponding attribute. The [keyword] can be `null` if a type name is
  /// given. The [type] must be `null` if the keyword is 'var'.
  DeclaredIdentifierImpl(CommentImpl comment, List<Annotation> metadata,
      this.keyword, TypeAnnotationImpl type, SimpleIdentifierImpl identifier)
      : super(comment, metadata) {
    _type = _becomeParentOf(type);
    _identifier = _becomeParentOf(identifier);
  }

  @override
  Iterable<SyntacticEntity> get childEntities =>
      super._childEntities..add(keyword)..add(_type)..add(_identifier);

  @override
  LocalVariableElement get declaredElement {
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

  @override
  SimpleIdentifier get identifier => _identifier;

  @override
  set identifier(SimpleIdentifier identifier) {
    _identifier = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @override
  TypeAnnotation get type => _type;

  @override
  set type(TypeAnnotation type) {
    _type = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitDeclaredIdentifier(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _type?.accept(visitor);
    _identifier?.accept(visitor);
  }
}

/// A simple identifier that declares a name.
// TODO(rnystrom): Consider making this distinct from [SimpleIdentifier] and
// get rid of all of the:
//
//     if (node.inDeclarationContext()) { ... }
//
// code and instead visit this separately. A declaration is semantically pretty
// different from a use, so using the same node type doesn't seem to buy us
// much.
class DeclaredSimpleIdentifier extends SimpleIdentifierImpl {
  DeclaredSimpleIdentifier(Token token) : super(token);

  @override
  bool inDeclarationContext() => true;
}

/// A formal parameter with a default value. There are two kinds of parameters
/// that are both represented by this class: named formal parameters and
/// positional formal parameters.
///
///    defaultFormalParameter ::=
///        [NormalFormalParameter] ('=' [Expression])?
///
///    defaultNamedParameter ::=
///        [NormalFormalParameter] (':' [Expression])?
class DefaultFormalParameterImpl extends FormalParameterImpl
    implements DefaultFormalParameter {
  /// The formal parameter with which the default value is associated.
  NormalFormalParameterImpl _parameter;

  /// The kind of this parameter.
  @override
  ParameterKind kind;

  /// The token separating the parameter from the default value, or `null` if
  /// there is no default value.
  @override
  Token separator;

  /// The expression computing the default value for the parameter, or `null` if
  /// there is no default value.
  ExpressionImpl _defaultValue;

  /// Initialize a newly created default formal parameter. The [separator] and
  /// [defaultValue] can be `null` if there is no default value.
  DefaultFormalParameterImpl(NormalFormalParameterImpl parameter, this.kind,
      this.separator, ExpressionImpl defaultValue) {
    _parameter = _becomeParentOf(parameter);
    _defaultValue = _becomeParentOf(defaultValue);
  }

  @override
  Token get beginToken => _parameter.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(_parameter)..add(separator)..add(_defaultValue);

  @override
  Token get covariantKeyword => null;

  @override
  ParameterElement get declaredElement => _parameter.declaredElement;

  @override
  Expression get defaultValue => _defaultValue;

  @override
  set defaultValue(Expression expression) {
    _defaultValue = _becomeParentOf(expression as ExpressionImpl);
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

  @override
  NormalFormalParameter get parameter => _parameter;

  @override
  set parameter(NormalFormalParameter formalParameter) {
    _parameter = _becomeParentOf(formalParameter as NormalFormalParameterImpl);
  }

  @override
  Token get requiredKeyword => null;

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitDefaultFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _parameter?.accept(visitor);
    _defaultValue?.accept(visitor);
  }
}

/// A node that represents a directive.
///
///    directive ::=
///        [ExportDirective]
///      | [ImportDirective]
///      | [LibraryDirective]
///      | [PartDirective]
///      | [PartOfDirective]
abstract class DirectiveImpl extends AnnotatedNodeImpl implements Directive {
  /// The element associated with this directive, or `null` if the AST structure
  /// has not been resolved or if this directive could not be resolved.
  Element _element;

  /// Initialize a newly create directive. Either or both of the [comment] and
  /// [metadata] can be `null` if the directive does not have the corresponding
  /// attribute.
  DirectiveImpl(CommentImpl comment, List<Annotation> metadata)
      : super(comment, metadata);

  @override
  Element get element => _element;

  /// Set the element associated with this directive to be the given [element].
  @override
  set element(Element element) {
    _element = element;
  }
}

/// A do statement.
///
///    doStatement ::=
///        'do' [Statement] 'while' '(' [Expression] ')' ';'
class DoStatementImpl extends StatementImpl implements DoStatement {
  /// The token representing the 'do' keyword.
  @override
  Token doKeyword;

  /// The body of the loop.
  StatementImpl _body;

  /// The token representing the 'while' keyword.
  @override
  Token whileKeyword;

  /// The left parenthesis.
  @override
  Token leftParenthesis;

  /// The condition that determines when the loop will terminate.
  ExpressionImpl _condition;

  /// The right parenthesis.
  @override
  Token rightParenthesis;

  /// The semicolon terminating the statement.
  @override
  Token semicolon;

  /// Initialize a newly created do loop.
  DoStatementImpl(
      this.doKeyword,
      StatementImpl body,
      this.whileKeyword,
      this.leftParenthesis,
      ExpressionImpl condition,
      this.rightParenthesis,
      this.semicolon) {
    _body = _becomeParentOf(body);
    _condition = _becomeParentOf(condition);
  }

  @override
  Token get beginToken => doKeyword;

  @override
  Statement get body => _body;

  @override
  set body(Statement statement) {
    _body = _becomeParentOf(statement as StatementImpl);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(doKeyword)
    ..add(_body)
    ..add(whileKeyword)
    ..add(leftParenthesis)
    ..add(_condition)
    ..add(rightParenthesis)
    ..add(semicolon);

  @override
  Expression get condition => _condition;

  @override
  set condition(Expression expression) {
    _condition = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Token get endToken => semicolon;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitDoStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _body?.accept(visitor);
    _condition?.accept(visitor);
  }
}

/// A dotted name, used in a configuration within an import or export directive.
///
///    dottedName ::=
///        [SimpleIdentifier] ('.' [SimpleIdentifier])*
class DottedNameImpl extends AstNodeImpl implements DottedName {
  /// The components of the identifier.
  NodeList<SimpleIdentifier> _components;

  /// Initialize a newly created dotted name.
  DottedNameImpl(List<SimpleIdentifier> components) {
    _components = NodeListImpl<SimpleIdentifier>(this, components);
  }

  @override
  Token get beginToken => _components.beginToken;

  @override
  // TODO(paulberry): add "." tokens.
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..addAll(_components);

  @override
  NodeList<SimpleIdentifier> get components => _components;

  @override
  Token get endToken => _components.endToken;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitDottedName(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _components.accept(visitor);
  }
}

/// A floating point literal expression.
///
///    doubleLiteral ::=
///        decimalDigit+ ('.' decimalDigit*)? exponent?
///      | '.' decimalDigit+ exponent?
///
///    exponent ::=
///        ('e' | 'E') ('+' | '-')? decimalDigit+
class DoubleLiteralImpl extends LiteralImpl implements DoubleLiteral {
  /// The token representing the literal.
  @override
  Token literal;

  /// The value of the literal.
  @override
  double value;

  /// Initialize a newly created floating point literal.
  DoubleLiteralImpl(this.literal, this.value);

  @override
  Token get beginToken => literal;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()..add(literal);

  @override
  Token get endToken => literal;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitDoubleLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// An empty function body, which can only appear in constructors or abstract
/// methods.
///
///    emptyFunctionBody ::=
///        ';'
class EmptyFunctionBodyImpl extends FunctionBodyImpl
    implements EmptyFunctionBody {
  /// The token representing the semicolon that marks the end of the function
  /// body.
  @override
  Token semicolon;

  /// Initialize a newly created function body.
  EmptyFunctionBodyImpl(this.semicolon);

  @override
  Token get beginToken => semicolon;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitEmptyFunctionBody(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // Empty function bodies have no children.
  }
}

/// An empty statement.
///
///    emptyStatement ::=
///        ';'
class EmptyStatementImpl extends StatementImpl implements EmptyStatement {
  /// The semicolon terminating the statement.
  @override
  Token semicolon;

  /// Initialize a newly created empty statement.
  EmptyStatementImpl(this.semicolon);

  @override
  Token get beginToken => semicolon;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  bool get isSynthetic => semicolon.isSynthetic;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitEmptyStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// The declaration of an enum constant.
class EnumConstantDeclarationImpl extends DeclarationImpl
    implements EnumConstantDeclaration {
  /// The name of the constant.
  SimpleIdentifierImpl _name;

  /// Initialize a newly created enum constant declaration. Either or both of
  /// the [comment] and [metadata] can be `null` if the constant does not have
  /// the corresponding attribute. (Technically, enum constants cannot have
  /// metadata, but we allow it for consistency.)
  EnumConstantDeclarationImpl(
      CommentImpl comment, List<Annotation> metadata, SimpleIdentifierImpl name)
      : super(comment, metadata) {
    _name = _becomeParentOf(name);
  }

  @override
  Iterable<SyntacticEntity> get childEntities =>
      super._childEntities..add(_name);

  @override
  FieldElement get declaredElement => _name?.staticElement as FieldElement;

  @override
  Token get endToken => _name.endToken;

  @override
  Token get firstTokenAfterCommentAndMetadata => _name.beginToken;

  @override
  SimpleIdentifier get name => _name;

  @override
  set name(SimpleIdentifier name) {
    _name = _becomeParentOf(name as SimpleIdentifierImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitEnumConstantDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _name?.accept(visitor);
  }
}

/// The declaration of an enumeration.
///
///    enumType ::=
///        metadata 'enum' [SimpleIdentifier] '{' [SimpleIdentifier]
///        (',' [SimpleIdentifier])* (',')? '}'
class EnumDeclarationImpl extends NamedCompilationUnitMemberImpl
    implements EnumDeclaration {
  /// The 'enum' keyword.
  @override
  Token enumKeyword;

  /// The left curly bracket.
  @override
  Token leftBracket;

  /// The enumeration constants being declared.
  NodeList<EnumConstantDeclaration> _constants;

  /// The right curly bracket.
  @override
  Token rightBracket;

  /// Initialize a newly created enumeration declaration. Either or both of the
  /// [comment] and [metadata] can be `null` if the declaration does not have
  /// the corresponding attribute. The list of [constants] must contain at least
  /// one value.
  EnumDeclarationImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      this.enumKeyword,
      SimpleIdentifierImpl name,
      this.leftBracket,
      List<EnumConstantDeclaration> constants,
      this.rightBracket)
      : super(comment, metadata, name) {
    _constants = NodeListImpl<EnumConstantDeclaration>(this, constants);
  }

  @override
  // TODO(brianwilkerson) Add commas?
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(enumKeyword)
    ..add(_name)
    ..add(leftBracket)
    ..addAll(_constants)
    ..add(rightBracket);

  @override
  NodeList<EnumConstantDeclaration> get constants => _constants;

  @override
  ClassElement get declaredElement => _name?.staticElement as ClassElement;

  @override
  Token get endToken => rightBracket;

  @override
  Token get firstTokenAfterCommentAndMetadata => enumKeyword;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitEnumDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _name?.accept(visitor);
    _constants.accept(visitor);
  }
}

/// Ephemeral identifiers are created as needed to mimic the presence of an
/// empty identifier.
class EphemeralIdentifier extends SimpleIdentifierImpl {
  EphemeralIdentifier(AstNode parent, int location)
      : super(StringToken(TokenType.IDENTIFIER, "", location)) {
    (parent as AstNodeImpl)._becomeParentOf(this);
  }
}

/// An export directive.
///
///    exportDirective ::=
///        [Annotation] 'export' [StringLiteral] [Combinator]* ';'
class ExportDirectiveImpl extends NamespaceDirectiveImpl
    implements ExportDirective {
  /// Initialize a newly created export directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute. The list of [combinators] can be `null` if there
  /// are no combinators.
  ExportDirectiveImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      Token keyword,
      StringLiteralImpl libraryUri,
      List<Configuration> configurations,
      List<Combinator> combinators,
      Token semicolon)
      : super(comment, metadata, keyword, libraryUri, configurations,
            combinators, semicolon);

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(keyword)
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
  E accept<E>(AstVisitor<E> visitor) => visitor.visitExportDirective(this);

  @override
  void visitChildren(AstVisitor visitor) {
    configurations.accept(visitor);
    super.visitChildren(visitor);
    combinators.accept(visitor);
  }
}

/// A function body consisting of a single expression.
///
///    expressionFunctionBody ::=
///        'async'? '=>' [Expression] ';'
class ExpressionFunctionBodyImpl extends FunctionBodyImpl
    implements ExpressionFunctionBody {
  /// The token representing the 'async' keyword, or `null` if there is no such
  /// keyword.
  @override
  Token keyword;

  /// The token introducing the expression that represents the body of the
  /// function.
  @override
  Token functionDefinition;

  /// The expression representing the body of the function.
  ExpressionImpl _expression;

  /// The semicolon terminating the statement.
  @override
  Token semicolon;

  /// Initialize a newly created function body consisting of a block of
  /// statements. The [keyword] can be `null` if the function body is not an
  /// async function body.
  ExpressionFunctionBodyImpl(this.keyword, this.functionDefinition,
      ExpressionImpl expression, this.semicolon) {
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
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
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

  @override
  Expression get expression => _expression;

  @override
  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  bool get isAsynchronous => keyword != null;

  @override
  bool get isSynchronous => keyword == null;

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitExpressionFunctionBody(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression?.accept(visitor);
  }
}

/// A node that represents an expression.
///
///    expression ::=
///        [AssignmentExpression]
///      | [ConditionalExpression] cascadeSection*
///      | [ThrowExpression]
abstract class ExpressionImpl extends AstNodeImpl
    implements CollectionElementImpl, Expression {
  /// The static type of this expression, or `null` if the AST structure has not
  /// been resolved.
  @override
  DartType staticType;

  /// An expression _e_ is said to _occur in a constant context_,
  /// * if _e_ is an element of a constant list literal, or a key or value of an
  ///   entry of a constant map literal.
  /// * if _e_ is an actual argument of a constant object expression or of a
  ///   metadata annotation.
  /// * if _e_ is the initializing expression of a constant variable
  ///   declaration.
  /// * if _e_ is a switch case expression.
  /// * if _e_ is an immediate subexpression of an expression _e1_ which occurs
  ///   in a constant context, unless _e1_ is a `throw` expression or a function
  ///   literal.
  ///
  /// This roughly means that everything which is inside a syntactically
  /// constant expression is in a constant context. A `throw` expression is
  /// currently not allowed in a constant expression, but extensions affecting
  /// that status may be considered. A similar situation arises for function
  /// literals.
  ///
  /// Note that the default value of an optional formal parameter is _not_ a
  /// constant context. This choice reserves some freedom to modify the
  /// semantics of default values.
  bool get inConstantContext {
    AstNode child = this;
    while (child is Expression ||
        child is ArgumentList ||
        child is MapLiteralEntry ||
        child is SpreadElement ||
        child is IfElement ||
        child is ForElement) {
      AstNode parent = child.parent;
      if (parent is TypedLiteralImpl && parent.constKeyword != null) {
        // Inside an explicitly `const` list or map literal.
        return true;
      } else if (parent is InstanceCreationExpression &&
          parent.keyword?.keyword == Keyword.CONST) {
        // Inside an explicitly `const` instance creation expression.
        return true;
      } else if (parent is Annotation) {
        // Inside an annotation.
        return true;
      } else if (parent is VariableDeclaration) {
        AstNode grandParent = parent.parent;
        // Inside the initializer for a `const` variable declaration.
        return grandParent is VariableDeclarationList &&
            grandParent.keyword?.keyword == Keyword.CONST;
      } else if (parent is SwitchCase) {
        // Inside a switch case.
        return true;
      }
      child = parent;
    }
    return false;
  }

  @override
  bool get isAssignable => false;

  @override
  ParameterElement get staticParameterElement {
    AstNode parent = this.parent;
    if (parent is ArgumentListImpl) {
      return parent._getStaticParameterElementFor(this);
    } else if (parent is IndexExpressionImpl) {
      if (identical(parent.index, this)) {
        return parent._staticParameterElementForIndex;
      }
    } else if (parent is BinaryExpressionImpl) {
      if (identical(parent.rightOperand, this)) {
        var parameters = parent.staticInvokeType?.parameters;
        if (parameters != null && parameters.isNotEmpty) {
          return parameters[0];
        }
        return null;
      }
    } else if (parent is AssignmentExpressionImpl) {
      if (identical(parent.rightHandSide, this)) {
        return parent._staticParameterElementForRightHandSide;
      }
    } else if (parent is PrefixExpressionImpl) {
      return parent._staticParameterElementForOperand;
    } else if (parent is PostfixExpressionImpl) {
      return parent._staticParameterElementForOperand;
    }
    return null;
  }

  @override
  Expression get unParenthesized => this;
}

/// An expression used as a statement.
///
///    expressionStatement ::=
///        [Expression]? ';'
class ExpressionStatementImpl extends StatementImpl
    implements ExpressionStatement {
  /// The expression that comprises the statement.
  ExpressionImpl _expression;

  /// The semicolon terminating the statement, or `null` if the expression is a
  /// function expression and therefore isn't followed by a semicolon.
  @override
  Token semicolon;

  /// Initialize a newly created expression statement.
  ExpressionStatementImpl(ExpressionImpl expression, this.semicolon) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Token get beginToken => _expression.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(_expression)..add(semicolon);

  @override
  Token get endToken {
    if (semicolon != null) {
      return semicolon;
    }
    return _expression.endToken;
  }

  @override
  Expression get expression => _expression;

  @override
  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  bool get isSynthetic => _expression.isSynthetic && semicolon.isSynthetic;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitExpressionStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression?.accept(visitor);
  }
}

/// The "extends" clause in a class declaration.
///
///    extendsClause ::=
///        'extends' [TypeName]
class ExtendsClauseImpl extends AstNodeImpl implements ExtendsClause {
  /// The token representing the 'extends' keyword.
  @override
  Token extendsKeyword;

  /// The name of the class that is being extended.
  TypeNameImpl _superclass;

  /// Initialize a newly created extends clause.
  ExtendsClauseImpl(this.extendsKeyword, TypeNameImpl superclass) {
    _superclass = _becomeParentOf(superclass);
  }

  @override
  Token get beginToken => extendsKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(extendsKeyword)..add(_superclass);

  @override
  Token get endToken => _superclass.endToken;

  @override
  TypeName get superclass => _superclass;

  @override
  set superclass(TypeName name) {
    _superclass = _becomeParentOf(name as TypeNameImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitExtendsClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _superclass?.accept(visitor);
  }
}

/// The declaration of an extension of a type.
///
///    extension ::=
///        'extension' [SimpleIdentifier] [TypeParameterList]?
///        'on' [TypeAnnotation] '{' [ClassMember]* '}'
///
/// Clients may not extend, implement or mix-in this class.
class ExtensionDeclarationImpl extends CompilationUnitMemberImpl
    implements ExtensionDeclaration {
  @override
  Token extensionKeyword;

  /// The name of the extension, or `null` if the extension does not have a
  /// name.
  SimpleIdentifierImpl _name;

  /// The type parameters for the extension, or `null` if the extension does not
  /// have any type parameters.
  TypeParameterListImpl _typeParameters;

  @override
  Token onKeyword;

  /// The type that is being extended.
  TypeAnnotationImpl _extendedType;

  @override
  Token leftBracket;

  /// The members being added to the extended class.
  NodeList<ClassMember> _members;

  @override
  Token rightBracket;

  ExtensionElement _declaredElement;

  ExtensionDeclarationImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      this.extensionKeyword,
      SimpleIdentifierImpl name,
      TypeParameterListImpl typeParameters,
      this.onKeyword,
      TypeAnnotationImpl extendedType,
      this.leftBracket,
      List<ClassMember> members,
      this.rightBracket)
      : super(comment, metadata) {
    _name = _becomeParentOf(name);
    _typeParameters = _becomeParentOf(typeParameters);
    _extendedType = _becomeParentOf(extendedType);
    _members = NodeListImpl<ClassMember>(this, members);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(extensionKeyword)
    ..add(name)
    ..add(typeParameters)
    ..add(onKeyword)
    ..add(extendedType)
    ..add(leftBracket)
    ..addAll(members)
    ..add(rightBracket);

  @override
  ExtensionElement get declaredElement => _declaredElement;

  /// Set the element declared by this declaration to the given [element].
  set declaredElement(ExtensionElement element) {
    _declaredElement = element;
  }

  @override
  Token get endToken => rightBracket;

  @override
  TypeAnnotation get extendedType => _extendedType;

  set extendedType(TypeAnnotation extendedClass) {
    _extendedType = _becomeParentOf(extendedClass as TypeAnnotationImpl);
  }

  @override
  Token get firstTokenAfterCommentAndMetadata => extensionKeyword;

  @override
  NodeList<ClassMember> get members => _members;

  @override
  SimpleIdentifier get name => _name;

  set name(SimpleIdentifier identifier) {
    _name = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  TypeParameterList get typeParameters => _typeParameters;

  set typeParameters(TypeParameterList typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitExtensionDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    name?.accept(visitor);
    _typeParameters?.accept(visitor);
    _extendedType?.accept(visitor);
    _members.accept(visitor);
  }
}

/// An override to force resolution to choose a member from a specific
/// extension.
///
///    extensionOverride ::=
///        [Identifier] [TypeArgumentList]? [ArgumentList]
class ExtensionOverrideImpl extends ExpressionImpl
    implements ExtensionOverride {
  /// The list of arguments to the override. In valid code this will contain a
  /// single argument, which evaluates to the object being extended.
  ArgumentListImpl _argumentList;

  /// The name of the extension being selected.
  IdentifierImpl _extensionName;

  /// The type arguments to be applied to the extension, or `null` if no type
  /// arguments were provided.
  TypeArgumentListImpl _typeArguments;

  @override
  List<DartType> typeArgumentTypes;

  @override
  DartType extendedType;

  ExtensionOverrideImpl(IdentifierImpl extensionName,
      TypeArgumentListImpl typeArguments, ArgumentListImpl argumentList) {
    _extensionName = _becomeParentOf(extensionName);
    _typeArguments = _becomeParentOf(typeArguments);
    _argumentList = _becomeParentOf(argumentList);
  }

  @override
  ArgumentList get argumentList => _argumentList;

  set argumentList(ArgumentList argumentList) {
    _argumentList = _becomeParentOf(argumentList as ArgumentListImpl);
  }

  @override
  Token get beginToken => _extensionName?.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_extensionName)
    ..add(_typeArguments)
    ..add(_argumentList);

  @override
  Token get endToken => _argumentList.endToken;

  @override
  Identifier get extensionName => _extensionName;

  set extensionName(Identifier extensionName) {
    _extensionName = _becomeParentOf(extensionName as IdentifierImpl);
  }

  @override
  bool get isNullAware {
    var nextType = argumentList.endToken.next.type;
    return nextType == TokenType.QUESTION_PERIOD ||
        nextType == TokenType.QUESTION;
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  ExtensionElement get staticElement => extensionName.staticElement;

  @override
  TypeArgumentList get typeArguments => _typeArguments;

  set typeArguments(TypeArgumentList typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments as TypeArgumentListImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) {
    return visitor.visitExtensionOverride(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _extensionName?.accept(visitor);
    _typeArguments?.accept(visitor);
    _argumentList?.accept(visitor);
  }
}

/// The declaration of one or more fields of the same type.
///
///    fieldDeclaration ::=
///        'static'? [VariableDeclarationList] ';'
class FieldDeclarationImpl extends ClassMemberImpl implements FieldDeclaration {
  @override
  Token abstractKeyword;

  /// The 'covariant' keyword, or `null` if the keyword was not used.
  @override
  Token covariantKeyword;

  @override
  Token externalKeyword;

  /// The token representing the 'static' keyword, or `null` if the fields are
  /// not static.
  @override
  Token staticKeyword;

  /// The fields being declared.
  VariableDeclarationListImpl _fieldList;

  /// The semicolon terminating the declaration.
  @override
  Token semicolon;

  /// Initialize a newly created field declaration. Either or both of the
  /// [comment] and [metadata] can be `null` if the declaration does not have
  /// the corresponding attribute. The [staticKeyword] can be `null` if the
  /// field is not a static field.
  FieldDeclarationImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      this.abstractKeyword,
      this.covariantKeyword,
      this.externalKeyword,
      this.staticKeyword,
      VariableDeclarationListImpl fieldList,
      this.semicolon)
      : super(comment, metadata) {
    _fieldList = _becomeParentOf(fieldList);
  }

  @override
  Iterable<SyntacticEntity> get childEntities =>
      super._childEntities..add(staticKeyword)..add(_fieldList)..add(semicolon);

  @override
  Element get declaredElement => null;

  @override
  Token get endToken => semicolon;

  @override
  VariableDeclarationList get fields => _fieldList;

  @override
  set fields(VariableDeclarationList fields) {
    _fieldList = _becomeParentOf(fields as VariableDeclarationListImpl);
  }

  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (abstractKeyword != null) {
      return abstractKeyword;
    } else if (externalKeyword != null) {
      return externalKeyword;
    } else if (covariantKeyword != null) {
      return covariantKeyword;
    } else if (staticKeyword != null) {
      return staticKeyword;
    }
    return _fieldList.beginToken;
  }

  @override
  bool get isStatic => staticKeyword != null;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitFieldDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _fieldList?.accept(visitor);
  }
}

/// A field formal parameter.
///
///    fieldFormalParameter ::=
///        ('final' [TypeName] | 'const' [TypeName] | 'var' | [TypeName])?
///        'this' '.' [SimpleIdentifier]
///        ([TypeParameterList]? [FormalParameterList])?
class FieldFormalParameterImpl extends NormalFormalParameterImpl
    implements FieldFormalParameter {
  /// The token representing either the 'final', 'const' or 'var' keyword, or
  /// `null` if no keyword was used.
  @override
  Token keyword;

  /// The name of the declared type of the parameter, or `null` if the parameter
  /// does not have a declared type.
  TypeAnnotationImpl _type;

  /// The token representing the 'this' keyword.
  @override
  Token thisKeyword;

  /// The token representing the period.
  @override
  Token period;

  /// The type parameters associated with the method, or `null` if the method is
  /// not a generic method.
  TypeParameterListImpl _typeParameters;

  /// The parameters of the function-typed parameter, or `null` if this is not a
  /// function-typed field formal parameter.
  FormalParameterListImpl _parameters;

  @override
  Token question;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute. The [keyword] can be `null` if there is a type.
  /// The [type] must be `null` if the keyword is 'var'. The [thisKeyword] and
  /// [period] can be `null` if the keyword 'this' was not provided.  The
  /// [parameters] can be `null` if this is not a function-typed field formal
  /// parameter.
  FieldFormalParameterImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      Token covariantKeyword,
      Token requiredKeyword,
      this.keyword,
      TypeAnnotationImpl type,
      this.thisKeyword,
      this.period,
      SimpleIdentifierImpl identifier,
      TypeParameterListImpl typeParameters,
      FormalParameterListImpl parameters,
      this.question)
      : super(
            comment, metadata, covariantKeyword, requiredKeyword, identifier) {
    _type = _becomeParentOf(type);
    _typeParameters = _becomeParentOf(typeParameters);
    _parameters = _becomeParentOf(parameters);
  }

  @override
  Token get beginToken {
    NodeList<Annotation> metadata = this.metadata;
    if (metadata.isNotEmpty) {
      return metadata.beginToken;
    } else if (requiredKeyword != null) {
      return requiredKeyword;
    } else if (covariantKeyword != null) {
      return covariantKeyword;
    } else if (keyword != null) {
      return keyword;
    } else if (_type != null) {
      return _type.beginToken;
    }
    return thisKeyword;
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(keyword)
    ..add(_type)
    ..add(thisKeyword)
    ..add(period)
    ..add(identifier)
    ..add(_parameters);

  @override
  Token get endToken {
    return question ?? _parameters?.endToken ?? identifier.endToken;
  }

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @override
  FormalParameterList get parameters => _parameters;

  @override
  set parameters(FormalParameterList parameters) {
    _parameters = _becomeParentOf(parameters as FormalParameterListImpl);
  }

  @override
  TypeAnnotation get type => _type;

  @override
  set type(TypeAnnotation type) {
    _type = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  TypeParameterList get typeParameters => _typeParameters;

  @override
  set typeParameters(TypeParameterList typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitFieldFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _type?.accept(visitor);
    identifier?.accept(visitor);
    _typeParameters?.accept(visitor);
    _parameters?.accept(visitor);
  }
}

abstract class ForEachPartsImpl extends ForLoopPartsImpl
    implements ForEachParts {
  @override
  Token inKeyword;

  /// The expression evaluated to produce the iterator.
  ExpressionImpl _iterable;

  /// Initialize a newly created for-each statement whose loop control variable
  /// is declared internally (in the for-loop part). The [awaitKeyword] can be
  /// `null` if this is not an asynchronous for loop.
  ForEachPartsImpl(this.inKeyword, ExpressionImpl iterator) {
    _iterable = _becomeParentOf(iterator);
  }

  @override
  Token get beginToken => inKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(inKeyword)..add(_iterable);

  @override
  Token get endToken => _iterable.endToken;

  @override
  Expression get iterable => _iterable;

  set iterable(Expression expression) {
    _iterable = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _iterable?.accept(visitor);
  }
}

class ForEachPartsWithDeclarationImpl extends ForEachPartsImpl
    implements ForEachPartsWithDeclaration {
  /// The declaration of the loop variable.
  DeclaredIdentifierImpl _loopVariable;

  /// Initialize a newly created for-each statement whose loop control variable
  /// is declared internally (inside the for-loop part).
  ForEachPartsWithDeclarationImpl(DeclaredIdentifierImpl loopVariable,
      Token inKeyword, ExpressionImpl iterator)
      : super(inKeyword, iterator) {
    _loopVariable = _becomeParentOf(loopVariable);
  }

  @override
  Token get beginToken => _loopVariable.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_loopVariable)
    ..addAll(super.childEntities);

  @override
  DeclaredIdentifier get loopVariable => _loopVariable;

  set loopVariable(DeclaredIdentifier variable) {
    _loopVariable = _becomeParentOf(variable as DeclaredIdentifierImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitForEachPartsWithDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _loopVariable?.accept(visitor);
    super.visitChildren(visitor);
  }
}

class ForEachPartsWithIdentifierImpl extends ForEachPartsImpl
    implements ForEachPartsWithIdentifier {
  /// The loop variable.
  SimpleIdentifierImpl _identifier;

  /// Initialize a newly created for-each statement whose loop control variable
  /// is declared externally (outside the for-loop part).
  ForEachPartsWithIdentifierImpl(
      SimpleIdentifierImpl identifier, Token inKeyword, ExpressionImpl iterator)
      : super(inKeyword, iterator) {
    _identifier = _becomeParentOf(identifier);
  }

  @override
  Token get beginToken => _identifier.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_identifier)
    ..addAll(super.childEntities);

  @override
  SimpleIdentifier get identifier => _identifier;

  set identifier(SimpleIdentifier identifier) {
    _identifier = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitForEachPartsWithIdentifier(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _identifier?.accept(visitor);
    _iterable?.accept(visitor);
  }
}

class ForElementImpl extends CollectionElementImpl
    with ForMixin
    implements ForElement {
  /// The body of the loop.
  CollectionElementImpl _body;

  /// Initialize a newly created for element.
  ForElementImpl(
      Token awaitKeyword,
      Token forKeyword,
      Token leftParenthesis,
      ForLoopPartsImpl forLoopParts,
      Token rightParenthesis,
      CollectionElementImpl body) {
    this.awaitKeyword = awaitKeyword;
    this.forKeyword = forKeyword;
    this.leftParenthesis = leftParenthesis;
    _forLoopParts = _becomeParentOf(forLoopParts);
    this.rightParenthesis = rightParenthesis;
    _body = _becomeParentOf(body);
  }

  @override
  CollectionElement get body => _body;

  set body(CollectionElement statement) {
    _body = _becomeParentOf(statement as CollectionElementImpl);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..addAll(super.childEntities)
    ..add(_body);

  @override
  Token get endToken => _body.endToken;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitForElement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _forLoopParts?.accept(visitor);
    _body?.accept(visitor);
  }
}

abstract class ForLoopPartsImpl extends AstNodeImpl implements ForLoopParts {}

/// A node representing a parameter to a function.
///
///    formalParameter ::=
///        [NormalFormalParameter]
///      | [DefaultFormalParameter]
abstract class FormalParameterImpl extends AstNodeImpl
    implements FormalParameter {
  @override
  ParameterElement get declaredElement {
    SimpleIdentifier identifier = this.identifier;
    if (identifier == null) {
      return null;
    }
    return identifier.staticElement as ParameterElement;
  }

  @override
  bool get isNamed => kind.isNamed;

  @override
  bool get isOptional => kind.isOptional;

  @override
  bool get isOptionalNamed => kind.isOptionalNamed;

  @override
  bool get isOptionalPositional => kind.isOptionalPositional;

  @override
  bool get isPositional => kind.isPositional;

  @override
  bool get isRequired => kind.isRequired;

  @override
  bool get isRequiredNamed => kind.isRequiredNamed;

  @override
  bool get isRequiredPositional => kind.isRequiredPositional;

  /// Return the kind of this parameter.
  ParameterKind get kind;
}

/// The formal parameter list of a method declaration, function declaration, or
/// function type alias.
///
/// While the grammar requires all optional formal parameters to follow all of
/// the normal formal parameters and at most one grouping of optional formal
/// parameters, this class does not enforce those constraints. All parameters
/// are flattened into a single list, which can have any or all kinds of
/// parameters (normal, named, and positional) in any order.
///
///    formalParameterList ::=
///        '(' ')'
///      | '(' normalFormalParameters (',' optionalFormalParameters)? ')'
///      | '(' optionalFormalParameters ')'
///
///    normalFormalParameters ::=
///        [NormalFormalParameter] (',' [NormalFormalParameter])*
///
///    optionalFormalParameters ::=
///        optionalPositionalFormalParameters
///      | namedFormalParameters
///
///    optionalPositionalFormalParameters ::=
///        '[' [DefaultFormalParameter] (',' [DefaultFormalParameter])* ']'
///
///    namedFormalParameters ::=
///        '{' [DefaultFormalParameter] (',' [DefaultFormalParameter])* '}'
class FormalParameterListImpl extends AstNodeImpl
    implements FormalParameterList {
  /// The left parenthesis.
  @override
  Token leftParenthesis;

  /// The parameters associated with the method.
  NodeList<FormalParameter> _parameters;

  /// The left square bracket ('[') or left curly brace ('{') introducing the
  /// optional parameters, or `null` if there are no optional parameters.
  @override
  Token leftDelimiter;

  /// The right square bracket (']') or right curly brace ('}') terminating the
  /// optional parameters, or `null` if there are no optional parameters.
  @override
  Token rightDelimiter;

  /// The right parenthesis.
  @override
  Token rightParenthesis;

  /// Initialize a newly created parameter list. The list of [parameters] can be
  /// `null` if there are no parameters. The [leftDelimiter] and
  /// [rightDelimiter] can be `null` if there are no optional parameters.
  FormalParameterListImpl(
      this.leftParenthesis,
      List<FormalParameter> parameters,
      this.leftDelimiter,
      this.rightDelimiter,
      this.rightParenthesis) {
    _parameters = NodeListImpl<FormalParameter>(this, parameters);
  }

  @override
  Token get beginToken => leftParenthesis;

  @override
  Iterable<SyntacticEntity> get childEntities {
    // TODO(paulberry): include commas.
    ChildEntities result = ChildEntities()..add(leftParenthesis);
    bool leftDelimiterNeeded = leftDelimiter != null;
    int length = _parameters.length;
    for (int i = 0; i < length; i++) {
      FormalParameter parameter = _parameters[i];
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

  @override
  List<ParameterElement> get parameterElements {
    int count = _parameters.length;
    List<ParameterElement> types = List<ParameterElement>(count);
    for (int i = 0; i < count; i++) {
      types[i] = _parameters[i].declaredElement;
    }
    return types;
  }

  @override
  NodeList<FormalParameter> get parameters => _parameters;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitFormalParameterList(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _parameters.accept(visitor);
  }
}

mixin ForMixin on AstNodeImpl {
  Token awaitKeyword;

  Token forKeyword;

  Token leftParenthesis;

  ForLoopPartsImpl _forLoopParts;

  Token rightParenthesis;

  @override
  Token get beginToken => awaitKeyword ?? forKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(awaitKeyword)
    ..add(forKeyword)
    ..add(leftParenthesis)
    ..add(_forLoopParts)
    ..add(rightParenthesis);

  ForLoopParts get forLoopParts => _forLoopParts;

  set forLoopParts(ForLoopParts forLoopParts) {
    _forLoopParts = _becomeParentOf(forLoopParts as ForLoopPartsImpl);
  }
}

abstract class ForPartsImpl extends ForLoopPartsImpl implements ForParts {
  @override
  Token leftSeparator;

  /// The condition used to determine when to terminate the loop, or `null` if
  /// there is no condition.
  ExpressionImpl _condition;

  @override
  Token rightSeparator;

  /// The list of expressions run after each execution of the loop body.
  NodeList<Expression> _updaters;

  /// Initialize a newly created for statement. Either the [variableList] or the
  /// [initialization] must be `null`. Either the [condition] and the list of
  /// [updaters] can be `null` if the loop does not have the corresponding
  /// attribute.
  ForPartsImpl(this.leftSeparator, ExpressionImpl condition,
      this.rightSeparator, List<Expression> updaters) {
    _condition = _becomeParentOf(condition);
    _updaters = NodeListImpl<Expression>(this, updaters);
  }

  @override
  Token get beginToken => leftSeparator;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(leftSeparator)
    ..add(_condition)
    ..add(rightSeparator)
    ..addAll(_updaters);

  @override
  Expression get condition => _condition;

  set condition(Expression expression) {
    _condition = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Token get endToken => _updaters?.endToken ?? rightSeparator;

  @override
  NodeList<Expression> get updaters => _updaters;

  @override
  void visitChildren(AstVisitor visitor) {
    _condition?.accept(visitor);
    _updaters.accept(visitor);
  }
}

class ForPartsWithDeclarationsImpl extends ForPartsImpl
    implements ForPartsWithDeclarations {
  /// The declaration of the loop variables, or `null` if there are no
  /// variables.  Note that a for statement cannot have both a variable list and
  /// an initialization expression, but can validly have neither.
  VariableDeclarationListImpl _variableList;

  /// Initialize a newly created for statement. Both the [condition] and the
  /// list of [updaters] can be `null` if the loop does not have the
  /// corresponding attribute.
  ForPartsWithDeclarationsImpl(
      VariableDeclarationListImpl variableList,
      Token leftSeparator,
      ExpressionImpl condition,
      Token rightSeparator,
      List<Expression> updaters)
      : super(leftSeparator, condition, rightSeparator, updaters) {
    _variableList = _becomeParentOf(variableList);
  }

  @override
  Token get beginToken => _variableList?.beginToken ?? super.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_variableList)
    ..addAll(super.childEntities);

  @override
  VariableDeclarationList get variables => _variableList;

  set variables(VariableDeclarationList variableList) {
    _variableList =
        _becomeParentOf(variableList as VariableDeclarationListImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitForPartsWithDeclarations(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _variableList?.accept(visitor);
    super.visitChildren(visitor);
  }
}

class ForPartsWithExpressionImpl extends ForPartsImpl
    implements ForPartsWithExpression {
  /// The initialization expression, or `null` if there is no initialization
  /// expression. Note that a for statement cannot have both a variable list and
  /// an initialization expression, but can validly have neither.
  ExpressionImpl _initialization;

  /// Initialize a newly created for statement. Both the [condition] and the
  /// list of [updaters] can be `null` if the loop does not have the
  /// corresponding attribute.
  ForPartsWithExpressionImpl(ExpressionImpl initialization, Token leftSeparator,
      ExpressionImpl condition, Token rightSeparator, List<Expression> updaters)
      : super(leftSeparator, condition, rightSeparator, updaters) {
    _initialization = _becomeParentOf(initialization);
  }

  @override
  Token get beginToken => initialization?.beginToken ?? super.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_initialization)
    ..addAll(super.childEntities);

  @override
  Expression get initialization => _initialization;

  set initialization(Expression initialization) {
    _initialization = _becomeParentOf(initialization as ExpressionImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitForPartsWithExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _initialization?.accept(visitor);
    super.visitChildren(visitor);
  }
}

class ForStatementImpl extends StatementImpl
    with ForMixin
    implements ForStatement {
  /// The body of the loop.
  StatementImpl _body;

  /// Initialize a newly created for statement.
  ForStatementImpl(
      Token awaitKeyword,
      Token forKeyword,
      Token leftParenthesis,
      ForLoopPartsImpl forLoopParts,
      Token rightParenthesis,
      StatementImpl body) {
    this.awaitKeyword = awaitKeyword;
    this.forKeyword = forKeyword;
    this.leftParenthesis = leftParenthesis;
    _forLoopParts = _becomeParentOf(forLoopParts);
    this.rightParenthesis = rightParenthesis;
    _body = _becomeParentOf(body);
  }

  @override
  Statement get body => _body;

  set body(Statement statement) {
    _body = _becomeParentOf(statement as StatementImpl);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..addAll(super.childEntities)
    ..add(_body);

  @override
  Token get endToken => _body.endToken;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitForStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _forLoopParts?.accept(visitor);
    _body?.accept(visitor);
  }
}

/// A node representing the body of a function or method.
///
///    functionBody ::=
///        [BlockFunctionBody]
///      | [EmptyFunctionBody]
///      | [ExpressionFunctionBody]
abstract class FunctionBodyImpl extends AstNodeImpl implements FunctionBody {
  /// Additional information about local variables and parameters that are
  /// declared within this function body or any enclosing function body.  `null`
  /// if resolution has not yet been performed.
  LocalVariableInfo localVariableInfo;

  /// Return `true` if this function body is asynchronous.
  @override
  bool get isAsynchronous => false;

  /// Return `true` if this function body is a generator.
  @override
  bool get isGenerator => false;

  /// Return `true` if this function body is synchronous.
  @override
  bool get isSynchronous => true;

  /// Return the token representing the 'async' or 'sync' keyword, or `null` if
  /// there is no such keyword.
  @override
  Token get keyword => null;

  /// Return the star following the 'async' or 'sync' keyword, or `null` if
  /// there is no star.
  @override
  Token get star => null;

  @override
  bool isPotentiallyMutatedInClosure(VariableElement variable) {
    if (localVariableInfo == null) {
      throw StateError('Resolution has not yet been performed');
    }
    return localVariableInfo.potentiallyMutatedInClosure.contains(variable);
  }

  @override
  bool isPotentiallyMutatedInScope(VariableElement variable) {
    if (localVariableInfo == null) {
      throw StateError('Resolution has not yet been performed');
    }
    return localVariableInfo.potentiallyMutatedInScope.contains(variable);
  }
}

/// A top-level declaration.
///
///    functionDeclaration ::=
///        'external' functionSignature
///      | functionSignature [FunctionBody]
///
///    functionSignature ::=
///        [Type]? ('get' | 'set')? [SimpleIdentifier] [FormalParameterList]
class FunctionDeclarationImpl extends NamedCompilationUnitMemberImpl
    implements FunctionDeclaration {
  /// The token representing the 'external' keyword, or `null` if this is not an
  /// external function.
  @override
  Token externalKeyword;

  /// The return type of the function, or `null` if no return type was declared.
  TypeAnnotationImpl _returnType;

  /// The token representing the 'get' or 'set' keyword, or `null` if this is a
  /// function declaration rather than a property declaration.
  @override
  Token propertyKeyword;

  /// The function expression being wrapped.
  FunctionExpressionImpl _functionExpression;

  /// Initialize a newly created function declaration. Either or both of the
  /// [comment] and [metadata] can be `null` if the function does not have the
  /// corresponding attribute. The [externalKeyword] can be `null` if the
  /// function is not an external function. The [returnType] can be `null` if no
  /// return type was specified. The [propertyKeyword] can be `null` if the
  /// function is neither a getter or a setter.
  FunctionDeclarationImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      this.externalKeyword,
      TypeAnnotationImpl returnType,
      this.propertyKeyword,
      SimpleIdentifierImpl name,
      FunctionExpressionImpl functionExpression)
      : super(comment, metadata, name) {
    _returnType = _becomeParentOf(returnType);
    _functionExpression = _becomeParentOf(functionExpression);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(externalKeyword)
    ..add(_returnType)
    ..add(propertyKeyword)
    ..add(_name)
    ..add(_functionExpression);

  @override
  ExecutableElement get declaredElement =>
      _name?.staticElement as ExecutableElement;

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

  @override
  FunctionExpression get functionExpression => _functionExpression;

  @override
  set functionExpression(FunctionExpression functionExpression) {
    _functionExpression =
        _becomeParentOf(functionExpression as FunctionExpressionImpl);
  }

  @override
  bool get isGetter => propertyKeyword?.keyword == Keyword.GET;

  @override
  bool get isSetter => propertyKeyword?.keyword == Keyword.SET;

  @override
  TypeAnnotation get returnType => _returnType;

  @override
  set returnType(TypeAnnotation type) {
    _returnType = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitFunctionDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _returnType?.accept(visitor);
    _name?.accept(visitor);
    _functionExpression?.accept(visitor);
  }
}

/// A [FunctionDeclaration] used as a statement.
class FunctionDeclarationStatementImpl extends StatementImpl
    implements FunctionDeclarationStatement {
  /// The function declaration being wrapped.
  FunctionDeclarationImpl _functionDeclaration;

  /// Initialize a newly created function declaration statement.
  FunctionDeclarationStatementImpl(
      FunctionDeclarationImpl functionDeclaration) {
    _functionDeclaration = _becomeParentOf(functionDeclaration);
  }

  @override
  Token get beginToken => _functionDeclaration.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(_functionDeclaration);

  @override
  Token get endToken => _functionDeclaration.endToken;

  @override
  FunctionDeclaration get functionDeclaration => _functionDeclaration;

  @override
  set functionDeclaration(FunctionDeclaration functionDeclaration) {
    _functionDeclaration =
        _becomeParentOf(functionDeclaration as FunctionDeclarationImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitFunctionDeclarationStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _functionDeclaration?.accept(visitor);
  }
}

/// A function expression.
///
///    functionExpression ::=
///        [TypeParameterList]? [FormalParameterList] [FunctionBody]
class FunctionExpressionImpl extends ExpressionImpl
    implements FunctionExpression {
  /// The type parameters associated with the method, or `null` if the method is
  /// not a generic method.
  TypeParameterListImpl _typeParameters;

  /// The parameters associated with the function, or `null` if the function is
  /// part of a top-level getter.
  FormalParameterListImpl _parameters;

  /// The body of the function, or `null` if this is an external function.
  FunctionBodyImpl _body;

  @override
  ExecutableElement declaredElement;

  /// Initialize a newly created function declaration.
  FunctionExpressionImpl(TypeParameterListImpl typeParameters,
      FormalParameterListImpl parameters, FunctionBodyImpl body) {
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
    throw StateError("Non-external functions must have a body");
  }

  @override
  FunctionBody get body => _body;

  @override
  set body(FunctionBody functionBody) {
    _body = _becomeParentOf(functionBody as FunctionBodyImpl);
  }

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(_parameters)..add(_body);

  @override
  Token get endToken {
    if (_body != null) {
      return _body.endToken;
    } else if (_parameters != null) {
      return _parameters.endToken;
    }
    // This should never be reached because external functions must be named,
    // hence either the body or the name should be non-null.
    throw StateError("Non-external functions must have a body");
  }

  @override
  FormalParameterList get parameters => _parameters;

  @override
  set parameters(FormalParameterList parameters) {
    _parameters = _becomeParentOf(parameters as FormalParameterListImpl);
  }

  @override
  Precedence get precedence => Precedence.primary;

  @override
  TypeParameterList get typeParameters => _typeParameters;

  @override
  set typeParameters(TypeParameterList typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitFunctionExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _typeParameters?.accept(visitor);
    _parameters?.accept(visitor);
    _body?.accept(visitor);
  }
}

/// The invocation of a function resulting from evaluating an expression.
/// Invocations of methods and other forms of functions are represented by
/// [MethodInvocation] nodes. Invocations of getters and setters are represented
/// by either [PrefixedIdentifier] or [PropertyAccess] nodes.
///
///    functionExpressionInvocation ::=
///        [Expression] [TypeArgumentList]? [ArgumentList]
class FunctionExpressionInvocationImpl extends InvocationExpressionImpl
    with NullShortableExpressionImpl
    implements FunctionExpressionInvocation {
  /// The expression producing the function being invoked.
  ExpressionImpl _function;

  /// The element associated with the function being invoked based on static
  /// type information, or `null` if the AST structure has not been resolved or
  /// the function could not be resolved.
  @override
  ExecutableElement staticElement;

  /// Initialize a newly created function expression invocation.
  FunctionExpressionInvocationImpl(ExpressionImpl function,
      TypeArgumentListImpl typeArguments, ArgumentListImpl argumentList)
      : super(typeArguments, argumentList) {
    _function = _becomeParentOf(function);
  }

  @override
  Token get beginToken => _function.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(_function)..add(_argumentList);

  @override
  Token get endToken => _argumentList.endToken;

  @override
  Expression get function => _function;

  @override
  set function(Expression expression) {
    _function = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  AstNode get _nullShortingExtensionCandidate => parent;

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitFunctionExpressionInvocation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _function?.accept(visitor);
    _typeArguments?.accept(visitor);
    _argumentList?.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression child) => identical(child, _function);
}

/// A function type alias.
///
///    functionTypeAlias ::=
///        functionPrefix [TypeParameterList]? [FormalParameterList] ';'
///
///    functionPrefix ::=
///        [TypeName]? [SimpleIdentifier]
class FunctionTypeAliasImpl extends TypeAliasImpl implements FunctionTypeAlias {
  /// The name of the return type of the function type being defined, or `null`
  /// if no return type was given.
  TypeAnnotationImpl _returnType;

  /// The type parameters for the function type, or `null` if the function type
  /// does not have any type parameters.
  TypeParameterListImpl _typeParameters;

  /// The parameters associated with the function type.
  FormalParameterListImpl _parameters;

  /// Initialize a newly created function type alias. Either or both of the
  /// [comment] and [metadata] can be `null` if the function does not have the
  /// corresponding attribute. The [returnType] can be `null` if no return type
  /// was specified. The [typeParameters] can be `null` if the function has no
  /// type parameters.
  FunctionTypeAliasImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      Token keyword,
      TypeAnnotationImpl returnType,
      SimpleIdentifierImpl name,
      TypeParameterListImpl typeParameters,
      FormalParameterListImpl parameters,
      Token semicolon)
      : super(comment, metadata, keyword, name, semicolon) {
    _returnType = _becomeParentOf(returnType);
    _typeParameters = _becomeParentOf(typeParameters);
    _parameters = _becomeParentOf(parameters);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(typedefKeyword)
    ..add(_returnType)
    ..add(_name)
    ..add(_typeParameters)
    ..add(_parameters)
    ..add(semicolon);

  @override
  FunctionTypeAliasElement get declaredElement =>
      _name?.staticElement as FunctionTypeAliasElement;

  @override
  FormalParameterList get parameters => _parameters;

  @override
  set parameters(FormalParameterList parameters) {
    _parameters = _becomeParentOf(parameters as FormalParameterListImpl);
  }

  @override
  TypeAnnotation get returnType => _returnType;

  @override
  set returnType(TypeAnnotation type) {
    _returnType = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  TypeParameterList get typeParameters => _typeParameters;

  @override
  set typeParameters(TypeParameterList typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitFunctionTypeAlias(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _returnType?.accept(visitor);
    _name?.accept(visitor);
    _typeParameters?.accept(visitor);
    _parameters?.accept(visitor);
  }
}

/// A function-typed formal parameter.
///
///    functionSignature ::=
///        [TypeName]? [SimpleIdentifier] [TypeParameterList]?
///        [FormalParameterList] '?'?
class FunctionTypedFormalParameterImpl extends NormalFormalParameterImpl
    implements FunctionTypedFormalParameter {
  /// The return type of the function, or `null` if the function does not have a
  /// return type.
  TypeAnnotationImpl _returnType;

  /// The type parameters associated with the function, or `null` if the
  /// function is not a generic function.
  TypeParameterListImpl _typeParameters;

  /// The parameters of the function-typed parameter.
  FormalParameterListImpl _parameters;

  @override
  Token question;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute. The [returnType] can be `null` if no return type
  /// was specified.
  FunctionTypedFormalParameterImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      Token covariantKeyword,
      Token requiredKeyword,
      TypeAnnotationImpl returnType,
      SimpleIdentifierImpl identifier,
      TypeParameterListImpl typeParameters,
      FormalParameterListImpl parameters,
      this.question)
      : super(
            comment, metadata, covariantKeyword, requiredKeyword, identifier) {
    _returnType = _becomeParentOf(returnType);
    _typeParameters = _becomeParentOf(typeParameters);
    _parameters = _becomeParentOf(parameters);
  }

  @override
  Token get beginToken {
    NodeList<Annotation> metadata = this.metadata;
    if (metadata.isNotEmpty) {
      return metadata.beginToken;
    } else if (requiredKeyword != null) {
      return requiredKeyword;
    } else if (covariantKeyword != null) {
      return covariantKeyword;
    } else if (_returnType != null) {
      return _returnType.beginToken;
    }
    return identifier?.beginToken;
  }

  @override
  Iterable<SyntacticEntity> get childEntities =>
      super._childEntities..add(_returnType)..add(identifier)..add(parameters);

  @override
  Token get endToken => question ?? _parameters.endToken;

  @override
  bool get isConst => false;

  @override
  bool get isFinal => false;

  @override
  FormalParameterList get parameters => _parameters;

  @override
  set parameters(FormalParameterList parameters) {
    _parameters = _becomeParentOf(parameters as FormalParameterListImpl);
  }

  @override
  TypeAnnotation get returnType => _returnType;

  @override
  set returnType(TypeAnnotation type) {
    _returnType = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  TypeParameterList get typeParameters => _typeParameters;

  @override
  set typeParameters(TypeParameterList typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitFunctionTypedFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _returnType?.accept(visitor);
    identifier?.accept(visitor);
    _typeParameters?.accept(visitor);
    _parameters?.accept(visitor);
  }
}

/// An anonymous function type.
///
///    functionType ::=
///        [TypeAnnotation]? 'Function' [TypeParameterList]?
///        [FormalParameterList]
///
/// where the FormalParameterList is being used to represent the following
/// grammar, despite the fact that FormalParameterList can represent a much
/// larger grammar than the one below. This is done in order to simplify the
/// implementation.
///
///    parameterTypeList ::=
///        () |
///        ( normalParameterTypes ,? ) |
///        ( normalParameterTypes , optionalParameterTypes ) |
///        ( optionalParameterTypes )
///    namedParameterTypes ::=
///        { namedParameterType (, namedParameterType)* ,? }
///    namedParameterType ::=
///        [TypeAnnotation]? [SimpleIdentifier]
///    normalParameterTypes ::=
///        normalParameterType (, normalParameterType)*
///    normalParameterType ::=
///        [TypeAnnotation] [SimpleIdentifier]?
///    optionalParameterTypes ::=
///        optionalPositionalParameterTypes | namedParameterTypes
///    optionalPositionalParameterTypes ::=
///        [ normalParameterTypes ,? ]
class GenericFunctionTypeImpl extends TypeAnnotationImpl
    implements GenericFunctionType {
  /// The name of the return type of the function type being defined, or
  /// `null` if no return type was given.
  TypeAnnotationImpl _returnType;

  @override
  Token functionKeyword;

  /// The type parameters for the function type, or `null` if the function type
  /// does not have any type parameters.
  TypeParameterListImpl _typeParameters;

  /// The parameters associated with the function type.
  FormalParameterListImpl _parameters;

  @override
  Token question;

  @override
  DartType type;

  /// Return the element associated with the function type, or `null` if the
  /// AST structure has not been resolved.
  GenericFunctionTypeElement declaredElement;

  /// Initialize a newly created generic function type.
  GenericFunctionTypeImpl(TypeAnnotationImpl returnType, this.functionKeyword,
      TypeParameterListImpl typeParameters, FormalParameterListImpl parameters,
      {this.question}) {
    _returnType = _becomeParentOf(returnType);
    _typeParameters = _becomeParentOf(typeParameters);
    _parameters = _becomeParentOf(parameters);
  }

  @override
  Token get beginToken => _returnType?.beginToken ?? functionKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_returnType)
    ..add(functionKeyword)
    ..add(_typeParameters)
    ..add(_parameters)
    ..add(question);

  @override
  Token get endToken => question ?? _parameters.endToken;

  @override
  FormalParameterList get parameters => _parameters;

  @override
  set parameters(FormalParameterList parameters) {
    _parameters = _becomeParentOf(parameters as FormalParameterListImpl);
  }

  @override
  TypeAnnotation get returnType => _returnType;

  @override
  set returnType(TypeAnnotation type) {
    _returnType = _becomeParentOf(type as TypeAnnotationImpl);
  }

  /// Return the type parameters for the function type, or `null` if the
  /// function type does not have any type parameters.
  @override
  TypeParameterList get typeParameters => _typeParameters;

  /// Set the type parameters for the function type to the given list of
  /// [typeParameters].
  @override
  set typeParameters(TypeParameterList typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl);
  }

  // TODO: implement type
  @override
  E accept<E>(AstVisitor<E> visitor) {
    return visitor.visitGenericFunctionType(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _returnType?.accept(visitor);
    _typeParameters?.accept(visitor);
    _parameters?.accept(visitor);
  }
}

/// A generic type alias.
///
///    functionTypeAlias ::=
///        metadata 'typedef' [SimpleIdentifier] [TypeParameterList]? =
///        [FunctionType] ';'
class GenericTypeAliasImpl extends TypeAliasImpl implements GenericTypeAlias {
  /// The type parameters for the function type, or `null` if the function
  /// type does not have any type parameters.
  TypeParameterListImpl _typeParameters;

  @override
  Token equals;

  /// The type of function being defined by the alias.
  GenericFunctionTypeImpl _functionType;

  /// Returns a newly created generic type alias. Either or both of the
  /// [comment] and [metadata] can be `null` if the variable list does not have
  /// the corresponding attribute. The [typeParameters] can be `null` if there
  /// are no type parameters.
  GenericTypeAliasImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      Token typedefToken,
      SimpleIdentifierImpl name,
      TypeParameterListImpl typeParameters,
      this.equals,
      GenericFunctionTypeImpl functionType,
      Token semicolon)
      : super(comment, metadata, typedefToken, name, semicolon) {
    _typeParameters = _becomeParentOf(typeParameters);
    _functionType = _becomeParentOf(functionType);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..addAll(metadata)
    ..add(typedefKeyword)
    ..add(name)
    ..add(_typeParameters)
    ..add(equals)
    ..add(_functionType);

  @override
  Element get declaredElement => name.staticElement;

  @override
  GenericFunctionType get functionType => _functionType;

  @override
  set functionType(GenericFunctionType functionType) {
    _functionType = _becomeParentOf(functionType as GenericFunctionTypeImpl);
  }

  @override
  TypeParameterList get typeParameters => _typeParameters;

  @override
  set typeParameters(TypeParameterList typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) {
    return visitor.visitGenericTypeAlias(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    name?.accept(visitor);
    _typeParameters?.accept(visitor);
    _functionType?.accept(visitor);
  }
}

/// A combinator that restricts the names being imported to those that are not
/// in a given list.
///
///    hideCombinator ::=
///        'hide' [SimpleIdentifier] (',' [SimpleIdentifier])*
class HideCombinatorImpl extends CombinatorImpl implements HideCombinator {
  /// The list of names from the library that are hidden by this combinator.
  NodeList<SimpleIdentifier> _hiddenNames;

  /// Initialize a newly created import show combinator.
  HideCombinatorImpl(Token keyword, List<SimpleIdentifier> hiddenNames)
      : super(keyword) {
    _hiddenNames = NodeListImpl<SimpleIdentifier>(this, hiddenNames);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(keyword)
    ..addAll(_hiddenNames);

  @override
  Token get endToken => _hiddenNames.endToken;

  @override
  NodeList<SimpleIdentifier> get hiddenNames => _hiddenNames;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitHideCombinator(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _hiddenNames.accept(visitor);
  }
}

/// A node that represents an identifier.
///
///    identifier ::=
///        [SimpleIdentifier]
///      | [PrefixedIdentifier]
abstract class IdentifierImpl extends ExpressionImpl implements Identifier {
  @override
  bool get isAssignable => true;
}

class IfElementImpl extends CollectionElementImpl
    with IfMixin
    implements IfElement {
  /// The element to be executed if the condition is `true`.
  CollectionElementImpl _thenElement;

  /// The element to be executed if the condition is `false`, or `null` if there
  /// is no such element.
  CollectionElementImpl _elseElement;

  /// Initialize a newly created for element.
  IfElementImpl(
      Token ifKeyword,
      Token leftParenthesis,
      ExpressionImpl condition,
      Token rightParenthesis,
      CollectionElementImpl thenElement,
      Token elseKeyword,
      CollectionElementImpl elseElement) {
    this.ifKeyword = ifKeyword;
    this.leftParenthesis = leftParenthesis;
    _condition = _becomeParentOf(condition);
    this.rightParenthesis = rightParenthesis;
    _thenElement = _becomeParentOf(thenElement);
    this.elseKeyword = elseKeyword;
    _elseElement = _becomeParentOf(elseElement);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..addAll(super.childEntities)
    ..add(_thenElement)
    ..add(elseKeyword)
    ..add(_elseElement);

  @override
  CollectionElement get elseElement => _elseElement;

  set elseElement(CollectionElement element) {
    _elseElement = _becomeParentOf(element as CollectionElementImpl);
  }

  @override
  Token get endToken => _elseElement?.endToken ?? _thenElement.endToken;

  @override
  CollectionElement get thenElement => _thenElement;

  set thenElement(CollectionElement element) {
    _thenElement = _becomeParentOf(element as CollectionElementImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitIfElement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _thenElement?.accept(visitor);
    _elseElement?.accept(visitor);
  }
}

mixin IfMixin on AstNodeImpl {
  Token ifKeyword;

  Token leftParenthesis;

  /// The condition used to determine which of the branches is executed next.
  ExpressionImpl _condition;

  Token rightParenthesis;

  Token elseKeyword;

  @override
  Token get beginToken => ifKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(ifKeyword)
    ..add(leftParenthesis)
    ..add(_condition)
    ..add(rightParenthesis);

  Expression get condition => _condition;

  set condition(Expression expression) {
    _condition = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _condition?.accept(visitor);
  }
}

/// An if statement.
///
///    ifStatement ::=
///        'if' '(' [Expression] ')' [Statement] ('else' [Statement])?
class IfStatementImpl extends StatementImpl
    with IfMixin
    implements IfStatement {
  /// The statement that is executed if the condition evaluates to `true`.
  StatementImpl _thenStatement;

  /// The statement that is executed if the condition evaluates to `false`, or
  /// `null` if there is no else statement.
  StatementImpl _elseStatement;

  /// Initialize a newly created if statement. The [elseKeyword] and
  /// [elseStatement] can be `null` if there is no else clause.
  IfStatementImpl(
      Token ifKeyword,
      Token leftParenthesis,
      ExpressionImpl condition,
      Token rightParenthesis,
      StatementImpl thenStatement,
      Token elseKeyword,
      StatementImpl elseStatement) {
    this.ifKeyword = ifKeyword;
    this.leftParenthesis = leftParenthesis;
    _condition = _becomeParentOf(condition);
    this.rightParenthesis = rightParenthesis;
    _thenStatement = _becomeParentOf(thenStatement);
    this.elseKeyword = elseKeyword;
    _elseStatement = _becomeParentOf(elseStatement);
  }

  @override
  Token get beginToken => ifKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..addAll(super.childEntities)
    ..add(_thenStatement)
    ..add(elseKeyword)
    ..add(_elseStatement);

  @override
  Statement get elseStatement => _elseStatement;

  @override
  set elseStatement(Statement statement) {
    _elseStatement = _becomeParentOf(statement as StatementImpl);
  }

  @override
  Token get endToken {
    if (_elseStatement != null) {
      return _elseStatement.endToken;
    }
    return _thenStatement.endToken;
  }

  @override
  Statement get thenStatement => _thenStatement;

  @override
  set thenStatement(Statement statement) {
    _thenStatement = _becomeParentOf(statement as StatementImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitIfStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _condition?.accept(visitor);
    _thenStatement?.accept(visitor);
    _elseStatement?.accept(visitor);
  }
}

/// The "implements" clause in an class declaration.
///
///    implementsClause ::=
///        'implements' [TypeName] (',' [TypeName])*
class ImplementsClauseImpl extends AstNodeImpl implements ImplementsClause {
  /// The token representing the 'implements' keyword.
  @override
  Token implementsKeyword;

  /// The interfaces that are being implemented.
  NodeList<TypeName> _interfaces;

  /// Initialize a newly created implements clause.
  ImplementsClauseImpl(this.implementsKeyword, List<TypeName> interfaces) {
    _interfaces = NodeListImpl<TypeName>(this, interfaces);
  }

  @override
  Token get beginToken => implementsKeyword;

  @override
  // TODO(paulberry): add commas.
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(implementsKeyword)
    ..addAll(interfaces);

  @override
  Token get endToken => _interfaces.endToken;

  @override
  NodeList<TypeName> get interfaces => _interfaces;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitImplementsClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _interfaces.accept(visitor);
  }
}

/// An import directive.
///
///    importDirective ::=
///        [Annotation] 'import' [StringLiteral] ('as' identifier)?
//         [Combinator]* ';'
///      | [Annotation] 'import' [StringLiteral] 'deferred' 'as' identifier
//         [Combinator]* ';'
class ImportDirectiveImpl extends NamespaceDirectiveImpl
    implements ImportDirective {
  /// The token representing the 'deferred' keyword, or `null` if the imported
  /// is not deferred.
  @override
  Token deferredKeyword;

  /// The token representing the 'as' keyword, or `null` if the imported names
  /// are not prefixed.
  @override
  Token asKeyword;

  /// The prefix to be used with the imported names, or `null` if the imported
  /// names are not prefixed.
  SimpleIdentifierImpl _prefix;

  /// Initialize a newly created import directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the function does not have the
  /// corresponding attribute. The [deferredKeyword] can be `null` if the import
  /// is not deferred. The [asKeyword] and [prefix] can be `null` if the import
  /// does not specify a prefix. The list of [combinators] can be `null` if
  /// there are no combinators.
  ImportDirectiveImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      Token keyword,
      StringLiteralImpl libraryUri,
      List<Configuration> configurations,
      this.deferredKeyword,
      this.asKeyword,
      SimpleIdentifierImpl prefix,
      List<Combinator> combinators,
      Token semicolon)
      : super(comment, metadata, keyword, libraryUri, configurations,
            combinators, semicolon) {
    _prefix = _becomeParentOf(prefix);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(keyword)
    ..add(_uri)
    ..add(deferredKeyword)
    ..add(asKeyword)
    ..add(_prefix)
    ..addAll(combinators)
    ..add(semicolon);

  @override
  ImportElement get element => super.element as ImportElement;

  @override
  SimpleIdentifier get prefix => _prefix;

  @override
  set prefix(SimpleIdentifier identifier) {
    _prefix = _becomeParentOf(identifier as SimpleIdentifierImpl);
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
  E accept<E>(AstVisitor<E> visitor) => visitor.visitImportDirective(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    configurations.accept(visitor);
    _prefix?.accept(visitor);
    combinators.accept(visitor);
  }
}

/// An index expression.
///
///    indexExpression ::=
///        [Expression] '[' [Expression] ']'
class IndexExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl
    implements IndexExpression {
  @override
  Token period;

  /// The expression used to compute the object being indexed, or `null` if this
  /// index expression is part of a cascade expression.
  ExpressionImpl _target;

  @override
  Token question;

  @override
  Token leftBracket;

  /// The expression used to compute the index.
  ExpressionImpl _index;

  @override
  Token rightBracket;

  /// The element associated with the operator based on the static type of the
  /// target, or `null` if the AST structure has not been resolved or if the
  /// operator could not be resolved.
  @override
  MethodElement staticElement;

  /// If this expression is both in a getter and setter context, the
  /// [AuxiliaryElements] will be set to hold onto the static element from the
  /// getter context.
  @override
  AuxiliaryElements auxiliaryElements;

  /// Initialize a newly created index expression that is a child of a cascade
  /// expression.
  IndexExpressionImpl.forCascade(this.period, this.question, this.leftBracket,
      ExpressionImpl index, this.rightBracket) {
    _index = _becomeParentOf(index);
  }

  /// Initialize a newly created index expression that is not a child of a
  /// cascade expression.
  IndexExpressionImpl.forTarget(ExpressionImpl target, this.question,
      this.leftBracket, ExpressionImpl index, this.rightBracket) {
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

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_target)
    ..add(period)
    ..add(leftBracket)
    ..add(_index)
    ..add(rightBracket);

  @override
  Token get endToken => rightBracket;

  @override
  Expression get index => _index;

  @override
  set index(Expression expression) {
    _index = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  bool get isAssignable => true;

  @override
  bool get isCascaded => period != null;

  @override
  bool get isNullAware {
    if (isCascaded) {
      return _ancestorCascade.isNullAware;
    }
    return question != null ||
        (leftBracket.type == TokenType.OPEN_SQUARE_BRACKET &&
            period != null &&
            period.type == TokenType.QUESTION_PERIOD_PERIOD);
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  Expression get realTarget {
    if (isCascaded) {
      return _ancestorCascade.target;
    }
    return _target;
  }

  @override
  Expression get target => _target;

  @override
  set target(Expression expression) {
    _target = _becomeParentOf(expression as ExpressionImpl);
  }

  /// Return the cascade that contains this [IndexExpression].
  ///
  /// We expect that [isCascaded] is `true`.
  CascadeExpression get _ancestorCascade {
    assert(isCascaded);
    for (var ancestor = parent;; ancestor = ancestor.parent) {
      if (ancestor is CascadeExpression) {
        return ancestor;
      }
    }
  }

  @override
  AstNode get _nullShortingExtensionCandidate => parent;

  /// If the AST structure has been resolved, and the function being invoked is
  /// known based on static type information, then return the parameter element
  /// representing the parameter to which the value of the index expression will
  /// be bound. Otherwise, return `null`.
  ParameterElement get _staticParameterElementForIndex {
    if (staticElement == null) {
      return null;
    }
    List<ParameterElement> parameters = staticElement.parameters;
    if (parameters.isEmpty) {
      return null;
    }
    return parameters[0];
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitIndexExpression(this);

  @override
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

  @override
  bool inSetterContext() {
    // TODO(brianwilkerson) Convert this to a getter.
    AstNode parent = this.parent;
    if (parent is PrefixExpression) {
      return parent.operator.type.isIncrementOperator;
    } else if (parent is PostfixExpression) {
      return parent.operator.type.isIncrementOperator;
    } else if (parent is AssignmentExpression) {
      return identical(parent.leftHandSide, this);
    }
    return false;
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _target?.accept(visitor);
    _index?.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression child) => identical(child, _target);
}

/// An instance creation expression.
///
///    newExpression ::=
///        ('new' | 'const')? [TypeName] ('.' [SimpleIdentifier])?
///        [ArgumentList]
class InstanceCreationExpressionImpl extends ExpressionImpl
    implements InstanceCreationExpression {
  // TODO(brianwilkerson) Consider making InstanceCreationExpressionImpl extend
  // InvocationExpressionImpl. This would probably be a breaking change, but is
  // also probably worth it.

  /// The 'new' or 'const' keyword used to indicate how an object should be
  /// created, or `null` if the keyword is implicit.
  @override
  Token keyword;

  /// The name of the constructor to be invoked.
  ConstructorNameImpl _constructorName;

  /// The type arguments associated with the constructor, rather than with the
  /// class in which the constructor is defined. It is always an error if there
  /// are type arguments because Dart doesn't currently support generic
  /// constructors, but we capture them in the AST in order to recover better.
  TypeArgumentListImpl _typeArguments;

  /// The list of arguments to the constructor.
  ArgumentListImpl _argumentList;

  /// Initialize a newly created instance creation expression.
  InstanceCreationExpressionImpl(this.keyword,
      ConstructorNameImpl constructorName, ArgumentListImpl argumentList,
      {TypeArgumentListImpl typeArguments}) {
    _constructorName = _becomeParentOf(constructorName);
    _typeArguments = _becomeParentOf(typeArguments);
    _argumentList = _becomeParentOf(argumentList);
  }

  @override
  ArgumentList get argumentList => _argumentList;

  @override
  set argumentList(ArgumentList argumentList) {
    _argumentList = _becomeParentOf(argumentList as ArgumentListImpl);
  }

  @override
  Token get beginToken => keyword ?? _constructorName.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(keyword)
    ..add(_constructorName)
    ..add(_typeArguments)
    ..add(_argumentList);

  @override
  ConstructorName get constructorName => _constructorName;

  @override
  set constructorName(ConstructorName name) {
    _constructorName = _becomeParentOf(name as ConstructorNameImpl);
  }

  @override
  Token get endToken => _argumentList.endToken;

  @override
  bool get isConst {
    if (!isImplicit) {
      return keyword.keyword == Keyword.CONST;
    } else {
      return inConstantContext;
    }
  }

  /// Return `true` if this is an implicit constructor invocations.
  bool get isImplicit => keyword == null;

  @override
  Precedence get precedence => Precedence.primary;

  /// Return the type arguments associated with the constructor, rather than
  /// with the class in which the constructor is defined. It is always an error
  /// if there are type arguments because Dart doesn't currently support generic
  /// constructors, but we capture them in the AST in order to recover better.
  TypeArgumentList get typeArguments => _typeArguments;

  /// Return the type arguments associated with the constructor, rather than
  /// with the class in which the constructor is defined. It is always an error
  /// if there are type arguments because Dart doesn't currently support generic
  /// constructors, but we capture them in the AST in order to recover better.
  set typeArguments(TypeArgumentList typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments as TypeArgumentListImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitInstanceCreationExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _constructorName?.accept(visitor);
    _typeArguments?.accept(visitor);
    _argumentList?.accept(visitor);
  }
}

/// An integer literal expression.
///
///    integerLiteral ::=
///        decimalIntegerLiteral
///      | hexadecimalIntegerLiteral
///
///    decimalIntegerLiteral ::=
///        decimalDigit+
///
///    hexadecimalIntegerLiteral ::=
///        '0x' hexadecimalDigit+
///      | '0X' hexadecimalDigit+
class IntegerLiteralImpl extends LiteralImpl implements IntegerLiteral {
  /// The token representing the literal.
  @override
  Token literal;

  /// The value of the literal.
  @override
  int value = 0;

  /// Initialize a newly created integer literal.
  IntegerLiteralImpl(this.literal, this.value);

  @override
  Token get beginToken => literal;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()..add(literal);

  @override
  Token get endToken => literal;

  /// Returns whether this literal's [parent] is a [PrefixExpression] of unary
  /// negation.
  ///
  /// Note: this does *not* indicate that the value itself is negated, just that
  /// the literal is the child of a negation operation. The literal value itself
  /// will always be positive.
  bool get immediatelyNegated {
    AstNode parent = this.parent; // Capture for type propagation.
    return parent is PrefixExpression &&
        parent.operator.type == TokenType.MINUS;
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitIntegerLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }

  static bool isValidAsDouble(String lexeme) {
    // Less than 16 characters must be a valid double since it will be less than
    // 9007199254740992, 0x10000000000000, both 16 characters and 53 bits.
    if (lexeme.length < 16) {
      return true;
    }

    BigInt fullPrecision = BigInt.tryParse(lexeme);
    if (fullPrecision == null) {
      return false;
    }

    // Usually handled by the length check, however, we must check this before
    // constructing a mask later, or we'd get a negative-shift runtime error.
    int bitLengthAsInt = fullPrecision.bitLength;
    if (bitLengthAsInt <= 53) {
      return true;
    }

    // This would overflow the exponent (larger than maximum double).
    if (fullPrecision > BigInt.from(double.maxFinite)) {
      return false;
    }

    // Say [lexeme] uses 100 bits as an integer. The bottom 47 must be 0s -- so
    // construct a mask of 47 ones, via of 2^n - 1 where n is 47.
    BigInt bottomMask = (BigInt.one << (bitLengthAsInt - 53)) - BigInt.one;

    return fullPrecision & bottomMask == BigInt.zero;
  }

  /// Return `true` if the given [lexeme] is a valid lexeme for an integer
  /// literal. The flag [isNegative] should be `true` if the lexeme is preceded
  /// by a unary negation operator.
  static bool isValidAsInteger(String lexeme, bool isNegative) {
    // TODO(jmesserly): this depends on the platform int implementation, and
    // may not be accurate if run on dart4web.
    //
    // (Prior to https://dart-review.googlesource.com/c/sdk/+/63023 there was
    // a partial implementation here which may be a good starting point.
    // _isValidDecimalLiteral relied on int.parse so that would need some fixes.
    // _isValidHexadecimalLiteral worked except for negative int64 max.)
    if (isNegative) lexeme = '-$lexeme';
    return int.tryParse(lexeme) != null;
  }

  /// Suggest the nearest valid double to a user. If the integer they wrote
  /// requires more than a 53 bit mantissa, or more than 10 exponent bits, do
  /// them the favor of suggesting the nearest integer that would work for them.
  static double nearestValidDouble(String lexeme) =>
      math.min(double.maxFinite, BigInt.parse(lexeme).toDouble());
}

/// A node within a [StringInterpolation].
///
///    interpolationElement ::=
///        [InterpolationExpression]
///      | [InterpolationString]
abstract class InterpolationElementImpl extends AstNodeImpl
    implements InterpolationElement {}

/// An expression embedded in a string interpolation.
///
///    interpolationExpression ::=
///        '$' [SimpleIdentifier]
///      | '$' '{' [Expression] '}'
class InterpolationExpressionImpl extends InterpolationElementImpl
    implements InterpolationExpression {
  /// The token used to introduce the interpolation expression; either '$' if
  /// the expression is a simple identifier or '${' if the expression is a full
  /// expression.
  @override
  Token leftBracket;

  /// The expression to be evaluated for the value to be converted into a
  /// string.
  ExpressionImpl _expression;

  /// The right curly bracket, or `null` if the expression is an identifier
  /// without brackets.
  @override
  Token rightBracket;

  /// Initialize a newly created interpolation expression.
  InterpolationExpressionImpl(
      this.leftBracket, ExpressionImpl expression, this.rightBracket) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Token get beginToken => leftBracket;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(leftBracket)..add(_expression)..add(rightBracket);

  @override
  Token get endToken {
    if (rightBracket != null) {
      return rightBracket;
    }
    return _expression.endToken;
  }

  @override
  Expression get expression => _expression;

  @override
  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitInterpolationExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression?.accept(visitor);
  }
}

/// A non-empty substring of an interpolated string.
///
///    interpolationString ::=
///        characters
class InterpolationStringImpl extends InterpolationElementImpl
    implements InterpolationString {
  /// The characters that will be added to the string.
  @override
  Token contents;

  /// The value of the literal.
  @override
  String value;

  /// Initialize a newly created string of characters that are part of a string
  /// interpolation.
  InterpolationStringImpl(this.contents, this.value);

  @override
  Token get beginToken => contents;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()..add(contents);

  @override
  int get contentsEnd => offset + _lexemeHelper.end;

  @override
  int get contentsOffset => contents.offset + _lexemeHelper.start;

  @override
  Token get endToken => contents;

  @override
  StringInterpolation get parent => super.parent;

  StringLexemeHelper get _lexemeHelper {
    String lexeme = contents.lexeme;
    return StringLexemeHelper(lexeme, identical(this, parent.elements.first),
        identical(this, parent.elements.last));
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitInterpolationString(this);

  @override
  void visitChildren(AstVisitor visitor) {}
}

/// Common base class for [FunctionExpressionInvocationImpl] and
/// [MethodInvocationImpl].
abstract class InvocationExpressionImpl extends ExpressionImpl
    implements InvocationExpression {
  /// The list of arguments to the function.
  ArgumentListImpl _argumentList;

  /// The type arguments to be applied to the method being invoked, or `null` if
  /// no type arguments were provided.
  TypeArgumentListImpl _typeArguments;

  @override
  List<DartType> typeArgumentTypes;

  @override
  DartType staticInvokeType;

  /// Initialize a newly created invocation.
  InvocationExpressionImpl(
      TypeArgumentListImpl typeArguments, ArgumentListImpl argumentList) {
    _typeArguments = _becomeParentOf(typeArguments);
    _argumentList = _becomeParentOf(argumentList);
  }

  @override
  ArgumentList get argumentList => _argumentList;

  set argumentList(ArgumentList argumentList) {
    _argumentList = _becomeParentOf(argumentList as ArgumentListImpl);
  }

  @override
  TypeArgumentList get typeArguments => _typeArguments;

  set typeArguments(TypeArgumentList typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments as TypeArgumentListImpl);
  }
}

/// An is expression.
///
///    isExpression ::=
///        [Expression] 'is' '!'? [TypeName]
class IsExpressionImpl extends ExpressionImpl implements IsExpression {
  /// The expression used to compute the value whose type is being tested.
  ExpressionImpl _expression;

  /// The is operator.
  @override
  Token isOperator;

  /// The not operator, or `null` if the sense of the test is not negated.
  @override
  Token notOperator;

  /// The name of the type being tested for.
  TypeAnnotationImpl _type;

  /// Initialize a newly created is expression. The [notOperator] can be `null`
  /// if the sense of the test is not negated.
  IsExpressionImpl(ExpressionImpl expression, this.isOperator, this.notOperator,
      TypeAnnotationImpl type) {
    _expression = _becomeParentOf(expression);
    _type = _becomeParentOf(type);
  }

  @override
  Token get beginToken => _expression.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_expression)
    ..add(isOperator)
    ..add(notOperator)
    ..add(_type);

  @override
  Token get endToken => _type.endToken;

  @override
  Expression get expression => _expression;

  @override
  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Precedence get precedence => Precedence.relational;

  @override
  TypeAnnotation get type => _type;

  @override
  set type(TypeAnnotation type) {
    _type = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitIsExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression?.accept(visitor);
    _type?.accept(visitor);
  }
}

/// A statement that has a label associated with them.
///
///    labeledStatement ::=
///       [Label]+ [Statement]
class LabeledStatementImpl extends StatementImpl implements LabeledStatement {
  /// The labels being associated with the statement.
  NodeList<Label> _labels;

  /// The statement with which the labels are being associated.
  StatementImpl _statement;

  /// Initialize a newly created labeled statement.
  LabeledStatementImpl(List<Label> labels, StatementImpl statement) {
    _labels = NodeListImpl<Label>(this, labels);
    _statement = _becomeParentOf(statement);
  }

  @override
  Token get beginToken {
    if (_labels.isNotEmpty) {
      return _labels.beginToken;
    }
    return _statement.beginToken;
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..addAll(_labels)
    ..add(_statement);

  @override
  Token get endToken => _statement.endToken;

  @override
  NodeList<Label> get labels => _labels;

  @override
  Statement get statement => _statement;

  @override
  set statement(Statement statement) {
    _statement = _becomeParentOf(statement as StatementImpl);
  }

  @override
  Statement get unlabeled => _statement.unlabeled;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitLabeledStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _labels.accept(visitor);
    _statement?.accept(visitor);
  }
}

/// A label on either a [LabeledStatement] or a [NamedExpression].
///
///    label ::=
///        [SimpleIdentifier] ':'
class LabelImpl extends AstNodeImpl implements Label {
  /// The label being associated with the statement.
  SimpleIdentifierImpl _label;

  /// The colon that separates the label from the statement.
  @override
  Token colon;

  /// Initialize a newly created label.
  LabelImpl(SimpleIdentifierImpl label, this.colon) {
    _label = _becomeParentOf(label);
  }

  @override
  Token get beginToken => _label.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(_label)..add(colon);

  @override
  Token get endToken => colon;

  @override
  SimpleIdentifier get label => _label;

  @override
  set label(SimpleIdentifier label) {
    _label = _becomeParentOf(label as SimpleIdentifierImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitLabel(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _label?.accept(visitor);
  }
}

/// A library directive.
///
///    libraryDirective ::=
///        [Annotation] 'library' [Identifier] ';'
class LibraryDirectiveImpl extends DirectiveImpl implements LibraryDirective {
  /// The token representing the 'library' keyword.
  @override
  Token libraryKeyword;

  /// The name of the library being defined.
  LibraryIdentifierImpl _name;

  /// The semicolon terminating the directive.
  @override
  Token semicolon;

  /// Initialize a newly created library directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute.
  LibraryDirectiveImpl(CommentImpl comment, List<Annotation> metadata,
      this.libraryKeyword, LibraryIdentifierImpl name, this.semicolon)
      : super(comment, metadata) {
    _name = _becomeParentOf(name);
  }

  @override
  Iterable<SyntacticEntity> get childEntities =>
      super._childEntities..add(libraryKeyword)..add(_name)..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => libraryKeyword;

  @override
  Token get keyword => libraryKeyword;

  @override
  LibraryIdentifier get name => _name;

  @override
  set name(LibraryIdentifier name) {
    _name = _becomeParentOf(name as LibraryIdentifierImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitLibraryDirective(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _name?.accept(visitor);
  }
}

/// The identifier for a library.
///
///    libraryIdentifier ::=
///        [SimpleIdentifier] ('.' [SimpleIdentifier])*
class LibraryIdentifierImpl extends IdentifierImpl
    implements LibraryIdentifier {
  /// The components of the identifier.
  NodeList<SimpleIdentifier> _components;

  /// Initialize a newly created prefixed identifier.
  LibraryIdentifierImpl(List<SimpleIdentifier> components) {
    _components = NodeListImpl<SimpleIdentifier>(this, components);
  }

  @override
  Token get beginToken => _components.beginToken;

  @override
  // TODO(paulberry): add "." tokens.
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..addAll(_components);

  @override
  NodeList<SimpleIdentifier> get components => _components;

  @override
  Token get endToken => _components.endToken;

  @override
  String get name {
    StringBuffer buffer = StringBuffer();
    bool needsPeriod = false;
    int length = _components.length;
    for (int i = 0; i < length; i++) {
      SimpleIdentifier identifier = _components[i];
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
  Precedence get precedence => Precedence.postfix;

  @override
  Element get staticElement => null;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitLibraryIdentifier(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _components.accept(visitor);
  }
}

class ListLiteralImpl extends TypedLiteralImpl implements ListLiteral {
  /// The left square bracket.
  @override
  Token leftBracket;

  /// The expressions used to compute the elements of the list.
  NodeList<CollectionElement> _elements;

  /// The right square bracket.
  @override
  Token rightBracket;

  /// Initialize a newly created list literal. The [constKeyword] can be `null`
  /// if the literal is not a constant. The [typeArguments] can be `null` if no
  /// type arguments were declared. The list of [elements] can be `null` if the
  /// list is empty.
  ListLiteralImpl(Token constKeyword, TypeArgumentListImpl typeArguments,
      this.leftBracket, List<Expression> elements, this.rightBracket)
      : super(constKeyword, typeArguments) {
    _elements = NodeListImpl<Expression>(this, elements);
  }

  /// Initialize a newly created list literal.
  ///
  /// The [constKeyword] can be `null` if the literal is not a constant. The
  /// [typeArguments] can be `null` if no type arguments were declared. The list
  /// of [elements] can be `null` if the list is empty.
  ListLiteralImpl.experimental(
      Token constKeyword,
      TypeArgumentListImpl typeArguments,
      this.leftBracket,
      List<CollectionElement> elements,
      this.rightBracket)
      : super(constKeyword, typeArguments) {
    _elements = NodeListImpl<CollectionElement>(this, elements);
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
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(leftBracket)
    ..addAll(_elements)
    ..add(rightBracket);

  @override
  NodeList<CollectionElement> get elements => _elements;

  @override
  Token get endToken => rightBracket;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitListLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _elements.accept(visitor);
  }
}

/// A node that represents a literal expression.
///
///    literal ::=
///        [BooleanLiteral]
///      | [DoubleLiteral]
///      | [IntegerLiteral]
///      | [ListLiteral]
///      | [MapLiteral]
///      | [NullLiteral]
///      | [StringLiteral]
abstract class LiteralImpl extends ExpressionImpl implements Literal {
  @override
  Precedence get precedence => Precedence.primary;
}

/// Additional information about local variables within a function or method
/// produced at resolution time.
class LocalVariableInfo {
  /// The set of local variables and parameters that are potentially mutated
  /// within a local function other than the function in which they are
  /// declared.
  final Set<VariableElement> potentiallyMutatedInClosure = <VariableElement>{};

  /// The set of local variables and parameters that are potentially mutated
  /// within the scope of their declarations.
  final Set<VariableElement> potentiallyMutatedInScope = <VariableElement>{};
}

/// A single key/value pair in a map literal.
///
///    mapLiteralEntry ::=
///        [Expression] ':' [Expression]
class MapLiteralEntryImpl extends CollectionElementImpl
    implements MapLiteralEntry {
  /// The expression computing the key with which the value will be associated.
  ExpressionImpl _key;

  /// The colon that separates the key from the value.
  @override
  Token separator;

  /// The expression computing the value that will be associated with the key.
  ExpressionImpl _value;

  /// Initialize a newly created map literal entry.
  MapLiteralEntryImpl(
      ExpressionImpl key, this.separator, ExpressionImpl value) {
    _key = _becomeParentOf(key);
    _value = _becomeParentOf(value);
  }

  @override
  Token get beginToken => _key.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(_key)..add(separator)..add(_value);

  @override
  Token get endToken => _value.endToken;

  @override
  Expression get key => _key;

  @override
  set key(Expression string) {
    _key = _becomeParentOf(string as ExpressionImpl);
  }

  @override
  Expression get value => _value;

  @override
  set value(Expression expression) {
    _value = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitMapLiteralEntry(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _key?.accept(visitor);
    _value?.accept(visitor);
  }
}

/// A method declaration.
///
///    methodDeclaration ::=
///        methodSignature [FunctionBody]
///
///    methodSignature ::=
///        'external'? ('abstract' | 'static')? [Type]? ('get' | 'set')?
///        methodName [TypeParameterList] [FormalParameterList]
///
///    methodName ::=
///        [SimpleIdentifier]
///      | 'operator' [SimpleIdentifier]
class MethodDeclarationImpl extends ClassMemberImpl
    implements MethodDeclaration {
  /// The token for the 'external' keyword, or `null` if the constructor is not
  /// external.
  @override
  Token externalKeyword;

  /// The token representing the 'abstract' or 'static' keyword, or `null` if
  /// neither modifier was specified.
  @override
  Token modifierKeyword;

  /// The return type of the method, or `null` if no return type was declared.
  TypeAnnotationImpl _returnType;

  /// The token representing the 'get' or 'set' keyword, or `null` if this is a
  /// method declaration rather than a property declaration.
  @override
  Token propertyKeyword;

  /// The token representing the 'operator' keyword, or `null` if this method
  /// does not declare an operator.
  @override
  Token operatorKeyword;

  /// The name of the method.
  SimpleIdentifierImpl _name;

  /// The type parameters associated with the method, or `null` if the method is
  /// not a generic method.
  TypeParameterListImpl _typeParameters;

  /// The parameters associated with the method, or `null` if this method
  /// declares a getter.
  FormalParameterListImpl _parameters;

  /// The body of the method.
  FunctionBodyImpl _body;

  /// Initialize a newly created method declaration. Either or both of the
  /// [comment] and [metadata] can be `null` if the declaration does not have
  /// the corresponding attribute. The [externalKeyword] can be `null` if the
  /// method is not external. The [modifierKeyword] can be `null` if the method
  /// is neither abstract nor static. The [returnType] can be `null` if no
  /// return type was specified. The [propertyKeyword] can be `null` if the
  /// method is neither a getter or a setter. The [operatorKeyword] can be
  /// `null` if the method does not implement an operator. The [parameters] must
  /// be `null` if this method declares a getter.
  MethodDeclarationImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      this.externalKeyword,
      this.modifierKeyword,
      TypeAnnotationImpl returnType,
      this.propertyKeyword,
      this.operatorKeyword,
      SimpleIdentifierImpl name,
      TypeParameterListImpl typeParameters,
      FormalParameterListImpl parameters,
      FunctionBodyImpl body)
      : super(comment, metadata) {
    _returnType = _becomeParentOf(returnType);
    _name = _becomeParentOf(name);
    _typeParameters = _becomeParentOf(typeParameters);
    _parameters = _becomeParentOf(parameters);
    _body = _becomeParentOf(body);
  }

  @override
  FunctionBody get body => _body;

  @override
  set body(FunctionBody functionBody) {
    _body = _becomeParentOf(functionBody as FunctionBodyImpl);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(externalKeyword)
    ..add(modifierKeyword)
    ..add(_returnType)
    ..add(propertyKeyword)
    ..add(operatorKeyword)
    ..add(_name)
    ..add(_parameters)
    ..add(_body);

  /// Return the element associated with this method, or `null` if the AST
  /// structure has not been resolved. The element can either be a
  /// [MethodElement], if this represents the declaration of a normal method, or
  /// a [PropertyAccessorElement] if this represents the declaration of either a
  /// getter or a setter.
  @override
  ExecutableElement get declaredElement =>
      _name?.staticElement as ExecutableElement;

  @override
  Token get endToken => _body.endToken;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (externalKeyword != null) {
      return externalKeyword;
    } else if (modifierKeyword != null) {
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

  @override
  bool get isAbstract {
    FunctionBody body = _body;
    return externalKeyword == null &&
        (body is EmptyFunctionBody && !body.semicolon.isSynthetic);
  }

  @override
  bool get isGetter => propertyKeyword?.keyword == Keyword.GET;

  @override
  bool get isOperator => operatorKeyword != null;

  @override
  bool get isSetter => propertyKeyword?.keyword == Keyword.SET;

  @override
  bool get isStatic => modifierKeyword?.keyword == Keyword.STATIC;

  @override
  SimpleIdentifier get name => _name;

  @override
  set name(SimpleIdentifier identifier) {
    _name = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  FormalParameterList get parameters => _parameters;

  @override
  set parameters(FormalParameterList parameters) {
    _parameters = _becomeParentOf(parameters as FormalParameterListImpl);
  }

  @override
  TypeAnnotation get returnType => _returnType;

  @override
  set returnType(TypeAnnotation type) {
    _returnType = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  TypeParameterList get typeParameters => _typeParameters;

  @override
  set typeParameters(TypeParameterList typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitMethodDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _returnType?.accept(visitor);
    _name?.accept(visitor);
    _typeParameters?.accept(visitor);
    _parameters?.accept(visitor);
    _body?.accept(visitor);
  }
}

/// The invocation of either a function or a method. Invocations of functions
/// resulting from evaluating an expression are represented by
/// [FunctionExpressionInvocation] nodes. Invocations of getters and setters are
/// represented by either [PrefixedIdentifier] or [PropertyAccess] nodes.
///
///    methodInvocation ::=
///        ([Expression] '.')? [SimpleIdentifier] [TypeArgumentList]?
///        [ArgumentList]
class MethodInvocationImpl extends InvocationExpressionImpl
    with NullShortableExpressionImpl
    implements MethodInvocation {
  /// The expression producing the object on which the method is defined, or
  /// `null` if there is no target (that is, the target is implicitly `this`).
  ExpressionImpl _target;

  /// The operator that separates the target from the method name, or `null`
  /// if there is no target. In an ordinary method invocation this will be a
  /// period ('.'). In a cascade section this will be the cascade operator
  /// ('..' | '?..').
  @override
  Token operator;

  /// The name of the method being invoked.
  SimpleIdentifierImpl _methodName;

  /// The invoke type of the [methodName] if the target element is a getter,
  /// or `null` otherwise.
  DartType _methodNameType;

  /// Initialize a newly created method invocation. The [target] and [operator]
  /// can be `null` if there is no target.
  MethodInvocationImpl(
      ExpressionImpl target,
      this.operator,
      SimpleIdentifierImpl methodName,
      TypeArgumentListImpl typeArguments,
      ArgumentListImpl argumentList)
      : super(typeArguments, argumentList) {
    _target = _becomeParentOf(target);
    _methodName = _becomeParentOf(methodName);
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
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(_target)
    ..add(operator)
    ..add(_methodName)
    ..add(_argumentList);

  @override
  Token get endToken => _argumentList.endToken;

  @override
  Expression get function => methodName;

  @override
  bool get isCascaded =>
      operator != null &&
      (operator.type == TokenType.PERIOD_PERIOD ||
          operator.type == TokenType.QUESTION_PERIOD_PERIOD);

  @override
  bool get isNullAware {
    if (isCascaded) {
      return _ancestorCascade.isNullAware;
    }
    return operator != null &&
        (operator.type == TokenType.QUESTION_PERIOD ||
            operator.type == TokenType.QUESTION_PERIOD_PERIOD);
  }

  @override
  SimpleIdentifier get methodName => _methodName;

  @override
  set methodName(SimpleIdentifier identifier) {
    _methodName = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  /// The invoke type of the [methodName].
  ///
  /// If the target element is a [MethodElement], this is the same as the
  /// [staticInvokeType]. If the target element is a getter, presumably
  /// returning an [ExecutableElement] so that it can be invoked in this
  /// [MethodInvocation], then this type is the type of the getter, and the
  /// [staticInvokeType] is the invoked type of the returned element.
  DartType get methodNameType => _methodNameType ?? staticInvokeType;

  /// Set the [methodName] invoke type, only if the target element is a getter.
  /// Otherwise, the target element itself is invoked, [_methodNameType] is
  /// `null`, and the getter will return [staticInvokeType].
  set methodNameType(DartType methodNameType) {
    _methodNameType = methodNameType;
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  Expression get realTarget {
    if (isCascaded) {
      return _ancestorCascade.target;
    }
    return _target;
  }

  @override
  Expression get target => _target;

  @override
  set target(Expression expression) {
    _target = _becomeParentOf(expression as ExpressionImpl);
  }

  /// Return the cascade that contains this [IndexExpression].
  ///
  /// We expect that [isCascaded] is `true`.
  CascadeExpression get _ancestorCascade {
    assert(isCascaded);
    for (var ancestor = parent;; ancestor = ancestor.parent) {
      if (ancestor is CascadeExpression) {
        return ancestor;
      }
    }
  }

  @override
  AstNode get _nullShortingExtensionCandidate => parent;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitMethodInvocation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _target?.accept(visitor);
    _methodName?.accept(visitor);
    _typeArguments?.accept(visitor);
    _argumentList?.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression child) => identical(child, _target);
}

/// The declaration of a mixin.
///
///    mixinDeclaration ::=
///        metadata? 'mixin' [SimpleIdentifier] [TypeParameterList]?
///        [RequiresClause]? [ImplementsClause]? '{' [ClassMember]* '}'
class MixinDeclarationImpl extends ClassOrMixinDeclarationImpl
    implements MixinDeclaration {
  @override
  Token mixinKeyword;

  /// The on clause for the mixin, or `null` if the mixin does not have any
  /// super-class constraints.
  OnClauseImpl _onClause;

  /// Initialize a newly created mixin declaration. Either or both of the
  /// [comment] and [metadata] can be `null` if the mixin does not have the
  /// corresponding attribute. The [typeParameters] can be `null` if the mixin
  /// does not have any type parameters. Either or both of the [onClause],
  /// and [implementsClause] can be `null` if the mixin does not have the
  /// corresponding clause. The list of [members] can be `null` if the mixin
  /// does not have any members.
  MixinDeclarationImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      this.mixinKeyword,
      SimpleIdentifierImpl name,
      TypeParameterListImpl typeParameters,
      OnClauseImpl onClause,
      ImplementsClauseImpl implementsClause,
      Token leftBracket,
      List<ClassMember> members,
      Token rightBracket)
      : super(comment, metadata, name, typeParameters, implementsClause,
            leftBracket, members, rightBracket) {
    _onClause = _becomeParentOf(onClause);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(mixinKeyword)
    ..add(_name)
    ..add(_typeParameters)
    ..add(_onClause)
    ..add(_implementsClause)
    ..add(leftBracket)
    ..addAll(members)
    ..add(rightBracket);

  @override
  ClassElement get declaredElement => _name?.staticElement as ClassElement;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return mixinKeyword;
  }

  @override
  ImplementsClause get implementsClause => _implementsClause;

  @override
  set implementsClause(ImplementsClause implementsClause) {
    _implementsClause =
        _becomeParentOf(implementsClause as ImplementsClauseImpl);
  }

  @override
  NodeList<ClassMember> get members => _members;

  @override
  OnClause get onClause => _onClause;

  set onClause(OnClause onClause) {
    _onClause = _becomeParentOf(onClause as OnClauseImpl);
  }

  @override
  @override
  TypeParameterList get typeParameters => _typeParameters;

  @override
  set typeParameters(TypeParameterList typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitMixinDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _name?.accept(visitor);
    _typeParameters?.accept(visitor);
    _onClause?.accept(visitor);
    _implementsClause?.accept(visitor);
    members.accept(visitor);
  }
}

/// A node that declares a single name within the scope of a compilation unit.
abstract class NamedCompilationUnitMemberImpl extends CompilationUnitMemberImpl
    implements NamedCompilationUnitMember {
  /// The name of the member being declared.
  SimpleIdentifierImpl _name;

  /// Initialize a newly created compilation unit member with the given [name].
  /// Either or both of the [comment] and [metadata] can be `null` if the member
  /// does not have the corresponding attribute.
  NamedCompilationUnitMemberImpl(
      CommentImpl comment, List<Annotation> metadata, SimpleIdentifierImpl name)
      : super(comment, metadata) {
    _name = _becomeParentOf(name);
  }

  @override
  SimpleIdentifier get name => _name;

  @override
  set name(SimpleIdentifier identifier) {
    _name = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }
}

/// An expression that has a name associated with it. They are used in method
/// invocations when there are named parameters.
///
///    namedExpression ::=
///        [Label] [Expression]
class NamedExpressionImpl extends ExpressionImpl implements NamedExpression {
  /// The name associated with the expression.
  LabelImpl _name;

  /// The expression with which the name is associated.
  ExpressionImpl _expression;

  /// Initialize a newly created named expression..
  NamedExpressionImpl(LabelImpl name, ExpressionImpl expression) {
    _name = _becomeParentOf(name);
    _expression = _becomeParentOf(expression);
  }

  @override
  Token get beginToken => _name.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(_name)..add(_expression);

  @override
  ParameterElement get element {
    Element element = _name.label.staticElement;
    if (element is ParameterElement) {
      return element;
    }
    return null;
  }

  @override
  Token get endToken => _expression.endToken;

  @override
  Expression get expression => _expression;

  @override
  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Label get name => _name;

  @override
  set name(Label identifier) {
    _name = _becomeParentOf(identifier as LabelImpl);
  }

  @override
  Precedence get precedence => Precedence.none;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitNamedExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _name?.accept(visitor);
    _expression?.accept(visitor);
  }
}

/// A node that represents a directive that impacts the namespace of a library.
///
///    directive ::=
///        [ExportDirective]
///      | [ImportDirective]
abstract class NamespaceDirectiveImpl extends UriBasedDirectiveImpl
    implements NamespaceDirective {
  /// The token representing the 'import' or 'export' keyword.
  @override
  Token keyword;

  /// The configurations used to control which library will actually be loaded
  /// at run-time.
  NodeList<Configuration> _configurations;

  /// The combinators used to control which names are imported or exported.
  NodeList<Combinator> _combinators;

  /// The semicolon terminating the directive.
  @override
  Token semicolon;

  @override
  String selectedUriContent;

  @override
  Source selectedSource;

  /// Initialize a newly created namespace directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute. The list of [combinators] can be `null` if there
  /// are no combinators.
  NamespaceDirectiveImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      this.keyword,
      StringLiteralImpl libraryUri,
      List<Configuration> configurations,
      List<Combinator> combinators,
      this.semicolon)
      : super(comment, metadata, libraryUri) {
    _configurations = NodeListImpl<Configuration>(this, configurations);
    _combinators = NodeListImpl<Combinator>(this, combinators);
  }

  @override
  NodeList<Combinator> get combinators => _combinators;

  @override
  NodeList<Configuration> get configurations => _configurations;

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => keyword;

  @override
  LibraryElement get uriElement;
}

/// The "native" clause in an class declaration.
///
///    nativeClause ::=
///        'native' [StringLiteral]
class NativeClauseImpl extends AstNodeImpl implements NativeClause {
  /// The token representing the 'native' keyword.
  @override
  Token nativeKeyword;

  /// The name of the native object that implements the class.
  StringLiteralImpl _name;

  /// Initialize a newly created native clause.
  NativeClauseImpl(this.nativeKeyword, StringLiteralImpl name) {
    _name = _becomeParentOf(name);
  }

  @override
  Token get beginToken => nativeKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(nativeKeyword)..add(_name);

  @override
  Token get endToken => _name.endToken;

  @override
  StringLiteral get name => _name;

  @override
  set name(StringLiteral name) {
    _name = _becomeParentOf(name as StringLiteralImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitNativeClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _name?.accept(visitor);
  }
}

/// A function body that consists of a native keyword followed by a string
/// literal.
///
///    nativeFunctionBody ::=
///        'native' [SimpleStringLiteral] ';'
class NativeFunctionBodyImpl extends FunctionBodyImpl
    implements NativeFunctionBody {
  /// The token representing 'native' that marks the start of the function body.
  @override
  Token nativeKeyword;

  /// The string literal, after the 'native' token.
  StringLiteralImpl _stringLiteral;

  /// The token representing the semicolon that marks the end of the function
  /// body.
  @override
  Token semicolon;

  /// Initialize a newly created function body consisting of the 'native' token,
  /// a string literal, and a semicolon.
  NativeFunctionBodyImpl(
      this.nativeKeyword, StringLiteralImpl stringLiteral, this.semicolon) {
    _stringLiteral = _becomeParentOf(stringLiteral);
  }

  @override
  Token get beginToken => nativeKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(nativeKeyword)..add(_stringLiteral)..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  StringLiteral get stringLiteral => _stringLiteral;

  @override
  set stringLiteral(StringLiteral stringLiteral) {
    _stringLiteral = _becomeParentOf(stringLiteral as StringLiteralImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitNativeFunctionBody(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _stringLiteral?.accept(visitor);
  }
}

/// A list of AST nodes that have a common parent.
class NodeListImpl<E extends AstNode> with ListMixin<E> implements NodeList<E> {
  /// The node that is the parent of each of the elements in the list.
  final AstNodeImpl _owner;

  /// The elements contained in the list.
  List<E> _elements = <E>[];

  /// Initialize a newly created list of nodes such that all of the nodes that
  /// are added to the list will have their parent set to the given [owner]. The
  /// list will initially be populated with the given [elements].
  NodeListImpl(this._owner, [List<E> elements]) {
    addAll(elements);
  }

  @override
  Token get beginToken {
    if (_elements.isEmpty) {
      return null;
    }
    return _elements[0].beginToken;
  }

  @override
  Token get endToken {
    int length = _elements.length;
    if (length == 0) {
      return null;
    }
    return _elements[length - 1].endToken;
  }

  @override
  int get length => _elements.length;

  @override
  set length(int newLength) {
    throw UnsupportedError("Cannot resize NodeList.");
  }

  @override
  AstNode get owner => _owner;

  @override
  E operator [](int index) {
    if (index < 0 || index >= _elements.length) {
      throw RangeError("Index: $index, Size: ${_elements.length}");
    }
    return _elements[index];
  }

  @override
  void operator []=(int index, E node) {
    if (index < 0 || index >= _elements.length) {
      throw RangeError("Index: $index, Size: ${_elements.length}");
    }
    _owner._becomeParentOf(node as AstNodeImpl);
    _elements[index] = node;
  }

  @override
  void accept(AstVisitor visitor) {
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
    if (nodes != null && nodes.isNotEmpty) {
      if (nodes is List<E>) {
        int length = nodes.length;
        for (int i = 0; i < length; i++) {
          E node = nodes[i];
          _elements.add(node);
          _owner._becomeParentOf(node as AstNodeImpl);
        }
      } else {
        for (E node in nodes) {
          _elements.add(node);
          _owner._becomeParentOf(node as AstNodeImpl);
        }
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
      throw RangeError("Index: $index, Size: ${_elements.length}");
    }
    _owner._becomeParentOf(node as AstNodeImpl);
    if (length == 0) {
      _elements.add(node);
    } else {
      _elements.insert(index, node);
    }
  }

  @override
  E removeAt(int index) {
    if (index < 0 || index >= _elements.length) {
      throw RangeError("Index: $index, Size: ${_elements.length}");
    }
    E removedNode = _elements[index];
    _elements.removeAt(index);
    return removedNode;
  }

  /// This is non-API and may be changed or removed at any point.
  ///
  /// Changes the length of this list
  /// If [newLength] is greater than the current length,
  /// entries are initialized to `null`.
  ///
  /// This list should NOT contain any `null` elements,
  /// so be sure to immediately follow a call to this method with calls
  /// to replace all the `null` elements with non-`null` elements.
  void setLength(int newLength) {
    _elements.length = newLength;
  }
}

/// A formal parameter that is required (is not optional).
///
///    normalFormalParameter ::=
///        [FunctionTypedFormalParameter]
///      | [FieldFormalParameter]
///      | [SimpleFormalParameter]
abstract class NormalFormalParameterImpl extends FormalParameterImpl
    implements NormalFormalParameter {
  /// The documentation comment associated with this parameter, or `null` if
  /// this parameter does not have a documentation comment associated with it.
  CommentImpl _comment;

  /// The annotations associated with this parameter.
  NodeList<Annotation> _metadata;

  /// The 'covariant' keyword, or `null` if the keyword was not used.
  @override
  Token covariantKeyword;

  /// The 'required' keyword, or `null` if the keyword was not used.
  @override
  Token requiredKeyword;

  /// The name of the parameter being declared.
  SimpleIdentifierImpl _identifier;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute.
  NormalFormalParameterImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      this.covariantKeyword,
      this.requiredKeyword,
      SimpleIdentifierImpl identifier) {
    _comment = _becomeParentOf(comment);
    _metadata = NodeListImpl<Annotation>(this, metadata);
    _identifier = _becomeParentOf(identifier);
  }

  @override
  Comment get documentationComment => _comment;

  @override
  set documentationComment(Comment comment) {
    _comment = _becomeParentOf(comment as CommentImpl);
  }

  @override
  SimpleIdentifier get identifier => _identifier;

  @override
  set identifier(SimpleIdentifier identifier) {
    _identifier = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  ParameterKind get kind {
    AstNode parent = this.parent;
    if (parent is DefaultFormalParameterImpl) {
      return parent.kind;
    }
    return ParameterKind.REQUIRED;
  }

  @override
  NodeList<Annotation> get metadata => _metadata;

  @override
  set metadata(List<Annotation> metadata) {
    _metadata.clear();
    _metadata.addAll(metadata);
  }

  @override
  List<AstNode> get sortedCommentAndAnnotations {
    return <AstNode>[]
      ..add(_comment)
      ..addAll(_metadata)
      ..sort(AstNode.LEXICAL_ORDER);
  }

  ChildEntities get _childEntities {
    ChildEntities result = ChildEntities();
    if (_commentIsBeforeAnnotations()) {
      result
        ..add(_comment)
        ..addAll(_metadata);
    } else {
      result.addAll(sortedCommentAndAnnotations);
    }
    result..add(requiredKeyword)..add(covariantKeyword);
    return result;
  }

  @override
  void visitChildren(AstVisitor visitor) {
    //
    // Note that subclasses are responsible for visiting the identifier because
    // they often need to visit other nodes before visiting the identifier.
    //
    if (_commentIsBeforeAnnotations()) {
      _comment?.accept(visitor);
      _metadata.accept(visitor);
    } else {
      List<AstNode> children = sortedCommentAndAnnotations;
      int length = children.length;
      for (int i = 0; i < length; i++) {
        children[i].accept(visitor);
      }
    }
  }

  /// Return `true` if the comment is lexically before any annotations.
  bool _commentIsBeforeAnnotations() {
    if (_comment == null || _metadata.isEmpty) {
      return true;
    }
    Annotation firstAnnotation = _metadata[0];
    return _comment.offset < firstAnnotation.offset;
  }
}

/// A null literal expression.
///
///    nullLiteral ::=
///        'null'
class NullLiteralImpl extends LiteralImpl implements NullLiteral {
  /// The token representing the literal.
  @override
  Token literal;

  /// Initialize a newly created null literal.
  NullLiteralImpl(this.literal);

  @override
  Token get beginToken => literal;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()..add(literal);

  @override
  Token get endToken => literal;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitNullLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// Mixin that can be used to implement [NullShortableExpression].
mixin NullShortableExpressionImpl implements NullShortableExpression {
  @override
  Expression get nullShortingTermination {
    var result = this;
    while (true) {
      var parent = result._nullShortingExtensionCandidate;
      if (parent is NullShortableExpressionImpl &&
          parent._extendsNullShorting(result)) {
        result = parent;
      } else {
        return result;
      }
    }
  }

  /// Gets the ancestor of this node to which null-shorting might be extended.
  /// Usually this is just the node's parent, however if `this` is the base of
  /// a cascade section, it will be the cascade expression itself, which may be
  /// a more distant ancestor.
  AstNode get _nullShortingExtensionCandidate;

  /// Indicates whether the effect of any null-shorting within [descendant]
  /// (which should be a descendant of `this`) should extend to include `this`.
  bool _extendsNullShorting(Expression descendant);
}

/// The "on" clause in a mixin declaration.
///
///    onClause ::=
///        'on' [TypeName] (',' [TypeName])*
class OnClauseImpl extends AstNodeImpl implements OnClause {
  @override
  Token onKeyword;

  /// The classes are super-class constraints for the mixin.
  NodeList<TypeName> _superclassConstraints;

  /// Initialize a newly created on clause.
  OnClauseImpl(this.onKeyword, List<TypeName> superclassConstraints) {
    _superclassConstraints =
        NodeListImpl<TypeName>(this, superclassConstraints);
  }

  @override
  Token get beginToken => onKeyword;

  @override
  // TODO(paulberry): add commas.
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(onKeyword)
    ..addAll(superclassConstraints);

  @override
  Token get endToken => _superclassConstraints.endToken;

  @override
  NodeList<TypeName> get superclassConstraints => _superclassConstraints;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitOnClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _superclassConstraints.accept(visitor);
  }
}

/// A parenthesized expression.
///
///    parenthesizedExpression ::=
///        '(' [Expression] ')'
class ParenthesizedExpressionImpl extends ExpressionImpl
    implements ParenthesizedExpression {
  /// The left parenthesis.
  @override
  Token leftParenthesis;

  /// The expression within the parentheses.
  ExpressionImpl _expression;

  /// The right parenthesis.
  @override
  Token rightParenthesis;

  /// Initialize a newly created parenthesized expression.
  ParenthesizedExpressionImpl(
      this.leftParenthesis, ExpressionImpl expression, this.rightParenthesis) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Token get beginToken => leftParenthesis;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(leftParenthesis)
    ..add(_expression)
    ..add(rightParenthesis);

  @override
  Token get endToken => rightParenthesis;

  @override
  Expression get expression => _expression;

  @override
  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Precedence get precedence => Precedence.primary;

  @override
  Expression get unParenthesized {
    // This is somewhat inefficient, but it avoids a stack overflow in the
    // degenerate case.
    Expression expression = _expression;
    while (expression is ParenthesizedExpressionImpl) {
      expression = (expression as ParenthesizedExpressionImpl)._expression;
    }
    return expression;
  }

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitParenthesizedExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression?.accept(visitor);
  }
}

/// A part directive.
///
///    partDirective ::=
///        [Annotation] 'part' [StringLiteral] ';'
class PartDirectiveImpl extends UriBasedDirectiveImpl implements PartDirective {
  /// The token representing the 'part' keyword.
  @override
  Token partKeyword;

  /// The semicolon terminating the directive.
  @override
  Token semicolon;

  /// Initialize a newly created part directive. Either or both of the [comment]
  /// and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute.
  PartDirectiveImpl(CommentImpl comment, List<Annotation> metadata,
      this.partKeyword, StringLiteralImpl partUri, this.semicolon)
      : super(comment, metadata, partUri);

  @override
  Iterable<SyntacticEntity> get childEntities =>
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
  E accept<E>(AstVisitor<E> visitor) => visitor.visitPartDirective(this);
}

/// A part-of directive.
///
///    partOfDirective ::=
///        [Annotation] 'part' 'of' [Identifier] ';'
class PartOfDirectiveImpl extends DirectiveImpl implements PartOfDirective {
  /// The token representing the 'part' keyword.
  @override
  Token partKeyword;

  /// The token representing the 'of' keyword.
  @override
  Token ofKeyword;

  /// The URI of the library that the containing compilation unit is part of.
  StringLiteralImpl _uri;

  /// The name of the library that the containing compilation unit is part of,
  /// or `null` if no name was given (typically because a library URI was
  /// provided).
  LibraryIdentifierImpl _libraryName;

  /// The semicolon terminating the directive.
  @override
  Token semicolon;

  /// Initialize a newly created part-of directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute.
  PartOfDirectiveImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      this.partKeyword,
      this.ofKeyword,
      StringLiteralImpl uri,
      LibraryIdentifierImpl libraryName,
      this.semicolon)
      : super(comment, metadata) {
    _uri = _becomeParentOf(uri);
    _libraryName = _becomeParentOf(libraryName);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(partKeyword)
    ..add(ofKeyword)
    ..add(_uri)
    ..add(_libraryName)
    ..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => partKeyword;

  @override
  Token get keyword => partKeyword;

  @override
  LibraryIdentifier get libraryName => _libraryName;

  @override
  set libraryName(LibraryIdentifier libraryName) {
    _libraryName = _becomeParentOf(libraryName as LibraryIdentifierImpl);
  }

  @override
  StringLiteral get uri => _uri;

  @override
  set uri(StringLiteral uri) {
    _uri = _becomeParentOf(uri as StringLiteralImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitPartOfDirective(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _libraryName?.accept(visitor);
    _uri?.accept(visitor);
  }
}

/// A postfix unary expression.
///
///    postfixExpression ::=
///        [Expression] [Token]
class PostfixExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl, CompoundAssignmentExpressionImpl
    implements PostfixExpression {
  /// The expression computing the operand for the operator.
  ExpressionImpl _operand;

  /// The postfix operator being applied to the operand.
  @override
  Token operator;

  /// The element associated with the operator based on the static type of the
  /// operand, or `null` if the AST structure has not been resolved, if the
  /// operator is not user definable, or if the operator could not be resolved.
  @override
  MethodElement staticElement;

  /// Initialize a newly created postfix expression.
  PostfixExpressionImpl(ExpressionImpl operand, this.operator) {
    _operand = _becomeParentOf(operand);
  }

  @override
  Token get beginToken => _operand.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(_operand)..add(operator);

  @override
  Token get endToken => operator;

  @override
  Expression get operand => _operand;

  @override
  set operand(Expression expression) {
    _operand = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  AstNode get _nullShortingExtensionCandidate => parent;

  /// If the AST structure has been resolved, and the function being invoked is
  /// known based on static type information, then return the parameter element
  /// representing the parameter to which the value of the operand will be
  /// bound.  Otherwise, return `null`.
  ParameterElement get _staticParameterElementForOperand {
    if (staticElement == null) {
      return null;
    }
    List<ParameterElement> parameters = staticElement.parameters;
    if (parameters.isEmpty) {
      return null;
    }
    return parameters[0];
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitPostfixExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _operand?.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression child) =>
      operator.type != TokenType.BANG && identical(child, operand);
}

/// An identifier that is prefixed or an access to an object property where the
/// target of the property access is a simple identifier.
///
///    prefixedIdentifier ::=
///        [SimpleIdentifier] '.' [SimpleIdentifier]
class PrefixedIdentifierImpl extends IdentifierImpl
    implements PrefixedIdentifier {
  /// The prefix associated with the library in which the identifier is defined.
  SimpleIdentifierImpl _prefix;

  /// The period used to separate the prefix from the identifier.
  @override
  Token period;

  /// The identifier being prefixed.
  SimpleIdentifierImpl _identifier;

  /// Initialize a newly created prefixed identifier.
  PrefixedIdentifierImpl(SimpleIdentifierImpl prefix, this.period,
      SimpleIdentifierImpl identifier) {
    _prefix = _becomeParentOf(prefix);
    _identifier = _becomeParentOf(identifier);
  }

  /// Initialize a newly created prefixed identifier that does not take
  /// ownership of the components. The resulting node is only for temporary use,
  /// such as by resolution.
  PrefixedIdentifierImpl.temp(this._prefix, this._identifier) : period = null;

  @override
  Token get beginToken => _prefix.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(_prefix)..add(period)..add(_identifier);

  @override
  Token get endToken => _identifier.endToken;

  @override
  SimpleIdentifier get identifier => _identifier;

  @override
  set identifier(SimpleIdentifier identifier) {
    _identifier = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  bool get isDeferred {
    Element element = _prefix.staticElement;
    if (element is PrefixElement) {
      List<ImportElement> imports =
          element.enclosingElement.getImportsWithPrefix(element);
      if (imports.length != 1) {
        return false;
      }
      return imports[0].isDeferred;
    }
    return false;
  }

  @override
  String get name => "${_prefix.name}.${_identifier.name}";

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  SimpleIdentifier get prefix => _prefix;

  @override
  set prefix(SimpleIdentifier identifier) {
    _prefix = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  Element get staticElement {
    if (_identifier == null) {
      return null;
    }
    return _identifier.staticElement;
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitPrefixedIdentifier(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _prefix?.accept(visitor);
    _identifier?.accept(visitor);
  }
}

/// A prefix unary expression.
///
///    prefixExpression ::=
///        [Token] [Expression]
class PrefixExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl, CompoundAssignmentExpressionImpl
    implements PrefixExpression {
  /// The prefix operator being applied to the operand.
  @override
  Token operator;

  /// The expression computing the operand for the operator.
  ExpressionImpl _operand;

  /// The element associated with the operator based on the static type of the
  /// operand, or `null` if the AST structure has not been resolved, if the
  /// operator is not user definable, or if the operator could not be resolved.
  @override
  MethodElement staticElement;

  /// Initialize a newly created prefix expression.
  PrefixExpressionImpl(this.operator, ExpressionImpl operand) {
    _operand = _becomeParentOf(operand);
  }

  @override
  Token get beginToken => operator;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(operator)..add(_operand);

  @override
  Token get endToken => _operand.endToken;

  @override
  Expression get operand => _operand;

  @override
  set operand(Expression expression) {
    _operand = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Precedence get precedence => Precedence.prefix;

  @override
  AstNode get _nullShortingExtensionCandidate => parent;

  /// If the AST structure has been resolved, and the function being invoked is
  /// known based on static type information, then return the parameter element
  /// representing the parameter to which the value of the operand will be
  /// bound.  Otherwise, return `null`.
  ParameterElement get _staticParameterElementForOperand {
    if (staticElement == null) {
      return null;
    }
    List<ParameterElement> parameters = staticElement.parameters;
    if (parameters.isEmpty) {
      return null;
    }
    return parameters[0];
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitPrefixExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _operand?.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression child) =>
      identical(child, operand) && operator.type.isIncrementOperator;
}

/// The access of a property of an object.
///
/// Note, however, that accesses to properties of objects can also be
/// represented as [PrefixedIdentifier] nodes in cases where the target is also
/// a simple identifier.
///
///    propertyAccess ::=
///        [Expression] '.' [SimpleIdentifier]
class PropertyAccessImpl extends ExpressionImpl
    with NullShortableExpressionImpl
    implements PropertyAccess {
  /// The expression computing the object defining the property being accessed.
  ExpressionImpl _target;

  /// The property access operator.
  @override
  Token operator;

  /// The name of the property being accessed.
  SimpleIdentifierImpl _propertyName;

  /// Initialize a newly created property access expression.
  PropertyAccessImpl(
      ExpressionImpl target, this.operator, SimpleIdentifierImpl propertyName) {
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
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(_target)..add(operator)..add(_propertyName);

  @override
  Token get endToken => _propertyName.endToken;

  @override
  bool get isAssignable => true;

  @override
  bool get isCascaded =>
      operator != null &&
      (operator.type == TokenType.PERIOD_PERIOD ||
          operator.type == TokenType.QUESTION_PERIOD_PERIOD);

  @override
  bool get isNullAware {
    if (isCascaded) {
      return _ancestorCascade.isNullAware;
    }
    return operator != null &&
        (operator.type == TokenType.QUESTION_PERIOD ||
            operator.type == TokenType.QUESTION_PERIOD_PERIOD);
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  SimpleIdentifier get propertyName => _propertyName;

  @override
  set propertyName(SimpleIdentifier identifier) {
    _propertyName = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  Expression get realTarget {
    if (isCascaded) {
      return _ancestorCascade.target;
    }
    return _target;
  }

  @override
  Expression get target => _target;

  @override
  set target(Expression expression) {
    _target = _becomeParentOf(expression as ExpressionImpl);
  }

  /// Return the cascade that contains this [IndexExpression].
  ///
  /// We expect that [isCascaded] is `true`.
  CascadeExpression get _ancestorCascade {
    assert(isCascaded);
    for (var ancestor = parent;; ancestor = ancestor.parent) {
      if (ancestor is CascadeExpression) {
        return ancestor;
      }
    }
  }

  @override
  AstNode get _nullShortingExtensionCandidate => parent;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitPropertyAccess(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _target?.accept(visitor);
    _propertyName?.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression child) => identical(child, _target);
}

/// The invocation of a constructor in the same class from within a
/// constructor's initialization list.
///
///    redirectingConstructorInvocation ::=
///        'this' ('.' identifier)? arguments
class RedirectingConstructorInvocationImpl extends ConstructorInitializerImpl
    implements RedirectingConstructorInvocation {
  /// The token for the 'this' keyword.
  @override
  Token thisKeyword;

  /// The token for the period before the name of the constructor that is being
  /// invoked, or `null` if the unnamed constructor is being invoked.
  @override
  Token period;

  /// The name of the constructor that is being invoked, or `null` if the
  /// unnamed constructor is being invoked.
  SimpleIdentifierImpl _constructorName;

  /// The list of arguments to the constructor.
  ArgumentListImpl _argumentList;

  /// The element associated with the constructor based on static type
  /// information, or `null` if the AST structure has not been resolved or if
  /// the constructor could not be resolved.
  @override
  ConstructorElement staticElement;

  /// Initialize a newly created redirecting invocation to invoke the
  /// constructor with the given name with the given arguments. The
  /// [constructorName] can be `null` if the constructor being invoked is the
  /// unnamed constructor.
  RedirectingConstructorInvocationImpl(this.thisKeyword, this.period,
      SimpleIdentifierImpl constructorName, ArgumentListImpl argumentList) {
    _constructorName = _becomeParentOf(constructorName);
    _argumentList = _becomeParentOf(argumentList);
  }

  @override
  ArgumentList get argumentList => _argumentList;

  @override
  set argumentList(ArgumentList argumentList) {
    _argumentList = _becomeParentOf(argumentList as ArgumentListImpl);
  }

  @override
  Token get beginToken => thisKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(thisKeyword)
    ..add(period)
    ..add(_constructorName)
    ..add(_argumentList);

  @override
  SimpleIdentifier get constructorName => _constructorName;

  @override
  set constructorName(SimpleIdentifier identifier) {
    _constructorName = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  Token get endToken => _argumentList.endToken;

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitRedirectingConstructorInvocation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _constructorName?.accept(visitor);
    _argumentList?.accept(visitor);
  }
}

/// A rethrow expression.
///
///    rethrowExpression ::=
///        'rethrow'
class RethrowExpressionImpl extends ExpressionImpl
    implements RethrowExpression {
  /// The token representing the 'rethrow' keyword.
  @override
  Token rethrowKeyword;

  /// Initialize a newly created rethrow expression.
  RethrowExpressionImpl(this.rethrowKeyword);

  @override
  Token get beginToken => rethrowKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(rethrowKeyword);

  @override
  Token get endToken => rethrowKeyword;

  @override
  Precedence get precedence => Precedence.assignment;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitRethrowExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// A return statement.
///
///    returnStatement ::=
///        'return' [Expression]? ';'
class ReturnStatementImpl extends StatementImpl implements ReturnStatement {
  /// The token representing the 'return' keyword.
  @override
  Token returnKeyword;

  /// The expression computing the value to be returned, or `null` if no
  /// explicit value was provided.
  ExpressionImpl _expression;

  /// The semicolon terminating the statement.
  @override
  Token semicolon;

  /// Initialize a newly created return statement. The [expression] can be
  /// `null` if no explicit value was provided.
  ReturnStatementImpl(
      this.returnKeyword, ExpressionImpl expression, this.semicolon) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Token get beginToken => returnKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(returnKeyword)..add(_expression)..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  Expression get expression => _expression;

  @override
  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitReturnStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression?.accept(visitor);
  }
}

/// A script tag that can optionally occur at the beginning of a compilation
/// unit.
///
///    scriptTag ::=
///        '#!' (~NEWLINE)* NEWLINE
class ScriptTagImpl extends AstNodeImpl implements ScriptTag {
  /// The token representing this script tag.
  @override
  Token scriptTag;

  /// Initialize a newly created script tag.
  ScriptTagImpl(this.scriptTag);

  @override
  Token get beginToken => scriptTag;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(scriptTag);

  @override
  Token get endToken => scriptTag;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitScriptTag(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

class SetOrMapLiteralImpl extends TypedLiteralImpl implements SetOrMapLiteral {
  @override
  Token leftBracket;

  /// The syntactic elements in the set.
  NodeList<CollectionElement> _elements;

  @override
  Token rightBracket;

  /// A representation of whether this literal represents a map or a set, or
  /// whether the kind has not or cannot be determined.
  _SetOrMapKind _resolvedKind;

  /// The context type computed by
  /// [ResolverVisitor._computeSetOrMapContextType].
  ///
  /// Note that this is not the same as the context pushed down by type
  /// inference (which can be obtained via [InferenceContext.getContext]).  For
  /// example, in the following code:
  ///
  ///     var m = {};
  ///
  /// The context pushed down by type inference is null, whereas the
  /// `contextType` is `Map<dynamic, dynamic>`.
  InterfaceType contextType;

  /// Initialize a newly created set or map literal. The [constKeyword] can be
  /// `null` if the literal is not a constant. The [typeArguments] can be `null`
  /// if no type arguments were declared. The [elements] can be `null` if the
  /// set is empty.
  SetOrMapLiteralImpl(Token constKeyword, TypeArgumentListImpl typeArguments,
      this.leftBracket, List<CollectionElement> elements, this.rightBracket)
      : super(constKeyword, typeArguments) {
    _elements = NodeListImpl<CollectionElement>(this, elements);
    _resolvedKind = _SetOrMapKind.unresolved;
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
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(leftBracket)
    ..addAll(elements)
    ..add(rightBracket);

  @override
  NodeList<CollectionElement> get elements => _elements;

  @override
  Token get endToken => rightBracket;

  @override
  bool get isMap => _resolvedKind == _SetOrMapKind.map;

  @override
  bool get isSet => _resolvedKind == _SetOrMapKind.set;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitSetOrMapLiteral(this);

  void becomeMap() {
    assert(_resolvedKind == _SetOrMapKind.unresolved ||
        _resolvedKind == _SetOrMapKind.map);
    _resolvedKind = _SetOrMapKind.map;
  }

  void becomeSet() {
    assert(_resolvedKind == _SetOrMapKind.unresolved ||
        _resolvedKind == _SetOrMapKind.set);
    _resolvedKind = _SetOrMapKind.set;
  }

  void becomeUnresolved() {
    _resolvedKind = _SetOrMapKind.unresolved;
  }

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _elements.accept(visitor);
  }
}

/// A combinator that restricts the names being imported to those in a given
/// list.
///
///    showCombinator ::=
///        'show' [SimpleIdentifier] (',' [SimpleIdentifier])*
class ShowCombinatorImpl extends CombinatorImpl implements ShowCombinator {
  /// The list of names from the library that are made visible by this
  /// combinator.
  NodeList<SimpleIdentifier> _shownNames;

  /// Initialize a newly created import show combinator.
  ShowCombinatorImpl(Token keyword, List<SimpleIdentifier> shownNames)
      : super(keyword) {
    _shownNames = NodeListImpl<SimpleIdentifier>(this, shownNames);
  }

  @override
  // TODO(paulberry): add commas.
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(keyword)
    ..addAll(_shownNames);

  @override
  Token get endToken => _shownNames.endToken;

  @override
  NodeList<SimpleIdentifier> get shownNames => _shownNames;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitShowCombinator(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _shownNames.accept(visitor);
  }
}

/// A simple formal parameter.
///
///    simpleFormalParameter ::=
///        ('final' [TypeName] | 'var' | [TypeName])? [SimpleIdentifier]
class SimpleFormalParameterImpl extends NormalFormalParameterImpl
    implements SimpleFormalParameter {
  /// The token representing either the 'final', 'const' or 'var' keyword, or
  /// `null` if no keyword was used.
  @override
  Token keyword;

  /// The name of the declared type of the parameter, or `null` if the parameter
  /// does not have a declared type.
  TypeAnnotationImpl _type;

  @override
  // TODO(brianwilkerson) This overrides a concrete implementation in which the
  // element is assumed to be stored in the `identifier`, but there is no
  // corresponding inherited setter. This seems inconsistent and error prone.
  ParameterElement declaredElement;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute. The [keyword] can be `null` if a type was
  /// specified. The [type] must be `null` if the keyword is 'var'.
  SimpleFormalParameterImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      Token covariantKeyword,
      Token requiredKeyword,
      this.keyword,
      TypeAnnotationImpl type,
      SimpleIdentifierImpl identifier)
      : super(
            comment, metadata, covariantKeyword, requiredKeyword, identifier) {
    _type = _becomeParentOf(type);
  }

  @override
  Token get beginToken {
    NodeList<Annotation> metadata = this.metadata;
    if (metadata.isNotEmpty) {
      return metadata.beginToken;
    } else if (requiredKeyword != null) {
      return requiredKeyword;
    } else if (covariantKeyword != null) {
      return covariantKeyword;
    } else if (keyword != null) {
      return keyword;
    } else if (_type != null) {
      return _type.beginToken;
    }
    return identifier?.beginToken;
  }

  @override
  Iterable<SyntacticEntity> get childEntities =>
      super._childEntities..add(keyword)..add(_type)..add(identifier);

  @override
  Token get endToken => identifier?.endToken ?? type?.endToken;

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @override
  TypeAnnotation get type => _type;

  @override
  set type(TypeAnnotation type) {
    _type = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitSimpleFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _type?.accept(visitor);
    identifier?.accept(visitor);
  }
}

/// A simple identifier.
///
///    simpleIdentifier ::=
///        initialCharacter internalCharacter*
///
///    initialCharacter ::= '_' | '$' | letter
///
///    internalCharacter ::= '_' | '$' | letter | digit
class SimpleIdentifierImpl extends IdentifierImpl implements SimpleIdentifier {
  /// The token representing the identifier.
  @override
  Token token;

  /// The element associated with this identifier based on static type
  /// information, or `null` if the AST structure has not been resolved or if
  /// this identifier could not be resolved.
  Element _staticElement;

  /// If this expression is both in a getter and setter context, the
  /// [AuxiliaryElements] will be set to hold onto the static element from the
  /// getter context.
  @override
  AuxiliaryElements auxiliaryElements;

  @override
  List<DartType> tearOffTypeArgumentTypes;

  /// Initialize a newly created identifier.
  SimpleIdentifierImpl(this.token);

  @override
  Token get beginToken => token;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()..add(token);

  @override
  Token get endToken => token;

  @override
  bool get isQualified {
    AstNode parent = this.parent;
    if (parent is PrefixedIdentifier) {
      return identical(parent.identifier, this);
    } else if (parent is PropertyAccess) {
      return identical(parent.propertyName, this);
    } else if (parent is MethodInvocation) {
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
  Precedence get precedence => Precedence.primary;

  /// This element is set when this identifier is used not as an expression,
  /// but just to reference some element.
  ///
  /// Examples are the name of the type in a [TypeName], the name of the method
  /// in a [MethodInvocation], the name of the constructor in a
  /// [ConstructorName], the name of the property in a [PropertyAccess], the
  /// prefix and the identifier in a [PrefixedIdentifier] (which then can be
  /// used to read or write a value).
  ///
  /// In invalid code, for recovery, any element could be used, e.g. a
  /// setter as a type name `set mySetter(_) {} mySetter topVar;`. We do this
  /// to help the user to navigate to this element, and maybe change its name,
  /// add a new declaration, etc.
  ///
  /// Return `null` if this identifier is used to either read or write a value,
  /// or the AST structure has not been resolved, or if this identifier could
  /// not be resolved.
  ///
  /// If either [readElement] or [writeElement] are not `null`, the
  /// [referenceElement] is `null`, because the identifier is being used to
  /// read or write a value.
  ///
  /// All three [readElement], [writeElement], and [referenceElement] can be
  /// `null` when the AST structure has not been resolved, or this identifier
  /// could not be resolved.
  Element get referenceElement => null;

  @override
  Element get staticElement => _staticElement;

  @override
  set staticElement(Element element) {
    _staticElement = element;
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitSimpleIdentifier(this);

  @override
  bool inDeclarationContext() => false;

  @override
  bool inGetterContext() {
    // TODO(brianwilkerson) Convert this to a getter.
    AstNode initialParent = this.parent;
    AstNode parent = initialParent;
    AstNode target = this;
    // skip prefix
    if (initialParent is PrefixedIdentifier) {
      if (identical(initialParent.prefix, this)) {
        return true;
      }
      parent = initialParent.parent;
      target = initialParent;
    } else if (initialParent is PropertyAccess) {
      if (identical(initialParent.target, this)) {
        return true;
      }
      parent = initialParent.parent;
      target = initialParent;
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
    if (parent is ConstructorFieldInitializer &&
        identical(parent.fieldName, target)) {
      return false;
    }
    if (parent is ForEachPartsWithIdentifier) {
      if (identical(parent.identifier, target)) {
        return false;
      }
    }
    if (parent is FieldFormalParameter) {
      if (identical(parent.identifier, target)) {
        return false;
      }
    }
    if (parent is VariableDeclaration) {
      if (identical(parent.name, target)) {
        return false;
      }
    }
    return true;
  }

  @override
  bool inSetterContext() {
    // TODO(brianwilkerson) Convert this to a getter.
    AstNode initialParent = this.parent;
    AstNode parent = initialParent;
    AstNode target = this;
    // skip prefix
    if (initialParent is PrefixedIdentifier) {
      // if this is the prefix, then return false
      if (identical(initialParent.prefix, this)) {
        return false;
      }
      parent = initialParent.parent;
      target = initialParent;
    } else if (initialParent is PropertyAccess) {
      if (identical(initialParent.target, this)) {
        return false;
      }
      parent = initialParent.parent;
      target = initialParent;
    }
    // analyze usage
    if (parent is PrefixExpression) {
      return parent.operator.type.isIncrementOperator;
    } else if (parent is PostfixExpression) {
      return parent.operator.type.isIncrementOperator;
    } else if (parent is AssignmentExpression) {
      return identical(parent.leftHandSide, target);
    } else if (parent is ForEachPartsWithIdentifier) {
      return identical(parent.identifier, target);
    }
    return false;
  }

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// A string literal expression that does not contain any interpolations.
///
///    simpleStringLiteral ::=
///        rawStringLiteral
///      | basicStringLiteral
///
///    rawStringLiteral ::=
///        'r' basicStringLiteral
///
///    simpleStringLiteral ::=
///        multiLineStringLiteral
///      | singleLineStringLiteral
///
///    multiLineStringLiteral ::=
///        "'''" characters "'''"
///      | '"""' characters '"""'
///
///    singleLineStringLiteral ::=
///        "'" characters "'"
///      | '"' characters '"'
class SimpleStringLiteralImpl extends SingleStringLiteralImpl
    implements SimpleStringLiteral {
  /// The token representing the literal.
  @override
  Token literal;

  /// The value of the literal.
  String _value;

  /// Initialize a newly created simple string literal.
  SimpleStringLiteralImpl(this.literal, String value) {
    _value = StringUtilities.intern(value);
  }

  @override
  Token get beginToken => literal;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()..add(literal);

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

  @override
  String get value => _value;

  @override
  set value(String string) {
    _value = StringUtilities.intern(_value);
  }

  StringLexemeHelper get _helper {
    return StringLexemeHelper(literal.lexeme, true, true);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitSimpleStringLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }

  @override
  void _appendStringValue(StringBuffer buffer) {
    buffer.write(value);
  }
}

/// A single string literal expression.
///
///    singleStringLiteral ::=
///        [SimpleStringLiteral]
///      | [StringInterpolation]
abstract class SingleStringLiteralImpl extends StringLiteralImpl
    implements SingleStringLiteral {}

class SpreadElementImpl extends AstNodeImpl
    implements CollectionElementImpl, SpreadElement {
  @override
  Token spreadOperator;

  ExpressionImpl _expression;

  SpreadElementImpl(this.spreadOperator, ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Token get beginToken => spreadOperator;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(spreadOperator)..add(_expression);

  @override
  Token get endToken => _expression.endToken;

  @override
  Expression get expression => _expression;

  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  bool get isNullAware =>
      spreadOperator.type == TokenType.PERIOD_PERIOD_PERIOD_QUESTION;

  @override
  E accept<E>(AstVisitor<E> visitor) {
    return visitor.visitSpreadElement(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _expression?.accept(visitor);
  }
}

/// A node that represents a statement.
///
///    statement ::=
///        [Block]
///      | [VariableDeclarationStatement]
///      | [ForStatement]
///      | [ForEachStatement]
///      | [WhileStatement]
///      | [DoStatement]
///      | [SwitchStatement]
///      | [IfStatement]
///      | [TryStatement]
///      | [BreakStatement]
///      | [ContinueStatement]
///      | [ReturnStatement]
///      | [ExpressionStatement]
///      | [FunctionDeclarationStatement]
abstract class StatementImpl extends AstNodeImpl implements Statement {
  @override
  Statement get unlabeled => this;
}

/// A string interpolation literal.
///
///    stringInterpolation ::=
///        ''' [InterpolationElement]* '''
///      | '"' [InterpolationElement]* '"'
class StringInterpolationImpl extends SingleStringLiteralImpl
    implements StringInterpolation {
  /// The elements that will be composed to produce the resulting string.
  NodeList<InterpolationElement> _elements;

  /// Initialize a newly created string interpolation expression.
  StringInterpolationImpl(List<InterpolationElement> elements) {
    _elements = NodeListImpl<InterpolationElement>(this, elements);
  }

  @override
  Token get beginToken => _elements.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..addAll(_elements);

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

  /// Return the elements that will be composed to produce the resulting string.
  @override
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
    return StringLexemeHelper(lexeme, true, false);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitStringInterpolation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _elements.accept(visitor);
  }

  @override
  void _appendStringValue(StringBuffer buffer) {
    throw ArgumentError();
  }
}

/// A helper for analyzing string lexemes.
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
      isRaw = lexeme.startsWith('r');
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

  /// Given the [lexeme] for a multi-line string whose content begins at the
  /// given [start] index, return the index of the first character that is
  /// included in the value of the string. According to the specification:
  ///
  /// If the first line of a multiline string consists solely of the whitespace
  /// characters defined by the production WHITESPACE 20.1), possibly prefixed
  /// by \, then that line is ignored, including the new line at its end.
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

/// A string literal expression.
///
///    stringLiteral ::=
///        [SimpleStringLiteral]
///      | [AdjacentStrings]
///      | [StringInterpolation]
abstract class StringLiteralImpl extends LiteralImpl implements StringLiteral {
  @override
  String get stringValue {
    StringBuffer buffer = StringBuffer();
    try {
      _appendStringValue(buffer);
    } on ArgumentError {
      return null;
    }
    return buffer.toString();
  }

  /// Append the value of this string literal to the given [buffer]. Throw an
  /// [ArgumentError] if the string is not a constant string without any
  /// string interpolation.
  void _appendStringValue(StringBuffer buffer);
}

/// The invocation of a superclass' constructor from within a constructor's
/// initialization list.
///
///    superInvocation ::=
///        'super' ('.' [SimpleIdentifier])? [ArgumentList]
class SuperConstructorInvocationImpl extends ConstructorInitializerImpl
    implements SuperConstructorInvocation {
  /// The token for the 'super' keyword.
  @override
  Token superKeyword;

  /// The token for the period before the name of the constructor that is being
  /// invoked, or `null` if the unnamed constructor is being invoked.
  @override
  Token period;

  /// The name of the constructor that is being invoked, or `null` if the
  /// unnamed constructor is being invoked.
  SimpleIdentifierImpl _constructorName;

  /// The list of arguments to the constructor.
  ArgumentListImpl _argumentList;

  /// The element associated with the constructor based on static type
  /// information, or `null` if the AST structure has not been resolved or if
  /// the constructor could not be resolved.
  @override
  ConstructorElement staticElement;

  /// Initialize a newly created super invocation to invoke the inherited
  /// constructor with the given name with the given arguments. The [period] and
  /// [constructorName] can be `null` if the constructor being invoked is the
  /// unnamed constructor.
  SuperConstructorInvocationImpl(this.superKeyword, this.period,
      SimpleIdentifierImpl constructorName, ArgumentListImpl argumentList) {
    _constructorName = _becomeParentOf(constructorName);
    _argumentList = _becomeParentOf(argumentList);
  }

  @override
  ArgumentList get argumentList => _argumentList;

  @override
  set argumentList(ArgumentList argumentList) {
    _argumentList = _becomeParentOf(argumentList as ArgumentListImpl);
  }

  @override
  Token get beginToken => superKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(superKeyword)
    ..add(period)
    ..add(_constructorName)
    ..add(_argumentList);

  @override
  SimpleIdentifier get constructorName => _constructorName;

  @override
  set constructorName(SimpleIdentifier identifier) {
    _constructorName = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  Token get endToken => _argumentList.endToken;

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitSuperConstructorInvocation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _constructorName?.accept(visitor);
    _argumentList?.accept(visitor);
  }
}

/// A super expression.
///
///    superExpression ::=
///        'super'
class SuperExpressionImpl extends ExpressionImpl implements SuperExpression {
  /// The token representing the 'super' keyword.
  @override
  Token superKeyword;

  /// Initialize a newly created super expression.
  SuperExpressionImpl(this.superKeyword);

  @override
  Token get beginToken => superKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(superKeyword);

  @override
  Token get endToken => superKeyword;

  @override
  Precedence get precedence => Precedence.primary;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitSuperExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// A case in a switch statement.
///
///    switchCase ::=
///        [SimpleIdentifier]* 'case' [Expression] ':' [Statement]*
class SwitchCaseImpl extends SwitchMemberImpl implements SwitchCase {
  /// The expression controlling whether the statements will be executed.
  ExpressionImpl _expression;

  /// Initialize a newly created switch case. The list of [labels] can be `null`
  /// if there are no labels.
  SwitchCaseImpl(List<Label> labels, Token keyword, ExpressionImpl expression,
      Token colon, List<Statement> statements)
      : super(labels, keyword, colon, statements) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..addAll(labels)
    ..add(keyword)
    ..add(_expression)
    ..add(colon)
    ..addAll(statements);

  @override
  Expression get expression => _expression;

  @override
  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitSwitchCase(this);

  @override
  void visitChildren(AstVisitor visitor) {
    labels.accept(visitor);
    _expression?.accept(visitor);
    statements.accept(visitor);
  }
}

/// The default case in a switch statement.
///
///    switchDefault ::=
///        [SimpleIdentifier]* 'default' ':' [Statement]*
class SwitchDefaultImpl extends SwitchMemberImpl implements SwitchDefault {
  /// Initialize a newly created switch default. The list of [labels] can be
  /// `null` if there are no labels.
  SwitchDefaultImpl(List<Label> labels, Token keyword, Token colon,
      List<Statement> statements)
      : super(labels, keyword, colon, statements);

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..addAll(labels)
    ..add(keyword)
    ..add(colon)
    ..addAll(statements);

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitSwitchDefault(this);

  @override
  void visitChildren(AstVisitor visitor) {
    labels.accept(visitor);
    statements.accept(visitor);
  }
}

/// An element within a switch statement.
///
///    switchMember ::=
///        switchCase
///      | switchDefault
abstract class SwitchMemberImpl extends AstNodeImpl implements SwitchMember {
  /// The labels associated with the switch member.
  NodeList<Label> _labels;

  /// The token representing the 'case' or 'default' keyword.
  @override
  Token keyword;

  /// The colon separating the keyword or the expression from the statements.
  @override
  Token colon;

  /// The statements that will be executed if this switch member is selected.
  NodeList<Statement> _statements;

  /// Initialize a newly created switch member. The list of [labels] can be
  /// `null` if there are no labels.
  SwitchMemberImpl(List<Label> labels, this.keyword, this.colon,
      List<Statement> statements) {
    _labels = NodeListImpl<Label>(this, labels);
    _statements = NodeListImpl<Statement>(this, statements);
  }

  @override
  Token get beginToken {
    if (_labels.isNotEmpty) {
      return _labels.beginToken;
    }
    return keyword;
  }

  @override
  Token get endToken {
    if (_statements.isNotEmpty) {
      return _statements.endToken;
    }
    return colon;
  }

  @override
  NodeList<Label> get labels => _labels;

  @override
  NodeList<Statement> get statements => _statements;
}

/// A switch statement.
///
///    switchStatement ::=
///        'switch' '(' [Expression] ')' '{' [SwitchCase]* [SwitchDefault]? '}'
class SwitchStatementImpl extends StatementImpl implements SwitchStatement {
  /// The token representing the 'switch' keyword.
  @override
  Token switchKeyword;

  /// The left parenthesis.
  @override
  Token leftParenthesis;

  /// The expression used to determine which of the switch members will be
  /// selected.
  ExpressionImpl _expression;

  /// The right parenthesis.
  @override
  Token rightParenthesis;

  /// The left curly bracket.
  @override
  Token leftBracket;

  /// The switch members that can be selected by the expression.
  NodeList<SwitchMember> _members;

  /// The right curly bracket.
  @override
  Token rightBracket;

  /// Initialize a newly created switch statement. The list of [members] can be
  /// `null` if there are no switch members.
  SwitchStatementImpl(
      this.switchKeyword,
      this.leftParenthesis,
      ExpressionImpl expression,
      this.rightParenthesis,
      this.leftBracket,
      List<SwitchMember> members,
      this.rightBracket) {
    _expression = _becomeParentOf(expression);
    _members = NodeListImpl<SwitchMember>(this, members);
  }

  @override
  Token get beginToken => switchKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(switchKeyword)
    ..add(leftParenthesis)
    ..add(_expression)
    ..add(rightParenthesis)
    ..add(leftBracket)
    ..addAll(_members)
    ..add(rightBracket);

  @override
  Token get endToken => rightBracket;

  @override
  Expression get expression => _expression;

  @override
  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  NodeList<SwitchMember> get members => _members;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitSwitchStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression?.accept(visitor);
    _members.accept(visitor);
  }
}

/// A symbol literal expression.
///
///    symbolLiteral ::=
///        '#' (operator | (identifier ('.' identifier)*))
class SymbolLiteralImpl extends LiteralImpl implements SymbolLiteral {
  /// The token introducing the literal.
  @override
  Token poundSign;

  /// The components of the literal.
  @override
  final List<Token> components;

  /// Initialize a newly created symbol literal.
  SymbolLiteralImpl(this.poundSign, this.components);

  @override
  Token get beginToken => poundSign;

  @override
  // TODO(paulberry): add "." tokens.
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(poundSign)
    ..addAll(components);

  @override
  Token get endToken => components[components.length - 1];

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitSymbolLiteral(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// A this expression.
///
///    thisExpression ::=
///        'this'
class ThisExpressionImpl extends ExpressionImpl implements ThisExpression {
  /// The token representing the 'this' keyword.
  @override
  Token thisKeyword;

  /// Initialize a newly created this expression.
  ThisExpressionImpl(this.thisKeyword);

  @override
  Token get beginToken => thisKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(thisKeyword);

  @override
  Token get endToken => thisKeyword;

  @override
  Precedence get precedence => Precedence.primary;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitThisExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// A throw expression.
///
///    throwExpression ::=
///        'throw' [Expression]
class ThrowExpressionImpl extends ExpressionImpl implements ThrowExpression {
  /// The token representing the 'throw' keyword.
  @override
  Token throwKeyword;

  /// The expression computing the exception to be thrown.
  ExpressionImpl _expression;

  /// Initialize a newly created throw expression.
  ThrowExpressionImpl(this.throwKeyword, ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Token get beginToken => throwKeyword;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(throwKeyword)..add(_expression);

  @override
  Token get endToken {
    if (_expression != null) {
      return _expression.endToken;
    }
    return throwKeyword;
  }

  @override
  Expression get expression => _expression;

  @override
  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Precedence get precedence => Precedence.assignment;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitThrowExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression?.accept(visitor);
  }
}

/// The declaration of one or more top-level variables of the same type.
///
///    topLevelVariableDeclaration ::=
///        ('final' | 'const') type? staticFinalDeclarationList ';'
///      | variableDeclaration ';'
class TopLevelVariableDeclarationImpl extends CompilationUnitMemberImpl
    implements TopLevelVariableDeclaration {
  /// The top-level variables being declared.
  VariableDeclarationListImpl _variableList;

  @override
  Token externalKeyword;

  /// The semicolon terminating the declaration.
  @override
  Token semicolon;

  /// Initialize a newly created top-level variable declaration. Either or both
  /// of the [comment] and [metadata] can be `null` if the variable does not
  /// have the corresponding attribute.
  TopLevelVariableDeclarationImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      this.externalKeyword,
      VariableDeclarationListImpl variableList,
      this.semicolon)
      : super(comment, metadata) {
    _variableList = _becomeParentOf(variableList);
  }

  @override
  Iterable<SyntacticEntity> get childEntities =>
      super._childEntities..add(_variableList)..add(semicolon);

  @override
  Element get declaredElement => null;

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata =>
      externalKeyword ?? _variableList.beginToken;

  @override
  VariableDeclarationList get variables => _variableList;

  @override
  set variables(VariableDeclarationList variables) {
    _variableList = _becomeParentOf(variables as VariableDeclarationListImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitTopLevelVariableDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _variableList?.accept(visitor);
  }
}

/// A try statement.
///
///    tryStatement ::=
///        'try' [Block] ([CatchClause]+ finallyClause? | finallyClause)
///
///    finallyClause ::=
///        'finally' [Block]
class TryStatementImpl extends StatementImpl implements TryStatement {
  /// The token representing the 'try' keyword.
  @override
  Token tryKeyword;

  /// The body of the statement.
  BlockImpl _body;

  /// The catch clauses contained in the try statement.
  NodeList<CatchClause> _catchClauses;

  /// The token representing the 'finally' keyword, or `null` if the statement
  /// does not contain a finally clause.
  @override
  Token finallyKeyword;

  /// The finally block contained in the try statement, or `null` if the
  /// statement does not contain a finally clause.
  BlockImpl _finallyBlock;

  /// Initialize a newly created try statement. The list of [catchClauses] can
  /// be`null` if there are no catch clauses. The [finallyKeyword] and
  /// [finallyBlock] can be `null` if there is no finally clause.
  TryStatementImpl(
      this.tryKeyword,
      BlockImpl body,
      List<CatchClause> catchClauses,
      this.finallyKeyword,
      BlockImpl finallyBlock) {
    _body = _becomeParentOf(body);
    _catchClauses = NodeListImpl<CatchClause>(this, catchClauses);
    _finallyBlock = _becomeParentOf(finallyBlock);
  }

  @override
  Token get beginToken => tryKeyword;

  @override
  Block get body => _body;

  @override
  set body(Block block) {
    _body = _becomeParentOf(block as BlockImpl);
  }

  @override
  NodeList<CatchClause> get catchClauses => _catchClauses;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
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
    } else if (_catchClauses.isNotEmpty) {
      return _catchClauses.endToken;
    }
    return _body.endToken;
  }

  @override
  Block get finallyBlock => _finallyBlock;

  @override
  set finallyBlock(Block block) {
    _finallyBlock = _becomeParentOf(block as BlockImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitTryStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _body?.accept(visitor);
    _catchClauses.accept(visitor);
    _finallyBlock?.accept(visitor);
  }
}

/// The declaration of a type alias.
///
///    typeAlias ::=
///        'typedef' typeAliasBody
///
///    typeAliasBody ::=
///        classTypeAlias
///      | functionTypeAlias
abstract class TypeAliasImpl extends NamedCompilationUnitMemberImpl
    implements TypeAlias {
  /// The token representing the 'typedef' keyword.
  @override
  Token typedefKeyword;

  /// The semicolon terminating the declaration.
  @override
  Token semicolon;

  /// Initialize a newly created type alias. Either or both of the [comment] and
  /// [metadata] can be `null` if the declaration does not have the
  /// corresponding attribute.
  TypeAliasImpl(CommentImpl comment, List<Annotation> metadata,
      this.typedefKeyword, SimpleIdentifierImpl name, this.semicolon)
      : super(comment, metadata, name);

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => typedefKeyword;
}

/// A type annotation.
///
///    type ::=
///        [NamedType]
///      | [GenericFunctionType]
abstract class TypeAnnotationImpl extends AstNodeImpl
    implements TypeAnnotation {}

/// A list of type arguments.
///
///    typeArguments ::=
///        '<' typeName (',' typeName)* '>'
class TypeArgumentListImpl extends AstNodeImpl implements TypeArgumentList {
  /// The left bracket.
  @override
  Token leftBracket;

  /// The type arguments associated with the type.
  NodeList<TypeAnnotation> _arguments;

  /// The right bracket.
  @override
  Token rightBracket;

  /// Initialize a newly created list of type arguments.
  TypeArgumentListImpl(
      this.leftBracket, List<TypeAnnotation> arguments, this.rightBracket) {
    _arguments = NodeListImpl<TypeAnnotation>(this, arguments);
  }

  @override
  NodeList<TypeAnnotation> get arguments => _arguments;

  @override
  Token get beginToken => leftBracket;

  @override
  // TODO(paulberry): Add commas.
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(leftBracket)
    ..addAll(_arguments)
    ..add(rightBracket);

  @override
  Token get endToken => rightBracket;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitTypeArgumentList(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _arguments.accept(visitor);
  }
}

/// A literal that has a type associated with it.
///
///    typedLiteral ::=
///        [ListLiteral]
///      | [MapLiteral]
abstract class TypedLiteralImpl extends LiteralImpl implements TypedLiteral {
  /// The token representing the 'const' keyword, or `null` if the literal is
  /// not a constant.
  @override
  Token constKeyword;

  /// The type argument associated with this literal, or `null` if no type
  /// arguments were declared.
  TypeArgumentListImpl _typeArguments;

  /// Initialize a newly created typed literal. The [constKeyword] can be
  /// `null` if the literal is not a constant. The [typeArguments] can be `null`
  /// if no type arguments were declared.
  TypedLiteralImpl(this.constKeyword, TypeArgumentListImpl typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @override
  bool get isConst {
    return constKeyword != null || inConstantContext;
  }

  @override
  TypeArgumentList get typeArguments => _typeArguments;

  @override
  set typeArguments(TypeArgumentList typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments as TypeArgumentListImpl);
  }

  ChildEntities get _childEntities =>
      ChildEntities()..add(constKeyword)..add(_typeArguments);

  @override
  void visitChildren(AstVisitor visitor) {
    _typeArguments?.accept(visitor);
  }
}

/// The name of a type, which can optionally include type arguments.
///
///    typeName ::=
///        [Identifier] typeArguments? '?'?
class TypeNameImpl extends TypeAnnotationImpl implements TypeName {
  /// The name of the type.
  IdentifierImpl _name;

  /// The type arguments associated with the type, or `null` if there are no
  /// type arguments.
  TypeArgumentListImpl _typeArguments;

  @override
  Token question;

  /// The type being named, or `null` if the AST structure has not been
  /// resolved.
  @override
  DartType type;

  /// Initialize a newly created type name. The [typeArguments] can be `null` if
  /// there are no type arguments.
  TypeNameImpl(IdentifierImpl name, TypeArgumentListImpl typeArguments,
      {this.question}) {
    _name = _becomeParentOf(name);
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @override
  Token get beginToken => _name.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(_name)..add(_typeArguments)..add(question);

  @override
  Token get endToken => question ?? _typeArguments?.endToken ?? _name.endToken;

  @override
  bool get isDeferred {
    Identifier identifier = name;
    if (identifier is! PrefixedIdentifier) {
      return false;
    }
    return (identifier as PrefixedIdentifier).isDeferred;
  }

  @override
  bool get isSynthetic => _name.isSynthetic && _typeArguments == null;

  @override
  Identifier get name => _name;

  @override
  set name(Identifier identifier) {
    _name = _becomeParentOf(identifier as IdentifierImpl);
  }

  @override
  TypeArgumentList get typeArguments => _typeArguments;

  @override
  set typeArguments(TypeArgumentList typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments as TypeArgumentListImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitTypeName(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _name?.accept(visitor);
    _typeArguments?.accept(visitor);
  }
}

/// A type parameter.
///
///    typeParameter ::=
///        typeParameterVariance? [SimpleIdentifier] ('extends' [TypeName])?
///
///    typeParameterVariance ::= 'out' | 'inout' | 'in'
class TypeParameterImpl extends DeclarationImpl implements TypeParameter {
  /// The name of the type parameter.
  SimpleIdentifierImpl _name;

  /// The token representing the variance modifier keyword, or `null` if
  /// there is no explicit variance modifier, meaning legacy covariance.
  Token varianceKeyword;

  /// The token representing the 'extends' keyword, or `null` if there is no
  /// explicit upper bound.
  @override
  Token extendsKeyword;

  /// The name of the upper bound for legal arguments, or `null` if there is no
  /// explicit upper bound.
  TypeAnnotationImpl _bound;

  /// Initialize a newly created type parameter. Either or both of the [comment]
  /// and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute. The [extendsKeyword] and [bound] can be `null` if
  /// the parameter does not have an upper bound.
  TypeParameterImpl(CommentImpl comment, List<Annotation> metadata,
      SimpleIdentifierImpl name, this.extendsKeyword, TypeAnnotationImpl bound)
      : super(comment, metadata) {
    _name = _becomeParentOf(name);
    _bound = _becomeParentOf(bound);
  }

  @override
  TypeAnnotation get bound => _bound;

  @override
  set bound(TypeAnnotation type) {
    _bound = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  Iterable<SyntacticEntity> get childEntities =>
      super._childEntities..add(_name)..add(extendsKeyword)..add(_bound);

  @override
  TypeParameterElement get declaredElement =>
      _name?.staticElement as TypeParameterElement;

  @override
  Token get endToken {
    if (_bound == null) {
      return _name.endToken;
    }
    return _bound.endToken;
  }

  @override
  Token get firstTokenAfterCommentAndMetadata => _name.beginToken;

  @override
  SimpleIdentifier get name => _name;

  @override
  set name(SimpleIdentifier identifier) {
    _name = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitTypeParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _name?.accept(visitor);
    _bound?.accept(visitor);
  }
}

/// Type parameters within a declaration.
///
///    typeParameterList ::=
///        '<' [TypeParameter] (',' [TypeParameter])* '>'
class TypeParameterListImpl extends AstNodeImpl implements TypeParameterList {
  /// The left angle bracket.
  @override
  final Token leftBracket;

  /// The type parameters in the list.
  NodeList<TypeParameter> _typeParameters;

  /// The right angle bracket.
  @override
  final Token rightBracket;

  /// Initialize a newly created list of type parameters.
  TypeParameterListImpl(
      this.leftBracket, List<TypeParameter> typeParameters, this.rightBracket) {
    _typeParameters = NodeListImpl<TypeParameter>(this, typeParameters);
  }

  @override
  Token get beginToken => leftBracket;

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(leftBracket)
    ..addAll(_typeParameters)
    ..add(rightBracket);

  @override
  Token get endToken => rightBracket;

  @override
  NodeList<TypeParameter> get typeParameters => _typeParameters;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitTypeParameterList(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _typeParameters.accept(visitor);
  }
}

/// A directive that references a URI.
///
///    uriBasedDirective ::=
///        [ExportDirective]
///      | [ImportDirective]
///      | [PartDirective]
abstract class UriBasedDirectiveImpl extends DirectiveImpl
    implements UriBasedDirective {
  /// The prefix of a URI using the `dart-ext` scheme to reference a native code
  /// library.
  static const String _DART_EXT_SCHEME = "dart-ext:";

  /// The URI referenced by this directive.
  StringLiteralImpl _uri;

  @override
  String uriContent;

  @override
  Source uriSource;

  /// Initialize a newly create URI-based directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute.
  UriBasedDirectiveImpl(
      CommentImpl comment, List<Annotation> metadata, StringLiteralImpl uri)
      : super(comment, metadata) {
    _uri = _becomeParentOf(uri);
  }

  @override
  StringLiteral get uri => _uri;

  @override
  set uri(StringLiteral uri) {
    _uri = _becomeParentOf(uri as StringLiteralImpl);
  }

  UriValidationCode validate() {
    return validateUri(this is ImportDirective, uri, uriContent);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _uri?.accept(visitor);
  }

  /// Validate this directive, but do not check for existence. Return a code
  /// indicating the problem if there is one, or `null` no problem.
  static UriValidationCode validateUri(
      bool isImport, StringLiteral uriLiteral, String uriContent) {
    if (uriLiteral is StringInterpolation) {
      return UriValidationCode.URI_WITH_INTERPOLATION;
    }
    if (uriContent == null) {
      return UriValidationCode.INVALID_URI;
    }
    if (uriContent.isEmpty) {
      return null;
    }
    if (isImport && uriContent.startsWith(_DART_EXT_SCHEME)) {
      return UriValidationCode.URI_WITH_DART_EXT_SCHEME;
    }
    Uri uri;
    try {
      uri = Uri.parse(Uri.encodeFull(uriContent));
    } on FormatException {
      return UriValidationCode.INVALID_URI;
    }
    if (uri.path.isEmpty) {
      return UriValidationCode.INVALID_URI;
    }
    return null;
  }
}

/// Validation codes returned by [UriBasedDirective.validate].
class UriValidationCode {
  static const UriValidationCode INVALID_URI = UriValidationCode('INVALID_URI');

  static const UriValidationCode URI_WITH_INTERPOLATION =
      UriValidationCode('URI_WITH_INTERPOLATION');

  static const UriValidationCode URI_WITH_DART_EXT_SCHEME =
      UriValidationCode('URI_WITH_DART_EXT_SCHEME');

  /// The name of the validation code.
  final String name;

  /// Initialize a newly created validation code to have the given [name].
  const UriValidationCode(this.name);

  @override
  String toString() => name;
}

/// An identifier that has an initial value associated with it. Instances of
/// this class are always children of the class [VariableDeclarationList].
///
///    variableDeclaration ::=
///        [SimpleIdentifier] ('=' [Expression])?
///
/// TODO(paulberry): the grammar does not allow metadata to be associated with
/// a VariableDeclaration, and currently we don't record comments for it either.
/// Consider changing the class hierarchy so that [VariableDeclaration] does not
/// extend [Declaration].
class VariableDeclarationImpl extends DeclarationImpl
    implements VariableDeclaration {
  /// The name of the variable being declared.
  SimpleIdentifierImpl _name;

  /// The equal sign separating the variable name from the initial value, or
  /// `null` if the initial value was not specified.
  @override
  Token equals;

  /// The expression used to compute the initial value for the variable, or
  /// `null` if the initial value was not specified.
  ExpressionImpl _initializer;

  /// Initialize a newly created variable declaration. The [equals] and
  /// [initializer] can be `null` if there is no initializer.
  VariableDeclarationImpl(
      SimpleIdentifierImpl name, this.equals, ExpressionImpl initializer)
      : super(null, null) {
    _name = _becomeParentOf(name);
    _initializer = _becomeParentOf(initializer);
  }

  @override
  Iterable<SyntacticEntity> get childEntities =>
      super._childEntities..add(_name)..add(equals)..add(_initializer);

  @override
  VariableElement get declaredElement =>
      _name?.staticElement as VariableElement;

  /// This overridden implementation of [documentationComment] looks in the
  /// grandparent node for Dartdoc comments if no documentation is specifically
  /// available on the node.
  @override
  Comment get documentationComment {
    Comment comment = super.documentationComment;
    if (comment == null) {
      AstNode node = parent?.parent;
      if (node is AnnotatedNode) {
        return node.documentationComment;
      }
    }
    return comment;
  }

  @override
  Token get endToken {
    if (_initializer != null) {
      return _initializer.endToken;
    }
    return _name.endToken;
  }

  @override
  Token get firstTokenAfterCommentAndMetadata => _name.beginToken;

  @override
  Expression get initializer => _initializer;

  @override
  set initializer(Expression expression) {
    _initializer = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  bool get isConst {
    AstNode parent = this.parent;
    return parent is VariableDeclarationList && parent.isConst;
  }

  @override
  bool get isFinal {
    AstNode parent = this.parent;
    return parent is VariableDeclarationList && parent.isFinal;
  }

  @override
  bool get isLate {
    AstNode parent = this.parent;
    return parent is VariableDeclarationList && parent.isLate;
  }

  @override
  SimpleIdentifier get name => _name;

  @override
  set name(SimpleIdentifier identifier) {
    _name = _becomeParentOf(identifier as SimpleIdentifierImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitVariableDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _name?.accept(visitor);
    _initializer?.accept(visitor);
  }
}

/// The declaration of one or more variables of the same type.
///
///    variableDeclarationList ::=
///        finalConstVarOrType [VariableDeclaration]
///        (',' [VariableDeclaration])*
///
///    finalConstVarOrType ::=
///      'final' 'late'? [TypeAnnotation]?
///      | 'const' [TypeAnnotation]?
///      | 'var'
///      | 'late'? [TypeAnnotation]
class VariableDeclarationListImpl extends AnnotatedNodeImpl
    implements VariableDeclarationList {
  /// The token representing the 'final', 'const' or 'var' keyword, or `null` if
  /// no keyword was included.
  @override
  Token keyword;

  /// The token representing the 'late' keyword, or `null` if the late modifier
  /// was not included.
  @override
  Token lateKeyword;

  /// The type of the variables being declared, or `null` if no type was
  /// provided.
  TypeAnnotationImpl _type;

  /// A list containing the individual variables being declared.
  NodeList<VariableDeclaration> _variables;

  /// Initialize a newly created variable declaration list. Either or both of
  /// the [comment] and [metadata] can be `null` if the variable list does not
  /// have the corresponding attribute. The [keyword] can be `null` if a type
  /// was specified. The [type] must be `null` if the keyword is 'var'.
  VariableDeclarationListImpl(
      CommentImpl comment,
      List<Annotation> metadata,
      this.lateKeyword,
      this.keyword,
      TypeAnnotationImpl type,
      List<VariableDeclaration> variables)
      : super(comment, metadata) {
    _type = _becomeParentOf(type);
    _variables = NodeListImpl<VariableDeclaration>(this, variables);
  }

  @override
  // TODO(paulberry): include commas.
  Iterable<SyntacticEntity> get childEntities => super._childEntities
    ..add(keyword)
    ..add(_type)
    ..addAll(_variables);

  @override
  Token get endToken => _variables.endToken;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (lateKeyword != null) {
      return lateKeyword;
    } else if (keyword != null) {
      return keyword;
    } else if (_type != null) {
      return _type.beginToken;
    }
    return _variables.beginToken;
  }

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @override
  bool get isLate => lateKeyword != null;

  @override
  TypeAnnotation get type => _type;

  @override
  set type(TypeAnnotation type) {
    _type = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  NodeList<VariableDeclaration> get variables => _variables;

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitVariableDeclarationList(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _type?.accept(visitor);
    _variables.accept(visitor);
  }
}

/// A list of variables that are being declared in a context where a statement
/// is required.
///
///    variableDeclarationStatement ::=
///        [VariableDeclarationList] ';'
class VariableDeclarationStatementImpl extends StatementImpl
    implements VariableDeclarationStatement {
  /// The variables being declared.
  VariableDeclarationListImpl _variableList;

  /// The semicolon terminating the statement.
  @override
  Token semicolon;

  /// Initialize a newly created variable declaration statement.
  VariableDeclarationStatementImpl(
      VariableDeclarationListImpl variableList, this.semicolon) {
    _variableList = _becomeParentOf(variableList);
  }

  @override
  Token get beginToken => _variableList.beginToken;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      ChildEntities()..add(_variableList)..add(semicolon);

  @override
  Token get endToken => semicolon;

  @override
  VariableDeclarationList get variables => _variableList;

  @override
  set variables(VariableDeclarationList variables) {
    _variableList = _becomeParentOf(variables as VariableDeclarationListImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) =>
      visitor.visitVariableDeclarationStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _variableList?.accept(visitor);
  }
}

/// A while statement.
///
///    whileStatement ::=
///        'while' '(' [Expression] ')' [Statement]
class WhileStatementImpl extends StatementImpl implements WhileStatement {
  /// The token representing the 'while' keyword.
  @override
  Token whileKeyword;

  /// The left parenthesis.
  @override
  Token leftParenthesis;

  /// The expression used to determine whether to execute the body of the loop.
  ExpressionImpl _condition;

  /// The right parenthesis.
  @override
  Token rightParenthesis;

  /// The body of the loop.
  StatementImpl _body;

  /// Initialize a newly created while statement.
  WhileStatementImpl(this.whileKeyword, this.leftParenthesis,
      ExpressionImpl condition, this.rightParenthesis, StatementImpl body) {
    _condition = _becomeParentOf(condition);
    _body = _becomeParentOf(body);
  }

  @override
  Token get beginToken => whileKeyword;

  @override
  Statement get body => _body;

  @override
  set body(Statement statement) {
    _body = _becomeParentOf(statement as StatementImpl);
  }

  @override
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(whileKeyword)
    ..add(leftParenthesis)
    ..add(_condition)
    ..add(rightParenthesis)
    ..add(_body);

  @override
  Expression get condition => _condition;

  @override
  set condition(Expression expression) {
    _condition = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  Token get endToken => _body.endToken;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitWhileStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _condition?.accept(visitor);
    _body?.accept(visitor);
  }
}

/// The with clause in a class declaration.
///
///    withClause ::=
///        'with' [TypeName] (',' [TypeName])*
class WithClauseImpl extends AstNodeImpl implements WithClause {
  /// The token representing the 'with' keyword.
  @override
  Token withKeyword;

  /// The names of the mixins that were specified.
  NodeList<TypeName> _mixinTypes;

  /// Initialize a newly created with clause.
  WithClauseImpl(this.withKeyword, List<TypeName> mixinTypes) {
    _mixinTypes = NodeListImpl<TypeName>(this, mixinTypes);
  }

  @override
  Token get beginToken => withKeyword;

  @override
  // TODO(paulberry): add commas.
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
    ..add(withKeyword)
    ..addAll(_mixinTypes);

  @override
  Token get endToken => _mixinTypes.endToken;

  @override
  NodeList<TypeName> get mixinTypes => _mixinTypes;

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitWithClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _mixinTypes.accept(visitor);
  }
}

/// A yield statement.
///
///    yieldStatement ::=
///        'yield' '*'? [Expression] ‘;’
class YieldStatementImpl extends StatementImpl implements YieldStatement {
  /// The 'yield' keyword.
  @override
  Token yieldKeyword;

  /// The star optionally following the 'yield' keyword.
  @override
  Token star;

  /// The expression whose value will be yielded.
  ExpressionImpl _expression;

  /// The semicolon following the expression.
  @override
  Token semicolon;

  /// Initialize a newly created yield expression. The [star] can be `null` if
  /// no star was provided.
  YieldStatementImpl(
      this.yieldKeyword, this.star, ExpressionImpl expression, this.semicolon) {
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
  Iterable<SyntacticEntity> get childEntities => ChildEntities()
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

  @override
  Expression get expression => _expression;

  @override
  set expression(Expression expression) {
    _expression = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  E accept<E>(AstVisitor<E> visitor) => visitor.visitYieldStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression?.accept(visitor);
  }
}

/// An indication of the resolved kind of a [SetOrMapLiteral].
enum _SetOrMapKind {
  /// Indicates that the literal represents a map.
  map,

  /// Indicates that the literal represents a set.
  set,

  /// Indicates that either
  /// - the literal is syntactically ambiguous and resolution has not yet been
  ///   performed, or
  /// - the literal is invalid because resolution was not able to resolve the
  ///   ambiguity.
  unresolved
}
