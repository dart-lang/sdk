// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library custom_element_bindings_test;

import 'dart:async';
import 'dart:html';
import 'package:mdv_observe/mdv_observe.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';
import 'mdv_observe_utils.dart';

main() {
  useHtmlConfiguration();
  group('Custom Element Bindings', customElementBindingsTest);
}

sym(x) => new Symbol(x);

customElementBindingsTest() {
  var testDiv;

  setUp(() {
    document.body.append(testDiv = new DivElement());
  });

  tearDown(() {
    testDiv.remove();
    testDiv = null;
  });

  createTestHtml(s) {
    var div = new DivElement();
    div.innerHtml = s;
    testDiv.append(div);

    for (var node in div.queryAll('*')) {
      if (node.isTemplate) TemplateElement.decorate(node);
    }

    return div;
  }


  test('override bind/unbind/unbindAll', () {
    var element = new MyCustomElement();
    var model = toSymbolMap({'a': new Point(123, 444), 'b': new Monster(100)});

    element.bind('my-point', model, 'a');
    element.bind('scary-monster', model, 'b');

    expect(element.attributes, isNot(contains('my-point')));
    expect(element.attributes, isNot(contains('scary-monster')));

    expect(element.myPoint, model[sym('a')]);
    expect(element.scaryMonster, model[sym('b')]);

    model[sym('a')] = null;
    deliverChangeRecords();
    expect(element.myPoint, null);
    element.unbind('my-point');

    model[sym('a')] = new Point(1, 2);
    model[sym('b')] = new Monster(200);
    deliverChangeRecords();
    expect(element.scaryMonster, model[sym('b')]);
    expect(element.myPoint, null, reason: 'a was unbound');

    element.unbindAll();
    model[sym('b')] = null;
    deliverChangeRecords();
    expect(element.scaryMonster.health, 200);
  });

  test('override attribute setter', () {
    var element = new WithAttrsCustomElement().real;
    var model = toSymbolMap({'a': 1, 'b': 2});
    element.bind('hidden?', model, 'a');
    element.bind('id', model, 'b');

    expect(element.attributes, contains('hidden'));
    expect(element.attributes['hidden'], '');
    expect(element.id, '2');

    model[sym('a')] = null;
    deliverChangeRecords();
    expect(element.attributes, isNot(contains('hidden')),
        reason: 'null is false-y');

    model[sym('a')] = false;
    deliverChangeRecords();
    expect(element.attributes, isNot(contains('hidden')));

    model[sym('a')] = 'foo';
    model[sym('b')] = 'x';
    deliverChangeRecords();
    expect(element.attributes, contains('hidden'));
    expect(element.attributes['hidden'], '');
    expect(element.id, 'x');

    expect(element.xtag.attributes.log, [
      ['remove', 'hidden?'],
      ['[]=', 'hidden', ''],
      ['remove', 'id'],
      ['[]=', 'id', '2'],
      ['remove', 'hidden'],
      ['remove', 'hidden'],
      ['[]=', 'hidden', ''],
      ['[]=', 'id', 'x'],
    ]);
  });

  test('template bind uses overridden custom element bind', () {

    var model = toSymbolMap({'a': new Point(123, 444), 'b': new Monster(100)});

    var div = createTestHtml('<template bind>'
          '<my-custom-element my-point="{{a}}" scary-monster="{{b}}">'
          '</my-custom-element>'
        '</template>');

    TemplateElement.instanceCreated.listen((fragment) {
      for (var e in fragment.queryAll('my-custom-element')) {
        new MyCustomElement.attach(e);
      }
    });

    div.query('template').model = model;
    deliverChangeRecords();

    var element = div.nodes[1];

    expect(element.xtag is MyCustomElement, true,
        reason: '${element.xtag} should be a MyCustomElement');

    expect(element.xtag.myPoint, model[sym('a')]);
    expect(element.xtag.scaryMonster, model[sym('b')]);

    expect(element.attributes, isNot(contains('my-point')));
    expect(element.attributes, isNot(contains('scary-monster')));

    model[sym('a')] = null;
    deliverChangeRecords();
    expect(element.xtag.myPoint, null);

    div.query('template').model = null;
    deliverChangeRecords();

    expect(element.parentNode, null, reason: 'element was detached');

    model[sym('a')] = new Point(1, 2);
    model[sym('b')] = new Monster(200);
    deliverChangeRecords();

    expect(element.xtag.myPoint, null, reason: 'model was unbound');
    expect(element.xtag.scaryMonster.health, 100, reason: 'model was unbound');
  });

}

