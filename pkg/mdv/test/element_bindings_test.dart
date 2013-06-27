// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library node_bindings_test;

import 'dart:async';
import 'dart:html';
import 'package:mdv/mdv.dart' as mdv;
import 'package:observe/observe.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';
import 'observe_utils.dart';

// Note: this file ported from
// https://github.com/toolkitchen/mdv/blob/master/tests/element_bindings.js

main() {
  mdv.initialize();
  useHtmlConfiguration();
  group('Element Bindings', elementBindingTests);
}

sym(x) => new Symbol(x);

observePath(obj, path) => new PathObserver(obj, path);

elementBindingTests() {
  var testDiv;

  setUp(() {
    document.body.append(testDiv = new DivElement());
  });

  tearDown(() {
    testDiv.remove();
    testDiv = null;
  });

  dispatchEvent(type, target) {
    target.dispatchEvent(new Event(type, cancelable: false));
  }

  test('Text', () {
    var template = new Element.html('<template bind>{{a}} and {{b}}');
    testDiv.append(template);
    var model = toSymbolMap({'a': 1, 'b': 2});
    template.model = model;
    deliverChangeRecords();
    var text = testDiv.nodes[1];
    expect(text.text, '1 and 2');

    model[sym('a')] = 3;
    deliverChangeRecords();
    expect(text.text, '3 and 2');
  });

  test('SimpleBinding', () {
    var el = new DivElement();
    var model = toSymbolMap({'a': '1'});
    el.bind('foo', model, 'a');
    deliverChangeRecords();
    expect(el.attributes['foo'], '1');

    model[sym('a')] = '2';
    deliverChangeRecords();
    expect(el.attributes['foo'], '2');

    model[sym('a')] = 232.2;
    deliverChangeRecords();
    expect(el.attributes['foo'], '232.2');

    model[sym('a')] = 232;
    deliverChangeRecords();
    expect(el.attributes['foo'], '232');

    model[sym('a')] = null;
    deliverChangeRecords();
    expect(el.attributes['foo'], '');
  });

  test('SimpleBindingWithDashes', () {
    var el = new DivElement();
    var model = toSymbolMap({'a': '1'});
    el.bind('foo-bar', model, 'a');
    deliverChangeRecords();
    expect(el.attributes['foo-bar'], '1');

    model[sym('a')] = '2';
    deliverChangeRecords();
    expect(el.attributes['foo-bar'], '2');
  });

  test('SimpleBindingWithComment', () {
    var el = new DivElement();
    el.innerHtml = '<!-- Comment -->';
    var model = toSymbolMap({'a': '1'});
    el.bind('foo-bar', model, 'a');
    deliverChangeRecords();
    expect(el.attributes['foo-bar'], '1');

    model[sym('a')] = '2';
    deliverChangeRecords();
    expect(el.attributes['foo-bar'], '2');
  });

  test('PlaceHolderBindingText', () {
    var model = toSymbolMap({
      'adj': 'cruel',
      'noun': 'world'
    });

    var el = new DivElement();
    el.text = 'dummy';
    el.nodes.first.text = 'Hello {{ adj }} {{noun}}!';
    var template = new Element.html('<template bind>');
    template.content.append(el);
    testDiv.append(template);
    template.model = model;

    deliverChangeRecords();
    el = testDiv.nodes[1].nodes.first;
    expect(el.text, 'Hello cruel world!');

    model[sym('adj')] = 'happy';
    deliverChangeRecords();
    expect(el.text, 'Hello happy world!');
  });

  test('InputElementTextBinding', () {
    var model = toSymbolMap({'val': 'ping'});

    var el = new InputElement();
    el.bind('value', model, 'val');
    deliverChangeRecords();
    expect(el.value, 'ping');

    el.value = 'pong';
    dispatchEvent('input', el);
    expect(model[sym('val')], 'pong');

    // Try a deep path.
    model = toSymbolMap({'a': {'b': {'c': 'ping'}}});

    el.bind('value', model, 'a.b.c');
    deliverChangeRecords();
    expect(el.value, 'ping');

    el.value = 'pong';
    dispatchEvent('input', el);
    expect(observePath(model, 'a.b.c').value, 'pong');

    // Start with the model property being absent.
    model[sym('a')][sym('b')].remove(sym('c'));
    deliverChangeRecords();
    expect(el.value, '');

    el.value = 'pong';
    dispatchEvent('input', el);
    expect(observePath(model, 'a.b.c').value, 'pong');
    deliverChangeRecords();

    // Model property unreachable (and unsettable).
    model[sym('a')].remove(sym('b'));
    deliverChangeRecords();
    expect(el.value, '');

    el.value = 'pong';
    dispatchEvent('input', el);
    expect(observePath(model, 'a.b.c').value, null);
  });

  test('InputElementCheckbox', () {
    var model = toSymbolMap({'val': true});

    var el = new InputElement();
    testDiv.append(el);
    el.type = 'checkbox';
    el.bind('checked', model, 'val');
    deliverChangeRecords();
    expect(el.checked, true);

    model[sym('val')] = false;
    deliverChangeRecords();
    expect(el.checked, false);

    el.click();
    expect(model[sym('val')], true);

    el.click();
    expect(model[sym('val')], false);

    el.onClick.listen((_) {
      expect(model[sym('val')], true);
    });
    el.onChange.listen((_) {
      expect(model[sym('val')], true);
    });

    el.dispatchEvent(new MouseEvent('click', view: window));
  });

  test('InputElementCheckbox - binding updated on click', () {
    var model = toSymbolMap({'val': true});

    var el = new InputElement();
    testDiv.append(el);
    el.type = 'checkbox';
    el.bind('checked', model, 'val');
    deliverChangeRecords();
    expect(el.checked, true);

    el.onClick.listen((_) {
      expect(model[sym('val')], false);
    });

    el.dispatchEvent(new MouseEvent('click', view: window));
  });

  test('InputElementCheckbox - binding updated on change', () {
    var model = toSymbolMap({'val': true});

    var el = new InputElement();
    testDiv.append(el);
    el.type = 'checkbox';
    el.bind('checked', model, 'val');
    deliverChangeRecords();
    expect(el.checked, true);

    el.onChange.listen((_) {
      expect(model[sym('val')], false);
    });

    el.dispatchEvent(new MouseEvent('click', view: window));
   });

  test('InputElementRadio', () {
    var model = toSymbolMap({'val1': true, 'val2': false, 'val3': false,
        'val4': true});
    var RADIO_GROUP_NAME = 'test';

    var container = testDiv;

    var el1 = new InputElement();
    testDiv.append(el1);
    el1.type = 'radio';
    el1.name = RADIO_GROUP_NAME;
    el1.bind('checked', model, 'val1');

    var el2 = new InputElement();
    testDiv.append(el2);
    el2.type = 'radio';
    el2.name = RADIO_GROUP_NAME;
    el2.bind('checked', model, 'val2');

    var el3 = new InputElement();
    testDiv.append(el3);
    el3.type = 'radio';
    el3.name = RADIO_GROUP_NAME;
    el3.bind('checked', model, 'val3');

    var el4 = new InputElement();
    testDiv.append(el4);
    el4.type = 'radio';
    el4.name = 'othergroup';
    el4.bind('checked', model, 'val4');

    deliverChangeRecords();
    expect(el1.checked, true);
    expect(el2.checked, false);
    expect(el3.checked, false);
    expect(el4.checked, true);

    model[sym('val1')] = false;
    model[sym('val2')] = true;
    deliverChangeRecords();
    expect(el1.checked, false);
    expect(el2.checked, true);
    expect(el3.checked, false);
    expect(el4.checked, true);

    el1.checked = true;
    dispatchEvent('change', el1);
    expect(model[sym('val1')], true);
    expect(model[sym('val2')], false);
    expect(model[sym('val3')], false);
    expect(model[sym('val4')], true);

    el3.checked = true;
    dispatchEvent('change', el3);
    expect(model[sym('val1')], false);
    expect(model[sym('val2')], false);
    expect(model[sym('val3')], true);
    expect(model[sym('val4')], true);
  });

  test('InputElementRadioMultipleForms', () {
    var model = toSymbolMap({'val1': true, 'val2': false, 'val3': false,
        'val4': true});
    var RADIO_GROUP_NAME = 'test';

    var form1 = new FormElement();
    testDiv.append(form1);
    var form2 = new FormElement();
    testDiv.append(form2);

    var el1 = new InputElement();
    form1.append(el1);
    el1.type = 'radio';
    el1.name = RADIO_GROUP_NAME;
    el1.bind('checked', model, 'val1');

    var el2 = new InputElement();
    form1.append(el2);
    el2.type = 'radio';
    el2.name = RADIO_GROUP_NAME;
    el2.bind('checked', model, 'val2');

    var el3 = new InputElement();
    form2.append(el3);
    el3.type = 'radio';
    el3.name = RADIO_GROUP_NAME;
    el3.bind('checked', model, 'val3');

    var el4 = new InputElement();
    form2.append(el4);
    el4.type = 'radio';
    el4.name = RADIO_GROUP_NAME;
    el4.bind('checked', model, 'val4');

    deliverChangeRecords();
    expect(el1.checked, true);
    expect(el2.checked, false);
    expect(el3.checked, false);
    expect(el4.checked, true);

    el2.checked = true;
    dispatchEvent('change', el2);
    expect(model[sym('val1')], false);
    expect(model[sym('val2')], true);

    // Radio buttons in form2 should be unaffected
    expect(model[sym('val3')], false);
    expect(model[sym('val4')], true);

    el3.checked = true;
    dispatchEvent('change', el3);
    expect(model[sym('val3')], true);
    expect(model[sym('val4')], false);

    // Radio buttons in form1 should be unaffected
    expect(model[sym('val1')], false);
    expect(model[sym('val2')], true);
  });

  test('BindToChecked', () {
    var div = new DivElement();
    testDiv.append(div);
    var child = new DivElement();
    div.append(child);
    var input = new InputElement();
    child.append(input);
    input.type = 'checkbox';

    var model = toSymbolMap({'a': {'b': false}});
    input.bind('checked', model, 'a.b');

    input.click();
    expect(model[sym('a')][sym('b')], true);

    input.click();
    expect(model[sym('a')][sym('b')], false);
  });

  test('MultipleReferences', () {
    var el = new DivElement();
    var template = new Element.html('<template bind>');
    template.content.append(el);
    testDiv.append(template);

    var model = toSymbolMap({'foo': 'bar'});
    el.attributes['foo'] = '{{foo}} {{foo}}';
    template.model = model;

    deliverChangeRecords();
    el = testDiv.nodes[1];
    expect(el.attributes['foo'], 'bar bar');
  });
}
