// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_procedure_builder;

import 'package:front_end/src/base/instrumentation.dart'
    show Instrumentation, InstrumentationValueForType;

import 'package:front_end/src/fasta/type_inference/type_inferrer.dart'
    show TypeInferrer;

import 'package:kernel/ast.dart'
    show
        Arguments,
        AsyncMarker,
        Constructor,
        ConstructorInvocation,
        DartType,
        DynamicType,
        EmptyStatement,
        Expression,
        FunctionNode,
        Initializer,
        LocalInitializer,
        Member,
        Name,
        NamedExpression,
        Procedure,
        ProcedureKind,
        RedirectingInitializer,
        Statement,
        StaticInvocation,
        StringLiteral,
        SuperInitializer,
        TypeParameter,
        VariableDeclaration,
        VariableGet,
        VoidType,
        setParents;

import 'package:kernel/type_algebra.dart' show containsTypeVariable, substitute;

import '../loader.dart' show Loader;

import '../messages.dart'
    show
        messageConstConstructorWithBody,
        messageInternalProblemBodyOnAbstractMethod,
        messageNonInstanceTypeVariableUse,
        messagePatchDeclarationMismatch,
        messagePatchDeclarationOrigin,
        messagePatchNonExternal;

import '../problems.dart' show internalProblem, unexpected;

import '../deprecated_problems.dart' show deprecated_inputError;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import 'kernel_builder.dart'
    show
        Builder,
        ClassBuilder,
        ConstructorReferenceBuilder,
        FormalParameterBuilder,
        KernelFormalParameterBuilder,
        KernelLibraryBuilder,
        KernelTypeBuilder,
        KernelTypeVariableBuilder,
        LibraryBuilder,
        MetadataBuilder,
        ProcedureBuilder,
        TypeVariableBuilder,
        isRedirectingGenerativeConstructorImplementation;

import 'kernel_shadow_ast.dart' show ShadowProcedure, ShadowVariableDeclaration;

import 'redirecting_factory_body.dart' show RedirectingFactoryBody;

