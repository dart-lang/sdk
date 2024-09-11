// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/reference_from_index.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../base/messages.dart';
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
import '../builder/name_iterator.dart';
import '../builder/record_type_builder.dart';
import '../builder/type_builder.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/hierarchy/hierarchy_builder.dart';
import '../kernel/kernel_helper.dart';
import '../type_inference/type_inference_engine.dart';
import 'class_declaration.dart';
import 'source_builder_mixins.dart';
import 'source_constructor_builder.dart';
import 'source_factory_builder.dart';
import 'source_field_builder.dart';
import 'source_library_builder.dart';
import 'source_member_builder.dart';
import 'type_parameter_scope_builder.dart';

class SourceExtensionTypeDeclarationBuilder
    extends ExtensionTypeDeclarationBuilderImpl
    with
        SourceDeclarationBuilderMixin,
        ClassDeclarationMixin,
        SourceTypedDeclarationBuilderMixin
    implements
        Comparable<SourceExtensionTypeDeclarationBuilder>,
        ClassDeclaration {
  @override
  final List<ConstructorReferenceBuilder>? constructorReferences;

  final ExtensionTypeDeclaration _extensionTypeDeclaration;

  SourceExtensionTypeDeclarationBuilder? _origin;

  MergedClassMemberScope? _mergedScope;

  final DeclarationNameSpaceBuilder _nameSpaceBuilder;

  late final LookupScope _scope;

  late final DeclarationNameSpace _nameSpace;

  late final ConstructorScope _constructorScope;

  @override
  final List<NominalVariableBuilder>? typeParameters;

  @override
  final LookupScope typeParameterScope;

  @override
  List<TypeBuilder>? interfaceBuilders;

  final SourceFieldBuilder? representationFieldBuilder;

  final IndexedContainer? indexedContainer;

  Nullability? _nullability;

  SourceExtensionTypeDeclarationBuilder(
      List<MetadataBuilder>? metadata,
      int modifiers,
      String name,
      this.typeParameters,
      this.interfaceBuilders,
      this.typeParameterScope,
      this._nameSpaceBuilder,
      SourceLibraryBuilder parent,
      this.constructorReferences,
      int startOffset,
      int nameOffset,
      int endOffset,
      this.indexedContainer,
      this.representationFieldBuilder)
      : _extensionTypeDeclaration = new ExtensionTypeDeclaration(
            name: name,
            fileUri: parent.fileUri,
            typeParameters: NominalVariableBuilder.typeParametersFromBuilders(
                typeParameters),
            reference: indexedContainer?.reference)
          ..fileOffset = nameOffset,
        super(metadata, modifiers, name, parent, nameOffset) {}

  @override
  LookupScope get scope => _scope;

  @override
  DeclarationNameSpace get nameSpace => _nameSpace;

  @override
  ConstructorScope get constructorScope => _constructorScope;

  @override
  void buildScopes(LibraryBuilder coreLibrary) {
    _nameSpace = _nameSpaceBuilder.buildNameSpace(libraryBuilder, this);
    _scope = new NameSpaceLookupScope(
        _nameSpace, ScopeKind.declaration, "extension type $name",
        parent: typeParameterScope);
    _constructorScope =
        new DeclarationNameSpaceConstructorScope(name, _nameSpace);
  }

  @override
  SourceLibraryBuilder get libraryBuilder =>
      super.libraryBuilder as SourceLibraryBuilder;

  @override
  TypeBuilder? get declaredRepresentationTypeBuilder =>
      representationFieldBuilder?.type;

  @override
  SourceExtensionTypeDeclarationBuilder get origin => _origin ?? this;

  // Coverage-ignore(suite): Not run.
  // TODO(johnniwinther): Add merged scope for extension type declarations.
  MergedClassMemberScope get mergedScope => _mergedScope ??= isAugmenting
      ? origin.mergedScope
      : throw new UnimplementedError(
          "SourceExtensionTypeDeclarationBuilder.mergedScope");

  @override
  ExtensionTypeDeclaration get extensionTypeDeclaration => isAugmenting
      ?
      // Coverage-ignore(suite): Not run.
      origin._extensionTypeDeclaration
      : _extensionTypeDeclaration;

  @override
  Annotatable get annotatable => extensionTypeDeclaration;

  @override
  int compareTo(SourceExtensionTypeDeclarationBuilder other) {
    int result = "$fileUri".compareTo("${other.fileUri}");
    if (result != 0) return result;
    return charOffset.compareTo(other.charOffset);
  }

  /// Builds the [ExtensionTypeDeclaration] for this extension type declaration
  /// builder and inserts the members into the [Library] of [libraryBuilder].
  ///
  /// [addMembersToLibrary] is `true` if the extension type members should be
  /// added to the library. This is `false` if the extension type declaration is
  /// in conflict with another library member. In this case, the extension type
  /// member should not be added to the library to avoid name clashes with other
  /// members in the library.
  ExtensionTypeDeclaration build(LibraryBuilder coreLibrary,
      {required bool addMembersToLibrary}) {
    if (interfaceBuilders != null) {
      for (int i = 0; i < interfaceBuilders!.length; ++i) {
        TypeBuilder typeBuilder = interfaceBuilders![i];
        TypeAliasBuilder? aliasBuilder =
            typeBuilder.declaration is TypeAliasBuilder
                ? typeBuilder.declaration as TypeAliasBuilder
                : null;
        DartType interface = typeBuilder.build(
            libraryBuilder, TypeUse.extensionTypeImplementsType);
        Message? errorMessage;
        List<LocatedMessage>? errorContext;

        if (typeParameters?.isNotEmpty ?? false) {
          for (NominalVariableBuilder variable in typeParameters!) {
            Variance variance = typeBuilder
                .computeTypeVariableBuilderVariance(variable,
                    sourceLoader: libraryBuilder.loader)
                .variance!;
            if (!variance.greaterThanOrEqual(variable.variance)) {
              if (variable.parameter.isLegacyCovariant) {
                errorMessage =
                    templateWrongTypeParameterVarianceInSuperinterface
                        .withArguments(variable.name, interface);
              } else {
                // Coverage-ignore-block(suite): Not run.
                errorMessage =
                    templateInvalidTypeVariableInSupertypeWithVariance
                        .withArguments(variable.variance.keyword, variable.name,
                            variance.keyword, typeBuilder.typeName!.name);
              }
            }
          }
          if (errorMessage != null) {
            libraryBuilder.addProblem(errorMessage, typeBuilder.charOffset!,
                noLength, typeBuilder.fileUri,
                context: errorContext);
            errorMessage = null;
          }
        }

        if (interface is ExtensionType) {
          if (interface.nullability == Nullability.nullable) {
            errorMessage = templateSuperExtensionTypeIsNullableAliased
                .withArguments(typeBuilder.fullNameForErrors, interface);
            if (aliasBuilder != null) {
              errorContext = [
                messageTypedefCause.withLocation(
                    aliasBuilder.fileUri, aliasBuilder.charOffset, noLength),
              ];
            }
          } else {
            extensionTypeDeclaration.implements.add(interface);
          }
        } else if (interface is InterfaceType) {
          if (interface.isPotentiallyNullable) {
            if (typeBuilder.nullabilityBuilder.isNullable) {
              errorMessage = templateNullableInterfaceError
                  .withArguments(typeBuilder.fullNameForErrors);
            } else {
              errorMessage = templateSuperExtensionTypeIsNullableAliased
                  .withArguments(typeBuilder.fullNameForErrors, interface);
              if (aliasBuilder != null) {
                errorContext = [
                  messageTypedefCause.withLocation(
                      aliasBuilder.fileUri, aliasBuilder.charOffset, noLength),
                ];
              }
            }
          } else {
            Class cls = interface.classNode;
            if (LibraryBuilder.isFunction(cls, coreLibrary) ||
                LibraryBuilder.isRecord(cls, coreLibrary)) {
              if (aliasBuilder != null) {
                // Coverage-ignore-block(suite): Not run.
                errorMessage = templateSuperExtensionTypeIsIllegalAliased
                    .withArguments(typeBuilder.fullNameForErrors, interface);
                errorContext = [
                  messageTypedefCause.withLocation(
                      aliasBuilder.fileUri, aliasBuilder.charOffset, noLength),
                ];
              } else {
                errorMessage = templateSuperExtensionTypeIsIllegal
                    .withArguments(typeBuilder.fullNameForErrors);
              }
            } else {
              extensionTypeDeclaration.implements.add(interface);
            }
          }
        } else if (interface is TypeParameterType) {
          errorMessage = templateSuperExtensionTypeIsTypeVariable
              .withArguments(typeBuilder.fullNameForErrors);
          if (aliasBuilder != null) {
            // Coverage-ignore-block(suite): Not run.
            errorContext = [
              messageTypedefCause.withLocation(
                  aliasBuilder.fileUri, aliasBuilder.charOffset, noLength),
            ];
          }
        } else {
          if (aliasBuilder != null) {
            errorMessage = templateSuperExtensionTypeIsIllegalAliased
                .withArguments(typeBuilder.fullNameForErrors, interface);
            errorContext = [
              messageTypedefCause.withLocation(
                  aliasBuilder.fileUri, aliasBuilder.charOffset, noLength),
            ];
          } else {
            errorMessage = templateSuperExtensionTypeIsIllegal
                .withArguments(typeBuilder.fullNameForErrors);
          }
        }
        if (errorMessage != null) {
          libraryBuilder.addProblem(errorMessage, typeBuilder.charOffset!,
              noLength, typeBuilder.fileUri,
              context: errorContext);
        }
      }
    }

    DartType representationType;
    String representationName;
    if (representationFieldBuilder != null) {
      TypeBuilder typeBuilder = representationFieldBuilder!.type;
      if (typeBuilder.isExplicit) {
        if (_checkRepresentationDependency(typeBuilder, this, {this}, {})) {
          representationType = const InvalidType();
        } else {
          representationType =
              typeBuilder.build(libraryBuilder, TypeUse.fieldType);
          if (typeParameters != null) {
            IncludesTypeParametersNonCovariantly checker =
                new IncludesTypeParametersNonCovariantly(
                    extensionTypeDeclaration.typeParameters,
                    // We are checking the returned type (field/getter type or return
                    // type of a method) and this is a covariant position.
                    initialVariance: Variance.covariant);
            if (representationType.accept(checker)) {
              libraryBuilder.addProblem(
                  messageNonCovariantTypeParameterInRepresentationType,
                  typeBuilder.charOffset!,
                  noLength,
                  typeBuilder.fileUri);
            }
          }
          if (isBottom(representationType)) {
            libraryBuilder.addProblem(
                messageExtensionTypeRepresentationTypeBottom,
                representationFieldBuilder!.charOffset,
                representationFieldBuilder!.name.length,
                representationFieldBuilder!.fileUri);
            representationType = const InvalidType();
          }
        }
      } else {
        representationType = const DynamicType();
      }
      representationName = representationFieldBuilder!.name;
    } else {
      representationType = const InvalidType();
      representationName = '#';
    }
    _extensionTypeDeclaration.declaredRepresentationType = representationType;
    _extensionTypeDeclaration.representationName = representationName;
    buildInternal(coreLibrary, addMembersToLibrary: addMembersToLibrary);
    checkConstructorStaticConflict();

    return _extensionTypeDeclaration;
  }

  bool _checkRepresentationDependency(
      TypeBuilder? typeBuilder,
      ExtensionTypeDeclarationBuilder rootExtensionTypeDeclaration,
      Set<ExtensionTypeDeclarationBuilder> seenExtensionTypeDeclarations,
      Set<TypeAliasBuilder> usedTypeAliasBuilders) {
    TypeBuilder? unaliased;
    if (typeBuilder != null) {
      typeBuilder.build(
          libraryBuilder, TypeUse.extensionTypeRepresentationType);
      unaliased = typeBuilder.unalias(
          usedTypeAliasBuilders: usedTypeAliasBuilders,
          // We allow creating new type variables during unaliasing. This type
          // variables are short-lived and therefore don't need to be bound.
          unboundTypeVariables: []);
    }
    switch (unaliased) {
      case NamedTypeBuilder(
          :TypeDeclarationBuilder? declaration,
          typeArguments: List<TypeBuilder>? arguments
        ):
        if (declaration is ExtensionTypeDeclarationBuilder) {
          bool declarationSeenFirstTime =
              seenExtensionTypeDeclarations.add(declaration);
          if (declaration == rootExtensionTypeDeclaration) {
            List<LocatedMessage> context = [];
            for (ExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder
                in seenExtensionTypeDeclarations) {
              if (extensionTypeDeclarationBuilder != this) {
                context.add(messageExtensionTypeDeclarationCause.withLocation(
                    extensionTypeDeclarationBuilder.fileUri,
                    extensionTypeDeclarationBuilder.charOffset,
                    extensionTypeDeclarationBuilder.name.length));
              }
            }
            for (TypeAliasBuilder typeAliasBuilder in usedTypeAliasBuilders) {
              context.add(messageTypedefCause.withLocation(
                  typeAliasBuilder.fileUri,
                  typeAliasBuilder.charOffset,
                  typeAliasBuilder.name.length));
            }
            libraryBuilder.addProblem(
                messageCyclicRepresentationDependency,
                representationFieldBuilder!.type.charOffset!,
                noLength,
                representationFieldBuilder!.type.fileUri,
                context: context);
            return true;
          } else {
            TypeBuilder? representationTypeBuilder =
                declaration.declaredRepresentationTypeBuilder;
            if (declarationSeenFirstTime && representationTypeBuilder != null) {
              if (_checkRepresentationDependency(
                  representationTypeBuilder,
                  rootExtensionTypeDeclaration,
                  seenExtensionTypeDeclarations.toSet(),
                  usedTypeAliasBuilders.toSet())) {
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
                usedTypeAliasBuilders.toSet())) {
              return true;
            }
          }
        } else if (declaration != null && declaration.typeVariablesCount > 0) {
          List<TypeVariableBuilder>? typeParameters;
          switch (declaration) {
            case ClassBuilder():
              typeParameters = declaration.typeVariables;
            case TypeAliasBuilder():
              // Coverage-ignore(suite): Not run.
              typeParameters = declaration.typeVariables;
            case ExtensionTypeDeclarationBuilder():
              typeParameters = declaration.typeParameters;
            // Coverage-ignore(suite): Not run.
            case BuiltinTypeDeclarationBuilder():
            case InvalidTypeDeclarationBuilder():
            case OmittedTypeDeclarationBuilder():
            case ExtensionBuilder():
            case TypeVariableBuilder():
          }
          if (typeParameters != null) {
            for (int i = 0; i < typeParameters.length; i++) {
              TypeVariableBuilder typeParameter = typeParameters[i];
              if (_checkRepresentationDependency(
                  typeParameter.defaultType!,
                  rootExtensionTypeDeclaration,
                  seenExtensionTypeDeclarations.toSet(),
                  usedTypeAliasBuilders.toSet())) {
                return true;
              }
            }
          }
        }
      case FunctionTypeBuilder(
          :List<StructuralVariableBuilder>? typeVariables,
          :List<ParameterBuilder>? formals,
          :TypeBuilder returnType
        ):
        if (_checkRepresentationDependency(
            returnType,
            rootExtensionTypeDeclaration,
            seenExtensionTypeDeclarations.toSet(),
            usedTypeAliasBuilders.toSet())) {
          return true;
        }
        if (formals != null) {
          for (ParameterBuilder formal in formals) {
            if (_checkRepresentationDependency(
                formal.type,
                rootExtensionTypeDeclaration,
                seenExtensionTypeDeclarations.toSet(),
                usedTypeAliasBuilders.toSet())) {
              return true;
            }
          }
        }
        if (typeVariables != null) {
          for (StructuralVariableBuilder typeVariable in typeVariables) {
            TypeBuilder? bound = typeVariable.bound;
            if (_checkRepresentationDependency(
                bound,
                rootExtensionTypeDeclaration,
                seenExtensionTypeDeclarations.toSet(),
                usedTypeAliasBuilders.toSet())) {
              return true;
            }
          }
        }
      case RecordTypeBuilder(
          :List<RecordTypeFieldBuilder>? positionalFields,
          :List<RecordTypeFieldBuilder>? namedFields
        ):
        if (positionalFields != null) {
          for (RecordTypeFieldBuilder field in positionalFields) {
            if (_checkRepresentationDependency(
                field.type,
                rootExtensionTypeDeclaration,
                seenExtensionTypeDeclarations.toSet(),
                usedTypeAliasBuilders.toSet())) {
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
                usedTypeAliasBuilders.toSet())) {
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
      CoreTypes coreTypes, ClassHierarchyBuilder hierarchyBuilder) {
    if (interfaceBuilders != null) {
      Map<TypeDeclarationBuilder, ({int count, int offset})>?
          duplicationProblems;
      Set<TypeDeclarationBuilder> implemented = {};
      for (int i = 0; i < interfaceBuilders!.length; ++i) {
        TypeBuilder typeBuilder = interfaceBuilders![i];
        DartType interface = typeBuilder.build(
            libraryBuilder, TypeUse.extensionTypeImplementsType);
        if (interface is InterfaceType) {
          if (!hierarchyBuilder.types.isSubtypeOf(declaredRepresentationType,
              interface, SubtypeCheckMode.withNullabilities)) {
            libraryBuilder.addProblem(
                templateInvalidExtensionTypeSuperInterface.withArguments(
                    interface, declaredRepresentationType, name),
                typeBuilder.charOffset!,
                noLength,
                typeBuilder.fileUri);
          }
        } else if (interface is ExtensionType) {
          if (!hierarchyBuilder.types.isSubtypeOf(declaredRepresentationType,
              interface, SubtypeCheckMode.withNullabilities)) {
            DartType instantiatedImplementedRepresentationType =
                Substitution.fromExtensionType(interface).substituteType(
                    interface
                        .extensionTypeDeclaration.declaredRepresentationType);
            if (!hierarchyBuilder.types.isSubtypeOf(
                declaredRepresentationType,
                instantiatedImplementedRepresentationType,
                SubtypeCheckMode.withNullabilities)) {
              libraryBuilder.addProblem(
                  templateInvalidExtensionTypeSuperExtensionType.withArguments(
                      declaredRepresentationType,
                      name,
                      instantiatedImplementedRepresentationType,
                      interface),
                  typeBuilder.charOffset!,
                  noLength,
                  typeBuilder.fileUri);
            }
          }
        }

        TypeDeclarationBuilder? typeDeclaration =
            typeBuilder.computeUnaliasedDeclaration(isUsedAsClass: false);
        if (typeDeclaration is ClassBuilder ||
            typeDeclaration is ExtensionTypeDeclarationBuilder) {
          if (!implemented.add(typeDeclaration!)) {
            duplicationProblems ??= {};
            switch (duplicationProblems[typeDeclaration]) {
              case (:var count, :var offset):
                duplicationProblems[typeDeclaration] =
                    (count: count + 1, offset: offset);
              case null:
                duplicationProblems[typeDeclaration] = (
                  count: 1,
                  offset: typeBuilder.charOffset ?? TreeNode.noOffset
                );
            }
          }
        }
      }

      if (duplicationProblems != null) {
        for (var MapEntry(key: typeDeclaration, value: (:count, :offset))
            in duplicationProblems.entries) {
          addProblem(
              templateImplementsRepeated.withArguments(
                  typeDeclaration.name, count),
              offset,
              noLength);
        }
      }
    }
  }

  @override
  Nullability computeNullability(
          {Map<ExtensionTypeDeclarationBuilder, TraversalState>?
              traversalState}) =>
      _nullability ??= _computeNullability(traversalState: traversalState);

  Nullability _computeNullabilityFromType(TypeBuilder typeBuilder,
      {required Map<ExtensionTypeDeclarationBuilder, TraversalState>
          traversalState}) {
    Nullability nullability = typeBuilder.nullabilityBuilder.build();
    TypeDeclarationBuilder? declaration = typeBuilder.declaration;
    switch (declaration) {
      case TypeAliasBuilder():
        return combineNullabilitiesForSubstitution(
            inner: _computeNullabilityFromType(
                declaration.unalias(typeBuilder.typeArguments,
                    unboundTypeVariables: [])!,
                traversalState: traversalState),
            outer: nullability);
      case ExtensionTypeDeclarationBuilder():
        return combineNullabilitiesForSubstitution(
            inner:
                declaration.computeNullability(traversalState: traversalState),
            outer: nullability);
      case ClassBuilder():
      // Coverage-ignore(suite): Not run.
      case NominalVariableBuilder():
      // Coverage-ignore(suite): Not run.
      case StructuralVariableBuilder():
      // Coverage-ignore(suite): Not run.
      case ExtensionBuilder():
      // Coverage-ignore(suite): Not run.
      case BuiltinTypeDeclarationBuilder():
      // Coverage-ignore(suite): Not run.
      case InvalidTypeDeclarationBuilder():
      // Coverage-ignore(suite): Not run.
      case OmittedTypeDeclarationBuilder():
      case null:
        return nullability;
    }
  }

  Nullability _computeNullability(
      {Map<ExtensionTypeDeclarationBuilder, TraversalState>? traversalState}) {
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
                traversalState: traversalState);
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
    Iterator<SourceFactoryBuilder> iterator =
        nameSpace.filteredConstructorIterator<SourceFactoryBuilder>(
            parent: this, includeDuplicates: true, includeAugmentations: true);
    while (iterator.moveNext()) {
      iterator.current.checkRedirectingFactories(typeEnvironment);
    }
  }

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    super.buildOutlineExpressions(classHierarchy, delayedDefaultValueCloners);

    Iterator<SourceMemberBuilder> iterator =
        nameSpace.filteredConstructorIterator(
            parent: this, includeDuplicates: false, includeAugmentations: true);
    while (iterator.moveNext()) {
      iterator.current
          .buildOutlineExpressions(classHierarchy, delayedDefaultValueCloners);
    }
  }

  @override
  void addMemberInternal(SourceMemberBuilder memberBuilder,
      BuiltMemberKind memberKind, Member member, Member? tearOff) {
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
            "${memberBuilder.runtimeType}:${memberKind}",
            "addMemberInternal",
            memberBuilder.charOffset,
            memberBuilder.fileUri);
      case BuiltMemberKind.ExtensionTypeRepresentationField:
        assert(
            tearOff == null, // Coverage-ignore(suite): Not run.
            "Unexpected tear-off $tearOff");
        extensionTypeDeclaration.addProcedure(member as Procedure);
    }
  }

  @override
  void addMemberDescriptorInternal(
      SourceMemberBuilder memberBuilder,
      BuiltMemberKind memberKind,
      Reference memberReference,
      Reference? tearOffReference) {
    String name = memberBuilder.name;
    ExtensionTypeMemberKind kind;
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
        unhandled("${memberBuilder.runtimeType}:${memberKind}", "buildMembers",
            memberBuilder.charOffset, memberBuilder.fileUri);
      case BuiltMemberKind.ExtensionField:
      case BuiltMemberKind.LateIsSetField:
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
            kind: kind));
  }

  @override
  // Coverage-ignore(suite): Not run.
  void applyAugmentation(Builder augmentation) {
    if (augmentation is SourceExtensionTypeDeclarationBuilder) {
      augmentation._origin = this;
      nameSpace.forEachLocalMember((String name, Builder member) {
        Builder? memberAugmentation =
            augmentation.nameSpace.lookupLocalMember(name, setter: false);
        if (memberAugmentation != null) {
          member.applyAugmentation(memberAugmentation);
        }
      });
      nameSpace.forEachLocalSetter((String name, Builder member) {
        Builder? memberAugmentation =
            augmentation.nameSpace.lookupLocalMember(name, setter: true);
        if (memberAugmentation != null) {
          member.applyAugmentation(memberAugmentation);
        }
      });

      // TODO(johnniwinther): Check that type parameters and on-type match
      // with origin declaration.
    } else {
      libraryBuilder.addProblem(messagePatchDeclarationMismatch,
          augmentation.charOffset, noLength, augmentation.fileUri, context: [
        messagePatchDeclarationOrigin.withLocation(
            fileUri, charOffset, noLength)
      ]);
    }
  }

  /// Looks up the constructor by [name] on the class built by this class
  /// builder.
  SourceExtensionTypeConstructorBuilder? lookupConstructor(Name name) {
    if (name.text == "new") {
      // Coverage-ignore-block(suite): Not run.
      name = new Name("", name.library);
    }

    Builder? builder = nameSpace.lookupConstructor(name.text);
    if (builder is SourceExtensionTypeConstructorBuilder) {
      return builder;
    }
    return null;
  }

  @override
  DartType get declaredRepresentationType =>
      _extensionTypeDeclaration.declaredRepresentationType;

  @override
  Iterator<T> fullMemberIterator<T extends Builder>() =>
      new ClassDeclarationMemberIterator<SourceExtensionTypeDeclarationBuilder,
              T>.full(
          const _SourceExtensionTypeDeclarationBuilderAugmentationAccess(),
          this,
          includeDuplicates: false);

  @override
  // Coverage-ignore(suite): Not run.
  NameIterator<T> fullMemberNameIterator<T extends Builder>() =>
      new ClassDeclarationMemberNameIterator<
              SourceExtensionTypeDeclarationBuilder, T>(
          const _SourceExtensionTypeDeclarationBuilderAugmentationAccess(),
          this,
          includeDuplicates: false);

  @override
  Iterator<T> fullConstructorIterator<T extends MemberBuilder>() =>
      new ClassDeclarationConstructorIterator<
              SourceExtensionTypeDeclarationBuilder, T>.full(
          const _SourceExtensionTypeDeclarationBuilderAugmentationAccess(),
          this,
          includeDuplicates: false);

  @override
  NameIterator<T> fullConstructorNameIterator<T extends MemberBuilder>() =>
      new ClassDeclarationConstructorNameIterator<
              SourceExtensionTypeDeclarationBuilder, T>(
          const _SourceExtensionTypeDeclarationBuilderAugmentationAccess(),
          this,
          includeDuplicates: false);

  @override
  // Coverage-ignore(suite): Not run.
  bool get isMixinDeclaration => false;

  @override
  BodyBuilderContext createBodyBuilderContext(
      {required bool inOutlineBuildingPhase,
      required bool inMetadata,
      required bool inConstFields}) {
    return new ExtensionTypeBodyBuilderContext(this,
        inOutlineBuildingPhase: inOutlineBuildingPhase,
        inMetadata: inMetadata,
        inConstFields: inConstFields);
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
          TypeDeclarationBuilder? unaliasedDeclaration =
              interface.computeUnaliasedDeclaration(isUsedAsClass: true);
          result[unaliasedDeclaration] = declarationBuilder;
        } else {
          result[declarationBuilder] = null;
        }
      }
    }
    return result;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Iterator<T> localMemberIterator<T extends Builder>() =>
      new ClassDeclarationMemberIterator<SourceExtensionTypeDeclarationBuilder,
          T>.local(this, includeDuplicates: false);

  @override
  // Coverage-ignore(suite): Not run.
  Iterator<T> localConstructorIterator<T extends MemberBuilder>() =>
      new ClassDeclarationConstructorIterator<
          SourceExtensionTypeDeclarationBuilder,
          T>.local(this, includeDuplicates: false);

  // Coverage-ignore(suite): Not run.
  /// Returns an iterator the origin extension type declaration and all
  /// augmentations in application order.
  Iterator<SourceExtensionTypeDeclarationBuilder> get declarationIterator =>
      new AugmentationIterator<SourceExtensionTypeDeclarationBuilder>(
          // TODO(johnniwinther): Support augmentations.
          origin,
          null);
}

class _SourceExtensionTypeDeclarationBuilderAugmentationAccess
    implements
        ClassDeclarationAugmentationAccess<
            SourceExtensionTypeDeclarationBuilder> {
  const _SourceExtensionTypeDeclarationBuilderAugmentationAccess();

  @override
  SourceExtensionTypeDeclarationBuilder getOrigin(
          SourceExtensionTypeDeclarationBuilder classDeclaration) =>
      classDeclaration.origin;

  @override
  Iterable<SourceExtensionTypeDeclarationBuilder>? getAugmentations(
          SourceExtensionTypeDeclarationBuilder classDeclaration) =>
      null;
}
