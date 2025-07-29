// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'declaration_builders.dart';

abstract class IDeclarationBuilder implements ITypeDeclarationBuilder {
  DeclarationNameSpace get nameSpace;

  /// Type parameters declared on this declaration.
  ///
  /// This is `null` if the declaration is not generic.
  List<NominalParameterBuilder>? get typeParameters;

  LibraryBuilder get libraryBuilder;

  @override
  Uri get fileUri;

  /// Lookup a member accessed statically through this declaration.
  MemberLookupResult? findStaticBuilder(String name, int fileOffset,
      Uri fileUri, LibraryBuilder accessingLibrary);

  MemberLookupResult? findConstructorOrFactory(
      String name, LibraryBuilder accessingLibrary);

  /// Returns the type of `this` in an instance of this declaration.
  ///
  /// This is non-null for class and mixin declarations and `null` for
  /// extension declarations.
  InterfaceType? get thisType;

  /// Lookups the member [name] declared in this declaration.
  ///
  /// If [setter] is `true` the sought member is a setter or assignable field.
  /// If [required] is `true` and no member is found an internal problem is
  /// reported.
  LookupResult? lookupLocalMember(String name, {bool required = false});

  List<DartType> buildAliasedTypeArguments(LibraryBuilder library,
      List<TypeBuilder>? arguments, ClassHierarchyBase? hierarchy);

  /// Returns an iterator of all members declared in this declaration, including
  /// duplicate declarations.
  Iterator<MemberBuilder> get unfilteredMembersIterator;

  /// [Iterator] for all members declared in this declaration of type [T].
  ///
  /// If [includeDuplicates] is `true`, duplicate declarations are included.
  Iterator<T> filteredMembersIterator<T extends MemberBuilder>(
      {required bool includeDuplicates});

  /// Returns an iterator of all constructors declared in this declaration,
  /// including duplicate declarations.
  Iterator<MemberBuilder> get unfilteredConstructorsIterator;

  /// [Iterator] for all constructors declared in this declaration of type [T].
  ///
  /// If [includeDuplicates] is `true`, duplicate declarations are included.
  Iterator<T> filteredConstructorsIterator<T extends MemberBuilder>(
      {required bool includeDuplicates});
}

abstract class DeclarationBuilderImpl extends TypeDeclarationBuilderImpl
    implements IDeclarationBuilder {
  @override
  LibraryBuilder get parent;

  @override
  LibraryBuilder get libraryBuilder {
    return parent.partOfLibrary ?? parent;
  }

  @override
  MemberLookupResult? findConstructorOrFactory(
      String name, LibraryBuilder accessingLibrary) {
    if (accessingLibrary.nameOriginBuilder !=
            libraryBuilder.nameOriginBuilder &&
        name.startsWith("_")) {
      return null;
    }
    return nameSpace.lookupConstructor(name == 'new' ? '' : name);
  }
}
