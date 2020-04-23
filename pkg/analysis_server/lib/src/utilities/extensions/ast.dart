// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

/// Extensions for [AstNode]s
extension AstNodeExtensions on AstNode {
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

/// Extensions for [FunctionBody]s
extension FunctionBodyExtensions on FunctionBody {
  bool get isEmpty =>
      this is EmptyFunctionBody ||
      (this is BlockFunctionBody && beginToken.isSynthetic);
}
