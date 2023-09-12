// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../messages.dart';
import '../problems.dart';
import '../scope.dart';
import 'builder.dart';
import 'declaration_builders.dart';
import 'field_builder.dart';
import 'library_builder.dart';
import 'member_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

/// Shared implementation between extension and extension type declaration
/// builders.
mixin DeclarationBuilderMixin implements IDeclarationBuilder {
  /// Type parameters declared.
  ///
  /// This is `null` if the declaration is not generic.
  List<TypeVariableBuilder>? get typeParameters;

  /// Lookup a static member of this declaration.
  @override
  Builder? findStaticBuilder(
      String name, int charOffset, Uri fileUri, LibraryBuilder accessingLibrary,
      {bool isSetter = false}) {
    if (accessingLibrary.nameOriginBuilder.origin !=
            libraryBuilder.nameOriginBuilder.origin &&
        name.startsWith("_")) {
      return null;
    }
    Builder? declaration = isSetter
        ? scope.lookupSetter(name, charOffset, fileUri, isInstanceScope: false)
        : scope.lookup(name, charOffset, fileUri, isInstanceScope: false);
    // TODO(johnniwinther): Handle patched extensions/extension type
    //  declarations.
    return declaration;
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
        nullabilityBuilder.build(library),
        buildAliasedTypeArguments(library, arguments, hierarchy),
        typeUse,
        fileUri,
        charOffset,
        hasExplicitTypeArguments: hasExplicitTypeArguments);
  }

  @override
  int get typeVariablesCount => typeParameters?.length ?? 0;

  @override
  List<DartType> buildAliasedTypeArguments(LibraryBuilder library,
      List<TypeBuilder>? arguments, ClassHierarchyBase? hierarchy) {
    if (arguments == null && typeParameters == null) {
      return <DartType>[];
    }

    if (arguments == null && typeParameters != null) {
      List<DartType> result =
          new List<DartType>.generate(typeParameters!.length, (int i) {
        return typeParameters![i].defaultType!.buildAliased(
            library, TypeUse.defaultTypeAsTypeArgument, hierarchy);
      }, growable: true);
      return result;
    }

    if (arguments != null && arguments.length != typeVariablesCount) {
      // That should be caught and reported as a compile-time error earlier.
      return unhandled(
          templateTypeArgumentMismatch
              .withArguments(typeVariablesCount)
              .problemMessage,
          "buildTypeArguments",
          -1,
          null);
    }

    assert(arguments!.length == typeVariablesCount);
    List<DartType> result =
        new List<DartType>.generate(arguments!.length, (int i) {
      return arguments[i]
          .buildAliased(library, TypeUse.typeArgument, hierarchy);
    }, growable: true);
    return result;
  }

  void forEach(void f(String name, Builder builder)) {
    scope
        .filteredNameIterator(
            includeDuplicates: false, includeAugmentations: false)
        .forEach(f);
  }

  @override
  InterfaceType? get thisType => null;

  @override
  Builder? lookupLocalMember(String name,
      {bool setter = false, bool required = false}) {
    // TODO(johnniwinther): Support patching on extensions/extension type
    //  declarations.
    Builder? builder = scope.lookupLocalMember(name, setter: setter);
    if (required && builder == null) {
      internalProblem(
          templateInternalProblemNotFoundIn.withArguments(
              name, fullNameForErrors),
          -1,
          null);
    }
    return builder;
  }

  Builder? lookupLocalMemberByName(Name name,
      {bool setter = false, bool required = false}) {
    Builder? builder =
        lookupLocalMember(name.text, setter: setter, required: required);
    if (builder == null && setter) {
      // When looking up setters, we include assignable fields.
      builder = lookupLocalMember(name.text, setter: false, required: required);
      if (builder is! FieldBuilder || !builder.isAssignable) {
        builder = null;
      }
    }
    if (builder != null) {
      if (name.isPrivate && libraryBuilder.library != name.library) {
        builder = null;
      } else if (builder is FieldBuilder &&
          !builder.isStatic &&
          !builder.isExternal) {
        // Non-external extension instance fields are invalid.
        builder = null;
      } else if (builder.isDuplicate) {
        // Duplicates are not visible in the instance scope.
        builder = null;
      } else if (builder is MemberBuilder && builder.isConflictingSetter) {
        // Conflicting setters are not visible in the instance scope.
        // TODO(johnniwinther): Should we return an [AmbiguousBuilder] here and
        // above?
        builder = null;
      }
    }
    return builder;
  }
}
