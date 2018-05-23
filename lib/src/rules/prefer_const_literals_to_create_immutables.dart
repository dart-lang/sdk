// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/ast.dart';

const desc =
    'Prefer const literals as parameters of constructors on @immutable classes.';

const details = '''

**PREFER** using `const` for instantiating list and map literal used as
parameters in immutable class instantiations.

**BAD:**
```
@immutable
class A {
  A(this.v);
  final v;
}

A a1 = new A([1]);
A a2 = new A({});
```

**GOOD:**
```
A a1 = new A(const [1]);
A a2 = new A(const {});
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

class PreferConstLiteralsToCreateImmutables extends LintRule
    implements NodeLintRule {
  PreferConstLiteralsToCreateImmutables()
      : super(
            name: 'prefer_const_literals_to_create_immutables',
            description: desc,
            details: details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry) {
    final visitor = new _Visitor(this);
    registry.addListLiteral(this, visitor);
    registry.addMapLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitListLiteral(ListLiteral node) => _visitTypedLiteral(node);

  @override
  void visitMapLiteral(MapLiteral node) => _visitTypedLiteral(node);

  Iterable<InterfaceType> _getSelfAndInheritedTypes(InterfaceType type) sync* {
    InterfaceType current = type;
    while (current != null && current is InterfaceType) {
      yield current;
      current = current.superclass;
    }
  }

  bool _hasImmutableAnnotation(DartType type) {
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
    AstNode node = literal;
    while (node is! InstanceCreationExpression &&
        (node is ParenthesizedExpression ||
            node is ArgumentList ||
            node is ListLiteral ||
            node is MapLiteral ||
            node is MapLiteralEntry ||
            node is NamedExpression)) {
      node = node.parent;
    }
    if (!(node is InstanceCreationExpression &&
        _hasImmutableAnnotation(node.bestType))) {
      return;
    }

    bool hasConstError;

    // put a fake const keyword and check if there's const error
    final oldKeyword = literal.constKeyword;
    literal.constKeyword = new KeywordToken(Keyword.CONST, node.offset);
    try {
      hasConstError = hasErrorWithConstantVerifier(literal);
    } finally {
      // restore old keyword
      literal.constKeyword = oldKeyword;
    }

    if (!hasConstError) {
      rule.reportLint(literal);
    }
  }
}
