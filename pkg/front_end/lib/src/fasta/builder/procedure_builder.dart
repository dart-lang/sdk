// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.procedure_builder;

// Note: we're deliberately using AsyncMarker and ProcedureKind from kernel
// outside the kernel-specific builders. This is simpler than creating
// additional enums.
import 'package:kernel/ast.dart'
    show AsyncMarker, ProcedureKind, VariableDeclaration;

import 'package:kernel/type_algebra.dart' show containsTypeVariable, substitute;
import 'package:kernel/type_algebra.dart';

import 'builder.dart'
    show
        Builder,
        FormalParameterBuilder,
        LibraryBuilder,
        MemberBuilder,
        MetadataBuilder,
        Scope,
        TypeBuilder,
        TypeVariableBuilder;

import 'extension_builder.dart';

import 'package:kernel/ast.dart'
    show
        Arguments,
        AsyncMarker,
        Class,
        Constructor,
        ConstructorInvocation,
        DartType,
        DynamicType,
        EmptyStatement,
        Expression,
        FunctionNode,
        Initializer,
        InterfaceType,
        Member,
        Name,
        Procedure,
        ProcedureKind,
        RedirectingInitializer,
        Statement,
        StaticInvocation,
        StringLiteral,
        SuperInitializer,
        TreeNode,
        TypeParameter,
        TypeParameterType,
        VariableDeclaration,
        setParents;

import '../../scanner/token.dart' show Token;

import '../constant_context.dart' show ConstantContext;

import '../kernel/body_builder.dart' show BodyBuilder;

import '../kernel/expression_generator_helper.dart'
    show ExpressionGeneratorHelper;

import '../kernel/kernel_builder.dart'
    show
        ClassBuilder,
        ConstructorReferenceBuilder,
        Builder,
        FormalParameterBuilder,
        LibraryBuilder,
        MetadataBuilder,
        TypeBuilder,
        TypeVariableBuilder,
        isRedirectingGenerativeConstructorImplementation;

import '../kernel/kernel_shadow_ast.dart' show VariableDeclarationJudgment;

import '../kernel/redirecting_factory_body.dart' show RedirectingFactoryBody;

import '../loader.dart' show Loader;

import '../messages.dart'
    show
        Message,
        messageConstFactoryRedirectionToNonConst,
        messageMoreThanOneSuperOrThisInitializer,
        messageNonInstanceTypeVariableUse,
        messagePatchDeclarationMismatch,
        messagePatchDeclarationOrigin,
        messagePatchNonExternal,
        messageSuperInitializerNotLast,
        messageThisInitializerNotAlone,
        noLength;

import '../problems.dart' show unexpected;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import '../type_inference/type_inference_engine.dart'
    show IncludesTypeParametersNonCovariantly, Variance;

/// Common base class for constructor and procedure builders.
abstract class FunctionBuilder extends MemberBuilder {
  final List<MetadataBuilder> metadata;

  final int modifiers;

  final TypeBuilder returnType;

  final String name;

  final List<TypeVariableBuilder> typeVariables;

  final List<FormalParameterBuilder> formals;

  /// If this procedure is an extension instance member, [_extensionThis] holds
  /// the synthetically added `this` parameter.
  VariableDeclaration _extensionThis;

  /// If this procedure is an extension instance member,
  /// [_extensionTypeParameters] holds the type parameters copied from the
  /// extension declaration.
  List<TypeParameter> _extensionTypeParameters;

  FunctionBuilder(
      this.metadata,
      this.modifiers,
      this.returnType,
      this.name,
      this.typeVariables,
      this.formals,
      LibraryBuilder compilationUnit,
      int charOffset,
      this.nativeMethodName)
      : super(compilationUnit, charOffset) {
    if (formals != null) {
      for (int i = 0; i < formals.length; i++) {
        formals[i].parent = this;
      }
    }
  }

  String get debugName => "FunctionBuilder";

  AsyncMarker get asyncModifier;

  ProcedureKind get kind;

