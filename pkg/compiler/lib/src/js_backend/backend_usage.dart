// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../common/resolution.dart' show Resolution;
import '../core_types.dart';
import '../elements/elements.dart';
import '../elements/resolution_types.dart';
import '../universe/selector.dart';
import '../universe/use.dart';
import '../universe/world_impact.dart'
    show WorldImpact, WorldImpactBuilder, WorldImpactBuilderImpl;
import '../util/util.dart' show Setlet;
import 'backend_helpers.dart';
import 'backend_impact.dart';

abstract class BackendUsage {
  bool get needToInitializeIsolateAffinityTag;
  bool get needToInitializeDispatchProperty;
  bool usedByBackend(Element element);
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
}

abstract class BackendUsageBuilder {
  Element registerBackendUse(Element element);
  void registerGlobalDependency(Element element);
  void registerBackendImpact(
      WorldImpactBuilder worldImpact, BackendImpact backendImpact);
  void registerBackendStaticUse(
      WorldImpactBuilder worldImpact, MethodElement element,
      {bool isGlobal: false});
  void registerBackendInstantiation(
      WorldImpactBuilder worldImpact, ClassElement cls,
      {bool isGlobal: false});
  WorldImpact createImpactFor(BackendImpact impact);
  void registerUsedMember(MemberElement member);

  /// `true` of `Object.runtimeType` is used.
  bool isRuntimeTypeUsed;

  /// `true` if the `dart:isolate` library is in use.
  bool isIsolateInUse;

  /// `true` if `Function.apply` is used.
  bool isFunctionApplyUsed;
}

class BackendUsageImpl implements BackendUsage, BackendUsageBuilder {
  final CommonElements _commonElements;
  final BackendHelpers _helpers;
  final Resolution _resolution;
  // TODO(johnniwinther): Remove the need for this.
  Setlet<Element> _globalDependencies;

  /// List of elements that the backend may use.
  final Set<Element> _helpersUsed = new Set<Element>();

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

  BackendUsageImpl(this._commonElements, this._helpers, this._resolution);

  bool get needToInitializeIsolateAffinityTag =>
      _needToInitializeIsolateAffinityTag;
  bool get needToInitializeDispatchProperty =>
      _needToInitializeDispatchProperty;

  /// The backend must *always* call this method when enqueuing an
  /// element. Calls done by the backend are not seen by global
  /// optimizations, so they would make these optimizations unsound.
  /// Therefore we need to collect the list of _helpers the backend may
  /// use.
  // TODO(johnniwinther): Replace this with a more precise modelling; type
  // inference of these elements is disabled.
  Element registerBackendUse(Element element) {
    if (element == null) return null;
    assert(invariant(element, _isValidBackendUse(element),
        message: "Backend use of $element is not allowed."));
    _helpersUsed.add(element.declaration);
    if (element.isClass && element.isPatched) {
      // Both declaration and implementation may declare fields, so we
      // add both to the list of _helpers.
      _helpersUsed.add(element.implementation);
    }
    return element;
  }

  bool _isValidBackendUse(Element element) {
    assert(invariant(element, element.isDeclaration, message: ""));
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

  bool usedByBackend(Element element) {
    if (element.isRegularParameter ||
        element.isInitializingFormal ||
        element.isField) {
      if (usedByBackend(element.enclosingElement)) return true;
    }
    return _helpersUsed.contains(element.declaration);
  }

  WorldImpact createImpactFor(BackendImpact impact) {
    WorldImpactBuilderImpl impactBuilder = new WorldImpactBuilderImpl();
    registerBackendImpact(impactBuilder, impact);
    return impactBuilder;
  }

  void registerBackendStaticUse(
      WorldImpactBuilder worldImpact, MethodElement element,
      {bool isGlobal: false}) {
    registerBackendUse(element);
    worldImpact.registerStaticUse(
        // TODO(johnniwinther): Store the correct use in impacts.
        new StaticUse.foreignUse(element));
    if (isGlobal) {
      registerGlobalDependency(element);
    }
  }

  void registerBackendInstantiation(
      WorldImpactBuilder worldImpact, ClassElement cls,
      {bool isGlobal: false}) {
    cls.ensureResolved(_resolution);
    registerBackendUse(cls);
    worldImpact.registerTypeUse(new TypeUse.instantiation(cls.rawType));
    if (isGlobal) {
      registerGlobalDependency(cls);
    }
  }

  void registerBackendImpact(
      WorldImpactBuilder worldImpact, BackendImpact backendImpact) {
    for (Element staticUse in backendImpact.staticUses) {
      assert(staticUse != null);
      registerBackendStaticUse(worldImpact, staticUse);
    }
    for (Element staticUse in backendImpact.globalUses) {
      assert(staticUse != null);
      registerBackendStaticUse(worldImpact, staticUse, isGlobal: true);
    }
    for (Selector selector in backendImpact.dynamicUses) {
      assert(selector != null);
      worldImpact.registerDynamicUse(new DynamicUse(selector, null));
    }
    for (ResolutionInterfaceType instantiatedType
        in backendImpact.instantiatedTypes) {
      registerBackendUse(instantiatedType.element);
      worldImpact.registerTypeUse(new TypeUse.instantiation(instantiatedType));
    }
    for (ClassElement cls in backendImpact.instantiatedClasses) {
      registerBackendInstantiation(worldImpact, cls);
    }
    for (ClassElement cls in backendImpact.globalClasses) {
      registerBackendInstantiation(worldImpact, cls, isGlobal: true);
    }
    for (BackendImpact otherImpact in backendImpact.otherImpacts) {
      registerBackendImpact(worldImpact, otherImpact);
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

  void registerGlobalDependency(Element element) {
    if (element == null) return;
    if (_globalDependencies == null) {
      _globalDependencies = new Setlet<Element>();
    }
    _globalDependencies.add(element.implementation);
  }

  Iterable<Element> get globalDependencies => _globalDependencies;
}
