// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.procedure_builder;

import 'dart:core' hide MapEntry;

import 'package:front_end/src/fasta/kernel/kernel_api.dart';
import 'package:kernel/ast.dart';

import 'package:kernel/type_algebra.dart' show containsTypeVariable, substitute;

import '../identifiers.dart';
import '../scope.dart';

import '../kernel/internal_ast.dart' show VariableDeclarationImpl;
import '../kernel/redirecting_factory_body.dart' show RedirectingFactoryBody;

import '../loader.dart' show Loader;

import '../messages.dart'
    show
        messageNonInstanceTypeVariableUse,
        messagePatchDeclarationMismatch,
        messagePatchDeclarationOrigin,
        messagePatchNonExternal,
        noLength,
        templateRequiredNamedParameterHasDefaultValueError;

import '../modifier.dart';

import '../problems.dart' show unexpected;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import '../type_inference/type_inference_engine.dart'
    show IncludesTypeParametersNonCovariantly;

import 'builder.dart';
import 'class_builder.dart';
import 'extension_builder.dart';
import 'formal_parameter_builder.dart';
import 'library_builder.dart';
import 'member_builder.dart';
import 'metadata_builder.dart';
import 'type_builder.dart';
import 'type_variable_builder.dart';

/// Common base class for constructor and procedure builders.
abstract class FunctionBuilder implements MemberBuilder {
  List<MetadataBuilder> get metadata;

  TypeBuilder get returnType;

  List<TypeVariableBuilder> get typeVariables;

  List<FormalParameterBuilder> get formals;

  AsyncMarker get asyncModifier;

  ProcedureKind get kind;

  bool get isAbstract;

  bool get isConstructor;

  bool get isRegularMethod;

  bool get isGetter;

  bool get isSetter;

  bool get isOperator;

  bool get isFactory;

  /// This is the formal parameter scope as specified in the Dart Programming
  /// Language Specification, 4th ed, section 9.2.
  Scope computeFormalParameterScope(Scope parent);

  Scope computeFormalParameterInitializerScope(Scope parent);

  /// This scope doesn't correspond to any scope specified in the Dart
  /// Programming Language Specification, 4th ed. It's an unspecified extension
  /// to support generic methods.
  Scope computeTypeParameterScope(Scope parent);

  FormalParameterBuilder getFormal(Identifier identifier);

  String get nativeMethodName;

  FunctionNode get function;

  FunctionBuilder get actualOrigin;

  Statement get body;

  void set body(Statement newBody);

  void setRedirectingFactoryBody(Member target, List<DartType> typeArguments);

  bool get isNative;

  /// Returns the [index]th parameter of this function.
  ///
  /// The index is the syntactical index, including both positional and named
  /// parameter in the order they are declared, and excluding the synthesized
  /// this parameter on extension instance members.
  VariableDeclaration getFormalParameter(int index);

  /// If this is an extension instance method, the tear off closure parameter
  /// corresponding to the [index]th parameter on the instance method is
  /// returned.
  ///
  /// This is used to update the default value for the closure parameter when
  /// it has been computed for the original parameter.
  VariableDeclaration getExtensionTearOffParameter(int index);

  /// Returns the parameter for 'this' synthetically added to extension
  /// instance members.
  VariableDeclaration get extensionThis;

  /// Returns a list of synthetic type parameters added to extension instance
  /// members.
  List<TypeParameter> get extensionTypeParameters;

  void becomeNative(Loader loader);

  bool checkPatch(FunctionBuilder patch);

  void reportPatchMismatch(Builder patch);
}

