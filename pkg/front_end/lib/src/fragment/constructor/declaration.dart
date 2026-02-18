// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../../base/extension_scope.dart';
import '../../base/local_scope.dart';
import '../../base/lookup_result.dart';
import '../../base/messages.dart';
import '../../base/name_space.dart';
import '../../base/scope.dart';
import '../../builder/constructor_builder.dart';
import '../../builder/declaration_builders.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/function_signature.dart';
import '../../builder/member_builder.dart';
import '../../builder/metadata_builder.dart';
import '../../builder/omitted_type_builder.dart';
import '../../builder/type_builder.dart';
import '../../builder/variable_builder.dart';
import '../../kernel/body_builder_context.dart';
import '../../kernel/internal_ast.dart';
import '../../kernel/kernel_helper.dart';
import '../../kernel/resolver.dart';
import '../../kernel/type_algorithms.dart';
import '../../source/check_helper.dart';
import '../../source/name_scheme.dart';
import '../../source/source_class_builder.dart';
import '../../source/source_constructor_builder.dart';
import '../../source/source_function_builder.dart';
import '../../source/source_library_builder.dart';
import '../../source/source_loader.dart';
import '../../source/source_member_builder.dart';
import '../../source/source_type_parameter_builder.dart';
import '../../source/type_parameter_factory.dart';
import '../fragment.dart';
import 'encoding.dart';

/// Interface for the constructor declaration aspect of a
/// [SourceConstructorBuilder].
///
/// If a constructor is augmented, it will have multiple
/// [ConstructorDeclaration]s on a single [SourceConstructorBuilder].
abstract class ConstructorDeclaration {
  Uri get fileUri;

  List<MetadataBuilder>? get metadata;

  FunctionSignature get signature;

  bool get hasParameters;

  List<Initializer> get initializers;

  void registerInitializers(List<Initializer> initializers);

  bool get isPrimaryConstructor;

  /// If this constructor is a primary constructor, returns the parameters
  /// available in the initializer scope. Otherwise returns `null`.
  List<FormalParameterBuilder>?
  get primaryConstructorInitializerScopeParameters;

  void createEncoding({
    required ProblemReporting problemReporting,
    required SourceLoader loader,
    required DeclarationBuilder declarationBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required TypeParameterFactory typeParameterFactory,
    required ConstructorEncodingStrategy encodingStrategy,
  });

  void buildOutlineNodes(
    BuildNodesCallback f, {
    required SourceConstructorBuilder constructorBuilder,
    required SourceLibraryBuilder libraryBuilder,
    required NameScheme nameScheme,
    required ConstructorReferences? constructorReferences,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  });

  void buildOutlineExpressions({
    required Iterable<Annotatable> annotatables,
    required Uri annotatablesFileUri,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required ClassHierarchy classHierarchy,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  });

  void checkTypes(
    ProblemReporting problemReporting,
    NameSpace nameSpace,
    TypeEnvironment typeEnvironment,
  );

  int computeDefaultTypes(
    ComputeDefaultTypeContext context, {
    required bool inErrorRecovery,
  });

  void prepareInitializers();

  void prependInitializer(Initializer initializer);

  Substitution computeFieldTypeSubstitution(
    DeclarationBuilder declarationBuilder,
  );

  void buildBody();

  bool get isExternal;

  bool get isRedirecting;

  void addSuperParameterDefaultValueCloners(
    SourceLibraryBuilder libraryBuilder,
    DeclarationBuilder declarationBuilder,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  );

  void inferFormalTypes(
    SourceLibraryBuilder libraryBuilder,
    DeclarationBuilder declarationBuilder,
    SourceConstructorBuilder constructorBuilder,
    ClassHierarchyBase hierarchy,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  );

  /// Mark the constructor as erroneous.
  ///
  /// This is used during the compilation phase to set the appropriate flag on
  /// the input AST node. The flag helps the verifier to skip apriori erroneous
  /// members and to avoid reporting cascading errors.
  void markAsErroneous();
}

