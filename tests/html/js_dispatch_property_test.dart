// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for dart2js initialization of dispatchPropertyName.

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

import 'package:expect/expect.dart' show NoInline, AssumeDynamic;

import 'js_dispatch_property_test_lib.dart';

@NoInline()
@AssumeDynamic()
confuse(x) => x;

main() {
  useHtmlConfiguration();

  group('group', () {
    test('test', () {
      // Force dynamic interceptor dispatch.
      var a = confuse(create());
      expect(a.foo('A'), equals('Foo A'));
    });
  });
}
