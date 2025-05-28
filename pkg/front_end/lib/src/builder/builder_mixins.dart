// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../base/lookup_result.dart';
import '../base/messages.dart';
import '../base/problems.dart';
import 'builder.dart';
import 'declaration_builders.dart';
import 'library_builder.dart';
import 'member_builder.dart';
import 'nullability_builder.dart';
import 'property_builder.dart';
import 'type_builder.dart';

/// Shared implementation between extension and extension type declaration
/// builders.
mixin DeclarationBuilderMixin implements IDeclarationBuilder {
  /// Lookup a static member of this declaration.
  @override
  LookupResult? findStaticBuilder(String name, int fileOffset, Uri fileUri,
      LibraryBuilder accessingLibrary) {
    if (accessingLibrary.nameOriginBuilder !=
            libraryBuilder.nameOriginBuilder &&
        name.startsWith("_")) {
      return null;
    }
    return nameSpace.lookupLocal(name,
        fileUri: fileUri, fileOffset: fileOffset, staticOnly: true);
  }

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
    return buildAliasedTypeWithBuiltArguments(
        library,
        nullabilityBuilder.build(),
        buildAliasedTypeArguments(library, arguments, hierarchy),
        typeUse,
        fileUri,
        charOffset,
        hasExplicitTypeArguments: hasExplicitTypeArguments);
  }

  @override
  InterfaceType? get thisType => null;

  @override
  NamedBuilder? lookupLocalMember(String name,
      {bool setter = false, bool required = false}) {
    // TODO(johnniwinther): Support augmented on extensions/extension type
    //  declarations.
    LookupResult? result = nameSpace.lookupLocalMember(name);
    NamedBuilder? builder = setter ? result?.setable : result?.getable;
    if (required && builder == null) {
      internalProblem(
          templateInternalProblemNotFoundIn.withArguments(
              name, fullNameForErrors),
          -1,
          null);
    }
    return builder;
  }

  MemberBuilder? lookupLocalMemberByName(Name name,
      {bool setter = false, bool required = false}) {
    NamedBuilder? builder =
        lookupLocalMember(name.text, setter: setter, required: required);
    if (builder == null && setter) {
      // When looking up setters, we include assignable fields.
      builder = lookupLocalMember(name.text, setter: false, required: required);
      if (builder is! PropertyBuilder || !builder.hasSetter) {
        builder = null;
      }
    }
    if (builder != null) {
      if (name.isPrivate && libraryBuilder.library != name.library) {
        builder = null;
      } else if (builder is PropertyBuilder &&
          builder.hasConcreteField &&
          !builder.isStatic) {
        // Non-external extension instance fields are invalid.
        builder = null;
      } else if (builder.isDuplicate) {
        // Duplicates are not visible in the instance scope.
        builder = null;
      }
    }
    return builder as MemberBuilder?;
  }
}
