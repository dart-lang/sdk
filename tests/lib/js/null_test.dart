// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library null_test;

import 'dart:js';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

main() {
  useHtmlConfiguration();
  test('null is sent as null', () {
    expect(context['isNull'].apply([null]), isTrue);
    expect(context['isUndefined'].apply([null]), isFalse);
  });
}
