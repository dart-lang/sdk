// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/ast.dart';

const _desc =
    r'Prefer using a public final field instead of a private field with a public'
    r'getter.';

const _details = r'''

From the [style guide](https://www.dartlang.org/articles/style-guide/):

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
  UnnecessaryGetters()
      : super(
            name: 'unnecessary_getters',
            description: _desc,
            details: _details,
            group: Group.style);

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
    for (MethodDeclaration method in methods) {
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

  _visitGetter(MethodDeclaration getter) {
    if (isSimpleGetter(getter)) {
      rule.reportLint(getter.name);
    }
  }
}
