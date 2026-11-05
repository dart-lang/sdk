// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:collection/collection.dart';

// TODO(scheglov): https://github.com/dart-lang/sdk/issues/43608
@ToBeDeprecated('Used only for the V1 AST.')
Element? _readElement(AstNode node) {
  var parent = node.parent;

  if (parent is AssignmentExpression && parent.leftHandSide == node) {
    return parent.readElement;
  }
  if (parent is PostfixExpression && parent.operand == node) {
    return parent.readElement;
  }
  if (parent is PrefixExpression && parent.operand == node) {
    return parent.readElement;
  }

  if (parent is PrefixedIdentifier && parent.identifier == node) {
    return _readElement(parent);
  }
  if (parent is PropertyAccess && parent.propertyName == node) {
    return _readElement(parent);
  }
  return null;
}

// TODO(scheglov): https://github.com/dart-lang/sdk/issues/43608
@ToBeDeprecated('Used only for the V1 AST.')
Element? _writeElement(AstNode node) {
  var parent = node.parent;

  if (parent is AssignmentExpression && parent.leftHandSide == node) {
    return parent.writeElement;
  }
  if (parent is PostfixExpression && parent.operand == node) {
    return parent.writeElement;
  }
  if (parent is PrefixExpression && parent.operand == node) {
    return parent.writeElement;
  }

  if (parent is PrefixedIdentifier && parent.identifier == node) {
    return _writeElement(parent);
  }
  if (parent is PropertyAccess && parent.propertyName == node) {
    return _writeElement(parent);
  }
  return null;
}

// TODO(scheglov): https://github.com/dart-lang/sdk/issues/43608
@ToBeDeprecated('Used only for the V1 AST.')
DartType? _writeType(AstNode node) {
  var parent = node.parent;

  if (parent is AssignmentExpression && parent.leftHandSide == node) {
    return parent.writeType;
  }
  if (parent is PostfixExpression && parent.operand == node) {
    return parent.writeType;
  }
  if (parent is PrefixExpression && parent.operand == node) {
    return parent.writeType;
  }

  if (parent is PrefixedIdentifier && parent.identifier == node) {
    return _writeType(parent);
  }
  if (parent is PropertyAccess && parent.propertyName == node) {
    return _writeType(parent);
  }
  return null;
}

/// The range from [_begin] to [_end], both tokens included.
class _TokenRange extends SyntacticEntity {
  final Token _begin;
  final Token _end;

  _TokenRange(this._begin, this._end);

  @override
  int get end => _end.end;

  @override
  int get length => end - offset;

  @override
  int get offset => _begin.offset;
}

extension AnnotationExtension on Annotation {
  /// The arguments of the annotation's constructor invocation, or `null` if
  /// the annotation is not a constructor invocation.
  ArgumentList? get argumentList {
    return switch (expression) {
      ConstructorInvocation(:var argumentList) => argumentList,
      _ => null,
    };
  }

  /// The annotation's name, to report diagnostics about the annotation at,
  /// such as `A` in `@A()`, `p.A` in `@p.A.named()`, or `A.named` in
  /// `@A.named()`.
  ///
  /// See [_nameTokens].
  SyntacticEntity get nameEntity {
    var (head, tail) = _nameTokens;
    return _TokenRange(head, tail ?? head);
  }

  /// The source of [nameEntity].
  String get nameSource {
    var (head, tail) = _nameTokens;
    return tail == null ? head.lexeme : '${head.lexeme}.${tail.lexeme}';
  }

  /// The tokens of the annotation's name: the first token of
  /// [Annotation.expression], and the token after the following period, if
  /// any.
  ///
  /// This is a syntactic approximation: for `@A.named()` it is `A.named`, but
  /// for `@p.A.named()` it is `p.A`.
  (Token, Token?) get _nameTokens {
    var head = expression.beginToken;
    var end = expression.endToken;
    if (!identical(head, end)) {
      var period = head.next!;
      if (period.type == TokenType.PERIOD && !identical(period, end)) {
        return (head, period.next!);
      }
    }
    return (head, null);
  }
}

extension ArgumentListExtension on ArgumentList {
  /// Returns the named argument with the given [name], or `null` if none.
  @ToBeDeprecated('Use byName2 instead.')
  NamedArgument? byName(String name) => arguments
      .whereType<NamedArgument>()
      .firstWhereOrNull((e) => e.name.lexeme == name);

