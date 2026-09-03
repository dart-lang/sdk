// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart' hide ExtensionTypeDeclaration;
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/src/bounds_checks.dart' show VarianceCalculationValue;

import '../base/messages.dart';
import '../base/modifiers.dart';
import '../base/name_space.dart';
import '../base/scope.dart';
import '../base/uri_offset.dart';
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/type_builder.dart';
import '../fragment/constructor/declaration.dart';
import '../fragment/constructor/encoding.dart';
import '../fragment/extension/declaration.dart';
import '../fragment/extension_type/declaration.dart';
import '../fragment/factory/declaration.dart';
import '../fragment/factory/encoding.dart';
import '../fragment/field/declaration.dart';
import '../fragment/fragment.dart';
import '../fragment/getter/declaration.dart';
import '../fragment/method/declaration.dart';
import '../fragment/method/encoding.dart';
import '../fragment/setter/declaration.dart';
import 'name_scheme.dart';
import 'name_space_builder.dart';
import 'nominal_parameter_name_space.dart';
import 'source_class_builder.dart';
import 'source_constructor_builder.dart';
import 'source_enum_builder.dart';
import 'source_extension_builder.dart';
import 'source_extension_type_declaration_builder.dart';
import 'source_factory_builder.dart';
import 'source_library_builder.dart';
import 'source_loader.dart';
import 'source_method_builder.dart';
import 'source_property_builder.dart';
import 'source_type_alias_builder.dart';
import 'source_type_parameter_builder.dart';
import 'type_parameter_factory.dart';

/// Reports an error if [declaration] is augmenting.
///
/// This is called when the first [_PreBuilder] is created, meaning that the
/// augmentation didn't correspond to an introductory declaration.
void _checkAugmentation(
  ProblemReporting problemReporting,
  _Declaration declaration,
) {
  if (declaration.isAugment) {
    Message message;
    switch (declaration.kind) {
      case _DeclarationKind.Class:
        message = declaration.inPatch
            ? diag.unmatchedPatchClass.withArguments(
                className: declaration.displayName,
              )
            : diag.unmatchedAugmentationClass.withArguments(
                className: declaration.displayName,
              );
      case _DeclarationKind.Constructor:
      case _DeclarationKind.Factory:
      case _DeclarationKind.Method:
      case _DeclarationKind.Property:
        if (declaration.inLibrary) {
          message = declaration.inPatch
              ? diag.unmatchedPatchLibraryMember.withArguments(
                  memberName: declaration.displayName,
                )
              : diag.unmatchedAugmentationLibraryMember.withArguments(
                  memberName: declaration.displayName,
                );
        } else {
          message = declaration.inPatch
              ? diag.unmatchedPatchClassMember.withArguments(
                  memberName: declaration.displayName,
                )
              : diag.unmatchedAugmentationClassMember.withArguments(
                  memberName: declaration.displayName,
                );
        }
      case _DeclarationKind.Mixin:
      case _DeclarationKind.NamedMixinApplication:
      case _DeclarationKind.Enum:
      case _DeclarationKind.Extension:
      case _DeclarationKind.ExtensionType:
      // Coverage-ignore(suite): Not run.
      case _DeclarationKind.Typedef:
        // TODO(johnniwinther): Specialize more messages.
        message = declaration.inPatch
            ? diag.unmatchedPatchDeclaration.withArguments(
                declarationName: declaration.displayName,
              )
            : diag.unmatchedAugmentationDeclaration.withArguments(
                declarationName: declaration.displayName,
              );
    }
    problemReporting.addProblem2(message, declaration.uriOffset);
  }
}

class BuilderFactory {
  final ProblemReporting _problemReporting;
  final SourceLoader _loader;
  final BuilderRegistry _builderRegistry;
  final SourceLibraryBuilder _enclosingLibraryBuilder;
  final DeclarationBuilder? _declarationBuilder;
  final TypeParameterFactory _typeParameterFactory;
  final Map<SourceClassBuilder, TypeBuilder> _mixinApplications;
  final IndexedLibrary? _indexedLibrary;
  final ContainerType _containerType;
  final IndexedContainer? _indexedContainer;
  final ContainerName? _containerName;
  final bool _inLibrary;

  new({
    required ProblemReporting problemReporting,
    required SourceLoader loader,
    required BuilderRegistry builderRegistry,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    DeclarationBuilder? declarationBuilder,
    required TypeParameterFactory typeParameterFactory,
    required Map<SourceClassBuilder, TypeBuilder> mixinApplications,
    required IndexedLibrary? indexedLibrary,
    required ContainerType containerType,
    IndexedContainer? indexedContainer,
    ContainerName? containerName,
  }) : _containerName = containerName,
       _indexedContainer = indexedContainer,
       _containerType = containerType,
       _indexedLibrary = indexedLibrary,
       _mixinApplications = mixinApplications,
       _typeParameterFactory = typeParameterFactory,
       _declarationBuilder = declarationBuilder,
       _enclosingLibraryBuilder = enclosingLibraryBuilder,
       _builderRegistry = builderRegistry,
       _loader = loader,
       _problemReporting = problemReporting,
       _inLibrary = declarationBuilder == null;

  void computeBuildersByName(
    String name, {
    List<Fragment>? fragments,
    SyntheticDeclaration? syntheticDeclaration,
    List<PrimaryConstructorBodyFragment>? primaryConstructorBodies,
  }) {
    List<_PreBuilder> nonConstructorPreBuilders = [];
    List<_PreBuilder> constructorPreBuilders = [];
    List<Fragment> unnamedFragments = [];

    if (syntheticDeclaration != null) {
      syntheticDeclaration.createDeclaration().registerPreBuilder(
        _problemReporting,
        nonConstructorPreBuilders,
        constructorPreBuilders,
      );
    }

    if (fragments != null) {
      for (int i = 0; i < fragments.length; i++) {
        Fragment fragment = fragments[i];
        _Declaration? declaration = _createDeclarationFromFragment(
          fragment,
          inLibrary: _inLibrary,
          unnamedFragments: unnamedFragments,
          primaryConstructorBodies: primaryConstructorBodies,
        );

        declaration?.registerPreBuilder(
          _problemReporting,
          nonConstructorPreBuilders,
          constructorPreBuilders,
        );
      }
    }

    for (int i = 0; i < nonConstructorPreBuilders.length; i++) {
      _PreBuilder preBuilder = nonConstructorPreBuilders[i];
      preBuilder.createBuilders(this);
    }
    for (int i = 0; i < constructorPreBuilders.length; i++) {
      _PreBuilder preBuilder = constructorPreBuilders[i];
      preBuilder.createBuilders(this);
    }
    for (int i = 0; i < unnamedFragments.length; i++) {
      Fragment fragment = unnamedFragments[i];
      _createBuilder(fragment);
    }
  }

  void _createBuilder(Fragment fragment, {List<Fragment>? augmentations}) {
    switch (fragment) {
      case TypedefFragment():
        _createTypedefBuilder(fragment);
      case ClassFragment():
        _createClassBuilderFromFragments(fragment, augmentations);
      case MixinFragment():
        _createMixinBuilderFromFragments(fragment, augmentations);
      case NamedMixinApplicationFragment():
        _createNamedMixinApplicationBuilder(fragment);
      case EnumFragment():
        _createEnumBuilderFromFragments(fragment, augmentations);
      case ExtensionFragment():
        _createExtensionBuilderFromFragments(fragment, augmentations);
      case ExtensionTypeFragment():
        _createExtensionTypeBuilderFragments(fragment, augmentations);
      case MethodFragment():
        _createMethodBuilder(fragment, augmentations);
      // Coverage-ignore(suite): Not run.
      case ConstructorFragment():
      case PrimaryConstructorFragment():
      case PrimaryConstructorBodyFragment():
      case FactoryFragment():
      case FieldFragment():
      case PrimaryConstructorFieldFragment():
      case GetterFragment():
      case SetterFragment():
      case EnumElementFragment():
        throw new UnsupportedError('Unexpected fragment $fragment.');
    }
    if (augmentations != null) {
      for (Fragment augmentation in augmentations) {
        // Coverage-ignore-block(suite): Not run.
        _createBuilder(augmentation);
      }
    }
  }

  /// Connects [augmentationTypeParameters] type parameters with the
  /// [nominalParameters] declared in the introductory fragment.
  ///
  /// If there is mismatch in number of type parameters an error is reported
  /// using [typeParametersMismatchMessage] and
  /// [typeParameterIntroductoryMessage] and synthetic type parameters
  /// corresponding to the [nominalParameters] are created for the augmentation.
  ///
  /// The type parameters, declared or synthesized, are added to
  /// [augmentationNominalParameterNameSpace].
  void _augmentTypeParameters({
    required List<TypeParameterFragment>? augmentationTypeParameters,
    required NominalParameterNameSpace augmentationNominalParameterNameSpace,
    required List<SourceNominalParameterBuilder>? nominalParameters,
    required String declarationName,
    required UriOffsetLength introductionUriOffset,
    required UriOffsetLength augmentationUriOffset,
    required MessageCode typeParametersMismatchMessage,
    required MessageCode typeParameterIntroductoryMessage,
  }) {
    int introductoryTypeParameterCount = nominalParameters?.length ?? 0;
    int augmentationTypeParameterCount =
        augmentationTypeParameters?.length ?? 0;
    if (introductoryTypeParameterCount != augmentationTypeParameterCount) {
      _problemReporting.addProblem2(
        typeParametersMismatchMessage,
        augmentationUriOffset,
        context: [
          typeParameterIntroductoryMessage.withLocation2(introductionUriOffset),
        ],
      );

      // Error recovery. Create fresh type parameters for the
      // augmentation.
      augmentationNominalParameterNameSpace.addTypeParameters(
        _problemReporting,
        _typeParameterFactory.createNominalParameterBuilders(
          augmentationTypeParameters,
        ),
        ownerName: declarationName,
        allowNameConflict: false,
      );
    } else if (augmentationTypeParameters != null) {
      for (int index = 0; index < introductoryTypeParameterCount; index++) {
        SourceNominalParameterBuilder nominalParameterBuilder =
            nominalParameters![index];
        TypeParameterFragment typeParameterFragment =
            augmentationTypeParameters[index];
        nominalParameterBuilder.addAugmentingDeclaration(
          new RegularNominalParameterDeclaration(typeParameterFragment),
        );
        typeParameterFragment.builder = nominalParameterBuilder;
      }
      augmentationNominalParameterNameSpace.addTypeParameters(
        _problemReporting,
        nominalParameters,
        ownerName: declarationName,
        allowNameConflict: false,
      );
    }
  }

