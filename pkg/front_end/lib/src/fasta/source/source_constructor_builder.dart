// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../builder/builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/type_builder.dart';
import '../constant_context.dart' show ConstantContext;
import '../dill/dill_member_builder.dart';
import '../identifiers.dart';
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
        finishConstructorPatch,
        finishProcedurePatch;
import '../messages.dart'
    show
        LocatedMessage,
        Message,
        messageMoreThanOneSuperInitializer,
        messageRedirectingConstructorWithAnotherInitializer,
        messageRedirectingConstructorWithMultipleRedirectInitializers,
        messageRedirectingConstructorWithSuperInitializer,
        messageSuperInitializerNotLast,
        noLength;
import '../scope.dart';
import '../source/source_class_builder.dart';
import '../source/source_enum_builder.dart';
import '../source/source_library_builder.dart' show SourceLibraryBuilder;
import '../source/source_loader.dart' show SourceLoader;
import '../source/source_member_builder.dart';
import '../type_inference/inference_results.dart';
import '../type_inference/type_schema.dart';
import '../util/helpers.dart' show DelayedActionPerformer;
import 'class_declaration.dart';
import 'constructor_declaration.dart';
import 'name_scheme.dart';
import 'source_extension_type_declaration_builder.dart';
import 'source_field_builder.dart';
import 'source_function_builder.dart';

abstract class SourceConstructorBuilder
    implements ConstructorBuilder, SourceMemberBuilder {
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
      int modifiers,
      this.returnType,
      String name,
      List<TypeVariableBuilder>? typeVariables,
      List<FormalParameterBuilder>? formals,
      SourceLibraryBuilder compilationUnit,
      int charOffset,
      this.charOpenParenOffset,
      String? nativeMethodName)
      : super(metadata, modifiers, name, typeVariables, formals,
            compilationUnit, charOffset, nativeMethodName) {
    if (formals != null) {
      for (FormalParameterBuilder formal in formals) {
        if (formal.isInitializingFormal || formal.isSuperInitializingFormal) {
          formal.type.registerInferable(this);
        }
      }
    }
  }

  @override
  DeclarationBuilder get declarationBuilder => super.declarationBuilder!;

  @override
  bool get isConstructor => true;

  @override
  ProcedureKind? get kind => null;

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
      libraryBuilder.loader.withUriForCrashReporting(fileUri, charOffset, () {
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

  @override
  List<Initializer> get initializers;

  void _injectInvalidInitializer(Message message, int charOffset, int length,
      ExpressionGeneratorHelper helper) {
    Initializer lastInitializer = initializers.removeLast();
    assert(lastInitializer == superInitializer ||
        lastInitializer == redirectingInitializer);
    Initializer error = helper.buildInvalidInitializer(
        helper.buildProblem(message, charOffset, length));
    initializers.add(error..parent = member);
    initializers.add(lastInitializer);
  }

  SuperInitializer? superInitializer;

  RedirectingInitializer? redirectingInitializer;

  @override
  void addInitializer(Initializer initializer, ExpressionGeneratorHelper helper,
      {required InitializerInferenceResult? inferenceResult}) {
    if (initializer is SuperInitializer) {
      if (superInitializer != null) {
        _injectInvalidInitializer(messageMoreThanOneSuperInitializer,
            initializer.fileOffset, "super".length, helper);
      } else if (redirectingInitializer != null) {
        _injectInvalidInitializer(
            messageRedirectingConstructorWithSuperInitializer,
            initializer.fileOffset,
            "super".length,
            helper);
      } else {
        inferenceResult?.applyResult(initializers, member);
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
            ..parent = member);
        } else {
          initializers.add(initializer..parent = member);
        }
      }
    } else if (initializer is RedirectingInitializer) {
      if (superInitializer != null) {
        // Point to the existing super initializer.
        _injectInvalidInitializer(
            messageRedirectingConstructorWithSuperInitializer,
            superInitializer!.fileOffset,
            "super".length,
            helper);
      } else if (redirectingInitializer != null) {
        _injectInvalidInitializer(
            messageRedirectingConstructorWithMultipleRedirectInitializers,
            initializer.fileOffset,
            noLength,
            helper);
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
          error.parent = member;
          initializers[i] = error;
        }
        inferenceResult?.applyResult(initializers, member);
        initializers.add(initializer..parent = member);
        redirectingInitializer = initializer;
      } else {
        inferenceResult?.applyResult(initializers, member);
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
            ..parent = member);
        } else {
          initializers.add(initializer..parent = member);
        }
      }
    } else if (redirectingInitializer != null) {
      int length = noLength;
      if (initializer is AssertInitializer) length = "assert".length;
      _injectInvalidInitializer(
          messageRedirectingConstructorWithAnotherInitializer,
          initializer.fileOffset,
          length,
          helper);
    } else if (superInitializer != null) {
      _injectInvalidInitializer(messageSuperInitializerNotLast,
          initializer.fileOffset, noLength, helper);
    } else {
      inferenceResult?.applyResult(initializers, member);
      initializers.add(initializer..parent = member);
    }
  }

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

  @override
  void checkTypes(
      SourceLibraryBuilder library, TypeEnvironment typeEnvironment) {
    library.checkTypesInConstructorBuilder(this, formals, typeEnvironment);
  }

  @override
  List<ClassMember> get localMembers =>
      throw new UnsupportedError('${runtimeType}.localMembers');

  @override
  List<ClassMember> get localSetters =>
      throw new UnsupportedError('${runtimeType}.localSetters');
}