abstract class KernelFunctionBuilder
    extends ProcedureBuilder<KernelTypeBuilder> {
  final String nativeMethodName;

  FunctionNode function;

  Statement actualBody;

  KernelFunctionBuilder(
      List<MetadataBuilder> metadata,
      int modifiers,
      KernelTypeBuilder returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      KernelLibraryBuilder compilationUnit,
      int charOffset,
      this.nativeMethodName)
      : super(metadata, modifiers, returnType, name, typeVariables, formals,
            compilationUnit, charOffset);

  KernelFunctionBuilder get actualOrigin;

  void set body(Statement newBody) {
    if (newBody != null) {
      if (isAbstract) {
        return internalProblem(messageInternalProblemBodyOnAbstractMethod,
            newBody.fileOffset, fileUri);
      }
      if (isConstructor && isConst) {
        return library.addCompileTimeError(
            messageConstConstructorWithBody, newBody.fileOffset, fileUri);
      }
    }
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

  void setRedirectingFactoryBody(Member target) {
    if (actualBody != null) {
      unexpected("null", "${actualBody.runtimeType}", charOffset, fileUri);
    }
    actualBody = new RedirectingFactoryBody(target);
    function.body = actualBody;
    actualBody?.parent = function;
    if (isPatch) {
      actualOrigin.setRedirectingFactoryBody(target);
    }
  }

  Statement get body => actualBody ??= new EmptyStatement();

  bool get isNative => nativeMethodName != null;

  FunctionNode buildFunction(LibraryBuilder library) {
    assert(function == null);
    FunctionNode result = new FunctionNode(body, asyncMarker: asyncModifier);
    if (typeVariables != null) {
      for (KernelTypeVariableBuilder t in typeVariables) {
        result.typeParameters.add(t.parameter);
      }
      setParents(result.typeParameters, result);
    }
    if (formals != null) {
      for (KernelFormalParameterBuilder formal in formals) {
        VariableDeclaration parameter = formal.build(library);
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
          new ShadowVariableDeclaration("#synthetic", 0);
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
              messageNonInstanceTypeVariableUse, charOffset, fileUri);
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
    return function = result;
  }

  Member build(SourceLibraryBuilder library);

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

  bool checkPatch(KernelFunctionBuilder patch) {
    if (!isExternal) {
      patch.library.addCompileTimeError(
          messagePatchNonExternal, patch.charOffset, patch.fileUri,
          context:
              messagePatchDeclarationOrigin.withLocation(fileUri, charOffset));
      return false;
    }
    return true;
  }

  void reportPatchMismatch(Builder patch) {
    library.addCompileTimeError(
        messagePatchDeclarationMismatch, patch.charOffset, patch.fileUri,
        context:
            messagePatchDeclarationOrigin.withLocation(fileUri, charOffset));
  }
}

class KernelProcedureBuilder extends KernelFunctionBuilder {
  final ShadowProcedure procedure;
  final int charOpenParenOffset;

  AsyncMarker actualAsyncModifier = AsyncMarker.Sync;

  final ConstructorReferenceBuilder redirectionTarget;

  @override
  KernelProcedureBuilder actualOrigin;

  KernelProcedureBuilder(
      List<MetadataBuilder> metadata,
      int modifiers,
      KernelTypeBuilder returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      ProcedureKind kind,
      KernelLibraryBuilder compilationUnit,
      int charOffset,
      this.charOpenParenOffset,
      int charEndOffset,
      [String nativeMethodName,
      this.redirectionTarget])
      : procedure = new ShadowProcedure(null, kind, null, returnType == null,
            fileUri: compilationUnit?.fileUri)
          ..fileOffset = charOffset
          ..fileEndOffset = charEndOffset,
        super(metadata, modifiers, returnType, name, typeVariables, formals,
            compilationUnit, charOffset, nativeMethodName);

  @override
  KernelProcedureBuilder get origin => actualOrigin ?? this;

  ProcedureKind get kind => procedure.kind;

  AsyncMarker get asyncModifier => actualAsyncModifier;

  Statement get body {
    if (actualBody == null &&
        redirectionTarget == null &&
        !isAbstract &&
        !isExternal) {
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

  Procedure build(SourceLibraryBuilder library) {
    // TODO(ahe): I think we may call this twice on parts. Investigate.
    if (procedure.name == null) {
      procedure.function = buildFunction(library);
      procedure.function.parent = procedure;
      procedure.function.fileOffset = charOpenParenOffset;
      procedure.function.fileEndOffset = procedure.fileEndOffset;
      procedure.isAbstract = isAbstract;
      procedure.isStatic = isStatic;
      procedure.isExternal = isExternal;
      procedure.isConst = isConst;
      procedure.name = new Name(name, library.target);
    }
    if (library.loader.target.strongMode &&
        (isSetter || (isOperator && name == '[]=')) &&
        returnType == null) {
      procedure.function.returnType = const VoidType();
    }
    return procedure;
  }

  Procedure get target => origin.procedure;

  @override
  void instrumentTopLevelInference(Instrumentation instrumentation) {
    bool isEligibleForTopLevelInference = this.isEligibleForTopLevelInference;
    if ((isEligibleForTopLevelInference || isSetter) && returnType == null) {
      instrumentation.record(procedure.fileUri, procedure.fileOffset, 'topType',
          new InstrumentationValueForType(procedure.function.returnType));
    }
    if (isEligibleForTopLevelInference) {
      if (formals != null) {
        for (var formal in formals) {
          if (formal.type == null) {
            VariableDeclaration formalTarget = formal.target;
            instrumentation.record(procedure.fileUri, formalTarget.fileOffset,
                'topType', new InstrumentationValueForType(formalTarget.type));
          }
        }
      }
    }
  }

  @override
  int finishPatch() {
    if (!isPatch) return 0;

    // TODO(ahe): restore file-offset once we track both origin and patch file
    // URIs. See https://github.com/dart-lang/sdk/issues/31579
    origin.procedure.fileUri = fileUri;
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
    if (patch is KernelProcedureBuilder) {
      if (checkPatch(patch)) {
        patch.actualOrigin = this;
      }
    } else {
      reportPatchMismatch(patch);
    }
  }
}

// TODO(ahe): Move this to own file?
class KernelConstructorBuilder extends KernelFunctionBuilder {
  final Constructor constructor;

  final int charOpenParenOffset;

  bool hasMovedSuperInitializer = false;

  SuperInitializer superInitializer;

  RedirectingInitializer redirectingInitializer;

  @override
  KernelConstructorBuilder actualOrigin;

  KernelConstructorBuilder(
      List<MetadataBuilder> metadata,
      int modifiers,
      KernelTypeBuilder returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      KernelLibraryBuilder compilationUnit,
      int charOffset,
      this.charOpenParenOffset,
      int charEndOffset,
      [String nativeMethodName])
      : constructor = new Constructor(null, fileUri: compilationUnit?.fileUri)
          ..fileOffset = charOffset
          ..fileEndOffset = charEndOffset,
        super(metadata, modifiers, returnType, name, typeVariables, formals,
            compilationUnit, charOffset, nativeMethodName);

  @override
  KernelConstructorBuilder get origin => actualOrigin ?? this;

  bool get isInstanceMember => false;

  bool get isConstructor => true;

  AsyncMarker get asyncModifier => AsyncMarker.Sync;

  ProcedureKind get kind => null;

  bool get isRedirectingGenerativeConstructor {
    return isRedirectingGenerativeConstructorImplementation(constructor);
  }

  Constructor build(SourceLibraryBuilder library) {
    if (constructor.name == null) {
      constructor.function = buildFunction(library);
      constructor.function.parent = constructor;
      constructor.function.fileOffset = charOpenParenOffset;
      constructor.function.fileEndOffset = constructor.fileEndOffset;
      constructor.isConst = isConst;
      constructor.isExternal = isExternal;
      constructor.name = new Name(name, library.target);
    }
    return constructor;
  }

  FunctionNode buildFunction(LibraryBuilder library) {
    // TODO(ahe): Should complain if another type is explicitly set.
    return super.buildFunction(library)..returnType = const VoidType();
  }

  Constructor get target => origin.constructor;

  void checkSuperOrThisInitializer(Initializer initializer) {
    if (superInitializer != null || redirectingInitializer != null) {
      return deprecated_inputError(fileUri, initializer.fileOffset,
          "Can't have more than one 'super' or 'this' initializer.");
    }
  }

  void addInitializer(Initializer initializer, TypeInferrer typeInferrer) {
    List<Initializer> initializers = constructor.initializers;
    if (initializer is SuperInitializer) {
      checkSuperOrThisInitializer(initializer);
      superInitializer = initializer;
    } else if (initializer is RedirectingInitializer) {
      checkSuperOrThisInitializer(initializer);
      redirectingInitializer = initializer;
      if (constructor.initializers.isNotEmpty) {
        deprecated_inputError(fileUri, initializer.fileOffset,
            "'this' initializer must be the only initializer.");
      }
    } else if (redirectingInitializer != null) {
      deprecated_inputError(fileUri, initializer.fileOffset,
          "'this' initializer must be the only initializer.");
    } else if (superInitializer != null) {
      // If there is a super initializer ([initializer] isn't it), we need to
      // insert [initializer] before the super initializer (thus ensuring that
      // the super initializer is always last).
      assert(superInitializer != initializer);
      assert(initializers.last == superInitializer);
      initializers.removeLast();
      if (!hasMovedSuperInitializer) {
        // To preserve correct evaluation order, the arguments to super call
        // must be evaluated before [initializer]. Once the super initializer
        // has been moved once, the arguments are evaluated in the correct
        // order.
        hasMovedSuperInitializer = true;
        Arguments arguments = superInitializer.arguments;
        List<Expression> positional = arguments.positional;
        for (int i = 0; i < positional.length; i++) {
          var type = typeInferrer.typeSchemaEnvironment.strongMode
              ? positional[i].getStaticType(typeInferrer.typeSchemaEnvironment)
              : const DynamicType();
          VariableDeclaration variable = new VariableDeclaration.forValue(
              positional[i],
              isFinal: true,
              type: type);
          initializers
              .add(new LocalInitializer(variable)..parent = constructor);
          positional[i] = new VariableGet(variable)..parent = arguments;
        }
        for (NamedExpression named in arguments.named) {
          VariableDeclaration variable =
              new VariableDeclaration.forValue(named.value, isFinal: true);
          named.value = new VariableGet(variable)..parent = named;
          initializers
              .add(new LocalInitializer(variable)..parent = constructor);
        }
      }
      initializers.add(initializer..parent = constructor);
      initializers.add(superInitializer);
      return;
    }
    initializers.add(initializer);
    initializer.parent = constructor;
  }

  @override
  int finishPatch() {
    if (!isPatch) return 0;

    // TODO(ahe): restore file-offset once we track both origin and patch file
    // URIs. See https://github.com/dart-lang/sdk/issues/31579
    origin.constructor.fileUri = fileUri;
    origin.constructor.fileOffset = constructor.fileOffset;
    origin.constructor.fileEndOffset = constructor.fileEndOffset;
    origin.constructor.annotations
        .forEach((m) => m.fileOffset = constructor.fileOffset);

    origin.constructor.isExternal = constructor.isExternal;
    origin.constructor.function = constructor.function;
    origin.constructor.function.parent = constructor.function;
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
    if (patch is KernelConstructorBuilder) {
      if (checkPatch(patch)) {
        patch.actualOrigin = this;
      }
    } else {
      reportPatchMismatch(patch);
    }
  }
}
