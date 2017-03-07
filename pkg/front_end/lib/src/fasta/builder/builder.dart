// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.builder;

import '../errors.dart' show internalError;

import '../messages.dart' show nit;

export 'class_builder.dart' show ClassBuilder;

export 'field_builder.dart' show FieldBuilder;

export 'library_builder.dart' show LibraryBuilder;

export 'procedure_builder.dart' show ProcedureBuilder;

export 'type_builder.dart' show TypeBuilder;

export 'formal_parameter_builder.dart' show FormalParameterBuilder;

export 'metadata_builder.dart' show MetadataBuilder;

export 'type_variable_builder.dart' show TypeVariableBuilder;

export 'function_type_alias_builder.dart' show FunctionTypeAliasBuilder;

export 'named_mixin_application_builder.dart' show NamedMixinApplicationBuilder;

export 'mixin_application_builder.dart' show MixinApplicationBuilder;

export 'enum_builder.dart' show EnumBuilder;

export 'type_declaration_builder.dart' show TypeDeclarationBuilder;

export 'named_type_builder.dart' show NamedTypeBuilder;

export 'constructor_reference_builder.dart' show ConstructorReferenceBuilder;

export '../source/unhandled_listener.dart' show Unhandled;

export 'member_builder.dart' show MemberBuilder;

export 'modifier_builder.dart' show ModifierBuilder;

export 'prefix_builder.dart' show PrefixBuilder;

export 'invalid_type_builder.dart' show InvalidTypeBuilder;

export 'mixed_accessor.dart' show MixedAccessor;

export 'scope.dart' show AccessErrorBuilder;

export 'dynamic_type_builder.dart' show DynamicTypeBuilder;

export 'function_type_builder.dart' show FunctionTypeBuilder;

import 'library_builder.dart' show LibraryBuilder;

abstract class Builder {
  /// Used when multiple things with the same name are declared within the same
  /// parent. Only used for declarations, not for scopes.
  ///
  // TODO(ahe): Move to member builder or something. Then we can make
  // this a const class.
  Builder next;

  /// The values of [parent], [charOffset], and [fileUri] aren't stored. We
  /// need to evaluate the memory impact of doing so, but want to ensure the
  /// information is always provided.
  Builder(Builder parent, int charOffset, Uri fileUri);

  int get charOffset => -1;

  Uri get fileUri => null;

  String get relativeFileUri {
    throw "The relativeFileUri method should be only called on subclasses "
        "which have an efficient implementation of `relativeFileUri`!";
  }

  /// Resolve types (lookup names in scope) recorded in this builder and return
  /// the number of types resolved.
  int resolveTypes(covariant Builder parent) => 0;

  /// Resolve constructors (lookup names in scope) recorded in this builder and
  /// return the number of constructors resolved.
  int resolveConstructors(covariant Builder parent) => 0;

  /// This builder and [other] has been imported into [library] using [name].
  ///
  /// This method handles this case according to the Dart language
  /// specification.
  Builder combineAmbiguousImport(
      String name, Builder other, LibraryBuilder library) {
    if (other == this) return this;
    bool isLocal = false;
    Builder preferred;
    Builder hidden;
    if (library.members[name] == this) {
      isLocal = true;
      preferred = this;
      hidden = other;
    } else if (getUri(other)?.scheme == "dart" &&
        getUri(this)?.scheme != "dart") {
      preferred = this;
      hidden = other;
    } else if (getUri(this)?.scheme == "dart" &&
        getUri(other)?.scheme != "dart") {
      preferred = other;
      hidden = this;
    } else {
      nit(
          library.fileUri,
          -1,
          "'$name' is imported from both "
          "'${getUri(this)}' and '${getUri(other)}'.");
      return library.buildAmbiguousBuilder(name, this, other, charOffset);
    }
    if (isLocal) {
      nit(
          library.fileUri,
          -1,
          "Local definition of '$name' hides imported "
          "version from '${getUri(other)}'.");
    } else {
      nit(
          library.fileUri,
          -1,
          "Import of '$name' "
          "(from '${getUri(preferred)}') hides imported version from "
          "'${getUri(hidden)}'.");
    }
    return preferred;
  }

  Builder get parent => null;

  bool get isFinal => false;

  bool get isField => false;

  bool get isRegularMethod => false;

  bool get isGetter => false;

  bool get isSetter => false;

  bool get isInstanceMember => false;

  bool get isStatic => false;

  bool get isTopLevel => false;

  bool get isTypeDeclaration => false;

  bool get isConstructor => false;

  bool get isFactory => false;

  bool get isLocal => false;

  get target => internalError("Unsupported operation $runtimeType.");

  bool get hasProblem => false;

  static Uri getUri(Builder builder) {
    if (builder == null) return internalError("Builder is null.");
    while (builder != null) {
      if (builder is LibraryBuilder) return builder.uri;
      builder = builder.parent;
    }
    return internalError("No library parent.");
  }
}
