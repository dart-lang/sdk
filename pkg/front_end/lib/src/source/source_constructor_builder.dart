// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../base/constant_context.dart' show ConstantContext;
import '../base/local_scope.dart';
import '../base/messages.dart'
    show
        LocatedMessage,
        Message,
        messageMoreThanOneSuperInitializer,
        messageRedirectingConstructorWithAnotherInitializer,
        messageRedirectingConstructorWithMultipleRedirectInitializers,
        messageRedirectingConstructorWithSuperInitializer,
        messageSuperInitializerNotLast,
        noLength;
import '../base/modifiers.dart';
import '../base/name_space.dart';
import '../base/scope.dart';
import '../builder/builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/type_builder.dart';
import '../fragment/constructor/body_builder_context.dart';
import '../fragment/constructor/declaration.dart';
import '../kernel/body_builder.dart' show BodyBuilder;
import '../kernel/body_builder_context.dart';
import '../kernel/expression_generator_helper.dart';
import '../kernel/hierarchy/class_member.dart' show ClassMember;
import '../kernel/internal_ast.dart';
import '../kernel/kernel_helper.dart'
    show DelayedDefaultValueCloner, TypeDependency;
import '../kernel/type_algorithms.dart';
import '../type_inference/inference_results.dart';
import 'constructor_declaration.dart';
import 'name_scheme.dart';
import 'source_class_builder.dart';
import 'source_function_builder.dart';
import 'source_library_builder.dart' show SourceLibraryBuilder;
import 'source_loader.dart'
    show CompilationPhaseForProblemReporting, SourceLoader;
import 'source_member_builder.dart';
import 'source_property_builder.dart';

abstract class SourceConstructorBuilder implements ConstructorBuilder {
  @override
  DeclarationBuilder get declarationBuilder;

  void buildOutlineNodes(BuildNodesCallback f);

  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners);

  int buildBodyNodes(BuildNodesCallback f);

  /// Infers the types of any untyped initializing formals.
  void inferFormalTypes(ClassHierarchyBase hierarchy);

  void addSuperParameterDefaultValueCloners(
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners);

  /// Returns `true` if this constructor is an redirecting generative
  /// constructor.
  ///
  /// It is considered redirecting if it has at least one redirecting
  /// initializer.
  bool get isRedirecting;

  @override
  Uri get fileUri;
}

