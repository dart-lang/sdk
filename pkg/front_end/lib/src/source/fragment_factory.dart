// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:kernel/ast.dart' hide Combinator, MapLiteralEntry;

import '../api_prototype/lowering_predicates.dart';
import '../base/combinator.dart' show CombinatorBuilder;
import '../base/configuration.dart' show Configuration;
import '../base/identifiers.dart' show Identifier;
import '../base/modifiers.dart';
import '../base/scope.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/type_builder.dart';
import '../fragment/fragment.dart';
import '../util/helpers.dart';
import 'offset_map.dart';
import 'source_type_parameter_builder.dart';
import 'type_parameter_factory.dart';

abstract class FragmentFactory {
  void beginClassOrNamedMixinApplicationHeader();

  /// Registers that this builder is preparing for a class declaration with the
  /// given [name] and [typeParameters] located at [nameOffset].
  void beginClassDeclaration(
    String name,
    int nameOffset,
    List<TypeParameterFragment>? typeParameters,
  );

  void beginClassBody();

  ClassFragment endClassDeclaration();

  void endClassDeclarationForParserRecovery(
    List<TypeParameterFragment>? typeParameters,
  );

  /// Registers that this builder is preparing for a mixin declaration with the
  /// given [name] and [typeParameters] located at [nameOffset].
  void beginMixinDeclaration(
    String name,
    int nameOffset,
    List<TypeParameterFragment>? typeParameters,
  );

  void beginMixinBody();

  MixinFragment endMixinDeclaration();

  void endMixinDeclarationForParserRecovery(
    List<TypeParameterFragment>? typeParameters,
  );

  /// Registers that this builder is preparing for a named mixin application
  /// with the given [name] and [typeParameters] located [charOffset].
  void beginNamedMixinApplication(
    String name,
    int charOffset,
    List<TypeParameterFragment>? typeParameters,
  );

  // TODO(johnniwinther): Avoid returning the type parameter scope here. Should
  // named mixin applications be created in the begin method, similar to the
  // other declarations?
  LookupScope endNamedMixinApplication(String name);

  void endNamedMixinApplicationForParserRecovery(
    List<TypeParameterFragment>? typeParameters,
  );

  void beginEnumDeclarationHeader();

  /// Registers that this builder is preparing for an enum declaration with
  /// the given [name] and [typeParameters] located at [nameOffset].
  void beginEnumDeclaration(
    String name,
    int nameOffset,
    List<TypeParameterFragment>? typeParameters,
  );

  void beginEnumBody();

  EnumFragment endEnumDeclaration();

  void endEnumDeclarationForParserRecovery(
    List<TypeParameterFragment>? typeParameters,
  );

  void beginExtensionOrExtensionTypeHeader();

  /// Registers that this builder is preparing for an extension declaration with
  /// the given [name] and [typeParameters] located at [nameOrExtensionOffset].
  ///
  /// If the extension is unnamed, [nameOrExtensionOffset] is the offset of the
  /// `extension` keyword. Otherwise it is the offset of the extension name.
  void beginExtensionDeclaration(
    String? name,
    int nameOrExtensionOffset,
    List<TypeParameterFragment>? typeParameters,
  );

  void beginExtensionBody();

  ExtensionFragment endExtensionDeclaration();

  /// Registers that this builder is preparing for an extension type declaration
  /// with the given [name] and [typeParameters] located at [nameOffset].
  void beginExtensionTypeDeclaration(
    String name,
    int nameOffset,
    List<TypeParameterFragment>? typeParameters,
  );

  void beginExtensionTypeBody();

  ExtensionTypeFragment endExtensionTypeDeclaration();

  void beginFactoryMethod();

  void endFactoryMethodForParserRecovery();

  void beginFunctionType();

  void endFunctionType();

  void beginConstructor();

  void endConstructorForParserRecovery(
    List<TypeParameterFragment>? typeParameters,
  );

  void beginStaticMethod();

  void endStaticMethodForParserRecovery(
    List<TypeParameterFragment>? typeParameters,
  );

