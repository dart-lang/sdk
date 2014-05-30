// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.nested_binding_test;

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

@CustomTag('my-test')
class MyTest extends PolymerElement {
  final List fruits = toObservable(['apples', 'oranges', 'pears']);

  final _testDone = new Completer();

  MyTest.created() : super.created();

  ready() {
    expect($['fruit'].text.trim(), 'Short name: [pears]');
    _testDone.complete();
  }
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('ready called',
      () => (querySelector('my-test') as MyTest)._testDone.future);
});
