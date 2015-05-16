// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library util_tests;

import 'dart:html';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';
import '../../../swarm_ui_lib/util/utilslib.dart';

main() {
  useHtmlConfiguration();
  test('insertAt', () {
    var a = [];
    CollectionUtils.insertAt(a, 0, 1);
    expect(a, orderedEquals([1]));

    CollectionUtils.insertAt(a, 0, 2);
    expect(a, orderedEquals([2, 1]));

    CollectionUtils.insertAt(a, 0, 5);
    CollectionUtils.insertAt(a, 0, 4);
    CollectionUtils.insertAt(a, 0, 3);
    expect(a, orderedEquals([3, 4, 5, 2, 1]));

    a = [];
    CollectionUtils.insertAt(a, 0, 1);
    expect(a, orderedEquals([1]));

    CollectionUtils.insertAt(a, 1, 2);
    expect(a, orderedEquals([1, 2]));

    CollectionUtils.insertAt(a, 1, 3);
    CollectionUtils.insertAt(a, 3, 4);
    CollectionUtils.insertAt(a, 3, 5);
    expect(a, orderedEquals([1, 3, 2, 5, 4]));
  });

  test('defaultString', () {
    expect(StringUtils.defaultString(null), isEmpty);
    expect(StringUtils.defaultString(''), isEmpty);
    expect(StringUtils.defaultString('test'), equals('test'));
  });
}
