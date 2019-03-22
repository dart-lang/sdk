// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.frontend_strategy;

import 'package:kernel/ast.dart' as ir;

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
import '../ir/annotations.dart';
import '../ir/closure.dart' show ClosureScopeModel;
import '../ir/impact.dart';
import '../ir/modular.dart';
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
import '../util/enumset.dart';
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

  KernelAnnotationProcessor _annotationProcessor;

  final Map<MemberEntity, ClosureScopeModel> closureModels = {};

  ModularStrategy _modularStrategy;
  IrAnnotationData _irAnnotationData;

  KernelFrontEndStrategy(this._compilerTask, this._options,
      DiagnosticReporter reporter, env.Environment environment) {
    assert(_compilerTask != null);
    _elementMap =
        new KernelToElementMapImpl(reporter, environment, this, _options);
    _modularStrategy = new KernelModularStrategy(_compilerTask, _elementMap);
  }

  @override
  void registerLoadedLibraries(KernelResult kernelResult) {
    _elementMap.addComponent(kernelResult.component);
    if (useIrAnnotationsDataForTesting) {
      _irAnnotationData = processAnnotations(kernelResult.component);
    }
    _annotationProcessor = new KernelAnnotationProcessor(
        elementMap, nativeBasicDataBuilder, _irAnnotationData);
  }

  IrAnnotationData get irAnnotationDataForTesting => _irAnnotationData;

  ModularStrategy get modularStrategyForTesting => _modularStrategy;

  @override
  ElementEnvironment get elementEnvironment => _elementMap.elementEnvironment;

  @override
  CommonElements get commonElements => _elementMap.commonElements;

  @override
  DartTypes get dartTypes => _elementMap.types;

  KernelToElementMap get elementMap => _elementMap;

  @override
  AnnotationProcessor get annotationProcessor {
    assert(_annotationProcessor != null,
        "AnnotationProcessor has not been created.");
    return _annotationProcessor;
  }

  @override
  DeferredLoadTask createDeferredLoadTask(Compiler compiler) =>
      new KernelDeferredLoadTask(compiler, _elementMap);

  @override
  NativeClassFinder createNativeClassFinder(NativeBasicData nativeBasicData) {
    return new BaseNativeClassFinder(
        _elementMap.elementEnvironment, nativeBasicData);
  }

  @override
  NoSuchMethodResolver createNoSuchMethodResolver() {
    return new KernelNoSuchMethodResolver(elementMap);
  }

  @override
  FunctionEntity computeMain(WorldImpactBuilder impactBuilder) {
    return elementEnvironment.mainFunction;
  }

  @override
  RuntimeTypesNeedBuilder createRuntimeTypesNeedBuilder() {
    return _runtimeTypesNeedBuilder ??= _options.disableRtiOptimization
        ? const TrivialRuntimeTypesNeedBuilder()
        : new RuntimeTypesNeedBuilderImpl(
            elementEnvironment, _elementMap.types);
  }

  @override
  RuntimeTypesNeedBuilder get runtimeTypesNeedBuilderForTesting =>
      _runtimeTypesNeedBuilder;

  @override
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
      Map<Entity, WorldImpact> impactCache,
      KFieldAnalysis fieldAnalysis) {
    return new KernelWorkItemBuilder(
        _compilerTask,
        elementMap,
        nativeBasicData,
        nativeDataBuilder,
        annotationsDataBuilder,
        impactTransformer,
        closureModels,
        impactCache,
        fieldAnalysis,
        _modularStrategy,
        _irAnnotationData);
  }

  @override
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
  final Map<MemberEntity, ClosureScopeModel> _closureModels;
  final Map<Entity, WorldImpact> _impactCache;
  final KFieldAnalysis _fieldAnalysis;
  final ModularStrategy _modularStrategy;
  final IrAnnotationData _irAnnotationData;

  KernelWorkItemBuilder(
      this._compilerTask,
      this._elementMap,
      NativeBasicData nativeBasicData,
      NativeDataBuilder nativeDataBuilder,
      this._annotationsDataBuilder,
      this._impactTransformer,
      this._closureModels,
      this._impactCache,
      this._fieldAnalysis,
      this._modularStrategy,
      this._irAnnotationData)
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
        _closureModels,
        _impactCache,
        _fieldAnalysis,
        _modularStrategy,
        _irAnnotationData);
  }
}

