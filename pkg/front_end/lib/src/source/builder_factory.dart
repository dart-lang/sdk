// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:kernel/ast.dart' hide Combinator, MapLiteralEntry;

import '../base/combinator.dart' show CombinatorBuilder;
import '../base/configuration.dart' show Configuration;
import '../base/export.dart';
import '../base/identifiers.dart' show Identifier;
import '../base/import.dart';
import '../base/modifiers.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/mixin_application_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/nullability_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/type_builder.dart';
import 'offset_map.dart';
import 'source_class_builder.dart';
import 'source_enum_builder.dart';
import 'source_library_builder.dart';
import 'type_parameter_scope_builder.dart';

abstract class BuilderFactoryResult {
  String? get name;

  bool get isPart;

  String? get partOfName;

  Uri? get partOfUri;

  /// The part directives in this compilation unit.
  List<Part> get parts;

  List<Import> get imports;

  List<Export> get exports;

  List<MetadataBuilder>? get metadata;

  TypeScope get typeScope;

  void takeMixinApplications(
      Map<SourceClassBuilder, TypeBuilder> mixinApplications);

  void collectUnboundTypeVariables(
      SourceLibraryBuilder libraryBuilder,
      Map<NominalVariableBuilder, SourceLibraryBuilder> nominalVariables,
      Map<StructuralVariableBuilder, SourceLibraryBuilder> structuralVariables);

  int finishNativeMethods();

  void registerUnresolvedStructuralVariables(
      List<StructuralVariableBuilder> unboundTypeVariables);

  List<LibraryPart> get libraryParts;
}

abstract class BuilderFactory {
  void beginClassOrNamedMixinApplicationHeader();

  /// Registers that this builder is preparing for a class declaration with the
  /// given [name] and [typeVariables] located at [nameOffset].
  void beginClassDeclaration(
      String name, int nameOffset, List<NominalVariableBuilder>? typeVariables);

  void beginClassBody();

  void endClassDeclaration(String name);

  void endClassDeclarationForParserRecovery(
      List<NominalVariableBuilder>? typeVariables);

  /// Registers that this builder is preparing for a mixin declaration with the
  /// given [name] and [typeVariables] located at [nameOffset].
  void beginMixinDeclaration(
      String name, int nameOffset, List<NominalVariableBuilder>? typeVariables);

  void beginMixinBody();

  void endMixinDeclaration(String name);

  void endMixinDeclarationForParserRecovery(
      List<NominalVariableBuilder>? typeVariables);

  /// Registers that this builder is preparing for a named mixin application
  /// with the given [name] and [typeVariables] located [charOffset].
  void beginNamedMixinApplication(
      String name, int charOffset, List<NominalVariableBuilder>? typeVariables);

  void endNamedMixinApplication(String name);

  void endNamedMixinApplicationForParserRecovery(
      List<NominalVariableBuilder>? typeVariables);

  void beginEnumDeclarationHeader(String name);

  /// Registers that this builder is preparing for an enum declaration with
  /// the given [name] and [typeVariables] located at [nameOffset].
  void beginEnumDeclaration(
      String name, int nameOffset, List<NominalVariableBuilder>? typeVariables);

  void beginEnumBody();

  void endEnumDeclaration(String name);

  void endEnumDeclarationForParserRecovery(
      List<NominalVariableBuilder>? typeVariables);

  void beginExtensionOrExtensionTypeHeader();

  /// Registers that this builder is preparing for an extension declaration with
  /// the given [name] and [typeVariables] located [charOffset].
  void beginExtensionDeclaration(String? name, int charOffset,
      List<NominalVariableBuilder>? typeVariables);

  void beginExtensionBody(TypeBuilder? extensionThisType);

  void endExtensionDeclaration(String? name);

  /// Registers that this builder is preparing for an extension type declaration
  /// with the given [name] and [typeVariables] located at [nameOffset].
  void beginExtensionTypeDeclaration(
      String name, int nameOffset, List<NominalVariableBuilder>? typeVariables);

  void beginExtensionTypeBody();

  void endExtensionTypeDeclaration(String name);

  void beginFactoryMethod();

  void endFactoryMethod();

  void endFactoryMethodForParserRecovery();

  void beginFunctionType();

  void endFunctionType();

  void beginConstructor();

  void endConstructor();

  void endConstructorForParserRecovery(
      List<NominalVariableBuilder>? typeVariables);

  void beginStaticMethod();

  void endStaticMethod();

  void endStaticMethodForParserRecovery(
      List<NominalVariableBuilder>? typeVariables);

  void beginInstanceMethod();

  void endInstanceMethod();

  void endInstanceMethodForParserRecovery(
      List<NominalVariableBuilder>? typeVariables);

