// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'declaration_builders.dart';

abstract class IDeclarationBuilder implements ITypeDeclarationBuilder {
  Scope get scope;

  LibraryBuilder get libraryBuilder;

  @override
  DeclarationBuilder get origin;

  /// Lookup a member accessed statically through this declaration.
  Builder? findStaticBuilder(
      String name, int charOffset, Uri fileUri, LibraryBuilder accessingLibrary,
      {bool isSetter = false});

  MemberBuilder? findConstructorOrFactory(
      String name, int charOffset, Uri uri, LibraryBuilder accessingLibrary);

  void addProblem(Message message, int charOffset, int length,
      {bool wasHandled = false, List<LocatedMessage>? context});

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
  Builder? lookupLocalMember(String name,
      {bool setter = false, bool required = false});

  ConstructorScope get constructorScope;

  List<DartType> buildAliasedTypeArguments(LibraryBuilder library,
      List<TypeBuilder>? arguments, ClassHierarchyBase? hierarchy);
}

abstract class DeclarationBuilderImpl extends TypeDeclarationBuilderImpl
    implements IDeclarationBuilder {
  @override
  final Scope scope;

  @override
  final ConstructorScope constructorScope;

  @override
  final Uri fileUri;

  DeclarationBuilderImpl(
      List<MetadataBuilder>? metadata,
      int modifiers,
      String name,
      LibraryBuilder parent,
      int charOffset,
      this.scope,
      this.constructorScope)
      : fileUri = parent.fileUri,
        super(metadata, modifiers, name, parent, charOffset);

  @override
  LibraryBuilder get libraryBuilder {
    LibraryBuilder library = parent as LibraryBuilder;
    return library.partOfLibrary ?? library;
  }

  @override
  DeclarationBuilder get origin => this as DeclarationBuilder;

  @override
  MemberBuilder? findConstructorOrFactory(
      String name, int charOffset, Uri uri, LibraryBuilder accessingLibrary) {
    if (accessingLibrary.nameOriginBuilder.origin !=
            libraryBuilder.nameOriginBuilder.origin &&
        name.startsWith("_")) {
      return null;
    }
    MemberBuilder? declaration =
        constructorScope.lookup(name == 'new' ? '' : name, charOffset, uri);
    if (declaration == null && isPatch) {
      return origin.findConstructorOrFactory(
          name, charOffset, uri, accessingLibrary);
    }
    return declaration;
  }

  @override
  void addProblem(Message message, int charOffset, int length,
      {bool wasHandled = false, List<LocatedMessage>? context}) {
    libraryBuilder.addProblem(message, charOffset, length, fileUri,
        wasHandled: wasHandled, context: context);
  }
}
