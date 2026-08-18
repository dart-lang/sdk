// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/utilities/extensions/version.dart';
import 'package:pub_semver/pub_semver.dart';

/// A visitor that finds code that assumes a later version of the SDK than the
/// minimum version required by the SDK constraints in `pubspec.yaml`.
class SdkConstraintVerifier extends RecursiveAstVisitor2<void> {
  /// The error reporter to be used to report errors.
  final DiagnosticReporter _errorReporter;

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
  bool get checkTripleShift => _checkTripleShift ??= !before_2_14_0
      .intersect(_versionConstraint)
      .isEmpty;

  @override
  void visitArgumentList(ArgumentList node) {
    // Check (optional) positional arguments.
    // Named arguments are checked in [NamedArgument].
    for (var argument in node.arguments2) {
      if (argument is! NamedArgument) {
        var parameter = argument.correspondingParameter;
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
  void visitBinaryOperatorInvocation(BinaryOperatorInvocation node) {
    if (checkTripleShift) {
      TokenType operatorType = node.operator.type;
      if (operatorType == TokenType.GT_GT_GT) {
        _errorReporter.report(diag.sdkVersionGtGtGtOperator.at(node.operator));
      }
    }
    super.visitBinaryOperatorInvocation(node);
  }

  @override
  void visitCascadeIndexExpression(CascadeIndexExpression node) {
    var element = switch (node.resolution) {
      MethodIndexReadResolution(:var element) => element,
      InvalidIndexReadResolution(
        recovery: MethodIndexReadResolution(:var element),
      ) =>
        element,
      _ => null,
    };
    _checkSinceSdkVersion(element, node);
    super.visitCascadeIndexExpression(node);
  }

  @override
  void visitCascadePropertyExtraction(CascadePropertyExtraction node) {
    var element = switch (node.resolution) {
      NamedReadResolutionWithElement(:var element) => element,
      _ => null,
    };
    _checkSinceSdkVersion(element, node, errorEntity: node.propertyName);
    super.visitCascadePropertyExtraction(node);
  }

  @override
  void visitCompoundAssignment(CompoundAssignment node) {
    var target = node.target;
    if (target
        case IndexAssignmentTarget(
              read: MethodIndexReadResolution(:var element),
            ) ||
            CascadeIndexAssignmentTarget(
              read: MethodIndexReadResolution(:var element),
            )) {
      _checkSinceSdkVersion(element, target);
    }
    if (target
        case IndexAssignmentTarget(
              write: MethodIndexWriteResolution(:var element),
            ) ||
            CascadeIndexAssignmentTarget(
              write: MethodIndexWriteResolution(:var element),
            )) {
      _checkSinceSdkVersion(element, target);
    }
    var read = switch (target) {
      PropertyAssignmentTarget(:var read) => read,
      UnqualifiedNameAssignmentTarget(:var read) => read,
      _ => null,
    };
    var write = switch (target) {
      PropertyAssignmentTarget(:var write) => write,
      UnqualifiedNameAssignmentTarget(:var write) => write,
      _ => null,
    };
    var errorEntity = switch (target) {
      PropertyAssignmentTarget() => target.propertyName,
      UnqualifiedNameAssignmentTarget() => target.name,
      _ => null,
    };
    if (read case NamedReadResolutionWithElement(:var element)) {
      _checkSinceSdkVersion(element, target, errorEntity: errorEntity);
    }
    if (write case NamedWriteResolutionWithElement(:var element)) {
      _checkSinceSdkVersion(element, target, errorEntity: errorEntity);
    }
    _checkSinceSdkVersion(node.element, node);
    super.visitCompoundAssignment(node);
  }

  @override
  void visitConstructorReference2(ConstructorReference2 node) {
    var typeReference = node.typeReference;
    _checkSinceSdkVersion(
      typeReference.element,
      typeReference,
      errorEntity: typeReference.name,
    );
    _checkSinceSdkVersion(
      node.element,
      node,
      errorEntity: node.selector?.name2 ?? typeReference.name,
    );
    super.visitConstructorReference2(node);
  }

  @override
  void visitConstructorTearOff(ConstructorTearOff node) {
    var typeReference = node.typeReference;
    _checkSinceSdkVersion(
      typeReference.element,
      typeReference,
      errorEntity: typeReference.name,
    );
    _checkSinceSdkVersion(node.element, node, errorEntity: node.selector.name2);
    super.visitConstructorTearOff(node);
  }

  @override
  void visitDirectAssignment(DirectAssignment node) {
    var target = node.target;
    if (target
        case IndexAssignmentTarget(
              write: MethodIndexWriteResolution(:var element),
            ) ||
            CascadeIndexAssignmentTarget(
              write: MethodIndexWriteResolution(:var element),
            )) {
      _checkSinceSdkVersion(element, target);
    }
    var write = switch (target) {
      PropertyAssignmentTarget(:var write) => write,
      UnqualifiedNameAssignmentTarget(:var write) => write,
      _ => null,
    };
    if (write case NamedWriteResolutionWithElement(:var element)) {
      _checkSinceSdkVersion(
        element,
        target,
        errorEntity: switch (target) {
          PropertyAssignmentTarget() => target.propertyName,
          UnqualifiedNameAssignmentTarget() => target.name,
          _ => null,
        },
      );
    }
    super.visitDirectAssignment(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _checkSinceSdkVersion(node.element, node);
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    // Don't flag references to either `Future` or `Stream` within a combinator.
  }

  @override
  void visitIfNullAssignment(IfNullAssignment node) {
    var target = node.target;
    if (target
        case IndexAssignmentTarget(
              read: MethodIndexReadResolution(:var element),
            ) ||
            CascadeIndexAssignmentTarget(
              read: MethodIndexReadResolution(:var element),
            )) {
      _checkSinceSdkVersion(element, target);
    }
    if (target
        case IndexAssignmentTarget(
              write: MethodIndexWriteResolution(:var element),
            ) ||
            CascadeIndexAssignmentTarget(
              write: MethodIndexWriteResolution(:var element),
            )) {
      _checkSinceSdkVersion(element, target);
    }
    if (target is UnqualifiedNameAssignmentTarget) {
      if (target.read case NamedReadResolutionWithElement(:var element)) {
        _checkSinceSdkVersion(element, target);
      }
      if (target.write case NamedWriteResolutionWithElement(:var element)) {
        _checkSinceSdkVersion(element, target);
      }
    }
    super.visitIfNullAssignment(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    _checkSinceSdkVersion(node.element, node);
    super.visitIndexExpression(node);
  }

  @override
  void visitIndexExpression2(IndexExpression2 node) {
    var element = switch (node.resolution) {
      MethodIndexReadResolution(:var element) => element,
      InvalidIndexReadResolution(
        recovery: MethodIndexReadResolution(:var element),
      ) =>
        element,
      _ => null,
    };
    _checkSinceSdkVersion(element, node);
    super.visitIndexExpression2(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (checkTripleShift && node.isOperator && node.name.lexeme == '>>>') {
      _errorReporter.report(diag.sdkVersionGtGtGtOperator.at(node.name));
    }
    super.visitMethodDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _checkSinceSdkVersion(node.methodName.element, node);
    super.visitMethodInvocation(node);
  }

  @override
  void visitNamedArgument(NamedArgument node) {
    _checkSinceSdkVersion(
      node.correspondingParameter,
      node,
      errorEntity: node.name,
    );
    super.visitNamedArgument(node);
  }

  @override
  void visitNamedType(NamedType node) {
    _checkSinceSdkVersion(node.element, node);
    super.visitNamedType(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _checkSinceSdkVersion(node.element, node);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _checkSinceSdkVersion(node.propertyName.element, node);
    super.visitPropertyAccess(node);
  }

  @override
  void visitReceiverPropertyExtraction(ReceiverPropertyExtraction node) {
    var element = switch (node.resolution) {
      NamedReadResolutionWithElement(:var element) => element,
      _ => null,
    };
    _checkSinceSdkVersion(element, node);
    super.visitReceiverPropertyExtraction(node);
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
    _checkSinceSdkVersion(node.element, node);
  }

  void _checkSinceSdkVersion(
    Element? element,
    AstNode target, {
    SyntacticEntity? errorEntity,
  }) {
    element = element?.nonSynthetic;
    if (element?.sinceSdkVersion case var sinceSdkVersion?) {
      if (!_versionConstraint.requiresAtLeast(sinceSdkVersion)) {
        if (errorEntity == null) {
          if (!_shouldReportEnumIndex(target, element!)) {
            return;
          }
          if (target is AssignmentExpression) {
            target = target.leftHandSide2;
          }
          if (target is ExtensionOverride) {
            errorEntity = target.name;
          } else if (target is FunctionExpressionInvocation) {
            errorEntity = target.argumentList;
          } else if (target is IndexExpression2) {
            errorEntity = target.leftBracket;
          } else if (target is IndexExpression) {
            errorEntity = target.leftBracket;
          } else if (target is IndexAssignmentTarget) {
            errorEntity = target.leftBracket;
          } else if (target is MethodInvocation) {
            errorEntity = target.methodName;
          } else if (target is NamedType) {
            errorEntity = target.name;
          } else if (target is PrefixedIdentifier) {
            errorEntity = target.identifier;
          } else if (target is PropertyAccess) {
            errorEntity = target.propertyName;
          } else if (target is PropertyExtraction) {
            errorEntity = target.propertyName;
          } else if (target is SimpleIdentifier) {
            errorEntity = target;
          } else {
            throw UnimplementedError('(${target.runtimeType}) $target');
          }
        }
        _errorReporter.report(
          diag.sdkVersionSince
              .withArguments(
                availableVersion: sinceSdkVersion.toString(),
                versionConstraints: _versionConstraint.toString(),
              )
              .at(errorEntity),
        );
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
        targetType = node.realTarget2.staticType;
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
