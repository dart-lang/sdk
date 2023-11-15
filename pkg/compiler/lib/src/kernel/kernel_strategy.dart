// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.frontend_strategy;

import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../common/elements.dart';
import '../common/names.dart' show Uris;
import '../common/tasks.dart';
import '../common/work.dart';
import '../compiler.dart';
import '../deferred_load/deferred_load.dart' show DeferredLoadTask;
import '../elements/entities.dart';
import '../enqueue.dart';
import '../environment.dart' as env;
import '../ir/annotations.dart';
import '../ir/closure.dart' show ClosureScopeModel;
import '../ir/impact.dart';
import '../ir/modular.dart';
import '../ir/scope.dart' show ScopeModel;
import '../js_backend/annotations.dart';
import '../js_backend/backend_impact.dart';
import '../js_backend/backend_usage.dart';
import '../js_backend/custom_elements_analysis.dart';
import '../js_backend/field_analysis.dart' show KFieldAnalysis;
import '../js_backend/interceptor_data.dart';
import '../js_backend/native_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../js_backend/resolution_listener.dart';
import '../js_backend/runtime_types_resolution.dart';
import '../js_model/elements.dart';
import '../kernel/dart2js_target.dart';
import '../kernel/no_such_method_resolver.dart';
import '../native/enqueue.dart' show NativeResolutionEnqueuer;
import '../native/resolver.dart';
import '../options.dart';
import '../resolution/enqueuer.dart';
import '../universe/class_hierarchy.dart';
import '../universe/resolution_world_builder.dart';
import '../universe/world_builder.dart';
import '../universe/world_impact.dart';
import '../util/enumset.dart';
import 'element_map.dart';
import 'element_map_impl.dart';
import 'native_basic_data.dart';

/// Front end strategy that loads '.dill' files and builds a resolved element
/// model from kernel IR nodes.
class KernelFrontendStrategy {
  final CompilerOptions _options;
  final CompilerTask _compilerTask;
  late final KernelToElementMap _elementMap;
  late final RuntimeTypesNeedBuilder _runtimeTypesNeedBuilder =
      _options.disableRtiOptimization
          ? const TrivialRuntimeTypesNeedBuilder()
          : RuntimeTypesNeedBuilderImpl(elementEnvironment);

  RuntimeTypesNeedBuilder get runtimeTypesNeedBuilderForTesting =>
      _runtimeTypesNeedBuilder;

  late KernelAnnotationProcessor _annotationProcessor;

  final Map<MemberEntity, ClosureScopeModel> closureModels = {};

  late ModularStrategy _modularStrategy;
  late IrAnnotationData _irAnnotationData;

  late NativeDataBuilder _nativeDataBuilder;
  NativeDataBuilder get nativeDataBuilder => _nativeDataBuilder;

  late final BackendUsageBuilder _backendUsageBuilder =
      BackendUsageBuilder(this);

  late NativeResolutionEnqueuer _nativeResolutionEnqueuer;

  /// Resolution support for generating table of interceptors and
  /// constructors for custom elements.
  late CustomElementsResolutionAnalysis _customElementsResolutionAnalysis;

  late KFieldAnalysis _fieldAnalysis;

  /// Support for classifying `noSuchMethod` implementations.
  late NoSuchMethodRegistry noSuchMethodRegistry;

  KernelFrontendStrategy(this._compilerTask, this._options,
      DiagnosticReporter reporter, env.Environment environment)
      : _elementMap = KernelToElementMap(reporter, environment, _options) {
    _modularStrategy = KernelModularStrategy(_compilerTask, _elementMap);
    noSuchMethodRegistry =
        NoSuchMethodRegistry(commonElements, NoSuchMethodResolver(_elementMap));
  }

  NativeResolutionEnqueuer get nativeResolutionEnqueuerForTesting =>
      _nativeResolutionEnqueuer;

  KFieldAnalysis get fieldAnalysisForTesting => _fieldAnalysis;