class DeclaredSourceConstructorBuilder
    extends AbstractSourceConstructorBuilder {
  late final Constructor _constructor;
  late final Procedure? _constructorTearOff;

  Set<SourceFieldBuilder>? _initializedFields;

  DeclaredSourceConstructorBuilder? actualOrigin;

  Constructor get actualConstructor => _constructor;

  List<DeclaredSourceConstructorBuilder>? _patches;

  bool _hasDefaultValueCloner = false;

  @override
  List<FormalParameterBuilder>? formals;

  @override
  String get fullNameForErrors {
    return "${flattenName(declarationBuilder.name, charOffset, fileUri)}"
        "${name.isEmpty ? '' : '.$name'}";
  }

  DeclaredSourceConstructorBuilder(
      List<MetadataBuilder>? metadata,
      int modifiers,
      OmittedTypeBuilder returnType,
      String name,
      List<TypeVariableBuilder>? typeVariables,
      this.formals,
      SourceLibraryBuilder compilationUnit,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      Reference? constructorReference,
      Reference? tearOffReference,
      NameScheme nameScheme,
      {String? nativeMethodName,
      required bool forAbstractClassOrEnumOrMixin})
      : _hasSuperInitializingFormals =
            formals?.any((formal) => formal.isSuperInitializingFormal) ?? false,
        super(
            metadata,
            modifiers,
            returnType,
            name,
            typeVariables,
            formals,
            compilationUnit,
            charOffset,
            charOpenParenOffset,
            nativeMethodName) {
    _constructor = new Constructor(new FunctionNode(null),
        name: dummyName,
        fileUri: compilationUnit.fileUri,
        reference: constructorReference)
      ..startFileOffset = startCharOffset
      ..fileOffset = charOffset
      ..fileEndOffset = charEndOffset
      ..isNonNullableByDefault = compilationUnit.isNonNullableByDefault;
    nameScheme
        .getConstructorMemberName(name, isTearOff: false)
        .attachMember(_constructor);
    _constructorTearOff = createConstructorTearOffProcedure(
        nameScheme.getConstructorMemberName(name, isTearOff: true),
        compilationUnit,
        compilationUnit.fileUri,
        charOffset,
        tearOffReference,
        forAbstractClassOrEnumOrMixin: forAbstractClassOrEnumOrMixin);
  }

  @override
  ClassDeclaration get classDeclaration => classBuilder;

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
  Member? get writeTarget => null;

  @override
  Member get invokeTarget => constructor;

  @override
  FunctionNode get function => _constructor.function;

  @override
  Iterable<Member> get exportedMembers => [constructor];

  @override
  List<Initializer> get initializers => _constructor.initializers;

  @override
  DeclaredSourceConstructorBuilder get origin => actualOrigin ?? this;

  List<SourceConstructorBuilder>? get patchForTesting => _patches;

  @override
  bool get isDeclarationInstanceMember => false;

  @override
  bool get isClassInstanceMember => false;

  @override
  bool get isEffectivelyExternal {
    bool isExternal = this.isExternal;
    if (isExternal) {
      List<SourceConstructorBuilder>? patches = _patches;
      if (patches != null) {
        for (SourceConstructorBuilder patch in patches) {
          isExternal &= patch.isExternal;
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
      List<SourceConstructorBuilder>? patches = _patches;
      if (patches != null) {
        for (SourceConstructorBuilder patch in patches) {
          isRedirecting |= patch.isRedirecting;
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
        buildConstructorTearOffProcedure(
            tearOff: _constructorTearOff,
            declarationConstructor: constructor,
            implementationConstructor: _constructor,
            enclosingDeclarationTypeParameters: classBuilder.cls.typeParameters,
            libraryBuilder: libraryBuilder);
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
    if (supertype is NamedTypeBuilder) {
      TypeDeclarationBuilder? declaration = supertype.declaration;
      if (declaration is ClassBuilder) {
        superclassBuilder = declaration;
      } else if (declaration is TypeAliasBuilder) {
        declaration = declaration.unaliasDeclaration(supertype.arguments);
        if (declaration is ClassBuilder) {
          superclassBuilder = declaration;
        } else {
          // The error in this case should be reported elsewhere.
          return null;
        }
      } else {
        // The error in this case should be reported elsewhere.
        return null;
      }
    } else {
      // The error in this case should be reported elsewhere.
      return null;
    }

    if (initializers != null &&
        initializers.isNotEmpty &&
        initializers.last is SuperInitializer) {
      superTarget = (initializers.last as SuperInitializer).target;
    } else {
      MemberBuilder? memberBuilder = superclassBuilder.constructorScope
          .lookup("", charOffset, libraryBuilder.fileUri);
      if (memberBuilder is ConstructorBuilder) {
        superTarget = memberBuilder.invokeTarget;
      } else {
        // The error in this case should be reported elsewhere.
        return null;
      }
    }

    MemberBuilder? constructorBuilder =
        superclassBuilder.findConstructorOrFactory(superTarget.name.text,
            charOffset, libraryBuilder.fileUri, libraryBuilder);
    return constructorBuilder is ConstructorBuilder ? constructorBuilder : null;
  }

  final bool _hasSuperInitializingFormals;

  final List<DelayedDefaultValueCloner> _superParameterDefaultValueCloners =
      <DelayedDefaultValueCloner>[];

  @override
  void _inferSuperInitializingFormals(ClassHierarchyBase hierarchy) {
    if (_hasSuperInitializingFormals) {
      List<Initializer>? initializers;
      if (beginInitializers != null) {
        BodyBuilder bodyBuilder = libraryBuilder.loader
            .createBodyBuilderForOutlineExpression(libraryBuilder,
                bodyBuilderContext, declarationBuilder.scope, fileUri);
        if (isConst) {
          bodyBuilder.constantContext = ConstantContext.required;
        }
        initializers = bodyBuilder.parseInitializers(beginInitializers!,
            doFinishConstructor: false);
      }
      finalizeSuperInitializingFormals(
          hierarchy, _superParameterDefaultValueCloners, initializers);
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
      // The error in this case should be reported elsewhere. Here we perform a
      // simple recovery.
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
            // The error is reported elsewhere.
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
            superTarget, constructor, substitution,
            positionalSuperParameters:
                positionalSuperParameters ?? const <int>[],
            namedSuperParameters: namedSuperParameters ?? const <String>[],
            isOutlineNode: true,
            libraryBuilder: libraryBuilder));
        if (_constructorTearOff != null) {
          delayedDefaultValueCloners.add(new DelayedDefaultValueCloner(
              superTarget, _constructorTearOff, substitution,
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
  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (_hasBuiltOutlines) return;
    if (isConst && isPatch) {
      origin.buildOutlineExpressions(
          classHierarchy, delayedActionPerformers, delayedDefaultValueCloners);
    }
    super.buildOutlineExpressions(
        classHierarchy, delayedActionPerformers, delayedDefaultValueCloners);

    // For modular compilation purposes we need to include initializers
    // for const constructors into the outline. We also need to parse
    // initializers to infer types of the super-initializing parameters.
    if ((isConst || _hasSuperInitializingFormals) &&
        beginInitializers != null) {
      final Scope? formalParameterScope;
      if (isConst) {
        // We're going to fully build the constructor so we need scopes.
        formalParameterScope = computeFormalParameterInitializerScope(
            computeFormalParameterScope(
                computeTypeParameterScope(declarationBuilder.scope)));
      } else {
        formalParameterScope = null;
      }
      BodyBuilder bodyBuilder = libraryBuilder.loader
          .createBodyBuilderForOutlineExpression(
              libraryBuilder, bodyBuilderContext, classBuilder.scope, fileUri,
              formalParameterScope: formalParameterScope);
      if (isConst) {
        bodyBuilder.constantContext = ConstantContext.required;
      }
      bodyBuilder.parseInitializers(beginInitializers!,
          doFinishConstructor: isConst);
      bodyBuilder.performBacklogComputations(
          delayedActionPerformers: delayedActionPerformers,
          allowFurtherDelays: false);
    }
    beginInitializers = null;
    addSuperParameterDefaultValueCloners(delayedDefaultValueCloners);
    if (isConst && isPatch) {
      _finishPatch();
    }
    _hasBuiltOutlines = true;
  }

  @override
  void addSuperParameterDefaultValueCloners(
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    ConstructorBuilder? superTargetBuilder =
        _computeSuperTargetBuilder(constructor.initializers);
    if (superTargetBuilder is SourceConstructorBuilder) {
      superTargetBuilder
          .addSuperParameterDefaultValueCloners(delayedDefaultValueCloners);
    }

    delayedDefaultValueCloners.addAll(_superParameterDefaultValueCloners);
    _superParameterDefaultValueCloners.clear();
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
      typeParameterTypes.add(
          new TypeParameterType.withDefaultNullabilityForLibrary(
              typeParameter, libraryBuilder.library));
    }
    InterfaceType type = new InterfaceType(
        enclosingClass, libraryBuilder.nonNullable, typeParameterTypes);
    returnType.registerInferredType(type);
  }

  Constructor get constructor => isPatch ? origin.constructor : _constructor;

  @override
  Member get member => constructor;

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    if (_constructorTearOff != null) {
      if (index < _constructorTearOff.function.positionalParameters.length) {
        return _constructorTearOff.function.positionalParameters[index];
      } else {
        index -= _constructorTearOff.function.positionalParameters.length;
        if (index < _constructorTearOff.function.namedParameters.length) {
          return _constructorTearOff.function.namedParameters[index];
        }
      }
    }
    return null;
  }

  void _finishPatch() {
    finishConstructorPatch(origin.constructor, _constructor);

    if (_constructorTearOff != null) {
      finishProcedurePatch(origin._constructorTearOff!, _constructorTearOff);
    }
  }

  @override
  int buildBodyNodes(BuildNodesCallback f) {
    if (!isPatch) return 0;
    _finishPatch();
    return 1;
  }

  List<DeclaredSourceConstructorBuilder>? get patchesForTesting => _patches;

  @override
  void becomeNative(SourceLoader loader) {
    _constructor.isExternal = true;
    super.becomeNative(loader);
  }

  @override
  void applyPatch(Builder patch) {
    if (patch is DeclaredSourceConstructorBuilder) {
      if (checkPatch(patch)) {
        patch.actualOrigin = this;
        (_patches ??= []).add(patch);
      }
    } else {
      reportPatchMismatch(patch);
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
  void registerInitializedField(SourceFieldBuilder fieldBuilder) {
    if (isPatch) {
      origin.registerInitializedField(fieldBuilder);
    } else {
      (_initializedFields ??= {}).add(fieldBuilder);
    }
  }

  @override
  Set<SourceFieldBuilder>? takeInitializedFields() {
    Set<SourceFieldBuilder>? result = _initializedFields;
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
  void checkTypes(
      SourceLibraryBuilder library, TypeEnvironment typeEnvironment) {
    super.checkTypes(library, typeEnvironment);
    List<DeclaredSourceConstructorBuilder>? patches = _patches;
    if (patches != null) {
      for (DeclaredSourceConstructorBuilder patch in patches) {
        patch.checkTypes(library, typeEnvironment);
      }
    }
  }

  @override
  DartType substituteFieldType(DartType fieldType) {
    // Nothing to do. Regular generative constructors don't have their own
    // type variables.
    return fieldType;
  }

  @override
  BodyBuilderContext get bodyBuilderContext =>
      new ConstructorBodyBuilderContext(this);

  // TODO(johnniwinther): Add annotations to tear-offs.
  @override
  Iterable<Annotatable> get annotatables => [constructor];

  @override
  bool get isAugmented {
    if (isPatch) {
      return origin._patches!.last != this;
    } else {
      return _patches != null;
    }
  }
}

class SyntheticSourceConstructorBuilder extends DillConstructorBuilder
    with SourceMemberBuilderMixin
    implements SourceConstructorBuilder {
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

  SyntheticSourceConstructorBuilder(SourceClassBuilder parent,
      Constructor constructor, Procedure? constructorTearOff,
      {MemberBuilder? definingConstructor,
      DelayedDefaultValueCloner? delayedDefaultValueCloner,
      TypeDependency? typeDependency})
      : _immediatelyDefiningConstructor = definingConstructor,
        _delayedDefaultValueCloner = delayedDefaultValueCloner,
        _typeDependency = typeDependency,
        super(constructor, constructorTearOff, parent);

  @override
  SourceLibraryBuilder get libraryBuilder =>
      super.libraryBuilder as SourceLibraryBuilder;

  @override
  DeclarationBuilder get declarationBuilder => classBuilder!;

  @override
  bool get isRedirecting {
    for (Initializer initializer in constructor.initializers) {
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

  MemberBuilder? get _effectivelyDefiningConstructor {
    MemberBuilder? origin = _immediatelyDefiningConstructor;
    while (origin is SyntheticSourceConstructorBuilder) {
      origin = origin._immediatelyDefiningConstructor;
    }
    return origin;
  }

  List<FormalParameterBuilder>? get formals {
    MemberBuilder? origin = _effectivelyDefiningConstructor;
    return origin is DeclaredSourceConstructorBuilder ? origin.formals : null;
  }

  @override
  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (_immediatelyDefiningConstructor != null) {
      // Ensure that default value expressions have been created for [_origin].
      // If [_origin] is from a source library, we need to build the default
      // values and initializers first.
      MemberBuilder origin = _immediatelyDefiningConstructor!;
      if (origin is SourceConstructorBuilder) {
        origin.buildOutlineExpressions(classHierarchy, delayedActionPerformers,
            delayedDefaultValueCloners);
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
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

  @override
  void checkTypes(
      SourceLibraryBuilder library, TypeEnvironment typeEnvironment) {}
}

class SourceExtensionTypeConstructorBuilder
    extends AbstractSourceConstructorBuilder {
  late final Procedure _constructor;
  late final Procedure? _constructorTearOff;

  Set<SourceFieldBuilder>? _initializedFields;

  @override
  List<Initializer> initializers = [];

  SourceExtensionTypeConstructorBuilder(
      List<MetadataBuilder>? metadata,
      int modifiers,
      OmittedTypeBuilder returnType,
      String name,
      List<TypeVariableBuilder>? typeVariables,
      List<FormalParameterBuilder>? formals,
      SourceLibraryBuilder compilationUnit,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      Reference? constructorReference,
      Reference? tearOffReference,
      NameScheme nameScheme,
      {String? nativeMethodName,
      required bool forAbstractClassOrEnumOrMixin})
      : super(
            metadata,
            modifiers,
            returnType,
            name,
            typeVariables,
            formals,
            compilationUnit,
            charOffset,
            charOpenParenOffset,
            nativeMethodName) {
    _constructor = new Procedure(
        dummyName, ProcedureKind.Method, new FunctionNode(null),
        fileUri: compilationUnit.fileUri, reference: constructorReference)
      ..fileOffset = charOffset
      ..fileEndOffset = charEndOffset
      ..isNonNullableByDefault = compilationUnit.isNonNullableByDefault;
    nameScheme
        .getConstructorMemberName(name, isTearOff: false)
        .attachMember(_constructor);
    _constructorTearOff = createConstructorTearOffProcedure(
        nameScheme.getConstructorMemberName(name, isTearOff: true),
        compilationUnit,
        compilationUnit.fileUri,
        charOffset,
        tearOffReference,
        forAbstractClassOrEnumOrMixin: forAbstractClassOrEnumOrMixin,
        forceCreateLowering: true)
      ?..isExtensionTypeMember = true;
  }

  @override
  ClassDeclaration get classDeclaration => extensionTypeDeclarationBuilder;

  SourceExtensionTypeDeclarationBuilder get extensionTypeDeclarationBuilder =>
      parent as SourceExtensionTypeDeclarationBuilder;

  @override
  Member get member => _constructor;

  @override
  Member get readTarget => _constructorTearOff ?? _constructor;

  @override
  Member? get writeTarget => null;

  @override
  Member get invokeTarget => _constructor;

  @override
  FunctionNode get function => _constructor.function;

  @override
  Iterable<Member> get exportedMembers => [_constructor];

  @override
  void addSuperParameterDefaultValueCloners(
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {}

  @override
  void _inferSuperInitializingFormals(ClassHierarchyBase hierarchy) {}

  @override
  int buildBodyNodes(BuildNodesCallback f) {
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
        extensionTypeDeclarationBuilder.extensionTypeDeclaration;
    List<DartType> typeParameterTypes = <DartType>[];
    for (int i = 0; i < function.typeParameters.length; i++) {
      TypeParameter typeParameter = function.typeParameters[i];
      typeParameterTypes.add(
          new TypeParameterType.withDefaultNullabilityForLibrary(
              typeParameter, libraryBuilder.library));
    }
    ExtensionType type = new ExtensionType(extensionTypeDeclaration,
        libraryBuilder.nonNullable, typeParameterTypes);
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
        buildConstructorTearOffProcedure(
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
  void registerInitializedField(SourceFieldBuilder fieldBuilder) {
    (_initializedFields ??= {}).add(fieldBuilder);
  }

  @override
  Set<SourceFieldBuilder>? takeInitializedFields() {
    Set<SourceFieldBuilder>? result = _initializedFields;
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
    if (typeVariables != null) {
      assert(extensionTypeDeclarationBuilder.typeParameters!.length ==
          typeVariables?.length);
      _substitutionCache = Substitution.fromPairs(
          extensionTypeDeclarationBuilder
              .extensionTypeDeclaration.typeParameters,
          new List<DartType>.generate(
              extensionTypeDeclarationBuilder.typeParameters!.length,
              (int index) =>
                  new TypeParameterType.withDefaultNullabilityForLibrary(
                      function.typeParameters[index],
                      libraryBuilder.origin.library)));
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
  BodyBuilderContext get bodyBuilderContext =>
      new ExtensionTypeConstructorBodyBuilderContext(this);

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
    }
    throw new UnsupportedError(
        "Unexpected initializer $node (${node.runtimeType})");
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    statements.add(node.statement);
  }

  @override
  void visitFieldInitializer(FieldInitializer node) {
    thisVariable
      ..initializer = (node.value..parent = thisVariable)
      ..fileOffset = node.fileOffset;
  }

  @override
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
  void visitSuperInitializer(SuperInitializer node) {
    // TODO(johnniwinther): Report error for this case.
  }
}
