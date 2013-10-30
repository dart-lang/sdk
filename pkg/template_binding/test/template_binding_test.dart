// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library template_binding.test.template_binding_test;

import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:math' as math;
import 'package:observe/observe.dart';
import 'package:template_binding/template_binding.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

// TODO(jmesserly): merge this file?
import 'binding_syntax.dart' show syntaxTests;
import 'utils.dart';

// Note: this file ported from
// https://github.com/Polymer/TemplateBinding/blob/ed3266266e751b5ab1f75f8e0509d0d5f0ef35d8/tests/tests.js

// TODO(jmesserly): submit a small cleanup patch to original. I fixed some
// cases where "div" and "t" were unintentionally using the JS global scope;
// look for "assertNodesAre".

main() {
  useHtmlConfiguration();

  setUp(() {
    document.body.append(testDiv = new DivElement());
  });

  tearDown(() {
    testDiv.remove();
    testDiv = null;
  });

  group('Template Instantiation', templateInstantiationTests);

  group('Binding Delegate API', () {
    group('with Observable', () {
      syntaxTests(([f, b]) => new FooBarModel(f, b));
    });

    group('with ChangeNotifier', () {
      syntaxTests(([f, b]) => new FooBarNotifyModel(f, b));
    });
  });

  group('Compat', compatTests);
}

var expando = new Expando('test');
void addExpandos(node) {
  while (node != null) {
    expando[node] = node.text;
    node = node.nextNode;
  }
}

void checkExpandos(node) {
  expect(node, isNotNull);
  while (node != null) {
    expect(expando[node], node.text);
    node = node.nextNode;
  }
}

