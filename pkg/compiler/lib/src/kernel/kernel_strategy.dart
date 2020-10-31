// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.frontend_strategy;

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import '../common.dart';
import '../common/backend_api.dart';
import '../common/names.dart' show Uris;
import '../common/resolution.dart';
import '../common/tasks.dart';
import '../common/work.dart';
import '../common_elements.dart';
import '../compiler.dart';
import '../deferred_load.dart' show DeferredLoadTask;
import '../elements/entities.dart';
import '../enqueue.dart';
import '../environment.dart' as env;
import '../frontend_strategy.dart';
import '../ir/annotations.dart';
import '../ir/closure.dart' show ClosureScopeModel;
import '../ir/impact.dart';
import '../ir/modular.dart';
import '../ir/scope.dart' show ScopeModel;
import '../ir/static_type.dart';
import '../js_backend/annotations.dart';
import '../js_backend/backend_impact.dart';
import '../js_backend/backend_usage.dart';
import '../js_backend/custom_elements_analysis.dart';
import '../js_backend/field_analysis.dart' show KFieldAnalysis;
import '../js_backend/impact_transformer.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/native_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../js_backend/resolution_listener.dart';
import '../js_backend/runtime_types_resolution.dart';
import '../kernel/dart2js_target.dart';
import '../native/enqueue.dart' show NativeResolutionEnqueuer;
import '../native/resolver.dart';
import '../options.dart';
import '../universe/class_hierarchy.dart';
import '../universe/resolution_world_builder.dart';
import '../universe/world_builder.dart';
import '../universe/world_impact.dart';
import '../util/enumset.dart';
import 'element_map.dart';
import 'element_map_impl.dart';
import 'loader.dart';

/// Front end strategy that loads '.dill' files and builds a resolved element
/// model from kernel IR nodes.
class KernelFrontendStrategy extends FrontendStrategy {
  final NativeBasicDataBuilderImpl nativeBasicDataBuilder =
      NativeBasicDataBuilderImpl();
  NativeBasicData _nativeBasicData;
  CompilerOptions _options;
  CompilerTask _compilerTask;
  KernelToElementMapImpl _elementMap;
  RuntimeTypesNeedBuilder _runtimeTypesNeedBuilder;

  KernelAnnotationProcessor _annotationProcessor;

  final Map<MemberEntity, ClosureScopeModel> closureModels = {};

  ModularStrategy _modularStrategy;
  IrAnnotationData _irAnnotationData;

  NativeDataBuilderImpl _nativeDataBuilder;
  NativeDataBuilder get nativeDataBuilder => _nativeDataBuilder;

  BackendUsageBuilder _backendUsageBuilder;

  NativeResolutionEnqueuer _nativeResolutionEnqueuer;

  /// Resolution support for generating table of interceptors and
  /// constructors for custom elements.
  CustomElementsResolutionAnalysis _customElementsResolutionAnalysis;

  KFieldAnalysis _fieldAnalysis;

  @override
  NoSuchMethodRegistry noSuchMethodRegistry;

  KernelFrontendStrategy(this._compilerTask, this._options,
      DiagnosticReporter reporter, env.Environment environment) {
    assert(_compilerTask != null);
    _elementMap = KernelToElementMapImpl(reporter, environment, this, _options);
    _modularStrategy = KernelModularStrategy(_compilerTask, _elementMap);
    _backendUsageBuilder = BackendUsageBuilderImpl(this);
    noSuchMethodRegistry = NoSuchMethodRegistryImpl(
        commonElements, KernelNoSuchMethodResolver(_elementMap));
  }

  NativeResolutionEnqueuer get nativeResolutionEnqueuerForTesting =>
      _nativeResolutionEnqueuer;

  KFieldAnalysis get fieldAnalysisForTesting => _fieldAnalysis;

  @override
  void onResolutionStart() {
    // TODO(johnniwinther): Avoid the compiler.elementEnvironment.getThisType
    // calls. Currently needed to ensure resolution of the classes for various
    // queries in native behavior computation, inference and codegen.
    elementEnvironment.getThisType(commonElements.jsArrayClass);
    elementEnvironment.getThisType(commonElements.jsExtendableArrayClass);

    _validateInterceptorImplementsAllObjectMethods(
        commonElements.jsInterceptorClass);
    // The null-interceptor must also implement *all* methods.
    _validateInterceptorImplementsAllObjectMethods(commonElements.jsNullClass);
  }

