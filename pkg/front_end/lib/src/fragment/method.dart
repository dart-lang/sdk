// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class MethodFragment implements Fragment, FunctionFragment {
  @override
  final String name;

  final Uri fileUri;
  final int startOffset;
  final int nameOffset;
  final int formalsOffset;
  final int endOffset;
  final bool isTopLevel;
  final List<MetadataBuilder>? metadata;
  final Modifiers modifiers;

  /// The declared return type of this method.
  ///
  /// If the return type was omitted, this is an [InferableTypeBuilder].
  final TypeBuilder returnType;

  /// The name space for the type parameters available on this method.
  ///
  /// Initially this contains only the [declaredTypeParameters], but for
  /// extension and extension type instance method this will include type
  /// parameters cloned from the extension or extension type, respectively.
  final NominalParameterNameSpace typeParameterNameSpace;

  /// The declared type parameters on this method.
  final List<NominalParameterBuilder>? declaredTypeParameters;

  /// The scope in which the method is declared.
  ///
  /// This is the scope used for resolving the [metadata].
  final LookupScope enclosingScope;

  /// The scope that introduces type parameters on this method.
  ///
  /// This is based on [typeParameterNameSpace] and initially this contains only
  /// the [declaredTypeParameters], but for extension and extension type
  /// instance methods this will include type parameters cloned from the
  /// extension or extension type, respectively.
  final LookupScope typeParameterScope;

  /// The declared formals on this method.
  final List<FormalParameterBuilder>? declaredFormals;

  final bool isOperator;
  final AsyncMarker asyncModifier;
  final String? nativeMethodName;

  final DeclarationFragment? enclosingDeclaration;
  final LibraryFragment enclosingCompilationUnit;

  SourceMethodBuilder? _builder;

  late final _MethodEncoding _encoding;

  MethodFragment({
    required this.name,
    required this.fileUri,
    required this.startOffset,
    required this.nameOffset,
    required this.formalsOffset,
    required this.endOffset,
    required this.isTopLevel,
    required this.metadata,
    required this.modifiers,
    required this.returnType,
    required this.declaredTypeParameters,
    required this.typeParameterNameSpace,
    required this.enclosingScope,
    required this.typeParameterScope,
    required this.declaredFormals,
    required this.isOperator,
    required this.asyncModifier,
    required this.nativeMethodName,
    required this.enclosingDeclaration,
    required this.enclosingCompilationUnit,
  });

  @override
  SourceMethodBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void setBuilder(
      ProblemReporting problemReporting,
      SourceMethodBuilder value,
      MethodEncodingStrategy encodingStrategy,
      List<NominalParameterBuilder> unboundNominalParameters) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
    _encoding = encodingStrategy.createMethodEncoding(
        value, this, unboundNominalParameters);
    typeParameterNameSpace.addTypeParameters(
        problemReporting, _encoding.clonedAndDeclaredTypeParameters,
        ownerName: name, allowNameConflict: true);
    returnType.registerInferredTypeListener(_encoding);
  }

  @override
  FunctionBodyBuildingContext createFunctionBodyBuildingContext() {
    return new _MethodBodyBuildingContext(this);
  }

  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, BuildNodesCallback f,
      {required Reference reference,
      required Reference? tearOffReference,
      required List<TypeParameter>? classTypeParameters}) {
    _encoding.buildOutlineNode(libraryBuilder, nameScheme, f,
        reference: reference,
        tearOffReference: tearOffReference,
        isAbstractOrExternal: modifiers.isAbstract || modifiers.isExternal,
        classTypeParameters: classTypeParameters);
  }

  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      Annotatable annotatable,
      {required bool isClassInstanceMember,
      required bool createFileUriExpression}) {
    _encoding.buildOutlineExpressions(classHierarchy, libraryBuilder,
        declarationBuilder, createBodyBuilderContext(), annotatable,
        isClassInstanceMember: isClassInstanceMember,
        createFileUriExpression: createFileUriExpression);
  }

  BodyBuilderContext createBodyBuilderContext() {
    return new _MethodFragmentBodyBuilderContext(
        this, builder.libraryBuilder, builder.declarationBuilder,
        isDeclarationInstanceMember: builder.isDeclarationInstanceMember);
  }

  void becomeNative(SourceLoader loader) {
    _encoding.becomeNative(loader);
  }

  int computeDefaultTypes(ComputeDefaultTypeContext context) {
    return _encoding.computeDefaultTypes(context);
  }

  void ensureTypes(
      ClassMembersBuilder membersBuilder,
      SourceClassBuilder enclosingClassBuilder,
      Set<ClassMember>? overrideDependencies) {
    if (overrideDependencies != null) {
      membersBuilder.inferMethodType(enclosingClassBuilder, _encoding.function,
          returnType, declaredFormals, overrideDependencies,
          name: name,
          fileUri: fileUri,
          nameOffset: nameOffset,
          nameLength: name.length);
    }
    _encoding.ensureTypes(
        enclosingClassBuilder.libraryBuilder, membersBuilder.hierarchyBuilder);
  }

  void checkTypes(
      SourceLibraryBuilder libraryBuilder, TypeEnvironment typeEnvironment,
      {required bool isAbstract, required bool isExternal}) {
    _encoding.checkTypes(libraryBuilder, typeEnvironment,
        isAbstract: isAbstract, isExternal: isExternal);
  }

  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    _encoding.checkVariance(sourceClassBuilder, typeEnvironment);
  }

  Procedure? get readTarget => _encoding.readTarget;

  Procedure get invokeTarget => _encoding.invokeTarget;

  // Coverage-ignore(suite): Not run.
  List<NominalParameterBuilder>? get typeParametersForTesting =>
      _encoding.clonedAndDeclaredTypeParameters;

  // Coverage-ignore(suite): Not run.
  List<FormalParameterBuilder>? get formalsForTesting =>
      _encoding.formalsForTesting;

  @override
  String toString() => '$runtimeType($name,$fileUri,$nameOffset)';
}