class KernelWorkItem implements WorkItem {
  final CompilerTask _compilerTask;
  final KernelToElementMapImpl _elementMap;
  final ImpactTransformer _impactTransformer;
  final NativeMemberResolver _nativeMemberResolver;
  final AnnotationsDataBuilder _annotationsDataBuilder;
  @override
  final MemberEntity element;
  final Map<MemberEntity, ClosureScopeModel> _closureModels;
  final Map<Entity, WorldImpact> _impactCache;
  final KFieldAnalysis _fieldAnalysis;
  final ModularStrategy _modularStrategy;
  final IrAnnotationData _irAnnotationData;

  KernelWorkItem(
      this._compilerTask,
      this._elementMap,
      this._impactTransformer,
      this._nativeMemberResolver,
      this._annotationsDataBuilder,
      this.element,
      this._closureModels,
      this._impactCache,
      this._fieldAnalysis,
      this._modularStrategy,
      this._irAnnotationData);

  @override
  WorldImpact run() {
    return _compilerTask.measure(() {
      ir.Member node = _elementMap.getMemberNode(element);
      _nativeMemberResolver.resolveNativeMember(node, _irAnnotationData);

      List<PragmaAnnotationData> pragmaAnnotationData =
          _modularStrategy.getPragmaAnnotationData(node);

      EnumSet<PragmaAnnotation> annotations = processMemberAnnotations(
          _elementMap.options,
          _elementMap.reporter,
          _elementMap.getMemberNode(element),
          pragmaAnnotationData);
      _annotationsDataBuilder.registerPragmaAnnotations(element, annotations);

      ModularMemberData modularMemberData =
          _modularStrategy.getModularMemberData(node, annotations);
      ScopeModel scopeModel = modularMemberData.scopeModel;
      if (scopeModel.closureScopeModel != null) {
        _closureModels[element] = scopeModel.closureScopeModel;
      }
      if (element.isField && !element.isInstanceMember) {
        _fieldAnalysis.registerStaticField(
            element, scopeModel.initializerComplexity);
      }
      ImpactBuilderData impactBuilderData = modularMemberData.impactBuilderData;
      return _compilerTask.measureSubtask('worldImpact', () {
        ResolutionImpact impact = _elementMap.computeWorldImpact(
            element,
            scopeModel.variableScopeModel,
            new Set<PragmaAnnotation>.from(
                annotations.iterable(PragmaAnnotation.values)),
            impactBuilderData: impactBuilderData);
        WorldImpact worldImpact =
            _impactTransformer.transformResolutionImpact(impact);
        if (_impactCache != null) {
          _impactCache[element] = worldImpact;
        }
        return worldImpact;
      });
    });
  }

  @override
  String toString() => 'KernelWorkItem($element)';
}

/// If `true` kernel impacts are computed as [ImpactData] directly on kernel
/// and converted to the K model afterwards. This is a pre-step to modularizing
/// the world impact computation.
bool useImpactDataForTesting = false;

/// If `true` pragma annotations are computed directly on kernel. This is a
/// pre-step to modularizing the world impact computation.
bool useIrAnnotationsDataForTesting = false;

class KernelModularStrategy extends ModularStrategy {
  final CompilerTask _compilerTask;
  final KernelToElementMapImpl _elementMap;

  KernelModularStrategy(this._compilerTask, this._elementMap);

  @override
  List<PragmaAnnotationData> getPragmaAnnotationData(ir.Member node) {
    if (useIrAnnotationsDataForTesting) {
      return computePragmaAnnotationDataFromIr(node);
    } else {
      return computePragmaAnnotationData(_elementMap.commonElements,
          _elementMap.elementEnvironment, _elementMap.getMember(node));
    }
  }

  @override
  ModularMemberData getModularMemberData(
      ir.Member node, EnumSet<PragmaAnnotation> annotations) {
    ScopeModel scopeModel = _compilerTask.measureSubtask('closures',
        () => new ScopeModel.from(node, _elementMap.constantEvaluator));
    ImpactBuilderData impactBuilderData;
    if (useImpactDataForTesting) {
      // TODO(johnniwinther): Always create and use the [ImpactBuilderData].
      // Currently it is a bit half-baked since we cannot compute data that
      // depend on metadata, so these parts of the impact data need to be
      // computed during conversion to [ResolutionImpact].
      impactBuilderData = _compilerTask.measureSubtask('worldImpact', () {
        ImpactBuilder builder = new ImpactBuilder(_elementMap.typeEnvironment,
            _elementMap.classHierarchy, scopeModel.variableScopeModel,
            useAsserts: _elementMap.options.enableUserAssertions,
            inferEffectivelyFinalVariableTypes:
                !annotations.contains(PragmaAnnotation.disableFinal));
        return builder.computeImpact(node);
      });
    }
    return new ModularMemberData(scopeModel, impactBuilderData);
  }
}
