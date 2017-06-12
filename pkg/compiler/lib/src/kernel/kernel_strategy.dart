// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.frontend_strategy;

import '../closure.dart';
import '../backend_strategy.dart';
import '../common.dart';
import '../common_elements.dart';
import '../common/backend_api.dart';
import '../common/codegen.dart' show CodegenRegistry, CodegenWorkItem;
import '../common/resolution.dart';
import '../common/tasks.dart';
import '../common/work.dart';
import '../compiler.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../environment.dart' as env;
import '../enqueue.dart';
import '../frontend_strategy.dart';
import '../io/source_information.dart';
import '../js_backend/backend.dart';
import '../js_backend/backend_usage.dart';
import '../js_backend/custom_elements_analysis.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/mirrors_analysis.dart';
import '../js_backend/mirrors_data.dart';
import '../js_backend/native_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../js_backend/runtime_types.dart';
import '../js_emitter/sorter.dart';
import '../kernel/element_map.dart';
import '../library_loader.dart';
import '../native/resolver.dart';
import '../serialization/task.dart';
import '../ssa/builder_kernel.dart';
import '../ssa/nodes.dart';
import '../ssa/ssa.dart';
import '../patch_parser.dart';
import '../resolved_uri_translator.dart';
import '../universe/world_builder.dart';
import '../universe/world_impact.dart';
import '../world.dart';
import 'element_map_impl.dart';

/// Front end strategy that loads '.dill' files and builds a resolved element
/// model from kernel IR nodes.
class KernelFrontEndStrategy implements FrontEndStrategy {
  KernelToElementMapImpl elementMap;

  KernelAnnotationProcessor _annotationProcesser;

  KernelFrontEndStrategy(
      DiagnosticReporter reporter, env.Environment environment)
      : elementMap = new KernelToElementMapImpl(reporter, environment);

  @override
  LibraryLoaderTask createLibraryLoader(
      ResolvedUriTranslator uriTranslator,
      ScriptLoader scriptLoader,
      ElementScanner scriptScanner,
      LibraryDeserializer deserializer,
      PatchResolverFunction patchResolverFunc,
      PatchParserTask patchParser,
      env.Environment environment,
      DiagnosticReporter reporter,
      Measurer measurer) {
    return new DillLibraryLoaderTask(
        elementMap, uriTranslator, scriptLoader, reporter, measurer);
  }

  @override
  ElementEnvironment get elementEnvironment => elementMap.elementEnvironment;

  DartTypes get dartTypes => elementMap.types;

  @override
  AnnotationProcessor get annotationProcesser =>
      _annotationProcesser ??= new KernelAnnotationProcessor(elementMap);

  @override
  NativeClassFinder createNativeClassFinder(NativeBasicData nativeBasicData) {
    return new BaseNativeClassFinder(elementMap.elementEnvironment,
        elementMap.commonElements, nativeBasicData);
  }

  NoSuchMethodResolver createNoSuchMethodResolver() {
    return new KernelNoSuchMethodResolver(elementMap);
  }

  /// Computes the main function from [mainLibrary] adding additional world
  /// impact to [impactBuilder].
  FunctionEntity computeMain(
      LibraryEntity mainLibrary, WorldImpactBuilder impactBuilder) {
    return elementEnvironment.mainFunction;
  }

  CustomElementsResolutionAnalysis createCustomElementsResolutionAnalysis(
      NativeBasicData nativeBasicData,
      BackendUsageBuilder backendUsageBuilder) {
    return new CustomElementsResolutionAnalysisImpl();
  }

  MirrorsDataBuilder createMirrorsDataBuilder() {
    return new MirrorsDataBuilderImpl();
  }

  MirrorsResolutionAnalysis createMirrorsResolutionAnalysis(
      JavaScriptBackend backend) {
    return new MirrorsResolutionAnalysisImpl();
  }

  RuntimeTypesNeedBuilder createRuntimeTypesNeedBuilder() {
    return new RuntimeTypesNeedBuilderImpl(
        elementEnvironment, elementMap.types);
  }