  bool get isConstructor => false;

  bool get isRegularMethod => identical(ProcedureKind.Method, kind);

  bool get isGetter => identical(ProcedureKind.Getter, kind);

  bool get isSetter => identical(ProcedureKind.Setter, kind);

  bool get isOperator => identical(ProcedureKind.Operator, kind);

  bool get isFactory => identical(ProcedureKind.Factory, kind);

  /// This is the formal parameter scope as specified in the Dart Programming
  /// Language Specification, 4th ed, section 9.2.
  Scope computeFormalParameterScope(Scope parent) {
    if (formals == null) return parent;
    Map<String, Builder> local = <String, Builder>{};
    for (FormalParameterBuilder formal in formals) {
      if (!isConstructor || !formal.isInitializingFormal) {
        local[formal.name] = formal;
      }
    }
    return new Scope(local, null, parent, "formal parameter",
        isModifiable: false);
  }

  Scope computeFormalParameterInitializerScope(Scope parent) {
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
    for (FormalParameterBuilder formal in formals) {
      local[formal.name] = formal.forFormalParameterInitializerScope();
    }
    return new Scope(local, null, parent, "formal parameter initializer",
        isModifiable: false);
  }

  /// This scope doesn't correspond to any scope specified in the Dart
  /// Programming Language Specification, 4th ed. It's an unspecified extension
  /// to support generic methods.
  Scope computeTypeParameterScope(Scope parent) {
    if (typeVariables == null) return parent;
    Map<String, Builder> local = <String, Builder>{};
    for (TypeVariableBuilder variable in typeVariables) {
      local[variable.name] = variable;
    }
    return new Scope(local, null, parent, "type parameter",
        isModifiable: false);
  }

  FormalParameterBuilder getFormal(String name) {
    if (formals != null) {
      for (FormalParameterBuilder formal in formals) {
        if (formal.name == name) return formal;
      }
    }
    return null;
  }

  final String nativeMethodName;

  FunctionNode function;

  Statement actualBody;

  FunctionBuilder get actualOrigin;

  void set body(Statement newBody) {
//    if (newBody != null) {
//      if (isAbstract) {
//        // TODO(danrubel): Is this check needed?
//        return internalProblem(messageInternalProblemBodyOnAbstractMethod,
//            newBody.fileOffset, fileUri);
//      }
//    }
    actualBody = newBody;
    if (function != null) {
      // A forwarding semi-stub is a method that is abstract in the source code,
      // but which needs to have a forwarding stub body in order to ensure that
      // covariance checks occur.  We don't want to replace the forwarding stub
      // body with null.
      TreeNode parent = function.parent;
      if (!(newBody == null &&
          parent is Procedure &&
          parent.isForwardingSemiStub)) {
        function.body = newBody;
        newBody?.parent = function;
      }
    }
  }

  void setRedirectingFactoryBody(Member target, List<DartType> typeArguments) {
    if (actualBody != null) {
      unexpected("null", "${actualBody.runtimeType}", charOffset, fileUri);
    }
    actualBody = new RedirectingFactoryBody(target, typeArguments);
    function.body = actualBody;
    actualBody?.parent = function;
    if (isPatch) {
      actualOrigin.setRedirectingFactoryBody(target, typeArguments);
    }
  }

  Statement get body => actualBody ??= new EmptyStatement();

  bool get isNative => nativeMethodName != null;