  /// Creates the declaration objects for the [introductory] fragment and each
  /// fragment in [augmentations], and uses these to create the builder object.
  ///
  /// The name spaces of the [introductory] fragment and [augmentations] are
  /// merged such that member fragments in augmentations are handled together
  /// with the member fragments declared in the introductory fragment.
  ///
  /// Type parameters are merged between the [introductory] fragment and the
  /// [augmentations].
  ///
  /// [reference] is the [Reference] used for the kernel node corresponding to
  /// the builder object in a previous incremental compilation.
  /// [createDeclaration] is used to create the declaration for a fragment.
  /// [createBuilder] is used to create the builder object from the
  ///
  /// [typeParametersMismatchMessage] and [typeParametersIntroductoryMessage]
  /// are used for reporting type parameter mismatches in
  /// [_augmentTypeParameters].
  void _createDeclarationBuilder<
    F extends DeclarationFragmentImpl,
    D,
    B extends DeclarationBuilder
  >({
    required F introductory,
    required List<Fragment>? augmentations,
    required Reference? reference,
    required D Function(F) createDeclaration,
    required B Function({
      required DeclarationNameSpaceBuilder nameSpaceBuilder,
      required List<SourceNominalParameterBuilder>? nominalParameters,
      required D introductory,
      required List<D> augmentations,
      required Modifiers modifiers,
    })
    createBuilder,
    required void Function(F fragment, B builder) setBuilder,
    required MessageCode typeParametersMismatchMessage,
    required MessageCode typeParametersIntroductoryMessage,
  }) {
    String name = introductory.name;
    DeclarationNameSpaceBuilder nameSpaceBuilder = introductory
        .toDeclarationNameSpaceBuilder();
    D introductoryDeclaration = createDeclaration(introductory);
    List<SourceNominalParameterBuilder>? nominalParameters =
        _typeParameterFactory.createNominalParameterBuilders(
          introductory.typeParameters,
        );
    introductory.nominalParameterNameSpace.addTypeParameters(
      _problemReporting,
      nominalParameters,
      ownerName: name,
      allowNameConflict: false,
    );

    Modifiers modifiers = introductory.modifiers;
    List<D> augmentationDeclarations = [];
    if (augmentations != null) {
      for (Fragment fragment in augmentations) {
        F augmentation = fragment as F;

        // TODO(johnniwinther): Check that other modifiers are consistent.
        if (augmentation.modifiers.declaresConstConstructor) {
          modifiers |= Modifiers.DeclaresConstConstructor;
        }
        augmentationDeclarations.add(createDeclaration(augmentation));
        nameSpaceBuilder.includeFragments(
          augmentation.toDeclarationNameSpaceBuilder(),
        );

        _augmentTypeParameters(
          declarationName: name,
          introductionUriOffset: introductory.uriOffset,
          augmentationUriOffset: augmentation.uriOffset,
          nominalParameters: nominalParameters,
          augmentationNominalParameterNameSpace:
              augmentation.nominalParameterNameSpace,
          augmentationTypeParameters: augmentation.typeParameters,
          typeParametersMismatchMessage: typeParametersMismatchMessage,
          typeParameterIntroductoryMessage: typeParametersIntroductoryMessage,
        );
      }
    }
    B builder = createBuilder(
      nameSpaceBuilder: nameSpaceBuilder,
      nominalParameters: nominalParameters,
      introductory: introductoryDeclaration,
      augmentations: augmentationDeclarations,
      modifiers: modifiers,
    );
    setBuilder(introductory, builder);
    introductory.bodyScope.declarationBuilder = builder;
    if (augmentations != null) {
      for (Fragment fragment in augmentations) {
        F augmentation = fragment as F;
        setBuilder(augmentation, builder);
        augmentation.bodyScope.declarationBuilder = builder;
      }
      augmentations.clear();
    }
    if (reference != null) {
      _loader.referenceMap.registerNamedBuilder(reference, builder);
    }
    _builderRegistry.registerBuilder(
      declaration: builder,
      uriOffset: introductory.uriOffset,
      inPatch: introductory.enclosingCompilationUnit.isPatch,
    );
  }

  void _createClassBuilderFromFragments(
    ClassFragment fragment,
    List<Fragment>? augmentations,
  ) {
    IndexedClass? indexedClass = _indexedLibrary?.lookupIndexedClass(
      fragment.name,
    );
    _createDeclarationBuilder(
      introductory: fragment,
      augmentations: augmentations,
      reference: indexedClass?.reference,
      createDeclaration: RegularClassDeclaration.new,
      createBuilder:
          ({
            required nameSpaceBuilder,
            required nominalParameters,
            required augmentations,
            required introductory,
            required modifiers,
          }) => new SourceClassBuilder(
            modifiers: modifiers,
            name: fragment.name,
            typeParameters: nominalParameters,
            typeParameterScope: fragment.typeParameterScope,
            nameSpaceBuilder: nameSpaceBuilder,
            libraryBuilder: _enclosingLibraryBuilder,
            fileUri: fragment.fileUri,
            nameOffset: fragment.nameOffset,
            indexedClass: indexedClass,
            introductory: introductory,
            augmentations: augmentations,
          ),
      setBuilder: (fragment, builder) => fragment.builder = builder,
      // TODO(johnniwinther): Use a distinct message for patch/augmentation
      //  and different kinds of declarations.
      typeParametersMismatchMessage: diag.patchClassTypeParametersMismatch,
      typeParametersIntroductoryMessage: diag.patchClassOrigin,
    );
  }

  void _createConstructorBuilderFromDeclarations(
    ConstructorDeclaration constructorDeclaration,
    List<ConstructorDeclaration> augmentationDeclarations, {
    required String name,
    required UriOffsetLength uriOffset,
    required bool isConst,
    required bool inPatch,
  }) {
    NameScheme nameScheme = new NameScheme(
      isInstanceMember: false,
      containerName: _containerName,
      containerType: _containerType,
      libraryName: _indexedLibrary != null
          ? new LibraryName(_indexedLibrary.library.reference)
          : _enclosingLibraryBuilder.libraryName,
    );

    ConstructorEncodingStrategy encodingStrategy =
        new ConstructorEncodingStrategy(
          _declarationBuilder!,
          isClosureContextLoweringEnabled:
              _loader.isClosureContextLoweringEnabled,
        );

    ConstructorReferences constructorReferences = new ConstructorReferences(
      name: name,
      nameScheme: nameScheme,
      indexedContainer: _indexedContainer,
      loader: _loader,
      declarationBuilder: _declarationBuilder,
    );

    SourceConstructorBuilder constructorBuilder = new SourceConstructorBuilder(
      name: name,
      libraryBuilder: _enclosingLibraryBuilder,
      declarationBuilder: _declarationBuilder,
      fileUri: uriOffset.fileUri,
      fileOffset: uriOffset.fileOffset,
      constructorReferences: constructorReferences,
      nameScheme: nameScheme,
      introductory: constructorDeclaration,
      augmentations: augmentationDeclarations,
      isConst: isConst,
    );
    constructorReferences.registerReference(
      _loader.referenceMap,
      constructorBuilder,
    );

    constructorDeclaration.createEncoding(
      problemReporting: _problemReporting,
      loader: _loader,
      declarationBuilder: _declarationBuilder,
      constructorBuilder: constructorBuilder,
      typeParameterFactory: _typeParameterFactory,
      encodingStrategy: encodingStrategy,
    );
    for (ConstructorDeclaration augmentation in augmentationDeclarations) {
      augmentation.createEncoding(
        problemReporting: _problemReporting,
        loader: _loader,
        declarationBuilder: _declarationBuilder,
        constructorBuilder: constructorBuilder,
        typeParameterFactory: _typeParameterFactory,
        encodingStrategy: encodingStrategy,
      );
    }
    _builderRegistry.registerBuilder(
      declaration: constructorBuilder,
      uriOffset: uriOffset,
      inPatch: inPatch,
    );
  }

