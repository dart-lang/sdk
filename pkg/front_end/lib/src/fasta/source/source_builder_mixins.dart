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
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/name_iterator.dart';
import '../builder/procedure_builder.dart';
import '../builder/type_builder.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/kernel_helper.dart';
import '../messages.dart';
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
    if (!memberBuilder.isPatch &&
        !memberBuilder.isDuplicate &&
        !memberBuilder.isConflictingSetter) {
      if (memberKind == BuiltMemberKind.ExtensionTypeRepresentationField) {
        addMemberInternal(memberBuilder, memberKind, member, tearOff);
      } else {
        if (addMembersToLibrary) {
          Reference addMember(Member member) {
            if (member is Field) {
              libraryBuilder.library.addField(member);
              return member.fieldReference;
            } else if (member is Procedure) {
              libraryBuilder.library.addProcedure(member);
              return member.reference;
            } else {
              unhandled("${member.runtimeType}", "buildBuilders",
                  member.fileOffset, member.fileUri);
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
    }
  }

  /// Adds [member] and [tearOff] to this declaration.
  void addMemberInternal(SourceMemberBuilder memberBuilder,
      BuiltMemberKind memberKind, Member member, Member? tearOff);

  /// Adds a descriptor for [member] to this declaration.
  void addMemberDescriptorInternal(
      SourceMemberBuilder memberBuilder,
      BuiltMemberKind memberKind,
      Reference memberReference,
      Reference? tearOffReference);

  /// Type parameters declared.
  ///
  /// This is `null` if the declaration is not generic.
  List<NominalVariableBuilder>? get typeParameters;

  @override
  List<DartType> buildAliasedTypeArguments(LibraryBuilder library,
      List<TypeBuilder>? arguments, ClassHierarchyBase? hierarchy) {
    if (arguments == null && typeParameters == null) {
      return <DartType>[];
    }

    if (arguments == null && typeParameters != null) {
      List<DartType> result =
          new List<DartType>.generate(typeParameters!.length, (int i) {
        if (typeParameters![i].defaultType == null) {
          throw 'here';
        }
        return typeParameters![i].defaultType!.buildAliased(
            library, TypeUse.defaultTypeAsTypeArgument, hierarchy);
      }, growable: true);
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
      return arguments[i]
          .buildAliased(library, TypeUse.typeArgument, hierarchy);
    }, growable: true);
    return result;
  }

  @override
  int get typeVariablesCount => typeParameters?.length ?? 0;
}

mixin SourceTypedDeclarationBuilderMixin implements IDeclarationBuilder {
  /// Checks for conflicts between constructors and static members declared
  /// in this type declaration.
  void checkConstructorStaticConflict() {
    NameIterator<MemberBuilder> iterator =
        constructorScope.filteredNameIterator(
            includeDuplicates: false, includeAugmentations: true);
    while (iterator.moveNext()) {
      String name = iterator.name;
      MemberBuilder constructor = iterator.current;
      Builder? member = scope.lookupLocalMember(name, setter: false);
      if (member == null) continue;
      if (!member.isStatic) continue;
      // TODO(ahe): Revisit these messages. It seems like the last two should
      // be `context` parameter to this message.
      addProblem(templateConflictsWithMember.withArguments(name),
          constructor.charOffset, noLength);
      if (constructor.isFactory) {
        addProblem(
            templateConflictsWithFactory.withArguments("${this.name}.${name}"),
            member.charOffset,
            noLength);
      } else {
        addProblem(
            templateConflictsWithConstructor
                .withArguments("${this.name}.${name}"),
            member.charOffset,
            noLength);
      }
    }

    scope.forEachLocalSetter((String name, Builder setter) {
      Builder? constructor = constructorScope.lookupLocalMember(name);
      if (constructor == null || !setter.isStatic) return;
      addProblem(templateConflictsWithConstructor.withArguments(name),
          setter.charOffset, noLength);
      addProblem(templateConflictsWithSetter.withArguments(name),
          constructor.charOffset, noLength);
    });
  }
}
