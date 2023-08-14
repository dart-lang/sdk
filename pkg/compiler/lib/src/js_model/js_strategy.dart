// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_model.strategy;

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../common/codegen.dart';
import '../common/elements.dart' show CommonElements, ElementEnvironment;
import '../common/tasks.dart';
import '../common/work.dart';
import '../compiler.dart';
import '../deferred_load/output_unit.dart'
    show LateOutputUnitDataBuilder, OutputUnitData;
import '../dump_info.dart';
import '../elements/entities.dart';
import '../enqueue.dart';
import '../inferrer/abstract_value_domain.dart';
import '../io/kernel_source_information.dart'
    show KernelSourceInformationStrategy;
import '../io/source_information.dart';
import '../inferrer/type_graph_inferrer.dart';
import '../inferrer/types.dart';
import '../js/js_source_mapping.dart';
import '../js_backend/backend.dart';
import '../js_backend/backend_impact.dart';
import '../js_backend/codegen_inputs.dart';
import '../js_backend/codegen_listener.dart';
import '../js_backend/custom_elements_analysis.dart';
import '../js_backend/enqueuer.dart';
import '../js_backend/impact_transformer.dart';
import '../js_backend/inferred_data.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/namer.dart'
    show
        FixedNames,
        FrequencyBasedNamer,
        MinifiedFixedNames,
        MinifyNamer,
        ModularNamer,
        Namer;
import '../js_backend/records_codegen.dart';
import '../js_backend/runtime_types.dart';
import '../js_backend/runtime_types_codegen.dart';
import '../js_backend/runtime_types_new.dart' show RecipeEncoder;
import '../js_backend/runtime_types_new.dart' show RecipeEncoderImpl;
import '../js_emitter/code_emitter_task.dart' show ModularEmitter;
import '../js_emitter/js_emitter.dart' show CodeEmitterTask;
import '../js_model/js_world.dart' show JClosedWorld;
import '../js/js.dart' as js;
import '../kernel/kernel_strategy.dart';
import '../kernel/kernel_world.dart';
import '../native/behavior.dart';
import '../native/enqueue.dart';
import '../options.dart';
import '../serialization/serialization.dart';
import '../ssa/builder.dart';
import '../ssa/metrics.dart';
import '../ssa/nodes.dart';
import '../ssa/ssa.dart';
import '../ssa/types.dart';
import '../tracer.dart';
import '../universe/codegen_world_builder.dart';
import '../universe/selector.dart';
import '../universe/world_impact.dart';
import 'closure.dart';
import 'element_map.dart';
import 'element_map_impl.dart';
import 'js_world.dart';
import 'js_world_builder.dart' show JClosedWorldBuilder;
import 'locals.dart';
import 'records.dart' show RecordDataBuilder;

/// JS Strategy pattern that defines the element model used in type inference
/// and code generation.
class JsBackendStrategy {
  final Compiler _compiler;
  late JsKernelToElementMap _elementMap;

  /// Codegen support for generating table of interceptors and
  /// constructors for custom elements.
  late final CustomElementsCodegenAnalysis _customElementsCodegenAnalysis;

  late final RecordsCodegen _recordsCodegen;

  late final NativeCodegenEnqueuer _nativeCodegenEnqueuer;

  late final Namer _namer;

  late final CodegenImpactTransformer _codegenImpactTransformer;

  late final CodeEmitterTask _emitterTask;

  late final RuntimeTypesChecksBuilder _rtiChecksBuilder;

  late final FunctionCompiler _functionCompiler;

  late SourceInformationStrategy sourceInformationStrategy;

  final SsaMetrics _ssaMetrics = SsaMetrics();

  /// The generated code as a js AST for compiled methods.
  final Map<MemberEntity, js.Expression> generatedCode = {};

  JsBackendStrategy(this._compiler) {
    bool generateSourceMap = _compiler.options.generateSourceMap;
    if (!generateSourceMap) {
      sourceInformationStrategy = const JavaScriptSourceInformationStrategy();
    } else {
      sourceInformationStrategy = KernelSourceInformationStrategy();
    }
    _emitterTask = CodeEmitterTask(_compiler, generateSourceMap);
    _functionCompiler = SsaFunctionCompiler(
        _compiler.options,
        _compiler.reporter,
        _ssaMetrics,
        this,
        _compiler.measurer,
        sourceInformationStrategy);
  }

