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
