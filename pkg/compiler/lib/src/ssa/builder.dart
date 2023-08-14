// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/static_weak_references.dart' as ir
    show StaticWeakReferences;
import 'package:js_runtime/synced/embedded_names.dart';
import 'package:js_shared/synced/embedded_names.dart'
    show JsBuiltin, JsGetName, TYPES;
import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common.dart';
import '../common/codegen.dart' show CodegenRegistry;
import '../common/elements.dart';
import '../common/names.dart';
import '../constants/constant_system.dart' as constant_system;
import '../constants/values.dart';
import '../deferred_load/output_unit.dart' show OutputUnit;
import '../dump_info.dart';
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../inferrer/abstract_value_domain.dart';
import '../inferrer/types.dart';
import '../io/source_information.dart';
import '../ir/static_type.dart';
import '../ir/static_type_provider.dart';
import '../ir/util.dart';
import '../js/js.dart' as js;
import '../js_backend/backend.dart' show FunctionInlineCache;
import '../js_backend/field_analysis.dart'
    show FieldAnalysisData, JFieldAnalysis;
import '../js_backend/interceptor_data.dart';
import '../js_backend/inferred_data.dart';
import '../js_backend/namer.dart' show ModularNamer;
import '../js_backend/native_data.dart';
import '../js_backend/runtime_types_resolution.dart';
import '../js_emitter/code_emitter_task.dart' show ModularEmitter;
import '../js_model/class_type_variable_access.dart';
import '../js_model/element_map.dart';
import '../js_model/elements.dart' show JGeneratorBody;
import '../js_model/js_strategy.dart';
import '../js_model/js_world.dart' show JClosedWorld;
import '../js_model/locals.dart' show GlobalLocalsMap, JumpVisitor;
import '../js_model/type_recipe.dart';
import '../js_model/records.dart' show RecordData, JRecordGetter;
import '../kernel/invocation_mirror_constants.dart';
import '../native/behavior.dart';
import '../native/js.dart';
import '../options.dart';
import '../tracer.dart';
import '../universe/call_structure.dart';
import '../universe/feature.dart';
import '../universe/record_shape.dart';
import '../universe/selector.dart';
import '../universe/target_checks.dart' show TargetChecks;
import '../universe/use.dart' show ConstantUse, StaticUse, TypeUse;
import 'branch_builder.dart';
import 'jump_handler.dart';
import 'locals_handler.dart';
import 'loop_handler.dart';
import 'metrics.dart';
import 'nodes.dart';
import 'string_builder.dart';
import 'switch_continue_analysis.dart';
import 'type_builder.dart';

// TODO(johnniwinther): Merge this with [KernelInliningState].
class StackFrame {
  final StackFrame? parent;
  final MemberEntity member;
  final AsyncMarker asyncMarker;
  final KernelToLocalsMap localsMap;
  // [ir.Let] and [ir.LocalInitializer] bindings.
  final Map<ir.VariableDeclaration, HInstruction> letBindings;
  final KernelToTypeInferenceMap typeInferenceMap;
  final SourceInformationBuilder sourceInformationBuilder;
  final StaticTypeProvider? staticTypeProvider;

  StackFrame(
      this.parent,
      this.member,
      this.asyncMarker,
      this.localsMap,
      this.letBindings,
      this.typeInferenceMap,
      this.sourceInformationBuilder,
      this.staticTypeProvider);
}

class KernelSsaGraphBuilder extends ir.Visitor<void> with ir.VisitorVoidMixin {
  /// Holds the resulting SSA graph.
  final HGraph graph = HGraph();

  /// True if the builder is processing nodes inside a try statement. This is
  /// important for generating control flow out of a try block like returns or
  /// breaks.
  bool _inTryStatement = false;

  /// Used to track the locals while building the graph.
  late LocalsHandler localsHandler;

  /// A stack of instructions.
  ///
  /// We build the SSA graph by simulating a stack machine.
  List<HInstruction> stack = [];

  /// The count of nested loops we are currently building.
  ///
  /// The loop nesting is consulted when inlining a function invocation. The
  /// inlining heuristics take this information into account.
  int loopDepth = 0;

  /// A mapping from jump targets to their handlers.
  Map<JumpTarget, JumpHandler> jumpTargets = {};

  final CompilerOptions options;
  final DiagnosticReporter reporter;
  final ModularEmitter _emitter;
  final ModularNamer _namer;
  final MemberEntity targetElement;
  final MemberEntity _initialTargetElement;
  final JClosedWorld closedWorld;
  final CodegenRegistry registry;
  final ClosureData _closureDataLookup;
  final RecordData _recordData;
  final Tracer _tracer;

  /// A stack of [InterfaceType]s that have been seen during inlining of
  /// factory constructors.  These types are preserved in [HInvokeStatic]s and
  /// [HCreate]s inside the inline code and registered during code generation
  /// for these nodes.
  // TODO(karlklose): consider removing this and keeping the (substituted) types
  // of the type variables in an environment (like the [LocalsHandler]).
  final List<InterfaceType> _currentImplicitInstantiations = [];

  /// Used to report information about inlining (which occurs while building the
  /// SSA graph), when dump-info is enabled.
  final InfoReporter? _infoReporter;

  final SsaMetrics _metrics;

  HInstruction? _rethrowableException;

  final SourceInformationStrategy _sourceInformationStrategy;
  final JsToElementMap _elementMap;
  final GlobalTypeInferenceResults globalInferenceResults;
  late final LoopHandler _loopHandler;
  late final TypeBuilder _typeBuilder;

  /// True if we are visiting the expression of a throw statement; we assume
  /// this is a slow path.
  bool _inExpressionOfThrow = false;

  final List<KernelInliningState> _inliningStack = [];
  Local? _returnLocal;
  DartType? _returnType;

  StackFrame? _currentFrame;

  final FunctionInlineCache _inlineCache;
  final InlineDataCache _inlineDataCache;

  final ir.Member? _memberContextNode;

  KernelSsaGraphBuilder(
      this.options,
      this.reporter,
      this._initialTargetElement,
      InterfaceType? instanceType,
      this._infoReporter,
      this._metrics,
      this._elementMap,
      this.globalInferenceResults,
      this.closedWorld,
      this.registry,
      this._namer,
      this._emitter,
      this._tracer,
      this._sourceInformationStrategy,
      this._inlineCache,
      this._inlineDataCache)
      : this.targetElement = _effectiveTargetElementFor(_initialTargetElement),
        this._closureDataLookup = closedWorld.closureDataLookup,
        this._recordData = closedWorld.recordData,
        _memberContextNode =
            _elementMap.getMemberContextNode(_initialTargetElement) {
    _enterFrame(targetElement, null);
    _loopHandler = KernelLoopHandler(this);
    _typeBuilder = KernelTypeBuilder(this, _elementMap);
    graph.element = targetElement;
    graph.sourceInformation =
        _sourceInformationBuilder.buildVariableDeclaration();
    localsHandler = LocalsHandler(this, targetElement, targetElement,
        instanceType, _nativeData, _interceptorData);
  }

  KernelToLocalsMap get _localsMap => _currentFrame!.localsMap;

  Map<ir.VariableDeclaration, HInstruction> get _letBindings =>
      _currentFrame!.letBindings;

  JCommonElements get _commonElements => _elementMap.commonElements;

  JElementEnvironment get _elementEnvironment => _elementMap.elementEnvironment;

  JFieldAnalysis get _fieldAnalysis => closedWorld.fieldAnalysis;

  KernelToTypeInferenceMap get _typeInferenceMap =>
      _currentFrame!.typeInferenceMap;

  SourceInformationBuilder get _sourceInformationBuilder =>
      _currentFrame!.sourceInformationBuilder;

  AbstractValueDomain get _abstractValueDomain =>
      closedWorld.abstractValueDomain;

  NativeData get _nativeData => closedWorld.nativeData;

  InterceptorData get _interceptorData => closedWorld.interceptorData;

  RuntimeTypesNeed get _rtiNeed => closedWorld.rtiNeed;

  GlobalLocalsMap get _globalLocalsMap =>
      globalInferenceResults.globalLocalsMap;

  InferredData get _inferredData => globalInferenceResults.inferredData;

  DartTypes get dartTypes => closedWorld.dartTypes;

  void push(HInstruction instruction) {
    add(instruction);
    stack.add(instruction);
  }

  HInstruction pop() {
    return stack.removeLast();
  }

  /// Pushes a boolean checking [expression] against null.
  pushCheckNull(HInstruction expression) {
    push(HIdentity(expression, graph.addConstantNull(closedWorld),
        _abstractValueDomain.boolType));
  }

  HBasicBlock? _current;

  /// The current block to add instructions to. Might be null, if we are
  /// visiting dead code, but see [_isReachable].
  HBasicBlock? get current => _current;

  void set current(HBasicBlock? c) {
    _isReachable = c != null;
    _current = c;
  }

  /// The most recently opened block. Has the same value as [current] while
  /// the block is open, but unlike [current], it isn't cleared when the
  /// current block is closed.
  late HBasicBlock lastOpenedBlock;

  /// Indicates whether the current block is dead (because it has a throw or a
  /// return further up). If this is false, then [current] may be null. If the
  /// block is dead then it may also be aborted, but for simplicity we only
  /// abort on statement boundaries, not in the middle of expressions. See
  /// [isAborted].
  bool _isReachable = true;

  /// Is the current statement or expression nested in a [ir.BlockExpression]?
  bool _inBlockExpression = false;

  HLocalValue? lastAddedParameter;

  Map<Local, HInstruction> parameters = {};
  late Set<Local> elidedParameters;

  HBasicBlock addNewBlock() {
    HBasicBlock block = graph.addNewBlock();
    // If adding a new block during building of an expression, it is due to
    // conditional expressions or short-circuit logical operators.
    return block;
  }

  void open(HBasicBlock block) {
    block.open();
    current = block;
    lastOpenedBlock = block;
  }

  HBasicBlock close(HControlFlow end) {
    HBasicBlock result = current!;
    current!.close(end);
    current = null;
    return result;
  }

  HBasicBlock _closeAndGotoExit(HControlFlow end) {
    HBasicBlock result = current!;
    current!.close(end);
    current = null;
    result.addSuccessor(graph.exit);
    return result;
  }

  void goto(HBasicBlock from, HBasicBlock to) {
    from.close(HGoto(_abstractValueDomain));
    from.addSuccessor(to);
  }

  void _prepareEntryBlock() {
    HBasicBlock block = graph.addNewBlock();
    // Create `graph.entry` as an initially empty block. `graph.entry` is
    // treated specially (holding parameters, local variables and constants)
    // but cannot receive constants before it has been closed. By closing it
    // here, we can use constants in the code that sets up the function.
    open(graph.entry);
    close(HGoto(_abstractValueDomain)).addSuccessor(block);
    open(block);
  }

  bool isAborted() {
    return current == null;
  }

  /// Creates a new block, transitions to it from any current block, and
  /// opens the new block.
  HBasicBlock openNewBlock() {
    HBasicBlock newBlock = addNewBlock();
    if (!isAborted()) goto(current!, newBlock);
    open(newBlock);
    return newBlock;
  }

  void add(HInstruction instruction) {
    current!.add(instruction);
  }

  HLocalValue addParameter(Entity? parameter, AbstractValue type,
      {bool isElided = false}) {
    HLocalValue result = isElided
        ? HLocalValue(parameter, type)
        : HParameterValue(parameter, type);
    if (lastAddedParameter == null) {
      graph.entry.addBefore(graph.entry.first, result);
    } else {
      graph.entry.addAfter(lastAddedParameter, result);
    }
    lastAddedParameter = result;
    return result;
  }

  HSubGraphBlockInformation? wrapStatementGraph(SubGraph? statements) {
    if (statements == null) return null;
    return HSubGraphBlockInformation(statements);
  }

  HExpressionInformation? wrapExpressionGraph(SubExpression? expression) {
    if (expression == null) return null;
    return HSubExpressionBlockInformation(expression);
  }

  HLiteralList _buildLiteralList(List<HInstruction> inputs) {
    return HLiteralList(inputs, _abstractValueDomain.growableListType);
  }

  /// Called when control flow is about to change, in which case we need to
  /// specify special successors if we are already in a try/catch/finally block.
  void _handleInTryStatement() {
    if (!_inTryStatement) return;
    HBasicBlock block = close(HExitTry(_abstractValueDomain));
    HBasicBlock newBlock = graph.addNewBlock();
    block.addSuccessor(newBlock);
    open(newBlock);
  }

  /// Helper to implement JS_GET_FLAG.
  ///
  /// The concrete SSA graph builder will extract a flag parameter from the
  /// JS_GET_FLAG call and then push a boolean result onto the stack. This
  /// function provides the boolean value corresponding to the given [flagName].
  /// If [flagName] is not recognized, this function returns `null` and the
  /// concrete SSA builder reports an error.
  bool? _getFlagValue(String flagName) {
    switch (flagName) {
      case 'FALSE':
        return false;
      case 'DEV_COMPILER':
        return false;
      case 'MINIFIED':
        return options.enableMinification;
      case 'MUST_RETAIN_METADATA':
        return false;
      case 'USE_CONTENT_SECURITY_POLICY':
        return options.features.useContentSecurityPolicy.isEnabled;
      case 'VARIANCE':
        return options.enableVariance;
      case 'LEGACY':
        return options.useLegacySubtyping;
      case 'PRINT_LEGACY_STARS':
        return options.printLegacyStars;
      default:
        return null;
    }
  }

  StaticType _getStaticType(ir.Expression node) {
    // TODO(johnniwinther): Substitute the type by the this type and type
    // arguments of the current frame.
    ir.DartType type = _currentFrame!.staticTypeProvider!.getStaticType(node);
    return StaticType(
        _elementMap.getDartType(type), computeClassRelationFromType(type));
  }

  StaticType _getStaticForInIteratorType(ir.ForInStatement node) {
    // TODO(johnniwinther): Substitute the type by the this type and type
    // arguments of the current frame.
    ir.DartType type =
        _currentFrame!.staticTypeProvider!.getForInIteratorType(node);
    return StaticType(
        _elementMap.getDartType(type), computeClassRelationFromType(type));
  }

  static MemberEntity _effectiveTargetElementFor(MemberEntity member) {
    if (member is JGeneratorBody) return member.function;
    return member;
  }

  void _enterFrame(
      MemberEntity member, SourceInformation? callSourceInformation) {
    AsyncMarker asyncMarker = AsyncMarker.SYNC;
    final function = getFunctionNode(_elementMap, member);
    if (function != null) {
      asyncMarker = getAsyncMarker(function);
    }
    _currentFrame = StackFrame(
        _currentFrame,
        member,
        asyncMarker,
        _globalLocalsMap.getLocalsMap(member),
        {},
        KernelToTypeInferenceMapImpl(member, globalInferenceResults),
        _currentFrame != null
            ? _currentFrame!.sourceInformationBuilder
                .forContext(member, callSourceInformation)
            : _sourceInformationStrategy.createBuilderForContext(member),
        _elementMap.getStaticTypeProvider(member));
  }

  void _leaveFrame() {
    _currentFrame = _currentFrame!.parent;
  }

  HGraph? build() {
    return reporter.withCurrentElement(_localsMap.currentMember, () {
      // TODO(het): no reason to do this here...
      HInstruction.idCounter = 0;
      MemberDefinition definition =
          _elementMap.getMemberDefinition(_initialTargetElement);

      switch (definition.kind) {
        case MemberKind.regular:
        case MemberKind.closureCall:
          ir.Node target = definition.node;
          if (target is ir.Procedure) {
            if (target.isExternal) {
              _buildExternalFunctionNode(targetElement as FunctionEntity,
                  _ensureDefaultArgumentValues(target, target.function));
            } else {
              _buildFunctionNode(targetElement as FunctionEntity,
                  _ensureDefaultArgumentValues(target, target.function));
            }
          } else if (target is ir.Field) {
            FieldAnalysisData fieldData = closedWorld.fieldAnalysis
                .getFieldData(targetElement as FieldEntity);

            if (fieldData.initialValue != null) {
              registry.registerConstantUse(
                  ConstantUse.init(fieldData.initialValue!));
              if (targetElement.isStatic || targetElement.isTopLevel) {
                /// No code is created for this field: All references inline the
                /// constant value.
                return null;
              }
            } else if (fieldData.isLazy) {
              // The generated initializer needs be wrapped in the cyclic-error
              // helper.
              registry.registerStaticUse(StaticUse.staticInvoke(
                  closedWorld.commonElements.cyclicThrowHelper,
                  CallStructure.ONE_ARG));
              registry.registerStaticUse(StaticUse.staticInvoke(
                  closedWorld.commonElements.throwLateFieldADI,
                  CallStructure.ONE_ARG));
            }
            if (targetElement.isInstanceMember) {
              if (fieldData.isEffectivelyFinal ||
                  !closedWorld.annotationsData
                      .getParameterCheckPolicy(targetElement)
                      .isEmitted) {
                // No need for a checked setter.
                return null;
              }
            }
            if (targetElement.isInstanceMember) {
              _buildInstanceFieldSetter(target);
            } else {
              _buildStaticFieldInitializer(target);
            }
          } else if (target is ir.LocalFunction) {
            _buildFunctionNode(targetElement as FunctionEntity,
                _ensureDefaultArgumentValues(null, target.function));
          } else {
            throw 'No case implemented to handle target: '
                '$target for $targetElement';
          }
          break;
        case MemberKind.constructor:
          final constructor = definition.node as ir.Constructor;
          _ensureDefaultArgumentValues(constructor, constructor.function);
          _buildConstructor(targetElement as ConstructorEntity, constructor);
          break;
        case MemberKind.constructorBody:
          final constructor = definition.node as ir.Constructor;
          _ensureDefaultArgumentValues(constructor, constructor.function);
          _buildConstructorBody(constructor);
          break;
        case MemberKind.closureField:
          // Closure fields have no setter and therefore never require any code.
          return null;
        case MemberKind.signature:
          ir.Node target = definition.node;
          ir.FunctionNode originalClosureNode;
          if (target is ir.Procedure) {
            originalClosureNode = target.function;
          } else if (target is ir.LocalFunction) {
            originalClosureNode = target.function;
          } else {
            failedAt(
                targetElement,
                "Unexpected function signature: "
                "$targetElement inside a non-closure: $target");
          }
          _buildMethodSignatureNewRti(originalClosureNode);
          break;
        case MemberKind.generatorBody:
          _buildGeneratorBody(_initialTargetElement as JGeneratorBody,
              _functionNodeOf(definition.node)!);
          break;
        case MemberKind.recordGetter:
          _buildRecordGetter(_initialTargetElement as JRecordGetter,
              definition as RecordGetterDefinition);
          break;
      }
      assert(graph.isValid(), "Invalid graph for $_initialTargetElement.");

      if (_tracer.isEnabled) {
        MemberEntity member = _initialTargetElement;
        String name = member.name ?? '<null>';
        if (member.isInstanceMember ||
            member is ConstructorEntity ||
            member.isStatic) {
          name = "${member.enclosingClass!.name}.$name";
          if (definition.kind == MemberKind.constructorBody) {
            name += " (body)";
          }
        }
        _tracer.traceCompilation(name);
        _tracer.traceGraph('builder', graph);
      }

      return graph;
    });
  }

  ir.FunctionNode? _functionNodeOf(ir.Node node) {
    if (node is ir.Member) return node.function;
    if (node is ir.LocalFunction) return node.function;
    return null;
  }

  ir.FunctionNode _ensureDefaultArgumentValues(
      ir.Member? member, ir.FunctionNode function) {
    // Register all [function]'s default argument values.
    //
    // Default values might be (or contain) functions that are not referenced
    // from anywhere else so we need to ensure these are enqueued.  Stubs and
    // `Function.apply` data are created after the codegen queue is closed, so
    // we force these functions into the queue by registering the constants as
    // used in advance. See language/cyclic_default_values_test.dart for an
    // example.
    //
    // TODO(sra): We could be more precise if stubs and `Function.apply` data
    // were generated by the codegen enqueuer. In practice even in huge programs
    // there are only very small number of constants created here that are not
    // actually used.
    void _registerDefaultValue(ir.VariableDeclaration node) {
      final constantValue = _elementMap
          .getConstantValue(member, node.initializer, implicitNull: true);
      assert(
          constantValue != null,
          failedAt(_elementMap.getMethod(function.parent as ir.Procedure),
              'No constant computed for $node'));
      registry.registerConstantUse(ConstantUse.init(constantValue!));
    }

    function.positionalParameters
        .skip(function.requiredParameterCount)
        .forEach(_registerDefaultValue);
    function.namedParameters.forEach(_registerDefaultValue);
    return function;
  }

  void _buildInstanceFieldSetter(ir.Field node) {
    assert(!node.isStatic);
    FieldEntity field = _elementMap.getMember(node) as FieldEntity;
    _openFunction(field, checks: TargetChecks.none);
    HInstruction thisInstruction = localsHandler.readThis(
        sourceInformation: _sourceInformationBuilder.buildGet(node));
    // Use dynamic type because the type computed by the inferrer is
    // narrowed to the type annotation.
    HInstruction parameter =
        HParameterValue(field, _abstractValueDomain.dynamicType);
    // Add the parameter as the last instruction of the entry block.
    // If the method is intercepted, we want the actual receiver
    // to be the first parameter.
    graph.entry.addBefore(graph.entry.last, parameter);
    DartType type = _getDartTypeIfValid(node.type);
    HInstruction value = _typeBuilder.potentiallyCheckOrTrustTypeOfParameter(
        field, parameter, type);
    // TODO(sra): Pass source information to
    // [potentiallyCheckOrTrustTypeOfParameter].
    // TODO(sra): The source information should indicate the field and
    // possibly its type but not the initializer.
    value.sourceInformation ??= _sourceInformationBuilder.buildSet(node);
    value = _potentiallyAssertNotNull(field, node, value, type);
    if (!_fieldAnalysis.getFieldData(field).isElided) {
      add(HFieldSet(_abstractValueDomain, field, thisInstruction, value));
    }
    _closeFunction();
  }

  void _buildStaticFieldInitializer(ir.Field node) {
    assert(node.isStatic);
    graph.isLazyInitializer = true;
    FieldEntity field = _elementMap.getMember(node) as FieldEntity;
    _openFunction(field, checks: TargetChecks.none);
    if (node.initializer != null) {
      node.initializer!.accept(this);
      HInstruction fieldValue = pop();
      HInstruction checkInstruction =
          _typeBuilder.potentiallyCheckOrTrustTypeOfAssignment(
              field, fieldValue, _getDartTypeIfValid(node.type));
      stack.add(checkInstruction);
    } else {
      stack.add(graph.addConstantNull(closedWorld));
    }
    HInstruction value = pop();
    _closeAndGotoExit(HReturn(_abstractValueDomain, value,
        _sourceInformationBuilder.buildReturn(node)));
    _closeFunction();
  }

  DartType _getDartTypeIfValid(ir.DartType type) {
    if (type is ir.InvalidType) return dartTypes.dynamicType();
    return _elementMap.getDartType(type);
  }

  /// Pops the most recent instruction from the stack and ensures that it is a
  /// non-null bool.
  HInstruction popBoolified() {
    HInstruction value = pop();
    return _typeBuilder.potentiallyCheckOrTrustTypeOfCondition(
        _currentFrame!.member, value);
  }

  /// Extend current method parameters with parameters for the class type
  /// parameters.  If the class has type parameters but does not need them, bind
  /// to `dynamic` (represented as `null`) so the bindings are available for
  /// building types up the inheritance chain of generative constructors.
  void _addClassTypeVariablesIfNeeded(MemberEntity member) {
    if (member is! ConstructorEntity && member is! ConstructorBodyEntity) {
      return;
    }
    ClassEntity cls = member.enclosingClass!;
    InterfaceType thisType = _elementEnvironment.getThisType(cls);
    if (thisType.typeArguments.isEmpty) {
      return;
    }
    bool needsTypeArguments = _rtiNeed.classNeedsTypeArguments(cls);
    thisType.typeArguments.forEach((DartType _typeVariable) {
      final typeVariableType = _typeVariable as TypeVariableType;
      HInstruction param;
      if (needsTypeArguments) {
        param = addParameter(
            typeVariableType.element, _abstractValueDomain.nonNullType);
      } else {
        // Unused, so bind to `dynamic`.
        param = graph.addConstantNull(closedWorld);
      }
      Local local = localsHandler.getTypeVariableAsLocal(typeVariableType);
      localsHandler.directLocals[local] = param;
    });
  }

  /// Extend current method parameters with parameters for the function type
  /// variables.
  void _addFunctionTypeVariablesIfNeeded(MemberEntity member) {
    if (member is! FunctionEntity) return;

    FunctionEntity function = member;
    List<TypeVariableType> typeVariables =
        _elementEnvironment.getFunctionTypeVariables(function);
    if (typeVariables.isEmpty) {
      return;
    }
    bool needsTypeArguments = _rtiNeed.methodNeedsTypeArguments(function);
    bool elideTypeParameters = function.parameterStructure.typeParameters == 0;
    for (TypeVariableType typeVariable in typeVariables) {
      HInstruction param;
      bool erased = false;
      if (elideTypeParameters) {
        // Add elided type parameters.
        param = _computeTypeArgumentDefaultValue(function, typeVariable);
        erased = true;
      } else if (needsTypeArguments) {
        param = addParameter(
            typeVariable.element, _abstractValueDomain.nonNullType);
      } else {
        // Unused, so bind to bound.
        param = _computeTypeArgumentDefaultValue(function, typeVariable);
        erased = true;
      }
      Local local = localsHandler.getTypeVariableAsLocal(typeVariable);
      localsHandler.directLocals[local] = param;
      if (!erased) {
        _functionTypeParameterLocals.add(local);
      }
    }
  }

  // Locals for function type parameters that can be forwarded, in argument
  // position order.
  final List<Local> _functionTypeParameterLocals = [];

  /// Builds a generative constructor.
  ///
  /// Generative constructors are built in stages, in effect inlining the
  /// initializers and constructor bodies up the inheritance chain.
  ///
  ///  1. Extend method parameters with parameters the class's type parameters.
  ///
  ///  2. Add type checks for value parameters (might need result of (1)).
  ///
  ///  3. Walk inheritance chain to build bindings for type parameters of
  ///     superclasses and mixed-in classes.
  ///
  ///  4. Collect initializer values. Walk up inheritance chain to collect field
  ///     initializers from field declarations, initializing parameters and
  ///     initializer.
  ///
  ///  5. Create reified type information for instance.
  ///
  ///  6. Allocate instance and assign initializers and reified type information
  ///     to fields by calling JavaScript constructor.
  ///
  ///  7. Walk inheritance chain to call or inline constructor bodies.
  ///
  /// All the bindings are put in the constructor's locals handler. The
  /// implication is that a class cannot be extended or mixed-in twice. If we in
  /// future support repeated uses of a mixin class, we should do so by cloning
  /// the mixin class in the Kernel input.
  void _buildConstructor(ConstructorEntity constructor, ir.Constructor node) {
    final sourceInformation = _sourceInformationBuilder.buildCreate(node);
    ClassEntity cls = constructor.enclosingClass;

    if (_inliningStack.isEmpty) {
      _openFunction(constructor,
          functionNode: node.function,
          parameterStructure: constructor.parameterStructure,
          checks: TargetChecks.none);
    }

    // [constructorData.fieldValues] accumulates the field initializer values,
    // which may be overwritten by initializer-list initializers.
    ConstructorData constructorData = ConstructorData();
    _buildInitializers(node, constructorData);

    List<HInstruction> constructorArguments = [];
    // Doing this instead of fieldValues.forEach because we haven't defined the
    // order of the arguments here. We can define that with JElements.
    bool isCustomElement = _nativeData.isNativeOrExtendsNative(cls) &&
        !_nativeData.isJsInteropClass(cls);
    InterfaceType thisType = _elementEnvironment.getThisType(cls);
    List<FieldEntity> fields = [];
    _elementEnvironment.forEachInstanceField(cls,
        (ClassEntity enclosingClass, FieldEntity member) {
      HInstruction? value = constructorData.fieldValues[member];
      FieldAnalysisData fieldData = _fieldAnalysis.getFieldData(member);
      if (value == null) {
        assert(
            fieldData.isInitializedInAllocator ||
                isCustomElement ||
                reporter.hasReportedError,
            'No initializer value for field ${member}');
      } else {
        if (!fieldData.isElided) {
          fields.add(member);
          DartType type = _elementEnvironment.getFieldType(member);
          type = localsHandler.substInContext(type);
          constructorArguments.add(_typeBuilder
              .potentiallyCheckOrTrustTypeOfAssignment(member, value, type));
        }
      }
    });

    _addImplicitInstantiation(thisType);
    List<InterfaceType> instantiatedTypes =
        List<InterfaceType>.from(_currentImplicitInstantiations);

    HInstruction newObject;
    if (isCustomElement) {
      // Bulk assign to the initialized fields.
      newObject = graph.explicitReceiverParameter!;
      // Null guard ensures an error if we are being called from an explicit
      // 'new' of the constructor instead of via an upgrade. It is optimized out
      // if there are field initializers.
      newObject = HNullCheck(newObject,
          _abstractValueDomain.excludeNull(newObject.instructionType))
        ..sourceInformation = sourceInformation;
      add(newObject);
      for (int i = 0; i < fields.length; i++) {
        add(HFieldSet(_abstractValueDomain, fields[i], newObject,
            constructorArguments[i]));
      }
    } else {
      // Create the runtime type information, if needed.
      bool needsTypeArguments =
          closedWorld.rtiNeed.classNeedsTypeArguments(cls);
      if (needsTypeArguments) {
        InterfaceType thisType = _elementEnvironment.getThisType(cls);
        HInstruction typeArgument = _typeBuilder.analyzeTypeArgumentNewRti(
            thisType, sourceElement,
            sourceInformation: sourceInformation);
        constructorArguments.add(typeArgument);
      }
      newObject = HCreate(cls, constructorArguments,
          _abstractValueDomain.createNonNullExact(cls), sourceInformation,
          instantiatedTypes: instantiatedTypes,
          hasRtiInput: needsTypeArguments);

      add(newObject);
    }
    _removeImplicitInstantiation(thisType);

    HInstruction? interceptor;
    // Generate calls to the constructor bodies.
    for (ir.Constructor body in constructorData.constructorChain.reversed) {
      if (_isEmptyStatement(body.function.body)) continue;

      List<HInstruction> bodyCallInputs = [];
      if (isCustomElement) {
        if (interceptor == null) {
          ConstantValue constant = InterceptorConstantValue(cls);
          interceptor = graph.addConstant(constant, closedWorld);
        }
        bodyCallInputs.add(interceptor);
      }
      bodyCallInputs.add(newObject);

      // Pass uncaptured arguments first, captured arguments in a box, then type
      // arguments.

      ConstructorEntity inlinedConstructor = _elementMap.getConstructor(body);

      _inlinedFrom(
          inlinedConstructor, _sourceInformationBuilder.buildCall(body, body),
          () {
        final constructorBody = _elementMap.getConstructorBody(body);

        void handleParameter(ir.VariableDeclaration node,
            {required bool isElided}) {
          if (isElided) return;

          Local parameter = _localsMap.getLocalVariable(node);
          // If [parameter] is boxed, it will be a field in the box passed as
          // the last parameter. So no need to directly pass it.
          if (!localsHandler.isBoxed(parameter)) {
            bodyCallInputs.add(localsHandler.readLocal(parameter));
          }
        }

        // Provide the parameters to the generative constructor body.
        forEachOrderedParameter(_elementMap, constructorBody, handleParameter);

        // If there are locals that escape (i.e. mutated in closures), we pass the
        // box to the constructor.
        CapturedScope scopeData =
            _closureDataLookup.getCapturedScope(constructorBody);
        if (scopeData.requiresContextBox) {
          bodyCallInputs.add(localsHandler.readLocal(scopeData.contextBox!));
        }

        // Pass type arguments.
        ClassEntity inlinedConstructorClass = constructorBody.enclosingClass!;
        if (closedWorld.rtiNeed
            .classNeedsTypeArguments(inlinedConstructorClass)) {
          InterfaceType thisType =
              _elementEnvironment.getThisType(inlinedConstructorClass);
          for (DartType typeVariable in thisType.typeArguments) {
            DartType result = localsHandler.substInContext(typeVariable);
            HInstruction argument =
                _typeBuilder.analyzeTypeArgument(result, sourceElement);
            bodyCallInputs.add(argument);
          }
        }

        if (!isCustomElement && // TODO(13836): Fix inlining.
            _tryInlineMethod(constructorBody, null, null, bodyCallInputs, null,
                node, sourceInformation)) {
          pop();
        } else {
          _invokeConstructorBody(body, bodyCallInputs,
              _sourceInformationBuilder.buildDeclaration(constructor));
        }
      });
    }

    if (_inliningStack.isEmpty) {
      _closeAndGotoExit(
          HReturn(_abstractValueDomain, newObject, sourceInformation));
      _closeFunction();
    } else {
      localsHandler.updateLocal(_returnLocal!, newObject,
          sourceInformation: sourceInformation);
    }
  }

  static bool _isEmptyStatement(ir.Statement? body) {
    if (body is ir.EmptyStatement) return true;
    if (body is ir.Block) return body.statements.every(_isEmptyStatement);
    return false;
  }

  void _invokeConstructorBody(ir.Constructor constructor,
      List<HInstruction> inputs, SourceInformation? sourceInformation) {
    MemberEntity constructorBody = _elementMap.getConstructorBody(constructor);
    HInvokeConstructorBody invoke = HInvokeConstructorBody(
        constructorBody as ConstructorBodyEntity,
        inputs,
        _abstractValueDomain.nonNullType,
        sourceInformation);
    add(invoke);
  }

  /// Sets context for generating code that is the result of inlining
  /// [inlinedTarget].
  void _inlinedFrom(MemberEntity inlinedTarget,
      SourceInformation? callSourceInformation, f()) {
    reporter.withCurrentElement(inlinedTarget, () {
      _enterFrame(inlinedTarget, callSourceInformation);
      var result = f();
      _leaveFrame();
      return result;
    });
  }

  void _ensureTypeVariablesForInitializers(
      ConstructorData constructorData, ClassEntity enclosingClass) {
    if (!constructorData.includedClasses.add(enclosingClass)) return;
    if (_rtiNeed.classNeedsTypeArguments(enclosingClass)) {
      // If [enclosingClass] needs RTI, we have to give a value to its type
      // parameters. For a super constructor call, the type is the supertype
      // of current class. For a redirecting constructor, the type is the
      // current type. [LocalsHandler.substInContext] takes care of both.
      InterfaceType thisType = _elementEnvironment.getThisType(enclosingClass);
      final type = localsHandler.substInContext(thisType) as InterfaceType;
      List<DartType> arguments = type.typeArguments;
      List<DartType> typeVariables = thisType.typeArguments;
      assert(arguments.length == typeVariables.length);
      Iterator<DartType> variables = typeVariables.iterator;
      type.typeArguments.forEach((DartType argument) {
        variables.moveNext();
        final typeVariable = variables.current as TypeVariableType;
        localsHandler.updateLocal(
            localsHandler.getTypeVariableAsLocal(typeVariable),
            _typeBuilder.analyzeTypeArgument(argument, sourceElement));
      });
    }
  }

