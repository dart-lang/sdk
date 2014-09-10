// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library template_binding.test.template_binding_test;

import 'dart:async';
import 'dart:html';
import 'dart:js' show JsObject;
import 'dart:math' as math;
import 'package:observe/observe.dart';
import 'package:template_binding/template_binding.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';

// TODO(jmesserly): merge this file?
import 'binding_syntax.dart' show syntaxTests;
import 'utils.dart';

// Note: this file ported from TemplateBinding's tests/tests.js

// TODO(jmesserly): submit a small cleanup patch to original. I fixed some
// cases where "div" and "t" were unintentionally using the JS global scope;
// look for "assertNodesAre".

main() => dirtyCheckZone().run(() {
  useHtmlConfiguration();

  // Load MutationObserver polyfill in case IE needs it.
  var script = new ScriptElement()
      ..src = '/root_dart/pkg/mutation_observer/lib/mutation_observer.min.js';
  var polyfillLoaded = script.onLoad.first;
  document.head.append(script);

  setUp(() => polyfillLoaded.then((_) {
    document.body.append(testDiv = new DivElement());
  }));

  tearDown(() {
    testDiv.remove();
    clearAllTemplates(testDiv);
    testDiv = null;
  });

  test('MutationObserver is supported', () {
    expect(MutationObserver.supported, true, reason: 'polyfill was loaded.');
  });

  group('Template', templateInstantiationTests);

  group('Binding Delegate API', () {
    group('with Observable', () {
      syntaxTests(([f, b]) => new FooBarModel(f, b));
    });

    group('with ChangeNotifier', () {
      syntaxTests(([f, b]) => new FooBarNotifyModel(f, b));
    });
  });

  group('Compat', compatTests);
});

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
  // Dart note: renamed some of these tests to have unique names

  test('accessing bindingDelegate getter without Bind', () {
    var div = createTestHtml('<template>');
    var template = div.firstChild;
    expect(templateBind(template).bindingDelegate, null);
  });

  test('Bind - simple', () {
    var div = createTestHtml('<template bind={{}}>text</template>');
    templateBind(div.firstChild).model = {};
    return new Future(() {
      expect(div.nodes.length, 2);
      expect(div.nodes.last.text, 'text');

      // Dart note: null is used instead of undefined to clear the template.
      templateBind(div.firstChild).model = null;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1);
      templateBind(div.firstChild).model = 123;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.nodes.last.text, 'text');
    });
  });

  test('oneTime-Bind', () {
    var div = createTestHtml('<template bind="[[ bound ]]">text</template>');
    var model = toObservable({'bound': 1});
    templateBind(div.firstChild).model = model;
    return new Future(() {
      expect(div.nodes.length, 2);
      expect(div.nodes.last.text, 'text');

      model['bound'] = false;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.nodes.last.text, 'text');
    });
  });

  test('Bind - no parent', () {
    var div = createTestHtml('<template bind>text</template>');
    var template = div.firstChild;
    template.remove();

    templateBind(template).model = {};
    return new Future(() {
      expect(template.nodes.length, 0);
      expect(template.nextNode, null);
    });
  });

  test('Bind - no defaultView', () {
    var div = createTestHtml('<template bind>text</template>');
    var template = div.firstChild;
    var doc = document.implementation.createHtmlDocument('');
    doc.adoptNode(div);
    templateBind(template).model = {};
    return new Future(() => expect(div.nodes.length, 2));
  });

  test('Empty Bind', () {
    var div = createTestHtml('<template bind>text</template>');
    var template = div.firstChild;
    templateBind(template).model = {};
    return new Future(() {
      expect(div.nodes.length, 2);
      expect(div.nodes.last.text, 'text');
    });
  });

  test('Bind If', () {
    var div = createTestHtml(
        '<template bind="{{ bound }}" if="{{ predicate }}">'
          'value:{{ value }}'
        '</template>');
    // Dart note: predicate changed from 0->null because 0 isn't falsey in Dart.
    // See https://code.google.com/p/dart/issues/detail?id=11956
    // Changed bound from null->1 since null is equivalent to JS undefined,
    // and would cause the template to not be expanded.
    var m = toObservable({ 'predicate': null, 'bound': 1 });
    var template = div.firstChild;
    bool errorSeen = false;
    runZoned(() {
      templateBind(template).model = m;
    }, onError: (e, s) {
      _expectNoSuchMethod(e);
      errorSeen = true;
    });
    return new Future(() {
      expect(div.nodes.length, 1);

      m['predicate'] = 1;

      expect(errorSeen, isFalse);
    }).then(nextMicrotask).then((_) {
      expect(errorSeen, isTrue);
      expect(div.nodes.length, 1);

      m['bound'] = toObservable({ 'value': 2 });

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'value:2');

      m['bound']['value'] = 3;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'value:3');

      templateBind(template).model = null;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1);
    });
  });

  test('Bind oneTime-If - predicate false', () {
    var div = createTestHtml(
        '<template bind="{{ bound }}" if="[[ predicate ]]">'
          'value:{{ value }}'
        '</template>');
    // Dart note: predicate changed from 0->null because 0 isn't falsey in Dart.
    // See https://code.google.com/p/dart/issues/detail?id=11956
    // Changed bound from null->1 since null is equivalent to JS undefined,
    // and would cause the template to not be expanded.
    var m = toObservable({ 'predicate': null, 'bound': 1 });
    var template = div.firstChild;
    templateBind(template).model = m;

    return new Future(() {
      expect(div.nodes.length, 1);

      m['predicate'] = 1;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1);

      m['bound'] = toObservable({ 'value': 2 });

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1);

      m['bound']['value'] = 3;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1);

      templateBind(template).model = null;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1);
    });
  });

  test('Bind oneTime-If - predicate true', () {
    var div = createTestHtml(
        '<template bind="{{ bound }}" if="[[ predicate ]]">'
          'value:{{ value }}'
        '</template>');

    // Dart note: changed bound from null->1 since null is equivalent to JS
    // undefined, and would cause the template to not be expanded.
    var m = toObservable({ 'predicate': 1, 'bound': 1 });
    var template = div.firstChild;
    bool errorSeen = false;
    runZoned(() {
      templateBind(template).model = m;
    }, onError: (e, s) {
      _expectNoSuchMethod(e);
      errorSeen = true;
    });

    return new Future(() {
      expect(div.nodes.length, 1);
      m['bound'] = toObservable({ 'value': 2 });
      expect(errorSeen, isTrue);
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'value:2');

      m['bound']['value'] = 3;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'value:3');

      m['predicate'] = null; // will have no effect

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'value:3');

      templateBind(template).model = null;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1);
    });
  });

  test('oneTime-Bind If', () {
    var div = createTestHtml(
        '<template bind="[[ bound ]]" if="{{ predicate }}">'
          'value:{{ value }}'
        '</template>');

    var m = toObservable({'predicate': null, 'bound': {'value': 2}});
    var template = div.firstChild;
    templateBind(template).model = m;

    return new Future(() {
      expect(div.nodes.length, 1);

      m['predicate'] = 1;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'value:2');

      m['bound']['value'] = 3;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'value:3');

      m['bound'] = toObservable({'value': 4 });

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'value:3');

      templateBind(template).model = null;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1);
    });
  });

  test('oneTime-Bind oneTime-If', () {
    var div = createTestHtml(
        '<template bind="[[ bound ]]" if="[[ predicate ]]">'
          'value:{{ value }}'
        '</template>');

    var m = toObservable({'predicate': 1, 'bound': {'value': 2}});
    var template = div.firstChild;
    templateBind(template).model = m;

    return new Future(() {
      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'value:2');

      m['bound']['value'] = 3;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'value:3');

      m['bound'] = toObservable({'value': 4 });

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'value:3');

      m['predicate'] = false;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'value:3');

      templateBind(template).model = null;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1);
    });
  });

  test('Bind If, 2', () {
    var div = createTestHtml(
        '<template bind="{{ foo }}" if="{{ bar }}">{{ bat }}</template>');
    var template = div.firstChild;
    var m = toObservable({ 'bar': null, 'foo': { 'bat': 'baz' } });
    templateBind(template).model = m;
    return new Future(() {
      expect(div.nodes.length, 1);

      m['bar'] = 1;
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'baz');
    });
  });

  test('If', () {
    var div = createTestHtml('<template if="{{ foo }}">{{ value }}</template>');
    // Dart note: foo changed from 0->null because 0 isn't falsey in Dart.
    // See https://code.google.com/p/dart/issues/detail?id=11956
    var m = toObservable({ 'foo': null, 'value': 'foo' });
    var template = div.firstChild;
    templateBind(template).model = m;
    return new Future(() {
      expect(div.nodes.length, 1);

      m['foo'] = 1;
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'foo');

      templateBind(template).model = null;
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1);
    });
  });

  test('Bind If minimal discardChanges', () {
    var div = createTestHtml(
        '<template bind="{{bound}}" if="{{predicate}}">value:{{ value }}'
        '</template>');
    // Dart Note: bound changed from null->{}.
    var m = toObservable({ 'bound': {}, 'predicate': null });
    var template = div.firstChild;

    var discardChangesCalled = { 'bound': 0, 'predicate': 0 };
    templateBind(template)
        ..model = m
        ..bindingDelegate =
            new BindIfMinimalDiscardChanges(discardChangesCalled);

    return new Future(() {
      expect(discardChangesCalled['bound'], 0);
      expect(discardChangesCalled['predicate'], 0);
      expect(div.childNodes.length, 1);
      m['predicate'] = 1;
    }).then(endOfMicrotask).then((_) {
      expect(discardChangesCalled['bound'], 1);
      expect(discardChangesCalled['predicate'], 0);

      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'value:');

      m['bound'] = toObservable({'value': 2});
    }).then(endOfMicrotask).then((_) {
      expect(discardChangesCalled['bound'], 1);
      expect(discardChangesCalled['predicate'], 1);

      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'value:2');

      m['bound']['value'] = 3;

    }).then(endOfMicrotask).then((_) {
      expect(discardChangesCalled['bound'], 1);
      expect(discardChangesCalled['predicate'], 1);

      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'value:3');

      templateBind(template).model = null;
    }).then(endOfMicrotask).then((_) {
      expect(discardChangesCalled['bound'], 1);
      expect(discardChangesCalled['predicate'], 1);

      expect(div.nodes.length, 1);
    });
  });


  test('Empty-If', () {
    var div = createTestHtml('<template if>{{ value }}</template>');
    var template = div.firstChild;
    var m = toObservable({ 'value': 'foo' });
    templateBind(template).model = null;
    return new Future(() {
      expect(div.nodes.length, 1);

      templateBind(template).model = m;
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'foo');
    });
  });

  test('OneTime - simple text', () {
    var div = createTestHtml('<template bind>[[ value ]]</template>');
    var template = div.firstChild;
    var m = toObservable({ 'value': 'foo' });
    templateBind(template).model = m;
    return new Future(() {
      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'foo');

      m['value'] = 'bar';

    }).then(endOfMicrotask).then((_) {
      // unchanged.
      expect(div.lastChild.text, 'foo');
    });
  });

  test('OneTime - compound text', () {
    var div = createTestHtml(
        '<template bind>[[ foo ]] bar [[ baz ]]</template>');
    var template = div.firstChild;
    var m = toObservable({ 'foo': 'FOO', 'baz': 'BAZ' });
    templateBind(template).model = m;
    return new Future(() {
      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'FOO bar BAZ');

      m['foo'] = 'FI';
      m['baz'] = 'BA';

    }).then(endOfMicrotask).then((_) {
      // unchanged.
      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'FOO bar BAZ');
    });
  });

  test('OneTime/Dynamic Mixed - compound text', () {
    var div = createTestHtml(
        '<template bind>[[ foo ]] bar {{ baz }}</template>');
    var template = div.firstChild;
    var m = toObservable({ 'foo': 'FOO', 'baz': 'BAZ' });
    templateBind(template).model = m;
    return new Future(() {
      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'FOO bar BAZ');

      m['foo'] = 'FI';
      m['baz'] = 'BA';

    }).then(endOfMicrotask).then((_) {
      // unchanged [[ foo ]].
      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'FOO bar BA');
    });
  });

  test('OneTime - simple attribute', () {
    var div = createTestHtml(
        '<template bind><div foo="[[ value ]]"></div></template>');
    var template = div.firstChild;
    var m = toObservable({ 'value': 'foo' });
    templateBind(template).model = m;
    return new Future(() {
      expect(div.nodes.length, 2);
      expect(div.lastChild.attributes['foo'], 'foo');

      m['value'] = 'bar';

    }).then(endOfMicrotask).then((_) {
      // unchanged.
      expect(div.nodes.length, 2);
      expect(div.lastChild.attributes['foo'], 'foo');
    });
  });

  test('OneTime - compound attribute', () {
    var div = createTestHtml(
        '<template bind>'
          '<div foo="[[ value ]]:[[ otherValue ]]"></div>'
        '</template>');
    var template = div.firstChild;
    var m = toObservable({ 'value': 'foo', 'otherValue': 'bar' });
    templateBind(template).model = m;
    return new Future(() {
      expect(div.nodes.length, 2);
      expect(div.lastChild.attributes['foo'], 'foo:bar');

      m['value'] = 'baz';
      m['otherValue'] = 'bot';

    }).then(endOfMicrotask).then((_) {
      // unchanged.
      expect(div.lastChild.attributes['foo'], 'foo:bar');
    });
  });

  test('OneTime/Dynamic mixed - compound attribute', () {
    var div = createTestHtml(
        '<template bind>'
          '<div foo="{{ value }}:[[ otherValue ]]"></div>'
        '</template>');
    var template = div.firstChild;
    var m = toObservable({ 'value': 'foo', 'otherValue': 'bar' });
    templateBind(template).model = m;
    return new Future(() {
      expect(div.nodes.length, 2);
      expect(div.lastChild.attributes['foo'], 'foo:bar');

      m['value'] = 'baz';
      m['otherValue'] = 'bot';

    }).then(endOfMicrotask).then((_) {
      // unchanged [[ otherValue ]].
      expect(div.lastChild.attributes['foo'], 'baz:bar');
    });
  });

  test('Repeat If', () {
    var div = createTestHtml(
        '<template repeat="{{ items }}" if="{{ predicate }}">{{}}</template>');
    // Dart note: predicate changed from 0->null because 0 isn't falsey in Dart.
    // See https://code.google.com/p/dart/issues/detail?id=11956
    var m = toObservable({ 'predicate': null, 'items': [1] });
    var template = div.firstChild;
    templateBind(template).model = m;
    return new Future(() {
      expect(div.nodes.length, 1);

      m['predicate'] = 1;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.nodes[1].text, '1');

      m['items']..add(2)..add(3);

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 4);
      expect(div.nodes[1].text, '1');
      expect(div.nodes[2].text, '2');
      expect(div.nodes[3].text, '3');

      m['items'] = [4];

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.nodes[1].text, '4');

      templateBind(template).model = null;
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1);
    });
  });

  test('Repeat oneTime-If (predicate false)', () {
    var div = createTestHtml(
        '<template repeat="{{ items }}" if="[[ predicate ]]">{{}}</template>');
    // Dart note: predicate changed from 0->null because 0 isn't falsey in Dart.
    // See https://code.google.com/p/dart/issues/detail?id=11956
    var m = toObservable({ 'predicate': null, 'items': [1] });
    var template = div.firstChild;
    templateBind(template).model = m;
    return new Future(() {
      expect(div.nodes.length, 1);

      m['predicate'] = 1;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1, reason: 'unchanged');

      m['items']..add(2)..add(3);

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1, reason: 'unchanged');

      m['items'] = [4];

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1, reason: 'unchanged');

      templateBind(template).model = null;
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1);
    });
  });

  test('Repeat oneTime-If (predicate true)', () {
    var div = createTestHtml(
        '<template repeat="{{ items }}" if="[[ predicate ]]">{{}}</template>');

    var m = toObservable({ 'predicate': true, 'items': [1] });
    var template = div.firstChild;
    templateBind(template).model = m;
    return new Future(() {
      expect(div.nodes.length, 2);
      expect(div.nodes[1].text, '1');

      m['items']..add(2)..add(3);

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 4);
      expect(div.nodes[1].text, '1');
      expect(div.nodes[2].text, '2');
      expect(div.nodes[3].text, '3');

      m['items'] = [4];

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.nodes[1].text, '4');

      m['predicate'] = false;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2, reason: 'unchanged');
      expect(div.nodes[1].text, '4', reason: 'unchanged');

      templateBind(template).model = null;
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1);
    });
  });

  test('oneTime-Repeat If', () {
    var div = createTestHtml(
        '<template repeat="[[ items ]]" if="{{ predicate }}">{{}}</template>');

    var m = toObservable({ 'predicate': false, 'items': [1] });
    var template = div.firstChild;
    templateBind(template).model = m;
    return new Future(() {
      expect(div.nodes.length, 1);

      m['predicate'] = true;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.nodes[1].text, '1');

      m['items']..add(2)..add(3);

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.nodes[1].text, '1');

      m['items'] = [4];

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.nodes[1].text, '1');

      templateBind(template).model = null;
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1);
    });
  });

  test('oneTime-Repeat oneTime-If', () {
    var div = createTestHtml(
        '<template repeat="[[ items ]]" if="[[ predicate ]]">{{}}</template>');

    var m = toObservable({ 'predicate': true, 'items': [1] });
    var template = div.firstChild;
    templateBind(template).model = m;
    return new Future(() {
      expect(div.nodes.length, 2);
      expect(div.nodes[1].text, '1');

      m['items']..add(2)..add(3);

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.nodes[1].text, '1');

      m['items'] = [4];

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.nodes[1].text, '1');

      m['predicate'] = false;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.nodes[1].text, '1');

      templateBind(template).model = null;
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1);
    });
  });

  test('TextTemplateWithNullStringBinding', () {
    var div = createTestHtml('<template bind={{}}>a{{b}}c</template>');
    var template = div.firstChild;
    var model = toObservable({'b': 'B'});
    templateBind(template).model = model;

    return new Future(() {
      expect(div.nodes.length, 2);
      expect(div.nodes.last.text, 'aBc');

      model['b'] = 'b';
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.last.text, 'abc');

      model['b'] = null;
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.last.text, 'ac');

      model = null;
    }).then(endOfMicrotask).then((_) {
      // setting model isn't bindable.
      expect(div.nodes.last.text, 'ac');
    });
  });

  test('TextTemplateWithBindingPath', () {
    var div = createTestHtml(
        '<template bind="{{ data }}">a{{b}}c</template>');
    var model = toObservable({ 'data': {'b': 'B'} });
    var template = div.firstChild;
    templateBind(template).model = model;

    return new Future(() {
      expect(div.nodes.length, 2);
      expect(div.nodes.last.text, 'aBc');

      model['data']['b'] = 'b';
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.last.text, 'abc');

      model['data'] = toObservable({'b': 'X'});
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.last.text, 'aXc');

      // Dart note: changed from `null` since our null means don't render a model.
      model['data'] = toObservable({});
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.last.text, 'ac');

      model['data'] = null;
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1);
    });
  });

  test('TextTemplateWithBindingAndConditional', () {
    var div = createTestHtml(
        '<template bind="{{}}" if="{{ d }}">a{{b}}c</template>');
    var template = div.firstChild;
    var model = toObservable({'b': 'B', 'd': 1});
    templateBind(template).model = model;

    return new Future(() {
      expect(div.nodes.length, 2);
      expect(div.nodes.last.text, 'aBc');

      model['b'] = 'b';
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.last.text, 'abc');

      // TODO(jmesserly): MDV set this to empty string and relies on JS conversion
      // rules. Is that intended?
      // See https://github.com/Polymer/TemplateBinding/issues/59
      model['d'] = null;
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1);

      model['d'] = 'here';
      model['b'] = 'd';

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.nodes.last.text, 'adc');
    });
  });

  test('TemplateWithTextBinding2', () {
    var div = createTestHtml(
        '<template bind="{{ b }}">a{{value}}c</template>');
    expect(div.nodes.length, 1);
    var template = div.firstChild;
    var model = toObservable({'b': {'value': 'B'}});
    templateBind(template).model = model;

    return new Future(() {
      expect(div.nodes.length, 2);
      expect(div.nodes.last.text, 'aBc');

      model['b'] = toObservable({'value': 'b'});
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.last.text, 'abc');
    });
  });

  test('TemplateWithAttributeBinding', () {
    var div = createTestHtml(
        '<template bind="{{}}">'
        '<div foo="a{{b}}c"></div>'
        '</template>');
    var template = div.firstChild;
    var model = toObservable({'b': 'B'});
    templateBind(template).model = model;

    return new Future(() {
      expect(div.nodes.length, 2);
      expect(div.nodes.last.attributes['foo'], 'aBc');

      model['b'] = 'b';
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.last.attributes['foo'], 'abc');

      model['b'] = 'X';
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.last.attributes['foo'], 'aXc');
    });
  });

  test('TemplateWithConditionalBinding', () {
    var div = createTestHtml(
        '<template bind="{{}}">'
        '<div foo?="{{b}}"></div>'
        '</template>');
    var template = div.firstChild;
    var model = toObservable({'b': 'b'});
    templateBind(template).model = model;

    return new Future(() {
      expect(div.nodes.length, 2);
      expect(div.nodes.last.attributes['foo'], '');
      expect(div.nodes.last.attributes, isNot(contains('foo?')));

      model['b'] = null;
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.last.attributes, isNot(contains('foo')));
    });
  });

  test('Repeat', () {
    var div = createTestHtml(
        '<template repeat="{{ array }}">{{}},</template>');

    var model = toObservable({'array': [0, 1, 2]});
    var template = templateBind(div.firstChild);
    template.model = model;

    return new Future(() {
      expect(div.nodes.length, 4);
      expect(div.text, '0,1,2,');

      model['array'].length = 1;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);
      expect(div.text, '0,');

      model['array'].addAll([3, 4]);

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 4);
      expect(div.text, '0,3,4,');

      model['array'].removeRange(1, 2);

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 3);
      expect(div.text, '0,4,');

      model['array'].addAll([5, 6]);
      model['array'] = toObservable(['x', 'y']);

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 3);
      expect(div.text, 'x,y,');

      template.model = null;

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1);
      expect(div.text, '');
    });
  });

  test('Repeat - oneTime', () {
    var div = createTestHtml('<template repeat="[[]]">text</template>');

    var model = toObservable([0, 1, 2]);
    var template = templateBind(div.firstChild);
    template.model = model;

    return new Future(() {
      expect(div.nodes.length, 4);

      model.length = 1;
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 4);

      model.addAll([3, 4]);
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 4);

      model.removeRange(1, 2);
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 4);

      template.model = null;
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1);
    });
  });

  test('Repeat - Reuse Instances', () {
    var div = createTestHtml('<template repeat>{{ val }}</template>');

    var model = toObservable([
      {'val': 10},
      {'val': 5},
      {'val': 2},
      {'val': 8},
      {'val': 1}
    ]);
    var template = div.firstChild;
    templateBind(template).model = model;

    return new Future(() {
      expect(div.nodes.length, 6);

      addExpandos(template.nextNode);
      checkExpandos(template.nextNode);

      model.sort((a, b) => a['val'] - b['val']);
    }).then(endOfMicrotask).then((_) {
      checkExpandos(template.nextNode);

      model = toObservable(model.reversed);
      templateBind(template).model = model;
    }).then(endOfMicrotask).then((_) {
      checkExpandos(template.nextNode);

      for (var item in model) {
        item['val'] += 1;
      }

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes[1].text, "11");
      expect(div.nodes[2].text, "9");
      expect(div.nodes[3].text, "6");
      expect(div.nodes[4].text, "3");
      expect(div.nodes[5].text, "2");
    });
  });

  test('Bind - Reuse Instance', () {
    var div = createTestHtml(
        '<template bind="{{ foo }}">{{ bar }}</template>');

    var template = div.firstChild;
    var model = toObservable({ 'foo': { 'bar': 5 }});
    templateBind(template).model = model;

    return new Future(() {
      expect(div.nodes.length, 2);

      addExpandos(template.nextNode);
      checkExpandos(template.nextNode);

      model = toObservable({'foo': model['foo']});
      templateBind(template).model = model;
    }).then(endOfMicrotask).then((_) {
      checkExpandos(template.nextNode);
    });
  });

  test('Repeat-Empty', () {
    var div = createTestHtml(
        '<template repeat>text</template>');

    var template = div.firstChild;
    var model = toObservable([0, 1, 2]);
    templateBind(template).model = model;

    return new Future(() {
      expect(div.nodes.length, 4);

      model.length = 1;
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 2);

      model.addAll(toObservable([3, 4]));
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 4);

      model.removeRange(1, 2);
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 3);
    });
  });

  test('Removal from iteration needs to unbind', () {
    var div = createTestHtml(
        '<template repeat="{{}}"><a>{{v}}</a></template>');
    var template = div.firstChild;
    var model = toObservable([{'v': 0}, {'v': 1}, {'v': 2}, {'v': 3},
        {'v': 4}]);
    templateBind(template).model = model;

    var nodes, vs;
    return new Future(() {

      nodes = div.nodes.skip(1).toList();
      vs = model.toList();

      for (var i = 0; i < 5; i++) {
        expect(nodes[i].text, '$i');
      }

      model.length = 3;
    }).then(endOfMicrotask).then((_) {
      for (var i = 0; i < 5; i++) {
        expect(nodes[i].text, '$i');
      }

      vs[3]['v'] = 33;
      vs[4]['v'] = 44;
    }).then(endOfMicrotask).then((_) {
      for (var i = 0; i < 5; i++) {
        expect(nodes[i].text, '$i');
      }
    });
  });

  test('Template.clear', () {
    var div = createTestHtml(
        '<template repeat>{{}}</template>');
    var template = div.firstChild;
    templateBind(template).model = [0, 1, 2];

    return new Future(() {
      expect(div.nodes.length, 4);
      expect(div.nodes[1].text, '0');
      expect(div.nodes[2].text, '1');
      expect(div.nodes[3].text, '2');

      // clear() synchronously removes instances and clears the model.
      templateBind(div.firstChild).clear();
      expect(div.nodes.length, 1);
      expect(templateBind(template).model, null);

      // test that template still works if new model assigned
      templateBind(template).model = [3, 4];

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 3);
      expect(div.nodes[1].text, '3');
      expect(div.nodes[2].text, '4');
    });
  });

  test('DOM Stability on Iteration', () {
    var div = createTestHtml(
        '<template repeat="{{}}">{{}}</template>');
    var template = div.firstChild;
    var model = toObservable([1, 2, 3, 4, 5]);
    templateBind(template).model = model;

    var nodes;
    return new Future(() {
      // Note: the node at index 0 is the <template>.
      nodes = div.nodes.toList();
      expect(nodes.length, 6, reason: 'list has 5 items');

      model.removeAt(0);
      model.removeLast();

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 4, reason: 'list has 3 items');
      expect(identical(div.nodes[1], nodes[2]), true, reason: '2 not removed');
      expect(identical(div.nodes[2], nodes[3]), true, reason: '3 not removed');
      expect(identical(div.nodes[3], nodes[4]), true, reason: '4 not removed');

      model.insert(0, 5);
      model[2] = 6;
      model.add(7);

    }).then(endOfMicrotask).then((_) {

      expect(div.nodes.length, 6, reason: 'list has 5 items');
      expect(nodes.contains(div.nodes[1]), false, reason: '5 is a new node');
      expect(identical(div.nodes[2], nodes[2]), true);
      expect(nodes.contains(div.nodes[3]), false, reason: '6 is a new node');
      expect(identical(div.nodes[4], nodes[4]), true);
      expect(nodes.contains(div.nodes[5]), false, reason: '7 is a new node');

      nodes = div.nodes.toList();

      model.insert(2, 8);

    }).then(endOfMicrotask).then((_) {

      expect(div.nodes.length, 7, reason: 'list has 6 items');
      expect(identical(div.nodes[1], nodes[1]), true);
      expect(identical(div.nodes[2], nodes[2]), true);
      expect(nodes.contains(div.nodes[3]), false, reason: '8 is a new node');
      expect(identical(div.nodes[4], nodes[3]), true);
      expect(identical(div.nodes[5], nodes[4]), true);
      expect(identical(div.nodes[6], nodes[5]), true);
    });
  });

  test('Repeat2', () {
    var div = createTestHtml(
        '<template repeat="{{}}">{{value}}</template>');
    expect(div.nodes.length, 1);

    var template = div.firstChild;
    var model = toObservable([
      {'value': 0},
      {'value': 1},
      {'value': 2}
    ]);
    templateBind(template).model = model;

    return new Future(() {
      expect(div.nodes.length, 4);
      expect(div.nodes[1].text, '0');
      expect(div.nodes[2].text, '1');
      expect(div.nodes[3].text, '2');

      model[1]['value'] = 'One';
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 4);
      expect(div.nodes[1].text, '0');
      expect(div.nodes[2].text, 'One');
      expect(div.nodes[3].text, '2');

      model.replaceRange(0, 1, toObservable([{'value': 'Zero'}]));
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 4);
      expect(div.nodes[1].text, 'Zero');
      expect(div.nodes[2].text, 'One');
      expect(div.nodes[3].text, '2');
    });
  });

  test('TemplateWithInputValue', () {
    var div = createTestHtml(
        '<template bind="{{}}">'
        '<input value="{{x}}">'
        '</template>');
    var template = div.firstChild;
    var model = toObservable({'x': 'hi'});
    templateBind(template).model = model;

    return new Future(() {
      expect(div.nodes.length, 2);
      expect(div.nodes.last.value, 'hi');

      model['x'] = 'bye';
      expect(div.nodes.last.value, 'hi');
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.last.value, 'bye');

      div.nodes.last.value = 'hello';
      dispatchEvent('input', div.nodes.last);
      expect(model['x'], 'hello');
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.last.value, 'hello');
    });
  });

