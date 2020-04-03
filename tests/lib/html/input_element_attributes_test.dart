// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:html';

import 'package:expect/minitest.dart';

dynamic _undefined = (() => new List(5)[0])();

main() {
  test('valueSetNull', () {
    final e = new TextInputElement();
    e.value = null;
    expect(e.value, '');
  });
  test('valueSetNullProxy', () {
    final e = new TextInputElement();
    e.value = _undefined;
    expect(e.value, '');
  });
}
