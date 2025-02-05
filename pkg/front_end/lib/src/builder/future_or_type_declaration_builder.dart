// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' show DartType, FutureOrType, Nullability;
import 'package:kernel/class_hierarchy.dart';

import 'declaration_builders.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

// Coverage-ignore(suite): Not run.
class FutureOrTypeDeclarationBuilder extends BuiltinTypeDeclarationBuilder {
  FutureOrTypeDeclarationBuilder(
      DartType type, LibraryBuilder compilationUnit, int charOffset)
      : super("FutureOr", type, compilationUnit, charOffset);

  @override
  DartType buildAliasedType(
      LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder,
      List<TypeBuilder>? arguments,
      TypeUse typeUse,
      Uri fileUri,
      int charOffset,
      ClassHierarchyBase? hierarchy,
      {required bool hasExplicitTypeArguments}) {
    return new FutureOrType(
        arguments!.single
            .buildAliased(library, TypeUse.typeArgument, hierarchy),
        nullabilityBuilder.build());
  }

  @override
  DartType buildAliasedTypeWithBuiltArguments(
      LibraryBuilder library,
      Nullability nullability,
      List<DartType> arguments,
      TypeUse typeUse,
      Uri fileUri,
      int charOffset,
      {required bool hasExplicitTypeArguments}) {
    return new FutureOrType(arguments.single, nullability);
  }

  @override
  Nullability computeNullabilityWithArguments(List<TypeBuilder>? typeArguments,
      {required Map<TypeParameterBuilder, TraversalState>
          typeParametersTraversalState}) {
    if (typeArguments != null && typeArguments.length == 1) {
      return typeArguments.single.computeNullability(
          typeParametersTraversalState: typeParametersTraversalState);
    } else {
      // This is `FutureOr<dynamic>`.
      return Nullability.nullable;
    }
  }
}
