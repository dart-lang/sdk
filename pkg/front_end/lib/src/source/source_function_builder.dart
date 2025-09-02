// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';

import '../base/messages.dart'
    show codeRequiredNamedParameterHasDefaultValueError;
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
  List<FormalParameterBuilder>? declaredFormals, {
  required List<TypeParameter>? classTypeParameters,
  required bool supportsTypeParameters,
}) {
  IncludesTypeParametersNonCovariantly? needsCheckVisitor;
  if (classTypeParameters != null && classTypeParameters.isNotEmpty) {
    needsCheckVisitor = new IncludesTypeParametersNonCovariantly(
      classTypeParameters,
      // We are checking the parameter types which are in a
      // contravariant position.
      initialVariance: Variance.contravariant,
    );
  }
  if (declaredTypeParameters != null) {
    for (int i = 0; i < declaredTypeParameters.length; i++) {
      SourceNominalParameterBuilder t = declaredTypeParameters[i];
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
    for (int i = 0; i < declaredFormals.length; i++) {
      FormalParameterBuilder formal = declaredFormals[i];
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
          codeRequiredNamedParameterHasDefaultValueError.withArguments(
            formal.name,
          ),
          formal.fileOffset,
          formal.name.length,
          formal.fileUri,
        );
      }
    }
  }
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
