// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/reference_from_index.dart';

import '../base/extension_scope.dart';
import '../base/lookup_result.dart';
import '../base/messages.dart';
import '../base/name_space.dart';
import '../base/problems.dart';
import '../base/uri_offset.dart';
import '../builder/builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/factory_builder.dart';
import '../builder/function_builder.dart';
import '../builder/member_builder.dart';
import '../builder/prefix_builder.dart';
import '../builder/type_builder.dart';
import '../fragment/fragment.dart';
import 'builder_factory.dart';
import 'name_scheme.dart';
import 'nominal_parameter_name_space.dart';
import 'source_class_builder.dart';
import 'source_extension_builder.dart';
import 'source_library_builder.dart';
import 'source_loader.dart';
import 'source_member_builder.dart';
import 'type_parameter_factory.dart';

class DeclarationNameSpaceBuilder {
  final NominalParameterNameSpace? _nominalParameterNameSpace;
  final List<Fragment> _fragments;

  DeclarationNameSpaceBuilder(this._nominalParameterNameSpace, this._fragments);

  DeclarationNameSpaceBuilder.empty()
    : _nominalParameterNameSpace = null,
      _fragments = const [];

  SourceDeclarationNameSpace buildNameSpace({
    required SourceLoader loader,
    required ProblemReporting problemReporting,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required IndexedLibrary? indexedLibrary,
    required IndexedContainer? indexedContainer,
    required ContainerType containerType,
    required ContainerName containerName,
    required List<SourceMemberBuilder> constructorBuilders,
    required List<SourceMemberBuilder> memberBuilders,
    required TypeParameterFactory typeParameterFactory,
    Map<String, SyntheticDeclaration>? syntheticDeclarations,
  }) {
    _DeclarationBuilderRegistry builderRegistry =
        new _DeclarationBuilderRegistry(
          problemReporting: problemReporting,
          enclosingLibraryBuilder: enclosingLibraryBuilder,
          declarationBuilder: declarationBuilder,
          constructorBuilders: constructorBuilders,
          memberBuilders: memberBuilders,
        );

    Map<String, List<Fragment>> fragmentsByName = {};
    int primaryConstructBodyCount = 0;
    List<PrimaryConstructorBodyFragment>? primaryConstructorBodies;
    for (Fragment fragment in _fragments) {
      if (fragment is PrimaryConstructorBodyFragment) {
        (primaryConstructorBodies ??= []).add(fragment);
        primaryConstructBodyCount++;
      } else {
        (fragmentsByName[fragment.name] ??= []).add(fragment);
      }
    }

    BuilderFactory builderFactory = new BuilderFactory(
      loader: loader,
      problemReporting: problemReporting,
      enclosingLibraryBuilder: enclosingLibraryBuilder,
      builderRegistry: builderRegistry,
      declarationBuilder: declarationBuilder,
      typeParameterFactory: typeParameterFactory,
      // TODO(johnniwinther): Avoid passing this:
      mixinApplications: const {},
      indexedLibrary: indexedLibrary,
      indexedContainer: indexedContainer,
      containerType: containerType,
      containerName: containerName,
    );
    for (MapEntry<String, List<Fragment>> entry in fragmentsByName.entries) {
      String name = entry.key;
      builderFactory.computeBuildersByName(
        name,
        fragments: entry.value,
        syntheticDeclaration: syntheticDeclarations?.remove(name),
        primaryConstructorBodies: primaryConstructorBodies,
      );
    }
    if (syntheticDeclarations != null) {
      for (MapEntry<String, SyntheticDeclaration> entry
          in syntheticDeclarations.entries) {
        String name = entry.key;
        builderFactory.computeBuildersByName(
          name,
          syntheticDeclaration: entry.value,
          primaryConstructorBodies: primaryConstructorBodies,
        );
      }
    }

    void checkConflicts(NamedBuilder member) {
      checkTypeParameterConflict(
        problemReporting,
        member.name,
        member,
        member.fileUri!,
      );
    }

    if (primaryConstructorBodies != null &&
        primaryConstructorBodies.isNotEmpty) {
      bool hasPrimaryConstructor =
          primaryConstructBodyCount > primaryConstructorBodies.length;
      int index = hasPrimaryConstructor ? 1 : 0;
      for (PrimaryConstructorBodyFragment fragment
          in primaryConstructorBodies) {
        if (index == 0) {
          problemReporting.addProblem2(
            diag.primaryConstructorBodyWithoutDeclaration,
            fragment.uriOffset,
          );
        } else {
          problemReporting.addProblem2(
            diag.multiplePrimaryConstructorBodyDeclarations,
            fragment.uriOffset,
          );
        }
        index++;
      }
    }

    memberBuilders.forEach(checkConflicts);
    constructorBuilders.forEach(checkConflicts);

    return new SourceDeclarationNameSpace(
      content: builderRegistry.content,
      constructors: builderRegistry.constructors,
    );
  }

