// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.universe.world_impact;

import '../dart_types.dart' show
    DartType,
    InterfaceType;
import '../elements/elements.dart' show
    Element,
    LocalFunctionElement,
    MethodElement;
import '../util/util.dart' show
    Setlet;

import 'universe.dart' show
    UniverseSelector;

class WorldImpact {
  const WorldImpact();

  Iterable<UniverseSelector> get dynamicInvocations =>
      const <UniverseSelector>[];
  Iterable<UniverseSelector> get dynamicGetters => const <UniverseSelector>[];
  Iterable<UniverseSelector> get dynamicSetters => const <UniverseSelector>[];

  // TODO(johnniwinther): Split this into more precise subsets.
  Iterable<Element> get staticUses => const <Element>[];

  // TODO(johnniwinther): Replace this by called constructors with type
  // arguments.
  Iterable<InterfaceType> get instantiatedTypes => const <InterfaceType>[];

  // TODO(johnniwinther): Collect checked types for checked mode separately to
  // support serialization.
  Iterable<DartType> get isChecks => const <DartType>[];

  Iterable<DartType> get checkedModeChecks => const <DartType>[];

  Iterable<DartType> get asCasts => const <DartType>[];

  Iterable<MethodElement> get closurizedFunctions => const <MethodElement>[];

  Iterable<LocalFunctionElement> get closures => const <LocalFunctionElement>[];

  Iterable<DartType> get typeLiterals => const <DartType>[];

  String toString() {
    StringBuffer sb = new StringBuffer();

    void add(String title, Iterable iterable) {
      if (iterable.isNotEmpty) {
        sb.write('\n $title:');
        iterable.forEach((e) => sb.write('\n  $e'));
      }
    }

    add('dynamic invocations', dynamicInvocations);
    add('dynamic getters', dynamicGetters);
    add('dynamic setters', dynamicSetters);
    add('static uses', staticUses);
    add('instantiated types', instantiatedTypes);
    add('is-checks', isChecks);
    add('checked-mode checks', checkedModeChecks);
    add('as-casts', asCasts);
    add('closurized functions', closurizedFunctions);
    add('closures', closures);
    add('type literals', typeLiterals);

    return sb.toString();
  }
}

class WorldImpactBuilder {
  // TODO(johnniwinther): Do we benefit from lazy initialization of the
  // [Setlet]s?
  Setlet<UniverseSelector> _dynamicInvocations;
  Setlet<UniverseSelector> _dynamicGetters;
  Setlet<UniverseSelector> _dynamicSetters;
  Setlet<InterfaceType> _instantiatedTypes;
  Setlet<Element> _staticUses;
  Setlet<DartType> _isChecks;
  Setlet<DartType> _asCasts;
  Setlet<DartType> _checkedModeChecks;
  Setlet<MethodElement> _closurizedFunctions;
  Setlet<LocalFunctionElement> _closures;
  Setlet<DartType> _typeLiterals;

  void registerDynamicGetter(UniverseSelector selector) {
    assert(selector != null);
    if (_dynamicGetters == null) {
      _dynamicGetters = new Setlet<UniverseSelector>();
    }
    _dynamicGetters.add(selector);
  }

  Iterable<UniverseSelector> get dynamicGetters {
    return _dynamicGetters != null
        ? _dynamicGetters : const <UniverseSelector>[];
  }

  void registerDynamicInvocation(UniverseSelector selector) {
    assert(selector != null);
    if (_dynamicInvocations == null) {
      _dynamicInvocations = new Setlet<UniverseSelector>();
    }
    _dynamicInvocations.add(selector);
  }

  Iterable<UniverseSelector> get dynamicInvocations {
    return _dynamicInvocations != null
        ? _dynamicInvocations : const <UniverseSelector>[];
  }

  void registerDynamicSetter(UniverseSelector selector) {
    assert(selector != null);
    if (_dynamicSetters == null) {
      _dynamicSetters = new Setlet<UniverseSelector>();
    }
    _dynamicSetters.add(selector);
  }

  Iterable<UniverseSelector> get dynamicSetters {
    return _dynamicSetters != null
        ? _dynamicSetters : const <UniverseSelector>[];
  }

  void registerInstantiatedType(InterfaceType type) {
    assert(type != null);
    if (_instantiatedTypes == null) {
      _instantiatedTypes = new Setlet<InterfaceType>();
    }
    _instantiatedTypes.add(type);
  }

  Iterable<InterfaceType> get instantiatedTypes {
    return _instantiatedTypes != null
        ? _instantiatedTypes : const <InterfaceType>[];
  }

  void registerTypeLiteral(DartType type) {
    assert(type != null);
    if (_typeLiterals == null) {
      _typeLiterals = new Setlet<DartType>();
    }
    _typeLiterals.add(type);
  }

  Iterable<DartType> get typeLiterals {
    return _typeLiterals != null
        ? _typeLiterals : const <DartType>[];
  }

  void registerStaticUse(Element element) {
    assert(element != null);
    if (_staticUses == null) {
      _staticUses = new Setlet<Element>();
    }
    _staticUses.add(element);
  }

  Iterable<Element> get staticUses {
    return _staticUses != null ? _staticUses : const <Element>[];
  }

  void registerIsCheck(DartType type) {
    assert(type != null);
    if (_isChecks == null) {
      _isChecks = new Setlet<DartType>();
    }
    _isChecks.add(type);
  }

  Iterable<DartType> get isChecks {
    return _isChecks != null
        ? _isChecks : const <DartType>[];
  }

  void registerAsCast(DartType type) {
    if (_asCasts == null) {
      _asCasts = new Setlet<DartType>();
    }
    _asCasts.add(type);
  }

  Iterable<DartType> get asCasts {
    return _asCasts != null
        ? _asCasts : const <DartType>[];
  }

  void registerCheckedModeCheckedType(DartType type) {
    if (_checkedModeChecks == null) {
      _checkedModeChecks = new Setlet<DartType>();
    }
    _checkedModeChecks.add(type);
  }

  Iterable<DartType> get checkedModeChecks {
    return _checkedModeChecks != null
        ? _checkedModeChecks : const <DartType>[];
  }

  void registerClosurizedFunction(MethodElement element) {
    if (_closurizedFunctions == null) {
      _closurizedFunctions = new Setlet<MethodElement>();
    }
    _closurizedFunctions.add(element);
  }

  Iterable<MethodElement> get closurizedFunctions {
    return _closurizedFunctions != null
        ? _closurizedFunctions : const <MethodElement>[];
  }

  void registerClosure(LocalFunctionElement element) {
    if (_closures == null) {
      _closures = new Setlet<LocalFunctionElement>();
    }
    _closures.add(element);
  }

  Iterable<LocalFunctionElement> get closures {
    return _closures != null
        ? _closures : const <LocalFunctionElement>[];
  }
}
