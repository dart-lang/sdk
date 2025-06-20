// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_algebra.dart';
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
import '../../source/fragment_factory.dart';
import '../../source/name_scheme.dart';
import '../../source/source_class_builder.dart';
import '../../source/source_function_builder.dart';
import '../../source/source_library_builder.dart';
import '../../source/source_loader.dart';
import '../../source/source_member_builder.dart';
import '../../source/source_method_builder.dart';
import '../../source/source_type_parameter_builder.dart';
import '../fragment.dart';

sealed class MethodEncoding implements InferredTypeListener {
  List<SourceNominalParameterBuilder>? get clonedAndDeclaredTypeParameters;
  List<FormalParameterBuilder>? get formals;
  FunctionNode get function;
  Procedure get invokeTarget;

  Procedure? get readTarget;

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

  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, BuildNodesCallback f,
      {required Reference reference,
      required Reference? tearOffReference,
      required bool isAbstractOrExternal,
      required List<TypeParameter>? classTypeParameters});

  void checkTypes(
      SourceLibraryBuilder libraryBuilder, TypeEnvironment typeEnvironment);

  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment);

  int computeDefaultTypes(ComputeDefaultTypeContext context);

  LocalScope createFormalParameterScope(LookupScope typeParameterScope);

  void ensureTypes(
      SourceLibraryBuilder libraryBuilder, ClassHierarchyBase hierarchy);

  VariableDeclaration getFormalParameter(int index);

  VariableDeclaration? getTearOffParameter(int index);
}

sealed class MethodEncodingStrategy {
  factory MethodEncodingStrategy(DeclarationBuilder? declarationBuilder,
      {required bool isInstanceMember}) {
    switch (declarationBuilder) {
      case ExtensionBuilder():
        if (isInstanceMember) {
          return const _ExtensionInstanceMethodStrategy();
        } else {
          return const _ExtensionStaticMethodStrategy();
        }
      case ExtensionTypeDeclarationBuilder():
        if (isInstanceMember) {
          return const _ExtensionTypeInstanceMethodStrategy();
        } else {
          return const _ExtensionTypeStaticMethodStrategy();
        }
      case null:
      case ClassBuilder():
        return const _RegularMethodStrategy();
    }
  }

  MethodEncoding createMethodEncoding(
      SourceMethodBuilder builder,
      MethodFragment fragment,
      List<NominalParameterBuilder> unboundNominalParameters);
}

