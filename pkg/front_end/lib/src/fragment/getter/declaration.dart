// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';

import '../../api_prototype/experimental_flags.dart';
import '../../base/local_scope.dart';
import '../../base/messages.dart';
import '../../base/scope.dart';
import '../../base/uri_offset.dart';
import '../../builder/declaration_builders.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/metadata_builder.dart';
import '../../builder/property_builder.dart';
import '../../builder/type_builder.dart';
import '../../kernel/body_builder_context.dart';
import '../../kernel/hierarchy/class_member.dart';
import '../../kernel/hierarchy/members_builder.dart';
import '../../kernel/internal_ast.dart';
import '../../kernel/type_algorithms.dart';
import '../../source/name_scheme.dart';
import '../../source/source_class_builder.dart';
import '../../source/source_library_builder.dart';
import '../../source/source_loader.dart';
import '../../source/source_member_builder.dart';
import '../../source/source_property_builder.dart';
import '../../source/stack_listener_impl.dart' show AsyncModifier;
import '../../source/type_parameter_factory.dart';
import '../../type_inference/context_allocation_strategy.dart';
import '../../type_inference/type_schema.dart';
import '../fragment.dart';
import 'body_builder_context.dart';
import 'encoding.dart';

/// Interface for a getter declaration aspect of a [SourcePropertyBuilder].
abstract class GetterDeclaration {
  Uri get fileUri;

  UriOffsetLength get uriOffset;

  GetterQuality get getterQuality;

  List<MetadataBuilder>? get metadata;

  Member get readTarget;

  void buildGetterOutlineExpressions({
    required ClassHierarchy classHierarchy,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required SourcePropertyBuilder propertyBuilder,
    required Annotatable annotatable,
    required Uri annotatableFileUri,
  });

  void buildGetterOutlineNode({
    required SourceLibraryBuilder libraryBuilder,
    required NameScheme nameScheme,
    required BuildNodesCallback callback,
    required PropertyReferences? references,
    required List<TypeParameter>? classTypeParameters,
  });

  void checkGetterTypes(
    ProblemReporting problemReporting,
    LibraryFeatures libraryFeatures,
    TypeEnvironment typeEnvironment,
    SourcePropertyBuilder? setterBuilder,
  );

  void checkGetterVariance(
    SourceClassBuilder sourceClassBuilder,
    TypeEnvironment typeEnvironment,
  );

  int computeGetterDefaultTypes(ComputeDefaultTypeContext context);

  void createGetterEncoding({
    required ProblemReporting problemReporting,
    required SourcePropertyBuilder builder,
    required PropertyEncodingStrategy encodingStrategy,
    required TypeParameterFactory typeParameterFactory,
    required bool isImplementation,
  });

  void ensureGetterTypes({
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required ClassMembersBuilder membersBuilder,
    required Set<ClassMember>? getterOverrideDependencies,
  });

  List<ClassMember> get localMembers;
}

