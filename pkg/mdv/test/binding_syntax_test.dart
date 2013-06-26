// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library binding_syntax_test;

import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'package:mdv/mdv.dart' as mdv;
import 'package:observe/observe.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';
import 'observe_utils.dart';

// Note: this file ported from
// https://github.com/toolkitchen/mdv/blob/master/tests/syntax.js

main() {
  mdv.initialize();
  useHtmlConfiguration();
  group('Syntax', syntaxTests);
}

syntaxTests() {
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

  recursivelySetTemplateModel(element, model) {
    for (var node in element.queryAll('*')) {
      if (node.isTemplate) node.model = model;
    }
  }

  test('Registration', () {
    var model = toSymbolMap({'foo': 'bar'});

    var testSyntax = new TestBindingSyntax();
    TemplateElement.syntax['Test'] = testSyntax;
    try {
      var div = createTestHtml(
          '<template bind syntax="Test">{{ foo }}' +
          '<template bind>{{ foo }}</template></template>');
      recursivelySetTemplateModel(div, model);
      deliverChangeRecords();
      expect(div.nodes.length, 4);
      expect(div.nodes.last.text, 'bar');
      expect(div.nodes[2].tagName, 'TEMPLATE');
      expect(div.nodes[2].attributes['syntax'], 'Test');

      expect(testSyntax.log, [
        [model, '', 'bind', 'TEMPLATE'],
        [model, 'foo', 'text', null],
        [model, '', 'bind', 'TEMPLATE'],
        [model, 'foo', 'text', null],
      ]);
    } finally {
      TemplateElement.syntax.remove('Test');
    }
  });

  test('getInstanceModel', () {
    var model = toObservable([{'foo': 1}, {'foo': 2}, {'foo': 3}]
        .map(toSymbolMap));

    var testSyntax = new TestModelSyntax();
    testSyntax.altModels.addAll([{'foo': 'a'}, {'foo': 'b'}, {'foo': 'c'}]
        .map(toSymbolMap));

    TemplateElement.syntax['Test'] = testSyntax;
    try {

      var div = createTestHtml(
          '<template repeat syntax="Test">' +
          '{{ foo }}</template>');

      var template = div.nodes[0];
      recursivelySetTemplateModel(div, model);
      deliverChangeRecords();

      expect(div.nodes.length, 4);
      expect(div.nodes[0].tagName, 'TEMPLATE');
      expect(div.nodes[1].text, 'a');
      expect(div.nodes[2].text, 'b');
      expect(div.nodes[3].text, 'c');

      expect(testSyntax.log, [
        [template, model[0]],
        [template, model[1]],
        [template, model[2]],
      ]);

    } finally {
      TemplateElement.syntax.remove('Test');
    }
  });

  // Note: this test was original, not a port of an existing test.
  test('getInstanceFragment', () {
    var model = toSymbolMap({'foo': 'bar'});

    var testSyntax = new WhitespaceRemover();
    TemplateElement.syntax['Test'] = testSyntax;
    try {
      var div = createTestHtml(
          '''<template bind syntax="Test">
            {{ foo }}
            <template bind>
              {{ foo }}
            </template>
          </template>''');

      recursivelySetTemplateModel(div, model);
      deliverChangeRecords();

      expect(testSyntax.trimmed, 2);
      expect(testSyntax.removed, 1);

      expect(div.nodes.length, 4);
      expect(div.nodes.last.text, 'bar');
      expect(div.nodes[2].tagName, 'TEMPLATE');
      expect(div.nodes[2].attributes['syntax'], 'Test');

    } finally {
      TemplateElement.syntax.remove('Test');
    }
  });

  test('Basic', () {
    var model = toSymbolMap({'foo': 2, 'bar': 4});

    TemplateElement.syntax['2x'] = new TimesTwoSyntax();

    var div = createTestHtml(
        '<template bind syntax="2x">'
        '{{ foo }} + {{ 2x: bar }} + {{ 4x: bar }}</template>');
    recursivelySetTemplateModel(div, model);
    deliverChangeRecords();
    expect(div.nodes.length, 2);
    expect(div.nodes.last.text, '2 + 8 + ');

    model[const Symbol('foo')] = 4;
    model[const Symbol('bar')] = 8;
    deliverChangeRecords();
    expect(div.nodes.last.text, '4 + 16 + ');

    TemplateElement.syntax.remove('2x');
  });

  test('Different Sub-Template Syntax', () {
    var model = toSymbolMap({'foo': 'bar'});

    TemplateElement.syntax['Test'] = new TestBindingSyntax();
    TemplateElement.syntax['Test2'] = new TestBindingSyntax();

    var div = createTestHtml(
        '<template bind syntax="Test">{{ foo }}'
        '<template bind syntax="Test2">{{ foo }}</template></template>');
    recursivelySetTemplateModel(div, model);
    deliverChangeRecords();
    expect(div.nodes.length, 4);
    expect(div.nodes.last.text, 'bar');
    expect(div.nodes[2].tagName, 'TEMPLATE');
    expect(div.nodes[2].attributes['syntax'], 'Test2');

    var testLog = TemplateElement.syntax['Test'].log;
    var test2Log = TemplateElement.syntax['Test2'].log;

    expect(testLog, [
      [model, '', 'bind', 'TEMPLATE'],
      [model, 'foo', 'text', null],
      [model, '', 'bind', 'TEMPLATE']
    ]);

    expect(test2Log, [[model, 'foo', 'text', null]]);

    TemplateElement.syntax.remove('Test');
    TemplateElement.syntax.remove('Test2');
  });
}

// TODO(jmesserly): mocks would be cleaner here.

class TestBindingSyntax extends CustomBindingSyntax {
  var log = [];

  getBinding(model, String path, String name, Node node) {
    log.add([model, path, name, node is Element ? node.tagName : null]);
  }
}

class TestModelSyntax extends CustomBindingSyntax {
  var log = [];
  var altModels = new ListQueue();

  getInstanceModel(template, model) {
    log.add([template, model]);
    return altModels.removeFirst();
  }
}

// Note: this isn't a very smart whitespace handler. A smarter one would only
// trim indentation, not all whitespace.
// See "trimOrCompact" in the web_ui Pub package.
class WhitespaceRemover extends CustomBindingSyntax {
  int trimmed = 0;
  int removed = 0;

  DocumentFragment getInstanceFragment(Element template) {
    var instance = template.createInstance();
    var walker = new TreeWalker(instance, NodeFilter.SHOW_TEXT);

    var toRemove = [];
    while (walker.nextNode() != null) {
      var node = walker.currentNode;
      var text = node.text.replaceAll('\n', '').trim();
      if (text.length != node.text.length) {
        if (text.length == 0) {
          toRemove.add(node);
        } else {
          trimmed++;
          node.text = text;
        }
      }
    }

    for (var node in toRemove) node.remove();
    removed += toRemove.length;

    return instance;
  }
}


class TimesTwoSyntax extends CustomBindingSyntax {
  getBinding(model, path, name, node) {
    path = path.trim();
    if (!path.startsWith('2x:')) return null;

    path = path.substring(3);
    return new CompoundBinding((values) => values['value'] * 2)
        ..bind('value', model, path);
  }
}