mixin _DirectMethodEncodingMixin implements MethodEncoding {
  Procedure? _procedure;

  @override
  List<SourceNominalParameterBuilder>? get clonedAndDeclaredTypeParameters =>
      _fragment.declaredTypeParameters?.builders;

  @override
  List<FormalParameterBuilder>? get formals => _fragment.declaredFormals;

  @override
  FunctionNode get function => _procedure!.function;

  @override
  Procedure get invokeTarget {
    assert(_procedure != null, "No procedure computed for $_fragment yet.");
    return _procedure!;
  }

  @override
  List<TypeParameter>? get thisTypeParameters => null;

  @override
  VariableDeclaration? get thisVariable => null;

  BuiltMemberKind get _builtMemberKind;

  MethodFragment get _fragment;

  bool get _isExtensionMember;

  bool get _isExtensionTypeMember;

  ProcedureKind get _procedureKind;

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
    buildTypeParametersForOutlineExpressions(classHierarchy, libraryBuilder,
        bodyBuilderContext, _fragment.declaredTypeParameters?.builders);
    buildFormalsForOutlineExpressions(
        libraryBuilder, declarationBuilder, _fragment.declaredFormals,
        scope: _fragment.typeParameterScope,
        isClassInstanceMember: isClassInstanceMember);
  }

  @override
  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, BuildNodesCallback f,
      {required Reference reference,
      required Reference? tearOffReference,
      required bool isAbstractOrExternal,
      List<TypeParameter>? classTypeParameters}) {
    FunctionNode function = new FunctionNode(
        isAbstractOrExternal ? null : new EmptyStatement(),
        asyncMarker: _fragment.asyncModifier)
      ..fileOffset = _fragment.formalsOffset
      ..fileEndOffset = _fragment.endOffset;
    buildTypeParametersAndFormals(libraryBuilder, function,
        _fragment.declaredTypeParameters?.builders, _fragment.declaredFormals,
        classTypeParameters: classTypeParameters, supportsTypeParameters: true);
    if (_fragment.returnType is! InferableTypeBuilder) {
      function.returnType =
          _fragment.returnType.build(libraryBuilder, TypeUse.returnType);
    }

    MemberName memberName =
        nameScheme.getProcedureMemberName(_procedureKind, _fragment.name);
    Procedure procedure = _procedure = new Procedure(
        memberName.name, _procedureKind, function,
        reference: reference, fileUri: _fragment.fileUri)
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
      SourceLibraryBuilder libraryBuilder, TypeEnvironment typeEnvironment) {
    List<SourceNominalParameterBuilder>? typeParameters =
        _fragment.declaredTypeParameters?.builders;
    if (typeParameters != null && typeParameters.isNotEmpty) {
      libraryBuilder.checkTypeParameterDependencies(typeParameters);
    }
    libraryBuilder.checkInitializersInFormals(
        _fragment.declaredFormals, typeEnvironment,
        isAbstract: _fragment.modifiers.isAbstract,
        isExternal: _fragment.modifiers.isExternal);
  }

  @override
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
    bool hasErrors = context.reportSimplicityIssuesForTypeParameters(
        _fragment.declaredTypeParameters?.builders);
    context.reportGenericFunctionTypesForFormals(_fragment.declaredFormals);
    if (_fragment.returnType is! OmittedTypeBuilder) {
      hasErrors |=
          context.reportInboundReferenceIssuesForType(_fragment.returnType);
      context.recursivelyReportGenericFunctionTypesAsBoundsForType(
          _fragment.returnType);
    }
    return context.computeDefaultTypesForVariables(
        _fragment.declaredTypeParameters?.builders,
        inErrorRecovery: hasErrors);
  }

  @override
  LocalScope createFormalParameterScope(LookupScope parent) {
    List<FormalParameterBuilder>? formals = _fragment.declaredFormals;
    if (formals == null) {
      return new FormalParameterScope(parent: parent);
    }
    Map<String, VariableBuilder> local = {};
    for (FormalParameterBuilder formal in formals) {
      if (formal.isWildcard) {
        continue;
      }
      local[formal.name] = formal;
    }
    return new FormalParameterScope(local: local, parent: parent);
  }

  @override
  void ensureTypes(
      SourceLibraryBuilder libraryBuilder, ClassHierarchyBase hierarchy) {
    _fragment.returnType
        .build(libraryBuilder, TypeUse.returnType, hierarchy: hierarchy);
    List<FormalParameterBuilder>? declaredFormals = _fragment.declaredFormals;
    if (declaredFormals != null) {
      for (FormalParameterBuilder formal in declaredFormals) {
        formal.type
            .build(libraryBuilder, TypeUse.parameterType, hierarchy: hierarchy);
      }
    }
  }

  @override
  VariableDeclaration getFormalParameter(int index) =>
      _fragment.declaredFormals![index].variable!;

  @override
  VariableDeclaration? getTearOffParameter(int index) => null;

  @override
  void onInferredType(DartType type) {
    function.returnType = type;
  }
}

class _ExtensionInstanceMethodEncoding extends MethodEncoding
    with _ExtensionInstanceMethodEncodingMixin {
  @override
  final MethodFragment _fragment;

  @override
  final List<SourceNominalParameterBuilder>? _clonedDeclarationTypeParameters;

  @override
  final FormalParameterBuilder _thisFormal;

  _ExtensionInstanceMethodEncoding(
      this._fragment, this._clonedDeclarationTypeParameters, this._thisFormal)
      : assert(!_fragment.isOperator);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionMethod;

  @override
  bool get _isExtensionMember => true;

  @override
  bool get _isExtensionTypeMember => false;

  @override
  bool get _isOperator => false;
}

