// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library kernel.hierarchy_based_type_environment;

import '../ast.dart'
    show Class, DartType, Member, Name, TypeDeclaration, TypeDeclarationType;

import '../class_hierarchy.dart' show ClassHierarchy;

import '../core_types.dart' show CoreTypes;

import '../type_environment.dart' show TypeEnvironment;

class HierarchyBasedTypeEnvironment extends TypeEnvironment {
  @override
  final ClassHierarchy hierarchy;

  HierarchyBasedTypeEnvironment(CoreTypes coreTypes, this.hierarchy)
      : super.fromSubclass(coreTypes, hierarchy);

  @override
  TypeDeclarationType? getTypeAsInstanceOf(TypeDeclarationType type,
      TypeDeclaration typeDeclaration, CoreTypes coreTypes,
      {required bool isNonNullableByDefault}) {
    return hierarchy.getTypeAsInstanceOf(type, typeDeclaration,
        isNonNullableByDefault: isNonNullableByDefault);
  }

  @override
  List<DartType>? getTypeArgumentsAsInstanceOf(
      TypeDeclarationType type, TypeDeclaration typeDeclaration) {
    if (type.typeDeclaration == typeDeclaration) return type.typeArguments;
    return hierarchy.getTypeArgumentsAsInstanceOf(type, typeDeclaration);
  }

  @override
  Member? getInterfaceMember(Class cls, Name name, {bool setter = false}) {
    return hierarchy.getInterfaceMember(cls, name, setter: setter);
  }
}
