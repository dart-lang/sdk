// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.property_change_test;

import 'dart:async';
import 'package:polymer/polymer.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

// Dart note: this is a tad different from the JS code. We don't support putting
// expandos on Dart objects and then observing them. On the other hand, we want
// to make sure that superclass observers are correctly detected.

final _zonk = new Completer();
final _bar = new Completer();

@reflectable
class XBase extends PolymerElement {
  @observable String zonk = '';

  XBase.created() : super.created();

  zonkChanged() {
    expect(zonk, 'zonk', reason: 'change calls *Changed on superclass');
    _zonk.complete();
  }
}

@CustomTag('x-test')
class XTest extends XBase {
  @observable String bar = '';

  XTest.created() : super.created();

  ready() {
    bar = 'bar';
    new Future(() { zonk = 'zonk'; });
  }

  barChanged() {
    expect(bar, 'bar', reason: 'change in ready calls *Changed');
    _bar.complete();
  }
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('bar change detected', () => _bar.future);
  test('zonk change detected', () => _zonk.future);
});
