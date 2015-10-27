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

  Iterable<DartType> get onCatchTypes => const <DartType>[];

  Iterable<MethodElement> get closurizedFunctions => const <MethodElement>[];

  Iterable<LocalFunctionElement> get closures => const <LocalFunctionElement>[];

  Iterable<DartType> get typeLiterals => const <DartType>[];

  String toString() => dump(this);

  static String dump(WorldImpact worldImpact) {
    StringBuffer sb = new StringBuffer();
    printOn(sb, worldImpact);
    return sb.toString();
  }

  static void printOn(StringBuffer sb, WorldImpact worldImpact) {
    void add(String title, Iterable iterable) {
      if (iterable.isNotEmpty) {
        sb.write('\n $title:');
        iterable.forEach((e) => sb.write('\n  $e'));
      }
    }

    add('dynamic invocations', worldImpact.dynamicInvocations);
    add('dynamic getters', worldImpact.dynamicGetters);
    add('dynamic setters', worldImpact.dynamicSetters);
    add('static uses', worldImpact.staticUses);
    add('instantiated types', worldImpact.instantiatedTypes);
    add('is-checks', worldImpact.isChecks);
    add('checked-mode checks', worldImpact.checkedModeChecks);
    add('as-casts', worldImpact.asCasts);
    add('on-catch-types', worldImpact.onCatchTypes);
    add('closurized functions', worldImpact.closurizedFunctions);
    add('closures', worldImpact.closures);
    add('type literals', worldImpact.typeLiterals);
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
  Setlet<DartType> _onCatchTypes;
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

  void registerOnCatchType(DartType type) {
    assert(type != null);
    if (_onCatchTypes == null) {
      _onCatchTypes = new Setlet<DartType>();
    }
    _onCatchTypes.add(type);
  }

  Iterable<DartType> get onCatchTypes {
    return _onCatchTypes != null
        ? _onCatchTypes : const <DartType>[];
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

/// Mutable implementation of [WorldImpact] used to transform
/// [ResolutionImpact] or [CodegenImpact] to [WorldImpact].
class TransformedWorldImpact implements WorldImpact {
  final WorldImpact worldImpact;

  Setlet<Element> _staticUses;
  Setlet<InterfaceType> _instantiatedTypes;
  Setlet<UniverseSelector> _dynamicGetters;
  Setlet<UniverseSelector> _dynamicInvocations;
  Setlet<UniverseSelector> _dynamicSetters;

  TransformedWorldImpact(this.worldImpact);

  @override
  Iterable<DartType> get asCasts => worldImpact.asCasts;

  @override
  Iterable<DartType> get checkedModeChecks => worldImpact.checkedModeChecks;

  @override
  Iterable<MethodElement> get closurizedFunctions {
    return worldImpact.closurizedFunctions;
  }

  @override
  Iterable<UniverseSelector> get dynamicGetters {
    return _dynamicGetters != null
        ? _dynamicGetters : worldImpact.dynamicGetters;
  }

  @override
  Iterable<UniverseSelector> get dynamicInvocations {
    return _dynamicInvocations != null
        ? _dynamicInvocations : worldImpact.dynamicInvocations;
  }

  @override
  Iterable<UniverseSelector> get dynamicSetters {
    return _dynamicSetters != null
        ? _dynamicSetters : worldImpact.dynamicSetters;
  }

  @override
  Iterable<DartType> get isChecks => worldImpact.isChecks;

  @override
  Iterable<DartType> get onCatchTypes => worldImpact.onCatchTypes;

  _unsupported(String message) => throw new UnsupportedError(message);

  void registerDynamicGetter(UniverseSelector selector) {
    if (_dynamicGetters == null) {
      _dynamicGetters = new Setlet<UniverseSelector>();
      _dynamicGetters.addAll(worldImpact.dynamicGetters);
    }
    _dynamicGetters.add(selector);
  }

  void registerDynamicInvocation(UniverseSelector selector) {
    if (_dynamicInvocations == null) {
      _dynamicInvocations = new Setlet<UniverseSelector>();
      _dynamicInvocations.addAll(worldImpact.dynamicInvocations);
    }
    _dynamicInvocations.add(selector);
  }

  void registerDynamicSetter(UniverseSelector selector) {
    if (_dynamicSetters == null) {
      _dynamicSetters = new Setlet<UniverseSelector>();
      _dynamicSetters.addAll(worldImpact.dynamicSetters);
    }
    _dynamicSetters.add(selector);
  }

  void registerInstantiatedType(InterfaceType type) {
    if (_instantiatedTypes == null) {
      _instantiatedTypes = new Setlet<InterfaceType>();
      _instantiatedTypes.addAll(worldImpact.instantiatedTypes);
    }
    _instantiatedTypes.add(type);
  }

  @override
  Iterable<InterfaceType> get instantiatedTypes {
    return _instantiatedTypes != null
        ? _instantiatedTypes : worldImpact.instantiatedTypes;
  }

  @override
  Iterable<DartType> get typeLiterals {
    return worldImpact.typeLiterals;
  }

  void registerStaticUse(Element element) {
    if (_staticUses == null) {
      _staticUses = new Setlet<Element>();
      _staticUses.addAll(worldImpact.staticUses);
    }
    _staticUses.add(element);
  }

  @override
  Iterable<Element> get staticUses {
    return _staticUses != null ? _staticUses : worldImpact.staticUses;
  }

  @override
  Iterable<LocalFunctionElement> get closures => worldImpact.closures;

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('TransformedWorldImpact($worldImpact)');
    WorldImpact.printOn(sb, this);
    return sb.toString();
  }
}
