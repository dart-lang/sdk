// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:expect/legacy/minitest.dart'; // ignore: deprecated_member_use_from_same_package

main() {
  test('Basic TouchEvent', () {
    if (globalContext.has('TouchEvent')) {
      var e = new TouchEvent('touch');
      expect(e is TouchEvent, isTrue);
    }
  });
}
