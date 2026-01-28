// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../base/lookup_result.dart';
import '../base/problems.dart';
import 'declaration_builders.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

/// Shared implementation between extension and extension type declaration
/// builders.
mixin DeclarationBuilderMixin implements IDeclarationBuilder {
  /// Lookup a static member of this declaration.
  @override
  MemberLookupResult? findStaticBuilder(
    String name,
    int fileOffset,
    Uri fileUri,
    LibraryBuilder accessingLibrary,
  ) {
    if (accessingLibrary.nameOriginBuilder !=
            libraryBuilder.nameOriginBuilder &&
        name.startsWith("_")) {
      return null;
    }
    MemberLookupResult? result = nameSpace.lookup(name);
    if (result != null && !result.isStatic) {
      result = null;
    }
    return result;
  }

  @override
  DartType buildAliasedType(
    LibraryBuilder library,
    NullabilityBuilder nullabilityBuilder,
    List<TypeBuilder>? arguments,
    TypeUse typeUse,
    Uri fileUri,
    int charOffset,
    ClassHierarchyBase? hierarchy, {
    required bool hasExplicitTypeArguments,
  }) {
    return buildAliasedTypeWithBuiltArguments(
      library,
      nullabilityBuilder.build(),
      buildAliasedTypeArguments(library, arguments, hierarchy),
      typeUse,
      fileUri,
      charOffset,
      hasExplicitTypeArguments: hasExplicitTypeArguments,
    );
  }

  @override
  InterfaceType? get thisType => null;

  @override
  MemberLookupResult? lookupLocalMember(String name, {bool required = false}) {
    MemberLookupResult? result = nameSpace.lookup(name);
    if (required && result == null) {
      internalProblem(
        diag.internalProblemNotFoundIn.withArgumentsOld(
          name,
          fullNameForErrors,
        ),
        -1,
        null,
      );
    }
    return result;
  }
}
