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
import '../js_backend/backend.dart';
import '../kernel/element_map.dart';
import '../native/behavior.dart';
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
  final bool _inGenerativeConstructor;

  LocalsHandler _locals;
  SideEffects _sideEffects = new SideEffects.empty();
  final Map<JumpTarget, List<LocalsHandler>> _breaksFor =
      <JumpTarget, List<LocalsHandler>>{};
  final Map<JumpTarget, List<LocalsHandler>> _continuesFor =
      <JumpTarget, List<LocalsHandler>>{};
  TypeInformation _returnType;

  /// Whether we currently collect [IsCheck]s.
  bool _accumulateIsChecks = false;
  bool _conditionIsSimple = false;

  /// The [IsCheck]s that show us what types locals currently _are_.
  List<IsCheck> _positiveIsChecks;

  /// The [IsCheck]s that show us what types locals currently are _not_.
  List<IsCheck> _negativeIsChecks;

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
        this._memberData = _inferrer.dataOfMember(_analyzedMember),
        this._inGenerativeConstructor = _analyzedNode is ir.Constructor {
    if (_locals != null) return;

    FieldInitializationScope<ir.Node> fieldScope =
        _inGenerativeConstructor ? new FieldInitializationScope(_types) : null;
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
    if (_inGenerativeConstructor) {
      _locals.fieldScope.isIndefinite = true;
    }
  }

  TypeInformation _thisType;
  TypeInformation get thisType {
    if (_thisType != null) return _thisType;
    ClassEntity cls = _elementMap.getMemberThisType(_analyzedMember)?.element;
    if (_closedWorld.isUsedAsMixin(cls)) {
      return _thisType = _types.nonNullSubtype(cls);
    } else {
      return _thisType = _types.nonNullSubclass(cls);
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
  TypeInformation visitConstructor(ir.Constructor node) {
    handleParameters(node.function);
    node.initializers.forEach(visit);
    visit(node.function.body);

    ClassEntity cls = _analyzedMember.enclosingClass;
    if (!(node.initializers.isNotEmpty &&
        node.initializers.first is ir.RedirectingInitializer)) {
      // Iterate over all instance fields, and give a null type to
      // fields that we haven't initialized for sure.
      _elementMap.elementEnvironment.forEachLocalClassMember(cls,
          (MemberEntity member) {
        if (member.isField && member.isInstanceMember && member.isAssignable) {
          TypeInformation type = _locals.fieldScope.readField(member);
          MemberDefinition definition = _elementMap.getMemberDefinition(member);
          assert(definition.kind == MemberKind.regular);
          ir.Field node = definition.node;
          if (type == null &&
              (node.initializer == null ||
                  node.initializer is ir.NullLiteral)) {
            _inferrer.recordTypeOfField(member, _types.nullType);
          }
        }
      });
    }

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
    return _returnType;
  }

  @override
  visitFieldInitializer(ir.FieldInitializer node) {
    TypeInformation rhsType = visit(node.value);
    FieldEntity field = _elementMap.getField(node.field);
    _locals.updateField(field, rhsType);
    _inferrer.recordTypeOfField(field, rhsType);
  }

  void handleParameters(ir.FunctionNode node) {
    int position = 0;
    for (ir.VariableDeclaration parameter in node.positionalParameters) {
      handleParameter(parameter,
          isOptional: position >= node.requiredParameterCount);
      position++;
    }
    for (ir.VariableDeclaration parameter in node.namedParameters) {
      handleParameter(parameter, isOptional: true);
    }
  }

  @override
  TypeInformation visitFunctionNode(ir.FunctionNode node) {
    // TODO(redemption): Handle native methods.
    handleParameters(node);
    visit(node.body);
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
  TypeInformation visitMapLiteral(ir.MapLiteral node) {
    return _inferrer.concreteTypes.putIfAbsent(node, () {
      List keyTypes = [];
      List valueTypes = [];

      for (ir.MapEntry entry in node.entries) {
        keyTypes.add(visit(entry.key));
        valueTypes.add(visit(entry.value));
      }

      TypeInformation type =
          node.isConst ? _types.constMapType : _types.mapType;
      return _types.allocateMap(
          type, node, _analyzedMember, keyTypes, valueTypes);
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
  TypeInformation visitBoolLiteral(ir.BoolLiteral node) {
    return _types.boolLiteralType(node.value);
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
  TypeInformation visitStringLiteral(ir.StringLiteral node) {
    return _types.stringLiteralType(node.value);
  }

  @override
  TypeInformation visitStringConcatenation(ir.StringConcatenation node) {
    node.visitChildren(this);
    return _types.stringType;
  }

  @override
  TypeInformation visitSymbolLiteral(ir.SymbolLiteral node) {
    return _types
        .nonNullSubtype(_closedWorld.commonElements.symbolImplementationClass);
  }

  @override
  TypeInformation visitTypeLiteral(ir.TypeLiteral node) {
    return _types.typeType;
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
    if (selector.name == '==') {
      if (_types.isNull(receiverType)) {
        // null == o
        _potentiallyAddNullCheck(node, node.arguments.positional.first);
        return _types.boolType;
      } else if (_types.isNull(arguments.positional[0])) {
        // o == null
        _potentiallyAddNullCheck(node, node.receiver);
        return _types.boolType;
      }
    }
    return handleDynamicInvoke(
        CallType.access, node, selector, mask, receiverType, arguments);
  }

  TypeInformation _handleDynamic(
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

  TypeInformation handleDynamicGet(ir.Node node, Selector selector,
      TypeMask mask, TypeInformation receiverType) {
    return _handleDynamic(
        CallType.access, node, selector, mask, receiverType, null);
  }

  TypeInformation handleDynamicSet(ir.Node node, Selector selector,
      TypeMask mask, TypeInformation receiverType, TypeInformation rhsType) {
    ArgumentsTypes arguments = new ArgumentsTypes([rhsType], null);
    return _handleDynamic(
        CallType.access, node, selector, mask, receiverType, arguments);
  }

  TypeInformation handleDynamicInvoke(
      CallType callType,
      ir.Node node,
      Selector selector,
      TypeMask mask,
      TypeInformation receiverType,
      ArgumentsTypes arguments) {
    return _handleDynamic(
        callType, node, selector, mask, receiverType, arguments);
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

  TypeInformation handleForeignInvoke(
      ir.StaticInvocation node,
      FunctionEntity function,
      ArgumentsTypes arguments,
      Selector selector,
      TypeMask mask) {
    String name = function.name;
    handleStaticInvoke(node, selector, mask, function, arguments);
    if (name == JavaScriptBackend.JS) {
      NativeBehavior nativeBehavior =
          _elementMap.getNativeBehaviorForJsCall(node);
      _sideEffects.add(nativeBehavior.sideEffects);
      return _inferrer.typeOfNativeBehavior(nativeBehavior);
    } else if (name == JavaScriptBackend.JS_EMBEDDED_GLOBAL) {
      NativeBehavior nativeBehavior =
          _elementMap.getNativeBehaviorForJsEmbeddedGlobalCall(node);
      _sideEffects.add(nativeBehavior.sideEffects);
      return _inferrer.typeOfNativeBehavior(nativeBehavior);
    } else if (name == JavaScriptBackend.JS_BUILTIN) {
      NativeBehavior nativeBehavior =
          _elementMap.getNativeBehaviorForJsBuiltinCall(node);
      _sideEffects.add(nativeBehavior.sideEffects);
      return _inferrer.typeOfNativeBehavior(nativeBehavior);
    } else if (name == JavaScriptBackend.JS_STRING_CONCAT) {
      return _types.stringType;
    } else {
      _sideEffects.setAllSideEffects();
      return _types.dynamicType;
    }
  }

  @override
  TypeInformation visitStaticInvocation(ir.StaticInvocation node) {
    MemberEntity member = _elementMap.getMember(node.target);
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    Selector selector = _elementMap.getSelector(node);
    TypeMask mask = _memberData.typeOfSend(node);
    if (_closedWorld.commonElements.isForeign(member)) {
      return handleForeignInvoke(node, member, arguments, selector, mask);
    } else if (member.isConstructor) {
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

  @override
  TypeInformation visitPropertyGet(ir.PropertyGet node) {
    TypeInformation receiverType = visit(node.receiver);
    Selector selector = _elementMap.getSelector(node);
    TypeMask mask = _memberData.typeOfSend(node);
    // TODO(redemption): Use `node.interfaceTarget` to narrow the receiver type
    // for --trust-type-annotations/strong-mode.
    return handleDynamicGet(node, selector, mask, receiverType);
  }

  @override
  TypeInformation visitPropertySet(ir.PropertySet node) {
    TypeInformation rhsType = visit(node.value);
    TypeInformation receiverType = visit(node.receiver);
    Selector selector = _elementMap.getSelector(node);
    TypeMask mask = _memberData.typeOfSend(node);
    if (_inGenerativeConstructor && node.receiver is ir.ThisExpression) {
      Iterable<MemberEntity> targets = _closedWorld.locateMembers(
          selector, _types.newTypedSelector(receiverType, mask));
      // We just recognized a field initialization of the form:
      // `this.foo = 42`. If there is only one target, we can update
      // its type.
      if (targets.length == 1) {
        MemberEntity single = targets.first;
        if (single.isField) {
          FieldEntity field = single;
          _locals.updateField(field, rhsType);
        }
      }
    }
    handleDynamicSet(node, selector, mask, receiverType, rhsType);
    return rhsType;
  }

  @override
  TypeInformation visitThisExpression(ir.ThisExpression node) {
    return thisType;
  }

  bool handleCondition(
      ir.Node node, List<IsCheck> positiveTests, List<IsCheck> negativeTests) {
    bool oldConditionIsSimple = _conditionIsSimple;
    bool oldAccumulateIsChecks = _accumulateIsChecks;
    List<IsCheck> oldPositiveIsChecks = _positiveIsChecks;
    List<IsCheck> oldNegativeIsChecks = _negativeIsChecks;
    _accumulateIsChecks = true;
    _conditionIsSimple = true;
    _positiveIsChecks = positiveTests;
    _negativeIsChecks = negativeTests;
    visit(node);
    bool simpleCondition = _conditionIsSimple;
    _accumulateIsChecks = oldAccumulateIsChecks;
    _positiveIsChecks = oldPositiveIsChecks;
    _negativeIsChecks = oldNegativeIsChecks;
    _conditionIsSimple = oldConditionIsSimple;
    return simpleCondition;
  }

  void _potentiallyAddIsCheck(ir.IsExpression node) {
    if (!_accumulateIsChecks) return;
    ir.Expression operand = node.operand;
    if (operand is ir.VariableGet) {
      _positiveIsChecks.add(new IsCheck(
          node,
          _localsMap.getLocalVariable(operand.variable),
          _elementMap.getDartType(node.type)));
    }
  }

  void _potentiallyAddNullCheck(
      ir.MethodInvocation node, ir.Expression receiver) {
    if (!_accumulateIsChecks) return;
    if (receiver is ir.VariableGet) {
      _positiveIsChecks.add(new IsCheck(
          node, _localsMap.getLocalVariable(receiver.variable), null));
    }
  }

  void _updateIsChecks(
      List<IsCheck> positiveTests, List<IsCheck> negativeTests) {
    for (IsCheck check in positiveTests) {
      if (check.type != null) {
        _locals.narrow(check.local, check.type, check.node);
      } else {
        DartType localType = _localsMap.getLocalType(_elementMap, check.local);
        _locals.update(check.local, _types.nullType, check.node, localType);
      }
    }
    for (IsCheck check in negativeTests) {
      if (check.type != null) {
        // TODO(johnniwinther): Use negative type knowledge.
      } else {
        _locals.narrow(
            check.local, _closedWorld.commonElements.objectType, check.node);
      }
    }
  }

  @override
  TypeInformation visitIfStatement(ir.IfStatement node) {
    List<IsCheck> positiveTests = <IsCheck>[];
    List<IsCheck> negativeTests = <IsCheck>[];
    bool simpleCondition =
        handleCondition(node.condition, positiveTests, negativeTests);
    LocalsHandler saved = _locals;
    _locals = new LocalsHandler.from(_locals, node);
    _updateIsChecks(positiveTests, negativeTests);
    visit(node.then);
    LocalsHandler thenLocals = _locals;
    _locals = new LocalsHandler.from(saved, node);
    if (simpleCondition) {
      _updateIsChecks(negativeTests, positiveTests);
    }
    visit(node.otherwise);
    saved.mergeDiamondFlow(thenLocals, _locals);
    _locals = saved;
    return null;
  }

  @override
  TypeInformation visitIsExpression(ir.IsExpression node) {
    _potentiallyAddIsCheck(node);
    visit(node.operand);
    return _types.boolType;
  }

  @override
  TypeInformation visitNot(ir.Not node) {
    List<IsCheck> temp = _positiveIsChecks;
    _positiveIsChecks = _negativeIsChecks;
    _negativeIsChecks = temp;
    visit(node.operand);
    temp = _positiveIsChecks;
    _positiveIsChecks = _negativeIsChecks;
    _negativeIsChecks = temp;
    return _types.boolType;
  }

  @override
  TypeInformation visitLogicalExpression(ir.LogicalExpression node) {
    if (node.operator == '&&') {
      _conditionIsSimple = false;
      bool oldAccumulateIsChecks = _accumulateIsChecks;
      List<IsCheck> oldPositiveIsChecks = _positiveIsChecks;
      List<IsCheck> oldNegativeIsChecks = _negativeIsChecks;
      if (!_accumulateIsChecks) {
        _accumulateIsChecks = true;
        _positiveIsChecks = <IsCheck>[];
        _negativeIsChecks = <IsCheck>[];
      }
      visit(node.left);
      LocalsHandler saved = _locals;
      _locals = new LocalsHandler.from(_locals, node);
      _updateIsChecks(_positiveIsChecks, _negativeIsChecks);
      LocalsHandler narrowed;
      if (oldAccumulateIsChecks) {
        narrowed = new LocalsHandler.topLevelCopyOf(_locals);
      } else {
        _accumulateIsChecks = false;
        _positiveIsChecks = oldPositiveIsChecks;
        _negativeIsChecks = oldNegativeIsChecks;
      }
      visit(node.right);
      if (oldAccumulateIsChecks) {
        bool invalidatedInRightHandSide(IsCheck check) {
          return narrowed.locals[check.local] != _locals.locals[check.local];
        }

        _positiveIsChecks.removeWhere(invalidatedInRightHandSide);
        _negativeIsChecks.removeWhere(invalidatedInRightHandSide);
      }
      saved.mergeDiamondFlow(_locals, null);
      _locals = saved;
      return _types.boolType;
    } else if (node.operator == '||') {
      _conditionIsSimple = false;
      List<IsCheck> positiveIsChecks = <IsCheck>[];
      List<IsCheck> negativeIsChecks = <IsCheck>[];
      bool isSimple =
          handleCondition(node.left, positiveIsChecks, negativeIsChecks);
      LocalsHandler saved = _locals;
      _locals = new LocalsHandler.from(_locals, node);
      if (isSimple) {
        _updateIsChecks(negativeIsChecks, positiveIsChecks);
      }
      bool oldAccumulateIsChecks = _accumulateIsChecks;
      _accumulateIsChecks = false;
      visit(node.right);
      _accumulateIsChecks = oldAccumulateIsChecks;
      saved.mergeDiamondFlow(_locals, null);
      _locals = saved;
      return _types.boolType;
    }
    failedAt(CURRENT_ELEMENT_SPANNABLE,
        "Unexpected logical operator '${node.operator}'.");
    return null;
  }
}

class IsCheck {
  final ir.Expression node;
  final Local local;
  final DartType type;

  IsCheck(this.node, this.local, this.type);

  String toString() => 'IsCheck($local,$type)';
}
