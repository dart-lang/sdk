// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc =
    r'Prefer an 8-digit hexadecimal integer(0xFFFFFFFF) to instantiate Color.';

const _details = r'''
**PREFER** an 8-digit hexadecimal integer(0xFFFFFFFF) to instantiate Color. Colors
have four 8-bit channels, which adds up to 32 bits, so Colors are described
using a 32 bit integer.

**BAD:**
```dart
Color(1);
Color(0x000001);
```

**GOOD:**
```dart
Color(0x00000001);
```

''';

class UseFullHexValuesForFlutterColors extends LintRule {
  static const LintCode code = LintCode(
      'use_full_hex_values_for_flutter_colors',
      "Instances of 'Color' should be created using an 8-digit hexadecimal "
          "integer (such as '0xFFFFFFFF').",
      correctionMessage:
          "Try using an 8-digit hexadecimal integer to create the 'Color'.");

  UseFullHexValuesForFlutterColors()
      : super(
            name: 'use_full_hex_values_for_flutter_colors',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var element = node.constructorName.staticElement;
    if (element != null &&
        element.isSameAs(
            uri: 'dart.ui', className: 'Color', constructorName: '')) {
      var arguments = node.argumentList.arguments;
      if (arguments.isNotEmpty) {
        var argument = arguments.first;
        if (argument is IntegerLiteral) {
          var value = argument.literal.lexeme.toLowerCase();
          if (!value.startsWith('0x') || value.length != 10) {
            rule.reportLint(argument);
          }
        }
      }
    }
  }
}
