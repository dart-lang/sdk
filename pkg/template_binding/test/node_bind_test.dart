// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library template_binding.test.node_bind_test;

import 'dart:html';

import 'package:observe/observe.dart' show toObservable, PathObserver;
import 'package:template_binding/template_binding.dart' show nodeBind;
import 'package:template_binding/src/node_binding.dart' show getObserverForTest;

import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';
import 'utils.dart';

// Note: this file ported from
// https://github.com/toolkitchen/mdv/blob/master/tests/node_bindings.js

main() {
  useHtmlConfiguration();

  setUp(() {
    document.body.append(testDiv = new DivElement());
  });

  tearDown(() {
    testDiv.remove();
    testDiv = null;
  });


  group('Text bindings', testBindings);
  group('Element attribute bindings', elementBindings);
  group('Form Element bindings', formBindings);
}

testBindings() {
  observeTest('Basic', () {
    var text = new Text('hi');
    var model = toObservable({'a': 1});
    nodeBind(text).bind('text', model, 'a');
    expect(text.text, '1');

    model['a'] = 2;
    performMicrotaskCheckpoint();
    expect(text.text, '2');

    nodeBind(text).unbind('text');
    model['a'] = 3;
    performMicrotaskCheckpoint();
    expect(text.text, '2');

    // TODO(rafaelw): Throw on binding to unavailable property?
  });

  observeTest('No Path', () {
    var text = new Text('hi');
    var model = 1;
    nodeBind(text).bind('text', model);
    expect(text.text, '1');
  });

  observeTest('Path unreachable', () {
    var text = testDiv.append(new Text('hi'));
    var model = 1;
    nodeBind(text).bind('text', model, 'a');
    expect(text.text, '');
  });

  observeTest('Observer is Model', () {
    var text = new Text('');
    var model = toObservable({'a': {'b': {'c': 1}}});
    var observer = new PathObserver(model, 'a.b.c');
    nodeBind(text).bind('text', observer, 'value');
    expect(text.text, '1');

    var binding = nodeBind(text).bindings['text'];
    expect(binding, isNotNull);
    expect(getObserverForTest(binding), observer,
        reason: 'should reuse observer');

    model['a']['b']['c'] = 2;
    performMicrotaskCheckpoint();
    expect(text.text, '2');
    nodeBind(text).unbind('text');
  });
}

elementBindings() {
  observeTest('Basic', () {
    var el = new DivElement();
    var model = toObservable({'a': '1'});
    nodeBind(el).bind('foo', model, 'a');
    performMicrotaskCheckpoint();
    expect(el.attributes['foo'], '1');

    model['a'] = '2';
    performMicrotaskCheckpoint();
    expect(el.attributes['foo'], '2');

    model['a'] = 232.2;
    performMicrotaskCheckpoint();
    expect(el.attributes['foo'], '232.2');

    model['a'] = 232;
    performMicrotaskCheckpoint();
    expect(el.attributes['foo'], '232');

    model['a'] = null;
    performMicrotaskCheckpoint();
    expect(el.attributes['foo'], '');
  });

  observeTest('No Path', () {
    var el = testDiv.append(new DivElement());
    var model = 1;
    nodeBind(el).bind('foo', model);
    expect(el.attributes['foo'], '1');
  });

  observeTest('Path unreachable', () {
    var el = testDiv.append(new DivElement());
    var model = toObservable({});
    nodeBind(el).bind('foo', model, 'bar');
    expect(el.attributes['foo'], '');
  });

  observeTest('Dashes', () {
    var el = testDiv.append(new DivElement());
    var model = toObservable({'a': '1'});
    nodeBind(el).bind('foo-bar', model, 'a');
    performMicrotaskCheckpoint();
    expect(el.attributes['foo-bar'], '1');

    model['a'] = '2';
    performMicrotaskCheckpoint();
    expect(el.attributes['foo-bar'], '2');
  });

  observeTest('Element.id, Element.hidden?', () {
    var element = new DivElement();
    var model = toObservable({'a': 1, 'b': 2});
    nodeBind(element).bind('hidden?', model, 'a');
    nodeBind(element).bind('id', model, 'b');

    expect(element.attributes, contains('hidden'));
    expect(element.attributes['hidden'], '');
    expect(element.id, '2');

    model['a'] = null;
    performMicrotaskCheckpoint();
    expect(element.attributes, isNot(contains('hidden')),
        reason: 'null is false-y');

    model['a'] = false;
    performMicrotaskCheckpoint();
    expect(element.attributes, isNot(contains('hidden')));

    model['a'] = 'foo';
    model['b'] = 'x';
    performMicrotaskCheckpoint();
    expect(element.attributes, contains('hidden'));
    expect(element.attributes['hidden'], '');
    expect(element.id, 'x');
  });

  observeTest('Element.id - path unreachable', () {
    var element = testDiv.append(new DivElement());
    var model = toObservable({});
    nodeBind(element).bind('id', model, 'a');
    expect(element.id, '');
  });
}