class SourceConstructorBuilderImpl extends SourceMemberBuilderImpl
    implements
        SourceConstructorBuilder,
        SourceFunctionBuilder,
        Inferable,
        ConstructorDeclarationBuilder,
        InferredTypeListener {
  final Modifiers modifiers;

  @override
  final String name;

  @override
  final SourceLibraryBuilder libraryBuilder;

  @override
  final DeclarationBuilder declarationBuilder;

  @override
  final int fileOffset;

  @override
  final Uri fileUri;

  Token? beginInitializers;

  final ConstructorDeclaration _introductory;

  final MemberName _memberName;

  final List<DelayedDefaultValueCloner> _delayedDefaultValueCloners = [];

  Set<SourcePropertyBuilder>? _initializedFields;

  SourceConstructorBuilderImpl? actualOrigin;

  List<SourceConstructorBuilderImpl>? _augmentations;

  SourceConstructorBuilderImpl({
    required this.modifiers,
    required this.name,
    required this.libraryBuilder,
    required this.declarationBuilder,
    required this.fileOffset,
    required this.fileUri,
    this.nativeMethodName,
    required Reference? constructorReference,
    required Reference? tearOffReference,
    required NameScheme nameScheme,
    required this.beginInitializers,
    required ConstructorDeclaration constructorDeclaration,
  })  : _introductory = constructorDeclaration,
        _memberName = nameScheme.getDeclaredName(name) {
    _introductory.createNode(
        name: name,
        libraryBuilder: libraryBuilder,
        nameScheme: nameScheme,
        constructorReference: constructorReference,
        tearOffReference: tearOffReference);

    returnType.registerInferredTypeListener(this);
    if (formals != null) {
      for (FormalParameterBuilder formal in formals!) {
        if (formal.isInitializingFormal || formal.isSuperInitializingFormal) {
          formal.type.registerInferable(this);
        }
      }
    }
  }

  @override
  Builder get parent => declarationBuilder;

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => _introductory.metadata;

  @override
  OmittedTypeBuilder get returnType => _introductory.returnType;

  @override
  List<NominalParameterBuilder>? get typeParameters =>
      _introductory.typeParameters;

  @override
  List<FormalParameterBuilder>? get formals => _introductory.formals;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadataForTesting => metadata;

  @override
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
  // Coverage-ignore(suite): Not run.
  bool get isAssignable => false;

  @override
  // Coverage-ignore(suite): Not run.
  Name get memberName => _memberName.name;

  /// Returns `true` if this member is augmented, either by being the origin
  /// of a augmented member or by not being the last among augmentations.
  bool get isAugmented {
    if (isAugmenting) {
      return origin._augmentations!.last != this;
    } else {
      return _augmentations != null;
    }
  }

  @override
  SourceConstructorBuilderImpl get origin => actualOrigin ?? this;

  // Coverage-ignore(suite): Not run.
  List<SourceConstructorBuilder>? get augmentationsForTesting => _augmentations;

  void _addAugmentation(Builder augmentation) {
    if (augmentation is SourceConstructorBuilderImpl) {
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
  void addAugmentation(Builder augmentation) {
    _addAugmentation(augmentation);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void applyAugmentation(Builder augmentation) {
    _addAugmentation(augmentation);
  }

  @override
  bool get isRedirecting => _introductory.isRedirecting;

  @override
  VariableDeclaration? get thisVariable => _introductory.thisVariable;

  @override
  List<TypeParameter>? get thisTypeParameters =>
      _introductory.thisTypeParameters;

  @override
  Member get readTarget => _introductory.readTarget;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => _introductory.readTargetReference;

  @override
  Member get invokeTarget =>
      isAugmenting ? origin.invokeTarget : _introductory.invokeTarget;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => isAugmenting
      ? origin.invokeTargetReference
      : _introductory.invokeTargetReference;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => null;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [invokeTargetReference];

  // TODO(johnniwinther): Add annotations to tear-offs.
  @override
  Iterable<Annotatable> get annotatables => [invokeTarget];

  @override
  FunctionNode get function => _introductory.function;

  @override
  void becomeNative(SourceLoader loader) {
    _introductory.becomeNative();
    for (Annotatable annotatable in annotatables) {
      loader.addNativeAnnotation(annotatable, nativeMethodName!);
    }
  }

  late final Substitution _fieldTypeSubstitution =
      _introductory.computeFieldTypeSubstitution(declarationBuilder);

  @override
  DartType substituteFieldType(DartType fieldType) {
    return _fieldTypeSubstitution.substituteType(fieldType);
  }

  LocalScope computeFormalParameterScope(LookupScope parent) {
    if (formals == null) return new FormalParameterScope(parent: parent);
    Map<String, Builder> local = <String, Builder>{};
    for (FormalParameterBuilder formal in formals!) {
      if (formal.isWildcard) {
        continue;
      }
      if (!isConstructor ||
          !formal.isInitializingFormal && !formal.isSuperInitializingFormal) {
        local[formal.name] = formal;
      }
    }
    return new FormalParameterScope(local: local, parent: parent);
  }

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

  final String? nativeMethodName;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isNative => nativeMethodName != null;

  @override
  void onInferredType(DartType type) {
    function.returnType = type;
  }

  @override
  bool get isConstructor => true;

  List<Initializer> get _initializers => _introductory.initializers;

  List<Initializer> get initializers =>
      isAugmenting ? origin.initializers : _initializers;

  SuperInitializer? superInitializer;

  RedirectingInitializer? redirectingInitializer;

  void _injectInvalidInitializer(Message message, int charOffset, int length,
      ExpressionGeneratorHelper helper, TreeNode parent) {
    Initializer lastInitializer = _introductory.initializers.removeLast();
    assert(lastInitializer == superInitializer ||
        lastInitializer == redirectingInitializer);
    Initializer error = helper.buildInvalidInitializer(
        helper.buildProblem(message, charOffset, length));
    _initializers.add(error..parent = parent);
    _initializers.add(lastInitializer);
  }

  @override
  void addInitializer(Initializer initializer, ExpressionGeneratorHelper helper,
      {required InitializerInferenceResult? inferenceResult,
      required TreeNode parent}) {
    if (initializer is SuperInitializer) {
      if (superInitializer != null) {
        _injectInvalidInitializer(messageMoreThanOneSuperInitializer,
            initializer.fileOffset, "super".length, helper, parent);
      } else if (redirectingInitializer != null) {
        _injectInvalidInitializer(
            messageRedirectingConstructorWithSuperInitializer,
            initializer.fileOffset,
            "super".length,
            helper,
            parent);
      } else {
        inferenceResult?.applyResult(_initializers, parent);
        superInitializer = initializer;

        LocatedMessage? message = helper.checkArgumentsForFunction(
            initializer.target.function,
            initializer.arguments,
            initializer.arguments.fileOffset, <TypeParameter>[]);
        if (message != null) {
          _initializers.add(helper.buildInvalidInitializer(
              helper.buildUnresolvedError(
                  helper.constructorNameForDiagnostics(
                      initializer.target.name.text),
                  initializer.fileOffset,
                  arguments: initializer.arguments,
                  isSuper: true,
                  message: message,
                  kind: UnresolvedKind.Constructor))
            ..parent = parent);
        } else {
          _initializers.add(initializer..parent = parent);
        }
      }
    } else if (initializer is RedirectingInitializer) {
      if (superInitializer != null) {
        // Point to the existing super initializer.
        _injectInvalidInitializer(
            messageRedirectingConstructorWithSuperInitializer,
            superInitializer!.fileOffset,
            "super".length,
            helper,
            parent);
      } else if (redirectingInitializer != null) {
        _injectInvalidInitializer(
            messageRedirectingConstructorWithMultipleRedirectInitializers,
            initializer.fileOffset,
            noLength,
            helper,
            parent);
      } else if (_initializers.isNotEmpty) {
        // Error on all previous ones.
        for (int i = 0; i < _initializers.length; i++) {
          Initializer initializer = _initializers[i];
          int length = noLength;
          if (initializer is AssertInitializer) length = "assert".length;
          Initializer error = helper.buildInvalidInitializer(
              helper.buildProblem(
                  messageRedirectingConstructorWithAnotherInitializer,
                  initializer.fileOffset,
                  length));
          error.parent = parent;
          _initializers[i] = error;
        }
        inferenceResult?.applyResult(_initializers, parent);
        _initializers.add(initializer..parent = parent);
        redirectingInitializer = initializer;
      } else {
        inferenceResult?.applyResult(_initializers, parent);
        redirectingInitializer = initializer;

        LocatedMessage? message = helper.checkArgumentsForFunction(
            initializer.target.function,
            initializer.arguments,
            initializer.arguments.fileOffset, const <TypeParameter>[]);
        if (message != null) {
          _initializers.add(helper.buildInvalidInitializer(
              helper.buildUnresolvedError(
                  helper.constructorNameForDiagnostics(
                      initializer.target.name.text),
                  initializer.fileOffset,
                  arguments: initializer.arguments,
                  isSuper: false,
                  message: message,
                  kind: UnresolvedKind.Constructor))
            ..parent = parent);
        } else {
          _initializers.add(initializer..parent = parent);
        }
      }
    } else if (redirectingInitializer != null) {
      int length = noLength;
      if (initializer is AssertInitializer) length = "assert".length;
      _injectInvalidInitializer(
          messageRedirectingConstructorWithAnotherInitializer,
          initializer.fileOffset,
          length,
          helper,
          parent);
    } else if (superInitializer != null) {
      _injectInvalidInitializer(messageSuperInitializerNotLast,
          initializer.fileOffset, noLength, helper, parent);
    } else {
      inferenceResult?.applyResult(_initializers, parent);
      _initializers.add(initializer..parent = parent);
    }
  }

  void _buildConstructorForOutline(Token? beginInitializers) {
    if (beginInitializers != null) {
      final LocalScope? formalParameterScope;
      if (isConst) {
        // We're going to fully build the constructor so we need scopes.
        formalParameterScope = computeFormalParameterInitializerScope(
            computeFormalParameterScope(_introductory.typeParameterScope));
      } else {
        formalParameterScope = null;
      }
      BodyBuilder bodyBuilder = libraryBuilder.loader
          .createBodyBuilderForOutlineExpression(
              libraryBuilder,
              createBodyBuilderContext(),
              _introductory.typeParameterScope,
              fileUri,
              formalParameterScope: formalParameterScope);
      if (isConst) {
        bodyBuilder.constantContext = ConstantContext.required;
      }
      inferFormalTypes(bodyBuilder.hierarchy);
      bodyBuilder.parseInitializers(beginInitializers,
          doFinishConstructor: isConst);
      bodyBuilder.performBacklogComputations();
    }
  }

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    int count = context.computeDefaultTypesForVariables(typeParameters,
        // Type parameters are inherited from the enclosing declaration, so if
        // it has issues, so do the constructors.
        inErrorRecovery: inErrorRecovery);
    context.reportGenericFunctionTypesForFormals(formals);
    List<SourceConstructorBuilderImpl>? augmentations = _augmentations;
    if (augmentations != null) {
      for (SourceConstructorBuilderImpl augmentation in augmentations) {
        count += augmentation.computeDefaultTypes(context,
            inErrorRecovery: inErrorRecovery);
      }
    }
    return count;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

  @override
  void checkTypes(SourceLibraryBuilder library, NameSpace nameSpace,
      TypeEnvironment typeEnvironment) {
    library.checkInitializersInFormals(formals, typeEnvironment,
        isAbstract: isAbstract, isExternal: isExternal);
    List<SourceConstructorBuilderImpl>? augmentations = _augmentations;
    if (augmentations != null) {
      for (SourceConstructorBuilderImpl augmentation in augmentations) {
        augmentation.checkTypes(library, nameSpace, typeEnvironment);
      }
    }
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
  bool get isFactory => false;

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

  @override
  void buildOutlineNodes(BuildNodesCallback f) {
    _introductory.buildOutlineNodes(f,
        constructorBuilder: this,
        libraryBuilder: libraryBuilder,
        declarationConstructor: invokeTarget,
        delayedDefaultValueCloners: _delayedDefaultValueCloners);
    List<SourceConstructorBuilder>? augmentations = _augmentations;
    if (augmentations != null) {
      for (SourceConstructorBuilder augmentation in augmentations) {
        augmentation.buildOutlineNodes((
            {required Member member,
            Member? tearOff,
            required BuiltMemberKind kind}) {
          // Don't add augmentations.
        });
      }
    }
  }

  @override
  int buildBodyNodes(BuildNodesCallback f) {
    _introductory.buildBody();
    int count = 0;
    List<SourceConstructorBuilder>? augmentations = _augmentations;
    if (augmentations != null) {
      for (SourceConstructorBuilder augmentation in augmentations) {
        count += augmentation.buildBodyNodes(f);
      }
    }
    if (isAugmenting) {
      _introductory.finishAugmentation(origin);
    }
    return count;
  }

  @override
  void registerInitializedField(SourcePropertyBuilder fieldBuilder) {
    if (isAugmenting) {
      origin.registerInitializedField(fieldBuilder);
    } else {
      (_initializedFields ??= {}).add(fieldBuilder);
    }
  }

  @override
  Set<SourcePropertyBuilder>? takeInitializedFields() {
    Set<SourcePropertyBuilder>? result = _initializedFields;
    _initializedFields = null;
    return result;
  }

  @override
  void prepareInitializers() {
    _introductory.prepareInitializers();
    redirectingInitializer = null;
    superInitializer = null;
  }

  @override
  void prependInitializer(Initializer initializer) {
    if (isAugmentation) {
      // Coverage-ignore-block(suite): Not run.
      origin.prependInitializer(initializer);
    } else {
      _introductory.prependInitializer(initializer);
    }
  }

  bool _hasBuiltOutlines = false;
  bool hasBuiltOutlineExpressions = false;

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (_hasBuiltOutlines) return;

    if (isConst && isAugmenting) {
      origin.buildOutlineExpressions(
          classHierarchy, delayedDefaultValueCloners);
    }
    if (!hasBuiltOutlineExpressions) {
      formals?.infer(classHierarchy);

      _introductory.buildOutlineExpressions(
          annotatables: annotatables,
          libraryBuilder: libraryBuilder,
          declarationBuilder: declarationBuilder,
          bodyBuilderContext: createBodyBuilderContext(),
          classHierarchy: classHierarchy,
          createFileUriExpression: isAugmented);

      hasBuiltOutlineExpressions = true;
    }
    if (isConst || _introductory.hasSuperInitializingFormals) {
      // For modular compilation purposes we need to include initializers
      // for const constructors into the outline.
      _buildConstructorForOutline(beginInitializers);
      _introductory.buildBody();
    }

    addSuperParameterDefaultValueCloners(delayedDefaultValueCloners);
    delayedDefaultValueCloners.addAll(_delayedDefaultValueCloners);
    _delayedDefaultValueCloners.clear();

    if (isConst && isAugmenting) {
      _introductory.finishAugmentation(origin);
    }

    beginInitializers = null;
    _hasBuiltOutlines = true;

    List<SourceConstructorBuilder>? augmentations = _augmentations;
    if (augmentations != null) {
      for (SourceConstructorBuilder augmentation in augmentations) {
        augmentation.buildOutlineExpressions(
            classHierarchy, delayedDefaultValueCloners);
      }
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get fullNameForErrors {
    return "${declarationBuilder.name}"
        "${name.isEmpty ? '' : '.$name'}";
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isDeclarationInstanceMember => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isClassInstanceMember => false;

  @override
  bool get isEffectivelyExternal {
    bool isExternal = this.isExternal;
    if (isExternal) {
      List<SourceConstructorBuilder>? augmentations = _augmentations;
      if (augmentations != null) {
        for (SourceConstructorBuilder augmentation in augmentations) {
          isExternal &= augmentation.isExternal;
        }
      }
    }
    return isExternal;
  }

  @override
  bool get isEffectivelyRedirecting {
    bool isRedirecting = this.isRedirecting;
    if (!isRedirecting) {
      List<SourceConstructorBuilder>? augmentations = _augmentations;
      if (augmentations != null) {
        for (SourceConstructorBuilder augmentation in augmentations) {
          isRedirecting |= augmentation.isRedirecting;
        }
      }
    }
    return isRedirecting;
  }

  ConstructorBuilder? _computeSuperTargetBuilder(
      List<Initializer>? initializers) {
    if (declarationBuilder is! SourceClassBuilder) {
      return null;
    }
    SourceClassBuilder classBuilder = declarationBuilder as SourceClassBuilder;

    Member superTarget;
    ClassBuilder superclassBuilder;

    TypeBuilder? supertype = classBuilder.supertypeBuilder;
    TypeDeclarationBuilder? supertypeDeclaration =
        supertype?.computeUnaliasedDeclaration(isUsedAsClass: false);
    if (supertypeDeclaration is ClassBuilder) {
      superclassBuilder = supertypeDeclaration;
    } else {
      assert(libraryBuilder.loader.assertProblemReportedElsewhere(
          "${this.runtimeType}._computeSuperTargetBuilder: "
          "Unaliased 'declaration' isn't a ClassBuilder.",
          expectedPhase: CompilationPhaseForProblemReporting.outline));
      return null;
    }

    if (initializers != null &&
        initializers.isNotEmpty &&
        initializers.last is SuperInitializer) {
      superTarget = (initializers.last as SuperInitializer).target;
    } else {
      MemberBuilder? memberBuilder = superclassBuilder.findConstructorOrFactory(
          "", fileOffset, fileUri, libraryBuilder);
      if (memberBuilder is ConstructorBuilder) {
        superTarget = memberBuilder.invokeTarget;
      } else {
        assert(libraryBuilder.loader.assertProblemReportedElsewhere(
            "${this.runtimeType}._computeSuperTargetBuilder: "
            "Can't find the implied unnamed constructor in the superclass.",
            expectedPhase: CompilationPhaseForProblemReporting.bodyBuilding));
        return null;
      }
    }

    MemberBuilder? constructorBuilder =
        superclassBuilder.findConstructorOrFactory(
            superTarget.name.text, fileOffset, fileUri, libraryBuilder);
    if (constructorBuilder is ConstructorBuilder) {
      return constructorBuilder;
    } else {
      // Coverage-ignore-block(suite): Not run.
      assert(libraryBuilder.loader.assertProblemReportedElsewhere(
          "${this.runtimeType}._computeSuperTargetBuilder: "
          "Can't find a constructor with name '${superTarget.name.text}' in "
          "the superclass.",
          expectedPhase: CompilationPhaseForProblemReporting.outline));
      return null;
    }
  }

  @override
  void inferTypes(ClassHierarchyBase hierarchy) {
    inferFormalTypes(hierarchy);
  }

  bool _hasFormalsInferred = false;

  @override
  void inferFormalTypes(ClassHierarchyBase hierarchy) {
    if (_hasFormalsInferred) return;
    if (formals != null) {
      libraryBuilder.loader.withUriForCrashReporting(fileUri, fileOffset, () {
        for (FormalParameterBuilder formal in formals!) {
          if (formal.type is InferableTypeBuilder) {
            if (formal.isInitializingFormal) {
              formal.finalizeInitializingFormal(
                  declarationBuilder, this, hierarchy);
            }
          }
        }
        _inferSuperInitializingFormals(hierarchy);
      });
    }
    _hasFormalsInferred = true;
  }

  void _inferSuperInitializingFormals(ClassHierarchyBase hierarchy) {
    if (_introductory.hasSuperInitializingFormals) {
      List<Initializer>? initializers;
      if (beginInitializers != null) {
        BodyBuilder bodyBuilder = libraryBuilder.loader
            .createBodyBuilderForOutlineExpression(
                libraryBuilder,
                createBodyBuilderContext(),
                _introductory.typeParameterScope,
                fileUri);
        if (isConst) {
          bodyBuilder.constantContext = ConstantContext.required;
        }
        initializers = bodyBuilder.parseInitializers(beginInitializers!,
            doFinishConstructor: false);
      }
      _finalizeSuperInitializingFormals(
          hierarchy, _delayedDefaultValueCloners, initializers);
    }
  }

  void _finalizeSuperInitializingFormals(
      ClassHierarchyBase hierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
      List<Initializer>? initializers) {
    if (formals == null) return;
    if (!_introductory.hasSuperInitializingFormals) return;

    void performRecoveryForErroneousCase() {
      for (FormalParameterBuilder formal in formals!) {
        if (formal.isSuperInitializingFormal) {
          TypeBuilder type = formal.type;
          if (type is InferableTypeBuilder) {
            type.registerInferredType(const InvalidType());
          }
        }
      }
    }

    ConstructorBuilder? superTargetBuilder =
        _computeSuperTargetBuilder(initializers);

    if (superTargetBuilder is SourceConstructorBuilder) {
      superTargetBuilder.inferFormalTypes(hierarchy);
    }

    Member superTarget;
    FunctionNode? superConstructorFunction;
    if (superTargetBuilder != null) {
      superTarget = superTargetBuilder.invokeTarget;
      superConstructorFunction = superTargetBuilder.function;
    } else {
      assert(libraryBuilder.loader.assertProblemReportedElsewhere(
          "${this.runtimeType}.finalizeSuperInitializingFormals: "
          "Can't compute super target.",
          expectedPhase: CompilationPhaseForProblemReporting.bodyBuilding));
      // Perform a simple recovery.
      return performRecoveryForErroneousCase();
    }

    List<DartType?> positionalSuperFormalType = [];
    List<bool> positionalSuperFormalHasInitializer = [];
    Map<String, DartType?> namedSuperFormalType = {};
    Map<String, bool> namedSuperFormalHasInitializer = {};

    for (VariableDeclaration formal
        in superConstructorFunction.positionalParameters) {
      positionalSuperFormalType.add(formal.type);
      positionalSuperFormalHasInitializer.add(formal.hasDeclaredInitializer);
    }
    for (VariableDeclaration formal
        in superConstructorFunction.namedParameters) {
      namedSuperFormalType[formal.name!] = formal.type;
      namedSuperFormalHasInitializer[formal.name!] =
          formal.hasDeclaredInitializer;
    }

    int superInitializingFormalIndex = -1;
    List<int?>? positionalSuperParameters;
    List<String>? namedSuperParameters;

    Supertype? supertype = hierarchy.getClassAsInstanceOf(
        classBuilder!.cls, superTarget.enclosingClass!);
    assert(supertype != null);
    Map<TypeParameter, DartType> substitution =
        new Map<TypeParameter, DartType>.fromIterables(
            supertype!.classNode.typeParameters, supertype.typeArguments);

    for (int formalIndex = 0; formalIndex < formals!.length; formalIndex++) {
      FormalParameterBuilder formal = formals![formalIndex];
      if (formal.isSuperInitializingFormal) {
        superInitializingFormalIndex++;
        bool hasImmediatelyDeclaredInitializer =
            formal.hasImmediatelyDeclaredInitializer;

        DartType? correspondingSuperFormalType;
        if (formal.isPositional) {
          assert(positionalSuperFormalHasInitializer.length ==
              positionalSuperFormalType.length);
          if (superInitializingFormalIndex <
              positionalSuperFormalHasInitializer.length) {
            if (formal.isOptional) {
              formal.hasDeclaredInitializer =
                  hasImmediatelyDeclaredInitializer ||
                      positionalSuperFormalHasInitializer[
                          superInitializingFormalIndex];
            }
            correspondingSuperFormalType =
                positionalSuperFormalType[superInitializingFormalIndex];
            if (!hasImmediatelyDeclaredInitializer &&
                !formal.isRequiredPositional) {
              (positionalSuperParameters ??= <int?>[]).add(formalIndex);
            } else {
              (positionalSuperParameters ??= <int?>[]).add(null);
            }
          } else {
            assert(libraryBuilder.loader.assertProblemReportedElsewhere(
                "${this.runtimeType}"
                ".finalizeSuperInitializingFormals: "
                "Super initializer count is greater than the count of "
                "positional formals in the super constructor.",
                expectedPhase:
                    CompilationPhaseForProblemReporting.bodyBuilding));
          }
        } else {
          if (namedSuperFormalHasInitializer[formal.name] != null) {
            if (formal.isOptional) {
              formal.hasDeclaredInitializer =
                  hasImmediatelyDeclaredInitializer ||
                      namedSuperFormalHasInitializer[formal.name]!;
            }
            correspondingSuperFormalType = namedSuperFormalType[formal.name];
            if (!hasImmediatelyDeclaredInitializer && !formal.isRequiredNamed) {
              (namedSuperParameters ??= <String>[]).add(formal.name);
            }
          } else {
            // TODO(cstefantsova): Report an error.
          }
        }

        if (formal.type is InferableTypeBuilder) {
          DartType? type = correspondingSuperFormalType;
          if (substitution.isNotEmpty && type != null) {
            type = substitute(type, substitution);
          }
          formal.type.registerInferredType(type ?? const DynamicType());
        }
        formal.variable!.hasDeclaredInitializer = formal.hasDeclaredInitializer;
      }
    }

    if (positionalSuperParameters != null || namedSuperParameters != null) {
      _introductory.addSuperParameterDefaultValueCloners(
          libraryBuilder: libraryBuilder,
          delayedDefaultValueCloners: delayedDefaultValueCloners,
          superTarget: superTarget,
          positionalSuperParameters: positionalSuperParameters,
          namedSuperParameters: namedSuperParameters);
    }
  }

  @override
  void addSuperParameterDefaultValueCloners(
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (beginInitializers != null && initializers.isNotEmpty) {
      // If the initializers aren't built yet, we can't compute the super
      // target. The synthetic initializers should be excluded, since they can
      // be built separately from formal field initializers.
      bool allInitializersAreSynthetic = true;
      for (Initializer initializer in initializers) {
        if (!initializer.isSynthetic) {
          allInitializersAreSynthetic = false;
          break;
        }
      }
      if (!allInitializersAreSynthetic) {
        ConstructorBuilder? superTargetBuilder =
            _computeSuperTargetBuilder(initializers);
        if (superTargetBuilder is SourceConstructorBuilder) {
          superTargetBuilder
              .addSuperParameterDefaultValueCloners(delayedDefaultValueCloners);
        }
      }
    }
  }

  BodyBuilderContext createBodyBuilderContext() {
    return new ConstructorBodyBuilderContext(this, _introductory, invokeTarget);
  }
}

class SyntheticSourceConstructorBuilder extends MemberBuilderImpl
    with SourceMemberBuilderMixin
    implements SourceConstructorBuilder {
  @override
  final SourceLibraryBuilder libraryBuilder;

  @override
  final SourceClassBuilder classBuilder;

  final Constructor _constructor;
  final Procedure? _constructorTearOff;

  /// The constructor from which this synthesized constructor is defined.
  ///
  /// This defines the parameter structure and the default values of this
  /// constructor.
  ///
  /// The [_immediatelyDefiningConstructor] might itself a synthesized
  /// constructor and [_effectivelyDefiningConstructor] can be used to find
  /// the constructor that effectively defines this constructor.
  MemberBuilder? _immediatelyDefiningConstructor;
  DelayedDefaultValueCloner? _delayedDefaultValueCloner;
  TypeDependency? _typeDependency;

  SyntheticSourceConstructorBuilder(this.libraryBuilder, this.classBuilder,
      Constructor constructor, Procedure? constructorTearOff,
      {MemberBuilder? definingConstructor,
      DelayedDefaultValueCloner? delayedDefaultValueCloner,
      TypeDependency? typeDependency})
      : _immediatelyDefiningConstructor = definingConstructor,
        _delayedDefaultValueCloner = delayedDefaultValueCloner,
        _typeDependency = typeDependency,
        _constructor = constructor,
        _constructorTearOff = constructorTearOff;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadataForTesting => null;

  @override
  // Coverage-ignore(suite): Not run.
  int get fileOffset => _constructor.fileOffset;

  @override
  // Coverage-ignore(suite): Not run.
  Uri get fileUri => _constructor.fileUri;

  @override
  Builder get parent => declarationBuilder;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [_constructor.reference];

  @override
  String get name => _constructor.name.text;

  @override
  // Coverage-ignore(suite): Not run.
  Name get memberName => _constructor.name;

  @override
  bool get isConstructor => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isFinal => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSynthesized => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAbstract => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExternal => _constructor.isExternal;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSynthetic => _constructor.isSynthetic;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAssignable => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isRegularMethod => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isGetter => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSetter => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isOperator => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isFactory => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isProperty => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isEnumElement => false;

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localMembers =>
      throw new UnsupportedError('${runtimeType}.localMembers');

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localSetters =>
      throw new UnsupportedError('${runtimeType}.localSetters');

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Annotatable> get annotatables => [_constructor];

  @override
  FunctionNode get function => _constructor.function;

  @override
  Member get readTarget => _constructorTearOff ?? _constructor;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference =>
      (_constructorTearOff ?? _constructor).reference;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => null;

  @override
  Constructor get invokeTarget => _constructor;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _constructor.reference;

  @override
  bool get isConst => _constructor.isConst;

  @override
  DeclarationBuilder get declarationBuilder => classBuilder;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isRedirecting {
    for (Initializer initializer in _constructor.initializers) {
      if (initializer is RedirectingInitializer) {
        return true;
      }
    }
    return false;
  }

  @override
  void inferFormalTypes(ClassHierarchyBase hierarchy) {
    if (_immediatelyDefiningConstructor is SourceConstructorBuilder) {
      (_immediatelyDefiningConstructor as SourceConstructorBuilder)
          .inferFormalTypes(hierarchy);
    }
    if (_typeDependency != null) {
      _typeDependency!.copyInferred();
      _typeDependency = null;
    }
  }

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (_immediatelyDefiningConstructor != null) {
      // Ensure that default value expressions have been created for [_origin].
      // If [_origin] is from a source library, we need to build the default
      // values and initializers first.
      MemberBuilder origin = _immediatelyDefiningConstructor!;
      if (origin is SourceConstructorBuilder) {
        origin.buildOutlineExpressions(
            classHierarchy, delayedDefaultValueCloners);
      }
      addSuperParameterDefaultValueCloners(delayedDefaultValueCloners);
      _immediatelyDefiningConstructor = null;
    }
  }

  @override
  void addSuperParameterDefaultValueCloners(
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    MemberBuilder? origin = _immediatelyDefiningConstructor;
    if (origin is SourceConstructorBuilder) {
      origin.addSuperParameterDefaultValueCloners(delayedDefaultValueCloners);
    }
    if (_delayedDefaultValueCloner != null) {
      // For constant constructors default values are computed and cloned part
      // of the outline expression and we there set `isOutlineNode` to `true`
      // below.
      //
      // For non-constant constructors default values are cloned as part of the
      // full compilation using `KernelTarget._delayedDefaultValueCloners`.
      delayedDefaultValueCloners
          .add(_delayedDefaultValueCloner!..isOutlineNode = true);
      _delayedDefaultValueCloner = null;
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    assert(false, "Unexpected call to $runtimeType.computeDefaultType");
    return 0;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

  @override
  void checkTypes(SourceLibraryBuilder library, NameSpace nameSpace,
      TypeEnvironment typeEnvironment) {}
}

class ExtensionTypeInitializerToStatementConverter
    implements InitializerVisitor<void> {
  VariableDeclaration thisVariable;
  final List<Statement> statements;

  ExtensionTypeInitializerToStatementConverter(
      this.statements, this.thisVariable);

  @override
  void visitAuxiliaryInitializer(AuxiliaryInitializer node) {
    if (node is ExtensionTypeRedirectingInitializer) {
      statements.add(new ExpressionStatement(
          new VariableSet(
              thisVariable,
              new StaticInvocation(node.target, node.arguments)
                ..fileOffset = node.fileOffset)
            ..fileOffset = node.fileOffset)
        ..fileOffset = node.fileOffset);
      return;
    } else if (node is ExtensionTypeRepresentationFieldInitializer) {
      thisVariable
        ..initializer = (node.value..parent = thisVariable)
        ..fileOffset = node.fileOffset;
      return;
    }
    // Coverage-ignore-block(suite): Not run.
    throw new UnsupportedError(
        "Unexpected initializer $node (${node.runtimeType})");
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    statements.add(node.statement);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitFieldInitializer(FieldInitializer node) {
    thisVariable
      ..initializer = (node.value..parent = thisVariable)
      ..fileOffset = node.fileOffset;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitInvalidInitializer(InvalidInitializer node) {
    statements.add(new ExpressionStatement(
        new InvalidExpression(null)..fileOffset = node.fileOffset)
      ..fileOffset);
  }

  @override
  void visitLocalInitializer(LocalInitializer node) {
    statements.add(node.variable);
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    throw new UnsupportedError(
        "Unexpected initializer $node (${node.runtimeType})");
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitSuperInitializer(SuperInitializer node) {
    // TODO(johnniwinther): Report error for this case.
  }
}
