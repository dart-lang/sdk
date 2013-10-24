// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library template_binding.test.node_bindings_test;

import 'dart:html';
import 'package:observe/observe.dart' show toObservable;
import 'package:template_binding/template_binding.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';
import 'utils.dart';

// Note: this file ported from
// https://github.com/toolkitchen/mdv/blob/master/tests/node_bindings.js

main() {
  useHtmlConfiguration();
  group('Node Bindings', nodeBindingTests);
}

nodeBindingTests() {
  setUp(() {
    document.body.append(testDiv = new DivElement());
  });

  tearDown(() {
    testDiv.remove();
    testDiv = null;
  });

  observeTest('Text', () {
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

  observeTest('Element', () {
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

  observeTest('Input.value', () => inputTextAreaValueTest('input'));
  observeTest('TextArea.value', () => inputTextAreaValueTest('textarea'));

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

  observeTest('Checkbox Input', () {
    var input = new InputElement();
    testDiv.append(input);
    input.type = 'checkbox';
    var model = toObservable({'x': true});
    nodeBind(input).bind('checked', model, 'x');
    expect(input.checked, true);

    model['x'] = false;
    expect(input.checked, true, reason: 'changes delivered async');
    performMicrotaskCheckpoint();
    expect(input.checked, false);

    input.click();
    expect(model['x'], true);
    performMicrotaskCheckpoint();

    input.click();
    expect(model['x'], false);
  });
}
