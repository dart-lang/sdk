// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.hierarchy_based_type_environment;

import '../ast.dart' show Class, DartType, InterfaceType, Library, Member, Name;

import '../class_hierarchy.dart' show ClassHierarchyBase;

import '../core_types.dart' show CoreTypes;

import '../type_environment.dart' show TypeEnvironment;

class HierarchyBasedTypeEnvironment extends TypeEnvironment {
  final ClassHierarchyBase hierarchy;

  HierarchyBasedTypeEnvironment(CoreTypes coreTypes, this.hierarchy)
      : super.fromSubclass(coreTypes, hierarchy);

  @override
  InterfaceType getTypeAsInstanceOf(InterfaceType type, Class superclass,
      Library clientLibrary, CoreTypes coreTypes) {
    return hierarchy.getTypeAsInstanceOf(type, superclass, clientLibrary);
  }

  @override
  List<DartType> getTypeArgumentsAsInstanceOf(
      InterfaceType type, Class superclass) {
    if (type.classNode == superclass) return type.typeArguments;
    return hierarchy.getTypeArgumentsAsInstanceOf(type, superclass);
  }

  @override
  Member getInterfaceMember(Class cls, Name name, {bool setter: false}) {
    return hierarchy.getInterfaceMember(cls, name, setter: setter);
  }
}
