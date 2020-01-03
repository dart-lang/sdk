// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r'Prefer declaring const constructors on `@immutable` classes.';

const _details = r'''

**PREFER** declaring const constructors on `@immutable` classes.

If a class is immutable, it is usually a good idea to make its constructor a
const constructor.

**GOOD:**
```
@immutable
class A {
  final a;
  const A(this.a);
}
```

**BAD:**
```
@immutable
class A {
  final a;
  A(this.a);
}
```

''';

/// The name of the top-level variable used to mark a immutable class.
String _IMMUTABLE_VAR_NAME = 'immutable';

/// The name of `meta` library, used to define analysis annotations.
String _META_LIB_NAME = 'meta';

bool _isImmutable(Element element) =>
    element is PropertyAccessorElement &&
    element.name == _IMMUTABLE_VAR_NAME &&
    element.library?.name == _META_LIB_NAME;

class PreferConstConstructorsInImmutables extends LintRule
    implements NodeLintRule {
  PreferConstConstructorsInImmutables()
      : super(
            name: 'prefer_const_constructors_in_immutables',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this, context);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final element = node.declaredElement;
    final isRedirected =
        element.isFactory && element.redirectedConstructor != null;
    if (node.body is EmptyFunctionBody &&
        !element.isConst &&
        !_hasMixin(element.enclosingElement) &&
        _hasImmutableAnnotation(element.enclosingElement) &&
        (isRedirected && element.redirectedConstructor.isConst ||
            (!isRedirected &&
                _hasConstConstructorInvocation(node) &&
                context.canBeConstConstructor(node)))) {
      rule.reportLintForToken(node.firstTokenAfterCommentAndMetadata);
    }
  }

  bool _hasConstConstructorInvocation(ConstructorDeclaration node) {
    final clazz = node.declaredElement.enclosingElement;
    // construct with super
    final superInvocation = node.initializers.firstWhere(
        (e) => e is SuperConstructorInvocation,
        orElse: () => null) as SuperConstructorInvocation;
    if (superInvocation != null) return superInvocation.staticElement.isConst;
    // construct with this
    final redirectInvocation = node.initializers.firstWhere(
        (e) => e is RedirectingConstructorInvocation,
        orElse: () => null) as RedirectingConstructorInvocation;
    if (redirectInvocation != null) {
      return redirectInvocation.staticElement.isConst;
    }
    // construct with implicit super()
    return clazz.supertype.constructors
        .firstWhere((e) => e.name.isEmpty)
        .isConst;
  }

  bool _hasImmutableAnnotation(ClassElement clazz) {
    final selfAndInheritedClasses = _getSelfAndInheritedClasses(clazz);
    final selfAndInheritedAnnotations =
        selfAndInheritedClasses.expand((c) => c.metadata).map((m) => m.element);
    return selfAndInheritedAnnotations.any(_isImmutable);
  }

  bool _hasMixin(ClassElement clazz) => clazz.mixins.isNotEmpty;

  static Iterable<ClassElement> _getSelfAndInheritedClasses(
      ClassElement self) sync* {
    var current = self;
    final seenElements = <ClassElement>{};
    while (current != null && seenElements.add(current)) {
      yield current;
      current = current.supertype?.element;
    }
  }
}
