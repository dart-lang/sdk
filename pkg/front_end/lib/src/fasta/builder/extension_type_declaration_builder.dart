// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../scope.dart';
import 'builder.dart';
import 'builder_mixins.dart';
import 'declaration_builder.dart';
import 'library_builder.dart';
import 'metadata_builder.dart';
import 'type_builder.dart';
import 'type_variable_builder.dart';

abstract class ExtensionTypeDeclarationBuilder implements DeclarationBuilder {
  /// Type parameters declared on the extension type declaration.
  ///
  /// This is `null` if the extension type declaration is not generic.
  List<TypeVariableBuilder>? get typeParameters;

  /// The type of the underlying representation.
  DartType get declaredRepresentationType;

  /// The type builder of the underlying representation.
  TypeBuilder? get declaredRepresentationTypeBuilder;

  /// Return the [ExtensionTypeDeclaration] built by this builder.
  ExtensionTypeDeclaration get extensionTypeDeclaration;

  /// Returns a list of the classes and extension types implemented by this
  /// extension type.
  List<TypeBuilder>? get interfaceBuilders;

  /// Looks up extension type member by [name] taking privacy into account.
  ///
  /// If [setter] is `true` the sought member is a setter or assignable field.
  /// If [required] is `true` and no member is found an internal problem is
  /// reported.
  ///
  /// If the extension type member is a duplicate, `null` is returned.
  // TODO(johnniwinther): Support [AmbiguousBuilder] here and in instance
  // member lookup to avoid reporting that the member doesn't exist when it is
  // duplicate.
  Builder? lookupLocalMemberByName(Name name,
      {bool setter = false, bool required = false});

  /// Calls [f] for each member declared in this extension.
  void forEach(void f(String name, Builder builder));

  @override
  Uri get fileUri;
}

abstract class ExtensionTypeDeclarationBuilderImpl
    extends DeclarationBuilderImpl
    with DeclarationBuilderMixin
    implements ExtensionTypeDeclarationBuilder {
  ExtensionTypeDeclarationBuilderImpl(
      List<MetadataBuilder>? metadata,
      int modifiers,
      String name,
      LibraryBuilder parent,
      int charOffset,
      Scope scope,
      ConstructorScope constructorScope)
      : super(metadata, modifiers, name, parent, charOffset, scope,
            constructorScope);

  @override
  DartType buildAliasedTypeWithBuiltArguments(
      LibraryBuilder library,
      Nullability nullability,
      List<DartType> arguments,
      TypeUse typeUse,
      Uri fileUri,
      int charOffset,
      {required bool hasExplicitTypeArguments}) {
    return new ExtensionType(extensionTypeDeclaration, nullability, arguments);
  }

  @override
  String get debugName => "ExtensionTypeDeclarationBuilder";
}
