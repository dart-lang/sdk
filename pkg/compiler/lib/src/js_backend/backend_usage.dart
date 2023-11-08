// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../common/elements.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../ir/runtime_type_analysis.dart';
import '../kernel/kernel_strategy.dart' show KernelFrontendStrategy;
import '../serialization/serialization.dart';
import '../universe/feature.dart';
import '../util/util.dart' show Setlet;
import 'backend_impact.dart';

abstract class BackendUsage {
  /// Deserializes a [BackendUsage] object from [source].
  factory BackendUsage.readFromDataSource(DataSourceReader source) =
      BackendUsageImpl.readFromDataSource;

  /// Serializes this [BackendUsage] to [sink].
  void writeToDataSink(DataSinkWriter sink);

  abstract bool needToInitializeIsolateAffinityTag;
  abstract bool needToInitializeDispatchProperty;

  /// Returns `true` if [element] is a function called by the backend.
  bool isFunctionUsedByBackend(FunctionEntity element);

  /// Returns `true` if [element] is an instance field of a class instantiated
  /// by the backend.
  bool isFieldUsedByBackend(FieldEntity element);

  Iterable<FunctionEntity> get globalFunctionDependencies;

  Iterable<ClassEntity> get globalClassDependencies;

  Iterable<RuntimeTypeUse> get runtimeTypeUses;

  /// `true` if a core-library function requires the preamble file to function.
  bool get requiresPreamble;

  /// `true` of `Object.runtimeType` is used.
  bool get isRuntimeTypeUsed;

  /// `true` if `Function.apply` is used.
  bool get isFunctionApplyUsed;

  /// `true` if startup timestamps are used.
  bool get requiresStartupMetrics;

  /// `true` if `noSuchMethod` is used.
  bool get isNoSuchMethodUsed;

  /// `true` if the `dart:html` is loaded.
  // TODO(johnniwinther): This is always `true` with the CFE.
  bool get isHtmlLoaded;
}

class BackendUsageBuilder {
  final KernelFrontendStrategy _frontendStrategy;
  // TODO(johnniwinther): Remove the need for these.
  Setlet<FunctionEntity>? _globalFunctionDependencies;
  Setlet<ClassEntity>? _globalClassDependencies;

  /// List of methods that the backend may use.
  final Set<FunctionEntity> _helperFunctionsUsed = {};

  /// List of classes that the backend may use.
  final Set<ClassEntity> _helperClassesUsed = {};

  final Set<RuntimeTypeUse> _runtimeTypeUses = {};

  bool _needToInitializeIsolateAffinityTag = false;
  bool _needToInitializeDispatchProperty = false;

  /// `true` if a core-library function requires the preamble file to function.
  bool _requiresPreamble = false;

  /// `true` if a core-library function accesses startup timestamps.
  bool _requiresStartupMetrics = false;

  /// `true` if `Function.apply` is used.
  bool _isFunctionApplyUsed = false;

  /// `true` if `noSuchMethod` is used.
  bool isNoSuchMethodUsed = false;

  bool _isHtmlLoaded = false;

  BackendUsageBuilder(this._frontendStrategy);

  KCommonElements get _commonElements => _frontendStrategy.commonElements;

  /// The backend must *always* call this method when enqueuing an function
  /// element. Calls done by the backend are not seen by global
  /// optimizations, so they would make these optimizations unsound.
  /// Therefore we need to collect the list of methods the backend may
  /// call.
  // TODO(johnniwinther): Replace this with a more precise modelling; type
  // inference of parameters of these functions is disabled.
  void registerBackendFunctionUse(FunctionEntity element) {
    assert(_isValidBackendUse(element, element.library),
        failedAt(element, "Backend use of $element is not allowed."));
    _helperFunctionsUsed.add(element);
  }

  /// The backend must *always* call this method when instantiating a class.
  /// Instantiations done by the backend are not seen by global optimizations,
  /// so they would make these optimizations unsound. Therefore we need to
  /// collect the list of classes the backend may instantiate.
  // TODO(johnniwinther): Replace this with a more precise modelling; type
  // inference of the instance fields of these classes is disabled.
  void registerBackendClassUse(ClassEntity element) {
    assert(_isValidBackendUse(element, element.library),
        failedAt(element, "Backend use of $element is not allowed."));
    _helperClassesUsed.add(element);
  }

  bool _isValidBackendUse(Entity element, LibraryEntity library) {
    if (_isValidEntity(element)) return true;
    SourceSpan span = _frontendStrategy.spanFromSpannable(element, element);
    if (library.canonicalUri.isScheme('dart') &&
        (span.uri.path.contains('_internal/js_runtime/lib') ||
            span.uri.path.contains('_internal/js_shared/lib'))) {
      // TODO(johnniwinther): We should be more precise about these.
      return true;
    } else {
      return false;
    }
  }