  void _validateInterceptorImplementsAllObjectMethods(
      ClassEntity interceptorClass) {
    if (interceptorClass == null) return;
    ClassEntity objectClass = commonElements.objectClass;
    elementEnvironment.forEachClassMember(objectClass,
        (_, MemberEntity member) {
      if (!member.isInstanceMember) return;
      MemberEntity interceptorMember = elementEnvironment
          .lookupLocalClassMember(interceptorClass, member.name);
      // Interceptors must override all Object methods due to calling convention
      // differences.
      assert(
          interceptorMember.enclosingClass == interceptorClass,
          failedAt(
              interceptorMember,
              "Member ${member.name} not overridden in ${interceptorClass}. "
              "Found $interceptorMember from "
              "${interceptorMember.enclosingClass}."));
    });
  }

  @override
  ResolutionEnqueuer createResolutionEnqueuer(
      CompilerTask task, Compiler compiler) {
    RuntimeTypesNeedBuilder rtiNeedBuilder = _createRuntimeTypesNeedBuilder();
    BackendImpacts impacts = BackendImpacts(commonElements, compiler.options);
    _nativeResolutionEnqueuer = NativeResolutionEnqueuer(
        compiler.options,
        elementEnvironment,
        commonElements,
        _elementMap.types,
        BaseNativeClassFinder(elementEnvironment, nativeBasicData));
    _nativeDataBuilder = NativeDataBuilderImpl(nativeBasicData);
    _customElementsResolutionAnalysis = CustomElementsResolutionAnalysis(
        elementEnvironment,
        commonElements,
        nativeBasicData,
        _backendUsageBuilder);
    _fieldAnalysis = KFieldAnalysis(this);
    ClassQueries classQueries = KernelClassQueries(elementMap);
    ClassHierarchyBuilder classHierarchyBuilder =
        ClassHierarchyBuilder(commonElements, classQueries);
    AnnotationsDataBuilder annotationsDataBuilder = AnnotationsDataBuilder();
    // TODO(johnniwinther): This is a hack. The annotation data is built while
    // using it. With CFE constants the annotations data can be built fully
    // before creating the resolution enqueuer.
    AnnotationsData annotationsData = AnnotationsDataImpl(
        compiler.options, annotationsDataBuilder.pragmaAnnotations);
    ImpactTransformer impactTransformer = JavaScriptImpactTransformer(
        elementEnvironment,
        commonElements,
        impacts,
        nativeBasicData,
        _nativeResolutionEnqueuer,
        _backendUsageBuilder,
        _customElementsResolutionAnalysis,
        rtiNeedBuilder,
        classHierarchyBuilder,
        annotationsData);
    InterceptorDataBuilder interceptorDataBuilder = InterceptorDataBuilderImpl(
        nativeBasicData, elementEnvironment, commonElements);
    return ResolutionEnqueuer(
        task,
        compiler.reporter,
        ResolutionEnqueuerListener(
            compiler.options,
            elementEnvironment,
            commonElements,
            impacts,
            nativeBasicData,
            interceptorDataBuilder,
            _backendUsageBuilder,
            noSuchMethodRegistry,
            _customElementsResolutionAnalysis,
            _nativeResolutionEnqueuer,
            _fieldAnalysis,
            compiler.deferredLoadTask),
        ResolutionWorldBuilderImpl(
            _options,
            elementMap,
            elementEnvironment,
            _elementMap.types,
            commonElements,
            nativeBasicData,
            nativeDataBuilder,
            interceptorDataBuilder,
            _backendUsageBuilder,
            rtiNeedBuilder,
            _fieldAnalysis,
            _nativeResolutionEnqueuer,
            noSuchMethodRegistry,
            annotationsDataBuilder,
            const StrongModeWorldStrategy(),
            classHierarchyBuilder,
            classQueries),
        KernelWorkItemBuilder(
            _compilerTask,
            elementMap,
            nativeBasicData,
            nativeDataBuilder,
            annotationsDataBuilder,
            impactTransformer,
            closureModels,
            compiler.impactCache,
            _fieldAnalysis,
            _modularStrategy,
            _irAnnotationData),
        annotationsData);
  }

  @override
  void onResolutionEnd() {}

