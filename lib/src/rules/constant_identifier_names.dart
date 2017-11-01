// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/utils.dart';

const _desc = r'Prefer using lowerCamelCase for constant names.';

const _details = r'''

**PREFER** using lowerCamelCase for constant names.

In new code, use `lowerCamelCase` for constant variables, including enum values.

In existing code that uses `ALL_CAPS_WITH_UNDERSCORES` for constants, you may
continue to use all caps to stay consistent.

**GOOD:**
```
const pi = 3.14;
const defaultTimeout = 1000;
final urlScheme = new RegExp('^([a-z]+):');

class Dice {
  static final numberGenerator = new Random();
}
```

**BAD:**
```
const PI = 3.14;
const kDefaultTimeout = 1000;
final URL_SCHEME = new RegExp('^([a-z]+):');

class Dice {
  static final NUMBER_GENERATOR = new Random();
}

```

''';

class ConstantIdentifierNames extends LintRule {
  ConstantIdentifierNames()
      : super(
            name: 'constant_identifier_names',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  LintRule rule;
  Visitor(this.rule);

  checkIdentifier(SimpleIdentifier id) {
    if (!isLowerCamelCase(id.name)) {
      rule.reportLint(id);
    }
  }

  @override
  visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    checkIdentifier(node.name);
  }

  @override
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    visitVariableDeclarationList(node.variables);
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {
    node.variables.forEach((VariableDeclaration v) {
      if (v.isConst) {
        checkIdentifier(v.name);
      }
    });
  }
}
