// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:meta/meta_meta.dart';

import '../analyzer.dart';

const _desc = r'Attach library annotations to library directives.';

class LibraryAnnotations extends LintRule {
  LibraryAnnotations()
    : super(name: LintNames.library_annotations, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.library_annotations;

  @override
  void registerNodeProcessors(NodeLintRegistry registry, RuleContext context) {
    var visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LibraryAnnotations rule;

  Directive? firstDirective;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    if (node.directives.isNotEmpty) {
      firstDirective = node.directives.first;
    }
    for (var directive in node.directives) {
      if (directive is PartOfDirective) return;

      if (directive is! LibraryDirective) {
        _check(directive);
      }
    }

    node.declarations.forEach(_check);
  }

  void _check(AnnotatedNode node) {
    for (var annotation in node.metadata) {
      var elementAnnotation = annotation.elementAnnotation;
      if (elementAnnotation == null) {
        return;
      }

      if (elementAnnotation.targetKinds.length == 1 &&
          elementAnnotation.targetKinds.contains(TargetKind.library) &&
          firstDirective == node) {
        rule.reportAtNode(annotation);
      } else if (elementAnnotation.isPragmaLateTrust) {
        rule.reportAtNode(annotation);
      }
    }
  }
}

extension on ElementAnnotation {
  /// Whether this is an annotation of the form `@pragma('dart2js:late:trust')`.
  bool get isPragmaLateTrust {
    if (_isConstructor(libraryName: 'dart.core', className: 'pragma')) {
      var value = computeConstantValue();
      var nameValue = value?.getField('name');
      return nameValue?.toStringValue() == 'dart2js:late:trust';
    }
    return false;
  }

  // Copied from package:analyzer/src/dart/element/element.dart
  bool _isConstructor({
    required String libraryName,
    required String className,
  }) {
    var element = element2;
    return element is ConstructorElement &&
        element.enclosingElement.name == className &&
        element.library.name == libraryName;
  }
}
