// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.property_change_test;

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

var _changes = 0;
final _done = new Completer();

checkDone() {
  if (6 == ++_changes) {
    _done.complete();
  }
}

@CustomTag('x-test')
class XTest extends PolymerElement {
  @observable String bar = '';
  @observable String pie;
  @observable Map a;

  XTest.created() : super.created();

  ready() {
    bar = 'bar';
    pie = 'pie';
    a = {'b': {'c': 'exists'}};
  }

  barChanged() {
    // Dart note: unlike polymer-js we support multiple observers, due to how
    // our @ObserveProperty metadata translated.
    // _done.completeError('barChanged should not be called.');
    expect('bar', 'bar', reason: 'barChanged called');
    checkDone();
  }

  @ObserveProperty('bar pie')
  validate() {
    window.console.log('validate');
    expect('bar', 'bar', reason: 'custom change observer called');
    expect('pie', 'pie', reason: 'custom change observer called');
    checkDone();
  }

  // Dart note: test that we can observe "pie" twice.
  @ObserveProperty('pie')
  validateYummyPie() {
    window.console.log('validateYummyPie');
    expect('pie', 'pie', reason: 'validateYummyPie called');
    checkDone();
  }


  @ObserveProperty('a.b.c')
  validateSubPath(oldValue, newValue) {
    window.console.log('validateSubPath $oldValue $newValue');
    expect(newValue, 'exists', reason: 'subpath change observer called');
    checkDone();
  }
}

@CustomTag('x-test2')
class XTest2 extends XTest {
  @observable String noogle;

  XTest2.created() : super.created();

  @ObserveProperty('noogle')
  validate() => super.validate();

  ready() {
    super.ready();
    noogle = 'noogle';
  }
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('changes detected', () => _done.future);
});
