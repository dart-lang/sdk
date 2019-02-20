// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.frontend_strategy;

import '../common.dart';
import '../common/backend_api.dart';
import '../common/resolution.dart';
import '../common/tasks.dart';
import '../common/work.dart';
import '../common_elements.dart';
import '../compiler.dart';
import '../deferred_load.dart' show DeferredLoadTask;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../enqueue.dart';
import '../environment.dart' as env;
import '../frontend_strategy.dart';
import '../ir/closure.dart' show ClosureScopeModel;
import '../ir/scope.dart' show ScopeModel;
import '../js_backend/annotations.dart';
import '../js_backend/field_analysis.dart' show KFieldAnalysis;
import '../js_backend/backend_usage.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/native_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../js_backend/runtime_types.dart';
import '../native/enqueue.dart' show NativeResolutionEnqueuer;
import '../native/resolver.dart';
import '../options.dart';
import '../universe/class_hierarchy.dart';
import '../universe/resolution_world_builder.dart';
import '../universe/world_builder.dart';
import '../universe/world_impact.dart';
import 'deferred_load.dart';
import 'element_map.dart';
import 'element_map_impl.dart';
import 'loader.dart';

/// Front end strategy that loads '.dill' files and builds a resolved element
/// model from kernel IR nodes.
class KernelFrontEndStrategy extends FrontendStrategyBase {
  CompilerOptions _options;
  CompilerTask _compilerTask;
  KernelToElementMapImpl _elementMap;
  RuntimeTypesNeedBuilder _runtimeTypesNeedBuilder;

  KernelAnnotationProcessor _annotationProcesser;

  final Map<MemberEntity, ClosureScopeModel> closureModels = {};

  KernelFrontEndStrategy(this._compilerTask, this._options,
      DiagnosticReporter reporter, env.Environment environment) {
    assert(_compilerTask != null);
    _elementMap =
        new KernelToElementMapImpl(reporter, environment, this, _options);
  }

  @override
  void registerLoadedLibraries(KernelResult kernelResult) {
    _elementMap.addComponent(kernelResult.component);
  }

  @override
  ElementEnvironment get elementEnvironment => _elementMap.elementEnvironment;

  @override
  CommonElements get commonElements => _elementMap.commonElements;

  DartTypes get dartTypes => _elementMap.types;

  KernelToElementMap get elementMap => _elementMap;

  @override
  AnnotationProcessor get annotationProcesser => _annotationProcesser ??=
      new KernelAnnotationProcessor(elementMap, nativeBasicDataBuilder);

  @override
  DeferredLoadTask createDeferredLoadTask(Compiler compiler) =>
      new KernelDeferredLoadTask(compiler, _elementMap);

  @override
  NativeClassFinder createNativeClassFinder(NativeBasicData nativeBasicData) {
    return new BaseNativeClassFinder(
        _elementMap.elementEnvironment, nativeBasicData);
  }

  NoSuchMethodResolver createNoSuchMethodResolver() {
    return new KernelNoSuchMethodResolver(elementMap);
  }

  /// Computes the main function from [mainLibrary] adding additional world
  /// impact to [impactBuilder].
  FunctionEntity computeMain(WorldImpactBuilder impactBuilder) {
    return elementEnvironment.mainFunction;
  }

  RuntimeTypesNeedBuilder createRuntimeTypesNeedBuilder() {
    return _runtimeTypesNeedBuilder ??= _options.disableRtiOptimization
        ? const TrivialRuntimeTypesNeedBuilder()
        : new RuntimeTypesNeedBuilderImpl(
            elementEnvironment, _elementMap.types);
  }

  RuntimeTypesNeedBuilder get runtimeTypesNeedBuilderForTesting =>
      _runtimeTypesNeedBuilder;

