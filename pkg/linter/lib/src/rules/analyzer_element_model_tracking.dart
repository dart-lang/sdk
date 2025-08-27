// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../lint_codes.dart';

const _desc = 'Specify element model tracking annotation.';

class AnalyzerElementModelTracking extends MultiAnalysisRule {
  static const ruleName = 'analyzer_element_model_tracking';

  AnalyzerElementModelTracking()
    : super(
        name: ruleName,
        description: _desc,
        state: const RuleState.internal(),
      );

  @override
  List<DiagnosticCode> get diagnosticCodes => [
    LinterLintCode.analyzerElementModelTrackingBad,
    LinterLintCode.analyzerElementModelTrackingMoreThanOne,
    LinterLintCode.analyzerElementModelTrackingZero,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addClassDeclaration(this, visitor);
  }
}

class _TrackingAnnotation {
  final Annotation node;
  final ElementAnnotation element;

  _TrackingAnnotation({required this.node, required this.element});
}

class _Visitor extends SimpleAstVisitor<void> {
  final MultiAnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    var element = node.declaredFragment!.element;
    if (element.isElementClass) {
      for (var member in node.members) {
        var trackingAnnotations = member.metadata
            .map((node) => node.asTrackingAnnotation)
            .nonNulls
            .toList();

        switch (member) {
          case ConstructorDeclaration():
            trackingAnnotations.forEach(_reportBad);
          case FieldDeclaration fieldDeclaration:
            for (var field in fieldDeclaration.fields.variables) {
              var fieldElement =
                  field.declaredFragment!.element as FieldElement;
              if (fieldElement.isPublic && fieldElement.isInstance) {
                var hasRequired = false;
                for (var annotation in trackingAnnotations) {
                  if (annotation.element.isTrackedIncludedInId) {
                    if (hasRequired) {
                      _reportMoreThanOne(annotation);
                    }
                    hasRequired = true;
                  } else {
                    _reportBad(annotation);
                  }
                }
                if (!hasRequired) {
                  _reportMissing(field.name);
                }
              } else {
                trackingAnnotations.forEach(_reportBad);
              }
            }
          case MethodDeclaration methodDeclaration:
            var element = methodDeclaration.declaredFragment!.element;
            switch (element) {
              case GetterElement getterElement:
                if (getterElement.isPublic &&
                    getterElement.isInstance &&
                    !getterElement.isAbstract) {
                  var hasRequired = false;
                  for (var annotation in trackingAnnotations) {
                    if (annotation.element.isTrackedDirectly ||
                        annotation.element.isTrackedDirectlyExpensive ||
                        annotation.element.isTrackedDirectlyOpaque ||
                        annotation.element.isTrackedIncludedInId ||
                        annotation.element.isTrackedIndirectly) {
                      if (hasRequired) {
                        _reportMoreThanOne(annotation);
                      }
                      hasRequired = true;
                    } else {
                      _reportBad(annotation);
                    }
                  }
                  if (!hasRequired) {
                    _reportMissing(methodDeclaration.name);
                  }
                } else {
                  trackingAnnotations.forEach(_reportBad);
                }
              case SetterElement():
                trackingAnnotations.forEach(_reportBad);
              case MethodElement methodElement:
                if (methodElement.isPublic &&
                    methodElement.isInstance &&
                    !methodElement.isAbstract &&
                    methodElement.returnType is! VoidType) {
                  var hasRequired = false;
                  for (var annotation in trackingAnnotations) {
                    if (annotation.element.isTrackedDirectly ||
                        annotation.element.isTrackedDirectlyExpensive ||
                        annotation.element.isTrackedDirectlyOpaque ||
                        annotation.element.isTrackedIncludedInId ||
                        annotation.element.isTrackedIndirectly) {
                      if (hasRequired) {
                        _reportMoreThanOne(annotation);
                      }
                      hasRequired = true;
                    } else {
                      _reportBad(annotation);
                    }
                  }
                  if (!hasRequired) {
                    _reportMissing(methodDeclaration.name);
                  }
                } else {
                  trackingAnnotations.forEach(_reportBad);
                }
            }
        }
      }
    }
  }

  void _reportBad(_TrackingAnnotation annotation) {
    rule.reportAtNode(
      annotation.node,
      diagnosticCode: LinterLintCode.analyzerElementModelTrackingBad,
    );
  }

  void _reportMissing(Token name) {
    rule.reportAtToken(
      name,
      diagnosticCode: LinterLintCode.analyzerElementModelTrackingZero,
    );
  }

  void _reportMoreThanOne(_TrackingAnnotation annotation) {
    rule.reportAtNode(
      annotation.node,
      diagnosticCode: LinterLintCode.analyzerElementModelTrackingMoreThanOne,
    );
  }
}

extension on Annotation {
  _TrackingAnnotation? get asTrackingAnnotation {
    if (elementAnnotation case var annotation?) {
      if (annotation.isAnyTracked) {
        return _TrackingAnnotation(node: this, element: annotation);
      }
    }
    return null;
  }
}

extension on ElementAnnotation {
  bool get isAnyTracked =>
      isTrackedDirectly ||
      isTrackedDirectlyExpensive ||
      isTrackedDirectlyOpaque ||
      isTrackedIncludedInId ||
      isTrackedIndirectly;

  bool get isElementClass => _isAnnotation('elementClass');

  bool get isTrackedDirectly => _isAnnotation('trackedDirectly');

  bool get isTrackedDirectlyExpensive =>
      _isAnnotation('trackedDirectlyExpensive');

  bool get isTrackedDirectlyOpaque => _isAnnotation('trackedDirectlyOpaque');

  bool get isTrackedIncludedInId => _isAnnotation('trackedIncludedInId');

  bool get isTrackedIndirectly => _isAnnotation('trackedIndirectly');

  bool _isAnnotation(String name) {
    if (element case GetterElement element) {
      return element.name == name &&
          element.library.uri.toString() ==
              'package:analyzer/src/fine/annotations.dart';
    }
    return false;
  }
}

extension on FieldElement {
  bool get isInstance => !isStatic;
}

extension on GetterElement {
  bool get isInstance => !isStatic;
}

extension on MethodElement {
  bool get isInstance => !isStatic;
}

extension on ClassElement {
  bool get isElementClass => metadata.annotations.any((e) => e.isElementClass);
}
