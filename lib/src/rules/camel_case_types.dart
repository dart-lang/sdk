// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library camel_case_types;

import 'package:analyzer/src/generated/ast.dart';
import 'package:dart_lint/src/linter.dart';

const desc = 'DO name types using UpperCamelCase.';

const details = '''
From the [style guide] (https://www.dartlang.org/articles/style-guide/):

**DO** name types using UpperCamelCase.

Classes and typedefs should capitalize the first letter of each word 
(including the first word), and use no separators.

**GOOD:**

```
class SliderMenu {
  // ...
}

class HttpRequest {
  // ...
}

typedef num Adder(num x, num y);
```
''';

class CamelCaseTypes extends LintRule {
  CamelCaseTypes() : super(
          name: 'CamelCaseTypes',
          description: desc,
          details: details,
          group: Group.STYLE_GUIDE,
          kind: Kind.DO);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {

  LintRule rule;
  Visitor(this.rule);

  @override
  visitClassDeclaration(ClassDeclaration node) {
    if (!isUpperCamelCase(node.name.toString())) {
      rule.reportLint(node);
    }
  }

  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (!isUpperCamelCase(node.name.toString())) {
      rule.reportLint(node);
    }
  }
}

final separator = new RegExp(r'[$_]');
final upperCase = new RegExp('[A-Z]');

bool isUpperCamelCase(String s) => s.startsWith(upperCase) &&
    !separator.hasMatch(s) &&
    CamelCaseString.isCamelCase(s);