  @override
  NativeBasicData get nativeBasicData {
    if (_nativeBasicData == null) {
      _nativeBasicData = nativeBasicDataBuilder.close(elementEnvironment);
      assert(
          _nativeBasicData != null,
          failedAt(NO_LOCATION_SPANNABLE,
              "NativeBasicData has not been computed yet."));
    }
    return _nativeBasicData;
  }

  @override
  void registerLoadedLibraries(KernelResult kernelResult) {
    _elementMap.addComponent(kernelResult.component);
    _irAnnotationData = processAnnotations(
        ModularCore(kernelResult.component, _elementMap.constantEvaluator));
    _annotationProcessor = KernelAnnotationProcessor(
        elementMap, nativeBasicDataBuilder, _irAnnotationData);
    for (Uri uri in kernelResult.libraries) {
      LibraryEntity library = elementEnvironment.lookupLibrary(uri);
      if (maybeEnableNative(library.canonicalUri)) {
        _annotationProcessor.extractNativeAnnotations(library);
      }
      _annotationProcessor.extractJsInteropAnnotations(library);
      if (uri == Uris.dart_html) {
        _backendUsageBuilder.registerHtmlIsLoaded();
      }
    }
  }

  IrAnnotationData get irAnnotationDataForTesting => _irAnnotationData;

  ModularStrategy get modularStrategyForTesting => _modularStrategy;

  @override
  ElementEnvironment get elementEnvironment => _elementMap.elementEnvironment;

  @override
  CommonElements get commonElements => _elementMap.commonElements;

  KernelToElementMap get elementMap => _elementMap;

  @override
  DeferredLoadTask createDeferredLoadTask(Compiler compiler) =>
      DeferredLoadTask(compiler, _elementMap);

  @override
  FunctionEntity computeMain(WorldImpactBuilder impactBuilder) {
    return elementEnvironment.mainFunction;
  }

  RuntimeTypesNeedBuilder _createRuntimeTypesNeedBuilder() {
    return _runtimeTypesNeedBuilder ??= _options.disableRtiOptimization
        ? const TrivialRuntimeTypesNeedBuilder()
        : RuntimeTypesNeedBuilderImpl(elementEnvironment);
  }

  RuntimeTypesNeedBuilder get runtimeTypesNeedBuilderForTesting =>
      _runtimeTypesNeedBuilder;

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
      : _nativeMemberResolver = KernelNativeMemberResolver(
            _elementMap, nativeBasicData, nativeDataBuilder);

  @override
  WorkItem createWorkItem(MemberEntity entity) {
    return KernelWorkItem(
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
            Set<PragmaAnnotation>.from(
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

class KernelModularStrategy extends ModularStrategy {
  final CompilerTask _compilerTask;
  final KernelToElementMapImpl _elementMap;

  KernelModularStrategy(this._compilerTask, this._elementMap);

  @override
  List<PragmaAnnotationData> getPragmaAnnotationData(ir.Member node) {
    return computePragmaAnnotationDataFromIr(node);
  }

  @override
  ModularMemberData getModularMemberData(
      ir.Member node, EnumSet<PragmaAnnotation> annotations) {
    ScopeModel scopeModel = _compilerTask.measureSubtask(
        'closures', () => ScopeModel.from(node, _elementMap.constantEvaluator));
    ImpactBuilderData impactBuilderData;
    if (useImpactDataForTesting) {
      // TODO(johnniwinther): Always create and use the [ImpactBuilderData].
      // Currently it is a bit half-baked since we cannot compute data that
      // depend on metadata, so these parts of the impact data need to be
      // computed during conversion to [ResolutionImpact].
      impactBuilderData = _compilerTask.measureSubtask('worldImpact', () {
        StaticTypeCacheImpl staticTypeCache = StaticTypeCacheImpl();
        ImpactBuilder builder = ImpactBuilder(
            ir.StaticTypeContext(node, _elementMap.typeEnvironment,
                cache: staticTypeCache),
            staticTypeCache,
            _elementMap.classHierarchy,
            scopeModel.variableScopeModel,
            useAsserts: _elementMap.options.enableUserAssertions,
            inferEffectivelyFinalVariableTypes:
                !annotations.contains(PragmaAnnotation.disableFinal));
        return builder.computeImpact(node);
      });
    }
    return ModularMemberData(scopeModel, impactBuilderData);
  }
}
