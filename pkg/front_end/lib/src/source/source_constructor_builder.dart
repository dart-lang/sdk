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
import '../builder/property_builder.dart';
import '../builder/type_builder.dart';
import '../kernel/body_builder.dart' show BodyBuilder;
import '../kernel/body_builder_context.dart';
import '../kernel/constructor_tearoff_lowering.dart';
import '../kernel/expression_generator_helper.dart';
import '../kernel/hierarchy/class_member.dart' show ClassMember;
import '../kernel/internal_ast.dart';
import '../kernel/kernel_helper.dart'
    show
        DelayedDefaultValueCloner,
        TypeDependency,
        finishConstructorAugmentation,
        finishProcedureAugmentation;
import '../kernel/type_algorithms.dart';
import '../type_inference/inference_results.dart';
import '../type_inference/type_schema.dart';
import 'constructor_declaration.dart';
import 'name_scheme.dart';
import 'source_class_builder.dart';
import 'source_enum_builder.dart';
import 'source_extension_type_declaration_builder.dart';
import 'source_function_builder.dart';
import 'source_library_builder.dart' show SourceLibraryBuilder;
import 'source_loader.dart'
    show CompilationPhaseForProblemReporting, SourceLoader;
import 'source_member_builder.dart';

abstract class SourceConstructorBuilder
    implements ConstructorBuilder, SourceMemberBuilder {
  @override
  DeclarationBuilder get declarationBuilder;

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
}