mixin _ExtensionInstanceMethodEncodingMixin implements MethodEncoding {
  Procedure? _procedure;

  Procedure? _extensionTearOff;
  @override
  late final List<TypeParameter>? thisTypeParameters =
      _clonedDeclarationTypeParameters != null
          ? function.typeParameters
              // TODO(johnniwinther): Ambivalent analyzer. `!` seems to be both
              //  required and unnecessary.
              // ignore: unnecessary_non_null_assertion
              .sublist(0, _clonedDeclarationTypeParameters!.length)
          : null;

  /// If this is an extension instance method then
  /// [_extensionTearOffParameterMap] holds a map from the parameters of
  /// the methods to the parameter of the closure returned in the tear-off.
  ///
  /// This map is used to set the default values on the closure parameters when
  /// these have been built.
  Map<VariableDeclaration, VariableDeclaration>? _extensionTearOffParameterMap;

  @override
  List<SourceNominalParameterBuilder>? get clonedAndDeclaredTypeParameters =>
      _clonedDeclarationTypeParameters != null ||
              _fragment.declaredTypeParameters != null
          ? [
              ...?_clonedDeclarationTypeParameters,
              ...?_fragment.declaredTypeParameters?.builders
            ]
          : null;

  @override
  List<FormalParameterBuilder>? get formals =>
      [_thisFormal, ...?_fragment.declaredFormals];

  @override
  FunctionNode get function => _procedure!.function;

  @override
  Procedure get invokeTarget => _procedure!;

  @override
  Procedure? get readTarget => _extensionTearOff;

  @override
  VariableDeclaration? get thisVariable => _thisFormal.variable!;

  BuiltMemberKind get _builtMemberKind;

  List<SourceNominalParameterBuilder>? get _clonedDeclarationTypeParameters;

  MethodFragment get _fragment;

  bool get _isExtensionMember;

  bool get _isExtensionTypeMember;

  bool get _isOperator;

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

    buildTypeParametersForOutlineExpressions(classHierarchy, libraryBuilder,
        bodyBuilderContext, _fragment.declaredTypeParameters?.builders);
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
  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, BuildNodesCallback f,
      {required Reference reference,
      required Reference? tearOffReference,
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
    buildTypeParametersAndFormals(libraryBuilder, function,
        _fragment.declaredTypeParameters?.builders, _fragment.declaredFormals,
        classTypeParameters: classTypeParameters, supportsTypeParameters: true);
    if (_fragment.returnType is! InferableTypeBuilder) {
      function.returnType =
          _fragment.returnType.build(libraryBuilder, TypeUse.returnType);
    }

    MemberName memberName =
        nameScheme.getProcedureMemberName(ProcedureKind.Method, _fragment.name);
    Procedure procedure = _procedure = new Procedure(
        memberName.name, ProcedureKind.Method, function,
        reference: reference, fileUri: _fragment.fileUri)
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

    if (!_isOperator) {
      _extensionTearOff =
          _buildExtensionTearOff(procedure, nameScheme, tearOffReference);
    }

    f(kind: _builtMemberKind, member: procedure, tearOff: _extensionTearOff);
  }

  @override
  void checkTypes(
      SourceLibraryBuilder libraryBuilder, TypeEnvironment typeEnvironment) {
    List<SourceNominalParameterBuilder>? typeParameters =
        _fragment.declaredTypeParameters?.builders;
    if (typeParameters != null && typeParameters.isNotEmpty) {
      libraryBuilder.checkTypeParameterDependencies(typeParameters);
    }
    libraryBuilder.checkInitializersInFormals(
        _fragment.declaredFormals, typeEnvironment,
        isAbstract: _fragment.modifiers.isAbstract,
        isExternal: _fragment.modifiers.isExternal);
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
    bool hasErrors = context.reportSimplicityIssuesForTypeParameters(
        _fragment.declaredTypeParameters?.builders);
    context.reportGenericFunctionTypesForFormals(_fragment.declaredFormals);
    if (_fragment.returnType is! OmittedTypeBuilder) {
      hasErrors |=
          context.reportInboundReferenceIssuesForType(_fragment.returnType);
      context.recursivelyReportGenericFunctionTypesAsBoundsForType(
          _fragment.returnType);
    }
    if (_clonedDeclarationTypeParameters != null &&
        _fragment.declaredTypeParameters != null) {
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
          _fragment.declaredTypeParameters?.builders,
          inErrorRecovery: hasErrors);
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
      SourceLibraryBuilder libraryBuilder, ClassHierarchyBase hierarchy) {
    _fragment.returnType
        .build(libraryBuilder, TypeUse.fieldType, hierarchy: hierarchy);
    _thisFormal.type
        .build(libraryBuilder, TypeUse.parameterType, hierarchy: hierarchy);
    List<FormalParameterBuilder>? declaredFormals = _fragment.declaredFormals;
    if (declaredFormals != null) {
      for (FormalParameterBuilder formal in declaredFormals) {
        formal.type
            .build(libraryBuilder, TypeUse.parameterType, hierarchy: hierarchy);
      }
    }
  }

  @override
  VariableDeclaration getFormalParameter(int index) =>
      _fragment.declaredFormals![index].variable!;

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    return _extensionTearOffParameterMap?[getFormalParameter(index)];
  }

  @override
  void onInferredType(DartType type) {
    function.returnType = type;
  }

  /// Creates a top level function that creates a tear off of an extension
  /// instance method.
  ///
  /// For this declaration
  ///
  ///     extension E<T> on A<T> {
  ///       X method<S>(S s, Y y) {}
  ///     }
  ///
  /// we create the top level function
  ///
  ///     X E|method<T, S>(A<T> #this, S s, Y y) {}
  ///
  /// and the tear off function
  ///
  ///     X Function<S>(S, Y) E|get#method<T>(A<T> #this) {
  ///       return (S s, Y y) => E|method<T, S>(#this, s, y);
  ///     }
  ///
  Procedure _buildExtensionTearOff(
      Procedure procedure, NameScheme nameScheme, Reference? tearOffReference) {
    _extensionTearOffParameterMap = {};

    int fileStartOffset = _fragment.startOffset;
    int fileOffset = _fragment.nameOffset;
    int fileEndOffset = _fragment.endOffset;

    int extensionTypeParameterCount =
        _clonedDeclarationTypeParameters?.length ?? 0;

    List<TypeParameter> typeParameters = <TypeParameter>[];

    Map<TypeParameter, DartType> substitutionMap = {};
    List<DartType> typeArguments = <DartType>[];
    for (TypeParameter typeParameter in procedure.function.typeParameters) {
      TypeParameter newTypeParameter = new TypeParameter(typeParameter.name);
      typeParameters.add(newTypeParameter);
      typeArguments.add(substitutionMap[typeParameter] = new TypeParameterType(
          newTypeParameter, typeParameter.computeNullabilityFromBound()));
    }

    List<TypeParameter> tearOffTypeParameters = <TypeParameter>[];
    List<TypeParameter> closureTypeParameters = <TypeParameter>[];
    Substitution substitution = Substitution.fromMap(substitutionMap);
    for (int index = 0; index < typeParameters.length; index++) {
      TypeParameter newTypeParameter = typeParameters[index];
      newTypeParameter.bound = substitution
          .substituteType(procedure.function.typeParameters[index].bound);
      newTypeParameter.defaultType =
          procedure.function.typeParameters[index].defaultType;
      if (index < extensionTypeParameterCount) {
        tearOffTypeParameters.add(newTypeParameter);
      } else {
        closureTypeParameters.add(newTypeParameter);
      }
    }

    VariableDeclaration copyParameter(
        VariableDeclaration parameter, DartType type) {
      VariableDeclaration newParameter = new VariableDeclaration(parameter.name,
          type: type,
          isFinal: parameter.isFinal,
          isLowered: parameter.isLowered,
          isRequired: parameter.isRequired)
        ..fileOffset = parameter.fileOffset;
      _extensionTearOffParameterMap![parameter] = newParameter;
      return newParameter;
    }

    VariableDeclaration extensionThis = copyParameter(
        procedure.function.positionalParameters.first,
        substitution.substituteType(
            procedure.function.positionalParameters.first.type));

    DartType closureReturnType =
        substitution.substituteType(procedure.function.returnType);
    List<VariableDeclaration> closurePositionalParameters = [];
    List<Expression> closurePositionalArguments = [];

    for (int position = 0;
        position < procedure.function.positionalParameters.length;
        position++) {
      VariableDeclaration parameter =
          procedure.function.positionalParameters[position];
      if (position == 0) {
        /// Pass `this` as a captured variable.
        closurePositionalArguments
            .add(new VariableGet(extensionThis)..fileOffset = fileOffset);
      } else {
        DartType type = substitution.substituteType(parameter.type);
        VariableDeclaration newParameter = copyParameter(parameter, type);
        closurePositionalParameters.add(newParameter);
        closurePositionalArguments
            .add(new VariableGet(newParameter)..fileOffset = fileOffset);
      }
    }
    List<VariableDeclaration> closureNamedParameters = [];
    List<NamedExpression> closureNamedArguments = [];
    for (VariableDeclaration parameter in procedure.function.namedParameters) {
      DartType type = substitution.substituteType(parameter.type);
      VariableDeclaration newParameter = copyParameter(parameter, type);
      closureNamedParameters.add(newParameter);
      closureNamedArguments.add(new NamedExpression(parameter.name!,
          new VariableGet(newParameter)..fileOffset = fileOffset));
    }

    Statement closureBody = new ReturnStatement(
        new StaticInvocation(
            procedure,
            new Arguments(closurePositionalArguments,
                types: typeArguments, named: closureNamedArguments))
          // We need to use the fileStartOffset on the StaticInvocation to
          // avoid a possible "fake coverage miss" on the name of the
          // extension method.
          ..fileOffset = fileStartOffset)
      ..fileOffset = fileOffset;

    FunctionExpression closure = new FunctionExpression(
        new FunctionNode(closureBody,
            typeParameters: closureTypeParameters,
            positionalParameters: closurePositionalParameters,
            namedParameters: closureNamedParameters,
            requiredParameterCount:
                procedure.function.requiredParameterCount - 1,
            returnType: closureReturnType)
          ..fileOffset = fileOffset
          ..fileEndOffset = fileEndOffset)
      // We need to use the fileStartOffset on the FunctionExpression to
      // avoid a possible "fake coverage miss" on the name of the
      // extension method.
      ..fileOffset = fileStartOffset;

    FunctionNode function = new FunctionNode(
        new ReturnStatement(closure)..fileOffset = fileOffset,
        typeParameters: tearOffTypeParameters,
        positionalParameters: [extensionThis],
        requiredParameterCount: 1,
        returnType:
            closure.function.computeFunctionType(Nullability.nonNullable))
      ..fileOffset = fileOffset
      ..fileEndOffset = fileEndOffset;

    MemberName tearOffName =
        nameScheme.getProcedureMemberName(ProcedureKind.Getter, _fragment.name);
    Procedure tearOff = new Procedure(
        tearOffName.name, ProcedureKind.Method, function,
        isStatic: true,
        isExtensionMember: _isExtensionMember,
        isExtensionTypeMember: _isExtensionTypeMember,
        reference: tearOffReference,
        fileUri: _fragment.fileUri)
      ..fileUri = _fragment.fileUri
      ..fileOffset = fileOffset
      ..fileStartOffset = _fragment.startOffset
      ..fileEndOffset = fileEndOffset;
    tearOffName.attachMember(tearOff);
    return tearOff;
  }
}

