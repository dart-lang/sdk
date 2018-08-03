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

  test('Nodes are proxied', () {
    var node = new JsObject.fromBrowserObject(new DivElement());
    context.callMethod('addTestProperty', [node]);
    expect(node is JsObject, isTrue);
    // TODO(justinfagnani): make this work in IE9
    // expect(node.instanceof(context['HTMLDivElement']), isTrue);
    expect(node['testProperty'], 'test');
  });

  test('primitives and null throw ArgumentError', () {
    for (var v in ['a', 1, 2.0, true, null]) {
      expect(() => new JsObject.fromBrowserObject(v), throwsArgumentError);
    }
  });
}
