// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
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

abstract class ExtensionBuilder implements DeclarationBuilder {
  /// Type parameters declared on the extension.
  ///
  /// This is `null` if the extension is not generic.
  List<TypeVariableBuilder>? get typeParameters;

  /// The type of the on-clause of the extension declaration.
  TypeBuilder get onType;

  /// Return the [Extension] built by this builder.
  Extension get extension;

  /// Looks up extension member by [name] taking privacy into account.
  ///
  /// If [setter] is `true` the sought member is a setter or assignable field.
  /// If [required] is `true` and no member is found an internal problem is
  /// reported.
  ///
  /// If the extension member is a duplicate, `null` is returned.
  // TODO(johnniwinther): Support [AmbiguousBuilder] here and in instance
  // member lookup to avoid reporting that the member doesn't exist when it is
  // duplicate.
  Builder? lookupLocalMemberByName(Name name,
      {bool setter = false, bool required = false});

  /// Calls [f] for each member declared in this extension.
  void forEach(void f(String name, Builder builder));
}

abstract class ExtensionBuilderImpl extends DeclarationBuilderImpl
    with DeclarationBuilderMixin
    implements ExtensionBuilder {
  ExtensionBuilderImpl(List<MetadataBuilder>? metadata, int modifiers,
      String name, LibraryBuilder parent, int charOffset, Scope scope)
      : super(metadata, modifiers, name, parent, charOffset, scope,
            new ConstructorScope(name, const {}));

  @override
  DartType buildAliasedTypeWithBuiltArguments(
      LibraryBuilder library,
      Nullability nullability,
      List<DartType> arguments,
      TypeUse typeUse,
      Uri fileUri,
      int charOffset,
      {required bool hasExplicitTypeArguments}) {
    throw new UnsupportedError("ExtensionBuilder.buildTypesWithBuiltArguments "
        "is not supported in library '${library.importUri}'.");
  }

  @override
  bool get isExtension => true;

  @override
  String get debugName => "ExtensionBuilder";
}
