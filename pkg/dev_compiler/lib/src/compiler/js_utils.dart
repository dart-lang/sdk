// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../js_ast/js_ast.dart';

/// Simplify `(args) => (() => { ... })()` to `(args) => { ... }`.
// TODO(jmesserly): find a better home for this function
Fun simplifyPassThroughArrowFunCallBody(Fun fn) {
  if (fn.body is Block && fn.body.statements.length == 1) {
    var stat = fn.body.statements.single;
    if (stat is Return && stat.value is Call) {
      Call call = stat.value;
      var innerFun = call.target;
      if (innerFun is ArrowFun &&
          call.arguments.isEmpty &&
          innerFun.params.isEmpty) {
        var body = innerFun.body;
        if (body is Block) {
          return new Fun(fn.params, body,
              typeParams: fn.typeParams, returnType: fn.returnType);
        }
      }
    }
  }
  return fn;
}

/// Transform the function so the last parameter is always returned.
///
/// This is useful for indexed set methods, which otherwise would not have
/// the right return value in JS.
Block alwaysReturnLastParameter(Block body, Parameter lastParam) {
  Statement blockBody = body;
  if (Return.foundIn(body)) {
    // If a return is inside body, transform `(params) { body }` to
    // `(params) { (() => { body })(); return value; }`.
    // TODO(jmesserly): we could instead generate the return differently,
    // and avoid the immediately invoked function.
    blockBody = new Call(new ArrowFun([], body), []).toStatement();
  }
  return new Block([blockBody, new Return(lastParam)]);
}

Set<Identifier> findMutatedVariables(Node scope) {
  var v = new MutationVisitor();
  scope.accept(v);
  return v.mutated;
}

class MutationVisitor extends BaseVisitor {
  final mutated = new Set<Identifier>();
  @override
  visitAssignment(node) {
    var id = node.leftHandSide;
    if (id is Identifier) mutated.add(id);
    super.visitAssignment(node);
  }
}
