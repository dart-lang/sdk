// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_algebra.dart';

import '../fasta_codes.dart'
    show templateInternalProblemNotFoundIn, templateTypeArgumentMismatch;
import '../scope.dart';
import '../source/source_library_builder.dart';
import '../problems.dart';
import '../util/helpers.dart';

import 'builder.dart';
import 'declaration_builder.dart';
import 'library_builder.dart';
import 'member_builder.dart';
import 'metadata_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';
import 'type_variable_builder.dart';

abstract class ExtensionBuilder implements DeclarationBuilder {
  List<TypeVariableBuilder> get typeParameters;
  TypeBuilder get onType;

  /// Return the [Extension] built by this builder.
  Extension get extension;

  void buildOutlineExpressions(LibraryBuilder library, CoreTypes coreTypes,
      List<DelayedActionPerformer> delayedActionPerformers);

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
    if (library is SourceLibraryBuilder &&
        library.enableExtensionTypesInLibrary) {
      return buildTypesWithBuiltArguments(
          library,
          nullabilityBuilder.build(library),
          buildTypeArguments(library, arguments, notInstanceContext));
    } else {
      throw new UnsupportedError("ExtensionBuilder.buildType is not supported"
          "in library '${library.importUri}'.");
    }
  }

  @override
  DartType buildTypesWithBuiltArguments(LibraryBuilder library,
      Nullability nullability, List<DartType> arguments) {
    if (library is SourceLibraryBuilder &&
        library.enableExtensionTypesInLibrary) {
      // TODO(dmitryas): Build the extension type rather than the on-type.
      DartType builtOnType = onType.build(library);
      if (typeParameters != null) {
        List<TypeParameter> typeParameterNodes = <TypeParameter>[];
        for (TypeVariableBuilder typeParameter in typeParameters) {
          typeParameterNodes.add(typeParameter.parameter);
        }
        builtOnType = Substitution.fromPairs(typeParameterNodes, arguments)
            .substituteType(builtOnType);
      }
      return builtOnType;
    } else {
      throw new UnsupportedError(
          "ExtensionBuilder.buildTypesWithBuiltArguments "
          "is not supported in library '${library.importUri}'.");
    }
  }

  @override
  int get typeVariablesCount => typeParameters?.length ?? 0;

  List<DartType> buildTypeArguments(
      LibraryBuilder library, List<TypeBuilder> arguments,
      [bool notInstanceContext]) {
    if (arguments == null && typeParameters == null) {
      return <DartType>[];
    }

    if (arguments == null && typeParameters != null) {
      List<DartType> result = new List<DartType>.filled(
          typeParameters.length, null,
          growable: true);
      for (int i = 0; i < result.length; ++i) {
        result[i] = typeParameters[i].defaultType.build(library);
      }
      if (library is SourceLibraryBuilder) {
        library.inferredTypes.addAll(result);
      }
      return result;
    }

    if (arguments != null && arguments.length != typeVariablesCount) {
      // That should be caught and reported as a compile-time error earlier.
      return unhandled(
          templateTypeArgumentMismatch
              .withArguments(typeVariablesCount)
              .message,
          "buildTypeArguments",
          -1,
          null);
    }

    assert(arguments.length == typeVariablesCount);
    List<DartType> result =
        new List<DartType>.filled(arguments.length, null, growable: true);
    for (int i = 0; i < result.length; ++i) {
      result[i] = arguments[i].build(library);
    }
    return result;
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
    if (builder != null) {
      if (name.isPrivate && library.library != name.library) {
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

  @override
  String get debugName => "ExtensionBuilder";

  @override
  void buildOutlineExpressions(LibraryBuilder library, CoreTypes coreTypes,
      List<DelayedActionPerformer> delayedActionPerformers) {
    void build(String ignore, Builder declaration) {
      MemberBuilder member = declaration;
      member.buildOutlineExpressions(
          library, coreTypes, delayedActionPerformers);
    }

    // TODO(johnniwinther): Handle annotations on the extension declaration.
    //MetadataBuilder.buildAnnotations(
    //    isPatch ? origin.extension : extension,
    //    metadata, library, this, null);
    scope.forEach(build);
  }
}
