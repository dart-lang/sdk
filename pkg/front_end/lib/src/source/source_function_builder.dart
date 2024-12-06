// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../api_prototype/lowering_predicates.dart';
import '../base/identifiers.dart';
import '../base/local_scope.dart';
import '../base/messages.dart'
    show
        messagePatchDeclarationMismatch,
        messagePatchDeclarationOrigin,
        messagePatchNonExternal,
        noLength,
        templateRequiredNamedParameterHasDefaultValueError;
import '../base/modifiers.dart';
import '../base/scope.dart';
import '../builder/builder.dart';
import '../builder/constructor_builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/function_builder.dart';
import '../builder/member_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/type_builder.dart';
import '../kernel/internal_ast.dart' show VariableDeclarationImpl;
import '../kernel/kernel_helper.dart';
import '../type_inference/type_inference_engine.dart'
    show IncludesTypeParametersNonCovariantly;
import 'source_builder_mixins.dart';
import 'source_extension_type_declaration_builder.dart';
import 'source_library_builder.dart';
import 'source_loader.dart' show SourceLoader;
import 'source_member_builder.dart';

abstract class SourceFunctionBuilder
    implements FunctionBuilder, SourceMemberBuilder {
  List<MetadataBuilder>? get metadata;

  TypeBuilder get returnType;

  List<NominalParameterBuilder>? get typeParameters;

  List<FormalParameterBuilder>? get formals;

  @override
  bool get isAbstract;

  @override
  bool get isConstructor;

  @override
  bool get isRegularMethod;

  @override
  bool get isGetter;

  @override
  bool get isSetter;

  @override
  bool get isOperator;

  @override
  bool get isFactory;

  /// This is the formal parameter scope as specified in the Dart Programming
  /// Language Specification, 4th ed, section 9.2.
  LocalScope computeFormalParameterScope(LookupScope parent);

  LocalScope computeFormalParameterInitializerScope(LocalScope parent);

  FormalParameterBuilder? getFormal(Identifier identifier);

  Statement? get body;

  void set body(Statement? newBody);

  bool get isNative;

  /// Returns the [index]th parameter of this function.
  ///
  /// The index is the syntactical index, including both positional and named
  /// parameter in the order they are declared, and excluding the synthesized
  /// this parameter on extension instance members.
  VariableDeclaration getFormalParameter(int index);

  /// If this is an extension instance method or constructor with lowering
  /// enabled, the tear off parameter corresponding to the [index]th parameter
  /// on the instance method or constructor is returned.
  ///
  /// This is used to update the default value for the closure parameter when
  /// it has been computed for the original parameter.
  VariableDeclaration? getTearOffParameter(int index);

  /// Returns the parameter for 'this' synthetically added to extension
  /// instance members.
  VariableDeclaration? get thisVariable;

  /// Returns a list of synthetic type parameters added to extension instance
  /// members.
  List<TypeParameter>? get thisTypeParameters;

  void becomeNative(SourceLoader loader);
}

