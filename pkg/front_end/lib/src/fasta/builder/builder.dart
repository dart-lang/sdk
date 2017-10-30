// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.builder;

import '../../base/instrumentation.dart' show Instrumentation;

import '../problems.dart' show unhandled, unsupported;

import 'library_builder.dart' show LibraryBuilder;

import 'class_builder.dart' show ClassBuilder;

export '../scope.dart' show AccessErrorBuilder, Scope, ScopeBuilder;

export '../source/unhandled_listener.dart' show Unhandled;

export 'builtin_type_builder.dart' show BuiltinTypeBuilder;

export 'class_builder.dart' show ClassBuilder;

export 'constructor_reference_builder.dart' show ConstructorReferenceBuilder;

export 'dynamic_type_builder.dart' show DynamicTypeBuilder;

export 'enum_builder.dart' show EnumBuilder;

export 'field_builder.dart' show FieldBuilder;

export 'formal_parameter_builder.dart' show FormalParameterBuilder;

export 'function_type_alias_builder.dart' show FunctionTypeAliasBuilder;

export 'function_type_builder.dart' show FunctionTypeBuilder;

export 'invalid_type_builder.dart' show InvalidTypeBuilder;

export 'library_builder.dart' show LibraryBuilder;

export 'load_library_builder.dart' show LoadLibraryBuilder;

export 'member_builder.dart' show MemberBuilder;

export 'metadata_builder.dart' show MetadataBuilder;

export 'mixin_application_builder.dart' show MixinApplicationBuilder;

export 'modifier_builder.dart' show ModifierBuilder;

export 'named_type_builder.dart' show NamedTypeBuilder;

export 'prefix_builder.dart' show PrefixBuilder;

export 'procedure_builder.dart' show ProcedureBuilder;

export 'qualified_name.dart' show QualifiedName;

export 'type_builder.dart' show TypeBuilder;

export 'type_declaration_builder.dart' show TypeDeclarationBuilder;

export 'type_variable_builder.dart' show TypeVariableBuilder;

export 'unresolved_type.dart' show UnresolvedType;

export 'void_type_builder.dart' show VoidTypeBuilder;

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

  get target => unsupported("${runtimeType}.target", charOffset, fileUri);

  bool get hasProblem => false;

  bool get isPatch => this != origin;

  Builder get origin => this;

  String get fullNameForErrors;

  Uri computeLibraryUri() {
    Builder builder = this;
    do {
      if (builder is LibraryBuilder) return builder.uri;
      builder = builder.parent;
    } while (builder != null);
    return unhandled("no library parent", "${runtimeType}", -1, null);
  }

  void prepareTopLevelInference(
      covariant LibraryBuilder library, ClassBuilder currentClass) {}

  void instrumentTopLevelInference(Instrumentation instrumentation) {}
}
