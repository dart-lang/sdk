// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:indexed_db' show IdbFactory, KeyRange;
import 'dart:typed_data' show Int32List;
import 'dart:js';

import 'package:js/js_util.dart' as js_util;
import 'package:expect/minitest.dart';

import 'js_test_util.dart';

main() {
  injectJs();

  test('JS->Dart', () {
    // Test that we are not pulling cached proxy from the prototype
    // when asking for a proxy for the object.
    final proto = context['someProto'];
    expect(proto['role'], equals('proto'));
    final obj = context['someObject'];
    expect(obj['role'], equals('object'));
  });
}
