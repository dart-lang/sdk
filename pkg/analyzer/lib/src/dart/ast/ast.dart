// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/doc_comment.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/ast/to_source_visitor.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/resolver/body_inference_context.dart';
import 'package:analyzer/src/dart/resolver/typed_literal_resolver.dart';
import 'package:analyzer/src/fasta/token_utils.dart' as util show findPrevious;
import 'package:analyzer/src/generated/inference_log.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// The "on" clause in a mixin declaration.
///
///    onClause ::=
///        'on' [NamedType] (',' [NamedType])*
@Deprecated('Use MixinOnClause instead')
typedef OnClause = MixinOnClause;

/// Two or more string literals that are implicitly concatenated because of
/// being adjacent (separated only by whitespace).
///
/// For example
/// ```dart
/// 'Hello ' 'World'
/// ```
///
/// While the grammar only allows adjacent strings where all of the strings are
/// of the same kind (single line or multi-line), this class doesn't enforce
/// that restriction.
///
///    adjacentStrings ::=
///        [StringLiteral] [StringLiteral]+
abstract final class AdjacentStrings implements StringLiteral {
  /// The strings that are implicitly concatenated.
  NodeList<StringLiteral> get strings;
}

final class AdjacentStringsImpl extends StringLiteralImpl
    implements AdjacentStrings {
  final NodeListImpl<StringLiteralImpl> _strings = NodeListImpl._();

  /// Initializes a newly created list of adjacent strings.
  ///
  /// To be syntactically valid, the list of [strings] must contain at least two
  /// elements.
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

/// An AST node that can be annotated with either a documentation comment, a
/// list of annotations (metadata), or both.
abstract final class AnnotatedNode implements AstNode {
  /// The documentation comment associated with this node, or `null` if this
  /// node doesn't have a documentation comment associated with it.
  Comment? get documentationComment;

  /// The first token following the comment and metadata.
  Token get firstTokenAfterCommentAndMetadata;

  /// The annotations associated with this node.
  ///
  /// If there are no annotations, then the returned list is empty.
  NodeList<Annotation> get metadata;

  /// A list containing the comment and annotations associated with this node,
  /// sorted in lexical order.
  ///
  /// If there are neither annotations nor a comment, then the returned list is
  /// empty.
  List<AstNode> get sortedCommentAndAnnotations;
}

sealed class AnnotatedNodeImpl extends AstNodeImpl with _AnnotatedNodeMixin {
  /// Initializes a newly created annotated node.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the node
  /// doesn't have the corresponding attribute.
  AnnotatedNodeImpl({
    required CommentImpl? comment,
    required List<AnnotationImpl>? metadata,
  }) {
    _initializeCommentAndAnnotations(comment, metadata);
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
  ChildEntities get _childEntities {
    return ChildEntities()
      ..addNode('documentationComment', documentationComment)
      ..addNodeList('metadata', metadata);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _visitCommentAndAnnotations(visitor);
  }
}

/// An annotation that can be associated with a declaration.
///
/// For example
/// ```dart
/// @override
/// ```
///
/// or
/// ```dart
/// @Deprecated('1.3.2')
/// ```
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
  /// The arguments to the constructor being invoked, or `null` if this
  /// annotation isn't the invocation of a constructor.
  ArgumentList? get arguments;

  /// The at sign (`@`) that introduces the annotation.
  Token get atSign;

  /// The name of the constructor being invoked, or `null` if this annotation
  /// isn't the invocation of a named constructor.
  SimpleIdentifier? get constructorName;

  /// The element associated with this annotation, or `null` if the AST
  /// structure hasn't been resolved or if this annotation couldn't be resolved.
  Element? get element;

  /// The element associated with this annotation.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if this
  /// annotation couldn't be resolved.
  @experimental
  Element2? get element2;

  /// The element annotation representing this annotation in the element model,
  /// or `null` if the AST hasn't been resolved.
  ElementAnnotation? get elementAnnotation;

  /// The name of either the class defining the constructor that is being
  /// invoked or the field that is being referenced.
  ///
  /// If a named constructor is being referenced, then the name of the
  /// constructor is available using [constructorName].
  Identifier get name;

  @override
  AstNode get parent;

  /// The period before the constructor name, or `null` if this annotation isn't
  /// the invocation of a named constructor.
  Token? get period;

  /// The type arguments to the constructor being invoked, or `null` if either
  /// this annotation isn't the invocation of a constructor or this annotation
  /// doesn't specify type arguments explicitly.
  ///
  /// Note that type arguments are only valid if [Feature.generic_metadata] is
  /// enabled.
  TypeArgumentList? get typeArguments;
}

final class AnnotationImpl extends AstNodeImpl implements Annotation {
  @override
  final Token atSign;

  IdentifierImpl _name;

  TypeArgumentListImpl? _typeArguments;

  @override
  final Token? period;

  SimpleIdentifierImpl? _constructorName;

  ArgumentListImpl? _arguments;

  Element? _element;

  @override
  ElementAnnotationImpl? elementAnnotation;

  /// Initializes a newly created annotation.
  ///
  /// Both the [period] and the [constructorName] can be `null` if the
  /// annotation isn't referencing a named constructor.
  ///
  /// The [arguments] can be `null` if the annotation isn't referencing a
  /// constructor.
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
    if (_element case var element?) {
      return element;
    } else if (_constructorName == null) {
      return _name.staticElement;
    }
    return null;
  }

  set element(Element? element) {
    _element = element;
  }

  @experimental
  @override
  Element2? get element2 {
    var element = this.element;
    if (element case Fragment fragment) {
      return fragment.element;
    } else if (element case Element2 element) {
      return element;
    }
    return null;
  }

  @override
  Token get endToken {
    if (arguments case var arguments?) {
      return arguments.endToken;
    } else if (constructorName case var constructorName?) {
      return constructorName.endToken;
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
  /// The expressions producing the values of the arguments.
  ///
  /// If there are no arguments the list will be empty.
  ///
  /// Although the language requires that positional arguments appear before
  /// named arguments unless the [Feature.named_arguments_anywhere] is enabled,
  /// this class allows them to be intermixed.
  NodeList<Expression> get arguments;

  /// The left parenthesis.
  Token get leftParenthesis;

  /// The right parenthesis.
  Token get rightParenthesis;
}

final class ArgumentListImpl extends AstNodeImpl implements ArgumentList {
  @override
  final Token leftParenthesis;

  final NodeListImpl<ExpressionImpl> _arguments = NodeListImpl._();

  @override
  final Token rightParenthesis;

  /// A list containing the elements representing the parameters corresponding
  /// to each of the arguments in this list, or `null` if the AST hasn't been
  /// resolved or if the function or method being invoked couldn't be
  /// determined based on static type information.
  ///
  /// The list must be the same length as the number of arguments, but can
  /// contain `null` entries if a given argument doesn't correspond to a formal
  /// parameter.
  List<ParameterElement?>? _correspondingStaticParameters;

  /// Initializes a newly created list of arguments.
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

  /// Returns the parameter element representing the parameter to which the
  /// value of the given expression is bound, or `null` if any of the following
  /// are not true
  /// - the given [expression] is a child of this list
  /// - the AST structure is resolved
  /// - the function being invoked is known based on static type information
  /// - the expression corresponds to one of the parameters of the function
  ///   being invoked
  ParameterElement? _getStaticParameterElementFor(Expression expression) {
    if (_correspondingStaticParameters == null ||
        _correspondingStaticParameters!.length != _arguments.length) {
      // Either the AST structure hasn't been resolved, the invocation of which
      // this list is a part couldn't be resolved, or the argument list was
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
  /// The `as` operator.
  Token get asOperator;

  /// The expression used to compute the value being cast.
  Expression get expression;

  /// The type being cast to.
  TypeAnnotation get type;
}

final class AsExpressionImpl extends ExpressionImpl implements AsExpression {
  ExpressionImpl _expression;

  @override
  final Token asOperator;

  TypeAnnotationImpl _type;

  /// Initializes a newly created as expression.
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

final class AssertInitializerImpl extends ConstructorInitializerImpl
    implements AssertInitializer {
  @override
  final Token assertKeyword;

  @override
  final Token leftParenthesis;

  ExpressionImpl _condition;

  @override
  final Token? comma;

  ExpressionImpl? _message;

  @override
  final Token rightParenthesis;

  /// Initializes a newly created assert initializer.
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
  /// The token representing the `assert` keyword.
  Token get assertKeyword;

  /// The comma between the [condition] and the [message], or `null` if no
  /// message was supplied.
  Token? get comma;

  /// The condition that is being asserted to be `true`.
  Expression get condition;

  /// The left parenthesis.
  Token get leftParenthesis;

  /// The message to report if the assertion fails, or `null` if no message was
  /// supplied.
  Expression? get message;

  /// The right parenthesis.
  Token get rightParenthesis;
}

/// An assert statement.
///
///    assertStatement ::=
///        'assert' '(' [Expression] (',' [Expression])? ')' ';'
abstract final class AssertStatement implements Assertion, Statement {
  /// The semicolon terminating the statement.
  Token get semicolon;
}

final class AssertStatementImpl extends StatementImpl
    implements AssertStatement {
  @override
  final Token assertKeyword;

  @override
  final Token leftParenthesis;

  ExpressionImpl _condition;

  @override
  final Token? comma;

  ExpressionImpl? _message;

  @override
  final Token rightParenthesis;

  @override
  final Token semicolon;

  /// Initializes a newly created assert statement.
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
  /// The element referenced by this pattern, or `null` if either [name] doesn't
  /// resolve to an element or the AST structure hasn't been resolved.
  ///
  /// In valid code this is either a [LocalVariableElement] or a
  /// [ParameterElement].
  Element? get element;

  /// The element referenced by this pattern.
  ///
  /// Returns `null` if either [name] doesn't resolve to an element or the AST
  /// structure hasn't been resolved.
  ///
  /// In valid code this is either a [LocalVariableElement2] or a
  /// [FormalParameterElement].
  @experimental
  Element2? get element2;
}

final class AssignedVariablePatternImpl extends VariablePatternImpl
    implements AssignedVariablePattern {
  @override
  Element? element;

  AssignedVariablePatternImpl({
    required super.name,
  });

  @override
  Token get beginToken => name;

  @experimental
  @override
  Element2? get element2 {
    return element.asElement2;
  }

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
    var element = this.element;
    if (element is PromotableElement) {
      return resolverVisitor
          .analyzeAssignedVariablePatternSchema(element)
          .unwrapTypeSchemaView();
    }
    return resolverVisitor.operations.unknownType.unwrapTypeSchemaView();
  }

  @override
  PatternResult<DartType> resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    return resolverVisitor.resolveAssignedVariablePattern(
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
  /// The expression used to compute the left hand side.
  Expression get leftHandSide;

  /// The assignment operator being applied.
  Token get operator;

  /// The expression used to compute the right-hand side.
  Expression get rightHandSide;
}

final class AssignmentExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl, CompoundAssignmentExpressionImpl
    implements AssignmentExpression {
  ExpressionImpl _leftHandSide;

  @override
  final Token operator;

  ExpressionImpl _rightHandSide;

  @override
  MethodElement? staticElement;

  /// Initializes a newly created assignment expression.
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

  @experimental
  @override
  MethodElement2? get element => (staticElement as MethodFragment?)?.element;

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

  /// The parameter element representing the parameter to which the value of the
  /// right operand is bound, or `null` if the AST structure is not resolved or
  /// the function being invoked is not known based on static type information.
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
  /// In other words, `compare` returns a negative value if the offset of the
  /// first node is less than the offset of the second node, zero (0) if the
  /// nodes have the same offset, and a positive value if the offset of the
  /// first node is greater than the offset of the second node.
  static Comparator<AstNode> LEXICAL_ORDER =
      (AstNode first, AstNode second) => first.offset - second.offset;

  /// The first token included in this node's source range.
  Token get beginToken;

  /// An iterator that can be used to iterate through all the entities (either
  /// AST nodes or tokens) that make up the contents of this node, including doc
  /// comments but excluding other comments.
  Iterable<SyntacticEntity> get childEntities;

  /// The offset of the character immediately following the last character of
  /// this node's source range.
  ///
  /// This is equivalent to `node.offset + node.length`. For a compilation unit
  /// this is equal to the length of the unit's source. For synthetic nodes this
  /// is equivalent to the node's offset (because the length is zero (`0`) by
  /// definition).
  @override
  int get end;

  /// The last token included in this node's source range.
  Token get endToken;

  /// Whether this node is a synthetic node.
  ///
  /// A synthetic node is a node that was introduced by the parser in order to
  /// recover from an error in the code. Synthetic nodes always have a length
  /// of zero (`0`).
  bool get isSynthetic;

  @override
  int get length;

  @override
  int get offset;

  /// Returns this node's parent node, or `null` if this node is the root of an
  /// AST structure.
  ///
  /// Note that the relationship between an AST node and its parent node may
  /// change over the lifetime of a node.
  AstNode? get parent;

  /// The node at the root of this node's AST structure.
  ///
  /// Note that this method's performance is linear with respect to the depth
  /// of the node in the AST structure (O(depth)).
  AstNode get root;

  /// Use the given [visitor] to visit this node.
  ///
  /// Returns the value returned by the visitor as a result of visiting this
  /// node.
  E? accept<E>(AstVisitor<E> visitor);

  /// Returns the token before [target], or `null` if it can't be found.
  Token? findPrevious(Token target);

  /// Returns the value of the property with the given [name], or `null` if this
  /// node doesn't have a property with the given name.
  @Deprecated('Use Expando instead')
  E? getProperty<E>(String name);

  /// Set the value of the property with the given [name] to the given [value].
  ///
  /// If the value is `null`, the property is removed.
  @Deprecated('Use Expando instead')
  void setProperty(String name, Object? value);

  /// Returns either this node or the most immediate ancestor of this node for
  /// which the [predicate] returns `true`, or `null` if there's no such node.
  E? thisOrAncestorMatching<E extends AstNode>(
    bool Function(AstNode) predicate,
  );

  /// Returns either this node or the most immediate ancestor of this node that
  /// has the given type, or `null` if there's no such node.
  E? thisOrAncestorOfType<E extends AstNode>();

  /// Returns a textual description of this node in a form approximating valid
  /// source.
  ///
  /// The returned string isn't valid source code primarily in the case where
  /// the node itself isn't well-formed.
  ///
  /// Clients should never depend on the returned value being valid code, nor
  /// being consistent from one version of the package to the next. As a result,
  /// clients should never display the returned string to users.
  String toSource();

  /// Returns a textual description of this node.
  ///
  /// The returned string is intended to be useful only for debugging.
  ///
  /// Clients should never depend on the returned value being useful for any
  /// purpose, nor being consistent from one version of the package to the next.
  /// As a result, clients should never display the returned string to users.
  @override
  String toString();

  /// Use the given [visitor] to visit all of the children of this node.
  ///
  /// The children are visited in lexical order.
  void visitChildren(AstVisitor visitor);
}

sealed class AstNodeImpl implements AstNode {
  AstNode? _parent;

  /// A table mapping the names of properties to their values, or `null` if this
  /// node doesn't have any properties associated with it.
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
    var beginToken = this.beginToken;
    var endToken = this.endToken;
    return endToken.offset + endToken.length - beginToken.offset;
  }

  /// The properties (tokens and nodes) of this node, with names, in the order
  /// in which these entities should normally appear, not necessarily in the
  /// order they really are (because of recovery).
  Iterable<ChildEntity> get namedChildEntities => _childEntities.entities;

  @override
  int get offset {
    var beginToken = this.beginToken;
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

  @Deprecated('Use Expando instead')
  @override
  E? getProperty<E>(String name) {
    return _propertyMap?[name] as E?;
  }

  @Deprecated('Use Expando instead')
  @override
  void setProperty(String name, Object? value) {
    if (value == null) {
      var propertyMap = _propertyMap;
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

  /// Returns the [child] node after making this node the parent of the [child]
  /// node.
  T _becomeParentOf<T extends AstNodeImpl?>(T child) {
    child?._parent = this;
    return child;
  }
}

/// Mixin for any [AstNodeImpl] that can potentially introduce a new scope.
base mixin AstNodeWithNameScopeMixin on AstNodeImpl {
  /// The [Scope] that was used while resolving `this`, or `null` if resolution
  /// has not been performed yet.
  Scope? nameScope;
}

/// An object that can be used to visit an AST structure.
///
/// Clients may not extend, implement or mix-in this class. There are classes
/// that implement this interface that provide useful default behaviors in
/// `package:analyzer/dart/ast/visitor.dart`. A couple of the most useful
/// include
/// - SimpleAstVisitor which implements every visit method by doing nothing,
/// - RecursiveAstVisitor which causes every node in a structure to be visited,
///   and
/// - ThrowingAstVisitor which implements every visit method by throwing an
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

  R? visitAugmentedExpression(AugmentedExpression node);

  R? visitAugmentedInvocation(AugmentedInvocation node);

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

  R? visitExtensionOnClause(ExtensionOnClause node);

  R? visitExtensionOverride(ExtensionOverride node);

  R? visitExtensionTypeDeclaration(ExtensionTypeDeclaration node);

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

  R? visitMixinDeclaration(MixinDeclaration node);

  R? visitMixinOnClause(MixinOnClause node);

  R? visitNamedExpression(NamedExpression node);

  R? visitNamedType(NamedType node);

  R? visitNativeClause(NativeClause node);

  R? visitNativeFunctionBody(NativeFunctionBody node);

  R? visitNullAssertPattern(NullAssertPattern node);

  R? visitNullAwareElement(NullAwareElement node);

  R? visitNullCheckPattern(NullCheckPattern node);

  R? visitNullLiteral(NullLiteral node);

  R? visitObjectPattern(ObjectPattern node);

  @Deprecated('Use visitMixinOnClause() instead')
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

  R? visitRepresentationConstructorName(RepresentationConstructorName node);

  R? visitRepresentationDeclaration(RepresentationDeclaration node);

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

/// The augmented expression.
///
/// It is created only inside an augmentation.
/// The exact meaning depends on what is augmented, and where it is used.
///
/// Augmenting getters: `augmented` invokes the getter and evaluates to the
/// return value.
/// The [element] is the augmented getter.
/// The [staticType] is the return type of the getter.
///
/// Augmenting setters: `augmented` must be followed by an `=`, and will
/// directly invoke the augmented setter.
/// The [element] is the augmented setter.
/// The [staticType] is meaningless, and set to `null`.
///
/// Augmenting fields: `augmented` can only be used in an initializer
/// expression, and refers to the original field's initializer expression.
/// The [element] is the augmented field.
/// The [staticType] is the type of the field.
///
/// Augmenting binary operators: `augmented` must be the LHS, and followed by
/// the argument, e.g. `augmented + 1`.
/// The [element] is the augmented [MethodElement].
/// The [staticType] is the type of `this`.
///
/// Augmenting index operators: `augmented` must be the index target,
/// e.g. `augmented[0]`.
/// The [element] is the augmented [MethodElement].
/// The [staticType] is the type of `this`.
///
/// Augmenting prefix operators: `augmented` must be the target, e.g.
/// `~augmented`.
/// The [element] is the augmented [MethodElement].
/// The [staticType] is the type of `this`.
abstract final class AugmentedExpression implements Expression {
  /// The 'augmented' keyword.
  Token get augmentedKeyword;

  /// The referenced augmented element: getter, setter, variable.
  Element? get element;

  /// The referenced augmented element: getter, setter, variable.
  // TODO(brianwilkerson): Consider resolving this to a fragment rather than an
  //  element. In this case I think that's closer to the right semantics.
  @experimental
  Element2? get element2;
}

final class AugmentedExpressionImpl extends ExpressionImpl
    implements AugmentedExpression {
  @override
  final Token augmentedKeyword;

  @override
  Element? element;

  AugmentedExpressionImpl({
    required this.augmentedKeyword,
  });

  @override
  Token get beginToken => augmentedKeyword;

  @experimental
  @override
  Element2? get element2 => (element as Fragment?)?.element;

  @override
  Token get endToken => augmentedKeyword;

  @override
  bool get isAssignable => true;

  @override
  Precedence get precedence => Precedence.primary;

  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('augmentedKeyword', augmentedKeyword);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAugmentedExpression(this);

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitAugmentedExpression(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    // There are no children to visit.
  }
}

/// Invocation of the augmented function, constructor, or method.
///
///    augmentedInvocation ::=
///        'augmented' [TypeArgumentList]? [ArgumentList]
abstract final class AugmentedInvocation implements Expression {
  /// The list of value arguments.
  ArgumentList get arguments;

  /// The 'augmented' keyword.
  Token get augmentedKeyword;

  /// The referenced augmented element: function, constructor, or method.
  ExecutableElement? get element;

  /// The referenced augmented element: function, constructor, or method.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if this
  /// fragment is the first fragment in the chain.
  // TODO(brianwilkerson): Consider resolving this to a fragment rather than an
  //  element. In this case I think that's closer to the right semantics.
  @experimental
  ExecutableElement2? get element2;

  /// The list of type arguments.
  ///
  /// In valid code cannot be provided for augmented constructor invocation.
  TypeArgumentList? get typeArguments;
}

final class AugmentedInvocationImpl extends ExpressionImpl
    implements AugmentedInvocation {
  @override
  final Token augmentedKeyword;

  @override
  ExecutableElement? element;

  @override
  final TypeArgumentListImpl? typeArguments;

  @override
  final ArgumentListImpl arguments;

  AugmentedInvocationImpl({
    required this.augmentedKeyword,
    required this.typeArguments,
    required this.arguments,
  }) {
    _becomeParentOf(typeArguments);
    _becomeParentOf(arguments);
  }

  @override
  Token get beginToken => augmentedKeyword;

  @experimental
  @override
  ExecutableElement2? get element2 => (element as ExecutableFragment?)?.element;

  @override
  Token get endToken => arguments.endToken;

  @override
  Precedence get precedence => Precedence.postfix;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('augmentedKeyword', augmentedKeyword)
    ..addNode('typeArguments', typeArguments)
    ..addNode('arguments', arguments);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitAugmentedInvocation(this);
  }

  @override
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitAugmentedInvocation(this, contextType: contextType);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    typeArguments?.accept(visitor);
    arguments.accept(visitor);
  }
}

/// An await expression.
///
///    awaitExpression ::=
///        'await' [Expression]
abstract final class AwaitExpression implements Expression {
  /// The `await` keyword.
  Token get awaitKeyword;

  /// The expression whose value is being waited on.
  Expression get expression;
}

final class AwaitExpressionImpl extends ExpressionImpl
    implements AwaitExpression {
  @override
  final Token awaitKeyword;

  ExpressionImpl _expression;

  /// Initializes a newly created await expression.
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
  /// The expression used to compute the left operand.
  Expression get leftOperand;

  /// The binary operator being applied.
  Token get operator;

  /// The expression used to compute the right operand.
  Expression get rightOperand;

  /// The function type of the invocation, or `null` if the AST structure hasn't
  /// been resolved or if the invocation couldn't be resolved.
  FunctionType? get staticInvokeType;
}

final class BinaryExpressionImpl extends ExpressionImpl
    implements BinaryExpression {
  ExpressionImpl _leftOperand;

  @override
  final Token operator;

  ExpressionImpl _rightOperand;

  @override
  MethodElement? staticElement;

  @override
  FunctionType? staticInvokeType;

  /// Initializes a newly created binary expression.
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

  @experimental
  @override
  MethodElement2? get element => staticElement?.asElement2 as MethodElement2?;

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
  /// The left curly bracket.
  Token get leftBracket;

  /// The right curly bracket.
  Token get rightBracket;

  /// The statements contained in the block.
  NodeList<Statement> get statements;
}

/// A function body that consists of a block of statements.
///
///    blockFunctionBody ::=
///        ('async' | 'async' '*' | 'sync' '*')? [Block]
abstract final class BlockFunctionBody implements FunctionBody {
  /// The block representing the body of the function.
  Block get block;
}

final class BlockFunctionBodyImpl extends FunctionBodyImpl
    implements BlockFunctionBody {
  @override
  final Token? keyword;

  @override
  final Token? star;

  BlockImpl _block;

  /// Initializes a newly created function body consisting of a block of
  /// statements.
  ///
  /// The [keyword] can be `null` if there's no keyword specified for the block.
  ///
  /// The [star] can be `null` if there's no star following the keyword (and
  /// must be `null` if there's no keyword).
  BlockFunctionBodyImpl({
    required this.keyword,
    required this.star,
    required BlockImpl block,
  }) : _block = block {
    _becomeParentOf(_block);
  }

  @override
  Token get beginToken {
    if (keyword case var keyword?) {
      return keyword;
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

final class BlockImpl extends StatementImpl
    with AstNodeWithNameScopeMixin
    implements Block {
  @override
  final Token leftBracket;

  final NodeListImpl<StatementImpl> _statements = NodeListImpl._();

  @override
  final Token rightBracket;

  /// Initializes a newly created block of code.
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
  /// The token representing the literal.
  Token get literal;

  /// The value of the literal.
  bool get value;
}

final class BooleanLiteralImpl extends LiteralImpl implements BooleanLiteral {
  @override
  final Token literal;

  @override
  final bool value;

  /// Initializes a newly created boolean literal.
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
  /// The token representing the `break` keyword.
  Token get breakKeyword;

  /// The label associated with the statement, or `null` if there's no label.
  SimpleIdentifier? get label;

  /// The semicolon terminating the statement.
  Token get semicolon;

  /// The node from which this break statement is breaking, or `null` if the AST
  /// hasn't yet been resolved or if the target couldn't be resolved.
  ///
  /// This is either a [Statement] (in the case of breaking out of a loop), a
  /// [SwitchMember] (in the case of a labeled break statement whose label
  /// matches a label on a switch case in an enclosing switch statement).
  ///
  /// Note that if the source code has errors, the target might be invalid.
  /// For example, if the break statement is trying to break to a switch case
  /// the target will be the switch case even though breaking to a switch case
  /// isn't valid.
  AstNode? get target;
}

final class BreakStatementImpl extends StatementImpl implements BreakStatement {
  @override
  final Token breakKeyword;

  SimpleIdentifierImpl? _label;

  @override
  final Token semicolon;

  @override
  AstNode? target;

  /// Initializes a newly created break statement.
  ///
  /// The [label] can be `null` if there's no label associated with the
  /// statement.
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
  /// The cascade sections sharing the common target.
  NodeList<Expression> get cascadeSections;

  /// Whether this cascade is null aware (as opposed to non-null).
  bool get isNullAware;

  /// The target of the cascade sections.
  Expression get target;
}

final class CascadeExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl
    implements CascadeExpression {
  ExpressionImpl _target;

  final NodeListImpl<ExpressionImpl> _cascadeSections = NodeListImpl._();

  /// Initializes a newly created cascade expression.
  ///
  /// The list of [cascadeSections] must contain at least one element.
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
  /// The token representing the `case` keyword.
  Token get caseKeyword;

  /// The pattern controlling whether the statements are executed.
  GuardedPattern get guardedPattern;
}

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

sealed class CaseNodeImpl implements AstNode {
  GuardedPatternImpl get guardedPattern;
}

/// A cast pattern.
///
///    castPattern ::=
///        [DartPattern] 'as' [TypeAnnotation]
abstract final class CastPattern implements DartPattern {
  /// The `as` token.
  Token get asToken;

  /// The pattern used to match the value being cast.
  DartPattern get pattern;

  /// The type that the value being matched is cast to.
  TypeAnnotation get type;
}

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
    return resolverVisitor.analyzeCastPatternSchema().unwrapTypeSchemaView();
  }

  @override
  PatternResult<DartType> resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    inferenceLogWriter?.enterPattern(this);
    type.accept(resolverVisitor);
    var requiredType = type.typeOrThrow;

    var analysisResult = resolverVisitor.analyzeCastPattern(
      context: context,
      pattern: this,
      innerPattern: pattern,
      requiredType: SharedTypeView(requiredType),
    );

    resolverVisitor.checkPatternNeverMatchesValueType(
      context: context,
      pattern: this,
      requiredType: requiredType,
      matchedValueType: analysisResult.matchedValueType.unwrapTypeView(),
    );
    inferenceLogWriter?.exitPattern(this);

    return analysisResult;
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
  /// The body of the catch block.
  Block get body;

  /// The token representing the `catch` keyword, or `null` if there's no
  /// `catch` keyword.
  Token? get catchKeyword;

  /// The comma separating the exception parameter from the stack trace
  /// parameter, or `null` if there's no stack trace parameter.
  Token? get comma;

  /// The parameter whose value is the exception that was thrown, or `null` if
  /// there's no `catch` keyword.
  CatchClauseParameter? get exceptionParameter;

  /// The type of exceptions caught by this catch clause, or `null` if this
  /// catch clause catches every type of exception.
  TypeAnnotation? get exceptionType;

  /// The left parenthesis, or `null` if there's no `catch` keyword.
  Token? get leftParenthesis;

  /// The token representing the `on` keyword, or `null` if there's no `on`
  /// keyword.
  Token? get onKeyword;

  /// The right parenthesis, or `null` if there's no `catch` keyword.
  Token? get rightParenthesis;

  /// The parameter whose value is the stack trace associated with the
  /// exception, or `null` if there's no stack trace parameter.
  CatchClauseParameter? get stackTraceParameter;
}

final class CatchClauseImpl extends AstNodeImpl implements CatchClause {
  @override
  final Token? onKeyword;

  TypeAnnotationImpl? _exceptionType;

  @override
  final Token? catchKeyword;

  @override
  final Token? leftParenthesis;

  CatchClauseParameterImpl? _exceptionParameter;

  @override
  final Token? comma;

  CatchClauseParameterImpl? _stackTraceParameter;

  @override
  final Token? rightParenthesis;

  BlockImpl _body;

  /// Initializes a newly created catch clause.
  ///
  /// The [onKeyword] and [exceptionType] can be `null` if the clause is to
  /// catch all exceptions.
  ///
  /// The [comma] and [_stackTraceParameter] can be `null` if the stack trace
  /// parameter isn't defined.
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
    if (onKeyword case var onKeyword?) {
      return onKeyword;
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

/// An 'exception' or 'stackTrace' parameter in [CatchClause].
abstract final class CatchClauseParameter extends AstNode {
  /// The declared element, or `null` if the AST hasn't been resolved.
  LocalVariableElement? get declaredElement;

  /// The declared element.
  ///
  /// Returns `null` if the AST hasn't been resolved.
  @experimental
  LocalVariableElement2? get declaredElement2;

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

  @experimental
  @override
  LocalVariableElement2? get declaredElement2 {
    return declaredElement.asElement2 as LocalVariableElementImpl2?;
  }

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

/// A helper class to allow iteration of child entities of an AST node.
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
    implements NamedCompilationUnitMember, _FragmentDeclaration {
  /// The `abstract` keyword, or `null` if the keyword was absent.
  Token? get abstractKeyword;

  /// The `augment` keyword, or `null` if the keyword was absent.
  @experimental
  Token? get augmentKeyword;

  /// The `base` keyword, or `null` if the keyword was absent.
  Token? get baseKeyword;

  /// The token representing the `class` keyword.
  Token get classKeyword;

  @override
  ClassElement? get declaredElement;

  @experimental
  @override
  ClassFragment? get declaredFragment;

  /// The `extends` clause for this class, or `null` if the class doesn't extend
  /// any other class.
  ExtendsClause? get extendsClause;

  /// The `final` keyword, or `null` if the keyword was absent.
  Token? get finalKeyword;

  /// The `implements` clause for the class, or `null` if the class doesn't
  /// implement any interfaces.
  ImplementsClause? get implementsClause;

  /// The `interface` keyword, or `null` if the keyword was absent.
  Token? get interfaceKeyword;

  /// The left curly bracket.
  Token get leftBracket;

  /// The `macro` keyword, or `null` if the keyword was absent.
  @experimental
  Token? get macroKeyword;

  /// The members defined by the class.
  NodeList<ClassMember> get members;

  /// The `mixin` keyword, or `null` if the keyword was absent.
  Token? get mixinKeyword;

  /// The native clause for this class, or `null` if the class doesn't have a
  /// native clause.
  NativeClause? get nativeClause;

  /// The right curly bracket.
  Token get rightBracket;

  /// The `sealed` keyword, or `null` if the keyword was absent.
  Token? get sealedKeyword;

  /// The type parameters for the class, or `null` if the class doesn't have any
  /// type parameters.
  TypeParameterList? get typeParameters;

  /// The `with` clause for the class, or `null` if the class doesn't have a
  /// `with` clause.
  WithClause? get withClause;
}

final class ClassDeclarationImpl extends NamedCompilationUnitMemberImpl
    with AstNodeWithNameScopeMixin
    implements ClassDeclaration {
  @override
  final Token? augmentKeyword;

  @override
  final Token? abstractKeyword;

  @override
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

  @override
  final Token classKeyword;

  @override
  TypeParameterListImpl? typeParameters;

  @override
  ExtendsClauseImpl? extendsClause;

  @override
  WithClauseImpl? withClause;

  @override
  ImplementsClauseImpl? implementsClause;

  @override
  final NativeClauseImpl? nativeClause;

  @override
  final Token leftBracket;

  @override
  final NodeListImpl<ClassMemberImpl> members = NodeListImpl._();

  @override
  final Token rightBracket;

  @override
  ClassElementImpl? declaredElement;

  ClassDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
    required this.abstractKeyword,
    required this.macroKeyword,
    required this.sealedKeyword,
    required this.baseKeyword,
    required this.interfaceKeyword,
    required this.finalKeyword,
    required this.mixinKeyword,
    required this.classKeyword,
    required super.name,
    required this.typeParameters,
    required this.extendsClause,
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

  @experimental
  @override
  ClassFragment? get declaredFragment => declaredElement as ClassFragment;

  @override
  Token get endToken => rightBracket;

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
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitClassDeclaration(this);

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

/// A node that declares a name within the scope of a class, enum, extension,
/// extension type, or mixin declaration.
sealed class ClassMember implements Declaration {}

sealed class ClassMemberImpl extends DeclarationImpl implements ClassMember {
  /// Initializes a newly created member of a class.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the member
  /// doesn't have the corresponding attribute.
  ClassMemberImpl({
    required super.comment,
    required super.metadata,
  });
}

/// A class type alias.
///
///    classTypeAlias ::=
///        classModifiers 'class' [SimpleIdentifier] [TypeParameterList]? '='
///        mixinApplication
///
///    classModifiers ::= 'sealed'
///      | 'abstract'? ('base' | 'interface' | 'final')?
///      | 'abstract'? 'base'? 'mixin'
///
///    mixinApplication ::=
///        [NamedType] [WithClause] [ImplementsClause]? ';'
abstract final class ClassTypeAlias implements TypeAlias, _FragmentDeclaration {
  /// The token for the `abstract` keyword, or `null` if this isn't defining an
  /// abstract class.
  Token? get abstractKeyword;

  /// The `base` keyword, or `null` if the keyword was absent.
  Token? get baseKeyword;

  @override
  ClassElement? get declaredElement;

  @experimental
  @override
  ClassFragment? get declaredFragment;

  /// The token for the '=' separating the name from the definition.
  Token get equals;

  /// The `final` keyword, or `null` if the keyword was absent.
  Token? get finalKeyword;

  /// The implements clause for this class, or `null` if there's no implements
  /// clause.
  ImplementsClause? get implementsClause;

  /// The `interface` keyword, or `null` if the keyword was absent.
  Token? get interfaceKeyword;

  /// The `mixin` keyword, or `null` if the keyword was absent.
  Token? get mixinKeyword;

  /// The `sealed` keyword, or `null` if the keyword was absent.
  Token? get sealedKeyword;

  /// The name of the superclass of the class being declared.
  NamedType get superclass;

  /// The type parameters for the class, or `null` if the class doesn't have any
  /// type parameters.
  TypeParameterList? get typeParameters;

  /// The with clause for this class.
  WithClause get withClause;
}

final class ClassTypeAliasImpl extends TypeAliasImpl implements ClassTypeAlias {
  TypeParameterListImpl? _typeParameters;

  @override
  final Token equals;

  @override
  final Token? abstractKeyword;

  /// The token for the `macro` keyword, or `null` if this isn't defining a
  /// macro class.
// TODO(brianwilkerson): Move this comment to the getter when it's added to
  //  the public API.
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

  NamedTypeImpl _superclass;

  WithClauseImpl _withClause;

  ImplementsClauseImpl? _implementsClause;

  @override
  ClassElementImpl? declaredElement;

  /// Initializes a newly created class type alias.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the class
  /// type alias doesn't have the corresponding attribute.
  ///
  /// The [typeParameters] can be `null` if the class doesn't have any type
  /// parameters.
  ///
  /// The [abstractKeyword] can be `null` if the class isn't abstract.
  ///
  /// The [implementsClause] can be `null` if the class doesn't implement any
  /// interfaces.
  ClassTypeAliasImpl({
    required super.comment,
    required super.metadata,
    required super.typedefKeyword,
    required super.name,
    required TypeParameterListImpl? typeParameters,
    required this.equals,
    required this.abstractKeyword,
    required this.macroKeyword,
    required this.sealedKeyword,
    required this.baseKeyword,
    required this.interfaceKeyword,
    required this.finalKeyword,
    required super.augmentKeyword,
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

  @experimental
  @override
  ClassFragment? get declaredFragment => declaredElement as ClassFragment?;

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
  /// The `hide` or `show` keyword specifying what kind of processing is to be
  /// done on the names.
  Token get keyword;
}

sealed class CombinatorImpl extends AstNodeImpl implements Combinator {
  @override
  final Token keyword;

  /// Initializes a newly created combinator.
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
  /// The markdown code blocks (both fenced and indented) contained in this
  /// comment.
  @experimental
  List<MdCodeBlock> get codeBlocks;

  @experimental
  List<DocDirective> get docDirectives;

  @experimental
  List<DocImport> get docImports;

  /// Whether this comment has a line beginning with '@nodoc', indicating its
  /// contents aren't intended for publishing.
  @experimental
  bool get hasNodoc;

  /// Whether this is a block comment.
  @Deprecated("Do not use; this value is always 'false'")
  bool get isBlock;

  /// Whether this is a documentation comment.
  @Deprecated("Do not use; this value is always 'true'")
  bool get isDocumentation;

  /// Whether this is an end-of-line comment.
  @Deprecated("Do not use; this value is always 'false'")
  bool get isEndOfLine;

  /// The references embedded within the documentation comment.
  ///
  /// If there are no references in the comment then the list will be empty.
  NodeList<CommentReference> get references;

  /// The tokens representing the comment.
  List<Token> get tokens;
}

final class CommentImpl extends AstNodeImpl
    with AstNodeWithNameScopeMixin
    implements Comment {
  @override
  final List<Token> tokens;

  final NodeListImpl<CommentReferenceImpl> _references = NodeListImpl._();

  @override
  final List<MdCodeBlock> codeBlocks;

  @override
  final List<DocImport> docImports;

  @override
  final List<DocDirective> docDirectives;

  @override
  final bool hasNodoc;

  /// Initializes a newly created comment.
  ///
  /// The list of [tokens] must contain at least one token.
  ///
  /// The [type] is the type of the comment.
  ///
  /// The list of [references] can be empty if the comment doesn't contain any
  /// embedded references.
  CommentImpl({
    required this.tokens,
    required List<CommentReferenceImpl> references,
    required this.codeBlocks,
    required this.docImports,
    required this.docDirectives,
    required this.hasNodoc,
  }) {
    _references._initialize(this, references);
  }

  @override
  Token get beginToken => tokens[0];

  @override
  Token get endToken => tokens[tokens.length - 1];

  @override
  bool get isBlock => false;

  @override
  bool get isDocumentation => true;

  @override
  bool get isEndOfLine => false;

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

  /// The token representing the `new` keyword, or `null` if there was no `new`
  /// keyword.
  Token? get newKeyword;
}

final class CommentReferenceImpl extends AstNodeImpl
    implements CommentReference {
  @override
  final Token? newKeyword;

  CommentReferableExpressionImpl _expression;

  @override
  final bool isSynthetic;

  /// Initializes a newly created reference to a Dart element.
  ///
  /// The [newKeyword] can be `null` if the reference isn't to a constructor.
  CommentReferenceImpl({
    required this.newKeyword,
    required CommentReferableExpressionImpl expression,
    required this.isSynthetic,
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

/// A compilation unit.
///
/// While the grammar restricts the order of the directives and declarations
/// within a compilation unit, this class doesn't enforce those restrictions.
/// In particular, the children of a compilation unit are visited in lexical
/// order even if lexical order doesn't conform to the restrictions of the
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
  /// The first (non-EOF) token in the token stream that was parsed to form this
  /// compilation unit.
  @override
  Token get beginToken;

  /// The declarations contained in this compilation unit.
  NodeList<CompilationUnitMember> get declarations;

  /// The element associated with this compilation unit, or `null` if the AST
  /// structure hasn't been resolved.
  CompilationUnitElement? get declaredElement;

  /// The fragment associated with this compilation unit.
  ///
  /// Returns `null` if the AST structure hasn't been resolved.
  @experimental
  LibraryFragment? get declaredFragment;

  /// The directives contained in this compilation unit.
  NodeList<Directive> get directives;

  /// The last token in the token stream that was parsed to form this
  /// compilation unit.
  ///
  /// This token should always have a type of [TokenType.EOF].
  @override
  Token get endToken;

  /// The set of features available to this compilation unit.
  ///
  /// Determined by some combination of the `package_config.json` file, the
  /// enclosing package's SDK version constraint, and/or the presence of a
  /// `@dart` directive in a comment at the top of the file.
  FeatureSet get featureSet;

  /// The language version override specified for this compilation unit using a
  /// token like '// @dart = 2.7', or `null` if no override is specified.
  LanguageVersionToken? get languageVersionToken;

  /// The line information for this compilation unit.
  LineInfo get lineInfo;

  /// The script tag at the beginning of the compilation unit, or `null` if
  /// there's no script tag in this compilation unit.
  ScriptTag? get scriptTag;

  /// A list containing all of the directives and declarations in this
  /// compilation unit, sorted in lexical order.
  List<AstNode> get sortedDirectivesAndDeclarations;
}

final class CompilationUnitImpl extends AstNodeImpl
    with AstNodeWithNameScopeMixin
    implements CompilationUnit {
  @override
  Token beginToken;

  ScriptTagImpl? _scriptTag;

  final NodeListImpl<DirectiveImpl> _directives = NodeListImpl._();

  final NodeListImpl<CompilationUnitMemberImpl> _declarations =
      NodeListImpl._();

  @override
  final Token endToken;

  @override
  CompilationUnitElementImpl? declaredElement;

  @override
  final LineInfo lineInfo;

  /// The language version information.
  LibraryLanguageVersion? languageVersion;

  @override
  final FeatureSet featureSet;

  /// Nodes that were parsed, but happened at locations where they aren't
  /// allowed.
  ///
  /// Instead of dropping them, we remember them here. Quick fixes can look
  /// here to determine which source range to remove.
  final List<AstNodeImpl> invalidNodes;

  /// Initializes a newly created compilation unit to have the given directives
  /// and declarations.
  ///
  /// The [scriptTag] can be `null` if there's no script tag in the compilation
  /// unit.
  ///
  /// The list of [directives] can be `null` if there are no directives in the
  /// compilation unit.
  ///
  /// The list of [declarations] can be `null` if there are no declarations in
  /// the compilation unit.
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

  @experimental
  @override
  LibraryFragment? get declaredFragment => declaredElement as LibraryFragment?;

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
    var endToken = this.endToken;
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

  /// Whether all of the directives are lexically before any declarations.
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

sealed class CompilationUnitMemberImpl extends DeclarationImpl
    implements CompilationUnitMember {
  /// Initializes a newly created compilation unit member.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the member
  /// doesn't have the corresponding attribute.
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
  /// The element that is used to read the value, or `null` if this node isn't a
  /// compound assignment, if the AST structure hasn't been resolved, or if the
  /// target couldn't be resolved.
  ///
  /// In valid code this element can be a [LocalVariableElement], a
  /// [ParameterElement], or a [PropertyAccessorElement] getter.
  ///
  /// In invalid code this element is `null`. For example, in `int += 2`, for
  /// recovery purposes, [writeElement] is filled, and can be used for
  /// navigation.
  Element? get readElement;

  /// The element that is used to read the value.
  ///
  /// Returns `null` if this node isn't a compound assignment, if the AST
  /// structure hasn't been resolved, or if the target couldn't be resolved.
  ///
  /// In valid code this element can be a [LocalVariableElement2], a
  /// [FormalParameterElement], or a [GetterElement].
  ///
  /// In invalid code this element is `null`. For example, in `int += 2`. In
  /// such cases, for recovery purposes, [writeElement] is filled, and can be
  /// used for navigation.
  @experimental
  Element2? get readElement2;

  /// The type of the value read with the [readElement], or `null` if this node
  /// isn't a compound assignment.
  ///
  /// Returns the type `dynamic` if the code is invalid, if the AST structure
  /// hasn't been resolved, or if the target couldn't be resolved.
  DartType? get readType;

  /// The element that is used to write the result, or `null` if the AST
  /// structure hasn't been resolved, or if the target couldn't be resolved.
  ///
  /// In valid code this is a [LocalVariableElement], [ParameterElement], or a
  /// [PropertyAccessorElement] setter.
  ///
  /// In invalid code, for recovery, we might use other elements, for example a
  /// [PropertyAccessorElement] getter `myGetter = 0` even though the getter
  /// can't be used to write a value. We do this to help the user to navigate
  /// to the getter, and maybe add the corresponding setter.
  ///
  /// If this node is a compound assignment, e. g. `x += 2`, both [readElement]
  /// and [writeElement] could be non-`null`.
  Element? get writeElement;

  /// The element that is used to write the result.
  ///
  /// Returns `null` if the AST structure hasn't been resolved, or if the target
  /// couldn't be resolved.
  ///
  /// In valid code this is a [LocalVariableElement2], [FormalParameterElement],
  /// or a [SetterElement].
  ///
  /// In invalid code, for recovery, we might use other elements, for example a
  /// [GetterElement] `myGetter = 0` even though the getter can't be used to set
  /// a value. We do this to help the user to navigate to the getter, and maybe
  /// add the corresponding setter.
  ///
  /// If this node is a compound assignment, such as `x += y`, both
  /// [readElement] and [writeElement] could be non-`null`.
  @experimental
  Element2? get writeElement2;

  /// The type of the target of the assignment.
  ///
  /// The types of assigned values must be subtypes of this type.
  ///
  /// If the target couldn't be resolved, this type is `dynamic`.
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

  @experimental
  @override
  Element2? get readElement2 {
    if (readElement is Fragment) {
      return (readElement as Fragment).element;
    } else if (readElement is Element2) {
      return readElement as Element2;
    }
    return null;
  }

  @experimental
  @override
  Element2? get writeElement2 => writeElement.asElement2;
}

/// A conditional expression.
///
///    conditionalExpression ::=
///        [Expression] '?' [Expression] ':' [Expression]
abstract final class ConditionalExpression implements Expression {
  /// The token used to separate the then expression from the else expression.
  Token get colon;

  /// The condition used to determine which of the expressions is executed next.
  Expression get condition;

  /// The expression that is executed if the condition evaluates to `false`.
  Expression get elseExpression;

  /// The token used to separate the condition from the then expression.
  Token get question;

  /// The expression that is executed if the condition evaluates to `true`.
  Expression get thenExpression;
}

final class ConditionalExpressionImpl extends ExpressionImpl
    implements ConditionalExpression {
  ExpressionImpl _condition;

  @override
  final Token question;

  ExpressionImpl _thenExpression;

  @override
  final Token colon;

  ExpressionImpl _elseExpression;

  /// Initializes a newly created conditional expression.
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
  /// The token for the equal operator, or `null` if the condition doesn't
  /// include an equality test.
  Token? get equalToken;

  /// The token for the `if` keyword.
  Token get ifKeyword;

  /// The token for the left parenthesis.
  Token get leftParenthesis;

  /// The name of the declared variable whose value is being used in the
  /// condition.
  DottedName get name;

  /// The result of resolving [uri].
  DirectiveUri? get resolvedUri;

  /// The token for the right parenthesis.
  Token get rightParenthesis;

  /// The URI of the implementation library to be used if the condition is
  /// `true`.
  StringLiteral get uri;

  /// The value to which the value of the declared variable is compared, or
  /// `null` if the condition doesn't include an equality test.
  StringLiteral? get value;
}

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
/// the expression isn't one of the valid alternatives.
///
///    constantPattern ::=
///        'const'? [Expression]
abstract final class ConstantPattern implements DartPattern {
  /// The `const` keyword, or `null` if the expression isn't preceded by the
  /// keyword `const`.
  Token? get constKeyword;

  /// The constant expression being used as a pattern.
  Expression get expression;
}

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
    return resolverVisitor
        .analyzeConstantPatternSchema()
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult<DartType> resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    inferenceLogWriter?.enterPattern(this);
    var analysisResult =
        resolverVisitor.analyzeConstantPattern(context, this, expression);
    expression = resolverVisitor.popRewrite()!;
    inferenceLogWriter?.exitPattern(this);
    return analysisResult;
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
///        [SimpleIdentifier] ('.' name)?
///
///    factoryName ::=
///        [Identifier] ('.' [SimpleIdentifier])?
///
///    initializerList ::=
///        ':' [ConstructorInitializer] (',' [ConstructorInitializer])*
abstract final class ConstructorDeclaration
    implements ClassMember, _FragmentDeclaration {
  /// The `augment` keyword, or `null` if the keyword was absent.
  Token? get augmentKeyword;

  /// The body of the constructor.
  FunctionBody get body;

  /// The token for the `const` keyword, or `null` if the constructor isn't a
  /// const constructor.
  Token? get constKeyword;

  @override
  ConstructorElement? get declaredElement;

  @experimental
  @override
  ConstructorFragment? get declaredFragment;

  /// The token for the `external` keyword to the given [token].
  Token? get externalKeyword;

  /// The token for the `factory` keyword, or `null` if the constructor isn't a
  /// factory constructor.
  Token? get factoryKeyword;

  /// The initializers associated with the constructor.
  NodeList<ConstructorInitializer> get initializers;

  /// The name of the constructor, or `null` if the constructor being declared
  /// is unnamed.
  Token? get name;

  /// The parameters associated with the constructor.
  FormalParameterList get parameters;

  /// The token for the period before the constructor name, or `null` if the
  /// constructor being declared is unnamed.
  Token? get period;

  /// The name of the constructor to which this constructor is redirected, or
  /// `null` if this isn't a redirecting factory constructor.
  ConstructorName? get redirectedConstructor;

  /// The type of object being created.
  ///
  /// This can be different than the type in which the constructor is being
  /// declared if the constructor is the implementation of a factory
  /// constructor.
  Identifier get returnType;

  /// The token for the separator (colon or equals) before the initializer list
  /// or redirection, or `null` if there are neither initializers nor a
  /// redirection.
  Token? get separator;
}

final class ConstructorDeclarationImpl extends ClassMemberImpl
    implements ConstructorDeclaration {
  @override
  final Token? augmentKeyword;

  @override
  final Token? externalKeyword;

  @override
  Token? constKeyword;

  @override
  final Token? factoryKeyword;

  IdentifierImpl _returnType;

  @override
  final Token? period;

  @override
  final Token? name;

  FormalParameterListImpl _parameters;

  @override
  Token? separator;

  final NodeListImpl<ConstructorInitializerImpl> _initializers =
      NodeListImpl._();

  ConstructorNameImpl? _redirectedConstructor;

  FunctionBodyImpl _body;

  @override
  ConstructorElementImpl? declaredElement;

  /// Initializes a newly created constructor declaration.
  ///
  /// The [externalKeyword] can be `null` if the constructor isn't external.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// constructor doesn't have the corresponding attribute.
  ///
  /// The [constKeyword] can be `null` if the constructor can't be used to
  /// create a constant.
  ///
  /// The [factoryKeyword] can be `null` if the constructor isn't a factory.
  ///
  /// The [period] and [name] can both be `null` if the constructor isn't a
  /// named constructor.
  ///
  /// The [separator] can be `null` if the constructor doesn't have any
  /// initializers and doesn't redirect to a different constructor.
  ///
  /// The list of [initializers] can be `null` if the constructor doesn't have
  /// any initializers.
  ///
  /// The [redirectedConstructor] can be `null` if the constructor doesn't
  /// redirect to a different constructor.
  ///
  /// The [body] can be `null` if the constructor doesn't have a body.
  ConstructorDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
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

  @experimental
  @override
  ConstructorFragment? get declaredFragment =>
      declaredElement as ConstructorFragment;

  @override
  Token get endToken {
    return _body.endToken;
  }

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return Token.lexicallyFirst(
            externalKeyword, constKeyword, factoryKeyword, augmentKeyword) ??
        _returnType.beginToken;
  }

  @override
  NodeListImpl<ConstructorInitializerImpl> get initializers => _initializers;

  /// Whether this is a trivial constructor.
  ///
  /// A trivial constructor is a generative constructor that isn't a redirecting
  /// constructor, declares no parameters, has no initializer list, has no body,
  /// and isn't external.
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
    ..addToken('augmentKeyword', augmentKeyword)
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
  /// The token for the equal sign between the field name and the expression.
  Token get equals;

  /// The expression computing the value to which the field is initialized.
  Expression get expression;

  /// The name of the field being initialized.
  SimpleIdentifier get fieldName;

  /// The token for the period after the `this` keyword, or `null` if there's no
  /// `this` keyword.
  Token? get period;

  /// The token for the `this` keyword, or `null` if there's no `this` keyword.
  Token? get thisKeyword;
}

final class ConstructorFieldInitializerImpl extends ConstructorInitializerImpl
    implements ConstructorFieldInitializer {
  @override
  final Token? thisKeyword;

  @override
  final Token? period;

  SimpleIdentifierImpl _fieldName;

  @override
  final Token equals;

  ExpressionImpl _expression;

  /// Initializes a newly created field initializer to initialize the field with
  /// the given name to the value of the given expression.
  ///
  /// The [thisKeyword] and [period] can be `null` if the `this` keyword isn't
  /// specified.
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
    if (thisKeyword case var thisKeyword?) {
      return thisKeyword;
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

sealed class ConstructorInitializerImpl extends AstNodeImpl
    implements ConstructorInitializer {}

/// The name of a constructor.
///
///    constructorName ::=
///        type ('.' identifier)?
abstract final class ConstructorName
    implements AstNode, ConstructorReferenceNode {
  /// The name of the constructor, or `null` if the specified constructor is the
  /// unnamed constructor and the name `new` wasn't explicitly used.
  SimpleIdentifier? get name;

  /// The token for the period before the constructor name, or `null` if the
  /// specified constructor is the unnamed constructor.
  Token? get period;

  /// The name of the type defining the constructor.
  NamedType get type;
}

final class ConstructorNameImpl extends AstNodeImpl implements ConstructorName {
  NamedTypeImpl _type;

  @override
  Token? period;

  SimpleIdentifierImpl? _name;

  @override
  ConstructorElement? staticElement;

  /// Initializes a newly created constructor name.
  ///
  /// The [period] and [name] can be `null` if the constructor being named is
  /// the unnamed constructor.
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

  @experimental
  @override
  ConstructorElement2? get element =>
      staticElement?.asElement2 as ConstructorElement2?;

  @override
  Token get endToken {
    if (name case var name?) {
      return name.endToken;
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

/// An expression representing a reference to a constructor.
///
/// For example, the expression `List.filled` in `var x = List.filled;`.
///
/// Objects of this type aren't produced directly by the parser (because the
/// parser can't tell whether an identifier refers to a type); they are
/// produced at resolution time.
abstract final class ConstructorReference
    implements Expression, CommentReferableExpression {
  /// The constructor being referenced.
  ConstructorName get constructorName;
}

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
  /// The element associated with the referenced constructor based on static
  /// type information.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if the
  /// constructor couldn't be resolved.
  @experimental
  ConstructorElement2? get element;

  /// The element associated with the referenced constructor based on static
  /// type information, or `null` if the AST structure hasn't been resolved or
  /// if the constructor couldn't be resolved.
  ConstructorElement? get staticElement;
}

/// The name of a constructor being invoked.
///
///    constructorSelector ::=
///        '.' identifier
abstract final class ConstructorSelector implements AstNode {
  /// The constructor name.
  SimpleIdentifier get name;

  /// The period before the constructor name.
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
  /// The token representing the `continue` keyword.
  Token get continueKeyword;

  /// The label associated with the statement, or `null` if there's no label.
  SimpleIdentifier? get label;

  /// The semicolon terminating the statement.
  Token get semicolon;

  /// The node to which this continue statement is continuing, or `null` if the
  /// AST hasn't yet been resolved or if the target couldn't be resolved.
  ///
  /// This is either a [Statement] (in the case of continuing a loop), or a
  /// [SwitchMember] (in the case of continuing from one switch case to
  /// another).
  ///
  /// Note that if the source code has errors, the target might be invalid.
  /// For example, the target might be in an enclosing function.
  AstNode? get target;
}

final class ContinueStatementImpl extends StatementImpl
    implements ContinueStatement {
  @override
  final Token continueKeyword;

  SimpleIdentifierImpl? _label;

  @override
  final Token semicolon;

  @override
  AstNode? target;

  /// Initializes a newly created continue statement.
  ///
  /// The [label] can be `null` if there's no label associated with the
  /// statement.
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
  /// The matched value type, or `null` if the node isn't resolved yet.
  DartType? get matchedValueType;

  /// The precedence of this pattern.
  ///
  /// The precedence is a positive integer value that defines how the source
  /// code is parsed into an AST. For example `a | b & c` is parsed as `a | (b
  /// & c)` because the precedence of `&` is greater than the precedence of `|`.
  PatternPrecedence get precedence;

  /// If this pattern is a parenthesized pattern, the result of unwrapping the
  /// pattern inside the parentheses. Otherwise, this pattern.
  DartPattern get unParenthesized;
}

sealed class DartPatternImpl extends AstNodeImpl
    implements DartPattern, ListPatternElementImpl {
  @override
  DartType? matchedValueType;

  /// The context for this pattern.
  ///
  /// The possible contexts are
  /// - Declaration context:
  ///     [ForEachPartsWithPatternImpl]
  ///     [PatternVariableDeclarationImpl]
  /// - Assignment context: [PatternAssignmentImpl]
  /// - Matching context: [GuardedPatternImpl]
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

  /// Dispatches this pattern to the [resolver], with the given [context]
  /// information.
  ///
  /// Note: most code shouldn't call this method directly, but should instead
  /// call [ResolverVisitor.dispatchPattern], which has some special logic for
  /// handling dynamic contexts.
  PatternResult<DartType> resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  );
}

/// A node that represents the declaration of one or more names.
///
/// Each declared name is visible within a name scope.
abstract final class Declaration implements AnnotatedNode {
  /// The element associated with this declaration, or `null` if either this
  /// node corresponds to a list of declarations or if the AST structure hasn't
  /// been resolved.
  Element? get declaredElement;
}

sealed class DeclarationImpl extends AnnotatedNodeImpl implements Declaration {
  /// Initializes a newly created declaration.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// declaration doesn't have the corresponding attribute.
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

  /// The element associated with this declaration.
  ///
  /// Returns `null` if either this node corresponds to a list of declarations
  /// or if the AST structure hasn't been resolved.
  @experimental
  LocalVariableElement2? get declaredElement2;

  /// Whether this variable was declared with the 'const' modifier.
  bool get isConst;

  /// Whether this variable was declared with the 'final' modifier.
  ///
  /// Returns `false` for variables that are declared with the 'const' modifier
  /// even though they are implicitly final.
  bool get isFinal;

  /// The token representing either the `final`, `const` or `var` keyword, or
  /// `null` if no keyword was used.
  Token? get keyword;

  /// The name of the variable being declared.
  Token get name;

  /// The name of the declared type of the parameter, or `null` if the parameter
  /// doesn't have a declared type.
  TypeAnnotation? get type;
}

final class DeclaredIdentifierImpl extends DeclarationImpl
    implements DeclaredIdentifier {
  @override
  final Token? keyword;

  TypeAnnotationImpl? _type;

  @override
  final Token name;

  @override
  LocalVariableElementImpl? declaredElement;

  /// Initializes a newly created formal parameter.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// declaration doesn't have the corresponding attribute.
  ///
  /// The [keyword] can be `null` if a type name is given.
  ///
  /// The [type] must be `null` if the keyword is `var`.
  DeclaredIdentifierImpl({
    required super.comment,
    required super.metadata,
    required this.keyword,
    required TypeAnnotationImpl? type,
    required this.name,
  }) : _type = type {
    _becomeParentOf(_type);
  }

  @experimental
  @override
  LocalVariableElement2? get declaredElement2 {
    return declaredElement.asElement2 as LocalVariableElementImpl2?;
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
  /// The element associated with this declaration, or `null` if the AST
  /// structure hasn't been resolved.
  BindPatternVariableElement? get declaredElement;

  /// The element declared by this declaration.
  ///
  /// Returns `null` if the AST structure hasn't been resolved.
  @experimental
  BindPatternVariableElement2? get declaredElement2;

  /// The `var` or `final` keyword.
  Token? get keyword;

  /// The type that the variable is required to match, or `null` if any type is
  /// matched.
  TypeAnnotation? get type;
}

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

  @experimental
  @override
  BindPatternVariableElement2? get declaredElement2 {
    return declaredElement?.element2;
  }

  @override
  Token get endToken => name;

  /// The `final` keyword, or `null` if the `final` keyword isn't used.
  Token? get finalKeyword {
    var keyword = this.keyword;
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
        .analyzeDeclaredVariablePatternSchema(
            type?.typeOrThrow.wrapSharedTypeView())
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult<DartType> resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    inferenceLogWriter?.enterPattern(this);
    var result = resolverVisitor.analyzeDeclaredVariablePattern(
        context,
        this,
        declaredElement!,
        declaredElement!.name,
        type?.typeOrThrow.wrapSharedTypeView());
    declaredElement!.type = result.staticType.unwrapTypeView();

    resolverVisitor.checkPatternNeverMatchesValueType(
      context: context,
      pattern: this,
      requiredType: result.staticType.unwrapTypeView(),
      matchedValueType: result.matchedValueType.unwrapTypeView(),
    );
    inferenceLogWriter?.exitPattern(this);

    return result;
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
  /// The expression computing the default value for the parameter, or `null` if
  /// there's no default value.
  Expression? get defaultValue;

  /// The formal parameter with which the default value is associated.
  NormalFormalParameter get parameter;

  /// The token separating the parameter from the default value, or `null` if
  /// there's no default value.
  Token? get separator;
}

final class DefaultFormalParameterImpl extends FormalParameterImpl
    implements DefaultFormalParameter {
  NormalFormalParameterImpl _parameter;

  @override
  ParameterKind kind;

  @override
  final Token? separator;

  ExpressionImpl? _defaultValue;

  /// Initializes a newly created default formal parameter.
  ///
  /// The [separator] and [defaultValue] can be `null` if there's no default
  /// value.
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

  @experimental
  @override
  FormalParameterFragment? get declaredFragment => _parameter.declaredFragment;

  @override
  ExpressionImpl? get defaultValue => _defaultValue;

  set defaultValue(ExpressionImpl? expression) {
    _defaultValue = _becomeParentOf(expression);
  }

  @override
  Token get endToken {
    if (defaultValue case var defaultValue?) {
      return defaultValue.endToken;
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
  /// The element associated with this directive, or `null` if the AST structure
  /// hasn't been resolved or if this directive couldn't be resolved.
  Element? get element;
}

sealed class DirectiveImpl extends AnnotatedNodeImpl implements Directive {
  ElementImpl? _element;

  /// Initializes a newly create directive.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// directive doesn't have the corresponding attribute.
  DirectiveImpl({
    required super.comment,
    required super.metadata,
  });

  @override
  ElementImpl? get element => _element;

  set element(ElementImpl? element) {
    _element = element;
  }
}

/// A do statement.
///
///    doStatement ::=
///        'do' [Statement] 'while' '(' [Expression] ')' ';'
abstract final class DoStatement implements Statement {
  /// The body of the loop.
  Statement get body;

  /// The condition that determines when the loop terminates.
  Expression get condition;

  /// The token representing the `do` keyword.
  Token get doKeyword;

  /// The left parenthesis.
  Token get leftParenthesis;

  /// The right parenthesis.
  Token get rightParenthesis;

  /// The semicolon terminating the statement.
  Token get semicolon;

  /// The token representing the `while` keyword.
  Token get whileKeyword;
}

final class DoStatementImpl extends StatementImpl implements DoStatement {
  @override
  final Token doKeyword;

  StatementImpl _body;

  @override
  final Token whileKeyword;

  @override
  final Token leftParenthesis;

  ExpressionImpl _condition;

  @override
  final Token rightParenthesis;

  @override
  final Token semicolon;

  /// Initializes a newly created do loop.
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
  /// The components of the identifier.
  NodeList<SimpleIdentifier> get components;
}

final class DottedNameImpl extends AstNodeImpl implements DottedName {
  final NodeListImpl<SimpleIdentifierImpl> _components = NodeListImpl._();

  /// Initializes a newly created dotted name.
  ///
  /// The list of [components] must contain at least one element.
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
  /// The token representing the literal.
  Token get literal;

  /// The value of the literal.
  double get value;
}

final class DoubleLiteralImpl extends LiteralImpl implements DoubleLiteral {
  @override
  final Token literal;

  @override
  double value;

  /// Initializes a newly created floating point literal.
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

/// An empty function body.
///
/// An empty function body can only appear in constructors or abstract methods.
///
///    emptyFunctionBody ::=
///        ';'
abstract final class EmptyFunctionBody implements FunctionBody {
  /// The token representing the semicolon that marks the end of the function
  /// body.
  Token get semicolon;
}

final class EmptyFunctionBodyImpl extends FunctionBodyImpl
    implements EmptyFunctionBody {
  @override
  final Token semicolon;

  /// Initializes a newly created function body.
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
  /// The semicolon terminating the statement.
  Token get semicolon;
}

final class EmptyStatementImpl extends StatementImpl implements EmptyStatement {
  @override
  final Token semicolon;

  /// Initializes a newly created empty statement.
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
  /// The explicit arguments (there are always implicit `index` and `name`
  /// leading arguments) to the invoked constructor.
  ArgumentList get argumentList;

  /// The selector of the constructor that is invoked by this enum constant, or
  /// `null` if the default constructor is invoked.
  ConstructorSelector? get constructorSelector;

  /// The type arguments applied to the enclosing enum declaration when invoking
  /// the constructor, or `null` if no type arguments were provided.
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
abstract final class EnumConstantDeclaration implements _FragmentDeclaration {
  /// The explicit arguments (there are always implicit `index` and `name`
  /// leading arguments) to the invoked constructor, or `null` if this constant
  /// doesn't provide any explicit arguments.
  EnumConstantArguments? get arguments;

  /// The `augment` keyword, or `null` if the keyword was absent.
  @experimental
  Token? get augmentKeyword;

  /// The constructor that is invoked by this enum constant, or `null` if the
  /// AST structure hasn't been resolved, or if the constructor couldn't be
  /// resolved.
  ConstructorElement? get constructorElement;

  /// The constructor that's invoked by this enum constant.
  ///
  /// Returns `null` if the AST structure hasn't been resolved, or if the
  /// constructor couldn't be resolved.
  @experimental
  ConstructorElement2? get constructorElement2;

  @override
  FieldElement? get declaredElement;

  @experimental
  @override
  FieldFragment? get declaredFragment;

  /// The name of the constant.
  Token get name;
}

final class EnumConstantDeclarationImpl extends DeclarationImpl
    implements EnumConstantDeclaration {
  @override
  final Token? augmentKeyword;

  @override
  final Token name;

  @override
  FieldElementImpl? declaredElement;

  @override
  final EnumConstantArgumentsImpl? arguments;

  @override
  ConstructorElement? constructorElement;

  /// Initializes a newly created enum constant declaration.
  ///
  /// Either or both of the [documentationComment] and [metadata] can be `null`
  /// if the constant doesn't have the corresponding attributes.
  EnumConstantDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
    required this.name,
    required this.arguments,
  }) {
    _becomeParentOf(arguments);
  }

  @experimental
  @override
  ConstructorElement2? get constructorElement2 =>
      constructorElement?.asElement2 as ConstructorElement2?;

  @experimental
  @override
  FieldFragment? get declaredFragment => declaredElement as FieldFragment?;

  @override
  Token get endToken => arguments?.endToken ?? name;

  @override
  Token get firstTokenAfterCommentAndMetadata => augmentKeyword ?? name;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('augmentKeyword', augmentKeyword)
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
abstract final class EnumDeclaration
    implements NamedCompilationUnitMember, _FragmentDeclaration {
  /// The `augment` keyword, or `null` if the keyword was absent.
  @experimental
  Token? get augmentKeyword;

  /// The enumeration constants being declared.
  NodeList<EnumConstantDeclaration> get constants;

  @override
  EnumElement? get declaredElement;

  @experimental
  @override
  EnumFragment? get declaredFragment;

  /// The `enum` keyword.
  Token get enumKeyword;

  /// The `implements` clause for the enumeration, or `null` if the enumeration
  /// doesn't implement any interfaces.
  ImplementsClause? get implementsClause;

  /// The left curly bracket.
  Token get leftBracket;

  /// The members declared by the enumeration.
  NodeList<ClassMember> get members;

  /// The right curly bracket.
  Token get rightBracket;

  /// The optional semicolon after the last constant.
  Token? get semicolon;

  /// The type parameters for the enumeration, or `null` if the enumeration
  /// doesn't have any type parameters.
  TypeParameterList? get typeParameters;

  /// The `with` clause for the enumeration, or `null` if the enumeration
  /// doesn't have a `with` clause.
  WithClause? get withClause;
}

final class EnumDeclarationImpl extends NamedCompilationUnitMemberImpl
    with AstNodeWithNameScopeMixin
    implements EnumDeclaration {
  @override
  final Token? augmentKeyword;

  @override
  final Token enumKeyword;

  TypeParameterListImpl? _typeParameters;

  WithClauseImpl? _withClause;

  ImplementsClauseImpl? _implementsClause;

  @override
  final Token leftBracket;

  final NodeListImpl<EnumConstantDeclarationImpl> _constants = NodeListImpl._();

  @override
  final Token? semicolon;

  final NodeListImpl<ClassMemberImpl> _members = NodeListImpl._();

  @override
  final Token rightBracket;

  @override
  EnumElementImpl? declaredElement;

  /// Initializes a newly created enumeration declaration.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// declaration doesn't have the corresponding attribute.
  ///
  /// The list of [constants] must contain at least one value.
  EnumDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
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

  @experimental
  @override
  EnumFragment? get declaredFragment => declaredElement as EnumFragment?;

  @override
  Token get endToken => rightBracket;

  @override
  Token get firstTokenAfterCommentAndMetadata => augmentKeyword ?? enumKeyword;

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
  // TODO(brianwilkerson): Add commas?
  ChildEntities get _childEntities => super._childEntities
    ..addToken('augmentKeyword', augmentKeyword)
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
  /// The element associated with this directive, or `null` if the AST structure
  /// hasn't been resolved.
  @override
  LibraryExportElement? get element;

  /// The token representing the `export` keyword.
  Token get exportKeyword;

  /// Information about this export directive.
  ///
  /// Returns `null` if the AST structure hasn't been resolved.
  @experimental
  LibraryExport? get libraryExport;
}

final class ExportDirectiveImpl extends NamespaceDirectiveImpl
    implements ExportDirective {
  @override
  final Token exportKeyword;

  /// Initializes a newly created export directive.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// directive doesn't have the corresponding attribute.
  ///
  /// The list of [combinators] can be `null` if there are no combinators.
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

  @experimental
  @override
  LibraryExport? get libraryExport => element as LibraryExport?;

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
  /// The parameter element representing the parameter to which the value of
  /// this expression is bound.
  ///
  /// Returns `null` if any of these conditions are false:
  /// - this expression is an argument to an invocation
  /// - the AST structure has been resolved
  /// - the function being invoked is known based on static type information
  /// - this expression corresponds to one of the parameters of the function
  ///   being invoked
  @experimental
  FormalParameterElement? get correspondingParameter;

  /// Whether this expression is in a constant context.
  ///
  /// An expression _e_ is said to _occur in a constant context_,
  /// - if _e_ is an element of a constant list literal, or a key or value of an
  ///   entry of a constant map literal.
  /// - if _e_ is an actual argument of a constant object expression or of a
  ///   metadata annotation.
  /// - if _e_ is the initializing expression of a constant variable
  ///   declaration.
  /// - if _e_ is a switch case expression.
  /// - if _e_ is an immediate subexpression of an expression _e1_ which occurs
  ///   in a constant context, unless _e1_ is a `throw` expression or a function
  ///   literal.
  ///
  /// This roughly means that everything which is inside a syntactically
  /// constant expression is in a constant context. A `throw` expression is
  /// currently not allowed in a constant expression, but extensions affecting
  /// that status might be considered. A similar situation arises for function
  /// literals.
  ///
  /// Note that the default value of an optional formal parameter is _not_ a
  /// constant context. This choice reserves some freedom to modify the
  /// semantics of default values.
  bool get inConstantContext;

  /// Whether this expression is syntactically valid for the LHS of an
  /// [AssignmentExpression].
  bool get isAssignable;

  /// The precedence of this expression.
  ///
  /// The precedence is a positive integer value that defines how the source
  /// code is parsed into an AST. For example `a * b + c` is parsed as
  /// `(a * b) + c` because the precedence of `*` is greater than the precedence
  /// of `+`.
  Precedence get precedence;

  /// The parameter element representing the parameter to which the value of
  /// this expression is bound, or `null` if any of these conditions are not
  /// `true`
  /// - this expression is an argument to an invocation
  /// - the AST structure is resolved
  /// - the function being invoked is known based on static type information
  /// - this expression corresponds to one of the parameters of the function
  ///   being invoked
  ParameterElement? get staticParameterElement;

  /// The static type of this expression, or `null` if the AST structure hasn't
  /// been resolved.
  DartType? get staticType;

  /// If this expression is a parenthesized expression, returns the result of
  /// unwrapping the expression inside the parentheses. Otherwise, returns this
  /// expression.
  Expression get unParenthesized;
}

/// A function body consisting of a single expression.
///
///    expressionFunctionBody ::=
///        'async'? '=>' [Expression] ';'
abstract final class ExpressionFunctionBody implements FunctionBody {
  /// The expression representing the body of the function.
  Expression get expression;

  /// The token introducing the expression that represents the body of the
  /// function.
  Token get functionDefinition;

  /// The token representing the `async` keyword, or `null` if there's no such
  /// keyword.
  @override
  Token? get keyword;

  /// The semicolon terminating the statement.
  Token? get semicolon;

  /// The star following the `async` keyword, or `null` if there's no star.
  ///
  /// It's an error for an expression function body to feature the star, but
  /// the parser accepts it.
  @override
  Token? get star;
}

final class ExpressionFunctionBodyImpl extends FunctionBodyImpl
    with AstNodeWithNameScopeMixin
    implements ExpressionFunctionBody {
  @override
  final Token? keyword;

  @override
  final Token? star;

  @override
  final Token functionDefinition;

  ExpressionImpl _expression;

  @override
  final Token? semicolon;

  /// Initializes a newly created function body consisting of a block of
  /// statements.
  ///
  /// The [keyword] can be `null` if the function body isn't an async function
  /// body.
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
    if (keyword case var keyword?) {
      return keyword;
    }
    return functionDefinition;
  }

  @override
  Token get endToken {
    if (semicolon case var semicolon?) {
      return semicolon;
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

sealed class ExpressionImpl extends AstNodeImpl
    implements CollectionElementImpl, Expression {
  DartType? _staticType;

  @experimental
  @override
  FormalParameterElement? get correspondingParameter {
    if (staticParameterElement case FormalParameterFragment fragment) {
      return fragment.element;
    }
    return null;
  }

  @override
  bool get inConstantContext {
    return constantContext(includeSelf: false) != null;
  }

  @override
  bool get isAssignable => false;

  @override
  ParameterElement? get staticParameterElement {
    var parent = this.parent;
    if (parent is ArgumentListImpl) {
      return parent._getStaticParameterElementFor(this);
    } else if (parent is IndexExpressionImpl) {
      if (identical(parent.index, this)) {
        return parent._staticParameterElementForIndex;
      }
    } else if (parent is BinaryExpressionImpl) {
      // TODO(scheglov): https://github.com/dart-lang/sdk/issues/49102
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
      // TODO(scheglov): This doesn't look right, there's no element for
      // the operand, for `a++` we invoke `a = a + 1`, so the parameter
      // is for `1`, not for `a`.
      return parent._staticParameterElementForOperand;
    } else if (parent is PostfixExpressionImpl) {
      // TODO(scheglov): The same as above.
      return parent._staticParameterElementForOperand;
    }
    return null;
  }

  @override
  DartType? get staticType => _staticType;

  @override
  ExpressionImpl get unParenthesized => this;

  /// Returns the [AstNode] that puts node into the constant context, and
  /// the explicit `const` keyword of that node. The keyword might be absent
  /// if the constness is implicit.
  ///
  /// Returns `null` if node is not in the constant context.
  (AstNode, Token?)? constantContext({
    required bool includeSelf,
  }) {
    AstNode? current = this;
    if (!includeSelf) {
      current = current.parent;
    }

    while (true) {
      switch (current) {
        case Annotation():
          return (current, null);
        case ConstantContextForExpressionImpl():
          return (current, null);
        case ConstantPatternImpl():
          if (current.constKeyword case var constKeyword?) {
            return (current, constKeyword);
          }
          return null;
        case EnumConstantArguments():
          return (current, null);
        case InstanceCreationExpression():
          var keyword = current.keyword;
          if (keyword != null && keyword.keyword == Keyword.CONST) {
            return (current, keyword);
          }
        case RecordLiteral():
          if (current.constKeyword case var constKeyword?) {
            return (current, constKeyword);
          }
        case SwitchCase():
          return (current, null);
        case TypedLiteralImpl():
          if (current.constKeyword case var constKeyword?) {
            return (current, constKeyword);
          }
        case VariableDeclarationList():
          var keyword = current.keyword;
          if (keyword != null && keyword.keyword == Keyword.CONST) {
            return (current, keyword);
          }
          return null;
        case ArgumentList():
        case Expression():
        case IfElement():
        case ForElement():
        case MapLiteralEntry():
        case SpreadElement():
        case VariableDeclaration():
          break;
        default:
          return null;
      }
      current = current?.parent;
    }
  }

  /// Record that the static type of the given node is the given type.
  ///
  /// @param expression the node whose type is to be recorded
  /// @param type the static type of the node
  void recordStaticType(DartType type, {required ResolverVisitor resolver}) {
    _staticType = type;
    if (type.isBottom) {
      resolver.flowAnalysis.flow?.handleExit();
    }
    inferenceLogWriter?.recordStaticType(this, type);
  }

  @override
  void resolveElement(
      ResolverVisitor resolver, CollectionLiteralContext? context) {
    resolver.analyzeExpression(
        this,
        SharedTypeSchemaView(
            context?.elementType ?? UnknownInferredType.instance));
  }

  /// Dispatches this expression to the [resolver], with the given [contextType]
  /// information.
  ///
  /// Note: most code shouldn't call this method directly, but should instead
  /// call [ResolverVisitor.dispatchExpression], which has some special logic
  /// for handling dynamic contexts.
  void resolveExpression(ResolverVisitor resolver, DartType contextType);

  /// Records that the static type of `this` is [type], without triggering any
  /// [ResolverVisitor] behaviors.
  ///
  /// This is used when the expression AST node occurs in a place where it is
  /// not technically a true expression, but the analyzer chooses to assign it a
  /// static type anyway (e.g. the [SimpleIdentifier] representing the method
  /// name in a method invocation).
  void setPseudoExpressionStaticType(DartType? type) {
    _staticType = type;
  }
}

/// An expression used as a statement.
///
///    expressionStatement ::=
///        [Expression]? ';'
abstract final class ExpressionStatement implements Statement {
  /// The expression that comprises the statement.
  Expression get expression;

  /// The semicolon terminating the statement, or `null` if the expression is a
  /// function expression and therefore isn't followed by a semicolon.
  Token? get semicolon;
}

final class ExpressionStatementImpl extends StatementImpl
    implements ExpressionStatement {
  ExpressionImpl _expression;

  @override
  final Token? semicolon;

  /// Initializes a newly created expression statement.
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
    if (semicolon case var semicolon?) {
      return semicolon;
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
  /// The token representing the `extends` keyword.
  Token get extendsKeyword;

  /// The name of the class that is being extended.
  NamedType get superclass;
}

final class ExtendsClauseImpl extends AstNodeImpl implements ExtendsClause {
  @override
  final Token extendsKeyword;

  NamedTypeImpl _superclass;

  /// Initializes a newly created extends clause.
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
abstract final class ExtensionDeclaration
    implements CompilationUnitMember, _FragmentDeclaration {
  /// The `augment` keyword, or `null` if the keyword was absent.
  @experimental
  Token? get augmentKeyword;

  @override
  ExtensionElement? get declaredElement;

  @experimental
  @override
  ExtensionFragment? get declaredFragment;

  /// The type that is being extended.
  @Deprecated('Use onClause instead')
  TypeAnnotation get extendedType;

  /// The token representing the `extension` keyword.
  Token get extensionKeyword;

  /// The left curly bracket.
  Token get leftBracket;

  /// The members being added to the extended class.
  NodeList<ClassMember> get members;

  /// The name of the extension, or `null` if the extension doesn't have a name.
  Token? get name;

  /// The `on` clause, `null` if an augmentation.
  ExtensionOnClause? get onClause;

  /// The token representing the 'on' keyword.
  @Deprecated('Use onClause instead')
  Token get onKeyword;

  /// The right curly bracket.
  Token get rightBracket;

  /// The token representing the `type` keyword.
  Token? get typeKeyword;

  /// The type parameters for the extension, or `null` if the extension doesn't
  /// have any type parameters.
  TypeParameterList? get typeParameters;
}

final class ExtensionDeclarationImpl extends CompilationUnitMemberImpl
    with AstNodeWithNameScopeMixin
    implements ExtensionDeclaration {
  @override
  final Token? augmentKeyword;

  @override
  final Token extensionKeyword;

  @override
  final Token? typeKeyword;

  @override
  final Token? name;

  TypeParameterListImpl? _typeParameters;

  @override
  ExtensionOnClauseImpl? onClause;

  @override
  final Token leftBracket;

  final NodeListImpl<ClassMemberImpl> _members = NodeListImpl._();

  @override
  final Token rightBracket;

  @override
  ExtensionElementImpl? declaredElement;

  ExtensionDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
    required this.extensionKeyword,
    required this.typeKeyword,
    required this.name,
    required TypeParameterListImpl? typeParameters,
    required this.onClause,
    required this.leftBracket,
    required List<ClassMemberImpl> members,
    required this.rightBracket,
  }) : _typeParameters = typeParameters {
    _becomeParentOf(_typeParameters);
    _becomeParentOf(onClause);
    _members._initialize(this, members);
  }

  @experimental
  @override
  ExtensionFragment? get declaredFragment =>
      declaredElement as ExtensionFragment?;

  @override
  Token get endToken => rightBracket;

  @Deprecated('Use onClause instead')
  @override
  TypeAnnotationImpl get extendedType {
    return onClause!.extendedType;
  }

  @override
  Token get firstTokenAfterCommentAndMetadata =>
      augmentKeyword ?? extensionKeyword;

  @override
  NodeListImpl<ClassMemberImpl> get members => _members;

  @Deprecated('Use onClause instead')
  @override
  Token get onKeyword => onClause!.onKeyword;

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('augmentKeyword', augmentKeyword)
    ..addToken('extensionKeyword', extensionKeyword)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addNode('onClause', onClause)
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
    onClause?.accept(visitor);
    _members.accept(visitor);
  }
}

/// The `on` clause in an extension declaration.
///
///    onClause ::= 'on' [TypeAnnotation]
abstract final class ExtensionOnClause implements AstNode {
  /// The extended type.
  TypeAnnotation get extendedType;

  /// The 'on' keyword.
  Token get onKeyword;
}

final class ExtensionOnClauseImpl extends AstNodeImpl
    implements ExtensionOnClause {
  @override
  final Token onKeyword;

  @override
  final TypeAnnotationImpl extendedType;

  ExtensionOnClauseImpl({
    required this.onKeyword,
    required this.extendedType,
  }) {
    _becomeParentOf(extendedType);
  }

  @override
  Token get beginToken => onKeyword;

  @override
  Token get endToken => extendedType.endToken;

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('onKeyword', onKeyword)
    ..addNode('extendedType', extendedType);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitExtensionOnClause(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    extendedType.accept(visitor);
  }
}

/// An override to force resolution to choose a member from a specific
/// extension.
///
///    extensionOverride ::=
///        [Identifier] [TypeArgumentList]? [ArgumentList]
abstract final class ExtensionOverride implements Expression {
  /// The list of arguments to the override.
  ///
  /// In valid code this contains a single argument that evaluates to the object
  /// being extended.
  ArgumentList get argumentList;

  /// The forced extension element.
  ExtensionElement get element;

  /// The extension that resolution will use to resolve member references.
  @experimental
  ExtensionElement2 get element2;

  /// The actual type extended by this override, produced by applying
  /// [typeArgumentTypes] to the generic type extended by the extension, or
  /// `null` if the AST structure hasn't been resolved.
  DartType? get extendedType;

  /// The optional import prefix before [name].
  ImportPrefixReference? get importPrefix;

  /// Whether this override is null aware (as opposed to non-null).
  bool get isNullAware;

  /// The name of the extension being selected.
  Token get name;

  /// The type arguments to be applied to the extension, or `null` if there are
  /// no type arguments.
  TypeArgumentList? get typeArguments;

  /// The actual type arguments to be applied to the extension, either
  /// explicitly specified in [typeArguments], or inferred, or `null` if the AST
  /// structure hasn't been resolved.
  ///
  /// An empty list if the extension doesn't have type arguments.
  List<DartType>? get typeArgumentTypes;
}

final class ExtensionOverrideImpl extends ExpressionImpl
    implements ExtensionOverride {
  @override
  final ImportPrefixReferenceImpl? importPrefix;

  @override
  final Token name;

  @override
  final ExtensionElement element;

  TypeArgumentListImpl? _typeArguments;

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

  @experimental
  @override
  ExtensionElement2 get element2 => (element as ExtensionFragment).element;

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

/// The declaration of an extension type.
///
///    <extensionTypeDeclaration> ::=
///        'extension' 'type' 'const'? <typeIdentifier> <typeParameters>?
///        <representationDeclaration> <interfaces>?
///        '{'
///            (<metadata> <extensionTypeMemberDeclaration>)*
///        '}'
@experimental
abstract final class ExtensionTypeDeclaration
    implements NamedCompilationUnitMember, _FragmentDeclaration {
  /// The `augment` keyword, or `null` if the keyword was absent.
  @experimental
  Token? get augmentKeyword;

  /// The `const` keyword.
  Token? get constKeyword;

  @override
  ExtensionTypeElement? get declaredElement;

  @experimental
  @override
  ExtensionTypeFragment? get declaredFragment;

  /// The `extension` keyword.
  Token get extensionKeyword;

  /// The `implements` clause.
  ImplementsClause? get implementsClause;

  /// The left curly bracket.
  Token get leftBracket;

  /// The members.
  NodeList<ClassMember> get members;

  /// The representation declaration.
  RepresentationDeclaration get representation;

  /// The right curly bracket.
  Token get rightBracket;

  /// The `type` keyword.
  Token get typeKeyword;

  /// The type parameters.
  TypeParameterList? get typeParameters;
}

final class ExtensionTypeDeclarationImpl extends NamedCompilationUnitMemberImpl
    with AstNodeWithNameScopeMixin
    implements ExtensionTypeDeclaration {
  @override
  final Token? augmentKeyword;

  @override
  final Token extensionKeyword;

  @override
  final Token typeKeyword;

  @override
  final Token? constKeyword;

  @override
  final TypeParameterListImpl? typeParameters;

  @override
  final RepresentationDeclarationImpl representation;

  @override
  final ImplementsClauseImpl? implementsClause;

  @override
  final Token leftBracket;

  @override
  final NodeListImpl<ClassMemberImpl> members = NodeListImpl._();

  @override
  final Token rightBracket;

  @override
  ExtensionTypeElementImpl? declaredElement;

  ExtensionTypeDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
    required this.extensionKeyword,
    required this.typeKeyword,
    required this.constKeyword,
    required super.name,
    required this.typeParameters,
    required this.representation,
    required this.implementsClause,
    required this.leftBracket,
    required List<ClassMemberImpl> members,
    required this.rightBracket,
  }) {
    _becomeParentOf(typeParameters);
    _becomeParentOf(representation);
    _becomeParentOf(implementsClause);
    this.members._initialize(this, members);
  }

  @experimental
  @override
  ExtensionTypeFragment? get declaredFragment =>
      declaredElement as ExtensionTypeFragment;

  @override
  Token get endToken => rightBracket;

  @override
  Token get firstTokenAfterCommentAndMetadata =>
      augmentKeyword ?? extensionKeyword;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('augmentKeyword', augmentKeyword)
    ..addToken('extensionKeyword', extensionKeyword)
    ..addToken('typeKeyword', typeKeyword)
    ..addToken('constKeyword', constKeyword)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addNode('representation', representation)
    ..addNode('implementsClause', implementsClause)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('members', members)
    ..addToken('rightBracket', rightBracket);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitExtensionTypeDeclaration(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    typeParameters?.accept(visitor);
    representation.accept(visitor);
    implementsClause?.accept(visitor);
    members.accept(visitor);
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
/// (Note: there's no `<fieldDeclaration>` production in the grammar; this is a
/// subset of the grammar production `<declaration>`, which encompasses
/// everything that can appear inside a class declaration except methods).
abstract final class FieldDeclaration implements ClassMember {
  /// The `abstract` keyword, or `null` if the keyword isn't used.
  Token? get abstractKeyword;

  /// The `augment` keyword, or `null` if the keyword was absent.
  @experimental
  Token? get augmentKeyword;

  /// The `covariant` keyword, or `null` if the keyword isn't used.
  Token? get covariantKeyword;

  /// The `external` keyword, or `null` if the keyword isn't used.
  Token? get externalKeyword;

  /// The fields being declared.
  VariableDeclarationList get fields;

  /// Whether the fields are declared to be static.
  bool get isStatic;

  /// The semicolon terminating the declaration.
  Token get semicolon;

  /// The token representing the `static` keyword, or `null` if the fields
  /// aren't static.
  Token? get staticKeyword;
}

final class FieldDeclarationImpl extends ClassMemberImpl
    implements FieldDeclaration {
  @override
  final Token? abstractKeyword;

  @override
  final Token? augmentKeyword;

  @override
  final Token? covariantKeyword;

  @override
  final Token? externalKeyword;

  @override
  final Token? staticKeyword;

  VariableDeclarationListImpl _fieldList;

  @override
  final Token semicolon;

  /// Initializes a newly created field declaration.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// declaration doesn't have the corresponding attribute.
  ///
  /// The [staticKeyword] can be `null` if the field isn't a static field.
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
    ..addToken('abstractKeyword', abstractKeyword)
    ..addToken('augmentKeyword', augmentKeyword)
    ..addToken('covariantKeyword', covariantKeyword)
    ..addToken('externalKeyword', externalKeyword)
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
///        ('final' [TypeAnnotation] | 'const' [TypeAnnotation] | 'var' |
///        [TypeAnnotation])?
///        'this' '.' name ([TypeParameterList]? [FormalParameterList])?
abstract final class FieldFormalParameter implements NormalFormalParameter {
  /// The token representing either the `final`, `const` or `var` keyword, or
  /// `null` if no keyword was used.
  Token? get keyword;

  @override
  Token get name;

  /// The parameters of the function-typed parameter, or `null` if this isn't a
  /// function-typed field formal parameter.
  FormalParameterList? get parameters;

  /// The token representing the period.
  Token get period;

  /// The question mark indicating that the function type is nullable, or `null`
  /// if there's no question mark, which will always be the case when the
  /// parameter doesn't use the older style for denoting a function typed
  /// parameter.
  ///
  /// If the parameter is function-typed, and has the question mark, then its
  /// function type is nullable. Having a nullable function type means that the
  /// parameter can be `null`.
  Token? get question;

  /// The token representing the `this` keyword.
  Token get thisKeyword;

  /// The declared type of the parameter, or `null` if the parameter doesn't
  /// have a declared type.
  ///
  /// If this is a function-typed field formal parameter this is the return type
  /// of the function.
  TypeAnnotation? get type;

  /// The type parameters associated with this method, or `null` if this method
  /// isn't a generic method.
  TypeParameterList? get typeParameters;
}

final class FieldFormalParameterImpl extends NormalFormalParameterImpl
    implements FieldFormalParameter {
  @override
  final Token? keyword;

  TypeAnnotationImpl? _type;

  @override
  final Token thisKeyword;

  @override
  final Token period;

  TypeParameterListImpl? _typeParameters;

  FormalParameterListImpl? _parameters;

  @override
  final Token? question;

  /// Initializes a newly created formal parameter.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// parameter doesn't have the corresponding attribute.
  ///
  /// The [keyword] can be `null` if there's a type.
  ///
  /// The [type] must be `null` if the keyword is `var`.
  ///
  /// The [thisKeyword] and [period] can be `null` if the keyword `this` isn't
  /// provided.
  ///
  /// The [parameters] can be `null` if this isn't a function-typed field formal
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
  Token get endToken {
    return question ?? _parameters?.endToken ?? name;
  }

  @override
  Token get firstTokenAfterCommentAndMetadata =>
      requiredKeyword ??
      covariantKeyword ??
      keyword ??
      type?.beginToken ??
      thisKeyword;

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
  /// The token representing the `in` keyword.
  Token get inKeyword;

  /// The expression evaluated to produce the iterator.
  Expression get iterable;
}

sealed class ForEachPartsImpl extends ForLoopPartsImpl implements ForEachParts {
  @override
  final Token inKeyword;

  ExpressionImpl _iterable;

  /// Initializes a newly created for-each statement whose loop control variable
  /// is declared internally (in the for-loop part).
  ///
  /// The [awaitKeyword] can be `null` if this isn't an asynchronous for loop.
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
  /// The declaration of the loop variable.
  DeclaredIdentifier get loopVariable;
}

final class ForEachPartsWithDeclarationImpl extends ForEachPartsImpl
    implements ForEachPartsWithDeclaration {
  DeclaredIdentifierImpl _loopVariable;

  /// Initializes a newly created for-each statement whose loop control variable
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
  /// The loop variable.
  SimpleIdentifier get identifier;
}

final class ForEachPartsWithIdentifierImpl extends ForEachPartsImpl
    implements ForEachPartsWithIdentifier {
  SimpleIdentifierImpl _identifier;

  /// Initializes a newly created for-each statement whose loop control variable
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
  /// The `var` or `final` keyword introducing the pattern.
  Token get keyword;

  /// The annotations associated with this node.
  NodeList<Annotation> get metadata;

  /// The pattern used to match the expression.
  DartPattern get pattern;
}

final class ForEachPartsWithPatternImpl extends ForEachPartsImpl
    implements ForEachPartsWithPattern {
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
  /// The token representing the `await` keyword, or `null` if there was no
  /// `await` keyword.
  Token? get awaitKeyword;

  /// The body of the loop.
  CollectionElement get body;

  /// The token representing the `for` keyword.
  Token get forKeyword;

  /// The parts of the for element that control the iteration.
  ForLoopParts get forLoopParts;

  /// The left parenthesis.
  Token get leftParenthesis;

  /// The right parenthesis.
  Token get rightParenthesis;
}

final class ForElementImpl extends CollectionElementImpl
    with AstNodeWithNameScopeMixin
    implements ForElement {
  @override
  final Token? awaitKeyword;

  @override
  final Token forKeyword;

  @override
  final Token leftParenthesis;

  ForLoopPartsImpl _forLoopParts;

  @override
  final Token rightParenthesis;

  CollectionElementImpl _body;

  /// Initializes a newly created for element.
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
  /// The `covariant` keyword, or `null` if the keyword isn't used.
  Token? get covariantKeyword;

  /// The element representing this parameter, or `null` if this parameter
  /// hasn't been resolved.
  ParameterElement? get declaredElement;

  ///The fragment declared by this parameter.
  ///
  /// Returns `null` if this parameter hasn't been resolved.
  @experimental
  FormalParameterFragment? get declaredFragment;

  /// Whether this parameter was declared with the 'const' modifier.
  bool get isConst;

  /// Whether the parameter has an explicit type.
  bool get isExplicitlyTyped;

  /// Whether this parameter was declared with the 'final' modifier.
  ///
  /// Returns `false` for parameters that are declared with the 'const' modifier
  /// even though they are implicitly final.
  bool get isFinal;

  /// Whether this parameter is a named parameter.
  ///
  /// Named parameters can either be required or optional.
  bool get isNamed;

  /// Whether this parameter is an optional parameter.
  ///
  /// Optional parameters can either be positional or named.
  bool get isOptional;

  /// Whether this parameter is both an optional and named parameter.
  bool get isOptionalNamed;

  /// Whether this parameter is both an optional and positional
  /// parameter.
  bool get isOptionalPositional;

  /// Whether this parameter is a positional parameter.
  ///
  /// Positional parameters can either be required or optional.
  bool get isPositional;

  /// Whether this parameter is a required parameter.
  ///
  /// Required parameters can either be positional or named.
  ///
  /// Note: this returns `false` for a named parameter that is annotated with
  /// the `@required` annotation.
  bool get isRequired;

  /// Whether this parameter is both a required and named parameter.
  ///
  /// Note: this returns `false` for a named parameter that is annotated with
  /// the `@required` annotation.
  bool get isRequiredNamed;

  /// Whether this parameter is both a required and positional parameter.
  bool get isRequiredPositional;

  /// The annotations associated with this parameter.
  NodeList<Annotation> get metadata;

  /// The name of the parameter being declared, or `null` if the parameter
  /// doesn't have a name, such as when it's part of a generic function type.
  Token? get name;

  /// The `required` keyword, or `null` if the keyword isn't used.
  Token? get requiredKeyword;
}

sealed class FormalParameterImpl extends AstNodeImpl
    implements FormalParameter {
  @override
  ParameterElementImpl? declaredElement;

  @experimental
  @override
  FormalParameterFragment? get declaredFragment =>
      declaredElement as FormalParameterFragment?;

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

  /// The kind of this parameter.
  ParameterKind get kind;

  @override
  NodeList<AnnotationImpl> get metadata;
}

/// The formal parameter list of a method declaration, function declaration, or
/// function type alias.
///
/// While the grammar requires all required positional parameters to be first,
/// optionally being followed by either optional positional parameters or named
/// parameters (but not both), this class doesn't enforce those constraints. All
/// parameters are flattened into a single list, which can have any or all kinds
/// of parameters (normal, named, and positional) in any order.
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
  /// The left square bracket ('[') or left curly brace ('{') introducing the
  /// optional or named parameters, or `null` if there are neither optional nor
  /// named parameters.
  Token? get leftDelimiter;

  /// The left parenthesis.
  Token get leftParenthesis;

  /// A list containing the elements representing the parameters in this list.
  ///
  /// The list contains `null`s if the parameters in this list haven't been
  /// resolved.
  List<ParameterElement?> get parameterElements;

  /// A list containing the fragments representing the parameters in this list.
  ///
  /// The list contains `null`s if the parameters in this list haven't been
  /// resolved.
  @experimental
  List<FormalParameterFragment?> get parameterFragments;

  /// The parameters associated with the method.
  NodeList<FormalParameter> get parameters;

  /// The right square bracket (']') or right curly brace ('}') terminating the
  /// optional or named parameters, or `null` if there are neither optional nor
  /// named parameters.
  Token? get rightDelimiter;

  /// The right parenthesis.
  Token get rightParenthesis;
}

final class FormalParameterListImpl extends AstNodeImpl
    implements FormalParameterList {
  @override
  final Token leftParenthesis;

  final NodeListImpl<FormalParameterImpl> _parameters = NodeListImpl._();

  @override
  final Token? leftDelimiter;

  @override
  final Token? rightDelimiter;

  @override
  final Token rightParenthesis;

  /// Initializes a newly created parameter list.
  ///
  /// The [leftDelimiter] and [rightDelimiter] can be `null` if there are no
  /// optional or named parameters, but it must be the case that either both are
  /// `null` or that both are non-`null`.
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

  @experimental
  @override
  List<FormalParameterFragment?> get parameterFragments =>
      parameterElements.cast<FormalParameterFragment?>();

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
  /// The condition used to determine when to terminate the loop, or `null` if
  /// there's no condition.
  Expression? get condition;

  /// The semicolon separating the initializer and the condition.
  Token get leftSeparator;

  /// The semicolon separating the condition and the updater.
  Token get rightSeparator;

  /// The list of expressions run after each execution of the loop body.
  NodeList<Expression> get updaters;
}

sealed class ForPartsImpl extends ForLoopPartsImpl implements ForParts {
  @override
  final Token leftSeparator;

  ExpressionImpl? _condition;

  @override
  final Token rightSeparator;

  final NodeListImpl<ExpressionImpl> _updaters = NodeListImpl._();

  /// Initializes a newly created for statement.
  ///
  /// Either the [variableList] or the [initialization] must be `null`.
  ///
  /// Either the [condition] and the list of [updaters] can be `null` if the
  /// loop doesn't have the corresponding attribute.
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
  /// The declaration of the loop variables.
  VariableDeclarationList get variables;
}

final class ForPartsWithDeclarationsImpl extends ForPartsImpl
    implements ForPartsWithDeclarations {
  VariableDeclarationListImpl _variableList;

  /// Initializes a newly created for statement.
  ///
  /// Both the [condition] and the list of [updaters] can be `null` if the loop
  /// doesn't have the corresponding attribute.
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
  /// The initialization expression, or `null` if there's no initialization
  /// expression.
  ///
  /// Note that a for statement can't have both a variable list and an
  /// initialization expression, but can validly have neither.
  Expression? get initialization;
}

final class ForPartsWithExpressionImpl extends ForPartsImpl
    implements ForPartsWithExpression {
  ExpressionImpl? _initialization;

  /// Initializes a newly created for statement.
  ///
  /// Both the [condition] and the list of [updaters] can be `null` if the loop
  /// doesn't have the corresponding attribute.
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

/// The parts of a for loop that control the iteration when there's a pattern
/// declaration as part of the for loop.
///
///   forLoopParts ::=
///       [PatternVariableDeclaration] ';' [Expression]? ';' expressionList?
abstract final class ForPartsWithPattern implements ForParts {
  /// The declaration of the loop variables.
  PatternVariableDeclaration get variables;
}

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
abstract final class ForStatement implements Statement {
  /// The token representing the `await` keyword, or `null` if there's no
  /// `await` keyword.
  Token? get awaitKeyword;

  /// The body of the loop.
  Statement get body;

  /// The token representing the `for` keyword.
  Token get forKeyword;

  /// The parts of the for element that control the iteration.
  ForLoopParts get forLoopParts;

  /// The left parenthesis.
  Token get leftParenthesis;

  /// The right parenthesis.
  Token get rightParenthesis;
}

final class ForStatementImpl extends StatementImpl
    with AstNodeWithNameScopeMixin
    implements ForStatement {
  @override
  final Token? awaitKeyword;

  @override
  final Token forKeyword;

  @override
  final Token leftParenthesis;

  ForLoopPartsImpl _forLoopParts;

  @override
  final Token rightParenthesis;

  StatementImpl _body;

  /// Initializes a newly created for statement.
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
  /// Whether this function body is asynchronous.
  bool get isAsynchronous;

  /// Whether this function body is a generator.
  bool get isGenerator;

  /// Whether this function body is synchronous.
  bool get isSynchronous;

  /// The token representing the `async` or `sync` keyword, or `null` if there's
  /// no such keyword.
  Token? get keyword;

  /// The star following the `async` or `sync` keyword, or `null` if there's no
  /// star.
  Token? get star;

  /// If [variable] is a local variable or parameter declared anywhere within
  /// the top level function or method containing this [FunctionBody], return a
  /// boolean indicating whether [variable] is potentially mutated within the
  /// scope of its declaration.
  ///
  /// If [variable] isn't a local variable or parameter declared within the top
  /// level function or method containing this [FunctionBody], return `false`.
  ///
  /// Throws an exception if resolution hasn't been performed.
  bool isPotentiallyMutatedInScope(VariableElement variable);

  /// If [variable] is a local variable or parameter declared anywhere within
  /// the top level function or method containing this [FunctionBody], return a
  /// boolean indicating whether [variable] is potentially mutated within the
  /// scope of its declaration.
  ///
  /// If [variable] isn't a local variable or parameter declared within the top
  /// level function or method containing this [FunctionBody], return `false`.
  ///
  /// Throws an exception if resolution hasn't been performed.
  @experimental
  bool isPotentiallyMutatedInScope2(VariableElement2 variable);
}

sealed class FunctionBodyImpl extends AstNodeImpl implements FunctionBody {
  /// Additional information about local variables and parameters that are
  /// declared within this function body or any enclosing function body, or
  /// `null` if resolution hasn't yet been performed.
  LocalVariableInfo? localVariableInfo;

  /// The [BodyInferenceContext] that was used during type inference of this
  /// function body, or `null` if resolution hasn't yet been performed.
  BodyInferenceContext? bodyContext;

  @override
  bool get isAsynchronous => false;

  @override
  bool get isGenerator => false;

  @override
  bool get isSynchronous => true;

  @override
  Token? get keyword => null;

  @override
  Token? get star => null;

  @override
  bool isPotentiallyMutatedInScope(VariableElement variable) {
    if (localVariableInfo == null) {
      throw StateError('Resolution has not been performed');
    }
    return localVariableInfo!.potentiallyMutatedInScope.contains(variable);
  }

  @experimental
  @override
  bool isPotentiallyMutatedInScope2(VariableElement2 variable) {
    if (variable is LocalVariableElementImpl2) {
      return isPotentiallyMutatedInScope(variable.wrappedElement);
    }
    if (variable case VariableElement variable) {
      return isPotentiallyMutatedInScope(variable);
    }
    return false;
  }

  /// Dispatch this function body to the resolver, imposing [imposedType] as the
  /// return type context for `return` statements.
  ///
  /// Returns value is the actual return type of the method.
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
// TODO(brianwilkerson): This class represents both declarations that can be
//  augmented and declarations that can't be augmented. This results in getters
//  that are only sometimes applicable. Consider changing the class hierarchy so
//  that these two kinds of variables can be distinguished.
abstract final class FunctionDeclaration
    implements NamedCompilationUnitMember, _FragmentDeclaration {
  /// The `augment` keyword, or `null` if there is no `augment` keyword.
  @experimental
  Token? get augmentKeyword;

  /// The element defined by this declaration.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if this node
  /// represents a top-level function.
  @override
  ExecutableElement? get declaredElement;

  /// The element defined by this local function declaration.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if this node
  /// is not a local function.
  LocalFunctionElement? get declaredElement2;

  /// The fragment declared by this declaration.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if this node
  /// represents a local function.
  @experimental
  @override
  ExecutableFragment? get declaredFragment;

  /// The token representing the `external` keyword, or `null` if this isn't an
  /// external function.
  Token? get externalKeyword;

  /// The function expression being wrapped.
  FunctionExpression get functionExpression;

  /// Whether this function declares a getter.
  bool get isGetter;

  /// Whether this function declares a setter.
  bool get isSetter;

  /// The token representing the `get` or `set` keyword, or `null` if this is a
  /// function declaration rather than a property declaration.
  Token? get propertyKeyword;

  /// The return type of the function, or `null` if no return type was declared.
  TypeAnnotation? get returnType;
}

final class FunctionDeclarationImpl extends NamedCompilationUnitMemberImpl
    with AstNodeWithNameScopeMixin
    implements FunctionDeclaration {
  @override
  final Token? augmentKeyword;

  @override
  final Token? externalKeyword;

  TypeAnnotationImpl? _returnType;

  @override
  final Token? propertyKeyword;

  FunctionExpressionImpl _functionExpression;

  @override
  ExecutableElementImpl? declaredElement;

  @override
  LocalFunctionElementImpl? declaredElement2;

  /// Initializes a newly created function declaration.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// function doesn't have the corresponding attribute.
  ///
  /// The [externalKeyword] can be `null` if the function isn't an external
  /// function.
  ///
  /// The [returnType] can be `null` if no return type was specified.
  ///
  /// The [propertyKeyword] can be `null` if the function is neither a getter or
  /// a setter.
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

  @experimental
  @override
  ExecutableFragment? get declaredFragment {
    if (declaredElement case ExecutableFragment fragment) {
      return fragment;
    }
    return null;
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
  /// The function declaration being wrapped.
  FunctionDeclaration get functionDeclaration;
}

final class FunctionDeclarationStatementImpl extends StatementImpl
    implements FunctionDeclarationStatement {
  FunctionDeclarationImpl _functionDeclaration;

  /// Initializes a newly created function declaration statement.
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
  /// The body of the function.
  FunctionBody get body;

  /// The element associated with the function, or `null` if the AST structure
  /// hasn't been resolved.
  ExecutableElement? get declaredElement;

  /// The element defined by this function expression.
  ///
  /// Returns `null` if the AST structure hasn't been resolved.
  ///
  /// Returns `null` if this expression is not a closure, and the parent is
  /// not a local function.
  @experimental
  LocalFunctionElement? get declaredElement2;

  /// The fragment declared by this function expression.
  ///
  /// Returns `null` if the AST structure hasn't been resolved.
  ///
  /// Returns `null` is thie expression is a closure, or the parent is a
  /// local function.
  @experimental
  ExecutableFragment? get declaredFragment;

  /// The parameters associated with the function, or `null` if the function is
  /// part of a top-level getter.
  FormalParameterList? get parameters;

  /// The type parameters associated with this method, or `null` if this method
  /// isn't a generic method.
  TypeParameterList? get typeParameters;
}

final class FunctionExpressionImpl extends ExpressionImpl
    implements FunctionExpression {
  TypeParameterListImpl? _typeParameters;

  FormalParameterListImpl? _parameters;

  FunctionBodyImpl _body;

  /// Whether a function type was supplied via context for this function
  /// expression.
  ///
  /// Returns `false` if resolution hasn't been performed yet.
  bool wasFunctionTypeSupplied = false;

  @override
  ExecutableElementImpl? declaredElement;

  @override
  LocalFunctionElementImpl? declaredElement2;

  /// Initializes a newly created function declaration.
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
    if (typeParameters case var typeParameters?) {
      return typeParameters.beginToken;
    } else if (parameters case var parameters?) {
      return parameters.beginToken;
    }
    return _body.beginToken;
  }

  @override
  FunctionBodyImpl get body => _body;

  set body(FunctionBodyImpl functionBody) {
    _body = _becomeParentOf(functionBody);
  }

  @override
  ExecutableFragment? get declaredFragment {
    if (declaredElement?.enclosingElement3 is CompilationUnitElement) {
      return declaredElement;
    }
    return null;
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

  DartType get returnType {
    // If a closure, or a local function.
    if (declaredElement2 case var declaredElement?) {
      return declaredElement.returnType;
    }
    // SAFETY: must be a top-level function.
    return declaredFragment!.element.returnType;
  }

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
  /// The element associated with the function being invoked based on static
  /// type information.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or the function
  /// couldn't be resolved.
  @experimental
  ExecutableElement2? get element;

  /// The expression producing the function being invoked.
  @override
  Expression get function;

  /// The element associated with the function being invoked based on static
  /// type information, or `null` if the AST structure hasn't been resolved or
  /// the function couldn't be resolved.
  ExecutableElement? get staticElement;
}

final class FunctionExpressionInvocationImpl extends InvocationExpressionImpl
    with NullShortableExpressionImpl
    implements FunctionExpressionInvocation {
  ExpressionImpl _function;

  @override
  ExecutableElement? staticElement;

  /// Initializes a newly created function expression invocation.
  FunctionExpressionInvocationImpl({
    required ExpressionImpl function,
    required super.typeArguments,
    required super.argumentList,
  }) : _function = function {
    _becomeParentOf(_function);
  }

  @override
  Token get beginToken => _function.beginToken;

  @experimental
  @override
  ExecutableElement2? get element =>
      staticElement?.asElement2 as ExecutableElement2?;

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
/// arguments applied to it.
///
/// For example, the expression `print` in `var x = print;`.
abstract final class FunctionReference
    implements Expression, CommentReferableExpression {
  /// The function being referenced.
  ///
  /// In error-free code, this is either a [SimpleIdentifier] (indicating a
  /// function that is in scope), a [PrefixedIdentifier] (indicating a either
  /// function imported via prefix or a static method in a class), or a
  /// [PropertyAccess] (indicating a static method in a class imported via
  /// prefix). In code with errors, this could be other kinds of expressions.
  /// For example, `(...)<int>` parses as a [FunctionReference] whose referent
  /// is a [ParenthesizedExpression].
  Expression get function;

  /// The type arguments being applied to the function, or `null` if there are
  /// no type arguments.
  TypeArgumentList? get typeArguments;

  /// The actual type arguments being applied to the function, either
  /// explicitly specified in [typeArguments], or inferred.
  ///
  /// An empty list if the function doesn't have type parameters, or `null` if
  /// the AST structure hasn't been resolved.
  List<DartType>? get typeArgumentTypes;
}

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
///        'typedef' functionPrefix [TypeParameterList]?
///        [FormalParameterList] ';'
///
///    functionPrefix ::=
///        [TypeAnnotation]? [SimpleIdentifier]
abstract final class FunctionTypeAlias
    implements TypeAlias, _FragmentDeclaration {
  @override
  TypeAliasElement? get declaredElement;

  @experimental
  @override
  TypeAliasFragment? get declaredFragment;

  /// The parameters associated with the function type.
  FormalParameterList get parameters;

  /// The return type of the function type being defined, or `null` if no return
  /// type was given.
  TypeAnnotation? get returnType;

  /// The type parameters for the function type, or `null` if the function type
  /// doesn't have any type parameters.
  TypeParameterList? get typeParameters;
}

final class FunctionTypeAliasImpl extends TypeAliasImpl
    implements FunctionTypeAlias {
  TypeAnnotationImpl? _returnType;

  TypeParameterListImpl? _typeParameters;

  FormalParameterListImpl _parameters;

  @override
  TypeAliasElementImpl? declaredElement;

  /// Initializes a newly created function type alias.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// function doesn't have the corresponding attribute.
  ///
  /// The [returnType] can be `null` if no return type was specified.
  ///
  /// The [typeParameters] can be `null` if the function has no type parameters.
  FunctionTypeAliasImpl({
    required super.comment,
    required super.metadata,
    required super.augmentKeyword,
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

  @experimental
  @override
  TypeAliasFragment? get declaredFragment =>
      declaredElement as TypeAliasFragment?;

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
    ..addToken('augmentKeyword', augmentKeyword)
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

  /// The parameters of the function-typed parameter.
  FormalParameterList get parameters;

  /// The question mark indicating that the function type is nullable, or `null`
  /// if there's no question mark.
  ///
  /// Having a nullable function type means that the parameter can be null.
  Token? get question;

  /// The return type of the function, or `null` if the function doesn't have a
  /// return type.
  TypeAnnotation? get returnType;

  /// The type parameters associated with this function, or `null` if this
  /// function isn't a generic function.
  TypeParameterList? get typeParameters;
}

final class FunctionTypedFormalParameterImpl extends NormalFormalParameterImpl
    implements FunctionTypedFormalParameter {
  TypeAnnotationImpl? _returnType;

  TypeParameterListImpl? _typeParameters;

  FormalParameterListImpl _parameters;

  @override
  final Token? question;

  /// Initializes a newly created formal parameter.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// parameter doesn't have the corresponding attribute.
  ///
  /// The [returnType] can be `null` if no return type was specified.
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
  Token get endToken => question ?? _parameters.endToken;

  @override
  Token get firstTokenAfterCommentAndMetadata =>
      requiredKeyword ?? covariantKeyword ?? returnType?.beginToken ?? name;

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
  /// The `Function` keyword.
  Token get functionKeyword;

  /// The parameters associated with the function type.
  FormalParameterList get parameters;

  /// The return type of the function type being defined, or `null` if no return
  /// type was given.
  TypeAnnotation? get returnType;

  /// The type parameters for the function type, or `null` if the function type
  /// doesn't have any type parameters.
  TypeParameterList? get typeParameters;
}

final class GenericFunctionTypeImpl extends TypeAnnotationImpl
    with AstNodeWithNameScopeMixin
    implements GenericFunctionType {
  TypeAnnotationImpl? _returnType;

  @override
  final Token functionKeyword;

  TypeParameterListImpl? _typeParameters;

  FormalParameterListImpl _parameters;

  @override
  final Token? question;

  @override
  DartType? type;

  /// The element associated with the function type, or `null` if the AST
  /// structure hasn't been resolved.
  GenericFunctionTypeElementImpl? declaredElement;

  /// Initializes a newly created generic function type.
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

  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

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
///        'typedef' [SimpleIdentifier] [TypeParameterList]? =
///        [FunctionType] ';'
abstract final class GenericTypeAlias
    implements TypeAlias, _FragmentDeclaration {
  /// The equal sign separating the name being defined from the function type.
  Token get equals;

  /// The type of function being defined by the alias, or `null` if the
  /// non-function type aliases feature is enabled and the denoted type isn't a
  /// [GenericFunctionType].
  GenericFunctionType? get functionType;

  /// The type being defined by the alias.
  TypeAnnotation get type;

  /// The type parameters for the function type, or `null` if the function type
  /// doesn't have any type parameters.
  TypeParameterList? get typeParameters;
}

final class GenericTypeAliasImpl extends TypeAliasImpl
    with AstNodeWithNameScopeMixin
    implements GenericTypeAlias {
  TypeAnnotationImpl _type;

  TypeParameterListImpl? _typeParameters;

  @override
  final Token equals;

  @override
  ElementImpl? declaredElement;

  /// Initializes a newly created generic type alias.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// variable list doesn't have the corresponding attribute.
  ///
  /// The [typeParameters] can be `null` if there are no type parameters.
  GenericTypeAliasImpl({
    required super.comment,
    required super.metadata,
    required super.augmentKeyword,
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

  @experimental
  @override
  Fragment? get declaredFragment => declaredElement as Fragment?;

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
    ..addToken('augmentKeyword', augmentKeyword)
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
  /// The pattern controlling whether the statements are executed.
  DartPattern get pattern;

  /// The clause controlling whether the statements are be executed.
  WhenClause? get whenClause;
}

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

/// A combinator that restricts the names being imported to those that aren't
/// in a given list.
///
///    hideCombinator ::=
///        'hide' [SimpleIdentifier] (',' [SimpleIdentifier])*
abstract final class HideCombinator implements Combinator {
  /// The list of names from the library that are hidden by this combinator.
  NodeList<SimpleIdentifier> get hiddenNames;
}

final class HideCombinatorImpl extends CombinatorImpl
    implements HideCombinator {
  final NodeListImpl<SimpleIdentifierImpl> _hiddenNames = NodeListImpl._();

  /// Initializes a newly created import show combinator.
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
  /// The element associated with this identifier based on static type
  /// information.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if this
  /// identifier couldn't be resolved. One example of the latter case is an
  /// identifier that isn't defined within the scope in which it appears.
  @experimental
  Element2? get element;

  /// The lexical representation of the identifier.
  String get name;

  /// The element associated with this identifier based on static type
  /// information, or `null` if the AST structure hasn't been resolved or if
  /// this identifier couldn't be resolved. One example of the latter case is an
  /// identifier that isn't defined within the scope in which it appears.
  Element? get staticElement;

  /// Returns `true` if the given [name] is visible only within the library in
  /// which it's declared.
  static bool isPrivateName(String name) => name.isNotEmpty && name[0] == "_";
}

sealed class IdentifierImpl extends CommentReferableExpressionImpl
    implements Identifier {
  @experimental
  @override
  Element2? get element {
    return staticElement.asElement2;
  }

  @override
  bool get isAssignable => true;
}

/// The basic structure of an if element.
abstract final class IfElement implements CollectionElement {
  /// The `case` clause used to match a pattern against the [expression].
  CaseClause? get caseClause;

  /// The condition used to determine which of the statements is executed next.
  @Deprecated('Use expression instead')
  Expression get condition;

  /// The statement that is executed if the condition evaluates to `false`, or
  /// `null` if there's no else statement.
  CollectionElement? get elseElement;

  /// The token representing the `else` keyword, or `null` if there's no else
  /// expression.
  Token? get elseKeyword;

  /// The expression used to either determine which of the statements is
  /// executed next or to compute the value to be matched against the pattern in
  /// the `case` clause.
  Expression get expression;

  /// The token representing the `if` keyword.
  Token get ifKeyword;

  /// The left parenthesis.
  Token get leftParenthesis;

  /// The right parenthesis.
  Token get rightParenthesis;

  /// The statement that is executed if the condition evaluates to `true`.
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

  CollectionElementImpl _thenElement;

  CollectionElementImpl? _elseElement;

  /// Initializes a newly created for element.
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
  /// The `case` clause used to match a pattern against the [expression].
  CaseClauseImpl? get caseClause;

  /// The expression used to either determine which of the statements is
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
  /// The `case` clause used to match a pattern against the [expression].
  CaseClause? get caseClause;

  /// The condition used to determine which of the statements is executed next.
  @Deprecated('Use expression instead')
  Expression get condition;

  /// The token representing the `else` keyword, or `null` if there's no else
  /// statement.
  Token? get elseKeyword;

  /// The statement that is executed if the condition evaluates to `false`, or
  /// `null` if there's no else statement.
  Statement? get elseStatement;

  /// The expression used to either determine which of the statements is
  /// executed next or to compute the value matched against the pattern in the
  /// `case` clause.
  Expression get expression;

  /// The token representing the `if` keyword.
  // TODO(scheglov): Extract shared `IfCondition`, see the patterns spec.
  Token get ifKeyword;

  /// The left parenthesis.
  Token get leftParenthesis;

  /// The right parenthesis.
  Token get rightParenthesis;

  /// The statement that is executed if the condition evaluates to `true`.
  Statement get thenStatement;
}

final class IfStatementImpl extends StatementImpl
    implements IfStatement, IfElementOrStatementImpl<StatementImpl> {
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

  StatementImpl _thenStatement;

  StatementImpl? _elseStatement;

  /// Initializes a newly created if statement.
  ///
  /// The [elseKeyword] and [elseStatement] can be `null` if there's no else
  /// clause.
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
    if (elseStatement case var elseStatement?) {
      return elseStatement.endToken;
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
  /// The token representing the `implements` keyword.
  Token get implementsKeyword;

  /// The list of the interfaces that are being implemented.
  NodeList<NamedType> get interfaces;
}

final class ImplementsClauseImpl extends AstNodeImpl
    implements ImplementsClause {
  @override
  final Token implementsKeyword;

  final NodeListImpl<NamedTypeImpl> _interfaces = NodeListImpl._();

  /// Initializes a newly created implements clause.
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
/// Objects of this type aren't produced directly by the parser (because the
/// parser can't tell whether an expression refers to a callable type); they
/// are produced at resolution time.
abstract final class ImplicitCallReference
    implements MethodReferenceExpression {
  /// The expression from which a `call` method is being referenced.
  Expression get expression;

  /// The element associated with the implicit `call` reference based on the
  /// static types.
  @override
  MethodElement get staticElement;

  /// The type arguments being applied to the tear-off, or `null` if there are
  /// no type arguments.
  TypeArgumentList? get typeArguments;

  /// The actual type arguments being applied to the tear-off, either explicitly
  /// specified in [typeArguments], or inferred.
  ///
  /// An empty list if the 'call' method doesn't have type parameters.
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

  @experimental
  @override
  MethodElement2? get element => (staticElement as MethodFragment?)?.element;

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
    resolver.visitImplicitCallReference(this);
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
///        [Annotation] 'import' [StringLiteral] ('as' identifier)?
///        [Combinator]* ';'
///      | [Annotation] 'import' [StringLiteral] 'deferred' 'as' identifier
///        [Combinator]* ';'
abstract final class ImportDirective implements NamespaceDirective {
  /// The token representing the `as` keyword, or `null` if the imported names
  /// aren't prefixed.
  Token? get asKeyword;

  /// The token representing the `deferred` keyword, or `null` if the imported
  /// URI isn't deferred.
  Token? get deferredKeyword;

  /// The element associated with this directive, or `null` if the AST structure
  /// hasn't been resolved.
  @override
  LibraryImportElement? get element;

  /// The token representing the `import` keyword.
  Token get importKeyword;

  /// Information about this import directive.
  ///
  /// Returns `null` if the AST structure hasn't been resolved.
  @experimental
  LibraryImport? get libraryImport;

  /// The prefix to be used with the imported names, or `null` if the imported
  /// names aren't prefixed.
  SimpleIdentifier? get prefix;
}

final class ImportDirectiveImpl extends NamespaceDirectiveImpl
    implements ImportDirective {
  @override
  final Token importKeyword;

  @override
  final Token? deferredKeyword;

  @override
  final Token? asKeyword;

  SimpleIdentifierImpl? _prefix;

  /// Initializes a newly created import directive.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// function doesn't have the corresponding attribute.
  ///
  /// The [deferredKeyword] can be `null` if the import isn't deferred.
  ///
  /// The [asKeyword] and [prefix] can be `null` if the import doesn't specify a
  /// prefix.
  ///
  /// The list of [combinators] can be `null` if there are no combinators.
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

  @experimental
  @override
  LibraryImport? get libraryImport => element as LibraryImport?;

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

  /// Returns `true` if the non-URI components of the two directives are
  /// syntactically identical.
  ///
  /// URIs are checked outside to see if they resolve to the same absolute URI,
  /// so to the same library, regardless of the used syntax (absolute, relative,
  /// not normalized).
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

    var combinators1 = node1.combinators;
    var combinators2 = node2.combinators;
    if (combinators1.length != combinators2.length) {
      return false;
    }
    for (var i = 0; i < combinators1.length; i++) {
      var combinator1 = combinators1[i];
      var combinator2 = combinators2[i];
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
  /// The element to which [name] is resolved.
  ///
  /// Usually a [PrefixElement], but can be anything in invalid code.
  Element? get element;

  /// The element to which [name] is resolved.
  ///
  /// Usually a [PrefixElement2], but can be anything in invalid code.
  @experimental
  Element2? get element2;

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

  @experimental
  @override
  Element2? get element2 {
    var element = this.element;
    if (element case PrefixElementImpl element) {
      return element.element2;
    } else if (element case Fragment fragment) {
      return fragment.element;
    } else if (element case Element2 element) {
      return element;
    }
    return null;
  }

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
  /// The expression used to compute the index.
  Expression get index;

  /// Whether this expression is cascaded.
  ///
  /// If it is, then the target of this expression isn't stored locally but is
  /// stored in the nearest ancestor that is a [CascadeExpression].
  bool get isCascaded;

  /// Whether this index expression is null aware (as opposed to non-null).
  bool get isNullAware;

  /// The left square bracket.
  Token get leftBracket;

  /// The period (".." | "?..") before a cascaded index expression, or `null` if
  /// this index expression isn't part of a cascade expression.
  Token? get period;

  /// The question mark before the left bracket, or `null` if there's no
  /// question mark.
  Token? get question;

  /// The expression used to compute the object being indexed.
  ///
  /// If this index expression isn't part of a cascade expression, then this
  /// is the same as [target]. If this index expression is part of a cascade
  /// expression, then the target expression stored with the cascade expression
  /// is returned.
  Expression get realTarget;

  /// The right square bracket.
  Token get rightBracket;

  /// The expression used to compute the object being indexed, or `null` if this
  /// index expression is part of a cascade expression.
  ///
  /// Use [realTarget] to get the target independent of whether this is part of
  /// a cascade expression.
  Expression? get target;

  /// Returns `true` if this expression is computing a right-hand value (that
  /// is, if this expression is in a context where the operator '[]' is
  /// invoked).
  ///
  /// Note that [inGetterContext] and [inSetterContext] aren't opposites, nor
  /// are they mutually exclusive. In other words, it's possible for both
  /// methods to return `true` when invoked on the same node.
  // TODO(brianwilkerson): Convert this to a getter.
  bool inGetterContext();

  /// Returns `true` if this expression is computing a left-hand value (that is,
  /// if this expression is in a context where the operator '[]=' is
  /// invoked).
  ///
  /// Note that [inGetterContext] and [inSetterContext] aren't opposites, nor
  /// are they mutually exclusive. In other words, it's possible for both
  /// methods to return `true` when invoked on the same node.
  // TODO(brianwilkerson): Convert this to a getter.
  bool inSetterContext();
}

final class IndexExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl
    implements IndexExpression {
  @override
  Token? period;

  ExpressionImpl? _target;

  @override
  final Token? question;

  @override
  final Token leftBracket;

  ExpressionImpl _index;

  @override
  final Token rightBracket;

  /// The element associated with the operator based on the static type of the
  /// target, or `null` if the AST structure hasn't been resolved or if the
  /// operator couldn't be resolved.
  @override
  MethodElement? staticElement;

  /// Initializes a newly created index expression that is a child of a cascade
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

  /// Initializes a newly created index expression that isn't a child of a
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
    if (target case var target?) {
      return target.beginToken;
    }
    return period!;
  }

  @experimental
  @override
  MethodElement2? get element => staticElement?.asElement2 as MethodElement2?;

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

  /// The cascade that contains this [IndexExpression].
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

  /// The parameter element representing the parameter to which the value of the
  /// index expression is bound, or `null` if the AST structure is not resolved,
  /// or the function being invoked is not known based on static type
  /// information.
  ParameterElement? get _staticParameterElementForIndex {
    Element? element = staticElement;

    var parent = this.parent;
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
    // TODO(brianwilkerson): Convert this to a getter.
    var parent = this.parent!;
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
    // TODO(brianwilkerson): Convert this to a getter.
    var parent = this.parent!;
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
///        ('new' | 'const')? [NamedType] ('.' [SimpleIdentifier])?
///        [ArgumentList]
abstract final class InstanceCreationExpression implements Expression {
  /// The list of arguments to the constructor.
  ArgumentList get argumentList;

  /// The name of the constructor to be invoked.
  ConstructorName get constructorName;

  /// Whether this creation expression is used to invoke a constant constructor,
  /// either because the keyword `const` was explicitly provided or because no
  /// keyword was provided and this expression is in a constant context.
  bool get isConst;

  /// The `new` or `const` keyword used to indicate how an object should be
  /// created, or `null` if the keyword isn't explicitly provided.
  Token? get keyword;
}

final class InstanceCreationExpressionImpl extends ExpressionImpl
    implements InstanceCreationExpression {
  // TODO(brianwilkerson): Consider making InstanceCreationExpressionImpl extend
  // InvocationExpressionImpl. This would probably be a breaking change, but is
  // also probably worth it.

  @override
  Token? keyword;

  ConstructorNameImpl _constructorName;

  /// The type arguments associated with the constructor, rather than with the
  /// class in which the constructor is defined.
  ///
  /// It's always an error if there are type arguments because Dart doesn't
  /// currently support generic constructors, but we capture them in the AST in
  /// order to recover better.
  TypeArgumentListImpl? _typeArguments;

  ArgumentListImpl _argumentList;

  /// Initializes a newly created instance creation expression.
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

  /// Whether this is an implicit constructor invocation.
  bool get isImplicit => keyword == null;

  @override
  Precedence get precedence => Precedence.primary;

  /// The type arguments associated with the constructor, rather than with the
  /// class in which the constructor is defined.
  ///
  /// It's always an error if there are type arguments because Dart doesn't
  /// currently support generic constructors, but we capture them in the AST in
  /// order to recover better.
  TypeArgumentListImpl? get typeArguments => _typeArguments;

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
  /// The token representing the literal.
  Token get literal;

  /// The value of the literal, or `null` when [literal] doesn't represent a
  /// valid `int` value, for example because of overflow.
  int? get value;
}

final class IntegerLiteralImpl extends LiteralImpl implements IntegerLiteral {
  @override
  final Token literal;

  @override
  int? value = 0;

  /// Initializes a newly created integer literal.
  IntegerLiteralImpl({
    required this.literal,
    required this.value,
  });

  @override
  Token get beginToken => literal;

  @override
  Token get endToken => literal;

  /// Whether this literal's [parent] is a [PrefixExpression] of unary negation.
  ///
  /// Note: this does *not* indicate that the value itself is negated, just that
  /// the literal is the child of a negation operation. The literal value itself
  /// is always positive.
  bool get immediatelyNegated {
    var parent = this.parent!;
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

  static bool isValidAsDouble(String source) {
    // Less than 16 characters must be a valid double since it's less than
    // 9007199254740992, 0x10000000000000, both 16 characters and 53 bits.
    if (source.length < 16) {
      return true;
    }

    var fullPrecision = BigInt.tryParse(source);
    if (fullPrecision == null) {
      return false;
    }

    // Usually handled by the length check, however, we must check this before
    // constructing a mask later, or we'd get a negative-shift runtime error.
    var bitLengthAsInt = fullPrecision.bitLength;
    if (bitLengthAsInt <= 53) {
      return true;
    }

    // This would overflow the exponent (larger than maximum double).
    if (fullPrecision > BigInt.from(double.maxFinite)) {
      return false;
    }

    // Say [lexeme] uses 100 bits as an integer. The bottom 47 must be 0s -- so
    // construct a mask of 47 ones, via of 2^n - 1 where n is 47.
    var bottomMask = (BigInt.one << (bitLengthAsInt - 53)) - BigInt.one;

    return fullPrecision & bottomMask == BigInt.zero;
  }

  /// Whether the given [source] is a valid lexeme for an integer
  /// literal.
  ///
  /// The flag [isNegative] should be `true` if the lexeme is preceded by a
  /// unary negation operator.
  static bool isValidAsInteger(String source, bool isNegative) {
    // TODO(jmesserly): this depends on the platform int implementation, and
    // might not be accurate if run in a browser.
    //
    // (Prior to https://dart-review.googlesource.com/c/sdk/+/63023 there was
    // a partial implementation here which might be a good starting point.
    // _isValidDecimalLiteral relied on int.parse so that would need some fixes.
    // _isValidHexadecimalLiteral worked except for negative int64 max.)
    if (isNegative) source = '-$source';
    return int.tryParse(source) != null;
  }

  /// Suggests the nearest valid double to a user.
  ///
  /// If the integer they wrote requires more than a 53 bit mantissa, or more
  /// than 10 exponent bits, do them the favor of suggesting the nearest integer
  /// that would work for them.
  static double nearestValidDouble(String source) =>
      math.min(double.maxFinite, BigInt.parse(source).toDouble());
}

/// A node within a [StringInterpolation].
///
///    interpolationElement ::=
///        [InterpolationExpression]
///      | [InterpolationString]
sealed class InterpolationElement implements AstNode {}

sealed class InterpolationElementImpl extends AstNodeImpl
    implements InterpolationElement {}

/// An expression embedded in a string interpolation.
///
///    interpolationExpression ::=
///        '$' [SimpleIdentifier]
///      | '$' '{' [Expression] '}'
abstract final class InterpolationExpression implements InterpolationElement {
  /// The expression to be evaluated for the value to be converted into a
  /// string.
  Expression get expression;

  /// The token used to introduce the interpolation expression.
  ///
  /// This will either be `$` if the expression is a simple identifier or `${`
  /// if the expression is a full expression.
  Token get leftBracket;

  /// The right curly bracket, or `null` if the expression is an identifier
  /// without brackets.
  Token? get rightBracket;
}

final class InterpolationExpressionImpl extends InterpolationElementImpl
    implements InterpolationExpression {
  @override
  final Token leftBracket;

  ExpressionImpl _expression;

  @override
  final Token? rightBracket;

  /// Initializes a newly created interpolation expression.
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
  /// The characters that are added to the string.
  Token get contents;

  /// The offset of the after-last contents character.
  int get contentsEnd;

  /// The offset of the first contents character.
  int get contentsOffset;

  /// The value of the literal.
  String get value;
}

final class InterpolationStringImpl extends InterpolationElementImpl
    implements InterpolationString {
  @override
  final Token contents;

  @override
  String value;

  /// Initializes a newly created string of characters that are part of a string
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

/// The invocation of a function or method.
///
/// This will either be a [FunctionExpressionInvocation] or a
/// [MethodInvocation].
abstract final class InvocationExpression implements Expression {
  /// The list of arguments to the method.
  ArgumentList get argumentList;

  /// The expression that identifies the function or method being invoked.
  ///
  /// For example:
  ///
  ///     (o.m)<TArgs>(args); // target is `o.m`
  ///     o.m<TArgs>(args);   // target is `m`
  ///
  /// In either case, the [function.staticType] is the [staticInvokeType] before
  /// applying type arguments `TArgs`.
  Expression get function;

  /// The function type of the invocation based on the static type information,
  /// or `null` if the AST structure hasn't been resolved, or if the invoke
  /// couldn't be resolved.
  ///
  /// This is usually a [FunctionType], but it can also be `dynamic` or
  /// `Function`. In the case of interface types that have a `call` method, we
  /// store the type of that `call` method here as parameterized.
  DartType? get staticInvokeType;

  /// The type arguments to be applied to the method being invoked, or `null` if
  /// no type arguments were provided.
  TypeArgumentList? get typeArguments;

  /// The actual type arguments of the invocation, either explicitly specified
  /// in [typeArguments], or inferred, or `null` if the AST structure hasn't
  /// been resolved.
  ///
  /// An empty list if the [function] doesn't have type parameters.
  List<DartType>? get typeArgumentTypes;
}

sealed class InvocationExpressionImpl extends ExpressionImpl
    implements InvocationExpression {
  ArgumentListImpl _argumentList;

  TypeArgumentListImpl? _typeArguments;

  @override
  List<DartType>? typeArgumentTypes;

  @override
  DartType? staticInvokeType;

  /// Initializes a newly created invocation.
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
  /// The expression used to compute the value whose type is being tested.
  Expression get expression;

  /// The is operator.
  Token get isOperator;

  /// The not operator, or `null` if the sense of the test isn't negated.
  Token? get notOperator;

  /// The type being tested for.
  TypeAnnotation get type;
}

final class IsExpressionImpl extends ExpressionImpl implements IsExpression {
  ExpressionImpl _expression;

  @override
  final Token isOperator;

  @override
  final Token? notOperator;

  TypeAnnotationImpl _type;

  /// Initializes a newly created is expression.
  ///
  /// The [notOperator] can be `null` if the sense of the test isn't negated.
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
  /// The colon that separates the label from the statement.
  Token get colon;

  /// The label being associated with the statement.
  SimpleIdentifier get label;
}

/// A statement that has a label associated with them.
///
///    labeledStatement ::=
///       [Label]+ [Statement]
abstract final class LabeledStatement implements Statement {
  /// The labels being associated with the statement.
  NodeList<Label> get labels;

  /// The statement with which the labels are being associated.
  Statement get statement;
}

final class LabeledStatementImpl extends StatementImpl
    implements LabeledStatement {
  final NodeListImpl<LabelImpl> _labels = NodeListImpl._();

  StatementImpl _statement;

  /// Initializes a newly created labeled statement.
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

final class LabelImpl extends AstNodeImpl implements Label {
  SimpleIdentifierImpl _label;

  @override
  final Token colon;

  /// Initializes a newly created label.
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

/// A library directive.
///
///    libraryDirective ::=
///        [Annotation] 'library' [LibraryIdentifier]? ';'
abstract final class LibraryDirective implements Directive {
  @override
  LibraryElement? get element;

  /// The element associated with this directive.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if this
  /// directive couldn't be resolved.
  @experimental
  LibraryElement2? get element2;

  /// The token representing the `library` keyword.
  Token get libraryKeyword;

  /// The name of the library being defined.
  LibraryIdentifier? get name2;

  /// The semicolon terminating the directive.
  Token get semicolon;
}

final class LibraryDirectiveImpl extends DirectiveImpl
    implements LibraryDirective {
  @override
  final Token libraryKeyword;

  LibraryIdentifierImpl? _name;

  @override
  final Token semicolon;

  /// Initializes a newly created library directive.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// directive doesn't have the corresponding attribute.
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
  LibraryElementImpl? get element {
    return super.element as LibraryElementImpl?;
  }

  @experimental
  @override
  LibraryElement2? get element2 => element as LibraryElement2?;

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
  /// The components of the identifier.
  NodeList<SimpleIdentifier> get components;
}

final class LibraryIdentifierImpl extends IdentifierImpl
    implements LibraryIdentifier {
  final NodeListImpl<SimpleIdentifierImpl> _components = NodeListImpl._();

  /// Initializes a newly created prefixed identifier.
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
    resolver.visitLibraryIdentifier(this);
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
  /// The syntactic elements used to compute the elements of the list.
  NodeList<CollectionElement> get elements;

  /// The left square bracket.
  Token get leftBracket;

  /// The right square bracket.
  Token get rightBracket;
}

final class ListLiteralImpl extends TypedLiteralImpl implements ListLiteral {
  @override
  final Token leftBracket;

  final NodeListImpl<CollectionElementImpl> _elements = NodeListImpl._();

  @override
  final Token rightBracket;

  /// Initializes a newly created list literal.
  ///
  /// The [constKeyword] can be `null` if the literal isn't a constant.
  ///
  /// The [typeArguments] can be `null` if no type arguments were declared.
  ///
  /// The list of [elements] can be `null` if the list is empty.
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
    if (constKeyword case var constKeyword?) {
      return constKeyword;
    }
    var typeArguments = this.typeArguments;
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
  /// The elements in this pattern.
  NodeList<ListPatternElement> get elements;

  /// The left square bracket.
  Token get leftBracket;

  /// The required type, specified by [typeArguments] or inferred from the
  /// matched value type, or `null` if the node isn't resolved yet.
  DartType? get requiredType;

  /// The right square bracket.
  Token get rightBracket;

  /// The type arguments associated with this pattern, or `null` if no type
  /// arguments were declared.
  TypeArgumentList? get typeArguments;
}

/// An element of a list pattern.
sealed class ListPatternElement implements AstNode {}

abstract final class ListPatternElementImpl
    implements AstNodeImpl, ListPatternElement {}

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
    return resolverVisitor
        .analyzeListPatternSchema(
          elementType: elementType?.wrapSharedTypeView(),
          elements: elements,
        )
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult<DartType> resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    inferenceLogWriter?.enterPattern(this);
    var analysisResult = resolverVisitor.listPatternResolver
        .resolve(node: this, context: context);
    inferenceLogWriter?.exitPattern(this);
    return analysisResult;
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
    return resolverVisitor
        .analyzeLogicalAndPatternSchema(leftOperand, rightOperand)
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult<DartType> resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    inferenceLogWriter?.enterPattern(this);
    var analysisResult = resolverVisitor.analyzeLogicalAndPattern(
        context, this, leftOperand, rightOperand);
    inferenceLogWriter?.exitPattern(this);
    return analysisResult;
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
    return resolverVisitor
        .analyzeLogicalOrPatternSchema(leftOperand, rightOperand)
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult<DartType> resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    inferenceLogWriter?.enterPattern(this);
    var analysisResult = resolverVisitor.analyzeLogicalOrPattern(
        context, this, leftOperand, rightOperand);
    resolverVisitor.nullSafetyDeadCodeVerifier.flowEnd(rightOperand);
    inferenceLogWriter?.exitPattern(this);
    return analysisResult;
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
///        '?'? [Expression] ':' '?'? [Expression]
abstract final class MapLiteralEntry implements CollectionElement {
  /// The expression computing the key with which the value is associated.
  Expression get key;

  /// The question prefix for the key that may present in null-aware map
  /// entries.
  Token? get keyQuestion;

  /// The colon that separates the key from the value.
  Token get separator;

  /// The expression computing the value that is associated with the key.
  Expression get value;

  /// The question prefix for the value that may present in null-aware map
  /// entries.
  Token? get valueQuestion;
}

final class MapLiteralEntryImpl extends CollectionElementImpl
    implements MapLiteralEntry {
  @override
  final Token? keyQuestion;

  ExpressionImpl _key;

  @override
  final Token separator;

  @override
  final Token? valueQuestion;

  ExpressionImpl _value;

  /// Initializes a newly created map literal entry.
  MapLiteralEntryImpl({
    required this.keyQuestion,
    required ExpressionImpl key,
    required this.separator,
    required this.valueQuestion,
    required ExpressionImpl value,
  })  : _key = key,
        _value = value {
    _becomeParentOf(_key);
    _becomeParentOf(_value);
  }

  @override
  Token get beginToken => keyQuestion ?? _key.beginToken;

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
    ..addToken('keyQuestion', keyQuestion)
    ..addNode('key', key)
    ..addToken('separator', separator)
    ..addToken('valueQuestion', valueQuestion)
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
  /// The elements in this pattern.
  NodeList<MapPatternElement> get elements;

  /// The left curly bracket.
  Token get leftBracket;

  /// The matched value type, or `null` if the node isn't resolved yet.
  DartType? get requiredType;

  /// The right curly bracket.
  Token get rightBracket;

  /// The type arguments associated with this pattern, or `null` if no type
  /// arguments were declared.
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
  /// The expression computing the key of the entry to be matched.
  Expression get key;

  /// The colon that separates the key from the value.
  Token get separator;

  /// The pattern used to match the value.
  DartPattern get value;
}

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
    var typeArgumentNodes = this.typeArguments?.arguments;
    ({
      SharedTypeView<DartType> keyType,
      SharedTypeView<DartType> valueType
    })? typeArguments;
    if (typeArgumentNodes != null && typeArgumentNodes.length == 2) {
      typeArguments = (
        keyType: SharedTypeView(typeArgumentNodes[0].typeOrThrow),
        valueType: SharedTypeView(typeArgumentNodes[1].typeOrThrow),
      );
    }
    return resolverVisitor
        .analyzeMapPatternSchema(
          typeArguments: typeArguments,
          elements: elements,
        )
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult<DartType> resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    return resolverVisitor.resolveMapPattern(node: this, context: context);
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
abstract final class MethodDeclaration
    implements ClassMember, _FragmentDeclaration {
  /// The token for the `augment` keyword.
  Token? get augmentKeyword;

  /// The body of the method.
  FunctionBody get body;

  @override
  ExecutableElement? get declaredElement;

  @experimental
  @override
  ExecutableFragment? get declaredFragment;

  /// The token for the `external` keyword, or `null` if the constructor isn't
  /// external.
  Token? get externalKeyword;

  /// Whether this method is declared to be an abstract method.
  bool get isAbstract;

  /// Whether this method declares a getter.
  bool get isGetter;

  /// Whether this method declares an operator.
  bool get isOperator;

  /// Whether this method declares a setter.
  bool get isSetter;

  /// Whether this method is declared to be a static method.
  bool get isStatic;

  /// The token representing the `abstract` or `static` keyword, or `null` if
  /// neither modifier was specified.
  Token? get modifierKeyword;

  /// The name of the method.
  Token get name;

  /// The token representing the `operator` keyword, or `null` if this method
  /// doesn't declare an operator.
  Token? get operatorKeyword;

  /// The parameters associated with the method, or `null` if this method
  /// declares a getter.
  FormalParameterList? get parameters;

  /// The token representing the `get` or `set` keyword, or `null` if this is a
  /// method declaration rather than a property
  /// declaration.
  Token? get propertyKeyword;

  /// The return type of the method, or `null` if no return type was declared.
  TypeAnnotation? get returnType;

  /// The type parameters associated with this method, or `null` if this method
  /// isn't a generic method.
  TypeParameterList? get typeParameters;
}

final class MethodDeclarationImpl extends ClassMemberImpl
    with AstNodeWithNameScopeMixin
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

  @experimental
  @override
  ExecutableFragment? get declaredFragment =>
      declaredElement as ExecutableFragment?;

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
    var body = this.body;
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
    ..addNode('typeParameters', typeParameters)
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
///        ([Expression] '.')? [SimpleIdentifier] [TypeArgumentList]?
///        [ArgumentList]
abstract final class MethodInvocation
    implements NullShortableExpression, InvocationExpression {
  /// Whether this expression is cascaded.
  ///
  /// If it is, then the target of this expression isn't stored locally but is
  /// stored in the nearest ancestor that is a [CascadeExpression].
  bool get isCascaded;

  /// Whether this method invocation is null aware (as opposed to non-null).
  bool get isNullAware;

  /// The name of the method being invoked.
  SimpleIdentifier get methodName;

  /// The operator that separates the target from the method name, or `null` if
  /// there's no target.
  ///
  /// In an ordinary method invocation this is either a period (`.`) or a
  /// null-aware opertator (`?.`). In a cascade section this is the cascade
  /// operator ('..').
  Token? get operator;

  /// The expression used to compute the receiver of the invocation.
  ///
  /// If this invocation isn't part of a cascade expression, then this is the
  /// same as [target]. If this invocation is part of a cascade expression,
  /// then the target stored with the cascade expression is returned.
  Expression? get realTarget;

  /// The expression producing the object on which the method is defined, or
  /// `null` if there's no target (that is, the target is implicitly `this`) or
  /// if this method invocation is part of a cascade expression.
  ///
  /// Use [realTarget] to get the target independent of whether this is part of
  /// a cascade expression.
  Expression? get target;
}

final class MethodInvocationImpl extends InvocationExpressionImpl
    with NullShortableExpressionImpl
    implements MethodInvocation {
  ExpressionImpl? _target;

  @override
  Token? operator;

  SimpleIdentifierImpl _methodName;

  /// The invoke type of the [methodName] if the target element is a getter,
  /// or `null` otherwise.
  DartType? _methodNameType;

  /// Initializes a newly created method invocation.
  ///
  /// The [target] and [operator] can be `null` if there's no target.
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
    if (target case var target?) {
      return target.beginToken;
    } else if (operator case var operator?) {
      return operator;
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
  /// [staticInvokeType].
  ///
  /// If the target element is a getter, presumably returning an
  /// [ExecutableElement] so that it can be invoked in this [MethodInvocation],
  /// then this type is the type of the getter, and the [staticInvokeType] is
  /// the invoked type of the returned element.
  DartType? get methodNameType => _methodNameType ?? staticInvokeType;

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

  /// The cascade that contains this [IndexExpression].
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
  /// The element associated with the expression based on the static types.
  ///
  /// Returns`null` if the AST structure hasn't been resolved, or there's no
  /// meaningful element to return. The latter case can occur, for example, when
  /// this is a non-compound assignment expression, or when the method referred
  /// to couldn't be resolved.
  @experimental
  MethodElement2? get element;

  /// The element associated with the expression based on the static types, or
  /// `null` if the AST structure hasn't been resolved, or there's no meaningful
  /// static element to return. The latter case can occur, for example, when
  /// this is a non-compound assignment expression, or when the method referred
  /// to couldn't be resolved.
  MethodElement? get staticElement;
}

/// The declaration of a mixin.
///
///    mixinDeclaration ::=
///        'base'? 'mixin' name [TypeParameterList]?
///        [OnClause]? [ImplementsClause]? '{' [ClassMember]* '}'
abstract final class MixinDeclaration
    implements NamedCompilationUnitMember, _FragmentDeclaration {
  /// The `augment` keyword, or `null` if the keyword was absent.
  Token? get augmentKeyword;

  /// The `base` keyword, or `null` if the keyword was absent.
  Token? get baseKeyword;

  @override
  MixinElement? get declaredElement;

  @experimental
  @override
  MixinFragment? get declaredFragment;

  /// The `implements` clause for the mixin, or `null` if the mixin doesn't
  /// implement any interfaces.
  ImplementsClause? get implementsClause;

  /// The left curly bracket.
  Token get leftBracket;

  /// The members defined by the mixin.
  NodeList<ClassMember> get members;

  /// The token representing the `mixin` keyword.
  Token get mixinKeyword;

  /// The on clause for the mixin, or `null` if the mixin doesn't have any
  /// superclass constraints.
  MixinOnClause? get onClause;

  /// The right curly bracket.
  Token get rightBracket;

  /// The type parameters for the mixin, or `null` if the mixin doesn't have any
  /// type parameters.
  TypeParameterList? get typeParameters;
}

final class MixinDeclarationImpl extends NamedCompilationUnitMemberImpl
    with AstNodeWithNameScopeMixin
    implements MixinDeclaration {
  @override
  final Token? augmentKeyword;

  @override
  final Token? baseKeyword;

  @override
  final Token mixinKeyword;

  @override
  final TypeParameterListImpl? typeParameters;

  @override
  final MixinOnClauseImpl? onClause;

  @override
  final ImplementsClauseImpl? implementsClause;

  @override
  final Token leftBracket;

  @override
  final NodeListImpl<ClassMemberImpl> members = NodeListImpl._();

  @override
  final Token rightBracket;

  @override
  MixinElementImpl? declaredElement;

  MixinDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
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

  @experimental
  @override
  MixinFragment? get declaredFragment => declaredElement as MixinFragment?;

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
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMixinDeclaration(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    typeParameters?.accept(visitor);
    onClause?.accept(visitor);
    implementsClause?.accept(visitor);
    members.accept(visitor);
  }
}

/// The "on" clause in a mixin declaration.
///
///    onClause ::=
///        'on' [NamedType] (',' [NamedType])*
abstract final class MixinOnClause implements AstNode {
  /// The token representing the `on` keyword.
  Token get onKeyword;

  /// The list of the classes are superclass constraints for the mixin.
  NodeList<NamedType> get superclassConstraints;
}

final class MixinOnClauseImpl extends AstNodeImpl implements MixinOnClause {
  @override
  final Token onKeyword;

  final NodeListImpl<NamedTypeImpl> _superclassConstraints = NodeListImpl._();

  MixinOnClauseImpl({
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
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMixinOnClause(this);

  @override
  void visitChildren(AstVisitor visitor) {
    _superclassConstraints.accept(visitor);
  }
}

/// A node that declares a single name within the scope of a compilation unit.
abstract final class NamedCompilationUnitMember
    implements CompilationUnitMember {
  /// The name of the member being declared.
  Token get name;
}

sealed class NamedCompilationUnitMemberImpl extends CompilationUnitMemberImpl
    implements NamedCompilationUnitMember {
  @override
  final Token name;

  /// Initializes a newly created compilation unit member with the given [name].
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the member
  /// doesn't have the corresponding attribute.
  NamedCompilationUnitMemberImpl({
    required super.comment,
    required super.metadata,
    required this.name,
  });
}

/// An expression that has a name associated with it.
///
/// They are only used in method invocations when there are named parameters.
///
///    namedExpression ::=
///        [Label] [Expression]
abstract final class NamedExpression implements Expression {
  /// The element representing the parameter being named by this expression, or
  /// `null` if the AST structure hasn't been resolved or if there's no
  /// parameter with the same name as this expression.
  ParameterElement? get element;

  /// The element representing the parameter being named by this expression.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if there's no
  /// parameter with the same name as this expression.
  @experimental
  FormalParameterElement? get element2;

  /// The expression with which the name is associated.
  Expression get expression;

  /// The name associated with the expression.
  Label get name;
}

final class NamedExpressionImpl extends ExpressionImpl
    implements NamedExpression {
  LabelImpl _name;

  ExpressionImpl _expression;

  /// Initializes a newly created named expression.
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

  @experimental
  @override
  FormalParameterElement? get element2 {
    if (element case FormalParameterFragment fragment) {
      return fragment.element;
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
  /// [ClassElement], or [TypeAliasElement], or `null` if [name2] can't be
  /// resolved, or there's no element for the type name, such as for `void`.
  Element? get element;

  /// The element of [name2] considering [importPrefix].
  ///
  /// This could be a [ClassElement], [TypeAliasElement], or other type defining
  /// element.
  ///
  /// Returns `null` if [name2] can't be resolved, or there's no element for the
  /// type name, such as for `void`.
  @experimental
  Element2? get element2;

  /// The optional import prefix before [name2].
  ImportPrefixReference? get importPrefix;

  /// Whether this type is a deferred type.
  ///
  /// A deferred type is a type that is referenced through an import prefix
  /// (such as `p.T`), where the prefix is used by a deferred import.
  ///
  /// Returns `false` if the AST structure hasn't been resolved.
  bool get isDeferred;

  /// The name of the type.
  Token get name2;

  /// The type being named, or `null` if the AST structure hasn't been resolved,
  /// or if this is part of a [ConstructorReference].
  @override
  DartType? get type;

  /// The type arguments associated with the type, or `null` if there are no
  /// type arguments.
  TypeArgumentList? get typeArguments;
}

final class NamedTypeImpl extends TypeAnnotationImpl implements NamedType {
  ImportPrefixReferenceImpl? _importPrefix;

  @override
  final Token name2;

  @experimental
  @override
  Element2? element2;

  @override
  TypeArgumentListImpl? typeArguments;

  @override
  final Token? question;

  @override
  DartType? type;

  /// Initializes a newly created type name.
  ///
  /// The [typeArguments] can be `null` if there are no type arguments.
  NamedTypeImpl({
    required ImportPrefixReferenceImpl? importPrefix,
    required this.name2,
    required this.typeArguments,
    required this.question,
  }) {
    this.importPrefix = importPrefix;
    _becomeParentOf(typeArguments);
  }

  @override
  Token get beginToken => importPrefix?.beginToken ?? name2;

  @override
  Element? get element {
    return element2.asElement;
  }

  @override
  Token get endToken => question ?? typeArguments?.endToken ?? name2;

  @override
  ImportPrefixReferenceImpl? get importPrefix {
    return _importPrefix;
  }

  set importPrefix(ImportPrefixReferenceImpl? value) {
    _importPrefix = value;
    _becomeParentOf(value);
  }

  @override
  bool get isDeferred {
    var importPrefixElement = importPrefix?.element;
    if (importPrefixElement is PrefixElement) {
      var imports = importPrefixElement.imports;
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
  /// The combinators used to control how names are imported or exported.
  NodeList<Combinator> get combinators;

  /// The configurations used to control which library is actually loaded at
  /// run-time.
  NodeList<Configuration> get configurations;

  /// The semicolon terminating the directive.
  Token get semicolon;
}

sealed class NamespaceDirectiveImpl extends UriBasedDirectiveImpl
    implements NamespaceDirective {
  final NodeListImpl<ConfigurationImpl> _configurations = NodeListImpl._();

  final NodeListImpl<CombinatorImpl> _combinators = NodeListImpl._();

  @override
  final Token semicolon;

  /// Initializes a newly created namespace directive.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// directive doesn't have the corresponding attribute.
  ///
  /// The list of [combinators] can be `null` if there are no combinators.
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
  /// The name of the native object that implements the class.
  StringLiteral? get name;

  /// The token representing the `native` keyword.
  Token get nativeKeyword;
}

final class NativeClauseImpl extends AstNodeImpl implements NativeClause {
  @override
  final Token nativeKeyword;

  @override
  final StringLiteralImpl? name;

  /// Initializes a newly created native clause.
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
  /// The token representing 'native' that marks the start of the function body.
  Token get nativeKeyword;

  /// The token representing the semicolon that marks the end of the function
  /// body.
  Token get semicolon;

  /// The string literal representing the string after the 'native' token.
  StringLiteral? get stringLiteral;
}

final class NativeFunctionBodyImpl extends FunctionBodyImpl
    implements NativeFunctionBody {
  @override
  final Token nativeKeyword;

  StringLiteralImpl? _stringLiteral;

  @override
  final Token semicolon;

  /// Initializes a newly created function body consisting of the 'native'
  /// token, a string literal, and a semicolon.
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
  /// The first token included in this node list's source range, or `null` if
  /// the list is empty.
  Token? get beginToken;

  /// The last token included in this node list's source range, or `null` if the
  /// list is empty.
  Token? get endToken;

  @Deprecated('NodeList cannot be resized')
  @override
  set length(int newLength);

  /// The node that is the parent of each of the elements in the list.
  AstNode get owner;

  /// Returns the node at the given [index] in the list or throw a [RangeError]
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

final class NodeListImpl<E extends AstNode>
    with ListMixin<E>
    implements NodeList<E> {
  late final AstNodeImpl _owner;

  late final List<E> _elements;

  /// Initializes a newly created list of nodes such that all of the nodes that
  /// are added to the list have their parent set to the given [owner].
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

/// A formal parameter that is required (isn't optional).
///
///    normalFormalParameter ::=
///        [FunctionTypedFormalParameter]
///      | [FieldFormalParameter]
///      | [SimpleFormalParameter]
sealed class NormalFormalParameter implements FormalParameter, AnnotatedNode {}

sealed class NormalFormalParameterImpl extends FormalParameterImpl
    with _AnnotatedNodeMixin
    implements NormalFormalParameter {
  @override
  final Token? covariantKeyword;

  @override
  final Token? requiredKeyword;

  @override
  final Token? name;

  /// Initializes a newly created formal parameter.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// parameter doesn't have the corresponding attribute.
  NormalFormalParameterImpl({
    required CommentImpl? comment,
    required List<AnnotationImpl>? metadata,
    required this.covariantKeyword,
    required this.requiredKeyword,
    required this.name,
  }) {
    _initializeCommentAndAnnotations(comment, metadata);
  }

  @override
  Token get beginToken =>
      metadata.beginToken ?? firstTokenAfterCommentAndMetadata;

  @override
  ParameterKind get kind {
    var parent = this.parent;
    if (parent is DefaultFormalParameterImpl) {
      return parent.kind;
    }
    return ParameterKind.REQUIRED;
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
    _visitCommentAndAnnotations(visitor);
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
    return resolverVisitor
        .analyzeNullCheckOrAssertPatternSchema(
          pattern,
          isAssert: true,
        )
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult<DartType> resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    inferenceLogWriter?.enterPattern(this);
    var analysisResult = resolverVisitor.analyzeNullCheckOrAssertPattern(
        context, this, pattern,
        isAssert: true);
    inferenceLogWriter?.exitPattern(this);
    return analysisResult;
  }

  @override
  void visitChildren(AstVisitor visitor) {
    pattern.accept(visitor);
  }
}

/// A null-aware element in a list or set literal.
///
///    <nullAwareExpressionElement> ::= '?' <expression>
abstract final class NullAwareElement implements CollectionElement {
  /// The question mark before the expression.
  Token get question;

  /// The expression computing the value that is associated with the element.
  Expression get value;
}

final class NullAwareElementImpl extends CollectionElementImpl
    implements NullAwareElement {
  @override
  final Token question;

  ExpressionImpl _value;

  /// Initializes a newly created null-aware element.
  NullAwareElementImpl({
    required this.question,
    required ExpressionImpl value,
  }) : _value = value {
    _becomeParentOf(_value);
  }

  @override
  Token get beginToken => question;

  @override
  Token get endToken => _value.endToken;

  @override
  ExpressionImpl get value => _value;

  set value(ExpressionImpl expression) {
    _value = _becomeParentOf(expression);
  }

  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('question', question)
    ..addNode('value', value);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNullAwareElement(this);

  @override
  void resolveElement(
      ResolverVisitor resolver, CollectionLiteralContext? context) {
    resolver.visitNullAwareElement(this, context: context);
    resolver.pushRewrite(null);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _value.accept(visitor);
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
    return resolverVisitor
        .analyzeNullCheckOrAssertPatternSchema(
          pattern,
          isAssert: false,
        )
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult<DartType> resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    inferenceLogWriter?.enterPattern(this);
    var analysisResult = resolverVisitor.analyzeNullCheckOrAssertPattern(
        context, this, pattern,
        isAssert: false);
    inferenceLogWriter?.exitPattern(this);
    return analysisResult;
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
  /// The token representing the literal.
  Token get literal;
}

final class NullLiteralImpl extends LiteralImpl implements NullLiteral {
  @override
  final Token literal;

  /// Initializes a newly created null literal.
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
  /// The expression that terminates any null shorting that might occur in this
  /// expression.
  ///
  /// This might be called regardless of whether this expression is itself
  /// null-aware.
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

  /// The ancestor of this node to which null-shorting might be extended.
  ///
  /// Usually this is just the node's parent, however if `this` is the base of
  /// a cascade section, it's the cascade expression itself, which might be a
  /// more distant ancestor.
  AstNode? get _nullShortingExtensionCandidate;

  /// Whether the effect of any null-shorting within [descendant] (which should
  /// be a descendant of `this`) should extend to include `this`.
  bool _extendsNullShorting(Expression descendant);
}

/// An object pattern.
///
///    objectPattern ::=
///        [Identifier] [TypeArgumentList]? '(' [PatternField] ')'
abstract final class ObjectPattern implements DartPattern {
  /// The patterns matching the properties of the object.
  NodeList<PatternField> get fields;

  /// The left parenthesis.
  Token get leftParenthesis;

  /// The right parenthesis.
  Token get rightParenthesis;

  /// The name of the type of object from which values are extracted.
  NamedType get type;
}

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
    return resolverVisitor
        .analyzeObjectPatternSchema(SharedTypeView(type.typeOrThrow))
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult<DartType> resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    inferenceLogWriter?.enterPattern(this);
    var result = resolverVisitor.analyzeObjectPattern(
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
      requiredType: result.requiredType.unwrapTypeView(),
      matchedValueType: result.matchedValueType.unwrapTypeView(),
    );
    inferenceLogWriter?.exitPattern(this);

    return result;
  }

  @override
  void visitChildren(AstVisitor visitor) {
    type.accept(visitor);
    fields.accept(visitor);
  }
}

/// A parenthesized expression.
///
///    parenthesizedExpression ::=
///        '(' [Expression] ')'
abstract final class ParenthesizedExpression implements Expression {
  /// The expression within the parentheses.
  Expression get expression;

  /// The left parenthesis.
  Token get leftParenthesis;

  /// The right parenthesis.
  Token get rightParenthesis;
}

final class ParenthesizedExpressionImpl extends ExpressionImpl
    implements ParenthesizedExpression {
  @override
  final Token leftParenthesis;

  ExpressionImpl _expression;

  @override
  final Token rightParenthesis;

  /// Initializes a newly created parenthesized expression.
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
  /// The left parenthesis.
  Token get leftParenthesis;

  /// The pattern within the parentheses.
  DartPattern get pattern;

  /// The right parenthesis.
  Token get rightParenthesis;
}

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
    return resolverVisitor
        .dispatchPatternSchema(pattern)
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult<DartType> resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    inferenceLogWriter?.enterPattern(this);
    var analysisResult = resolverVisitor.dispatchPattern(context, pattern);
    inferenceLogWriter?.exitPattern(this);
    return analysisResult;
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
  /// The configurations that control which file is actually included.
  NodeList<Configuration> get configurations;

  @override
  PartElement? get element;

  /// Information about this part directive.
  ///
  /// Returns `null` if the AST structure hasn't been resolved.
  @experimental
  LibraryFragmentInclude? get fragmentInclude;

  /// The token representing the `part` keyword.
  Token get partKeyword;

  /// The semicolon terminating the directive.
  Token get semicolon;
}

final class PartDirectiveImpl extends UriBasedDirectiveImpl
    implements PartDirective {
  @override
  final Token partKeyword;

  @override
  final NodeListImpl<ConfigurationImpl> configurations = NodeListImpl._();

  @override
  final Token semicolon;

  /// Initializes a newly created part directive.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// directive doesn't have the corresponding attribute.
  PartDirectiveImpl({
    required super.comment,
    required super.metadata,
    required this.partKeyword,
    required super.uri,
    required List<ConfigurationImpl>? configurations,
    required this.semicolon,
  }) {
    this.configurations._initialize(this, configurations);
  }

  @override
  PartElementImpl? get element {
    return super.element as PartElementImpl?;
  }

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata => partKeyword;

  @experimental
  @override
  LibraryFragmentInclude? get fragmentInclude =>
      element as LibraryFragmentInclude?;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('partKeyword', partKeyword)
    ..addNode('uri', uri)
    ..addNodeList('configurations', configurations)
    ..addToken('semicolon', semicolon);

  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPartDirective(this);

  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    configurations.accept(visitor);
  }
}

/// A part-of directive.
///
///    partOfDirective ::=
///        [Annotation] 'part' 'of' [Identifier] ';'
abstract final class PartOfDirective implements Directive {
  /// The name of the library that the containing compilation unit is part of,
  /// or `null` if no name was given (typically because a library URI was
  /// provided).
  LibraryIdentifier? get libraryName;

  /// The token representing the `of` keyword.
  Token get ofKeyword;

  /// The token representing the `part` keyword.
  Token get partKeyword;

  /// The semicolon terminating the directive.
  Token get semicolon;

  /// The URI of the library that the containing compilation unit is part of, or
  /// `null` if no URI was given (typically because a library name was provided).
  StringLiteral? get uri;
}

final class PartOfDirectiveImpl extends DirectiveImpl
    implements PartOfDirective {
  @override
  final Token partKeyword;

  @override
  final Token ofKeyword;

  StringLiteralImpl? _uri;

  LibraryIdentifierImpl? _libraryName;

  @override
  final Token semicolon;

  /// Initializes a newly created part-of directive.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// directive doesn't have the corresponding attribute.
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
  /// The equal sign separating the pattern from the expression.
  Token get equals;

  /// The expression that is matched by the pattern.
  Expression get expression;

  /// The pattern that matches the expression.
  DartPattern get pattern;
}

final class PatternAssignmentImpl extends ExpressionImpl
    implements PatternAssignment {
  @override
  final Token equals;

  ExpressionImpl _expression;

  @override
  final DartPatternImpl pattern;

  /// The pattern type schema, used for downward inference of [expression];
  /// or `null` if the node isn't resolved yet.
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
  // TODO(brianwilkerson): Create a new precedence constant for pattern
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
  void resolveExpression(ResolverVisitor resolver, DartType contextType) {
    resolver.visitPatternAssignment(this, contextType: contextType);
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
  /// The effective name of the field, or `null` if [name] is `null` and
  /// [pattern] isn't a variable pattern.
  ///
  /// The effective name can either be specified explicitly by [name], or
  /// implied by the variable pattern inside [pattern].
  String? get effectiveName;

  /// The element referenced by [effectiveName], or `null` if not resolved yet,
  /// non-`null` inside valid [ObjectPattern]s, always `null` inside
  /// [RecordPattern]s.
  Element? get element;

  /// The element referenced by [effectiveName].
  ///
  /// Returns `null` if the AST structure is not resolved yet.
  ///
  /// Returns non-`null` inside valid [ObjectPattern]s; always returns `null`
  /// inside [RecordPattern]s.
  @experimental
  Element2? get element2;

  /// The name of the field, or `null` if the field is a positional field.
  PatternFieldName? get name;

  /// The pattern used to match the corresponding record field.
  DartPattern get pattern;
}

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
    var nameNode = name;
    if (nameNode != null) {
      var nameToken = nameNode.name ?? pattern.variablePattern?.name;
      return nameToken?.lexeme;
    }
    return null;
  }

  @experimental
  @override
  Element2? get element2 {
    var element = this.element;
    if (element case Fragment fragment) {
      return fragment.element;
    } else if (element case Element2 element) {
      return element;
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
  /// The equal sign separating the pattern from the expression.
  Token get equals;

  /// The expression that is matched by the pattern.
  Expression get expression;

  /// The `var` or `final` keyword introducing the declaration.
  Token get keyword;

  /// The pattern that matches the expression.
  DartPattern get pattern;
}

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
  /// or `null` if the node isn't resolved yet.
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

  /// The semicolon terminating the statement.
  Token get semicolon;
}

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
  /// The expression computing the operand for the operator.
  Expression get operand;

  /// The postfix operator being applied to the operand.
  Token get operator;

  /// The element associated with the operator based on the static type of the
  /// operand, or `null` if the AST structure hasn't been resolved, if the
  /// operator isn't user definable, or if the operator couldn't be resolved.
  @override
  MethodElement? get staticElement;
}

final class PostfixExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl, CompoundAssignmentExpressionImpl
    implements PostfixExpression {
  ExpressionImpl _operand;

  @override
  final Token operator;

  @override
  MethodElement? staticElement;

  /// Initializes a newly created postfix expression.
  PostfixExpressionImpl({
    required ExpressionImpl operand,
    required this.operator,
  }) : _operand = operand {
    _becomeParentOf(_operand);
  }

  @override
  Token get beginToken => _operand.beginToken;

  @experimental
  @override
  MethodElement2? get element => (staticElement as MethodFragment?)?.element;

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

  /// The parameter element representing the parameter to which the value of the
  /// operand is bound, or `null` ff the AST structure is not resolved or the
  /// function being invoked isn't known based on static type information.
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
  /// The identifier being prefixed.
  SimpleIdentifier get identifier;

  /// Whether this type is a deferred type.
  ///
  /// A deferred type is a type that is referenced through an import prefix
  /// (such as `p.T`), where the prefix is used by a deferred import.
  ///
  /// Returns `false` if the AST structure hasn't been resolved.
  bool get isDeferred;

  /// The period used to separate the prefix from the identifier.
  Token get period;

  /// The prefix associated with the library in which the identifier is defined.
  SimpleIdentifier get prefix;
}

final class PrefixedIdentifierImpl extends IdentifierImpl
    implements PrefixedIdentifier {
  SimpleIdentifierImpl _prefix;

  @override
  final Token period;

  SimpleIdentifierImpl _identifier;

  /// Initializes a newly created prefixed identifier.
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
      var imports = element.imports;
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
  /// The element associated with the operator based on the static type of the
  /// operand, or `null` if the AST structure hasn't been resolved, if the
  /// operator isn't user definable, or if the operator couldn't be resolved.
  @override
  MethodElement? staticElement;

  /// The expression computing the operand for the operator.
  Expression get operand;

  /// The prefix operator being applied to the operand.
  Token get operator;
}

final class PrefixExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl, CompoundAssignmentExpressionImpl
    implements PrefixExpression {
  @override
  final Token operator;

  ExpressionImpl _operand;

  @override
  MethodElement? staticElement;

  /// Initializes a newly created prefix expression.
  PrefixExpressionImpl({
    required this.operator,
    required ExpressionImpl operand,
  }) : _operand = operand {
    _becomeParentOf(_operand);
  }

  @override
  Token get beginToken => operator;

  @experimental
  @override
  MethodElement2? get element => (staticElement as MethodFragment?)?.element;

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

  /// The parameter element representing the parameter to which the value of the
  /// operand is bound, or `null` if the AST structure is not resolved or the
  /// function being invoked isn't known based on static type information.
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
  /// Whether this expression is cascaded.
  ///
  /// If it is, then the target of this expression isn't stored locally but is
  /// stored in the nearest ancestor that is a [CascadeExpression].
  bool get isCascaded;

  /// Whether this property access is null aware (as opposed to non-null).
  bool get isNullAware;

  /// The property access operator.
  Token get operator;

  /// The name of the property being accessed.
  SimpleIdentifier get propertyName;

  /// The expression used to compute the receiver of the invocation.
  ///
  /// If this invocation isn't part of a cascade expression, then this is the
  /// same as [target]. If this invocation is part of a cascade expression,
  /// then the target stored with the cascade expression is returned.
  Expression get realTarget;

  /// The expression computing the object defining the property being accessed,
  /// or `null` if this property access is part of a cascade expression.
  ///
  /// Use [realTarget] to get the target independent of whether this is part of
  /// a cascade expression.
  Expression? get target;
}

final class PropertyAccessImpl extends CommentReferableExpressionImpl
    with NullShortableExpressionImpl
    implements PropertyAccess {
  ExpressionImpl? _target;

  @override
  final Token operator;

  SimpleIdentifierImpl _propertyName;

  /// Initializes a newly created property access expression.
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
    if (target case var target?) {
      return target.beginToken;
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

  /// The cascade that contains this [IndexExpression].
  ///
  /// This method assumes that [isCascaded] is `true`.
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
  /// The token representing the `const` keyword, or `null` if the literal isn't
  /// a constant.
  Token? get constKeyword;

  /// The syntactic elements used to compute the fields of the record.
  NodeList<Expression> get fields;

  /// Whether this literal is a constant expression.
  ///
  /// It is a constant expression if either the keyword `const` was explicitly
  /// provided or because no keyword was provided and this expression occurs in
  /// a constant context.
  bool get isConst;

  /// The left parenthesis.
  Token get leftParenthesis;

  /// The right parenthesis.
  Token get rightParenthesis;
}

final class RecordLiteralImpl extends LiteralImpl implements RecordLiteral {
  @override
  final Token? constKeyword;

  @override
  final Token leftParenthesis;

  final NodeListImpl<ExpressionImpl> _fields = NodeListImpl._();

  @override
  final Token rightParenthesis;

  /// Initializes a newly created record literal.
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
  /// The fields of the record pattern.
  NodeList<PatternField> get fields;

  /// The left parenthesis.
  Token get leftParenthesis;

  /// The right parenthesis.
  Token get rightParenthesis;
}

final class RecordPatternImpl extends DartPatternImpl implements RecordPattern {
  final NodeListImpl<PatternFieldImpl> _fields = NodeListImpl._();

  @override
  final Token leftParenthesis;

  @override
  final Token rightParenthesis;

  bool hasDuplicateNamedField = false;

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
    return resolverVisitor
        .analyzeRecordPatternSchema(
          fields: resolverVisitor.buildSharedPatternFields(
            fields,
            mustBeNamed: false,
          ),
        )
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult<DartType> resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    inferenceLogWriter?.enterPattern(this);
    var result = resolverVisitor.analyzeRecordPattern(
      context,
      this,
      fields: resolverVisitor.buildSharedPatternFields(
        fields,
        mustBeNamed: false,
      ),
    );

    if (!hasDuplicateNamedField) {
      resolverVisitor.checkPatternNeverMatchesValueType(
        context: context,
        pattern: this,
        requiredType: result.requiredType.unwrapTypeView(),
        matchedValueType: result.matchedValueType.unwrapTypeView(),
      );
    }
    inferenceLogWriter?.exitPattern(this);

    return result;
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
  /// The list of arguments to the constructor.
  ArgumentList get argumentList;

  /// The name of the constructor that is being invoked, or `null` if the
  /// unnamed constructor is being invoked.
  SimpleIdentifier? get constructorName;

  /// The token for the period before the name of the constructor that is being
  /// invoked, or `null` if the unnamed constructor is being invoked.
  Token? get period;

  /// The element associated with the constructor based on static type
  /// information, or `null` if the AST structure hasn't been resolved or if the
  /// constructor couldn't be resolved.
  @override
  ConstructorElement? get staticElement;

  /// The token for the `this` keyword.
  Token get thisKeyword;
}

final class RedirectingConstructorInvocationImpl
    extends ConstructorInitializerImpl
    implements RedirectingConstructorInvocation {
  @override
  final Token thisKeyword;

  @override
  final Token? period;

  SimpleIdentifierImpl? _constructorName;

  ArgumentListImpl _argumentList;

  @override
  ConstructorElement? staticElement;

  /// Initializes a newly created redirecting invocation to invoke the
  /// constructor with the given name with the given arguments.
  ///
  /// The [constructorName] can be `null` if the constructor being invoked is
  /// the unnamed constructor.
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

  @experimental
  @override
  ConstructorElement2? get element =>
      staticElement?.asElement2 as ConstructorElement2?;

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

  /// The element of the [operator] for the matched type.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if the
  /// operator couldn't be resolved.
  @experimental
  MethodElement2? get element2;

  /// The expression used to compute the operand.
  Expression get operand;

  /// The relational operator being applied.
  Token get operator;
}

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

  @experimental
  @override
  MethodElement2? get element2 {
    if (element case MethodFragment fragment) {
      return fragment.element;
    }
    return null;
  }

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
    return resolverVisitor
        .analyzeRelationalPatternSchema()
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult<DartType> resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    inferenceLogWriter?.enterPattern(this);
    var analysisResult =
        resolverVisitor.analyzeRelationalPattern(context, this, operand);
    resolverVisitor.popRewrite();
    inferenceLogWriter?.exitPattern(this);
    return analysisResult;
  }

  @override
  void visitChildren(AstVisitor visitor) {
    operand.accept(visitor);
  }
}

/// The name of the primary constructor of an extension type.
@experimental
abstract final class RepresentationConstructorName implements AstNode {
  /// The name of the primary constructor.
  Token get name;

  /// The period separating [name] from the previous token.
  Token get period;
}

final class RepresentationConstructorNameImpl extends AstNodeImpl
    implements RepresentationConstructorName {
  @override
  final Token period;

  @override
  final Token name;

  RepresentationConstructorNameImpl({
    required this.period,
    required this.name,
  });

  @override
  Token get beginToken => period;

  @override
  Token get endToken => name;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('period', period)
    ..addToken('name', name);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitRepresentationConstructorName(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {}
}

/// The declaration of an extension type representation.
///
/// It declares both the representation field and the primary constructor.
///
///    <representationDeclaration> ::=
///        ('.' <identifierOrNew>)? '(' <metadata> <type> <identifier> ')'
@experimental
abstract final class RepresentationDeclaration implements AstNode {
  /// The element of the primary constructor.
  ConstructorElement? get constructorElement;

  /// The fragment of the primary constructor contained in this declaration.
  @experimental
  ConstructorFragment? get constructorFragment;

  /// The optional name of the primary constructor.
  RepresentationConstructorName? get constructorName;

  /// The element for [fieldName] with [fieldType].
  FieldElement? get fieldElement;

  /// The fragment for [fieldName] with [fieldType] contained in this
  /// declaration.
  @experimental
  FieldFragment? get fieldFragment;

  /// The annotations associated with the field.
  NodeList<Annotation> get fieldMetadata;

  /// The representation name.
  Token get fieldName;

  /// The representation type.
  TypeAnnotation get fieldType;

  /// The left parenthesis.
  Token get leftParenthesis;

  /// The right parenthesis.
  Token get rightParenthesis;
}

final class RepresentationDeclarationImpl extends AstNodeImpl
    implements RepresentationDeclaration {
  @override
  final RepresentationConstructorNameImpl? constructorName;

  @override
  ConstructorElementImpl? constructorElement;

  @override
  final Token leftParenthesis;

  @override
  final NodeListImpl<AnnotationImpl> fieldMetadata = NodeListImpl._();

  @override
  final TypeAnnotationImpl fieldType;

  @override
  final Token fieldName;

  @override
  FieldElementImpl? fieldElement;

  @override
  final Token rightParenthesis;

  RepresentationDeclarationImpl({
    required this.constructorName,
    required this.leftParenthesis,
    required List<AnnotationImpl> fieldMetadata,
    required this.fieldType,
    required this.fieldName,
    required this.rightParenthesis,
  }) {
    this.fieldMetadata._initialize(this, fieldMetadata);
    _becomeParentOf(constructorName);
    _becomeParentOf(fieldType);
  }

  @override
  Token get beginToken => constructorName?.beginToken ?? leftParenthesis;

  @experimental
  @override
  ConstructorFragment? get constructorFragment =>
      constructorElement as ConstructorFragment?;

  @override
  Token get endToken => rightParenthesis;

  @experimental
  @override
  FieldFragment? get fieldFragment => fieldElement as FieldFragment?;

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addNode('constructorName', constructorName)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNodeList('fieldMetadata', fieldMetadata)
    ..addNode('fieldType', fieldType)
    ..addToken('fieldName', fieldName)
    ..addToken('rightParenthesis', rightParenthesis);

  @override
  E? accept<E>(AstVisitor<E> visitor) {
    return visitor.visitRepresentationDeclaration(this);
  }

  @override
  void visitChildren(AstVisitor visitor) {
    constructorName?.accept(visitor);
    fieldMetadata.accept(visitor);
    fieldType.accept(visitor);
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
  /// The token representing the `rethrow` keyword.
  Token get rethrowKeyword;
}

final class RethrowExpressionImpl extends ExpressionImpl
    implements RethrowExpression {
  @override
  final Token rethrowKeyword;

  /// Initializes a newly created rethrow expression.
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
  /// The expression computing the value to be returned, or `null` if no
  /// explicit value was provided.
  Expression? get expression;

  /// The token representing the `return` keyword.
  Token get returnKeyword;

  /// The semicolon terminating the statement.
  Token get semicolon;
}

final class ReturnStatementImpl extends StatementImpl
    implements ReturnStatement {
  @override
  final Token returnKeyword;

  ExpressionImpl? _expression;

  @override
  final Token semicolon;

  /// Initializes a newly created return statement.
  ///
  /// The [expression] can be `null` if no explicit value was provided.
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
  /// The token representing this script tag.
  Token get scriptTag;
}

final class ScriptTagImpl extends AstNodeImpl implements ScriptTag {
  @override
  final Token scriptTag;

  /// Initializes a newly created script tag.
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
/// is used to represent a map literal and `SetLiteral` is used for set
/// literals.
abstract final class SetOrMapLiteral implements TypedLiteral {
  /// The syntactic elements used to compute the elements of the set or map.
  NodeList<CollectionElement> get elements;

  /// Whether this literal represents a map literal.
  ///
  /// This getter always returns `false` if [isSet] returns `true`.
  ///
  /// However, this getter is _not_ the inverse of [isSet]. It's possible for
  /// both getters to return `false` if
  ///
  /// - the AST hasn't been resolved (because determining the kind of the
  ///   literal is done during resolution),
  /// - the literal is ambiguous (contains one or more spread elements and none
  ///   of those elements can be used to determine the kind of the literal), or
  /// - the literal is invalid because it contains both expressions (for sets)
  ///   and map entries (for maps).
  ///
  /// In both of the latter two cases there are compilation errors associated
  /// with the literal.
  bool get isMap;

  /// Whether this literal represents a set literal.
  ///
  /// This getter always returns `false` if [isMap] returns `true`.
  ///
  /// However, this getter is _not_ the inverse of [isMap]. It's possible for
  /// both getters to return `false` if
  ///
  /// - the AST hasn't been resolved (because determining the kind of the
  ///   literal is done during resolution),
  /// - the literal is ambiguous (contains one or more spread elements and none
  ///   of those elements can be used to determine the kind of the literal), or
  /// - the literal is invalid because it contains both expressions (for sets)
  ///   and map entries (for maps).
  ///
  /// In both of the latter two cases there are compilation errors associated
  /// with the literal.
  bool get isSet;

  /// The left curly bracket.
  Token get leftBracket;

  /// The right curly bracket.
  Token get rightBracket;
}

final class SetOrMapLiteralImpl extends TypedLiteralImpl
    implements SetOrMapLiteral {
  @override
  final Token leftBracket;

  final NodeListImpl<CollectionElementImpl> _elements = NodeListImpl._();

  @override
  final Token rightBracket;

  /// A representation of whether this literal represents a map or a set, or
  /// whether the kind hasn't or can't be determined.
  _SetOrMapKind _resolvedKind = _SetOrMapKind.unresolved;

  /// The context type computed by
  /// [ResolverVisitor._computeSetOrMapContextType].
  ///
  /// Note that this isn't the same as the context pushed down by type
  /// inference (which can be obtained via [InferenceContext.getContext]). For
  /// example, in the following code:
  ///
  ///     var m = {};
  ///
  /// The context pushed down by type inference is null, whereas the
  /// `contextType` is `Map<dynamic, dynamic>`.
  InterfaceType? contextType;

  /// Initializes a newly created set or map literal.
  ///
  /// The [constKeyword] can be `null` if the literal isn't a constant.
  ///
  /// The [typeArguments] can be `null` if no type arguments were declared.
  ///
  /// The [elements] can be `null` if the set is empty.
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
    if (constKeyword case var constKeyword?) {
      return constKeyword;
    }
    var typeArguments = this.typeArguments;
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

/// A combinator that restricts the names being imported to those in a given
/// list.
///
///    showCombinator ::=
///        'show' [SimpleIdentifier] (',' [SimpleIdentifier])*
abstract final class ShowCombinator implements Combinator {
  /// The list of names from the library that are made visible by this
  /// combinator.
  NodeList<SimpleIdentifier> get shownNames;
}

final class ShowCombinatorImpl extends CombinatorImpl
    implements ShowCombinator {
  final NodeListImpl<SimpleIdentifierImpl> _shownNames = NodeListImpl._();

  /// Initializes a newly created import show combinator.
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
///        ('final' [TypeAnnotation] | 'var' | [TypeAnnotation])?
///        [SimpleIdentifier]
abstract final class SimpleFormalParameter implements NormalFormalParameter {
  /// The token representing either the `final`, `const` or `var` keyword, or
  /// `null` if no keyword was used.
  Token? get keyword;

  /// The declared type of the parameter, or `null` if the parameter doesn't
  /// have a declared type.
  TypeAnnotation? get type;
}

final class SimpleFormalParameterImpl extends NormalFormalParameterImpl
    implements SimpleFormalParameter {
  @override
  final Token? keyword;

  TypeAnnotationImpl? _type;

  /// Initializes a newly created formal parameter.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// parameter doesn't have the corresponding attribute.
  ///
  /// The [keyword] can be `null` if a type was specified.
  ///
  /// The [type] must be `null` if the keyword is `var`.
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
  Token get endToken => name ?? type!.endToken;

  @override
  Token get firstTokenAfterCommentAndMetadata =>
      requiredKeyword ??
      covariantKeyword ??
      keyword ??
      type?.beginToken ??
      name!;

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
  /// Whether this identifier is the "name" part of a prefixed identifier or a
  /// method invocation.
  bool get isQualified;

  /// If the identifier is a tear-off, return the inferred type arguments
  /// applied to the function type of the element to produce its `[staticType]`.
  ///
  /// An empty list if the function type doesn't have type parameters or if the
  /// context type has type parameters, or `null` if this node isn't a tear-off
  /// or if the AST structure hasn't been resolved.
  List<DartType>? get tearOffTypeArgumentTypes;

  /// The token representing the identifier.
  Token get token;

  /// Whether this identifier is the name being declared in a declaration.
  // TODO(brianwilkerson): Convert this to a getter.
  bool inDeclarationContext();

  /// Whether this expression is computing a right-hand value.
  ///
  /// Note that [inGetterContext] and [inSetterContext] aren't opposites, nor
  /// are they mutually exclusive. In other words, it's possible for both
  /// methods to return `true` when invoked on the same node.
  // TODO(brianwilkerson): Convert this to a getter.
  bool inGetterContext();

  /// Whether this expression is computing a left-hand value.
  ///
  /// Note that [inGetterContext] and [inSetterContext] aren't opposites, nor
  /// are they mutually exclusive. In other words, it's possible for both
  /// methods to return `true` when invoked on the same node.
  // TODO(brianwilkerson): Convert this to a getter.
  bool inSetterContext();
}

final class SimpleIdentifierImpl extends IdentifierImpl
    implements SimpleIdentifier {
  @override
  Token token;

  /// The element associated with this identifier based on static type
  /// information, or `null` if the AST structure hasn't been resolved or if
  /// this identifier couldn't be resolved.
  Element? _staticElement;

  @override
  List<DartType>? tearOffTypeArgumentTypes;

  /// If this identifier is meant to be looked up in the enclosing scope, the
  /// raw result the scope lookup, prior to figuring out whether a write or a
  /// read context is intended, and prior to falling back on implicit `this` (if
  /// appropriate).
  ///
  /// Or `null` if this identifier isn't meant to be looked up in the enclosing
  /// scope.
  ScopeLookupResult? scopeLookupResult;

  /// Initializes a newly created identifier.
  SimpleIdentifierImpl(this.token);

  /// The cascade that contains this [SimpleIdentifier].
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
    var parent = this.parent!;
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

  /// The element being referenced by this identifier, or `null` if this
  /// identifier is used to either read or write a value, the AST structure
  /// hasn't been resolved, or if this identifier couldn't be resolved.
  ///
  /// This element is set when this identifier is used not as an expression,
  /// but just to reference some element.
  ///
  /// Examples are the name of the type in a [NamedType], the name of the method
  /// in a [MethodInvocation], the name of the constructor in a
  /// [ConstructorName], the name of the property in a [PropertyAccess], the
  /// prefix and the identifier in a [PrefixedIdentifier] (which then can be
  /// used to read or write a value).
  ///
  /// In invalid code, for recovery, any element could be used. For example, in
  /// `set mySetter(_) {} mySetter topVar;` a setter is used as a type name. We
  /// do this to help the user to navigate to this element, and maybe change its
  /// name, add a new declaration, etc.
  ///
  /// If either [readElement] or [writeElement] aren't `null`, the
  /// [referenceElement] is `null`, because the identifier is being used to
  /// read or write a value.
  ///
  /// All three of [readElement], [writeElement], and [referenceElement] can be
  /// `null` when the AST structure hasn't been resolved, or this identifier
  /// couldn't be resolved.
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
    var parent = this.parent;
    switch (parent) {
      case ImportDirective():
        return parent.prefix == this;
      case Label():
        var parent2 = parent.parent;
        return parent2 is Statement || parent2 is SwitchMember;
    }
    return false;
  }

  @override
  bool inGetterContext() {
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

/// A string literal expression that doesn't contain any interpolations.
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
  /// The token representing the literal.
  Token get literal;

  /// The value of the literal.
  String get value;
}

final class SimpleStringLiteralImpl extends SingleStringLiteralImpl
    implements SimpleStringLiteral {
  @override
  final Token literal;

  @override
  String value;

  /// Initializes a newly created simple string literal.
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
  /// The offset of the after-last contents character.
  int get contentsEnd;

  /// The offset of the first contents character.
  ///
  /// If the string is multiline, then leading whitespaces are skipped.
  int get contentsOffset;

  /// Whether this string literal is a multi-line string.
  bool get isMultiline;

  /// Whether this string literal is a raw string.
  bool get isRaw;

  /// Whether this string literal uses single quotes (' or ''').
  ///
  /// If `false` is returned then the string literal uses double quotes
  /// (" or """).
  bool get isSingleQuoted;
}

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
  /// If this is a labeled statement, returns the statement being labeled,
  /// otherwise returns the statement itself.
  Statement get unlabeled;
}

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
  /// The elements that are composed to produce the resulting string.
  ///
  /// The list includes [firstString] and [lastString].
  NodeList<InterpolationElement> get elements;

  /// The first element in this interpolation, which is always a string.
  ///
  /// The string might be empty if there's no text before the first
  /// interpolation expression (such as in `'$foo bar'`).
  InterpolationString get firstString;

  /// The last element in this interpolation, which is always a string.
  ///
  /// The string might be empty if there's no text after the last
  /// interpolation expression (such as in `'foo $bar'`).
  InterpolationString get lastString;
}

final class StringInterpolationImpl extends SingleStringLiteralImpl
    implements StringInterpolation {
  /// The elements that are composed to produce the resulting string.
  final NodeListImpl<InterpolationElementImpl> _elements = NodeListImpl._();

  /// Initializes a newly created string interpolation expression.
  StringInterpolationImpl({
    required List<InterpolationElementImpl> elements,
  }) {
    // TODO(scheglov): Replace asserts with appropriately typed parameters.
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
  /// given [start] index, returns the index of the first character that is
  /// included in the value of the string.
  ///
  /// According to the specification:
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
  /// The value of the string literal, or `null` if the string isn't a constant
  /// string without any string interpolation.
  String? get stringValue;
}

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

  /// Append the value of this string literal to the given [buffer].
  ///
  /// Throw an [ArgumentError] if the string isn't a constant string without any
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
  /// The list of arguments to the constructor.
  ArgumentList get argumentList;

  /// The name of the constructor that is being invoked, or `null` if the
  /// unnamed constructor is being invoked.
  SimpleIdentifier? get constructorName;

  /// The token for the period before the name of the constructor that is being
  /// invoked, or `null` if the unnamed constructor is being invoked.
  Token? get period;

  /// The token for the `super` keyword.
  Token get superKeyword;
}

final class SuperConstructorInvocationImpl extends ConstructorInitializerImpl
    implements SuperConstructorInvocation {
  @override
  final Token superKeyword;

  @override
  final Token? period;

  SimpleIdentifierImpl? _constructorName;

  ArgumentListImpl _argumentList;

  @override
  ConstructorElement? staticElement;

  /// Initializes a newly created super invocation to invoke the inherited
  /// constructor with the given name with the given arguments.
  ///
  /// The [period] and [constructorName] can be `null` if the constructor being
  /// invoked is the unnamed constructor.
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

  @experimental
  @override
  ConstructorElement2? get element =>
      staticElement?.asElement2 as ConstructorElement2?;

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
  /// The token representing the `super` keyword.
  Token get superKeyword;
}

final class SuperExpressionImpl extends ExpressionImpl
    implements SuperExpression {
  @override
  final Token superKeyword;

  /// Initializes a newly created super expression.
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
///        ('final' [TypeAnnotation] | 'const' [TypeAnnotation] | 'var' |
///        [TypeAnnotation])?
///        'super' '.' name ([TypeParameterList]? [FormalParameterList])?
abstract final class SuperFormalParameter implements NormalFormalParameter {
  /// The token representing either the `final`, `const` or `var` keyword, or
  /// `null` if no keyword was used.
  Token? get keyword;

  /// The name of the parameter being declared.
  @override
  Token get name;

  /// The parameters of the function-typed parameter, or `null` if this isn't a
  /// function-typed field formal parameter.
  FormalParameterList? get parameters;

  /// The token representing the period.
  Token get period;

  /// The question mark indicating that the function type is nullable, or `null`
  /// if there's no question mark, which will always be the case when the
  /// parameter doesn't use the older style for denoting a function typed
  /// parameter.
  ///
  /// If the parameter is function-typed, and has the question mark, then its
  /// function type is nullable. Having a nullable function type means that the
  /// parameter can be `null`.
  Token? get question;

  /// The token representing the `super` keyword.
  Token get superKeyword;

  /// The declared type of the parameter, or `null` if the parameter doesn't
  /// have a declared type.
  ///
  /// If this is a function-typed field formal parameter this is the return type
  /// of the function.
  TypeAnnotation? get type;

  /// The type parameters associated with this method, or `null` if this method
  /// isn't a generic method.
  TypeParameterList? get typeParameters;
}

final class SuperFormalParameterImpl extends NormalFormalParameterImpl
    implements SuperFormalParameter {
  @override
  final Token? keyword;

  TypeAnnotationImpl? _type;

  @override
  final Token superKeyword;

  @override
  final Token period;

  TypeParameterListImpl? _typeParameters;

  FormalParameterListImpl? _parameters;

  @override
  final Token? question;

  /// Initializes a newly created formal parameter.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// parameter doesn't have the corresponding attribute.
  ///
  /// The [keyword] can be `null` if there's a type.
  ///
  /// The [type] must be `null` if the keyword is `var`.
  ///
  /// The [thisKeyword] and [period] can be `null` if the keyword `this` isn't
  /// provided.
  ///
  /// The[parameters] can be `null` if this isn't a function-typed field formal
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
  Token get endToken {
    return question ?? _parameters?.endToken ?? name;
  }

  @override
  Token get firstTokenAfterCommentAndMetadata =>
      requiredKeyword ??
      covariantKeyword ??
      keyword ??
      type?.beginToken ??
      superKeyword;

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
  /// The expression controlling whether the statements are executed.
  Expression get expression;
}

final class SwitchCaseImpl extends SwitchMemberImpl implements SwitchCase {
  ExpressionImpl _expression;

  /// Initializes a newly created switch case.
  ///
  /// The list of [labels] can be `null` if there are no labels.
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

final class SwitchDefaultImpl extends SwitchMemberImpl
    implements SwitchDefault {
  /// Initializes a newly created switch default.
  ///
  /// The list of [labels] can be `null` if there are no labels.
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
  /// The cases that can be selected by the expression.
  NodeList<SwitchExpressionCase> get cases;

  /// The expression used to determine which of the switch cases is selected.
  Expression get expression;

  /// The left curly bracket.
  Token get leftBracket;

  /// The left parenthesis.
  Token get leftParenthesis;

  /// The right curly bracket.
  Token get rightBracket;

  /// The right parenthesis.
  Token get rightParenthesis;

  /// The token representing the `switch` keyword.
  Token get switchKeyword;
}

/// A case in a switch expression.
///
///    switchExpressionCase ::=
///        [GuardedPattern] '=>' [Expression]
abstract final class SwitchExpressionCase implements AstNode {
  /// The arrow separating the pattern from the expression.
  Token get arrow;

  /// The expression whose value is returned from the switch expression if the
  /// pattern matches.
  Expression get expression;

  /// The refutable pattern that must match for the [expression] to be executed.
  GuardedPattern get guardedPattern;
}

final class SwitchExpressionCaseImpl extends AstNodeImpl
    with AstNodeWithNameScopeMixin
    implements SwitchExpressionCase, CaseNodeImpl {
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
    inferenceLogWriter?.enterExpression(this, contextType);
    var previousExhaustiveness = resolver.legacySwitchExhaustiveness;
    var staticType = resolver
        .analyzeSwitchExpression(
            this, expression, cases.length, SharedTypeSchemaView(contextType))
        .type
        .unwrapTypeView();
    recordStaticType(staticType, resolver: resolver);
    resolver.popRewrite();
    resolver.legacySwitchExhaustiveness = previousExhaustiveness;
    inferenceLogWriter?.exitExpression(this);
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
// TODO(brianwilkerson): Consider renaming `SwitchMember`, `SwitchCase`, and
//  `SwitchDefault` to start with `SwitchStatement` for consistency.
sealed class SwitchMember implements AstNode {
  /// The colon separating the keyword or the expression from the statements.
  Token get colon;

  /// The token representing the `case` or `default` keyword.
  Token get keyword;

  /// The labels associated with the switch member.
  NodeList<Label> get labels;

  /// The statements that are executed if this switch member is selected.
  NodeList<Statement> get statements;
}

sealed class SwitchMemberImpl extends AstNodeImpl
    with AstNodeWithNameScopeMixin
    implements SwitchMember {
  final NodeListImpl<LabelImpl> _labels = NodeListImpl._();

  @override
  final Token keyword;

  @override
  final Token colon;

  final NodeListImpl<StatementImpl> _statements = NodeListImpl._();

  /// Initializes a newly created switch member.
  ///
  /// The list of [labels] can be `null` if there are no labels.
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
  /// The pattern controlling whether the statements is executed.
  GuardedPattern get guardedPattern;
}

final class SwitchPatternCaseImpl extends SwitchMemberImpl
    implements SwitchPatternCase, CaseNodeImpl {
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
  /// The expression used to determine which of the switch members is selected.
  Expression get expression;

  /// The left curly bracket.
  Token get leftBracket;

  /// The left parenthesis.
  Token get leftParenthesis;

  /// The switch members that can be selected by the expression.
  NodeList<SwitchMember> get members;

  /// The right curly bracket.
  Token get rightBracket;

  /// The right parenthesis.
  Token get rightParenthesis;

  /// The token representing the `switch` keyword.
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

final class SwitchStatementImpl extends StatementImpl
    implements SwitchStatement {
  @override
  final Token switchKeyword;

  @override
  final Token leftParenthesis;

  ExpressionImpl _expression;

  @override
  final Token rightParenthesis;

  @override
  final Token leftBracket;

  final NodeListImpl<SwitchMemberImpl> _members = NodeListImpl._();

  late final List<SwitchStatementCaseGroup> memberGroups =
      _computeMemberGroups();

  @override
  final Token rightBracket;

  /// Initializes a newly created switch statement.
  ///
  /// The list of [members] can be `null` if there are no switch members.
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
  /// The components of the literal.
  List<Token> get components;

  /// The token introducing the literal.
  Token get poundSign;
}

final class SymbolLiteralImpl extends LiteralImpl implements SymbolLiteral {
  @override
  final Token poundSign;

  @override
  final List<Token> components;

  /// Initializes a newly created symbol literal.
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
/// there's no identifier in the AST structure.
///
/// For example, there's no identifier in the AST when the parser can't
/// distinguish between a method invocation and an invocation of a top-level
/// function imported with a prefix.
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
  /// The token representing the `this` keyword.
  Token get thisKeyword;
}

final class ThisExpressionImpl extends ExpressionImpl
    implements ThisExpression {
  @override
  final Token thisKeyword;

  /// Initializes a newly created this expression.
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
  /// The expression computing the exception to be thrown.
  Expression get expression;

  /// The token representing the `throw` keyword.
  Token get throwKeyword;
}

final class ThrowExpressionImpl extends ExpressionImpl
    implements ThrowExpression {
  @override
  final Token throwKeyword;

  ExpressionImpl _expression;

  /// Initializes a newly created throw expression.
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
/// (Note: there's no `<topLevelVariableDeclaration>` production in the grammar;
/// this is a subset of the grammar production `<topLevelDeclaration>`, which
/// encompasses everything that can appear inside a Dart file after part
/// directives).
abstract final class TopLevelVariableDeclaration
    implements CompilationUnitMember {
  /// The `augment` keyword, or `null` if the keyword was absent.
  @experimental
  Token? get augmentKeyword;

  /// The `external` keyword, or `null` if the keyword isn't used.
  Token? get externalKeyword;

  /// The semicolon terminating the declaration.
  Token get semicolon;

  /// The top-level variables being declared.
  VariableDeclarationList get variables;
}

final class TopLevelVariableDeclarationImpl extends CompilationUnitMemberImpl
    implements TopLevelVariableDeclaration {
  VariableDeclarationListImpl _variableList;

  @override
  final Token? augmentKeyword;

  @override
  final Token? externalKeyword;

  @override
  final Token semicolon;

  /// Initializes a newly created top-level variable declaration.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// variable doesn't have the corresponding attribute.
  TopLevelVariableDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
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
      augmentKeyword ?? externalKeyword ?? _variableList.beginToken;

  @override
  VariableDeclarationListImpl get variables => _variableList;

  set variables(VariableDeclarationListImpl variables) {
    _variableList = _becomeParentOf(variables);
  }

  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('augmentKeyword', augmentKeyword)
    ..addToken('externalKeyword', externalKeyword)
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
  /// The body of the statement.
  Block get body;

  /// The catch clauses contained in the try statement.
  NodeList<CatchClause> get catchClauses;

  /// The finally block contained in the try statement, or `null` if the
  /// statement doesn't contain a finally clause.
  Block? get finallyBlock;

  /// The token representing the `finally` keyword, or `null` if the statement
  /// doesn't contain a finally clause.
  Token? get finallyKeyword;

  /// The token representing the `try` keyword.
  Token get tryKeyword;
}

final class TryStatementImpl extends StatementImpl implements TryStatement {
  @override
  final Token tryKeyword;

  BlockImpl _body;

  final NodeListImpl<CatchClauseImpl> _catchClauses = NodeListImpl._();

  @override
  final Token? finallyKeyword;

  BlockImpl? _finallyBlock;

  /// Initializes a newly created try statement.
  ///
  /// The [finallyKeyword] and [finallyBlock] can be `null` if there's no
  /// finally clause.
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
    if (finallyBlock case var finallyBlock?) {
      return finallyBlock.endToken;
    } else if (finallyKeyword case var finallyKeyword?) {
      return finallyKeyword;
    } else if (_catchClauses case [..., var last]) {
      return last.endToken;
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
  /// The `augment` keyword, or `null` if the keyword was absent.
  @experimental
  Token? get augmentKeyword;

  /// The semicolon terminating the declaration.
  Token get semicolon;

  /// The token representing the `typedef` or `class` keyword.
  Token get typedefKeyword;
}

sealed class TypeAliasImpl extends NamedCompilationUnitMemberImpl
    implements TypeAlias {
  @override
  final Token? augmentKeyword;

  @override
  final Token typedefKeyword;

  @override
  final Token semicolon;

  /// Initializes a newly created type alias.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// declaration doesn't have the corresponding attribute.
  TypeAliasImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
    required this.typedefKeyword,
    required super.name,
    required this.semicolon,
  });

  @override
  Token get endToken => semicolon;

  @override
  Token get firstTokenAfterCommentAndMetadata {
    return augmentKeyword ?? typedefKeyword;
  }
}

/// A type annotation.
///
///    type ::=
///        [NamedType]
///      | [GenericFunctionType]
///      | [RecordTypeAnnotation]
sealed class TypeAnnotation implements AstNode {
  /// The question mark indicating that the type is nullable, or `null` if
  /// there's no question mark.
  Token? get question;

  /// The type being named, or `null` if the AST structure hasn't been resolved.
  DartType? get type;
}

sealed class TypeAnnotationImpl extends AstNodeImpl implements TypeAnnotation {}

/// A list of type arguments.
///
///    typeArguments ::=
///        '<' typeName (',' typeName)* '>'
abstract final class TypeArgumentList implements AstNode {
  /// The type arguments associated with the type.
  NodeList<TypeAnnotation> get arguments;

  /// The left bracket.
  Token get leftBracket;

  /// The right bracket.
  Token get rightBracket;
}

final class TypeArgumentListImpl extends AstNodeImpl
    implements TypeArgumentList {
  @override
  final Token leftBracket;

  final NodeListImpl<TypeAnnotationImpl> _arguments = NodeListImpl._();

  @override
  final Token rightBracket;

  /// Initializes a newly created list of type arguments.
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
  /// The token representing the `const` keyword, or `null` if the literal isn't
  /// a constant.
  Token? get constKeyword;

  /// Whether this literal is a constant expression.
  ///
  /// It is a constant expression if either the keyword `const` was explicitly
  /// provided or because no keyword was provided and this expression occurs in
  /// a constant context.
  bool get isConst;

  /// The type argument associated with this literal, or `null` if no type
  /// arguments were declared.
  TypeArgumentList? get typeArguments;
}

sealed class TypedLiteralImpl extends LiteralImpl implements TypedLiteral {
  @override
  Token? constKeyword;

  TypeArgumentListImpl? _typeArguments;

  /// Initializes a newly created typed literal.
  ///
  /// The [constKeyword] can be `null` if the literal isn't a constant.
  ///
  /// The [typeArguments] can be `null` if no type arguments were declared.
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

/// An expression representing a type, such as the expression `int` in
/// `var x = int;`.
///
/// Objects of this type aren't produced directly by the parser (because the
/// parser can't tell whether an identifier refers to a type); they are
/// produced at resolution time.
///
/// The `.staticType` getter returns the type of the expression (which is
/// always the type `Type`). To get the type represented by the type literal
/// use `.typeName.type`.
abstract final class TypeLiteral
    implements Expression, CommentReferableExpression {
  /// The type represented by this literal.
  NamedType get type;
}

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
abstract final class TypeParameter
    implements Declaration, _FragmentDeclaration {
  /// The upper bound for legal arguments, or `null` if there's no explicit
  /// upper bound.
  TypeAnnotation? get bound;

  @override
  TypeParameterElement? get declaredElement;

  @experimental
  @override
  TypeParameterFragment? get declaredFragment;

  /// The token representing the `extends` keyword, or `null` if there's no
  /// explicit upper bound.
  Token? get extendsKeyword;

  /// The name of the type parameter.
  Token get name;
}

final class TypeParameterImpl extends DeclarationImpl implements TypeParameter {
  @override
  final Token name;

  /// The token representing the variance modifier keyword, or `null` if there's
  /// no explicit variance modifier, meaning legacy covariance.
  Token? varianceKeyword;

  @override
  Token? extendsKeyword;

  TypeAnnotationImpl? _bound;

  @override
  TypeParameterElementImpl? declaredElement;

  /// Initializes a newly created type parameter.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// parameter doesn't have the corresponding attribute.
  ///
  /// The [extendsKeyword] and [bound] can be `null` if the parameter doesn't
  /// have a bound.
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

  @experimental
  @override
  TypeParameterFragment? get declaredFragment =>
      declaredElement as TypeParameterFragment?;

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
  /// The left angle bracket.
  Token get leftBracket;

  /// The right angle bracket.
  Token get rightBracket;

  /// The type parameters for the type.
  NodeList<TypeParameter> get typeParameters;
}

final class TypeParameterListImpl extends AstNodeImpl
    implements TypeParameterList {
  @override
  final Token leftBracket;

  final NodeListImpl<TypeParameterImpl> _typeParameters = NodeListImpl._();

  @override
  final Token rightBracket;

  /// Initializes a newly created list of type parameters.
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
  /// The URI referenced by this directive.
  StringLiteral get uri;
}

sealed class UriBasedDirectiveImpl extends DirectiveImpl
    implements UriBasedDirective {
  StringLiteralImpl _uri;

  /// Initializes a newly create URI-based directive.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// directive doesn't have the corresponding attribute.
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

  /// Validate this directive, but don't check for existence.
  ///
  /// Returns a code indicating the problem if a problem was found, or `null` if
  /// there's no problem.
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

  /// Initializes a newly created validation code to have the given [name].
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
// TODO(paulberry): The grammar doesn't allow metadata to be associated with a
//  VariableDeclaration, and currently we don't record comments for it either.
//  Consider changing the class hierarchy so that [VariableDeclaration] doesn't
//  extend [Declaration].
//
// TODO(brianwilkerson): This class represents both declarations that can be
//  augmented and declarations that can't be augmented. This results in getters
//  that are only sometimes applicable. Consider changing the class hierarchy so
//  that these two kinds of variables can be distinguished.
abstract final class VariableDeclaration
    implements Declaration, _FragmentDeclaration {
  /// The element declared by this declaration.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if this node
  /// represents the declaration of a top-level variable or a field.
  @override
  VariableElement? get declaredElement;

  /// The element declared by this declaration.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if this node
  /// represents the declaration of a top-level variable or a field.
  @experimental
  LocalVariableElement2? get declaredElement2;

  /// The fragment declared by this declaration.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if this node
  /// represents the declaration of a local variable.
  @experimental
  @override
  VariableFragment? get declaredFragment;

  /// The equal sign separating the variable name from the initial value, or
  /// `null` if the initial value isn't specified.
  Token? get equals;

  /// The expression used to compute the initial value for the variable, or
  /// `null` if the initial value isn't specified.
  Expression? get initializer;

  /// Whether this variable was declared with the 'const' modifier.
  bool get isConst;

  /// Whether this variable was declared with the 'final' modifier.
  ///
  /// Variables that are declared with the 'const' modifier return `false` even
  /// though they are implicitly final.
  bool get isFinal;

  /// Whether this variable was declared with the 'late' modifier.
  bool get isLate;

  /// The name of the variable being declared.
  Token get name;
}

final class VariableDeclarationImpl extends DeclarationImpl
    implements VariableDeclaration {
  @override
  final Token name;

  @override
  VariableElementImpl? declaredElement;

  @override
  final Token? equals;

  ExpressionImpl? _initializer;

  /// When this node is read as a part of summaries, we usually don't want
  /// to read the [initializer], but we need to know if there is one in
  /// the code. So, this flag might be set to `true` even though
  /// [initializer] is `null`.
  bool hasInitializer = false;

  /// Initializes a newly created variable declaration.
  ///
  /// The [equals] and [initializer] can be `null` if there's no initializer.
  VariableDeclarationImpl({
    required this.name,
    required this.equals,
    required ExpressionImpl? initializer,
  })  : _initializer = initializer,
        super(comment: null, metadata: null) {
    _becomeParentOf(_initializer);
  }

  @experimental
  @override
  LocalVariableElement2? get declaredElement2 {
    return declaredElement.asElement2.ifTypeOrNull<LocalVariableElement2>();
  }

  @experimental
  @override
  VariableFragment? get declaredFragment {
    if (declaredElement case VariableFragment fragment) {
      return fragment;
    }
    return null;
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
    if (initializer case var initializer?) {
      return initializer.endToken;
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
    var parent = this.parent;
    return parent is VariableDeclarationList && parent.isConst;
  }

  @override
  bool get isFinal {
    var parent = this.parent;
    return parent is VariableDeclarationList && parent.isFinal;
  }

  @override
  bool get isLate {
    var parent = this.parent;
    return parent is VariableDeclarationList && parent.isLate;
  }

  DartType get type {
    if (declaredElement2 case var declaredElement?) {
      return declaredElement.type;
    }
    // SAFETY: The variable declaration is either a local variable,
    // of a fragment of: top-level, field, formal parameter.
    return declaredFragment!.element.type;
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
///        finalConstVarOrType [VariableDeclaration]
///        (',' [VariableDeclaration])*
///
///    finalConstVarOrType ::=
///      'final' 'late'? [TypeAnnotation]?
///      | 'const' [TypeAnnotation]?
///      | 'var'
///      | 'late'? [TypeAnnotation]
abstract final class VariableDeclarationList implements AnnotatedNode {
  /// Whether the variables in this list were declared with the 'const'
  /// modifier.
  bool get isConst;

  /// Whether the variables in this list were declared with the 'final'
  /// modifier.
  ///
  /// Variables that are declared with the 'const' modifier return `false` even
  /// though they are implicitly final. (In other words, this is a syntactic
  /// check rather than a semantic check.)
  bool get isFinal;

  /// Whether the variables in this list were declared with the 'late' modifier.
  bool get isLate;

  /// The token representing the `final`, `const` or `var` keyword, or `null` if
  /// no keyword was included.
  Token? get keyword;

  /// The token representing the `late` keyword, or `null` if the late modifier
  /// isn't included.
  Token? get lateKeyword;

  /// The type of the variables being declared, or `null` if no type was
  /// provided.
  TypeAnnotation? get type;

  /// A list containing the individual variables being declared.
  NodeList<VariableDeclaration> get variables;
}

final class VariableDeclarationListImpl extends AnnotatedNodeImpl
    implements VariableDeclarationList {
  @override
  final Token? keyword;

  @override
  final Token? lateKeyword;

  TypeAnnotationImpl? _type;

  final NodeListImpl<VariableDeclarationImpl> _variables = NodeListImpl._();

  /// Initializes a newly created variable declaration list.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// variable list doesn't have the corresponding attribute.
  ///
  /// The [keyword] can be `null` if a type was specified.
  ///
  /// The [type] must be `null` if the keyword is `var`.
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
  /// The semicolon terminating the statement.
  Token get semicolon;

  /// The variables being declared.
  VariableDeclarationList get variables;
}

final class VariableDeclarationStatementImpl extends StatementImpl
    implements VariableDeclarationStatement {
  VariableDeclarationListImpl _variableList;

  @override
  final Token semicolon;

  /// Initializes a newly created variable declaration statement.
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
  /// The condition that is evaluated when the [pattern] matches, that must
  /// evaluate to `true` in order for the [expression] to be executed.
  Expression get expression;

  /// The `when` keyword.
  Token get whenKeyword;
}

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
  /// The body of the loop.
  Statement get body;

  /// The expression used to determine whether to execute the body of the loop.
  Expression get condition;

  /// The left parenthesis.
  Token get leftParenthesis;

  /// The right parenthesis.
  Token get rightParenthesis;

  /// The token representing the `while` keyword.
  Token get whileKeyword;
}

final class WhileStatementImpl extends StatementImpl implements WhileStatement {
  @override
  final Token whileKeyword;

  @override
  final Token leftParenthesis;

  ExpressionImpl _condition;

  @override
  final Token rightParenthesis;

  StatementImpl _body;

  /// Initializes a newly created while statement.
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
  /// The `var` or `final` keyword.
  Token? get keyword;

  /// The `_` token.
  Token get name;

  /// The type that the pattern is required to match, or `null` if any type is
  /// matched.
  TypeAnnotation? get type;
}

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
    var keyword = this.keyword;
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
        .analyzeDeclaredVariablePatternSchema(
            type?.typeOrThrow.wrapSharedTypeView())
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult<DartType> resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    var declaredType = type?.typeOrThrow;
    var analysisResult = resolverVisitor.analyzeWildcardPattern(
      context: context,
      node: this,
      declaredType: declaredType?.wrapSharedTypeView(),
    );

    if (declaredType != null) {
      resolverVisitor.checkPatternNeverMatchesValueType(
        context: context,
        pattern: this,
        requiredType: declaredType,
        matchedValueType: analysisResult.matchedValueType.unwrapTypeView(),
      );
    }

    return analysisResult;
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
  /// The names of the mixins that were specified.
  NodeList<NamedType> get mixinTypes;

  /// The token representing the `with` keyword.
  Token get withKeyword;
}

final class WithClauseImpl extends AstNodeImpl implements WithClause {
  @override
  final Token withKeyword;

  final NodeListImpl<NamedTypeImpl> _mixinTypes = NodeListImpl._();

  /// Initializes a newly created with clause.
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
  /// The expression whose value is yielded.
  Expression get expression;

  /// The semicolon following the expression.
  Token get semicolon;

  /// The star optionally following the `yield` keyword.
  Token? get star;

  /// The `yield` keyword.
  Token get yieldKeyword;
}

final class YieldStatementImpl extends StatementImpl implements YieldStatement {
  @override
  final Token yieldKeyword;

  @override
  final Token? star;

  ExpressionImpl _expression;

  @override
  final Token semicolon;

  /// Initializes a newly created yield expression.
  ///
  /// The [star] can be `null` if no star was provided.
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

/// Mixin implementing shared functionality for AST nodes that can have optional
/// annotations and an optional documentation comment.
base mixin _AnnotatedNodeMixin on AstNodeImpl implements AnnotatedNode {
  CommentImpl? _comment;

  final NodeListImpl<AnnotationImpl> _metadata = NodeListImpl._();

  @override
  CommentImpl? get documentationComment => _comment;

  set documentationComment(CommentImpl? comment) {
    _comment = _becomeParentOf(comment);
  }

  /// The first token following the comment and metadata.
  @override
  Token get firstTokenAfterCommentAndMetadata;

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

  /// Returns `true` if there are no annotations before the comment.
  ///
  /// Note that a result of `true` doesn't imply that there's a comment, nor
  /// that there are annotations associated with this node.
  bool _commentIsBeforeAnnotations() {
    if (_comment == null || _metadata.isEmpty) {
      return true;
    }
    Annotation firstAnnotation = _metadata[0];
    return _comment!.offset < firstAnnotation.offset;
  }

  /// Initializes the comment and metadata pointed to by this node.
  ///
  /// Intended to be called from the constructor.
  void _initializeCommentAndAnnotations(
      CommentImpl? comment, List<AnnotationImpl>? metadata) {
    _comment = _becomeParentOf(comment);
    _metadata._initialize(this, metadata);
  }

  /// Visits the AST nodes associated with [documentationComment] and
  /// [metadata] (if any).
  ///
  /// Intended to be called from the [AstNode.visitChildren] method.
  void _visitCommentAndAnnotations(AstVisitor<dynamic> visitor) {
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
}

/// A declaration of a fragment of an element.
abstract final class _FragmentDeclaration implements Declaration {
  /// The fragment declared by this declaration.
  ///
  /// Returns `null` if the AST structure hasn't been resolved.
  @experimental
  Fragment? get declaredFragment;
}

/// An indication of the resolved kind of a [SetOrMapLiteral].
enum _SetOrMapKind {
  /// Indicates that the literal represents a map.
  map,

  /// Indicates that the literal represents a set.
  set,

  /// Indicates that either
  /// - the literal is syntactically ambiguous and resolution hasn't yet been
  ///   performed, or
  /// - the literal is invalid because resolution isn't able to resolve the
  ///   ambiguity.
  unresolved
}
