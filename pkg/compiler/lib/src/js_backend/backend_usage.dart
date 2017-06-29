// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../common_elements.dart';
import '../elements/elements.dart' show Element;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../util/util.dart' show Setlet;
import 'backend_impact.dart';

abstract class BackendUsage {
  bool needToInitializeIsolateAffinityTag;
  bool needToInitializeDispatchProperty;

  /// Returns `true` if [element] is a function called by the backend.
  bool isFunctionUsedByBackend(FunctionEntity element);

  /// Returns `true` if [element] is an instance field of a class instantiated
  /// by the backend.
  bool isFieldUsedByBackend(FieldEntity element);

  Iterable<FunctionEntity> get globalFunctionDependencies;

  Iterable<ClassEntity> get globalClassDependencies;

  /// `true` if a core-library function requires the preamble file to function.
  bool get requiresPreamble;

  /// `true` if [CommonElements.invokeOnMethod] is used.
  bool get isInvokeOnUsed;

  /// `true` of `Object.runtimeType` is used.
  bool get isRuntimeTypeUsed;

  /// `true` if the `dart:isolate` library is in use.
  bool get isIsolateInUse;

  /// `true` if `Function.apply` is used.
  bool get isFunctionApplyUsed;

  /// `true` if 'dart:mirrors' features are used.
  bool get isMirrorsUsed;

  /// `true` if `noSuchMethod` is used.
  bool get isNoSuchMethodUsed;
}

abstract class BackendUsageBuilder {
  /// The backend must *always* call this method when enqueuing an function
  /// element. Calls done by the backend are not seen by global
  /// optimizations, so they would make these optimizations unsound.
  /// Therefore we need to collect the list of methods the backend may
  /// call.
  // TODO(johnniwinther): Replace this with a more precise modelling; type
  // inference of parameters of these functions is disabled.
  void registerBackendFunctionUse(FunctionEntity element);

  /// The backend must *always* call this method when instantiating a class.
  /// Instantiations done by the backend are not seen by global optimizations,
  /// so they would make these optimizations unsound. Therefore we need to
  /// collect the list of classes the backend may instantiate.
  // TODO(johnniwinther): Replace this with a more precise modelling; type
  // inference of the instance fields of these classes is disabled.
  void registerBackendClassUse(ClassEntity element);

  void registerGlobalFunctionDependency(FunctionEntity element);
  void registerGlobalClassDependency(ClassEntity element);

  /// Collect backend use from [backendImpact].
  void processBackendImpact(BackendImpact backendImpact);

  void registerUsedMember(MemberEntity member);

  /// `true` of `Object.runtimeType` is used.
  bool isRuntimeTypeUsed;

  /// `true` if the `dart:isolate` library is in use.
  bool isIsolateInUse;

  /// `true` if `Function.apply` is used.
  bool isFunctionApplyUsed;

  /// `true` if `noSuchMethod` is used.
  bool isNoSuchMethodUsed;

  BackendUsage close();
}

class BackendUsageBuilderImpl implements BackendUsageBuilder {
  final CommonElements _commonElements;
  // TODO(johnniwinther): Remove the need for these.
  Setlet<FunctionEntity> _globalFunctionDependencies;
  Setlet<ClassEntity> _globalClassDependencies;

  /// List of methods that the backend may use.
  final Set<FunctionEntity> _helperFunctionsUsed = new Set<FunctionEntity>();

  /// List of classes that the backend may use.
  final Set<ClassEntity> _helperClassesUsed = new Set<ClassEntity>();

  bool _needToInitializeIsolateAffinityTag = false;
  bool _needToInitializeDispatchProperty = false;

  /// `true` if a core-library function requires the preamble file to function.
  bool requiresPreamble = false;

  /// `true` if [CommonElements.invokeOnMethod] is used.
  bool isInvokeOnUsed = false;

  /// `true` of `Object.runtimeType` is used.
  bool isRuntimeTypeUsed = false;

