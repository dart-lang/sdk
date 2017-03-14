// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../common_elements.dart';
import '../elements/elements.dart';
import '../elements/resolution_types.dart';
import '../util/util.dart' show Setlet;
import 'backend_helpers.dart';
import 'backend_impact.dart';

abstract class BackendUsage {
  bool needToInitializeIsolateAffinityTag;
  bool needToInitializeDispatchProperty;

  /// Returns `true` if [element] is the parameter of a function called by the
  /// backend.
  bool isParameterUsedByBackend(ParameterElement element);

  /// Returns `true` if [element] is an instance field of a class instantiated
  /// by the backend.
  bool isFieldUsedByBackend(FieldElement element);

  Iterable<Element> get globalDependencies;

  /// `true` if a core-library function requires the preamble file to function.
  bool get requiresPreamble;

  /// `true` if [BackendHelpers.invokeOnMethod] is used.
  bool get isInvokeOnUsed;

  /// `true` of `Object.runtimeType` is used.
  bool get isRuntimeTypeUsed;

  /// `true` if the `dart:isolate` library is in use.
  bool get isIsolateInUse;

  /// `true` if `Function.apply` is used.
  bool get isFunctionApplyUsed;

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
  void registerBackendFunctionUse(MethodElement element);

  /// The backend must *always* call this method when instantiating a class.
  /// Instantiations done by the backend are not seen by global optimizations,
  /// so they would make these optimizations unsound. Therefore we need to
  /// collect the list of classes the backend may instantiate.
  // TODO(johnniwinther): Replace this with a more precise modelling; type
  // inference of the instance fields of these classes is disabled.
  void registerBackendClassUse(ClassElement element);

  void registerGlobalFunctionDependency(MethodElement element);
  void registerGlobalClassDependency(ClassElement element);

  /// Collect backend use from [backendImpact].
  void processBackendImpact(BackendImpact backendImpact);

  void registerUsedMember(MemberElement member);

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
  final ElementEnvironment _elementEnvironment;
  final CommonElements _commonElements;
  final BackendHelpers _helpers;
  // TODO(johnniwinther): Remove the need for this.
  Setlet<Element> _globalDependencies;

  /// List of methods that the backend may use.
  final Set<MethodElement> _helperFunctionsUsed = new Set<MethodElement>();

  /// List of classes that the backend may use.
  final Set<ClassElement> _helperClassesUsed = new Set<ClassElement>();

  bool _needToInitializeIsolateAffinityTag = false;
  bool _needToInitializeDispatchProperty = false;

  /// `true` if a core-library function requires the preamble file to function.
  bool requiresPreamble = false;

  /// `true` if [BackendHelpers.invokeOnMethod] is used.
  bool isInvokeOnUsed = false;

  /// `true` of `Object.runtimeType` is used.
  bool isRuntimeTypeUsed = false;

  /// `true` if the `dart:isolate` library is in use.
  bool isIsolateInUse = false;

  /// `true` if `Function.apply` is used.
  bool isFunctionApplyUsed = false;

  /// `true` if `noSuchMethod` is used.
  bool isNoSuchMethodUsed = false;

  BackendUsageBuilderImpl(
      this._elementEnvironment, this._commonElements, this._helpers);

  @override
  void registerBackendFunctionUse(MethodElement element) {
    assert(invariant(element, element.isDeclaration,
        message: "Backend use $element must be the declaration."));
    assert(invariant(element, _isValidBackendUse(element),
        message: "Backend use of $element is not allowed."));
    _helperFunctionsUsed.add(element);
  }

  @override
  void registerBackendClassUse(ClassElement element) {
    assert(invariant(element, element.isDeclaration,
        message: "Backend use $element must be the declaration."));
    assert(invariant(element, _isValidBackendUse(element),
        message: "Backend use of $element is not allowed."));
    _helperClassesUsed.add(element);
  }

  bool _isValidBackendUse(Element element) {
    assert(invariant(element, element.isDeclaration,
        message: "Element $element must be the declaration."));
    if (element is ConstructorElement &&
        (element == _helpers.streamIteratorConstructor ||
            _commonElements.isSymbolConstructor(element) ||
            _helpers.isSymbolValidatedConstructor(element) ||
            element == _helpers.syncCompleterConstructor)) {
      // TODO(johnniwinther): These are valid but we could be more precise.
      return true;
    } else if (element == _commonElements.symbolClass ||
        element == _helpers.objectNoSuchMethod) {
      // TODO(johnniwinther): These are valid but we could be more precise.
      return true;
    } else if (element.implementationLibrary.isPatch ||
        // Needed to detect deserialized injected elements, that is
        // element declared in patch files.
        (element.library.isPlatformLibrary &&
            element.sourcePosition.uri.path
                .contains('_internal/js_runtime/lib/')) ||
        element.library == _helpers.jsHelperLibrary ||
        element.library == _helpers.interceptorsLibrary ||
        element.library == _helpers.isolateHelperLibrary) {
      // TODO(johnniwinther): We should be more precise about these.
      return true;
    } else if (element == _commonElements.listClass ||
        element == _helpers.mapLiteralClass ||
        element == _commonElements.functionClass ||
        element == _commonElements.stringClass) {
      // TODO(johnniwinther): Avoid these.
      return true;
    } else if (element == _helpers.genericNoSuchMethod ||
        element == _helpers.unresolvedConstructorError ||
        element == _helpers.malformedTypeError) {
      return true;
    }
    return false;
  }