class Monster {
  int health;
  Monster(this.health);
}

/** Demonstrates a custom element overriding bind/unbind/unbindAll. */
class MyCustomElement implements Element {
  final Element real;

  Point myPoint;
  Monster scaryMonster;

  StreamSubscription _sub1, _sub2;

  MyCustomElement() : this.attach(new Element.tag('my-custom-element'));

  MyCustomElement.attach(this.real) {
    real.xtag = this;
  }


  get attributes => real.attributes;

  void bind(String name, model, String path) {
    switch (name) {
      case 'my-point':
        unbind('my-point');
        attributes.remove('my-point');

        _sub1 = new PathObserver(model, path).bindSync((v) {
          myPoint = v;
        });
        return;
      case 'scary-monster':
        unbind('scary-monster');
        attributes.remove('scary-monster');

        _sub2 = new PathObserver(model, path).bindSync((v) {
          scaryMonster = v;
        });
        return;
    }
    real.bind(name, model, path);
  }

  void unbind(String name) {
    switch (name) {
      case 'my-point':
        if (_sub1 != null) {
          print('!!! unbind $name');
          _sub1.cancel();
          _sub1 = null;
        }
        return;
      case 'scary-monster':
        if (_sub2 != null) {
          print('!!! unbind $name');
          _sub2.cancel();
          _sub2 = null;
        }
        return;
    }
    real.unbind(name);
  }

  void unbindAll() {
    unbind('my-point');
    unbind('scary-monster');
    real.unbindAll();
  }
}

/**
 * Demonstrates a custom element can override attributes []= and remove.
 * and see changes that the data binding system is making to the attributes.
 */
class WithAttrsCustomElement implements Element {
  final Element real;
  final AttributeMapWrapper<String, String> attributes;

  factory WithAttrsCustomElement() {
    var real = new Element.tag('with-attrs-custom-element');
    var attributes = new AttributeMapWrapper(real.attributes);
    return new WithAttrsCustomElement._(real, attributes);
  }

  WithAttrsCustomElement._(this.real, this.attributes) {
    real.xtag = this;
  }

  void bind(String name, model, String path) => real.bind(name, model, path);
  void unbind(String name) => real.unbind(name);
  void unbindAll() => real.unbindAll();
}

// TODO(jmesserly): would be nice to use mocks when mirrors work on dart2js.
class AttributeMapWrapper<K, V> implements Map<K, V> {
  final List log = [];
  Map<K, V> _map;

  AttributeMapWrapper(this._map);

  bool containsValue(Object value) => _map.containsValue(value);
  bool containsKey(Object key) => _map.containsKey(key);
  V operator [](Object key) => _map[key];

  void operator []=(K key, V value) {
    log.add(['[]=', key, value]);
    _map[key] = value;
  }

  V putIfAbsent(K key, V ifAbsent()) => _map.putIfAbsent(key, ifAbsent);

  V remove(Object key) {
    log.add(['remove', key]);
    _map.remove(key);
  }

  void clear() => _map.clear();
  void forEach(void f(K key, V value)) => _map.forEach(f);
  Iterable<K> get keys => _map.keys;
  Iterable<V> get values => _map.values;
  int get length => _map.length;
  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;
}
