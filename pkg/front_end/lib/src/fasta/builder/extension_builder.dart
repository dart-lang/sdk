// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../fasta_codes.dart'
    show templateInternalProblemNotFoundIn, templateTypeArgumentMismatch;
import '../kernel/kernel_helper.dart';
import '../scope.dart';
import '../source/source_library_builder.dart';
import '../problems.dart';
import '../util/helpers.dart';

import 'builder.dart';
import 'declaration_builder.dart';
import 'field_builder.dart';
import 'library_builder.dart';
import 'member_builder.dart';
import 'metadata_builder.dart';
import 'nullability_builder.dart';
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

  void buildOutlineExpressions(
      SourceLibraryBuilder library,
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<SynthesizedFunctionNode> synthesizedFunctionNodes);

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
      {bool setter: false, bool required: false});

  /// Calls [f] for each member declared in this extension.
  void forEach(void f(String name, Builder builder));
}

abstract class ExtensionBuilderImpl extends DeclarationBuilderImpl
    implements ExtensionBuilder {
  ExtensionBuilderImpl(List<MetadataBuilder>? metadata, int modifiers,
      String name, LibraryBuilder parent, int charOffset, Scope scope)
      : super(metadata, modifiers, name, parent, charOffset, scope);

  /// Lookup a static member of this declaration.
  @override
  Builder? findStaticBuilder(
      String name, int charOffset, Uri fileUri, LibraryBuilder accessingLibrary,
      {bool isSetter: false}) {
    if (accessingLibrary.nameOriginBuilder.origin !=
            library.nameOriginBuilder.origin &&
        name.startsWith("_")) {
      return null;
    }
    Builder? declaration = isSetter
        ? scope.lookupSetter(name, charOffset, fileUri, isInstanceScope: false)
        : scope.lookup(name, charOffset, fileUri, isInstanceScope: false);
    // TODO(johnniwinther): Handle patched extensions.
    return declaration;
  }

  @override
  DartType buildType(LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder>? arguments) {
    if (library is SourceLibraryBuilder &&
        library.enableExtensionTypesInLibrary) {
      return buildTypeWithBuiltArguments(
          library,
          nullabilityBuilder.build(library),
          _buildTypeArguments(library, arguments));
    } else {
      throw new UnsupportedError("ExtensionBuilder.buildType is not supported"
          "in library '${library.importUri}'.");
    }
  }

  @override
  DartType buildTypeWithBuiltArguments(LibraryBuilder library,
      Nullability nullability, List<DartType> arguments) {
    if (library is SourceLibraryBuilder &&
        library.enableExtensionTypesInLibrary) {
      return new ExtensionType(extension, nullability, arguments);
    } else {
      throw new UnsupportedError(
          "ExtensionBuilder.buildTypesWithBuiltArguments "
          "is not supported in library '${library.importUri}'.");
    }
  }

  @override
  int get typeVariablesCount => typeParameters?.length ?? 0;

  List<DartType> _buildTypeArguments(
      LibraryBuilder library, List<TypeBuilder>? arguments) {
    if (arguments == null && typeParameters == null) {
      return <DartType>[];
    }

    if (arguments == null && typeParameters != null) {
      List<DartType> result =
          new List<DartType>.generate(typeParameters!.length, (int i) {
        return typeParameters![i].defaultType!.build(library);
      }, growable: true);
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
              .problemMessage,
          "buildTypeArguments",
          -1,
          null);
    }

    assert(arguments!.length == typeVariablesCount);
    List<DartType> result =
        new List<DartType>.generate(arguments!.length, (int i) {
      return arguments[i].build(library);
    }, growable: true);
    return result;
  }

  @override
  void forEach(void f(String name, Builder builder)) {
    scope.forEach(f);
  }

  @override
  bool get isExtension => true;

  @override
  InterfaceType? get thisType => null;

  @override
  Builder? lookupLocalMember(String name,
      {bool setter: false, bool required: false}) {
    // TODO(johnniwinther): Support patching on extensions.
    Builder? builder = scope.lookupLocalMember(name, setter: setter);
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
  Builder? lookupLocalMemberByName(Name name,
      {bool setter: false, bool required: false}) {
    Builder? builder =
        lookupLocalMember(name.text, setter: setter, required: required);
    if (builder == null && setter) {
      // When looking up setters, we include assignable fields.
      builder = lookupLocalMember(name.text, setter: false, required: required);
      if (builder is! FieldBuilder || !builder.isAssignable) {
        builder = null;
      }
    }
    if (builder != null) {
      if (name.isPrivate && library.library != name.library) {
        builder = null;
      } else if (builder is FieldBuilder &&
          !builder.isStatic &&
          !builder.isExternal) {
        // Non-external extension instance fields are invalid.
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
}
