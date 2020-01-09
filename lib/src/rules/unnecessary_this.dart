// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r"Don't access members with `this` unless avoiding shadowing.";

const _details = r'''

From the [style guide](https://dart.dev/guides/language/effective-dart/style/):

**DON'T** use `this` when not needed to avoid shadowing.

**BAD:**
```
class Box {
  var value;
  void update(new_value) {
    this.value = new_value;
  }
}
```

**GOOD:**
```
class Box {
  var value;
  void update(new_value) {
    value = new_value;
  }
}
```

**GOOD:**
```
class Box {
  var value;
  void update(value) {
    this.value = value;
  }
}
```

''';

class UnnecessaryThis extends LintRule implements NodeLintRule {
  UnnecessaryThis()
      : super(
            name: 'unnecessary_this',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addConstructorFieldInitializer(this, visitor);
    registry.addThisExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    if (node.thisKeyword != null) {
      rule.reportLintForToken(node.thisKeyword);
    }
  }

  @override
  void visitThisExpression(ThisExpression node) {
    final parent = node.parent;

    Element element;
    if (parent is PropertyAccess) {
      element = parent.propertyName.staticElement;
    } else if (parent is MethodInvocation) {
      element = parent.methodName.staticElement;
    } else {
      return;
    }

    if (_canReferenceElementWithoutThisPrefix(element, node)) {
      rule.reportLint(parent);
    }
  }

  bool _canReferenceElementWithoutThisPrefix(Element element, AstNode node) {
    if (element == null) {
      return false;
    }

    var id = element.displayName;
    var isSetter = element is PropertyAccessorElement && element.isSetter;
    var result = context.resolveNameInScope(id, isSetter, node);

    // No result, definitely no shadowing.
    // The requested element is inherited, or from an extension.
    if (result.isNone) {
      return true;
    }

    // The result has the matching name, might be shadowing.
    // Check that the element is the same.
    if (result.isRequestedName) {
      return result.element == element;
    }

    // The result has the same basename, but not the same name.
    // Must be an instance member, so that:
    //  - not shadowed by a local declaration;
    //  - prevents us from going up to the library scope;
    //  - the requested element must be inherited, or from an extension.
    if (result.isDifferentName) {
      var enclosing = result.element.enclosingElement;
      return enclosing is ClassElement;
    }

    // Should not happen.
    return false;
  }
}
