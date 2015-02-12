// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unnecessary_getters;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:linter/src/ast.dart';
import 'package:linter/src/linter.dart';

const desc = '''
PREFER using a public final field instead of a private field with 
a public getter.
''';

const details = '''
From the [style guide] (https://www.dartlang.org/articles/style-guide/):

**PREFER** using a public final field instead of a private field with a public 
getter.

If you have a field that outside code should be able to see but not assign to 
(and you don't need to set it outside of the constructor), a simple solution 
that works in many cases is to just mark it `final`.

**GOOD:**

```
class Box {
  final contents = [];
}
```

**BAD:**

```
class Box {
  var _contents;
  get contents => _contents;
}
```
''';

class UnnecessaryGetters extends LintRule {
  UnnecessaryGetters() : super(
          name: 'UnnecessaryGetters',
          description: desc,
          details: details,
          group: Group.STYLE_GUIDE,
          kind: Kind.PREFER);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  LintRule rule;
  Visitor(this.rule);

  @override
  visitClassDeclaration(ClassDeclaration node) {
    Map<String, MethodDeclaration> getters = {};
    Map<String, MethodDeclaration> setters = {};

    // Filter on public methods
    var methods = node.members.where(isPublicMethod);

    // Build getter/setter maps
    for (var method in methods) {
      if (method.isGetter) {
        getters[method.name.toString()] = method;
      } else if (method.isSetter) {
        setters[method.name.toString()] = method;
      }
    }

    // Only select getters without setters
    var candidates = getters.keys.where((id) => !setters.keys.contains(id));
    candidates.map((n) => getters[n]).forEach(_visitGetter);
  }

  bool _check(MethodDeclaration getter, Expression expression) {
    if (expression is SimpleIdentifier) {
      var staticElement = expression.staticElement;
      if (staticElement is PropertyAccessorElement) {
        Element getterElement = getter.element;
        // Skipping library level getters, test that the enclosing element is
        // the same
        if (staticElement.enclosingElement != null &&
            (staticElement.enclosingElement ==
                getterElement.enclosingElement)) {
          return staticElement.isSynthetic && staticElement.variable.isPrivate;
        }
      }
    }
    return false;
  }

  _visitGetter(MethodDeclaration getter) {
    if (getter.body is ExpressionFunctionBody) {
      ExpressionFunctionBody body = getter.body;
      if (_check(getter, body.expression)) {
        rule.reportLint(getter);
      }
    } else if (getter.body is BlockFunctionBody) {
      BlockFunctionBody body = getter.body;
      Block block = body.block;
      if (block.statements.length == 1) {
        if (block.statements[0] is ReturnStatement) {
          ReturnStatement returnStatement = block.statements[0];
          if (_check(getter, returnStatement.expression)) {
            rule.reportLint(getter);
          }
        }
      }
    }
  }
}
