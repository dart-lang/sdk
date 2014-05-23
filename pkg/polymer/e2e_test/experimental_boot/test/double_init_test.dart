// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library experimental_boot.test.double_init_test;

import 'dart:async';
import 'dart:js' as js;

import 'package:polymer/polymer.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

@initMethod
init() {
  useHtmlConfiguration();
  test('can\'t call initPolymer when using polymer_experimental', () {
    expect(() => initPolymer(), throwsA("Initialization was already done."));
  });
}
