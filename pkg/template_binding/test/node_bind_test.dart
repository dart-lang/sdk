// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library template_binding.test.node_bind_test;

import 'dart:async';
import 'dart:html';

import 'package:observe/observe.dart'
    show toObservable, PathObserver, PropertyPath;
import 'package:template_binding/template_binding.dart' show nodeBind;

import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';
import 'utils.dart';

// Note: this file ported from
// https://github.com/toolkitchen/mdv/blob/master/tests/node_bindings.js

main() => dirtyCheckZone().run(() {
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
});

testBindings() {
  test('Basic', () {
    var text = new Text('hi');
    var model = toObservable({'a': 1});
    nodeBind(text).bind('text', new PathObserver(model, 'a'));
    expect(text.text, '1');

    model['a'] = 2;
    return new Future(() {
      expect(text.text, '2');

      nodeBind(text).unbind('text');
      model['a'] = 3;
    }).then(endOfMicrotask).then((_) {
      // TODO(rafaelw): Throw on binding to unavailable property?
      expect(text.text, '2');
    });
  });

  test('oneTime', () {
    var text = new Text('hi');
    nodeBind(text).bind('text', 1, oneTime: true);
    expect(text.text, '1');
  });

  test('No Path', () {
    var text = new Text('hi');
    var model = 1;
    nodeBind(text).bind('text', new PathObserver(model));
    expect(text.text, '1');
  });

  test('Path unreachable', () {
    var text = testDiv.append(new Text('hi'));
    var model = 1;
    nodeBind(text).bind('text', new PathObserver(model, 'a'));
    expect(text.text, '');
  });

  test('Observer is Model', () {
    var text = new Text('');
    var model = toObservable({'a': {'b': {'c': 1}}});
    var observer = new PathObserver(model, 'a.b.c');
    nodeBind(text).bind('text', observer);
    expect(text.text, '1');

    var binding = nodeBind(text).bindings['text'];
    expect(binding, observer, reason: 'should reuse observer');

    model['a']['b']['c'] = 2;
    return new Future(() {
      expect(text.text, '2');
      nodeBind(text).unbind('text');
    });
  });
}

elementBindings() {
  test('Basic', () {
    var el = new DivElement();
    var model = toObservable({'a': '1'});
    nodeBind(el).bind('foo', new PathObserver(model, 'a'));

    return new Future(() {
      expect(el.attributes['foo'], '1');
      model['a'] = '2';
    }).then(endOfMicrotask).then((_) {
      expect(el.attributes['foo'], '2');
      model['a'] = 232.2;
    }).then(endOfMicrotask).then((_) {
      expect(el.attributes['foo'], '232.2');
      model['a'] = 232;
    }).then(endOfMicrotask).then((_) {
      expect(el.attributes['foo'], '232');
      model['a'] = null;
    }).then(endOfMicrotask).then((_) {
      expect(el.attributes['foo'], '');
    });
  });

  test('oneTime', () {
    var el = testDiv.append(new DivElement());
    var model = toObservable({'a': '1'});
    nodeBind(el).bind('foo', 1, oneTime: true);
    expect('1', el.attributes['foo']);
  });

  test('No Path', () {
    var el = testDiv.append(new DivElement());
    var model = 1;
    nodeBind(el).bind('foo', new PathObserver(model));
    return new Future(() {
      expect(el.attributes['foo'], '1');
    });
  });

  test('Path unreachable', () {
    var el = testDiv.append(new DivElement());
    var model = toObservable({});
    nodeBind(el).bind('foo', new PathObserver(model, 'bar'));
    return new Future(() {
      expect(el.attributes['foo'], '');
    });
  });

  test('Dashes', () {
    var el = testDiv.append(new DivElement());
    var model = toObservable({'a': '1'});
    nodeBind(el).bind('foo-bar', new PathObserver(model, 'a'));
    return new Future(() {
      expect(el.attributes['foo-bar'], '1');
      model['a'] = '2';

    }).then(endOfMicrotask).then((_) {
      expect(el.attributes['foo-bar'], '2');
    });
  });

  test('Element.id, Element.hidden?', () {
    var element = new DivElement();
    var model = toObservable({'a': 1, 'b': 2});
    nodeBind(element).bind('hidden?', new PathObserver(model, 'a'));
    nodeBind(element).bind('id', new PathObserver(model, 'b'));

    expect(element.attributes, contains('hidden'));
    expect(element.attributes['hidden'], '');
    expect(element.id, '2');

    model['a'] = null;
    return new Future(() {
      expect(element.attributes, isNot(contains('hidden')),
          reason: 'null is false-y');

      model['a'] = false;
    }).then(endOfMicrotask).then((_) {
      expect(element.attributes, isNot(contains('hidden')));

      model['a'] = 'foo';
      model['b'] = 'x';
    }).then(endOfMicrotask).then((_) {
      expect(element.attributes, contains('hidden'));
      expect(element.attributes['hidden'], '');
      expect(element.id, 'x');
    });
  });

  test('Element.id - path unreachable', () {
    var element = testDiv.append(new DivElement());
    var model = toObservable({});
    nodeBind(element).bind('id', new PathObserver(model, 'a'));
    return new Future(() => expect(element.id, ''));
  });
}

