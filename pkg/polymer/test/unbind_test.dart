// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library polymer.test.unbind_test;

import 'dart:async' show Future, scheduleMicrotask;
import 'dart:html';

@MirrorsUsed(targets: const [Polymer], override: 'polymer.test.unbind_test')
import 'dart:mirrors' show reflect, reflectClass, MirrorSystem, MirrorsUsed;

import 'package:polymer/polymer.dart';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';

@CustomTag('x-test')
class XTest extends PolymerElement {
  @observable var foo = '';
  @observable var bar;

  bool forceReady = true;
  bool fooWasChanged = false;
  var validBar;

  factory XTest() => new Element.tag('x-test');
  XTest.created() : super.created();

  ready() {}

  fooChanged() {
    fooWasChanged = true;
  }

  barChanged() {
    validBar = bar;
  }

  bool get isBarValid => validBar == bar;
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  test('unbind', unbindTests);
});

Future testAsync(List<Function> tests, int delayMs, [List args]) {
  if (tests.length == 0) return new Future.value();
  // TODO(jmesserly): CustomElements.takeRecords();
  return new Future.delayed(new Duration(milliseconds: delayMs), () {
    if (args == null) args = [];
    var lastArgs = Function.apply(tests.removeAt(0), args);
    return testAsync(tests, delayMs, lastArgs);
  });
}

// TODO(sorvell): In IE, the unbind time is indeterminate, so wait an
// extra beat.
delay(x) => new Future.delayed(new Duration(milliseconds: 50), () => x);

// TODO(jmesserly): fix this when it's easier to get a private symbol.
final unboundSymbol = reflectClass(Polymer).declarations.keys
    .firstWhere((s) => MirrorSystem.getName(s) == '_unbound');

_unbound(node) => reflect(node).getField(unboundSymbol).reflectee;

unbindTests() {
  var xTest = document.querySelector('x-test');
  xTest.foo = 'bar';
  scheduleMicrotask(Observable.dirtyCheck);

  return delay(null).then((_) {
    expect(_unbound(xTest), null, reason:
        'element is bound when inserted');
    expect(xTest.fooWasChanged, true, reason:
        'element is actually bound');
    xTest.remove();
  }).then(delay).then((_) {
    expect(_unbound(xTest), true, reason:
        'element is unbound when removed');
    return new XTest();
  }).then(delay).then((node) {
    expect(_unbound(node), null, reason:
        'element is bound when not inserted');
    node.foo = 'bar';
    scheduleMicrotask(Observable.dirtyCheck);
    return node;
  }).then(delay).then((node) {
    expect(node.fooWasChanged, true, reason: 'node is actually bound');
    var n = new XTest();
    n.cancelUnbindAll();
    return n;
  }).then(delay).then((node) {
    expect(_unbound(node), null, reason:
        'element is bound when cancelUnbindAll is called');
    node.unbindAll();
    expect(_unbound(node), true, reason:
        'element is unbound when unbindAll is called');
    var n = new XTest()..id = 'foobar!!!';
    document.body.append(n);
    return n;
  }).then(delay).then((node) {
    expect(_unbound(node), null, reason:
        'element is bound when manually inserted');
    node.remove();
    return node;
  }).then(delay).then((node) {
    expect(_unbound(node), true, reason:
        'element is unbound when manually removed is called');
  });
}
