// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

/// Visitor that applies resolution data from the front end (obtained via
/// [ResolutionStorer]) to an analyzer AST.
class ResolutionApplier extends GeneralizingAstVisitor {
  final List<DartType> _types;
  int _typeIndex = 0;

  ResolutionApplier(this._types);

  /// Verifies that all types passed to the constructor have been applied.
  void checkDone() {
    if (_typeIndex != _types.length) {
      throw new StateError(
          'Some types were not consumed, starting at ${_types[_typeIndex]}');
    }
  }

  @override
  void visitExpression(Expression node) {
    visitNode(node);
    node.staticType = _getTypeFor(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    node.target?.accept(this);
    // TODO(paulberry): store resolution of node.methodName.
    // TODO(paulberry): store resolution of node.typeArguments.
    node.argumentList.accept(this);
    node.staticType = _getTypeFor(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.variables.length != 1) {
      // TODO(paulberry): handle this case
      throw new UnimplementedError('Multiple variables in one declaration');
    }
    if (node.metadata.isNotEmpty) {
      // TODO(paulberry): handle this case
      throw new UnimplementedError('Metadata on a variable declaration list');
    }
    node.variables.accept(this);
    if (node.type != null) {
      _applyToTypeAnnotation(node.variables[0].name.staticType, node.type);
    }
  }

  void _applyToTypeAnnotation(DartType type, TypeAnnotation typeAnnotation) {
    // TODO(paulberry): implement this.
  }

  DartType _getTypeFor(AstNode node) {
    return _types[_typeIndex++];
  }
}

/// Visitor that applies resolution data from the front end (obtained via
/// [ResolutionStorer]) to an analyzer AST, and also checks file offsets to
/// verify that the types are applied to the correct subexpressions.
class ValidatingResolutionApplier extends ResolutionApplier {
  /// Indicates whether debug messages should be printed.
  static const bool _debug = false;

  final List<int> _typeOffsets;

  ValidatingResolutionApplier(List<DartType> types, this._typeOffsets)
      : super(types);

  @override
  void checkDone() {
    if (_typeIndex != _types.length) {
      throw new StateError('Some types were not consumed, starting at offset '
          '${_typeOffsets[_typeIndex]}');
    }
  }

  @override
  DartType _getTypeFor(AstNode node) {
    if (_debug) print('Getting type for $node');
    if (node.offset != _typeOffsets[_typeIndex]) {
      throw new StateError(
          'Expected a type for offset ${node.offset}; got one for '
          '${_typeOffsets[_typeIndex]}');
    }
    return super._getTypeFor(node);
  }
}