  void _processBackendStaticUse(MethodElement element, {bool isGlobal: false}) {
    registerBackendFunctionUse(element);
    if (isGlobal) {
      registerGlobalFunctionDependency(element);
    }
  }

  void _processBackendInstantiation(ClassElement cls, {bool isGlobal: false}) {
    registerBackendClassUse(cls);
    if (isGlobal) {
      registerGlobalClassDependency(cls);
    }
  }

  void processBackendImpact(BackendImpact backendImpact) {
    for (MethodElement staticUse in backendImpact.staticUses) {
      assert(staticUse != null);
      _processBackendStaticUse(staticUse);
    }
    for (MethodElement staticUse in backendImpact.globalUses) {
      assert(staticUse != null);
      _processBackendStaticUse(staticUse, isGlobal: true);
    }
    for (ResolutionInterfaceType instantiatedType
        in backendImpact.instantiatedTypes) {
      registerBackendClassUse(instantiatedType.element);
    }
    for (ClassElement cls in backendImpact.instantiatedClasses) {
      _processBackendInstantiation(cls);
    }
    for (ClassElement cls in backendImpact.globalClasses) {
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

  void registerUsedMember(MemberElement member) {
    if (member == _helpers.getIsolateAffinityTagMarker) {
      _needToInitializeIsolateAffinityTag = true;
    } else if (member == _helpers.requiresPreambleMarker) {
      requiresPreamble = true;
    } else if (member == _helpers.invokeOnMethod) {
      isInvokeOnUsed = true;
    } else if (_commonElements.isFunctionApplyMethod(member)) {
      isFunctionApplyUsed = true;
    }
  }

  void registerGlobalFunctionDependency(MethodElement element) {
    _registerGlobalDependency(element);
  }

  void registerGlobalClassDependency(ClassElement element) {
    _registerGlobalDependency(element);
  }

  void _registerGlobalDependency(Element element) {
    if (element == null) return;
    if (_globalDependencies == null) {
      _globalDependencies = new Setlet<Element>();
    }
    _globalDependencies.add(element.implementation);
  }

  BackendUsage close() {
    return new BackendUsageImpl(
        globalDependencies: _globalDependencies,
        helperFunctionsUsed: _helperFunctionsUsed,
        helperClassesUsed: _helperClassesUsed,
        needToInitializeIsolateAffinityTag: _needToInitializeIsolateAffinityTag,
        needToInitializeDispatchProperty: _needToInitializeDispatchProperty,
        requiresPreamble: requiresPreamble,
        isInvokeOnUsed: isInvokeOnUsed,
        isRuntimeTypeUsed: isRuntimeTypeUsed,
        isIsolateInUse: isIsolateInUse,
        isFunctionApplyUsed: isFunctionApplyUsed,
        isNoSuchMethodUsed: isNoSuchMethodUsed);
  }
}

class BackendUsageImpl implements BackendUsage {
  // TODO(johnniwinther): Remove the need for this.
  final Set<Element> _globalDependencies;

  /// Set of functions called by the backend.
  final Set<Element> _helperFunctionsUsed;

  /// Set of classes instantiated by the backend.
  final Set<Element> _helperClassesUsed;

  bool needToInitializeIsolateAffinityTag;
  bool needToInitializeDispatchProperty;

  /// `true` if a core-library function requires the preamble file to function.
  final bool requiresPreamble;

  /// `true` if [BackendHelpers.invokeOnMethod] is used.
  final bool isInvokeOnUsed;

  /// `true` of `Object.runtimeType` is used.
  final bool isRuntimeTypeUsed;

  /// `true` if the `dart:isolate` library is in use.
  final bool isIsolateInUse;

  /// `true` if `Function.apply` is used.
  final bool isFunctionApplyUsed;

  /// `true` if `noSuchMethod` is used.
  final bool isNoSuchMethodUsed;

  BackendUsageImpl(
      {Set<Element> globalDependencies,
      Set<MethodElement> helperFunctionsUsed,
      Set<ClassElement> helperClassesUsed,
      this.needToInitializeIsolateAffinityTag,
      this.needToInitializeDispatchProperty,
      this.requiresPreamble,
      this.isInvokeOnUsed,
      this.isRuntimeTypeUsed,
      this.isIsolateInUse,
      this.isFunctionApplyUsed,
      this.isNoSuchMethodUsed})
      : this._globalDependencies = globalDependencies,
        this._helperFunctionsUsed = helperFunctionsUsed,
        this._helperClassesUsed = helperClassesUsed;

  @override
  bool isParameterUsedByBackend(ParameterElement element) {
    return _helperFunctionsUsed.contains(element.functionDeclaration);
  }

  @override
  bool isFieldUsedByBackend(FieldElement element) {
    return _helperClassesUsed.contains(element.enclosingClass);
  }

  Iterable<Element> get globalDependencies => _globalDependencies;
}
