// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';

import '../api_prototype/experimental_flags.dart';
import '../base/lookup_result.dart';
import '../base/messages.dart';
import '../base/problems.dart';
import '../base/scope.dart';
import '../builder/builder.dart';
import '../builder/builder_mixins.dart';
import '../builder/constructor_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/factory_builder.dart';
import '../builder/library_builder.dart';
import '../builder/type_builder.dart';
import '../kernel/type_algorithms.dart';
import 'source_class_builder.dart';
import 'source_declaration_builder.dart';
import 'source_library_builder.dart';
import 'source_member_builder.dart';
import 'source_type_parameter_builder.dart';

mixin SourceDeclarationBuilderBaseMixin
    implements DeclarationBuilderMixin, SourceDeclarationBuilder {
  @override
  List<SourceNominalParameterBuilder>? get typeParameters;

  @override
  int get typeParametersCount => typeParameters?.length ?? 0;

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context) {
    bool hasErrors = context.reportNonSimplicityIssues(this, typeParameters);
    int count = context.computeDefaultTypesForVariables(
      typeParameters,
      inErrorRecovery: hasErrors,
    );

    Iterator<SourceMemberBuilder> constructorIterator =
        filteredConstructorsIterator<SourceMemberBuilder>(
          includeDuplicates: false,
        );
    while (constructorIterator.moveNext()) {
      count += constructorIterator.current.computeDefaultTypes(
        context,
        inErrorRecovery: hasErrors,
      );
    }

    Iterator<SourceMemberBuilder> memberIterator = filteredMembersIterator(
      includeDuplicates: false,
    );
    while (memberIterator.moveNext()) {
      count += memberIterator.current.computeDefaultTypes(
        context,
        inErrorRecovery: hasErrors,
      );
    }
    return count;
  }

  void checkTypesInOutline(TypeEnvironment typeEnvironment) {
    ProblemReporting problemReporting = libraryBuilder;
    LibraryFeatures libraryFeatures = libraryBuilder.libraryFeatures;

    Iterator<SourceMemberBuilder> memberIterator = filteredMembersIterator(
      includeDuplicates: false,
    );

    SourceDeclarationBuilder enclosingDeclarationBuilder = this;
    SourceClassBuilder? enclosingClassBuilder =
        enclosingDeclarationBuilder is SourceClassBuilder
        ? enclosingDeclarationBuilder
        : null;
    while (memberIterator.moveNext()) {
      SourceMemberBuilder builder = memberIterator.current;
      if (enclosingClassBuilder != null) {
        builder.checkVariance(enclosingClassBuilder, typeEnvironment);
      }
      builder.checkTypes(
        problemReporting,
        libraryFeatures,
        nameSpace,
        typeEnvironment,
      );
    }

    Iterator<SourceMemberBuilder> constructorIterator =
        filteredConstructorsIterator(includeDuplicates: false);
    while (constructorIterator.moveNext()) {
      constructorIterator.current.checkTypes(
        problemReporting,
        libraryFeatures,
        nameSpace,
        typeEnvironment,
      );
    }
  }

  @override
  List<DartType> buildAliasedTypeArguments(
    LibraryBuilder library,
    List<TypeBuilder>? arguments,
    ClassHierarchyBase? hierarchy,
  ) {
    if (arguments == null && typeParameters == null) {
      return <DartType>[];
    }

    if (arguments == null && typeParameters != null) {
      List<DartType> result = new List<DartType>.generate(
        typeParameters!.length,
        (int i) {
          if (typeParameters![i].defaultType == null) {
            throw 'here';
          }
          return typeParameters![i].defaultType!.buildAliased(
            library,
            TypeUse.defaultTypeAsTypeArgument,
            hierarchy,
          );
        },
        growable: true,
      );
      return result;
    }

    if (arguments != null && arguments.length != typeParametersCount) {
      // Coverage-ignore-block(suite): Not run.
      assert(
        libraryBuilder.loader.assertProblemReportedElsewhere(
          "$runtimeType.buildAliasedTypeArguments: "
          "the numbers of type parameters and type arguments don't match.",
          expectedPhase: CompilationPhaseForProblemReporting.outline,
        ),
      );
      return unhandled(
        diag.typeArgumentMismatch
            .withArguments(expectedCount: typeParametersCount)
            .problemMessage,
        "buildTypeArguments",
        -1,
        null,
      );
    }

    assert(arguments!.length == typeParametersCount);
    List<DartType> result = new List<DartType>.generate(arguments!.length, (
      int i,
    ) {
      return arguments[i].buildAliased(
        library,
        TypeUse.typeArgument,
        hierarchy,
      );
    }, growable: true);
    return result;
  }
}

