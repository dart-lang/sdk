// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/matcher.dart';

@CustomTag('x-foo')
class XFoo extends PolymerElement {
  @observable var foo = 'foo!';
  final _ready = new Completer();
  Future onTestDone;

  XFoo.created() : super.created() {
    onTestDone = _ready.future.then(_runTest);
  }

  _runTest(_) {
    expect(foo, $['foo'].attributes['foo']);
    expect($['bool'].attributes['foo'], '');
    expect($['bool'].attributes, isNot(contains('foo?')));
    expect($['content'].innerHtml, foo);

    expect(foo, $['bar'].attributes['foo']);
    expect($['barBool'].attributes['foo'], '');
    expect($['barBool'].attributes, isNot(contains('foo?')));
    expect($['barContent'].innerHtml, foo);
  }

  ready() => _ready.complete();
}

main() {
  initPolymer();
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('ready called', () => query('x-foo').onTestDone);
}