  void beginInstanceMethod();

  void endInstanceMethodForParserRecovery(
    List<TypeParameterFragment>? typeParameters,
  );

  void beginTopLevelMethod();

  void endTopLevelMethodForParserRecovery(
    List<TypeParameterFragment>? typeParameters,
  );

  void beginTypedef();

  void endTypedef();

  void endTypedefForParserRecovery(List<TypeParameterFragment>? typeParameters);

  void checkStacks();

  void addScriptToken(int charOffset);

  void addLibraryDirective({
    required String? libraryName,
    required int fileOffset,
    required List<MetadataBuilder>? metadata,
  });

  void addPart(
    OffsetMap offsetMap,
    Token partKeyword,
    List<MetadataBuilder>? metadata,
    String uri,
    int charOffset,
  );

  void addPartOfWithName({
    required List<MetadataBuilder>? metadata,
    required String name,
    required int fileOffset,
  });

  void addPartOfWithUri({
    required List<MetadataBuilder>? metadata,
    required String uri,
    required int uriOffset,
    required int fileOffset,
  });

  void addImport({
    OffsetMap? offsetMap,
    Token? importKeyword,
    required List<MetadataBuilder>? metadata,
    required bool isAugmentationImport,
    required String uri,
    required List<Configuration>? configurations,
    required String? prefix,
    required List<CombinatorBuilder>? combinators,
    required bool deferred,
    required int charOffset,
    required int prefixCharOffset,
    required int uriOffset,
  });

  void addExport(
    OffsetMap offsetMap,
    Token exportKeyword,
    List<MetadataBuilder>? metadata,
    String uri,
    List<Configuration>? configurations,
    List<CombinatorBuilder>? combinators,
    int charOffset,
    int uriOffset,
  );

  void addClass({
    required OffsetMap offsetMap,
    required List<MetadataBuilder>? metadata,
    required Modifiers modifiers,
    required Identifier identifier,
    required List<TypeParameterFragment>? typeParameters,
    required TypeBuilder? supertype,
    required List<TypeBuilder>? mixins,
    required List<TypeBuilder>? interfaces,
    required int startOffset,
    required int nameOffset,
    required int endOffset,
    required int supertypeOffset,
  });

  void addEnum({
    required OffsetMap offsetMap,
    required List<MetadataBuilder>? metadata,
    required Identifier identifier,
    required List<TypeParameterFragment>? typeParameters,
    required List<TypeBuilder>? mixins,
    required List<TypeBuilder>? interfaces,
    required int startOffset,
    required int endOffset,
  });

  void addEnumElement({
    required List<MetadataBuilder>? metadata,
    required String name,
    required int nameOffset,
    required ConstructorReferenceBuilder? constructorReferenceBuilder,
    required Token? argumentsBeginToken,
  });

  void addExtensionDeclaration({
    required OffsetMap offsetMap,
    required Token beginToken,
    required List<MetadataBuilder>? metadata,
    required Modifiers modifiers,
    required Identifier? identifier,
    required List<TypeParameterFragment>? typeParameters,
    required TypeBuilder onType,
    required int startOffset,
    required int endOffset,
  });

  void addExtensionTypeDeclaration({
    required OffsetMap offsetMap,
    required List<MetadataBuilder>? metadata,
    required Modifiers modifiers,
    required Identifier identifier,
    required List<TypeParameterFragment>? typeParameters,
    required List<TypeBuilder>? interfaces,
    required int startOffset,
    required int endOffset,
  });

  void addMixinDeclaration({
    required OffsetMap offsetMap,
    required List<MetadataBuilder>? metadata,
    required Modifiers modifiers,
    required Identifier identifier,
    required List<TypeParameterFragment>? typeParameters,
    required List<TypeBuilder>? supertypeConstraints,
    required List<TypeBuilder>? interfaces,
    required int startOffset,
    required int nameOffset,
    required int endOffset,
  });

