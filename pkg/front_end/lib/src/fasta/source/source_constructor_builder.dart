// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../builder/builder.dart';
import '../builder/class_builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/library_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/type_alias_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_declaration_builder.dart';
import '../builder/type_variable_builder.dart';
import '../constant_context.dart' show ConstantContext;
import '../dill/dill_member_builder.dart';
import '../identifiers.dart';
import '../kernel/body_builder.dart' show BodyBuilder;
import '../kernel/constructor_tearoff_lowering.dart';
import '../kernel/expression_generator_helper.dart';
import '../kernel/hierarchy/class_member.dart' show ClassMember;
import '../kernel/kernel_helper.dart' show DelayedDefaultValueCloner;
import '../kernel/utils.dart'
    show isRedirectingGenerativeConstructorImplementation;
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
import '../source/source_library_builder.dart' show SourceLibraryBuilder;
import '../source/source_loader.dart' show SourceLoader;
import '../source/source_member_builder.dart';
import '../type_inference/type_inferrer.dart';
import '../type_inference/type_schema.dart';
import '../util/helpers.dart' show DelayedActionPerformer;
import 'source_field_builder.dart';
import 'source_function_builder.dart';

abstract class SourceConstructorBuilder
    implements ConstructorBuilder, SourceMemberBuilder {}

