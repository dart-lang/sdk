// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/resolver/invocation_inference_helper.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Data constructor containing information about the result of performing type
/// inference on an instance creation (either an InstanceCreationExpression or
/// an Annotation that refers to a constructor).
class InstanceCreationInferenceResult {
  /// The refined constructor element (after type inference)
  final ConstructorElement constructorElement;

  /// The type that was constructed (after type inference)
  final DartType constructedType;

  InstanceCreationInferenceResult(
      {required this.constructorElement, required this.constructedType});
}

/// Mixin containing shared functionality for resolving AST nodes that may
/// create instances (InstanceCreationExpression and Annotation).
mixin InstanceCreationResolverMixin {
  ResolverVisitor get resolver;

  /// Performs the first step of type inference for a constructor invocation.
  InstanceCreationInferenceResult? inferArgumentTypes(
      {required AstNode inferenceNode,
      required ConstructorElement? constructorElement,
      required ConstructorElementToInfer? elementToInfer,
      required TypeArgumentListImpl? typeArguments,
      required ArgumentListImpl arguments,
      required AstNode errorNode,
      required bool isConst}) {
    InstanceCreationInferenceResult? inferenceResult;
    FunctionType? inferred;

    // If the constructor is generic, we'll have a ConstructorMember that
    // substitutes in type arguments (possibly `dynamic`) from earlier in
    // resolution.
    //
    // Otherwise we'll have a ConstructorElement, and we can skip inference
    // because there's nothing to infer in a non-generic type.
    if (elementToInfer != null) {
      // TODO(leafp): Currently, we may re-infer types here, since we
      // sometimes resolve multiple times.  We should really check that we
      // have not already inferred something.  However, the obvious ways to
      // check this don't work, since we may have been instantiated
      // to bounds in an earlier phase, and we *do* want to do inference
      // in that case.

      // Get back to the uninstantiated generic constructor.
      // TODO(jmesserly): should we store this earlier in resolution?
      // Or look it up, instead of jumping backwards through the Member?
      var rawElement = elementToInfer.element;
      var constructorType = elementToInfer.asType;

      inferred = resolver.inferenceHelper.inferArgumentTypesForGeneric(
          inferenceNode, constructorType, typeArguments,
          isConst: isConst, errorNode: errorNode);

      if (inferred != null) {
        // Fix up the parameter elements based on inferred method.
        arguments.correspondingStaticParameters =
            ResolverVisitor.resolveArgumentsToParameters(
          argumentList: arguments,
          parameters: inferred.parameters,
        );

        // Update the static element as well. This is used in some cases, such
        // as computing constant values. It is stored in two places.
        constructorElement = ConstructorMember.from(
          rawElement,
          inferred.returnType as InterfaceType,
        );
        inferenceResult = InstanceCreationInferenceResult(
            constructorElement: constructorElement,
            constructedType: inferred.returnType);
      }
    }

    if (inferred == null) {
      if (constructorElement != null) {
        var type = constructorElement.type;
        type = resolver.toLegacyTypeIfOptOut(type) as FunctionType;
      }
    }

    return inferenceResult;
  }
}