  /// Collects the values for field initializers for the direct fields of
  /// [clazz].
  void _collectFieldValues(ir.Class clazz, ConstructorData constructorData) {
    ClassEntity cls = _elementMap.getClass(clazz);
    _elementEnvironment.forEachDirectInstanceField(cls, (FieldEntity field) {
      _ensureTypeVariablesForInitializers(
          constructorData, field.enclosingClass!);

      MemberDefinition definition = _elementMap.getMemberDefinition(field);
      late final ir.Field node;
      switch (definition.kind) {
        case MemberKind.regular:
          node = definition.node as ir.Field;
          break;
        default:
          failedAt(field, "Unexpected member definition $definition.");
      }

      bool ignoreAllocatorAnalysis = false;
      if (_nativeData.isNativeOrExtendsNative(cls)) {
        // @Native classes have 'fields' which are really getters/setter.  Do
        // not try to initialize e.g. 'tagName'.
        if (_nativeData.isNativeClass(cls)) return;
        // Fields that survive this test are fields of custom elements.
        ignoreAllocatorAnalysis = true;
      }

      if (ignoreAllocatorAnalysis ||
          !_fieldAnalysis.getFieldData(field).isInitializedInAllocator) {
        final initializer = node.initializer;
        if (initializer == null) {
          constructorData.fieldValues[field] =
              graph.addConstantNull(closedWorld);
        } else {
          // Compile the initializer in the context of the field so we know that
          // class type parameters are accessed as values.
          // TODO(sra): It would be sufficient to know the context was a field
          // initializer.
          _inlinedFrom(
              field, _sourceInformationBuilder.buildAssignment(initializer),
              () {
            initializer.accept(this);
            constructorData.fieldValues[field] = pop();
          });
        }
      }
    });
  }

  static bool _isRedirectingConstructor(ir.Constructor constructor) =>
      constructor.initializers
          .any((initializer) => initializer is ir.RedirectingInitializer);

  /// Collects field initializers all the way up the inheritance chain.
  void _buildInitializers(
      ir.Constructor constructor, ConstructorData constructorData) {
    assert(
        _elementMap.getConstructor(constructor) == _localsMap.currentMember,
        failedAt(
            _localsMap.currentMember,
            'Expected ${_localsMap.currentMember} '
            'but found ${_elementMap.getConstructor(constructor)}.'));
    constructorData.constructorChain.add(constructor);

    if (!_isRedirectingConstructor(constructor)) {
      // Compute values for field initializers, but only if this is not a
      // redirecting constructor, since the target will compute the fields.
      _collectFieldValues(constructor.enclosingClass, constructorData);
    }
    var foundSuperOrRedirectCall = false;
    for (var initializer in constructor.initializers) {
      if (initializer is ir.FieldInitializer) {
        FieldEntity field = _elementMap.getField(initializer.field);
        if (!_fieldAnalysis.getFieldData(field).isInitializedInAllocator) {
          initializer.value.accept(this);
          constructorData.fieldValues[field] = pop();
        }
      } else if (initializer is ir.SuperInitializer) {
        assert(!foundSuperOrRedirectCall);
        foundSuperOrRedirectCall = true;
        _inlineSuperInitializer(initializer, constructorData, constructor);
      } else if (initializer is ir.RedirectingInitializer) {
        assert(!foundSuperOrRedirectCall);
        foundSuperOrRedirectCall = true;
        _inlineRedirectingInitializer(
            initializer, constructorData, constructor);
      } else if (initializer is ir.LocalInitializer) {
        // LocalInitializer is like a let-expression that is in scope for the
        // rest of the initializers.
        ir.VariableDeclaration variable = initializer.variable;
        assert(variable.isFinal);
        variable.initializer!.accept(this);
        HInstruction value = pop();
        // TODO(sra): Apply inferred type information.
        _letBindings[variable] = value;
      } else if (initializer is ir.AssertInitializer) {
        initializer.statement.accept(this);
      } else if (initializer is ir.InvalidInitializer) {
        assert(false, 'ir.InvalidInitializer not handled');
      } else {
        assert(false, 'Unhandled initializer ir.${initializer.runtimeType}');
      }
    }

    if (!foundSuperOrRedirectCall) {
      assert(
          _elementMap.getClass(constructor.enclosingClass) ==
                  _elementMap.commonElements.objectClass ||
              constructor.isExternal ||
              constructor.initializers.any(_ErroneousInitializerVisitor.check),
          'All constructors should have super- or redirecting- initializers,'
          ' except Object()'
          ' ${constructor.initializers}');
    }
  }

  List<HInstruction> _normalizeAndBuildArguments(
      ir.Member member, ir.FunctionNode function, ir.Arguments arguments) {
    List<HInstruction> builtArguments = [];
    var positionalIndex = 0;
    function.positionalParameters.forEach((ir.VariableDeclaration parameter) {
      if (positionalIndex < arguments.positional.length) {
        arguments.positional[positionalIndex++].accept(this);
        builtArguments.add(pop());
      } else {
        builtArguments.add(_defaultValueForParameter(member, parameter));
      }
    });
    // Evaluate named arguments in given order.
    Map<String, HInstruction> namedArguments = _visitNamedArguments(arguments);
    // And add them to `builtArguments` in calling-convention order.
    function.namedParameters.toList()
      ..sort(namedOrdering)
      ..forEach((ir.VariableDeclaration parameter) {
        var argument = namedArguments[parameter.name];
        argument ??= _defaultValueForParameter(member, parameter);
        builtArguments.add(argument);
      });

    return builtArguments;
  }

  /// Inlines the given redirecting [constructor]'s initializers by collecting
  /// its field values and building its constructor initializers. We visit super
  /// constructors all the way up to the [Object] constructor.
  void _inlineRedirectingInitializer(ir.RedirectingInitializer initializer,
      ConstructorData constructorData, ir.Constructor caller) {
    ir.Constructor superOrRedirectConstructor = initializer.target;
    List<HInstruction> arguments = _normalizeAndBuildArguments(
        superOrRedirectConstructor,
        superOrRedirectConstructor.function,
        initializer.arguments);

    // Redirecting initializer already has [localsHandler] bindings for type
    // parameters from the redirecting constructor.

    // For redirecting constructors, the fields will be initialized later by the
    // effective target, so we don't do it here.

    _inlineSuperOrRedirectCommon(initializer, superOrRedirectConstructor,
        arguments, constructorData, caller);
  }

  /// Inlines the given super [constructor]'s initializers by collecting its
  /// field values and building its constructor initializers. We visit super
  /// constructors all the way up to the [Object] constructor.
  void _inlineSuperInitializer(ir.SuperInitializer initializer,
      ConstructorData constructorData, ir.Constructor caller) {
    ir.Constructor target = initializer.target;
    List<HInstruction> arguments = _normalizeAndBuildArguments(
        target, target.function, initializer.arguments);

    ir.Class callerClass = caller.enclosingClass;
    ir.Supertype supertype = callerClass.supertype!;

    // The class of the super-constructor may not be the supertype class. In
    // this case, we must go up the class hierarchy until we reach the class
    // containing the super-constructor.
    while (supertype.classNode != target.enclosingClass) {
      // Fields from unnamed mixin application classes (ie Object&Foo) get
      // "collected" with the regular supertype fields, so we must bind type
      // parameters from both the supertype and the supertype's mixin classes
      // before collecting the field values.
      _collectFieldValues(supertype.classNode, constructorData);
      supertype = supertype.classNode.supertype!;
    }

    _inlineSuperOrRedirectCommon(
        initializer, target, arguments, constructorData, caller);
  }

  void _inlineSuperOrRedirectCommon(
      ir.Initializer initializer,
      ir.Constructor constructor,
      List<HInstruction> arguments,
      ConstructorData constructorData,
      ir.Constructor caller) {
    var index = 0;

    ConstructorEntity element = _elementMap.getConstructor(constructor);
    final oldScopeMember = localsHandler.scopeMember;

    _inlinedFrom(
        element, _sourceInformationBuilder.buildCall(initializer, initializer),
        () {
      void handleParameter(ir.VariableDeclaration node) {
        Local parameter = _localsMap.getLocalVariable(node);
        HInstruction argument = arguments[index++];
        // Because we are inlining the initializer, we must update
        // what was given as parameter. This will be used in case
        // there is a parameter check expression in the initializer.
        parameters[parameter] = argument;
        localsHandler.updateLocal(parameter, argument);
      }

      constructor.function.positionalParameters.forEach(handleParameter);
      constructor.function.namedParameters.toList()
        ..sort(namedOrdering)
        ..forEach(handleParameter);

      _ensureTypeVariablesForInitializers(
          constructorData, element.enclosingClass);

      // Set the locals handler state as if we were inlining the constructor.
      localsHandler.setupScope(element);
      localsHandler.enterScope(_closureDataLookup.getCapturedScope(element),
          _sourceInformationBuilder.buildDeclaration(element));
      _buildInitializers(constructor, constructorData);
    });
    localsHandler.setupScope(oldScopeMember);
  }

  /// Constructs a special signature function for a closure.
  void _buildMethodSignatureNewRti(ir.FunctionNode originalClosureNode) {
    // The signature function has no corresponding ir.Node, so we just use the
    // targetElement to set up the type environment.
    _openFunction(targetElement, checks: TargetChecks.none);
    FunctionType functionType =
        _elementMap.getFunctionType(originalClosureNode);
    HInstruction rti =
        _typeBuilder.analyzeTypeArgumentNewRti(functionType, sourceElement);
    close(HReturn(_abstractValueDomain, rti,
            _sourceInformationBuilder.buildReturn(originalClosureNode)))
        .addSuccessor(graph.exit);
    _closeFunction();
  }

  /// Builds generative constructor body.
  void _buildConstructorBody(ir.Constructor constructor) {
    FunctionEntity constructorBody =
        _elementMap.getConstructorBody(constructor);
    _openFunction(constructorBody,
        functionNode: constructor.function,
        parameterStructure: constructorBody.parameterStructure,
        checks: TargetChecks.none);
    if (!constructorBody.isExternal) {
      constructor.function.body!.accept(this);
    }
    _closeFunction();
  }

  void _buildRecordGetter(
      JRecordGetter getter, RecordGetterDefinition definition) {
    ClassEntity getterClass = getter.enclosingClass!;
    int indexInShape = definition.indexInShape;
    final representation = _recordData.representationForClass(getterClass)!;
    final path = _recordData.pathForAccess(representation.shape, indexInShape);

    // TODO(50081): Attribute all synthetic records code to the nearest class
    // declared in Dart. Worst case, it can all be attributed to the `Record`
    // interface.
    SourceInformation? sourceInformation;

    // Manually set up entry. This does not work...
    //
    //     _openFunction(getter, checks: TargetChecks.none);
    //
    // ...since we don't have a scope model for the localsHandler. What we
    // should have is a lightweight localsHandler for synthetic methods.
    //
    // TODO(51310): Split [_openFunction] into parts which can be used for
    // synthetic methods.

    _prepareEntryBlock();

    // Create a 'this' parameter.
    //
    // Intercepted getters have two parameters (this, receiver) and other
    // getters have one (this). Add them at the beginning of the entry block.

    final typeOfThis = _abstractValueDomain.createNonNullSubclass(getterClass);
    HThis thisInstruction = HThis(null, typeOfThis);
    graph.thisInstruction = thisInstruction;
    graph.entry.addAtEntry(thisInstruction);
    lastAddedParameter = thisInstruction;

    if (_interceptorData.isInterceptedMethod(getter)) {
      SyntheticLocal parameter = localsHandler.createLocal('receiver');
      HParameterValue value = HParameterValue(parameter, typeOfThis);
      graph.explicitReceiverParameter = value;
      graph.entry.addAfter(thisInstruction, value);
      lastAddedParameter = value;
    }

    HInstruction receiver = thisInstruction;

    AbstractValue resultType = _abstractValueDomain.dynamicType;

    if (path.index == null) {
      HFieldGet fieldGet = HFieldGet(
          path.field, receiver, resultType, sourceInformation,
          isAssignable: false);
      push(fieldGet);
    } else {
      HFieldGet fieldGet = HFieldGet(path.field, receiver,
          _abstractValueDomain.constListType, sourceInformation,
          isAssignable: false);
      push(fieldGet);
      final list = pop();
      push(HIndex(
          list, graph.addConstantInt(path.index!, closedWorld), resultType));
    }

    HInstruction value = pop();
    _closeAndGotoExit(HReturn(_abstractValueDomain, value, sourceInformation));
    _closeFunction();
  }

  /// Builds an SSA graph for FunctionNodes, found in FunctionExpressions and
  /// Procedures.
  void _buildFunctionNode(
      FunctionEntity function, ir.FunctionNode functionNode) {
    if (functionNode.asyncMarker != ir.AsyncMarker.Sync) {
      if (functionNode.asyncMarker == ir.AsyncMarker.SyncStar) {
        _buildSyncStarGenerator(function, functionNode);
      } else {
        _buildGenerator(function, functionNode);
      }
      return;
    }

    _openFunction(function,
        functionNode: functionNode,
        parameterStructure: function.parameterStructure,
        checks: _checksForFunction(function));

    if (options.experimentUnreachableMethodsThrow) {
      var emptyParameters = parameters.values.where((parameter) =>
          _abstractValueDomain
              .isEmpty(parameter.instructionType)
              .isDefinitelyTrue);
      if (emptyParameters.length > 0) {
        _addComment('${emptyParameters} inferred as [empty]');
        add(HInvokeStatic(_commonElements.assertUnreachableMethod, [],
            _abstractValueDomain.dynamicType, const []));
        _closeFunction();
        return;
      }
    }
    functionNode.body!.accept(this);
    _closeFunction();
  }

  /// Adds a JavaScript comment to the output. The comment will be omitted in
  /// minified mode.  Each line in [text] is preceded with `//` and indented.
  /// Use sparingly. In order for the comment to be retained it is modeled as
  /// having side effects which will inhibit code motion.
  // TODO(sra): Figure out how to keep comment anchored without effects.
  void _addComment(String text) {
    add(HForeignCode(js.js.statementTemplateYielding(js.Comment(text)),
        _abstractValueDomain.dynamicType, [],
        isStatement: true));
  }

  /// Builds an SSA graph for a sync*/async/async* generator.  We generate a
  /// entry function which tail-calls a body function. The entry contains
  /// per-invocation checks and the body, which is later transformed, contains
  /// the reentrant 'state machine' code.
  void _buildGenerator(FunctionEntity function, ir.FunctionNode functionNode) {
    _openFunction(function,
        functionNode: functionNode,
        parameterStructure: function.parameterStructure,
        checks: _checksForFunction(function));

    // Prepare to tail-call the body.

    // Is 'buildAsyncBody' the best location for the entry?
    var sourceInformation = _sourceInformationBuilder.buildAsyncBody();

    // Forward all the parameters to the body.
    List<HInstruction> inputs = [];
    if (graph.thisInstruction != null) {
      inputs.add(graph.thisInstruction!);
    }
    if (graph.explicitReceiverParameter != null) {
      inputs.add(graph.explicitReceiverParameter!);
    }
    for (Local local in parameters.keys) {
      if (!elidedParameters.contains(local)) {
        inputs.add(localsHandler.readLocal(local));
      }
    }
    for (Local local in _functionTypeParameterLocals) {
      inputs.add(localsHandler.readLocal(local));
    }

    // Add the type parameter for the generator's element type.
    DartType elementType = _elementEnvironment.getAsyncOrSyncStarElementType(
        function.asyncMarker, _returnType!);

    // TODO(sra): [elementType] can contain free type variables that are erased
    // due to no rtiNeed. We will get getter code if these type variables are
    // substituted with an <any> or <erased> type.
    if (elementType.containsFreeTypeVariables) {
      // Type must be computed in the entry function, where the type variables
      // are in scope, and passed to the body function.
      inputs.add(_typeBuilder.analyzeTypeArgumentNewRti(elementType, function));
    } else {
      // Types with no type variables can be emitted as part of the generator,
      // avoiding an extra argument.
      if (_generatedEntryIsEmpty()) {
        // If the entry function is empty (e.g. no argument checks) and the type
        // can be generated in body, 'inline' the body by generating it in
        // place. This works because the subsequent transformation of the code
        // is 'correct' for the empty entry function code.
        graph.needsAsyncRewrite = true;
        graph.asyncElementType = elementType;
        functionNode.body!.accept(this);
        _closeFunction();
        return;
      }
    }

    JGeneratorBody body = _elementMap.getGeneratorBody(function);
    push(HInvokeGeneratorBody(
        body,
        inputs,
        _abstractValueDomain.dynamicType, // TODO: better type.
        sourceInformation));

    _closeAndGotoExit(HReturn(_abstractValueDomain, pop(), sourceInformation));

    _closeFunction();
  }

  /// Builds an SSA graph for a sync* method.  A sync* method is split into an
  /// entry function and a body function. The entry function calls the body
  /// function and wraps the result in an `_SyncStarIterable<T>`. The body
  /// function is a separate entity (GeneratorBodyEntity) that is compiled via
  /// SSA and the transformed into a reentrant state-machine.
  ///
  /// Here we generate the entry function which is approximately like this:
  ///
  ///     Iterable<T> foo(parameters) {
  ///       return _makeSyncStarIterable<T>(foo$body(parameters));
  ///     }
  void _buildSyncStarGenerator(
      FunctionEntity function, ir.FunctionNode functionNode) {
    _openFunction(function,
        functionNode: functionNode,
        parameterStructure: function.parameterStructure,
        checks: _checksForFunction(function));

    // Prepare to call the body generator.

    // Is 'buildAsyncBody' the best location for the entry?
    var sourceInformation = _sourceInformationBuilder.buildAsyncBody();

    // Forward all the parameters to the body.
    List<HInstruction> inputs = [];
    if (graph.thisInstruction != null) {
      inputs.add(graph.thisInstruction!);
    }
    if (graph.explicitReceiverParameter != null) {
      inputs.add(graph.explicitReceiverParameter!);
    }
    for (Local local in parameters.keys) {
      if (!elidedParameters.contains(local)) {
        inputs.add(localsHandler.readLocal(local));
      }
    }
    for (Local local in _functionTypeParameterLocals) {
      inputs.add(localsHandler.readLocal(local));
    }

    JGeneratorBody body = _elementMap.getGeneratorBody(function);
    push(HInvokeGeneratorBody(
        body,
        inputs,
        _abstractValueDomain.dynamicType, // Untyped JavaScript thunk.
        sourceInformation));

    // Call `_makeSyncStarIterable<T>(body)`. This usually gets inlined.

    final elementType = _elementEnvironment.getAsyncOrSyncStarElementType(
        function.asyncMarker, _returnType!);
    FunctionEntity method = _commonElements.syncStarIterableFactory;
    List<HInstruction> arguments = [pop()];
    List<DartType> typeArguments = const [];
    if (_rtiNeed.methodNeedsTypeArguments(method)) {
      typeArguments = [elementType];
      _addTypeArguments(arguments, typeArguments, sourceInformation);
    }
    _pushStaticInvocation(method, arguments,
        _typeInferenceMap.getReturnTypeOf(method), typeArguments,
        sourceInformation: sourceInformation);

    _closeAndGotoExit(HReturn(_abstractValueDomain, pop(), sourceInformation));

    _closeFunction();
  }

  /// Builds an SSA graph for a async/async* generator body.
  void _buildGeneratorBody(
      JGeneratorBody function, ir.FunctionNode functionNode) {
    FunctionEntity entry = function.function;
    _openFunction(entry,
        functionNode: functionNode,
        parameterStructure: function.parameterStructure,
        checks: TargetChecks.none);
    graph.needsAsyncRewrite = true;
    if (!function.elementType.containsFreeTypeVariables) {
      // We can generate the element type in place
      graph.asyncElementType = function.elementType;
    }
    functionNode.body!.accept(this);
    _closeFunction();
  }

  bool _generatedEntryIsEmpty() {
    HBasicBlock block = current!;
    // If `block.id` is not 1 then we generated some control flow.
    if (block.id != 1) return false;
    for (HInstruction? node = block.first; node != null; node = node.next) {
      if (node is HGoto) continue;
      if (node is HLoadType) continue; // Orphaned if check is redundant.
      return false;
    }
    return true;
  }

  void _potentiallyAddFunctionParameterTypeChecks(MemberEntity member,
      ir.FunctionNode function, TargetChecks targetChecks) {
    // Put the type checks in the first successor of the entry,
    // because that is where the type guards will also be inserted.
    // This way we ensure that a type guard will dominate the type
    // check.

    if (targetChecks.checkTypeParameters) {
      _checkTypeVariableBounds(targetElement as FunctionEntity);
    }

    MemberDefinition definition =
        _elementMap.getMemberDefinition(targetElement);
    bool nodeIsConstructorBody = definition.kind == MemberKind.constructorBody;

    void _handleParameter(ir.VariableDeclaration variable) {
      Local local = _localsMap.getLocalVariable(variable);
      if (nodeIsConstructorBody &&
          _closureDataLookup
              .getCapturedScope(targetElement)
              .isBoxedVariable(_localsMap, local)) {
        // If local is boxed, then `variable` will be a field inside the box
        // passed as the last parameter, so no need to update our locals
        // handler or check types at this point.
        return;
      }
      if (elidedParameters.contains(local)) {
        // Elided parameters are initialized to a default value that is
        // statically checked.
        return;
      }

      HInstruction newParameter = localsHandler.readLocal(local);
      DartType type = _getDartTypeIfValid(variable.type);

      if (targetChecks.checkAllParameters ||
          (targetChecks.checkCovariantParameters &&
              (variable.isCovariantByClass ||
                  variable.isCovariantByDeclaration))) {
        newParameter = _typeBuilder.potentiallyCheckOrTrustTypeOfParameter(
            targetElement, newParameter, type);
      } else {
        newParameter = _typeBuilder.trustTypeOfParameter(
            targetElement, newParameter, type);
      }
      // TODO(sra): Hoist out of loop.
      newParameter =
          _potentiallyAssertNotNull(member, variable, newParameter, type);
      localsHandler.updateLocal(local, newParameter);
    }

    function.positionalParameters.forEach(_handleParameter);
    function.namedParameters.toList().forEach(_handleParameter);
  }

  void _checkTypeVariableBounds(FunctionEntity method) {
    if (_rtiNeed.methodNeedsTypeArguments(method) &&
        closedWorld.annotationsData.getParameterCheckPolicy(method).isEmitted) {
      ir.FunctionNode function = getFunctionNode(_elementMap, method)!;
      for (ir.TypeParameter typeParameter in function.typeParameters) {
        Local local = _localsMap.getLocalTypeVariableEntity(_elementMap
            .getTypeVariableType(
                ir.TypeParameterType(typeParameter, ir.Nullability.nonNullable))
            .element);
        HInstruction newParameter = localsHandler.directLocals[local]!;
        DartType bound = _getDartTypeIfValid(typeParameter.bound);
        if (!dartTypes.isTopType(bound)) {
          registry.registerTypeUse(TypeUse.typeVariableBoundCheck(bound));
          // TODO(sigmund): method name here is not minified, should it be?
          _checkTypeBound(newParameter, bound, local.name!, method.name!);
        }
      }
    }
  }

  /// In mixed mode, inserts an assertion of the form `assert(x != null)` for
  /// parameters in opt-in libraries that have a static type that cannot be
  /// nullable under a strong interpretation.
  HInstruction _potentiallyAssertNotNull(MemberEntity member,
      ir.TreeNode context, HInstruction value, DartType type) {
    if (!options.enableNullAssertions) return value;
    if (!_isNonNullableByDefault(context)) return value;
    if (!dartTypes.isNonNullableIfSound(type)) return value;

    // `operator==` is usually augmented to handle a `null`-argument before this
    // test would be inserted.  There are a few exceptions (Object,
    // Interceptor), where the body of the `==` method is designed to handle a
    // `null` argument. In the usual case the null assertion is unnecessary and
    // will be optimized away. In the exception cases a null assertion would be
    // incorrect. Either way we should not do a null-assertion on the parameter
    // of any `operator==` method.
    if (member.name == '==') return value;

    if (options.enableUserAssertions) {
      pushCheckNull(value);
      push(HNot(pop(), _abstractValueDomain.boolType));
      var sourceInformation = _sourceInformationBuilder.buildAssert(context);
      _pushStaticInvocation(
          _commonElements.assertHelper,
          [pop()],
          _typeInferenceMap.getReturnTypeOf(_commonElements.assertHelper),
          const <DartType>[],
          sourceInformation: sourceInformation);
      pop();
      return value;
    } else {
      HInstruction nullCheck = HNullCheck(
          value, _abstractValueDomain.excludeNull(value.instructionType))
        ..sourceInformation = value.sourceInformation;
      add(nullCheck);
      return nullCheck;
    }
  }

  bool _isNonNullableByDefault(ir.TreeNode node) {
    if (node is ir.Library) return node.isNonNullableByDefault;
    return _isNonNullableByDefault(node.parent!);
  }

  /// Builds an SSA graph for FunctionNodes of external methods.
  void _buildExternalFunctionNode(
      FunctionEntity function, ir.FunctionNode functionNode) {
    assert(functionNode.body == null);

    if (closedWorld.nativeData.isNativeMember(targetElement)) {
      _buildExternalNativeFunctionNode(function, functionNode);
      return;
    }

    if (function.name == '==') {
      if (_buildSpecialRuntimeEqualsMethod(function, functionNode)) return;
    }

    // `external` functions in `dart:_foreign_helper` are queued for compilation
    // in a modular or staged compile, so just generate an empty function. The
    // actual call sites for these methods are recognized and replaced, so the
    // method generated here is never called.
    if (_commonElements.isForeignHelper(function)) {
      _openFunction(function,
          functionNode: functionNode,
          parameterStructure: function.parameterStructure,
          checks: _checksForFunction(function));
      _closeFunction();
      return;
    }

    failedAt(CURRENT_ELEMENT_SPANNABLE, 'Unknown external method $function');
  }

  bool _buildSpecialRuntimeEqualsMethod(
      FunctionEntity function, ir.FunctionNode functionNode) {
    assert(function.name == '==');

    if (function.enclosingClass == _commonElements.jsNullClass) {
      _openFunction(function,
          functionNode: functionNode,
          parameterStructure: function.parameterStructure,
          checks: _checksForFunction(function));
      HInstruction instance = graph.addConstantNull(closedWorld);
      HInstruction parameter = parameters.values.first;
      HInstruction value =
          HIdentity(instance, parameter, _abstractValueDomain.boolType);
      add(value);
      _closeAndGotoExit(HReturn(_abstractValueDomain, value,
          _sourceInformationBuilder.buildReturn(functionNode)));
      _closeFunction();
      return true;
    }

    return false;
  }

  /// Builds an SSA graph for FunctionNodes of external methods that are
  /// 'native' or 'js-interop' methods. This produces a graph for a method with
  /// Dart calling conventions that forwards to the actual JavaScript `external`
  /// method.
  void _buildExternalNativeFunctionNode(
      FunctionEntity function, ir.FunctionNode functionNode) {
    bool isJsInterop = closedWorld.nativeData.isJsInteropMember(function);

    _openFunction(function,
        functionNode: functionNode,
        parameterStructure: function.parameterStructure,
        checks: _checksForFunction(function));

    List<HInstruction> inputs = [];
    if (targetElement.isInstanceMember) {
      inputs.add(localsHandler.readThis(
          sourceInformation: _sourceInformationBuilder.buildGet(functionNode)));
    }

    void handleParameter(ir.VariableDeclaration param) {
      Local local = _localsMap.getLocalVariable(param);
      // Convert Dart function to JavaScript function.
      HInstruction argument = localsHandler.readLocal(local);
      ir.DartType type = param.type;
      if (!isJsInterop && type is ir.FunctionType) {
        int arity = type.positionalParameters.length;
        _pushStaticInvocation(
            _commonElements.closureConverter,
            [argument, graph.addConstantInt(arity, closedWorld)],
            _abstractValueDomain.dynamicType,
            const <DartType>[],
            sourceInformation: null);
        argument = pop();
      }
      inputs.add(argument);
    }

    for (int position = 0;
        position < function.parameterStructure.positionalParameters;
        position++) {
      handleParameter(functionNode.positionalParameters[position]);
    }
    if (functionNode.namedParameters.isNotEmpty) {
      List<ir.VariableDeclaration> namedParameters = functionNode
          .namedParameters
          // Filter elided parameters.
          .where((p) =>
              function.parameterStructure.namedParameters.contains(p.name))
          .toList();
      // Sort by file offset to visit parameters in declaration order.
      namedParameters.sort(nativeOrdering);
      namedParameters.forEach(handleParameter);
    }

    NativeBehavior nativeBehavior =
        _nativeData.getNativeMethodBehavior(function);
    AbstractValue returnType =
        _typeInferenceMap.typeFromNativeBehavior(nativeBehavior, closedWorld);

    push(HInvokeExternal(
        targetElement as FunctionEntity, inputs, returnType, nativeBehavior,
        sourceInformation: null));
    HInstruction value = pop();
    // TODO(johnniwinther): Provide source information.
    if (options.nativeNullAssertions) {
      if (_isNonNullableByDefault(functionNode)) {
        DartType type = _getDartTypeIfValid(functionNode.returnType);
        if (dartTypes.isNonNullableIfSound(type) &&
            nodeIsInWebLibrary(functionNode)) {
          push(HNullCheck(value, _abstractValueDomain.excludeNull(returnType),
              sticky: true));
          value = pop();
        }
      }
    }
    if (targetElement.isSetter) {
      _closeAndGotoExit(HGoto(_abstractValueDomain));
    } else {
      _emitReturn(value, _sourceInformationBuilder.buildReturn(functionNode));
    }

    _closeFunction();
  }

  void _addImplicitInstantiation(DartType? type) {
    if (type is InterfaceType) {
      _currentImplicitInstantiations.add(type);
    } else {
      assert(type == null);
    }
  }

  void _removeImplicitInstantiation(DartType? type) {
    if (type != null) {
      _currentImplicitInstantiations.removeLast();
    }
  }

  TargetChecks _checksForFunction(FunctionEntity function) {
    if (!function.isInstanceMember) {
      // Static methods with no tear-off can be generated with no checks.
      final access = closedWorld.getMemberAccess(function);
      if (access != null && access.reads.isEmpty) {
        return TargetChecks.none;
      }
    }
    // TODO(sra): Instance methods can be generated with reduced checks if
    // called only from non-dynamic call-sites.
    return TargetChecks.dynamicChecks;
  }

  void _openFunction(MemberEntity member,
      {ir.FunctionNode? functionNode,
      ParameterStructure? parameterStructure,
      required TargetChecks checks}) {
    Map<Local, AbstractValue> parameterMap = {};
    List<ir.VariableDeclaration> elidedParameters = [];
    Set<Local> elidedParameterSet = Set();
    if (functionNode != null) {
      void handleParameter(ir.VariableDeclaration node,
          {required bool isOptional, required bool isElided}) {
        Local local = _localsMap.getLocalVariable(node);
        if (isElided) {
          elidedParameters.add(node);
          elidedParameterSet.add(local);
        }
        parameterMap[local] =
            _typeInferenceMap.getInferredTypeOfParameter(local);
      }

      forEachOrderedParameterByFunctionNode(
          functionNode, parameterStructure!, handleParameter);

      _returnType = _elementMap.getDartType(functionNode.returnType);
    }

    _prepareEntryBlock();

    localsHandler.startFunction(targetElement, parameterMap, elidedParameterSet,
        _sourceInformationBuilder.buildDeclaration(targetElement),
        isGenerativeConstructorBody: targetElement is ConstructorBodyEntity);

    ir.Member memberContextNode = _elementMap.getMemberContextNode(member)!;
    for (ir.VariableDeclaration node in elidedParameters) {
      Local local = _localsMap.getLocalVariable(node);
      localsHandler.updateLocal(
          local, _defaultValueForParameter(memberContextNode, node));
    }

    _addClassTypeVariablesIfNeeded(member);
    _addFunctionTypeVariablesIfNeeded(member);

    // If [member] is `operator==` we explicitly add a null check at the
    // beginning of the method. This is to avoid having call sites do the null
    // check. The null check is added before the argument type checks since in
    // strong mode, the parameter type might be non-nullable.
    if (member is FunctionEntity && member.name == '==') {
      if (functionNode == null)
        throw StateError("'==' should have functionNode");
      if (!_commonElements.operatorEqHandlesNullArgument(member)) {
        _handleIf(
            visitCondition: () {
              final parameter = parameters.values.first;
              push(HIdentity(parameter, graph.addConstantNull(closedWorld),
                  _abstractValueDomain.boolType));
            },
            visitThen: () {
              _closeAndGotoExit(HReturn(
                  _abstractValueDomain,
                  graph.addConstantBool(false, closedWorld),
                  _sourceInformationBuilder.buildReturn(functionNode)));
            },
            visitElse: null,
            sourceInformation: _sourceInformationBuilder.buildIf(functionNode));
      }
    }

    if (functionNode != null) {
      _potentiallyAddFunctionParameterTypeChecks(member, functionNode, checks);
    }
    _insertCoverageCall(member);
  }

  void _closeFunction() {
    if (!isAborted()) _closeAndGotoExit(HGoto(_abstractValueDomain));
    graph.finalize(_abstractValueDomain);
  }

  @override
  void defaultNode(ir.Node node) {
    throw UnsupportedError('Unhandled node $node (${node.runtimeType})');
  }

  /// Returns the current source element. This is used by the type builder.
  // TODO(efortuna): Update this when we implement inlining.
  // TODO(sra): Re-implement type builder using Kernel types and the
  // `target` for context.
  MemberEntity get sourceElement => _currentFrame!.member;

  @override
  void visitCheckLibraryIsLoaded(ir.CheckLibraryIsLoaded checkLoad) {
    ImportEntity import = _elementMap.getImport(checkLoad.import);
    String loadId = closedWorld.outputUnitData.getImportDeferName(
        _elementMap.getSpannable(targetElement, checkLoad), import);
    HInstruction prefixConstant = graph.addConstantString(loadId, closedWorld);
    _pushStaticInvocation(
        _commonElements.checkDeferredIsLoaded,
        [prefixConstant],
        _typeInferenceMap
            .getReturnTypeOf(_commonElements.checkDeferredIsLoaded),
        const <DartType>[],
        sourceInformation: null);
  }

  @override
  void visitLoadLibrary(ir.LoadLibrary loadLibrary) {
    String loadId = closedWorld.outputUnitData.getImportDeferName(
        _elementMap.getSpannable(targetElement, loadLibrary),
        _elementMap.getImport(loadLibrary.import));

    final priority =
        closedWorld.annotationsData.getLoadLibraryPriorityAt(loadLibrary);
    final flag = priority.index;

    final sourceInformation =
        _sourceInformationBuilder.buildCall(loadLibrary, loadLibrary);

    push(HInvokeStatic(
        _commonElements.loadDeferredLibrary,
        [
          graph.addConstantString(loadId, closedWorld),
          graph.addConstantInt(flag, closedWorld)
        ],
        _abstractValueDomain.nonNullType,
        const <DartType>[],
        targetCanThrow: false)
      ..sourceInformation = sourceInformation);
  }