templateInstantiationTests() {

  observeTest('Template', () {
    var div = createTestHtml('<template bind={{}}>text</template>');
    templateBind(div.firstChild).model = {};
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 2);
    expect(div.nodes.last.text, 'text');

    templateBind(div.firstChild).model = null;
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 1);
  });

  observeTest('Template bind, no parent', () {
    var div = createTestHtml('<template bind>text</template>');
    var template = div.firstChild;
    template.remove();

    templateBind(template).model = {};
    performMicrotaskCheckpoint();
    expect(template.nodes.length, 0);
    expect(template.nextNode, null);
  });

  observeTest('Template bind, no defaultView', () {
    var div = createTestHtml('<template bind>text</template>');
    var template = div.firstChild;
    var doc = document.implementation.createHtmlDocument('');
    doc.adoptNode(div);
    recursivelySetTemplateModel(template, {});
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 1);
  });

  observeTest('Template-Empty Bind', () {
    var div = createTestHtml('<template bind>text</template>');
    var template = div.firstChild;
    templateBind(template).model = {};
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 2);
    expect(div.nodes.last.text, 'text');
  });

  observeTest('Template Bind If', () {
    var div = createTestHtml('<template bind if="{{ foo }}">text</template>');
    // Note: changed this value from 0->null because zero is not falsey in Dart.
    // See https://code.google.com/p/dart/issues/detail?id=11956
    var m = toObservable({ 'foo': null });
    var template = div.firstChild;
    templateBind(template).model = m;
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 1);

    m['foo'] = 1;
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 2);
    expect(div.lastChild.text, 'text');

    templateBind(template).model = null;
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 1);
  });

  observeTest('Template Bind If, 2', () {
    var div = createTestHtml(
        '<template bind="{{ foo }}" if="{{ bar }}">{{ bat }}</template>');
    var m = toObservable({ 'bar': null, 'foo': { 'bat': 'baz' } });
    recursivelySetTemplateModel(div, m);
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 1);

    m['bar'] = 1;
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 2);
    expect(div.lastChild.text, 'baz');
  });

  observeTest('Template If', () {
    var div = createTestHtml('<template if="{{ foo }}">{{ value }}</template>');
    // Note: changed this value from 0->null because zero is not falsey in
    // Dart. See https://code.google.com/p/dart/issues/detail?id=11956
    var m = toObservable({ 'foo': null, 'value': 'foo' });
    var template = div.firstChild;
    templateBind(template).model = m;
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 1);

    m['foo'] = 1;
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 2);
    expect(div.lastChild.text, 'foo');

    templateBind(template).model = null;
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 1);
  });

  observeTest('Template Empty-If', () {
    var div = createTestHtml('<template if>{{ value }}</template>');
    var m = toObservable({ 'value': 'foo' });
    recursivelySetTemplateModel(div, null);
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 1);

    recursivelySetTemplateModel(div, m);
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 2);
    expect(div.lastChild.text, 'foo');
  });

  observeTest('Template Repeat If', () {
    var div = createTestHtml(
        '<template repeat="{{ foo }}" if="{{ bar }}">{{ }}</template>');
    // Note: changed this value from 0->null because zero is not falsey in Dart.
    // See https://code.google.com/p/dart/issues/detail?id=11956
    var m = toObservable({ 'bar': null, 'foo': [1, 2, 3] });
    var template = div.firstChild;
    templateBind(template).model = m;
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 1);

    m['bar'] = 1;
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 4);
    expect(div.nodes[1].text, '1');
    expect(div.nodes[2].text, '2');
    expect(div.nodes[3].text, '3');

    templateBind(template).model = null;
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 1);
  });

  observeTest('TextTemplateWithNullStringBinding', () {
    var div = createTestHtml('<template bind={{}}>a{{b}}c</template>');
    var model = toObservable({'b': 'B'});
    recursivelySetTemplateModel(div, model);

    performMicrotaskCheckpoint();
    expect(div.nodes.length, 2);
    expect(div.nodes.last.text, 'aBc');

    model['b'] = 'b';
    performMicrotaskCheckpoint();
    expect(div.nodes.last.text, 'abc');

    model['b'] = null;
    performMicrotaskCheckpoint();
    expect(div.nodes.last.text, 'ac');

    model = null;
    performMicrotaskCheckpoint();
    // setting model isn't observable.
    expect(div.nodes.last.text, 'ac');
  });

  observeTest('TextTemplateWithBindingPath', () {
    var div = createTestHtml(
        '<template bind="{{ data }}">a{{b}}c</template>');
    var model = toObservable({ 'data': {'b': 'B'} });
    var template = div.firstChild;
    templateBind(template).model = model;

    performMicrotaskCheckpoint();
    expect(div.nodes.length, 2);
    expect(div.nodes.last.text, 'aBc');

    model['data']['b'] = 'b';
    performMicrotaskCheckpoint();
    expect(div.nodes.last.text, 'abc');

    model['data'] = toObservable({'b': 'X'});
    performMicrotaskCheckpoint();
    expect(div.nodes.last.text, 'aXc');

    // Dart note: changed from `null` since our null means don't render a model.
    model['data'] = toObservable({});
    performMicrotaskCheckpoint();
    expect(div.nodes.last.text, 'ac');

    model['data'] = null;
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 1);
  });

  observeTest('TextTemplateWithBindingAndConditional', () {
    var div = createTestHtml(
        '<template bind="{{}}" if="{{ d }}">a{{b}}c</template>');
    var model = toObservable({'b': 'B', 'd': 1});
    recursivelySetTemplateModel(div, model);

    performMicrotaskCheckpoint();
    expect(div.nodes.length, 2);
    expect(div.nodes.last.text, 'aBc');

    model['b'] = 'b';
    performMicrotaskCheckpoint();
    expect(div.nodes.last.text, 'abc');

    // TODO(jmesserly): MDV set this to empty string and relies on JS conversion
    // rules. Is that intended?
    // See https://github.com/toolkitchen/mdv/issues/59
    model['d'] = null;
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 1);

    model['d'] = 'here';
    model['b'] = 'd';

    performMicrotaskCheckpoint();
    expect(div.nodes.length, 2);
    expect(div.nodes.last.text, 'adc');
  });

  observeTest('TemplateWithTextBinding2', () {
    var div = createTestHtml(
        '<template bind="{{ b }}">a{{value}}c</template>');
    expect(div.nodes.length, 1);
    var model = toObservable({'b': {'value': 'B'}});
    recursivelySetTemplateModel(div, model);

    performMicrotaskCheckpoint();
    expect(div.nodes.length, 2);
    expect(div.nodes.last.text, 'aBc');

    model['b'] = toObservable({'value': 'b'});
    performMicrotaskCheckpoint();
    expect(div.nodes.last.text, 'abc');
  });

  observeTest('TemplateWithAttributeBinding', () {
    var div = createTestHtml(
        '<template bind="{{}}">'
        '<div foo="a{{b}}c"></div>'
        '</template>');
    var model = toObservable({'b': 'B'});
    recursivelySetTemplateModel(div, model);

    performMicrotaskCheckpoint();
    expect(div.nodes.length, 2);
    expect(div.nodes.last.attributes['foo'], 'aBc');

    model['b'] = 'b';
    performMicrotaskCheckpoint();
    expect(div.nodes.last.attributes['foo'], 'abc');

    model['b'] = 'X';
    performMicrotaskCheckpoint();
    expect(div.nodes.last.attributes['foo'], 'aXc');
  });

  observeTest('TemplateWithConditionalBinding', () {
    var div = createTestHtml(
        '<template bind="{{}}">'
        '<div foo?="{{b}}"></div>'
        '</template>');
    var model = toObservable({'b': 'b'});
    recursivelySetTemplateModel(div, model);

    performMicrotaskCheckpoint();
    expect(div.nodes.length, 2);
    expect(div.nodes.last.attributes['foo'], '');
    expect(div.nodes.last.attributes, isNot(contains('foo?')));

    model['b'] = null;
    performMicrotaskCheckpoint();
    expect(div.nodes.last.attributes, isNot(contains('foo')));
  });

  observeTest('Repeat', () {
    var div = createTestHtml(
        '<template repeat="{{}}"">text</template>');

    var model = toObservable([0, 1, 2]);
    recursivelySetTemplateModel(div, model);

    performMicrotaskCheckpoint();
    expect(div.nodes.length, 4);

    model.length = 1;
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 2);

    model.addAll(toObservable([3, 4]));
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 4);

    model.removeRange(1, 2);
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 3);
  });

  observeTest('Repeat - Reuse Instances', () {
    var div = createTestHtml('<template repeat>{{ val }}</template>');

    var model = toObservable([
      {'val': 10},
      {'val': 5},
      {'val': 2},
      {'val': 8},
      {'val': 1}
    ]);
    recursivelySetTemplateModel(div, model);

    performMicrotaskCheckpoint();
    expect(div.nodes.length, 6);
    var template = div.firstChild;

    addExpandos(template.nextNode);
    checkExpandos(template.nextNode);

    model.sort((a, b) => a['val'] - b['val']);
    performMicrotaskCheckpoint();
    checkExpandos(template.nextNode);

    model = toObservable(model.reversed);
    recursivelySetTemplateModel(div, model);
    performMicrotaskCheckpoint();
    checkExpandos(template.nextNode);

    for (var item in model) {
      item['val'] += 1;
    }

    performMicrotaskCheckpoint();
    expect(div.nodes[1].text, "11");
    expect(div.nodes[2].text, "9");
    expect(div.nodes[3].text, "6");
    expect(div.nodes[4].text, "3");
    expect(div.nodes[5].text, "2");
  });

  observeTest('Bind - Reuse Instance', () {
    var div = createTestHtml(
        '<template bind="{{ foo }}">{{ bar }}</template>');

    var model = toObservable({ 'foo': { 'bar': 5 }});
    recursivelySetTemplateModel(div, model);

    performMicrotaskCheckpoint();
    expect(div.nodes.length, 2);
    var template = div.firstChild;

    addExpandos(template.nextNode);
    checkExpandos(template.nextNode);

    model = toObservable({'foo': model['foo']});
    recursivelySetTemplateModel(div, model);
    performMicrotaskCheckpoint();
    checkExpandos(template.nextNode);
  });

  observeTest('Repeat-Empty', () {
    var div = createTestHtml(
        '<template repeat>text</template>');

    var model = toObservable([0, 1, 2]);
    recursivelySetTemplateModel(div, model);

    performMicrotaskCheckpoint();
    expect(div.nodes.length, 4);

    model.length = 1;
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 2);

    model.addAll(toObservable([3, 4]));
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 4);

    model.removeRange(1, 2);
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 3);
  });

  observeTest('Removal from iteration needs to unbind', () {
    var div = createTestHtml(
        '<template repeat="{{}}"><a>{{v}}</a></template>');
    var model = toObservable([{'v': 0}, {'v': 1}, {'v': 2}, {'v': 3},
        {'v': 4}]);
    recursivelySetTemplateModel(div, model);
    performMicrotaskCheckpoint();

    var nodes = div.nodes.skip(1).toList();
    var vs = model.toList();

    for (var i = 0; i < 5; i++) {
      expect(nodes[i].text, '$i');
    }

    model.length = 3;
    performMicrotaskCheckpoint();
    for (var i = 0; i < 5; i++) {
      expect(nodes[i].text, '$i');
    }

    vs[3]['v'] = 33;
    vs[4]['v'] = 44;
    performMicrotaskCheckpoint();
    for (var i = 0; i < 5; i++) {
      expect(nodes[i].text, '$i');
    }
  });

  observeTest('DOM Stability on Iteration', () {
    var div = createTestHtml(
        '<template repeat="{{}}">{{}}</template>');
    var model = toObservable([1, 2, 3, 4, 5]);
    recursivelySetTemplateModel(div, model);

    performMicrotaskCheckpoint();

    // Note: the node at index 0 is the <template>.
    var nodes = div.nodes.toList();
    expect(nodes.length, 6, reason: 'list has 5 items');

    model.removeAt(0);
    model.removeLast();

    performMicrotaskCheckpoint();
    expect(div.nodes.length, 4, reason: 'list has 3 items');
    expect(identical(div.nodes[1], nodes[2]), true, reason: '2 not removed');
    expect(identical(div.nodes[2], nodes[3]), true, reason: '3 not removed');
    expect(identical(div.nodes[3], nodes[4]), true, reason: '4 not removed');

    model.insert(0, 5);
    model[2] = 6;
    model.add(7);

    performMicrotaskCheckpoint();

    expect(div.nodes.length, 6, reason: 'list has 5 items');
    expect(nodes.contains(div.nodes[1]), false, reason: '5 is a new node');
    expect(identical(div.nodes[2], nodes[2]), true);
    expect(nodes.contains(div.nodes[3]), false, reason: '6 is a new node');
    expect(identical(div.nodes[4], nodes[4]), true);
    expect(nodes.contains(div.nodes[5]), false, reason: '7 is a new node');

    nodes = div.nodes.toList();

    model.insert(2, 8);

    performMicrotaskCheckpoint();

    expect(div.nodes.length, 7, reason: 'list has 6 items');
    expect(identical(div.nodes[1], nodes[1]), true);
    expect(identical(div.nodes[2], nodes[2]), true);
    expect(nodes.contains(div.nodes[3]), false, reason: '8 is a new node');
    expect(identical(div.nodes[4], nodes[3]), true);
    expect(identical(div.nodes[5], nodes[4]), true);
    expect(identical(div.nodes[6], nodes[5]), true);
  });

  observeTest('Repeat2', () {
    var div = createTestHtml(
        '<template repeat="{{}}">{{value}}</template>');
    expect(div.nodes.length, 1);

    var model = toObservable([
      {'value': 0},
      {'value': 1},
      {'value': 2}
    ]);
    recursivelySetTemplateModel(div, model);

    performMicrotaskCheckpoint();
    expect(div.nodes.length, 4);
    expect(div.nodes[1].text, '0');
    expect(div.nodes[2].text, '1');
    expect(div.nodes[3].text, '2');

    model[1]['value'] = 'One';
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 4);
    expect(div.nodes[1].text, '0');
    expect(div.nodes[2].text, 'One');
    expect(div.nodes[3].text, '2');

    model.replaceRange(0, 1, toObservable([{'value': 'Zero'}]));
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 4);
    expect(div.nodes[1].text, 'Zero');
    expect(div.nodes[2].text, 'One');
    expect(div.nodes[3].text, '2');
  });

  observeTest('TemplateWithInputValue', () {
    var div = createTestHtml(
        '<template bind="{{}}">'
        '<input value="{{x}}">'
        '</template>');
    var model = toObservable({'x': 'hi'});
    recursivelySetTemplateModel(div, model);

    performMicrotaskCheckpoint();
    expect(div.nodes.length, 2);
    expect(div.nodes.last.value, 'hi');

    model['x'] = 'bye';
    expect(div.nodes.last.value, 'hi');
    performMicrotaskCheckpoint();
    expect(div.nodes.last.value, 'bye');

    div.nodes.last.value = 'hello';
    dispatchEvent('input', div.nodes.last);
    expect(model['x'], 'hello');
    performMicrotaskCheckpoint();
    expect(div.nodes.last.value, 'hello');
  });

