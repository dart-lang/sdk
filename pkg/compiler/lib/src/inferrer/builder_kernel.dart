// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../compiler.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../kernel/kernel.dart';
import '../ssa/kernel_ast_adapter.dart';
import '../tree/tree.dart' as ast;
import '../universe/side_effects.dart' show SideEffects;
import 'inferrer_engine.dart';
import 'locals_handler.dart';
import 'type_graph_nodes.dart';
import 'type_system.dart';

/// [KernelTypeGraphBuilder] constructs a type-inference graph for a particular
/// element.
///
/// Calling [run] will start the work of visiting the body of the code to
/// construct a set of inference-nodes that abstractly represent what the code
/// is doing.
class KernelTypeGraphBuilder extends ir.Visitor<TypeInformation> {
  final Compiler compiler;
  final AstElement originalElement;
  // TODO(efortuna): Remove this.
  final Element outermostElement;
  final ir.Node analyzedNode;
  final ResolvedAst resolvedAst;
  final TypeSystem types;
  LocalsHandler locals;
  final InferrerEngine inferrer;
  SideEffects sideEffects = new SideEffects.empty();
  int loopLevel = 0;
  bool get inLoop => loopLevel > 0;

  final Set<Entity> capturedVariables = new Set<Entity>();

  final KernelAstAdapter astAdapter;

  KernelTypeGraphBuilder.internal(
      this.originalElement,
      this.resolvedAst,
      this.outermostElement,
      this.inferrer,
      this.compiler,
      this.locals,
      this.astAdapter,
      this.analyzedNode)
      : this.types = inferrer.types {
    if (locals != null) return;

    ast.Node node;
    if (resolvedAst.kind == ResolvedAstKind.PARSED) {
      node = resolvedAst.node;
    }
    FieldInitializationScope fieldScope = (analyzedNode is ir.Constructor)
        ? new FieldInitializationScope(types)
        : null;
    locals =
        new LocalsHandler(inferrer, types, compiler.options, node, fieldScope);
  }

  factory KernelTypeGraphBuilder(Element element, ResolvedAst resolvedAst,
      Compiler compiler, InferrerEngine inferrer,
      [LocalsHandler handler]) {
    var adapter = _createKernelAdapter(compiler, resolvedAst);
    var node = adapter.getMemberNode(element);
    return new KernelTypeGraphBuilder.internal(
        element,
        resolvedAst,
        element.outermostEnclosingMemberOrTopLevel.implementation,
        inferrer,
        compiler,
        handler,
        adapter,
        node);
  }

  static KernelAstAdapter _createKernelAdapter(
      Compiler compiler, ResolvedAst resolvedAst) {
    Kernel kernel = compiler.backend.kernelTask.kernel;
    return new KernelAstAdapter(kernel, compiler.backend, resolvedAst,
        kernel.nodeToAst, kernel.nodeToElement);
  }

  TypeInformation run() {
    ir.Expression initializer;
    if (analyzedNode is ir.Field) {
      ir.Field field = analyzedNode;
      initializer = field.initializer;
      if (initializer == null || initializer is ir.NullLiteral) {
        // Eagerly bailout, because computing the closure data only
        // works for functions and field assignments.
        return types.nullType;
      }
    }

    // Update the locals that are boxed in [locals]. These locals will
    // be handled specially, in that we are computing their LUB at
    // each update, and reading them yields the type that was found in a
    // previous analysis of [outermostElement].
    ClosureRepresentationInfo closureData = compiler.closureDataLookup
        .getClosureRepresentationInfo(resolvedAst.element);
    closureData.forEachCapturedVariable((variable, field) {
      locals.setCaptured(variable, field);
    });
    closureData.forEachBoxedVariable((variable, field) {
      locals.setCapturedAndBoxed(variable, field);
    });

    if (analyzedNode is ir.Field) {
      return initializer.accept(this);
    }
    return _processFunctionNode(analyzedNode);
  }

  TypeInformation _processFunctionNode(ir.FunctionNode funcNode) {
    // TODO(efortuna): Implement.
    return types.dynamicType;
  }

  @override
  TypeInformation defaultExpression(ir.Expression expression) {
    // TODO(efortuna): Remove when more is implemented.
    return types.dynamicType;
  }

  @override
  TypeInformation visitNullLiteral(ir.NullLiteral literal) {
    return types.nullType;
  }

  @override
  TypeInformation visitBlock(ir.Block block) {
    for (ir.Statement statement in block.statements) {
      statement.accept(this);
      if (locals.aborts) break;
    }
    return null;
  }

  @override
  TypeInformation visitListLiteral(ir.ListLiteral listLiteral) {
    // We only set the type once. We don't need to re-visit the children
    // when re-analyzing the node.
    return inferrer.concreteKernelTypes.putIfAbsent(listLiteral, () {
      TypeInformation elementType;
      int length = 0;
      for (ir.Expression element in listLiteral.expressions) {
        TypeInformation type = element.accept(this);
        elementType = elementType == null
            ? types.allocatePhi(null, null, type)
            : types.addPhiInput(null, elementType, type);
        length++;
      }
      elementType = elementType == null
          ? types.nonNullEmpty()
          : types.simplifyPhi(null, null, elementType);
      TypeInformation containerType =
          listLiteral.isConst ? types.constListType : types.growableListType;
      // TODO(efortuna): Change signature of allocateList and the rest of
      // type_system to deal with Kernel elements.
      return types.allocateList(containerType, astAdapter.getNode(listLiteral),
          outermostElement, elementType, length);
    });
  }
}