  _Declaration? _createDeclarationFromFragment(
    Fragment fragment, {
    required bool inLibrary,
    required List<Fragment> unnamedFragments,
    required List<PrimaryConstructorBodyFragment>? primaryConstructorBodies,
  }) {
    switch (fragment) {
      case ClassFragment():
        return new _StandardFragmentDeclaration(
          _DeclarationKind.Class,
          fragment,
          displayName: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        );
      case EnumFragment():
        return new _StandardFragmentDeclaration(
          _DeclarationKind.Enum,
          fragment,
          displayName: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        );
      case ExtensionTypeFragment():
        return new _StandardFragmentDeclaration(
          _DeclarationKind.ExtensionType,
          fragment,
          displayName: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        );
      case MethodFragment():
        return new _StandardFragmentDeclaration(
          _DeclarationKind.Method,
          fragment,
          displayName: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          isStatic: inLibrary || fragment.modifiers.isStatic,
          inPatch:
              fragment.enclosingDeclaration?.isPatch ??
              fragment.enclosingCompilationUnit.isPatch,
          inLibrary: inLibrary,
        );
      case MixinFragment():
        return new _StandardFragmentDeclaration(
          _DeclarationKind.Mixin,
          fragment,
          displayName: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        );
      case NamedMixinApplicationFragment():
        return new _StandardFragmentDeclaration(
          _DeclarationKind.NamedMixinApplication,
          fragment,
          displayName: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        );
      case TypedefFragment():
        return new _StandardFragmentDeclaration(
          _DeclarationKind.Typedef,
          fragment,
          displayName: fragment.name,
          // TODO(johnniwinther): Support typedef augmentations.
          isAugment: false,
          inPatch: fragment.enclosingCompilationUnit.isPatch,
          inLibrary: true,
        );
      case ExtensionFragment():
        if (!fragment.isUnnamed) {
          return new _StandardFragmentDeclaration(
            _DeclarationKind.Extension,
            fragment,
            displayName: fragment.name,
            isAugment: fragment.modifiers.isAugment,
            inPatch: fragment.enclosingCompilationUnit.isPatch,
            inLibrary: true,
          );
        } else {
          unnamedFragments.add(fragment);
          return null;
        }
      case FactoryFragment():
        return new _FactoryConstructorDeclaration(
          new FactoryDeclarationImpl(fragment),
          name: fragment.name,
          displayName: fragment.constructorName.fullName,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingDeclaration.isPatch,
          inLibrary: inLibrary,
          isConst: fragment.modifiers.isConst,
          uriOffset: fragment.uriOffset,
        );
      case ConstructorFragment():
        return new _GenerativeConstructorDeclaration(
          new RegularConstructorDeclaration(fragment),
          name: fragment.name,
          displayName: fragment.constructorName.fullName,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingDeclaration.isPatch,
          inLibrary: inLibrary,
          isConst: fragment.modifiers.isConst,
          uriOffset: fragment.uriOffset,
        );
      case PrimaryConstructorFragment():
        PrimaryConstructorBodyFragment? bodyFragment;
        if (primaryConstructorBodies != null &&
            primaryConstructorBodies.isNotEmpty) {
          bodyFragment = primaryConstructorBodies.removeAt(0);
        }
        return new _GenerativeConstructorDeclaration(
          new PrimaryConstructorDeclaration(fragment, bodyFragment),
          name: fragment.name,
          displayName: fragment.constructorName.fullName,
          isAugment: fragment.modifiers.isAugment,
          inPatch: fragment.enclosingDeclaration.isPatch,
          inLibrary: inLibrary,
          isConst: fragment.modifiers.isConst,
          uriOffset: fragment.uriOffset,
        );
      case PrimaryConstructorBodyFragment():
        // Coverage-ignore(suite): Not run.
        throw new UnsupportedError("Unexpected primary constructor body.");
      case FieldFragment():
        RegularFieldDeclaration declaration = new RegularFieldDeclaration(
          fragment,
        );
        return new _FieldDeclaration(
          displayName: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          propertyKind: fragment.hasSetter
              ? _PropertyKind.Field
              : _PropertyKind.FinalField,
          isStatic: inLibrary || fragment.modifiers.isStatic,
          inPatch:
              fragment.enclosingDeclaration?.isPatch ??
              fragment.enclosingCompilationUnit.isPatch,
          inLibrary: inLibrary,
          uriOffset: fragment.uriOffset,
          declarations: new _PropertyDeclarations(
            field: declaration,
            getter: declaration,
            setter: fragment.hasSetter ? declaration : null,
          ),
        );
      case PrimaryConstructorFieldFragment():
        PrimaryConstructorFieldDeclaration declaration =
            new PrimaryConstructorFieldDeclaration(fragment);
        return new _FieldDeclaration(
          displayName: fragment.name,
          isAugment: false,
          propertyKind: fragment.hasSetter
              ? _PropertyKind.Field
              : _PropertyKind.FinalField,
          isStatic: false,
          inPatch: fragment.enclosingDeclaration.isPatch,
          inLibrary: false,
          uriOffset: fragment.uriOffset,
          declarations: new _PropertyDeclarations(
            field: declaration,
            getter: declaration,
            setter: fragment.hasSetter ? declaration : null,
          ),
        );
      case GetterFragment():
        return new _GetterDeclaration(
          displayName: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          propertyKind: _PropertyKind.Getter,
          isStatic: inLibrary || fragment.modifiers.isStatic,
          inPatch:
              fragment.enclosingDeclaration?.isPatch ??
              fragment.enclosingCompilationUnit.isPatch,
          inLibrary: inLibrary,
          uriOffset: fragment.uriOffset,
          declarations: new _PropertyDeclarations(
            getter: new RegularGetterDeclaration(fragment),
          ),
        );
      case SetterFragment():
        return new _SetterDeclaration(
          displayName: fragment.name,
          isAugment: fragment.modifiers.isAugment,
          propertyKind: _PropertyKind.Setter,
          isStatic: inLibrary || fragment.modifiers.isStatic,
          inPatch:
              fragment.enclosingDeclaration?.isPatch ??
              fragment.enclosingCompilationUnit.isPatch,
          inLibrary: inLibrary,
          uriOffset: fragment.uriOffset,
          declarations: new _PropertyDeclarations(
            setter: new RegularSetterDeclaration(fragment),
          ),
        );
      case EnumElementFragment():
        EnumElementDeclaration declaration = new EnumElementDeclaration(
          fragment,
        );
        return new _FieldDeclaration(
          displayName: fragment.name,
          isAugment: false,
          propertyKind: _PropertyKind.FinalField,
          isStatic: true,
          inPatch: fragment.enclosingDeclaration.isPatch,
          inLibrary: inLibrary,
          uriOffset: fragment.uriOffset,
          declarations: new _PropertyDeclarations(
            field: declaration,
            getter: declaration,
          ),
        );
    }
  }

  void _createEnumBuilderFromFragments(
    EnumFragment fragment,
    List<Fragment>? augmentations,
  ) {
    String name = fragment.name;
    IndexedClass? indexedClass = _indexedLibrary?.lookupIndexedClass(name);
    _createDeclarationBuilder(
      introductory: fragment,
      augmentations: augmentations,
      reference: indexedClass?.reference,
      createDeclaration: (fragment) =>
          new EnumDeclaration(fragment, _loader.target.underscoreEnumType),
      createBuilder:
          ({
            required augmentations,
            required introductory,
            required modifiers,
            required nameSpaceBuilder,
            required nominalParameters,
          }) => new SourceEnumBuilder(
            name: name,
            typeParameters: nominalParameters,
            underscoreEnumTypeBuilder: _loader.target.underscoreEnumType,
            enumElements: fragment.enumElements,
            libraryBuilder: _enclosingLibraryBuilder,
            fileUri: fragment.fileUri,
            startOffset: fragment.startOffset,
            nameOffset: fragment.nameOffset,
            endOffset: fragment.endOffset,
            indexedClass: indexedClass,
            typeParameterScope: fragment.typeParameterScope,
            nameSpaceBuilder: nameSpaceBuilder,
            introductory: introductory,
            augmentations: augmentations,
            modifiers: modifiers,
          ),
      setBuilder: (fragment, builder) => fragment.builder = builder,
      // TODO(johnniwinther): Use a distinct message for patch/augmentation
      //  and different kinds of declarations.
      typeParametersMismatchMessage: diag.patchClassTypeParametersMismatch,
      typeParametersIntroductoryMessage: diag.patchClassOrigin,
    );
  }

  void _createExtensionBuilderFromFragments(
    ExtensionFragment fragment,
    List<Fragment>? augmentations,
  ) {
    Reference? reference;
    if (!fragment.extensionName.isUnnamedExtension) {
      reference = _indexedLibrary?.lookupExtension(fragment.name);
    }
    _createDeclarationBuilder(
      introductory: fragment,
      augmentations: augmentations,
      reference: reference,
      createDeclaration: ExtensionDeclaration.new,
      createBuilder:
          ({
            required DeclarationNameSpaceBuilder nameSpaceBuilder,
            required List<SourceNominalParameterBuilder>? nominalParameters,
            required ExtensionDeclaration introductory,
            required List<ExtensionDeclaration> augmentations,
            required Modifiers modifiers,
          }) => new SourceExtensionBuilder(
            enclosingLibraryBuilder: _enclosingLibraryBuilder,
            fileUri: fragment.fileUri,
            startOffset: fragment.startOffset,
            nameOffset: fragment.nameOrExtensionOffset,
            endOffset: fragment.endOffset,
            modifiers: modifiers,
            extensionName: fragment.extensionName,
            typeParameters: nominalParameters,
            nameSpaceBuilder: nameSpaceBuilder,
            introductory: introductory,
            augmentations: augmentations,
            reference: reference,
            onType: fragment.onType,
          ),
      setBuilder: (fragment, builder) => fragment.builder = builder,
      // TODO(johnniwinther): Use a distinct message for patch/augmentation
      //  and different kinds of declarations.
      typeParametersMismatchMessage: diag.patchExtensionTypeParametersMismatch,
      typeParametersIntroductoryMessage: diag.patchExtensionOrigin,
    );
  }

  void _createExtensionTypeBuilderFragments(
    ExtensionTypeFragment fragment,
    List<Fragment>? augmentations,
  ) {
    IndexedContainer? indexedContainer = _indexedLibrary
        ?.lookupIndexedExtensionTypeDeclaration(fragment.name);
    List<PrimaryConstructorFieldFragment> primaryConstructorFields =
        fragment.primaryConstructorFields;
    PrimaryConstructorFieldFragment? representationFieldFragment;
    if (primaryConstructorFields.isNotEmpty) {
      representationFieldFragment = primaryConstructorFields.first;
    }
    _createDeclarationBuilder(
      introductory: fragment,
      augmentations: augmentations,
      reference: indexedContainer?.reference,
      createDeclaration: ExtensionTypeDeclaration.new,
      createBuilder:
          ({
            required DeclarationNameSpaceBuilder nameSpaceBuilder,
            required List<SourceNominalParameterBuilder>? nominalParameters,
            required ExtensionTypeDeclaration introductory,
            required List<ExtensionTypeDeclaration> augmentations,
            required Modifiers modifiers,
          }) => new SourceExtensionTypeDeclarationBuilder(
            name: fragment.name,
            enclosingLibraryBuilder: _enclosingLibraryBuilder,
            constructorReferences: fragment.constructorReferences,
            fileUri: fragment.fileUri,
            startOffset: fragment.startOffset,
            nameOffset: fragment.nameOffset,
            endOffset: fragment.endOffset,
            modifiers: modifiers,
            typeParameters: nominalParameters,
            interfaceBuilders: fragment.interfaces,
            nameSpaceBuilder: nameSpaceBuilder,
            introductory: introductory,
            augmentations: augmentations,
            indexedContainer: indexedContainer,
            representationFieldFragment: representationFieldFragment,
          ),
      setBuilder: (fragment, builder) => fragment.builder = builder,
      // TODO(johnniwinther): Use a distinct message for patch/augmentation
      //  and different kinds of declarations.
      typeParametersMismatchMessage: diag.patchClassTypeParametersMismatch,
      typeParametersIntroductoryMessage: diag.patchClassOrigin,
    );
  }

