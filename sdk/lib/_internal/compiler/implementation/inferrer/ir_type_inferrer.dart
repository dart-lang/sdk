// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.ir_type_inferrer;

import '../ir/ir_nodes.dart';
import 'inferrer_visitor.dart' show TypeSystem;
import 'simple_types_inferrer.dart' show InferrerEngine;
import '../elements/elements.dart' show
    Element, FunctionElement, FunctionSignature;
import '../dart2jslib.dart' show Compiler, Constant, ConstantSystem;
import 'type_graph_inferrer.dart' show TypeInformation;

class IrTypeInferrerVisitor extends IrNodesVisitor {
  final Compiler compiler;
  final Element analyzedElement;
  final TypeSystem<TypeInformation> types;
  final InferrerEngine<TypeInformation, TypeSystem<TypeInformation>> inferrer;

  IrTypeInferrerVisitor(this.compiler,
                        this.analyzedElement,
                        InferrerEngine<TypeInformation,
                        TypeSystem<TypeInformation>> inferrer)
    : inferrer = inferrer,
      types = inferrer.types;

  final Map<IrNode, TypeInformation> analyzed = <IrNode, TypeInformation>{};

  TypeInformation returnType;

  TypeInformation run() {
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
    return returnType;
  }

  TypeInformation typeOfConstant(Constant constant) {
    return inferrer.types.getConcreteTypeFor(constant.computeMask(compiler));
  }

  void visitIrConstant(IrConstant node) {
    analyzed[node] = typeOfConstant(node.value);
  }

  void visitIrReturn(IrReturn node) {
    TypeInformation type = analyzed[node.value];
    returnType = inferrer.addReturnTypeFor(analyzedElement, returnType, type);
  }

  void visitNode(IrNode node) {
    compiler.internalError('Unexpected IrNode $node');
  }
}
