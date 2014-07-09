// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library template_binding.test.custom_element_bindings_test;

import 'dart:async';
import 'dart:html';
import 'dart:collection' show MapView;
import 'package:template_binding/template_binding.dart';
import 'package:observe/observe.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';
import 'package:web_components/polyfill.dart';
import 'utils.dart';

Future _registered;

main() => dirtyCheckZone().run(() {
  useHtmlConfiguration();

  _registered = customElementsReady.then((_) {
    document.registerElement('my-custom-element', MyCustomElement);
  });

  group('Custom Element Bindings', customElementBindingsTest);
});

customElementBindingsTest() {
  setUp(() {
    document.body.append(testDiv = new DivElement());
    return _registered;
  });

  tearDown(() {
    testDiv.remove();
    testDiv = null;
  });

  test('override bind/bindFinished', () {
    var element = new MyCustomElement();
    var model = toObservable({'a': new Point(123, 444), 'b': new Monster(100)});

    var pointBinding = nodeBind(element)
        .bind('my-point', new PathObserver(model, 'a'));

    var scaryBinding = nodeBind(element)
        .bind('scary-monster', new PathObserver(model, 'b'));

    expect(element.attributes, isNot(contains('my-point')));
    expect(element.attributes, isNot(contains('scary-monster')));

    expect(element.myPoint, model['a']);
    expect(element.scaryMonster, model['b']);

    model['a'] = null;
    return new Future(() {
      expect(element.myPoint, null);
      expect(element.bindFinishedCalled, 0);
      pointBinding.close();

      model['a'] = new Point(1, 2);
      model['b'] = new Monster(200);
    }).then(endOfMicrotask).then((_) {
      expect(element.scaryMonster, model['b']);
      expect(element.myPoint, null, reason: 'a was unbound');

      scaryBinding.close();
      model['b'] = null;
    }).then(endOfMicrotask).then((_) {
      expect(element.scaryMonster.health, 200);
      expect(element.bindFinishedCalled, 0);
    });
  });

  test('template bind uses overridden custom element bind', () {

    var model = toObservable({'a': new Point(123, 444), 'b': new Monster(100)});
    var div = createTestHtml('<template bind>'
          '<my-custom-element my-point="{{a}}" scary-monster="{{b}}">'
          '</my-custom-element>'
        '</template>');

    templateBind(div.query('template')).model = model;
    var element;
    return new Future(() {
      element = div.nodes[1];

      expect(element is MyCustomElement, true,
          reason: '$element should be a MyCustomElement');

      expect(element.myPoint, model['a']);
      expect(element.scaryMonster, model['b']);

      expect(element.attributes, isNot(contains('my-point')));
      expect(element.attributes, isNot(contains('scary-monster')));

      expect(element.bindFinishedCalled, 1);

      model['a'] = null;
    }).then(endOfMicrotask).then((_) {
      expect(element.myPoint, null);
      expect(element.bindFinishedCalled, 1);


      templateBind(div.query('template')).model = null;
    }).then(endOfMicrotask).then((_) {
      // Note: the detached element
      expect(element.parentNode is DocumentFragment, true,
          reason: 'removed element is added back to its document fragment');
      expect(element.parentNode.parentNode, null,
          reason: 'document fragment is detached');
      expect(element.bindFinishedCalled, 1);

      model['a'] = new Point(1, 2);
      model['b'] = new Monster(200);
    }).then(endOfMicrotask).then((_) {
      expect(element.myPoint, null, reason: 'model was unbound');
      expect(element.scaryMonster.health, 100, reason: 'model was unbound');
      expect(element.bindFinishedCalled, 1);
    });
  });

}

class Monster {
  int health;
  Monster(this.health);
}

/** Demonstrates a custom element overriding bind/bindFinished. */
class MyCustomElement extends HtmlElement implements NodeBindExtension {
  Point myPoint;
  Monster scaryMonster;
  int bindFinishedCalled = 0;

  factory MyCustomElement() => new Element.tag('my-custom-element');

  MyCustomElement.created() : super.created();

  Bindable bind(String name, value, {oneTime: false}) {
    switch (name) {
      case 'my-point':
      case 'scary-monster':
        attributes.remove(name);
        if (oneTime) {
          _setProperty(name, value);
          return null;
        }
        _setProperty(name, value.open((x) => _setProperty(name, x)));

        if (!enableBindingsReflection) return value;
        if (bindings == null) bindings = {};
        var old = bindings[name];
        if (old != null) old.close();
        return bindings[name] = value;
    }
    return nodeBindFallback(this).bind(name, value, oneTime: oneTime);
  }

  void bindFinished() {
    bindFinishedCalled++;
  }

  get bindings => nodeBindFallback(this).bindings;
  set bindings(x) => nodeBindFallback(this).bindings = x;
  get templateInstance => nodeBindFallback(this).templateInstance;

  void _setProperty(String property, newValue) {
    if (property == 'my-point') myPoint = newValue;
    if (property == 'scary-monster') scaryMonster = newValue;
  }
}