  /// Called before processing of the resolution queue is started.
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
    ClassEntity objectClass = commonElements.objectClass;
    elementEnvironment.forEachClassMember(objectClass,
        (_, MemberEntity member) {
      if (!member.isInstanceMember) return;
      MemberEntity interceptorMember = elementEnvironment
          .lookupLocalClassMember(interceptorClass, member.memberName)!;
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

  ResolutionEnqueuer createResolutionEnqueuer(
      CompilerTask task, Compiler compiler) {
    RuntimeTypesNeedBuilder rtiNeedBuilder = _runtimeTypesNeedBuilder;
    BackendImpacts impacts = BackendImpacts(commonElements, compiler.options);
    final nativeBasicData = _elementMap.nativeBasicData;
    _nativeResolutionEnqueuer = NativeResolutionEnqueuer(
        compiler.options,
        elementEnvironment,
        commonElements,
        _elementMap.types,
        NativeClassFinder(elementEnvironment, nativeBasicData));
    _nativeDataBuilder = NativeDataBuilder(nativeBasicData);
    _customElementsResolutionAnalysis = CustomElementsResolutionAnalysis(
        elementEnvironment,
        commonElements,
        nativeBasicData,
        _backendUsageBuilder);
    _fieldAnalysis = KFieldAnalysis(elementMap);
    ClassHierarchyBuilder classHierarchyBuilder =
        ClassHierarchyBuilder(commonElements, elementMap);
    AnnotationsDataBuilder annotationsDataBuilder = AnnotationsDataBuilder();
    // TODO(johnniwinther): This is a hack. The annotation data is built while
    // using it. With CFE constants the annotations data can be built fully
    // before creating the resolution enqueuer.
    AnnotationsData annotationsData = AnnotationsDataImpl(compiler.options,
        compiler.reporter, annotationsDataBuilder.pragmaAnnotations);
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
        ResolutionWorldBuilder(
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
            classHierarchyBuilder),
        KernelWorkItemBuilder(
            _compilerTask,
            elementMap,
            nativeBasicData,
            nativeDataBuilder,
            annotationsDataBuilder,
            closureModels,
            compiler.impactCache,
            _fieldAnalysis,
            _modularStrategy,
            _irAnnotationData,
            impacts,
            _nativeResolutionEnqueuer,
            _backendUsageBuilder,
            _customElementsResolutionAnalysis,
            rtiNeedBuilder,
            annotationsData),
        annotationsData);
  }

  /// Registers a set of loaded libraries with this strategy.
  void registerLoadedLibraries(ir.Component component, List<Uri> libraries) {
    _elementMap.addComponent(component);
    _irAnnotationData = processAnnotations(
        ModularCore(component, _elementMap.constantEvaluator));
    _annotationProcessor = KernelAnnotationProcessor(
        elementMap, elementMap.nativeBasicDataBuilder, _irAnnotationData);
    for (Uri uri in libraries) {
      LibraryEntity library = elementEnvironment.lookupLibrary(uri)!;
      if (maybeEnableNative(library.canonicalUri)) {
        _annotationProcessor.extractNativeAnnotations(library);
      }
      _annotationProcessor.extractJsInteropAnnotations(library);
      if (uri == Uris.dart_html) {
        _backendUsageBuilder.registerHtmlIsLoaded();
      }
    }
  }

  void registerModuleData(ModuleData? data) {
    if (data == null) {
      _modularStrategy = KernelModularStrategy(_compilerTask, _elementMap);
    } else {
      _modularStrategy =
          DeserializedModularStrategy(_compilerTask, _elementMap, data);
    }
  }

  IrAnnotationData get irAnnotationDataForTesting => _irAnnotationData;

  ModularStrategy get modularStrategyForTesting => _modularStrategy;

  /// Returns the [ElementEnvironment] for the element model used in this
  /// strategy.
  KernelElementEnvironment get elementEnvironment =>
      _elementMap.elementEnvironment;

  /// Returns the [CommonElements] for the element model used in this
  /// strategy.
  KCommonElements get commonElements => _elementMap.commonElements;

  KernelToElementMap get elementMap => _elementMap;

  /// Creates a [DeferredLoadTask] for the element model used in this strategy.
  DeferredLoadTask createDeferredLoadTask(Compiler compiler) =>
      DeferredLoadTask(compiler, _elementMap);

  /// Computes the main function from [mainLibrary] adding additional world
  /// impact to [impactBuilder].
  FunctionEntity? computeMain(WorldImpactBuilder impactBuilder) {
    return elementEnvironment.mainFunction;
  }

  /// Creates a [SourceSpan] from [spannable] in context of [currentElement].
  SourceSpan spanFromSpannable(Spannable spannable, Entity? currentElement) {
    return _elementMap.getSourceSpan(spannable, currentElement);
  }
}

class KernelWorkItemBuilder implements WorkItemBuilder {
  final CompilerTask _compilerTask;
  final KernelToElementMap _elementMap;
  final KernelNativeMemberResolver _nativeMemberResolver;
  final AnnotationsDataBuilder _annotationsDataBuilder;
  final Map<MemberEntity, ClosureScopeModel> _closureModels;
  final Map<Entity, WorldImpact> _impactCache;
  final KFieldAnalysis _fieldAnalysis;
  final ModularStrategy _modularStrategy;
  final IrAnnotationData _irAnnotationData;
  final BackendImpacts _impacts;
  final NativeResolutionEnqueuer _nativeResolutionEnqueuer;
  final BackendUsageBuilder _backendUsageBuilder;
  final CustomElementsResolutionAnalysis _customElementsResolutionAnalysis;
  final RuntimeTypesNeedBuilder _rtiNeedBuilder;
  final AnnotationsData _annotationsData;

  KernelWorkItemBuilder(
      this._compilerTask,
      this._elementMap,
      NativeBasicData nativeBasicData,
      NativeDataBuilder nativeDataBuilder,
      this._annotationsDataBuilder,
      this._closureModels,
      this._impactCache,
      this._fieldAnalysis,
      this._modularStrategy,
      this._irAnnotationData,
      this._impacts,
      this._nativeResolutionEnqueuer,
      this._backendUsageBuilder,
      this._customElementsResolutionAnalysis,
      this._rtiNeedBuilder,
      this._annotationsData)
      : _nativeMemberResolver = KernelNativeMemberResolver(
            _elementMap, nativeBasicData, nativeDataBuilder);

