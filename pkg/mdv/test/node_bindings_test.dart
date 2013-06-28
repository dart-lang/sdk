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
// https://github.com/toolkitchen/mdv/blob/master/tests/node_bindings.js

main() {
  mdv.initialize();
  useHtmlConfiguration();
  group('Node Bindings', nodeBindingTests);
}

sym(x) => new Symbol(x);

nodeBindingTests() {
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
    var text = new Text('hi');
    var model = toSymbolMap({'a': 1});
    text.bind('text', model, 'a');
    expect(text.text, '1');

    model[sym('a')] = 2;
    deliverChangeRecords();
    expect(text.text, '2');

    text.unbind('text');
    model[sym('a')] = 3;
    deliverChangeRecords();
    expect(text.text, '2');

    // TODO(rafaelw): Throw on binding to unavailable property?
  });

  test('Element', () {
    var element = new DivElement();
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
  });

  test('Text Input', () {
    var input = new InputElement();
    var model = toSymbolMap({'x': 42});
    input.bind('value', model, 'x');
    expect(input.value, '42');

    model[sym('x')] = 'Hi';
    expect(input.value, '42', reason: 'changes delivered async');
    deliverChangeRecords();
    expect(input.value, 'Hi');

    input.value = 'changed';
    dispatchEvent('input', input);
    expect(model[sym('x')], 'changed');

    input.unbind('value');

    input.value = 'changed again';
    dispatchEvent('input', input);
    expect(model[sym('x')], 'changed');

    input.bind('value', model, 'x');
    model[sym('x')] = null;
    deliverChangeRecords();
    expect(input.value, '');
  });

  test('Radio Input', () {
    var input = new InputElement();
    input.type = 'radio';
    var model = toSymbolMap({'x': true});
    input.bind('checked', model, 'x');
    expect(input.checked, true);

    model[sym('x')] = false;
    expect(input.checked, true);
    deliverChangeRecords();
    expect(input.checked, false,reason: 'model change should update checked');

    input.checked = true;
    dispatchEvent('change', input);
    expect(model[sym('x')], true, reason: 'input.checked should set model');

    input.unbind('checked');

    input.checked = false;
    dispatchEvent('change', input);
    expect(model[sym('x')], true,
        reason: 'disconnected binding should not fire');
  });

  test('Checkbox Input', () {
    var input = new InputElement();
    testDiv.append(input);
    input.type = 'checkbox';
    var model = toSymbolMap({'x': true});
    input.bind('checked', model, 'x');
    expect(input.checked, true);

    model[sym('x')] = false;
    expect(input.checked, true, reason: 'changes delivered async');
    deliverChangeRecords();
    expect(input.checked, false);

    input.click();
    expect(model[sym('x')], true);
    deliverChangeRecords();

    input.click();
    expect(model[sym('x')], false);
  });
}
