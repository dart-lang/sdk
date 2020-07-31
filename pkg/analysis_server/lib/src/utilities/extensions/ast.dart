// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

extension AstNodeExtensions on AstNode {
  /// Return `true` if this node has an `override` annotation.
  bool get hasOverride {
    var node = this;
    if (node is AnnotatedNode) {
      for (var annotation in node.metadata) {
        if (annotation.name.name == 'override' &&
            annotation.arguments == null) {
          return true;
        }
      }
    }
    return false;
  }

  bool get inAsyncMethodOrFunction {
    var body = thisOrAncestorOfType<FunctionBody>();
    return body != null && body.isAsynchronous && body.star == null;
  }

  bool get inAsyncStarOrSyncStarMethodOrFunction {
    var body = thisOrAncestorOfType<FunctionBody>();
    return body != null && body.keyword != null && body.star != null;
  }

  bool get inCatchClause => thisOrAncestorOfType<CatchClause>() != null;

  bool get inClassMemberBody {
    var node = this;
    while (true) {
      var body = node.thisOrAncestorOfType<FunctionBody>();
      if (body == null) {
        return false;
      }
      var parent = body.parent;
      if (parent is ConstructorDeclaration || parent is MethodDeclaration) {
        return true;
      }
      node = parent;
    }
  }

  bool get inDoLoop => thisOrAncestorOfType<DoStatement>() != null;

  bool get inForLoop =>
      thisOrAncestorMatching((p) => p is ForStatement) != null;

  bool get inLoop => inDoLoop || inForLoop || inWhileLoop;

  bool get inSwitch => thisOrAncestorOfType<SwitchStatement>() != null;

  bool get inWhileLoop => thisOrAncestorOfType<WhileStatement>() != null;
}

extension ExpressionExtensions on Expression {
  /// Return `true` if this expression is an invocation of the method `cast`
  /// from either Iterable`, `List`, `Map`, or `Set`.
  bool get isCastMethodInvocation {
    if (this is MethodInvocation) {
      var element = (this as MethodInvocation).methodName.staticElement;
      return element is MethodElement && element.isCastMethod;
    }
    return false;
  }

  /// Return `true` if this expression is an invocation of the method `toList`
  /// from either `Iterable` or `List`.
  bool get isToListMethodInvocation {
    if (this is MethodInvocation) {
      var element = (this as MethodInvocation).methodName.staticElement;
      return element is MethodElement && element.isToListMethod;
    }
    return false;
  }
}

extension FunctionBodyExtensions on FunctionBody {
  bool get isEmpty =>
      this is EmptyFunctionBody ||
      (this is BlockFunctionBody && beginToken.isSynthetic);
}
