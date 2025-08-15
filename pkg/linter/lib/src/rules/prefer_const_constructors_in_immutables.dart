// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/lint/constants.dart'; // ignore: implementation_imports
import 'package:collection/collection.dart' show IterableExtension;

import '../analyzer.dart';

const _desc = r'Prefer declaring `const` constructors on `@immutable` classes.';

class PreferConstConstructorsInImmutables extends LintRule {
  PreferConstConstructorsInImmutables()
    : super(
        name: LintNames.prefer_const_constructors_in_immutables,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.preferConstConstructorsInImmutables;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
    registry.addExtensionTypeDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var element = node.declaredFragment?.element;
    if (element == null) return;
    if (element.isConst) return;
    if (node.body is! EmptyFunctionBody) return;
    var enclosingElement = element.enclosingElement;

    if (enclosingElement.mixins.isNotEmpty) return;
    if (!_hasImmutableAnnotation(enclosingElement)) return;
    var isRedirected =
        element.isFactory && element.redirectedConstructor != null;
    if (isRedirected && (element.redirectedConstructor?.isConst ?? false)) {
      rule.reportAtToken(node.firstTokenAfterCommentAndMetadata);
    }
    if (!isRedirected &&
        _hasConstConstructorInvocation(node) &&
        node.canBeConst) {
      rule.reportAtToken(node.firstTokenAfterCommentAndMetadata);
    }
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    if (node.constKeyword != null) return;
    var element = node.declaredFragment?.element;
    if (element == null) return;
    if (element.metadata.hasImmutable) {
      rule.reportAtToken(node.name);
    }
  }

  static List<InterfaceElement> _getSelfAndSuperClasses(InterfaceElement self) {
    InterfaceElement? current = self;
    var seenElements = <InterfaceElement>{};
    while (current != null && seenElements.add(current)) {
      current = current.supertype?.element;
    }
    return seenElements.toList();
  }

  static bool _hasConstConstructorInvocation(ConstructorDeclaration node) {
    var declaredElement = node.declaredFragment?.element;
    if (declaredElement == null) {
      return false;
    }
    var clazz = declaredElement.enclosingElement;
    // Constructor with super-initializer.
    var superInvocation =
        node.initializers.whereType<SuperConstructorInvocation>().firstOrNull;
    if (superInvocation != null) {
      return superInvocation.element?.isConst ?? false;
    }
    // Constructor with 'this' redirecting initializer.
    var redirectInvocation =
        node.initializers
            .whereType<RedirectingConstructorInvocation>()
            .firstOrNull;
    if (redirectInvocation != null) {
      return redirectInvocation.element?.isConst ?? false;
    }

    if (clazz is ExtensionTypeElement) {
      return clazz.primaryConstructor.isConst;
    }

    // Constructor with implicit `super()` call.
    var unnamedSuperConstructor = clazz.supertype?.constructors
        .firstWhereOrNull((e) => e.name == 'new');
    return unnamedSuperConstructor != null && unnamedSuperConstructor.isConst;
  }

  /// Whether [clazz] or any of its super-types are annotated with
  /// `@immutable`.
  static bool _hasImmutableAnnotation(InterfaceElement clazz) {
    var selfAndInheritedClasses = _getSelfAndSuperClasses(clazz);
    return selfAndInheritedClasses.any((cls) => cls.metadata.hasImmutable);
  }
}
