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
import '../../builder/omitted_type_builder.dart';
import '../../builder/type_builder.dart';
import '../../builder/variable_builder.dart';
import '../../kernel/body_builder_context.dart';
import '../../kernel/internal_ast.dart';
import '../../kernel/type_algorithms.dart';
import '../../source/check_helper.dart';
import '../../source/name_scheme.dart';
import '../../source/source_class_builder.dart';
import '../../source/source_function_builder.dart';
import '../../source/source_library_builder.dart';
import '../../source/source_loader.dart';
import '../../source/source_member_builder.dart';
import '../../source/source_property_builder.dart';
import '../../source/source_type_parameter_builder.dart';
import '../../source/type_parameter_factory.dart';
import '../fragment.dart';

class ExtensionInstanceSetterEncoding extends SetterEncoding
    with _ExtensionInstanceSetterEncodingMixin {
  @override
  final SetterFragment _fragment;

  @override
  final List<SourceNominalParameterBuilder>? _clonedDeclarationTypeParameters;

  @override
  final FormalParameterBuilder _thisFormal;

  ExtensionInstanceSetterEncoding(
    this._fragment,
    this._clonedDeclarationTypeParameters,
    this._thisFormal,
  );

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionSetter;

  @override
  bool get _isExtensionMember => true;

  @override
  bool get _isExtensionTypeMember => false;
}

class ExtensionStaticSetterEncoding extends SetterEncoding
    with _DirectSetterEncodingMixin {
  @override
  final SetterFragment _fragment;

  ExtensionStaticSetterEncoding(this._fragment);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionSetter;

  @override
  bool get _isExtensionMember => true;

  @override
  bool get _isExtensionTypeMember => false;
}

class ExtensionTypeInstanceSetterEncoding extends SetterEncoding
    with _ExtensionInstanceSetterEncodingMixin {
  @override
  final SetterFragment _fragment;

  @override
  final List<SourceNominalParameterBuilder>? _clonedDeclarationTypeParameters;

  @override
  final FormalParameterBuilder _thisFormal;

  ExtensionTypeInstanceSetterEncoding(
    this._fragment,
    this._clonedDeclarationTypeParameters,
    this._thisFormal,
  );

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionTypeSetter;

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => true;
}

class ExtensionTypeStaticSetterEncoding extends SetterEncoding
    with _DirectSetterEncodingMixin {
  @override
  final SetterFragment _fragment;

  ExtensionTypeStaticSetterEncoding(this._fragment);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionTypeSetter;

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => true;
}

class RegularSetterEncoding extends SetterEncoding
    with _DirectSetterEncodingMixin {
  @override
  final SetterFragment _fragment;

  RegularSetterEncoding(this._fragment);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.Method;

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => false;
}

sealed class SetterEncoding {
  List<SourceNominalParameterBuilder>? get clonedAndDeclaredTypeParameters;
  List<FormalParameterBuilder>? get formals;
  FunctionNode get function;

  List<TypeParameter>? get thisTypeParameters;

  VariableDeclaration? get thisVariable;

  Procedure get writeTarget;

  void becomeNative(SourceLoader loader);

  void buildOutlineExpressions({
    required ClassHierarchy classHierarchy,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required Annotatable annotatable,
    required Uri annotatableFileUri,
    required bool isClassInstanceMember,
  });

  void buildOutlineNode({
    required SourceLibraryBuilder libraryBuilder,
    required ProblemReporting problemReporting,
    required NameScheme nameScheme,
    required BuildNodesCallback f,
    required PropertyReferences? references,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  });

  void checkTypes(
    ProblemReporting problemReporting,
    TypeEnvironment typeEnvironment, {
    required bool isAbstract,
    required bool isExternal,
  });

  void checkVariance(
    SourceClassBuilder sourceClassBuilder,
    TypeEnvironment typeEnvironment,
  );

  int computeDefaultTypes(ComputeDefaultTypeContext context);

  LocalScope createFormalParameterScope(LookupScope typeParameterScope);