mixin _ConstructorDeclarationMixin
    implements ConstructorDeclaration, ConstructorFragmentDeclaration {
  bool get _hasSuperInitializingFormals;

  ExtensionScope get _extensionScope;

  LookupScope get _typeParameterScope;

  abstract Token? _beginInitializers;

  List<SourceNominalParameterBuilder>? get _typeParameters;

  late final List<FormalParameterBuilder>? _initializerScopeParameters =
      _computeInitializerScopeParameters();

  @override
  bool get hasParameters => formals != null;

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
    Map<String, VariableBuilder> local = {};
    for (FormalParameterBuilder formal in _initializerScopeParameters!) {
      local[formal.name] = formal;
    }
    return parent.createNestedFixedScope(
      kind: LocalScopeKind.initializers,
      local: local,
    );
  }

  List<FormalParameterBuilder>? _computeInitializerScopeParameters() {
    if (formals == null) return null;
    List<FormalParameterBuilder> list = [];
    for (FormalParameterBuilder formal in formals!) {
      // Wildcard initializing formal parameters do not introduce a local
      // variable in the initializer list.
      if (formal.isWildcard) continue;

      list.add(formal.forFormalParameterInitializerScope());
    }
    return list;
  }

  @override
  List<FormalParameterBuilder>?
  get primaryConstructorInitializerScopeParameters {
    assert(
      isPrimaryConstructor,
      "Unexpected call to "
      "$runtimeType.primaryConstructorInitializerScopeParameters "
      "on non-primary constructor.",
    );
    if (isPrimaryConstructor) {
      return _initializerScopeParameters;
    }
    return null;
  }

  @override
  bool get isPrimaryConstructor => false;

  @override
  void inferFormalTypes(
    SourceLibraryBuilder libraryBuilder,
    DeclarationBuilder declarationBuilder,
    SourceConstructorBuilder constructorBuilder,
    ClassHierarchyBase hierarchy,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {
    if (formals != null) {
      libraryBuilder.loader.withUriForCrashReporting(fileUri, fileOffset, () {
        for (FormalParameterBuilder formal in formals!) {
          if (formal.type is InferableTypeBuilder) {
            if (formal.isInitializingFormal) {
              formal.finalizeInitializingFormal(
                declarationBuilder,
                constructorBuilder,
                hierarchy,
              );
            }
          }
        }
        _inferSuperInitializingFormals(
          libraryBuilder,
          declarationBuilder,
          constructorBuilder,
          hierarchy,
          delayedDefaultValueCloners,
        );
      });
    }
  }

  void _inferSuperInitializingFormals(
    SourceLibraryBuilder libraryBuilder,
    DeclarationBuilder declarationBuilder,
    SourceConstructorBuilder constructorBuilder,
    ClassHierarchyBase hierarchy,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {
    if (_hasSuperInitializingFormals) {
      List<Initializer>? initializers;
      Token? beginInitializers = this._beginInitializers;
      if (beginInitializers != null) {
        Resolver resolver = libraryBuilder.loader.createResolver();
        initializers = resolver.buildInitializersUnfinished(
          libraryBuilder: libraryBuilder,
          bodyBuilderContext: createBodyBuilderContext(constructorBuilder),
          extensionScope: _extensionScope,
          typeParameterScope: _typeParameterScope,
          fileUri: fileUri,
          beginInitializers: beginInitializers,
          isConst: isConst,
        );
      }
      _finalizeSuperInitializingFormals(
        libraryBuilder,
        declarationBuilder,
        hierarchy,
        delayedDefaultValueCloners,
        initializers,
      );
    }
  }

  void _finalizeSuperInitializingFormals(
    SourceLibraryBuilder libraryBuilder,
    DeclarationBuilder declarationBuilder,
    ClassHierarchyBase hierarchy,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
    List<Initializer>? initializers,
  ) {
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

    ConstructorBuilder? superTargetBuilder = _computeSuperTargetBuilder(
      libraryBuilder,
      declarationBuilder,
      initializers,
    );

    if (superTargetBuilder is SourceConstructorBuilder) {
      superTargetBuilder.inferFormalTypes(hierarchy);
    }

    Member superTarget;
    FunctionSignature? superConstructorSignature;
    if (superTargetBuilder != null) {
      superTarget = superTargetBuilder.invokeTarget;
      superConstructorSignature = superTargetBuilder.signature;
    } else {
      assert(
        libraryBuilder.loader.assertProblemReportedElsewhere(
          "${this.runtimeType}.finalizeSuperInitializingFormals: "
          "Can't compute super target.",
          expectedPhase: CompilationPhaseForProblemReporting.bodyBuilding,
        ),
      );
      // Perform a simple recovery.
      return performRecoveryForErroneousCase();
    }
    SourceClassBuilder classBuilder = declarationBuilder as SourceClassBuilder;

    List<ParameterInfo> positionalSuperInfo =
        superConstructorSignature.positionalParameters;
    Map<String, ParameterInfo> namedSuperInfo =
        superConstructorSignature.namedParameters;

    int superInitializingFormalIndex = -1;
    List<int?>? positionalSuperParameters;
    List<String>? namedSuperParameters;

    Supertype? supertype = hierarchy.getClassAsInstanceOf(
      classBuilder.cls,
      superTarget.enclosingClass!,
    );
    assert(supertype != null);
    Map<TypeParameter, DartType> substitution =
        new Map<TypeParameter, DartType>.fromIterables(
          supertype!.classNode.typeParameters,
          supertype.typeArguments,
        );

    for (int formalIndex = 0; formalIndex < formals!.length; formalIndex++) {
      FormalParameterBuilder formal = formals![formalIndex];
      if (formal.isSuperInitializingFormal) {
        superInitializingFormalIndex++;
        bool hasImmediatelyDeclaredInitializer =
            formal.hasImmediatelyDeclaredInitializer;

        DartType? correspondingSuperFormalType;
        if (formal.isPositional) {
          if (superInitializingFormalIndex < positionalSuperInfo.length) {
            ParameterInfo parameterInfo =
                positionalSuperInfo[superInitializingFormalIndex];
            if (formal.isOptional) {
              formal.hasDeclaredInitializer =
                  hasImmediatelyDeclaredInitializer ||
                  parameterInfo.hasDeclaredInitializer;
            }
            correspondingSuperFormalType = parameterInfo.type;
            if (!hasImmediatelyDeclaredInitializer &&
                !formal.isRequiredPositional) {
              (positionalSuperParameters ??= <int?>[]).add(formalIndex);
            } else {
              (positionalSuperParameters ??= <int?>[]).add(null);
            }
          } else {
            assert(
              libraryBuilder.loader.assertProblemReportedElsewhere(
                "${this.runtimeType}"
                ".finalizeSuperInitializingFormals: "
                "Super initializer count is greater than the count of "
                "positional formals in the super constructor.",
                expectedPhase: CompilationPhaseForProblemReporting.bodyBuilding,
              ),
            );
          }
        } else {
          ParameterInfo? parameterInfo = namedSuperInfo[formal.name];
          if (parameterInfo != null) {
            if (formal.isOptional) {
              formal.hasDeclaredInitializer =
                  hasImmediatelyDeclaredInitializer ||
                  parameterInfo.hasDeclaredInitializer;
            }
            correspondingSuperFormalType = parameterInfo.type;
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
      _addSuperParameterDefaultValueCloners(
        libraryBuilder: libraryBuilder,
        delayedDefaultValueCloners: delayedDefaultValueCloners,
        superTarget: superTarget,
        positionalSuperParameters: positionalSuperParameters,
        namedSuperParameters: namedSuperParameters,
      );
    }
  }

  void _addSuperParameterDefaultValueCloners({
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
    required Member superTarget,
    required List<int?>? positionalSuperParameters,
    required List<String>? namedSuperParameters,
    required SourceLibraryBuilder libraryBuilder,
  });

  ConstructorBuilder? _computeSuperTargetBuilder(
    SourceLibraryBuilder libraryBuilder,
    DeclarationBuilder declarationBuilder,
    List<Initializer>? initializers,
  ) {
    if (declarationBuilder is! SourceClassBuilder) {
      return null;
    }
    SourceClassBuilder classBuilder = declarationBuilder;

    Member superTarget;
    ClassBuilder superclassBuilder;

    TypeBuilder? supertype = classBuilder.supertypeBuilder;
    TypeDeclarationBuilder? supertypeDeclaration = supertype
        ?.computeUnaliasedDeclaration(isUsedAsClass: false);
    if (supertypeDeclaration is ClassBuilder) {
      superclassBuilder = supertypeDeclaration;
    } else {
      assert(
        libraryBuilder.loader.assertProblemReportedElsewhere(
          "${this.runtimeType}._computeSuperTargetBuilder: "
          "Unaliased 'declaration' isn't a ClassBuilder.",
          expectedPhase: CompilationPhaseForProblemReporting.outline,
        ),
      );
      return null;
    }

    Initializer? lastInitializer =
        initializers != null && initializers.isNotEmpty
        ? initializers.last
        : null;
    // TODO(johnniwinther): This method is currently called with initializers
    // in an uninferred state for non-const constructors with super parameters
    // and in an inferred state for const constructors with super parameters.
    // Avoid this inconsistency by calling this before inference.
    if (lastInitializer is SuperInitializer) {
      superTarget = lastInitializer.target;
    } else if (lastInitializer is InternalSuperInitializer) {
      superTarget = lastInitializer.target;
    } else {
      MemberLookupResult? result = superclassBuilder.findConstructorOrFactory(
        "",
        libraryBuilder,
      );
      MemberBuilder? memberBuilder = result?.getable;
      if (result != null &&
          !result.isInvalidLookup &&
          memberBuilder is ConstructorBuilder) {
        superTarget = memberBuilder.invokeTarget;
      } else {
        assert(
          libraryBuilder.loader.assertProblemReportedElsewhere(
            "${this.runtimeType}._computeSuperTargetBuilder: "
            "Can't find the implied unnamed constructor in the superclass.",
            expectedPhase: CompilationPhaseForProblemReporting.bodyBuilding,
          ),
        );
        return null;
      }
    }

    MemberLookupResult? result = superclassBuilder.findConstructorOrFactory(
      superTarget.name.text,
      libraryBuilder,
    );
    MemberBuilder? constructorBuilder = result?.getable;
    if (result != null &&
        !result.isInvalidLookup &&
        constructorBuilder is ConstructorBuilder) {
      return constructorBuilder;
    } else {
      // Coverage-ignore-block(suite): Not run.
      assert(
        libraryBuilder.loader.assertProblemReportedElsewhere(
          "${this.runtimeType}._computeSuperTargetBuilder: "
          "Can't find a constructor with name '${superTarget.name.text}' in "
          "the superclass.",
          expectedPhase: CompilationPhaseForProblemReporting.outline,
        ),
      );
      return null;
    }
  }

  @override
  void addSuperParameterDefaultValueCloners(
    SourceLibraryBuilder libraryBuilder,
    DeclarationBuilder declarationBuilder,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {
    if (_beginInitializers != null && initializers.isNotEmpty) {
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
        ConstructorBuilder? superTargetBuilder = _computeSuperTargetBuilder(
          libraryBuilder,
          declarationBuilder,
          initializers,
        );
        if (superTargetBuilder is SourceConstructorBuilder) {
          superTargetBuilder.addSuperParameterDefaultValueCloners(
            delayedDefaultValueCloners,
          );
        }
      }
    }
  }

  @override
  LocalScope computeFormalParameterScope(LookupScope parent) {
    if (formals == null) return new FormalParameterScope(parent: parent);
    Map<String, VariableBuilder> local = {};
    for (FormalParameterBuilder formal in formals!) {
      if (formal.isWildcard) {
        continue;
      }
      if (!formal.isInitializingFormal && !formal.isSuperInitializingFormal) {
        local[formal.name] = formal;
      }
    }
    return new FormalParameterScope(local: local, parent: parent);
  }

  void _buildConstructorForOutlineExpressions(
    SourceLibraryBuilder libraryBuilder,
    SourceConstructorBuilder constructorBuilder,
  ) {
    if (_beginInitializers != null) {
      final LocalScope? formalParameterScope;
      if (isConst) {
        // We're going to fully build the constructor so we need scopes.
        formalParameterScope = computeFormalParameterInitializerScope(
          computeFormalParameterScope(_typeParameterScope),
        );
      } else {
        formalParameterScope = null;
      }
      Resolver resolver = libraryBuilder.loader.createResolver();
      resolver.buildInitializers(
        libraryBuilder: libraryBuilder,
        constructorBuilder: constructorBuilder,
        extensionScope: _extensionScope,
        typeParameterScope: _typeParameterScope,
        formalParameterScope: formalParameterScope,
        bodyBuilderContext: createBodyBuilderContext(constructorBuilder),
        fileUri: fileUri,
        beginInitializers: _beginInitializers!,
        isConst: isConst,
      );
    }
  }

  void _buildOutlineExpressions(
    SourceLibraryBuilder libraryBuilder,
    SourceConstructorBuilder constructorBuilder,
  ) {
    if (isConst || _hasSuperInitializingFormals) {
      // For modular compilation purposes we need to include initializers
      // for const constructors into the outline.
      _buildConstructorForOutlineExpressions(
        libraryBuilder,
        constructorBuilder,
      );
      buildBody();
    }
  }

  void _buildMetadataForOutlineExpressions({
    required Iterable<Annotatable> annotatables,
    required Uri annotatablesFileUri,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
  });

  void _buildTypeParametersAndFormalsForOutlineExpressions({
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
  });

  @override
  void buildOutlineExpressions({
    required Iterable<Annotatable> annotatables,
    required Uri annotatablesFileUri,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required ClassHierarchy classHierarchy,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  }) {
    formals?.infer(classHierarchy);
    BodyBuilderContext bodyBuilderContext = createBodyBuilderContext(
      constructorBuilder,
    );
    _buildMetadataForOutlineExpressions(
      annotatables: annotatables,
      annotatablesFileUri: annotatablesFileUri,
      libraryBuilder: libraryBuilder,
      declarationBuilder: declarationBuilder,
      constructorBuilder: constructorBuilder,
      bodyBuilderContext: bodyBuilderContext,
      classHierarchy: classHierarchy,
    );
    _buildTypeParametersAndFormalsForOutlineExpressions(
      libraryBuilder: libraryBuilder,
      declarationBuilder: declarationBuilder,
      constructorBuilder: constructorBuilder,
      bodyBuilderContext: bodyBuilderContext,
      classHierarchy: classHierarchy,
    );
    _buildOutlineExpressions(libraryBuilder, constructorBuilder);
    addSuperParameterDefaultValueCloners(
      libraryBuilder,
      declarationBuilder,
      delayedDefaultValueCloners,
    );
    _beginInitializers = null;
  }

  @override
  void checkTypes(
    ProblemReporting problemReporting,
    NameSpace nameSpace,
    TypeEnvironment typeEnvironment,
  ) {
    problemReporting.checkInitializersInFormals(
      formals: formals,
      typeEnvironment: typeEnvironment,
      isAbstract: false,
      isExternal: isExternal,
    );
  }

  @override
  int computeDefaultTypes(
    ComputeDefaultTypeContext context, {
    required bool inErrorRecovery,
  }) {
    int count = context.computeDefaultTypesForVariables(
      _typeParameters,
      // Type parameters are inherited from the enclosing declaration, so if
      // it has issues, so do the constructors.
      inErrorRecovery: inErrorRecovery,
    );
    context.reportGenericFunctionTypesForFormals(formals);
    return count;
  }
}

mixin _ConstructorEncodingMixin
    implements
        ConstructorDeclaration,
        _ConstructorDeclarationMixin,
        ConstructorFragmentDeclaration {
  ConstructorEncoding get _encoding;

  @override
  void registerInitializers(List<Initializer> initializers) {
    _encoding.registerInitializers(initializers);
  }

  String? get _nativeMethodName;

  @override
  late final bool _hasSuperInitializingFormals =
      formals?.any((formal) => formal.isSuperInitializingFormal) ?? false;

  @override
  FunctionSignature get signature => _encoding.signature;

  @override
  List<Initializer> get initializers => _encoding.initializers;

  @override
  bool get isRedirecting => _encoding.isRedirecting;

  @override
  void prepareInitializers() {
    _encoding.prepareInitializers();
  }

  @override
  void prependInitializer(Initializer initializer) {
    _encoding.prependInitializer(initializer);
  }

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    return _encoding.getTearOffParameter(index);
  }

  @override
  void markAsErroneous() {
    _encoding.markAsErroneous();
  }

  @override
  VariableDeclaration? get thisVariable => _encoding.thisVariable;

  @override
  List<TypeParameter>? get thisTypeParameters => _encoding.thisTypeParameters;

  @override
  void registerFunctionBody(Statement? body, Scope? scope) {
    _encoding.registerFunctionBody(body: body, scope: scope);
  }

  @override
  void registerNoBodyConstructor() {
    _encoding.registerNoBodyConstructor();
  }

  @override
  void buildBody() {
    _encoding.buildBody();
  }

  @override
  void _addSuperParameterDefaultValueCloners({
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
    required Member superTarget,
    required List<int?>? positionalSuperParameters,
    required List<String>? namedSuperParameters,
    required SourceLibraryBuilder libraryBuilder,
  }) {
    _encoding.addSuperParameterDefaultValueCloners(
      delayedDefaultValueCloners: delayedDefaultValueCloners,
      superTarget: superTarget,
      positionalSuperParameters: positionalSuperParameters,
      namedSuperParameters: namedSuperParameters,
      libraryBuilder: libraryBuilder,
    );
  }

  @override
  Substitution computeFieldTypeSubstitution(
    DeclarationBuilder declarationBuilder,
  ) {
    return _encoding.computeFieldTypeSubstitution(
      declarationBuilder,
      _typeParameters,
    );
  }

  @override
  void becomeNative(SourceLoader loader) {
    _encoding.becomeNative(loader, _nativeMethodName!);
  }
}

mixin _RegularConstructorDeclarationMixin
    implements
        _ConstructorDeclarationMixin,
        _ConstructorEncodingMixin,
        InferredTypeListener {
  void _buildTypeParametersAndFormals({
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
    required ExtensionScope extensionScope,
    required LookupScope typeParameterScope,
  }) {
    if (_typeParameters != null) {
      for (int i = 0; i < _typeParameters!.length; i++) {
        _typeParameters![i].buildOutlineExpressions(
          libraryBuilder,
          bodyBuilderContext,
          classHierarchy,
        );
      }
    }

    if (formals != null) {
      for (FormalParameterBuilder formal in formals!) {
        formal.buildOutlineExpressions(
          libraryBuilder: libraryBuilder,
          declarationBuilder: declarationBuilder,
          memberBuilder: constructorBuilder,
          extensionScope: extensionScope,
          scope: typeParameterScope,
        );
      }
    }
  }

  @override
  BodyBuilderContext createBodyBuilderContext(
    SourceConstructorBuilder constructorBuilder,
  ) {
    return _encoding.createBodyBuilderContext(constructorBuilder, this);
  }

  @override
  void onInferredType(DartType type) {
    _encoding.registerInferredReturnType(type);
  }

  void _registerInferable(Inferable inferable) {
    returnType.registerInferredTypeListener(this);
    if (formals != null) {
      for (FormalParameterBuilder formal in formals!) {
        if (formal.isInitializingFormal || formal.isSuperInitializingFormal) {
          formal.type.registerInferable(inferable);
        }
      }
    }
  }
}

class RegularConstructorDeclaration
    with
        _ConstructorDeclarationMixin,
        _ConstructorEncodingMixin,
        _RegularConstructorDeclarationMixin
    implements ConstructorDeclaration, ConstructorFragmentDeclaration {
  final ConstructorFragment _fragment;

  @override
  late final ConstructorEncoding _encoding;

  late final List<FormalParameterBuilder>? _formals;

  @override
  late final List<SourceNominalParameterBuilder>? _typeParameters;

  @override
  Token? _beginInitializers;

  RegularConstructorDeclaration(this._fragment)
    : _beginInitializers = _fragment.beginInitializers {
    _fragment.declaration = this;
  }

  @override
  String? get _nativeMethodName => _fragment.nativeMethodName;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isNative => _fragment.nativeMethodName != null;

  @override
  ExtensionScope get _extensionScope =>
      _fragment.enclosingCompilationUnit.extensionScope;

  @override
  LookupScope get _typeParameterScope => _fragment.typeParameterScope;

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  OmittedTypeBuilder get returnType => _fragment.returnType;

  @override
  bool get isConst => _fragment.modifiers.isConst;

  @override
  bool get isExternal => _fragment.modifiers.isExternal;

  @override
  int get fileOffset => _fragment.fullNameOffset;

  @override
  Uri get fileUri => _fragment.fileUri;

  @override
  void createEncoding({
    required ProblemReporting problemReporting,
    required SourceLoader loader,
    required DeclarationBuilder declarationBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required TypeParameterFactory typeParameterFactory,
    required ConstructorEncodingStrategy encodingStrategy,
  }) {
    _fragment.builder = constructorBuilder;
    _typeParameters = encodingStrategy.createTypeParameters(
      declarationBuilder: declarationBuilder,
      declarationTypeParameterFragments:
          _fragment.enclosingDeclaration.typeParameters,
      typeParameters: typeParameterFactory.createNominalParameterBuilders(
        _fragment.typeParameters,
      ),
      typeParameterFactory: typeParameterFactory,
    );
    _fragment.typeParameterNameSpace.addTypeParameters(
      problemReporting,
      _typeParameters,
      ownerName: _fragment.name,
      allowNameConflict: true,
    );
    _formals = encodingStrategy.createFormals(
      loader: loader,
      formals: _fragment.formals,
      fileUri: _fragment.fileUri,
      fileOffset: _fragment.fullNameOffset,
    );
    _encoding = encodingStrategy.createEncoding(
      isExternal: _fragment.modifiers.isExternal,
    );
    _registerInferable(constructorBuilder);
  }

  @override
  List<FormalParameterBuilder>? get formals => _formals;

  @override
  void buildOutlineNodes(
    BuildNodesCallback f, {
    required SourceConstructorBuilder constructorBuilder,
    required SourceLibraryBuilder libraryBuilder,
    required NameScheme nameScheme,
    required ConstructorReferences? constructorReferences,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  }) {
    _encoding.buildOutlineNodes(
      f,
      constructorBuilder: constructorBuilder,
      libraryBuilder: libraryBuilder,
      declarationBuilder: constructorBuilder.declarationBuilder,
      name: _fragment.name,
      nameScheme: nameScheme,
      constructorReferences: constructorReferences,
      fileUri: _fragment.fileUri,
      startOffset: _fragment.startOffset,
      fileOffset: _fragment.fullNameOffset,
      endOffset: _fragment.endOffset,
      isSynthetic: false,
      forAbstractClassOrEnumOrMixin: _fragment.forAbstractClassOrMixin,
      formalsOffset: _fragment.formalsOffset,
      isConst: _fragment.modifiers.isConst,
      returnType: returnType,
      typeParameters: _typeParameters,
      formals: formals,
      delayedDefaultValueCloners: delayedDefaultValueCloners,
    );
  }

  @override
  void _buildMetadataForOutlineExpressions({
    required Iterable<Annotatable> annotatables,
    required Uri annotatablesFileUri,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
  }) {
    for (Annotatable annotatable in annotatables) {
      MetadataBuilder.buildAnnotations(
        annotatable: annotatable,
        annotatableFileUri: annotatablesFileUri,
        metadata: _fragment.metadata,
        annotationsFileUri: _fragment.fileUri,
        bodyBuilderContext: bodyBuilderContext,
        libraryBuilder: libraryBuilder,
        extensionScope: _fragment.enclosingCompilationUnit.extensionScope,
        scope: _fragment.enclosingScope,
      );
    }
  }

  @override
  void _buildTypeParametersAndFormalsForOutlineExpressions({
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
  }) {
    _buildTypeParametersAndFormals(
      libraryBuilder: libraryBuilder,
      declarationBuilder: declarationBuilder,
      constructorBuilder: constructorBuilder,
      bodyBuilderContext: bodyBuilderContext,
      classHierarchy: classHierarchy,
      extensionScope: _fragment.enclosingCompilationUnit.extensionScope,
      typeParameterScope: _fragment.typeParameterScope,
    );
  }
}

class DefaultEnumConstructorDeclaration
    with
        _ConstructorDeclarationMixin,
        _ConstructorEncodingMixin,
        _RegularConstructorDeclarationMixin
    implements ConstructorDeclaration {
  @override
  final Uri fileUri;

  @override
  final int fileOffset;

  @override
  final OmittedTypeBuilder returnType;

  @override
  final List<FormalParameterBuilder> formals;

  @override
  late final ConstructorEncoding _encoding;

  @override
  final ExtensionScope _extensionScope;

  /// The scope in which to build the formal parameters.
  final LookupScope _lookupScope;

  @override
  Token? _beginInitializers;

  DefaultEnumConstructorDeclaration({
    required this.returnType,
    required this.formals,
    required Uri fileUri,
    required int fileOffset,
    required ExtensionScope extensionScope,
    required LookupScope lookupScope,
  }) : fileUri = fileUri,
       fileOffset = fileOffset,
       _extensionScope = extensionScope,
       _lookupScope = lookupScope,
       // Trick the constructor to be built during the outline phase.
       // TODO(johnniwinther): Avoid relying on [beginInitializers] to
       // ensure building constructors creation during the outline phase.
       _beginInitializers = new Token.eof(-1);

  @override
  void createEncoding({
    required ProblemReporting problemReporting,
    required SourceLoader loader,
    required DeclarationBuilder declarationBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required TypeParameterFactory typeParameterFactory,
    required ConstructorEncodingStrategy encodingStrategy,
  }) {
    _encoding = encodingStrategy.createEncoding(isExternal: false);
    _registerInferable(constructorBuilder);
  }

  @override
  void becomeNative(SourceLoader loader) {
    throw new UnsupportedError("$runtimeType.becomeNative()");
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isNative => false;

  @override
  LookupScope get _typeParameterScope => _lookupScope;

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => null;

  @override
  List<SourceNominalParameterBuilder>? get _typeParameters => null;

  @override
  bool get isConst => true;

  @override
  bool get isExternal => false;

  @override
  void buildOutlineNodes(
    BuildNodesCallback f, {
    required SourceConstructorBuilder constructorBuilder,
    required SourceLibraryBuilder libraryBuilder,
    required NameScheme nameScheme,
    required ConstructorReferences? constructorReferences,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  }) {
    _encoding.buildOutlineNodes(
      f,
      constructorBuilder: constructorBuilder,
      libraryBuilder: libraryBuilder,
      declarationBuilder: constructorBuilder.declarationBuilder,
      name: '',
      nameScheme: nameScheme,
      constructorReferences: constructorReferences,
      fileUri: fileUri,
      startOffset: fileOffset,
      fileOffset: fileOffset,
      formalsOffset: fileOffset,
      endOffset: fileOffset,
      isSynthetic: true,
      forAbstractClassOrEnumOrMixin: true,
      isConst: true,
      returnType: returnType,
      typeParameters: _typeParameters,
      formals: formals,
      delayedDefaultValueCloners: delayedDefaultValueCloners,
    );
  }

  @override
  void _buildMetadataForOutlineExpressions({
    required Iterable<Annotatable> annotatables,
    required Uri annotatablesFileUri,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
  }) {
    // There is no metadata on a default enum constructor.
  }

  @override
  void _buildTypeParametersAndFormalsForOutlineExpressions({
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
  }) {
    _buildTypeParametersAndFormals(
      libraryBuilder: libraryBuilder,
      declarationBuilder: declarationBuilder,
      constructorBuilder: constructorBuilder,
      bodyBuilderContext: bodyBuilderContext,
      classHierarchy: classHierarchy,
      extensionScope: _extensionScope,
      typeParameterScope: _lookupScope,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  String? get _nativeMethodName => null;
}

class PrimaryConstructorDeclaration
    with _ConstructorDeclarationMixin, _ConstructorEncodingMixin
    implements
        ConstructorDeclaration,
        ConstructorFragmentDeclaration,
        InferredTypeListener {
  final PrimaryConstructorFragment _fragment;
  final PrimaryConstructorBodyFragment? _bodyFragment;

  late final List<FormalParameterBuilder>? _formals;

  @override
  late final List<SourceNominalParameterBuilder>? _typeParameters;

  @override
  late final ConstructorEncoding _encoding;

  @override
  Token? _beginInitializers;

  PrimaryConstructorDeclaration(this._fragment, this._bodyFragment)
    : _beginInitializers = _fragment.beginInitializers {
    _fragment.declaration = this;
  }

  @override
  bool get isPrimaryConstructor => true;

  @override
  // Coverage-ignore(suite): Not run.
  String? get _nativeMethodName => null;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isNative => false;

  @override
  void createEncoding({
    required ProblemReporting problemReporting,
    required SourceLoader loader,
    required DeclarationBuilder declarationBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required TypeParameterFactory typeParameterFactory,
    required ConstructorEncodingStrategy encodingStrategy,
  }) {
    _fragment.builder = constructorBuilder;
    _bodyFragment?.builder = constructorBuilder;
    _bodyFragment?.registerPrimaryConstructorFragment(
      problemReporting,
      _fragment,
    );
    _fragment.primaryConstructorBodyFragment = _bodyFragment;
    _typeParameters = encodingStrategy.createTypeParameters(
      declarationBuilder: declarationBuilder,
      declarationTypeParameterFragments:
          _fragment.enclosingDeclaration.typeParameters,
      typeParameters: null,
      typeParameterFactory: typeParameterFactory,
    );
    _fragment.typeParameterNameSpace.addTypeParameters(
      problemReporting,
      _typeParameters,
      ownerName: _fragment.name,
      allowNameConflict: true,
    );
    _formals = encodingStrategy.createFormals(
      loader: loader,
      formals: _fragment.formals,
      fileUri: _fragment.fileUri,
      fileOffset: _fragment.fileOffset,
    );
    _encoding = encodingStrategy.createEncoding(
      isExternal: _fragment.modifiers.isExternal,
    );
    _registerInferable(constructorBuilder);
  }

  void _buildTypeParametersAndFormals({
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
    required ExtensionScope extensionScope,
    required LookupScope typeParameterScope,
  }) {
    if (_typeParameters != null) {
      for (int i = 0; i < _typeParameters!.length; i++) {
        _typeParameters![i].buildOutlineExpressions(
          libraryBuilder,
          bodyBuilderContext,
          classHierarchy,
        );
      }
    }

    if (formals != null) {
      // For const constructors we need to include default parameter values
      // into the outline. For all other formals we need to call
      // buildOutlineExpressions to clear initializerToken to prevent
      // consuming too much memory.
      for (FormalParameterBuilder formal in formals!) {
        formal.buildOutlineExpressions(
          libraryBuilder: libraryBuilder,
          declarationBuilder: declarationBuilder,
          memberBuilder: constructorBuilder,
          extensionScope: extensionScope,
          scope: typeParameterScope,
        );
      }
    }
  }

  @override
  BodyBuilderContext createBodyBuilderContext(
    SourceConstructorBuilder constructorBuilder,
  ) {
    return _encoding.createBodyBuilderContext(constructorBuilder, this);
  }

  @override
  void onInferredType(DartType type) {
    _encoding.registerInferredReturnType(type);
  }

  void _registerInferable(Inferable inferable) {
    returnType.registerInferredTypeListener(this);
    if (formals != null) {
      for (FormalParameterBuilder formal in formals!) {
        if (formal.isInitializingFormal || formal.isSuperInitializingFormal) {
          formal.type.registerInferable(inferable);
        }
      }
    }
  }

  @override
  ExtensionScope get _extensionScope =>
      _fragment.enclosingCompilationUnit.extensionScope;

  @override
  LookupScope get _typeParameterScope => _fragment.typeParameterScope;

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => null;

  @override
  OmittedTypeBuilder get returnType => _fragment.returnType;

  @override
  List<FormalParameterBuilder>? get formals => _formals;

  @override
  bool get isConst => _fragment.modifiers.isConst;

  @override
  bool get isExternal => _fragment.modifiers.isExternal;

  @override
  void buildOutlineNodes(
    BuildNodesCallback f, {
    required SourceConstructorBuilder constructorBuilder,
    required SourceLibraryBuilder libraryBuilder,
    required NameScheme nameScheme,
    required ConstructorReferences? constructorReferences,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  }) {
    _encoding.buildOutlineNodes(
      f,
      constructorBuilder: constructorBuilder,
      libraryBuilder: libraryBuilder,
      declarationBuilder: constructorBuilder.declarationBuilder,
      name: _fragment.name,
      nameScheme: nameScheme,
      constructorReferences: constructorReferences,
      fileUri: _fragment.fileUri,
      fileOffset: _fragment.fileOffset,
      startOffset: _fragment.startOffset,
      formalsOffset: _fragment.formalsOffset,
      // TODO(johnniwinther): Provide `endOffset`.
      endOffset: _fragment.formalsOffset,
      forAbstractClassOrEnumOrMixin: _fragment.forAbstractClassOrMixin,
      isConst: _fragment.modifiers.isConst,
      isSynthetic: false,
      returnType: returnType,
      typeParameters: _typeParameters,
      formals: formals,
      delayedDefaultValueCloners: delayedDefaultValueCloners,
    );
  }

  @override
  void _buildMetadataForOutlineExpressions({
    required Iterable<Annotatable> annotatables,
    required Uri annotatablesFileUri,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
  }) {
    if (_bodyFragment case var bodyFragment?) {
      for (Annotatable annotatable in annotatables) {
        MetadataBuilder.buildAnnotations(
          annotatable: annotatable,
          annotatableFileUri: annotatablesFileUri,
          metadata: bodyFragment.metadata,
          annotationsFileUri: bodyFragment.fileUri,
          bodyBuilderContext: bodyBuilderContext,
          libraryBuilder: libraryBuilder,
          extensionScope: bodyFragment.enclosingCompilationUnit.extensionScope,
          scope: bodyFragment.enclosingScope,
        );
      }
    }
  }

  @override
  void _buildTypeParametersAndFormalsForOutlineExpressions({
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
  }) {
    _buildTypeParametersAndFormals(
      libraryBuilder: libraryBuilder,
      declarationBuilder: declarationBuilder,
      constructorBuilder: constructorBuilder,
      bodyBuilderContext: bodyBuilderContext,
      classHierarchy: classHierarchy,
      extensionScope: _fragment.enclosingCompilationUnit.extensionScope,
      typeParameterScope: _fragment.typeParameterScope,
    );
  }

  @override
  int get fileOffset => _fragment.fileOffset;

  @override
  Uri get fileUri => _fragment.fileUri;
}

/// Interface for using a [ConstructorFragment] or [PrimaryConstructorFragment]
/// to create a [BodyBuilderContext].
abstract class ConstructorFragmentDeclaration {
  int get fileOffset;

  OmittedTypeBuilder get returnType;

  List<FormalParameterBuilder>? get formals;

  BodyBuilderContext createBodyBuilderContext(
    SourceConstructorBuilder constructorBuilder,
  );

  void registerFunctionBody(Statement? body, Scope? scope);

  void registerNoBodyConstructor();

  VariableDeclaration? get thisVariable;

  List<TypeParameter>? get thisTypeParameters;

  void becomeNative(SourceLoader loader);

  /// Returns the [VariableDeclaration] for the tear off, if any, of the
  /// [index]th formal parameter declared in the constructor.
  VariableDeclaration? getTearOffParameter(int index);

  LocalScope computeFormalParameterScope(LookupScope parent);

  LocalScope computeFormalParameterInitializerScope(LocalScope parent);

  bool get isConst;

  bool get isExternal;

  bool get isNative;
}

mixin _SyntheticConstructorDeclarationMixin implements ConstructorDeclaration {
  Constructor get _constructor;

  Procedure? get _constructorTearOff;

  @override
  // Coverage-ignore(suite): Not run.
  void registerInitializers(List<Initializer> initializers) {
    _constructor.initializers.addAll(initializers);
    setParents(initializers, _constructor);
  }

  @override
  bool get isPrimaryConstructor => false;

  @override
  // Coverage-ignore(suite): Not run.
  List<FormalParameterBuilder>?
  get primaryConstructorInitializerScopeParameters {
    assert(
      false,
      "Unexpected call to "
      "$runtimeType.initializerScopeParameters "
      "on non-primary constructor.",
    );
    return null;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Uri get fileUri => _constructor.fileUri;

  @override
  FunctionSignature get signature =>
      new FunctionNodeSignature(_constructor.function);

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasParameters =>
      _constructor.function.positionalParameters.isNotEmpty ||
      _constructor.function.namedParameters.isNotEmpty;

  @override
  bool get isExternal => false;

  @override
  bool get isRedirecting {
    for (Initializer initializer in _constructor.initializers) {
      assert(
        initializer is! AuxiliaryInitializer,
        "Unexpected auxiliary initializer $initializer.",
      );
      if (initializer is RedirectingInitializer) {
        return true;
      }
    }
    return false;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void markAsErroneous() {
    _constructor.isErroneous = true;
  }

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => null;

  @override
  void checkTypes(
    ProblemReporting problemReporting,
    NameSpace nameSpace,
    TypeEnvironment typeEnvironment,
  ) {}

  @override
  // Coverage-ignore(suite): Not run.
  int computeDefaultTypes(
    ComputeDefaultTypeContext context, {
    required bool inErrorRecovery,
  }) {
    assert(false, "Unexpected call to $runtimeType.computeDefaultType");
    return 0;
  }

  @override
  void buildBody() {}

  @override
  void buildOutlineNodes(
    BuildNodesCallback f, {
    required SourceConstructorBuilder constructorBuilder,
    required SourceLibraryBuilder libraryBuilder,
    required NameScheme nameScheme,
    required ConstructorReferences? constructorReferences,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  }) {
    f(
      member: _constructor,
      tearOff: _constructorTearOff,
      kind: BuiltMemberKind.Constructor,
    );
  }

  @override
  List<Initializer> get initializers {
    throw new UnsupportedError("Unexpected call to $runtimeType.initializers");
  }

  @override
  void prepareInitializers() {
    throw new UnsupportedError(
      "Unexpected call to $runtimeType.prepareInitializers",
    );
  }

  @override
  void prependInitializer(Initializer initializer) {
    throw new UnsupportedError(
      "Unexpected call to $runtimeType.prependInitializer",
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Substitution computeFieldTypeSubstitution(
    DeclarationBuilder declarationBuilder,
  ) {
    return Substitution.empty;
  }
}

class DefaultConstructorDeclaration
    with _SyntheticConstructorDeclarationMixin
    implements ConstructorDeclaration {
  @override
  final Constructor _constructor;

  @override
  final Procedure? _constructorTearOff;

  DefaultConstructorDeclaration({
    required Constructor constructor,
    required Procedure? constructorTearOff,
  }) : this._constructor = constructor,
       this._constructorTearOff = constructorTearOff;

  @override
  // Coverage-ignore(suite): Not run.
  void createEncoding({
    required ProblemReporting problemReporting,
    required SourceLoader loader,
    required DeclarationBuilder declarationBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required TypeParameterFactory typeParameterFactory,
    required ConstructorEncodingStrategy encodingStrategy,
  }) {}

  @override
  void addSuperParameterDefaultValueCloners(
    SourceLibraryBuilder libraryBuilder,
    DeclarationBuilder declarationBuilder,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {}

  @override
  void buildOutlineExpressions({
    required Iterable<Annotatable> annotatables,
    required Uri annotatablesFileUri,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required ClassHierarchy classHierarchy,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  }) {}

  @override
  void inferFormalTypes(
    SourceLibraryBuilder libraryBuilder,
    DeclarationBuilder declarationBuilder,
    SourceConstructorBuilder constructorBuilder,
    ClassHierarchyBase hierarchy,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {}
}

class ForwardingConstructorDeclaration
    with _SyntheticConstructorDeclarationMixin
    implements ConstructorDeclaration {
  @override
  final Constructor _constructor;

  @override
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

  ForwardingConstructorDeclaration({
    required Constructor constructor,
    required Procedure? constructorTearOff,
    required MemberBuilder definingConstructor,
    required DelayedDefaultValueCloner delayedDefaultValueCloner,
    required TypeDependency? typeDependency,
  }) : _constructor = constructor,
       _constructorTearOff = constructorTearOff,
       _immediatelyDefiningConstructor = definingConstructor,
       _delayedDefaultValueCloner = delayedDefaultValueCloner,
       _typeDependency = typeDependency;

  @override
  // Coverage-ignore(suite): Not run.
  void createEncoding({
    required ProblemReporting problemReporting,
    required SourceLoader loader,
    required DeclarationBuilder declarationBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required TypeParameterFactory typeParameterFactory,
    required ConstructorEncodingStrategy encodingStrategy,
  }) {}

  @override
  void addSuperParameterDefaultValueCloners(
    SourceLibraryBuilder libraryBuilder,
    DeclarationBuilder declarationBuilder,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {
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
      delayedDefaultValueCloners.add(
        _delayedDefaultValueCloner!..isOutlineNode = true,
      );
      _delayedDefaultValueCloner = null;
    }
  }

  @override
  void buildOutlineExpressions({
    required Iterable<Annotatable> annotatables,
    required Uri annotatablesFileUri,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required SourceConstructorBuilder constructorBuilder,
    required ClassHierarchy classHierarchy,
    required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  }) {
    if (_immediatelyDefiningConstructor != null) {
      // Ensure that default value expressions have been created for [_origin].
      // If [_origin] is from a source library, we need to build the default
      // values and initializers first.
      MemberBuilder origin = _immediatelyDefiningConstructor!;
      if (origin is SourceConstructorBuilder) {
        origin.buildOutlineExpressions(
          classHierarchy,
          delayedDefaultValueCloners,
        );
      }
      addSuperParameterDefaultValueCloners(
        libraryBuilder,
        declarationBuilder,
        delayedDefaultValueCloners,
      );
      _immediatelyDefiningConstructor = null;
    }
  }

  @override
  void inferFormalTypes(
    SourceLibraryBuilder libraryBuilder,
    DeclarationBuilder declarationBuilder,
    SourceConstructorBuilder constructorBuilder,
    ClassHierarchyBase hierarchy,
    List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
  ) {
    if (_immediatelyDefiningConstructor is SourceConstructorBuilder) {
      (_immediatelyDefiningConstructor as SourceConstructorBuilder)
          .inferFormalTypes(hierarchy);
    }
    if (_typeDependency != null) {
      _typeDependency!.copyInferred();
      _typeDependency = null;
    }
  }
}
