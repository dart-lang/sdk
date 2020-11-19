// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/visitor.dart';
import '../frontend_server.dart';

// Transformer/visitor for toString
// If we add any more of these, they really should go into a separate library.

/// A [RecursiveVisitor] that replaces [Object.toString] overrides with
/// `super.toString()`.
class ToStringVisitor extends RecursiveVisitor<void> {
  /// The [packageUris] must not be null.
  ToStringVisitor(this._packageUris) : assert(_packageUris != null);

  /// A set of package URIs to apply this transformer to, e.g. 'dart:ui' and
  /// 'package:flutter/foundation.dart'.
  final Set<String> _packageUris;

  /// Turn 'dart:ui' into 'dart:ui', or
  /// 'package:flutter/src/semantics_event.dart' into 'package:flutter'.
  String _importUriToPackage(Uri importUri) =>
      '${importUri.scheme}:${importUri.pathSegments.first}';

  bool _isInTargetPackage(Procedure node) {
    return _packageUris
        .contains(_importUriToPackage(node.enclosingLibrary.importUri));
  }

  bool _hasKeepAnnotation(Procedure node) {
    for (ConstantExpression expression
        in node.annotations.whereType<ConstantExpression>()) {
      if (expression.constant is! InstanceConstant) {
        continue;
      }
      final InstanceConstant constant = expression.constant as InstanceConstant;
      if (constant.classNode.name == '_KeepToString' &&
          constant.classNode.enclosingLibrary.importUri.toString() ==
              'dart:ui') {
        return true;
      }
    }
    return false;
  }

  @override
  void visitProcedure(Procedure node) {
    if (node.name.text == 'toString' &&
        node.enclosingClass != null &&
        node.enclosingLibrary != null &&
        !node.isStatic &&
        !node.isAbstract &&
        !node.enclosingClass.isEnum &&
        _isInTargetPackage(node) &&
        !_hasKeepAnnotation(node)) {
      node.function.body.replaceWith(
        ReturnStatement(
          SuperMethodInvocation(
            node.name,
            Arguments(<Expression>[]),
          ),
        ),
      );
    }
  }

  @override
  void defaultMember(Member node) {}
}

/// Replaces [Object.toString] overrides with calls to super for the specified
/// [packageUris].
class ToStringTransformer extends ProgramTransformer {
  /// The [packageUris] parameter must not be null, but may be empty.
  ToStringTransformer(this._child, this._packageUris)
      : assert(_packageUris != null);

  final ProgramTransformer _child;

  /// A set of package URIs to apply this transformer to, e.g. 'dart:ui' and
  /// 'package:flutter/foundation.dart'.
  final Set<String> _packageUris;

  @override
  void transform(Component component) {
    assert(_child is! ToStringTransformer);
    if (_packageUris.isNotEmpty) {
      component.visitChildren(ToStringVisitor(_packageUris));
    }
    _child?.transform(component);
  }
}
