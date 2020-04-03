// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "legacy_upper_bound_helper.dart" show LegacyUpperBoundTest;

import "package:kernel/ast.dart" show DartType, Library;

import "package:kernel/class_hierarchy.dart" show ClassHierarchy;

import "package:kernel/core_types.dart" show CoreTypes;

class KernelLegacyUpperBoundTest extends LegacyUpperBoundTest {
  ClassHierarchy hierarchy;

  @override
  Future<void> parseComponent(String source) {
    super.parseComponent(source);
    hierarchy = new ClassHierarchy(component, coreTypes);
    return null;
  }

  @override
  DartType getLegacyLeastUpperBound(
      DartType a, DartType b, Library clientLibrary, CoreTypes coreTypes) {
    return hierarchy.getLegacyLeastUpperBound(a, b, clientLibrary, coreTypes);
  }
}

main() {
  new KernelLegacyUpperBoundTest().test();
}