class DeclaredSourceConstructorBuilder extends SourceFunctionBuilderImpl
    implements SourceConstructorBuilder {
  final Constructor _constructor;
  final Procedure? _constructorTearOff;

  Set<SourceFieldBuilder>? _initializedFields;

  final int charOpenParenOffset;

  bool hasMovedSuperInitializer = false;

  SuperInitializer? superInitializer;

  RedirectingInitializer? redirectingInitializer;

  Token? beginInitializers;

  DeclaredSourceConstructorBuilder? actualOrigin;

  Constructor get actualConstructor => _constructor;

  List<DeclaredSourceConstructorBuilder>? _patches;

  bool _hasFormalsInferred = false;

  final bool _hasSuperInitializingFormals;

  final List<DelayedDefaultValueCloner> _superParameterDefaultValueCloners =
      <DelayedDefaultValueCloner>[];

  @override
  List<FormalParameterBuilder>? formals;

  @override
  String get fullNameForErrors {
    return "${flattenName(classBuilder.name, charOffset, fileUri)}"
        "${name.isEmpty ? '' : '.$name'}";
  }

  DeclaredSourceConstructorBuilder(
      List<MetadataBuilder>? metadata,
      int modifiers,
      TypeBuilder? returnType,
      String name,
      List<TypeVariableBuilder>? typeVariables,
      this.formals,
      SourceLibraryBuilder compilationUnit,
      int startCharOffset,
      int charOffset,
      this.charOpenParenOffset,
      int charEndOffset,
      Reference? constructorReference,
      Reference? tearOffReference,
      {String? nativeMethodName,
      required bool forAbstractClassOrEnum})
      : _constructor = new Constructor(new FunctionNode(null),
            name: new Name(name, compilationUnit.library),
            fileUri: compilationUnit.fileUri,
            reference: constructorReference)
          ..startFileOffset = startCharOffset
          ..fileOffset = charOffset
          ..fileEndOffset = charEndOffset
          ..isNonNullableByDefault = compilationUnit.isNonNullableByDefault,
        _constructorTearOff = createConstructorTearOffProcedure(
            name,
            compilationUnit,
            compilationUnit.fileUri,
            charOffset,
            tearOffReference,
            forAbstractClassOrEnum: forAbstractClassOrEnum),
        _hasSuperInitializingFormals =
            formals?.any((formal) => formal.isSuperInitializingFormal) ?? false,
        super(metadata, modifiers, returnType, name, typeVariables, formals,
            compilationUnit, charOffset, nativeMethodName);

  @override
  SourceClassBuilder get classBuilder =>
      super.classBuilder as SourceClassBuilder;

  @override
  Member? get readTarget => _constructorTearOff ?? _constructor;

  @override
  Member? get writeTarget => null;

  @override
  Member get invokeTarget => constructor;

  @override
  FunctionNode get function => _constructor.function;

  @override
  Iterable<Member> get exportedMembers => [constructor];

  @override
  DeclaredSourceConstructorBuilder get origin => actualOrigin ?? this;

  List<SourceConstructorBuilder>? get patchForTesting => _patches;

  @override
  bool get isDeclarationInstanceMember => false;

  @override
  bool get isClassInstanceMember => false;

  @override
  bool get isConstructor => true;

  @override
  AsyncMarker get asyncModifier => AsyncMarker.Sync;

  @override
  ProcedureKind? get kind => null;

  @override
  bool get isRedirectingGenerativeConstructor {
    return isRedirectingGenerativeConstructorImplementation(_constructor);
  }

  @override
  void buildMembers(
      SourceLibraryBuilder library, void Function(Member, BuiltMemberKind) f) {
    Member member = build(library);
    f(member, BuiltMemberKind.Constructor);
    if (_constructorTearOff != null) {
      f(_constructorTearOff!, BuiltMemberKind.Method);
    }
  }

  bool _hasBeenBuilt = false;

  @override
  Constructor build(SourceLibraryBuilder sourceLibraryBuilder) {
    if (!_hasBeenBuilt) {
      buildFunction(sourceLibraryBuilder);
      _constructor.function.fileOffset = charOpenParenOffset;
      _constructor.function.fileEndOffset = _constructor.fileEndOffset;
      _constructor.function.typeParameters = const <TypeParameter>[];
      _constructor.isConst = isConst;
      _constructor.isExternal = isExternal;
      updatePrivateMemberName(_constructor, sourceLibraryBuilder);

      if (_constructorTearOff != null) {
        buildConstructorTearOffProcedure(_constructorTearOff!, _constructor,
            classBuilder.cls, sourceLibraryBuilder);
      }

      _hasBeenBuilt = true;
    }
    if (formals != null) {
      bool needsInference = false;
      for (FormalParameterBuilder formal in formals!) {
        if (formal.type == null &&
            (formal.isInitializingFormal || formal.isSuperInitializingFormal)) {
          formal.variable!.type = const UnknownType();
          needsInference = true;
        } else if (!formal.hasDeclaredInitializer &&
            formal.isSuperInitializingFormal) {
          needsInference = true;
        }
      }
      if (needsInference) {
        assert(
            libraryBuilder == sourceLibraryBuilder,
            "Unexpected library builder ${sourceLibraryBuilder} for"
            " constructor $this in ${libraryBuilder}.");
        sourceLibraryBuilder.loader
            .registerConstructorToBeInferred(_constructor, this);
      }
    }
    return _constructor;
  }

  /// Infers the types of any untyped initializing formals.
  void inferFormalTypes(TypeEnvironment typeEnvironment) {
    if (_hasFormalsInferred) return;
    if (formals != null) {
      for (FormalParameterBuilder formal in formals!) {
        if (formal.type == null) {
          if (formal.isInitializingFormal) {
            formal.finalizeInitializingFormal(classBuilder);
          }
        }
      }

      if (_hasSuperInitializingFormals) {
        List<Initializer>? initializers;
        if (beginInitializers != null) {
          BodyBuilder bodyBuilder = libraryBuilder.loader
              .createBodyBuilderForOutlineExpression(libraryBuilder,
                  classBuilder, this, classBuilder.scope, fileUri);
          bodyBuilder.constantContext = ConstantContext.required;
          initializers = bodyBuilder.parseInitializers(beginInitializers!,
              doFinishConstructor: false);
        }
        finalizeSuperInitializingFormals(
            typeEnvironment, _superParameterDefaultValueCloners, initializers);
      }
    }
    _hasFormalsInferred = true;
  }

  ConstructorBuilder? _computeSuperTargetBuilder(
      List<Initializer>? initializers) {
    Constructor superTarget;
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
        superTarget = memberBuilder.constructor;
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

  void finalizeSuperInitializingFormals(
      TypeEnvironment typeEnvironment,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners,
      List<Initializer>? initializers) {
    if (formals == null) return;
    if (!_hasSuperInitializingFormals) return;

    void performRecoveryForErroneousCase() {
      for (FormalParameterBuilder formal in formals!) {
        if (formal.isSuperInitializingFormal) {
          formal.variable!.type = const DynamicType();
        }
      }
    }

    ConstructorBuilder? superTargetBuilder =
        _computeSuperTargetBuilder(initializers);
    Constructor superTarget;
    List<FormalParameterBuilder>? superFormals;
    if (superTargetBuilder is DeclaredSourceConstructorBuilder) {
      superTarget = superTargetBuilder.constructor;
      superFormals = superTargetBuilder.formals!;
    } else if (superTargetBuilder is DillConstructorBuilder) {
      superTarget = superTargetBuilder.constructor;
      if (superTargetBuilder is SyntheticSourceConstructorBuilder) {
        superFormals = superTargetBuilder.formals;
      } else {
        // The error in this case should be reported elsewhere. Here we perform
        // a simple recovery.
        return performRecoveryForErroneousCase();
      }
    } else {
      // The error in this case should be reported elsewhere. Here we perform a
      // simple recovery.
      return performRecoveryForErroneousCase();
    }

    if (superFormals == null) {
      // The error in this case should be reported elsewhere. Here we perform a
      // simple recovery.
      return performRecoveryForErroneousCase();
    }

    if (superTargetBuilder is DeclaredSourceConstructorBuilder) {
      superTargetBuilder.inferFormalTypes(typeEnvironment);
    } else if (superTargetBuilder is SyntheticSourceConstructorBuilder) {
      MemberBuilder? superTargetOriginBuilder = superTargetBuilder.actualOrigin;
      if (superTargetOriginBuilder is DeclaredSourceConstructorBuilder) {
        superTargetOriginBuilder.inferFormalTypes(typeEnvironment);
      }
    }

    int superInitializingFormalIndex = -1;
    List<int?>? positionalSuperParameters;
    List<String>? namedSuperParameters;

    Supertype? supertype = typeEnvironment.hierarchy
        .getClassAsInstanceOf(classBuilder.cls, superTarget.enclosingClass);
    assert(supertype != null);
    Map<TypeParameter, DartType> substitution =
        new Map<TypeParameter, DartType>.fromIterables(
            supertype!.classNode.typeParameters, supertype.typeArguments);

    for (int formalIndex = 0; formalIndex < formals!.length; formalIndex++) {
      FormalParameterBuilder formal = formals![formalIndex];
      if (formal.isSuperInitializingFormal) {
        superInitializingFormalIndex++;
        bool hasImmediatelyDeclaredInitializer = formal.hasDeclaredInitializer;

        FormalParameterBuilder? correspondingSuperFormal;

        if (formal.isPositional) {
          if (superInitializingFormalIndex < superFormals.length) {
            correspondingSuperFormal =
                superFormals[superInitializingFormalIndex];
            formal.hasDeclaredInitializer = hasImmediatelyDeclaredInitializer ||
                correspondingSuperFormal.hasDeclaredInitializer;
            if (!hasImmediatelyDeclaredInitializer && !formal.isRequired) {
              (positionalSuperParameters ??= <int?>[]).add(formalIndex);
            } else {
              (positionalSuperParameters ??= <int?>[]).add(null);
            }
          } else {
            // TODO(cstefantsova): Report an error.
          }
        } else {
          for (FormalParameterBuilder superFormal in superFormals) {
            if (superFormal.isNamed && superFormal.name == formal.name) {
              correspondingSuperFormal = superFormal;
              break;
            }
          }

          if (correspondingSuperFormal != null) {
            formal.hasDeclaredInitializer = hasImmediatelyDeclaredInitializer ||
                correspondingSuperFormal.hasDeclaredInitializer;
            if (!hasImmediatelyDeclaredInitializer && !formal.isNamedRequired) {
              (namedSuperParameters ??= <String>[]).add(formal.name);
            }
          } else {
            // TODO(cstefantsova): Report an error.
          }
        }

        if (formal.type == null) {
          DartType? type = correspondingSuperFormal?.variable?.type;
          if (substitution.isNotEmpty && type != null) {
            type = substitute(type, substitution);
          }
          formal.variable!.type = type ?? const DynamicType();
        }
      }
    }

    if (positionalSuperParameters != null || namedSuperParameters != null) {
      delayedDefaultValueCloners.add(new DelayedDefaultValueCloner(
          substitution, superTarget.function, constructor.function,
          positionalSuperParameters: positionalSuperParameters ?? const <int>[],
          namedSuperParameters: namedSuperParameters ?? const <String>[],
          isOutlineNode: true,
          libraryBuilder: libraryBuilder));
    }
  }

  bool _hasBuiltOutlines = false;

  @override
  void buildOutlineExpressions(
      SourceLibraryBuilder library,
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (_hasBuiltOutlines) return;
    if (isConst && isPatch) {
      origin.buildOutlineExpressions(library, classHierarchy,
          delayedActionPerformers, delayedDefaultValueCloners);
    }
    super.buildOutlineExpressions(library, classHierarchy,
        delayedActionPerformers, delayedDefaultValueCloners);

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
                computeTypeParameterScope(declarationBuilder!.scope)));
      } else {
        formalParameterScope = null;
      }
      BodyBuilder bodyBuilder = library.loader
          .createBodyBuilderForOutlineExpression(
              library, classBuilder, this, classBuilder.scope, fileUri,
              formalParameterScope: formalParameterScope);
      bodyBuilder.constantContext = ConstantContext.required;
      bodyBuilder.parseInitializers(beginInitializers!,
          doFinishConstructor: isConst);
      bodyBuilder.performBacklogComputations(delayedActionPerformers);
    }
    beginInitializers = null;
    addSuperParameterDefaultValueCloners(delayedDefaultValueCloners);
    if (isConst && isPatch) {
      _finishPatch();
    }
    _hasBuiltOutlines = true;
  }

  void addSuperParameterDefaultValueCloners(
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    ConstructorBuilder? superTargetBuilder =
        _computeSuperTargetBuilder(constructor.initializers);
    if (superTargetBuilder is DeclaredSourceConstructorBuilder) {
      superTargetBuilder
          .addSuperParameterDefaultValueCloners(delayedDefaultValueCloners);
    } else if (superTargetBuilder is SyntheticSourceConstructorBuilder) {
      superTargetBuilder
          .addSuperParameterDefaultValueCloners(delayedDefaultValueCloners);
    }

    delayedDefaultValueCloners.addAll(_superParameterDefaultValueCloners);
    _superParameterDefaultValueCloners.clear();
  }

  @override
  void buildFunction(SourceLibraryBuilder library) {
    // According to the specification §9.3 the return type of a constructor
    // function is its enclosing class.
    super.buildFunction(library);
    Class enclosingClass = classBuilder.cls;
    List<DartType> typeParameterTypes = <DartType>[];
    for (int i = 0; i < enclosingClass.typeParameters.length; i++) {
      TypeParameter typeParameter = enclosingClass.typeParameters[i];
      typeParameterTypes.add(
          new TypeParameterType.withDefaultNullabilityForLibrary(
              typeParameter, library.library));
    }
    function.returnType = new InterfaceType(
        enclosingClass, library.nonNullable, typeParameterTypes);
  }

  @override
  Constructor get constructor => isPatch ? origin.constructor : _constructor;

  @override
  Member get member => constructor;

  void injectInvalidInitializer(Message message, int charOffset, int length,
      ExpressionGeneratorHelper helper) {
    List<Initializer> initializers = _constructor.initializers;
    Initializer lastInitializer = initializers.removeLast();
    assert(lastInitializer == superInitializer ||
        lastInitializer == redirectingInitializer);
    Initializer error = helper.buildInvalidInitializer(
        helper.buildProblem(message, charOffset, length));
    initializers.add(error..parent = _constructor);
    initializers.add(lastInitializer);
  }

  void addInitializer(Initializer initializer, ExpressionGeneratorHelper helper,
      {required InitializerInferenceResult? inferenceResult}) {
    List<Initializer> initializers = _constructor.initializers;
    if (initializer is SuperInitializer) {
      if (superInitializer != null) {
        injectInvalidInitializer(messageMoreThanOneSuperInitializer,
            initializer.fileOffset, "super".length, helper);
      } else if (redirectingInitializer != null) {
        injectInvalidInitializer(
            messageRedirectingConstructorWithSuperInitializer,
            initializer.fileOffset,
            "super".length,
            helper);
      } else {
        inferenceResult?.applyResult(initializers, _constructor);
        superInitializer = initializer;

        LocatedMessage? message = helper.checkArgumentsForFunction(
            initializer.target.function,
            initializer.arguments,
            initializer.arguments.fileOffset, <TypeParameter>[]);
        if (message != null) {
          initializers.add(helper.buildInvalidInitializer(
              helper.buildUnresolvedError(
                  helper.forest.createNullLiteral(initializer.fileOffset),
                  helper.constructorNameForDiagnostics(
                      initializer.target.name.text),
                  initializer.arguments,
                  initializer.fileOffset,
                  isSuper: true,
                  message: message,
                  kind: UnresolvedKind.Constructor))
            ..parent = _constructor);
        } else {
          initializers.add(initializer..parent = _constructor);
        }
      }
    } else if (initializer is RedirectingInitializer) {
      if (superInitializer != null) {
        // Point to the existing super initializer.
        injectInvalidInitializer(
            messageRedirectingConstructorWithSuperInitializer,
            superInitializer!.fileOffset,
            "super".length,
            helper);
      } else if (redirectingInitializer != null) {
        injectInvalidInitializer(
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
          error.parent = _constructor;
          initializers[i] = error;
        }
        inferenceResult?.applyResult(initializers, _constructor);
        initializers.add(initializer..parent = _constructor);
        redirectingInitializer = initializer;
      } else {
        inferenceResult?.applyResult(initializers, _constructor);
        redirectingInitializer = initializer;

        LocatedMessage? message = helper.checkArgumentsForFunction(
            initializer.target.function,
            initializer.arguments,
            initializer.arguments.fileOffset, const <TypeParameter>[]);
        if (message != null) {
          initializers.add(helper.buildInvalidInitializer(
              helper.buildUnresolvedError(
                  helper.forest.createNullLiteral(initializer.fileOffset),
                  helper.constructorNameForDiagnostics(
                      initializer.target.name.text,
                      isSuper: false),
                  initializer.arguments,
                  initializer.fileOffset,
                  isSuper: false,
                  message: message,
                  kind: UnresolvedKind.Constructor))
            ..parent = _constructor);
        } else {
          initializers.add(initializer..parent = _constructor);
        }
      }
    } else if (redirectingInitializer != null) {
      int length = noLength;
      if (initializer is AssertInitializer) length = "assert".length;
      injectInvalidInitializer(
          messageRedirectingConstructorWithAnotherInitializer,
          initializer.fileOffset,
          length,
          helper);
    } else if (superInitializer != null) {
      injectInvalidInitializer(messageSuperInitializerNotLast,
          initializer.fileOffset, noLength, helper);
    } else {
      inferenceResult?.applyResult(initializers, _constructor);
      initializers.add(initializer..parent = _constructor);
    }
  }

  @override
  VariableDeclaration? getTearOffParameter(int index) {
    if (_constructorTearOff != null) {
      if (index < _constructorTearOff!.function.positionalParameters.length) {
        return _constructorTearOff!.function.positionalParameters[index];
      } else {
        index -= _constructorTearOff!.function.positionalParameters.length;
        if (index < _constructorTearOff!.function.namedParameters.length) {
          return _constructorTearOff!.function.namedParameters[index];
        }
      }
    }
    return null;
  }

  void _finishPatch() {
    // TODO(ahe): restore file-offset once we track both origin and patch file
    // URIs. See https://github.com/dart-lang/sdk/issues/31579
    origin.constructor.fileUri = fileUri;
    origin.constructor.startFileOffset = _constructor.startFileOffset;
    origin.constructor.fileOffset = _constructor.fileOffset;
    origin.constructor.fileEndOffset = _constructor.fileEndOffset;
    origin.constructor.annotations
        .forEach((m) => m.fileOffset = _constructor.fileOffset);

    origin.constructor.isExternal = _constructor.isExternal;
    origin.constructor.function = _constructor.function;
    origin.constructor.function.parent = origin.constructor;
    origin.constructor.initializers = _constructor.initializers;
    setParents(origin.constructor.initializers, origin.constructor);
  }

  @override
  int finishPatch() {
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
    hasMovedSuperInitializer = false;
  }

  @override
  List<ClassMember> get localMembers =>
      throw new UnsupportedError('${runtimeType}.localMembers');

  @override
  List<ClassMember> get localSetters =>
      throw new UnsupportedError('${runtimeType}.localSetters');

  /// Registers field as being initialized by this constructor.
  ///
  /// The field can be initialized either via an initializing formal or via an
  /// entry in the constructor initializer list.
  void registerInitializedField(SourceFieldBuilder fieldBuilder) {
    (_initializedFields ??= {}).add(fieldBuilder);
  }

  /// Returns the fields registered as initialized by this constructor.
  ///
  /// Returns the set of fields previously registered via
  /// [registerInitializedField] and passes on the ownership of the collection
  /// to the caller.
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
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

  @override
  void checkTypes(
      SourceLibraryBuilder library, TypeEnvironment typeEnvironment) {
    library.checkTypesInConstructorBuilder(this, typeEnvironment);
    List<DeclaredSourceConstructorBuilder>? patches = _patches;
    if (patches != null) {
      for (DeclaredSourceConstructorBuilder patch in patches) {
        patch.checkTypes(library, typeEnvironment);
      }
    }
  }
}

