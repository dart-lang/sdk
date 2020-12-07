// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide MapEntry;

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';

import '../constant_context.dart' show ConstantContext;

import '../dill/dill_member_builder.dart';

import '../kernel/body_builder.dart' show BodyBuilder;
import '../kernel/class_hierarchy_builder.dart' show ClassMember;
import '../kernel/expression_generator_helper.dart'
    show ExpressionGeneratorHelper;

import '../kernel/kernel_builder.dart'
    show isRedirectingGenerativeConstructorImplementation;
import '../kernel/kernel_target.dart' show ClonedFunctionNode;

import '../loader.dart' show Loader;

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

import 'builder.dart';
import 'class_builder.dart';
import 'field_builder.dart';
import 'formal_parameter_builder.dart';
import 'function_builder.dart';
import 'library_builder.dart';
import 'member_builder.dart';
import 'metadata_builder.dart';
import 'type_builder.dart';
import 'type_variable_builder.dart';

abstract class ConstructorBuilder implements FunctionBuilder {
  int get charOpenParenOffset;

  bool hasMovedSuperInitializer;

  SuperInitializer superInitializer;

  RedirectingInitializer redirectingInitializer;

  Token beginInitializers;

  @override
  ConstructorBuilder get actualOrigin;

  ConstructorBuilder get patchForTesting;

  Constructor get actualConstructor;

  @override
  ConstructorBuilder get origin;

  bool get isRedirectingGenerativeConstructor;

  /// The [Constructor] built by this builder.
  Constructor get constructor;

  void injectInvalidInitializer(Message message, int charOffset, int length,
      ExpressionGeneratorHelper helper);

  void addInitializer(
      Initializer initializer, ExpressionGeneratorHelper helper);

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
  Set<FieldBuilder> takeInitializedFields();
}