  ResolutionWorldBuilder createResolutionWorldBuilder(
      NativeBasicData nativeBasicData,
      NativeDataBuilder nativeDataBuilder,
      InterceptorDataBuilder interceptorDataBuilder,
      BackendUsageBuilder backendUsageBuilder,
      SelectorConstraintsStrategy selectorConstraintsStrategy) {
    return new KernelResolutionWorldBuilder(
        elementMap,
        nativeBasicData,
        nativeDataBuilder,
        interceptorDataBuilder,
        backendUsageBuilder,
        selectorConstraintsStrategy);
  }

  WorkItemBuilder createResolutionWorkItemBuilder(
      NativeBasicData nativeBasicData,
      NativeDataBuilder nativeDataBuilder,
      ImpactTransformer impactTransformer) {
    return new KernelWorkItemBuilder(
        elementMap, nativeBasicData, nativeDataBuilder, impactTransformer);
  }

  @override
  SourceSpan spanFromSpannable(Spannable spannable, Entity currentElement) {
    // TODO(johnniwinther): Compute source spans from kernel elements.
    return new SourceSpan(null, null, null);
  }
}

class KernelWorkItemBuilder implements WorkItemBuilder {
  final KernelToElementMapImpl _elementMap;
  final ImpactTransformer _impactTransformer;
  final NativeMemberResolver _nativeMemberResolver;

  KernelWorkItemBuilder(this._elementMap, NativeBasicData nativeBasicData,
      NativeDataBuilder nativeDataBuilder, this._impactTransformer)
      : _nativeMemberResolver = new KernelNativeMemberResolver(
            _elementMap, nativeBasicData, nativeDataBuilder);

  @override
  WorkItem createWorkItem(MemberEntity entity) {
    return new KernelWorkItem(
        _elementMap, _impactTransformer, _nativeMemberResolver, entity);
  }
}

class KernelWorkItem implements ResolutionWorkItem {
  final KernelToElementMapImpl _elementMap;
  final ImpactTransformer _impactTransformer;
  final NativeMemberResolver _nativeMemberResolver;
  final MemberEntity element;

  KernelWorkItem(this._elementMap, this._impactTransformer,
      this._nativeMemberResolver, this.element);

  @override
  WorldImpact run() {
    _nativeMemberResolver.resolveNativeMember(element);
    ResolutionImpact impact = _elementMap.computeWorldImpact(element);
    return _impactTransformer.transformResolutionImpact(impact);
  }
}

/// Mock implementation of [MirrorsDataImpl].
class MirrorsDataBuilderImpl extends MirrorsDataImpl {
  MirrorsDataBuilderImpl() : super(null, null, null);

  @override
  void registerUsedMember(MemberEntity member) {}

  @override
  void computeMembersNeededForReflection(
      ResolutionWorldBuilder worldBuilder, ClosedWorld closedWorld) {}

  @override
  void maybeMarkClosureAsNeededForReflection(
      ClosureClassElement globalizedElement,
      FunctionElement callFunction,
      FunctionElement function) {}

  @override
  void registerConstSymbol(String name) {}

  @override
  void registerMirrorUsage(
      Set<String> symbols, Set<Element> targets, Set<Element> metaTargets) {}
}

/// Mock implementation of [CustomElementsResolutionAnalysis].
class CustomElementsResolutionAnalysisImpl
    implements CustomElementsResolutionAnalysis {
  @override
  CustomElementsAnalysisJoin get join {
    throw new UnimplementedError('CustomElementsResolutionAnalysisImpl.join');
  }

  @override
  WorldImpact flush() {
    // TODO(johnniwinther): Implement this.
    return const WorldImpact();
  }

  @override
  void registerStaticUse(MemberEntity element) {}

  @override
  void registerInstantiatedClass(ClassEntity classElement) {}

  @override
  void registerTypeLiteral(DartType type) {}
}

/// Mock implementation of [MirrorsResolutionAnalysis].
class MirrorsResolutionAnalysisImpl implements MirrorsResolutionAnalysis {
  @override
  void onQueueEmpty(Enqueuer enqueuer, Iterable<ClassEntity> recentClasses) {}

