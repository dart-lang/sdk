// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common.dart';
import '../constants/constant_system.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../kernel/element_map.dart';
import '../options.dart';
import '../types/constants.dart';
import '../types/types.dart';
import '../universe/selector.dart';
import '../universe/side_effects.dart';
import '../world.dart';
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
  final CompilerOptions _options;
  final ClosedWorld _closedWorld;
  final ClosureDataLookup<ir.Node> _closureDataLookup;
  final InferrerEngine<ir.Node> _inferrer;
  final TypeSystem<ir.Node> _types;
  final MemberEntity _analyzedMember;
  final ir.Node _analyzedNode;
  final KernelToElementMapForBuilding _elementMap;
  final KernelToLocalsMap _localsMap;
  LocalsHandler _locals;
  final GlobalTypeInferenceElementData<ir.Node> _memberData;
  SideEffects _sideEffects = new SideEffects.empty();

  TypeInformation _returnType;

  KernelTypeGraphBuilder(
      this._options,
      this._closedWorld,
      this._closureDataLookup,
      this._inferrer,
      this._analyzedMember,
      this._analyzedNode,
      this._elementMap,
      this._localsMap,
      [this._locals])
      : this._types = _inferrer.types,
        this._memberData = _inferrer.dataOfMember(_analyzedMember) {
    if (_locals != null) return;

    FieldInitializationScope<ir.Node> fieldScope =
        _analyzedNode is ir.Constructor
            ? new FieldInitializationScope(_types)
            : null;
    _locals = new LocalsHandler(
        _inferrer, _types, _options, _analyzedNode, fieldScope);
  }

  int _loopLevel = 0;

  bool get inLoop => _loopLevel > 0;

  TypeInformation run() {
    if (_analyzedMember.isField) {
      if (_analyzedNode == null || _analyzedNode is ir.NullLiteral) {
        // Eagerly bailout, because computing the closure data only
        // works for functions and field assignments.
        return _types.nullType;
      }
    }

    // Update the locals that are boxed in [locals]. These locals will
    // be handled specially, in that we are computing their LUB at
    // each update, and reading them yields the type that was found in a
    // previous analysis of [outermostElement].
    ClosureRepresentationInfo closureData =
        _closureDataLookup.getClosureInfoForMember(_analyzedMember);
    closureData.forEachCapturedVariable((variable, field) {
      _locals.setCaptured(variable, field);
    });
    closureData.forEachBoxedVariable((variable, field) {
      _locals.setCapturedAndBoxed(variable, field);
    });

    return _analyzedNode.accept(this);
  }

  void recordReturnType(TypeInformation type) {
    FunctionEntity analyzedMethod = _analyzedMember;
    _returnType =
        _inferrer.addReturnTypeForMethod(analyzedMethod, _returnType, type);
  }

  void initializationIsIndefinite() {
    MemberEntity member = _analyzedMember;
    if (member is ConstructorEntity && member.isGenerativeConstructor) {
      _locals.fieldScope.isIndefinite = true;
    }
  }

  TypeInformation visit(ir.Node node) {
    return node == null ? null : node.accept(this);
  }

  void visitList(List<ir.Node> nodes) {
    if (nodes == null) return;
    nodes.forEach(visit);
  }

  @override
  TypeInformation visitFunctionNode(ir.FunctionNode node) {
    // TODO(redemption): Handle constructors.
    // TODO(redemption): Handle native methods.
    visitList(node.positionalParameters);
    visitList(node.namedParameters);
    visit(node.body);
    switch (node.asyncMarker) {
      case ir.AsyncMarker.Sync:
        if (_returnType == null) {
          // No return in the body.
          _returnType = _locals.seenReturnOrThrow
              ? _types.nonNullEmpty() // Body always throws.
              : _types.nullType;
        } else if (!_locals.seenReturnOrThrow) {
          // We haven'TypeInformation seen returns on all branches. So the method may
          // also return null.
          recordReturnType(_types.nullType);
        }
        break;

      case ir.AsyncMarker.SyncStar:
        // TODO(asgerf): Maybe make a ContainerTypeMask for these? The type
        //               contained is the method body's return type.
        recordReturnType(_types.syncStarIterableType);
        break;

      case ir.AsyncMarker.Async:
        recordReturnType(_types.asyncFutureType);
        break;

      case ir.AsyncMarker.AsyncStar:
        recordReturnType(_types.asyncStarStreamType);
        break;
      case ir.AsyncMarker.SyncYielding:
        failedAt(
            _analyzedMember, "Unexpected async marker: ${node.asyncMarker}");
        break;
    }
    return _returnType;
  }

  @override
  TypeInformation defaultExpression(ir.Expression node) {
    // TODO(johnniwinther): Make this throw to assert that all expressions are
    // handled.
    return _types.dynamicType;
  }

  @override
  TypeInformation defaultStatement(ir.Statement node) {
    // TODO(johnniwinther): Make this throw to assert that all statements are
    // handled.
    node.visitChildren(this);
    return null;
  }

  @override
  TypeInformation visitNullLiteral(ir.NullLiteral literal) {
    return _types.nullType;
  }

  @override
  TypeInformation visitBlock(ir.Block block) {
    for (ir.Statement statement in block.statements) {
      statement.accept(this);
      if (_locals.aborts) break;
    }
    return null;
  }

  @override
  TypeInformation visitListLiteral(ir.ListLiteral listLiteral) {
    // We only set the type once. We don't need to re-visit the children
    // when re-analyzing the node.
    return _inferrer.concreteTypes.putIfAbsent(listLiteral, () {
      TypeInformation elementType;
      int length = 0;
      for (ir.Expression element in listLiteral.expressions) {
        TypeInformation type = element.accept(this);
        elementType = elementType == null
            ? _types.allocatePhi(null, null, type, isTry: false)
            : _types.addPhiInput(null, elementType, type);
        length++;
      }
      elementType = elementType == null
          ? _types.nonNullEmpty()
          : _types.simplifyPhi(null, null, elementType);
      TypeInformation containerType =
          listLiteral.isConst ? _types.constListType : _types.growableListType;
      return _types.allocateList(
          containerType, listLiteral, _analyzedMember, elementType, length);
    });
  }

  @override
  TypeInformation visitReturnStatement(ir.ReturnStatement node) {
    ir.Node expression = node.expression;
    recordReturnType(
        expression == null ? _types.nullType : expression.accept(this));
    _locals.seenReturnOrThrow = true;
    initializationIsIndefinite();
    return null;
  }

  @override
  TypeInformation visitIntLiteral(ir.IntLiteral node) {
    ConstantSystem constantSystem = _closedWorld.constantSystem;
    // The JavaScript backend may turn this literal into a double at
    // runtime.
    return _types.getConcreteTypeFor(
        computeTypeMask(_closedWorld, constantSystem.createInt(node.value)));
  }

  @override
  TypeInformation visitDoubleLiteral(ir.DoubleLiteral node) {
    ConstantSystem constantSystem = _closedWorld.constantSystem;
    // The JavaScript backend may turn this literal into an integer at
    // runtime.
    return _types.getConcreteTypeFor(
        computeTypeMask(_closedWorld, constantSystem.createDouble(node.value)));
  }

  @override
  TypeInformation visitVariableDeclaration(ir.VariableDeclaration node) {
    Local local = _localsMap.getLocalVariable(node);
    DartType type = _localsMap.getLocalType(_elementMap, local);
    if (node.initializer == null) {
      _locals.update(local, _types.nullType, node, type);
    } else {
      _locals.update(local, visit(node.initializer), node, type);
    }
    return null;
  }

  @override
  TypeInformation visitVariableGet(ir.VariableGet node) {
    return _locals.use(_localsMap.getLocalVariable(node.variable));
  }

  @override
  TypeInformation visitVariableSet(ir.VariableSet node) {
    Local local = _localsMap.getLocalVariable(node.variable);
    DartType type = _localsMap.getLocalType(_elementMap, local);
    TypeInformation rhsType = visit(node.value);
    _locals.update(local, rhsType, node, type);
    return rhsType;
  }

  ArgumentsTypes analyzeArguments(ir.Arguments arguments) {
    List<TypeInformation> positional = <TypeInformation>[];
    Map<String, TypeInformation> named;
    for (ir.Expression argument in arguments.positional) {
      positional.add(argument.accept(this));
    }
    for (ir.NamedExpression argument in arguments.named) {
      named ??= <String, TypeInformation>{};
      named[argument.name] = argument.value.accept(this);
    }

    /// TODO(johnniwinther): Track `isThisExposed`.
    return new ArgumentsTypes(positional, named);
  }

  @override
  TypeInformation visitMethodInvocation(ir.MethodInvocation node) {
    TypeInformation receiverType = visit(node.receiver);
    Selector selector = _elementMap.getSelector(node);
    TypeMask mask = _memberData.typeOfSend(node);

    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    if (selector.name == '==' || selector.name == '!=') {
      if (_types.isNull(receiverType)) {
        // TODO(johnniwinther): Add null check.
        return _types.boolType;
      } else if (_types.isNull(arguments.positional[0])) {
        // TODO(johnniwinther): Add null check.
        return _types.boolType;
      }
    }
    return handleDynamicInvoke(
        CallType.access, node, selector, mask, receiverType, arguments);
  }

  TypeInformation handleDynamicInvoke(
      CallType callType,
      ir.Node node,
      Selector selector,
      TypeMask mask,
      TypeInformation receiverType,
      ArgumentsTypes arguments) {
    assert(receiverType != null);
    if (_types.selectorNeedsUpdate(receiverType, mask)) {
      mask = receiverType == _types.dynamicType
          ? null
          : _types.newTypedSelector(receiverType, mask);
      _inferrer.updateSelectorInMember(
          _analyzedMember, callType, node, selector, mask);
    }

    // TODO(johnniwinther): Refine receiver on non-captured locals.

    return _inferrer.registerCalledSelector(callType, node, selector, mask,
        receiverType, _analyzedMember, arguments, _sideEffects,
        inLoop: inLoop, isConditional: false);
  }

  @override
  TypeInformation visitLet(ir.Let node) {
    visit(node.variable);
    return visit(node.body);
  }
}