class _MethodBodyBuildingContext implements FunctionBodyBuildingContext {
  MethodFragment _fragment;

  _MethodBodyBuildingContext(this._fragment);

  @override
  MemberKind get memberKind => _fragment.isTopLevel
      ? MemberKind.TopLevelMethod
      : (_fragment.modifiers.isStatic
          ? MemberKind.StaticMethod
          : MemberKind.NonStaticMethod);

  @override
  bool get shouldBuild => true;

  @override
  LocalScope computeFormalParameterScope(LookupScope typeParameterScope) {
    return _fragment._encoding.createFormalParameterScope(typeParameterScope);
  }

  @override
  LookupScope get typeParameterScope {
    return _fragment.typeParameterScope;
  }

  @override
  BodyBuilderContext createBodyBuilderContext() {
    return _fragment.createBodyBuilderContext();
  }

  @override
  InferenceDataForTesting? get inferenceDataForTesting => _fragment
      .builder
      .dataForTesting
      // Coverage-ignore(suite): Not run.
      ?.inferenceData;

  @override
  List<TypeParameter>? get thisTypeParameters =>
      _fragment._encoding.thisTypeParameters;

  @override
  VariableDeclaration? get thisVariable => _fragment._encoding.thisVariable;
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

  _MethodEncoding createMethodEncoding(
      SourceMethodBuilder builder,
      MethodFragment fragment,
      List<NominalParameterBuilder> unboundNominalParameters);
}

class _RegularMethodStrategy implements MethodEncodingStrategy {
  const _RegularMethodStrategy();

  @override
  _MethodEncoding createMethodEncoding(
      SourceMethodBuilder builder,
      MethodFragment fragment,
      List<NominalParameterBuilder> unboundNominalParameters) {
    return fragment.isOperator
        ? new _RegularOperatorEncoding(fragment)
        : new _RegularMethodEncoding(fragment);
  }
}

