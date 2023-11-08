// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';

/// TODO(scheglov) https://github.com/dart-lang/sdk/issues/43608
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

/// TODO(scheglov) https://github.com/dart-lang/sdk/issues/43608
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

/// TODO(scheglov) https://github.com/dart-lang/sdk/issues/43608
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

extension AstNodeNullableExtension on AstNode? {
  List<ClassMember> get classMembers {
    final self = this;
    if (self is ClassDeclaration) {
      return self.members;
    } else if (self is EnumDeclaration) {
      return self.members;
    } else if (self is ExtensionDeclaration) {
      return self.members;
    } else if (self is ExtensionTypeDeclaration) {
      return self.members;
    } else if (self is MixinDeclaration) {
      return self.members;
    } else {
      throw UnimplementedError('(${self.runtimeType}) $self');
    }
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
    final self = this;
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
  DartType get typeOrThrow {
    var type = staticType;
    if (type == null) {
      throw StateError('No type: $this');
    }
    return type;
  }
}

extension FormalParameterExtension on FormalParameter {
  bool get isOfLocalFunction {
    return thisOrAncestorOfType<FunctionBody>() != null;
  }

  FormalParameter get notDefault {
    var self = this;
    if (self is DefaultFormalParameter) {
      return self.parameter;
    }
    return self;
  }

  FormalParameterList get parentFormalParameterList {
    var parent = this.parent;
    if (parent is DefaultFormalParameter) {
      parent = parent.parent;
    }
    return parent as FormalParameterList;
  }

  AstNode get typeOrSelf {
    var self = this;
    if (self is SimpleFormalParameter) {
      var type = self.type;
      if (type != null) {
        return type;
      }
    }
    return self;
  }
}

/// TODO(scheglov) https://github.com/dart-lang/sdk/issues/43608
extension IdentifierExtension on Identifier {
  Element? get readElement {
    return _readElement(this);
  }

  SimpleIdentifier get simpleName {
    final self = this;
    if (self is SimpleIdentifier) {
      return self;
    } else {
      return (self as PrefixedIdentifier).identifier;
    }
  }

  Element? get writeElement {
    return _writeElement(this);
  }

  Element? get writeOrReadElement {
    return _writeElement(this) ?? staticElement;
  }

  DartType? get writeOrReadType {
    return _writeType(this) ?? staticType;
  }
}

extension IdentifierImplExtension on IdentifierImpl {
  NamedTypeImpl toNamedType({
    required TypeArgumentListImpl? typeArguments,
    Token? question,
  }) {
    final self = this;
    if (self is PrefixedIdentifierImpl) {
      return NamedTypeImpl(
        importPrefix: ImportPrefixReferenceImpl(
          name: self.prefix.token,
          period: self.period,
        )..element = self.prefix.staticElement,
        name2: self.identifier.token,
        typeArguments: typeArguments,
        question: question,
      )..element = self.identifier.staticElement;
    } else if (self is SimpleIdentifierImpl) {
      return NamedTypeImpl(
        importPrefix: null,
        name2: self.token,
        typeArguments: typeArguments,
        question: question,
      )..element = self.staticElement;
    } else {
      throw UnimplementedError('(${self.runtimeType}) $self');
    }
  }
}

/// TODO(scheglov) https://github.com/dart-lang/sdk/issues/43608
extension IndexExpressionExtension on IndexExpression {
  Element? get writeOrReadElement {
    return _writeElement(this) ?? staticElement;
  }
}

extension ListOfFormalParameterExtension on List<FormalParameter> {
  Iterable<FormalParameterImpl> get asImpl {
    return cast<FormalParameterImpl>();
  }
}

extension MethodDeclarationExtension on MethodDeclaration {
  bool get hasObjectMemberName {
    return const {
      '==',
      'hashCode',
      'toString',
      'runtimeType',
      'noSuchMethod',
    }.contains(name.lexeme);
  }
}

extension NamedTypeExtension on NamedType {
  String get qualifiedName {
    final importPrefix = this.importPrefix;
    if (importPrefix != null) {
      return '${importPrefix.name.lexeme}.${name2.lexeme}';
    } else {
      return name2.lexeme;
    }
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

extension RecordTypeAnnotationExtension on RecordTypeAnnotation {
  List<RecordTypeAnnotationField> get fields {
    return [
      ...positionalFields,
      ...?namedFields?.fields,
    ];
  }
}

extension TypeAnnotationExtension on TypeAnnotation {
  /// Return the static type of this type annotation.
  ///
  /// This accessor should be used on expressions that are expected to
  /// be already resolved. Every such expression must have the type set,
  /// at least `dynamic`.
  DartType get typeOrThrow {
    final type = this.type;
    if (type == null) {
      throw StateError('No type: $this');
    }
    return type;
  }
}