class _ExtensionInstanceMethodStrategy implements MethodEncodingStrategy {
  const _ExtensionInstanceMethodStrategy();

  @override
  MethodEncoding createMethodEncoding(
      SourceMethodBuilder builder,
      MethodFragment fragment,
      List<NominalParameterBuilder> unboundNominalParameters) {
    ExtensionBuilder declarationBuilder =
        builder.declarationBuilder as ExtensionBuilder;
    SynthesizedExtensionSignature signature = new SynthesizedExtensionSignature(
        declarationBuilder: declarationBuilder,
        extensionTypeParameterFragments:
            fragment.enclosingDeclaration!.typeParameters,
        unboundNominalParameters: unboundNominalParameters,
        onTypeBuilder: declarationBuilder.onType,
        fileUri: fragment.fileUri,
        fileOffset: fragment.nameOffset);
    return fragment.isOperator
        ? new _ExtensionInstanceOperatorEncoding(fragment,
            signature.clonedDeclarationTypeParameters, signature.thisFormal)
        : new _ExtensionInstanceMethodEncoding(fragment,
            signature.clonedDeclarationTypeParameters, signature.thisFormal);
  }
}

class _ExtensionInstanceOperatorEncoding extends MethodEncoding
    with _ExtensionInstanceMethodEncodingMixin {
  @override
  final MethodFragment _fragment;

  @override
  final List<SourceNominalParameterBuilder>? _clonedDeclarationTypeParameters;

  @override
  final FormalParameterBuilder _thisFormal;

  _ExtensionInstanceOperatorEncoding(
      this._fragment, this._clonedDeclarationTypeParameters, this._thisFormal)
      : assert(_fragment.isOperator);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionOperator;

  @override
  bool get _isExtensionMember => true;

  @override
  bool get _isExtensionTypeMember => false;

  @override
  bool get _isOperator => true;
}