  void _createFactoryBuilderFromDeclarations(
    FactoryDeclaration introductory,
    List<FactoryDeclaration> augmentations, {
    required String name,
    required bool isConst,
    required UriOffsetLength uriOffset,
    required bool inPatch,
  }) {
    FactoryEncodingStrategy encodingStrategy = new FactoryEncodingStrategy(
      _declarationBuilder!,
    );

    NameScheme nameScheme = new NameScheme(
      containerName: _containerName,
      containerType: _containerType,
      isInstanceMember: false,
      libraryName: _indexedLibrary != null
          ? new LibraryName(_indexedLibrary.library.reference)
          : _enclosingLibraryBuilder.libraryName,
    );

    FactoryReferences factoryReferences = new FactoryReferences(
      name: name,
      nameScheme: nameScheme,
      indexedContainer: _indexedContainer,
      loader: _loader,
      declarationBuilder: _declarationBuilder,
    );

    bool isRedirectingFactory = introductory.isRedirectingFactory;
    for (FactoryDeclaration augmentation in augmentations) {
      if (augmentation.isRedirectingFactory) {
        isRedirectingFactory = true;
      }
    }

    SourceFactoryBuilder factoryBuilder = new SourceFactoryBuilder(
      name: name,
      libraryBuilder: _enclosingLibraryBuilder,
      declarationBuilder: _declarationBuilder,
      fileUri: uriOffset.fileUri,
      fileOffset: uriOffset.fileOffset,
      factoryReferences: factoryReferences,
      nameScheme: nameScheme,
      introductory: introductory,
      augmentations: augmentations,
      isConst: isConst,
    );
    if (isRedirectingFactory) {
      (_enclosingLibraryBuilder.redirectingFactoryBuilders ??= []).add(
        factoryBuilder,
      );
    }
    introductory.createEncoding(
      problemReporting: _problemReporting,
      declarationBuilder: _declarationBuilder,
      factoryBuilder: factoryBuilder,
      typeParameterFactory: _typeParameterFactory,
      encodingStrategy: encodingStrategy,
    );
    for (FactoryDeclaration augmentation in augmentations) {
      augmentation.createEncoding(
        problemReporting: _problemReporting,
        declarationBuilder: _declarationBuilder,
        factoryBuilder: factoryBuilder,
        typeParameterFactory: _typeParameterFactory,
        encodingStrategy: encodingStrategy,
      );
    }

    factoryReferences.registerReference(_loader.referenceMap, factoryBuilder);
    _builderRegistry.registerBuilder(
      declaration: factoryBuilder,
      uriOffset: uriOffset,
      inPatch: inPatch,
    );
  }

  void _createMethodBuilder(
    MethodFragment fragment,
    List<Fragment>? augmentations,
  ) {
    String name = fragment.name;
    final bool isInstanceMember =
        _containerType != ContainerType.Library && !fragment.modifiers.isStatic;

    _typeParameterFactory.createNominalParameterBuilders(
      fragment.declaredTypeParameters,
    );

    MethodEncodingStrategy encodingStrategy = new MethodEncodingStrategy(
      _declarationBuilder,
      isInstanceMember: isInstanceMember,
    );

    ProcedureKind kind = fragment.isOperator
        ? ProcedureKind.Operator
        : ProcedureKind.Method;

    final bool isExtensionMember = _containerType == ContainerType.Extension;
    final bool isExtensionTypeMember =
        _containerType == ContainerType.ExtensionType;

    NameScheme nameScheme = new NameScheme(
      containerName: _containerName,
      containerType: _containerType,
      isInstanceMember: isInstanceMember,
      libraryName: _indexedLibrary != null
          ? new LibraryName(_indexedLibrary.library.reference)
          : _enclosingLibraryBuilder.libraryName,
    );

    Reference? procedureReference;
    Reference? tearOffReference;
    IndexedContainer? indexedContainer = _indexedContainer ?? _indexedLibrary;

    if (indexedContainer != null) {
      Name nameToLookup = nameScheme.getProcedureMemberName(kind, name).name;
      procedureReference = indexedContainer.lookupGetterReference(nameToLookup);
      if ((isExtensionMember || isExtensionTypeMember) &&
          kind == ProcedureKind.Method) {
        tearOffReference = indexedContainer.lookupGetterReference(
          nameScheme.getProcedureMemberName(ProcedureKind.Getter, name).name,
        );
      }
    }

    Modifiers modifiers = fragment.modifiers;
    MethodDeclaration introductoryDeclaration = new MethodDeclarationImpl(
      fragment,
    );

    List<MethodDeclaration> augmentationDeclarations = [];
    if (augmentations != null) {
      for (Fragment augmentation in augmentations) {
        // Promote [augmentation] to [MethodFragment].
        augmentation as MethodFragment;

        augmentationDeclarations.add(new MethodDeclarationImpl(augmentation));

        _typeParameterFactory.createNominalParameterBuilders(
          augmentation.declaredTypeParameters,
        );

        if (!(augmentation.modifiers.isAbstract ||
            augmentation.modifiers.isExternal)) {
          modifiers -= Modifiers.Abstract;
          modifiers -= Modifiers.External;
        }
      }
    }

    SourceMethodBuilder methodBuilder = new SourceMethodBuilder(
      fileUri: fragment.fileUri,
      fileOffset: fragment.nameOffset,
      name: name,
      libraryBuilder: _enclosingLibraryBuilder,
      declarationBuilder: _declarationBuilder,
      isStatic: modifiers.isStatic,
      modifiers: modifiers,
      introductory: introductoryDeclaration,
      augmentations: augmentationDeclarations,
      nameScheme: nameScheme,
      reference: procedureReference,
      tearOffReference: tearOffReference,
    );
    fragment.builder = methodBuilder;
    if (augmentations != null) {
      for (Fragment augmentation in augmentations) {
        // Promote [augmentation] to [MethodFragment].
        augmentation as MethodFragment;

        augmentation.builder = methodBuilder;
      }
      augmentations.clear();
    }
    introductoryDeclaration.createEncoding(
      _problemReporting,
      methodBuilder,
      encodingStrategy,
      _typeParameterFactory,
    );
    for (MethodDeclaration augmentation in augmentationDeclarations) {
      augmentation.createEncoding(
        _problemReporting,
        methodBuilder,
        encodingStrategy,
        _typeParameterFactory,
      );
    }

    if (procedureReference != null) {
      _loader.referenceMap.registerNamedBuilder(
        procedureReference,
        methodBuilder,
      );
    }
    _builderRegistry.registerBuilder(
      declaration: methodBuilder,
      uriOffset: fragment.uriOffset,
      inPatch:
          fragment.enclosingDeclaration?.isPatch ??
          fragment.enclosingCompilationUnit.isPatch,
    );
  }

  void _createMixinBuilderFromFragments(
    MixinFragment fragment,
    List<Fragment>? augmentations,
  ) {
    String name = fragment.name;
    IndexedClass? indexedClass = _indexedLibrary?.lookupIndexedClass(name);
    _createDeclarationBuilder(
      introductory: fragment,
      augmentations: augmentations,
      reference: indexedClass?.reference,
      createDeclaration: MixinDeclaration.new,
      createBuilder:
          ({
            required augmentations,
            required introductory,
            required modifiers,
            required nameSpaceBuilder,
            required nominalParameters,
          }) => new SourceClassBuilder(
            modifiers: modifiers,
            name: name,
            typeParameters: fragment.typeParameterBuilders,
            typeParameterScope: fragment.typeParameterScope,
            nameSpaceBuilder: nameSpaceBuilder,
            libraryBuilder: _enclosingLibraryBuilder,
            fileUri: fragment.fileUri,
            nameOffset: fragment.nameOffset,
            indexedClass: indexedClass,
            introductory: introductory,
            augmentations: augmentations,
          ),
      setBuilder: (fragment, builder) => fragment.builder = builder,
      // TODO(johnniwinther): Use a distinct message for patch/augmentation
      //  and different kinds of declarations.
      typeParametersMismatchMessage: diag.patchClassTypeParametersMismatch,
      typeParametersIntroductoryMessage: diag.patchClassOrigin,
    );
  }

  void _createNamedMixinApplicationBuilder(
    NamedMixinApplicationFragment fragment,
  ) {
    List<TypeBuilder> mixins = fragment.mixins.toList();
    TypeBuilder mixin = mixins.removeLast();
    ClassDeclaration classDeclaration = new NamedMixinApplication(
      fragment,
      mixins,
    );

    String name = fragment.name;

    IndexedClass? referencesFromIndexedClass = _indexedLibrary
        ?.lookupIndexedClass(name);

    _typeParameterFactory.createNominalParameterBuilders(
      fragment.typeParameters,
    );
    fragment.nominalParameterNameSpace.addTypeParameters(
      _problemReporting,
      fragment.typeParameterBuilders,
      ownerName: name,
      allowNameConflict: false,
    );
    LookupScope typeParameterScope = TypeParameterScope.fromList(
      fragment.enclosingScope,
      fragment.typeParameterBuilders,
    );
    DeclarationNameSpaceBuilder nameSpaceBuilder =
        new DeclarationNameSpaceBuilder.empty();
    SourceClassBuilder classBuilder = new SourceClassBuilder(
      modifiers: fragment.modifiers | Modifiers.NamedMixinApplication,
      name: name,
      typeParameters: fragment.typeParameterBuilders,
      typeParameterScope: typeParameterScope,
      nameSpaceBuilder: nameSpaceBuilder,
      libraryBuilder: _enclosingLibraryBuilder,
      fileUri: fragment.fileUri,
      nameOffset: fragment.nameOffset,
      indexedClass: referencesFromIndexedClass,
      mixedInTypeBuilder: mixin,
      introductory: classDeclaration,
    );
    _mixinApplications[classBuilder] = mixin;
    fragment.builder = classBuilder;
    if (referencesFromIndexedClass != null) {
      _loader.referenceMap.registerNamedBuilder(
        referencesFromIndexedClass.reference,
        classBuilder,
      );
    }
    _builderRegistry.registerBuilder(
      declaration: classBuilder,
      uriOffset: fragment.uriOffset,
      inPatch: fragment.enclosingCompilationUnit.isPatch,
    );
  }

