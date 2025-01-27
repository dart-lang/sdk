// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../api_prototype/lowering_predicates.dart';
import '../base/identifiers.dart';
import '../base/local_scope.dart';
import '../base/messages.dart'
    show
        messageConstFactoryRedirectionToNonConst,
        noLength,
        templateCyclicRedirectingFactoryConstructors,
        templateIncompatibleRedirecteeFunctionType,
        templateRedirectingFactoryIncompatibleTypeArgument,
        templateTypeArgumentMismatch;
import '../base/modifiers.dart';
import '../base/name_space.dart';
import '../base/problems.dart' show unexpected, unhandled;
import '../base/scope.dart';
import '../builder/builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/constructor_reference_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/type_builder.dart';
import '../codes/cfe_codes.dart';
import '../dill/dill_extension_type_member_builder.dart';
import '../dill/dill_member_builder.dart';
import '../kernel/body_builder_context.dart';
import '../kernel/constructor_tearoff_lowering.dart';
import '../kernel/hierarchy/class_member.dart';
import '../kernel/internal_ast.dart';
import '../kernel/kernel_helper.dart';
import '../kernel/type_algorithms.dart';
import '../type_inference/inference_helper.dart';
import '../type_inference/type_inferrer.dart';
import '../type_inference/type_schema.dart';
import 'name_scheme.dart';
import 'redirecting_factory_body.dart';
import 'source_builder_mixins.dart';
import 'source_class_builder.dart';
import 'source_extension_type_declaration_builder.dart';
import 'source_function_builder.dart';
import 'source_library_builder.dart' show SourceLibraryBuilder;
import 'source_loader.dart'
    show CompilationPhaseForProblemReporting, SourceLoader;
import 'source_member_builder.dart';