  List<CompilerTask> get tasks {
    List<CompilerTask> result = functionCompiler.tasks;
    result.add(emitterTask);
    return result;
  }

  FunctionCompiler get functionCompiler => _functionCompiler;

  CodeEmitterTask get emitterTask => _emitterTask;

  Namer get namerForTesting => _namer;

  NativeCodegenEnqueuer get nativeCodegenEnqueuer => _nativeCodegenEnqueuer;

  RuntimeTypesChecksBuilder get rtiChecksBuilderForTesting => _rtiChecksBuilder;

  Map<MemberEntity, WorldImpact>? codegenImpactsForTesting;

  String? getGeneratedCodeForTesting(MemberEntity element) {
    if (generatedCode[element] == null) return null;
    return js.prettyPrint(generatedCode[element]!,
        enableMinification: _compiler.options.enableMinification);
  }

  /// Codegen support for generating table of interceptors and
  /// constructors for custom elements.
  CustomElementsCodegenAnalysis get customElementsCodegenAnalysis =>
      _customElementsCodegenAnalysis;

  RecordsCodegen get recordsCodegen => _recordsCodegen;

  RuntimeTypesChecksBuilder get rtiChecksBuilder {
    assert(
        !_rtiChecksBuilder.rtiChecksBuilderClosed,
        failedAt(NO_LOCATION_SPANNABLE,
            "RuntimeTypesChecks has already been computed."));
    return _rtiChecksBuilder;
  }

  /// Create the [JClosedWorld] from [closedWorld].
  JClosedWorld createJClosedWorld(
      KClosedWorld closedWorld, OutputUnitData outputUnitData) {
    KernelFrontendStrategy strategy = _compiler.frontendStrategy;
    _elementMap = JsKernelToElementMap(
        _compiler.reporter,
        _compiler.environment,
        strategy.elementMap,
        closedWorld.liveMemberUsage,
        closedWorld.liveAbstractInstanceMembers,
        closedWorld.annotationsData);
    ClosureDataBuilder closureDataBuilder = ClosureDataBuilder(
        _compiler.reporter, _elementMap, closedWorld.annotationsData);
    RecordDataBuilder recordDataBuilder = RecordDataBuilder(
        _compiler.reporter, _elementMap, closedWorld.annotationsData);
    JClosedWorldBuilder closedWorldBuilder = JClosedWorldBuilder(
        _elementMap,
        closureDataBuilder,
        recordDataBuilder,
        _compiler.options,
        _compiler.reporter,
        _compiler.abstractValueStrategy);
    JClosedWorld jClosedWorld = closedWorldBuilder.convertClosedWorld(
        closedWorld, strategy.closureModels, outputUnitData);
    _elementMap.lateOutputUnitDataBuilder =
        LateOutputUnitDataBuilder(jClosedWorld.outputUnitData);
    return jClosedWorld;
  }

  /// Registers [closedWorld] as the current closed world used by this backend
  /// strategy.
  ///
  /// This is used to support serialization after type inference.
  void registerJClosedWorld(covariant JClosedWorld closedWorld) {
    _elementMap = closedWorld.elementMap;
    sourceInformationStrategy.onElementMapAvailable(_elementMap);
  }

