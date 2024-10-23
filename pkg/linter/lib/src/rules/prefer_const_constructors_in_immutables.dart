// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/lint/linter.dart'; // ignore: implementation_imports
import 'package:collection/collection.dart' show IterableExtension;

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Prefer declaring `const` constructors on `@immutable` classes.';

class PreferConstConstructorsInImmutables extends LintRule {
  PreferConstConstructorsInImmutables()
      : super(
          name: LintNames.prefer_const_constructors_in_immutables,
          description: _desc,
        );

  @override
  LintCode get lintCode =>
      LinterLintCode.prefer_const_constructors_in_immutables;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
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
    var enclosingElement = element.enclosingElement2;
    if (enclosingElement.isMacro) return;

    if (enclosingElement.mixins.isNotEmpty) return;
    if (!_hasImmutableAnnotation(enclosingElement)) return;
    var isRedirected =
        element.isFactory && element.redirectedConstructor2 != null;
    if (isRedirected && (element.redirectedConstructor2?.isConst ?? false)) {
      rule.reportLintForToken(node.firstTokenAfterCommentAndMetadata);
    }
    if (!isRedirected &&
        _hasConstConstructorInvocation(node) &&
        node.canBeConst) {
      rule.reportLintForToken(node.firstTokenAfterCommentAndMetadata);
    }
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    if (node.constKeyword != null) return;
    var element = node.declaredFragment?.element;
    if (element == null) return;
    if (element.metadata2.hasImmutable) {
      rule.reportLintForToken(node.name);
    }
  }

  static List<InterfaceElement2> _getSelfAndSuperClasses(
      InterfaceElement2 self) {
    InterfaceElement2? current = self;
    var seenElements = <InterfaceElement2>{};
    while (current != null && seenElements.add(current)) {
      current = current.supertype?.element3;
    }
    return seenElements.toList();
  }

  static bool _hasConstConstructorInvocation(ConstructorDeclaration node) {
    var declaredElement = node.declaredFragment?.element;
    if (declaredElement == null) {
      return false;
    }
    var clazz = declaredElement.enclosingElement2;
    // Constructor with super-initializer.
    var superInvocation =
        node.initializers.whereType<SuperConstructorInvocation>().firstOrNull;
    if (superInvocation != null) {
      return superInvocation.element?.isConst ?? false;
    }
    // Constructor with 'this' redirecting initializer.
    var redirectInvocation = node.initializers
        .whereType<RedirectingConstructorInvocation>()
        .firstOrNull;
    if (redirectInvocation != null) {
      return redirectInvocation.element?.isConst ?? false;
    }

    if (clazz is ExtensionTypeElement2) {
      return clazz.primaryConstructor2.isConst;
    }

    // Constructor with implicit `super()` call.
    var unnamedSuperConstructor = clazz.supertype?.constructors2
        .firstWhereOrNull((e) => e.name3 == 'new');
    return unnamedSuperConstructor != null && unnamedSuperConstructor.isConst;
  }

  /// Whether [clazz] or any of its super-types are annotated with
  /// `@immutable`.
  static bool _hasImmutableAnnotation(InterfaceElement2 clazz) {
    var selfAndInheritedClasses = _getSelfAndSuperClasses(clazz);
    return selfAndInheritedClasses.any((cls) => cls.metadata2.hasImmutable);
  }
}
