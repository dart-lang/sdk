// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:js';

import 'package:expect/minitest.dart';

import 'js_test_util.dart';

main() {
  injectJs();

  test('is check', () {
    var fn = (String s) => true;
    var jsFn = allowInterop(fn);
    expect(fn is StringToBool, isTrue);
    expect(jsFn is StringToBool, isTrue);
    expect(jsFn is Function, isTrue);
    expect(jsFn is List, isFalse);
  });
}
