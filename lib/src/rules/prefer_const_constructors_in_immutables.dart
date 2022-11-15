// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart' show IterableExtension;

import '../analyzer.dart';

const _desc = r'Prefer declaring const constructors on `@immutable` classes.';

const _details = r'''
**PREFER** declaring const constructors on `@immutable` classes.

If a class is immutable, it is usually a good idea to make its constructor a
const constructor.

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

/// The name of the top-level variable used to mark a immutable class.
String _immutableVarName = 'immutable';

/// The name of `meta` library, used to define analysis annotations.
String _metaLibName = 'meta';

bool _isImmutable(Element? element) =>
    element is PropertyAccessorElement &&
    element.name == _immutableVarName &&
    element.library.name == _metaLibName;

class PreferConstConstructorsInImmutables extends LintRule {
  static const LintCode code = LintCode(
      'prefer_const_constructors_in_immutables',
      "Constructors in '@immutable' classes should be declared as 'const'.",
      correctionMessage: "Try adding 'const' to the constructor declaration.");

  PreferConstConstructorsInImmutables()
      : super(
            name: 'prefer_const_constructors_in_immutables',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    var element = node.declaredElement;
    if (element == null) {
      return;
    }
    var isRedirected =
        element.isFactory && element.redirectedConstructor != null;
    if (node.body is EmptyFunctionBody &&
        !element.isConst &&
        !_hasMixin(element.enclosingElement) &&
        _hasImmutableAnnotation(element.enclosingElement) &&
        (isRedirected && (element.redirectedConstructor?.isConst ?? false) ||
            (!isRedirected &&
                _hasConstConstructorInvocation(node) &&
                context.canBeConstConstructor(node)))) {
      rule.reportLintForToken(node.firstTokenAfterCommentAndMetadata);
    }
  }

  bool _hasConstConstructorInvocation(ConstructorDeclaration node) {
    var declaredElement = node.declaredElement;
    if (declaredElement == null) {
      return false;
    }
    var clazz = declaredElement.enclosingElement;
    // construct with super
    var superInvocation = node.initializers
            .firstWhereOrNull((e) => e is SuperConstructorInvocation)
        as SuperConstructorInvocation?;
    if (superInvocation != null) {
      return superInvocation.staticElement?.isConst ?? false;
    }
    // construct with this
    var redirectInvocation = node.initializers
            .firstWhereOrNull((e) => e is RedirectingConstructorInvocation)
        as RedirectingConstructorInvocation?;
    if (redirectInvocation != null) {
      return redirectInvocation.staticElement?.isConst ?? false;
    }
    // construct with implicit super()
    var supertype = clazz.supertype;
    return supertype != null &&
        supertype.constructors.firstWhere((e) => e.name.isEmpty).isConst;
  }

  bool _hasImmutableAnnotation(InterfaceElement clazz) {
    var selfAndInheritedClasses = _getSelfAndSuperClasses(clazz);
    for (var cls in selfAndInheritedClasses) {
      if (cls.metadata.any((m) => _isImmutable(m.element))) return true;
    }
    return false;
  }

  bool _hasMixin(InterfaceElement clazz) => clazz.mixins.isNotEmpty;

  static List<InterfaceElement> _getSelfAndSuperClasses(InterfaceElement self) {
    InterfaceElement? current = self;
    var seenElements = <InterfaceElement>{};
    while (current != null && seenElements.add(current)) {
      current = current.supertype?.element;
    }
    return seenElements.toList();
  }
}
