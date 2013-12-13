// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.ir_type_inferrer;

import '../ir/ir_nodes.dart';
import 'inferrer_visitor.dart' show TypeSystem, ArgumentsTypes;
import 'simple_types_inferrer.dart' show InferrerEngine;
import '../elements/elements.dart' show
    Elements, Element, FunctionElement, FunctionSignature;
import '../dart2jslib.dart' show Compiler, Constant, ConstantSystem;
import 'type_graph_inferrer.dart' show TypeInformation;
import '../universe/universe.dart' show Selector, SideEffects;


class IrTypeInferrerVisitor extends IrNodesVisitor {
  final Compiler compiler;
  final Element analyzedElement;
  final Element outermostElement;
  final InferrerEngine<TypeInformation, TypeSystem<TypeInformation>> inferrer;
  final TypeSystem<TypeInformation> types;

  IrTypeInferrerVisitor(this.compiler,
                        Element analyzedElement,
                        InferrerEngine<TypeInformation,
                        TypeSystem<TypeInformation>> inferrer)
    : this.analyzedElement = analyzedElement,
      outermostElement = _outermostElement(analyzedElement),
      this.inferrer = inferrer,
      types = inferrer.types;

  final SideEffects sideEffects = new SideEffects.empty();
  bool inLoop = false;

  static Element _outermostElement(Element analyzedElememnt) {
    Element outermostElement =
        analyzedElememnt.getOutermostEnclosingMemberOrTopLevel().implementation;
    assert(outermostElement != null);
    return outermostElement;
  }

  final Map<IrNode, TypeInformation> analyzed = <IrNode, TypeInformation>{};

  TypeInformation returnType;

  TypeInformation run() {
    // TODO(lry): handle fields.
    assert(!analyzedElement.isField());

    FunctionElement function = analyzedElement;
    FunctionSignature signature = function.computeSignature(compiler);
    IrFunction node = compiler.irBuilder.getIr(function);

    // TODO(lry): handle parameters.
    assert(function.computeSignature(compiler).parameterCount == 0);
    // TODO(lry): handle native.
    assert(!function.isNative());
    // TODO(lry): handle constructors.
    assert(!analyzedElement.isGenerativeConstructor());
    // TODO(lry): handle synthethics.
    assert(!analyzedElement.isSynthesized);

    visitAll(node.statements);
    compiler.world.registerSideEffects(analyzedElement, sideEffects);
    return returnType;
  }

  TypeInformation typeOfConstant(Constant constant) {
    return inferrer.types.getConcreteTypeFor(constant.computeMask(compiler));
  }

  TypeInformation handleStaticSend(IrNode node,
                                   Selector selector,
                                   Element element,
                                   ArgumentsTypes arguments) {
    return inferrer.registerCalledElement(
        node, selector, outermostElement, element, arguments,
        sideEffects, inLoop);
  }

  ArgumentsTypes<TypeInformation> analyzeArguments(
      Selector selector, List<IrNode> arguments) {
    // TODO(lry): support named arguments, necessary information should be
    // in [selector].
    assert(selector.namedArgumentCount == 0);
    List<TypeInformation> positional =
        arguments.map((e) => analyzed[e]).toList(growable: false);
    return new ArgumentsTypes<TypeInformation>(positional, null);
  }

  void visitIrConstant(IrConstant node) {
    analyzed[node] = typeOfConstant(node.value);
  }

  void visitIrReturn(IrReturn node) {
    TypeInformation type = analyzed[node.value];
    returnType = inferrer.addReturnTypeFor(analyzedElement, returnType, type);
  }

  void visitIrInvokeStatic(IrInvokeStatic node) {
    FunctionElement element = node.target;
    Selector selector = node.selector;
    // TODO(lry): handle foreign functions.
    assert(!element.isForeign(compiler));
    // In erroneous code the number of arguments in the selector might not
    // match the function element.
    if (!selector.applies(element, compiler)) {
      analyzed[node] = types.dynamicType;
    } else {
      ArgumentsTypes arguments = analyzeArguments(selector, node.arguments);
      analyzed[node] = handleStaticSend(node, selector, element, arguments);
    }
  }

  void visitIrNode(IrNode node) {
    compiler.internalError('Unexpected IrNode $node');
  }
}
