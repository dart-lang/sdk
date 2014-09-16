// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

int testsRun = 0;

@CustomTag('decoration-test')
class DecorationTest extends PolymerElement {
  List<int> options = [1, 2, 3, 4];

  DecorationTest.created() : super.created();

  ready() {
    this.test();
    testsRun++;
  }

  test() {
    expect($['select'].children.length, 5,
        reason: 'attribute template stamped');
  }
}

@CustomTag('decoration-test2')
class DecorationTest2 extends DecorationTest {
  List<List<int>> arrs = [ [1,2,3], [4,5,6] ];

  DecorationTest2.created() : super.created();

  test() {
    expect($['tbody'].children.length, 3,
        reason: 'attribute template stamped');
    expect($['tbody'].children[1].children.length, 4,
        reason: 'attribute sub-template stamped');
  }
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('declaration-tests-ran', () {
    // TODO(jakemac): Change this to '2' once http://dartbug.com/20197 is fixed.
    expect(testsRun, 3, reason: 'decoration-tests-ran');
  });
});
