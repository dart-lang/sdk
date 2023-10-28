// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import 'package:front_end/src/api_prototype/static_weak_references.dart' as ir
    show StaticWeakReferences;

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
import '../js_model/elements.dart';
import '../js_model/locals.dart' show JumpVisitor;
import '../js_model/js_world.dart';
import '../native/behavior.dart';
import '../options.dart';
import '../universe/member_hierarchy.dart';
import '../universe/record_shape.dart';
import '../universe/selector.dart';
import '../universe/side_effects.dart';
import '../util/util.dart';
import 'engine.dart';
import 'locals_handler.dart';
import 'type_graph_nodes.dart';
import 'type_system.dart';

/// [KernelTypeGraphBuilder] constructs a type-inference graph for a particular
/// element.
///
/// Calling [run] will start the work of visiting the body of the code to
/// construct a set of inference-nodes that abstractly represent what the code
/// is doing.
class KernelTypeGraphBuilder extends ir.VisitorDefault<TypeInformation?>
    with ir.VisitorNullMixin<TypeInformation> {
  final CompilerOptions _options;
  final JClosedWorld _closedWorld;
  final InferrerEngine _inferrer;
  final TypeSystem _types;
  final MemberEntity _analyzedMember;
  final ir.Node? _analyzedNode;
  final KernelToLocalsMap _localsMap;
  final GlobalTypeInferenceElementData _memberData;
  final MemberHierarchyBuilder _memberHierarchyBuilder;
  final bool _inGenerativeConstructor;

  DartTypes get _dartTypes => _closedWorld.dartTypes;

  LocalState _stateInternal;
  LocalState? _stateAfterWhenTrueInternal;
  LocalState? _stateAfterWhenFalseInternal;

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

  /// Removes from the current [_state] any data from the boolean value of the
  /// most recently visited node.
  void _clearConditionalStateAfter() {
    _stateAfterWhenTrueInternal = _stateAfterWhenFalseInternal = null;
  }

  final SideEffectsBuilder _sideEffectsBuilder;
  final Map<JumpTarget, List<LocalState>> _breaksFor =
      <JumpTarget, List<LocalState>>{};
  final Map<JumpTarget, List<LocalState>> _continuesFor =
      <JumpTarget, List<LocalState>>{};
  TypeInformation? _returnType;
  final Set<Local> _capturedVariables = Set<Local>();
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
      this._memberHierarchyBuilder,
      [LocalState? previousState,
      Map<Local, FieldEntity>? capturedAndBoxed])
      : this._types = _inferrer.types,
        this._memberData = _inferrer.dataOfMember(_analyzedMember),
        // TODO(johnniwinther): Should side effects also be tracked for field
        // initializers?
        this._sideEffectsBuilder = _analyzedMember is FunctionEntity
            ? _inferrer.inferredDataBuilder
                .getSideEffectsBuilder(_analyzedMember)
            : SideEffectsBuilder.free(_analyzedMember),
        this._inGenerativeConstructor = _analyzedNode is ir.Constructor,
        this._capturedAndBoxed = capturedAndBoxed != null
            ? Map<Local, FieldEntity>.from(capturedAndBoxed)
            : <Local, FieldEntity>{},
        _stateInternal = previousState ??
            LocalState.initial(
                inGenerativeConstructor: _analyzedNode is ir.Constructor);

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
    final cls = _elementMap.getMemberThisType(_analyzedMember)?.element;
    if (cls == null) return false;
    return _closedWorld.classHierarchy
        .isSubclassOf(member.enclosingClass!, cls);
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
  void _checkIfExposesThis(Selector selector, AbstractValue? mask) {
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
        if (element is FieldEntity) {
          final field = element;
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
    if (_analyzedMember is FieldEntity) {
      if (_analyzedNode == null ||
          isNullLiteral(_analyzedNode as ir.Expression)) {
        // Eagerly bailout, because computing the closure data only
        // works for functions and field assignments.
        return _types.nullType;
      }
    }

    // Update the locals that are boxed in [locals]. These locals will
    // be handled specially, in that we are computing their LUB at
    // each update, and reading them yields the type that was found in a
    // previous analysis of [outermostElement].
    if (!_analyzedMember.isAbstract) {
      ScopeInfo scopeInfo = _closureDataLookup.getScopeInfo(_analyzedMember);
      scopeInfo.forEachBoxedVariable(_localsMap, (variable, field) {
        _capturedAndBoxed[variable] = field;
      });
    }

    return visit(_analyzedNode)!;
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
    final analyzedMethod = _analyzedMember as FunctionEntity;
    _returnType = _inferrer.addReturnTypeForMethod(analyzedMethod, type);
  }

  late final TypeInformation thisType = () {
    final cls = _elementMap.getMemberThisType(_analyzedMember)!.element;
    if (_closedWorld.isUsedAsMixin(cls)) {
      return _types.nonNullSubtype(cls);
    } else {
      return _types.nonNullSubclass(cls);
    }
  }();

  TypeInformation? visit(ir.Node? node, {bool conditionContext = false}) {
    var oldAccumulateIsChecks = _accumulateIsChecks;
    _accumulateIsChecks = conditionContext;
    var result = node?.accept(this);

    // Clear the conditional state to ensure we don't accidentally carry over
    // conclusions from a nested condition into an outer condition. For example:
    //
    //   if (methodCall(x is T && true)) { /* don't assume x is T here. */ }
    if (!conditionContext) _clearConditionalStateAfter();
    _accumulateIsChecks = oldAccumulateIsChecks;
    return result;
  }

  void handleParameter(ir.VariableDeclaration node,
      {required bool isOptional}) {
    Local local = _localsMap.getLocalVariable(node);
    _state.setLocal(
        _inferrer, _capturedAndBoxed, local, _inferrer.typeOfParameter(local));
    if (isOptional) {
      TypeInformation type;
      if (node.initializer != null) {
        type = visit(node.initializer)!;
      } else {
        type = _types.nullType;
      }
      _inferrer.setDefaultTypeOfParameter(local, type);
    }
  }

  @override
  TypeInformation visitConstructor(ir.Constructor node) {
    handleParameters(node.function);
    node.initializers.forEach(visit);
    visit(node.function.body);

    final cls = _analyzedMember.enclosingClass!;
    if (!(node.initializers.isNotEmpty &&
        node.initializers.first is ir.RedirectingInitializer)) {
      // Iterate over all instance fields, and give a null type to
      // fields that we haven't initialized for sure.
      _elementMap.elementEnvironment.forEachLocalClassMember(cls,
          (MemberEntity member) {
        if (member is FieldEntity &&
            member.isInstanceMember &&
            member.isAssignable) {
          final type = _state.readField(member);
          MemberDefinition definition = _elementMap.getMemberDefinition(member);
          assert(definition.kind == MemberKind.regular);
          final node = definition.node as ir.Field;
          final initializer = node.initializer;
          if (type == null &&
              (initializer == null || isNullLiteral(initializer))) {
            _inferrer.recordTypeOfField(member, _types.nullType);
          }
        }
      });
    }
    _inferrer.recordExposesThis(
        _analyzedMember as ConstructorEntity, _state.isThisExposed);

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
    return _returnType!;
  }

  @override
  visitFieldInitializer(ir.FieldInitializer node) {
    final rhsType = visit(node.value)!;
    FieldEntity field = _elementMap.getField(node.field);
    _state.updateField(field, rhsType);
    _inferrer.recordTypeOfField(field, rhsType);
    return null;
  }

  @override
  visitSuperInitializer(ir.SuperInitializer node) {
    ConstructorEntity constructor = _elementMap.getConstructor(node.target);
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    Selector selector = Selector(SelectorKind.CALL, constructor.memberName,
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
    Selector selector = Selector(SelectorKind.CALL, constructor.memberName,
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
      NativeBehavior nativeBehavior = _closedWorld.nativeData
          .getNativeMethodBehavior(_analyzedMember as FunctionEntity);
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
    }
    assert(_breaksFor.isEmpty);
    assert(_continuesFor.isEmpty);
    return _returnType!;
  }

  @override
  TypeInformation visitInstantiation(ir.Instantiation node) {
    return createInstantiationTypeInformation(visit(node.expression)!);
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
    throw UnimplementedError(
        'Unhandled expression: ${node} (${node.runtimeType})');
  }

  @override
  defaultStatement(ir.Statement node) {
    throw UnimplementedError(
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

  void _handleAssertStatement(ir.AssertStatement node) {
    // Avoid pollution from assert statement unless enabled.
    if (!_options.enableUserAssertions) {
      return;
    }
    // TODO(johnniwinther): Should assert be used with --trust-type-annotations?
    // TODO(johnniwinther): Track reachable for assertions known to fail.
    final stateBefore = _state;
    handleCondition(node.condition);
    final afterConditionWhenTrue = _stateAfterWhenTrue;
    final afterConditionWhenFalse = _stateAfterWhenFalse;
    _state = LocalState.childPath(afterConditionWhenFalse);
    visit(node.message);
    final stateAfterMessage = _state;
    stateAfterMessage.seenReturnOrThrow = true;
    _state = stateBefore.mergeDiamondFlow(
        _inferrer, afterConditionWhenTrue, stateAfterMessage);
  }

  @override
  visitAssertInitializer(ir.AssertInitializer node) {
    _handleAssertStatement(node.statement);
    return null;
  }

  @override
  visitAssertStatement(ir.AssertStatement node) {
    _handleAssertStatement(node);
    return null;
  }

  @override
  visitBreakStatement(ir.BreakStatement node) {
    JumpTarget target = _localsMap.getJumpTargetForBreak(node);
    _state.seenBreakOrContinue = true;
    // Do a deep-copy of the locals, because the code following the
    // break will change them.
    if (_localsMap.generateContinueForBreak(node)) {
      _continuesFor[target]!.add(LocalState.deepCopyOf(_state));
    } else {
      _breaksFor[target]!.add(LocalState.deepCopyOf(_state));
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
      final stateBefore = _state;
      final jumpTarget = _localsMap.getJumpTargetForLabel(node);
      _setupBreaksAndContinues(jumpTarget);
      _state = LocalState.childPath(stateBefore);
      visit(body);
      _state = stateBefore.mergeAfterBreaks(_inferrer, _getBreaks(jumpTarget),
          keepOwnLocals: false);
      _clearBreaksAndContinues(jumpTarget);
    }
    return null;
  }

  @override
  visitSwitchStatement(ir.SwitchStatement node) {
    visit(node.expression);

    final jumpTarget = _localsMap.getJumpTargetForSwitch(node);
    _setupBreaksAndContinues(jumpTarget);

    List<JumpTarget> continueTargets = <JumpTarget>[];
    bool hasDefaultCase = false;
    for (ir.SwitchCase switchCase in node.cases) {
      final continueTarget = _localsMap.getJumpTargetForSwitchCase(switchCase);
      if (continueTarget != null) {
        continueTargets.add(continueTarget);
      }
      if (switchCase.isDefault) {
        hasDefaultCase = true;
      }
    }
    final stateBefore = _state;
    if (continueTargets.isNotEmpty) {
      continueTargets.forEach(_setupBreaksAndContinues);

      // If the switch statement has a continue, we conservatively
      // visit all cases and update [locals] until we have reached a
      // fixed point.
      bool changed;
      stateBefore.startLoop(_inferrer, node);
      do {
        changed = false;
        // We first visit every case and collect the updated continue states.
        // We must do a full pass as the jumps may be to earlier cases.
        _visitCasesForSwitch(node, stateBefore);

        // We then pass back over the cases and update the state of any continue
        // targets with the states we collected in the last pass.
        for (ir.SwitchCase switchCase in node.cases) {
          final continueTarget =
              _localsMap.getJumpTargetForSwitchCase(switchCase);
          if (continueTarget != null) {
            changed |= stateBefore.mergeAll(
                _inferrer, _getLoopBackEdges(continueTarget));
          }
        }
      } while (changed);
      stateBefore.endLoop(_inferrer, node);

      continueTargets.forEach(_clearBreaksAndContinues);
    } else {
      // Gather the termination states of each case by visiting all the breaks.
      _visitCasesForSwitch(node, stateBefore);
    }

    // Combine all the termination states accumulated from all the visited
    // breaks that target this switch.
    _state = stateBefore.mergeAfterBreaks(_inferrer, _getBreaks(jumpTarget),
        keepOwnLocals: !hasDefaultCase);
    _clearBreaksAndContinues(jumpTarget);
    return null;
  }

  _visitCasesForSwitch(ir.SwitchStatement node, LocalState stateBefore) {
    for (ir.SwitchCase switchCase in node.cases) {
      _state = LocalState.childPath(stateBefore);
      visit(switchCase);
    }
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
    _continuesFor[target]!.add(LocalState.deepCopyOf(_state));
    return null;
  }

  @override
  TypeInformation visitListLiteral(ir.ListLiteral node) {
    return createListTypeInformation(
        node, node.expressions.map((e) => visit(e)!),
        isConst: node.isConst);
  }

  TypeInformation createListTypeInformation(
      ir.TreeNode node, Iterable<TypeInformation> elementTypes,
      {required bool isConst}) {
    // We only set the type once. We don't need to re-visit the children
    // when re-analyzing the node.
    return _inferrer.concreteTypes.putIfAbsent(node, () {
      PhiElementTypeInformation? elementType;
      int length = 0;
      for (TypeInformation type in elementTypes) {
        elementType = elementType == null
            ? _types.allocatePhi(null, null, type, isTry: false)
            : _types.addPhiInput(null, elementType, type);
        length++;
      }
      final simplifiedElementType = elementType == null
          ? _types.nonNullEmpty()
          : _types.simplifyPhi(null, null, elementType);
      TypeInformation containerType =
          isConst ? _types.constListType : _types.growableListType;
      return _types.allocateList(
          containerType, node, _analyzedMember, simplifiedElementType, length);
    });
  }

  @override
  TypeInformation visitSetLiteral(ir.SetLiteral node) {
    return createSetTypeInformation(
        node, node.expressions.map((e) => visit(e)!),
        isConst: node.isConst);
  }

  TypeInformation createSetTypeInformation(
      ir.TreeNode node, Iterable<TypeInformation> elementTypes,
      {required bool isConst}) {
    return _inferrer.concreteTypes.putIfAbsent(node, () {
      PhiElementTypeInformation? elementType;
      for (TypeInformation type in elementTypes) {
        elementType = elementType == null
            ? _types.allocatePhi(null, null, type, isTry: false)
            : _types.addPhiInput(null, elementType, type);
      }
      final simplifiedElementType = elementType == null
          ? _types.nonNullEmpty()
          : _types.simplifyPhi(null, null, elementType);
      TypeInformation containerType =
          isConst ? _types.constSetType : _types.setType;
      return _types.allocateSet(
          containerType, node, _analyzedMember, simplifiedElementType);
    });
  }

  @override
  TypeInformation visitMapLiteral(ir.MapLiteral node) {
    return createMapTypeInformation(
        node, node.entries.map((e) => Pair(visit(e.key)!, visit(e.value)!)),
        isConst: node.isConst);
  }

  TypeInformation createMapTypeInformation(ir.TreeNode node,
      Iterable<Pair<TypeInformation, TypeInformation>> entryTypes,
      {required bool isConst}) {
    return _inferrer.concreteTypes.putIfAbsent(node, () {
      List<TypeInformation> keyTypes = [];
      List<TypeInformation> valueTypes = [];

      for (Pair<TypeInformation, TypeInformation> entryType in entryTypes) {
        keyTypes.add(entryType.a);
        valueTypes.add(entryType.b);
      }

      final type = isConst ? _types.constMapType : _types.mapType;
      return _types.allocateMap(
          type, node, _analyzedMember, keyTypes, valueTypes);
    });
  }

  @override
  TypeInformation visitRecordLiteral(ir.RecordLiteral node) {
    final recordType = _elementMap.getDartType(node.recordType) as RecordType;
    final fieldValues = [
      for (final expression in node.positional) visit(expression)!,
      for (final namedExpression in node.named) visit(namedExpression.value)!
    ];
    return createRecordTypeInformation(node, recordType, fieldValues,
        isConst: node.isConst);
  }

  TypeInformation createRecordTypeInformation(
      ir.TreeNode node, RecordType recordType, List<TypeInformation> fieldTypes,
      {required bool isConst}) {
    return _types.allocateRecord(node, recordType, fieldTypes, isConst);
  }

  @override
  TypeInformation? visitReturnStatement(ir.ReturnStatement node) {
    final expression = node.expression;
    recordReturnType(expression == null ? _types.nullType : visit(expression)!);
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
  TypeInformation? visitVariableDeclaration(ir.VariableDeclaration node) {
    assert(
        node.parent is! ir.FunctionNode, "Unexpected parameter declaration.");
    Local local = _localsMap.getLocalVariable(node);
    DartType type = _localsMap.getLocalType(_elementMap, local);
    if (node.initializer == null) {
      _state.updateLocal(
          _inferrer, _capturedAndBoxed, local, _types.nullType, type);
    } else {
      _state.updateLocal(
          _inferrer, _capturedAndBoxed, local, visit(node.initializer)!, type);
    }
    if (node.initializer is ir.ThisExpression) {
      _state.markThisAsExposed();
    }
    return null;
  }

  @override
  TypeInformation? visitVariableGet(ir.VariableGet node) {
    Local local = _localsMap.getLocalVariable(node.variable);
    return _state.readLocal(_inferrer, _capturedAndBoxed, local);
  }

  @override
  TypeInformation visitVariableSet(ir.VariableSet node) {
    final rhsType = visit(node.value)!;
    if (node.value is ir.ThisExpression) {
      _state.markThisAsExposed();
    }
    Local local = _localsMap.getLocalVariable(node.variable);
    DartType type = _localsMap.getLocalType(_elementMap, local);
    _state.updateLocal(_inferrer, _capturedAndBoxed, local, rhsType, type);
    return rhsType;
  }

  ArgumentsTypes analyzeArguments(ir.Arguments arguments) {
    List<TypeInformation> positional = <TypeInformation>[];
    Map<String, TypeInformation>? named;
    for (ir.Expression argument in arguments.positional) {
      // TODO(ngeoffray): We could do better here if we knew what we
      // are calling does not expose this.
      if (argument is ir.ThisExpression) {
        _state.markThisAsExposed();
      }
      positional.add(visit(argument)!);
    }
    for (ir.NamedExpression argument in arguments.named) {
      named ??= <String, TypeInformation>{};
      ir.Expression value = argument.value;
      // TODO(ngeoffray): We could do better here if we knew what we
      // are calling does not expose this.
      if (value is ir.ThisExpression) {
        _state.markThisAsExposed();
      }
      named[argument.name] = visit(value)!;
    }

    return ArgumentsTypes(positional, named);
  }

  AbstractValue? _typeOfReceiver(ir.TreeNode node, ir.Expression receiver) {
    final data = _memberData as KernelGlobalTypeInferenceElementData;
    AbstractValue? mask = data.typeOfReceiver(node);
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

  TypeInformation _handleLocalFunctionInvocation(
      ir.Expression node,
      ir.FunctionDeclaration function,
      ir.Arguments arguments,
      Selector selector) {
    ArgumentsTypes argumentsTypes = analyzeArguments(arguments);
    ClosureRepresentationInfo info =
        _closureDataLookup.getClosureInfo(function);
    final callMethod = info.callMethod!;
    if (isIncompatibleInvoke(callMethod, argumentsTypes)) {
      return _types.dynamicType;
    }

    TypeInformation type =
        handleStaticInvoke(node, selector, callMethod, argumentsTypes);
    FunctionType functionType =
        _elementMap.elementEnvironment.getFunctionType(callMethod);
    if (functionType.returnType.containsFreeTypeVariables) {
      // The return type varies with the call site so we narrow the static
      // return type.
      type = _types.narrowType(type, _getStaticType(node));
    }
    return type;
  }

  @override
  TypeInformation visitLocalFunctionInvocation(
      ir.LocalFunctionInvocation node) {
    Selector selector = _elementMap.getSelector(node);
    return _handleLocalFunctionInvocation(
        node,
        node.variable.parent as ir.FunctionDeclaration,
        node.arguments,
        selector);
  }

  @override
  TypeInformation visitEqualsNull(ir.EqualsNull node) {
    visit(node.expression);
    // TODO(johnniwinther). This triggers the computation of the mask for the
    // receiver of the call to `==`, which doesn't happen in this case. Remove
    // this when the ssa builder recognizes `== null` directly.
    _typeOfReceiver(node, node.expression);
    _potentiallyAddNullCheck(node.expression);
    return _types.boolType;
  }

  TypeInformation _handleMethodInvocation(
      ir.Expression node,
      ir.Expression receiver,
      TypeInformation receiverType,
      Selector selector,
      ArgumentsTypes arguments,
      ir.Member? interfaceTarget) {
    final mask = _typeOfReceiver(node, receiver);
    if (receiver is ir.ThisExpression) {
      _checkIfExposesThis(
          selector, _types.newTypedSelector(receiverType, mask));
    }
    TypeInformation type = handleDynamicInvoke(CallType.access, node, selector,
        mask, receiverType, arguments, _getVariableDeclaration(receiver));
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

  TypeInformation _handleEqualsCall(
      ir.Expression node,
      ir.Expression left,
      TypeInformation leftType,
      ir.Expression right,
      TypeInformation rightType) {
    // TODO(johnniwinther). This triggers the computation of the mask for the
    // receiver of the call to `==`, which might not happen in this case. Remove
    // this when the ssa builder recognizes `== null` directly.
    _typeOfReceiver(node, left);
    bool leftIsNull = _types.isNull(leftType);
    bool rightIsNull = _types.isNull(rightType);
    if (leftIsNull) {
      // [right] is `null` if [node] evaluates to `true`.
      _potentiallyAddNullCheck(right);
    }
    if (rightIsNull) {
      // [left] is `null` if [node] evaluates to `true`.
      _potentiallyAddNullCheck(left);
    }
    if (leftIsNull || rightIsNull) {
      // `left == right` where `left` and/or `right` is known to have type
      // `Null` so we have no invocation to register.
      return _types.boolType;
    }
    Selector selector = Selector.binaryOperator('==');
    ArgumentsTypes arguments = ArgumentsTypes([rightType], null);
    return _handleMethodInvocation(
        node, left, leftType, selector, arguments, null);
  }

  @override
  TypeInformation visitEqualsCall(ir.EqualsCall node) {
    final leftType = visit(node.left)!;
    final rightType = visit(node.right)!;
    return _handleEqualsCall(node, node.left, leftType, node.right, rightType);
  }

  @override
  TypeInformation visitInstanceInvocation(ir.InstanceInvocation node) {
    Selector selector = _elementMap.getSelector(node);
    ir.Expression receiver = node.receiver;
    final receiverType = visit(receiver)!;
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    return _handleMethodInvocation(node, node.receiver, receiverType, selector,
        arguments, node.interfaceTarget);
  }

  @override
  TypeInformation visitInstanceGetterInvocation(
      ir.InstanceGetterInvocation node) {
    Selector selector = _elementMap.getSelector(node);
    ir.Expression receiver = node.receiver;
    final receiverType = visit(receiver)!;
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    return _handleMethodInvocation(node, node.receiver, receiverType, selector,
        arguments, node.interfaceTarget);
  }

  @override
  TypeInformation visitDynamicInvocation(ir.DynamicInvocation node) {
    Selector selector = _elementMap.getSelector(node);
    ir.Expression receiver = node.receiver;
    final receiverType = visit(receiver)!;
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    return _handleMethodInvocation(
        node, node.receiver, receiverType, selector, arguments, null);
  }

  @override
  TypeInformation visitFunctionInvocation(ir.FunctionInvocation node) {
    Selector selector = _elementMap.getSelector(node);
    ir.Expression receiver = node.receiver;
    final receiverType = visit(receiver)!;
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    return _handleMethodInvocation(
        node, node.receiver, receiverType, selector, arguments, null);
  }

  ir.VariableDeclaration? _getVariableDeclaration(ir.Expression node) {
    return node is ir.VariableGet ? node.variable : null;
  }

  TypeInformation _handleDynamic(
      CallType callType,
      ir.TreeNode node,
      Selector selector,
      AbstractValue? mask,
      TypeInformation receiverType,
      ArgumentsTypes? arguments,
      ir.VariableDeclaration? variable) {
    if (_types.selectorNeedsUpdate(receiverType, mask)) {
      mask = receiverType == _types.dynamicType
          ? null
          : _types.newTypedSelector(receiverType, mask);
      _inferrer.updateSelectorInMember(
          _analyzedMember, callType, node, selector, mask);
    }

    if (variable != null) {
      Local local = _localsMap.getLocalVariable(variable);
      if (!_capturedVariables.contains(local)) {
        // Receiver strengthening to non-null.
        DartType type = _localsMap.getLocalType(_elementMap, local);
        _state.updateLocal(
            _inferrer, _capturedAndBoxed, local, receiverType, type,
            excludeNull: !selector.appliesToNullWithoutThrow());
      }
    }

    return _inferrer.registerCalledSelector(callType, node, selector, mask,
        receiverType, _analyzedMember, arguments, _sideEffectsBuilder,
        inLoop: inLoop, isConditional: false);
  }

  TypeInformation handleDynamicGet(
      ir.TreeNode node,
      Selector selector,
      AbstractValue? mask,
      TypeInformation receiverType,
      ir.VariableDeclaration? variable) {
    return _handleDynamic(
        CallType.access, node, selector, mask, receiverType, null, variable);
  }

  TypeInformation handleDynamicSet(
      ir.TreeNode node,
      Selector selector,
      AbstractValue? mask,
      TypeInformation receiverType,
      TypeInformation rhsType,
      ir.VariableDeclaration? variable) {
    ArgumentsTypes arguments = ArgumentsTypes([rhsType], null);
    return _handleDynamic(CallType.access, node, selector, mask, receiverType,
        arguments, variable);
  }

  TypeInformation handleDynamicInvoke(
      CallType callType,
      ir.TreeNode node,
      Selector selector,
      AbstractValue? mask,
      TypeInformation receiverType,
      ArgumentsTypes arguments,
      ir.VariableDeclaration? variable) {
    return _handleDynamic(
        callType, node, selector, mask, receiverType, arguments, variable);
  }

  @override
  TypeInformation? visitLet(ir.Let node) {
    visit(node.variable);
    return visit(node.body);
  }

  @override
  TypeInformation? visitBlockExpression(ir.BlockExpression node) {
    visit(node.body);
    return visit(node.value);
  }

  @override
  TypeInformation? visitForInStatement(ir.ForInStatement node) {
    if (node.iterable is ir.ThisExpression) {
      // Any reasonable implementation of an iterator would expose
      // this, so we play it safe and assume it will.
      _state.markThisAsExposed();
    }

    AbstractValue? currentMask;
    AbstractValue? moveNextMask;
    TypeInformation iteratorType;
    if (node.isAsync) {
      final expressionType = visit(node.iterable)!;

      currentMask = _memberData.typeOfIteratorCurrent(node);
      moveNextMask = _memberData.typeOfIteratorMoveNext(node);

      ConstructorEntity constructor =
          _closedWorld.commonElements.streamIteratorConstructor;

      /// Synthesize a call to the [StreamIterator] constructor.
      iteratorType = handleStaticInvoke(
          node, null, constructor, ArgumentsTypes([expressionType], null));
    } else {
      final expressionType = visit(node.iterable)!;
      Selector iteratorSelector = Selectors.iterator;
      final iteratorMask = _memberData.typeOfIterator(node);
      currentMask = _memberData.typeOfIteratorCurrent(node);
      moveNextMask = _memberData.typeOfIteratorMoveNext(node);

      iteratorType = handleDynamicInvoke(CallType.forIn, node, iteratorSelector,
          iteratorMask, expressionType, ArgumentsTypes.empty(), null);
    }

    handleDynamicInvoke(CallType.forIn, node, Selectors.moveNext, moveNextMask,
        iteratorType, ArgumentsTypes.empty(), null);
    TypeInformation currentType = handleDynamicInvoke(
        CallType.forIn,
        node,
        Selectors.current,
        currentMask,
        iteratorType,
        ArgumentsTypes.empty(),
        null);

    Local variable = _localsMap.getLocalVariable(node.variable);
    DartType variableType = _localsMap.getLocalType(_elementMap, variable);
    _state.updateLocal(
        _inferrer, _capturedAndBoxed, variable, currentType, variableType);

    final target = _localsMap.getJumpTargetForForIn(node);
    return handleLoop(node, target, () {
      visit(node.body);
    });
  }

  void _setupBreaksAndContinues(JumpTarget? target) {
    if (target == null) return;
    if (target.isContinueTarget) {
      _continuesFor[target] = <LocalState>[];
    }
    if (target.isBreakTarget) {
      _breaksFor[target] = <LocalState>[];
    }
  }

  void _clearBreaksAndContinues(JumpTarget? element) {
    if (element == null) return;
    _continuesFor.remove(element);
    _breaksFor.remove(element);
  }

  List<LocalState> _getBreaks(JumpTarget? target) {
    List<LocalState> list = <LocalState>[_state];
    if (target == null) return list;
    if (!target.isBreakTarget) return list;
    return list..addAll(_breaksFor[target]!);
  }

  List<LocalState> _getLoopBackEdges(JumpTarget? target) {
    List<LocalState> list = <LocalState>[_state];
    if (target == null) return list;
    if (!target.isContinueTarget) return list;
    return list..addAll(_continuesFor[target]!);
  }

  TypeInformation? handleLoop(ir.Node node, JumpTarget? target, void logic()) {
    _loopLevel++;
    bool changed = false;
    final stateBefore = _state;
    stateBefore.startLoop(_inferrer, node);
    do {
      // Setup (and clear in case of multiple iterations of the loop)
      // the lists of breaks and continues seen in the loop.
      _setupBreaksAndContinues(target);
      _state = LocalState.childPath(stateBefore);
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
  int? _findLength(ir.Arguments arguments) {
    int? finish(int length) {
      // Filter out lengths that should not be tracked.
      if (length < 0) return null;
      // Serialization limit.
      if (length >= (1 << 30)) return null;
      return length;
    }

    ir.Expression firstArgument = arguments.positional.first;
    if (firstArgument is ir.ConstantExpression &&
        firstArgument.constant is ir.DoubleConstant) {
      final constant = firstArgument.constant as ir.DoubleConstant;
      double doubleValue = constant.value;
      int truncatedValue = doubleValue.truncate();
      if (doubleValue == truncatedValue) {
        return finish(truncatedValue);
      }
    } else if (firstArgument is ir.IntLiteral) {
      return finish(firstArgument.value);
    } else if (firstArgument is ir.StaticGet) {
      MemberEntity member = _elementMap.getMember(firstArgument.target);
      if (member is JField) {
        FieldAnalysisData fieldData =
            _closedWorld.fieldAnalysis.getFieldData(member);
        final constantValue = fieldData.constantValue;
        if (fieldData.isEffectivelyConstant &&
            constantValue is IntConstantValue) {
          BigInt intValue = constantValue.intValue;
          if (intValue.isValidInt) {
            return finish(intValue.toInt());
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
      {required bool defaultGrowable}) {
    TypeInformation finish(bool? growable) {
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
      ir.TreeNode node,
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

    if (commonElements.isNamedListConstructor('filled', constructor)) {
      // We have something like `List.filled(len, fill)`.
      final length = _findLength(arguments);
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
      final length = _findLength(arguments);
      TypeInformation baseType =
          _listBaseType(arguments, defaultGrowable: true);
      TypeInformation closureArgumentInfo = argumentsTypes.positional[1];
      // If the argument is an immediate closure, the element type is that
      // returned by the closure.
      TypeInformation? elementType;
      if (closureArgumentInfo is ClosureTypeInformation) {
        FunctionEntity closure = closureArgumentInfo.closure;
        elementType = _types.getInferredTypeOfMember(closure);
      }
      elementType ??= _types.dynamicType;
      return _inferrer.concreteTypes.putIfAbsent(
          node,
          () => _types.allocateList(
              baseType, node, _analyzedMember, elementType!, length));
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
      final length = _findLength(arguments);
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
      final length = _findLength(arguments);
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
      final length = _findLength(arguments);
      TypeInformation elementType = _types.nonNullEmpty();
      return _inferrer.concreteTypes.putIfAbsent(
          node,
          () => _types.allocateList(_types.growableListType, node,
              _analyzedMember, elementType, length));
    }

    if (_isConstructorOfTypedArraySubclass(constructor)) {
      // We have something like `Uint32List(len)`.
      final length = _findLength(arguments);
      final member = _elementMap.elementEnvironment
          .lookupClassMember(constructor.enclosingClass, Names.INDEX_NAME)!;
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

  TypeInformation handleStaticInvoke(ir.Node node, Selector? selector,
      MemberEntity element, ArgumentsTypes? arguments) {
    return _inferrer.registerCalledMember(node, selector, _analyzedMember,
        element, arguments, _sideEffectsBuilder, inLoop);
  }

  TypeInformation handleForeignInvoke(ir.StaticInvocation node,
      FunctionEntity function, ArgumentsTypes arguments, Selector selector) {
    final name = function.name;
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
    } else if (_closedWorld.commonElements.isCreateJsSentinel(function)) {
      return _types.lateSentinelType;
    } else if (_closedWorld.commonElements.isIsJsSentinel(function)) {
      return _types.boolType;
    } else {
      _sideEffectsBuilder.setAllSideEffects();
      return _types.dynamicType;
    }
  }

  @override
  TypeInformation visitStaticInvocation(ir.StaticInvocation node) {
    if (ir.StaticWeakReferences.isWeakReference(node)) {
      final weakTarget = ir.StaticWeakReferences.getWeakReferenceTarget(node);
      if (_elementMap.containsMethod(weakTarget)) {
        return visit(ir.StaticWeakReferences.getWeakReferenceArgument(node))!;
      }
      return _types.nullType;
    }
    MemberEntity member = _elementMap.getMember(node.target);
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    Selector selector = _elementMap.getSelector(node);
    if (_closedWorld.commonElements.isForeign(member)) {
      return handleForeignInvoke(
          node, member as FunctionEntity, arguments, selector);
    } else if (_closedWorld.commonElements.isLateReadCheck(member)) {
      // `_lateReadCheck` is essentially a narrowing to exclude the sentinel
      // value. In order to avoid poor inference resulting from a large
      // fan-in/fan-out, we perform the narrowing directly instead of creating a
      // [TypeInformation] for this member.
      handleStaticInvoke(node, selector, member, arguments);
      return _types.narrowType(arguments.positional[0],
          _elementMap.getDartType(node.arguments.types.single),
          excludeLateSentinel: true);
    } else if (_closedWorld.commonElements.isCreateSentinel(member)) {
      handleStaticInvoke(node, selector, member, arguments);
      return _types.lateSentinelType;
    } else if (_closedWorld.commonElements.isIsSentinel(member)) {
      handleStaticInvoke(node, selector, member, arguments);

      // Calls to `isSentinel` can only come from the late lowering kernel
      // transformation.
      final value = node.arguments.positional.single as ir.VariableGet;

      Local local = _localsMap.getLocalVariable(value.variable);
      DartType localType = _localsMap.getLocalType(_elementMap, local);
      LocalState stateWhenSentinel = LocalState.childPath(_state);
      LocalState stateWhenNotSentinel = LocalState.childPath(_state);

      // Narrow tested variable to late sentinel on true branch.
      stateWhenSentinel.updateLocal(_inferrer, _capturedAndBoxed, local,
          _types.lateSentinelType, localType);

      // Narrow tested variable to not late sentinel on false branch.
      final currentTypeInformation =
          stateWhenNotSentinel.readLocal(_inferrer, _capturedAndBoxed, local)!;
      stateWhenNotSentinel.updateLocal(_inferrer, _capturedAndBoxed, local,
          currentTypeInformation, localType,
          excludeLateSentinel: true);

      _setStateAfter(_state, stateWhenSentinel, stateWhenNotSentinel);

      return _types.boolType;
    } else if (member is ConstructorEntity) {
      return handleConstructorInvoke(
          node, node.arguments, selector, member, arguments);
    } else {
      assert(member.isFunction, "Unexpected static invocation target: $member");
      TypeInformation type =
          handleStaticInvoke(node, selector, member, arguments);
      FunctionType functionType = _elementMap.elementEnvironment
          .getFunctionType(member as FunctionEntity);
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

  @override
  TypeInformation visitStaticTearOff(ir.StaticTearOff node) {
    return createStaticGetTypeInformation(node, node.target);
  }

  TypeInformation createStaticGetTypeInformation(
      ir.Node node, ir.Member target) {
    MemberEntity member = _elementMap.getMember(target);
    return handleStaticInvoke(
        node, Selector.getter(member.memberName), member, null);
  }

  @override
  TypeInformation visitStaticSet(ir.StaticSet node) {
    final rhsType = visit(node.value)!;
    if (node.value is ir.ThisExpression) {
      _state.markThisAsExposed();
    }
    MemberEntity member = _elementMap.getMember(node.target);
    handleStaticInvoke(node, Selector.setter(member.memberName), member,
        ArgumentsTypes([rhsType], null));
    return rhsType;
  }

  TypeInformation _handlePropertyGet(ir.Expression node, ir.Expression receiver,
      {ir.Member? interfaceTarget}) {
    final receiverType = visit(receiver)!;
    Selector selector = _elementMap.getSelector(node);
    final mask = _typeOfReceiver(node, receiver);
    if (receiver is ir.ThisExpression) {
      _checkIfExposesThis(
          selector, _types.newTypedSelector(receiverType, mask));
    }
    TypeInformation type = handleDynamicGet(
        node, selector, mask, receiverType, _getVariableDeclaration(receiver));
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
  TypeInformation visitInstanceGet(ir.InstanceGet node) {
    return _handlePropertyGet(node, node.receiver,
        interfaceTarget: node.interfaceTarget);
  }

  @override
  TypeInformation visitInstanceTearOff(ir.InstanceTearOff node) {
    return _handlePropertyGet(node, node.receiver,
        interfaceTarget: node.interfaceTarget);
  }

  @override
  TypeInformation visitDynamicGet(ir.DynamicGet node) {
    return _handlePropertyGet(node, node.receiver);
  }

  TypeInformation _handleRecordFieldGet(
      ir.Expression node, ir.Expression receiver, String fieldName) {
    final receiverType = visit(receiver)!;
    (_memberData as KernelGlobalTypeInferenceElementData)
        .setReceiverTypeMask(node, receiverType.type);
    return _types.allocateRecordFieldGet(node, fieldName, receiverType);
  }

  @override
  TypeInformation visitRecordIndexGet(ir.RecordIndexGet node) {
    return _handleRecordFieldGet(node, node.receiver,
        RecordShape.positionalFieldIndexToGetterName(node.index));
  }

  @override
  TypeInformation visitRecordNameGet(ir.RecordNameGet node) {
    return _handleRecordFieldGet(node, node.receiver, node.name);
  }

  @override
  TypeInformation visitFunctionTearOff(ir.FunctionTearOff node) {
    return _handlePropertyGet(node, node.receiver);
  }

  TypeInformation _handlePropertySet(
      ir.Expression node, ir.Expression receiver, ir.Expression value) {
    final receiverType = visit(receiver)!;
    Selector selector = _elementMap.getSelector(node);
    final mask = _typeOfReceiver(node, receiver);

    final rhsType = visit(value)!;
    if (value is ir.ThisExpression) {
      _state.markThisAsExposed();
    }

    if (_inGenerativeConstructor && receiver is ir.ThisExpression) {
      final typedMask = _types.newTypedSelector(receiverType, mask);
      if (!_closedWorld.includesClosureCall(selector, typedMask)) {
        Iterable<DynamicCallTarget> targets =
            _memberHierarchyBuilder.rootsForCall(typedMask, selector);
        // We just recognized a field initialization of the form:
        // `this.foo = 42`. If there is only one non-virtual target, we can
        // update its type. If the target is virtual then technically overrides
        // of the target are also valid targets and we cannot make this update.
        if (targets.length == 1 && !targets.single.isVirtual) {
          MemberEntity single = targets.single.member;
          if (single is FieldEntity) {
            final field = single;
            _state.updateField(field, rhsType);
          }
        }
      }
    }
    if (receiver is ir.ThisExpression) {
      _checkIfExposesThis(
          selector, _types.newTypedSelector(receiverType, mask));
    }
    handleDynamicSet(node, selector, mask, receiverType, rhsType,
        _getVariableDeclaration(receiver));
    return rhsType;
  }

  @override
  TypeInformation visitInstanceSet(ir.InstanceSet node) {
    return _handlePropertySet(node, node.receiver, node.value);
  }

  @override
  TypeInformation visitDynamicSet(ir.DynamicSet node) {
    return _handlePropertySet(node, node.receiver, node.value);
  }

  @override
  TypeInformation visitThisExpression(ir.ThisExpression node) {
    return thisType;
  }

  TypeInformation? handleCondition(ir.Node? node) {
    return visit(node, conditionContext: true);
  }

  void _potentiallyAddIsCheck(ir.IsExpression node) {
    if (!_accumulateIsChecks) return;
    ir.Expression operand = node.operand;
    if (operand is ir.VariableGet) {
      Local local = _localsMap.getLocalVariable(operand.variable);
      DartType localType = _elementMap.getDartType(node.type);
      LocalState stateAfterCheckWhenTrue = LocalState.childPath(_state);
      LocalState stateAfterCheckWhenFalse = LocalState.childPath(_state);

      // Narrow variable to tested type on true branch.
      final currentTypeInformation = stateAfterCheckWhenTrue.readLocal(
          _inferrer, _capturedAndBoxed, local)!;
      stateAfterCheckWhenTrue.updateLocal(_inferrer, _capturedAndBoxed, local,
          currentTypeInformation, localType,
          isCast: false);
      _setStateAfter(_state, stateAfterCheckWhenTrue, stateAfterCheckWhenFalse);
    }
  }

  void _potentiallyAddNullCheck(ir.Expression receiver) {
    if (!_accumulateIsChecks) return;
    if (receiver is ir.VariableGet) {
      Local local = _localsMap.getLocalVariable(receiver.variable);
      DartType localType = _localsMap.getLocalType(_elementMap, local);
      LocalState stateAfterCheckWhenNull = LocalState.childPath(_state);
      LocalState stateAfterCheckWhenNotNull = LocalState.childPath(_state);

      // Narrow tested variable to 'Null' on true branch.
      stateAfterCheckWhenNull.updateLocal(
          _inferrer, _capturedAndBoxed, local, _types.nullType, localType);

      // Narrow tested variable to 'not null' on false branch.
      TypeInformation currentTypeInformation = stateAfterCheckWhenNotNull
          .readLocal(_inferrer, _capturedAndBoxed, local)!;
      stateAfterCheckWhenNotNull.updateLocal(_inferrer, _capturedAndBoxed,
          local, currentTypeInformation, _closedWorld.commonElements.objectType,
          excludeNull: true);
      _setStateAfter(
          _state, stateAfterCheckWhenNull, stateAfterCheckWhenNotNull);
    }
  }

  @override
  TypeInformation? visitIfStatement(ir.IfStatement node) {
    final stateBefore = _state;
    handleCondition(node.condition);
    final stateAfterConditionWhenTrue = _stateAfterWhenTrue;
    final stateAfterConditionWhenFalse = _stateAfterWhenFalse;
    _state = LocalState.childPath(stateAfterConditionWhenTrue);
    visit(node.then);
    final stateAfterThen = _state;
    _state = LocalState.childPath(stateAfterConditionWhenFalse);
    visit(node.otherwise);
    final stateAfterElse = _state;
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
    final stateAfterOperandWhenTrue = _stateAfterWhenTrue;
    final stateAfterOperandWhenFalse = _stateAfterWhenFalse;
    _setStateAfter(
        _state, stateAfterOperandWhenFalse, stateAfterOperandWhenTrue);
    // TODO(sra): Improve precision on constant and bool-conversion-to-constant
    // inputs.
    return _types.boolType;
  }

  @override
  TypeInformation? visitLogicalExpression(ir.LogicalExpression node) {
    if (node.operatorEnum == ir.LogicalExpressionOperator.AND) {
      final stateBefore = _state;
      _state = LocalState.childPath(stateBefore);
      final leftInfo = handleCondition(node.left)!;
      final stateAfterLeftWhenTrue = _stateAfterWhenTrue;
      final stateAfterLeftWhenFalse = _stateAfterWhenFalse;
      _state = LocalState.childPath(stateAfterLeftWhenTrue);
      final rightInfo = handleCondition(node.right)!;
      final stateAfterRightWhenTrue = _stateAfterWhenTrue;
      final stateAfterRightWhenFalse = _stateAfterWhenFalse;
      final stateAfterWhenTrue = stateAfterRightWhenTrue;
      LocalState stateAfterWhenFalse = LocalState.childPath(stateBefore)
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
      final stateBefore = _state;
      _state = LocalState.childPath(stateBefore);
      final leftInfo = handleCondition(node.left)!;
      final stateAfterLeftWhenTrue = _stateAfterWhenTrue;
      final stateAfterLeftWhenFalse = _stateAfterWhenFalse;
      _state = LocalState.childPath(stateAfterLeftWhenFalse);
      final rightInfo = handleCondition(node.right)!;
      final stateAfterRightWhenTrue = _stateAfterWhenTrue;
      final stateAfterRightWhenFalse = _stateAfterWhenFalse;
      LocalState stateAfterWhenTrue = LocalState.childPath(stateBefore)
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
  }

  @override
  TypeInformation visitConditionalExpression(ir.ConditionalExpression node) {
    final stateBefore = _state;
    handleCondition(node.condition);
    final stateAfterWhenTrue = _stateAfterWhenTrue;
    final stateAfterWhenFalse = _stateAfterWhenFalse;
    _state = LocalState.childPath(stateAfterWhenTrue);
    final firstType = visit(node.then)!;
    final stateAfterThen = _state;
    _state = LocalState.childPath(stateAfterWhenFalse);
    final secondType = visit(node.otherwise)!;
    final stateAfterElse = _state;
    _state =
        stateBefore.mergeDiamondFlow(_inferrer, stateAfterThen, stateAfterElse);
    return _types.allocateDiamondPhi(firstType, secondType);
  }

  TypeInformation handleLocalFunction(
      ir.LocalFunction node, ir.FunctionNode functionNode,
      [ir.VariableDeclaration? variable]) {
    // We loose track of [this] in closures (see issue 20840). To be on
    // the safe side, we mark [this] as exposed here. We could do better by
    // analyzing the closure.
    // TODO(herhut): Analyze whether closure exposes this. Possibly using
    // whether the created closure as a `thisLocal`.
    _state.markThisAsExposed();

    ClosureRepresentationInfo info = _closureDataLookup.getClosureInfo(node);
    final callMethod = info.callMethod!;

    // Record the types of captured non-boxed variables. Types of
    // these variables may already be there, because of an analysis of
    // a previous closure.
    info.forEachFreeVariable(_localsMap, (Local variable, FieldEntity field) {
      if (!info.isBoxedVariable(_localsMap, variable)) {
        if (variable == info.thisLocal) {
          _inferrer.recordTypeOfField(field, thisType);
        }
        final localType =
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
      return _types.allocateClosure(callMethod);
    });
    if (variable != null) {
      Local local = _localsMap.getLocalVariable(variable);
      DartType type = _localsMap.getLocalType(_elementMap, local);
      _state.updateLocal(
          _inferrer, _capturedAndBoxed, local, localFunctionType, type,
          excludeNull: true);
    }

    // We don't put the closure in the work queue of the
    // inferrer, because it will share information with its enclosing
    // method, like for example the types of local variables.
    LocalState closureState = LocalState.closure(_state);
    KernelTypeGraphBuilder visitor = KernelTypeGraphBuilder(
        _options,
        _closedWorld,
        _inferrer,
        callMethod,
        functionNode,
        _localsMap,
        _staticTypeProvider,
        _memberHierarchyBuilder,
        closureState,
        _capturedAndBoxed);
    visitor.run();
    _inferrer.recordReturnType(callMethod, visitor._returnType!);

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
      _state = LocalState.childPath(_stateAfterWhenTrue);
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
      //     _state = LocalState.childPath(_stateAfterWhenTrue, node.body);
    });
  }

  @override
  visitForStatement(ir.ForStatement node) {
    for (ir.VariableDeclaration variable in node.variables) {
      visit(variable);
    }
    return handleLoop(node, _localsMap.getJumpTargetForFor(node), () {
      handleCondition(node.condition);
      _state = LocalState.childPath(_stateAfterWhenTrue);
      visit(node.body);
      for (ir.Expression update in node.updates) {
        visit(update);
      }
    });
  }

  @override
  visitTryCatch(ir.TryCatch node) {
    final stateBefore = _state;
    _state = LocalState.tryBlock(stateBefore, node);
    _state.markInitializationAsIndefinite();
    visit(node.body);
    final stateAfterTry = _state;
    // If the try block contains a throw, then `stateAfterBody.aborts` will be
    // true. The catch needs to be aware of the results of inference from the
    // try block since we may get there via the abortive control flow:
    //
    // dynamic x = "bad";
    // try {
    //   ...
    //   x = 0;
    //   throw ...;
    // } catch (_) {
    //   print(x + 42); <-- x may be 0 here.
    // }
    //
    // Note that this will also cause us to ignore aborts due to breaks,
    // returns, and continues. Since these control flow constructs will not jump
    // to a catch block, this may cause some types flowing into the catch block
    // to be wider than necessary:
    //
    // dynamic x = "bad";
    // try {
    //   x = 0;
    //   return;
    // } catch (_) {
    //   print(x + 42); <-- x cannot be 0 here.
    // }
    _state = stateBefore.mergeTry(_inferrer, stateAfterTry);
    for (ir.Catch catchBlock in node.catches) {
      final stateBeforeCatch = _state;
      _state = LocalState.childPath(stateBeforeCatch);
      visit(catchBlock);
      final stateAfterCatch = _state;
      _state = stateBeforeCatch.mergeCatch(_inferrer, stateAfterCatch);
    }

    return null;
  }

  @override
  visitTryFinally(ir.TryFinally node) {
    final stateBefore = _state;
    _state = LocalState.tryBlock(stateBefore, node);
    _state.markInitializationAsIndefinite();
    visit(node.body);
    // Even if the try block contains abortive control flow, the finally block
    // needs to be aware of the results of inference from the try block since we
    // still reach the finally after abortive control flow:
    //
    // dynamic x = "bad";
    // try {
    //   ...
    //   x = 0;
    //   return;
    // } finally {
    //   print(x + 42); <-- x may be 0 here.
    // }
    _state = stateBefore.mergeTry(_inferrer, _state);
    final stateBeforeFinalizer = _state;
    // Use a child path to reset abort state before continuing into the
    // `finally` block.
    _state = LocalState.childPath(stateBeforeFinalizer);
    visit(node.finalizer);
    // Continue with a copy of the state after the finalizer since control flow
    // should continue linearly. Update abort state to account for try/catch
    // aborting.
    _state = LocalState.childPath(_state)
      ..seenReturnOrThrow =
          _state.seenReturnOrThrow || stateBeforeFinalizer.seenReturnOrThrow
      ..seenBreakOrContinue = _state.seenBreakOrContinue ||
          stateBeforeFinalizer.seenBreakOrContinue;
    return null;
  }

  @override
  visitCatch(ir.Catch node) {
    final exception = node.exception;
    if (exception != null) {
      TypeInformation mask;
      DartType type = _elementMap.getDartType(node.guard).withoutNullability;
      if (type is InterfaceType) {
        InterfaceType interfaceType = type;
        mask = _types.nonNullSubtype(interfaceType.element);
      } else {
        mask = _types.dynamicType;
      }
      Local local = _localsMap.getLocalVariable(exception);
      _state.updateLocal(
          _inferrer, _capturedAndBoxed, local, mask, _dartTypes.dynamicType(),
          excludeNull: true /* `throw null` produces a TypeError */);
    }
    final stackTrace = node.stackTrace;
    if (stackTrace != null) {
      Local local = _localsMap.getLocalVariable(stackTrace);
      // TODO(johnniwinther): Use a mask based on [StackTrace].
      // Note: stack trace may be null if users omit a stack in
      // `completer.completeError`.
      _state.updateLocal(_inferrer, _capturedAndBoxed, local,
          _types.dynamicType, _dartTypes.dynamicType());
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
      ir.Node node, Selector selector, ArgumentsTypes? arguments) {
    // Ensure we create a node, to make explicit the call to the
    // `noSuchMethod` handler.
    FunctionEntity noSuchMethod =
        _elementMap.getSuperNoSuchMethod(_analyzedMember.enclosingClass!);
    return handleStaticInvoke(node, selector, noSuchMethod, arguments);
  }

  @override
  TypeInformation visitSuperPropertyGet(ir.SuperPropertyGet node) {
    // TODO(herhut): We could do better here if we knew what we
    // are calling does not expose this.
    _state.markThisAsExposed();

    final target = getEffectiveSuperTarget(node.interfaceTarget);
    Selector selector = Selector.getter(_elementMap.getName(node.name));
    if (target == null) {
      // TODO(johnniwinther): Remove this when the CFE checks for missing
      //  concrete super targets.
      // TODO(48820): If this path is infeasible, update types on
      //  getEffectiveSuperTarget.
      return handleSuperNoSuchMethod(node, selector, null);
    }
    MemberEntity member = _elementMap.getMember(target);
    TypeInformation type = handleStaticInvoke(node, selector, member, null);
    if (member.isGetter) {
      FunctionType functionType = _elementMap.elementEnvironment
          .getFunctionType(member as FunctionEntity);
      if (functionType.returnType.containsFreeTypeVariables) {
        // The result type varies with the call site so we narrow the static
        // result type.
        type = _types.narrowType(type, _getStaticType(node));
      }
    } else if (member is FieldEntity) {
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

    final rhsType = visit(node.value)!;
    final target = getEffectiveSuperTarget(node.interfaceTarget);
    Selector selector = Selector.setter(_elementMap.getName(node.name));
    ArgumentsTypes arguments = ArgumentsTypes([rhsType], null);
    if (target == null) {
      // TODO(johnniwinther): Remove this when the CFE checks for missing
      //  concrete super targets.
      return handleSuperNoSuchMethod(node, selector, arguments);
    }
    final member = _elementMap.getMember(target);
    handleStaticInvoke(node, selector, member, arguments);
    return rhsType;
  }

  @override
  TypeInformation visitSuperMethodInvocation(ir.SuperMethodInvocation node) {
    // TODO(herhut): We could do better here if we knew what we
    // are calling does not expose this.
    _state.markThisAsExposed();

    final target = getEffectiveSuperTarget(node.interfaceTarget);
    ArgumentsTypes arguments = analyzeArguments(node.arguments);
    Selector selector = _elementMap.getSelector(node);
    if (target == null) {
      // TODO(johnniwinther): Remove this when the CFE checks for missing
      //  concrete super targets.
      return handleSuperNoSuchMethod(node, selector, arguments);
    }
    MemberEntity member = _elementMap.getMember(target);
    assert(member.isFunction, "Unexpected super invocation target: $member");
    if (isIncompatibleInvoke(member as FunctionEntity, arguments)) {
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

  @override
  TypeInformation visitAsExpression(ir.AsExpression node) {
    final operandType = visit(node.operand)!;
    return _types.narrowType(operandType, _elementMap.getDartType(node.type));
  }

  @override
  TypeInformation visitNullCheck(ir.NullCheck node) {
    final operandType = visit(node.operand)!;
    return _types.narrowType(operandType, _getStaticType(node));
  }

  @override
  TypeInformation visitAwaitExpression(ir.AwaitExpression node) {
    final futureType = visit(node.operand)!;
    return _inferrer.registerAwait(node, futureType);
  }

  @override
  TypeInformation visitYieldStatement(ir.YieldStatement node) {
    final operandType = visit(node.expression)!;
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
    return TypeInformationConstantVisitor(this, node)
        .visitConstant(node.constant);
  }
}

class TypeInformationConstantVisitor
    extends ir.ComputeOnceConstantVisitor<TypeInformation> {
  final KernelTypeGraphBuilder builder;
  final ir.ConstantExpression expression;

  TypeInformationConstantVisitor(this.builder, this.expression);

  static Never _unexpectedConstant(ir.Constant node) {
    throw UnsupportedError("Unexpected constant: "
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
        ConstantReference(expression, node),
        node.entries
            .map((e) => Pair(visitConstant(e.key), visitConstant(e.value))),
        isConst: true);
  }

  @override
  TypeInformation visitListConstant(ir.ListConstant node) {
    return builder.createListTypeInformation(
        ConstantReference(expression, node),
        node.entries.map((e) => visitConstant(e)),
        isConst: true);
  }

  @override
  TypeInformation visitSetConstant(ir.SetConstant node) {
    return builder.createSetTypeInformation(ConstantReference(expression, node),
        node.entries.map((e) => visitConstant(e)),
        isConst: true);
  }

  @override
  TypeInformation visitRecordConstant(ir.RecordConstant node) {
    final recordType =
        builder._elementMap.getDartType(node.recordType) as RecordType;
    final fieldValues = [
      for (final value in node.positional) visitConstant(value),
      for (final value in node.named.values) visitConstant(value)
    ];
    return builder.createRecordTypeInformation(
        ConstantReference(expression, node), recordType, fieldValues,
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
  TypeInformation visitInstantiationConstant(ir.InstantiationConstant node) {
    return builder.createInstantiationTypeInformation(
        visitConstant(node.tearOffConstant));
  }

  @override
  TypeInformation visitStaticTearOffConstant(ir.StaticTearOffConstant node) {
    return builder.createStaticGetTypeInformation(node, node.target);
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

  @override
  Never visitConstructorTearOffConstant(ir.ConstructorTearOffConstant node) =>
      _unexpectedConstant(node);

  @override
  Never visitRedirectingFactoryTearOffConstant(
          ir.RedirectingFactoryTearOffConstant node) =>
      _unexpectedConstant(node);

  @override
  Never visitTypedefTearOffConstant(ir.TypedefTearOffConstant node) =>
      _unexpectedConstant(node);

  @override
  Never visitAuxiliaryConstant(ir.AuxiliaryConstant node) =>
      _unexpectedConstant(node);
}

class Refinement {
  final Selector selector;
  final AbstractValue mask;

  Refinement(this.selector, this.mask);
}

class LocalState {
  final LocalsHandler _locals;
  final FieldInitializationScope? _fields;
  bool seenReturnOrThrow = false;
  bool seenBreakOrContinue = false;
  LocalsHandler? _tryBlock;

  LocalState.initial({required bool inGenerativeConstructor})
      : this.internal(LocalsHandler(),
            inGenerativeConstructor ? FieldInitializationScope() : null, null,
            seenReturnOrThrow: false, seenBreakOrContinue: false);

  LocalState.childPath(LocalState other)
      : this.internal(LocalsHandler.from(other._locals),
            FieldInitializationScope.from(other._fields), other._tryBlock,
            seenReturnOrThrow: false, seenBreakOrContinue: false);

  LocalState.closure(LocalState other)
      : this.internal(LocalsHandler.from(other._locals),
            FieldInitializationScope.from(other._fields), null,
            seenReturnOrThrow: false, seenBreakOrContinue: false);

  factory LocalState.tryBlock(LocalState other, ir.TreeNode node) {
    LocalsHandler locals = LocalsHandler.tryBlock(other._locals, node);
    final fieldScope = FieldInitializationScope.from(other._fields);
    LocalsHandler tryBlock = locals;
    return LocalState.internal(locals, fieldScope, tryBlock,
        seenReturnOrThrow: false, seenBreakOrContinue: false);
  }

  LocalState.deepCopyOf(LocalState other)
      : _locals = LocalsHandler.deepCopyOf(other._locals),
        _tryBlock = other._tryBlock,
        _fields = other._fields;

  LocalState.internal(this._locals, this._fields, this._tryBlock,
      {required this.seenReturnOrThrow, required this.seenBreakOrContinue});

  bool get aborts {
    return seenReturnOrThrow || seenBreakOrContinue;
  }

  bool get isThisExposed {
    return _fields?.isThisExposed ?? true;
  }

  void markThisAsExposed() {
    _fields?.isThisExposed = true;
  }

  void markInitializationAsIndefinite() {
    _fields?.isIndefinite = true;
  }

  TypeInformation? readField(FieldEntity field) {
    return _fields!.readField(field);
  }

  void updateField(FieldEntity field, TypeInformation type) {
    _fields!.updateField(field, type);
  }

  TypeInformation? readLocal(InferrerEngine inferrer,
      Map<Local, FieldEntity> capturedAndBoxed, Local local) {
    final field = capturedAndBoxed[local];
    if (field != null) {
      return inferrer.typeOfMember(field);
    } else {
      return _locals.use(local);
    }
  }

  void updateLocal(
      InferrerEngine inferrer,
      Map<Local, FieldEntity> capturedAndBoxed,
      Local local,
      TypeInformation type,
      DartType staticType,
      {isCast = true,
      excludeNull = false,
      excludeLateSentinel = false}) {
    setLocal(
        inferrer,
        capturedAndBoxed,
        local,
        inferrer.types.narrowType(type, staticType,
            isCast: isCast,
            excludeNull: excludeNull,
            excludeLateSentinel: excludeLateSentinel));
  }

  void setLocal(
      InferrerEngine inferrer,
      Map<Local, FieldEntity> capturedAndBoxed,
      Local local,
      TypeInformation type) {
    final field = capturedAndBoxed[local];
    if (field != null) {
      inferrer.recordTypeOfField(field, type);
    } else {
      _locals.update(inferrer, local, type, _tryBlock);
    }
  }

  LocalState mergeTry(InferrerEngine inferrer, LocalState other) {
    final locals = _locals.mergeFlow(inferrer, other._locals);
    return LocalState.internal(locals, _fields, _tryBlock,
        seenReturnOrThrow: seenReturnOrThrow || other.seenReturnOrThrow,
        seenBreakOrContinue: seenBreakOrContinue || other.seenBreakOrContinue);
  }

  LocalState mergeCatch(InferrerEngine inferrer, LocalState other) {
    LocalsHandler locals;
    if (aborts) {
      locals = other._locals;
    } else if (other.aborts) {
      locals = _locals;
    } else {
      locals = _locals.mergeFlow(inferrer, other._locals);
    }
    return LocalState.internal(locals, _fields, _tryBlock,
        seenReturnOrThrow: seenReturnOrThrow && other.seenReturnOrThrow,
        seenBreakOrContinue: seenBreakOrContinue && other.seenReturnOrThrow);
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

    final fieldScope = _fields?.mergeDiamondFlow(
        inferrer, thenBranch._fields!, elseBranch._fields!);
    return LocalState.internal(locals, fieldScope, _tryBlock,
        seenReturnOrThrow: seenReturnOrThrow,
        seenBreakOrContinue: seenBreakOrContinue);
  }

  LocalState mergeAfterBreaks(InferrerEngine inferrer, List<LocalState> states,
      {bool keepOwnLocals = true}) {
    bool allBranchesReturnOrThrow = true;
    for (LocalState state in states) {
      allBranchesReturnOrThrow &= state.seenReturnOrThrow;
    }

    keepOwnLocals &= !seenReturnOrThrow;

    LocalsHandler locals = _locals.mergeAfterBreaks(
        inferrer,
        states
            .where((LocalState state) => !state.seenReturnOrThrow)
            .map((LocalState state) => state._locals),
        keepOwnLocals: keepOwnLocals);
    seenReturnOrThrow = allBranchesReturnOrThrow && !keepOwnLocals;
    return LocalState.internal(locals, _fields, _tryBlock,
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
    StringBuffer sb = StringBuffer();
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
    StringBuffer sb = StringBuffer();
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
