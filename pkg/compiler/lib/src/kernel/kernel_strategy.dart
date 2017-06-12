// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.frontend_strategy;

import '../closure.dart';
import '../common.dart';
import '../common_elements.dart';
import '../common/backend_api.dart';
import '../common/resolution.dart';
import '../common/tasks.dart';
import '../common/work.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../environment.dart' as env;
import '../enqueue.dart';
import '../frontend_strategy.dart';
import '../js_backend/backend.dart';
import '../js_backend/backend_usage.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/mirrors_analysis.dart';
import '../js_backend/mirrors_data.dart';
import '../js_backend/native_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../js_backend/runtime_types.dart';
import '../library_loader.dart';
import '../native/resolver.dart';
import '../serialization/task.dart';
import '../patch_parser.dart';
import '../resolved_uri_translator.dart';
import '../universe/world_builder.dart';
import '../universe/world_impact.dart';
import '../world.dart';
import 'element_map_impl.dart';

/// Front end strategy that loads '.dill' files and builds a resolved element
/// model from kernel IR nodes.
class KernelFrontEndStrategy implements FrontendStrategy {
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

  @override
  CommonElements get commonElements => elementMap.commonElements;

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

  MirrorsDataBuilder createMirrorsDataBuilder() {
    return new MirrorsDataBuilderImpl(elementMap.commonElements);
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
  MirrorsDataBuilderImpl(CommonElements commonElements)
      : super(null, null, commonElements);

  @override
  void registerUsedMember(MemberEntity member) {}

  @override
  void computeMembersNeededForReflection(
      ResolutionWorldBuilder worldBuilder, ClosedWorld closedWorld) {
    // TODO(johnniwinther): Support dart:mirrors.
    createImmutableSets();
  }

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

class MirrorsCodegenAnalysisImpl implements MirrorsCodegenAnalysis {
  @override
  int get preMirrorsMethodCount {
    // TODO(johnniwinther): Implement this.
    return null;
  }

  @override
  void onQueueEmpty(Enqueuer enqueuer, Iterable<ClassEntity> recentClasses) {
    // TODO(johnniwinther): Implement this.
  }
}
