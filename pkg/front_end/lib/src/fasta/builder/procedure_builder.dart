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

import '../source/source_loader.dart' show SourceLoader;

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

  /// If this procedure is an instance member declared in an extension
  /// declaration, [extensionThis] holds the synthetically added `this`
  /// parameter.
  VariableDeclaration extensionThis;

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
      var parent = function.parent;
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
      Class enclosingClass = parent.target;
      if (enclosingClass.typeParameters.isNotEmpty) {
        needsCheckVisitor = new IncludesTypeParametersNonCovariantly(
            enclosingClass.typeParameters,
            // We are checking the parameter types which are in a contravariant position.
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
    if (isSetter && (formals?.length != 1 || formals[0].isOptional)) {
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
    if (!isConstructor && !isInstanceMember && parent is ClassBuilder) {
      List<TypeParameter> typeParameters = parent.target.typeParameters;
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
    if (parent is ClassBuilder) {
      ClassBuilder cls = parent;
      if (cls.isExtension && isInstanceMember) {
        extensionThis = result.positionalParameters.first;
      }
    }
    return function = result;
  }

  Member build(SourceLibraryBuilder library);

  @override
  void buildOutlineExpressions(LibraryBuilder library) {
    MetadataBuilder.buildAnnotations(
        target, metadata, library, isClassMember ? parent : null, this);

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
    Builder constructor = loader.getNativeAnnotation();
    Arguments arguments =
        new Arguments(<Expression>[new StringLiteral(nativeMethodName)]);
    Expression annotation;
    if (constructor.isConstructor) {
      annotation = new ConstructorInvocation(constructor.target, arguments)
        ..isConst = true;
    } else {
      annotation = new StaticInvocation(constructor.target, arguments)
        ..isConst = true;
    }
    target.addAnnotation(annotation);
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
  final Procedure procedure;
  final int charOpenParenOffset;

  AsyncMarker actualAsyncModifier = AsyncMarker.Sync;

  @override
  ProcedureBuilder actualOrigin;

  bool hadTypesInferred = false;

  ProcedureBuilder(
      List<MetadataBuilder> metadata,
      int modifiers,
      TypeBuilder returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      ProcedureKind kind,
      SourceLibraryBuilder compilationUnit,
      int startCharOffset,
      int charOffset,
      this.charOpenParenOffset,
      int charEndOffset,
      [String nativeMethodName])
      : procedure =
            new Procedure(null, kind, null, fileUri: compilationUnit?.fileUri)
              ..startFileOffset = startCharOffset
              ..fileOffset = charOffset
              ..fileEndOffset = charEndOffset,
        super(metadata, modifiers, returnType, name, typeVariables, formals,
            compilationUnit, charOffset, nativeMethodName);

  @override
  ProcedureBuilder get origin => actualOrigin ?? this;

  ProcedureKind get kind => procedure.kind;

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
    if (isInstanceMember) {
      if (returnType == null) return true;
      if (formals != null) {
        for (var formal in formals) {
          if (formal.type == null) return true;
        }
      }
    }
    return false;
  }

  /// Returns `true` if this procedure is declared in an extension declaration.
  bool get isExtensionMethod {
    if (parent is ClassBuilder) {
      ClassBuilder cls = parent;
      return cls.isExtension;
    }
    return false;
  }

  Procedure build(SourceLibraryBuilder library) {
    // TODO(ahe): I think we may call this twice on parts. Investigate.
    if (procedure.name == null) {
      procedure.function = buildFunction(library);
      procedure.function.parent = procedure;
      procedure.function.fileOffset = charOpenParenOffset;
      procedure.function.fileEndOffset = procedure.fileEndOffset;
      procedure.isAbstract = isAbstract;
      procedure.isExternal = isExternal;
      procedure.isConst = isConst;
      if (isExtensionMethod) {
        ClassBuilder extension = parent;
        procedure.isStatic = false;
        procedure.isExtensionMethod = true;
        procedure.kind = ProcedureKind.Method;
        procedure.name = new Name('${extension.name}|${name}', library.target);
      } else {
        procedure.isStatic = isStatic;
        procedure.name = new Name(name, library.target);
      }
    }
    return procedure;
  }

  Procedure get target => origin.procedure;

  @override
  int finishPatch() {
    if (!isPatch) return 0;

    // TODO(ahe): restore file-offset once we track both origin and patch file
    // URIs. See https://github.com/dart-lang/sdk/issues/31579
    origin.procedure.fileUri = fileUri;
    origin.procedure.startFileOffset = procedure.startFileOffset;
    origin.procedure.fileOffset = procedure.fileOffset;
    origin.procedure.fileEndOffset = procedure.fileEndOffset;
    origin.procedure.annotations
        .forEach((m) => m.fileOffset = procedure.fileOffset);

    origin.procedure.isAbstract = procedure.isAbstract;
    origin.procedure.isExternal = procedure.isExternal;
    origin.procedure.function = procedure.function;
    origin.procedure.function.parent = origin.procedure;
    return 1;
  }

  @override
  void becomeNative(Loader loader) {
    procedure.isExternal = true;
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
  final Constructor constructor;

  final int charOpenParenOffset;

  bool hasMovedSuperInitializer = false;

  SuperInitializer superInitializer;

  RedirectingInitializer redirectingInitializer;

  Token beginInitializers;

  @override
  ConstructorBuilder actualOrigin;

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
      : constructor = new Constructor(null, fileUri: compilationUnit?.fileUri)
          ..startFileOffset = startCharOffset
          ..fileOffset = charOffset
          ..fileEndOffset = charEndOffset,
        super(metadata, modifiers, returnType, name, typeVariables, formals,
            compilationUnit, charOffset, nativeMethodName);

  @override
  ConstructorBuilder get origin => actualOrigin ?? this;

  bool get isInstanceMember => false;

  bool get isConstructor => true;

  AsyncMarker get asyncModifier => AsyncMarker.Sync;

  ProcedureKind get kind => null;

  bool get isRedirectingGenerativeConstructor {
    return isRedirectingGenerativeConstructorImplementation(constructor);
  }

  bool get isEligibleForTopLevelInference {
    if (library.legacyMode) return false;
    if (formals != null) {
      for (var formal in formals) {
        if (formal.type == null && formal.isInitializingFormal) return true;
      }
    }
    return false;
  }

  Constructor build(SourceLibraryBuilder library) {
    if (constructor.name == null) {
      constructor.function = buildFunction(library);
      constructor.function.parent = constructor;
      constructor.function.fileOffset = charOpenParenOffset;
      constructor.function.fileEndOffset = constructor.fileEndOffset;
      constructor.function.typeParameters = const <TypeParameter>[];
      constructor.isConst = isConst;
      constructor.isExternal = isExternal;
      constructor.name = new Name(name, library.target);
    }
    if (isEligibleForTopLevelInference) {
      for (FormalParameterBuilder formal in formals) {
        if (formal.type == null && formal.isInitializingFormal) {
          formal.declaration.type = null;
        }
      }
      library.loader.typeInferenceEngine.toBeInferred[constructor] = library;
    }
    return constructor;
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
      if (library.loader is SourceLoader) {
        SourceLoader loader = library.loader;
        loader.transformPostInference(target, bodyBuilder.transformSetLiterals,
            bodyBuilder.transformCollections);
      }
      bodyBuilder.resolveRedirectingFactoryTargets();
    }
    beginInitializers = null;
  }

  FunctionNode buildFunction(LibraryBuilder library) {
    // According to the specification §9.3 the return type of a constructor
    // function is its enclosing class.
    FunctionNode functionNode = super.buildFunction(library);
    ClassBuilder enclosingClass = parent;
    List<DartType> typeParameterTypes = new List<DartType>();
    for (int i = 0; i < enclosingClass.target.typeParameters.length; i++) {
      TypeParameter typeParameter = enclosingClass.target.typeParameters[i];
      typeParameterTypes.add(new TypeParameterType(typeParameter));
    }
    functionNode.returnType =
        new InterfaceType(enclosingClass.target, typeParameterTypes);
    return functionNode;
  }

  Constructor get target => origin.constructor;

  void injectInvalidInitializer(
      Message message, int charOffset, ExpressionGeneratorHelper helper) {
    List<Initializer> initializers = constructor.initializers;
    Initializer lastInitializer = initializers.removeLast();
    assert(lastInitializer == superInitializer ||
        lastInitializer == redirectingInitializer);
    Initializer error = helper.buildInvalidInitializer(
        helper.desugarSyntheticExpression(
            helper.buildProblem(message, charOffset, noLength)),
        charOffset);
    initializers.add(error..parent = constructor);
    initializers.add(lastInitializer);
  }

  void addInitializer(
      Initializer initializer, ExpressionGeneratorHelper helper) {
    List<Initializer> initializers = constructor.initializers;
    if (initializer is SuperInitializer) {
      if (superInitializer != null || redirectingInitializer != null) {
        injectInvalidInitializer(messageMoreThanOneSuperOrThisInitializer,
            initializer.fileOffset, helper);
      } else {
        initializers.add(initializer..parent = constructor);
        superInitializer = initializer;
      }
    } else if (initializer is RedirectingInitializer) {
      if (superInitializer != null || redirectingInitializer != null) {
        injectInvalidInitializer(messageMoreThanOneSuperOrThisInitializer,
            initializer.fileOffset, helper);
      } else if (constructor.initializers.isNotEmpty) {
        Initializer first = constructor.initializers.first;
        Initializer error = helper.buildInvalidInitializer(
            helper.desugarSyntheticExpression(helper.buildProblem(
                messageThisInitializerNotAlone, first.fileOffset, noLength)),
            first.fileOffset);
        initializers.add(error..parent = constructor);
      } else {
        initializers.add(initializer..parent = constructor);
        redirectingInitializer = initializer;
      }
    } else if (redirectingInitializer != null) {
      injectInvalidInitializer(
          messageThisInitializerNotAlone, initializer.fileOffset, helper);
    } else if (superInitializer != null) {
      injectInvalidInitializer(
          messageSuperInitializerNotLast, superInitializer.fileOffset, helper);
    } else {
      initializers.add(initializer..parent = constructor);
    }
  }

  @override
  int finishPatch() {
    if (!isPatch) return 0;

    // TODO(ahe): restore file-offset once we track both origin and patch file
    // URIs. See https://github.com/dart-lang/sdk/issues/31579
    origin.constructor.fileUri = fileUri;
    origin.constructor.startFileOffset = constructor.startFileOffset;
    origin.constructor.fileOffset = constructor.fileOffset;
    origin.constructor.fileEndOffset = constructor.fileEndOffset;
    origin.constructor.annotations
        .forEach((m) => m.fileOffset = constructor.fileOffset);

    origin.constructor.isExternal = constructor.isExternal;
    origin.constructor.function = constructor.function;
    origin.constructor.function.parent = origin.constructor;
    origin.constructor.initializers = constructor.initializers;
    setParents(origin.constructor.initializers, origin.constructor);
    return 1;
  }

  @override
  void becomeNative(Loader loader) {
    constructor.isExternal = true;
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
    if (target.isConst) {
      target.initializers.length = 0;
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