class _ExtensionInstanceMethodStrategy implements MethodEncodingStrategy {
  const _ExtensionInstanceMethodStrategy();

  @override
  _MethodEncoding createMethodEncoding(
      SourceMethodBuilder builder,
      MethodFragment fragment,
      List<NominalParameterBuilder> unboundNominalParameters) {
    ExtensionBuilder declarationBuilder =
        builder.declarationBuilder as ExtensionBuilder;
    SynthesizedExtensionSignature signature = new SynthesizedExtensionSignature(
        declarationBuilder, unboundNominalParameters,
        fileUri: fragment.fileUri, fileOffset: fragment.nameOffset);
    return fragment.isOperator
        ? new _ExtensionInstanceOperatorEncoding(fragment,
            signature.clonedDeclarationTypeParameters, signature.thisFormal)
        : new _ExtensionInstanceMethodEncoding(fragment,
            signature.clonedDeclarationTypeParameters, signature.thisFormal);
  }
}

class _ExtensionStaticMethodStrategy implements MethodEncodingStrategy {
  const _ExtensionStaticMethodStrategy();

  @override
  _MethodEncoding createMethodEncoding(
      SourceMethodBuilder builder,
      MethodFragment fragment,
      List<NominalParameterBuilder> unboundNominalParameters) {
    return new _ExtensionStaticMethodEncoding(fragment);
  }
}

class _ExtensionTypeInstanceMethodStrategy implements MethodEncodingStrategy {
  const _ExtensionTypeInstanceMethodStrategy();

  @override
  _MethodEncoding createMethodEncoding(
      SourceMethodBuilder builder,
      MethodFragment fragment,
      List<NominalParameterBuilder> unboundNominalParameters) {
    ExtensionTypeDeclarationBuilder declarationBuilder =
        builder.declarationBuilder as ExtensionTypeDeclarationBuilder;
    SynthesizedExtensionTypeSignature signature =
        new SynthesizedExtensionTypeSignature(
            declarationBuilder, unboundNominalParameters,
            fileUri: fragment.fileUri, fileOffset: fragment.nameOffset);
    return fragment.isOperator
        ? new _ExtensionTypeInstanceOperatorEncoding(fragment,
            signature.clonedDeclarationTypeParameters, signature.thisFormal)
        : new _ExtensionTypeInstanceMethodEncoding(fragment,
            signature.clonedDeclarationTypeParameters, signature.thisFormal);
  }
}

class _ExtensionTypeStaticMethodStrategy implements MethodEncodingStrategy {
  const _ExtensionTypeStaticMethodStrategy();

  @override
  _MethodEncoding createMethodEncoding(
      SourceMethodBuilder builder,
      MethodFragment fragment,
      List<NominalParameterBuilder> unboundNominalParameters) {
    return new _ExtensionTypeStaticMethodEncoding(fragment);
  }
}

sealed class _MethodEncoding implements InferredTypeListener {
  VariableDeclaration? get thisVariable;
  List<TypeParameter>? get thisTypeParameters;
  FunctionNode get function;
  Procedure? get readTarget;
  Procedure get invokeTarget;

  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, BuildNodesCallback f,
      {required Reference reference,
      required Reference? tearOffReference,
      required bool isAbstractOrExternal,
      required List<TypeParameter>? classTypeParameters});

  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      BodyBuilderContext bodyBuilderContext,
      Annotatable annotatable,
      {required bool isClassInstanceMember,
      required bool createFileUriExpression});

  LocalScope createFormalParameterScope(LookupScope typeParameterScope);

  int computeDefaultTypes(ComputeDefaultTypeContext context);

  void ensureTypes(
      SourceLibraryBuilder libraryBuilder, ClassHierarchyBase hierarchy);

  void becomeNative(SourceLoader loader);

  List<FormalParameterBuilder>? get formals;

  VariableDeclaration getFormalParameter(int index);

  VariableDeclaration? getTearOffParameter(int index);

  void checkTypes(
      SourceLibraryBuilder libraryBuilder, TypeEnvironment typeEnvironment,
      {required bool isAbstract, required bool isExternal});

  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment);

  List<NominalParameterBuilder>? get clonedAndDeclaredTypeParameters;

  List<FormalParameterBuilder>? get formalsForTesting;
}