  void addNamedMixinApplication({
    required List<MetadataBuilder>? metadata,
    required String name,
    required List<TypeParameterFragment>? typeParameters,
    required Modifiers modifiers,
    required TypeBuilder? supertype,
    required List<TypeBuilder> mixins,
    required List<TypeBuilder>? interfaces,
    required int startOffset,
    required int nameOffset,
    required int endOffset,
  });

  void addFunctionTypeAlias(
    List<MetadataBuilder>? metadata,
    String name,
    List<TypeParameterFragment>? typeParameters,
    TypeBuilder type,
    int nameOffset,
  );

  void addClassMethod({
    required OffsetMap offsetMap,
    required List<MetadataBuilder>? metadata,
    required Identifier identifier,
    required String name,
    required TypeBuilder? returnType,
    required List<FormalParameterBuilder>? formals,
    required List<TypeParameterFragment>? typeParameters,
    required Token? beginInitializers,
    required int startOffset,
    required int endOffset,
    required int nameOffset,
    required int formalsOffset,
    required Modifiers modifiers,
    required bool isStatic,
    required bool forAbstractClassOrMixin,
    required bool isExtensionMember,
    required bool isExtensionTypeMember,
    required AsyncMarker asyncModifier,
    required String? nativeMethodName,
    required ProcedureKind kind,
  });

  void addConstructor({
    required OffsetMap offsetMap,
    required List<MetadataBuilder>? metadata,
    required Modifiers modifiers,
    required Identifier identifier,
    required List<TypeParameterFragment>? typeParameters,
    required List<FormalParameterBuilder>? formals,
    required int startOffset,
    required int formalsOffset,
    required int endOffset,
    required String? nativeMethodName,
    required Token? beginInitializers,
    required bool hasNewKeyword,
    required bool forAbstractClassOrMixin,
  });

  void addPrimaryConstructor({
    required OffsetMap offsetMap,
    required Token beginToken,
    required String? name,
    required List<FormalParameterBuilder>? formals,
    required int startOffset,
    required int? nameOffset,
    required int formalsOffset,
    required bool isConst,
  });

  void addPrimaryConstructorBody({
    required OffsetMap offsetMap,
    required Token beginToken,
    required List<MetadataBuilder>? metadata,
    required int endOffset,
    required Token? beginInitializers,
    required bool hasBody,
    required int bodyOffset,
  });

  void addPrimaryConstructorField({
    required List<MetadataBuilder>? metadata,
    required Modifiers modifiers,
    required TypeBuilder type,
    required String name,
    required int nameOffset,
    required Token? defaultValueToken,
  });

  void addFactoryMethod({
    required OffsetMap offsetMap,
    required List<MetadataBuilder>? metadata,
    required Modifiers modifiers,
    required Identifier identifier,
    required List<FormalParameterBuilder>? formals,
    required ConstructorReferenceBuilder? redirectionTarget,
    required int startOffset,
    required int nameOffset,
    required int formalsOffset,
    required int endOffset,
    required String? nativeMethodName,
    required AsyncMarker asyncModifier,
  });

  ConstructorName computeAndValidateConstructorName(
    DeclarationFragmentImpl enclosingDeclaration,
    Identifier identifier, {
    bool hasNewKeyword = false,
    bool isFactory = false,
  });

  void addMethod({
    required OffsetMap offsetMap,
    required List<MetadataBuilder>? metadata,
    required Modifiers modifiers,
    required TypeBuilder? returnType,
    required Identifier identifier,
    required String name,
    required List<TypeParameterFragment>? typeParameters,
    required List<FormalParameterBuilder>? formals,
    required int startOffset,
    required int nameOffset,
    required int formalsOffset,
    required int endOffset,
    required String? nativeMethodName,
    required AsyncMarker asyncModifier,
    required bool isInstanceMember,
    required bool isExtensionMember,
    required bool isExtensionTypeMember,
    required bool isOperator,
  });

