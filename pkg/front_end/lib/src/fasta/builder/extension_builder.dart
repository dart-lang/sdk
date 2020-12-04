// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import '../fasta_codes.dart' show templateInternalProblemNotFoundIn;
import '../scope.dart';
import '../problems.dart';

import 'builder.dart';
import 'library_builder.dart';
import 'member_builder.dart';
import 'metadata_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';
import 'type_variable_builder.dart';
import 'declaration_builder.dart';

abstract class ExtensionBuilder implements DeclarationBuilder {
  List<TypeVariableBuilder> get typeParameters;
  TypeBuilder get onType;

  /// Return the [Extension] built by this builder.
  Extension get extension;

  void buildOutlineExpressions(LibraryBuilder library, CoreTypes coreTypes);

  /// Looks up extension member by [name] taking privacy into account.
  ///
  /// If [setter] is `true` the sought member is a setter or assignable field.
  /// If [required] is `true` and no member is found an internal problem is
  /// reported.
  Builder lookupLocalMemberByName(Name name,
      {bool setter: false, bool required: false});

  /// Calls [f] for each member declared in this extension.
  void forEach(void f(String name, Builder builder));
}

abstract class ExtensionBuilderImpl extends DeclarationBuilderImpl
    implements ExtensionBuilder {
  @override
  final List<TypeVariableBuilder> typeParameters;

  @override
  final TypeBuilder onType;

  ExtensionBuilderImpl(
      List<MetadataBuilder> metadata,
      int modifiers,
      String name,
      LibraryBuilder parent,
      int charOffset,
      Scope scope,
      this.typeParameters,
      this.onType)
      : super(metadata, modifiers, name, parent, charOffset, scope);

  /// Lookup a static member of this declaration.
  @override
  Builder findStaticBuilder(
      String name, int charOffset, Uri fileUri, LibraryBuilder accessingLibrary,
      {bool isSetter: false}) {
    if (accessingLibrary.origin != library.origin && name.startsWith("_")) {
      return null;
    }
    Builder declaration = isSetter
        ? scope.lookupSetter(name, charOffset, fileUri, isInstanceScope: false)
        : scope.lookup(name, charOffset, fileUri, isInstanceScope: false);
    // TODO(johnniwinther): Handle patched extensions.
    return declaration;
  }

  @override
  DartType buildType(LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder> arguments,
      [bool notInstanceContext]) {
    throw new UnsupportedError("ExtensionBuilder.buildType is not supported.");
  }

  @override
  DartType buildTypesWithBuiltArguments(LibraryBuilder library,
      Nullability nullability, List<DartType> arguments) {
    throw new UnsupportedError("ExtensionBuilder.buildTypesWithBuiltArguments "
        "is not supported.");
  }

  @override
  void forEach(void f(String name, Builder builder)) {
    scope.forEach(f);
  }

  @override
  bool get isExtension => true;

  @override
  InterfaceType get thisType => null;

  @override
  Builder lookupLocalMember(String name,
      {bool setter: false, bool required: false}) {
    // TODO(johnniwinther): Support patching on extensions.
    Builder builder = scope.lookupLocalMember(name, setter: setter);
    if (required && builder == null) {
      internalProblem(
          templateInternalProblemNotFoundIn.withArguments(
              name, fullNameForErrors),
          -1,
          null);
    }
    return builder;
  }

  @override
  Builder lookupLocalMemberByName(Name name,
      {bool setter: false, bool required: false}) {
    Builder builder =
        lookupLocalMember(name.text, setter: setter, required: required);
    if (builder != null && name.isPrivate && library.library != name.library) {
      builder = null;
    }
    return builder;
  }

  @override
  String get debugName => "ExtensionBuilder";

  @override
  void buildOutlineExpressions(LibraryBuilder library, CoreTypes coreTypes) {
    void build(String ignore, Builder declaration) {
      MemberBuilder member = declaration;
      member.buildOutlineExpressions(library, coreTypes);
    }

    // TODO(johnniwinther): Handle annotations on the extension declaration.
    //MetadataBuilder.buildAnnotations(
    //    isPatch ? origin.extension : extension,
    //    metadata, library, this, null);
    scope.forEach(build);
  }
}