  void checkTypeParameterConflict(
    ProblemReporting _problemReporting,
    String name,
    NamedBuilder memberBuilder,
    Uri fileUri,
  ) {
    if (memberBuilder.isDuplicate) return;
    if (_nominalParameterNameSpace != null) {
      NominalParameterBuilder? tv = _nominalParameterNameSpace.getTypeParameter(
        name,
      );
      if (tv != null) {
        _problemReporting.addProblem(
          diag.conflictsWithTypeParameter.withArguments(typeVariableName: name),
          memberBuilder.fileOffset,
          name.length,
          fileUri,
          context: [
            diag.conflictsWithTypeParameterCause.withLocation(
              tv.fileUri!,
              tv.fileOffset,
              name.length,
            ),
          ],
        );
      }
    }
  }

  void includeBuilders(DeclarationNameSpaceBuilder other) {
    _fragments.addAll(other._fragments);
    other._fragments.clear();
  }
}

class LibraryNameSpaceBuilder {
  List<Fragment> _fragments = [];

  void addFragment(Fragment fragment) {
    _fragments.add(fragment);
  }

  void includeBuilders(LibraryNameSpaceBuilder other) {
    _fragments.addAll(other._fragments);
  }

  (LibraryNameSpace, LibraryExtensions) toNameSpace({
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required IndexedLibrary? indexedLibrary,
    required ProblemReporting problemReporting,
    required TypeParameterFactory typeParameterFactory,
    required Map<SourceClassBuilder, TypeBuilder> mixinApplications,
    required List<NamedBuilder> memberBuilders,
  }) {
    _LibraryBuilderRegistry builderRegistry = new _LibraryBuilderRegistry(
      problemReporting: problemReporting,
      enclosingLibraryBuilder: enclosingLibraryBuilder,
      memberBuilders: memberBuilders,
    );

    Map<String, List<Fragment>> fragmentsByName = {};
    for (Fragment fragment in _fragments) {
      (fragmentsByName[fragment.name] ??= []).add(fragment);
    }

    BuilderFactory builderFactory = new BuilderFactory(
      loader: enclosingLibraryBuilder.loader,
      builderRegistry: builderRegistry,
      problemReporting: problemReporting,
      enclosingLibraryBuilder: enclosingLibraryBuilder,
      typeParameterFactory: typeParameterFactory,
      mixinApplications: mixinApplications,
      indexedLibrary: indexedLibrary,
      containerType: ContainerType.Library,
    );

    for (MapEntry<String, List<Fragment>> entry in fragmentsByName.entries) {
      builderFactory.computeBuildersByName(entry.key, fragments: entry.value);
    }
    return (
      new LibraryNameSpace(content: builderRegistry.content),
      new LibraryExtensions(extensions: builderRegistry.extensions),
    );
  }
}

class _DeclarationBuilderRegistry implements BuilderRegistry {
  final Map<String, MemberLookupResult> content = {};
  final Map<String, MemberLookupResult> constructors = {};
  final ProblemReporting problemReporting;
  final SourceLibraryBuilder enclosingLibraryBuilder;
  final DeclarationBuilder declarationBuilder;
  final List<SourceMemberBuilder> constructorBuilders;
  final List<SourceMemberBuilder> memberBuilders;

  _DeclarationBuilderRegistry({
    required this.problemReporting,
    required this.enclosingLibraryBuilder,
    required this.declarationBuilder,
    required this.constructorBuilders,
    required this.memberBuilders,
  });

  @override
  void registerBuilder({
    required covariant MemberBuilder declaration,
    required UriOffsetLength uriOffset,
    required bool inPatch,
  }) {
    String name = declaration.name;

    assert(
      declaration.next == null,
      "Unexpected declaration.next ${declaration.next} on $declaration",
    );

    bool isConstructor =
        declaration is ConstructorBuilder || declaration is FactoryBuilder;
    if (!isConstructor && name == declarationBuilder.name) {
      // TODO(johnniwinther): Check these closer to the member declaration to
      // better specialize the message.
      if (declarationBuilder.isEnum && name == 'values') {
        problemReporting.addProblem(
          diag.enumWithNameValues,
          declarationBuilder.fileOffset,
          name.length,
          declarationBuilder.fileUri,
        );
      } else {
        problemReporting.addProblem2(diag.memberWithSameNameAsClass, uriOffset);
      }
    }
    if (isConstructor) {
      constructorBuilders.add(declaration as SourceMemberBuilder);
    } else {
      memberBuilders.add(declaration as SourceMemberBuilder);
    }

    if (inPatch &&
        !name.startsWith('_') &&
        !_allowInjectedPublicMember(enclosingLibraryBuilder, declaration)) {
      // TODO(johnniwinther): Test adding a no-name constructor in the
      //  patch, either as an injected or duplicated constructor.
      problemReporting.addProblem2(
        diag.patchInjectionFailed.withArguments(
          name: name,
          uri: enclosingLibraryBuilder.importUri,
        ),
        uriOffset,
      );
    }

    if (isConstructor) {
      MemberLookupResult? existingResult = constructors[name];

      assert(
        existingResult != declaration,
        "Unexpected existing declaration $existingResult",
      );

      if (existingResult == null) {
        constructors[name] = declaration as MemberBuilder;
      } else if (existingResult is DuplicateMemberLookupResult) {
        declaration.next = existingResult.declarations.last;
        existingResult.declarations.add(declaration);
      } else {
        MemberBuilder existingDeclaration = existingResult.getable!;
        declaration.next = existingDeclaration;
        constructors[name] = new DuplicateMemberLookupResult([
          existingDeclaration,
          declaration,
        ]);
      }
    } else {
      MemberLookupResult? existingResult = content[name];
      if (existingResult == null) {
        content[name] = declaration;
      } else if (existingResult is DuplicateMemberLookupResult) {
        declaration.next = existingResult.declarations.last;
        existingResult.declarations.add(declaration);
      } else {
        MemberBuilder? existingGetable = existingResult.getable;
        MemberBuilder? existingSetable = existingResult.setable;
        declaration.next = existingGetable ?? existingSetable;
        content[name] = new DuplicateMemberLookupResult([
          if (existingGetable != null) existingGetable,
          if (existingSetable != null) existingSetable,
          declaration,
        ]);
      }
    }
  }