  bool _isValidEntity(Entity element) {
    if (element is ConstructorEntity &&
        (element == _commonElements.streamIteratorConstructor ||
            _commonElements.isSymbolConstructor(element))) {
      // TODO(johnniwinther): These are valid but we could be more precise.
      return true;
    } else if (element == _commonElements.symbolImplementationClass ||
        element == _commonElements.objectNoSuchMethod) {
      // TODO(johnniwinther): These are valid but we could be more precise.
      return true;
    } else if (element == _commonElements.listClass ||
        element == _commonElements.mapLiteralClass ||
        element == _commonElements.setLiteralClass ||
        element == _commonElements.unmodifiableSetClass ||
        element == _commonElements.functionClass ||
        element == _commonElements.stringClass) {
      // TODO(johnniwinther): Avoid these.
      return true;
    }
    return false;
  }

  void _processBackendStaticUse(FunctionEntity element,
      {bool isGlobal = false}) {
    registerBackendFunctionUse(element);
    if (isGlobal) {
      registerGlobalFunctionDependency(element);
    }
  }

  void _processBackendInstantiation(ClassEntity cls, {bool isGlobal = false}) {
    registerBackendClassUse(cls);
    if (isGlobal) {
      registerGlobalClassDependency(cls);
    }
  }

  /// Collect backend use from [backendImpact].
  void processBackendImpact(BackendImpact backendImpact) {
    for (FunctionEntity staticUse in backendImpact.staticUses) {
      _processBackendStaticUse(staticUse);
    }
    for (FunctionEntity staticUse in backendImpact.globalUses) {
      _processBackendStaticUse(staticUse, isGlobal: true);
    }
    for (InterfaceType instantiatedType in backendImpact.instantiatedTypes) {
      registerBackendClassUse(instantiatedType.element);
    }
    for (ClassEntity cls in backendImpact.instantiatedClasses) {
      _processBackendInstantiation(cls);
    }
    for (ClassEntity cls in backendImpact.globalClasses) {
      _processBackendInstantiation(cls, isGlobal: true);
    }
    for (BackendImpact otherImpact in backendImpact.otherImpacts) {
      processBackendImpact(otherImpact);
    }
    for (BackendFeature feature in backendImpact.features) {
      switch (feature) {
        case BackendFeature.needToInitializeDispatchProperty:
          _needToInitializeDispatchProperty = true;
          break;
        case BackendFeature.needToInitializeIsolateAffinityTag:
          _needToInitializeIsolateAffinityTag = true;
          break;
      }
    }
  }

  void registerUsedMember(MemberEntity member) {
    if (member == _commonElements.getIsolateAffinityTagMarker) {
      _needToInitializeIsolateAffinityTag = true;
    } else if (member == _commonElements.requiresPreambleMarker) {
      _requiresPreamble = true;
    } else if (_commonElements.isFunctionApplyMethod(member)) {
      _isFunctionApplyUsed = true;
    } else if (member == _commonElements.rawStartupMetrics) {
      _requiresStartupMetrics = true;
    }
  }

  void registerGlobalFunctionDependency(FunctionEntity element) {
    _globalFunctionDependencies ??= Setlet();
    _globalFunctionDependencies!.add(element);
  }

  void registerGlobalClassDependency(ClassEntity element) {
    _globalClassDependencies ??= Setlet();
    _globalClassDependencies!.add(element);
  }

  /// Register use of `runtimeType`.
  void registerRuntimeTypeUse(RuntimeTypeUse runtimeTypeUse) {
    _runtimeTypeUses.add(runtimeTypeUse);
  }

  /// Register that `dart:html` is loaded.
  void registerHtmlIsLoaded() {
    _isHtmlLoaded = true;
  }

  BackendUsage close() {
    return BackendUsageImpl(
        globalFunctionDependencies: _globalFunctionDependencies,
        globalClassDependencies: _globalClassDependencies,
        helperFunctionsUsed: _helperFunctionsUsed,
        helperClassesUsed: _helperClassesUsed,
        needToInitializeIsolateAffinityTag: _needToInitializeIsolateAffinityTag,
        needToInitializeDispatchProperty: _needToInitializeDispatchProperty,
        requiresPreamble: _requiresPreamble,
        requiresStartupMetrics: _requiresStartupMetrics,
        runtimeTypeUses: _runtimeTypeUses,
        isFunctionApplyUsed: _isFunctionApplyUsed,
        isNoSuchMethodUsed: isNoSuchMethodUsed,
        isHtmlLoaded: _isHtmlLoaded);
  }
}

class BackendUsageImpl implements BackendUsage {
  /// Tag used for identifying serialized [BackendUsage] objects in a
  /// debugging data stream.
  static const String tag = 'backend-usage';

  // TODO(johnniwinther): Remove the need for these.
  final Set<FunctionEntity>? _globalFunctionDependencies;
  final Set<ClassEntity>? _globalClassDependencies;

  /// Set of functions called by the backend.
  final Set<FunctionEntity> _helperFunctionsUsed;

  /// Set of classes instantiated by the backend.
  final Set<ClassEntity> _helperClassesUsed;

  final Set<RuntimeTypeUse> _runtimeTypeUses;

  @override
  bool needToInitializeIsolateAffinityTag;
  @override
  bool needToInitializeDispatchProperty;