//////////////////////////////////////////////////////////////////////////////

  observeTest('Decorated', () {
    var div = createTestHtml(
        '<template bind="{{ XX }}" id="t1">'
          '<p>Crew member: {{name}}, Job title: {{title}}</p>'
        '</template>'
        '<template bind="{{ XY }}" id="t2" ref="t1"></template>');

    var model = toObservable({
      'XX': {'name': 'Leela', 'title': 'Captain'},
      'XY': {'name': 'Fry', 'title': 'Delivery boy'},
      'XZ': {'name': 'Zoidberg', 'title': 'Doctor'}
    });
    recursivelySetTemplateModel(div, model);

    performMicrotaskCheckpoint();

    var t1 = document.getElementById('t1');
    var instance = t1.nextElementSibling;
    expect(instance.text, 'Crew member: Leela, Job title: Captain');

    var t2 = document.getElementById('t2');
    instance = t2.nextElementSibling;
    expect(instance.text, 'Crew member: Fry, Job title: Delivery boy');

    expect(div.children.length, 4);
    expect(div.nodes.length, 4);

    expect(div.nodes[1].tagName, 'P');
    expect(div.nodes[3].tagName, 'P');
  });

  observeTest('DefaultStyles', () {
    var t = new Element.tag('template');
    TemplateBindExtension.decorate(t);

    document.body.append(t);
    expect(t.getComputedStyle().display, 'none');

    t.remove();
  });


  observeTest('Bind', () {
    var div = createTestHtml('<template bind="{{}}">Hi {{ name }}</template>');
    var model = toObservable({'name': 'Leela'});
    recursivelySetTemplateModel(div, model);

    performMicrotaskCheckpoint();
    expect(div.nodes[1].text, 'Hi Leela');
  });

  observeTest('BindImperative', () {
    var div = createTestHtml(
        '<template>'
          'Hi {{ name }}'
        '</template>');
    var t = div.nodes.first;

    var model = toObservable({'name': 'Leela'});
    nodeBind(t).bind('bind', model, '');

    performMicrotaskCheckpoint();
    expect(div.nodes[1].text, 'Hi Leela');
  });

  observeTest('BindPlaceHolderHasNewLine', () {
    var div = createTestHtml(
        '<template bind="{{}}">Hi {{\nname\n}}</template>');
    var model = toObservable({'name': 'Leela'});
    recursivelySetTemplateModel(div, model);

    performMicrotaskCheckpoint();
    expect(div.nodes[1].text, 'Hi Leela');
  });

  observeTest('BindWithRef', () {
    var id = 't${new math.Random().nextInt(100)}';
    var div = createTestHtml(
        '<template id="$id">'
          'Hi {{ name }}'
        '</template>'
        '<template ref="$id" bind="{{}}"></template>');

    var t1 = div.nodes.first;
    var t2 = div.nodes[1];

    expect(templateBind(t2).ref, t1);

    var model = toObservable({'name': 'Fry'});
    recursivelySetTemplateModel(div, model);

    performMicrotaskCheckpoint();
    expect(t2.nextNode.text, 'Hi Fry');
  });

  observeTest('BindWithDynamicRef', () {
    var id = 't${new math.Random().nextInt(100)}';
    var div = createTestHtml(
        '<template id="$id">'
          'Hi {{ name }}'
        '</template>'
        '<template ref="{{ id }}" bind="{{}}"></template>');

    var t1 = div.firstChild;
    var t2 = div.nodes[1];
    var model = toObservable({'name': 'Fry', 'id': id });
    recursivelySetTemplateModel(div, model);

    performMicrotaskCheckpoint();
    expect(t2.nextNode.text, 'Hi Fry');
  });

  observeTest('BindChanged', () {
    var model = toObservable({
      'XX': {'name': 'Leela', 'title': 'Captain'},
      'XY': {'name': 'Fry', 'title': 'Delivery boy'},
      'XZ': {'name': 'Zoidberg', 'title': 'Doctor'}
    });

    var div = createTestHtml(
        '<template bind="{{ XX }}">Hi {{ name }}</template>');

    recursivelySetTemplateModel(div, model);

    var t = div.nodes.first;
    performMicrotaskCheckpoint();

    expect(div.nodes.length, 2);
    expect(t.nextNode.text, 'Hi Leela');

    nodeBind(t).bind('bind', model, 'XZ');
    performMicrotaskCheckpoint();

    expect(div.nodes.length, 2);
    expect(t.nextNode.text, 'Hi Zoidberg');
  });

  assertNodesAre(div, [arguments]) {
    var expectedLength = arguments.length;
    expect(div.nodes.length, expectedLength + 1);

    for (var i = 0; i < arguments.length; i++) {
      var targetNode = div.nodes[i + 1];
      expect(targetNode.text, arguments[i]);
    }
  }

  observeTest('Repeat3', () {
    var div = createTestHtml(
        '<template repeat="{{ contacts }}">Hi {{ name }}</template>');
    var t = div.nodes.first;

    var m = toObservable({
      'contacts': [
        {'name': 'Raf'},
        {'name': 'Arv'},
        {'name': 'Neal'}
      ]
    });

    recursivelySetTemplateModel(div, m);
    performMicrotaskCheckpoint();

    assertNodesAre(div, ['Hi Raf', 'Hi Arv', 'Hi Neal']);

    m['contacts'].add(toObservable({'name': 'Alex'}));
    performMicrotaskCheckpoint();
    assertNodesAre(div, ['Hi Raf', 'Hi Arv', 'Hi Neal', 'Hi Alex']);

    m['contacts'].replaceRange(0, 2,
        toObservable([{'name': 'Rafael'}, {'name': 'Erik'}]));
    performMicrotaskCheckpoint();
    assertNodesAre(div, ['Hi Rafael', 'Hi Erik', 'Hi Neal', 'Hi Alex']);

    m['contacts'].removeRange(1, 3);
    performMicrotaskCheckpoint();
    assertNodesAre(div, ['Hi Rafael', 'Hi Alex']);

    m['contacts'].insertAll(1,
        toObservable([{'name': 'Erik'}, {'name': 'Dimitri'}]));
    performMicrotaskCheckpoint();
    assertNodesAre(div, ['Hi Rafael', 'Hi Erik', 'Hi Dimitri', 'Hi Alex']);

    m['contacts'].replaceRange(0, 1,
        toObservable([{'name': 'Tab'}, {'name': 'Neal'}]));
    performMicrotaskCheckpoint();
    assertNodesAre(div, ['Hi Tab', 'Hi Neal', 'Hi Erik', 'Hi Dimitri',
        'Hi Alex']);

    m['contacts'] = toObservable([{'name': 'Alex'}]);
    performMicrotaskCheckpoint();
    assertNodesAre(div, ['Hi Alex']);

    m['contacts'].length = 0;
    performMicrotaskCheckpoint();
    assertNodesAre(div, []);
  });

  observeTest('RepeatModelSet', () {
    var div = createTestHtml(
        '<template repeat="{{ contacts }}">'
          'Hi {{ name }}'
        '</template>');
    var m = toObservable({
      'contacts': [
        {'name': 'Raf'},
        {'name': 'Arv'},
        {'name': 'Neal'}
      ]
    });
    recursivelySetTemplateModel(div, m);

    performMicrotaskCheckpoint();
    var t = div.nodes.first;

    assertNodesAre(div, ['Hi Raf', 'Hi Arv', 'Hi Neal']);
  });

  observeTest('RepeatEmptyPath', () {
    var div = createTestHtml(
        '<template repeat="{{}}">Hi {{ name }}</template>');
    var t = div.nodes.first;

    var m = toObservable([
      {'name': 'Raf'},
      {'name': 'Arv'},
      {'name': 'Neal'}
    ]);
    recursivelySetTemplateModel(div, m);

    performMicrotaskCheckpoint();

    assertNodesAre(div, ['Hi Raf', 'Hi Arv', 'Hi Neal']);

    m.add(toObservable({'name': 'Alex'}));
    performMicrotaskCheckpoint();
    assertNodesAre(div, ['Hi Raf', 'Hi Arv', 'Hi Neal', 'Hi Alex']);

    m.replaceRange(0, 2, toObservable([{'name': 'Rafael'}, {'name': 'Erik'}]));
    performMicrotaskCheckpoint();
    assertNodesAre(div, ['Hi Rafael', 'Hi Erik', 'Hi Neal', 'Hi Alex']);

    m.removeRange(1, 3);
    performMicrotaskCheckpoint();
    assertNodesAre(div, ['Hi Rafael', 'Hi Alex']);

    m.insertAll(1, toObservable([{'name': 'Erik'}, {'name': 'Dimitri'}]));
    performMicrotaskCheckpoint();
    assertNodesAre(div, ['Hi Rafael', 'Hi Erik', 'Hi Dimitri', 'Hi Alex']);

    m.replaceRange(0, 1, toObservable([{'name': 'Tab'}, {'name': 'Neal'}]));
    performMicrotaskCheckpoint();
    assertNodesAre(div, ['Hi Tab', 'Hi Neal', 'Hi Erik', 'Hi Dimitri',
        'Hi Alex']);

    m.length = 0;
    m.add(toObservable({'name': 'Alex'}));
    performMicrotaskCheckpoint();
    assertNodesAre(div, ['Hi Alex']);
  });

  observeTest('RepeatNullModel', () {
    var div = createTestHtml(
        '<template repeat="{{}}">Hi {{ name }}</template>');
    var t = div.nodes.first;

    var m = null;
    recursivelySetTemplateModel(div, m);

    expect(div.nodes.length, 1);

    t.attributes['iterate'] = '';
    m = toObservable({});
    recursivelySetTemplateModel(div, m);

    performMicrotaskCheckpoint();
    expect(div.nodes.length, 1);
  });

  observeTest('RepeatReuse', () {
    var div = createTestHtml(
        '<template repeat="{{}}">Hi {{ name }}</template>');
    var t = div.nodes.first;

    var m = toObservable([
      {'name': 'Raf'},
      {'name': 'Arv'},
      {'name': 'Neal'}
    ]);
    recursivelySetTemplateModel(div, m);
    performMicrotaskCheckpoint();

    assertNodesAre(div, ['Hi Raf', 'Hi Arv', 'Hi Neal']);
    var node1 = div.nodes[1];
    var node2 = div.nodes[2];
    var node3 = div.nodes[3];

    m.replaceRange(1, 2, toObservable([{'name': 'Erik'}]));
    performMicrotaskCheckpoint();
    assertNodesAre(div, ['Hi Raf', 'Hi Erik', 'Hi Neal']);
    expect(div.nodes[1], node1,
        reason: 'model[0] did not change so the node should not have changed');
    expect(div.nodes[2], isNot(equals(node2)),
        reason: 'Should not reuse when replacing');
    expect(div.nodes[3], node3,
        reason: 'model[2] did not change so the node should not have changed');

    node2 = div.nodes[2];
    m.insert(0, toObservable({'name': 'Alex'}));
    performMicrotaskCheckpoint();
    assertNodesAre(div, ['Hi Alex', 'Hi Raf', 'Hi Erik', 'Hi Neal']);
  });

  observeTest('TwoLevelsDeepBug', () {
    var div = createTestHtml(
      '<template bind="{{}}"><span><span>{{ foo }}</span></span></template>');

    var model = toObservable({'foo': 'bar'});
    recursivelySetTemplateModel(div, model);
    performMicrotaskCheckpoint();

    expect(div.nodes[1].nodes[0].nodes[0].text, 'bar');
  });

  observeTest('Checked', () {
    var div = createTestHtml(
        '<template>'
          '<input type="checkbox" checked="{{a}}">'
        '</template>');
    var t = div.nodes.first;
    var m = toObservable({
      'a': true
    });
    nodeBind(t).bind('bind', m, '');
    performMicrotaskCheckpoint();

    var instanceInput = t.nextNode;
    expect(instanceInput.checked, true);

    instanceInput.click();
    expect(instanceInput.checked, false);

    instanceInput.click();
    expect(instanceInput.checked, true);
  });

  nestedHelper(s, start) {
    var div = createTestHtml(s);

    var m = toObservable({
      'a': {
        'b': 1,
        'c': {'d': 2}
      },
    });

    recursivelySetTemplateModel(div, m);
    performMicrotaskCheckpoint();

    var i = start;
    expect(div.nodes[i++].text, '1');
    expect(div.nodes[i++].tagName, 'TEMPLATE');
    expect(div.nodes[i++].text, '2');

    m['a']['b'] = 11;
    performMicrotaskCheckpoint();
    expect(div.nodes[start].text, '11');

    m['a']['c'] = toObservable({'d': 22});
    performMicrotaskCheckpoint();
    expect(div.nodes[start + 2].text, '22');
  }

  observeTest('Nested', () {
    nestedHelper(
        '<template bind="{{a}}">'
          '{{b}}'
          '<template bind="{{c}}">'
            '{{d}}'
          '</template>'
        '</template>', 1);
  });

  observeTest('NestedWithRef', () {
    nestedHelper(
        '<template id="inner">{{d}}</template>'
        '<template id="outer" bind="{{a}}">'
          '{{b}}'
          '<template ref="inner" bind="{{c}}"></template>'
        '</template>', 2);
  });

  nestedIterateInstantiateHelper(s, start) {
    var div = createTestHtml(s);

    var m = toObservable({
      'a': [
        {
          'b': 1,
          'c': {'d': 11}
        },
        {
          'b': 2,
          'c': {'d': 22}
        }
      ]
    });

    recursivelySetTemplateModel(div, m);
    performMicrotaskCheckpoint();

    var i = start;
    expect(div.nodes[i++].text, '1');
    expect(div.nodes[i++].tagName, 'TEMPLATE');
    expect(div.nodes[i++].text, '11');
    expect(div.nodes[i++].text, '2');
    expect(div.nodes[i++].tagName, 'TEMPLATE');
    expect(div.nodes[i++].text, '22');

    m['a'][1] = toObservable({
      'b': 3,
      'c': {'d': 33}
    });

    performMicrotaskCheckpoint();
    expect(div.nodes[start + 3].text, '3');
    expect(div.nodes[start + 5].text, '33');
  }

  observeTest('NestedRepeatBind', () {
    nestedIterateInstantiateHelper(
        '<template repeat="{{a}}">'
          '{{b}}'
          '<template bind="{{c}}">'
            '{{d}}'
          '</template>'
        '</template>', 1);
  });

  observeTest('NestedRepeatBindWithRef', () {
    nestedIterateInstantiateHelper(
        '<template id="inner">'
          '{{d}}'
        '</template>'
        '<template repeat="{{a}}">'
          '{{b}}'
          '<template ref="inner" bind="{{c}}"></template>'
        '</template>', 2);
  });

  nestedIterateIterateHelper(s, start) {
    var div = createTestHtml(s);

    var m = toObservable({
      'a': [
        {
          'b': 1,
          'c': [{'d': 11}, {'d': 12}]
        },
        {
          'b': 2,
          'c': [{'d': 21}, {'d': 22}]
        }
      ]
    });

    recursivelySetTemplateModel(div, m);
    performMicrotaskCheckpoint();

    var i = start;
    expect(div.nodes[i++].text, '1');
    expect(div.nodes[i++].tagName, 'TEMPLATE');
    expect(div.nodes[i++].text, '11');
    expect(div.nodes[i++].text, '12');
    expect(div.nodes[i++].text, '2');
    expect(div.nodes[i++].tagName, 'TEMPLATE');
    expect(div.nodes[i++].text, '21');
    expect(div.nodes[i++].text, '22');

    m['a'][1] = toObservable({
      'b': 3,
      'c': [{'d': 31}, {'d': 32}, {'d': 33}]
    });

    i = start + 4;
    performMicrotaskCheckpoint();
    expect(div.nodes[start + 4].text, '3');
    expect(div.nodes[start + 6].text, '31');
    expect(div.nodes[start + 7].text, '32');
    expect(div.nodes[start + 8].text, '33');
  }

  observeTest('NestedRepeatBind', () {
    nestedIterateIterateHelper(
        '<template repeat="{{a}}">'
          '{{b}}'
          '<template repeat="{{c}}">'
            '{{d}}'
          '</template>'
        '</template>', 1);
  });

  observeTest('NestedRepeatRepeatWithRef', () {
    nestedIterateIterateHelper(
        '<template id="inner">'
          '{{d}}'
        '</template>'
        '<template repeat="{{a}}">'
          '{{b}}'
          '<template ref="inner" repeat="{{c}}"></template>'
        '</template>', 2);
  });

  observeTest('NestedRepeatSelfRef', () {
    var div = createTestHtml(
        '<template id="t" repeat="{{}}">'
          '{{name}}'
          '<template ref="t" repeat="{{items}}"></template>'
        '</template>');

    var m = toObservable([
      {
        'name': 'Item 1',
        'items': [
          {
            'name': 'Item 1.1',
            'items': [
              {
                 'name': 'Item 1.1.1',
                 'items': []
              }
            ]
          },
          {
            'name': 'Item 1.2'
          }
        ]
      },
      {
        'name': 'Item 2',
        'items': []
      },
    ]);

    recursivelySetTemplateModel(div, m);
    performMicrotaskCheckpoint();

    var i = 1;
    expect(div.nodes[i++].text, 'Item 1');
    expect(div.nodes[i++].tagName, 'TEMPLATE');
    expect(div.nodes[i++].text, 'Item 1.1');
    expect(div.nodes[i++].tagName, 'TEMPLATE');
    expect(div.nodes[i++].text, 'Item 1.1.1');
    expect(div.nodes[i++].tagName, 'TEMPLATE');
    expect(div.nodes[i++].text, 'Item 1.2');
    expect(div.nodes[i++].tagName, 'TEMPLATE');
    expect(div.nodes[i++].text, 'Item 2');

    m[0] = toObservable({'name': 'Item 1 changed'});

    i = 1;
    performMicrotaskCheckpoint();
    expect(div.nodes[i++].text, 'Item 1 changed');
    expect(div.nodes[i++].tagName, 'TEMPLATE');
    expect(div.nodes[i++].text, 'Item 2');
  });

  observeTest('Attribute Template Option/Optgroup', () {
    var div = createTestHtml(
        '<template bind>'
          '<select selectedIndex="{{ selected }}">'
            '<optgroup template repeat="{{ groups }}" label="{{ name }}">'
              '<option template repeat="{{ items }}">{{ val }}</option>'
            '</optgroup>'
          '</select>'
        '</template>');

    var m = toObservable({
      'selected': 1,
      'groups': [{
        'name': 'one', 'items': [{ 'val': 0 }, { 'val': 1 }]
      }],
    });

    recursivelySetTemplateModel(div, m);
    performMicrotaskCheckpoint();

    var select = div.nodes[0].nextNode;
    expect(select.nodes.length, 2);

    scheduleMicrotask(expectAsync0(() {
      scheduleMicrotask(expectAsync0(() {
        // TODO(jmesserly): this should be called sooner.
        expect(select.selectedIndex, 1);
      }));
    }));
    expect(select.nodes[0].tagName, 'TEMPLATE');
    expect((templateBind(templateBind(select.nodes[0]).ref)
        .content.nodes[0] as Element).tagName, 'OPTGROUP');

    var optgroup = select.nodes[1];
    expect(optgroup.nodes[0].tagName, 'TEMPLATE');
    expect(optgroup.nodes[1].tagName, 'OPTION');
    expect(optgroup.nodes[1].text, '0');
    expect(optgroup.nodes[2].tagName, 'OPTION');
    expect(optgroup.nodes[2].text, '1');
  });

  observeTest('NestedIterateTableMixedSemanticNative', () {
    if (!parserHasNativeTemplate) return;

    var div = createTestHtml(
        '<table><tbody>'
          '<template repeat="{{}}">'
            '<tr>'
              '<td template repeat="{{}}" class="{{ val }}">{{ val }}</td>'
            '</tr>'
          '</template>'
        '</tbody></table>');

    var m = toObservable([
      [{ 'val': 0 }, { 'val': 1 }],
      [{ 'val': 2 }, { 'val': 3 }]
    ]);

    recursivelySetTemplateModel(div, m);
    performMicrotaskCheckpoint();

    var tbody = div.nodes[0].nodes[0];

    // 1 for the <tr template>, 2 * (1 tr)
    expect(tbody.nodes.length, 3);

    // 1 for the <td template>, 2 * (1 td)
    expect(tbody.nodes[1].nodes.length, 3);

    expect(tbody.nodes[1].nodes[1].text, '0');
    expect(tbody.nodes[1].nodes[2].text, '1');

    // 1 for the <td template>, 2 * (1 td)
    expect(tbody.nodes[2].nodes.length, 3);
    expect(tbody.nodes[2].nodes[1].text, '2');
    expect(tbody.nodes[2].nodes[2].text, '3');

    // Asset the 'class' binding is retained on the semantic template (just
    // check the last one).
    expect(tbody.nodes[2].nodes[2].attributes["class"], '3');
  });

  observeTest('NestedIterateTable', () {
    var div = createTestHtml(
        '<table><tbody>'
          '<tr template repeat="{{}}">'
            '<td template repeat="{{}}" class="{{ val }}">{{ val }}</td>'
          '</tr>'
        '</tbody></table>');

    var m = toObservable([
      [{ 'val': 0 }, { 'val': 1 }],
      [{ 'val': 2 }, { 'val': 3 }]
    ]);

    recursivelySetTemplateModel(div, m);
    performMicrotaskCheckpoint();

    var i = 1;
    var tbody = div.nodes[0].nodes[0];

    // 1 for the <tr template>, 2 * (1 tr)
    expect(tbody.nodes.length, 3);

    // 1 for the <td template>, 2 * (1 td)
    expect(tbody.nodes[1].nodes.length, 3);
    expect(tbody.nodes[1].nodes[1].text, '0');
    expect(tbody.nodes[1].nodes[2].text, '1');

    // 1 for the <td template>, 2 * (1 td)
    expect(tbody.nodes[2].nodes.length, 3);
    expect(tbody.nodes[2].nodes[1].text, '2');
    expect(tbody.nodes[2].nodes[2].text, '3');

    // Asset the 'class' binding is retained on the semantic template (just
    // check the last one).
    expect(tbody.nodes[2].nodes[2].attributes['class'], '3');
  });

  observeTest('NestedRepeatDeletionOfMultipleSubTemplates', () {
    var div = createTestHtml(
        '<ul>'
          '<template repeat="{{}}" id=t1>'
            '<li>{{name}}'
              '<ul>'
                '<template ref=t1 repaet="{{items}}"></template>'
              '</ul>'
            '</li>'
          '</template>'
        '</ul>');

    var m = toObservable([
      {
        'name': 'Item 1',
        'items': [
          {
            'name': 'Item 1.1'
          }
        ]
      }
    ]);

    recursivelySetTemplateModel(div, m);

    performMicrotaskCheckpoint();
    m.removeAt(0);
    performMicrotaskCheckpoint();
  });

  observeTest('DeepNested', () {
    var div = createTestHtml(
      '<template bind="{{a}}">'
        '<p>'
          '<template bind="{{b}}">'
            '{{ c }}'
          '</template>'
        '</p>'
      '</template>');

    var m = toObservable({
      'a': {
        'b': {
          'c': 42
        }
      }
    });
    recursivelySetTemplateModel(div, m);
    performMicrotaskCheckpoint();

    expect(div.nodes[1].tagName, 'P');
    expect(div.nodes[1].nodes.first.tagName, 'TEMPLATE');
    expect(div.nodes[1].nodes[1].text, '42');
  });

  observeTest('TemplateContentRemoved', () {
    var div = createTestHtml('<template bind="{{}}">{{ }}</template>');
    var model = 42;

    recursivelySetTemplateModel(div, model);
    performMicrotaskCheckpoint();
    expect(div.nodes[1].text, '42');
    expect(div.nodes[0].text, '');
  });

  observeTest('TemplateContentRemovedEmptyArray', () {
    var div = createTestHtml('<template iterate>Remove me</template>');
    var model = toObservable([]);

    recursivelySetTemplateModel(div, model);
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 1);
    expect(div.nodes[0].text, '');
  });

  observeTest('TemplateContentRemovedNested', () {
    var div = createTestHtml(
        '<template bind="{{}}">'
          '{{ a }}'
          '<template bind="{{}}">'
            '{{ b }}'
          '</template>'
        '</template>');

    var model = toObservable({
      'a': 1,
      'b': 2
    });
    recursivelySetTemplateModel(div, model);
    performMicrotaskCheckpoint();

    expect(div.nodes[0].text, '');
    expect(div.nodes[1].text, '1');
    expect(div.nodes[2].text, '');
    expect(div.nodes[3].text, '2');
  });

  observeTest('BindWithUndefinedModel', () {
    var div = createTestHtml(
        '<template bind="{{}}" if="{{}}">{{ a }}</template>');

    var model = toObservable({'a': 42});
    recursivelySetTemplateModel(div, model);
    performMicrotaskCheckpoint();
    expect(div.nodes[1].text, '42');

    model = null;
    recursivelySetTemplateModel(div, model);
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 1);

    model = toObservable({'a': 42});
    recursivelySetTemplateModel(div, model);
    performMicrotaskCheckpoint();
    expect(div.nodes[1].text, '42');
  });

  observeTest('BindNested', () {
    var div = createTestHtml(
        '<template bind="{{}}">'
          'Name: {{ name }}'
          '<template bind="{{wife}}" if="{{wife}}">'
            'Wife: {{ name }}'
          '</template>'
          '<template bind="{{child}}" if="{{child}}">'
            'Child: {{ name }}'
          '</template>'
        '</template>');

    var m = toObservable({
      'name': 'Hermes',
      'wife': {
        'name': 'LaBarbara'
      }
    });
    recursivelySetTemplateModel(div, m);
    performMicrotaskCheckpoint();

    expect(div.nodes.length, 5);
    expect(div.nodes[1].text, 'Name: Hermes');
    expect(div.nodes[3].text, 'Wife: LaBarbara');

    m['child'] = toObservable({'name': 'Dwight'});
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 6);
    expect(div.nodes[5].text, 'Child: Dwight');

    m.remove('wife');
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 5);
    expect(div.nodes[4].text, 'Child: Dwight');
  });

  observeTest('BindRecursive', () {
    var div = createTestHtml(
        '<template bind="{{}}" if="{{}}" id="t">'
          'Name: {{ name }}'
          '<template bind="{{friend}}" if="{{friend}}" ref="t"></template>'
        '</template>');

    var m = toObservable({
      'name': 'Fry',
      'friend': {
        'name': 'Bender'
      }
    });
    recursivelySetTemplateModel(div, m);
    performMicrotaskCheckpoint();

    expect(div.nodes.length, 5);
    expect(div.nodes[1].text, 'Name: Fry');
    expect(div.nodes[3].text, 'Name: Bender');

    m['friend']['friend'] = toObservable({'name': 'Leela'});
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 7);
    expect(div.nodes[5].text, 'Name: Leela');

    m['friend'] = toObservable({'name': 'Leela'});
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 5);
    expect(div.nodes[3].text, 'Name: Leela');
  });

  observeTest('Template - Self is terminator', () {
    var div = createTestHtml(
        '<template repeat>{{ foo }}'
          '<template bind></template>'
        '</template>');

    var m = toObservable([{ 'foo': 'bar' }]);
    recursivelySetTemplateModel(div, m);
    performMicrotaskCheckpoint();

    m.add(toObservable({ 'foo': 'baz' }));
    recursivelySetTemplateModel(div, m);
    performMicrotaskCheckpoint();

    expect(div.nodes.length, 5);
    expect(div.nodes[1].text, 'bar');
    expect(div.nodes[3].text, 'baz');
  });

  observeTest('Template - Same Contents, Different Array has no effect', () {
    if (!MutationObserver.supported) return;

    var div = createTestHtml('<template repeat>{{ foo }}</template>');

    var m = toObservable([{ 'foo': 'bar' }, { 'foo': 'bat'}]);
    recursivelySetTemplateModel(div, m);
    performMicrotaskCheckpoint();

    var observer = new MutationObserver((records, _) {});
    observer.observe(div, childList: true);

    var template = div.firstChild;
    nodeBind(template).bind('repeat', toObservable(m.toList()), '');
    performMicrotaskCheckpoint();
    var records = observer.takeRecords();
    expect(records.length, 0);
  });

  observeTest('RecursiveRef', () {
    var div = createTestHtml(
        '<template bind>'
          '<template id=src>{{ foo }}</template>'
          '<template bind ref=src></template>'
        '</template>');

    var m = toObservable({'foo': 'bar'});
    recursivelySetTemplateModel(div, m);
    performMicrotaskCheckpoint();

    expect(div.nodes.length, 4);
    expect(div.nodes[3].text, 'bar');
  });

  observeTest('ChangeFromBindToRepeat', () {
    var div = createTestHtml(
        '<template bind="{{a}}">'
          '{{ length }}'
        '</template>');
    var template = div.nodes.first;

    // Note: this test data is a little different from the JS version, because
    // we allow binding to the "length" field of the Map in preference to
    // binding keys.
    var m = toObservable({
      'a': [
        [],
        { 'b': [1,2,3,4] },
        // Note: this will use the Map "length" property, not the "length" key.
        {'length': 42, 'c': 123}
      ]
    });
    recursivelySetTemplateModel(div, m);
    performMicrotaskCheckpoint();

    expect(div.nodes.length, 2);
    expect(div.nodes[1].text, '3');

    nodeBind(template)
        ..unbind('bind')
        ..bind('repeat', m, 'a');
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 4);
    expect(div.nodes[1].text, '0');
    expect(div.nodes[2].text, '1');
    expect(div.nodes[3].text, '2');

    nodeBind(template).unbind('repeat');
    nodeBind(template).bind('bind', m, 'a.1.b');

    performMicrotaskCheckpoint();
    expect(div.nodes.length, 2);
    expect(div.nodes[1].text, '4');
  });

  observeTest('ChangeRefId', () {
    var div = createTestHtml(
        '<template id="a">a:{{ }}</template>'
        '<template id="b">b:{{ }}</template>'
        '<template repeat="{{}}">'
          '<template ref="a" bind="{{}}"></template>'
        '</template>');
    var model = toObservable([]);
    recursivelySetTemplateModel(div, model);
    performMicrotaskCheckpoint();

    expect(div.nodes.length, 3);

    document.getElementById('a').id = 'old-a';
    document.getElementById('b').id = 'a';

    model..add(1)..add(2);
    performMicrotaskCheckpoint();

    expect(div.nodes.length, 7);
    expect(div.nodes[4].text, 'b:1');
    expect(div.nodes[6].text, 'b:2');
  });

  observeTest('Content', () {
    var div = createTestHtml(
        '<template><a></a></template>'
        '<template><b></b></template>');
    var templateA = div.nodes.first;
    var templateB = div.nodes.last;
    var contentA = templateBind(templateA).content;
    var contentB = templateBind(templateB).content;
    expect(contentA, isNotNull);

    expect(templateA.ownerDocument, isNot(equals(contentA.ownerDocument)));
    expect(templateB.ownerDocument, isNot(equals(contentB.ownerDocument)));

    expect(templateB.ownerDocument, templateA.ownerDocument);
    expect(contentB.ownerDocument, contentA.ownerDocument);

    expect(templateA.ownerDocument.window, window);
    expect(templateB.ownerDocument.window, window);

    expect(contentA.ownerDocument.window, null);
    expect(contentB.ownerDocument.window, null);

    expect(contentA.nodes.last, contentA.nodes.first);
    expect(contentA.nodes.first.tagName, 'A');

    expect(contentB.nodes.last, contentB.nodes.first);
    expect(contentB.nodes.first.tagName, 'B');
  });

  observeTest('NestedContent', () {
    var div = createTestHtml(
        '<template>'
        '<template></template>'
        '</template>');
    var templateA = div.nodes.first;
    var templateB = templateBind(templateA).content.nodes.first;

    expect(templateB.ownerDocument, templateBind(templateA)
        .content.ownerDocument);
    expect(templateBind(templateB).content.ownerDocument,
        templateBind(templateA).content.ownerDocument);
  });

  observeTest('BindShadowDOM', () {
    if (ShadowRoot.supported) {
      var root = createShadowTestHtml(
          '<template bind="{{}}">Hi {{ name }}</template>');
      var model = toObservable({'name': 'Leela'});
      recursivelySetTemplateModel(root, model);
      performMicrotaskCheckpoint();
      expect(root.nodes[1].text, 'Hi Leela');
    }
  });

  // Dart note: this test seems gone from JS. Keeping for posterity sake.
  observeTest('BindShadowDOM createInstance', () {
    if (ShadowRoot.supported) {
      var model = toObservable({'name': 'Leela'});
      var template = new Element.html('<template>Hi {{ name }}</template>');
      var root = createShadowTestHtml('');
      root.nodes.add(templateBind(template).createInstance(model));

      performMicrotaskCheckpoint();
      expect(root.text, 'Hi Leela');

      model['name'] = 'Fry';
      performMicrotaskCheckpoint();
      expect(root.text, 'Hi Fry');
    }
  });

  observeTest('BindShadowDOM Template Ref', () {
    if (ShadowRoot.supported) {
      var root = createShadowTestHtml(
          '<template id=foo>Hi</template><template bind ref=foo></template>');
      recursivelySetTemplateModel(root, toObservable({}));
      performMicrotaskCheckpoint();
      expect(root.nodes.length, 3);
    }
  });

  // https://github.com/toolkitchen/mdv/issues/8
  observeTest('UnbindingInNestedBind', () {
    var div = createTestHtml(
      '<template bind="{{outer}}" if="{{outer}}" syntax="testHelper">'
        '<template bind="{{inner}}" if="{{inner}}">'
          '{{ age }}'
        '</template>'
      '</template>');

    var syntax = new UnbindingInNestedBindSyntax();
    var model = toObservable({
      'outer': {
        'inner': {
          'age': 42
        }
      }
    });

    recursivelySetTemplateModel(div, model, syntax);

    performMicrotaskCheckpoint();
    expect(syntax.count, 1);

    var inner = model['outer']['inner'];
    model['outer'] = null;

    performMicrotaskCheckpoint();
    expect(syntax.count, 1);

    model['outer'] = toObservable({'inner': {'age': 2}});
    syntax.expectedAge = 2;

    performMicrotaskCheckpoint();
    expect(syntax.count, 2);
  });

  // https://github.com/toolkitchen/mdv/issues/8
  observeTest('DontCreateInstancesForAbandonedIterators', () {
    var div = createTestHtml(
      '<template bind="{{}} {{}}">'
        '<template bind="{{}}">Foo'
        '</template>'
      '</template>');
    recursivelySetTemplateModel(div, null);
    performMicrotaskCheckpoint();
  });

  observeTest('CreateInstance', () {
    var div = createTestHtml(
      '<template bind="{{a}}">'
        '<template bind="{{b}}">'
          '{{ foo }}:{{ replaceme }}'
        '</template>'
      '</template>');
    var outer = templateBind(div.nodes.first);
    var model = toObservable({'b': {'foo': 'bar'}});

    var host = new DivElement();
    var instance = outer.createInstance(model, new TestBindingSyntax());
    expect(outer.content.nodes.first,
        templateBind(instance.nodes.first).ref);

    host.append(instance);
    performMicrotaskCheckpoint();
    expect(host.firstChild.nextNode.text, 'bar:replaced');
  });

  observeTest('Bootstrap', () {
    var div = new DivElement();
    div.innerHtml =
      '<template>'
        '<div></div>'
        '<template>'
          'Hello'
        '</template>'
      '</template>';

    TemplateBindExtension.bootstrap(div);
    var template = templateBind(div.nodes.first);
    expect(template.content.nodes.length, 2);
    var template2 = templateBind(template.content.nodes.first.nextNode);
    expect(template2.content.nodes.length, 1);
    expect(template2.content.nodes.first.text, 'Hello');

    template = new Element.tag('template');
    template.innerHtml =
      '<template>'
        '<div></div>'
        '<template>'
          'Hello'
        '</template>'
      '</template>';

    TemplateBindExtension.bootstrap(template);
    template2 = templateBind(templateBind(template).content.nodes.first);
    expect(template2.content.nodes.length, 2);
    var template3 = templateBind(template2.content.nodes.first.nextNode);
    expect(template3.content.nodes.length, 1);
    expect(template3.content.nodes.first.text, 'Hello');
  });

  observeTest('issue-285', () {
    var div = createTestHtml(
        '<template>'
          '<template bind if="{{show}}">'
            '<template id=del repeat="{{items}}">'
              '{{}}'
            '</template>'
          '</template>'
        '</template>');

    var template = div.firstChild;

    var model = toObservable({
      'show': true,
      'items': [1]
    });

    div.append(templateBind(template).createInstance(model,
        new Issue285Syntax()));

    performMicrotaskCheckpoint();
    expect(template.nextNode.nextNode.nextNode.text, '2');
    model['show'] = false;
    performMicrotaskCheckpoint();
    model['show'] = true;
    performMicrotaskCheckpoint();
    expect(template.nextNode.nextNode.nextNode.text, '2');
  });

  observeTest('issue-141', () {
    var div = createTestHtml(
        '<template bind>' +
          '<div foo="{{foo1}} {{foo2}}" bar="{{bar}}"></div>' +
        '</template>');

    var model = toObservable({
      'foo1': 'foo1Value',
      'foo2': 'foo2Value',
      'bar': 'barValue'
    });

    recursivelySetTemplateModel(div, model);
    performMicrotaskCheckpoint();

    expect(div.lastChild.attributes['bar'], 'barValue');
  });
}

