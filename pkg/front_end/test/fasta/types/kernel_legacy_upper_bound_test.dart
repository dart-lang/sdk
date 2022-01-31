// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "legacy_upper_bound_helper.dart" show LegacyUpperBoundTest;

import "package:kernel/ast.dart" show DartType, InterfaceType, Library;

import "package:kernel/class_hierarchy.dart" show ClassHierarchy;

class KernelLegacyUpperBoundTest extends LegacyUpperBoundTest {
  late ClassHierarchy hierarchy;

  @override
  bool get isNonNullableByDefault => true;

  @override
  Future<void> parseComponent(String source) async {
    await super.parseComponent(source);
    hierarchy = new ClassHierarchy(env.component, env.coreTypes);
  }

  @override
  DartType getLegacyLeastUpperBound(
      DartType a, DartType b, Library clientLibrary) {
    return hierarchy.getLegacyLeastUpperBound(
        a as InterfaceType, b as InterfaceType, clientLibrary);
  }
}

void main() {
  new KernelLegacyUpperBoundTest().test();
}