  void _createPropertyBuilder({
    required String name,
    required UriOffsetLength uriOffset,
    required FieldDeclaration? fieldDeclaration,
    required GetterDeclaration? getterDeclaration,
    required List<GetterDeclaration> getterAugmentations,
    required SetterDeclaration? setterDeclaration,
    required List<SetterDeclaration> setterAugmentations,
    required bool isStatic,
    required bool inPatch,
  }) {
    bool isInstanceMember =
        _containerType != ContainerType.Library && !isStatic;

    bool fieldIsLateWithLowering = false;
    if (fieldDeclaration != null) {
      fieldIsLateWithLowering =
          fieldDeclaration.isLate &&
          (_loader.target.backendTarget.isLateFieldLoweringEnabled(
                hasInitializer: fieldDeclaration.hasInitializer,
                isFinal: fieldDeclaration.isFinal,
                isStatic: !isInstanceMember,
              ) ||
              (_loader.target.backendTarget.useStaticFieldLowering &&
                  !isInstanceMember));
    }

    PropertyEncodingStrategy propertyEncodingStrategy =
        new PropertyEncodingStrategy(
          _declarationBuilder,
          isInstanceMember: isInstanceMember,
        );

    NameScheme nameScheme = new NameScheme(
      isInstanceMember: isInstanceMember,
      containerName: _containerName,
      containerType: _containerType,
      libraryName: _indexedLibrary != null
          ? new LibraryName(_indexedLibrary.reference)
          : _enclosingLibraryBuilder.libraryName,
    );
    IndexedContainer? indexedContainer = _indexedContainer ?? _indexedLibrary;

    PropertyReferences references = new PropertyReferences(
      name,
      nameScheme,
      indexedContainer,
      fieldIsLateWithLowering: fieldIsLateWithLowering,
    );

    SourcePropertyBuilder propertyBuilder = new SourcePropertyBuilder(
      fileUri: uriOffset.fileUri,
      fileOffset: uriOffset.fileOffset,
      name: name,
      libraryBuilder: _enclosingLibraryBuilder,
      declarationBuilder: _declarationBuilder,
      fieldDeclaration: fieldDeclaration,
      getterDeclaration: getterDeclaration,
      getterAugmentations: getterAugmentations,
      setterDeclaration: setterDeclaration,
      setterAugmentations: setterAugmentations,
      isStatic: isStatic,
      nameScheme: nameScheme,
      references: references,
    );

    fieldDeclaration?.createFieldEncoding(propertyBuilder);

    getterDeclaration?.createGetterEncoding(
      _problemReporting,
      propertyBuilder,
      propertyEncodingStrategy,
      _typeParameterFactory,
    );
    for (GetterDeclaration augmentation in getterAugmentations) {
      augmentation.createGetterEncoding(
        _problemReporting,
        propertyBuilder,
        propertyEncodingStrategy,
        _typeParameterFactory,
      );
    }

    setterDeclaration?.createSetterEncoding(
      _problemReporting,
      propertyBuilder,
      propertyEncodingStrategy,
      _typeParameterFactory,
    );
    for (SetterDeclaration augmentation in setterAugmentations) {
      augmentation.createSetterEncoding(
        _problemReporting,
        propertyBuilder,
        propertyEncodingStrategy,
        _typeParameterFactory,
      );
    }

    references.registerReference(_loader.referenceMap, propertyBuilder);

    _builderRegistry.registerBuilder(
      declaration: propertyBuilder,
      uriOffset: uriOffset,
      inPatch: inPatch,
    );
  }

  void _createTypedefBuilder(TypedefFragment fragment) {
    List<SourceNominalParameterBuilder>? nominalParameters =
        _typeParameterFactory.createNominalParameterBuilders(
          fragment.typeParameters,
        );
    if (nominalParameters != null) {
      for (SourceNominalParameterBuilder typeParameter in nominalParameters) {
        typeParameter.varianceCalculationValue =
            VarianceCalculationValue.pending;
      }
    }
    fragment.nominalParameterNameSpace.addTypeParameters(
      _problemReporting,
      nominalParameters,
      ownerName: fragment.name,
      allowNameConflict: true,
    );

    Reference? reference = _indexedLibrary?.lookupTypedef(fragment.name);
    SourceTypeAliasBuilder typedefBuilder = new SourceTypeAliasBuilder(
      name: fragment.name,
      enclosingLibraryBuilder: _enclosingLibraryBuilder,
      fileUri: fragment.fileUri,
      fileOffset: fragment.nameOffset,
      fragment: fragment,
      reference: reference,
    );
    if (reference != null) {
      _loader.referenceMap.registerNamedBuilder(reference, typedefBuilder);
    }
    _builderRegistry.registerBuilder(
      declaration: typedefBuilder,
      uriOffset: fragment.uriOffset,
      inPatch: fragment.enclosingCompilationUnit.isPatch,
    );
  }
}

abstract class BuilderRegistry {
  void registerBuilder({
    required NamedBuilder declaration,
    required UriOffsetLength uriOffset,
    required bool inPatch,
  });
}

class EnumValuesDeclaration extends _PropertyDeclaration
    implements SyntheticDeclaration {
  new({
    required String name,
    required UriOffsetLength uriOffset,
    required FieldDeclaration field,
    required GetterDeclaration getter,
  }) : super(
         propertyKind: _PropertyKind.FinalField,
         displayName: name,
         isAugment: false,
         inPatch: false,
         inLibrary: false,
         uriOffset: uriOffset,
         declarations: new _PropertyDeclarations(field: field, getter: getter),
       );
  @override
  _Declaration createDeclaration() {
    return this;
  }

  @override
  void reportDuplicateDeclaration(
    ProblemReporting problemReporting,
    _Declaration declaration,
  ) {
    problemReporting.addProblem2(
      diag.enumContainsValuesDeclaration,
      declaration.uriOffset,
    );
  }

  @override
  void reportStaticInstanceConflict(
    ProblemReporting problemReporting,
    _PropertyDeclaration declaration,
  ) {
    problemReporting.addProblem2(
      diag.instanceAndSynthesizedStaticConflict.withArguments(
        name: displayName,
      ),
      declaration.uriOffset,
    );
  }

  @override
  _PreBuilder _createPreBuilder() {
    return new _PropertyPreBuilder.forField(this);
  }
}

abstract class SyntheticDeclaration {
  _Declaration createDeclaration();
}

sealed class _ConstructorDeclaration extends _Declaration {
  final bool isConst;

  @override
  final UriOffsetLength uriOffset;

  new(
    super.kind, {
    required super.displayName,
    required super.isAugment,
    required super.inPatch,
    required super.inLibrary,
    required this.isConst,
    required this.uriOffset,
  });

  @override
  void registerPreBuilder(
    ProblemReporting problemReporting,
    List<_PreBuilder> nonConstructorPreBuilders,
    List<_PreBuilder> constructorPreBuilders,
  ) {
    _addPreBuilder(
      problemReporting,
      constructorPreBuilders,
      nonConstructorPreBuilders,
    );
  }
}

/// [_PreBuilder] for generative and factory constructors.
sealed class _ConstructorPreBuilder<T extends _ConstructorDeclaration>
    extends _PreBuilder {
  final T _declaration;
  final List<T> _augmentations = [];

  // TODO(johnniwinther): Report error if [fragment] is augmenting.
  new(this._declaration);

  @override
  bool absorbFragment(
    ProblemReporting problemReporting,
    _Declaration declaration,
  ) {
    if (declaration.isAugment) {
      if (declaration is T && declaration.kind == _declaration.kind) {
        // Example:
        //
        //    class A {
        //      A();
        //      augment A();
        //    }
        //
        _augmentations.add(declaration);
        return true;
      } else {
        // Example:
        //
        //    class A {
        //      A();
        //      augment void A() {}
        //    }
        //
        // TODO(johnniwinther): Report augmentation conflict.
        return false;
      }
    } else {
      // Example:
      //
      //    class A {
      //      A();
      //      A();
      //    }
      //
      _declaration.reportDuplicateDeclaration(problemReporting, declaration);
      return false;
    }
  }

  @override
  void checkFragment(
    ProblemReporting problemReporting,
    _Declaration nonConstructorDeclaration,
  ) {
    // Check conflict with non-constructor.
    if (nonConstructorDeclaration.isStatic) {
      // Examples:
      //
      //    class A {
      //      A.foo();
      //      static void foo() {}
      //    }
      //
      // and
      //
      //    class A {
      //      factory A.foo() => throw '';
      //      static void foo() {}
      //    }
      //
      _declaration.reportConstructorConflict(
        problemReporting,
        nonConstructorDeclaration,
      );
    }
  }
}

abstract class _Declaration {
  final _DeclarationKind kind;
  final String displayName;
  final bool isAugment;
  final bool inPatch;
  final bool inLibrary;
  final bool isStatic;

  new(
    this.kind, {
    required this.displayName,
    required this.isAugment,
    required this.inPatch,
    required this.inLibrary,
    this.isStatic = true,
  });

  UriOffsetLength get uriOffset;

  void registerPreBuilder(
    ProblemReporting problemReporting,
    List<_PreBuilder> nonConstructorPreBuilders,
    List<_PreBuilder> constructorPreBuilders,
  );

  void reportConstructorConflict(
    ProblemReporting problemReporting,
    _Declaration declaration,
  );

  /// Reports that [declaration] conflicts with this declaration.
  void reportDuplicateDeclaration(
    ProblemReporting problemReporting,
    _Declaration declaration,
  );