  /// Returns the named argument with the given [name], or `null` if none.
  NamedArgument? byName2(String name) => arguments2
      .whereType<NamedArgument>()
      .firstWhereOrNull((e) => e.name.lexeme == name);

  /// Returns the argument with the given [index], or `null` if none.
  @ToBeDeprecated('Use elementAtOrNull2 instead.')
  Argument? elementAtOrNull(int index) {
    if (index < arguments.length) {
      return arguments[index];
    }
    return null;
  }

  /// Returns the argument with the given [index], or `null` if none.
  Argument? elementAtOrNull2(int index) {
    if (index < arguments2.length) {
      return arguments2[index];
    }
    return null;
  }
}

extension ConstructorDeclarationExtension on ConstructorDeclaration {
  bool get isNonRedirectingGenerative {
    // Must be generative.
    if (externalKeyword != null || factoryKeyword != null) {
      return false;
    }

    // Must be non-redirecting.
    for (var initializer in initializers) {
      if (initializer is RedirectingConstructorInvocation) {
        return false;
      }
    }

    return true;
  }
}

extension DartPatternExtension on DartPattern {
  /// Return the matched value type of this pattern.
  ///
  /// This accessor should be used on patterns that are expected to
  /// be already resolved. Every such pattern must have the type set.
  DartType get matchedValueTypeOrThrow {
    var type = matchedValueType;
    if (type == null) {
      throw StateError('No type: $this');
    }
    return type;
  }

  DartType? get requiredType {
    var self = this;
    if (self is DeclaredVariablePattern) {
      return self.type?.typeOrThrow;
    } else if (self is ListPattern) {
      return self.requiredType;
    } else if (self is MapPattern) {
      return self.requiredType;
    } else if (self is WildcardPattern) {
      return self.type?.typeOrThrow;
    }
    return null;
  }
}

extension ExpressionExtension on Expression {
  /// Return the static type of this expression.
  ///
  /// This accessor should be used on expressions that are expected to
  /// be already resolved. Every such expression must have the type set,
  /// at least `dynamic`.
  TypeImpl get typeOrThrow => (this as ExpressionImpl).typeOrThrow;
}

extension ExpressionImplExtension on ExpressionImpl {
  /// Return the static type of this expression.
  ///
  /// This accessor should be used on expressions that are expected to
  /// be already resolved. Every such expression must have the type set,
  /// at least `dynamic`.
  TypeImpl get typeOrThrow {
    var type = staticType;
    if (type == null) {
      throw StateError('No type: $this');
    }
    return type;
  }
}

extension FormalParameterExtension on FormalParameter {
  @ToBeDeprecated('Use isOfLocalFunction2 instead.')
  bool get isOfLocalFunction {
    return thisOrAncestorOfType<FunctionBody>() != null;
  }

  bool get isOfLocalFunction2 {
    return thisOrAncestorOfType2<FunctionBody>() != null;
  }

  @ToBeDeprecated('Use parentFormalParameterList2 instead.')
  FormalParameterList get parentFormalParameterList {
    return switch (parent) {
      FormalParameterList parent => parent,
      _ => throw StateError('Formal parameter has no formal parameter list'),
    };
  }

  FormalParameterList get parentFormalParameterList2 {
    return switch (parent2) {
      FormalParameterList parent => parent,
      DelimitedFormalParameters(parent2: FormalParameterList parent) => parent,
      _ => throw StateError('Formal parameter has no formal parameter list'),
    };
  }

  AstNode get typeOrSelf {
    var type = this.type;
    if (type != null) {
      return type;
    }
    return this;
  }
}

// TODO(scheglov): https://github.com/dart-lang/sdk/issues/43608
@ToBeDeprecated('Use NameExpression or NamedAssignmentTarget instead.')
extension IdentifierExtension on Identifier {
  Element? get readElement {
    return _readElement(this);
  }

  Element? get writeElement {
    return _writeElement(this);
  }

  Element? get writeOrReadElement {
    return _writeElement(this) ?? element;
  }

  DartType? get writeOrReadType {
    return _writeType(this) ?? staticType;
  }
}