  @override
  void visitBlock(ir.Block block) {
    assert(!isAborted());
    // [block] can be unreachable at the beginning of a block if an
    // ir.BlockExpression that is a subexpression of an expression that contains
    // a throwing prior subexpression, e.g. `[throw e, {...[]}]`.
    if (!_isReachable) return;

    for (ir.Statement statement in block.statements) {
      statement.accept(this);
      if (!_isReachable) {
        // The block has been aborted by a return or a throw.
        if (stack.isNotEmpty) {
          reporter.internalError(
              NO_LOCATION_SPANNABLE, 'Non-empty instruction stack.');
        }
        return;
      }
    }
    assert(!current!.isClosed());
    if (stack.isNotEmpty) {
      reporter.internalError(
          NO_LOCATION_SPANNABLE, 'Non-empty instruction stack');
    }
  }

  @override
  void visitEmptyStatement(ir.EmptyStatement node) {
    // Empty statement adds no instructions to current block.
  }

  @override
  void visitExpressionStatement(ir.ExpressionStatement node) {
    if (!_isReachable) return;
    ir.Expression expression = node.expression;

    // Handle a `throw` expression in statement-position, with control flow to
    // the exit. (In expression position the throw does not create control-flow
    // out of CFG region for the expression).
    if (expression is ir.Throw &&
        _inliningStack.isEmpty &&
        !_inBlockExpression) {
      _visitThrowExpression(expression.expression);
      _handleInTryStatement();
      final sourceInformation =
          _sourceInformationBuilder.buildThrow(node.expression);
      _closeAndGotoExit(HThrow(_abstractValueDomain, pop(), sourceInformation));
    } else {
      expression.accept(this);
      pop();
    }
  }

  @override
  void visitConstantExpression(ir.ConstantExpression node) {
    ConstantValue value =
        _elementMap.getConstantValue(_memberContextNode!, node)!;
    final sourceInformation = _sourceInformationBuilder.buildGet(node);
    if (!closedWorld.outputUnitData
        .hasOnlyNonDeferredImportPathsToConstant(targetElement, value)) {
      OutputUnit outputUnit =
          closedWorld.outputUnitData.outputUnitForConstant(value);
      final deferredConstant = DeferredGlobalConstantValue(value, outputUnit);
      registry.registerConstantUse(ConstantUse.deferred(deferredConstant));
      stack.add(graph.addDeferredConstant(
          deferredConstant, sourceInformation, closedWorld));
    } else {
      stack.add(graph.addConstant(value, closedWorld,
          sourceInformation: sourceInformation));
    }
  }

  @override
  void visitReturnStatement(ir.ReturnStatement node) {
    final sourceInformation = _sourceInformationBuilder.buildReturn(node);
    HInstruction? value;
    if (node.expression != null) {
      node.expression!.accept(this);
      value = pop();
      if (_currentFrame!.asyncMarker == AsyncMarker.ASYNC) {
        // TODO(johnniwinther): Is this special-casing of async still needed
        // or should we use the general check below?
        /*if (options.enableTypeAssertions &&
            !isValidAsyncReturnType(_returnType)) {
          generateTypeError(
              "Async function returned a Future,"
              " was declared to return a ${_returnType}.",
              sourceInformation);
          pop();
          return;
        }*/
      } else {
        value = _typeBuilder.potentiallyCheckOrTrustTypeOfAssignment(
            _currentFrame!.member, value, _returnType!);
      }
    }
    _handleInTryStatement();
    if (_inliningStack.isEmpty && targetElement.isSetter) {
      if (node.parent is ir.FunctionNode) {
        // An arrow function definition of a setter has a ReturnStatement as a
        // body, e.g. "set foo(x) => this._x = x;". There is no way to access
        // the returned value, so don't emit a return.
        return;
      }
    }
    // TODO(43456): Better unreachable code removal. `_isReachable` removes
    // more code, but also `return`s that pattern-match against more compact
    // arrow functions. The `return`s also help the JavaScript VM.
    // TODO(b/276976255): Using `_isReachable` causes a test failure.
    if (!isAborted()) {
      _emitReturn(value, sourceInformation);
    }
  }

  @override
  void visitForStatement(ir.ForStatement node) {
    assert(_isReachable);
    void buildInitializer() {
      for (ir.VariableDeclaration declaration in node.variables) {
        declaration.accept(this);
      }
    }

    HInstruction buildCondition() {
      if (node.condition == null) {
        return graph.addConstantBool(true, closedWorld);
      }
      node.condition!.accept(this);
      return popBoolified();
    }

    void buildUpdate() {
      for (ir.Expression expression in node.updates) {
        expression.accept(this);
        assert(!isAborted());
        // The result of the update instruction isn't used, and can just
        // be dropped.
        pop();
      }
    }

    void buildBody() {
      node.body.accept(this);
    }

    final jumpTarget = _localsMap.getJumpTargetForFor(node);
    _loopHandler.handleLoop(
        node,
        _closureDataLookup.getCapturedLoopScope(node),
        jumpTarget,
        buildInitializer,
        buildCondition,
        buildUpdate,
        buildBody,
        _sourceInformationBuilder.buildLoop(node));
  }

  @override
  void visitForInStatement(ir.ForInStatement node) {
    if (node.isAsync) {
      _buildAsyncForIn(node);
    } else if (_typeInferenceMap.isJsIndexableIterator(
        node, _abstractValueDomain)) {
      // If the expression being iterated over is a JS indexable type, we can
      // generate an optimized version of for-in that uses indexing.
      _buildForInIndexable(node);
    } else {
      _buildForInIterator(node);
    }
  }

  /// Builds the graph for a for-in node with an indexable expression.
  ///
  /// In this case we build:
  ///
  ///    int end = a.length;
  ///    for (int i = 0;
  ///         i < a.length;
  ///         checkConcurrentModificationError(a.length == end, a), ++i) {
  ///      <declaredIdentifier> = a[i];
  ///      <body>
  ///    }
  void _buildForInIndexable(ir.ForInStatement node) {
    SyntheticLocal indexVariable = localsHandler.createLocal('_i');

    // These variables are shared by initializer, condition, body and update.
    late final HInstruction array; // Set in buildInitializer.
    late final bool isFixed; // Set in buildInitializer.
    HInstruction? originalLength; // Set for growable lists.

    HInstruction buildGetLength(SourceInformation? sourceInformation) {
      HGetLength result = HGetLength(
          array, _abstractValueDomain.positiveIntType,
          isAssignable: !isFixed)
        ..sourceInformation = sourceInformation;
      add(result);
      return result;
    }

    void buildConcurrentModificationErrorCheck() {
      if (originalLength == null) return;
      // The static call checkConcurrentModificationError() is expanded in
      // codegen to:
      //
      //     array.length == _end || throwConcurrentModificationError(array)
      //
      final sourceInformation =
          _sourceInformationBuilder.buildForInMoveNext(node);
      HInstruction length = buildGetLength(sourceInformation);
      push(HIdentity(length, originalLength!, _abstractValueDomain.boolType)
        ..sourceInformation = sourceInformation);
      _pushStaticInvocation(
          _commonElements.checkConcurrentModificationError,
          [pop(), array],
          _typeInferenceMap.getReturnTypeOf(
              _commonElements.checkConcurrentModificationError),
          const <DartType>[],
          sourceInformation: sourceInformation);
      pop();
    }

    void buildInitializer() {
      final sourceInformation =
          _sourceInformationBuilder.buildForInIterator(node);

      node.iterable.accept(this);
      array = pop();
      isFixed = _abstractValueDomain
          .isFixedLengthJsIndexable(array.instructionType)
          .isDefinitelyTrue;
      localsHandler.updateLocal(
          indexVariable, graph.addConstantInt(0, closedWorld),
          sourceInformation: sourceInformation);
      originalLength = buildGetLength(sourceInformation);
    }

    HInstruction buildCondition() {
      final sourceInformation =
          _sourceInformationBuilder.buildForInMoveNext(node);
      HInstruction index = localsHandler.readLocal(indexVariable,
          sourceInformation: sourceInformation);
      HInstruction length = buildGetLength(sourceInformation);
      HInstruction compare = HLess(index, length, _abstractValueDomain.boolType)
        ..sourceInformation = sourceInformation;
      add(compare);
      return compare;
    }

    void buildBody() {
      // If we had mechanically inlined ArrayIterator.moveNext(), it would have
      // inserted the ConcurrentModificationError check as part of the
      // condition.  It is not necessary on the first iteration since there is
      // no code between calls to `get iterator` and `moveNext`, so the test is
      // moved to the loop update.

      // Find a type for the element. Use the element type of the indexer of the
      // array, as this is stronger than the Iterator's `get current` type, for
      // example, `get current` includes null.
      // TODO(sra): The element type of a container type mask might be better.
      AbstractValue type = _typeInferenceMap.inferredIndexType(node);

      final sourceInformation =
          _sourceInformationBuilder.buildForInCurrent(node);
      HInstruction index = localsHandler.readLocal(indexVariable,
          sourceInformation: sourceInformation);
      // No bound check is necessary on indexer as it is immediately guarded by
      // the condition.
      HInstruction value = HIndex(array, index, type)
        ..sourceInformation = sourceInformation;
      add(value);

      Local loopVariableLocal = _localsMap.getLocalVariable(node.variable);
      localsHandler.updateLocal(loopVariableLocal, value,
          sourceInformation: sourceInformation);
      // Hint to name loop value after name of loop variable.
      if (loopVariableLocal is! SyntheticLocal) {
        value.sourceElement ??= loopVariableLocal;
      }

      node.body.accept(this);
    }

    void buildUpdate() {
      // See buildBody as to why we check here.
      buildConcurrentModificationErrorCheck();

      // TODO(sra): It would be slightly shorter to generate `a[i++]` in the
      // body (and that more closely follows what an inlined iterator would do)
      // but the code is horrible as `i+1` is carried around the loop in an
      // additional variable.
      final sourceInformation = _sourceInformationBuilder.buildForInSet(node);
      HInstruction index = localsHandler.readLocal(indexVariable,
          sourceInformation: sourceInformation);
      HInstruction one = graph.addConstantInt(1, closedWorld);
      HInstruction addInstruction =
          HAdd(index, one, _abstractValueDomain.positiveIntType)
            ..sourceInformation = sourceInformation;
      add(addInstruction);
      localsHandler.updateLocal(indexVariable, addInstruction,
          sourceInformation: sourceInformation);
    }

    _loopHandler.handleLoop(
        node,
        _closureDataLookup.getCapturedLoopScope(node),
        _localsMap.getJumpTargetForForIn(node),
        buildInitializer,
        buildCondition,
        buildUpdate,
        buildBody,
        _sourceInformationBuilder.buildLoop(node));
  }

  void _buildForInIterator(ir.ForInStatement node) {
    // Generate a structure equivalent to:
    //   Iterator<E> $iter = <iterable>.iterator;
    //   while ($iter.moveNext()) {
    //     <variable> = $iter.current;
    //     <body>
    //   }

    // The iterator is shared between initializer, condition and body.
    late final HInstruction iterator;
    StaticType iteratorType = _getStaticForInIteratorType(node);

    void buildInitializer() {
      final receiverType = _typeInferenceMap.typeOfIterator(node);
      node.iterable.accept(this);
      HInstruction receiver = pop();
      _pushDynamicInvocation(
          node,
          _getStaticType(node.iterable),
          receiverType,
          Selectors.iterator,
          [receiver],
          const <DartType>[],
          _sourceInformationBuilder.buildForInIterator(node));
      iterator = pop();
    }

    HInstruction buildCondition() {
      final receiverType = _typeInferenceMap.typeOfIteratorMoveNext(node);
      _pushDynamicInvocation(
          node,
          iteratorType,
          receiverType,
          Selectors.moveNext,
          [iterator],
          const <DartType>[],
          _sourceInformationBuilder.buildForInMoveNext(node));
      return popBoolified();
    }

    void buildBody() {
      final sourceInformation =
          _sourceInformationBuilder.buildForInCurrent(node);
      final receiverType = _typeInferenceMap.typeOfIteratorCurrent(node);
      _pushDynamicInvocation(node, iteratorType, receiverType,
          Selectors.current, [iterator], const <DartType>[], sourceInformation);

      Local loopVariableLocal = _localsMap.getLocalVariable(node.variable);
      HInstruction value = _typeBuilder.potentiallyCheckOrTrustTypeOfAssignment(
          _currentFrame!.member,
          pop(),
          _getDartTypeIfValid(node.variable.type));
      localsHandler.updateLocal(loopVariableLocal, value,
          sourceInformation: sourceInformation);
      // Hint to name loop value after name of loop variable.
      if (loopVariableLocal is! SyntheticLocal) {
        value.sourceElement ??= loopVariableLocal;
      }
      node.body.accept(this);
    }

    _loopHandler.handleLoop(
        node,
        _closureDataLookup.getCapturedLoopScope(node),
        _localsMap.getJumpTargetForForIn(node),
        buildInitializer,
        buildCondition,
        () {},
        buildBody,
        _sourceInformationBuilder.buildLoop(node));
  }

  void _buildAsyncForIn(ir.ForInStatement node) {
    // The async-for is implemented with a StreamIterator.
    HInstruction streamIterator;

    node.iterable.accept(this);

    List<HInstruction> arguments = [pop()];
    ClassEntity cls = _commonElements.streamIterator;
    DartType typeArg = _elementMap.getDartType(node.variable.type);
    final instanceType =
        localsHandler.substInContext(dartTypes.interfaceType(cls, [typeArg]))
            as InterfaceType;
    // TODO(johnniwinther): This should be the exact type.
    StaticType staticInstanceType =
        StaticType(instanceType, ClassRelation.subtype);
    _addImplicitInstantiation(instanceType);
    final sourceInformation =
        _sourceInformationBuilder.buildForInIterator(node);
    // TODO(johnniwinther): Pass type arguments to constructors like calling
    // a generic method.
    if (_rtiNeed.classNeedsTypeArguments(cls)) {
      _addTypeArguments(arguments, [typeArg], sourceInformation);
    }
    ConstructorEntity constructor = _commonElements.streamIteratorConstructor;
    _pushStaticInvocation(constructor, arguments,
        _typeInferenceMap.getReturnTypeOf(constructor), const <DartType>[],
        instanceType: instanceType, sourceInformation: sourceInformation);

    streamIterator = pop();

    void buildInitializer() {}

    HInstruction buildCondition() {
      final receiverType = _typeInferenceMap.typeOfIteratorMoveNext(node);
      _pushDynamicInvocation(
          node,
          staticInstanceType,
          receiverType,
          Selectors.moveNext,
          [streamIterator],
          const <DartType>[],
          _sourceInformationBuilder.buildForInMoveNext(node));
      HInstruction future = pop();
      push(HAwait(future, _abstractValueDomain.dynamicType));
      return popBoolified();
    }

    void buildBody() {
      final receiverType = _typeInferenceMap.typeOfIteratorCurrent(node);
      _pushDynamicInvocation(
          node,
          staticInstanceType,
          receiverType,
          Selectors.current,
          [streamIterator],
          const <DartType>[],
          _sourceInformationBuilder.buildForInIterator(node));
      localsHandler.updateLocal(
          _localsMap.getLocalVariable(node.variable), pop());
      node.body.accept(this);
    }

    void buildUpdate() {}

    // Creates a synthetic try/finally block in case anything async goes amiss.
    TryCatchFinallyBuilder tryBuilder =
        TryCatchFinallyBuilder(this, _sourceInformationBuilder.buildLoop(node));
    // Build fake try body:
    _loopHandler.handleLoop(
        node,
        _closureDataLookup.getCapturedLoopScope(node),
        _localsMap.getJumpTargetForForIn(node),
        buildInitializer,
        buildCondition,
        buildUpdate,
        buildBody,
        _sourceInformationBuilder.buildLoop(node));

    void finalizerFunction() {
      _pushDynamicInvocation(
          node,
          staticInstanceType,
          null,
          Selectors.cancel,
          [streamIterator],
          const <DartType>[],
          _sourceInformationBuilder
              // ignore:deprecated_member_use_from_same_package
              .buildGeneric(node));
      add(HAwait(pop(), _abstractValueDomain.dynamicType));
    }

    tryBuilder
      ..closeTryBody()
      ..buildFinallyBlock(finalizerFunction)
      ..cleanUp();
  }

  HInstruction _callSetRuntimeTypeInfo(HInstruction typeInfo,
      HInstruction newObject, SourceInformation? sourceInformation) {
    // Set the runtime type information on the object.
    FunctionEntity typeInfoSetterFn = _commonElements.setArrayType;
    // TODO(efortuna): Insert source information in this static invocation.
    _pushStaticInvocation(typeInfoSetterFn, [newObject, typeInfo],
        _abstractValueDomain.dynamicType, const <DartType>[],
        sourceInformation: sourceInformation);

    // The new object will now be referenced through the
    // `setArrayType` call. We therefore set the type of that
    // instruction to be of the object's type.
    assert(
        stack.last is HInvokeStatic || stack.last == newObject,
        failedAt(
            CURRENT_ELEMENT_SPANNABLE,
            "Unexpected `stack.last`: Found ${stack.last}, "
            "expected ${newObject} or an HInvokeStatic. "
            "State: typeInfo=$typeInfo, stack=$stack."));
    stack.last.instructionType = newObject.instructionType;
    return pop();
  }

  @override
  void visitWhileStatement(ir.WhileStatement node) {
    assert(_isReachable);
    HInstruction buildCondition() {
      node.condition.accept(this);
      return popBoolified();
    }

    _loopHandler.handleLoop(
        node,
        _closureDataLookup.getCapturedLoopScope(node),
        _localsMap.getJumpTargetForWhile(node),
        () {},
        buildCondition,
        () {}, () {
      node.body.accept(this);
    }, _sourceInformationBuilder.buildLoop(node));
  }

  @override
  void visitDoStatement(ir.DoStatement node) {
    final sourceInformation = _sourceInformationBuilder.buildLoop(node);
    // TODO(efortuna): I think this can be rewritten using
    // LoopHandler.handleLoop with some tricks about when the "update" happens.
    LocalsHandler savedLocals = LocalsHandler.from(localsHandler);
    CapturedLoopScope loopClosureInfo =
        _closureDataLookup.getCapturedLoopScope(node);
    localsHandler.startLoop(loopClosureInfo, sourceInformation);
    final target = _localsMap.getJumpTargetForDo(node);
    JumpHandler jumpHandler = _loopHandler.beginLoopHeader(node, target);
    final currentBlock = current!;
    final loopInfo = currentBlock.loopInformation!;
    HBasicBlock loopEntryBlock = currentBlock;
    HBasicBlock bodyEntryBlock = currentBlock;
    bool hasContinues = target != null && target.isContinueTarget;
    if (hasContinues) {
      // Add extra block to hang labels on.
      // It doesn't currently work if they are on the same block as the
      // HLoopInfo. The handling of HLabeledBlockInformation will visit a
      // SubGraph that starts at the same block again, so the HLoopInfo is
      // either handled twice, or it's handled after the labeled block info,
      // both of which generate the wrong code.
      // Using a separate block is just a simple workaround.
      bodyEntryBlock = openNewBlock();
    }
    localsHandler.enterLoopBody(loopClosureInfo, sourceInformation);
    node.body.accept(this);

    // If there are no continues we could avoid the creation of the condition
    // block. This could also lead to a block having multiple entries and exits.
    HBasicBlock bodyExitBlock;
    bool isAbortingBody = false;
    if (current != null) {
      bodyExitBlock = close(HGoto(_abstractValueDomain));
    } else {
      isAbortingBody = true;
      bodyExitBlock = lastOpenedBlock;
    }

    SubExpression conditionExpression;
    bool loopIsDegenerate = isAbortingBody && !hasContinues;
    if (!loopIsDegenerate) {
      HBasicBlock conditionBlock = addNewBlock();

      List<LocalsHandler> continueHandlers = <LocalsHandler>[];
      jumpHandler
          .forEachContinue((HContinue instruction, LocalsHandler locals) {
        instruction.block!.addSuccessor(conditionBlock);
        continueHandlers.add(locals);
      });

      if (!isAbortingBody) {
        bodyExitBlock.addSuccessor(conditionBlock);
      }

      if (!continueHandlers.isEmpty) {
        if (!isAbortingBody) continueHandlers.add(localsHandler);
        localsHandler =
            savedLocals.mergeMultiple(continueHandlers, conditionBlock);
        SubGraph bodyGraph = SubGraph(bodyEntryBlock, bodyExitBlock);
        List<LabelDefinition> labels = jumpHandler.labels;
        HSubGraphBlockInformation bodyInfo =
            HSubGraphBlockInformation(bodyGraph);
        HLabeledBlockInformation info;
        if (!labels.isEmpty) {
          info = HLabeledBlockInformation(bodyInfo, labels, isContinue: true);
        } else {
          info = HLabeledBlockInformation.implicit(bodyInfo, target,
              isContinue: true);
        }
        bodyEntryBlock.setBlockFlow(info, conditionBlock);
      }
      open(conditionBlock);

      node.condition.accept(this);
      assert(!isAborted());
      HInstruction conditionInstruction = popBoolified();
      HBasicBlock conditionEndBlock = close(HLoopBranch(_abstractValueDomain,
          conditionInstruction, HLoopBranch.DO_WHILE_LOOP));

      HBasicBlock avoidCriticalEdge = addNewBlock();
      conditionEndBlock.addSuccessor(avoidCriticalEdge);
      open(avoidCriticalEdge);
      close(HGoto(_abstractValueDomain));
      avoidCriticalEdge.addSuccessor(loopEntryBlock); // The back-edge.

      conditionExpression = SubExpression(conditionBlock, conditionEndBlock);

      // Avoid a critical edge from the condition to the loop-exit body.
      HBasicBlock conditionExitBlock = addNewBlock();
      open(conditionExitBlock);
      close(HGoto(_abstractValueDomain));
      conditionEndBlock.addSuccessor(conditionExitBlock);

      _loopHandler.endLoop(
          loopEntryBlock, conditionExitBlock, jumpHandler, localsHandler);

      loopEntryBlock.postProcessLoopHeader();
      SubGraph bodyGraph = SubGraph(loopEntryBlock, bodyExitBlock);
      final newLoopInfo = loopEntryBlock.loopInformation!;
      HLoopBlockInformation loopBlockInfo = HLoopBlockInformation(
          HLoopBlockInformation.DO_WHILE_LOOP,
          null,
          wrapExpressionGraph(conditionExpression),
          wrapStatementGraph(bodyGraph),
          null,
          newLoopInfo.target,
          newLoopInfo.labels,
          sourceInformation);
      loopEntryBlock.setBlockFlow(loopBlockInfo, current);
      loopInfo.loopBlockInformation = loopBlockInfo;
    } else {
      // Since the loop has no back edge, we remove the loop information on the
      // header.
      loopEntryBlock.loopInformation = null;

      if (jumpHandler.hasAnyBreak()) {
        // Null branchBlock because the body of the do-while loop always aborts,
        // so we never get to the condition.
        _loopHandler.endLoop(loopEntryBlock, null, jumpHandler, localsHandler);

        // Since the body of the loop has a break, we attach a synthesized label
        // to the body.
        SubGraph bodyGraph = SubGraph(bodyEntryBlock, bodyExitBlock);
        JumpTarget target = _localsMap.getJumpTargetForDo(node)!;
        final label = target.addLabel('loop', isBreakTarget: true);
        HLabeledBlockInformation info = HLabeledBlockInformation(
            HSubGraphBlockInformation(bodyGraph), <LabelDefinition>[label]);
        loopEntryBlock.setBlockFlow(info, current);
        jumpHandler.forEachBreak((HBreak breakInstruction, _) {
          HBasicBlock block = breakInstruction.block!;
          block.addAtExit(
              HBreak.toLabel(_abstractValueDomain, label, sourceInformation));
          block.remove(breakInstruction);
        });
      }
    }
    jumpHandler.close();
  }

  @override
  void visitIfStatement(ir.IfStatement node) {
    _handleIf(
        visitCondition: () => node.condition.accept(this),
        visitThen: () => node.then.accept(this),
        visitElse: () => node.otherwise?.accept(this),
        sourceInformation: _sourceInformationBuilder.buildIf(node));
  }

  void _handleIf(
      {ir.Node? node,
      required void visitCondition(),
      required void visitThen(),
      void visitElse()?,
      SourceInformation? sourceInformation}) {
    SsaBranchBuilder branchBuilder = SsaBranchBuilder(this,
        node == null ? null : _elementMap.getSpannable(targetElement, node));
    branchBuilder.handleIf(visitCondition, visitThen, visitElse,
        sourceInformation: sourceInformation);
  }

  @override
  void visitAsExpression(ir.AsExpression node) {
    // Recognize these special cases, where expression e has static type `T?`:
    //
    //     e as T
    //     (e as dynamic) as T
    //
    // These patterns can only fail if `e` results in a `null` value.  The
    // second pattern occurs when `e as dynamic` is used get an implicit
    // downcast in order to make use of the different policies for explicit and
    // implicit downcasts.
    //
    // The pattern match is syntactic which ensures the type bindings are
    // consistent, i.e. from the same instance of a type variable scope.
    ir.Expression operand = _skipCastsToDynamic(node.operand);
    operand.accept(this);

    bool isNullRemovalPattern = false;

    StaticType operandType = _getStaticType(operand);
    DartType type = _elementMap.getDartType(node.type);
    if (!node.isCovarianceCheck) {
      if (_elementMap.types.isSubtype(operandType.type, type)) {
        // Skip unneeded casts.
        return;
      }
      if (_elementMap.types
          .isSubtype(operandType.type, _elementMap.types.nullableType(type))) {
        isNullRemovalPattern = true;
      }
    }

    final sourceInformation = _sourceInformationBuilder.buildAs(node);
    HInstruction expressionInstruction = pop();

    if (node.type is ir.InvalidType) {
      _generateTypeError('invalid type', sourceInformation);
      return;
    }

    CheckPolicy policy;
    final currentFrame = _currentFrame!;
    if (node.isTypeError) {
      policy = closedWorld.annotationsData
          .getImplicitDowncastCheckPolicy(currentFrame.member);
    } else {
      policy = closedWorld.annotationsData
          .getExplicitCastCheckPolicy(currentFrame.member);
    }

    if (!policy.isEmitted) {
      stack.add(expressionInstruction);
      return;
    }

    void generateCheck() {
      HInstruction converted = _typeBuilder.buildAsCheck(
          expressionInstruction, localsHandler.substInContext(type),
          isTypeError: node.isTypeError, sourceInformation: sourceInformation);
      if (converted != expressionInstruction) {
        add(converted);
      }
      stack.add(converted);
    }

    if (isNullRemovalPattern) {
      // Generate a conditional to test only `null` values:
      //
      //     temp = e;
      //     temp == null ? temp as T : temp
      SsaBranchBuilder(this).handleConditional(
          () {
            push(HIdentity(
                expressionInstruction,
                graph.addConstantNull(closedWorld),
                _abstractValueDomain.boolType));
          },
          generateCheck,
          () {
            stack.add(expressionInstruction);
          });
    } else {
      generateCheck();
    }
  }

  static ir.Expression _skipCastsToDynamic(ir.Expression node) {
    if (node is ir.AsExpression && node.type is ir.DynamicType) {
      return _skipCastsToDynamic(node.operand);
    }
    return node;
  }

  @override
  void visitNullCheck(ir.NullCheck node) {
    node.operand.accept(this);
    HInstruction expression = pop();
    final sourceInformation = _sourceInformationBuilder.buildUnary(node);
    push(HNullCheck(expression,
        _abstractValueDomain.excludeNull(expression.instructionType))
      ..sourceInformation = sourceInformation);
  }

  void _generateError(FunctionEntity function, String message,
      AbstractValue typeMask, SourceInformation? sourceInformation) {
    HInstruction errorMessage = graph.addConstantString(message, closedWorld);
    _pushStaticInvocation(
        function, [errorMessage], typeMask, const <DartType>[],
        sourceInformation: sourceInformation);
  }

  void _generateTypeError(
      String message, SourceInformation? sourceInformation) {
    _generateError(
        _commonElements.throwTypeError,
        message,
        _typeInferenceMap.getReturnTypeOf(_commonElements.throwTypeError),
        sourceInformation);
  }

  void _generateUnsupportedError(
      String message, SourceInformation? sourceInformation) {
    _generateError(
        _commonElements.throwUnsupportedError,
        message,
        _typeInferenceMap
            .getReturnTypeOf(_commonElements.throwUnsupportedError),
        sourceInformation);
  }

  @override
  void visitAssertStatement(ir.AssertStatement node) {
    if (!options.enableUserAssertions) return;
    var sourceInformation = _sourceInformationBuilder.buildAssert(node);
    if (node.message == null) {
      node.condition.accept(this);
      _pushStaticInvocation(
          _commonElements.assertHelper,
          [pop()],
          _typeInferenceMap.getReturnTypeOf(_commonElements.assertHelper),
          const <DartType>[],
          sourceInformation: sourceInformation);
      pop();
      return;
    }

    // if (assertTest(condition)) assertThrow(message);
    void buildCondition() {
      node.condition.accept(this);
      _pushStaticInvocation(
          _commonElements.assertTest,
          [pop()],
          _typeInferenceMap.getReturnTypeOf(_commonElements.assertTest),
          const <DartType>[],
          sourceInformation: sourceInformation);
    }

    void fail() {
      node.message!.accept(this);
      _pushStaticInvocation(
          _commonElements.assertThrow,
          [pop()],
          _typeInferenceMap.getReturnTypeOf(_commonElements.assertThrow),
          const <DartType>[],
          sourceInformation: sourceInformation);
      pop();
    }

    _handleIf(visitCondition: buildCondition, visitThen: fail);
  }

  /// Creates a [JumpHandler] for a statement. The node must be a jump
  /// target. If there are no breaks or continues targeting the statement,
  /// a special "null handler" is returned.
  ///
  /// [isLoopJump] is true when the jump handler is for a loop. This is used
  /// to distinguish the synthesized loop created for a switch statement with
  /// continue statements from simple switch statements.
  JumpHandler createJumpHandler(ir.TreeNode node, JumpTarget? target,
      {bool isLoopJump = false}) {
    if (target == null) {
      // No breaks or continues to this node.
      return NullJumpHandler(reporter);
    }
    if (isLoopJump && node is ir.SwitchStatement) {
      return KernelSwitchCaseJumpHandler(this, target, node, _localsMap);
    }

    return JumpHandler(this, target);
  }

  @override
  void visitBreakStatement(ir.BreakStatement node) {
    assert(!isAborted());
    _handleInTryStatement();
    JumpTarget target = _localsMap.getJumpTargetForBreak(node);
    JumpHandler handler = jumpTargets[target]!;
    final sourceInformation = _sourceInformationBuilder.buildGoto(node);
    if (_localsMap.generateContinueForBreak(node)) {
      if (handler.labels.isNotEmpty) {
        handler.generateContinue(sourceInformation, handler.labels.first);
      } else {
        handler.generateContinue(sourceInformation);
      }
    } else {
      if (handler.labels.isNotEmpty) {
        handler.generateBreak(sourceInformation, handler.labels.first);
      } else {
        handler.generateBreak(sourceInformation);
      }
    }
  }

  @override
  void visitLabeledStatement(ir.LabeledStatement node) {
    ir.Statement body = node.body;
    if (JumpVisitor.canBeBreakTarget(body)) {
      // loops and switches handle breaks on their own
      body.accept(this);
      return;
    }
    final jumpTarget = _localsMap.getJumpTargetForLabel(node);
    if (jumpTarget == null) {
      // The label is not needed.
      body.accept(this);
      return;
    }

    JumpHandler handler = createJumpHandler(node, jumpTarget);

    LocalsHandler beforeLocals = LocalsHandler.from(localsHandler);

    HBasicBlock newBlock = openNewBlock();
    body.accept(this);
    SubGraph bodyGraph = SubGraph(newBlock, lastOpenedBlock);

    // Create join block only if reached, otherwise it won't have a dominator.
    late final HBasicBlock joinBlock = graph.addNewBlock();
    List<LocalsHandler> breakHandlers = [];
    handler.forEachBreak((HBreak breakInstruction, LocalsHandler locals) {
      breakInstruction.block!.addSuccessor(joinBlock);
      breakHandlers.add(locals);
    });

    if (!isAborted()) {
      goto(current!, joinBlock);
      breakHandlers.add(localsHandler);
    }

    if (breakHandlers.isNotEmpty) {
      open(joinBlock);
      localsHandler = beforeLocals.mergeMultiple(breakHandlers, joinBlock);

      // There was at least one reachable break, so the label is needed.
      newBlock.setBlockFlow(
          HLabeledBlockInformation(
              HSubGraphBlockInformation(bodyGraph), handler.labels),
          joinBlock);
    }
    handler.close();
  }

  /// Loop through the cases in a switch and create a mapping of case
  /// expressions to constants.
  Map<ir.Expression, ConstantValue> _buildSwitchCaseConstants(
      ir.SwitchStatement switchStatement) {
    Map<ir.Expression, ConstantValue> constants = {};
    for (ir.SwitchCase switchCase in switchStatement.cases) {
      for (ir.Expression caseExpression in switchCase.expressions) {
        final constant =
            _elementMap.getConstantValue(_memberContextNode!, caseExpression)!;
        constants[caseExpression] = constant;
      }
    }
    return constants;
  }

  @override
  void visitContinueSwitchStatement(ir.ContinueSwitchStatement node) {
    _handleInTryStatement();
    JumpTarget target = _localsMap.getJumpTargetForContinueSwitch(node);
    final handler = jumpTargets[target]!;
    assert(target.labels.isNotEmpty);
    handler.generateContinue(
        _sourceInformationBuilder.buildGoto(node), target.labels.first);
  }

  @override
  void visitSwitchStatement(ir.SwitchStatement node) {
    final sourceInformation = _sourceInformationBuilder.buildSwitch(node);
    // The switch case indices must match those computed in
    // [KernelSwitchCaseJumpHandler].
    bool hasContinue = false;
    Map<ir.SwitchCase, int> caseIndex = {};
    int switchIndex = 1;
    bool hasDefault = false;
    for (ir.SwitchCase switchCase in node.cases) {
      if (_isDefaultCase(switchCase)) {
        hasDefault = true;
      }
      if (SwitchContinueAnalysis.containsContinue(switchCase.body)) {
        hasContinue = true;
      }
      caseIndex[switchCase] = switchIndex;
      switchIndex++;
    }

    JumpHandler jumpHandler =
        createJumpHandler(node, _localsMap.getJumpTargetForSwitch(node));
    if (!hasContinue) {
      // If the switch statement has no switch cases targeted by continue
      // statements we encode the switch statement directly.
      _buildSimpleSwitchStatement(node, jumpHandler, sourceInformation);
    } else {
      _buildComplexSwitchStatement(
          node, jumpHandler, caseIndex, hasDefault, sourceInformation);
    }
  }

  /// Helper for building switch statements.
  static bool _isDefaultCase(ir.SwitchCase? switchCase) =>
      switchCase == null || switchCase.isDefault;