  /// Adds this declaration to [thesePreBuilders] and checks it against the
  /// [otherPreBuilders].
  ///
  /// If this declaration can be absorbed into an existing declaration in
  /// [thesePreBuilders], it is added to the corresponding [_PreBuilder].
  /// Otherwise a new [_PreBuilder] is created and added to [thesePreBuilders].
  void _addPreBuilder(
    ProblemReporting problemReporting,
    List<_PreBuilder> thesePreBuilders,
    List<_PreBuilder> otherPreBuilders,
  ) {
    for (_PreBuilder existingPreBuilder in thesePreBuilders) {
      if (existingPreBuilder.absorbFragment(problemReporting, this)) {
        return;
      }
    }
    _checkAugmentation(problemReporting, this);
    thesePreBuilders.add(_createPreBuilder());
    if (otherPreBuilders.isNotEmpty) {
      otherPreBuilders.first.checkFragment(problemReporting, this);
    }
  }

  /// Creates the [_PreBuilder] for this [_Declaration].
  ///
  /// This is called for the declarations that aren't absorbed into a
  /// pre-existing declaration.
  _PreBuilder _createPreBuilder();
}

enum _DeclarationKind {
  Constructor,
  Factory,
  Class,
  Mixin,
  NamedMixinApplication,
  Enum,
  Extension,
  ExtensionType,
  Typedef,
  Method,
  Property,
}

/// [_PreBuilder] for non-constructor, non-property declarations.
class _DeclarationPreBuilder extends _PreBuilder {
  final _StandardDeclaration _declaration;
  final List<_StandardDeclaration> _augmentations = [];

  // TODO(johnniwinther): Report error if [fragment] is augmenting.
  new(this._declaration);

  @override
  bool absorbFragment(
    ProblemReporting problemReporting,
    _Declaration declaration,
  ) {
    if (declaration.isAugment) {
      if (declaration.kind == _declaration.kind) {
        // Example:
        //
        //    class Foo {}
        //    augment class Foo {}
        //
        _augmentations.add(declaration as _StandardDeclaration);
        return true;
      } else {
        // Example:
        //
        //    class Foo {}
        //    augment extension Foo {}
        //
        // TODO(johnniwinther): Report augmentation conflict.
        return false;
      }
    } else {
      // Examples:
      //
      //    class Foo {}
      //    set Foo(_) {}
      //
      // and
      //
      //    class Foo {}
      //    class Foo {}
      //
      _declaration.reportDuplicateDeclaration(problemReporting, declaration);
      return false;
    }
  }

  @override
  void checkFragment(
    ProblemReporting problemReporting,
    _Declaration constructorDeclaration,
  ) {
    // Check conflict with constructor.
    if (_declaration.isStatic) {
      // Examples:
      //
      //    class A {
      //      static void foo() {}
      //      A.foo();
      //    }
      //
      // and
      //
      //    class A {
      //      static void foo() {}
      //      factory A.foo() => throw '';
      //    }
      //
      _declaration.reportConstructorConflict(
        problemReporting,
        constructorDeclaration,
      );
    }
  }

  @override
  void createBuilders(BuilderFactory builderFactory) {
    builderFactory._createBuilder(
      _declaration._fragment,
      augmentations: _augmentations.map((f) => f._fragment).toList(),
    );
  }
}

mixin _DeclarationReportingMixin implements _Declaration {
  @override
  void reportDuplicateDeclaration(
    ProblemReporting problemReporting,
    _Declaration declaration,
  ) {
    // TODO(johnniwinther): Mark [declaration] as a duplicate so we don't
    //  report duplicates on duplicates.
    _reportDuplicateDeclaration(
      problemReporting,
      name: displayName,
      existingUriOffset: uriOffset,
      newUriOffset: declaration.uriOffset,
      existingKind: _getExistingKindForDuplicate(declaration),
      newIsSetter:
          declaration is _PropertyDeclaration &&
          declaration.propertyKind == _PropertyKind.Setter,
    );
  }

  _ExistingKind _getExistingKindForDuplicate(_Declaration declaration) =>
      _ExistingKind.Getable;

  void _reportDuplicateDeclaration(
    ProblemReporting problemReporting, {
    required String name,
    required UriOffsetLength existingUriOffset,
    required UriOffsetLength newUriOffset,
    required _ExistingKind existingKind,
    required bool newIsSetter,
  }) {
    switch (existingKind) {
      case _ExistingKind.Getable:
        if (newIsSetter) {
          problemReporting.addProblem2(
            diag.setterConflictsWithDeclaration.withArguments(setterName: name),
            newUriOffset,
            context: [
              diag.setterConflictsWithDeclarationCause
                  .withArguments(setterName: name)
                  .withLocation2(existingUriOffset),
            ],
          );
          return;
        }
        break;
      case _ExistingKind.ExplicitSetter:
        if (!newIsSetter) {
          problemReporting.addProblem2(
            diag.declarationConflictsWithSetter.withArguments(setterName: name),
            newUriOffset,
            context: <LocatedMessage>[
              diag.declarationConflictsWithSetterCause
                  .withArguments(setterName: name)
                  .withLocation2(existingUriOffset),
            ],
          );
          return;
        }
        break;
      case _ExistingKind.ImplicitSetter:
        problemReporting.addProblem2(
          diag.conflictsWithImplicitSetter.withArguments(fieldName: name),
          newUriOffset,
          context: [
            diag.conflictsWithImplicitSetterCause
                .withArguments(fieldName: name)
                .withLocation2(existingUriOffset),
          ],
        );
        return;
    }

    problemReporting.addProblem2(
      diag.duplicatedDeclaration.withArguments(name: name),
      newUriOffset,
      context: <LocatedMessage>[
        diag.duplicatedDeclarationCause
            .withArguments(name: name)
            .withLocation2(existingUriOffset),
      ],
    );
  }
}

enum _ExistingKind { Getable, ExplicitSetter, ImplicitSetter }

class _FactoryConstructorDeclaration extends _ConstructorDeclaration
    with _DeclarationReportingMixin {
  final String _name;
  final FactoryDeclaration _declaration;

  new(
    this._declaration, {
    required String name,
    required super.displayName,
    required super.isAugment,
    required super.inPatch,
    required super.inLibrary,
    required super.isConst,
    required super.uriOffset,
  }) : _name = name,
       super(_DeclarationKind.Factory);

  @override
  void reportConstructorConflict(
    ProblemReporting problemReporting,
    _Declaration nonConstructorDeclaration,
  ) {
    // Example:
    //
    //    class A {
    //      factory A.foo() => throw '';
    //      static void foo() {}
    //    }
    //
    problemReporting.addProblem2(
      diag.memberConflictsWithFactory.withArguments(factoryName: displayName),
      nonConstructorDeclaration.uriOffset,
      context: [
        diag.memberConflictsWithFactoryCause
            .withArguments(factoryName: displayName)
            .withLocation2(uriOffset),
      ],
    );
  }

  @override
  _PreBuilder _createPreBuilder() =>
      new _FactoryConstructorPreBuilder(_name, this);
}

class _FactoryConstructorPreBuilder
    extends _ConstructorPreBuilder<_FactoryConstructorDeclaration> {
  final String _name;

  new(this._name, super._declaration);

  @override
  void createBuilders(BuilderFactory builderFactory) {
    builderFactory._createFactoryBuilderFromDeclarations(
      _declaration._declaration,
      _augmentations.map((a) => a._declaration).toList(),
      name: _name,
      uriOffset: _declaration.uriOffset,
      isConst: _declaration.isConst,
      inPatch: _declaration.inPatch,
    );
  }
}

class _FieldDeclaration extends _PropertyDeclaration
    with _DeclarationReportingMixin {
  new({
    required super.displayName,
    required super.isAugment,
    required super.inPatch,
    required super.inLibrary,
    required super.propertyKind,
    required super.declarations,
    required super.uriOffset,
    super.isStatic,
  });

  @override
  _PreBuilder _createPreBuilder() => new _PropertyPreBuilder.forField(this);

  @override
  _ExistingKind _getExistingKindForDuplicate(_Declaration declaration) {
    bool newIsSetter =
        declaration is _PropertyDeclaration &&
        declaration.propertyKind == _PropertyKind.Setter;
    return newIsSetter ? _ExistingKind.ImplicitSetter : _ExistingKind.Getable;
  }
}

mixin _FragmentDeclarationMixin implements _Declaration {
  @override
  UriOffsetLength get uriOffset => _fragment.uriOffset;

  Fragment get _fragment;

  @override
  String toString() => _fragment.toString();
}

class _GenerativeConstructorDeclaration extends _ConstructorDeclaration
    with _DeclarationReportingMixin {
  final String _name;
  final ConstructorDeclaration _declaration;

  new(
    this._declaration, {
    required String name,
    required super.displayName,
    required super.isAugment,
    required super.inPatch,
    required super.inLibrary,
    required super.isConst,
    required super.uriOffset,
  }) : _name = name,
       super(_DeclarationKind.Constructor);

  @override
  void reportConstructorConflict(
    ProblemReporting problemReporting,
    _Declaration nonConstructorDeclaration,
  ) {
    // Example:
    //
    //    class A {
    //      A.foo();
    //      static void foo() {}
    //    }
    //
    problemReporting.addProblem2(
      diag.memberConflictsWithConstructor.withArguments(
        constructorName: displayName,
      ),
      nonConstructorDeclaration.uriOffset,
      context: [
        diag.memberConflictsWithConstructorCause
            .withArguments(constructorName: displayName)
            .withLocation2(uriOffset),
      ],
    );
  }

  @override
  _PreBuilder _createPreBuilder() =>
      new _GenerativeConstructorPreBuilder(_name, this);
}

class _GenerativeConstructorPreBuilder
    extends _ConstructorPreBuilder<_GenerativeConstructorDeclaration> {
  final String _name;

  new(this._name, super._declaration);

  @override
  void createBuilders(BuilderFactory builderFactory) {
    builderFactory._createConstructorBuilderFromDeclarations(
      _declaration._declaration,
      _augmentations.map((a) => a._declaration).toList(),
      name: _name,
      uriOffset: _declaration.uriOffset,
      isConst: _declaration.isConst,
      inPatch: _declaration.inPatch,
    );
  }
}