  /// Called when the compiler starts running the codegen.
  ///
  /// Returns the [CodegenInputs] objects with the needed data.
  CodegenInputs onCodegenStart(
      GlobalTypeInferenceResults globalTypeInferenceResults) {
    JClosedWorld closedWorld = globalTypeInferenceResults.closedWorld;
    FixedNames fixedNames = _compiler.options.enableMinification
        ? const MinifiedFixedNames()
        : const FixedNames();

    Tracer tracer =
        Tracer(closedWorld, _compiler.options, _compiler.outputProvider);

    RuntimeTypesSubstitutions rtiSubstitutions;
    if (_compiler.options.disableRtiOptimization) {
      final trivialSubs =
          rtiSubstitutions = TrivialRuntimeTypesSubstitutions(closedWorld);
      _rtiChecksBuilder =
          TrivialRuntimeTypesChecksBuilder(closedWorld, trivialSubs);
    } else {
      RuntimeTypesImpl runtimeTypesImpl = RuntimeTypesImpl(closedWorld);
      _rtiChecksBuilder = runtimeTypesImpl;
      rtiSubstitutions = runtimeTypesImpl;
    }

    RecipeEncoder rtiRecipeEncoder = RecipeEncoderImpl(closedWorld,
        rtiSubstitutions, closedWorld.nativeData, closedWorld.commonElements);

    CodegenInputs codegen =
        CodegenInputs(rtiSubstitutions, rtiRecipeEncoder, tracer, fixedNames);

    functionCompiler.initialize(globalTypeInferenceResults, codegen);
    return codegen;
  }

  /// Creates an [Enqueuer] for code generation specific to this backend.
  CodegenEnqueuer createCodegenEnqueuer(
      CompilerTask task,
      JClosedWorld closedWorld,
      GlobalTypeInferenceResults globalInferenceResults,
      CodegenInputs codegen,
      CodegenResults codegenResults,
      SourceLookup sourceLookup) {
    OneShotInterceptorData oneShotInterceptorData = OneShotInterceptorData(
        closedWorld.interceptorData,
        closedWorld.commonElements,
        closedWorld.nativeData);
    _onCodegenEnqueuerStart(
        globalInferenceResults, codegen, oneShotInterceptorData);
    ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
    CommonElements commonElements = closedWorld.commonElements;
    BackendImpacts impacts = BackendImpacts(commonElements, _compiler.options);
    _customElementsCodegenAnalysis = CustomElementsCodegenAnalysis(
        commonElements, elementEnvironment, closedWorld.nativeData);
    _recordsCodegen = RecordsCodegen(commonElements, closedWorld.recordData);
    return CodegenEnqueuer(
        task,
        CodegenWorldBuilderImpl(
            closedWorld,
            _compiler.abstractValueStrategy.createSelectorStrategy(),
            oneShotInterceptorData),
        KernelCodegenWorkItemBuilder(
            this,
            closedWorld,
            codegenResults,
            ClosedEntityLookup(_elementMap),
            // TODO(johnniwinther): Avoid the need for a [ComponentLookup]. This
            // is caused by some type masks holding a kernel node for using in
            // tracing.
            ComponentLookup(_elementMap.programEnv.mainComponent),
            sourceLookup),
        CodegenEnqueuerListener(
            _compiler.options,
            elementEnvironment,
            commonElements,
            impacts,
            closedWorld.backendUsage,
            closedWorld.rtiNeed,
            closedWorld.recordData,
            customElementsCodegenAnalysis,
            recordsCodegen,
            nativeCodegenEnqueuer),
        closedWorld.annotationsData);
  }

  /// Called before the compiler starts running the codegen enqueuer.
  void _onCodegenEnqueuerStart(
      GlobalTypeInferenceResults globalTypeInferenceResults,
      CodegenInputs codegen,
      OneShotInterceptorData oneShotInterceptorData) {
    JClosedWorld closedWorld = globalTypeInferenceResults.closedWorld;
    FixedNames fixedNames = codegen.fixedNames;
    _namer = _compiler.options.enableMinification
        ? _compiler.options.useFrequencyNamer
            ? FrequencyBasedNamer(closedWorld, fixedNames)
            : MinifyNamer(closedWorld, fixedNames)
        : Namer(closedWorld, fixedNames);
    _nativeCodegenEnqueuer = NativeCodegenEnqueuer(
        _compiler.options,
        closedWorld.elementEnvironment,
        closedWorld.commonElements,
        closedWorld.dartTypes,
        emitterTask,
        closedWorld.liveNativeClasses,
        closedWorld.nativeData);
    emitterTask.createEmitter(_namer, codegen, closedWorld);
    // TODO(johnniwinther): Share the impact object created in
    // createCodegenEnqueuer.
    BackendImpacts impacts =
        BackendImpacts(closedWorld.commonElements, _compiler.options);

    _codegenImpactTransformer = CodegenImpactTransformer(
        closedWorld,
        closedWorld.elementEnvironment,
        impacts,
        closedWorld.nativeData,
        closedWorld.backendUsage,
        closedWorld.rtiNeed,
        nativeCodegenEnqueuer,
        _namer,
        oneShotInterceptorData,
        rtiChecksBuilder,
        emitterTask.nativeEmitter);
  }