  /// `true` if the `dart:isolate` library is in use.
  bool isIsolateInUse = false;

  /// `true` if `Function.apply` is used.
  bool isFunctionApplyUsed = false;

  /// `true` if 'dart:mirrors' features are used.
  bool isMirrorsUsed = false;

  /// `true` if `noSuchMethod` is used.
  bool isNoSuchMethodUsed = false;

  BackendUsageBuilderImpl(this._commonElements);

  @override
  void registerBackendFunctionUse(FunctionEntity element) {
    assert(_isValidBackendUse(element),
        failedAt(element, "Backend use of $element is not allowed."));
    _helperFunctionsUsed.add(element);
  }

  @override
  void registerBackendClassUse(ClassEntity element) {
    assert(_isValidBackendUse(element),
        failedAt(element, "Backend use of $element is not allowed."));
    _helperClassesUsed.add(element);
  }

  bool _isValidBackendUse(Entity element) {
    if (_isValidEntity(element)) return true;
    if (element is Element) {
      assert(element.isDeclaration,
          failedAt(element, "Backend use $element must be the declaration."));
      if (element.implementationLibrary.isPatch ||
          // Needed to detect deserialized injected elements, that is
          // element declared in patch files.
          (element.library.isPlatformLibrary &&
              element.sourcePosition.uri.path
                  .contains('_internal/js_runtime/lib/')) ||
          element.library == _commonElements.jsHelperLibrary ||
          element.library == _commonElements.interceptorsLibrary ||
          element.library == _commonElements.isolateHelperLibrary) {
        // TODO(johnniwinther): We should be more precise about these.
        return true;
      } else {
        return false;
      }
    }
    // TODO(redemption): Support remaining checks on [Entity]s.
    return true;
  }

  bool _isValidEntity(Entity element) {
    if (element is ConstructorEntity &&
        (element == _commonElements.streamIteratorConstructor ||
            _commonElements.isSymbolConstructor(element) ||
            _commonElements.isSymbolValidatedConstructor(element) ||
            element == _commonElements.syncCompleterConstructor)) {
      // TODO(johnniwinther): These are valid but we could be more precise.
      return true;
    } else if (element == _commonElements.symbolImplementationClass ||
        element == _commonElements.objectNoSuchMethod) {
      // TODO(johnniwinther): These are valid but we could be more precise.
      return true;
    } else if (element == _commonElements.listClass ||
        element == _commonElements.mapLiteralClass ||
        element == _commonElements.functionClass ||
        element == _commonElements.stringClass) {
      // TODO(johnniwinther): Avoid these.
      return true;
    } else if (element == _commonElements.genericNoSuchMethod ||
        element == _commonElements.unresolvedConstructorError ||
        element == _commonElements.malformedTypeError) {
      return true;
    }
    return false;
  }

  void _processBackendStaticUse(FunctionEntity element,
      {bool isGlobal: false}) {
    registerBackendFunctionUse(element);
    if (isGlobal) {
      registerGlobalFunctionDependency(element);
    }
  }

  void _processBackendInstantiation(ClassEntity cls, {bool isGlobal: false}) {
    registerBackendClassUse(cls);
    if (isGlobal) {
      registerGlobalClassDependency(cls);
    }
  }

  void processBackendImpact(BackendImpact backendImpact) {
    for (FunctionEntity staticUse in backendImpact.staticUses) {
      assert(staticUse != null);
      _processBackendStaticUse(staticUse);
    }
    for (FunctionEntity staticUse in backendImpact.globalUses) {
      assert(staticUse != null);
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
      requiresPreamble = true;
    } else if (member == _commonElements.invokeOnMethod) {
      isInvokeOnUsed = true;
    } else if (_commonElements.isFunctionApplyMethod(member)) {
      isFunctionApplyUsed = true;
    } else if (member.library == _commonElements.mirrorsLibrary) {
      isMirrorsUsed = true;
    }
  }