  FunctionNode buildFunction(LibraryBuilder library) {
    assert(function == null);
    FunctionNode result = new FunctionNode(body, asyncMarker: asyncModifier);
    IncludesTypeParametersNonCovariantly needsCheckVisitor;
    if (!isConstructor && !isFactory && parent is ClassBuilder) {
      ClassBuilder enclosingClassBuilder = parent;
      Class enclosingClass = enclosingClassBuilder.cls;
      if (enclosingClass.typeParameters.isNotEmpty) {
        needsCheckVisitor = new IncludesTypeParametersNonCovariantly(
            enclosingClass.typeParameters,
            // We are checking the parameter types which are in a
            // contravariant position.
            initialVariance: Variance.contravariant);
      }
    }
    if (typeVariables != null) {
      for (TypeVariableBuilder t in typeVariables) {
        TypeParameter parameter = t.parameter;
        result.typeParameters.add(parameter);
        if (needsCheckVisitor != null) {
          if (parameter.bound.accept(needsCheckVisitor)) {
            parameter.isGenericCovariantImpl = true;
          }
        }
      }
      setParents(result.typeParameters, result);
    }
    if (formals != null) {
      for (FormalParameterBuilder formal in formals) {
        VariableDeclaration parameter = formal.build(library, 0);
        if (needsCheckVisitor != null) {
          if (parameter.type.accept(needsCheckVisitor)) {
            parameter.isGenericCovariantImpl = true;
          }
        }
        if (formal.isNamed) {
          result.namedParameters.add(parameter);
        } else {
          result.positionalParameters.add(parameter);
        }
        parameter.parent = result;
        if (formal.isRequired) {
          result.requiredParameterCount++;
        }
      }
    }
    if (!isExtensionInstanceMember &&
        isSetter &&
        (formals?.length != 1 || formals[0].isOptional)) {
      // Replace illegal parameters by single dummy parameter.
      // Do this after building the parameters, since the diet listener
      // assumes that parameters are built, even if illegal in number.
      VariableDeclaration parameter =
          new VariableDeclarationJudgment("#synthetic", 0);
      result.positionalParameters.clear();
      result.positionalParameters.add(parameter);
      parameter.parent = result;
      result.namedParameters.clear();
      result.requiredParameterCount = 1;
    }
    if (returnType != null) {
      result.returnType = returnType.build(library);
    }
    if (!isConstructor &&
        !isDeclarationInstanceMember &&
        parent is ClassBuilder) {
      ClassBuilder enclosingClassBuilder = parent;
      List<TypeParameter> typeParameters =
          enclosingClassBuilder.cls.typeParameters;
      if (typeParameters.isNotEmpty) {
        Map<TypeParameter, DartType> substitution;
        DartType removeTypeVariables(DartType type) {
          if (substitution == null) {
            substitution = <TypeParameter, DartType>{};
            for (TypeParameter parameter in typeParameters) {
              substitution[parameter] = const DynamicType();
            }
          }
          library.addProblem(
              messageNonInstanceTypeVariableUse, charOffset, noLength, fileUri);
          return substitute(type, substitution);
        }

        Set<TypeParameter> set = typeParameters.toSet();
        for (VariableDeclaration parameter in result.positionalParameters) {
          if (containsTypeVariable(parameter.type, set)) {
            parameter.type = removeTypeVariables(parameter.type);
          }
        }
        for (VariableDeclaration parameter in result.namedParameters) {
          if (containsTypeVariable(parameter.type, set)) {
            parameter.type = removeTypeVariables(parameter.type);
          }
        }
        if (containsTypeVariable(result.returnType, set)) {
          result.returnType = removeTypeVariables(result.returnType);
        }
      }
    }
    if (isExtensionInstanceMember) {
      ExtensionBuilder extensionBuilder = parent;
      _extensionThis = result.positionalParameters.first;
      if (extensionBuilder.typeParameters != null) {
        int count = extensionBuilder.typeParameters.length;
        _extensionTypeParameters = new List<TypeParameter>(count);
        for (int index = 0; index < count; index++) {
          _extensionTypeParameters[index] = result.typeParameters[index];
        }
      }
    }
    return function = result;
  }

  /// Returns the parameter for 'this' synthetically added to extension
  /// instance members.
  VariableDeclaration get extensionThis {
    assert(_extensionThis != null || !isExtensionInstanceMember,
        "ProcedureBuilder.extensionThis has not been set.");
    return _extensionThis;
  }

