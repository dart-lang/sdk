// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dromaeo;
import 'dart:async';
import 'dart:html';
import 'dart:json' as json;
import '../../../samples/third_party/dromaeo/common/common.dart';
import 'dart:math' as Math;
import '../../../pkg/unittest/lib/unittest.dart';
import '../../../pkg/unittest/lib/html_config.dart';
part '../../../samples/third_party/dromaeo/tests/Common.dart';
part '../../../samples/third_party/dromaeo/tests/RunnerSuite.dart';

/**
 * The smoketest equivalent of an individual test run, much like
 * dom-attr-html.dart, dom-modify-html.dart, dom-query-html.dart and others.
 */
void main() {
  new Suite(window, 'dom-nothing')
    .prep(() {})
    .test('no-op', () {})
    .end();
}