mixin _DirectMethodEncodingMixin implements _MethodEncoding {
  MethodFragment get _fragment;

  Procedure? _procedure;

  @override
  VariableDeclaration? get thisVariable => null;

  @override
  List<TypeParameter>? get thisTypeParameters => null;

  BuiltMemberKind get _builtMemberKind;

  bool get _isExtensionMember;

  bool get _isExtensionTypeMember;

  ProcedureKind get _procedureKind;

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
        _fragment.declaredTypeParameters, _fragment.declaredFormals,
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
  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      BodyBuilderContext bodyBuilderContext,
      Annotatable annotatable,
      {required bool isClassInstanceMember,
      required bool createFileUriExpression}) {
    _buildMetadataForOutlineExpressions(
        libraryBuilder,
        _fragment.enclosingScope,
        bodyBuilderContext,
        annotatable,
        _fragment.metadata,
        fileUri: _fragment.fileUri,
        createFileUriExpression: createFileUriExpression);
    _buildTypeParametersForOutlineExpressions(
        classHierarchy,
        libraryBuilder,
        bodyBuilderContext,
        _fragment.typeParameterScope,
        _fragment.declaredTypeParameters);
    _buildFormalsForOutlineExpressions(
        libraryBuilder, declarationBuilder, _fragment.declaredFormals,
        scope: _fragment.typeParameterScope,
        isClassInstanceMember: isClassInstanceMember);
  }

  @override
  FunctionNode get function => _procedure!.function;

  @override
  Procedure get invokeTarget {
    assert(_procedure != null, "No procedure computed for $_fragment yet.");
    return _procedure!;
  }

  @override
  LocalScope createFormalParameterScope(LookupScope parent) {
    List<FormalParameterBuilder>? formals = _fragment.declaredFormals;
    if (formals == null) {
      return new FormalParameterScope(parent: parent);
    }
    Map<String, Builder> local = <String, Builder>{};
    for (FormalParameterBuilder formal in formals) {
      if (formal.isWildcard) {
        continue;
      }
      local[formal.name] = formal;
    }
    return new FormalParameterScope(local: local, parent: parent);
  }

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context) {
    bool hasErrors = context.reportSimplicityIssuesForTypeParameters(
        _fragment.declaredTypeParameters);
    context.reportGenericFunctionTypesForFormals(_fragment.declaredFormals);
    if (_fragment.returnType is! OmittedTypeBuilder) {
      hasErrors |=
          context.reportInboundReferenceIssuesForType(_fragment.returnType);
      context.recursivelyReportGenericFunctionTypesAsBoundsForType(
          _fragment.returnType);
    }
    return context.computeDefaultTypesForVariables(
        _fragment.declaredTypeParameters,
        inErrorRecovery: hasErrors);
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
  void onInferredType(DartType type) {
    function.returnType = type;
  }

  @override
  void becomeNative(SourceLoader loader) {
    loader.addNativeAnnotation(_procedure!, _fragment.nativeMethodName!);
  }

  @override
  List<FormalParameterBuilder>? get formals => _fragment.declaredFormals;

  @override
  VariableDeclaration getFormalParameter(int index) =>
      _fragment.declaredFormals![index].variable!;

  @override
  VariableDeclaration? getTearOffParameter(int index) => null;

  @override
  void checkTypes(
      SourceLibraryBuilder libraryBuilder, TypeEnvironment typeEnvironment,
      {required bool isAbstract, required bool isExternal}) {
    List<TypeParameterBuilder>? typeParameters =
        _fragment.declaredTypeParameters;
    if (typeParameters != null && typeParameters.isNotEmpty) {
      libraryBuilder.checkTypeParameterDependencies(typeParameters);
    }
    libraryBuilder.checkInitializersInFormals(
        _fragment.declaredFormals, typeEnvironment,
        isAbstract: isAbstract, isExternal: isExternal);
  }

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    sourceClassBuilder.checkVarianceInTypeParameters(
        typeEnvironment, _fragment.declaredTypeParameters);
    sourceClassBuilder.checkVarianceInFormals(
        typeEnvironment, _fragment.declaredFormals);
    sourceClassBuilder.checkVarianceInReturnType(
        typeEnvironment, function.returnType,
        fileOffset: _fragment.nameOffset, fileUri: _fragment.fileUri);
  }

  @override
  List<NominalParameterBuilder>? get clonedAndDeclaredTypeParameters =>
      _fragment.declaredTypeParameters;

  @override
  // Coverage-ignore(suite): Not run.
  List<FormalParameterBuilder>? get formalsForTesting =>
      _fragment.declaredFormals;
}