class RegularGetterDeclaration
    implements GetterDeclaration, GetterFragmentDeclaration {
  final GetterFragment _fragment;
  late final GetterEncoding _encoding;
  late final bool _isImplementation;

  new(this._fragment) {
    _fragment.declaration = this;
  }

  @override
  bool get isImplementation => _isImplementation;

  @override
  UriOffsetLength get uriOffset => _fragment.uriOffset;

  @override
  AsyncModifier get asyncModifier => _fragment.asyncModifier;

  @override
  // Coverage-ignore(suite): Not run.
  Uri get fileUri => _fragment.fileUri;

  @override
  List<FormalParameterBuilder>? get formals => _encoding.formals;

  @override
  bool get isNoSuchMethodForwarder => _encoding.isNoSuchMethodForwarder;

  @override
  GetterQuality get getterQuality => _fragment.modifiers.isAbstract
      ? GetterQuality.Abstract
      : _fragment.modifiers.isExternal
      ? GetterQuality.External
      : GetterQuality.Concrete;

  @override
  bool get isExternal => _fragment.modifiers.isExternal;

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  // Coverage-ignore(suite): Not run.
  String get name => _fragment.name;

  @override
  int get nameOffset => _fragment.nameOffset;

  @override
  Procedure get readTarget => _encoding.readTarget;

  @override
  TypeBuilder get returnType => _fragment.returnType;

  @override
  List<TypeParameter>? get thisTypeParameters => _encoding.thisTypeParameters;

  @override
  InternalVariable? get thisVariable => _encoding.thisVariable;

  @override
  void becomeNative(SourceLoader loader) {
    _encoding.becomeNative(loader);
  }

  @override
  void buildGetterOutlineExpressions({
    required ClassHierarchy classHierarchy,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required SourcePropertyBuilder propertyBuilder,
    required Annotatable annotatable,
    required Uri annotatableFileUri,
  }) {
    _encoding.buildOutlineExpressions(
      classHierarchy: classHierarchy,
      libraryBuilder: libraryBuilder,
      declarationBuilder: declarationBuilder,
      propertyBuilder: propertyBuilder,
      bodyBuilderContext: createBodyBuilderContext(propertyBuilder),
      annotatable: annotatable,
      annotatableFileUri: annotatableFileUri,
    );
  }

  @override
  void buildGetterOutlineNode({
    required SourceLibraryBuilder libraryBuilder,
    required NameScheme nameScheme,
    required BuildNodesCallback callback,
    required PropertyReferences? references,
    required List<TypeParameter>? classTypeParameters,
  }) {
    _encoding.buildOutlineNode(
      libraryBuilder: libraryBuilder,
      nameScheme: nameScheme,
      callback: callback,
      references: references,
      isAbstractOrExternal:
          _fragment.modifiers.isAbstract || _fragment.modifiers.isExternal,
      classTypeParameters: classTypeParameters,
    );
  }

  @override
  void checkGetterTypes(
    ProblemReporting problemReporting,
    LibraryFeatures libraryFeatures,
    TypeEnvironment typeEnvironment,
    SourcePropertyBuilder? setterBuilder,
  ) {
    _encoding.checkTypes(
      problemReporting,
      libraryFeatures,
      typeEnvironment,
      setterBuilder,
      isAbstract: _fragment.modifiers.isAbstract,
      isExternal: _fragment.modifiers.isExternal,
    );
  }

  @override
  void checkGetterVariance(
    SourceClassBuilder sourceClassBuilder,
    TypeEnvironment typeEnvironment,
  ) {
    _encoding.checkVariance(sourceClassBuilder, typeEnvironment);
  }

  @override
  int computeGetterDefaultTypes(ComputeDefaultTypeContext context) {
    return _encoding.computeDefaultTypes(context);
  }

  @override
  BodyBuilderContext createBodyBuilderContext(
    SourcePropertyBuilder propertyBuilder,
  ) {
    return new GetterFragmentBodyBuilderContext(
      propertyBuilder,
      this,
      propertyBuilder.libraryBuilder,
      propertyBuilder.declarationBuilder,
      isDeclarationInstanceMember: propertyBuilder.isDeclarationInstanceMember,
    );
  }

  @override
  void createGetterEncoding({
    required ProblemReporting problemReporting,
    required SourcePropertyBuilder builder,
    required PropertyEncodingStrategy encodingStrategy,
    required TypeParameterFactory typeParameterFactory,
    required bool isImplementation,
  }) {
    _isImplementation = isImplementation;
    _fragment.builder = builder;
    typeParameterFactory.createNominalParameterBuilders(
      _fragment.declaredTypeParameters,
    );

    _encoding = encodingStrategy.createGetterEncoding(
      builder,
      _fragment,
      typeParameterFactory,
    );
    _fragment.typeParameterNameSpace.addTypeParameters(
      problemReporting,
      _encoding.clonedAndDeclaredTypeParameters,
      ownerName: _fragment.name,
      allowNameConflict: true,
    );
    _fragment.returnType.registerInferredTypeListener(_encoding);
  }

  @override
  LocalScope createFormalParameterScope(LookupScope typeParameterScope) {
    return _encoding.createFormalParameterScope(typeParameterScope);
  }

  @override
  void ensureGetterTypes({
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required ClassMembersBuilder membersBuilder,
    required Set<ClassMember>? getterOverrideDependencies,
  }) {
    if (getterOverrideDependencies != null) {
      membersBuilder.inferGetterType(
        declarationBuilder as SourceClassBuilder,
        _fragment.returnType,
        getterOverrideDependencies,
        name: _fragment.name,
        fileUri: _fragment.fileUri,
        nameOffset: _fragment.nameOffset,
        nameLength: _fragment.name.length,
      );
    }
    _encoding.ensureTypes(libraryBuilder, membersBuilder.hierarchyBuilder);
  }

  @override
  List<ClassMember> get localMembers => [
    new GetterClassMember(_fragment.builder),
  ];

  @override
  void registerFunctionBody({
    required Statement? body,
    required AsyncModifier asyncModifier,
    required DartType? emittedValueType,
    required ScopeProviderInfo? scopeProviderInfo,
  }) {
    assert(
      asyncModifier.kind == this.asyncModifier.kind,
      "Unexpected change in async modifier on $this from "
      "${asyncModifier} to ${this.asyncModifier.kind}.",
    );
    _encoding.registerFunctionBody(
      body: body,
      asyncModifier: asyncModifier,
      emittedValueType: emittedValueType,
      scopeProviderInfo: scopeProviderInfo,
    );
  }

  @override
  DartType get returnTypeContext {
    final bool isReturnTypeUndeclared =
        returnType is OmittedTypeBuilder &&
        _encoding.function.returnType is DynamicType;
    return isReturnTypeUndeclared
        ? const UnknownType()
        : _encoding.function.returnType;
  }

  @override
  String toString() => '$runtimeType($_fragment)';
}

/// Interface for using a [GetterFragment] to create a [BodyBuilderContext].
abstract class GetterFragmentDeclaration {
  AsyncModifier get asyncModifier;

  List<FormalParameterBuilder>? get formals;

  bool get isNoSuchMethodForwarder;

  bool get isExternal;

  /// Whether this declaration hold the implementation for the getter.
  ///
  /// For augmentations, only one of the getter declarations is considered
  /// as the implementation. Other declarations can only provide annotations
  /// for the generated AST node.
  bool get isImplementation;

  String get name;

  int get nameOffset;

  TypeBuilder get returnType;

  List<TypeParameter>? get thisTypeParameters;

  InternalVariable? get thisVariable;

  void becomeNative(SourceLoader loader);

  BodyBuilderContext createBodyBuilderContext(
    SourcePropertyBuilder propertyBuilder,
  );

  LocalScope createFormalParameterScope(LookupScope typeParameterScope);

  void registerFunctionBody({
    required Statement? body,
    required AsyncModifier asyncModifier,
    required DartType? emittedValueType,
    required ScopeProviderInfo? scopeProviderInfo,
  });

  DartType get returnTypeContext;
}
