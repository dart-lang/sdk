// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.class_hierarchy_builder;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/src/standard_bounds.dart';
import 'package:kernel/type_environment.dart';

import '../../builder/class_builder.dart';
import '../../messages.dart' show Message;
import '../../type_inference/standard_bounds.dart'
    show TypeSchemaStandardBounds;
import '../../type_inference/type_constraint_gatherer.dart'
    show TypeConstraintGatherer;
import '../../type_inference/mixin_inferrer.dart' show MixinInferrer;
import '../../type_inference/type_schema_environment.dart' show TypeConstraint;
import 'hierarchy_builder.dart';

class BuilderMixinInferrer extends MixinInferrer {
  final ClassBuilder cls;

  BuilderMixinInferrer(
      this.cls, CoreTypes coreTypes, TypeBuilderConstraintGatherer gatherer)
      : super(coreTypes, gatherer);

  @override
  Supertype? asInstantiationOf(Supertype type, Class superclass) {
    List<DartType>? arguments =
        gatherer.getTypeArgumentsAsInstanceOf(type.asInterfaceType, superclass);
    if (arguments == null) return null;
    return new Supertype(superclass, arguments);
  }

  @override
  void reportProblem(Message message, Class kernelClass) {
    int length = cls.isMixinApplication ? 1 : cls.fullNameForErrors.length;
    cls.addProblem(message, cls.charOffset, length);
  }
}

class TypeBuilderConstraintGatherer extends TypeConstraintGatherer
    with StandardBounds, TypeSchemaStandardBounds {
  @override
  final ClassHierarchyBuilder hierarchy;

  TypeBuilderConstraintGatherer(
      this.hierarchy, Iterable<TypeParameter> typeParameters,
      {required bool isNonNullableByDefault})
      : super.subclassing(typeParameters,
            isNonNullableByDefault: isNonNullableByDefault);

  @override
  CoreTypes get coreTypes => hierarchy.coreTypes;

  @override
  void addLowerBound(TypeConstraint constraint, DartType lower,
      {required bool isNonNullableByDefault}) {
    constraint.lower = getStandardUpperBound(constraint.lower, lower,
        isNonNullableByDefault: isNonNullableByDefault);
  }

  @override
  void addUpperBound(TypeConstraint constraint, DartType upper,
      {required bool isNonNullableByDefault}) {
    constraint.upper = getStandardLowerBound(constraint.upper, upper,
        isNonNullableByDefault: isNonNullableByDefault);
  }

  @override
  Member? getInterfaceMember(Class class_, Name name, {bool setter = false}) {
    return null;
  }

  @override
  InterfaceType getTypeAsInstanceOf(
      InterfaceType type, Class superclass, CoreTypes coreTypes,
      {required bool isNonNullableByDefault}) {
    return hierarchy.getTypeAsInstanceOf(type, superclass,
        isNonNullableByDefault: isNonNullableByDefault);
  }

  @override
  List<DartType>? getTypeArgumentsAsInstanceOf(
      InterfaceType type, Class superclass) {
    return hierarchy.getTypeArgumentsAsInstanceOf(type, superclass);
  }

  @override
  List<DartType>? getExtensionTypeArgumentsAsInstanceOf(
      ExtensionType type, ExtensionTypeDeclaration superclass) {
    return hierarchy
        .getExtensionTypeArgumentsAsInstanceOfExtensionTypeDeclaration(
            type, superclass);
  }

  @override
  InterfaceType futureType(DartType type, Nullability nullability) {
    return new InterfaceType(
        hierarchy.futureClass, nullability, <DartType>[type]);
  }

  @override
  bool isSubtypeOf(
      DartType subtype, DartType supertype, SubtypeCheckMode mode) {
    return hierarchy.types.isSubtypeOf(subtype, supertype, mode);
  }

  @override
  bool areMutualSubtypes(DartType s, DartType t, SubtypeCheckMode mode) {
    return isSubtypeOf(s, t, mode) && isSubtypeOf(t, s, mode);
  }
}
