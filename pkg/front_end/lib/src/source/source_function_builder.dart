// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../base/messages.dart'
    show
        messagePatchDeclarationMismatch,
        messagePatchDeclarationOrigin,
        messagePatchNonExternal,
        noLength,
        templateRequiredNamedParameterHasDefaultValueError;
import '../builder/builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/type_builder.dart';
import '../type_inference/type_inference_engine.dart'
    show IncludesTypeParametersNonCovariantly;
import 'source_library_builder.dart';
import 'source_type_parameter_builder.dart';

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
    List<SourceNominalParameterBuilder>? declaredTypeParameters,
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
    for (SourceNominalParameterBuilder t in declaredTypeParameters) {
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

// Coverage-ignore(suite): Not run.
/// Reports an error if [augmentation] is from a patch library and [origin] is
/// not external.
bool checkAugmentation(
    {required SourceLibraryBuilder augmentationLibraryBuilder,
    required Builder origin,
    required Builder augmentation}) {
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

// Coverage-ignore(suite): Not run.
/// Reports the error that [augmentation] cannot augment [origin].
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

extension FormalsMethods on List<FormalParameterBuilder> {
  /// Ensures the type of each of the formals is inferred.
  void infer(ClassHierarchy classHierarchy) {
    for (FormalParameterBuilder formal in this) {
      TypeBuilder formalType = formal.type;
      if (formalType is InferableTypeBuilder) {
        formalType.inferType(classHierarchy);
      }
    }
  }
}
