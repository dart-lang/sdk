// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/extensions.dart'; // ignore: implementation_imports
import 'package:analyzer/src/lint/constants.dart'; // ignore: implementation_imports
import 'package:collection/collection.dart' show IterableExtension;

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Prefer declaring `const` constructors on `@immutable` classes.';

class PreferConstConstructorsInImmutables extends AnalysisRule {
  PreferConstConstructorsInImmutables()
    : super(
        name: LintNames.prefer_const_constructors_in_immutables,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode => diag.preferConstConstructorsInImmutables;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
    registry.addPrimaryConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var element = node.declaredFragment?.element;
    if (element == null) return;
    if (element.isConst) return;
    if (node.body is! EmptyFunctionBody) return;
    var interfaceElement = element.enclosingElement;

    if (interfaceElement.mixins.isNotEmpty) return;
    if (!interfaceElement.hasImmutableAnnotation) return;

    if (element case ConstructorElement(
      isFactory: true,
      redirectedConstructor: ConstructorElement redirectedConstructor,
    )) {
      if (redirectedConstructor.isConst) {
        rule.reportAtToken(node.firstTokenAfterCommentAndMetadata);
      }
    } else if (_hasConstConstructorInvocation(
          element: node.declaredFragment?.element,
          initializers: node.initializers,
        ) &&
        node.canBeConst) {
      rule.reportAtToken(node.firstTokenAfterCommentAndMetadata);
    }
  }

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    var element = node.declaredFragment?.element;
    if (element == null) return;
    if (element.isConst) return;
    if (node.body?.body != null && node.body?.body is! EmptyFunctionBody) {
      return;
    }

    var interfaceElement = element.enclosingElement;
    if (interfaceElement.mixins.isNotEmpty) return;
    if (!interfaceElement.hasImmutableAnnotation) return;

    if (interfaceElement is ExtensionTypeElement) {
      rule.reportAtSourceRange(node.errorRange);
      return;
    }

    if (element case ConstructorElement(
      isFactory: true,
      redirectedConstructor: ConstructorElement redirectedConstructor,
    )) {
      if (redirectedConstructor.isConst) {
        rule.reportAtSourceRange(node.errorRange);
      }
    } else if (_hasConstConstructorInvocation(
          element: node.declaredFragment?.element,
          initializers: node.body?.initializers,
        ) &&
        node.canBeConst) {
      rule.reportAtSourceRange(node.errorRange);
    }
  }

  static bool _hasConstConstructorInvocation({
    required ConstructorElement? element,
    required List<ConstructorInitializer>? initializers,
  }) {
    if (element == null) return false;

    var interfaceElement = element.enclosingElement;
    // Constructor with super-initializer.
    var superInvocation = initializers
        ?.whereType<SuperConstructorInvocation>()
        .firstOrNull;
    if (superInvocation != null) {
      return superInvocation.element?.isConst ?? false;
    }
    // Constructor with 'this' redirecting initializer.
    var redirectInvocation = initializers
        ?.whereType<RedirectingConstructorInvocation>()
        .firstOrNull;
    if (redirectInvocation != null) {
      return redirectInvocation.element?.isConst ?? false;
    }

    if (interfaceElement is ExtensionTypeElement) {
      return interfaceElement.primaryConstructor.isConst;
    }

    // Constructor with implicit `super()` call.
    var unnamedSuperConstructor = interfaceElement.supertype?.constructors
        .firstWhereOrNull((e) => e.name == 'new');
    return unnamedSuperConstructor != null && unnamedSuperConstructor.isConst;
  }
}

extension on InterfaceElement {
  /// Whether this or any super-types are annotated with `@immutable`.
  bool get hasImmutableAnnotation {
    InterfaceElement? current = this;
    var seenElements = <InterfaceElement>{};
    while (current != null && seenElements.add(current)) {
      if (current.metadata.hasImmutable) return true;
      current = current.supertype?.element;
    }
    return false;
  }
}