class ConstructorBuilderImpl extends FunctionBuilderImpl
    implements ConstructorBuilder {
  final Constructor _constructor;

  Set<FieldBuilder> _initializedFields;

  @override
  final int charOpenParenOffset;

  @override
  bool hasMovedSuperInitializer = false;

  @override
  SuperInitializer superInitializer;

  @override
  RedirectingInitializer redirectingInitializer;

  @override
  Token beginInitializers;

  @override
  ConstructorBuilder actualOrigin;

  @override
  Constructor get actualConstructor => _constructor;

  ConstructorBuilderImpl(
      List<MetadataBuilder> metadata,
      int modifiers,
      TypeBuilder returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      SourceLibraryBuilder compilationUnit,
      int startCharOffset,
      int charOffset,
      this.charOpenParenOffset,
      int charEndOffset,
      Constructor referenceFrom,
      [String nativeMethodName])
      : _constructor = new Constructor(null,
            fileUri: compilationUnit.fileUri,
            reference: referenceFrom?.reference)
          ..startFileOffset = startCharOffset
          ..fileOffset = charOffset
          ..fileEndOffset = charEndOffset
          ..isNonNullableByDefault = compilationUnit.isNonNullableByDefault,
        super(metadata, modifiers, returnType, name, typeVariables, formals,
            compilationUnit, charOffset, nativeMethodName);

  @override
  Member get readTarget => null;

  @override
  Member get writeTarget => null;

  @override
  Member get invokeTarget => constructor;

  @override
  Iterable<Member> get exportedMembers => [constructor];

  @override
  ConstructorBuilder get origin => actualOrigin ?? this;

  @override
  ConstructorBuilder get patchForTesting => dataForTesting?.patchForTesting;

  @override
  bool get isDeclarationInstanceMember => false;

  @override
  bool get isClassInstanceMember => false;

  @override
  bool get isConstructor => true;

  @override
  AsyncMarker get asyncModifier => AsyncMarker.Sync;

  @override
  ProcedureKind get kind => null;

  @override
  bool get isRedirectingGenerativeConstructor {
    return isRedirectingGenerativeConstructorImplementation(_constructor);
  }

  @override
  void buildMembers(
      LibraryBuilder library, void Function(Member, BuiltMemberKind) f) {
    Member member = build(library);
    f(member, BuiltMemberKind.Constructor);
  }

  @override
  Constructor build(SourceLibraryBuilder libraryBuilder) {
    if (_constructor.name == null) {
      _constructor.function = buildFunction(libraryBuilder);
      _constructor.function.parent = _constructor;
      _constructor.function.fileOffset = charOpenParenOffset;
      _constructor.function.fileEndOffset = _constructor.fileEndOffset;
      _constructor.function.typeParameters = const <TypeParameter>[];
      _constructor.isConst = isConst;
      _constructor.isExternal = isExternal;
      _constructor.name = new Name(name, libraryBuilder.library);
    }
    if (formals != null) {
      bool needsInference = false;
      for (FormalParameterBuilder formal in formals) {
        if (formal.type == null && formal.isInitializingFormal) {
          formal.variable.type = null;
          needsInference = true;
        }
      }
      if (needsInference) {
        assert(
            library == libraryBuilder,
            "Unexpected library builder ${libraryBuilder} for"
            " constructor $this in ${library}.");
        libraryBuilder.loader.typeInferenceEngine.toBeInferred[_constructor] =
            this;
      }
    }
    return _constructor;
  }

  @override
  void inferFormalTypes() {
    if (formals != null) {
      for (FormalParameterBuilder formal in formals) {
        if (formal.type == null && formal.isInitializingFormal) {
          formal.finalizeInitializingFormal(classBuilder);
        }
      }
    }
  }

  @override
  void buildOutlineExpressions(LibraryBuilder library, CoreTypes coreTypes) {
    super.buildOutlineExpressions(library, coreTypes);

    // For modular compilation purposes we need to include initializers
    // for const constructors into the outline.
    if (isConst && beginInitializers != null) {
      ClassBuilder classBuilder = parent;
      BodyBuilder bodyBuilder = library.loader
          .createBodyBuilderForOutlineExpression(
              library, classBuilder, this, classBuilder.scope, fileUri);
      bodyBuilder.constantContext = ConstantContext.required;
      bodyBuilder.parseInitializers(beginInitializers);
      bodyBuilder.resolveRedirectingFactoryTargets();
    }
    beginInitializers = null;
  }

  @override
  FunctionNode buildFunction(SourceLibraryBuilder library) {
    // According to the specification §9.3 the return type of a constructor
    // function is its enclosing class.
    FunctionNode functionNode = super.buildFunction(library);
    ClassBuilder enclosingClassBuilder = parent;
    Class enclosingClass = enclosingClassBuilder.cls;
    List<DartType> typeParameterTypes = <DartType>[];
    for (int i = 0; i < enclosingClass.typeParameters.length; i++) {
      TypeParameter typeParameter = enclosingClass.typeParameters[i];
      typeParameterTypes.add(
          new TypeParameterType.withDefaultNullabilityForLibrary(
              typeParameter, library.library));
    }
    functionNode.returnType = new InterfaceType(
        enclosingClass, library.nonNullable, typeParameterTypes);
    return functionNode;
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
  void addInitializer(
      Initializer initializer, ExpressionGeneratorHelper helper) {
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
        initializers.add(initializer..parent = _constructor);
        superInitializer = initializer;
      }
    } else if (initializer is RedirectingInitializer) {
      if (superInitializer != null) {
        // Point to the existing super initializer.
        injectInvalidInitializer(
            messageRedirectingConstructorWithSuperInitializer,
            superInitializer.fileOffset,
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
        initializers.add(initializer..parent = _constructor);
        redirectingInitializer = initializer;
      } else {
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
      initializers.add(initializer..parent = _constructor);
    }
  }

  @override
  int finishPatch() {
    if (!isPatch) return 0;

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
    return 1;
  }

  @override
  void becomeNative(Loader loader) {
    _constructor.isExternal = true;
    super.becomeNative(loader);
  }

  @override
  void applyPatch(Builder patch) {
    if (patch is ConstructorBuilderImpl) {
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
    _constructor.initializers.length = 0;
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
  Set<FieldBuilder> takeInitializedFields() {
    Set<FieldBuilder> result = _initializedFields;
    _initializedFields = null;
    return result;
  }
}

class SyntheticConstructorBuilder extends DillConstructorBuilder {
  MemberBuilderImpl _origin;
  ClonedFunctionNode _clonedFunctionNode;

  SyntheticConstructorBuilder(
      SourceClassBuilder parent, Constructor constructor,
      {MemberBuilder origin, ClonedFunctionNode clonedFunctionNode})
      : _origin = origin,
        _clonedFunctionNode = clonedFunctionNode,
        super(constructor, parent);

  void buildOutlineExpressions(
      LibraryBuilder libraryBuilder, CoreTypes coreTypes) {
    if (_origin != null) {
      // Ensure that default value expressions have been created for [_origin].
      _origin.buildOutlineExpressions(libraryBuilder, coreTypes);
      _clonedFunctionNode.cloneDefaultValues();
      _clonedFunctionNode = null;
      _origin = null;
    }
  }
}