  void registerGlobalFunctionDependency(FunctionEntity element) {
    assert(element != null);
    if (_globalFunctionDependencies == null) {
      _globalFunctionDependencies = new Setlet<FunctionEntity>();
    }
    _globalFunctionDependencies.add(element);
  }

  void registerGlobalClassDependency(ClassEntity element) {
    assert(element != null);
    if (_globalClassDependencies == null) {
      _globalClassDependencies = new Setlet<ClassEntity>();
    }
    _globalClassDependencies.add(element);
  }

  BackendUsage close() {
    return new BackendUsageImpl(
        globalFunctionDependencies: _globalFunctionDependencies,
        globalClassDependencies: _globalClassDependencies,
        helperFunctionsUsed: _helperFunctionsUsed,
        helperClassesUsed: _helperClassesUsed,
        needToInitializeIsolateAffinityTag: _needToInitializeIsolateAffinityTag,
        needToInitializeDispatchProperty: _needToInitializeDispatchProperty,
        requiresPreamble: requiresPreamble,
        isInvokeOnUsed: isInvokeOnUsed,
        isRuntimeTypeUsed: isRuntimeTypeUsed,
        isIsolateInUse: isIsolateInUse,
        isFunctionApplyUsed: isFunctionApplyUsed,
        isMirrorsUsed: isMirrorsUsed,
        isNoSuchMethodUsed: isNoSuchMethodUsed);
  }
}

class BackendUsageImpl implements BackendUsage {
  // TODO(johnniwinther): Remove the need for these.
  final Set<FunctionEntity> _globalFunctionDependencies;
  final Set<ClassEntity> _globalClassDependencies;

  /// Set of functions called by the backend.
  final Set<FunctionEntity> _helperFunctionsUsed;

  /// Set of classes instantiated by the backend.
  final Set<ClassEntity> _helperClassesUsed;

  bool needToInitializeIsolateAffinityTag;
  bool needToInitializeDispatchProperty;

  /// `true` if a core-library function requires the preamble file to function.
  final bool requiresPreamble;

  /// `true` if [CommonElements.invokeOnMethod] is used.
  final bool isInvokeOnUsed;

  /// `true` of `Object.runtimeType` is used.
  final bool isRuntimeTypeUsed;

  /// `true` if the `dart:isolate` library is in use.
  final bool isIsolateInUse;

  /// `true` if `Function.apply` is used.
  final bool isFunctionApplyUsed;

  /// `true` if 'dart:mirrors' features are used.
  final bool isMirrorsUsed;

  /// `true` if `noSuchMethod` is used.
  final bool isNoSuchMethodUsed;

  BackendUsageImpl(
      {Set<FunctionEntity> globalFunctionDependencies,
      Set<ClassEntity> globalClassDependencies,
      Set<FunctionEntity> helperFunctionsUsed,
      Set<ClassEntity> helperClassesUsed,
      this.needToInitializeIsolateAffinityTag,
      this.needToInitializeDispatchProperty,
      this.requiresPreamble,
      this.isInvokeOnUsed,
      this.isRuntimeTypeUsed,
      this.isIsolateInUse,
      this.isFunctionApplyUsed,
      this.isMirrorsUsed,
      this.isNoSuchMethodUsed})
      : this._globalFunctionDependencies = globalFunctionDependencies,
        this._globalClassDependencies = globalClassDependencies,
        this._helperFunctionsUsed = helperFunctionsUsed,
        this._helperClassesUsed = helperClassesUsed;

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
      _globalFunctionDependencies ?? const <FunctionEntity>[];

  @override
  Iterable<ClassEntity> get globalClassDependencies =>
      _globalClassDependencies ?? const <ClassEntity>[];

  Iterable<FunctionEntity> get helperFunctionsUsed => _helperFunctionsUsed;

  Iterable<ClassEntity> get helperClassesUsed => _helperClassesUsed;
}
