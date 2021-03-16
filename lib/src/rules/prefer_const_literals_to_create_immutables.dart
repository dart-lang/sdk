// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const desc =
    'Prefer const literals as parameters of constructors on @immutable classes.';

const details = '''

**PREFER** using `const` for instantiating list, map and set literals used as
parameters in immutable class instantiations.

**BAD:**
```dart
@immutable
class A {
  A(this.v);
  final v;
}

A a1 = new A([1]);
A a2 = new A({});
```

**GOOD:**
```dart
A a1 = new A(const [1]);
A a2 = new A(const {});
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

class PreferConstLiteralsToCreateImmutables extends LintRule
    implements NodeLintRule {
  PreferConstLiteralsToCreateImmutables()
      : super(
            name: 'prefer_const_literals_to_create_immutables',
            description: desc,
            details: details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this, context);
    registry.addListLiteral(this, visitor);
    registry.addSetOrMapLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitListLiteral(ListLiteral node) => _visitTypedLiteral(node);

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    _visitTypedLiteral(node);
  }

  Iterable<InterfaceType> _getSelfAndInheritedTypes(InterfaceType type) sync* {
    InterfaceType? current = type;
    // TODO(a14n) the is check looks unnecessary but prevents https://github.com/dart-lang/sdk/issues/33210
    // for now it's not clear how this can happen
    while (current != null && current is InterfaceType) {
      yield current;
      current = current.superclass;
    }
  }

  bool _hasImmutableAnnotation(DartType? type) {
    if (type is! InterfaceType) {
      // This happens when we find an instance creation expression for a class
      // that cannot be resolved.
      return false;
    }
    final inheritedAndSelfTypes = _getSelfAndInheritedTypes(type);
    final inheritedAndSelfAnnotations = inheritedAndSelfTypes
        .map((type) => type.element)
        .expand((c) => c.metadata)
        .map((m) => m.element);
    return inheritedAndSelfAnnotations.any(_isImmutable);
  }

  void _visitTypedLiteral(TypedLiteral literal) {
    if (literal.isConst) return;

    // looking for parent instance creation to check if class is immutable
    AstNode? node = literal;
    while (node is! InstanceCreationExpression &&
        (node is ParenthesizedExpression ||
            node is ArgumentList ||
            node is ListLiteral ||
            node is SetOrMapLiteral ||
            node is MapLiteralEntry ||
            node is NamedExpression)) {
      node = node?.parent;
    }
    if (!(node is InstanceCreationExpression &&
        _hasImmutableAnnotation(node.staticType))) {
      return;
    }

    if (context.canBeConst(literal)) {
      rule.reportLint(literal);
    }
  }
}
