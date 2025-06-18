// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../../base/constant_context.dart';
import '../../base/identifiers.dart';
import '../../base/local_scope.dart';
import '../../base/name_space.dart';
import '../../base/scope.dart';
import '../../builder/constructor_builder.dart';
import '../../builder/declaration_builders.dart';
import '../../builder/formal_parameter_builder.dart';
import '../../builder/member_builder.dart';
import '../../builder/metadata_builder.dart';
import '../../builder/omitted_type_builder.dart';
import '../../builder/type_builder.dart';
import '../../builder/variable_builder.dart';
import '../../kernel/body_builder.dart';
import '../../kernel/body_builder_context.dart';
import '../../kernel/internal_ast.dart';
import '../../kernel/kernel_helper.dart';
import '../../kernel/type_algorithms.dart';
import '../../source/name_scheme.dart';
import '../../source/source_class_builder.dart';
import '../../source/source_constructor_builder.dart';
import '../../source/source_extension_builder.dart';
import '../../source/source_extension_type_declaration_builder.dart';
import '../../source/source_function_builder.dart';
import '../../source/source_library_builder.dart';
import '../../source/source_loader.dart';
import '../../source/source_member_builder.dart';
import '../../source/source_type_parameter_builder.dart';
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

  FunctionNode get function;

  bool get hasParameters;

  List<Initializer> get initializers;

  void createEncoding(SourceConstructorBuilder builder);

  void registerInferable(Inferable inferable);

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

  void checkTypes(SourceLibraryBuilder libraryBuilder, NameSpace nameSpace,
      TypeEnvironment typeEnvironment);

  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery});

  void prepareInitializers();

  void prependInitializer(Initializer initializer);

  Substitution computeFieldTypeSubstitution(
      DeclarationBuilder declarationBuilder);

  void buildBody();

  bool get isExternal;

  bool get isRedirecting;

  void addSuperParameterDefaultValueCloners(
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder declarationBuilder,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners);

  void inferFormalTypes(
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder declarationBuilder,
      SourceConstructorBuilder constructorBuilder,
      ClassHierarchyBase hierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners);

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

  LookupScope get _typeParameterScope;

  abstract Token? _beginInitializers;

  List<SourceNominalParameterBuilder>? get _typeParameters;

  @override
  bool get hasParameters => formals != null;

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

  @override
  void inferFormalTypes(
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder declarationBuilder,
      SourceConstructorBuilder constructorBuilder,
      ClassHierarchyBase hierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (formals != null) {
      libraryBuilder.loader.withUriForCrashReporting(fileUri, fileOffset, () {
        for (FormalParameterBuilder formal in formals!) {
          if (formal.type is InferableTypeBuilder) {
            if (formal.isInitializingFormal) {
              formal.finalizeInitializingFormal(
                  declarationBuilder, constructorBuilder, hierarchy);
            }
          }
        }
        _inferSuperInitializingFormals(libraryBuilder, declarationBuilder,
            constructorBuilder, hierarchy, delayedDefaultValueCloners);
      });
    }
  }

  void _inferSuperInitializingFormals(
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder declarationBuilder,
      SourceConstructorBuilder constructorBuilder,
      ClassHierarchyBase hierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (_hasSuperInitializingFormals) {
      List<Initializer>? initializers;
      Token? beginInitializers = this._beginInitializers;
      if (beginInitializers != null) {
        BodyBuilder bodyBuilder = libraryBuilder.loader
            .createBodyBuilderForOutlineExpression(
                libraryBuilder,
                createBodyBuilderContext(constructorBuilder),
                _typeParameterScope,
                fileUri);
        if (isConst) {
          bodyBuilder.constantContext = ConstantContext.required;
        }
        initializers = bodyBuilder.parseInitializers(beginInitializers,
            doFinishConstructor: false);
      }
      _finalizeSuperInitializingFormals(libraryBuilder, declarationBuilder,
          hierarchy, delayedDefaultValueCloners, initializers);
    }
  }

  void _finalizeSuperInitializingFormals(
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder declarationBuilder,
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

    ConstructorBuilder? superTargetBuilder = _computeSuperTargetBuilder(
        libraryBuilder, declarationBuilder, initializers);

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
    SourceClassBuilder classBuilder = declarationBuilder as SourceClassBuilder;

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
      _addSuperParameterDefaultValueCloners(
          libraryBuilder: libraryBuilder,
          delayedDefaultValueCloners: delayedDefaultValueCloners,
          superTarget: superTarget,
          positionalSuperParameters: positionalSuperParameters,
          namedSuperParameters: namedSuperParameters);
    }
  }

  void _addSuperParameterDefaultValueCloners(
      {required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
      required Member superTarget,
      required List<int?>? positionalSuperParameters,
      required List<String>? namedSuperParameters,
      required SourceLibraryBuilder libraryBuilder});

  ConstructorBuilder? _computeSuperTargetBuilder(
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder declarationBuilder,
      List<Initializer>? initializers) {
    if (declarationBuilder is! SourceClassBuilder) {
      return null;
    }
    SourceClassBuilder classBuilder = declarationBuilder;

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
  void addSuperParameterDefaultValueCloners(
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder declarationBuilder,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
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
            libraryBuilder, declarationBuilder, initializers);
        if (superTargetBuilder is SourceConstructorBuilder) {
          superTargetBuilder
              .addSuperParameterDefaultValueCloners(delayedDefaultValueCloners);
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
      SourceConstructorBuilder constructorBuilder) {
    if (_beginInitializers != null) {
      final LocalScope? formalParameterScope;
      if (isConst) {
        // We're going to fully build the constructor so we need scopes.
        formalParameterScope = computeFormalParameterInitializerScope(
            computeFormalParameterScope(_typeParameterScope));
      } else {
        formalParameterScope = null;
      }
      BodyBuilder bodyBuilder = libraryBuilder.loader
          .createBodyBuilderForOutlineExpression(
              libraryBuilder,
              createBodyBuilderContext(constructorBuilder),
              _typeParameterScope,
              fileUri,
              formalParameterScope: formalParameterScope);
      if (isConst) {
        bodyBuilder.constantContext = ConstantContext.required;
      }
      constructorBuilder.inferFormalTypes(bodyBuilder.hierarchy);
      bodyBuilder.parseInitializers(_beginInitializers!,
          doFinishConstructor: isConst);
      bodyBuilder.performBacklogComputations();
    }
  }

  void _buildOutlineExpressions(SourceLibraryBuilder libraryBuilder,
      SourceConstructorBuilder constructorBuilder) {
    if (isConst || _hasSuperInitializingFormals) {
      // For modular compilation purposes we need to include initializers
      // for const constructors into the outline.
      _buildConstructorForOutlineExpressions(
          libraryBuilder, constructorBuilder);
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
    BodyBuilderContext bodyBuilderContext =
        createBodyBuilderContext(constructorBuilder);
    _buildMetadataForOutlineExpressions(
        annotatables: annotatables,
        annotatablesFileUri: annotatablesFileUri,
        libraryBuilder: libraryBuilder,
        declarationBuilder: declarationBuilder,
        constructorBuilder: constructorBuilder,
        bodyBuilderContext: bodyBuilderContext,
        classHierarchy: classHierarchy);
    _buildTypeParametersAndFormalsForOutlineExpressions(
        libraryBuilder: libraryBuilder,
        declarationBuilder: declarationBuilder,
        bodyBuilderContext: bodyBuilderContext,
        classHierarchy: classHierarchy);
    _buildOutlineExpressions(libraryBuilder, constructorBuilder);
    addSuperParameterDefaultValueCloners(
        libraryBuilder, declarationBuilder, delayedDefaultValueCloners);
    _beginInitializers = null;
  }

  @override
  void checkTypes(SourceLibraryBuilder libraryBuilder, NameSpace nameSpace,
      TypeEnvironment typeEnvironment) {
    libraryBuilder.checkInitializersInFormals(formals, typeEnvironment,
        isAbstract: false, isExternal: isExternal);
  }

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    int count = context.computeDefaultTypesForVariables(_typeParameters,
        // Type parameters are inherited from the enclosing declaration, so if
        // it has issues, so do the constructors.
        inErrorRecovery: inErrorRecovery);
    context.reportGenericFunctionTypesForFormals(formals);
    return count;
  }
}