  ResolutionWorldBuilder createResolutionWorldBuilder(
      NativeBasicData nativeBasicData,
      NativeDataBuilder nativeDataBuilder,
      InterceptorDataBuilder interceptorDataBuilder,
      BackendUsageBuilder backendUsageBuilder,
      RuntimeTypesNeedBuilder rtiNeedBuilder,
      KFieldAnalysis allocatorAnalysis,
      NativeResolutionEnqueuer nativeResolutionEnqueuer,
      NoSuchMethodRegistry noSuchMethodRegistry,
      AnnotationsDataBuilder annotationsDataBuilder,
      SelectorConstraintsStrategy selectorConstraintsStrategy,
      ClassHierarchyBuilder classHierarchyBuilder,
      ClassQueries classQueries) {
    return new ResolutionWorldBuilderImpl(
        _options,
        elementMap,
        elementMap.elementEnvironment,
        elementMap.types,
        elementMap.commonElements,
        nativeBasicData,
        nativeDataBuilder,
        interceptorDataBuilder,
        backendUsageBuilder,
        rtiNeedBuilder,
        allocatorAnalysis,
        nativeResolutionEnqueuer,
        noSuchMethodRegistry,
        annotationsDataBuilder,
        selectorConstraintsStrategy,
        classHierarchyBuilder,
        classQueries);
  }

  @override
  WorkItemBuilder createResolutionWorkItemBuilder(
      NativeBasicData nativeBasicData,
      NativeDataBuilder nativeDataBuilder,
      AnnotationsDataBuilder annotationsDataBuilder,
      ImpactTransformer impactTransformer,
      Map<Entity, WorldImpact> impactCache) {
    return new KernelWorkItemBuilder(
        _compilerTask,
        elementMap,
        nativeBasicData,
        nativeDataBuilder,
        annotationsDataBuilder,
        impactTransformer,
        closureModels,
        impactCache);
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
  final CompilerTask _compilerTask;
  final KernelToElementMapImpl _elementMap;
  final ImpactTransformer _impactTransformer;
  final NativeMemberResolver _nativeMemberResolver;
  final AnnotationsDataBuilder _annotationsDataBuilder;
  final Map<MemberEntity, ClosureScopeModel> closureModels;
  final Map<Entity, WorldImpact> impactCache;

  KernelWorkItemBuilder(
      this._compilerTask,
      this._elementMap,
      NativeBasicData nativeBasicData,
      NativeDataBuilder nativeDataBuilder,
      this._annotationsDataBuilder,
      this._impactTransformer,
      this.closureModels,
      this.impactCache)
      : _nativeMemberResolver = new KernelNativeMemberResolver(
            _elementMap, nativeBasicData, nativeDataBuilder);

  @override
  WorkItem createWorkItem(MemberEntity entity) {
    return new KernelWorkItem(
        _compilerTask,
        _elementMap,
        _impactTransformer,
        _nativeMemberResolver,
        _annotationsDataBuilder,
        entity,
        closureModels,
        impactCache);
  }
}

class KernelWorkItem implements WorkItem {
  final CompilerTask _compilerTask;
  final KernelToElementMapImpl _elementMap;
  final ImpactTransformer _impactTransformer;
  final NativeMemberResolver _nativeMemberResolver;
  final AnnotationsDataBuilder _annotationsDataBuilder;
  final MemberEntity element;
  final Map<MemberEntity, ClosureScopeModel> closureModels;
  final Map<Entity, WorldImpact> impactCache;

  KernelWorkItem(
      this._compilerTask,
      this._elementMap,
      this._impactTransformer,
      this._nativeMemberResolver,
      this._annotationsDataBuilder,
      this.element,
      this.closureModels,
      this.impactCache);

  @override
  WorldImpact run() {
    return _compilerTask.measure(() {
      _nativeMemberResolver.resolveNativeMember(element);
      Set<PragmaAnnotation> annotations = processMemberAnnotations(
          _elementMap.reporter,
          _elementMap.commonElements,
          _elementMap.elementEnvironment,
          _annotationsDataBuilder,
          element);
      ScopeModel scopeModel = _compilerTask.measureSubtask('closures', () {
        ScopeModel scopeModel = _elementMap.computeScopeModel(element);
        if (scopeModel?.closureScopeModel != null) {
          closureModels[element] = scopeModel.closureScopeModel;
        }
        return scopeModel;
      });
      return _compilerTask.measureSubtask('worldImpact', () {
        ResolutionImpact impact = _elementMap.computeWorldImpact(
            element, scopeModel?.variableScopeModel, annotations);
        WorldImpact worldImpact =
            _impactTransformer.transformResolutionImpact(impact);
        if (impactCache != null) {
          impactCache[element] = worldImpact;
        }
        return worldImpact;
      });
    });
  }
}