class _GetterDeclaration extends _PropertyDeclaration
    with _DeclarationReportingMixin {
  new({
    required super.displayName,
    required super.isAugment,
    required super.inPatch,
    required super.inLibrary,
    required super.propertyKind,
    required super.declarations,
    required super.uriOffset,
    super.isStatic,
  });

  @override
  _PreBuilder _createPreBuilder() => new _PropertyPreBuilder.forGetter(this);
}

abstract class _NonConstructorDeclaration extends _Declaration {
  new(
    super.kind, {
    required super.displayName,
    required super.isAugment,
    required super.inPatch,
    required super.inLibrary,
    super.isStatic,
  });

  @override
  void registerPreBuilder(
    ProblemReporting problemReporting,
    List<_PreBuilder> nonConstructorPreBuilders,
    List<_PreBuilder> constructorPreBuilders,
  ) {
    _addPreBuilder(
      problemReporting,
      nonConstructorPreBuilders,
      constructorPreBuilders,
    );
  }

  @override
  void reportConstructorConflict(
    ProblemReporting problemReporting,
    _Declaration constructorDeclaration,
  ) {
    if (constructorDeclaration.kind == _DeclarationKind.Constructor) {
      // Example:
      //
      //    class A {
      //      static int get foo => 42;
      //      A.foo();
      //    }
      //
      problemReporting.addProblem2(
        diag.constructorConflictsWithMember.withArguments(
          memberName: displayName,
        ),
        constructorDeclaration.uriOffset,
        context: [
          diag.constructorConflictsWithMemberCause
              .withArguments(memberName: displayName)
              .withLocation2(uriOffset),
        ],
      );
    } else {
      assert(
        constructorDeclaration.kind == _DeclarationKind.Factory,
        "Unexpected constructor kind $constructorDeclaration",
      );
      // Example:
      //
      //    class A {
      //      static int get foo => 42;
      //      factory A.foo() => throw '';
      //    }
      //
      problemReporting.addProblem2(
        diag.factoryConflictsWithMember.withArguments(memberName: displayName),
        constructorDeclaration.uriOffset,
        context: [
          diag.factoryConflictsWithMemberCause
              .withArguments(memberName: displayName)
              .withLocation2(uriOffset),
        ],
      );
    }
  }
}

/// A [_PreBuilder] is a precursor to a [Builder] with subclasses for
/// properties, constructors, and other declarations.
sealed class _PreBuilder {
  /// Tries to include [declaration] in this [_PreBuilder].
  ///
  /// If [declaration] can be absorbed, `true` is returned. Otherwise an error
  /// is reported and `false` is returned.
  bool absorbFragment(
    ProblemReporting problemReporting,
    _Declaration declaration,
  );

  /// Checks with [declaration] conflicts with this [_PreBuilder].
  ///
  /// This is called between constructors and non-constructors which do not
  /// occupy the same name space but can only co-exist if the non-constructor
  /// is not static.
  void checkFragment(
    ProblemReporting problemReporting,
    _Declaration declaration,
  );

  /// Creates [Builder]s for the fragments absorbed into this [_PreBuilder],
  /// using [BuilderFactory] to create a [Builder] for a single [Fragment].
  ///
  /// If `conflictingSetter` is `true`, the created [Builder] must be marked
  /// as a conflicting setter. This is needed to ensure that we don't create
  /// conflicting AST nodes: Normally we only create [Builder]s for
  /// non-duplicate declarations, but because setters are store in a separate
  /// map the [NameSpace], they are not directly marked as duplicate if they
  /// do not conflict with other setters.
  void createBuilders(BuilderFactory builderFactory);
}

abstract class _PropertyDeclaration extends _NonConstructorDeclaration {
  final _PropertyKind propertyKind;
  final _PropertyDeclarations declarations;

  @override
  final UriOffsetLength uriOffset;

  new({
    required super.displayName,
    required super.isAugment,
    required super.inPatch,
    required super.inLibrary,
    required this.propertyKind,
    required this.declarations,
    required this.uriOffset,
    super.isStatic,
  }) : super(_DeclarationKind.Property);

  void reportStaticInstanceConflict(
    ProblemReporting problemReporting,
    _PropertyDeclaration declaration,
  ) {
    if (isStatic) {
      problemReporting.addProblem2(
        diag.instanceConflictsWithStatic.withArguments(
          propertyName: displayName,
        ),
        declaration.uriOffset,
        context: [
          diag.instanceConflictsWithStaticCause
              .withArguments(propertyName: displayName)
              .withLocation2(uriOffset),
        ],
      );
    } else {
      problemReporting.addProblem2(
        diag.staticConflictsWithInstance.withArguments(
          propertyName: displayName,
        ),
        declaration.uriOffset,
        context: [
          diag.staticConflictsWithInstanceCause
              .withArguments(propertyName: displayName)
              .withLocation2(uriOffset),
        ],
      );
    }
  }
}

class _PropertyDeclarations {
  final FieldDeclaration? field;
  final GetterDeclaration? getter;
  final SetterDeclaration? setter;

  new({this.field, this.getter, this.setter});
}

enum _PropertyKind { Getter, Setter, Field, FinalField }

/// [_PreBuilder] for properties, i.e. fields, getters and setters.
class _PropertyPreBuilder extends _PreBuilder {
  final bool inPatch;
  final String name;
  final UriOffsetLength uriOffset;
  final bool isStatic;
  _PropertyDeclaration? _getterDeclaration;
  _PropertyDeclaration? _setterDeclaration;
  List<GetterDeclaration> _getterAugmentations = [];
  List<SetterDeclaration> _setterAugmentations = [];

  // TODO(johnniwinther): Report error if [field] is augmenting.
  new forField(_PropertyDeclaration field)
    : isStatic = field.isStatic,
      inPatch = field.inPatch,
      name = field.displayName,
      uriOffset = field.uriOffset,
      _getterDeclaration = field,
      _setterDeclaration = field.propertyKind == _PropertyKind.Field
          ? field
          : null {
    _PropertyDeclarations declarations = field.declarations;
    assert(
      declarations.field != null,
      "Unexpected field declaration from field ${field}.",
    );
    assert(
      declarations.getter != null,
      "Unexpected getter declaration from field ${field}.",
    );
    assert(
      (declarations.setter != null) ==
          (_getterDeclaration!.propertyKind == _PropertyKind.Field),
      "Unexpected setter declaration from field ${field}.",
    );
  }

  // TODO(johnniwinther): Report error if [getter] is augmenting.
  new forGetter(_PropertyDeclaration getter)
    : isStatic = getter.isStatic,
      inPatch = getter.inPatch,
      name = getter.displayName,
      uriOffset = getter.uriOffset,
      _getterDeclaration = getter {
    _PropertyDeclarations declarations = getter.declarations;
    assert(
      declarations.field == null,
      "Unexpected field declaration from getter ${getter}.",
    );
    assert(
      declarations.getter != null,
      "Unexpected getter declaration from getter ${getter}.",
    );
    assert(
      declarations.setter == null,
      "Unexpected setter declaration from getter ${getter}.",
    );
  }

  // TODO(johnniwinther): Report error if [setter] is augmenting.
  new forSetter(_PropertyDeclaration setter)
    : isStatic = setter.isStatic,
      inPatch = setter.inPatch,
      name = setter.displayName,
      uriOffset = setter.uriOffset,
      _setterDeclaration = setter {
    _PropertyDeclarations declarations = setter.declarations;
    assert(
      declarations.field == null,
      "Unexpected field declaration from setter ${setter}.",
    );
    assert(
      declarations.getter == null,
      "Unexpected getter declaration from setter ${setter}.",
    );
    assert(
      declarations.setter != null,
      "Unexpected setter declaration from setter ${setter}.",
    );
  }

