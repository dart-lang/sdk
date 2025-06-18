// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/base/uri_offset.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_environment.dart';

import '../../base/local_scope.dart';
import '../../base/scope.dart';
import '../../builder/declaration_builders.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/omitted_type_builder.dart';
import '../../builder/type_builder.dart';
import '../../builder/variable_builder.dart';
import '../../kernel/body_builder_context.dart';
import '../../kernel/type_algorithms.dart';
import '../../source/name_scheme.dart';
import '../../source/source_class_builder.dart';
import '../../source/source_function_builder.dart';
import '../../source/source_library_builder.dart';
import '../../source/source_loader.dart';
import '../../source/source_member_builder.dart';
import '../../source/source_property_builder.dart';
import '../../source/source_type_parameter_builder.dart';
import '../fragment.dart';

class ExtensionInstanceGetterEncoding extends GetterEncoding
    with _ExtensionInstanceGetterEncodingMixin {
  @override
  final GetterFragment _fragment;

  @override
  final List<SourceNominalParameterBuilder>? _clonedDeclarationTypeParameters;

  @override
  final FormalParameterBuilder _thisFormal;

  ExtensionInstanceGetterEncoding(
      this._fragment, this._clonedDeclarationTypeParameters, this._thisFormal);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionGetter;

  @override
  bool get _isExtensionMember => true;

  @override
  bool get _isExtensionTypeMember => false;
}

class ExtensionStaticGetterEncoding extends GetterEncoding
    with _DirectGetterEncodingMixin {
  @override
  final GetterFragment _fragment;

  ExtensionStaticGetterEncoding(this._fragment);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionGetter;

  @override
  bool get _isExtensionMember => true;

  @override
  bool get _isExtensionTypeMember => false;
}

class ExtensionTypeInstanceGetterEncoding extends GetterEncoding
    with _ExtensionInstanceGetterEncodingMixin {
  @override
  final GetterFragment _fragment;

  @override
  final List<SourceNominalParameterBuilder>? _clonedDeclarationTypeParameters;

  @override
  final FormalParameterBuilder _thisFormal;

  ExtensionTypeInstanceGetterEncoding(
      this._fragment, this._clonedDeclarationTypeParameters, this._thisFormal);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionTypeGetter;

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => true;
}

class ExtensionTypeStaticGetterEncoding extends GetterEncoding
    with _DirectGetterEncodingMixin {
  @override
  final GetterFragment _fragment;

  ExtensionTypeStaticGetterEncoding(this._fragment);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionTypeGetter;

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => true;
}

sealed class GetterEncoding implements InferredTypeListener {
  List<SourceNominalParameterBuilder>? get clonedAndDeclaredTypeParameters;
  List<FormalParameterBuilder>? get formals;
  FunctionNode get function;

  Procedure get readTarget;

  List<TypeParameter>? get thisTypeParameters;

  VariableDeclaration? get thisVariable;

  void becomeNative(SourceLoader loader);

  void buildOutlineExpressions(
      {required ClassHierarchy classHierarchy,
      required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder? declarationBuilder,
      required BodyBuilderContext bodyBuilderContext,
      required Annotatable annotatable,
      required Uri annotatableFileUri,
      required bool isClassInstanceMember});

  void buildOutlineNode(
      {required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required BuildNodesCallback f,
      required PropertyReferences? references,
      required bool isAbstractOrExternal,
      required List<TypeParameter>? classTypeParameters});

  void checkTypes(SourceLibraryBuilder libraryBuilder,
      TypeEnvironment typeEnvironment, SourcePropertyBuilder? setterBuilder,
      {required bool isAbstract, required bool isExternal});

  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment);

  int computeDefaultTypes(ComputeDefaultTypeContext context);

  LocalScope createFormalParameterScope(LookupScope typeParameterScope);

  void ensureTypes(
      SourceLibraryBuilder libraryBuilder, ClassHierarchyBase hierarchy);

  VariableDeclaration getFormalParameter(int index);
}

class RegularGetterEncoding extends GetterEncoding
    with _DirectGetterEncodingMixin {
  @override
  final GetterFragment _fragment;

  RegularGetterEncoding(this._fragment);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.Method;

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => false;
}

