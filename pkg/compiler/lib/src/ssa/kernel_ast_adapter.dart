// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../constants/values.dart';
import '../diagnostics/invariant.dart';
import '../elements/elements.dart';
import '../js_backend/js_backend.dart';
import '../tree/tree.dart' as ast;

/// A helper class that abstracts all accesses of the AST from Kernel nodes.
///
/// The goal is to remove all need for the AST from the Kernel SSA builder.
class KernelAstAdapter {
  final JavaScriptBackend backend;
  final ResolvedAst resolvedAst;
  final Map<ir.Node, ast.Node> nodeToAst;

  KernelAstAdapter(this.backend, this.resolvedAst, this.nodeToAst);

  ConstantValue getConstantFor(ir.Node node) {
    ast.Node astNode = nodeToAst[node];
    ConstantValue constantValue = backend.constants
        .getConstantValueForNode(astNode, resolvedAst.elements);
    assert(invariant(astNode, constantValue != null,
        message: 'No constant computed for $node'));
    return constantValue;
  }
}
