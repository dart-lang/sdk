// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';

import '../../base/compiler_context.dart';
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
import '../../kernel/type_algorithms.dart';
import '../../source/check_helper.dart';
import '../../source/name_scheme.dart';
import '../../source/source_class_builder.dart';
import '../../source/source_library_builder.dart';
import '../../source/source_loader.dart';
import '../../source/source_member_builder.dart';
import '../../source/source_property_builder.dart';
import '../../source/type_parameter_factory.dart';
import '../../type_inference/external_ast_helper.dart';
import '../../type_inference/type_schema.dart';
import '../fragment.dart';
import 'body_builder_context.dart';
import 'encoding.dart';

/// Interface for a setter declaration aspect of a [SourcePropertyBuilder].
abstract class SetterDeclaration {
  Uri get fileUri;

  UriOffsetLength get uriOffset;

  List<MetadataBuilder>? get metadata;

  SetterQuality get setterQuality;

  Member? get writeTarget;

  void buildSetterOutlineExpressions({
    required ClassHierarchy classHierarchy,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required SourcePropertyBuilder propertyBuilder,
    required Annotatable annotatable,
    required Uri annotatableFileUri,
  });

  void buildSetterOutlineNode({
    required SourceLibraryBuilder libraryBuilder,
    required ProblemReporting problemReporting,
    required NameScheme nameScheme,
    required BuildNodesCallback f,
    required PropertyReferences? references,
    required List<TypeParameter>? classTypeParameters,
  });

  void checkSetterTypes(
    ProblemReporting problemReporting,
    TypeEnvironment typeEnvironment,
  );

  void checkSetterVariance(
    SourceClassBuilder sourceClassBuilder,
    TypeEnvironment typeEnvironment,
  );

  int computeSetterDefaultTypes(ComputeDefaultTypeContext context);

  void createSetterEncoding(
    ProblemReporting problemReporting,
    SourcePropertyBuilder builder,
    PropertyEncodingStrategy encodingStrategy,
    TypeParameterFactory typeParameterFactory,
  );

  void ensureSetterTypes({
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required ClassMembersBuilder membersBuilder,
    required Set<ClassMember>? setterOverrideDependencies,
  });

  Iterable<Reference> getExportedSetterReferences(
    PropertyReferences references,
  );

  List<ClassMember> get localSetters;
}