  WorldImpact generateCode(
      WorkItem work,
      JClosedWorld closedWorld,
      CodegenResults codegenResults,
      EntityLookup entityLookup,
      ComponentLookup componentLookup,
      SourceLookup sourceLookup) {
    MemberEntity member = work.element;
    CodegenResult result = codegenResults.getCodegenResults(member);
    if (_compiler.options.testMode) {
      bool useDataKinds = true;
      List<Object> data = [];
      DataSinkWriter sink = DataSinkWriter(
          ObjectDataSink(data), _compiler.options,
          useDataKinds: useDataKinds);
      sink.registerCodegenWriter(CodegenWriterImpl(closedWorld));
      result.writeToDataSink(sink);
      sink.close();
      DataSourceReader source = DataSourceReader(
          ObjectDataSource(data), _compiler.options,
          useDataKinds: useDataKinds);
      List<ModularName> modularNames = [];
      List<ModularExpression> modularExpression = [];
      source.registerCodegenReader(
          CodegenReaderImpl(closedWorld, modularNames, modularExpression));
      source.registerEntityLookup(entityLookup);
      source.registerComponentLookup(componentLookup);
      source.registerSourceLookup(sourceLookup);
      result = CodegenResult.readFromDataSource(
          source, modularNames, modularExpression);
    }
    if (result.code != null) {
      generatedCode[member] = result.code!;
    }
    if (retainDataForTesting) {
      codegenImpactsForTesting ??= {};
      codegenImpactsForTesting![member] = result.impact;
    }
    WorldImpact worldImpact =
        _codegenImpactTransformer.transformCodegenImpact(result.impact);
    _compiler.dumpInfoTask.registerImpact(member, worldImpact);
    result.applyModularState(_namer, emitterTask.emitter);
    return worldImpact;
  }

  /// Called when code generation has been completed.
  void onCodegenEnd(CodegenInputs codegen) {
    sourceInformationStrategy.onComplete();
    codegen.tracer.close();
  }

  /// Generates the output and returns the total size of the generated code.
  int assembleProgram(JClosedWorld closedWorld, InferredData inferredData,
      CodegenInputs codegenInputs, CodegenWorld codegenWorld) {
    int programSize = emitterTask.assembleProgram(
        _namer, closedWorld, inferredData, codegenInputs, codegenWorld);
    closedWorld.noSuchMethodData.emitDiagnostic(_compiler.reporter);
    return programSize;
  }

  /// Creates the [SsaBuilder] used for the element model.
  SsaBuilder createSsaBuilder(
      CompilerTask task, SourceInformationStrategy sourceInformationStrategy) {
    return KernelSsaBuilder(
        task,
        _compiler.options,
        _compiler.reporter,
        _compiler.dumpInfoTask,
        _ssaMetrics,
        _elementMap,
        sourceInformationStrategy);
  }

  /// Creates a [SourceSpan] from [spannable] in context of [currentElement].
  SourceSpan spanFromSpannable(Spannable spannable, Entity? currentElement) {
    return _elementMap.getSourceSpan(spannable, currentElement);
  }

  /// Creates the [TypesInferrer] used by this strategy.
  TypesInferrer createTypesInferrer(
      covariant JClosedWorld closedWorld,
      GlobalLocalsMap globalLocalsMap,
      InferredDataBuilder inferredDataBuilder) {
    return TypeGraphInferrer(
        _compiler, closedWorld, globalLocalsMap, inferredDataBuilder);
  }

