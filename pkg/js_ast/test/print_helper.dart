// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:js_ast/js_ast.dart';

/// Supports three calling patterns:
///
///     testExpression(template)
///     testExpression(template, expected)
///     testExpression(template, arguments, expected)
///
/// `template` is a String, possibly containing `#` placeholders.
/// `arguments` can be a String, but only when `expected` is provided.
Node testExpression(String expression, [optional1, String? optional2]) {
  return _test(js.call, expression, optional1, optional2);
}

/// Supports three calling patterns:
///
///     testStatement(template)
///     testStatement(template, expected)
///     testStatement(template, arguments, expected)
///
/// `template` is a String, possibly containing `#` placeholders.
/// `arguments` can be a String, but only when `expected` is provided.
Node testStatement(String expression, [optional1, String? optional2]) {
  return _test(js.statement, expression, optional1, optional2);
}

Node _test(Node Function(String, Object?) parse, String expression, optional1,
    String? optional2) {
  final String expected;
  final Object? arguments; // null, List, or Map.

  if (optional2 is String) {
    expected = optional2;
    arguments = optional1 ?? const [];
  } else if (optional1 is String) {
    expected = optional1;
    arguments = const [];
  } else {
    expected = expression;
    arguments = optional1;
  }

  Node node = parse(expression, arguments);
  String jsText = prettyPrint(node);
  Expect.stringEquals(expected.trim(), jsText.trim());
  return node;
}

String prettyPrint(Node node) {
  JavaScriptPrintingOptions options = JavaScriptPrintingOptions(
      shouldCompressOutput: false,
      minifyLocalVariables: false,
      preferSemicolonToNewlineInMinifiedOutput: false);
  SimpleJavaScriptPrintingContext context = SimpleJavaScriptPrintingContext();
  Printer printer = Printer(options, context);
  printer.visit(node);
  return context.getText();
}
