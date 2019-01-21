// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Prefer a 8-hex integer(0xFFFFFFFF) to instantiate Color.';

const _details = r'''

Prefer a 8-hex integer(0xFFFFFFFF) to instantiate Color. Colors have four 8-bit
channels, which adds up to 32 bits, so Colors are described using a 32 bit
integer.

**BAD:**
```
Color(1);
Color(0x000001);
```

**GOOD:**
```
Color(0x00000001);
```

''';

class FlutterColorInstantiation extends LintRule implements NodeLintRule {
  FlutterColorInstantiation()
      : super(
            name: 'flutter_color_instantiation',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = new _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.staticElement?.library?.name == 'dart.ui' &&
        node.staticElement?.returnType?.name == 'Color' &&
        node.staticElement?.name == '') {
      final argument = node.argumentList.arguments.first;
      if (argument is IntegerLiteral) {
        final value = argument.literal.lexeme;
        if (!value.startsWith('0x') || value.length != 10) {
          rule.reportLint(argument);
        }
      }
    }
  }
}