//////////////////////////////////////////////////////////////////////////////

  test('Decorated', () {
    var div = createTestHtml(
        '<template bind="{{ XX }}" id="t1">'
          '<p>Crew member: {{name}}, Job title: {{title}}</p>'
        '</template>'
        '<template bind="{{ XY }}" id="t2" ref="t1"></template>');

    var t1 = document.getElementById('t1');
    var t2 = document.getElementById('t2');
    var model = toObservable({
      'XX': {'name': 'Leela', 'title': 'Captain'},
      'XY': {'name': 'Fry', 'title': 'Delivery boy'},
      'XZ': {'name': 'Zoidberg', 'title': 'Doctor'}
    });
    templateBind(t1).model = model;
    templateBind(t2).model = model;

    return new Future(() {
      var instance = t1.nextElementSibling;
      expect(instance.text, 'Crew member: Leela, Job title: Captain');

      instance = t2.nextElementSibling;
      expect(instance.text, 'Crew member: Fry, Job title: Delivery boy');

      expect(div.children.length, 4);
      expect(div.nodes.length, 4);

      expect(div.nodes[1].tagName, 'P');
      expect(div.nodes[3].tagName, 'P');
    });
  });

  test('DefaultStyles', () {
    var t = new Element.tag('template');
    TemplateBindExtension.decorate(t);

    document.body.append(t);
    expect(t.getComputedStyle().display, 'none');

    t.remove();
  });


  test('Bind', () {
    var div = createTestHtml('<template bind="{{}}">Hi {{ name }}</template>');
    var template = div.firstChild;
    var model = toObservable({'name': 'Leela'});
    templateBind(template).model = model;

    return new Future(() => expect(div.nodes[1].text, 'Hi Leela'));
  });

  test('BindPlaceHolderHasNewLine', () {
    var div = createTestHtml(
        '<template bind="{{}}">Hi {{\nname\n}}</template>');
    var template = div.firstChild;
    var model = toObservable({'name': 'Leela'});
    templateBind(template).model = model;

    return new Future(() => expect(div.nodes[1].text, 'Hi Leela'));
  });

  test('BindWithRef', () {
    var id = 't${new math.Random().nextInt(100)}';
    var div = createTestHtml(
        '<template id="$id">'
          'Hi {{ name }}'
        '</template>'
        '<template ref="$id" bind="{{}}"></template>');

    var t1 = div.nodes.first;
    var t2 = div.nodes[1];

    var model = toObservable({'name': 'Fry'});
    templateBind(t1).model = model;
    templateBind(t2).model = model;

    return new Future(() => expect(t2.nextNode.text, 'Hi Fry'));
  });

  test('Ref at multiple', () {
    // Note: this test is asserting that template "ref"erences can be located
    // at various points. In particular:
    // -in the document (at large) (e.g. ref=doc)
    // -within template content referenced from sub-content
    //   -both before and after the reference
    // The following asserts ensure that all referenced templates content is
    // found.
    var div = createTestHtml(
      '<template bind>'
        '<template bind ref=doc></template>'
        '<template id=elRoot>EL_ROOT</template>'
        '<template bind>'
          '<template bind ref=elRoot></template>'
          '<template bind>'
            '<template bind ref=subA></template>'
            '<template id=subB>SUB_B</template>'
            '<template bind>'
              '<template bind ref=subB></template>'
            '</template>'
          '</template>'
          '<template id=subA>SUB_A</template>'
        '</template>'
      '</template>'
      '<template id=doc>DOC</template>');
    var t = div.firstChild;
    var fragment = templateBind(t).createInstance({});
    expect(fragment.nodes.length, 14);
    expect(fragment.nodes[1].text, 'DOC');
    expect(fragment.nodes[5].text, 'EL_ROOT');
    expect(fragment.nodes[8].text, 'SUB_A');
    expect(fragment.nodes[12].text, 'SUB_B');
    div.append(fragment);
  });

  test('Update Ref', () {
    // Updating ref by observing the attribute is dependent on MutationObserver
    var div = createTestHtml(
        '<template id=A>Hi, {{}}</template>'
        '<template id=B>Hola, {{}}</template>'
        '<template ref=A repeat></template>');

    var template = div.nodes[2];
    var model = new ObservableList.from(['Fry']);
    templateBind(template).model = model;

    return new Future(() {
      expect(div.nodes.length, 4);
      expect('Hi, Fry', div.nodes[3].text);

      // In IE 11, MutationObservers do not fire before setTimeout.
      // So rather than using "then" to queue up the next test, we use a
      // MutationObserver here to detect the change to "ref".
      var done = new Completer();
      new MutationObserver((mutations, observer) {
        expect(div.nodes.length, 5);

        expect('Hola, Fry', div.nodes[3].text);
        expect('Hola, Leela', div.nodes[4].text);
        done.complete();
      }).observe(template, attributes: true, attributeFilter: ['ref']);

      template.setAttribute('ref', 'B');
      model.add('Leela');

      return done.future;
    });
  });

  test('Bound Ref', () {
    var div = createTestHtml(
        '<template id=A>Hi, {{}}</template>'
        '<template id=B>Hola, {{}}</template>'
        '<template ref="{{ ref }}" repeat="{{ people }}"></template>');

    var template = div.nodes[2];
    var model = toObservable({'ref': 'A', 'people': ['Fry']});
    templateBind(template).model = model;

    return new Future(() {
      expect(div.nodes.length, 4);
      expect('Hi, Fry', div.nodes[3].text);

      model['ref'] = 'B';
      model['people'].add('Leela');

    }).then(endOfMicrotask).then((x) {
      expect(div.nodes.length, 5);

      expect('Hola, Fry', div.nodes[3].text);
      expect('Hola, Leela', div.nodes[4].text);
    });
  });

  test('BindWithDynamicRef', () {
    var id = 't${new math.Random().nextInt(100)}';
    var div = createTestHtml(
        '<template id="$id">'
          'Hi {{ name }}'
        '</template>'
        '<template ref="{{ id }}" bind="{{}}"></template>');

    var t1 = div.firstChild;
    var t2 = div.nodes[1];
    var model = toObservable({'name': 'Fry', 'id': id });
    templateBind(t1).model = model;
    templateBind(t2).model = model;

    return new Future(() => expect(t2.nextNode.text, 'Hi Fry'));
  });

  assertNodesAre(div, [arguments]) {
    var expectedLength = arguments.length;
    expect(div.nodes.length, expectedLength + 1);

    for (var i = 0; i < arguments.length; i++) {
      var targetNode = div.nodes[i + 1];
      expect(targetNode.text, arguments[i]);
    }
  }

  test('Repeat3', () {
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

    templateBind(t).model = m;
    return new Future(() {

      assertNodesAre(div, ['Hi Raf', 'Hi Arv', 'Hi Neal']);

      m['contacts'].add(toObservable({'name': 'Alex'}));
    }).then(endOfMicrotask).then((_) {
      assertNodesAre(div, ['Hi Raf', 'Hi Arv', 'Hi Neal', 'Hi Alex']);

      m['contacts'].replaceRange(0, 2,
          toObservable([{'name': 'Rafael'}, {'name': 'Erik'}]));
    }).then(endOfMicrotask).then((_) {
      assertNodesAre(div, ['Hi Rafael', 'Hi Erik', 'Hi Neal', 'Hi Alex']);

      m['contacts'].removeRange(1, 3);
    }).then(endOfMicrotask).then((_) {
      assertNodesAre(div, ['Hi Rafael', 'Hi Alex']);

      m['contacts'].insertAll(1,
          toObservable([{'name': 'Erik'}, {'name': 'Dimitri'}]));
    }).then(endOfMicrotask).then((_) {
      assertNodesAre(div, ['Hi Rafael', 'Hi Erik', 'Hi Dimitri', 'Hi Alex']);

      m['contacts'].replaceRange(0, 1,
          toObservable([{'name': 'Tab'}, {'name': 'Neal'}]));
    }).then(endOfMicrotask).then((_) {
      assertNodesAre(div, ['Hi Tab', 'Hi Neal', 'Hi Erik', 'Hi Dimitri',
          'Hi Alex']);

      m['contacts'] = toObservable([{'name': 'Alex'}]);
    }).then(endOfMicrotask).then((_) {
      assertNodesAre(div, ['Hi Alex']);

      m['contacts'].length = 0;
    }).then(endOfMicrotask).then((_) {
      assertNodesAre(div, []);
    });
  });

  test('RepeatModelSet', () {
    var div = createTestHtml(
        '<template repeat="{{ contacts }}">'
          'Hi {{ name }}'
        '</template>');
    var template = div.firstChild;
    var m = toObservable({
      'contacts': [
        {'name': 'Raf'},
        {'name': 'Arv'},
        {'name': 'Neal'}
      ]
    });
    templateBind(template).model = m;
    return new Future(() {
      assertNodesAre(div, ['Hi Raf', 'Hi Arv', 'Hi Neal']);
    });
  });

  test('RepeatEmptyPath', () {
    var div = createTestHtml(
        '<template repeat="{{}}">Hi {{ name }}</template>');
    var t = div.nodes.first;

    var m = toObservable([
      {'name': 'Raf'},
      {'name': 'Arv'},
      {'name': 'Neal'}
    ]);
    templateBind(t).model = m;
    return new Future(() {

      assertNodesAre(div, ['Hi Raf', 'Hi Arv', 'Hi Neal']);

      m.add(toObservable({'name': 'Alex'}));
    }).then(endOfMicrotask).then((_) {
      assertNodesAre(div, ['Hi Raf', 'Hi Arv', 'Hi Neal', 'Hi Alex']);

      m.replaceRange(0, 2, toObservable([{'name': 'Rafael'}, {'name': 'Erik'}]));
    }).then(endOfMicrotask).then((_) {
      assertNodesAre(div, ['Hi Rafael', 'Hi Erik', 'Hi Neal', 'Hi Alex']);

      m.removeRange(1, 3);
    }).then(endOfMicrotask).then((_) {
      assertNodesAre(div, ['Hi Rafael', 'Hi Alex']);

      m.insertAll(1, toObservable([{'name': 'Erik'}, {'name': 'Dimitri'}]));
    }).then(endOfMicrotask).then((_) {
      assertNodesAre(div, ['Hi Rafael', 'Hi Erik', 'Hi Dimitri', 'Hi Alex']);

      m.replaceRange(0, 1, toObservable([{'name': 'Tab'}, {'name': 'Neal'}]));
    }).then(endOfMicrotask).then((_) {
      assertNodesAre(div, ['Hi Tab', 'Hi Neal', 'Hi Erik', 'Hi Dimitri',
          'Hi Alex']);

      m.length = 0;
      m.add(toObservable({'name': 'Alex'}));
    }).then(endOfMicrotask).then((_) {
      assertNodesAre(div, ['Hi Alex']);
    });
  });

  test('RepeatNullModel', () {
    var div = createTestHtml(
        '<template repeat="{{}}">Hi {{ name }}</template>');
    var t = div.nodes.first;

    var m = null;
    templateBind(t).model = m;

    expect(div.nodes.length, 1);

    t.attributes['iterate'] = '';
    m = toObservable({});
    templateBind(t).model = m;
    return new Future(() => expect(div.nodes.length, 1));
  });

  test('RepeatReuse', () {
    var div = createTestHtml(
        '<template repeat="{{}}">Hi {{ name }}</template>');
    var t = div.nodes.first;

    var m = toObservable([
      {'name': 'Raf'},
      {'name': 'Arv'},
      {'name': 'Neal'}
    ]);
    templateBind(t).model = m;

    var node1, node2, node3;
    return new Future(() {
      assertNodesAre(div, ['Hi Raf', 'Hi Arv', 'Hi Neal']);
      node1 = div.nodes[1];
      node2 = div.nodes[2];
      node3 = div.nodes[3];

      m.replaceRange(1, 2, toObservable([{'name': 'Erik'}]));
    }).then(endOfMicrotask).then((_) {
      assertNodesAre(div, ['Hi Raf', 'Hi Erik', 'Hi Neal']);
      expect(div.nodes[1], node1,
          reason: 'model[0] did not change so the node should not have changed');
      expect(div.nodes[2], isNot(equals(node2)),
          reason: 'Should not reuse when replacing');
      expect(div.nodes[3], node3,
          reason: 'model[2] did not change so the node should not have changed');

      node2 = div.nodes[2];
      m.insert(0, toObservable({'name': 'Alex'}));
    }).then(endOfMicrotask).then((_) {
      assertNodesAre(div, ['Hi Alex', 'Hi Raf', 'Hi Erik', 'Hi Neal']);
    });
  });

  test('TwoLevelsDeepBug', () {
    var div = createTestHtml(
      '<template bind="{{}}"><span><span>{{ foo }}</span></span></template>');
    var template = div.firstChild;
    var model = toObservable({'foo': 'bar'});
    templateBind(template).model = model;
    return new Future(() {
      expect(div.nodes[1].nodes[0].nodes[0].text, 'bar');
    });
  });

  test('Checked', () {
    var div = createTestHtml(
        '<template bind>'
          '<input type="checkbox" checked="{{a}}">'
        '</template>');
    var t = div.nodes.first;
    templateBind(t).model = toObservable({'a': true });

    return new Future(() {

      var instanceInput = t.nextNode;
      expect(instanceInput.checked, true);

      instanceInput.click();
      expect(instanceInput.checked, false);

      instanceInput.click();
      expect(instanceInput.checked, true);
    });
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
    return new Future(() {

      var i = start;
      expect(div.nodes[i++].text, '1');
      expect(div.nodes[i++].tagName, 'TEMPLATE');
      expect(div.nodes[i++].text, '2');

      m['a']['b'] = 11;
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes[start].text, '11');

      m['a']['c'] = toObservable({'d': 22});
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes[start + 2].text, '22');

      //clearAllTemplates(div);
    });
  }

  test('Nested', () => nestedHelper(
      '<template bind="{{a}}">'
        '{{b}}'
        '<template bind="{{c}}">'
          '{{d}}'
        '</template>'
      '</template>', 1));

  test('NestedWithRef', () => nestedHelper(
        '<template id="inner">{{d}}</template>'
        '<template id="outer" bind="{{a}}">'
          '{{b}}'
          '<template ref="inner" bind="{{c}}"></template>'
        '</template>', 2));

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
    return new Future(() {

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

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes[start + 3].text, '3');
      expect(div.nodes[start + 5].text, '33');
    });
  }

  test('NestedRepeatBind', () => nestedIterateInstantiateHelper(
      '<template repeat="{{a}}">'
        '{{b}}'
        '<template bind="{{c}}">'
          '{{d}}'
        '</template>'
      '</template>', 1));

  test('NestedRepeatBindWithRef', () => nestedIterateInstantiateHelper(
      '<template id="inner">'
        '{{d}}'
      '</template>'
      '<template repeat="{{a}}">'
        '{{b}}'
        '<template ref="inner" bind="{{c}}"></template>'
      '</template>', 2));

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
    return new Future(() {

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
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes[start + 4].text, '3');
      expect(div.nodes[start + 6].text, '31');
      expect(div.nodes[start + 7].text, '32');
      expect(div.nodes[start + 8].text, '33');
    });
  }

  test('NestedRepeatBind', () => nestedIterateIterateHelper(
      '<template repeat="{{a}}">'
        '{{b}}'
        '<template repeat="{{c}}">'
          '{{d}}'
        '</template>'
      '</template>', 1));

  test('NestedRepeatRepeatWithRef', () => nestedIterateIterateHelper(
      '<template id="inner">'
        '{{d}}'
      '</template>'
      '<template repeat="{{a}}">'
        '{{b}}'
        '<template ref="inner" repeat="{{c}}"></template>'
      '</template>', 2));

  test('NestedRepeatSelfRef', () {
    var div = createTestHtml(
        '<template id="t" repeat="{{}}">'
          '{{name}}'
          '<template ref="t" repeat="{{items}}"></template>'
        '</template>');

    var template = div.firstChild;

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

    templateBind(template).model = m;

    int i = 1;
    return new Future(() {
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
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes[i++].text, 'Item 1 changed');
      expect(div.nodes[i++].tagName, 'TEMPLATE');
      expect(div.nodes[i++].text, 'Item 2');
    });
  });

  // Note: we don't need a zone for this test, and we don't want to alter timing
  // since we're testing a rather subtle relationship between select and option.
  test('Attribute Template Option/Optgroup', () {
    var div = createTestHtml(
        '<template bind>'
          '<select selectedIndex="{{ selected }}">'
            '<optgroup template repeat="{{ groups }}" label="{{ name }}">'
              '<option template repeat="{{ items }}">{{ val }}</option>'
            '</optgroup>'
          '</select>'
        '</template>');

    var template = div.firstChild;
    var m = toObservable({
      'selected': 1,
      'groups': [{
        'name': 'one', 'items': [{ 'val': 0 }, { 'val': 1 }]
      }],
    });

    templateBind(template).model = m;

    var completer = new Completer();

    new MutationObserver((records, observer) {
      var select = div.nodes[0].nextNode;
      if (select == null || select.querySelector('option') == null) return;

      observer.disconnect();
      new Future(() {
        expect(select.nodes.length, 2);

        expect(select.selectedIndex, 1, reason: 'selected index should update '
            'after template expands.');

        expect(select.nodes[0].tagName, 'TEMPLATE');
        var optgroup = select.nodes[1];
        expect(optgroup.nodes[0].tagName, 'TEMPLATE');
        expect(optgroup.nodes[1].tagName, 'OPTION');
        expect(optgroup.nodes[1].text, '0');
        expect(optgroup.nodes[2].tagName, 'OPTION');
        expect(optgroup.nodes[2].text, '1');

        completer.complete();
      });
    })..observe(div, childList: true, subtree: true);

    Observable.dirtyCheck();

    return completer.future;
  });

  test('NestedIterateTableMixedSemanticNative', () {
    if (!parserHasNativeTemplate) return null;

    var div = createTestHtml(
        '<table><tbody>'
          '<template repeat="{{}}">'
            '<tr>'
              '<td template repeat="{{}}" class="{{ val }}">{{ val }}</td>'
            '</tr>'
          '</template>'
        '</tbody></table>');
    var template = div.firstChild.firstChild.firstChild;

    var m = toObservable([
      [{ 'val': 0 }, { 'val': 1 }],
      [{ 'val': 2 }, { 'val': 3 }]
    ]);

    templateBind(template).model = m;
    return new Future(() {
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
  });

  test('NestedIterateTable', () {
    var div = createTestHtml(
        '<table><tbody>'
          '<tr template repeat="{{}}">'
            '<td template repeat="{{}}" class="{{ val }}">{{ val }}</td>'
          '</tr>'
        '</tbody></table>');
    var template = div.firstChild.firstChild.firstChild;

    var m = toObservable([
      [{ 'val': 0 }, { 'val': 1 }],
      [{ 'val': 2 }, { 'val': 3 }]
    ]);

    templateBind(template).model = m;
    return new Future(() {

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
  });

  test('NestedRepeatDeletionOfMultipleSubTemplates', () {
    var div = createTestHtml(
        '<ul>'
          '<template repeat="{{}}" id=t1>'
            '<li>{{name}}'
              '<ul>'
                '<template ref=t1 repeat="{{items}}"></template>'
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
    var ul = div.firstChild;
    var t = ul.firstChild;

    templateBind(t).model = m;
    return new Future(() {
      expect(ul.nodes.length, 2);
      var ul2 = ul.nodes[1].nodes[1];
      expect(ul2.nodes.length, 2);
      var ul3 = ul2.nodes[1].nodes[1];
      expect(ul3.nodes.length, 1);

      m.removeAt(0);
    }).then(endOfMicrotask).then((_) {
      expect(ul.nodes.length, 1);
    });
  });

  test('DeepNested', () {
    var div = createTestHtml(
      '<template bind="{{a}}">'
        '<p>'
          '<template bind="{{b}}">'
            '{{ c }}'
          '</template>'
        '</p>'
      '</template>');
    var template = div.firstChild;
    var m = toObservable({
      'a': {
        'b': {
          'c': 42
        }
      }
    });
    templateBind(template).model = m;
    return new Future(() {
      expect(div.nodes[1].tagName, 'P');
      expect(div.nodes[1].nodes.first.tagName, 'TEMPLATE');
      expect(div.nodes[1].nodes[1].text, '42');
    });
  });

  test('TemplateContentRemoved', () {
    var div = createTestHtml('<template bind="{{}}">{{ }}</template>');
    var template = div.firstChild;
    var model = 42;

    templateBind(template).model = model;
    return new Future(() {
      expect(div.nodes[1].text, '42');
      expect(div.nodes[0].text, '');
    });
  });

  test('TemplateContentRemovedEmptyArray', () {
    var div = createTestHtml('<template iterate>Remove me</template>');
    var template = div.firstChild;
    templateBind(template).model = [];
    return new Future(() {
      expect(div.nodes.length, 1);
      expect(div.nodes[0].text, '');
    });
  });

  test('TemplateContentRemovedNested', () {
    var div = createTestHtml(
        '<template bind="{{}}">'
          '{{ a }}'
          '<template bind="{{}}">'
            '{{ b }}'
          '</template>'
        '</template>');
    var template = div.firstChild;
    var model = toObservable({
      'a': 1,
      'b': 2
    });
    templateBind(template).model = model;
    return new Future(() {
      expect(div.nodes[0].text, '');
      expect(div.nodes[1].text, '1');
      expect(div.nodes[2].text, '');
      expect(div.nodes[3].text, '2');
    });
  });

  test('BindWithUndefinedModel', () {
    var div = createTestHtml(
        '<template bind="{{}}" if="{{}}">{{ a }}</template>');
    var template = div.firstChild;

    var model = toObservable({'a': 42});
    templateBind(template).model = model;
    return new Future(() {
      expect(div.nodes[1].text, '42');

      model = null;
      templateBind(template).model = model;
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 1);

      model = toObservable({'a': 42});
      templateBind(template).model = model;
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes[1].text, '42');
    });
  });

  test('BindNested', () {
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
    var template = div.firstChild;
    var m = toObservable({
      'name': 'Hermes',
      'wife': {
        'name': 'LaBarbara'
      }
    });
    templateBind(template).model = m;

    return new Future(() {
      expect(div.nodes.length, 5);
      expect(div.nodes[1].text, 'Name: Hermes');
      expect(div.nodes[3].text, 'Wife: LaBarbara');

      m['child'] = toObservable({'name': 'Dwight'});

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 6);
      expect(div.nodes[5].text, 'Child: Dwight');

      m.remove('wife');

    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 5);
      expect(div.nodes[4].text, 'Child: Dwight');
    });
  });

  test('BindRecursive', () {
    var div = createTestHtml(
        '<template bind="{{}}" if="{{}}" id="t">'
          'Name: {{ name }}'
          '<template bind="{{friend}}" if="{{friend}}" ref="t"></template>'
        '</template>');
    var template = div.firstChild;
    var m = toObservable({
      'name': 'Fry',
      'friend': {
        'name': 'Bender'
      }
    });
    templateBind(template).model = m;
    return new Future(() {
      expect(div.nodes.length, 5);
      expect(div.nodes[1].text, 'Name: Fry');
      expect(div.nodes[3].text, 'Name: Bender');

      m['friend']['friend'] = toObservable({'name': 'Leela'});
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 7);
      expect(div.nodes[5].text, 'Name: Leela');

      m['friend'] = toObservable({'name': 'Leela'});
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.length, 5);
      expect(div.nodes[3].text, 'Name: Leela');
    });
  });

  test('Template - Self is terminator', () {
    var div = createTestHtml(
        '<template repeat>{{ foo }}'
          '<template bind></template>'
        '</template>');
    var template = div.firstChild;

    var m = toObservable([{ 'foo': 'bar' }]);
    templateBind(template).model = m;
    return new Future(() {

      m.add(toObservable({ 'foo': 'baz' }));
      templateBind(template).model = m;
    }).then(endOfMicrotask).then((_) {

      expect(div.nodes.length, 5);
      expect(div.nodes[1].text, 'bar');
      expect(div.nodes[3].text, 'baz');
    });
  });

  test('Template - Same Contents, Different Array has no effect', () {
    if (!MutationObserver.supported) return null;

    var div = createTestHtml('<template repeat>{{ foo }}</template>');
    var template = div.firstChild;

    var m = toObservable([{ 'foo': 'bar' }, { 'foo': 'bat'}]);
    templateBind(template).model = m;
    var observer = new MutationObserver((x, y) {});
    return new Future(() {
      observer.observe(div, childList: true);

      var template = div.firstChild;
      templateBind(template).model = new ObservableList.from(m);
    }).then(endOfMicrotask).then((_) {
      var records = observer.takeRecords();
      expect(records.length, 0);
    });
  });

  test('RecursiveRef', () {
    var div = createTestHtml(
        '<template bind>'
          '<template id=src>{{ foo }}</template>'
          '<template bind ref=src></template>'
        '</template>');

    var m = toObservable({'foo': 'bar'});
    templateBind(div.firstChild).model = m;
    return new Future(() {
      expect(div.nodes.length, 4);
      expect(div.nodes[3].text, 'bar');
    });
  });

  test('baseURI', () {
    // TODO(jmesserly): Dart's setInnerHtml breaks this test -- the template
    // URL is created as blank despite the NullTreeSanitizer.
    // Use JS interop as a workaround.
    //var div = createTestHtml('<template bind>'
    //   '<div style="background: url(foo.jpg)"></div></template>');
    var div = new DivElement();
    new JsObject.fromBrowserObject(div)['innerHTML'] = '<template bind>'
        '<div style="background: url(foo.jpg)"></div></template>';
    testDiv.append(div);
    TemplateBindExtension.decorate(div.firstChild);

    var local = document.createElement('div');
    local.attributes['style'] = 'background: url(foo.jpg)';
    div.append(local);
    var template = div.firstChild;
    templateBind(template).model = {};
    return new Future(() {
      expect(div.nodes[1].style.backgroundImage, local.style.backgroundImage);
    });
  });

  test('ChangeRefId', () {
    var div = createTestHtml(
        '<template id="a">a:{{ }}</template>'
        '<template id="b">b:{{ }}</template>'
        '<template repeat="{{}}">'
          '<template ref="a" bind="{{}}"></template>'
        '</template>');
    var template = div.nodes[2];
    var model = toObservable([]);
    templateBind(template).model = model;
    return new Future(() {
      expect(div.nodes.length, 3);

      document.getElementById('a').id = 'old-a';
      document.getElementById('b').id = 'a';

      model..add(1)..add(2);
    }).then(endOfMicrotask).then((_) {

      expect(div.nodes.length, 7);
      expect(div.nodes[4].text, 'b:1');
      expect(div.nodes[6].text, 'b:2');
    });
  });

  test('Content', () {
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

    // NOTE: these tests don't work under ShadowDOM polyfill.
    // Disabled for now.
    //expect(templateA.ownerDocument.window, window);
    //expect(templateB.ownerDocument.window, window);

    expect(contentA.ownerDocument.window, null);
    expect(contentB.ownerDocument.window, null);

    expect(contentA.nodes.last, contentA.nodes.first);
    expect(contentA.nodes.first.tagName, 'A');

    expect(contentB.nodes.last, contentB.nodes.first);
    expect(contentB.nodes.first.tagName, 'B');
  });

  test('NestedContent', () {
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

  test('BindShadowDOM', () {
    if (!ShadowRoot.supported) return null;

    var root = createShadowTestHtml(
        '<template bind="{{}}">Hi {{ name }}</template>');
    var model = toObservable({'name': 'Leela'});
    templateBind(root.firstChild).model = model;
    return new Future(() => expect(root.nodes[1].text, 'Hi Leela'));
  });

  // Dart note: this test seems gone from JS. Keeping for posterity sake.
  test('BindShadowDOM createInstance', () {
    if (!ShadowRoot.supported) return null;

    var model = toObservable({'name': 'Leela'});
    var template = new Element.html('<template>Hi {{ name }}</template>');
    var root = createShadowTestHtml('');
    root.nodes.add(templateBind(template).createInstance(model));

    return new Future(() {
      expect(root.text, 'Hi Leela');

      model['name'] = 'Fry';
    }).then(endOfMicrotask).then((_) {
      expect(root.text, 'Hi Fry');
    });
  });

  test('BindShadowDOM Template Ref', () {
    if (!ShadowRoot.supported) return null;
    var root = createShadowTestHtml(
        '<template id=foo>Hi</template><template bind ref=foo></template>');
    var template = root.nodes[1];
    templateBind(template).model = toObservable({});
    return new Future(() {
      expect(root.nodes.length, 3);
      clearAllTemplates(root);
    });
  });

  // https://github.com/Polymer/TemplateBinding/issues/8
  test('UnbindingInNestedBind', () {
    var div = createTestHtml(
      '<template bind="{{outer}}" if="{{outer}}" syntax="testHelper">'
        '<template bind="{{inner}}" if="{{inner}}">'
          '{{ age }}'
        '</template>'
      '</template>');
    var template = div.firstChild;
    var syntax = new UnbindingInNestedBindSyntax();
    var model = toObservable({'outer': {'inner': {'age': 42}}});

    templateBind(template)..model = model..bindingDelegate = syntax;

    return new Future(() {
      expect(syntax.count, 1);

      var inner = model['outer']['inner'];
      model['outer'] = null;

    }).then(endOfMicrotask).then((_) {
      expect(syntax.count, 1);

      model['outer'] = toObservable({'inner': {'age': 2}});
      syntax.expectedAge = 2;

    }).then(endOfMicrotask).then((_) {
      expect(syntax.count, 2);
    });
  });

  // https://github.com/toolkitchen/mdv/issues/8
  test('DontCreateInstancesForAbandonedIterators', () {
    var div = createTestHtml(
      '<template bind="{{}} {{}}">'
        '<template bind="{{}}">Foo</template>'
      '</template>');
    var template = div.firstChild;
    templateBind(template).model = null;
    return nextMicrotask;
  });

  test('CreateInstance', () {
    var div = createTestHtml(
      '<template bind="{{a}}">'
        '<template bind="{{b}}">'
          '{{ foo }}:{{ replaceme }}'
        '</template>'
      '</template>');
    var outer = templateBind(div.nodes.first);
    var model = toObservable({'b': {'foo': 'bar'}});

    var instance = outer.createInstance(model, new TestBindingSyntax());
    expect(instance.firstChild.nextNode.text, 'bar:replaced');

    clearAllTemplates(instance);
  });

  test('CreateInstance - sync error', () {
    var div = createTestHtml('<template>{{foo}}</template>');
    var outer = templateBind(div.nodes.first);
    var model = 1; // model is missing 'foo' should throw.
    expect(() => outer.createInstance(model, new TestBindingSyntax()),
        throwsA(_isNoSuchMethodError));
  });

  test('CreateInstance - async error', () {
    var div = createTestHtml(
      '<template>'
        '<template bind="{{b}}">'
          '{{ foo }}:{{ replaceme }}'
        '</template>'
      '</template>');
    var outer = templateBind(div.nodes.first);
    var model = toObservable({'b': 1}); // missing 'foo' should throw.

    bool seen = false;
    runZoned(() => outer.createInstance(model, new TestBindingSyntax()),
      onError: (e) {
        _expectNoSuchMethod(e);
        seen = true;
      });
    return new Future(() { expect(seen, isTrue); });
  });

  test('Repeat - svg', () {
    var div = createTestHtml(
        '<svg width="400" height="110">'
          '<template repeat>'
            '<rect width="{{ width }}" height="{{ height }}" />'
          '</template>'
        '</svg>');

    var model = toObservable([{ 'width': 10, 'height': 11 },
                              { 'width': 20, 'height': 21 }]);
    var svg = div.firstChild;
    var template = svg.firstChild;
    templateBind(template).model = model;

    return new Future(() {
      expect(svg.nodes.length, 3);
      expect(svg.nodes[1].attributes['width'], '10');
      expect(svg.nodes[1].attributes['height'], '11');
      expect(svg.nodes[2].attributes['width'], '20');
      expect(svg.nodes[2].attributes['height'], '21');
    });
  });

  test('Bootstrap', () {
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

  test('issue-285', () {
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

    return new Future(() {
      expect(template.nextNode.nextNode.nextNode.text, '2');
      model['show'] = false;
    }).then(endOfMicrotask).then((_) {
      model['show'] = true;
    }).then(endOfMicrotask).then((_) {
      expect(template.nextNode.nextNode.nextNode.text, '2');
    });
  });

  test('Accessor value retrieval count', () {
    var div = createTestHtml(
        '<template bind>{{ prop }}</template>');

    var model = new TestAccessorModel();

    templateBind(div.firstChild).model = model;

    return new Future(() {
      expect(model.count, 1);

      model.value++;
      // Dart note: we don't handle getters in @observable, so we need to
      // notify regardless.
      model.notifyPropertyChange(#prop, 1, model.value);

    }).then(endOfMicrotask).then((_) {
      expect(model.count, 2);
    });
  });

  test('issue-141', () {
    var div = createTestHtml(
        '<template bind>'
          '<div foo="{{foo1}} {{foo2}}" bar="{{bar}}"></div>'
        '</template>');

    var template = div.firstChild;
    var model = toObservable({
      'foo1': 'foo1Value',
      'foo2': 'foo2Value',
      'bar': 'barValue'
    });

    templateBind(template).model = model;
    return new Future(() {
      expect(div.lastChild.attributes['bar'], 'barValue');
    });
  });

  test('issue-18', () {
    var delegate = new Issue18Syntax();

    var div = createTestHtml(
        '<template bind>'
          '<div class="foo: {{ bar }}"></div>'
        '</template>');

    var template = div.firstChild;
    var model = toObservable({'bar': 2});

    templateBind(template)..model = model..bindingDelegate = delegate;

    return new Future(() {
      expect(div.lastChild.attributes['class'], 'foo: 2');
    });
  });

  test('issue-152', () {
    var div = createTestHtml(
        '<template ref=notThere bind>XXX</template>');

    var template = div.firstChild;
    templateBind(template).model = {};

    return new Future(() {
      // if a ref cannot be located, a template will continue to use itself
      // as the source of template instances.
      expect(div.nodes[1].text, 'XXX');
    });
  });
}

compatTests() {
  test('underbar bindings', () {
    var div = createTestHtml(
        '<template bind>'
          '<div _style="color: {{ color }};"></div>'
          '<img _src="{{ url }}">'
          '<a _href="{{ url2 }}">Link</a>'
          '<input type="number" _value="{{ number }}">'
        '</template>');

    var template = div.firstChild;
    var model = toObservable({
      'color': 'red',
      'url': 'pic.jpg',
      'url2': 'link.html',
      'number': 4
    });

    templateBind(template).model = model;
    return new Future(() {
      var subDiv = div.firstChild.nextNode;
      expect(subDiv.attributes['style'], 'color: red;');

      var img = subDiv.nextNode;
      expect(img.attributes['src'], 'pic.jpg');

      var a = img.nextNode;
      expect(a.attributes['href'], 'link.html');

      var input = a.nextNode;
      expect(input.value, '4');
    });
  });
}

// TODO(jmesserly): ideally we could test the type with isNoSuchMethodError,
// however dart:js converts the nSM into a String at some point.
// So for now we do string comparison.
_isNoSuchMethodError(e) => '$e'.contains('NoSuchMethodError');

_expectNoSuchMethod(e) {
  // expect(e, isNoSuchMethodError);
  expect('$e', contains('NoSuchMethodError'));
}

class Issue285Syntax extends BindingDelegate {
  prepareInstanceModel(template) {
    if (template.id == 'del') return (val) => val * 2;
  }
}

class TestBindingSyntax extends BindingDelegate {
  prepareBinding(String path, name, node) {
    if (path.trim() == 'replaceme') {
      return (m, n, oneTime) => new PathObserver('replaced', '');
    }
    return null;
  }
}

class UnbindingInNestedBindSyntax extends BindingDelegate {
  int expectedAge = 42;
  int count = 0;

  prepareBinding(path, name, node) {
    if (name != 'text' || path != 'age') return null;

    return (model, _, oneTime) {
      expect(model['age'], expectedAge);
      count++;
      return new PathObserver(model, path);
    };
  }
}

class Issue18Syntax extends BindingDelegate {
  prepareBinding(path, name, node) {
    if (name != 'class') return null;

    return (model, _, oneTime) => new PathObserver(model, path);
  }
}

class BindIfMinimalDiscardChanges extends BindingDelegate {
  Map<String, int> discardChangesCalled;

  BindIfMinimalDiscardChanges(this.discardChangesCalled) : super() {}

  prepareBinding(path, name, node) {
    return (model, node, oneTime) =>
      new DiscardCountingPathObserver(discardChangesCalled, model, path);
  }
}

class DiscardCountingPathObserver extends PathObserver {
  Map<String, int> discardChangesCalled;

  DiscardCountingPathObserver(this.discardChangesCalled, model, path)
      : super(model, path) {}

  get value {
    discardChangesCalled[path.toString()]++;
    return super.value;
  }
}

class TestAccessorModel extends Observable {
  @observable var value = 1;
  var count = 0;

  @reflectable
  get prop {
    count++;
    return value;
  }
}
