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

class BackendUsage {
  final CommonElements commonElements;
  final BackendHelpers helpers;
  final Resolution resolution;
  // TODO(johnniwinther): Remove the need for this.
  Setlet<Element> _globalDependencies;

  /// List of elements that the backend may use.
  final Set<Element> helpersUsed = new Set<Element>();

  bool needToInitializeIsolateAffinityTag = false;
  bool needToInitializeDispatchProperty = false;

  BackendUsage(this.commonElements, this.helpers, this.resolution);

  /// The backend must *always* call this method when enqueuing an
  /// element. Calls done by the backend are not seen by global
  /// optimizations, so they would make these optimizations unsound.
  /// Therefore we need to collect the list of helpers the backend may
  /// use.
  // TODO(johnniwinther): Replace this with a more precise modelling; type
  // inference of these elements is disabled.
  Element registerBackendUse(Element element) {
    if (element == null) return null;
    assert(invariant(element, _isValidBackendUse(element),
        message: "Backend use of $element is not allowed."));
    helpersUsed.add(element.declaration);
    if (element.isClass && element.isPatched) {
      // Both declaration and implementation may declare fields, so we
      // add both to the list of helpers.
      helpersUsed.add(element.implementation);
    }
    return element;
  }

  bool _isValidBackendUse(Element element) {
    assert(invariant(element, element.isDeclaration, message: ""));
    if (element is ConstructorElement &&
        (element == helpers.streamIteratorConstructor ||
            commonElements.isSymbolConstructor(element) ||
            helpers.isSymbolValidatedConstructor(element) ||
            element == helpers.syncCompleterConstructor)) {
      // TODO(johnniwinther): These are valid but we could be more precise.
      return true;
    } else if (element == commonElements.symbolClass ||
        element == helpers.objectNoSuchMethod) {
      // TODO(johnniwinther): These are valid but we could be more precise.
      return true;
    } else if (element.implementationLibrary.isPatch ||
        // Needed to detect deserialized injected elements, that is
        // element declared in patch files.
        (element.library.isPlatformLibrary &&
            element.sourcePosition.uri.path
                .contains('_internal/js_runtime/lib/')) ||
        element.library == helpers.jsHelperLibrary ||
        element.library == helpers.interceptorsLibrary ||
        element.library == helpers.isolateHelperLibrary) {
      // TODO(johnniwinther): We should be more precise about these.
      return true;
    } else if (element == commonElements.listClass ||
        element == helpers.mapLiteralClass ||
        element == commonElements.functionClass ||
        element == commonElements.stringClass) {
      // TODO(johnniwinther): Avoid these.
      return true;
    } else if (element == helpers.genericNoSuchMethod ||
        element == helpers.unresolvedConstructorError ||
        element == helpers.malformedTypeError) {
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
    return helpersUsed.contains(element.declaration);
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
    cls.ensureResolved(resolution);
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
          needToInitializeDispatchProperty = true;
          break;
        case BackendFeature.needToInitializeIsolateAffinityTag:
          needToInitializeIsolateAffinityTag = true;
          break;
      }
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
