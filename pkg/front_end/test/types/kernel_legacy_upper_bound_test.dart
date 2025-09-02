// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:kernel/ast.dart" show DartType, InterfaceType;
import "package:kernel/class_hierarchy.dart" show ClassHierarchy;

import "legacy_upper_bound_helper.dart" show LegacyUpperBoundTest;

class KernelLegacyUpperBoundTest extends LegacyUpperBoundTest {
  late ClassHierarchy hierarchy;

  @override
  Future<void> parseComponent(String source) async {
    await super.parseComponent(source);
    hierarchy = new ClassHierarchy(env.component, env.coreTypes);
  }

  @override
  DartType getLegacyLeastUpperBound(DartType a, DartType b) {
    return hierarchy.getLegacyLeastUpperBound(
      a as InterfaceType,
      b as InterfaceType,
    );
  }
}

void main() {
  new KernelLegacyUpperBoundTest().test();
}
