// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';

/// The behavior common to all of the changes used to construct a transform.
abstract class Change<D> {
  /// Use the [builder] to create a change that is part or all of the fix being
  /// made by the data-driven [fix]. The [data] is the data returned by the
  /// [validate] method.
  void apply(DartFileEditBuilder builder, DataDrivenFix fix, D data);

  /// Return the invocation containing the given [node]. The invocation will be
  /// either an instance creation expression, function invocation, method
  /// invocation, or an extension override.
  AstNode getInvocation(AstNode node) {
    if (node is ArgumentList) {
      return node.parent;
    } else if (node is InstanceCreationExpression ||
        node is InvocationExpression) {
      return node;
    } else if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is ConstructorName) {
        var grandparent = parent.parent;
        if (grandparent is InstanceCreationExpression) {
          return grandparent;
        }
      } else if (parent is MethodInvocation && parent.methodName == node) {
        return parent;
      }
    } else if (node is TypeArgumentList) {
      var parent = node.parent;
      if (parent is InvocationExpression) {
        return parent;
      } else if (parent is ExtensionOverride) {
        return parent;
      }
    }
    return null;
  }

  /// Validate that this change can be applied. Return the data to be passed to
  /// [apply] if the change can be applied, or `null` if it can't be applied.
  D validate(DataDrivenFix fix);
}
