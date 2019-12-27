// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

import '../analyzer.dart';
import '../rules.dart';
import '../utils.dart';

const String _INCOMPATIBLE_WITH_CLASS_NAME = 'IncompatibleWith';
const String _LINT_RULE_CLASS_NAME = 'LintRule';
const String _LINTER_META_LIB_NAME = 'linter_meta';

bool _isIncompatibleWithAnnotation(Element element) =>
    element is ConstructorElement &&
    element.enclosingElement.name == _INCOMPATIBLE_WITH_CLASS_NAME &&
    element.library?.name == _LINTER_META_LIB_NAME;

class LintCache {
  List<LintRuleDetails> details = <LintRuleDetails>[];

  bool _initialized = false;

  LintRuleDetails findDetailsByClassName(String className) {
    for (var detail in details) {
      if (detail.className == className) {
        return detail;
      }
    }
    return null;
  }

  LintRuleDetails findDetailsById(String id) {
    for (var detail in details) {
      if (detail.id == id) {
        return detail;
      }
    }
    return null;
  }

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    registerLintRules();

    // Setup details.
    for (var lint in Analyzer.facade.registeredRules) {
      details.add(LintRuleDetails(lint.runtimeType.toString(), lint.name));
    }

    // Process compatibility annotations.
    final rulePath = File('lib/src/rules').absolute.path;
    final collection = AnalysisContextCollection(
      includedPaths: [rulePath],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );

    final visitor = _LintVisitor();
    for (var context in collection.contexts) {
      for (var filePath in context.contextRoot.analyzedFiles()) {
        if (isDartFileName(filePath)) {
          final result = await context.currentSession.getResolvedUnit(filePath);
          result.unit.accept(visitor);
        }
      }
    }

    for (var classElement in visitor.classElements) {
      for (var annotation in classElement.metadata) {
        if (_isIncompatibleWithAnnotation(annotation.element)) {
          final constantValue = annotation.computeConstantValue();
          final ruleObjects = constantValue?.getField('rules')?.toListValue();
          if (ruleObjects != null) {
            final lintClassName = classElement.thisType.name;
            final ruleDetails = findDetailsByClassName(lintClassName);
            for (var ruleObject in ruleObjects) {
              final ruleId = ruleObject.toStringValue();
              ruleDetails.incompatibleRules.add(ruleId);
            }
          }
        }
      }
    }
    _initialized = true;
  }
}

class LintRuleDetails {
  final String className;
  final String id;
  final List<String> incompatibleRules = <String>[];
  LintRuleDetails(this.className, this.id);

  @override
  String toString() => '$className:$id';
}

class _LintVisitor extends RecursiveAstVisitor {
  final List<ClassElement> classElements = <ClassElement>[];

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final classElement = node.declaredElement;
    if (classElement == null) {
      return;
    }

    for (var superType in classElement.allSupertypes) {
      if (superType.name == _LINT_RULE_CLASS_NAME) {
        classElements.add(classElement);
        return;
      }
    }
  }
}
