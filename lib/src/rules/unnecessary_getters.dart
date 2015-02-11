// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unnecessary_getters;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:dart_lint/src/linter.dart';

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


bool isPublicMethod(ClassMember m) =>
    m is MethodDeclaration && m.element.isPublic;

class UnnecessaryGetters extends LintRule {
  UnnecessaryGetters()
      : super(
          name: 'UnnecessaryGetters',
          description: desc,
          details: details,
          group: Group.STYLE_GUIDE,
          kind: Kind.PREFER);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final Map<String, MethodDeclaration> getters = {};
  final Map<String, MethodDeclaration> setters = {};

  LintRule rule;
  Visitor(this.rule);

  @override
  visitClassDeclaration(ClassDeclaration node) {

    // Filter on public methods
    var methods = node.members.where((m) => isPublicMethod(m));

    //Build getter/setter maps
    for (var method in methods) {
      if (method.isGetter) {
        var name = method.name.toString();
        getters[name] = method;
      } else if (method.isSetter) {
        var name = method.name.toString();
        setters[name] = method;
      }
    }

    // Only select getters without setters
    var candidates = getters.keys.where((id) => !setters.keys.contains(id));
    candidates.map((n) => getters[n]).forEach((g) => _visitGetter(g));
  }

  bool _check(Expression expression) {
    if (expression is SimpleIdentifier) {
      var staticElement = expression.staticElement;
      if (staticElement is PropertyAccessorElement) {
        return staticElement.isSynthetic && staticElement.variable.isPrivate;
      }
    }
    return false;
  }

  _visitGetter(MethodDeclaration getter) {
    if (getter.body is ExpressionFunctionBody) {
      if (_check((getter.body as ExpressionFunctionBody).expression)) {
        rule.reportLint(getter);
      }
    } else if (getter.body is BlockFunctionBody) {
      Block block = (getter.body as BlockFunctionBody).block;
      if (block.statements.length == 1) {
        if (block.statements[0] is ReturnStatement) {
          if (_check((block.statements[0] as ReturnStatement).expression)) {
            rule.reportLint(getter);
          }
        }
      }
    }
  }

}
