// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library element_animate_test;

import 'dart:async';
import 'dart:html';

import 'package:async_helper/async_minitest.dart';

main() {
  test('supported', () {
    expect(Animation.supported, isTrue);
  });
}
