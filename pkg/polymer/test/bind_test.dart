// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

@CustomTag('x-bar')
class XBar extends PolymerElement {
  XBar.created() : super.created();

  get testValue => true;
}

@CustomTag('x-foo')
class XFoo extends PolymerElement {
  @observable var foo = 'foo!';
  final _testDone = new Completer();
  Future get onTestDone => _testDone.future;

  XFoo.created() : super.created();

  _runTest(_) {
    expect($['bindId'].text.trim(), 'bar!');

    expect(foo, $['foo'].attributes['foo']);
    expect($['bool'].attributes['foo'], '');
    expect($['bool'].attributes, isNot(contains('foo?')));
    expect($['content'].innerHtml, foo);

    expect(foo, $['bar'].attributes['foo']);
    expect($['barBool'].attributes['foo'], '');
    expect($['barBool'].attributes, isNot(contains('foo?')));
    expect($['barContent'].innerHtml, foo);
    _testDone.complete();
  }

  ready() {
    onMutation($['bindId']).then(_runTest);
  }
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('ready called', () => (querySelector('x-foo') as XFoo).onTestDone);
});