class _ExtensionStaticMethodEncoding extends MethodEncoding
    with _DirectMethodEncodingMixin {
  @override
  final MethodFragment _fragment;

  _ExtensionStaticMethodEncoding(this._fragment)
      : assert(!_fragment.isOperator);

  @override
  Procedure? get readTarget => invokeTarget;

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionMethod;

  @override
  bool get _isExtensionMember => true;

  @override
  bool get _isExtensionTypeMember => false;

  @override
  ProcedureKind get _procedureKind => ProcedureKind.Method;
}

class _ExtensionStaticMethodStrategy implements MethodEncodingStrategy {
  const _ExtensionStaticMethodStrategy();

  @override
  MethodEncoding createMethodEncoding(
      SourceMethodBuilder builder,
      MethodFragment fragment,
      List<NominalParameterBuilder> unboundNominalParameters) {
    return new _ExtensionStaticMethodEncoding(fragment);
  }
}

class _ExtensionTypeInstanceMethodEncoding extends MethodEncoding
    with _ExtensionInstanceMethodEncodingMixin {
  @override
  final MethodFragment _fragment;

  @override
  final List<SourceNominalParameterBuilder>? _clonedDeclarationTypeParameters;

  @override
  final FormalParameterBuilder _thisFormal;

  _ExtensionTypeInstanceMethodEncoding(
      this._fragment, this._clonedDeclarationTypeParameters, this._thisFormal)
      : assert(!_fragment.isOperator);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionTypeMethod;

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => true;

  @override
  bool get _isOperator => false;
}

