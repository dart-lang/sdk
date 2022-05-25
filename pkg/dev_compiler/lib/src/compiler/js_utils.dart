// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:js_shared/synced/embedded_names.dart'
    show RtiUniverseFieldNames;

import '../js_ast/js_ast.dart';

/// Simplify `(args) => (() => { ... })()` to `(args) => { ... }`.
// TODO(jmesserly): find a better home for this function
Fun simplifyPassThroughArrowFunCallBody(Fun fn) {
  if (fn.body.statements.length == 1) {
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

class MutationVisitor extends BaseVisitorVoid {
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

/// Recursively clears all source information from all visited nodes.
class SourceInformationClearer extends BaseVisitorVoid {
  @override
  void visitNode(Node node) {
    node.visitChildren(this);
    node.sourceInformation = null;
  }
}

/// Returns an expression that creates the initial Rti Universe.
///
/// This needs to be kept in sync with `_Universe.create` in `dart:_rti`.
Expression createRtiUniverse() {
  Property initField(String name, String value) =>
      Property(js.string(name), js(value));

  var universeFields = [
    initField(RtiUniverseFieldNames.evalCache, 'new Map()'),
    initField(RtiUniverseFieldNames.typeRules, '{}'),
    initField(RtiUniverseFieldNames.erasedTypes, '{}'),
    initField(RtiUniverseFieldNames.typeParameterVariances, '{}'),
    initField(RtiUniverseFieldNames.sharedEmptyArray, '[]'),
  ];

  return ObjectInitializer(universeFields);
}