class _RegularOperatorEncoding extends _MethodEncoding
    with _DirectMethodEncodingMixin {
  @override
  final MethodFragment _fragment;

  _RegularOperatorEncoding(this._fragment) : assert(_fragment.isOperator);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.Method;

  @override
  ProcedureKind get _procedureKind => ProcedureKind.Operator;

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => false;

  @override
  // Coverage-ignore(suite): Not run.
  Procedure? get readTarget => null;
}

class _RegularMethodEncoding extends _MethodEncoding
    with _DirectMethodEncodingMixin {
  @override
  final MethodFragment _fragment;

  _RegularMethodEncoding(this._fragment) : assert(!_fragment.isOperator);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.Method;

  @override
  ProcedureKind get _procedureKind => ProcedureKind.Method;

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => false;

  @override
  Procedure? get readTarget => invokeTarget;
}

class _ExtensionStaticMethodEncoding extends _MethodEncoding
    with _DirectMethodEncodingMixin {
  @override
  final MethodFragment _fragment;

  _ExtensionStaticMethodEncoding(this._fragment)
      : assert(!_fragment.isOperator);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionMethod;

  @override
  ProcedureKind get _procedureKind => ProcedureKind.Method;

  @override
  bool get _isExtensionMember => true;

  @override
  bool get _isExtensionTypeMember => false;

  @override
  Procedure? get readTarget => invokeTarget;
}

class _ExtensionTypeStaticMethodEncoding extends _MethodEncoding
    with _DirectMethodEncodingMixin {
  @override
  final MethodFragment _fragment;

  _ExtensionTypeStaticMethodEncoding(this._fragment)
      : assert(!_fragment.isOperator);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionTypeMethod;

  @override
  ProcedureKind get _procedureKind => ProcedureKind.Method;

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => true;

  @override
  Procedure? get readTarget => invokeTarget;
}