compatTests() {
  observeTest('underbar bindings', () {
    var div = createTestHtml(
        '<template bind>'
          '<div _style="color: {{ color }};"></div>'
          '<img _src="{{ url }}">'
          '<a _href="{{ url2 }}">Link</a>'
          '<input type="number" _value="{{ number }}">'
        '</template>');

    var model = toObservable({
      'color': 'red',
      'url': 'pic.jpg',
      'url2': 'link.html',
      'number': 4
    });

    recursivelySetTemplateModel(div, model);
    performMicrotaskCheckpoint();

    var subDiv = div.firstChild.nextNode;
    expect(subDiv.attributes['style'], 'color: red;');

    var img = subDiv.nextNode;
    expect(img.attributes['src'], 'pic.jpg');

    var a = img.nextNode;
    expect(a.attributes['href'], 'link.html');

    var input = a.nextNode;
    expect(input.value, '4');
  });
}

class Issue285Syntax extends BindingDelegate {
  prepareInstanceModel(template) {
    if (template.id == 'del') return (val) => val * 2;
  }
}

class TestBindingSyntax extends BindingDelegate {
  prepareBinding(String path, name, node) {
    if (path.trim() == 'replaceme') {
      return (x, y) => new ObservableBox('replaced');
    }
    return null;
  }
}

class UnbindingInNestedBindSyntax extends BindingDelegate {
  int expectedAge = 42;
  int count = 0;

  prepareBinding(path, name, node) {
    if (name != 'text' || path != 'age') return null;

    return (model, node) {
      expect(model['age'], expectedAge);
      count++;
      return model;
    };
  }
}