  void beginTopLevelMethod();

  void endTopLevelMethod();

  void endTopLevelMethodForParserRecovery(
      List<NominalVariableBuilder>? typeVariables);

  void beginTypedef();

  void endTypedef();

  void endTypedefForParserRecovery(List<NominalVariableBuilder>? typeVariables);

  void checkStacks();

  void addScriptToken(int charOffset);

  void addLibraryDirective(
      {required String? libraryName,
      required List<MetadataBuilder>? metadata,
      required bool isAugment});

  void addPart(OffsetMap offsetMap, Token partKeyword,
      List<MetadataBuilder>? metadata, String uri, int charOffset);

  void addPartOf(List<MetadataBuilder>? metadata, String? name, String? uri,
      int uriOffset);

  void addImport(
      {OffsetMap? offsetMap,
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
      required int uriOffset});

  void addExport(
      OffsetMap offsetMap,
      Token exportKeyword,
      List<MetadataBuilder>? metadata,
      String uri,
      List<Configuration>? configurations,
      List<CombinatorBuilder>? combinators,
      int charOffset,
      int uriOffset);

  void addClass(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required Identifier identifier,
      required List<NominalVariableBuilder>? typeVariables,
      required TypeBuilder? supertype,
      required MixinApplicationBuilder? mixins,
      required List<TypeBuilder>? interfaces,
      required int startOffset,
      required int nameOffset,
      required int endOffset,
      required int supertypeOffset});

  void addEnum(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Identifier identifier,
      required List<NominalVariableBuilder>? typeVariables,
      required MixinApplicationBuilder? supertypeBuilder,
      required List<TypeBuilder>? interfaceBuilders,
      required List<EnumConstantInfo?>? enumConstantInfos,
      required int startOffset,
      required int endOffset});

  void addExtensionDeclaration(
      {required OffsetMap offsetMap,
      required Token beginToken,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required Identifier? identifier,
      required List<NominalVariableBuilder>? typeVariables,
      required TypeBuilder onType,
      required int startOffset,
      required int nameOrExtensionOffset,
      required int endOffset});

  void addExtensionTypeDeclaration(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required Identifier identifier,
      required List<NominalVariableBuilder>? typeVariables,
      required List<TypeBuilder>? interfaces,
      required int startOffset,
      required int endOffset});

  void addMixinDeclaration(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required Identifier identifier,
      required List<NominalVariableBuilder>? typeVariables,
      required List<TypeBuilder>? supertypeConstraints,
      required List<TypeBuilder>? interfaces,
      required int startOffset,
      required int nameOffset,
      required int endOffset});

  void addNamedMixinApplication(
      {required List<MetadataBuilder>? metadata,
      required String name,
      required List<NominalVariableBuilder>? typeVariables,
      required Modifiers modifiers,
      required TypeBuilder? supertype,
      required MixinApplicationBuilder mixinApplication,
      required List<TypeBuilder>? interfaces,
      required int startOffset,
      required int nameOffset,
      required int endOffset});

  MixinApplicationBuilder addMixinApplication(
      List<TypeBuilder> mixins, int charOffset);

  void addFunctionTypeAlias(
      List<MetadataBuilder>? metadata,
      String name,
      List<NominalVariableBuilder>? typeVariables,
      TypeBuilder type,
      int charOffset);

  void addClassMethod(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Identifier identifier,
      required String name,
      required TypeBuilder? returnType,
      required List<FormalParameterBuilder>? formals,
      required List<NominalVariableBuilder>? typeVariables,
      required Token? beginInitializers,
      required int startOffset,
      required int endOffset,
      required int nameOffset,
      required int formalsOffset,
      required Modifiers modifiers,
      required bool inConstructor,
      required bool isStatic,
      required bool isConstructor,
      required bool forAbstractClassOrMixin,
      required bool isExtensionMember,
      required bool isExtensionTypeMember,
      required AsyncMarker asyncModifier,
      required String? nativeMethodName,
      required ProcedureKind? kind});

  void addConstructor(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required Identifier identifier,
      required String constructorName,
      required List<NominalVariableBuilder>? typeVariables,
      required List<FormalParameterBuilder>? formals,
      required int startOffset,
      required int nameOffset,
      required int formalsOffset,
      required int endOffset,
      required String? nativeMethodName,
      required Token? beginInitializers,
      required bool forAbstractClassOrMixin});

  void addPrimaryConstructor(
      {required OffsetMap offsetMap,
      required Token beginToken,
      required String constructorName,
      required List<FormalParameterBuilder>? formals,
      required int startOffset,
      required int? nameOffset,
      required int formalsOffset,
      required bool isConst});

  void addPrimaryConstructorField(
      {required List<MetadataBuilder>? metadata,
      required TypeBuilder type,
      required String name,
      required int charOffset});

  void addFactoryMethod(
      {required OffsetMap offsetMap,
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
      required AsyncMarker asyncModifier});

  String? computeAndValidateConstructorName(
      DeclarationFragment enclosingDeclaration, Identifier identifier,
      {isFactory = false});

  void addMethod(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required TypeBuilder? returnType,
      required Identifier identifier,
      required String name,
      required List<NominalVariableBuilder>? typeVariables,
      required List<FormalParameterBuilder>? formals,
      required ProcedureKind kind,
      required int startOffset,
      required int nameOffset,
      required int formalsOffset,
      required int endOffset,
      required String? nativeMethodName,
      required AsyncMarker asyncModifier,
      required bool isInstanceMember,
      required bool isExtensionMember,
      required bool isExtensionTypeMember});

  void addGetter(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required TypeBuilder? returnType,
      required Identifier identifier,
      required String name,
      required List<NominalVariableBuilder>? typeVariables,
      required List<FormalParameterBuilder>? formals,
      required int startOffset,
      required int nameOffset,
      required int formalsOffset,
      required int endOffset,
      required String? nativeMethodName,
      required AsyncMarker asyncModifier,
      required bool isInstanceMember,
      required bool isExtensionMember,
      required bool isExtensionTypeMember});

  void addSetter(
      {required OffsetMap offsetMap,
      required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required TypeBuilder? returnType,
      required Identifier identifier,
      required String name,
      required List<NominalVariableBuilder>? typeVariables,
      required List<FormalParameterBuilder>? formals,
      required int startOffset,
      required int nameOffset,
      required int formalsOffset,
      required int endOffset,
      required String? nativeMethodName,
      required AsyncMarker asyncModifier,
      required bool isInstanceMember,
      required bool isExtensionMember,
      required bool isExtensionTypeMember});

  void addFields(
      OffsetMap offsetMap,
      List<MetadataBuilder>? metadata,
      Modifiers modifiers,
      bool isTopLevel,
      TypeBuilder? type,
      List<FieldInfo> fieldInfos);

  FormalParameterBuilder addFormalParameter(
      List<MetadataBuilder>? metadata,
      FormalParameterKind kind,
      Modifiers modifiers,
      TypeBuilder type,
      String name,
      bool hasThis,
      bool hasSuper,
      int charOffset,
      Token? initializerToken,
      {bool lowerWildcard = false});

  ConstructorReferenceBuilder addConstructorReference(TypeName name,
      List<TypeBuilder>? typeArguments, String? suffix, int charOffset);

  ConstructorReferenceBuilder? addUnnamedConstructorReference(
      List<TypeBuilder>? typeArguments, Identifier? suffix, int charOffset);

  TypeBuilder addNamedType(
      TypeName typeName,
      NullabilityBuilder nullabilityBuilder,
      List<TypeBuilder>? arguments,
      int charOffset,
      {required InstanceTypeVariableAccessState instanceTypeVariableAccess});

  FunctionTypeBuilder addFunctionType(
      TypeBuilder returnType,
      List<StructuralVariableBuilder>? structuralVariableBuilders,
      List<FormalParameterBuilder>? formals,
      NullabilityBuilder nullabilityBuilder,
      Uri fileUri,
      int charOffset,
      {required bool hasFunctionFormalParameterSyntax});

  TypeBuilder addVoidType(int charOffset);

  InferableTypeBuilder addInferableType();

  NominalVariableBuilder addNominalTypeVariable(List<MetadataBuilder>? metadata,
      String name, TypeBuilder? bound, int charOffset, Uri fileUri,
      {required TypeVariableKind kind});

  StructuralVariableBuilder addStructuralTypeVariable(
      List<MetadataBuilder>? metadata,
      String name,
      TypeBuilder? bound,
      int charOffset,
      Uri fileUri);

  void registerUnboundStructuralVariables(
      List<StructuralVariableBuilder> variableBuilders);
}

class NominalVariableCopy {
  final List<NominalVariableBuilder> newVariableBuilders;
  final List<TypeBuilder> newTypeArguments;
  final Map<NominalVariableBuilder, TypeBuilder> substitutionMap;
  final Map<NominalVariableBuilder, NominalVariableBuilder> newToOldVariableMap;

  NominalVariableCopy(this.newVariableBuilders, this.newTypeArguments,
      this.substitutionMap, this.newToOldVariableMap);
}

class FieldInfo {
  final Identifier identifier;
  final Token? initializerToken;
  final Token? beforeLast;
  final int charEndOffset;

  const FieldInfo(this.identifier, this.initializerToken, this.beforeLast,
      this.charEndOffset);
}