mixin _ExtensionInstanceMethodEncodingMixin implements _MethodEncoding {
  MethodFragment get _fragment;

  Procedure? _procedure;
  Procedure? _extensionTearOff;

  List<NominalParameterBuilder>? get _clonedDeclarationTypeParameters;

  FormalParameterBuilder get _thisFormal;

  @override
  late final List<TypeParameter>? thisTypeParameters =
      _clonedDeclarationTypeParameters != null
          ? function.typeParameters
              // TODO(johnniwinther): Ambivalent analyzer. `!` seems to be both
              //  required and unnecessary.
              // ignore: unnecessary_non_null_assertion
              .sublist(0, _clonedDeclarationTypeParameters!.length)
          : null;

  @override
  VariableDeclaration? get thisVariable => _thisFormal.variable!;

  BuiltMemberKind get _builtMemberKind;

  bool get _isExtensionMember;

  bool get _isExtensionTypeMember;

  bool get _isOperator;

  @override
  FunctionNode get function => _procedure!.function;

  @override
  Procedure get invokeTarget => _procedure!;

  @override
  Procedure? get readTarget => _extensionTearOff;

  /// If this is an extension instance method then
  /// [_extensionTearOffParameterMap] holds a map from the parameters of
  /// the methods to the parameter of the closure returned in the tear-off.
  ///
  /// This map is used to set the default values on the closure parameters when
  /// these have been built.
  Map<VariableDeclaration, VariableDeclaration>? _extensionTearOffParameterMap;

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
        _fragment.declaredTypeParameters, _fragment.declaredFormals,
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
  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      BodyBuilderContext bodyBuilderContext,
      Annotatable annotatable,
      {required bool isClassInstanceMember,
      required bool createFileUriExpression}) {
    _buildMetadataForOutlineExpressions(
        libraryBuilder,
        _fragment.enclosingScope,
        bodyBuilderContext,
        annotatable,
        _fragment.metadata,
        fileUri: _fragment.fileUri,
        createFileUriExpression: createFileUriExpression);

    _buildTypeParametersForOutlineExpressions(
        classHierarchy,
        libraryBuilder,
        bodyBuilderContext,
        _fragment.typeParameterScope,
        _fragment.declaredTypeParameters);
    _buildFormalsForOutlineExpressions(
        libraryBuilder, declarationBuilder, _fragment.declaredFormals,
        scope: _fragment.typeParameterScope,
        isClassInstanceMember: isClassInstanceMember);

    _buildTypeParametersForOutlineExpressions(
        classHierarchy,
        libraryBuilder,
        bodyBuilderContext,
        _fragment.typeParameterScope,
        _clonedDeclarationTypeParameters);
    _buildFormalForOutlineExpressions(
        libraryBuilder, declarationBuilder, _thisFormal,
        scope: _fragment.typeParameterScope,
        isClassInstanceMember: isClassInstanceMember);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void becomeNative(SourceLoader loader) {
    loader.addNativeAnnotation(_procedure!, _fragment.nativeMethodName!);
  }

  @override
  void checkTypes(
      SourceLibraryBuilder libraryBuilder, TypeEnvironment typeEnvironment,
      {required bool isAbstract, required bool isExternal}) {
    List<TypeParameterBuilder>? typeParameters =
        _fragment.declaredTypeParameters;
    if (typeParameters != null && typeParameters.isNotEmpty) {
      libraryBuilder.checkTypeParameterDependencies(typeParameters);
    }
    libraryBuilder.checkInitializersInFormals(
        _fragment.declaredFormals, typeEnvironment,
        isAbstract: isAbstract, isExternal: isExternal);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    sourceClassBuilder.checkVarianceInTypeParameters(
        typeEnvironment, _fragment.declaredTypeParameters);
    sourceClassBuilder.checkVarianceInFormals(
        typeEnvironment, _fragment.declaredFormals);
    sourceClassBuilder.checkVarianceInReturnType(
        typeEnvironment, function.returnType,
        fileOffset: _fragment.nameOffset, fileUri: _fragment.fileUri);
  }

  @override
  LocalScope createFormalParameterScope(LookupScope parent) {
    Map<String, Builder> local = <String, Builder>{};

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
  int computeDefaultTypes(ComputeDefaultTypeContext context) {
    bool hasErrors = context.reportSimplicityIssuesForTypeParameters(
        _fragment.declaredTypeParameters);
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
        ..._fragment.declaredTypeParameters!
      ], inErrorRecovery: hasErrors);
    } else if (_clonedDeclarationTypeParameters != null) {
      return context.computeDefaultTypesForVariables(
          _clonedDeclarationTypeParameters,
          inErrorRecovery: hasErrors);
    } else {
      return context.computeDefaultTypesForVariables(
          _fragment.declaredTypeParameters,
          inErrorRecovery: hasErrors);
    }
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
  void onInferredType(DartType type) {
    function.returnType = type;
  }

  @override
  List<FormalParameterBuilder>? get formals =>
      [_thisFormal, ...?_fragment.declaredFormals];

  @override
  VariableDeclaration getFormalParameter(int index) =>
      _fragment.declaredFormals![index].variable!;

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    return _extensionTearOffParameterMap?[getFormalParameter(index)];
  }

  @override
  List<NominalParameterBuilder>? get clonedAndDeclaredTypeParameters =>
      _clonedDeclarationTypeParameters != null ||
              _fragment.declaredTypeParameters != null
          ? [
              ...?_clonedDeclarationTypeParameters,
              ...?_fragment.declaredTypeParameters
            ]
          : null;

  @override
  // Coverage-ignore(suite): Not run.
  List<FormalParameterBuilder>? get formalsForTesting =>
      [_thisFormal, ...?_fragment.declaredFormals];
}

