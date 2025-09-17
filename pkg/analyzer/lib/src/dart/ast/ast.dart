// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file is partially generated, using [GenerateNodeImpl].
/// After modifying any these annotations, run
/// 'dart run pkg/analyzer/tool/generators/ast_generator.dart' to update.
library;

import 'dart:collection';
import 'dart:math' as math;

import 'package:_fe_analyzer_shared/src/base/analyzer_public_api.dart';
import 'package:_fe_analyzer_shared/src/scanner/string_canonicalizer.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart';
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/doc_comment.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/ast/to_source_visitor.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/constant/compute.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/constant/utilities.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/resolver/body_inference_context.dart';
import 'package:analyzer/src/dart/resolver/typed_literal_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/fasta/token_utils.dart' as util show findPrevious;
import 'package:analyzer/src/generated/inference_log.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/lint/constants.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

part 'ast.g.dart';

/// Marker for declarations that are code generated.
const generated = _Generated();

/// The type alias that allows using nullable type as type literals.
typedef _TypeLiteral<X> = X;

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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class AdjacentStrings implements StringLiteral {
  /// The strings that are implicitly concatenated.
  NodeList<StringLiteral> get strings;
}

@GenerateNodeImpl(childEntitiesOrder: [GenerateNodeProperty('strings')])
final class AdjacentStringsImpl extends StringLiteralImpl
    implements AdjacentStrings {
  @generated
  @override
  final NodeListImpl<StringLiteralImpl> strings = NodeListImpl._();

  @generated
  AdjacentStringsImpl({required List<StringLiteralImpl> strings}) {
    this.strings._initialize(this, strings);
  }

  @generated
  @override
  Token get beginToken {
    if (strings.beginToken case var result?) {
      return result;
    }
    throw StateError('Expected at least one non-null');
  }

  @generated
  @override
  Token get endToken {
    if (strings.endToken case var result?) {
      return result;
    }
    throw StateError('Expected at least one non-null');
  }

  @generated
  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addNodeList('strings', strings);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAdjacentStrings(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitAdjacentStrings(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    strings.accept(visitor);
  }

  @override
  void _appendStringValue(StringBuffer buffer) {
    int length = strings.length;
    for (int i = 0; i < length; i++) {
      strings[i]._appendStringValue(buffer);
    }
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (strings._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// An AST node that can be annotated with either a documentation comment, a
/// list of annotations (metadata), or both.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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
    if (_documentationComment == null) {
      if (_metadata.isEmpty) {
        return firstTokenAfterCommentAndMetadata;
      }
      return _metadata.beginToken!;
    } else if (_metadata.isEmpty) {
      return _documentationComment!.beginToken;
    }
    Token commentToken = _documentationComment!.beginToken;
    Token metadataToken = _metadata.beginToken!;
    if (commentToken.offset < metadataToken.offset) {
      return commentToken;
    }
    return metadataToken;
  }

  @override
  void visitChildren(AstVisitor visitor) {
    _visitCommentAndAnnotations(visitor);
  }

  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (_documentationComment?._containsOffset(rangeOffset, rangeEnd) ??
        false) {
      return _documentationComment;
    }
    return _metadata._elementContainingRange(rangeOffset, rangeEnd);
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class Annotation implements AstNode {
  /// The arguments to the constructor being invoked, or `null` if this
  /// annotation isn't the invocation of a constructor.
  ArgumentList? get arguments;

  /// The at sign (`@`) that introduces the annotation.
  Token get atSign;

  /// The name of the constructor being invoked, or `null` if this annotation
  /// isn't the invocation of a named constructor.
  SimpleIdentifier? get constructorName;

  /// The element associated with this annotation.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if this
  /// annotation couldn't be resolved.
  Element? get element;

  /// The element associated with this annotation.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if this
  /// annotation couldn't be resolved.
  @Deprecated('Use element instead')
  Element? get element2;

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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('atSign'),
    GenerateNodeProperty('name'),
    GenerateNodeProperty('typeArguments'),
    GenerateNodeProperty('period'),
    GenerateNodeProperty('constructorName'),
    GenerateNodeProperty('arguments'),
  ],
)
final class AnnotationImpl extends AstNodeImpl implements Annotation {
  @generated
  @override
  final Token atSign;

  @generated
  IdentifierImpl _name;

  @generated
  TypeArgumentListImpl? _typeArguments;

  @generated
  @override
  final Token? period;

  @generated
  SimpleIdentifierImpl? _constructorName;

  @generated
  ArgumentListImpl? _arguments;

  Element? _element;

  @override
  ElementAnnotationImpl? elementAnnotation;

  @generated
  AnnotationImpl({
    required this.atSign,
    required IdentifierImpl name,
    required TypeArgumentListImpl? typeArguments,
    required this.period,
    required SimpleIdentifierImpl? constructorName,
    required ArgumentListImpl? arguments,
  }) : _name = name,
       _typeArguments = typeArguments,
       _constructorName = constructorName,
       _arguments = arguments {
    _becomeParentOf(name);
    _becomeParentOf(typeArguments);
    _becomeParentOf(constructorName);
    _becomeParentOf(arguments);
  }

  @generated
  @override
  ArgumentListImpl? get arguments => _arguments;

  @generated
  set arguments(ArgumentListImpl? arguments) {
    _arguments = _becomeParentOf(arguments);
  }

  @generated
  @override
  Token get beginToken {
    return atSign;
  }

  @generated
  @override
  SimpleIdentifierImpl? get constructorName => _constructorName;

  @generated
  set constructorName(SimpleIdentifierImpl? constructorName) {
    _constructorName = _becomeParentOf(constructorName);
  }

  @override
  Element? get element {
    if (_element case var element?) {
      return element;
    } else if (constructorName == null) {
      return name.element;
    }
    return null;
  }

  set element(Element? value) {
    _element = value;
  }

  @Deprecated('Use element instead')
  @override
  Element? get element2 {
    return element;
  }

  @generated
  @override
  Token get endToken {
    if (arguments case var arguments?) {
      return arguments.endToken;
    }
    if (constructorName case var constructorName?) {
      return constructorName.endToken;
    }
    if (period case var period?) {
      return period;
    }
    if (typeArguments case var typeArguments?) {
      return typeArguments.endToken;
    }
    return name.endToken;
  }

  @generated
  @override
  IdentifierImpl get name => _name;

  @generated
  set name(IdentifierImpl name) {
    _name = _becomeParentOf(name);
  }

  @override
  AstNode get parent => super.parent!;

  @generated
  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  @generated
  set typeArguments(TypeArgumentListImpl? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('atSign', atSign)
    ..addNode('name', name)
    ..addNode('typeArguments', typeArguments)
    ..addToken('period', period)
    ..addNode('constructorName', constructorName)
    ..addNode('arguments', arguments);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAnnotation(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    name.accept(visitor);
    typeArguments?.accept(visitor);
    constructorName?.accept(visitor);
    arguments?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (name._containsOffset(rangeOffset, rangeEnd)) {
      return name;
    }
    if (typeArguments case var typeArguments?) {
      if (typeArguments._containsOffset(rangeOffset, rangeEnd)) {
        return typeArguments;
      }
    }
    if (constructorName case var constructorName?) {
      if (constructorName._containsOffset(rangeOffset, rangeEnd)) {
        return constructorName;
      }
    }
    if (arguments case var arguments?) {
      if (arguments._containsOffset(rangeOffset, rangeEnd)) {
        return arguments;
      }
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('leftParenthesis'),
    GenerateNodeProperty('arguments'),
    GenerateNodeProperty('rightParenthesis'),
  ],
)
final class ArgumentListImpl extends AstNodeImpl implements ArgumentList {
  @generated
  @override
  final Token leftParenthesis;

  @generated
  @override
  final NodeListImpl<ExpressionImpl> arguments = NodeListImpl._();

  @generated
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
  List<InternalFormalParameterElement?>? _correspondingStaticParameters;

  @generated
  ArgumentListImpl({
    required this.leftParenthesis,
    required List<ExpressionImpl> arguments,
    required this.rightParenthesis,
  }) {
    this.arguments._initialize(this, arguments);
  }

  @generated
  @override
  Token get beginToken {
    return leftParenthesis;
  }

  List<InternalFormalParameterElement?>? get correspondingStaticParameters =>
      _correspondingStaticParameters;

  set correspondingStaticParameters(
    List<InternalFormalParameterElement?>? parameters,
  ) {
    if (parameters != null && parameters.length != arguments.length) {
      throw ArgumentError(
        "Expected ${arguments.length} parameters, not ${parameters.length}",
      );
    }
    _correspondingStaticParameters = parameters;
  }

  @generated
  @override
  Token get endToken {
    return rightParenthesis;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNodeList('arguments', arguments)
    ..addToken('rightParenthesis', rightParenthesis);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitArgumentList(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    arguments.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (arguments._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }

  /// Returns the parameter element representing the parameter to which the
  /// value of the given expression is bound, or `null` if any of the following
  /// are not true
  /// - the given [expression] is a child of this list
  /// - the AST structure is resolved
  /// - the function being invoked is known based on static type information
  /// - the expression corresponds to one of the parameters of the function
  ///   being invoked
  InternalFormalParameterElement? _getStaticParameterElementFor(
    Expression expression,
  ) {
    if (_correspondingStaticParameters == null ||
        _correspondingStaticParameters!.length != arguments.length) {
      // Either the AST structure hasn't been resolved, the invocation of which
      // this list is a part couldn't be resolved, or the argument list was
      // modified after the parameters were set.
      return null;
    }
    int index = arguments.indexOf(expression);
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class AsExpression implements Expression {
  /// The `as` operator.
  Token get asOperator;

  /// The expression used to compute the value being cast.
  Expression get expression;

  /// The type being cast to.
  TypeAnnotation get type;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('expression'),
    GenerateNodeProperty('asOperator'),
    GenerateNodeProperty('type'),
  ],
)
final class AsExpressionImpl extends ExpressionImpl implements AsExpression {
  @generated
  ExpressionImpl _expression;

  @generated
  @override
  final Token asOperator;

  @generated
  TypeAnnotationImpl _type;

  @generated
  AsExpressionImpl({
    required ExpressionImpl expression,
    required this.asOperator,
    required TypeAnnotationImpl type,
  }) : _expression = expression,
       _type = type {
    _becomeParentOf(expression);
    _becomeParentOf(type);
  }

  @generated
  @override
  Token get beginToken {
    return expression.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return type.endToken;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.relational;

  @generated
  @override
  TypeAnnotationImpl get type => _type;

  @generated
  set type(TypeAnnotationImpl type) {
    _type = _becomeParentOf(type);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('expression', expression)
    ..addToken('asOperator', asOperator)
    ..addNode('type', type);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAsExpression(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitAsExpression(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
    type.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    if (type._containsOffset(rangeOffset, rangeEnd)) {
      return type;
    }
    return null;
  }
}

/// An assert in the initializer list of a constructor.
///
///    assertInitializer ::=
///        'assert' '(' [Expression] (',' [Expression])? ')'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class AssertInitializer
    implements Assertion, ConstructorInitializer {}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('assertKeyword'),
    GenerateNodeProperty('leftParenthesis'),
    GenerateNodeProperty('condition'),
    GenerateNodeProperty('comma'),
    GenerateNodeProperty('message'),
    GenerateNodeProperty('rightParenthesis'),
  ],
)
final class AssertInitializerImpl extends ConstructorInitializerImpl
    implements AssertInitializer {
  @generated
  @override
  final Token assertKeyword;

  @generated
  @override
  final Token leftParenthesis;

  @generated
  ExpressionImpl _condition;

  @generated
  @override
  final Token? comma;

  @generated
  ExpressionImpl? _message;

  @generated
  @override
  final Token rightParenthesis;

  @generated
  AssertInitializerImpl({
    required this.assertKeyword,
    required this.leftParenthesis,
    required ExpressionImpl condition,
    required this.comma,
    required ExpressionImpl? message,
    required this.rightParenthesis,
  }) : _condition = condition,
       _message = message {
    _becomeParentOf(condition);
    _becomeParentOf(message);
  }

  @generated
  @override
  Token get beginToken {
    return assertKeyword;
  }

  @generated
  @override
  ExpressionImpl get condition => _condition;

  @generated
  set condition(ExpressionImpl condition) {
    _condition = _becomeParentOf(condition);
  }

  @generated
  @override
  Token get endToken {
    return rightParenthesis;
  }

  @generated
  @override
  ExpressionImpl? get message => _message;

  @generated
  set message(ExpressionImpl? message) {
    _message = _becomeParentOf(message);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('assertKeyword', assertKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('condition', condition)
    ..addToken('comma', comma)
    ..addNode('message', message)
    ..addToken('rightParenthesis', rightParenthesis);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAssertInitializer(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    condition.accept(visitor);
    message?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (condition._containsOffset(rangeOffset, rangeEnd)) {
      return condition;
    }
    if (message case var message?) {
      if (message._containsOffset(rangeOffset, rangeEnd)) {
        return message;
      }
    }
    return null;
  }
}

/// An assertion, either in a block or in the initializer list of a constructor.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class AssertStatement implements Assertion, Statement {
  /// The semicolon terminating the statement.
  Token get semicolon;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('assertKeyword'),
    GenerateNodeProperty('leftParenthesis'),
    GenerateNodeProperty('condition'),
    GenerateNodeProperty('comma'),
    GenerateNodeProperty('message'),
    GenerateNodeProperty('rightParenthesis'),
    GenerateNodeProperty('semicolon'),
  ],
)
final class AssertStatementImpl extends StatementImpl
    implements AssertStatement {
  @generated
  @override
  final Token assertKeyword;

  @generated
  @override
  final Token leftParenthesis;

  @generated
  ExpressionImpl _condition;

  @generated
  @override
  final Token? comma;

  @generated
  ExpressionImpl? _message;

  @generated
  @override
  final Token rightParenthesis;

  @generated
  @override
  final Token semicolon;

  @generated
  AssertStatementImpl({
    required this.assertKeyword,
    required this.leftParenthesis,
    required ExpressionImpl condition,
    required this.comma,
    required ExpressionImpl? message,
    required this.rightParenthesis,
    required this.semicolon,
  }) : _condition = condition,
       _message = message {
    _becomeParentOf(condition);
    _becomeParentOf(message);
  }

  @generated
  @override
  Token get beginToken {
    return assertKeyword;
  }

  @generated
  @override
  ExpressionImpl get condition => _condition;

  @generated
  set condition(ExpressionImpl condition) {
    _condition = _becomeParentOf(condition);
  }

  @generated
  @override
  Token get endToken {
    return semicolon;
  }

  @generated
  @override
  ExpressionImpl? get message => _message;

  @generated
  set message(ExpressionImpl? message) {
    _message = _becomeParentOf(message);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('assertKeyword', assertKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('condition', condition)
    ..addToken('comma', comma)
    ..addNode('message', message)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAssertStatement(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    condition.accept(visitor);
    message?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (condition._containsOffset(rangeOffset, rangeEnd)) {
      return condition;
    }
    if (message case var message?) {
      if (message._containsOffset(rangeOffset, rangeEnd)) {
        return message;
      }
    }
    return null;
  }
}

/// A variable pattern in [PatternAssignment].
///
///    variablePattern ::= identifier
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class AssignedVariablePattern implements VariablePattern {
  /// The element referenced by this pattern.
  ///
  /// Returns `null` if either [name] doesn't resolve to an element or the AST
  /// structure hasn't been resolved.
  ///
  /// In valid code this is either a [LocalVariableElement] or a
  /// [FormalParameterElement].
  Element? get element;

  @Deprecated('Use element instead')
  Element? get element2;
}

@GenerateNodeImpl(
  childEntitiesOrder: [GenerateNodeProperty('name', isSuper: true)],
)
final class AssignedVariablePatternImpl extends VariablePatternImpl
    implements AssignedVariablePattern {
  @override
  Element? element;

  @generated
  AssignedVariablePatternImpl({required super.name});

  @generated
  @override
  Token get beginToken {
    return name;
  }

  @Deprecated('Use element instead')
  @override
  Element? get element2 => element;

  @generated
  @override
  Token get endToken {
    return name;
  }

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()..addToken('name', name);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitAssignedVariablePattern(this);

  @override
  TypeImpl computePatternSchema(ResolverVisitor resolverVisitor) {
    var element = this.element;
    if (element is PromotableElementImpl) {
      return resolverVisitor
          .analyzeAssignedVariablePatternSchema(element)
          .unwrapTypeSchemaView();
    }
    return resolverVisitor.operations.unknownType.unwrapTypeSchemaView();
  }

  @override
  PatternResult resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    return resolverVisitor.resolveAssignedVariablePattern(
      node: this,
      context: context,
    );
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {}

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    return null;
  }
}

/// An assignment expression.
///
///    assignmentExpression ::=
///        [Expression] operator [Expression]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class AssignmentExpression
    implements
        // ignore: deprecated_member_use_from_same_package
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('leftHandSide'),
    GenerateNodeProperty('operator'),
    GenerateNodeProperty('rightHandSide'),
  ],
)
final class AssignmentExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl, CompoundAssignmentExpressionImpl
    implements AssignmentExpression {
  @generated
  ExpressionImpl _leftHandSide;

  @generated
  @override
  final Token operator;

  @generated
  ExpressionImpl _rightHandSide;

  @override
  InternalMethodElement? element;

  @generated
  AssignmentExpressionImpl({
    required ExpressionImpl leftHandSide,
    required this.operator,
    required ExpressionImpl rightHandSide,
  }) : _leftHandSide = leftHandSide,
       _rightHandSide = rightHandSide {
    _becomeParentOf(leftHandSide);
    _becomeParentOf(rightHandSide);
  }

  @generated
  @override
  Token get beginToken {
    return leftHandSide.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return rightHandSide.endToken;
  }

  @generated
  @override
  ExpressionImpl get leftHandSide => _leftHandSide;

  @generated
  set leftHandSide(ExpressionImpl leftHandSide) {
    _leftHandSide = _becomeParentOf(leftHandSide);
  }

  @override
  Precedence get precedence => Precedence.assignment;

  @generated
  @override
  ExpressionImpl get rightHandSide => _rightHandSide;

  @generated
  set rightHandSide(ExpressionImpl rightHandSide) {
    _rightHandSide = _becomeParentOf(rightHandSide);
  }

  @generated
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
  InternalFormalParameterElement? get _staticParameterElementForRightHandSide {
    Element? executableElement;
    if (operator.type != TokenType.EQ) {
      executableElement = element;
    } else {
      executableElement = writeElement;
    }

    if (executableElement is ExecutableElement) {
      var formalParameters = executableElement.formalParameters;
      if (formalParameters.isEmpty) {
        return null;
      }
      if (operator.type == TokenType.EQ && leftHandSide is IndexExpression) {
        return formalParameters.length == 2
            ? (formalParameters[1] as InternalFormalParameterElement)
            : null;
      }
      return formalParameters[0] as InternalFormalParameterElement;
    }

    return null;
  }

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitAssignmentExpression(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitAssignmentExpression(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    leftHandSide.accept(visitor);
    rightHandSide.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (leftHandSide._containsOffset(rangeOffset, rangeEnd)) {
      return leftHandSide;
    }
    if (rightHandSide._containsOffset(rangeOffset, rangeEnd)) {
      return rightHandSide;
    }
    return null;
  }

  @override
  bool _extendsNullShorting(Expression descendant) =>
      identical(descendant, _leftHandSide);
}

/// A node in the AST structure for a Dart program.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class AstNode implements SyntacticEntity {
  /// A comparator that can be used to sort AST nodes in lexical order.
  ///
  /// In other words, `compare` returns a negative value if the offset of the
  /// first node is less than the offset of the second node, zero (0) if the
  /// nodes have the same offset, and a positive value if the offset of the
  /// first node is greater than the offset of the second node.
  static Comparator<AstNode> LEXICAL_ORDER = (AstNode first, AstNode second) =>
      first.offset - second.offset;

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

  @override
  Iterable<SyntacticEntity> get childEntities =>
      _childEntities.syntacticEntities;

  @override
  int get end => endToken.end;

  @override
  bool get isSynthetic => false;

  @override
  int get length => end - offset;

  /// The properties (tokens and nodes) of this node, with names, in the order
  /// in which these entities should normally appear, not necessarily in the
  /// order they really are (because of recovery).
  Iterable<ChildEntity> get namedChildEntities => _childEntities.entities;

  @override
  int get offset => beginToken.offset;

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

  /// Returns the child of this node that completely contains the range.
  ///
  /// Returns `null` if none of the children contain the range (which means that
  /// this node is the covering node).
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd);

  /// Returns whether this node contains the range from [rangeOffset] to
  /// [rangeEnd].
  ///
  /// When the range is an insertion point between two adjacent tokens, one of
  /// which belongs to this node and the other to a different node, then this
  /// node is considered to contain the insertion point unless the token that
  /// doesn't belonging to this node is an identifier.
  bool _containsOffset(int rangeOffset, int rangeEnd) {
    // Cache some values to avoid computing them multiple times.
    var beginToken = this.beginToken;
    var offset = beginToken.offset;
    var endToken = this.endToken;
    var end = endToken.end;
    // Handle the special insertion point cases.
    if (rangeOffset == rangeEnd) {
      if (rangeOffset == offset) {
        var previous = beginToken.previous;
        if (previous != null &&
            rangeOffset == previous.end &&
            previous.isIdentifier) {
          return false;
        }
      }
      if (rangeOffset == end) {
        var next = endToken.next;
        if (next != null && rangeOffset == next.offset && next.isIdentifier) {
          return false;
        }
      }
    }
    // Handle the general case.
    return offset <= rangeOffset && end >= rangeEnd;
  }

  static void linkNodeTokens(AstNodeImpl root) {
    Token? lastToken;
    var stack = <Object>[root];
    while (stack.isNotEmpty) {
      var entity = stack.removeLast();
      switch (entity) {
        case Token token:
          lastToken?.next = token;
          token.previous = lastToken;
          lastToken = token;
        case NodeListImpl nodeList:
          // Push in reverse order, so process in source order.
          stack.addAll(nodeList.reversed);
        case AstNodeImpl node:
          // Push in reverse order, so process in source order.
          var entities = node._childEntities.entities;
          stack.addAll(entities.reversed.map((e) => e.value));
        default:
          throw UnimplementedError('${entity.runtimeType}');
      }
    }
  }
}

/// Mixin for any [AstNodeImpl] that can potentially introduce a new scope.
base mixin AstNodeWithNameScopeMixin on AstNodeImpl {
  /// The [Scope] that was used while resolving `this`, or `null` if resolution
  /// has not been performed yet.
  Scope? nameScope;
}

/// The result of attempting to evaluate an expression as a constant.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
final class AttemptedConstantEvaluationResult {
  /// The value of the expression, or `null` if has [diagnostics].
  ///
  /// If evaluating a constant expression yields diagnostics, then the value of
  /// the constant expression cannot be calculated.
  final DartObject? value;

  /// The diagnostics reported during the evaluation.
  final List<Diagnostic> diagnostics;

  AttemptedConstantEvaluationResult._(this.value, this.diagnostics);
}

/// An await expression.
///
///    awaitExpression ::=
///        'await' [Expression]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class AwaitExpression implements Expression {
  /// The `await` keyword.
  Token get awaitKeyword;

  /// The expression whose value is being waited on.
  Expression get expression;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('awaitKeyword'),
    GenerateNodeProperty('expression'),
  ],
)
final class AwaitExpressionImpl extends ExpressionImpl
    implements AwaitExpression {
  @generated
  @override
  final Token awaitKeyword;

  @generated
  ExpressionImpl _expression;

  @generated
  AwaitExpressionImpl({
    required this.awaitKeyword,
    required ExpressionImpl expression,
  }) : _expression = expression {
    _becomeParentOf(expression);
  }

  @generated
  @override
  Token get beginToken {
    return awaitKeyword;
  }

  @generated
  @override
  Token get endToken {
    return expression.endToken;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.prefix;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('awaitKeyword', awaitKeyword)
    ..addNode('expression', expression);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitAwaitExpression(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitAwaitExpression(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    return null;
  }
}

/// A binary (infix) expression.
///
///    binaryExpression ::=
///        [Expression] [Token] [Expression]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('leftOperand'),
    GenerateNodeProperty('operator'),
    GenerateNodeProperty('rightOperand'),
  ],
)
final class BinaryExpressionImpl extends ExpressionImpl
    implements BinaryExpression {
  @generated
  ExpressionImpl _leftOperand;

  @generated
  @override
  final Token operator;

  @generated
  ExpressionImpl _rightOperand;

  @override
  MethodElement? element;

  @override
  FunctionTypeImpl? staticInvokeType;

  @generated
  BinaryExpressionImpl({
    required ExpressionImpl leftOperand,
    required this.operator,
    required ExpressionImpl rightOperand,
  }) : _leftOperand = leftOperand,
       _rightOperand = rightOperand {
    _becomeParentOf(leftOperand);
    _becomeParentOf(rightOperand);
  }

  @generated
  @override
  Token get beginToken {
    return leftOperand.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return rightOperand.endToken;
  }

  @generated
  @override
  ExpressionImpl get leftOperand => _leftOperand;

  @generated
  set leftOperand(ExpressionImpl leftOperand) {
    _leftOperand = _becomeParentOf(leftOperand);
  }

  @override
  Precedence get precedence => Precedence.forTokenType(operator.type);

  @generated
  @override
  ExpressionImpl get rightOperand => _rightOperand;

  @generated
  set rightOperand(ExpressionImpl rightOperand) {
    _rightOperand = _becomeParentOf(rightOperand);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('leftOperand', leftOperand)
    ..addToken('operator', operator)
    ..addNode('rightOperand', rightOperand);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitBinaryExpression(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitBinaryExpression(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    leftOperand.accept(visitor);
    rightOperand.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (leftOperand._containsOffset(rangeOffset, rangeEnd)) {
      return leftOperand;
    }
    if (rightOperand._containsOffset(rangeOffset, rangeEnd)) {
      return rightOperand;
    }
    return null;
  }
}

/// A sequence of statements.
///
///    block ::=
///        '{' statement* '}'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class BlockFunctionBody implements FunctionBody {
  /// The block representing the body of the function.
  Block get block;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('keyword'),
    GenerateNodeProperty('star'),
    GenerateNodeProperty('block'),
  ],
)
final class BlockFunctionBodyImpl extends FunctionBodyImpl
    implements BlockFunctionBody {
  @generated
  @override
  final Token? keyword;

  @generated
  @override
  final Token? star;

  @generated
  BlockImpl _block;

  @generated
  BlockFunctionBodyImpl({
    required this.keyword,
    required this.star,
    required BlockImpl block,
  }) : _block = block {
    _becomeParentOf(block);
  }

  @generated
  @override
  Token get beginToken {
    if (keyword case var keyword?) {
      return keyword;
    }
    if (star case var star?) {
      return star;
    }
    return block.beginToken;
  }

  @generated
  @override
  BlockImpl get block => _block;

  @generated
  set block(BlockImpl block) {
    _block = _becomeParentOf(block);
  }

  @generated
  @override
  Token get endToken {
    return block.endToken;
  }

  @override
  bool get isAsynchronous => keyword?.lexeme == Keyword.ASYNC.lexeme;

  @override
  bool get isGenerator => star != null;

  @override
  bool get isSynchronous => keyword?.lexeme != Keyword.ASYNC.lexeme;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('keyword', keyword)
    ..addToken('star', star)
    ..addNode('block', block);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitBlockFunctionBody(this);

  @override
  TypeImpl resolve(ResolverVisitor resolver, TypeImpl? imposedType) =>
      resolver.visitBlockFunctionBody(this, imposedType: imposedType);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    block.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (block._containsOffset(rangeOffset, rangeEnd)) {
      return block;
    }
    return null;
  }
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('leftBracket'),
    GenerateNodeProperty('statements'),
    GenerateNodeProperty('rightBracket'),
  ],
)
final class BlockImpl extends StatementImpl
    with AstNodeWithNameScopeMixin
    implements Block {
  @generated
  @override
  final Token leftBracket;

  @generated
  @override
  final NodeListImpl<StatementImpl> statements = NodeListImpl._();

  @generated
  @override
  final Token rightBracket;

  @generated
  BlockImpl({
    required this.leftBracket,
    required List<StatementImpl> statements,
    required this.rightBracket,
  }) {
    this.statements._initialize(this, statements);
  }

  @generated
  @override
  Token get beginToken {
    return leftBracket;
  }

  @generated
  @override
  Token get endToken {
    return rightBracket;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('statements', statements)
    ..addToken('rightBracket', rightBracket);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitBlock(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    statements.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (statements._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// A boolean literal expression.
///
///    booleanLiteral ::=
///        'false' | 'true'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class BooleanLiteral implements Literal {
  /// The token representing the literal.
  Token get literal;

  /// The value of the literal.
  bool get value;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('literal'),
    GenerateNodeProperty('value'),
  ],
)
final class BooleanLiteralImpl extends LiteralImpl implements BooleanLiteral {
  @generated
  @override
  final Token literal;

  @generated
  @override
  final bool value;

  @generated
  BooleanLiteralImpl({required this.literal, required this.value});

  @generated
  @override
  Token get beginToken {
    return literal;
  }

  @generated
  @override
  Token get endToken {
    return literal;
  }

  @override
  bool get isSynthetic => literal.isSynthetic;

  @generated
  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('literal', literal);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitBooleanLiteral(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitBooleanLiteral(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {}

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    return null;
  }
}

/// A break statement.
///
///    breakStatement ::=
///        'break' [SimpleIdentifier]? ';'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('breakKeyword'),
    GenerateNodeProperty('label'),
    GenerateNodeProperty('semicolon'),
  ],
)
final class BreakStatementImpl extends StatementImpl implements BreakStatement {
  @generated
  @override
  final Token breakKeyword;

  @generated
  SimpleIdentifierImpl? _label;

  @generated
  @override
  final Token semicolon;

  @override
  AstNode? target;

  @generated
  BreakStatementImpl({
    required this.breakKeyword,
    required SimpleIdentifierImpl? label,
    required this.semicolon,
  }) : _label = label {
    _becomeParentOf(label);
  }

  @generated
  @override
  Token get beginToken {
    return breakKeyword;
  }

  @generated
  @override
  Token get endToken {
    return semicolon;
  }

  @generated
  @override
  SimpleIdentifierImpl? get label => _label;

  @generated
  set label(SimpleIdentifierImpl? label) {
    _label = _becomeParentOf(label);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('breakKeyword', breakKeyword)
    ..addNode('label', label)
    ..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitBreakStatement(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    label?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (label case var label?) {
      if (label._containsOffset(rangeOffset, rangeEnd)) {
        return label;
      }
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class CascadeExpression
    implements
        Expression,
        // ignore: deprecated_member_use_from_same_package
        NullShortableExpression {
  /// The cascade sections sharing the common target.
  NodeList<Expression> get cascadeSections;

  /// Whether this cascade is null aware (as opposed to non-null).
  bool get isNullAware;

  /// The target of the cascade sections.
  Expression get target;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('target'),
    GenerateNodeProperty('cascadeSections'),
  ],
)
final class CascadeExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl
    implements CascadeExpression {
  @generated
  ExpressionImpl _target;

  @generated
  @override
  final NodeListImpl<ExpressionImpl> cascadeSections = NodeListImpl._();

  @generated
  CascadeExpressionImpl({
    required ExpressionImpl target,
    required List<ExpressionImpl> cascadeSections,
  }) : _target = target {
    _becomeParentOf(target);
    this.cascadeSections._initialize(this, cascadeSections);
  }

  @generated
  @override
  Token get beginToken {
    return target.beginToken;
  }

  @generated
  @override
  Token get endToken {
    if (cascadeSections.endToken case var result?) {
      return result;
    }
    return target.endToken;
  }

  @override
  bool get isNullAware {
    return target.endToken.next!.type == TokenType.QUESTION_PERIOD_PERIOD;
  }

  @override
  Precedence get precedence => Precedence.cascade;

  @generated
  @override
  ExpressionImpl get target => _target;

  @generated
  set target(ExpressionImpl target) {
    _target = _becomeParentOf(target);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('target', target)
    ..addNodeList('cascadeSections', cascadeSections);

  @override
  AstNode? get _nullShortingExtensionCandidate => null;

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitCascadeExpression(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitCascadeExpression(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    target.accept(visitor);
    cascadeSections.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (target._containsOffset(rangeOffset, rangeEnd)) {
      return target;
    }
    if (cascadeSections._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }

  @override
  bool _extendsNullShorting(Expression descendant) {
    // Null shorting that occurs in a cascade section does not extend to the
    // full cascade expression.
    return false;
  }
}

/// The `case` clause that can optionally appear in an `if` statement.
///
///    caseClause ::=
///        'case' [GuardedPattern]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class CaseClause implements AstNode {
  /// The token representing the `case` keyword.
  Token get caseKeyword;

  /// The pattern controlling whether the statements are executed.
  GuardedPattern get guardedPattern;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('caseKeyword'),
    GenerateNodeProperty('guardedPattern'),
  ],
)
final class CaseClauseImpl extends AstNodeImpl
    with AstNodeWithNameScopeMixin
    implements CaseClause {
  @generated
  @override
  final Token caseKeyword;

  @generated
  GuardedPatternImpl _guardedPattern;

  @generated
  CaseClauseImpl({
    required this.caseKeyword,
    required GuardedPatternImpl guardedPattern,
  }) : _guardedPattern = guardedPattern {
    _becomeParentOf(guardedPattern);
  }

  @generated
  @override
  Token get beginToken {
    return caseKeyword;
  }

  @generated
  @override
  Token get endToken {
    return guardedPattern.endToken;
  }

  @generated
  @override
  GuardedPatternImpl get guardedPattern => _guardedPattern;

  @generated
  set guardedPattern(GuardedPatternImpl guardedPattern) {
    _guardedPattern = _becomeParentOf(guardedPattern);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('caseKeyword', caseKeyword)
    ..addNode('guardedPattern', guardedPattern);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitCaseClause(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    guardedPattern.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (guardedPattern._containsOffset(rangeOffset, rangeEnd)) {
      return guardedPattern;
    }
    return null;
  }
}

sealed class CaseNodeImpl implements AstNode {
  GuardedPatternImpl get guardedPattern;
}

/// A cast pattern.
///
///    castPattern ::=
///        [DartPattern] 'as' [TypeAnnotation]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class CastPattern implements DartPattern {
  /// The `as` token.
  Token get asToken;

  /// The pattern used to match the value being cast.
  DartPattern get pattern;

  /// The type that the value being matched is cast to.
  TypeAnnotation get type;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('pattern'),
    GenerateNodeProperty('asToken'),
    GenerateNodeProperty('type'),
  ],
)
final class CastPatternImpl extends DartPatternImpl implements CastPattern {
  @generated
  DartPatternImpl _pattern;

  @generated
  @override
  final Token asToken;

  @generated
  TypeAnnotationImpl _type;

  @generated
  CastPatternImpl({
    required DartPatternImpl pattern,
    required this.asToken,
    required TypeAnnotationImpl type,
  }) : _pattern = pattern,
       _type = type {
    _becomeParentOf(pattern);
    _becomeParentOf(type);
  }

  @generated
  @override
  Token get beginToken {
    return pattern.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return type.endToken;
  }

  @generated
  @override
  DartPatternImpl get pattern => _pattern;

  @generated
  set pattern(DartPatternImpl pattern) {
    _pattern = _becomeParentOf(pattern);
  }

  @override
  PatternPrecedence get precedence => PatternPrecedence.postfix;

  @generated
  @override
  TypeAnnotationImpl get type => _type;

  @generated
  set type(TypeAnnotationImpl type) {
    _type = _becomeParentOf(type);
  }

  @override
  VariablePatternImpl? get variablePattern => pattern.variablePattern;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('pattern', pattern)
    ..addToken('asToken', asToken)
    ..addNode('type', type);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitCastPattern(this);

  @override
  TypeImpl computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor.analyzeCastPatternSchema().unwrapTypeSchemaView();
  }

  @override
  PatternResult resolvePattern(
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

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    pattern.accept(visitor);
    type.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (pattern._containsOffset(rangeOffset, rangeEnd)) {
      return pattern;
    }
    if (type._containsOffset(rangeOffset, rangeEnd)) {
      return type;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('onKeyword'),
    GenerateNodeProperty('exceptionType'),
    GenerateNodeProperty('catchKeyword'),
    GenerateNodeProperty('leftParenthesis'),
    GenerateNodeProperty('exceptionParameter'),
    GenerateNodeProperty('comma'),
    GenerateNodeProperty('stackTraceParameter'),
    GenerateNodeProperty('rightParenthesis'),
    GenerateNodeProperty('body'),
  ],
)
final class CatchClauseImpl extends AstNodeImpl implements CatchClause {
  @generated
  @override
  final Token? onKeyword;

  @generated
  TypeAnnotationImpl? _exceptionType;

  @generated
  @override
  final Token? catchKeyword;

  @generated
  @override
  final Token? leftParenthesis;

  @generated
  CatchClauseParameterImpl? _exceptionParameter;

  @generated
  @override
  final Token? comma;

  @generated
  CatchClauseParameterImpl? _stackTraceParameter;

  @generated
  @override
  final Token? rightParenthesis;

  @generated
  BlockImpl _body;

  @generated
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
  }) : _exceptionType = exceptionType,
       _exceptionParameter = exceptionParameter,
       _stackTraceParameter = stackTraceParameter,
       _body = body {
    _becomeParentOf(exceptionType);
    _becomeParentOf(exceptionParameter);
    _becomeParentOf(stackTraceParameter);
    _becomeParentOf(body);
  }

  @generated
  @override
  Token get beginToken {
    if (onKeyword case var onKeyword?) {
      return onKeyword;
    }
    if (exceptionType case var exceptionType?) {
      return exceptionType.beginToken;
    }
    if (catchKeyword case var catchKeyword?) {
      return catchKeyword;
    }
    if (leftParenthesis case var leftParenthesis?) {
      return leftParenthesis;
    }
    if (exceptionParameter case var exceptionParameter?) {
      return exceptionParameter.beginToken;
    }
    if (comma case var comma?) {
      return comma;
    }
    if (stackTraceParameter case var stackTraceParameter?) {
      return stackTraceParameter.beginToken;
    }
    if (rightParenthesis case var rightParenthesis?) {
      return rightParenthesis;
    }
    return body.beginToken;
  }

  @generated
  @override
  BlockImpl get body => _body;

  @generated
  set body(BlockImpl body) {
    _body = _becomeParentOf(body);
  }

  @generated
  @override
  Token get endToken {
    return body.endToken;
  }

  @generated
  @override
  CatchClauseParameterImpl? get exceptionParameter => _exceptionParameter;

  @generated
  set exceptionParameter(CatchClauseParameterImpl? exceptionParameter) {
    _exceptionParameter = _becomeParentOf(exceptionParameter);
  }

  @generated
  @override
  TypeAnnotationImpl? get exceptionType => _exceptionType;

  @generated
  set exceptionType(TypeAnnotationImpl? exceptionType) {
    _exceptionType = _becomeParentOf(exceptionType);
  }

  @generated
  @override
  CatchClauseParameterImpl? get stackTraceParameter => _stackTraceParameter;

  @generated
  set stackTraceParameter(CatchClauseParameterImpl? stackTraceParameter) {
    _stackTraceParameter = _becomeParentOf(stackTraceParameter);
  }

  @generated
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

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitCatchClause(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    exceptionType?.accept(visitor);
    exceptionParameter?.accept(visitor);
    stackTraceParameter?.accept(visitor);
    body.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (exceptionType case var exceptionType?) {
      if (exceptionType._containsOffset(rangeOffset, rangeEnd)) {
        return exceptionType;
      }
    }
    if (exceptionParameter case var exceptionParameter?) {
      if (exceptionParameter._containsOffset(rangeOffset, rangeEnd)) {
        return exceptionParameter;
      }
    }
    if (stackTraceParameter case var stackTraceParameter?) {
      if (stackTraceParameter._containsOffset(rangeOffset, rangeEnd)) {
        return stackTraceParameter;
      }
    }
    if (body._containsOffset(rangeOffset, rangeEnd)) {
      return body;
    }
    return null;
  }
}

/// An 'exception' or 'stackTrace' parameter in [CatchClause].
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class CatchClauseParameter extends AstNode {
  /// The declared element.
  ///
  /// Returns `null` if the AST hasn't been resolved.
  @Deprecated('Use declaredFragment instead')
  LocalVariableElement? get declaredElement;

  /// The declared element.
  ///
  /// Returns `null` if the AST hasn't been resolved.
  @Deprecated('Use declaredFragment instead')
  LocalVariableElement? get declaredElement2;

  /// The declared fragment.
  ///
  /// Returns `null` if the AST hasn't been resolved.
  LocalVariableFragment? get declaredFragment;

  /// The name of the parameter.
  Token get name;
}

@GenerateNodeImpl(childEntitiesOrder: [GenerateNodeProperty('name')])
final class CatchClauseParameterImpl extends AstNodeImpl
    implements CatchClauseParameter {
  @generated
  @override
  final Token name;

  @override
  LocalVariableFragmentImpl? declaredFragment;

  @generated
  CatchClauseParameterImpl({required this.name});

  @generated
  @override
  Token get beginToken {
    return name;
  }

  @Deprecated('Use declaredFragment instead')
  @override
  LocalVariableElementImpl? get declaredElement {
    return declaredFragment?.element;
  }

  @Deprecated('Use declaredFragment instead')
  @override
  LocalVariableElementImpl? get declaredElement2 {
    return declaredElement;
  }

  @generated
  @override
  Token get endToken {
    return name;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()..addToken('name', name);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitCatchClauseParameter(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {}

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    return null;
  }
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
      entities.add(ChildEntity(name, value));
    }
  }

  void addNodeList(String name, List<AstNode> value) {
    entities.add(ChildEntity(name, value));
  }

  void addToken(String name, Token? value) {
    if (value != null) {
      entities.add(ChildEntity(name, value));
    }
  }

  void addTokenList(String name, List<Token> value) {
    entities.add(ChildEntity(name, value));
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ClassDeclaration implements NamedCompilationUnitMember {
  /// The `abstract` keyword, or `null` if the keyword was absent.
  Token? get abstractKeyword;

  /// The `augment` keyword, or `null` if the keyword was absent.
  Token? get augmentKeyword;

  /// The `base` keyword, or `null` if the keyword was absent.
  Token? get baseKeyword;

  /// The token representing the `class` keyword.
  Token get classKeyword;

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
  @Deprecated('Support for macros was removed')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('augmentKeyword'),
    GenerateNodeProperty('abstractKeyword'),
    GenerateNodeProperty('macroKeyword'),
    GenerateNodeProperty('sealedKeyword'),
    GenerateNodeProperty('baseKeyword'),
    GenerateNodeProperty('interfaceKeyword'),
    GenerateNodeProperty('finalKeyword'),
    GenerateNodeProperty('mixinKeyword'),
    GenerateNodeProperty('classKeyword'),
    GenerateNodeProperty('name', isSuper: true),
    GenerateNodeProperty('typeParameters'),
    GenerateNodeProperty('extendsClause'),
    GenerateNodeProperty('withClause'),
    GenerateNodeProperty('implementsClause'),
    GenerateNodeProperty('nativeClause'),
    GenerateNodeProperty('leftBracket'),
    GenerateNodeProperty('members'),
    GenerateNodeProperty('rightBracket'),
  ],
)
final class ClassDeclarationImpl extends NamedCompilationUnitMemberImpl
    with AstNodeWithNameScopeMixin
    implements ClassDeclaration {
  @generated
  @override
  final Token? augmentKeyword;

  @generated
  @override
  final Token? abstractKeyword;

  @generated
  @override
  final Token? macroKeyword;

  @generated
  @override
  final Token? sealedKeyword;

  @generated
  @override
  final Token? baseKeyword;

  @generated
  @override
  final Token? interfaceKeyword;

  @generated
  @override
  final Token? finalKeyword;

  @generated
  @override
  final Token? mixinKeyword;

  @generated
  @override
  final Token classKeyword;

  @generated
  TypeParameterListImpl? _typeParameters;

  @generated
  ExtendsClauseImpl? _extendsClause;

  @generated
  WithClauseImpl? _withClause;

  @generated
  ImplementsClauseImpl? _implementsClause;

  @generated
  NativeClauseImpl? _nativeClause;

  @generated
  @override
  final Token leftBracket;

  @generated
  @override
  final NodeListImpl<ClassMemberImpl> members = NodeListImpl._();

  @generated
  @override
  final Token rightBracket;

  @override
  ClassFragmentImpl? declaredFragment;

  @generated
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
    required TypeParameterListImpl? typeParameters,
    required ExtendsClauseImpl? extendsClause,
    required WithClauseImpl? withClause,
    required ImplementsClauseImpl? implementsClause,
    required NativeClauseImpl? nativeClause,
    required this.leftBracket,
    required List<ClassMemberImpl> members,
    required this.rightBracket,
  }) : _typeParameters = typeParameters,
       _extendsClause = extendsClause,
       _withClause = withClause,
       _implementsClause = implementsClause,
       _nativeClause = nativeClause {
    _becomeParentOf(typeParameters);
    _becomeParentOf(extendsClause);
    _becomeParentOf(withClause);
    _becomeParentOf(implementsClause);
    _becomeParentOf(nativeClause);
    this.members._initialize(this, members);
  }

  @generated
  @override
  Token get endToken {
    return rightBracket;
  }

  @generated
  @override
  ExtendsClauseImpl? get extendsClause => _extendsClause;

  @generated
  set extendsClause(ExtendsClauseImpl? extendsClause) {
    _extendsClause = _becomeParentOf(extendsClause);
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (augmentKeyword case var augmentKeyword?) {
      return augmentKeyword;
    }
    if (abstractKeyword case var abstractKeyword?) {
      return abstractKeyword;
    }
    if (macroKeyword case var macroKeyword?) {
      return macroKeyword;
    }
    if (sealedKeyword case var sealedKeyword?) {
      return sealedKeyword;
    }
    if (baseKeyword case var baseKeyword?) {
      return baseKeyword;
    }
    if (interfaceKeyword case var interfaceKeyword?) {
      return interfaceKeyword;
    }
    if (finalKeyword case var finalKeyword?) {
      return finalKeyword;
    }
    if (mixinKeyword case var mixinKeyword?) {
      return mixinKeyword;
    }
    return classKeyword;
  }

  @generated
  @override
  ImplementsClauseImpl? get implementsClause => _implementsClause;

  @generated
  set implementsClause(ImplementsClauseImpl? implementsClause) {
    _implementsClause = _becomeParentOf(implementsClause);
  }

  @generated
  @override
  NativeClauseImpl? get nativeClause => _nativeClause;

  @generated
  set nativeClause(NativeClauseImpl? nativeClause) {
    _nativeClause = _becomeParentOf(nativeClause);
  }

  @generated
  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  @generated
  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @generated
  @override
  WithClauseImpl? get withClause => _withClause;

  @generated
  set withClause(WithClauseImpl? withClause) {
    _withClause = _becomeParentOf(withClause);
  }

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('augmentKeyword', augmentKeyword)
    ..addToken('abstractKeyword', abstractKeyword)
    ..addToken('macroKeyword', macroKeyword)
    ..addToken('sealedKeyword', sealedKeyword)
    ..addToken('baseKeyword', baseKeyword)
    ..addToken('interfaceKeyword', interfaceKeyword)
    ..addToken('finalKeyword', finalKeyword)
    ..addToken('mixinKeyword', mixinKeyword)
    ..addToken('classKeyword', classKeyword)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addNode('extendsClause', extendsClause)
    ..addNode('withClause', withClause)
    ..addNode('implementsClause', implementsClause)
    ..addNode('nativeClause', nativeClause)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('members', members)
    ..addToken('rightBracket', rightBracket);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitClassDeclaration(this);

  @generated
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

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (typeParameters case var typeParameters?) {
      if (typeParameters._containsOffset(rangeOffset, rangeEnd)) {
        return typeParameters;
      }
    }
    if (extendsClause case var extendsClause?) {
      if (extendsClause._containsOffset(rangeOffset, rangeEnd)) {
        return extendsClause;
      }
    }
    if (withClause case var withClause?) {
      if (withClause._containsOffset(rangeOffset, rangeEnd)) {
        return withClause;
      }
    }
    if (implementsClause case var implementsClause?) {
      if (implementsClause._containsOffset(rangeOffset, rangeEnd)) {
        return implementsClause;
      }
    }
    if (nativeClause case var nativeClause?) {
      if (nativeClause._containsOffset(rangeOffset, rangeEnd)) {
        return nativeClause;
      }
    }
    if (members._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// A node that declares a name within the scope of a class, enum, extension,
/// extension type, or mixin declaration.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
sealed class ClassMember implements Declaration {}

sealed class ClassMemberImpl extends DeclarationImpl implements ClassMember {
  /// Initializes a newly created member of a class.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the member
  /// doesn't have the corresponding attribute.
  ClassMemberImpl({required super.comment, required super.metadata});
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ClassTypeAlias implements TypeAlias {
  /// The token for the `abstract` keyword, or `null` if this isn't defining an
  /// abstract class.
  Token? get abstractKeyword;

  /// The `base` keyword, or `null` if the keyword was absent.
  Token? get baseKeyword;

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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('abstractKeyword'),
    GenerateNodeProperty('sealedKeyword'),
    GenerateNodeProperty('baseKeyword'),
    GenerateNodeProperty('interfaceKeyword'),
    GenerateNodeProperty('finalKeyword'),
    GenerateNodeProperty('augmentKeyword', isSuper: true),
    GenerateNodeProperty('mixinKeyword'),
    GenerateNodeProperty('typedefKeyword', isSuper: true),
    GenerateNodeProperty('name', isSuper: true),
    GenerateNodeProperty('typeParameters'),
    GenerateNodeProperty('equals'),
    GenerateNodeProperty('superclass'),
    GenerateNodeProperty('withClause'),
    GenerateNodeProperty('implementsClause'),
    GenerateNodeProperty('semicolon', isSuper: true),
  ],
)
final class ClassTypeAliasImpl extends TypeAliasImpl implements ClassTypeAlias {
  @generated
  @override
  final Token? abstractKeyword;

  @generated
  @override
  final Token? sealedKeyword;

  @generated
  @override
  final Token? baseKeyword;

  @generated
  @override
  final Token? interfaceKeyword;

  @generated
  @override
  final Token? finalKeyword;

  @generated
  @override
  final Token? mixinKeyword;

  @generated
  TypeParameterListImpl? _typeParameters;

  @generated
  @override
  final Token equals;

  @generated
  NamedTypeImpl _superclass;

  @generated
  WithClauseImpl _withClause;

  @generated
  ImplementsClauseImpl? _implementsClause;

  @override
  ClassFragmentImpl? declaredFragment;

  @generated
  ClassTypeAliasImpl({
    required super.comment,
    required super.metadata,
    required this.abstractKeyword,
    required this.sealedKeyword,
    required this.baseKeyword,
    required this.interfaceKeyword,
    required this.finalKeyword,
    required super.augmentKeyword,
    required this.mixinKeyword,
    required super.typedefKeyword,
    required super.name,
    required TypeParameterListImpl? typeParameters,
    required this.equals,
    required NamedTypeImpl superclass,
    required WithClauseImpl withClause,
    required ImplementsClauseImpl? implementsClause,
    required super.semicolon,
  }) : _typeParameters = typeParameters,
       _superclass = superclass,
       _withClause = withClause,
       _implementsClause = implementsClause {
    _becomeParentOf(typeParameters);
    _becomeParentOf(superclass);
    _becomeParentOf(withClause);
    _becomeParentOf(implementsClause);
  }

  @generated
  @override
  Token get endToken {
    return semicolon;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (abstractKeyword case var abstractKeyword?) {
      return abstractKeyword;
    }
    if (sealedKeyword case var sealedKeyword?) {
      return sealedKeyword;
    }
    if (baseKeyword case var baseKeyword?) {
      return baseKeyword;
    }
    if (interfaceKeyword case var interfaceKeyword?) {
      return interfaceKeyword;
    }
    if (finalKeyword case var finalKeyword?) {
      return finalKeyword;
    }
    if (augmentKeyword case var augmentKeyword?) {
      return augmentKeyword;
    }
    if (mixinKeyword case var mixinKeyword?) {
      return mixinKeyword;
    }
    return typedefKeyword;
  }

  @generated
  @override
  ImplementsClauseImpl? get implementsClause => _implementsClause;

  @generated
  set implementsClause(ImplementsClauseImpl? implementsClause) {
    _implementsClause = _becomeParentOf(implementsClause);
  }

  @generated
  @override
  NamedTypeImpl get superclass => _superclass;

  @generated
  set superclass(NamedTypeImpl superclass) {
    _superclass = _becomeParentOf(superclass);
  }

  @generated
  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  @generated
  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @generated
  @override
  WithClauseImpl get withClause => _withClause;

  @generated
  set withClause(WithClauseImpl withClause) {
    _withClause = _becomeParentOf(withClause);
  }

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('abstractKeyword', abstractKeyword)
    ..addToken('sealedKeyword', sealedKeyword)
    ..addToken('baseKeyword', baseKeyword)
    ..addToken('interfaceKeyword', interfaceKeyword)
    ..addToken('finalKeyword', finalKeyword)
    ..addToken('augmentKeyword', augmentKeyword)
    ..addToken('mixinKeyword', mixinKeyword)
    ..addToken('typedefKeyword', typedefKeyword)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addToken('equals', equals)
    ..addNode('superclass', superclass)
    ..addNode('withClause', withClause)
    ..addNode('implementsClause', implementsClause)
    ..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitClassTypeAlias(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    typeParameters?.accept(visitor);
    superclass.accept(visitor);
    withClause.accept(visitor);
    implementsClause?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (typeParameters case var typeParameters?) {
      if (typeParameters._containsOffset(rangeOffset, rangeEnd)) {
        return typeParameters;
      }
    }
    if (superclass._containsOffset(rangeOffset, rangeEnd)) {
      return superclass;
    }
    if (withClause._containsOffset(rangeOffset, rangeEnd)) {
      return withClause;
    }
    if (implementsClause case var implementsClause?) {
      if (implementsClause._containsOffset(rangeOffset, rangeEnd)) {
        return implementsClause;
      }
    }
    return null;
  }
}

@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
sealed class CollectionElement implements AstNode {}

sealed class CollectionElementImpl extends AstNodeImpl
    implements CollectionElement {
  /// Dispatches this collection element to the [resolver], with the given
  /// [context] information.
  void resolveElement(
    ResolverVisitor resolver,
    CollectionLiteralContext? context,
  );
}

/// A combinator associated with an import or export directive.
///
///    combinator ::=
///        [HideCombinator]
///      | [ShowCombinator]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
sealed class Combinator implements AstNode {
  /// The `hide` or `show` keyword specifying what kind of processing is to be
  /// done on the names.
  Token get keyword;
}

sealed class CombinatorImpl extends AstNodeImpl implements Combinator {
  @override
  final Token keyword;

  /// Initializes a newly created combinator.
  CombinatorImpl({required this.keyword});

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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class Comment implements AstNode {
  /// The markdown code blocks (both fenced and indented) contained in this
  /// comment.
  List<MdCodeBlock> get codeBlocks;

  List<DocDirective> get docDirectives;

  List<DocImport> get docImports;

  /// Whether this comment has a line beginning with '@nodoc', indicating its
  /// contents aren't intended for publishing.
  bool get hasNodoc;

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

  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    return _references._elementContainingRange(rangeOffset, rangeEnd);
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class CommentReferableExpression implements Expression {}

sealed class CommentReferableExpressionImpl extends ExpressionImpl
    implements CommentReferableExpression {}

/// A reference to a Dart element that is found within a documentation comment.
///
///    commentReference ::=
///        '[' 'new'? [CommentReferableExpression] ']'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class CommentReference implements AstNode {
  /// The comment-referable expression being referenced.
  CommentReferableExpression get expression;

  /// The token representing the `new` keyword, or `null` if there was no `new`
  /// keyword.
  Token? get newKeyword;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('newKeyword'),
    GenerateNodeProperty('expression'),
    GenerateNodeProperty('isSynthetic'),
  ],
)
final class CommentReferenceImpl extends AstNodeImpl
    implements CommentReference {
  @generated
  @override
  final Token? newKeyword;

  @generated
  CommentReferableExpressionImpl _expression;

  @generated
  @override
  final bool isSynthetic;

  @generated
  CommentReferenceImpl({
    required this.newKeyword,
    required CommentReferableExpressionImpl expression,
    required this.isSynthetic,
  }) : _expression = expression {
    _becomeParentOf(expression);
  }

  @generated
  @override
  Token get beginToken {
    if (newKeyword case var newKeyword?) {
      return newKeyword;
    }
    return expression.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return expression.endToken;
  }

  @generated
  @override
  CommentReferableExpressionImpl get expression => _expression;

  @generated
  set expression(CommentReferableExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('newKeyword', newKeyword)
    ..addNode('expression', expression);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitCommentReference(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class CompilationUnit implements AstNode {
  /// The first (non-EOF) token in the token stream that was parsed to form this
  /// compilation unit.
  @override
  Token get beginToken;

  /// The declarations contained in this compilation unit.
  NodeList<CompilationUnitMember> get declarations;

  /// The fragment associated with this compilation unit.
  ///
  /// Returns `null` if the AST structure hasn't been resolved.
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

  /// The language version information.
  LibraryLanguageVersion get languageVersion;

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

  /// Returns the minimal covering node for the range of characters beginning at
  /// the [offset] with the given [length].
  ///
  /// Returns `null` if the range is outside the range covered by the receiver.
  ///
  /// The minimal covering node is the node, rooted at the receiver, with the
  /// shortest length whose range completely includes the given range.
  AstNode? nodeCovering({required int offset, int length = 0});
}

final class CompilationUnitImpl extends AstNodeImpl
    with AstNodeWithNameScopeMixin
    implements CompilationUnit {
  @override
  final Token beginToken;

  ScriptTagImpl? _scriptTag;

  final NodeListImpl<DirectiveImpl> _directives = NodeListImpl._();

  final NodeListImpl<CompilationUnitMemberImpl> _declarations =
      NodeListImpl._();

  @override
  final Token endToken;

  @override
  LibraryFragmentImpl? declaredFragment;

  @override
  final LineInfo lineInfo;

  @override
  final LibraryLanguageVersion languageVersion;

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
    required this.languageVersion,
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
    return <AstNode>[..._directives, ..._declarations]
      ..sort(AstNode.LEXICAL_ORDER);
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
  AstNode? nodeCovering({required int offset, int length = 0}) {
    var end = offset + length;

    if (offset < 0 || end > this.end) {
      return null;
    }
    AstNodeImpl previousNode = this;
    var currentNode = previousNode._childContainingRange(offset, end);
    while (currentNode != null) {
      previousNode = currentNode;
      currentNode = previousNode._childContainingRange(offset, end);
    }
    return previousNode;
  }

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

  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (_scriptTag?._containsOffset(rangeOffset, rangeEnd) ?? false) {
      return _scriptTag;
    }
    return _directives._elementContainingRange(rangeOffset, rangeEnd) ??
        _declarations._elementContainingRange(rangeOffset, rangeEnd);
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class CompilationUnitMember implements Declaration {}

sealed class CompilationUnitMemberImpl extends DeclarationImpl
    implements CompilationUnitMember {
  /// Initializes a newly created compilation unit member.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the member
  /// doesn't have the corresponding attribute.
  CompilationUnitMemberImpl({required super.comment, required super.metadata});
}

/// A potentially compound assignment.
///
/// A compound assignment is any node in which a single expression is used to
/// specify both where to access a value to be operated on (the "read") and to
/// specify where to store the result of the operation (the "write"). This
/// happens in an [AssignmentExpression] when the assignment operator is a
/// compound assignment operator, and in a [PrefixExpression] or
/// [PostfixExpression] when the operator is an increment operator.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class CompoundAssignmentExpression implements Expression {
  /// The element that is used to read the value.
  ///
  /// Returns `null` if this node isn't a compound assignment, if the AST
  /// structure hasn't been resolved, or if the target couldn't be resolved.
  ///
  /// In valid code this element can be a [LocalVariableElement], a
  /// [FormalParameterElement], or a [GetterElement].
  ///
  /// In invalid code this element is `null`. For example, in `int += 2`. In
  /// such cases, for recovery purposes, [writeElement] is filled, and can be
  /// used for navigation.
  Element? get readElement;

  /// The element that is used to read the value.
  ///
  /// Returns `null` if this node isn't a compound assignment, if the AST
  /// structure hasn't been resolved, or if the target couldn't be resolved.
  ///
  /// In valid code this element can be a [LocalVariableElement], a
  /// [FormalParameterElement], or a [GetterElement].
  ///
  /// In invalid code this element is `null`. For example, in `int += 2`. In
  /// such cases, for recovery purposes, [writeElement] is filled, and can be
  /// used for navigation.
  @Deprecated('Use readElement instead')
  Element? get readElement2;

  /// The type of the value read with the [readElement], or `null` if this node
  /// isn't a compound assignment.
  ///
  /// Returns the type `dynamic` if the code is invalid, if the AST structure
  /// hasn't been resolved, or if the target couldn't be resolved.
  DartType? get readType;

  /// The element that is used to write the result.
  ///
  /// Returns `null` if the AST structure hasn't been resolved, or if the target
  /// couldn't be resolved.
  ///
  /// In valid code this is a [LocalVariableElement], [FormalParameterElement],
  /// or a [SetterElement].
  ///
  /// In invalid code, for recovery, we might use other elements, for example a
  /// [GetterElement] `myGetter = 0` even though the getter can't be used to set
  /// a value. We do this to help the user to navigate to the getter, and maybe
  /// add the corresponding setter.
  ///
  /// If this node is a compound assignment, such as `x += y`, both
  /// [readElement] and [writeElement] could be non-`null`.
  Element? get writeElement;

  /// The element that is used to write the result.
  ///
  /// Returns `null` if the AST structure hasn't been resolved, or if the target
  /// couldn't be resolved.
  ///
  /// In valid code this is a [LocalVariableElement], [FormalParameterElement],
  /// or a [SetterElement].
  ///
  /// In invalid code, for recovery, we might use other elements, for example a
  /// [GetterElement] `myGetter = 0` even though the getter can't be used to set
  /// a value. We do this to help the user to navigate to the getter, and maybe
  /// add the corresponding setter.
  ///
  /// If this node is a compound assignment, such as `x += y`, both
  /// [readElement] and [writeElement] could be non-`null`.
  @Deprecated('Use writeElement instead')
  Element? get writeElement2;

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
  TypeImpl? readType;

  @override
  TypeImpl? writeType;

  @Deprecated('Use readElement instead')
  @override
  Element? get readElement2 => readElement;

  @Deprecated('Use writeElement instead')
  @override
  Element? get writeElement2 => writeElement;
}

/// A conditional expression.
///
///    conditionalExpression ::=
///        [Expression] '?' [Expression] ':' [Expression]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('condition'),
    GenerateNodeProperty('question'),
    GenerateNodeProperty('thenExpression'),
    GenerateNodeProperty('colon'),
    GenerateNodeProperty('elseExpression'),
  ],
)
final class ConditionalExpressionImpl extends ExpressionImpl
    implements ConditionalExpression {
  @generated
  ExpressionImpl _condition;

  @generated
  @override
  final Token question;

  @generated
  ExpressionImpl _thenExpression;

  @generated
  @override
  final Token colon;

  @generated
  ExpressionImpl _elseExpression;

  @generated
  ConditionalExpressionImpl({
    required ExpressionImpl condition,
    required this.question,
    required ExpressionImpl thenExpression,
    required this.colon,
    required ExpressionImpl elseExpression,
  }) : _condition = condition,
       _thenExpression = thenExpression,
       _elseExpression = elseExpression {
    _becomeParentOf(condition);
    _becomeParentOf(thenExpression);
    _becomeParentOf(elseExpression);
  }

  @generated
  @override
  Token get beginToken {
    return condition.beginToken;
  }

  @generated
  @override
  ExpressionImpl get condition => _condition;

  @generated
  set condition(ExpressionImpl condition) {
    _condition = _becomeParentOf(condition);
  }

  @generated
  @override
  ExpressionImpl get elseExpression => _elseExpression;

  @generated
  set elseExpression(ExpressionImpl elseExpression) {
    _elseExpression = _becomeParentOf(elseExpression);
  }

  @generated
  @override
  Token get endToken {
    return elseExpression.endToken;
  }

  @override
  Precedence get precedence => Precedence.conditional;

  @generated
  @override
  ExpressionImpl get thenExpression => _thenExpression;

  @generated
  set thenExpression(ExpressionImpl thenExpression) {
    _thenExpression = _becomeParentOf(thenExpression);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('condition', condition)
    ..addToken('question', question)
    ..addNode('thenExpression', thenExpression)
    ..addToken('colon', colon)
    ..addNode('elseExpression', elseExpression);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitConditionalExpression(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitConditionalExpression(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    condition.accept(visitor);
    thenExpression.accept(visitor);
    elseExpression.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (condition._containsOffset(rangeOffset, rangeEnd)) {
      return condition;
    }
    if (thenExpression._containsOffset(rangeOffset, rangeEnd)) {
      return thenExpression;
    }
    if (elseExpression._containsOffset(rangeOffset, rangeEnd)) {
      return elseExpression;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('ifKeyword'),
    GenerateNodeProperty('leftParenthesis'),
    GenerateNodeProperty('name'),
    GenerateNodeProperty('equalToken'),
    GenerateNodeProperty('value'),
    GenerateNodeProperty('rightParenthesis'),
    GenerateNodeProperty('uri'),
  ],
)
final class ConfigurationImpl extends AstNodeImpl implements Configuration {
  @generated
  @override
  final Token ifKeyword;

  @generated
  @override
  final Token leftParenthesis;

  @generated
  DottedNameImpl _name;

  @generated
  @override
  final Token? equalToken;

  @generated
  StringLiteralImpl? _value;

  @generated
  @override
  final Token rightParenthesis;

  @generated
  StringLiteralImpl _uri;

  @override
  DirectiveUri? resolvedUri;

  @generated
  ConfigurationImpl({
    required this.ifKeyword,
    required this.leftParenthesis,
    required DottedNameImpl name,
    required this.equalToken,
    required StringLiteralImpl? value,
    required this.rightParenthesis,
    required StringLiteralImpl uri,
  }) : _name = name,
       _value = value,
       _uri = uri {
    _becomeParentOf(name);
    _becomeParentOf(value);
    _becomeParentOf(uri);
  }

  @generated
  @override
  Token get beginToken {
    return ifKeyword;
  }

  @generated
  @override
  Token get endToken {
    return uri.endToken;
  }

  @generated
  @override
  DottedNameImpl get name => _name;

  @generated
  set name(DottedNameImpl name) {
    _name = _becomeParentOf(name);
  }

  @generated
  @override
  StringLiteralImpl get uri => _uri;

  @generated
  set uri(StringLiteralImpl uri) {
    _uri = _becomeParentOf(uri);
  }

  @generated
  @override
  StringLiteralImpl? get value => _value;

  @generated
  set value(StringLiteralImpl? value) {
    _value = _becomeParentOf(value);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('ifKeyword', ifKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('name', name)
    ..addToken('equalToken', equalToken)
    ..addNode('value', value)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addNode('uri', uri);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitConfiguration(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    name.accept(visitor);
    value?.accept(visitor);
    uri.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (name._containsOffset(rangeOffset, rangeEnd)) {
      return name;
    }
    if (value case var value?) {
      if (value._containsOffset(rangeOffset, rangeEnd)) {
        return value;
      }
    }
    if (uri._containsOffset(rangeOffset, rangeEnd)) {
      return uri;
    }
    return null;
  }
}

final class ConstantContextForExpressionImpl extends AstNodeImpl {
  final Fragment variable;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ConstantPattern implements DartPattern {
  /// The `const` keyword, or `null` if the expression isn't preceded by the
  /// keyword `const`.
  Token? get constKeyword;

  /// The constant expression being used as a pattern.
  Expression get expression;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('constKeyword'),
    GenerateNodeProperty('expression'),
  ],
)
final class ConstantPatternImpl extends DartPatternImpl
    implements ConstantPattern {
  @generated
  @override
  final Token? constKeyword;

  @generated
  ExpressionImpl _expression;

  @generated
  ConstantPatternImpl({
    required this.constKeyword,
    required ExpressionImpl expression,
  }) : _expression = expression {
    _becomeParentOf(expression);
  }

  @generated
  @override
  Token get beginToken {
    if (constKeyword case var constKeyword?) {
      return constKeyword;
    }
    return expression.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return expression.endToken;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('constKeyword', constKeyword)
    ..addNode('expression', expression);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitConstantPattern(this);

  @override
  TypeImpl computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor
        .analyzeConstantPatternSchema()
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    inferenceLogWriter?.enterPattern(this);
    var analysisResult = resolverVisitor.analyzeConstantPattern(
      context,
      this,
      expression,
    );
    expression = resolverVisitor.popRewrite()!;
    inferenceLogWriter?.exitPattern(this);
    return analysisResult;
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    return null;
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
///      | 'external'? 'const' constructorName formalParameterList
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ConstructorDeclaration implements ClassMember {
  /// The `augment` keyword, or `null` if the keyword was absent.
  Token? get augmentKeyword;

  /// The body of the constructor.
  FunctionBody get body;

  /// The token for the `const` keyword, or `null` if the constructor isn't a
  /// const constructor.
  Token? get constKeyword;

  @override
  ConstructorFragment? get declaredFragment;

  /// The token for the `external` keyword to this constructor declaration.
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
  Identifier get returnType;

  /// The token for the separator (colon or equals) before the initializer list
  /// or redirection, or `null` if there are neither initializers nor a
  /// redirection.
  Token? get separator;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('augmentKeyword', tokenGroupId: 0),
    GenerateNodeProperty('externalKeyword', tokenGroupId: 0),
    GenerateNodeProperty('constKeyword', tokenGroupId: 0, isTokenFinal: false),
    GenerateNodeProperty('factoryKeyword', tokenGroupId: 0),
    GenerateNodeProperty('returnType'),
    GenerateNodeProperty('period'),
    GenerateNodeProperty('name'),
    GenerateNodeProperty('parameters'),
    GenerateNodeProperty('separator', isTokenFinal: false),
    GenerateNodeProperty('initializers'),
    GenerateNodeProperty('redirectedConstructor'),
    GenerateNodeProperty('body'),
  ],
)
final class ConstructorDeclarationImpl extends ClassMemberImpl
    implements ConstructorDeclaration {
  @generated
  @override
  final Token? augmentKeyword;

  @generated
  @override
  final Token? externalKeyword;

  @generated
  @override
  Token? constKeyword;

  @generated
  @override
  final Token? factoryKeyword;

  @generated
  IdentifierImpl _returnType;

  @generated
  @override
  final Token? period;

  @generated
  @override
  final Token? name;

  @generated
  FormalParameterListImpl _parameters;

  @generated
  @override
  Token? separator;

  @generated
  @override
  final NodeListImpl<ConstructorInitializerImpl> initializers =
      NodeListImpl._();

  @generated
  ConstructorNameImpl? _redirectedConstructor;

  @generated
  FunctionBodyImpl _body;

  @override
  ConstructorFragmentImpl? declaredFragment;

  @generated
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
    required List<ConstructorInitializerImpl> initializers,
    required ConstructorNameImpl? redirectedConstructor,
    required FunctionBodyImpl body,
  }) : _returnType = returnType,
       _parameters = parameters,
       _redirectedConstructor = redirectedConstructor,
       _body = body {
    _becomeParentOf(returnType);
    _becomeParentOf(parameters);
    this.initializers._initialize(this, initializers);
    _becomeParentOf(redirectedConstructor);
    _becomeParentOf(body);
  }

  @generated
  @override
  FunctionBodyImpl get body => _body;

  @generated
  set body(FunctionBodyImpl body) {
    _body = _becomeParentOf(body);
  }

  @generated
  @override
  Token get endToken {
    return body.endToken;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (Token.lexicallyFirst(
          augmentKeyword,
          externalKeyword,
          constKeyword,
          factoryKeyword,
        )
        case var result?) {
      return result;
    }
    return returnType.beginToken;
  }

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

  @generated
  @override
  FormalParameterListImpl get parameters => _parameters;

  @generated
  set parameters(FormalParameterListImpl parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @generated
  @override
  ConstructorNameImpl? get redirectedConstructor => _redirectedConstructor;

  @generated
  set redirectedConstructor(ConstructorNameImpl? redirectedConstructor) {
    _redirectedConstructor = _becomeParentOf(redirectedConstructor);
  }

  @generated
  @override
  IdentifierImpl get returnType => _returnType;

  @generated
  set returnType(IdentifierImpl returnType) {
    _returnType = _becomeParentOf(returnType);
  }

  @generated
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

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitConstructorDeclaration(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    returnType.accept(visitor);
    parameters.accept(visitor);
    initializers.accept(visitor);
    redirectedConstructor?.accept(visitor);
    body.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (returnType._containsOffset(rangeOffset, rangeEnd)) {
      return returnType;
    }
    if (parameters._containsOffset(rangeOffset, rangeEnd)) {
      return parameters;
    }
    if (initializers._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    if (redirectedConstructor case var redirectedConstructor?) {
      if (redirectedConstructor._containsOffset(rangeOffset, rangeEnd)) {
        return redirectedConstructor;
      }
    }
    if (body._containsOffset(rangeOffset, rangeEnd)) {
      return body;
    }
    return null;
  }
}

/// The initialization of a field within a constructor's initialization list.
///
///    fieldInitializer ::=
///        ('this' '.')? [SimpleIdentifier] '=' [Expression]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('thisKeyword'),
    GenerateNodeProperty('period'),
    GenerateNodeProperty('fieldName'),
    GenerateNodeProperty('equals'),
    GenerateNodeProperty('expression'),
  ],
)
final class ConstructorFieldInitializerImpl extends ConstructorInitializerImpl
    implements ConstructorFieldInitializer {
  @generated
  @override
  final Token? thisKeyword;

  @generated
  @override
  final Token? period;

  @generated
  SimpleIdentifierImpl _fieldName;

  @generated
  @override
  final Token equals;

  @generated
  ExpressionImpl _expression;

  @generated
  ConstructorFieldInitializerImpl({
    required this.thisKeyword,
    required this.period,
    required SimpleIdentifierImpl fieldName,
    required this.equals,
    required ExpressionImpl expression,
  }) : _fieldName = fieldName,
       _expression = expression {
    _becomeParentOf(fieldName);
    _becomeParentOf(expression);
  }

  @generated
  @override
  Token get beginToken {
    if (thisKeyword case var thisKeyword?) {
      return thisKeyword;
    }
    if (period case var period?) {
      return period;
    }
    return fieldName.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return expression.endToken;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @generated
  @override
  SimpleIdentifierImpl get fieldName => _fieldName;

  @generated
  set fieldName(SimpleIdentifierImpl fieldName) {
    _fieldName = _becomeParentOf(fieldName);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('thisKeyword', thisKeyword)
    ..addToken('period', period)
    ..addNode('fieldName', fieldName)
    ..addToken('equals', equals)
    ..addNode('expression', expression);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitConstructorFieldInitializer(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    fieldName.accept(visitor);
    expression.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (fieldName._containsOffset(rangeOffset, rangeEnd)) {
      return fieldName;
    }
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    return null;
  }
}

/// A node that can occur in the initializer list of a constructor declaration.
///
///    constructorInitializer ::=
///        [SuperConstructorInvocation]
///      | [ConstructorFieldInitializer]
///      | [RedirectingConstructorInvocation]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
sealed class ConstructorInitializer implements AstNode {}

sealed class ConstructorInitializerImpl extends AstNodeImpl
    implements ConstructorInitializer {}

/// The name of a constructor.
///
///    constructorName ::=
///        type ('.' identifier)?
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('type'),
    GenerateNodeProperty('period', isTokenFinal: false),
    GenerateNodeProperty('name'),
  ],
)
final class ConstructorNameImpl extends AstNodeImpl implements ConstructorName {
  @generated
  NamedTypeImpl _type;

  @generated
  @override
  Token? period;

  @generated
  SimpleIdentifierImpl? _name;

  @override
  InternalConstructorElement? element;

  @generated
  ConstructorNameImpl({
    required NamedTypeImpl type,
    required this.period,
    required SimpleIdentifierImpl? name,
  }) : _type = type,
       _name = name {
    _becomeParentOf(type);
    _becomeParentOf(name);
  }

  @generated
  @override
  Token get beginToken {
    return type.beginToken;
  }

  @generated
  @override
  Token get endToken {
    if (name case var name?) {
      return name.endToken;
    }
    if (period case var period?) {
      return period;
    }
    return type.endToken;
  }

  @generated
  @override
  SimpleIdentifierImpl? get name => _name;

  @generated
  set name(SimpleIdentifierImpl? name) {
    _name = _becomeParentOf(name);
  }

  @generated
  @override
  NamedTypeImpl get type => _type;

  @generated
  set type(NamedTypeImpl type) {
    _type = _becomeParentOf(type);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('type', type)
    ..addToken('period', period)
    ..addNode('name', name);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitConstructorName(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    type.accept(visitor);
    name?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (type._containsOffset(rangeOffset, rangeEnd)) {
      return type;
    }
    if (name case var name?) {
      if (name._containsOffset(rangeOffset, rangeEnd)) {
        return name;
      }
    }
    return null;
  }
}

/// An expression representing a reference to a constructor.
///
/// For example, the expression `List.filled` in `var x = List.filled;`.
///
/// Objects of this type aren't produced directly by the parser (because the
/// parser can't tell whether an identifier refers to a type); they are
/// produced at resolution time.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ConstructorReference
    implements Expression, CommentReferableExpression {
  /// The constructor being referenced.
  ConstructorName get constructorName;
}

@GenerateNodeImpl(childEntitiesOrder: [GenerateNodeProperty('constructorName')])
final class ConstructorReferenceImpl extends CommentReferableExpressionImpl
    implements ConstructorReference {
  @generated
  ConstructorNameImpl _constructorName;

  @generated
  ConstructorReferenceImpl({required ConstructorNameImpl constructorName})
    : _constructorName = constructorName {
    _becomeParentOf(constructorName);
  }

  @generated
  @override
  Token get beginToken {
    return constructorName.beginToken;
  }

  @generated
  @override
  ConstructorNameImpl get constructorName => _constructorName;

  @generated
  set constructorName(ConstructorNameImpl constructorName) {
    _constructorName = _becomeParentOf(constructorName);
  }

  @generated
  @override
  Token get endToken {
    return constructorName.endToken;
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @generated
  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addNode('constructorName', constructorName);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitConstructorReference(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitConstructorReference(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    constructorName.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (constructorName._containsOffset(rangeOffset, rangeEnd)) {
      return constructorName;
    }
    return null;
  }
}

/// An AST node that makes reference to a constructor.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ConstructorReferenceNode implements AstNode {
  /// The element associated with the referenced constructor based on static
  /// type information.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if the
  /// constructor couldn't be resolved.
  ConstructorElement? get element;
}

/// The name of a constructor being invoked.
///
///    constructorSelector ::=
///        '.' identifier
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ConstructorSelector implements AstNode {
  /// The constructor name.
  SimpleIdentifier get name;

  /// The period before the constructor name.
  Token get period;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('period'),
    GenerateNodeProperty('name'),
  ],
)
final class ConstructorSelectorImpl extends AstNodeImpl
    implements ConstructorSelector {
  @generated
  @override
  final Token period;

  @generated
  SimpleIdentifierImpl _name;

  @generated
  ConstructorSelectorImpl({
    required this.period,
    required SimpleIdentifierImpl name,
  }) : _name = name {
    _becomeParentOf(name);
  }

  @generated
  @override
  Token get beginToken {
    return period;
  }

  @generated
  @override
  Token get endToken {
    return name.endToken;
  }

  @generated
  @override
  SimpleIdentifierImpl get name => _name;

  @generated
  set name(SimpleIdentifierImpl name) {
    _name = _becomeParentOf(name);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('period', period)
    ..addNode('name', name);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitConstructorSelector(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    name.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (name._containsOffset(rangeOffset, rangeEnd)) {
      return name;
    }
    return null;
  }
}

/// A continue statement.
///
///    continueStatement ::=
///        'continue' [SimpleIdentifier]? ';'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('continueKeyword'),
    GenerateNodeProperty('label'),
    GenerateNodeProperty('semicolon'),
  ],
)
final class ContinueStatementImpl extends StatementImpl
    implements ContinueStatement {
  @generated
  @override
  final Token continueKeyword;

  @generated
  SimpleIdentifierImpl? _label;

  @generated
  @override
  final Token semicolon;

  @override
  AstNode? target;

  @generated
  ContinueStatementImpl({
    required this.continueKeyword,
    required SimpleIdentifierImpl? label,
    required this.semicolon,
  }) : _label = label {
    _becomeParentOf(label);
  }

  @generated
  @override
  Token get beginToken {
    return continueKeyword;
  }

  @generated
  @override
  Token get endToken {
    return semicolon;
  }

  @generated
  @override
  SimpleIdentifierImpl? get label => _label;

  @generated
  set label(SimpleIdentifierImpl? label) {
    _label = _becomeParentOf(label);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('continueKeyword', continueKeyword)
    ..addNode('label', label)
    ..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitContinueStatement(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    label?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (label case var label?) {
      if (label._containsOffset(rangeOffset, rangeEnd)) {
        return label;
      }
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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
  TypeImpl? matchedValueType;

  /// The context for this pattern.
  ///
  /// The possible contexts are
  /// - Declaration context:
  ///     [ForEachPartsWithPatternImpl]
  ///     [PatternVariableDeclarationImpl]
  /// - Assignment context: [PatternAssignmentImpl]
  /// - Matching context: [GuardedPatternImpl]
  AstNodeImpl? get patternContext {
    for (DartPatternImpl current = this; ;) {
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

  TypeImpl computePatternSchema(ResolverVisitor resolverVisitor);

  /// Dispatches this pattern to the [resolverVisitor], with the given [context]
  /// information.
  ///
  /// Note: most code shouldn't call this method directly, but should instead
  /// call [ResolverVisitor.dispatchPattern], which has some special logic for
  /// handling dynamic contexts.
  PatternResult resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  );
}

/// A node that represents the declaration of one or more names.
///
/// Each declared name is visible within a name scope.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class Declaration implements AnnotatedNode {
  /// The fragment declared by this declaration.
  ///
  /// Returns `null` if the AST structure hasn't been resolved.
  ///
  /// Returns `null` for [FieldDeclaration] and [TopLevelVariableDeclaration]
  /// because these nodes don't declare any fragments, but individual
  /// [VariableDeclaration]s inside them do. They are [Declaration]s mostly to
  /// fit into [ClassDeclaration.members] and [CompilationUnit.declarations].
  Fragment? get declaredFragment;
}

sealed class DeclarationImpl extends AnnotatedNodeImpl implements Declaration {
  /// Initializes a newly created declaration.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// declaration doesn't have the corresponding attribute.
  DeclarationImpl({required super.comment, required super.metadata});

  @override
  FragmentImpl? get declaredFragment;
}

/// The declaration of a single identifier.
///
///    declaredIdentifier ::=
///        [Annotation] finalConstVarOrType [SimpleIdentifier]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class DeclaredIdentifier implements Declaration {
  /// The element associated with this declaration.
  ///
  /// Returns `null` if either this node corresponds to a list of declarations
  /// or if the AST structure hasn't been resolved.
  @Deprecated('Use declaredFragment instead')
  LocalVariableElement? get declaredElement;

  /// The element associated with this declaration.
  ///
  /// Returns `null` if either this node corresponds to a list of declarations
  /// or if the AST structure hasn't been resolved.
  @Deprecated('Use declaredFragment instead')
  LocalVariableElement? get declaredElement2;

  @override
  LocalVariableFragment? get declaredFragment;

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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('keyword'),
    GenerateNodeProperty('type'),
    GenerateNodeProperty('name'),
  ],
)
final class DeclaredIdentifierImpl extends DeclarationImpl
    implements DeclaredIdentifier {
  @generated
  @override
  final Token? keyword;

  @generated
  TypeAnnotationImpl? _type;

  @generated
  @override
  final Token name;

  @override
  LocalVariableFragmentImpl? declaredFragment;

  @generated
  DeclaredIdentifierImpl({
    required super.comment,
    required super.metadata,
    required this.keyword,
    required TypeAnnotationImpl? type,
    required this.name,
  }) : _type = type {
    _becomeParentOf(type);
  }

  @Deprecated('Use declaredFragment instead')
  @override
  LocalVariableElementImpl? get declaredElement {
    return declaredFragment?.element;
  }

  @Deprecated('Use declaredFragment instead')
  @override
  LocalVariableElementImpl? get declaredElement2 {
    return declaredElement;
  }

  @generated
  @override
  Token get endToken {
    return name;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (keyword case var keyword?) {
      return keyword;
    }
    if (type case var type?) {
      return type.beginToken;
    }
    return name;
  }

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @generated
  @override
  TypeAnnotationImpl? get type => _type;

  @generated
  set type(TypeAnnotationImpl? type) {
    _type = _becomeParentOf(type);
  }

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('keyword', keyword)
    ..addNode('type', type)
    ..addToken('name', name);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitDeclaredIdentifier(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    type?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (type case var type?) {
      if (type._containsOffset(rangeOffset, rangeEnd)) {
        return type;
      }
    }
    return null;
  }
}

/// A variable pattern that declares a variable.
///
///    variablePattern ::=
///        ( 'var' | 'final' | 'final'? [TypeAnnotation])? [Identifier]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
sealed class DeclaredVariablePattern implements VariablePattern {
  /// The element declared by this declaration.
  ///
  /// Returns `null` if the AST structure hasn't been resolved.
  @Deprecated('Use declaredFragment instead')
  BindPatternVariableElement? get declaredElement;

  /// The element declared by this declaration.
  ///
  /// Returns `null` if the AST structure hasn't been resolved.
  @Deprecated('Use declaredFragment instead')
  BindPatternVariableElement? get declaredElement2;

  /// The fragment declared by this declaration.
  ///
  /// Returns `null` if the AST structure hasn't been resolved.
  BindPatternVariableFragment? get declaredFragment;

  /// The `var` or `final` keyword.
  Token? get keyword;

  /// The type that the variable is required to match, or `null` if any type is
  /// matched.
  TypeAnnotation? get type;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('keyword'),
    GenerateNodeProperty('type'),
    GenerateNodeProperty('name', isSuper: true),
  ],
)
final class DeclaredVariablePatternImpl extends VariablePatternImpl
    implements DeclaredVariablePattern {
  @generated
  @override
  final Token? keyword;

  @generated
  TypeAnnotationImpl? _type;

  @override
  BindPatternVariableFragmentImpl? declaredFragment;

  @generated
  DeclaredVariablePatternImpl({
    required this.keyword,
    required TypeAnnotationImpl? type,
    required super.name,
  }) : _type = type {
    _becomeParentOf(type);
  }

  @generated
  @override
  Token get beginToken {
    if (keyword case var keyword?) {
      return keyword;
    }
    if (type case var type?) {
      return type.beginToken;
    }
    return name;
  }

  @Deprecated('Use declaredFragment instead')
  @override
  BindPatternVariableElementImpl? get declaredElement {
    return declaredFragment?.element;
  }

  @Deprecated('Use declaredFragment instead')
  @override
  BindPatternVariableElementImpl? get declaredElement2 {
    return declaredElement;
  }

  @generated
  @override
  Token get endToken {
    return name;
  }

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

  @generated
  @override
  TypeAnnotationImpl? get type => _type;

  @generated
  set type(TypeAnnotationImpl? type) {
    _type = _becomeParentOf(type);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('keyword', keyword)
    ..addNode('type', type)
    ..addToken('name', name);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitDeclaredVariablePattern(this);

  @override
  TypeImpl computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor
        .analyzeDeclaredVariablePatternSchema(
          type?.typeOrThrow.wrapSharedTypeView(),
        )
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    inferenceLogWriter?.enterPattern(this);
    var declaredElement = declaredFragment!.element;
    var result = resolverVisitor.analyzeDeclaredVariablePattern(
      context,
      this,
      declaredElement,
      declaredElement.name ?? '',
      type?.typeOrThrow.wrapSharedTypeView(),
    );
    declaredElement.type = result.staticType.unwrapTypeView();

    resolverVisitor.checkPatternNeverMatchesValueType(
      context: context,
      pattern: this,
      requiredType: result.staticType.unwrapTypeView(),
      matchedValueType: result.matchedValueType.unwrapTypeView(),
    );
    inferenceLogWriter?.exitPattern(this);

    return result;
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    type?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (type case var type?) {
      if (type._containsOffset(rangeOffset, rangeEnd)) {
        return type;
      }
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('parameter'),
    GenerateNodeProperty('separator'),
    GenerateNodeProperty('defaultValue'),
    GenerateNodeProperty('kind', type: ParameterKind),
  ],
)
final class DefaultFormalParameterImpl extends FormalParameterImpl
    implements DefaultFormalParameter {
  @generated
  NormalFormalParameterImpl _parameter;

  @generated
  @override
  final Token? separator;

  @generated
  ExpressionImpl? _defaultValue;

  @generated
  @override
  final ParameterKind kind;

  @generated
  DefaultFormalParameterImpl({
    required NormalFormalParameterImpl parameter,
    required this.separator,
    required ExpressionImpl? defaultValue,
    required this.kind,
  }) : _parameter = parameter,
       _defaultValue = defaultValue {
    _becomeParentOf(parameter);
    _becomeParentOf(defaultValue);
  }

  @generated
  @override
  Token get beginToken {
    return parameter.beginToken;
  }

  @override
  Token? get covariantKeyword => null;

  @override
  FormalParameterFragmentImpl? get declaredFragment =>
      _parameter.declaredFragment;

  @generated
  @override
  ExpressionImpl? get defaultValue => _defaultValue;

  @generated
  set defaultValue(ExpressionImpl? defaultValue) {
    _defaultValue = _becomeParentOf(defaultValue);
  }

  @generated
  @override
  Token get endToken {
    if (defaultValue case var defaultValue?) {
      return defaultValue.endToken;
    }
    if (separator case var separator?) {
      return separator;
    }
    return parameter.endToken;
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

  @generated
  @override
  NormalFormalParameterImpl get parameter => _parameter;

  @generated
  set parameter(NormalFormalParameterImpl parameter) {
    _parameter = _becomeParentOf(parameter);
  }

  @override
  Token? get requiredKeyword => null;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('parameter', parameter)
    ..addToken('separator', separator)
    ..addNode('defaultValue', defaultValue);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitDefaultFormalParameter(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    parameter.accept(visitor);
    defaultValue?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (parameter._containsOffset(rangeOffset, rangeEnd)) {
      return parameter;
    }
    if (defaultValue case var defaultValue?) {
      if (defaultValue._containsOffset(rangeOffset, rangeEnd)) {
        return defaultValue;
      }
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
sealed class Directive implements AnnotatedNode {}

sealed class DirectiveImpl extends AnnotatedNodeImpl implements Directive {
  /// Initializes a newly create directive.
  ///
  /// Either or both of the [comment] and [metadata] can be `null` if the
  /// directive doesn't have the corresponding attribute.
  DirectiveImpl({required super.comment, required super.metadata});
}

/// Works together with [GenerateNodeImpl], annotated constructors and methods
/// will not be generated.
class DoNotGenerate {
  final String reason;

  const DoNotGenerate({required this.reason});
}

/// A do statement.
///
///    doStatement ::=
///        'do' [Statement] 'while' '(' [Expression] ')' ';'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('doKeyword'),
    GenerateNodeProperty('body'),
    GenerateNodeProperty('whileKeyword'),
    GenerateNodeProperty('leftParenthesis'),
    GenerateNodeProperty('condition'),
    GenerateNodeProperty('rightParenthesis'),
    GenerateNodeProperty('semicolon'),
  ],
)
final class DoStatementImpl extends StatementImpl implements DoStatement {
  @generated
  @override
  final Token doKeyword;

  @generated
  StatementImpl _body;

  @generated
  @override
  final Token whileKeyword;

  @generated
  @override
  final Token leftParenthesis;

  @generated
  ExpressionImpl _condition;

  @generated
  @override
  final Token rightParenthesis;

  @generated
  @override
  final Token semicolon;

  @generated
  DoStatementImpl({
    required this.doKeyword,
    required StatementImpl body,
    required this.whileKeyword,
    required this.leftParenthesis,
    required ExpressionImpl condition,
    required this.rightParenthesis,
    required this.semicolon,
  }) : _body = body,
       _condition = condition {
    _becomeParentOf(body);
    _becomeParentOf(condition);
  }

  @generated
  @override
  Token get beginToken {
    return doKeyword;
  }

  @generated
  @override
  StatementImpl get body => _body;

  @generated
  set body(StatementImpl body) {
    _body = _becomeParentOf(body);
  }

  @generated
  @override
  ExpressionImpl get condition => _condition;

  @generated
  set condition(ExpressionImpl condition) {
    _condition = _becomeParentOf(condition);
  }

  @generated
  @override
  Token get endToken {
    return semicolon;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('doKeyword', doKeyword)
    ..addNode('body', body)
    ..addToken('whileKeyword', whileKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('condition', condition)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitDoStatement(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    body.accept(visitor);
    condition.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (body._containsOffset(rangeOffset, rangeEnd)) {
      return body;
    }
    if (condition._containsOffset(rangeOffset, rangeEnd)) {
      return condition;
    }
    return null;
  }
}

/// A node that represents a dot shorthand constructor invocation.
///
/// For example, `.fromCharCode(42)`.
///
///    dotShorthandHead ::=
///        '.' [SimpleIdentifier] [TypeArgumentList]? [ArgumentList]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class DotShorthandConstructorInvocation
    extends InvocationExpression
    implements ConstructorReferenceNode {
  /// The `const` keyword, or `null` if the expression isn't preceded by the
  /// keyword `const`.
  Token? get constKeyword;

  /// The name of the constructor invocation.
  SimpleIdentifier get constructorName;

  /// Whether this dot shorthand constructor invocation will be evaluated at
  /// compile-time, either because the keyword `const` was explicitly provided
  /// or because no keyword was provided and this expression is in a constant
  /// context.
  bool get isConst;

  /// The token representing the period.
  Token get period;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('constKeyword', isTokenFinal: false),
    GenerateNodeProperty('period'),
    GenerateNodeProperty('constructorName'),
    GenerateNodeProperty('typeArguments', isSuper: true),
    GenerateNodeProperty('argumentList', isSuper: true),
  ],
)
final class DotShorthandConstructorInvocationImpl
    extends InvocationExpressionImpl
    with DotShorthandMixin
    implements
        RewrittenMethodInvocationImpl,
        DotShorthandConstructorInvocation {
  @generated
  @override
  Token? constKeyword;

  @generated
  @override
  final Token period;

  @generated
  SimpleIdentifierImpl _constructorName;

  @override
  ConstructorElementImpl? element;

  @generated
  DotShorthandConstructorInvocationImpl({
    required this.constKeyword,
    required this.period,
    required SimpleIdentifierImpl constructorName,
    required super.typeArguments,
    required super.argumentList,
  }) : _constructorName = constructorName {
    _becomeParentOf(constructorName);
  }

  @generated
  @override
  Token get beginToken {
    if (constKeyword case var constKeyword?) {
      return constKeyword;
    }
    return period;
  }

  @override
  bool get canBeConst {
    var element = constructorName.element;
    if (element is! InternalConstructorElement) return false;
    if (!element.isConst) return false;

    // Ensure that dependencies (e.g. default parameter values) are computed.
    element.baseElement.computeConstantDependencies();

    // Verify that the evaluation of the constructor would not produce an
    // exception.
    var oldKeyword = constKeyword;
    try {
      constKeyword = KeywordToken(Keyword.CONST, offset);
      return !hasConstantVerifierError;
    } finally {
      constKeyword = oldKeyword;
    }
  }

  @generated
  @override
  SimpleIdentifierImpl get constructorName => _constructorName;

  @generated
  set constructorName(SimpleIdentifierImpl constructorName) {
    _constructorName = _becomeParentOf(constructorName);
  }

  @generated
  @override
  Token get endToken {
    return argumentList.endToken;
  }

  @override
  ExpressionImpl get function => constructorName;

  @override
  bool get isConst {
    return constKeyword?.keyword == Keyword.CONST || inConstantContext;
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('constKeyword', constKeyword)
    ..addToken('period', period)
    ..addNode('constructorName', constructorName)
    ..addNode('typeArguments', typeArguments)
    ..addNode('argumentList', argumentList);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitDotShorthandConstructorInvocation(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitDotShorthandConstructorInvocation(
      this,
      contextType: contextType,
    );
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    constructorName.accept(visitor);
    typeArguments?.accept(visitor);
    argumentList.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (constructorName._containsOffset(rangeOffset, rangeEnd)) {
      return constructorName;
    }
    if (typeArguments case var typeArguments?) {
      if (typeArguments._containsOffset(rangeOffset, rangeEnd)) {
        return typeArguments;
      }
    }
    if (argumentList._containsOffset(rangeOffset, rangeEnd)) {
      return argumentList;
    }
    return null;
  }
}

/// A node that represents a dot shorthand static method or constructor
/// invocation.
///
/// For example, `.parse('42')`.
///
///    dotShorthandHead ::=
///        '.' [SimpleIdentifier] [TypeArgumentList]? [ArgumentList]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class DotShorthandInvocation extends InvocationExpression {
  /// The name of the constructor or static method invocation.
  SimpleIdentifier get memberName;

  /// The token representing the period.
  Token get period;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('period'),
    GenerateNodeProperty('memberName'),
    GenerateNodeProperty('typeArguments', isSuper: true),
    GenerateNodeProperty('argumentList', isSuper: true),
  ],
)
final class DotShorthandInvocationImpl extends InvocationExpressionImpl
    with DotShorthandMixin
    implements DotShorthandInvocation {
  @generated
  @override
  final Token period;

  @generated
  SimpleIdentifierImpl _memberName;

  @generated
  DotShorthandInvocationImpl({
    required this.period,
    required SimpleIdentifierImpl memberName,
    required super.typeArguments,
    required super.argumentList,
  }) : _memberName = memberName {
    _becomeParentOf(memberName);
  }

  @generated
  @override
  Token get beginToken {
    return period;
  }

  @generated
  @override
  Token get endToken {
    return argumentList.endToken;
  }

  @override
  ExpressionImpl get function => memberName;

  @generated
  @override
  SimpleIdentifierImpl get memberName => _memberName;

  @generated
  set memberName(SimpleIdentifierImpl memberName) {
    _memberName = _becomeParentOf(memberName);
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('period', period)
    ..addNode('memberName', memberName)
    ..addNode('typeArguments', typeArguments)
    ..addNode('argumentList', argumentList);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitDotShorthandInvocation(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitDotShorthandInvocation(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    memberName.accept(visitor);
    typeArguments?.accept(visitor);
    argumentList.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (memberName._containsOffset(rangeOffset, rangeEnd)) {
      return memberName;
    }
    if (typeArguments case var typeArguments?) {
      if (typeArguments._containsOffset(rangeOffset, rangeEnd)) {
        return typeArguments;
      }
    }
    if (argumentList._containsOffset(rangeOffset, rangeEnd)) {
      return argumentList;
    }
    return null;
  }
}

base mixin DotShorthandMixin on ExpressionImpl {
  /// Whether the AST node is a dot shorthand and has a dot shorthand head
  /// ([DotShorthandInvocation], [DotShorthandConstructorInvocation] or
  /// [DotShorthandPropertyAccess]) as its
  /// inner-most target.
  ///
  /// This is `false` and remains `false` when there is no dot shorthand head as
  /// its inner-most target. When we are parsing and notice that we have a dot
  /// shorthand head, we flip this flag to `true` and it remains `true` for that
  /// expression.
  ///
  /// We use this flag to determine the correct context type to cache. This
  /// cached context type is then used to resolve the dot shorthand head.
  bool isDotShorthand = false;
}

/// A node that represents a dot shorthand property access of a field or a
/// static getter.
///
/// For example, `.zero`.
///
///    dotShorthandHead ::= '.' [SimpleIdentifier]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class DotShorthandPropertyAccess extends Expression {
  /// The token representing the period.
  Token get period;

  /// The name of the property being accessed.
  SimpleIdentifier get propertyName;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('period'),
    GenerateNodeProperty('propertyName'),
  ],
)
final class DotShorthandPropertyAccessImpl extends ExpressionImpl
    with DotShorthandMixin
    implements DotShorthandPropertyAccess {
  @generated
  @override
  final Token period;

  @generated
  SimpleIdentifierImpl _propertyName;

  @generated
  DotShorthandPropertyAccessImpl({
    required this.period,
    required SimpleIdentifierImpl propertyName,
  }) : _propertyName = propertyName {
    _becomeParentOf(propertyName);
  }

  @generated
  @override
  Token get beginToken {
    return period;
  }

  @generated
  @override
  Token get endToken {
    return propertyName.endToken;
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @generated
  @override
  SimpleIdentifierImpl get propertyName => _propertyName;

  @generated
  set propertyName(SimpleIdentifierImpl propertyName) {
    _propertyName = _becomeParentOf(propertyName);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('period', period)
    ..addNode('propertyName', propertyName);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitDotShorthandPropertyAccess(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitDotShorthandPropertyAccess(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    propertyName.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (propertyName._containsOffset(rangeOffset, rangeEnd)) {
      return propertyName;
    }
    return null;
  }
}

/// A dotted name, used in a configuration within an import or export directive.
///
///    dottedName ::=
///        [SimpleIdentifier] ('.' [SimpleIdentifier])*
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class DottedName implements AstNode {
  /// The components of the identifier.
  NodeList<SimpleIdentifier> get components;
}

@GenerateNodeImpl(childEntitiesOrder: [GenerateNodeProperty('components')])
final class DottedNameImpl extends AstNodeImpl implements DottedName {
  @generated
  @override
  final NodeListImpl<SimpleIdentifierImpl> components = NodeListImpl._();

  @generated
  DottedNameImpl({required List<SimpleIdentifierImpl> components}) {
    this.components._initialize(this, components);
  }

  @generated
  @override
  Token get beginToken {
    if (components.beginToken case var result?) {
      return result;
    }
    throw StateError('Expected at least one non-null');
  }

  @generated
  @override
  Token get endToken {
    if (components.endToken case var result?) {
      return result;
    }
    throw StateError('Expected at least one non-null');
  }

  @generated
  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addNodeList('components', components);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitDottedName(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    components.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (components._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class DoubleLiteral implements Literal {
  /// The token representing the literal.
  Token get literal;

  /// The value of the literal.
  double get value;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('literal'),
    GenerateNodeProperty('value'),
  ],
)
final class DoubleLiteralImpl extends LiteralImpl implements DoubleLiteral {
  @generated
  @override
  final Token literal;

  @generated
  @override
  final double value;

  @generated
  DoubleLiteralImpl({required this.literal, required this.value});

  @generated
  @override
  Token get beginToken {
    return literal;
  }

  @generated
  @override
  Token get endToken {
    return literal;
  }

  @generated
  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('literal', literal);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitDoubleLiteral(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitDoubleLiteral(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {}

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    return null;
  }
}

/// An empty function body.
///
/// An empty function body can only appear in constructors or abstract methods.
///
///    emptyFunctionBody ::=
///        ';'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class EmptyFunctionBody implements FunctionBody {
  /// The token representing the semicolon that marks the end of the function
  /// body.
  Token get semicolon;
}

@GenerateNodeImpl(childEntitiesOrder: [GenerateNodeProperty('semicolon')])
final class EmptyFunctionBodyImpl extends FunctionBodyImpl
    implements EmptyFunctionBody {
  @generated
  @override
  final Token semicolon;

  @generated
  EmptyFunctionBodyImpl({required this.semicolon});

  @generated
  @override
  Token get beginToken {
    return semicolon;
  }

  @generated
  @override
  Token get endToken {
    return semicolon;
  }

  @generated
  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitEmptyFunctionBody(this);

  @override
  TypeImpl resolve(ResolverVisitor resolver, TypeImpl? imposedType) =>
      resolver.visitEmptyFunctionBody(this, imposedType: imposedType);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {}

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    return null;
  }
}

/// An empty statement.
///
///    emptyStatement ::=
///        ';'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class EmptyStatement implements Statement {
  /// The semicolon terminating the statement.
  Token get semicolon;
}

@GenerateNodeImpl(childEntitiesOrder: [GenerateNodeProperty('semicolon')])
final class EmptyStatementImpl extends StatementImpl implements EmptyStatement {
  @generated
  @override
  final Token semicolon;

  @generated
  EmptyStatementImpl({required this.semicolon});

  @generated
  @override
  Token get beginToken {
    return semicolon;
  }

  @generated
  @override
  Token get endToken {
    return semicolon;
  }

  @override
  bool get isSynthetic => semicolon.isSynthetic;

  @generated
  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitEmptyStatement(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {}

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    return null;
  }
}

/// The arguments part of an enum constant.
///
///    enumConstantArguments ::=
///        [TypeArgumentList]? [ConstructorSelector]? [ArgumentList]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('typeArguments'),
    GenerateNodeProperty('constructorSelector'),
    GenerateNodeProperty('argumentList'),
  ],
)
final class EnumConstantArgumentsImpl extends AstNodeImpl
    implements EnumConstantArguments {
  @generated
  TypeArgumentListImpl? _typeArguments;

  @generated
  ConstructorSelectorImpl? _constructorSelector;

  @generated
  ArgumentListImpl _argumentList;

  @generated
  EnumConstantArgumentsImpl({
    required TypeArgumentListImpl? typeArguments,
    required ConstructorSelectorImpl? constructorSelector,
    required ArgumentListImpl argumentList,
  }) : _typeArguments = typeArguments,
       _constructorSelector = constructorSelector,
       _argumentList = argumentList {
    _becomeParentOf(typeArguments);
    _becomeParentOf(constructorSelector);
    _becomeParentOf(argumentList);
  }

  @generated
  @override
  ArgumentListImpl get argumentList => _argumentList;

  @generated
  set argumentList(ArgumentListImpl argumentList) {
    _argumentList = _becomeParentOf(argumentList);
  }

  @generated
  @override
  Token get beginToken {
    if (typeArguments case var typeArguments?) {
      return typeArguments.beginToken;
    }
    if (constructorSelector case var constructorSelector?) {
      return constructorSelector.beginToken;
    }
    return argumentList.beginToken;
  }

  @generated
  @override
  ConstructorSelectorImpl? get constructorSelector => _constructorSelector;

  @generated
  set constructorSelector(ConstructorSelectorImpl? constructorSelector) {
    _constructorSelector = _becomeParentOf(constructorSelector);
  }

  @generated
  @override
  Token get endToken {
    return argumentList.endToken;
  }

  @generated
  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  @generated
  set typeArguments(TypeArgumentListImpl? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('typeArguments', typeArguments)
    ..addNode('constructorSelector', constructorSelector)
    ..addNode('argumentList', argumentList);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitEnumConstantArguments(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    typeArguments?.accept(visitor);
    constructorSelector?.accept(visitor);
    argumentList.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (typeArguments case var typeArguments?) {
      if (typeArguments._containsOffset(rangeOffset, rangeEnd)) {
        return typeArguments;
      }
    }
    if (constructorSelector case var constructorSelector?) {
      if (constructorSelector._containsOffset(rangeOffset, rangeEnd)) {
        return constructorSelector;
      }
    }
    if (argumentList._containsOffset(rangeOffset, rangeEnd)) {
      return argumentList;
    }
    return null;
  }
}

/// The declaration of an enum constant.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class EnumConstantDeclaration implements Declaration {
  /// The explicit arguments (there are always implicit `index` and `name`
  /// leading arguments) to the invoked constructor, or `null` if this constant
  /// doesn't provide any explicit arguments.
  EnumConstantArguments? get arguments;

  /// The `augment` keyword, or `null` if the keyword was absent.
  Token? get augmentKeyword;

  /// The constructor that's invoked by this enum constant.
  ///
  /// Returns `null` if the AST structure hasn't been resolved, or if the
  /// constructor couldn't be resolved.
  ConstructorElement? get constructorElement;

  /// The constructor that's invoked by this enum constant.
  ///
  /// Returns `null` if the AST structure hasn't been resolved, or if the
  /// constructor couldn't be resolved.
  @Deprecated('Use constructorElement instead')
  ConstructorElement? get constructorElement2;

  @override
  FieldFragment? get declaredFragment;

  /// The name of the constant.
  Token get name;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('augmentKeyword'),
    GenerateNodeProperty('name'),
    GenerateNodeProperty('arguments'),
  ],
)
final class EnumConstantDeclarationImpl extends DeclarationImpl
    implements EnumConstantDeclaration {
  @generated
  @override
  final Token? augmentKeyword;

  @generated
  @override
  final Token name;

  @generated
  EnumConstantArgumentsImpl? _arguments;

  @override
  FieldFragmentImpl? declaredFragment;

  @override
  InternalConstructorElement? constructorElement;

  @generated
  EnumConstantDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
    required this.name,
    required EnumConstantArgumentsImpl? arguments,
  }) : _arguments = arguments {
    _becomeParentOf(arguments);
  }

  @generated
  @override
  EnumConstantArgumentsImpl? get arguments => _arguments;

  @generated
  set arguments(EnumConstantArgumentsImpl? arguments) {
    _arguments = _becomeParentOf(arguments);
  }

  @Deprecated('Use constructorElement instead')
  @override
  InternalConstructorElement? get constructorElement2 => constructorElement;

  @generated
  @override
  Token get endToken {
    if (arguments case var arguments?) {
      return arguments.endToken;
    }
    return name;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (augmentKeyword case var augmentKeyword?) {
      return augmentKeyword;
    }
    return name;
  }

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('augmentKeyword', augmentKeyword)
    ..addToken('name', name)
    ..addNode('arguments', arguments);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitEnumConstantDeclaration(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    arguments?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (arguments case var arguments?) {
      if (arguments._containsOffset(rangeOffset, rangeEnd)) {
        return arguments;
      }
    }
    return null;
  }
}

/// The declaration of an enumeration.
///
///    enumType ::=
///        metadata 'enum' name [TypeParameterList]?
///        [WithClause]? [ImplementsClause]? '{' [SimpleIdentifier]
///        (',' [SimpleIdentifier])* (';' [ClassMember]+)? '}'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class EnumDeclaration implements NamedCompilationUnitMember {
  /// The `augment` keyword, or `null` if the keyword was absent.
  Token? get augmentKeyword;

  /// The enumeration constants being declared.
  NodeList<EnumConstantDeclaration> get constants;

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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('augmentKeyword'),
    GenerateNodeProperty('enumKeyword'),
    GenerateNodeProperty('name', isSuper: true),
    GenerateNodeProperty('typeParameters'),
    GenerateNodeProperty('withClause'),
    GenerateNodeProperty('implementsClause'),
    GenerateNodeProperty('leftBracket'),
    GenerateNodeProperty('constants'),
    GenerateNodeProperty('semicolon'),
    GenerateNodeProperty('members'),
    GenerateNodeProperty('rightBracket'),
  ],
)
final class EnumDeclarationImpl extends NamedCompilationUnitMemberImpl
    with AstNodeWithNameScopeMixin
    implements EnumDeclaration {
  @generated
  @override
  final Token? augmentKeyword;

  @generated
  @override
  final Token enumKeyword;

  @generated
  TypeParameterListImpl? _typeParameters;

  @generated
  WithClauseImpl? _withClause;

  @generated
  ImplementsClauseImpl? _implementsClause;

  @generated
  @override
  final Token leftBracket;

  @generated
  @override
  final NodeListImpl<EnumConstantDeclarationImpl> constants = NodeListImpl._();

  @generated
  @override
  final Token? semicolon;

  @generated
  @override
  final NodeListImpl<ClassMemberImpl> members = NodeListImpl._();

  @generated
  @override
  final Token rightBracket;

  @override
  EnumFragmentImpl? declaredFragment;

  @generated
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
  }) : _typeParameters = typeParameters,
       _withClause = withClause,
       _implementsClause = implementsClause {
    _becomeParentOf(typeParameters);
    _becomeParentOf(withClause);
    _becomeParentOf(implementsClause);
    this.constants._initialize(this, constants);
    this.members._initialize(this, members);
  }

  @generated
  @override
  Token get endToken {
    return rightBracket;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (augmentKeyword case var augmentKeyword?) {
      return augmentKeyword;
    }
    return enumKeyword;
  }

  @generated
  @override
  ImplementsClauseImpl? get implementsClause => _implementsClause;

  @generated
  set implementsClause(ImplementsClauseImpl? implementsClause) {
    _implementsClause = _becomeParentOf(implementsClause);
  }

  @generated
  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  @generated
  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @generated
  @override
  WithClauseImpl? get withClause => _withClause;

  @generated
  set withClause(WithClauseImpl? withClause) {
    _withClause = _becomeParentOf(withClause);
  }

  @generated
  @override
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

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitEnumDeclaration(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    typeParameters?.accept(visitor);
    withClause?.accept(visitor);
    implementsClause?.accept(visitor);
    constants.accept(visitor);
    members.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (typeParameters case var typeParameters?) {
      if (typeParameters._containsOffset(rangeOffset, rangeEnd)) {
        return typeParameters;
      }
    }
    if (withClause case var withClause?) {
      if (withClause._containsOffset(rangeOffset, rangeEnd)) {
        return withClause;
      }
    }
    if (implementsClause case var implementsClause?) {
      if (implementsClause._containsOffset(rangeOffset, rangeEnd)) {
        return implementsClause;
      }
    }
    if (constants._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    if (members._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// An export directive.
///
///    exportDirective ::=
///        [Annotation] 'export' [StringLiteral] [Combinator]* ';'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ExportDirective implements NamespaceDirective {
  /// The token representing the `export` keyword.
  Token get exportKeyword;

  /// Information about this export directive.
  ///
  /// Returns `null` if the AST structure hasn't been resolved.
  LibraryExport? get libraryExport;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('exportKeyword'),
    GenerateNodeProperty('uri', isSuper: true),
    GenerateNodeProperty('configurations', isSuper: true),
    GenerateNodeProperty('combinators', isSuper: true),
    GenerateNodeProperty('semicolon', isSuper: true),
  ],
)
final class ExportDirectiveImpl extends NamespaceDirectiveImpl
    implements ExportDirective {
  @generated
  @override
  final Token exportKeyword;

  @override
  LibraryExportImpl? libraryExport;

  @generated
  ExportDirectiveImpl({
    required super.comment,
    required super.metadata,
    required this.exportKeyword,
    required super.uri,
    required super.configurations,
    required super.combinators,
    required super.semicolon,
  });

  @generated
  @override
  Token get endToken {
    return semicolon;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    return exportKeyword;
  }

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('exportKeyword', exportKeyword)
    ..addNode('uri', uri)
    ..addNodeList('configurations', configurations)
    ..addNodeList('combinators', combinators)
    ..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitExportDirective(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    uri.accept(visitor);
    configurations.accept(visitor);
    combinators.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (uri._containsOffset(rangeOffset, rangeEnd)) {
      return uri;
    }
    if (configurations._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    if (combinators._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// A node that represents an expression.
///
///    expression ::=
///        [AssignmentExpression]
///      | [ConditionalExpression] cascadeSection*
///      | [ThrowExpression]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class Expression implements CollectionElement {
  /// Whether it would be valid for this expression to have a `const` keyword.
  ///
  /// Note that this method can cause constant evaluation to occur, which can be
  /// computationally expensive.
  bool get canBeConst;

  /// The parameter element representing the parameter to which the value of
  /// this expression is bound.
  ///
  /// Returns `null` if any of these conditions are false:
  /// - this expression is an argument to an invocation
  /// - the AST structure has been resolved
  /// - the function being invoked is known based on static type information
  /// - this expression corresponds to one of the parameters of the function
  ///   being invoked
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

  /// The static type of this expression, or `null` if the AST structure hasn't
  /// been resolved.
  DartType? get staticType;

  /// If this expression is a parenthesized expression, returns the result of
  /// unwrapping the expression inside the parentheses. Otherwise, returns this
  /// expression.
  Expression get unParenthesized;

  /// Computes the constant value of this expression, if it has one.
  ///
  /// Returns a [AttemptedConstantEvaluationResult], containing both the computed
  /// constant value, and a list of errors that occurred during the computation.
  ///
  /// Returns `null` if this expression is not a constant expression.
  AttemptedConstantEvaluationResult? computeConstantValue();
}

/// A function body consisting of a single expression.
///
///    expressionFunctionBody ::=
///        'async'? '=>' [Expression] ';'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('keyword'),
    GenerateNodeProperty('star'),
    GenerateNodeProperty('functionDefinition'),
    GenerateNodeProperty('expression'),
    GenerateNodeProperty('semicolon'),
  ],
)
final class ExpressionFunctionBodyImpl extends FunctionBodyImpl
    with AstNodeWithNameScopeMixin
    implements ExpressionFunctionBody {
  @generated
  @override
  final Token? keyword;

  @generated
  @override
  final Token? star;

  @generated
  @override
  final Token functionDefinition;

  @generated
  ExpressionImpl _expression;

  @generated
  @override
  final Token? semicolon;

  @generated
  ExpressionFunctionBodyImpl({
    required this.keyword,
    required this.star,
    required this.functionDefinition,
    required ExpressionImpl expression,
    required this.semicolon,
  }) : _expression = expression {
    _becomeParentOf(expression);
  }

  @generated
  @override
  Token get beginToken {
    if (keyword case var keyword?) {
      return keyword;
    }
    if (star case var star?) {
      return star;
    }
    return functionDefinition;
  }

  @generated
  @override
  Token get endToken {
    if (semicolon case var semicolon?) {
      return semicolon;
    }
    return expression.endToken;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  bool get isAsynchronous => keyword?.lexeme == Keyword.ASYNC.lexeme;

  @override
  bool get isGenerator => star != null;

  @override
  bool get isSynchronous => keyword?.lexeme != Keyword.ASYNC.lexeme;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('keyword', keyword)
    ..addToken('star', star)
    ..addToken('functionDefinition', functionDefinition)
    ..addNode('expression', expression)
    ..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitExpressionFunctionBody(this);

  @override
  TypeImpl resolve(ResolverVisitor resolver, TypeImpl? imposedType) =>
      resolver.visitExpressionFunctionBody(this, imposedType: imposedType);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    return null;
  }
}

sealed class ExpressionImpl extends CollectionElementImpl
    implements Expression {
  TypeImpl? _staticType;

  @override
  bool get canBeConst => false;

  @override
  InternalFormalParameterElement? get correspondingParameter {
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
        var parameters = parent.staticInvokeType?.formalParameters;
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
  bool get inConstantContext {
    return constantContext(includeSelf: false) != null;
  }

  @override
  bool get isAssignable => false;

  @override
  TypeImpl? get staticType => _staticType;

  @override
  ExpressionImpl get unParenthesized => this;

  @override
  AttemptedConstantEvaluationResult? computeConstantValue() {
    var unitNode = thisOrAncestorOfType<CompilationUnitImpl>();
    var unitFragment = unitNode?.declaredFragment;
    if (unitFragment == null) {
      throw ArgumentError('This AST structure has not yet been resolved.');
    }

    var libraryElement = unitFragment.element;
    var declaredVariables = libraryElement.session.declaredVariables;

    var evaluationEngine = ConstantEvaluationEngine(
      declaredVariables: declaredVariables,
      configuration: ConstantEvaluationConfiguration(),
    );

    var dependencies = <ConstantEvaluationTarget>[];
    accept(ReferenceFinder(dependencies.add));

    computeConstants(
      declaredVariables: declaredVariables,
      constants: dependencies,
      featureSet: libraryElement.featureSet,
      configuration: ConstantEvaluationConfiguration(),
    );

    var diagnosticListener = RecordingDiagnosticListener();
    var visitor = ConstantVisitor(
      evaluationEngine,
      libraryElement,
      DiagnosticReporter(diagnosticListener, unitFragment.source),
    );

    var constant = visitor.evaluateAndReportInvalidConstant(this);
    var isInvalidConstant = diagnosticListener.diagnostics.any(
      (e) => e.diagnosticCode == CompileTimeErrorCode.invalidConstant,
    );
    if (isInvalidConstant) {
      return null;
    }

    return AttemptedConstantEvaluationResult._(
      constant is DartObjectImpl ? constant : null,
      diagnosticListener.diagnostics,
    );
  }

  /// Returns the [AstNode] that puts node into the constant context, and
  /// the explicit `const` keyword of that node. The keyword might be absent
  /// if the constness is implicit.
  ///
  /// Returns `null` if node is not in the constant context.
  (AstNode, Token?)? constantContext({required bool includeSelf}) {
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
        case DotShorthandConstructorInvocation():
          if (current.constKeyword case var constKeyword?) {
            return (current, constKeyword);
          }
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
        case ForElement():
        case IfElement():
        case InterpolationExpression():
        case MapLiteralEntry():
        case NullAwareElement():
        case SpreadElement():
        case VariableDeclaration():
          break;
        default:
          return null;
      }
      current = current?.parent;
    }
  }

  /// Called when null shorting terminates, and so the type of an expression
  /// needs to be made nullable.
  ///
  /// [type] is the new static type of the expression.
  void recordNullShortedType(TypeImpl type) {
    _staticType = type;
    inferenceLogWriter?.recordNullShortedType(this, type);
  }

  /// Record that the static type of the given node is the given type.
  ///
  /// @param expression the node whose type is to be recorded
  /// @param type the static type of the node
  void recordStaticType(DartType type, {required ResolverVisitor resolver}) {
    // TODO(paulberry): remove this cast by changing the type of the parameter
    // `type`.
    _staticType = type as TypeImpl;
    if (type.isBottom) {
      resolver.flowAnalysis.flow?.handleExit();
    }
    inferenceLogWriter?.recordStaticType(this, type);
  }

  @override
  void resolveElement(
    ResolverVisitor resolver,
    CollectionLiteralContext? context,
  ) {
    resolver.analyzeExpression(
      this,
      SharedTypeSchemaView(
        context?.elementType ?? UnknownInferredType.instance,
      ),
    );
  }

  /// Dispatches this expression to the [resolver], with the given [contextType]
  /// information.
  ///
  /// Note: most code shouldn't call this method directly, but should instead
  /// call [ResolverVisitor.dispatchExpression], which has some special logic
  /// for handling dynamic contexts.
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType);

  /// Records that the static type of `this` is [type], without triggering any
  /// [ResolverVisitor] behaviors.
  ///
  /// This is used when the expression AST node occurs in a place where it is
  /// not technically a true expression, but the analyzer chooses to assign it a
  /// static type anyway (e.g. the [SimpleIdentifier] representing the method
  /// name in a method invocation).
  void setPseudoExpressionStaticType(DartType? type) {
    // TODO(paulberry): remove this cast by changing the type of the parameter
    // `type`.
    _staticType = type as TypeImpl?;
  }
}

/// An expression used as a statement.
///
///    expressionStatement ::=
///        [Expression]? ';'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ExpressionStatement implements Statement {
  /// The expression that comprises the statement.
  Expression get expression;

  /// The semicolon terminating the statement, or `null` if the expression is a
  /// function expression and therefore isn't followed by a semicolon.
  Token? get semicolon;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('expression'),
    GenerateNodeProperty('semicolon'),
  ],
)
final class ExpressionStatementImpl extends StatementImpl
    implements ExpressionStatement {
  @generated
  ExpressionImpl _expression;

  @generated
  @override
  final Token? semicolon;

  @generated
  ExpressionStatementImpl({
    required ExpressionImpl expression,
    required this.semicolon,
  }) : _expression = expression {
    _becomeParentOf(expression);
  }

  @generated
  @override
  Token get beginToken {
    return expression.beginToken;
  }

  @generated
  @override
  Token get endToken {
    if (semicolon case var semicolon?) {
      return semicolon;
    }
    return expression.endToken;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  bool get isSynthetic =>
      _expression.isSynthetic && (semicolon == null || semicolon!.isSynthetic);

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('expression', expression)
    ..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitExpressionStatement(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    return null;
  }
}

/// The "extends" clause in a class declaration.
///
///    extendsClause ::=
///        'extends' [NamedType]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ExtendsClause implements AstNode {
  /// The token representing the `extends` keyword.
  Token get extendsKeyword;

  /// The name of the class that is being extended.
  NamedType get superclass;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('extendsKeyword'),
    GenerateNodeProperty('superclass'),
  ],
)
final class ExtendsClauseImpl extends AstNodeImpl implements ExtendsClause {
  @generated
  @override
  final Token extendsKeyword;

  @generated
  NamedTypeImpl _superclass;

  @generated
  ExtendsClauseImpl({
    required this.extendsKeyword,
    required NamedTypeImpl superclass,
  }) : _superclass = superclass {
    _becomeParentOf(superclass);
  }

  @generated
  @override
  Token get beginToken {
    return extendsKeyword;
  }

  @generated
  @override
  Token get endToken {
    return superclass.endToken;
  }

  @generated
  @override
  NamedTypeImpl get superclass => _superclass;

  @generated
  set superclass(NamedTypeImpl superclass) {
    _superclass = _becomeParentOf(superclass);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('extendsKeyword', extendsKeyword)
    ..addNode('superclass', superclass);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitExtendsClause(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    superclass.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (superclass._containsOffset(rangeOffset, rangeEnd)) {
      return superclass;
    }
    return null;
  }
}

/// The declaration of an extension of a type.
///
///    extension ::=
///        'extension' [SimpleIdentifier]? [TypeParameterList]?
///        'on' [TypeAnnotation] [ShowClause]? [HideClause]?
///        '{' [ClassMember]* '}'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ExtensionDeclaration implements CompilationUnitMember {
  /// The `augment` keyword, or `null` if the keyword was absent.
  Token? get augmentKeyword;

  @override
  ExtensionFragment? get declaredFragment;

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

  /// The right curly bracket.
  Token get rightBracket;

  /// The token representing the `type` keyword.
  Token? get typeKeyword;

  /// The type parameters for the extension, or `null` if the extension doesn't
  /// have any type parameters.
  TypeParameterList? get typeParameters;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('augmentKeyword'),
    GenerateNodeProperty('extensionKeyword'),
    GenerateNodeProperty('typeKeyword'),
    GenerateNodeProperty('name'),
    GenerateNodeProperty('typeParameters'),
    GenerateNodeProperty('onClause'),
    GenerateNodeProperty('leftBracket'),
    GenerateNodeProperty('members'),
    GenerateNodeProperty('rightBracket'),
  ],
)
final class ExtensionDeclarationImpl extends CompilationUnitMemberImpl
    with AstNodeWithNameScopeMixin
    implements ExtensionDeclaration {
  @generated
  @override
  final Token? augmentKeyword;

  @generated
  @override
  final Token extensionKeyword;

  @generated
  @override
  final Token? typeKeyword;

  @generated
  @override
  final Token? name;

  @generated
  TypeParameterListImpl? _typeParameters;

  @generated
  ExtensionOnClauseImpl? _onClause;

  @generated
  @override
  final Token leftBracket;

  @generated
  @override
  final NodeListImpl<ClassMemberImpl> members = NodeListImpl._();

  @generated
  @override
  final Token rightBracket;

  @override
  ExtensionFragmentImpl? declaredFragment;

  @generated
  ExtensionDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
    required this.extensionKeyword,
    required this.typeKeyword,
    required this.name,
    required TypeParameterListImpl? typeParameters,
    required ExtensionOnClauseImpl? onClause,
    required this.leftBracket,
    required List<ClassMemberImpl> members,
    required this.rightBracket,
  }) : _typeParameters = typeParameters,
       _onClause = onClause {
    _becomeParentOf(typeParameters);
    _becomeParentOf(onClause);
    this.members._initialize(this, members);
  }

  @generated
  @override
  Token get endToken {
    return rightBracket;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (augmentKeyword case var augmentKeyword?) {
      return augmentKeyword;
    }
    return extensionKeyword;
  }

  @generated
  @override
  ExtensionOnClauseImpl? get onClause => _onClause;

  @generated
  set onClause(ExtensionOnClauseImpl? onClause) {
    _onClause = _becomeParentOf(onClause);
  }

  @generated
  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  @generated
  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('augmentKeyword', augmentKeyword)
    ..addToken('extensionKeyword', extensionKeyword)
    ..addToken('typeKeyword', typeKeyword)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addNode('onClause', onClause)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('members', members)
    ..addToken('rightBracket', rightBracket);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitExtensionDeclaration(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    typeParameters?.accept(visitor);
    onClause?.accept(visitor);
    members.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (typeParameters case var typeParameters?) {
      if (typeParameters._containsOffset(rangeOffset, rangeEnd)) {
        return typeParameters;
      }
    }
    if (onClause case var onClause?) {
      if (onClause._containsOffset(rangeOffset, rangeEnd)) {
        return onClause;
      }
    }
    if (members._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// The `on` clause in an extension declaration.
///
///    onClause ::= 'on' [TypeAnnotation]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ExtensionOnClause implements AstNode {
  /// The extended type.
  TypeAnnotation get extendedType;

  /// The 'on' keyword.
  Token get onKeyword;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('onKeyword'),
    GenerateNodeProperty('extendedType'),
  ],
)
final class ExtensionOnClauseImpl extends AstNodeImpl
    implements ExtensionOnClause {
  @generated
  @override
  final Token onKeyword;

  @generated
  TypeAnnotationImpl _extendedType;

  @generated
  ExtensionOnClauseImpl({
    required this.onKeyword,
    required TypeAnnotationImpl extendedType,
  }) : _extendedType = extendedType {
    _becomeParentOf(extendedType);
  }

  @generated
  @override
  Token get beginToken {
    return onKeyword;
  }

  @generated
  @override
  Token get endToken {
    return extendedType.endToken;
  }

  @generated
  @override
  TypeAnnotationImpl get extendedType => _extendedType;

  @generated
  set extendedType(TypeAnnotationImpl extendedType) {
    _extendedType = _becomeParentOf(extendedType);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('onKeyword', onKeyword)
    ..addNode('extendedType', extendedType);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitExtensionOnClause(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    extendedType.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (extendedType._containsOffset(rangeOffset, rangeEnd)) {
      return extendedType;
    }
    return null;
  }
}

/// An override to force resolution to choose a member from a specific
/// extension.
///
///    extensionOverride ::=
///        [Identifier] [TypeArgumentList]? [ArgumentList]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ExtensionOverride implements Expression {
  /// The list of arguments to the override.
  ///
  /// In valid code this contains a single argument that evaluates to the object
  /// being extended.
  ArgumentList get argumentList;

  /// The extension that resolution will use to resolve member references.
  ExtensionElement get element;

  /// The extension that resolution will use to resolve member references.
  @Deprecated('Use element instead')
  ExtensionElement get element2;

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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('importPrefix'),
    GenerateNodeProperty('name'),
    GenerateNodeProperty('typeArguments'),
    GenerateNodeProperty('argumentList'),
    GenerateNodeProperty('element', type: ExtensionElementImpl),
  ],
)
final class ExtensionOverrideImpl extends ExpressionImpl
    implements ExtensionOverride {
  @generated
  ImportPrefixReferenceImpl? _importPrefix;

  @generated
  @override
  final Token name;

  @generated
  TypeArgumentListImpl? _typeArguments;

  @generated
  ArgumentListImpl _argumentList;

  @generated
  @override
  final ExtensionElementImpl element;

  @override
  List<DartType>? typeArgumentTypes;

  @override
  TypeImpl? extendedType;

  @generated
  ExtensionOverrideImpl({
    required ImportPrefixReferenceImpl? importPrefix,
    required this.name,
    required TypeArgumentListImpl? typeArguments,
    required ArgumentListImpl argumentList,
    required this.element,
  }) : _importPrefix = importPrefix,
       _typeArguments = typeArguments,
       _argumentList = argumentList {
    _becomeParentOf(importPrefix);
    _becomeParentOf(typeArguments);
    _becomeParentOf(argumentList);
  }

  @generated
  @override
  ArgumentListImpl get argumentList => _argumentList;

  @generated
  set argumentList(ArgumentListImpl argumentList) {
    _argumentList = _becomeParentOf(argumentList);
  }

  @generated
  @override
  Token get beginToken {
    if (importPrefix case var importPrefix?) {
      return importPrefix.beginToken;
    }
    return name;
  }

  @Deprecated('Use element instead')
  @override
  ExtensionElementImpl get element2 => element;

  @generated
  @override
  Token get endToken {
    return argumentList.endToken;
  }

  @generated
  @override
  ImportPrefixReferenceImpl? get importPrefix => _importPrefix;

  @generated
  set importPrefix(ImportPrefixReferenceImpl? importPrefix) {
    _importPrefix = _becomeParentOf(importPrefix);
  }

  @override
  bool get isNullAware {
    var nextType = argumentList.endToken.next!.type;
    return nextType == TokenType.QUESTION_PERIOD ||
        nextType == TokenType.QUESTION;
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @generated
  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  @generated
  set typeArguments(TypeArgumentListImpl? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('importPrefix', importPrefix)
    ..addToken('name', name)
    ..addNode('typeArguments', typeArguments)
    ..addNode('argumentList', argumentList);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitExtensionOverride(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitExtensionOverride(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    importPrefix?.accept(visitor);
    typeArguments?.accept(visitor);
    argumentList.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (importPrefix case var importPrefix?) {
      if (importPrefix._containsOffset(rangeOffset, rangeEnd)) {
        return importPrefix;
      }
    }
    if (typeArguments case var typeArguments?) {
      if (typeArguments._containsOffset(rangeOffset, rangeEnd)) {
        return typeArguments;
      }
    }
    if (argumentList._containsOffset(rangeOffset, rangeEnd)) {
      return argumentList;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ExtensionTypeDeclaration
    implements NamedCompilationUnitMember {
  /// The `augment` keyword, or `null` if the keyword was absent.
  Token? get augmentKeyword;

  /// The `const` keyword.
  Token? get constKeyword;

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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('augmentKeyword'),
    GenerateNodeProperty('extensionKeyword'),
    GenerateNodeProperty('typeKeyword'),
    GenerateNodeProperty('constKeyword'),
    GenerateNodeProperty('name', isSuper: true),
    GenerateNodeProperty('typeParameters'),
    GenerateNodeProperty('representation'),
    GenerateNodeProperty('implementsClause'),
    GenerateNodeProperty('leftBracket'),
    GenerateNodeProperty('members'),
    GenerateNodeProperty('rightBracket'),
  ],
)
final class ExtensionTypeDeclarationImpl extends NamedCompilationUnitMemberImpl
    with AstNodeWithNameScopeMixin
    implements ExtensionTypeDeclaration {
  @generated
  @override
  final Token? augmentKeyword;

  @generated
  @override
  final Token extensionKeyword;

  @generated
  @override
  final Token typeKeyword;

  @generated
  @override
  final Token? constKeyword;

  @generated
  TypeParameterListImpl? _typeParameters;

  @generated
  RepresentationDeclarationImpl _representation;

  @generated
  ImplementsClauseImpl? _implementsClause;

  @generated
  @override
  final Token leftBracket;

  @generated
  @override
  final NodeListImpl<ClassMemberImpl> members = NodeListImpl._();

  @generated
  @override
  final Token rightBracket;

  @override
  ExtensionTypeFragmentImpl? declaredFragment;

  @generated
  ExtensionTypeDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
    required this.extensionKeyword,
    required this.typeKeyword,
    required this.constKeyword,
    required super.name,
    required TypeParameterListImpl? typeParameters,
    required RepresentationDeclarationImpl representation,
    required ImplementsClauseImpl? implementsClause,
    required this.leftBracket,
    required List<ClassMemberImpl> members,
    required this.rightBracket,
  }) : _typeParameters = typeParameters,
       _representation = representation,
       _implementsClause = implementsClause {
    _becomeParentOf(typeParameters);
    _becomeParentOf(representation);
    _becomeParentOf(implementsClause);
    this.members._initialize(this, members);
  }

  @generated
  @override
  Token get endToken {
    return rightBracket;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (augmentKeyword case var augmentKeyword?) {
      return augmentKeyword;
    }
    return extensionKeyword;
  }

  @generated
  @override
  ImplementsClauseImpl? get implementsClause => _implementsClause;

  @generated
  set implementsClause(ImplementsClauseImpl? implementsClause) {
    _implementsClause = _becomeParentOf(implementsClause);
  }

  @generated
  @override
  RepresentationDeclarationImpl get representation => _representation;

  @generated
  set representation(RepresentationDeclarationImpl representation) {
    _representation = _becomeParentOf(representation);
  }

  @generated
  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  @generated
  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @generated
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

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitExtensionTypeDeclaration(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    typeParameters?.accept(visitor);
    representation.accept(visitor);
    implementsClause?.accept(visitor);
    members.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (typeParameters case var typeParameters?) {
      if (typeParameters._containsOffset(rangeOffset, rangeEnd)) {
        return typeParameters;
      }
    }
    if (representation._containsOffset(rangeOffset, rangeEnd)) {
      return representation;
    }
    if (implementsClause case var implementsClause?) {
      if (implementsClause._containsOffset(rangeOffset, rangeEnd)) {
        return implementsClause;
      }
    }
    if (members._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class FieldDeclaration implements ClassMember {
  /// The `abstract` keyword, or `null` if the keyword isn't used.
  Token? get abstractKeyword;

  /// The `augment` keyword, or `null` if the keyword was absent.
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('abstractKeyword', tokenGroupId: 0),
    GenerateNodeProperty('augmentKeyword', tokenGroupId: 0),
    GenerateNodeProperty('covariantKeyword', tokenGroupId: 0),
    GenerateNodeProperty('externalKeyword', tokenGroupId: 0),
    GenerateNodeProperty('staticKeyword', tokenGroupId: 0),
    GenerateNodeProperty('fields'),
    GenerateNodeProperty('semicolon'),
  ],
)
final class FieldDeclarationImpl extends ClassMemberImpl
    implements FieldDeclaration {
  @generated
  @override
  final Token? abstractKeyword;

  @generated
  @override
  final Token? augmentKeyword;

  @generated
  @override
  final Token? covariantKeyword;

  @generated
  @override
  final Token? externalKeyword;

  @generated
  @override
  final Token? staticKeyword;

  @generated
  VariableDeclarationListImpl _fields;

  @generated
  @override
  final Token semicolon;

  @generated
  FieldDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.abstractKeyword,
    required this.augmentKeyword,
    required this.covariantKeyword,
    required this.externalKeyword,
    required this.staticKeyword,
    required VariableDeclarationListImpl fields,
    required this.semicolon,
  }) : _fields = fields {
    _becomeParentOf(fields);
  }

  @override
  Null get declaredFragment => null;

  @generated
  @override
  Token get endToken {
    return semicolon;
  }

  @generated
  @override
  VariableDeclarationListImpl get fields => _fields;

  @generated
  set fields(VariableDeclarationListImpl fields) {
    _fields = _becomeParentOf(fields);
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (Token.lexicallyFirst(
          abstractKeyword,
          augmentKeyword,
          covariantKeyword,
          externalKeyword,
          staticKeyword,
        )
        case var result?) {
      return result;
    }
    return fields.beginToken;
  }

  @override
  bool get isStatic => staticKeyword != null;

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('abstractKeyword', abstractKeyword)
    ..addToken('augmentKeyword', augmentKeyword)
    ..addToken('covariantKeyword', covariantKeyword)
    ..addToken('externalKeyword', externalKeyword)
    ..addToken('staticKeyword', staticKeyword)
    ..addNode('fields', fields)
    ..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFieldDeclaration(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    fields.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (fields._containsOffset(rangeOffset, rangeEnd)) {
      return fields;
    }
    return null;
  }
}

/// A field formal parameter.
///
///    fieldFormalParameter ::=
///        ('final' [TypeAnnotation] | 'const' [TypeAnnotation] | 'var' |
///        [TypeAnnotation])?
///        'this' '.' name ([TypeParameterList]? [FormalParameterList])?
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class FieldFormalParameter implements NormalFormalParameter {
  @override
  FieldFormalParameterFragment? get declaredFragment;

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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('covariantKeyword', isSuper: true),
    GenerateNodeProperty('requiredKeyword', isSuper: true),
    GenerateNodeProperty('keyword'),
    GenerateNodeProperty('type'),
    GenerateNodeProperty('thisKeyword'),
    GenerateNodeProperty('period'),
    GenerateNodeProperty('name', isSuper: true, superNullAssertOverride: true),
    GenerateNodeProperty('typeParameters'),
    GenerateNodeProperty('parameters'),
    GenerateNodeProperty('question'),
  ],
)
final class FieldFormalParameterImpl extends NormalFormalParameterImpl
    implements FieldFormalParameter {
  @generated
  @override
  final Token? keyword;

  @generated
  TypeAnnotationImpl? _type;

  @generated
  @override
  final Token thisKeyword;

  @generated
  @override
  final Token period;

  @generated
  TypeParameterListImpl? _typeParameters;

  @generated
  FormalParameterListImpl? _parameters;

  @generated
  @override
  final Token? question;

  @generated
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
  }) : _type = type,
       _typeParameters = typeParameters,
       _parameters = parameters {
    _becomeParentOf(type);
    _becomeParentOf(typeParameters);
    _becomeParentOf(parameters);
  }

  @override
  FieldFormalParameterFragmentImpl? get declaredFragment {
    return super.declaredFragment as FieldFormalParameterFragmentImpl?;
  }

  @generated
  @override
  Token get endToken {
    if (question case var question?) {
      return question;
    }
    if (parameters case var parameters?) {
      return parameters.endToken;
    }
    if (typeParameters case var typeParameters?) {
      return typeParameters.endToken;
    }
    return name;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (covariantKeyword case var covariantKeyword?) {
      return covariantKeyword;
    }
    if (requiredKeyword case var requiredKeyword?) {
      return requiredKeyword;
    }
    if (keyword case var keyword?) {
      return keyword;
    }
    if (type case var type?) {
      return type.beginToken;
    }
    return thisKeyword;
  }

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isExplicitlyTyped => _parameters != null || _type != null;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @generated
  @override
  Token get name => super.name!;

  @generated
  @override
  FormalParameterListImpl? get parameters => _parameters;

  @generated
  set parameters(FormalParameterListImpl? parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @generated
  @override
  TypeAnnotationImpl? get type => _type;

  @generated
  set type(TypeAnnotationImpl? type) {
    _type = _becomeParentOf(type);
  }

  @generated
  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  @generated
  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('covariantKeyword', covariantKeyword)
    ..addToken('requiredKeyword', requiredKeyword)
    ..addToken('keyword', keyword)
    ..addNode('type', type)
    ..addToken('thisKeyword', thisKeyword)
    ..addToken('period', period)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addNode('parameters', parameters)
    ..addToken('question', question);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitFieldFormalParameter(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    type?.accept(visitor);
    typeParameters?.accept(visitor);
    parameters?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (type case var type?) {
      if (type._containsOffset(rangeOffset, rangeEnd)) {
        return type;
      }
    }
    if (typeParameters case var typeParameters?) {
      if (typeParameters._containsOffset(rangeOffset, rangeEnd)) {
        return typeParameters;
      }
    }
    if (parameters case var parameters?) {
      if (parameters._containsOffset(rangeOffset, rangeEnd)) {
        return parameters;
      }
    }
    return null;
  }
}

/// The parts of a for-each loop that control the iteration.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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
  ForEachPartsImpl({required this.inKeyword, required ExpressionImpl iterable})
    : _iterable = iterable {
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

  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (_iterable._containsOffset(rangeOffset, rangeEnd)) {
      return _iterable;
    }
    return null;
  }
}

/// The parts of a for-each loop that control the iteration when the loop
/// variable is declared as part of the for loop.
///
///   forLoopParts ::=
///       [DeclaredIdentifier] 'in' [Expression]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ForEachPartsWithDeclaration implements ForEachParts {
  /// The declaration of the loop variable.
  DeclaredIdentifier get loopVariable;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('loopVariable'),
    GenerateNodeProperty('inKeyword', isSuper: true),
    GenerateNodeProperty('iterable', isSuper: true),
  ],
)
final class ForEachPartsWithDeclarationImpl extends ForEachPartsImpl
    implements ForEachPartsWithDeclaration {
  @generated
  DeclaredIdentifierImpl _loopVariable;

  @generated
  ForEachPartsWithDeclarationImpl({
    required DeclaredIdentifierImpl loopVariable,
    required super.inKeyword,
    required super.iterable,
  }) : _loopVariable = loopVariable {
    _becomeParentOf(loopVariable);
  }

  @generated
  @override
  Token get beginToken {
    return loopVariable.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return iterable.endToken;
  }

  @generated
  @override
  DeclaredIdentifierImpl get loopVariable => _loopVariable;

  @generated
  set loopVariable(DeclaredIdentifierImpl loopVariable) {
    _loopVariable = _becomeParentOf(loopVariable);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('loopVariable', loopVariable)
    ..addToken('inKeyword', inKeyword)
    ..addNode('iterable', iterable);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitForEachPartsWithDeclaration(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    loopVariable.accept(visitor);
    iterable.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (loopVariable._containsOffset(rangeOffset, rangeEnd)) {
      return loopVariable;
    }
    if (iterable._containsOffset(rangeOffset, rangeEnd)) {
      return iterable;
    }
    return null;
  }
}

/// The parts of a for-each loop that control the iteration when the loop
/// variable is declared outside of the for loop.
///
///   forLoopParts ::=
///       [SimpleIdentifier] 'in' [Expression]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ForEachPartsWithIdentifier implements ForEachParts {
  /// The loop variable.
  SimpleIdentifier get identifier;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('identifier'),
    GenerateNodeProperty('inKeyword', isSuper: true),
    GenerateNodeProperty('iterable', isSuper: true),
  ],
)
final class ForEachPartsWithIdentifierImpl extends ForEachPartsImpl
    implements ForEachPartsWithIdentifier {
  @generated
  SimpleIdentifierImpl _identifier;

  @generated
  ForEachPartsWithIdentifierImpl({
    required SimpleIdentifierImpl identifier,
    required super.inKeyword,
    required super.iterable,
  }) : _identifier = identifier {
    _becomeParentOf(identifier);
  }

  @generated
  @override
  Token get beginToken {
    return identifier.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return iterable.endToken;
  }

  @generated
  @override
  SimpleIdentifierImpl get identifier => _identifier;

  @generated
  set identifier(SimpleIdentifierImpl identifier) {
    _identifier = _becomeParentOf(identifier);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('identifier', identifier)
    ..addToken('inKeyword', inKeyword)
    ..addNode('iterable', iterable);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitForEachPartsWithIdentifier(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    identifier.accept(visitor);
    iterable.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (identifier._containsOffset(rangeOffset, rangeEnd)) {
      return identifier;
    }
    if (iterable._containsOffset(rangeOffset, rangeEnd)) {
      return iterable;
    }
    return null;
  }
}

/// A for-loop part with a pattern.
///
///    forEachPartsWithPattern ::=
///        ( 'final' | 'var' ) [DartPattern] 'in' [Expression]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ForEachPartsWithPattern implements ForEachParts {
  /// The `var` or `final` keyword introducing the pattern.
  Token get keyword;

  /// The annotations associated with this node.
  NodeList<Annotation> get metadata;

  /// The pattern used to match the expression.
  DartPattern get pattern;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('metadata'),
    GenerateNodeProperty('keyword'),
    GenerateNodeProperty('pattern'),
    GenerateNodeProperty('inKeyword', isSuper: true),
    GenerateNodeProperty('iterable', isSuper: true),
  ],
)
final class ForEachPartsWithPatternImpl extends ForEachPartsImpl
    implements ForEachPartsWithPattern {
  @generated
  @override
  final NodeListImpl<AnnotationImpl> metadata = NodeListImpl._();

  @generated
  @override
  final Token keyword;

  @generated
  DartPatternImpl _pattern;

  /// Variables declared in [pattern].
  late final List<BindPatternVariableFragmentImpl> variables;

  @generated
  ForEachPartsWithPatternImpl({
    required List<AnnotationImpl> metadata,
    required this.keyword,
    required DartPatternImpl pattern,
    required super.inKeyword,
    required super.iterable,
  }) : _pattern = pattern {
    this.metadata._initialize(this, metadata);
    _becomeParentOf(pattern);
  }

  @generated
  @override
  Token get beginToken {
    if (metadata.beginToken case var result?) {
      return result;
    }
    return keyword;
  }

  @generated
  @override
  Token get endToken {
    return iterable.endToken;
  }

  /// If [keyword] is `final`, returns it.
  Token? get finalKeyword {
    if (keyword.keyword == Keyword.FINAL) {
      return keyword;
    }
    return null;
  }

  @generated
  @override
  DartPatternImpl get pattern => _pattern;

  @generated
  set pattern(DartPatternImpl pattern) {
    _pattern = _becomeParentOf(pattern);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNodeList('metadata', metadata)
    ..addToken('keyword', keyword)
    ..addNode('pattern', pattern)
    ..addToken('inKeyword', inKeyword)
    ..addNode('iterable', iterable);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitForEachPartsWithPattern(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    metadata.accept(visitor);
    pattern.accept(visitor);
    iterable.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (metadata._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    if (pattern._containsOffset(rangeOffset, rangeEnd)) {
      return pattern;
    }
    if (iterable._containsOffset(rangeOffset, rangeEnd)) {
      return iterable;
    }
    return null;
  }
}

/// The basic structure of a for element.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ForElement
    implements CollectionElement, ForLoop<CollectionElement> {}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('awaitKeyword'),
    GenerateNodeProperty('forKeyword'),
    GenerateNodeProperty('leftParenthesis'),
    GenerateNodeProperty('forLoopParts'),
    GenerateNodeProperty('rightParenthesis'),
    GenerateNodeProperty('body'),
  ],
)
final class ForElementImpl extends CollectionElementImpl
    with AstNodeWithNameScopeMixin
    implements
        ForLoopImpl<CollectionElement, CollectionElementImpl>,
        ForElement {
  @generated
  @override
  final Token? awaitKeyword;

  @generated
  @override
  final Token forKeyword;

  @generated
  @override
  final Token leftParenthesis;

  @generated
  ForLoopPartsImpl _forLoopParts;

  @generated
  @override
  final Token rightParenthesis;

  @generated
  CollectionElementImpl _body;

  @generated
  ForElementImpl({
    required this.awaitKeyword,
    required this.forKeyword,
    required this.leftParenthesis,
    required ForLoopPartsImpl forLoopParts,
    required this.rightParenthesis,
    required CollectionElementImpl body,
  }) : _forLoopParts = forLoopParts,
       _body = body {
    _becomeParentOf(forLoopParts);
    _becomeParentOf(body);
  }

  @generated
  @override
  Token get beginToken {
    if (awaitKeyword case var awaitKeyword?) {
      return awaitKeyword;
    }
    return forKeyword;
  }

  @generated
  @override
  CollectionElementImpl get body => _body;

  @generated
  set body(CollectionElementImpl body) {
    _body = _becomeParentOf(body);
  }

  @generated
  @override
  Token get endToken {
    return body.endToken;
  }

  @generated
  @override
  ForLoopPartsImpl get forLoopParts => _forLoopParts;

  @generated
  set forLoopParts(ForLoopPartsImpl forLoopParts) {
    _forLoopParts = _becomeParentOf(forLoopParts);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('awaitKeyword', awaitKeyword)
    ..addToken('forKeyword', forKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('forLoopParts', forLoopParts)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addNode('body', body);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitForElement(this);

  @override
  void resolveElement(
    ResolverVisitor resolver,
    CollectionLiteralContext? context,
  ) {
    resolver.visitForElement(this, context: context);
    resolver.pushRewrite(null);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    forLoopParts.accept(visitor);
    body.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (forLoopParts._containsOffset(rangeOffset, rangeEnd)) {
      return forLoopParts;
    }
    if (body._containsOffset(rangeOffset, rangeEnd)) {
      return body;
    }
    return null;
  }
}

/// A for or for-each statement or collection element.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
sealed class ForLoop<Body extends AstNode> implements AstNode {
  /// The token representing the `await` keyword, or `null` if there's no
  /// `await` keyword.
  Token? get awaitKeyword;

  /// The body of the loop.
  Body get body;

  /// The token representing the `for` keyword.
  Token get forKeyword;

  /// The parts of the for element that control the iteration.
  ForLoopParts get forLoopParts;

  /// The left parenthesis.
  Token get leftParenthesis;

  /// The right parenthesis.
  Token get rightParenthesis;
}

sealed class ForLoopImpl<Body extends AstNode, BodyImpl extends Body>
    implements AstNodeImpl, ForLoop<Body> {
  @override
  BodyImpl get body;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
sealed class ForLoopParts implements AstNode {
  @override
  ForLoop get parent;
}

sealed class ForLoopPartsImpl extends AstNodeImpl implements ForLoopParts {
  @override
  ForLoopImpl get parent => super.parent as ForLoopImpl;
}

/// A node representing a parameter to a function.
///
///    formalParameter ::=
///        [NormalFormalParameter]
///      | [DefaultFormalParameter]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
sealed class FormalParameter implements AstNode {
  /// The `covariant` keyword, or `null` if the keyword isn't used.
  Token? get covariantKeyword;

  ///The fragment declared by this parameter.
  ///
  /// Returns `null` if this parameter hasn't been resolved.
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
  FormalParameterFragmentImpl? declaredFragment;

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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class FormalParameterList implements AstNode {
  /// The left square bracket ('[') or left curly brace ('{') introducing the
  /// optional or named parameters, or `null` if there are neither optional nor
  /// named parameters.
  Token? get leftDelimiter;

  /// The left parenthesis.
  Token get leftParenthesis;

  /// A list containing the fragments representing the parameters in this list.
  ///
  /// The list contains `null`s if the parameters in this list haven't been
  /// resolved.
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('leftParenthesis'),
    GenerateNodeProperty('parameters'),
    GenerateNodeProperty('leftDelimiter'),
    GenerateNodeProperty('rightDelimiter'),
    GenerateNodeProperty('rightParenthesis'),
  ],
)
final class FormalParameterListImpl extends AstNodeImpl
    implements FormalParameterList {
  @generated
  @override
  final Token leftParenthesis;

  @generated
  @override
  final NodeListImpl<FormalParameterImpl> parameters = NodeListImpl._();

  @generated
  @override
  final Token? leftDelimiter;

  @generated
  @override
  final Token? rightDelimiter;

  @generated
  @override
  final Token rightParenthesis;

  @generated
  FormalParameterListImpl({
    required this.leftParenthesis,
    required List<FormalParameterImpl> parameters,
    required this.leftDelimiter,
    required this.rightDelimiter,
    required this.rightParenthesis,
  }) {
    this.parameters._initialize(this, parameters);
  }

  @generated
  @override
  Token get beginToken {
    return leftParenthesis;
  }

  @generated
  @override
  Token get endToken {
    return rightParenthesis;
  }

  @override
  List<FormalParameterFragmentImpl?> get parameterFragments {
    return parameters.map((node) => node.declaredFragment).toList();
  }

  @override
  @DoNotGenerate(reason: 'Has special logic for delimiters')
  ChildEntities get _childEntities {
    // TODO(paulberry): include commas.
    var result = ChildEntities()..addToken('leftParenthesis', leftParenthesis);
    bool leftDelimiterNeeded = leftDelimiter != null;
    int length = parameters.length;
    for (int i = 0; i < length; i++) {
      FormalParameter parameter = parameters[i];
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

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFormalParameterList(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    parameters.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (parameters._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// The parts of a for loop that control the iteration.
///
///   forLoopParts ::=
///       [VariableDeclaration] ';' [Expression]? ';' expressionList?
///     | [Expression]? ';' [Expression]? ';' expressionList?
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (_condition?._containsOffset(rangeOffset, rangeEnd) ?? false) {
      return _condition;
    }
    return _updaters._elementContainingRange(rangeOffset, rangeEnd);
  }
}

/// The parts of a for loop that control the iteration when there are one or
/// more variable declarations as part of the for loop.
///
///   forLoopParts ::=
///       [VariableDeclarationList] ';' [Expression]? ';' expressionList?
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ForPartsWithDeclarations implements ForParts {
  /// The declaration of the loop variables.
  VariableDeclarationList get variables;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('variables'),
    GenerateNodeProperty('leftSeparator', isSuper: true),
    GenerateNodeProperty('condition', isSuper: true),
    GenerateNodeProperty('rightSeparator', isSuper: true),
    GenerateNodeProperty('updaters', isSuper: true),
  ],
)
final class ForPartsWithDeclarationsImpl extends ForPartsImpl
    implements ForPartsWithDeclarations {
  @generated
  VariableDeclarationListImpl _variables;

  @generated
  ForPartsWithDeclarationsImpl({
    required VariableDeclarationListImpl variables,
    required super.leftSeparator,
    required super.condition,
    required super.rightSeparator,
    required super.updaters,
  }) : _variables = variables {
    _becomeParentOf(variables);
  }

  @generated
  @override
  Token get beginToken {
    return variables.beginToken;
  }

  @generated
  @override
  Token get endToken {
    if (updaters.endToken case var result?) {
      return result;
    }
    return rightSeparator;
  }

  @generated
  @override
  VariableDeclarationListImpl get variables => _variables;

  @generated
  set variables(VariableDeclarationListImpl variables) {
    _variables = _becomeParentOf(variables);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('variables', variables)
    ..addToken('leftSeparator', leftSeparator)
    ..addNode('condition', condition)
    ..addToken('rightSeparator', rightSeparator)
    ..addNodeList('updaters', updaters);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitForPartsWithDeclarations(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    variables.accept(visitor);
    condition?.accept(visitor);
    updaters.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (variables._containsOffset(rangeOffset, rangeEnd)) {
      return variables;
    }
    if (condition case var condition?) {
      if (condition._containsOffset(rangeOffset, rangeEnd)) {
        return condition;
      }
    }
    if (updaters._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// The parts of a for loop that control the iteration when there are no
/// variable declarations as part of the for loop.
///
///   forLoopParts ::=
///       [Expression]? ';' [Expression]? ';' expressionList?
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ForPartsWithExpression implements ForParts {
  /// The initialization expression, or `null` if there's no initialization
  /// expression.
  ///
  /// Note that a for statement can't have both a variable list and an
  /// initialization expression, but can validly have neither.
  Expression? get initialization;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('initialization'),
    GenerateNodeProperty('leftSeparator', isSuper: true),
    GenerateNodeProperty('condition', isSuper: true),
    GenerateNodeProperty('rightSeparator', isSuper: true),
    GenerateNodeProperty('updaters', isSuper: true),
  ],
)
final class ForPartsWithExpressionImpl extends ForPartsImpl
    implements ForPartsWithExpression {
  @generated
  ExpressionImpl? _initialization;

  @generated
  ForPartsWithExpressionImpl({
    required ExpressionImpl? initialization,
    required super.leftSeparator,
    required super.condition,
    required super.rightSeparator,
    required super.updaters,
  }) : _initialization = initialization {
    _becomeParentOf(initialization);
  }

  @generated
  @override
  Token get beginToken {
    if (initialization case var initialization?) {
      return initialization.beginToken;
    }
    return leftSeparator;
  }

  @generated
  @override
  Token get endToken {
    if (updaters.endToken case var result?) {
      return result;
    }
    return rightSeparator;
  }

  @generated
  @override
  ExpressionImpl? get initialization => _initialization;

  @generated
  set initialization(ExpressionImpl? initialization) {
    _initialization = _becomeParentOf(initialization);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('initialization', initialization)
    ..addToken('leftSeparator', leftSeparator)
    ..addNode('condition', condition)
    ..addToken('rightSeparator', rightSeparator)
    ..addNodeList('updaters', updaters);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitForPartsWithExpression(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    initialization?.accept(visitor);
    condition?.accept(visitor);
    updaters.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (initialization case var initialization?) {
      if (initialization._containsOffset(rangeOffset, rangeEnd)) {
        return initialization;
      }
    }
    if (condition case var condition?) {
      if (condition._containsOffset(rangeOffset, rangeEnd)) {
        return condition;
      }
    }
    if (updaters._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// The parts of a for loop that control the iteration when there's a pattern
/// declaration as part of the for loop.
///
///   forLoopParts ::=
///       [PatternVariableDeclaration] ';' [Expression]? ';' expressionList?
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ForPartsWithPattern implements ForParts {
  /// The declaration of the loop variables.
  PatternVariableDeclaration get variables;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('variables'),
    GenerateNodeProperty('leftSeparator', isSuper: true),
    GenerateNodeProperty('condition', isSuper: true),
    GenerateNodeProperty('rightSeparator', isSuper: true),
    GenerateNodeProperty('updaters', isSuper: true),
  ],
)
final class ForPartsWithPatternImpl extends ForPartsImpl
    implements ForPartsWithPattern {
  @generated
  PatternVariableDeclarationImpl _variables;

  @generated
  ForPartsWithPatternImpl({
    required PatternVariableDeclarationImpl variables,
    required super.leftSeparator,
    required super.condition,
    required super.rightSeparator,
    required super.updaters,
  }) : _variables = variables {
    _becomeParentOf(variables);
  }

  @generated
  @override
  Token get beginToken {
    return variables.beginToken;
  }

  @generated
  @override
  Token get endToken {
    if (updaters.endToken case var result?) {
      return result;
    }
    return rightSeparator;
  }

  @generated
  @override
  PatternVariableDeclarationImpl get variables => _variables;

  @generated
  set variables(PatternVariableDeclarationImpl variables) {
    _variables = _becomeParentOf(variables);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('variables', variables)
    ..addToken('leftSeparator', leftSeparator)
    ..addNode('condition', condition)
    ..addToken('rightSeparator', rightSeparator)
    ..addNodeList('updaters', updaters);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitForPartsWithPattern(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    variables.accept(visitor);
    condition?.accept(visitor);
    updaters.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (variables._containsOffset(rangeOffset, rangeEnd)) {
      return variables;
    }
    if (condition case var condition?) {
      if (condition._containsOffset(rangeOffset, rangeEnd)) {
        return condition;
      }
    }
    if (updaters._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ForStatement implements Statement, ForLoop<Statement> {}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('awaitKeyword'),
    GenerateNodeProperty('forKeyword'),
    GenerateNodeProperty('leftParenthesis'),
    GenerateNodeProperty('forLoopParts'),
    GenerateNodeProperty('rightParenthesis'),
    GenerateNodeProperty('body'),
  ],
)
final class ForStatementImpl extends StatementImpl
    with AstNodeWithNameScopeMixin
    implements ForLoopImpl<Statement, StatementImpl>, ForStatement {
  @generated
  @override
  final Token? awaitKeyword;

  @generated
  @override
  final Token forKeyword;

  @generated
  @override
  final Token leftParenthesis;

  @generated
  ForLoopPartsImpl _forLoopParts;

  @generated
  @override
  final Token rightParenthesis;

  @generated
  StatementImpl _body;

  @generated
  ForStatementImpl({
    required this.awaitKeyword,
    required this.forKeyword,
    required this.leftParenthesis,
    required ForLoopPartsImpl forLoopParts,
    required this.rightParenthesis,
    required StatementImpl body,
  }) : _forLoopParts = forLoopParts,
       _body = body {
    _becomeParentOf(forLoopParts);
    _becomeParentOf(body);
  }

  @generated
  @override
  Token get beginToken {
    if (awaitKeyword case var awaitKeyword?) {
      return awaitKeyword;
    }
    return forKeyword;
  }

  @generated
  @override
  StatementImpl get body => _body;

  @generated
  set body(StatementImpl body) {
    _body = _becomeParentOf(body);
  }

  @generated
  @override
  Token get endToken {
    return body.endToken;
  }

  @generated
  @override
  ForLoopPartsImpl get forLoopParts => _forLoopParts;

  @generated
  set forLoopParts(ForLoopPartsImpl forLoopParts) {
    _forLoopParts = _becomeParentOf(forLoopParts);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('awaitKeyword', awaitKeyword)
    ..addToken('forKeyword', forKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('forLoopParts', forLoopParts)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addNode('body', body);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitForStatement(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    forLoopParts.accept(visitor);
    body.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (forLoopParts._containsOffset(rangeOffset, rangeEnd)) {
      return forLoopParts;
    }
    if (body._containsOffset(rangeOffset, rangeEnd)) {
      return body;
    }
    return null;
  }
}

/// A node representing the body of a function or method.
///
///    functionBody ::=
///        [BlockFunctionBody]
///      | [EmptyFunctionBody]
///      | [ExpressionFunctionBody]
///      | [NativeFunctionBody]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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
  @Deprecated('Use isPotentiallyMutatedInScope instead')
  bool isPotentiallyMutatedInScope2(VariableElement variable);
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

  @Deprecated('Use isPotentiallyMutatedInScope instead')
  @override
  bool isPotentiallyMutatedInScope2(VariableElement variable) {
    return isPotentiallyMutatedInScope(variable);
  }

  /// Dispatch this function body to the resolver, imposing [imposedType] as the
  /// return type context for `return` statements.
  ///
  /// Returns value is the actual return type of the method.
  TypeImpl resolve(ResolverVisitor resolver, TypeImpl? imposedType);
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class FunctionDeclaration implements NamedCompilationUnitMember {
  /// The `augment` keyword, or `null` if there is no `augment` keyword.
  Token? get augmentKeyword;

  /// The fragment declared by this declaration.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if this node
  /// represents a local function.
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('augmentKeyword'),
    GenerateNodeProperty('externalKeyword'),
    GenerateNodeProperty('returnType'),
    GenerateNodeProperty('propertyKeyword'),
    GenerateNodeProperty('name', isSuper: true),
    GenerateNodeProperty('functionExpression'),
  ],
)
final class FunctionDeclarationImpl extends NamedCompilationUnitMemberImpl
    with AstNodeWithNameScopeMixin
    implements FunctionDeclaration {
  @generated
  @override
  final Token? augmentKeyword;

  @generated
  @override
  final Token? externalKeyword;

  @generated
  TypeAnnotationImpl? _returnType;

  @generated
  @override
  final Token? propertyKeyword;

  @generated
  FunctionExpressionImpl _functionExpression;

  @override
  ExecutableFragmentImpl? declaredFragment;

  @generated
  FunctionDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
    required this.externalKeyword,
    required TypeAnnotationImpl? returnType,
    required this.propertyKeyword,
    required super.name,
    required FunctionExpressionImpl functionExpression,
  }) : _returnType = returnType,
       _functionExpression = functionExpression {
    _becomeParentOf(returnType);
    _becomeParentOf(functionExpression);
  }

  @generated
  @override
  Token get endToken {
    return functionExpression.endToken;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (augmentKeyword case var augmentKeyword?) {
      return augmentKeyword;
    }
    if (externalKeyword case var externalKeyword?) {
      return externalKeyword;
    }
    if (returnType case var returnType?) {
      return returnType.beginToken;
    }
    if (propertyKeyword case var propertyKeyword?) {
      return propertyKeyword;
    }
    return name;
  }

  @generated
  @override
  FunctionExpressionImpl get functionExpression => _functionExpression;

  @generated
  set functionExpression(FunctionExpressionImpl functionExpression) {
    _functionExpression = _becomeParentOf(functionExpression);
  }

  @override
  bool get isGetter => propertyKeyword?.keyword == Keyword.GET;

  @override
  bool get isSetter => propertyKeyword?.keyword == Keyword.SET;

  @generated
  @override
  TypeAnnotationImpl? get returnType => _returnType;

  @generated
  set returnType(TypeAnnotationImpl? returnType) {
    _returnType = _becomeParentOf(returnType);
  }

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('augmentKeyword', augmentKeyword)
    ..addToken('externalKeyword', externalKeyword)
    ..addNode('returnType', returnType)
    ..addToken('propertyKeyword', propertyKeyword)
    ..addToken('name', name)
    ..addNode('functionExpression', functionExpression);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFunctionDeclaration(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    returnType?.accept(visitor);
    functionExpression.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (returnType case var returnType?) {
      if (returnType._containsOffset(rangeOffset, rangeEnd)) {
        return returnType;
      }
    }
    if (functionExpression._containsOffset(rangeOffset, rangeEnd)) {
      return functionExpression;
    }
    return null;
  }
}

/// A [FunctionDeclaration] used as a statement.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class FunctionDeclarationStatement implements Statement {
  /// The function declaration being wrapped.
  FunctionDeclaration get functionDeclaration;
}

@GenerateNodeImpl(
  childEntitiesOrder: [GenerateNodeProperty('functionDeclaration')],
)
final class FunctionDeclarationStatementImpl extends StatementImpl
    implements FunctionDeclarationStatement {
  @generated
  FunctionDeclarationImpl _functionDeclaration;

  @generated
  FunctionDeclarationStatementImpl({
    required FunctionDeclarationImpl functionDeclaration,
  }) : _functionDeclaration = functionDeclaration {
    _becomeParentOf(functionDeclaration);
  }

  @generated
  @override
  Token get beginToken {
    return functionDeclaration.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return functionDeclaration.endToken;
  }

  @generated
  @override
  FunctionDeclarationImpl get functionDeclaration => _functionDeclaration;

  @generated
  set functionDeclaration(FunctionDeclarationImpl functionDeclaration) {
    _functionDeclaration = _becomeParentOf(functionDeclaration);
  }

  @generated
  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addNode('functionDeclaration', functionDeclaration);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitFunctionDeclarationStatement(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    functionDeclaration.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (functionDeclaration._containsOffset(rangeOffset, rangeEnd)) {
      return functionDeclaration;
    }
    return null;
  }
}

/// A function expression.
///
///    functionExpression ::=
///        [TypeParameterList]? [FormalParameterList] [FunctionBody]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class FunctionExpression implements Expression {
  /// The body of the function.
  FunctionBody get body;

  /// The fragment declared by this function expression.
  ///
  /// Returns `null` if the AST structure hasn't been resolved.
  ///
  /// Returns `null` is thie expression is a closure, or the parent is a
  /// local function.
  ExecutableFragment? get declaredFragment;

  /// The parameters associated with the function, or `null` if the function is
  /// part of a top-level getter.
  FormalParameterList? get parameters;

  /// The type parameters associated with this method, or `null` if this method
  /// isn't a generic method.
  TypeParameterList? get typeParameters;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('typeParameters'),
    GenerateNodeProperty('parameters'),
    GenerateNodeProperty('body'),
  ],
)
final class FunctionExpressionImpl extends ExpressionImpl
    implements FunctionExpression {
  @generated
  TypeParameterListImpl? _typeParameters;

  @generated
  FormalParameterListImpl? _parameters;

  @generated
  FunctionBodyImpl _body;

  /// Whether a function type was supplied via context for this function
  /// expression.
  ///
  /// Returns `false` if resolution hasn't been performed yet.
  bool wasFunctionTypeSupplied = false;

  @override
  ExecutableFragmentImpl? declaredFragment;

  @generated
  FunctionExpressionImpl({
    required TypeParameterListImpl? typeParameters,
    required FormalParameterListImpl? parameters,
    required FunctionBodyImpl body,
  }) : _typeParameters = typeParameters,
       _parameters = parameters,
       _body = body {
    _becomeParentOf(typeParameters);
    _becomeParentOf(parameters);
    _becomeParentOf(body);
  }

  @generated
  @override
  Token get beginToken {
    if (typeParameters case var typeParameters?) {
      return typeParameters.beginToken;
    }
    if (parameters case var parameters?) {
      return parameters.beginToken;
    }
    return body.beginToken;
  }

  @generated
  @override
  FunctionBodyImpl get body => _body;

  @generated
  set body(FunctionBodyImpl body) {
    _body = _becomeParentOf(body);
  }

  @generated
  @override
  Token get endToken {
    return body.endToken;
  }

  @generated
  @override
  FormalParameterListImpl? get parameters => _parameters;

  @generated
  set parameters(FormalParameterListImpl? parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @override
  Precedence get precedence => Precedence.primary;

  @generated
  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  @generated
  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('typeParameters', typeParameters)
    ..addNode('parameters', parameters)
    ..addNode('body', body);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFunctionExpression(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitFunctionExpression(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    typeParameters?.accept(visitor);
    parameters?.accept(visitor);
    body.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (typeParameters case var typeParameters?) {
      if (typeParameters._containsOffset(rangeOffset, rangeEnd)) {
        return typeParameters;
      }
    }
    if (parameters case var parameters?) {
      if (parameters._containsOffset(rangeOffset, rangeEnd)) {
        return parameters;
      }
    }
    if (body._containsOffset(rangeOffset, rangeEnd)) {
      return body;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class FunctionExpressionInvocation
    implements
        // ignore: deprecated_member_use_from_same_package
        NullShortableExpression,
        InvocationExpression {
  /// The element associated with the function being invoked based on static
  /// type information.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or the function
  /// couldn't be resolved.
  ExecutableElement? get element;

  /// The expression producing the function being invoked.
  @override
  Expression get function;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('function'),
    GenerateNodeProperty('typeArguments', isSuper: true),
    GenerateNodeProperty('argumentList', isSuper: true),
  ],
)
final class FunctionExpressionInvocationImpl extends InvocationExpressionImpl
    with NullShortableExpressionImpl
    implements RewrittenMethodInvocationImpl, FunctionExpressionInvocation {
  @generated
  ExpressionImpl _function;

  @override
  ExecutableElement? element;

  @generated
  FunctionExpressionInvocationImpl({
    required ExpressionImpl function,
    required super.typeArguments,
    required super.argumentList,
  }) : _function = function {
    _becomeParentOf(function);
  }

  @generated
  @override
  Token get beginToken {
    return function.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return argumentList.endToken;
  }

  @generated
  @override
  ExpressionImpl get function => _function;

  @generated
  set function(ExpressionImpl function) {
    _function = _becomeParentOf(function);
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('function', function)
    ..addNode('typeArguments', typeArguments)
    ..addNode('argumentList', argumentList);

  @override
  AstNode? get _nullShortingExtensionCandidate => parent;

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitFunctionExpressionInvocation(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitFunctionExpressionInvocation(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    function.accept(visitor);
    typeArguments?.accept(visitor);
    argumentList.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (function._containsOffset(rangeOffset, rangeEnd)) {
      return function;
    }
    if (typeArguments case var typeArguments?) {
      if (typeArguments._containsOffset(rangeOffset, rangeEnd)) {
        return typeArguments;
      }
    }
    if (argumentList._containsOffset(rangeOffset, rangeEnd)) {
      return argumentList;
    }
    return null;
  }

  @override
  bool _extendsNullShorting(Expression descendant) =>
      identical(descendant, _function);
}

/// An expression representing a reference to a function, possibly with type
/// arguments applied to it.
///
/// For example, the expression `print` in `var x = print;`.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class FunctionReference
    implements Expression, CommentReferableExpression {
  /// The function being referenced.
  ///
  /// In error-free code, this is either a [SimpleIdentifier] (indicating a
  /// function that is in scope), a [PrefixedIdentifier] (indicating a either
  /// function imported via prefix or a static method in a class), a
  /// [PropertyAccess] (indicating a static method in a class imported via
  /// prefix), or a [DotShorthandPropertyAccess] (indicating a static method in
  /// a class). In code with errors, this could be other kinds of expressions.
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('function'),
    GenerateNodeProperty('typeArguments'),
  ],
)
final class FunctionReferenceImpl extends CommentReferableExpressionImpl
    with DotShorthandMixin
    implements FunctionReference {
  @generated
  ExpressionImpl _function;

  @generated
  TypeArgumentListImpl? _typeArguments;

  @override
  List<TypeImpl>? typeArgumentTypes;

  @generated
  FunctionReferenceImpl({
    required ExpressionImpl function,
    required TypeArgumentListImpl? typeArguments,
  }) : _function = function,
       _typeArguments = typeArguments {
    _becomeParentOf(function);
    _becomeParentOf(typeArguments);
  }

  @generated
  @override
  Token get beginToken {
    return function.beginToken;
  }

  @generated
  @override
  Token get endToken {
    if (typeArguments case var typeArguments?) {
      return typeArguments.endToken;
    }
    return function.endToken;
  }

  @generated
  @override
  ExpressionImpl get function => _function;

  @generated
  set function(ExpressionImpl function) {
    _function = _becomeParentOf(function);
  }

  @override
  Precedence get precedence =>
      typeArguments == null ? function.precedence : Precedence.postfix;

  @generated
  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  @generated
  set typeArguments(TypeArgumentListImpl? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('function', function)
    ..addNode('typeArguments', typeArguments);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFunctionReference(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitFunctionReference(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    function.accept(visitor);
    typeArguments?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (function._containsOffset(rangeOffset, rangeEnd)) {
      return function;
    }
    if (typeArguments case var typeArguments?) {
      if (typeArguments._containsOffset(rangeOffset, rangeEnd)) {
        return typeArguments;
      }
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class FunctionTypeAlias implements TypeAlias {
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('augmentKeyword', isSuper: true),
    GenerateNodeProperty('typedefKeyword', isSuper: true),
    GenerateNodeProperty('returnType'),
    GenerateNodeProperty('name', isSuper: true),
    GenerateNodeProperty('typeParameters'),
    GenerateNodeProperty('parameters'),
    GenerateNodeProperty('semicolon', isSuper: true),
  ],
)
final class FunctionTypeAliasImpl extends TypeAliasImpl
    implements FunctionTypeAlias {
  @generated
  TypeAnnotationImpl? _returnType;

  @generated
  TypeParameterListImpl? _typeParameters;

  @generated
  FormalParameterListImpl _parameters;

  @override
  TypeAliasFragmentImpl? declaredFragment;

  @generated
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
  }) : _returnType = returnType,
       _typeParameters = typeParameters,
       _parameters = parameters {
    _becomeParentOf(returnType);
    _becomeParentOf(typeParameters);
    _becomeParentOf(parameters);
  }

  @generated
  @override
  Token get endToken {
    return semicolon;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (augmentKeyword case var augmentKeyword?) {
      return augmentKeyword;
    }
    return typedefKeyword;
  }

  @generated
  @override
  FormalParameterListImpl get parameters => _parameters;

  @generated
  set parameters(FormalParameterListImpl parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @generated
  @override
  TypeAnnotationImpl? get returnType => _returnType;

  @generated
  set returnType(TypeAnnotationImpl? returnType) {
    _returnType = _becomeParentOf(returnType);
  }

  @generated
  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  @generated
  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('augmentKeyword', augmentKeyword)
    ..addToken('typedefKeyword', typedefKeyword)
    ..addNode('returnType', returnType)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addNode('parameters', parameters)
    ..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitFunctionTypeAlias(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    returnType?.accept(visitor);
    typeParameters?.accept(visitor);
    parameters.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (returnType case var returnType?) {
      if (returnType._containsOffset(rangeOffset, rangeEnd)) {
        return returnType;
      }
    }
    if (typeParameters case var typeParameters?) {
      if (typeParameters._containsOffset(rangeOffset, rangeEnd)) {
        return typeParameters;
      }
    }
    if (parameters._containsOffset(rangeOffset, rangeEnd)) {
      return parameters;
    }
    return null;
  }
}

/// A function-typed formal parameter.
///
///    functionSignature ::=
///        [TypeAnnotation]? name [TypeParameterList]?
///        [FormalParameterList] '?'?
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('covariantKeyword', isSuper: true),
    GenerateNodeProperty('requiredKeyword', isSuper: true),
    GenerateNodeProperty('returnType'),
    GenerateNodeProperty('name', isSuper: true, superNullAssertOverride: true),
    GenerateNodeProperty('typeParameters'),
    GenerateNodeProperty('parameters'),
    GenerateNodeProperty('question'),
  ],
)
final class FunctionTypedFormalParameterImpl extends NormalFormalParameterImpl
    implements FunctionTypedFormalParameter {
  @generated
  TypeAnnotationImpl? _returnType;

  @generated
  TypeParameterListImpl? _typeParameters;

  @generated
  FormalParameterListImpl _parameters;

  @generated
  @override
  final Token? question;

  @generated
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
  }) : _returnType = returnType,
       _typeParameters = typeParameters,
       _parameters = parameters {
    _becomeParentOf(returnType);
    _becomeParentOf(typeParameters);
    _becomeParentOf(parameters);
  }

  @generated
  @override
  Token get endToken {
    if (question case var question?) {
      return question;
    }
    return parameters.endToken;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (covariantKeyword case var covariantKeyword?) {
      return covariantKeyword;
    }
    if (requiredKeyword case var requiredKeyword?) {
      return requiredKeyword;
    }
    if (returnType case var returnType?) {
      return returnType.beginToken;
    }
    return name;
  }

  @override
  bool get isConst => false;

  @override
  bool get isExplicitlyTyped => true;

  @override
  bool get isFinal => false;

  @generated
  @override
  Token get name => super.name!;

  @generated
  @override
  FormalParameterListImpl get parameters => _parameters;

  @generated
  set parameters(FormalParameterListImpl parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @generated
  @override
  TypeAnnotationImpl? get returnType => _returnType;

  @generated
  set returnType(TypeAnnotationImpl? returnType) {
    _returnType = _becomeParentOf(returnType);
  }

  @generated
  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  @generated
  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('covariantKeyword', covariantKeyword)
    ..addToken('requiredKeyword', requiredKeyword)
    ..addNode('returnType', returnType)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addNode('parameters', parameters)
    ..addToken('question', question);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitFunctionTypedFormalParameter(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    returnType?.accept(visitor);
    typeParameters?.accept(visitor);
    parameters.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (returnType case var returnType?) {
      if (returnType._containsOffset(rangeOffset, rangeEnd)) {
        return returnType;
      }
    }
    if (typeParameters case var typeParameters?) {
      if (typeParameters._containsOffset(rangeOffset, rangeEnd)) {
        return typeParameters;
      }
    }
    if (parameters._containsOffset(rangeOffset, rangeEnd)) {
      return parameters;
    }
    return null;
  }
}

class GenerateNodeImpl {
  /// The order is important for [AstNodeImpl._childEntities].
  final List<GenerateNodeProperty> childEntitiesOrder;

  const GenerateNodeImpl({required this.childEntitiesOrder});
}

/// Description for a single property in the node implementation.
///
/// Most of these descriptions refer to properties of the public interface,
/// e.g. `Foo` in `class FooImpl extends BarImpl implements Baz, Foo`.
class GenerateNodeProperty {
  final String name;

  /// If `true`, then `super.name` should be generated in the constructor,
  /// and no field or getter is generated, unless [superNullAssertOverride].
  final bool isSuper;

  /// Normally [NodeList] properties are final, but sometimes we mutate nodes.
  final bool isNodeListFinal;

  /// Normally [Token] properties are final, but sometimes we mutate nodes.
  final bool isTokenFinal;

  /// When the property is from the public interface, its field or getter
  /// should have `@override` annotation. But sometimes we want to have
  /// implementation only property, not in the public interface.
  final bool withOverride;

  /// To generate overrides like `Token get name => super.name!;`.
  /// Obviously, these are always paired with [isSuper].
  final bool superNullAssertOverride;

  /// If the parser can recover from tokens in a group of keyword tokens
  /// being in wrong order, each keyword's property in the group should be
  /// marked with the same non-null value for this field. The generated code
  /// for [AstNode.beginToken] or
  /// [AnnotatedNode.firstTokenAfterCommentAndMetadata] will use
  /// [Token.lexicallyFirst] to identify which keyword in the group appears
  /// first.
  ///
  /// Only meaningful when applied to token properties; all properties with
  /// the same [tokenGroupId] should appear consecutively in the
  /// `childEntitiesOrder` list.
  final int? tokenGroupId;

  /// The type of the property.
  ///
  /// If the property is declared in the public API, this doesn't need to be
  /// specified (because it can be inferred from the public API declaration).
  final Type? type;

  const GenerateNodeProperty(
    this.name, {
    this.isSuper = false,
    this.isNodeListFinal = true,
    this.isTokenFinal = true,
    this.withOverride = true,
    this.superNullAssertOverride = false,
    this.tokenGroupId,
    this.type,
  });
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class GenericFunctionType implements TypeAnnotation {
  /// The fragment declared by this declaration.
  ///
  /// Returns `null` if the AST structure hasn't been resolved.
  GenericFunctionTypeFragment? get declaredFragment;

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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('returnType'),
    GenerateNodeProperty('functionKeyword'),
    GenerateNodeProperty('typeParameters'),
    GenerateNodeProperty('parameters'),
    GenerateNodeProperty('question'),
  ],
)
final class GenericFunctionTypeImpl extends TypeAnnotationImpl
    with AstNodeWithNameScopeMixin
    implements GenericFunctionType {
  @generated
  TypeAnnotationImpl? _returnType;

  @generated
  @override
  final Token functionKeyword;

  @generated
  TypeParameterListImpl? _typeParameters;

  @generated
  FormalParameterListImpl _parameters;

  @generated
  @override
  final Token? question;

  @override
  TypeImpl? type;

  /// The element associated with the function type, or `null` if the AST
  /// structure hasn't been resolved.
  @override
  GenericFunctionTypeFragmentImpl? declaredFragment;

  @generated
  GenericFunctionTypeImpl({
    required TypeAnnotationImpl? returnType,
    required this.functionKeyword,
    required TypeParameterListImpl? typeParameters,
    required FormalParameterListImpl parameters,
    required this.question,
  }) : _returnType = returnType,
       _typeParameters = typeParameters,
       _parameters = parameters {
    _becomeParentOf(returnType);
    _becomeParentOf(typeParameters);
    _becomeParentOf(parameters);
  }

  @generated
  @override
  Token get beginToken {
    if (returnType case var returnType?) {
      return returnType.beginToken;
    }
    return functionKeyword;
  }

  @generated
  @override
  Token get endToken {
    if (question case var question?) {
      return question;
    }
    return parameters.endToken;
  }

  @generated
  @override
  FormalParameterListImpl get parameters => _parameters;

  @generated
  set parameters(FormalParameterListImpl parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @generated
  @override
  TypeAnnotationImpl? get returnType => _returnType;

  @generated
  set returnType(TypeAnnotationImpl? returnType) {
    _returnType = _becomeParentOf(returnType);
  }

  @generated
  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  @generated
  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('returnType', returnType)
    ..addToken('functionKeyword', functionKeyword)
    ..addNode('typeParameters', typeParameters)
    ..addNode('parameters', parameters)
    ..addToken('question', question);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitGenericFunctionType(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    returnType?.accept(visitor);
    typeParameters?.accept(visitor);
    parameters.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (returnType case var returnType?) {
      if (returnType._containsOffset(rangeOffset, rangeEnd)) {
        return returnType;
      }
    }
    if (typeParameters case var typeParameters?) {
      if (typeParameters._containsOffset(rangeOffset, rangeEnd)) {
        return typeParameters;
      }
    }
    if (parameters._containsOffset(rangeOffset, rangeEnd)) {
      return parameters;
    }
    return null;
  }
}

/// A generic type alias.
///
///    functionTypeAlias ::=
///        'typedef' [SimpleIdentifier] [TypeParameterList]? =
///        [FunctionType] ';'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class GenericTypeAlias implements TypeAlias {
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('augmentKeyword', isSuper: true),
    GenerateNodeProperty('typedefKeyword', isSuper: true),
    GenerateNodeProperty('name', isSuper: true),
    GenerateNodeProperty('typeParameters'),
    GenerateNodeProperty('equals'),
    GenerateNodeProperty('type'),
    GenerateNodeProperty('semicolon', isSuper: true),
  ],
)
final class GenericTypeAliasImpl extends TypeAliasImpl
    with AstNodeWithNameScopeMixin
    implements GenericTypeAlias {
  @generated
  TypeParameterListImpl? _typeParameters;

  @generated
  @override
  final Token equals;

  @generated
  TypeAnnotationImpl _type;

  @override
  TypeAliasFragmentImpl? declaredFragment;

  @generated
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
  }) : _typeParameters = typeParameters,
       _type = type {
    _becomeParentOf(typeParameters);
    _becomeParentOf(type);
  }

  @generated
  @override
  Token get endToken {
    return semicolon;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (augmentKeyword case var augmentKeyword?) {
      return augmentKeyword;
    }
    return typedefKeyword;
  }

  @override
  GenericFunctionType? get functionType {
    var type = _type;
    return type is GenericFunctionTypeImpl ? type : null;
  }

  set functionType(GenericFunctionType? functionType) {
    _type = _becomeParentOf(functionType as GenericFunctionTypeImpl?)!;
  }

  @generated
  @override
  TypeAnnotationImpl get type => _type;

  @generated
  set type(TypeAnnotationImpl type) {
    _type = _becomeParentOf(type);
  }

  @generated
  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  @generated
  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('augmentKeyword', augmentKeyword)
    ..addToken('typedefKeyword', typedefKeyword)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addToken('equals', equals)
    ..addNode('type', type)
    ..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitGenericTypeAlias(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    typeParameters?.accept(visitor);
    type.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (typeParameters case var typeParameters?) {
      if (typeParameters._containsOffset(rangeOffset, rangeEnd)) {
        return typeParameters;
      }
    }
    if (type._containsOffset(rangeOffset, rangeEnd)) {
      return type;
    }
    return null;
  }
}

/// The pattern with an optional [WhenClause].
///
///    guardedPattern ::=
///        [DartPattern] [WhenClause]?
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class GuardedPattern implements AstNode {
  /// The pattern controlling whether the statements are executed.
  DartPattern get pattern;

  /// The clause controlling whether the statements are be executed.
  WhenClause? get whenClause;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('pattern'),
    GenerateNodeProperty('whenClause'),
  ],
)
final class GuardedPatternImpl extends AstNodeImpl implements GuardedPattern {
  @generated
  DartPatternImpl _pattern;

  @generated
  WhenClauseImpl? _whenClause;

  /// Variables declared in [pattern], available in [whenClause] guard, and
  /// to the `ifTrue` node.
  late Map<String, PatternVariableElementImpl> variables;

  @generated
  GuardedPatternImpl({
    required DartPatternImpl pattern,
    required WhenClauseImpl? whenClause,
  }) : _pattern = pattern,
       _whenClause = whenClause {
    _becomeParentOf(pattern);
    _becomeParentOf(whenClause);
  }

  @generated
  @override
  Token get beginToken {
    return pattern.beginToken;
  }

  @generated
  @override
  Token get endToken {
    if (whenClause case var whenClause?) {
      return whenClause.endToken;
    }
    return pattern.endToken;
  }

  @generated
  @override
  DartPatternImpl get pattern => _pattern;

  @generated
  set pattern(DartPatternImpl pattern) {
    _pattern = _becomeParentOf(pattern);
  }

  @generated
  @override
  WhenClauseImpl? get whenClause => _whenClause;

  @generated
  set whenClause(WhenClauseImpl? whenClause) {
    _whenClause = _becomeParentOf(whenClause);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('pattern', pattern)
    ..addNode('whenClause', whenClause);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitGuardedPattern(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    pattern.accept(visitor);
    whenClause?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (pattern._containsOffset(rangeOffset, rangeEnd)) {
      return pattern;
    }
    if (whenClause case var whenClause?) {
      if (whenClause._containsOffset(rangeOffset, rangeEnd)) {
        return whenClause;
      }
    }
    return null;
  }
}

/// A combinator that restricts the names being imported to those that aren't
/// in a given list.
///
///    hideCombinator ::=
///        'hide' [SimpleIdentifier] (',' [SimpleIdentifier])*
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class HideCombinator implements Combinator {
  /// The list of names from the library that are hidden by this combinator.
  NodeList<SimpleIdentifier> get hiddenNames;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('keyword', isSuper: true),
    GenerateNodeProperty('hiddenNames'),
  ],
)
final class HideCombinatorImpl extends CombinatorImpl
    implements HideCombinator {
  @generated
  @override
  final NodeListImpl<SimpleIdentifierImpl> hiddenNames = NodeListImpl._();

  @generated
  HideCombinatorImpl({
    required super.keyword,
    required List<SimpleIdentifierImpl> hiddenNames,
  }) {
    this.hiddenNames._initialize(this, hiddenNames);
  }

  @generated
  @override
  Token get beginToken {
    return keyword;
  }

  @generated
  @override
  Token get endToken {
    if (hiddenNames.endToken case var result?) {
      return result;
    }
    return keyword;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('keyword', keyword)
    ..addNodeList('hiddenNames', hiddenNames);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitHideCombinator(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    hiddenNames.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (hiddenNames._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// A node that represents an identifier.
///
///    identifier ::=
///        [SimpleIdentifier]
///      | [PrefixedIdentifier]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
sealed class Identifier implements Expression, CommentReferableExpression {
  /// The element associated with this identifier based on static type
  /// information.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if this
  /// identifier couldn't be resolved. One example of the latter case is an
  /// identifier that isn't defined within the scope in which it appears.
  Element? get element;

  /// The lexical representation of the identifier.
  String get name;

  /// Returns `true` if the given [name] is visible only within the library in
  /// which it's declared.
  static bool isPrivateName(String name) => name.isNotEmpty && name[0] == "_";
}

sealed class IdentifierImpl extends CommentReferableExpressionImpl
    implements Identifier {
  @override
  bool get isAssignable => true;
}

/// The basic structure of an if element.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class IfElement implements CollectionElement {
  /// The `case` clause used to match a pattern against the [expression].
  CaseClause? get caseClause;

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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('ifKeyword'),
    GenerateNodeProperty('leftParenthesis'),
    GenerateNodeProperty('expression'),
    GenerateNodeProperty('caseClause'),
    GenerateNodeProperty('rightParenthesis'),
    GenerateNodeProperty('thenElement'),
    GenerateNodeProperty('elseKeyword'),
    GenerateNodeProperty('elseElement'),
  ],
)
final class IfElementImpl extends CollectionElementImpl
    implements IfElementOrStatementImpl<CollectionElementImpl>, IfElement {
  @generated
  @override
  final Token ifKeyword;

  @generated
  @override
  final Token leftParenthesis;

  @generated
  ExpressionImpl _expression;

  @generated
  CaseClauseImpl? _caseClause;

  @generated
  @override
  final Token rightParenthesis;

  @generated
  CollectionElementImpl _thenElement;

  @generated
  @override
  final Token? elseKeyword;

  @generated
  CollectionElementImpl? _elseElement;

  @generated
  IfElementImpl({
    required this.ifKeyword,
    required this.leftParenthesis,
    required ExpressionImpl expression,
    required CaseClauseImpl? caseClause,
    required this.rightParenthesis,
    required CollectionElementImpl thenElement,
    required this.elseKeyword,
    required CollectionElementImpl? elseElement,
  }) : _expression = expression,
       _caseClause = caseClause,
       _thenElement = thenElement,
       _elseElement = elseElement {
    _becomeParentOf(expression);
    _becomeParentOf(caseClause);
    _becomeParentOf(thenElement);
    _becomeParentOf(elseElement);
  }

  @generated
  @override
  Token get beginToken {
    return ifKeyword;
  }

  @generated
  @override
  CaseClauseImpl? get caseClause => _caseClause;

  @generated
  set caseClause(CaseClauseImpl? caseClause) {
    _caseClause = _becomeParentOf(caseClause);
  }

  set condition(ExpressionImpl condition) {
    _expression = _becomeParentOf(condition);
  }

  @generated
  @override
  CollectionElementImpl? get elseElement => _elseElement;

  @generated
  set elseElement(CollectionElementImpl? elseElement) {
    _elseElement = _becomeParentOf(elseElement);
  }

  @generated
  @override
  Token get endToken {
    if (elseElement case var elseElement?) {
      return elseElement.endToken;
    }
    if (elseKeyword case var elseKeyword?) {
      return elseKeyword;
    }
    return thenElement.endToken;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  CollectionElementImpl? get ifFalse => elseElement;

  @override
  CollectionElementImpl get ifTrue => thenElement;

  @generated
  @override
  CollectionElementImpl get thenElement => _thenElement;

  @generated
  set thenElement(CollectionElementImpl thenElement) {
    _thenElement = _becomeParentOf(thenElement);
  }

  @generated
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

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitIfElement(this);

  @override
  void resolveElement(
    ResolverVisitor resolver,
    CollectionLiteralContext? context,
  ) {
    resolver.visitIfElement(this, context: context);
    resolver.pushRewrite(null);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
    caseClause?.accept(visitor);
    thenElement.accept(visitor);
    elseElement?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    if (caseClause case var caseClause?) {
      if (caseClause._containsOffset(rangeOffset, rangeEnd)) {
        return caseClause;
      }
    }
    if (thenElement._containsOffset(rangeOffset, rangeEnd)) {
      return thenElement;
    }
    if (elseElement case var elseElement?) {
      if (elseElement._containsOffset(rangeOffset, rangeEnd)) {
        return elseElement;
      }
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class IfStatement implements Statement {
  /// The `case` clause used to match a pattern against the [expression].
  CaseClause? get caseClause;

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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('ifKeyword'),
    GenerateNodeProperty('leftParenthesis'),
    GenerateNodeProperty('expression'),
    GenerateNodeProperty('caseClause'),
    GenerateNodeProperty('rightParenthesis'),
    GenerateNodeProperty('thenStatement'),
    GenerateNodeProperty('elseKeyword'),
    GenerateNodeProperty('elseStatement'),
  ],
)
final class IfStatementImpl extends StatementImpl
    implements IfElementOrStatementImpl<StatementImpl>, IfStatement {
  @generated
  @override
  final Token ifKeyword;

  @generated
  @override
  final Token leftParenthesis;

  @generated
  ExpressionImpl _expression;

  @generated
  CaseClauseImpl? _caseClause;

  @generated
  @override
  final Token rightParenthesis;

  @generated
  StatementImpl _thenStatement;

  @generated
  @override
  final Token? elseKeyword;

  @generated
  StatementImpl? _elseStatement;

  @generated
  IfStatementImpl({
    required this.ifKeyword,
    required this.leftParenthesis,
    required ExpressionImpl expression,
    required CaseClauseImpl? caseClause,
    required this.rightParenthesis,
    required StatementImpl thenStatement,
    required this.elseKeyword,
    required StatementImpl? elseStatement,
  }) : _expression = expression,
       _caseClause = caseClause,
       _thenStatement = thenStatement,
       _elseStatement = elseStatement {
    _becomeParentOf(expression);
    _becomeParentOf(caseClause);
    _becomeParentOf(thenStatement);
    _becomeParentOf(elseStatement);
  }

  @generated
  @override
  Token get beginToken {
    return ifKeyword;
  }

  @generated
  @override
  CaseClauseImpl? get caseClause => _caseClause;

  @generated
  set caseClause(CaseClauseImpl? caseClause) {
    _caseClause = _becomeParentOf(caseClause);
  }

  set condition(ExpressionImpl condition) {
    _expression = _becomeParentOf(condition);
  }

  @generated
  @override
  StatementImpl? get elseStatement => _elseStatement;

  @generated
  set elseStatement(StatementImpl? elseStatement) {
    _elseStatement = _becomeParentOf(elseStatement);
  }

  @generated
  @override
  Token get endToken {
    if (elseStatement case var elseStatement?) {
      return elseStatement.endToken;
    }
    if (elseKeyword case var elseKeyword?) {
      return elseKeyword;
    }
    return thenStatement.endToken;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  StatementImpl? get ifFalse => elseStatement;

  @override
  StatementImpl get ifTrue => thenStatement;

  @generated
  @override
  StatementImpl get thenStatement => _thenStatement;

  @generated
  set thenStatement(StatementImpl thenStatement) {
    _thenStatement = _becomeParentOf(thenStatement);
  }

  @generated
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

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitIfStatement(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
    caseClause?.accept(visitor);
    thenStatement.accept(visitor);
    elseStatement?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    if (caseClause case var caseClause?) {
      if (caseClause._containsOffset(rangeOffset, rangeEnd)) {
        return caseClause;
      }
    }
    if (thenStatement._containsOffset(rangeOffset, rangeEnd)) {
      return thenStatement;
    }
    if (elseStatement case var elseStatement?) {
      if (elseStatement._containsOffset(rangeOffset, rangeEnd)) {
        return elseStatement;
      }
    }
    return null;
  }
}

/// The "implements" clause in an class declaration.
///
///    implementsClause ::=
///        'implements' [NamedType] (',' [NamedType])*
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ImplementsClause implements AstNode {
  /// The token representing the `implements` keyword.
  Token get implementsKeyword;

  /// The list of the interfaces that are being implemented.
  NodeList<NamedType> get interfaces;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('implementsKeyword'),
    GenerateNodeProperty('interfaces'),
  ],
)
final class ImplementsClauseImpl extends AstNodeImpl
    implements ImplementsClause {
  @generated
  @override
  final Token implementsKeyword;

  @generated
  @override
  final NodeListImpl<NamedTypeImpl> interfaces = NodeListImpl._();

  @generated
  ImplementsClauseImpl({
    required this.implementsKeyword,
    required List<NamedTypeImpl> interfaces,
  }) {
    this.interfaces._initialize(this, interfaces);
  }

  @generated
  @override
  Token get beginToken {
    return implementsKeyword;
  }

  @generated
  @override
  Token get endToken {
    if (interfaces.endToken case var result?) {
      return result;
    }
    return implementsKeyword;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('implementsKeyword', implementsKeyword)
    ..addNodeList('interfaces', interfaces);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitImplementsClause(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    interfaces.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (interfaces._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// An expression representing an implicit 'call' method reference.
///
/// Objects of this type aren't produced directly by the parser (because the
/// parser can't tell whether an expression refers to a callable type); they
/// are produced at resolution time.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ImplicitCallReference
    implements MethodReferenceExpression {
  /// The expression from which a `call` method is being referenced.
  Expression get expression;

  /// The type arguments being applied to the tear-off, or `null` if there are
  /// no type arguments.
  TypeArgumentList? get typeArguments;

  /// The actual type arguments being applied to the tear-off, either explicitly
  /// specified in [typeArguments], or inferred.
  ///
  /// An empty list if the 'call' method doesn't have type parameters.
  List<DartType> get typeArgumentTypes;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('expression'),
    GenerateNodeProperty('typeArguments'),
    GenerateNodeProperty('element'),
    GenerateNodeProperty('typeArgumentTypes', type: List<DartType>),
  ],
)
final class ImplicitCallReferenceImpl extends ExpressionImpl
    implements ImplicitCallReference {
  @generated
  ExpressionImpl _expression;

  @generated
  TypeArgumentListImpl? _typeArguments;

  @generated
  @override
  final MethodElement? element;

  @generated
  @override
  final List<DartType> typeArgumentTypes;

  @generated
  ImplicitCallReferenceImpl({
    required ExpressionImpl expression,
    required TypeArgumentListImpl? typeArguments,
    required this.element,
    required this.typeArgumentTypes,
  }) : _expression = expression,
       _typeArguments = typeArguments {
    _becomeParentOf(expression);
    _becomeParentOf(typeArguments);
  }

  @generated
  @override
  Token get beginToken {
    return expression.beginToken;
  }

  @generated
  @override
  Token get endToken {
    if (typeArguments case var typeArguments?) {
      return typeArguments.endToken;
    }
    return expression.endToken;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence =>
      typeArguments == null ? expression.precedence : Precedence.postfix;

  @generated
  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  @generated
  set typeArguments(TypeArgumentListImpl? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('expression', expression)
    ..addNode('typeArguments', typeArguments);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitImplicitCallReference(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitImplicitCallReference(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
    typeArguments?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    if (typeArguments case var typeArguments?) {
      if (typeArguments._containsOffset(rangeOffset, rangeEnd)) {
        return typeArguments;
      }
    }
    return null;
  }
}

/// An import directive.
///
///    importDirective ::=
///        [Annotation] 'import' [StringLiteral] ('as' identifier)?
///        [Combinator]* ';'
///      | [Annotation] 'import' [StringLiteral] 'deferred' 'as' identifier
///        [Combinator]* ';'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ImportDirective implements NamespaceDirective {
  /// The token representing the `as` keyword, or `null` if the imported names
  /// aren't prefixed.
  Token? get asKeyword;

  /// The token representing the `deferred` keyword, or `null` if the imported
  /// URI isn't deferred.
  Token? get deferredKeyword;

  /// The token representing the `import` keyword.
  Token get importKeyword;

  /// Information about this import directive.
  ///
  /// Returns `null` if the AST structure hasn't been resolved.
  LibraryImport? get libraryImport;

  /// The prefix to be used with the imported names, or `null` if the imported
  /// names aren't prefixed.
  SimpleIdentifier? get prefix;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('importKeyword'),
    GenerateNodeProperty('uri', isSuper: true),
    GenerateNodeProperty('configurations', isSuper: true),
    GenerateNodeProperty('deferredKeyword'),
    GenerateNodeProperty('asKeyword'),
    GenerateNodeProperty('prefix'),
    GenerateNodeProperty('combinators', isSuper: true),
    GenerateNodeProperty('semicolon', isSuper: true),
  ],
)
final class ImportDirectiveImpl extends NamespaceDirectiveImpl
    implements ImportDirective {
  @generated
  @override
  final Token importKeyword;

  @generated
  @override
  final Token? deferredKeyword;

  @generated
  @override
  final Token? asKeyword;

  @generated
  SimpleIdentifierImpl? _prefix;

  @override
  LibraryImportImpl? libraryImport;

  @generated
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
    _becomeParentOf(prefix);
  }

  @generated
  @override
  Token get endToken {
    return semicolon;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    return importKeyword;
  }

  @generated
  @override
  SimpleIdentifierImpl? get prefix => _prefix;

  @generated
  set prefix(SimpleIdentifierImpl? prefix) {
    _prefix = _becomeParentOf(prefix);
  }

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('importKeyword', importKeyword)
    ..addNode('uri', uri)
    ..addNodeList('configurations', configurations)
    ..addToken('deferredKeyword', deferredKeyword)
    ..addToken('asKeyword', asKeyword)
    ..addNode('prefix', prefix)
    ..addNodeList('combinators', combinators)
    ..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitImportDirective(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    uri.accept(visitor);
    configurations.accept(visitor);
    prefix?.accept(visitor);
    combinators.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (uri._containsOffset(rangeOffset, rangeEnd)) {
      return uri;
    }
    if (configurations._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    if (prefix case var prefix?) {
      if (prefix._containsOffset(rangeOffset, rangeEnd)) {
        return prefix;
      }
    }
    if (combinators._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ImportPrefixReference implements AstNode {
  /// The element to which [name] is resolved.
  ///
  /// Usually a [PrefixElement], but can be anything in invalid code.
  Element? get element;

  /// The element to which [name] is resolved.
  ///
  /// Usually a [PrefixElement], but can be anything in invalid code.
  @Deprecated('Use element instead')
  Element? get element2;

  /// The name of the referenced import prefix.
  Token get name;

  /// The `.` that separates [name] from the following identifier.
  Token get period;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('name'),
    GenerateNodeProperty('period'),
  ],
)
final class ImportPrefixReferenceImpl extends AstNodeImpl
    implements ImportPrefixReference {
  @generated
  @override
  final Token name;

  @generated
  @override
  final Token period;

  @override
  Element? element;

  @generated
  ImportPrefixReferenceImpl({required this.name, required this.period});

  @generated
  @override
  Token get beginToken {
    return name;
  }

  @Deprecated('Use element instead')
  @override
  Element? get element2 => element;

  @generated
  @override
  Token get endToken {
    return period;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('name', name)
    ..addToken('period', period);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitImportPrefixReference(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {}

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    return null;
  }
}

/// An index expression.
///
///    indexExpression ::=
///        [Expression] '[' [Expression] ']'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class IndexExpression
    implements
        // ignore: deprecated_member_use_from_same_package
        NullShortableExpression,
        MethodReferenceExpression {
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('target'),
    GenerateNodeProperty('period'),
    GenerateNodeProperty('question'),
    GenerateNodeProperty('leftBracket'),
    GenerateNodeProperty('index'),
    GenerateNodeProperty('rightBracket'),
  ],
)
final class IndexExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl, DotShorthandMixin
    implements IndexExpression {
  @generated
  ExpressionImpl? _target;

  @generated
  @override
  final Token? period;

  @generated
  @override
  final Token? question;

  @generated
  @override
  final Token leftBracket;

  @generated
  ExpressionImpl _index;

  @generated
  @override
  final Token rightBracket;

  /// The element associated with the operator based on the static type of the
  /// target, or `null` if the AST structure hasn't been resolved or if the
  /// operator couldn't be resolved.
  @override
  MethodElement? element;

  @generated
  IndexExpressionImpl({
    required ExpressionImpl? target,
    required this.period,
    required this.question,
    required this.leftBracket,
    required ExpressionImpl index,
    required this.rightBracket,
  }) : _target = target,
       _index = index {
    _becomeParentOf(target);
    _becomeParentOf(index);
  }

  @generated
  @override
  Token get beginToken {
    if (target case var target?) {
      return target.beginToken;
    }
    if (period case var period?) {
      return period;
    }
    if (question case var question?) {
      return question;
    }
    return leftBracket;
  }

  @generated
  @override
  Token get endToken {
    return rightBracket;
  }

  @generated
  @override
  ExpressionImpl get index => _index;

  @generated
  set index(ExpressionImpl index) {
    _index = _becomeParentOf(index);
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

  @generated
  @override
  ExpressionImpl? get target => _target;

  @generated
  set target(ExpressionImpl? target) {
    _target = _becomeParentOf(target);
  }

  /// The cascade that contains this [IndexExpression].
  ///
  /// We expect that [isCascaded] is `true`.
  CascadeExpressionImpl get _ancestorCascade {
    assert(isCascaded);
    for (var ancestor = parent!; ; ancestor = ancestor.parent!) {
      if (ancestor is CascadeExpressionImpl) {
        return ancestor;
      }
    }
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('target', target)
    ..addToken('period', period)
    ..addToken('question', question)
    ..addToken('leftBracket', leftBracket)
    ..addNode('index', index)
    ..addToken('rightBracket', rightBracket);

  @override
  AstNode get _nullShortingExtensionCandidate => parent!;

  /// The parameter element representing the parameter to which the value of the
  /// index expression is bound, or `null` if the AST structure is not resolved,
  /// or the function being invoked is not known based on static type
  /// information.
  InternalFormalParameterElement? get _staticParameterElementForIndex {
    Element? element = this.element;

    var parent = this.parent;
    if (parent is CompoundAssignmentExpression) {
      element = parent.writeElement ?? parent.readElement;
    }

    if (element is InternalExecutableElement) {
      var formalParameters = element.formalParameters;
      if (formalParameters.isEmpty) {
        return null;
      }
      return formalParameters[0];
    }
    return null;
  }

  @generated
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

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitIndexExpression(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    target?.accept(visitor);
    index.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (target case var target?) {
      if (target._containsOffset(rangeOffset, rangeEnd)) {
        return target;
      }
    }
    if (index._containsOffset(rangeOffset, rangeEnd)) {
      return index;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class InstanceCreationExpression implements Expression {
  /// The list of arguments to the constructor.
  ArgumentList get argumentList;

  /// The name of the constructor to be invoked.
  ConstructorName get constructorName;

  /// Whether this creation expression will be evaluated at compile-time,
  /// either because the keyword `const` was explicitly provided or because no
  /// keyword was provided and this expression is in a constant context.
  bool get isConst;

  /// The `new` or `const` keyword used to indicate how an object should be
  /// created, or `null` if the keyword isn't explicitly provided.
  Token? get keyword;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('keyword', isTokenFinal: false),
    GenerateNodeProperty('constructorName'),
    GenerateNodeProperty(
      'typeArguments',
      withOverride: false,
      type: _TypeLiteral<TypeArgumentList?>,
    ),
    GenerateNodeProperty('argumentList'),
  ],
)
// TODO(brianwilkerson): Consider making InstanceCreationExpressionImpl extend
// InvocationExpressionImpl. This would probably be a breaking change, but is
// also probably worth it.
final class InstanceCreationExpressionImpl extends ExpressionImpl
    implements InstanceCreationExpression {
  @generated
  @override
  Token? keyword;

  @generated
  ConstructorNameImpl _constructorName;

  @generated
  TypeArgumentListImpl? _typeArguments;

  @generated
  ArgumentListImpl _argumentList;

  @generated
  InstanceCreationExpressionImpl({
    required this.keyword,
    required ConstructorNameImpl constructorName,
    required TypeArgumentListImpl? typeArguments,
    required ArgumentListImpl argumentList,
  }) : _constructorName = constructorName,
       _typeArguments = typeArguments,
       _argumentList = argumentList {
    _becomeParentOf(constructorName);
    _becomeParentOf(typeArguments);
    _becomeParentOf(argumentList);
  }

  @generated
  @override
  ArgumentListImpl get argumentList => _argumentList;

  @generated
  set argumentList(ArgumentListImpl argumentList) {
    _argumentList = _becomeParentOf(argumentList);
  }

  @generated
  @override
  Token get beginToken {
    if (keyword case var keyword?) {
      return keyword;
    }
    return constructorName.beginToken;
  }

  @override
  bool get canBeConst {
    var element = constructorName.element;
    if (element == null || !element.isConst) return false;

    // Ensure that dependencies (e.g. default parameter values) are computed.
    element.baseElement.computeConstantDependencies();

    // Verify that the evaluation of the constructor would not produce an
    // exception.
    var oldKeyword = keyword;
    try {
      keyword = KeywordToken(Keyword.CONST, offset);
      return !hasConstantVerifierError;
    } finally {
      keyword = oldKeyword;
    }
  }

  @generated
  @override
  ConstructorNameImpl get constructorName => _constructorName;

  @generated
  set constructorName(ConstructorNameImpl constructorName) {
    _constructorName = _becomeParentOf(constructorName);
  }

  @generated
  @override
  Token get endToken {
    return argumentList.endToken;
  }

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

  @generated
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  @generated
  set typeArguments(TypeArgumentListImpl? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('keyword', keyword)
    ..addNode('constructorName', constructorName)
    ..addNode('typeArguments', typeArguments)
    ..addNode('argumentList', argumentList);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitInstanceCreationExpression(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitInstanceCreationExpression(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    constructorName.accept(visitor);
    typeArguments?.accept(visitor);
    argumentList.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (constructorName._containsOffset(rangeOffset, rangeEnd)) {
      return constructorName;
    }
    if (typeArguments case var typeArguments?) {
      if (typeArguments._containsOffset(rangeOffset, rangeEnd)) {
        return typeArguments;
      }
    }
    if (argumentList._containsOffset(rangeOffset, rangeEnd)) {
      return argumentList;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class IntegerLiteral implements Literal {
  /// The token representing the literal.
  Token get literal;

  /// The value of the literal, or `null` when [literal] doesn't represent a
  /// valid `int` value, for example because of overflow.
  int? get value;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('literal'),
    GenerateNodeProperty('value'),
  ],
)
final class IntegerLiteralImpl extends LiteralImpl implements IntegerLiteral {
  @generated
  @override
  final Token literal;

  @generated
  @override
  final int? value;

  @generated
  IntegerLiteralImpl({required this.literal, required this.value});

  @generated
  @override
  Token get beginToken {
    return literal;
  }

  @generated
  @override
  Token get endToken {
    return literal;
  }

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

  @generated
  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('literal', literal);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitIntegerLiteral(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitIntegerLiteral(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {}

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
sealed class InterpolationElement implements AstNode {}

sealed class InterpolationElementImpl extends AstNodeImpl
    implements InterpolationElement {}

/// An expression embedded in a string interpolation.
///
///    interpolationExpression ::=
///        '$' [SimpleIdentifier]
///      | '$' '{' [Expression] '}'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('leftBracket'),
    GenerateNodeProperty('expression'),
    GenerateNodeProperty('rightBracket'),
  ],
)
final class InterpolationExpressionImpl extends InterpolationElementImpl
    implements InterpolationExpression {
  @generated
  @override
  final Token leftBracket;

  @generated
  ExpressionImpl _expression;

  @generated
  @override
  final Token? rightBracket;

  @generated
  InterpolationExpressionImpl({
    required this.leftBracket,
    required ExpressionImpl expression,
    required this.rightBracket,
  }) : _expression = expression {
    _becomeParentOf(expression);
  }

  @generated
  @override
  Token get beginToken {
    return leftBracket;
  }

  @generated
  @override
  Token get endToken {
    if (rightBracket case var rightBracket?) {
      return rightBracket;
    }
    return expression.endToken;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftBracket', leftBracket)
    ..addNode('expression', expression)
    ..addToken('rightBracket', rightBracket);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitInterpolationExpression(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    return null;
  }
}

/// A non-empty substring of an interpolated string.
///
///    interpolationString ::=
///        characters
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('contents'),
    GenerateNodeProperty('value'),
  ],
)
final class InterpolationStringImpl extends InterpolationElementImpl
    implements InterpolationString {
  @generated
  @override
  final Token contents;

  @generated
  @override
  final String value;

  @generated
  InterpolationStringImpl({required this.contents, required this.value});

  @generated
  @override
  Token get beginToken {
    return contents;
  }

  @override
  int get contentsEnd => offset + _lexemeHelper.end;

  @override
  int get contentsOffset => contents.offset + _lexemeHelper.start;

  @generated
  @override
  Token get endToken {
    return contents;
  }

  @override
  StringInterpolation get parent => super.parent as StringInterpolation;

  @generated
  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('contents', contents);

  StringLexemeHelper get _lexemeHelper {
    String lexeme = contents.lexeme;
    return StringLexemeHelper(
      lexeme,
      identical(this, parent.elements.first),
      identical(this, parent.elements.last),
    );
  }

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitInterpolationString(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {}

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    return null;
  }
}

/// The invocation of a function or method.
///
/// This will either be a [FunctionExpressionInvocation], a [MethodInvocation],
/// a [DotShorthandConstructorInvocation], or a [DotShorthandInvocation].
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class InvocationExpression implements Expression {
  /// The list of arguments to the method.
  ArgumentList get argumentList;

  /// The expression that identifies the function or method being invoked.
  ///
  /// For example:
  ///
  /// ```dart
  /// (o.m)<TArgs>(args); // target is `o.m`
  /// o.m<TArgs>(args);   // target is `m`
  /// ```
  ///
  /// In either case, the `function.staticType` is the [staticInvokeType] before
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
  List<TypeImpl>? typeArgumentTypes;

  @override
  TypeImpl? staticInvokeType;

  /// Initializes a newly created invocation.
  InvocationExpressionImpl({
    required TypeArgumentListImpl? typeArguments,
    required ArgumentListImpl argumentList,
  }) : _typeArguments = typeArguments,
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('expression'),
    GenerateNodeProperty('isOperator'),
    GenerateNodeProperty('notOperator'),
    GenerateNodeProperty('type'),
  ],
)
final class IsExpressionImpl extends ExpressionImpl implements IsExpression {
  @generated
  ExpressionImpl _expression;

  @generated
  @override
  final Token isOperator;

  @generated
  @override
  final Token? notOperator;

  @generated
  TypeAnnotationImpl _type;

  @generated
  IsExpressionImpl({
    required ExpressionImpl expression,
    required this.isOperator,
    required this.notOperator,
    required TypeAnnotationImpl type,
  }) : _expression = expression,
       _type = type {
    _becomeParentOf(expression);
    _becomeParentOf(type);
  }

  @generated
  @override
  Token get beginToken {
    return expression.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return type.endToken;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.relational;

  @generated
  @override
  TypeAnnotationImpl get type => _type;

  @generated
  set type(TypeAnnotationImpl type) {
    _type = _becomeParentOf(type);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('expression', expression)
    ..addToken('isOperator', isOperator)
    ..addToken('notOperator', notOperator)
    ..addNode('type', type);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitIsExpression(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitIsExpression(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
    type.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    if (type._containsOffset(rangeOffset, rangeEnd)) {
      return type;
    }
    return null;
  }
}

/// A label on either a [LabeledStatement] or a [NamedExpression].
///
///    label ::=
///        [SimpleIdentifier] ':'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class Label implements AstNode {
  /// The colon that separates the label from the statement.
  Token get colon;

  /// The fragment declared by this declaration.
  ///
  /// Returns `null` if the AST structure hasn't been resolved.
  LabelFragment? get declaredFragment;

  /// The label being associated with the statement.
  SimpleIdentifier get label;
}

/// A statement that has a label associated with them.
///
///    labeledStatement ::=
///       [Label]+ [Statement]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class LabeledStatement implements Statement {
  /// The labels being associated with the statement.
  NodeList<Label> get labels;

  /// The statement with which the labels are being associated.
  Statement get statement;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('labels'),
    GenerateNodeProperty('statement'),
  ],
)
final class LabeledStatementImpl extends StatementImpl
    implements LabeledStatement {
  @generated
  @override
  final NodeListImpl<LabelImpl> labels = NodeListImpl._();

  @generated
  StatementImpl _statement;

  @generated
  LabeledStatementImpl({
    required List<LabelImpl> labels,
    required StatementImpl statement,
  }) : _statement = statement {
    this.labels._initialize(this, labels);
    _becomeParentOf(statement);
  }

  @generated
  @override
  Token get beginToken {
    if (labels.beginToken case var result?) {
      return result;
    }
    return statement.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return statement.endToken;
  }

  @generated
  @override
  StatementImpl get statement => _statement;

  @generated
  set statement(StatementImpl statement) {
    _statement = _becomeParentOf(statement);
  }

  @override
  StatementImpl get unlabeled => _statement.unlabeled;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNodeList('labels', labels)
    ..addNode('statement', statement);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitLabeledStatement(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    labels.accept(visitor);
    statement.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (labels._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    if (statement._containsOffset(rangeOffset, rangeEnd)) {
      return statement;
    }
    return null;
  }
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('label'),
    GenerateNodeProperty('colon'),
  ],
)
final class LabelImpl extends AstNodeImpl implements Label {
  @generated
  SimpleIdentifierImpl _label;

  @generated
  @override
  final Token colon;

  @generated
  LabelImpl({required SimpleIdentifierImpl label, required this.colon})
    : _label = label {
    _becomeParentOf(label);
  }

  @generated
  @override
  Token get beginToken {
    return label.beginToken;
  }

  @override
  LabelFragmentImpl? get declaredFragment =>
      (label.element as LabelElementImpl?)?.firstFragment;

  @generated
  @override
  Token get endToken {
    return colon;
  }

  @generated
  @override
  SimpleIdentifierImpl get label => _label;

  @generated
  set label(SimpleIdentifierImpl label) {
    _label = _becomeParentOf(label);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('label', label)
    ..addToken('colon', colon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitLabel(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    label.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (label._containsOffset(rangeOffset, rangeEnd)) {
      return label;
    }
    return null;
  }
}

/// A library directive.
///
///    libraryDirective ::=
///        [Annotation] 'library' [LibraryIdentifier]? ';'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class LibraryDirective implements Directive {
  /// The element associated with this directive.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if this
  /// directive couldn't be resolved.
  LibraryElement? get element;

  /// The element associated with this directive.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if this
  /// directive couldn't be resolved.
  @Deprecated('Use element instead')
  LibraryElement? get element2;

  /// The token representing the `library` keyword.
  Token get libraryKeyword;

  /// The name of the library being defined.
  LibraryIdentifier? get name;

  /// The name of the library being defined.
  @Deprecated('Use name instead')
  LibraryIdentifier? get name2;

  /// The semicolon terminating the directive.
  Token get semicolon;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('libraryKeyword'),
    GenerateNodeProperty('name'),
    GenerateNodeProperty('semicolon'),
  ],
)
final class LibraryDirectiveImpl extends DirectiveImpl
    implements LibraryDirective {
  @generated
  @override
  final Token libraryKeyword;

  @generated
  LibraryIdentifierImpl? _name;

  @generated
  @override
  final Token semicolon;

  @override
  LibraryElementImpl? element;

  @generated
  LibraryDirectiveImpl({
    required super.comment,
    required super.metadata,
    required this.libraryKeyword,
    required LibraryIdentifierImpl? name,
    required this.semicolon,
  }) : _name = name {
    _becomeParentOf(name);
  }

  @Deprecated('Use element instead')
  @override
  LibraryElementImpl? get element2 => element;

  @generated
  @override
  Token get endToken {
    return semicolon;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    return libraryKeyword;
  }

  @generated
  @override
  LibraryIdentifierImpl? get name => _name;

  @generated
  set name(LibraryIdentifierImpl? name) {
    _name = _becomeParentOf(name);
  }

  @Deprecated('Use name instead')
  @override
  LibraryIdentifierImpl? get name2 => name;

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('libraryKeyword', libraryKeyword)
    ..addNode('name', name)
    ..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitLibraryDirective(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    name?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (name case var name?) {
      if (name._containsOffset(rangeOffset, rangeEnd)) {
        return name;
      }
    }
    return null;
  }
}

/// The identifier for a library.
///
///    libraryIdentifier ::=
///        [SimpleIdentifier] ('.' [SimpleIdentifier])*
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class LibraryIdentifier implements Identifier {
  /// The components of the identifier.
  NodeList<SimpleIdentifier> get components;
}

@GenerateNodeImpl(childEntitiesOrder: [GenerateNodeProperty('components')])
final class LibraryIdentifierImpl extends IdentifierImpl
    implements LibraryIdentifier {
  @generated
  @override
  final NodeListImpl<SimpleIdentifierImpl> components = NodeListImpl._();

  @generated
  LibraryIdentifierImpl({required List<SimpleIdentifierImpl> components}) {
    this.components._initialize(this, components);
  }

  @generated
  @override
  Token get beginToken {
    if (components.beginToken case var result?) {
      return result;
    }
    throw StateError('Expected at least one non-null');
  }

  @override
  Element? get element => null;

  @generated
  @override
  Token get endToken {
    if (components.endToken case var result?) {
      return result;
    }
    throw StateError('Expected at least one non-null');
  }

  @override
  String get name {
    StringBuffer buffer = StringBuffer();
    bool needsPeriod = false;
    int length = components.length;
    for (int i = 0; i < length; i++) {
      SimpleIdentifier identifier = components[i];
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

  @generated
  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addNodeList('components', components);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitLibraryIdentifier(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitLibraryIdentifier(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    components.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (components._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// A list literal.
///
///    listLiteral ::=
///        'const'? [TypeAnnotationList]? '[' elements? ']'
///
///    elements ::=
///        [CollectionElement] (',' [CollectionElement])* ','?
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ListLiteral implements TypedLiteral {
  /// The syntactic elements used to compute the elements of the list.
  NodeList<CollectionElement> get elements;

  /// The left square bracket.
  Token get leftBracket;

  /// The right square bracket.
  Token get rightBracket;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('constKeyword', isSuper: true),
    GenerateNodeProperty('typeArguments', isSuper: true),
    GenerateNodeProperty('leftBracket'),
    GenerateNodeProperty('elements', isNodeListFinal: false),
    GenerateNodeProperty('rightBracket'),
  ],
)
final class ListLiteralImpl extends TypedLiteralImpl implements ListLiteral {
  @generated
  @override
  final Token leftBracket;

  @generated
  @override
  NodeListImpl<CollectionElementImpl> elements = NodeListImpl._();

  @generated
  @override
  final Token rightBracket;

  @generated
  ListLiteralImpl({
    required super.constKeyword,
    required super.typeArguments,
    required this.leftBracket,
    required List<CollectionElementImpl> elements,
    required this.rightBracket,
  }) {
    this.elements._initialize(this, elements);
  }

  @generated
  @override
  Token get beginToken {
    if (constKeyword case var constKeyword?) {
      return constKeyword;
    }
    if (typeArguments case var typeArguments?) {
      return typeArguments.beginToken;
    }
    return leftBracket;
  }

  @generated
  @override
  Token get endToken {
    return rightBracket;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('constKeyword', constKeyword)
    ..addNode('typeArguments', typeArguments)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('elements', elements)
    ..addToken('rightBracket', rightBracket);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitListLiteral(this);

  void addElements(List<CollectionElementImpl> moreElements) {
    elements = NodeListImpl._()
      .._initialize(this, [...elements, ...moreElements]);
    AstNodeImpl.linkNodeTokens(this);
  }

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitListLiteral(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    typeArguments?.accept(visitor);
    elements.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (typeArguments case var typeArguments?) {
      if (typeArguments._containsOffset(rangeOffset, rangeEnd)) {
        return typeArguments;
      }
    }
    if (elements._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// A list pattern.
///
///    listPattern ::=
///        [TypeArgumentList]? '[' [DartPattern] (',' [DartPattern])* ','? ']'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
sealed class ListPatternElement implements AstNode {}

abstract final class ListPatternElementImpl
    implements AstNodeImpl, ListPatternElement {}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('typeArguments'),
    GenerateNodeProperty('leftBracket'),
    GenerateNodeProperty('elements'),
    GenerateNodeProperty('rightBracket'),
  ],
)
final class ListPatternImpl extends DartPatternImpl implements ListPattern {
  @generated
  TypeArgumentListImpl? _typeArguments;

  @generated
  @override
  final Token leftBracket;

  @generated
  @override
  final NodeListImpl<ListPatternElementImpl> elements = NodeListImpl._();

  @generated
  @override
  final Token rightBracket;

  @override
  TypeImpl? requiredType;

  @generated
  ListPatternImpl({
    required TypeArgumentListImpl? typeArguments,
    required this.leftBracket,
    required List<ListPatternElementImpl> elements,
    required this.rightBracket,
  }) : _typeArguments = typeArguments {
    _becomeParentOf(typeArguments);
    this.elements._initialize(this, elements);
  }

  @generated
  @override
  Token get beginToken {
    if (typeArguments case var typeArguments?) {
      return typeArguments.beginToken;
    }
    return leftBracket;
  }

  @generated
  @override
  Token get endToken {
    return rightBracket;
  }

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @generated
  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  @generated
  set typeArguments(TypeArgumentListImpl? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('typeArguments', typeArguments)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('elements', elements)
    ..addToken('rightBracket', rightBracket);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitListPattern(this);

  @override
  TypeImpl computePatternSchema(ResolverVisitor resolverVisitor) {
    var elementType = typeArguments?.arguments.elementAtOrNull(0)?.typeOrThrow;
    return resolverVisitor
        .analyzeListPatternSchema(
          elementType: elementType?.wrapSharedTypeView(),
          elements: elements,
        )
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    inferenceLogWriter?.enterPattern(this);
    var analysisResult = resolverVisitor.listPatternResolver.resolve(
      node: this,
      context: context,
    );
    inferenceLogWriter?.exitPattern(this);
    return analysisResult;
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    typeArguments?.accept(visitor);
    elements.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (typeArguments case var typeArguments?) {
      if (typeArguments._containsOffset(rangeOffset, rangeEnd)) {
        return typeArguments;
      }
    }
    if (elements._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
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
///      | [RecordLiteral]
///      | [SetOrMapLiteral]
///      | [StringLiteral]
///      | [SymbolLiteral]
///      | [TypedLiteral]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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
  final Set<VariableElement> potentiallyMutatedInScope = {};
}

/// A logical-and pattern.
///
///    logicalAndPattern ::=
///        [DartPattern] '&&' [DartPattern]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class LogicalAndPattern implements DartPattern {
  /// The left sub-pattern.
  DartPattern get leftOperand;

  /// The `&&` operator.
  Token get operator;

  /// The right sub-pattern.
  DartPattern get rightOperand;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('leftOperand'),
    GenerateNodeProperty('operator'),
    GenerateNodeProperty('rightOperand'),
  ],
)
final class LogicalAndPatternImpl extends DartPatternImpl
    implements LogicalAndPattern {
  @generated
  DartPatternImpl _leftOperand;

  @generated
  @override
  final Token operator;

  @generated
  DartPatternImpl _rightOperand;

  @generated
  LogicalAndPatternImpl({
    required DartPatternImpl leftOperand,
    required this.operator,
    required DartPatternImpl rightOperand,
  }) : _leftOperand = leftOperand,
       _rightOperand = rightOperand {
    _becomeParentOf(leftOperand);
    _becomeParentOf(rightOperand);
  }

  @generated
  @override
  Token get beginToken {
    return leftOperand.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return rightOperand.endToken;
  }

  @generated
  @override
  DartPatternImpl get leftOperand => _leftOperand;

  @generated
  set leftOperand(DartPatternImpl leftOperand) {
    _leftOperand = _becomeParentOf(leftOperand);
  }

  @override
  PatternPrecedence get precedence => PatternPrecedence.logicalAnd;

  @generated
  @override
  DartPatternImpl get rightOperand => _rightOperand;

  @generated
  set rightOperand(DartPatternImpl rightOperand) {
    _rightOperand = _becomeParentOf(rightOperand);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('leftOperand', leftOperand)
    ..addToken('operator', operator)
    ..addNode('rightOperand', rightOperand);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitLogicalAndPattern(this);

  @override
  TypeImpl computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor
        .analyzeLogicalAndPatternSchema(leftOperand, rightOperand)
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    inferenceLogWriter?.enterPattern(this);
    var analysisResult = resolverVisitor.analyzeLogicalAndPattern(
      context,
      this,
      leftOperand,
      rightOperand,
    );
    inferenceLogWriter?.exitPattern(this);
    return analysisResult;
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    leftOperand.accept(visitor);
    rightOperand.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (leftOperand._containsOffset(rangeOffset, rangeEnd)) {
      return leftOperand;
    }
    if (rightOperand._containsOffset(rangeOffset, rangeEnd)) {
      return rightOperand;
    }
    return null;
  }
}

/// A logical-or pattern.
///
///    logicalOrPattern ::=
///        [DartPattern] '||' [DartPattern]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class LogicalOrPattern implements DartPattern {
  /// The left sub-pattern.
  DartPattern get leftOperand;

  /// The `||` operator.
  Token get operator;

  /// The right sub-pattern.
  DartPattern get rightOperand;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('leftOperand'),
    GenerateNodeProperty('operator'),
    GenerateNodeProperty('rightOperand'),
  ],
)
final class LogicalOrPatternImpl extends DartPatternImpl
    implements LogicalOrPattern {
  @generated
  DartPatternImpl _leftOperand;

  @generated
  @override
  final Token operator;

  @generated
  DartPatternImpl _rightOperand;

  @generated
  LogicalOrPatternImpl({
    required DartPatternImpl leftOperand,
    required this.operator,
    required DartPatternImpl rightOperand,
  }) : _leftOperand = leftOperand,
       _rightOperand = rightOperand {
    _becomeParentOf(leftOperand);
    _becomeParentOf(rightOperand);
  }

  @generated
  @override
  Token get beginToken {
    return leftOperand.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return rightOperand.endToken;
  }

  @generated
  @override
  DartPatternImpl get leftOperand => _leftOperand;

  @generated
  set leftOperand(DartPatternImpl leftOperand) {
    _leftOperand = _becomeParentOf(leftOperand);
  }

  @override
  PatternPrecedence get precedence => PatternPrecedence.logicalOr;

  @generated
  @override
  DartPatternImpl get rightOperand => _rightOperand;

  @generated
  set rightOperand(DartPatternImpl rightOperand) {
    _rightOperand = _becomeParentOf(rightOperand);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('leftOperand', leftOperand)
    ..addToken('operator', operator)
    ..addNode('rightOperand', rightOperand);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitLogicalOrPattern(this);

  @override
  TypeImpl computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor
        .analyzeLogicalOrPatternSchema(leftOperand, rightOperand)
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    inferenceLogWriter?.enterPattern(this);
    var analysisResult = resolverVisitor.analyzeLogicalOrPattern(
      context,
      this,
      leftOperand,
      rightOperand,
    );
    resolverVisitor.nullSafetyDeadCodeVerifier.flowEnd(rightOperand);
    inferenceLogWriter?.exitPattern(this);
    return analysisResult;
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    leftOperand.accept(visitor);
    rightOperand.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (leftOperand._containsOffset(rangeOffset, rangeEnd)) {
      return leftOperand;
    }
    if (rightOperand._containsOffset(rangeOffset, rangeEnd)) {
      return rightOperand;
    }
    return null;
  }
}

/// A single key/value pair in a map literal.
///
///    mapLiteralEntry ::=
///        '?'? [Expression] ':' '?'? [Expression]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('keyQuestion'),
    GenerateNodeProperty('key'),
    GenerateNodeProperty('separator'),
    GenerateNodeProperty('valueQuestion'),
    GenerateNodeProperty('value'),
  ],
)
final class MapLiteralEntryImpl extends CollectionElementImpl
    implements MapLiteralEntry {
  @generated
  @override
  final Token? keyQuestion;

  @generated
  ExpressionImpl _key;

  @generated
  @override
  final Token separator;

  @generated
  @override
  final Token? valueQuestion;

  @generated
  ExpressionImpl _value;

  @generated
  MapLiteralEntryImpl({
    required this.keyQuestion,
    required ExpressionImpl key,
    required this.separator,
    required this.valueQuestion,
    required ExpressionImpl value,
  }) : _key = key,
       _value = value {
    _becomeParentOf(key);
    _becomeParentOf(value);
  }

  @generated
  @override
  Token get beginToken {
    if (keyQuestion case var keyQuestion?) {
      return keyQuestion;
    }
    return key.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return value.endToken;
  }

  @generated
  @override
  ExpressionImpl get key => _key;

  @generated
  set key(ExpressionImpl key) {
    _key = _becomeParentOf(key);
  }

  @generated
  @override
  ExpressionImpl get value => _value;

  @generated
  set value(ExpressionImpl value) {
    _value = _becomeParentOf(value);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('keyQuestion', keyQuestion)
    ..addNode('key', key)
    ..addToken('separator', separator)
    ..addToken('valueQuestion', valueQuestion)
    ..addNode('value', value);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMapLiteralEntry(this);

  @override
  void resolveElement(
    ResolverVisitor resolver,
    CollectionLiteralContext? context,
  ) {
    resolver.visitMapLiteralEntry(this, context: context);
    resolver.pushRewrite(null);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    key.accept(visitor);
    value.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (key._containsOffset(rangeOffset, rangeEnd)) {
      return key;
    }
    if (value._containsOffset(rangeOffset, rangeEnd)) {
      return value;
    }
    return null;
  }
}

/// A map pattern.
///
///    mapPattern ::=
///        [TypeArgumentList]? '{' [MapPatternEntry] (',' [MapPatternEntry])*
///        ','? '}'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
sealed class MapPatternElement implements AstNode {}

sealed class MapPatternElementImpl implements AstNodeImpl, MapPatternElement {}

/// An entry in a map pattern.
///
///    mapPatternEntry ::=
///        [Expression] ':' [DartPattern]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class MapPatternEntry implements AstNode, MapPatternElement {
  /// The expression computing the key of the entry to be matched.
  Expression get key;

  /// The colon that separates the key from the value.
  Token get separator;

  /// The pattern used to match the value.
  DartPattern get value;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('key'),
    GenerateNodeProperty('separator'),
    GenerateNodeProperty('value'),
  ],
)
final class MapPatternEntryImpl extends AstNodeImpl
    implements MapPatternElementImpl, MapPatternEntry {
  @generated
  ExpressionImpl _key;

  @generated
  @override
  final Token separator;

  @generated
  DartPatternImpl _value;

  @generated
  MapPatternEntryImpl({
    required ExpressionImpl key,
    required this.separator,
    required DartPatternImpl value,
  }) : _key = key,
       _value = value {
    _becomeParentOf(key);
    _becomeParentOf(value);
  }

  @generated
  @override
  Token get beginToken {
    return key.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return value.endToken;
  }

  @generated
  @override
  ExpressionImpl get key => _key;

  @generated
  set key(ExpressionImpl key) {
    _key = _becomeParentOf(key);
  }

  @generated
  @override
  DartPatternImpl get value => _value;

  @generated
  set value(DartPatternImpl value) {
    _value = _becomeParentOf(value);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('key', key)
    ..addToken('separator', separator)
    ..addNode('value', value);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMapPatternEntry(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    key.accept(visitor);
    value.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (key._containsOffset(rangeOffset, rangeEnd)) {
      return key;
    }
    if (value._containsOffset(rangeOffset, rangeEnd)) {
      return value;
    }
    return null;
  }
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('typeArguments'),
    GenerateNodeProperty('leftBracket'),
    GenerateNodeProperty('elements'),
    GenerateNodeProperty('rightBracket'),
  ],
)
final class MapPatternImpl extends DartPatternImpl implements MapPattern {
  @generated
  TypeArgumentListImpl? _typeArguments;

  @generated
  @override
  final Token leftBracket;

  @generated
  @override
  final NodeListImpl<MapPatternElementImpl> elements = NodeListImpl._();

  @generated
  @override
  final Token rightBracket;

  @override
  TypeImpl? requiredType;

  @generated
  MapPatternImpl({
    required TypeArgumentListImpl? typeArguments,
    required this.leftBracket,
    required List<MapPatternElementImpl> elements,
    required this.rightBracket,
  }) : _typeArguments = typeArguments {
    _becomeParentOf(typeArguments);
    this.elements._initialize(this, elements);
  }

  @generated
  @override
  Token get beginToken {
    if (typeArguments case var typeArguments?) {
      return typeArguments.beginToken;
    }
    return leftBracket;
  }

  @generated
  @override
  Token get endToken {
    return rightBracket;
  }

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @generated
  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  @generated
  set typeArguments(TypeArgumentListImpl? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('typeArguments', typeArguments)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('elements', elements)
    ..addToken('rightBracket', rightBracket);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMapPattern(this);

  @override
  TypeImpl computePatternSchema(ResolverVisitor resolverVisitor) {
    var typeArgumentNodes = this.typeArguments?.arguments;
    ({SharedTypeView keyType, SharedTypeView valueType})? typeArguments;
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
  PatternResult resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    return resolverVisitor.resolveMapPattern(node: this, context: context);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    typeArguments?.accept(visitor);
    elements.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (typeArguments case var typeArguments?) {
      if (typeArguments._containsOffset(rangeOffset, rangeEnd)) {
        return typeArguments;
      }
    }
    if (elements._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class MethodDeclaration implements ClassMember {
  /// The token for the `augment` keyword.
  Token? get augmentKeyword;

  /// The body of the method.
  FunctionBody get body;

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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('augmentKeyword'),
    GenerateNodeProperty('externalKeyword', tokenGroupId: 0),
    GenerateNodeProperty('modifierKeyword', tokenGroupId: 0),
    GenerateNodeProperty('returnType'),
    GenerateNodeProperty('propertyKeyword', tokenGroupId: 1),
    GenerateNodeProperty('operatorKeyword', tokenGroupId: 1),
    GenerateNodeProperty('name'),
    GenerateNodeProperty('typeParameters'),
    GenerateNodeProperty('parameters'),
    GenerateNodeProperty('body'),
  ],
)
final class MethodDeclarationImpl extends ClassMemberImpl
    with AstNodeWithNameScopeMixin
    implements MethodDeclaration {
  @generated
  @override
  final Token? augmentKeyword;

  @generated
  @override
  final Token? externalKeyword;

  @generated
  @override
  final Token? modifierKeyword;

  @generated
  TypeAnnotationImpl? _returnType;

  @generated
  @override
  final Token? propertyKeyword;

  @generated
  @override
  final Token? operatorKeyword;

  @generated
  @override
  final Token name;

  @generated
  TypeParameterListImpl? _typeParameters;

  @generated
  FormalParameterListImpl? _parameters;

  @generated
  FunctionBodyImpl _body;

  @override
  ExecutableFragmentImpl? declaredFragment;

  @generated
  MethodDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
    required this.externalKeyword,
    required this.modifierKeyword,
    required TypeAnnotationImpl? returnType,
    required this.propertyKeyword,
    required this.operatorKeyword,
    required this.name,
    required TypeParameterListImpl? typeParameters,
    required FormalParameterListImpl? parameters,
    required FunctionBodyImpl body,
  }) : _returnType = returnType,
       _typeParameters = typeParameters,
       _parameters = parameters,
       _body = body {
    _becomeParentOf(returnType);
    _becomeParentOf(typeParameters);
    _becomeParentOf(parameters);
    _becomeParentOf(body);
  }

  @generated
  @override
  FunctionBodyImpl get body => _body;

  @generated
  set body(FunctionBodyImpl body) {
    _body = _becomeParentOf(body);
  }

  @generated
  @override
  Token get endToken {
    return body.endToken;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (augmentKeyword case var augmentKeyword?) {
      return augmentKeyword;
    }
    if (Token.lexicallyFirst(externalKeyword, modifierKeyword)
        case var result?) {
      return result;
    }
    if (returnType case var returnType?) {
      return returnType.beginToken;
    }
    if (Token.lexicallyFirst(propertyKeyword, operatorKeyword)
        case var result?) {
      return result;
    }
    return name;
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

  @generated
  @override
  FormalParameterListImpl? get parameters => _parameters;

  @generated
  set parameters(FormalParameterListImpl? parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @generated
  @override
  TypeAnnotationImpl? get returnType => _returnType;

  @generated
  set returnType(TypeAnnotationImpl? returnType) {
    _returnType = _becomeParentOf(returnType);
  }

  @generated
  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  @generated
  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @generated
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

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMethodDeclaration(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    returnType?.accept(visitor);
    typeParameters?.accept(visitor);
    parameters?.accept(visitor);
    body.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (returnType case var returnType?) {
      if (returnType._containsOffset(rangeOffset, rangeEnd)) {
        return returnType;
      }
    }
    if (typeParameters case var typeParameters?) {
      if (typeParameters._containsOffset(rangeOffset, rangeEnd)) {
        return typeParameters;
      }
    }
    if (parameters case var parameters?) {
      if (parameters._containsOffset(rangeOffset, rangeEnd)) {
        return parameters;
      }
    }
    if (body._containsOffset(rangeOffset, rangeEnd)) {
      return body;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class MethodInvocation
    implements
        // ignore: deprecated_member_use_from_same_package
        NullShortableExpression,
        InvocationExpression {
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
  /// null-aware operator (`?.`). In a cascade section this is the cascade
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('target'),
    GenerateNodeProperty('operator', isTokenFinal: false),
    GenerateNodeProperty('methodName'),
    GenerateNodeProperty('typeArguments', isSuper: true),
    GenerateNodeProperty('argumentList', isSuper: true),
  ],
)
final class MethodInvocationImpl extends InvocationExpressionImpl
    with NullShortableExpressionImpl, DotShorthandMixin
    implements MethodInvocation {
  @generated
  ExpressionImpl? _target;

  @generated
  @override
  Token? operator;

  @generated
  SimpleIdentifierImpl _methodName;

  /// The invoke type of the [methodName] if the target element is a getter,
  /// or `null` otherwise.
  DartType? _methodNameType;

  @generated
  MethodInvocationImpl({
    required ExpressionImpl? target,
    required this.operator,
    required SimpleIdentifierImpl methodName,
    required super.typeArguments,
    required super.argumentList,
  }) : _target = target,
       _methodName = methodName {
    _becomeParentOf(target);
    _becomeParentOf(methodName);
  }

  @generated
  @override
  Token get beginToken {
    if (target case var target?) {
      return target.beginToken;
    }
    if (operator case var operator?) {
      return operator;
    }
    return methodName.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return argumentList.endToken;
  }

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

  @generated
  @override
  SimpleIdentifierImpl get methodName => _methodName;

  @generated
  set methodName(SimpleIdentifierImpl methodName) {
    _methodName = _becomeParentOf(methodName);
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

  @generated
  @override
  ExpressionImpl? get target => _target;

  @generated
  set target(ExpressionImpl? target) {
    _target = _becomeParentOf(target);
  }

  /// The cascade that contains this [IndexExpression].
  ///
  /// We expect that [isCascaded] is `true`.
  CascadeExpressionImpl get _ancestorCascade {
    assert(isCascaded);
    for (var ancestor = parent!; ; ancestor = ancestor.parent!) {
      if (ancestor is CascadeExpressionImpl) {
        return ancestor;
      }
    }
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('target', target)
    ..addToken('operator', operator)
    ..addNode('methodName', methodName)
    ..addNode('typeArguments', typeArguments)
    ..addNode('argumentList', argumentList);

  @override
  AstNode? get _nullShortingExtensionCandidate => parent;

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMethodInvocation(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitMethodInvocation(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    target?.accept(visitor);
    methodName.accept(visitor);
    typeArguments?.accept(visitor);
    argumentList.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (target case var target?) {
      if (target._containsOffset(rangeOffset, rangeEnd)) {
        return target;
      }
    }
    if (methodName._containsOffset(rangeOffset, rangeEnd)) {
      return methodName;
    }
    if (typeArguments case var typeArguments?) {
      if (typeArguments._containsOffset(rangeOffset, rangeEnd)) {
        return typeArguments;
      }
    }
    if (argumentList._containsOffset(rangeOffset, rangeEnd)) {
      return argumentList;
    }
    return null;
  }

  @override
  bool _extendsNullShorting(Expression descendant) =>
      identical(descendant, _target);
}

/// An expression that implicitly makes reference to a method.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class MethodReferenceExpression implements Expression {
  /// The element associated with the expression based on the static types.
  ///
  /// Returns`null` if the AST structure hasn't been resolved, or there's no
  /// meaningful element to return. The latter case can occur, for example, when
  /// this is a non-compound assignment expression, or when the method referred
  /// to couldn't be resolved.
  MethodElement? get element;
}

/// The declaration of a mixin.
///
///    mixinDeclaration ::=
///        'base'? 'mixin' name [TypeParameterList]?
///        [OnClause]? [ImplementsClause]? '{' [ClassMember]* '}'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class MixinDeclaration implements NamedCompilationUnitMember {
  /// The `augment` keyword, or `null` if the keyword was absent.
  Token? get augmentKeyword;

  /// The `base` keyword, or `null` if the keyword was absent.
  Token? get baseKeyword;

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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('augmentKeyword'),
    GenerateNodeProperty('baseKeyword'),
    GenerateNodeProperty('mixinKeyword'),
    GenerateNodeProperty('name', isSuper: true),
    GenerateNodeProperty('typeParameters'),
    GenerateNodeProperty('onClause'),
    GenerateNodeProperty('implementsClause'),
    GenerateNodeProperty('leftBracket'),
    GenerateNodeProperty('members'),
    GenerateNodeProperty('rightBracket'),
  ],
)
final class MixinDeclarationImpl extends NamedCompilationUnitMemberImpl
    with AstNodeWithNameScopeMixin
    implements MixinDeclaration {
  @generated
  @override
  final Token? augmentKeyword;

  @generated
  @override
  final Token? baseKeyword;

  @generated
  @override
  final Token mixinKeyword;

  @generated
  TypeParameterListImpl? _typeParameters;

  @generated
  MixinOnClauseImpl? _onClause;

  @generated
  ImplementsClauseImpl? _implementsClause;

  @generated
  @override
  final Token leftBracket;

  @generated
  @override
  final NodeListImpl<ClassMemberImpl> members = NodeListImpl._();

  @generated
  @override
  final Token rightBracket;

  @override
  MixinFragmentImpl? declaredFragment;

  @generated
  MixinDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
    required this.baseKeyword,
    required this.mixinKeyword,
    required super.name,
    required TypeParameterListImpl? typeParameters,
    required MixinOnClauseImpl? onClause,
    required ImplementsClauseImpl? implementsClause,
    required this.leftBracket,
    required List<ClassMemberImpl> members,
    required this.rightBracket,
  }) : _typeParameters = typeParameters,
       _onClause = onClause,
       _implementsClause = implementsClause {
    _becomeParentOf(typeParameters);
    _becomeParentOf(onClause);
    _becomeParentOf(implementsClause);
    this.members._initialize(this, members);
  }

  @generated
  @override
  Token get endToken {
    return rightBracket;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (augmentKeyword case var augmentKeyword?) {
      return augmentKeyword;
    }
    if (baseKeyword case var baseKeyword?) {
      return baseKeyword;
    }
    return mixinKeyword;
  }

  @generated
  @override
  ImplementsClauseImpl? get implementsClause => _implementsClause;

  @generated
  set implementsClause(ImplementsClauseImpl? implementsClause) {
    _implementsClause = _becomeParentOf(implementsClause);
  }

  @generated
  @override
  MixinOnClauseImpl? get onClause => _onClause;

  @generated
  set onClause(MixinOnClauseImpl? onClause) {
    _onClause = _becomeParentOf(onClause);
  }

  @generated
  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  @generated
  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @generated
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

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMixinDeclaration(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    typeParameters?.accept(visitor);
    onClause?.accept(visitor);
    implementsClause?.accept(visitor);
    members.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (typeParameters case var typeParameters?) {
      if (typeParameters._containsOffset(rangeOffset, rangeEnd)) {
        return typeParameters;
      }
    }
    if (onClause case var onClause?) {
      if (onClause._containsOffset(rangeOffset, rangeEnd)) {
        return onClause;
      }
    }
    if (implementsClause case var implementsClause?) {
      if (implementsClause._containsOffset(rangeOffset, rangeEnd)) {
        return implementsClause;
      }
    }
    if (members._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// The "on" clause in a mixin declaration.
///
///    onClause ::=
///        'on' [NamedType] (',' [NamedType])*
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class MixinOnClause implements AstNode {
  /// The token representing the `on` keyword.
  Token get onKeyword;

  /// The list of the classes are superclass constraints for the mixin.
  NodeList<NamedType> get superclassConstraints;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('onKeyword'),
    GenerateNodeProperty('superclassConstraints'),
  ],
)
final class MixinOnClauseImpl extends AstNodeImpl implements MixinOnClause {
  @generated
  @override
  final Token onKeyword;

  @generated
  @override
  final NodeListImpl<NamedTypeImpl> superclassConstraints = NodeListImpl._();

  @generated
  MixinOnClauseImpl({
    required this.onKeyword,
    required List<NamedTypeImpl> superclassConstraints,
  }) {
    this.superclassConstraints._initialize(this, superclassConstraints);
  }

  @generated
  @override
  Token get beginToken {
    return onKeyword;
  }

  @generated
  @override
  Token get endToken {
    if (superclassConstraints.endToken case var result?) {
      return result;
    }
    return onKeyword;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('onKeyword', onKeyword)
    ..addNodeList('superclassConstraints', superclassConstraints);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitMixinOnClause(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    superclassConstraints.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (superclassConstraints._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// A node that declares a single name within the scope of a compilation unit.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class NamedExpression implements Expression {
  /// The element representing the parameter being named by this expression.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if there's no
  /// parameter with the same name as this expression.
  FormalParameterElement? get element;

  /// The element representing the parameter being named by this expression.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if there's no
  /// parameter with the same name as this expression.
  @Deprecated('Use element instead')
  FormalParameterElement? get element2;

  /// The expression with which the name is associated.
  Expression get expression;

  /// The name associated with the expression.
  Label get name;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('name'),
    GenerateNodeProperty('expression'),
  ],
)
final class NamedExpressionImpl extends ExpressionImpl
    implements NamedExpression {
  @generated
  LabelImpl _name;

  @generated
  ExpressionImpl _expression;

  @generated
  NamedExpressionImpl({
    required LabelImpl name,
    required ExpressionImpl expression,
  }) : _name = name,
       _expression = expression {
    _becomeParentOf(name);
    _becomeParentOf(expression);
  }

  @generated
  @override
  Token get beginToken {
    return name.beginToken;
  }

  @override
  InternalFormalParameterElement? get element {
    return _name.label.element?.ifTypeOrNull();
  }

  @Deprecated('Use element instead')
  @override
  InternalFormalParameterElement? get element2 {
    return element;
  }

  @generated
  @override
  Token get endToken {
    return expression.endToken;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @generated
  @override
  LabelImpl get name => _name;

  @generated
  set name(LabelImpl name) {
    _name = _becomeParentOf(name);
  }

  @override
  Precedence get precedence => Precedence.none;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('name', name)
    ..addNode('expression', expression);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNamedExpression(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitNamedExpression(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    name.accept(visitor);
    expression.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (name._containsOffset(rangeOffset, rangeEnd)) {
      return name;
    }
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    return null;
  }
}

/// A named type, which can optionally include type arguments.
///
///    namedType ::=
///        [ImportPrefixReference]? name typeArguments?
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class NamedType implements TypeAnnotation {
  /// The element of [name] considering [importPrefix].
  ///
  /// This could be a [ClassElement], [TypeAliasElement], or other type defining
  /// element.
  ///
  /// Returns `null` if [name] can't be resolved, or there's no element for the
  /// type name, such as for `void`.
  Element? get element;

  /// The element of [name] considering [importPrefix].
  ///
  /// This could be a [ClassElement], [TypeAliasElement], or other type defining
  /// element.
  ///
  /// Returns `null` if [name] can't be resolved, or there's no element for the
  /// type name, such as for `void`.
  @Deprecated('Use element instead')
  Element? get element2;

  /// The optional import prefix before [name].
  ImportPrefixReference? get importPrefix;

  /// Whether this type is a deferred type.
  ///
  /// A deferred type is a type that is referenced through an import prefix
  /// (such as `p.T`), where the prefix is used by a deferred import.
  ///
  /// Returns `false` if the AST structure hasn't been resolved.
  bool get isDeferred;

  /// The name of the type.
  Token get name;

  /// The name of the type.
  @Deprecated('Use name instead')
  Token get name2;

  /// The type being named, or `null` if the AST structure hasn't been resolved,
  /// or if this is part of a [ConstructorReference].
  @override
  DartType? get type;

  /// The type arguments associated with the type, or `null` if there are no
  /// type arguments.
  TypeArgumentList? get typeArguments;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('importPrefix'),
    GenerateNodeProperty('name'),
    GenerateNodeProperty('typeArguments'),
    GenerateNodeProperty('question'),
  ],
)
final class NamedTypeImpl extends TypeAnnotationImpl implements NamedType {
  @generated
  ImportPrefixReferenceImpl? _importPrefix;

  @generated
  @override
  final Token name;

  @generated
  TypeArgumentListImpl? _typeArguments;

  @generated
  @override
  final Token? question;

  @override
  Element? element;

  @override
  TypeImpl? type;

  @generated
  NamedTypeImpl({
    required ImportPrefixReferenceImpl? importPrefix,
    required this.name,
    required TypeArgumentListImpl? typeArguments,
    required this.question,
  }) : _importPrefix = importPrefix,
       _typeArguments = typeArguments {
    _becomeParentOf(importPrefix);
    _becomeParentOf(typeArguments);
  }

  @generated
  @override
  Token get beginToken {
    if (importPrefix case var importPrefix?) {
      return importPrefix.beginToken;
    }
    return name;
  }

  @Deprecated('Use element instead')
  @override
  Element? get element2 => element;

  @generated
  @override
  Token get endToken {
    if (question case var question?) {
      return question;
    }
    if (typeArguments case var typeArguments?) {
      return typeArguments.endToken;
    }
    return name;
  }

  @generated
  @override
  ImportPrefixReferenceImpl? get importPrefix => _importPrefix;

  @generated
  set importPrefix(ImportPrefixReferenceImpl? importPrefix) {
    _importPrefix = _becomeParentOf(importPrefix);
  }

  @override
  bool get isDeferred {
    var importPrefixElement = importPrefix?.element;
    if (importPrefixElement is PrefixElement) {
      return importPrefixElement.fragments.any(
        (fragment) => fragment.isDeferred,
      );
    }
    return false;
  }

  @override
  bool get isSynthetic => name.isSynthetic && typeArguments == null;

  @Deprecated('Use name instead')
  @override
  Token get name2 => name;

  @generated
  @override
  TypeArgumentListImpl? get typeArguments => _typeArguments;

  @generated
  set typeArguments(TypeArgumentListImpl? typeArguments) {
    _typeArguments = _becomeParentOf(typeArguments);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('importPrefix', importPrefix)
    ..addToken('name', name)
    ..addNode('typeArguments', typeArguments)
    ..addToken('question', question);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNamedType(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    importPrefix?.accept(visitor);
    typeArguments?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (importPrefix case var importPrefix?) {
      if (importPrefix._containsOffset(rangeOffset, rangeEnd)) {
        return importPrefix;
      }
    }
    if (typeArguments case var typeArguments?) {
      if (typeArguments._containsOffset(rangeOffset, rangeEnd)) {
        return typeArguments;
      }
    }
    return null;
  }
}

/// A node that represents a directive that impacts the namespace of a library.
///
///    directive ::=
///        [ExportDirective]
///      | [ImportDirective]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class NativeClause implements AstNode {
  /// The name of the native object that implements the class.
  StringLiteral? get name;

  /// The token representing the `native` keyword.
  Token get nativeKeyword;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('nativeKeyword'),
    GenerateNodeProperty('name'),
  ],
)
final class NativeClauseImpl extends AstNodeImpl implements NativeClause {
  @generated
  @override
  final Token nativeKeyword;

  @generated
  StringLiteralImpl? _name;

  @generated
  NativeClauseImpl({
    required this.nativeKeyword,
    required StringLiteralImpl? name,
  }) : _name = name {
    _becomeParentOf(name);
  }

  @generated
  @override
  Token get beginToken {
    return nativeKeyword;
  }

  @generated
  @override
  Token get endToken {
    if (name case var name?) {
      return name.endToken;
    }
    return nativeKeyword;
  }

  @generated
  @override
  StringLiteralImpl? get name => _name;

  @generated
  set name(StringLiteralImpl? name) {
    _name = _becomeParentOf(name);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('nativeKeyword', nativeKeyword)
    ..addNode('name', name);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNativeClause(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    name?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (name case var name?) {
      if (name._containsOffset(rangeOffset, rangeEnd)) {
        return name;
      }
    }
    return null;
  }
}

/// A function body that consists of a native keyword followed by a string
/// literal.
///
///    nativeFunctionBody ::=
///        'native' [SimpleStringLiteral] ';'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class NativeFunctionBody implements FunctionBody {
  /// The token representing 'native' that marks the start of the function body.
  Token get nativeKeyword;

  /// The token representing the semicolon that marks the end of the function
  /// body.
  Token get semicolon;

  /// The string literal representing the string after the 'native' token.
  StringLiteral? get stringLiteral;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('nativeKeyword'),
    GenerateNodeProperty('stringLiteral'),
    GenerateNodeProperty('semicolon'),
  ],
)
final class NativeFunctionBodyImpl extends FunctionBodyImpl
    implements NativeFunctionBody {
  @generated
  @override
  final Token nativeKeyword;

  @generated
  StringLiteralImpl? _stringLiteral;

  @generated
  @override
  final Token semicolon;

  @generated
  NativeFunctionBodyImpl({
    required this.nativeKeyword,
    required StringLiteralImpl? stringLiteral,
    required this.semicolon,
  }) : _stringLiteral = stringLiteral {
    _becomeParentOf(stringLiteral);
  }

  @generated
  @override
  Token get beginToken {
    return nativeKeyword;
  }

  @generated
  @override
  Token get endToken {
    return semicolon;
  }

  @generated
  @override
  StringLiteralImpl? get stringLiteral => _stringLiteral;

  @generated
  set stringLiteral(StringLiteralImpl? stringLiteral) {
    _stringLiteral = _becomeParentOf(stringLiteral);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('nativeKeyword', nativeKeyword)
    ..addNode('stringLiteral', stringLiteral)
    ..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNativeFunctionBody(this);

  @override
  TypeImpl resolve(ResolverVisitor resolver, TypeImpl? imposedType) =>
      resolver.visitNativeFunctionBody(this, imposedType: imposedType);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    stringLiteral?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (stringLiteral case var stringLiteral?) {
      if (stringLiteral._containsOffset(rangeOffset, rangeEnd)) {
        return stringLiteral;
      }
    }
    return null;
  }
}

/// A list of AST nodes that have a common parent.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

final class NodeListImpl<E extends AstNodeImpl>
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

  /// Returns the child of this node that completely contains the range.
  ///
  /// Returns `null` if none of the children contain the range (which means that
  /// this node is the covering node).
  AstNodeImpl? _elementContainingRange(int rangeOffset, int rangeEnd) {
    var left = 0;
    var right = _elements.length - 1;
    while (left <= right) {
      var middle = left + ((right - left) / 2).truncate();
      var candidate = _elements[middle] as AstNodeImpl;
      if (candidate._containsOffset(rangeOffset, rangeEnd)) {
        return candidate;
      }
      if (rangeEnd <= candidate.offset) {
        right = middle - 1;
      } else if (candidate.end <= rangeOffset) {
        left = middle + 1;
      } else {
        return null;
      }
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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
  void visitChildren(AstVisitor visitor) {
    //
    // Note that subclasses are responsible for visiting the identifier because
    // they often need to visit other nodes before visiting the identifier.
    //
    _visitCommentAndAnnotations(visitor);
  }

  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (_documentationComment?._containsOffset(rangeOffset, rangeEnd) ??
        false) {
      return _documentationComment;
    }
    return _metadata._elementContainingRange(rangeOffset, rangeEnd);
  }
}

/// A null-assert pattern.
///
///    nullAssertPattern ::=
///        [DartPattern] '!'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class NullAssertPattern implements DartPattern {
  /// The `!` token.
  Token get operator;

  /// The sub-pattern.
  DartPattern get pattern;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('pattern'),
    GenerateNodeProperty('operator'),
  ],
)
final class NullAssertPatternImpl extends DartPatternImpl
    implements NullAssertPattern {
  @generated
  DartPatternImpl _pattern;

  @generated
  @override
  final Token operator;

  @generated
  NullAssertPatternImpl({
    required DartPatternImpl pattern,
    required this.operator,
  }) : _pattern = pattern {
    _becomeParentOf(pattern);
  }

  @generated
  @override
  Token get beginToken {
    return pattern.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return operator;
  }

  @generated
  @override
  DartPatternImpl get pattern => _pattern;

  @generated
  set pattern(DartPatternImpl pattern) {
    _pattern = _becomeParentOf(pattern);
  }

  @override
  PatternPrecedence get precedence => PatternPrecedence.postfix;

  @override
  VariablePatternImpl? get variablePattern => pattern.variablePattern;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('pattern', pattern)
    ..addToken('operator', operator);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNullAssertPattern(this);

  @override
  TypeImpl computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor
        .analyzeNullCheckOrAssertPatternSchema(pattern, isAssert: true)
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    inferenceLogWriter?.enterPattern(this);
    var analysisResult = resolverVisitor.analyzeNullCheckOrAssertPattern(
      context,
      this,
      pattern,
      isAssert: true,
    );
    inferenceLogWriter?.exitPattern(this);
    return analysisResult;
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    pattern.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (pattern._containsOffset(rangeOffset, rangeEnd)) {
      return pattern;
    }
    return null;
  }
}

/// A null-aware element in a list or set literal.
///
///    <nullAwareExpressionElement> ::= '?' <expression>
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class NullAwareElement implements CollectionElement {
  /// The question mark before the expression.
  Token get question;

  /// The expression computing the value that is associated with the element.
  Expression get value;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('question'),
    GenerateNodeProperty('value'),
  ],
)
final class NullAwareElementImpl extends CollectionElementImpl
    implements NullAwareElement {
  @generated
  @override
  final Token question;

  @generated
  ExpressionImpl _value;

  @generated
  NullAwareElementImpl({required this.question, required ExpressionImpl value})
    : _value = value {
    _becomeParentOf(value);
  }

  @generated
  @override
  Token get beginToken {
    return question;
  }

  @generated
  @override
  Token get endToken {
    return value.endToken;
  }

  @generated
  @override
  ExpressionImpl get value => _value;

  @generated
  set value(ExpressionImpl value) {
    _value = _becomeParentOf(value);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('question', question)
    ..addNode('value', value);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNullAwareElement(this);

  @override
  void resolveElement(
    ResolverVisitor resolver,
    CollectionLiteralContext? context,
  ) {
    resolver.visitNullAwareElement(this, context: context);
    resolver.pushRewrite(null);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    value.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (value._containsOffset(rangeOffset, rangeEnd)) {
      return value;
    }
    return null;
  }
}

/// A null-check pattern.
///
///    nullCheckPattern ::=
///        [DartPattern] '?'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class NullCheckPattern implements DartPattern {
  /// The `?` token.
  Token get operator;

  /// The sub-pattern.
  DartPattern get pattern;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('pattern'),
    GenerateNodeProperty('operator'),
  ],
)
final class NullCheckPatternImpl extends DartPatternImpl
    implements NullCheckPattern {
  @generated
  DartPatternImpl _pattern;

  @generated
  @override
  final Token operator;

  @generated
  NullCheckPatternImpl({
    required DartPatternImpl pattern,
    required this.operator,
  }) : _pattern = pattern {
    _becomeParentOf(pattern);
  }

  @generated
  @override
  Token get beginToken {
    return pattern.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return operator;
  }

  @generated
  @override
  DartPatternImpl get pattern => _pattern;

  @generated
  set pattern(DartPatternImpl pattern) {
    _pattern = _becomeParentOf(pattern);
  }

  @override
  PatternPrecedence get precedence => PatternPrecedence.postfix;

  @override
  VariablePatternImpl? get variablePattern => pattern.variablePattern;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('pattern', pattern)
    ..addToken('operator', operator);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNullCheckPattern(this);

  @override
  TypeImpl computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor
        .analyzeNullCheckOrAssertPatternSchema(pattern, isAssert: false)
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    inferenceLogWriter?.enterPattern(this);
    var analysisResult = resolverVisitor.analyzeNullCheckOrAssertPattern(
      context,
      this,
      pattern,
      isAssert: false,
    );
    inferenceLogWriter?.exitPattern(this);
    return analysisResult;
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    pattern.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (pattern._containsOffset(rangeOffset, rangeEnd)) {
      return pattern;
    }
    return null;
  }
}

/// A null literal expression.
///
///    nullLiteral ::=
///        'null'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class NullLiteral implements Literal {
  /// The token representing the literal.
  Token get literal;
}

@GenerateNodeImpl(childEntitiesOrder: [GenerateNodeProperty('literal')])
final class NullLiteralImpl extends LiteralImpl implements NullLiteral {
  @generated
  @override
  final Token literal;

  @generated
  NullLiteralImpl({required this.literal});

  @generated
  @override
  Token get beginToken {
    return literal;
  }

  @generated
  @override
  Token get endToken {
    return literal;
  }

  @generated
  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('literal', literal);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitNullLiteral(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitNullLiteral(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {}

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    return null;
  }
}

/// Abstract interface for expressions that may participate in null-shorting.
///
/// This is an analyzer-internal interface that was exposed through the public
/// API by mistake. It is deprecated and will be removed in analyzer version
/// 9.0.0.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
@Deprecated('No longer supported.')
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
  @Deprecated('No longer supported.')
  Expression get nullShortingTermination;
}

base mixin NullShortableExpressionImpl
    implements
        // ignore: deprecated_member_use_from_same_package
        NullShortableExpression {
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('type'),
    GenerateNodeProperty('leftParenthesis'),
    GenerateNodeProperty('fields'),
    GenerateNodeProperty('rightParenthesis'),
  ],
)
final class ObjectPatternImpl extends DartPatternImpl implements ObjectPattern {
  @generated
  NamedTypeImpl _type;

  @generated
  @override
  final Token leftParenthesis;

  @generated
  @override
  final NodeListImpl<PatternFieldImpl> fields = NodeListImpl._();

  @generated
  @override
  final Token rightParenthesis;

  @generated
  ObjectPatternImpl({
    required NamedTypeImpl type,
    required this.leftParenthesis,
    required List<PatternFieldImpl> fields,
    required this.rightParenthesis,
  }) : _type = type {
    _becomeParentOf(type);
    this.fields._initialize(this, fields);
  }

  @generated
  @override
  Token get beginToken {
    return type.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return rightParenthesis;
  }

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @generated
  @override
  NamedTypeImpl get type => _type;

  @generated
  set type(NamedTypeImpl type) {
    _type = _becomeParentOf(type);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('type', type)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNodeList('fields', fields)
    ..addToken('rightParenthesis', rightParenthesis);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitObjectPattern(this);

  @override
  TypeImpl computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor
        .analyzeObjectPatternSchema(SharedTypeView(type.typeOrThrow))
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult resolvePattern(
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

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    type.accept(visitor);
    fields.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (type._containsOffset(rangeOffset, rangeEnd)) {
      return type;
    }
    if (fields._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// A parenthesized expression.
///
///    parenthesizedExpression ::=
///        '(' [Expression] ')'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ParenthesizedExpression implements Expression {
  /// The expression within the parentheses.
  Expression get expression;

  /// The left parenthesis.
  Token get leftParenthesis;

  /// The right parenthesis.
  Token get rightParenthesis;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('leftParenthesis'),
    GenerateNodeProperty('expression'),
    GenerateNodeProperty('rightParenthesis'),
  ],
)
final class ParenthesizedExpressionImpl extends ExpressionImpl
    implements ParenthesizedExpression {
  @generated
  @override
  final Token leftParenthesis;

  @generated
  ExpressionImpl _expression;

  @generated
  @override
  final Token rightParenthesis;

  @generated
  ParenthesizedExpressionImpl({
    required this.leftParenthesis,
    required ExpressionImpl expression,
    required this.rightParenthesis,
  }) : _expression = expression {
    _becomeParentOf(expression);
  }

  @generated
  @override
  Token get beginToken {
    return leftParenthesis;
  }

  @generated
  @override
  Token get endToken {
    return rightParenthesis;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
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

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('expression', expression)
    ..addToken('rightParenthesis', rightParenthesis);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitParenthesizedExpression(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitParenthesizedExpression(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    return null;
  }
}

/// A parenthesized pattern.
///
///    parenthesizedPattern ::=
///        '(' [DartPattern] ')'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ParenthesizedPattern implements DartPattern {
  /// The left parenthesis.
  Token get leftParenthesis;

  /// The pattern within the parentheses.
  DartPattern get pattern;

  /// The right parenthesis.
  Token get rightParenthesis;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('leftParenthesis'),
    GenerateNodeProperty('pattern'),
    GenerateNodeProperty('rightParenthesis'),
  ],
)
final class ParenthesizedPatternImpl extends DartPatternImpl
    implements ParenthesizedPattern {
  @generated
  @override
  final Token leftParenthesis;

  @generated
  DartPatternImpl _pattern;

  @generated
  @override
  final Token rightParenthesis;

  @generated
  ParenthesizedPatternImpl({
    required this.leftParenthesis,
    required DartPatternImpl pattern,
    required this.rightParenthesis,
  }) : _pattern = pattern {
    _becomeParentOf(pattern);
  }

  @generated
  @override
  Token get beginToken {
    return leftParenthesis;
  }

  @generated
  @override
  Token get endToken {
    return rightParenthesis;
  }

  @generated
  @override
  DartPatternImpl get pattern => _pattern;

  @generated
  set pattern(DartPatternImpl pattern) {
    _pattern = _becomeParentOf(pattern);
  }

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

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('pattern', pattern)
    ..addToken('rightParenthesis', rightParenthesis);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitParenthesizedPattern(this);

  @override
  TypeImpl computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor
        .dispatchPatternSchema(pattern)
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    inferenceLogWriter?.enterPattern(this);
    var analysisResult = resolverVisitor.dispatchPattern(context, pattern);
    inferenceLogWriter?.exitPattern(this);
    return analysisResult;
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    pattern.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (pattern._containsOffset(rangeOffset, rangeEnd)) {
      return pattern;
    }
    return null;
  }
}

/// A part directive.
///
///    partDirective ::=
///        [Annotation] 'part' [StringLiteral] ';'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class PartDirective implements UriBasedDirective {
  /// The configurations that control which file is actually included.
  NodeList<Configuration> get configurations;

  /// Information about this part directive.
  ///
  /// Returns `null` if the AST structure hasn't been resolved.
  PartInclude? get partInclude;

  /// The token representing the `part` keyword.
  Token get partKeyword;

  /// The semicolon terminating the directive.
  Token get semicolon;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('partKeyword'),
    GenerateNodeProperty('uri', isSuper: true),
    GenerateNodeProperty('configurations'),
    GenerateNodeProperty('semicolon'),
  ],
)
final class PartDirectiveImpl extends UriBasedDirectiveImpl
    implements PartDirective {
  @generated
  @override
  final Token partKeyword;

  @generated
  @override
  final NodeListImpl<ConfigurationImpl> configurations = NodeListImpl._();

  @generated
  @override
  final Token semicolon;

  @override
  PartIncludeImpl? partInclude;

  @generated
  PartDirectiveImpl({
    required super.comment,
    required super.metadata,
    required this.partKeyword,
    required super.uri,
    required List<ConfigurationImpl> configurations,
    required this.semicolon,
  }) {
    this.configurations._initialize(this, configurations);
  }

  @generated
  @override
  Token get endToken {
    return semicolon;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    return partKeyword;
  }

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('partKeyword', partKeyword)
    ..addNode('uri', uri)
    ..addNodeList('configurations', configurations)
    ..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPartDirective(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    uri.accept(visitor);
    configurations.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (uri._containsOffset(rangeOffset, rangeEnd)) {
      return uri;
    }
    if (configurations._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// A part-of directive.
///
///    partOfDirective ::=
///        [Annotation] 'part' 'of' [Identifier] ';'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('partKeyword'),
    GenerateNodeProperty('ofKeyword'),
    GenerateNodeProperty('uri'),
    GenerateNodeProperty('libraryName'),
    GenerateNodeProperty('semicolon'),
  ],
)
final class PartOfDirectiveImpl extends DirectiveImpl
    implements PartOfDirective {
  @generated
  @override
  final Token partKeyword;

  @generated
  @override
  final Token ofKeyword;

  @generated
  StringLiteralImpl? _uri;

  @generated
  LibraryIdentifierImpl? _libraryName;

  @generated
  @override
  final Token semicolon;

  @generated
  PartOfDirectiveImpl({
    required super.comment,
    required super.metadata,
    required this.partKeyword,
    required this.ofKeyword,
    required StringLiteralImpl? uri,
    required LibraryIdentifierImpl? libraryName,
    required this.semicolon,
  }) : _uri = uri,
       _libraryName = libraryName {
    _becomeParentOf(uri);
    _becomeParentOf(libraryName);
  }

  @generated
  @override
  Token get endToken {
    return semicolon;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    return partKeyword;
  }

  @generated
  @override
  LibraryIdentifierImpl? get libraryName => _libraryName;

  @generated
  set libraryName(LibraryIdentifierImpl? libraryName) {
    _libraryName = _becomeParentOf(libraryName);
  }

  @generated
  @override
  StringLiteralImpl? get uri => _uri;

  @generated
  set uri(StringLiteralImpl? uri) {
    _uri = _becomeParentOf(uri);
  }

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('partKeyword', partKeyword)
    ..addToken('ofKeyword', ofKeyword)
    ..addNode('uri', uri)
    ..addNode('libraryName', libraryName)
    ..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPartOfDirective(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    uri?.accept(visitor);
    libraryName?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (uri case var uri?) {
      if (uri._containsOffset(rangeOffset, rangeEnd)) {
        return uri;
      }
    }
    if (libraryName case var libraryName?) {
      if (libraryName._containsOffset(rangeOffset, rangeEnd)) {
        return libraryName;
      }
    }
    return null;
  }
}

/// A pattern assignment.
///
///    patternAssignment ::=
///        [DartPattern] '=' [Expression]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class PatternAssignment implements Expression {
  /// The equal sign separating the pattern from the expression.
  Token get equals;

  /// The expression that is matched by the pattern.
  Expression get expression;

  /// The pattern that matches the expression.
  DartPattern get pattern;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('pattern'),
    GenerateNodeProperty('equals'),
    GenerateNodeProperty('expression'),
  ],
)
final class PatternAssignmentImpl extends ExpressionImpl
    implements PatternAssignment {
  @generated
  DartPatternImpl _pattern;

  @generated
  @override
  final Token equals;

  @generated
  ExpressionImpl _expression;

  /// The pattern type schema, used for downward inference of [expression];
  /// or `null` if the node isn't resolved yet.
  TypeImpl? patternTypeSchema;

  @generated
  PatternAssignmentImpl({
    required DartPatternImpl pattern,
    required this.equals,
    required ExpressionImpl expression,
  }) : _pattern = pattern,
       _expression = expression {
    _becomeParentOf(pattern);
    _becomeParentOf(expression);
  }

  @generated
  @override
  Token get beginToken {
    return pattern.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return expression.endToken;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @generated
  @override
  DartPatternImpl get pattern => _pattern;

  @generated
  set pattern(DartPatternImpl pattern) {
    _pattern = _becomeParentOf(pattern);
  }

  @override
  // TODO(brianwilkerson): Create a new precedence constant for pattern
  //  assignments. The proposal doesn't make the actual value clear.
  Precedence get precedence => Precedence.assignment;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('pattern', pattern)
    ..addToken('equals', equals)
    ..addNode('expression', expression);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPatternAssignment(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitPatternAssignment(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    pattern.accept(visitor);
    expression.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (pattern._containsOffset(rangeOffset, rangeEnd)) {
      return pattern;
    }
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    return null;
  }
}

/// A field in an object or record pattern.
///
///    patternField ::=
///        [PatternFieldName]? [DartPattern]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class PatternField implements AstNode {
  /// The effective name of the field, or `null` if [name] is `null` and
  /// [pattern] isn't a variable pattern.
  ///
  /// The effective name can either be specified explicitly by [name], or
  /// implied by the variable pattern inside [pattern].
  String? get effectiveName;

  /// The element referenced by [effectiveName].
  ///
  /// Returns `null` if the AST structure is not resolved yet.
  ///
  /// Returns non-`null` inside valid [ObjectPattern]s; always returns `null`
  /// inside [RecordPattern]s.
  Element? get element;

  /// The element referenced by [effectiveName].
  ///
  /// Returns `null` if the AST structure is not resolved yet.
  ///
  /// Returns non-`null` inside valid [ObjectPattern]s; always returns `null`
  /// inside [RecordPattern]s.
  @Deprecated('Use element instead')
  Element? get element2;

  /// The name of the field, or `null` if the field is a positional field.
  PatternFieldName? get name;

  /// The pattern used to match the corresponding record field.
  DartPattern get pattern;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('name'),
    GenerateNodeProperty('pattern'),
  ],
)
final class PatternFieldImpl extends AstNodeImpl implements PatternField {
  @generated
  PatternFieldNameImpl? _name;

  @generated
  DartPatternImpl _pattern;

  @override
  Element? element;

  @generated
  PatternFieldImpl({
    required PatternFieldNameImpl? name,
    required DartPatternImpl pattern,
  }) : _name = name,
       _pattern = pattern {
    _becomeParentOf(name);
    _becomeParentOf(pattern);
  }

  @generated
  @override
  Token get beginToken {
    if (name case var name?) {
      return name.beginToken;
    }
    return pattern.beginToken;
  }

  @override
  String? get effectiveName {
    var nameNode = name;
    if (nameNode != null) {
      var nameToken = nameNode.name ?? pattern.variablePattern?.name;
      return nameToken?.lexeme;
    }
    return null;
  }

  @Deprecated('Use element instead')
  @override
  Element? get element2 => element;

  @generated
  @override
  Token get endToken {
    return pattern.endToken;
  }

  @generated
  @override
  PatternFieldNameImpl? get name => _name;

  @generated
  set name(PatternFieldNameImpl? name) {
    _name = _becomeParentOf(name);
  }

  @generated
  @override
  DartPatternImpl get pattern => _pattern;

  @generated
  set pattern(DartPatternImpl pattern) {
    _pattern = _becomeParentOf(pattern);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('name', name)
    ..addNode('pattern', pattern);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPatternField(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    name?.accept(visitor);
    pattern.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (name case var name?) {
      if (name._containsOffset(rangeOffset, rangeEnd)) {
        return name;
      }
    }
    if (pattern._containsOffset(rangeOffset, rangeEnd)) {
      return pattern;
    }
    return null;
  }
}

/// A field name in an object or record pattern field.
///
///    patternFieldName ::=
///        [Token]? ':'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class PatternFieldName implements AstNode {
  /// The colon following the name.
  Token get colon;

  /// The name of the field.
  Token? get name;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('name'),
    GenerateNodeProperty('colon'),
  ],
)
final class PatternFieldNameImpl extends AstNodeImpl
    implements PatternFieldName {
  @generated
  @override
  final Token? name;

  @generated
  @override
  final Token colon;

  @generated
  PatternFieldNameImpl({required this.name, required this.colon});

  @generated
  @override
  Token get beginToken {
    if (name case var name?) {
      return name;
    }
    return colon;
  }

  @generated
  @override
  Token get endToken {
    return colon;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('name', name)
    ..addToken('colon', colon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPatternFieldName(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {}

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    return null;
  }
}

/// A pattern variable declaration.
///
///    patternDeclaration ::=
///        ( 'final' | 'var' ) [DartPattern] '=' [Expression]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('keyword'),
    GenerateNodeProperty('pattern'),
    GenerateNodeProperty('equals'),
    GenerateNodeProperty('expression'),
  ],
)
final class PatternVariableDeclarationImpl extends AnnotatedNodeImpl
    implements PatternVariableDeclaration {
  @generated
  @override
  final Token keyword;

  @generated
  DartPatternImpl _pattern;

  @generated
  @override
  final Token equals;

  @generated
  ExpressionImpl _expression;

  /// The pattern type schema, used for downward inference of [expression];
  /// or `null` if the node isn't resolved yet.
  TypeImpl? patternTypeSchema;

  /// Variables declared in [pattern].
  late final List<BindPatternVariableElementImpl> elements;

  @generated
  PatternVariableDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.keyword,
    required DartPatternImpl pattern,
    required this.equals,
    required ExpressionImpl expression,
  }) : _pattern = pattern,
       _expression = expression {
    _becomeParentOf(pattern);
    _becomeParentOf(expression);
  }

  @generated
  @override
  Token get endToken {
    return expression.endToken;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
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

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    return keyword;
  }

  @generated
  @override
  DartPatternImpl get pattern => _pattern;

  @generated
  set pattern(DartPatternImpl pattern) {
    _pattern = _becomeParentOf(pattern);
  }

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('keyword', keyword)
    ..addNode('pattern', pattern)
    ..addToken('equals', equals)
    ..addNode('expression', expression);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitPatternVariableDeclaration(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    pattern.accept(visitor);
    expression.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (pattern._containsOffset(rangeOffset, rangeEnd)) {
      return pattern;
    }
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    return null;
  }
}

/// A pattern variable declaration statement.
///
///    patternDeclaration ::=
///        [PatternVariableDeclaration] ';'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class PatternVariableDeclarationStatement implements Statement {
  /// The pattern declaration.
  PatternVariableDeclaration get declaration;

  /// The semicolon terminating the statement.
  Token get semicolon;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('declaration'),
    GenerateNodeProperty('semicolon'),
  ],
)
final class PatternVariableDeclarationStatementImpl extends StatementImpl
    implements PatternVariableDeclarationStatement {
  @generated
  PatternVariableDeclarationImpl _declaration;

  @generated
  @override
  final Token semicolon;

  @generated
  PatternVariableDeclarationStatementImpl({
    required PatternVariableDeclarationImpl declaration,
    required this.semicolon,
  }) : _declaration = declaration {
    _becomeParentOf(declaration);
  }

  @generated
  @override
  Token get beginToken {
    return declaration.beginToken;
  }

  @generated
  @override
  PatternVariableDeclarationImpl get declaration => _declaration;

  @generated
  set declaration(PatternVariableDeclarationImpl declaration) {
    _declaration = _becomeParentOf(declaration);
  }

  @generated
  @override
  Token get endToken {
    return semicolon;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('declaration', declaration)
    ..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitPatternVariableDeclarationStatement(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    declaration.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (declaration._containsOffset(rangeOffset, rangeEnd)) {
      return declaration;
    }
    return null;
  }
}

/// A postfix unary expression.
///
///    postfixExpression ::=
///        [Expression] [Token]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class PostfixExpression
    implements
        Expression,
        // ignore: deprecated_member_use_from_same_package
        NullShortableExpression,
        MethodReferenceExpression,
        CompoundAssignmentExpression {
  /// The element associated with the operator based on the static type of the
  /// operand, or `null` if the AST structure hasn't been resolved, if the
  /// operator isn't user definable, or if the operator couldn't be resolved.
  @override
  MethodElement? get element;

  /// The expression computing the operand for the operator.
  Expression get operand;

  /// The postfix operator being applied to the operand.
  Token get operator;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('operand'),
    GenerateNodeProperty('operator'),
  ],
)
final class PostfixExpressionImpl extends ExpressionImpl
    with
        NullShortableExpressionImpl,
        CompoundAssignmentExpressionImpl,
        DotShorthandMixin
    implements PostfixExpression {
  @generated
  ExpressionImpl _operand;

  @generated
  @override
  final Token operator;

  @override
  MethodElement? element;

  @generated
  PostfixExpressionImpl({
    required ExpressionImpl operand,
    required this.operator,
  }) : _operand = operand {
    _becomeParentOf(operand);
  }

  @generated
  @override
  Token get beginToken {
    return operand.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return operator;
  }

  @generated
  @override
  ExpressionImpl get operand => _operand;

  @generated
  set operand(ExpressionImpl operand) {
    _operand = _becomeParentOf(operand);
  }

  @override
  Precedence get precedence => Precedence.postfix;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('operand', operand)
    ..addToken('operator', operator);

  @override
  AstNode? get _nullShortingExtensionCandidate => parent;

  /// The parameter element representing the parameter to which the value of the
  /// operand is bound, or `null` ff the AST structure is not resolved or the
  /// function being invoked isn't known based on static type information.
  InternalFormalParameterElement? get _staticParameterElementForOperand {
    if (element == null) {
      return null;
    }
    var parameters = element!.formalParameters;
    if (parameters.isEmpty) {
      return null;
    }
    // TODO(paulberry): eliminate this cast by changing the type of
    // `staticElement` to `MethodElement2OrMember?`.
    return parameters[0] as InternalFormalParameterElement;
  }

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPostfixExpression(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitPostfixExpression(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    operand.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (operand._containsOffset(rangeOffset, rangeEnd)) {
      return operand;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('prefix'),
    GenerateNodeProperty('period'),
    GenerateNodeProperty('identifier'),
  ],
)
final class PrefixedIdentifierImpl extends IdentifierImpl
    implements PrefixedIdentifier {
  @generated
  SimpleIdentifierImpl _prefix;

  @generated
  @override
  final Token period;

  @generated
  SimpleIdentifierImpl _identifier;

  @generated
  PrefixedIdentifierImpl({
    required SimpleIdentifierImpl prefix,
    required this.period,
    required SimpleIdentifierImpl identifier,
  }) : _prefix = prefix,
       _identifier = identifier {
    _becomeParentOf(prefix);
    _becomeParentOf(identifier);
  }

  @generated
  @override
  Token get beginToken {
    return prefix.beginToken;
  }

  @override
  Element? get element {
    return _identifier.element;
  }

  @generated
  @override
  Token get endToken {
    return identifier.endToken;
  }

  @generated
  @override
  SimpleIdentifierImpl get identifier => _identifier;

  @generated
  set identifier(SimpleIdentifierImpl identifier) {
    _identifier = _becomeParentOf(identifier);
  }

  @override
  bool get isDeferred {
    var element = _prefix.element;
    if (element is PrefixElement) {
      return element.fragments.any((fragment) => fragment.isDeferred);
    }
    return false;
  }

  @override
  String get name => "${_prefix.name}.${_identifier.name}";

  @override
  Precedence get precedence => Precedence.postfix;

  @generated
  @override
  SimpleIdentifierImpl get prefix => _prefix;

  @generated
  set prefix(SimpleIdentifierImpl prefix) {
    _prefix = _becomeParentOf(prefix);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('prefix', prefix)
    ..addToken('period', period)
    ..addNode('identifier', identifier);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPrefixedIdentifier(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitPrefixedIdentifier(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    prefix.accept(visitor);
    identifier.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (prefix._containsOffset(rangeOffset, rangeEnd)) {
      return prefix;
    }
    if (identifier._containsOffset(rangeOffset, rangeEnd)) {
      return identifier;
    }
    return null;
  }
}

/// A prefix unary expression.
///
///    prefixExpression ::=
///        [Token] [Expression]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class PrefixExpression
    implements
        Expression,
        // ignore: deprecated_member_use_from_same_package
        NullShortableExpression,
        MethodReferenceExpression,
        CompoundAssignmentExpression {
  /// The element associated with the operator based on the static type of the
  /// operand, or `null` if the AST structure hasn't been resolved, if the
  /// operator isn't user definable, or if the operator couldn't be resolved.
  @override
  MethodElement? get element;

  /// The expression computing the operand for the operator.
  Expression get operand;

  /// The prefix operator being applied to the operand.
  Token get operator;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('operator'),
    GenerateNodeProperty('operand'),
  ],
)
final class PrefixExpressionImpl extends ExpressionImpl
    with NullShortableExpressionImpl, CompoundAssignmentExpressionImpl
    implements PrefixExpression {
  @generated
  @override
  final Token operator;

  @generated
  ExpressionImpl _operand;

  @override
  MethodElement? element;

  @generated
  PrefixExpressionImpl({
    required this.operator,
    required ExpressionImpl operand,
  }) : _operand = operand {
    _becomeParentOf(operand);
  }

  @generated
  @override
  Token get beginToken {
    return operator;
  }

  @generated
  @override
  Token get endToken {
    return operand.endToken;
  }

  @generated
  @override
  ExpressionImpl get operand => _operand;

  @generated
  set operand(ExpressionImpl operand) {
    _operand = _becomeParentOf(operand);
  }

  @override
  Precedence get precedence => Precedence.prefix;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('operator', operator)
    ..addNode('operand', operand);

  @override
  AstNode? get _nullShortingExtensionCandidate => parent;

  /// The parameter element representing the parameter to which the value of the
  /// operand is bound, or `null` if the AST structure is not resolved or the
  /// function being invoked isn't known based on static type information.
  InternalFormalParameterElement? get _staticParameterElementForOperand {
    if (element == null) {
      return null;
    }
    var parameters = element!.formalParameters;
    if (parameters.isEmpty) {
      return null;
    }
    // TODO(paulberry): eliminate this cast by changing the type of
    // `staticElement` to `MethodElementOrMember?`.
    return parameters[0] as InternalFormalParameterElement;
  }

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPrefixExpression(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitPrefixExpression(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    operand.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (operand._containsOffset(rangeOffset, rangeEnd)) {
      return operand;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class PropertyAccess
    implements
        // ignore: deprecated_member_use_from_same_package
        NullShortableExpression,
        CommentReferableExpression {
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('target'),
    GenerateNodeProperty('operator'),
    GenerateNodeProperty('propertyName'),
  ],
)
final class PropertyAccessImpl extends CommentReferableExpressionImpl
    with NullShortableExpressionImpl, DotShorthandMixin
    implements PropertyAccess {
  @generated
  ExpressionImpl? _target;

  @generated
  @override
  final Token operator;

  @generated
  SimpleIdentifierImpl _propertyName;

  @generated
  PropertyAccessImpl({
    required ExpressionImpl? target,
    required this.operator,
    required SimpleIdentifierImpl propertyName,
  }) : _target = target,
       _propertyName = propertyName {
    _becomeParentOf(target);
    _becomeParentOf(propertyName);
  }

  @generated
  @override
  Token get beginToken {
    if (target case var target?) {
      return target.beginToken;
    }
    return operator;
  }

  @generated
  @override
  Token get endToken {
    return propertyName.endToken;
  }

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

  @generated
  @override
  SimpleIdentifierImpl get propertyName => _propertyName;

  @generated
  set propertyName(SimpleIdentifierImpl propertyName) {
    _propertyName = _becomeParentOf(propertyName);
  }

  @override
  ExpressionImpl get realTarget {
    if (isCascaded) {
      return _ancestorCascade.target;
    }
    return _target!;
  }

  @generated
  @override
  ExpressionImpl? get target => _target;

  @generated
  set target(ExpressionImpl? target) {
    _target = _becomeParentOf(target);
  }

  /// The cascade that contains this [IndexExpression].
  ///
  /// This method assumes that [isCascaded] is `true`.
  CascadeExpressionImpl get _ancestorCascade {
    assert(isCascaded);
    for (var ancestor = parent!; ; ancestor = ancestor.parent!) {
      if (ancestor is CascadeExpressionImpl) {
        return ancestor;
      }
    }
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('target', target)
    ..addToken('operator', operator)
    ..addNode('propertyName', propertyName);

  @override
  AstNode? get _nullShortingExtensionCandidate => parent;

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitPropertyAccess(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitPropertyAccess(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    target?.accept(visitor);
    propertyName.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (target case var target?) {
      if (target._containsOffset(rangeOffset, rangeEnd)) {
        return target;
      }
    }
    if (propertyName._containsOffset(rangeOffset, rangeEnd)) {
      return propertyName;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('constKeyword'),
    GenerateNodeProperty('leftParenthesis'),
    GenerateNodeProperty('fields'),
    GenerateNodeProperty('rightParenthesis'),
  ],
)
final class RecordLiteralImpl extends LiteralImpl implements RecordLiteral {
  @generated
  @override
  final Token? constKeyword;

  @generated
  @override
  final Token leftParenthesis;

  @generated
  @override
  final NodeListImpl<ExpressionImpl> fields = NodeListImpl._();

  @generated
  @override
  final Token rightParenthesis;

  @generated
  RecordLiteralImpl({
    required this.constKeyword,
    required this.leftParenthesis,
    required List<ExpressionImpl> fields,
    required this.rightParenthesis,
  }) {
    this.fields._initialize(this, fields);
  }

  @generated
  @override
  Token get beginToken {
    if (constKeyword case var constKeyword?) {
      return constKeyword;
    }
    return leftParenthesis;
  }

  @generated
  @override
  Token get endToken {
    return rightParenthesis;
  }

  @override
  bool get isConst => constKeyword != null || inConstantContext;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('constKeyword', constKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNodeList('fields', fields)
    ..addToken('rightParenthesis', rightParenthesis);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitRecordLiteral(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitRecordLiteral(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    fields.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (fields._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// A record pattern.
///
///    recordPattern ::=
///        '(' [PatternField] (',' [PatternField])* ')'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class RecordPattern implements DartPattern {
  /// The fields of the record pattern.
  NodeList<PatternField> get fields;

  /// The left parenthesis.
  Token get leftParenthesis;

  /// The right parenthesis.
  Token get rightParenthesis;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('leftParenthesis'),
    GenerateNodeProperty('fields'),
    GenerateNodeProperty('rightParenthesis'),
  ],
)
final class RecordPatternImpl extends DartPatternImpl implements RecordPattern {
  @generated
  @override
  final Token leftParenthesis;

  @generated
  @override
  final NodeListImpl<PatternFieldImpl> fields = NodeListImpl._();

  @generated
  @override
  final Token rightParenthesis;

  bool hasDuplicateNamedField = false;

  @generated
  RecordPatternImpl({
    required this.leftParenthesis,
    required List<PatternFieldImpl> fields,
    required this.rightParenthesis,
  }) {
    this.fields._initialize(this, fields);
  }

  @generated
  @override
  Token get beginToken {
    return leftParenthesis;
  }

  @generated
  @override
  Token get endToken {
    return rightParenthesis;
  }

  @override
  PatternPrecedence get precedence => PatternPrecedence.primary;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNodeList('fields', fields)
    ..addToken('rightParenthesis', rightParenthesis);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitRecordPattern(this);

  @override
  TypeImpl computePatternSchema(ResolverVisitor resolverVisitor) {
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
  PatternResult resolvePattern(
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

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    fields.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (fields._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (type._containsOffset(rangeOffset, rangeEnd)) {
      return type;
    }
    return metadata._elementContainingRange(rangeOffset, rangeEnd);
  }
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('leftParenthesis'),
    GenerateNodeProperty('positionalFields'),
    GenerateNodeProperty('namedFields'),
    GenerateNodeProperty('rightParenthesis'),
    GenerateNodeProperty('question'),
  ],
)
final class RecordTypeAnnotationImpl extends TypeAnnotationImpl
    implements RecordTypeAnnotation {
  @generated
  @override
  final Token leftParenthesis;

  @generated
  @override
  final NodeListImpl<RecordTypeAnnotationPositionalFieldImpl> positionalFields =
      NodeListImpl._();

  @generated
  RecordTypeAnnotationNamedFieldsImpl? _namedFields;

  @generated
  @override
  final Token rightParenthesis;

  @generated
  @override
  final Token? question;

  @override
  TypeImpl? type;

  @generated
  RecordTypeAnnotationImpl({
    required this.leftParenthesis,
    required List<RecordTypeAnnotationPositionalFieldImpl> positionalFields,
    required RecordTypeAnnotationNamedFieldsImpl? namedFields,
    required this.rightParenthesis,
    required this.question,
  }) : _namedFields = namedFields {
    this.positionalFields._initialize(this, positionalFields);
    _becomeParentOf(namedFields);
  }

  @generated
  @override
  Token get beginToken {
    return leftParenthesis;
  }

  @generated
  @override
  Token get endToken {
    if (question case var question?) {
      return question;
    }
    return rightParenthesis;
  }

  @generated
  @override
  RecordTypeAnnotationNamedFieldsImpl? get namedFields => _namedFields;

  @generated
  set namedFields(RecordTypeAnnotationNamedFieldsImpl? namedFields) {
    _namedFields = _becomeParentOf(namedFields);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNodeList('positionalFields', positionalFields)
    ..addNode('namedFields', namedFields)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addToken('question', question);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitRecordTypeAnnotation(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    positionalFields.accept(visitor);
    namedFields?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (positionalFields._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    if (namedFields case var namedFields?) {
      if (namedFields._containsOffset(rangeOffset, rangeEnd)) {
        return namedFields;
      }
    }
    return null;
  }
}

/// A named field in a [RecordTypeAnnotation].
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class RecordTypeAnnotationNamedField
    implements RecordTypeAnnotationField {
  @override
  Token get name;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('metadata', isSuper: true),
    GenerateNodeProperty('type', isSuper: true),
    GenerateNodeProperty('name'),
  ],
)
final class RecordTypeAnnotationNamedFieldImpl
    extends RecordTypeAnnotationFieldImpl
    implements RecordTypeAnnotationNamedField {
  @generated
  @override
  final Token name;

  @generated
  RecordTypeAnnotationNamedFieldImpl({
    required super.metadata,
    required super.type,
    required this.name,
  });

  @generated
  @override
  Token get beginToken {
    if (metadata.beginToken case var result?) {
      return result;
    }
    return type.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return name;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNodeList('metadata', metadata)
    ..addNode('type', type)
    ..addToken('name', name);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitRecordTypeAnnotationNamedField(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    metadata.accept(visitor);
    type.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (metadata._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    if (type._containsOffset(rangeOffset, rangeEnd)) {
      return type;
    }
    return null;
  }
}

/// The portion of a [RecordTypeAnnotation] with named fields.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class RecordTypeAnnotationNamedFields implements AstNode {
  /// The fields contained in the block.
  NodeList<RecordTypeAnnotationNamedField> get fields;

  /// The left curly bracket.
  Token get leftBracket;

  /// The right curly bracket.
  Token get rightBracket;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('leftBracket'),
    GenerateNodeProperty('fields'),
    GenerateNodeProperty('rightBracket'),
  ],
)
final class RecordTypeAnnotationNamedFieldsImpl extends AstNodeImpl
    implements RecordTypeAnnotationNamedFields {
  @generated
  @override
  final Token leftBracket;

  @generated
  @override
  final NodeListImpl<RecordTypeAnnotationNamedFieldImpl> fields =
      NodeListImpl._();

  @generated
  @override
  final Token rightBracket;

  @generated
  RecordTypeAnnotationNamedFieldsImpl({
    required this.leftBracket,
    required List<RecordTypeAnnotationNamedFieldImpl> fields,
    required this.rightBracket,
  }) {
    this.fields._initialize(this, fields);
  }

  @generated
  @override
  Token get beginToken {
    return leftBracket;
  }

  @generated
  @override
  Token get endToken {
    return rightBracket;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('fields', fields)
    ..addToken('rightBracket', rightBracket);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitRecordTypeAnnotationNamedFields(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    fields.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (fields._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// A positional field in a [RecordTypeAnnotation].
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class RecordTypeAnnotationPositionalField
    implements RecordTypeAnnotationField {}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('metadata', isSuper: true),
    GenerateNodeProperty('type', isSuper: true),
    GenerateNodeProperty('name'),
  ],
)
final class RecordTypeAnnotationPositionalFieldImpl
    extends RecordTypeAnnotationFieldImpl
    implements RecordTypeAnnotationPositionalField {
  @generated
  @override
  final Token? name;

  @generated
  RecordTypeAnnotationPositionalFieldImpl({
    required super.metadata,
    required super.type,
    required this.name,
  });

  @generated
  @override
  Token get beginToken {
    if (metadata.beginToken case var result?) {
      return result;
    }
    return type.beginToken;
  }

  @generated
  @override
  Token get endToken {
    if (name case var name?) {
      return name;
    }
    return type.endToken;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNodeList('metadata', metadata)
    ..addNode('type', type)
    ..addToken('name', name);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitRecordTypeAnnotationPositionalField(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    metadata.accept(visitor);
    type.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (metadata._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    if (type._containsOffset(rangeOffset, rangeEnd)) {
      return type;
    }
    return null;
  }
}

/// The invocation of a constructor in the same class from within a
/// constructor's initialization list.
///
///    redirectingConstructorInvocation ::=
///        'this' ('.' identifier)? arguments
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

  /// The token for the `this` keyword.
  Token get thisKeyword;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('thisKeyword'),
    GenerateNodeProperty('period'),
    GenerateNodeProperty('constructorName'),
    GenerateNodeProperty('argumentList'),
  ],
)
final class RedirectingConstructorInvocationImpl
    extends ConstructorInitializerImpl
    implements RedirectingConstructorInvocation {
  @generated
  @override
  final Token thisKeyword;

  @generated
  @override
  final Token? period;

  @generated
  SimpleIdentifierImpl? _constructorName;

  @generated
  ArgumentListImpl _argumentList;

  @override
  ConstructorElementImpl? element;

  @generated
  RedirectingConstructorInvocationImpl({
    required this.thisKeyword,
    required this.period,
    required SimpleIdentifierImpl? constructorName,
    required ArgumentListImpl argumentList,
  }) : _constructorName = constructorName,
       _argumentList = argumentList {
    _becomeParentOf(constructorName);
    _becomeParentOf(argumentList);
  }

  @generated
  @override
  ArgumentListImpl get argumentList => _argumentList;

  @generated
  set argumentList(ArgumentListImpl argumentList) {
    _argumentList = _becomeParentOf(argumentList);
  }

  @generated
  @override
  Token get beginToken {
    return thisKeyword;
  }

  @generated
  @override
  SimpleIdentifierImpl? get constructorName => _constructorName;

  @generated
  set constructorName(SimpleIdentifierImpl? constructorName) {
    _constructorName = _becomeParentOf(constructorName);
  }

  @generated
  @override
  Token get endToken {
    return argumentList.endToken;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('thisKeyword', thisKeyword)
    ..addToken('period', period)
    ..addNode('constructorName', constructorName)
    ..addNode('argumentList', argumentList);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitRedirectingConstructorInvocation(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    constructorName?.accept(visitor);
    argumentList.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (constructorName case var constructorName?) {
      if (constructorName._containsOffset(rangeOffset, rangeEnd)) {
        return constructorName;
      }
    }
    if (argumentList._containsOffset(rangeOffset, rangeEnd)) {
      return argumentList;
    }
    return null;
  }
}

/// A relational pattern.
///
///    relationalPattern ::=
///        (equalityOperator | relationalOperator) [Expression]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class RelationalPattern implements DartPattern {
  /// The element of the [operator] for the matched type.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if the
  /// operator couldn't be resolved.
  MethodElement? get element;

  /// The element of the [operator] for the matched type.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if the
  /// operator couldn't be resolved.
  @Deprecated('Use element instead')
  MethodElement? get element2;

  /// The expression used to compute the operand.
  Expression get operand;

  /// The relational operator being applied.
  Token get operator;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('operator'),
    GenerateNodeProperty('operand'),
  ],
)
final class RelationalPatternImpl extends DartPatternImpl
    implements RelationalPattern {
  @generated
  @override
  final Token operator;

  @generated
  ExpressionImpl _operand;

  @override
  MethodElement? element;

  @generated
  RelationalPatternImpl({
    required this.operator,
    required ExpressionImpl operand,
  }) : _operand = operand {
    _becomeParentOf(operand);
  }

  @generated
  @override
  Token get beginToken {
    return operator;
  }

  @Deprecated('Use element instead')
  @override
  MethodElement? get element2 => element;

  @generated
  @override
  Token get endToken {
    return operand.endToken;
  }

  @generated
  @override
  ExpressionImpl get operand => _operand;

  @generated
  set operand(ExpressionImpl operand) {
    _operand = _becomeParentOf(operand);
  }

  @override
  PatternPrecedence get precedence => PatternPrecedence.relational;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('operator', operator)
    ..addNode('operand', operand);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitRelationalPattern(this);

  @override
  TypeImpl computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor
        .analyzeRelationalPatternSchema()
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult resolvePattern(
    ResolverVisitor resolverVisitor,
    SharedMatchContext context,
  ) {
    inferenceLogWriter?.enterPattern(this);
    var analysisResult = resolverVisitor.analyzeRelationalPattern(
      context,
      this,
      operand,
    );
    resolverVisitor.popRewrite();
    inferenceLogWriter?.exitPattern(this);
    return analysisResult;
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    operand.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (operand._containsOffset(rangeOffset, rangeEnd)) {
      return operand;
    }
    return null;
  }
}

/// The name of the primary constructor of an extension type.
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class RepresentationConstructorName implements AstNode {
  /// The name of the primary constructor.
  Token get name;

  /// The period separating [name] from the previous token.
  Token get period;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('period'),
    GenerateNodeProperty('name'),
  ],
)
final class RepresentationConstructorNameImpl extends AstNodeImpl
    implements RepresentationConstructorName {
  @generated
  @override
  final Token period;

  @generated
  @override
  final Token name;

  @generated
  RepresentationConstructorNameImpl({required this.period, required this.name});

  @generated
  @override
  Token get beginToken {
    return period;
  }

  @generated
  @override
  Token get endToken {
    return name;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('period', period)
    ..addToken('name', name);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitRepresentationConstructorName(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {}

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    return null;
  }
}

/// The declaration of an extension type representation.
///
/// It declares both the representation field and the primary constructor.
///
///    <representationDeclaration> ::=
///        ('.' <identifierOrNew>)? '(' <metadata> <type> <identifier> ')'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class RepresentationDeclaration implements AstNode {
  /// The fragment of the primary constructor contained in this declaration.
  ConstructorFragment? get constructorFragment;

  /// The optional name of the primary constructor.
  RepresentationConstructorName? get constructorName;

  /// The fragment for [fieldName] with [fieldType] contained in this
  /// declaration.
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('constructorName'),
    GenerateNodeProperty('leftParenthesis'),
    GenerateNodeProperty('fieldMetadata'),
    GenerateNodeProperty('fieldType'),
    GenerateNodeProperty('fieldName'),
    GenerateNodeProperty('rightParenthesis'),
  ],
)
final class RepresentationDeclarationImpl extends AstNodeImpl
    implements RepresentationDeclaration {
  @generated
  RepresentationConstructorNameImpl? _constructorName;

  @generated
  @override
  final Token leftParenthesis;

  @generated
  @override
  final NodeListImpl<AnnotationImpl> fieldMetadata = NodeListImpl._();

  @generated
  TypeAnnotationImpl _fieldType;

  @generated
  @override
  final Token fieldName;

  @generated
  @override
  final Token rightParenthesis;

  @override
  ConstructorFragmentImpl? constructorFragment;

  @override
  FieldFragmentImpl? fieldFragment;

  @generated
  RepresentationDeclarationImpl({
    required RepresentationConstructorNameImpl? constructorName,
    required this.leftParenthesis,
    required List<AnnotationImpl> fieldMetadata,
    required TypeAnnotationImpl fieldType,
    required this.fieldName,
    required this.rightParenthesis,
  }) : _constructorName = constructorName,
       _fieldType = fieldType {
    _becomeParentOf(constructorName);
    this.fieldMetadata._initialize(this, fieldMetadata);
    _becomeParentOf(fieldType);
  }

  @generated
  @override
  Token get beginToken {
    if (constructorName case var constructorName?) {
      return constructorName.beginToken;
    }
    return leftParenthesis;
  }

  @generated
  @override
  RepresentationConstructorNameImpl? get constructorName => _constructorName;

  @generated
  set constructorName(RepresentationConstructorNameImpl? constructorName) {
    _constructorName = _becomeParentOf(constructorName);
  }

  @generated
  @override
  Token get endToken {
    return rightParenthesis;
  }

  @generated
  @override
  TypeAnnotationImpl get fieldType => _fieldType;

  @generated
  set fieldType(TypeAnnotationImpl fieldType) {
    _fieldType = _becomeParentOf(fieldType);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('constructorName', constructorName)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNodeList('fieldMetadata', fieldMetadata)
    ..addNode('fieldType', fieldType)
    ..addToken('fieldName', fieldName)
    ..addToken('rightParenthesis', rightParenthesis);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitRepresentationDeclaration(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    constructorName?.accept(visitor);
    fieldMetadata.accept(visitor);
    fieldType.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (constructorName case var constructorName?) {
      if (constructorName._containsOffset(rangeOffset, rangeEnd)) {
        return constructorName;
      }
    }
    if (fieldMetadata._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    if (fieldType._containsOffset(rangeOffset, rangeEnd)) {
      return fieldType;
    }
    return null;
  }
}

/// A rest pattern element.
///
///    restPatternElement ::= '...' [DartPattern]?
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class RestPatternElement
    implements ListPatternElement, MapPatternElement {
  /// The operator token '...'.
  Token get operator;

  /// The optional pattern.
  DartPattern? get pattern;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('operator'),
    GenerateNodeProperty('pattern'),
  ],
)
final class RestPatternElementImpl extends AstNodeImpl
    implements
        ListPatternElementImpl,
        MapPatternElementImpl,
        RestPatternElement {
  @generated
  @override
  final Token operator;

  @generated
  DartPatternImpl? _pattern;

  @generated
  RestPatternElementImpl({
    required this.operator,
    required DartPatternImpl? pattern,
  }) : _pattern = pattern {
    _becomeParentOf(pattern);
  }

  @generated
  @override
  Token get beginToken {
    return operator;
  }

  @generated
  @override
  Token get endToken {
    if (pattern case var pattern?) {
      return pattern.endToken;
    }
    return operator;
  }

  @generated
  @override
  DartPatternImpl? get pattern => _pattern;

  @generated
  set pattern(DartPatternImpl? pattern) {
    _pattern = _becomeParentOf(pattern);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('operator', operator)
    ..addNode('pattern', pattern);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitRestPatternElement(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    pattern?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (pattern case var pattern?) {
      if (pattern._containsOffset(rangeOffset, rangeEnd)) {
        return pattern;
      }
    }
    return null;
  }
}

/// A rethrow expression.
///
///    rethrowExpression ::=
///        'rethrow'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class RethrowExpression implements Expression {
  /// The token representing the `rethrow` keyword.
  Token get rethrowKeyword;
}

@GenerateNodeImpl(childEntitiesOrder: [GenerateNodeProperty('rethrowKeyword')])
final class RethrowExpressionImpl extends ExpressionImpl
    implements RethrowExpression {
  @generated
  @override
  final Token rethrowKeyword;

  @generated
  RethrowExpressionImpl({required this.rethrowKeyword});

  @generated
  @override
  Token get beginToken {
    return rethrowKeyword;
  }

  @generated
  @override
  Token get endToken {
    return rethrowKeyword;
  }

  @override
  Precedence get precedence => Precedence.assignment;

  @generated
  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('rethrowKeyword', rethrowKeyword);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitRethrowExpression(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitRethrowExpression(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {}

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    return null;
  }
}

/// A return statement.
///
///    returnStatement ::=
///        'return' [Expression]? ';'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ReturnStatement implements Statement {
  /// The expression computing the value to be returned, or `null` if no
  /// explicit value was provided.
  Expression? get expression;

  /// The token representing the `return` keyword.
  Token get returnKeyword;

  /// The semicolon terminating the statement.
  Token get semicolon;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('returnKeyword'),
    GenerateNodeProperty('expression'),
    GenerateNodeProperty('semicolon'),
  ],
)
final class ReturnStatementImpl extends StatementImpl
    implements ReturnStatement {
  @generated
  @override
  final Token returnKeyword;

  @generated
  ExpressionImpl? _expression;

  @generated
  @override
  final Token semicolon;

  @generated
  ReturnStatementImpl({
    required this.returnKeyword,
    required ExpressionImpl? expression,
    required this.semicolon,
  }) : _expression = expression {
    _becomeParentOf(expression);
  }

  @generated
  @override
  Token get beginToken {
    return returnKeyword;
  }

  @generated
  @override
  Token get endToken {
    return semicolon;
  }

  @generated
  @override
  ExpressionImpl? get expression => _expression;

  @generated
  set expression(ExpressionImpl? expression) {
    _expression = _becomeParentOf(expression);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('returnKeyword', returnKeyword)
    ..addNode('expression', expression)
    ..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitReturnStatement(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    expression?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (expression case var expression?) {
      if (expression._containsOffset(rangeOffset, rangeEnd)) {
        return expression;
      }
    }
    return null;
  }
}

/// A resolved dot shorthand invocation.
///
/// Either a [FunctionExpressionInvocationImpl], a static method invocation, or
/// a [DotShorthandConstructorInvocationImpl], a constructor invocation.
sealed class RewrittenMethodInvocationImpl implements ExpressionImpl {}

/// A script tag that can optionally occur at the beginning of a compilation
/// unit.
///
///    scriptTag ::=
///        '#!' (~NEWLINE)* NEWLINE
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ScriptTag implements AstNode {
  /// The token representing this script tag.
  Token get scriptTag;
}

@GenerateNodeImpl(childEntitiesOrder: [GenerateNodeProperty('scriptTag')])
final class ScriptTagImpl extends AstNodeImpl implements ScriptTag {
  @generated
  @override
  final Token scriptTag;

  @generated
  ScriptTagImpl({required this.scriptTag});

  @generated
  @override
  Token get beginToken {
    return scriptTag;
  }

  @generated
  @override
  Token get endToken {
    return scriptTag;
  }

  @generated
  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('scriptTag', scriptTag);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitScriptTag(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {}

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('constKeyword', isSuper: true),
    GenerateNodeProperty('typeArguments', isSuper: true),
    GenerateNodeProperty('leftBracket'),
    GenerateNodeProperty('elements'),
    GenerateNodeProperty('rightBracket'),
  ],
)
final class SetOrMapLiteralImpl extends TypedLiteralImpl
    implements SetOrMapLiteral {
  @generated
  @override
  final Token leftBracket;

  @generated
  @override
  final NodeListImpl<CollectionElementImpl> elements = NodeListImpl._();

  @generated
  @override
  final Token rightBracket;

  /// A representation of whether this literal represents a map or a set, or
  /// whether the kind hasn't or can't be determined.
  _SetOrMapKind _resolvedKind = _SetOrMapKind.unresolved;

  /// The context type computed by [TypedLiteralResolver].
  InterfaceType? contextType;

  @generated
  SetOrMapLiteralImpl({
    required super.constKeyword,
    required super.typeArguments,
    required this.leftBracket,
    required List<CollectionElementImpl> elements,
    required this.rightBracket,
  }) {
    this.elements._initialize(this, elements);
  }

  @generated
  @override
  Token get beginToken {
    if (constKeyword case var constKeyword?) {
      return constKeyword;
    }
    if (typeArguments case var typeArguments?) {
      return typeArguments.beginToken;
    }
    return leftBracket;
  }

  @generated
  @override
  Token get endToken {
    return rightBracket;
  }

  @override
  bool get isMap => _resolvedKind == _SetOrMapKind.map;

  @override
  bool get isSet => _resolvedKind == _SetOrMapKind.set;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('constKeyword', constKeyword)
    ..addNode('typeArguments', typeArguments)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('elements', elements)
    ..addToken('rightBracket', rightBracket);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSetOrMapLiteral(this);

  void becomeMap() {
    assert(
      _resolvedKind == _SetOrMapKind.unresolved ||
          _resolvedKind == _SetOrMapKind.map,
    );
    _resolvedKind = _SetOrMapKind.map;
  }

  void becomeSet() {
    assert(
      _resolvedKind == _SetOrMapKind.unresolved ||
          _resolvedKind == _SetOrMapKind.set,
    );
    _resolvedKind = _SetOrMapKind.set;
  }

  void becomeUnresolved() {
    _resolvedKind = _SetOrMapKind.unresolved;
  }

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitSetOrMapLiteral(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    typeArguments?.accept(visitor);
    elements.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (typeArguments case var typeArguments?) {
      if (typeArguments._containsOffset(rangeOffset, rangeEnd)) {
        return typeArguments;
      }
    }
    if (elements._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// A combinator that restricts the names being imported to those in a given
/// list.
///
///    showCombinator ::=
///        'show' [SimpleIdentifier] (',' [SimpleIdentifier])*
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ShowCombinator implements Combinator {
  /// The list of names from the library that are made visible by this
  /// combinator.
  NodeList<SimpleIdentifier> get shownNames;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('keyword', isSuper: true),
    GenerateNodeProperty('shownNames'),
  ],
)
final class ShowCombinatorImpl extends CombinatorImpl
    implements ShowCombinator {
  @generated
  @override
  final NodeListImpl<SimpleIdentifierImpl> shownNames = NodeListImpl._();

  @generated
  ShowCombinatorImpl({
    required super.keyword,
    required List<SimpleIdentifierImpl> shownNames,
  }) {
    this.shownNames._initialize(this, shownNames);
  }

  @generated
  @override
  Token get beginToken {
    return keyword;
  }

  @generated
  @override
  Token get endToken {
    if (shownNames.endToken case var result?) {
      return result;
    }
    return keyword;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('keyword', keyword)
    ..addNodeList('shownNames', shownNames);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitShowCombinator(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    shownNames.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (shownNames._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// A simple formal parameter.
///
///    simpleFormalParameter ::=
///        ('final' [TypeAnnotation] | 'var' | [TypeAnnotation])?
///        [SimpleIdentifier]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class SimpleFormalParameter implements NormalFormalParameter {
  /// The token representing either the `final`, `const` or `var` keyword, or
  /// `null` if no keyword was used.
  Token? get keyword;

  /// The declared type of the parameter, or `null` if the parameter doesn't
  /// have a declared type.
  TypeAnnotation? get type;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('covariantKeyword', isSuper: true),
    GenerateNodeProperty('requiredKeyword', isSuper: true),
    GenerateNodeProperty('keyword'),
    GenerateNodeProperty('type'),
    GenerateNodeProperty('name', isSuper: true),
  ],
)
final class SimpleFormalParameterImpl extends NormalFormalParameterImpl
    implements SimpleFormalParameter {
  @generated
  @override
  final Token? keyword;

  @generated
  TypeAnnotationImpl? _type;

  @generated
  SimpleFormalParameterImpl({
    required super.comment,
    required super.metadata,
    required super.covariantKeyword,
    required super.requiredKeyword,
    required this.keyword,
    required TypeAnnotationImpl? type,
    required super.name,
  }) : _type = type {
    _becomeParentOf(type);
  }

  @generated
  @override
  Token get endToken {
    if (name case var name?) {
      return name;
    }
    if (type case var type?) {
      return type.endToken;
    }
    if (keyword case var keyword?) {
      return keyword;
    }
    if (requiredKeyword case var requiredKeyword?) {
      return requiredKeyword;
    }
    if (covariantKeyword case var covariantKeyword?) {
      return covariantKeyword;
    }
    throw StateError('Expected at least one non-null');
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (covariantKeyword case var covariantKeyword?) {
      return covariantKeyword;
    }
    if (requiredKeyword case var requiredKeyword?) {
      return requiredKeyword;
    }
    if (keyword case var keyword?) {
      return keyword;
    }
    if (type case var type?) {
      return type.beginToken;
    }
    if (name case var name?) {
      return name;
    }
    throw StateError('Expected at least one non-null');
  }

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isExplicitlyTyped => _type != null;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @generated
  @override
  TypeAnnotationImpl? get type => _type;

  @generated
  set type(TypeAnnotationImpl? type) {
    _type = _becomeParentOf(type);
  }

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('covariantKeyword', covariantKeyword)
    ..addToken('requiredKeyword', requiredKeyword)
    ..addToken('keyword', keyword)
    ..addNode('type', type)
    ..addToken('name', name);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitSimpleFormalParameter(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    type?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (type case var type?) {
      if (type._containsOffset(rangeOffset, rangeEnd)) {
        return type;
      }
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(childEntitiesOrder: [GenerateNodeProperty('token')])
final class SimpleIdentifierImpl extends IdentifierImpl
    implements SimpleIdentifier {
  @generated
  @override
  final Token token;

  /// The element associated with this identifier based on static type
  /// information, or `null` if the AST structure hasn't been resolved or if
  /// this identifier couldn't be resolved.
  @override
  Element? element;

  @override
  List<TypeImpl>? tearOffTypeArgumentTypes;

  /// If this identifier is meant to be looked up in the enclosing scope, the
  /// raw result the scope lookup, prior to figuring out whether a write or a
  /// read context is intended, and prior to falling back on implicit `this` (if
  /// appropriate).
  ///
  /// Or `null` if this identifier isn't meant to be looked up in the enclosing
  /// scope.
  ScopeLookupResult? scopeLookupResult;

  @generated
  SimpleIdentifierImpl({required this.token});

  /// The cascade that contains this [SimpleIdentifier].
  CascadeExpressionImpl? get ancestorCascade {
    var operatorType = token.previous?.type;
    if (operatorType == TokenType.PERIOD_PERIOD ||
        operatorType == TokenType.QUESTION_PERIOD_PERIOD) {
      return thisOrAncestorOfType<CascadeExpressionImpl>();
    }
    return null;
  }

  @generated
  @override
  Token get beginToken {
    return token;
  }

  @generated
  @override
  Token get endToken {
    return token;
  }

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

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()..addToken('token', token);

  @generated
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

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitSimpleIdentifier(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {}

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class SimpleStringLiteral implements SingleStringLiteral {
  /// The token representing the literal.
  Token get literal;

  /// The value of the literal.
  String get value;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('literal'),
    GenerateNodeProperty('value'),
  ],
)
final class SimpleStringLiteralImpl extends SingleStringLiteralImpl
    implements SimpleStringLiteral {
  @generated
  @override
  final Token literal;

  @generated
  @override
  final String value;

  @generated
  SimpleStringLiteralImpl({required this.literal, required this.value});

  @generated
  @override
  Token get beginToken {
    return literal;
  }

  @override
  int get contentsEnd => offset + _helper.end;

  @override
  int get contentsOffset => offset + _helper.start;

  @generated
  @override
  Token get endToken {
    return literal;
  }

  @override
  bool get isMultiline => _helper.isMultiline;

  @override
  bool get isRaw => _helper.isRaw;

  @override
  bool get isSingleQuoted => _helper.isSingleQuoted;

  @override
  bool get isSynthetic => literal.isSynthetic;

  @generated
  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('literal', literal);

  StringLexemeHelper get _helper {
    return StringLexemeHelper(literal.lexeme, true, true);
  }

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSimpleStringLiteral(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitSimpleStringLiteral(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {}

  @override
  void _appendStringValue(StringBuffer buffer) {
    buffer.write(value);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    return null;
  }
}

/// A single string literal expression.
///
///    singleStringLiteral ::=
///        [SimpleStringLiteral]
///      | [StringInterpolation]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class SpreadElement implements CollectionElement {
  /// The expression used to compute the collection being spread.
  Expression get expression;

  /// Whether this is a null-aware spread, as opposed to a non-null spread.
  bool get isNullAware;

  /// The spread operator, either '...' or '...?'.
  Token get spreadOperator;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('spreadOperator'),
    GenerateNodeProperty('expression'),
  ],
)
final class SpreadElementImpl extends CollectionElementImpl
    implements SpreadElement {
  @generated
  @override
  final Token spreadOperator;

  @generated
  ExpressionImpl _expression;

  @generated
  SpreadElementImpl({
    required this.spreadOperator,
    required ExpressionImpl expression,
  }) : _expression = expression {
    _becomeParentOf(expression);
  }

  @generated
  @override
  Token get beginToken {
    return spreadOperator;
  }

  @generated
  @override
  Token get endToken {
    return expression.endToken;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  bool get isNullAware =>
      spreadOperator.type == TokenType.PERIOD_PERIOD_PERIOD_QUESTION;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('spreadOperator', spreadOperator)
    ..addNode('expression', expression);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSpreadElement(this);

  @override
  void resolveElement(
    ResolverVisitor resolver,
    CollectionLiteralContext? context,
  ) {
    resolver.visitSpreadElement(this, context: context);
    resolver.pushRewrite(null);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(childEntitiesOrder: [GenerateNodeProperty('elements')])
final class StringInterpolationImpl extends SingleStringLiteralImpl
    implements StringInterpolation {
  @generated
  @override
  final NodeListImpl<InterpolationElementImpl> elements = NodeListImpl._();

  @DoNotGenerate(reason: 'Has useful asserts')
  StringInterpolationImpl({required List<InterpolationElementImpl> elements}) {
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
    this.elements._initialize(this, elements);
  }

  @generated
  @override
  Token get beginToken {
    if (elements.beginToken case var result?) {
      return result;
    }
    throw StateError('Expected at least one non-null');
  }

  @override
  int get contentsEnd {
    var element = elements.last as InterpolationString;
    return element.contentsEnd;
  }

  @override
  int get contentsOffset {
    var element = elements.first as InterpolationString;
    return element.contentsOffset;
  }

  @generated
  @override
  Token get endToken {
    if (elements.endToken case var result?) {
      return result;
    }
    throw StateError('Expected at least one non-null');
  }

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

  @generated
  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addNodeList('elements', elements);

  StringLexemeHelper get _firstHelper {
    var lastString = elements.first as InterpolationString;
    String lexeme = lastString.contents.lexeme;
    return StringLexemeHelper(lexeme, true, false);
  }

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitStringInterpolation(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitStringInterpolation(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    elements.accept(visitor);
  }

  @override
  void _appendStringValue(StringBuffer buffer) {
    throw ArgumentError();
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (elements._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('superKeyword'),
    GenerateNodeProperty('period'),
    GenerateNodeProperty('constructorName'),
    GenerateNodeProperty('argumentList'),
  ],
)
final class SuperConstructorInvocationImpl extends ConstructorInitializerImpl
    implements SuperConstructorInvocation {
  @generated
  @override
  final Token superKeyword;

  @generated
  @override
  final Token? period;

  @generated
  SimpleIdentifierImpl? _constructorName;

  @generated
  ArgumentListImpl _argumentList;

  @override
  InternalConstructorElement? element;

  @generated
  SuperConstructorInvocationImpl({
    required this.superKeyword,
    required this.period,
    required SimpleIdentifierImpl? constructorName,
    required ArgumentListImpl argumentList,
  }) : _constructorName = constructorName,
       _argumentList = argumentList {
    _becomeParentOf(constructorName);
    _becomeParentOf(argumentList);
  }

  @generated
  @override
  ArgumentListImpl get argumentList => _argumentList;

  @generated
  set argumentList(ArgumentListImpl argumentList) {
    _argumentList = _becomeParentOf(argumentList);
  }

  @generated
  @override
  Token get beginToken {
    return superKeyword;
  }

  @generated
  @override
  SimpleIdentifierImpl? get constructorName => _constructorName;

  @generated
  set constructorName(SimpleIdentifierImpl? constructorName) {
    _constructorName = _becomeParentOf(constructorName);
  }

  @generated
  @override
  Token get endToken {
    return argumentList.endToken;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('superKeyword', superKeyword)
    ..addToken('period', period)
    ..addNode('constructorName', constructorName)
    ..addNode('argumentList', argumentList);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitSuperConstructorInvocation(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    constructorName?.accept(visitor);
    argumentList.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (constructorName case var constructorName?) {
      if (constructorName._containsOffset(rangeOffset, rangeEnd)) {
        return constructorName;
      }
    }
    if (argumentList._containsOffset(rangeOffset, rangeEnd)) {
      return argumentList;
    }
    return null;
  }
}

/// A super expression.
///
///    superExpression ::=
///        'super'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class SuperExpression implements Expression {
  /// The token representing the `super` keyword.
  Token get superKeyword;
}

@GenerateNodeImpl(childEntitiesOrder: [GenerateNodeProperty('superKeyword')])
final class SuperExpressionImpl extends ExpressionImpl
    implements SuperExpression {
  @generated
  @override
  final Token superKeyword;

  @generated
  SuperExpressionImpl({required this.superKeyword});

  @generated
  @override
  Token get beginToken {
    return superKeyword;
  }

  @generated
  @override
  Token get endToken {
    return superKeyword;
  }

  @override
  Precedence get precedence => Precedence.primary;

  @generated
  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('superKeyword', superKeyword);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSuperExpression(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitSuperExpression(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {}

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    return null;
  }
}

/// A super-initializer formal parameter.
///
///    superFormalParameter ::=
///        ('final' [TypeAnnotation] | 'const' [TypeAnnotation] | 'var' |
///        [TypeAnnotation])?
///        'super' '.' name ([TypeParameterList]? [FormalParameterList])?
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('covariantKeyword', isSuper: true),
    GenerateNodeProperty('requiredKeyword', isSuper: true),
    GenerateNodeProperty('keyword'),
    GenerateNodeProperty('type'),
    GenerateNodeProperty('superKeyword'),
    GenerateNodeProperty('period'),
    GenerateNodeProperty('name', isSuper: true, superNullAssertOverride: true),
    GenerateNodeProperty('typeParameters'),
    GenerateNodeProperty('parameters'),
    GenerateNodeProperty('question'),
  ],
)
final class SuperFormalParameterImpl extends NormalFormalParameterImpl
    implements SuperFormalParameter {
  @generated
  @override
  final Token? keyword;

  @generated
  TypeAnnotationImpl? _type;

  @generated
  @override
  final Token superKeyword;

  @generated
  @override
  final Token period;

  @generated
  TypeParameterListImpl? _typeParameters;

  @generated
  FormalParameterListImpl? _parameters;

  @generated
  @override
  final Token? question;

  @generated
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
  }) : _type = type,
       _typeParameters = typeParameters,
       _parameters = parameters {
    _becomeParentOf(type);
    _becomeParentOf(typeParameters);
    _becomeParentOf(parameters);
  }

  @generated
  @override
  Token get endToken {
    if (question case var question?) {
      return question;
    }
    if (parameters case var parameters?) {
      return parameters.endToken;
    }
    if (typeParameters case var typeParameters?) {
      return typeParameters.endToken;
    }
    return name;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (covariantKeyword case var covariantKeyword?) {
      return covariantKeyword;
    }
    if (requiredKeyword case var requiredKeyword?) {
      return requiredKeyword;
    }
    if (keyword case var keyword?) {
      return keyword;
    }
    if (type case var type?) {
      return type.beginToken;
    }
    return superKeyword;
  }

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isExplicitlyTyped => _parameters != null || _type != null;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @generated
  @override
  Token get name => super.name!;

  @generated
  @override
  FormalParameterListImpl? get parameters => _parameters;

  @generated
  set parameters(FormalParameterListImpl? parameters) {
    _parameters = _becomeParentOf(parameters);
  }

  @generated
  @override
  TypeAnnotationImpl? get type => _type;

  @generated
  set type(TypeAnnotationImpl? type) {
    _type = _becomeParentOf(type);
  }

  @generated
  @override
  TypeParameterListImpl? get typeParameters => _typeParameters;

  @generated
  set typeParameters(TypeParameterListImpl? typeParameters) {
    _typeParameters = _becomeParentOf(typeParameters);
  }

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('covariantKeyword', covariantKeyword)
    ..addToken('requiredKeyword', requiredKeyword)
    ..addToken('keyword', keyword)
    ..addNode('type', type)
    ..addToken('superKeyword', superKeyword)
    ..addToken('period', period)
    ..addToken('name', name)
    ..addNode('typeParameters', typeParameters)
    ..addNode('parameters', parameters)
    ..addToken('question', question);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitSuperFormalParameter(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    type?.accept(visitor);
    typeParameters?.accept(visitor);
    parameters?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (type case var type?) {
      if (type._containsOffset(rangeOffset, rangeEnd)) {
        return type;
      }
    }
    if (typeParameters case var typeParameters?) {
      if (typeParameters._containsOffset(rangeOffset, rangeEnd)) {
        return typeParameters;
      }
    }
    if (parameters case var parameters?) {
      if (parameters._containsOffset(rangeOffset, rangeEnd)) {
        return parameters;
      }
    }
    return null;
  }
}

/// A case in a switch statement.
///
///    switchCase ::=
///        [SimpleIdentifier]* 'case' [Expression] ':' [Statement]*
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class SwitchCase implements SwitchMember {
  /// The expression controlling whether the statements are executed.
  Expression get expression;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('labels', isSuper: true),
    GenerateNodeProperty('keyword', isSuper: true),
    GenerateNodeProperty('expression'),
    GenerateNodeProperty('colon', isSuper: true),
    GenerateNodeProperty('statements', isSuper: true),
  ],
)
final class SwitchCaseImpl extends SwitchMemberImpl implements SwitchCase {
  @generated
  ExpressionImpl _expression;

  @generated
  SwitchCaseImpl({
    required super.labels,
    required super.keyword,
    required ExpressionImpl expression,
    required super.colon,
    required super.statements,
  }) : _expression = expression {
    _becomeParentOf(expression);
  }

  @generated
  @override
  Token get beginToken {
    if (labels.beginToken case var result?) {
      return result;
    }
    return keyword;
  }

  @generated
  @override
  Token get endToken {
    if (statements.endToken case var result?) {
      return result;
    }
    return colon;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNodeList('labels', labels)
    ..addToken('keyword', keyword)
    ..addNode('expression', expression)
    ..addToken('colon', colon)
    ..addNodeList('statements', statements);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSwitchCase(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    labels.accept(visitor);
    expression.accept(visitor);
    statements.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (labels._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    if (statements._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// The default case in a switch statement.
///
///    switchDefault ::=
///        [SimpleIdentifier]* 'default' ':' [Statement]*
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class SwitchDefault implements SwitchMember {}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('labels', isSuper: true),
    GenerateNodeProperty('keyword', isSuper: true),
    GenerateNodeProperty('colon', isSuper: true),
    GenerateNodeProperty('statements', isSuper: true),
  ],
)
final class SwitchDefaultImpl extends SwitchMemberImpl
    implements SwitchDefault {
  @generated
  SwitchDefaultImpl({
    required super.labels,
    required super.keyword,
    required super.colon,
    required super.statements,
  });

  @generated
  @override
  Token get beginToken {
    if (labels.beginToken case var result?) {
      return result;
    }
    return keyword;
  }

  @generated
  @override
  Token get endToken {
    if (statements.endToken case var result?) {
      return result;
    }
    return colon;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNodeList('labels', labels)
    ..addToken('keyword', keyword)
    ..addToken('colon', colon)
    ..addNodeList('statements', statements);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSwitchDefault(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    labels.accept(visitor);
    statements.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (labels._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    if (statements._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// A switch expression.
///
///    switchExpression ::=
///        'switch' '(' [Expression] ')' '{' [SwitchExpressionCase]
///        (',' [SwitchExpressionCase])* ','? '}'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class SwitchExpressionCase implements AstNode {
  /// The arrow separating the pattern from the expression.
  Token get arrow;

  /// The expression whose value is returned from the switch expression if the
  /// pattern matches.
  Expression get expression;

  /// The refutable pattern that must match for the [expression] to be executed.
  GuardedPattern get guardedPattern;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('guardedPattern'),
    GenerateNodeProperty('arrow'),
    GenerateNodeProperty('expression'),
  ],
)
final class SwitchExpressionCaseImpl extends AstNodeImpl
    with AstNodeWithNameScopeMixin
    implements CaseNodeImpl, SwitchExpressionCase {
  @generated
  GuardedPatternImpl _guardedPattern;

  @generated
  @override
  final Token arrow;

  @generated
  ExpressionImpl _expression;

  @generated
  SwitchExpressionCaseImpl({
    required GuardedPatternImpl guardedPattern,
    required this.arrow,
    required ExpressionImpl expression,
  }) : _guardedPattern = guardedPattern,
       _expression = expression {
    _becomeParentOf(guardedPattern);
    _becomeParentOf(expression);
  }

  @generated
  @override
  Token get beginToken {
    return guardedPattern.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return expression.endToken;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @generated
  @override
  GuardedPatternImpl get guardedPattern => _guardedPattern;

  @generated
  set guardedPattern(GuardedPatternImpl guardedPattern) {
    _guardedPattern = _becomeParentOf(guardedPattern);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('guardedPattern', guardedPattern)
    ..addToken('arrow', arrow)
    ..addNode('expression', expression);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitSwitchExpressionCase(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    guardedPattern.accept(visitor);
    expression.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (guardedPattern._containsOffset(rangeOffset, rangeEnd)) {
      return guardedPattern;
    }
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    return null;
  }
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('switchKeyword'),
    GenerateNodeProperty('leftParenthesis'),
    GenerateNodeProperty('expression'),
    GenerateNodeProperty('rightParenthesis'),
    GenerateNodeProperty('leftBracket'),
    GenerateNodeProperty('cases'),
    GenerateNodeProperty('rightBracket'),
  ],
)
final class SwitchExpressionImpl extends ExpressionImpl
    implements SwitchExpression {
  @generated
  @override
  final Token switchKeyword;

  @generated
  @override
  final Token leftParenthesis;

  @generated
  ExpressionImpl _expression;

  @generated
  @override
  final Token rightParenthesis;

  @generated
  @override
  final Token leftBracket;

  @generated
  @override
  final NodeListImpl<SwitchExpressionCaseImpl> cases = NodeListImpl._();

  @generated
  @override
  final Token rightBracket;

  @generated
  SwitchExpressionImpl({
    required this.switchKeyword,
    required this.leftParenthesis,
    required ExpressionImpl expression,
    required this.rightParenthesis,
    required this.leftBracket,
    required List<SwitchExpressionCaseImpl> cases,
    required this.rightBracket,
  }) : _expression = expression {
    _becomeParentOf(expression);
    this.cases._initialize(this, cases);
  }

  @generated
  @override
  Token get beginToken {
    return switchKeyword;
  }

  @generated
  @override
  Token get endToken {
    return rightBracket;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.primary;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('switchKeyword', switchKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('expression', expression)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('cases', cases)
    ..addToken('rightBracket', rightBracket);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSwitchExpression(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitSwitchExpression(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
    cases.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    if (cases._elementContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class SwitchPatternCase implements SwitchMember {
  /// The pattern controlling whether the statements is executed.
  GuardedPattern get guardedPattern;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('labels', isSuper: true),
    GenerateNodeProperty('keyword', isSuper: true),
    GenerateNodeProperty('guardedPattern'),
    GenerateNodeProperty('colon', isSuper: true),
    GenerateNodeProperty('statements', isSuper: true),
  ],
)
final class SwitchPatternCaseImpl extends SwitchMemberImpl
    implements CaseNodeImpl, SwitchPatternCase {
  @generated
  GuardedPatternImpl _guardedPattern;

  @generated
  SwitchPatternCaseImpl({
    required super.labels,
    required super.keyword,
    required GuardedPatternImpl guardedPattern,
    required super.colon,
    required super.statements,
  }) : _guardedPattern = guardedPattern {
    _becomeParentOf(guardedPattern);
  }

  @generated
  @override
  Token get beginToken {
    if (labels.beginToken case var result?) {
      return result;
    }
    return keyword;
  }

  @generated
  @override
  Token get endToken {
    if (statements.endToken case var result?) {
      return result;
    }
    return colon;
  }

  @generated
  @override
  GuardedPatternImpl get guardedPattern => _guardedPattern;

  @generated
  set guardedPattern(GuardedPatternImpl guardedPattern) {
    _guardedPattern = _becomeParentOf(guardedPattern);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNodeList('labels', labels)
    ..addToken('keyword', keyword)
    ..addNode('guardedPattern', guardedPattern)
    ..addToken('colon', colon)
    ..addNodeList('statements', statements);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSwitchPatternCase(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    labels.accept(visitor);
    guardedPattern.accept(visitor);
    statements.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (labels._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    if (guardedPattern._containsOffset(rangeOffset, rangeEnd)) {
      return guardedPattern;
    }
    if (statements._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// A switch statement.
///
///    switchStatement ::=
///        'switch' '(' [Expression] ')' '{' [SwitchCase]* [SwitchDefault]? '}'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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
  late Map<String, PromotableElementImpl> variables;

  SwitchStatementCaseGroup(this.members, this.hasLabels);

  NodeListImpl<StatementImpl> get statements {
    return members.last.statements;
  }
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('switchKeyword'),
    GenerateNodeProperty('leftParenthesis'),
    GenerateNodeProperty('expression'),
    GenerateNodeProperty('rightParenthesis'),
    GenerateNodeProperty('leftBracket'),
    GenerateNodeProperty('members'),
    GenerateNodeProperty('rightBracket'),
  ],
)
final class SwitchStatementImpl extends StatementImpl
    implements SwitchStatement {
  @generated
  @override
  final Token switchKeyword;

  @generated
  @override
  final Token leftParenthesis;

  @generated
  ExpressionImpl _expression;

  @generated
  @override
  final Token rightParenthesis;

  @generated
  @override
  final Token leftBracket;

  @generated
  @override
  final NodeListImpl<SwitchMemberImpl> members = NodeListImpl._();

  @generated
  @override
  final Token rightBracket;

  late final List<SwitchStatementCaseGroup> memberGroups =
      _computeMemberGroups();

  @generated
  SwitchStatementImpl({
    required this.switchKeyword,
    required this.leftParenthesis,
    required ExpressionImpl expression,
    required this.rightParenthesis,
    required this.leftBracket,
    required List<SwitchMemberImpl> members,
    required this.rightBracket,
  }) : _expression = expression {
    _becomeParentOf(expression);
    this.members._initialize(this, members);
  }

  @generated
  @override
  Token get beginToken {
    return switchKeyword;
  }

  @generated
  @override
  Token get endToken {
    return rightBracket;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('switchKeyword', switchKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('expression', expression)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('members', members)
    ..addToken('rightBracket', rightBracket);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSwitchStatement(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
    members.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    if (members._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }

  List<SwitchStatementCaseGroup> _computeMemberGroups() {
    var groups = <SwitchStatementCaseGroup>[];
    var groupMembers = <SwitchMemberImpl>[];
    var groupHasLabels = false;
    for (var member in members) {
      groupMembers.add(member);
      groupHasLabels |= member.labels.isNotEmpty;
      if (member.statements.isNotEmpty) {
        groups.add(SwitchStatementCaseGroup(groupMembers, groupHasLabels));
        groupMembers = [];
        groupHasLabels = false;
      }
    }
    if (groupMembers.isNotEmpty) {
      groups.add(SwitchStatementCaseGroup(groupMembers, groupHasLabels));
    }
    return groups;
  }
}

/// A symbol literal expression.
///
///    symbolLiteral ::=
///        '#' (operator | (identifier ('.' identifier)*))
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class SymbolLiteral implements Literal {
  /// The components of the literal.
  List<Token> get components;

  /// The token introducing the literal.
  Token get poundSign;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('poundSign'),
    GenerateNodeProperty('components'),
  ],
)
final class SymbolLiteralImpl extends LiteralImpl implements SymbolLiteral {
  @generated
  @override
  final Token poundSign;

  @generated
  @override
  final List<Token> components;

  @generated
  SymbolLiteralImpl({required this.poundSign, required this.components});

  @generated
  @override
  Token get beginToken {
    return poundSign;
  }

  @generated
  @override
  Token get endToken {
    return components[components.length - 1];
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('poundSign', poundSign)
    ..addTokenList('components', components);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitSymbolLiteral(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitSymbolLiteral(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {}

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ThisExpression implements Expression {
  /// The token representing the `this` keyword.
  Token get thisKeyword;
}

@GenerateNodeImpl(childEntitiesOrder: [GenerateNodeProperty('thisKeyword')])
final class ThisExpressionImpl extends ExpressionImpl
    implements ThisExpression {
  @generated
  @override
  final Token thisKeyword;

  @generated
  ThisExpressionImpl({required this.thisKeyword});

  @generated
  @override
  Token get beginToken {
    return thisKeyword;
  }

  @generated
  @override
  Token get endToken {
    return thisKeyword;
  }

  @override
  Precedence get precedence => Precedence.primary;

  @generated
  @override
  ChildEntities get _childEntities =>
      ChildEntities()..addToken('thisKeyword', thisKeyword);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitThisExpression(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitThisExpression(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {}

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    return null;
  }
}

/// A throw expression.
///
///    throwExpression ::=
///        'throw' [Expression]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class ThrowExpression implements Expression {
  /// The expression computing the exception to be thrown.
  Expression get expression;

  /// The token representing the `throw` keyword.
  Token get throwKeyword;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('throwKeyword'),
    GenerateNodeProperty('expression'),
  ],
)
final class ThrowExpressionImpl extends ExpressionImpl
    implements ThrowExpression {
  @generated
  @override
  final Token throwKeyword;

  @generated
  ExpressionImpl _expression;

  @generated
  ThrowExpressionImpl({
    required this.throwKeyword,
    required ExpressionImpl expression,
  }) : _expression = expression {
    _becomeParentOf(expression);
  }

  @generated
  @override
  Token get beginToken {
    return throwKeyword;
  }

  @generated
  @override
  Token get endToken {
    return expression.endToken;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @override
  Precedence get precedence => Precedence.assignment;

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('throwKeyword', throwKeyword)
    ..addNode('expression', expression);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitThrowExpression(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitThrowExpression(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class TopLevelVariableDeclaration
    implements CompilationUnitMember {
  /// The `augment` keyword, or `null` if the keyword was absent.
  Token? get augmentKeyword;

  /// The `external` keyword, or `null` if the keyword isn't used.
  Token? get externalKeyword;

  /// The semicolon terminating the declaration.
  Token get semicolon;

  /// The top-level variables being declared.
  VariableDeclarationList get variables;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('augmentKeyword'),
    GenerateNodeProperty('externalKeyword'),
    GenerateNodeProperty('variables'),
    GenerateNodeProperty('semicolon'),
  ],
)
final class TopLevelVariableDeclarationImpl extends CompilationUnitMemberImpl
    implements TopLevelVariableDeclaration {
  @generated
  @override
  final Token? augmentKeyword;

  @generated
  @override
  final Token? externalKeyword;

  @generated
  VariableDeclarationListImpl _variables;

  @generated
  @override
  final Token semicolon;

  @generated
  TopLevelVariableDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.augmentKeyword,
    required this.externalKeyword,
    required VariableDeclarationListImpl variables,
    required this.semicolon,
  }) : _variables = variables {
    _becomeParentOf(variables);
  }

  @override
  Null get declaredFragment => null;

  @generated
  @override
  Token get endToken {
    return semicolon;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (augmentKeyword case var augmentKeyword?) {
      return augmentKeyword;
    }
    if (externalKeyword case var externalKeyword?) {
      return externalKeyword;
    }
    return variables.beginToken;
  }

  @generated
  @override
  VariableDeclarationListImpl get variables => _variables;

  @generated
  set variables(VariableDeclarationListImpl variables) {
    _variables = _becomeParentOf(variables);
  }

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('augmentKeyword', augmentKeyword)
    ..addToken('externalKeyword', externalKeyword)
    ..addNode('variables', variables)
    ..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitTopLevelVariableDeclaration(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    variables.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (variables._containsOffset(rangeOffset, rangeEnd)) {
      return variables;
    }
    return null;
  }
}

/// A try statement.
///
///    tryStatement ::=
///        'try' [Block] ([CatchClause]+ finallyClause? | finallyClause)
///
///    finallyClause ::=
///        'finally' [Block]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('tryKeyword'),
    GenerateNodeProperty('body'),
    GenerateNodeProperty('catchClauses'),
    GenerateNodeProperty('finallyKeyword'),
    GenerateNodeProperty('finallyBlock'),
  ],
)
final class TryStatementImpl extends StatementImpl implements TryStatement {
  @generated
  @override
  final Token tryKeyword;

  @generated
  BlockImpl _body;

  @generated
  @override
  final NodeListImpl<CatchClauseImpl> catchClauses = NodeListImpl._();

  @generated
  @override
  final Token? finallyKeyword;

  @generated
  BlockImpl? _finallyBlock;

  @generated
  TryStatementImpl({
    required this.tryKeyword,
    required BlockImpl body,
    required List<CatchClauseImpl> catchClauses,
    required this.finallyKeyword,
    required BlockImpl? finallyBlock,
  }) : _body = body,
       _finallyBlock = finallyBlock {
    _becomeParentOf(body);
    this.catchClauses._initialize(this, catchClauses);
    _becomeParentOf(finallyBlock);
  }

  @generated
  @override
  Token get beginToken {
    return tryKeyword;
  }

  @generated
  @override
  BlockImpl get body => _body;

  @generated
  set body(BlockImpl body) {
    _body = _becomeParentOf(body);
  }

  @generated
  @override
  Token get endToken {
    if (finallyBlock case var finallyBlock?) {
      return finallyBlock.endToken;
    }
    if (finallyKeyword case var finallyKeyword?) {
      return finallyKeyword;
    }
    if (catchClauses.endToken case var result?) {
      return result;
    }
    return body.endToken;
  }

  @generated
  @override
  BlockImpl? get finallyBlock => _finallyBlock;

  @generated
  set finallyBlock(BlockImpl? finallyBlock) {
    _finallyBlock = _becomeParentOf(finallyBlock);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('tryKeyword', tryKeyword)
    ..addNode('body', body)
    ..addNodeList('catchClauses', catchClauses)
    ..addToken('finallyKeyword', finallyKeyword)
    ..addNode('finallyBlock', finallyBlock);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitTryStatement(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    body.accept(visitor);
    catchClauses.accept(visitor);
    finallyBlock?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (body._containsOffset(rangeOffset, rangeEnd)) {
      return body;
    }
    if (catchClauses._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    if (finallyBlock case var finallyBlock?) {
      if (finallyBlock._containsOffset(rangeOffset, rangeEnd)) {
        return finallyBlock;
      }
    }
    return null;
  }
}

/// The declaration of a type alias.
///
///    typeAlias ::=
///        [ClassTypeAlias]
///      | [FunctionTypeAlias]
///      | [GenericTypeAlias]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class TypeAlias implements NamedCompilationUnitMember {
  /// The `augment` keyword, or `null` if the keyword was absent.
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
sealed class TypeAnnotation implements AstNode {
  /// The question mark indicating that the type is nullable, or `null` if
  /// there's no question mark.
  Token? get question;

  /// The type being named, or `null` if the AST structure hasn't been resolved.
  DartType? get type;
}

sealed class TypeAnnotationImpl extends AstNodeImpl implements TypeAnnotation {
  @override
  TypeImpl? get type;
}

/// A list of type arguments.
///
///    typeArguments ::=
///        '<' typeName (',' typeName)* '>'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class TypeArgumentList implements AstNode {
  /// The type arguments associated with the type.
  NodeList<TypeAnnotation> get arguments;

  /// The left bracket.
  Token get leftBracket;

  /// The right bracket.
  Token get rightBracket;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('leftBracket'),
    GenerateNodeProperty('arguments'),
    GenerateNodeProperty('rightBracket'),
  ],
)
final class TypeArgumentListImpl extends AstNodeImpl
    implements TypeArgumentList {
  @generated
  @override
  final Token leftBracket;

  @generated
  @override
  final NodeListImpl<TypeAnnotationImpl> arguments = NodeListImpl._();

  @generated
  @override
  final Token rightBracket;

  @generated
  TypeArgumentListImpl({
    required this.leftBracket,
    required List<TypeAnnotationImpl> arguments,
    required this.rightBracket,
  }) {
    this.arguments._initialize(this, arguments);
  }

  @generated
  @override
  Token get beginToken {
    return leftBracket;
  }

  @generated
  @override
  Token get endToken {
    return rightBracket;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('arguments', arguments)
    ..addToken('rightBracket', rightBracket);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitTypeArgumentList(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    arguments.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (arguments._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// A literal that has a type associated with it.
///
///    typedLiteral ::=
///        [ListLiteral]
///      | [SetOrMapLiteral]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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
  bool get canBeConst {
    var oldKeyword = constKeyword;
    try {
      constKeyword = KeywordToken(Keyword.CONST, offset);
      return !hasConstantVerifierError;
    } finally {
      constKeyword = oldKeyword;
    }
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

  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (_typeArguments?._containsOffset(rangeOffset, rangeEnd) ?? false) {
      return _typeArguments;
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class TypeLiteral
    implements Expression, CommentReferableExpression {
  /// The type represented by this literal.
  NamedType get type;
}

@GenerateNodeImpl(childEntitiesOrder: [GenerateNodeProperty('type')])
final class TypeLiteralImpl extends CommentReferableExpressionImpl
    implements TypeLiteral {
  @generated
  NamedTypeImpl _type;

  @generated
  TypeLiteralImpl({required NamedTypeImpl type}) : _type = type {
    _becomeParentOf(type);
  }

  @generated
  @override
  Token get beginToken {
    return type.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return type.endToken;
  }

  @override
  Precedence get precedence {
    if (type.typeArguments != null) {
      return Precedence.postfix;
    } else if (type.importPrefix != null) {
      return Precedence.postfix;
    } else {
      return Precedence.primary;
    }
  }

  @generated
  @override
  NamedTypeImpl get type => _type;

  @generated
  set type(NamedTypeImpl type) {
    _type = _becomeParentOf(type);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()..addNode('type', type);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitTypeLiteral(this);

  @generated
  @override
  void resolveExpression(ResolverVisitor resolver, TypeImpl contextType) {
    resolver.visitTypeLiteral(this, contextType: contextType);
  }

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    type.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (type._containsOffset(rangeOffset, rangeEnd)) {
      return type;
    }
    return null;
  }
}

/// A type parameter.
///
///    typeParameter ::=
///        name ('extends' [TypeAnnotation])?
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class TypeParameter implements Declaration {
  /// The upper bound for legal arguments, or `null` if there's no explicit
  /// upper bound.
  TypeAnnotation? get bound;

  @override
  TypeParameterFragment? get declaredFragment;

  /// The token representing the `extends` keyword, or `null` if there's no
  /// explicit upper bound.
  Token? get extendsKeyword;

  /// The name of the type parameter.
  Token get name;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty(
      'varianceKeyword',
      type: _TypeLiteral<Token?>,
      isTokenFinal: false,
      withOverride: false,
    ),
    GenerateNodeProperty('name'),
    GenerateNodeProperty('extendsKeyword', isTokenFinal: false),
    GenerateNodeProperty('bound'),
  ],
)
final class TypeParameterImpl extends DeclarationImpl implements TypeParameter {
  @generated
  Token? varianceKeyword;

  @generated
  @override
  final Token name;

  @generated
  @override
  Token? extendsKeyword;

  @generated
  TypeAnnotationImpl? _bound;

  @override
  TypeParameterFragmentImpl? declaredFragment;

  @generated
  TypeParameterImpl({
    required super.comment,
    required super.metadata,
    required this.varianceKeyword,
    required this.name,
    required this.extendsKeyword,
    required TypeAnnotationImpl? bound,
  }) : _bound = bound {
    _becomeParentOf(bound);
  }

  @generated
  @override
  TypeAnnotationImpl? get bound => _bound;

  @generated
  set bound(TypeAnnotationImpl? bound) {
    _bound = _becomeParentOf(bound);
  }

  @generated
  @override
  Token get endToken {
    if (bound case var bound?) {
      return bound.endToken;
    }
    if (extendsKeyword case var extendsKeyword?) {
      return extendsKeyword;
    }
    return name;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (varianceKeyword case var varianceKeyword?) {
      return varianceKeyword;
    }
    return name;
  }

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('varianceKeyword', varianceKeyword)
    ..addToken('name', name)
    ..addToken('extendsKeyword', extendsKeyword)
    ..addNode('bound', bound);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitTypeParameter(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    bound?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (bound case var bound?) {
      if (bound._containsOffset(rangeOffset, rangeEnd)) {
        return bound;
      }
    }
    return null;
  }
}

/// Type parameters within a declaration.
///
///    typeParameterList ::=
///        '<' [TypeParameter] (',' [TypeParameter])* '>'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class TypeParameterList implements AstNode {
  /// The left angle bracket.
  Token get leftBracket;

  /// The right angle bracket.
  Token get rightBracket;

  /// The type parameters for the type.
  NodeList<TypeParameter> get typeParameters;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('leftBracket'),
    GenerateNodeProperty('typeParameters'),
    GenerateNodeProperty('rightBracket'),
  ],
)
final class TypeParameterListImpl extends AstNodeImpl
    implements TypeParameterList {
  @generated
  @override
  final Token leftBracket;

  @generated
  @override
  final NodeListImpl<TypeParameterImpl> typeParameters = NodeListImpl._();

  @generated
  @override
  final Token rightBracket;

  @generated
  TypeParameterListImpl({
    required this.leftBracket,
    required List<TypeParameterImpl> typeParameters,
    required this.rightBracket,
  }) {
    this.typeParameters._initialize(this, typeParameters);
  }

  @generated
  @override
  Token get beginToken {
    return leftBracket;
  }

  @generated
  @override
  Token get endToken {
    return rightBracket;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('leftBracket', leftBracket)
    ..addNodeList('typeParameters', typeParameters)
    ..addToken('rightBracket', rightBracket);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitTypeParameterList(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    typeParameters.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (typeParameters._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// A directive that references a URI.
///
///    uriBasedDirective ::=
///        [LibraryAugmentationDirective]
///        [ExportDirective]
///      | [ImportDirective]
///      | [PartDirective]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    var childFromSuper = super._childContainingRange(rangeOffset, rangeEnd);
    if (childFromSuper != null) {
      return childFromSuper;
    }
    if (_uri._containsOffset(rangeOffset, rangeEnd)) {
      return _uri;
    }
    return null;
  }

  /// Validate this directive, but don't check for existence.
  ///
  /// Returns a code indicating the problem if a problem was found, or `null` if
  /// there's no problem.
  static UriValidationCode? validateUri(
    bool isImport,
    StringLiteral uriLiteral,
    String? uriContent,
  ) {
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

/// Validation codes returned by [UriBasedDirectiveImpl.validateUri].
class UriValidationCode {
  static const UriValidationCode INVALID_URI = UriValidationCode('INVALID_URI');

  static const UriValidationCode URI_WITH_INTERPOLATION = UriValidationCode(
    'URI_WITH_INTERPOLATION',
  );

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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class VariableDeclaration implements Declaration {
  /// The element declared by this declaration.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if this node
  /// represents the declaration of a top-level variable or a field.
  @Deprecated('Use declaredFragment instead')
  LocalVariableElement? get declaredElement;

  /// The element declared by this declaration.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if this node
  /// represents the declaration of a top-level variable or a field.
  @Deprecated('Use declaredFragment instead')
  LocalVariableElement? get declaredElement2;

  /// The fragment declared by this declaration.
  ///
  /// Returns `null` if the AST structure hasn't been resolved or if this node
  /// represents the declaration of a local variable.
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('name'),
    GenerateNodeProperty('equals'),
    GenerateNodeProperty('initializer'),
  ],
)
final class VariableDeclarationImpl extends DeclarationImpl
    implements VariableDeclaration {
  @generated
  @override
  final Token name;

  @generated
  @override
  final Token? equals;

  @generated
  ExpressionImpl? _initializer;

  @override
  VariableFragmentImpl? declaredFragment;

  /// When this node is read as a part of summaries, we usually don't want
  /// to read the [initializer], but we need to know if there is one in
  /// the code. So, this flag might be set to `true` even though
  /// [initializer] is `null`.
  bool hasInitializer = false;

  @generated
  VariableDeclarationImpl({
    required super.comment,
    required super.metadata,
    required this.name,
    required this.equals,
    required ExpressionImpl? initializer,
  }) : _initializer = initializer {
    _becomeParentOf(initializer);
  }

  @Deprecated('Use declaredFragment instead')
  @override
  LocalVariableElementImpl? get declaredElement {
    return declaredFragment?.element.ifTypeOrNull<LocalVariableElementImpl>();
  }

  @Deprecated('Use declaredFragment instead')
  @override
  LocalVariableElementImpl? get declaredElement2 {
    return declaredElement;
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

  @generated
  @override
  Token get endToken {
    if (initializer case var initializer?) {
      return initializer.endToken;
    }
    if (equals case var equals?) {
      return equals;
    }
    return name;
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    return name;
  }

  @generated
  @override
  ExpressionImpl? get initializer => _initializer;

  @generated
  set initializer(ExpressionImpl? initializer) {
    _initializer = _becomeParentOf(initializer);
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

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('name', name)
    ..addToken('equals', equals)
    ..addNode('initializer', initializer);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitVariableDeclaration(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    initializer?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (initializer case var initializer?) {
      if (initializer._containsOffset(rangeOffset, rangeEnd)) {
        return initializer;
      }
    }
    return null;
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
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('lateKeyword'),
    GenerateNodeProperty('keyword'),
    GenerateNodeProperty('type'),
    GenerateNodeProperty('variables'),
  ],
)
final class VariableDeclarationListImpl extends AnnotatedNodeImpl
    implements VariableDeclarationList {
  @generated
  @override
  final Token? lateKeyword;

  @generated
  @override
  final Token? keyword;

  @generated
  TypeAnnotationImpl? _type;

  @generated
  @override
  final NodeListImpl<VariableDeclarationImpl> variables = NodeListImpl._();

  @generated
  VariableDeclarationListImpl({
    required super.comment,
    required super.metadata,
    required this.lateKeyword,
    required this.keyword,
    required TypeAnnotationImpl? type,
    required List<VariableDeclarationImpl> variables,
  }) : _type = type {
    _becomeParentOf(type);
    this.variables._initialize(this, variables);
  }

  @generated
  @override
  Token get endToken {
    if (variables.endToken case var result?) {
      return result;
    }
    if (type case var type?) {
      return type.endToken;
    }
    if (keyword case var keyword?) {
      return keyword;
    }
    if (lateKeyword case var lateKeyword?) {
      return lateKeyword;
    }
    throw StateError('Expected at least one non-null');
  }

  @generated
  @override
  Token get firstTokenAfterCommentAndMetadata {
    if (lateKeyword case var lateKeyword?) {
      return lateKeyword;
    }
    if (keyword case var keyword?) {
      return keyword;
    }
    if (type case var type?) {
      return type.beginToken;
    }
    if (variables.beginToken case var result?) {
      return result;
    }
    throw StateError('Expected at least one non-null');
  }

  @override
  bool get isConst => keyword?.keyword == Keyword.CONST;

  @override
  bool get isFinal => keyword?.keyword == Keyword.FINAL;

  @override
  bool get isLate => lateKeyword != null;

  @generated
  @override
  TypeAnnotationImpl? get type => _type;

  @generated
  set type(TypeAnnotationImpl? type) {
    _type = _becomeParentOf(type);
  }

  @generated
  @override
  ChildEntities get _childEntities => super._childEntities
    ..addToken('lateKeyword', lateKeyword)
    ..addToken('keyword', keyword)
    ..addNode('type', type)
    ..addNodeList('variables', variables);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitVariableDeclarationList(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    super.visitChildren(visitor);
    type?.accept(visitor);
    variables.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (super._childContainingRange(rangeOffset, rangeEnd) case var result?) {
      return result;
    }
    if (type case var type?) {
      if (type._containsOffset(rangeOffset, rangeEnd)) {
        return type;
      }
    }
    if (variables._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// A list of variables that are being declared in a context where a statement
/// is required.
///
///    variableDeclarationStatement ::=
///        [VariableDeclarationList] ';'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class VariableDeclarationStatement implements Statement {
  /// The semicolon terminating the statement.
  Token get semicolon;

  /// The variables being declared.
  VariableDeclarationList get variables;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('variables'),
    GenerateNodeProperty('semicolon'),
  ],
)
final class VariableDeclarationStatementImpl extends StatementImpl
    implements VariableDeclarationStatement {
  @generated
  VariableDeclarationListImpl _variables;

  @generated
  @override
  final Token semicolon;

  @generated
  VariableDeclarationStatementImpl({
    required VariableDeclarationListImpl variables,
    required this.semicolon,
  }) : _variables = variables {
    _becomeParentOf(variables);
  }

  @generated
  @override
  Token get beginToken {
    return variables.beginToken;
  }

  @generated
  @override
  Token get endToken {
    return semicolon;
  }

  @generated
  @override
  VariableDeclarationListImpl get variables => _variables;

  @generated
  set variables(VariableDeclarationListImpl variables) {
    _variables = _becomeParentOf(variables);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addNode('variables', variables)
    ..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) =>
      visitor.visitVariableDeclarationStatement(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    variables.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (variables._containsOffset(rangeOffset, rangeEnd)) {
      return variables;
    }
    return null;
  }
}

/// The shared interface of [AssignedVariablePattern] and
/// [DeclaredVariablePattern].
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

  VariablePatternImpl({required this.name});

  @override
  VariablePatternImpl? get variablePattern => this;
}

/// A guard in a pattern-based `case` in a `switch` statement, `switch`
/// expression, `if` statement, or `if` element.
///
///    switchCase ::=
///        'when' [Expression]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class WhenClause implements AstNode {
  /// The condition that is evaluated when the pattern matches, that must
  /// evaluate to `true` in order for the [expression] to be executed.
  Expression get expression;

  /// The `when` keyword.
  Token get whenKeyword;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('whenKeyword'),
    GenerateNodeProperty('expression'),
  ],
)
final class WhenClauseImpl extends AstNodeImpl implements WhenClause {
  @generated
  @override
  final Token whenKeyword;

  @generated
  ExpressionImpl _expression;

  @generated
  WhenClauseImpl({
    required this.whenKeyword,
    required ExpressionImpl expression,
  }) : _expression = expression {
    _becomeParentOf(expression);
  }

  @generated
  @override
  Token get beginToken {
    return whenKeyword;
  }

  @generated
  @override
  Token get endToken {
    return expression.endToken;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('whenKeyword', whenKeyword)
    ..addNode('expression', expression);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitWhenClause(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    return null;
  }
}

/// A while statement.
///
///    whileStatement ::=
///        'while' '(' [Expression] ')' [Statement]
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('whileKeyword'),
    GenerateNodeProperty('leftParenthesis'),
    GenerateNodeProperty('condition'),
    GenerateNodeProperty('rightParenthesis'),
    GenerateNodeProperty('body'),
  ],
)
final class WhileStatementImpl extends StatementImpl implements WhileStatement {
  @generated
  @override
  final Token whileKeyword;

  @generated
  @override
  final Token leftParenthesis;

  @generated
  ExpressionImpl _condition;

  @generated
  @override
  final Token rightParenthesis;

  @generated
  StatementImpl _body;

  @generated
  WhileStatementImpl({
    required this.whileKeyword,
    required this.leftParenthesis,
    required ExpressionImpl condition,
    required this.rightParenthesis,
    required StatementImpl body,
  }) : _condition = condition,
       _body = body {
    _becomeParentOf(condition);
    _becomeParentOf(body);
  }

  @generated
  @override
  Token get beginToken {
    return whileKeyword;
  }

  @generated
  @override
  StatementImpl get body => _body;

  @generated
  set body(StatementImpl body) {
    _body = _becomeParentOf(body);
  }

  @generated
  @override
  ExpressionImpl get condition => _condition;

  @generated
  set condition(ExpressionImpl condition) {
    _condition = _becomeParentOf(condition);
  }

  @generated
  @override
  Token get endToken {
    return body.endToken;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('whileKeyword', whileKeyword)
    ..addToken('leftParenthesis', leftParenthesis)
    ..addNode('condition', condition)
    ..addToken('rightParenthesis', rightParenthesis)
    ..addNode('body', body);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitWhileStatement(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    condition.accept(visitor);
    body.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (condition._containsOffset(rangeOffset, rangeEnd)) {
      return condition;
    }
    if (body._containsOffset(rangeOffset, rangeEnd)) {
      return body;
    }
    return null;
  }
}

/// A wildcard pattern.
///
///    wildcardPattern ::=
///        ( 'var' | 'final' | 'final'? [TypeAnnotation])? '_'
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class WildcardPattern implements DartPattern {
  /// The `var` or `final` keyword.
  Token? get keyword;

  /// The `_` token.
  Token get name;

  /// The type that the pattern is required to match, or `null` if any type is
  /// matched.
  TypeAnnotation? get type;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('keyword'),
    GenerateNodeProperty('type'),
    GenerateNodeProperty('name'),
  ],
)
final class WildcardPatternImpl extends DartPatternImpl
    implements WildcardPattern {
  @generated
  @override
  final Token? keyword;

  @generated
  TypeAnnotationImpl? _type;

  @generated
  @override
  final Token name;

  @generated
  WildcardPatternImpl({
    required this.keyword,
    required TypeAnnotationImpl? type,
    required this.name,
  }) : _type = type {
    _becomeParentOf(type);
  }

  @generated
  @override
  Token get beginToken {
    if (keyword case var keyword?) {
      return keyword;
    }
    if (type case var type?) {
      return type.beginToken;
    }
    return name;
  }

  @generated
  @override
  Token get endToken {
    return name;
  }

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

  @generated
  @override
  TypeAnnotationImpl? get type => _type;

  @generated
  set type(TypeAnnotationImpl? type) {
    _type = _becomeParentOf(type);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('keyword', keyword)
    ..addNode('type', type)
    ..addToken('name', name);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitWildcardPattern(this);

  @override
  TypeImpl computePatternSchema(ResolverVisitor resolverVisitor) {
    return resolverVisitor
        .analyzeDeclaredVariablePatternSchema(
          type?.typeOrThrow.wrapSharedTypeView(),
        )
        .unwrapTypeSchemaView();
  }

  @override
  PatternResult resolvePattern(
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

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    type?.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (type case var type?) {
      if (type._containsOffset(rangeOffset, rangeEnd)) {
        return type;
      }
    }
    return null;
  }
}

/// The with clause in a class declaration.
///
///    withClause ::=
///        'with' [NamedType] (',' [NamedType])*
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
abstract final class WithClause implements AstNode {
  /// The names of the mixins that were specified.
  NodeList<NamedType> get mixinTypes;

  /// The token representing the `with` keyword.
  Token get withKeyword;
}

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('withKeyword'),
    GenerateNodeProperty('mixinTypes'),
  ],
)
final class WithClauseImpl extends AstNodeImpl implements WithClause {
  @generated
  @override
  final Token withKeyword;

  @generated
  @override
  final NodeListImpl<NamedTypeImpl> mixinTypes = NodeListImpl._();

  @generated
  WithClauseImpl({
    required this.withKeyword,
    required List<NamedTypeImpl> mixinTypes,
  }) {
    this.mixinTypes._initialize(this, mixinTypes);
  }

  @generated
  @override
  Token get beginToken {
    return withKeyword;
  }

  @generated
  @override
  Token get endToken {
    if (mixinTypes.endToken case var result?) {
      return result;
    }
    return withKeyword;
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('withKeyword', withKeyword)
    ..addNodeList('mixinTypes', mixinTypes);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitWithClause(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    mixinTypes.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (mixinTypes._elementContainingRange(rangeOffset, rangeEnd)
        case var result?) {
      return result;
    }
    return null;
  }
}

/// A yield statement.
///
///    yieldStatement ::=
///        'yield' '*'? [Expression] ‘;’
@AnalyzerPublicApi(message: 'exported by lib/dart/ast/ast.dart')
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

@GenerateNodeImpl(
  childEntitiesOrder: [
    GenerateNodeProperty('yieldKeyword'),
    GenerateNodeProperty('star'),
    GenerateNodeProperty('expression'),
    GenerateNodeProperty('semicolon'),
  ],
)
final class YieldStatementImpl extends StatementImpl implements YieldStatement {
  @generated
  @override
  final Token yieldKeyword;

  @generated
  @override
  final Token? star;

  @generated
  ExpressionImpl _expression;

  @generated
  @override
  final Token semicolon;

  @generated
  YieldStatementImpl({
    required this.yieldKeyword,
    required this.star,
    required ExpressionImpl expression,
    required this.semicolon,
  }) : _expression = expression {
    _becomeParentOf(expression);
  }

  @generated
  @override
  Token get beginToken {
    return yieldKeyword;
  }

  @generated
  @override
  Token get endToken {
    return semicolon;
  }

  @generated
  @override
  ExpressionImpl get expression => _expression;

  @generated
  set expression(ExpressionImpl expression) {
    _expression = _becomeParentOf(expression);
  }

  @generated
  @override
  ChildEntities get _childEntities => ChildEntities()
    ..addToken('yieldKeyword', yieldKeyword)
    ..addToken('star', star)
    ..addNode('expression', expression)
    ..addToken('semicolon', semicolon);

  @generated
  @override
  E? accept<E>(AstVisitor<E> visitor) => visitor.visitYieldStatement(this);

  @generated
  @override
  void visitChildren(AstVisitor visitor) {
    expression.accept(visitor);
  }

  @generated
  @override
  AstNodeImpl? _childContainingRange(int rangeOffset, int rangeEnd) {
    if (expression._containsOffset(rangeOffset, rangeEnd)) {
      return expression;
    }
    return null;
  }
}

/// Mixin implementing shared functionality for AST nodes that can have optional
/// annotations and an optional documentation comment.
base mixin _AnnotatedNodeMixin on AstNodeImpl implements AnnotatedNode {
  CommentImpl? _documentationComment;

  final NodeListImpl<AnnotationImpl> _metadata = NodeListImpl._();

  @override
  CommentImpl? get documentationComment => _documentationComment;

  set documentationComment(CommentImpl? comment) {
    _documentationComment = _becomeParentOf(comment);
  }

  /// The first token following the comment and metadata.
  @override
  Token get firstTokenAfterCommentAndMetadata;

  @override
  NodeListImpl<AnnotationImpl> get metadata => _metadata;

  @override
  List<AstNode> get sortedCommentAndAnnotations {
    var comment = _documentationComment;
    return <AstNode>[if (comment != null) comment, ..._metadata]
      ..sort(AstNode.LEXICAL_ORDER);
  }

  @override
  @mustCallSuper
  ChildEntities get _childEntities {
    return ChildEntities()
      ..addNode('documentationComment', documentationComment)
      ..addNodeList('metadata', metadata);
  }

  /// Returns `true` if there are no annotations before the comment.
  ///
  /// Note that a result of `true` doesn't imply that there's a comment, nor
  /// that there are annotations associated with this node.
  bool _commentIsBeforeAnnotations() {
    if (_documentationComment == null || _metadata.isEmpty) {
      return true;
    }
    Annotation firstAnnotation = _metadata[0];
    return _documentationComment!.offset < firstAnnotation.offset;
  }

  /// Initializes the comment and metadata pointed to by this node.
  ///
  /// Intended to be called from the constructor.
  void _initializeCommentAndAnnotations(
    CommentImpl? comment,
    List<AnnotationImpl>? metadata,
  ) {
    _documentationComment = _becomeParentOf(comment);
    _metadata._initialize(this, metadata);
  }

  /// Visits the AST nodes associated with [documentationComment] and
  /// [metadata] (if any).
  ///
  /// Intended to be called from the [AstNode.visitChildren] method.
  void _visitCommentAndAnnotations(AstVisitor<dynamic> visitor) {
    if (_commentIsBeforeAnnotations()) {
      _documentationComment?.accept(visitor);
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

class _Generated {
  const _Generated();
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
  unresolved,
}
