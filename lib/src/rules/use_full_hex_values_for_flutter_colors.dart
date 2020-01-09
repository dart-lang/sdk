// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _desc =
    r'Prefer an 8-digit hexadecimal integer(0xFFFFFFFF) to instantiate Color.';

const _details = r'''

Prefer an 8-digit hexadecimal integer(0xFFFFFFFF) to instantiate Color. Colors
have four 8-bit channels, which adds up to 32 bits, so Colors are described
using a 32 bit integer.

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

class UseFullHexValuesForFlutterColors extends LintRule
    implements NodeLintRule {
  UseFullHexValuesForFlutterColors()
      : super(
            name: 'use_full_hex_values_for_flutter_colors',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (DartTypeUtilities.isConstructorElement(node.staticElement,
        uriStr: 'dart.ui', className: 'Color', constructorName: '')) {
      final arguments = node.argumentList.arguments;
      if (arguments.isNotEmpty) {
        final argument = arguments.first;
        if (argument is IntegerLiteral) {
          final value = argument.literal.lexeme;
          if (!value.startsWith('0x') || value.length != 10) {
            rule.reportLint(argument);
          }
        }
      }
    }
  }
}
