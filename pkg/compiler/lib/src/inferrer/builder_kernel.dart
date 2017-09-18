// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common.dart';
import '../common/names.dart';
import '../constants/constant_system.dart';
import '../elements/entities.dart';
import '../elements/jumps.dart';
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
  final GlobalTypeInferenceElementData<ir.Node> _memberData;

  LocalsHandler _locals;
  SideEffects _sideEffects = new SideEffects.empty();
  final Map<JumpTarget, List<LocalsHandler>> _breaksFor =
      <JumpTarget, List<LocalsHandler>>{};
  final Map<JumpTarget, List<LocalsHandler>> _continuesFor =
      <JumpTarget, List<LocalsHandler>>{};
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

  void handleParameter(ir.VariableDeclaration node, {bool isOptional}) {
    Local local = _localsMap.getLocalVariable(node);
    DartType type = _localsMap.getLocalType(_elementMap, local);
    _locals.update(local, _inferrer.typeOfParameter(local), node, type);
    if (isOptional) {
      TypeInformation type = visit(node.initializer);
      _inferrer.setDefaultTypeOfParameter(local, type,
          isInstanceMember: _analyzedMember.isInstanceMember);
    }
  }

  @override
  TypeInformation visitFunctionNode(ir.FunctionNode node) {
    // TODO(redemption): Handle native methods.

    int position = 0;
    for (ir.VariableDeclaration parameter in node.positionalParameters) {
      handleParameter(parameter,
          isOptional: position >= node.requiredParameterCount);
      position++;
    }
    for (ir.VariableDeclaration parameter in node.namedParameters) {
      handleParameter(parameter, isOptional: true);
    }
    visit(node.body);
    MemberEntity analyzedMember = _analyzedMember;
    if (analyzedMember is ConstructorEntity &&
        analyzedMember.isGenerativeConstructor) {
      // TODO(redemption): Handle initializers.
      ClassEntity cls = analyzedMember.enclosingClass;
      if (cls.isAbstract) {
        if (_closedWorld.isInstantiated(cls)) {
          _returnType = _types.nonNullSubclass(cls);
        } else {
          // TODO(johnniwinther): Avoid analyzing [_analyzedMember] in this
          // case; it's never called.
          _returnType = _types.nonNullEmpty();
        }
      } else {
        _returnType = _types.nonNullExact(cls);
      }
    } else {
      switch (node.asyncMarker) {
        case ir.AsyncMarker.Sync:
          if (_returnType == null) {
            // No return in the body.
            _returnType = _locals.seenReturnOrThrow
                ? _types.nonNullEmpty() // Body always throws.
                : _types.nullType;
          } else if (!_locals.seenReturnOrThrow) {
            // We haven'TypeInformation seen returns on all branches. So the
            // method may also return null.
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
    assert(
        node.parent is! ir.FunctionNode, "Unexpected parameter declaration.");
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

  @override
  TypeInformation visitForInStatement(ir.ForInStatement node) {
    TypeInformation expressionType = visit(node.iterable);
    Selector iteratorSelector = Selectors.iterator;
    TypeMask iteratorMask = _memberData.typeOfIterator(node);
    Selector currentSelector = Selectors.current;
    TypeMask currentMask = _memberData.typeOfIteratorCurrent(node);
    Selector moveNextSelector = Selectors.moveNext;
    TypeMask moveNextMask = _memberData.typeOfIteratorMoveNext(node);

    TypeInformation iteratorType = handleDynamicInvoke(
        CallType.forIn,
        node,
        iteratorSelector,
        iteratorMask,
        expressionType,
        new ArgumentsTypes.empty());

    handleDynamicInvoke(CallType.forIn, node, moveNextSelector, moveNextMask,
        iteratorType, new ArgumentsTypes.empty());
    TypeInformation currentType = handleDynamicInvoke(CallType.forIn, node,
        currentSelector, currentMask, iteratorType, new ArgumentsTypes.empty());

    Local variable = _localsMap.getLocalVariable(node.variable);
    DartType variableType = _localsMap.getLocalType(_elementMap, variable);
    _locals.update(variable, currentType, node.variable, variableType);

    JumpTarget target = _localsMap.getJumpTargetForForIn(node);
    return handleLoop(node, target, () {
      visit(node.body);
    });
  }

  void _setupBreaksAndContinues(JumpTarget target) {
    if (target == null) return;
    if (target.isContinueTarget) _continuesFor[target] = <LocalsHandler>[];
    if (target.isBreakTarget) _breaksFor[target] = <LocalsHandler>[];
  }

  void _clearBreaksAndContinues(JumpTarget element) {
    _continuesFor.remove(element);
    _breaksFor.remove(element);
  }

  List<LocalsHandler> _getBreaks(JumpTarget target) {
    List<LocalsHandler> list = <LocalsHandler>[_locals];
    if (target == null) return list;
    if (!target.isBreakTarget) return list;
    return list..addAll(_breaksFor[target]);
  }

  List<LocalsHandler> _getLoopBackEdges(JumpTarget target) {
    List<LocalsHandler> list = <LocalsHandler>[_locals];
    if (target == null) return list;
    if (!target.isContinueTarget) return list;
    return list..addAll(_continuesFor[target]);
  }

  TypeInformation handleLoop(ir.Node node, JumpTarget target, void logic()) {
    _loopLevel++;
    bool changed = false;
    LocalsHandler saved = _locals;
    saved.startLoop(node);
    do {
      // Setup (and clear in case of multiple iterations of the loop)
      // the lists of breaks and continues seen in the loop.
      _setupBreaksAndContinues(target);
      _locals = new LocalsHandler.from(saved, node);
      logic();
      changed = saved.mergeAll(_getLoopBackEdges(target));
    } while (changed);
    _loopLevel--;
    saved.endLoop(node);
    bool keepOwnLocals = node is! ir.DoStatement;
    saved.mergeAfterBreaks(_getBreaks(target), keepOwnLocals: keepOwnLocals);
    _locals = saved;
    _clearBreaksAndContinues(target);
    return null;
  }

  @override
  TypeInformation visitConstructorInvocation(ir.ConstructorInvocation node) {
    ConstructorEntity constructor = _elementMap.getConstructor(node.target);
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    // TODO(redemption): Handle initializers.
    // TODO(redemption): Handle foreign constructors.
    Selector selector = _elementMap.getSelector(node);
    TypeMask mask = _memberData.typeOfSend(node);
    return handleConstructorInvoke(
        node, selector, mask, constructor, arguments);
  }

  TypeInformation handleConstructorInvoke(ir.Node node, Selector selector,
      TypeMask mask, ConstructorEntity constructor, ArgumentsTypes arguments) {
    TypeInformation returnType =
        handleStaticInvoke(node, selector, mask, constructor, arguments);
    // TODO(redemption): Special-case `List` constructors.
    return returnType;
  }

  TypeInformation handleStaticInvoke(ir.Node node, Selector selector,
      TypeMask mask, MemberEntity element, ArgumentsTypes arguments) {
    return _inferrer.registerCalledMember(node, selector, mask, _analyzedMember,
        element, arguments, _sideEffects, inLoop);
  }

  @override
  TypeInformation visitStaticInvocation(ir.StaticInvocation node) {
    MemberEntity member = _elementMap.getMember(node.target);
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    // TODO(redemption): Handle foreign functions.
    Selector selector = _elementMap.getSelector(node);
    TypeMask mask = _memberData.typeOfSend(node);
    if (member.isConstructor) {
      return handleConstructorInvoke(node, selector, mask, member, arguments);
    } else if (member.isFunction) {
      return handleStaticInvoke(node, selector, mask, member, arguments);
    } else {
      handleStaticInvoke(node, selector, mask, member, arguments);
      return _inferrer.registerCalledClosure(
          node,
          selector,
          mask,
          _inferrer.typeOfMember(member),
          _analyzedMember,
          arguments,
          _sideEffects,
          inLoop);
    }
  }
}