/// Common base class for constructor and procedure builders.
abstract class FunctionBuilderImpl extends MemberBuilderImpl
    implements FunctionBuilder {
  @override
  final List<MetadataBuilder> metadata;

  @override
  final int modifiers;

  @override
  final TypeBuilder returnType;

  @override
  final String name;

  @override
  final List<TypeVariableBuilder> typeVariables;

  @override
  final List<FormalParameterBuilder> formals;

  /// If this procedure is an extension instance member, [_extensionThis] holds
  /// the synthetically added `this` parameter.
  VariableDeclaration _extensionThis;

  /// If this procedure is an extension instance member,
  /// [_extensionTypeParameters] holds the type parameters copied from the
  /// extension declaration.
  List<TypeParameter> _extensionTypeParameters;

  FunctionBuilderImpl(
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

  @override
  String get debugName => "FunctionBuilder";

  @override
  AsyncMarker get asyncModifier;

  @override
  bool get isConstructor => false;

  @override
  bool get isAbstract => (modifiers & abstractMask) != 0;

  @override
  bool get isRegularMethod => identical(ProcedureKind.Method, kind);

  @override
  bool get isGetter => identical(ProcedureKind.Getter, kind);

  @override
  bool get isSetter => identical(ProcedureKind.Setter, kind);

  @override
  bool get isOperator => identical(ProcedureKind.Operator, kind);

  @override
  bool get isFactory => identical(ProcedureKind.Factory, kind);

  @override
  bool get isExternal => (modifiers & externalMask) != 0;

  @override
  bool get isAssignable => false;

  @override
  Scope computeFormalParameterScope(Scope parent) {
    if (formals == null) return parent;
    Map<String, Builder> local = <String, Builder>{};
    for (FormalParameterBuilder formal in formals) {
      if (!isConstructor || !formal.isInitializingFormal) {
        local[formal.name] = formal;
      }
    }
    return new Scope(
        local: local,
        parent: parent,
        debugName: "formal parameter",
        isModifiable: false);
  }

  @override
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
    return new Scope(
        local: local,
        parent: parent,
        debugName: "formal parameter initializer",
        isModifiable: false);
  }

  @override
  Scope computeTypeParameterScope(Scope parent) {
    if (typeVariables == null) return parent;
    Map<String, Builder> local = <String, Builder>{};
    for (TypeVariableBuilder variable in typeVariables) {
      local[variable.name] = variable;
    }
    return new Scope(
        local: local,
        parent: parent,
        debugName: "type parameter",
        isModifiable: false);
  }

  @override
  FormalParameterBuilder getFormal(Identifier identifier) {
    if (formals != null) {
      for (FormalParameterBuilder formal in formals) {
        if (formal.name == identifier.name &&
            formal.charOffset == identifier.charOffset) {
          return formal;
        }
      }
      // If we have any formals we should find the one we're looking for.
      assert(false, "$identifier not found in $formals");
    }
    return null;
  }

  @override
  final String nativeMethodName;

  @override
  FunctionNode function;

  Statement bodyInternal;

  @override
  void set body(Statement newBody) {
//    if (newBody != null) {
//      if (isAbstract) {
//        // TODO(danrubel): Is this check needed?
//        return internalProblem(messageInternalProblemBodyOnAbstractMethod,
//            newBody.fileOffset, fileUri);
//      }
//    }
    bodyInternal = newBody;
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

  @override
  void setRedirectingFactoryBody(Member target, List<DartType> typeArguments) {
    if (bodyInternal != null) {
      unexpected("null", "${bodyInternal.runtimeType}", charOffset, fileUri);
    }
    bodyInternal = new RedirectingFactoryBody(target, typeArguments);
    function.body = bodyInternal;
    bodyInternal?.parent = function;
    if (isPatch) {
      actualOrigin.setRedirectingFactoryBody(target, typeArguments);
    }
  }

  @override
  Statement get body => bodyInternal ??= new EmptyStatement();

  @override
  bool get isNative => nativeMethodName != null;

  FunctionNode buildFunction(SourceLibraryBuilder library) {
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
        VariableDeclaration parameter = formal.build(
            library, 0, !isConstructor && !isDeclarationInstanceMember);
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

        if (library.isNonNullableByDefault) {
          // Required named parameters can't have default values.
          if (formal.isNamedRequired && formal.initializerToken != null) {
            library.addProblem(
                templateRequiredNamedParameterHasDefaultValueError
                    .withArguments(formal.name),
                formal.charOffset,
                formal.name.length,
                formal.fileUri);
          }
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
          new VariableDeclarationImpl("#synthetic", 0);
      result.positionalParameters.clear();
      result.positionalParameters.add(parameter);
      parameter.parent = result;
      result.namedParameters.clear();
      result.requiredParameterCount = 1;
    }
    if (returnType != null) {
      result.returnType = returnType.build(
          library, null, !isConstructor && !isDeclarationInstanceMember);
    }
    if (!isConstructor && !isDeclarationInstanceMember) {
      List<TypeParameter> typeParameters;
      if (parent is ClassBuilder) {
        ClassBuilder enclosingClassBuilder = parent;
        typeParameters = enclosingClassBuilder.cls.typeParameters;
      } else if (parent is ExtensionBuilder) {
        ExtensionBuilder enclosingExtensionBuilder = parent;
        typeParameters = enclosingExtensionBuilder.extension.typeParameters;
      }

      if (typeParameters != null && typeParameters.isNotEmpty) {
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
        _extensionTypeParameters = new List<TypeParameter>.filled(count, null);
        for (int index = 0; index < count; index++) {
          _extensionTypeParameters[index] = result.typeParameters[index];
        }
      }
    }
    return function = result;
  }

  @override
  VariableDeclaration getFormalParameter(int index) {
    if (isExtensionInstanceMember) {
      return formals[index + 1].variable;
    } else {
      return formals[index].variable;
    }
  }

  @override
  VariableDeclaration getExtensionTearOffParameter(int index) => null;

  @override
  VariableDeclaration get extensionThis {
    assert(_extensionThis != null || !isExtensionInstanceMember,
        "ProcedureBuilder.extensionThis has not been set.");
    return _extensionThis;
  }

  @override
  List<TypeParameter> get extensionTypeParameters {
    // Use [_extensionThis] as marker for whether extension type parameters have
    // been computed.
    assert(_extensionThis != null || !isExtensionInstanceMember,
        "ProcedureBuilder.extensionTypeParameters has not been set.");
    return _extensionTypeParameters;
  }

  bool _hasBuiltOutlineExpressions = false;

  @override
  void buildOutlineExpressions(LibraryBuilder library, CoreTypes coreTypes) {
    if (!_hasBuiltOutlineExpressions) {
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
      _hasBuiltOutlineExpressions = true;
    }
  }

  Member build(SourceLibraryBuilder library);

  @override
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

  @override
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

  @override
  void reportPatchMismatch(Builder patch) {
    library.addProblem(messagePatchDeclarationMismatch, patch.charOffset,
        noLength, patch.fileUri, context: [
      messagePatchDeclarationOrigin.withLocation(fileUri, charOffset, noLength)
    ]);
  }
}
