// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_procedure_builder;

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
        messageExternalMethodWithBody,
        messageInternalProblemBodyOnAbstractMethod,
        messageNonInstanceTypeVariableUse,
        warning;

import '../problems.dart' show internalProblem;

import '../deprecated_problems.dart' show deprecated_inputError;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import '../type_inference/type_inference_listener.dart'
    show TypeInferenceListener;

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

import 'kernel_shadow_ast.dart' show ShadowProcedure;

abstract class KernelFunctionBuilder
    extends ProcedureBuilder<KernelTypeBuilder> {
  final String nativeMethodName;

  FunctionNode function;

  Statement actualBody;

  KernelFunctionBuilder(
      String documentationComment,
      List<MetadataBuilder> metadata,
      int modifiers,
      KernelTypeBuilder returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      KernelLibraryBuilder compilationUnit,
      int charOffset,
      this.nativeMethodName)
      : super(documentationComment, metadata, modifiers, returnType, name,
            typeVariables, formals, compilationUnit, charOffset);

  void set body(Statement newBody) {
    if (newBody != null) {
      if (isAbstract) {
        return internalProblem(messageInternalProblemBodyOnAbstractMethod,
            newBody.fileOffset, fileUri);
      }
      if (isExternal) {
        return library.addCompileTimeError(
            messageExternalMethodWithBody, newBody.fileOffset, fileUri);
      }
      if (isConstructor && isConst) {
        return library.addCompileTimeError(
            messageConstConstructorWithBody, newBody.fileOffset, fileUri);
      }
    }
    actualBody = newBody;
    if (function != null) {
      function.body = newBody;
      newBody?.parent = function;
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
          warning(messageNonInstanceTypeVariableUse, charOffset, fileUri);
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
    target.isExternal = true;
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
}

class KernelProcedureBuilder extends KernelFunctionBuilder {
  final ShadowProcedure procedure;
  final int charOpenParenOffset;

  AsyncMarker actualAsyncModifier = AsyncMarker.Sync;

  final ConstructorReferenceBuilder redirectionTarget;

  KernelProcedureBuilder(
      String documentationComment,
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
            fileUri: compilationUnit?.relativeFileUri)
          ..fileOffset = charOffset
          ..fileEndOffset = charEndOffset,
        super(
            documentationComment,
            metadata,
            modifiers,
            returnType,
            name,
            typeVariables,
            formals,
            compilationUnit,
            charOffset,
            nativeMethodName);

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
    } else {
      if (isSetter && returnType == null) return true;
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
      procedure.documentationComment = documentationComment;
    }
    if (isEligibleForTopLevelInference) {
      library.loader.typeInferenceEngine.recordMember(procedure);
    }
    return procedure;
  }

  Procedure get target => procedure;

  @override
  void prepareTopLevelInference(
      SourceLibraryBuilder library, ClassBuilder currentClass) {
    if (isEligibleForTopLevelInference) {
      var typeInferenceEngine = library.loader.typeInferenceEngine;
      var listener = new TypeInferenceListener();
      typeInferenceEngine.createTopLevelTypeInferrer(
          listener, procedure.enclosingClass?.thisType, procedure);
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

  KernelConstructorBuilder(
      String documentationComment,
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
      : constructor = new Constructor(null)
          ..fileOffset = charOffset
          ..fileEndOffset = charEndOffset,
        super(
            documentationComment,
            metadata,
            modifiers,
            returnType,
            name,
            typeVariables,
            formals,
            compilationUnit,
            charOffset,
            nativeMethodName);

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
      constructor.documentationComment = documentationComment;
    }
    return constructor;
  }

  FunctionNode buildFunction(LibraryBuilder library) {
    // TODO(ahe): Should complain if another type is explicitly set.
    return super.buildFunction(library)..returnType = const VoidType();
  }

  Constructor get target => constructor;

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
}
