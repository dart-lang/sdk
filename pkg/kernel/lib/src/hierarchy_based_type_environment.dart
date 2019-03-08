// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.hierarchy_based_type_environment;

import '../ast.dart' show Class, InterfaceType;

import '../class_hierarchy.dart' show ClassHierarchy;

import '../core_types.dart' show CoreTypes;

import '../type_environment.dart' show TypeEnvironment;

class HierarchyBasedTypeEnvironment extends TypeEnvironment {
  final ClassHierarchy hierarchy;

  HierarchyBasedTypeEnvironment(CoreTypes coreTypes, this.hierarchy)
      : super.fromSubclass(coreTypes);

  @override
  InterfaceType getTypeAsInstanceOf(InterfaceType type, Class superclass) {
    return hierarchy.getTypeAsInstanceOf(type, superclass);
  }
}
