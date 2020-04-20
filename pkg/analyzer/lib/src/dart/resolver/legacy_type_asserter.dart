// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

/// A visitor to assert that legacy libraries deal with legacy types.
///
/// Intended to be used via the static method
/// [LegacyTypeAsserter.assertLegacyTypes], inside an `assert()` node.
///
/// Has a defense against being accidentally run outside of an assert statement,
/// but that can be overridden if needed.
///
/// Checks that the static type of every node, as well as the elements of many
/// nodes, have legacy types, and asserts that the legacy types are deep legacy
/// types.
class LegacyTypeAsserter extends GeneralizingAstVisitor {
  final Set<DartType> _visitedTypes = {};

  LegacyTypeAsserter({bool requireIsDebug = true}) {
    if (requireIsDebug) {
      bool isDebug = false;

      assert(() {
        isDebug = true;
        return true;
      }());

      if (!isDebug) {
        throw UnsupportedError(
            'Legacy type asserter is being run outside of a debug environment');
      }
    }
  }

  @override
  visitClassMember(ClassMember node) {
    final element = node.declaredElement;
    if (element is ExecutableElement) {
      _assertLegacyType(element?.type);
    }
    super.visitClassMember(node);
  }

  @override
  visitCompilationUnit(CompilationUnit node) {
    if (!node.featureSet.isEnabled(Feature.non_nullable)) {
      super.visitCompilationUnit(node);
    }
  }

  @override
  visitDeclaredIdentifier(DeclaredIdentifier node) {
    _assertLegacyType(node.declaredElement?.type);
    super.visitDeclaredIdentifier(node);
  }

  @override
  visitExpression(Expression node) {
    _assertLegacyType(node.staticType);
    _assertLegacyType(node.staticParameterElement?.type);
    super.visitExpression(node);
  }

  @override
  visitFormalParameter(FormalParameter node) {
    _assertLegacyType(node.declaredElement?.type);
    super.visitFormalParameter(node);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    _assertLegacyType(node.declaredElement?.type);
    super.visitFunctionDeclaration(node);
  }

  @override
  visitInvocationExpression(InvocationExpression node) {
    _assertLegacyType(node.staticInvokeType);
    node.typeArgumentTypes?.forEach(_assertLegacyType);
    return super.visitInvocationExpression(node);
  }

  @override
  visitTypeAnnotation(TypeAnnotation node) {
    _assertLegacyType(node.type);
    super.visitTypeAnnotation(node);
  }

  @override
  visitTypeName(TypeName node) {
    _assertLegacyType(node.type);
    super.visitTypeName(node);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    _assertLegacyType(node.declaredElement?.type);
    super.visitVariableDeclaration(node);
  }

  void _assertLegacyType(DartType type) {
    if (type == null) {
      return;
    }

    if (type.isDynamic || type.isVoid) {
      return;
    }

    if (type.isBottom && type.isDartCoreNull) {
      // Never?, which is ok.
      //
      // Note: we could allow Null? and Null, but we really should be able to
      // guarantee that we are only working with Null*, so that's what this
      // currently does.
      return;
    }

    if (!_visitedTypes.add(type)) {
      return;
    }

    if (type is TypeParameterType) {
      _assertLegacyType(type.bound);
    } else if (type is InterfaceType) {
      type.typeArguments.forEach(_assertLegacyType);
    } else if (type is FunctionType) {
      _assertLegacyType(type.returnType);
      type.parameters.map((param) => param.type).forEach(_assertLegacyType);
      type.typeArguments.forEach(_assertLegacyType);
      type.typeFormals.map((param) => param.bound).forEach(_assertLegacyType);
    }

    if (type.nullabilitySuffix == NullabilitySuffix.star) {
      return;
    }

    throw StateError('Expected all legacy types, but got '
        '${type.getDisplayString(withNullability: true)} '
        '(${type.runtimeType})');
  }

  static bool assertLegacyTypes(CompilationUnit compilationUnit) {
    LegacyTypeAsserter().visitCompilationUnit(compilationUnit);
    return true;
  }
}
