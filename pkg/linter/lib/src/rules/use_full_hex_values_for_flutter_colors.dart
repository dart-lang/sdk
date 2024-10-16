// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc =
    r'Prefer an 8-digit hexadecimal integer (for example, 0xFFFFFFFF) to '
    'instantiate a Color.';

class UseFullHexValuesForFlutterColors extends LintRule {
  UseFullHexValuesForFlutterColors()
      : super(
          name: LintNames.use_full_hex_values_for_flutter_colors,
          description: _desc,
        );

  @override
  LintCode get lintCode =>
      LinterLintCode.use_full_hex_values_for_flutter_colors;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static final _underscoresPattern = RegExp('_+');

  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var element = node.constructorName.element;
    if (element != null &&
        element.isSameAs(
            uri: 'dart.ui', className: 'Color', constructorName: '')) {
      var arguments = node.argumentList.arguments;
      if (arguments.isNotEmpty) {
        var argument = arguments.first;
        if (argument is IntegerLiteral) {
          var value = argument.literal.lexeme.toLowerCase();
          value = value.replaceAll(_underscoresPattern, '');
          if (!value.startsWith('0x') || value.length != 10) {
            rule.reportLint(argument);
          }
        }
      }
    }
  }
}