class _ExtensionInstanceOperatorEncoding extends _MethodEncoding
    with _ExtensionInstanceMethodEncodingMixin {
  @override
  final MethodFragment _fragment;

  @override
  final List<NominalParameterBuilder>? _clonedDeclarationTypeParameters;

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

class _ExtensionInstanceMethodEncoding extends _MethodEncoding
    with _ExtensionInstanceMethodEncodingMixin {
  @override
  final MethodFragment _fragment;

  @override
  final List<NominalParameterBuilder>? _clonedDeclarationTypeParameters;

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

class _ExtensionTypeInstanceOperatorEncoding extends _MethodEncoding
    with _ExtensionInstanceMethodEncodingMixin {
  @override
  final MethodFragment _fragment;

  @override
  final List<NominalParameterBuilder>? _clonedDeclarationTypeParameters;

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

class _ExtensionTypeInstanceMethodEncoding extends _MethodEncoding
    with _ExtensionInstanceMethodEncodingMixin {
  @override
  final MethodFragment _fragment;

  @override
  final List<NominalParameterBuilder>? _clonedDeclarationTypeParameters;

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

class _MethodFragmentBodyBuilderContext extends BodyBuilderContext {
  final MethodFragment _fragment;

  _MethodFragmentBodyBuilderContext(
      this._fragment,
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      {required bool isDeclarationInstanceMember})
      : super(libraryBuilder, declarationBuilder,
            isDeclarationInstanceMember: isDeclarationInstanceMember);

  @override
  LocalScope computeFormalParameterInitializerScope(LocalScope parent) {
    /// Initializer formals or super parameters cannot occur in getters so
    /// we don't need to create a new scope.
    return parent;
  }

  @override
  FunctionNode get function => _fragment._encoding.function;

  @override
  void setAsyncModifier(AsyncMarker asyncModifier) {
    assert(
        asyncModifier == _fragment.asyncModifier,
        "Unexpected change in async modifier on $_fragment from "
        "${_fragment.asyncModifier} to $asyncModifier.");
  }

  @override
  bool get isExternalFunction => _fragment.modifiers.isExternal;

  @override
  int get memberNameOffset => _fragment.nameOffset;

  @override
  int get memberNameLength => _fragment.name.length;

  @override
  DartType get returnTypeContext {
    final bool isReturnTypeUndeclared =
        _fragment.returnType is OmittedTypeBuilder &&
            function.returnType is DynamicType;
    return isReturnTypeUndeclared ? const UnknownType() : function.returnType;
  }

  @override
  TypeBuilder get returnType => _fragment.returnType;

  @override
  void registerFunctionBody(Statement body) {
    function.body = body..parent = function;
  }

  @override
  void registerSuperCall() {
    // TODO(johnniwinther): This should be set on the member built from this
    // fragment and copied to the origin if necessary.
    _fragment.builder.invokeTarget.transformerFlags |=
        TransformerFlag.superCalls;
  }

  @override
  List<FormalParameterBuilder>? get formals => _fragment._encoding.formals;

  @override
  VariableDeclaration getFormalParameter(int index) =>
      _fragment._encoding.getFormalParameter(index);

  @override
  VariableDeclaration? getTearOffParameter(int index) =>
      _fragment._encoding.getTearOffParameter(index);

  @override
  AugmentSuperTarget? get augmentSuperTarget {
    if (_fragment.builder.isAugmentation) {
      return _fragment.builder.augmentSuperTarget;
    }
    return null;
  }
}
