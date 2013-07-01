// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that uninstantiated native classes can be used as type arguments in
// checks.

import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

class C<T> {
  String cssText;
}

class D {
  String cssText;
}

f(x) => x;

var g = f;

useCssText(var o) => o.cssText;

void main() {
  useHtmlConfiguration();

  // Provoke (uninferred) access to [cssText].
  print(useCssText(g(new C())));
  print(useCssText(g(new D())));

  // Use the uninstantiated [CssStyleDeclaration] (which has a [cssText] field).
  expect(new C() is C<CssStyleDeclaration>, isTrue);
  expect(new C<int>() is C<CssStyleDeclaration>, isFalse);
}