  void ensureTypes(
    SourceLibraryBuilder libraryBuilder,
    ClassHierarchyBase hierarchy,
  );

  VariableDeclaration getFormalParameter(int index);
}

mixin _DirectSetterEncodingMixin implements SetterEncoding {
  Procedure? _procedure;

  @override
  List<SourceNominalParameterBuilder>? get clonedAndDeclaredTypeParameters =>
      _fragment
          .declaredTypeParameters
          // Coverage-ignore(suite): Not run.
          ?.builders;

  @override
  List<FormalParameterBuilder>? get formals => _fragment.declaredFormals;

  @override
  FunctionNode get function => _procedure!.function;

  @override
  List<TypeParameter>? get thisTypeParameters => null;

  @override
  VariableDeclaration? get thisVariable => null;

  @override
  Procedure get writeTarget => _procedure!;

  BuiltMemberKind get _builtMemberKind;

  SetterFragment get _fragment;

  bool get _isExtensionMember;

  bool get _isExtensionTypeMember;

  @override
  void becomeNative(SourceLoader loader) {
    loader.addNativeAnnotation(_procedure!, _fragment.nativeMethodName!);
  }

  @override
  void buildOutlineExpressions({
    required ClassHierarchy classHierarchy,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required Annotatable annotatable,
    required Uri annotatableFileUri,
    required bool isClassInstanceMember,
  }) {
    buildMetadataForOutlineExpressions(
      libraryBuilder: libraryBuilder,
      extensionScope: _fragment.enclosingCompilationUnit.extensionScope,
      scope: _fragment.enclosingScope,
      bodyBuilderContext: bodyBuilderContext,
      annotatable: annotatable,
      annotatableFileUri: annotatableFileUri,
      metadata: _fragment.metadata,
      annotationsFileUri: _fragment.fileUri,
    );

    buildTypeParametersForOutlineExpressions(
      classHierarchy,
      libraryBuilder,
      bodyBuilderContext,
      _fragment
          .declaredTypeParameters
          // Coverage-ignore(suite): Not run.
          ?.builders,
    );
    buildFormalsForOutlineExpressions(
      libraryBuilder,
      declarationBuilder,
      _fragment.declaredFormals,
      extensionScope: _fragment.enclosingCompilationUnit.extensionScope,
      scope: _fragment.typeParameterScope,
      isClassInstanceMember: isClassInstanceMember,
    );
  }

  @override
  void buildOutlineNode({
    required SourceLibraryBuilder libraryBuilder,
    required ProblemReporting problemReporting,
    required NameScheme nameScheme,
    required BuildNodesCallback f,
    required PropertyReferences? references,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  }) {
    FunctionNode function =
        new FunctionNode(
            isAbstractOrExternal ? null : new EmptyStatement(),
            asyncMarker: _fragment.asyncModifier,
          )
          ..fileOffset = _fragment.formalsOffset
          ..fileEndOffset = _fragment.endOffset;
    buildTypeParametersAndFormals(
      libraryBuilder,
      function,
      _fragment
          .declaredTypeParameters
          // Coverage-ignore(suite): Not run.
          ?.builders,
      _fragment.declaredFormals,
      classTypeParameters: classTypeParameters,
      supportsTypeParameters: true,
    );
    if (_fragment.returnType is! InferableTypeBuilder) {
      DartType returnType = _fragment.returnType.build(
        libraryBuilder,
        TypeUse.returnType,
      );
      if (returnType is! VoidType) {
        problemReporting.addProblem(
          codeNonVoidReturnSetter,
          _fragment.returnType.charOffset!,
          noLength,
          _fragment.fileUri,
        );
        returnType = const VoidType();
      }
      function.returnType = returnType;
    }
    if (_fragment.declaredFormals?.length != 1 ||
        _fragment.declaredFormals![0].isOptionalPositional) {
      // Replace illegal parameters by single dummy parameter.
      // Do this after building the parameters, since the diet listener
      // assumes that parameters are built, even if illegal in number.
      VariableDeclaration parameter = new VariableDeclarationImpl("#synthetic");
      function.positionalParameters.clear();
      function.positionalParameters.add(parameter);
      parameter.parent = function;
      function.namedParameters.clear();
      function.requiredParameterCount = 1;
    }
    MemberName memberName = nameScheme.getProcedureMemberName(
      ProcedureKind.Setter,
      _fragment.name,
    );
    Procedure procedure = _procedure =
        new Procedure(
            memberName.name,
            ProcedureKind.Setter,
            function,
            reference: references?.setterReference,
            fileUri: _fragment.fileUri,
          )
          ..fileStartOffset = _fragment.startOffset
          ..fileOffset = _fragment.nameOffset
          ..fileEndOffset = _fragment.endOffset
          ..isAbstract = _fragment.modifiers.isAbstract
          ..isExternal = _fragment.modifiers.isExternal
          ..isConst = _fragment.modifiers.isConst
          ..isStatic = _fragment.modifiers.isStatic
          ..isExtensionMember = _isExtensionMember
          ..isExtensionTypeMember = _isExtensionTypeMember;
    memberName.attachMember(procedure);

    f(kind: _builtMemberKind, member: procedure);
  }

  @override
  void checkTypes(
    ProblemReporting problemReporting,
    TypeEnvironment typeEnvironment, {
    required bool isAbstract,
    required bool isExternal,
  }) {
    List<SourceNominalParameterBuilder>? typeParameters = _fragment
        .declaredTypeParameters
        // Coverage-ignore(suite): Not run.
        ?.builders;
    // Coverage-ignore(suite): Not run.
    if (typeParameters != null && typeParameters.isNotEmpty) {
      checkTypeParameterDependencies(problemReporting, typeParameters);
    }
    problemReporting.checkInitializersInFormals(
      formals: _fragment.declaredFormals,
      typeEnvironment: typeEnvironment,
      isAbstract: isAbstract,
      isExternal: isExternal,
    );
  }

  @override
  void checkVariance(
    SourceClassBuilder sourceClassBuilder,
    TypeEnvironment typeEnvironment,
  ) {
    sourceClassBuilder.checkVarianceInTypeParameters(
      typeEnvironment,
      _fragment
          .declaredTypeParameters
          // Coverage-ignore(suite): Not run.
          ?.builders,
    );
    sourceClassBuilder.checkVarianceInFormals(
      typeEnvironment,
      _fragment.declaredFormals,
    );
    sourceClassBuilder.checkVarianceInReturnType(
      typeEnvironment,
      function.returnType,
      fileOffset: _fragment.nameOffset,
      fileUri: _fragment.fileUri,
    );
  }

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context) {
    bool hasErrors = context.reportSimplicityIssuesForTypeParameters(
      _fragment
          .declaredTypeParameters
          // Coverage-ignore(suite): Not run.
          ?.builders,
    );
    context.reportGenericFunctionTypesForFormals(_fragment.declaredFormals);
    if (_fragment.returnType is! OmittedTypeBuilder) {
      hasErrors |= context.reportInboundReferenceIssuesForType(
        _fragment.returnType,
      );
      context.recursivelyReportGenericFunctionTypesAsBoundsForType(
        _fragment.returnType,
      );
    }
    return context.computeDefaultTypesForVariables(
      _fragment
          .declaredTypeParameters
          // Coverage-ignore(suite): Not run.
          ?.builders,
      inErrorRecovery: hasErrors,
    );
  }

  @override
  LocalScope createFormalParameterScope(LookupScope parent) {
    Map<String, VariableBuilder> local = {};
    List<FormalParameterBuilder>? formals = _fragment.declaredFormals;
    if (formals != null) {
      for (FormalParameterBuilder formal in formals) {
        if (formal.isWildcard) {
          continue;
        }
        local[formal.name] = formal;
      }
    }
    return new FormalParameterScope(local: local, parent: parent);
  }

  @override
  void ensureTypes(
    SourceLibraryBuilder libraryBuilder,
    ClassHierarchyBase hierarchy,
  ) {
    _fragment.returnType.build(
      libraryBuilder,
      TypeUse.returnType,
      hierarchy: hierarchy,
    );
    List<FormalParameterBuilder>? declaredFormals = _fragment.declaredFormals;
    if (declaredFormals != null) {
      for (FormalParameterBuilder formal in declaredFormals) {
        formal.type.build(
          libraryBuilder,
          TypeUse.parameterType,
          hierarchy: hierarchy,
        );
      }
    }
  }

  @override
  VariableDeclaration getFormalParameter(int index) =>
      _fragment.declaredFormals![index].variable!;
}

