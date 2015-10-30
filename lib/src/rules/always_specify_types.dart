// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.annotate_types;

import 'package:analyzer/src/generated/ast.dart'
    show
        AstVisitor,
        SimpleAstVisitor,
        SimpleFormalParameter,
        VariableDeclarationList;
import 'package:analyzer/src/generated/scanner.dart' show Token;
import 'package:linter/src/ast.dart';
import 'package:linter/src/linter.dart';

const desc = 'Specify type annotations.';

const details = '''
From the [flutter style guide]
(https://github.com/flutter/engine/blob/master/sky/specs/style-guide.md):

**DO** specify type annotations.

Avoid `var` when specifying that a type is unknown and short-hands that elide
type annotations.  Use `dynamic` if you are being explicit that the type is
unknown. Use `Object` if you are being explicit that you want an object that
implements `==` and `hashCode`.

**GOOD:**
```
int foo = 10;
final Bar bar = new Bar();
String baz = 'hello';
const int quux = 20;
```

**BAD:**
```
var foo = 10;
final bar = new Bar();
const quux = 20;
```
''';

class AlwaysSpecifyTypes extends LintRule {
  AlwaysSpecifyTypes()
      : super(
            name: 'always_specify_types',
            description: desc,
            details: details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  LintRule rule;
  Visitor(this.rule);

  bool hasNoAnnotation(SimpleFormalParameter param) =>
      param.keyword == null && param.type == null;

  bool isUntypedList(VariableDeclarationList list) {
    if (isVar(list.keyword)) {
      return true;
    }
    return list.type == null && isFinalOrConst(list.keyword);
  }

  bool isUntypedParam(SimpleFormalParameter param) {
    Token keyword = param.keyword;
    if (hasNoAnnotation(param) || isVar(keyword)) {
      return true;
    }
    return param.type == null && isFinalOrConst(keyword);
  }

  @override
  visitSimpleFormalParameter(SimpleFormalParameter param) {
    if (isUntypedParam(param)) {
      rule.reportLint(param);
    }
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList list) {
    if (isUntypedList(list)) {
      rule.reportLint(list);
    }
  }
}
