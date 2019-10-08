// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart';

import '../fasta_codes.dart' show templateInternalProblemNotFoundIn;
import '../scope.dart';
import '../problems.dart';
import 'builder.dart';
import 'declaration.dart';
import 'declaration_builder.dart';
import 'library_builder.dart';
import 'metadata_builder.dart';
import 'type_builder.dart';
import 'type_variable_builder.dart';

abstract class ExtensionBuilder implements DeclarationBuilder {
  List<TypeVariableBuilder> get typeParameters;
  TypeBuilder get onType;

  /// Return the [Extension] built by this builder.
  Extension get extension;

  // Deliberately unrelated return type to statically detect more accidental
  // use until Builder.target is fully retired.
  @override
  UnrelatedTarget get target;

  void buildOutlineExpressions(LibraryBuilder library);
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

  // Deliberately unrelated return type to statically detect more accidental
  // use until Builder.target is fully retired.
  @override
  UnrelatedTarget get target => unsupported(
      "ExtensionBuilder.target is deprecated. "
      "Use ExtensionBuilder.extension instead.",
      charOffset,
      fileUri);

  @override
  DartType buildType(LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder> arguments) {
    throw new UnsupportedError("ExtensionBuilder.buildType is not supported.");
  }

  @override
  DartType buildTypesWithBuiltArguments(LibraryBuilder library,
      Nullability nullability, List<DartType> arguments) {
    throw new UnsupportedError("ExtensionBuilder.buildTypesWithBuiltArguments "
        "is not supported.");
  }

  @override
  bool get isExtension => true;

  @override
  InterfaceType get thisType => null;

  @override
  Builder lookupLocalMember(String name,
      {bool setter: false, bool required: false}) {
    // TODO(johnniwinther): Support patching on extensions.
    Builder builder = setter ? scope.setters[name] : scope.local[name];
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
  String get debugName => "ExtensionBuilder";

  @override
  void buildOutlineExpressions(LibraryBuilder library) {
    void build(String ignore, Builder declaration) {
      MemberBuilder member = declaration;
      member.buildOutlineExpressions(library);
    }

    // TODO(johnniwinther): Handle annotations on the extension declaration.
    //MetadataBuilder.buildAnnotations(
    //    isPatch ? origin.extension : extension,
    //    metadata, library, this, null);
    scope.forEach(build);
  }
}
