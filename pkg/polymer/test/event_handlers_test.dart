// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.event_handlers_test;

import 'dart:async';
import 'dart:html';

import 'package:polymer/polymer.dart';
import 'package:template_binding/template_binding.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

@CustomTag('x-test')
class XTest extends PolymerElement {
  int _testCount = 0;
  String _lastEvent;
  String _lastMessage;
  List list1 = toObservable([]);
  List list2 = toObservable([]);
  Future _onTestDone;

  XTest.created() : super.created();

  @override
  parseDeclaration(elementElement) {
    var template = fetchTemplate(elementElement);
    if (template != null) {
      lightFromTemplate(template);
    }
  }

  ready() {
    super.ready();
    for (var i = 0; i < 10; i++) {
      var model = new MiniModel(this, i);
      list1.add(model);
      list2.add(model);
    }

    _onTestDone = new Future.sync(_runTests);
  }

  hostTapAction(event, detail, node) => _logEvent(event);

  divTapAction(event, detail, node) => _logEvent(event);

  focusAction(event, detail, node) => _logEvent(event);

  blurAction(event, detail, node) => _logEvent(event);

  scrollAction(event, detail, node) => _logEvent(event);

  itemTapAction(event, detail, node) {
    var model = nodeBind(event.target).templateInstance.model;
    _logEvent(event, "x-test callback ${model['this']}");
  }

  _logEvent(event, [message]) {
    _testCount++;
    _lastEvent = event.type;
    _lastMessage = message;
  }

  Future _runTests() {
    fire('tap', onNode: $['div']);
    expect(_testCount, 2, reason: 'event heard at div and host');
    expect(_lastEvent, 'tap', reason: 'tap handled');
    fire('focus', onNode: $['input'], canBubble: false);
    expect(_testCount, 3, reason: 'event heard by input');
    expect(_lastEvent, 'focus', reason: 'focus handled');
    fire('blur', onNode: $['input'], canBubble: false);
    expect(_testCount, 4, reason: 'event heard by input');
    expect(_lastEvent, 'blur', reason: 'blur handled');
    fire('scroll', onNode: $['list'], canBubble: false);
    expect(_testCount, 5, reason: 'event heard by list');
    expect(_lastEvent, 'scroll', reason: 'scroll handled');

    return onMutation($['list']).then((_) {
      var l1 = $['list'].querySelectorAll('.list1')[4];
      fire('tap', onNode: l1, canBubble: false);
      expect(_testCount, 6, reason: 'event heard by list1 item');
      expect(_lastEvent, 'tap', reason: 'tap handled');
      expect(_lastMessage, 'x-test callback <mini-model 4>');

      var l2 = $['list'].querySelectorAll('.list2')[3];
      fire('tap', onNode: l2, canBubble: false);
      expect(_testCount, 7, reason: 'event heard by list2 item');
      expect(_lastEvent, 'tap', reason: 'tap handled by model');
      expect(_lastMessage, 'x-test callback x-test');
    });
  }
}

class MiniModel extends Observable {
  XTest _element;
  @observable final int index;
  @reflectable void itemTapAction(e, d, n) {
    _element._logEvent(e, 'mini-model callback $this');
    e.stopPropagation();
  }
  MiniModel(this._element, this.index);
  String toString() => "<mini-model $index>";
}

main() => initPolymer();

@initMethod init() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);
  test('events handled', () {
    XTest test = querySelector('x-test');
    expect(test._onTestDone, isNotNull, reason: 'ready was called');
    return test._onTestDone;
  });
}