  /// Helper for building switch statements.
  HInstruction _buildExpression(ir.SwitchStatement switchStatement) {
    switchStatement.expression.accept(this);
    return pop();
  }

  /// Helper method for creating the list of constants that make up the
  /// switch case branches.
  List<ConstantValue> _getSwitchConstants(
      ir.SwitchStatement parentSwitch, ir.SwitchCase? switchCase) {
    Map<ir.Expression, ConstantValue> constantsLookup =
        _buildSwitchCaseConstants(parentSwitch);
    List<ConstantValue> constantList = [];
    if (switchCase != null) {
      for (var expression in switchCase.expressions) {
        constantList.add(constantsLookup[expression]!);
      }
    }
    return constantList;
  }

  /// Builds a simple switch statement which does not handle uses of continue
  /// statements to labeled switch cases.
  void _buildSimpleSwitchStatement(ir.SwitchStatement switchStatement,
      JumpHandler jumpHandler, SourceInformation? sourceInformation) {
    void buildSwitchCase(ir.SwitchCase? switchCase) {
      switchCase!.body.accept(this);
    }

    _handleSwitch(
        switchStatement,
        jumpHandler,
        _buildExpression,
        switchStatement.cases,
        _getSwitchConstants,
        _isDefaultCase,
        buildSwitchCase,
        sourceInformation);
    jumpHandler.close();
  }

  /// Builds a switch statement that can handle arbitrary uses of continue
  /// statements to labeled switch cases.
  void _buildComplexSwitchStatement(
      ir.SwitchStatement switchStatement,
      JumpHandler jumpHandler,
      Map<ir.SwitchCase, int> caseIndex,
      bool hasDefault,
      SourceInformation? sourceInformation) {
    // If the switch statement has switch cases targeted by continue
    // statements we create the following encoding:
    //
    //   switch (e) {
    //     l_1: case e0: s_1; break;
    //     l_2: case e1: s_2; continue l_i;
    //     ...
    //     l_n: default: s_n; continue l_j;
    //   }
    //
    // is encoded as
    //
    //   var target;
    //   switch (e) {
    //     case e1: target = 1; break;
    //     case e2: target = 2; break;
    //     ...
    //     default: target = n; break;
    //   }
    //   l: while (true) {
    //    switch (target) {
    //       case 1: s_1; break l;
    //       case 2: s_2; target = i; continue l;
    //       ...
    //       case n: s_n; target = j; continue l;
    //     }
    //   }
    //
    // This is because JS does not have this same "continue label" semantics so
    // we encode it in the form of a state machine.

    // TODO(https://dartbug.com/51777): Consider alternative with single switch
    // statement.

    JumpTarget switchTarget =
        _localsMap.getJumpTargetForSwitch(switchStatement)!;
    localsHandler.updateLocal(switchTarget, graph.addConstantNull(closedWorld));

    var switchCases = List<ir.SwitchCase?>.from(switchStatement.cases);
    if (!hasDefault) {
      // Use null as the marker for a synthetic default clause.
      // The synthetic default is added because otherwise there would be no
      // good place to give a default value to the local.
      switchCases = List<ir.SwitchCase?>.from(switchCases);
      switchCases.add(null);
    }

    void buildSwitchCase(ir.SwitchCase? switchCase) {
      SourceInformation? caseSourceInformation = sourceInformation;
      if (switchCase != null) {
        caseSourceInformation = _sourceInformationBuilder.buildGoto(switchCase);
        // Generate 'target = i; break;' for switch case i.
        int index = caseIndex[switchCase]!;
        HInstruction value = graph.addConstantInt(index, closedWorld);
        localsHandler.updateLocal(switchTarget, value,
            sourceInformation: caseSourceInformation);
      } else {
        // Generate synthetic default case 'target = null; break;'.
        HInstruction nullValue = graph.addConstantNull(closedWorld);
        localsHandler.updateLocal(switchTarget, nullValue,
            sourceInformation: caseSourceInformation);
      }
      jumpTargets[switchTarget]!.generateBreak(caseSourceInformation);
    }

    _handleSwitch(
        switchStatement,
        jumpHandler,
        _buildExpression,
        switchCases,
        _getSwitchConstants,
        _isDefaultCase,
        buildSwitchCase,
        sourceInformation);
    jumpHandler.close();

    HInstruction buildCondition() => graph.addConstantBool(true, closedWorld);

    void buildSwitch() {
      HInstruction buildExpression(ir.SwitchStatement notUsed) {
        return localsHandler.readLocal(switchTarget);
      }

      List<ConstantValue> getConstants(
          ir.SwitchStatement parentSwitch, ir.SwitchCase? switchCase) {
        return [constant_system.createIntFromInt(caseIndex[switchCase]!)];
      }

      void buildSwitchCase(ir.SwitchCase? switchCase) {
        switchCase!.body.accept(this);
        if (!isAborted()) {
          // Ensure that we break the loop if the case falls through. (This
          // is only possible for the last case.)
          jumpTargets[switchTarget]!.generateBreak(sourceInformation);
        }
      }

      // Pass a [NullJumpHandler] because the target for the contained break
      // is not the generated switch statement but instead the loop generated
      // in the call to [handleLoop] below.
      _handleSwitch(
          switchStatement, // nor is buildExpression.
          NullJumpHandler(reporter),
          buildExpression,
          switchStatement.cases,
          getConstants,
          (_) => false, // No case is default.
          buildSwitchCase,
          sourceInformation);
    }

    void buildLoop() {
      _loopHandler.handleLoop(
          switchStatement,
          _closureDataLookup.getCapturedLoopScope(switchStatement),
          switchTarget,
          () {},
          buildCondition,
          () {},
          buildSwitch,
          _sourceInformationBuilder.buildLoop(switchStatement));
    }

    if (hasDefault) {
      buildLoop();
    } else {
      // If the switch statement has no default case, surround the loop with
      // a test of the target. So:
      // `if (target) while (true) ...` If there's no default case, target is
      // null, so we don't drop into the while loop.
      void buildCondition() {
        js.Template code = js.js.parseForeignJS('#');
        push(HForeignCode(code, _abstractValueDomain.boolType,
            [localsHandler.readLocal(switchTarget)],
            nativeBehavior: NativeBehavior.PURE));
      }

      _handleIf(
          node: switchStatement,
          visitCondition: buildCondition,
          visitThen: buildLoop,
          visitElse: () => {},
          sourceInformation: sourceInformation);
    }
  }

  /// Creates a switch statement.
  ///
  /// [jumpHandler] is the [JumpHandler] for the created switch statement.
  /// [buildSwitchCase] creates the statements for the switch case.
  void _handleSwitch(
      ir.SwitchStatement switchStatement,
      JumpHandler jumpHandler,
      HInstruction buildExpression(ir.SwitchStatement statement),
      List<ir.SwitchCase?> switchCases,
      List<ConstantValue> getConstants(
          ir.SwitchStatement parentSwitch, ir.SwitchCase? switchCase),
      bool isDefaultCase(ir.SwitchCase? switchCase),
      void buildSwitchCase(ir.SwitchCase? switchCase),
      SourceInformation? sourceInformation) {
    HBasicBlock expressionStart = openNewBlock();
    HInstruction expression = buildExpression(switchStatement);

    if (switchCases.isEmpty) {
      return;
    }

    HSwitch switchInstruction = HSwitch(_abstractValueDomain, [expression]);
    HBasicBlock expressionEnd = close(switchInstruction);
    LocalsHandler savedLocals = localsHandler;

    List<HStatementInformation> statements = [];
    bool hasDefault = false;
    for (ir.SwitchCase? switchCase in switchCases) {
      HBasicBlock block = graph.addNewBlock();
      for (ConstantValue constant
          in getConstants(switchStatement, switchCase)) {
        HConstant hConstant = graph.addConstant(constant, closedWorld);
        switchInstruction.inputs.add(hConstant);
        hConstant.usedBy.add(switchInstruction);
        expressionEnd.addSuccessor(block);
      }

      if (isDefaultCase(switchCase)) {
        // An HSwitch has n inputs and n+1 successors, the last being the
        // default case.
        expressionEnd.addSuccessor(block);
        hasDefault = true;
      }
      open(block);
      localsHandler = LocalsHandler.from(savedLocals);
      buildSwitchCase(switchCase);
      if (!isAborted() &&
          // TODO(johnniwinther): Reinsert this if `isReachable` is no longer
          // set to `false` when `_tryInlineMethod` sees an always throwing
          // method.
          //switchCase == switchCases.last &&
          !isDefaultCase(switchCase)) {
        // If there is no default, we will add one later to avoid
        // the critical edge. So we generate a break statement to make
        // sure the last case does not fall through to the default case.
        jumpHandler.generateBreak(sourceInformation);
      }
      statements
          .add(HSubGraphBlockInformation(SubGraph(block, lastOpenedBlock)));
    }

    // Add a join-block if necessary.
    // We create [joinBlock] early, and then go through the cases that might
    // want to jump to it. In each case, if we add [joinBlock] as a successor
    // of another block, we also add an element to [caseHandlers] that is used
    // to create the phis in [joinBlock].
    // If we never jump to the join block, [caseHandlers] will stay empty, and
    // the join block is never added to the graph.
    HBasicBlock? joinBlock = HBasicBlock();
    List<LocalsHandler> caseHandlers = [];
    jumpHandler.forEachBreak((HBreak instruction, LocalsHandler locals) {
      instruction.block!.addSuccessor(joinBlock!);
      caseHandlers.add(locals);
    });
    jumpHandler.forEachContinue((HContinue instruction, LocalsHandler locals) {
      assert(
          false,
          failedAt(_elementMap.getSpannable(targetElement, switchStatement),
              'Continue cannot target a switch.'));
    });
    if (!isAborted()) {
      current!.close(HGoto(_abstractValueDomain));
      lastOpenedBlock.addSuccessor(joinBlock);
      caseHandlers.add(localsHandler);
    }
    if (!hasDefault) {
      // Always create a default case, to avoid a critical edge in the
      // graph.
      HBasicBlock defaultCase = addNewBlock();
      expressionEnd.addSuccessor(defaultCase);
      open(defaultCase);
      close(HGoto(_abstractValueDomain));
      defaultCase.addSuccessor(joinBlock);
      caseHandlers.add(savedLocals);
      statements
          .add(HSubGraphBlockInformation(SubGraph(defaultCase, defaultCase)));
    }
    assert(caseHandlers.length == joinBlock.predecessors.length);
    if (caseHandlers.isNotEmpty) {
      graph.addBlock(joinBlock);
      open(joinBlock);
      if (caseHandlers.length == 1) {
        localsHandler = caseHandlers[0];
      } else {
        localsHandler = savedLocals.mergeMultiple(caseHandlers, joinBlock);
      }
    } else {
      // The joinBlock is not used.
      joinBlock = null;
    }

    HSubExpressionBlockInformation expressionInfo =
        HSubExpressionBlockInformation(
            SubExpression(expressionStart, expressionEnd));
    expressionStart.setBlockFlow(
        HSwitchBlockInformation(expressionInfo, statements, jumpHandler.target,
            jumpHandler.labels, sourceInformation),
        joinBlock);

    jumpHandler.close();
  }

  @override
  void visitConditionalExpression(ir.ConditionalExpression node) {
    SsaBranchBuilder brancher = SsaBranchBuilder(this);
    brancher.handleConditional(() => node.condition.accept(this),
        () => node.then.accept(this), () => node.otherwise.accept(this));
  }

  @override
  void visitLogicalExpression(ir.LogicalExpression node) {
    SsaBranchBuilder brancher = SsaBranchBuilder(this);
    _handleLogicalExpression(node.left, () => node.right.accept(this), brancher,
        node.operatorEnum, _sourceInformationBuilder.buildBinary(node));
  }

  /// Optimizes logical binary expression where the left has the same logical
  /// binary operator.
  ///
  /// This method transforms the operator by optimizing the case where [left] is
  /// a logical "and" or logical "or". Then it uses [branchBuilder] to build the
  /// graph for the optimized expression.
  ///
  /// For example, `(x && y) && z` is transformed into `x && (y && z)`:
  ///
  void _handleLogicalExpression(
      ir.Expression left,
      void visitRight(),
      SsaBranchBuilder brancher,
      ir.LogicalExpressionOperator operatorEnum,
      SourceInformation? sourceInformation) {
    if (left is ir.LogicalExpression && left.operatorEnum == operatorEnum) {
      ir.Expression innerLeft = left.left;
      ir.Expression middle = left.right;
      _handleLogicalExpression(
          innerLeft,
          () => _handleLogicalExpression(middle, visitRight, brancher,
              operatorEnum, _sourceInformationBuilder.buildBinary(middle)),
          brancher,
          operatorEnum,
          sourceInformation);
    } else {
      brancher.handleLogicalBinary(
          () => left.accept(this), visitRight, sourceInformation,
          isAnd: operatorEnum == ir.LogicalExpressionOperator.AND);
    }
  }

  @override
  void visitIntLiteral(ir.IntLiteral node) {
    stack.add(graph.addConstantIntAsUnsigned(node.value, closedWorld));
  }

  @override
  void visitDoubleLiteral(ir.DoubleLiteral node) {
    stack.add(graph.addConstantDouble(node.value, closedWorld));
  }

  @override
  void visitBoolLiteral(ir.BoolLiteral node) {
    stack.add(graph.addConstantBool(node.value, closedWorld));
  }

  @override
  void visitStringLiteral(ir.StringLiteral node) {
    stack.add(graph.addConstantString(node.value, closedWorld));
  }

  @override
  void visitSymbolLiteral(ir.SymbolLiteral node) {
    stack.add(graph.addConstant(
        _elementMap.getConstantValue(_memberContextNode!, node)!, closedWorld));
    registry.registerConstSymbol(node.value);
  }

  @override
  void visitNullLiteral(ir.NullLiteral node) {
    stack.add(graph.addConstantNull(closedWorld));
  }

  /// Set the runtime type information if necessary.
  HInstruction _setListRuntimeTypeInfoIfNeeded(HInstruction object,
      InterfaceType type, SourceInformation? sourceInformation) {
    // [type] could be `List<T>`, so ensure it is `JSArray<T>`.
    InterfaceType arrayType = dartTypes.interfaceType(
        _commonElements.jsArrayClass, type.typeArguments);
    if (!_rtiNeed.classNeedsTypeArguments(type.element) ||
        _equivalentToMissingRti(arrayType)) {
      return object;
    }
    HInstruction rti =
        _typeBuilder.analyzeTypeArgumentNewRti(arrayType, sourceElement);

    // TODO(15489): Register at codegen.
    registry.registerInstantiation(type);
    return _callSetRuntimeTypeInfo(rti, object, sourceInformation);
  }

  @override
  void visitListLiteral(ir.ListLiteral node) {
    HInstruction listInstruction;
    if (node.isConst) {
      listInstruction = graph.addConstant(
          _elementMap.getConstantValue(_memberContextNode!, node)!,
          closedWorld);
    } else {
      List<HInstruction> elements = [];
      for (ir.Expression element in node.expressions) {
        element.accept(this);
        elements.add(pop());
      }
      listInstruction = _buildLiteralList(elements);
      add(listInstruction);
      final sourceInformation =
          _sourceInformationBuilder.buildListLiteral(node);
      final type = localsHandler.substInContext(_commonElements.listType(
          _elementMap.getDartType(node.typeArgument))) as InterfaceType;
      listInstruction = _setListRuntimeTypeInfoIfNeeded(
          listInstruction, type, sourceInformation);
    }

    AbstractValue type =
        _typeInferenceMap.typeOfListLiteral(node, _abstractValueDomain);
    if (_abstractValueDomain.containsAll(type).isDefinitelyFalse) {
      listInstruction.instructionType = type;
    }
    stack.add(listInstruction);
  }

  @override
  void visitSetLiteral(ir.SetLiteral node) {
    if (node.isConst) {
      stack.add(graph.addConstant(
          _elementMap.getConstantValue(_memberContextNode!, node)!,
          closedWorld));
      return;
    }

    // The set literal constructors take the elements as a List.
    List<HInstruction> elements = [];
    for (ir.Expression element in node.expressions) {
      element.accept(this);
      elements.add(pop());
    }

    // The constructor is a procedure because it's a factory.
    FunctionEntity constructor;
    List<HInstruction> inputs = [];
    if (elements.isEmpty) {
      constructor = _commonElements.setLiteralConstructorEmpty;
    } else {
      constructor = _commonElements.setLiteralConstructor;
      HLiteralList argList = _buildLiteralList(elements);
      add(argList);
      inputs.add(argList);
    }

    assert(
        constructor is ConstructorEntity && constructor.isFactoryConstructor);

    final type = localsHandler.substInContext(
            _commonElements.setType(_elementMap.getDartType(node.typeArgument)))
        as InterfaceType;
    final cls = constructor.enclosingClass!;

    if (_rtiNeed.classNeedsTypeArguments(cls)) {
      List<HInstruction> typeInputs = [];
      type.typeArguments.forEach((DartType argument) {
        typeInputs
            .add(_typeBuilder.analyzeTypeArgument(argument, sourceElement));
      });

      // We lift this common call pattern into a helper function to save space
      // in the output.
      if (typeInputs.every((HInstruction input) =>
          input.isNull(_abstractValueDomain).isDefinitelyTrue)) {
        if (elements.isEmpty) {
          constructor = _commonElements.setLiteralUntypedEmptyMaker;
        } else {
          constructor = _commonElements.setLiteralUntypedMaker;
        }
      } else {
        inputs.addAll(typeInputs);
      }
    }

    // If runtime type information is needed and the set literal has no type
    // parameter, 'constructor' is a static function that forwards the call to
    // the factory constructor without a type parameter.
    assert(constructor.isFunction ||
        (constructor is ConstructorEntity && constructor.isFactoryConstructor));

    // The instruction type will always be a subtype of the setLiteralClass, but
    // type inference might discover a more specific type or find nothing (in
    // dart2js unit tests).

    AbstractValue setType = _abstractValueDomain
        .createNonNullSubtype(_commonElements.setLiteralClass);
    AbstractValue returnTypeMask =
        _typeInferenceMap.getReturnTypeOf(constructor);
    AbstractValue instructionType =
        _abstractValueDomain.intersection(setType, returnTypeMask);

    _addImplicitInstantiation(type);
    _pushStaticInvocation(
        constructor, inputs, instructionType, const <DartType>[],
        sourceInformation: _sourceInformationBuilder.buildNew(node));
    _removeImplicitInstantiation(type);
  }

  @override
  void visitMapLiteral(ir.MapLiteral node) {
    if (node.isConst) {
      stack.add(graph.addConstant(
          _elementMap.getConstantValue(_memberContextNode!, node)!,
          closedWorld));
      return;
    }

    // The map literal constructors take the key-value pairs as a List
    List<HInstruction> constructorArgs = [];
    for (ir.MapLiteralEntry mapEntry in node.entries) {
      mapEntry.key.accept(this);
      constructorArgs.add(pop());
      mapEntry.value.accept(this);
      constructorArgs.add(pop());
    }

    // The constructor is a procedure because it's a factory.
    FunctionEntity constructor;
    List<HInstruction> inputs = [];
    if (constructorArgs.isEmpty) {
      constructor = _commonElements.mapLiteralConstructorEmpty;
    } else {
      constructor = _commonElements.mapLiteralConstructor;
      HLiteralList argList = _buildLiteralList(constructorArgs);
      add(argList);
      inputs.add(argList);
    }

    assert(
        constructor is ConstructorEntity && constructor.isFactoryConstructor);

    final type = localsHandler.substInContext(_commonElements.mapType(
        _elementMap.getDartType(node.keyType),
        _elementMap.getDartType(node.valueType))) as InterfaceType;
    final cls = constructor.enclosingClass!;

    if (_rtiNeed.classNeedsTypeArguments(cls)) {
      List<HInstruction> typeInputs = [];
      type.typeArguments.forEach((DartType argument) {
        typeInputs
            .add(_typeBuilder.analyzeTypeArgument(argument, sourceElement));
      });

      // We lift this common call pattern into a helper function to save space
      // in the output.
      if (typeInputs.every((HInstruction input) =>
          input.isNull(_abstractValueDomain).isDefinitelyTrue)) {
        if (constructorArgs.isEmpty) {
          constructor = _commonElements.mapLiteralUntypedEmptyMaker;
        } else {
          constructor = _commonElements.mapLiteralUntypedMaker;
        }
      } else {
        inputs.addAll(typeInputs);
      }
    }

    // If runtime type information is needed and the map literal has no type
    // parameters, 'constructor' is a static function that forwards the call to
    // the factory constructor without type parameters.
    assert(constructor.isFunction ||
        (constructor is ConstructorEntity && constructor.isFactoryConstructor));

    // The instruction type will always be a subtype of the mapLiteralClass, but
    // type inference might discover a more specific type, or find nothing (in
    // dart2js unit tests).

    AbstractValue mapType = _abstractValueDomain
        .createNonNullSubtype(_commonElements.mapLiteralClass);
    AbstractValue returnTypeMask =
        _typeInferenceMap.getReturnTypeOf(constructor);
    AbstractValue instructionType =
        _abstractValueDomain.intersection(mapType, returnTypeMask);

    _addImplicitInstantiation(type);
    _pushStaticInvocation(
        constructor, inputs, instructionType, const <DartType>[],
        sourceInformation: _sourceInformationBuilder.buildNew(node));
    _removeImplicitInstantiation(type);
  }

  @override
  void visitMapLiteralEntry(ir.MapLiteralEntry node) {
    failedAt(CURRENT_ELEMENT_SPANNABLE,
        'ir.MapEntry should be handled in visitMapLiteral');
  }

  @override
  void visitRecordLiteral(ir.RecordLiteral node) {
    SourceInformation? sourceInformation =
        _sourceInformationBuilder.buildCreate(node);
    assert(!node.isConst);

    List<HInstruction> inputs = [];
    for (ir.Expression expression in node.positional) {
      expression.accept(this);
      inputs.add(pop());
    }
    for (ir.NamedExpression namedExpression in node.named) {
      namedExpression.value.accept(this);
      inputs.add(pop());
    }

    // TODO(50701): Choose class depending in inferred type of record fields
    // which might be better than the static type.
    RecordType dartType =
        _elementMap.getDartType(node.recordType) as RecordType;
    if (dartType.containsTypeVariables) {
      dartType = localsHandler.substInContext(dartType) as RecordType;
    }

    final recordRepresentation =
        _recordData.representationForStaticType(dartType);
    ClassEntity recordClass = recordRepresentation.cls;

    if (recordRepresentation.usesList) {
      // TODO(50081): Can we use `.constListType`?
      push(HLiteralList(inputs, _abstractValueDomain.fixedListType));
      inputs = [pop()];
    }

    AbstractValue type =
        _typeInferenceMap.typeOfRecordLiteral(node, _abstractValueDomain) ??
            _abstractValueDomain
                .createFromStaticType(dartType, nullable: true)
                .abstractValue;

    final allocation = HCreate(recordClass, inputs, type, sourceInformation);

    // TODO(50701): With traced record types there might be a better type.

    push(allocation);
  }

  @override
  void visitRecordIndexGet(ir.RecordIndexGet node) {
    final shape = recordShapeOfRecordType(node.receiverType);
    return _handleRecordFieldGet(node, node.receiver, shape, node.index);
  }

  @override
  void visitRecordNameGet(ir.RecordNameGet node) {
    final shape = recordShapeOfRecordType(node.receiverType);
    int index = shape.indexOfFieldName(node.name);
    return _handleRecordFieldGet(node, node.receiver, shape, index);
  }

  void _handleRecordFieldGet(ir.Expression node, ir.TreeNode receiverNode,
      RecordShape shape, int indexInShape) {
    receiverNode.accept(this);
    HInstruction receiver = pop();

    SourceInformation? sourceInformation =
        _sourceInformationBuilder.buildGet(node);

    if (_recordData.representationForShape(shape) != null) {
      final recordType = _typeInferenceMap.receiverTypeOfGet(node) ??
          _abstractValueDomain
              .createFromStaticType(_getStaticType(node).type, nullable: true)
              .abstractValue;
      final fieldType = _abstractValueDomain.getGetterTypeInRecord(
          recordType, shape.getterNameOfIndex(indexInShape));

      final path = _recordData.pathForAccess(shape, indexInShape);
      if (path.index == null) {
        HFieldGet fieldGet = HFieldGet(
            path.field, receiver, fieldType, sourceInformation,
            isAssignable: false);
        push(fieldGet);
      } else {
        HFieldGet fieldGet = HFieldGet(path.field, receiver,
            _abstractValueDomain.constListType, sourceInformation,
            isAssignable: false);
        push(fieldGet);
        final list = pop();
        push(HIndex(
            list, graph.addConstantInt(indexInShape, closedWorld), fieldType));
      }
    } else {
      // There are no records with this shape, so the path here must be
      // infeasible.
      push(HInvokeStatic(_commonElements.assertUnreachableMethod, [],
          _abstractValueDomain.emptyType, const [])
        ..sourceInformation = sourceInformation);
      // TODO(50081): Should we make subsequent code unreachable?
    }
  }

  @override
  void visitTypeLiteral(ir.TypeLiteral node) {
    final sourceInformation = _sourceInformationBuilder.buildGet(node);
    ir.DartType type = node.type;
    DartType dartType = _elementMap.getDartType(type);
    if (!dartType.containsTypeVariables) {
      final constant = _elementMap.getConstantValue(_memberContextNode!, node)!;
      stack.add(graph.addConstant(constant, closedWorld,
          sourceInformation: sourceInformation));
      return;
    }
    // For other types (e.g. TypeParameterType, function types from expanded
    // typedefs), look-up or construct a reified type representation and convert
    // to a RuntimeType.

    dartType = localsHandler.substInContext(dartType);
    HInstruction value = _typeBuilder.analyzeTypeArgument(
        dartType, sourceElement,
        sourceInformation: sourceInformation);
    _pushStaticInvocation(
        _commonElements.createRuntimeType,
        [value],
        _typeInferenceMap.getReturnTypeOf(_commonElements.createRuntimeType),
        const <DartType>[],
        sourceInformation: sourceInformation);
  }

  @override
  void visitStaticGet(ir.StaticGet node) {
    ir.Member staticTarget = node.target;
    final sourceInformation = _sourceInformationBuilder.buildGet(node);
    if (staticTarget is ir.Procedure &&
        staticTarget.kind == ir.ProcedureKind.Getter) {
      final getter = _elementMap.getMember(staticTarget) as FunctionEntity;
      // Invoke the getter
      _pushStaticInvocation(getter, const [],
          _typeInferenceMap.getReturnTypeOf(getter), const <DartType>[],
          sourceInformation: sourceInformation);
    } else if (staticTarget is ir.Field) {
      FieldEntity field = _elementMap.getField(staticTarget);
      FieldAnalysisData fieldData = _fieldAnalysis.getFieldData(field);
      if (fieldData.isEager) {
        push(HStatic(field, _typeInferenceMap.getInferredTypeOf(field),
            sourceInformation));
      } else if (fieldData.isEffectivelyConstant) {
        OutputUnit outputUnit =
            closedWorld.outputUnitData.outputUnitForMember(field);
        final initialValue = fieldData.initialValue!;
        // TODO(sigmund): this is not equivalent to what the old FE does: if
        // there is no prefix the old FE wouldn't treat this in any special
        // way. Also, if the prefix points to a constant in the main output
        // unit, the old FE would still generate a deferred wrapper here.
        if (!closedWorld.outputUnitData
            .hasOnlyNonDeferredImportPaths(targetElement, field)) {
          final deferredConstant =
              DeferredGlobalConstantValue(initialValue, outputUnit);
          registry.registerConstantUse(ConstantUse.deferred(deferredConstant));
          stack.add(graph.addDeferredConstant(
              deferredConstant, sourceInformation, closedWorld));
        } else {
          stack.add(graph.addConstant(initialValue, closedWorld,
              sourceInformation: sourceInformation));
        }
      } else {
        assert(
            fieldData.isLazy, "Unexpected field data for $field: $fieldData");
        push(HLazyStatic(field, _typeInferenceMap.getInferredTypeOf(field),
            sourceInformation));
      }
    } else {
      // TODO(johnniwinther): This is a constant tear off, so we should have
      // created a constant value instead. Remove this case when we use CFE
      // constants.
      final member = _elementMap.getMember(staticTarget);
      push(HStatic(member, _typeInferenceMap.getInferredTypeOf(member),
          sourceInformation));
    }
  }

  @override
  void visitStaticTearOff(ir.StaticTearOff node) {
    // TODO(johnniwinther): This is a constant tear off, so we should have
    // created a constant value instead. Remove this case when we use CFE
    // constants.
    ir.Member staticTarget = node.target;
    final sourceInformation = _sourceInformationBuilder.buildGet(node);
    final member = _elementMap.getMember(staticTarget);
    push(HStatic(member, _typeInferenceMap.getInferredTypeOf(member),
        sourceInformation));
  }

  @override
  void visitStaticSet(ir.StaticSet node) {
    node.value.accept(this);
    HInstruction value = pop();

    ir.Member staticTarget = node.target;
    if (staticTarget is ir.Procedure) {
      final setter = _elementMap.getMember(staticTarget) as FunctionEntity;
      // Invoke the setter
      _pushStaticInvocation(setter, [value],
          _typeInferenceMap.getReturnTypeOf(setter), const <DartType>[],
          sourceInformation: _sourceInformationBuilder.buildSet(node));
      pop();
    } else {
      final target = _elementMap.getMember(staticTarget) as FieldEntity;
      if (!_fieldAnalysis.getFieldData(target).isElided) {
        add(HStaticStore(
            _abstractValueDomain,
            target,
            _typeBuilder.potentiallyCheckOrTrustTypeOfAssignment(
                target, value, _getDartTypeIfValid(staticTarget.setterType))));
      }
    }
    stack.add(value);
  }

  void _handlePropertyGet(
      ir.Expression node, ir.Expression receiver, ir.Name name) {
    receiver.accept(this);
    HInstruction receiverInstruction = pop();
    _pushDynamicInvocation(
        node,
        _getStaticType(receiver),
        _typeInferenceMap.receiverTypeOfGet(node),
        Selector.getter(_elementMap.getName(name)),
        [receiverInstruction],
        const <DartType>[],
        _sourceInformationBuilder.buildGet(node));
  }

  @override
  void visitInstanceGet(ir.InstanceGet node) {
    _handlePropertyGet(node, node.receiver, node.name);
  }

  @override
  void visitInstanceTearOff(ir.InstanceTearOff node) {
    _handlePropertyGet(node, node.receiver, node.name);
  }

  @override
  void visitDynamicGet(ir.DynamicGet node) {
    _handlePropertyGet(node, node.receiver, node.name);
  }

  @override
  void visitFunctionTearOff(ir.FunctionTearOff node) {
    _handlePropertyGet(node, node.receiver, ir.Name.callName);
  }

  @override
  void visitVariableGet(ir.VariableGet node) {
    ir.VariableDeclaration variable = node.variable;
    final letBinding = _letBindings[variable];
    if (letBinding != null) {
      stack.add(letBinding);
      return;
    }

    Local local = _localsMap.getLocalVariable(node.variable);
    stack.add(localsHandler.readLocal(local,
        sourceInformation: _sourceInformationBuilder.buildGet(node)));
  }

  void _handlePropertySet(ir.Expression node, ir.Expression receiver,
      ir.Name name, ir.Expression value) {
    receiver.accept(this);
    HInstruction receiverInstruction = pop();
    value.accept(this);
    HInstruction valueInstruction = pop();

    _pushDynamicInvocation(
        node,
        _getStaticType(receiver),
        _typeInferenceMap.receiverTypeOfSet(node, _abstractValueDomain),
        Selector.setter(_elementMap.getName(name)),
        [receiverInstruction, valueInstruction],
        const <DartType>[],
        _sourceInformationBuilder.buildAssignment(node));

    pop();
    stack.add(valueInstruction);
  }

  @override
  void visitInstanceSet(ir.InstanceSet node) {
    _handlePropertySet(node, node.receiver, node.name, node.value);
  }

  @override
  void visitDynamicSet(ir.DynamicSet node) {
    _handlePropertySet(node, node.receiver, node.name, node.value);
  }

  @override
  void visitSuperPropertySet(ir.SuperPropertySet node) {
    final sourceInformation = _sourceInformationBuilder.buildAssignment(node);
    node.value.accept(this);
    HInstruction value = pop();

    final target = getEffectiveSuperTarget(node.interfaceTarget);
    if (target == null) {
      // TODO(johnniwinther): Remove this when the CFE checks for missing
      //  concrete super targets.
      _generateSuperNoSuchMethod(node, _elementMap.getSelector(node).name + "=",
          [value], const <DartType>[], sourceInformation);
    } else {
      MemberEntity member = _elementMap.getMember(target);
      _buildInvokeSuper(
          _elementMap.getSelector(node),
          _elementMap.getClass(_containingClass(node)),
          member,
          [value],
          const <DartType>[],
          sourceInformation);
    }
    pop();
    stack.add(value);
  }

  @override
  void visitVariableSet(ir.VariableSet node) {
    node.value.accept(this);
    HInstruction value = pop();
    _visitLocalSetter(
        node.variable, value, _sourceInformationBuilder.buildAssignment(node));
  }

  @override
  void visitVariableDeclaration(ir.VariableDeclaration node) {
    Local local = _localsMap.getLocalVariable(node);
    if (node.initializer == null) {
      HInstruction initialValue = graph.addConstantNull(closedWorld);
      localsHandler.updateLocal(local, initialValue);
    } else if (node.isConst) {
      final constant =
          _elementMap.getConstantValue(_memberContextNode!, node.initializer);
      assert(constant != null, failedAt(CURRENT_ELEMENT_SPANNABLE));
      HInstruction initialValue = graph.addConstant(constant!, closedWorld);
      localsHandler.updateLocal(local, initialValue);
    } else {
      node.initializer!.accept(this);
      HInstruction initialValue = pop();

      _visitLocalSetter(
          node, initialValue, _sourceInformationBuilder.buildAssignment(node));

      // Ignore value
      pop();
    }
  }

  void _visitLocalSetter(ir.VariableDeclaration variable, HInstruction value,
      SourceInformation? sourceInformation) {
    Local local = _localsMap.getLocalVariable(variable);

    // Give the value a name if it doesn't have one already.
    if (value.sourceElement == null) {
      value.sourceElement = local;
    }

    stack.add(value);
    localsHandler.updateLocal(
        local,
        _typeBuilder.potentiallyCheckOrTrustTypeOfAssignment(
            _currentFrame!.member, value, _getDartTypeIfValid(variable.type)),
        sourceInformation: sourceInformation);
  }

  @override
  void visitLet(ir.Let node) {
    ir.VariableDeclaration variable = node.variable;
    variable.initializer!.accept(this);
    HInstruction initializedValue = pop();
    // TODO(sra): Apply inferred type information.
    _letBindings[variable] = initializedValue;
    // TODO(43456): Use `!_isReachable` for better dead code removal.
    if (isAborted()) {
      stack.add(graph.addConstantUnreachable(closedWorld));
    } else {
      node.body.accept(this);
    }
  }