  void addGetter({
    required OffsetMap offsetMap,
    required List<MetadataBuilder>? metadata,
    required Modifiers modifiers,
    required TypeBuilder? returnType,
    required Identifier identifier,
    required String name,
    required List<TypeParameterFragment>? typeParameters,
    required List<FormalParameterBuilder>? formals,
    required int startOffset,
    required int nameOffset,
    required int formalsOffset,
    required int endOffset,
    required String? nativeMethodName,
    required AsyncMarker asyncModifier,
    required bool isInstanceMember,
    required bool isExtensionMember,
    required bool isExtensionTypeMember,
  });

  void addSetter({
    required OffsetMap offsetMap,
    required List<MetadataBuilder>? metadata,
    required Modifiers modifiers,
    required TypeBuilder? returnType,
    required Identifier identifier,
    required String name,
    required List<TypeParameterFragment>? typeParameters,
    required List<FormalParameterBuilder>? formals,
    required int startOffset,
    required int nameOffset,
    required int formalsOffset,
    required int endOffset,
    required String? nativeMethodName,
    required AsyncMarker asyncModifier,
    required bool isInstanceMember,
    required bool isExtensionMember,
    required bool isExtensionTypeMember,
  });

  void addFields(
    OffsetMap offsetMap,
    List<MetadataBuilder>? metadata,
    Modifiers modifiers,
    bool isTopLevel,
    TypeBuilder? type,
    List<FieldInfo> fieldInfos,
  );

  FormalParameterBuilder addFormalParameter({
    required List<MetadataBuilder>? metadata,
    required FormalParameterKind kind,
    required Modifiers modifiers,
    required TypeBuilder type,
    required String name,
    required String? publicName,
    required bool hasThis,
    required bool hasSuper,
    required int nameOffset,
    required Token? initializerToken,
    bool lowerWildcard = false,
  });

  ConstructorReferenceBuilder addConstructorReference(
    TypeName name,
    List<TypeBuilder>? typeArguments,
    String? suffix,
    int charOffset,
  );

  ConstructorReferenceBuilder? addUnnamedConstructorReference(
    List<TypeBuilder>? typeArguments,
    Identifier? suffix,
    int charOffset,
  );

  TypeBuilder addNamedType(
    TypeName typeName,
    NullabilityBuilder nullabilityBuilder,
    List<TypeBuilder>? arguments,
    int charOffset, {
    required InstanceTypeParameterAccessState instanceTypeParameterAccess,
  });

  FunctionTypeBuilder addFunctionType(
    TypeBuilder returnType,
    List<SourceStructuralParameterBuilder>? structuralParameterBuilders,
    List<FormalParameterBuilder>? formals,
    NullabilityBuilder nullabilityBuilder,
    Uri fileUri,
    int charOffset, {
    required bool hasFunctionFormalParameterSyntax,
  });

  TypeBuilder addVoidType(int charOffset);

  InferableTypeBuilder addInferableType(
    InferenceDefaultType inferenceDefaultType,
  );

  TypeParameterFragment addNominalParameter({
    required List<MetadataBuilder>? metadata,
    required String name,
    required int nameOffset,
    required Uri fileUri,
    required TypeParameterKind kind,
  });

  StructuralParameterBuilder addStructuralParameter({
    required List<MetadataBuilder>? metadata,
    required String name,
    required int nameOffset,
    required Uri fileUri,
  });
}

/// The synthesized type parameters and this formal for an extension instance
/// member.
class SynthesizedExtensionSignature {
  final List<SourceNominalParameterBuilder>? clonedDeclarationTypeParameters;
  final FormalParameterBuilder thisFormal;

  SynthesizedExtensionSignature._(
    this.clonedDeclarationTypeParameters,
    this.thisFormal,
  );