  /// Prepare [source] to deserialize modular code generation data.
  void prepareCodegenReader(DataSourceReader source) {
    source.registerEntityReader(ClosedEntityReader(_elementMap));
    source.registerEntityLookup(ClosedEntityLookup(_elementMap));
    source.registerComponentLookup(
        ComponentLookup(_elementMap.programEnv.mainComponent));
  }

  /// Calls [f] for every member that needs to be serialized for modular code
  /// generation and returns an [EntityWriter] for encoding these members in
  /// the serialized data.
  ///
  /// The needed members include members computed on demand during non-modular
  /// code generation, such as constructor bodies and generator bodies.
  EntityWriter forEachCodegenMember(void Function(MemberEntity member) f) {
    int earlyMemberIndexLimit = _elementMap.prepareForCodegenSerialization();
    ClosedEntityWriter entityWriter = ClosedEntityWriter(earlyMemberIndexLimit);
    for (int memberIndex = 0;
        memberIndex < _elementMap.members.length;
        memberIndex++) {
      final member = _elementMap.members.getEntity(memberIndex);
      if (member == null || member.isAbstract) continue;
      f(member);
    }
    return entityWriter;
  }
}

class KernelCodegenWorkItemBuilder implements WorkItemBuilder {
  final JsBackendStrategy _backendStrategy;
  final JClosedWorld _closedWorld;
  final CodegenResults _codegenResults;
  final EntityLookup _entityLookup;
  final ComponentLookup _componentLookup;
  final SourceLookup _sourceLookup;

  KernelCodegenWorkItemBuilder(
      this._backendStrategy,
      this._closedWorld,
      this._codegenResults,
      this._entityLookup,
      this._componentLookup,
      this._sourceLookup);

  @override
  WorkItem? createWorkItem(MemberEntity entity) {
    if (entity.isAbstract) return null;
    return KernelCodegenWorkItem(
        _backendStrategy,
        _closedWorld,
        _codegenResults,
        _entityLookup,
        _componentLookup,
        _sourceLookup,
        entity);
  }
}

class KernelCodegenWorkItem extends WorkItem {
  final JsBackendStrategy _backendStrategy;
  final JClosedWorld _closedWorld;
  final CodegenResults _codegenResults;
  final EntityLookup _entityLookup;
  final ComponentLookup _componentLookup;
  final SourceLookup _sourceLookup;
  @override
  final MemberEntity element;

  KernelCodegenWorkItem(
      this._backendStrategy,
      this._closedWorld,
      this._codegenResults,
      this._entityLookup,
      this._componentLookup,
      this._sourceLookup,
      this.element);

  @override
  WorldImpact run() {
    return _backendStrategy.generateCode(this, _closedWorld, _codegenResults,
        _entityLookup, _componentLookup, _sourceLookup);
  }
}

/// Task for building SSA from kernel IR loaded from .dill.
class KernelSsaBuilder implements SsaBuilder {
  final CompilerTask _task;
  final CompilerOptions _options;
  final DiagnosticReporter _reporter;
  final DumpInfoTask _dumpInfoTask;
  final SsaMetrics _metrics;
  final JsToElementMap _elementMap;
  final SourceInformationStrategy _sourceInformationStrategy;

  // TODO(48820): Make this final by passing in closed world to constructor.
  FunctionInlineCache? _inlineCache;
  final InlineDataCache _inlineDataCache;

  KernelSsaBuilder(
      this._task,
      this._options,
      this._reporter,
      this._dumpInfoTask,
      this._metrics,
      this._elementMap,
      this._sourceInformationStrategy)
      : _inlineDataCache = InlineDataCache(
            enableUserAssertions: _options.enableUserAssertions,
            omitImplicitCasts: _options.omitImplicitChecks);

  @override
  HGraph? build(
      MemberEntity member,
      JClosedWorld closedWorld,
      GlobalTypeInferenceResults results,
      CodegenInputs codegen,
      CodegenRegistry registry,
      ModularNamer namer,
      ModularEmitter emitter) {
    _inlineCache ??= FunctionInlineCache(closedWorld.annotationsData);
    return _task.measure(() {
      KernelSsaGraphBuilder builder = KernelSsaGraphBuilder(
          _options,
          _reporter,
          member,
          _elementMap.getMemberThisType(member),
          _dumpInfoTask,
          _metrics,
          _elementMap,
          results,
          closedWorld,
          registry,
          namer,
          emitter,
          codegen.tracer,
          _sourceInformationStrategy,
          _inlineCache!,
          _inlineDataCache);
      return builder.build();
    });
  }
}