  @override
  void visitBlockExpression(ir.BlockExpression node) {
    node.body.accept(this);
    // Body can be partially generated due to an exception exit and be missing
    // bindings referenced in the value.
    if (!_isReachable) {
      stack.add(graph.addConstantUnreachable(closedWorld));
    } else {
      final previous = _inBlockExpression;
      try {
        _inBlockExpression = true;
        node.value.accept(this);
      } finally {
        _inBlockExpression = previous;
      }
    }
  }

  /// Generate instructions to evaluate the positional arguments in source
  /// order.
  List<HInstruction> _visitPositionalArguments(ir.Arguments arguments) {
    List<HInstruction> result = [];
    for (ir.Expression argument in arguments.positional) {
      argument.accept(this);
      result.add(pop());
    }
    return result;
  }

  /// Generate instructions to evaluate the named arguments in source order.
  /// Returns a fresh map from parameter name to evaluated argument.
  Map<String, HInstruction> _visitNamedArguments(ir.Arguments arguments) {
    Map<String, HInstruction> values = {};
    for (ir.NamedExpression argument in arguments.named) {
      argument.value.accept(this);
      values[argument.name] = pop();
    }
    return values;
  }

  /// Builds the list of instructions for the expressions in the arguments to a
  /// dynamic target (member function).  Dynamic targets use stubs to add
  /// defaulted arguments, so (unlike static targets) we do not add the default
  /// values.
  List<HInstruction> _visitArgumentsForDynamicTarget(
      Selector selector, ir.Arguments arguments, List<DartType> typeArguments,
      [SourceInformation? sourceInformation]) {
    List<HInstruction> values = _visitPositionalArguments(arguments);

    if (arguments.named.isNotEmpty) {
      Map<String, HInstruction> namedValues = _visitNamedArguments(arguments);
      for (String name in selector.callStructure.getOrderedNamedArguments()) {
        values.add(namedValues[name]!);
      }
    }

    _addTypeArguments(values, typeArguments, sourceInformation);

    return values;
  }

  /// Build the argument list for JS-interop invocations, which have slightly
  /// different semantics than dart because of JS's null vs undefined and lack
  /// of named arguments. A `null` argument indicates an optional argument which
  /// was not provided.
  List<HInstruction?> _visitArgumentsForNativeStaticTarget(
      ir.FunctionNode target, ir.Arguments arguments) {
    // Visit arguments in source order, then re-order and fill in defaults.
    List<HInstruction?> values =
        List.from(_visitPositionalArguments(arguments));

    if (target.namedParameters.isNotEmpty) {
      // Only anonymous factory or inline class literal constructors involving
      // JS interop are allowed to have named parameters. Otherwise, throw an
      // error.
      final member = target.parent as ir.Member;
      final function = _elementMap.getMember(member) as FunctionEntity;
      bool isAnonymousFactory = function is ConstructorEntity &&
          function.isFactoryConstructor &&
          _nativeData.isAnonymousJsInteropClass(function.enclosingClass);
      // JS interop checks assert that the only inline class interop member that
      // has named parameters is an object literal constructor. We could do a
      // more robust check by visiting all inline classes and recording
      // descriptors, but that's expensive.
      bool isObjectLiteralConstructor = member.isInlineClassMember;
      if (isAnonymousFactory || isObjectLiteralConstructor) {
        // TODO(sra): Have a "CompiledArguments" structure to just update with
        // what values we have rather than creating a map and de-populating it.
        Map<String, HInstruction> namedValues = _visitNamedArguments(arguments);

        // Visit named arguments in parameter-position order, selecting provided
        // or default value.
        var namedParameters = target.namedParameters.toList();
        assert(namedValues.keys
            .every((k) => namedParameters.any((p) => p.name == k)));
        namedParameters.sort(nativeOrdering);
        for (ir.VariableDeclaration parameter in namedParameters) {
          final value = namedValues[parameter.name];
          values.add(value);
        }
      }
    }
    return values;
  }

  /// Fills [typeArguments] with the type arguments needed for [selector] and
  /// returns the selector corresponding to the passed type arguments.
  ///
  /// If [isImplicitCall] is `true`, the target of the invocation can be either
  /// the target of the [selector] or of the corresponding `.call` selector. In
  /// this case we need to check both selectors to see if we need to pass type
  /// arguments. This occurs for field/getter invocations.
  Selector _fillDynamicTypeArguments(
      Selector selector, ir.Arguments arguments, List<DartType> typeArguments,
      {bool isImplicitCall = false}) {
    if (selector.typeArgumentCount > 0) {
      if (_rtiNeed.selectorNeedsTypeArguments(selector) ||
          (isImplicitCall &&
              _rtiNeed.selectorNeedsTypeArguments(selector.toCallSelector()))) {
        typeArguments.addAll(arguments.types.map(_elementMap.getDartType));
      } else {
        return selector.toNonGeneric();
      }
    }
    return selector;
  }

  List<DartType> _getConstructorTypeArguments(
      ConstructorEntity constructor, ir.Arguments arguments) {
    // TODO(johnniwinther): Pass type arguments to constructors like calling
    // a generic method.
    return const <DartType>[];
  }

  // TODO(johnniwinther): Remove this when type arguments are passed to
  // constructors like calling a generic method.
  List<DartType> _getClassTypeArguments(
      ClassEntity cls, ir.Arguments arguments) {
    if (_rtiNeed.classNeedsTypeArguments(cls)) {
      return arguments.types.map(_elementMap.getDartType).toList();
    }
    return const <DartType>[];
  }

  List<DartType> _getStaticTypeArguments(
      FunctionEntity function, ir.Arguments arguments) {
    if (_rtiNeed.methodNeedsTypeArguments(function)) {
      return arguments.types.map(_elementMap.getDartType).toList();
    }
    return const <DartType>[];
  }

  /// Build argument list in canonical order for a static [target], including
  /// filling in the default argument value.
  List<HInstruction> _visitArgumentsForStaticTarget(
      ir.Member memberContextNode,
      ir.FunctionNode target,
      ParameterStructure parameterStructure,
      ir.Arguments arguments,
      List<DartType> typeArguments,
      SourceInformation? sourceInformation) {
    // Visit arguments in source order, then re-order and fill in defaults.
    List<HInstruction> values = _visitPositionalArguments(arguments);

    while (values.length < parameterStructure.positionalParameters) {
      ir.VariableDeclaration parameter =
          target.positionalParameters[values.length];
      values.add(_defaultValueForParameter(memberContextNode, parameter));
    }

    if (parameterStructure.namedParameters.isNotEmpty) {
      Map<String, HInstruction> namedValues = _visitNamedArguments(arguments);

      // Visit named arguments in parameter-position order, selecting provided
      // or default value.
      // TODO(sra): Ensure the stored order is canonical so we don't have to
      // sort. The old builder uses CallStructure.makeArgumentList which depends
      // on the old element model.
      List<ir.VariableDeclaration> namedParameters = target.namedParameters
          // Filter elided parameters.
          .where((p) => parameterStructure.namedParameters.contains(p.name))
          .toList()
        ..sort(namedOrdering);
      for (ir.VariableDeclaration parameter in namedParameters) {
        final value = namedValues[parameter.name];
        if (value == null) {
          values.add(_defaultValueForParameter(memberContextNode, parameter));
        } else {
          values.add(value);
          namedValues.remove(parameter.name);
        }
      }
      assert(namedValues.isEmpty);
    } else {
      assert(arguments.named.isEmpty);
    }

    _addTypeArguments(values, typeArguments, sourceInformation);
    return values;
  }

  void _addTypeArguments(List<HInstruction?> values,
      List<DartType> typeArguments, SourceInformation? sourceInformation) {
    if (typeArguments.isEmpty) return;
    for (DartType type in typeArguments) {
      values.add(_typeBuilder.analyzeTypeArgument(type, sourceElement,
          sourceInformation: sourceInformation));
    }
  }

  HInstruction _defaultValueForParameter(
      ir.Member memberContextNode, ir.VariableDeclaration parameter) {
    final constant = _elementMap.getConstantValue(
        memberContextNode, parameter.initializer,
        implicitNull: true);
    assert(constant != null, failedAt(CURRENT_ELEMENT_SPANNABLE));
    return graph.addConstant(constant!, closedWorld);
  }

  @override
  void visitStaticInvocation(ir.StaticInvocation node) {
    if (ir.StaticWeakReferences.isWeakReference(node)) {
      final weakTarget = ir.StaticWeakReferences.getWeakReferenceTarget(node);
      if (_elementMap.containsMethod(weakTarget)) {
        final argument = ir.StaticWeakReferences.getWeakReferenceArgument(node);
        argument.accept(this);
        return;
      }
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }
    ir.Procedure target = node.target;
    final sourceInformation = _sourceInformationBuilder.buildCall(node, node);
    final function = _elementMap.getMember(target) as FunctionEntity;
    if (_commonElements.isForeignHelper(function)) {
      _handleInvokeStaticForeign(node, function);
      return;
    }

    if (_commonElements.isExtractTypeArguments(function) &&
        _handleExtractTypeArguments(node, sourceInformation)) {
      return;
    }

    AbstractValue typeMask = _typeInferenceMap.getReturnTypeOf(function);

    List<DartType> typeArguments =
        _getStaticTypeArguments(function, node.arguments);

    // Recognize e.g. `bool.fromEnvironment('x')`
    // TODO(sra): Can we delete this code now that the CFE does constant folding
    // for us during loading?
    if (function.isExternal &&
        function is ConstructorEntity &&
        function.isFromEnvironmentConstructor) {
      if (node.isConst) {
        // Just like all const constructors (see visitConstructorInvocation).
        stack.add(graph.addConstant(
            _elementMap.getConstantValue(_memberContextNode!, node)!,
            closedWorld,
            sourceInformation: sourceInformation));
      } else {
        _generateUnsupportedError(
            '${function.enclosingClass.name}.${function.name} '
            'can only be used as a const constructor',
            sourceInformation);
      }
      return;
    }

    if (closedWorld.nativeData.isJsInteropMember(function)) {
      final arguments =
          _visitArgumentsForNativeStaticTarget(target.function, node.arguments);

      if (function is ConstructorEntity && function.isFactoryConstructor) {
        _handleInvokeNativeFactoryConstructor(
            node, function, typeMask, arguments, sourceInformation);
        return;
      }

      // Static methods currently ignore the type parameters.
      _pushStaticNativeInvocation(function, arguments, typeMask, typeArguments);
    } else {
      final arguments = _visitArgumentsForStaticTarget(
          target,
          target.function,
          function.parameterStructure,
          node.arguments,
          typeArguments,
          sourceInformation);

      if (function is ConstructorEntity && function.isFactoryConstructor) {
        _handleInvokeFactoryConstructor(
            node, function, typeMask, arguments, sourceInformation);
        return;
      }

      // Static methods currently ignore the type parameters.
      _pushStaticInvocation(function, arguments, typeMask, typeArguments,
          sourceInformation: sourceInformation);
    }
  }

  void _handleInvokeFactoryConstructor(
      ir.StaticInvocation invocation,
      ConstructorEntity function,
      AbstractValue typeMask,
      List<HInstruction> arguments,
      SourceInformation? sourceInformation) {
    // Recognize `JSArray<E>.typed(allocation)`.
    if (function == _commonElements.jsArrayTypedConstructor) {
      if (invocation.arguments.named.isEmpty) {
        if (invocation.arguments.positional.length == 1) {
          assert(arguments.length == 1);
          _handleInvokeJSArrayTypedConstructor(
              invocation, function, typeMask, arguments, sourceInformation);
          return;
        }
      }
    }

    InterfaceType instanceType = _elementMap.createInterfaceType(
        invocation.target.enclosingClass!, invocation.arguments.types);

    // Factory constructors take type parameters.
    List<DartType> typeArguments =
        _getConstructorTypeArguments(function, invocation.arguments);

    // This could be a List factory constructor that returned a fresh list and
    // we have a call-site-specific type from type inference.
    var allocatedListType = globalInferenceResults.typeOfNewList(invocation);
    AbstractValue resultType = allocatedListType ?? typeMask;

    // TODO(johnniwinther): Remove this when type arguments are passed to
    // constructors like calling a generic method.
    _addTypeArguments(
        arguments,
        _getClassTypeArguments(function.enclosingClass, invocation.arguments),
        sourceInformation);
    instanceType = localsHandler.substInContext(instanceType) as InterfaceType;
    _addImplicitInstantiation(instanceType);
    _pushStaticInvocation(function, arguments, resultType, typeArguments,
        sourceInformation: sourceInformation, instanceType: instanceType);

    if (allocatedListType != null) {
      HInstruction newInstance = stack.last.nonCheck();
      if (newInstance is HInvokeStatic) {
        newInstance.setAllocation(true);
      }
      // Is the constructor call one from which we can extract the length
      // argument?
      bool isFixedList = false;

      if (_abstractValueDomain.isFixedArray(resultType).isDefinitelyTrue) {
        // These constructors all take a length as the first argument.
        if (_commonElements.isNamedListConstructor('filled', function) ||
            _commonElements.isNamedListConstructor('generate', function) ||
            _commonElements.isNamedJSArrayConstructor('fixed', function) ||
            _commonElements.isNamedJSArrayConstructor(
                'allocateFixed', function)) {
          isFixedList = true;
        }
      }

      if (_abstractValueDomain.isTypedArray(resultType).isDefinitelyTrue) {
        // The unnamed constructors of typed arrays take a length as the first
        // argument.
        if (function.name == '') isFixedList = true;
        // TODO(sra): Can this misfire?
      }

      if (isFixedList) {
        if (newInstance is HInvokeStatic || newInstance is HForeignCode) {
          graph.allocatedFixedLists.add(newInstance);
        }
      }
    }
  }

  void _handleInvokeNativeFactoryConstructor(
      ir.StaticInvocation invocation,
      ConstructorEntity function,
      AbstractValue typeMask,
      List<HInstruction?> arguments,
      SourceInformation? sourceInformation) {
    InterfaceType instanceType = _elementMap.createInterfaceType(
        invocation.target.enclosingClass!, invocation.arguments.types);

    // Factory constructors take type parameters.
    List<DartType> typeArguments =
        _getConstructorTypeArguments(function, invocation.arguments);

    // TODO(johnniwinther): Remove this when type arguments are passed to
    // constructors like calling a generic method.
    _addTypeArguments(
        arguments,
        _getClassTypeArguments(function.enclosingClass, invocation.arguments),
        sourceInformation);
    instanceType = localsHandler.substInContext(instanceType) as InterfaceType;
    _addImplicitInstantiation(instanceType);
    _pushStaticNativeInvocation(function, arguments, typeMask, typeArguments);
  }

  /// Handle the `JSArray<E>.typed` constructor, which returns its argument,
  /// which must be a JSArray, with the JSArray type Rti information added on a
  /// property.
  void _handleInvokeJSArrayTypedConstructor(
      ir.StaticInvocation invocation,
      ConstructorEntity function,
      AbstractValue typeMask,
      List<HInstruction> arguments,
      SourceInformation? sourceInformation) {
    // TODO(sra): We rely here on inlining the identity-like factory
    // constructor. Instead simply select the single argument and add the type.

    // Factory constructors take type parameters.
    List<DartType> typeArguments =
        _getConstructorTypeArguments(function, invocation.arguments);
    // TODO(johnniwinther): Remove this when type arguments are passed to
    // constructors like calling a generic method.
    _addTypeArguments(
        arguments,
        _getClassTypeArguments(function.enclosingClass, invocation.arguments),
        sourceInformation);
    _pushStaticInvocation(function, arguments, typeMask, typeArguments,
        sourceInformation: sourceInformation);

    InterfaceType type = _elementMap.createInterfaceType(
        invocation.target.enclosingClass!, invocation.arguments.types);
    stack.add(_setListRuntimeTypeInfoIfNeeded(pop(), type, sourceInformation));
  }

  /// Replace calls to `extractTypeArguments` with equivalent code. Returns
  /// `true` if `extractTypeArguments` is handled.
  bool _handleExtractTypeArguments(
      ir.StaticInvocation invocation, SourceInformation? sourceInformation) {
    // Expand calls as follows:
    //
    //     r = extractTypeArguments<Map>(e, f)
    // -->
    //     environment = HInstanceEnvironment(e);
    //     T1 = HTypeEval( environment, 'Map.K');
    //     T2 = HTypeEval( environment, 'Map.V');
    //     r = f<T1, T2>();
    //
    // TODO(sra): Should we add a check before the variable extraction? We could
    // add a type check (which would permit `null`), or add an is-check with an
    // explicit throw.

    if (invocation.arguments.positional.length != 2) return false;
    if (invocation.arguments.named.isNotEmpty) return false;
    var types = invocation.arguments.types;
    if (types.length != 1) return false;

    // The type should be a single type name.
    ir.DartType type = types.first;
    DartType typeValue = dartTypes.eraseLegacy(
        localsHandler.substInContext(_elementMap.getDartType(type)));
    if (typeValue is! InterfaceType) return false;
    InterfaceType interfaceType = typeValue;
    if (!dartTypes.treatAsRawType(interfaceType)) return false;

    ClassEntity cls = interfaceType.element;
    InterfaceType thisType = _elementEnvironment.getThisType(cls);

    List<HInstruction> arguments =
        _visitPositionalArguments(invocation.arguments);

    HInstruction object = arguments[0];
    HInstruction closure = arguments[1];

    List<HInstruction> inputs = [closure];
    List<DartType> typeArguments = [];

    closedWorld.registerExtractTypeArguments(cls);
    HInstruction instanceType =
        HInstanceEnvironment(object, _abstractValueDomain.dynamicType);
    add(instanceType);
    TypeEnvironmentStructure envStructure =
        FullTypeEnvironmentStructure(classType: thisType);

    thisType.typeArguments.forEach((variable) {
      assert(variable is TypeVariableType);
      typeArguments.add(variable);
      TypeRecipe recipe = TypeExpressionRecipe(variable);
      HInstruction typeEval = HTypeEval(
          instanceType, envStructure, recipe, _abstractValueDomain.dynamicType);
      add(typeEval);
      inputs.add(typeEval);
    });

    // TODO(sra): In compliance mode, insert a check that [closure] is a
    // function of N type arguments.

    Selector selector =
        Selector.callClosure(0, const <String>[], typeArguments.length);
    StaticType receiverStaticType =
        _getStaticType(invocation.arguments.positional[1]);
    AbstractValue receiverType = _abstractValueDomain
        .createFromStaticType(receiverStaticType.type,
            classRelation: receiverStaticType.relation, nullable: true)
        .abstractValue;
    push(HInvokeClosure(selector, receiverType, inputs,
        _abstractValueDomain.dynamicType, typeArguments));

    return true;
  }

  void _handleInvokeStaticForeign(
      ir.StaticInvocation invocation, MemberEntity member) {
    final name = member.name;
    if (name == 'JS') {
      _handleForeignJs(invocation);
    } else if (name == 'DART_CLOSURE_TO_JS') {
      _handleForeignDartClosureToJs(invocation, 'DART_CLOSURE_TO_JS');
    } else if (name == 'RAW_DART_FUNCTION_REF') {
      _handleForeignRawFunctionRef(invocation, 'RAW_DART_FUNCTION_REF');
    } else if (name == 'JS_GET_NAME') {
      _handleForeignJsGetName(invocation);
    } else if (name == 'JS_EMBEDDED_GLOBAL') {
      _handleForeignJsEmbeddedGlobal(invocation);
    } else if (name == 'JS_BUILTIN') {
      _handleForeignJsBuiltin(invocation);
    } else if (name == 'JS_GET_FLAG') {
      _handleForeignJsGetFlag(invocation);
    } else if (name == 'JS_EFFECT') {
      stack.add(graph.addConstantNull(closedWorld));
    } else if (name == 'JS_INTERCEPTOR_CONSTANT') {
      _handleJsInterceptorConstant(invocation);
    } else if (name == 'getInterceptor') {
      _handleForeignGetInterceptor(invocation);
    } else if (name == 'getJSArrayInteropRti') {
      _handleForeignGetJSArrayInteropRti(invocation);
    } else if (name == 'JS_RAW_EXCEPTION') {
      _handleJsRawException(invocation);
    } else if (name == 'JS_STRING_CONCAT') {
      _handleJsStringConcat(invocation);
    } else if (name == '_createInvocationMirror') {
      _handleCreateInvocationMirror(invocation);
    } else if (name == 'TYPE_REF') {
      _handleForeignTypeRef(invocation);
    } else if (name == 'LEGACY_TYPE_REF') {
      _handleForeignLegacyTypeRef(invocation);
    } else if (name == 'createJsSentinel') {
      _handleForeignCreateJsSentinel(invocation);
    } else if (name == 'isJsSentinel') {
      _handleForeignIsJsSentinel(invocation);
    } else if (name == '_lateReadCheck') {
      _handleLateReadCheck(invocation);
    } else if (name == '_lateWriteOnceCheck') {
      _handleLateWriteOnceCheck(invocation);
    } else if (name == '_lateInitializeOnceCheck') {
      _handleLateInitializeOnceCheck(invocation);
    } else if (name == 'HCharCodeAt') {
      _handleCharCodeAt(invocation);
    } else {
      reporter.internalError(
          _elementMap.getSpannable(targetElement, invocation),
          "Unknown foreign: ${name}");
    }
  }

  String _readStringLiteral(ir.Expression node) {
    if (node is ir.StringLiteral) {
      return node.value;
    }
    if (node is ir.ConstantExpression) {
      final constant = node.constant;
      if (constant is ir.StringConstant) {
        return constant.value;
      }
    }
    return reporter.internalError(
        _elementMap.getSpannable(targetElement, node),
        "Unexpected string literal: "
        "${node is ir.ConstantExpression ? node.constant : node}");
  }

  int _readIntLiteral(ir.Expression node) {
    if (node is ir.IntLiteral) {
      return node.value;
    }
    if (node is ir.ConstantExpression) {
      final constant = node.constant;
      if (constant is ir.IntConstant) {
        return constant.value;
      } else if (constant is ir.DoubleConstant) {
        assert(constant.value.floor() == constant.value,
            "Unexpected int literal value ${constant.value}.");
        return constant.value.toInt();
      }
    }
    return reporter.internalError(
        _elementMap.getSpannable(targetElement, node),
        "Unexpected int literal: "
        "${node is ir.ConstantExpression ? node.constant : node}");
  }

  void _handleCreateInvocationMirror(ir.StaticInvocation invocation) {
    String name = _readStringLiteral(invocation.arguments.positional[0]);
    final typeArgumentsLiteral =
        invocation.arguments.positional[1] as ir.ListLiteral;
    List<DartType> typeArguments =
        typeArgumentsLiteral.expressions.map((ir.Expression expression) {
      final typeLiteral = expression as ir.TypeLiteral;
      return _elementMap.getDartType(typeLiteral.type);
    }).toList();

    final positionalArgumentsLiteral =
        invocation.arguments.positional[2] as ir.ListLiteral;
    ir.Expression namedArgumentsLiteral = invocation.arguments.positional[3];
    Map<String, ir.Expression> namedArguments = {};
    int kind = _readIntLiteral(invocation.arguments.positional[4]);

    Name memberName = Name(name, _currentFrame!.member.library.canonicalUri);
    Selector? selector;
    switch (kind) {
      case invocationMirrorGetterKind:
        selector = Selector.getter(memberName);
        break;
      case invocationMirrorSetterKind:
        selector = Selector.setter(memberName);
        break;
      case invocationMirrorMethodKind:
        if (memberName == Names.INDEX_NAME) {
          selector = Selector.index();
        } else if (memberName == Names.INDEX_SET_NAME) {
          selector = Selector.indexSet();
        } else {
          if (namedArgumentsLiteral is ir.MapLiteral) {
            namedArgumentsLiteral.entries.forEach((ir.MapLiteralEntry entry) {
              String key = _readStringLiteral(entry.key);
              namedArguments[key] = entry.value;
            });
          } else if (namedArgumentsLiteral is ir.ConstantExpression &&
              namedArgumentsLiteral.constant is ir.MapConstant) {
            final constant = namedArgumentsLiteral.constant as ir.MapConstant;
            for (ir.ConstantMapEntry entry in constant.entries) {
              final key = entry.key as ir.StringConstant;
              namedArguments[key.value] = ir.ConstantExpression(entry.value);
            }
          } else {
            reporter.internalError(
                computeSourceSpanFromTreeNode(invocation),
                "Unexpected named arguments value in createInvocationMirror: "
                "${namedArgumentsLiteral}.");
          }
          CallStructure callStructure = CallStructure(
              positionalArgumentsLiteral.expressions.length,
              namedArguments.keys.toList(),
              typeArguments.length);
          if (Selector.isOperatorName(name)) {
            selector =
                Selector(SelectorKind.OPERATOR, memberName, callStructure);
          } else {
            selector = Selector.call(memberName, callStructure);
          }
        }
        break;
    }

    HConstant nameConstant = graph.addConstant(
        constant_system.createSymbol(closedWorld.commonElements, name),
        closedWorld);

    List<HInstruction> arguments = [];
    for (ir.Expression argument in positionalArgumentsLiteral.expressions) {
      argument.accept(this);
      arguments.add(pop());
    }
    if (namedArguments.isNotEmpty) {
      Map<String, HInstruction> namedValues = {};
      namedArguments.forEach((String name, ir.Expression value) {
        value.accept(this);
        namedValues[name] = pop();
      });
      for (String name in selector!.callStructure.getOrderedNamedArguments()) {
        arguments.add(namedValues[name]!);
      }
    }

    final sourceInformation =
        _sourceInformationBuilder.buildCall(invocation, invocation);
    _addTypeArguments(arguments, typeArguments, sourceInformation);

    HInstruction argumentsInstruction = _buildLiteralList(arguments);
    add(argumentsInstruction);

    List<HInstruction> argumentNames = <HInstruction>[];
    for (String argumentName
        in selector!.callStructure.getOrderedNamedArguments()) {
      ConstantValue argumentNameConstant =
          constant_system.createString(argumentName);
      argumentNames.add(graph.addConstant(argumentNameConstant, closedWorld));
    }
    HInstruction argumentNamesInstruction = _buildLiteralList(argumentNames);
    add(argumentNamesInstruction);

    HInstruction typeArgumentCount =
        graph.addConstantInt(typeArguments.length, closedWorld);

    js.Name internalName = _namer.invocationName(selector);

    ConstantValue kindConstant =
        constant_system.createIntFromInt(selector.invocationMirrorKind);

    _pushStaticInvocation(
        _commonElements.createUnmangledInvocationMirror,
        [
          nameConstant,
          graph.addConstantStringFromName(internalName, closedWorld),
          graph.addConstant(kindConstant, closedWorld),
          argumentsInstruction,
          argumentNamesInstruction,
          typeArgumentCount,
        ],
        _abstractValueDomain.dynamicType,
        const <DartType>[],
        sourceInformation: sourceInformation);
  }

  bool _unexpectedForeignArguments(ir.StaticInvocation invocation,
      {required int minPositional,
      int? maxPositional,
      int typeArgumentCount = 0}) {
    String pluralizeArguments(int count, [String adjective = '']) {
      if (count == 0) return 'no ${adjective}arguments';
      if (count == 1) return 'one ${adjective}argument';
      if (count == 2) return 'two ${adjective}arguments';
      return '$count ${adjective}arguments';
    }

    String name() => invocation.target.name.text;

    ir.Arguments arguments = invocation.arguments;
    bool bad = false;
    if (arguments.types.length != typeArgumentCount) {
      String expected = pluralizeArguments(typeArgumentCount, 'type ');
      String actual = pluralizeArguments(arguments.types.length, 'type ');
      reporter.reportErrorMessage(
          _elementMap.getSpannable(targetElement, invocation),
          MessageKind.GENERIC,
          {'text': "Error: '${name()}' takes $expected, not $actual."});
      bad = true;
    }
    if (arguments.positional.length < minPositional) {
      String phrase = pluralizeArguments(minPositional);
      if (maxPositional != minPositional) phrase = 'at least $phrase';
      reporter.reportErrorMessage(
          _elementMap.getSpannable(targetElement, invocation),
          MessageKind.GENERIC,
          {'text': "Error: Too few arguments. '${name()}' takes $phrase."});
      bad = true;
    }
    if (maxPositional != null && arguments.positional.length > maxPositional) {
      String phrase = pluralizeArguments(maxPositional);
      if (maxPositional != minPositional) phrase = 'at most $phrase';
      reporter.reportErrorMessage(
          _elementMap.getSpannable(targetElement, invocation),
          MessageKind.GENERIC,
          {'text': "Error: Too many arguments. '${name()}' takes $phrase."});
      bad = true;
    }
    if (arguments.named.isNotEmpty) {
      reporter.reportErrorMessage(
          _elementMap.getSpannable(targetElement, invocation),
          MessageKind.GENERIC,
          {'text': "Error: '${name()}' does not take named arguments."});
      bad = true;
    }
    return bad;
  }

  /// Returns the value of the string argument. The argument must evaluate to a
  /// constant.  If there is an error, the error is reported and `null` is
  /// returned.
  String? _foreignConstantStringArgument(
      ir.StaticInvocation invocation, int position, String methodName,
      [String adjective = '']) {
    ir.Expression argument = invocation.arguments.positional[position];
    argument.accept(this);
    HInstruction instruction = pop();

    if (instruction is HConstant) {
      ConstantValue constant = instruction.constant;
      if (constant is StringConstantValue) return constant.stringValue;
    }

    reporter.reportErrorMessage(
        _elementMap.getSpannable(targetElement, argument),
        MessageKind.GENERIC, {
      'text': "Error: Expected String constant as ${adjective}argument "
          "to '$methodName'."
    });
    return null;
  }

  void _handleForeignDartClosureToJs(
      ir.StaticInvocation invocation, String name) {
    // TODO(sra): Do we need to wrap the closure in something that saves the
    // current isolate?
    _handleForeignRawFunctionRef(invocation, name);
  }

  void _handleForeignRawFunctionRef(
      ir.StaticInvocation invocation, String name) {
    if (_unexpectedForeignArguments(invocation,
        minPositional: 1, maxPositional: 1)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    ir.Expression closure = invocation.arguments.positional.single;
    String problem = 'requires a static method or top-level method';

    bool handleTarget(ir.Procedure procedure) {
      final function = procedure.function;
      if (function.requiredParameterCount ==
              function.positionalParameters.length &&
          function.namedParameters.isEmpty) {
        push(HFunctionReference(_elementMap.getMethod(procedure),
            _abstractValueDomain.dynamicType));
        return true;
      }
      problem = 'does not handle a closure with optional parameters';
      return false;
    }

    if (closure is ir.StaticGet) {
      ir.Member staticTarget = closure.target;
      if (staticTarget is ir.Procedure) {
        if (staticTarget.kind == ir.ProcedureKind.Method) {
          if (handleTarget(staticTarget)) {
            return;
          }
        }
      }
    } else if (closure is ir.ConstantExpression) {
      final tearOff = closure.constant;
      if (tearOff is ir.StaticTearOffConstant) {
        ir.Procedure member = tearOff.target;
        if (handleTarget(member)) {
          return;
        }
      }
    }

    reporter.reportErrorMessage(
        _elementMap.getSpannable(targetElement, invocation),
        MessageKind.GENERIC,
        {'text': "'$name' $problem."});
    stack.add(graph.addConstantNull(closedWorld)); // Result expected on stack.
    return;
  }

  void _handleJsRawException(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation,
        minPositional: 0, maxPositional: 0)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    if (_rethrowableException != null) {
      stack.add(_rethrowableException!);
      return;
    }

    reporter.reportErrorMessage(
        _elementMap.getSpannable(targetElement, invocation),
        MessageKind.GENERIC,
        {'text': "Error: JS_RAW_EXCEPTION() must be in a 'catch' block."});
    // Result expected on stack.
    stack.add(graph.addConstantNull(closedWorld));
  }

  void _handleForeignJsGetName(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation,
        minPositional: 1, maxPositional: 1)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    ir.Node argument = invocation.arguments.positional.first;
    argument.accept(this);
    HInstruction instruction = pop();

    if (instruction is HConstant) {
      final name = _getNameForJsGetName(instruction.constant, _namer)!;
      stack.add(graph.addConstantStringFromName(name, closedWorld));
      return;
    }

