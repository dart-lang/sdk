// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import '../builder/library_builder.dart';

import '../constant_context.dart' show ConstantContext;

import '../dill/dill_member_builder.dart';

import '../kernel/body_builder.dart' show BodyBuilder;
import '../kernel/class_hierarchy_builder.dart' show ClassMember;
import '../kernel/constructor_tearoff_lowering.dart';
import '../kernel/expression_generator_helper.dart'
    show ExpressionGeneratorHelper;
import '../kernel/utils.dart'
    show isRedirectingGenerativeConstructorImplementation;
import '../kernel/kernel_helper.dart' show SynthesizedFunctionNode;

import '../source/source_loader.dart' show SourceLoader;

import '../messages.dart'
    show
        Message,
        messageMoreThanOneSuperInitializer,
        messageRedirectingConstructorWithAnotherInitializer,
        messageRedirectingConstructorWithMultipleRedirectInitializers,
        messageRedirectingConstructorWithSuperInitializer,
        messageSuperInitializerNotLast,
        noLength;

import '../source/source_class_builder.dart';
import '../source/source_library_builder.dart' show SourceLibraryBuilder;
import '../type_inference/type_schema.dart';
import '../type_inference/type_inferrer.dart';
import '../util/helpers.dart' show DelayedActionPerformer;

import 'builder.dart';
import 'field_builder.dart';
import 'formal_parameter_builder.dart';
import 'function_builder.dart';
import 'member_builder.dart';
import 'metadata_builder.dart';
import 'type_builder.dart';
import 'type_variable_builder.dart';

abstract class ConstructorBuilder implements FunctionBuilder {
  abstract Token? beginInitializers;

  ConstructorBuilder? get actualOrigin;

  ConstructorBuilder? get patchForTesting;

  Constructor get actualConstructor;

  @override
  ConstructorBuilder get origin;

  bool get isRedirectingGenerativeConstructor;

  /// The [Constructor] built by this builder.
  Constructor get constructor;

  void injectInvalidInitializer(Message message, int charOffset, int length,
      ExpressionGeneratorHelper helper);

  void addInitializer(Initializer initializer, ExpressionGeneratorHelper helper,
      {required InitializerInferenceResult? inferenceResult});

  void prepareInitializers();

  /// Infers the types of any untyped initializing formals.
  void inferFormalTypes();

  /// Registers field as being initialized by this constructor.
  ///
  /// The field can be initialized either via an initializing formal or via an
  /// entry in the constructor initializer list.
  void registerInitializedField(FieldBuilder fieldBuilder);

  /// Returns the fields registered as initialized by this constructor.
  ///
  /// Returns the set of fields previously registered via
  /// [registerInitializedField] and passes on the ownership of the collection
  /// to the caller.
  Set<FieldBuilder>? takeInitializedFields();
}

