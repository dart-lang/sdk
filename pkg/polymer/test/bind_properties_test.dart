// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

export 'package:polymer/init.dart';

class XBaz extends PolymerElement {
  @published
  int get val => readValue(#val);
  set val(v) => writeValue(#val, v);

  XBaz.created() : super.created();
}

class XBar extends PolymerElement {
  @published
  int get val => readValue(#val);
  set val(v) => writeValue(#val, v);

  XBar.created() : super.created();
}

class XBat extends PolymerElement {
  @published
  int get val => readValue(#val);
  set val(v) => writeValue(#val, v);

  XBat.created() : super.created();
}

class XFoo extends PolymerElement {
  @published
  int get val => readValue(#val);
  set val(v) => writeValue(#val, v);

  XFoo.created() : super.created();
}

@CustomTag('bind-properties-test')
class XTest extends PolymerElement {
  XTest.created() : super.created();

  @published var obj;

  ready() {
    obj = toObservable({'path': {'to': {'value': 3}}});
    readyCalled();
  }
}

var completer = new Completer();
waitForElementReady(_) => completer.future;
readyCalled() { completer.complete(null); }

@initMethod
init() {
  // TODO(sigmund): investigate why are we still seeing failures due to the
  // order of registrations, then use @CustomTag instead of this.
  Polymer.register('x-foo', XFoo);
  Polymer.register('x-bar', XBar);
  Polymer.register('x-baz', XBaz);
  Polymer.register('x-bat', XBat);

  useHtmlConfiguration();

  setUp(() => Polymer.onReady.then(waitForElementReady));

  test('bind properties test', () {
    var e = document.querySelector('bind-properties-test');
    var foo = e.shadowRoot.querySelector('#foo');
    var bar = foo.shadowRoot.querySelector('#bar');
    var bat = foo.shadowRoot.querySelector('#bat');
    var baz = bar.shadowRoot.querySelector('#baz');

    expect(foo.val, 3);
    expect(bar.val, 3);
    expect(bat.val, 3);
    expect(baz.val, 3);

    foo.val = 4;

    expect(foo.val, 4);
    expect(bar.val, 4);
    expect(bat.val, 4);
    expect(baz.val, 4);

    baz.val = 5;

    expect(foo.val, 5);
    expect(bar.val, 5);
    expect(bat.val, 5);
    expect(baz.val, 5);

    e.obj['path']['to']['value'] = 6;

    expect(foo.val, 6);
    expect(bar.val, 6);
    expect(bat.val, 6);
    expect(baz.val, 6);
  });
}

