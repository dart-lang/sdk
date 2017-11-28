// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.frontend_strategy;

import '../../compiler_new.dart' as api;
import '../common.dart';
import '../common/backend_api.dart';
import '../common/resolution.dart';
import '../common/tasks.dart';
import '../common/work.dart';
import '../common_elements.dart';
import '../compiler.dart';
import '../deferred_load.dart' show DeferredLoadTask;
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../enqueue.dart';
import '../environment.dart' as env;
import '../frontend_strategy.dart';
import '../js_backend/backend.dart';
import '../js_backend/backend_usage.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/mirrors_analysis.dart';
import '../js_backend/mirrors_data.dart';
import '../js_backend/native_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../js_backend/runtime_types.dart';
import '../js_model/closure.dart' show ScopeModel;
import '../library_loader.dart';
import '../native/enqueue.dart' show NativeResolutionEnqueuer;
import '../native/resolver.dart';
import '../options.dart';
import '../patch_parser.dart';
import '../resolved_uri_translator.dart';
import '../serialization/task.dart';
import '../universe/class_hierarchy_builder.dart';
import '../universe/world_builder.dart';
import '../universe/world_impact.dart';
import '../world.dart';
import 'deferred_load.dart';
import 'element_map.dart';
import 'element_map_impl.dart';

/// Front end strategy that loads '.dill' files and builds a resolved element
/// model from kernel IR nodes.
class KernelFrontEndStrategy extends FrontendStrategyBase {
  CompilerOptions _options;
  KernelToElementMapForImpactImpl _elementMap;

  KernelAnnotationProcessor _annotationProcesser;

  final Map<MemberEntity, ScopeModel> closureModels =
      <MemberEntity, ScopeModel>{};

  KernelFrontEndStrategy(
      this._options, DiagnosticReporter reporter, env.Environment environment) {
    _elementMap = new KernelToElementMapForImpactImpl(
        reporter, environment, this, _options);
  }

  @override
  LibraryLoaderTask createLibraryLoader(
      ResolvedUriTranslator uriTranslator,
      ScriptLoader scriptLoader,
      api.CompilerInput compilerInput,
      ElementScanner scriptScanner,
      LibraryDeserializer deserializer,
      PatchResolverFunction patchResolverFunc,
      PatchParserTask patchParser,
      env.Environment environment,
      DiagnosticReporter reporter,
      Measurer measurer) {
    return new KernelLibraryLoaderTask(_options.platformBinaries,
        _options.packageConfig, _elementMap, compilerInput, reporter, measurer,
        verbose: _options.verbose);
  }

  @override
  ElementEnvironment get elementEnvironment => _elementMap.elementEnvironment;

  @override
  CommonElements get commonElements => _elementMap.commonElements;

  DartTypes get dartTypes => _elementMap.types;

  KernelToElementMapForImpact get elementMap => _elementMap;

  @override
  AnnotationProcessor get annotationProcesser => _annotationProcesser ??=
      new KernelAnnotationProcessor(elementMap, nativeBasicDataBuilder);

  @override
  DeferredLoadTask createDeferredLoadTask(Compiler compiler) =>
      new KernelDeferredLoadTask(compiler, _elementMap);