  @override
  bool absorbFragment(
    ProblemReporting problemReporting,
    _Declaration declaration,
  ) {
    if (declaration is! _PropertyDeclaration) {
      if (_getterDeclaration != null) {
        // Example:
        //
        //    int get foo => 42;
        //    void foo() {}
        //
        _getterDeclaration!.reportDuplicateDeclaration(
          problemReporting,
          declaration,
        );
      } else {
        assert(_setterDeclaration != null);
        // Example:
        //
        //    void set foo(_) {}
        //    void foo() {}
        //
        _setterDeclaration!.reportDuplicateDeclaration(
          problemReporting,
          declaration,
        );
      }
      return false;
    }

    _PropertyKind? propertyKind = declaration.propertyKind;
    switch (propertyKind) {
      case _PropertyKind.Getter:
        if (_getterDeclaration == null) {
          // Example:
          //
          //    void set foo(_) {}
          //    int get foo => 42;
          //
          if (declaration.isAugment) {
            // Example:
            //
            //    void set foo(_) {}
            //    augment int get foo => 42;
            //
            // TODO(johnniwinther): Report error.
          }
          if (declaration.isStatic != isStatic) {
            // Examples:
            //
            //    class A {
            //      void set foo(_) {}
            //      static int get foo => 42;
            //    }
            //
            // and
            //
            //    class A {
            //      static void set foo(_) {}
            //      int get foo => 42;
            //    }
            //
            _setterDeclaration!.reportStaticInstanceConflict(
              problemReporting,
              declaration,
            );
            return false;
          } else {
            _PropertyDeclarations declarations = declaration.declarations;
            assert(
              declarations.field == null,
              "Unexpected field declaration from getter "
              "${declaration}.",
            );
            assert(
              declarations.setter == null,
              "Unexpected setter declaration from getter "
              "${declaration}.",
            );
            _getterDeclaration = declaration;
            return true;
          }
        } else {
          if (declaration.isAugment) {
            // Example:
            //
            //    int get foo => 42;
            //    augment int get foo => 87;
            //
            _PropertyDeclarations declarations = declaration.declarations;
            assert(
              declarations.field == null,
              "Unexpected field declaration from getter "
              "${declaration}.",
            );
            assert(
              declarations.setter == null,
              "Unexpected setter declaration from getter "
              "${declaration}.",
            );
            _getterAugmentations.add(declarations.getter!);
            return true;
          } else {
            // Example:
            //
            //    int get foo => 42;
            //    int get foo => 87;
            //
            _getterDeclaration!.reportDuplicateDeclaration(
              problemReporting,
              declaration,
            );
            return false;
          }
        }
      case _PropertyKind.Setter:
        if (_setterDeclaration == null) {
          // Examples:
          //
          //    int get foo => 42;
          //    void set foo(_) {}
          //
          //    final int bar = 42;
          //    void set bar(_) {}
          //
          if (declaration.isAugment) {
            // Example:
            //
            //    int get foo => 42;
            //    augment void set foo(_) {}
            //
            // TODO(johnniwinther): Report error.
          }
          if (declaration.isStatic != isStatic) {
            // Examples:
            //
            //    class A {
            //      int get foo => 42;
            //      static void set foo(_) {}
            //    }
            //
            // and
            //
            //    class A {
            //      static int get foo => 42;
            //      void set foo(_) {}
            //    }
            //
            _getterDeclaration!.reportStaticInstanceConflict(
              problemReporting,
              declaration,
            );
            return false;
          } else {
            _PropertyDeclarations declarations = declaration.declarations;
            assert(
              declarations.field == null,
              "Unexpected field declaration from setter "
              "${declaration}.",
            );
            assert(
              declarations.getter == null,
              "Unexpected getter declaration from setter "
              "${declaration}.",
            );
            _setterDeclaration = declaration;
            return true;
          }
        } else {
          if (declaration.isAugment) {
            // Example:
            //
            //    void set foo(_) {}
            //    augment void set foo(_) {}
            //
            _PropertyDeclarations declarations = declaration.declarations;
            assert(
              declarations.field == null,
              "Unexpected field declaration from setter "
              "${declaration}.",
            );
            assert(
              declarations.getter == null,
              "Unexpected getter declaration from setter "
              "${declaration}.",
            );
            _setterAugmentations.add(declarations.setter!);
            return true;
          } else {
            // Examples:
            //
            //    int? foo;
            //    void set foo(_) {}
            //
            // and
            //
            //    void set foo(_) {}
            //    void set foo(_) {}
            //
            _setterDeclaration!.reportDuplicateDeclaration(
              problemReporting,
              declaration,
            );
            return false;
          }
        }
      case _PropertyKind.Field:
        if (_getterDeclaration == null) {
          // Example:
          //
          //    void set foo(_) {}
          //    int? foo;
          //
          assert(_getterDeclaration == null && _setterDeclaration != null);
          // We have an explicit setter.
          _setterDeclaration!.reportDuplicateDeclaration(
            problemReporting,
            declaration,
          );
          return false;
        } else if (_setterDeclaration != null) {
          // Examples:
          //
          //    int? foo;
          //    int? foo;
          //
          //    int get bar => 42;
          //    void set bar(_) {}
          //    int bar = 87;
          //
          //    final int baz = 42;
          //    void set baz(_) {}
          //    int baz = 87;
          //
          assert(_getterDeclaration != null && _setterDeclaration != null);
          // We have both getter and setter
          if (declaration.isAugment) {
            // Coverage-ignore-block(suite): Not run.
            if (_getterDeclaration!.propertyKind == declaration.propertyKind) {
              // Example:
              //
              //    int foo = 42;
              //    augment int foo = 87;
              //
              _PropertyDeclarations declarations = declaration.declarations;
              // TODO(johnniwinther): Handle field augmentation.
              _getterAugmentations.add(declarations.getter!);
              _setterAugmentations.add(declarations.setter!);
              return true;
            } else {
              // Example:
              //
              //    final int foo = 42;
              //    void set foo(_) {}
              //    augment int foo = 87;
              //
              // TODO(johnniwinther): Report error.
              // TODO(johnniwinther): Should the augment be absorbed in this
              //  case, as an erroneous augmentation?
              return false;
            }
          } else {
            // Examples:
            //
            //    int? foo;
            //    int? foo;
            //
            //    int? get bar => null;
            //    void set bar(_) {}
            //    int? bar;
            //
            _getterDeclaration!.reportDuplicateDeclaration(
              problemReporting,
              declaration,
            );
            return false;
          }
        } else {
          // Examples:
          //
          //    int get foo => 42;
          //    int? foo;
          //
          //    final int bar = 42;
          //    int? bar;
          //
          assert(_getterDeclaration != null && _setterDeclaration == null);
          _getterDeclaration!.reportDuplicateDeclaration(
            problemReporting,
            declaration,
          );
          return false;
        }
      case _PropertyKind.FinalField:
        if (_getterDeclaration == null) {
          // Example:
          //
          //    void set foo(_) {}
          //    final int foo = 42;
          //
          assert(_getterDeclaration == null && _setterDeclaration != null);
          // We have an explicit setter.
          if (declaration.isAugment) {
            // Example:
            //
            //    void set foo(_) {}
            //    augment final int foo = 42;
            //
            // TODO(johnniwinther): Report error.
          }
          if (declaration.isStatic != isStatic) {
            // Coverage-ignore-block(suite): Not run.
            // Examples:
            //
            //    class A {
            //      void set foo(_) {}
            //      static final int foo = 42;
            //    }
            //
            // and
            //
            //    class A {
            //      static void set foo(_) {}
            //      final int foo = 42;
            //    }
            //
            _setterDeclaration!.reportStaticInstanceConflict(
              problemReporting,
              declaration,
            );
            return false;
          } else {
            _PropertyDeclarations declarations = declaration.declarations;
            assert(
              declarations.setter == null,
              "Unexpected setter declaration from field "
              "${declaration}.",
            );
            _getterDeclaration = declaration;
            return true;
          }
        } else {
          // Examples:
          //
          //    final int foo = 42;
          //    final int foo = 87;
          //
          //    int get bar => 42;
          //    final int bar = 87;
          //
          if (declaration.isAugment) {
            // Coverage-ignore-block(suite): Not run.
            if (_getterDeclaration!.propertyKind == declaration.propertyKind) {
              // Example:
              //
              //    final int foo = 42;
              //    augment final int foo = 87;
              //
              _PropertyDeclarations declarations = declaration.declarations;
              assert(
                declarations.setter == null,
                "Unexpected setter declaration from final field "
                "${declaration}.",
              );
              // TODO(johnniwinther): Handle field augmentation.
              _getterAugmentations.add(declarations.getter!);
              return true;
            } else {
              // Example:
              //
              //    int foo = 42;
              //    augment final int foo = 87;
              //
              // TODO(johnniwinther): Report error.
              // TODO(johnniwinther): Should the augment be absorbed in this
              //  case, as an erroneous augmentation?
              return false;
            }
          } else {
            // Examples:
            //
            //    final int foo = 42;
            //    final int foo = 87;
            //
            //    int get bar => 42;
            //    final int bar = 87;
            //
            _getterDeclaration!.reportDuplicateDeclaration(
              problemReporting,
              declaration,
            );
            return false;
          }
        }
    }
  }

  @override
  void checkFragment(
    ProblemReporting problemReporting,
    _Declaration constructorDeclaration,
  ) {
    // Check conflict with constructor.
    if (isStatic) {
      if (_getterDeclaration != null) {
        // Examples:
        //
        //    class A {
        //      static int get foo => 42;
        //      A.foo();
        //    }
        //
        // and
        //
        //    class A {
        //      static int get foo => 42;
        //      factory A.foo() => throw '';
        //    }
        //
        _getterDeclaration!.reportConstructorConflict(
          problemReporting,
          constructorDeclaration,
        );
      } else {
        // Coverage-ignore-block(suite): Not run.
        // Examples:
        //
        //    class A {
        //      static void set foo(_) {}
        //      A.foo();
        //    }
        //
        // and
        //
        //    class A {
        //      static void set foo(_) {}
        //      factory A.foo() => throw '';
        //    }
        //
        _setterDeclaration!.reportConstructorConflict(
          problemReporting,
          constructorDeclaration,
        );
      }
    }
  }

  @override
  void createBuilders(BuilderFactory builderFactory) {
    builderFactory._createPropertyBuilder(
      name: name,
      inPatch: inPatch,
      isStatic: isStatic,
      uriOffset: uriOffset,
      fieldDeclaration: _getterDeclaration?.declarations.field,
      getterDeclaration: _getterDeclaration?.declarations.getter,
      getterAugmentations: _getterAugmentations,
      setterDeclaration: _setterDeclaration?.declarations.setter,
      setterAugmentations: _setterAugmentations,
    );
  }
}

class _SetterDeclaration extends _PropertyDeclaration
    with _DeclarationReportingMixin {
  new({
    required super.displayName,
    required super.isAugment,
    required super.inPatch,
    required super.inLibrary,
    required super.propertyKind,
    required super.declarations,
    required super.uriOffset,
    super.isStatic,
  });

  @override
  _PreBuilder _createPreBuilder() => new _PropertyPreBuilder.forSetter(this);

  @override
  _ExistingKind _getExistingKindForDuplicate(_Declaration declaration) {
    return _ExistingKind.ExplicitSetter;
  }
}

abstract class _StandardDeclaration extends _NonConstructorDeclaration {
  new(
    super.kind, {
    required super.displayName,
    required super.isAugment,
    required super.inPatch,
    required super.inLibrary,
    super.isStatic,
  });

  // TODO(johnniwinther): Remove this.
  Fragment get _fragment;
}

class _StandardFragmentDeclaration extends _StandardDeclaration
    with
        _DeclarationReportingMixin,
        _FragmentDeclarationMixin,
        _StandardFragmentDeclarationMixin {
  @override
  final Fragment _fragment;

  new(
    super.kind,
    this._fragment, {
    required super.displayName,
    required super.isAugment,
    required super.inPatch,
    required super.inLibrary,
    super.isStatic,
  });

  @override
  _PreBuilder _createPreBuilder() => new _DeclarationPreBuilder(this);
}

mixin _StandardFragmentDeclarationMixin implements _StandardDeclaration {
  @override
  Fragment get _fragment;
}
