// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:polymer/polymer.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

@CustomTag('x-test')
class XTest extends PolymerElement {
  @observable List list;

  final _attached = new Completer();
  Future onTestDone;

  XTest.created() : super.created() {
    onTestDone = _attached.future.then(_runTest);
  }

  attached() {
    super.attached();
    _attached.complete();
  }

  _runTest(_) {
    list = [
      {'name': 'foo'},
      {'name': 'bar'}
    ];
    return new Future(() {
      // tickle SD polyfill
      offsetHeight;
      var children = this.$['echo'].children;
      expect(children[0].localName, 'template', reason:
          'shadowDOM dynamic distribution via template');
      expect(children[1].text, 'foo', reason:
          'shadowDOM dynamic distribution via template');
      expect(children[2].text, 'bar', reason:
          'shadowDOM dynamic distribution via template');
      expect(children.length, 3, reason: 'expected number of children');
    });
  }
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('inserted called', () => (querySelector('x-test') as XTest).onTestDone);
});