class _ExtensionTypeInstanceMethodStrategy implements MethodEncodingStrategy {
  const _ExtensionTypeInstanceMethodStrategy();

  @override
  MethodEncoding createMethodEncoding(
      SourceMethodBuilder builder,
      MethodFragment fragment,
      List<NominalParameterBuilder> unboundNominalParameters) {
    ExtensionTypeDeclarationBuilder declarationBuilder =
        builder.declarationBuilder as ExtensionTypeDeclarationBuilder;
    SynthesizedExtensionTypeSignature signature =
        new SynthesizedExtensionTypeSignature(
            extensionTypeDeclarationBuilder: declarationBuilder,
            extensionTypeTypeParameters:
                fragment.enclosingDeclaration!.typeParameters,
            unboundNominalParameters: unboundNominalParameters,
            fileUri: fragment.fileUri,
            fileOffset: fragment.nameOffset);
    return fragment.isOperator
        ? new _ExtensionTypeInstanceOperatorEncoding(fragment,
            signature.clonedDeclarationTypeParameters, signature.thisFormal)
        : new _ExtensionTypeInstanceMethodEncoding(fragment,
            signature.clonedDeclarationTypeParameters, signature.thisFormal);
  }
}

class _ExtensionTypeInstanceOperatorEncoding extends MethodEncoding
    with _ExtensionInstanceMethodEncodingMixin {
  @override
  final MethodFragment _fragment;

  @override
  final List<SourceNominalParameterBuilder>? _clonedDeclarationTypeParameters;

  @override
  final FormalParameterBuilder _thisFormal;

  _ExtensionTypeInstanceOperatorEncoding(
      this._fragment, this._clonedDeclarationTypeParameters, this._thisFormal)
      : assert(_fragment.isOperator);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionTypeOperator;

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => true;

  @override
  bool get _isOperator => true;
}