    reporter.reportErrorMessage(
        _elementMap.getSpannable(targetElement, argument),
        MessageKind.GENERIC,
        {'text': 'Error: Expected a JsGetName enum value.'});
    // Result expected on stack.
    stack.add(graph.addConstantNull(closedWorld));
  }

  int? _extractEnumIndexFromConstantValue(
      ConstantValue constant, ClassEntity classElement) {
    if (constant is ConstructedConstantValue &&
        constant.type.element == classElement) {
      assert(constant.fields.length >= 1);
      for (var field in constant.fields.keys) {
        if (field.memberName.text == "index") {
          final indexConstant = constant.fields[field];
          if (indexConstant is IntConstantValue) {
            return indexConstant.intValue.toInt();
          }
          break;
        }
      }
    }
    return null;
  }

  /// Returns the [js.Name] for the `JsGetName` [constant] value.
  js.Name? _getNameForJsGetName(ConstantValue constant, ModularNamer namer) {
    final index = _extractEnumIndexFromConstantValue(
        constant, _commonElements.jsGetNameEnum);
    if (index == null) return null;
    return namer.getNameForJsGetName(
        CURRENT_ELEMENT_SPANNABLE, JsGetName.values[index]);
  }

  void _handleForeignJsEmbeddedGlobal(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation,
        minPositional: 2, maxPositional: 2)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }
    final globalName = _foreignConstantStringArgument(
        invocation, 1, 'JS_EMBEDDED_GLOBAL', 'second ')!;
    js.Template expr = js.js.expressionTemplateYielding(
        _emitter.generateEmbeddedGlobalAccess(globalName));

    NativeBehavior nativeBehavior =
        _elementMap.getNativeBehaviorForJsEmbeddedGlobalCall(invocation);

    AbstractValue ssaType =
        _typeInferenceMap.typeFromNativeBehavior(nativeBehavior, closedWorld);
    push(HForeignCode(expr, ssaType, const <HInstruction>[],
        nativeBehavior: nativeBehavior));
  }

  void _handleForeignJsBuiltin(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, minPositional: 2)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    List<ir.Expression> arguments = invocation.arguments.positional;
    ir.Expression nameArgument = arguments[1];

    nameArgument.accept(this);
    HInstruction instruction = pop();

    js.Template? template;
    if (instruction is HConstant) {
      template = _getJsBuiltinTemplate(instruction.constant, _emitter);
    }
    if (template == null) {
      reporter.reportErrorMessage(
          _elementMap.getSpannable(targetElement, nameArgument),
          MessageKind.GENERIC,
          {'text': 'Error: Expected a JsBuiltin enum value.'});
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    List<HInstruction> inputs = [];
    for (ir.Expression argument in arguments.skip(2)) {
      argument.accept(this);
      inputs.add(pop());
    }

    NativeBehavior nativeBehavior =
        _elementMap.getNativeBehaviorForJsBuiltinCall(invocation);

    AbstractValue ssaType =
        _typeInferenceMap.typeFromNativeBehavior(nativeBehavior, closedWorld);
    push(HForeignCode(template, ssaType, inputs,
        nativeBehavior: nativeBehavior));
  }

  /// Returns the [js.Template] for the `JsBuiltin` [constant] value.
  js.Template? _getJsBuiltinTemplate(
      ConstantValue constant, ModularEmitter emitter) {
    final index = _extractEnumIndexFromConstantValue(
        constant, _commonElements.jsBuiltinEnum);
    if (index == null) return null;
    return _templateForBuiltin(JsBuiltin.values[index]);
  }

  /// Returns the JS template for the given [builtin].
  js.Template? _templateForBuiltin(JsBuiltin builtin) {
    switch (builtin) {
      case JsBuiltin.dartObjectConstructor:
        ClassEntity objectClass = closedWorld.commonElements.objectClass;
        return js.js.expressionTemplateYielding(
            _emitter.constructorAccess(objectClass));

      case JsBuiltin.dartClosureConstructor:
        ClassEntity closureClass = closedWorld.commonElements.closureClass;
        // TODO(sra): Should add a dependency on the constructor used as a
        // token.
        registry
            // ignore:deprecated_member_use_from_same_package
            .registerInstantiatedClass(closureClass);
        return js.js.expressionTemplateYielding(
            _emitter.constructorAccess(closureClass));

      case JsBuiltin.getMetadata:
        String metadataAccess =
            _emitter.generateEmbeddedGlobalAccessString(METADATA);
        return js.js.expressionTemplateFor("$metadataAccess[#]");

      case JsBuiltin.getType:
        String typesAccess = _emitter.generateEmbeddedGlobalAccessString(TYPES);
        return js.js.expressionTemplateFor("$typesAccess[#]");

      default:
        reporter.internalError(
            NO_LOCATION_SPANNABLE, "Unhandled Builtin: $builtin");
        return null;
    }
  }

  void _handleForeignJsGetFlag(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation,
        minPositional: 1, maxPositional: 1)) {
      stack.add(
          // Result expected on stack.
          graph.addConstantBool(false, closedWorld));
      return;
    }
    String name = _foreignConstantStringArgument(invocation, 0, 'JS_GET_FLAG')!;
    final value = _getFlagValue(name);
    if (value == null) {
      reporter.reportErrorMessage(
          _elementMap.getSpannable(targetElement, invocation),
          MessageKind.GENERIC,
          {'text': 'Error: Unknown internal flag "$name".'});
    } else {
      stack.add(graph.addConstantBool(value, closedWorld));
    }
  }

  void _handleJsInterceptorConstant(ir.StaticInvocation invocation) {
    // Single argument must be a TypeConstant which is converted into a
    // InterceptorConstant.
    if (_unexpectedForeignArguments(invocation,
        minPositional: 1, maxPositional: 1)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }
    ir.Expression argument = invocation.arguments.positional.single;
    argument.accept(this);
    HInstruction argumentInstruction = pop();
    if (argumentInstruction is HConstant) {
      ConstantValue argumentConstant = argumentInstruction.constant;
      if (argumentConstant is TypeConstantValue) {
        final interfaceType =
            argumentConstant.representedType.withoutNullability;
        if (interfaceType is InterfaceType) {
          // TODO(sra): Check that type is a subclass of [Interceptor].
          ConstantValue constant =
              InterceptorConstantValue(interfaceType.element);
          HInstruction instruction = graph.addConstant(constant, closedWorld);
          stack.add(instruction);
          return;
        }
      }
    }

    reporter.reportErrorMessage(
        _elementMap.getSpannable(targetElement, invocation),
        MessageKind.WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT);
    stack.add(graph.addConstantNull(closedWorld));
  }

  void _handleForeignGetInterceptor(ir.StaticInvocation invocation) {
    // Single argument is the intercepted object.
    if (_unexpectedForeignArguments(invocation,
        minPositional: 1, maxPositional: 1)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }
    ir.Expression argument = invocation.arguments.positional.single;
    argument.accept(this);
    HInstruction argumentInstruction = pop();

    final sourceInformation =
        _sourceInformationBuilder.buildCall(invocation, invocation);
    HInstruction instruction =
        _interceptorFor(argumentInstruction, sourceInformation);
    stack.add(instruction);
  }

  void _handleForeignGetJSArrayInteropRti(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation,
        minPositional: 0, maxPositional: 0)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }
    // TODO(sra): This should be JSArray<any>, created via
    // _elementEnvironment.getJsInteropType(_elementEnvironment.jsArrayClass);
    InterfaceType interopType = dartTypes
        .interfaceType(_commonElements.jsArrayClass, [dartTypes.dynamicType()]);
    final sourceInformation =
        _sourceInformationBuilder.buildCall(invocation, invocation);
    HInstruction rti =
        HLoadType.type(interopType, _abstractValueDomain.dynamicType)
          ..sourceInformation = sourceInformation;
    push(rti);
  }

  bool _equivalentToMissingRti(InterfaceType type) {
    assert(type.element == _commonElements.jsArrayClass);
    return dartTypes.isStrongTopType(type.typeArguments.single);
  }

  void _handleForeignJs(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation,
        minPositional: 2, maxPositional: null, typeArgumentCount: 1)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    NativeBehavior nativeBehavior =
        _elementMap.getNativeBehaviorForJsCall(invocation);

    List<HInstruction> inputs = [];
    for (ir.Expression argument in invocation.arguments.positional.skip(2)) {
      argument.accept(this);
      inputs.add(pop());
    }

    final codeTemplate = nativeBehavior.codeTemplate!;

    if (codeTemplate.positionalArgumentCount != inputs.length) {
      reporter.reportErrorMessage(
          _elementMap.getSpannable(targetElement, invocation),
          MessageKind.GENERIC, {
        'text': 'Mismatch between number of placeholders'
            ' and number of arguments.'
      });
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    if (HasCapturedPlaceholders.check(codeTemplate.ast)) {
      reporter.reportErrorMessage(
          _elementMap.getSpannable(targetElement, invocation),
          MessageKind.JS_PLACEHOLDER_CAPTURE);
    }

    AbstractValue ssaType =
        _typeInferenceMap.typeFromNativeBehavior(nativeBehavior, closedWorld);

    SourceInformation? sourceInformation;
    HInstruction code = HForeignCode(codeTemplate, ssaType, inputs,
        isStatement: !codeTemplate.isExpression,
        effects: nativeBehavior.sideEffects,
        nativeBehavior: nativeBehavior)
      ..sourceInformation = sourceInformation;
    push(code);

    DartType type = _getDartTypeIfValid(invocation.arguments.types.single);
    final trustedMask = _typeBuilder.trustTypeMask(type);

    if (trustedMask != null) {
      // We only allow the type argument to narrow `dynamic`, which probably
      // comes from an unspecified return type in the NativeBehavior.
      if (_abstractValueDomain
          .containsAll(code.instructionType)
          .isPotentiallyTrue) {
        // Overwrite the type with the narrower type.
        code.instructionType = trustedMask;
      }
      // It is acceptable for the type parameter to be broader than the
      // specified type.
    }

    _maybeAddNullCheckOnJS(invocation);
  }

  /// If [invocation] is a `JS()` invocation in a web library and the static
  /// type is non-nullable, add a check to make sure it isn't null.
  void _maybeAddNullCheckOnJS(ir.StaticInvocation invocation) {
    if (options.nativeNullAssertions &&
        nodeIsInWebLibrary(invocation) &&
        closedWorld.dartTypes
            .isNonNullableIfSound(_getStaticType(invocation).type)) {
      HInstruction code = pop();
      push(HNullCheck(
          code, _abstractValueDomain.excludeNull(code.instructionType),
          sticky: true));
    }
  }

  void _handleJsStringConcat(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation,
        minPositional: 2, maxPositional: 2)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }
    List<HInstruction> inputs = _visitPositionalArguments(invocation.arguments);
    push(HStringConcat(inputs[0], inputs[1], _abstractValueDomain.stringType));
  }

  void _handleCharCodeAt(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation,
        minPositional: 2, maxPositional: 2)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }
    List<HInstruction> inputs = _visitPositionalArguments(invocation.arguments);
    push(HCharCodeAt(inputs[0], inputs[1], _abstractValueDomain.uint31Type));
  }

  void _handleForeignTypeRef(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation,
        minPositional: 0, maxPositional: 0, typeArgumentCount: 1)) {
      stack.add(
          // Result expected on stack.
          graph.addConstantNull(closedWorld));
      return;
    }
    DartType type = _elementMap.getDartType(invocation.arguments.types.single);
    final sourceInformation =
        _sourceInformationBuilder.buildCall(invocation, invocation);
    push(HLoadType.type(type, _abstractValueDomain.dynamicType)
      ..sourceInformation = sourceInformation);
  }

  void _handleForeignLegacyTypeRef(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation,
        minPositional: 0, maxPositional: 0, typeArgumentCount: 1)) {
      stack.add(
          // Result expected on stack.
          graph.addConstantNull(closedWorld));
      return;
    }
    DartType type = closedWorld.dartTypes
        .legacyType(_elementMap.getDartType(invocation.arguments.types.single));
    final sourceInformation =
        _sourceInformationBuilder.buildCall(invocation, invocation);
    push(HLoadType.type(type, _abstractValueDomain.dynamicType)
      ..sourceInformation = sourceInformation);
  }

  void _handleForeignCreateJsSentinel(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation,
        minPositional: 0, maxPositional: 0, typeArgumentCount: 1)) {
      stack.add(
          // Result expected on stack.
          graph.addConstantNull(closedWorld));
      return;
    }

    final sourceInformation =
        _sourceInformationBuilder.buildCall(invocation, invocation);
    stack.add(graph.addConstantLateSentinel(closedWorld,
        sourceInformation: sourceInformation));
  }

  void _handleForeignIsJsSentinel(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation,
        minPositional: 1, maxPositional: 1)) {
      stack.add(
          // Result expected on stack.
          graph.addConstantNull(closedWorld));
      return;
    }

    final sourceInformation =
        _sourceInformationBuilder.buildCall(invocation, invocation);
    HInstruction checkedExpression =
        _visitPositionalArguments(invocation.arguments).single;
    push(HIsLateSentinel(checkedExpression, _abstractValueDomain.boolType)
      ..sourceInformation = sourceInformation);
  }

  // TODO(fishythefish): Support specialization of late sentinels based on type.

  void _handleLateReadCheck(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation,
        minPositional: 2, maxPositional: 2, typeArgumentCount: 1)) {
      stack.add(
          // Result expected on stack.
          graph.addConstantNull(closedWorld));
      return;
    }

    final sourceInformation =
        _sourceInformationBuilder.buildCall(invocation, invocation);

    List<HInstruction> arguments =
        _visitPositionalArguments(invocation.arguments);
    HInstruction value = arguments[0];
    final name = options.omitLateNames ? null : arguments[1];

    CheckPolicy policy =
        closedWorld.annotationsData.getLateVariableCheckPolicyAt(invocation);

    push(HLateReadCheck(value, name, policy.isTrusted,
        _abstractValueDomain.excludeLateSentinel(value.instructionType))
      ..sourceInformation = sourceInformation);
  }

  void _handleLateWriteOnceCheck(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation,
        minPositional: 2, maxPositional: 2)) {
      stack.add(
          // Result expected on stack.
          graph.addConstantNull(closedWorld));
      return;
    }

    final sourceInformation =
        _sourceInformationBuilder.buildCall(invocation, invocation);

    List<HInstruction> arguments =
        _visitPositionalArguments(invocation.arguments);
    HInstruction value = arguments[0];
    final name = options.omitLateNames ? null : arguments[1];

    CheckPolicy policy =
        closedWorld.annotationsData.getLateVariableCheckPolicyAt(invocation);

    push(HLateWriteOnceCheck(
        value, name, policy.isTrusted, _abstractValueDomain.dynamicType)
      ..sourceInformation = sourceInformation);
  }

  void _handleLateInitializeOnceCheck(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation,
        minPositional: 2, maxPositional: 2)) {
      stack.add(
          // Result expected on stack.
          graph.addConstantNull(closedWorld));
      return;
    }

    final sourceInformation =
        _sourceInformationBuilder.buildCall(invocation, invocation);

    List<HInstruction> arguments =
        _visitPositionalArguments(invocation.arguments);
    HInstruction value = arguments[0];
    final name = options.omitLateNames ? null : arguments[1];

    CheckPolicy policy =
        closedWorld.annotationsData.getLateVariableCheckPolicyAt(invocation);

    push(HLateInitializeOnceCheck(
        value, name, policy.isTrusted, _abstractValueDomain.dynamicType)
      ..sourceInformation = sourceInformation);
  }

  void _pushStaticInvocation(
      FunctionEntity target,
      List<HInstruction> arguments,
      AbstractValue typeMask,
      List<DartType> typeArguments,
      {SourceInformation? sourceInformation,
      InterfaceType? instanceType}) {
    // TODO(redemption): Pass current node if needed.
    if (_tryInlineMethod(
        target, null, null, arguments, typeArguments, null, sourceInformation,
        instanceType: instanceType)) {
      return;
    }

    if (closedWorld.nativeData.isJsInteropMember(target)) {
      _pushStaticNativeInvocation(target, arguments, typeMask, typeArguments);
      return;
    }

    HInvokeStatic instruction = HInvokeStatic(
        target, arguments, typeMask, typeArguments,
        targetCanThrow: !_inferredData.getCannotThrow(target))
      ..sourceInformation = sourceInformation;

    if (_currentImplicitInstantiations.isNotEmpty) {
      instruction.instantiatedTypes =
          List<InterfaceType>.from(_currentImplicitInstantiations);
    }
    instruction.sideEffects = _inferredData.getSideEffectsOfElement(target);
    push(instruction);
  }

  void _pushStaticNativeInvocation(
      FunctionEntity target,
      List<HInstruction?> arguments,
      AbstractValue typeMask,
      List<DartType> typeArguments) {
    push(_invokeJsInteropFunction(target, arguments));
    return;
  }

  void _pushDynamicInvocation(
      ir.Node node,
      StaticType staticReceiverType,
      AbstractValue? receiverType,
      Selector selector,
      List<HInstruction> arguments,
      List<DartType> typeArguments,
      SourceInformation? sourceInformation) {
    AbstractValue typeBound = _abstractValueDomain
        .createFromStaticType(staticReceiverType.type,
            classRelation: staticReceiverType.relation, nullable: true)
        .abstractValue;
    receiverType = receiverType == null
        ? typeBound
        : _abstractValueDomain.intersection(receiverType, typeBound);

    // We prefer to not inline certain operations on indexables,
    // because the constant folder will handle them better and turn
    // them into simpler instructions that allow further
    // optimizations.
    bool isOptimizableOperationOnIndexable(
        Selector selector, MemberEntity element) {
      bool isLength = selector.isGetter && selector.name == "length";
      if (isLength || selector.isIndex) {
        return closedWorld.classHierarchy.isSubtypeOf(
            element.enclosingClass!, _commonElements.jsIndexableClass);
      } else if (selector.isIndexSet) {
        return closedWorld.classHierarchy.isSubtypeOf(
            element.enclosingClass!, _commonElements.jsMutableIndexableClass);
      } else {
        return false;
      }
    }

    bool isOptimizableOperation(Selector selector, MemberEntity element) {
      final cls = element.enclosingClass;
      if (isOptimizableOperationOnIndexable(selector, element)) return true;
      if (!_interceptorData.interceptedClasses.contains(cls)) return false;
      if (selector.isOperator) return true;
      if (selector.isSetter) return true;
      if (selector.isIndex) return true;
      if (selector.isIndexSet) return true;
      if (element == _commonElements.jsArrayAdd ||
          element == _commonElements.jsArrayRemoveLast ||
          _commonElements.isJsStringSplit(element)) {
        return true;
      }
      return false;
    }

    final element = closedWorld.locateSingleMember(selector, receiverType);
    if (element != null &&
        element is FunctionEntity &&
        !(element.isGetter && selector.isCall) &&
        !(element.isFunction && selector.isGetter) &&
        !isOptimizableOperation(selector, element)) {
      if (_tryInlineMethod(element, selector, receiverType, arguments,
          typeArguments, node, sourceInformation)) {
        return;
      }
    }

    HInstruction receiver = arguments.first;
    List<HInstruction> inputs = [];

    bool isIntercepted =
        closedWorld.interceptorData.isInterceptedSelector(selector);

    if (isIntercepted) {
      HInterceptor interceptor = _interceptorFor(receiver, sourceInformation);
      inputs.add(interceptor);
    }
    inputs.addAll(arguments);

    AbstractValue resultType =
        _typeInferenceMap.resultTypeOfSelector(selector, receiverType);
    HInvokeDynamic invoke;
    if (selector.isGetter) {
      _metrics.countGettersTotal.add();
      invoke = HInvokeDynamicGetter(selector, receiverType, element, inputs,
          isIntercepted, resultType, sourceInformation);
    } else if (selector.isSetter) {
      _metrics.countSettersTotal.add();
      invoke = HInvokeDynamicSetter(selector, receiverType, element, inputs,
          isIntercepted, resultType, sourceInformation);
    } else if (selector.isClosureCall) {
      assert(!isIntercepted);
      invoke = HInvokeClosure(
          selector, receiverType, inputs, resultType, typeArguments)
        ..sourceInformation = sourceInformation;
    } else {
      invoke = HInvokeDynamicMethod(selector, receiverType, inputs, resultType,
          typeArguments, sourceInformation,
          isIntercepted: isIntercepted);
    }
    invoke.instructionContext = _currentFrame!.member;
    if (node is ir.InstanceInvocation) {
      invoke.isInvariant = node.isInvariant;
      invoke.isBoundsSafe = node.isBoundsSafe;
    }
    push(invoke);
  }

  HInstruction _invokeJsInteropFunction(
      FunctionEntity element, List<HInstruction?> arguments) {
    assert(closedWorld.nativeData.isJsInteropMember(element));

    bool isAnonymousFactory = element is ConstructorEntity &&
        element.isFactoryConstructor &&
        _nativeData.isAnonymousJsInteropClass(element.enclosingClass);
    ir.Node node = _elementMap.getMemberDefinition(element).node;
    // JS interop checks assert that the only inline class interop member that
    // has named parameters is an object literal constructor. We could do a more
    // robust check by visiting all inline classes and recording descriptors,
    // but that's expensive.
    bool isObjectLiteralConstructor = node is ir.Procedure &&
        node.isInlineClassMember &&
        node.function.namedParameters.isNotEmpty;
    if (isAnonymousFactory || isObjectLiteralConstructor) {
      // Constructor that is syntactic sugar for creating a JavaScript object
      // literal.
      int i = 0;
      int positions = 0;
      List<HInstruction> filteredArguments = [];
      Map<String, js.Expression> parameterNameMap = {};

      // Note: we don't use `constructor.parameterStructure` here because
      // we don't elide parameters to js-interop external static targets
      // (including factory constructors.)
      // TODO(johnniwinther): can we elide those parameters? This should be
      // consistent with what we do with instance methods.
      final procedure = node as ir.Procedure;
      List<ir.VariableDeclaration> namedParameters =
          procedure.function.namedParameters.toList();

      namedParameters.sort(nativeOrdering);
      for (ir.VariableDeclaration variable in namedParameters) {
        String parameterName = variable.name!;
        // TODO(jacobr): consider throwing if parameter names do not match
        // names of properties in the class.
        final argument = arguments[i];
        if (argument != null) {
          filteredArguments.add(argument);
          var jsName = _nativeData.computeUnescapedJSInteropName(parameterName);
          parameterNameMap[jsName] = js.InterpolatedExpression(positions++);
        }
        i++;
      }
      var codeTemplate = js.Template(null, js.objectLiteral(parameterNameMap));

      var nativeBehavior = NativeBehavior()..codeTemplate = codeTemplate;
      registry.registerNativeMethod(element);
      // TODO(efortuna): Source information.
      return HForeignCode(
          codeTemplate, _abstractValueDomain.dynamicType, filteredArguments,
          nativeBehavior: nativeBehavior);
    }

    // Strip off trailing arguments that were not specified.
    // we could assert that the trailing arguments are all null.
    // TODO(jacobr): rewrite named arguments to an object literal matching
    // the factory constructor case.
    List<HInstruction> inputs = arguments.whereType<HInstruction>().toList();

    var nativeBehavior = NativeBehavior()..sideEffects.setAllSideEffects();

    DartType type = element is ConstructorEntity
        ? _elementEnvironment.getThisType(element.enclosingClass)
        : _elementEnvironment.getFunctionType(element).returnType;
    // Native behavior effects here are similar to native/behavior.dart.
    // The return type is dynamic because we don't trust js-interop type
    // declarations.
    nativeBehavior.typesReturned.add(dartTypes.dynamicType());

    // The allocation effects include the declared type if it is native (which
    // includes js interop types).
    type = type.withoutNullability;
    if (type is InterfaceType && _nativeData.isNativeClass(type.element)) {
      nativeBehavior.typesInstantiated.add(type);
    }

    // It also includes any other JS interop type. Technically, a JS interop API
    // could return anything, so the sound thing to do would be to assume that
    // anything that may come from JS as instantiated. In order to prevent the
    // resulting code bloat (e.g. from `dart:html`), we unsoundly assume that
    // only JS interop types are returned.
    nativeBehavior.typesInstantiated.add(_elementEnvironment
        .getThisType(_commonElements.jsLegacyJavaScriptObjectClass));

    AbstractValue instructionType =
        _typeInferenceMap.typeFromNativeBehavior(nativeBehavior, closedWorld);

    // TODO(efortuna): Add source information.
    return HInvokeExternal(element, inputs, instructionType, nativeBehavior,
        sourceInformation: null);
  }

  @override
  void visitFunctionNode(ir.FunctionNode node) {
    final sourceInformation = _sourceInformationBuilder.buildCreate(node);
    ClosureRepresentationInfo closureInfo =
        _closureDataLookup.getClosureInfo(node.parent as ir.LocalFunction);
    ClassEntity closureClassEntity = closureInfo.closureClassEntity!;

    List<HInstruction> capturedVariables = [];
    _elementEnvironment.forEachInstanceField(closureClassEntity,
        (_, FieldEntity field) {
      if (_fieldAnalysis.getFieldData(field).isElided) return;
      capturedVariables.add(localsHandler
          .readLocal(closureInfo.getLocalForField(_localsMap, field)));
    });

    AbstractValue type =
        _abstractValueDomain.createNonNullExact(closureClassEntity);
    // TODO(efortuna): Add source information here.
    push(HCreate(closureClassEntity, capturedVariables, type, sourceInformation,
        callMethod: closureInfo.callMethod));
  }

  @override
  void visitFunctionDeclaration(ir.FunctionDeclaration declaration) {
    assert(_isReachable);
    declaration.function.accept(this);
    Local local = _localsMap.getLocalVariable(declaration.variable);
    localsHandler.updateLocal(local, pop());
  }

  @override
  void visitFunctionExpression(ir.FunctionExpression funcExpression) {
    funcExpression.function.accept(this);
  }

  @override
  void visitInstantiation(ir.Instantiation node) {
    List<HInstruction> arguments = [];
    node.expression.accept(this);
    arguments.add(pop());

    // A generic function instantiation is created by calling a helper function
    // which takes the arguments.
    int typeArgumentCount = node.typeArguments.length;
    FunctionEntity target =
        _commonElements.getInstantiateFunction(typeArgumentCount);

    StaticType expressionType = _getStaticType(node.expression);
    final functionType = expressionType.type.withoutNullability as FunctionType;
    bool typeArgumentsNeeded = _rtiNeed.methodNeedsTypeArguments(target);

    List<DartType> typeArguments = node.typeArguments
        .map((type) => typeArgumentsNeeded
            ? _elementMap.getDartType(type)
            : _commonElements.dynamicType)
        .toList();
    registry.registerGenericInstantiation(
        GenericInstantiation(functionType, typeArguments));

    // TODO(sra): Add instantiations to SourceInformationBuilder.
    SourceInformation? sourceInformation;

    // TODO(47484): Allow callee to have different calling convention for type
    // arguments.
    if (typeArgumentsNeeded) {
      _addTypeArguments(arguments, typeArguments, sourceInformation);
    }

    bool targetCanThrow = false; // TODO(sra): Is this true?

    // TODO(sra): Use [_pushStaticInvocation] to allow inlining. We don't now
    // because inference can't tell that the call has no side-effects.
    HInstruction instruction = HInvokeStatic(
        target, arguments, _abstractValueDomain.functionType, <DartType>[],
        targetCanThrow: targetCanThrow);
    instruction.sourceInformation = sourceInformation;
    instruction.sideEffects
      ..clearAllDependencies()
      ..clearAllSideEffects();

    push(instruction);
  }

  void _handleMethodInvocation(
      ir.Expression node, ir.Expression receiver, ir.Arguments arguments,
      {bool isImplicitCall = false}) {
    receiver.accept(this);
    HInstruction receiverInstruction = pop();
    Selector selector = _elementMap.getSelector(node);
    List<DartType> typeArguments = [];
    selector = _fillDynamicTypeArguments(selector, arguments, typeArguments,
        isImplicitCall: isImplicitCall);
    _pushDynamicInvocation(
        node,
        _getStaticType(receiver),
        _typeInferenceMap.receiverTypeOfInvocation(node, _abstractValueDomain),
        selector,
        [
          receiverInstruction,
          ..._visitArgumentsForDynamicTarget(selector, arguments, typeArguments)
        ],
        typeArguments,
        _sourceInformationBuilder.buildCall(receiver, node));
  }

  @override
  void visitInstanceInvocation(ir.InstanceInvocation node) {
    _handleMethodInvocation(node, node.receiver, node.arguments);
  }

  @override
  void visitInstanceGetterInvocation(ir.InstanceGetterInvocation node) {
    _handleMethodInvocation(node, node.receiver, node.arguments,
        isImplicitCall: true);
  }

  @override
  void visitDynamicInvocation(ir.DynamicInvocation node) {
    _handleMethodInvocation(node, node.receiver, node.arguments);
  }

  @override
  void visitFunctionInvocation(ir.FunctionInvocation node) {
    _handleMethodInvocation(node, node.receiver, node.arguments);
  }

  @override
  void visitLocalFunctionInvocation(ir.LocalFunctionInvocation node) {
    Local local = _localsMap.getLocalVariable(node.variable);
    stack.add(localsHandler.readLocal(local,
        sourceInformation: _sourceInformationBuilder.buildGet(node)));
    HInstruction receiverInstruction = pop();
    Selector selector = _elementMap.getSelector(node);
    List<DartType> typeArguments = [];
    selector =
        _fillDynamicTypeArguments(selector, node.arguments, typeArguments);
    _pushDynamicInvocation(
        node,
        StaticType(_elementMap.getDartType(node.variable.type),
            computeClassRelationFromType(node.variable.type)),
        _typeInferenceMap.receiverTypeOfInvocation(node, _abstractValueDomain),
        selector,
        [
          receiverInstruction,
          ..._visitArgumentsForDynamicTarget(
              selector, node.arguments, typeArguments)
        ],
        typeArguments,
        _sourceInformationBuilder.buildCall(node, node));
  }

  void _handleEquals(ir.Expression node, ir.Expression left,
      HInstruction leftInstruction, HInstruction rightInstruction) {
    _pushDynamicInvocation(
        node,
        _getStaticType(left),
        _typeInferenceMap.receiverTypeOfInvocation(node, _abstractValueDomain),
        Selectors.equals,
        [leftInstruction, rightInstruction],
        const <DartType>[],
        _sourceInformationBuilder.buildCall(left, node));
  }

  @override
  void visitEqualsNull(ir.EqualsNull node) {
    node.expression.accept(this);
    HInstruction receiverInstruction = pop();
    _handleEquals(node, node.expression, receiverInstruction,
        graph.addConstantNull(closedWorld));
  }

  @override
  void visitEqualsCall(ir.EqualsCall node) {
    node.left.accept(this);
    HInstruction leftInstruction = pop();
    node.right.accept(this);
    HInstruction rightInstruction = pop();
    return _handleEquals(node, node.left, leftInstruction, rightInstruction);
  }

  HInterceptor _interceptorFor(
      HInstruction intercepted, SourceInformation? sourceInformation) {
    HInterceptor interceptor =
        HInterceptor(intercepted, _abstractValueDomain.nonNullType)
          ..sourceInformation = sourceInformation;
    add(interceptor);
    return interceptor;
  }

  static ir.Class _containingClass(ir.TreeNode? node) {
    while (node != null) {
      if (node is ir.Class) return node;
      node = node.parent;
    }
    throw ArgumentError.value(node, 'node', 'No containing class found.');
  }

  void _generateSuperNoSuchMethod(
      ir.Expression invocation,
      String publicName,
      List<HInstruction> arguments,
      List<DartType> typeArguments,
      SourceInformation? sourceInformation) {
    Selector selector = _elementMap.getSelector(invocation);
    ClassEntity containingClass =
        _elementMap.getClass(_containingClass(invocation));
    FunctionEntity noSuchMethod =
        _elementMap.getSuperNoSuchMethod(containingClass);

    ConstantValue nameConstant = constant_system.createString(publicName);

    js.Name internalName = _namer.invocationName(selector);

    var argumentsInstruction = _buildLiteralList(arguments);
    add(argumentsInstruction);

    List<HInstruction> argumentNames = [];
    for (String argumentName in selector.namedArguments) {
      ConstantValue argumentNameConstant =
          constant_system.createString(argumentName);
      argumentNames.add(graph.addConstant(argumentNameConstant, closedWorld));
    }
    var argumentNamesInstruction = _buildLiteralList(argumentNames);
    add(argumentNamesInstruction);

    ConstantValue kindConstant =
        constant_system.createIntFromInt(selector.invocationMirrorKind);

    _pushStaticInvocation(
        _commonElements.createInvocationMirror,
        [
          graph.addConstant(nameConstant, closedWorld),
          graph.addConstantStringFromName(internalName, closedWorld),
          graph.addConstant(kindConstant, closedWorld),
          argumentsInstruction,
          argumentNamesInstruction,
          graph.addConstantInt(typeArguments.length, closedWorld),
        ],
        _abstractValueDomain.dynamicType,
        typeArguments,
        sourceInformation: sourceInformation);

    _buildInvokeSuper(Selectors.noSuchMethod_, containingClass, noSuchMethod,
        [pop()], typeArguments, sourceInformation);
  }

  HInstruction _buildInvokeSuper(
      Selector selector,
      ClassEntity containingClass,
      MemberEntity target,
      List<HInstruction> arguments,
      List<DartType> typeArguments,
      SourceInformation? sourceInformation) {
    HInstruction receiver =
        localsHandler.readThis(sourceInformation: sourceInformation);

    List<HInstruction> inputs = [];
    bool isIntercepted =
        closedWorld.interceptorData.isInterceptedSelector(selector);
    if (isIntercepted) {
      inputs.add(_interceptorFor(receiver, sourceInformation));
    }
    inputs.add(receiver);
    inputs.addAll(arguments);

    late final AbstractValue typeMask;
    if (selector.isGetter && target.isGetter ||
        !selector.isGetter && target is FunctionEntity) {
      typeMask = _typeInferenceMap.getReturnTypeOf(target as FunctionEntity);
    } else {
      typeMask = _abstractValueDomain.dynamicType;
    }
    HInstruction instruction = HInvokeSuper(target, containingClass, selector,
        inputs, isIntercepted, typeMask, typeArguments, sourceInformation,
        isSetter: selector.isSetter || selector.isIndexSet);
    // TODO(natebiggs): Pass typeMask below and make non-nullable.
    instruction.sideEffects =
        _inferredData.getSideEffectsOfSelector(selector, null);
    push(instruction);
    return instruction;
  }

  @override
  void visitSuperPropertyGet(ir.SuperPropertyGet node) {
    final sourceInformation = _sourceInformationBuilder.buildGet(node);
    final target = getEffectiveSuperTarget(node.interfaceTarget);
    if (target == null) {
      // TODO(johnniwinther): Remove this when the CFE checks for missing
      //  concrete super targets.
      _generateSuperNoSuchMethod(node, _elementMap.getSelector(node).name,
          const <HInstruction>[], const <DartType>[], sourceInformation);
      return;
    }
    MemberEntity member = _elementMap.getMember(target);
    if (member is FieldEntity) {
      FieldAnalysisData fieldData = _fieldAnalysis.getFieldData(member);
      if (fieldData.isEffectivelyConstant) {
        final value = fieldData.constantValue!;
        stack.add(graph.addConstant(value, closedWorld,
            sourceInformation: sourceInformation));
        return;
      }
    }
    _buildInvokeSuper(
        _elementMap.getSelector(node),
        _elementMap.getClass(_containingClass(node)),
        member,
        const <HInstruction>[],
        const <DartType>[],
        sourceInformation);
  }

  @override
  void visitSuperMethodInvocation(ir.SuperMethodInvocation node) {
    final sourceInformation = _sourceInformationBuilder.buildCall(node, node);
    final superTarget = getEffectiveSuperTarget(node.interfaceTarget);
    if (superTarget == null) {
      // TODO(johnniwinther): Remove this when the CFE checks for missing
      //  concrete super targets.
      Selector selector = _elementMap.getSelector(node);
      List<DartType> typeArguments = <DartType>[];
      selector =
          _fillDynamicTypeArguments(selector, node.arguments, typeArguments);
      List<HInstruction> arguments = _visitArgumentsForDynamicTarget(
          selector, node.arguments, typeArguments);
      _generateSuperNoSuchMethod(
          node, selector.name, arguments, typeArguments, sourceInformation);
      return;
    }
    MemberEntity member = _elementMap.getMember(superTarget);
    List<DartType> typeArguments =
        _getStaticTypeArguments(member as FunctionEntity, node.arguments);

    MemberDefinition targetDefinition = _elementMap.getMemberDefinition(member);
    final target = targetDefinition.node as ir.Procedure;
    List<HInstruction> arguments = _visitArgumentsForStaticTarget(
        target,
        target.function,
        member.parameterStructure,
        node.arguments,
        typeArguments,
        sourceInformation);
    _buildInvokeSuper(
        _elementMap.getSelector(node),
        _elementMap.getClass(_containingClass(node)),
        member,
        arguments,
        typeArguments,
        sourceInformation);
  }

  void _checkTypeBound(HInstruction typeInstruction, DartType bound,
      String variableName, String methodName) {
    HInstruction boundInstruction = _typeBuilder.analyzeTypeArgumentNewRti(
        localsHandler.substInContext(bound), sourceElement);

    HInstruction variableNameInstruction =
        graph.addConstantString(variableName, closedWorld);
    HInstruction methodNameInstruction =
        graph.addConstantString(methodName, closedWorld);
    FunctionEntity element = _commonElements.checkTypeBound;
    List<HInstruction> inputs = [
      typeInstruction,
      boundInstruction,
      variableNameInstruction,
      methodNameInstruction,
    ];
    HInstruction checkBound = HInvokeStatic(
        element, inputs, typeInstruction.instructionType, const <DartType>[]);
    add(checkBound);
  }

  @override
  void visitConstructorInvocation(ir.ConstructorInvocation node) {
    final sourceInformation = _sourceInformationBuilder.buildNew(node);
    ir.Constructor target = node.target;
    if (node.isConst) {
      ConstantValue constant =
          _elementMap.getConstantValue(_memberContextNode!, node)!;
      stack.add(graph.addConstant(constant, closedWorld,
          sourceInformation: sourceInformation));
      return;
    }

    ConstructorEntity constructor = _elementMap.getConstructor(target);
    ClassEntity cls = constructor.enclosingClass;
    AbstractValue typeMask = _abstractValueDomain.createNonNullExact(cls);
    InterfaceType instanceType = _elementMap.createInterfaceType(
        target.enclosingClass, node.arguments.types);
    instanceType = localsHandler.substInContext(instanceType) as InterfaceType;

    if (_nativeData.isJsInteropMember(constructor)) {
      List<HInstruction?> arguments = [];

      List<DartType> typeArguments =
          _getConstructorTypeArguments(constructor, node.arguments);
      arguments.addAll(_visitArgumentsForNativeStaticTarget(
          target.function, node.arguments));
      // TODO(johnniwinther): Remove this when type arguments are passed to
      // constructors like calling a generic method.
      _addTypeArguments(arguments, _getClassTypeArguments(cls, node.arguments),
          sourceInformation);
      _addImplicitInstantiation(instanceType);
      _pushStaticNativeInvocation(
          constructor, arguments, typeMask, typeArguments);
      _removeImplicitInstantiation(instanceType);
    } else {
      List<HInstruction> arguments = [];

      if (constructor.isGenerativeConstructor &&
          _nativeData.isNativeOrExtendsNative(constructor.enclosingClass)) {
        // Native class generative constructors take a pre-constructed object.
        arguments.add(graph.addConstantNull(closedWorld));
      }
      List<DartType> typeArguments =
          _getConstructorTypeArguments(constructor, node.arguments);

      arguments.addAll(_visitArgumentsForStaticTarget(
          target,
          target.function,
          constructor.parameterStructure,
          node.arguments,
          typeArguments,
          sourceInformation));
      // TODO(johnniwinther): Remove this when type arguments are passed to
      // constructors like calling a generic method.
      _addTypeArguments(arguments, _getClassTypeArguments(cls, node.arguments),
          sourceInformation);
      _addImplicitInstantiation(instanceType);
      _pushStaticInvocation(constructor, arguments, typeMask, typeArguments,
          sourceInformation: sourceInformation, instanceType: instanceType);
      _removeImplicitInstantiation(instanceType);
    }
  }

  @override
  void visitIsExpression(ir.IsExpression node) {
    node.operand.accept(this);
    HInstruction expression = pop();
    _pushIsTest(node.type, expression, _sourceInformationBuilder.buildIs(node));
  }

  void _pushIsTest(ir.DartType type, HInstruction expression,
      SourceInformation? sourceInformation) {
    if (type is ir.InvalidType) {
      // TODO(sra): Make InvalidType carry a message.
      _generateTypeError('invalid type', sourceInformation);
      pop();
      stack.add(graph.addConstantBool(true, closedWorld));
      return;
    }

    DartType typeValue =
        localsHandler.substInContext(_elementMap.getDartType(type));

    HInstruction rti =
        _typeBuilder.analyzeTypeArgumentNewRti(typeValue, sourceElement);
    AbstractValueWithPrecision checkedType =
        _abstractValueDomain.createFromStaticType(typeValue, nullable: false);

    push(HIsTest(
        typeValue, checkedType, expression, rti, _abstractValueDomain.boolType)
      ..sourceInformation = sourceInformation);
  }

  @override
  void visitThrow(ir.Throw node) {
    _visitThrowExpression(node.expression);
    if (_isReachable) {
      final sourceInformation = _sourceInformationBuilder.buildThrow(node);
      _handleInTryStatement();
      push(HThrowExpression(_abstractValueDomain, pop(), sourceInformation));
      _isReachable = false;
    }
  }

  void _visitThrowExpression(ir.Expression expression) {
    bool old = _inExpressionOfThrow;
    try {
      _inExpressionOfThrow = true;
      expression.accept(this);
    } finally {
      _inExpressionOfThrow = old;
    }
  }

  @override
  void visitYieldStatement(ir.YieldStatement node) {
    node.expression.accept(this);
    add(HYield(_abstractValueDomain, pop(), node.isYieldStar,
        _sourceInformationBuilder.buildYield(node)));
  }

  @override
  void visitAwaitExpression(ir.AwaitExpression node) {
    node.operand.accept(this);
    HInstruction awaited = pop();
    // TODO(herhut): Improve this type.
    push(HAwait(awaited, _abstractValueDomain.dynamicType)
      ..sourceInformation = _sourceInformationBuilder.buildAwait(node));
  }

  @override
  void visitRethrow(ir.Rethrow node) {
    HInstruction? exception = _rethrowableException;
    if (exception == null) {
      exception = graph.addConstantNull(closedWorld);
      reporter.internalError(_elementMap.getSpannable(targetElement, node),
          'rethrowableException should not be null.');
    }
    _handleInTryStatement();
    final sourceInformation = _sourceInformationBuilder.buildThrow(node);
    _closeAndGotoExit(HThrow(_abstractValueDomain, exception, sourceInformation,
        isRethrow: true));
    // ir.Rethrow is an expression so we need to push a value - a constant with
    // no type.
    stack.add(graph.addConstantUnreachable(closedWorld));
  }

  @override
  void visitThisExpression(ir.ThisExpression node) {
    stack.add(localsHandler.readThis(
        sourceInformation: _sourceInformationBuilder.buildGet(node)));
  }

  @override
  void visitNot(ir.Not node) {
    node.operand.accept(this);
    push(HNot(popBoolified(), _abstractValueDomain.boolType)
      ..sourceInformation = _sourceInformationBuilder.buildUnary(node));
  }

  @override
  void visitStringConcatenation(ir.StringConcatenation stringConcat) {
    KernelStringBuilder stringBuilder = KernelStringBuilder(this);
    stringConcat.accept(stringBuilder);
    stack.add(stringBuilder.result!);
  }

  @override
  void visitTryCatch(ir.TryCatch node) {
    TryCatchFinallyBuilder tryBuilder =
        TryCatchFinallyBuilder(this, _sourceInformationBuilder.buildTry(node));
    node.body.accept(this);
    tryBuilder
      ..closeTryBody()
      ..buildCatch(node)
      ..cleanUp();
  }

  /// `try { ... } catch { ... } finally { ... }` statements are a little funny
  /// because a try can have one or both of {catch|finally}. The way this is
  /// encoded in kernel AST are two separate classes with no common superclass
  /// aside from Statement. If a statement has both `catch` and `finally`
  /// clauses then it is encoded in kernel as so that the TryCatch is the body
  /// statement of the TryFinally. To produce more efficient code rather than
  /// nested try statements, the visitors avoid one potential level of
  /// recursion.
  @override
  void visitTryFinally(ir.TryFinally node) {
    TryCatchFinallyBuilder tryBuilder =
        TryCatchFinallyBuilder(this, _sourceInformationBuilder.buildTry(node));

    // We do these shenanigans to produce better looking code that doesn't
    // have nested try statements.
    final nodeBody = node.body;
    if (nodeBody is ir.TryCatch) {
      nodeBody.body.accept(this);
      tryBuilder
        ..closeTryBody()
        ..buildCatch(nodeBody);
    } else {
      node.body.accept(this);
      tryBuilder.closeTryBody();
    }

    tryBuilder
      ..buildFinallyBlock(() {
        node.finalizer.accept(this);
      })
      ..cleanUp();
  }

  bool _tryInlineMethod(
      FunctionEntity function,
      Selector? selector,
      AbstractValue? mask,
      List<HInstruction> providedArguments,
      List<DartType>? typeArguments,
      ir.Node? currentNode,
      SourceInformation? sourceInformation,
      {InterfaceType? instanceType}) {
    final inlined = _doTryInlineMethod(function, selector, mask,
        providedArguments, typeArguments, currentNode, sourceInformation,
        instanceType: instanceType);
    if (inlined) {
      _metrics.countMethodInlined.add();
    } else {
      _metrics.countMethodNotInlined.add();
    }
    return inlined;
  }

  /// Try to inline [element] within the correct context of the builder. The
  /// insertion point is the state of the builder.
  bool _doTryInlineMethod(
      FunctionEntity function,
      Selector? selector,
      AbstractValue? mask,
      List<HInstruction> providedArguments,
      List<DartType>? typeArguments,
      ir.Node? currentNode,
      SourceInformation? sourceInformation,
      {InterfaceType? instanceType}) {
    if (function.isExternal) {
      // Don't inline external methods; these should just fail at runtime.
      return false;
    }

    if (_nativeData.isJsInteropMember(function) &&
        !(function is ConstructorEntity && function.isFactoryConstructor)) {
      // We only inline factory JavaScript interop constructors.
      return false;
    }

    // Check if inlining is disabled for the current element (includes globally)
    // before making decisions on the basis of the callee so that cached callee
    // decisions are not a function of the call site's method.
    if (closedWorld.annotationsData.hasDisableInlining(_currentFrame!.member)) {
      return false;
    }

    bool insideLoop = loopDepth > 0 || graph.calledInLoop;

    // Bail out early if the inlining decision is in the cache and we can't
    // inline (no need to check the hard constraints).
    if (_inlineCache.markedAsNoInline(function)) return false;
    final cachedCanBeInlined =
        _inlineCache.canInline(function, insideLoop: insideLoop);
    if (cachedCanBeInlined == false) return false;

    bool meetsHardConstraints() {
      assert(
          selector != null ||
              function.isStatic ||
              function.isTopLevel ||
              function is ConstructorEntity ||
              function is ConstructorBodyEntity,
          failedAt(function, "Missing selector for inlining of $function."));
      if (selector != null) {
        if (!selector.applies(function)) return false;
        if (mask != null &&
            _abstractValueDomain
                .isTargetingMember(mask, function, selector.memberName)
                .isDefinitelyFalse) {
          return false;
        }
      }

      if (_nativeData.isJsInteropMember(function)) return false;

      // Don't inline operator== methods if the parameter can be null.
      if (function.name == '==') {
        if (providedArguments[1]
            .isNull(_abstractValueDomain)
            .isPotentiallyTrue) {
          return false;
        }
      }

      // Generative constructors of native classes should not be called directly
      // and have an extra argument that causes problems with inlining.
      if (function is ConstructorEntity &&
          function.isGenerativeConstructor &&
          _nativeData.isNativeOrExtendsNative(function.enclosingClass)) {
        return false;
      }

      // A generative constructor body is not seen by global analysis,
      // so we should not query for its type.
      if (function is! ConstructorBodyEntity) {
        if (globalInferenceResults.resultOfMember(function).throwsAlways) {
          // TODO(johnniwinther): It seems wrong to set `isReachable` to `false`
          // since we are _not_ going to inline [function]. This has
          // implications in switch cases where we might need to insert a
          // `break` that was skipped due to `isReachable` being `false`.
          _isReachable = false;
          return false;
        }
      }

      // Record getters are synthetic and have no bodies so we cannot inline
      // them at this point.
      if (function is JRecordGetter) return false;

      return true;
    }

    bool doesNotContainCode(InlineData inlineData) {
      // A function with size 1 does not contain any code.
      return inlineData.canBeInlined(maxInliningNodes: 1);
    }

    bool reductiveHeuristic(InlineData inlineData) {
      // The call is on a path which is executed rarely, so inline only if it
      // does not make the program larger.
      if (_isCalledOnce(function)) {
        return inlineData.canBeInlined();
      }
      if (inlineData.canBeInlinedReductive(
          argumentCount: providedArguments.length)) {
        return true;
      }
      return doesNotContainCode(inlineData);
    }

    bool heuristicSayGoodToGo() {
      // Don't inline recursively,
      if (_inliningStack.any((entry) => entry.function == function)) {
        return false;
      }

      // Don't inline across deferred import to prevent leaking code. The only
      // exception is an empty function (which does not contain code).
      bool hasOnlyNonDeferredImportPaths = closedWorld.outputUnitData
          .hasOnlyNonDeferredImportPaths(_initialTargetElement, function);

      InlineData inlineData =
          _inlineDataCache.getInlineData(_elementMap, function);

      if (!hasOnlyNonDeferredImportPaths) {
        return doesNotContainCode(inlineData);
      }

      // Do not inline code that is rarely executed unless it reduces size.
      if (_inExpressionOfThrow || graph.isLazyInitializer) {
        return reductiveHeuristic(inlineData);
      }

      if (cachedCanBeInlined == true) {
        // We may have forced the inlining of some methods. Therefore check
        // if we can inline this method regardless of size.
        String? reason;
        assert(
            (reason = inlineData.cannotBeInlinedReason(allowLoops: true)) ==
                null,
            failedAt(function, "Cannot inline $function: $reason"));
        return true;
      }

      int numParameters = function.parameterStructure.totalParameters;
      int? maxInliningNodes;
      if (insideLoop) {
        maxInliningNodes = InlineWeeder.INLINING_NODES_INSIDE_LOOP +
            InlineWeeder.INLINING_NODES_INSIDE_LOOP_ARG_FACTOR * numParameters;
      } else {
        maxInliningNodes = InlineWeeder.INLINING_NODES_OUTSIDE_LOOP +
            InlineWeeder.INLINING_NODES_OUTSIDE_LOOP_ARG_FACTOR * numParameters;
      }

      bool markedTryInline = _inlineCache.markedAsTryInline(function);
      bool calledOnce = _isCalledOnce(function);
      // If a method is called only once, and all the methods in the inlining
      // stack are called only once as well, we know we will save on output size
      // by inlining this method.
      if (markedTryInline || calledOnce) {
        maxInliningNodes = null;
      }
      bool allowLoops = false;
      if (markedTryInline) {
        allowLoops = true;
      }

      bool canInline = inlineData.canBeInlined(
          maxInliningNodes: maxInliningNodes, allowLoops: allowLoops);
      if (markedTryInline) {
        if (canInline) {
          _inlineCache.markAsInlinable(function, insideLoop: true);
          _inlineCache.markAsInlinable(function, insideLoop: false);
        } else {
          _inlineCache.markAsNonInlinable(function, insideLoop: true);
          _inlineCache.markAsNonInlinable(function, insideLoop: false);
        }
      } else if (calledOnce) {
        // TODO(34203): We can't update the decision due to imprecision in the
        // calledOnce data, described in Issue 34203.
      } else {
        if (canInline) {
          _inlineCache.markAsInlinable(function, insideLoop: insideLoop);
        } else {
          if (_isFunctionCalledOnce(function)) {
            // TODO(34203): We can't update the decision due to imprecision in
            // the calledOnce data, described in Issue 34203.
          } else {
            _inlineCache.markAsNonInlinable(function, insideLoop: insideLoop);
          }
        }
      }
      return canInline;
    }

    void doInlining() {
      if (function is ConstructorEntity) {
        registry.registerStaticUse(
            StaticUse.constructorInlining(function, instanceType));
      } else {
        assert(instanceType == null,
            "Unexpected instance type for $function: $instanceType");
        registry.registerStaticUse(
            StaticUse.methodInlining(function, typeArguments));
      }

      // Add an explicit null check on the receiver before doing the inlining.
      if (function.isInstanceMember &&
          function is! ConstructorBodyEntity &&
          (mask == null ||
              _abstractValueDomain.isNull(mask).isPotentiallyTrue)) {
        HNullCheck guard =
            HNullCheck(providedArguments[0], _abstractValueDomain.dynamicType)
              ..selector = selector
              ..sourceInformation = sourceInformation;
        add(guard);
        providedArguments[0] = guard;
      }
      List<HInstruction> compiledArguments = _completeCallArgumentsList(
          function, selector, providedArguments, currentNode);
      _enterInlinedMethod(function, compiledArguments, instanceType);
      _inlinedFrom(function, sourceInformation, () {
        if (!_isReachable) {
          _emitReturn(
              graph.addConstantUnreachable(closedWorld), sourceInformation);
        } else {
          _doInline(function);
        }
      });
      _leaveInlinedMethod();
    }

    if (meetsHardConstraints() && heuristicSayGoodToGo()) {
      doInlining();
      _infoReporter?.reportInlined(
          function,
          _inliningStack.isEmpty
              ? targetElement
              : _inliningStack.last.function);
      return true;
    }

    return false;
  }

  /// Returns a complete argument list for a call of [function].
  List<HInstruction> _completeCallArgumentsList(
      FunctionEntity function,
      Selector? selector,
      List<HInstruction> providedArguments,
      ir.Node? currentNode) {
    bool isInstanceMember = function.isInstanceMember;
    // For static calls, [providedArguments] is complete, default arguments
    // have been included if necessary, see [makeStaticArgumentList].
    if (!isInstanceMember ||
        currentNode == null || // In erroneous code, currentNode can be null.
        _providedArgumentsKnownToBeComplete(currentNode) ||
        function is ConstructorBodyEntity ||
        selector!.isGetter) {
      // For these cases, the provided argument list is known to be complete.
      return providedArguments;
    } else {
      return _completeDynamicCallArgumentsList(
          selector, function, providedArguments);
    }
  }

  /// Returns a complete argument list for a dynamic call of [function]. The
  /// initial argument list [providedArguments], created by
  /// [addDynamicSendArgumentsToList], does not include values for default
  /// arguments used in the call. The reason is that the target function (which
  /// defines the defaults) is not known.
  ///
  /// However, inlining can only be performed when the target function can be
  /// resolved statically. The defaults can therefore be included at this point.
  ///
  /// The [providedArguments] list contains first all positional arguments, then
  /// the provided named arguments (the named arguments that are defined in the
  /// [selector]) in a specific order (see [addDynamicSendArgumentsToList]).
  List<HInstruction> _completeDynamicCallArgumentsList(Selector selector,
      FunctionEntity function, List<HInstruction> providedArguments) {
    assert(selector.applies(function));
    CallStructure callStructure = selector.callStructure;
    ParameterStructure parameterStructure = function.parameterStructure;
    List<String> selectorArgumentNames =
        selector.callStructure.getOrderedNamedArguments();
    bool methodNeedsTypeArguments = _rtiNeed.methodNeedsTypeArguments(function);
    List<HInstruction> compiledArguments = [];

    // Copy receiver.
    compiledArguments.add(providedArguments[0]);

    /// Offset of positional arguments in [providedArguments].
    int positionalArgumentOffset = 1;

    /// Offset of named arguments in [providedArguments].
    int namedArgumentOffset = callStructure.positionalArgumentCount + 1;

    int positionalArgumentIndex = 0;
    int namedArgumentIndex = 0;

    _elementEnvironment.forEachParameter(function,
        (DartType type, String? name, ConstantValue? defaultValue) {
      if (positionalArgumentIndex < parameterStructure.positionalParameters) {
        if (positionalArgumentIndex < callStructure.positionalArgumentCount) {
          compiledArguments.add(providedArguments[
              positionalArgumentOffset + positionalArgumentIndex++]);
        } else {
          assert(defaultValue != null,
              failedAt(function, 'No constant computed for parameter $name'));
          compiledArguments.add(graph.addConstant(defaultValue!, closedWorld));
        }
      } else {
        // Example:
        //     void foo(a, {b, d, c})
        //     foo(0, d = 1, b = 2)
        //
        // providedArguments = [0, 2, 1]
        // selectorArgumentNames = [b, d]
        // parameterStructure.namedParameters = [b, c, d]
        //
        // For each parameter name in the signature, if the argument name
        // matches we use the next provided argument, otherwise we get the
        // default.
        if (namedArgumentIndex < selectorArgumentNames.length &&
            name == selectorArgumentNames[namedArgumentIndex]) {
          // The named argument was provided in the function invocation.
          compiledArguments.add(
              providedArguments[namedArgumentOffset + namedArgumentIndex++]);
        } else {
          assert(defaultValue != null,
              failedAt(function, 'No constant computed for parameter $name'));
          compiledArguments.add(graph.addConstant(defaultValue!, closedWorld));
        }
      }
    });
    if (methodNeedsTypeArguments) {
      if (callStructure.typeArgumentCount ==
          parameterStructure.typeParameters) {
        /// Offset of type arguments in [providedArguments].
        int typeArgumentOffset = callStructure.argumentCount + 1;
        // Pass explicit type arguments.
        for (int typeArgumentIndex = 0;
            typeArgumentIndex < callStructure.typeArgumentCount;
            typeArgumentIndex++) {
          compiledArguments
              .add(providedArguments[typeArgumentOffset + typeArgumentIndex]);
        }
      } else {
        assert(callStructure.typeArgumentCount == 0);
        // Pass type variable bounds as type arguments.
        for (TypeVariableType typeVariable
            in _elementEnvironment.getFunctionTypeVariables(function)) {
          compiledArguments
              .add(_computeTypeArgumentDefaultValue(function, typeVariable));
        }
      }
    }
    return compiledArguments;
  }

  HInstruction _computeTypeArgumentDefaultValue(
      FunctionEntity function, TypeVariableType typeVariable) {
    DartType bound =
        _elementEnvironment.getTypeVariableDefaultType(typeVariable.element);
    return _typeBuilder.analyzeTypeArgument(bound, function);
  }

  /// This method is invoked before inlining the body of [function] into this
  /// [SsaGraphBuilder].
  void _enterInlinedMethod(FunctionEntity function,
      List<HInstruction> compiledArguments, InterfaceType? instanceType) {
    KernelInliningState state = KernelInliningState(
        function,
        _returnLocal,
        _returnType,
        stack,
        localsHandler,
        _inTryStatement,
        _isCalledOnce(function));
    _inliningStack.add(state);

    // Setting up the state of the (AST) builder is performed even when the
    // inlined function is in IR, because the irInliner uses the [returnElement]
    // of the AST builder.
    _setupStateForInlining(function, compiledArguments, instanceType);
  }

  /// This method sets up the local state of the builder for inlining
  /// [function]. The arguments of the function are inserted into the
  /// [localsHandler].
  ///
  /// When inlining a function, `return` statements are not emitted as
  /// [HReturn] instructions. Instead, the value of a synthetic element is
  /// updated in the [localsHandler]. This function creates such an element and
  /// stores it in the [_returnLocal] field.
  void _setupStateForInlining(FunctionEntity function,
      List<HInstruction> compiledArguments, InterfaceType? instanceType) {
    localsHandler = LocalsHandler(
        this,
        function,
        function,
        instanceType ?? _elementMap.getMemberThisType(function),
        _nativeData,
        _interceptorData);
    localsHandler.setupScope(function);

    CapturedScope scopeData = _closureDataLookup.getCapturedScope(function);
    bool forGenerativeConstructorBody = function is ConstructorBodyEntity;

    _returnLocal = SyntheticLocal("result", function, function);
    localsHandler.updateLocal(
        _returnLocal!, graph.addConstantNull(closedWorld));

    _inTryStatement = false; // TODO(lry): why? Document.

    int argumentIndex = 0;
    if (function.isInstanceMember) {
      localsHandler.updateLocal(
          localsHandler.thisLocal!, compiledArguments[argumentIndex++]);
    }

    final memberContextNode = _elementMap.getMemberContextNode(function)!;
    KernelToLocalsMap localsMap = _globalLocalsMap.getLocalsMap(function);
    forEachOrderedParameter(_elementMap, function,
        (ir.VariableDeclaration variable, {required bool isElided}) {
      Local local = localsMap.getLocalVariable(variable);
      if (isElided) {
        localsHandler.updateLocal(
            local, _defaultValueForParameter(memberContextNode, variable));
        return;
      }
      if (forGenerativeConstructorBody &&
          scopeData.isBoxedVariable(_localsMap, local)) {
        // The parameter will be a field in the box passed as the last
        // parameter. So no need to have it.
        return;
      }
      HInstruction argument = compiledArguments[argumentIndex++];
      localsHandler.updateLocal(local, argument);
    });

    bool hasTypeParameters = function.parameterStructure.typeParameters > 0;
    bool needsTypeArguments = _rtiNeed.methodNeedsTypeArguments(function);
    for (TypeVariableType typeVariable
        in _elementEnvironment.getFunctionTypeVariables(function)) {
      HInstruction argument;
      if (hasTypeParameters && needsTypeArguments) {
        argument = compiledArguments[argumentIndex++];
      } else {
        argument = _computeTypeArgumentDefaultValue(function, typeVariable);
      }
      localsHandler.updateLocal(
          localsHandler.getTypeVariableAsLocal(typeVariable), argument);
    }

    if (forGenerativeConstructorBody && scopeData.requiresContextBox) {
      HInstruction box = compiledArguments[argumentIndex++];
      assert(box is HCreateBox);
      // TODO(sra): Make inlining of closures work. We should always call
      // enterScope, and pass in the inlined 'this' as well as the 'box'.
      localsHandler.enterScope(scopeData, null,
          inlinedBox: box,
          forGenerativeConstructorBody: forGenerativeConstructorBody);
    }

    final enclosing = function.enclosingClass;
    if ((function is ConstructorEntity || function is ConstructorBodyEntity) &&
        _rtiNeed.classNeedsTypeArguments(enclosing!)) {
      InterfaceType thisType = _elementEnvironment.getThisType(enclosing);
      thisType.typeArguments.forEach((_typeVariable) {
        final typeVariable = _typeVariable as TypeVariableType;
        HInstruction argument = compiledArguments[argumentIndex++];
        localsHandler.updateLocal(
            localsHandler.getTypeVariableAsLocal(typeVariable), argument);
      });
    }

    assert(
        argumentIndex == compiledArguments.length ||
            !_rtiNeed.methodNeedsTypeArguments(function) &&
                compiledArguments.length - argumentIndex ==
                    function.parameterStructure.typeParameters,
        failedAt(
            function,
            "Only ${argumentIndex} of ${compiledArguments.length} "
            "arguments have been read from: ${compiledArguments} passed to "
            "$function."));

    _returnType = _elementEnvironment.getFunctionType(function).returnType;
    stack = <HInstruction>[];

    _insertCoverageCall(function);
  }

  void _leaveInlinedMethod() {
    HInstruction result = localsHandler.readLocal(_returnLocal!);
    KernelInliningState state = _inliningStack.removeLast();
    _restoreState(state);
    stack.add(result);
  }

  void _restoreState(KernelInliningState state) {
    localsHandler = state.oldLocalsHandler;
    _returnLocal = state.oldReturnLocal;
    _inTryStatement = state.inTryStatement;
    _returnType = state.oldReturnType;
    assert(stack.isEmpty);
    stack = state.oldStack;
  }

  bool _providedArgumentsKnownToBeComplete(ir.Node currentNode) {
    /* When inlining the iterator methods generated for a for-in loop, the
     * [currentNode] is the [ForIn] tree. The compiler-generated iterator
     * invocations are known to have fully specified argument lists, no default
     * arguments are used. See invocations of [pushInvokeDynamic] in
     * [visitForIn].
     */
    // TODO(redemption): Is this valid here?
    return currentNode is ir.ForInStatement;
  }

  void _emitReturn(HInstruction? value, SourceInformation? sourceInformation) {
    if (_inliningStack.isEmpty) {
      _closeAndGotoExit(
          HReturn(_abstractValueDomain, value, sourceInformation));
    } else {
      value ??= graph.addConstantNull(closedWorld);
      localsHandler.updateLocal(_returnLocal!, value);
    }
  }

  void _doInline(FunctionEntity function) {
    _visitInlinedFunction(function);
  }

  /// Run this builder on the body of the [function] to be inlined.
  void _visitInlinedFunction(FunctionEntity function) {
    _potentiallyCheckInlinedParameterTypes(function);

    MemberDefinition definition = _elementMap.getMemberDefinition(function);
    switch (definition.kind) {
      case MemberKind.constructor:
        _buildConstructor(
            function as ConstructorEntity, definition.node as ir.Constructor);
        return;
      case MemberKind.constructorBody:
        final constructor = definition.node as ir.Constructor;
        constructor.function.body!.accept(this);
        return;
      case MemberKind.regular:
        ir.Node node = definition.node;
        if (node is ir.Constructor) {
          node.function.body!.accept(this);
          return;
        } else if (node is ir.Procedure) {
          node.function.body!.accept(this);
          return;
        }
        break;
      case MemberKind.closureCall:
        final node = definition.node as ir.LocalFunction;
        node.function.body!.accept(this);
        return;
      default:
        break;
    }
    failedAt(function, "Unexpected inlined function: $definition");
  }

  /// Generates type tests for the parameters of the inlined function.
  void _potentiallyCheckInlinedParameterTypes(FunctionEntity function) {
    // TODO(sra): Incorporate properties of call site to help determine which
    // type parameters and value parameters need to be checked.
    bool trusted = false;
    if (function.isStatic ||
        function.isTopLevel ||
        function is ConstructorEntity ||
        function is ConstructorBodyEntity) {
      // We inline static methods, top-level methods, constructors and
      // constructor bodies only from direct call sites.
      trusted = true;
    }

    if (!trusted) {
      _checkTypeVariableBounds(function);
    }

    KernelToLocalsMap localsMap = _globalLocalsMap.getLocalsMap(function);
    forEachOrderedParameter(_elementMap, function,
        (ir.VariableDeclaration variable, {required bool isElided}) {
      Local parameter = localsMap.getLocalVariable(variable);
      HInstruction argument = localsHandler.readLocal(parameter);
      DartType type = localsMap.getLocalType(_elementMap, parameter);
      HInstruction checkedOrTrusted;
      if (trusted) {
        checkedOrTrusted =
            _typeBuilder.trustTypeOfParameter(function, argument, type);
      } else {
        checkedOrTrusted = _typeBuilder.potentiallyCheckOrTrustTypeOfParameter(
            function, argument, type);
      }
      checkedOrTrusted =
          _potentiallyAssertNotNull(function, variable, checkedOrTrusted, type);
      localsHandler.updateLocal(parameter, checkedOrTrusted);
    });
  }

  bool get _allInlinedFunctionsCalledOnce {
    return _inliningStack.isEmpty || _inliningStack.last.allFunctionsCalledOnce;
  }

  bool _isFunctionCalledOnce(FunctionEntity element) {
    // ConstructorBodyElements are not in the type inference graph.
    if (element is ConstructorBodyEntity) {
      // If there are no subclasses with constructors that have this constructor
      // as a superconstructor, it is called once by the generative
      // constructor's factory.  A simplified version is to check this is a
      // constructor body for a leaf class.
      ClassEntity class_ = element.enclosingClass!;
      if (closedWorld.classHierarchy.isDirectlyInstantiated(class_)) {
        return !closedWorld.classHierarchy.isIndirectlyInstantiated(class_);
      }
      return false;
    }
    return globalInferenceResults.resultOfMember(element).isCalledOnce;
  }

  bool _isCalledOnce(FunctionEntity element) {
    return _allInlinedFunctionsCalledOnce && _isFunctionCalledOnce(element);
  }

  void _insertCoverageCall(MemberEntity element) {
    if (!options.experimentCallInstrumentation) return;
    if (element == _commonElements.traceHelper) return;
    // TODO(sigmund): create a better uuid for elements.
    HConstant idConstant = graph.addConstantInt(element.hashCode, closedWorld);
    String? n(Entity? e) => e == null ? '' : e.name;
    String name = "${n(element.library)}:${n(element.enclosingClass)}."
        "${n(element)}";
    HConstant nameConstant = graph.addConstantString(name, closedWorld);
    add(HInvokeStatic(_commonElements.traceHelper, [idConstant, nameConstant],
        _abstractValueDomain.dynamicType, const <DartType>[]));
  }
}