abstract class AbstractSourceConstructorBuilder
    extends SourceFunctionBuilderImpl
    implements SourceConstructorBuilder, Inferable, ConstructorDeclaration {
  @override
  final OmittedTypeBuilder returnType;

  final int charOpenParenOffset;

  bool _hasFormalsInferred = false;

  Token? beginInitializers;

  AbstractSourceConstructorBuilder(
      List<MetadataBuilder>? metadata,
      Modifiers modifiers,
      this.returnType,
      String name,
      List<NominalParameterBuilder>? typeParameters,
      List<FormalParameterBuilder>? formals,
      this.charOpenParenOffset,
      String? nativeMethodName,
      this.beginInitializers)
      : super(metadata, modifiers, name, typeParameters, formals,
            nativeMethodName) {
    if (formals != null) {
      for (FormalParameterBuilder formal in formals) {
        if (formal.isInitializingFormal || formal.isSuperInitializingFormal) {
          formal.type.registerInferable(this);
        }
      }
    }
  }

  @override
  bool get isConstructor => true;

  @override
  Statement? get body {
    if (bodyInternal == null && !isExternal) {
      bodyInternal = new EmptyStatement();
    }
    return bodyInternal;
  }

  @override
  AsyncMarker get asyncModifier => AsyncMarker.Sync;

  @override
  void inferTypes(ClassHierarchyBase hierarchy) {
    inferFormalTypes(hierarchy);
  }

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

  // Coverage-ignore(suite): Not run.
  void _inferSuperInitializingFormals(ClassHierarchyBase hierarchy) {}

  void _buildFormals(Member member) {
    if (formals != null) {
      bool needsInference = false;
      for (FormalParameterBuilder formal in formals!) {
        if (formal.type is InferableTypeBuilder &&
            (formal.isInitializingFormal || formal.isSuperInitializingFormal)) {
          formal.variable!.type = const UnknownType();
          needsInference = true;
        } else if (!formal.hasDeclaredInitializer &&
            formal.isSuperInitializingFormal) {
          needsInference = true;
        }
      }
      if (needsInference) {
        libraryBuilder.loader.registerConstructorToBeInferred(member, this);
      }
    }
  }

  List<Initializer> get initializers;

  void _injectInvalidInitializer(Message message, int charOffset, int length,
      ExpressionGeneratorHelper helper, TreeNode parent) {
    Initializer lastInitializer = initializers.removeLast();
    assert(lastInitializer == superInitializer ||
        lastInitializer == redirectingInitializer);
    Initializer error = helper.buildInvalidInitializer(
        helper.buildProblem(message, charOffset, length));
    initializers.add(error..parent = parent);
    initializers.add(lastInitializer);
  }

  SuperInitializer? superInitializer;

  RedirectingInitializer? redirectingInitializer;

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
        inferenceResult?.applyResult(initializers, parent);
        superInitializer = initializer;

        LocatedMessage? message = helper.checkArgumentsForFunction(
            initializer.target.function,
            initializer.arguments,
            initializer.arguments.fileOffset, <TypeParameter>[]);
        if (message != null) {
          initializers.add(helper.buildInvalidInitializer(
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
          initializers.add(initializer..parent = parent);
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
      } else if (initializers.isNotEmpty) {
        // Error on all previous ones.
        for (int i = 0; i < initializers.length; i++) {
          Initializer initializer = initializers[i];
          int length = noLength;
          if (initializer is AssertInitializer) length = "assert".length;
          Initializer error = helper.buildInvalidInitializer(
              helper.buildProblem(
                  messageRedirectingConstructorWithAnotherInitializer,
                  initializer.fileOffset,
                  length));
          error.parent = parent;
          initializers[i] = error;
        }
        inferenceResult?.applyResult(initializers, parent);
        initializers.add(initializer..parent = parent);
        redirectingInitializer = initializer;
      } else {
        inferenceResult?.applyResult(initializers, parent);
        redirectingInitializer = initializer;

        LocatedMessage? message = helper.checkArgumentsForFunction(
            initializer.target.function,
            initializer.arguments,
            initializer.arguments.fileOffset, const <TypeParameter>[]);
        if (message != null) {
          initializers.add(helper.buildInvalidInitializer(
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
          initializers.add(initializer..parent = parent);
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
      inferenceResult?.applyResult(initializers, parent);
      initializers.add(initializer..parent = parent);
    }
  }

  void _buildConstructorForOutline(
      Token? beginInitializers, LookupScope declarationScope) {
    if (beginInitializers != null) {
      final LocalScope? formalParameterScope;
      if (isConst) {
        // We're going to fully build the constructor so we need scopes.
        formalParameterScope = computeFormalParameterInitializerScope(
            computeFormalParameterScope(
                computeTypeParameterScope(declarationBuilder.scope)));
      } else {
        formalParameterScope = null;
      }
      BodyBuilder bodyBuilder = libraryBuilder.loader
          .createBodyBuilderForOutlineExpression(libraryBuilder,
              createBodyBuilderContext(), declarationScope, fileUri,
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

  Procedure? get _constructorTearOff;

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    Procedure? constructorTearOff = _constructorTearOff;
    if (constructorTearOff != null) {
      if (index < constructorTearOff.function.positionalParameters.length) {
        return constructorTearOff.function.positionalParameters[index];
      } else {
        index -= constructorTearOff.function.positionalParameters.length;
        if (index < constructorTearOff.function.namedParameters.length) {
          return constructorTearOff.function.namedParameters[index];
        }
      }
    }
    return null;
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
    library.checkInitializersInFormals(formals, typeEnvironment,
        isAbstract: isAbstract, isExternal: isExternal);
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
}

class DeclaredSourceConstructorBuilder
    extends AbstractSourceConstructorBuilder {
  late final Constructor _constructor;

  @override
  late final Procedure? _constructorTearOff;

  Set<PropertyBuilder>? _initializedFields;

  DeclaredSourceConstructorBuilder? actualOrigin;

  List<DeclaredSourceConstructorBuilder>? _augmentations;

  bool _hasDefaultValueCloner = false;

  @override
  List<FormalParameterBuilder>? formals;

  final MemberName _memberName;

  @override
  String get fullNameForErrors {
    return "${declarationBuilder.name}"
        "${name.isEmpty ? '' : '.$name'}";
  }

  @override
  final int fileOffset;

  @override
  final Uri fileUri;

  @override
  final SourceLibraryBuilder libraryBuilder;

  @override
  final DeclarationBuilder declarationBuilder;

  DeclaredSourceConstructorBuilder(
      {required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required OmittedTypeBuilder returnType,
      required String name,
      required List<NominalParameterBuilder>? typeParameters,
      required this.formals,
      required this.libraryBuilder,
      required this.declarationBuilder,
      required this.fileUri,
      required int startOffset,
      required this.fileOffset,
      required int formalsOffset,
      required int endOffset,
      required Reference? constructorReference,
      required Reference? tearOffReference,
      required NameScheme nameScheme,
      String? nativeMethodName,
      required bool forAbstractClassOrEnumOrMixin,
      required Token? beginInitializers,
      bool isSynthetic = false})
      : _hasSuperInitializingFormals =
            formals?.any((formal) => formal.isSuperInitializingFormal) ?? false,
        _memberName = nameScheme.getDeclaredName(name),
        super(metadata, modifiers, returnType, name, typeParameters, formals,
            formalsOffset, nativeMethodName, beginInitializers) {
    _constructor = new Constructor(new FunctionNode(null),
        name: dummyName,
        fileUri: fileUri,
        reference: constructorReference,
        isSynthetic: isSynthetic)
      ..startFileOffset = startOffset
      ..fileOffset = fileOffset
      ..fileEndOffset = endOffset;
    nameScheme
        .getConstructorMemberName(name, isTearOff: false)
        .attachMember(_constructor);
    _constructorTearOff = createConstructorTearOffProcedure(
        nameScheme.getConstructorMemberName(name, isTearOff: true),
        libraryBuilder,
        fileUri,
        fileOffset,
        tearOffReference,
        forAbstractClassOrEnumOrMixin: forAbstractClassOrEnumOrMixin);
  }

  @override
  Builder get parent => declarationBuilder;

  @override
  bool get supportsTypeParameters => false;

  @override
  // Coverage-ignore(suite): Not run.
  Name get memberName => _memberName.name;

  @override
  SourceClassBuilder get classBuilder =>
      super.classBuilder as SourceClassBuilder;

  @override
  Member get readTarget =>
      _constructorTearOff ??
      // The case is need to ensure that the upper bound is [Member] and not
      // [GenericFunction].
      // ignore: unnecessary_cast
      _constructor as Member;

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
  Member get invokeTarget => constructor;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => constructor.reference;

  @override
  FunctionNode get function => _constructor.function;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [constructor.reference];

  @override
  List<Initializer> get initializers => _constructor.initializers;

  @override
  DeclaredSourceConstructorBuilder get origin => actualOrigin ?? this;

  // Coverage-ignore(suite): Not run.
  List<SourceConstructorBuilder>? get augmentationsForTesting => _augmentations;

  @override
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
  bool get isRedirecting {
    for (Initializer initializer in initializers) {
      if (initializer is RedirectingInitializer) {
        return true;
      }
    }
    return false;
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

  @override
  void buildOutlineNodes(BuildNodesCallback f) {
    _build();
    f(
        member: _constructor,
        tearOff: _constructorTearOff,
        kind: BuiltMemberKind.Constructor);
  }

  bool _hasBeenBuilt = false;

  void _build() {
    if (!_hasBeenBuilt) {
      buildFunction();
      _constructor.function.fileOffset = charOpenParenOffset;
      _constructor.function.fileEndOffset = _constructor.fileEndOffset;
      _constructor.function.typeParameters = const <TypeParameter>[];
      _constructor.isConst = isConst;
      _constructor.isExternal = isExternal;

      if (_constructorTearOff != null) {
        DelayedDefaultValueCloner delayedDefaultValueCloners =
            buildConstructorTearOffProcedure(
                tearOff: _constructorTearOff,
                declarationConstructor: constructor,
                implementationConstructor: _constructor,
                enclosingDeclarationTypeParameters:
                    classBuilder.cls.typeParameters,
                libraryBuilder: libraryBuilder);
        _delayedDefaultValueCloners.add(delayedDefaultValueCloners);
      }

      _hasBeenBuilt = true;
    }
    _buildFormals(_constructor);
  }

  @override
  VariableDeclaration getFormalParameter(int index) {
    if (parent is SourceEnumBuilder) {
      return formals![index + 2].variable!;
    } else {
      return super.getFormalParameter(index);
    }
  }

  ConstructorBuilder? _computeSuperTargetBuilder(
      List<Initializer>? initializers) {
    Member superTarget;
    ClassBuilder superclassBuilder;

    TypeBuilder? supertype = classBuilder.supertypeBuilder;
    TypeDeclarationBuilder? supertypeDeclaration =
        supertype?.computeUnaliasedDeclaration(isUsedAsClass: false);
    if (supertypeDeclaration is ClassBuilder) {
      superclassBuilder = supertypeDeclaration;
    } else {
      assert(libraryBuilder.loader.assertProblemReportedElsewhere(
          "DeclaredSourceConstructorBuilder._computeSuperTargetBuilder: "
          "Unaliased 'declaration' isn't a ClassBuilder.",
          expectedPhase: CompilationPhaseForProblemReporting.outline));
      return null;
    }

    if (initializers != null &&
        initializers.isNotEmpty &&
        initializers.last is SuperInitializer) {
      superTarget = (initializers.last as SuperInitializer).target;
    } else {
      MemberBuilder? memberBuilder = superclassBuilder.constructorScope
          .lookup("", fileOffset, libraryBuilder.fileUri);
      if (memberBuilder is ConstructorBuilder) {
        superTarget = memberBuilder.invokeTarget;
      } else {
        assert(libraryBuilder.loader.assertProblemReportedElsewhere(
            "DeclaredSourceConstructorBuilder._computeSuperTargetBuilder: "
            "Can't find the implied unnamed constructor in the superclass.",
            expectedPhase: CompilationPhaseForProblemReporting.bodyBuilding));
        return null;
      }
    }

    MemberBuilder? constructorBuilder =
        superclassBuilder.findConstructorOrFactory(superTarget.name.text,
            fileOffset, libraryBuilder.fileUri, libraryBuilder);
    if (constructorBuilder is ConstructorBuilder) {
      return constructorBuilder;
    } else {
      // Coverage-ignore-block(suite): Not run.
      assert(libraryBuilder.loader.assertProblemReportedElsewhere(
          "DeclaredSourceConstructorBuilder._computeSuperTargetBuilder: "
          "Can't find a constructor with name '${superTarget.name.text}' in "
          "the superclass.",
          expectedPhase: CompilationPhaseForProblemReporting.outline));
      return null;
    }
  }

  final bool _hasSuperInitializingFormals;

  final List<DelayedDefaultValueCloner> _delayedDefaultValueCloners =
      <DelayedDefaultValueCloner>[];

  @override
  void _inferSuperInitializingFormals(ClassHierarchyBase hierarchy) {
    if (_hasSuperInitializingFormals) {
      List<Initializer>? initializers;
      if (beginInitializers != null) {
        BodyBuilder bodyBuilder = libraryBuilder.loader
            .createBodyBuilderForOutlineExpression(libraryBuilder,
                createBodyBuilderContext(), declarationBuilder.scope, fileUri);
        if (isConst) {
          bodyBuilder.constantContext = ConstantContext.required;
        }
        initializers = bodyBuilder.parseInitializers(beginInitializers!,
            doFinishConstructor: false);
      }
      finalizeSuperInitializingFormals(
          hierarchy, _delayedDefaultValueCloners, initializers);
    }
  }

  void finalizeSuperInitializingFormals(
      ClassHierarchyBase hierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
      List<Initializer>? initializers) {
    if (formals == null) return;
    if (!_hasSuperInitializingFormals) return;

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
          "DeclaredSourceConstructorBuilder.finalizeSuperInitializingFormals: "
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
        classBuilder.cls, superTarget.enclosingClass!);
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
                "DeclaredSourceConstructorBuilder"
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
      if (!_hasDefaultValueCloner) {
        // If this constructor formals are part of a cyclic dependency this
        // might be called more than once.
        delayedDefaultValueCloners.add(new DelayedDefaultValueCloner(
            superTarget, constructor,
            positionalSuperParameters:
                positionalSuperParameters ?? const <int>[],
            namedSuperParameters: namedSuperParameters ?? const <String>[],
            isOutlineNode: true,
            libraryBuilder: libraryBuilder));
        if (_constructorTearOff != null) {
          delayedDefaultValueCloners.add(new DelayedDefaultValueCloner(
              superTarget, _constructorTearOff,
              positionalSuperParameters:
                  positionalSuperParameters ?? const <int>[],
              namedSuperParameters: namedSuperParameters ?? const <String>[],
              isOutlineNode: true,
              libraryBuilder: libraryBuilder));
        }
        _hasDefaultValueCloner = true;
      }
    }
  }

  bool _hasBuiltOutlines = false;

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (_hasBuiltOutlines) return;
    if (isConst && isAugmenting) {
      origin.buildOutlineExpressions(
          classHierarchy, delayedDefaultValueCloners);
    }
    super.buildOutlineExpressions(classHierarchy, delayedDefaultValueCloners);

    // For modular compilation purposes we need to include initializers
    // for const constructors into the outline. We also need to parse
    // initializers to infer types of the super-initializing parameters.
    if (isConst || _hasSuperInitializingFormals) {
      _buildConstructorForOutline(beginInitializers, classBuilder.scope);
    }
    addSuperParameterDefaultValueCloners(delayedDefaultValueCloners);
    if (isConst && isAugmenting) {
      _finishAugmentation();
    }
    beginInitializers = null;
    _hasBuiltOutlines = true;
  }

  @override
  void addSuperParameterDefaultValueCloners(
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (beginInitializers != null && constructor.initializers.isNotEmpty) {
      // If the initializers aren't built yet, we can't compute the super
      // target. The synthetic initializers should be excluded, since they can
      // be built separately from formal field initializers.
      bool allInitializersAreSynthetic = true;
      for (Initializer initializer in constructor.initializers) {
        if (!initializer.isSynthetic) {
          allInitializersAreSynthetic = false;
          break;
        }
      }
      if (!allInitializersAreSynthetic) {
        ConstructorBuilder? superTargetBuilder =
            _computeSuperTargetBuilder(constructor.initializers);
        if (superTargetBuilder is SourceConstructorBuilder) {
          superTargetBuilder
              .addSuperParameterDefaultValueCloners(delayedDefaultValueCloners);
        }
      }
    }

    delayedDefaultValueCloners.addAll(_delayedDefaultValueCloners);
    _delayedDefaultValueCloners.clear();
  }

  @override
  void buildFunction() {
    // According to the specification §9.3 the return type of a constructor
    // function is its enclosing class.
    super.buildFunction();
    Class enclosingClass = classBuilder.cls;
    List<DartType> typeParameterTypes = <DartType>[];
    for (int i = 0; i < enclosingClass.typeParameters.length; i++) {
      TypeParameter typeParameter = enclosingClass.typeParameters[i];
      typeParameterTypes
          .add(new TypeParameterType.withDefaultNullability(typeParameter));
    }
    InterfaceType type = new InterfaceType(
        enclosingClass, Nullability.nonNullable, typeParameterTypes);
    returnType.registerInferredType(type);
  }

  Constructor get constructor =>
      isAugmenting ? origin.constructor : _constructor;

  void _finishAugmentation() {
    finishConstructorAugmentation(origin.constructor, _constructor);

    if (_constructorTearOff != null) {
      finishProcedureAugmentation(
          origin._constructorTearOff!, _constructorTearOff);
    }
  }

  @override
  int buildBodyNodes(BuildNodesCallback f) {
    if (!isAugmenting) return 0;
    _finishAugmentation();
    return 1;
  }

  @override
  void becomeNative(SourceLoader loader) {
    _constructor.isExternal = true;
    super.becomeNative(loader);
  }

  @override
  void applyAugmentation(Builder augmentation) {
    if (augmentation is DeclaredSourceConstructorBuilder) {
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
  void prepareInitializers() {
    // For const constructors we parse initializers already at the outlining
    // stage, there is no easy way to make body building stage skip initializer
    // parsing, so we simply clear parsed initializers and rebuild them
    // again.
    // For when doing an experimental incremental compilation they are also
    // potentially done more than once (because it rebuilds the bodies of an old
    // compile), and so we also clear them.
    // Note: this method clears both initializers from the target Kernel node
    // and internal state associated with parsing initializers.
    _constructor.initializers = [];
    redirectingInitializer = null;
    superInitializer = null;
  }

  @override
  void prependInitializer(Initializer initializer) {
    initializer.parent = constructor;
    constructor.initializers.insert(0, initializer);
  }

  @override
  void registerInitializedField(PropertyBuilder fieldBuilder) {
    if (isAugmenting) {
      origin.registerInitializedField(fieldBuilder);
    } else {
      (_initializedFields ??= {}).add(fieldBuilder);
    }
  }

  @override
  Set<PropertyBuilder>? takeInitializedFields() {
    Set<PropertyBuilder>? result = _initializedFields;
    _initializedFields = null;
    return result;
  }

  void ensureGrowableFormals() {
    if (formals != null) {
      formals = new List<FormalParameterBuilder>.of(formals!, growable: true);
    } else {
      formals = <FormalParameterBuilder>[];
    }
  }

  @override
  void checkTypes(SourceLibraryBuilder library, NameSpace nameSpace,
      TypeEnvironment typeEnvironment) {
    super.checkTypes(library, nameSpace, typeEnvironment);
    List<DeclaredSourceConstructorBuilder>? augmentations = _augmentations;
    if (augmentations != null) {
      for (DeclaredSourceConstructorBuilder augmentation in augmentations) {
        augmentation.checkTypes(library, nameSpace, typeEnvironment);
      }
    }
  }

  @override
  DartType substituteFieldType(DartType fieldType) {
    // Nothing to do. Regular generative constructors don't have their own
    // type parameters.
    return fieldType;
  }

  @override
  BodyBuilderContext createBodyBuilderContext() {
    return new ConstructorBodyBuilderContext(this, constructor);
  }

  // TODO(johnniwinther): Add annotations to tear-offs.
  @override
  Iterable<Annotatable> get annotatables => [constructor];

  @override
  bool get isAugmented {
    if (isAugmenting) {
      return origin._augmentations!.last != this;
    } else {
      return _augmentations != null;
    }
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

class SourceExtensionTypeConstructorBuilder
    extends AbstractSourceConstructorBuilder {
  @override
  final SourceLibraryBuilder libraryBuilder;

  @override
  final SourceExtensionTypeDeclarationBuilder declarationBuilder;

  late final Procedure _constructor;

  @override
  late final Procedure? _constructorTearOff;

  Set<PropertyBuilder>? _initializedFields;

  @override
  List<Initializer> initializers = [];

  final MemberName _memberName;

  DelayedDefaultValueCloner? _delayedDefaultValueCloner;

  @override
  final int fileOffset;

  @override
  final Uri fileUri;

  SourceExtensionTypeConstructorBuilder(
      {required List<MetadataBuilder>? metadata,
      required Modifiers modifiers,
      required OmittedTypeBuilder returnType,
      required String name,
      required List<NominalParameterBuilder>? typeParameters,
      required List<FormalParameterBuilder>? formals,
      required this.libraryBuilder,
      required this.declarationBuilder,
      required this.fileUri,
      required int startOffset,
      required this.fileOffset,
      required int formalsOffset,
      required int endOffset,
      required Reference? constructorReference,
      required Reference? tearOffReference,
      required NameScheme nameScheme,
      String? nativeMethodName,
      required bool forAbstractClassOrEnumOrMixin,
      required Token? beginInitializers})
      : _memberName = nameScheme.getDeclaredName(name),
        super(metadata, modifiers, returnType, name, typeParameters, formals,
            formalsOffset, nativeMethodName, beginInitializers) {
    _constructor = new Procedure(
        dummyName, ProcedureKind.Method, new FunctionNode(null),
        fileUri: fileUri, reference: constructorReference)
      ..fileOffset = fileOffset
      ..fileEndOffset = endOffset;
    nameScheme
        .getConstructorMemberName(name, isTearOff: false)
        .attachMember(_constructor);
    _constructorTearOff = createConstructorTearOffProcedure(
        nameScheme.getConstructorMemberName(name, isTearOff: true),
        libraryBuilder,
        fileUri,
        fileOffset,
        tearOffReference,
        forAbstractClassOrEnumOrMixin: forAbstractClassOrEnumOrMixin,
        forceCreateLowering: true)
      ?..isExtensionTypeMember = true;
  }

  @override
  Builder get parent => declarationBuilder;

  @override
  // Coverage-ignore(suite): Not run.
  Name get memberName => _memberName.name;

  @override
  Member get readTarget =>
      _constructorTearOff ?? // Coverage-ignore(suite): Not run.
      _constructor;

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
  Member get invokeTarget => _constructor;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get invokeTargetReference => _constructor.reference;

  @override
  FunctionNode get function => _constructor.function;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedMemberReferences => [_constructor.reference];

  @override
  // Coverage-ignore(suite): Not run.
  void addSuperParameterDefaultValueCloners(
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {}

  @override
  void _inferSuperInitializingFormals(ClassHierarchyBase hierarchy) {
    if (formals != null) {
      for (FormalParameterBuilder formal in formals!) {
        if (formal.isSuperInitializingFormal) {
          TypeBuilder formalTypeBuilder = formal.type;
          if (formalTypeBuilder is InferableTypeBuilder) {
            formalTypeBuilder.registerType(const InvalidType());
          }
        }
      }
    }
  }

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    super.buildOutlineExpressions(classHierarchy, delayedDefaultValueCloners);

    if (isConst) {
      // For modular compilation purposes we need to include initializers
      // for const constructors into the outline.
      LookupScope typeParameterScope =
          computeTypeParameterScope(declarationBuilder.scope);
      _buildConstructorForOutline(beginInitializers, typeParameterScope);
      _buildBody();
    }
    beginInitializers = null;

    if (_delayedDefaultValueCloner != null) {
      delayedDefaultValueCloners.add(_delayedDefaultValueCloner!);
    }
  }

  bool _hasBuiltBody = false;

  void _buildBody() {
    if (_hasBuiltBody) {
      return;
    }
    if (!isExternal) {
      VariableDeclaration thisVariable = this.thisVariable!;
      List<Statement> statements = [thisVariable];
      ExtensionTypeInitializerToStatementConverter visitor =
          new ExtensionTypeInitializerToStatementConverter(
              statements, thisVariable);
      for (Initializer initializer in initializers) {
        initializer.accept(visitor);
      }
      if (body != null && body is! EmptyStatement) {
        statements.add(body!);
      }
      statements.add(new ReturnStatement(new VariableGet(thisVariable)));
      body = new Block(statements);
    }
    _hasBuiltBody = true;
  }

  @override
  int buildBodyNodes(BuildNodesCallback f) {
    _buildBody();
    // TODO(johnniwinther): Support augmentation.
    return 0;
  }

  @override
  void buildOutlineNodes(BuildNodesCallback f) {
    _build();
    f(
        member: _constructor,
        tearOff: _constructorTearOff,
        kind: BuiltMemberKind.ExtensionTypeConstructor);
  }

  bool _hasBeenBuilt = false;

  @override
  void buildFunction() {
    // According to the specification §9.3 the return type of a constructor
    // function is its enclosing class.
    super.buildFunction();
    ExtensionTypeDeclaration extensionTypeDeclaration =
        declarationBuilder.extensionTypeDeclaration;
    List<DartType> typeParameterTypes = <DartType>[];
    for (int i = 0; i < function.typeParameters.length; i++) {
      TypeParameter typeParameter = function.typeParameters[i];
      typeParameterTypes
          .add(new TypeParameterType.withDefaultNullability(typeParameter));
    }
    ExtensionType type = new ExtensionType(
        extensionTypeDeclaration, Nullability.nonNullable, typeParameterTypes);
    returnType.registerInferredType(type);
  }

  void _build() {
    if (!_hasBeenBuilt) {
      buildFunction();
      _constructor.function.fileOffset = charOpenParenOffset;
      _constructor.function.fileEndOffset = _constructor.fileEndOffset;
      _constructor.isConst = isConst;
      _constructor.isExternal = isExternal;
      _constructor.isStatic = true;
      _constructor.isExtensionTypeMember = true;

      if (_constructorTearOff != null) {
        _delayedDefaultValueCloner = buildConstructorTearOffProcedure(
            tearOff: _constructorTearOff,
            declarationConstructor: _constructor,
            implementationConstructor: _constructor,
            libraryBuilder: libraryBuilder);
      }

      _hasBeenBuilt = true;
    }
    _buildFormals(_constructor);
  }

  @override
  void prepareInitializers() {
    // For const constructors we parse initializers already at the outlining
    // stage, there is no easy way to make body building stage skip initializer
    // parsing, so we simply clear parsed initializers and rebuild them
    // again.
    // For when doing an experimental incremental compilation they are also
    // potentially done more than once (because it rebuilds the bodies of an old
    // compile), and so we also clear them.
    // Note: this method clears both initializers from the target Kernel node
    // and internal state associated with parsing initializers.
    initializers = [];
    redirectingInitializer = null;
    superInitializer = null;
  }

  @override
  void prependInitializer(Initializer initializer) {
    initializers.insert(0, initializer);
  }

  @override
  void registerInitializedField(PropertyBuilder fieldBuilder) {
    (_initializedFields ??= {}).add(fieldBuilder);
  }

  @override
  Set<PropertyBuilder>? takeInitializedFields() {
    Set<PropertyBuilder>? result = _initializedFields;
    _initializedFields = null;
    return result;
  }

  @override
  bool get isEffectivelyExternal => isExternal;

  @override
  bool get isRedirecting {
    for (Initializer initializer in initializers) {
      if (initializer is ExtensionTypeRedirectingInitializer) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get isEffectivelyRedirecting => isRedirecting;

  Substitution? _substitutionCache;

  Substitution get _substitution {
    if (typeParameters != null) {
      assert(
          declarationBuilder.typeParameters!.length == typeParameters?.length);
      _substitutionCache = Substitution.fromPairs(
          declarationBuilder.extensionTypeDeclaration.typeParameters,
          new List<DartType>.generate(
              declarationBuilder.typeParameters!.length,
              (int index) => new TypeParameterType.withDefaultNullability(
                  function.typeParameters[index])));
    } else {
      _substitutionCache = Substitution.empty;
    }
    return _substitutionCache!;
  }

  @override
  DartType substituteFieldType(DartType fieldType) {
    return _substitution.substituteType(fieldType);
  }

  @override
  BodyBuilderContext createBodyBuilderContext() {
    return new ExtensionTypeConstructorBodyBuilderContext(this, _constructor);
  }

  // TODO(johnniwinther): Add annotations to tear-offs.
  @override
  Iterable<Annotatable> get annotatables => [_constructor];

  @override
  bool get isAugmented => false;
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