class SourceFactoryBuilder extends SourceMemberBuilderImpl
    implements SourceFunctionBuilder, InferredTypeListener {
  @override
  final List<MetadataBuilder>? metadata;

  final Modifiers modifiers;

  @override
  final String name;

  @override
  final List<NominalParameterBuilder>? typeParameters;

  @override
  final List<FormalParameterBuilder>? formals;

  /// If this procedure is an extension instance member or extension type
  /// instance member, [_thisVariable] holds the synthetically added `this`
  /// parameter.
  VariableDeclaration? _thisVariable;

  /// If this procedure is an extension instance member or extension type
  /// instance member, [_thisTypeParameters] holds the type parameters copied
  /// from the extension/extension type declaration.
  List<TypeParameter>? _thisTypeParameters;

  @override
  final SourceLibraryBuilder libraryBuilder;

  @override
  final DeclarationBuilder declarationBuilder;

  final int formalsOffset;

  AsyncMarker actualAsyncModifier = AsyncMarker.Sync;

  @override
  final bool isExtensionInstanceMember = false;

  @override
  final TypeBuilder returnType;

  late final Procedure _procedureInternal;
  late final Procedure? _factoryTearOff;

  SourceFactoryBuilder? actualOrigin;

  List<SourceFactoryBuilder>? _augmentations;

  final MemberName _memberName;

  DelayedDefaultValueCloner? _delayedDefaultValueCloner;

  final int nameOffset;

  @override
  final Uri fileUri;

  final ConstructorReferenceBuilder? redirectionTarget;

  List<DartType>? _redirectionTypeArguments;

  FreshTypeParameters? _tearOffTypeParameters;

  bool _hasBeenCheckedAsRedirectingFactory = false;

  SourceFactoryBuilder(
      {required this.metadata,
      required this.modifiers,
      required this.returnType,
      required this.name,
      required this.typeParameters,
      required this.formals,
      required this.libraryBuilder,
      required this.declarationBuilder,
      required this.fileUri,
      required int startOffset,
      required this.nameOffset,
      required this.formalsOffset,
      required int endOffset,
      required Reference? procedureReference,
      required Reference? tearOffReference,
      required AsyncMarker asyncModifier,
      required NameScheme nameScheme,
      this.nativeMethodName,
      required this.redirectionTarget})
      : _memberName = nameScheme.getDeclaredName(name) {
    returnType.registerInferredTypeListener(this);
    _procedureInternal = new Procedure(
        dummyName,
        nameScheme.isExtensionTypeMember
            ? ProcedureKind.Method
            : ProcedureKind.Factory,
        new FunctionNode(null),
        fileUri: fileUri,
        reference: procedureReference)
      ..fileStartOffset = startOffset
      ..fileOffset = nameOffset
      ..fileEndOffset = endOffset
      ..isExtensionTypeMember = nameScheme.isExtensionTypeMember;
    nameScheme
        .getConstructorMemberName(name, isTearOff: false)
        .attachMember(_procedureInternal);
    _factoryTearOff = createFactoryTearOffProcedure(
        nameScheme.getConstructorMemberName(name, isTearOff: true),
        libraryBuilder,
        fileUri,
        nameOffset,
        tearOffReference,
        forceCreateLowering: nameScheme.isExtensionTypeMember)
      ?..isExtensionTypeMember = nameScheme.isExtensionTypeMember;
    this.asyncModifier = asyncModifier;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadataForTesting => metadata;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAugmentation => modifiers.isAugment;

  @override
  bool get isExternal => modifiers.isExternal;

  @override
  bool get isAbstract => modifiers.isAbstract;

  @override
  bool get isConst => modifiers.isConst;

  @override
  bool get isStatic => modifiers.isStatic;

  @override
  bool get isAugment => modifiers.isAugment;

  @override
  bool get isConstructor => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAssignable => false;

  @override
  LocalScope computeFormalParameterScope(LookupScope parent) {
    if (formals == null) return new FormalParameterScope(parent: parent);
    Map<String, Builder> local = <String, Builder>{};
    for (FormalParameterBuilder formal in formals!) {
      if (formal.isWildcard) {
        continue;
      }
      if (!isConstructor ||
          // Coverage-ignore(suite): Not run.
          !formal.isInitializingFormal && !formal.isSuperInitializingFormal) {
        local[formal.name] = formal;
      }
    }
    return new FormalParameterScope(local: local, parent: parent);
  }

  @override
  LocalScope computeFormalParameterInitializerScope(LocalScope parent) {
    // From
    // [dartLangSpec.tex](../../../../../../docs/language/dartLangSpec.tex) at
    // revision 94b23d3b125e9d246e07a2b43b61740759a0dace:
    //
    // When the formal parameter list of a non-redirecting generative
    // constructor contains any initializing formals, a new scope is
    // introduced, the _formal parameter initializer scope_, which is the
    // current scope of the initializer list of the constructor, and which is
    // enclosed in the scope where the constructor is declared.  Each
    // initializing formal in the formal parameter list introduces a final
    // local variable into the formal parameter initializer scope, but not into
    // the formal parameter scope; every other formal parameter introduces a
    // local variable into both the formal parameter scope and the formal
    // parameter initializer scope.

    if (formals == null) return parent;
    Map<String, Builder> local = <String, Builder>{};
    for (FormalParameterBuilder formal in formals!) {
      // Wildcard initializing formal parameters do not introduce a local
      // variable in the initializer list.
      if (formal.isWildcard) continue;

      local[formal.name] = formal.forFormalParameterInitializerScope();
    }
    return parent.createNestedFixedScope(
        debugName: "formal parameter initializer",
        kind: ScopeKind.initializers,
        local: local);
  }

  // TODO(johnniwinther): Remove this.
  LookupScope computeTypeParameterScope(LookupScope parent) {
    if (typeParameters == null) return parent;
    Map<String, Builder> local = <String, Builder>{};
    for (NominalParameterBuilder variable in typeParameters!) {
      if (variable.isWildcard) continue;
      local[variable.name] = variable;
    }
    return new TypeParameterScope(parent, local);
  }

  @override
  FormalParameterBuilder? getFormal(Identifier identifier) {
    if (formals != null) {
      for (FormalParameterBuilder formal in formals!) {
        if (formal.isWildcard &&
            identifier.name == '_' &&
            formal.fileOffset == identifier.nameOffset) {
          return formal;
        }
        if (formal.name == identifier.name &&
            formal.fileOffset == identifier.nameOffset) {
          return formal;
        }
      }
      // Coverage-ignore(suite): Not run.
      // If we have any formals we should find the one we're looking for.
      assert(false, "$identifier not found in $formals");
    }
    return null;
  }

  final String? nativeMethodName;

  Statement? bodyInternal;

  @override
  void set body(Statement? newBody) {
//    if (newBody != null) {
//      if (isAbstract) {
//        // TODO(danrubel): Is this check needed?
//        return internalProblem(messageInternalProblemBodyOnAbstractMethod,
//            newBody.fileOffset, fileUri);
//      }
//    }
    bodyInternal = newBody;
    // A forwarding semi-stub is a method that is abstract in the source code,
    // but which needs to have a forwarding stub body in order to ensure that
    // covariance checks occur.  We don't want to replace the forwarding stub
    // body with null.
    TreeNode? parent = function.parent;
    if (!(newBody == null &&
        // Coverage-ignore(suite): Not run.
        parent is Procedure &&
        // Coverage-ignore(suite): Not run.
        parent.isForwardingSemiStub)) {
      function.body = newBody;
      newBody?.parent = function;
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isNative => nativeMethodName != null;

  bool get supportsTypeParameters => true;

  void buildFunction() {
    function.asyncMarker = asyncModifier;
    function.body = body;
    body?.parent = function;
    buildTypeParametersAndFormals(
        libraryBuilder, function, typeParameters, formals,
        classTypeParameters: null,
        supportsTypeParameters: supportsTypeParameters);
    if (!(isExtensionInstanceMember || isExtensionTypeInstanceMember) &&
        isSetter &&
        // Coverage-ignore(suite): Not run.
        (formals?.length != 1 || formals![0].isOptionalPositional)) {
      // Coverage-ignore-block(suite): Not run.
      // Replace illegal parameters by single dummy parameter.
      // Do this after building the parameters, since the diet listener
      // assumes that parameters are built, even if illegal in number.
      VariableDeclaration parameter = new VariableDeclarationImpl("#synthetic");
      function.positionalParameters.clear();
      function.positionalParameters.add(parameter);
      parameter.parent = function;
      function.namedParameters.clear();
      function.requiredParameterCount = 1;
    } else if ((isExtensionInstanceMember || isExtensionTypeInstanceMember) &&
        // Coverage-ignore(suite): Not run.
        isSetter &&
        // Coverage-ignore(suite): Not run.
        (formals?.length != 2 || formals![1].isOptionalPositional)) {
      // Coverage-ignore-block(suite): Not run.
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
    if (returnType is! InferableTypeBuilder) {
      function.returnType =
          returnType.build(libraryBuilder, TypeUse.returnType);
    }
    if (isExtensionInstanceMember || isExtensionTypeInstanceMember) {
      // Coverage-ignore-block(suite): Not run.
      SourceDeclarationBuilderMixin declarationBuilder =
          parent as SourceDeclarationBuilderMixin;
      if (declarationBuilder.typeParameters != null) {
        int count = declarationBuilder.typeParameters!.length;
        _thisTypeParameters = new List<TypeParameter>.generate(
            count, (int index) => function.typeParameters[index],
            growable: false);
      }
      if (isExtensionTypeInstanceMember && isConstructor) {
        SourceExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder =
            parent as SourceExtensionTypeDeclarationBuilder;
        List<DartType> typeArguments;
        if (_thisTypeParameters != null) {
          typeArguments = [
            for (TypeParameter parameter in _thisTypeParameters!)
              new TypeParameterType.withDefaultNullability(parameter)
          ];
        } else {
          typeArguments = [];
        }
        _thisVariable = new VariableDeclarationImpl(syntheticThisName,
            isFinal: true,
            type: new ExtensionType(
                extensionTypeDeclarationBuilder.extensionTypeDeclaration,
                Nullability.nonNullable,
                typeArguments))
          ..fileOffset = fileOffset
          ..isLowered = true;
      } else {
        _thisVariable = function.positionalParameters.first;
      }
    }
  }

  @override
  VariableDeclaration getFormalParameter(int index) {
    if (this is! ConstructorBuilder &&
        (isExtensionInstanceMember || isExtensionTypeInstanceMember)) {
      // Coverage-ignore-block(suite): Not run.
      return formals![index + 1].variable!;
    } else {
      return formals![index].variable!;
    }
  }

  @override
  VariableDeclaration? get thisVariable {
    assert(
        _thisVariable != null ||
            !(isExtensionInstanceMember || isExtensionTypeInstanceMember),
        "ProcedureBuilder.thisVariable has not been set.");
    return _thisVariable;
  }

  @override
  List<TypeParameter>? get thisTypeParameters {
    // Use [_thisVariable] as marker for whether this type parameters have
    // been computed.
    assert(
        _thisVariable != null ||
            !(isExtensionInstanceMember || isExtensionTypeInstanceMember),
        "ProcedureBuilder.thisTypeParameters has not been set.");
    return _thisTypeParameters;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void onInferredType(DartType type) {
    function.returnType = type;
  }

  @override
  void becomeNative(SourceLoader loader) {
    for (Annotatable annotatable in annotatables) {
      loader.addNativeAnnotation(annotatable, nativeMethodName!);
    }
    _procedureInternal.isExternal = true;
  }

  @override
  int get fileOffset => nameOffset;

  @override
  Builder get parent => declarationBuilder;

  @override
  // Coverage-ignore(suite): Not run.
  Name get memberName => _memberName.name;

  // Coverage-ignore(suite): Not run.
  List<SourceFactoryBuilder>? get augmentationsForTesting => _augmentations;

  AsyncMarker get asyncModifier => actualAsyncModifier;

  void set asyncModifier(AsyncMarker newModifier) {
    actualAsyncModifier = newModifier;
    function.asyncMarker = actualAsyncModifier;
    function.dartAsyncMarker = actualAsyncModifier;
  }

  @override
  SourceFactoryBuilder get origin => actualOrigin ?? this;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isRegularMethod => false;

  @override
  bool get isGetter => false;

  @override
  bool get isSetter => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isOperator => false;

  @override
  bool get isFactory => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isFinal => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSynthesized => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isEnumElement => false;

  Procedure get _procedure =>
      isAugmenting ? origin._procedure : _procedureInternal;

  @override
  FunctionNode get function => _procedureInternal.function;

  @override
  Member? get readTarget => origin._factoryTearOff ?? _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get readTargetReference =>
      (origin._factoryTearOff ?? _procedure).reference;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => null;

  @override
  Member? get invokeTarget => _procedure;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get invokeTargetReference => _procedure.reference;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [_procedure.reference];

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    if (_factoryTearOff != null) {
      if (index < _factoryTearOff.function.positionalParameters.length) {
        return _factoryTearOff.function.positionalParameters[index];
      } else {
        index -= _factoryTearOff.function.positionalParameters.length;
        if (index < _factoryTearOff.function.namedParameters.length) {
          return _factoryTearOff.function.namedParameters[index];
        }
      }
    }
    return null;
  }

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localMembers =>
      throw new UnsupportedError('${runtimeType}.localMembers');

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localSetters =>
      throw new UnsupportedError('${runtimeType}.localSetters');

  @override
  void applyAugmentation(Builder augmentation) {
    if (augmentation is SourceFactoryBuilder) {
      if (checkAugmentation(
          augmentationLibraryBuilder: augmentation.libraryBuilder,
          origin: this,
          augmentation: augmentation)) {
        augmentation.actualOrigin = this;
        (_augmentations ??= []).add(augmentation);
      }
    } else {
      // Coverage-ignore-block(suite): Not run.
      reportAugmentationMismatch(
          originLibraryBuilder: libraryBuilder,
          origin: this,
          augmentation: augmentation);
    }
  }

  @override
  int buildBodyNodes(BuildNodesCallback f) {
    if (!isAugmenting) return 0;
    _finishAugmentation();
    return 1;
  }

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    int count = context.computeDefaultTypesForVariables(typeParameters,
        // Type parameters are inherited from the enclosing declaration, so if
        // it has issues, so do the constructors.
        inErrorRecovery: inErrorRecovery);
    context.reportGenericFunctionTypesForFormals(formals);
    return count;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

  @override
  void checkTypes(SourceLibraryBuilder library, NameSpace nameSpace,
      TypeEnvironment typeEnvironment) {
    if (redirectionTarget != null) {
      // Default values are not required on redirecting factory constructors so
      // we don't call [checkInitializersInFormals].
    } else {
      library.checkInitializersInFormals(formals, typeEnvironment,
          isAbstract: isAbstract, isExternal: isExternal);
    }
    List<SourceFactoryBuilder>? augmentations = _augmentations;
    if (augmentations != null) {
      for (SourceFactoryBuilder augmentation in augmentations) {
        augmentation.checkTypes(library, nameSpace, typeEnvironment);
      }
    }
  }

  /// Checks the redirecting factories of this factory builder and its
  /// augmentations.
  void checkRedirectingFactories(TypeEnvironment typeEnvironment) {
    if (redirectionTarget != null) {
      _checkRedirectingFactory(typeEnvironment);
    }
    List<SourceFactoryBuilder>? augmentations = _augmentations;
    if (augmentations != null) {
      for (SourceFactoryBuilder augmentation in augmentations) {
        if (augmentation.redirectionTarget != null) {
          augmentation._checkRedirectingFactory(typeEnvironment);
        }
      }
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get fullNameForErrors {
    return "${declarationBuilder.name}"
        "${name.isEmpty ? '' : '.$name'}";
  }

  // TODO(johnniwinther): Add annotations to tear-offs.
  @override
  Iterable<Annotatable> get annotatables => [_procedure];

  /// Returns `true` if this member is augmented, either by being the origin
  /// of a augmented member or by not being the last among augmentations.
  bool get isAugmented {
    if (isAugmenting) {
      return origin._augmentations!.last != this;
    } else {
      return _augmentations != null;
    }
  }

  List<DartType>? get redirectionTypeArguments {
    assert(redirectionTarget != null);
    return _redirectionTypeArguments;
  }

  void set redirectionTypeArguments(List<DartType>? value) {
    assert(redirectionTarget != null);
    _redirectionTypeArguments = value;
  }

  @override
  Statement? get body {
    if (redirectionTarget == null &&
        bodyInternal == null &&
        !isAbstract &&
        !isExternal) {
      bodyInternal = new EmptyStatement();
    }
    return bodyInternal;
  }

  void setRedirectingFactoryBody(Member target, List<DartType> typeArguments) {
    if (bodyInternal != null) {
      unexpected("null", "${bodyInternal.runtimeType}", fileOffset, fileUri);
    }

    // Ensure that constant factories only have constant targets/bodies.
    if (isConst && !target.isConst) {
      // Coverage-ignore-block(suite): Not run.
      libraryBuilder.addProblem(messageConstFactoryRedirectionToNonConst,
          fileOffset, noLength, fileUri);
    }

    bodyInternal =
        createRedirectingFactoryBody(target, typeArguments, function);
    _procedureInternal.function.body = bodyInternal;
    _procedureInternal.function.redirectingFactoryTarget =
        new RedirectingFactoryTarget(target, typeArguments);
    bodyInternal?.parent = function;
    if (isAugmenting) {
      if (function.typeParameters.isNotEmpty) {
        Map<TypeParameter, DartType> substitution = <TypeParameter, DartType>{};
        for (int i = 0; i < function.typeParameters.length; i++) {
          substitution[function.typeParameters[i]] =
              new TypeParameterType.withDefaultNullability(
                  actualOrigin!.function.typeParameters[i]);
        }
        typeArguments = new List<DartType>.generate(typeArguments.length,
            (int i) => substitute(typeArguments[i], substitution),
            growable: false);
      }
      actualOrigin!.setRedirectingFactoryBody(target, typeArguments);
    }
  }

  void setRedirectingFactoryError(String message) {
    assert(redirectionTarget != null);

    body = createRedirectingFactoryErrorBody(message);
    _procedure.function.redirectingFactoryTarget =
        new RedirectingFactoryTarget.error(message);
    if (_factoryTearOff != null) {
      _factoryTearOff.function.body = createRedirectingFactoryErrorBody(message)
        ..parent = _factoryTearOff.function;
    }
  }

  @override
  void buildOutlineNodes(BuildNodesCallback f) {
    _build();
    f(
        member: _procedureInternal,
        tearOff: _factoryTearOff,
        kind: isExtensionTypeMember
            ? (redirectionTarget != null
                ? BuiltMemberKind.ExtensionTypeRedirectingFactory
                : BuiltMemberKind.ExtensionTypeFactory)
            : (redirectionTarget != null
                ? BuiltMemberKind.RedirectingFactory
                : BuiltMemberKind.Factory));
  }

  void _build() {
    buildFunction();
    _procedureInternal.function.fileOffset = formalsOffset;
    _procedureInternal.function.fileEndOffset =
        _procedureInternal.fileEndOffset;
    _procedureInternal.isAbstract = isAbstract;
    _procedureInternal.isExternal = isExternal;
    _procedureInternal.isConst = isConst;
    _procedureInternal.isStatic = isStatic;

    if (redirectionTarget != null) {
      if (redirectionTarget!.typeArguments != null) {
        redirectionTypeArguments = new List<DartType>.generate(
            redirectionTarget!.typeArguments!.length,
            (int i) => redirectionTarget!.typeArguments![i]
                .build(libraryBuilder, TypeUse.redirectionTypeArgument),
            growable: false);
      }
      if (_factoryTearOff != null) {
        _tearOffTypeParameters =
            buildRedirectingFactoryTearOffProcedureParameters(
                tearOff: _factoryTearOff,
                implementationConstructor: _procedureInternal,
                libraryBuilder: libraryBuilder);
      }
    } else {
      if (_factoryTearOff != null) {
        _delayedDefaultValueCloner = buildConstructorTearOffProcedure(
            tearOff: _factoryTearOff,
            declarationConstructor: _procedure,
            implementationConstructor: _procedureInternal,
            libraryBuilder: libraryBuilder);
      }
    }
  }

  bool _hasBuiltOutlineExpressions = false;

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (_hasBuiltOutlineExpressions) return;
    _hasBuiltOutlineExpressions = true;

    if (redirectionTarget != null && isConst && isAugmenting) {
      origin.buildOutlineExpressions(
          classHierarchy, delayedDefaultValueCloners);
    }

    formals?.infer(classHierarchy);

    if (_delayedDefaultValueCloner != null) {
      delayedDefaultValueCloners.add(_delayedDefaultValueCloner!);
    }

    DeclarationBuilder? classOrExtensionBuilder =
        isClassMember || isExtensionMember || isExtensionTypeMember
            ? parent as DeclarationBuilder
            : null;
    LookupScope parentScope =
        classOrExtensionBuilder?.scope ?? // Coverage-ignore(suite): Not run.
            libraryBuilder.scope;
    for (Annotatable annotatable in annotatables) {
      MetadataBuilder.buildAnnotations(annotatable, metadata,
          createBodyBuilderContext(), libraryBuilder, fileUri, parentScope,
          createFileUriExpression: isAugmented);
    }
    if (typeParameters != null) {
      for (int i = 0; i < typeParameters!.length; i++) {
        typeParameters![i].buildOutlineExpressions(
            libraryBuilder,
            createBodyBuilderContext(),
            classHierarchy,
            computeTypeParameterScope(parentScope));
      }
    }

    if (formals != null) {
      // For const constructors we need to include default parameter values
      // into the outline. For all other formals we need to call
      // buildOutlineExpressions to clear initializerToken to prevent
      // consuming too much memory.
      for (FormalParameterBuilder formal in formals!) {
        formal.buildOutlineExpressions(libraryBuilder, declarationBuilder,
            buildDefaultValue: FormalParameterBuilder
                .needsDefaultValuesBuiltAsOutlineExpressions(this));
      }
    }

    if (redirectionTarget == null) {
      return;
    }

    RedirectingFactoryTarget? redirectingFactoryTarget =
        _procedureInternal.function.redirectingFactoryTarget;
    if (redirectingFactoryTarget == null) {
      // The error is reported elsewhere.
      return;
    }
    List<DartType>? typeArguments = redirectingFactoryTarget.typeArguments;
    Member? target = redirectingFactoryTarget.target;
    if (typeArguments != null && typeArguments.any((t) => t is UnknownType)) {
      TypeInferrer inferrer = libraryBuilder.loader.typeInferenceEngine
          .createLocalTypeInferrer(
              fileUri, declarationBuilder.thisType, libraryBuilder, null);
      InferenceHelper helper = libraryBuilder.loader
          .createBodyBuilderForOutlineExpression(libraryBuilder,
              createBodyBuilderContext(), declarationBuilder.scope, fileUri);
      Builder? targetBuilder = redirectionTarget!.target;

      if (targetBuilder is SourceMemberBuilder) {
        // Ensure that target has been built.
        targetBuilder.buildOutlineExpressions(
            classHierarchy, delayedDefaultValueCloners);
      }
      if (targetBuilder is FunctionBuilder) {
        target = targetBuilder.invokeTarget!;
      }
      // Coverage-ignore(suite): Not run.
      else if (targetBuilder is DillMemberBuilder) {
        target = targetBuilder.invokeTarget!;
      } else {
        unhandled("${targetBuilder.runtimeType}", "buildOutlineExpressions",
            fileOffset, fileUri);
      }

      typeArguments = inferrer.inferRedirectingFactoryTypeArguments(
          helper,
          _procedureInternal.function.returnType,
          _procedure.function,
          fileOffset,
          target,
          target.function!.computeFunctionType(Nullability.nonNullable));
      if (typeArguments == null) {
        assert(libraryBuilder.loader.assertProblemReportedElsewhere(
            "RedirectingFactoryTarget.buildOutlineExpressions",
            expectedPhase: CompilationPhaseForProblemReporting.outline));
        // Use 'dynamic' for recovery.
        typeArguments = new List<DartType>.filled(
            declarationBuilder.typeParametersCount, const DynamicType(),
            growable: true);
      }

      _procedureInternal.function.body =
          createRedirectingFactoryBody(target, typeArguments, function);
      assert(function == _procedureInternal.function);
      _procedureInternal.function.body!.parent = function;
      _procedureInternal.function.redirectingFactoryTarget =
          new RedirectingFactoryTarget(target, typeArguments);
    }

    Set<Procedure> seenTargets = {};
    while (target is Procedure && target.isRedirectingFactory) {
      if (!seenTargets.add(target)) {
        // Cyclic dependency.
        target = null;
        break;
      }
      RedirectingFactoryTarget redirectingFactoryTarget =
          target.function.redirectingFactoryTarget!;
      if (typeArguments != null) {
        Substitution substitution = Substitution.fromPairs(
            target.function.typeParameters, typeArguments);
        typeArguments = redirectingFactoryTarget.typeArguments
            ?.map(substitution.substituteType)
            .toList();
      } else {
        // Coverage-ignore-block(suite): Not run.
        typeArguments = redirectingFactoryTarget.typeArguments;
      }
      target = redirectingFactoryTarget.target;
    }

    if (target is Constructor ||
        target is Procedure &&
            (target.isFactory || target.isExtensionTypeMember)) {
      // Coverage-ignore(suite): Not run.
      typeArguments ??= [];
      if (_factoryTearOff != null) {
        delayedDefaultValueCloners.add(buildRedirectingFactoryTearOffBody(
            _factoryTearOff,
            target!,
            typeArguments,
            _tearOffTypeParameters!,
            libraryBuilder));
      }
      delayedDefaultValueCloners.add(new DelayedDefaultValueCloner(
          target!, _procedure,
          libraryBuilder: libraryBuilder, identicalSignatures: false));
    }
    if (isConst && isAugmenting) {
      _finishAugmentation();
    }
  }

  void _finishAugmentation() {
    finishProcedureAugmentation(origin._procedure, _procedureInternal);

    if (_factoryTearOff != null) {
      finishProcedureAugmentation(origin._factoryTearOff!, _factoryTearOff);
    }

    if (redirectionTarget != null) {
      SourceFactoryBuilder redirectingOrigin = origin;
      if (redirectingOrigin.redirectionTarget != null) {
        // Coverage-ignore-block(suite): Not run.
        redirectingOrigin.redirectionTypeArguments = redirectionTypeArguments;
      }
    }
  }

  List<DartType>? getRedirectionTypeArguments() {
    assert(redirectionTarget != null);
    return _procedure.function.redirectingFactoryTarget!.typeArguments;
  }

  // Computes the function type of a given redirection target. Returns [null] if
  // the type of the target could not be computed.
  FunctionType? _computeRedirecteeType(
      SourceFactoryBuilder factory, TypeEnvironment typeEnvironment) {
    assert(factory.redirectionTarget != null);
    ConstructorReferenceBuilder redirectionTarget = factory.redirectionTarget!;
    Builder? targetBuilder = redirectionTarget.target;
    FunctionNode targetNode;
    if (targetBuilder == null) return null;
    if (targetBuilder is FunctionBuilder) {
      targetNode = targetBuilder.function;
    } else if (targetBuilder is DillExtensionTypeFactoryBuilder) {
      targetNode = targetBuilder.member.function!;
    } else if (targetBuilder is AmbiguousBuilder) {
      // Multiple definitions with the same name: An error has already been
      // issued.
      // TODO(http://dartbug.com/35294): Unfortunate error; see also
      // https://dart-review.googlesource.com/c/sdk/+/85390/.
      return null;
    } else {
      unhandled("${targetBuilder.runtimeType}", "computeRedirecteeType",
          fileOffset, fileUri);
    }

    List<DartType>? typeArguments = factory.getRedirectionTypeArguments();
    FunctionType targetFunctionType =
        targetNode.computeFunctionType(Nullability.nonNullable);
    if (typeArguments != null &&
        targetFunctionType.typeParameters.length != typeArguments.length) {
      libraryBuilder.addProblemForRedirectingFactory(
          factory,
          templateTypeArgumentMismatch
              .withArguments(targetFunctionType.typeParameters.length),
          redirectionTarget.charOffset,
          noLength,
          redirectionTarget.fileUri);
      return null;
    }

    // Compute the substitution of the target class type parameters if
    // [redirectionTarget] has any type arguments.
    FunctionTypeInstantiator? instantiator;
    bool hasProblem = false;
    if (typeArguments != null && typeArguments.length > 0) {
      instantiator = new FunctionTypeInstantiator.fromIterables(
          targetFunctionType.typeParameters, typeArguments);
      for (int i = 0; i < targetFunctionType.typeParameters.length; i++) {
        StructuralParameter typeParameter =
            targetFunctionType.typeParameters[i];
        DartType typeParameterBound =
            instantiator.substitute(typeParameter.bound);
        DartType typeArgument = typeArguments[i];
        // Check whether the [typeArgument] respects the bounds of
        // [typeParameter].
        if (!typeEnvironment.isSubtypeOf(typeArgument, typeParameterBound,
            SubtypeCheckMode.ignoringNullabilities)) {
          // Coverage-ignore-block(suite): Not run.
          libraryBuilder.addProblemForRedirectingFactory(
              factory,
              templateRedirectingFactoryIncompatibleTypeArgument.withArguments(
                  typeArgument, typeParameterBound),
              redirectionTarget.charOffset,
              noLength,
              redirectionTarget.fileUri);
          hasProblem = true;
        } else {
          if (!typeEnvironment.isSubtypeOf(typeArgument, typeParameterBound,
              SubtypeCheckMode.withNullabilities)) {
            libraryBuilder.addProblemForRedirectingFactory(
                factory,
                templateRedirectingFactoryIncompatibleTypeArgument
                    .withArguments(typeArgument, typeParameterBound),
                redirectionTarget.charOffset,
                noLength,
                redirectionTarget.fileUri);
            hasProblem = true;
          }
        }
      }
    } else if (typeArguments == null &&
        targetFunctionType.typeParameters.length > 0) {
      // TODO(hillerstrom): In this case, we need to perform type inference on
      // the redirectee to obtain actual type arguments which would allow the
      // following program to type check:
      //
      //    class A<T> {
      //       factory A() = B;
      //    }
      //    class B<T> implements A<T> {
      //       B();
      //    }
      //
      return null;
    }

    // Substitute if necessary.
    targetFunctionType = instantiator == null
        ? targetFunctionType
        : (instantiator.substitute(targetFunctionType.withoutTypeParameters)
            as FunctionType);

    return hasProblem ? null : targetFunctionType;
  }

  bool _isCyclicRedirectingFactory(SourceFactoryBuilder factory) {
    assert(factory.redirectionTarget != null);
    // We use the [tortoise and hare algorithm]
    // (https://en.wikipedia.org/wiki/Cycle_detection#Tortoise_and_hare) to
    // handle cycles.
    Builder? tortoise = factory;
    Builder? hare = factory.redirectionTarget!.target;
    if (hare == factory) {
      return true;
    }
    while (tortoise != hare) {
      // Hare moves 2 steps forward.
      if (hare is! SourceFactoryBuilder || hare.redirectionTarget == null) {
        return false;
      }
      hare = hare.redirectionTarget!.target;
      if (hare == factory) {
        return true;
      }
      if (hare is! SourceFactoryBuilder || hare.redirectionTarget == null) {
        return false;
      }
      hare = hare.redirectionTarget!.target;
      if (hare == factory) {
        return true;
      }
      // Tortoise moves one step forward. No need to test type of tortoise
      // as it follows hare which already checked types.
      tortoise = (tortoise as SourceFactoryBuilder).redirectionTarget!.target;
    }
    // Cycle found, but original factory doesn't belong to a cycle.
    return false;
  }

  /// Checks this factory builder if it is for a redirecting factory.
  void _checkRedirectingFactory(TypeEnvironment typeEnvironment) {
    assert(redirectionTarget != null);

    if (_hasBeenCheckedAsRedirectingFactory) return;
    _hasBeenCheckedAsRedirectingFactory = true;

    // Check that factory declaration is not cyclic.
    if (_isCyclicRedirectingFactory(this)) {
      libraryBuilder.addProblemForRedirectingFactory(
          this,
          templateCyclicRedirectingFactoryConstructors
              .withArguments("${declarationBuilder.name}"
                  "${name == '' ? '' : '.${name}'}"),
          fileOffset,
          noLength,
          fileUri);
      return;
    }

    // The factory type cannot contain any type parameters other than those of
    // its enclosing class, because constructors cannot specify type parameters
    // of their own.
    FunctionType factoryType =
        function.computeThisFunctionType(Nullability.nonNullable);
    if (isAugmenting) {
      // The redirection target type uses the origin type parameters so we must
      // substitute augmentation type parameters before checking subtyping.
      if (function.typeParameters.isNotEmpty) {
        Map<TypeParameter, DartType> substitution = <TypeParameter, DartType>{};
        for (int i = 0; i < function.typeParameters.length; i++) {
          substitution[function.typeParameters[i]] =
              new TypeParameterType.withDefaultNullability(
                  actualOrigin!.function.typeParameters[i]);
        }
        factoryType = substitute(factoryType, substitution) as FunctionType;
      }
    }
    FunctionType? redirecteeType =
        _computeRedirecteeType(this, typeEnvironment);
    Map<TypeParameter, DartType> substitutionMap = {};
    for (int i = 0; i < factoryType.typeParameters.length; i++) {
      TypeParameter functionTypeParameter = origin.function.typeParameters[i];
      substitutionMap[functionTypeParameter] =
          new StructuralParameterType.withDefaultNullability(
              factoryType.typeParameters[i]);
    }
    redirecteeType = redirecteeType != null
        ? substitute(redirecteeType, substitutionMap) as FunctionType
        : null;

    // TODO(hillerstrom): It would be preferable to know whether a failure
    // happened during [_computeRedirecteeType].
    if (redirecteeType == null) {
      return;
    }

    Builder? redirectionTargetBuilder = redirectionTarget!.target;
    if (redirectionTargetBuilder is SourceFactoryBuilder &&
        redirectionTargetBuilder.redirectionTarget != null) {
      redirectionTargetBuilder._checkRedirectingFactory(typeEnvironment);
      String? errorMessage = redirectionTargetBuilder
          .function.redirectingFactoryTarget?.errorMessage;
      if (errorMessage != null) {
        setRedirectingFactoryError(errorMessage);
      }
    }

    Builder? redirectionTargetParent = redirectionTarget!.target?.parent;
    bool redirectingTargetParentIsEnum = redirectionTargetParent is ClassBuilder
        ? redirectionTargetParent.isEnum
        : false;
    if (!((classBuilder?.cls.isEnum ?? false) &&
        (redirectionTarget!.target?.isConstructor ?? false) &&
        redirectingTargetParentIsEnum)) {
      // Check whether [redirecteeType] <: [factoryType].
      FunctionType factoryTypeWithoutTypeParameters =
          factoryType.withoutTypeParameters;
      if (!typeEnvironment.isSubtypeOf(
          redirecteeType,
          factoryTypeWithoutTypeParameters,
          SubtypeCheckMode.withNullabilities)) {
        libraryBuilder.addProblemForRedirectingFactory(
            this,
            templateIncompatibleRedirecteeFunctionType.withArguments(
                redirecteeType, factoryTypeWithoutTypeParameters),
            redirectionTarget!.charOffset,
            noLength,
            redirectionTarget!.fileUri);
      }
    } else {
      // Redirection to generative enum constructors is forbidden.
      assert(libraryBuilder.loader.assertProblemReportedElsewhere(
          "RedirectingFactoryBuilder._checkRedirectingFactory: "
          "Redirection to generative enum constructor.",
          expectedPhase: CompilationPhaseForProblemReporting.bodyBuilding));
    }
  }

  BodyBuilderContext createBodyBuilderContext() {
    if (redirectionTarget != null) {
      return new RedirectingFactoryBodyBuilderContext(this, _procedure);
    } else {
      return new FactoryBodyBuilderContext(this, _procedure);
    }
  }
}