class KernelToTypeInferenceMapImpl implements KernelToTypeInferenceMap {
  final GlobalTypeInferenceResults _globalInferenceResults;
  late final GlobalTypeInferenceMemberResult _targetResults;

  KernelToTypeInferenceMapImpl(
      MemberEntity target, this._globalInferenceResults) {
    _targetResults = _resultOf(target);
  }

  GlobalTypeInferenceMemberResult _resultOf(MemberEntity e) =>
      _globalInferenceResults
          .resultOfMember(e is ConstructorBodyEntity ? e.constructor : e);

  @override
  AbstractValue getReturnTypeOf(FunctionEntity function) {
    return AbstractValueFactory.inferredReturnTypeForElement(
        function, _globalInferenceResults);
  }

  @override
  AbstractValue? receiverTypeOfInvocation(
      ir.Expression node, AbstractValueDomain abstractValueDomain) {
    return _targetResults.typeOfReceiver(node);
  }

  @override
  AbstractValue? receiverTypeOfGet(ir.Expression node) {
    return _targetResults.typeOfReceiver(node);
  }

  @override
  AbstractValue? receiverTypeOfSet(
      ir.Expression node, AbstractValueDomain abstractValueDomain) {
    return _targetResults.typeOfReceiver(node);
  }

  @override
  AbstractValue typeOfListLiteral(
      ir.ListLiteral listLiteral, AbstractValueDomain abstractValueDomain) {
    return _globalInferenceResults.typeOfListLiteral(listLiteral) ??
        abstractValueDomain.dynamicType;
  }

  @override
  AbstractValue? typeOfRecordLiteral(
      ir.RecordLiteral recordLiteral, AbstractValueDomain abstractValueDomain) {
    return _globalInferenceResults.typeOfRecordLiteral(recordLiteral);
  }

  @override
  AbstractValue? typeOfIterator(ir.ForInStatement node) {
    return _targetResults.typeOfIterator(node);
  }

  @override
  AbstractValue? typeOfIteratorCurrent(ir.ForInStatement node) {
    return _targetResults.typeOfIteratorCurrent(node);
  }

  @override
  AbstractValue? typeOfIteratorMoveNext(ir.ForInStatement node) {
    return _targetResults.typeOfIteratorMoveNext(node);
  }

  @override
  bool isJsIndexableIterator(
      ir.ForInStatement node, AbstractValueDomain abstractValueDomain) {
    final mask = typeOfIterator(node);
    // TODO(sra): Investigate why mask is sometimes null.
    if (mask == null) return false;
    return abstractValueDomain.isJsIndexableAndIterable(mask).isDefinitelyTrue;
  }

  @override
  AbstractValue inferredIndexType(ir.ForInStatement node) {
    return AbstractValueFactory.inferredResultTypeForSelector(
        Selector.index(), typeOfIterator(node)!, _globalInferenceResults);
  }

  @override
  AbstractValue getInferredTypeOf(MemberEntity member) {
    return AbstractValueFactory.inferredTypeForMember(
        member, _globalInferenceResults);
  }

  @override
  AbstractValue getInferredTypeOfParameter(Local parameter) {
    return AbstractValueFactory.inferredTypeForParameter(
        parameter, _globalInferenceResults);
  }

  @override
  AbstractValue resultTypeOfSelector(Selector selector, AbstractValue mask) {
    return AbstractValueFactory.inferredResultTypeForSelector(
        selector, mask, _globalInferenceResults);
  }

  @override
  AbstractValue typeFromNativeBehavior(
      NativeBehavior nativeBehavior, JClosedWorld closedWorld) {
    return AbstractValueFactory.fromNativeBehavior(nativeBehavior, closedWorld);
  }
}
