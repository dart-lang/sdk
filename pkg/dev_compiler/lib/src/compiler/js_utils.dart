// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import '../js_ast/js_ast.dart';

/// Simplify `(args) => (() => { ... })()` to `(args) => { ... }`.
// TODO(jmesserly): find a better home for this function
Fun simplifyPassThroughArrowFunCallBody(Fun fn) {
  if (fn.body is Block && fn.body.statements.length == 1) {
    var stat = fn.body.statements.single;
    if (stat is Return && stat.value is Call) {
      var call = stat.value as Call;
      var innerFun = call.target;
      if (innerFun is ArrowFun &&
          call.arguments.isEmpty &&
          innerFun.params.isEmpty) {
        var body = innerFun.body;
        if (body is Block) {
          return Fun(fn.params, body);
        }
      }
    }
  }
  return fn;
}

Set<String> findMutatedVariables(Node scope) {
  var v = MutationVisitor();
  scope.accept(v);
  return v.mutated;
}

class MutationVisitor extends BaseVisitor<void> {
  /// Using Identifier names instead of a more precise key may result in
  /// mutations being imprecisely reported when variables shadow each other.
  final mutated = <String>{};
  @override
  void visitAssignment(node) {
    var id = node.leftHandSide;
    if (id is Identifier) mutated.add(id.name);
    super.visitAssignment(node);
  }
}
