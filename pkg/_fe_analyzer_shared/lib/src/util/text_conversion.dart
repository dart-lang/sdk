// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/characters.dart'
    show $MINUS, $_, $a, $z, $A;

/// Converts the kebab case [text] to (upper) camel case.
///
/// If [upperCaseFirst] is `true` the result is  upper camel case, otherwise the
/// result is (lower) camel case.
///
/// Kebab case is of the form `foo-bar-baz`. (Lower) camel case is of the form
/// `fooBarBaz`, and upper camel case is of the form `FooBarBaz`.
String kebabCaseToCamelCase(String text, {bool upperCaseFirst = false}) {
  StringBuffer identifier = new StringBuffer();
  bool first = true;
  for (int index = 0; index < text.length; ++index) {
    int code = text.codeUnitAt(index);
    if (code == $MINUS) {
      ++index;
      code = text.codeUnitAt(index);
      if ($a <= code && code <= $z) {
        code = code - $a + $A;
      }
    }
    if (first && upperCaseFirst && $a <= code && code <= $z) {
      code = code - $a + $A;
    }
    first = false;
    identifier.writeCharCode(code);
  }
  return identifier.toString();
}

/// Converts the kebab case [text] to snake case.
///
/// Kebab case is of form `foo-bar-baz`. Snake case is of form `foo_bar_baz`.
String kebabCaseToSnakeCase(String text) {
  StringBuffer identifier = new StringBuffer();
  for (int index = 0; index < text.length; ++index) {
    int code = text.codeUnitAt(index);
    if (code == $MINUS) {
      code = $_;
    }
    identifier.writeCharCode(code);
  }
  return identifier.toString();
}
