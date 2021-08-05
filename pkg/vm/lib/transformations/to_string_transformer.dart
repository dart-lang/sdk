// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

/// Transformer/visitor for toString
transformComponent(Component component, List<String> packageUris) {
  component.visitChildren(ToStringVisitor(packageUris.toSet()));
}

/// A [RecursiveVisitor] that replaces [Object.toString] overrides with
/// `super.toString()`.
class ToStringVisitor extends RecursiveVisitor {
  /// The [packageUris] must not be null.
  ToStringVisitor(this._packageUris);

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
      final className = constant.classNode.name;
      final libraryUri =
          constant.classNode.enclosingLibrary.importUri.toString();
      if (className == 'pragma' && libraryUri == 'dart:core') {
        for (var fieldRef in constant.fieldValues.keys) {
          if (fieldRef.asField.name.text == 'name') {
            Constant? name = constant.fieldValues[fieldRef];
            return name is StringConstant &&
                name.value == 'flutter:keep-to-string';
          }
        }
        return false;
      }
    }
    return false;
  }

  @override
  void visitProcedure(Procedure node) {
    if (node.name.text == 'toString' &&
        node.enclosingClass != null &&
        !node.isStatic &&
        !node.isAbstract &&
        !node.enclosingClass!.isEnum &&
        _isInTargetPackage(node) &&
        !_hasKeepAnnotation(node)) {
      node.function.body!.replaceWith(
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