  factory SynthesizedExtensionSignature({
    required ExtensionBuilder declarationBuilder,
    required List<TypeParameterFragment>? extensionTypeParameterFragments,
    required TypeBuilder onTypeBuilder,
    required TypeParameterFactory typeParameterFactory,
    required Uri fileUri,
    required int fileOffset,
    required bool isClosureContextLoweringEnabled,
  }) {
    NominalParameterCopy? nominalVariableCopy = typeParameterFactory
        .copyTypeParameters(
          oldParameterBuilders: declarationBuilder.typeParameters,
          oldParameterFragments: extensionTypeParameterFragments,
          kind: TypeParameterKind.extensionSynthesized,
          instanceTypeParameterAccess: InstanceTypeParameterAccessState.Allowed,
        );

    List<SourceNominalParameterBuilder>? clonedDeclarationTypeParameters =
        nominalVariableCopy?.newParameterBuilders;

    TypeBuilder thisType = onTypeBuilder;
    if (nominalVariableCopy != null) {
      thisType = nominalVariableCopy.createInContext(thisType);
    }

    FormalParameterBuilder thisFormal = new FormalParameterBuilder(
      kind: FormalParameterKind.requiredPositional,
      modifiers: Modifiers.Final,
      type: thisType,
      name: syntheticThisName,
      nameOffset: null,
      fileOffset: fileOffset,
      fileUri: fileUri,
      isExtensionThis: true,
      hasImmediatelyDeclaredInitializer: false,
      isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
    );
    return new SynthesizedExtensionSignature._(
      clonedDeclarationTypeParameters,
      thisFormal,
    );
  }
}

/// The synthesized type parameters and this formal for an extension type
/// instance member.
class SynthesizedExtensionTypeSignature {
  final List<SourceNominalParameterBuilder>? clonedDeclarationTypeParameters;
  final FormalParameterBuilder thisFormal;

  SynthesizedExtensionTypeSignature._(
    this.clonedDeclarationTypeParameters,
    this.thisFormal,
  );

  factory SynthesizedExtensionTypeSignature({
    required ExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder,
    required List<TypeParameterFragment>? extensionTypeTypeParameters,
    required TypeParameterFactory typeParameterFactory,
    required Uri fileUri,
    required int fileOffset,
    required bool isClosureContextLoweringEnabled,
  }) {
    NominalParameterCopy? nominalVariableCopy = typeParameterFactory
        .copyTypeParameters(
          oldParameterBuilders: extensionTypeDeclarationBuilder.typeParameters,
          oldParameterFragments: extensionTypeTypeParameters,
          kind: TypeParameterKind.extensionSynthesized,
          instanceTypeParameterAccess: InstanceTypeParameterAccessState.Allowed,
        );

    List<SourceNominalParameterBuilder>? clonedDeclarationTypeParameters =
        nominalVariableCopy?.newParameterBuilders;

    TypeBuilder thisType = new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
      extensionTypeDeclarationBuilder,
      const NullabilityBuilder.omitted(),
      arguments: extensionTypeTypeParameters != null
          ? new List<TypeBuilder>.generate(
              extensionTypeTypeParameters.length,
              (int index) =>
                  new NamedTypeBuilderImpl.fromTypeDeclarationBuilder(
                    clonedDeclarationTypeParameters![index],
                    const NullabilityBuilder.omitted(),
                    instanceTypeParameterAccess:
                        InstanceTypeParameterAccessState.Allowed,
                  ),
            )
          : null,
      instanceTypeParameterAccess: InstanceTypeParameterAccessState.Allowed,
    );

    if (nominalVariableCopy != null) {
      thisType = nominalVariableCopy.createInContext(thisType);
    }

    FormalParameterBuilder thisFormal = new FormalParameterBuilder(
      kind: FormalParameterKind.requiredPositional,
      modifiers: Modifiers.Final,
      type: thisType,
      name: syntheticThisName,
      nameOffset: null,
      fileOffset: fileOffset,
      fileUri: fileUri,
      isExtensionThis: true,
      hasImmediatelyDeclaredInitializer: false,
      isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
    );

    return new SynthesizedExtensionTypeSignature._(
      clonedDeclarationTypeParameters,
      thisFormal,
    );
  }
}

class FieldInfo {
  final Identifier identifier;
  final Token? initializerToken;
  final Token? beforeLast;
  final int endOffset;

  const FieldInfo(
    this.identifier,
    this.initializerToken,
    this.beforeLast,
    this.endOffset,
  );
}