  @override
  MirrorsCodegenAnalysis close() {
    // TODO(johnniwinther): Implement this.
    return new MirrorsCodegenAnalysisImpl();
  }

  @override
  void onResolutionComplete() {}
}

/// Backend strategy that uses the kernel elements as the backend model.
// TODO(johnniwinther): Replace this with a strategy based on the J-element
// model.
class KernelBackendStrategy implements BackendStrategy {
  final Compiler _compiler;

  KernelBackendStrategy(this._compiler);

  @override
  ClosedWorldRefiner createClosedWorldRefiner(KernelClosedWorld closedWorld) {
    return closedWorld;
  }

  @override
  Sorter get sorter =>
      throw new UnimplementedError('KernelBackendStrategy.sorter');

  @override
  void convertClosures(ClosedWorldRefiner closedWorldRefiner) {
    // TODO(johnniwinther,efortuna): Compute closure classes for kernel based
    // elements.
  }

  @override
  WorkItemBuilder createCodegenWorkItemBuilder(ClosedWorld closedWorld) {
    return new KernelCodegenWorkItemBuilder(_compiler.backend, closedWorld);
  }

  @override
  CodegenWorldBuilder createCodegenWorldBuilder(
      NativeBasicData nativeBasicData,
      ClosedWorld closedWorld,
      SelectorConstraintsStrategy selectorConstraintsStrategy) {
    return new KernelCodegenWorldBuilder(_compiler.elementEnvironment,
        nativeBasicData, closedWorld, selectorConstraintsStrategy);
  }

  @override
  SsaBuilderTask createSsaBuilderTask(JavaScriptBackend backend,
      SourceInformationStrategy sourceInformationStrategy) {
    return new KernelSsaBuilderTask(backend.compiler);
  }
}

class MirrorsCodegenAnalysisImpl implements MirrorsCodegenAnalysis {
  @override
  int get preMirrorsMethodCount {
    throw new UnimplementedError(
        'MirrorsCodegenAnalysisImpl.preMirrorsMethodCount');
  }

  @override
  void onQueueEmpty(Enqueuer enqueuer, Iterable<ClassEntity> recentClasses) {
    throw new UnimplementedError('MirrorsCodegenAnalysisImpl.onQueueEmpty');
  }
}

class KernelCodegenWorkItemBuilder implements WorkItemBuilder {
  final JavaScriptBackend _backend;
  final ClosedWorld _closedWorld;

  KernelCodegenWorkItemBuilder(this._backend, this._closedWorld);

  @override
  CodegenWorkItem createWorkItem(MemberEntity entity) {
    return new KernelCodegenWorkItem(_backend, _closedWorld, entity);
  }
}

class KernelCodegenWorkItem extends CodegenWorkItem {
  final JavaScriptBackend _backend;
  final ClosedWorld _closedWorld;
  final MemberEntity element;
  final CodegenRegistry registry;

  KernelCodegenWorkItem(this._backend, this._closedWorld, this.element)
      : registry = new CodegenRegistry(element);

  @override
  WorldImpact run() {
    return _backend.codegen(this, _closedWorld);
  }
}

/// Task for building SSA from kernel IR loaded from .dill.
class KernelSsaBuilderTask extends CompilerTask implements SsaBuilderTask {
  final Compiler _compiler;

  KernelSsaBuilderTask(this._compiler) : super(_compiler.measurer);

  KernelToElementMap get _elementMap {
    KernelFrontEndStrategy frontEndStrategy = _compiler.frontEndStrategy;
    return frontEndStrategy.elementMap;
  }

  @override
  HGraph build(CodegenWorkItem work, ClosedWorld closedWorld) {
    KernelSsaBuilder builder = new KernelSsaBuilder(
        work.element,
        work.element.enclosingClass,
        _compiler,
        _elementMap,
        closedWorld,
        work.registry,
        const SourceInformationBuilder(),
        null);
    return builder.build();
  }
}