class SourceConstructorBuilder extends FunctionBuilderImpl
    implements ConstructorBuilder {
  final Constructor _constructor;
  final Procedure? _constructorTearOff;

  Set<FieldBuilder>? _initializedFields;

  final int charOpenParenOffset;

  bool hasMovedSuperInitializer = false;

  SuperInitializer? superInitializer;

  RedirectingInitializer? redirectingInitializer;

  @override
  Token? beginInitializers;

  @override
  ConstructorBuilder? actualOrigin;

  @override
  Constructor get actualConstructor => _constructor;

  SourceConstructorBuilder(
      List<MetadataBuilder>? metadata,
      int modifiers,
      TypeBuilder? returnType,
      String name,
      List<TypeVariableBuilder>? typeVariables,
      List<FormalParameterBuilder>? formals,
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
        super(metadata, modifiers, returnType, name, typeVariables, formals,
            compilationUnit, charOffset, nativeMethodName);

  @override
  SourceLibraryBuilder get library => super.library as SourceLibraryBuilder;

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
  ConstructorBuilder get origin => actualOrigin ?? this;

  @override
  ConstructorBuilder? get patchForTesting =>
      dataForTesting?.patchForTesting as ConstructorBuilder?;

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
  Constructor build(SourceLibraryBuilder libraryBuilder) {
    if (!_hasBeenBuilt) {
      buildFunction(libraryBuilder);
      _constructor.function.fileOffset = charOpenParenOffset;
      _constructor.function.fileEndOffset = _constructor.fileEndOffset;
      _constructor.function.typeParameters = const <TypeParameter>[];
      _constructor.isConst = isConst;
      _constructor.isExternal = isExternal;
      updatePrivateMemberName(_constructor, libraryBuilder);

      if (_constructorTearOff != null) {
        buildConstructorTearOffProcedure(_constructorTearOff!, _constructor,
            classBuilder.cls, libraryBuilder);
      }

      _hasBeenBuilt = true;
    }
    if (formals != null) {
      bool needsInference = false;
      for (FormalParameterBuilder formal in formals!) {
        if (formal.type == null && formal.isInitializingFormal) {
          formal.variable!.type = const UnknownType();
          needsInference = true;
        }
      }
      if (needsInference) {
        assert(
            library == libraryBuilder,
            "Unexpected library builder ${libraryBuilder} for"
            " constructor $this in ${library}.");
        libraryBuilder.loader
            .registerConstructorToBeInferred(_constructor, this);
      }
    }
    return _constructor;
  }

  @override
  void inferFormalTypes() {
    if (formals != null) {
      for (FormalParameterBuilder formal in formals!) {
        if (formal.type == null && formal.isInitializingFormal) {
          formal.finalizeInitializingFormal(classBuilder);
        }
      }
    }
  }

  bool _hasBuiltOutlines = false;

  @override
  void buildOutlineExpressions(
      SourceLibraryBuilder library,
      CoreTypes coreTypes,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<SynthesizedFunctionNode> synthesizedFunctionNodes) {
    if (_hasBuiltOutlines) return;
    if (isConst && isPatch) {
      origin.buildOutlineExpressions(library, coreTypes,
          delayedActionPerformers, synthesizedFunctionNodes);
    }
    super.buildOutlineExpressions(
        library, coreTypes, delayedActionPerformers, synthesizedFunctionNodes);

    // For modular compilation purposes we need to include initializers
    // for const constructors into the outline.
    if (isConst && beginInitializers != null) {
      BodyBuilder bodyBuilder = library.loader
          .createBodyBuilderForOutlineExpression(
              library, classBuilder, this, classBuilder.scope, fileUri);
      bodyBuilder.constantContext = ConstantContext.required;
      bodyBuilder.parseInitializers(beginInitializers!);
      bodyBuilder.performBacklogComputations(delayedActionPerformers);
    }
    beginInitializers = null;
    if (isConst && isPatch) {
      _finishPatch();
    }
    _hasBuiltOutlines = true;
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

  @override
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

  @override
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
        initializers.add(initializer..parent = _constructor);
        superInitializer = initializer;
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
        initializers.add(initializer..parent = _constructor);
        redirectingInitializer = initializer;
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

  @override
  void becomeNative(SourceLoader loader) {
    _constructor.isExternal = true;
    super.becomeNative(loader);
  }

  @override
  void applyPatch(Builder patch) {
    if (patch is SourceConstructorBuilder) {
      if (checkPatch(patch)) {
        patch.actualOrigin = this;
        dataForTesting?.patchForTesting = patch;
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
    hasMovedSuperInitializer = false;
  }

  @override
  List<ClassMember> get localMembers =>
      throw new UnsupportedError('${runtimeType}.localMembers');

  @override
  List<ClassMember> get localSetters =>
      throw new UnsupportedError('${runtimeType}.localSetters');

  @override
  void registerInitializedField(FieldBuilder fieldBuilder) {
    (_initializedFields ??= {}).add(fieldBuilder);
  }

  @override
  Set<FieldBuilder>? takeInitializedFields() {
    Set<FieldBuilder>? result = _initializedFields;
    _initializedFields = null;
    return result;
  }
}

class SyntheticConstructorBuilder extends DillConstructorBuilder {
  MemberBuilderImpl? _origin;
  SynthesizedFunctionNode? _synthesizedFunctionNode;

  SyntheticConstructorBuilder(SourceClassBuilder parent,
      Constructor constructor, Procedure? constructorTearOff,
      {MemberBuilderImpl? origin,
      SynthesizedFunctionNode? synthesizedFunctionNode})
      : _origin = origin,
        _synthesizedFunctionNode = synthesizedFunctionNode,
        super(constructor, constructorTearOff, parent);

  @override
  void buildOutlineExpressions(
      SourceLibraryBuilder libraryBuilder,
      CoreTypes coreTypes,
      List<DelayedActionPerformer> delayedActionPerformers,
      List<SynthesizedFunctionNode> synthesizedFunctionNodes) {
    if (_origin != null) {
      // Ensure that default value expressions have been created for [_origin].
      LibraryBuilder originLibraryBuilder = _origin!.library;
      if (originLibraryBuilder is SourceLibraryBuilder) {
        // If [_origin] is from a source library, we need to build the default
        // values and initializers first.
        _origin!.buildOutlineExpressions(originLibraryBuilder, coreTypes,
            delayedActionPerformers, synthesizedFunctionNodes);
      }
      _synthesizedFunctionNode!.cloneDefaultValues();
      _synthesizedFunctionNode = null;
      _origin = null;
    }
  }
}