  @override
  NativeClassFinder createNativeClassFinder(NativeBasicData nativeBasicData) {
    return new BaseNativeClassFinder(_elementMap.elementEnvironment,
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

  MirrorsDataBuilder createMirrorsDataBuilder() {
    return new MirrorsDataBuilderImpl(elementEnvironment, commonElements);
  }

  MirrorsResolutionAnalysis createMirrorsResolutionAnalysis(
      JavaScriptBackend backend) {
    return new MirrorsResolutionAnalysisImpl();
  }

  RuntimeTypesNeedBuilder createRuntimeTypesNeedBuilder() {
    return new RuntimeTypesNeedBuilderImpl(
        elementEnvironment, _elementMap.types);
  }

  ResolutionWorldBuilder createResolutionWorldBuilder(
      NativeBasicData nativeBasicData,
      NativeDataBuilder nativeDataBuilder,
      InterceptorDataBuilder interceptorDataBuilder,
      BackendUsageBuilder backendUsageBuilder,
      RuntimeTypesNeedBuilder rtiNeedBuilder,
      NativeResolutionEnqueuer nativeResolutionEnqueuer,
      NoSuchMethodRegistry noSuchMethodRegistry,
      SelectorConstraintsStrategy selectorConstraintsStrategy,
      ClassHierarchyBuilder classHierarchyBuilder,
      ClassQueries classQueries) {
    return new KernelResolutionWorldBuilder(
        _options,
        elementMap,
        nativeBasicData,
        nativeDataBuilder,
        interceptorDataBuilder,
        backendUsageBuilder,
        rtiNeedBuilder,
        nativeResolutionEnqueuer,
        noSuchMethodRegistry,
        selectorConstraintsStrategy,
        classHierarchyBuilder,
        classQueries);
  }

  @override
  WorkItemBuilder createResolutionWorkItemBuilder(
      NativeBasicData nativeBasicData,
      NativeDataBuilder nativeDataBuilder,
      ImpactTransformer impactTransformer,
      Map<Entity, WorldImpact> impactCache) {
    return new KernelWorkItemBuilder(elementMap, nativeBasicData,
        nativeDataBuilder, impactTransformer, closureModels, impactCache);
  }

  ClassQueries createClassQueries() {
    return new KernelClassQueries(elementMap);
  }

  @override
  SourceSpan spanFromSpannable(Spannable spannable, Entity currentElement) {
    return _elementMap.getSourceSpan(spannable, currentElement);
  }
}

class KernelWorkItemBuilder implements WorkItemBuilder {
  final KernelToElementMapForImpactImpl _elementMap;
  final ImpactTransformer _impactTransformer;
  final NativeMemberResolver _nativeMemberResolver;
  final Map<MemberEntity, ScopeModel> closureModels;
  final Map<Entity, WorldImpact> impactCache;

  KernelWorkItemBuilder(
      this._elementMap,
      NativeBasicData nativeBasicData,
      NativeDataBuilder nativeDataBuilder,
      this._impactTransformer,
      this.closureModels,
      this.impactCache)
      : _nativeMemberResolver = new KernelNativeMemberResolver(
            _elementMap, nativeBasicData, nativeDataBuilder);

  @override
  WorkItem createWorkItem(MemberEntity entity) {
    return new KernelWorkItem(_elementMap, _impactTransformer,
        _nativeMemberResolver, entity, closureModels, impactCache);
  }
}

class KernelWorkItem implements ResolutionWorkItem {
  final KernelToElementMapForImpactImpl _elementMap;
  final ImpactTransformer _impactTransformer;
  final NativeMemberResolver _nativeMemberResolver;
  final MemberEntity element;
  final Map<MemberEntity, ScopeModel> closureModels;
  final Map<Entity, WorldImpact> impactCache;

  KernelWorkItem(
      this._elementMap,
      this._impactTransformer,
      this._nativeMemberResolver,
      this.element,
      this.closureModels,
      this.impactCache);

  @override
  WorldImpact run() {
    _nativeMemberResolver.resolveNativeMember(element);
    ResolutionImpact impact = _elementMap.computeWorldImpact(element);
    ScopeModel closureModel = _elementMap.computeScopeModel(element);
    if (closureModel != null) {
      closureModels[element] = closureModel;
    }
    WorldImpact worldImpact =
        _impactTransformer.transformResolutionImpact(impact);
    if (impactCache != null) {
      impactCache[element] = impact;
    }
    return worldImpact;
  }
}

/// Mock implementation of [MirrorsDataImpl].
class MirrorsDataBuilderImpl extends MirrorsDataImpl {
  MirrorsDataBuilderImpl(
      ElementEnvironment elementEnvironment, CommonElements commonElements)
      : super(null, null, elementEnvironment, commonElements);

  @override
  void registerUsedMember(MemberEntity member) {}

  @override
  void computeMembersNeededForReflection(
      ResolutionWorldBuilder worldBuilder, ClosedWorld closedWorld) {
    // TODO(redemption): Support dart:mirrors.
    createImmutableSets();
  }

  @override
  void maybeMarkClosureAsNeededForReflection(ClassEntity closureClass,
      FunctionEntity callMethod, Local localFunction) {}

  @override
  void registerConstSymbol(String name) {}

  @override
  void registerMirrorUsage(
      Set<String> symbols, Set<Element> targets, Set<Element> metaTargets) {}
}

/// Mock implementation of [MirrorsResolutionAnalysis].
class MirrorsResolutionAnalysisImpl implements MirrorsResolutionAnalysis {
  @override
  void onQueueEmpty(Enqueuer enqueuer, Iterable<ClassEntity> recentClasses) {}

  @override
  MirrorsCodegenAnalysis close() {
    // TODO(redemption): Implement this.
    return new MirrorsCodegenAnalysisImpl();
  }

  @override
  void onResolutionComplete() {}
}

class MirrorsCodegenAnalysisImpl implements MirrorsCodegenAnalysis {
  @override
  int get preMirrorsMethodCount {
    // TODO(redemption): Implement this.
    return null;
  }

  @override
  void onQueueEmpty(Enqueuer enqueuer, Iterable<ClassEntity> recentClasses) {
    // TODO(redemption): Implement this.
  }
}
