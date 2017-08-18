// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.builder;

import '../problems.dart' show unhandled, unsupported;

export 'class_builder.dart' show ClassBuilder;

export 'field_builder.dart' show FieldBuilder;

export 'library_builder.dart' show LibraryBuilder;

export 'procedure_builder.dart' show ProcedureBuilder;

export 'type_builder.dart' show TypeBuilder;

export 'formal_parameter_builder.dart' show FormalParameterBuilder;

export 'metadata_builder.dart' show MetadataBuilder;

export 'type_variable_builder.dart' show TypeVariableBuilder;

export 'function_type_alias_builder.dart' show FunctionTypeAliasBuilder;

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

export '../scope.dart' show AccessErrorBuilder, Scope, ScopeBuilder;

export 'builtin_type_builder.dart' show BuiltinTypeBuilder;

export 'dynamic_type_builder.dart' show DynamicTypeBuilder;

export 'void_type_builder.dart' show VoidTypeBuilder;

export 'function_type_builder.dart' show FunctionTypeBuilder;

import 'library_builder.dart' show LibraryBuilder;

import 'package:front_end/src/fasta/builder/class_builder.dart'
    show ClassBuilder;

import 'package:front_end/src/fasta/source/source_library_builder.dart'
    show SourceLibraryBuilder;

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
  int resolveConstructors(LibraryBuilder parent) => 0;

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

  bool get isTypeVariable => false;

  bool get isConstructor => false;

  bool get isFactory => false;

  bool get isLocal => false;

  bool get isConst => false;

  bool get isSynthetic => false;

  get target => unsupported("target", charOffset, fileUri);

  bool get hasProblem => false;

  String get fullNameForErrors;

  Uri computeLibraryUri() {
    Builder builder = this;
    do {
      if (builder is LibraryBuilder) return builder.uri;
      builder = builder.parent;
    } while (builder != null);
    return unhandled("no library parent", "${runtimeType}", -1, null);
  }

  void prepareInitializerInference(
      SourceLibraryBuilder library, ClassBuilder currentClass) {}
}