mixin _DirectGetterEncodingMixin implements GetterEncoding {
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
  Procedure get readTarget => _procedure!;

  @override
  List<TypeParameter>? get thisTypeParameters => null;

  @override
  VariableDeclaration? get thisVariable => null;

  BuiltMemberKind get _builtMemberKind;

  GetterFragment get _fragment;

  bool get _isExtensionMember;

  bool get _isExtensionTypeMember;

  @override
  void becomeNative(SourceLoader loader) {
    loader.addNativeAnnotation(_procedure!, _fragment.nativeMethodName!);
  }

  @override
  void buildOutlineExpressions(
      {required ClassHierarchy classHierarchy,
      required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder? declarationBuilder,
      required BodyBuilderContext bodyBuilderContext,
      required Annotatable annotatable,
      required Uri annotatableFileUri,
      required bool isClassInstanceMember}) {
    buildMetadataForOutlineExpressions(
        libraryBuilder: libraryBuilder,
        scope: _fragment.enclosingScope,
        bodyBuilderContext: bodyBuilderContext,
        annotatable: annotatable,
        annotatableFileUri: annotatableFileUri,
        metadata: _fragment.metadata);
    buildTypeParametersForOutlineExpressions(
        classHierarchy,
        libraryBuilder,
        bodyBuilderContext,
        _fragment
            .declaredTypeParameters
            // Coverage-ignore(suite): Not run.
            ?.builders);
    buildFormalsForOutlineExpressions(
        libraryBuilder, declarationBuilder, _fragment.declaredFormals,
        scope: _fragment.typeParameterScope,
        isClassInstanceMember: isClassInstanceMember);
  }

  @override
  void buildOutlineNode(
      {required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required BuildNodesCallback f,
      required PropertyReferences? references,
      required bool isAbstractOrExternal,
      required List<TypeParameter>? classTypeParameters}) {
    FunctionNode function = new FunctionNode(
        isAbstractOrExternal ? null : new EmptyStatement(),
        asyncMarker: _fragment.asyncModifier)
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
        supportsTypeParameters: true);
    if (_fragment.returnType is! InferableTypeBuilder) {
      function.returnType =
          _fragment.returnType.build(libraryBuilder, TypeUse.returnType);
    }

    MemberName memberName =
        nameScheme.getProcedureMemberName(ProcedureKind.Getter, _fragment.name);
    Procedure procedure = _procedure = new Procedure(
        memberName.name, ProcedureKind.Getter, function,
        reference: references?.getterReference, fileUri: _fragment.fileUri)
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
  void checkTypes(SourceLibraryBuilder libraryBuilder,
      TypeEnvironment typeEnvironment, SourcePropertyBuilder? setterBuilder,
      {required bool isAbstract, required bool isExternal}) {
    List<SourceNominalParameterBuilder>? typeParameters = _fragment
        .declaredTypeParameters
        // Coverage-ignore(suite): Not run.
        ?.builders;
    // Coverage-ignore(suite): Not run.
    if (typeParameters != null && typeParameters.isNotEmpty) {
      libraryBuilder.checkTypeParameterDependencies(typeParameters);
    }
    libraryBuilder.checkInitializersInFormals(
        _fragment.declaredFormals, typeEnvironment,
        isAbstract: isAbstract, isExternal: isExternal);
    if (setterBuilder != null) {
      DartType getterType = function.returnType;
      DartType setterType = SourcePropertyBuilder.getSetterType(setterBuilder,
          getterExtensionTypeParameters: null);
      libraryBuilder.checkGetterSetterTypes(
        typeEnvironment,
        getterType: getterType,
        getterName: _fragment.name,
        getterUriOffset: new UriOffsetLength(
            _fragment.fileUri, _fragment.nameOffset, _fragment.name.length),
        setterType: setterType,
        setterName: setterBuilder.name,
        setterUriOffset: setterBuilder.setterUriOffset!,
      );
    }
  }

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    sourceClassBuilder.checkVarianceInTypeParameters(
        typeEnvironment,
        _fragment
            .declaredTypeParameters
            // Coverage-ignore(suite): Not run.
            ?.builders);
    sourceClassBuilder.checkVarianceInFormals(
        typeEnvironment, _fragment.declaredFormals);
    sourceClassBuilder.checkVarianceInReturnType(
        typeEnvironment, function.returnType,
        fileOffset: _fragment.nameOffset, fileUri: _fragment.fileUri);
  }

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context) {
    bool hasErrors = context.reportSimplicityIssuesForTypeParameters(_fragment
        .declaredTypeParameters
        // Coverage-ignore(suite): Not run.
        ?.builders);
    context.reportGenericFunctionTypesForFormals(_fragment.declaredFormals);
    if (_fragment.returnType is! OmittedTypeBuilder) {
      hasErrors |=
          context.reportInboundReferenceIssuesForType(_fragment.returnType);
      context.recursivelyReportGenericFunctionTypesAsBoundsForType(
          _fragment.returnType);
    }
    return context.computeDefaultTypesForVariables(
        _fragment
            .declaredTypeParameters
            // Coverage-ignore(suite): Not run.
            ?.builders,
        inErrorRecovery: hasErrors);
  }

  @override
  LocalScope createFormalParameterScope(LookupScope typeParameterScope) {
    return new FormalParameterScope(parent: typeParameterScope);
  }

  @override
  void ensureTypes(
      SourceLibraryBuilder libraryBuilder, ClassHierarchyBase hierarchy) {
    _fragment.returnType
        .build(libraryBuilder, TypeUse.returnType, hierarchy: hierarchy);
  }

  @override
  VariableDeclaration getFormalParameter(int index) =>
      _fragment.declaredFormals![index].variable!;

  @override
  void onInferredType(DartType type) {
    function.returnType = type;
  }
}

