// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library FormDataTest;

import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

void main() {
  // TODO(efortuna): This is a bad test. Revisit when we have tests that can run
  // both a server and fire up a browser.
  useHtmlConfiguration();

  var isFormData = predicate((x) => x is FormData, 'is a FormData');

  test('constructorTest1', () {
    var form = new FormData();
    expect(form, isNotNull);
    expect(form, isFormData);
  });

  test('constructorTest2', () {
    var form = new FormData(new FormElement());
    expect(form, isNotNull);
    expect(form, isFormData);
  });

  test('appendTest', () {
    var form = new FormData();
    form.append('test', '1', 'foo');
    form.append('username', 'Elmo', 'foo');
    form.append('address', '1 Sesame Street', 'foo');
    form.append('password', '123456', 'foo');
    expect(form, isNotNull);
  });
}