class RegularSetterDeclaration
    implements SetterDeclaration, SetterFragmentDeclaration {
  final SetterFragment _fragment;
  late final SetterEncoding _encoding;

  RegularSetterDeclaration(this._fragment) {
    _fragment.declaration = this;
  }

  @override
  UriOffsetLength get uriOffset => _fragment.uriOffset;

  @override
  // Coverage-ignore(suite): Not run.
  Uri get fileUri => _fragment.fileUri;

  @override
  List<FormalParameterBuilder>? get formals => _encoding.formals;

  @override
  bool get isNoSuchMethodForwarder => _encoding.isNoSuchMethodForwarder;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAbstract => _fragment.modifiers.isAbstract;

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
  TypeBuilder get returnType => _fragment.returnType;

  @override
  SetterQuality get setterQuality => _fragment.modifiers.isAbstract
      ? SetterQuality.Abstract
      : _fragment.modifiers.isExternal
      ? SetterQuality.External
      : SetterQuality.Concrete;

  @override
  List<TypeParameter>? get thisTypeParameters => _encoding.thisTypeParameters;

  @override
  VariableDeclaration? get thisVariable => _encoding.thisVariable;

  @override
  Procedure get writeTarget => _encoding.writeTarget;

  @override
  void becomeNative(SourceLoader loader) {
    _encoding.becomeNative(loader);
  }

  @override
  void buildSetterOutlineExpressions({
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
  void buildSetterOutlineNode({
    required SourceLibraryBuilder libraryBuilder,
    required ProblemReporting problemReporting,
    required NameScheme nameScheme,
    required BuildNodesCallback f,
    required PropertyReferences? references,
    required List<TypeParameter>? classTypeParameters,
  }) {
    _encoding.buildOutlineNode(
      libraryBuilder: libraryBuilder,
      problemReporting: problemReporting,
      nameScheme: nameScheme,
      f: f,
      references: references,
      isAbstractOrExternal:
          _fragment.modifiers.isAbstract || _fragment.modifiers.isExternal,
      classTypeParameters: classTypeParameters,
    );
  }

  @override
  void checkSetterTypes(
    ProblemReporting problemReporting,
    TypeEnvironment typeEnvironment,
  ) {
    _encoding.checkTypes(
      problemReporting,
      typeEnvironment,
      isAbstract: _fragment.modifiers.isAbstract,
      isExternal: _fragment.modifiers.isExternal,
    );
  }

  @override
  void checkSetterVariance(
    SourceClassBuilder sourceClassBuilder,
    TypeEnvironment typeEnvironment,
  ) {
    _encoding.checkVariance(sourceClassBuilder, typeEnvironment);
  }

  @override
  int computeSetterDefaultTypes(ComputeDefaultTypeContext context) {
    return _encoding.computeDefaultTypes(context);
  }

  @override
  BodyBuilderContext createBodyBuilderContext(
    SourcePropertyBuilder propertyBuilder,
  ) {
    return new SetterBodyBuilderContext(
      propertyBuilder,
      this,
      propertyBuilder.libraryBuilder,
      propertyBuilder.declarationBuilder,
      isDeclarationInstanceMember: propertyBuilder.isDeclarationInstanceMember,
    );
  }

  @override
  void createSetterEncoding(
    ProblemReporting problemReporting,
    SourcePropertyBuilder builder,
    PropertyEncodingStrategy encodingStrategy,
    TypeParameterFactory typeParameterFactory,
  ) {
    _fragment.builder = builder;
    typeParameterFactory.createNominalParameterBuilders(
      _fragment.declaredTypeParameters,
    );
    _encoding = encodingStrategy.createSetterEncoding(
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
  }

  @override
  LocalScope createFormalParameterScope(LookupScope typeParameterScope) {
    return _encoding.createFormalParameterScope(typeParameterScope);
  }

  @override
  void ensureSetterTypes({
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required ClassMembersBuilder membersBuilder,
    required Set<ClassMember>? setterOverrideDependencies,
  }) {
    if (setterOverrideDependencies != null) {
      membersBuilder.inferSetterType(
        declarationBuilder as SourceClassBuilder,
        _fragment.declaredFormals,
        setterOverrideDependencies,
        name: _fragment.name,
        fileUri: _fragment.fileUri,
        nameOffset: _fragment.nameOffset,
        nameLength: _fragment.name.length,
      );
    }
    _encoding.ensureTypes(libraryBuilder, membersBuilder.hierarchyBuilder);
  }

  @override
  Iterable<Reference> getExportedSetterReferences(
    PropertyReferences references,
  ) => [references.setterReference];

  @override
  List<ClassMember> get localSetters => [
    new SetterClassMember(_fragment.builder),
  ];

  @override
  void registerFunctionBody({
    required CompilerContext compilerContext,
    required ProblemReporting problemReporting,
    required Statement? body,
    required Scope? scope,
    required AsyncMarker asyncMarker,
    required DartType? emittedValueType,
  }) {
    List<FormalParameterBuilder>? declaredFormals = _fragment.declaredFormals;
    if (declaredFormals == null ||
        declaredFormals.length != 1 ||
        declaredFormals.single.isOptionalPositional) {
      int fileOffset = _fragment.formalsOffset;
      if (body == null) {
        body = new EmptyStatement()..fileOffset = fileOffset;
      }
      if (declaredFormals != null) {
        // Illegal parameters were removed by the function builder.
        // Add them as local variable to put them in scope of the body.
        List<Statement> statements = <Statement>[];
        for (FormalParameterBuilder parameter in declaredFormals) {
          statements.add(parameter.variable!);
        }
        statements.add(body);
        body = createBlock(statements, fileOffset: fileOffset);
      }
      body = createBlock([
        createExpressionStatement(
          problemReporting.buildProblem(
            compilerContext: compilerContext,
            message: diag.setterWithWrongNumberOfFormals,
            fileUri: _fragment.fileUri,
            fileOffset: fileOffset,
            length: noLength,
          ),
        ),
        body,
      ], fileOffset: fileOffset);
    }
    assert(
      asyncMarker == _fragment.asyncModifier,
      "Unexpected change in async modifier on $this from "
      "${_fragment.asyncModifier} to $asyncMarker.",
    );
    _encoding.registerFunctionBody(
      body: body,
      // TODO(cstefantsova): Update scope to handle the insertion of parameters
      // as locals above.
      scope: scope,
      asyncMarker: asyncMarker,
      emittedValueType: emittedValueType,
    );
  }

  @override
  DartType get returnTypeContext {
    final bool isReturnTypeUndeclared =
        returnType is OmittedTypeBuilder &&
        // Coverage-ignore(suite): Not run.
        _encoding.function.returnType is DynamicType;
    return isReturnTypeUndeclared
        ? const UnknownType()
        : _encoding.function.returnType;
  }
}

/// Interface for using a [SetterFragment] to create a [BodyBuilderContext].
abstract class SetterFragmentDeclaration {
  List<FormalParameterBuilder>? get formals;

  bool get isNoSuchMethodForwarder;

  bool get isAbstract;

  bool get isExternal;

  String get name;

  int get nameOffset;

  TypeBuilder get returnType;

  List<TypeParameter>? get thisTypeParameters;

  VariableDeclaration? get thisVariable;

  void becomeNative(SourceLoader loader);

  BodyBuilderContext createBodyBuilderContext(
    SourcePropertyBuilder propertyBuilder,
  );

  LocalScope createFormalParameterScope(LookupScope typeParameterScope);

  void registerFunctionBody({
    required CompilerContext compilerContext,
    required ProblemReporting problemReporting,
    required Statement? body,
    required Scope? scope,
    required AsyncMarker asyncMarker,
    required DartType? emittedValueType,
  });

  DartType get returnTypeContext;
}