  /// Returns a list of synthetic type parameters added to extension instance
  /// members.
  List<TypeParameter> get extensionTypeParameters {
    // Use [_extensionThis] as marker for whether extension type parameters have
    // been computed.
    assert(_extensionThis != null || !isExtensionInstanceMember,
        "ProcedureBuilder.extensionTypeParameters has not been set.");
    return _extensionTypeParameters;
  }

  Member build(SourceLibraryBuilder library);

  @override
  void buildOutlineExpressions(LibraryBuilder library) {
    MetadataBuilder.buildAnnotations(
        member, metadata, library, isClassMember ? parent : null, this);

    if (formals != null) {
      // For const constructors we need to include default parameter values
      // into the outline. For all other formals we need to call
      // buildOutlineExpressions to clear initializerToken to prevent
      // consuming too much memory.
      for (FormalParameterBuilder formal in formals) {
        formal.buildOutlineExpressions(library);
      }
    }
  }

  void becomeNative(Loader loader) {
    MemberBuilder constructor = loader.getNativeAnnotation();
    Arguments arguments =
        new Arguments(<Expression>[new StringLiteral(nativeMethodName)]);
    Expression annotation;
    if (constructor.isConstructor) {
      annotation = new ConstructorInvocation(constructor.member, arguments)
        ..isConst = true;
    } else {
      annotation = new StaticInvocation(constructor.member, arguments)
        ..isConst = true;
    }
    member.addAnnotation(annotation);
  }

  bool checkPatch(FunctionBuilder patch) {
    if (!isExternal) {
      patch.library.addProblem(
          messagePatchNonExternal, patch.charOffset, noLength, patch.fileUri,
          context: [
            messagePatchDeclarationOrigin.withLocation(
                fileUri, charOffset, noLength)
          ]);
      return false;
    }
    return true;
  }

  void reportPatchMismatch(Builder patch) {
    library.addProblem(messagePatchDeclarationMismatch, patch.charOffset,
        noLength, patch.fileUri, context: [
      messagePatchDeclarationOrigin.withLocation(fileUri, charOffset, noLength)
    ]);
  }
}

class ProcedureBuilder extends FunctionBuilder {
  final Procedure _procedure;
  final int charOpenParenOffset;
  final ProcedureKind kind;

  AsyncMarker actualAsyncModifier = AsyncMarker.Sync;

  @override
  ProcedureBuilder actualOrigin;

  Procedure get actualProcedure => _procedure;

  bool hadTypesInferred = false;

  ProcedureBuilder(
      List<MetadataBuilder> metadata,
      int modifiers,
      TypeBuilder returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      this.kind,
      SourceLibraryBuilder compilationUnit,
      int startCharOffset,
      int charOffset,
      this.charOpenParenOffset,
      int charEndOffset,
      [String nativeMethodName])
      : _procedure =
            new Procedure(null, kind, null, fileUri: compilationUnit?.fileUri)
              ..startFileOffset = startCharOffset
              ..fileOffset = charOffset
              ..fileEndOffset = charEndOffset,
        super(metadata, modifiers, returnType, name, typeVariables, formals,
            compilationUnit, charOffset, nativeMethodName);

  @override
  ProcedureBuilder get origin => actualOrigin ?? this;

  AsyncMarker get asyncModifier => actualAsyncModifier;

  Statement get body {
    if (actualBody == null && !isAbstract && !isExternal) {
      actualBody = new EmptyStatement();
    }
    return actualBody;
  }

  void set asyncModifier(AsyncMarker newModifier) {
    actualAsyncModifier = newModifier;
    if (function != null) {
      // No parent, it's an enum.
      function.asyncMarker = actualAsyncModifier;
      function.dartAsyncMarker = actualAsyncModifier;
    }
  }

  bool get isEligibleForTopLevelInference {
    if (library.legacyMode) return false;
    if (isDeclarationInstanceMember) {
      if (returnType == null) return true;
      if (formals != null) {
        for (FormalParameterBuilder formal in formals) {
          if (formal.type == null) return true;
        }
      }
    }
    return false;
  }

