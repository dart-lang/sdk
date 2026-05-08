// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/generated/error_detection_helpers.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';

/// Helper for resolving [VariableDeclaration]s.
class VariableDeclarationResolver {
  final ResolverVisitor _resolver;
  final bool _strictInference;

  VariableDeclarationResolver({
    required ResolverVisitor resolver,
    required bool strictInference,
  }) : _resolver = resolver,
       _strictInference = strictInference;

  void resolve(VariableDeclarationImpl node) {
    var parent = node.parent as VariableDeclarationList;

    var initializer = node.initializer;

    if (initializer == null) {
      if (_strictInference && parent.type == null) {
        _resolver.diagnosticReporter.report(
          diag.inferenceFailureOnUninitializedVariable
              .withArguments(variable: node.name.lexeme)
              .at(node),
        );
      }
      return;
    }

    var element = node.declaredFragment!.element;
    var isTopLevel =
        element is FieldElement || element is TopLevelVariableElement;

    List<FormalParameterElementImpl>? inScopePrimaryConstructorParameters;
    if (element is FieldElementImpl &&
        element.isInstanceField &&
        !element.isLate) {
      inScopePrimaryConstructorParameters = element.enclosingElement
          .tryCast<InterfaceElementImpl>()
          ?.primaryConstructor
          ?.formalParameters;
    }

    if (isTopLevel) {
      _resolver.flowAnalysis.bodyOrInitializer_enter(
        node,
        inScopePrimaryConstructorParameters,
      );
      if (inScopePrimaryConstructorParameters != null) {
        _resolver.flowAnalysis.declarePrimaryConstructorParameters(
          inScopePrimaryConstructorParameters,
        );
      }
    } else if (element.isLate) {
      _resolver.flowAnalysis.flow?.lateInitializer_begin(node);
    }

    var contextType =
        element is! PropertyInducingElementImpl ||
            element.shouldUseTypeForInitializerInference
        ? element.type
        : UnknownInferredType.instance;
    _resolver.analyzeExpression(initializer, SharedTypeSchemaView(contextType));
    initializer = _resolver.popRewrite()!;
    var whyNotPromoted = _resolver.flowAnalysis.flow?.whyNotPromoted(
      _resolver.flowAnalysis.flow?.getExpressionInfo(initializer),
    );

    var initializerType = initializer.typeOrThrow;
    if (parent.type == null && element is LocalVariableElementImpl) {
      element.type = _resolver
          .variableTypeFromInitializerType(SharedTypeView(initializerType))
          .unwrapTypeView();
    }

    if (isTopLevel) {
      _resolver.flowAnalysis.bodyOrInitializer_exit();
      _resolver.nullSafetyDeadCodeVerifier.flowEnd(node);
    } else if (element.isLate) {
      _resolver.flowAnalysis.flow?.lateInitializer_end();
    }

    // Initializers of top-level variables and fields are already included
    // into elements during linking.
    if (element is LocalVariableElementImpl && element.isConst) {
      var fragment = element.firstFragment;
      fragment.constantInitializer = initializer;
    }

    _resolver.checkForAssignableExpressionAtType(
      initializer,
      initializerType,
      element.type,
      const NonAssignabilityReporterForAssignment(),
      whyNotPromoted: whyNotPromoted,
    );
  }
}
