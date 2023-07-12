// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_operations.dart'
    as shared;
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/ast/to_source_visitor.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/resolver/typed_literal_resolver.dart';
import 'package:analyzer/src/fasta/token_utils.dart' as util show findPrevious;
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart' show LineInfo;
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Two or more string literals that are implicitly concatenated because of
/// being adjacent (separated only by whitespace).
///
/// While the grammar only allows adjacent strings when all of the strings are
/// of the same kind (single line or multi-line), this class doesn't enforce
/// that restriction.
///
///    adjacentStrings ::=
///        [StringLiteral] [StringLiteral]+
abstract final class AdjacentStrings implements StringLiteral {
  /// Return the strings that are implicitly concatenated.
  NodeList<StringLiteral> get strings;
}

/// Two or more string literals that are implicitly concatenated because of
/// being adjacent (separated only by whitespace).
///
/// While the grammar only allows adjacent strings when all of the strings are
/// of the same kind (single line or multi-line), this class doesn't enforce
/// that restriction.
///
///    adjacentStrings ::=
///        [StringLiteral] [StringLiteral]+
final class AdjacentStringsImpl extends StringLiteralImpl
    implements AdjacentStrings {
  /// The strings that are implicitly concatenated.
  final NodeListImpl<StringLiteralImpl> _strings = NodeListImpl._();

  /// Initialize a newly created list of adjacent strings. To be syntactically
  /// valid, the list of [strings] must contain at least two elements.
  AdjacentStringsImpl({
    required List<StringLiteralImpl> strings,
  }) {
    _strings._initialize(this, strings);
  }

  @override
  Token get beginToken => _strings.beginToken!;

  @override
  Token get endToken => _strings.endToken!;

  @override
  NodeListImpl<StringLiteralImpl> get strings => _strings;

  @override
  ChildEntities get _childEntities {
    return ChildEntities()..addNodeList('strings', strings);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAdjacentStrings(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitAdjacentStrings(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _strings.accept(visitor);
  }

  @override
  void _appendStringValue(StringBuffer buffer) {
    int length = strings.length;
    for (int i = 0; i < length; i++) {
      strings[i]._appendStringValue(buffer);
    }
  }
}

/// An AST node that can be annotated with both a documentation comment and a
/// list of annotations.
abstract final class AnnotatedNode implements AstNode {
  /// Return the documentation comment associated with this node, or `null` if
  /// this node does not have a documentation comment associated with it.
  Comment? get documentationComment;

  /// Return the first token following the comment and metadata.
  Token get firstTokenAfterCommentAndMetadata;

  /// Return the annotations associated with this node.
  NodeList<Annotation> get metadata;

  /// Return a list containing the comment and annotations associated with this
  /// node, sorted in lexical order.
  List<AstNode> get sortedCommentAndAnnotations;
}

/// An AST node that can be annotated with both a documentation comment and a
/// list of annotations.
sealed class AnnotatedNodeImpl extends AstNodeImpl implements AnnotatedNode {
  /// The documentation comment associated with this node, or `null` if this
  /// node does not have a documentation comment associated with it.
  CommentImpl? _comment;

  /// The annotations associated with this node.
  final NodeListImpl<AnnotationImpl> _metadata = NodeListImpl._();

  /// Initialize a newly created annotated node. Either or both of the [comment]
  /// and [metadata] can be `null` if the node does not have the corresponding
  /// attribute.
  AnnotatedNodeImpl({
    required CommentImpl? comment,
    required List<AnnotationImpl>? metadata,
  }) : _comment = comment {
    _becomeParentOf(_comment);
    _metadata._initialize(this, metadata);
  }

  @override
  Token get beginToken {
    if (_comment == null) {
      if (_metadata.isEmpty) {
        return firstTokenAfterCommentAndMetadata;
      }
      return _metadata.beginToken!;
    } else if (_metadata.isEmpty) {
      return _comment!.beginToken;
    }
    Token commentToken = _comment!.beginToken;
    Token metadataToken = _metadata.beginToken!;
    if (commentToken.offset < metadataToken.offset) {
      return commentToken;
    }
    return metadataToken;
  }

  @override
  CommentImpl? get documentationComment => _comment;

  set documentationComment(CommentImpl? comment) {
    _comment = _becomeParentOf(comment);
  }

  @override
  NodeListImpl<AnnotationImpl> get metadata => _metadata;

  @override
  List<AstNode> get sortedCommentAndAnnotations {
    var comment = _comment;
    return <AstNode>[
      if (comment != null) comment,
      ..._metadata,
    ]..sort(AstNode.LEXICAL_ORDER);
  }

  @override
  ChildEntities get _childEntities {
    return ChildEntities()
      ..addNode('documentationComment', documentationComment)
      ..addNodeList('metadata', metadata);
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
    return _comment!.offset < firstAnnotation.offset;
  }
}

/// An annotation that can be associated with an AST node.
///
///    metadata ::=
///        annotation*
///
///    annotation ::=
///        '@' metadatum
///
///    metadatum ::=
///        [Identifier]
///      | qualifiedName
///      | constructorDesignation argumentPart
abstract final class Annotation implements AstNode {
  /// Return the arguments to the constructor being invoked, or `null` if this
  /// annotation is not the invocation of a constructor.
  ArgumentList? get arguments;

  /// Return the at sign that introduced the annotation.
  Token get atSign;

  /// Return the name of the constructor being invoked, or `null` if this
  /// annotation is not the invocation of a named constructor.
  SimpleIdentifier? get constructorName;

  /// Return the element associated with this annotation, or `null` if the AST
  /// structure has not been resolved or if this annotation could not be
  /// resolved.
  Element? get element;

  /// Return the element annotation representing this annotation in the element
  /// model; `null` when the AST has not been resolved.
  ElementAnnotation? get elementAnnotation;

  /// Return the name of the class defining the constructor that is being
  /// invoked or the name of the field that is being referenced.
  Identifier get name;

  @override
  AstNode get parent;

  /// Return the period before the constructor name, or `null` if this
  /// annotation is not the invocation of a named constructor.
  Token? get period;

  /// Returns the type arguments to the constructor being invoked, or `null` if
  /// (a) this annotation is not the invocation of a constructor or (b) this
  /// annotation does not specify type arguments explicitly.
  ///
  /// Note that type arguments are only valid if [Feature.generic_metadata] is
  /// enabled.
  TypeArgumentList? get typeArguments;
}

/// An annotation that can be associated with an AST node.
///
///    metadata ::=
///        annotation*
///
///    annotation ::=
///        '@' [Identifier] ('.' [SimpleIdentifier])? [ArgumentList]?
final class AnnotationImpl extends AstNodeImpl implements Annotation {
  /// The at sign that introduced the annotation.
  @override
  final Token atSign;

  /// The name of the class defining the constructor that is being invoked or
  /// the name of the field that is being referenced.
  IdentifierImpl _name;

  /// The type arguments to the constructor being invoked, or `null` if (a) this
  /// annotation is not the invocation of a constructor or (b) this annotation
  /// does not specify type arguments explicitly.
  ///
  /// Note that type arguments are only valid if [Feature.generic_metadata] is
  /// enabled.
  TypeArgumentListImpl? _typeArguments;

  /// The period before the constructor name, or `null` if this annotation is
  /// not the invocation of a named constructor.
  @override
  final Token? period;

  /// The name of the constructor being invoked, or `null` if this annotation is
  /// not the invocation of a named constructor.
  SimpleIdentifierImpl? _constructorName;

  /// The arguments to the constructor being invoked, or `null` if this
  /// annotation is not the invocation of a constructor.
  ArgumentListImpl? _arguments;

  /// The element associated with this annotation, or `null` if the AST
  /// structure has not been resolved or if this annotation could not be
  /// resolved.
  Element? _element;

  /// The element annotation representing this annotation in the element model.
  @override
  ElementAnnotation? elementAnnotation;

  /// Initialize a newly created annotation. Both the [period] and the
  /// [constructorName] can be `null` if the annotation is not referencing a
  /// named constructor. The [arguments] can be `null` if the annotation is not
  /// referencing a constructor.
  ///
  /// Note that type arguments are only valid if [Feature.generic_metadata] is
  /// enabled.
  AnnotationImpl({
    required this.atSign,
    required IdentifierImpl name,
    required TypeArgumentListImpl? typeArguments,
    required this.period,
    required SimpleIdentifierImpl? constructorName,
    required ArgumentListImpl? arguments,
  })  : _name = name,
        _typeArguments = typeArguments,
        _constructorName = constructorName,
        _arguments = arguments {
    _becomeParentOf(_name);
    _becomeParentOf(_typeArguments);
    _becomeParentOf(_constructorName);
    _becomeParentOf(_arguments);
  }

  @override
  ArgumentListImpl? get arguments => _arguments;

  set arguments(ArgumentListImpl? arguments) {
    _arguments = _becomeParentOf(arguments);
  }

  @override
  Token get beginToken => atSign;

  @override
  SimpleIdentifierImpl? get constructorName => _constructorName;

  set constructorName(SimpleIdentifierImpl? name) {
    _constructorName = _becomeParentOf(name);
  }

  @override
  Element? get element {
    if (_element != null) {
      return _element!;
    } else if (_constructorName == null) {
      return _name.staticElement;
    }
    return null;
  }

  set element(Element? element) {
    _element = element;
  }

  @override
  Token get endToken {
    if (_arguments != null) {
      return _arguments!.endToken;
    } else if (_constructorName != null) {
      return _constructorName!.endToken;
    }
    return _name.endToken;
  }

  @override
  IdentifierImpl get name => _name;

  set name(IdentifierImpl name) {
    _name = _becomeParentOf(name)!;
  }

  @override
  AstNode get parent => super.parent!;

  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  /// Sets the type arguments to the constructor being invoked to the given
  /// [typeArguments].
  set typeArguments(TypeArgumentListImpl? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @override
  ChildEntities get _childEntities {
    return ChildEntities()
      ..addToken('atSign', atSign)
      ..addNode('name', name)
      ..addNode('typeArguments', typeArguments)
      ..addToken('period', period)
      ..addNode('constructorName', constructorName)
      ..addNode('arguments', arguments);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAnnotation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _name.accept(visitor);
    _typeArguments?.accept(visitor);
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
abstract final class ArgumentList implements AstNode {
  /// Return the expressions producing the values of the arguments.
  ///
  /// Although the language requires that positional arguments appear before
  /// named arguments, this class allows them to be intermixed.
  NodeList<Expression> get arguments;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the right parenthesis.
  Token get rightParenthesis;
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
final class ArgumentListImpl extends AstNodeImpl implements ArgumentList {
  /// The left parenthesis.
  @override
  final Token leftParenthesis;

  /// The expressions producing the values of the arguments.
  final NodeListImpl<ExpressionImpl> _arguments = NodeListImpl._();

  /// The right parenthesis.
  @override
  final Token rightParenthesis;

  /// A list containing the elements representing the parameters corresponding
  /// to each of the arguments in this list, or `null` if the AST has not been
  /// resolved or if the function or method being invoked could not be
  /// determined based on static type information. The list must be the same
  /// length as the number of arguments, but can contain `null` entries if a
  /// given argument does not correspond to a formal parameter.
  List<ParameterElement?>? _correspondingStaticParameters;

  /// Initialize a newly created list of arguments. The list of [arguments] can
  /// be `null` if there are no arguments.
  ArgumentListImpl({
    required this.leftParenthesis,
    required List<ExpressionImpl> arguments,
    required this.rightParenthesis,
  }) {
    _arguments._initialize(this, arguments);
  }

  @override
  NodeListImpl<ExpressionImpl> get arguments => _arguments;

  @override
  Token get beginToken => leftParenthesis;

  List<ParameterElement?>? get correspondingStaticParameters =>
      _correspondingStaticParameters;

  set correspondingStaticParameters(List<ParameterElement?>? parameters) {
    if (parameters != null && parameters.length != _arguments.length) {
      throw ArgumentError(
          "Expected ${_arguments.length} parameters, not ${parameters.length}");
    }
    _correspondingStaticParameters = parameters;
  }

  @override
  Token get endToken => rightParenthesis;

  @override
  // TODO(paulberry): Add commas.
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNodeList('arguments', arguments)
    ..addToken('rightParenthesis', rightParenthesis);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitArgumentList(this);

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
  ParameterElement? _getStaticParameterElementFor(Expression expression) {
    if (_correspondingStaticParameters == null ||
        _correspondingStaticParameters!.length != _arguments.length) {
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
    return _correspondingStaticParameters![index];
  }
}

/// An as expression.
///
///    asExpression ::=
///        [Expression] 'as' [TypeAnnotation]
abstract final class AsExpression implements Expression {
  /// Return the 'as' operator.
  Token get asOperator;

  /// Return the expression used to compute the value being cast.
  Expression get expression;

  /// Return the type being cast to.
  TypeAnnotation get type;
}

/// An as expression.
///
///    asExpression ::=
///        [Expression] 'as' [NamedType]
final class AsExpressionImpl extends ExpressionImpl implements AsExpression {
  /// The expression used to compute the value being cast.
  ExpressionImpl _expression;

  /// The 'as' operator.
  @override
  final Token asOperator;

  /// The type being cast to.
  TypeAnnotationImpl _type;

  /// Initialize a newly created as expression.
  AsExpressionImpl({
    required ExpressionImpl expression,
    required this.asOperator,
    required TypeAnnotationImpl type,
  })  : _expression = expression,
        _type = type {
    _becomeParentOf(_expression);
    _becomeParentOf(_type);
  }

  @override
  Token get beginToken => _expression.beginToken;

  @override
  Token get endToken => _type.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.relational;

  @override
  TypeAnnotationImpl get type => _type;

  set type(TypeAnnotationImpl type) {
    _type = _becomeParentOf(type);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('expression', expression)
    ..addToken('asOperator', asOperator)
    ..addNode('type', type);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAsExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitAsExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
    _type.accept(visitor);
  }
}

/// An assert in the initializer list of a constructor.
///
///    assertInitializer ::=
///        'assert' '(' [Expression] (',' [Expression])? ')'
abstract final class AssertInitializer
    implements Assertion, ConstructorInitializer {}

/// An assert in the initializer list of a constructor.
///
///    assertInitializer ::=
///        'assert' '(' [Expression] (',' [Expression])? ')'
final class AssertInitializerImpl extends ConstructorInitializerImpl
    implements AssertInitializer {
  @override
  final Token assertKeyword;

  @override
  final Token leftParenthesis;

  /// The condition that is being asserted to be `true`.
  ExpressionImpl _condition;

  @override
  final Token? comma;

  /// The message to report if the assertion fails, or `null` if no message was
  /// supplied.
  ExpressionImpl? _message;

  @override
  final Token rightParenthesis;

  /// Initialize a newly created assert initializer.
  AssertInitializerImpl({
    required this.assertKeyword,
    required this.leftParenthesis,
    required ExpressionImpl condition,
    required this.comma,
    required ExpressionImpl? message,
    required this.rightParenthesis,
  })  : _condition = condition,
        _message = message {
    _becomeParentOf(_condition);
    _becomeParentOf(_message);
  }

  @override
  Token get beginToken => assertKeyword;

  @override
  ExpressionImpl get condition => _condition;

  set condition(ExpressionImpl condition) {
    _condition = _becomeParentOf(condition);
  }

  @override
  Token get endToken => rightParenthesis;

  @override
  ExpressionImpl? get message => _message;

  set message(ExpressionImpl? expression) {
    _message = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('assertKeyword', assertKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('condition', condition)
    ..addToken('comma', comma)
    ..addNode('message', message)
    ..addToken('rightParenthesis', rightParenthesis);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAssertInitializer(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _condition.accept(visitor);
    message?.accept(visitor);
  }
}

/// An assertion, either in a block or in the initializer list of a constructor.
abstract final class Assertion implements AstNode {
  /// Return the token representing the 'assert' keyword.
  Token get assertKeyword;

  /// Return the comma between the [condition] and the [message], or `null` if
  /// no message was supplied.
  Token? get comma;

  /// Return the condition that is being asserted to be `true`.
  Expression get condition;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the message to report if the assertion fails, or `null` if no
  /// message was supplied.
  Expression? get message;

  ///  Return the right parenthesis.
  Token get rightParenthesis;
}

/// An assert statement.
///
///    assertStatement ::=
///        'assert' '(' [Expression] (',' [Expression])? ')' ';'
abstract final class AssertStatement implements Assertion, Statement {
  /// Return the semicolon terminating the statement.
  Token get semicolon;
}

/// An assert statement.
///
///    assertStatement ::=
///        'assert' '(' [Expression] ')' ';'
final class AssertStatementImpl extends StatementImpl
    implements AssertStatement {
  @override
  final Token assertKeyword;

  @override
  final Token leftParenthesis;

  /// The condition that is being asserted to be `true`.
  ExpressionImpl _condition;

  @override
  final Token? comma;

  /// The message to report if the assertion fails, or `null` if no message was
  /// supplied.
  ExpressionImpl? _message;

  @override
  final Token rightParenthesis;

  @override
  final Token semicolon;

  /// Initialize a newly created assert statement.
  AssertStatementImpl({
    required this.assertKeyword,
    required this.leftParenthesis,
    required ExpressionImpl condition,
    required this.comma,
    required ExpressionImpl? message,
    required this.rightParenthesis,
    required this.semicolon,
  })  : _condition = condition,
        _message = message {
    _becomeParentOf(_condition);
    _becomeParentOf(_message);
  }

  @override
  Token get beginToken => assertKeyword;

  @override
  ExpressionImpl get condition => _condition;

  set condition(ExpressionImpl condition) {
    _condition = _becomeParentOf(condition);
  }

  @override
  Token get endToken => semicolon;

  @override
  ExpressionImpl? get message => _message;

  set message(ExpressionImpl? expression) {
    _message = _becomeParentOf(expression as ExpressionImpl);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('assertKeyword', assertKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('condition', condition)
    ..addToken('comma', comma)
    ..addNode('message', message)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAssertStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _condition.accept(visitor);
    message?.accept(visitor);
  }
}

/// A variable pattern in [PatternAssignment].
///
///    variablePattern ::= identifier
abstract final class AssignedVariablePattern implements VariablePattern {
  /// Return the element referenced by this pattern, or `null` if either
  /// [name] does not resolve to an element, or the AST structure has not
  /// been resolved. In valid code this will be either [LocalVariableElement]
  /// or [ParameterElement].
  Element? get element;
}

/// A variable pattern in [PatternAssignment].
///
///    variablePattern ::= identifier
final class AssignedVariablePatternImpl extends VariablePatternImpl
    implements AssignedVariablePattern {
  @override
  Element? element;

  AssignedVariablePatternImpl({
    required super.name,
  });

  @override
  Token get beginToken => name;

  @override
  Token get endToken => name;

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @override
  ChildEntities get _childEntities => ChildEntities()..addToken('name', name);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitAssignedVariablePattern(this);
  }

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    final element = this.element;
    if (element is PromotableElement) {
      return resolverVisitor.analyzeAssignedVariablePatternSchema(element);
    }
    return resolverVisitor.unknownType;
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.resolveAssignedVariablePattern(
      node: this,
      context: context,
    );
  }

  @override
  void visitChildren(AstVisitor visitor) {}
}

/// An assignment expression.
///
///    assignmentExpression ::=
///        [Expression] operator [Expression]
abstract final class AssignmentExpression
    implements
        NullShortableExpression,
        MethodReferenceExpression,
        CompoundAssignmentExpression {
  /// Return the expression used to compute the left hand side.
  Expression get leftHandSide;

  /// Return the assignment operator being applied.
  Token get operator;

  /// Return the expression used to compute the right hand side.
  Expression get rightHandSide;
}

/// An assignment expression.
///
///    assignmentExpression ::=
///        [Expression] operator [Expression]
final class AssignmentExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl, CompoundAssignmentExpressionImpl
    implements AssignmentExpression {
  /// The expression used to compute the left hand side.
  ExpressionImpl _leftHandSide;

  /// The assignment operator being applied.
  @override
  final Token operator;

  /// The expression used to compute the right hand side.
  ExpressionImpl _rightHandSide;

  /// The element associated with the operator based on the static type of the
  /// left-hand-side, or `null` if the AST structure has not been resolved, if
  /// the operator is not a compound operator, or if the operator could not be
  /// resolved.
  @override
  MethodElement? staticElement;

  /// Initialize a newly created assignment expression.
  AssignmentExpressionImpl({
    required ExpressionImpl leftHandSide,
    required this.operator,
    required ExpressionImpl rightHandSide,
  })  : _leftHandSide = leftHandSide,
        _rightHandSide = rightHandSide {
    _becomeParentOf(_leftHandSide);
    _becomeParentOf(_rightHandSide);
  }

  @override
  Token get beginToken => _leftHandSide.beginToken;

  @override
  Token get endToken => _rightHandSide.endToken;

  @override
  ExpressionImpl get leftHandSide => _leftHandSide;

  set leftHandSide(ExpressionImpl expression) {
    _leftHandSide = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.assignment;

  @override
  ExpressionImpl get rightHandSide => _rightHandSide;

  set rightHandSide(ExpressionImpl expression) {
    _rightHandSide = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('leftHandSide', leftHandSide)
    ..addToken('operator', operator)
    ..addNode('rightHandSide', rightHandSide);

  @override
  AstNode? get _nullShortingExtensionCandidate => parent;

  /// If the AST structure has been resolved, and the function being invoked is
  /// known based on static type information, then return the parameter element
  /// representing the parameter to which the value of the right operand will be
  /// bound. Otherwise, return `null`.
  ParameterElement? get _staticParameterElementForRightHandSide {
    Element? executableElement;
    if (operator.type != TokenType.EQ) {
      executableElement = staticElement;
    } else {
      executableElement = writeElement;
    }

    if (executableElement is ExecutableElement) {
      List<ParameterElement> parameters = executableElement.parameters;
      if (parameters.isEmpty) {
        return null;
      }
      if (operator.type == TokenType.EQ && leftHandSide is IndexExpression) {
        return parameters.length == 2 ? parameters[1] : null;
      }
      return parameters[0];
    }

    return null;
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitAssignmentExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitAssignmentExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _leftHandSide.accept(visitor);
    _rightHandSide.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression descendant) =>
      identical(descendant, _leftHandSide);
}

/// A node in the AST structure for a Dart program.
abstract final class AstNode implements SyntacticEntity {
  /// A comparator that can be used to sort AST nodes in lexical order.
  ///
  /// In other words, `compare` will return a negative value if the offset of
  /// the first node is less than the offset of the second node, zero (0) if
  /// the nodes have the same offset, and a positive value if the offset of the
  /// first node is greater than the offset of the second node.
  static Comparator<AstNode> LEXICAL_ORDER =
      (AstNode first, AstNode second) => first.offset - second.offset;

  /// Return the first token included in this node's source range.
  Token get beginToken;

  /// Return an iterator that can be used to iterate through all the entities
  /// (either AST nodes or tokens) that make up the contents of this node,
  /// including doc comments but excluding other comments.
  Iterable<SyntacticEntity> get childEntities;

  /// Return the offset of the character immediately following the last
  /// character of this node's source range.
  ///
  /// This is equivalent to `node.offset + node.length`. For a compilation unit
  /// this will be equal to the length of the unit's source. For synthetic nodes
  /// this will be equivalent to the node's offset (because the length is zero
  /// (0) by definition).
  @override
  int get end;

  /// Return the last token included in this node's source range.
  Token get endToken;

  /// Return `true` if this node is a synthetic node.
  ///
  /// A synthetic node is a node that was introduced by the parser in order to
  /// recover from an error in the code. Synthetic nodes always have a length
  /// of zero (`0`).
  bool get isSynthetic;

  @override
  int get length;

  @override
  int get offset;

  /// Return this node's parent node, or `null` if this node is the root of an
  /// AST structure.
  ///
  /// Note that the relationship between an AST node and its parent node may
  /// change over the lifetime of a node.
  AstNode? get parent;

  /// Return the node at the root of this node's AST structure.
  ///
  /// Note that this method's performance is linear with respect to the depth
  /// of the node in the AST structure (O(depth)).
  AstNode get root;

  /// Use the given [visitor] to visit this node.
  ///
  /// Return the value returned by the visitor as a result of visiting this
  /// node.
  E? accept<E>(AstVisitor<E> visitor);

  /// Return the token before [target] or `null` if it cannot be found.
  Token? findPrevious(Token target);

  /// Return the value of the property with the given [name], or `null` if this
  /// node does not have a property with the given name.
  E? getProperty<E>(String name);

  /// Set the value of the property with the given [name] to the given [value].
  /// If the value is `null`, the property will effectively be removed.
  void setProperty(String name, Object? value);

  /// Return either this node or the most immediate ancestor of this node for
  /// which the [predicate] returns `true`, or `null` if there is no such node.
  E? thisOrAncestorMatching<E extends AstNode>(
    bool Function(AstNode) predicate,
  );

  /// Return either this node or the most immediate ancestor of this node that
  /// has the given type, or `null` if there is no such node.
  E? thisOrAncestorOfType<E extends AstNode>();

  /// Return a textual description of this node in a form approximating valid
  /// source.
  ///
  /// The returned string will not be valid source primarily in the case where
  /// the node itself is not well-formed.
  String toSource();

  /// Use the given [visitor] to visit all of the children of this node.
  ///
  /// The children will be visited in lexical order.
  void visitChildren(AstVisitor visitor);
}

/// A node in the AST structure for a Dart program.
sealed class AstNodeImpl implements AstNode {
  /// The parent of the node, or `null` if the node is the root of an AST
  /// structure.
  AstNode? _parent;

  /// A table mapping the names of properties to their values, or `null` if this
  /// node does not have any properties associated with it.
  Map<String, Object>? _propertyMap;

  @override
  Iterable<SyntacticEntity> get childEntities =>
      _childEntities.syntacticEntities;

  @override
  int get end => offset + length;

  @override
  bool get isSynthetic => false;

  @override
  int get length {
    final beginToken = this.beginToken;
    final endToken = this.endToken;
    return endToken.offset + endToken.length - beginToken.offset;
  }

  /// Return properties (tokens and nodes) of this node, with names, in the
  /// order in which these entities should normally appear, not necessary in
  /// the order they really are (because of recovery).
  Iterable<ChildEntity> get namedChildEntities => _childEntities.entities;

  @override
  int get offset {
    final beginToken = this.beginToken;
    return beginToken.offset;
  }

  @override
  AstNode? get parent => _parent;

  @override
  AstNode get root {
    AstNode root = this;
    var rootParent = parent;
    while (rootParent != null) {
      root = rootParent;
      rootParent = root.parent;
    }
    return root;
  }

  ChildEntities get _childEntities => ChildEntities();

  void detachFromParent() {
    _parent = null;
  }

  @override
  Token? findPrevious(Token target) =>
      util.findPrevious(beginToken, target) ?? parent?.findPrevious(target);

  @override
  E? getProperty<E>(String name) {
    return _propertyMap?[name] as E?;
  }

  @override
  void setProperty(String name, Object? value) {
    if (value == null) {
      final propertyMap = _propertyMap;
      if (propertyMap != null) {
        propertyMap.remove(name);
        if (propertyMap.isEmpty) {
          _propertyMap = null;
        }
      }
    } else {
      (_propertyMap ??= HashMap<String, Object>())[name] = value;
    }
  }

  @override
  E? thisOrAncestorMatching<E extends AstNode>(
    bool Function(AstNode) predicate,
  ) {
    AstNode? node = this;
    while (node != null && !predicate(node)) {
      node = node.parent;
    }
    return node as E?;
  }

  @override
  E? thisOrAncestorOfType<E extends AstNode>() {
    AstNode? node = this;
    while (node != null && node is! E) {
      node = node.parent;
    }
    return node as E?;
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
  T _becomeParentOf<T extends AstNodeImpl?>(T child) {
    child?._parent = this;
    return child;
  }
}

/// An object that can be used to visit an AST structure.
///
/// Clients may not extend, implement or mix-in this class. There are classes
/// that implement this interface that provide useful default behaviors in
/// `package:analyzer/dart/ast/visitor.dart`. A couple of the most useful
/// include
/// * SimpleAstVisitor which implements every visit method by doing nothing,
/// * RecursiveAstVisitor which will cause every node in a structure to be
///   visited, and
/// * ThrowingAstVisitor which implements every visit method by throwing an
///   exception.
abstract class AstVisitor<R> {
  R? visitAdjacentStrings(AdjacentStrings node);

  R? visitAnnotation(Annotation node);

  R? visitArgumentList(ArgumentList node);

  R? visitAsExpression(AsExpression node);

  R? visitAssertInitializer(AssertInitializer node);

  R? visitAssertStatement(AssertStatement assertStatement);

  R? visitAssignedVariablePattern(AssignedVariablePattern node);

  R? visitAssignmentExpression(AssignmentExpression node);

  R? visitAugmentationImportDirective(AugmentationImportDirective node);

  R? visitAwaitExpression(AwaitExpression node);

  R? visitBinaryExpression(BinaryExpression node);

  R? visitBlock(Block node);

  R? visitBlockFunctionBody(BlockFunctionBody node);

  R? visitBooleanLiteral(BooleanLiteral node);

  R? visitBreakStatement(BreakStatement node);

  R? visitCascadeExpression(CascadeExpression node);

  R? visitCaseClause(CaseClause node);

  R? visitCastPattern(CastPattern node);

  R? visitCatchClause(CatchClause node);

  R? visitCatchClauseParameter(CatchClauseParameter node);

  R? visitClassAugmentationDeclaration(ClassAugmentationDeclaration node);

  R? visitClassDeclaration(ClassDeclaration node);

  R? visitClassTypeAlias(ClassTypeAlias node);

  R? visitComment(Comment node);

  R? visitCommentReference(CommentReference node);

  R? visitCompilationUnit(CompilationUnit node);

  R? visitConditionalExpression(ConditionalExpression node);

  R? visitConfiguration(Configuration node);

  R? visitConstantPattern(ConstantPattern node);

  R? visitConstructorDeclaration(ConstructorDeclaration node);

  R? visitConstructorFieldInitializer(ConstructorFieldInitializer node);

  R? visitConstructorName(ConstructorName node);

  R? visitConstructorReference(ConstructorReference node);

  R? visitConstructorSelector(ConstructorSelector node);

  R? visitContinueStatement(ContinueStatement node);

  R? visitDeclaredIdentifier(DeclaredIdentifier node);

  R? visitDeclaredVariablePattern(DeclaredVariablePattern node);

  R? visitDefaultFormalParameter(DefaultFormalParameter node);

  R? visitDoStatement(DoStatement node);

  R? visitDottedName(DottedName node);

  R? visitDoubleLiteral(DoubleLiteral node);

  R? visitEmptyFunctionBody(EmptyFunctionBody node);

  R? visitEmptyStatement(EmptyStatement node);

  R? visitEnumConstantArguments(EnumConstantArguments node);

  R? visitEnumConstantDeclaration(EnumConstantDeclaration node);

  R? visitEnumDeclaration(EnumDeclaration node);

  R? visitExportDirective(ExportDirective node);

  R? visitExpressionFunctionBody(ExpressionFunctionBody node);

  R? visitExpressionStatement(ExpressionStatement node);

  R? visitExtendsClause(ExtendsClause node);

  R? visitExtensionDeclaration(ExtensionDeclaration node);

  R? visitExtensionOverride(ExtensionOverride node);

  R? visitFieldDeclaration(FieldDeclaration node);

  R? visitFieldFormalParameter(FieldFormalParameter node);

  R? visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node);

  R? visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node);

  R? visitForEachPartsWithPattern(ForEachPartsWithPattern node);

  R? visitForElement(ForElement node);

  R? visitFormalParameterList(FormalParameterList node);

  R? visitForPartsWithDeclarations(ForPartsWithDeclarations node);

  R? visitForPartsWithExpression(ForPartsWithExpression node);

  R? visitForPartsWithPattern(ForPartsWithPattern node);

  R? visitForStatement(ForStatement node);

  R? visitFunctionDeclaration(FunctionDeclaration node);

  R? visitFunctionDeclarationStatement(FunctionDeclarationStatement node);

  R? visitFunctionExpression(FunctionExpression node);

  R? visitFunctionExpressionInvocation(FunctionExpressionInvocation node);

  R? visitFunctionReference(FunctionReference node);

  R? visitFunctionTypeAlias(FunctionTypeAlias functionTypeAlias);

  R? visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node);

  R? visitGenericFunctionType(GenericFunctionType node);

  R? visitGenericTypeAlias(GenericTypeAlias node);

  R? visitGuardedPattern(GuardedPattern node);

  R? visitHideCombinator(HideCombinator node);

  R? visitIfElement(IfElement node);

  R? visitIfStatement(IfStatement node);

  R? visitImplementsClause(ImplementsClause node);

  R? visitImplicitCallReference(ImplicitCallReference node);

  R? visitImportDirective(ImportDirective node);

  R? visitImportPrefixReference(ImportPrefixReference node);

  R? visitIndexExpression(IndexExpression node);

  R? visitInstanceCreationExpression(InstanceCreationExpression node);

  R? visitIntegerLiteral(IntegerLiteral node);

  R? visitInterpolationExpression(InterpolationExpression node);

  R? visitInterpolationString(InterpolationString node);

  R? visitIsExpression(IsExpression node);

  R? visitLabel(Label node);

  R? visitLabeledStatement(LabeledStatement node);

  R? visitLibraryAugmentationDirective(LibraryAugmentationDirective node);

  R? visitLibraryDirective(LibraryDirective node);

  R? visitLibraryIdentifier(LibraryIdentifier node);

  R? visitListLiteral(ListLiteral node);

  R? visitListPattern(ListPattern node);

  R? visitLogicalAndPattern(LogicalAndPattern node);

  R? visitLogicalOrPattern(LogicalOrPattern node);

  R? visitMapLiteralEntry(MapLiteralEntry node);

  R? visitMapPattern(MapPattern node);

  R? visitMapPatternEntry(MapPatternEntry node);

  R? visitMethodDeclaration(MethodDeclaration node);

  R? visitMethodInvocation(MethodInvocation node);

  R? visitMixinAugmentationDeclaration(MixinAugmentationDeclaration node);

  R? visitMixinDeclaration(MixinDeclaration node);

  R? visitNamedExpression(NamedExpression node);

  R? visitNamedType(NamedType node);

  R? visitNativeClause(NativeClause node);

  R? visitNativeFunctionBody(NativeFunctionBody node);

  R? visitNullAssertPattern(NullAssertPattern node);

  R? visitNullCheckPattern(NullCheckPattern node);

  R? visitNullLiteral(NullLiteral node);

  R? visitObjectPattern(ObjectPattern node);

  R? visitOnClause(OnClause node);

  R? visitParenthesizedExpression(ParenthesizedExpression node);

  R? visitParenthesizedPattern(ParenthesizedPattern node);

  R? visitPartDirective(PartDirective node);

  R? visitPartOfDirective(PartOfDirective node);

  R? visitPatternAssignment(PatternAssignment node);

  R? visitPatternField(PatternField node);

  R? visitPatternFieldName(PatternFieldName node);

  R? visitPatternVariableDeclaration(PatternVariableDeclaration node);

  R? visitPatternVariableDeclarationStatement(
      PatternVariableDeclarationStatement node);

  R? visitPostfixExpression(PostfixExpression node);

  R? visitPrefixedIdentifier(PrefixedIdentifier node);

  R? visitPrefixExpression(PrefixExpression node);

  R? visitPropertyAccess(PropertyAccess node);

  R? visitRecordLiteral(RecordLiteral node);

  R? visitRecordPattern(RecordPattern node);

  R? visitRecordTypeAnnotation(RecordTypeAnnotation node);

  R? visitRecordTypeAnnotationNamedField(RecordTypeAnnotationNamedField node);

  R? visitRecordTypeAnnotationNamedFields(RecordTypeAnnotationNamedFields node);

  R? visitRecordTypeAnnotationPositionalField(
      RecordTypeAnnotationPositionalField node);

  R? visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node);

  R? visitRelationalPattern(RelationalPattern node);

  R? visitRestPatternElement(RestPatternElement node);

  R? visitRethrowExpression(RethrowExpression node);

  R? visitReturnStatement(ReturnStatement node);

  R? visitScriptTag(ScriptTag node);

  R? visitSetOrMapLiteral(SetOrMapLiteral node);

  R? visitShowCombinator(ShowCombinator node);

  R? visitSimpleFormalParameter(SimpleFormalParameter node);

  R? visitSimpleIdentifier(SimpleIdentifier node);

  R? visitSimpleStringLiteral(SimpleStringLiteral node);

  R? visitSpreadElement(SpreadElement node);

  R? visitStringInterpolation(StringInterpolation node);

  R? visitSuperConstructorInvocation(SuperConstructorInvocation node);

  R? visitSuperExpression(SuperExpression node);

  R? visitSuperFormalParameter(SuperFormalParameter node);

  R? visitSwitchCase(SwitchCase node);

  R? visitSwitchDefault(SwitchDefault node);

  R? visitSwitchExpression(SwitchExpression node);

  R? visitSwitchExpressionCase(SwitchExpressionCase node);

  R? visitSwitchPatternCase(SwitchPatternCase node);

  R? visitSwitchStatement(SwitchStatement node);

  R? visitSymbolLiteral(SymbolLiteral node);

  R? visitThisExpression(ThisExpression node);

  R? visitThrowExpression(ThrowExpression node);

  R? visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node);

  R? visitTryStatement(TryStatement node);

  R? visitTypeArgumentList(TypeArgumentList node);

  R? visitTypeLiteral(TypeLiteral node);

  R? visitTypeParameter(TypeParameter node);

  R? visitTypeParameterList(TypeParameterList node);

  R? visitVariableDeclaration(VariableDeclaration node);

  R? visitVariableDeclarationList(VariableDeclarationList node);

  R? visitVariableDeclarationStatement(VariableDeclarationStatement node);

  R? visitWhenClause(WhenClause node);

  R? visitWhileStatement(WhileStatement node);

  R? visitWildcardPattern(WildcardPattern node);

  R? visitWithClause(WithClause node);

  R? visitYieldStatement(YieldStatement node);
}

/// An augmentation import directive.
///
///    importDirective ::=
///        [Annotation] 'import' 'augment' [StringLiteral] ';'
@experimental
abstract final class AugmentationImportDirective implements UriBasedDirective {
  /// The token representing the 'augment' keyword.
  Token get augmentKeyword;

  @override
  AugmentationImportElement? get element;

  /// The token representing the 'import' keyword.
  Token get importKeyword;

  /// Return the semicolon terminating the directive.
  Token get semicolon;
}

/// An augmentation import directive.
///
///    importDirective ::=
///        [Annotation] 'import' 'augment' [StringLiteral] ';'
final class AugmentationImportDirectiveImpl extends UriBasedDirectiveImpl
    implements AugmentationImportDirective {
  @override
  final Token importKeyword;

  @override
  final Token augmentKeyword;

  @override
  final Token semicolon;

  AugmentationImportDirectiveImpl({
    required super.comment,
    required super.metadata,
    required this.importKeyword,
    required this.augmentKeyword,
    required this.semicolon,
    required super.uri,
  }) {
    _becomeParentOf(_uri);
  }

  @override
  AugmentationImportElementImpl? get element {
    return super.element as AugmentationImportElementImpl?;
  }

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => importKeyword;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('importKeyword', importKeyword)
    ..addToken('augmentKeyword', augmentKeyword)
    ..addNode('uri', uri)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitAugmentationImportDirective(this);
  }
}

/// An await expression.
///
///    awaitExpression ::=
///        'await' [Expression]
abstract final class AwaitExpression implements Expression {
  /// Return the 'await' keyword.
  Token get awaitKeyword;

  /// Return the expression whose value is being waited on.
  Expression get expression;
}

/// An await expression.
///
///    awaitExpression ::=
///        'await' [Expression]
final class AwaitExpressionImpl extends ExpressionImpl
    implements AwaitExpression {
  /// The 'await' keyword.
  @override
  final Token awaitKeyword;

  /// The expression whose value is being waited on.
  ExpressionImpl _expression;

  /// Initialize a newly created await expression.
  AwaitExpressionImpl({
    required this.awaitKeyword,
    required ExpressionImpl expression,
  }) : _expression = expression {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken {
    return awaitKeyword;
  }

  @override
  Token get endToken => _expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.prefix;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('awaitKeyword', awaitKeyword)
    ..addNode('expression', expression);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAwaitExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitAwaitExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
  }
}

/// A binary (infix) expression.
///
///    binaryExpression ::=
///        [Expression] [Token] [Expression]
abstract final class BinaryExpression
    implements Expression, MethodReferenceExpression {
  /// Return the expression used to compute the left operand.
  Expression get leftOperand;

  /// Return the binary operator being applied.
  Token get operator;

  /// Return the expression used to compute the right operand.
  Expression get rightOperand;

  /// The function type of the invocation, or `null` if the AST structure has
  /// not been resolved, or if the invocation could not be resolved.
  FunctionType? get staticInvokeType;
}

/// A binary (infix) expression.
///
///    binaryExpression ::=
///        [Expression] [Token] [Expression]
final class BinaryExpressionImpl extends ExpressionImpl
    implements BinaryExpression {
  /// The expression used to compute the left operand.
  ExpressionImpl _leftOperand;

  /// The binary operator being applied.
  @override
  final Token operator;

  /// The expression used to compute the right operand.
  ExpressionImpl _rightOperand;

  /// The element associated with the operator based on the static type of the
  /// left operand, or `null` if the AST structure has not been resolved, if the
  /// operator is not user definable, or if the operator could not be resolved.
  @override
  MethodElement? staticElement;

  @override
  FunctionType? staticInvokeType;

  /// Initialize a newly created binary expression.
  BinaryExpressionImpl({
    required ExpressionImpl leftOperand,
    required this.operator,
    required ExpressionImpl rightOperand,
  })  : _leftOperand = leftOperand,
        _rightOperand = rightOperand {
    _becomeParentOf(leftOperand);
    _becomeParentOf(rightOperand);
  }

  @override
  Token get beginToken => _leftOperand.beginToken;

  @override
  Token get endToken => _rightOperand.endToken;

  @override
  ExpressionImpl get leftOperand => _leftOperand;

  set leftOperand(ExpressionImpl expression) {
    _leftOperand = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.forTokenType(operator.type);

  @override
  ExpressionImpl get rightOperand => _rightOperand;

  set rightOperand(ExpressionImpl expression) {
    _rightOperand = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('leftOperand', leftOperand)
    ..addToken('operator', operator)
    ..addNode('rightOperand', rightOperand);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitBinaryExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitBinaryExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _leftOperand.accept(visitor);
    _rightOperand.accept(visitor);
  }
}

/// A sequence of statements.
///
///    block ::=
///        '{' statement* '}'
abstract final class Block implements Statement {
  /// Return the left curly bracket.
  Token get leftBracket;

  /// Return the right curly bracket.
  Token get rightBracket;

  /// Return the statements contained in the block.
  NodeList<Statement> get statements;
}

/// A function body that consists of a block of statements.
///
///    blockFunctionBody ::=
///        ('async' | 'async' '*' | 'sync' '*')? [Block]
abstract final class BlockFunctionBody implements FunctionBody {
  /// Return the block representing the body of the function.
  Block get block;
}

/// A function body that consists of a block of statements.
///
///    blockFunctionBody ::=
///        ('async' | 'async' '*' | 'sync' '*')? [Block]
final class BlockFunctionBodyImpl extends FunctionBodyImpl
    implements BlockFunctionBody {
  /// The token representing the 'async' or 'sync' keyword, or `null` if there
  /// is no such keyword.
  @override
  final Token? keyword;

  /// The star optionally following the 'async' or 'sync' keyword, or `null` if
  /// there is wither no such keyword or no star.
  @override
  final Token? star;

  /// The block representing the body of the function.
  BlockImpl _block;

  /// Initialize a newly created function body consisting of a block of
  /// statements. The [keyword] can be `null` if there is no keyword specified
  /// for the block. The [star] can be `null` if there is no star following the
  /// keyword (and must be `null` if there is no keyword).
  BlockFunctionBodyImpl({
    required this.keyword,
    required this.star,
    required BlockImpl block,
  }) : _block = block {
    _becomeParentOf(_block);
  }

  @override
  Token get beginToken {
    if (keyword != null) {
      return keyword!;
    }
    return _block.beginToken;
  }

  @override
  BlockImpl get block => _block;

  set block(BlockImpl block) {
    _block = _becomeParentOf(block);
  }

  @override
  Token get endToken => _block.endToken;

  @override
  bool get isAsynchronous => keyword?.lexeme == Keyword.ASYNC.lexeme;

  @override
  bool get isGenerator => star != null;

  @override
  bool get isSynchronous => keyword?.lexeme != Keyword.ASYNC.lexeme;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('keyword', keyword)
    ..addToken('star', star)
    ..addNode('block', block);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitBlockFunctionBody(this);

  @override
  DartType resolve(ResolverVisitor resolver, DartType? imposedType) =>
      resolver.visitBlockFunctionBody(this, imposedType: imposedType);

  @override
  void visitChildren(AstVisitor visitor) {
    _block.accept(visitor);
  }
}

/// A sequence of statements.
///
///    block ::=
///        '{' statement* '}'
final class BlockImpl extends StatementImpl implements Block {
  /// The left curly bracket.
  @override
  final Token leftBracket;

  /// The statements contained in the block.
  final NodeListImpl<StatementImpl> _statements = NodeListImpl._();

  /// The right curly bracket.
  @override
  final Token rightBracket;

  /// Initialize a newly created block of code.
  BlockImpl({
    required this.leftBracket,
    required List<StatementImpl> statements,
    required this.rightBracket,
  }) {
    _statements._initialize(this, statements);
  }

  @override
  Token get beginToken => leftBracket;

  @override
  Token get endToken => rightBracket;

  @override
  NodeListImpl<StatementImpl> get statements => _statements;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('statements', statements)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitBlock(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _statements.accept(visitor);
  }
}

/// A boolean literal expression.
///
///    booleanLiteral ::=
///        'false' | 'true'
abstract final class BooleanLiteral implements Literal {
  /// Return the token representing the literal.
  Token get literal;

  /// Return the value of the literal.
  bool get value;
}

/// A boolean literal expression.
///
///    booleanLiteral ::=
///        'false' | 'true'
final class BooleanLiteralImpl extends LiteralImpl implements BooleanLiteral {
  /// The token representing the literal.
  @override
  final Token literal;

  /// The value of the literal.
  @override
  final bool value;

  /// Initialize a newly created boolean literal.
  BooleanLiteralImpl({
    required this.literal,
    required this.value,
  });

  @override
  Token get beginToken => literal;

  @override
  Token get endToken => literal;

  @override
  bool get isSynthetic => literal.isSynthetic;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('literal', literal);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitBooleanLiteral(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitBooleanLiteral(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// A break statement.
///
///    breakStatement ::=
///        'break' [SimpleIdentifier]? ';'
abstract final class BreakStatement implements Statement {
  /// Return the token representing the 'break' keyword.
  Token get breakKeyword;

  /// Return the label associated with the statement, or `null` if there is no
  /// label.
  SimpleIdentifier? get label;

  /// Return the semicolon terminating the statement.
  Token get semicolon;

  /// Return the node from which this break statement is breaking.
  ///
  /// This will be either a [Statement] (in the case of breaking out of a
  /// loop), a [SwitchMember] (in the case of a labeled break statement whose
  /// label matches a label on a switch case in an enclosing switch statement),
  /// or `null` if the AST has not yet been resolved or if the target could not
  /// be resolved. Note that if the source code has errors, the target might be
  /// invalid (e.g. trying to break to a switch case).
  AstNode? get target;
}

/// A break statement.
///
///    breakStatement ::=
///        'break' [SimpleIdentifier]? ';'
final class BreakStatementImpl extends StatementImpl implements BreakStatement {
  /// The token representing the 'break' keyword.
  @override
  final Token breakKeyword;

  /// The label associated with the statement, or `null` if there is no label.
  SimpleIdentifierImpl? _label;

  /// The semicolon terminating the statement.
  @override
  final Token semicolon;

  /// The AstNode which this break statement is breaking from.  This will be
  /// either a [Statement] (in the case of breaking out of a loop), a
  /// [SwitchMember] (in the case of a labeled break statement whose label
  /// matches a label on a switch case in an enclosing switch statement), or
  /// `null` if the AST has not yet been resolved or if the target could not be
  /// resolved. Note that if the source code has errors, the target might be
  /// invalid (e.g. trying to break to a switch case).
  @override
  AstNode? target;

  /// Initialize a newly created break statement. The [label] can be `null` if
  /// there is no label associated with the statement.
  BreakStatementImpl({
    required this.breakKeyword,
    required SimpleIdentifierImpl? label,
    required this.semicolon,
  }) : _label = label {
    _becomeParentOf(_label);
  }

  @override
  Token get beginToken => breakKeyword;

  @override
  Token get endToken => semicolon;

  @override
  SimpleIdentifierImpl? get label => _label;

  set label(SimpleIdentifierImpl? identifier) {
    _label = _becomeParentOf(identifier);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('breakKeyword', breakKeyword)
    ..addNode('label', label)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitBreakStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _label?.accept(visitor);
  }
}

/// A sequence of cascaded expressions: expressions that share a common target.
///
/// There are three kinds of expressions that can be used in a cascade
/// expression: [IndexExpression], [MethodInvocation] and [PropertyAccess].
///
///    cascadeExpression ::=
///        [Expression] cascadeSection*
///
///    cascadeSection ::=
///        ('..' | '?..') (cascadeSelector arguments*)
///        (assignableSelector arguments*)*
///        (assignmentOperator expressionWithoutCascade)?
///
///    cascadeSelector ::=
///        '[ ' expression '] '
///      | identifier
abstract final class CascadeExpression
    implements Expression, NullShortableExpression {
  /// Return the cascade sections sharing the common target.
  NodeList<Expression> get cascadeSections;

  /// Whether this cascade is null aware (as opposed to non-null).
  bool get isNullAware;

  /// Return the target of the cascade sections.
  Expression get target;
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
final class CascadeExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl
    implements CascadeExpression {
  /// The target of the cascade sections.
  ExpressionImpl _target;

  /// The cascade sections sharing the common target.
  final NodeListImpl<ExpressionImpl> _cascadeSections = NodeListImpl._();

  /// Initialize a newly created cascade expression. The list of
  /// [cascadeSections] must contain at least one element.
  CascadeExpressionImpl({
    required ExpressionImpl target,
    required List<ExpressionImpl> cascadeSections,
  }) : _target = target {
    _becomeParentOf(_target);
    _cascadeSections._initialize(this, cascadeSections);
  }

  @override
  Token get beginToken => _target.beginToken;

  @override
  NodeListImpl<ExpressionImpl> get cascadeSections => _cascadeSections;

  @override
  Token get endToken => _cascadeSections.endToken!;

  @override
  bool get isNullAware {
    return target.endToken.next!.type == TokenType.QUESTION_PERIOD_PERIOD;
  }

  @override
  Precedence get precedence => Precedence.cascade;

  @override
  ExpressionImpl get target => _target;

  set target(ExpressionImpl target) {
    _target = _becomeParentOf(target);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('target', target)
    ..addNodeList('cascadeSections', cascadeSections);

  @override
  AstNode? get _nullShortingExtensionCandidate => null;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitCascadeExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitCascadeExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _target.accept(visitor);
    _cascadeSections.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression descendant) {
    return _cascadeSections.contains(descendant);
  }
}

/// The `case` clause that can optionally appear in an `if` statement.
///
///    caseClause ::=
///        'case' [GuardedPattern]
abstract final class CaseClause implements AstNode {
  /// Return the token representing the 'case' keyword.
  Token get caseKeyword;

  /// Return the pattern controlling whether the statements will be executed.
  GuardedPattern get guardedPattern;
}

/// The `case` clause that can optionally appear in an `if` statement.
///
///    caseClause ::=
///        'case' [DartPattern] [WhenClause]?
final class CaseClauseImpl extends AstNodeImpl implements CaseClause {
  @override
  final Token caseKeyword;

  @override
  final GuardedPatternImpl guardedPattern;

  CaseClauseImpl({
    required this.caseKeyword,
    required this.guardedPattern,
  }) {
    _becomeParentOf(guardedPattern);
  }

  @override
  Token get beginToken => caseKeyword;

  @override
  Token get endToken => guardedPattern.endToken;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('caseKeyword', caseKeyword)
    ..addNode('guardedPattern', guardedPattern);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitCaseClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    guardedPattern.accept(visitor);
  }
}

/// A cast pattern.
///
///    castPattern ::=
///        [DartPattern] 'as' [TypeAnnotation]
abstract final class CastPattern implements DartPattern {
  /// The `as` token.
  Token get asToken;

  /// The pattern whose matched value will be cast.
  DartPattern get pattern;

  /// The type that the value being matched is cast to.
  TypeAnnotation get type;
}

/// A cast pattern.
///
///    castPattern ::=
///        [DartPattern] 'as' [TypeAnnotation]
final class CastPatternImpl extends DartPatternImpl implements CastPattern {
  @override
  final Token asToken;

  @override
  final DartPatternImpl pattern;

  @override
  final TypeAnnotationImpl type;

  CastPatternImpl({
    required this.pattern,
    required this.asToken,
    required this.type,
  }) {
    _becomeParentOf(pattern);
    _becomeParentOf(type);
  }

  @override
  Token get beginToken => pattern.beginToken;

  @override
  Token get endToken => type.endToken;

  @override
  PatternPrecedence get precedence => PatternPrecedence.postfix;

  @override
  VariablePatternImpl? get variablePattern => pattern.variablePattern;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('pattern', pattern)
    ..addToken('asToken', asToken)
    ..addNode('type', type);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitCastPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor.analyzeCastPatternSchema();
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    type.accept(resolverVisitor);
    final requiredType = type.typeOrThrow;

    resolverVisitor.analyzeCastPattern(
      context: context,
      pattern: this,
      innerPattern: pattern,
      requiredType: requiredType,
    );

    resolverVisitor.checkPatternNeverMatchesValueType(
      context: context,
      pattern: this,
      requiredType: requiredType,
    );
  }

  @override
  void visitChildren(AstVisitor visitor) {
    pattern.accept(visitor);
    type.accept(visitor);
  }
}

/// A catch clause within a try statement.
///
///    onPart ::=
///        catchPart [Block]
///      | 'on' type catchPart? [Block]
///
///    catchPart ::=
///        'catch' '(' [CatchClauseParameter] (',' [CatchClauseParameter])? ')'
abstract final class CatchClause implements AstNode {
  /// Return the body of the catch block.
  Block get body;

  /// Return the token representing the 'catch' keyword, or `null` if there is
  /// no 'catch' keyword.
  Token? get catchKeyword;

  /// Return the comma separating the exception parameter from the stack trace
  /// parameter, or `null` if there is no stack trace parameter.
  Token? get comma;

  /// Return the parameter whose value will be the exception that was thrown, or
  /// `null` if there is no 'catch' keyword.
  CatchClauseParameter? get exceptionParameter;

  /// Return the type of exceptions caught by this catch clause, or `null` if
  /// this catch clause catches every type of exception.
  TypeAnnotation? get exceptionType;

  /// Return the left parenthesis, or `null` if there is no 'catch' keyword.
  Token? get leftParenthesis;

  /// Return the token representing the 'on' keyword, or `null` if there is no
  /// 'on' keyword.
  Token? get onKeyword;

  /// Return the right parenthesis, or `null` if there is no 'catch' keyword.
  Token? get rightParenthesis;

  /// Return the parameter whose value will be the stack trace associated with
  /// the exception, or `null` if there is no stack trace parameter.
  CatchClauseParameter? get stackTraceParameter;
}

/// A catch clause within a try statement.
///
///    onPart ::=
///        catchPart [Block]
///      | 'on' type catchPart? [Block]
///
///    catchPart ::=
///        'catch' '(' [SimpleIdentifier] (',' [SimpleIdentifier])? ')'
final class CatchClauseImpl extends AstNodeImpl implements CatchClause {
  /// The token representing the 'on' keyword, or `null` if there is no 'on'
  /// keyword.
  @override
  final Token? onKeyword;

  /// The type of exceptions caught by this catch clause, or `null` if this
  /// catch clause catches every type of exception.
  TypeAnnotationImpl? _exceptionType;

  /// The token representing the 'catch' keyword, or `null` if there is no
  /// 'catch' keyword.
  @override
  final Token? catchKeyword;

  /// The left parenthesis, or `null` if there is no 'catch' keyword.
  @override
  final Token? leftParenthesis;

  /// The parameter whose value will be the exception that was thrown, or `null`
  /// if there is no 'catch' keyword.
  CatchClauseParameterImpl? _exceptionParameter;

  /// The comma separating the exception parameter from the stack trace
  /// parameter, or `null` if there is no stack trace parameter.
  @override
  final Token? comma;

  /// The parameter whose value will be the stack trace associated with the
  /// exception, or `null` if there is no stack trace parameter.
  CatchClauseParameterImpl? _stackTraceParameter;

  /// The right parenthesis, or `null` if there is no 'catch' keyword.
  @override
  final Token? rightParenthesis;

  /// The body of the catch block.
  BlockImpl _body;

  /// Initialize a newly created catch clause. The [onKeyword] and
  /// [exceptionType] can be `null` if the clause will catch all exceptions. The
  /// [comma] and [_stackTraceParameter] can be `null` if the stack trace
  /// parameter is not defined.
  CatchClauseImpl({
    required this.onKeyword,
    required TypeAnnotationImpl? exceptionType,
    required this.catchKeyword,
    required this.leftParenthesis,
    required CatchClauseParameterImpl? exceptionParameter,
    required this.comma,
    required CatchClauseParameterImpl? stackTraceParameter,
    required this.rightParenthesis,
    required BlockImpl body,
  })  : assert(onKeyword != null || catchKeyword != null),
        _exceptionType = exceptionType,
        _exceptionParameter = exceptionParameter,
        _stackTraceParameter = stackTraceParameter,
        _body = body {
    _becomeParentOf(_exceptionType);
    _becomeParentOf(_exceptionParameter);
    _becomeParentOf(_stackTraceParameter);
    _becomeParentOf(_body);
  }

  @override
  Token get beginToken {
    if (onKeyword != null) {
      return onKeyword!;
    }
    return catchKeyword!;
  }

  @override
  BlockImpl get body => _body;

  set body(BlockImpl block) {
    _body = _becomeParentOf(block);
  }

  @override
  Token get endToken => _body.endToken;

  @override
  CatchClauseParameterImpl? get exceptionParameter {
    return _exceptionParameter;
  }

  set exceptionParameter(CatchClauseParameterImpl? parameter) {
    _exceptionParameter = parameter;
    _becomeParentOf(parameter);
  }

  @override
  TypeAnnotationImpl? get exceptionType => _exceptionType;

  set exceptionType(TypeAnnotationImpl? exceptionType) {
    _exceptionType = _becomeParentOf(exceptionType);
  }

  @override
  CatchClauseParameterImpl? get stackTraceParameter {
    return _stackTraceParameter;
  }

  set stackTraceParameter(CatchClauseParameterImpl? parameter) {
    _stackTraceParameter = parameter;
    _becomeParentOf(parameter);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('onKeyword', onKeyword)
    ..addNode('exceptionType', exceptionType)
    ..addToken('catchKeyword', catchKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('exceptionParameter', exceptionParameter)
    ..addToken('comma', comma)
    ..addNode('stackTraceParameter', stackTraceParameter)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addNode('body', body);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitCatchClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _exceptionType?.accept(visitor);
    _exceptionParameter?.accept(visitor);
    _stackTraceParameter?.accept(visitor);
    _body.accept(visitor);
  }
}

/// The 'exception' or 'stackTrace' parameter in [CatchClause].
abstract final class CatchClauseParameter extends AstNode {
  /// The declared element, or `null` if the AST has not been resolved.
  LocalVariableElement? get declaredElement;

  /// The name of the parameter.
  Token get name;
}

final class CatchClauseParameterImpl extends AstNodeImpl
    implements CatchClauseParameter {
  @override
  final Token name;

  @override
  LocalVariableElementImpl? declaredElement;

  CatchClauseParameterImpl({
    required this.name,
  });

  @override
  Token get beginToken => name;

  @override
  Token get endToken => name;

  @override
  ChildEntities get _childEntities =>
      super._childEntities..addToken('name', name);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitCatchClauseParameter(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {}
}

/// Helper class to allow iteration of child entities of an AST node.
class ChildEntities {
  /// The list of child entities to be iterated over.
  final List<ChildEntity> entities = [];

  List<SyntacticEntity> get syntacticEntities {
    var result = <SyntacticEntity>[];
    for (var entity in entities) {
      var entityValue = entity.value;
      if (entityValue is SyntacticEntity) {
        result.add(entityValue);
      } else if (entityValue is List<Object>) {
        for (var element in entityValue) {
          if (element is SyntacticEntity) {
            result.add(element);
          }
        }
      }
    }

    var needsSorting = false;
    int? lastOffset;
    for (var entity in result) {
      if (lastOffset != null && lastOffset > entity.offset) {
        needsSorting = true;
        break;
      }
      lastOffset = entity.offset;
    }

    if (needsSorting) {
      result.sort((a, b) => a.offset - b.offset);
    }

    return result;
  }

  void addAll(ChildEntities other) {
    entities.addAll(other.entities);
  }

  void addNode(String name, AstNode? value) {
    if (value != null) {
      entities.add(
        ChildEntity(name, value),
      );
    }
  }

  void addNodeList(String name, List<AstNode> value) {
    entities.add(
      ChildEntity(name, value),
    );
  }

  void addToken(String name, Token? value) {
    if (value != null) {
      entities.add(
        ChildEntity(name, value),
      );
    }
  }

  void addTokenList(String name, List<Token> value) {
    entities.add(
      ChildEntity(name, value),
    );
  }
}

/// A named child of an [AstNode], usually a token, node, or a list of nodes.
class ChildEntity {
  final String name;
  final Object value;

  ChildEntity(this.name, this.value);
}

/// The declaration of a class augmentation.
///
///    classAugmentationDeclaration ::=
///        'augment' 'class' name [TypeParameterList]?
///        [ExtendsClause]? [WithClause]? [ImplementsClause]?
///        '{' [ClassMember]* '}'
@experimental
abstract final class ClassAugmentationDeclaration
    implements ClassOrAugmentationDeclaration {
  /// The token representing the 'augment' keyword.
  Token get augmentKeyword;

  @override
  ClassAugmentationElement? get declaredElement;
}

final class ClassAugmentationDeclarationImpl
    extends ClassOrAugmentationDeclarationImpl
    implements ClassAugmentationDeclaration {
  @override
  final Token augmentKeyword;

  @override
  ClassAugmentationElementImpl? declaredElement;

  ClassAugmentationDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
    required super.abstractKeyword,
    required super.macroKeyword,
    required super.inlineKeyword,
    required super.sealedKeyword,
    required super.baseKeyword,
    required super.interfaceKeyword,
    required super.finalKeyword,
    required super.mixinKeyword,
    required super.classKeyword,
    required super.name,
    required super.typeParameters,
    required super.withClause,
    required super.implementsClause,
    required super.nativeClause,
    required super.leftBracket,
    required super.members,
    required super.rightBracket,
  });

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitClassAugmentationDeclaration(this);
  }
}

/// The declaration of a class.
///
///    classDeclaration ::=
///        classModifiers 'class' name [TypeParameterList]?
///        [ExtendsClause]? [WithClause]? [ImplementsClause]?
///        '{' [ClassMember]* '}'
///
///    classModifiers ::= 'sealed'
///      | 'abstract'? ('base' | 'interface' | 'final')?
///      | 'abstract'? 'base'? 'mixin'
abstract final class ClassDeclaration
    implements ClassOrAugmentationDeclaration {
  @override
  ClassElement? get declaredElement;

  /// Returns the `extends` clause for this class, or `null` if the class
  /// does not extend any other class.
  ExtendsClause? get extendsClause;

  /// Return the 'inline' keyword, or `null` if the keyword was absent.
  @experimental
  Token? get inlineKeyword;

  /// Return the native clause for this class, or `null` if the class does not
  /// have a native clause.
  NativeClause? get nativeClause;
}

final class ClassDeclarationImpl extends ClassOrAugmentationDeclarationImpl
    implements ClassDeclaration {
  @override
  ExtendsClauseImpl? extendsClause;

  @override
  ClassElementImpl? declaredElement;

  ClassDeclarationImpl({
    required super.comment,
    required super.metadata,
    required super.abstractKeyword,
    required super.macroKeyword,
    required super.inlineKeyword,
    required super.sealedKeyword,
    required super.baseKeyword,
    required super.interfaceKeyword,
    required super.finalKeyword,
    required super.mixinKeyword,
    required super.classKeyword,
    required super.name,
    required super.typeParameters,
    required this.extendsClause,
    required super.withClause,
    required super.implementsClause,
    required super.nativeClause,
    required super.leftBracket,
    required super.members,
    required super.rightBracket,
  });

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitClassDeclaration(this);
}

/// A node that declares a name within the scope of a class declarations.
///
/// When the 'extension-methods' experiment is enabled, these nodes can also be
/// located inside extension declarations.
sealed class ClassMember implements Declaration {}

/// A node that declares a name within the scope of a class.
sealed class ClassMemberImpl extends DeclarationImpl implements ClassMember {
  /// Initialize a newly created member of a class. Either or both of the
  /// [comment] and [metadata] can be `null` if the member does not have the
  /// corresponding attribute.
  ClassMemberImpl({
    required super.comment,
    required super.metadata,
  });
}

/// Shared interface between [ClassDeclaration] and
/// [ClassAugmentationDeclaration].
@experimental
abstract final class ClassOrAugmentationDeclaration
    implements NamedCompilationUnitMember {
  /// Return the 'abstract' keyword, or `null` if the keyword was absent.
  ///
  /// In valid code only [ClassDeclaration] can specify it.
  Token? get abstractKeyword;

  /// Return the 'base' keyword, or `null` if the keyword was absent.
  Token? get baseKeyword;

  /// Returns the token representing the 'class' keyword.
  Token get classKeyword;

  @override
  ClassOrAugmentationElement? get declaredElement;

  /// Return the 'final' keyword, or `null` if the keyword was absent.
  Token? get finalKeyword;

  /// Returns the `implements` clause for the class, or `null` if the class
  /// does not implement any interfaces.
  ImplementsClause? get implementsClause;

  /// Return the 'interface' keyword, or `null` if the keyword was absent.
  Token? get interfaceKeyword;

  /// Returns the left curly bracket.
  Token get leftBracket;

  /// Returns the members defined by the class.
  NodeList<ClassMember> get members;

  /// Return the 'mixin' keyword, or `null` if the keyword was absent.
  Token? get mixinKeyword;

  /// Returns the right curly bracket.
  Token get rightBracket;

  /// Return the 'sealed' keyword, or `null` if the keyword was absent.
  Token? get sealedKeyword;

  /// Returns the type parameters for the class, or `null` if the class does
  /// not have any type parameters.
  TypeParameterList? get typeParameters;

  /// Returns the `with` clause for the class, or `null` if the class does not
  /// have a `with` clause.
  WithClause? get withClause;
}

sealed class ClassOrAugmentationDeclarationImpl
    extends NamedCompilationUnitMemberImpl
    implements ClassOrAugmentationDeclaration {
  @override
  final Token? abstractKeyword;

  /// The 'macro' keyword, or `null` if the keyword was absent.
  final Token? macroKeyword;

  @override
  final Token? sealedKeyword;

  @override
  final Token? baseKeyword;

  @override
  final Token? interfaceKeyword;

  @override
  final Token? finalKeyword;

  @override
  final Token? mixinKeyword;

  /// The 'inline' keyword, or `null` if the keyword was absent.
  final Token? inlineKeyword;

  @override
  final Token classKeyword;

  @override
  TypeParameterListImpl? typeParameters;

  @override
  WithClauseImpl? withClause;

  @override
  ImplementsClauseImpl? implementsClause;

  final NativeClauseImpl? nativeClause;

  @override
  final Token leftBracket;

  @override
  final NodeListImpl<ClassMemberImpl> members = NodeListImpl._();

  @override
  final Token rightBracket;

  ClassOrAugmentationDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.abstractKeyword,
    required this.macroKeyword,
    required this.sealedKeyword,
    required this.baseKeyword,
    required this.interfaceKeyword,
    required this.finalKeyword,
    required this.mixinKeyword,
    required this.inlineKeyword,
    required this.classKeyword,
    required super.name,
    required this.typeParameters,
    required this.withClause,
    required this.implementsClause,
    required this.nativeClause,
    required this.leftBracket,
    required List<ClassMemberImpl> members,
    required this.rightBracket,
  }) {
    _becomeParentOf(typeParameters);
    _becomeParentOf(extendsClause);
    _becomeParentOf(withClause);
    _becomeParentOf(implementsClause);
    _becomeParentOf(nativeClause);
    this.members._initialize(this, members);
  }

  Token? get augmentKeyword => null;

  @override
  Token get endToken => rightBracket;

  ExtendsClauseImpl? get extendsClause => null;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return abstractKeyword ??
        macroKeyword ??
        sealedKeyword ??
        baseKeyword ??
        interfaceKeyword ??
        finalKeyword ??
        augmentKeyword ??
        mixinKeyword ??
        classKeyword;
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('abstractKeyword', abstractKeyword)
    ..addToken('macroKeyword', macroKeyword)
    ..addToken('inlineKeyword', inlineKeyword)
    ..addToken('sealedKeyword', sealedKeyword)
    ..addToken('baseKeyword', baseKeyword)
    ..addToken('interfaceKeyword', interfaceKeyword)
    ..addToken('finalKeyword', finalKeyword)
    ..addToken('augmentKeyword', augmentKeyword)
    ..addToken('mixinKeyword', mixinKeyword)
    ..addToken('classKeyword', classKeyword)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addNode('extendsClause', extendsClause)
    ..addNode('withClause', withClause)
    ..addNode('implementsClause', implementsClause)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('members', members)
    ..addToken('rightBracket', rightBracket);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    typeParameters?.accept(visitor);
    extendsClause?.accept(visitor);
    withClause?.accept(visitor);
    implementsClause?.accept(visitor);
    nativeClause?.accept(visitor);
    members.accept(visitor);
  }
}

/// A class type alias.
///
///    classTypeAlias ::=
///        classModifiers 'class' [SimpleIdentifier] [TypeParameterList]? '=' mixinApplication
///
///    classModifiers ::= 'sealed'
///      | 'abstract'? ('base' | 'interface' | 'final')?
///      | 'abstract'? 'base'? 'mixin'
///
///    mixinApplication ::=
///        [NamedType] [WithClause] [ImplementsClause]? ';'
abstract final class ClassTypeAlias implements TypeAlias {
  /// Return the token for the 'abstract' keyword, or `null` if this is not
  /// defining an abstract class.
  Token? get abstractKeyword;

  /// Return the 'base' keyword, or `null` if the keyword was absent.
  Token? get baseKeyword;

  @override
  ClassElement? get declaredElement;

  /// Return the token for the '=' separating the name from the definition.
  Token get equals;

  /// Return the 'final' keyword, or `null` if the keyword was absent.
  Token? get finalKeyword;

  /// Return the implements clause for this class, or `null` if there is no
  /// implements clause.
  ImplementsClause? get implementsClause;

  /// Return the 'interface' keyword, or `null` if the keyword was absent.
  Token? get interfaceKeyword;

  /// Return the 'mixin' keyword, or `null` if the keyword was absent.
  Token? get mixinKeyword;

  /// Return the 'sealed' keyword, or `null` if the keyword was absent.
  Token? get sealedKeyword;

  /// Return the name of the superclass of the class being declared.
  NamedType get superclass;

  /// Return the type parameters for the class, or `null` if the class does not
  /// have any type parameters.
  TypeParameterList? get typeParameters;

  /// Return the with clause for this class.
  WithClause get withClause;
}

/// A class type alias.
///
///    classTypeAlias ::=
///        classModifiers 'class' [SimpleIdentifier] [TypeParameterList]? '=' mixinApplication
///
///    classModifiers ::= 'sealed'
///      | 'abstract'? ('base' | 'interface' | 'final')?
///      | 'abstract'? 'base'? 'mixin'
///
///    mixinApplication ::=
///        [NamedType] [WithClause] [ImplementsClause]? ';'
final class ClassTypeAliasImpl extends TypeAliasImpl implements ClassTypeAlias {
  /// The type parameters for the class, or `null` if the class does not have
  /// any type parameters.
  TypeParameterListImpl? _typeParameters;

  /// The token for the '=' separating the name from the definition.
  @override
  final Token equals;

  /// The token for the 'abstract' keyword, or `null` if this is not defining an
  /// abstract class.
  @override
  final Token? abstractKeyword;

  /// The token for the 'macro' keyword, or `null` if this is not defining a
  /// macro class.
  final Token? macroKeyword;

  /// The token for the 'inline' keyword, or `null` if this is not defining an
  /// inline class.
  final Token? inlineKeyword;

  /// The token for the 'sealed' keyword, or `null` if this is not defining a
  /// sealed class.
  @override
  final Token? sealedKeyword;

  /// The token for the 'base' keyword, or `null` if this is not defining a base
  /// class.
  @override
  final Token? baseKeyword;

  /// The token for the 'interface' keyword, or `null` if this is not defining
  /// an interface class.
  @override
  final Token? interfaceKeyword;

  /// The token for the 'final' keyword, or `null` if this is not defining a
  /// final class.
  @override
  final Token? finalKeyword;

  /// The token for the 'augment' keyword, or `null` if this is not defining an
  /// augmentation class.
  final Token? augmentKeyword;

  /// The token for the 'mixin' keyword, or `null` if this is not defining a
  /// mixin class.
  @override
  final Token? mixinKeyword;

  /// The name of the superclass of the class being declared.
  NamedTypeImpl _superclass;

  /// The with clause for this class.
  WithClauseImpl _withClause;

  /// The implements clause for this class, or `null` if there is no implements
  /// clause.
  ImplementsClauseImpl? _implementsClause;

  @override
  ClassElementImpl? declaredElement;

  /// Initialize a newly created class type alias. Either or both of the
  /// [comment] and [metadata] can be `null` if the class type alias does not
  /// have the corresponding attribute. The [typeParameters] can be `null` if
  /// the class does not have any type parameters. The [abstractKeyword] can be
  /// `null` if the class is not abstract. The [implementsClause] can be `null`
  /// if the class does not implement any interfaces.
  ClassTypeAliasImpl({
    required super.comment,
    required super.metadata,
    required super.typedefKeyword,
    required super.name,
    required TypeParameterListImpl? typeParameters,
    required this.equals,
    required this.abstractKeyword,
    required this.macroKeyword,
    required this.inlineKeyword,
    required this.sealedKeyword,
    required this.baseKeyword,
    required this.interfaceKeyword,
    required this.finalKeyword,
    required this.augmentKeyword,
    required this.mixinKeyword,
    required NamedTypeImpl superclass,
    required WithClauseImpl withClause,
    required ImplementsClauseImpl? implementsClause,
    required super.semicolon,
  })  : _typeParameters = typeParameters,
        _superclass = superclass,
        _withClause = withClause,
        _implementsClause = implementsClause {
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_superclass);
    _becomeParentOf(_withClause);
    _becomeParentOf(_implementsClause);
  }

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return abstractKeyword ??
        macroKeyword ??
        inlineKeyword ??
        sealedKeyword ??
        baseKeyword ??
        interfaceKeyword ??
        finalKeyword ??
        augmentKeyword ??
        mixinKeyword ??
        typedefKeyword;
  }

  @override
  ImplementsClauseImpl? get implementsClause => _implementsClause;

  set implementsClause(ImplementsClauseImpl? implementsClause) {
    _implementsClause = _becomeParentOf(implementsClause);
  }

  @override
  NamedTypeImpl get superclass => _superclass;

  set superclass(NamedTypeImpl superclass) {
    _superclass = _becomeParentOf(superclass);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters as TypeParameterListImpl);
  }

  @override
  WithClauseImpl get withClause => _withClause;

  set withClause(WithClauseImpl withClause) {
    _withClause = _becomeParentOf(withClause);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('typedefKeyword', typedefKeyword)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addToken('equals', equals)
    ..addToken('abstractKeyword', abstractKeyword)
    ..addToken('inlineKeyword', inlineKeyword)
    ..addToken('macroKeyword', macroKeyword)
    ..addToken('sealedKeyword', sealedKeyword)
    ..addToken('baseKeyword', baseKeyword)
    ..addToken('interfaceKeyword', interfaceKeyword)
    ..addToken('finalKeyword', finalKeyword)
    ..addToken('augmentKeyword', augmentKeyword)
    ..addToken('mixinKeyword', mixinKeyword)
    ..addNode('superclass', superclass)
    ..addNode('withClause', withClause)
    ..addNode('implementsClause', implementsClause)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitClassTypeAlias(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _typeParameters?.accept(visitor);
    _superclass.accept(visitor);
    _withClause.accept(visitor);
    _implementsClause?.accept(visitor);
  }
}

/// An element in a list, map or set literal.
///
///    collectionElement ::=
///        [Expression]
///      | [IfElement]
///      | [ForElement]
///      | [MapLiteralEntry]
///      | [SpreadElement]
sealed class CollectionElement implements AstNode {}

sealed class CollectionElementImpl extends AstNodeImpl
    implements CollectionElement {
  /// Dispatches this collection element to the [resolver], with the given
  /// [context] information.
  void resolveElement(
      ResolverVisitor resolver, CollectionLiteralContext? context);
}

/// A combinator associated with an import or export directive.
///
///    combinator ::=
///        [HideCombinator]
///      | [ShowCombinator]
sealed class Combinator implements AstNode {
  /// Return the 'hide' or 'show' keyword specifying what kind of processing is
  /// to be done on the names.
  Token get keyword;
}

/// A combinator associated with an import or export directive.
///
///    combinator ::=
///        [HideCombinator]
///      | [ShowCombinator]
sealed class CombinatorImpl extends AstNodeImpl implements Combinator {
  /// The 'hide' or 'show' keyword specifying what kind of processing is to be
  /// done on the names.
  @override
  final Token keyword;

  /// Initialize a newly created combinator.
  CombinatorImpl({
    required this.keyword,
  });

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
abstract final class Comment implements AstNode {
  /// Return `true` if this is a block comment.
  bool get isBlock;

  /// Return `true` if this is a documentation comment.
  bool get isDocumentation;

  /// Return `true` if this is an end-of-line comment.
  bool get isEndOfLine;

  /// Return the references embedded within the documentation comment.
  NodeList<CommentReference> get references;

  /// Return the tokens representing the comment.
  List<Token> get tokens;
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
final class CommentImpl extends AstNodeImpl implements Comment {
  /// The tokens representing the comment.
  @override
  final List<Token> tokens;

  /// The type of the comment.
  final CommentType _type;

  /// The references embedded within the documentation comment. This list will
  /// be empty unless this is a documentation comment that has references embedded
  /// within it.
  final NodeListImpl<CommentReferenceImpl> _references = NodeListImpl._();

  /// Initialize a newly created comment. The list of [tokens] must contain at
  /// least one token. The [_type] is the type of the comment. The list of
  /// [references] can be empty if the comment does not contain any embedded
  /// references.
  CommentImpl({
    required this.tokens,
    required CommentType type,
    required List<CommentReferenceImpl> references,
  }) : _type = type {
    _references._initialize(this, references);
  }

  @override
  Token get beginToken => tokens[0];

  @override
  Token get endToken => tokens[tokens.length - 1];

  @override
  bool get isBlock => _type == CommentType.BLOCK;

  @override
  bool get isDocumentation => _type == CommentType.DOCUMENTATION;

  @override
  bool get isEndOfLine => _type == CommentType.END_OF_LINE;

  @override
  NodeListImpl<CommentReferenceImpl> get references => _references;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNodeList('references', references)
    ..addTokenList('tokens', tokens);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitComment(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _references.accept(visitor);
  }
}

/// An interface for an [Expression] which can make up a [CommentReference].
///
///    commentReferableExpression ::=
///        [ConstructorReference]
///      | [FunctionReference]
///      | [PrefixedIdentifier]
///      | [PropertyAccess]
///      | [SimpleIdentifier]
///      | [TypeLiteral]
///
/// This interface should align closely with dartdoc's notion of
/// comment-referable expressions at:
/// https://github.com/dart-lang/dartdoc/blob/master/lib/src/comment_references/parser.dart
abstract final class CommentReferableExpression implements Expression {}

sealed class CommentReferableExpressionImpl extends ExpressionImpl
    implements CommentReferableExpression {}

/// A reference to a Dart element that is found within a documentation comment.
///
///    commentReference ::=
///        '[' 'new'? [CommentReferableExpression] ']'
abstract final class CommentReference implements AstNode {
  /// The comment-referable expression being referenced.
  CommentReferableExpression get expression;

  /// Return the token representing the 'new' keyword, or `null` if there was no
  /// 'new' keyword.
  Token? get newKeyword;
}

/// A reference to a Dart element that is found within a documentation comment.
///
///    commentReference ::=
///        '[' 'new'? [Identifier] ']'
final class CommentReferenceImpl extends AstNodeImpl
    implements CommentReference {
  /// The token representing the 'new' keyword, or `null` if there was no 'new'
  /// keyword.
  @override
  final Token? newKeyword;

  /// The expression being referenced.
  CommentReferableExpressionImpl _expression;

  /// Initialize a newly created reference to a Dart element. The [newKeyword]
  /// can be `null` if the reference is not to a constructor.
  CommentReferenceImpl({
    required this.newKeyword,
    required CommentReferableExpressionImpl expression,
  }) : _expression = expression {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => newKeyword ?? _expression.beginToken;

  @override
  Token get endToken => _expression.endToken;

  @override
  CommentReferableExpressionImpl get expression => _expression;

  set expression(CommentReferableExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('newKeyword', newKeyword)
    ..addNode('expression', expression);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitCommentReference(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
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
abstract final class CompilationUnit implements AstNode {
  /// Return the declarations contained in this compilation unit.
  NodeList<CompilationUnitMember> get declarations;

  /// Return the element associated with this compilation unit, or `null` if the
  /// AST structure has not been resolved.
  CompilationUnitElement? get declaredElement;

  /// Return the directives contained in this compilation unit.
  NodeList<Directive> get directives;

  /// The set of features available to this compilation unit.
  ///
  /// Determined by some combination of the .packages file, the enclosing
  /// package's SDK version constraint, and/or the presence of a `@dart`
  /// directive in a comment at the top of the file.
  FeatureSet get featureSet;

  /// The language version override specified for this compilation unit using a
  /// token like '// @dart = 2.7', or `null` if no override is specified.
  LanguageVersionToken? get languageVersionToken;

  /// Return the line information for this compilation unit.
  LineInfo get lineInfo;

  /// Return the script tag at the beginning of the compilation unit, or `null`
  /// if there is no script tag in this compilation unit.
  ScriptTag? get scriptTag;

  /// Return a list containing all of the directives and declarations in this
  /// compilation unit, sorted in lexical order.
  List<AstNode> get sortedDirectivesAndDeclarations;
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
final class CompilationUnitImpl extends AstNodeImpl implements CompilationUnit {
  /// The first token in the token stream that was parsed to form this
  /// compilation unit.
  @override
  Token beginToken;

  /// The script tag at the beginning of the compilation unit, or `null` if
  /// there is no script tag in this compilation unit.
  ScriptTagImpl? _scriptTag;

  /// The directives contained in this compilation unit.
  final NodeListImpl<DirectiveImpl> _directives = NodeListImpl._();

  /// The declarations contained in this compilation unit.
  final NodeListImpl<CompilationUnitMemberImpl> _declarations =
      NodeListImpl._();

  /// The last token in the token stream that was parsed to form this
  /// compilation unit. This token should always have a type of [TokenType.EOF].
  @override
  final Token endToken;

  /// The element associated with this compilation unit, or `null` if the AST
  /// structure has not been resolved.
  @override
  CompilationUnitElementImpl? declaredElement;

  /// The line information for this compilation unit.
  @override
  final LineInfo lineInfo;

  /// The language version information.
  LibraryLanguageVersion? languageVersion;

  @override
  final FeatureSet featureSet;

  /// Nodes that were parsed, but happened at locations where they are not
  /// allowed. So, instead of dropping them, we remember them here. Quick
  /// fixes could look here to determine which source range to remove.
  final List<AstNodeImpl> invalidNodes;

  /// Initialize a newly created compilation unit to have the given directives
  /// and declarations. The [scriptTag] can be `null` if there is no script tag
  /// in the compilation unit. The list of [directives] can be `null` if there
  /// are no directives in the compilation unit. The list of [declarations] can
  /// be `null` if there are no declarations in the compilation unit.
  CompilationUnitImpl({
    required this.beginToken,
    required ScriptTagImpl? scriptTag,
    required List<DirectiveImpl>? directives,
    required List<CompilationUnitMemberImpl>? declarations,
    required this.endToken,
    required this.featureSet,
    required this.lineInfo,
    required this.invalidNodes,
  }) : _scriptTag = scriptTag {
    _becomeParentOf(_scriptTag);
    _directives._initialize(this, directives);
    _declarations._initialize(this, declarations);
  }

  @override
  NodeListImpl<CompilationUnitMemberImpl> get declarations => _declarations;

  @override
  NodeListImpl<DirectiveImpl> get directives => _directives;

  @override
  LanguageVersionToken? get languageVersionToken {
    Token? targetToken = beginToken;
    if (targetToken.type == TokenType.SCRIPT_TAG) {
      targetToken = targetToken.next;
    }

    Token? comment = targetToken?.precedingComments;
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
    final endToken = this.endToken;
    return endToken.offset + endToken.length;
  }

  @override
  int get offset => 0;

  @override
  ScriptTagImpl? get scriptTag => _scriptTag;

  set scriptTag(ScriptTagImpl? scriptTag) {
    _scriptTag = _becomeParentOf(scriptTag);
  }

  @override
  List<AstNode> get sortedDirectivesAndDeclarations {
    return <AstNode>[
      ..._directives,
      ..._declarations,
    ]..sort(AstNode.LEXICAL_ORDER);
  }

  @override
  ChildEntities get _childEntities {
    return ChildEntities()
      ..addNode('scriptTag', scriptTag)
      ..addNodeList('directives', directives)
      ..addNodeList('declarations', declarations);
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
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitCompilationUnit(this);

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
abstract final class CompilationUnitMember implements Declaration {}

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
sealed class CompilationUnitMemberImpl extends DeclarationImpl
    implements CompilationUnitMember {
  /// Initialize a newly created generic compilation unit member. Either or both
  /// of the [comment] and [metadata] can be `null` if the member does not have
  /// the corresponding attribute.
  CompilationUnitMemberImpl({
    required super.comment,
    required super.metadata,
  });
}

/// A potentially compound assignment.
///
/// A compound assignment is any node in which a single expression is used to
/// specify both where to access a value to be operated on (the "read") and to
/// specify where to store the result of the operation (the "write"). This
/// happens in an [AssignmentExpression] when the assignment operator is a
/// compound assignment operator, and in a [PrefixExpression] or
/// [PostfixExpression] when the operator is an increment operator.
abstract final class CompoundAssignmentExpression implements Expression {
  /// The element that is used to read the value.
  ///
  /// If this node is not a compound assignment, this element is `null`.
  ///
  /// In valid code this element can be a [LocalVariableElement], a
  /// [ParameterElement], or a [PropertyAccessorElement] getter.
  ///
  /// In invalid code this element is `null`, for example `int += 2`. For
  /// recovery [writeElement] is filled, and can be used for navigation.
  ///
  /// This element is `null` if the AST structure has not been resolved, or
  /// if the target could not be resolved.
  Element? get readElement;

  /// The type of the value read with the [readElement].
  ///
  /// If this node is not a compound assignment, this type is `null`.
  ///
  /// In invalid code, e.g. `int += 2`, this type is `dynamic`.
  ///
  /// This type is `null` if the AST structure has not been resolved.
  ///
  /// If the target could not be resolved, this type is `dynamic`.
  DartType? get readType;

  /// The element that is used to write the result.
  ///
  /// In valid code this is a [LocalVariableElement], [ParameterElement], or a
  /// [PropertyAccessorElement] setter.
  ///
  /// In invalid code, for recovery, we might use other elements, for example a
  /// [PropertyAccessorElement] getter `myGetter = 0` even though the getter
  /// cannot be used to write a value. We do this to help the user to navigate
  /// to the getter, and maybe add the corresponding setter.
  ///
  /// If this node is a compound assignment, e. g. `x += 2`, both [readElement]
  /// and [writeElement] could be not `null`.
  ///
  /// This element is `null` if the AST structure has not been resolved, or
  /// if the target could not be resolved.
  Element? get writeElement;

  /// The types of assigned values must be subtypes of this type.
  ///
  /// If the target could not be resolved, this type is `dynamic`.
  DartType? get writeType;
}

base mixin CompoundAssignmentExpressionImpl
    implements CompoundAssignmentExpression {
  @override
  Element? readElement;

  @override
  Element? writeElement;

  @override
  DartType? readType;

  @override
  DartType? writeType;
}

/// A conditional expression.
///
///    conditionalExpression ::=
///        [Expression] '?' [Expression] ':' [Expression]
abstract final class ConditionalExpression implements Expression {
  /// Return the token used to separate the then expression from the else
  /// expression.
  Token get colon;

  /// Return the condition used to determine which of the expressions is
  /// executed next.
  Expression get condition;

  /// Return the expression that is executed if the condition evaluates to
  /// `false`.
  Expression get elseExpression;

  /// Return the token used to separate the condition from the then expression.
  Token get question;

  /// Return the expression that is executed if the condition evaluates to
  /// `true`.
  Expression get thenExpression;
}

/// A conditional expression.
///
///    conditionalExpression ::=
///        [Expression] '?' [Expression] ':' [Expression]
final class ConditionalExpressionImpl extends ExpressionImpl
    implements ConditionalExpression {
  /// The condition used to determine which of the expressions is executed next.
  ExpressionImpl _condition;

  /// The token used to separate the condition from the then expression.
  @override
  final Token question;

  /// The expression that is executed if the condition evaluates to `true`.
  ExpressionImpl _thenExpression;

  /// The token used to separate the then expression from the else expression.
  @override
  final Token colon;

  /// The expression that is executed if the condition evaluates to `false`.
  ExpressionImpl _elseExpression;

  /// Initialize a newly created conditional expression.
  ConditionalExpressionImpl({
    required ExpressionImpl condition,
    required this.question,
    required ExpressionImpl thenExpression,
    required this.colon,
    required ExpressionImpl elseExpression,
  })  : _condition = condition,
        _thenExpression = thenExpression,
        _elseExpression = elseExpression {
    _becomeParentOf(_condition);
    _becomeParentOf(_thenExpression);
    _becomeParentOf(_elseExpression);
  }

  @override
  Token get beginToken => _condition.beginToken;

  @override
  ExpressionImpl get condition => _condition;

  set condition(ExpressionImpl expression) {
    _condition = _becomeParentOf(expression);
  }

  @override
  ExpressionImpl get elseExpression => _elseExpression;

  set elseExpression(ExpressionImpl expression) {
    _elseExpression = _becomeParentOf(expression);
  }

  @override
  Token get endToken => _elseExpression.endToken;

  @override
  Precedence get precedence => Precedence.conditional;

  @override
  ExpressionImpl get thenExpression => _thenExpression;

  set thenExpression(ExpressionImpl expression) {
    _thenExpression = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('condition', condition)
    ..addToken('question', question)
    ..addNode('thenExpression', thenExpression)
    ..addToken('colon', colon)
    ..addNode('elseExpression', elseExpression);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitConditionalExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitConditionalExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _condition.accept(visitor);
    _thenExpression.accept(visitor);
    _elseExpression.accept(visitor);
  }
}

/// A configuration in either an import or export directive.
///
///    configuration ::=
///        'if' '(' test ')' uri
///
///    test ::=
///        dottedName ('==' stringLiteral)?
///
///    dottedName ::=
///        identifier ('.' identifier)*
abstract final class Configuration implements AstNode {
  /// Return the token for the equal operator, or `null` if the condition does
  /// not include an equality test.
  Token? get equalToken;

  /// Return the token for the 'if' keyword.
  Token get ifKeyword;

  /// Return the token for the left parenthesis.
  Token get leftParenthesis;

  /// Return the name of the declared variable whose value is being used in the
  /// condition.
  DottedName get name;

  /// The result of resolving [uri].
  DirectiveUri? get resolvedUri;

  /// Return the token for the right parenthesis.
  Token get rightParenthesis;

  /// Return the URI of the implementation library to be used if the condition
  /// is true.
  StringLiteral get uri;

  /// Return the value to which the value of the declared variable will be
  /// compared, or `null` if the condition does not include an equality test.
  StringLiteral? get value;
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
final class ConfigurationImpl extends AstNodeImpl implements Configuration {
  @override
  final Token ifKeyword;

  @override
  final Token leftParenthesis;

  DottedNameImpl _name;

  @override
  final Token? equalToken;

  StringLiteralImpl? _value;

  @override
  final Token rightParenthesis;

  StringLiteralImpl _uri;

  @override
  DirectiveUri? resolvedUri;

  ConfigurationImpl({
    required this.ifKeyword,
    required this.leftParenthesis,
    required DottedNameImpl name,
    required this.equalToken,
    required StringLiteralImpl? value,
    required this.rightParenthesis,
    required StringLiteralImpl uri,
  })  : _name = name,
        _value = value,
        _uri = uri {
    _becomeParentOf(_name);
    _becomeParentOf(_value);
    _becomeParentOf(_uri);
  }

  @override
  Token get beginToken => ifKeyword;

  @override
  Token get endToken => _uri.endToken;

  @override
  DottedNameImpl get name => _name;

  set name(DottedNameImpl name) {
    _name = _becomeParentOf(name);
  }

  @override
  StringLiteralImpl get uri => _uri;

  set uri(StringLiteralImpl uri) {
    _uri = _becomeParentOf(uri);
  }

  @override
  StringLiteralImpl? get value => _value;

  set value(StringLiteralImpl? value) {
    _value = _becomeParentOf(value as StringLiteralImpl);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('ifKeyword', ifKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('name', name)
    ..addToken('equalToken', equalToken)
    ..addNode('value', value)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addNode('uri', uri);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitConfiguration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _name.accept(visitor);
    _value?.accept(visitor);
    _uri.accept(visitor);
  }
}

/// This class is used as a marker of constant context for initializers
/// of constant fields and top-level variables read from summaries.
final class ConstantContextForExpressionImpl extends AstNodeImpl {
  final Element variable;
  final ExpressionImpl expression;

  ConstantContextForExpressionImpl(this.variable, this.expression) {
    _becomeParentOf(expression);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A constant expression being used as a pattern.
///
/// The only expressions that can be validly used as a pattern are
/// - `bool` literals
/// - `double` literals
/// - `int` literals
/// - `null` literals
/// - `String` literals
/// - references to constant variables
/// - constant constructor invocations
/// - constant list literals
/// - constant set or map literals
/// - constant expressions wrapped in parentheses and preceded by the `const`
///   keyword
///
/// This node is also used to recover from cases where a different kind of
/// expression is used as a pattern, so clients need to handle the case where
/// the expression is not one of the valid alternatives.
///
///    constantPattern ::=
///        'const'? [Expression]
abstract final class ConstantPattern implements DartPattern {
  /// Return the `const` keyword, or `null` if the expression is not preceded by
  /// the keyword `const`.
  Token? get constKeyword;

  /// Return the constant expression being used as a pattern.
  Expression get expression;
}

/// An expression being used as a pattern.
///
/// The only expressions that can be validly used as a pattern are `bool`,
/// `double`, `int`, `null`, and `String` literals and references to constant
/// variables.
///
/// This node is also used to recover from cases where a different kind of
/// expression is used as a pattern, so clients need to handle the case where
/// the expression is not one of the valid alternatives.
///
///    constantPattern ::=
///        'const'? [Expression]
final class ConstantPatternImpl extends DartPatternImpl
    implements ConstantPattern {
  @override
  final Token? constKeyword;

  ExpressionImpl _expression;

  ConstantPatternImpl({
    required this.constKeyword,
    required ExpressionImpl expression,
  }) : _expression = expression {
    _becomeParentOf(expression);
  }

  @override
  Token get beginToken => constKeyword ?? expression.beginToken;

  @override
  Token get endToken => expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('const', constKeyword)
    ..addNode('expression', expression);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitConstantPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor.analyzeConstantPatternSchema();
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.analyzeConstantPattern(context, this, expression);
    expression = resolverVisitor.popRewrite()!;
  }

  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
  }
}

/// A constructor declaration.
///
///    constructorDeclaration ::=
///        constructorSignature [FunctionBody]?
///      | constructorName formalParameterList ':' 'this' ('.' [SimpleIdentifier])? arguments
///
///    constructorSignature ::=
///        'external'? constructorName formalParameterList initializerList?
///      | 'external'? 'factory' factoryName formalParameterList initializerList?
///      | 'external'? 'const'  constructorName formalParameterList initializerList?
///
///    constructorName ::=
///        [SimpleIdentifier] ('.' name)?
///
///    factoryName ::=
///        [Identifier] ('.' [SimpleIdentifier])?
///
///    initializerList ::=
///        ':' [ConstructorInitializer] (',' [ConstructorInitializer])*
abstract final class ConstructorDeclaration implements ClassMember {
  /// Return the body of the constructor.
  FunctionBody get body;

  /// Return the token for the 'const' keyword, or `null` if the constructor is
  /// not a const constructor.
  Token? get constKeyword;

  @override
  ConstructorElement? get declaredElement;

  /// Return the token for the 'external' keyword to the given [token].
  Token? get externalKeyword;

  /// Return the token for the 'factory' keyword, or `null` if the constructor
  /// is not a factory constructor.
  Token? get factoryKeyword;

  /// Return the initializers associated with the constructor.
  NodeList<ConstructorInitializer> get initializers;

  /// Return the name of the constructor, or `null` if the constructor being
  /// declared is unnamed.
  Token? get name;

  /// Return the parameters associated with the constructor.
  FormalParameterList get parameters;

  /// Return the token for the period before the constructor name, or `null` if
  /// the constructor being declared is unnamed.
  Token? get period;

  /// Return the name of the constructor to which this constructor will be
  /// redirected, or `null` if this is not a redirecting factory constructor.
  ConstructorName? get redirectedConstructor;

  /// Return the type of object being created.
  ///
  /// This can be different than the type in which the constructor is being
  /// declared if the constructor is the implementation of a factory
  /// constructor.
  Identifier get returnType;

  /// Return the token for the separator (colon or equals) before the
  /// initializer list or redirection, or `null` if there are no initializers.
  Token? get separator;
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
final class ConstructorDeclarationImpl extends ClassMemberImpl
    implements ConstructorDeclaration {
  /// The token for the 'external' keyword, or `null` if the constructor is not
  /// external.
  @override
  final Token? externalKeyword;

  /// The token for the 'const' keyword, or `null` if the constructor is not a
  /// const constructor.
  @override
  Token? constKeyword;

  /// The token for the 'factory' keyword, or `null` if the constructor is not a
  /// factory constructor.
  @override
  final Token? factoryKeyword;

  /// The type of object being created. This can be different than the type in
  /// which the constructor is being declared if the constructor is the
  /// implementation of a factory constructor.
  IdentifierImpl _returnType;

  /// The token for the period before the constructor name, or `null` if the
  /// constructor being declared is unnamed.
  @override
  final Token? period;

  /// The name of the constructor, or `null` if the constructor being declared
  /// is unnamed.
  @override
  final Token? name;

  /// The parameters associated with the constructor.
  FormalParameterListImpl _parameters;

  /// The token for the separator (colon or equals) before the initializer list
  /// or redirection, or `null` if there are no initializers.
  @override
  Token? separator;

  /// The initializers associated with the constructor.
  final NodeListImpl<ConstructorInitializerImpl> _initializers =
      NodeListImpl._();

  /// The name of the constructor to which this constructor will be redirected,
  /// or `null` if this is not a redirecting factory constructor.
  ConstructorNameImpl? _redirectedConstructor;

  /// The body of the constructor.
  FunctionBodyImpl _body;

  /// The element associated with this constructor, or `null` if the AST
  /// structure has not been resolved or if this constructor could not be
  /// resolved.
  @override
  ConstructorElementImpl? declaredElement;

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
  ConstructorDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.externalKeyword,
    required this.constKeyword,
    required this.factoryKeyword,
    required IdentifierImpl returnType,
    required this.period,
    required this.name,
    required FormalParameterListImpl parameters,
    required this.separator,
    required List<ConstructorInitializerImpl>? initializers,
    required ConstructorNameImpl? redirectedConstructor,
    required FunctionBodyImpl body,
  })  : _returnType = returnType,
        _parameters = parameters,
        _redirectedConstructor = redirectedConstructor,
        _body = body {
    _becomeParentOf(_returnType);
    _becomeParentOf(_parameters);
    _initializers._initialize(this, initializers);
    _becomeParentOf(_redirectedConstructor);
    _becomeParentOf(_body);
  }

  @override
  FunctionBodyImpl get body => _body;

  set body(FunctionBodyImpl functionBody) {
    _body = _becomeParentOf(functionBody);
  }

  @override
  Token get endToken {
    return _body.endToken;
  }

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return Token.lexicallyFirst(
            externalKeyword, constKeyword, factoryKeyword) ??
        _returnType.beginToken;
  }

  @override
  NodeListImpl<ConstructorInitializerImpl> get initializers => _initializers;

  // A trivial constructor is a generative constructor that is not a
  // redirecting constructor, declares no parameters, has no
  // initializer list, has no body, and is not external.
  bool get isTrivial =>
      redirectedConstructor == null &&
      parameters.parameters.isEmpty &&
      initializers.isEmpty &&
      body is EmptyFunctionBody &&
      externalKeyword == null;

  @override
  FormalParameterListImpl get parameters => _parameters;

  set parameters(FormalParameterListImpl parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @override
  ConstructorNameImpl? get redirectedConstructor => _redirectedConstructor;

  set redirectedConstructor(ConstructorNameImpl? redirectedConstructor) {
    _redirectedConstructor =
        _becomeParentOf(redirectedConstructor as ConstructorNameImpl);
  }

  @override
  IdentifierImpl get returnType => _returnType;

  set returnType(IdentifierImpl typeName) {
    _returnType = _becomeParentOf(typeName);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('externalKeyword', externalKeyword)
    ..addToken('constKeyword', constKeyword)
    ..addToken('factoryKeyword', factoryKeyword)
    ..addNode('returnType', returnType)
    ..addToken('period', period)
    ..addToken('name', name)
    ..addNode('parameters', parameters)
    ..addToken('separator', separator)
    ..addNodeList('initializers', initializers)
    ..addNode('redirectedConstructor', redirectedConstructor)
    ..addNode('body', body);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitConstructorDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _returnType.accept(visitor);
    _parameters.accept(visitor);
    _initializers.accept(visitor);
    _redirectedConstructor?.accept(visitor);
    _body.accept(visitor);
  }
}

/// The initialization of a field within a constructor's initialization list.
///
///    fieldInitializer ::=
///        ('this' '.')? [SimpleIdentifier] '=' [Expression]
abstract final class ConstructorFieldInitializer
    implements ConstructorInitializer {
  /// Return the token for the equal sign between the field name and the
  /// expression.
  Token get equals;

  /// Return the expression computing the value to which the field will be
  /// initialized.
  Expression get expression;

  /// Return the name of the field being initialized.
  SimpleIdentifier get fieldName;

  /// Return the token for the period after the 'this' keyword, or `null` if
  /// there is no 'this' keyword.
  Token? get period;

  /// Return the token for the 'this' keyword, or `null` if there is no 'this'
  /// keyword.
  Token? get thisKeyword;
}

/// The initialization of a field within a constructor's initialization list.
///
///    fieldInitializer ::=
///        ('this' '.')? [SimpleIdentifier] '=' [Expression]
final class ConstructorFieldInitializerImpl extends ConstructorInitializerImpl
    implements ConstructorFieldInitializer {
  /// The token for the 'this' keyword, or `null` if there is no 'this' keyword.
  @override
  final Token? thisKeyword;

  /// The token for the period after the 'this' keyword, or `null` if there is
  /// no 'this' keyword.
  @override
  final Token? period;

  /// The name of the field being initialized.
  SimpleIdentifierImpl _fieldName;

  /// The token for the equal sign between the field name and the expression.
  @override
  final Token equals;

  /// The expression computing the value to which the field will be initialized.
  ExpressionImpl _expression;

  /// Initialize a newly created field initializer to initialize the field with
  /// the given name to the value of the given expression. The [thisKeyword] and
  /// [period] can be `null` if the 'this' keyword was not specified.
  ConstructorFieldInitializerImpl({
    required this.thisKeyword,
    required this.period,
    required SimpleIdentifierImpl fieldName,
    required this.equals,
    required ExpressionImpl expression,
  })  : _fieldName = fieldName,
        _expression = expression {
    _becomeParentOf(_fieldName);
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken {
    if (thisKeyword != null) {
      return thisKeyword!;
    }
    return _fieldName.beginToken;
  }

  @override
  Token get endToken => _expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  SimpleIdentifierImpl get fieldName => _fieldName;

  set fieldName(SimpleIdentifierImpl identifier) {
    _fieldName = _becomeParentOf(identifier);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('thisKeyword', thisKeyword)
    ..addToken('period', period)
    ..addNode('fieldName', fieldName)
    ..addToken('equals', equals)
    ..addNode('expression', expression);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitConstructorFieldInitializer(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _fieldName.accept(visitor);
    _expression.accept(visitor);
  }
}

/// A node that can occur in the initializer list of a constructor declaration.
///
///    constructorInitializer ::=
///        [SuperConstructorInvocation]
///      | [ConstructorFieldInitializer]
///      | [RedirectingConstructorInvocation]
sealed class ConstructorInitializer implements AstNode {}

/// A node that can occur in the initializer list of a constructor declaration.
///
///    constructorInitializer ::=
///        [SuperConstructorInvocation]
///      | [ConstructorFieldInitializer]
///      | [RedirectingConstructorInvocation]
sealed class ConstructorInitializerImpl extends AstNodeImpl
    implements ConstructorInitializer {}

/// The name of a constructor.
///
///    constructorName ::=
///        type ('.' identifier)?
abstract final class ConstructorName
    implements AstNode, ConstructorReferenceNode {
  /// Return the name of the constructor, or `null` if the specified constructor
  /// is the unnamed constructor.
  SimpleIdentifier? get name;

  /// Return the token for the period before the constructor name, or `null` if
  /// the specified constructor is the unnamed constructor.
  Token? get period;

  /// Return the name of the type defining the constructor.
  NamedType get type;
}

/// The name of the constructor.
///
///    constructorName ::=
///        type ('.' identifier)?
final class ConstructorNameImpl extends AstNodeImpl implements ConstructorName {
  /// The name of the type defining the constructor.
  NamedTypeImpl _type;

  /// The token for the period before the constructor name, or `null` if the
  /// specified constructor is the unnamed constructor.
  @override
  Token? period;

  /// The name of the constructor, or `null` if the specified constructor is the
  /// unnamed constructor.
  SimpleIdentifierImpl? _name;

  /// The element associated with this constructor name based on static type
  /// information, or `null` if the AST structure has not been resolved or if
  /// this constructor name could not be resolved.
  @override
  ConstructorElement? staticElement;

  /// Initialize a newly created constructor name. The [period] and [name] can
  /// be`null` if the constructor being named is the unnamed constructor.
  ConstructorNameImpl({
    required NamedTypeImpl type,
    required this.period,
    required SimpleIdentifierImpl? name,
  })  : _type = type,
        _name = name {
    _becomeParentOf(_type);
    _becomeParentOf(_name);
  }

  @override
  Token get beginToken => _type.beginToken;

  @override
  Token get endToken {
    if (_name != null) {
      return _name!.endToken;
    }
    return _type.endToken;
  }

  @override
  SimpleIdentifierImpl? get name => _name;

  set name(SimpleIdentifierImpl? name) {
    _name = _becomeParentOf(name);
  }

  @override
  NamedTypeImpl get type => _type;

  set type(NamedTypeImpl type) {
    _type = _becomeParentOf(type);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('type', type)
    ..addToken('period', period)
    ..addNode('name', name);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitConstructorName(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _type.accept(visitor);
    _name?.accept(visitor);
  }
}

/// An expression representing a reference to a constructor, e.g. the expression
/// `List.filled` in `var x = List.filled;`.
///
/// Objects of this type are not produced directly by the parser (because the
/// parser cannot tell whether an identifier refers to a type); they are
/// produced at resolution time.
abstract final class ConstructorReference
    implements Expression, CommentReferableExpression {
  /// The constructor being referenced.
  ConstructorName get constructorName;
}

/// An expression representing a reference to a constructor, e.g. the expression
/// `List.filled` in `var x = List.filled;`.
///
/// Objects of this type are not produced directly by the parser (because the
/// parser cannot tell whether an identifier refers to a type); they are
/// produced at resolution time.
final class ConstructorReferenceImpl extends CommentReferableExpressionImpl
    implements ConstructorReference {
  ConstructorNameImpl _constructorName;

  ConstructorReferenceImpl({
    required ConstructorNameImpl constructorName,
  }) : _constructorName = constructorName {
    _becomeParentOf(_constructorName);
  }

  @override
  Token get beginToken => constructorName.beginToken;

  @override
  ConstructorNameImpl get constructorName => _constructorName;

  set constructorName(ConstructorNameImpl value) {
    _constructorName = _becomeParentOf(value);
  }

  @override
  Token get endToken => constructorName.endToken;

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addNode('constructorName', constructorName);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitConstructorReference(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitConstructorReference(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    constructorName.accept(visitor);
  }
}

/// An AST node that makes reference to a constructor.
abstract final class ConstructorReferenceNode implements AstNode {
  /// Return the element associated with the referenced constructor based on
  /// static type information, or `null` if the AST structure has not been
  /// resolved or if the constructor could not be resolved.
  ConstructorElement? get staticElement;
}

/// The name of a constructor being invoked.
///
///    constructorSelector ::=
///        '.' identifier
abstract final class ConstructorSelector implements AstNode {
  /// Return the constructor name.
  SimpleIdentifier get name;

  /// Return the period before the constructor name.
  Token get period;
}

final class ConstructorSelectorImpl extends AstNodeImpl
    implements ConstructorSelector {
  @override
  final Token period;

  @override
  final SimpleIdentifierImpl name;

  ConstructorSelectorImpl({
    required this.period,
    required this.name,
  }) {
    _becomeParentOf(name);
  }

  @override
  Token get beginToken => period;

  @override
  Token get endToken => name.token;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('period', period)
    ..addNode('name', name);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitConstructorSelector(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {}
}

/// A continue statement.
///
///    continueStatement ::=
///        'continue' [SimpleIdentifier]? ';'
abstract final class ContinueStatement implements Statement {
  /// Return the token representing the 'continue' keyword.
  Token get continueKeyword;

  /// Return the label associated with the statement, or `null` if there is no
  /// label.
  SimpleIdentifier? get label;

  /// Return the semicolon terminating the statement.
  Token get semicolon;

  /// Return the node to which this continue statement is continuing.
  ///
  /// This will be either a [Statement] (in the case of continuing a loop), a
  /// [SwitchMember] (in the case of continuing from one switch case to
  /// another), or `null` if the AST has not yet been resolved or if the target
  /// could not be resolved. Note that if the source code has errors, the
  /// target might be invalid (e.g. the target may be in an enclosing
  /// function).
  AstNode? get target;
}

/// A continue statement.
///
///    continueStatement ::=
///        'continue' [SimpleIdentifier]? ';'
final class ContinueStatementImpl extends StatementImpl
    implements ContinueStatement {
  /// The token representing the 'continue' keyword.
  @override
  final Token continueKeyword;

  /// The label associated with the statement, or `null` if there is no label.
  SimpleIdentifierImpl? _label;

  /// The semicolon terminating the statement.
  @override
  final Token semicolon;

  /// The AstNode which this continue statement is continuing to.  This will be
  /// either a Statement (in the case of continuing a loop) or a SwitchMember
  /// (in the case of continuing from one switch case to another).  Null if the
  /// AST has not yet been resolved or if the target could not be resolved.
  /// Note that if the source code has errors, the target may be invalid (e.g.
  /// the target may be in an enclosing function).
  @override
  AstNode? target;

  /// Initialize a newly created continue statement. The [label] can be `null`
  /// if there is no label associated with the statement.
  ContinueStatementImpl({
    required this.continueKeyword,
    required SimpleIdentifierImpl? label,
    required this.semicolon,
  }) : _label = label {
    _becomeParentOf(_label);
  }

  @override
  Token get beginToken => continueKeyword;

  @override
  Token get endToken => semicolon;

  @override
  SimpleIdentifierImpl? get label => _label;

  set label(SimpleIdentifierImpl? identifier) {
    _label = _becomeParentOf(identifier);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('continueKeyword', continueKeyword)
    ..addNode('label', label)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitContinueStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _label?.accept(visitor);
  }
}

/// A pattern.
///
///    pattern ::=
///        [AssignedVariablePattern]
///      | [DeclaredVariablePattern]
///      | [CastPattern]
///      | [ConstantPattern]
///      | [ListPattern]
///      | [LogicalAndPattern]
///      | [LogicalOrPattern]
///      | [MapPattern]
///      | [NullAssertPattern]
///      | [NullCheckPattern]
///      | [ObjectPattern]
///      | [ParenthesizedPattern]
///      | [RecordPattern]
///      | [RelationalPattern]
sealed class DartPattern implements AstNode, ListPatternElement {
  /// The matched value type, or `null` if the node is not resolved yet.
  DartType? get matchedValueType;

  /// Return the precedence of this pattern.
  ///
  /// The precedence is a positive integer value that defines how the source
  /// code is parsed into an AST. For example `a | b & c` is parsed as `a | (b
  /// & c)` because the precedence of `&` is greater than the precedence of `|`.
  PatternPrecedence get precedence;

  /// If this pattern is a parenthesized pattern, return the result of
  /// unwrapping the pattern inside the parentheses. Otherwise, return this
  /// pattern.
  DartPattern get unParenthesized;
}

/// A pattern.
///
///    pattern ::=
///        [AssignedVariablePattern]
///      | [DeclaredVariablePattern]
///      | [CastPattern]
///      | [ConstantPattern]
///      | [ListPattern]
///      | [LogicalAndPattern]
///      | [LogicalOrPattern]
///      | [MapPattern]
///      | [NullAssertPattern]
///      | [NullCheckPattern]
///      | [ObjectPattern]
///      | [ParenthesizedPattern]
///      | [RecordPattern]
///      | [RelationalPattern]
sealed class DartPatternImpl extends AstNodeImpl
    implements DartPattern, ListPatternElementImpl {
  @override
  DartType? matchedValueType;

  /// Returns the context for this pattern.
  /// * Declaration context:
  ///     [ForEachPartsWithPatternImpl]
  ///     [PatternVariableDeclarationImpl]
  /// * Assignment context: [PatternAssignmentImpl]
  /// * Matching context: [GuardedPatternImpl]
  AstNodeImpl? get patternContext {
    for (DartPatternImpl current = this;;) {
      var parent = current.parent;
      if (parent is MapPatternEntry) {
        parent = parent.parent;
      } else if (parent is PatternFieldImpl) {
        parent = parent.parent;
      } else if (parent is RestPatternElementImpl) {
        parent = parent.parent;
      }
      if (parent is ForEachPartsWithPatternImpl) {
        return parent;
      } else if (parent is PatternVariableDeclarationImpl) {
        return parent;
      } else if (parent is PatternAssignmentImpl) {
        return parent;
      } else if (parent is GuardedPatternImpl) {
        return parent;
      } else if (parent is DartPatternImpl) {
        current = parent;
      } else {
        return null;
      }
    }
  }

  @override
  DartPattern get unParenthesized => this;

  /// The variable pattern, itself, or wrapped in a unary pattern.
  VariablePatternImpl? get variablePattern => null;

  DartType computePatternSchema(ResolverVisitor resolverVisitor);

  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  );
}

/// A node that represents the declaration of one or more names.
///
/// Each declared name is visible within a name scope.
abstract final class Declaration implements AnnotatedNode {
  /// Return the element associated with this declaration, or `null` if either
  /// this node corresponds to a list of declarations or if the AST structure
  /// has not been resolved.
  Element? get declaredElement;
}

/// A node that represents the declaration of one or more names. Each declared
/// name is visible within a name scope.
sealed class DeclarationImpl extends AnnotatedNodeImpl implements Declaration {
  /// Initialize a newly created declaration. Either or both of the [comment]
  /// and [metadata] can be `null` if the declaration does not have the
  /// corresponding attribute.
  DeclarationImpl({
    required super.comment,
    required super.metadata,
  });
}

/// The declaration of a single identifier.
///
///    declaredIdentifier ::=
///        [Annotation] finalConstVarOrType [SimpleIdentifier]
abstract final class DeclaredIdentifier implements Declaration {
  @override
  LocalVariableElement? get declaredElement;

  /// Return `true` if this variable was declared with the 'const' modifier.
  bool get isConst;

  /// Return `true` if this variable was declared with the 'final' modifier.
  /// Variables that are declared with the 'const' modifier will return `false`
  /// even though they are implicitly final.
  bool get isFinal;

  /// Return the token representing either the 'final', 'const' or 'var'
  /// keyword, or `null` if no keyword was used.
  Token? get keyword;

  /// Return the name of the variable being declared.
  Token get name;

  /// Return the name of the declared type of the parameter, or `null` if the
  /// parameter does not have a declared type.
  TypeAnnotation? get type;
}

/// The declaration of a single identifier.
///
///    declaredIdentifier ::=
///        [Annotation] finalConstVarOrType [SimpleIdentifier]
final class DeclaredIdentifierImpl extends DeclarationImpl
    implements DeclaredIdentifier {
  /// The token representing either the 'final', 'const' or 'var' keyword, or
  /// `null` if no keyword was used.
  @override
  final Token? keyword;

  /// The name of the declared type of the parameter, or `null` if the parameter
  /// does not have a declared type.
  TypeAnnotationImpl? _type;

  @override
  final Token name;

  @override
  LocalVariableElementImpl? declaredElement;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the declaration does not have
  /// the corresponding attribute. The [keyword] can be `null` if a type name is
  /// given. The [type] must be `null` if the keyword is 'var'.
  DeclaredIdentifierImpl({
    required super.comment,
    required super.metadata,
    required this.keyword,
    required TypeAnnotationImpl? type,
    required this.name,
  }) : _type = type {
    _becomeParentOf(_type);
  }

  @override
  Token get endToken => name;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return keyword ?? _type?.beginToken ?? name;
  }

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @override
  TypeAnnotationImpl? get type => _type;

  set type(TypeAnnotationImpl? type) {
    _type = _becomeParentOf(type);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('keyword', keyword)
    ..addNode('type', type)
    ..addToken('name', name);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitDeclaredIdentifier(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _type?.accept(visitor);
  }
}

/// A variable pattern that declares a variable.
///
///    variablePattern ::=
///        ( 'var' | 'final' | 'final'? [TypeAnnotation])? [Identifier]
sealed class DeclaredVariablePattern implements VariablePattern {
  /// Return the element associated with this declaration, or `null` if the AST
  /// structure has not been resolved.
  BindPatternVariableElement? get declaredElement;

  /// The 'var' or 'final' keyword.
  Token? get keyword;

  /// The type that the variable is required to match, or `null` if any type is
  /// matched.
  TypeAnnotation? get type;
}

/// A variable pattern.
///
///    variablePattern ::=
///        ( 'var' | 'final' | 'final'? [TypeAnnotation])? [Identifier]
final class DeclaredVariablePatternImpl extends VariablePatternImpl
    implements DeclaredVariablePattern {
  @override
  BindPatternVariableElementImpl? declaredElement;

  @override
  final Token? keyword;

  @override
  final TypeAnnotationImpl? type;

  DeclaredVariablePatternImpl({
    required this.keyword,
    required this.type,
    required super.name,
  }) {
    _becomeParentOf(type);
  }

  @override
  Token get beginToken => keyword ?? type?.beginToken ?? name;

  @override
  Token get endToken => name;

  /// If [keyword] is `final`, returns it.
  Token? get finalKeyword {
    final keyword = this.keyword;
    if (keyword != null && keyword.keyword == Keyword.FINAL) {
      return keyword;
    }
    return null;
  }

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('keyword', keyword)
    ..addNode('type', type)
    ..addToken('name', name);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitDeclaredVariablePattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor
        .analyzeDeclaredVariablePatternSchema(type?.typeOrThrow);
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    final result = resolverVisitor.analyzeDeclaredVariablePattern(context, this,
        declaredElement!, declaredElement!.name, type?.typeOrThrow);
    declaredElement!.type = result.staticType;

    resolverVisitor.checkPatternNeverMatchesValueType(
      context: context,
      pattern: this,
      requiredType: result.staticType,
    );
  }

  @override
  void visitChildren(AstVisitor visitor) {
    type?.accept(visitor);
  }
}

/// A formal parameter with a default value.
///
/// There are two kinds of parameters that are both represented by this class:
/// named formal parameters and positional formal parameters.
///
///    defaultFormalParameter ::=
///        [NormalFormalParameter] ('=' [Expression])?
///
///    defaultNamedParameter ::=
///        [NormalFormalParameter] (':' [Expression])?
abstract final class DefaultFormalParameter implements FormalParameter {
  /// Return the expression computing the default value for the parameter, or
  /// `null` if there is no default value.
  Expression? get defaultValue;

  /// Return the formal parameter with which the default value is associated.
  NormalFormalParameter get parameter;

  /// Return the token separating the parameter from the default value, or
  /// `null` if there is no default value.
  Token? get separator;
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
final class DefaultFormalParameterImpl extends FormalParameterImpl
    implements DefaultFormalParameter {
  /// The formal parameter with which the default value is associated.
  NormalFormalParameterImpl _parameter;

  /// The kind of this parameter.
  @override
  ParameterKind kind;

  /// The token separating the parameter from the default value, or `null` if
  /// there is no default value.
  @override
  final Token? separator;

  /// The expression computing the default value for the parameter, or `null` if
  /// there is no default value.
  ExpressionImpl? _defaultValue;

  /// Initialize a newly created default formal parameter. The [separator] and
  /// [defaultValue] can be `null` if there is no default value.
  DefaultFormalParameterImpl({
    required NormalFormalParameterImpl parameter,
    required this.kind,
    required this.separator,
    required ExpressionImpl? defaultValue,
  })  : _parameter = parameter,
        _defaultValue = defaultValue {
    _becomeParentOf(_parameter);
    _becomeParentOf(_defaultValue);
  }

  @override
  Token get beginToken => _parameter.beginToken;

  @override
  Token? get covariantKeyword => null;

  @override
  ParameterElementImpl? get declaredElement => _parameter.declaredElement;

  @override
  ExpressionImpl? get defaultValue => _defaultValue;

  set defaultValue(ExpressionImpl? expression) {
    _defaultValue = _becomeParentOf(expression);
  }

  @override
  Token get endToken {
    if (_defaultValue != null) {
      return _defaultValue!.endToken;
    }
    return _parameter.endToken;
  }

  @override
  bool get isConst => _parameter.isConst;

  @override
  bool get isExplicitlyTyped => _parameter.isExplicitlyTyped;

  @override
  bool get isFinal => _parameter.isFinal;

  @override
  NodeListImpl<AnnotationImpl> get metadata => _parameter.metadata;

  @override
  Token? get name => _parameter.name;

  @override
  NormalFormalParameterImpl get parameter => _parameter;

  set parameter(NormalFormalParameterImpl formalParameter) {
    _parameter = _becomeParentOf(formalParameter);
  }

  @override
  Token? get requiredKeyword => null;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('parameter', parameter)
    ..addToken('separator', separator)
    ..addNode('defaultValue', defaultValue);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitDefaultFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _parameter.accept(visitor);
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
sealed class Directive implements AnnotatedNode {
  /// Return the element associated with this directive, or `null` if the AST
  /// structure has not been resolved.
  Element? get element;
}

/// A node that represents a directive.
///
///    directive ::=
///        [AugmentationImportDirective]
///      | [ExportDirective]
///      | [ImportDirective]
///      | [LibraryDirective]
///      | [PartDirective]
///      | [PartOfDirective]
sealed class DirectiveImpl extends AnnotatedNodeImpl implements Directive {
  /// The element associated with this directive, or `null` if the AST structure
  /// has not been resolved or if this directive could not be resolved.
  Element? _element;

  /// Initialize a newly create directive. Either or both of the [comment] and
  /// [metadata] can be `null` if the directive does not have the corresponding
  /// attribute.
  DirectiveImpl({
    required super.comment,
    required super.metadata,
  });

  @override
  Element? get element => _element;

  /// Set the element associated with this directive to be the given [element].
  set element(Element? element) {
    _element = element;
  }
}

/// A do statement.
///
///    doStatement ::=
///        'do' [Statement] 'while' '(' [Expression] ')' ';'
abstract final class DoStatement implements Statement {
  /// Return the body of the loop.
  Statement get body;

  /// Return the condition that determines when the loop will terminate.
  Expression get condition;

  /// Return the token representing the 'do' keyword.
  Token get doKeyword;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the right parenthesis.
  Token get rightParenthesis;

  /// Return the semicolon terminating the statement.
  Token get semicolon;

  /// Return the token representing the 'while' keyword.
  Token get whileKeyword;
}

/// A do statement.
///
///    doStatement ::=
///        'do' [Statement] 'while' '(' [Expression] ')' ';'
final class DoStatementImpl extends StatementImpl implements DoStatement {
  /// The token representing the 'do' keyword.
  @override
  final Token doKeyword;

  /// The body of the loop.
  StatementImpl _body;

  /// The token representing the 'while' keyword.
  @override
  final Token whileKeyword;

  /// The left parenthesis.
  @override
  final Token leftParenthesis;

  /// The condition that determines when the loop will terminate.
  ExpressionImpl _condition;

  /// The right parenthesis.
  @override
  final Token rightParenthesis;

  /// The semicolon terminating the statement.
  @override
  final Token semicolon;

  /// Initialize a newly created do loop.
  DoStatementImpl({
    required this.doKeyword,
    required StatementImpl body,
    required this.whileKeyword,
    required this.leftParenthesis,
    required ExpressionImpl condition,
    required this.rightParenthesis,
    required this.semicolon,
  })  : _body = body,
        _condition = condition {
    _becomeParentOf(_body);
    _becomeParentOf(_condition);
  }

  @override
  Token get beginToken => doKeyword;

  @override
  StatementImpl get body => _body;

  set body(StatementImpl statement) {
    _body = _becomeParentOf(statement);
  }

  @override
  ExpressionImpl get condition => _condition;

  set condition(ExpressionImpl expression) {
    _condition = _becomeParentOf(expression);
  }

  @override
  Token get endToken => semicolon;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('doKeyword', doKeyword)
    ..addNode('body', body)
    ..addToken('whileKeyword', whileKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('condition', condition)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitDoStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _body.accept(visitor);
    _condition.accept(visitor);
  }
}

/// A dotted name, used in a configuration within an import or export directive.
///
///    dottedName ::=
///        [SimpleIdentifier] ('.' [SimpleIdentifier])*
abstract final class DottedName implements AstNode {
  /// Return the components of the identifier.
  NodeList<SimpleIdentifier> get components;
}

/// A dotted name, used in a configuration within an import or export directive.
///
///    dottedName ::=
///        [SimpleIdentifier] ('.' [SimpleIdentifier])*
final class DottedNameImpl extends AstNodeImpl implements DottedName {
  /// The components of the identifier.
  final NodeListImpl<SimpleIdentifierImpl> _components = NodeListImpl._();

  /// Initialize a newly created dotted name.
  DottedNameImpl({
    required List<SimpleIdentifierImpl> components,
  }) {
    _components._initialize(this, components);
  }

  @override
  Token get beginToken => _components.beginToken!;

  @override
  NodeListImpl<SimpleIdentifierImpl> get components => _components;

  @override
  Token get endToken => _components.endToken!;

  @override
  // TODO(paulberry): add "." tokens.
  ChildEntities get _childEntities =>
      ChildEntities()..addNodeList('components', components);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitDottedName(this);

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
abstract final class DoubleLiteral implements Literal {
  /// Return the token representing the literal.
  Token get literal;

  /// Return the value of the literal.
  double get value;
}

/// A floating point literal expression.
///
///    doubleLiteral ::=
///        decimalDigit+ ('.' decimalDigit*)? exponent?
///      | '.' decimalDigit+ exponent?
///
///    exponent ::=
///        ('e' | 'E') ('+' | '-')? decimalDigit+
final class DoubleLiteralImpl extends LiteralImpl implements DoubleLiteral {
  /// The token representing the literal.
  @override
  final Token literal;

  /// The value of the literal.
  @override
  double value;

  /// Initialize a newly created floating point literal.
  DoubleLiteralImpl({
    required this.literal,
    required this.value,
  });

  @override
  Token get beginToken => literal;

  @override
  Token get endToken => literal;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('literal', literal);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitDoubleLiteral(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitDoubleLiteral(this, contextType: contextType);
  }

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
abstract final class EmptyFunctionBody implements FunctionBody {
  /// Return the token representing the semicolon that marks the end of the
  /// function body.
  Token get semicolon;
}

/// An empty function body, which can only appear in constructors or abstract
/// methods.
///
///    emptyFunctionBody ::=
///        ';'
final class EmptyFunctionBodyImpl extends FunctionBodyImpl
    implements EmptyFunctionBody {
  /// The token representing the semicolon that marks the end of the function
  /// body.
  @override
  final Token semicolon;

  /// Initialize a newly created function body.
  EmptyFunctionBodyImpl({
    required this.semicolon,
  });

  @override
  Token get beginToken => semicolon;

  @override
  Token get endToken => semicolon;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitEmptyFunctionBody(this);

  @override
  DartType resolve(ResolverVisitor resolver, DartType? imposedType) =>
      resolver.visitEmptyFunctionBody(this, imposedType: imposedType);

  @override
  void visitChildren(AstVisitor visitor) {
    // Empty function bodies have no children.
  }
}

/// An empty statement.
///
///    emptyStatement ::=
///        ';'
abstract final class EmptyStatement implements Statement {
  /// Return the semicolon terminating the statement.
  Token get semicolon;
}

/// An empty statement.
///
///    emptyStatement ::=
///        ';'
final class EmptyStatementImpl extends StatementImpl implements EmptyStatement {
  /// The semicolon terminating the statement.
  @override
  final Token semicolon;

  /// Initialize a newly created empty statement.
  EmptyStatementImpl({
    required this.semicolon,
  });

  @override
  Token get beginToken => semicolon;

  @override
  Token get endToken => semicolon;

  @override
  bool get isSynthetic => semicolon.isSynthetic;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitEmptyStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// The arguments part of an enum constant.
///
///    enumConstantArguments ::=
///        [TypeArgumentList]? [ConstructorSelector]? [ArgumentList]
abstract final class EnumConstantArguments implements AstNode {
  /// Return the explicit arguments (there are always implicit `index` and
  /// `name` leading arguments) to the invoked constructor.
  ArgumentList get argumentList;

  /// Return the selector of the constructor that is invoked by this enum
  /// constant, or `null` if the default constructor is invoked.
  ConstructorSelector? get constructorSelector;

  /// Return the type arguments applied to the enclosing enum declaration
  /// when invoking the constructor, or `null` if no type arguments were
  /// provided.
  TypeArgumentList? get typeArguments;
}

final class EnumConstantArgumentsImpl extends AstNodeImpl
    implements EnumConstantArguments {
  @override
  final TypeArgumentListImpl? typeArguments;

  @override
  final ConstructorSelectorImpl? constructorSelector;

  @override
  final ArgumentListImpl argumentList;

  EnumConstantArgumentsImpl({
    required this.typeArguments,
    required this.constructorSelector,
    required this.argumentList,
  }) {
    _becomeParentOf(typeArguments);
    _becomeParentOf(constructorSelector);
    _becomeParentOf(argumentList);
  }

  @override
  Token get beginToken =>
      (typeArguments ?? constructorSelector ?? argumentList).beginToken;

  @override
  Token get endToken => argumentList.endToken;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('typeArguments', typeArguments)
    ..addNode('constructorSelector', constructorSelector)
    ..addNode('argumentList', argumentList);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitEnumConstantArguments(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    typeArguments?.accept(visitor);
    constructorSelector?.accept(visitor);
    argumentList.accept(visitor);
  }
}

/// The declaration of an enum constant.
abstract final class EnumConstantDeclaration implements Declaration {
  /// Return the explicit arguments (there are always implicit `index` and
  /// `name` leading arguments) to the invoked constructor, or `null` if this
  /// constant does not provide any explicit arguments.
  EnumConstantArguments? get arguments;

  /// Return the constructor that is invoked by this enum constant, or `null`
  /// if the AST structure has not been resolved, or if the constructor could
  /// not be resolved.
  ConstructorElement? get constructorElement;

  @override
  FieldElement? get declaredElement;

  /// Return the name of the constant.
  Token get name;
}

/// The declaration of an enum constant.
final class EnumConstantDeclarationImpl extends DeclarationImpl
    implements EnumConstantDeclaration {
  @override
  final Token name;

  @override
  FieldElementImpl? declaredElement;

  @override
  final EnumConstantArgumentsImpl? arguments;

  @override
  ConstructorElement? constructorElement;

  /// Initialize a newly created enum constant declaration. Either or both of
  /// the [documentationComment] and [metadata] can be `null` if the constant
  /// does not have the corresponding attribute.
  EnumConstantDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.name,
    required this.arguments,
  }) {
    _becomeParentOf(arguments);
  }

  @override
  Token get endToken => arguments?.endToken ?? name;

  @override
  Token get firstTokenAfterCommentAndMetadata => name;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('name', name)
    ..addNode('arguments', arguments);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitEnumConstantDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    arguments?.accept(visitor);
  }
}

/// The declaration of an enumeration.
///
///    enumType ::=
///        metadata 'enum' name [TypeParameterList]?
///        [WithClause]? [ImplementsClause]? '{' [SimpleIdentifier]
///        (',' [SimpleIdentifier])* (';' [ClassMember]+)? '}'
abstract final class EnumDeclaration implements NamedCompilationUnitMember {
  /// Return the enumeration constants being declared.
  NodeList<EnumConstantDeclaration> get constants;

  @override
  EnumElement? get declaredElement;

  /// Return the 'enum' keyword.
  Token get enumKeyword;

  /// Returns the `implements` clause for the enumeration, or `null` if the
  /// enumeration does not implement any interfaces.
  ImplementsClause? get implementsClause;

  /// Return the left curly bracket.
  Token get leftBracket;

  /// Return the members declared by the enumeration.
  NodeList<ClassMember> get members;

  /// Return the right curly bracket.
  Token get rightBracket;

  /// Return the optional semicolon after the last constant.
  Token? get semicolon;

  /// Returns the type parameters for the enumeration, or `null` if the
  /// enumeration does not have any type parameters.
  TypeParameterList? get typeParameters;

  /// Return the `with` clause for the enumeration, or `null` if the
  /// enumeration does not have a `with` clause.
  WithClause? get withClause;
}

/// The declaration of an enumeration.
///
///    enumType ::=
///        metadata 'enum' [SimpleIdentifier] [TypeParameterList]?
///        [WithClause]? [ImplementsClause]? '{' [SimpleIdentifier]
///        (',' [SimpleIdentifier])* (';' [ClassMember]+)? '}'
final class EnumDeclarationImpl extends NamedCompilationUnitMemberImpl
    implements EnumDeclaration {
  /// The 'enum' keyword.
  @override
  final Token enumKeyword;

  /// The type parameters, or `null` if the enumeration does not have any
  /// type parameters.
  TypeParameterListImpl? _typeParameters;

  /// The `with` clause for the enumeration, or `null` if the class does not
  /// have a `with` clause.
  WithClauseImpl? _withClause;

  /// The `implements` clause for the enumeration, or `null` if the enumeration
  /// does not implement any interfaces.
  ImplementsClauseImpl? _implementsClause;

  /// The left curly bracket.
  @override
  final Token leftBracket;

  /// The enumeration constants being declared.
  final NodeListImpl<EnumConstantDeclarationImpl> _constants = NodeListImpl._();

  @override
  final Token? semicolon;

  /// The members defined by the enum.
  final NodeListImpl<ClassMemberImpl> _members = NodeListImpl._();

  /// The right curly bracket.
  @override
  final Token rightBracket;

  @override
  EnumElementImpl? declaredElement;

  /// Initialize a newly created enumeration declaration. Either or both of the
  /// [comment] and [metadata] can be `null` if the declaration does not have
  /// the corresponding attribute. The list of [constants] must contain at least
  /// one value.
  EnumDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.enumKeyword,
    required super.name,
    required TypeParameterListImpl? typeParameters,
    required WithClauseImpl? withClause,
    required ImplementsClauseImpl? implementsClause,
    required this.leftBracket,
    required List<EnumConstantDeclarationImpl> constants,
    required this.semicolon,
    required List<ClassMemberImpl> members,
    required this.rightBracket,
  })  : _typeParameters = typeParameters,
        _withClause = withClause,
        _implementsClause = implementsClause {
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_withClause);
    _becomeParentOf(_implementsClause);
    _constants._initialize(this, constants);
    _members._initialize(this, members);
  }

  @override
  NodeListImpl<EnumConstantDeclarationImpl> get constants => _constants;

  @override
  Token get endToken => rightBracket;

  @override
  Token get firstTokenAfterCommentAndMetadata => enumKeyword;

  @override
  ImplementsClauseImpl? get implementsClause => _implementsClause;

  set implementsClause(ImplementsClauseImpl? implementsClause) {
    _implementsClause = _becomeParentOf(implementsClause);
  }

  @override
  NodeListImpl<ClassMemberImpl> get members => _members;

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  WithClauseImpl? get withClause => _withClause;

  set withClause(WithClauseImpl? withClause) {
    _withClause = _becomeParentOf(withClause);
  }

  @override
  // TODO(brianwilkerson) Add commas?
  ChildEntities get _childEntities => super._childEntities
    ..addToken('enumKeyword', enumKeyword)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addNode('withClause', withClause)
    ..addNode('implementsClause', implementsClause)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('constants', constants)
    ..addToken('semicolon', semicolon)
    ..addNodeList('members', members)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitEnumDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _typeParameters?.accept(visitor);
    _withClause?.accept(visitor);
    _implementsClause?.accept(visitor);
    _constants.accept(visitor);
    _members.accept(visitor);
  }
}

/// An export directive.
///
///    exportDirective ::=
///        [Annotation] 'export' [StringLiteral] [Combinator]* ';'
abstract final class ExportDirective implements NamespaceDirective {
  /// Return the element associated with this directive, or `null` if the AST
  /// structure has not been resolved.
  @override
  LibraryExportElement? get element;

  /// The token representing the 'export' keyword.
  Token get exportKeyword;
}

/// An export directive.
///
///    exportDirective ::=
///        [Annotation] 'export' [StringLiteral] [Combinator]* ';'
final class ExportDirectiveImpl extends NamespaceDirectiveImpl
    implements ExportDirective {
  @override
  final Token exportKeyword;

  /// Initialize a newly created export directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute. The list of [combinators] can be `null` if there
  /// are no combinators.
  ExportDirectiveImpl({
    required super.comment,
    required super.metadata,
    required this.exportKeyword,
    required super.uri,
    required super.configurations,
    required super.combinators,
    required super.semicolon,
  });

  @override
  LibraryExportElementImpl? get element {
    return super.element as LibraryExportElementImpl?;
  }

  @override
  Token get firstTokenAfterCommentAndMetadata => exportKeyword;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('exportKeyword', exportKeyword)
    ..addNode('uri', uri)
    ..addNodeList('combinators', combinators)
    ..addNodeList('configurations', configurations)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitExportDirective(this);

  @override
  void visitChildren(AstVisitor visitor) {
    configurations.accept(visitor);
    super.visitChildren(visitor);
    combinators.accept(visitor);
  }
}

/// A node that represents an expression.
///
///    expression ::=
///        [AssignmentExpression]
///      | [ConditionalExpression] cascadeSection*
///      | [ThrowExpression]
abstract final class Expression implements CollectionElement {
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
  bool get inConstantContext;

  /// Return `true` if this expression is syntactically valid for the LHS of an
  /// [AssignmentExpression].
  bool get isAssignable;

  /// Return the precedence of this expression.
  ///
  /// The precedence is a positive integer value that defines how the source
  /// code is parsed into an AST. For example `a * b + c` is parsed as `(a * b)
  /// + c` because the precedence of `*` is greater than the precedence of `+`.
  Precedence get precedence;

  /// If this expression is an argument to an invocation, and the AST structure
  /// has been resolved, and the function being invoked is known based on static
  /// type information, and this expression corresponds to one of the parameters
  /// of the function being invoked, then return the parameter element
  /// representing the parameter to which the value of this expression will be
  /// bound. Otherwise, return `null`.
  ParameterElement? get staticParameterElement;

  /// Return the static type of this expression, or `null` if the AST structure
  /// has not been resolved.
  DartType? get staticType;

  /// If this expression is a parenthesized expression, return the result of
  /// unwrapping the expression inside the parentheses. Otherwise, return this
  /// expression.
  Expression get unParenthesized;
}

/// A function body consisting of a single expression.
///
///    expressionFunctionBody ::=
///        'async'? '=>' [Expression] ';'
abstract final class ExpressionFunctionBody implements FunctionBody {
  /// Return the expression representing the body of the function.
  Expression get expression;

  /// Return the token introducing the expression that represents the body of the
  /// function.
  Token get functionDefinition;

  /// Return the semicolon terminating the statement.
  Token? get semicolon;
}

/// A function body consisting of a single expression.
///
///    expressionFunctionBody ::=
///        'async'? '=>' [Expression] ';'
final class ExpressionFunctionBodyImpl extends FunctionBodyImpl
    implements ExpressionFunctionBody {
  /// The token representing the 'async' keyword, or `null` if there is no such
  /// keyword.
  @override
  final Token? keyword;

  /// The star optionally following the 'async' or 'sync' keyword, or `null` if
  /// there is wither no such keyword or no star.
  ///
  /// It is an error for an expression function body to feature the star, but
  /// the parser will accept it.
  @override
  final Token? star;

  /// The token introducing the expression that represents the body of the
  /// function.
  @override
  final Token functionDefinition;

  /// The expression representing the body of the function.
  ExpressionImpl _expression;

  /// The semicolon terminating the statement.
  @override
  final Token? semicolon;

  /// Initialize a newly created function body consisting of a block of
  /// statements. The [keyword] can be `null` if the function body is not an
  /// async function body.
  ExpressionFunctionBodyImpl({
    required this.keyword,
    required this.star,
    required this.functionDefinition,
    required ExpressionImpl expression,
    required this.semicolon,
  }) : _expression = expression {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken {
    if (keyword != null) {
      return keyword!;
    }
    return functionDefinition;
  }

  @override
  Token get endToken {
    if (semicolon != null) {
      return semicolon!;
    }
    return _expression.endToken;
  }

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  bool get isAsynchronous => keyword?.lexeme == Keyword.ASYNC.lexeme;

  @override
  bool get isGenerator => star != null;

  @override
  bool get isSynchronous => keyword?.lexeme != Keyword.ASYNC.lexeme;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('keyword', keyword)
    ..addToken('star', star)
    ..addToken('functionDefinition', functionDefinition)
    ..addNode('expression', expression)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitExpressionFunctionBody(this);

  @override
  DartType resolve(ResolverVisitor resolver, DartType? imposedType) =>
      resolver.visitExpressionFunctionBody(this, imposedType: imposedType);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
  }
}

/// A node that represents an expression.
///
///    expression ::=
///        [AssignmentExpression]
///      | [ConditionalExpression] cascadeSection*
///      | [ThrowExpression]
sealed class ExpressionImpl extends AstNodeImpl
    implements CollectionElementImpl, Expression {
  /// The static type of this expression, or `null` if the AST structure has not
  /// been resolved.
  @override
  DartType? staticType;

  @override
  bool get inConstantContext {
    AstNode child = this;
    while (child is Expression ||
        child is ArgumentList ||
        child is MapLiteralEntry ||
        child is SpreadElement ||
        child is IfElement ||
        child is ForElement) {
      var parent = child.parent;
      if (parent is ConstantContextForExpressionImpl) {
        return true;
      } else if (parent is ConstantPatternImpl) {
        return parent.constKeyword != null;
      } else if (parent is EnumConstantArguments) {
        return true;
      } else if (parent is TypedLiteralImpl && parent.constKeyword != null) {
        // Inside an explicitly `const` list or map literal.
        return true;
      } else if (parent is InstanceCreationExpression &&
          parent.keyword?.keyword == Keyword.CONST) {
        // Inside an explicitly `const` instance creation expression.
        return true;
      } else if (parent is Annotation) {
        // Inside an annotation.
        return true;
      } else if (parent is RecordLiteral && parent.constKeyword != null) {
        return true;
      } else if (parent is VariableDeclaration) {
        var grandParent = parent.parent;
        // Inside the initializer for a `const` variable declaration.
        return grandParent is VariableDeclarationList &&
            grandParent.keyword?.keyword == Keyword.CONST;
      } else if (parent is SwitchCase) {
        // Inside a switch case.
        return true;
      } else if (parent == null) {
        break;
      }
      child = parent;
    }
    return false;
  }

  @override
  bool get isAssignable => false;

  @override
  ParameterElement? get staticParameterElement {
    final parent = this.parent;
    if (parent is ArgumentListImpl) {
      return parent._getStaticParameterElementFor(this);
    } else if (parent is IndexExpressionImpl) {
      if (identical(parent.index, this)) {
        return parent._staticParameterElementForIndex;
      }
    } else if (parent is BinaryExpressionImpl) {
      // TODO(scheglov) https://github.com/dart-lang/sdk/issues/49102
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
      // TODO(scheglov) This does not look right, there is no element for
      // the operand, for `a++` we invoke `a = a + 1`, so the parameter
      // is for `1`, not for `a`.
      return parent._staticParameterElementForOperand;
    } else if (parent is PostfixExpressionImpl) {
      // TODO(scheglov) The same as above.
      return parent._staticParameterElementForOperand;
    }
    return null;
  }

  @override
  ExpressionImpl get unParenthesized => this;

  @override
  void resolveElement(
      ResolverVisitor resolver, CollectionLiteralContext? context) {
    resolver.analyzeExpression(this, context?.elementType);
  }

  /// Dispatches this expression to the [resolver], with the given [contextType]
  /// information.
  ///
  /// Note: most code shouldn't call this method directly, but should instead
  /// call [ResolverVisitor.analyzeExpression], which has some special logic for
  /// handling dynamic contexts.
  void resolveExpression(ResolverVisitor resolver, DartType contextType);
}

/// An expression used as a statement.
///
///    expressionStatement ::=
///        [Expression]? ';'
abstract final class ExpressionStatement implements Statement {
  /// Return the expression that comprises the statement.
  Expression get expression;

  /// Return the semicolon terminating the statement, or `null` if the
  /// expression is a function expression and therefore isn't followed by a
  /// semicolon.
  Token? get semicolon;
}

/// An expression used as a statement.
///
///    expressionStatement ::=
///        [Expression]? ';'
final class ExpressionStatementImpl extends StatementImpl
    implements ExpressionStatement {
  /// The expression that comprises the statement.
  ExpressionImpl _expression;

  /// The semicolon terminating the statement, or `null` if the expression is a
  /// function expression and therefore isn't followed by a semicolon.
  @override
  final Token? semicolon;

  /// Initialize a newly created expression statement.
  ExpressionStatementImpl({
    required ExpressionImpl expression,
    required this.semicolon,
  }) : _expression = expression {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => _expression.beginToken;

  @override
  Token get endToken {
    if (semicolon != null) {
      return semicolon!;
    }
    return _expression.endToken;
  }

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  bool get isSynthetic =>
      _expression.isSynthetic && (semicolon == null || semicolon!.isSynthetic);

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('expression', expression)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitExpressionStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
  }
}

/// The "extends" clause in a class declaration.
///
///    extendsClause ::=
///        'extends' [NamedType]
abstract final class ExtendsClause implements AstNode {
  /// Return the token representing the 'extends' keyword.
  Token get extendsKeyword;

  /// Return the name of the class that is being extended.
  NamedType get superclass;
}

/// The "extends" clause in a class declaration.
///
///    extendsClause ::=
///        'extends' [NamedType]
final class ExtendsClauseImpl extends AstNodeImpl implements ExtendsClause {
  /// The token representing the 'extends' keyword.
  @override
  final Token extendsKeyword;

  /// The name of the class that is being extended.
  NamedTypeImpl _superclass;

  /// Initialize a newly created extends clause.
  ExtendsClauseImpl({
    required this.extendsKeyword,
    required NamedTypeImpl superclass,
  }) : _superclass = superclass {
    _becomeParentOf(_superclass);
  }

  @override
  Token get beginToken => extendsKeyword;

  @override
  Token get endToken => _superclass.endToken;

  @override
  NamedTypeImpl get superclass => _superclass;

  set superclass(NamedTypeImpl name) {
    _superclass = _becomeParentOf(name);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('extendsKeyword', extendsKeyword)
    ..addNode('superclass', superclass);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitExtendsClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _superclass.accept(visitor);
  }
}

/// The declaration of an extension of a type.
///
///    extension ::=
///        'extension' [SimpleIdentifier]? [TypeParameterList]?
///        'on' [TypeAnnotation] [ShowClause]? [HideClause]?
///        '{' [ClassMember]* '}'
abstract final class ExtensionDeclaration implements CompilationUnitMember {
  @override
  ExtensionElement? get declaredElement;

  /// Return the type that is being extended.
  TypeAnnotation get extendedType;

  /// Return the token representing the 'extension' keyword.
  Token get extensionKeyword;

  /// Return the left curly bracket.
  Token get leftBracket;

  /// Return the members being added to the extended class.
  NodeList<ClassMember> get members;

  /// Return the name of the extension, or `null` if the extension does not have
  /// a name.
  Token? get name;

  /// Return the token representing the 'on' keyword.
  Token get onKeyword;

  /// Return the right curly bracket.
  Token get rightBracket;

  /// Return the token representing the 'type' keyword.
  Token? get typeKeyword;

  /// Return the type parameters for the extension, or `null` if the extension
  /// does not have any type parameters.
  TypeParameterList? get typeParameters;
}

/// The declaration of an extension of a type.
///
///    extension ::=
///        'extension' [SimpleIdentifier] [TypeParameterList]?
///        'on' [TypeAnnotation] '{' [ClassMember]* '}'
final class ExtensionDeclarationImpl extends CompilationUnitMemberImpl
    implements ExtensionDeclaration {
  @override
  final Token extensionKeyword;

  @override
  final Token? typeKeyword;

  @override
  final Token? name;

  /// The type parameters for the extension, or `null` if the extension does not
  /// have any type parameters.
  TypeParameterListImpl? _typeParameters;

  @override
  final Token onKeyword;

  /// The type that is being extended.
  TypeAnnotationImpl _extendedType;

  @override
  final Token leftBracket;

  /// The members being added to the extended class.
  final NodeListImpl<ClassMemberImpl> _members = NodeListImpl._();

  @override
  final Token rightBracket;

  @override
  ExtensionElementImpl? declaredElement;

  ExtensionDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.extensionKeyword,
    required this.typeKeyword,
    required this.name,
    required TypeParameterListImpl? typeParameters,
    required this.onKeyword,
    required TypeAnnotationImpl extendedType,
    required this.leftBracket,
    required List<ClassMemberImpl> members,
    required this.rightBracket,
  })  : _typeParameters = typeParameters,
        _extendedType = extendedType {
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_extendedType);
    _members._initialize(this, members);
  }

  @override
  Token get endToken => rightBracket;

  @override
  TypeAnnotationImpl get extendedType => _extendedType;

  set extendedType(TypeAnnotationImpl extendedClass) {
    _extendedType = _becomeParentOf(extendedClass);
  }

  @override
  Token get firstTokenAfterCommentAndMetadata => extensionKeyword;

  @override
  NodeListImpl<ClassMemberImpl> get members => _members;

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('extensionKeyword', extensionKeyword)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addToken('onKeyword', onKeyword)
    ..addNode('extendedType', extendedType)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('members', members)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitExtensionDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _typeParameters?.accept(visitor);
    _extendedType.accept(visitor);
    _members.accept(visitor);
  }
}

/// An override to force resolution to choose a member from a specific
/// extension.
///
///    extensionOverride ::=
///        [Identifier] [TypeArgumentList]? [ArgumentList]
abstract final class ExtensionOverride implements Expression {
  /// Return the list of arguments to the override. In valid code this will
  /// contain a single argument, which evaluates to the object being extended.
  ArgumentList get argumentList;

  /// The forced extension element.
  ExtensionElement get element;

  /// Return the actual type extended by this override, produced by applying
  /// [typeArgumentTypes] to the generic type extended by the extension.
  ///
  /// Return `null` if the AST structure has not been resolved.
  DartType? get extendedType;

  /// The optional import prefix before [name].
  ImportPrefixReference? get importPrefix;

  /// Whether this override is null aware (as opposed to non-null).
  bool get isNullAware;

  /// The name of the extension being selected.
  Token get name;

  /// Return the type arguments to be applied to the extension, or `null` if no
  /// type arguments were provided.
  TypeArgumentList? get typeArguments;

  /// Return the actual type arguments to be applied to the extension, either
  /// explicitly specified in [typeArguments], or inferred.
  ///
  /// If the AST has been resolved, never returns `null`, returns an empty list
  /// if the extension does not have type parameters.
  ///
  /// Return `null` if the AST structure has not been resolved.
  List<DartType>? get typeArgumentTypes;
}

/// An override to force resolution to choose a member from a specific
/// extension.
///
///    extensionOverride ::=
///        [Identifier] [TypeArgumentList]? [ArgumentList]
final class ExtensionOverrideImpl extends ExpressionImpl
    implements ExtensionOverride {
  @override
  final ImportPrefixReferenceImpl? importPrefix;

  @override
  final Token name;

  @override
  final ExtensionElement element;

  /// The type arguments to be applied to the extension, or `null` if no type
  /// arguments were provided.
  TypeArgumentListImpl? _typeArguments;

  /// The list of arguments to the override. In valid code this will contain a
  /// single argument, which evaluates to the object being extended.
  ArgumentListImpl _argumentList;

  @override
  List<DartType>? typeArgumentTypes;

  @override
  DartType? extendedType;

  ExtensionOverrideImpl({
    required this.importPrefix,
    required this.name,
    required TypeArgumentListImpl? typeArguments,
    required ArgumentListImpl argumentList,
    required this.element,
  })  : _typeArguments = typeArguments,
        _argumentList = argumentList {
    _becomeParentOf(importPrefix);
    _becomeParentOf(_typeArguments);
    _becomeParentOf(_argumentList);
  }

  @override
  ArgumentListImpl get argumentList => _argumentList;

  set argumentList(ArgumentListImpl argumentList) {
    _argumentList = _becomeParentOf(argumentList);
  }

  @override
  Token get beginToken => importPrefix?.name ?? name;

  @override
  Token get endToken => _argumentList.endToken;

  @override
  bool get isNullAware {
    var nextType = argumentList.endToken.next!.type;
    return nextType == TokenType.QUESTION_PERIOD ||
        nextType == TokenType.QUESTION;
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  set typeArguments(TypeArgumentListImpl? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('importPrefix', importPrefix)
    ..addToken('name', name)
    ..addNode('typeArguments', typeArguments)
    ..addNode('argumentList', argumentList);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitExtensionOverride(this);
  }

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitExtensionOverride(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    importPrefix?.accept(visitor);
    _typeArguments?.accept(visitor);
    _argumentList.accept(visitor);
  }
}

/// The declaration of one or more fields of the same type.
///
///    fieldDeclaration ::=
///        'static' 'const' <type>? <staticFinalDeclarationList>
///      | 'static' 'final' <type>? <staticFinalDeclarationList>
///      | 'static' 'late' 'final' <type>? <initializedIdentifierList>
///      | 'static' 'late'? <varOrType> <initializedIdentifierList>
///      | 'covariant' 'late'? <varOrType> <initializedIdentifierList>
///      | 'late'? 'final' <type>? <initializedIdentifierList>
///      | 'late'? <varOrType> <initializedIdentifierList>
///      | 'external' ('static'? <finalVarOrType> | 'covariant' <varOrType>)
///            <identifierList>
///      | 'abstract' (<finalVarOrType> | 'covariant' <varOrType>)
///            <identifierList>
///
/// (Note: there is no <fieldDeclaration> production in the grammar; this is a
/// subset of the grammar production <declaration>, which encompasses everything
/// that can appear inside a class declaration except methods).
///
/// Prior to the 'extension-methods' experiment, these nodes were always
/// children of a class declaration. When the experiment is enabled, these nodes
/// can also be children of an extension declaration.
abstract final class FieldDeclaration implements ClassMember {
  /// The `abstract` keyword, or `null` if the keyword was not used.
  Token? get abstractKeyword;

  /// The 'covariant' keyword, or `null` if the keyword was not used.
  Token? get covariantKeyword;

  /// The `external` keyword, or `null` if the keyword was not used.
  Token? get externalKeyword;

  /// Return the fields being declared.
  VariableDeclarationList get fields;

  /// Return `true` if the fields are declared to be static.
  bool get isStatic;

  /// Return the semicolon terminating the declaration.
  Token get semicolon;

  /// Return the token representing the 'static' keyword, or `null` if the
  /// fields are not static.
  Token? get staticKeyword;
}

/// The declaration of one or more fields of the same type.
///
///    fieldDeclaration ::=
///        'static'? [VariableDeclarationList] ';'
final class FieldDeclarationImpl extends ClassMemberImpl
    implements FieldDeclaration {
  @override
  final Token? abstractKeyword;

  /// The 'augment' keyword, or `null` if the keyword was not used.
  final Token? augmentKeyword;

  /// The 'covariant' keyword, or `null` if the keyword was not used.
  @override
  final Token? covariantKeyword;

  @override
  final Token? externalKeyword;

  /// The token representing the 'static' keyword, or `null` if the fields are
  /// not static.
  @override
  final Token? staticKeyword;

  /// The fields being declared.
  VariableDeclarationListImpl _fieldList;

  /// The semicolon terminating the declaration.
  @override
  final Token semicolon;

  /// Initialize a newly created field declaration. Either or both of the
  /// [comment] and [metadata] can be `null` if the declaration does not have
  /// the corresponding attribute. The [staticKeyword] can be `null` if the
  /// field is not a static field.
  FieldDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.abstractKeyword,
    required this.augmentKeyword,
    required this.covariantKeyword,
    required this.externalKeyword,
    required this.staticKeyword,
    required VariableDeclarationListImpl fieldList,
    required this.semicolon,
  }) : _fieldList = fieldList {
    _becomeParentOf(_fieldList);
  }

  @override
  Element? get declaredElement => null;

  @override
  Token get endToken => semicolon;

  @override
  VariableDeclarationListImpl get fields => _fieldList;

  set fields(VariableDeclarationListImpl fields) {
    _fieldList = _becomeParentOf(fields);
  }

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return Token.lexicallyFirst(abstractKeyword, augmentKeyword,
            externalKeyword, covariantKeyword, staticKeyword) ??
        _fieldList.beginToken;
  }

  @override
  bool get isStatic => staticKeyword != null;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('staticKeyword', staticKeyword)
    ..addNode('fields', fields)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFieldDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _fieldList.accept(visitor);
  }
}

/// A field formal parameter.
///
///    fieldFormalParameter ::=
///        ('final' [TypeAnnotation] | 'const' [TypeAnnotation] | 'var' | [TypeAnnotation])?
///        'this' '.' name ([TypeParameterList]? [FormalParameterList])?
abstract final class FieldFormalParameter implements NormalFormalParameter {
  /// Return the token representing either the 'final', 'const' or 'var'
  /// keyword, or `null` if no keyword was used.
  Token? get keyword;

  @override
  Token get name;

  /// Return the parameters of the function-typed parameter, or `null` if this
  /// is not a function-typed field formal parameter.
  FormalParameterList? get parameters;

  /// Return the token representing the period.
  Token get period;

  /// If the parameter is function-typed, and has the question mark, then its
  /// function type is nullable. Having a nullable function type means that the
  /// parameter can be null.
  Token? get question;

  /// Return the token representing the 'this' keyword.
  Token get thisKeyword;

  /// Return the declared type of the parameter, or `null` if the parameter does
  /// not have a declared type.
  ///
  /// Note that if this is a function-typed field formal parameter this is the
  /// return type of the function.
  TypeAnnotation? get type;

  /// Return the type parameters associated with this method, or `null` if this
  /// method is not a generic method.
  TypeParameterList? get typeParameters;
}

/// A field formal parameter.
///
///    fieldFormalParameter ::=
///        ('final' [NamedType] | 'const' [NamedType] | 'var' | [NamedType])?
///        'this' '.' [SimpleIdentifier]
///        ([TypeParameterList]? [FormalParameterList])?
final class FieldFormalParameterImpl extends NormalFormalParameterImpl
    implements FieldFormalParameter {
  /// The token representing either the 'final', 'const' or 'var' keyword, or
  /// `null` if no keyword was used.
  @override
  final Token? keyword;

  /// The name of the declared type of the parameter, or `null` if the parameter
  /// does not have a declared type.
  TypeAnnotationImpl? _type;

  /// The token representing the 'this' keyword.
  @override
  final Token thisKeyword;

  /// The token representing the period.
  @override
  final Token period;

  /// The type parameters associated with the method, or `null` if the method is
  /// not a generic method.
  TypeParameterListImpl? _typeParameters;

  /// The parameters of the function-typed parameter, or `null` if this is not a
  /// function-typed field formal parameter.
  FormalParameterListImpl? _parameters;

  @override
  final Token? question;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute. The [keyword] can be `null` if there is a type.
  /// The [type] must be `null` if the keyword is 'var'. The [thisKeyword] and
  /// [period] can be `null` if the keyword 'this' was not provided.  The
  /// [parameters] can be `null` if this is not a function-typed field formal
  /// parameter.
  FieldFormalParameterImpl({
    required super.comment,
    required super.metadata,
    required super.covariantKeyword,
    required super.requiredKeyword,
    required this.keyword,
    required TypeAnnotationImpl? type,
    required this.thisKeyword,
    required this.period,
    required super.name,
    required TypeParameterListImpl? typeParameters,
    required FormalParameterListImpl? parameters,
    required this.question,
  })  : _type = type,
        _typeParameters = typeParameters,
        _parameters = parameters {
    _becomeParentOf(_type);
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_parameters);
  }

  @override
  Token get beginToken {
    final metadata = this.metadata;
    if (metadata.isNotEmpty) {
      return metadata.beginToken!;
    } else if (requiredKeyword != null) {
      return requiredKeyword!;
    } else if (covariantKeyword != null) {
      return covariantKeyword!;
    } else if (keyword != null) {
      return keyword!;
    } else if (_type != null) {
      return _type!.beginToken;
    }
    return thisKeyword;
  }

  @override
  Token get endToken {
    return question ?? _parameters?.endToken ?? name;
  }

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isExplicitlyTyped => _parameters != null || _type != null;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @override
  Token get name => super.name!;

  @override
  FormalParameterListImpl? get parameters => _parameters;

  set parameters(FormalParameterListImpl? parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @override
  TypeAnnotationImpl? get type => _type;

  set type(TypeAnnotationImpl? type) {
    _type = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('keyword', keyword)
    ..addNode('type', type)
    ..addToken('thisKeyword', thisKeyword)
    ..addToken('period', period)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addNode('parameters', parameters);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitFieldFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _type?.accept(visitor);
    _typeParameters?.accept(visitor);
    _parameters?.accept(visitor);
  }
}

/// The parts of a for-each loop that control the iteration.
sealed class ForEachParts implements ForLoopParts {
  /// Return the token representing the 'in' keyword.
  Token get inKeyword;

  /// Return the expression evaluated to produce the iterator.
  Expression get iterable;
}

sealed class ForEachPartsImpl extends ForLoopPartsImpl implements ForEachParts {
  @override
  final Token inKeyword;

  /// The expression evaluated to produce the iterator.
  ExpressionImpl _iterable;

  /// Initialize a newly created for-each statement whose loop control variable
  /// is declared internally (in the for-loop part). The [awaitKeyword] can be
  /// `null` if this is not an asynchronous for loop.
  ForEachPartsImpl({
    required this.inKeyword,
    required ExpressionImpl iterable,
  }) : _iterable = iterable {
    _becomeParentOf(_iterable);
  }

  @override
  Token get beginToken => inKeyword;

  @override
  Token get endToken => _iterable.endToken;

  @override
  ExpressionImpl get iterable => _iterable;

  set iterable(ExpressionImpl expression) {
    _iterable = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('inKeyword', inKeyword)
    ..addNode('iterable', iterable);

  @override
  void visitChildren(AstVisitor visitor) {
    _iterable.accept(visitor);
  }
}

/// The parts of a for-each loop that control the iteration when the loop
/// variable is declared as part of the for loop.
///
///   forLoopParts ::=
///       [DeclaredIdentifier] 'in' [Expression]
abstract final class ForEachPartsWithDeclaration implements ForEachParts {
  /// Return the declaration of the loop variable.
  DeclaredIdentifier get loopVariable;
}

final class ForEachPartsWithDeclarationImpl extends ForEachPartsImpl
    implements ForEachPartsWithDeclaration {
  /// The declaration of the loop variable.
  DeclaredIdentifierImpl _loopVariable;

  /// Initialize a newly created for-each statement whose loop control variable
  /// is declared internally (inside the for-loop part).
  ForEachPartsWithDeclarationImpl({
    required DeclaredIdentifierImpl loopVariable,
    required super.inKeyword,
    required super.iterable,
  }) : _loopVariable = loopVariable {
    _becomeParentOf(_loopVariable);
  }

  @override
  Token get beginToken => _loopVariable.beginToken;

  @override
  DeclaredIdentifierImpl get loopVariable => _loopVariable;

  set loopVariable(DeclaredIdentifierImpl variable) {
    _loopVariable = _becomeParentOf(variable);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('loopVariable', loopVariable)
    ..addAll(super._childEntities);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitForEachPartsWithDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _loopVariable.accept(visitor);
    super.visitChildren(visitor);
  }
}

/// The parts of a for-each loop that control the iteration when the loop
/// variable is declared outside of the for loop.
///
///   forLoopParts ::=
///       [SimpleIdentifier] 'in' [Expression]
abstract final class ForEachPartsWithIdentifier implements ForEachParts {
  /// Return the loop variable.
  SimpleIdentifier get identifier;
}

final class ForEachPartsWithIdentifierImpl extends ForEachPartsImpl
    implements ForEachPartsWithIdentifier {
  /// The loop variable.
  SimpleIdentifierImpl _identifier;

  /// Initialize a newly created for-each statement whose loop control variable
  /// is declared externally (outside the for-loop part).
  ForEachPartsWithIdentifierImpl({
    required SimpleIdentifierImpl identifier,
    required super.inKeyword,
    required super.iterable,
  }) : _identifier = identifier {
    _becomeParentOf(_identifier);
  }

  @override
  Token get beginToken => _identifier.beginToken;

  @override
  SimpleIdentifierImpl get identifier => _identifier;

  set identifier(SimpleIdentifierImpl identifier) {
    _identifier = _becomeParentOf(identifier);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('identifier', identifier)
    ..addAll(super._childEntities);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitForEachPartsWithIdentifier(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _identifier.accept(visitor);
    _iterable.accept(visitor);
  }
}

/// A for-loop part with a pattern.
///
///    forEachPartsWithPattern ::=
///        ( 'final' | 'var' ) [DartPattern] 'in' [Expression]
abstract final class ForEachPartsWithPattern implements ForEachParts {
  /// Return the `var` or `final` keyword introducing the pattern.
  Token get keyword;

  /// Returns the annotations associated with this node.
  NodeList<Annotation> get metadata;

  /// The pattern that will match the expression.
  DartPattern get pattern;
}

/// A for-loop part with a pattern.
///
///    forEachPartsWithPattern ::=
///        ( 'final' | 'var' ) [DartPattern] 'in' [Expression]
final class ForEachPartsWithPatternImpl extends ForEachPartsImpl
    implements ForEachPartsWithPattern {
  /// The annotations associated with this node.
  final NodeListImpl<AnnotationImpl> _metadata = NodeListImpl._();

  @override
  final Token keyword;

  @override
  final DartPatternImpl pattern;

  /// Variables declared in [pattern].
  late final List<BindPatternVariableElementImpl> variables;

  ForEachPartsWithPatternImpl({
    required List<AnnotationImpl>? metadata,
    required this.keyword,
    required this.pattern,
    required super.inKeyword,
    required super.iterable,
  }) {
    _metadata._initialize(this, metadata);
    _becomeParentOf(pattern);
  }

  @override
  Token get beginToken {
    if (_metadata.isEmpty) {
      return keyword;
    } else {
      return _metadata.beginToken!;
    }
  }

  /// If [keyword] is `final`, returns it.
  Token? get finalKeyword {
    if (keyword.keyword == Keyword.FINAL) {
      return keyword;
    }
    return null;
  }

  @override
  NodeListImpl<AnnotationImpl> get metadata => _metadata;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNodeList('metadata', metadata)
    ..addToken('keyword', keyword)
    ..addNode('pattern', pattern)
    ..addAll(super._childEntities);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitForEachPartsWithPattern(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _metadata.accept(visitor);
    pattern.accept(visitor);
    super.visitChildren(visitor);
  }
}

/// The basic structure of a for element.
abstract final class ForElement implements CollectionElement {
  /// Return the token representing the 'await' keyword, or `null` if there was
  /// no 'await' keyword.
  Token? get awaitKeyword;

  /// Return the body of the loop.
  CollectionElement get body;

  /// Return the token representing the 'for' keyword.
  Token get forKeyword;

  /// Return the parts of the for element that control the iteration.
  ForLoopParts get forLoopParts;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the right parenthesis.
  Token get rightParenthesis;
}

final class ForElementImpl extends CollectionElementImpl implements ForElement {
  @override
  final Token? awaitKeyword;

  @override
  final Token forKeyword;

  @override
  final Token leftParenthesis;

  ForLoopPartsImpl _forLoopParts;

  @override
  final Token rightParenthesis;

  /// The body of the loop.
  CollectionElementImpl _body;

  /// Initialize a newly created for element.
  ForElementImpl({
    required this.awaitKeyword,
    required this.forKeyword,
    required this.leftParenthesis,
    required ForLoopPartsImpl forLoopParts,
    required this.rightParenthesis,
    required CollectionElementImpl body,
  })  : _forLoopParts = forLoopParts,
        _body = body {
    _becomeParentOf(_forLoopParts);
    _becomeParentOf(_body);
  }

  @override
  Token get beginToken => awaitKeyword ?? forKeyword;

  @override
  CollectionElementImpl get body => _body;

  set body(CollectionElementImpl statement) {
    _body = _becomeParentOf(statement);
  }

  @override
  Token get endToken => _body.endToken;

  @override
  ForLoopPartsImpl get forLoopParts => _forLoopParts;

  set forLoopParts(ForLoopPartsImpl forLoopParts) {
    _forLoopParts = _becomeParentOf(forLoopParts);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('awaitKeyword', awaitKeyword)
    ..addToken('forKeyword', forKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('forLoopParts', forLoopParts)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addNode('body', body);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitForElement(this);

  @override
  void resolveElement(
      ResolverVisitor resolver, CollectionLiteralContext? context) {
    resolver.visitForElement(this, context: context);
    resolver.pushRewrite(null);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _forLoopParts.accept(visitor);
    _body.accept(visitor);
  }
}

/// The parts of a for or for-each loop that control the iteration.
///
///   forLoopParts ::=
///       [VariableDeclaration] ';' [Expression]? ';' expressionList?
///     | [Expression]? ';' [Expression]? ';' expressionList?
///     | [DeclaredIdentifier] 'in' [Expression]
///     | [SimpleIdentifier] 'in' [Expression]
///
///   expressionList ::=
///       [Expression] (',' [Expression])*
sealed class ForLoopParts implements AstNode {}

sealed class ForLoopPartsImpl extends AstNodeImpl implements ForLoopParts {}

/// A node representing a parameter to a function.
///
///    formalParameter ::=
///        [NormalFormalParameter]
///      | [DefaultFormalParameter]
sealed class FormalParameter implements AstNode {
  /// The 'covariant' keyword, or `null` if the keyword was not used.
  Token? get covariantKeyword;

  /// Return the element representing this parameter, or `null` if this
  /// parameter has not been resolved.
  ParameterElement? get declaredElement;

  /// Return `true` if this parameter was declared with the 'const' modifier.
  bool get isConst;

  /// Indicates whether the parameter has an explicit type.
  bool get isExplicitlyTyped;

  /// Return `true` if this parameter was declared with the 'final' modifier.
  ///
  /// Parameters that are declared with the 'const' modifier will return
  /// `false` even though they are implicitly final.
  bool get isFinal;

  /// Return `true` if this parameter is a named parameter.
  ///
  /// Named parameters can either be required or optional.
  bool get isNamed;

  /// Return `true` if this parameter is an optional parameter.
  ///
  /// Optional parameters can either be positional or named.
  bool get isOptional;

  /// Return `true` if this parameter is both an optional and named parameter.
  bool get isOptionalNamed;

  /// Return `true` if this parameter is both an optional and positional
  /// parameter.
  bool get isOptionalPositional;

  /// Return `true` if this parameter is a positional parameter.
  ///
  /// Positional parameters can either be required or optional.
  bool get isPositional;

  /// Return `true` if this parameter is a required parameter.
  ///
  /// Required parameters can either be positional or named.
  ///
  /// Note: this will return `false` for a named parameter that is annotated
  /// with the `@required` annotation.
  bool get isRequired;

  /// Return `true` if this parameter is both a required and named parameter.
  ///
  /// Note: this will return `false` for a named parameter that is annotated
  /// with the `@required` annotation.
  bool get isRequiredNamed;

  /// Return `true` if this parameter is both a required and positional
  /// parameter.
  bool get isRequiredPositional;

  /// Return the annotations associated with this parameter.
  NodeList<Annotation> get metadata;

  /// Return the name of the parameter being declared, or `null` if the
  /// parameter doesn't have a name, such as when it's part of a generic
  /// function type.
  Token? get name;

  /// The 'required' keyword, or `null` if the keyword was not used.
  Token? get requiredKeyword;
}

/// A node representing a parameter to a function.
///
///    formalParameter ::=
///        [NormalFormalParameter]
///      | [DefaultFormalParameter]
sealed class FormalParameterImpl extends AstNodeImpl
    implements FormalParameter {
  @override
  ParameterElementImpl? declaredElement;

  /// TODO(scheglov) I was not able to update 'nnbd_migration' any better.
  SimpleIdentifier? get identifierForMigration {
    final token = name;
    if (token != null) {
      final result = SimpleIdentifierImpl(token);
      result.staticElement = declaredElement;
      _becomeParentOf(result);
      return result;
    }
    return null;
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
abstract final class FormalParameterList implements AstNode {
  /// Return the left square bracket ('[') or left curly brace ('{') introducing
  /// the optional parameters, or `null` if there are no optional parameters.
  Token? get leftDelimiter;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return a list containing the elements representing the parameters in this
  /// list.
  ///
  /// The list will contain `null`s if the parameters in this list have not
  /// been resolved.
  List<ParameterElement?> get parameterElements;

  /// Return the parameters associated with the method.
  NodeList<FormalParameter> get parameters;

  /// Return the right square bracket (']') or right curly brace ('}')
  /// terminating the optional parameters, or `null` if there are no optional
  /// parameters.
  Token? get rightDelimiter;

  /// Return the right parenthesis.
  Token get rightParenthesis;
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
final class FormalParameterListImpl extends AstNodeImpl
    implements FormalParameterList {
  /// The left parenthesis.
  @override
  final Token leftParenthesis;

  /// The parameters associated with the method.
  final NodeListImpl<FormalParameterImpl> _parameters = NodeListImpl._();

  /// The left square bracket ('[') or left curly brace ('{') introducing the
  /// optional parameters, or `null` if there are no optional parameters.
  @override
  final Token? leftDelimiter;

  /// The right square bracket (']') or right curly brace ('}') terminating the
  /// optional parameters, or `null` if there are no optional parameters.
  @override
  final Token? rightDelimiter;

  /// The right parenthesis.
  @override
  final Token rightParenthesis;

  /// Initialize a newly created parameter list. The list of [parameters] can be
  /// `null` if there are no parameters. The [leftDelimiter] and
  /// [rightDelimiter] can be `null` if there are no optional parameters.
  FormalParameterListImpl({
    required this.leftParenthesis,
    required List<FormalParameterImpl> parameters,
    required this.leftDelimiter,
    required this.rightDelimiter,
    required this.rightParenthesis,
  }) {
    _parameters._initialize(this, parameters);
  }

  @override
  Token get beginToken => leftParenthesis;

  @override
  Token get endToken => rightParenthesis;

  @override
  List<ParameterElement?> get parameterElements {
    int count = _parameters.length;
    var types = <ParameterElement?>[];
    for (int i = 0; i < count; i++) {
      types.add(_parameters[i].declaredElement);
    }
    return types;
  }

  @override
  NodeListImpl<FormalParameterImpl> get parameters => _parameters;

  @override
  ChildEntities get _childEntities {
    // TODO(paulberry): include commas.
    var result = ChildEntities()..addToken('leftParenthesis', leftParenthesis);
    bool leftDelimiterNeeded = leftDelimiter != null;
    int length = _parameters.length;
    for (int i = 0; i < length; i++) {
      FormalParameter parameter = _parameters[i];
      if (leftDelimiterNeeded && leftDelimiter!.offset < parameter.offset) {
        result.addToken('leftDelimiter', leftDelimiter);
        leftDelimiterNeeded = false;
      }
      result.addNode('parameter', parameter);
    }
    return result
      ..addToken('rightDelimiter', rightDelimiter)
      ..addToken('rightParenthesis', rightParenthesis);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFormalParameterList(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _parameters.accept(visitor);
  }
}

/// The parts of a for loop that control the iteration.
///
///   forLoopParts ::=
///       [VariableDeclaration] ';' [Expression]? ';' expressionList?
///     | [Expression]? ';' [Expression]? ';' expressionList?
sealed class ForParts implements ForLoopParts {
  /// Return the condition used to determine when to terminate the loop, or
  /// `null` if there is no condition.
  Expression? get condition;

  /// Return the semicolon separating the initializer and the condition.
  Token get leftSeparator;

  /// Return the semicolon separating the condition and the updater.
  Token get rightSeparator;

  /// Return the list of expressions run after each execution of the loop body.
  NodeList<Expression> get updaters;
}

sealed class ForPartsImpl extends ForLoopPartsImpl implements ForParts {
  @override
  final Token leftSeparator;

  /// The condition used to determine when to terminate the loop, or `null` if
  /// there is no condition.
  ExpressionImpl? _condition;

  @override
  final Token rightSeparator;

  /// The list of expressions run after each execution of the loop body.
  final NodeListImpl<ExpressionImpl> _updaters = NodeListImpl._();

  /// Initialize a newly created for statement. Either the [variableList] or the
  /// [initialization] must be `null`. Either the [condition] and the list of
  /// [updaters] can be `null` if the loop does not have the corresponding
  /// attribute.
  ForPartsImpl({
    required this.leftSeparator,
    required ExpressionImpl? condition,
    required this.rightSeparator,
    required List<ExpressionImpl>? updaters,
  }) : _condition = condition {
    _becomeParentOf(_condition);
    _updaters._initialize(this, updaters);
  }

  @override
  Token get beginToken => leftSeparator;

  @override
  ExpressionImpl? get condition => _condition;

  set condition(ExpressionImpl? expression) {
    _condition = _becomeParentOf(expression);
  }

  @override
  Token get endToken => _updaters.endToken ?? rightSeparator;

  @override
  NodeListImpl<ExpressionImpl> get updaters => _updaters;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftSeparator', leftSeparator)
    ..addNode('condition', condition)
    ..addToken('rightSeparator', rightSeparator)
    ..addNodeList('updaters', updaters);

  @override
  void visitChildren(AstVisitor visitor) {
    _condition?.accept(visitor);
    _updaters.accept(visitor);
  }
}

/// The parts of a for loop that control the iteration when there are one or
/// more variable declarations as part of the for loop.
///
///   forLoopParts ::=
///       [VariableDeclarationList] ';' [Expression]? ';' expressionList?
abstract final class ForPartsWithDeclarations implements ForParts {
  /// Return the declaration of the loop variables.
  VariableDeclarationList get variables;
}

final class ForPartsWithDeclarationsImpl extends ForPartsImpl
    implements ForPartsWithDeclarations {
  /// The declaration of the loop variables, or `null` if there are no
  /// variables.  Note that a for statement cannot have both a variable list and
  /// an initialization expression, but can validly have neither.
  VariableDeclarationListImpl _variableList;

  /// Initialize a newly created for statement. Both the [condition] and the
  /// list of [updaters] can be `null` if the loop does not have the
  /// corresponding attribute.
  ForPartsWithDeclarationsImpl({
    required VariableDeclarationListImpl variableList,
    required super.leftSeparator,
    required super.condition,
    required super.rightSeparator,
    required super.updaters,
  }) : _variableList = variableList {
    _becomeParentOf(_variableList);
  }

  @override
  Token get beginToken => _variableList.beginToken;

  @override
  VariableDeclarationListImpl get variables => _variableList;

  set variables(VariableDeclarationListImpl? variableList) {
    _variableList =
        _becomeParentOf(variableList as VariableDeclarationListImpl);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('variables', variables)
    ..addAll(super._childEntities);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitForPartsWithDeclarations(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _variableList.accept(visitor);
    super.visitChildren(visitor);
  }
}

/// The parts of a for loop that control the iteration when there are no
/// variable declarations as part of the for loop.
///
///   forLoopParts ::=
///       [Expression]? ';' [Expression]? ';' expressionList?
abstract final class ForPartsWithExpression implements ForParts {
  /// Return the initialization expression, or `null` if there is no
  /// initialization expression.
  Expression? get initialization;
}

final class ForPartsWithExpressionImpl extends ForPartsImpl
    implements ForPartsWithExpression {
  /// The initialization expression, or `null` if there is no initialization
  /// expression. Note that a for statement cannot have both a variable list and
  /// an initialization expression, but can validly have neither.
  ExpressionImpl? _initialization;

  /// Initialize a newly created for statement. Both the [condition] and the
  /// list of [updaters] can be `null` if the loop does not have the
  /// corresponding attribute.
  ForPartsWithExpressionImpl({
    required ExpressionImpl? initialization,
    required super.leftSeparator,
    required super.condition,
    required super.rightSeparator,
    required super.updaters,
  }) : _initialization = initialization {
    _becomeParentOf(_initialization);
  }

  @override
  Token get beginToken => initialization?.beginToken ?? super.beginToken;

  @override
  ExpressionImpl? get initialization => _initialization;

  set initialization(ExpressionImpl? initialization) {
    _initialization = _becomeParentOf(initialization);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('initialization', initialization)
    ..addAll(super._childEntities);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitForPartsWithExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _initialization?.accept(visitor);
    super.visitChildren(visitor);
  }
}

/// The parts of a for loop that control the iteration when there is a pattern
/// declaration as part of the for loop.
///
///   forLoopParts ::=
///       [PatternVariableDeclaration] ';' [Expression]? ';' expressionList?
abstract final class ForPartsWithPattern implements ForParts {
  /// Return the declaration of the loop variables.
  PatternVariableDeclaration get variables;
}

/// The parts of a for loop that control the iteration when there is a pattern
/// declaration as part of the for loop.
///
///   forLoopParts ::=
///       [PatternVariableDeclaration] ';' [Expression]? ';' expressionList?
final class ForPartsWithPatternImpl extends ForPartsImpl
    implements ForPartsWithPattern {
  @override
  final PatternVariableDeclarationImpl variables;

  ForPartsWithPatternImpl({
    required this.variables,
    required super.leftSeparator,
    required super.condition,
    required super.rightSeparator,
    required super.updaters,
  }) {
    _becomeParentOf(variables);
  }

  @override
  Token get beginToken => variables.beginToken;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('variables', variables)
    ..addAll(super._childEntities);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitForPartsWithPattern(this);

  @override
  void visitChildren(AstVisitor visitor) {
    variables.accept(visitor);
    super.visitChildren(visitor);
  }
}

/// A for or for-each statement.
///
///    forStatement ::=
///        'for' '(' forLoopParts ')' [Statement]
///
///    forLoopParts ::=
///       [VariableDeclaration] ';' [Expression]? ';' expressionList?
///     | [Expression]? ';' [Expression]? ';' expressionList?
///     | [DeclaredIdentifier] 'in' [Expression]
///     | [SimpleIdentifier] 'in' [Expression]
///
/// This is the class that is used to represent a for loop when either the
/// 'control-flow-collections' or 'spread-collections' experiments are enabled.
/// If neither of those experiments are enabled, then either `ForStatement` or
/// `ForEachStatement` will be used.
abstract final class ForStatement implements Statement {
  /// Return the token representing the 'await' keyword, or `null` if there is
  /// no 'await' keyword.
  Token? get awaitKeyword;

  /// Return the body of the loop.
  Statement get body;

  /// Return the token representing the 'for' keyword.
  Token get forKeyword;

  /// Return the parts of the for element that control the iteration.
  ForLoopParts get forLoopParts;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the right parenthesis.
  Token get rightParenthesis;
}

final class ForStatementImpl extends StatementImpl implements ForStatement {
  @override
  final Token? awaitKeyword;

  @override
  final Token forKeyword;

  @override
  final Token leftParenthesis;

  ForLoopPartsImpl _forLoopParts;

  @override
  final Token rightParenthesis;

  /// The body of the loop.
  StatementImpl _body;

  /// Initialize a newly created for statement.
  ForStatementImpl({
    required this.awaitKeyword,
    required this.forKeyword,
    required this.leftParenthesis,
    required ForLoopPartsImpl forLoopParts,
    required this.rightParenthesis,
    required StatementImpl body,
  })  : _forLoopParts = forLoopParts,
        _body = body {
    _becomeParentOf(_forLoopParts);
    _becomeParentOf(_body);
  }

  @override
  Token get beginToken => awaitKeyword ?? forKeyword;

  @override
  StatementImpl get body => _body;

  set body(StatementImpl statement) {
    _body = _becomeParentOf(statement);
  }

  @override
  Token get endToken => _body.endToken;

  @override
  ForLoopPartsImpl get forLoopParts => _forLoopParts;

  set forLoopParts(ForLoopPartsImpl forLoopParts) {
    _forLoopParts = _becomeParentOf(forLoopParts);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('awaitKeyword', awaitKeyword)
    ..addToken('forKeyword', forKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('forLoopParts', forLoopParts)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addNode('body', body);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitForStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _forLoopParts.accept(visitor);
    _body.accept(visitor);
  }
}

/// A node representing the body of a function or method.
///
///    functionBody ::=
///        [BlockFunctionBody]
///      | [EmptyFunctionBody]
///      | [ExpressionFunctionBody]
///      | [NativeFunctionBody]
sealed class FunctionBody implements AstNode {
  /// Return `true` if this function body is asynchronous.
  bool get isAsynchronous;

  /// Return `true` if this function body is a generator.
  bool get isGenerator;

  /// Return `true` if this function body is synchronous.
  bool get isSynchronous;

  /// Return the token representing the 'async' or 'sync' keyword, or `null` if
  /// there is no such keyword.
  Token? get keyword;

  /// Return the star following the 'async' or 'sync' keyword, or `null` if
  /// there is no star.
  Token? get star;

  /// If [variable] is a local variable or parameter declared anywhere within
  /// the top level function or method containing this [FunctionBody], return a
  /// boolean indicating whether [variable] is potentially mutated within the
  /// scope of its declaration.
  ///
  /// If [variable] is not a local variable or parameter declared within the top
  /// level function or method containing this [FunctionBody], return `false`.
  ///
  /// Throws an exception if resolution has not yet been performed.
  bool isPotentiallyMutatedInScope(VariableElement variable);
}

/// A node representing the body of a function or method.
///
///    functionBody ::=
///        [BlockFunctionBody]
///      | [EmptyFunctionBody]
///      | [ExpressionFunctionBody]
sealed class FunctionBodyImpl extends AstNodeImpl implements FunctionBody {
  /// Additional information about local variables and parameters that are
  /// declared within this function body or any enclosing function body.  `null`
  /// if resolution has not yet been performed.
  LocalVariableInfo? localVariableInfo;

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
  Token? get keyword => null;

  /// Return the star following the 'async' or 'sync' keyword, or `null` if
  /// there is no star.
  @override
  Token? get star => null;

  @override
  bool isPotentiallyMutatedInScope(VariableElement variable) {
    if (localVariableInfo == null) {
      throw StateError('Resolution has not yet been performed');
    }
    return localVariableInfo!.potentiallyMutatedInScope.contains(variable);
  }

  /// Dispatch this function body to the resolver, imposing [imposedType] as the
  /// return type context for `return` statements.
  ///
  /// Return value is the actual return type of the method.
  DartType resolve(ResolverVisitor resolver, DartType? imposedType);
}

/// A function declaration.
///
/// Wrapped in a [FunctionDeclarationStatement] to represent a local function
/// declaration, otherwise a top-level function declaration.
///
///    functionDeclaration ::=
///        'external' functionSignature
///      | functionSignature [FunctionBody]
///
///    functionSignature ::=
///        [Type]? ('get' | 'set')? name [FormalParameterList]
abstract final class FunctionDeclaration implements NamedCompilationUnitMember {
  @override
  ExecutableElement? get declaredElement;

  /// Return the token representing the 'external' keyword, or `null` if this is
  /// not an external function.
  Token? get externalKeyword;

  /// Return the function expression being wrapped.
  FunctionExpression get functionExpression;

  /// Return `true` if this function declares a getter.
  bool get isGetter;

  /// Return `true` if this function declares a setter.
  bool get isSetter;

  /// Return the token representing the 'get' or 'set' keyword, or `null` if
  /// this is a function declaration rather than a property declaration.
  Token? get propertyKeyword;

  /// Return the return type of the function, or `null` if no return type was
  /// declared.
  TypeAnnotation? get returnType;
}

/// A function declaration.
///
/// Wrapped in a [FunctionDeclarationStatementImpl] to represent a local
/// function declaration, otherwise a top-level function declaration.
///
///    functionDeclaration ::=
///        'external' functionSignature
///      | functionSignature [FunctionBody]
///
///    functionSignature ::=
///        [Type]? ('get' | 'set')? [SimpleIdentifier] [FormalParameterList]
final class FunctionDeclarationImpl extends NamedCompilationUnitMemberImpl
    implements FunctionDeclaration {
  /// The token representing the 'augment' keyword, or `null` if this is not an
  /// function augmentation.
  final Token? augmentKeyword;

  /// The token representing the 'external' keyword, or `null` if this is not an
  /// external function.
  @override
  final Token? externalKeyword;

  /// The return type of the function, or `null` if no return type was declared.
  TypeAnnotationImpl? _returnType;

  /// The token representing the 'get' or 'set' keyword, or `null` if this is a
  /// function declaration rather than a property declaration.
  @override
  final Token? propertyKeyword;

  /// The function expression being wrapped.
  FunctionExpressionImpl _functionExpression;

  @override
  ExecutableElementImpl? declaredElement;

  /// Initialize a newly created function declaration. Either or both of the
  /// [comment] and [metadata] can be `null` if the function does not have the
  /// corresponding attribute. The [externalKeyword] can be `null` if the
  /// function is not an external function. The [returnType] can be `null` if no
  /// return type was specified. The [propertyKeyword] can be `null` if the
  /// function is neither a getter or a setter.
  FunctionDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
    required this.externalKeyword,
    required TypeAnnotationImpl? returnType,
    required this.propertyKeyword,
    required super.name,
    required FunctionExpressionImpl functionExpression,
  })  : _returnType = returnType,
        _functionExpression = functionExpression {
    _becomeParentOf(_returnType);
    _becomeParentOf(_functionExpression);
  }

  @override
  Token get endToken => _functionExpression.endToken;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return augmentKeyword ??
        externalKeyword ??
        _returnType?.beginToken ??
        propertyKeyword ??
        name;
  }

  @override
  FunctionExpressionImpl get functionExpression => _functionExpression;

  set functionExpression(FunctionExpressionImpl functionExpression) {
    _functionExpression = _becomeParentOf(functionExpression);
  }

  @override
  bool get isGetter => propertyKeyword?.keyword == Keyword.GET;

  @override
  bool get isSetter => propertyKeyword?.keyword == Keyword.SET;

  @override
  TypeAnnotationImpl? get returnType => _returnType;

  set returnType(TypeAnnotationImpl? type) {
    _returnType = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('augmentKeyword', augmentKeyword)
    ..addToken('externalKeyword', externalKeyword)
    ..addNode('returnType', returnType)
    ..addToken('propertyKeyword', propertyKeyword)
    ..addToken('name', name)
    ..addNode('functionExpression', functionExpression);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFunctionDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _returnType?.accept(visitor);
    _functionExpression.accept(visitor);
  }
}

/// A [FunctionDeclaration] used as a statement.
abstract final class FunctionDeclarationStatement implements Statement {
  /// Return the function declaration being wrapped.
  FunctionDeclaration get functionDeclaration;
}

/// A [FunctionDeclaration] used as a statement.
final class FunctionDeclarationStatementImpl extends StatementImpl
    implements FunctionDeclarationStatement {
  /// The function declaration being wrapped.
  FunctionDeclarationImpl _functionDeclaration;

  /// Initialize a newly created function declaration statement.
  FunctionDeclarationStatementImpl({
    required FunctionDeclarationImpl functionDeclaration,
  }) : _functionDeclaration = functionDeclaration {
    _becomeParentOf(_functionDeclaration);
  }

  @override
  Token get beginToken => _functionDeclaration.beginToken;

  @override
  Token get endToken => _functionDeclaration.endToken;

  @override
  FunctionDeclarationImpl get functionDeclaration => _functionDeclaration;

  set functionDeclaration(FunctionDeclarationImpl functionDeclaration) {
    _functionDeclaration = _becomeParentOf(functionDeclaration);
  }

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addNode('functionDeclaration', functionDeclaration);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitFunctionDeclarationStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _functionDeclaration.accept(visitor);
  }
}

/// A function expression.
///
///    functionExpression ::=
///        [TypeParameterList]? [FormalParameterList] [FunctionBody]
abstract final class FunctionExpression implements Expression {
  /// Return the body of the function.
  FunctionBody get body;

  /// Return the element associated with the function, or `null` if the AST
  /// structure has not been resolved.
  ExecutableElement? get declaredElement;

  /// Return the parameters associated with the function, or `null` if the
  /// function is part of a top-level getter.
  FormalParameterList? get parameters;

  /// Return the type parameters associated with this method, or `null` if this
  /// method is not a generic method.
  TypeParameterList? get typeParameters;
}

/// A function expression.
///
///    functionExpression ::=
///        [TypeParameterList]? [FormalParameterList] [FunctionBody]
final class FunctionExpressionImpl extends ExpressionImpl
    implements FunctionExpression {
  /// The type parameters associated with the method, or `null` if the method is
  /// not a generic method.
  TypeParameterListImpl? _typeParameters;

  /// The parameters associated with the function, or `null` if the function is
  /// part of a top-level getter.
  FormalParameterListImpl? _parameters;

  /// The body of the function.
  FunctionBodyImpl _body;

  /// If resolution has been performed, this boolean indicates whether a
  /// function type was supplied via context for this function expression.
  /// `false` if resolution hasn't been performed yet.
  bool wasFunctionTypeSupplied = false;

  @override
  ExecutableElementImpl? declaredElement;

  /// Initialize a newly created function declaration.
  FunctionExpressionImpl({
    required TypeParameterListImpl? typeParameters,
    required FormalParameterListImpl? parameters,
    required FunctionBodyImpl body,
  })  : _typeParameters = typeParameters,
        _parameters = parameters,
        _body = body {
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_parameters);
    _becomeParentOf(_body);
  }

  @override
  Token get beginToken {
    if (_typeParameters != null) {
      return _typeParameters!.beginToken;
    } else if (_parameters != null) {
      return _parameters!.beginToken;
    }
    return _body.beginToken;
  }

  @override
  FunctionBodyImpl get body => _body;

  set body(FunctionBodyImpl functionBody) {
    _body = _becomeParentOf(functionBody);
  }

  @override
  Token get endToken {
    return _body.endToken;
  }

  @override
  FormalParameterListImpl? get parameters => _parameters;

  set parameters(FormalParameterListImpl? parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @override
  Precedence get precedence => Precedence.primary;

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('typeParameters', typeParameters)
    ..addNode('parameters', parameters)
    ..addNode('body', body);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFunctionExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitFunctionExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _typeParameters?.accept(visitor);
    _parameters?.accept(visitor);
    _body.accept(visitor);
  }
}

/// The invocation of a function resulting from evaluating an expression.
///
/// Invocations of methods and other forms of functions are represented by
/// [MethodInvocation] nodes. Invocations of getters and setters are represented
/// by either [PrefixedIdentifier] or [PropertyAccess] nodes.
///
///    functionExpressionInvocation ::=
///        [Expression] [TypeArgumentList]? [ArgumentList]
abstract final class FunctionExpressionInvocation
    implements NullShortableExpression, InvocationExpression {
  /// Return the expression producing the function being invoked.
  @override
  Expression get function;

  /// Return the element associated with the function being invoked based on
  /// static type information, or `null` if the AST structure has not been
  /// resolved or the function could not be resolved.
  ExecutableElement? get staticElement;
}

/// The invocation of a function resulting from evaluating an expression.
/// Invocations of methods and other forms of functions are represented by
/// [MethodInvocation] nodes. Invocations of getters and setters are represented
/// by either [PrefixedIdentifier] or [PropertyAccess] nodes.
///
///    functionExpressionInvocation ::=
///        [Expression] [TypeArgumentList]? [ArgumentList]
final class FunctionExpressionInvocationImpl extends InvocationExpressionImpl
    with NullShortableExpressionImpl
    implements FunctionExpressionInvocation {
  /// The expression producing the function being invoked.
  ExpressionImpl _function;

  /// The element associated with the function being invoked based on static
  /// type information, or `null` if the AST structure has not been resolved or
  /// the function could not be resolved.
  @override
  ExecutableElement? staticElement;

  /// Initialize a newly created function expression invocation.
  FunctionExpressionInvocationImpl({
    required ExpressionImpl function,
    required super.typeArguments,
    required super.argumentList,
  }) : _function = function {
    _becomeParentOf(_function);
  }

  @override
  Token get beginToken => _function.beginToken;

  @override
  Token get endToken => _argumentList.endToken;

  @override
  ExpressionImpl get function => _function;

  set function(ExpressionImpl expression) {
    _function = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('function', function)
    ..addNode('typeArguments', typeArguments)
    ..addNode('argumentList', argumentList);

  @override
  AstNode? get _nullShortingExtensionCandidate => parent;

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitFunctionExpressionInvocation(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitFunctionExpressionInvocation(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _function.accept(visitor);
    _typeArguments?.accept(visitor);
    _argumentList.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression descendant) =>
      identical(descendant, _function);
}

/// An expression representing a reference to a function, possibly with type
/// arguments applied to it, e.g. the expression `print` in `var x = print;`.
abstract final class FunctionReference
    implements Expression, CommentReferableExpression {
  /// The function being referenced.
  ///
  /// In error-free code, this will be either a SimpleIdentifier (indicating a
  /// function that is in scope), a PrefixedIdentifier (indicating a either
  /// function imported via prefix or a static method in a class), or a
  /// PropertyAccess (indicating a static method in a class imported via
  /// prefix).  In code with errors, this could be other kinds of expressions
  /// (e.g. `(...)<int>` parses as a FunctionReference whose referent is a
  /// ParenthesizedExpression.
  Expression get function;

  /// The type arguments being applied to the function, or `null` if there are
  /// no type arguments.
  TypeArgumentList? get typeArguments;

  /// The actual type arguments being applied to the function, either explicitly
  /// specified in [typeArguments], or inferred.
  ///
  /// If the AST has been resolved, never returns `null`, returns an empty list
  /// if the function does not have type parameters.
  ///
  /// Returns `null` if the AST structure has not been resolved.
  List<DartType>? get typeArgumentTypes;
}

/// An expression representing a reference to a function, possibly with type
/// arguments applied to it, e.g. the expression `print` in `var x = print;`.
final class FunctionReferenceImpl extends CommentReferableExpressionImpl
    implements FunctionReference {
  ExpressionImpl _function;

  TypeArgumentListImpl? _typeArguments;

  @override
  List<DartType>? typeArgumentTypes;

  FunctionReferenceImpl({
    required ExpressionImpl function,
    required TypeArgumentListImpl? typeArguments,
  })  : _function = function,
        _typeArguments = typeArguments {
    _becomeParentOf(_function);
    _becomeParentOf(_typeArguments);
  }

  @override
  Token get beginToken => function.beginToken;

  @override
  Token get endToken => typeArguments?.endToken ?? function.endToken;

  @override
  ExpressionImpl get function => _function;

  set function(ExpressionImpl value) {
    _function = _becomeParentOf(value);
  }

  @override
  Precedence get precedence =>
      typeArguments == null ? function.precedence : Precedence.postfix;

  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  set typeArguments(TypeArgumentListImpl? value) {
    _typeArguments = _becomeParentOf(value);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('function', function)
    ..addNode('typeArguments', typeArguments);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFunctionReference(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitFunctionReference(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    function.accept(visitor);
    typeArguments?.accept(visitor);
  }
}

/// A function type alias.
///
///    functionTypeAlias ::=
///        'typedef' functionPrefix [TypeParameterList]? [FormalParameterList] ';'
///
///    functionPrefix ::=
///        [TypeAnnotation]? [SimpleIdentifier]
abstract final class FunctionTypeAlias implements TypeAlias {
  @override
  TypeAliasElement? get declaredElement;

  /// Return the parameters associated with the function type.
  FormalParameterList get parameters;

  /// Return the return type of the function type being defined, or `null` if no
  /// return type was given.
  TypeAnnotation? get returnType;

  /// Return the type parameters for the function type, or `null` if the
  /// function type does not have any type parameters.
  TypeParameterList? get typeParameters;
}

/// A function type alias.
///
///    functionTypeAlias ::=
///        'typedef' functionPrefix [TypeParameterList]? [FormalParameterList] ';'
///
///    functionPrefix ::=
///        [TypeAnnotation]? [SimpleIdentifier]
final class FunctionTypeAliasImpl extends TypeAliasImpl
    implements FunctionTypeAlias {
  /// The name of the return type of the function type being defined, or `null`
  /// if no return type was given.
  TypeAnnotationImpl? _returnType;

  /// The type parameters for the function type, or `null` if the function type
  /// does not have any type parameters.
  TypeParameterListImpl? _typeParameters;

  /// The parameters associated with the function type.
  FormalParameterListImpl _parameters;

  @override
  TypeAliasElementImpl? declaredElement;

  /// Initialize a newly created function type alias. Either or both of the
  /// [comment] and [metadata] can be `null` if the function does not have the
  /// corresponding attribute. The [returnType] can be `null` if no return type
  /// was specified. The [typeParameters] can be `null` if the function has no
  /// type parameters.
  FunctionTypeAliasImpl({
    required super.comment,
    required super.metadata,
    required super.typedefKeyword,
    required TypeAnnotationImpl? returnType,
    required super.name,
    required TypeParameterListImpl? typeParameters,
    required FormalParameterListImpl parameters,
    required super.semicolon,
  })  : _returnType = returnType,
        _typeParameters = typeParameters,
        _parameters = parameters {
    _becomeParentOf(_returnType);
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_parameters);
  }

  @override
  FormalParameterListImpl get parameters => _parameters;

  set parameters(FormalParameterListImpl parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @override
  TypeAnnotationImpl? get returnType => _returnType;

  set returnType(TypeAnnotationImpl? type) {
    _returnType = _becomeParentOf(type);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('typedefKeyword', typedefKeyword)
    ..addNode('returnType', returnType)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addNode('parameters', parameters)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFunctionTypeAlias(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _returnType?.accept(visitor);
    _typeParameters?.accept(visitor);
    _parameters.accept(visitor);
  }
}

/// A function-typed formal parameter.
///
///    functionSignature ::=
///        [TypeAnnotation]? name [TypeParameterList]?
///        [FormalParameterList] '?'?
abstract final class FunctionTypedFormalParameter
    implements NormalFormalParameter {
  @override
  Token get name;

  /// Return the parameters of the function-typed parameter.
  FormalParameterList get parameters;

  /// Return the question mark indicating that the function type is nullable, or
  /// `null` if there is no question mark. Having a nullable function type means
  /// that the parameter can be null.
  Token? get question;

  /// Return the return type of the function, or `null` if the function does not
  /// have a return type.
  TypeAnnotation? get returnType;

  /// Return the type parameters associated with this function, or `null` if
  /// this function is not a generic function.
  TypeParameterList? get typeParameters;
}

/// A function-typed formal parameter.
///
///    functionSignature ::=
///        [NamedType]? [SimpleIdentifier] [TypeParameterList]?
///        [FormalParameterList] '?'?
final class FunctionTypedFormalParameterImpl extends NormalFormalParameterImpl
    implements FunctionTypedFormalParameter {
  /// The return type of the function, or `null` if the function does not have a
  /// return type.
  TypeAnnotationImpl? _returnType;

  /// The type parameters associated with the function, or `null` if the
  /// function is not a generic function.
  TypeParameterListImpl? _typeParameters;

  /// The parameters of the function-typed parameter.
  FormalParameterListImpl _parameters;

  @override
  final Token? question;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute. The [returnType] can be `null` if no return type
  /// was specified.
  FunctionTypedFormalParameterImpl({
    required super.comment,
    required super.metadata,
    required super.covariantKeyword,
    required super.requiredKeyword,
    required TypeAnnotationImpl? returnType,
    required super.name,
    required TypeParameterListImpl? typeParameters,
    required FormalParameterListImpl parameters,
    required this.question,
  })  : _returnType = returnType,
        _typeParameters = typeParameters,
        _parameters = parameters {
    _becomeParentOf(_returnType);
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_parameters);
  }

  @override
  Token get beginToken {
    final metadata = this.metadata;
    if (metadata.isNotEmpty) {
      return metadata.beginToken!;
    } else if (requiredKeyword != null) {
      return requiredKeyword!;
    } else if (covariantKeyword != null) {
      return covariantKeyword!;
    } else if (_returnType != null) {
      return _returnType!.beginToken;
    }
    return name;
  }

  @override
  Token get endToken => question ?? _parameters.endToken;

  @override
  bool get isConst => false;

  @override
  bool get isExplicitlyTyped => true;

  @override
  bool get isFinal => false;

  @override
  Token get name => super.name!;

  @override
  FormalParameterListImpl get parameters => _parameters;

  set parameters(FormalParameterListImpl parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @override
  TypeAnnotationImpl? get returnType => _returnType;

  set returnType(TypeAnnotationImpl? type) {
    _returnType = _becomeParentOf(type);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('returnType', returnType)
    ..addToken('name', name)
    ..addNode('parameters', parameters);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitFunctionTypedFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _returnType?.accept(visitor);
    _typeParameters?.accept(visitor);
    _parameters.accept(visitor);
  }
}

/// An anonymous function type.
///
///    functionType ::=
///        [TypeAnnotation]? 'Function' [TypeParameterList]?
///        [FormalParameterList] '?'?
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
abstract final class GenericFunctionType implements TypeAnnotation {
  /// Return the keyword 'Function'.
  Token get functionKeyword;

  /// Return the parameters associated with the function type.
  FormalParameterList get parameters;

  /// Return the return type of the function type being defined, or `null` if
  /// no return type was given.
  TypeAnnotation? get returnType;

  /// Return the type parameters for the function type, or `null` if the
  /// function type does not have any type parameters.
  TypeParameterList? get typeParameters;
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
final class GenericFunctionTypeImpl extends TypeAnnotationImpl
    implements GenericFunctionType {
  /// The name of the return type of the function type being defined, or
  /// `null` if no return type was given.
  TypeAnnotationImpl? _returnType;

  @override
  final Token functionKeyword;

  /// The type parameters for the function type, or `null` if the function type
  /// does not have any type parameters.
  TypeParameterListImpl? _typeParameters;

  /// The parameters associated with the function type.
  FormalParameterListImpl _parameters;

  @override
  final Token? question;

  @override
  DartType? type;

  /// Return the element associated with the function type, or `null` if the
  /// AST structure has not been resolved.
  GenericFunctionTypeElementImpl? declaredElement;

  /// Initialize a newly created generic function type.
  GenericFunctionTypeImpl({
    required TypeAnnotationImpl? returnType,
    required this.functionKeyword,
    required TypeParameterListImpl? typeParameters,
    required FormalParameterListImpl parameters,
    required this.question,
  })  : _returnType = returnType,
        _typeParameters = typeParameters,
        _parameters = parameters {
    _becomeParentOf(_returnType);
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_parameters);
  }

  @override
  Token get beginToken => _returnType?.beginToken ?? functionKeyword;

  @override
  Token get endToken => question ?? _parameters.endToken;

  @override
  FormalParameterListImpl get parameters => _parameters;

  set parameters(FormalParameterListImpl parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @override
  TypeAnnotationImpl? get returnType => _returnType;

  set returnType(TypeAnnotationImpl? type) {
    _returnType = _becomeParentOf(type);
  }

  /// Return the type parameters for the function type, or `null` if the
  /// function type does not have any type parameters.
  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  /// Set the type parameters for the function type to the given list of
  /// [typeParameters].
  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('returnType', returnType)
    ..addToken('functionKeyword', functionKeyword)
    ..addNode('typeParameters', typeParameters)
    ..addNode('parameters', parameters)
    ..addToken('question', question);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitGenericFunctionType(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _returnType?.accept(visitor);
    _typeParameters?.accept(visitor);
    _parameters.accept(visitor);
  }
}

/// A generic type alias.
///
///    functionTypeAlias ::=
///        'typedef' [SimpleIdentifier] [TypeParameterList]? = [FunctionType] ';'
abstract final class GenericTypeAlias implements TypeAlias {
  /// Return the equal sign separating the name being defined from the function
  /// type.
  Token get equals;

  /// Return the type of function being defined by the alias.
  ///
  /// When the non-function type aliases feature is enabled and the denoted
  /// type is not a [GenericFunctionType], return `null`.
  GenericFunctionType? get functionType;

  /// Return the type being defined by the alias.
  TypeAnnotation get type;

  /// Return the type parameters for the function type, or `null` if the
  /// function type does not have any type parameters.
  TypeParameterList? get typeParameters;
}

/// A generic type alias.
///
///    functionTypeAlias ::=
///        'typedef' [SimpleIdentifier] [TypeParameterList]? = [FunctionType] ';'
final class GenericTypeAliasImpl extends TypeAliasImpl
    implements GenericTypeAlias {
  /// The type being defined by the alias.
  TypeAnnotationImpl _type;

  /// The type parameters for the function type, or `null` if the function
  /// type does not have any type parameters.
  TypeParameterListImpl? _typeParameters;

  @override
  final Token equals;

  @override
  ElementImpl? declaredElement;

  /// Returns a newly created generic type alias. Either or both of the
  /// [comment] and [metadata] can be `null` if the variable list does not have
  /// the corresponding attribute. The [typeParameters] can be `null` if there
  /// are no type parameters.
  GenericTypeAliasImpl({
    required super.comment,
    required super.metadata,
    required super.typedefKeyword,
    required super.name,
    required TypeParameterListImpl? typeParameters,
    required this.equals,
    required TypeAnnotationImpl type,
    required super.semicolon,
  })  : _typeParameters = typeParameters,
        _type = type {
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_type);
  }

  /// The type of function being defined by the alias.
  ///
  /// If the non-function type aliases feature is enabled, a type alias may have
  /// a [_type] which is not a [GenericFunctionTypeImpl].  In that case `null`
  /// is returned.
  @override
  GenericFunctionType? get functionType {
    var type = _type;
    return type is GenericFunctionTypeImpl ? type : null;
  }

  set functionType(GenericFunctionType? functionType) {
    _type = _becomeParentOf(functionType as GenericFunctionTypeImpl?)!;
  }

  @override
  TypeAnnotationImpl get type => _type;

  /// Set the type being defined by the alias to the given [TypeAnnotation].
  set type(TypeAnnotationImpl typeAnnotation) {
    _type = _becomeParentOf(typeAnnotation);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNodeList('metadata', metadata)
    ..addToken('typedefKeyword', typedefKeyword)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addToken('equals', equals)
    ..addNode('type', type);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitGenericTypeAlias(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _typeParameters?.accept(visitor);
    _type.accept(visitor);
  }
}

/// The pattern with an optional [WhenClause].
///
///    guardedPattern ::=
///        [DartPattern] [WhenClause]?
abstract final class GuardedPattern implements AstNode {
  /// Return the pattern controlling whether the statements will be executed.
  DartPattern get pattern;

  /// Return the clause controlling whether the statements will be executed.
  WhenClause? get whenClause;
}

/// The `case` clause that can optionally appear in an `if` statement.
///
///    caseClause ::=
///        'case' [DartPattern] [WhenClause]?
final class GuardedPatternImpl extends AstNodeImpl implements GuardedPattern {
  @override
  final DartPatternImpl pattern;

  /// Variables declared in [pattern], available in [whenClause] guard, and
  /// to the `ifTrue` node.
  late Map<String, PatternVariableElementImpl> variables;

  @override
  final WhenClauseImpl? whenClause;

  GuardedPatternImpl({
    required this.pattern,
    required this.whenClause,
  }) {
    _becomeParentOf(pattern);
    _becomeParentOf(whenClause);
  }

  @override
  Token get beginToken => pattern.beginToken;

  @override
  Token get endToken => whenClause?.endToken ?? pattern.endToken;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('pattern', pattern)
    ..addNode('whenClause', whenClause);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitGuardedPattern(this);

  @override
  void visitChildren(AstVisitor visitor) {
    pattern.accept(visitor);
    whenClause?.accept(visitor);
  }
}

/// A combinator that restricts the names being imported to those that are not
/// in a given list.
///
///    hideCombinator ::=
///        'hide' [SimpleIdentifier] (',' [SimpleIdentifier])*
abstract final class HideCombinator implements Combinator {
  /// Return the list of names from the library that are hidden by this
  /// combinator.
  NodeList<SimpleIdentifier> get hiddenNames;
}

/// A combinator that restricts the names being imported to those that are not
/// in a given list.
///
///    hideCombinator ::=
///        'hide' [SimpleIdentifier] (',' [SimpleIdentifier])*
final class HideCombinatorImpl extends CombinatorImpl
    implements HideCombinator {
  /// The list of names from the library that are hidden by this combinator.
  final NodeListImpl<SimpleIdentifierImpl> _hiddenNames = NodeListImpl._();

  /// Initialize a newly created import show combinator.
  HideCombinatorImpl({
    required super.keyword,
    required List<SimpleIdentifierImpl> hiddenNames,
  }) {
    _hiddenNames._initialize(this, hiddenNames);
  }

  @override
  Token get endToken => _hiddenNames.endToken!;

  @override
  NodeListImpl<SimpleIdentifierImpl> get hiddenNames => _hiddenNames;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('keyword', keyword)
    ..addNodeList('hiddenNames', hiddenNames);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitHideCombinator(this);

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
sealed class Identifier implements Expression, CommentReferableExpression {
  /// Return the lexical representation of the identifier.
  String get name;

  /// Return the element associated with this identifier based on static type
  /// information, or `null` if the AST structure has not been resolved or if
  /// this identifier could not be resolved.
  ///
  /// One example of the latter case is an identifier that is not defined
  /// within the scope in which it appears.
  Element? get staticElement;

  /// Return `true` if the given [name] is visible only within the library in
  /// which it is declared.
  static bool isPrivateName(String name) => name.isNotEmpty && name[0] == "_";
}

/// A node that represents an identifier.
///
///    identifier ::=
///        [SimpleIdentifier]
///      | [PrefixedIdentifier]
sealed class IdentifierImpl extends CommentReferableExpressionImpl
    implements Identifier {
  @override
  bool get isAssignable => true;
}

/// The basic structure of an if element.
abstract final class IfElement implements CollectionElement {
  /// Return the `case` clause used to match a pattern against the [expression].
  CaseClause? get caseClause;

  /// Return the condition used to determine which of the statements is executed
  /// next.
  @Deprecated('Use expression instead')
  Expression get condition;

  /// Return the statement that is executed if the condition evaluates to
  /// `false`, or `null` if there is no else statement.
  CollectionElement? get elseElement;

  /// Return the token representing the 'else' keyword, or `null` if there is no
  /// else statement.
  Token? get elseKeyword;

  /// Return the expression used to either determine which of the statements is
  /// executed next or to compute the value to be matched against the pattern in
  /// the `case` clause.
  Expression get expression;

  /// Return the token representing the 'if' keyword.
  Token get ifKeyword;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the right parenthesis.
  Token get rightParenthesis;

  /// Return the statement that is executed if the condition evaluates to
  /// `true`.
  CollectionElement get thenElement;
}

final class IfElementImpl extends CollectionElementImpl
    implements IfElement, IfElementOrStatementImpl<CollectionElementImpl> {
  @override
  final Token ifKeyword;

  @override
  final Token leftParenthesis;

  ExpressionImpl _expression;

  @override
  final CaseClauseImpl? caseClause;

  @override
  final Token rightParenthesis;

  @override
  final Token? elseKeyword;

  /// The element to be executed if the condition is `true`.
  CollectionElementImpl _thenElement;

  /// The element to be executed if the condition is `false`, or `null` if there
  /// is no such element.
  CollectionElementImpl? _elseElement;

  /// Initialize a newly created for element.
  IfElementImpl({
    required this.ifKeyword,
    required this.leftParenthesis,
    required ExpressionImpl expression,
    required this.caseClause,
    required this.rightParenthesis,
    required CollectionElementImpl thenElement,
    required this.elseKeyword,
    required CollectionElementImpl? elseElement,
  })  : _expression = expression,
        _thenElement = thenElement,
        _elseElement = elseElement {
    _becomeParentOf(_expression);
    _becomeParentOf(caseClause);
    _becomeParentOf(_thenElement);
    _becomeParentOf(_elseElement);
  }

  @override
  Token get beginToken => ifKeyword;

  @Deprecated('Use expression instead')
  @override
  ExpressionImpl get condition => _expression;

  set condition(ExpressionImpl condition) {
    _expression = _becomeParentOf(condition);
  }

  @override
  CollectionElementImpl? get elseElement => _elseElement;

  set elseElement(CollectionElementImpl? element) {
    _elseElement = _becomeParentOf(element);
  }

  @override
  Token get endToken => _elseElement?.endToken ?? _thenElement.endToken;

  @override
  ExpressionImpl get expression => _expression;

  @override
  CollectionElementImpl? get ifFalse => elseElement;

  @override
  CollectionElementImpl get ifTrue => thenElement;

  @override
  CollectionElementImpl get thenElement => _thenElement;

  set thenElement(CollectionElementImpl element) {
    _thenElement = _becomeParentOf(element);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('ifKeyword', ifKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('expression', expression)
    ..addNode('caseClause', caseClause)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addNode('thenElement', thenElement)
    ..addToken('elseKeyword', elseKeyword)
    ..addNode('elseElement', elseElement);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitIfElement(this);

  @override
  void resolveElement(
      ResolverVisitor resolver, CollectionLiteralContext? context) {
    resolver.visitIfElement(this, context: context);
    resolver.pushRewrite(null);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
    caseClause?.accept(visitor);
    _thenElement.accept(visitor);
    _elseElement?.accept(visitor);
  }
}

sealed class IfElementOrStatementImpl<E extends AstNodeImpl>
    implements AstNodeImpl {
  /// Return the `case` clause used to match a pattern against the [expression].
  CaseClauseImpl? get caseClause;

  /// Return the expression used to either determine which of the statements is
  /// executed next or to compute the value matched against the pattern in the
  /// `case` clause.
  ExpressionImpl get expression;

  /// The node that is executed if the condition evaluates to `false`.
  E? get ifFalse;

  /// The node that is executed if the condition evaluates to `true`.
  E get ifTrue;
}

/// An if statement.
///
///    ifStatement ::=
///        'if' '(' [Expression] [CaseClause]? ')'[Statement]
///        ('else' [Statement])?
abstract final class IfStatement implements Statement {
  /// Return the `case` clause used to match a pattern against the [expression].
  CaseClause? get caseClause;

  /// Return the condition used to determine which of the statements is executed
  /// next.
  @Deprecated('Use expression instead')
  Expression get condition;

  /// Return the token representing the 'else' keyword, or `null` if there is no
  /// else statement.
  Token? get elseKeyword;

  /// Return the statement that is executed if the condition evaluates to
  /// `false`, or `null` if there is no else statement.
  Statement? get elseStatement;

  /// Return the expression used to either determine which of the statements is
  /// executed next or to compute the value matched against the pattern in the
  /// `case` clause.
  Expression get expression;

  /// Return the token representing the 'if' keyword.
  /// TODO(scheglov) Extract shared `IfCondition`, see the patterns spec.
  Token get ifKeyword;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the right parenthesis.
  Token get rightParenthesis;

  /// Return the statement that is executed if the condition evaluates to
  /// `true`.
  Statement get thenStatement;
}

/// An if statement.
///
///    ifStatement ::=
///        'if' '(' [Expression] [CaseClause]? ')'[Statement]
///        ('else' [Statement])?
final class IfStatementImpl extends StatementImpl
    implements IfStatement, IfElementOrStatementImpl<StatementImpl> {
  @override
  final Token ifKeyword;

  @override
  final Token leftParenthesis;

  /// The condition used to determine which of the branches is executed next.
  ExpressionImpl _expression;

  @override
  final CaseClauseImpl? caseClause;

  @override
  final Token rightParenthesis;

  @override
  final Token? elseKeyword;

  /// The statement that is executed if the condition evaluates to `true`.
  StatementImpl _thenStatement;

  /// The statement that is executed if the condition evaluates to `false`, or
  /// `null` if there is no else statement.
  StatementImpl? _elseStatement;

  /// Initialize a newly created if statement. The [elseKeyword] and
  /// [elseStatement] can be `null` if there is no else clause.
  IfStatementImpl({
    required this.ifKeyword,
    required this.leftParenthesis,
    required ExpressionImpl expression,
    required this.caseClause,
    required this.rightParenthesis,
    required StatementImpl thenStatement,
    required this.elseKeyword,
    required StatementImpl? elseStatement,
  })  : _expression = expression,
        _thenStatement = thenStatement,
        _elseStatement = elseStatement {
    _becomeParentOf(_expression);
    _becomeParentOf(caseClause);
    _becomeParentOf(_thenStatement);
    _becomeParentOf(_elseStatement);
  }

  @override
  Token get beginToken => ifKeyword;

  @Deprecated('Use expression instead')
  @override
  ExpressionImpl get condition => _expression;

  set condition(ExpressionImpl condition) {
    _expression = _becomeParentOf(condition);
  }

  @override
  StatementImpl? get elseStatement => _elseStatement;

  set elseStatement(StatementImpl? statement) {
    _elseStatement = _becomeParentOf(statement);
  }

  @override
  Token get endToken {
    if (_elseStatement != null) {
      return _elseStatement!.endToken;
    }
    return _thenStatement.endToken;
  }

  @override
  ExpressionImpl get expression => _expression;

  @override
  StatementImpl? get ifFalse => elseStatement;

  @override
  StatementImpl get ifTrue => thenStatement;

  @override
  StatementImpl get thenStatement => _thenStatement;

  set thenStatement(StatementImpl statement) {
    _thenStatement = _becomeParentOf(statement);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('ifKeyword', ifKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('expression', expression)
    ..addNode('caseClause', caseClause)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addNode('thenStatement', thenStatement)
    ..addToken('elseKeyword', elseKeyword)
    ..addNode('elseStatement', elseStatement);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitIfStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
    caseClause?.accept(visitor);
    _thenStatement.accept(visitor);
    _elseStatement?.accept(visitor);
  }
}

/// The "implements" clause in an class declaration.
///
///    implementsClause ::=
///        'implements' [NamedType] (',' [NamedType])*
abstract final class ImplementsClause implements AstNode {
  /// Return the token representing the 'implements' keyword.
  Token get implementsKeyword;

  /// Return the list of the interfaces that are being implemented.
  NodeList<NamedType> get interfaces;
}

/// The "implements" clause in an class declaration.
///
///    implementsClause ::=
///        'implements' [NamedType] (',' [NamedType])*
final class ImplementsClauseImpl extends AstNodeImpl
    implements ImplementsClause {
  /// The token representing the 'implements' keyword.
  @override
  final Token implementsKeyword;

  /// The interfaces that are being implemented.
  final NodeListImpl<NamedTypeImpl> _interfaces = NodeListImpl._();

  /// Initialize a newly created implements clause.
  ImplementsClauseImpl({
    required this.implementsKeyword,
    required List<NamedTypeImpl> interfaces,
  }) {
    _interfaces._initialize(this, interfaces);
  }

  @override
  Token get beginToken => implementsKeyword;

  @override
  Token get endToken => _interfaces.endToken ?? implementsKeyword;

  @override
  NodeListImpl<NamedTypeImpl> get interfaces => _interfaces;

  @override
  // TODO(paulberry): add commas.
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('implementsKeyword', implementsKeyword)
    ..addNodeList('interfaces', interfaces);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitImplementsClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _interfaces.accept(visitor);
  }
}

/// An expression representing an implicit 'call' method reference.
///
/// Objects of this type are not produced directly by the parser (because the
/// parser cannot tell whether an expression refers to a callable type); they
/// are produced at resolution time.
abstract final class ImplicitCallReference
    implements MethodReferenceExpression {
  /// Return the expression from which a `call` method is being referenced.
  Expression get expression;

  /// Return the element associated with the implicit 'call' reference based on
  /// the static types.
  @override
  MethodElement get staticElement;

  /// The type arguments being applied to the tear-off, or `null` if there are
  /// no type arguments.
  TypeArgumentList? get typeArguments;

  /// The actual type arguments being applied to the tear-off, either explicitly
  /// specified in [typeArguments], or inferred.
  ///
  /// Returns an empty list if the 'call' method does not have type parameters.
  List<DartType> get typeArgumentTypes;
}

final class ImplicitCallReferenceImpl extends ExpressionImpl
    implements ImplicitCallReference {
  ExpressionImpl _expression;

  TypeArgumentListImpl? _typeArguments;

  @override
  List<DartType> typeArgumentTypes;

  @override
  MethodElement staticElement;

  ImplicitCallReferenceImpl({
    required ExpressionImpl expression,
    required this.staticElement,
    required TypeArgumentListImpl? typeArguments,
    required this.typeArgumentTypes,
  })  : _expression = expression,
        _typeArguments = typeArguments {
    _becomeParentOf(_expression);
    _becomeParentOf(_typeArguments);
  }

  @override
  Token get beginToken => expression.beginToken;

  @override
  Token get endToken => typeArguments?.endToken ?? expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl value) {
    _expression = _becomeParentOf(value);
  }

  @override
  Precedence get precedence =>
      typeArguments == null ? expression.precedence : Precedence.postfix;

  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  set typeArguments(TypeArgumentListImpl? value) {
    _typeArguments = _becomeParentOf(value);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('expression', expression)
    ..addNode('typeArguments', typeArguments);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitImplicitCallReference(this);
  }

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitImplicitCallReference(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
    typeArguments?.accept(visitor);
  }
}

/// An import directive.
///
///    importDirective ::=
///        [Annotation] 'import' [StringLiteral] ('as' identifier)? [Combinator]* ';'
///      | [Annotation] 'import' [StringLiteral] 'deferred' 'as' identifier [Combinator]* ';'
abstract final class ImportDirective implements NamespaceDirective {
  /// Return the token representing the 'as' keyword, or `null` if the imported
  /// names are not prefixed.
  Token? get asKeyword;

  /// Return the token representing the 'deferred' keyword, or `null` if the
  /// imported URI is not deferred.
  Token? get deferredKeyword;

  /// Return the element associated with this directive, or `null` if the AST
  /// structure has not been resolved.
  @override
  LibraryImportElement? get element;

  /// The token representing the 'import' keyword.
  Token get importKeyword;

  /// Return the prefix to be used with the imported names, or `null` if the
  /// imported names are not prefixed.
  SimpleIdentifier? get prefix;
}

/// An import directive.
///
///    importDirective ::=
///        [Annotation] 'import' [StringLiteral] ('as' identifier)?
//         [Combinator]* ';'
///      | [Annotation] 'import' [StringLiteral] 'deferred' 'as' identifier
//         [Combinator]* ';'
final class ImportDirectiveImpl extends NamespaceDirectiveImpl
    implements ImportDirective {
  @override
  final Token importKeyword;

  /// The token representing the 'deferred' keyword, or `null` if the imported
  /// is not deferred.
  @override
  final Token? deferredKeyword;

  /// The token representing the 'as' keyword, or `null` if the imported names
  /// are not prefixed.
  @override
  final Token? asKeyword;

  /// The prefix to be used with the imported names, or `null` if the imported
  /// names are not prefixed.
  SimpleIdentifierImpl? _prefix;

  /// Initialize a newly created import directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the function does not have the
  /// corresponding attribute. The [deferredKeyword] can be `null` if the import
  /// is not deferred. The [asKeyword] and [prefix] can be `null` if the import
  /// does not specify a prefix. The list of [combinators] can be `null` if
  /// there are no combinators.
  ImportDirectiveImpl({
    required super.comment,
    required super.metadata,
    required this.importKeyword,
    required super.uri,
    required super.configurations,
    required this.deferredKeyword,
    required this.asKeyword,
    required SimpleIdentifierImpl? prefix,
    required super.combinators,
    required super.semicolon,
  }) : _prefix = prefix {
    _becomeParentOf(_prefix);
  }

  @override
  LibraryImportElementImpl? get element =>
      super.element as LibraryImportElementImpl?;

  @override
  Token get firstTokenAfterCommentAndMetadata => importKeyword;

  @override
  SimpleIdentifierImpl? get prefix => _prefix;

  set prefix(SimpleIdentifierImpl? identifier) {
    _prefix = _becomeParentOf(identifier);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('importKeyword', importKeyword)
    ..addNode('uri', uri)
    ..addToken('deferredKeyword', deferredKeyword)
    ..addToken('asKeyword', asKeyword)
    ..addNode('prefix', prefix)
    ..addNodeList('combinators', combinators)
    ..addNodeList('configurations', configurations)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitImportDirective(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    configurations.accept(visitor);
    _prefix?.accept(visitor);
    combinators.accept(visitor);
  }

  /// Return `true` if the non-URI components of the two directives are
  /// syntactically identical. URIs are checked outside to see if they resolve
  /// to the same absolute URI, so to the same library, regardless of the used
  /// syntax (absolute, relative, not normalized).
  static bool areSyntacticallyIdenticalExceptUri(
    NamespaceDirective node1,
    NamespaceDirective node2,
  ) {
    if (node1 is ImportDirective &&
        node2 is ImportDirective &&
        node1.prefix?.name != node2.prefix?.name) {
      return false;
    }

    bool areSameNames(
      List<SimpleIdentifier> names1,
      List<SimpleIdentifier> names2,
    ) {
      if (names1.length != names2.length) {
        return false;
      }
      for (var i = 0; i < names1.length; i++) {
        if (names1[i].name != names2[i].name) {
          return false;
        }
      }
      return true;
    }

    final combinators1 = node1.combinators;
    final combinators2 = node2.combinators;
    if (combinators1.length != combinators2.length) {
      return false;
    }
    for (var i = 0; i < combinators1.length; i++) {
      final combinator1 = combinators1[i];
      final combinator2 = combinators2[i];
      if (combinator1 is HideCombinator && combinator2 is HideCombinator) {
        if (!areSameNames(combinator1.hiddenNames, combinator2.hiddenNames)) {
          return false;
        }
      } else if (combinator1 is ShowCombinator &&
          combinator2 is ShowCombinator) {
        if (!areSameNames(combinator1.shownNames, combinator2.shownNames)) {
          return false;
        }
      } else {
        return false;
      }
    }

    return true;
  }
}

/// Reference to an import prefix name.
abstract final class ImportPrefixReference implements AstNode {
  /// The element to which [name] is resolved. Usually a [PrefixElement], but
  /// can be anything in invalid code.
  Element? get element;

  /// The name of the referenced import prefix.
  Token get name;

  /// The `.` that separates [name] from the following identifier.
  Token get period;
}

final class ImportPrefixReferenceImpl extends AstNodeImpl
    implements ImportPrefixReference {
  @override
  final Token name;

  @override
  final Token period;

  @override
  Element? element;

  ImportPrefixReferenceImpl({
    required this.name,
    required this.period,
  });

  @override
  Token get beginToken => name;

  @override
  Token get endToken => period;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('name', name)
    ..addToken('period', period);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitImportPrefixReference(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {}
}

/// An index expression.
///
///    indexExpression ::=
///        [Expression] '[' [Expression] ']'
abstract final class IndexExpression
    implements NullShortableExpression, MethodReferenceExpression {
  /// Return the expression used to compute the index.
  Expression get index;

  /// Return `true` if this expression is cascaded.
  ///
  /// If it is, then the target of this expression is not stored locally but is
  /// stored in the nearest ancestor that is a [CascadeExpression].
  bool get isCascaded;

  /// Whether this index expression is null aware (as opposed to non-null).
  bool get isNullAware;

  /// Return the left square bracket.
  Token get leftBracket;

  /// Return the period (".." | "?..") before a cascaded index expression, or
  /// `null` if this index expression is not part of a cascade expression.
  Token? get period;

  /// Return the question mark before the left bracket, or `null` if there is no
  /// question mark.
  Token? get question;

  /// Return the expression used to compute the object being indexed.
  ///
  /// If this index expression is not part of a cascade expression, then this
  /// is the same as [target]. If this index expression is part of a cascade
  /// expression, then the target expression stored with the cascade expression
  /// is returned.
  Expression get realTarget;

  /// Return the right square bracket.
  Token get rightBracket;

  /// Return the expression used to compute the object being indexed, or `null`
  /// if this index expression is part of a cascade expression.
  ///
  /// Use [realTarget] to get the target independent of whether this is part of
  /// a cascade expression.
  Expression? get target;

  /// Return `true` if this expression is computing a right-hand value (that is,
  /// if this expression is in a context where the operator '[]' will be
  /// invoked).
  ///
  /// Note that [inGetterContext] and [inSetterContext] are not opposites, nor
  /// are they mutually exclusive. In other words, it is possible for both
  /// methods to return `true` when invoked on the same node.
  // TODO(brianwilkerson) Convert this to a getter.
  bool inGetterContext();

  /// Return `true` if this expression is computing a left-hand value (that is,
  /// if this expression is in a context where the operator '[]=' will be
  /// invoked).
  ///
  /// Note that [inGetterContext] and [inSetterContext] are not opposites, nor
  /// are they mutually exclusive. In other words, it is possible for both
  /// methods to return `true` when invoked on the same node.
  // TODO(brianwilkerson) Convert this to a getter.
  bool inSetterContext();
}

/// An index expression.
///
///    indexExpression ::=
///        [Expression] '[' [Expression] ']'
final class IndexExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl
    implements IndexExpression {
  @override
  Token? period;

  /// The expression used to compute the object being indexed, or `null` if this
  /// index expression is part of a cascade expression.
  ExpressionImpl? _target;

  @override
  final Token? question;

  @override
  final Token leftBracket;

  /// The expression used to compute the index.
  ExpressionImpl _index;

  @override
  final Token rightBracket;

  /// The element associated with the operator based on the static type of the
  /// target, or `null` if the AST structure has not been resolved or if the
  /// operator could not be resolved.
  @override
  MethodElement? staticElement;

  /// Initialize a newly created index expression that is a child of a cascade
  /// expression.
  IndexExpressionImpl.forCascade({
    required this.period,
    required this.question,
    required this.leftBracket,
    required ExpressionImpl index,
    required this.rightBracket,
  }) : _index = index {
    _becomeParentOf(_index);
  }

  /// Initialize a newly created index expression that is not a child of a
  /// cascade expression.
  IndexExpressionImpl.forTarget({
    required ExpressionImpl? target,
    required this.question,
    required this.leftBracket,
    required ExpressionImpl index,
    required this.rightBracket,
  })  : _target = target,
        _index = index {
    _becomeParentOf(_target);
    _becomeParentOf(_index);
  }

  @override
  Token get beginToken {
    if (_target != null) {
      return _target!.beginToken;
    }
    return period!;
  }

  @override
  Token get endToken => rightBracket;

  @override
  ExpressionImpl get index => _index;

  set index(ExpressionImpl expression) {
    _index = _becomeParentOf(expression);
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
            period!.type == TokenType.QUESTION_PERIOD_PERIOD);
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  ExpressionImpl get realTarget {
    if (isCascaded) {
      return _ancestorCascade.target;
    }
    return _target!;
  }

  @override
  ExpressionImpl? get target => _target;

  set target(ExpressionImpl? expression) {
    _target = _becomeParentOf(expression);
  }

  /// Return the cascade that contains this [IndexExpression].
  ///
  /// We expect that [isCascaded] is `true`.
  CascadeExpressionImpl get _ancestorCascade {
    assert(isCascaded);
    for (var ancestor = parent!;; ancestor = ancestor.parent!) {
      if (ancestor is CascadeExpressionImpl) {
        return ancestor;
      }
    }
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('target', target)
    ..addToken('period', period)
    ..addToken('leftBracket', leftBracket)
    ..addNode('index', index)
    ..addToken('rightBracket', rightBracket);

  @override
  AstNode get _nullShortingExtensionCandidate => parent!;

  /// If the AST structure has been resolved, and the function being invoked is
  /// known based on static type information, then return the parameter element
  /// representing the parameter to which the value of the index expression will
  /// be bound. Otherwise, return `null`.
  ParameterElement? get _staticParameterElementForIndex {
    Element? element = staticElement;

    final parent = this.parent;
    if (parent is CompoundAssignmentExpression) {
      element = parent.writeElement ?? parent.readElement;
    }

    if (element is ExecutableElement) {
      List<ParameterElement> parameters = element.parameters;
      if (parameters.isEmpty) {
        return null;
      }
      return parameters[0];
    }
    return null;
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitIndexExpression(this);

  @override
  bool inGetterContext() {
    // TODO(brianwilkerson) Convert this to a getter.
    final parent = this.parent!;
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
    final parent = this.parent!;
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
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitIndexExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _target?.accept(visitor);
    _index.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression descendant) =>
      identical(descendant, _target);
}

/// An instance creation expression.
///
///    newExpression ::=
///        ('new' | 'const')? [NamedType] ('.' [SimpleIdentifier])? [ArgumentList]
abstract final class InstanceCreationExpression implements Expression {
  /// Return the list of arguments to the constructor.
  ArgumentList get argumentList;

  /// Return the name of the constructor to be invoked.
  ConstructorName get constructorName;

  /// Return `true` if this creation expression is used to invoke a constant
  /// constructor, either because the keyword `const` was explicitly provided or
  /// because no keyword was provided and this expression is in a constant
  /// context.
  bool get isConst;

  /// Return the 'new' or 'const' keyword used to indicate how an object should
  /// be created, or `null` if the keyword was not explicitly provided.
  Token? get keyword;
}

/// An instance creation expression.
///
///    newExpression ::=
///        ('new' | 'const')? [NamedType] ('.' [SimpleIdentifier])?
///        [ArgumentList]
final class InstanceCreationExpressionImpl extends ExpressionImpl
    implements InstanceCreationExpression {
  // TODO(brianwilkerson) Consider making InstanceCreationExpressionImpl extend
  // InvocationExpressionImpl. This would probably be a breaking change, but is
  // also probably worth it.

  /// The 'new' or 'const' keyword used to indicate how an object should be
  /// created, or `null` if the keyword is implicit.
  @override
  Token? keyword;

  /// The name of the constructor to be invoked.
  ConstructorNameImpl _constructorName;

  /// The type arguments associated with the constructor, rather than with the
  /// class in which the constructor is defined. It is always an error if there
  /// are type arguments because Dart doesn't currently support generic
  /// constructors, but we capture them in the AST in order to recover better.
  TypeArgumentListImpl? _typeArguments;

  /// The list of arguments to the constructor.
  ArgumentListImpl _argumentList;

  /// Initialize a newly created instance creation expression.
  InstanceCreationExpressionImpl({
    required this.keyword,
    required ConstructorNameImpl constructorName,
    required ArgumentListImpl argumentList,
    required TypeArgumentListImpl? typeArguments,
  })  : _constructorName = constructorName,
        _argumentList = argumentList,
        _typeArguments = typeArguments {
    _becomeParentOf(_constructorName);
    _becomeParentOf(_argumentList);
    _becomeParentOf(_typeArguments);
  }

  @override
  ArgumentListImpl get argumentList => _argumentList;

  set argumentList(ArgumentListImpl argumentList) {
    _argumentList = _becomeParentOf(argumentList);
  }

  @override
  Token get beginToken => keyword ?? _constructorName.beginToken;

  @override
  ConstructorNameImpl get constructorName => _constructorName;

  set constructorName(ConstructorNameImpl name) {
    _constructorName = _becomeParentOf(name);
  }

  @override
  Token get endToken => _argumentList.endToken;

  @override
  bool get isConst {
    if (!isImplicit) {
      return keyword!.keyword == Keyword.CONST;
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
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  /// Return the type arguments associated with the constructor, rather than
  /// with the class in which the constructor is defined. It is always an error
  /// if there are type arguments because Dart doesn't currently support generic
  /// constructors, but we capture them in the AST in order to recover better.
  set typeArguments(TypeArgumentListImpl? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('keyword', keyword)
    ..addNode('constructorName', constructorName)
    ..addNode('typeArguments', typeArguments)
    ..addNode('argumentList', argumentList);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitInstanceCreationExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitInstanceCreationExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _constructorName.accept(visitor);
    _typeArguments?.accept(visitor);
    _argumentList.accept(visitor);
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
abstract final class IntegerLiteral implements Literal {
  /// Return the token representing the literal.
  Token get literal;

  /// Return the value of the literal, or `null` when [literal] does not
  /// represent a valid `int` value, for example because of overflow.
  int? get value;
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
final class IntegerLiteralImpl extends LiteralImpl implements IntegerLiteral {
  /// The token representing the literal.
  @override
  final Token literal;

  /// The value of the literal.
  @override
  int? value = 0;

  /// Initialize a newly created integer literal.
  IntegerLiteralImpl({
    required this.literal,
    required this.value,
  });

  @override
  Token get beginToken => literal;

  @override
  Token get endToken => literal;

  /// Returns whether this literal's [parent] is a [PrefixExpression] of unary
  /// negation.
  ///
  /// Note: this does *not* indicate that the value itself is negated, just that
  /// the literal is the child of a negation operation. The literal value itself
  /// will always be positive.
  bool get immediatelyNegated {
    final parent = this.parent!;
    return parent is PrefixExpression &&
        parent.operator.type == TokenType.MINUS;
  }

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('literal', literal);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitIntegerLiteral(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitIntegerLiteral(this, contextType: contextType);
  }

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

    var fullPrecision = BigInt.tryParse(lexeme);
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
sealed class InterpolationElement implements AstNode {}

/// A node within a [StringInterpolation].
///
///    interpolationElement ::=
///        [InterpolationExpression]
///      | [InterpolationString]
sealed class InterpolationElementImpl extends AstNodeImpl
    implements InterpolationElement {}

/// An expression embedded in a string interpolation.
///
///    interpolationExpression ::=
///        '$' [SimpleIdentifier]
///      | '$' '{' [Expression] '}'
abstract final class InterpolationExpression implements InterpolationElement {
  /// Return the expression to be evaluated for the value to be converted into a
  /// string.
  Expression get expression;

  /// Return the token used to introduce the interpolation expression; either
  /// '$' if the expression is a simple identifier or '${' if the expression is
  /// a full expression.
  Token get leftBracket;

  /// Return the right curly bracket, or `null` if the expression is an
  /// identifier without brackets.
  Token? get rightBracket;
}

/// An expression embedded in a string interpolation.
///
///    interpolationExpression ::=
///        '$' [SimpleIdentifier]
///      | '$' '{' [Expression] '}'
final class InterpolationExpressionImpl extends InterpolationElementImpl
    implements InterpolationExpression {
  /// The token used to introduce the interpolation expression; either '$' if
  /// the expression is a simple identifier or '${' if the expression is a full
  /// expression.
  @override
  final Token leftBracket;

  /// The expression to be evaluated for the value to be converted into a
  /// string.
  ExpressionImpl _expression;

  /// The right curly bracket, or `null` if the expression is an identifier
  /// without brackets.
  @override
  final Token? rightBracket;

  /// Initialize a newly created interpolation expression.
  InterpolationExpressionImpl({
    required this.leftBracket,
    required ExpressionImpl expression,
    required this.rightBracket,
  }) : _expression = expression {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => leftBracket;

  @override
  Token get endToken => rightBracket ?? _expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftBracket', leftBracket)
    ..addNode('expression', expression)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitInterpolationExpression(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
  }
}

/// A non-empty substring of an interpolated string.
///
///    interpolationString ::=
///        characters
abstract final class InterpolationString implements InterpolationElement {
  /// Return the characters that will be added to the string.
  Token get contents;

  /// Return the offset of the after-last contents character.
  int get contentsEnd;

  /// Return the offset of the first contents character.
  int get contentsOffset;

  /// Return the value of the literal.
  String get value;
}

/// A non-empty substring of an interpolated string.
///
///    interpolationString ::=
///        characters
final class InterpolationStringImpl extends InterpolationElementImpl
    implements InterpolationString {
  /// The characters that will be added to the string.
  @override
  final Token contents;

  /// The value of the literal.
  @override
  String value;

  /// Initialize a newly created string of characters that are part of a string
  /// interpolation.
  InterpolationStringImpl({
    required this.contents,
    required this.value,
  });

  @override
  Token get beginToken => contents;

  @override
  int get contentsEnd => offset + _lexemeHelper.end;

  @override
  int get contentsOffset => contents.offset + _lexemeHelper.start;

  @override
  Token get endToken => contents;

  @override
  StringInterpolation get parent => super.parent as StringInterpolation;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('contents', contents);

  StringLexemeHelper get _lexemeHelper {
    String lexeme = contents.lexeme;
    return StringLexemeHelper(lexeme, identical(this, parent.elements.first),
        identical(this, parent.elements.last));
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitInterpolationString(this);

  @override
  void visitChildren(AstVisitor visitor) {}
}

/// The invocation of a function or method; either a
/// [FunctionExpressionInvocation] or a [MethodInvocation].
abstract final class InvocationExpression implements Expression {
  /// Return the list of arguments to the method.
  ArgumentList get argumentList;

  /// The expression that identifies the function or method being invoked.
  /// For example:
  ///
  ///     (o.m)<TArgs>(args); // target will be `o.m`
  ///     o.m<TArgs>(args);   // target will be `m`
  ///
  /// In either case, the [function.staticType] will be the
  /// [staticInvokeType] before applying type arguments `TArgs`.
  Expression get function;

  /// Return the function type of the invocation based on the static type
  /// information, or `null` if the AST structure has not been resolved, or if
  /// the invoke could not be resolved.
  ///
  /// This will usually be a [FunctionType], but it can also be `dynamic` or
  /// `Function`. In the case of interface types that have a `call` method, we
  /// store the type of that `call` method here as parameterized.
  DartType? get staticInvokeType;

  /// Return the type arguments to be applied to the method being invoked, or
  /// `null` if no type arguments were provided.
  TypeArgumentList? get typeArguments;

  /// Return the actual type arguments of the invocation, either explicitly
  /// specified in [typeArguments], or inferred.
  ///
  /// If the AST has been resolved, never returns `null`, returns an empty list
  /// if the [function] does not have type parameters.
  ///
  /// Return `null` if the AST structure has not been resolved.
  List<DartType>? get typeArgumentTypes;
}

/// Common base class for [FunctionExpressionInvocationImpl] and
/// [MethodInvocationImpl].
sealed class InvocationExpressionImpl extends ExpressionImpl
    implements InvocationExpression {
  /// The list of arguments to the function.
  ArgumentListImpl _argumentList;

  /// The type arguments to be applied to the method being invoked, or `null` if
  /// no type arguments were provided.
  TypeArgumentListImpl? _typeArguments;

  @override
  List<DartType>? typeArgumentTypes;

  @override
  DartType? staticInvokeType;

  /// Initialize a newly created invocation.
  InvocationExpressionImpl({
    required TypeArgumentListImpl? typeArguments,
    required ArgumentListImpl argumentList,
  })  : _typeArguments = typeArguments,
        _argumentList = argumentList {
    _becomeParentOf(_typeArguments);
    _becomeParentOf(_argumentList);
  }

  @override
  ArgumentListImpl get argumentList => _argumentList;

  set argumentList(ArgumentListImpl argumentList) {
    _argumentList = _becomeParentOf(argumentList);
  }

  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  set typeArguments(TypeArgumentListImpl? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }
}

/// An is expression.
///
///    isExpression ::=
///        [Expression] 'is' '!'? [TypeAnnotation]
abstract final class IsExpression implements Expression {
  /// Return the expression used to compute the value whose type is being
  /// tested.
  Expression get expression;

  /// Return the is operator.
  Token get isOperator;

  /// Return the not operator, or `null` if the sense of the test is not
  /// negated.
  Token? get notOperator;

  /// Return the type being tested for.
  TypeAnnotation get type;
}

/// An is expression.
///
///    isExpression ::=
///        [Expression] 'is' '!'? [NamedType]
final class IsExpressionImpl extends ExpressionImpl implements IsExpression {
  /// The expression used to compute the value whose type is being tested.
  ExpressionImpl _expression;

  /// The is operator.
  @override
  final Token isOperator;

  /// The not operator, or `null` if the sense of the test is not negated.
  @override
  final Token? notOperator;

  /// The name of the type being tested for.
  TypeAnnotationImpl _type;

  /// Initialize a newly created is expression. The [notOperator] can be `null`
  /// if the sense of the test is not negated.
  IsExpressionImpl({
    required ExpressionImpl expression,
    required this.isOperator,
    required this.notOperator,
    required TypeAnnotationImpl type,
  })  : _expression = expression,
        _type = type {
    _becomeParentOf(_expression);
    _becomeParentOf(_type);
  }

  @override
  Token get beginToken => _expression.beginToken;

  @override
  Token get endToken => _type.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.relational;

  @override
  TypeAnnotationImpl get type => _type;

  set type(TypeAnnotationImpl type) {
    _type = _becomeParentOf(type);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('expression', expression)
    ..addToken('isOperator', isOperator)
    ..addToken('notOperator', notOperator)
    ..addNode('type', type);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitIsExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitIsExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
    _type.accept(visitor);
  }
}

/// A label on either a [LabeledStatement] or a [NamedExpression].
///
///    label ::=
///        [SimpleIdentifier] ':'
abstract final class Label implements AstNode {
  /// Return the colon that separates the label from the statement.
  Token get colon;

  /// Return the label being associated with the statement.
  SimpleIdentifier get label;
}

/// A statement that has a label associated with them.
///
///    labeledStatement ::=
///       [Label]+ [Statement]
abstract final class LabeledStatement implements Statement {
  /// Return the labels being associated with the statement.
  NodeList<Label> get labels;

  /// Return the statement with which the labels are being associated.
  Statement get statement;
}

/// A statement that has a label associated with them.
///
///    labeledStatement ::=
///       [Label]+ [Statement]
final class LabeledStatementImpl extends StatementImpl
    implements LabeledStatement {
  /// The labels being associated with the statement.
  final NodeListImpl<LabelImpl> _labels = NodeListImpl._();

  /// The statement with which the labels are being associated.
  StatementImpl _statement;

  /// Initialize a newly created labeled statement.
  LabeledStatementImpl({
    required List<LabelImpl> labels,
    required StatementImpl statement,
  }) : _statement = statement {
    _labels._initialize(this, labels);
    _becomeParentOf(_statement);
  }

  @override
  Token get beginToken {
    if (_labels.isNotEmpty) {
      return _labels.beginToken!;
    }
    return _statement.beginToken;
  }

  @override
  Token get endToken => _statement.endToken;

  @override
  NodeListImpl<LabelImpl> get labels => _labels;

  @override
  StatementImpl get statement => _statement;

  set statement(StatementImpl statement) {
    _statement = _becomeParentOf(statement);
  }

  @override
  StatementImpl get unlabeled => _statement.unlabeled;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNodeList('labels', labels)
    ..addNode('statement', statement);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitLabeledStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _labels.accept(visitor);
    _statement.accept(visitor);
  }
}

/// A label on either a [LabeledStatement] or a [NamedExpression].
///
///    label ::=
///        [SimpleIdentifier] ':'
final class LabelImpl extends AstNodeImpl implements Label {
  /// The label being associated with the statement.
  SimpleIdentifierImpl _label;

  /// The colon that separates the label from the statement.
  @override
  final Token colon;

  /// Initialize a newly created label.
  LabelImpl({
    required SimpleIdentifierImpl label,
    required this.colon,
  }) : _label = label {
    _becomeParentOf(_label);
  }

  @override
  Token get beginToken => _label.beginToken;

  @override
  Token get endToken => colon;

  @override
  SimpleIdentifierImpl get label => _label;

  set label(SimpleIdentifierImpl label) {
    _label = _becomeParentOf(label);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('label', label)
    ..addToken('colon', colon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitLabel(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _label.accept(visitor);
  }
}

/// A library augmentation directive.
///
///    libraryAugmentationDirective ::=
///        [metadata] 'library' 'augment' [StringLiteral] ';'
@experimental
abstract final class LibraryAugmentationDirective implements UriBasedDirective {
  /// Return the token representing the 'augment' keyword.
  Token get augmentKeyword;

  /// Return the token representing the 'library' keyword.
  Token get libraryKeyword;

  /// Return the semicolon terminating the directive.
  Token get semicolon;
}

/// A library directive.
///
///    libraryAugmentationDirective ::=
///        [metadata] 'library' 'augment' [StringLiteral] ';'
@experimental
final class LibraryAugmentationDirectiveImpl extends UriBasedDirectiveImpl
    implements LibraryAugmentationDirective {
  @override
  final Token libraryKeyword;

  @override
  final Token augmentKeyword;

  @override
  final Token semicolon;

  LibraryAugmentationDirectiveImpl({
    required super.comment,
    required super.metadata,
    required this.libraryKeyword,
    required this.augmentKeyword,
    required super.uri,
    required this.semicolon,
  });

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => libraryKeyword;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('libraryKeyword', libraryKeyword)
    ..addToken('augmentKeyword', augmentKeyword)
    ..addNode('uri', uri)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitLibraryAugmentationDirective(this);
  }
}

/// A library directive.
///
///    libraryDirective ::=
///        [Annotation] 'library' [LibraryIdentifier]? ';'
abstract final class LibraryDirective implements Directive {
  /// Return the token representing the 'library' keyword.
  Token get libraryKeyword;

  /// Return the name of the library being defined.
  LibraryIdentifier? get name2;

  /// Return the semicolon terminating the directive.
  Token get semicolon;
}

/// A library directive.
///
///    libraryDirective ::=
///        [Annotation] 'library' [Identifier] ';'
final class LibraryDirectiveImpl extends DirectiveImpl
    implements LibraryDirective {
  /// The token representing the 'library' keyword.
  @override
  final Token libraryKeyword;

  /// The name of the library being defined.
  LibraryIdentifierImpl? _name;

  /// The semicolon terminating the directive.
  @override
  final Token semicolon;

  /// Initialize a newly created library directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute.
  LibraryDirectiveImpl({
    required super.comment,
    required super.metadata,
    required this.libraryKeyword,
    required LibraryIdentifierImpl? name,
    required this.semicolon,
  }) : _name = name {
    _becomeParentOf(_name);
  }

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => libraryKeyword;

  set name(LibraryIdentifierImpl? name) {
    _name = _becomeParentOf(name);
  }

  @override
  LibraryIdentifierImpl? get name2 => _name;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('libraryKeyword', libraryKeyword)
    ..addNode('name', name2)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitLibraryDirective(this);

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
abstract final class LibraryIdentifier implements Identifier {
  /// Return the components of the identifier.
  NodeList<SimpleIdentifier> get components;
}

/// The identifier for a library.
///
///    libraryIdentifier ::=
///        [SimpleIdentifier] ('.' [SimpleIdentifier])*
final class LibraryIdentifierImpl extends IdentifierImpl
    implements LibraryIdentifier {
  /// The components of the identifier.
  final NodeListImpl<SimpleIdentifierImpl> _components = NodeListImpl._();

  /// Initialize a newly created prefixed identifier.
  LibraryIdentifierImpl({
    required List<SimpleIdentifierImpl> components,
  }) {
    _components._initialize(this, components);
  }

  @override
  Token get beginToken => _components.beginToken!;

  @override
  NodeListImpl<SimpleIdentifierImpl> get components => _components;

  @override
  Token get endToken => _components.endToken!;

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
    return considerCanonicalizeString(buffer.toString());
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  Element? get staticElement => null;

  @override
  // TODO(paulberry): add "." tokens.
  ChildEntities get _childEntities =>
      ChildEntities()..addNodeList('components', components);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitLibraryIdentifier(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitLibraryIdentifier(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _components.accept(visitor);
  }
}

/// A list literal.
///
///    listLiteral ::=
///        'const'? [TypeAnnotationList]? '[' elements? ']'
///
///    elements ::=
///        [CollectionElement] (',' [CollectionElement])* ','?
abstract final class ListLiteral implements TypedLiteral {
  /// Return the syntactic elements used to compute the elements of the list.
  NodeList<CollectionElement> get elements;

  /// Return the left square bracket.
  Token get leftBracket;

  /// Return the right square bracket.
  Token get rightBracket;
}

final class ListLiteralImpl extends TypedLiteralImpl implements ListLiteral {
  /// The left square bracket.
  @override
  final Token leftBracket;

  /// The expressions used to compute the elements of the list.
  final NodeListImpl<CollectionElementImpl> _elements = NodeListImpl._();

  /// The right square bracket.
  @override
  final Token rightBracket;

  /// Initialize a newly created list literal. The [constKeyword] can be `null`
  /// if the literal is not a constant. The [typeArguments] can be `null` if no
  /// type arguments were declared. The list of [elements] can be `null` if the
  /// list is empty.
  ListLiteralImpl({
    required super.constKeyword,
    required super.typeArguments,
    required this.leftBracket,
    required List<CollectionElementImpl> elements,
    required this.rightBracket,
  }) {
    _elements._initialize(this, elements);
  }

  @override
  Token get beginToken {
    if (constKeyword != null) {
      return constKeyword!;
    }
    final typeArguments = this.typeArguments;
    if (typeArguments != null) {
      return typeArguments.beginToken;
    }
    return leftBracket;
  }

  @override
  NodeListImpl<CollectionElementImpl> get elements => _elements;

  @override
  Token get endToken => rightBracket;

  @override
  // TODO(paulberry): add commas.
  ChildEntities get _childEntities => super._childEntities
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('elements', elements)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitListLiteral(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitListLiteral(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _elements.accept(visitor);
  }
}

/// A list pattern.
///
///    listPattern ::=
///        [TypeArgumentList]? '[' [DartPattern] (',' [DartPattern])* ','? ']'
abstract final class ListPattern implements DartPattern {
  /// Return the elements in this pattern.
  NodeList<ListPatternElement> get elements;

  /// Return the left square bracket.
  Token get leftBracket;

  /// The required type, specified by [typeArguments] or inferred from the
  /// matched value type; or `null` if the node is not resolved yet.
  DartType? get requiredType;

  /// Return the right square bracket.
  Token get rightBracket;

  /// Return the type arguments associated with this pattern, or `null` if no
  /// type arguments were declared.
  TypeArgumentList? get typeArguments;
}

/// An element of a list pattern.
sealed class ListPatternElement implements AstNode {}

abstract final class ListPatternElementImpl
    implements AstNodeImpl, ListPatternElement {}

/// A list pattern.
///
///    listPattern ::=
///        [TypeArgumentList]? '[' [DartPattern] (',' [DartPattern])* ','? ']'
final class ListPatternImpl extends DartPatternImpl implements ListPattern {
  @override
  final TypeArgumentListImpl? typeArguments;

  @override
  final Token leftBracket;

  final NodeListImpl<ListPatternElementImpl> _elements = NodeListImpl._();

  @override
  final Token rightBracket;

  @override
  DartType? requiredType;

  ListPatternImpl({
    required this.typeArguments,
    required this.leftBracket,
    required List<ListPatternElementImpl> elements,
    required this.rightBracket,
  }) {
    _becomeParentOf(typeArguments);
    _elements._initialize(this, elements);
  }

  @override
  Token get beginToken => typeArguments?.beginToken ?? leftBracket;

  @override
  NodeList<ListPatternElementImpl> get elements => _elements;

  @override
  Token get endToken => rightBracket;

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('typeArguments', typeArguments)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('elements', elements)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitListPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    var elementType = typeArguments?.arguments.elementAtOrNull(0)?.typeOrThrow;
    return resolverVisitor.analyzeListPatternSchema(
      elementType: elementType,
      elements: elements,
    );
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.listPatternResolver.resolve(node: this, context: context);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    typeArguments?.accept(visitor);
    elements.accept(visitor);
  }
}

/// A node that represents a literal expression.
///
///    literal ::=
///        [BooleanLiteral]
///      | [DoubleLiteral]
///      | [IntegerLiteral]
///      | [ListLiteral]
///      | [NullLiteral]
///      | [SetOrMapLiteral]
///      | [StringLiteral]
sealed class Literal implements Expression {}

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
sealed class LiteralImpl extends ExpressionImpl implements Literal {
  @override
  Precedence get precedence => Precedence.primary;
}

/// Additional information about local variables within a function or method
/// produced at resolution time.
class LocalVariableInfo {
  /// The set of local variables and parameters that are potentially mutated
  /// within the scope of their declarations.
  final Set<VariableElement> potentiallyMutatedInScope = <VariableElement>{};
}

/// A logical-and pattern.
///
///    logicalAndPattern ::=
///        [DartPattern] '&&' [DartPattern]
abstract final class LogicalAndPattern implements DartPattern {
  /// The left sub-pattern.
  DartPattern get leftOperand;

  /// The `&&` operator.
  Token get operator;

  /// The right sub-pattern.
  DartPattern get rightOperand;
}

/// A logical-and pattern.
///
///    logicalAndPattern ::=
///        [DartPattern] '&&' [DartPattern]
final class LogicalAndPatternImpl extends DartPatternImpl
    implements LogicalAndPattern {
  @override
  final DartPatternImpl leftOperand;

  @override
  final Token operator;

  @override
  final DartPatternImpl rightOperand;

  LogicalAndPatternImpl({
    required this.leftOperand,
    required this.operator,
    required this.rightOperand,
  }) {
    _becomeParentOf(leftOperand);
    _becomeParentOf(rightOperand);
  }

  @override
  Token get beginToken => leftOperand.beginToken;

  @override
  Token get endToken => rightOperand.endToken;

  @override
  PatternPrecedence get precedence => PatternPrecedence.logicalAnd;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('leftOperand', leftOperand)
    ..addToken('operator', operator)
    ..addNode('rightOperand', rightOperand);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitLogicalAndPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor.analyzeLogicalAndPatternSchema(
        leftOperand, rightOperand);
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.analyzeLogicalAndPattern(
        context, this, leftOperand, rightOperand);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    leftOperand.accept(visitor);
    rightOperand.accept(visitor);
  }
}

/// A logical-or pattern.
///
///    logicalOrPattern ::=
///        [DartPattern] '||' [DartPattern]
abstract final class LogicalOrPattern implements DartPattern {
  /// The left sub-pattern.
  DartPattern get leftOperand;

  /// The `||` operator.
  Token get operator;

  /// The right sub-pattern.
  DartPattern get rightOperand;
}

/// A logical-or pattern.
///
///    logicalOrPattern ::=
///        [DartPattern] '||' [DartPattern]
final class LogicalOrPatternImpl extends DartPatternImpl
    implements LogicalOrPattern {
  @override
  final DartPatternImpl leftOperand;

  @override
  final Token operator;

  @override
  final DartPatternImpl rightOperand;

  LogicalOrPatternImpl({
    required this.leftOperand,
    required this.operator,
    required this.rightOperand,
  }) {
    _becomeParentOf(leftOperand);
    _becomeParentOf(rightOperand);
  }

  @override
  Token get beginToken => leftOperand.beginToken;

  @override
  Token get endToken => rightOperand.endToken;

  @override
  PatternPrecedence get precedence => PatternPrecedence.logicalOr;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('leftOperand', leftOperand)
    ..addToken('operator', operator)
    ..addNode('rightOperand', rightOperand);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitLogicalOrPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor.analyzeLogicalOrPatternSchema(
        leftOperand, rightOperand);
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.analyzeLogicalOrPattern(
        context, this, leftOperand, rightOperand);
    resolverVisitor.nullSafetyDeadCodeVerifier.flowEnd(rightOperand);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    leftOperand.accept(visitor);
    rightOperand.accept(visitor);
  }
}

/// A single key/value pair in a map literal.
///
///    mapLiteralEntry ::=
///        [Expression] ':' [Expression]
abstract final class MapLiteralEntry implements CollectionElement {
  /// Return the expression computing the key with which the value will be
  /// associated.
  Expression get key;

  /// Return the colon that separates the key from the value.
  Token get separator;

  /// Return the expression computing the value that will be associated with the
  /// key.
  Expression get value;
}

/// A single key/value pair in a map literal.
///
///    mapLiteralEntry ::=
///        [Expression] ':' [Expression]
final class MapLiteralEntryImpl extends CollectionElementImpl
    implements MapLiteralEntry {
  /// The expression computing the key with which the value will be associated.
  ExpressionImpl _key;

  /// The colon that separates the key from the value.
  @override
  final Token separator;

  /// The expression computing the value that will be associated with the key.
  ExpressionImpl _value;

  /// Initialize a newly created map literal entry.
  MapLiteralEntryImpl({
    required ExpressionImpl key,
    required this.separator,
    required ExpressionImpl value,
  })  : _key = key,
        _value = value {
    _becomeParentOf(_key);
    _becomeParentOf(_value);
  }

  @override
  Token get beginToken => _key.beginToken;

  @override
  Token get endToken => _value.endToken;

  @override
  ExpressionImpl get key => _key;

  set key(ExpressionImpl string) {
    _key = _becomeParentOf(string);
  }

  @override
  ExpressionImpl get value => _value;

  set value(ExpressionImpl expression) {
    _value = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('key', key)
    ..addToken('separator', separator)
    ..addNode('value', value);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMapLiteralEntry(this);

  @override
  void resolveElement(
      ResolverVisitor resolver, CollectionLiteralContext? context) {
    resolver.visitMapLiteralEntry(this, context: context);
    resolver.pushRewrite(null);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _key.accept(visitor);
    _value.accept(visitor);
  }
}

/// A map pattern.
///
///    mapPattern ::=
///        [TypeArgumentList]? '{' [MapPatternEntry] (',' [MapPatternEntry])*
///        ','? '}'
abstract final class MapPattern implements DartPattern {
  /// Return the elements in this pattern.
  NodeList<MapPatternElement> get elements;

  /// Return the left curly bracket.
  Token get leftBracket;

  /// The matched value type, or `null` if the node is not resolved yet.
  DartType? get requiredType;

  /// Return the right curly bracket.
  Token get rightBracket;

  /// Return the type arguments associated with this pattern, or `null` if no
  /// type arguments were declared.
  TypeArgumentList? get typeArguments;
}

/// An element of a map pattern.
sealed class MapPatternElement implements AstNode {}

sealed class MapPatternElementImpl implements AstNodeImpl, MapPatternElement {}

/// An entry in a map pattern.
///
///    mapPatternEntry ::=
///        [Expression] ':' [DartPattern]
abstract final class MapPatternEntry implements AstNode, MapPatternElement {
  /// Return the expression computing the key of the entry to be matched.
  Expression get key;

  /// Return the colon that separates the key from the value.
  Token get separator;

  /// Return the pattern used to match the value.
  DartPattern get value;
}

/// An entry in a map pattern.
///
///    mapPatternEntry ::=
///        [Expression] ':' [DartPattern]
final class MapPatternEntryImpl extends AstNodeImpl
    implements MapPatternEntry, MapPatternElementImpl {
  ExpressionImpl _key;

  @override
  final Token separator;

  @override
  final DartPatternImpl value;

  MapPatternEntryImpl({
    required ExpressionImpl key,
    required this.separator,
    required this.value,
  }) : _key = key {
    _becomeParentOf(_key);
    _becomeParentOf(value);
  }

  @override
  Token get beginToken => key.beginToken;

  @override
  Token get endToken => value.endToken;

  @override
  ExpressionImpl get key => _key;

  set key(ExpressionImpl key) {
    _key = _becomeParentOf(key);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('key', key)
    ..addToken('separator', separator)
    ..addNode('value', value);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMapPatternEntry(this);

  @override
  void visitChildren(AstVisitor visitor) {
    key.accept(visitor);
    value.accept(visitor);
  }
}

/// A map pattern.
///
///    mapPattern ::=
///        [TypeArgumentList]? '{' [MapPatternEntry] (',' [MapPatternEntry])*
///        ','? '}'
final class MapPatternImpl extends DartPatternImpl implements MapPattern {
  @override
  final TypeArgumentListImpl? typeArguments;

  @override
  final Token leftBracket;

  final NodeListImpl<MapPatternElementImpl> _elements = NodeListImpl._();

  @override
  final Token rightBracket;

  @override
  DartType? requiredType;

  MapPatternImpl({
    required this.typeArguments,
    required this.leftBracket,
    required List<MapPatternElementImpl> elements,
    required this.rightBracket,
  }) {
    _becomeParentOf(typeArguments);
    _elements._initialize(this, elements);
  }

  @override
  Token get beginToken => typeArguments?.beginToken ?? leftBracket;

  @override
  NodeList<MapPatternElementImpl> get elements => _elements;

  @override
  Token get endToken => rightBracket;

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('typeArguments', typeArguments)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('elements', elements)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMapPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    shared.MapPatternTypeArguments<DartType>? typeArguments;
    final typeArgumentNodes = this.typeArguments?.arguments;
    if (typeArgumentNodes != null && typeArgumentNodes.length == 2) {
      typeArguments = shared.MapPatternTypeArguments(
        keyType: typeArgumentNodes[0].typeOrThrow,
        valueType: typeArgumentNodes[1].typeOrThrow,
      );
    }
    return resolverVisitor.analyzeMapPatternSchema(
      typeArguments: typeArguments,
      elements: elements,
    );
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.resolveMapPattern(node: this, context: context);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    typeArguments?.accept(visitor);
    elements.accept(visitor);
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
///
/// Prior to the 'extension-methods' experiment, these nodes were always
/// children of a class declaration. When the experiment is enabled, these nodes
/// can also be children of an extension declaration.
abstract final class MethodDeclaration implements ClassMember {
  /// The token for the 'augment' keyword.
  Token? get augmentKeyword;

  /// Return the body of the method.
  FunctionBody get body;

  @override
  ExecutableElement? get declaredElement;

  /// Return the token for the 'external' keyword, or `null` if the constructor
  /// is not external.
  Token? get externalKeyword;

  /// Return `true` if this method is declared to be an abstract method.
  bool get isAbstract;

  /// Return `true` if this method declares a getter.
  bool get isGetter;

  /// Return `true` if this method declares an operator.
  bool get isOperator;

  /// Return `true` if this method declares a setter.
  bool get isSetter;

  /// Return `true` if this method is declared to be a static method.
  bool get isStatic;

  /// Return the token representing the 'abstract' or 'static' keyword, or
  /// `null` if neither modifier was specified.
  Token? get modifierKeyword;

  /// Return the name of the method.
  Token get name;

  /// Return the token representing the 'operator' keyword, or `null` if this
  /// method does not declare an operator.
  Token? get operatorKeyword;

  /// Return the parameters associated with the method, or `null` if this method
  /// declares a getter.
  FormalParameterList? get parameters;

  /// Return the token representing the 'get' or 'set' keyword, or `null` if
  /// this is a method declaration rather than a property declaration.
  Token? get propertyKeyword;

  /// Return the return type of the method, or `null` if no return type was
  /// declared.
  TypeAnnotation? get returnType;

  /// Return the type parameters associated with this method, or `null` if this
  /// method is not a generic method.
  TypeParameterList? get typeParameters;
}

final class MethodDeclarationImpl extends ClassMemberImpl
    implements MethodDeclaration {
  @override
  final Token? augmentKeyword;

  @override
  final Token? externalKeyword;

  @override
  final Token? modifierKeyword;

  @override
  final TypeAnnotationImpl? returnType;

  @override
  final Token? propertyKeyword;

  @override
  final Token? operatorKeyword;

  @override
  final Token name;

  @override
  final TypeParameterListImpl? typeParameters;

  @override
  final FormalParameterListImpl? parameters;

  @override
  final FunctionBodyImpl body;

  @override
  ExecutableElementImpl? declaredElement;

  MethodDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
    required this.externalKeyword,
    required this.modifierKeyword,
    required this.returnType,
    required this.propertyKeyword,
    required this.operatorKeyword,
    required this.name,
    required this.typeParameters,
    required this.parameters,
    required this.body,
  }) {
    _becomeParentOf(returnType);
    _becomeParentOf(typeParameters);
    _becomeParentOf(parameters);
    _becomeParentOf(body);
  }

  @override
  Token get endToken => body.endToken;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return augmentKeyword ??
        Token.lexicallyFirst(externalKeyword, modifierKeyword) ??
        returnType?.beginToken ??
        Token.lexicallyFirst(propertyKeyword, operatorKeyword) ??
        name;
  }

  @override
  bool get isAbstract {
    final body = this.body;
    return externalKeyword == null &&
        (body is EmptyFunctionBodyImpl && !body.semicolon.isSynthetic);
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
  ChildEntities get _childEntities => super._childEntities
    ..addToken('augmentKeyword', augmentKeyword)
    ..addToken('externalKeyword', externalKeyword)
    ..addToken('modifierKeyword', modifierKeyword)
    ..addNode('returnType', returnType)
    ..addToken('propertyKeyword', propertyKeyword)
    ..addToken('operatorKeyword', operatorKeyword)
    ..addToken('name', name)
    ..addNode('parameters', parameters)
    ..addNode('body', body);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMethodDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    returnType?.accept(visitor);
    typeParameters?.accept(visitor);
    parameters?.accept(visitor);
    body.accept(visitor);
  }
}

/// The invocation of either a function or a method.
///
/// Invocations of functions resulting from evaluating an expression are
/// represented by [FunctionExpressionInvocation] nodes. Invocations of getters
/// and setters are represented by either [PrefixedIdentifier] or
/// [PropertyAccess] nodes.
///
///    methodInvocation ::=
///        ([Expression] '.')? [SimpleIdentifier] [TypeArgumentList]? [ArgumentList]
abstract final class MethodInvocation
    implements NullShortableExpression, InvocationExpression {
  /// Return `true` if this expression is cascaded.
  ///
  /// If it is, then the target of this expression is not stored locally but is
  /// stored in the nearest ancestor that is a [CascadeExpression].
  bool get isCascaded;

  /// Whether this method invocation is null aware (as opposed to non-null).
  bool get isNullAware;

  /// Return the name of the method being invoked.
  SimpleIdentifier get methodName;

  /// Return the operator that separates the target from the method name, or
  /// `null` if there is no target.
  ///
  /// In an ordinary method invocation this will be period ('.'). In a cascade
  /// section this will be the cascade operator ('..').
  Token? get operator;

  /// Return the expression used to compute the receiver of the invocation.
  ///
  /// If this invocation is not part of a cascade expression, then this is the
  /// same as [target]. If this invocation is part of a cascade expression,
  /// then the target stored with the cascade expression is returned.
  Expression? get realTarget;

  /// Return the expression producing the object on which the method is defined,
  /// or `null` if there is no target (that is, the target is implicitly `this`)
  /// or if this method invocation is part of a cascade expression.
  ///
  /// Use [realTarget] to get the target independent of whether this is part of
  /// a cascade expression.
  Expression? get target;
}

/// The invocation of either a function or a method. Invocations of functions
/// resulting from evaluating an expression are represented by
/// [FunctionExpressionInvocation] nodes. Invocations of getters and setters are
/// represented by either [PrefixedIdentifier] or [PropertyAccess] nodes.
///
///    methodInvocation ::=
///        ([Expression] '.')? [SimpleIdentifier] [TypeArgumentList]?
///        [ArgumentList]
final class MethodInvocationImpl extends InvocationExpressionImpl
    with NullShortableExpressionImpl
    implements MethodInvocation {
  /// The expression producing the object on which the method is defined, or
  /// `null` if there is no target (that is, the target is implicitly `this`).
  ExpressionImpl? _target;

  /// The operator that separates the target from the method name, or `null`
  /// if there is no target. In an ordinary method invocation this will be a
  /// period ('.'). In a cascade section this will be the cascade operator
  /// ('..' | '?..').
  @override
  Token? operator;

  /// The name of the method being invoked.
  SimpleIdentifierImpl _methodName;

  /// The invoke type of the [methodName] if the target element is a getter,
  /// or `null` otherwise.
  DartType? _methodNameType;

  /// Initialize a newly created method invocation. The [target] and [operator]
  /// can be `null` if there is no target.
  MethodInvocationImpl({
    required ExpressionImpl? target,
    required this.operator,
    required SimpleIdentifierImpl methodName,
    required super.typeArguments,
    required super.argumentList,
  })  : _target = target,
        _methodName = methodName {
    _becomeParentOf(_target);
    _becomeParentOf(_methodName);
  }

  @override
  Token get beginToken {
    if (_target != null) {
      return _target!.beginToken;
    } else if (operator != null) {
      return operator!;
    }
    return _methodName.beginToken;
  }

  @override
  Token get endToken => _argumentList.endToken;

  @override
  ExpressionImpl get function => methodName;

  @override
  bool get isCascaded =>
      operator != null &&
      (operator!.type == TokenType.PERIOD_PERIOD ||
          operator!.type == TokenType.QUESTION_PERIOD_PERIOD);

  @override
  bool get isNullAware {
    if (isCascaded) {
      return _ancestorCascade.isNullAware;
    }
    return operator != null &&
        (operator!.type == TokenType.QUESTION_PERIOD ||
            operator!.type == TokenType.QUESTION_PERIOD_PERIOD);
  }

  @override
  SimpleIdentifierImpl get methodName => _methodName;

  set methodName(SimpleIdentifierImpl identifier) {
    _methodName = _becomeParentOf(identifier);
  }

  /// The invoke type of the [methodName].
  ///
  /// If the target element is a [MethodElement], this is the same as the
  /// [staticInvokeType]. If the target element is a getter, presumably
  /// returning an [ExecutableElement] so that it can be invoked in this
  /// [MethodInvocation], then this type is the type of the getter, and the
  /// [staticInvokeType] is the invoked type of the returned element.
  DartType? get methodNameType => _methodNameType ?? staticInvokeType;

  /// Set the [methodName] invoke type, only if the target element is a getter.
  /// Otherwise, the target element itself is invoked, [_methodNameType] is
  /// `null`, and the getter will return [staticInvokeType].
  set methodNameType(DartType? methodNameType) {
    _methodNameType = methodNameType;
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  ExpressionImpl? get realTarget {
    if (isCascaded) {
      return _ancestorCascade.target;
    }
    return _target;
  }

  @override
  ExpressionImpl? get target => _target;

  set target(ExpressionImpl? expression) {
    _target = _becomeParentOf(expression);
  }

  /// Return the cascade that contains this [IndexExpression].
  ///
  /// We expect that [isCascaded] is `true`.
  CascadeExpressionImpl get _ancestorCascade {
    assert(isCascaded);
    for (var ancestor = parent!;; ancestor = ancestor.parent!) {
      if (ancestor is CascadeExpressionImpl) {
        return ancestor;
      }
    }
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('target', target)
    ..addToken('operator', operator)
    ..addNode('methodName', methodName)
    ..addNode('typeArguments', typeArguments)
    ..addNode('argumentList', argumentList);

  @override
  AstNode? get _nullShortingExtensionCandidate => parent;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMethodInvocation(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitMethodInvocation(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _target?.accept(visitor);
    _methodName.accept(visitor);
    _typeArguments?.accept(visitor);
    _argumentList.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression descendant) =>
      identical(descendant, _target);
}

/// An expression that implicitly makes reference to a method.
abstract final class MethodReferenceExpression implements Expression {
  /// Return the element associated with the expression based on the static
  /// types, or `null` if the AST structure has not been resolved, or there is
  /// no meaningful static element to return (e.g. because this is a
  /// non-compound assignment expression, or because the method referred to
  /// could not be resolved).
  MethodElement? get staticElement;
}

/// The declaration of a mixin augmentation.
///
///    mixinAugmentationDeclaration ::=
///        'augment' 'mixin' name [TypeParameterList]?
///        [OnClause]? [ImplementsClause]? '{' [ClassMember]* '}'
@experimental
abstract final class MixinAugmentationDeclaration
    implements MixinOrAugmentationDeclaration {
  /// The token representing the 'augment' keyword.
  Token get augmentKeyword;

  @override
  MixinAugmentationElement? get declaredElement;
}

final class MixinAugmentationDeclarationImpl
    extends MixinOrAugmentationDeclarationImpl
    implements MixinAugmentationDeclaration {
  @override
  MixinAugmentationElementImpl? declaredElement;

  @override
  final Token augmentKeyword;

  MixinAugmentationDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
    required super.baseKeyword,
    required super.mixinKeyword,
    required super.name,
    required super.typeParameters,
    required super.onClause,
    required super.implementsClause,
    required super.leftBracket,
    required super.members,
    required super.rightBracket,
  });

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitMixinAugmentationDeclaration(this);
}

/// The declaration of a mixin.
///
///    mixinDeclaration ::=
///        'base'? 'mixin' name [TypeParameterList]?
///        [OnClause]? [ImplementsClause]? '{' [ClassMember]* '}'
abstract final class MixinDeclaration
    implements MixinOrAugmentationDeclaration {
  @override
  MixinElement? get declaredElement;
}

final class MixinDeclarationImpl extends MixinOrAugmentationDeclarationImpl
    implements MixinDeclaration {
  @override
  MixinElementImpl? declaredElement;

  MixinDeclarationImpl({
    required super.comment,
    required super.metadata,
    required super.baseKeyword,
    required super.mixinKeyword,
    required super.name,
    required super.typeParameters,
    required super.onClause,
    required super.implementsClause,
    required super.leftBracket,
    required super.members,
    required super.rightBracket,
  });

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMixinDeclaration(this);
}

/// Shared interface between [MixinDeclaration] and
/// [MixinAugmentationDeclaration].
@experimental
abstract final class MixinOrAugmentationDeclaration
    implements NamedCompilationUnitMember {
  /// Return the 'base' keyword, or `null` if the keyword was absent.
  Token? get baseKeyword;

  @override
  MixinOrAugmentationElement? get declaredElement;

  /// Returns the `implements` clause for the mixin, or `null` if the mixin
  /// does not implement any interfaces.
  ImplementsClause? get implementsClause;

  /// Returns the left curly bracket.
  Token get leftBracket;

  /// Returns the members defined by the mixin.
  NodeList<ClassMember> get members;

  /// Return the token representing the 'mixin' keyword.
  Token get mixinKeyword;

  /// Return the on clause for the mixin, or `null` if the mixin does not have
  /// any superclass constraints.
  OnClause? get onClause;

  /// Returns the right curly bracket.
  Token get rightBracket;

  /// Returns the type parameters for the mixin, or `null` if the mixin does
  /// not have any type parameters.
  TypeParameterList? get typeParameters;
}

sealed class MixinOrAugmentationDeclarationImpl
    extends NamedCompilationUnitMemberImpl
    implements MixinOrAugmentationDeclaration {
  @override
  final Token? baseKeyword;

  @override
  final Token mixinKeyword;

  @override
  final TypeParameterListImpl? typeParameters;

  @override
  final OnClauseImpl? onClause;

  @override
  final ImplementsClauseImpl? implementsClause;

  @override
  final Token leftBracket;

  @override
  final NodeListImpl<ClassMemberImpl> members = NodeListImpl._();

  @override
  final Token rightBracket;

  MixinOrAugmentationDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.baseKeyword,
    required this.mixinKeyword,
    required super.name,
    required this.typeParameters,
    required this.onClause,
    required this.implementsClause,
    required this.leftBracket,
    required List<ClassMemberImpl> members,
    required this.rightBracket,
  }) {
    _becomeParentOf(typeParameters);
    _becomeParentOf(onClause);
    _becomeParentOf(implementsClause);
    this.members._initialize(this, members);
  }

  Token? get augmentKeyword => null;

  @override
  Token get endToken => rightBracket;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return augmentKeyword ?? baseKeyword ?? mixinKeyword;
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('augmentKeyword', augmentKeyword)
    ..addToken('baseKeyword', baseKeyword)
    ..addToken('mixinKeyword', mixinKeyword)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addNode('onClause', onClause)
    ..addNode('implementsClause', implementsClause)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('members', members)
    ..addToken('rightBracket', rightBracket);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    typeParameters?.accept(visitor);
    onClause?.accept(visitor);
    implementsClause?.accept(visitor);
    members.accept(visitor);
  }
}

/// A node that declares a single name within the scope of a compilation unit.
abstract final class NamedCompilationUnitMember
    implements CompilationUnitMember {
  /// Return the name of the member being declared.
  Token get name;
}

/// A node that declares a single name within the scope of a compilation unit.
sealed class NamedCompilationUnitMemberImpl extends CompilationUnitMemberImpl
    implements NamedCompilationUnitMember {
  /// The name of the member being declared.
  @override
  final Token name;

  /// Initialize a newly created compilation unit member with the given [name].
  /// Either or both of the [comment] and [metadata] can be `null` if the member
  /// does not have the corresponding attribute.
  NamedCompilationUnitMemberImpl({
    required super.comment,
    required super.metadata,
    required this.name,
  });
}

/// An expression that has a name associated with it. They are used in method
/// invocations when there are named parameters.
///
///    namedExpression ::=
///        [Label] [Expression]
abstract final class NamedExpression implements Expression {
  /// Return the element representing the parameter being named by this
  /// expression, or `null` if the AST structure has not been resolved or if
  /// there is no parameter with the same name as this expression.
  ParameterElement? get element;

  /// Return the expression with which the name is associated.
  Expression get expression;

  /// Return the name associated with the expression.
  Label get name;
}

/// An expression that has a name associated with it. They are used in method
/// invocations when there are named parameters.
///
///    namedExpression ::=
///        [Label] [Expression]
final class NamedExpressionImpl extends ExpressionImpl
    implements NamedExpression {
  /// The name associated with the expression.
  LabelImpl _name;

  /// The expression with which the name is associated.
  ExpressionImpl _expression;

  /// Initialize a newly created named expression..
  NamedExpressionImpl({
    required LabelImpl name,
    required ExpressionImpl expression,
  })  : _name = name,
        _expression = expression {
    _becomeParentOf(_name);
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => _name.beginToken;

  @override
  ParameterElement? get element {
    var element = _name.label.staticElement;
    if (element is ParameterElement) {
      return element;
    }
    return null;
  }

  @override
  Token get endToken => _expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  LabelImpl get name => _name;

  set name(LabelImpl identifier) {
    _name = _becomeParentOf(identifier);
  }

  @override
  Precedence get precedence => Precedence.none;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('name', name)
    ..addNode('expression', expression);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNamedExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitNamedExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _name.accept(visitor);
    _expression.accept(visitor);
  }
}

/// A named type, which can optionally include type arguments.
///
///    namedType ::=
///        [ImportPrefixReference]? name typeArguments?
abstract final class NamedType implements TypeAnnotation {
  /// The element of [name2] considering [importPrefix] for example a
  /// [ClassElement], or [TypeAliasElement]. Can be `null` if [name2] cannot
  /// be resolved, or there is no element for the type name, e.g. for `void`.
  Element? get element;

  /// The optional import prefix before [name2].
  ImportPrefixReference? get importPrefix;

  /// Return `true` if this type is a deferred type.
  ///
  /// 15.1 Static Types: A type <i>T</i> is deferred iff it is of the form
  /// </i>p.T</i> where <i>p</i> is a deferred prefix.
  bool get isDeferred;

  /// Return the name of the type.
  Token get name2;

  /// Return the type arguments associated with the type, or `null` if there are
  /// no type arguments.
  TypeArgumentList? get typeArguments;
}

/// The name of a type, which can optionally include type arguments.
///
///    typeName ::=
///        [Identifier] typeArguments? '?'?
final class NamedTypeImpl extends TypeAnnotationImpl implements NamedType {
  @override
  final ImportPrefixReferenceImpl? importPrefix;

  @override
  final Token name2;

  @override
  Element? element;

  @override
  TypeArgumentListImpl? typeArguments;

  @override
  final Token? question;

  /// The type being named, or `null` if the AST structure has not been
  /// resolved, or if this is part of a [ConstructorReference].
  @override
  DartType? type;

  /// Initialize a newly created type name. The [typeArguments] can be `null` if
  /// there are no type arguments.
  NamedTypeImpl({
    required this.importPrefix,
    required this.name2,
    required this.typeArguments,
    required this.question,
  }) {
    _becomeParentOf(importPrefix);
    _becomeParentOf(typeArguments);
  }

  @override
  Token get beginToken => importPrefix?.beginToken ?? name2;

  @override
  Token get endToken => question ?? typeArguments?.endToken ?? name2;

  @override
  bool get isDeferred {
    final importPrefixElement = importPrefix?.element;
    if (importPrefixElement is PrefixElement) {
      final imports = importPrefixElement.imports;
      if (imports.length != 1) {
        return false;
      }
      return imports[0].prefix is DeferredImportElementPrefix;
    }
    return false;
  }

  @override
  bool get isSynthetic => name2.isSynthetic && typeArguments == null;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('importPrefix', importPrefix)
    ..addToken('name', name2)
    ..addNode('typeArguments', typeArguments)
    ..addToken('question', question);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNamedType(this);

  @override
  void visitChildren(AstVisitor visitor) {
    importPrefix?.accept(visitor);
    typeArguments?.accept(visitor);
  }
}

/// A node that represents a directive that impacts the namespace of a library.
///
///    directive ::=
///        [ExportDirective]
///      | [ImportDirective]
sealed class NamespaceDirective implements UriBasedDirective {
  /// Return the combinators used to control how names are imported or exported.
  NodeList<Combinator> get combinators;

  /// Return the configurations used to control which library will actually be
  /// loaded at run-time.
  NodeList<Configuration> get configurations;

  /// Return the semicolon terminating the directive.
  Token get semicolon;
}

/// A node that represents a directive that impacts the namespace of a library.
///
///    directive ::=
///        [ExportDirective]
///      | [ImportDirective]
sealed class NamespaceDirectiveImpl extends UriBasedDirectiveImpl
    implements NamespaceDirective {
  /// The configurations used to control which library will actually be loaded
  /// at run-time.
  final NodeListImpl<ConfigurationImpl> _configurations = NodeListImpl._();

  /// The combinators used to control which names are imported or exported.
  final NodeListImpl<CombinatorImpl> _combinators = NodeListImpl._();

  /// The semicolon terminating the directive.
  @override
  final Token semicolon;

  /// Initialize a newly created namespace directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute. The list of [combinators] can be `null` if there
  /// are no combinators.
  NamespaceDirectiveImpl({
    required super.comment,
    required super.metadata,
    required super.uri,
    required List<ConfigurationImpl>? configurations,
    required List<CombinatorImpl>? combinators,
    required this.semicolon,
  }) {
    _configurations._initialize(this, configurations);
    _combinators._initialize(this, combinators);
  }

  @override
  NodeListImpl<CombinatorImpl> get combinators => _combinators;

  @override
  NodeListImpl<ConfigurationImpl> get configurations => _configurations;

  @override
  Token get endToken => semicolon;
}

/// The "native" clause in an class declaration.
///
///    nativeClause ::=
///        'native' [StringLiteral]
abstract final class NativeClause implements AstNode {
  /// Return the name of the native object that implements the class.
  StringLiteral? get name;

  /// Return the token representing the 'native' keyword.
  Token get nativeKeyword;
}

/// The "native" clause in an class declaration.
///
///    nativeClause ::=
///        'native' [StringLiteral]
final class NativeClauseImpl extends AstNodeImpl implements NativeClause {
  @override
  final Token nativeKeyword;

  @override
  final StringLiteralImpl? name;

  /// Initialize a newly created native clause.
  NativeClauseImpl({
    required this.nativeKeyword,
    required this.name,
  }) {
    _becomeParentOf(name);
  }

  @override
  Token get beginToken => nativeKeyword;

  @override
  Token get endToken {
    return name?.endToken ?? nativeKeyword;
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('nativeKeyword', nativeKeyword)
    ..addNode('name', name);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNativeClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    name?.accept(visitor);
  }
}

/// A function body that consists of a native keyword followed by a string
/// literal.
///
///    nativeFunctionBody ::=
///        'native' [SimpleStringLiteral] ';'
abstract final class NativeFunctionBody implements FunctionBody {
  /// Return the token representing 'native' that marks the start of the
  /// function body.
  Token get nativeKeyword;

  /// Return the token representing the semicolon that marks the end of the
  /// function body.
  Token get semicolon;

  /// Return the string literal representing the string after the 'native'
  /// token.
  StringLiteral? get stringLiteral;
}

/// A function body that consists of a native keyword followed by a string
/// literal.
///
///    nativeFunctionBody ::=
///        'native' [SimpleStringLiteral] ';'
final class NativeFunctionBodyImpl extends FunctionBodyImpl
    implements NativeFunctionBody {
  /// The token representing 'native' that marks the start of the function body.
  @override
  final Token nativeKeyword;

  /// The string literal, after the 'native' token.
  StringLiteralImpl? _stringLiteral;

  /// The token representing the semicolon that marks the end of the function
  /// body.
  @override
  final Token semicolon;

  /// Initialize a newly created function body consisting of the 'native' token,
  /// a string literal, and a semicolon.
  NativeFunctionBodyImpl({
    required this.nativeKeyword,
    required StringLiteralImpl? stringLiteral,
    required this.semicolon,
  }) : _stringLiteral = stringLiteral {
    _becomeParentOf(_stringLiteral);
  }

  @override
  Token get beginToken => nativeKeyword;

  @override
  Token get endToken => semicolon;

  @override
  StringLiteralImpl? get stringLiteral => _stringLiteral;

  set stringLiteral(StringLiteralImpl? stringLiteral) {
    _stringLiteral = _becomeParentOf(stringLiteral);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('nativeKeyword', nativeKeyword)
    ..addNode('stringLiteral', stringLiteral)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNativeFunctionBody(this);

  @override
  DartType resolve(ResolverVisitor resolver, DartType? imposedType) =>
      resolver.visitNativeFunctionBody(this, imposedType: imposedType);

  @override
  void visitChildren(AstVisitor visitor) {
    _stringLiteral?.accept(visitor);
  }
}

/// A list of AST nodes that have a common parent.
abstract final class NodeList<E extends AstNode> implements List<E> {
  /// Return the first token included in this node list's source range, or
  /// `null` if the list is empty.
  Token? get beginToken;

  /// Return the last token included in this node list's source range, or `null`
  /// if the list is empty.
  Token? get endToken;

  @Deprecated('NodeList cannot be resized')
  @override
  set length(int newLength);

  /// Return the node that is the parent of each of the elements in the list.
  AstNode get owner;

  /// Return the node at the given [index] in the list or throw a [RangeError]
  /// if [index] is out of bounds.
  @override
  E operator [](int index);

  /// Use the given [visitor] to visit each of the nodes in this list.
  void accept(AstVisitor visitor);

  @Deprecated('NodeList cannot be resized')
  @override
  void add(E element);

  @Deprecated('NodeList cannot be resized')
  @override
  void addAll(Iterable<E> iterable);

  @Deprecated('NodeList cannot be resized')
  @override
  void clear();

  @Deprecated('NodeList cannot be resized')
  @override
  void insert(int index, E element);

  @Deprecated('NodeList cannot be resized')
  @override
  E removeAt(int index);
}

/// A list of AST nodes that have a common parent.
final class NodeListImpl<E extends AstNode>
    with ListMixin<E>
    implements NodeList<E> {
  /// The node that is the parent of each of the elements in the list.
  late final AstNodeImpl _owner;

  /// The elements contained in the list.
  late final List<E> _elements;

  /// Initialize a newly created list of nodes such that all of the nodes that
  /// are added to the list will have their parent set to the given [owner].
  NodeListImpl(AstNodeImpl owner) : _owner = owner;

  /// Create a partially initialized instance, [_initialize] must be called.
  NodeListImpl._();

  @override
  Token? get beginToken {
    if (_elements.isEmpty) {
      return null;
    }
    return _elements[0].beginToken;
  }

  @override
  Token? get endToken {
    int length = _elements.length;
    if (length == 0) {
      return null;
    }
    return _elements[length - 1].endToken;
  }

  @override
  int get length => _elements.length;

  @Deprecated('NodeList cannot be resized')
  @override
  set length(int newLength) {
    throw UnsupportedError("Cannot resize NodeList.");
  }

  @override
  AstNodeImpl get owner => _owner;

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
    _elements[index] = node;
    _owner._becomeParentOf(node as AstNodeImpl);
  }

  @override
  void accept(AstVisitor visitor) {
    int length = _elements.length;
    for (var i = 0; i < length; i++) {
      _elements[i].accept(visitor);
    }
  }

  @Deprecated('NodeList cannot be resized')
  @override
  void add(E element) {
    throw UnsupportedError("Cannot resize NodeList.");
  }

  @Deprecated('NodeList cannot be resized')
  @override
  void addAll(Iterable<E> iterable) {
    throw UnsupportedError("Cannot resize NodeList.");
  }

  @Deprecated('NodeList cannot be resized')
  @override
  void clear() {
    throw UnsupportedError("Cannot resize NodeList.");
  }

  @Deprecated('NodeList cannot be resized')
  @override
  void insert(int index, E element) {
    throw UnsupportedError("Cannot resize NodeList.");
  }

  @Deprecated('NodeList cannot be resized')
  @override
  E removeAt(int index) {
    throw UnsupportedError("Cannot resize NodeList.");
  }

  /// Set the [owner] of this container, and populate it with [elements].
  void _initialize(AstNodeImpl owner, List<E>? elements) {
    _owner = owner;
    if (elements == null || elements.isEmpty) {
      _elements = const <Never>[];
    } else {
      _elements = elements.toList(growable: false);
      var length = elements.length;
      for (var i = 0; i < length; i++) {
        var node = elements[i];
        owner._becomeParentOf(node as AstNodeImpl);
      }
    }
  }
}

/// A formal parameter that is required (is not optional).
///
///    normalFormalParameter ::=
///        [FunctionTypedFormalParameter]
///      | [FieldFormalParameter]
///      | [SimpleFormalParameter]
sealed class NormalFormalParameter implements FormalParameter {
  /// Return the documentation comment associated with this parameter, or `null`
  /// if this parameter does not have a documentation comment associated with
  /// it.
  Comment? get documentationComment;

  /// Return a list containing the comment and annotations associated with this
  /// parameter, sorted in lexical order.
  List<AstNode> get sortedCommentAndAnnotations;
}

/// A formal parameter that is required (is not optional).
///
///    normalFormalParameter ::=
///        [FunctionTypedFormalParameter]
///      | [FieldFormalParameter]
///      | [SimpleFormalParameter]
sealed class NormalFormalParameterImpl extends FormalParameterImpl
    implements NormalFormalParameter {
  /// The documentation comment associated with this parameter, or `null` if
  /// this parameter does not have a documentation comment associated with it.
  CommentImpl? _comment;

  /// The annotations associated with this parameter.
  final NodeListImpl<AnnotationImpl> _metadata = NodeListImpl._();

  /// The 'covariant' keyword, or `null` if the keyword was not used.
  @override
  final Token? covariantKeyword;

  /// The 'required' keyword, or `null` if the keyword was not used.
  @override
  final Token? requiredKeyword;

  @override
  final Token? name;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute.
  NormalFormalParameterImpl({
    required CommentImpl? comment,
    required List<AnnotationImpl>? metadata,
    required this.covariantKeyword,
    required this.requiredKeyword,
    required this.name,
  }) : _comment = comment {
    _becomeParentOf(_comment);
    _metadata._initialize(this, metadata);
  }

  @override
  CommentImpl? get documentationComment => _comment;

  set documentationComment(CommentImpl? comment) {
    _comment = _becomeParentOf(comment);
  }

  @override
  ParameterKind get kind {
    final parent = this.parent;
    if (parent is DefaultFormalParameterImpl) {
      return parent.kind;
    }
    return ParameterKind.REQUIRED;
  }

  @override
  NodeListImpl<AnnotationImpl> get metadata => _metadata;

  @override
  List<AstNode> get sortedCommentAndAnnotations {
    var comment = _comment;
    return <AstNode>[
      if (comment != null) comment,
      ..._metadata,
    ]..sort(AstNode.LEXICAL_ORDER);
  }

  @override
  ChildEntities get _childEntities {
    return ChildEntities()
      ..addNode('documentationComment', documentationComment)
      ..addNodeList('metadata', metadata)
      ..addToken('requiredKeyword', requiredKeyword)
      ..addToken('covariantKeyword', covariantKeyword);
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
    return _comment!.offset < firstAnnotation.offset;
  }
}

/// A null-assert pattern.
///
///    nullAssertPattern ::=
///        [DartPattern] '!'
abstract final class NullAssertPattern implements DartPattern {
  /// The `!` token.
  Token get operator;

  /// The sub-pattern.
  DartPattern get pattern;
}

/// A null-assert pattern.
///
///    nullAssertPattern ::=
///        [DartPattern] '!'
final class NullAssertPatternImpl extends DartPatternImpl
    implements NullAssertPattern {
  @override
  final DartPatternImpl pattern;

  @override
  final Token operator;

  NullAssertPatternImpl({
    required this.pattern,
    required this.operator,
  }) {
    _becomeParentOf(pattern);
  }

  @override
  Token get beginToken => pattern.beginToken;

  @override
  Token get endToken => operator;

  @override
  PatternPrecedence get precedence => PatternPrecedence.postfix;

  @override
  VariablePatternImpl? get variablePattern => pattern.variablePattern;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('pattern', pattern)
    ..addToken('operator', operator);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNullAssertPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor.analyzeNullCheckOrAssertPatternSchema(
      pattern,
      isAssert: true,
    );
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.analyzeNullCheckOrAssertPattern(context, this, pattern,
        isAssert: true);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    pattern.accept(visitor);
  }
}

/// A null-check pattern.
///
///    nullCheckPattern ::=
///        [DartPattern] '?'
abstract final class NullCheckPattern implements DartPattern {
  /// The `?` token.
  Token get operator;

  /// The sub-pattern.
  DartPattern get pattern;
}

/// A null-check pattern.
///
///    nullCheckPattern ::=
///        [DartPattern] '?'
final class NullCheckPatternImpl extends DartPatternImpl
    implements NullCheckPattern {
  @override
  final DartPatternImpl pattern;

  @override
  final Token operator;

  NullCheckPatternImpl({
    required this.pattern,
    required this.operator,
  }) {
    _becomeParentOf(pattern);
  }

  @override
  Token get beginToken => pattern.beginToken;

  @override
  Token get endToken => operator;

  @override
  PatternPrecedence get precedence => PatternPrecedence.postfix;

  @override
  VariablePatternImpl? get variablePattern => pattern.variablePattern;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('pattern', pattern)
    ..addToken('operator', operator);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNullCheckPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor.analyzeNullCheckOrAssertPatternSchema(
      pattern,
      isAssert: false,
    );
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.analyzeNullCheckOrAssertPattern(context, this, pattern,
        isAssert: false);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    pattern.accept(visitor);
  }
}

/// A null literal expression.
///
///    nullLiteral ::=
///        'null'
abstract final class NullLiteral implements Literal {
  /// Return the token representing the literal.
  Token get literal;
}

/// A null literal expression.
///
///    nullLiteral ::=
///        'null'
final class NullLiteralImpl extends LiteralImpl implements NullLiteral {
  /// The token representing the literal.
  @override
  final Token literal;

  /// Initialize a newly created null literal.
  NullLiteralImpl({
    required this.literal,
  });

  @override
  Token get beginToken => literal;

  @override
  Token get endToken => literal;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('literal', literal);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNullLiteral(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitNullLiteral(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// Abstract interface for expressions that may participate in null-shorting.
abstract final class NullShortableExpression implements Expression {
  /// Returns the expression that terminates any null shorting that might occur
  /// in this expression.  This may be called regardless of whether this
  /// expression is itself null-aware.
  ///
  /// For example, the statement `a?.b[c] = d;` contains the following
  /// null-shortable subexpressions:
  /// - `a?.b`
  /// - `a?.b[c]`
  /// - `a?.b[c] = d`
  ///
  /// Calling [nullShortingTermination] on any of these subexpressions yields
  /// the expression `a?.b[c] = d`, indicating that the null-shorting induced by
  /// the `?.` causes the rest of the subexpression `a?.b[c] = d` to be skipped.
  Expression get nullShortingTermination;
}

/// Mixin that can be used to implement [NullShortableExpression].
base mixin NullShortableExpressionImpl implements NullShortableExpression {
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
  AstNode? get _nullShortingExtensionCandidate;

  /// Indicates whether the effect of any null-shorting within [descendant]
  /// (which should be a descendant of `this`) should extend to include `this`.
  bool _extendsNullShorting(Expression descendant);
}

/// An object pattern.
///
///    objectPattern ::=
///        [Identifier] [TypeArgumentList]? '(' [PatternField] ')'
abstract final class ObjectPattern implements DartPattern {
  /// Return the patterns matching the properties of the object.
  NodeList<PatternField> get fields;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the right parenthesis.
  Token get rightParenthesis;

  /// The name of the type of object from which values will be extracted.
  NamedType get type;
}

/// An object pattern.
///
///    objectPattern ::=
///        [Identifier] [TypeArgumentList]? '(' [PatternField] ')'
final class ObjectPatternImpl extends DartPatternImpl implements ObjectPattern {
  final NodeListImpl<PatternFieldImpl> _fields = NodeListImpl._();

  @override
  final Token leftParenthesis;

  @override
  final Token rightParenthesis;

  @override
  final NamedTypeImpl type;

  ObjectPatternImpl({
    required this.type,
    required this.leftParenthesis,
    required List<PatternFieldImpl> fields,
    required this.rightParenthesis,
  }) {
    _becomeParentOf(type);
    _fields._initialize(this, fields);
  }

  @override
  Token get beginToken => type.beginToken;

  @override
  Token get endToken => rightParenthesis;

  @override
  NodeList<PatternFieldImpl> get fields => _fields;

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('type', type)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNodeList('fields', fields)
    ..addToken('rightParenthesis', rightParenthesis);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitObjectPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor.analyzeObjectPatternSchema(type.typeOrThrow);
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    final result = resolverVisitor.analyzeObjectPattern(
      context,
      this,
      fields: resolverVisitor.buildSharedPatternFields(
        fields,
        mustBeNamed: true,
      ),
    );

    resolverVisitor.checkPatternNeverMatchesValueType(
      context: context,
      pattern: this,
      requiredType: result.requiredType,
    );
  }

  @override
  void visitChildren(AstVisitor visitor) {
    type.accept(visitor);
    fields.accept(visitor);
  }
}

/// The "on" clause in a mixin declaration.
///
///    onClause ::=
///        'on' [NamedType] (',' [NamedType])*
abstract final class OnClause implements AstNode {
  /// Return the token representing the 'on' keyword.
  Token get onKeyword;

  /// Return the list of the classes are superclass constraints for the mixin.
  NodeList<NamedType> get superclassConstraints;
}

/// The "on" clause in a mixin declaration.
///
///    onClause ::=
///        'on' [NamedType] (',' [NamedType])*
final class OnClauseImpl extends AstNodeImpl implements OnClause {
  @override
  final Token onKeyword;

  /// The classes are super-class constraints for the mixin.
  final NodeListImpl<NamedTypeImpl> _superclassConstraints = NodeListImpl._();

  /// Initialize a newly created on clause.
  OnClauseImpl({
    required this.onKeyword,
    required List<NamedTypeImpl> superclassConstraints,
  }) {
    _superclassConstraints._initialize(this, superclassConstraints);
  }

  @override
  Token get beginToken => onKeyword;

  @override
  Token get endToken => _superclassConstraints.endToken ?? onKeyword;

  @override
  NodeListImpl<NamedTypeImpl> get superclassConstraints =>
      _superclassConstraints;

  @override
  // TODO(paulberry): add commas.
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('onKeyword', onKeyword)
    ..addNodeList('superclassConstraints', superclassConstraints);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitOnClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _superclassConstraints.accept(visitor);
  }
}

/// A parenthesized expression.
///
///    parenthesizedExpression ::=
///        '(' [Expression] ')'
abstract final class ParenthesizedExpression implements Expression {
  /// Return the expression within the parentheses.
  Expression get expression;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the right parenthesis.
  Token get rightParenthesis;
}

/// A parenthesized expression.
///
///    parenthesizedExpression ::=
///        '(' [Expression] ')'
final class ParenthesizedExpressionImpl extends ExpressionImpl
    implements ParenthesizedExpression {
  /// The left parenthesis.
  @override
  final Token leftParenthesis;

  /// The expression within the parentheses.
  ExpressionImpl _expression;

  /// The right parenthesis.
  @override
  final Token rightParenthesis;

  /// Initialize a newly created parenthesized expression.
  ParenthesizedExpressionImpl({
    required this.leftParenthesis,
    required ExpressionImpl expression,
    required this.rightParenthesis,
  }) : _expression = expression {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => leftParenthesis;

  @override
  Token get endToken => rightParenthesis;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.primary;

  @override
  ExpressionImpl get unParenthesized {
    // This is somewhat inefficient, but it avoids a stack overflow in the
    // degenerate case.
    var expression = _expression;
    while (expression is ParenthesizedExpressionImpl) {
      expression = expression._expression;
    }
    return expression;
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('expression', expression)
    ..addToken('rightParenthesis', rightParenthesis);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitParenthesizedExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitParenthesizedExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
  }
}

/// A parenthesized pattern.
///
///    parenthesizedPattern ::=
///        '(' [DartPattern] ')'
abstract final class ParenthesizedPattern implements DartPattern {
  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// The pattern within the parentheses.
  DartPattern get pattern;

  /// Return the right parenthesis.
  Token get rightParenthesis;
}

/// A parenthesized pattern.
///
///    parenthesizedPattern ::=
///        '(' [DartPattern] ')'
final class ParenthesizedPatternImpl extends DartPatternImpl
    implements ParenthesizedPattern {
  @override
  final Token leftParenthesis;

  @override
  final DartPatternImpl pattern;

  @override
  final Token rightParenthesis;

  ParenthesizedPatternImpl({
    required this.leftParenthesis,
    required this.pattern,
    required this.rightParenthesis,
  }) {
    _becomeParentOf(pattern);
  }

  @override
  Token get beginToken => leftParenthesis;

  @override
  Token get endToken => rightParenthesis;

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @override
  DartPattern get unParenthesized {
    var result = pattern;
    while (result is ParenthesizedPatternImpl) {
      result = result.pattern;
    }
    return result;
  }

  @override
  VariablePatternImpl? get variablePattern => pattern.variablePattern;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('pattern', pattern)
    ..addToken('rightParenthesis', rightParenthesis);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitParenthesizedPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor.dispatchPatternSchema(pattern);
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.dispatchPattern(context, pattern);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    pattern.accept(visitor);
  }
}

/// A part directive.
///
///    partDirective ::=
///        [Annotation] 'part' [StringLiteral] ';'
abstract final class PartDirective implements UriBasedDirective {
  @override
  PartElement? get element;

  /// Return the token representing the 'part' keyword.
  Token get partKeyword;

  /// Return the semicolon terminating the directive.
  Token get semicolon;
}

/// A part directive.
///
///    partDirective ::=
///        [Annotation] 'part' [StringLiteral] ';'
final class PartDirectiveImpl extends UriBasedDirectiveImpl
    implements PartDirective {
  /// The token representing the 'part' keyword.
  @override
  final Token partKeyword;

  /// The semicolon terminating the directive.
  @override
  final Token semicolon;

  /// Initialize a newly created part directive. Either or both of the [comment]
  /// and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute.
  PartDirectiveImpl({
    required super.comment,
    required super.metadata,
    required this.partKeyword,
    required super.uri,
    required this.semicolon,
  });

  @override
  PartElement? get element {
    return super.element as PartElement?;
  }

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => partKeyword;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('partKeyword', partKeyword)
    ..addNode('uri', uri)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPartDirective(this);
}

/// A part-of directive.
///
///    partOfDirective ::=
///        [Annotation] 'part' 'of' [Identifier] ';'
abstract final class PartOfDirective implements Directive {
  /// Return the name of the library that the containing compilation unit is
  /// part of.
  LibraryIdentifier? get libraryName;

  /// Return the token representing the 'of' keyword.
  Token get ofKeyword;

  /// Return the token representing the 'part' keyword.
  Token get partKeyword;

  /// Return the semicolon terminating the directive.
  Token get semicolon;

  /// Return the URI of the library that the containing compilation unit is part
  /// of, or `null` if no URI was given (typically because a library name was
  /// provided).
  StringLiteral? get uri;
}

/// A part-of directive.
///
///    partOfDirective ::=
///        [Annotation] 'part' 'of' [Identifier] ';'
final class PartOfDirectiveImpl extends DirectiveImpl
    implements PartOfDirective {
  /// The token representing the 'part' keyword.
  @override
  final Token partKeyword;

  /// The token representing the 'of' keyword.
  @override
  final Token ofKeyword;

  /// The URI of the library that the containing compilation unit is part of.
  StringLiteralImpl? _uri;

  /// The name of the library that the containing compilation unit is part of,
  /// or `null` if no name was given (typically because a library URI was
  /// provided).
  LibraryIdentifierImpl? _libraryName;

  /// The semicolon terminating the directive.
  @override
  final Token semicolon;

  /// Initialize a newly created part-of directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute.
  PartOfDirectiveImpl({
    required super.comment,
    required super.metadata,
    required this.partKeyword,
    required this.ofKeyword,
    required StringLiteralImpl? uri,
    required LibraryIdentifierImpl? libraryName,
    required this.semicolon,
  })  : _uri = uri,
        _libraryName = libraryName {
    _becomeParentOf(_uri);
    _becomeParentOf(_libraryName);
  }

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => partKeyword;

  @override
  LibraryIdentifierImpl? get libraryName => _libraryName;

  set libraryName(LibraryIdentifierImpl? libraryName) {
    _libraryName = _becomeParentOf(libraryName);
  }

  @override
  StringLiteralImpl? get uri => _uri;

  set uri(StringLiteralImpl? uri) {
    _uri = _becomeParentOf(uri);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('partKeyword', partKeyword)
    ..addToken('ofKeyword', ofKeyword)
    ..addNode('uri', uri)
    ..addNode('libraryName', libraryName)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPartOfDirective(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _libraryName?.accept(visitor);
    _uri?.accept(visitor);
  }
}

/// A pattern assignment.
///
///    patternAssignment ::=
///        [DartPattern] '=' [Expression]
abstract final class PatternAssignment implements Expression {
  /// Return the equal sign separating the pattern from the expression.
  Token get equals;

  /// The expression that will be matched by the pattern.
  Expression get expression;

  /// The pattern that will match the expression.
  DartPattern get pattern;
}

/// A pattern assignment.
///
///    patternAssignment ::=
///        [DartPattern] '=' [Expression]
///
/// When used as the condition in an `if`, the pattern is always a
/// [PatternVariable] whose type is not `null`.
final class PatternAssignmentImpl extends ExpressionImpl
    implements PatternAssignment {
  @override
  final Token equals;

  ExpressionImpl _expression;

  @override
  final DartPatternImpl pattern;

  /// The pattern type schema, used for downward inference of [expression];
  /// or `null` if the node is not resolved yet.
  DartType? patternTypeSchema;

  PatternAssignmentImpl({
    required this.pattern,
    required this.equals,
    required ExpressionImpl expression,
  }) : _expression = expression {
    _becomeParentOf(pattern);
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => pattern.beginToken;

  @override
  Token get endToken => expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  // TODO(brianwilkerson) Create a new precedence constant for pattern
  //  assignments. The proposal doesn't make the actual value clear.
  Precedence get precedence => Precedence.assignment;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('pattern', pattern)
    ..addToken('equals', equals)
    ..addNode('expression', expression);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPatternAssignment(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType? contextType) {
    resolver.visitPatternAssignment(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    pattern.accept(visitor);
    expression.accept(visitor);
  }
}

/// A field in an object or record pattern.
///
///    patternField ::=
///        [PatternFieldName]? [DartPattern]
abstract final class PatternField implements AstNode {
  /// The name specified explicitly by [name], or implied by the variable
  /// pattern inside [pattern]. Always `null` if [name] is `null`. Can be `null`
  /// if [name] does not have the explicit name and [pattern] is not a variable
  /// pattern.
  String? get effectiveName;

  /// The element referenced by [effectiveName]. Is `null` if not resolved yet,
  /// not `null` inside valid [ObjectPattern]s, always `null` inside
  /// [RecordPattern]s.
  Element? get element;

  /// The name of the field, or `null` if the field is a positional field.
  PatternFieldName? get name;

  /// The pattern used to match the corresponding record field.
  DartPattern get pattern;
}

/// A field in a record pattern.
///
///    patternField ::=
///        [PatternFieldName]? [DartPattern]
final class PatternFieldImpl extends AstNodeImpl implements PatternField {
  @override
  Element? element;

  @override
  final PatternFieldNameImpl? name;

  @override
  final DartPatternImpl pattern;

  PatternFieldImpl({required this.name, required this.pattern}) {
    _becomeParentOf(name);
    _becomeParentOf(pattern);
  }

  @override
  Token get beginToken => name?.beginToken ?? pattern.beginToken;

  @override
  String? get effectiveName {
    final nameNode = name;
    if (nameNode != null) {
      final nameToken = nameNode.name ?? pattern.variablePattern?.name;
      return nameToken?.lexeme;
    }
    return null;
  }

  @override
  Token get endToken => pattern.endToken;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('name', name)
    ..addNode('pattern', pattern);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPatternField(this);

  @override
  void visitChildren(AstVisitor visitor) {
    name?.accept(visitor);
    pattern.accept(visitor);
  }
}

/// A field name in an object or record pattern field.
///
///    patternFieldName ::=
///        [Token]? ':'
abstract final class PatternFieldName implements AstNode {
  /// The colon following the name.
  Token get colon;

  /// The name of the field.
  Token? get name;
}

/// A field name in a record pattern field.
///
///    patternFieldName ::=
///        [Token]? ':'
final class PatternFieldNameImpl extends AstNodeImpl
    implements PatternFieldName {
  @override
  final Token colon;

  @override
  final Token? name;

  PatternFieldNameImpl({required this.name, required this.colon});

  @override
  Token get beginToken => name ?? colon;

  @override
  Token get endToken => colon;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('name', name)
    ..addToken('colon', colon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPatternFieldName(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// A pattern variable declaration.
///
///    patternDeclaration ::=
///        ( 'final' | 'var' ) [DartPattern] '=' [Expression]
abstract final class PatternVariableDeclaration implements AnnotatedNode {
  /// Return the equal sign separating the pattern from the expression.
  Token get equals;

  /// The expression that will be matched by the pattern.
  Expression get expression;

  /// Return the `var` or `final` keyword introducing the declaration.
  Token get keyword;

  /// The pattern that will match the expression.
  DartPattern get pattern;
}

/// A pattern variable declaration.
///
///    patternDeclaration ::=
///        ( 'final' | 'var' ) [DartPattern] '=' [Expression]
final class PatternVariableDeclarationImpl extends AnnotatedNodeImpl
    implements PatternVariableDeclaration {
  @override
  final Token equals;

  ExpressionImpl _expression;

  @override
  final Token keyword;

  @override
  final DartPatternImpl pattern;

  /// The pattern type schema, used for downward inference of [expression];
  /// or `null` if the node is not resolved yet.
  DartType? patternTypeSchema;

  /// Variables declared in [pattern].
  late final List<BindPatternVariableElementImpl> elements;

  PatternVariableDeclarationImpl({
    required this.keyword,
    required this.pattern,
    required this.equals,
    required ExpressionImpl expression,
    required super.comment,
    required super.metadata,
  }) : _expression = expression {
    _becomeParentOf(pattern);
    _becomeParentOf(_expression);
  }

  @override
  Token get endToken => expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  /// If [keyword] is `final`, returns it.
  Token? get finalKeyword {
    if (keyword.keyword == Keyword.FINAL) {
      return keyword;
    }
    return null;
  }

  @override
  Token get firstTokenAfterCommentAndMetadata => keyword;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('keyword', keyword)
    ..addNode('pattern', pattern)
    ..addToken('equals', equals)
    ..addNode('expression', expression);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitPatternVariableDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    pattern.accept(visitor);
    expression.accept(visitor);
  }
}

/// A pattern variable declaration statement.
///
///    patternDeclaration ::=
///        [PatternVariableDeclaration] ';'
abstract final class PatternVariableDeclarationStatement implements Statement {
  /// The pattern declaration.
  PatternVariableDeclaration get declaration;

  /// Return the semicolon terminating the statement.
  Token get semicolon;
}

/// A pattern variable declaration statement.
///
///    patternDeclarationStatement ::=
///        [PatternVariableDeclaration] ';'
final class PatternVariableDeclarationStatementImpl extends StatementImpl
    implements PatternVariableDeclarationStatement {
  @override
  final PatternVariableDeclarationImpl declaration;

  @override
  final Token semicolon;

  PatternVariableDeclarationStatementImpl({
    required this.declaration,
    required this.semicolon,
  }) {
    _becomeParentOf(declaration);
  }

  @override
  Token get beginToken => declaration.beginToken;

  @override
  Token get endToken => semicolon;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('declaration', declaration)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitPatternVariableDeclarationStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    declaration.accept(visitor);
  }
}

/// A postfix unary expression.
///
///    postfixExpression ::=
///        [Expression] [Token]
abstract final class PostfixExpression
    implements
        Expression,
        NullShortableExpression,
        MethodReferenceExpression,
        CompoundAssignmentExpression {
  /// Return the expression computing the operand for the operator.
  Expression get operand;

  /// Return the postfix operator being applied to the operand.
  Token get operator;
}

/// A postfix unary expression.
///
///    postfixExpression ::=
///        [Expression] [Token]
final class PostfixExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl, CompoundAssignmentExpressionImpl
    implements PostfixExpression {
  /// The expression computing the operand for the operator.
  ExpressionImpl _operand;

  /// The postfix operator being applied to the operand.
  @override
  final Token operator;

  /// The element associated with the operator based on the static type of the
  /// operand, or `null` if the AST structure has not been resolved, if the
  /// operator is not user definable, or if the operator could not be resolved.
  @override
  MethodElement? staticElement;

  /// Initialize a newly created postfix expression.
  PostfixExpressionImpl({
    required ExpressionImpl operand,
    required this.operator,
  }) : _operand = operand {
    _becomeParentOf(_operand);
  }

  @override
  Token get beginToken => _operand.beginToken;

  @override
  Token get endToken => operator;

  @override
  ExpressionImpl get operand => _operand;

  set operand(ExpressionImpl expression) {
    _operand = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('operand', operand)
    ..addToken('operator', operator);

  @override
  AstNode? get _nullShortingExtensionCandidate => parent;

  /// If the AST structure has been resolved, and the function being invoked is
  /// known based on static type information, then return the parameter element
  /// representing the parameter to which the value of the operand will be
  /// bound.  Otherwise, return `null`.
  ParameterElement? get _staticParameterElementForOperand {
    if (staticElement == null) {
      return null;
    }
    List<ParameterElement> parameters = staticElement!.parameters;
    if (parameters.isEmpty) {
      return null;
    }
    return parameters[0];
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPostfixExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitPostfixExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _operand.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression descendant) =>
      identical(descendant, operand);
}

/// An identifier that is prefixed or an access to an object property where the
/// target of the property access is a simple identifier.
///
///    prefixedIdentifier ::=
///        [SimpleIdentifier] '.' [SimpleIdentifier]
abstract final class PrefixedIdentifier implements Identifier {
  /// Return the identifier being prefixed.
  SimpleIdentifier get identifier;

  /// Return `true` if this type is a deferred type. If the AST structure has
  /// not been resolved, then return `false`.
  ///
  /// 15.1 Static Types: A type <i>T</i> is deferred iff it is of the form
  /// </i>p.T</i> where <i>p</i> is a deferred prefix.
  bool get isDeferred;

  /// Return the period used to separate the prefix from the identifier.
  Token get period;

  /// Return the prefix associated with the library in which the identifier is
  /// defined.
  SimpleIdentifier get prefix;
}

/// An identifier that is prefixed or an access to an object property where the
/// target of the property access is a simple identifier.
///
///    prefixedIdentifier ::=
///        [SimpleIdentifier] '.' [SimpleIdentifier]
final class PrefixedIdentifierImpl extends IdentifierImpl
    implements PrefixedIdentifier {
  /// The prefix associated with the library in which the identifier is defined.
  SimpleIdentifierImpl _prefix;

  /// The period used to separate the prefix from the identifier.
  @override
  final Token period;

  /// The identifier being prefixed.
  SimpleIdentifierImpl _identifier;

  /// Initialize a newly created prefixed identifier.
  PrefixedIdentifierImpl({
    required SimpleIdentifierImpl prefix,
    required this.period,
    required SimpleIdentifierImpl identifier,
  })  : _prefix = prefix,
        _identifier = identifier {
    _becomeParentOf(_prefix);
    _becomeParentOf(_identifier);
  }

  @override
  Token get beginToken => _prefix.beginToken;

  @override
  Token get endToken => _identifier.endToken;

  @override
  SimpleIdentifierImpl get identifier => _identifier;

  set identifier(SimpleIdentifierImpl identifier) {
    _identifier = _becomeParentOf(identifier);
  }

  @override
  bool get isDeferred {
    Element? element = _prefix.staticElement;
    if (element is PrefixElement) {
      final imports = element.imports;
      if (imports.length != 1) {
        return false;
      }
      return imports[0].prefix is DeferredImportElementPrefix;
    }
    return false;
  }

  @override
  String get name => "${_prefix.name}.${_identifier.name}";

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  SimpleIdentifierImpl get prefix => _prefix;

  set prefix(SimpleIdentifierImpl identifier) {
    _prefix = _becomeParentOf(identifier);
  }

  @override
  Element? get staticElement {
    return _identifier.staticElement;
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('prefix', prefix)
    ..addToken('period', period)
    ..addNode('identifier', identifier);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPrefixedIdentifier(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitPrefixedIdentifier(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _prefix.accept(visitor);
    _identifier.accept(visitor);
  }
}

/// A prefix unary expression.
///
///    prefixExpression ::=
///        [Token] [Expression]
abstract final class PrefixExpression
    implements
        Expression,
        NullShortableExpression,
        MethodReferenceExpression,
        CompoundAssignmentExpression {
  /// Return the expression computing the operand for the operator.
  Expression get operand;

  /// Return the prefix operator being applied to the operand.
  Token get operator;
}

/// A prefix unary expression.
///
///    prefixExpression ::=
///        [Token] [Expression]
final class PrefixExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl, CompoundAssignmentExpressionImpl
    implements PrefixExpression {
  /// The prefix operator being applied to the operand.
  @override
  final Token operator;

  /// The expression computing the operand for the operator.
  ExpressionImpl _operand;

  /// The element associated with the operator based on the static type of the
  /// operand, or `null` if the AST structure has not been resolved, if the
  /// operator is not user definable, or if the operator could not be resolved.
  @override
  MethodElement? staticElement;

  /// Initialize a newly created prefix expression.
  PrefixExpressionImpl({
    required this.operator,
    required ExpressionImpl operand,
  }) : _operand = operand {
    _becomeParentOf(_operand);
  }

  @override
  Token get beginToken => operator;

  @override
  Token get endToken => _operand.endToken;

  @override
  ExpressionImpl get operand => _operand;

  set operand(ExpressionImpl expression) {
    _operand = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.prefix;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('operator', operator)
    ..addNode('operand', operand);

  @override
  AstNode? get _nullShortingExtensionCandidate => parent;

  /// If the AST structure has been resolved, and the function being invoked is
  /// known based on static type information, then return the parameter element
  /// representing the parameter to which the value of the operand will be
  /// bound.  Otherwise, return `null`.
  ParameterElement? get _staticParameterElementForOperand {
    if (staticElement == null) {
      return null;
    }
    List<ParameterElement> parameters = staticElement!.parameters;
    if (parameters.isEmpty) {
      return null;
    }
    return parameters[0];
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPrefixExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitPrefixExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _operand.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression descendant) =>
      identical(descendant, operand) && operator.type.isIncrementOperator;
}

/// The access of a property of an object.
///
/// Note, however, that accesses to properties of objects can also be
/// represented as [PrefixedIdentifier] nodes in cases where the target is also
/// a simple identifier.
///
///    propertyAccess ::=
///        [Expression] '.' [SimpleIdentifier]
abstract final class PropertyAccess
    implements NullShortableExpression, CommentReferableExpression {
  /// Return `true` if this expression is cascaded.
  ///
  /// If it is, then the target of this expression is not stored locally but is
  /// stored in the nearest ancestor that is a [CascadeExpression].
  bool get isCascaded;

  /// Whether this property access is null aware (as opposed to non-null).
  bool get isNullAware;

  /// Return the property access operator.
  Token get operator;

  /// Return the name of the property being accessed.
  SimpleIdentifier get propertyName;

  /// Return the expression used to compute the receiver of the invocation.
  ///
  /// If this invocation is not part of a cascade expression, then this is the
  /// same as [target]. If this invocation is part of a cascade expression,
  /// then the target stored with the cascade expression is returned.
  Expression get realTarget;

  /// Return the expression computing the object defining the property being
  /// accessed, or `null` if this property access is part of a cascade
  /// expression.
  ///
  /// Use [realTarget] to get the target independent of whether this is part of
  /// a cascade expression.
  Expression? get target;
}

/// The access of a property of an object.
///
/// Note, however, that accesses to properties of objects can also be
/// represented as [PrefixedIdentifier] nodes in cases where the target is also
/// a simple identifier.
///
///    propertyAccess ::=
///        [Expression] '.' [SimpleIdentifier]
final class PropertyAccessImpl extends CommentReferableExpressionImpl
    with NullShortableExpressionImpl
    implements PropertyAccess {
  /// The expression computing the object defining the property being accessed.
  ExpressionImpl? _target;

  /// The property access operator.
  @override
  final Token operator;

  /// The name of the property being accessed.
  SimpleIdentifierImpl _propertyName;

  /// Initialize a newly created property access expression.
  PropertyAccessImpl({
    required ExpressionImpl? target,
    required this.operator,
    required SimpleIdentifierImpl propertyName,
  })  : _target = target,
        _propertyName = propertyName {
    _becomeParentOf(_target);
    _becomeParentOf(_propertyName);
  }

  @override
  Token get beginToken {
    if (_target != null) {
      return _target!.beginToken;
    }
    return operator;
  }

  @override
  Token get endToken => _propertyName.endToken;

  @override
  bool get isAssignable => true;

  @override
  bool get isCascaded =>
      operator.type == TokenType.PERIOD_PERIOD ||
      operator.type == TokenType.QUESTION_PERIOD_PERIOD;

  @override
  bool get isNullAware {
    if (isCascaded) {
      return _ancestorCascade.isNullAware;
    }
    return operator.type == TokenType.QUESTION_PERIOD ||
        operator.type == TokenType.QUESTION_PERIOD_PERIOD;
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  SimpleIdentifierImpl get propertyName => _propertyName;

  set propertyName(SimpleIdentifierImpl identifier) {
    _propertyName = _becomeParentOf(identifier);
  }

  @override
  ExpressionImpl get realTarget {
    if (isCascaded) {
      return _ancestorCascade.target;
    }
    return _target!;
  }

  @override
  ExpressionImpl? get target => _target;

  set target(ExpressionImpl? expression) {
    _target = _becomeParentOf(expression);
  }

  /// Return the cascade that contains this [IndexExpression].
  ///
  /// We expect that [isCascaded] is `true`.
  CascadeExpressionImpl get _ancestorCascade {
    assert(isCascaded);
    for (var ancestor = parent!;; ancestor = ancestor.parent!) {
      if (ancestor is CascadeExpressionImpl) {
        return ancestor;
      }
    }
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('target', target)
    ..addToken('operator', operator)
    ..addNode('propertyName', propertyName);

  @override
  AstNode? get _nullShortingExtensionCandidate => parent;

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPropertyAccess(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitPropertyAccess(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _target?.accept(visitor);
    _propertyName.accept(visitor);
  }

  @override
  bool _extendsNullShorting(Expression descendant) =>
      identical(descendant, _target);
}

/// A record literal.
///
///    recordLiteral ::= '(' recordField (',' recordField)* ','? ')'
///
///    recordField  ::= (identifier ':')? [Expression]
abstract final class RecordLiteral implements Literal {
  /// Return the token representing the 'const' keyword, or `null` if the
  /// literal is not a constant.
  Token? get constKeyword;

  /// Return the syntactic elements used to compute the fields of the record.
  NodeList<Expression> get fields;

  /// Return `true` if this literal is a constant expression, either because the
  /// keyword `const` was explicitly provided or because no keyword was provided
  /// and this expression is in a constant context.
  bool get isConst;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the right parenthesis.
  Token get rightParenthesis;
}

final class RecordLiteralImpl extends LiteralImpl implements RecordLiteral {
  @override
  final Token? constKeyword;

  @override
  final Token leftParenthesis;

  /// The syntactic elements used to compute the fields of the record.
  final NodeListImpl<ExpressionImpl> _fields = NodeListImpl._();

  @override
  final Token rightParenthesis;

  /// Initialize a newly created record literal.
  RecordLiteralImpl({
    required this.constKeyword,
    required this.leftParenthesis,
    required List<ExpressionImpl> fields,
    required this.rightParenthesis,
  }) {
    _fields._initialize(this, fields);
  }

  @override
  Token get beginToken => constKeyword ?? leftParenthesis;

  @override
  Token get endToken => rightParenthesis;

  @override
  NodeList<ExpressionImpl> get fields => _fields;

  @override
  bool get isConst => constKeyword != null || inConstantContext;

  @override
  // TODO(paulberry): add commas.
  ChildEntities get _childEntities => super._childEntities
    ..addToken('constKeyword', constKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNodeList('fields', fields)
    ..addToken('rightParenthesis', rightParenthesis);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitRecordLiteral(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitRecordLiteral(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _fields.accept(visitor);
  }
}

/// A record pattern.
///
///    recordPattern ::=
///        '(' [PatternField] (',' [PatternField])* ')'
abstract final class RecordPattern implements DartPattern {
  /// Return the fields of the record pattern.
  NodeList<PatternField> get fields;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the right parenthesis.
  Token get rightParenthesis;
}

/// A record pattern.
///
///    recordPattern ::=
///        '(' [PatternField] (',' [PatternField])* ')'
final class RecordPatternImpl extends DartPatternImpl implements RecordPattern {
  final NodeListImpl<PatternFieldImpl> _fields = NodeListImpl._();

  @override
  final Token leftParenthesis;

  @override
  final Token rightParenthesis;

  RecordPatternImpl({
    required this.leftParenthesis,
    required List<PatternFieldImpl> fields,
    required this.rightParenthesis,
  }) {
    _fields._initialize(this, fields);
  }

  @override
  Token get beginToken => leftParenthesis;

  @override
  Token get endToken => rightParenthesis;

  @override
  NodeList<PatternFieldImpl> get fields => _fields;

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNodeList('fields', fields)
    ..addToken('rightParenthesis', rightParenthesis);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitRecordPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor.analyzeRecordPatternSchema(
      fields: resolverVisitor.buildSharedPatternFields(
        fields,
        mustBeNamed: false,
      ),
    );
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.analyzeRecordPattern(
      context,
      this,
      fields: resolverVisitor.buildSharedPatternFields(
        fields,
        mustBeNamed: false,
      ),
    );
  }

  @override
  void visitChildren(AstVisitor visitor) {
    fields.accept(visitor);
  }
}

/// A record type.
///
/// recordType ::=
///     '(' recordTypeFields ',' recordTypeNamedFields ')'
///   | '(' recordTypeFields ','? ')'
///   | '(' recordTypeNamedFields ')'
///
/// recordTypeFields ::= recordTypeField ( ',' recordTypeField )*
///
/// recordTypeField ::= metadata type identifier?
///
/// recordTypeNamedFields ::=
///     '{' recordTypeNamedField
///     ( ',' recordTypeNamedField )* ','? '}'
///
/// recordTypeNamedField ::= metadata type identifier
abstract final class RecordTypeAnnotation implements TypeAnnotation {
  /// The left parenthesis.
  Token get leftParenthesis;

  /// The optional named fields.
  RecordTypeAnnotationNamedFields? get namedFields;

  /// The positional fields (might be empty).
  NodeList<RecordTypeAnnotationPositionalField> get positionalFields;

  /// The right parenthesis.
  Token get rightParenthesis;
}

/// A field in a [RecordTypeAnnotation].
sealed class RecordTypeAnnotationField implements AstNode {
  /// The annotations associated with the field.
  NodeList<Annotation> get metadata;

  /// The name of the field.
  Token? get name;

  /// The type of the field.
  TypeAnnotation get type;
}

sealed class RecordTypeAnnotationFieldImpl extends AstNodeImpl
    implements RecordTypeAnnotationField {
  @override
  final NodeListImpl<AnnotationImpl> metadata = NodeListImpl._();

  @override
  final TypeAnnotationImpl type;

  RecordTypeAnnotationFieldImpl({
    required List<AnnotationImpl>? metadata,
    required this.type,
  }) {
    this.metadata._initialize(this, metadata);
    _becomeParentOf(type);
  }

  @override
  Token get beginToken => metadata.beginToken ?? type.beginToken;

  @override
  Token get endToken => name ?? type.endToken;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNodeList('metadata', metadata)
    ..addNode('type', type)
    ..addToken('name', name);

  @override
  void visitChildren(AstVisitor visitor) {
    metadata.accept(visitor);
    type.accept(visitor);
  }
}

final class RecordTypeAnnotationImpl extends TypeAnnotationImpl
    implements RecordTypeAnnotation {
  @override
  final Token leftParenthesis;

  @override
  final NodeListImpl<RecordTypeAnnotationPositionalFieldImpl> positionalFields =
      NodeListImpl._();

  @override
  final RecordTypeAnnotationNamedFieldsImpl? namedFields;

  @override
  final Token rightParenthesis;

  @override
  final Token? question;

  @override
  DartType? type;

  RecordTypeAnnotationImpl({
    required this.leftParenthesis,
    required List<RecordTypeAnnotationPositionalFieldImpl> positionalFields,
    required this.namedFields,
    required this.rightParenthesis,
    required this.question,
  }) {
    _becomeParentOf(namedFields);
    this.positionalFields._initialize(this, positionalFields);
  }

  @override
  Token get beginToken => leftParenthesis;

  @override
  Token get endToken => question ?? rightParenthesis;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNodeList('positionalFields', positionalFields)
    ..addNode('namedFields', namedFields)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addToken('question', question);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitRecordTypeAnnotation(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    positionalFields.accept(visitor);
    namedFields?.accept(visitor);
  }
}

/// A named field in a [RecordTypeAnnotation].
abstract final class RecordTypeAnnotationNamedField
    implements RecordTypeAnnotationField {
  @override
  Token get name;
}

final class RecordTypeAnnotationNamedFieldImpl
    extends RecordTypeAnnotationFieldImpl
    implements RecordTypeAnnotationNamedField {
  @override
  final Token name;

  RecordTypeAnnotationNamedFieldImpl({
    required super.metadata,
    required super.type,
    required this.name,
  });

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitRecordTypeAnnotationNamedField(this);
  }
}

/// The portion of a [RecordTypeAnnotation] with named fields.
abstract final class RecordTypeAnnotationNamedFields implements AstNode {
  /// The fields contained in the block.
  NodeList<RecordTypeAnnotationNamedField> get fields;

  /// The left curly bracket.
  Token get leftBracket;

  /// The right curly bracket.
  Token get rightBracket;
}

final class RecordTypeAnnotationNamedFieldsImpl extends AstNodeImpl
    implements RecordTypeAnnotationNamedFields {
  @override
  final Token leftBracket;

  @override
  final NodeListImpl<RecordTypeAnnotationNamedFieldImpl> fields =
      NodeListImpl._();

  @override
  final Token rightBracket;

  RecordTypeAnnotationNamedFieldsImpl({
    required this.leftBracket,
    required List<RecordTypeAnnotationNamedFieldImpl> fields,
    required this.rightBracket,
  }) {
    this.fields._initialize(this, fields);
  }

  @override
  Token get beginToken => leftBracket;

  @override
  Token get endToken => rightBracket;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('fields', fields)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitRecordTypeAnnotationNamedFields(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    fields.accept(visitor);
  }
}

/// A positional field in a [RecordTypeAnnotation].
abstract final class RecordTypeAnnotationPositionalField
    implements RecordTypeAnnotationField {}

final class RecordTypeAnnotationPositionalFieldImpl
    extends RecordTypeAnnotationFieldImpl
    implements RecordTypeAnnotationPositionalField {
  @override
  final Token? name;

  RecordTypeAnnotationPositionalFieldImpl({
    required super.metadata,
    required super.type,
    required this.name,
  });

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitRecordTypeAnnotationPositionalField(this);
  }
}

/// The invocation of a constructor in the same class from within a
/// constructor's initialization list.
///
///    redirectingConstructorInvocation ::=
///        'this' ('.' identifier)? arguments
abstract final class RedirectingConstructorInvocation
    implements ConstructorInitializer, ConstructorReferenceNode {
  /// Return the list of arguments to the constructor.
  ArgumentList get argumentList;

  /// Return the name of the constructor that is being invoked, or `null` if the
  /// unnamed constructor is being invoked.
  SimpleIdentifier? get constructorName;

  /// Return the token for the period before the name of the constructor that is
  /// being invoked, or `null` if the unnamed constructor is being invoked.
  Token? get period;

  /// Return the token for the 'this' keyword.
  Token get thisKeyword;
}

/// The invocation of a constructor in the same class from within a
/// constructor's initialization list.
///
///    redirectingConstructorInvocation ::=
///        'this' ('.' identifier)? arguments
final class RedirectingConstructorInvocationImpl
    extends ConstructorInitializerImpl
    implements RedirectingConstructorInvocation {
  /// The token for the 'this' keyword.
  @override
  final Token thisKeyword;

  /// The token for the period before the name of the constructor that is being
  /// invoked, or `null` if the unnamed constructor is being invoked.
  @override
  final Token? period;

  /// The name of the constructor that is being invoked, or `null` if the
  /// unnamed constructor is being invoked.
  SimpleIdentifierImpl? _constructorName;

  /// The list of arguments to the constructor.
  ArgumentListImpl _argumentList;

  /// The element associated with the constructor based on static type
  /// information, or `null` if the AST structure has not been resolved or if
  /// the constructor could not be resolved.
  @override
  ConstructorElement? staticElement;

  /// Initialize a newly created redirecting invocation to invoke the
  /// constructor with the given name with the given arguments. The
  /// [constructorName] can be `null` if the constructor being invoked is the
  /// unnamed constructor.
  RedirectingConstructorInvocationImpl({
    required this.thisKeyword,
    required this.period,
    required SimpleIdentifierImpl? constructorName,
    required ArgumentListImpl argumentList,
  })  : _constructorName = constructorName,
        _argumentList = argumentList {
    _becomeParentOf(_constructorName);
    _becomeParentOf(_argumentList);
  }

  @override
  ArgumentListImpl get argumentList => _argumentList;

  set argumentList(ArgumentListImpl argumentList) {
    _argumentList = _becomeParentOf(argumentList);
  }

  @override
  Token get beginToken => thisKeyword;

  @override
  SimpleIdentifierImpl? get constructorName => _constructorName;

  set constructorName(SimpleIdentifierImpl? identifier) {
    _constructorName = _becomeParentOf(identifier);
  }

  @override
  Token get endToken => _argumentList.endToken;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('thisKeyword', thisKeyword)
    ..addToken('period', period)
    ..addNode('constructorName', constructorName)
    ..addNode('argumentList', argumentList);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitRedirectingConstructorInvocation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _constructorName?.accept(visitor);
    _argumentList.accept(visitor);
  }
}

/// A relational pattern.
///
///    relationalPattern ::=
///        (equalityOperator | relationalOperator) [Expression]
abstract final class RelationalPattern implements DartPattern {
  /// The element of the [operator] for the matched type.
  MethodElement? get element;

  /// Return the expression used to compute the operand.
  Expression get operand;

  /// Return the relational operator being applied.
  Token get operator;
}

/// A relational pattern.
///
///    relationalPattern ::=
///        (equalityOperator | relationalOperator) [Expression]
final class RelationalPatternImpl extends DartPatternImpl
    implements RelationalPattern {
  ExpressionImpl _operand;

  @override
  final Token operator;

  @override
  MethodElement? element;

  RelationalPatternImpl({
    required this.operator,
    required ExpressionImpl operand,
  }) : _operand = operand {
    _becomeParentOf(operand);
  }

  @override
  Token get beginToken => operator;

  @override
  Token get endToken => operand.endToken;

  @override
  ExpressionImpl get operand => _operand;

  set operand(ExpressionImpl operand) {
    _operand = _becomeParentOf(operand);
  }

  @override
  PatternPrecedence get precedence => PatternPrecedence.relational;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('operator', operator)
    ..addNode('operand', operand);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitRelationalPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor.analyzeRelationalPatternSchema();
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    resolverVisitor.analyzeRelationalPattern(context, this, operand);
    resolverVisitor.popRewrite();
  }

  @override
  void visitChildren(AstVisitor visitor) {
    operand.accept(visitor);
  }
}

/// A rest pattern element.
///
///    restPatternElement ::= '...' [DartPattern]?
abstract final class RestPatternElement
    implements ListPatternElement, MapPatternElement {
  /// The operator token '...'.
  Token get operator;

  /// The optional pattern.
  DartPattern? get pattern;
}

final class RestPatternElementImpl extends AstNodeImpl
    implements
        RestPatternElement,
        ListPatternElementImpl,
        MapPatternElementImpl {
  @override
  final Token operator;

  @override
  final DartPatternImpl? pattern;

  RestPatternElementImpl({
    required this.operator,
    required this.pattern,
  }) {
    _becomeParentOf(pattern);
  }

  @override
  Token get beginToken => operator;

  @override
  Token get endToken => pattern?.endToken ?? operator;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('operator', operator)
    ..addNode('pattern', pattern);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitRestPatternElement(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    pattern?.accept(visitor);
  }
}

/// A rethrow expression.
///
///    rethrowExpression ::=
///        'rethrow'
abstract final class RethrowExpression implements Expression {
  /// Return the token representing the 'rethrow' keyword.
  Token get rethrowKeyword;
}

/// A rethrow expression.
///
///    rethrowExpression ::=
///        'rethrow'
final class RethrowExpressionImpl extends ExpressionImpl
    implements RethrowExpression {
  /// The token representing the 'rethrow' keyword.
  @override
  final Token rethrowKeyword;

  /// Initialize a newly created rethrow expression.
  RethrowExpressionImpl({
    required this.rethrowKeyword,
  });

  @override
  Token get beginToken => rethrowKeyword;

  @override
  Token get endToken => rethrowKeyword;

  @override
  Precedence get precedence => Precedence.assignment;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('rethrowKeyword', rethrowKeyword);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitRethrowExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitRethrowExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// A return statement.
///
///    returnStatement ::=
///        'return' [Expression]? ';'
abstract final class ReturnStatement implements Statement {
  /// Return the expression computing the value to be returned, or `null` if no
  /// explicit value was provided.
  Expression? get expression;

  /// Return the token representing the 'return' keyword.
  Token get returnKeyword;

  /// Return the semicolon terminating the statement.
  Token get semicolon;
}

/// A return statement.
///
///    returnStatement ::=
///        'return' [Expression]? ';'
final class ReturnStatementImpl extends StatementImpl
    implements ReturnStatement {
  /// The token representing the 'return' keyword.
  @override
  final Token returnKeyword;

  /// The expression computing the value to be returned, or `null` if no
  /// explicit value was provided.
  ExpressionImpl? _expression;

  /// The semicolon terminating the statement.
  @override
  final Token semicolon;

  /// Initialize a newly created return statement. The [expression] can be
  /// `null` if no explicit value was provided.
  ReturnStatementImpl({
    required this.returnKeyword,
    required ExpressionImpl? expression,
    required this.semicolon,
  }) : _expression = expression {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => returnKeyword;

  @override
  Token get endToken => semicolon;

  @override
  ExpressionImpl? get expression => _expression;

  set expression(ExpressionImpl? expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('returnKeyword', returnKeyword)
    ..addNode('expression', expression)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitReturnStatement(this);

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
abstract final class ScriptTag implements AstNode {
  /// Return the token representing this script tag.
  Token get scriptTag;
}

/// A script tag that can optionally occur at the beginning of a compilation
/// unit.
///
///    scriptTag ::=
///        '#!' (~NEWLINE)* NEWLINE
final class ScriptTagImpl extends AstNodeImpl implements ScriptTag {
  /// The token representing this script tag.
  @override
  final Token scriptTag;

  /// Initialize a newly created script tag.
  ScriptTagImpl({
    required this.scriptTag,
  });

  @override
  Token get beginToken => scriptTag;

  @override
  Token get endToken => scriptTag;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('scriptTag', scriptTag);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitScriptTag(this);

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// A set or map literal.
///
///    setOrMapLiteral ::=
///        'const'? [TypeArgumentList]? '{' elements? '}'
///
///    elements ::=
///        [CollectionElement] ( ',' [CollectionElement] )* ','?
///
/// This is the class that is used to represent either a map or set literal when
/// either the 'control-flow-collections' or 'spread-collections' experiments
/// are enabled. If neither of those experiments are enabled, then `MapLiteral`
/// will be used to represent a map literal and `SetLiteral` will be used for
/// set literals.
abstract final class SetOrMapLiteral implements TypedLiteral {
  /// Return the syntactic elements used to compute the elements of the set or
  /// map.
  NodeList<CollectionElement> get elements;

  /// Return `true` if this literal represents a map literal.
  ///
  /// This getter will always return `false` if [isSet] returns `true`.
  ///
  /// However, this getter is _not_ the inverse of [isSet]. It is possible for
  /// both getters to return `false` if
  ///
  /// - the AST has not been resolved (because determining the kind of the
  ///   literal is done during resolution),
  /// - the literal is ambiguous (contains one or more spread elements and none
  ///   of those elements can be used to determine the kind of the literal), or
  /// - the literal is invalid because it contains both expressions (for sets)
  ///   and map entries (for maps).
  ///
  /// In both of the latter two cases there will be compilation errors
  /// associated with the literal.
  bool get isMap;

  /// Return `true` if this literal represents a set literal.
  ///
  /// This getter will always return `false` if [isMap] returns `true`.
  ///
  /// However, this getter is _not_ the inverse of [isMap]. It is possible for
  /// both getters to return `false` if
  ///
  /// - the AST has not been resolved (because determining the kind of the
  ///   literal is done during resolution),
  /// - the literal is ambiguous (contains one or more spread elements and none
  ///   of those elements can be used to determine the kind of the literal), or
  /// - the literal is invalid because it contains both expressions (for sets)
  ///   and map entries (for maps).
  ///
  /// In both of the latter two cases there will be compilation errors
  /// associated with the literal.
  bool get isSet;

  /// Return the left curly bracket.
  Token get leftBracket;

  /// Return the right curly bracket.
  Token get rightBracket;
}

final class SetOrMapLiteralImpl extends TypedLiteralImpl
    implements SetOrMapLiteral {
  @override
  final Token leftBracket;

  /// The syntactic elements in the set.
  final NodeListImpl<CollectionElementImpl> _elements = NodeListImpl._();

  @override
  final Token rightBracket;

  /// A representation of whether this literal represents a map or a set, or
  /// whether the kind has not or cannot be determined.
  _SetOrMapKind _resolvedKind = _SetOrMapKind.unresolved;

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
  InterfaceType? contextType;

  /// Initialize a newly created set or map literal. The [constKeyword] can be
  /// `null` if the literal is not a constant. The [typeArguments] can be `null`
  /// if no type arguments were declared. The [elements] can be `null` if the
  /// set is empty.
  SetOrMapLiteralImpl({
    required super.constKeyword,
    required super.typeArguments,
    required this.leftBracket,
    required List<CollectionElementImpl> elements,
    required this.rightBracket,
  }) {
    _elements._initialize(this, elements);
  }

  @override
  Token get beginToken {
    if (constKeyword != null) {
      return constKeyword!;
    }
    final typeArguments = this.typeArguments;
    if (typeArguments != null) {
      return typeArguments.beginToken;
    }
    return leftBracket;
  }

  @override
  NodeListImpl<CollectionElementImpl> get elements => _elements;

  @override
  Token get endToken => rightBracket;

  @override
  bool get isMap => _resolvedKind == _SetOrMapKind.map;

  @override
  bool get isSet => _resolvedKind == _SetOrMapKind.set;

  @override
  // TODO(paulberry): add commas.
  ChildEntities get _childEntities => super._childEntities
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('elements', elements)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSetOrMapLiteral(this);

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
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitSetOrMapLiteral(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _elements.accept(visitor);
  }
}

/// A combinator that restricts the names being imported to those in a given list.
///
///    showCombinator ::=
///        'show' [SimpleIdentifier] (',' [SimpleIdentifier])*
abstract final class ShowCombinator implements Combinator {
  /// Return the list of names from the library that are made visible by this
  /// combinator.
  NodeList<SimpleIdentifier> get shownNames;
}

/// A combinator that restricts the names being imported to those in a given
/// list.
///
///    showCombinator ::=
///        'show' [SimpleIdentifier] (',' [SimpleIdentifier])*
final class ShowCombinatorImpl extends CombinatorImpl
    implements ShowCombinator {
  /// The list of names from the library that are made visible by this
  /// combinator.
  final NodeListImpl<SimpleIdentifierImpl> _shownNames = NodeListImpl._();

  /// Initialize a newly created import show combinator.
  ShowCombinatorImpl({
    required super.keyword,
    required List<SimpleIdentifierImpl> shownNames,
  }) {
    _shownNames._initialize(this, shownNames);
  }

  @override
  Token get endToken => _shownNames.endToken!;

  @override
  NodeListImpl<SimpleIdentifierImpl> get shownNames => _shownNames;

  @override
  // TODO(paulberry): add commas.
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('keyword', keyword)
    ..addNodeList('shownNames', shownNames);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitShowCombinator(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _shownNames.accept(visitor);
  }
}

/// A simple formal parameter.
///
///    simpleFormalParameter ::=
///        ('final' [TypeAnnotation] | 'var' | [TypeAnnotation])? [SimpleIdentifier]
abstract final class SimpleFormalParameter implements NormalFormalParameter {
  /// Return the token representing either the 'final', 'const' or 'var'
  /// keyword, or `null` if no keyword was used.
  Token? get keyword;

  /// Return the declared type of the parameter, or `null` if the parameter does
  /// not have a declared type.
  TypeAnnotation? get type;
}

/// A simple formal parameter.
///
///    simpleFormalParameter ::=
///        ('final' [NamedType] | 'var' | [NamedType])? [SimpleIdentifier]
final class SimpleFormalParameterImpl extends NormalFormalParameterImpl
    implements SimpleFormalParameter {
  /// The token representing either the 'final', 'const' or 'var' keyword, or
  /// `null` if no keyword was used.
  @override
  final Token? keyword;

  /// The name of the declared type of the parameter, or `null` if the parameter
  /// does not have a declared type.
  TypeAnnotationImpl? _type;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute. The [keyword] can be `null` if a type was
  /// specified. The [type] must be `null` if the keyword is 'var'.
  SimpleFormalParameterImpl({
    required super.comment,
    required super.metadata,
    required super.covariantKeyword,
    required super.requiredKeyword,
    required this.keyword,
    required TypeAnnotationImpl? type,
    required super.name,
  }) : _type = type {
    _becomeParentOf(_type);
  }

  @override
  Token get beginToken {
    final metadata = this.metadata;
    if (metadata.isNotEmpty) {
      return metadata.beginToken!;
    } else if (requiredKeyword != null) {
      return requiredKeyword!;
    } else if (covariantKeyword != null) {
      return covariantKeyword!;
    } else if (keyword != null) {
      return keyword!;
    } else if (_type != null) {
      return _type!.beginToken;
    }
    return name!;
  }

  @override
  Token get endToken => name ?? type!.endToken;

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isExplicitlyTyped => _type != null;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @override
  TypeAnnotationImpl? get type => _type;

  set type(TypeAnnotationImpl? type) {
    _type = _becomeParentOf(type);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('keyword', keyword)
    ..addNode('type', type)
    ..addToken('name', name);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitSimpleFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _type?.accept(visitor);
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
abstract final class SimpleIdentifier implements Identifier {
  /// Return `true` if this identifier is the "name" part of a prefixed
  /// identifier or a method invocation.
  bool get isQualified;

  /// If the identifier is a tear-off, return the inferred type arguments
  /// applied to the function type of the element to produce its `[staticType]`.
  ///
  /// Return an empty list if the function type does not have type parameters.
  ///
  /// Return an empty list if the context type has type parameters.
  ///
  /// Return `null` if not a tear-off.
  ///
  /// Return `null` if the AST structure has not been resolved.
  List<DartType>? get tearOffTypeArgumentTypes;

  /// Return the token representing the identifier.
  Token get token;

  /// Return `true` if this identifier is the name being declared in a
  /// declaration.
  // TODO(brianwilkerson) Convert this to a getter.
  bool inDeclarationContext();

  /// Return `true` if this expression is computing a right-hand value.
  ///
  /// Note that [inGetterContext] and [inSetterContext] are not opposites, nor
  /// are they mutually exclusive. In other words, it is possible for both
  /// methods to return `true` when invoked on the same node.
  // TODO(brianwilkerson) Convert this to a getter.
  bool inGetterContext();

  /// Return `true` if this expression is computing a left-hand value.
  ///
  /// Note that [inGetterContext] and [inSetterContext] are not opposites, nor
  /// are they mutually exclusive. In other words, it is possible for both
  /// methods to return `true` when invoked on the same node.
  // TODO(brianwilkerson) Convert this to a getter.
  bool inSetterContext();
}

/// A simple identifier.
///
///    simpleIdentifier ::=
///        initialCharacter internalCharacter*
///
///    initialCharacter ::= '_' | '$' | letter
///
///    internalCharacter ::= '_' | '$' | letter | digit
final class SimpleIdentifierImpl extends IdentifierImpl
    implements SimpleIdentifier {
  /// The token representing the identifier.
  @override
  final Token token;

  /// The element associated with this identifier based on static type
  /// information, or `null` if the AST structure has not been resolved or if
  /// this identifier could not be resolved.
  Element? _staticElement;

  @override
  List<DartType>? tearOffTypeArgumentTypes;

  /// If this identifier is meant to be looked up in the enclosing scope, the
  /// raw result the scope lookup, prior to figuring out whether a write or a
  /// read context is intended, and prior to falling back on implicit `this` (if
  /// appropriate).
  ///
  /// `null` if this identifier is not meant to be looked up in the enclosing
  /// scope.
  ScopeLookupResult? scopeLookupResult;

  /// Initialize a newly created identifier.
  SimpleIdentifierImpl(this.token);

  /// Return the cascade that contains this [SimpleIdentifier].
  CascadeExpressionImpl? get ancestorCascade {
    var operatorType = token.previous?.type;
    if (operatorType == TokenType.PERIOD_PERIOD ||
        operatorType == TokenType.QUESTION_PERIOD_PERIOD) {
      return thisOrAncestorOfType<CascadeExpressionImpl>();
    }
    return null;
  }

  @override
  Token get beginToken => token;

  @override
  Token get endToken => token;

  @override
  bool get isQualified {
    final parent = this.parent!;
    if (parent is PrefixedIdentifier) {
      return identical(parent.identifier, this);
    } else if (parent is PropertyAccess) {
      return identical(parent.propertyName, this);
    } else if (parent is ConstructorName) {
      return identical(parent.name, this);
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
  /// Examples are the name of the type in a [NamedType], the name of the method
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
  Element? get referenceElement => null;

  @override
  Element? get staticElement => _staticElement;

  set staticElement(Element? element) {
    _staticElement = element;
  }

  @override
  ChildEntities get _childEntities => ChildEntities()..addToken('token', token);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSimpleIdentifier(this);

  @override
  bool inDeclarationContext() {
    final parent = this.parent;
    switch (parent) {
      case ImportDirective():
        return parent.prefix == this;
      case Label():
        final parent2 = parent.parent;
        return parent2 is Statement || parent2 is SwitchMember;
    }
    return false;
  }

  @override
  bool inGetterContext() {
    // TODO(brianwilkerson) Convert this to a getter.
    AstNode initialParent = this.parent!;
    AstNode parent = initialParent;
    AstNode target = this;
    // skip prefix
    if (initialParent is PrefixedIdentifier) {
      if (identical(initialParent.prefix, this)) {
        return true;
      }
      parent = initialParent.parent!;
      target = initialParent;
    } else if (initialParent is PropertyAccess) {
      if (identical(initialParent.target, this)) {
        return true;
      }
      parent = initialParent.parent!;
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
    return true;
  }

  @override
  bool inSetterContext() {
    // TODO(brianwilkerson) Convert this to a getter.
    AstNode initialParent = this.parent!;
    AstNode parent = initialParent;
    AstNode target = this;
    // skip prefix
    if (initialParent is PrefixedIdentifier) {
      // if this is the prefix, then return false
      if (identical(initialParent.prefix, this)) {
        return false;
      }
      parent = initialParent.parent!;
      target = initialParent;
    } else if (initialParent is PropertyAccess) {
      if (identical(initialParent.target, this)) {
        return false;
      }
      parent = initialParent.parent!;
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
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitSimpleIdentifier(this, contextType: contextType);
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
///    basicStringLiteral ::=
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
abstract final class SimpleStringLiteral implements SingleStringLiteral {
  /// Return the token representing the literal.
  Token get literal;

  /// Return the value of the literal.
  String get value;
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
final class SimpleStringLiteralImpl extends SingleStringLiteralImpl
    implements SimpleStringLiteral {
  /// The token representing the literal.
  @override
  final Token literal;

  /// The value of the literal.
  @override
  String value;

  /// Initialize a newly created simple string literal.
  SimpleStringLiteralImpl({
    required this.literal,
    required this.value,
  });

  @override
  Token get beginToken => literal;

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
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('literal', literal);

  StringLexemeHelper get _helper {
    return StringLexemeHelper(literal.lexeme, true, true);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSimpleStringLiteral(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitSimpleStringLiteral(this, contextType: contextType);
  }

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
sealed class SingleStringLiteral implements StringLiteral {
  /// Return the offset of the after-last contents character.
  int get contentsEnd;

  /// Return the offset of the first contents character.
  ///
  /// If the string is multiline, then leading whitespaces are skipped.
  int get contentsOffset;

  /// Return `true` if this string literal is a multi-line string.
  bool get isMultiline;

  /// Return `true` if this string literal is a raw string.
  bool get isRaw;

  /// Return `true` if this string literal uses single quotes (' or '''), or
  /// `false` if this string literal uses double quotes (" or """).
  bool get isSingleQuoted;
}

/// A single string literal expression.
///
///    singleStringLiteral ::=
///        [SimpleStringLiteral]
///      | [StringInterpolation]
sealed class SingleStringLiteralImpl extends StringLiteralImpl
    implements SingleStringLiteral {}

/// A spread element.
///
///    spreadElement:
///        ( '...' | '...?' ) [Expression]
abstract final class SpreadElement implements CollectionElement {
  /// The expression used to compute the collection being spread.
  Expression get expression;

  /// Whether this is a null-aware spread, as opposed to a non-null spread.
  bool get isNullAware;

  /// The spread operator, either '...' or '...?'.
  Token get spreadOperator;
}

final class SpreadElementImpl extends AstNodeImpl
    implements CollectionElementImpl, SpreadElement {
  @override
  final Token spreadOperator;

  ExpressionImpl _expression;

  SpreadElementImpl({
    required this.spreadOperator,
    required ExpressionImpl expression,
  }) : _expression = expression {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => spreadOperator;

  @override
  Token get endToken => _expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  bool get isNullAware =>
      spreadOperator.type == TokenType.PERIOD_PERIOD_PERIOD_QUESTION;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('spreadOperator', spreadOperator)
    ..addNode('expression', expression);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitSpreadElement(this);
  }

  @override
  void resolveElement(
      ResolverVisitor resolver, CollectionLiteralContext? context) {
    resolver.visitSpreadElement(this, context: context);
    resolver.pushRewrite(null);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
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
abstract final class Statement implements AstNode {
  /// If this is a labeled statement, return the unlabeled portion of the
  /// statement, otherwise return the statement itself.
  Statement get unlabeled;
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
sealed class StatementImpl extends AstNodeImpl implements Statement {
  @override
  StatementImpl get unlabeled => this;
}

/// A string interpolation literal.
///
///    stringInterpolation ::=
///        ''' [InterpolationElement]* '''
///      | '"' [InterpolationElement]* '"'
abstract final class StringInterpolation implements SingleStringLiteral {
  /// Return the elements that will be composed to produce the resulting string.
  /// The list includes [firstString] and [lastString].
  NodeList<InterpolationElement> get elements;

  /// Return the first element in this interpolation, which is always a string.
  /// The string might be empty if there is no text before the first
  /// interpolation expression (such as in `'$foo bar'`).
  InterpolationString get firstString;

  /// Return the last element in this interpolation, which is always a string.
  /// The string might be empty if there is no text after the last
  /// interpolation expression (such as in `'foo $bar'`).
  InterpolationString get lastString;
}

/// A string interpolation literal.
///
///    stringInterpolation ::=
///        ''' [InterpolationElement]* '''
///      | '"' [InterpolationElement]* '"'
final class StringInterpolationImpl extends SingleStringLiteralImpl
    implements StringInterpolation {
  /// The elements that will be composed to produce the resulting string.
  final NodeListImpl<InterpolationElementImpl> _elements = NodeListImpl._();

  /// Initialize a newly created string interpolation expression.
  StringInterpolationImpl({
    required List<InterpolationElementImpl> elements,
  }) {
    // TODO(scheglov) Replace asserts with appropriately typed parameters.
    assert(elements.length > 2, 'Expected at last three elements.');
    assert(
      elements.first is InterpolationStringImpl,
      'The first element must be a string.',
    );
    assert(
      elements[1] is InterpolationExpressionImpl,
      'The second element must be an expression.',
    );
    assert(
      elements.last is InterpolationStringImpl,
      'The last element must be a string.',
    );
    _elements._initialize(this, elements);
  }

  @override
  Token get beginToken => _elements.beginToken!;

  @override
  int get contentsEnd {
    var element = _elements.last as InterpolationString;
    return element.contentsEnd;
  }

  @override
  int get contentsOffset {
    var element = _elements.first as InterpolationString;
    return element.contentsOffset;
  }

  /// Return the elements that will be composed to produce the resulting string.
  @override
  NodeListImpl<InterpolationElementImpl> get elements => _elements;

  @override
  Token get endToken => _elements.endToken!;

  @override
  InterpolationStringImpl get firstString =>
      elements.first as InterpolationStringImpl;

  @override
  bool get isMultiline => _firstHelper.isMultiline;

  @override
  bool get isRaw => false;

  @override
  bool get isSingleQuoted => _firstHelper.isSingleQuoted;

  @override
  InterpolationStringImpl get lastString =>
      elements.last as InterpolationStringImpl;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addNodeList('elements', elements);

  StringLexemeHelper get _firstHelper {
    var lastString = _elements.first as InterpolationString;
    String lexeme = lastString.contents.lexeme;
    return StringLexemeHelper(lexeme, true, false);
  }

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitStringInterpolation(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitStringInterpolation(this, contextType: contextType);
  }

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
  int end = 0;

  StringLexemeHelper(this.lexeme, this.isFirst, this.isLast) {
    if (isFirst) {
      isRaw = lexeme.startsWith('r');
      if (isRaw) {
        start++;
      }
      if (lexeme.startsWith("'''", start)) {
        isSingleQuoted = true;
        isMultiline = true;
        start += 3;
        start = _trimInitialWhitespace(start);
      } else if (lexeme.startsWith('"""', start)) {
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
          (lexeme.endsWith("'''") || lexeme.endsWith('"""'))) {
        end -= 3;
      } else if (start + 1 <= end &&
          (lexeme.endsWith("'") || lexeme.endsWith('"'))) {
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
sealed class StringLiteral implements Literal {
  /// Return the value of the string literal, or `null` if the string is not a
  /// constant string without any string interpolation.
  String? get stringValue;
}

/// A string literal expression.
///
///    stringLiteral ::=
///        [SimpleStringLiteral]
///      | [AdjacentStrings]
///      | [StringInterpolation]
sealed class StringLiteralImpl extends LiteralImpl implements StringLiteral {
  @override
  String? get stringValue {
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
abstract final class SuperConstructorInvocation
    implements ConstructorInitializer, ConstructorReferenceNode {
  /// Return the list of arguments to the constructor.
  ArgumentList get argumentList;

  /// Return the name of the constructor that is being invoked, or `null` if the
  /// unnamed constructor is being invoked.
  SimpleIdentifier? get constructorName;

  /// Return the token for the period before the name of the constructor that is
  /// being invoked, or `null` if the unnamed constructor is being invoked.
  Token? get period;

  /// Return the token for the 'super' keyword.
  Token get superKeyword;
}

/// The invocation of a superclass' constructor from within a constructor's
/// initialization list.
///
///    superInvocation ::=
///        'super' ('.' [SimpleIdentifier])? [ArgumentList]
final class SuperConstructorInvocationImpl extends ConstructorInitializerImpl
    implements SuperConstructorInvocation {
  /// The token for the 'super' keyword.
  @override
  final Token superKeyword;

  /// The token for the period before the name of the constructor that is being
  /// invoked, or `null` if the unnamed constructor is being invoked.
  @override
  final Token? period;

  /// The name of the constructor that is being invoked, or `null` if the
  /// unnamed constructor is being invoked.
  SimpleIdentifierImpl? _constructorName;

  /// The list of arguments to the constructor.
  ArgumentListImpl _argumentList;

  /// The element associated with the constructor based on static type
  /// information, or `null` if the AST structure has not been resolved or if
  /// the constructor could not be resolved.
  @override
  ConstructorElement? staticElement;

  /// Initialize a newly created super invocation to invoke the inherited
  /// constructor with the given name with the given arguments. The [period] and
  /// [constructorName] can be `null` if the constructor being invoked is the
  /// unnamed constructor.
  SuperConstructorInvocationImpl({
    required this.superKeyword,
    required this.period,
    required SimpleIdentifierImpl? constructorName,
    required ArgumentListImpl argumentList,
  })  : _constructorName = constructorName,
        _argumentList = argumentList {
    _becomeParentOf(_constructorName);
    _becomeParentOf(_argumentList);
  }

  @override
  ArgumentListImpl get argumentList => _argumentList;

  set argumentList(ArgumentListImpl argumentList) {
    _argumentList = _becomeParentOf(argumentList);
  }

  @override
  Token get beginToken => superKeyword;

  @override
  SimpleIdentifierImpl? get constructorName => _constructorName;

  set constructorName(SimpleIdentifierImpl? identifier) {
    _constructorName = _becomeParentOf(identifier);
  }

  @override
  Token get endToken => _argumentList.endToken;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('superKeyword', superKeyword)
    ..addToken('period', period)
    ..addNode('constructorName', constructorName)
    ..addNode('argumentList', argumentList);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitSuperConstructorInvocation(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _constructorName?.accept(visitor);
    _argumentList.accept(visitor);
  }
}

/// A super expression.
///
///    superExpression ::=
///        'super'
abstract final class SuperExpression implements Expression {
  /// Return the token representing the 'super' keyword.
  Token get superKeyword;
}

/// A super expression.
///
///    superExpression ::=
///        'super'
final class SuperExpressionImpl extends ExpressionImpl
    implements SuperExpression {
  /// The token representing the 'super' keyword.
  @override
  final Token superKeyword;

  /// Initialize a newly created super expression.
  SuperExpressionImpl({
    required this.superKeyword,
  });

  @override
  Token get beginToken => superKeyword;

  @override
  Token get endToken => superKeyword;

  @override
  Precedence get precedence => Precedence.primary;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('superKeyword', superKeyword);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSuperExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitSuperExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// A super-initializer formal parameter.
///
///    superFormalParameter ::=
///        ('final' [TypeAnnotation] | 'const' [TypeAnnotation] | 'var' | [TypeAnnotation])?
///        'super' '.' name ([TypeParameterList]? [FormalParameterList])?
abstract final class SuperFormalParameter implements NormalFormalParameter {
  /// Return the token representing either the 'final', 'const' or 'var'
  /// keyword, or `null` if no keyword was used.
  Token? get keyword;

  @override
  Token get name;

  /// Return the parameters of the function-typed parameter, or `null` if this
  /// is not a function-typed field formal parameter.
  FormalParameterList? get parameters;

  /// Return the token representing the period.
  Token get period;

  /// If the parameter is function-typed, and has the question mark, then its
  /// function type is nullable. Having a nullable function type means that the
  /// parameter can be null.
  Token? get question;

  /// Return the token representing the 'super' keyword.
  Token get superKeyword;

  /// Return the declared type of the parameter, or `null` if the parameter does
  /// not have a declared type.
  ///
  /// Note that if this is a function-typed field formal parameter this is the
  /// return type of the function.
  TypeAnnotation? get type;

  /// Return the type parameters associated with this method, or `null` if this
  /// method is not a generic method.
  TypeParameterList? get typeParameters;
}

/// A super-initializer formal parameter.
///
///    fieldFormalParameter ::=
///        ('final' [NamedType] | 'const' [NamedType] | 'var' | [NamedType])?
///        'super' '.' [SimpleIdentifier]
///        ([TypeParameterList]? [FormalParameterList])?
final class SuperFormalParameterImpl extends NormalFormalParameterImpl
    implements SuperFormalParameter {
  /// The token representing either the 'final', 'const' or 'var' keyword, or
  /// `null` if no keyword was used.
  @override
  final Token? keyword;

  /// The name of the declared type of the parameter, or `null` if the parameter
  /// does not have a declared type.
  TypeAnnotationImpl? _type;

  /// The token representing the 'super' keyword.
  @override
  final Token superKeyword;

  /// The token representing the period.
  @override
  final Token period;

  /// The type parameters associated with the method, or `null` if the method is
  /// not a generic method.
  TypeParameterListImpl? _typeParameters;

  /// The parameters of the function-typed parameter, or `null` if this is not a
  /// function-typed field formal parameter.
  FormalParameterListImpl? _parameters;

  @override
  final Token? question;

  /// Initialize a newly created formal parameter. Either or both of the
  /// [comment] and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute. The [keyword] can be `null` if there is a type.
  /// The [type] must be `null` if the keyword is 'var'. The [thisKeyword] and
  /// [period] can be `null` if the keyword 'this' was not provided.  The
  /// [parameters] can be `null` if this is not a function-typed field formal
  /// parameter.
  SuperFormalParameterImpl({
    required super.comment,
    required super.metadata,
    required super.covariantKeyword,
    required super.requiredKeyword,
    required this.keyword,
    required TypeAnnotationImpl? type,
    required this.superKeyword,
    required this.period,
    required super.name,
    required TypeParameterListImpl? typeParameters,
    required FormalParameterListImpl? parameters,
    required this.question,
  })  : _type = type,
        _typeParameters = typeParameters,
        _parameters = parameters {
    _becomeParentOf(_type);
    _becomeParentOf(_typeParameters);
    _becomeParentOf(_parameters);
  }

  @override
  Token get beginToken {
    final metadata = this.metadata;
    if (metadata.isNotEmpty) {
      return metadata.beginToken!;
    } else if (requiredKeyword != null) {
      return requiredKeyword!;
    } else if (covariantKeyword != null) {
      return covariantKeyword!;
    } else if (keyword != null) {
      return keyword!;
    } else if (_type != null) {
      return _type!.beginToken;
    }
    return superKeyword;
  }

  @override
  Token get endToken {
    return question ?? _parameters?.endToken ?? name;
  }

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isExplicitlyTyped => _parameters != null || _type != null;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @override
  Token get name => super.name!;

  @override
  FormalParameterListImpl? get parameters => _parameters;

  set parameters(FormalParameterListImpl? parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @override
  TypeAnnotationImpl? get type => _type;

  set type(TypeAnnotationImpl? type) {
    _type = _becomeParentOf(type as TypeAnnotationImpl);
  }

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('keyword', keyword)
    ..addNode('type', type)
    ..addToken('superKeyword', superKeyword)
    ..addToken('period', period)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addNode('parameters', parameters);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitSuperFormalParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _type?.accept(visitor);
    _typeParameters?.accept(visitor);
    _parameters?.accept(visitor);
  }
}

/// A case in a switch statement.
///
///    switchCase ::=
///        [SimpleIdentifier]* 'case' [Expression] ':' [Statement]*
abstract final class SwitchCase implements SwitchMember {
  /// Return the expression controlling whether the statements will be executed.
  Expression get expression;
}

/// A case in a switch statement.
///
///    switchCase ::=
///        [SimpleIdentifier]* 'case' [Expression] ':' [Statement]*
final class SwitchCaseImpl extends SwitchMemberImpl implements SwitchCase {
  /// The expression controlling whether the statements will be executed.
  ExpressionImpl _expression;

  /// Initialize a newly created switch case. The list of [labels] can be `null`
  /// if there are no labels.
  SwitchCaseImpl({
    required super.labels,
    required super.keyword,
    required ExpressionImpl expression,
    required super.colon,
    required super.statements,
  }) : _expression = expression {
    _becomeParentOf(_expression);
  }

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNodeList('labels', labels)
    ..addToken('keyword', keyword)
    ..addNode('expression', expression)
    ..addToken('colon', colon)
    ..addNodeList('statements', statements);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSwitchCase(this);

  @override
  void visitChildren(AstVisitor visitor) {
    labels.accept(visitor);
    _expression.accept(visitor);
    statements.accept(visitor);
  }
}

/// The default case in a switch statement.
///
///    switchDefault ::=
///        [SimpleIdentifier]* 'default' ':' [Statement]*
abstract final class SwitchDefault implements SwitchMember {}

/// The default case in a switch statement.
///
///    switchDefault ::=
///        [SimpleIdentifier]* 'default' ':' [Statement]*
final class SwitchDefaultImpl extends SwitchMemberImpl
    implements SwitchDefault {
  /// Initialize a newly created switch default. The list of [labels] can be
  /// `null` if there are no labels.
  SwitchDefaultImpl({
    required super.labels,
    required super.keyword,
    required super.colon,
    required super.statements,
  });

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNodeList('labels', labels)
    ..addToken('keyword', keyword)
    ..addToken('colon', colon)
    ..addNodeList('statements', statements);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSwitchDefault(this);

  @override
  void visitChildren(AstVisitor visitor) {
    labels.accept(visitor);
    statements.accept(visitor);
  }
}

/// A switch expression.
///
///    switchExpression ::=
///        'switch' '(' [Expression] ')' '{' [SwitchExpressionCase]
///        (',' [SwitchExpressionCase])* ','? '}'
abstract final class SwitchExpression implements Expression {
  /// Return the cases that can be selected by the expression.
  NodeList<SwitchExpressionCase> get cases;

  /// Return the expression used to determine which of the switch cases will
  /// be selected.
  Expression get expression;

  /// Return the left curly bracket.
  Token get leftBracket;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the right curly bracket.
  Token get rightBracket;

  /// Return the right parenthesis.
  Token get rightParenthesis;

  /// Return the token representing the 'switch' keyword.
  Token get switchKeyword;
}

/// A case in a switch expression.
///
///    switchExpressionCase ::=
///        [GuardedPattern] '=>' [Expression]
abstract final class SwitchExpressionCase implements AstNode {
  /// Return the arrow separating the pattern from the expression.
  Token get arrow;

  /// Return the expression whose value will be returned from the switch
  /// expression if the pattern matches.
  Expression get expression;

  /// Return the refutable pattern that must match for the [expression] to
  /// be executed.
  GuardedPattern get guardedPattern;
}

/// A case in a switch expression.
///
///    switchExpressionCase ::=
///        [GuardedPattern] '=>' [Expression]
final class SwitchExpressionCaseImpl extends AstNodeImpl
    implements SwitchExpressionCase {
  @override
  final GuardedPatternImpl guardedPattern;

  @override
  final Token arrow;

  ExpressionImpl _expression;

  SwitchExpressionCaseImpl({
    required this.guardedPattern,
    required this.arrow,
    required ExpressionImpl expression,
  }) : _expression = expression {
    _becomeParentOf(guardedPattern);
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => guardedPattern.beginToken;

  @override
  Token get endToken => expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('guardedPattern', guardedPattern)
    ..addToken('arrow', arrow)
    ..addNode('expression', expression);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitSwitchExpressionCase(this);

  @override
  void visitChildren(AstVisitor visitor) {
    guardedPattern.accept(visitor);
    expression.accept(visitor);
  }
}

/// A switch expression.
///
///    switchExpression ::=
///        'switch' '(' [Expression] ')' '{' [SwitchExpressionCase]
///        (',' [SwitchExpressionCase])* ','? '}'
final class SwitchExpressionImpl extends ExpressionImpl
    implements SwitchExpression {
  @override
  final Token switchKeyword;

  @override
  final Token leftParenthesis;

  ExpressionImpl _expression;

  @override
  final Token rightParenthesis;

  @override
  final Token leftBracket;

  @override
  final NodeListImpl<SwitchExpressionCaseImpl> cases = NodeListImpl._();

  @override
  final Token rightBracket;

  SwitchExpressionImpl({
    required this.switchKeyword,
    required this.leftParenthesis,
    required ExpressionImpl expression,
    required this.rightParenthesis,
    required this.leftBracket,
    required List<SwitchExpressionCaseImpl> cases,
    required this.rightBracket,
  }) : _expression = expression {
    _becomeParentOf(_expression);
    this.cases._initialize(this, cases);
  }

  @override
  Token get beginToken => switchKeyword;

  @override
  Token get endToken => rightBracket;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.primary;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('switchKeyword', switchKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('expression', expression)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('cases', cases)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSwitchExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    var previousExhaustiveness = resolver.legacySwitchExhaustiveness;
    staticType = resolver
        .analyzeSwitchExpression(this, expression, cases.length, contextType)
        .type;
    resolver.popRewrite();
    resolver.legacySwitchExhaustiveness = previousExhaustiveness;
  }

  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
    cases.accept(visitor);
  }
}

/// An element within a switch statement.
///
///    switchMember ::=
///        [SwitchCase]
///      | [SwitchDefault]
///      | [SwitchPatternCase]
///
/// The class [SwitchPatternCase] exists only to support the 'patterns' feature.
///
/// Note that when the patterns feature is enabled by default, the class
/// [SwitchPatternCase] might replace [SwitchCase] entirely. If we do that, then
/// legacy code (code opted into a version prior to the release of patterns)
/// will likely wrap the expression in a [ConstantPattern] with synthetic
/// tokens.
// TODO(brianwilkerson) Consider renaming `SwitchMember`, `SwitchCase`, and
//  `SwitchDefault` to start with `SwitchStatement` for consistency.
sealed class SwitchMember implements AstNode {
  /// Return the colon separating the keyword or the expression from the
  /// statements.
  Token get colon;

  /// Return the token representing the 'case' or 'default' keyword.
  Token get keyword;

  /// Return the labels associated with the switch member.
  NodeList<Label> get labels;

  /// Return the statements that will be executed if this switch member is
  /// selected.
  NodeList<Statement> get statements;
}

/// An element within a switch statement.
///
///    switchMember ::=
///        switchCase
///      | switchDefault
sealed class SwitchMemberImpl extends AstNodeImpl implements SwitchMember {
  /// The labels associated with the switch member.
  final NodeListImpl<LabelImpl> _labels = NodeListImpl._();

  /// The token representing the 'case' or 'default' keyword.
  @override
  final Token keyword;

  /// The colon separating the keyword or the expression from the statements.
  @override
  final Token colon;

  /// The statements that will be executed if this switch member is selected.
  final NodeListImpl<StatementImpl> _statements = NodeListImpl._();

  /// Initialize a newly created switch member. The list of [labels] can be
  /// `null` if there are no labels.
  SwitchMemberImpl({
    required List<LabelImpl> labels,
    required this.keyword,
    required this.colon,
    required List<StatementImpl> statements,
  }) {
    _labels._initialize(this, labels);
    _statements._initialize(this, statements);
  }

  @override
  Token get beginToken {
    if (_labels.isNotEmpty) {
      return _labels.beginToken!;
    }
    return keyword;
  }

  @override
  Token get endToken {
    if (_statements.isNotEmpty) {
      return _statements.endToken!;
    }
    return colon;
  }

  @override
  NodeListImpl<LabelImpl> get labels => _labels;

  @override
  NodeListImpl<StatementImpl> get statements => _statements;
}

/// A pattern-based case in a switch statement.
///
///    switchPatternCase ::=
///        [Label]* 'case' [DartPattern] [WhenClause]? ':' [Statement]*
abstract final class SwitchPatternCase implements SwitchMember {
  /// Return the pattern controlling whether the statements will be executed.
  GuardedPattern get guardedPattern;
}

/// A pattern-based case in a switch statement.
///
///    switchPatternCase ::=
///        [Label]* 'case' [DartPattern] [WhenClause]? ':' [Statement]*
final class SwitchPatternCaseImpl extends SwitchMemberImpl
    implements SwitchPatternCase {
  @override
  final GuardedPatternImpl guardedPattern;

  SwitchPatternCaseImpl({
    required super.labels,
    required super.keyword,
    required this.guardedPattern,
    required super.colon,
    required super.statements,
  }) {
    _becomeParentOf(guardedPattern);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNodeList('labels', labels)
    ..addToken('keyword', keyword)
    ..addNode('guardedPattern', guardedPattern)
    ..addToken('colon', colon)
    ..addNodeList('statements', statements);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSwitchPatternCase(this);

  @override
  void visitChildren(AstVisitor visitor) {
    labels.accept(visitor);
    guardedPattern.accept(visitor);
    statements.accept(visitor);
  }
}

/// A switch statement.
///
///    switchStatement ::=
///        'switch' '(' [Expression] ')' '{' [SwitchCase]* [SwitchDefault]? '}'
abstract final class SwitchStatement implements Statement {
  /// Return the expression used to determine which of the switch members will
  /// be selected.
  Expression get expression;

  /// Return the left curly bracket.
  Token get leftBracket;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the switch members that can be selected by the expression.
  NodeList<SwitchMember> get members;

  /// Return the right curly bracket.
  Token get rightBracket;

  /// Return the right parenthesis.
  Token get rightParenthesis;

  /// Return the token representing the 'switch' keyword.
  Token get switchKeyword;
}

class SwitchStatementCaseGroup {
  final List<SwitchMemberImpl> members;
  final bool hasLabels;

  /// Joined variables declared in [members], available in [statements].
  late Map<String, PromotableElement> variables;

  SwitchStatementCaseGroup(this.members, this.hasLabels);

  NodeListImpl<StatementImpl> get statements {
    return members.last.statements;
  }
}

/// A switch statement.
///
///    switchStatement ::=
///        'switch' '(' [Expression] ')' '{' [SwitchCase]* [SwitchDefault]? '}'
final class SwitchStatementImpl extends StatementImpl
    implements SwitchStatement {
  /// The token representing the 'switch' keyword.
  @override
  final Token switchKeyword;

  /// The left parenthesis.
  @override
  final Token leftParenthesis;

  /// The expression used to determine which of the switch members will be
  /// selected.
  ExpressionImpl _expression;

  /// The right parenthesis.
  @override
  final Token rightParenthesis;

  /// The left curly bracket.
  @override
  final Token leftBracket;

  /// The switch members that can be selected by the expression.
  final NodeListImpl<SwitchMemberImpl> _members = NodeListImpl._();

  late final List<SwitchStatementCaseGroup> memberGroups =
      _computeMemberGroups();

  /// The right curly bracket.
  @override
  final Token rightBracket;

  /// Initialize a newly created switch statement. The list of [members] can be
  /// `null` if there are no switch members.
  SwitchStatementImpl({
    required this.switchKeyword,
    required this.leftParenthesis,
    required ExpressionImpl expression,
    required this.rightParenthesis,
    required this.leftBracket,
    required List<SwitchMemberImpl> members,
    required this.rightBracket,
  }) : _expression = expression {
    _becomeParentOf(_expression);
    _members._initialize(this, members);
  }

  @override
  Token get beginToken => switchKeyword;

  @override
  Token get endToken => rightBracket;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  NodeListImpl<SwitchMemberImpl> get members => _members;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('switchKeyword', switchKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('expression', expression)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('members', members)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSwitchStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
    _members.accept(visitor);
  }

  List<SwitchStatementCaseGroup> _computeMemberGroups() {
    var groups = <SwitchStatementCaseGroup>[];
    var groupMembers = <SwitchMemberImpl>[];
    var groupHasLabels = false;
    for (var member in members) {
      groupMembers.add(member);
      groupHasLabels |= member.labels.isNotEmpty;
      if (member.statements.isNotEmpty) {
        groups.add(
          SwitchStatementCaseGroup(groupMembers, groupHasLabels),
        );
        groupMembers = [];
        groupHasLabels = false;
      }
    }
    if (groupMembers.isNotEmpty) {
      groups.add(
        SwitchStatementCaseGroup(groupMembers, groupHasLabels),
      );
    }
    return groups;
  }
}

/// A symbol literal expression.
///
///    symbolLiteral ::=
///        '#' (operator | (identifier ('.' identifier)*))
abstract final class SymbolLiteral implements Literal {
  /// Return the components of the literal.
  List<Token> get components;

  /// Return the token introducing the literal.
  Token get poundSign;
}

/// A symbol literal expression.
///
///    symbolLiteral ::=
///        '#' (operator | (identifier ('.' identifier)*))
final class SymbolLiteralImpl extends LiteralImpl implements SymbolLiteral {
  /// The token introducing the literal.
  @override
  final Token poundSign;

  /// The components of the literal.
  @override
  final List<Token> components;

  /// Initialize a newly created symbol literal.
  SymbolLiteralImpl({
    required this.poundSign,
    required this.components,
  });

  @override
  Token get beginToken => poundSign;

  @override
  Token get endToken => components[components.length - 1];

  @override
  // TODO(paulberry): add "." tokens.
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('poundSign', poundSign)
    ..addTokenList('components', components);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSymbolLiteral(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitSymbolLiteral(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// An identifier that can be used to look up names in the lexical scope when
/// there is no identifier in the AST structure. There is no identifier in the
/// AST when the parser could not distinguish between a method invocation and an
/// invocation of a top-level function imported with a prefix.
final class SyntheticIdentifier implements SimpleIdentifier {
  @override
  final String name;

  SyntheticIdentifier(this.name);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A this expression.
///
///    thisExpression ::=
///        'this'
abstract final class ThisExpression implements Expression {
  /// Return the token representing the 'this' keyword.
  Token get thisKeyword;
}

/// A this expression.
///
///    thisExpression ::=
///        'this'
final class ThisExpressionImpl extends ExpressionImpl
    implements ThisExpression {
  /// The token representing the 'this' keyword.
  @override
  final Token thisKeyword;

  /// Initialize a newly created this expression.
  ThisExpressionImpl({
    required this.thisKeyword,
  });

  @override
  Token get beginToken => thisKeyword;

  @override
  Token get endToken => thisKeyword;

  @override
  Precedence get precedence => Precedence.primary;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('thisKeyword', thisKeyword);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitThisExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitThisExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// A throw expression.
///
///    throwExpression ::=
///        'throw' [Expression]
abstract final class ThrowExpression implements Expression {
  /// Return the expression computing the exception to be thrown.
  Expression get expression;

  /// Return the token representing the 'throw' keyword.
  Token get throwKeyword;
}

/// A throw expression.
///
///    throwExpression ::=
///        'throw' [Expression]
final class ThrowExpressionImpl extends ExpressionImpl
    implements ThrowExpression {
  /// The token representing the 'throw' keyword.
  @override
  final Token throwKeyword;

  /// The expression computing the exception to be thrown.
  ExpressionImpl _expression;

  /// Initialize a newly created throw expression.
  ThrowExpressionImpl({
    required this.throwKeyword,
    required ExpressionImpl expression,
  }) : _expression = expression {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken => throwKeyword;

  @override
  Token get endToken {
    return _expression.endToken;
  }

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.assignment;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('throwKeyword', throwKeyword)
    ..addNode('expression', expression);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitThrowExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitThrowExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
  }
}

/// The declaration of one or more top-level variables of the same type.
///
///    topLevelVariableDeclaration ::=
///        ('final' | 'const') <type>? <staticFinalDeclarationList> ';'
///      | 'late' 'final' <type>? <initializedIdentifierList> ';'
///      | 'late'? <varOrType> <initializedIdentifierList> ';'
///      | 'external' <finalVarOrType> <identifierList> ';'
///
/// (Note: there is no <topLevelVariableDeclaration> production in the grammar;
/// this is a subset of the grammar production <topLevelDeclaration>, which
/// encompasses everything that can appear inside a Dart file after part
/// directives).
abstract final class TopLevelVariableDeclaration
    implements CompilationUnitMember {
  /// The `external` keyword, or `null` if the keyword was not used.
  Token? get externalKeyword;

  /// Return the semicolon terminating the declaration.
  Token get semicolon;

  /// Return the top-level variables being declared.
  VariableDeclarationList get variables;
}

/// The declaration of one or more top-level variables of the same type.
///
///    topLevelVariableDeclaration ::=
///        ('final' | 'const') type? staticFinalDeclarationList ';'
///      | variableDeclaration ';'
final class TopLevelVariableDeclarationImpl extends CompilationUnitMemberImpl
    implements TopLevelVariableDeclaration {
  /// The top-level variables being declared.
  VariableDeclarationListImpl _variableList;

  @override
  final Token? externalKeyword;

  /// The semicolon terminating the declaration.
  @override
  final Token semicolon;

  /// Initialize a newly created top-level variable declaration. Either or both
  /// of the [comment] and [metadata] can be `null` if the variable does not
  /// have the corresponding attribute.
  TopLevelVariableDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.externalKeyword,
    required VariableDeclarationListImpl variableList,
    required this.semicolon,
  }) : _variableList = variableList {
    _becomeParentOf(_variableList);
  }

  @override
  Element? get declaredElement => null;

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata =>
      externalKeyword ?? _variableList.beginToken;

  @override
  VariableDeclarationListImpl get variables => _variableList;

  set variables(VariableDeclarationListImpl variables) {
    _variableList = _becomeParentOf(variables);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('variables', variables)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitTopLevelVariableDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _variableList.accept(visitor);
  }
}

/// A try statement.
///
///    tryStatement ::=
///        'try' [Block] ([CatchClause]+ finallyClause? | finallyClause)
///
///    finallyClause ::=
///        'finally' [Block]
abstract final class TryStatement implements Statement {
  /// Return the body of the statement.
  Block get body;

  /// Return the catch clauses contained in the try statement.
  NodeList<CatchClause> get catchClauses;

  /// Return the finally block contained in the try statement, or `null` if the
  /// statement does not contain a finally clause.
  Block? get finallyBlock;

  /// Return the token representing the 'finally' keyword, or `null` if the
  /// statement does not contain a finally clause.
  Token? get finallyKeyword;

  /// Return the token representing the 'try' keyword.
  Token get tryKeyword;
}

/// A try statement.
///
///    tryStatement ::=
///        'try' [Block] ([CatchClause]+ finallyClause? | finallyClause)
///
///    finallyClause ::=
///        'finally' [Block]
final class TryStatementImpl extends StatementImpl implements TryStatement {
  /// The token representing the 'try' keyword.
  @override
  final Token tryKeyword;

  /// The body of the statement.
  BlockImpl _body;

  /// The catch clauses contained in the try statement.
  final NodeListImpl<CatchClauseImpl> _catchClauses = NodeListImpl._();

  /// The token representing the 'finally' keyword, or `null` if the statement
  /// does not contain a finally clause.
  @override
  final Token? finallyKeyword;

  /// The finally block contained in the try statement, or `null` if the
  /// statement does not contain a finally clause.
  BlockImpl? _finallyBlock;

  /// Initialize a newly created try statement. The list of [catchClauses] can
  /// be`null` if there are no catch clauses. The [finallyKeyword] and
  /// [finallyBlock] can be `null` if there is no finally clause.
  TryStatementImpl({
    required this.tryKeyword,
    required BlockImpl body,
    required List<CatchClauseImpl> catchClauses,
    required this.finallyKeyword,
    required BlockImpl? finallyBlock,
  })  : _body = body,
        _finallyBlock = finallyBlock {
    _becomeParentOf(_body);
    _catchClauses._initialize(this, catchClauses);
    _becomeParentOf(_finallyBlock);
  }

  @override
  Token get beginToken => tryKeyword;

  @override
  BlockImpl get body => _body;

  set body(BlockImpl block) {
    _body = _becomeParentOf(block);
  }

  @override
  NodeListImpl<CatchClauseImpl> get catchClauses => _catchClauses;

  @override
  Token get endToken {
    if (_finallyBlock != null) {
      return _finallyBlock!.endToken;
    } else if (finallyKeyword != null) {
      return finallyKeyword!;
    } else if (_catchClauses.isNotEmpty) {
      return _catchClauses.endToken!;
    }
    return _body.endToken;
  }

  @override
  BlockImpl? get finallyBlock => _finallyBlock;

  set finallyBlock(BlockImpl? block) {
    _finallyBlock = _becomeParentOf(block);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('tryKeyword', tryKeyword)
    ..addNode('body', body)
    ..addNodeList('catchClauses', catchClauses)
    ..addToken('finallyKeyword', finallyKeyword)
    ..addNode('finallyBlock', finallyBlock);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitTryStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _body.accept(visitor);
    _catchClauses.accept(visitor);
    _finallyBlock?.accept(visitor);
  }
}

/// The declaration of a type alias.
///
///    typeAlias ::=
///        [ClassTypeAlias]
///      | [FunctionTypeAlias]
///      | [GenericTypeAlias]
abstract final class TypeAlias implements NamedCompilationUnitMember {
  /// Return the semicolon terminating the declaration.
  Token get semicolon;

  /// Return the token representing the 'typedef' or 'class' keyword.
  Token get typedefKeyword;
}

/// The declaration of a type alias.
///
///    typeAlias ::=
///        [ClassTypeAlias]
///      | [FunctionTypeAlias]
///      | [GenericTypeAlias]
sealed class TypeAliasImpl extends NamedCompilationUnitMemberImpl
    implements TypeAlias {
  /// The token representing the 'typedef' or 'class' keyword.
  @override
  final Token typedefKeyword;

  /// The semicolon terminating the declaration.
  @override
  final Token semicolon;

  /// Initialize a newly created type alias. Either or both of the [comment] and
  /// [metadata] can be `null` if the declaration does not have the
  /// corresponding attribute.
  TypeAliasImpl({
    required super.comment,
    required super.metadata,
    required this.typedefKeyword,
    required super.name,
    required this.semicolon,
  });

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
///      | [RecordTypeAnnotation]
sealed class TypeAnnotation implements AstNode {
  /// The question mark indicating that the type is nullable, or `null` if there
  /// is no question mark.
  Token? get question;

  /// Return the type being named, or `null` if the AST structure has not been
  /// resolved.
  DartType? get type;
}

/// A type annotation.
///
///    type ::=
///        [NamedType]
///      | [GenericFunctionType]
sealed class TypeAnnotationImpl extends AstNodeImpl implements TypeAnnotation {}

/// A list of type arguments.
///
///    typeArguments ::=
///        '<' typeName (',' typeName)* '>'
abstract final class TypeArgumentList implements AstNode {
  /// Return the type arguments associated with the type.
  NodeList<TypeAnnotation> get arguments;

  /// Return the left bracket.
  Token get leftBracket;

  /// Return the right bracket.
  Token get rightBracket;
}

/// A list of type arguments.
///
///    typeArguments ::=
///        '<' typeName (',' typeName)* '>'
final class TypeArgumentListImpl extends AstNodeImpl
    implements TypeArgumentList {
  /// The left bracket.
  @override
  final Token leftBracket;

  /// The type arguments associated with the type.
  final NodeListImpl<TypeAnnotationImpl> _arguments = NodeListImpl._();

  /// The right bracket.
  @override
  final Token rightBracket;

  /// Initialize a newly created list of type arguments.
  TypeArgumentListImpl({
    required this.leftBracket,
    required List<TypeAnnotationImpl> arguments,
    required this.rightBracket,
  }) {
    _arguments._initialize(this, arguments);
  }

  @override
  NodeListImpl<TypeAnnotationImpl> get arguments => _arguments;

  @override
  Token get beginToken => leftBracket;

  @override
  Token get endToken => rightBracket;

  @override
  // TODO(paulberry): Add commas.
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('arguments', arguments)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitTypeArgumentList(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _arguments.accept(visitor);
  }
}

/// A literal that has a type associated with it.
///
///    typedLiteral ::=
///        [ListLiteral]
///      | [SetOrMapLiteral]
sealed class TypedLiteral implements Literal {
  /// Return the token representing the 'const' keyword, or `null` if the
  /// literal is not a constant.
  Token? get constKeyword;

  /// Return `true` if this literal is a constant expression, either because the
  /// keyword `const` was explicitly provided or because no keyword was provided
  /// and this expression is in a constant context.
  bool get isConst;

  /// Return the type argument associated with this literal, or `null` if no
  /// type arguments were declared.
  TypeArgumentList? get typeArguments;
}

/// A literal that has a type associated with it.
///
///    typedLiteral ::=
///        [ListLiteral]
///      | [MapLiteral]
sealed class TypedLiteralImpl extends LiteralImpl implements TypedLiteral {
  /// The token representing the 'const' keyword, or `null` if the literal is
  /// not a constant.
  @override
  Token? constKeyword;

  /// The type argument associated with this literal, or `null` if no type
  /// arguments were declared.
  TypeArgumentListImpl? _typeArguments;

  /// Initialize a newly created typed literal. The [constKeyword] can be
  /// `null` if the literal is not a constant. The [typeArguments] can be `null`
  /// if no type arguments were declared.
  TypedLiteralImpl({
    required this.constKeyword,
    required TypeArgumentListImpl? typeArguments,
  }) : _typeArguments = typeArguments {
    _becomeParentOf(_typeArguments);
  }

  @override
  bool get isConst {
    return constKeyword != null || inConstantContext;
  }

  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  set typeArguments(TypeArgumentListImpl? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('constKeyword', constKeyword)
    ..addNode('typeArguments', typeArguments);

  @override
  void visitChildren(AstVisitor visitor) {
    _typeArguments?.accept(visitor);
  }
}

/// An expression representing a type, e.g. the expression `int` in
/// `var x = int;`.
///
/// Objects of this type are not produced directly by the parser (because the
/// parser cannot tell whether an identifier refers to a type); they are
/// produced at resolution time.
///
/// The `.staticType` getter returns the type of the expression (which will
/// always be the type `Type`).  To see the type represented by the type literal
/// use `.typeName.type`.
abstract final class TypeLiteral
    implements Expression, CommentReferableExpression {
  /// The type represented by this literal.
  NamedType get type;
}

/// An expression representing a type, e.g. the expression `int` in
/// `var x = int;`.
///
/// Objects of this type are not produced directly by the parser (because the
/// parser cannot tell whether an identifier refers to a type); they are
/// produced at resolution time.
///
/// The `.staticType` getter returns the type of the expression (which will
/// always be the type `Type`).  To see the type represented by the type literal
/// use `.typeName.type`.
final class TypeLiteralImpl extends CommentReferableExpressionImpl
    implements TypeLiteral {
  NamedTypeImpl _typeName;

  TypeLiteralImpl({
    required NamedTypeImpl typeName,
  }) : _typeName = typeName {
    _becomeParentOf(_typeName);
  }

  @override
  Token get beginToken => _typeName.beginToken;

  @override
  Token get endToken => _typeName.endToken;

  @override
  Precedence get precedence {
    if (_typeName.typeArguments != null) {
      return Precedence.postfix;
    } else if (_typeName.importPrefix != null) {
      return Precedence.postfix;
    } else {
      return Precedence.primary;
    }
  }

  @override
  NamedTypeImpl get type => _typeName;

  set typeName(NamedTypeImpl value) {
    _typeName = _becomeParentOf(value);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()..addNode('type', type);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitTypeLiteral(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitTypeLiteral(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _typeName.accept(visitor);
  }
}

/// A type parameter.
///
///    typeParameter ::=
///        name ('extends' [TypeAnnotation])?
abstract final class TypeParameter implements Declaration {
  /// Return the upper bound for legal arguments, or `null` if there is no
  /// explicit upper bound.
  TypeAnnotation? get bound;

  @override
  TypeParameterElement? get declaredElement;

  /// Return the token representing the 'extends' keyword, or `null` if there is
  /// no explicit upper bound.
  Token? get extendsKeyword;

  /// Return the name of the type parameter.
  Token get name;
}

/// A type parameter.
///
///    typeParameter ::=
///        typeParameterVariance? [SimpleIdentifier] ('extends' [NamedType])?
///
///    typeParameterVariance ::= 'out' | 'inout' | 'in'
final class TypeParameterImpl extends DeclarationImpl implements TypeParameter {
  @override
  final Token name;

  /// The token representing the variance modifier keyword, or `null` if
  /// there is no explicit variance modifier, meaning legacy covariance.
  Token? varianceKeyword;

  /// The token representing the 'extends' keyword, or `null` if there is no
  /// explicit upper bound.
  @override
  Token? extendsKeyword;

  /// The name of the upper bound for legal arguments, or `null` if there is no
  /// explicit upper bound.
  TypeAnnotationImpl? _bound;

  @override
  TypeParameterElementImpl? declaredElement;

  /// Initialize a newly created type parameter. Either or both of the [comment]
  /// and [metadata] can be `null` if the parameter does not have the
  /// corresponding attribute. The [extendsKeyword] and [bound] can be `null` if
  /// the parameter does not have an upper bound.
  TypeParameterImpl({
    required super.comment,
    required super.metadata,
    required this.name,
    required this.extendsKeyword,
    required TypeAnnotationImpl? bound,
    this.varianceKeyword,
  }) : _bound = bound {
    _becomeParentOf(_bound);
  }

  @override
  TypeAnnotationImpl? get bound => _bound;

  set bound(TypeAnnotationImpl? type) {
    _bound = _becomeParentOf(type);
  }

  @override
  Token get endToken {
    return _bound?.endToken ?? name;
  }

  @override
  Token get firstTokenAfterCommentAndMetadata => varianceKeyword ?? name;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('name', name)
    ..addToken('extendsKeyword', extendsKeyword)
    ..addNode('bound', bound);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitTypeParameter(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _bound?.accept(visitor);
  }
}

/// Type parameters within a declaration.
///
///    typeParameterList ::=
///        '<' [TypeParameter] (',' [TypeParameter])* '>'
abstract final class TypeParameterList implements AstNode {
  /// Return the left angle bracket.
  Token get leftBracket;

  /// Return the right angle bracket.
  Token get rightBracket;

  /// Return the type parameters for the type.
  NodeList<TypeParameter> get typeParameters;
}

/// Type parameters within a declaration.
///
///    typeParameterList ::=
///        '<' [TypeParameter] (',' [TypeParameter])* '>'
final class TypeParameterListImpl extends AstNodeImpl
    implements TypeParameterList {
  /// The left angle bracket.
  @override
  final Token leftBracket;

  /// The type parameters in the list.
  final NodeListImpl<TypeParameterImpl> _typeParameters = NodeListImpl._();

  /// The right angle bracket.
  @override
  final Token rightBracket;

  /// Initialize a newly created list of type parameters.
  TypeParameterListImpl({
    required this.leftBracket,
    required List<TypeParameterImpl> typeParameters,
    required this.rightBracket,
  }) {
    _typeParameters._initialize(this, typeParameters);
  }

  @override
  Token get beginToken => leftBracket;

  @override
  Token get endToken => rightBracket;

  @override
  NodeListImpl<TypeParameterImpl> get typeParameters => _typeParameters;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('typeParameters', typeParameters)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitTypeParameterList(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _typeParameters.accept(visitor);
  }
}

/// A directive that references a URI.
///
///    uriBasedDirective ::=
///        [LibraryAugmentationDirective]
///        [ExportDirective]
///      | [ImportDirective]
///      | [PartDirective]
sealed class UriBasedDirective implements Directive {
  /// Return the URI referenced by this directive.
  StringLiteral get uri;
}

/// A directive that references a URI.
///
///    uriBasedDirective ::=
///        [ExportDirective]
///      | [ImportDirective]
///      | [PartDirective]
sealed class UriBasedDirectiveImpl extends DirectiveImpl
    implements UriBasedDirective {
  /// The URI referenced by this directive.
  StringLiteralImpl _uri;

  /// Initialize a newly create URI-based directive. Either or both of the
  /// [comment] and [metadata] can be `null` if the directive does not have the
  /// corresponding attribute.
  UriBasedDirectiveImpl({
    required super.comment,
    required super.metadata,
    required StringLiteralImpl uri,
  }) : _uri = uri {
    _becomeParentOf(_uri);
  }

  @override
  StringLiteralImpl get uri => _uri;

  set uri(StringLiteralImpl uri) {
    _uri = _becomeParentOf(uri);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _uri.accept(visitor);
  }

  /// Validate this directive, but do not check for existence. Return a code
  /// indicating the problem if there is one, or `null` no problem.
  static UriValidationCode? validateUri(
      bool isImport, StringLiteral uriLiteral, String? uriContent) {
    if (uriLiteral is StringInterpolation) {
      return UriValidationCode.URI_WITH_INTERPOLATION;
    }
    if (uriContent == null) {
      return UriValidationCode.INVALID_URI;
    }
    if (uriContent.isEmpty) {
      return null;
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

  /// The name of the validation code.
  final String name;

  /// Initialize a newly created validation code to have the given [name].
  const UriValidationCode(this.name);

  @override
  String toString() => name;
}

/// An identifier that has an initial value associated with it.
///
/// Instances of this class are always children of the class
/// [VariableDeclarationList].
///
///    variableDeclaration ::=
///        name ('=' [Expression])?
// TODO(paulberry): the grammar does not allow metadata to be associated with a
// VariableDeclaration, and currently we don't record comments for it either.
// Consider changing the class hierarchy so that [VariableDeclaration] does not
// extend [Declaration].
abstract final class VariableDeclaration implements Declaration {
  @override
  VariableElement? get declaredElement;

  /// Return the equal sign separating the variable name from the initial value,
  /// or `null` if the initial value was not specified.
  Token? get equals;

  /// Return the expression used to compute the initial value for the variable,
  /// or `null` if the initial value was not specified.
  Expression? get initializer;

  /// Return `true` if this variable was declared with the 'const' modifier.
  bool get isConst;

  /// Return `true` if this variable was declared with the 'final' modifier.
  ///
  /// Variables that are declared with the 'const' modifier will return `false`
  /// even though they are implicitly final.
  bool get isFinal;

  /// Return `true` if this variable was declared with the 'late' modifier.
  bool get isLate;

  /// Return the name of the variable being declared.
  Token get name;
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
final class VariableDeclarationImpl extends DeclarationImpl
    implements VariableDeclaration {
  @override
  final Token name;

  @override
  VariableElementImpl? declaredElement;

  /// The equal sign separating the variable name from the initial value, or
  /// `null` if the initial value was not specified.
  @override
  final Token? equals;

  /// The expression used to compute the initial value for the variable, or
  /// `null` if the initial value was not specified.
  ExpressionImpl? _initializer;

  /// When this node is read as a part of summaries, we usually don't want
  /// to read the [initializer], but we need to know if there is one in
  /// the code. So, this flag might be set to `true` even though
  /// [initializer] is `null`.
  bool hasInitializer = false;

  /// Initialize a newly created variable declaration. The [equals] and
  /// [initializer] can be `null` if there is no initializer.
  VariableDeclarationImpl({
    required this.name,
    required this.equals,
    required ExpressionImpl? initializer,
  })  : _initializer = initializer,
        super(comment: null, metadata: null) {
    _becomeParentOf(_initializer);
  }

  /// This overridden implementation of [documentationComment] looks in the
  /// grandparent node for Dartdoc comments if no documentation is specifically
  /// available on the node.
  @override
  CommentImpl? get documentationComment {
    var comment = super.documentationComment;
    if (comment == null) {
      var node = parent?.parent;
      if (node is AnnotatedNodeImpl) {
        return node.documentationComment;
      }
    }
    return comment;
  }

  @override
  Token get endToken {
    if (_initializer != null) {
      return _initializer!.endToken;
    }
    return name;
  }

  @override
  Token get firstTokenAfterCommentAndMetadata => name;

  @override
  ExpressionImpl? get initializer => _initializer;

  set initializer(ExpressionImpl? expression) {
    _initializer = _becomeParentOf(expression);
  }

  @override
  bool get isConst {
    final parent = this.parent;
    return parent is VariableDeclarationList && parent.isConst;
  }

  @override
  bool get isFinal {
    final parent = this.parent;
    return parent is VariableDeclarationList && parent.isFinal;
  }

  @override
  bool get isLate {
    final parent = this.parent;
    return parent is VariableDeclarationList && parent.isLate;
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('name', name)
    ..addToken('equals', equals)
    ..addNode('initializer', initializer);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitVariableDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    _initializer?.accept(visitor);
  }
}

/// The declaration of one or more variables of the same type.
///
///    variableDeclarationList ::=
///        finalConstVarOrType [VariableDeclaration] (',' [VariableDeclaration])*
///
///    finalConstVarOrType ::=
///      'final' 'late'? [TypeAnnotation]?
///      | 'const' [TypeAnnotation]?
///      | 'var'
///      | 'late'? [TypeAnnotation]
abstract final class VariableDeclarationList implements AnnotatedNode {
  /// Return `true` if the variables in this list were declared with the 'const'
  /// modifier.
  bool get isConst;

  /// Return `true` if the variables in this list were declared with the 'final'
  /// modifier.
  ///
  /// Variables that are declared with the 'const' modifier will return `false`
  /// even though they are implicitly final. (In other words, this is a
  /// syntactic check rather than a semantic check.)
  bool get isFinal;

  /// Return `true` if the variables in this list were declared with the 'late'
  /// modifier.
  bool get isLate;

  /// Return the token representing the 'final', 'const' or 'var' keyword, or
  /// `null` if no keyword was included.
  Token? get keyword;

  /// Return the token representing the 'late' keyword, or `null` if the late
  /// modifier was not included.
  Token? get lateKeyword;

  /// Return the type of the variables being declared, or `null` if no type was
  /// provided.
  TypeAnnotation? get type;

  /// Return a list containing the individual variables being declared.
  NodeList<VariableDeclaration> get variables;
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
final class VariableDeclarationListImpl extends AnnotatedNodeImpl
    implements VariableDeclarationList {
  /// The token representing the 'final', 'const' or 'var' keyword, or `null` if
  /// no keyword was included.
  @override
  final Token? keyword;

  /// The token representing the 'late' keyword, or `null` if the late modifier
  /// was not included.
  @override
  final Token? lateKeyword;

  /// The type of the variables being declared, or `null` if no type was
  /// provided.
  TypeAnnotationImpl? _type;

  /// A list containing the individual variables being declared.
  final NodeListImpl<VariableDeclarationImpl> _variables = NodeListImpl._();

  /// Initialize a newly created variable declaration list. Either or both of
  /// the [comment] and [metadata] can be `null` if the variable list does not
  /// have the corresponding attribute. The [keyword] can be `null` if a type
  /// was specified. The [type] must be `null` if the keyword is 'var'.
  VariableDeclarationListImpl({
    required super.comment,
    required super.metadata,
    required this.lateKeyword,
    required this.keyword,
    required TypeAnnotationImpl? type,
    required List<VariableDeclarationImpl> variables,
  }) : _type = type {
    _becomeParentOf(_type);
    _variables._initialize(this, variables);
  }

  @override
  Token get endToken => _variables.endToken!;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return Token.lexicallyFirst(lateKeyword, keyword) ??
        _type?.beginToken ??
        _variables.beginToken!;
  }

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @override
  bool get isLate => lateKeyword != null;

  @override
  TypeAnnotationImpl? get type => _type;

  set type(TypeAnnotationImpl? type) {
    _type = _becomeParentOf(type);
  }

  @override
  NodeListImpl<VariableDeclarationImpl> get variables => _variables;

  @override
  // TODO(paulberry): include commas.
  ChildEntities get _childEntities => super._childEntities
    ..addToken('lateKeyword', lateKeyword)
    ..addToken('keyword', keyword)
    ..addNode('type', type)
    ..addNodeList('variables', variables);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
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
abstract final class VariableDeclarationStatement implements Statement {
  /// Return the semicolon terminating the statement.
  Token get semicolon;

  /// Return the variables being declared.
  VariableDeclarationList get variables;
}

/// A list of variables that are being declared in a context where a statement
/// is required.
///
///    variableDeclarationStatement ::=
///        [VariableDeclarationList] ';'
final class VariableDeclarationStatementImpl extends StatementImpl
    implements VariableDeclarationStatement {
  /// The variables being declared.
  VariableDeclarationListImpl _variableList;

  /// The semicolon terminating the statement.
  @override
  final Token semicolon;

  /// Initialize a newly created variable declaration statement.
  VariableDeclarationStatementImpl({
    required VariableDeclarationListImpl variableList,
    required this.semicolon,
  }) : _variableList = variableList {
    _becomeParentOf(_variableList);
  }

  @override
  Token get beginToken => _variableList.beginToken;

  @override
  Token get endToken => semicolon;

  @override
  VariableDeclarationListImpl get variables => _variableList;

  set variables(VariableDeclarationListImpl variables) {
    _variableList = _becomeParentOf(variables);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('variables', variables)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitVariableDeclarationStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _variableList.accept(visitor);
  }
}

/// The shared interface of [AssignedVariablePattern] and
/// [DeclaredVariablePattern].
sealed class VariablePattern implements DartPattern {
  /// The name of the variable declared or referenced by the pattern.
  Token get name;
}

sealed class VariablePatternImpl extends DartPatternImpl
    implements VariablePattern {
  @override
  final Token name;

  /// If this variable was used to resolve an implicitly named field, the
  /// implicit name node is recorded here for a future use.
  PatternFieldNameImpl? fieldNameWithImplicitName;

  VariablePatternImpl({
    required this.name,
  });

  @override
  VariablePatternImpl? get variablePattern => this;
}

/// A guard in a pattern-based `case` in a `switch` statement, `switch`
/// expression, `if` statement, or `if` element.
///
///    switchCase ::=
///        'when' [Expression]
abstract final class WhenClause implements AstNode {
  /// Return the condition that is evaluated when the [pattern] matches, that
  /// must evaluate to `true` in order for the [expression] to be executed.
  Expression get expression;

  /// Return the `when` keyword.
  Token get whenKeyword;
}

/// A guard in a pattern-based `case` in a `switch` statement or `switch`
/// expression.
///
///    switchCase ::=
///        'when' [Expression]
final class WhenClauseImpl extends AstNodeImpl implements WhenClause {
  ExpressionImpl _expression;

  @override
  final Token whenKeyword;

  WhenClauseImpl({
    required this.whenKeyword,
    required ExpressionImpl expression,
  }) : _expression = expression {
    _becomeParentOf(expression);
  }

  @override
  Token get beginToken => whenKeyword;

  @override
  Token get endToken => expression.endToken;

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('whenKeyword', whenKeyword)
    ..addNode('expression', expression);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitWhenClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
  }
}

/// A while statement.
///
///    whileStatement ::=
///        'while' '(' [Expression] ')' [Statement]
abstract final class WhileStatement implements Statement {
  /// Return the body of the loop.
  Statement get body;

  /// Return the expression used to determine whether to execute the body of the
  /// loop.
  Expression get condition;

  /// Return the left parenthesis.
  Token get leftParenthesis;

  /// Return the right parenthesis.
  Token get rightParenthesis;

  /// Return the token representing the 'while' keyword.
  Token get whileKeyword;
}

/// A while statement.
///
///    whileStatement ::=
///        'while' '(' [Expression] ')' [Statement]
final class WhileStatementImpl extends StatementImpl implements WhileStatement {
  /// The token representing the 'while' keyword.
  @override
  final Token whileKeyword;

  /// The left parenthesis.
  @override
  final Token leftParenthesis;

  /// The expression used to determine whether to execute the body of the loop.
  ExpressionImpl _condition;

  /// The right parenthesis.
  @override
  final Token rightParenthesis;

  /// The body of the loop.
  StatementImpl _body;

  /// Initialize a newly created while statement.
  WhileStatementImpl({
    required this.whileKeyword,
    required this.leftParenthesis,
    required ExpressionImpl condition,
    required this.rightParenthesis,
    required StatementImpl body,
  })  : _condition = condition,
        _body = body {
    _becomeParentOf(_condition);
    _becomeParentOf(_body);
  }

  @override
  Token get beginToken => whileKeyword;

  @override
  StatementImpl get body => _body;

  set body(StatementImpl statement) {
    _body = _becomeParentOf(statement);
  }

  @override
  ExpressionImpl get condition => _condition;

  set condition(ExpressionImpl expression) {
    _condition = _becomeParentOf(expression);
  }

  @override
  Token get endToken => _body.endToken;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('whileKeyword', whileKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('condition', condition)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addNode('body', body);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitWhileStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _condition.accept(visitor);
    _body.accept(visitor);
  }
}

/// A wildcard pattern.
///
///    wildcardPattern ::=
///        ( 'var' | 'final' | 'final'? [TypeAnnotation])? '_'
abstract final class WildcardPattern implements DartPattern {
  /// The 'var' or 'final' keyword.
  Token? get keyword;

  /// The `_` token.
  Token get name;

  /// The type that the pattern is required to match, or `null` if any type is
  /// matched.
  TypeAnnotation? get type;
}

/// A wildcard pattern.
///
///    variablePattern ::=
///        ( 'var' | 'final' | 'final'? [TypeAnnotation])? '_'
final class WildcardPatternImpl extends DartPatternImpl
    implements WildcardPattern {
  @override
  final Token? keyword;

  @override
  final Token name;

  @override
  final TypeAnnotationImpl? type;

  WildcardPatternImpl({
    required this.name,
    required this.keyword,
    required this.type,
  }) {
    _becomeParentOf(type);
  }

  @override
  Token get beginToken => type?.beginToken ?? name;

  @override
  Token get endToken => name;

  /// If [keyword] is `final`, returns it.
  Token? get finalKeyword {
    final keyword = this.keyword;
    if (keyword != null && keyword.keyword == Keyword.FINAL) {
      return keyword;
    }
    return null;
  }

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('keyword', keyword)
    ..addNode('type', type)
    ..addToken('name', name);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitWildcardPattern(this);

  @override
  DartType computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor
        .analyzeDeclaredVariablePatternSchema(type?.typeOrThrow);
  }

  @override
  void resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    final declaredType = type?.typeOrThrow;
    resolverVisitor.analyzeWildcardPattern(
      context: context,
      node: this,
      declaredType: declaredType,
    );

    if (declaredType != null) {
      resolverVisitor.checkPatternNeverMatchesValueType(
        context: context,
        pattern: this,
        requiredType: declaredType,
      );
    }
  }

  @override
  void visitChildren(AstVisitor visitor) {
    type?.accept(visitor);
  }
}

/// The with clause in a class declaration.
///
///    withClause ::=
///        'with' [NamedType] (',' [NamedType])*
abstract final class WithClause implements AstNode {
  /// Return the names of the mixins that were specified.
  NodeList<NamedType> get mixinTypes;

  /// Return the token representing the 'with' keyword.
  Token get withKeyword;
}

/// The with clause in a class declaration.
///
///    withClause ::=
///        'with' [NamedType] (',' [NamedType])*
final class WithClauseImpl extends AstNodeImpl implements WithClause {
  /// The token representing the 'with' keyword.
  @override
  final Token withKeyword;

  /// The names of the mixins that were specified.
  final NodeListImpl<NamedTypeImpl> _mixinTypes = NodeListImpl._();

  /// Initialize a newly created with clause.
  WithClauseImpl({
    required this.withKeyword,
    required List<NamedTypeImpl> mixinTypes,
  }) {
    _mixinTypes._initialize(this, mixinTypes);
  }

  @override
  Token get beginToken => withKeyword;

  @override
  Token get endToken => _mixinTypes.endToken ?? withKeyword;

  @override
  NodeListImpl<NamedTypeImpl> get mixinTypes => _mixinTypes;

  @override
  // TODO(paulberry): add commas.
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('withKeyword', withKeyword)
    ..addNodeList('mixinTypes', mixinTypes);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitWithClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _mixinTypes.accept(visitor);
  }
}

/// A yield statement.
///
///    yieldStatement ::=
///        'yield' '*'? [Expression] ‘;’
abstract final class YieldStatement implements Statement {
  /// Return the expression whose value will be yielded.
  Expression get expression;

  /// Return the semicolon following the expression.
  Token get semicolon;

  /// Return the star optionally following the 'yield' keyword.
  Token? get star;

  /// Return the 'yield' keyword.
  Token get yieldKeyword;
}

/// A yield statement.
///
///    yieldStatement ::=
///        'yield' '*'? [Expression] ‘;’
final class YieldStatementImpl extends StatementImpl implements YieldStatement {
  /// The 'yield' keyword.
  @override
  final Token yieldKeyword;

  /// The star optionally following the 'yield' keyword.
  @override
  final Token? star;

  /// The expression whose value will be yielded.
  ExpressionImpl _expression;

  /// The semicolon following the expression.
  @override
  final Token semicolon;

  /// Initialize a newly created yield expression. The [star] can be `null` if
  /// no star was provided.
  YieldStatementImpl({
    required this.yieldKeyword,
    required this.star,
    required ExpressionImpl expression,
    required this.semicolon,
  }) : _expression = expression {
    _becomeParentOf(_expression);
  }

  @override
  Token get beginToken {
    return yieldKeyword;
  }

  @override
  Token get endToken {
    return semicolon;
  }

  @override
  ExpressionImpl get expression => _expression;

  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('yieldKeyword', yieldKeyword)
    ..addToken('star', star)
    ..addNode('expression', expression)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitYieldStatement(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _expression.accept(visitor);
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
