// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';

import '../../base/local_scope.dart';
import '../../base/messages.dart';
import '../../base/scope.dart';
import '../../builder/declaration_builders.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/metadata_builder.dart';
import '../../builder/type_builder.dart';
import '../../kernel/body_builder_context.dart';
import '../../kernel/hierarchy/class_member.dart';
import '../../kernel/hierarchy/members_builder.dart';
import '../../kernel/type_algorithms.dart';
import '../../source/name_scheme.dart';
import '../../source/source_class_builder.dart';
import '../../source/source_library_builder.dart';
import '../../source/source_loader.dart';
import '../../source/source_member_builder.dart';
import '../../source/source_property_builder.dart';
import '../fragment.dart';
import 'body_builder_context.dart';
import 'encoding.dart';

abstract class GetterDeclaration {
  AsyncMarker get asyncModifier;

  Uri get fileUri;

  List<FormalParameterBuilder>? get formals;

  FunctionNode get function;

  bool get isAbstract;

  bool get isExternal;

  List<MetadataBuilder>? get metadata;

  String get name;

  int get nameOffset;

  Procedure get readTarget;

  TypeBuilder get returnType;

  List<TypeParameter>? get thisTypeParameters;

  VariableDeclaration? get thisVariable;

  void becomeNative(SourceLoader loader);

  void buildOutlineExpressions(
      {required ClassHierarchy classHierarchy,
      required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder? declarationBuilder,
      required SourcePropertyBuilder propertyBuilder,
      required Annotatable annotatable,
      required bool isClassInstanceMember,
      required bool createFileUriExpression});

  void buildOutlineNode(
      {required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required BuildNodesCallback f,
      required GetterReference? references,
      required List<TypeParameter>? classTypeParameters});

  void checkTypes(SourceLibraryBuilder libraryBuilder,
      TypeEnvironment typeEnvironment, SourcePropertyBuilder? setterBuilder);

  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment);

  int computeDefaultTypes(ComputeDefaultTypeContext context);

  BodyBuilderContext createBodyBuilderContext(
      SourcePropertyBuilder propertyBuilder);

  void createEncoding(
      ProblemReporting problemReporting,
      SourcePropertyBuilder builder,
      PropertyEncodingStrategy encodingStrategy,
      List<NominalParameterBuilder> unboundNominalParameters);

  LocalScope createFormalParameterScope(LookupScope typeParameterScope);

  void ensureTypes(
      {required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder? declarationBuilder,
      required ClassMembersBuilder membersBuilder,
      required Set<ClassMember>? getterOverrideDependencies});

  Iterable<Reference> getExportedMemberReferences(GetterReference references);

  VariableDeclaration getFormalParameter(int index);
}

class GetterDeclarationImpl implements GetterDeclaration {
  final GetterFragment _fragment;
  late final GetterEncoding _encoding;

  GetterDeclarationImpl(this._fragment) {
    _fragment.declaration = this;
  }

  @override
  AsyncMarker get asyncModifier => _fragment.asyncModifier;

  @override
  Uri get fileUri => _fragment.fileUri;

  @override
  List<FormalParameterBuilder>? get formals => _encoding.formals;

  @override
  FunctionNode get function => _encoding.function;

  @override
  bool get isAbstract => _fragment.modifiers.isAbstract;

  @override
  bool get isExternal => _fragment.modifiers.isExternal;

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
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
  VariableDeclaration? get thisVariable => _encoding.thisVariable;

  @override
  void becomeNative(SourceLoader loader) {
    _encoding.becomeNative(loader);
  }

  @override
  void buildOutlineExpressions(
      {required ClassHierarchy classHierarchy,
      required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder? declarationBuilder,
      required SourcePropertyBuilder propertyBuilder,
      required Annotatable annotatable,
      required bool isClassInstanceMember,
      required bool createFileUriExpression}) {
    _encoding.buildOutlineExpressions(
        classHierarchy,
        libraryBuilder,
        declarationBuilder,
        createBodyBuilderContext(propertyBuilder),
        annotatable,
        isClassInstanceMember: isClassInstanceMember,
        createFileUriExpression: createFileUriExpression);
  }

  @override
  void buildOutlineNode(
      {required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required BuildNodesCallback f,
      required GetterReference? references,
      required List<TypeParameter>? classTypeParameters}) {
    _encoding.buildOutlineNode(
        libraryBuilder: libraryBuilder,
        nameScheme: nameScheme,
        f: f,
        references: references,
        isAbstractOrExternal:
            _fragment.modifiers.isAbstract || _fragment.modifiers.isExternal,
        classTypeParameters: classTypeParameters);
  }

  @override
  void checkTypes(SourceLibraryBuilder libraryBuilder,
      TypeEnvironment typeEnvironment, SourcePropertyBuilder? setterBuilder) {
    _encoding.checkTypes(libraryBuilder, typeEnvironment, setterBuilder,
        isAbstract: isAbstract, isExternal: isExternal);
  }

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    _encoding.checkVariance(sourceClassBuilder, typeEnvironment);
  }

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context) {
    return _encoding.computeDefaultTypes(context);
  }

  @override
  BodyBuilderContext createBodyBuilderContext(
      SourcePropertyBuilder propertyBuilder) {
    return new GetterFragmentBodyBuilderContext(propertyBuilder, this,
        propertyBuilder.libraryBuilder, propertyBuilder.declarationBuilder,
        isDeclarationInstanceMember:
            propertyBuilder.isDeclarationInstanceMember);
  }

  @override
  void createEncoding(
      ProblemReporting problemReporting,
      SourcePropertyBuilder builder,
      PropertyEncodingStrategy encodingStrategy,
      List<NominalParameterBuilder> unboundNominalParameters) {
    _encoding = encodingStrategy.createGetterEncoding(
        builder, _fragment, unboundNominalParameters);
    _fragment.typeParameterNameSpace.addTypeParameters(
        problemReporting, _encoding.clonedAndDeclaredTypeParameters,
        ownerName: _fragment.name, allowNameConflict: true);
    returnType.registerInferredTypeListener(_encoding);
  }

  @override
  LocalScope createFormalParameterScope(LookupScope typeParameterScope) {
    return _encoding.createFormalParameterScope(typeParameterScope);
  }

  @override
  void ensureTypes(
      {required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder? declarationBuilder,
      required ClassMembersBuilder membersBuilder,
      required Set<ClassMember>? getterOverrideDependencies}) {
    if (getterOverrideDependencies != null) {
      membersBuilder.inferGetterType(declarationBuilder as SourceClassBuilder,
          _fragment.returnType, getterOverrideDependencies,
          name: _fragment.name,
          fileUri: _fragment.fileUri,
          nameOffset: _fragment.nameOffset,
          nameLength: _fragment.name.length);
    }
    _encoding.ensureTypes(libraryBuilder, membersBuilder.hierarchyBuilder);
  }

  @override
  Iterable<Reference> getExportedMemberReferences(GetterReference references) =>
      [references.getterReference];

  @override
  VariableDeclaration getFormalParameter(int index) {
    return _encoding.getFormalParameter(index);
  }
}
