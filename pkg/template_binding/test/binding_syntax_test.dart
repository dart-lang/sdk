// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library template_binding.test.binding_syntax_test;

import 'dart:collection';
import 'dart:html';
import 'package:template_binding/template_binding.dart';
import 'package:observe/observe.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';
import 'utils.dart';

// Note: this file ported from
// https://github.com/toolkitchen/mdv/blob/master/tests/syntax.js

main() {
  useHtmlConfiguration();

  group('Syntax FooBarModel', () {
    syntaxTests(([f, b]) => new FooBarModel(f, b));
  });
  group('Syntax FooBarNotifyModel', () {
    syntaxTests(([f, b]) => new FooBarNotifyModel(f, b));
  });
}

syntaxTests(FooBarModel fooModel([foo, bar])) {
  setUp(() {
    document.body.append(testDiv = new DivElement());
  });

  tearDown(() {
    testDiv.remove();
    testDiv = null;
  });

  observeTest('Registration', () {
    var model = fooModel('bar');
    var testSyntax = new TestBindingSyntax();
    var div = createTestHtml('<template bind>{{ foo }}'
        '<template bind>{{ foo }}</template></template>');
    recursivelySetTemplateModel(div, model, testSyntax);
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 4);
    expect(div.nodes.last.text, 'bar');
    expect(div.nodes[2].tagName, 'TEMPLATE');
    expect(testSyntax.log, [
      [model, '', 'bind', 'TEMPLATE'],
      [model, 'foo', 'text', null],
      [model, '', 'bind', 'TEMPLATE'],
      [model, 'foo', 'text', null],
    ]);
  });

  observeTest('getInstanceModel', () {
    var model = toObservable([fooModel(1), fooModel(2), fooModel(3)]);

    var testSyntax = new TestModelSyntax();
    testSyntax.altModels.addAll([fooModel('a'), fooModel('b'), fooModel('c')]);

    var div = createTestHtml('<template repeat>{{ foo }}</template>');

    var template = div.nodes[0];
    recursivelySetTemplateModel(div, model, testSyntax);
    performMicrotaskCheckpoint();

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
  });

  observeTest('getInstanceModel - reorder instances', () {
    var model = toObservable([0, 1, 2]);

    var div = createTestHtml('<template repeat syntax="Test">{{}}</template>');
    var template = div.firstChild;
    var delegate = new TestInstanceModelSyntax();

    recursivelySetTemplateModel(div, model, delegate);
    performMicrotaskCheckpoint();
    expect(delegate.count, 3);

    // Note: intentionally mutate in place.
    model.replaceRange(0, model.length, model.reversed.toList());
    performMicrotaskCheckpoint();
    expect(delegate.count, 3);
  });

  observeTest('Basic', () {
    var model = fooModel(2, 4);
    var div = createTestHtml(
        '<template bind syntax="2x">'
        '{{ foo }} + {{ 2x: bar }} + {{ 4x: bar }}</template>');
    recursivelySetTemplateModel(div, model, new TimesTwoSyntax());
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 2);
    expect(div.nodes.last.text, '2 + 8 + ');

    model.foo = 4;
    model.bar = 8;
    performMicrotaskCheckpoint();
    expect(div.nodes.last.text, '4 + 16 + ');
  });
}

// TODO(jmesserly): mocks would be cleaner here.

class TestBindingSyntax extends BindingDelegate {
  var log = [];

  getBinding(model, String path, String name, node) {
    log.add([model, path, name, node is Element ? node.tagName : null]);
  }
}

class TestModelSyntax extends BindingDelegate {
  var log = [];
  var altModels = new ListQueue();

  getInstanceModel(template, model) {
    log.add([template, model]);
    return altModels.removeFirst();
  }
}

class TestInstanceModelSyntax extends BindingDelegate {
  int count = 0;
  getInstanceModel(template, model) {
    count++;
    return model;
  }
}

// Note: this isn't a very smart whitespace handler. A smarter one would only
// trim indentation, not all whitespace.
// See "trimOrCompact" in the web_ui Pub package.
class WhitespaceRemover extends BindingDelegate {
  int trimmed = 0;
  int removed = 0;

  DocumentFragment getInstanceFragment(Element template) {
    var instance = templateBind(template).createInstance();
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

class TimesTwoSyntax extends BindingDelegate {
  getBinding(model, path, name, node) {
    path = path.trim();
    if (!path.startsWith('2x:')) return null;

    path = path.substring(3);
    return new CompoundBinding((values) => values['value'] * 2)
        ..bind('value', model, path);
  }
}