  /// Returns `true` if this procedure is declared in an extension declaration.
  bool get isExtensionMethod {
    return parent is ExtensionBuilder;
  }

  Procedure build(SourceLibraryBuilder libraryBuilder) {
    // TODO(ahe): I think we may call this twice on parts. Investigate.
    if (_procedure.name == null) {
      _procedure.function = buildFunction(libraryBuilder);
      _procedure.function.parent = _procedure;
      _procedure.function.fileOffset = charOpenParenOffset;
      _procedure.function.fileEndOffset = _procedure.fileEndOffset;
      _procedure.isAbstract = isAbstract;
      _procedure.isExternal = isExternal;
      _procedure.isConst = isConst;
      if (isExtensionMethod) {
        ExtensionBuilder extension = parent;
        procedure.isExtensionMember = true;
        procedure.isStatic = true;
        String kindInfix = '';
        if (isExtensionInstanceMember) {
          // Instance getter and setter are converted to methods so we use an
          // infix to make their names unique.
          switch (kind) {
            case ProcedureKind.Getter:
              kindInfix = 'get#';
              break;
            case ProcedureKind.Setter:
              kindInfix = 'set#';
              break;
            case ProcedureKind.Method:
            case ProcedureKind.Operator:
              kindInfix = '';
              break;
            case ProcedureKind.Factory:
              throw new UnsupportedError(
                  'Unexpected extension method kind ${kind}');
          }
          procedure.kind = ProcedureKind.Method;
        }
        procedure.name = new Name(
            '${extension.name}|${kindInfix}${name}', libraryBuilder.library);
      } else {
        _procedure.isStatic = isStatic;
        _procedure.name = new Name(name, libraryBuilder.library);
      }
    }
    return _procedure;
  }

  /// The [Procedure] built by this builder.
  Procedure get procedure => isPatch ? origin.procedure : _procedure;

  Member get member => procedure;

  @override
  int finishPatch() {
    if (!isPatch) return 0;

    // TODO(ahe): restore file-offset once we track both origin and patch file
    // URIs. See https://github.com/dart-lang/sdk/issues/31579
    origin.procedure.fileUri = fileUri;
    origin.procedure.startFileOffset = _procedure.startFileOffset;
    origin.procedure.fileOffset = _procedure.fileOffset;
    origin.procedure.fileEndOffset = _procedure.fileEndOffset;
    origin.procedure.annotations
        .forEach((m) => m.fileOffset = _procedure.fileOffset);

    origin.procedure.isAbstract = _procedure.isAbstract;
    origin.procedure.isExternal = _procedure.isExternal;
    origin.procedure.function = _procedure.function;
    origin.procedure.function.parent = origin.procedure;
    return 1;
  }

  @override
  void becomeNative(Loader loader) {
    _procedure.isExternal = true;
    super.becomeNative(loader);
  }

  @override
  void applyPatch(Builder patch) {
    if (patch is ProcedureBuilder) {
      if (checkPatch(patch)) {
        patch.actualOrigin = this;
      }
    } else {
      reportPatchMismatch(patch);
    }
  }
}

// TODO(ahe): Move this to own file?
class ConstructorBuilder extends FunctionBuilder {
  final Constructor _constructor;

  final int charOpenParenOffset;

  bool hasMovedSuperInitializer = false;

  SuperInitializer superInitializer;

  RedirectingInitializer redirectingInitializer;

  Token beginInitializers;

  @override
  ConstructorBuilder actualOrigin;

  Constructor get actualConstructor => _constructor;

  ConstructorBuilder(
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
      [String nativeMethodName])
      : _constructor = new Constructor(null, fileUri: compilationUnit?.fileUri)
          ..startFileOffset = startCharOffset
          ..fileOffset = charOffset
          ..fileEndOffset = charEndOffset,
        super(metadata, modifiers, returnType, name, typeVariables, formals,
            compilationUnit, charOffset, nativeMethodName);

  @override
  ConstructorBuilder get origin => actualOrigin ?? this;