/// Common base class for constructor and procedure builders.
abstract class SourceFunctionBuilderImpl extends SourceMemberBuilderImpl
    implements SourceFunctionBuilder, InferredTypeListener {
  @override
  final List<MetadataBuilder>? metadata;

  final Modifiers modifiers;

  @override
  final String name;

  @override
  final List<NominalParameterBuilder>? typeParameters;

  @override
  final List<FormalParameterBuilder>? formals;

  /// If this procedure is an extension instance member or extension type
  /// instance member, [_thisVariable] holds the synthetically added `this`
  /// parameter.
  VariableDeclaration? _thisVariable;

  /// If this procedure is an extension instance member or extension type
  /// instance member, [_thisTypeParameters] holds the type parameters copied
  /// from the extension/extension type declaration.
  List<TypeParameter>? _thisTypeParameters;

  SourceFunctionBuilderImpl(this.metadata, this.modifiers, this.name,
      this.typeParameters, this.formals, this.nativeMethodName) {
    returnType.registerInferredTypeListener(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<MetadataBuilder>? get metadataForTesting => metadata;

  AsyncMarker get asyncModifier;

  @override
  bool get isAugmentation => modifiers.isAugment;

  @override
  bool get isExternal => modifiers.isExternal;

  @override
  bool get isAbstract => modifiers.isAbstract;

  @override
  bool get isConst => modifiers.isConst;

  @override
  bool get isStatic => modifiers.isStatic;

  @override
  bool get isAugment => modifiers.isAugment;

  @override
  bool get isConstructor => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isAssignable => false;

  /// Returns `true` if this member is augmented, either by being the origin
  /// of a augmented member or by not being the last among augmentations.
  bool get isAugmented;

  @override
  LocalScope computeFormalParameterScope(LookupScope parent) {
    if (formals == null) return new FormalParameterScope(parent: parent);
    Map<String, Builder> local = <String, Builder>{};
    for (FormalParameterBuilder formal in formals!) {
      if (formal.isWildcard) {
        continue;
      }
      if (!isConstructor ||
          !formal.isInitializingFormal && !formal.isSuperInitializingFormal) {
        local[formal.name] = formal;
      }
    }
    return new FormalParameterScope(local: local, parent: parent);
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
    Map<String, Builder> local = <String, Builder>{};
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

  // TODO(johnniwinther): Remove this.
  LookupScope computeTypeParameterScope(LookupScope parent) {
    if (typeParameters == null) return parent;
    Map<String, Builder> local = <String, Builder>{};
    for (NominalParameterBuilder variable in typeParameters!) {
      if (variable.isWildcard) continue;
      local[variable.name] = variable;
    }
    return new TypeParameterScope(parent, local);
  }

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

  final String? nativeMethodName;

  Statement? bodyInternal;

  @override
  void set body(Statement? newBody) {
//    if (newBody != null) {
//      if (isAbstract) {
//        // TODO(danrubel): Is this check needed?
//        return internalProblem(messageInternalProblemBodyOnAbstractMethod,
//            newBody.fileOffset, fileUri);
//      }
//    }
    bodyInternal = newBody;
    // A forwarding semi-stub is a method that is abstract in the source code,
    // but which needs to have a forwarding stub body in order to ensure that
    // covariance checks occur.  We don't want to replace the forwarding stub
    // body with null.
    TreeNode? parent = function.parent;
    if (!(newBody == null &&
        // Coverage-ignore(suite): Not run.
        parent is Procedure &&
        // Coverage-ignore(suite): Not run.
        parent.isForwardingSemiStub)) {
      function.body = newBody;
      newBody?.parent = function;
    }
  }

  @override
  bool get isNative => nativeMethodName != null;

  bool get supportsTypeParameters => true;

  void buildFunction() {
    function.asyncMarker = asyncModifier;
    function.body = body;
    body?.parent = function;
    List<TypeParameter>? classTypeParameters;
    if (!isConstructor && !isFactory && parent is ClassBuilder) {
      Class enclosingClass = classBuilder!.cls;
      classTypeParameters = enclosingClass.typeParameters;
    }
    buildTypeParametersAndFormals(
        libraryBuilder, function, typeParameters, formals,
        classTypeParameters: classTypeParameters,
        supportsTypeParameters: supportsTypeParameters);
    if (!(isExtensionInstanceMember || isExtensionTypeInstanceMember) &&
        isSetter &&
        (formals?.length != 1 || formals![0].isOptionalPositional)) {
      // Replace illegal parameters by single dummy parameter.
      // Do this after building the parameters, since the diet listener
      // assumes that parameters are built, even if illegal in number.
      VariableDeclaration parameter = new VariableDeclarationImpl("#synthetic");
      function.positionalParameters.clear();
      function.positionalParameters.add(parameter);
      parameter.parent = function;
      function.namedParameters.clear();
      function.requiredParameterCount = 1;
    } else if ((isExtensionInstanceMember || isExtensionTypeInstanceMember) &&
        isSetter &&
        (formals?.length != 2 || formals![1].isOptionalPositional)) {
      // Replace illegal parameters by single dummy parameter (after #this).
      // Do this after building the parameters, since the diet listener
      // assumes that parameters are built, even if illegal in number.
      VariableDeclaration thisParameter = function.positionalParameters[0];
      VariableDeclaration parameter = new VariableDeclarationImpl("#synthetic");
      function.positionalParameters.clear();
      function.positionalParameters.add(thisParameter);
      function.positionalParameters.add(parameter);
      parameter.parent = function;
      function.namedParameters.clear();
      function.requiredParameterCount = 2;
    }
    if (returnType is! InferableTypeBuilder) {
      function.returnType =
          returnType.build(libraryBuilder, TypeUse.returnType);
    }
    if (isExtensionInstanceMember || isExtensionTypeInstanceMember) {
      SourceDeclarationBuilderMixin declarationBuilder =
          parent as SourceDeclarationBuilderMixin;
      if (declarationBuilder.typeParameters != null) {
        int count = declarationBuilder.typeParameters!.length;
        _thisTypeParameters = new List<TypeParameter>.generate(
            count, (int index) => function.typeParameters[index],
            growable: false);
      }
      if (isExtensionTypeInstanceMember && isConstructor) {
        SourceExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder =
            parent as SourceExtensionTypeDeclarationBuilder;
        List<DartType> typeArguments;
        if (_thisTypeParameters != null) {
          typeArguments = new List<DartType>.generate(
              _thisTypeParameters!.length,
              (int index) => new TypeParameterType(
                  _thisTypeParameters![index],
                  TypeParameterType.computeNullabilityFromBound(
                      _thisTypeParameters![index])));
        } else {
          typeArguments = [];
        }
        _thisVariable = new VariableDeclarationImpl(syntheticThisName,
            isFinal: true,
            type: new ExtensionType(
                extensionTypeDeclarationBuilder.extensionTypeDeclaration,
                Nullability.nonNullable,
                typeArguments))
          ..fileOffset = fileOffset
          ..isLowered = true;
      } else {
        _thisVariable = function.positionalParameters.first;
      }
    }
  }

  @override
  VariableDeclaration getFormalParameter(int index) {
    if (this is! ConstructorBuilder &&
        (isExtensionInstanceMember || isExtensionTypeInstanceMember)) {
      return formals![index + 1].variable!;
    } else {
      return formals![index].variable!;
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  VariableDeclaration? getTearOffParameter(int index) => null;

  @override
  VariableDeclaration? get thisVariable {
    assert(
        _thisVariable != null ||
            !(isExtensionInstanceMember || isExtensionTypeInstanceMember),
        "ProcedureBuilder.thisVariable has not been set.");
    return _thisVariable;
  }

  @override
  List<TypeParameter>? get thisTypeParameters {
    // Use [_thisVariable] as marker for whether this type parameters have
    // been computed.
    assert(
        _thisVariable != null ||
            !(isExtensionInstanceMember || isExtensionTypeInstanceMember),
        "ProcedureBuilder.thisTypeParameters has not been set.");
    return _thisTypeParameters;
  }

  @override
  void onInferredType(DartType type) {
    function.returnType = type;
  }

  bool hasBuiltOutlineExpressions = false;

  @override
  void buildOutlineExpressions(ClassHierarchy classHierarchy,
      List<DelayedDefaultValueCloner> delayedDefaultValueCloners) {
    if (!hasBuiltOutlineExpressions) {
      DeclarationBuilder? classOrExtensionBuilder =
          isClassMember || isExtensionMember || isExtensionTypeMember
              ? parent as DeclarationBuilder
              : null;
      LookupScope parentScope =
          classOrExtensionBuilder?.scope ?? libraryBuilder.scope;
      for (Annotatable annotatable in annotatables) {
        MetadataBuilder.buildAnnotations(annotatable, metadata,
            createBodyBuilderContext(), libraryBuilder, fileUri, parentScope,
            createFileUriExpression: isAugmented);
      }
      if (typeParameters != null) {
        for (int i = 0; i < typeParameters!.length; i++) {
          typeParameters![i].buildOutlineExpressions(
              libraryBuilder,
              createBodyBuilderContext(),
              classHierarchy,
              computeTypeParameterScope(parentScope));
        }
      }

      if (formals != null) {
        // For const constructors we need to include default parameter values
        // into the outline. For all other formals we need to call
        // buildOutlineExpressions to clear initializerToken to prevent
        // consuming too much memory.
        for (FormalParameterBuilder formal in formals!) {
          formal.buildOutlineExpressions(libraryBuilder, declarationBuilder,
              buildDefaultValue: FormalParameterBuilder
                  .needsDefaultValuesBuiltAsOutlineExpressions(this));
        }
      }
      hasBuiltOutlineExpressions = true;
    }
  }

  @override
  void becomeNative(SourceLoader loader) {
    MemberBuilder constructor = loader.getNativeAnnotation();
    for (Annotatable annotatable in annotatables) {
      Arguments arguments =
          new Arguments(<Expression>[new StringLiteral(nativeMethodName!)]);
      Expression annotation;
      if (constructor.isConstructor) {
        annotation = new ConstructorInvocation(
            constructor.invokeTarget as Constructor, arguments)
          ..isConst = true;
      } else {
        // Coverage-ignore-block(suite): Not run.
        annotation = new StaticInvocation(
            constructor.invokeTarget as Procedure, arguments)
          ..isConst = true;
      }

      annotatable.addAnnotation(annotation);
    }
  }
}

/// Builds the [TypeParameter]s for [declaredTypeParameters] and the parameter
/// [VariableDeclaration]s for [declaredFormals] and adds them to [function].
///
/// If [classTypeParameters] the bounds on type parameters and formal parameter
/// types will be marked as `isCovariantByClass` depending on their use of the
/// [classTypeParameters].
///
/// If [supportsTypeParameters] is false, declared type parameters are not added
/// to the function. This is done to avoid adding type parameters to
/// [Constructor]s which don't support them.
void buildTypeParametersAndFormals(
    SourceLibraryBuilder libraryBuilder,
    FunctionNode function,
    List<NominalParameterBuilder>? declaredTypeParameters,
    List<FormalParameterBuilder>? declaredFormals,
    {required List<TypeParameter>? classTypeParameters,
    required bool supportsTypeParameters}) {
  IncludesTypeParametersNonCovariantly? needsCheckVisitor;
  if (classTypeParameters != null && classTypeParameters.isNotEmpty) {
    needsCheckVisitor =
        new IncludesTypeParametersNonCovariantly(classTypeParameters,
            // We are checking the parameter types which are in a
            // contravariant position.
            initialVariance: Variance.contravariant);
  }
  if (declaredTypeParameters != null) {
    for (NominalParameterBuilder t in declaredTypeParameters) {
      TypeParameter parameter = t.parameter;
      if (supportsTypeParameters) {
        function.typeParameters.add(parameter);
      }
      if (needsCheckVisitor != null) {
        if (parameter.bound.accept(needsCheckVisitor)) {
          parameter.isCovariantByClass = true;
        }
      }
    }
    setParents(function.typeParameters, function);
  }
  if (declaredFormals != null) {
    for (FormalParameterBuilder formal in declaredFormals) {
      VariableDeclaration parameter = formal.build(libraryBuilder);
      if (needsCheckVisitor != null) {
        if (parameter.type.accept(needsCheckVisitor)) {
          parameter.isCovariantByClass = true;
        }
      }
      if (formal.isNamed) {
        function.namedParameters.add(parameter);
      } else {
        function.positionalParameters.add(parameter);
      }
      parameter.parent = function;
      if (formal.isRequiredPositional) {
        function.requiredParameterCount++;
      }

      // Required named parameters can't have default values.
      if (formal.isRequiredNamed && formal.initializerToken != null) {
        libraryBuilder.addProblem(
            templateRequiredNamedParameterHasDefaultValueError
                .withArguments(formal.name),
            formal.fileOffset,
            formal.name.length,
            formal.fileUri);
      }
    }
  }
}

/// Reports an error if [augmentation] is from a patch library and [origin] is
/// not external.
bool checkAugmentation(
    {required SourceLibraryBuilder augmentationLibraryBuilder,
    required Builder origin,
    required Builder augmentation}) {
  // Coverage-ignore-block(suite): Not run.
  if (!origin.isExternal && !augmentationLibraryBuilder.isAugmentationLibrary) {
    augmentationLibraryBuilder.addProblem(messagePatchNonExternal,
        augmentation.fileOffset, noLength, augmentation.fileUri!,
        context: [
          messagePatchDeclarationOrigin.withLocation(
              origin.fileUri!, origin.fileOffset, noLength)
        ]);
    return false;
  }
  return true;
}

/// Reports the error that [augmentation] cannot augment [origin].
// Coverage-ignore(suite): Not run.
void reportAugmentationMismatch(
    {required SourceLibraryBuilder originLibraryBuilder,
    required Builder origin,
    required Builder augmentation}) {
  originLibraryBuilder.addProblem(messagePatchDeclarationMismatch,
      augmentation.fileOffset, noLength, augmentation.fileUri!,
      context: [
        messagePatchDeclarationOrigin.withLocation(
            origin.fileUri!, origin.fileOffset, noLength)
      ]);
}