/// Data collected to create a constructor.
class ConstructorData {
  /// Inlined (super) constructors.
  final List<ir.Constructor> constructorChain = [];

  /// Initial values for all instance fields.
  final Map<FieldEntity, HInstruction> fieldValues = {};

  /// Classes for which type variables have been prepared.
  final Set<ClassEntity> includedClasses = {};
}

class KernelInliningState {
  final FunctionEntity function;
  final Local? oldReturnLocal;
  final DartType? oldReturnType;
  final List<HInstruction> oldStack;
  final LocalsHandler oldLocalsHandler;
  final bool inTryStatement;
  final bool allFunctionsCalledOnce;

  KernelInliningState(
      this.function,
      this.oldReturnLocal,
      this.oldReturnType,
      this.oldStack,
      this.oldLocalsHandler,
      this.inTryStatement,
      this.allFunctionsCalledOnce);

  @override
  String toString() => 'KernelInliningState($function,'
      'allFunctionsCalledOnce=$allFunctionsCalledOnce)';
}

/// Class in charge of building try, catch and/or finally blocks. This handles
/// the instructions that need to be output and the dominator calculation of
/// this sequence of code.
class TryCatchFinallyBuilder {
  final KernelSsaGraphBuilder kernelBuilder;
  final SourceInformation? trySourceInformation;

  late final HBasicBlock enterBlock;
  late final HBasicBlock startTryBlock;
  HBasicBlock? endTryBlock;
  HBasicBlock? startCatchBlock;
  HBasicBlock? endCatchBlock;
  HBasicBlock? startFinallyBlock;
  HBasicBlock? endFinallyBlock;
  HBasicBlock? exitBlock;
  late final HTry tryInstruction;
  HLocalValue? exception;

  /// True if the code surrounding this try statement was also part of a
  /// try/catch/finally statement.
  late final bool previouslyInTryStatement;

  SubGraph? bodyGraph;
  SubGraph? catchGraph;
  SubGraph? finallyGraph;

  // The original set of locals that were defined before this try block.
  // The catch block and the finally block must not reuse the existing locals
  // handler. None of the variables that have been defined in the body-block
  // will be used, but for loops we will add (unnecessary) phis that will
  // reference the body variables. This makes it look as if the variables were
  // used in a non-dominated block.
  LocalsHandler? originalSavedLocals;

  TryCatchFinallyBuilder(this.kernelBuilder, this.trySourceInformation) {
    tryInstruction = HTry(kernelBuilder._abstractValueDomain);
    originalSavedLocals = LocalsHandler.from(kernelBuilder.localsHandler);
    enterBlock = kernelBuilder.openNewBlock();
    kernelBuilder.close(tryInstruction);
    previouslyInTryStatement = kernelBuilder._inTryStatement;
    kernelBuilder._inTryStatement = true;

    startTryBlock = kernelBuilder.graph.addNewBlock();
    kernelBuilder.open(startTryBlock);
  }

  void _addExitTrySuccessor(HBasicBlock? successor) {
    if (successor == null) return;
    // Iterate over all blocks created inside this try/catch, and
    // attach successor information to blocks that end with
    // [HExitTry].
    for (int i = startTryBlock.id; i < successor.id; i++) {
      HBasicBlock block = kernelBuilder.graph.blocks[i];
      var last = block.last;
      if (last is HExitTry) {
        block.addSuccessor(successor);
      }
    }
  }

  void _addOptionalSuccessor(HBasicBlock block1, HBasicBlock? block2) {
    if (block2 != null) block1.addSuccessor(block2);
  }

