// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common.dart';
import '../common/names.dart';
import '../constants/constant_system.dart' as constant_system;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_domain.dart';
import '../inferrer/types.dart';
import '../ir/constants.dart';
import '../ir/static_type_provider.dart';
import '../ir/util.dart';
import '../js_backend/field_analysis.dart';
import '../js_model/element_map.dart';
import '../js_model/locals.dart' show JumpVisitor;
import '../js_model/js_world.dart';
import '../native/behavior.dart';
import '../options.dart';
import '../universe/selector.dart';
import '../universe/side_effects.dart';
import '../util/util.dart';
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
  final JsClosedWorld _closedWorld;
  final InferrerEngine _inferrer;
  final TypeSystem _types;
  final MemberEntity _analyzedMember;
  final ir.Node _analyzedNode;
  final KernelToLocalsMap _localsMap;
  final GlobalTypeInferenceElementData _memberData;
  final bool _inGenerativeConstructor;

  DartTypes get _dartTypes => _closedWorld.dartTypes;

  LocalState _stateInternal;
  LocalState _stateAfterWhenTrueInternal;
  LocalState _stateAfterWhenFalseInternal;

  /// Returns the current local state for when the boolean value of the most
  /// recently visited node is not taken into account
  LocalState get _state {
    return _stateInternal;
  }

  /// Sets the current local state for when the boolean value of the most
  /// recently visited node is not taken into account
  ///
  /// This used for when the most recently visited node is not a boolean
  /// expression and there for also resets [_stateAfterWhenTrue] and
  /// [_stateAfterWhenFalse] to the same value.
  void set _state(LocalState value) {
    _stateInternal = value;
    _stateAfterWhenTrueInternal = _stateAfterWhenFalseInternal = null;
  }

  /// Returns the current local state for when the most recently visited node
  /// has evaluated to `true`.
  ///
  /// If the most recently visited node is not a boolean expression then this is
  /// the same as [_state].
  LocalState get _stateAfterWhenTrue =>
      _stateAfterWhenTrueInternal ?? _stateInternal;

  /// Returns the current local state for when the most recently visited node
  /// has evaluated to `false`.
  ///
  /// If the most recently visited node is not a boolean expression then this is
  /// the same as [_state].
  LocalState get _stateAfterWhenFalse =>
      _stateAfterWhenFalseInternal ?? _stateInternal;

  /// Sets the current local state. [base] is the local state for when the
  /// boolean value of the most recently visited node is not taken into account.
  /// [whenTrue] and [whenFalse] are the local state for when the boolean value
  /// of the most recently visited node is `true` or `false`, respectively.
  void _setStateAfter(
      LocalState base, LocalState whenTrue, LocalState whenFalse) {
    _stateInternal = base;
    _stateAfterWhenTrueInternal = whenTrue;
    _stateAfterWhenFalseInternal = whenFalse;
  }

  final SideEffectsBuilder _sideEffectsBuilder;
  final Map<JumpTarget, List<LocalState>> _breaksFor =
      <JumpTarget, List<LocalState>>{};
  final Map<JumpTarget, List<LocalState>> _continuesFor =
      <JumpTarget, List<LocalState>>{};
  TypeInformation _returnType;
  final Set<Local> _capturedVariables = new Set<Local>();
  final Map<Local, FieldEntity> _capturedAndBoxed;

  final StaticTypeProvider _staticTypeProvider;

  /// Whether we currently taken the boolean result of is-checks or null-checks
  /// into account in the local state.
  bool _accumulateIsChecks = false;

  KernelTypeGraphBuilder(
      this._options,
      this._closedWorld,
      this._inferrer,
      this._analyzedMember,
      this._analyzedNode,
      this._localsMap,
      this._staticTypeProvider,
      [this._stateInternal,
      Map<Local, FieldEntity> capturedAndBoxed])
      : this._types = _inferrer.types,
        this._memberData = _inferrer.dataOfMember(_analyzedMember),
        // TODO(johnniwinther): Should side effects also be tracked for field
        // initializers?
        this._sideEffectsBuilder = _analyzedMember is FunctionEntity
            ? _inferrer.inferredDataBuilder
                .getSideEffectsBuilder(_analyzedMember)
            : new SideEffectsBuilder.free(_analyzedMember),
        this._inGenerativeConstructor = _analyzedNode is ir.Constructor,
        this._capturedAndBoxed = capturedAndBoxed != null
            ? new Map<Local, FieldEntity>.from(capturedAndBoxed)
            : <Local, FieldEntity>{} {
    if (_state != null) return;

    _state = new LocalState.initial(
        inGenerativeConstructor: _inGenerativeConstructor);
  }

  JsToElementMap get _elementMap => _closedWorld.elementMap;

  ClosureData get _closureDataLookup => _closedWorld.closureDataLookup;

  DartType _getStaticType(ir.Expression node) {
    return _elementMap.getDartType(_staticTypeProvider.getStaticType(node));
  }

  int _loopLevel = 0;

  bool get inLoop => _loopLevel > 0;

  /// Returns `true` if [member] is defined in a subclass of the current this
  /// type.
  bool _isInClassOrSubclass(MemberEntity member) {
    ClassEntity cls = _elementMap.getMemberThisType(_analyzedMember)?.element;
    if (cls == null) return false;
    return _closedWorld.classHierarchy.isSubclassOf(member.enclosingClass, cls);
  }

  /// Checks whether the access or update of [selector] on [mask] potentially
  /// exposes `this`.
  ///
  /// If all matching members are instance fields on the current `this`
  /// class or subclasses, `this` is not considered to be exposed.
  ///
  /// If an instance field matched with a [selector] that is _not_ a setter, the
  /// field is considered to have been read before initialization and the field
  /// is assumed to be potentially `null`.
  void _checkIfExposesThis(Selector selector, AbstractValue mask) {
    if (_state.isThisExposed) {
      // We already consider `this` to have been exposed.
      return;
    }
    if (_inferrer.closedWorld.includesClosureCall(selector, mask)) {
      // TODO(ngeoffray): We could do better here if we knew what we
      // are calling does not expose this.
      _state.markThisAsExposed();
    } else {
      _inferrer.forEachElementMatching(selector, mask, (MemberEntity element) {
        if (element != null && element.isField) {
          FieldEntity field = element;
          if (!selector.isSetter &&
              _isInClassOrSubclass(field) &&
              field.isAssignable &&
              _state.readField(field) == null &&
              getFieldInitializer(_elementMap, field) == null) {
            // If the field is being used before this constructor
            // actually had a chance to initialize it, say it can be
            // null.
            _inferrer.recordTypeOfField(field, _types.nullType);
          }
          // Accessing a field does not expose `this`.
          return true;
        }
        // TODO(ngeoffray): We could do better here if we knew what we
        // are calling does not expose this.
        _state.markThisAsExposed();
        return false;
      });
    }
  }

  TypeInformation run() {
    if (_analyzedMember.isField) {
      if (_analyzedNode == null || isNullLiteral(_analyzedNode)) {
        // Eagerly bailout, because computing the closure data only
        // works for functions and field assignments.
        return _types.nullType;
      }
    }

    // Update the locals that are boxed in [locals]. These locals will
    // be handled specially, in that we are computing their LUB at
    // each update, and reading them yields the type that was found in a
    // previous analysis of [outermostElement].
    ScopeInfo scopeInfo = _closureDataLookup.getScopeInfo(_analyzedMember);
    scopeInfo.forEachBoxedVariable((variable, field) {
      _capturedAndBoxed[variable] = field;
    });

    return visit(_analyzedNode);
  }

  bool isIncompatibleInvoke(FunctionEntity function, ArgumentsTypes arguments) {
    ParameterStructure parameterStructure = function.parameterStructure;

    return arguments.positional.length <
            parameterStructure.requiredPositionalParameters ||
        arguments.positional.length > parameterStructure.positionalParameters ||
        arguments.named.keys
            .any((name) => !parameterStructure.namedParameters.contains(name));
  }

  void recordReturnType(TypeInformation type) {
    FunctionEntity analyzedMethod = _analyzedMember;
    _returnType =
        _inferrer.addReturnTypeForMethod(analyzedMethod, _returnType, type);
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

  TypeInformation visit(ir.Node node, {bool conditionContext: false}) {
    var oldAccumulateIsChecks = _accumulateIsChecks;
    _accumulateIsChecks = conditionContext;
    var result = node?.accept(this);
    _accumulateIsChecks = oldAccumulateIsChecks;
    return result;
  }

  void visitList(List<ir.Node> nodes) {
    if (nodes == null) return;
    nodes.forEach(visit);
  }

  void handleParameter(ir.VariableDeclaration node, {bool isOptional}) {
    Local local = _localsMap.getLocalVariable(node);
    DartType type = _localsMap.getLocalType(_elementMap, local);
    _state.updateLocal(_inferrer, _capturedAndBoxed, local,
        _inferrer.typeOfParameter(local), node, type);
    if (isOptional) {
      TypeInformation type;
      if (node.initializer != null) {
        type = visit(node.initializer);
      } else {
        type = _types.nullType;
      }
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
          TypeInformation type = _state.readField(member);
          MemberDefinition definition = _elementMap.getMemberDefinition(member);
          assert(definition.kind == MemberKind.regular);
          ir.Field node = definition.node;
          if (type == null &&
              (node.initializer == null || isNullLiteral(node.initializer))) {
            _inferrer.recordTypeOfField(member, _types.nullType);
          }
        }
      });
    }
    _inferrer.recordExposesThis(_analyzedMember, _state.isThisExposed);

    if (cls.isAbstract) {
      if (_closedWorld.classHierarchy.isInstantiated(cls)) {
        _returnType = _types.nonNullSubclass(cls);
      } else {
        // TODO(johnniwinther): Avoid analyzing [_analyzedMember] in this
        // case; it's never called.
        _returnType = _types.nonNullEmpty();
      }
    } else {
      _returnType = _types.nonNullExact(cls);
    }
    assert(_breaksFor.isEmpty);
    assert(_continuesFor.isEmpty);
    return _returnType;
  }

  @override
  visitFieldInitializer(ir.FieldInitializer node) {
    TypeInformation rhsType = visit(node.value);
    FieldEntity field = _elementMap.getField(node.field);
    _state.updateField(field, rhsType);
    _inferrer.recordTypeOfField(field, rhsType);
    return null;
  }

  @override
  visitSuperInitializer(ir.SuperInitializer node) {
    ConstructorEntity constructor = _elementMap.getConstructor(node.target);
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    Selector selector = new Selector(SelectorKind.CALL, constructor.memberName,
        _elementMap.getCallStructure(node.arguments));
    handleConstructorInvoke(
        node, node.arguments, selector, constructor, arguments);

    _inferrer.analyze(constructor);
    if (_inferrer.checkIfExposesThis(constructor)) {
      _state.markThisAsExposed();
    }
    return null;
  }

  @override
  visitRedirectingInitializer(ir.RedirectingInitializer node) {
    ConstructorEntity constructor = _elementMap.getConstructor(node.target);
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    Selector selector = new Selector(SelectorKind.CALL, constructor.memberName,
        _elementMap.getCallStructure(node.arguments));
    handleConstructorInvoke(
        node, node.arguments, selector, constructor, arguments);

    _inferrer.analyze(constructor);
    if (_inferrer.checkIfExposesThis(constructor)) {
      _state.markThisAsExposed();
    }
    return null;
  }

  @override
  visitLocalInitializer(ir.LocalInitializer node) {
    visit(node.variable);
    return null;
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
    handleParameters(node);

    if (_closedWorld.nativeData.isNativeMember(_analyzedMember)) {
      // Native methods do not have a body, and we currently just say
      // they return dynamic and may contain all side-effects.
      NativeBehavior nativeBehavior =
          _closedWorld.nativeData.getNativeMethodBehavior(_analyzedMember);
      _sideEffectsBuilder.add(nativeBehavior.sideEffects);
      return _types.dynamicType;
    }

    visit(node.body);
    switch (node.asyncMarker) {
      case ir.AsyncMarker.Sync:
        if (_returnType == null) {
          // No return in the body.
          _returnType = _state.seenReturnOrThrow
              ? _types.nonNullEmpty() // Body always throws.
              : _types.nullType;
        } else if (!_state.seenReturnOrThrow) {
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
    assert(_breaksFor.isEmpty);
    assert(_continuesFor.isEmpty);
    return _returnType;
  }

  @override
  TypeInformation visitInstantiation(ir.Instantiation node) {
    return createInstantiationTypeInformation(visit(node.expression));
  }

  TypeInformation createInstantiationTypeInformation(
      TypeInformation expressionType) {
    // TODO(sra): Add a TypeInformation for Instantiations.  Instantiated
    // generic methods will need to be traced separately, and have the
    // information gathered in tracing reflected back to the generic method. For
    // now, pass along the uninstantiated method.
    return expressionType;
  }

  @override
  TypeInformation defaultExpression(ir.Expression node) {
    throw new UnimplementedError(
        'Unhandled expression: ${node} (${node.runtimeType})');
  }

  @override
  defaultStatement(ir.Statement node) {
    throw new UnimplementedError(
        'Unhandled statement: ${node} (${node.runtimeType})');
  }

  @override
  TypeInformation visitNullLiteral(ir.NullLiteral literal) {
    return createNullTypeInformation();
  }

  TypeInformation createNullTypeInformation() {
    return _types.nullType;
  }

  @override
  visitBlock(ir.Block block) {
    for (ir.Statement statement in block.statements) {
      visit(statement);
      if (_state.aborts) break;
    }
    return null;
  }

  @override
  visitExpressionStatement(ir.ExpressionStatement node) {
    visit(node.expression);
    return null;
  }

  @override
  visitEmptyStatement(ir.EmptyStatement node) {
    // Nothing to do.
    return null;
  }

  @override
  visitAssertStatement(ir.AssertStatement node) {
    // Avoid pollution from assert statement unless enabled.
    if (!_options.enableUserAssertions) {
      return null;
    }
    // TODO(johnniwinther): Should assert be used with --trust-type-annotations?
    // TODO(johnniwinther): Track reachable for assertions known to fail.
    LocalState stateBefore = _state;
    handleCondition(node.condition);
    LocalState afterConditionWhenTrue = _stateAfterWhenTrue;
    LocalState afterConditionWhenFalse = _stateAfterWhenFalse;
    _state = new LocalState.childPath(afterConditionWhenFalse);
    visit(node.message);
    LocalState stateAfterMessage = _state;
    stateAfterMessage.seenReturnOrThrow = true;
    _state = stateBefore.mergeDiamondFlow(
        _inferrer, afterConditionWhenTrue, stateAfterMessage);
    return null;
  }

  @override
  visitBreakStatement(ir.BreakStatement node) {
    JumpTarget target = _localsMap.getJumpTargetForBreak(node);
    _state.seenBreakOrContinue = true;
    // Do a deep-copy of the locals, because the code following the
    // break will change them.
    if (_localsMap.generateContinueForBreak(node)) {
      _continuesFor[target].add(new LocalState.deepCopyOf(_state));
    } else {
      _breaksFor[target].add(new LocalState.deepCopyOf(_state));
    }
    return null;
  }

  @override
  visitLabeledStatement(ir.LabeledStatement node) {
    ir.Statement body = node.body;
    if (JumpVisitor.canBeBreakTarget(body)) {
      // Loops and switches handle their own labels.
      visit(body);
    } else {
      JumpTarget jumpTarget = _localsMap.getJumpTargetForLabel(node);
      _setupBreaksAndContinues(jumpTarget);
      visit(body);
      _state.mergeAfterBreaks(_inferrer, _getBreaks(jumpTarget));
      _clearBreaksAndContinues(jumpTarget);
    }
    return null;
  }

  @override
  visitSwitchStatement(ir.SwitchStatement node) {
    visit(node.expression);

    JumpTarget jumpTarget = _localsMap.getJumpTargetForSwitch(node);
    _setupBreaksAndContinues(jumpTarget);

    List<JumpTarget> continueTargets = <JumpTarget>[];
    for (ir.SwitchCase switchCase in node.cases) {
      JumpTarget continueTarget =
          _localsMap.getJumpTargetForSwitchCase(switchCase);
      if (continueTarget != null) {
        continueTargets.add(continueTarget);
      }
    }
    if (continueTargets.isNotEmpty) {
      continueTargets.forEach(_setupBreaksAndContinues);

      // If the switch statement has a continue, we conservatively
      // visit all cases and update [locals] until we have reached a
      // fixed point.
      bool changed;
      _state.startLoop(_inferrer, node);
      do {
        changed = false;
        for (ir.SwitchCase switchCase in node.cases) {
          LocalState stateBeforeCase = _state;
          _state = new LocalState.childPath(stateBeforeCase);
          visit(switchCase);
          LocalState stateAfterCase = _state;
          changed =
              stateBeforeCase.mergeAll(_inferrer, [stateAfterCase]) || changed;
          _state = stateBeforeCase;
        }
      } while (changed);
      _state.endLoop(_inferrer, node);

      continueTargets.forEach(_clearBreaksAndContinues);
    } else {
      LocalState stateBeforeCase = _state;
      List<LocalState> statesToMerge = <LocalState>[];
      bool hasDefaultCase = false;

      for (ir.SwitchCase switchCase in node.cases) {
        if (switchCase.isDefault) {
          hasDefaultCase = true;
        }
        _state = new LocalState.childPath(stateBeforeCase);
        visit(switchCase);
        statesToMerge.add(_state);
      }
      stateBeforeCase.mergeAfterBreaks(_inferrer, statesToMerge,
          keepOwnLocals: !hasDefaultCase);
      _state = stateBeforeCase;
    }
    _clearBreaksAndContinues(jumpTarget);
    return null;
  }

  @override
  visitSwitchCase(ir.SwitchCase node) {
    visit(node.body);
    return null;
  }

  @override
  visitContinueSwitchStatement(ir.ContinueSwitchStatement node) {
    JumpTarget target = _localsMap.getJumpTargetForContinueSwitch(node);
    _state.seenBreakOrContinue = true;
    // Do a deep-copy of the locals, because the code following the
    // break will change them.
    _continuesFor[target].add(new LocalState.deepCopyOf(_state));
    return null;
  }

  @override
  TypeInformation visitListLiteral(ir.ListLiteral node) {
    return createListTypeInformation(
        node, node.expressions.map((e) => visit(e)),
        isConst: node.isConst);
  }

  TypeInformation createListTypeInformation(
      ir.TreeNode node, Iterable<TypeInformation> elementTypes,
      {bool isConst}) {
    // We only set the type once. We don't need to re-visit the children
    // when re-analyzing the node.
    return _inferrer.concreteTypes.putIfAbsent(node, () {
      TypeInformation elementType;
      int length = 0;
      for (TypeInformation type in elementTypes) {
        elementType = elementType == null
            ? _types.allocatePhi(null, null, type, isTry: false)
            : _types.addPhiInput(null, elementType, type);
        length++;
      }
      elementType = elementType == null
          ? _types.nonNullEmpty()
          : _types.simplifyPhi(null, null, elementType);
      TypeInformation containerType =
          isConst ? _types.constListType : _types.growableListType;
      return _types.allocateList(
          containerType, node, _analyzedMember, elementType, length);
    });
  }

  @override
  TypeInformation visitSetLiteral(ir.SetLiteral node) {
    return createSetTypeInformation(node, node.expressions.map((e) => visit(e)),
        isConst: node.isConst);
  }

  TypeInformation createSetTypeInformation(
      ir.TreeNode node, Iterable<TypeInformation> elementTypes,
      {bool isConst}) {
    return _inferrer.concreteTypes.putIfAbsent(node, () {
      TypeInformation elementType;
      for (TypeInformation type in elementTypes) {
        elementType = elementType == null
            ? _types.allocatePhi(null, null, type, isTry: false)
            : _types.addPhiInput(null, elementType, type);
      }
      elementType = elementType == null
          ? _types.nonNullEmpty()
          : _types.simplifyPhi(null, null, elementType);
      TypeInformation containerType =
          isConst ? _types.constSetType : _types.setType;
      return _types.allocateSet(
          containerType, node, _analyzedMember, elementType);
    });
  }

  @override
  TypeInformation visitMapLiteral(ir.MapLiteral node) {
    return createMapTypeInformation(
        node, node.entries.map((e) => new Pair(visit(e.key), visit(e.value))),
        isConst: node.isConst);
  }

  TypeInformation createMapTypeInformation(ir.TreeNode node,
      Iterable<Pair<TypeInformation, TypeInformation>> entryTypes,
      {bool isConst}) {
    return _inferrer.concreteTypes.putIfAbsent(node, () {
      List keyTypes = <TypeInformation>[];
      List valueTypes = <TypeInformation>[];

      for (Pair<TypeInformation, TypeInformation> entryType in entryTypes) {
        keyTypes.add(entryType.a);
        valueTypes.add(entryType.b);
      }

      TypeInformation type = isConst ? _types.constMapType : _types.mapType;
      return _types.allocateMap(
          type, node, _analyzedMember, keyTypes, valueTypes);
    });
  }

  @override
  TypeInformation visitReturnStatement(ir.ReturnStatement node) {
    ir.Node expression = node.expression;
    recordReturnType(expression == null ? _types.nullType : visit(expression));
    _state.seenReturnOrThrow = true;
    _state.markInitializationAsIndefinite();
    return null;
  }

  @override
  TypeInformation visitBoolLiteral(ir.BoolLiteral node) {
    return createBoolTypeInformation(node.value);
  }

  TypeInformation createBoolTypeInformation(bool value) {
    return _types.boolLiteralType(value);
  }

  @override
  TypeInformation visitIntLiteral(ir.IntLiteral node) {
    return createIntTypeInformation(node.value);
  }

  TypeInformation createIntTypeInformation(int value) {
    // The JavaScript backend may turn this literal into a double at
    // runtime.
    return _types.getConcreteTypeFor(_closedWorld.abstractValueDomain
        .computeAbstractValueForConstant(
            constant_system.createIntFromInt(value)));
  }

  @override
  TypeInformation visitDoubleLiteral(ir.DoubleLiteral node) {
    return createDoubleTypeInformation(node.value);
  }

  TypeInformation createDoubleTypeInformation(double value) {
    // The JavaScript backend may turn this literal into a double at
    // runtime.
    return _types.getConcreteTypeFor(_closedWorld.abstractValueDomain
        .computeAbstractValueForConstant(constant_system.createDouble(value)));
  }

  @override
  TypeInformation visitStringLiteral(ir.StringLiteral node) {
    return createStringTypeInformation(node.value);
  }

  TypeInformation createStringTypeInformation(String value) {
    return _types.stringLiteralType(value);
  }

  @override
  TypeInformation visitStringConcatenation(ir.StringConcatenation node) {
    // Interpolation could have any effects since it could call any toString()
    // method.
    // TODO(sra): This could be modelled by a call to toString() but with a
    // guaranteed String return type.  Interpolation of known types would get
    // specialized effects.  This would not currently be effective since the JS
    // code in the toString methods for intercepted primitive types is assumed
    // to have all effects.  Effect annotations on JS code would be needed to
    // get the benefit.
    _sideEffectsBuilder.setAllSideEffects();

    node.visitChildren(this);
    return _types.stringType;
  }

  @override
  TypeInformation visitSymbolLiteral(ir.SymbolLiteral node) {
    return createSymbolLiteralTypeInformation();
  }

  TypeInformation createSymbolLiteralTypeInformation() {
    return _types
        .nonNullSubtype(_closedWorld.commonElements.symbolImplementationClass);
  }

  @override
  TypeInformation visitTypeLiteral(ir.TypeLiteral node) {
    return createTypeLiteralInformation();
  }

  TypeInformation createTypeLiteralInformation() {
    return _types.typeType;
  }

  @override
  TypeInformation visitVariableDeclaration(ir.VariableDeclaration node) {
    assert(
        node.parent is! ir.FunctionNode, "Unexpected parameter declaration.");
    Local local = _localsMap.getLocalVariable(node);
    DartType type = _localsMap.getLocalType(_elementMap, local);
    if (node.initializer == null) {
      _state.updateLocal(
          _inferrer, _capturedAndBoxed, local, _types.nullType, node, type);
    } else {
      _state.updateLocal(_inferrer, _capturedAndBoxed, local,
          visit(node.initializer), node, type);
    }
    if (node.initializer is ir.ThisExpression) {
      _state.markThisAsExposed();
    }
    return null;
  }

  @override
  TypeInformation visitVariableGet(ir.VariableGet node) {
    Local local = _localsMap.getLocalVariable(node.variable);
    TypeInformation type =
        _state.readLocal(_inferrer, _capturedAndBoxed, local);
    assert(type != null, "Missing type information for $local.");
    return type;
  }

  @override
  TypeInformation visitVariableSet(ir.VariableSet node) {
    TypeInformation rhsType = visit(node.value);
    if (node.value is ir.ThisExpression) {
      _state.markThisAsExposed();
    }
    Local local = _localsMap.getLocalVariable(node.variable);
    DartType type = _localsMap.getLocalType(_elementMap, local);
    _state.updateLocal(
        _inferrer, _capturedAndBoxed, local, rhsType, node, type);
    return rhsType;
  }

  ArgumentsTypes analyzeArguments(ir.Arguments arguments) {
    List<TypeInformation> positional = <TypeInformation>[];
    Map<String, TypeInformation> named;
    for (ir.Expression argument in arguments.positional) {
      // TODO(ngeoffray): We could do better here if we knew what we
      // are calling does not expose this.
      if (argument is ir.ThisExpression) {
        _state.markThisAsExposed();
      }
      positional.add(visit(argument));
    }
    for (ir.NamedExpression argument in arguments.named) {
      named ??= <String, TypeInformation>{};
      ir.Expression value = argument.value;
      // TODO(ngeoffray): We could do better here if we knew what we
      // are calling does not expose this.
      if (value is ir.ThisExpression) {
        _state.markThisAsExposed();
      }
      named[argument.name] = visit(value);
    }

    return new ArgumentsTypes(positional, named);
  }

  AbstractValue _typeOfReceiver(ir.TreeNode node, ir.TreeNode receiver) {
    KernelGlobalTypeInferenceElementData data = _memberData;
    AbstractValue mask = data.typeOfReceiver(node);
    if (mask != null) return mask;
    // TODO(sigmund): ensure that this is only called once per node.
    DartType staticType = _getStaticType(receiver);
    bool includeNull =
        _dartTypes.useLegacySubtyping || staticType is NullableType;
    staticType = staticType.withoutNullability;
    if (staticType is InterfaceType) {
      ClassEntity cls = staticType.element;
      if (receiver is ir.ThisExpression && !_closedWorld.isUsedAsMixin(cls)) {
        mask = _closedWorld.abstractValueDomain.createNonNullSubclass(cls);
      } else if (includeNull) {
        mask = _closedWorld.abstractValueDomain.createNullableSubtype(cls);
      } else {
        mask = _closedWorld.abstractValueDomain.createNonNullSubtype(cls);
      }
      data.setReceiverTypeMask(node, mask);
      return mask;
    }
    // TODO(sigmund): consider also extracting the bound of type parameters.
    return null;
  }

  @override
  TypeInformation visitMethodInvocation(ir.MethodInvocation node) {
    Selector selector = _elementMap.getSelector(node);
    AbstractValue mask = _typeOfReceiver(node, node.receiver);

    ir.TreeNode receiver = node.receiver;
    if (receiver is ir.VariableGet &&
        receiver.variable.parent is ir.FunctionDeclaration) {
      // This is an invocation of a named local function.
      ArgumentsTypes arguments = analyzeArguments(node.arguments);
      ClosureRepresentationInfo info =
          _closureDataLookup.getClosureInfo(receiver.variable.parent);
      if (isIncompatibleInvoke(info.callMethod, arguments)) {
        return _types.dynamicType;
      }

      TypeInformation type =
          handleStaticInvoke(node, selector, info.callMethod, arguments);
      FunctionType functionType =
          _elementMap.elementEnvironment.getFunctionType(info.callMethod);
      if (functionType.returnType.containsFreeTypeVariables) {
        // The return type varies with the call site so we narrow the static
        // return type.
        type = _types.narrowType(type, _getStaticType(node));
      }
      return type;
    }

    TypeInformation receiverType = visit(receiver);
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
    if (node.receiver is ir.ThisExpression) {
      _checkIfExposesThis(
          selector, _types.newTypedSelector(receiverType, mask));
    }
    TypeInformation type = handleDynamicInvoke(
        CallType.access, node, selector, mask, receiverType, arguments);
    ir.Member interfaceTarget = node.interfaceTarget;
    if (interfaceTarget != null) {
      if (interfaceTarget is ir.Procedure &&
          (interfaceTarget.kind == ir.ProcedureKind.Method ||
              interfaceTarget.kind == ir.ProcedureKind.Operator)) {
        // Pull the type from kernel (instead of from the J-model) because the
        // interface target might be abstract and therefore not part of the
        // J-model.
        ir.DartType returnType = interfaceTarget.function.returnType;
        // The return type varies with the call site so we narrow the static
        // return type.
        if (containsFreeVariables(returnType)) {
          type = _types.narrowType(type, _getStaticType(node));
        }
      } else {
        // The return type is thrown away when using [TypeMask]s; narrow to the
        // static return type.
        type = _types.narrowType(type, _getStaticType(node));
      }
    } else {
      // We don't have a known target but the static type hold some information
      // if it is a function type.
      type = _types.narrowType(type, _getStaticType(node));
    }
    return type;
  }

  TypeInformation _handleDynamic(
      CallType callType,
      ir.Node node,
      Selector selector,
      AbstractValue mask,
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

    ir.VariableDeclaration variable;
    if (node is ir.MethodInvocation && node.receiver is ir.VariableGet) {
      ir.VariableGet get = node.receiver;
      variable = get.variable;
    } else if (node is ir.PropertyGet && node.receiver is ir.VariableGet) {
      ir.VariableGet get = node.receiver;
      variable = get.variable;
    } else if (node is ir.PropertySet && node.receiver is ir.VariableGet) {
      ir.VariableGet get = node.receiver;
      variable = get.variable;
    }

    if (variable != null) {
      Local local = _localsMap.getLocalVariable(variable);
      if (!_capturedVariables.contains(local)) {
        // Receiver strengthening to non-null.
        DartType type = _localsMap.getLocalType(_elementMap, local);
        _state.updateLocal(
            _inferrer, _capturedAndBoxed, local, receiverType, node, type,
            excludeNull: !selector.appliesToNullWithoutThrow());
      }
    }

    return _inferrer.registerCalledSelector(callType, node, selector, mask,
        receiverType, _analyzedMember, arguments, _sideEffectsBuilder,
        inLoop: inLoop, isConditional: false);
  }

  TypeInformation handleDynamicGet(ir.Node node, Selector selector,
      AbstractValue mask, TypeInformation receiverType) {
    return _handleDynamic(
        CallType.access, node, selector, mask, receiverType, null);
  }

  TypeInformation handleDynamicSet(
      ir.Node node,
      Selector selector,
      AbstractValue mask,
      TypeInformation receiverType,
      TypeInformation rhsType) {
    ArgumentsTypes arguments = new ArgumentsTypes([rhsType], null);
    return _handleDynamic(
        CallType.access, node, selector, mask, receiverType, arguments);
  }

  TypeInformation handleDynamicInvoke(
      CallType callType,
      ir.Node node,
      Selector selector,
      AbstractValue mask,
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
  TypeInformation visitBlockExpression(ir.BlockExpression node) {
    visit(node.body);
    return visit(node.value);
  }

  @override
  TypeInformation visitForInStatement(ir.ForInStatement node) {
    if (node.iterable is ir.ThisExpression) {
      // Any reasonable implementation of an iterator would expose
      // this, so we play it safe and assume it will.
      _state.markThisAsExposed();
    }

    AbstractValue currentMask;
    AbstractValue moveNextMask;
    TypeInformation iteratorType;
    if (node.isAsync) {
      TypeInformation expressionType = visit(node.iterable);

      currentMask = _memberData.typeOfIteratorCurrent(node);
      moveNextMask = _memberData.typeOfIteratorMoveNext(node);

      ConstructorEntity constructor =
          _closedWorld.commonElements.streamIteratorConstructor;

      /// Synthesize a call to the [StreamIterator] constructor.
      iteratorType = handleStaticInvoke(
          node, null, constructor, new ArgumentsTypes([expressionType], null));
    } else {
      TypeInformation expressionType = visit(node.iterable);
      Selector iteratorSelector = Selectors.iterator;
      AbstractValue iteratorMask = _memberData.typeOfIterator(node);
      currentMask = _memberData.typeOfIteratorCurrent(node);
      moveNextMask = _memberData.typeOfIteratorMoveNext(node);

      iteratorType = handleDynamicInvoke(CallType.forIn, node, iteratorSelector,
          iteratorMask, expressionType, new ArgumentsTypes.empty());
    }

    handleDynamicInvoke(CallType.forIn, node, Selectors.moveNext, moveNextMask,
        iteratorType, new ArgumentsTypes.empty());
    TypeInformation currentType = handleDynamicInvoke(
        CallType.forIn,
        node,
        Selectors.current,
        currentMask,
        iteratorType,
        new ArgumentsTypes.empty());

    Local variable = _localsMap.getLocalVariable(node.variable);
    DartType variableType = _localsMap.getLocalType(_elementMap, variable);
    _state.updateLocal(_inferrer, _capturedAndBoxed, variable, currentType,
        node.variable, variableType);

    JumpTarget target = _localsMap.getJumpTargetForForIn(node);
    return handleLoop(node, target, () {
      visit(node.body);
    });
  }

  void _setupBreaksAndContinues(JumpTarget target) {
    if (target == null) return;
    if (target.isContinueTarget) {
      _continuesFor[target] = <LocalState>[];
    }
    if (target.isBreakTarget) {
      _breaksFor[target] = <LocalState>[];
    }
  }

  void _clearBreaksAndContinues(JumpTarget element) {
    _continuesFor.remove(element);
    _breaksFor.remove(element);
  }

  List<LocalState> _getBreaks(JumpTarget target) {
    List<LocalState> list = <LocalState>[_state];
    if (target == null) return list;
    if (!target.isBreakTarget) return list;
    return list..addAll(_breaksFor[target]);
  }

  List<LocalState> _getLoopBackEdges(JumpTarget target) {
    List<LocalState> list = <LocalState>[_state];
    if (target == null) return list;
    if (!target.isContinueTarget) return list;
    return list..addAll(_continuesFor[target]);
  }

  TypeInformation handleLoop(ir.Node node, JumpTarget target, void logic()) {
    _loopLevel++;
    bool changed = false;
    LocalState stateBefore = _state;
    stateBefore.startLoop(_inferrer, node);
    do {
      // Setup (and clear in case of multiple iterations of the loop)
      // the lists of breaks and continues seen in the loop.
      _setupBreaksAndContinues(target);
      _state = new LocalState.childPath(stateBefore);
      logic();
      changed = stateBefore.mergeAll(_inferrer, _getLoopBackEdges(target));
    } while (changed);
    _loopLevel--;
    stateBefore.endLoop(_inferrer, node);
    bool keepOwnLocals = node is! ir.DoStatement;
    _state = stateBefore.mergeAfterBreaks(_inferrer, _getBreaks(target),
        keepOwnLocals: keepOwnLocals);
    _clearBreaksAndContinues(target);
    return null;
  }

  @override
  TypeInformation visitConstructorInvocation(ir.ConstructorInvocation node) {
    ConstructorEntity constructor = _elementMap.getConstructor(node.target);
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    Selector selector = _elementMap.getSelector(node);
    return handleConstructorInvoke(
        node, node.arguments, selector, constructor, arguments);
  }

  /// Try to find the length given to a fixed array constructor call.
  int _findLength(ir.Arguments arguments) {
    int finish(int length) {
      // Filter out lengths that should not be tracked.
      if (length < 0) return null;
      // Serialization limit.
      if (length >= (1 << 30)) return null;
      return length;
    }

    ir.Expression firstArgument = arguments.positional.first;
    if (firstArgument is ir.ConstantExpression &&
        firstArgument.constant is ir.DoubleConstant) {
      ir.DoubleConstant constant = firstArgument.constant;
      double doubleValue = constant.value;
      int truncatedValue = doubleValue.truncate();
      if (doubleValue == truncatedValue) {
        return finish(truncatedValue);
      }
    } else if (firstArgument is ir.IntLiteral) {
      return finish(firstArgument.value);
    } else if (firstArgument is ir.StaticGet) {
      MemberEntity member = _elementMap.getMember(firstArgument.target);
      if (member.isField) {
        FieldAnalysisData fieldData =
            _closedWorld.fieldAnalysis.getFieldData(member);
        if (fieldData.isEffectivelyConstant && fieldData.constantValue.isInt) {
          IntConstantValue intValue = fieldData.constantValue;
          if (intValue.intValue.isValidInt) {
            return finish(intValue.intValue.toInt());
          }
        }
      }
    }
    return null;
  }

  /// Find the base type for a system List constructor from the value passed to
  /// the 'growable' argument. [defaultGrowable] is the default value of the
  /// 'growable' parameter.
  TypeInformation _listBaseType(ir.Arguments arguments,
      {bool defaultGrowable}) {
    TypeInformation finish(bool /*?*/ growable) {
      if (growable == true) return _types.growableListType;
      if (growable == false) return _types.fixedListType;
      return _types.mutableArrayType;
    }

    for (ir.NamedExpression named in arguments.named) {
      if (named.name == 'growable') {
        ir.Expression argument = named.value;
        if (argument is ir.BoolLiteral) return finish(argument.value);
        if (argument is ir.ConstantExpression) {
          ir.Constant constant = argument.constant;
          if (constant is ir.BoolConstant) return finish(constant.value);
        }
        // 'growable' is present, but indeterminate.
        return finish(null);
      }
    }
    // 'growable' is missing.
    return finish(defaultGrowable);
  }

  /// Returns `true` for constructors of typed arrays.
  bool _isConstructorOfTypedArraySubclass(ConstructorEntity constructor) {
    ClassEntity cls = constructor.enclosingClass;
    return cls.library.canonicalUri == Uris.dart__native_typed_data &&
        _closedWorld.nativeData.isNativeClass(cls) &&
        _closedWorld.classHierarchy
            .isSubtypeOf(cls, _closedWorld.commonElements.typedDataClass) &&
        _closedWorld.classHierarchy
            .isSubtypeOf(cls, _closedWorld.commonElements.listClass) &&
        constructor.name == '';
  }

  TypeInformation handleConstructorInvoke(
      ir.Node node,
      ir.Arguments arguments,
      Selector selector,
      ConstructorEntity constructor,
      ArgumentsTypes argumentsTypes) {
    TypeInformation returnType =
        handleStaticInvoke(node, selector, constructor, argumentsTypes);

    // See if we can replace the returned type with one that better describes
    // the operation. For system List constructors we can treat this as the
    // allocation point of a new collection. The static invoke above ensures
    // that the implementation of the constructor sees the arguments.

    var commonElements = _elementMap.commonElements;

    if (commonElements.isUnnamedListConstructor(constructor)) {
      // We have `new List(...)`.
      if (arguments.positional.isEmpty && arguments.named.isEmpty) {
        // We have `new List()`.
        return _inferrer.concreteTypes.putIfAbsent(
            node,
            () => _types.allocateList(_types.growableListType, node,
                _analyzedMember, _types.nonNullEmpty(), 0));
      } else {
        // We have `new List(len)`.
        int length = _findLength(arguments);
        return _inferrer.concreteTypes.putIfAbsent(
            node,
            () => _types.allocateList(_types.fixedListType, node,
                _analyzedMember, _types.nullType, length));
      }
    }

    if (commonElements.isNamedListConstructor('filled', constructor)) {
      // We have something like `List.filled(len, fill)`.
      int length = _findLength(arguments);
      TypeInformation elementType = argumentsTypes.positional[1];
      TypeInformation baseType =
          _listBaseType(arguments, defaultGrowable: false);
      return _inferrer.concreteTypes.putIfAbsent(
          node,
          () => _types.allocateList(
              baseType, node, _analyzedMember, elementType, length));
    }

    if (commonElements.isNamedListConstructor('generate', constructor)) {
      // We have something like `List.generate(len, generator)`.
      int length = _findLength(arguments);
      TypeInformation baseType =
          _listBaseType(arguments, defaultGrowable: true);
      TypeInformation closureArgumentInfo = argumentsTypes.positional[1];
      // If the argument is an immediate closure, the element type is that
      // returned by the closure.
      TypeInformation elementType;
      if (closureArgumentInfo is ClosureTypeInformation) {
        FunctionEntity closure = closureArgumentInfo.closure;
        elementType = _types.getInferredTypeOfMember(closure);
      }
      elementType ??= _types.dynamicType;
      return _inferrer.concreteTypes.putIfAbsent(
          node,
          () => _types.allocateList(
              baseType, node, _analyzedMember, elementType, length));
    }

    if (commonElements.isNamedListConstructor('empty', constructor)) {
      // We have something like `List.empty(growable: true)`.
      TypeInformation baseType =
          _listBaseType(arguments, defaultGrowable: false);
      TypeInformation elementType = _types.nonNullEmpty(); // No elements!
      return _inferrer.concreteTypes.putIfAbsent(
          node,
          () => _types.allocateList(
              baseType, node, _analyzedMember, elementType, 0));
    }
    if (commonElements.isNamedListConstructor('of', constructor) ||
        commonElements.isNamedListConstructor('from', constructor)) {
      // We have something like `List.of(elements)`.
      TypeInformation baseType =
          _listBaseType(arguments, defaultGrowable: true);
      // TODO(sra): Use static type to bound the element type, preferably as a
      // narrowing of all inputs.
      TypeInformation elementType = _types.dynamicType;
      return _inferrer.concreteTypes.putIfAbsent(
          node,
          () => _types.allocateList(
              baseType, node, _analyzedMember, elementType));
    }

    // `JSArray.fixed` corresponds to `new Array(length)`, which is a list
    // filled with `null`.
    if (commonElements.isNamedJSArrayConstructor('fixed', constructor)) {
      int length = _findLength(arguments);
      TypeInformation elementType = _types.nullType;
      return _inferrer.concreteTypes.putIfAbsent(
          node,
          () => _types.allocateList(_types.fixedListType, node, _analyzedMember,
              elementType, length));
    }

    // `JSArray.allocateFixed` creates an array with 'no elements'. The contract
    // is that the caller will assign a value to each member before any element
    // is accessed. We can start tracking the element type as 'bottom'.
    if (commonElements.isNamedJSArrayConstructor(
        'allocateFixed', constructor)) {
      int length = _findLength(arguments);
      TypeInformation elementType = _types.nonNullEmpty();
      return _inferrer.concreteTypes.putIfAbsent(
          node,
          () => _types.allocateList(_types.fixedListType, node, _analyzedMember,
              elementType, length));
    }

    // `JSArray.allocateGrowable` creates an array with 'no elements'. The
    // contract is that the caller will assign a value to each member before any
    // element is accessed. We can start tracking the element type as 'bottom'.
    if (commonElements.isNamedJSArrayConstructor(
        'allocateGrowable', constructor)) {
      int length = _findLength(arguments);
      TypeInformation elementType = _types.nonNullEmpty();
      return _inferrer.concreteTypes.putIfAbsent(
          node,
          () => _types.allocateList(_types.growableListType, node,
              _analyzedMember, elementType, length));
    }

    if (_isConstructorOfTypedArraySubclass(constructor)) {
      // We have something like `Uint32List(len)`.
      int length = _findLength(arguments);
      MemberEntity member = _elementMap.elementEnvironment
          .lookupClassMember(constructor.enclosingClass, '[]');
      TypeInformation elementType = _inferrer.returnTypeOfMember(member);
      return _inferrer.concreteTypes.putIfAbsent(
          node,
          () => _types.allocateList(
              _types.nonNullExact(constructor.enclosingClass),
              node,
              _analyzedMember,
              elementType,
              length));
    }

    return returnType;
  }

  TypeInformation handleStaticInvoke(ir.Node node, Selector selector,
      MemberEntity element, ArgumentsTypes arguments) {
    return _inferrer.registerCalledMember(node, selector, _analyzedMember,
        element, arguments, _sideEffectsBuilder, inLoop);
  }

  TypeInformation handleClosureCall(ir.Node node, Selector selector,
      MemberEntity member, ArgumentsTypes arguments) {
    return _inferrer.registerCalledClosure(
        node,
        selector,
        _inferrer.typeOfMember(member),
        _analyzedMember,
        arguments,
        _sideEffectsBuilder,
        inLoop: inLoop);
  }

  TypeInformation handleForeignInvoke(ir.StaticInvocation node,
      FunctionEntity function, ArgumentsTypes arguments, Selector selector) {
    String name = function.name;
    handleStaticInvoke(node, selector, function, arguments);
    if (name == Identifiers.JS) {
      NativeBehavior nativeBehavior =
          _elementMap.getNativeBehaviorForJsCall(node);
      _sideEffectsBuilder.add(nativeBehavior.sideEffects);
      return _inferrer.typeOfNativeBehavior(nativeBehavior);
    } else if (name == Identifiers.JS_EMBEDDED_GLOBAL) {
      NativeBehavior nativeBehavior =
          _elementMap.getNativeBehaviorForJsEmbeddedGlobalCall(node);
      _sideEffectsBuilder.add(nativeBehavior.sideEffects);
      return _inferrer.typeOfNativeBehavior(nativeBehavior);
    } else if (name == Identifiers.JS_BUILTIN) {
      NativeBehavior nativeBehavior =
          _elementMap.getNativeBehaviorForJsBuiltinCall(node);
      _sideEffectsBuilder.add(nativeBehavior.sideEffects);
      return _inferrer.typeOfNativeBehavior(nativeBehavior);
    } else if (name == Identifiers.JS_STRING_CONCAT) {
      return _types.stringType;
    } else {
      _sideEffectsBuilder.setAllSideEffects();
      return _types.dynamicType;
    }
  }

  @override
  TypeInformation visitStaticInvocation(ir.StaticInvocation node) {
    MemberEntity member = _elementMap.getMember(node.target);
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    Selector selector = _elementMap.getSelector(node);
    if (_closedWorld.commonElements.isForeign(member)) {
      return handleForeignInvoke(node, member, arguments, selector);
    } else if (member.isConstructor) {
      return handleConstructorInvoke(
          node, node.arguments, selector, member, arguments);
    } else {
      assert(member.isFunction, "Unexpected static invocation target: $member");
      TypeInformation type =
          handleStaticInvoke(node, selector, member, arguments);
      FunctionType functionType =
          _elementMap.elementEnvironment.getFunctionType(member);
      if (functionType.returnType.containsFreeTypeVariables) {
        // The return type varies with the call site so we narrow the static
        // return type.
        type = _types.narrowType(type, _getStaticType(node));
      }
      return type;
    }
  }

  @override
  TypeInformation visitLoadLibrary(ir.LoadLibrary node) {
    // TODO(johnniwinther): Improve this by returning a Future type instead.
    return _types.dynamicType;
  }

  @override
  TypeInformation visitStaticGet(ir.StaticGet node) {
    return createStaticGetTypeInformation(node, node.target);
  }

  TypeInformation createStaticGetTypeInformation(
      ir.Node node, ir.Member target) {
    MemberEntity member = _elementMap.getMember(target);
    return handleStaticInvoke(
        node, new Selector.getter(member.memberName), member, null);
  }

  @override
  TypeInformation visitStaticSet(ir.StaticSet node) {
    TypeInformation rhsType = visit(node.value);
    if (node.value is ir.ThisExpression) {
      _state.markThisAsExposed();
    }
    MemberEntity member = _elementMap.getMember(node.target);
    handleStaticInvoke(node, new Selector.setter(member.memberName), member,
        new ArgumentsTypes([rhsType], null));
    return rhsType;
  }

  TypeInformation handlePropertyGet(ir.TreeNode node, ir.TreeNode receiver,
      TypeInformation receiverType, ir.Member interfaceTarget,
      {bool isThis}) {
    Selector selector = _elementMap.getSelector(node);
    AbstractValue mask = _typeOfReceiver(node, receiver);
    if (isThis) {
      _checkIfExposesThis(
          selector, _types.newTypedSelector(receiverType, mask));
    }
    TypeInformation type = handleDynamicGet(node, selector, mask, receiverType);
    if (interfaceTarget != null) {
      // Pull the type from kernel (instead of from the J-model) because the
      // interface target might be abstract and therefore not part of the
      // J-model.
      ir.DartType resultType = interfaceTarget.getterType;
      // The result type varies with the call site so we narrow the static
      // result type.
      if (containsFreeVariables(resultType)) {
        type = _types.narrowType(type, _getStaticType(node));
      }
    }
    return type;
  }

  @override
  TypeInformation visitPropertyGet(ir.PropertyGet node) {
    TypeInformation receiverType = visit(node.receiver);
    return handlePropertyGet(
        node, node.receiver, receiverType, node.interfaceTarget,
        isThis: node.receiver is ir.ThisExpression);
  }

  @override
  TypeInformation visitPropertySet(ir.PropertySet node) {
    TypeInformation receiverType = visit(node.receiver);
    Selector selector = _elementMap.getSelector(node);
    AbstractValue mask = _typeOfReceiver(node, node.receiver);

    TypeInformation rhsType = visit(node.value);
    if (node.value is ir.ThisExpression) {
      _state.markThisAsExposed();
    }

    if (_inGenerativeConstructor && node.receiver is ir.ThisExpression) {
      AbstractValue typedMask = _types.newTypedSelector(receiverType, mask);
      if (!_closedWorld.includesClosureCall(selector, typedMask)) {
        Iterable<MemberEntity> targets =
            _closedWorld.locateMembers(selector, typedMask);
        // We just recognized a field initialization of the form:
        // `this.foo = 42`. If there is only one target, we can update
        // its type.
        if (targets.length == 1) {
          MemberEntity single = targets.first;
          if (single.isField) {
            FieldEntity field = single;
            _state.updateField(field, rhsType);
          }
        }
      }
    }
    if (node.receiver is ir.ThisExpression) {
      _checkIfExposesThis(
          selector, _types.newTypedSelector(receiverType, mask));
    }
    handleDynamicSet(node, selector, mask, receiverType, rhsType);
    return rhsType;
  }

  @override
  TypeInformation visitThisExpression(ir.ThisExpression node) {
    return thisType;
  }

  TypeInformation handleCondition(ir.Node node) {
    bool oldAccumulateIsChecks = _accumulateIsChecks;
    _accumulateIsChecks = true;
    TypeInformation result = visit(node, conditionContext: true);
    _accumulateIsChecks = oldAccumulateIsChecks;
    return result;
  }

  void _potentiallyAddIsCheck(ir.IsExpression node) {
    if (!_accumulateIsChecks) return;
    ir.Expression operand = node.operand;
    if (operand is ir.VariableGet) {
      Local local = _localsMap.getLocalVariable(operand.variable);
      DartType localType = _elementMap.getDartType(node.type);
      LocalState stateAfterCheckWhenTrue = new LocalState.childPath(_state);
      LocalState stateAfterCheckWhenFalse = new LocalState.childPath(_state);

      // Narrow variable to tested type on true branch.
      TypeInformation currentTypeInformation = stateAfterCheckWhenTrue
          .readLocal(_inferrer, _capturedAndBoxed, local);
      stateAfterCheckWhenTrue.updateLocal(_inferrer, _capturedAndBoxed, local,
          currentTypeInformation, node, localType,
          isCast: false);
      _setStateAfter(_state, stateAfterCheckWhenTrue, stateAfterCheckWhenFalse);
    }
  }

  void _potentiallyAddNullCheck(
      ir.MethodInvocation node, ir.Expression receiver) {
    if (!_accumulateIsChecks) return;
    if (receiver is ir.VariableGet) {
      Local local = _localsMap.getLocalVariable(receiver.variable);
      DartType localType = _localsMap.getLocalType(_elementMap, local);
      LocalState stateAfterCheckWhenTrue = new LocalState.childPath(_state);
      LocalState stateAfterCheckWhenFalse = new LocalState.childPath(_state);

      // Narrow tested variable to 'Null' on true branch.
      stateAfterCheckWhenTrue.updateLocal(_inferrer, _capturedAndBoxed, local,
          _types.nullType, node, localType);

      // Narrow tested variable to 'not null' on false branch.
      TypeInformation currentTypeInformation = stateAfterCheckWhenFalse
          .readLocal(_inferrer, _capturedAndBoxed, local);
      stateAfterCheckWhenFalse.updateLocal(_inferrer, _capturedAndBoxed, local,
          currentTypeInformation, node, _closedWorld.commonElements.objectType,
          excludeNull: true);

      _setStateAfter(_state, stateAfterCheckWhenTrue, stateAfterCheckWhenFalse);
    }
  }

  @override
  TypeInformation visitIfStatement(ir.IfStatement node) {
    LocalState stateBefore = _state;
    handleCondition(node.condition);
    LocalState stateAfterConditionWhenTrue = _stateAfterWhenTrue;
    LocalState stateAfterConditionWhenFalse = _stateAfterWhenFalse;
    _state = new LocalState.childPath(stateAfterConditionWhenTrue);
    visit(node.then);
    LocalState stateAfterThen = _state;
    _state = new LocalState.childPath(stateAfterConditionWhenFalse);
    visit(node.otherwise);
    LocalState stateAfterElse = _state;
    _state =
        stateBefore.mergeDiamondFlow(_inferrer, stateAfterThen, stateAfterElse);
    return null;
  }

  @override
  TypeInformation visitIsExpression(ir.IsExpression node) {
    visit(node.operand);
    _potentiallyAddIsCheck(node);
    return _types.boolType;
  }

  @override
  TypeInformation visitNot(ir.Not node) {
    visit(node.operand, conditionContext: _accumulateIsChecks);
    LocalState stateAfterOperandWhenTrue = _stateAfterWhenTrue;
    LocalState stateAfterOperandWhenFalse = _stateAfterWhenFalse;
    _setStateAfter(
        _state, stateAfterOperandWhenFalse, stateAfterOperandWhenTrue);
    // TODO(sra): Improve precision on constant and bool-conversion-to-constant
    // inputs.
    return _types.boolType;
  }

  @override
  TypeInformation visitLogicalExpression(ir.LogicalExpression node) {
    if (node.operatorEnum == ir.LogicalExpressionOperator.AND) {
      LocalState stateBefore = _state;
      _state = new LocalState.childPath(stateBefore);
      TypeInformation leftInfo = handleCondition(node.left);
      LocalState stateAfterLeftWhenTrue = _stateAfterWhenTrue;
      LocalState stateAfterLeftWhenFalse = _stateAfterWhenFalse;
      _state = new LocalState.childPath(stateAfterLeftWhenTrue);
      TypeInformation rightInfo = handleCondition(node.right);
      LocalState stateAfterRightWhenTrue = _stateAfterWhenTrue;
      LocalState stateAfterRightWhenFalse = _stateAfterWhenFalse;
      LocalState stateAfterWhenTrue = stateAfterRightWhenTrue;
      LocalState stateAfterWhenFalse = new LocalState.childPath(stateBefore)
          .mergeDiamondFlow(
              _inferrer, stateAfterLeftWhenFalse, stateAfterRightWhenFalse);
      LocalState after = stateBefore.mergeDiamondFlow(
          _inferrer, stateAfterWhenTrue, stateAfterWhenFalse);
      _setStateAfter(after, stateAfterWhenTrue, stateAfterWhenFalse);
      // Constant-fold result.
      if (_types.isLiteralFalse(leftInfo)) return leftInfo;
      if (_types.isLiteralTrue(leftInfo)) {
        if (_types.isLiteralFalse(rightInfo)) return rightInfo;
        if (_types.isLiteralTrue(rightInfo)) return rightInfo;
      }
      // TODO(sra): Add a selector/mux node to improve precision.
      return _types.boolType;
    } else if (node.operatorEnum == ir.LogicalExpressionOperator.OR) {
      LocalState stateBefore = _state;
      _state = new LocalState.childPath(stateBefore);
      TypeInformation leftInfo = handleCondition(node.left);
      LocalState stateAfterLeftWhenTrue = _stateAfterWhenTrue;
      LocalState stateAfterLeftWhenFalse = _stateAfterWhenFalse;
      _state = new LocalState.childPath(stateAfterLeftWhenFalse);
      TypeInformation rightInfo = handleCondition(node.right);
      LocalState stateAfterRightWhenTrue = _stateAfterWhenTrue;
      LocalState stateAfterRightWhenFalse = _stateAfterWhenFalse;
      LocalState stateAfterWhenTrue = new LocalState.childPath(stateBefore)
          .mergeDiamondFlow(
              _inferrer, stateAfterLeftWhenTrue, stateAfterRightWhenTrue);
      LocalState stateAfterWhenFalse = stateAfterRightWhenFalse;
      LocalState stateAfter = stateBefore.mergeDiamondFlow(
          _inferrer, stateAfterWhenTrue, stateAfterWhenFalse);
      _setStateAfter(stateAfter, stateAfterWhenTrue, stateAfterWhenFalse);
      // Constant-fold result.
      if (_types.isLiteralTrue(leftInfo)) return leftInfo;
      if (_types.isLiteralFalse(leftInfo)) {
        if (_types.isLiteralTrue(rightInfo)) return rightInfo;
        if (_types.isLiteralFalse(rightInfo)) return rightInfo;
      }
      // TODO(sra): Add a selector/mux node to improve precision.
      return _types.boolType;
    }
    failedAt(CURRENT_ELEMENT_SPANNABLE,
        "Unexpected logical operator '${node.operatorEnum}'.");
    return null;
  }

  @override
  TypeInformation visitConditionalExpression(ir.ConditionalExpression node) {
    LocalState stateBefore = _state;
    handleCondition(node.condition);
    LocalState stateAfterWhenTrue = _stateAfterWhenTrue;
    LocalState stateAfterWhenFalse = _stateAfterWhenFalse;
    _state = new LocalState.childPath(stateAfterWhenTrue);
    TypeInformation firstType = visit(node.then);
    LocalState stateAfterThen = _state;
    _state = new LocalState.childPath(stateAfterWhenFalse);
    TypeInformation secondType = visit(node.otherwise);
    LocalState stateAfterElse = _state;
    _state =
        stateBefore.mergeDiamondFlow(_inferrer, stateAfterThen, stateAfterElse);
    return _types.allocateDiamondPhi(firstType, secondType);
  }

  TypeInformation handleLocalFunction(
      ir.TreeNode node, ir.FunctionNode functionNode,
      [ir.VariableDeclaration variable]) {
    // We loose track of [this] in closures (see issue 20840). To be on
    // the safe side, we mark [this] as exposed here. We could do better by
    // analyzing the closure.
    // TODO(herhut): Analyze whether closure exposes this. Possibly using
    // whether the created closure as a `thisLocal`.
    _state.markThisAsExposed();

    ClosureRepresentationInfo info = _closureDataLookup.getClosureInfo(node);

    // Record the types of captured non-boxed variables. Types of
    // these variables may already be there, because of an analysis of
    // a previous closure.
    info.forEachFreeVariable((Local variable, FieldEntity field) {
      if (!info.isBoxedVariable(variable)) {
        if (variable == info.thisLocal) {
          _inferrer.recordTypeOfField(field, thisType);
        }
        TypeInformation localType =
            _state.readLocal(_inferrer, _capturedAndBoxed, variable);
        // The type is null for type parameters.
        if (localType != null) {
          _inferrer.recordTypeOfField(field, localType);
        }
      }
      _capturedVariables.add(variable);
    });

    TypeInformation localFunctionType =
        _inferrer.concreteTypes.putIfAbsent(node, () {
      return _types.allocateClosure(info.callMethod);
    });
    if (variable != null) {
      Local local = _localsMap.getLocalVariable(variable);
      DartType type = _localsMap.getLocalType(_elementMap, local);
      _state.updateLocal(
          _inferrer, _capturedAndBoxed, local, localFunctionType, node, type,
          excludeNull: true);
    }

    // We don't put the closure in the work queue of the
    // inferrer, because it will share information with its enclosing
    // method, like for example the types of local variables.
    LocalState closureState = new LocalState.closure(_state);
    KernelTypeGraphBuilder visitor = new KernelTypeGraphBuilder(
        _options,
        _closedWorld,
        _inferrer,
        info.callMethod,
        functionNode,
        _localsMap,
        _staticTypeProvider,
        closureState,
        _capturedAndBoxed);
    visitor.run();
    _inferrer.recordReturnType(info.callMethod, visitor._returnType);

    return localFunctionType;
  }

  @override
  TypeInformation visitFunctionDeclaration(ir.FunctionDeclaration node) {
    return handleLocalFunction(node, node.function, node.variable);
  }

  @override
  TypeInformation visitFunctionExpression(ir.FunctionExpression node) {
    return handleLocalFunction(node, node.function);
  }

  @override
  visitWhileStatement(ir.WhileStatement node) {
    return handleLoop(node, _localsMap.getJumpTargetForWhile(node), () {
      handleCondition(node.condition);
      _state = new LocalState.childPath(_stateAfterWhenTrue);
      visit(node.body);
    });
  }

  @override
  visitDoStatement(ir.DoStatement node) {
    return handleLoop(node, _localsMap.getJumpTargetForDo(node), () {
      visit(node.body);
      handleCondition(node.condition);
      // TODO(29309): This condition appears to strengthen both the back-edge
      // and exit-edge. For now, avoid strengthening on the condition until the
      // proper fix is found.
      //
      //     _state = new LocalState.childPath(_stateAfterWhenTrue, node.body);
    });
  }

  @override
  visitForStatement(ir.ForStatement node) {
    for (ir.VariableDeclaration variable in node.variables) {
      visit(variable);
    }
    return handleLoop(node, _localsMap.getJumpTargetForFor(node), () {
      handleCondition(node.condition);
      _state = new LocalState.childPath(_stateAfterWhenTrue);
      visit(node.body);
      for (ir.Expression update in node.updates) {
        visit(update);
      }
    });
  }

  @override
  visitTryCatch(ir.TryCatch node) {
    LocalState stateBefore = _state;
    _state = new LocalState.tryBlock(stateBefore, node);
    _state.markInitializationAsIndefinite();
    visit(node.body);
    LocalState stateAfterBody = _state;
    _state = stateBefore.mergeFlow(_inferrer, stateAfterBody);
    for (ir.Catch catchBlock in node.catches) {
      LocalState stateBeforeCatch = _state;
      _state = new LocalState.childPath(stateBeforeCatch);
      visit(catchBlock);
      LocalState stateAfterCatch = _state;
      _state = stateBeforeCatch.mergeFlow(_inferrer, stateAfterCatch);
    }
    return null;
  }

  @override
  visitTryFinally(ir.TryFinally node) {
    LocalState stateBefore = _state;
    _state = new LocalState.tryBlock(stateBefore, node);
    _state.markInitializationAsIndefinite();
    visit(node.body);
    LocalState stateAfterBody = _state;
    _state = stateBefore.mergeFlow(_inferrer, stateAfterBody);
    visit(node.finalizer);
    return null;
  }

  @override
  visitCatch(ir.Catch node) {
    ir.VariableDeclaration exception = node.exception;
    if (exception != null) {
      TypeInformation mask;
      DartType type = node.guard != null
          ? _elementMap.getDartType(node.guard).withoutNullability
          : _dartTypes.dynamicType();
      if (type is InterfaceType) {
        InterfaceType interfaceType = type;
        mask = _types.nonNullSubtype(interfaceType.element);
      } else {
        mask = _types.dynamicType;
      }
      Local local = _localsMap.getLocalVariable(exception);
      _state.updateLocal(_inferrer, _capturedAndBoxed, local, mask, node,
          _dartTypes.dynamicType(),
          excludeNull: true /* `throw null` produces a NullThrownError */);
    }
    ir.VariableDeclaration stackTrace = node.stackTrace;
    if (stackTrace != null) {
      Local local = _localsMap.getLocalVariable(stackTrace);
      // TODO(johnniwinther): Use a mask based on [StackTrace].
      // Note: stack trace may be null if users omit a stack in
      // `completer.completeError`.
      _state.updateLocal(_inferrer, _capturedAndBoxed, local,
          _types.dynamicType, node, _dartTypes.dynamicType());
    }
    visit(node.body);
    return null;
  }

  @override
  TypeInformation visitThrow(ir.Throw node) {
    visit(node.expression);
    _state.seenReturnOrThrow = true;
    return _types.nonNullEmpty();
  }

  @override
  TypeInformation visitRethrow(ir.Rethrow node) {
    _state.seenReturnOrThrow = true;
    return _types.nonNullEmpty();
  }

  TypeInformation handleSuperNoSuchMethod(
      ir.Node node, Selector selector, ArgumentsTypes arguments) {
    // Ensure we create a node, to make explicit the call to the
    // `noSuchMethod` handler.
    FunctionEntity noSuchMethod =
        _elementMap.getSuperNoSuchMethod(_analyzedMember.enclosingClass);
    return handleStaticInvoke(node, selector, noSuchMethod, arguments);
  }

  @override
  TypeInformation visitSuperPropertyGet(ir.SuperPropertyGet node) {
    // TODO(herhut): We could do better here if we knew what we
    // are calling does not expose this.
    _state.markThisAsExposed();

    MemberEntity member =
        _elementMap.getSuperMember(_analyzedMember, node.name);
    assert(member != null, "No member found for super property get: $node");
    Selector selector = new Selector.getter(_elementMap.getName(node.name));
    TypeInformation type = handleStaticInvoke(node, selector, member, null);
    if (member.isGetter) {
      FunctionType functionType =
          _elementMap.elementEnvironment.getFunctionType(member);
      if (functionType.returnType.containsFreeTypeVariables) {
        // The result type varies with the call site so we narrow the static
        // result type.
        type = _types.narrowType(type, _getStaticType(node));
      }
    } else if (member.isField) {
      DartType fieldType = _elementMap.elementEnvironment.getFieldType(member);
      if (fieldType.containsFreeTypeVariables) {
        // The result type varies with the call site so we narrow the static
        // result type.
        type = _types.narrowType(type, _getStaticType(node));
      }
    }
    return type;
  }

  @override
  TypeInformation visitSuperPropertySet(ir.SuperPropertySet node) {
    // TODO(herhut): We could do better here if we knew what we
    // are calling does not expose this.
    _state.markThisAsExposed();

    TypeInformation rhsType = visit(node.value);
    MemberEntity member =
        _elementMap.getSuperMember(_analyzedMember, node.name, setter: true);
    assert(member != null, "No member found for super property set: $node");
    Selector selector = new Selector.setter(_elementMap.getName(node.name));
    ArgumentsTypes arguments = new ArgumentsTypes([rhsType], null);
    handleStaticInvoke(node, selector, member, arguments);
    return rhsType;
  }

  @override
  TypeInformation visitSuperMethodInvocation(ir.SuperMethodInvocation node) {
    // TODO(herhut): We could do better here if we knew what we
    // are calling does not expose this.
    _state.markThisAsExposed();

    MemberEntity member =
        _elementMap.getSuperMember(_analyzedMember, node.name);
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    Selector selector = _elementMap.getSelector(node);
    if (member == null) {
      // TODO(johnniwinther): This shouldn't be necessary.
      return handleSuperNoSuchMethod(node, selector, arguments);
    } else {
      assert(member.isFunction, "Unexpected super invocation target: $member");
      if (isIncompatibleInvoke(member, arguments)) {
        return handleSuperNoSuchMethod(node, selector, arguments);
      } else {
        TypeInformation type =
            handleStaticInvoke(node, selector, member, arguments);
        FunctionType functionType =
            _elementMap.elementEnvironment.getFunctionType(member);
        if (functionType.returnType.containsFreeTypeVariables) {
          // The return type varies with the call site so we narrow the static
          // return type.
          type = _types.narrowType(type, _getStaticType(node));
        }
        return type;
      }
    }
  }

  @override
  TypeInformation visitAsExpression(ir.AsExpression node) {
    TypeInformation operandType = visit(node.operand);
    return _types.narrowType(operandType, _elementMap.getDartType(node.type));
  }

  @override
  TypeInformation visitNullCheck(ir.NullCheck node) {
    TypeInformation operandType = visit(node.operand);
    return _types.narrowType(operandType, _getStaticType(node));
  }

  @override
  TypeInformation visitAwaitExpression(ir.AwaitExpression node) {
    TypeInformation futureType = visit(node.operand);
    return _inferrer.registerAwait(node, futureType);
  }

  @override
  TypeInformation visitYieldStatement(ir.YieldStatement node) {
    TypeInformation operandType = visit(node.expression);
    return _inferrer.registerYield(node, operandType);
  }

  @override
  TypeInformation visitCheckLibraryIsLoaded(ir.CheckLibraryIsLoaded node) {
    return _types.nonNullEmpty();
  }

  @override
  TypeInformation visitInvalidExpression(ir.InvalidExpression node) {
    // TODO(johnniwinther): Maybe this should be [empty] instead?
    return _types.dynamicType;
  }

  @override
  TypeInformation visitConstantExpression(ir.ConstantExpression node) {
    return new TypeInformationConstantVisitor(this, node)
        .visitConstant(node.constant);
  }
}

class TypeInformationConstantVisitor
    extends ir.ComputeOnceConstantVisitor<TypeInformation> {
  final KernelTypeGraphBuilder builder;
  final ir.ConstantExpression expression;

  TypeInformationConstantVisitor(this.builder, this.expression);

  @override
  TypeInformation defaultConstant(ir.Constant node) {
    throw new UnsupportedError("Unexpected constant: "
        "${node} (${node.runtimeType})");
  }

  @override
  TypeInformation visitNullConstant(ir.NullConstant node) {
    return builder.createNullTypeInformation();
  }

  @override
  TypeInformation visitBoolConstant(ir.BoolConstant node) {
    return builder.createBoolTypeInformation(node.value);
  }

  @override
  TypeInformation visitIntConstant(ir.IntConstant node) {
    return builder.createIntTypeInformation(node.value);
  }

  @override
  TypeInformation visitDoubleConstant(ir.DoubleConstant node) {
    return builder.createDoubleTypeInformation(node.value);
  }

  @override
  TypeInformation visitStringConstant(ir.StringConstant node) {
    return builder.createStringTypeInformation(node.value);
  }

  @override
  TypeInformation visitSymbolConstant(ir.SymbolConstant node) {
    return builder.createSymbolLiteralTypeInformation();
  }

  @override
  TypeInformation visitMapConstant(ir.MapConstant node) {
    return builder.createMapTypeInformation(
        new ConstantReference(expression, node),
        node.entries
            .map((e) => new Pair(visitConstant(e.key), visitConstant(e.value))),
        isConst: true);
  }

  @override
  TypeInformation visitListConstant(ir.ListConstant node) {
    return builder.createListTypeInformation(
        new ConstantReference(expression, node),
        node.entries.map((e) => visitConstant(e)),
        isConst: true);
  }

  @override
  TypeInformation visitSetConstant(ir.SetConstant node) {
    return builder.createSetTypeInformation(
        new ConstantReference(expression, node),
        node.entries.map((e) => visitConstant(e)),
        isConst: true);
  }

  @override
  TypeInformation visitInstanceConstant(ir.InstanceConstant node) {
    node.fieldValues.forEach((ir.Reference reference, ir.Constant value) {
      builder._inferrer.recordTypeOfField(
          builder._elementMap.getField(reference.asField),
          visitConstant(value));
    });
    return builder._types.getConcreteTypeFor(builder
        ._closedWorld.abstractValueDomain
        .createNonNullExact(builder._elementMap.getClass(node.classNode)));
  }

  @override
  TypeInformation visitPartialInstantiationConstant(
      ir.PartialInstantiationConstant node) {
    return builder.createInstantiationTypeInformation(
        visitConstant(node.tearOffConstant));
  }

  @override
  TypeInformation visitTearOffConstant(ir.TearOffConstant node) {
    return builder.createStaticGetTypeInformation(node, node.procedure);
  }

  @override
  TypeInformation visitTypeLiteralConstant(ir.TypeLiteralConstant node) {
    return builder.createTypeLiteralInformation();
  }

  @override
  TypeInformation visitUnevaluatedConstant(ir.UnevaluatedConstant node) {
    assert(false, "Unexpected unevaluated constant: $node");
    return builder._types.dynamicType;
  }
}

class Refinement {
  final Selector selector;
  final AbstractValue mask;

  Refinement(this.selector, this.mask);
}

class LocalState {
  final LocalsHandler _locals;
  final FieldInitializationScope _fields;
  bool seenReturnOrThrow = false;
  bool seenBreakOrContinue = false;
  LocalsHandler _tryBlock;

  LocalState.initial({bool inGenerativeConstructor})
      : this.internal(
            new LocalsHandler(),
            inGenerativeConstructor ? new FieldInitializationScope() : null,
            null,
            seenReturnOrThrow: false,
            seenBreakOrContinue: false);

  LocalState.childPath(LocalState other)
      : this.internal(new LocalsHandler.from(other._locals),
            new FieldInitializationScope.from(other._fields), other._tryBlock,
            seenReturnOrThrow: false, seenBreakOrContinue: false);

  LocalState.closure(LocalState other)
      : this.internal(new LocalsHandler.from(other._locals),
            new FieldInitializationScope.from(other._fields), null,
            seenReturnOrThrow: false, seenBreakOrContinue: false);

  factory LocalState.tryBlock(LocalState other, ir.TreeNode node) {
    LocalsHandler locals = new LocalsHandler.tryBlock(other._locals, node);
    FieldInitializationScope fieldScope =
        new FieldInitializationScope.from(other._fields);
    LocalsHandler tryBlock = locals;
    return new LocalState.internal(locals, fieldScope, tryBlock,
        seenReturnOrThrow: false, seenBreakOrContinue: false);
  }

  LocalState.deepCopyOf(LocalState other)
      : _locals = new LocalsHandler.deepCopyOf(other._locals),
        _tryBlock = other._tryBlock,
        _fields = other._fields;

  LocalState.internal(this._locals, this._fields, this._tryBlock,
      {this.seenReturnOrThrow, this.seenBreakOrContinue});

  bool get aborts {
    return seenReturnOrThrow || seenBreakOrContinue;
  }

  bool get isThisExposed {
    return _fields == null || _fields.isThisExposed;
  }

  void markThisAsExposed() {
    _fields?.isThisExposed = true;
  }

  void markInitializationAsIndefinite() {
    _fields?.isIndefinite = true;
  }

  TypeInformation readField(FieldEntity field) {
    return _fields.readField(field);
  }

  void updateField(FieldEntity field, TypeInformation type) {
    _fields.updateField(field, type);
  }

  TypeInformation readLocal(InferrerEngine inferrer,
      Map<Local, FieldEntity> capturedAndBoxed, Local local) {
    FieldEntity field = capturedAndBoxed[local];
    if (field != null) {
      return inferrer.typeOfMember(field);
    } else {
      return _locals.use(inferrer, local);
    }
  }

  void updateLocal(
      InferrerEngine inferrer,
      Map<Local, FieldEntity> capturedAndBoxed,
      Local local,
      TypeInformation type,
      ir.Node node,
      DartType staticType,
      {isCast: true,
      excludeNull: false}) {
    assert(type != null);
    type = inferrer.types
        .narrowType(type, staticType, isCast: isCast, excludeNull: excludeNull);

    FieldEntity field = capturedAndBoxed[local];
    if (field != null) {
      inferrer.recordTypeOfField(field, type);
    } else {
      _locals.update(inferrer, local, type, node, staticType, _tryBlock);
    }
  }

  LocalState mergeFlow(InferrerEngine inferrer, LocalState other) {
    seenReturnOrThrow = false;
    seenBreakOrContinue = false;

    if (other.aborts) {
      return this;
    }
    LocalsHandler locals = _locals.mergeFlow(inferrer, other._locals);
    return new LocalState.internal(locals, _fields, _tryBlock,
        seenReturnOrThrow: seenReturnOrThrow,
        seenBreakOrContinue: seenBreakOrContinue);
  }

  LocalState mergeDiamondFlow(
      InferrerEngine inferrer, LocalState thenBranch, LocalState elseBranch) {
    seenReturnOrThrow =
        thenBranch.seenReturnOrThrow && elseBranch.seenReturnOrThrow;
    seenBreakOrContinue =
        thenBranch.seenBreakOrContinue && elseBranch.seenBreakOrContinue;

    LocalsHandler locals;
    if (aborts) {
      locals = _locals;
    } else if (thenBranch.aborts) {
      locals = _locals.mergeFlow(inferrer, elseBranch._locals, inPlace: true);
    } else if (elseBranch.aborts) {
      locals = _locals.mergeFlow(inferrer, thenBranch._locals, inPlace: true);
    } else {
      locals = _locals.mergeDiamondFlow(
          inferrer, thenBranch._locals, elseBranch._locals);
    }

    FieldInitializationScope fieldScope = _fields?.mergeDiamondFlow(
        inferrer, thenBranch._fields, elseBranch._fields);
    return new LocalState.internal(locals, fieldScope, _tryBlock,
        seenReturnOrThrow: seenReturnOrThrow,
        seenBreakOrContinue: seenBreakOrContinue);
  }

  LocalState mergeAfterBreaks(InferrerEngine inferrer, List<LocalState> states,
      {bool keepOwnLocals: true}) {
    bool allBranchesAbort = true;
    for (LocalState state in states) {
      allBranchesAbort = allBranchesAbort && state.seenReturnOrThrow;
    }

    keepOwnLocals = keepOwnLocals && !seenReturnOrThrow;

    LocalsHandler locals = _locals.mergeAfterBreaks(
        inferrer,
        states
            .where((LocalState state) => !state.seenReturnOrThrow)
            .map((LocalState state) => state._locals),
        keepOwnLocals: keepOwnLocals);
    seenReturnOrThrow = allBranchesAbort && !keepOwnLocals;
    return new LocalState.internal(locals, _fields, _tryBlock,
        seenReturnOrThrow: seenReturnOrThrow,
        seenBreakOrContinue: seenBreakOrContinue);
  }

  bool mergeAll(InferrerEngine inferrer, List<LocalState> states) {
    assert(!seenReturnOrThrow);
    return _locals.mergeAll(
        inferrer,
        states
            .where((LocalState state) => !state.seenReturnOrThrow)
            .map((LocalState state) => state._locals));
  }

  void startLoop(InferrerEngine inferrer, ir.Node loop) {
    _locals.startLoop(inferrer, loop);
  }

  void endLoop(InferrerEngine inferrer, ir.Node loop) {
    _locals.endLoop(inferrer, loop);
  }

  String toStructuredText(String indent) {
    StringBuffer sb = new StringBuffer();
    _toStructuredText(sb, indent);
    return sb.toString();
  }

  void _toStructuredText(StringBuffer sb, String indent) {
    sb.write('LocalState($hashCode) [');
    sb.write('\n${indent}  locals:');
    sb.write(_locals.toStructuredText('${indent}    '));
    sb.write('\n]');
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('LocalState(');
    sb.write('locals=$_locals');
    if (_fields != null) {
      sb.write(',fields=$_fields');
    }
    if (seenReturnOrThrow) {
      sb.write(',seenReturnOrThrow');
    }
    if (seenBreakOrContinue) {
      sb.write(',seenBreakOrContinue');
    }
    sb.write(')');
    return sb.toString();
  }
}