  bool _allowInjectedPublicMember(
    SourceLibraryBuilder enclosingLibraryBuilder,
    Builder newBuilder,
  ) {
    if (enclosingLibraryBuilder.importUri.isScheme("dart") &&
        enclosingLibraryBuilder.importUri.path.startsWith("_")) {
      return true;
    }
    if (newBuilder.isStatic) {
      return declarationBuilder.name.startsWith('_');
    }
    // TODO(johnniwinther): Restrict the use of injected public class members.
    return true;
  }
}

class _LibraryBuilderRegistry implements BuilderRegistry {
  final Map<String, LookupResult> content = {};
  final Set<ExtensionBuilder> extensions = {};
  final ProblemReporting problemReporting;
  final SourceLibraryBuilder enclosingLibraryBuilder;
  final List<NamedBuilder> memberBuilders;

  _LibraryBuilderRegistry({
    required this.problemReporting,
    required this.enclosingLibraryBuilder,
    required this.memberBuilders,
  });

  @override
  void registerBuilder({
    required NamedBuilder declaration,
    required UriOffsetLength uriOffset,
    required bool inPatch,
  }) {
    String name = declaration.name;

    assert(
      declaration.next == null,
      "Unexpected declaration.next ${declaration.next} on $declaration",
    );

    memberBuilders.add(declaration);

    if (declaration is SourceExtensionBuilder &&
        declaration.isUnnamedExtension) {
      extensions.add(declaration);
      return;
    }

    if (declaration is MemberBuilder || declaration is TypeDeclarationBuilder) {
      // Expected.
    } else {
      // Coverage-ignore-block(suite): Not run.
      // Prefix builders are added when computing the import scope.
      assert(
        declaration is! PrefixBuilder,
        "Unexpected prefix builder $declaration.",
      );
      unhandled(
        "${declaration.runtimeType}",
        "addBuilder",
        uriOffset.fileOffset,
        uriOffset.fileUri,
      );
    }

    assert(
      !(declaration is FunctionBuilder &&
          // Coverage-ignore(suite): Not run.
          (declaration is ConstructorBuilder || declaration is FactoryBuilder)),
      "Unexpected constructor in library: $declaration.",
    );

    if (inPatch &&
        !name.startsWith('_') &&
        !_allowInjectedPublicMember(enclosingLibraryBuilder, declaration)) {
      problemReporting.addProblem2(
        diag.patchInjectionFailed.withArguments(
          name: name,
          uri: enclosingLibraryBuilder.importUri,
        ),
        uriOffset,
      );
    }

    LookupResult? existingResult = content[name];
    NamedBuilder? existing = existingResult?.getable ?? existingResult?.setable;

    assert(
      existing != declaration,
      "Unexpected existing declaration $existing",
    );

    if (declaration.next != null &&
        // Coverage-ignore(suite): Not run.
        declaration.next != existing) {
      unexpected(
        "${declaration.next!.fileUri}@${declaration.next!.fileOffset}",
        "${existing?.fileUri}@${existing?.fileOffset}",
        declaration.fileOffset,
        declaration.fileUri,
      );
    }
    declaration.next = existing;
    if (declaration is SourceExtensionBuilder && !declaration.isDuplicate) {
      // We add the extension declaration to the extension scope only if its
      // name is unique. Only the first of duplicate extensions is accessible
      // by name or by resolution and the remaining are dropped for the
      // output.
      extensions.add(declaration);
    }
    content[name] = declaration as LookupResult;
  }

  bool _allowInjectedPublicMember(
    SourceLibraryBuilder enclosingLibraryBuilder,
    Builder newBuilder,
  ) {
    return enclosingLibraryBuilder.importUri.isScheme("dart") &&
        enclosingLibraryBuilder.importUri.path.startsWith("_");
  }
}
