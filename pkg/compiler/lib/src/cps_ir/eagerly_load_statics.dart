// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cps_ir.eagerly_load_statics;

import 'cps_ir_nodes.dart';
import 'optimizers.dart' show Pass;
import '../elements/elements.dart';
import 'cps_fragment.dart';

/// Replaces [GetLazyStatic] with [GetStatic] when the static field is known
/// to have been initialized.
///
/// Apart from [GetStatic] generating better code, this improves the side-effect
/// analysis in the [GVN] pass, since [GetStatic] has no effects.
class EagerlyLoadStatics extends TrampolineRecursiveVisitor implements Pass {
  String get passName => 'Eagerly load statics';

  Map<FieldElement, Primitive> initializerFor = <FieldElement, Primitive>{};

  final Map<Continuation, Map<FieldElement, Primitive>> initializersAt =
      <Continuation, Map<FieldElement, Primitive>>{};

  static Map<FieldElement, Primitive> cloneFieldMap(
      Map<FieldElement, Primitive> map) {
    return new Map<FieldElement, Primitive>.from(map);
  }

  void rewrite(FunctionDefinition node) {
    visit(node.body);
  }

  Expression traverseLetPrim(LetPrim node) {
    Expression next = node.body;
    visit(node.primitive);
    return next;
  }

  Expression traverseLetCont(LetCont node) {
    for (Continuation cont in node.continuations) {
      initializersAt[cont] = cloneFieldMap(initializerFor);
      push(cont);
    }
    return node.body;
  }

  Expression traverseLetHandler(LetHandler node) {
    initializersAt[node.handler] = cloneFieldMap(initializerFor);
    push(node.handler);
    return node.body;
  }

  Expression traverseContinuation(Continuation cont) {
    initializerFor = initializersAt[cont];
    return cont.body;
  }

  void visitGetLazyStatic(GetLazyStatic node) {
    Primitive initializer = initializerFor[node.element];
    if (initializer is GetLazyStatic && initializer.isFinal) {
      // No reason to create a GetStatic when the field is final.
      node.replaceWithFragment(new CpsFragment(), initializer);
    } else if (initializer != null) {
      GetStatic newNode = new GetStatic.witnessed(node.element, initializer,
          sourceInformation: node.sourceInformation)..type = node.type;
      node.replaceWith(newNode);
    } else {
      initializerFor[node.element] = node;
    }
  }

  void visitSetStatic(SetStatic node) {
    initializerFor.putIfAbsent(node.element, () => node);
  }
}
