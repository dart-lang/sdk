// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/builder/function_type_builder.dart';
import 'package:front_end/src/fasta/builder/record_type_builder.dart';
import 'package:front_end/src/fasta/kernel/body_builder_context.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../../base/common.dart';
import '../builder/builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/extension_type_declaration_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/name_iterator.dart';
import '../builder/named_type_builder.dart';
import '../builder/type_alias_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_declaration_builder.dart';
import '../builder/type_variable_builder.dart';
import '../kernel/kernel_helper.dart';
import '../messages.dart';
import '../problems.dart';
import '../scope.dart';
import '../type_inference/type_inference_engine.dart';
import '../util/helpers.dart';
import 'class_declaration.dart';
import 'source_builder_mixins.dart';
import 'source_constructor_builder.dart';
import 'source_field_builder.dart';
import 'source_library_builder.dart';
import 'source_member_builder.dart';

class SourceExtensionTypeDeclarationBuilder
    extends ExtensionTypeDeclarationBuilderImpl
    with SourceDeclarationBuilderMixin, ClassDeclarationMixin
    implements
        Comparable<SourceExtensionTypeDeclarationBuilder>,
        ClassDeclaration {
  @override
  final List<ConstructorReferenceBuilder>? constructorReferences;

  final ExtensionTypeDeclaration _extensionTypeDeclaration;

  SourceExtensionTypeDeclarationBuilder? _origin;
  SourceExtensionTypeDeclarationBuilder? patchForTesting;

  MergedClassMemberScope? _mergedScope;

  @override
  final List<TypeVariableBuilder>? typeParameters;

  @override
  List<TypeBuilder>? interfaceBuilders;

  final SourceFieldBuilder? representationFieldBuilder;

  SourceExtensionTypeDeclarationBuilder(
      List<MetadataBuilder>? metadata,
      int modifiers,
      String name,
      this.typeParameters,
      this.interfaceBuilders,
      Scope scope,
      ConstructorScope constructorScope,
      SourceLibraryBuilder parent,
      this.constructorReferences,
      int startOffset,
      int nameOffset,
      int endOffset,
      ExtensionTypeDeclaration? referenceFrom,
      this.representationFieldBuilder)
      : _extensionTypeDeclaration = new ExtensionTypeDeclaration(
            name: name,
            fileUri: parent.fileUri,
            typeParameters:
                TypeVariableBuilder.typeParametersFromBuilders(typeParameters),
            reference: referenceFrom?.reference)
          ..fileOffset = nameOffset,
        super(metadata, modifiers, name, parent, nameOffset, scope,
            constructorScope);

  @override
  SourceLibraryBuilder get libraryBuilder =>
      super.libraryBuilder as SourceLibraryBuilder;

  @override
  TypeBuilder? get declaredRepresentationTypeBuilder =>
      representationFieldBuilder?.type;

  @override
  SourceExtensionTypeDeclarationBuilder get origin => _origin ?? this;

  // TODO(johnniwinther): Add merged scope for extension type declarations.
  MergedClassMemberScope get mergedScope => _mergedScope ??= isPatch
      ? origin.mergedScope
      : throw new UnimplementedError(
          "SourceExtensionTypeDeclarationBuilder.mergedScope");

  @override
  ExtensionTypeDeclaration get extensionTypeDeclaration =>
      isPatch ? origin._extensionTypeDeclaration : _extensionTypeDeclaration;

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
        DartType interface =
            typeBuilder.build(libraryBuilder, TypeUse.superType);
        Message? errorMessage;
        List<LocatedMessage>? errorContext;
        if (interface is ExtensionType) {
          if (interface.isPotentiallyNullable) {
            errorMessage =
                templateSuperExtensionTypeIsNullableAliased.withArguments(
                    typeBuilder.fullNameForErrors,
                    interface,
                    libraryBuilder.isNonNullableByDefault);
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
            errorMessage =
                templateSuperExtensionTypeIsNullableAliased.withArguments(
                    typeBuilder.fullNameForErrors,
                    interface,
                    libraryBuilder.isNonNullableByDefault);
            if (aliasBuilder != null) {
              errorContext = [
                messageTypedefCause.withLocation(
                    aliasBuilder.fileUri, aliasBuilder.charOffset, noLength),
              ];
            }
          } else {
            Class cls = interface.classNode;
            if (LibraryBuilder.isObject(cls, coreLibrary) ||
                LibraryBuilder.isFunction(cls, coreLibrary) ||
                LibraryBuilder.isRecord(cls, coreLibrary)) {
              if (aliasBuilder != null) {
                errorMessage =
                    templateSuperExtensionTypeIsIllegalAliased.withArguments(
                        typeBuilder.fullNameForErrors,
                        interface,
                        libraryBuilder.isNonNullableByDefault);
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
            errorContext = [
              messageTypedefCause.withLocation(
                  aliasBuilder.fileUri, aliasBuilder.charOffset, noLength),
            ];
          }
        } else {
          if (aliasBuilder != null) {
            errorMessage =
                templateSuperExtensionTypeIsIllegalAliased.withArguments(
                    typeBuilder.fullNameForErrors,
                    interface,
                    libraryBuilder.isNonNullableByDefault);
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
        if (_checkRepresentationDependency(typeBuilder, {this}, {})) {
          representationType = const InvalidType();
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

    return _extensionTypeDeclaration;
  }

  bool _checkRepresentationDependency(
      TypeBuilder? typeBuilder,
      Set<ExtensionTypeDeclarationBuilder> seenExtensionTypeDeclarations,
      Set<TypeAliasBuilder> usedTypeAliasBuilders) {
    TypeBuilder? unaliased = typeBuilder?.unalias(
        usedTypeAliasBuilders: usedTypeAliasBuilders,
        // We allow creating new type variables during unaliasing. This type
        // variables are short-lived and therefore don't need to be bound.
        unboundTypeVariables: []);
    if (unaliased is NamedTypeBuilder) {
      TypeDeclarationBuilder? declaration = unaliased.declaration;
      if (declaration is ExtensionTypeDeclarationBuilder) {
        if (!seenExtensionTypeDeclarations.add(declaration)) {
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
          if (representationTypeBuilder != null) {
            if (_checkRepresentationDependency(
                representationTypeBuilder,
                seenExtensionTypeDeclarations.toSet(),
                usedTypeAliasBuilders.toSet())) {
              return true;
            }
          }
        }
      }
      List<TypeBuilder>? typeArguments = unaliased.arguments;
      if (typeArguments != null) {
        for (TypeBuilder typeArgument in typeArguments) {
          if (_checkRepresentationDependency(
              typeArgument,
              seenExtensionTypeDeclarations.toSet(),
              usedTypeAliasBuilders.toSet())) {
            return true;
          }
        }
      }
    } else if (unaliased is FunctionTypeBuilder) {
      if (_checkRepresentationDependency(
          unaliased.returnType,
          seenExtensionTypeDeclarations.toSet(),
          usedTypeAliasBuilders.toSet())) {
        return true;
      }
      List<ParameterBuilder>? formals = unaliased.formals;
      if (formals != null) {
        for (ParameterBuilder formal in formals) {
          if (_checkRepresentationDependency(
              formal.type,
              seenExtensionTypeDeclarations.toSet(),
              usedTypeAliasBuilders.toSet())) {
            return true;
          }
        }
      }
      List<TypeVariableBuilder>? typeVariables = unaliased.typeVariables;
      if (typeVariables != null) {
        for (TypeVariableBuilder typeVariable in typeVariables) {
          TypeBuilder? bound = typeVariable.bound;
          if (_checkRepresentationDependency(
              bound,
              seenExtensionTypeDeclarations.toSet(),
              usedTypeAliasBuilders.toSet())) {
            return true;
          }
        }
      }
    } else if (unaliased is RecordTypeBuilder) {
      List<RecordTypeFieldBuilder>? positionalFields =
          unaliased.positionalFields;
      if (positionalFields != null) {
        for (RecordTypeFieldBuilder field in positionalFields) {
          if (_checkRepresentationDependency(
              field.type,
              seenExtensionTypeDeclarations.toSet(),
              usedTypeAliasBuilders.toSet())) {
            return true;
          }
        }
      }
      List<RecordTypeFieldBuilder>? namedFields = unaliased.namedFields;
      if (namedFields != null) {
        for (RecordTypeFieldBuilder field in namedFields) {
          if (_checkRepresentationDependency(
              field.type,
              seenExtensionTypeDeclarations.toSet(),
              usedTypeAliasBuilders.toSet())) {
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    super.buildOutlineExpressions(
        classHierarchy, delayedActionPerformers, delayedDefaultValueCloners);

    Iterator<SourceMemberBuilder> iterator = constructorScope.filteredIterator(
        parent: this, includeDuplicates: false, includeAugmentations: true);
    while (iterator.moveNext()) {
      iterator.current.buildOutlineExpressions(
          classHierarchy, delayedActionPerformers, delayedDefaultValueCloners);
    }
  }

  @override
  void addMemberDescriptorInternal(SourceMemberBuilder memberBuilder,
      Member member, BuiltMemberKind memberKind, Reference memberReference) {
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
      case BuiltMemberKind.ExtensionTearOff:
        unhandled("${member.runtimeType}:${memberKind}", "buildMembers",
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
      case BuiltMemberKind.ExtensionTypeTearOff:
        kind = ExtensionTypeMemberKind.TearOff;
        break;
    }
    extensionTypeDeclaration.members.add(new ExtensionTypeMemberDescriptor(
        name: new Name(name, libraryBuilder.library),
        member: memberReference,
        isStatic: memberBuilder.isStatic,
        kind: kind));
  }

  @override
  void applyPatch(Builder patch) {
    if (patch is SourceExtensionTypeDeclarationBuilder) {
      patch._origin = this;
      if (retainDataForTesting) {
        patchForTesting = patch;
      }
      scope.forEachLocalMember((String name, Builder member) {
        Builder? memberPatch =
            patch.scope.lookupLocalMember(name, setter: false);
        if (memberPatch != null) {
          member.applyPatch(memberPatch);
        }
      });
      scope.forEachLocalSetter((String name, Builder member) {
        Builder? memberPatch =
            patch.scope.lookupLocalMember(name, setter: true);
        if (memberPatch != null) {
          member.applyPatch(memberPatch);
        }
      });

      // TODO(johnniwinther): Check that type parameters and on-type match
      // with origin declaration.
    } else {
      libraryBuilder.addProblem(messagePatchDeclarationMismatch,
          patch.charOffset, noLength, patch.fileUri, context: [
        messagePatchDeclarationOrigin.withLocation(
            fileUri, charOffset, noLength)
      ]);
    }
  }

  /// Looks up the constructor by [name] on the class built by this class
  /// builder.
  SourceExtensionTypeConstructorBuilder? lookupConstructor(Name name) {
    if (name.text == "new") {
      name = new Name("", name.library);
    }

    Builder? builder = constructorScope.lookupLocalMember(name.text);
    if (builder is SourceExtensionTypeConstructorBuilder) {
      return builder;
    }
    return null;
  }

  // TODO(johnniwinther): Implement representationType.
  @override
  DartType get declaredRepresentationType => throw new UnimplementedError();

  @override
  Iterator<T> fullMemberIterator<T extends Builder>() =>
      new ClassDeclarationMemberIterator<SourceExtensionTypeDeclarationBuilder,
              T>(
          const _SourceExtensionTypeDeclarationBuilderAugmentationAccess(),
          this,
          includeDuplicates: false);

  @override
  NameIterator<T> fullMemberNameIterator<T extends Builder>() =>
      new ClassDeclarationMemberNameIterator<
              SourceExtensionTypeDeclarationBuilder, T>(
          const _SourceExtensionTypeDeclarationBuilderAugmentationAccess(),
          this,
          includeDuplicates: false);

  @override
  Iterator<T> fullConstructorIterator<T extends MemberBuilder>() =>
      new ClassDeclarationConstructorIterator<
              SourceExtensionTypeDeclarationBuilder, T>(
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
  bool get isMixinDeclaration => false;

  @override
  bool get hasGenerativeConstructor {
    // TODO(johnniwinther): Support default constructor? and factories.
    return true;
  }

  @override
  BodyBuilderContext get bodyBuilderContext =>
      new ExtensionTypeBodyBuilderContext(this);

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
          TypeAliasBuilder aliasBuilder = declarationBuilder;
          NamedTypeBuilder namedBuilder = interface as NamedTypeBuilder;
          declarationBuilder = aliasBuilder.unaliasDeclaration(
              namedBuilder.arguments,
              isUsedAsClass: true,
              usedAsClassCharOffset: namedBuilder.charOffset,
              usedAsClassFileUri: namedBuilder.fileUri);
          result[declarationBuilder] = aliasBuilder;
        } else {
          result[declarationBuilder] = null;
        }
      }
    }
    return result;
  }
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
