// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ir_type_inferrer;

import '../ir/ir_nodes.dart';
import 'inferrer_visitor.dart' show
    TypeSystem;
import 'simple_types_inferrer.dart' show
    InferrerEngine;
import '../elements/elements.dart' show
    Element, FunctionElement, FunctionSignature;
import '../dart2jslib.dart' show
    Compiler, Constant, ConstantSystem;

class IrTypeInferrerVisitor<T> extends IrNodesVisitor<T> {
  final Compiler compiler;
  final Element analyzedElement;
  final TypeSystem<T> types;
  final InferrerEngine<T, TypeSystem<T>> inferrer;

  IrTypeInferrerVisitor(this.compiler, this.analyzedElement,
                        InferrerEngine<T, TypeSystem<T>> inferrer)
    : inferrer = inferrer,
      types = inferrer.types;

  final Map<IrNode, T> analyzed = new Map<IrNode, T>();

  T recordAnalyzed(IrNode node, T type) => analyzed[node] = type;

  T run() {
    if (analyzedElement.isField()) {
      // TODO(lry): handle fields.
      throw "Type infer from IR for field $analyzedElement";
    }
    FunctionElement function = analyzedElement;
    FunctionSignature signature = function.computeSignature(compiler);
    IrFunction node = compiler.irBuilder.getIr(function);
    // TODO(lry): handle parameters.

    if (function.isNative()) {
      // TODO(lry): handle native.
      throw "Type infer from IR for native $analyzedElement";
    }

    if (analyzedElement.isGenerativeConstructor()) {
      // TODO(lry): handle constructors.
      throw "Type infer from IR for constructor $analyzedElement";
    }

    if (analyzedElement.isSynthesized) {
      // TODO(lry): handle synthethics.
      throw "Type infer from IR for synthetic $analyzedElement";
    }

    visitAll(node.statements);
  }

  T typeOfConstant(Constant constant) {
    if (constant.isBool()) return types.boolType;
    if (constant.isNum()) {
      ConstantSystem constantSystem = compiler.backend.constantSystem;
      // The JavaScript backend may turn this literal into a double at runtime.
      if (constantSystem.isDouble(constant)) return types.doubleType;
      return types.intType;
    }
    if (constant.isString()) return types.stringType;
    if (constant.isNull()) return types.nullType;
    compiler.internalError("Unexpected constant: $constant");
  }

  T visitIrConstant(IrConstant node) {
    return recordAnalyzed(node, typeOfConstant(node.value));
  }

  T visitIrReturn(IrReturn node) {
    inferrer.addReturnTypeFor(analyzedElement, null, analyzed[node.value]);
  }

  T visitNode(IrNode node) {
    compiler.internalError('Unexpected IrNode $node');
  }
}
