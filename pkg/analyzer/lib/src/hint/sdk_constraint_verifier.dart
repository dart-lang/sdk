// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/utilities/extensions/version.dart';
import 'package:pub_semver/pub_semver.dart';

/// A visitor that finds code that assumes a later version of the SDK than the
/// minimum version required by the SDK constraints in `pubspec.yaml`.
class SdkConstraintVerifier extends RecursiveAstVisitor<void> {
  /// The error reporter to be used to report errors.
  final ErrorReporter _errorReporter;

  /// The version constraint for the SDK.
  final VersionConstraint _versionConstraint;

  /// A cached flag indicating whether references to the triple-shift features
  /// need to be checked. Use [checkTripleShift] to access this field.
  bool? _checkTripleShift;

  /// Initialize a newly created verifier to use the given [_errorReporter] to
  /// report errors.
  SdkConstraintVerifier(this._errorReporter, this._versionConstraint);

  /// Return a range covering every version up to, but not including, 2.14.0.
  VersionRange get before_2_14_0 => VersionRange(max: Version.parse('2.14.0'));

  /// Return a range covering every version up to, but not including, 2.1.0.
  VersionRange get before_2_1_0 => VersionRange(max: Version.parse('2.1.0'));

  /// Return a range covering every version up to, but not including, 2.2.0.
  VersionRange get before_2_2_0 => VersionRange(max: Version.parse('2.2.0'));

  /// Return a range covering every version up to, but not including, 2.2.2.
  VersionRange get before_2_2_2 => VersionRange(max: Version.parse('2.2.2'));

  /// Return a range covering every version up to, but not including, 2.5.0.
  VersionRange get before_2_5_0 => VersionRange(max: Version.parse('2.5.0'));

  /// Return a range covering every version up to, but not including, 2.6.0.
  VersionRange get before_2_6_0 => VersionRange(max: Version.parse('2.6.0'));

  /// Return `true` if references to the constant-update-2018 features need to
  /// be checked.
  bool get checkTripleShift => _checkTripleShift ??=
      !before_2_14_0.intersect(_versionConstraint).isEmpty;

  @override
  void visitArgumentList(ArgumentList node) {
    // Check (optional) positional arguments.
    // Named arguments are checked in [NamedExpression].
    for (var argument in node.arguments) {
      if (argument is! NamedExpression) {
        var parameter = argument.staticParameterElement;
        _checkSinceSdkVersion(parameter, node, errorEntity: argument);
      }
    }

    super.visitArgumentList(node);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _checkSinceSdkVersion(node.readElement, node);
    _checkSinceSdkVersion(node.writeElement, node);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (checkTripleShift) {
      TokenType operatorType = node.operator.type;
      if (operatorType == TokenType.GT_GT_GT) {
        _errorReporter.atToken(
          node.operator,
          WarningCode.SDK_VERSION_GT_GT_GT_OPERATOR,
        );
      }
    }
    super.visitBinaryExpression(node);
  }

  @override
  void visitConstructorName(ConstructorName node) {
    _checkSinceSdkVersion(node.staticElement, node);
    super.visitConstructorName(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _checkSinceSdkVersion(node.staticElement, node);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    // Don't flag references to either `Future` or `Stream` within a combinator.
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _checkSinceSdkVersion(node.staticElement, node);
    super.visitIndexExpression(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (checkTripleShift && node.isOperator && node.name.lexeme == '>>>') {
      _errorReporter.atToken(
        node.name,
        WarningCode.SDK_VERSION_GT_GT_GT_OPERATOR,
      );
    }
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _checkSinceSdkVersion(node.methodName.staticElement, node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitNamedType(NamedType node) {
    _checkSinceSdkVersion(node.element, node);
    super.visitNamedType(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _checkSinceSdkVersion(node.staticElement, node);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _checkSinceSdkVersion(node.propertyName.staticElement, node);
    super.visitPropertyAccess(node);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    // Don't flag references to either `Future` or `Stream` within a combinator.
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return;
    }
    _checkSinceSdkVersion(node.staticElement, node);
  }

  void _checkSinceSdkVersion(
    Element? element,
    AstNode target, {
    SyntacticEntity? errorEntity,
  }) {
    if (element != null) {
      var sinceSdkVersion = element.sinceSdkVersion;
      if (sinceSdkVersion != null) {
        if (!_versionConstraint.requiresAtLeast(sinceSdkVersion)) {
          if (errorEntity == null) {
            if (!_shouldReportEnumIndex(target, element)) {
              return;
            }
            if (target is AssignmentExpression) {
              target = target.leftHandSide;
            }
            if (target is ConstructorName) {
              errorEntity = target.name?.token ?? target.type.name2;
            } else if (target is ExtensionOverride) {
              errorEntity = target.name;
            } else if (target is FunctionExpressionInvocation) {
              errorEntity = target.argumentList;
            } else if (target is IndexExpression) {
              errorEntity = target.leftBracket;
            } else if (target is MethodInvocation) {
              errorEntity = target.methodName;
            } else if (target is NamedType) {
              errorEntity = target.name2;
            } else if (target is PrefixedIdentifier) {
              errorEntity = target.identifier;
            } else if (target is PropertyAccess) {
              errorEntity = target.propertyName;
            } else if (target is SimpleIdentifier) {
              errorEntity = target;
            } else {
              throw UnimplementedError('(${target.runtimeType}) $target');
            }
          }
          _errorReporter.atEntity(
            errorEntity,
            WarningCode.SDK_VERSION_SINCE,
            arguments: [
              sinceSdkVersion.toString(),
              _versionConstraint.toString(),
            ],
          );
        }
      }
    }
  }

  /// Returns `false` if [element] is the `index` property, and the target
  /// of [node] is exactly the `Enum` class from `dart:core`. We have already
  /// checked that the property is not available to the enclosing package.
  ///
  /// Returns `true` if [element] is something else, or if the target is a
  /// concrete enum. The `index` was always available for concrete enums,
  /// but there was no common `Enum` supertype for all enums.
  static bool _shouldReportEnumIndex(AstNode node, Element element) {
    if (element is PropertyAccessorElement && element.name == 'index') {
      DartType? targetType;
      if (node is PrefixedIdentifier) {
        targetType = node.prefix.staticType;
      } else if (node is PropertyAccess) {
        targetType = node.realTarget.staticType;
      }
      if (targetType != null) {
        var targetElement = targetType.element;
        return targetElement is ClassElement && targetElement.isDartCoreEnum;
      }
      return false;
    } else {
      return true;
    }
  }
}