mixin SourceDeclarationBuilderMixin
    implements DeclarationBuilderMixin, SourceDeclarationBuilder {
  @override
  SourceLibraryBuilder get libraryBuilder;

  @override
  Uri get fileUri;

  /// Builds the [Extension] for this extension build and inserts the members
  /// into the [Library] of [libraryBuilder].
  ///
  /// [addMembersToLibrary] is `true` if the extension members should be added
  /// to the library. This is `false` if the extension is in conflict with
  /// another library member. In this case, the extension member should not be
  /// added to the library to avoid name clashes with other members in the
  /// library.
  void buildInternal(
    LibraryBuilder coreLibrary, {
    required bool addMembersToLibrary,
  }) {
    ClassBuilder objectClassBuilder =
        coreLibrary.lookupRequiredLocalMember('Object') as ClassBuilder;

    void buildBuilders(NamedBuilder declaration) {
      String name = declaration.name;
      if (!name.startsWith('_') &&
          !(declaration is ConstructorBuilder ||
              declaration is FactoryBuilder)) {
        LookupResult? result = objectClassBuilder.lookupLocalMember(name);
        Builder? objectGetter = result?.getable;
        Builder? objectSetter = result?.setable;
        if (objectGetter != null && !objectGetter.isStatic ||
            // Coverage-ignore(suite): Not run.
            objectSetter != null && !objectSetter.isStatic) {
          libraryBuilder.addProblem(
            // TODO(johnniwinther): Use a different error message for
            //  extension type declarations.
            diag.extensionMemberConflictsWithObjectMember.withArguments(
              memberName: name,
            ),
            declaration.fileOffset,
            name.length,
            declaration.fileUri,
          );
        }
      }
      if (declaration.parent != this) {
        // Coverage-ignore-block(suite): Not run.
        if (fileUri != declaration.parent!.fileUri) {
          unexpected(
            "$fileUri",
            "${declaration.parent!.fileUri}",
            fileOffset,
            fileUri,
          );
        } else {
          unexpected(
            fullNameForErrors,
            declaration.parent!.fullNameForErrors,
            fileOffset,
            fileUri,
          );
        }
      } else if (declaration is SourceMemberBuilder) {
        SourceMemberBuilder memberBuilder = declaration;
        memberBuilder.buildOutlineNodes(({
          required Member member,
          Member? tearOff,
          required BuiltMemberKind kind,
        }) {
          _buildMember(
            memberBuilder,
            member,
            tearOff,
            kind,
            addMembersToLibrary: addMembersToLibrary,
          );
        });
      } else {
        unhandled(
          "${declaration.runtimeType}",
          "buildBuilders",
          declaration.fileOffset,
          declaration.fileUri,
        );
      }
    }

    unfilteredMembersIterator.forEach(buildBuilders);
    unfilteredConstructorsIterator.forEach(buildBuilders);
  }

  int buildBodyNodes({required bool addMembersToLibrary}) {
    int count = 0;
    Iterator<SourceMemberBuilder> iterator =
        filteredMembersIterator<SourceMemberBuilder>(
          includeDuplicates: false,
        ).join(
          filteredConstructorsIterator<SourceMemberBuilder>(
            includeDuplicates: false,
          ),
        );
    while (iterator.moveNext()) {
      SourceMemberBuilder declaration = iterator.current;
      count += declaration.buildBodyNodes(
        // Coverage-ignore(suite): Not run.
        ({
          required Member member,
          Member? tearOff,
          required BuiltMemberKind kind,
        }) {
          _buildMember(
            declaration,
            member,
            tearOff,
            kind,
            addMembersToLibrary: addMembersToLibrary,
          );
        },
      );
    }
    return count;
  }

  void _buildMember(
    SourceMemberBuilder memberBuilder,
    Member member,
    Member? tearOff,
    BuiltMemberKind memberKind, {
    required bool addMembersToLibrary,
  }) {
    if (!memberBuilder.isDuplicate) {
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
              unhandled(
                "${member.runtimeType}",
                "buildBuilders",
                member.fileOffset,
                member.fileUri,
              );
            }
          }

          Reference memberReference = addMember(member);
          Reference? tearOffReference;
          if (tearOff != null) {
            tearOffReference = addMember(tearOff);
          }
          addMemberDescriptorInternal(
            memberBuilder,
            memberKind,
            memberReference,
            tearOffReference,
          );
        } else {
          // Still set parent to avoid crashes.
          member.parent = libraryBuilder.library;
        }
      }
    }
  }

  /// Adds [member] and [tearOff] to this declaration.
  void addMemberInternal(
    SourceMemberBuilder memberBuilder,
    BuiltMemberKind memberKind,
    Member member,
    Member? tearOff,
  );

  /// Adds a descriptor for [member] to this declaration.
  void addMemberDescriptorInternal(
    SourceMemberBuilder memberBuilder,
    BuiltMemberKind memberKind,
    Reference memberReference,
    Reference? tearOffReference,
  );
}