  @override
  bool get isDeclarationInstanceMember => false;

  @override
  bool get isClassInstanceMember => false;

  bool get isConstructor => true;

  AsyncMarker get asyncModifier => AsyncMarker.Sync;

  ProcedureKind get kind => null;

  bool get isRedirectingGenerativeConstructor {
    return isRedirectingGenerativeConstructorImplementation(_constructor);
  }

  bool get isEligibleForTopLevelInference {
    if (library.legacyMode) return false;
    if (formals != null) {
      for (FormalParameterBuilder formal in formals) {
        if (formal.type == null && formal.isInitializingFormal) return true;
      }
    }
    return false;
  }

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
    if (isEligibleForTopLevelInference) {
      for (FormalParameterBuilder formal in formals) {
        if (formal.type == null && formal.isInitializingFormal) {
          formal.variable.type = null;
        }
      }
      libraryBuilder.loader.typeInferenceEngine.toBeInferred[_constructor] =
          libraryBuilder;
    }
    return _constructor;
  }

  @override
  void buildOutlineExpressions(LibraryBuilder library) {
    super.buildOutlineExpressions(library);

    // For modular compilation purposes we need to include initializers
    // for const constructors into the outline.
    if (isConst && beginInitializers != null) {
      ClassBuilder classBuilder = parent;
      BodyBuilder bodyBuilder = new BodyBuilder.forOutlineExpression(
          library, classBuilder, this, classBuilder.scope, fileUri);
      bodyBuilder.constantContext = ConstantContext.inferred;
      bodyBuilder.parseInitializers(beginInitializers);
      bodyBuilder.resolveRedirectingFactoryTargets();
    }
    beginInitializers = null;
  }

  FunctionNode buildFunction(LibraryBuilder library) {
    // According to the specification §9.3 the return type of a constructor
    // function is its enclosing class.
    FunctionNode functionNode = super.buildFunction(library);
    ClassBuilder enclosingClassBuilder = parent;
    Class enclosingClass = enclosingClassBuilder.cls;
    List<DartType> typeParameterTypes = new List<DartType>();
    for (int i = 0; i < enclosingClass.typeParameters.length; i++) {
      TypeParameter typeParameter = enclosingClass.typeParameters[i];
      typeParameterTypes.add(new TypeParameterType(typeParameter));
    }
    functionNode.returnType =
        new InterfaceType(enclosingClass, typeParameterTypes);
    return functionNode;
  }

  /// The [Constructor] built by this builder.
  Constructor get constructor => isPatch ? origin.constructor : _constructor;

  Member get member => constructor;

  void injectInvalidInitializer(
      Message message, int charOffset, ExpressionGeneratorHelper helper) {
    List<Initializer> initializers = _constructor.initializers;
    Initializer lastInitializer = initializers.removeLast();
    assert(lastInitializer == superInitializer ||
        lastInitializer == redirectingInitializer);
    Initializer error = helper.buildInvalidInitializer(
        helper.desugarSyntheticExpression(
            helper.buildProblem(message, charOffset, noLength)),
        charOffset);
    initializers.add(error..parent = _constructor);
    initializers.add(lastInitializer);
  }

  void addInitializer(
      Initializer initializer, ExpressionGeneratorHelper helper) {
    List<Initializer> initializers = _constructor.initializers;
    if (initializer is SuperInitializer) {
      if (superInitializer != null || redirectingInitializer != null) {
        injectInvalidInitializer(messageMoreThanOneSuperOrThisInitializer,
            initializer.fileOffset, helper);
      } else {
        initializers.add(initializer..parent = _constructor);
        superInitializer = initializer;
      }
    } else if (initializer is RedirectingInitializer) {
      if (superInitializer != null || redirectingInitializer != null) {
        injectInvalidInitializer(messageMoreThanOneSuperOrThisInitializer,
            initializer.fileOffset, helper);
      } else if (_constructor.initializers.isNotEmpty) {
        Initializer first = _constructor.initializers.first;
        Initializer error = helper.buildInvalidInitializer(
            helper.desugarSyntheticExpression(helper.buildProblem(
                messageThisInitializerNotAlone, first.fileOffset, noLength)),
            first.fileOffset);
        initializers.add(error..parent = _constructor);
      } else {
        initializers.add(initializer..parent = _constructor);
        redirectingInitializer = initializer;
      }
    } else if (redirectingInitializer != null) {
      injectInvalidInitializer(
          messageThisInitializerNotAlone, initializer.fileOffset, helper);
    } else if (superInitializer != null) {
      injectInvalidInitializer(
          messageSuperInitializerNotLast, superInitializer.fileOffset, helper);
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
    if (patch is ConstructorBuilder) {
      if (checkPatch(patch)) {
        patch.actualOrigin = this;
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
    // Note: this method clears both initializers from the target Kernel node
    // and internal state associated with parsing initializers.
    if (constructor.isConst) {
      constructor.initializers.length = 0;
      redirectingInitializer = null;
      superInitializer = null;
      hasMovedSuperInitializer = false;
    }
  }
}

class RedirectingFactoryBuilder extends ProcedureBuilder {
  final ConstructorReferenceBuilder redirectionTarget;
  List<DartType> typeArguments;

  RedirectingFactoryBuilder(
      List<MetadataBuilder> metadata,
      int modifiers,
      TypeBuilder returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      SourceLibraryBuilder compilationUnit,
      int startCharOffset,
      int charOffset,
      int charOpenParenOffset,
      int charEndOffset,
      [String nativeMethodName,
      this.redirectionTarget])
      : super(
            metadata,
            modifiers,
            returnType,
            name,
            typeVariables,
            formals,
            ProcedureKind.Factory,
            compilationUnit,
            startCharOffset,
            charOffset,
            charOpenParenOffset,
            charEndOffset,
            nativeMethodName);

  @override
  Statement get body => actualBody;

  @override
  void setRedirectingFactoryBody(Member target, List<DartType> typeArguments) {
    if (actualBody != null) {
      unexpected("null", "${actualBody.runtimeType}", charOffset, fileUri);
    }

    // Ensure that constant factories only have constant targets/bodies.
    if (isConst && !target.isConst) {
      library.addProblem(messageConstFactoryRedirectionToNonConst, charOffset,
          noLength, fileUri);
    }

    actualBody = new RedirectingFactoryBody(target, typeArguments);
    function.body = actualBody;
    actualBody?.parent = function;
    if (isPatch) {
      if (function.typeParameters != null) {
        Map<TypeParameter, DartType> substitution = <TypeParameter, DartType>{};
        for (int i = 0; i < function.typeParameters.length; i++) {
          substitution[function.typeParameters[i]] =
              new TypeParameterType(actualOrigin.function.typeParameters[i]);
        }
        List<DartType> newTypeArguments =
            new List<DartType>(typeArguments.length);
        for (int i = 0; i < newTypeArguments.length; i++) {
          newTypeArguments[i] = substitute(typeArguments[i], substitution);
        }
        typeArguments = newTypeArguments;
      }
      actualOrigin.setRedirectingFactoryBody(target, typeArguments);
    }
  }

  @override
  Procedure build(SourceLibraryBuilder library) {
    Procedure result = super.build(library);
    result.isRedirectingFactoryConstructor = true;
    if (redirectionTarget.typeArguments != null) {
      typeArguments =
          new List<DartType>(redirectionTarget.typeArguments.length);
      for (int i = 0; i < typeArguments.length; i++) {
        typeArguments[i] = redirectionTarget.typeArguments[i].build(library);
      }
    }
    return result;
  }

  @override
  int finishPatch() {
    if (!isPatch) return 0;

    super.finishPatch();

    if (origin is RedirectingFactoryBuilder) {
      RedirectingFactoryBuilder redirectingOrigin = origin;
      redirectingOrigin.typeArguments = typeArguments;
    }

    return 1;
  }
}
