// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common.dart';
import '../compiler.dart';
import '../elements/entities.dart';
import '../kernel/element_map.dart';
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
  final MemberEntity analyzedMember;
  final ir.Node analyzedNode;
  final TypeSystem<ir.Node> types;
  LocalsHandler locals;
  final InferrerEngine<ir.Node> inferrer;
  SideEffects sideEffects = new SideEffects.empty();
  int loopLevel = 0;
  bool get inLoop => loopLevel > 0;
  TypeInformation returnType;

  final Set<Local> capturedVariables = new Set<Local>();

  KernelTypeGraphBuilder.internal(this.analyzedMember, this.inferrer,
      this.compiler, this.locals, this.analyzedNode)
      : this.types = inferrer.types {
    if (locals != null) return;

    FieldInitializationScope<ir.Node> fieldScope =
        analyzedNode is ir.Constructor
            ? new FieldInitializationScope(types)
            : null;
    locals = new LocalsHandler(
        inferrer, types, compiler.options, analyzedNode, fieldScope);
  }

  factory KernelTypeGraphBuilder(
      MemberEntity element,
      Compiler compiler,
      KernelToElementMapForBuilding elementMap,
      InferrerEngine<ir.Node> inferrer,
      ir.TreeNode analyzedNode,
      [LocalsHandler<ir.Node> handler]) {
    return new KernelTypeGraphBuilder.internal(
        element, inferrer, compiler, handler, analyzedNode);
  }

  TypeInformation run() {
    if (analyzedMember.isField) {
      if (analyzedNode == null || analyzedNode is ir.NullLiteral) {
        // Eagerly bailout, because computing the closure data only
        // works for functions and field assignments.
        return types.nullType;
      }
    }

    // Update the locals that are boxed in [locals]. These locals will
    // be handled specially, in that we are computing their LUB at
    // each update, and reading them yields the type that was found in a
    // previous analysis of [outermostElement].
    ClosureRepresentationInfo closureData = compiler
        .backendStrategy.closureDataLookup
        .getClosureInfoForMember(analyzedMember);
    closureData.forEachCapturedVariable((variable, field) {
      locals.setCaptured(variable, field);
    });
    closureData.forEachBoxedVariable((variable, field) {
      locals.setCapturedAndBoxed(variable, field);
    });

    return analyzedNode.accept(this);
  }

  void recordReturnType(TypeInformation type) {
    FunctionEntity analyzedMethod = analyzedMember;
    returnType =
        inferrer.addReturnTypeForMethod(analyzedMethod, returnType, type);
  }

  void initializationIsIndefinite() {
    MemberEntity member = analyzedMember;
    if (member is ConstructorEntity && member.isGenerativeConstructor) {
      locals.fieldScope.isIndefinite = true;
    }
  }

  TypeInformation visit(ir.Node node) {
    return node == null ? null : node.accept(this);
  }

  @override
  TypeInformation visitFunctionNode(ir.FunctionNode node) {
    // TODO(redemption): Handle constructors.
    // TODO(redemption): Handle native methods.
    // TODO(redemption): Set up parameters.
    visit(node.body);
    switch (node.asyncMarker) {
      case ir.AsyncMarker.Sync:
        if (returnType == null) {
          // No return in the body.
          returnType = locals.seenReturnOrThrow
              ? types.nonNullEmpty() // Body always throws.
              : types.nullType;
        } else if (!locals.seenReturnOrThrow) {
          // We haven'TypeInformation seen returns on all branches. So the method may
          // also return null.
          recordReturnType(types.nullType);
        }
        break;

      case ir.AsyncMarker.SyncStar:
        // TODO(asgerf): Maybe make a ContainerTypeMask for these? The type
        //               contained is the method body's return type.
        recordReturnType(types.syncStarIterableType);
        break;

      case ir.AsyncMarker.Async:
        recordReturnType(types.asyncFutureType);
        break;

      case ir.AsyncMarker.AsyncStar:
        recordReturnType(types.asyncStarStreamType);
        break;
      case ir.AsyncMarker.SyncYielding:
        failedAt(
            analyzedMember, "Unexpected async marker: ${node.asyncMarker}");
        break;
    }
    return returnType;
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
    return inferrer.concreteTypes.putIfAbsent(listLiteral, () {
      TypeInformation elementType;
      int length = 0;
      for (ir.Expression element in listLiteral.expressions) {
        TypeInformation type = element.accept(this);
        elementType = elementType == null
            ? types.allocatePhi(null, null, type, isTry: false)
            : types.addPhiInput(null, elementType, type);
        length++;
      }
      elementType = elementType == null
          ? types.nonNullEmpty()
          : types.simplifyPhi(null, null, elementType);
      TypeInformation containerType =
          listLiteral.isConst ? types.constListType : types.growableListType;
      return types.allocateList(
          containerType, listLiteral, analyzedMember, elementType, length);
    });
  }

  @override
  TypeInformation visitReturnStatement(ir.ReturnStatement node) {
    ir.Node expression = node.expression;
    recordReturnType(
        expression == null ? types.nullType : expression.accept(this));
    locals.seenReturnOrThrow = true;
    initializationIsIndefinite();
    return null;
  }
}