mixin _ExtensionInstanceSetterEncodingMixin implements SetterEncoding {
  Procedure? _procedure;

  @override
  List<SourceNominalParameterBuilder>? get clonedAndDeclaredTypeParameters =>
      _clonedDeclarationTypeParameters != null ||
          _fragment.declaredTypeParameters != null
      ? [
          ...?_clonedDeclarationTypeParameters,
          ...?_fragment
              .declaredTypeParameters
              // Coverage-ignore(suite): Not run.
              ?.builders,
        ]
      : null;

  @override
  List<FormalParameterBuilder>? get formals => [
    _thisFormal,
    ...?_fragment.declaredFormals,
  ];

  @override
  FunctionNode get function => _procedure!.function;

  @override
  List<TypeParameter>? get thisTypeParameters =>
      _clonedDeclarationTypeParameters != null ? function.typeParameters : null;

  @override
  VariableDeclaration? get thisVariable => _thisFormal.variable!;

  @override
  Procedure get writeTarget => _procedure!;

  BuiltMemberKind get _builtMemberKind;

  List<SourceNominalParameterBuilder>? get _clonedDeclarationTypeParameters;

  SetterFragment get _fragment;

  bool get _isExtensionMember;

  bool get _isExtensionTypeMember;

  FormalParameterBuilder get _thisFormal;

  @override
  // Coverage-ignore(suite): Not run.
  void becomeNative(SourceLoader loader) {
    loader.addNativeAnnotation(_procedure!, _fragment.nativeMethodName!);
  }

  @override
  void buildOutlineExpressions({
    required ClassHierarchy classHierarchy,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required Annotatable annotatable,
    required Uri annotatableFileUri,
    required bool isClassInstanceMember,
  }) {
    buildMetadataForOutlineExpressions(
      libraryBuilder: libraryBuilder,
      extensionScope: _fragment.enclosingCompilationUnit.extensionScope,
      scope: _fragment.enclosingScope,
      bodyBuilderContext: bodyBuilderContext,
      annotatable: annotatable,
      annotatableFileUri: annotatableFileUri,
      metadata: _fragment.metadata,
      annotationsFileUri: _fragment.fileUri,
    );

    buildTypeParametersForOutlineExpressions(
      classHierarchy,
      libraryBuilder,
      bodyBuilderContext,
      _fragment
          .declaredTypeParameters
          // Coverage-ignore(suite): Not run.
          ?.builders,
    );
    buildFormalsForOutlineExpressions(
      libraryBuilder,
      declarationBuilder,
      _fragment.declaredFormals,
      extensionScope: _fragment.enclosingCompilationUnit.extensionScope,
      scope: _fragment.typeParameterScope,
      isClassInstanceMember: isClassInstanceMember,
    );

    buildTypeParametersForOutlineExpressions(
      classHierarchy,
      libraryBuilder,
      bodyBuilderContext,
      _clonedDeclarationTypeParameters,
    );
    buildFormalForOutlineExpressions(
      libraryBuilder,
      declarationBuilder,
      _thisFormal,
      extensionScope: _fragment.enclosingCompilationUnit.extensionScope,
      scope: _fragment.typeParameterScope,
      isClassInstanceMember: isClassInstanceMember,
    );
  }

  @override
  void buildOutlineNode({
    required SourceLibraryBuilder libraryBuilder,
    required ProblemReporting problemReporting,
    required NameScheme nameScheme,
    required BuildNodesCallback f,
    required PropertyReferences? references,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  }) {
    List<TypeParameter>? typeParameters;
    if (_clonedDeclarationTypeParameters != null) {
      typeParameters = [];
      // TODO(johnniwinther): Ambivalent analyzer. `!` seems to be both required
      // and unnecessary.
      // ignore: unnecessary_non_null_assertion
      for (NominalParameterBuilder t in _clonedDeclarationTypeParameters!) {
        typeParameters.add(t.parameter);
      }
    }
    FunctionNode function =
        new FunctionNode(
            isAbstractOrExternal ? null : new EmptyStatement(),
            typeParameters: typeParameters,
            positionalParameters: [_thisFormal.build(libraryBuilder)],
            asyncMarker: _fragment.asyncModifier,
          )
          ..fileOffset = _fragment.formalsOffset
          ..fileEndOffset = _fragment.endOffset;
    buildTypeParametersAndFormals(
      libraryBuilder,
      function,
      _fragment
          .declaredTypeParameters
          // Coverage-ignore(suite): Not run.
          ?.builders,
      _fragment.declaredFormals,
      classTypeParameters: classTypeParameters,
      supportsTypeParameters: true,
    );
    // TODO(johnniwinther): We should have a consistent normalization strategy.
    // We ensure that setters have 1 parameter, but for getters we include all
    // declared parameters.
    if ((_fragment.declaredFormals?.length != 1 ||
        _fragment.declaredFormals![0].isOptionalPositional)) {
      // Replace illegal parameters by single dummy parameter (after #this).
      // Do this after building the parameters, since the diet listener
      // assumes that parameters are built, even if illegal in number.
      VariableDeclaration thisParameter = function.positionalParameters[0];
      VariableDeclaration parameter = new VariableDeclarationImpl("#synthetic");
      function.positionalParameters.clear();
      function.positionalParameters.add(thisParameter);
      function.positionalParameters.add(parameter);
      parameter.parent = function;
      function.namedParameters.clear();
      function.requiredParameterCount = 2;
    }
    if (_fragment.returnType is! InferableTypeBuilder) {
      DartType returnType = _fragment.returnType.build(
        libraryBuilder,
        TypeUse.returnType,
      );
      if (returnType is! VoidType) {
        problemReporting.addProblem(
          codeNonVoidReturnSetter,
          _fragment.returnType.charOffset!,
          noLength,
          _fragment.fileUri,
        );
        returnType = const VoidType();
      }
      function.returnType = returnType;
    }

    MemberName memberName = nameScheme.getProcedureMemberName(
      ProcedureKind.Setter,
      _fragment.name,
    );
    Procedure procedure = _procedure =
        new Procedure(
            memberName.name,
            ProcedureKind.Method,
            function,
            reference: references?.setterReference,
            fileUri: _fragment.fileUri,
          )
          ..fileStartOffset = _fragment.startOffset
          ..fileOffset = _fragment.nameOffset
          ..fileEndOffset = _fragment.endOffset
          ..isAbstract = _fragment.modifiers.isAbstract
          ..isExternal = _fragment.modifiers.isExternal
          ..isConst = _fragment.modifiers.isConst
          ..isStatic = true
          ..isExtensionMember = _isExtensionMember
          ..isExtensionTypeMember = _isExtensionTypeMember;
    memberName.attachMember(procedure);

    f(kind: _builtMemberKind, member: procedure);
  }

  @override
  void checkTypes(
    ProblemReporting problemReporting,
    TypeEnvironment typeEnvironment, {
    required bool isAbstract,
    required bool isExternal,
  }) {
    List<SourceNominalParameterBuilder>? typeParameters = _fragment
        .declaredTypeParameters
        // Coverage-ignore(suite): Not run.
        ?.builders;
    // Coverage-ignore(suite): Not run.
    if (typeParameters != null && typeParameters.isNotEmpty) {
      checkTypeParameterDependencies(problemReporting, typeParameters);
    }
    problemReporting.checkInitializersInFormals(
      formals: _fragment.declaredFormals,
      typeEnvironment: typeEnvironment,
      isAbstract: isAbstract,
      isExternal: isExternal,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void checkVariance(
    SourceClassBuilder sourceClassBuilder,
    TypeEnvironment typeEnvironment,
  ) {
    sourceClassBuilder.checkVarianceInTypeParameters(
      typeEnvironment,
      _fragment.declaredTypeParameters?.builders,
    );
    sourceClassBuilder.checkVarianceInFormals(
      typeEnvironment,
      _fragment.declaredFormals,
    );
    sourceClassBuilder.checkVarianceInReturnType(
      typeEnvironment,
      function.returnType,
      fileOffset: _fragment.nameOffset,
      fileUri: _fragment.fileUri,
    );
  }

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context) {
    bool hasErrors = context.reportSimplicityIssuesForTypeParameters(
      _fragment
          .declaredTypeParameters
          // Coverage-ignore(suite): Not run.
          ?.builders,
    );
    context.reportGenericFunctionTypesForFormals(_fragment.declaredFormals);
    if (_fragment.returnType is! OmittedTypeBuilder) {
      hasErrors |= context.reportInboundReferenceIssuesForType(
        _fragment.returnType,
      );
      context.recursivelyReportGenericFunctionTypesAsBoundsForType(
        _fragment.returnType,
      );
    }
    if (_clonedDeclarationTypeParameters != null &&
        _fragment.declaredTypeParameters != null) {
      // Coverage-ignore-block(suite): Not run.
      // We need to compute all default types together since they might be
      // interdependent.
      return context.computeDefaultTypesForVariables([
        // TODO(johnniwinther): Ambivalent analyzer. `!` seems to be both
        //  required and unnecessary.
        // ignore: unnecessary_non_null_assertion
        ..._clonedDeclarationTypeParameters!,
        ..._fragment.declaredTypeParameters!.builders,
      ], inErrorRecovery: hasErrors);
    } else if (_clonedDeclarationTypeParameters != null) {
      return context.computeDefaultTypesForVariables(
        _clonedDeclarationTypeParameters,
        inErrorRecovery: hasErrors,
      );
    } else {
      return context.computeDefaultTypesForVariables(
        _fragment
            .declaredTypeParameters
            // Coverage-ignore(suite): Not run.
            ?.builders,
        inErrorRecovery: hasErrors,
      );
    }
  }

  @override
  LocalScope createFormalParameterScope(LookupScope parent) {
    Map<String, VariableBuilder> local = {};

    assert(!_thisFormal.isWildcard);
    local[_thisFormal.name] = _thisFormal;

    List<FormalParameterBuilder>? formals = _fragment.declaredFormals;
    if (formals != null) {
      for (FormalParameterBuilder formal in formals) {
        if (formal.isWildcard) {
          continue;
        }
        local[formal.name] = formal;
      }
    }
    return new FormalParameterScope(local: local, parent: parent);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void ensureTypes(
    SourceLibraryBuilder libraryBuilder,
    ClassHierarchyBase hierarchy,
  ) {
    _fragment.returnType.build(
      libraryBuilder,
      TypeUse.fieldType,
      hierarchy: hierarchy,
    );
    _thisFormal.type.build(
      libraryBuilder,
      TypeUse.parameterType,
      hierarchy: hierarchy,
    );
    List<FormalParameterBuilder>? declaredFormals = _fragment.declaredFormals;
    if (declaredFormals != null) {
      for (FormalParameterBuilder formal in declaredFormals) {
        formal.type.build(
          libraryBuilder,
          TypeUse.parameterType,
          hierarchy: hierarchy,
        );
      }
    }
  }

  @override
  VariableDeclaration getFormalParameter(int index) =>
      _fragment.declaredFormals![index].variable!;
}
