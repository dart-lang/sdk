// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'package:polymer/polymer.dart';

class XFoo extends PolymerElement {
  XFoo.created() : super.created();

  @PublishedProperty(reflect: true) var foo = '';
  @PublishedProperty(reflect: true) String baz = '';

  @PublishedProperty(reflect: true) var def1, def2;
}

class XBar extends XFoo {
  XBar.created() : super.created();

  @PublishedProperty(reflect: true) int zot = 3;
  @PublishedProperty(reflect: true) bool zim = false;
  @PublishedProperty(reflect: true) String str = 'str';
  @PublishedProperty(reflect: true) Object obj;
}

class XZot extends XBar {
  // Dart note: trying to make this roughly equivalent to the JS
  @PublishedProperty(reflect: false) int get zot => super.zot;
  @PublishedProperty(reflect: false) set zot(int x) { super.zot = x; }

  XZot.created() : super.created() {
    zot = 2;
    str = 'str2';
  }
}

class XCompose extends PolymerElement {
  XCompose.created() : super.created();

  @observable bool zim = false;
}

Future onAttributeChange(Element node) {
  var completer = new Completer();
  new MutationObserver((records, observer) {
    observer.disconnect();
    completer.complete();
  })..observe(node, attributes: true);
  scheduleMicrotask(Observable.dirtyCheck);
  return completer.future;
}

main() => initPolymer().run(() {
  useHtmlConfiguration();

  setUp(() => Polymer.onReady);

  // Most tests use @CustomTag, here we test out the impertive register:
  Polymer.register('x-foo', XFoo);
  Polymer.register('x-bar', XBar);
  Polymer.register('x-zot', XZot);
  Polymer.register('x-compose', XCompose);

  test('property to attribute reflection', () {
    var xcompose = querySelector('x-compose');
    var xfoo = querySelector('x-foo');
    var xbar = querySelector('x-bar');
    var xzot = querySelector('x-zot');
    xfoo.foo = 5;
    xfoo.attributes['def1'] = '15';
    xfoo.def2 = 15;

    // Dart note: our test here is more async than JS until we change
    // Polymer.dart bindings to work like observe.js "bindToInstance".
    return onAttributeChange(xfoo).then((_) {
      expect(xcompose.$['bar'].attributes.containsKey('zim'), false,
          reason: 'attribute bound to property updates when binding is made');

      expect(xfoo.attributes['def2'], '15',
          reason: 'default valued published property reflects to attr');

      expect(xfoo.def1, 15,
          reason: 'attr updates default valued published property');

      expect('${xfoo.foo}', xfoo.attributes['foo'],
          reason: 'attribute reflects property as string');
      xfoo.attributes['foo'] = '27';
      // TODO(jmesserly): why is JS leaving this as a String? From the code it
      // looks like it should use the type of 5 and parse it as a number.
      expect('${xfoo.foo}', xfoo.attributes['foo'],
          reason: 'property reflects attribute');
      //
      xfoo.baz = 'Hello';
    }).then((_) => onAttributeChange(xfoo)).then((_) {
      expect(xfoo.baz, xfoo.attributes['baz'],
          reason: 'attribute reflects property');
      //
      xbar.foo = 'foo!';
      xbar.zot = 27;
      xbar.zim = true;
      xbar.str = 'str!';
      xbar.obj = {'hello': 'world'};
    }).then((_) => onAttributeChange(xbar)).then((_) {
      expect(xbar.foo, xbar.attributes['foo'],
          reason: 'inherited published property is reflected');
      expect('${xbar.zot}', xbar.attributes['zot'],
          reason: 'attribute reflects property as number');
      expect(xbar.attributes['zim'], '', reason:
          'attribute reflects true valued boolean property as '
          'having attribute');
      expect(xbar.str, xbar.attributes['str'],
          reason: 'attribute reflects property as published string');
      expect(xbar.attributes.containsKey('obj'), false,
          reason: 'attribute does not reflect object property');
      xbar.attributes['zim'] = 'false';
      xbar.attributes['foo'] = 'foo!!';
      xbar.attributes['zot'] = '54';
      xbar.attributes['str'] = 'str!!';
      xbar.attributes['obj'] = "{'hello': 'world'}";
      expect(xbar.foo, xbar.attributes['foo'],
          reason: 'property reflects attribute as string');
      expect(xbar.zot, 54,
          reason: 'property reflects attribute as number');
      expect(xbar.zim, false,
          reason: 'property reflects attribute as boolean');
      expect(xbar.str, 'str!!',
          reason: 'property reflects attribute as published string');
      expect(xbar.obj, {'hello': 'world'},
          reason: 'property reflects attribute as object');
      xbar.zim = false;
    }).then((_) => onAttributeChange(xbar)).then((_) {
      expect(xbar.attributes.containsKey('zim'), false, reason:
          'attribute reflects false valued boolean property as NOT '
          'having attribute');
      xbar.obj = 'hi';
    }).then((_) => onAttributeChange(xbar)).then((_) {
      expect(xbar.attributes['obj'], 'hi', reason:
          'reflect property based on current type');

      expect(xzot.str, 'str2');
      expect(xzot.zot, 2);
      xzot.str = 'hello';
      xzot.zot = 5;
    }).then((_) => onAttributeChange(xzot)).then((_) {
      expect(xzot.attributes['str'], xzot.str);
      // TODO(jmesserly): the JS test seems backwards of the description text.
      // Is it because it doesn't do "Platform.flush()"?
      expect(xzot.attributes['zot'], '5',
          reason: 'extendee reflect false not honored');
    });
  });
});