formBindings() {
  inputTextAreaValueTest(String tagName) {
    var el = new Element.tag(tagName);
    testDiv.nodes.add(el);
    var model = toObservable({'x': 42});
    nodeBind(el).bind('value', new PathObserver(model, 'x'));
    expect(el.value, '42');

    model['x'] = 'Hi';
    expect(el.value, '42', reason: 'changes delivered async');
    return new Future(() {
      expect(el.value, 'Hi');

      el.value = 'changed';
      dispatchEvent('input', el);
      expect(model['x'], 'changed');

      nodeBind(el).unbind('value');

      el.value = 'changed again';
      dispatchEvent('input', el);
      expect(model['x'], 'changed');

      nodeBind(el).bind('value', new PathObserver(model, 'x'));
      model['x'] = null;
    }).then(endOfMicrotask).then((_) {
      expect(el.value, '');
    });
  }

  inputTextAreaValueOnetime(String tagName) {
    var el = testDiv.append(new Element.tag(tagName));
    nodeBind(el).bind('value', 42, oneTime: true);
    expect(el.value, '42');
  }

  inputTextAreaNoPath(String tagName) {
    var el = testDiv.append(new Element.tag(tagName));
    var model = 42;
    nodeBind(el).bind('value', new PathObserver(model));
    expect(el.value, '42');
  }

  inputTextAreaPathUnreachable(String tagName) {
    var el = testDiv.append(new Element.tag(tagName));
    var model = toObservable({});
    nodeBind(el).bind('value', new PathObserver(model, 'a'));
    expect(el.value, '');
  }

  test('Input.value',
      () => inputTextAreaValueTest('input'));

  test('Input.value - oneTime',
      () => inputTextAreaValueOnetime('input'));

  test('Input.value - no path',
      () => inputTextAreaNoPath('input'));

  test('Input.value - path unreachable',
      () => inputTextAreaPathUnreachable('input'));

  test('TextArea.value',
      () => inputTextAreaValueTest('textarea'));

  test('TextArea.value - oneTime',
      () => inputTextAreaValueOnetime('textarea'));

  test('TextArea.value - no path',
      () => inputTextAreaNoPath('textarea'));

  test('TextArea.value - path unreachable',
      () => inputTextAreaPathUnreachable('textarea'));

  test('Radio Input', () {
    var input = new InputElement();
    input.type = 'radio';
    var model = toObservable({'x': true});
    nodeBind(input).bind('checked', new PathObserver(model, 'x'));
    expect(input.checked, true);

    model['x'] = false;
    expect(input.checked, true);
    return new Future(() {
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
  });

  test('Input.value - user value rejected', () {
    var model = toObservable({'val': 'ping'});

    var el = new InputElement();
    nodeBind(el).bind('value', new PathObserver(model, 'val'));
    return new Future(() {
      expect(el.value, 'ping');

      el.value = 'pong';
      dispatchEvent('input', el);
      expect(model['val'], 'pong');

      // Try a deep path.
      model = toObservable({'a': {'b': {'c': 'ping'}}});

      nodeBind(el).bind('value', new PathObserver(model, 'a.b.c'));
    }).then(endOfMicrotask).then((_) {
      expect(el.value, 'ping');

      el.value = 'pong';
      dispatchEvent('input', el);
      expect(new PropertyPath('a.b.c').getValueFrom(model), 'pong');

      // Start with the model property being absent.
      model['a']['b'].remove('c');
    }).then(endOfMicrotask).then((_) {
      expect(el.value, '');

      el.value = 'pong';
      dispatchEvent('input', el);
      expect(new PropertyPath('a.b.c').getValueFrom(model), 'pong');
    }).then(endOfMicrotask).then((_) {

      // Model property unreachable (and unsettable).
      model['a'].remove('b');
    }).then(endOfMicrotask).then((_) {
      expect(el.value, '');

      el.value = 'pong';
      dispatchEvent('input', el);
      expect(new PropertyPath('a.b.c').getValueFrom(model), null);
    });
  });

  test('Checkbox Input.checked', () {
    var el = testDiv.append(new InputElement());
    el.type = 'checkbox';

    var model = toObservable({'x': true});
    nodeBind(el).bind('checked', new PathObserver(model, 'x'));
    expect(el.checked, true);

    model['x'] = false;
    expect(el.checked, true, reason: 'changes delivered async');
    return new Future(() {
      expect(el.checked, false);

      el.click();
      expect(model['x'], true);
    }).then(endOfMicrotask).then((_) {

      el.click();
      expect(model['x'], false);
    });
  });

  test('Checkbox Input.checked - oneTime', () {
    var input = testDiv.append(new InputElement());
    input.type = 'checkbox';
    nodeBind(input).bind('checked', true, oneTime: true);
    expect(input.checked, true, reason: 'checked was set');
  });

  test('Checkbox Input.checked - path unreachable', () {
    var input = testDiv.append(new InputElement());
    input.type = 'checkbox';
    var model = toObservable({});
    nodeBind(input).bind('checked', new PathObserver(model, 'x'));
    expect(input.checked, false);
  });

  test('Checkbox Input.checked 2', () {
    var model = toObservable({'val': true});

    var el = testDiv.append(new InputElement());
    el.type = 'checkbox';
    nodeBind(el).bind('checked', new PathObserver(model, 'val'));
    return new Future(() {
      expect(el.checked, true);

      model['val'] = false;
    }).then(endOfMicrotask).then((_) {
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
  });

  test('Checkbox Input.checked - binding updated on click', () {
    var model = toObservable({'val': true});

    var el = new InputElement();
    testDiv.append(el);
    el.type = 'checkbox';
    nodeBind(el).bind('checked', new PathObserver(model, 'val'));
    return new Future(() {
      expect(el.checked, true);

      int fired = 0;
      el.onClick.listen((_) {
        fired++;
        expect(model['val'], false);
      });

      el.dispatchEvent(new MouseEvent('click', view: window));

      expect(fired, 1, reason: 'events dispatched synchronously');
    });
  });

  test('Checkbox Input.checked - binding updated on change', () {
    var model = toObservable({'val': true});

    var el = new InputElement();
    testDiv.append(el);
    el.type = 'checkbox';
    nodeBind(el).bind('checked', new PathObserver(model, 'val'));
    return new Future(() {
      expect(el.checked, true);

      int fired = 0;
      el.onChange.listen((_) {
        fired++;
        expect(model['val'], false);
      });

      el.dispatchEvent(new MouseEvent('click', view: window));

      expect(fired, 1, reason: 'events dispatched synchronously');
    });
  });

  test('Radio Input.checked', () {
    var input = testDiv.append(new InputElement());
    input.type = 'radio';
    var model = toObservable({'x': true});
    nodeBind(input).bind('checked', new PathObserver(model, 'x'));
    expect(input.checked, true);

    model['x'] = false;
    expect(input.checked, true);
    return new Future(() {
      expect(input.checked, false);

      input.checked = true;
      dispatchEvent('change', input);
      expect(model['x'], true);

      nodeBind(input).unbind('checked');

      input.checked = false;
      dispatchEvent('change', input);
      expect(model['x'], true);
    });
  });

  test('Radio Input.checked - oneTime', () {
    var input = testDiv.append(new InputElement());
    input.type = 'radio';
    nodeBind(input).bind('checked', true, oneTime: true);
    expect(input.checked, true, reason: 'checked was set');
  });

  radioInputChecked2(host) {
    var model = toObservable({'val1': true, 'val2': false, 'val3': false,
        'val4': true});
    var RADIO_GROUP_NAME = 'test';

    var container = host.append(new DivElement());

    var el1 = container.append(new InputElement());
    el1.type = 'radio';
    el1.name = RADIO_GROUP_NAME;
    nodeBind(el1).bind('checked', new PathObserver(model, 'val1'));

    var el2 = container.append(new InputElement());
    el2.type = 'radio';
    el2.name = RADIO_GROUP_NAME;
    nodeBind(el2).bind('checked', new PathObserver(model, 'val2'));

    var el3 = container.append(new InputElement());
    el3.type = 'radio';
    el3.name = RADIO_GROUP_NAME;
    nodeBind(el3).bind('checked', new PathObserver(model, 'val3'));

    var el4 = container.append(new InputElement());
    el4.type = 'radio';
    el4.name = 'othergroup';
    nodeBind(el4).bind('checked', new PathObserver(model, 'val4'));

    return new Future(() {
      expect(el1.checked, true);
      expect(el2.checked, false);
      expect(el3.checked, false);
      expect(el4.checked, true);

      model['val1'] = false;
      model['val2'] = true;
    }).then(endOfMicrotask).then((_) {
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
    });
  }

  test('Radio Input.checked 2', () => radioInputChecked2(testDiv));

  test('Radio Input.checked 2 - ShadowRoot', () {
    if (!ShadowRoot.supported) return null;

    var shadowRoot = new DivElement().createShadowRoot();
    return radioInputChecked2(shadowRoot)
        .whenComplete(() => unbindAll(shadowRoot));
  });

  radioInputCheckedMultipleForms(host) {
    var model = toObservable({'val1': true, 'val2': false, 'val3': false,
        'val4': true});
    var RADIO_GROUP_NAME = 'test';

    var container = testDiv.append(new DivElement());
    var form1 = new FormElement();
    container.append(form1);
    var form2 = new FormElement();
    container.append(form2);

    var el1 = new InputElement();
    form1.append(el1);
    el1.type = 'radio';
    el1.name = RADIO_GROUP_NAME;
    nodeBind(el1).bind('checked', new PathObserver(model, 'val1'));

    var el2 = new InputElement();
    form1.append(el2);
    el2.type = 'radio';
    el2.name = RADIO_GROUP_NAME;
    nodeBind(el2).bind('checked', new PathObserver(model, 'val2'));

    var el3 = new InputElement();
    form2.append(el3);
    el3.type = 'radio';
    el3.name = RADIO_GROUP_NAME;
    nodeBind(el3).bind('checked', new PathObserver(model, 'val3'));

    var el4 = new InputElement();
    form2.append(el4);
    el4.type = 'radio';
    el4.name = RADIO_GROUP_NAME;
    nodeBind(el4).bind('checked', new PathObserver(model, 'val4'));

    return new Future(() {
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
    });
  }

  test('Radio Input.checked - multiple forms', () {
    return radioInputCheckedMultipleForms(testDiv);
  });

  test('Radio Input.checked - multiple forms - ShadowRoot', () {
    if (!ShadowRoot.supported) return null;

    var shadowRoot = new DivElement().createShadowRoot();
    return radioInputCheckedMultipleForms(shadowRoot)
        .whenComplete(() => unbindAll(shadowRoot));
  });

  test('Select.selectedIndex', () {
    var select = new SelectElement();
    testDiv.append(select);
    var option0 = select.append(new OptionElement());
    var option1 = select.append(new OptionElement());
    var option2 = select.append(new OptionElement());

    var model = toObservable({'val': 2});

    nodeBind(select).bind('selectedIndex', new PathObserver(model, 'val'));
    return new Future(() {
      expect(select.selectedIndex, 2);

      select.selectedIndex = 1;
      dispatchEvent('change', select);
      expect(model['val'], 1);
    });
  });

  test('Select.selectedIndex - oneTime', () {
    var select = new SelectElement();
    testDiv.append(select);
    var option0 = select.append(new OptionElement());
    var option1 = select.append(new OptionElement());
    var option2 = select.append(new OptionElement());

    nodeBind(select).bind('selectedIndex', 2, oneTime: true);
    return new Future(() => expect(select.selectedIndex, 2));
  });

  test('Select.selectedIndex - invalid path', () {
    var select = new SelectElement();
    testDiv.append(select);
    var option0 = select.append(new OptionElement());
    var option1 = select.append(new OptionElement());
    option1.selected = true;
    var option2 = select.append(new OptionElement());

    var model = toObservable({'val': 'foo'});

    nodeBind(select).bind('selectedIndex', new PathObserver(model, 'val'));
    return new Future(() => expect(select.selectedIndex, 0));
  });

  test('Select.selectedIndex - path unreachable', () {
    var select = new SelectElement();
    testDiv.append(select);
    var option0 = select.append(new OptionElement());
    var option1 = select.append(new OptionElement());
    option1.selected = true;
    var option2 = select.append(new OptionElement());

    var model = toObservable({});

    nodeBind(select).bind('selectedIndex', new PathObserver(model, 'val'));
    return new Future(() => expect(select.selectedIndex, 0));
  });

  test('Option.value', () {
    var option = testDiv.append(new OptionElement());
    var model = toObservable({'x': 42});
    nodeBind(option).bind('value', new PathObserver(model, 'x'));
    expect(option.value, '42');

    model['x'] = 'Hi';
    expect(option.value, '42');
    return new Future(() => expect(option.value, 'Hi'));
  });

  test('Option.value - oneTime', () {
    var option = testDiv.append(new OptionElement());
    nodeBind(option).bind('value', 42, oneTime: true);
    expect(option.value, '42');
  });

  test('Select.value', () {
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

    nodeBind(option0).bind('value', new PathObserver(model, 'opt0'));
    nodeBind(option1).bind('value', new PathObserver(model, 'opt1'));
    nodeBind(option2).bind('value', new PathObserver(model, 'opt2'));

    nodeBind(select).bind('value', new PathObserver(model, 'selected'));
    return new Future(() {
      expect(select.value, 'b');

      select.value = 'c';
      dispatchEvent('change', select);
      expect(model['selected'], 'c');

      model['opt2'] = 'X';
    }).then(endOfMicrotask).then((_) {
      expect(select.value, 'X');
      expect(model['selected'], 'X');

      model['selected'] = 'a';
    }).then(endOfMicrotask).then((_) {
      expect(select.value, 'a');
    });
  });
}
