// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../base/messages.dart';
import '../base/modifiers.dart';
import '../base/name_space.dart';
import '../base/problems.dart';
import '../base/scope.dart';
import '../builder/augmentation_iterator.dart';
import '../builder/builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/record_type_builder.dart';
import '../builder/type_builder.dart';
import '../fragment/fragment.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/hierarchy/hierarchy_builder.dart';
import '../kernel/kernel_helper.dart';
import '../type_inference/type_inference_engine.dart';
import 'name_scheme.dart';
import 'name_space_builder.dart';
import 'source_builder_mixins.dart';
import 'source_constructor_builder.dart';
import 'source_factory_builder.dart';
import 'source_library_builder.dart';
import 'source_member_builder.dart';
import 'source_property_builder.dart';
import 'source_type_parameter_builder.dart';

class SourceExtensionTypeDeclarationBuilder
    extends ExtensionTypeDeclarationBuilderImpl
    with SourceDeclarationBuilderBaseMixin, SourceDeclarationBuilderMixin
    implements Comparable<SourceExtensionTypeDeclarationBuilder> {
  @override
  final SourceLibraryBuilder parent;

  @override
  final int fileOffset;

  @override
  final String name;

  @override
  final Uri fileUri;

  final Modifiers _modifiers;

  final List<ConstructorReferenceBuilder> constructorReferences;

  late final ExtensionTypeDeclaration _extensionTypeDeclaration;

  final DeclarationNameSpaceBuilder _nameSpaceBuilder;

  late final SourceDeclarationNameSpace _nameSpace;
  late final List<SourceMemberBuilder> _constructorBuilders;
  late final List<SourceMemberBuilder> _memberBuilders;

  @override
  final List<SourceNominalParameterBuilder>? typeParameters;

  @override
  List<TypeBuilder>? interfaceBuilders;

  final ExtensionTypeFragment _introductory;

  PrimaryConstructorFieldFragment? _representationFieldFragment;

  final IndexedContainer? indexedContainer;

  Nullability? _nullability;

  SourceExtensionTypeDeclarationBuilder({
    required this.name,
    required SourceLibraryBuilder enclosingLibraryBuilder,
    required this.constructorReferences,
    required this.fileUri,
    required int startOffset,
    required int nameOffset,
    required int endOffset,
    required ExtensionTypeFragment fragment,
    required this.indexedContainer,
    required PrimaryConstructorFieldFragment? representationFieldFragment,
  }) : parent = enclosingLibraryBuilder,
       fileOffset = nameOffset,
       _modifiers = fragment.modifiers,
       typeParameters = fragment.typeParameters?.builders,
       interfaceBuilders = fragment.interfaces,
       _introductory = fragment,
       _nameSpaceBuilder = fragment.toDeclarationNameSpaceBuilder(),
       _representationFieldFragment = representationFieldFragment {
    _introductory.builder = this;
    _introductory.bodyScope.declarationBuilder = this;

    // TODO(johnniwinther): Move this to the [build] once augmentations are
    // handled through fragments.
    _extensionTypeDeclaration = new ExtensionTypeDeclaration(
      name: name,
      fileUri: fileUri,
      typeParameters: SourceNominalParameterBuilder.typeParametersFromBuilders(
        fragment.typeParameters?.builders,
      ),
      reference: indexedContainer?.reference,
    )..fileOffset = nameOffset;
  }

  @override
  Iterator<SourceMemberBuilder> get unfilteredMembersIterator =>
      _memberBuilders.iterator;

  @override
  Iterator<T> filteredMembersIterator<T extends MemberBuilder>({
    required bool includeDuplicates,
  }) => new FilteredIterator<T>(
    _memberBuilders.iterator,
    includeDuplicates: includeDuplicates,
  );

  @override
  Iterator<SourceMemberBuilder> get unfilteredConstructorsIterator =>
      _constructorBuilders.iterator;

  @override
  Iterator<T> filteredConstructorsIterator<T extends MemberBuilder>({
    required bool includeDuplicates,
  }) => new FilteredIterator<T>(
    _constructorBuilders.iterator,
    includeDuplicates: includeDuplicates,
  );

  @override
  int resolveConstructors(SourceLibraryBuilder library) {
    int count = 0;
    if (constructorReferences.isNotEmpty) {
      for (ConstructorReferenceBuilder ref in constructorReferences) {
        ref.resolveIn(_introductory.bodyScope, library);
      }
      count += constructorReferences.length;
    }
    if (count > 0) {
      Iterator<SourceFactoryBuilder> iterator = filteredConstructorsIterator(
        includeDuplicates: true,
      );
      while (iterator.moveNext()) {
        SourceFactoryBuilder factoryBuilder = iterator.current;
        assert(
          factoryBuilder.declarationBuilder == this,
          "Unexpected builder $factoryBuilder in $this.",
        );
        factoryBuilder.resolveRedirectingFactory();
      }
    }
    return count;
  }

  @override
  DeclarationNameSpace get nameSpace => _nameSpace;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isStatic => _modifiers.isStatic;

  SourcePropertyBuilder? get representationFieldBuilder =>
      _representationFieldFragment?.builder;

  @override
  void buildScopes(LibraryBuilder coreLibrary) {
    _constructorBuilders = [];
    _memberBuilders = [];
    _nameSpace = _nameSpaceBuilder.buildNameSpace(
      loader: libraryBuilder.loader,
      problemReporting: libraryBuilder,
      enclosingLibraryBuilder: libraryBuilder,
      declarationBuilder: this,
      indexedLibrary: libraryBuilder.indexedLibrary,
      indexedContainer: indexedContainer,
      containerType: ContainerType.ExtensionType,
      containerName: new ClassName(name),
      constructorBuilders: _constructorBuilders,
      memberBuilders: _memberBuilders,
      typeParameterFactory: libraryBuilder.typeParameterFactory,
    );
  }

  @override
  SourceLibraryBuilder get libraryBuilder =>
      super.libraryBuilder as SourceLibraryBuilder;

  @override
  TypeBuilder? get declaredRepresentationTypeBuilder =>
      _representationFieldFragment?.type;

  @override
  ExtensionTypeDeclaration get extensionTypeDeclaration =>
      _extensionTypeDeclaration;

  @override
  int compareTo(SourceExtensionTypeDeclarationBuilder other) {
    int result = "$fileUri".compareTo("${other.fileUri}");
    if (result != 0) return result;
    return fileOffset.compareTo(other.fileOffset);
  }

  /// Builds the [ExtensionTypeDeclaration] for this extension type declaration
  /// builder and inserts the members into the [Library] of [libraryBuilder].
  ///
  /// [addMembersToLibrary] is `true` if the extension type members should be
  /// added to the library. This is `false` if the extension type declaration is
  /// in conflict with another library member. In this case, the extension type
  /// member should not be added to the library to avoid name clashes with other
  /// members in the library.
  ExtensionTypeDeclaration build(
    LibraryBuilder coreLibrary, {
    required bool addMembersToLibrary,
  }) {
    if (interfaceBuilders != null) {
      for (int i = 0; i < interfaceBuilders!.length; ++i) {
        TypeBuilder typeBuilder = interfaceBuilders![i];
        TypeAliasBuilder? aliasBuilder =
            typeBuilder.declaration is TypeAliasBuilder
            ? typeBuilder.declaration as TypeAliasBuilder
            : null;

        DartType interface = typeBuilder.build(
          libraryBuilder,
          TypeUse.extensionTypeImplementsType,
        );

        TypeDeclarationBuilder? implementedDeclaration = typeBuilder
            .computeUnaliasedDeclaration(isUsedAsClass: false);
        if (LibraryBuilder.isFunction(implementedDeclaration, coreLibrary) ||
            LibraryBuilder.isRecord(implementedDeclaration, coreLibrary)) {
          Message? errorMessage;
          List<LocatedMessage>? errorContext;
          if (aliasBuilder != null) {
            // Coverage-ignore-block(suite): Not run.
            errorMessage = diag.superExtensionTypeIsIllegalAliased
                .withArguments(
                  typeName: typeBuilder.fullNameForErrors,
                  aliasedType: interface,
                );
            errorContext = [
              diag.typedefCause.withLocation(
                aliasBuilder.fileUri,
                aliasBuilder.fileOffset,
                noLength,
              ),
            ];
          } else {
            errorMessage = diag.superExtensionTypeIsIllegal.withArguments(
              typeName: typeBuilder.fullNameForErrors,
            );
          }
          libraryBuilder.addProblem(
            errorMessage,
            typeBuilder.charOffset!,
            noLength,
            typeBuilder.fileUri,
            context: errorContext,
          );
          continue;
        }

        if (typeParameters?.isNotEmpty ?? false) {
          for (NominalParameterBuilder variable in typeParameters!) {
            Variance variance = typeBuilder
                .computeTypeParameterBuilderVariance(
                  variable,
                  sourceLoader: libraryBuilder.loader,
                )
                .variance!;
            if (!variance.greaterThanOrEqual(variable.variance)) {
              Message? errorMessage;
              if (variable.parameter.isLegacyCovariant) {
                errorMessage = diag.wrongTypeParameterVarianceInSuperinterface
                    .withArguments(
                      typeVariableName: variable.name,
                      type: interface,
                    );
              } else {
                // Coverage-ignore-block(suite): Not run.
                errorMessage = diag.invalidTypeParameterInSupertypeWithVariance
                    .withArguments(
                      typeVariableVariance: variable.variance.keyword,
                      typeVariableName: variable.name,
                      useVariance: variance.keyword,
                      supertypeName: typeBuilder.typeName!.name,
                    );
              }
              libraryBuilder.addProblem(
                errorMessage,
                typeBuilder.charOffset!,
                noLength,
                typeBuilder.fileUri,
              );
            }
          }
        }

        if (interface is ExtensionType) {
          if (interface.nullability == Nullability.nullable) {
            Message? errorMessage = diag.superExtensionTypeIsNullableAliased
                .withArguments(
                  typeName: typeBuilder.fullNameForErrors,
                  aliasedType: interface,
                );
            List<LocatedMessage>? errorContext;
            if (aliasBuilder != null) {
              errorContext = [
                diag.typedefCause.withLocation(
                  aliasBuilder.fileUri,
                  aliasBuilder.fileOffset,
                  noLength,
                ),
              ];
            }
            libraryBuilder.addProblem(
              errorMessage,
              typeBuilder.charOffset!,
              noLength,
              typeBuilder.fileUri,
              context: errorContext,
            );
          } else {
            extensionTypeDeclaration.implements.add(interface);
          }
        } else if (interface is InterfaceType) {
          if (interface.isPotentiallyNullable) {
            Message? errorMessage;
            List<LocatedMessage>? errorContext;
            if (typeBuilder.nullabilityBuilder.isNullable) {
              errorMessage = diag.nullableInterfaceError.withArguments(
                interfaceName: typeBuilder.fullNameForErrors,
              );
            } else {
              errorMessage = diag.superExtensionTypeIsNullableAliased
                  .withArguments(
                    typeName: typeBuilder.fullNameForErrors,
                    aliasedType: interface,
                  );
              if (aliasBuilder != null) {
                errorContext = [
                  diag.typedefCause.withLocation(
                    aliasBuilder.fileUri,
                    aliasBuilder.fileOffset,
                    noLength,
                  ),
                ];
              }
            }
            libraryBuilder.addProblem(
              errorMessage,
              typeBuilder.charOffset!,
              noLength,
              typeBuilder.fileUri,
              context: errorContext,
            );
          } else {
            extensionTypeDeclaration.implements.add(interface);
          }
        } else if (interface is TypeParameterType) {
          Message? errorMessage = diag.superExtensionTypeIsTypeParameter
              .withArguments(typeName: typeBuilder.fullNameForErrors);
          List<LocatedMessage>? errorContext;
          if (aliasBuilder != null) {
            // Coverage-ignore-block(suite): Not run.
            errorContext = [
              diag.typedefCause.withLocation(
                aliasBuilder.fileUri,
                aliasBuilder.fileOffset,
                noLength,
              ),
            ];
          }
          libraryBuilder.addProblem(
            errorMessage,
            typeBuilder.charOffset!,
            noLength,
            typeBuilder.fileUri,
            context: errorContext,
          );
        } else {
          Message? errorMessage;
          List<LocatedMessage>? errorContext;
          if (aliasBuilder != null) {
            errorMessage = diag.superExtensionTypeIsIllegalAliased
                .withArguments(
                  typeName: typeBuilder.fullNameForErrors,
                  aliasedType: interface,
                );
            errorContext = [
              diag.typedefCause.withLocation(
                aliasBuilder.fileUri,
                aliasBuilder.fileOffset,
                noLength,
              ),
            ];
          } else {
            errorMessage = diag.superExtensionTypeIsIllegal.withArguments(
              typeName: typeBuilder.fullNameForErrors,
            );
          }
          libraryBuilder.addProblem(
            errorMessage,
            typeBuilder.charOffset!,
            noLength,
            typeBuilder.fileUri,
            context: errorContext,
          );
        }
      }
    }

    DartType representationType;
    String representationName;
    if (_representationFieldFragment != null) {
      TypeBuilder typeBuilder = _representationFieldFragment!.type;
      if (typeBuilder.isExplicit) {
        if (_checkRepresentationDependency(typeBuilder, this, {this}, {})) {
          representationType = const InvalidType();
        } else {
          representationType = typeBuilder.build(
            libraryBuilder,
            TypeUse.fieldType,
          );
          if (typeParameters != null) {
            IncludesTypeParametersNonCovariantly
            checker = new IncludesTypeParametersNonCovariantly(
              extensionTypeDeclaration.typeParameters,
              // We are checking the returned type (field/getter type or return
              // type of a method) and this is a covariant position.
              initialVariance: Variance.covariant,
            );
            if (representationType.accept(checker)) {
              libraryBuilder.addProblem(
                diag.nonCovariantTypeParameterInRepresentationType,
                typeBuilder.charOffset!,
                noLength,
                typeBuilder.fileUri,
              );
            }
          }
          if (isBottom(representationType)) {
            libraryBuilder.addProblem(
              diag.extensionTypeRepresentationTypeBottom,
              _representationFieldFragment!.nameOffset,
              _representationFieldFragment!.name.length,
              _representationFieldFragment!.fileUri,
            );
            representationType = const InvalidType();
          }
        }
      } else {
        representationType = const DynamicType();
      }
      representationName = _representationFieldFragment!.name;
    } else {
      representationType = const InvalidType();
      representationName = '#';
    }
    _extensionTypeDeclaration.declaredRepresentationType = representationType;
    _extensionTypeDeclaration.representationName = representationName;
    buildInternal(coreLibrary, addMembersToLibrary: addMembersToLibrary);

    return _extensionTypeDeclaration;
  }

  bool _checkRepresentationDependency(
    TypeBuilder? typeBuilder,
    ExtensionTypeDeclarationBuilder rootExtensionTypeDeclaration,
    Set<ExtensionTypeDeclarationBuilder> seenExtensionTypeDeclarations,
    Set<TypeAliasBuilder> usedTypeAliasBuilders,
  ) {
    TypeBuilder? unaliased;
    if (typeBuilder != null) {
      typeBuilder.build(
        libraryBuilder,
        TypeUse.extensionTypeRepresentationType,
      );
      unaliased = typeBuilder.unalias(
        usedTypeAliasBuilders: usedTypeAliasBuilders,
      );
    }
    switch (unaliased) {
      case NamedTypeBuilder(
        :TypeDeclarationBuilder? declaration,
        typeArguments: List<TypeBuilder>? arguments,
      ):
        if (declaration is ExtensionTypeDeclarationBuilder) {
          bool declarationSeenFirstTime = seenExtensionTypeDeclarations.add(
            declaration,
          );
          if (declaration == rootExtensionTypeDeclaration) {
            List<LocatedMessage> context = [];
            for (ExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder
                in seenExtensionTypeDeclarations) {
              if (extensionTypeDeclarationBuilder != this) {
                context.add(
                  diag.extensionTypeDeclarationCause.withLocation(
                    extensionTypeDeclarationBuilder.fileUri,
                    extensionTypeDeclarationBuilder.fileOffset,
                    extensionTypeDeclarationBuilder.name.length,
                  ),
                );
              }
            }
            for (TypeAliasBuilder typeAliasBuilder in usedTypeAliasBuilders) {
              context.add(
                diag.typedefCause.withLocation(
                  typeAliasBuilder.fileUri,
                  typeAliasBuilder.fileOffset,
                  typeAliasBuilder.name.length,
                ),
              );
            }
            libraryBuilder.addProblem(
              diag.cyclicRepresentationDependency,
              _representationFieldFragment!.type.charOffset!,
              noLength,
              _representationFieldFragment!.type.fileUri,
              context: context,
            );
            return true;
          } else {
            TypeBuilder? representationTypeBuilder =
                declaration.declaredRepresentationTypeBuilder;
            if (declarationSeenFirstTime && representationTypeBuilder != null) {
              if (_checkRepresentationDependency(
                representationTypeBuilder,
                rootExtensionTypeDeclaration,
                seenExtensionTypeDeclarations.toSet(),
                usedTypeAliasBuilders.toSet(),
              )) {
                return true;
              }
            }
          }
        }
        if (arguments != null) {
          for (TypeBuilder typeArgument in arguments) {
            if (_checkRepresentationDependency(
              typeArgument,
              rootExtensionTypeDeclaration,
              seenExtensionTypeDeclarations.toSet(),
              usedTypeAliasBuilders.toSet(),
            )) {
              return true;
            }
          }
        } else if (declaration != null && declaration.typeParametersCount > 0) {
          List<TypeParameterBuilder>? typeParameters;
          switch (declaration) {
            case ClassBuilder():
              typeParameters = declaration.typeParameters;
            case TypeAliasBuilder():
              // Coverage-ignore(suite): Not run.
              typeParameters = declaration.typeParameters;
            case ExtensionTypeDeclarationBuilder():
              typeParameters = declaration.typeParameters;
            // Coverage-ignore(suite): Not run.
            case BuiltinTypeDeclarationBuilder():
            case InvalidBuilder():
            case ExtensionBuilder():
            case TypeParameterBuilder():
          }
          if (typeParameters != null) {
            for (int i = 0; i < typeParameters.length; i++) {
              TypeParameterBuilder typeParameter = typeParameters[i];
              if (_checkRepresentationDependency(
                typeParameter.defaultType!,
                rootExtensionTypeDeclaration,
                seenExtensionTypeDeclarations.toSet(),
                usedTypeAliasBuilders.toSet(),
              )) {
                return true;
              }
            }
          }
        }
      case FunctionTypeBuilder(
        typeParameters: List<StructuralParameterBuilder>? typeParameters,
        :List<ParameterBuilder>? formals,
        :TypeBuilder returnType,
      ):
        if (_checkRepresentationDependency(
          returnType,
          rootExtensionTypeDeclaration,
          seenExtensionTypeDeclarations.toSet(),
          usedTypeAliasBuilders.toSet(),
        )) {
          return true;
        }
        if (formals != null) {
          for (ParameterBuilder formal in formals) {
            if (_checkRepresentationDependency(
              formal.type,
              rootExtensionTypeDeclaration,
              seenExtensionTypeDeclarations.toSet(),
              usedTypeAliasBuilders.toSet(),
            )) {
              return true;
            }
          }
        }
        if (typeParameters != null) {
          for (StructuralParameterBuilder typeParameter in typeParameters) {
            TypeBuilder? bound = typeParameter.bound;
            if (_checkRepresentationDependency(
              bound,
              rootExtensionTypeDeclaration,
              seenExtensionTypeDeclarations.toSet(),
              usedTypeAliasBuilders.toSet(),
            )) {
              return true;
            }
          }
        }
      case RecordTypeBuilder(
        :List<RecordTypeFieldBuilder>? positionalFields,
        :List<RecordTypeFieldBuilder>? namedFields,
      ):
        if (positionalFields != null) {
          for (RecordTypeFieldBuilder field in positionalFields) {
            if (_checkRepresentationDependency(
              field.type,
              rootExtensionTypeDeclaration,
              seenExtensionTypeDeclarations.toSet(),
              usedTypeAliasBuilders.toSet(),
            )) {
              return true;
            }
          }
        }
        if (namedFields != null) {
          for (RecordTypeFieldBuilder field in namedFields) {
            if (_checkRepresentationDependency(
              field.type,
              rootExtensionTypeDeclaration,
              seenExtensionTypeDeclarations.toSet(),
              usedTypeAliasBuilders.toSet(),
            )) {
              return true;
            }
          }
        }
      case OmittedTypeBuilder():
      case FixedTypeBuilder():
      case InvalidTypeBuilder():
      case null:
    }
    return false;
  }

  void checkSupertypes(
    CoreTypes coreTypes,
    ClassHierarchyBuilder hierarchyBuilder,
  ) {
    if (interfaceBuilders != null) {
      Map<TypeDeclarationBuilder, ({int count, int offset})>?
      duplicationProblems;
      Set<TypeDeclarationBuilder> implemented = {};
      for (int i = 0; i < interfaceBuilders!.length; ++i) {
        TypeBuilder typeBuilder = interfaceBuilders![i];
        DartType interface = typeBuilder.build(
          libraryBuilder,
          TypeUse.extensionTypeImplementsType,
        );
        if (interface is InterfaceType) {
          if (!hierarchyBuilder.types.isSubtypeOf(
            declaredRepresentationType,
            interface,
          )) {
            libraryBuilder.addProblem(
              diag.invalidExtensionTypeSuperInterface.withArguments(
                interfaceType: interface,
                representationType: declaredRepresentationType,
                extensionTypeName: name,
              ),
              typeBuilder.charOffset!,
              noLength,
              typeBuilder.fileUri,
            );
          }
        } else if (interface is ExtensionType) {
          if (!hierarchyBuilder.types.isSubtypeOf(
            declaredRepresentationType,
            interface,
          )) {
            DartType instantiatedImplementedRepresentationType =
                Substitution.fromExtensionType(interface).substituteType(
                  interface.extensionTypeDeclaration.declaredRepresentationType,
                );
            if (!hierarchyBuilder.types.isSubtypeOf(
              declaredRepresentationType,
              instantiatedImplementedRepresentationType,
            )) {
              libraryBuilder.addProblem(
                diag.invalidExtensionTypeSuperExtensionType.withArguments(
                  representationType: declaredRepresentationType,
                  extensionTypeName: name,
                  implementedExtensionRepresentationType:
                      instantiatedImplementedRepresentationType,
                  implementedExtensionType: interface,
                ),
                typeBuilder.charOffset!,
                noLength,
                typeBuilder.fileUri,
              );
            }
          }
        }

        TypeDeclarationBuilder? typeDeclaration = typeBuilder
            .computeUnaliasedDeclaration(isUsedAsClass: false);
        if (typeDeclaration is ClassBuilder ||
            typeDeclaration is ExtensionTypeDeclarationBuilder) {
          if (!implemented.add(typeDeclaration!)) {
            duplicationProblems ??= {};
            switch (duplicationProblems[typeDeclaration]) {
              case (:var count, :var offset):
                duplicationProblems[typeDeclaration] = (
                  count: count + 1,
                  offset: offset,
                );
              case null:
                duplicationProblems[typeDeclaration] = (
                  count: 1,
                  offset: typeBuilder.charOffset ?? TreeNode.noOffset,
                );
            }
          }
        }
      }

      if (duplicationProblems != null) {
        for (var MapEntry(key: typeDeclaration, value: (:count, :offset))
            in duplicationProblems.entries) {
          libraryBuilder.addProblem(
            diag.implementsRepeated.withArguments(
              name: typeDeclaration.name,
              extraCount: count,
            ),
            offset,
            noLength,
            fileUri,
          );
        }
      }
    }
  }

  @override
  Nullability computeNullability({
    Map<ExtensionTypeDeclarationBuilder, TraversalState>? traversalState,
  }) => _nullability ??= _computeNullability(traversalState: traversalState);

  Nullability _computeNullabilityFromType(
    TypeBuilder typeBuilder, {
    required Map<ExtensionTypeDeclarationBuilder, TraversalState>
    traversalState,
  }) {
    Nullability nullability = typeBuilder.nullabilityBuilder.build();
    TypeDeclarationBuilder? declaration = typeBuilder.declaration;
    switch (declaration) {
      case TypeAliasBuilder():
        return combineNullabilitiesForSubstitution(
          inner: _computeNullabilityFromType(
            declaration.unalias(typeBuilder.typeArguments)!,
            traversalState: traversalState,
          ),
          outer: nullability,
        );
      case ExtensionTypeDeclarationBuilder():
        return combineNullabilitiesForSubstitution(
          inner: declaration.computeNullability(traversalState: traversalState),
          outer: nullability,
        );
      case ClassBuilder():
      // Coverage-ignore(suite): Not run.
      case NominalParameterBuilder():
      // Coverage-ignore(suite): Not run.
      case StructuralParameterBuilder():
      // Coverage-ignore(suite): Not run.
      case ExtensionBuilder():
      // Coverage-ignore(suite): Not run.
      case BuiltinTypeDeclarationBuilder():
      // Coverage-ignore(suite): Not run.
      case InvalidBuilder():
      case null:
        return nullability;
    }
  }

  Nullability _computeNullability({
    Map<ExtensionTypeDeclarationBuilder, TraversalState>? traversalState,
  }) {
    traversalState ??= {};
    Nullability nullability = Nullability.undetermined;
    switch (traversalState[this] ??= TraversalState.unvisited) {
      case TraversalState.unvisited:
        traversalState[this] = TraversalState.active;
        List<TypeBuilder>? interfaceBuilders = this.interfaceBuilders;
        if (interfaceBuilders != null) {
          for (TypeBuilder interfaceBuilder in interfaceBuilders) {
            Nullability interfaceNullability = _computeNullabilityFromType(
              interfaceBuilder,
              traversalState: traversalState,
            );
            if (interfaceNullability == Nullability.nonNullable) {
              nullability = Nullability.nonNullable;
              break;
            }
          }
        }
        traversalState[this] = TraversalState.visited;
      // Coverage-ignore(suite): Not run.
      case TraversalState.active:
      case TraversalState.visited:
        traversalState[this] = TraversalState.visited;
    }
    return nullability;
  }

  void checkRedirectingFactories(TypeEnvironment typeEnvironment) {
    Iterator<SourceFactoryBuilder> iterator = filteredConstructorsIterator(
      includeDuplicates: true,
    );
    while (iterator.moveNext()) {
      iterator.current.checkRedirectingFactories(typeEnvironment);
    }
  }

  void buildOutlineExpressions(
    ClassHierarchy classHierarchy,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {
    BodyBuilderContext bodyBuilderContext = createBodyBuilderContext();
    MetadataBuilder.buildAnnotations(
      annotatable: extensionTypeDeclaration,
      annotatableFileUri: extensionTypeDeclaration.fileUri,
      metadata: _introductory.metadata,
      annotationsFileUri: _introductory.fileUri,
      bodyBuilderContext: bodyBuilderContext,
      libraryBuilder: libraryBuilder,
      extensionScope: _introductory.enclosingCompilationUnit.extensionScope,
      scope: _introductory.enclosingScope,
    );

    if (_introductory.typeParameters != null) {
      for (int i = 0; i < _introductory.typeParameters!.length; i++) {
        _introductory.typeParameters![i].builder.buildOutlineExpressions(
          libraryBuilder,
          bodyBuilderContext,
          classHierarchy,
        );
      }
    }

    Iterator<SourceMemberBuilder> iterator = filteredMembersIterator(
      includeDuplicates: false,
    );
    while (iterator.moveNext()) {
      iterator.current.buildOutlineExpressions(
        classHierarchy,
        delayedDefaultValueCloners,
      );
    }

    Iterator<SourceMemberBuilder> constructorIterator =
        filteredConstructorsIterator(includeDuplicates: false);
    while (constructorIterator.moveNext()) {
      constructorIterator.current.buildOutlineExpressions(
        classHierarchy,
        delayedDefaultValueCloners,
      );
    }
  }

  @override
  void addMemberInternal(
    SourceMemberBuilder memberBuilder,
    BuiltMemberKind memberKind,
    Member member,
    Member? tearOff,
  ) {
    switch (memberKind) {
      case BuiltMemberKind.Constructor:
      case BuiltMemberKind.RedirectingFactory:
      case BuiltMemberKind.Field:
      case BuiltMemberKind.Method:
      case BuiltMemberKind.Factory:
      case BuiltMemberKind.ExtensionMethod:
      case BuiltMemberKind.ExtensionGetter:
      case BuiltMemberKind.ExtensionSetter:
      case BuiltMemberKind.ExtensionOperator:
      case BuiltMemberKind.ExtensionField:
      case BuiltMemberKind.LateBackingField:
      case BuiltMemberKind.LateIsSetField:
      case BuiltMemberKind.ExtensionTypeConstructor:
      case BuiltMemberKind.ExtensionTypeFactory:
      case BuiltMemberKind.ExtensionTypeRedirectingFactory:
      case BuiltMemberKind.ExtensionTypeMethod:
      case BuiltMemberKind.ExtensionTypeGetter:
      case BuiltMemberKind.LateGetter:
      case BuiltMemberKind.ExtensionTypeSetter:
      case BuiltMemberKind.LateSetter:
      case BuiltMemberKind.ExtensionTypeOperator:
        // Coverage-ignore(suite): Not run.
        unhandled(
          "$memberBuilder(${memberBuilder.runtimeType}):${memberKind}",
          "addMemberInternal",
          memberBuilder.fileOffset,
          memberBuilder.fileUri,
        );
      case BuiltMemberKind.ExtensionTypeRepresentationField:
        assert(tearOff == null, "Unexpected tear-off $tearOff");
        extensionTypeDeclaration.addProcedure(member as Procedure);
    }
  }

  @override
  void addMemberDescriptorInternal(
    SourceMemberBuilder memberBuilder,
    BuiltMemberKind memberKind,
    Reference memberReference,
    Reference? tearOffReference,
  ) {
    String name = memberBuilder.name;
    ExtensionTypeMemberKind kind;
    bool isInternalImplementation = false;
    switch (memberKind) {
      case BuiltMemberKind.Constructor:
      case BuiltMemberKind.RedirectingFactory:
      case BuiltMemberKind.Field:
      case BuiltMemberKind.Method:
      case BuiltMemberKind.Factory:
      case BuiltMemberKind.ExtensionMethod:
      case BuiltMemberKind.ExtensionGetter:
      case BuiltMemberKind.ExtensionSetter:
      case BuiltMemberKind.ExtensionOperator:
      case BuiltMemberKind.ExtensionTypeRepresentationField:
        // Coverage-ignore(suite): Not run.
        unhandled(
          "$memberBuilder(${memberBuilder.runtimeType}):${memberKind}",
          "buildMembers",
          memberBuilder.fileOffset,
          memberBuilder.fileUri,
        );
      case BuiltMemberKind.ExtensionField:
        kind = ExtensionTypeMemberKind.Field;
        break;
      case BuiltMemberKind.LateBackingField:
      case BuiltMemberKind.LateIsSetField:
        isInternalImplementation = true;
        kind = ExtensionTypeMemberKind.Field;
        break;
      case BuiltMemberKind.ExtensionTypeConstructor:
        kind = ExtensionTypeMemberKind.Constructor;
        break;
      case BuiltMemberKind.ExtensionTypeFactory:
        kind = ExtensionTypeMemberKind.Factory;
        break;
      case BuiltMemberKind.ExtensionTypeRedirectingFactory:
        kind = ExtensionTypeMemberKind.RedirectingFactory;
        break;
      case BuiltMemberKind.ExtensionTypeMethod:
        kind = ExtensionTypeMemberKind.Method;
        break;
      case BuiltMemberKind.ExtensionTypeGetter:
      case BuiltMemberKind.LateGetter:
        kind = ExtensionTypeMemberKind.Getter;
        break;
      case BuiltMemberKind.ExtensionTypeSetter:
      case BuiltMemberKind.LateSetter:
        kind = ExtensionTypeMemberKind.Setter;
        break;
      case BuiltMemberKind.ExtensionTypeOperator:
        kind = ExtensionTypeMemberKind.Operator;
        break;
    }
    extensionTypeDeclaration.memberDescriptors.add(
      new ExtensionTypeMemberDescriptor(
        name: new Name(name, libraryBuilder.library),
        memberReference: memberReference,
        tearOffReference: tearOffReference,
        isStatic: memberBuilder.isStatic,
        isInternalImplementation: isInternalImplementation,
        kind: kind,
      ),
    );
  }

  /// Looks up the constructor by [name] on the class built by this class
  /// builder.
  SourceConstructorBuilder? lookupConstructor(Name name) {
    if (name.text == "new") {
      // Coverage-ignore-block(suite): Not run.
      name = new Name("", name.library);
    }

    Builder? builder = nameSpace.lookupConstructor(name.text)?.getable;
    if (builder is SourceConstructorBuilder) {
      return builder;
    }
    return null;
  }

  @override
  DartType get declaredRepresentationType =>
      _extensionTypeDeclaration.declaredRepresentationType;

  BodyBuilderContext createBodyBuilderContext() {
    return new ExtensionTypeBodyBuilderContext(this);
  }

  /// Return a map whose keys are the supertypes of this
  /// [SourceExtensionTypeDeclarationBuilder] after expansion of type aliases,
  /// if any. For each supertype key, the corresponding value is the type alias
  /// which was unaliased in order to find the supertype, or null if the
  /// supertype was not aliased.
  Map<TypeDeclarationBuilder?, TypeAliasBuilder?> computeDirectSupertypes() {
    final Map<TypeDeclarationBuilder?, TypeAliasBuilder?> result = {};
    final List<TypeBuilder>? interfaces = this.interfaceBuilders;
    if (interfaces != null) {
      for (int i = 0; i < interfaces.length; i++) {
        TypeBuilder interface = interfaces[i];
        TypeDeclarationBuilder? declarationBuilder = interface.declaration;
        if (declarationBuilder is TypeAliasBuilder) {
          TypeDeclarationBuilder? unaliasedDeclaration = interface
              .computeUnaliasedDeclaration(isUsedAsClass: true);
          result[unaliasedDeclaration] = declarationBuilder;
        } else {
          result[declarationBuilder] = null;
        }
      }
    }
    return result;
  }

  // Coverage-ignore(suite): Not run.
  /// Returns an iterator the origin extension type declaration and all
  /// augmentations in application order.
  Iterator<SourceExtensionTypeDeclarationBuilder> get declarationIterator =>
      new AugmentationIterator<SourceExtensionTypeDeclarationBuilder>(
        this,
        null,
      );

  @override
  // Coverage-ignore(suite): Not run.
  Reference get reference => _extensionTypeDeclaration.reference;
}