mixin _ConstructorEncodingMixin
    implements ConstructorDeclaration, ConstructorFragmentDeclaration {
  ConstructorEncoding get _encoding;

  @override
  FunctionNode get function => _encoding.function;

  @override
  List<Initializer> get initializers => _encoding.initializers;

  @override
  void prepareInitializers() {
    _encoding.prepareInitializers();
  }

  @override
  void prependInitializer(Initializer initializer) {
    _encoding.prependInitializer(initializer);
  }

  @override
  VariableDeclaration getFormalParameter(int index) {
    return _encoding.getFormalParameter(index);
  }

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    return _encoding.getTearOffParameter(index);
  }

  @override
  void markAsErroneous() {
    _encoding.markAsErroneous();
  }
}

mixin _RegularConstructorDeclarationMixin
    implements
        _ConstructorDeclarationMixin,
        _ConstructorEncodingMixin,
        InferredTypeListener {
  @override
  RegularConstructorEncoding get _encoding;

  @override
  void registerFunctionBody(Statement value) {
    _encoding.registerFunctionBody(value);
  }

  @override
  void registerNoBodyConstructor() {
    _encoding.registerNoBodyConstructor();
  }

  @override
  VariableDeclaration? get thisVariable => null;

  @override
  List<TypeParameter>? get thisTypeParameters => null;

  @override
  Substitution computeFieldTypeSubstitution(
      DeclarationBuilder declarationBuilder) {
    // Nothing to substitute. Regular generative constructors don't have their
    // own type parameters.
    return Substitution.empty;
  }

  @override
  void buildBody() {}

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
  late final bool _hasSuperInitializingFormals =
      formals?.any((formal) => formal.isSuperInitializingFormal) ?? false;

  @override
  void _addSuperParameterDefaultValueCloners(
      {required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
      required Member superTarget,
      required List<int?>? positionalSuperParameters,
      required List<String>? namedSuperParameters,
      required SourceLibraryBuilder libraryBuilder}) {
    _encoding.addSuperParameterDefaultValueCloners(
        delayedDefaultValueCloners: delayedDefaultValueCloners,
        superTarget: superTarget,
        positionalSuperParameters: positionalSuperParameters,
        namedSuperParameters: namedSuperParameters,
        libraryBuilder: libraryBuilder);
  }

  void _buildTypeParametersAndFormals({
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
    required LookupScope typeParameterScope,
  }) {
    if (_typeParameters != null) {
      for (int i = 0; i < _typeParameters!.length; i++) {
        _typeParameters![i].buildOutlineExpressions(
            libraryBuilder, bodyBuilderContext, classHierarchy);
      }
    }

    if (formals != null) {
      // For const constructors we need to include default parameter values
      // into the outline. For all other formals we need to call
      // buildOutlineExpressions to clear initializerToken to prevent
      // consuming too much memory.
      for (FormalParameterBuilder formal in formals!) {
        formal.buildOutlineExpressions(libraryBuilder, declarationBuilder,
            scope: typeParameterScope, buildDefaultValue: true);
      }
    }
  }

  @override
  BodyBuilderContext createBodyBuilderContext(
      SourceConstructorBuilder constructorBuilder) {
    return _encoding.createBodyBuilderContext(constructorBuilder, this);
  }

  @override
  void onInferredType(DartType type) {
    function.returnType = type;
  }

  @override
  void registerInferable(Inferable inferable) {
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
  final List<FormalParameterBuilder>? _syntheticFormals;

  @override
  final RegularConstructorEncoding _encoding;

  @override
  final List<SourceNominalParameterBuilder>? _typeParameters;

  @override
  Token? _beginInitializers;

  RegularConstructorDeclaration(this._fragment,
      {required List<FormalParameterBuilder>? syntheticFormals,
      required List<SourceNominalParameterBuilder>? typeParameters,
      // TODO(johnniwinther): Create a separate [ConstructorDeclaration] for
      // enum constructors.
      required bool isEnumConstructor})
      : _typeParameters = typeParameters,
        _syntheticFormals = syntheticFormals,
        _beginInitializers = _fragment.beginInitializers,
        _encoding = new RegularConstructorEncoding(
            isExternal: _fragment.modifiers.isExternal,
            isEnumConstructor: isEnumConstructor) {
    _fragment.declaration = this;
  }

  @override
  void createEncoding(SourceConstructorBuilder builder) {
    _fragment.builder = builder;
  }

  @override
  void becomeNative(SourceLoader loader) {
    _encoding.becomeNative(loader, _fragment.nativeMethodName!);
  }

  @override
  LookupScope get _typeParameterScope => _fragment.typeParameterScope;

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  OmittedTypeBuilder get returnType => _fragment.returnType;

  @override
  late final List<FormalParameterBuilder>? formals = _syntheticFormals != null
      ? [..._syntheticFormals, ...?_fragment.formals]
      : _fragment.formals;

  @override
  bool get isConst => _fragment.modifiers.isConst;

  @override
  bool get isExternal => _fragment.modifiers.isExternal;

  @override
  void buildOutlineNodes(BuildNodesCallback f,
      {required SourceConstructorBuilder constructorBuilder,
      required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required ConstructorReferences? constructorReferences,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners}) {
    _encoding.buildOutlineNodes(f,
        constructorBuilder: constructorBuilder,
        libraryBuilder: libraryBuilder,
        declarationBuilder:
            constructorBuilder.declarationBuilder as SourceClassBuilder,
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
        delayedDefaultValueCloners: delayedDefaultValueCloners);
  }

  @override
  void _buildMetadataForOutlineExpressions(
      {required Iterable<Annotatable> annotatables,
      required Uri annotatablesFileUri,
      required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder declarationBuilder,
      required SourceConstructorBuilder constructorBuilder,
      required BodyBuilderContext bodyBuilderContext,
      required ClassHierarchy classHierarchy}) {
    for (Annotatable annotatable in annotatables) {
      MetadataBuilder.buildAnnotations(
          annotatable: annotatable,
          annotatableFileUri: annotatablesFileUri,
          metadata: _fragment.metadata,
          bodyBuilderContext: bodyBuilderContext,
          libraryBuilder: libraryBuilder,
          scope: _fragment.enclosingScope);
    }
  }

  @override
  void _buildTypeParametersAndFormalsForOutlineExpressions(
      {required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder declarationBuilder,
      required BodyBuilderContext bodyBuilderContext,
      required ClassHierarchy classHierarchy}) {
    _buildTypeParametersAndFormals(
        libraryBuilder: libraryBuilder,
        declarationBuilder: declarationBuilder,
        bodyBuilderContext: bodyBuilderContext,
        classHierarchy: classHierarchy,
        typeParameterScope: _fragment.typeParameterScope);
  }

  @override
  int get fileOffset => _fragment.fullNameOffset;

  @override
  Uri get fileUri => _fragment.fileUri;
}

// Coverage-ignore(suite): Not run.
class PrimaryConstructorDeclaration
    with
        _ConstructorDeclarationMixin,
        _ConstructorEncodingMixin,
        _RegularConstructorDeclarationMixin
    implements ConstructorDeclaration, ConstructorFragmentDeclaration {
  final PrimaryConstructorFragment _fragment;

  @override
  final RegularConstructorEncoding _encoding;

  @override
  Token? _beginInitializers;

  PrimaryConstructorDeclaration(this._fragment)
      : _beginInitializers = _fragment.beginInitializers,
        _encoding = new RegularConstructorEncoding(
            isExternal: _fragment.modifiers.isExternal,
            isEnumConstructor: false) {
    _fragment.declaration = this;
  }

  @override
  void createEncoding(SourceConstructorBuilder builder) {
    _fragment.builder = builder;
  }

  @override
  void becomeNative(SourceLoader loader) {
    throw new UnsupportedError("$runtimeType.becomeNative()");
  }

  @override
  LookupScope get _typeParameterScope => _fragment.typeParameterScope;

  @override
  OmittedTypeBuilder get returnType => _fragment.returnType;

  @override
  List<MetadataBuilder>? get metadata => null;

  @override
  List<FormalParameterBuilder>? get formals => _fragment.formals;

  @override
  List<SourceNominalParameterBuilder>? get _typeParameters => null;

  @override
  bool get isConst => _fragment.modifiers.isConst;

  @override
  bool get isExternal => _fragment.modifiers.isExternal;

  @override
  void buildOutlineNodes(BuildNodesCallback f,
      {required SourceConstructorBuilder constructorBuilder,
      required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required ConstructorReferences? constructorReferences,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners}) {
    _encoding.buildOutlineNodes(f,
        constructorBuilder: constructorBuilder,
        libraryBuilder: libraryBuilder,
        declarationBuilder:
            constructorBuilder.declarationBuilder as SourceClassBuilder,
        name: _fragment.name,
        nameScheme: nameScheme,
        constructorReferences: constructorReferences,
        fileUri: _fragment.fileUri,
        startOffset: _fragment.startOffset,
        fileOffset: _fragment.fileOffset,
        formalsOffset: _fragment.formalsOffset,
        // TODO(johnniwinther): Provide `endOffset`.
        endOffset: _fragment.formalsOffset,
        isSynthetic: false,
        forAbstractClassOrEnumOrMixin: _fragment.forAbstractClassOrMixin,
        isConst: _fragment.modifiers.isConst,
        returnType: returnType,
        typeParameters: _typeParameters,
        formals: formals,
        delayedDefaultValueCloners: delayedDefaultValueCloners);
  }

  @override
  void _buildMetadataForOutlineExpressions(
      {required Iterable<Annotatable> annotatables,
      required Uri annotatablesFileUri,
      required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder declarationBuilder,
      required SourceConstructorBuilder constructorBuilder,
      required BodyBuilderContext bodyBuilderContext,
      required ClassHierarchy classHierarchy}) {
    // There is no metadata on a primary constructor.
  }

  @override
  void _buildTypeParametersAndFormalsForOutlineExpressions(
      {required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder declarationBuilder,
      required BodyBuilderContext bodyBuilderContext,
      required ClassHierarchy classHierarchy}) {
    _buildTypeParametersAndFormals(
        libraryBuilder: libraryBuilder,
        declarationBuilder: declarationBuilder,
        bodyBuilderContext: bodyBuilderContext,
        classHierarchy: classHierarchy,
        typeParameterScope: _fragment.typeParameterScope);
  }

  @override
  int get fileOffset => _fragment.fileOffset;

  @override
  Uri get fileUri => _fragment.fileUri;
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
  final RegularConstructorEncoding _encoding = new RegularConstructorEncoding(
      isExternal: false, isEnumConstructor: true);

  /// The scope in which to build the formal parameters.
  final LookupScope _lookupScope;

  @override
  Token? _beginInitializers;

  DefaultEnumConstructorDeclaration(
      {required this.returnType,
      required this.formals,
      required Uri fileUri,
      required int fileOffset,
      required LookupScope lookupScope})
      : fileUri = fileUri,
        fileOffset = fileOffset,
        _lookupScope = lookupScope,
        // Trick the constructor to be built during the outline phase.
        // TODO(johnniwinther): Avoid relying on [beginInitializers] to
        // ensure building constructors creation during the outline phase.
        _beginInitializers = new Token.eof(-1);

  @override
  // Coverage-ignore(suite): Not run.
  void createEncoding(SourceConstructorBuilder builder) {}

  @override
  void becomeNative(SourceLoader loader) {
    throw new UnsupportedError("$runtimeType.becomeNative()");
  }

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
  void buildOutlineNodes(BuildNodesCallback f,
      {required SourceConstructorBuilder constructorBuilder,
      required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required ConstructorReferences? constructorReferences,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners}) {
    _encoding.buildOutlineNodes(f,
        constructorBuilder: constructorBuilder,
        libraryBuilder: libraryBuilder,
        declarationBuilder:
            constructorBuilder.declarationBuilder as SourceClassBuilder,
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
        delayedDefaultValueCloners: delayedDefaultValueCloners);
  }

  @override
  void _buildMetadataForOutlineExpressions(
      {required Iterable<Annotatable> annotatables,
      required Uri annotatablesFileUri,
      required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder declarationBuilder,
      required SourceConstructorBuilder constructorBuilder,
      required BodyBuilderContext bodyBuilderContext,
      required ClassHierarchy classHierarchy}) {
    // There is no metadata on a default enum constructor.
  }

  @override
  void _buildTypeParametersAndFormalsForOutlineExpressions(
      {required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder declarationBuilder,
      required BodyBuilderContext bodyBuilderContext,
      required ClassHierarchy classHierarchy}) {
    _buildTypeParametersAndFormals(
        libraryBuilder: libraryBuilder,
        declarationBuilder: declarationBuilder,
        bodyBuilderContext: bodyBuilderContext,
        classHierarchy: classHierarchy,
        typeParameterScope: _lookupScope);
  }
}

mixin _ExtensionTypeConstructorDeclarationMixin
    implements
        _ConstructorDeclarationMixin,
        _ConstructorEncodingMixin,
        InferredTypeListener {
  @override
  ExtensionTypeConstructorEncoding get _encoding;

  @override
  void registerFunctionBody(Statement value) {
    _encoding.registerFunctionBody(value);
  }

  @override
  void registerNoBodyConstructor() {
    _encoding.registerNoBodyConstructor();
  }

  @override
  VariableDeclaration? get thisVariable => _encoding.thisVariable;

  @override
  List<TypeParameter>? get thisTypeParameters => _encoding.thisTypeParameters;

  @override
  void becomeNative(SourceLoader loader) {
    throw new UnsupportedError("$runtimeType.becomeNative()");
  }

  @override
  Substitution computeFieldTypeSubstitution(
      DeclarationBuilder declarationBuilder) {
    if (_typeParameters != null) {
      assert(
          declarationBuilder.typeParameters!.length == _typeParameters?.length);
      return Substitution.fromPairs(
          (declarationBuilder as SourceExtensionTypeDeclarationBuilder)
              .extensionTypeDeclaration
              .typeParameters,
          new List<DartType>.generate(
              declarationBuilder.typeParameters!.length,
              (int index) => new TypeParameterType.withDefaultNullability(
                  function.typeParameters[index])));
    } else {
      return Substitution.empty;
    }
  }

  @override
  void buildBody() {
    _encoding.buildBody();
  }

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
  late final bool _hasSuperInitializingFormals =
      formals?.any((formal) => formal.isSuperInitializingFormal) ?? false;

  @override
  void _addSuperParameterDefaultValueCloners(
      {required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
      required Member superTarget,
      required List<int?>? positionalSuperParameters,
      required List<String>? namedSuperParameters,
      required SourceLibraryBuilder libraryBuilder}) {
    throw new UnsupportedError(
        '$runtimeType.addSuperParameterDefaultValueCloners');
  }

  void _buildTypeParametersAndFormals({
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
    required LookupScope typeParameterScope,
  }) {
    if (_typeParameters != null) {
      for (int i = 0; i < _typeParameters!.length; i++) {
        _typeParameters![i].buildOutlineExpressions(
            libraryBuilder, bodyBuilderContext, classHierarchy);
      }
    }

    if (formals != null) {
      // For const constructors we need to include default parameter values
      // into the outline. For all other formals we need to call
      // buildOutlineExpressions to clear initializerToken to prevent
      // consuming too much memory.
      for (FormalParameterBuilder formal in formals!) {
        formal.buildOutlineExpressions(libraryBuilder, declarationBuilder,
            scope: typeParameterScope, buildDefaultValue: true);
      }
    }
  }

  @override
  BodyBuilderContext createBodyBuilderContext(
      SourceConstructorBuilder constructorBuilder) {
    return _encoding.createBodyBuilderContext(constructorBuilder, this);
  }

  @override
  void onInferredType(DartType type) {
    function.returnType = type;
  }

  @override
  void registerInferable(Inferable inferable) {
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

class ExtensionTypeConstructorDeclaration
    with
        _ConstructorDeclarationMixin,
        _ConstructorEncodingMixin,
        _ExtensionTypeConstructorDeclarationMixin
    implements ConstructorDeclaration, ConstructorFragmentDeclaration {
  final ConstructorFragment _fragment;

  @override
  final List<SourceNominalParameterBuilder>? _typeParameters;

  @override
  final ExtensionTypeConstructorEncoding _encoding;

  @override
  Token? _beginInitializers;

  ExtensionTypeConstructorDeclaration(this._fragment,
      {required List<SourceNominalParameterBuilder>? typeParameters})
      : _typeParameters = typeParameters,
        _beginInitializers = _fragment.beginInitializers,
        _encoding = new ExtensionTypeConstructorEncoding(
            isExternal: _fragment.modifiers.isExternal) {
    _fragment.declaration = this;
  }

  @override
  void createEncoding(SourceConstructorBuilder builder) {
    _fragment.builder = builder;
  }

  @override
  LookupScope get _typeParameterScope => _fragment.typeParameterScope;

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  OmittedTypeBuilder get returnType => _fragment.returnType;

  @override
  List<FormalParameterBuilder>? get formals => _fragment.formals;

  @override
  bool get isConst => _fragment.modifiers.isConst;

  @override
  bool get isExternal => _fragment.modifiers.isExternal;

  @override
  void buildOutlineNodes(BuildNodesCallback f,
      {required SourceConstructorBuilder constructorBuilder,
      required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required ConstructorReferences? constructorReferences,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners}) {
    _encoding.buildOutlineNodes(f,
        constructorBuilder: constructorBuilder,
        libraryBuilder: libraryBuilder,
        declarationBuilder: constructorBuilder.declarationBuilder
            as SourceExtensionTypeDeclarationBuilder,
        name: _fragment.name,
        nameScheme: nameScheme,
        constructorReferences: constructorReferences,
        fileUri: _fragment.fileUri,
        fileOffset: _fragment.fullNameOffset,
        formalsOffset: _fragment.formalsOffset,
        endOffset: _fragment.endOffset,
        forAbstractClassOrEnumOrMixin: _fragment.forAbstractClassOrMixin,
        isConst: _fragment.modifiers.isConst,
        returnType: returnType,
        typeParameters: _typeParameters,
        formals: formals,
        delayedDefaultValueCloners: delayedDefaultValueCloners);
  }

  @override
  void _buildMetadataForOutlineExpressions(
      {required Iterable<Annotatable> annotatables,
      required Uri annotatablesFileUri,
      required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder declarationBuilder,
      required SourceConstructorBuilder constructorBuilder,
      required BodyBuilderContext bodyBuilderContext,
      required ClassHierarchy classHierarchy}) {
    for (Annotatable annotatable in annotatables) {
      MetadataBuilder.buildAnnotations(
          annotatable: annotatable,
          annotatableFileUri: annotatablesFileUri,
          metadata: _fragment.metadata,
          bodyBuilderContext: bodyBuilderContext,
          libraryBuilder: libraryBuilder,
          scope: _fragment.enclosingScope);
    }
  }

  @override
  void _buildTypeParametersAndFormalsForOutlineExpressions(
      {required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder declarationBuilder,
      required BodyBuilderContext bodyBuilderContext,
      required ClassHierarchy classHierarchy}) {
    _buildTypeParametersAndFormals(
        libraryBuilder: libraryBuilder,
        declarationBuilder: declarationBuilder,
        bodyBuilderContext: bodyBuilderContext,
        classHierarchy: classHierarchy,
        typeParameterScope: _fragment.typeParameterScope);
  }

  @override
  int get fileOffset => _fragment.fullNameOffset;

  @override
  Uri get fileUri => _fragment.fileUri;
}

class ExtensionTypePrimaryConstructorDeclaration
    with
        _ConstructorDeclarationMixin,
        _ConstructorEncodingMixin,
        _ExtensionTypeConstructorDeclarationMixin
    implements ConstructorDeclaration, ConstructorFragmentDeclaration {
  final PrimaryConstructorFragment _fragment;

  @override
  final List<SourceNominalParameterBuilder>? _typeParameters;

  @override
  final ExtensionTypeConstructorEncoding _encoding;

  @override
  Token? _beginInitializers;

  ExtensionTypePrimaryConstructorDeclaration(this._fragment,
      {required List<SourceNominalParameterBuilder>? typeParameters})
      : _typeParameters = typeParameters,
        _beginInitializers = _fragment.beginInitializers,
        _encoding = new ExtensionTypeConstructorEncoding(
            isExternal: _fragment.modifiers.isExternal) {
    _fragment.declaration = this;
  }

  @override
  void createEncoding(SourceConstructorBuilder builder) {
    _fragment.builder = builder;
  }

  @override
  LookupScope get _typeParameterScope => _fragment.typeParameterScope;

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => null;

  @override
  OmittedTypeBuilder get returnType => _fragment.returnType;

  @override
  List<FormalParameterBuilder>? get formals => _fragment.formals;

  @override
  bool get isConst => _fragment.modifiers.isConst;

  @override
  bool get isExternal => _fragment.modifiers.isExternal;

  @override
  void buildOutlineNodes(BuildNodesCallback f,
      {required SourceConstructorBuilder constructorBuilder,
      required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required ConstructorReferences? constructorReferences,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners}) {
    _encoding.buildOutlineNodes(f,
        constructorBuilder: constructorBuilder,
        libraryBuilder: libraryBuilder,
        declarationBuilder: constructorBuilder.declarationBuilder
            as SourceExtensionTypeDeclarationBuilder,
        name: _fragment.name,
        nameScheme: nameScheme,
        constructorReferences: constructorReferences,
        fileUri: _fragment.fileUri,
        fileOffset: _fragment.fileOffset,
        formalsOffset: _fragment.formalsOffset,
        // TODO(johnniwinther): Provide `endOffset`.
        endOffset: _fragment.formalsOffset,
        forAbstractClassOrEnumOrMixin: _fragment.forAbstractClassOrMixin,
        isConst: _fragment.modifiers.isConst,
        returnType: returnType,
        typeParameters: _typeParameters,
        formals: formals,
        delayedDefaultValueCloners: delayedDefaultValueCloners);
  }

  @override
  void _buildMetadataForOutlineExpressions(
      {required Iterable<Annotatable> annotatables,
      required Uri annotatablesFileUri,
      required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder declarationBuilder,
      required SourceConstructorBuilder constructorBuilder,
      required BodyBuilderContext bodyBuilderContext,
      required ClassHierarchy classHierarchy}) {
    // There is no metadata on a primary constructor.
  }

  @override
  void _buildTypeParametersAndFormalsForOutlineExpressions(
      {required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder declarationBuilder,
      required BodyBuilderContext bodyBuilderContext,
      required ClassHierarchy classHierarchy}) {
    _buildTypeParametersAndFormals(
        libraryBuilder: libraryBuilder,
        declarationBuilder: declarationBuilder,
        bodyBuilderContext: bodyBuilderContext,
        classHierarchy: classHierarchy,
        typeParameterScope: _fragment.typeParameterScope);
  }

  @override
  int get fileOffset => _fragment.fileOffset;

  @override
  Uri get fileUri => _fragment.fileUri;
}

mixin _ExtensionConstructorDeclarationMixin
    implements
        _ConstructorDeclarationMixin,
        _ConstructorEncodingMixin,
        InferredTypeListener {
  @override
  ExtensionConstructorEncoding get _encoding;

  @override
  // Coverage-ignore(suite): Not run.
  void registerFunctionBody(Statement value) {
    _encoding.registerFunctionBody(value);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void registerNoBodyConstructor() {
    _encoding.registerNoBodyConstructor();
  }

  @override
  // Coverage-ignore(suite): Not run.
  VariableDeclaration? get thisVariable => _encoding.thisVariable;

  @override
  // Coverage-ignore(suite): Not run.
  List<TypeParameter>? get thisTypeParameters => _encoding.thisTypeParameters;

  @override
  void becomeNative(SourceLoader loader) {
    throw new UnsupportedError("$runtimeType.becomeNative()");
  }

  @override
  // Coverage-ignore(suite): Not run.
  Substitution computeFieldTypeSubstitution(
      DeclarationBuilder declarationBuilder) {
    if (_typeParameters != null) {
      assert(
          declarationBuilder.typeParameters!.length == _typeParameters?.length);
      return Substitution.fromPairs(
          (declarationBuilder as SourceExtensionTypeDeclarationBuilder)
              .extensionTypeDeclaration
              .typeParameters,
          new List<DartType>.generate(
              declarationBuilder.typeParameters!.length,
              (int index) => new TypeParameterType.withDefaultNullability(
                  function.typeParameters[index])));
    } else {
      return Substitution.empty;
    }
  }

  @override
  void buildBody() {
    _encoding.buildBody();
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isRedirecting {
    for (Initializer initializer in initializers) {
      if (initializer is ExtensionTypeRedirectingInitializer) {
        return true;
      }
    }
    return false;
  }

  @override
  late final bool _hasSuperInitializingFormals =
      formals?.any((formal) => formal.isSuperInitializingFormal) ?? false;

  @override
  void _addSuperParameterDefaultValueCloners(
      {required List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
      required Member superTarget,
      required List<int?>? positionalSuperParameters,
      required List<String>? namedSuperParameters,
      required SourceLibraryBuilder libraryBuilder}) {
    throw new UnsupportedError(
        '$runtimeType.addSuperParameterDefaultValueCloners');
  }

  // Coverage-ignore(suite): Not run.
  void _buildTypeParametersAndFormals({
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder declarationBuilder,
    required BodyBuilderContext bodyBuilderContext,
    required ClassHierarchy classHierarchy,
    required LookupScope typeParameterScope,
  }) {
    if (_typeParameters != null) {
      for (int i = 0; i < _typeParameters!.length; i++) {
        _typeParameters![i].buildOutlineExpressions(
            libraryBuilder, bodyBuilderContext, classHierarchy);
      }
    }

    if (formals != null) {
      // For const constructors we need to include default parameter values
      // into the outline. For all other formals we need to call
      // buildOutlineExpressions to clear initializerToken to prevent
      // consuming too much memory.
      for (FormalParameterBuilder formal in formals!) {
        formal.buildOutlineExpressions(libraryBuilder, declarationBuilder,
            scope: typeParameterScope, buildDefaultValue: true);
      }
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  BodyBuilderContext createBodyBuilderContext(
      SourceConstructorBuilder constructorBuilder) {
    return _encoding.createBodyBuilderContext(constructorBuilder, this);
  }

  @override
  void onInferredType(DartType type) {
    function.returnType = type;
  }

  @override
  void registerInferable(Inferable inferable) {
    returnType.registerInferredTypeListener(this);
    if (formals != null) {
      for (FormalParameterBuilder formal in formals!) {
        if (formal.isInitializingFormal || formal.isSuperInitializingFormal) {
          // Coverage-ignore-block(suite): Not run.
          formal.type.registerInferable(inferable);
        }
      }
    }
  }
}

class ExtensionConstructorDeclaration
    with
        _ConstructorDeclarationMixin,
        _ConstructorEncodingMixin,
        _ExtensionConstructorDeclarationMixin
    implements ConstructorDeclaration, ConstructorFragmentDeclaration {
  final ConstructorFragment _fragment;

  @override
  final List<SourceNominalParameterBuilder>? _typeParameters;

  @override
  final ExtensionConstructorEncoding _encoding;

  @override
  Token? _beginInitializers;

  ExtensionConstructorDeclaration(this._fragment,
      {required List<SourceNominalParameterBuilder>? typeParameters})
      : _typeParameters = typeParameters,
        _beginInitializers = _fragment.beginInitializers,
        _encoding = new ExtensionConstructorEncoding(
            isExternal: _fragment.modifiers.isExternal) {
    _fragment.declaration = this;
  }

  @override
  void createEncoding(SourceConstructorBuilder builder) {
    _fragment.builder = builder;
  }

  @override
  // Coverage-ignore(suite): Not run.
  LookupScope get _typeParameterScope => _fragment.typeParameterScope;

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  OmittedTypeBuilder get returnType => _fragment.returnType;

  @override
  List<FormalParameterBuilder>? get formals => _fragment.formals;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isConst => _fragment.modifiers.isConst;

  @override
  bool get isExternal => _fragment.modifiers.isExternal;

  @override
  void buildOutlineNodes(BuildNodesCallback f,
      {required SourceConstructorBuilder constructorBuilder,
      required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required ConstructorReferences? constructorReferences,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners}) {
    _encoding.buildOutlineNodes(f,
        constructorBuilder: constructorBuilder,
        libraryBuilder: libraryBuilder,
        declarationBuilder:
            constructorBuilder.declarationBuilder as SourceExtensionBuilder,
        name: _fragment.name,
        nameScheme: nameScheme,
        constructorReferences: constructorReferences,
        fileUri: _fragment.fileUri,
        fileOffset: _fragment.fullNameOffset,
        formalsOffset: _fragment.formalsOffset,
        endOffset: _fragment.endOffset,
        forAbstractClassOrEnumOrMixin: _fragment.forAbstractClassOrMixin,
        isConst: _fragment.modifiers.isConst,
        returnType: returnType,
        typeParameters: _typeParameters,
        formals: formals,
        delayedDefaultValueCloners: delayedDefaultValueCloners);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void _buildMetadataForOutlineExpressions(
      {required Iterable<Annotatable> annotatables,
      required Uri annotatablesFileUri,
      required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder declarationBuilder,
      required SourceConstructorBuilder constructorBuilder,
      required BodyBuilderContext bodyBuilderContext,
      required ClassHierarchy classHierarchy}) {
    for (Annotatable annotatable in annotatables) {
      MetadataBuilder.buildAnnotations(
          annotatable: annotatable,
          annotatableFileUri: annotatablesFileUri,
          metadata: _fragment.metadata,
          bodyBuilderContext: bodyBuilderContext,
          libraryBuilder: libraryBuilder,
          scope: _fragment.enclosingScope);
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  void _buildTypeParametersAndFormalsForOutlineExpressions(
      {required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder declarationBuilder,
      required BodyBuilderContext bodyBuilderContext,
      required ClassHierarchy classHierarchy}) {
    _buildTypeParametersAndFormals(
        libraryBuilder: libraryBuilder,
        declarationBuilder: declarationBuilder,
        bodyBuilderContext: bodyBuilderContext,
        classHierarchy: classHierarchy,
        typeParameterScope: _fragment.typeParameterScope);
  }

  @override
  // Coverage-ignore(suite): Not run.
  int get fileOffset => _fragment.fullNameOffset;

  @override
  // Coverage-ignore(suite): Not run.
  Uri get fileUri => _fragment.fileUri;
}

/// Interface for using a [ConstructorFragment] or [PrimaryConstructorFragment]
/// to create a [BodyBuilderContext].
abstract class ConstructorFragmentDeclaration {
  int get fileOffset;

  OmittedTypeBuilder get returnType;

  List<FormalParameterBuilder>? get formals;

  BodyBuilderContext createBodyBuilderContext(
      SourceConstructorBuilder constructorBuilder);

  FunctionNode get function;

  void registerFunctionBody(Statement value);

  void registerNoBodyConstructor();

  VariableDeclaration? get thisVariable;

  List<TypeParameter>? get thisTypeParameters;

  void becomeNative(SourceLoader loader);

  /// Returns the [VariableDeclaration] for the [index]th formal parameter
  /// declared in the constructor.
  ///
  /// The synthetic parameters of enum constructor are *not* included, so index
  /// 0 zero of an enum constructor is the first user defined parameter.
  VariableDeclaration getFormalParameter(int index);

  /// Returns the [VariableDeclaration] for the tear off, if any, of the
  /// [index]th formal parameter declared in the constructor.
  VariableDeclaration? getTearOffParameter(int index);

  FormalParameterBuilder? getFormal(Identifier identifier);

  LocalScope computeFormalParameterScope(LookupScope parent);

  LocalScope computeFormalParameterInitializerScope(LocalScope parent);

  bool get isConst;

  bool get isExternal;
}

mixin _SyntheticConstructorDeclarationMixin implements ConstructorDeclaration {
  Constructor get _constructor;

  Procedure? get _constructorTearOff;

  @override
  // Coverage-ignore(suite): Not run.
  Uri get fileUri => _constructor.fileUri;

  @override
  FunctionNode get function => _constructor.function;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasParameters =>
      _constructor.function.positionalParameters.isNotEmpty ||
      _constructor.function.namedParameters.isNotEmpty;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExternal => false;

  @override
  bool get isRedirecting {
    for (Initializer initializer in _constructor.initializers) {
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
  void checkTypes(SourceLibraryBuilder libraryBuilder, NameSpace nameSpace,
      TypeEnvironment typeEnvironment) {}

  @override
  // Coverage-ignore(suite): Not run.
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    assert(false, "Unexpected call to $runtimeType.computeDefaultType");
    return 0;
  }

  @override
  void buildBody() {}

  @override
  void buildOutlineNodes(BuildNodesCallback f,
      {required SourceConstructorBuilder constructorBuilder,
      required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required ConstructorReferences? constructorReferences,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners}) {
    f(
        member: _constructor,
        tearOff: _constructorTearOff,
        kind: BuiltMemberKind.Constructor);
  }

  @override
  Substitution computeFieldTypeSubstitution(
      DeclarationBuilder declarationBuilder) {
    throw new UnsupportedError(
        "Unexpected call to $runtimeType.computeFieldTypeSubstitution");
  }

  @override
  List<Initializer> get initializers {
    throw new UnsupportedError("Unexpected call to $runtimeType.initializers");
  }

  @override
  void prepareInitializers() {
    throw new UnsupportedError(
        "Unexpected call to $runtimeType.prepareInitializers");
  }

  @override
  void prependInitializer(Initializer initializer) {
    throw new UnsupportedError(
        "Unexpected call to $runtimeType.prependInitializer");
  }

  @override
  void registerInferable(Inferable inferable) {}
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
  })  : this._constructor = constructor,
        this._constructorTearOff = constructorTearOff;

  @override
  // Coverage-ignore(suite): Not run.
  void createEncoding(SourceConstructorBuilder builder) {}

  @override
  void addSuperParameterDefaultValueCloners(
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder declarationBuilder,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {}

  @override
  void buildOutlineExpressions(
      {required Iterable<Annotatable> annotatables,
      required Uri annotatablesFileUri,
      required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder declarationBuilder,
      required SourceConstructorBuilder constructorBuilder,
      required ClassHierarchy classHierarchy,
      required List<DelayedDefaultValueCloner> delayedDefaultValueCloners}) {}

  @override
  void inferFormalTypes(
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder declarationBuilder,
      SourceConstructorBuilder constructorBuilder,
      ClassHierarchyBase hierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {}
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
  })  : _constructor = constructor,
        _constructorTearOff = constructorTearOff,
        _immediatelyDefiningConstructor = definingConstructor,
        _delayedDefaultValueCloner = delayedDefaultValueCloner,
        _typeDependency = typeDependency;

  @override
  // Coverage-ignore(suite): Not run.
  void createEncoding(SourceConstructorBuilder builder) {}

  @override
  void addSuperParameterDefaultValueCloners(
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder declarationBuilder,
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
            classHierarchy, delayedDefaultValueCloners);
      }
      addSuperParameterDefaultValueCloners(
          libraryBuilder, declarationBuilder, delayedDefaultValueCloners);
      _immediatelyDefiningConstructor = null;
    }
  }

  @override
  void inferFormalTypes(
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder declarationBuilder,
      SourceConstructorBuilder constructorBuilder,
      ClassHierarchyBase hierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
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