mixin _ExtensionInstanceGetterEncodingMixin implements GetterEncoding {
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
                  ?.builders
            ]
          : null;

  @override
  List<FormalParameterBuilder>? get formals =>
      [_thisFormal, ...?_fragment.declaredFormals];

  @override
  FunctionNode get function => _procedure!.function;

  @override
  Procedure get readTarget => _procedure!;

  @override
  List<TypeParameter>? get thisTypeParameters =>
      _clonedDeclarationTypeParameters != null ? function.typeParameters : null;

  @override
  VariableDeclaration? get thisVariable => _thisFormal.variable!;

  BuiltMemberKind get _builtMemberKind;

  List<SourceNominalParameterBuilder>? get _clonedDeclarationTypeParameters;

  GetterFragment get _fragment;

  bool get _isExtensionMember;

  bool get _isExtensionTypeMember;

  FormalParameterBuilder get _thisFormal;

  @override
  // Coverage-ignore(suite): Not run.
  void becomeNative(SourceLoader loader) {
    loader.addNativeAnnotation(_procedure!, _fragment.nativeMethodName!);
  }

  @override
  void buildOutlineExpressions(
      {required ClassHierarchy classHierarchy,
      required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder? declarationBuilder,
      required BodyBuilderContext bodyBuilderContext,
      required Annotatable annotatable,
      required Uri annotatableFileUri,
      required bool isClassInstanceMember}) {
    buildMetadataForOutlineExpressions(
        libraryBuilder: libraryBuilder,
        scope: _fragment.enclosingScope,
        bodyBuilderContext: bodyBuilderContext,
        annotatable: annotatable,
        annotatableFileUri: annotatableFileUri,
        metadata: _fragment.metadata);

    buildTypeParametersForOutlineExpressions(
        classHierarchy,
        libraryBuilder,
        bodyBuilderContext,
        _fragment
            .declaredTypeParameters
            // Coverage-ignore(suite): Not run.
            ?.builders);
    buildFormalsForOutlineExpressions(
        libraryBuilder, declarationBuilder, _fragment.declaredFormals,
        scope: _fragment.typeParameterScope,
        isClassInstanceMember: isClassInstanceMember);

    buildTypeParametersForOutlineExpressions(classHierarchy, libraryBuilder,
        bodyBuilderContext, _clonedDeclarationTypeParameters);
    buildFormalForOutlineExpressions(
        libraryBuilder, declarationBuilder, _thisFormal,
        scope: _fragment.typeParameterScope,
        isClassInstanceMember: isClassInstanceMember);
  }

  @override
  void buildOutlineNode(
      {required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required BuildNodesCallback f,
      required PropertyReferences? references,
      required bool isAbstractOrExternal,
      required List<TypeParameter>? classTypeParameters}) {
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
    FunctionNode function = new FunctionNode(
        isAbstractOrExternal ? null : new EmptyStatement(),
        typeParameters: typeParameters,
        positionalParameters: [_thisFormal.build(libraryBuilder)],
        asyncMarker: _fragment.asyncModifier)
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
        supportsTypeParameters: true);
    if (_fragment.returnType is! InferableTypeBuilder) {
      function.returnType =
          _fragment.returnType.build(libraryBuilder, TypeUse.returnType);
    }

    MemberName memberName =
        nameScheme.getProcedureMemberName(ProcedureKind.Getter, _fragment.name);
    Procedure procedure = _procedure = new Procedure(
        memberName.name, ProcedureKind.Method, function,
        reference: references?.getterReference, fileUri: _fragment.fileUri)
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
  void checkTypes(SourceLibraryBuilder libraryBuilder,
      TypeEnvironment typeEnvironment, SourcePropertyBuilder? setterBuilder,
      {required bool isAbstract, required bool isExternal}) {
    List<SourceNominalParameterBuilder>? typeParameters = _fragment
        .declaredTypeParameters
        // Coverage-ignore(suite): Not run.
        ?.builders;
    // Coverage-ignore(suite): Not run.
    if (typeParameters != null && typeParameters.isNotEmpty) {
      libraryBuilder.checkTypeParameterDependencies(typeParameters);
    }
    libraryBuilder.checkInitializersInFormals(
        _fragment.declaredFormals, typeEnvironment,
        isAbstract: isAbstract, isExternal: isExternal);
    if (setterBuilder != null) {
      DartType getterType = function.returnType;
      DartType setterType = SourcePropertyBuilder.getSetterType(setterBuilder,
          getterExtensionTypeParameters: function.typeParameters);
      libraryBuilder.checkGetterSetterTypes(typeEnvironment,
          getterType: getterType,
          getterName: _fragment.name,
          getterUriOffset: new UriOffsetLength(
              _fragment.fileUri, _fragment.nameOffset, _fragment.name.length),
          setterType: setterType,
          setterName: setterBuilder.name,
          setterUriOffset: setterBuilder.setterUriOffset!);
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    sourceClassBuilder.checkVarianceInTypeParameters(
        typeEnvironment, _fragment.declaredTypeParameters?.builders);
    sourceClassBuilder.checkVarianceInFormals(
        typeEnvironment, _fragment.declaredFormals);
    sourceClassBuilder.checkVarianceInReturnType(
        typeEnvironment, function.returnType,
        fileOffset: _fragment.nameOffset, fileUri: _fragment.fileUri);
  }

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context) {
    bool hasErrors = context.reportSimplicityIssuesForTypeParameters(_fragment
        .declaredTypeParameters
        // Coverage-ignore(suite): Not run.
        ?.builders);
    context.reportGenericFunctionTypesForFormals(_fragment.declaredFormals);
    if (_fragment.returnType is! OmittedTypeBuilder) {
      hasErrors |=
          context.reportInboundReferenceIssuesForType(_fragment.returnType);
      context.recursivelyReportGenericFunctionTypesAsBoundsForType(
          _fragment.returnType);
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
        ..._fragment.declaredTypeParameters!.builders
      ], inErrorRecovery: hasErrors);
    } else if (_clonedDeclarationTypeParameters != null) {
      return context.computeDefaultTypesForVariables(
          _clonedDeclarationTypeParameters,
          inErrorRecovery: hasErrors);
    } else {
      return context.computeDefaultTypesForVariables(
          _fragment
              .declaredTypeParameters
              // Coverage-ignore(suite): Not run.
              ?.builders,
          inErrorRecovery: hasErrors);
    }
  }

  @override
  LocalScope createFormalParameterScope(LookupScope typeParameterScope) {
    Map<String, VariableBuilder> local = {};
    assert(!_thisFormal.isWildcard);
    local[_thisFormal.name] = _thisFormal;
    return new FormalParameterScope(local: local, parent: typeParameterScope);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void ensureTypes(
      SourceLibraryBuilder libraryBuilder, ClassHierarchyBase hierarchy) {
    _fragment.returnType
        .build(libraryBuilder, TypeUse.fieldType, hierarchy: hierarchy);
    _thisFormal.type
        .build(libraryBuilder, TypeUse.parameterType, hierarchy: hierarchy);
  }

  @override
  // Coverage-ignore(suite): Not run.
  VariableDeclaration getFormalParameter(int index) =>
      _fragment.declaredFormals![index].variable!;

  @override
  void onInferredType(DartType type) {
    function.returnType = type;
  }
}