formBindings() {
  inputTextAreaValueTest(String tagName) {
    var el = new Element.tag(tagName);
    testDiv.nodes.add(el);
    var model = toObservable({'x': 42});
    nodeBind(el).bind('value', model, 'x');
    expect(el.value, '42');

    model['x'] = 'Hi';
    expect(el.value, '42', reason: 'changes delivered async');
    performMicrotaskCheckpoint();
    expect(el.value, 'Hi');

    el.value = 'changed';
    dispatchEvent('input', el);
    expect(model['x'], 'changed');

    nodeBind(el).unbind('value');

    el.value = 'changed again';
    dispatchEvent('input', el);
    expect(model['x'], 'changed');

    nodeBind(el).bind('value', model, 'x');
    model['x'] = null;
    performMicrotaskCheckpoint();
    expect(el.value, '');
  }

  inputTextAreaNoPath(String tagName) {
    var el = testDiv.append(new Element.tag(tagName));
    var model = 42;
    nodeBind(el).bind('value', model);
    expect(el.value, '42');
  }

  inputTextAreaPathUnreachable(String tagName) {
    var el = testDiv.append(new Element.tag(tagName));
    var model = toObservable({});
    nodeBind(el).bind('value', model, 'a');
    expect(el.value, '');
  }

  observeTest('Input.value',
      () => inputTextAreaValueTest('input'));
  observeTest('Input.value - no path',
      () => inputTextAreaNoPath('input'));
  observeTest('Input.value - path unreachable',
      () => inputTextAreaPathUnreachable('input'));
  observeTest('TextArea.value',
      () => inputTextAreaValueTest('textarea'));
  observeTest('TextArea.value - no path',
      () => inputTextAreaNoPath('textarea'));
  observeTest('TextArea.value - path unreachable',
      () => inputTextAreaPathUnreachable('textarea'));

  observeTest('Radio Input', () {
    var input = new InputElement();
    input.type = 'radio';
    var model = toObservable({'x': true});
    nodeBind(input).bind('checked', model, 'x');
    expect(input.checked, true);

    model['x'] = false;
    expect(input.checked, true);
    performMicrotaskCheckpoint();
    expect(input.checked, false,reason: 'model change should update checked');

    input.checked = true;
    dispatchEvent('change', input);
    expect(model['x'], true, reason: 'input.checked should set model');

    nodeBind(input).unbind('checked');

    input.checked = false;
    dispatchEvent('change', input);
    expect(model['x'], true,
        reason: 'disconnected binding should not fire');
  });

  observeTest('Input.value - user value rejected', () {
    var model = toObservable({'val': 'ping'});

    var el = new InputElement();
    nodeBind(el).bind('value', model, 'val');
    performMicrotaskCheckpoint();
    expect(el.value, 'ping');

    el.value = 'pong';
    dispatchEvent('input', el);
    expect(model['val'], 'pong');

    // Try a deep path.
    model = toObservable({'a': {'b': {'c': 'ping'}}});

    nodeBind(el).bind('value', model, 'a.b.c');
    performMicrotaskCheckpoint();
    expect(el.value, 'ping');

    el.value = 'pong';
    dispatchEvent('input', el);
    expect(new PathObserver(model, 'a.b.c').value, 'pong');

    // Start with the model property being absent.
    model['a']['b'].remove('c');
    performMicrotaskCheckpoint();
    expect(el.value, '');

    el.value = 'pong';
    dispatchEvent('input', el);
    expect(new PathObserver(model, 'a.b.c').value, 'pong');
    performMicrotaskCheckpoint();

    // Model property unreachable (and unsettable).
    model['a'].remove('b');
    performMicrotaskCheckpoint();
    expect(el.value, '');

    el.value = 'pong';
    dispatchEvent('input', el);
    expect(new PathObserver(model, 'a.b.c').value, null);
  });

  observeTest('(Checkbox)Input.checked', () {
    var el = testDiv.append(new InputElement());
    el.type = 'checkbox';

    var model = toObservable({'x': true});
    nodeBind(el).bind('checked', model, 'x');
    expect(el.checked, true);

    model['x'] = false;
    expect(el.checked, true, reason: 'changes delivered async');
    performMicrotaskCheckpoint();
    expect(el.checked, false);

    el.click();
    expect(model['x'], true);
    performMicrotaskCheckpoint();

    el.click();
    expect(model['x'], false);
  });

  observeTest('(Checkbox)Input.checked - path unreachable', () {
    var input = testDiv.append(new InputElement());
    input.type = 'checkbox';
    var model = toObservable({});
    nodeBind(input).bind('checked', model, 'x');
    expect(input.checked, false);
  });

  observeTest('(Checkbox)Input.checked 2', () {
    var model = toObservable({'val': true});

    var el = testDiv.append(new InputElement());
    el.type = 'checkbox';
    nodeBind(el).bind('checked', model, 'val');
    performMicrotaskCheckpoint();
    expect(el.checked, true);

    model['val'] = false;
    performMicrotaskCheckpoint();
    expect(el.checked, false);

    el.click();
    expect(model['val'], true);

    el.click();
    expect(model['val'], false);

    el.onClick.listen((_) {
      expect(model['val'], true);
    });
    el.onChange.listen((_) {
      expect(model['val'], true);
    });

    el.dispatchEvent(new MouseEvent('click', view: window));
  });

  observeTest('(Checkbox)Input.checked - binding updated on click', () {
    var model = toObservable({'val': true});

    var el = new InputElement();
    testDiv.append(el);
    el.type = 'checkbox';
    nodeBind(el).bind('checked', model, 'val');
    performMicrotaskCheckpoint();
    expect(el.checked, true);

    el.onClick.listen((_) {
      expect(model['val'], false);
    });

    el.dispatchEvent(new MouseEvent('click', view: window));
  });

  observeTest('(Checkbox)Input.checked - binding updated on change', () {
    var model = toObservable({'val': true});

    var el = new InputElement();
    testDiv.append(el);
    el.type = 'checkbox';
    nodeBind(el).bind('checked', model, 'val');
    performMicrotaskCheckpoint();
    expect(el.checked, true);

    el.onChange.listen((_) {
      expect(model['val'], false);
    });

    el.dispatchEvent(new MouseEvent('click', view: window));
  });

  observeTest('(Radio)Input.checked', () {
    var input = testDiv.append(new InputElement());
    input.type = 'radio';
    var model = toObservable({'x': true});
    nodeBind(input).bind('checked', model, 'x');
    expect(input.checked, true);

    model['x'] = false;
    expect(input.checked, true);
    performMicrotaskCheckpoint();
    expect(input.checked, false);

    input.checked = true;
    dispatchEvent('change', input);
    expect(model['x'], true);

    nodeBind(input).unbind('checked');

    input.checked = false;
    dispatchEvent('change', input);
    expect(model['x'], true);
  });

  radioInputChecked2(host) {
    var model = toObservable({'val1': true, 'val2': false, 'val3': false,
        'val4': true});
    var RADIO_GROUP_NAME = 'test';

    var container = host.append(new DivElement());

    var el1 = container.append(new InputElement());
    el1.type = 'radio';
    el1.name = RADIO_GROUP_NAME;
    nodeBind(el1).bind('checked', model, 'val1');

    var el2 = container.append(new InputElement());
    el2.type = 'radio';
    el2.name = RADIO_GROUP_NAME;
    nodeBind(el2).bind('checked', model, 'val2');

    var el3 = container.append(new InputElement());
    el3.type = 'radio';
    el3.name = RADIO_GROUP_NAME;
    nodeBind(el3).bind('checked', model, 'val3');

    var el4 = container.append(new InputElement());
    el4.type = 'radio';
    el4.name = 'othergroup';
    nodeBind(el4).bind('checked', model, 'val4');

    performMicrotaskCheckpoint();
    expect(el1.checked, true);
    expect(el2.checked, false);
    expect(el3.checked, false);
    expect(el4.checked, true);

    model['val1'] = false;
    model['val2'] = true;
    performMicrotaskCheckpoint();
    expect(el1.checked, false);
    expect(el2.checked, true);
    expect(el3.checked, false);
    expect(el4.checked, true);

    el1.checked = true;
    dispatchEvent('change', el1);
    expect(model['val1'], true);
    expect(model['val2'], false);
    expect(model['val3'], false);
    expect(model['val4'], true);

    el3.checked = true;
    dispatchEvent('change', el3);
    expect(model['val1'], false);
    expect(model['val2'], false);
    expect(model['val3'], true);
    expect(model['val4'], true);
  }

  observeTest('(Radio)Input.checked 2', () {
    radioInputChecked2(testDiv);
  });

  observeTest('(Radio)Input.checked 2 - ShadowRoot', () {
    if (!ShadowRoot.supported) return;

    var div = new DivElement();
    var shadowRoot = div.createShadowRoot();
    radioInputChecked2(shadowRoot);
    unbindAll(shadowRoot);
  });

  radioInputCheckedMultipleForms(host) {
    var model = toObservable({'val1': true, 'val2': false, 'val3': false,
        'val4': true});
    var RADIO_GROUP_NAME = 'observeTest';

    var container = testDiv.append(new DivElement());
    var form1 = new FormElement();
    container.append(form1);
    var form2 = new FormElement();
    container.append(form2);

    var el1 = new InputElement();
    form1.append(el1);
    el1.type = 'radio';
    el1.name = RADIO_GROUP_NAME;
    nodeBind(el1).bind('checked', model, 'val1');

    var el2 = new InputElement();
    form1.append(el2);
    el2.type = 'radio';
    el2.name = RADIO_GROUP_NAME;
    nodeBind(el2).bind('checked', model, 'val2');

    var el3 = new InputElement();
    form2.append(el3);
    el3.type = 'radio';
    el3.name = RADIO_GROUP_NAME;
    nodeBind(el3).bind('checked', model, 'val3');

    var el4 = new InputElement();
    form2.append(el4);
    el4.type = 'radio';
    el4.name = RADIO_GROUP_NAME;
    nodeBind(el4).bind('checked', model, 'val4');

    performMicrotaskCheckpoint();
    expect(el1.checked, true);
    expect(el2.checked, false);
    expect(el3.checked, false);
    expect(el4.checked, true);

    el2.checked = true;
    dispatchEvent('change', el2);
    expect(model['val1'], false);
    expect(model['val2'], true);

    // Radio buttons in form2 should be unaffected
    expect(model['val3'], false);
    expect(model['val4'], true);

    el3.checked = true;
    dispatchEvent('change', el3);
    expect(model['val3'], true);
    expect(model['val4'], false);

    // Radio buttons in form1 should be unaffected
    expect(model['val1'], false);
    expect(model['val2'], true);
  }

  observeTest('(Radio)Input.checked - multiple forms', () {
    radioInputCheckedMultipleForms(testDiv);
  });

  observeTest('(Radio)Input.checked 2 - ShadowRoot', () {
    if (!ShadowRoot.supported) return;

    var shadowRoot = new DivElement().createShadowRoot();
    radioInputChecked2(shadowRoot);
    unbindAll(shadowRoot);
  });

  observeTest('Select.selectedIndex', () {
    var select = new SelectElement();
    testDiv.append(select);
    var option0 = select.append(new OptionElement());
    var option1 = select.append(new OptionElement());
    var option2 = select.append(new OptionElement());

    var model = toObservable({'val': 2});

    nodeBind(select).bind('selectedIndex', model, 'val');
    performMicrotaskCheckpoint();
    expect(select.selectedIndex, 2);

    select.selectedIndex = 1;
    dispatchEvent('change', select);
    expect(model['val'], 1);
  });

  observeTest('Select.selectedIndex - path NaN', () {
    var select = new SelectElement();
    testDiv.append(select);
    var option0 = select.append(new OptionElement());
    var option1 = select.append(new OptionElement());
    option1.selected = true;
    var option2 = select.append(new OptionElement());

    var model = toObservable({'val': 'foo'});

    nodeBind(select).bind('selectedIndex', model, 'val');
    performMicrotaskCheckpoint();
    expect(select.selectedIndex, 0);
  });

  observeTest('Select.selectedIndex - path unreachable', () {
    var select = new SelectElement();
    testDiv.append(select);
    var option0 = select.append(new OptionElement());
    var option1 = select.append(new OptionElement());
    option1.selected = true;
    var option2 = select.append(new OptionElement());

    var model = toObservable({});

    nodeBind(select).bind('selectedIndex', model, 'val');
    performMicrotaskCheckpoint();
    expect(select.selectedIndex, 0);
  });

  observeTest('Option.value', () {
    var option = testDiv.append(new OptionElement());
    var model = toObservable({'x': 42});
    nodeBind(option).bind('value', model, 'x');
    expect(option.value, '42');

    model['x'] = 'Hi';
    expect(option.value, '42');
    performMicrotaskCheckpoint();
    expect(option.value, 'Hi');
  });

  observeTest('Select.value', () {
    var select = testDiv.append(new SelectElement());
    testDiv.append(select);
    var option0 = select.append(new OptionElement());
    var option1 = select.append(new OptionElement());
    var option2 = select.append(new OptionElement());

    var model = toObservable({
      'opt0': 'a',
      'opt1': 'b',
      'opt2': 'c',
      'selected': 'b'
    });

    nodeBind(option0).bind('value', model, 'opt0');
    nodeBind(option1).bind('value', model, 'opt1');
    nodeBind(option2).bind('value', model, 'opt2');

    nodeBind(select).bind('value', model, 'selected');
    performMicrotaskCheckpoint();
    expect(select.value, 'b');

    select.value = 'c';
    dispatchEvent('change', select);
    expect(model['selected'], 'c');

    model['opt2'] = 'X';
    performMicrotaskCheckpoint();
    expect(select.value, 'X');
    expect(model['selected'], 'X');

    model['selected'] = 'a';
    performMicrotaskCheckpoint();
    expect(select.value, 'a');
  });
}
