// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/resolver/type_analyzer.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/generated/error_detection_helpers.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';

/// Helper for resolving [VariableDeclaration]s.
class VariableDeclarationResolver {
  final TypeAnalyzer _typeAnalyzer;
  final bool _strictInference;

  VariableDeclarationResolver({
    required TypeAnalyzer typeAnalyzer,
    required bool strictInference,
  }) : _typeAnalyzer = typeAnalyzer,
       _strictInference = strictInference;

  void resolve(VariableDeclarationImpl node) {
    var parent = node.parent2 as VariableDeclarationList;

    var initializer = node.initializer2;

    if (initializer == null) {
      if (_strictInference && parent.type == null) {
        _typeAnalyzer.diagnosticReporter.report(
          diag.inferenceFailureOnUninitializedVariable
              .withArguments(variable: node.name.lexeme)
              .at(node),
        );
      }
      return;
    }

    var element = node.declaredFragment!.element;
    bool isTopLevel;
    bool bindsThis;
    if (element is FieldElementImpl) {
      isTopLevel = true;
      bindsThis = !element.isStatic && element.isLate;
    } else if (element is TopLevelVariableElement) {
      isTopLevel = true;
      bindsThis = false;
    } else {
      isTopLevel = false;
      bindsThis = false;
    }

    List<FormalParameterElementImpl>? inScopePrimaryConstructorParameters;
    if (element is FieldElementImpl &&
        element.isInstanceField &&
        !element.isLate) {
      inScopePrimaryConstructorParameters = element.enclosingElement
          .tryCast<InterfaceElementImpl>()
          ?.primaryConstructor
          ?.formalParameters;
    }

    var beforeInitializerOffset = node.equals!.offset;
    if (isTopLevel) {
      _typeAnalyzer.flowAnalysis.flowAnalysisRoot_enter(
        node,
        inScopePrimaryConstructorParameters,
        offset: beforeInitializerOffset,
      );
      if (inScopePrimaryConstructorParameters != null) {
        _typeAnalyzer.flowAnalysis.declarePrimaryConstructorParameters(
          inScopePrimaryConstructorParameters,
          offset: beforeInitializerOffset,
        );
      }
    } else if (element.isLate) {
      _typeAnalyzer.flowAnalysis.flow?.lateInitializer_begin(
        node,
        offset: beforeInitializerOffset,
      );
    }
    if (bindsThis) {
      _typeAnalyzer.flowAnalysis.flow?.thisBinding_begin(
        null,
        thisType: SharedTypeView(_typeAnalyzer.thisType!),
        offset: initializer.offset,
      );
    }

    var contextType =
        element is PropertyInducingElementImpl &&
            element.isTypeInferredFromInitializer
        ? UnknownInferredType.instance
        : element.type;
    _typeAnalyzer.withThisAccessibility(
      bindsThis || _typeAnalyzer.isThisAccessible,
      () => _typeAnalyzer.analyzeExpression(
        initializer!,
        SharedTypeSchemaView(contextType),
      ),
    );
    initializer = _typeAnalyzer.popRewrite()!;
    var whyNotPromoted = _typeAnalyzer.flowAnalysis.flow?.whyNotPromoted(
      _typeAnalyzer.flowAnalysis.getExpressionInfo(initializer),
    );

    var initializerType = initializer.typeOrThrow;
    if (parent.type == null && element is LocalVariableElementImpl) {
      element.type = _typeAnalyzer
          .variableTypeFromInitializerType(SharedTypeView(initializerType))
          .unwrapTypeView();
    }

    if (bindsThis) {
      _typeAnalyzer.flowAnalysis.flow?.thisBinding_end(offset: initializer.end);
    }
    if (isTopLevel) {
      _typeAnalyzer.flowAnalysis.flowAnalysisRoot_exit();
      _typeAnalyzer.nullSafetyDeadCodeVerifier.flowEnd(node);
    } else if (element.isLate) {
      _typeAnalyzer.flowAnalysis.flow?.lateInitializer_end(offset: node.end);
    }

    // Initializers of top-level variables and fields are already included
    // into elements during linking.
    if (element is LocalVariableElementImpl && element.isConst) {
      var fragment = element.firstFragment;
      fragment.constantInitializer2 = initializer;
    }

    _typeAnalyzer.checkForAssignableExpressionAtType(
      initializer,
      initializerType,
      element.type,
      const NonAssignabilityReporterForAssignment(),
      whyNotPromoted: whyNotPromoted,
    );
  }
}