  @override
  final bool requiresPreamble;

  @override
  final bool requiresStartupMetrics;

  @override
  final bool isFunctionApplyUsed;

  @override
  final bool isNoSuchMethodUsed;

  @override
  final bool isHtmlLoaded;

  BackendUsageImpl(
      {required Set<FunctionEntity>? globalFunctionDependencies,
      required Set<ClassEntity>? globalClassDependencies,
      required Set<FunctionEntity> helperFunctionsUsed,
      required Set<ClassEntity> helperClassesUsed,
      required this.needToInitializeIsolateAffinityTag,
      required this.needToInitializeDispatchProperty,
      required this.requiresPreamble,
      required this.requiresStartupMetrics,
      required Set<RuntimeTypeUse> runtimeTypeUses,
      required this.isFunctionApplyUsed,
      required this.isNoSuchMethodUsed,
      required this.isHtmlLoaded})
      : this._globalFunctionDependencies = globalFunctionDependencies,
        this._globalClassDependencies = globalClassDependencies,
        this._helperFunctionsUsed = helperFunctionsUsed,
        this._helperClassesUsed = helperClassesUsed,
        this._runtimeTypeUses = runtimeTypeUses;

  factory BackendUsageImpl.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    Set<FunctionEntity> globalFunctionDependencies =
        source.readMembers<FunctionEntity>().toSet();
    Set<ClassEntity> globalClassDependencies = source.readClasses().toSet();
    Set<FunctionEntity> helperFunctionsUsed =
        source.readMembers<FunctionEntity>().toSet();
    Set<ClassEntity> helperClassesUsed = source.readClasses().toSet();
    Set<RuntimeTypeUse> runtimeTypeUses = source.readList(() {
      RuntimeTypeUseKind kind = source.readEnum(RuntimeTypeUseKind.values);
      DartType receiverType = source.readDartType();
      DartType? argumentType = source.readDartTypeOrNull();
      return RuntimeTypeUse(kind, receiverType, argumentType);
    }).toSet();
    bool needToInitializeIsolateAffinityTag = source.readBool();
    bool needToInitializeDispatchProperty = source.readBool();
    bool requiresPreamble = source.readBool();
    bool requiresStartupMetrics = source.readBool();
    bool isFunctionApplyUsed = source.readBool();
    bool isNoSuchMethodUsed = source.readBool();
    bool isHtmlLoaded = source.readBool();
    source.end(tag);
    return BackendUsageImpl(
        globalFunctionDependencies: globalFunctionDependencies,
        globalClassDependencies: globalClassDependencies,
        helperFunctionsUsed: helperFunctionsUsed,
        helperClassesUsed: helperClassesUsed,
        runtimeTypeUses: runtimeTypeUses,
        needToInitializeIsolateAffinityTag: needToInitializeIsolateAffinityTag,
        needToInitializeDispatchProperty: needToInitializeDispatchProperty,
        requiresPreamble: requiresPreamble,
        requiresStartupMetrics: requiresStartupMetrics,
        isFunctionApplyUsed: isFunctionApplyUsed,
        isNoSuchMethodUsed: isNoSuchMethodUsed,
        isHtmlLoaded: isHtmlLoaded);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeMembers(_globalFunctionDependencies, allowNull: true);
    sink.writeClasses(_globalClassDependencies, allowNull: true);
    sink.writeMembers(_helperFunctionsUsed);
    sink.writeClasses(_helperClassesUsed);
    sink.writeList(runtimeTypeUses, (RuntimeTypeUse runtimeTypeUse) {
      sink.writeEnum(runtimeTypeUse.kind);
      sink.writeDartType(runtimeTypeUse.receiverType);
      sink.writeDartTypeOrNull(runtimeTypeUse.argumentType);
    });
    sink.writeBool(needToInitializeIsolateAffinityTag);
    sink.writeBool(needToInitializeDispatchProperty);
    sink.writeBool(requiresPreamble);
    sink.writeBool(requiresStartupMetrics);
    sink.writeBool(isFunctionApplyUsed);
    sink.writeBool(isNoSuchMethodUsed);
    sink.writeBool(isHtmlLoaded);
    sink.end(tag);
  }

  @override
  bool isFunctionUsedByBackend(FunctionEntity element) {
    return _helperFunctionsUsed.contains(element);
  }

  @override
  bool isFieldUsedByBackend(FieldEntity element) {
    return _helperClassesUsed.contains(element.enclosingClass);
  }

  @override
  Iterable<FunctionEntity> get globalFunctionDependencies =>
      _globalFunctionDependencies ?? const [];

  @override
  Iterable<ClassEntity> get globalClassDependencies =>
      _globalClassDependencies ?? const [];

  Iterable<FunctionEntity> get helperFunctionsUsed => _helperFunctionsUsed;

  Iterable<ClassEntity> get helperClassesUsed => _helperClassesUsed;

  @override
  bool get isRuntimeTypeUsed => _runtimeTypeUses.isNotEmpty;

  @override
  Iterable<RuntimeTypeUse> get runtimeTypeUses => _runtimeTypeUses;
}
