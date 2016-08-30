// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../constants/values.dart';
import '../diagnostics/invariant.dart';
import '../elements/elements.dart';
import '../js_backend/js_backend.dart';
import '../tree/tree.dart' as ast;
import '../types/masks.dart';
import '../universe/side_effects.dart';

import 'types.dart';

/// A helper class that abstracts all accesses of the AST from Kernel nodes.
///
/// The goal is to remove all need for the AST from the Kernel SSA builder.
class KernelAstAdapter {
  final JavaScriptBackend _backend;
  final ResolvedAst _resolvedAst;
  final Map<ir.Node, ast.Node> _nodeToAst;
  final Map<ir.Node, Element> _nodeToElement;

  KernelAstAdapter(this._backend, this._resolvedAst, this._nodeToAst,
      this._nodeToElement, Map<FunctionElement, ir.Member> functions) {
    for (FunctionElement functionElement in functions.keys) {
      _nodeToElement[functions[functionElement]] = functionElement;
    }
  }

  ConstantValue getConstantForSymbol(ir.SymbolLiteral node) {
    ast.Node astNode = _nodeToAst[node];
    ConstantValue constantValue = _backend.constants
        .getConstantValueForNode(astNode, _resolvedAst.elements);
    assert(invariant(astNode, constantValue != null,
        message: 'No constant computed for $node'));
    return constantValue;
  }

  Element getElement(ir.Node node) {
    Element result = _nodeToElement[node];
    assert(result != null);
    return result;
  }

  bool getCanThrow(ir.Procedure procedure) {
    FunctionElement function = getElement(procedure);
    return !_backend.compiler.world.getCannotThrow(function);
  }

  TypeMask returnTypeOf(ir.Procedure node) {
    return TypeMaskFactory.inferredReturnTypeForElement(
        getElement(node), _backend.compiler);
  }

  SideEffects getSideEffects(ir.Node node) {
    return _backend.compiler.world.getSideEffectsOfElement(getElement(node));
  }
}