class SyntheticSourceConstructorBuilder extends DillConstructorBuilder
    with SourceMemberBuilderMixin {
  // TODO(johnniwinther,cstefantsova): Rename [_origin] to avoid the confusion
  // with patches.
  // TODO(johnniwinther): Change the type of [_origin] to SourceMemberBuilder
  // when it's the supertype for both old SourceMemberBuilder and
  // SyntheticConstructorBuilder.
  MemberBuilder? _origin;
  DelayedDefaultValueCloner? _delayedDefaultValueCloner;

  SyntheticSourceConstructorBuilder(SourceClassBuilder parent,
      Constructor constructor, Procedure? constructorTearOff,
      {MemberBuilder? origin,
      DelayedDefaultValueCloner? delayedDefaultValueCloner})
      : _origin = origin,
        _delayedDefaultValueCloner = delayedDefaultValueCloner,
        super(constructor, constructorTearOff, parent);

  @override
  SourceLibraryBuilder get libraryBuilder =>
      super.libraryBuilder as SourceLibraryBuilder;

  // TODO(johnniwinther,cstefantsova): Rename [actualOrigin] to avoid the
  //  confusion with patches.
  MemberBuilder? get actualOrigin {
    MemberBuilder? origin = _origin;
    while (origin is SyntheticSourceConstructorBuilder) {
      origin = origin._origin;
    }
    return origin;
  }

  List<FormalParameterBuilder>? get formals {
    MemberBuilder? origin = actualOrigin;
    return origin is DeclaredSourceConstructorBuilder ? origin.formals : null;
  }

  @override
  void buildOutlineExpressions(
      SourceLibraryBuilder libraryBuilder,
      ClassHierarchy classHierarchy,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (_origin != null) {
      // Ensure that default value expressions have been created for [_origin].
      LibraryBuilder originLibraryBuilder = _origin!.libraryBuilder;
      if (originLibraryBuilder is SourceLibraryBuilder) {
        // If [_origin] is from a source library, we need to build the default
        // values and initializers first.
        MemberBuilder origin = _origin!;
        if (origin is DeclaredSourceConstructorBuilder) {
          origin.buildOutlineExpressions(originLibraryBuilder, classHierarchy,
              delayedActionPerformers, delayedDefaultValueCloners);
        } else if (origin is SyntheticSourceConstructorBuilder) {
          origin.buildOutlineExpressions(originLibraryBuilder, classHierarchy,
              delayedActionPerformers, delayedDefaultValueCloners);
        }
      }
      addSuperParameterDefaultValueCloners(delayedDefaultValueCloners);
      _origin = null;
    }
  }

  void addSuperParameterDefaultValueCloners(
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    MemberBuilder? origin = _origin;
    if (origin is DeclaredSourceConstructorBuilder) {
      origin.addSuperParameterDefaultValueCloners(delayedDefaultValueCloners);
    } else if (origin is SyntheticSourceConstructorBuilder) {
      origin.addSuperParameterDefaultValueCloners(delayedDefaultValueCloners);
    }
    if (_delayedDefaultValueCloner != null) {
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