  /// Helper function to set up basic block successors for try-catch-finally
  /// sequences.
  void _setBlockSuccessors() {
    // Setup all successors. The entry block that contains the [HTry]
    // has 1) the body, 2) the catch, 3) the finally, and 4) the exit
    // blocks as successors.
    final exit = exitBlock!;
    enterBlock.addSuccessor(startTryBlock);
    _addOptionalSuccessor(enterBlock, startCatchBlock);
    _addOptionalSuccessor(enterBlock, startFinallyBlock);
    enterBlock.addSuccessor(exit);

    // The body has either the catch or the finally block as successor.
    final endTry = endTryBlock;
    if (endTry != null) {
      assert(startCatchBlock != null || startFinallyBlock != null);
      endTry.addSuccessor(startCatchBlock ?? startFinallyBlock!);
      endTry.addSuccessor(exit);
    }

    // The catch block has either the finally or the exit block as
    // successor.
    endCatchBlock?.addSuccessor(startFinallyBlock ?? exit);

    // The finally block has the exit block as successor.
    endFinallyBlock?.addSuccessor(exit);

    // If a block inside try/catch aborts (eg with a return statement),
    // we explicitly mark this block a predecessor of the catch
    // block and the finally block.
    _addExitTrySuccessor(startCatchBlock);
    _addExitTrySuccessor(startFinallyBlock);
  }

  /// Build the finally{} clause of a try/{catch}/finally statement. Note this
  /// does not examine the body of the try clause, only the finally portion.
  void buildFinallyBlock(void buildFinalizer()) {
    kernelBuilder.localsHandler = LocalsHandler.from(originalSavedLocals!);
    startFinallyBlock = kernelBuilder.graph.addNewBlock();
    kernelBuilder.open(startFinallyBlock!);
    buildFinalizer();
    if (!kernelBuilder.isAborted()) {
      endFinallyBlock =
          kernelBuilder.close(HGoto(kernelBuilder._abstractValueDomain));
    }
    tryInstruction.finallyBlock = startFinallyBlock;
    finallyGraph = SubGraph(startFinallyBlock!, kernelBuilder.lastOpenedBlock);
  }

  void closeTryBody() {
    // We use a [HExitTry] instead of a [HGoto] for the try block
    // because it will have multiple successors: the join block, and
    // the catch or finally block.
    if (!kernelBuilder.isAborted()) {
      endTryBlock =
          kernelBuilder.close(HExitTry(kernelBuilder._abstractValueDomain));
    }
    bodyGraph = SubGraph(startTryBlock, kernelBuilder.lastOpenedBlock);
  }

  void buildCatch(ir.TryCatch tryCatch) {
    kernelBuilder.localsHandler = LocalsHandler.from(originalSavedLocals!);
    startCatchBlock = kernelBuilder.graph.addNewBlock();
    kernelBuilder.open(startCatchBlock!);
    // Note that the name of this local is irrelevant.
    SyntheticLocal local = kernelBuilder.localsHandler.createLocal('exception');
    exception =
        HLocalValue(local, kernelBuilder._abstractValueDomain.nonNullType)
          ..sourceInformation = trySourceInformation;
    kernelBuilder.add(exception!);
    final oldRethrowableException = kernelBuilder._rethrowableException;
    kernelBuilder._rethrowableException = exception;

    AbstractValue unwrappedType = kernelBuilder._typeInferenceMap
        .getReturnTypeOf(kernelBuilder._commonElements.exceptionUnwrapper);
    // Global type analysis does not currently understand that strong mode
    // `Object` is not nullable, so is imprecise in the return type of the
    // unwrapper, which leads to unnecessary checks for 'on Object'.
    unwrappedType =
        kernelBuilder._abstractValueDomain.excludeNull(unwrappedType);
    kernelBuilder._pushStaticInvocation(
        kernelBuilder._commonElements.exceptionUnwrapper,
        [exception!],
        unwrappedType,
        const <DartType>[],
        sourceInformation: trySourceInformation);
    final unwrappedException = kernelBuilder.pop() as HInvokeStatic;
    unwrappedException.sideEffects
      ..clearAllDependencies()
      ..clearAllSideEffects();
    unwrappedException.targetCanThrow = false;
    tryInstruction.exception = exception;
    int catchesIndex = 0;

    void pushCondition(ir.Catch catchBlock) {
      kernelBuilder._pushIsTest(catchBlock.guard, unwrappedException,
          kernelBuilder._sourceInformationBuilder.buildCatch(catchBlock));
    }

    void visitThen() {
      ir.Catch catchBlock = tryCatch.catches[catchesIndex];
      catchesIndex++;
      if (catchBlock.exception != null) {
        Local exceptionVariable =
            kernelBuilder._localsMap.getLocalVariable(catchBlock.exception!);
        kernelBuilder.localsHandler.updateLocal(
            exceptionVariable, unwrappedException,
            sourceInformation:
                kernelBuilder._sourceInformationBuilder.buildCatch(catchBlock));
      }
      if (catchBlock.stackTrace != null) {
        kernelBuilder._pushStaticInvocation(
            kernelBuilder._commonElements.traceFromException,
            [exception!],
            kernelBuilder._typeInferenceMap.getReturnTypeOf(
                kernelBuilder._commonElements.traceFromException),
            const <DartType>[],
            sourceInformation:
                kernelBuilder._sourceInformationBuilder.buildCatch(catchBlock));
        HInstruction traceInstruction = kernelBuilder.pop();
        Local traceVariable =
            kernelBuilder._localsMap.getLocalVariable(catchBlock.stackTrace!);
        kernelBuilder.localsHandler.updateLocal(traceVariable, traceInstruction,
            sourceInformation:
                kernelBuilder._sourceInformationBuilder.buildCatch(catchBlock));
      }
      catchBlock.body.accept(kernelBuilder);
    }

    void visitElse() {
      if (catchesIndex >= tryCatch.catches.length) {
        kernelBuilder._closeAndGotoExit(HThrow(
            kernelBuilder._abstractValueDomain,
            exception!,
            exception!.sourceInformation,
            isRethrow: true));
      } else {
        ir.Catch nextCatch = tryCatch.catches[catchesIndex];
        kernelBuilder._handleIf(
            visitCondition: () {
              pushCondition(nextCatch);
            },
            visitThen: visitThen,
            visitElse: visitElse,
            sourceInformation:
                kernelBuilder._sourceInformationBuilder.buildCatch(nextCatch));
      }
    }

    ir.Catch firstBlock = tryCatch.catches[catchesIndex];
    kernelBuilder._handleIf(
        visitCondition: () {
          pushCondition(firstBlock);
        },
        visitThen: visitThen,
        visitElse: visitElse,
        sourceInformation:
            kernelBuilder._sourceInformationBuilder.buildCatch(firstBlock));
    if (!kernelBuilder.isAborted()) {
      endCatchBlock =
          kernelBuilder.close(HGoto(kernelBuilder._abstractValueDomain));
    }

    kernelBuilder._rethrowableException = oldRethrowableException;
    tryInstruction.catchBlock = startCatchBlock;
    catchGraph = SubGraph(startCatchBlock!, kernelBuilder.lastOpenedBlock);
  }

  void cleanUp() {
    exitBlock = kernelBuilder.graph.addNewBlock();
    _setBlockSuccessors();

    // Use the locals handler not altered by the catch and finally
    // blocks.
    kernelBuilder.localsHandler = originalSavedLocals!;
    kernelBuilder.open(exitBlock!);
    enterBlock.setBlockFlow(
        HTryBlockInformation(
            kernelBuilder.wrapStatementGraph(bodyGraph),
            exception,
            kernelBuilder.wrapStatementGraph(catchGraph),
            kernelBuilder.wrapStatementGraph(finallyGraph)),
        exitBlock);
    kernelBuilder._inTryStatement = previouslyInTryStatement;
  }
}

class KernelTypeBuilder extends TypeBuilder {
  final JsToElementMap _elementMap;

  KernelTypeBuilder(super.builder, this._elementMap);

  @override
  ClassTypeVariableAccess computeTypeVariableAccess(MemberEntity member) {
    return _elementMap.getClassTypeVariableAccessForMember(member);
  }
}

class _ErroneousInitializerVisitor extends ir.Visitor<bool>
    with ir.VisitorDefaultValueMixin<bool> {
  _ErroneousInitializerVisitor();

  // TODO(30809): Use const constructor.
  static bool check(ir.Initializer initializer) =>
      initializer.accept(_ErroneousInitializerVisitor());

  @override
  bool defaultInitializer(ir.Node node) => false;

  @override
  bool visitInvalidInitializer(ir.InvalidInitializer node) => true;

  @override
  bool visitLocalInitializer(ir.LocalInitializer node) {
    return node.variable.initializer?.accept(this) ?? false;
  }

  // Expressions: Does the expression always throw?
  @override
  bool get defaultValue => false;

  @override
  bool visitThrow(ir.Throw node) => true;

  // TODO(sra): We might need to match other expressions that always throw but
  // in a subexpression.
}

/// Special [JumpHandler] implementation used to handle continue statements
/// targeting switch cases.
class KernelSwitchCaseJumpHandler extends SwitchCaseJumpHandler {
  KernelSwitchCaseJumpHandler(KernelSsaGraphBuilder builder, JumpTarget target,
      ir.SwitchStatement switchStatement, KernelToLocalsMap localsMap)
      : super(builder, target) {
    // The switch case indices must match those computed in
    // [KernelSsaBuilder.buildSwitchCaseConstants].
    // Switch indices are 1-based so we can bypass the synthetic loop when no
    // cases match simply by branching on the index (which defaults to null).
    // TODO
    int switchIndex = 1;
    for (ir.SwitchCase switchCase in switchStatement.cases) {
      final continueTarget = localsMap.getJumpTargetForSwitchCase(switchCase);
      if (continueTarget != null) {
        targetIndexMap[continueTarget] = switchIndex;
        assert(builder.jumpTargets[continueTarget] == null);
        builder.jumpTargets[continueTarget] = this;
      }
      switchIndex++;
    }
  }
}

class StaticType {
  final DartType type;
  final ClassRelation relation;

  StaticType(this.type, this.relation);

  @override
  int get hashCode => type.hashCode * 13 + relation.hashCode * 19;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    return other is StaticType &&
        type == other.type &&
        relation == other.relation;
  }

  @override
  String toString() => 'StaticType($type,$relation)';
}

class InlineData {
  bool isConstructor = false;
  bool codeAfterReturn = false;
  bool hasLoop = false;
  bool hasClosure = false;
  bool hasTry = false;
  bool hasAsyncAwait = false;
  bool hasThrow = false;
  bool hasLongString = false;
  bool hasExternalConstantConstructorCall = false;
  bool hasTypeArguments = false;
  bool hasArgumentDefaulting = false;
  bool hasCast = false;
  bool hasIf = false;
  bool hasLabel = false; // TODO(51652): Remove when inlining works with labels.
  List<int> argumentCounts = [];
  int regularNodeCount = 0;
  int callCount = 0;
  int reductiveNodeCount = 0;

  InlineData();

  bool canBeInlined({int? maxInliningNodes, bool allowLoops = false}) {
    return cannotBeInlinedReason(
            maxInliningNodes: maxInliningNodes, allowLoops: allowLoops) ==
        null;
  }

  String? cannotBeInlinedReason(
      {int? maxInliningNodes, bool allowLoops = false}) {
    if (hasLoop && !allowLoops) {
      return 'loop';
    } else if (hasTry) {
      return 'try';
    } else if (hasClosure) {
      return 'closure';
    } else if (codeAfterReturn) {
      return 'code after return';
    } else if (hasAsyncAwait) {
      return 'async/await';
    } else if (maxInliningNodes != null &&
        regularNodeCount - 1 > maxInliningNodes) {
      return 'too many nodes (${regularNodeCount - 1}>$maxInliningNodes)';
    }
    if (hasLabel) return 'has label';
    return null;
  }

  bool canBeInlinedReductive({required int argumentCount}) {
    return cannotBeInlinedReductiveReason(argumentCount: argumentCount) == null;
  }

  String? cannotBeInlinedReductiveReason({required int argumentCount}) {
    if (hasTry) {
      return 'try';
    } else if (hasClosure) {
      return 'closure';
    } else if (codeAfterReturn) {
      return 'code after return';
    } else if (hasAsyncAwait) {
      return 'async/await';
    } else if (callCount > 1) {
      return 'too many calls';
    } else if (hasThrow) {
      return 'throw';
    } else if (hasLongString) {
      return 'long string';
    } else if (hasExternalConstantConstructorCall) {
      return 'external const constructor';
    } else if (hasTypeArguments) {
      return 'type arguments';
    } else if (hasArgumentDefaulting) {
      return 'argument defaulting';
    } else if (hasCast) {
      return 'cast';
    } else if (hasIf) {
      return 'if';
    } else if (isConstructor) {
      return 'constructor';
    }
    if (hasLabel) return 'has label';
    for (int count in argumentCounts) {
      if (count > argumentCount) {
        return 'increasing arguments';
      }
    }
    // Node budget that covers one call and the passed-in arguments.
    // The +1 also allows a top-level zero-argument to be inlined if it
    // returns a constant.
    int maxInliningNodes = argumentCount + 1;
    if (reductiveNodeCount > maxInliningNodes) {
      return 'too many nodes (${reductiveNodeCount}>$maxInliningNodes)';
    }

    return null;
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write('InlineData(');
    String comma = '';
    if (isConstructor) {
      sb.write('isConstructor');
      comma = ',';
    }
    if (codeAfterReturn) {
      sb.write(comma);
      sb.write('codeAfterReturn');
      comma = ',';
    }
    if (hasLoop) {
      sb.write(comma);
      sb.write('hasLoop');
      comma = ',';
    }
    if (hasClosure) {
      sb.write(comma);
      sb.write('hasClosure');
      comma = ',';
    }
    if (hasTry) {
      sb.write(comma);
      sb.write('hasTry');
      comma = ',';
    }
    if (hasAsyncAwait) {
      sb.write(comma);
      sb.write('hasAsyncAwait');
      comma = ',';
    }
    if (hasThrow) {
      sb.write(comma);
      sb.write('hasThrow');
      comma = ',';
    }
    if (hasLongString) {
      sb.write(comma);
      sb.write('hasLongString');
      comma = ',';
    }
    if (hasExternalConstantConstructorCall) {
      sb.write(comma);
      sb.write('hasExternalConstantConstructorCall');
      comma = ',';
    }
    if (hasTypeArguments) {
      sb.write(comma);
      sb.write('hasTypeArguments');
      comma = ',';
    }
    if (hasArgumentDefaulting) {
      sb.write(comma);
      sb.write('hasArgumentDefaulting');
      comma = ',';
    }
    if (hasCast) {
      sb.write(comma);
      sb.write('hasCast');
      comma = ',';
    }
    if (hasIf) {
      sb.write(comma);
      sb.write('hasIf');
      comma = ',';
    }
    if (hasLabel) {
      sb.write(comma);
      sb.write('hasLabel');
      comma = ',';
    }
    if (argumentCounts.isNotEmpty) {
      sb.write(comma);
      sb.write('argumentCounts={${argumentCounts.join(',')}}');
      comma = ',';
    }
    sb.write(comma);
    sb.write('regularNodeCount=$regularNodeCount,');
    sb.write('callCount=$callCount,');
    sb.write('reductiveNodeCount=$reductiveNodeCount');
    sb.write(')');
    return sb.toString();
  }
}

class InlineDataCache {
  final bool enableUserAssertions;
  final bool omitImplicitCasts;

  InlineDataCache(
      {this.enableUserAssertions = false, this.omitImplicitCasts = false});

  final Map<FunctionEntity, InlineData> _cache = {};

  InlineData getInlineData(JsToElementMap elementMap, FunctionEntity function) {
    return _cache[function] ??= InlineWeeder.computeInlineData(
        elementMap, function,
        enableUserAssertions: enableUserAssertions,
        omitImplicitCasts: omitImplicitCasts);
  }
}

class InlineWeeder extends ir.Visitor<void> with ir.VisitorVoidMixin {
  // Invariant: *INSIDE_LOOP* > *OUTSIDE_LOOP*
  static const INLINING_NODES_OUTSIDE_LOOP = 15;
  static const INLINING_NODES_OUTSIDE_LOOP_ARG_FACTOR = 3;
  static const INLINING_NODES_INSIDE_LOOP = 34;
  static const INLINING_NODES_INSIDE_LOOP_ARG_FACTOR = 4;

  final bool enableUserAssertions;
  final bool omitImplicitCasts;

  final InlineData data = InlineData();
  bool seenReturn = false;

  /// Whether node-count is collector to determine if a function can be
  /// inlined.
  bool countRegularNode = true;

  /// Whether node-count is collected to determine if inlining a function is
  /// very likely to reduce code size.
  ///
  /// For the reductive analysis:
  /// We allow the body to be a single function call that does not have any more
  /// inputs than the inlinee.
  ///
  /// We allow the body to be the return of an 'eligible' constant. A constant
  /// is 'eligible' if it is not large (e.g. a long string).
  ///
  /// We skip 'e as{TypeError} T' when the checks are omitted.
  //
  // TODO(sra): Consider slightly expansive simple constructors where all we
  // gain is a 'new' keyword, e.g. `new X.Foo(a)` vs `X.Foo$(a)`.
  //
  // TODO(25231): Make larger string constants eligible by sharing references.
  bool countReductiveNode = true;

  // When handling a generative constructor factory, the super constructor calls
  // are 'inlined', so tend to reuse the same parameters. [discountParameters]
  // is true to avoid double-counting these parameters.
  bool discountParameters = false;

  InlineWeeder(
      {this.enableUserAssertions = false, this.omitImplicitCasts = false});

  static InlineData computeInlineData(
      JsToElementMap elementMap, FunctionEntity function,
      {bool enableUserAssertions = false, bool omitImplicitCasts = false}) {
    InlineWeeder visitor = InlineWeeder(
        enableUserAssertions: enableUserAssertions,
        omitImplicitCasts: omitImplicitCasts);
    final node = getFunctionNode(elementMap, function)!;
    if (function is ConstructorEntity) {
      visitor.data.isConstructor = true;
      MemberDefinition definition = elementMap.getMemberDefinition(function);
      ir.Node node = definition.node;
      if (node is ir.Constructor) {
        visitor.skipReductiveNodes(() {
          visitor.handleGenerativeConstructorFactory(node);
        });
        return visitor.data;
      }
    }
    node.accept(visitor);
    return visitor.data;
  }

  void skipRegularNodes(void f()) {
    bool oldCountRegularNode = countRegularNode;
    countRegularNode = false;
    f();
    countRegularNode = oldCountRegularNode;
  }

  void skipReductiveNodes(void f()) {
    bool oldCountReductiveNode = countReductiveNode;
    countReductiveNode = false;
    f();
    countReductiveNode = oldCountReductiveNode;
  }

  void registerRegularNode([int count = 1]) {
    if (countRegularNode) {
      data.regularNodeCount += count;
      if (seenReturn) {
        data.codeAfterReturn = true;
      }
    }
  }

  void registerReductiveNode() {
    if (countReductiveNode) {
      data.reductiveNodeCount++;
      if (seenReturn) {
        data.codeAfterReturn = true;
      }
    }
  }

  void unregisterReductiveNode() {
    if (countReductiveNode) {
      data.reductiveNodeCount--;
    }
  }

  void visit(ir.Node? node) => node?.accept(this);

  void visitList(List<ir.Node> nodes) {
    for (ir.Node node in nodes) {
      visit(node);
    }
  }

  @override
  defaultNode(ir.Node node) {
    registerRegularNode();
    registerReductiveNode();
    node.visitChildren(this);
  }

  @override
  visitConstantExpression(ir.ConstantExpression node) {
    registerRegularNode();
    registerReductiveNode();
    ir.Constant constant = node.constant;
    // Avoid copying long strings into call site.
    if (constant is ir.StringConstant && isLongString(constant.value)) {
      data.hasLongString = true;
    }
  }

  @override
  visitReturnStatement(ir.ReturnStatement node) {
    registerRegularNode();
    node.visitChildren(this);
    seenReturn = true;
  }

  @override
  visitThrow(ir.Throw node) {
    registerRegularNode();
    data.hasThrow = true;
    node.visitChildren(this);
  }

  _handleLoop(ir.Node node) {
    // It's actually not difficult to inline a method with a loop, but our
    // measurements show that it's currently better to not inline a method that
    // contains a loop.
    data.hasLoop = true;
    node.visitChildren(this);
  }

  @override
  visitForStatement(ir.ForStatement node) {
    _handleLoop(node);
  }

  @override
  visitForInStatement(ir.ForInStatement node) {
    _handleLoop(node);
  }

  @override
  visitWhileStatement(ir.WhileStatement node) {
    _handleLoop(node);
  }

  @override
  visitDoStatement(ir.DoStatement node) {
    _handleLoop(node);
  }

  @override
  visitTryCatch(ir.TryCatch node) {
    data.hasTry = true;
  }

  @override
  visitTryFinally(ir.TryFinally node) {
    data.hasTry = true;
  }

  @override
  visitFunctionExpression(ir.FunctionExpression node) {
    registerRegularNode();
    data.hasClosure = true;
  }

  @override
  visitFunctionDeclaration(ir.FunctionDeclaration node) {
    registerRegularNode();
    data.hasClosure = true;
  }

  @override
  visitFunctionNode(ir.FunctionNode node) {
    if (node.asyncMarker != ir.AsyncMarker.Sync) {
      data.hasAsyncAwait = true;
    }
    // TODO(sra): Cost of parameter checking?
    skipReductiveNodes(() {
      visitList(node.typeParameters);
      visitList(node.positionalParameters);
      visitList(node.namedParameters);
      visit(node.returnType);
    });
    visit(node.body);
  }

  @override
  visitConditionalExpression(ir.ConditionalExpression node) {
    // Heuristic: In "parameter ? A : B" there is a high probability that
    // parameter is a constant. Assuming the parameter is constant, we can
    // compute a count that is bounded by the largest arm rather than the sum of
    // both arms.
    ir.Expression condition = node.condition;
    visit(condition);
    int commonPrefixCount = data.regularNodeCount;

    visit(node.then);
    int thenCount = data.regularNodeCount - commonPrefixCount;

    data.regularNodeCount = commonPrefixCount;
    visit(node.otherwise);
    int elseCount = data.regularNodeCount - commonPrefixCount;

    data.regularNodeCount = commonPrefixCount + thenCount + elseCount;
    if (condition is ir.VariableGet &&
        condition.variable.parent is ir.FunctionNode) {
      data.regularNodeCount =
          commonPrefixCount + (thenCount > elseCount ? thenCount : elseCount);
    }
    // This is last so that [tooDifficult] is always updated.
    registerRegularNode();
    registerReductiveNode();
    skipRegularNodes(() => visit(node.staticType));
  }

  @override
  visitAssertInitializer(ir.AssertInitializer node) {
    if (!enableUserAssertions) return;
    node.visitChildren(this);
  }

  @override
  visitAssertStatement(ir.AssertStatement node) {
    if (!enableUserAssertions) return;
    defaultNode(node);
  }

  void registerCall() {
    ++data.callCount;
  }

  @override
  visitEmptyStatement(ir.EmptyStatement node) {
    registerRegularNode();
  }

  @override
  visitExpressionStatement(ir.ExpressionStatement node) {
    registerRegularNode();
    node.visitChildren(this);
  }

  @override
  visitLabeledStatement(ir.LabeledStatement node) {
    registerRegularNode();
    data.hasLabel = true;
    node.visitChildren(this);
  }

  @override
  visitSwitchStatement(ir.SwitchStatement node) {
    registerRegularNode();
    registerReductiveNode();
    // Don't visit 'SwitchStatement.expressionType'.
    node.expression.accept(this);
    visitList(node.cases);
  }

  @override
  visitBlock(ir.Block node) {
    registerRegularNode();
    node.visitChildren(this);
  }

  /// Returns `true` if [value] is considered a long string for which copying
  /// should be avoided.
  bool isLongString(String value) => value.length > 14;

  @override
  visitStringLiteral(ir.StringLiteral node) {
    registerRegularNode();
    registerReductiveNode();
    // Avoid copying long strings into call site.
    if (isLongString(node.value)) {
      data.hasLongString = true;
    }
  }

  @override
  visitInstanceGet(ir.InstanceGet node) {
    registerCall();
    registerRegularNode();
    registerReductiveNode();
    skipReductiveNodes(() => visit(node.name));
    visit(node.receiver);
  }

  @override
  visitInstanceTearOff(ir.InstanceTearOff node) {
    registerCall();
    registerRegularNode();
    registerReductiveNode();
    skipReductiveNodes(() => visit(node.name));
    visit(node.receiver);
  }

  @override
  visitDynamicGet(ir.DynamicGet node) {
    registerCall();
    registerRegularNode();
    registerReductiveNode();
    skipReductiveNodes(() => visit(node.name));
    visit(node.receiver);
  }

  @override
  visitInstanceSet(ir.InstanceSet node) {
    registerCall();
    registerRegularNode();
    registerReductiveNode();
    skipReductiveNodes(() => visit(node.name));
    visit(node.receiver);
    visit(node.value);
  }

  @override
  visitDynamicSet(ir.DynamicSet node) {
    registerCall();
    registerRegularNode();
    registerReductiveNode();
    skipReductiveNodes(() => visit(node.name));
    visit(node.receiver);
    visit(node.value);
  }

  @override
  visitVariableGet(ir.VariableGet node) {
    if (discountParameters && node.variable.parent is ir.FunctionNode) return;
    registerRegularNode();
    registerReductiveNode();
    skipReductiveNodes(() => visit(node.promotedType));
  }

  @override
  visitThisExpression(ir.ThisExpression node) {
    registerRegularNode();
    registerReductiveNode();
  }

  @override
  visitStaticGet(ir.StaticGet node) {
    // Assume lazy-init static, loaded via a call: `$.$get$foo()`.
    registerCall();
    registerRegularNode();
    registerReductiveNode();
  }

  @override
  visitConstructorInvocation(ir.ConstructorInvocation node) {
    registerRegularNode();
    registerReductiveNode();
    if (node.isConst) {
      // A const constructor call compiles to a constant pool reference.
      skipReductiveNodes(() => node.visitChildren(this));
    } else {
      registerCall();
      _processArguments(node.arguments, node.target.function);
    }
  }

  @override
  visitStaticInvocation(ir.StaticInvocation node) {
    registerRegularNode();
    if (node.isConst) {
      data.hasExternalConstantConstructorCall = true;
      skipReductiveNodes(() => node.visitChildren(this));
    } else {
      registerCall();
      registerReductiveNode();
      _processArguments(node.arguments, node.target.function);
    }
  }

  @override
  visitInstanceInvocation(ir.InstanceInvocation node) {
    registerRegularNode();
    registerReductiveNode();
    registerCall();
    visit(node.receiver);
    skipReductiveNodes(() => visit(node.name));
    _processArguments(node.arguments, null);
  }

  @override
  visitInstanceGetterInvocation(ir.InstanceGetterInvocation node) {
    registerRegularNode();
    registerReductiveNode();
    registerCall();
    visit(node.receiver);
    skipReductiveNodes(() => visit(node.name));
    _processArguments(node.arguments, null);
  }

  @override
  visitDynamicInvocation(ir.DynamicInvocation node) {
    registerRegularNode();
    registerReductiveNode();
    registerCall();
    visit(node.receiver);
    skipReductiveNodes(() => visit(node.name));
    _processArguments(node.arguments, null);
  }

  @override
  visitFunctionInvocation(ir.FunctionInvocation node) {
    registerRegularNode();
    registerReductiveNode();
    registerCall();
    visit(node.receiver);
    skipReductiveNodes(() => visit(node.name));
    _processArguments(node.arguments, null);
  }

  @override
  visitLocalFunctionInvocation(ir.LocalFunctionInvocation node) {
    registerRegularNode();
    registerReductiveNode();
    registerCall();
    _processArguments(node.arguments, null);
    // Account for the implicit access to the local variable:
    registerRegularNode();
    registerReductiveNode();
  }

  @override
  visitEqualsNull(ir.EqualsNull node) {
    registerRegularNode();
    registerReductiveNode();
    visit(node.expression);
  }

  @override
  visitEqualsCall(ir.EqualsCall node) {
    registerRegularNode();
    registerReductiveNode();
    registerCall();
    visit(node.left);
    visit(node.right);
  }

  _processArguments(ir.Arguments arguments, ir.FunctionNode? target) {
    registerRegularNode();
    if (arguments.types.isNotEmpty) {
      data.hasTypeArguments = true;
      skipReductiveNodes(() => visitList(arguments.types));
    }
    int count = arguments.positional.length + arguments.named.length;
    data.argumentCounts.add(count);

    if (target != null) {
      // Disallow defaulted optional arguments since they will be passed
      // explicitly.
      if (target.positionalParameters.length + target.namedParameters.length >
          count) {
        data.hasArgumentDefaulting = true;
      }
    }

    visitList(arguments.positional);
    for (ir.NamedExpression expression in arguments.named) {
      registerRegularNode();
      expression.value.accept(this);
    }
  }

  @override
  visitAsExpression(ir.AsExpression node) {
    registerRegularNode();
    visit(node.operand);
    skipReductiveNodes(() => visit(node.type));
    if (!(node.isTypeError && omitImplicitCasts)) {
      data.hasCast = true;
    }
  }

  @override
  visitVariableDeclaration(ir.VariableDeclaration node) {
    registerRegularNode();
    skipReductiveNodes(() {
      visitList(node.annotations);
      visit(node.type);
    });
    visit(node.initializer);

    // A local variable is an alias for the initializer expression.
    if (node.initializer != null) {
      unregisterReductiveNode(); // discount one reference to the variable.
    }
  }

  @override
  visitIfStatement(ir.IfStatement node) {
    registerRegularNode();
    node.visitChildren(this);
    data.hasIf = true;
  }

  void handleGenerativeConstructorFactory(ir.Constructor node) {
    // Generative constructors are compiled to a factory constructor which
    // contains inlined all the initializations up the inheritance chain and
    // then call each of the constructor bodies down the inheritance chain.
    ir.Constructor? constructor = node;

    Set<ir.Field> initializedFields = {};
    bool hasCallToSomeConstructorBody = false;

    inheritance_loop:
    while (constructor != null) {
      ir.Constructor? superConstructor;
      for (var initializer in constructor.initializers) {
        if (initializer is ir.RedirectingInitializer) {
          // Discount the size of the arguments by references that are
          // pass-through.
          // TODO(sra): Need to add size of defaulted arguments.
          var discountParametersOld = discountParameters;
          discountParameters = true;
          initializer.arguments.accept(this);
          discountParameters = discountParametersOld;
          constructor = initializer.target;
          continue inheritance_loop;
        } else if (initializer is ir.SuperInitializer) {
          superConstructor = initializer.target;
          // Discount the size of the arguments by references that are
          // pass-through.
          // TODO(sra): Need to add size of defaulted arguments.
          var discountParametersOld = discountParameters;
          discountParameters = true;
          initializer.arguments.accept(this);
          discountParameters = discountParametersOld;
        } else if (initializer is ir.FieldInitializer) {
          initializedFields.add(initializer.field);
          initializer.value.accept(this);
        } else if (initializer is ir.AssertInitializer) {
          if (enableUserAssertions) {
            initializer.accept(this);
          }
        } else {
          initializer.accept(this);
        }
      }

      _handleFields(constructor!.enclosingClass, initializedFields);

      // There will be a call to the constructor's body, which might be empty
      // and inlined away.
      var function = constructor.function;
      var body = function.body!;
      if (!isEmptyBody(body)) {
        // All of the parameters are passed to the body.
        int parameterCount = function.positionalParameters.length +
            function.namedParameters.length +
            function.typeParameters.length;

        hasCallToSomeConstructorBody = true;
        registerCall();
        // A body call looks like "t.Body$(arguments);", i.e. an expression
        // statement with an instance member call, but the receiver is not
        // counted in the arguments. I'm guessing about 6 nodes for this.
        registerRegularNode(
            6 + parameterCount * INLINING_NODES_OUTSIDE_LOOP_ARG_FACTOR);

        // We can't inline a generative constructor factory when one of the
        // bodies rewrites the environment to put locals or parameters into a
        // box. The box is created in the generative constructor factory since
        // the box may be shared between closures in the initializer list and
        // closures in the constructor body.
        var bodyVisitor = InlineWeederBodyClosure();
        body.accept(bodyVisitor);
        if (bodyVisitor.tooDifficult) {
          data.hasClosure = true;
        }
      }

      if (superConstructor != null) {
        // The class of the super-constructor may not be the supertype class. In
        // this case, we must go up the class hierarchy until we reach the class
        // containing the super-constructor.
        ir.Supertype supertype = constructor.enclosingClass.supertype!;
        while (supertype.classNode != superConstructor.enclosingClass) {
          _handleFields(supertype.classNode, initializedFields);
          supertype = supertype.classNode.supertype!;
        }
      }
      constructor = superConstructor;
    }

    // In addition to the initializer expressions and body calls, there is an
    // allocator call.
    if (hasCallToSomeConstructorBody) {
      // A temporary is required so we have
      //
      //     t=new ...;
      //     ...;
      //     use(t);
      //
      // I'm guessing it takes about 4 nodes to introduce the temporary and
      // assign it.
      registerRegularNode(4); // A temporary is required.
    }
    // The initial field values are passed to the allocator.
    registerRegularNode(
        initializedFields.length * INLINING_NODES_OUTSIDE_LOOP_ARG_FACTOR);
  }

  void _handleFields(ir.Class cls, Set<ir.Field> initializedFields) {
    for (ir.Field field in cls.fields) {
      if (!field.isInstanceMember) continue;
      final initializer = field.initializer;
      if (initializer == null ||
          initializer is ir.ConstantExpression &&
              initializer.constant is ir.PrimitiveConstant ||
          initializer is ir.BasicLiteral) {
        // Simple field initializers happen in the allocator, so do not
        // contribute to the size of the generative constructor factory.
        // TODO(sra): Use FieldInfo which tells us if the field is elided or
        // initialized in the allocator.
        continue;
      }
      if (!initializedFields.add(field)) continue;
      initializer.accept(this);
    }
    // If [cls] is a mixin application, include fields from mixed in class.
    if (cls.mixedInType != null) {
      _handleFields(cls.mixedInType!.classNode, initializedFields);
    }
  }

  bool isEmptyBody(ir.Statement body) {
    if (body is ir.EmptyStatement) return true;
    if (body is ir.Block) return body.statements.every(isEmptyBody);
    if (body is ir.AssertStatement && !enableUserAssertions) return true;
    return false;
  }
}

/// Visitor to detect environment-rewriting that prevents inlining
/// (e.g. closures).
class InlineWeederBodyClosure extends ir.Visitor<void>
    with ir.VisitorVoidMixin {
  bool tooDifficult = false;

  InlineWeederBodyClosure();

  @override
  defaultNode(ir.Node node) {
    if (tooDifficult) return;
    node.visitChildren(this);
  }

  @override
  void visitFunctionExpression(ir.FunctionExpression node) {
    tooDifficult = true;
  }

  @override
  void visitFunctionDeclaration(ir.FunctionDeclaration node) {
    tooDifficult = true;
  }

  @override
  void visitFunctionNode(ir.FunctionNode node) {
    assert(false);
    if (node.asyncMarker != ir.AsyncMarker.Sync) {
      tooDifficult = true;
      return;
    }
    node.visitChildren(this);
  }
}