// TODO(scheglov): https://github.com/dart-lang/sdk/issues/43608
@ToBeDeprecated('Use IndexExpression2 or IndexAssignmentTarget instead.')
extension IndexExpressionExtension on IndexExpression {
  Element? get writeOrReadElement {
    return _writeElement(this) ?? element;
  }
}

extension IndexReadResolutionImplExtension on IndexReadResolutionImpl {
  /// The method selected by successful resolution or error recovery.
  ///
  /// Its parameter list need not be valid for `operator []`.
  InternalMethodElement? get elementOrRecovery => switch (this) {
    MethodIndexReadResolutionImpl(:var element) => element,
    InvalidIndexReadResolutionImpl(:var recoveryElement) => recoveryElement,
    DynamicIndexReadResolutionImpl() => null,
  };
}

extension IndexWriteResolutionImplExtension on IndexWriteResolutionImpl {
  /// The method selected by successful resolution or error recovery.
  ///
  /// Its parameter list need not be valid for `operator []=`.
  InternalMethodElement? get elementOrRecovery => switch (this) {
    MethodIndexWriteResolutionImpl(:var element) => element,
    InvalidIndexWriteResolutionImpl(:var recoveryElement) => recoveryElement,
    DynamicIndexWriteResolutionImpl() => null,
  };
}

extension ListOfFormalParameterExtension on List<FormalParameter> {
  Iterable<FormalParameterImpl> get asImpl {
    return cast<FormalParameterImpl>();
  }
}

extension NamedTypeExtension on NamedType {
  String get qualifiedName {
    var importPrefix = this.importPrefix;
    if (importPrefix != null) {
      return '${importPrefix.name.lexeme}.${name.lexeme}';
    } else {
      return name.lexeme;
    }
  }
}

extension NullableStringExtension on String? {
  bool get isEmptyOrNull {
    var str = this;
    if (str == null) return true;
    if (str.isEmpty) return true;
    return false;
  }
}

extension PatternFieldImplExtension on PatternFieldImpl {
  /// A [SyntacticEntity] which can be used in error reporting, which is valid
  /// for both explicit getter names (like `Rect(width: var w, height: var h)`)
  /// and implicit getter names (like `Rect(:var width, :var height)`).
  SyntacticEntity get errorEntity {
    var fieldName = name;
    if (fieldName == null) {
      return this;
    }
    var fieldNameName = fieldName.name;
    if (fieldNameName == null) {
      var variablePattern = pattern.variablePattern;
      return variablePattern?.name ?? this;
    } else {
      return fieldNameName;
    }
  }
}

extension ReadResolutionExtension on ReadResolution {
  /// The element selected by successful resolution or error recovery.
  ///
  /// The recovery element need not support reading.
  Element? get elementOrRecovery => switch (this) {
    InvalidIndexReadResolution(:var recoveryElement) => recoveryElement,
    InvalidNamedReadResolution(:var recoveryElement) => recoveryElement,
    _ => element,
  };
}

extension RecordTypeAnnotationExtension on RecordTypeAnnotation {
  List<RecordTypeAnnotationField> get fields {
    return [...positionalFields, ...?namedFields?.fields];
  }
}

extension TypeAnnotationExtension on TypeAnnotation {
  /// Return the static type of this type annotation.
  ///
  /// This accessor should be used on expressions that are expected to
  /// be already resolved. Every such expression must have the type set,
  /// at least `dynamic`.
  TypeImpl get typeOrThrow => (this as TypeAnnotationImpl).typeOrThrow;
}

extension TypeAnnotationImplExtension on TypeAnnotationImpl {
  /// Return the static type of this type annotation.
  ///
  /// This accessor should be used on expressions that are expected to
  /// be already resolved. Every such expression must have the type set,
  /// at least `dynamic`.
  TypeImpl get typeOrThrow {
    var type = this.type;
    if (type == null) {
      throw StateError('No type: $this');
    }
    return type;
  }
}

extension WriteResolutionExtension on WriteResolution {
  /// The element selected by successful resolution or error recovery.
  ///
  /// The recovery element need not support writing.
  Element? get elementOrRecovery => switch (this) {
    InvalidIndexWriteResolution(:var recoveryElement) => recoveryElement,
    InvalidNamedWriteResolution(:var recoveryElement) => recoveryElement,
    _ => element,
  };
}