class _ExtensionTypeStaticMethodEncoding extends MethodEncoding
    with _DirectMethodEncodingMixin {
  @override
  final MethodFragment _fragment;

  _ExtensionTypeStaticMethodEncoding(this._fragment)
      : assert(!_fragment.isOperator);

  @override
  Procedure? get readTarget => invokeTarget;

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionTypeMethod;

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => true;

  @override
  ProcedureKind get _procedureKind => ProcedureKind.Method;
}

class _ExtensionTypeStaticMethodStrategy implements MethodEncodingStrategy {
  const _ExtensionTypeStaticMethodStrategy();

  @override
  MethodEncoding createMethodEncoding(
      SourceMethodBuilder builder,
      MethodFragment fragment,
      List<NominalParameterBuilder> unboundNominalParameters) {
    return new _ExtensionTypeStaticMethodEncoding(fragment);
  }
}

class _RegularMethodEncoding extends MethodEncoding
    with _DirectMethodEncodingMixin {
  @override
  final MethodFragment _fragment;

  _RegularMethodEncoding(this._fragment) : assert(!_fragment.isOperator);

  @override
  Procedure? get readTarget => invokeTarget;

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.Method;

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => false;

  @override
  ProcedureKind get _procedureKind => ProcedureKind.Method;
}

class _RegularMethodStrategy implements MethodEncodingStrategy {
  const _RegularMethodStrategy();

  @override
  MethodEncoding createMethodEncoding(
      SourceMethodBuilder builder,
      MethodFragment fragment,
      List<NominalParameterBuilder> unboundNominalParameters) {
    return fragment.isOperator
        ? new _RegularOperatorEncoding(fragment)
        : new _RegularMethodEncoding(fragment);
  }
}

class _RegularOperatorEncoding extends MethodEncoding
    with _DirectMethodEncodingMixin {
  @override
  final MethodFragment _fragment;

  _RegularOperatorEncoding(this._fragment) : assert(_fragment.isOperator);

  @override
  Procedure? get readTarget => null;

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.Method;

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => false;

  @override
  ProcedureKind get _procedureKind => ProcedureKind.Operator;
}
