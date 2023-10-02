// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';

import '../builder/builder.dart';
import '../builder/builder_mixins.dart';
import '../builder/declaration_builders.dart';
import '../builder/library_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/procedure_builder.dart';
import '../fasta_codes.dart'
    show templateExtensionMemberConflictsWithObjectMember;
import '../kernel/body_builder_context.dart';
import '../kernel/kernel_helper.dart';
import '../problems.dart';
import '../scope.dart';
import '../util/helpers.dart';
import 'source_constructor_builder.dart';
import 'source_field_builder.dart';
import 'source_library_builder.dart';
import 'source_member_builder.dart';
import 'source_procedure_builder.dart';

mixin SourceDeclarationBuilderMixin implements DeclarationBuilderMixin {
  @override
  SourceLibraryBuilder get libraryBuilder;

  @override
  Uri get fileUri;

  /// Returns the [Annotatable] node that holds the annotations declared on
  /// this declaration or its augmentations.
  Annotatable get annotatable;

  /// Builds the [Extension] for this extension build and inserts the members
  /// into the [Library] of [libraryBuilder].
  ///
  /// [addMembersToLibrary] is `true` if the extension members should be added
  /// to the library. This is `false` if the extension is in conflict with
  /// another library member. In this case, the extension member should not be
  /// added to the library to avoid name clashes with other members in the
  /// library.
  void buildInternal(LibraryBuilder coreLibrary,
      {required bool addMembersToLibrary}) {
    SourceLibraryBuilder.checkMemberConflicts(libraryBuilder, scope,
        checkForInstanceVsStaticConflict: true,
        checkForMethodVsSetterConflict: true);

    ClassBuilder objectClassBuilder =
        coreLibrary.lookupLocalMember('Object', required: true) as ClassBuilder;

    void buildBuilders(String name, Builder declaration) {
      Builder? objectGetter = objectClassBuilder.lookupLocalMember(name);
      Builder? objectSetter =
          objectClassBuilder.lookupLocalMember(name, setter: true);
      if (objectGetter != null && !objectGetter.isStatic ||
          objectSetter != null && !objectSetter.isStatic) {
        addProblem(
            // TODO(johnniwinther): Use a different error message for extension
            //  type declarations.
            templateExtensionMemberConflictsWithObjectMember
                .withArguments(name),
            declaration.charOffset,
            name.length);
      }
      if (declaration.parent != this) {
        if (fileUri != declaration.parent!.fileUri) {
          unexpected("$fileUri", "${declaration.parent!.fileUri}", charOffset,
              fileUri);
        } else {
          unexpected(fullNameForErrors, declaration.parent!.fullNameForErrors,
              charOffset, fileUri);
        }
      } else if (declaration is SourceMemberBuilder) {
        SourceMemberBuilder memberBuilder = declaration;
        memberBuilder.buildOutlineNodes((
            {required Member member,
            Member? tearOff,
            required BuiltMemberKind kind}) {
          _buildMember(memberBuilder, member, tearOff, kind,
              addMembersToLibrary: addMembersToLibrary);
        });
      } else {
        unhandled("${declaration.runtimeType}", "buildBuilders",
            declaration.charOffset, declaration.fileUri);
      }
    }

    scope.unfilteredNameIterator.forEach(buildBuilders);
    constructorScope.unfilteredNameIterator.forEach(buildBuilders);
  }

  int buildBodyNodes({required bool addMembersToLibrary}) {
    int count = 0;
    Iterator<SourceMemberBuilder> iterator = scope
        .filteredIterator<SourceMemberBuilder>(
            parent: this, includeDuplicates: false, includeAugmentations: true)
        .join(constructorScope.filteredIterator<SourceMemberBuilder>(
            parent: this,
            includeDuplicates: false,
            includeAugmentations: true));
    while (iterator.moveNext()) {
      SourceMemberBuilder declaration = iterator.current;
      count += declaration.buildBodyNodes((
          {required Member member,
          Member? tearOff,
          required BuiltMemberKind kind}) {
        _buildMember(declaration, member, tearOff, kind,
            addMembersToLibrary: addMembersToLibrary);
      });
    }
    return count;
  }

  void checkTypesInOutline(TypeEnvironment typeEnvironment) {
    forEach((String name, Builder builder) {
      if (builder is SourceFieldBuilder) {
        // Check fields.
        libraryBuilder.checkTypesInField(builder, typeEnvironment);
      } else if (builder is SourceProcedureBuilder) {
        // Check procedures
        libraryBuilder.checkTypesInFunctionBuilder(builder, typeEnvironment);
        if (builder.isGetter) {
          Builder? setterDeclaration =
              scope.lookupLocalMember(builder.name, setter: true);
          if (setterDeclaration != null) {
            libraryBuilder.checkGetterSetterTypes(builder,
                setterDeclaration as ProcedureBuilder, typeEnvironment);
          }
        }
      } else if (builder is SourceConstructorBuilder) {
        builder.checkTypes(libraryBuilder, typeEnvironment);
      } else {
        assert(false, "Unexpected member: $builder.");
      }
    });
  }

  BodyBuilderContext get bodyBuilderContext;

  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    MetadataBuilder.buildAnnotations(annotatable, metadata, bodyBuilderContext,
        libraryBuilder, fileUri, libraryBuilder.scope);
    if (typeParameters != null) {
      for (int i = 0; i < typeParameters!.length; i++) {
        typeParameters![i].buildOutlineExpressions(
            libraryBuilder,
            bodyBuilderContext,
            classHierarchy,
            delayedActionPerformers,
            scope.parent!);
      }
    }

    Iterator<SourceMemberBuilder> iterator = scope.filteredIterator(
        parent: this, includeDuplicates: false, includeAugmentations: true);
    while (iterator.moveNext()) {
      iterator.current.buildOutlineExpressions(
          classHierarchy, delayedActionPerformers, delayedDefaultValueCloners);
    }
  }

  void _buildMember(SourceMemberBuilder memberBuilder, Member member,
      Member? tearOff, BuiltMemberKind memberKind,
      {required bool addMembersToLibrary}) {
    if (addMembersToLibrary &&
        !memberBuilder.isPatch &&
        !memberBuilder.isDuplicate &&
        !memberBuilder.isConflictingSetter) {
      Reference addMember(Member member) {
        if (member is Field) {
          libraryBuilder.library.addField(member);
          return member.fieldReference;
        } else if (member is Procedure) {
          libraryBuilder.library.addProcedure(member);
          return member.reference;
        } else {
          unhandled("${member.runtimeType}", "buildBuilders", member.fileOffset,
              member.fileUri);
        }
      }

      Reference memberReference = addMember(member);
      Reference? tearOffReference;
      if (tearOff != null) {
        tearOffReference = addMember(tearOff);
      }
      addMemberDescriptorInternal(
          memberBuilder, memberKind, memberReference, tearOffReference);
    }
  }

  /// Adds a descriptor for [member] to this declaration.
  void addMemberDescriptorInternal(
      SourceMemberBuilder memberBuilder,
      BuiltMemberKind memberKind,
      Reference memberReference,
      Reference? tearOffReference);
}