  @override
  WorkItem createWorkItem(MemberEntity entity) {
    return KernelWorkItem(
        _compilerTask,
        _elementMap,
        _nativeMemberResolver,
        _annotationsDataBuilder,
        entity,
        _closureModels,
        _impactCache,
        _fieldAnalysis,
        _modularStrategy,
        _irAnnotationData,
        _impacts,
        _nativeResolutionEnqueuer,
        _backendUsageBuilder,
        _customElementsResolutionAnalysis,
        _rtiNeedBuilder,
        _annotationsData);
  }
}

class KernelWorkItem implements WorkItem {
  final CompilerTask _compilerTask;
  final KernelToElementMap _elementMap;
  final KernelNativeMemberResolver _nativeMemberResolver;
  final AnnotationsDataBuilder _annotationsDataBuilder;
  @override
  final MemberEntity element;
  final Map<MemberEntity, ClosureScopeModel> _closureModels;
  final Map<Entity, WorldImpact> _impactCache;
  final KFieldAnalysis _fieldAnalysis;
  final ModularStrategy _modularStrategy;
  final IrAnnotationData _irAnnotationData;
  final BackendImpacts _impacts;
  final NativeResolutionEnqueuer _nativeResolutionEnqueuer;
  final BackendUsageBuilder _backendUsageBuilder;
  final CustomElementsResolutionAnalysis _customElementsResolutionAnalysis;
  final RuntimeTypesNeedBuilder _rtiNeedBuilder;
  final AnnotationsData _annotationsData;

  KernelWorkItem(
      this._compilerTask,
      this._elementMap,
      this._nativeMemberResolver,
      this._annotationsDataBuilder,
      this.element,
      this._closureModels,
      this._impactCache,
      this._fieldAnalysis,
      this._modularStrategy,
      this._irAnnotationData,
      this._impacts,
      this._nativeResolutionEnqueuer,
      this._backendUsageBuilder,
      this._customElementsResolutionAnalysis,
      this._rtiNeedBuilder,
      this._annotationsData);

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
          node,
          pragmaAnnotationData);
      _annotationsDataBuilder.registerPragmaAnnotations(element, annotations);
      // TODO(sra): Replace the above three statements with a single call to a
      // new API on AnnotationsData that causes the annotations to be parsed and
      // checked.

      ModularMemberData modularMemberData =
          _modularStrategy.getModularMemberData(node, annotations);
      ScopeModel scopeModel = modularMemberData.scopeModel;
      if (scopeModel.closureScopeModel != null) {
        _closureModels[element] = scopeModel.closureScopeModel!;
      }
      if (element is FieldEntity && !element.isInstanceMember) {
        _fieldAnalysis.registerStaticField(
            element as JField, scopeModel.initializerComplexity);
      }
      ImpactBuilderData impactBuilderData = modularMemberData.impactBuilderData;
      return _compilerTask.measureSubtask('worldImpact', () {
        WorldImpact worldImpact = _elementMap.computeWorldImpact(
            element as JMember,
            _impacts,
            _nativeResolutionEnqueuer,
            _backendUsageBuilder,
            _customElementsResolutionAnalysis,
            _rtiNeedBuilder,
            _annotationsData,
            impactBuilderData);
        _impactCache[element] = worldImpact;
        return worldImpact;
      });
    });
  }

  @override
  String toString() => 'KernelWorkItem($element)';
}

class KernelModularStrategy extends ModularStrategy {
  final CompilerTask _compilerTask;
  final KernelToElementMap _elementMap;

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
    return _compilerTask.measureSubtask('worldImpact', () {
      return computeModularMemberData(
          _elementMap, node, scopeModel, annotations);
    });
  }
}

class DeserializedModularStrategy extends ModularStrategy {
  final CompilerTask _compilerTask;
  final KernelToElementMap _elementMap;
  final Map<ir.Member, ImpactBuilderData> _cache = {};

  DeserializedModularStrategy(
      this._compilerTask, this._elementMap, ModuleData data) {
    for (Map<ir.Member, ImpactBuilderData> moduleData
        in data.impactData.values) {
      _cache.addAll(moduleData);
    }
  }

  @override
  List<PragmaAnnotationData> getPragmaAnnotationData(ir.Member node) {
    return computePragmaAnnotationDataFromIr(node);
  }

  @override
  ModularMemberData getModularMemberData(
      ir.Member node, EnumSet<PragmaAnnotation> annotations) {
    // TODO(joshualitt): serialize scope model too.
    var scopeModel = _compilerTask.measureSubtask(
        'closures', () => ScopeModel.from(node, _elementMap.constantEvaluator));
    var impactBuilderData = _cache[node];
    if (impactBuilderData == null) {
      throw 'missing modular analysis data for $node';
    }
    return ModularMemberData(scopeModel, impactBuilderData);
  }
}
