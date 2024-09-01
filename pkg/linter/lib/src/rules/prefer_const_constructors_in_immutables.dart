// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/lint/linter.dart'; // ignore: implementation_imports
import 'package:collection/collection.dart' show IterableExtension;

import '../analyzer.dart';
import '../extensions.dart';
import '../linter_lint_codes.dart';

const _desc = r'Prefer declaring `const` constructors on `@immutable` classes.';

const _details = r'''
**PREFER** declaring `const` constructors on `@immutable` classes.

If a class is immutable, it is usually a good idea to make its constructor a
`const` constructor.

**BAD:**
```dart
@immutable
class A {
  final a;
  A(this.a);
}
```

**GOOD:**
```dart
@immutable
class A {
  final a;
  const A(this.a);
}
```

''';

class PreferConstConstructorsInImmutables extends LintRule {
  PreferConstConstructorsInImmutables()
      : super(
            name: 'prefer_const_constructors_in_immutables',
            description: _desc,
            details: _details,
            categories: {LintRuleCategory.style});

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
    var element = node.declaredElement;
    if (element == null) return;
    if (element.isConst) return;
    if (node.body is! EmptyFunctionBody) return;
    var enclosingElement = element.enclosingElement3;
    if (enclosingElement.isMacro) return;
    if (enclosingElement.mixins.isNotEmpty) return;
    if (!_hasImmutableAnnotation(enclosingElement)) return;
    var isRedirected =
        element.isFactory && element.redirectedConstructor != null;
    if (isRedirected && (element.redirectedConstructor?.isConst ?? false)) {
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
    var element = node.declaredElement;
    if (element == null) return;
    if (element.hasImmutable) {
      rule.reportLintForToken(node.name);
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
    var declaredElement = node.declaredElement;
    if (declaredElement == null) {
      return false;
    }
    var clazz = declaredElement.enclosingElement3;
    // Constructor with super-initializer.
    var superInvocation =
        node.initializers.whereType<SuperConstructorInvocation>().firstOrNull;
    if (superInvocation != null) {
      return superInvocation.staticElement?.isConst ?? false;
    }
    // Constructor with 'this' redirecting initializer.
    var redirectInvocation = node.initializers
        .whereType<RedirectingConstructorInvocation>()
        .firstOrNull;
    if (redirectInvocation != null) {
      return redirectInvocation.staticElement?.isConst ?? false;
    }

    if (clazz is ExtensionTypeElement) {
      return clazz.primaryConstructor.isConst;
    }

    // Constructor with implicit `super()` call.
    var unnamedSuperConstructor =
        clazz.supertype?.constructors.firstWhereOrNull((e) => e.name.isEmpty);
    return unnamedSuperConstructor != null && unnamedSuperConstructor.isConst;
  }

  /// Whether [clazz] or any of its super-types are annotated with
  /// `@immutable`.
  static bool _hasImmutableAnnotation(InterfaceElement clazz) {
    var selfAndInheritedClasses = _getSelfAndSuperClasses(clazz);
    return selfAndInheritedClasses.any((cls) => cls.hasImmutable);
  }
}
