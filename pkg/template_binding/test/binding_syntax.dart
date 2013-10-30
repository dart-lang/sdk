// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library template_binding.test.binding_syntax;

import 'dart:collection';
import 'dart:html';
import 'package:template_binding/template_binding.dart';
import 'package:observe/observe.dart';
import 'package:unittest/html_config.dart';
import 'package:unittest/unittest.dart';
import 'utils.dart';

// Note: this test is executed by template_element_test.dart

syntaxTests(FooBarModel fooModel([foo, bar])) {
  observeTest('prepareBinding', () {
    var model = fooModel('bar');
    var testSyntax = new TestBindingSyntax();
    var div = createTestHtml(
        '<template bind>{{ foo }}'
          '<template bind>{{ foo }}</template>'
        '</template>');
    recursivelySetTemplateModel(div, model, testSyntax);
    performMicrotaskCheckpoint();
    expect(div.nodes.length, 4);
    expect(div.nodes.last.text, 'bar');
    expect(div.nodes[2].tagName, 'TEMPLATE');
    expect(testSyntax.log, [
      ['prepare', '', 'bind', 'TEMPLATE'],
      ['bindFn', model, 'TEMPLATE', 0],
      ['prepare', 'foo', 'text', 'TEXT'],
      ['prepare', '', 'bind', 'TEMPLATE'],
      ['bindFn', model, 'TEXT', 2],
      ['bindFn', model, 'TEMPLATE', 3],
      ['prepare', 'foo', 'text', 'TEXT'],
      ['bindFn', model, 'TEXT', 6],
    ]);
  });

  observeTest('prepareInstanceModel', () {
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
      ['prepare', template],
      ['bindFn', model[0]],
      ['bindFn', model[1]],
      ['bindFn', model[2]],
    ]);
  });

  observeTest('prepareInstanceModel - reorder instances', () {
    var model = toObservable([0, 1, 2]);

    var div = createTestHtml('<template repeat>{{}}</template>');
    var template = div.firstChild;
    var delegate = new TestInstanceModelSyntax();

    recursivelySetTemplateModel(div, model, delegate);
    performMicrotaskCheckpoint();
    expect(delegate.prepareCount, 1);
    expect(delegate.callCount, 3);

    // Note: intentionally mutate in place.
    model.replaceRange(0, model.length, model.reversed.toList());
    performMicrotaskCheckpoint();
    expect(delegate.prepareCount, 1);
    expect(delegate.callCount, 3);
  });

  observeTest('prepareInstancePositionChanged', () {
    var model = toObservable(['a', 'b', 'c']);

    var div = createTestHtml('<template repeat>{{}}</template>');
    var delegate = new TestPositionChangedSyntax();

    var template = div.nodes[0];
    recursivelySetTemplateModel(div, model, delegate);
    performMicrotaskCheckpoint();

    expect(div.nodes.length, 4);
    expect(div.nodes[0].tagName, 'TEMPLATE');
    expect(div.nodes[1].text, 'a');
    expect(div.nodes[2].text, 'b');
    expect(div.nodes[3].text, 'c');

    expect(delegate.log, [
      ['prepare', template],
      ['bindFn', model[0], 0],
      ['bindFn', model[1], 1],
      ['bindFn', model[2], 2],
    ]);

    delegate.log.clear();

    model.removeAt(1);
    performMicrotaskCheckpoint();

    expect(delegate.log, [['bindFn', 'c', 1]], reason: 'removed item');

    expect(div.nodes.skip(1).map((n) => n.text), ['a', 'c']);
  });

  observeTest('Basic', () {
    var model = fooModel(2, 4);
    var div = createTestHtml(
        '<template bind>'
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

  // Note: issue-141 test not included here as it's not related to the
  // BindingDelegate
}

// TODO(jmesserly): mocks would be cleaner here.

class TestBindingSyntax extends BindingDelegate {
  var log = [];

  prepareBinding(String path, String name, Node node) {
    var tagName = node is Element ? node.tagName : 'TEXT';
    int id = log.length;
    log.add(['prepare', path, name, tagName]);
    final outerNode = node;
    return (model, node) {
      var tagName = node is Element ? node.tagName : 'TEXT';
      log.add(['bindFn', model, tagName, id]);
    };
  }
}

class TestModelSyntax extends BindingDelegate {
  var log = [];
  var altModels = new ListQueue();

  prepareInstanceModel(template) {
    log.add(['prepare', template]);
    return (model) {
      log.add(['bindFn', model]);
      return altModels.removeFirst();
    };
  }
}

class TestInstanceModelSyntax extends BindingDelegate {
  int prepareCount = 0;
  int callCount = 0;
  prepareInstanceModel(template) {
    prepareCount++;
    return (model) {
      callCount++;
      return model;
    };
  }
}


class TestPositionChangedSyntax extends BindingDelegate {
  var log = [];

  prepareInstancePositionChanged(template) {
    int id = log.length;
    log.add(['prepare', template]);
    return (templateInstance, index) {
      log.add(['bindFn', templateInstance.model, index]);
    };
  }
}


class TimesTwoSyntax extends BindingDelegate {
  prepareBinding(path, name, node) {
    path = path.trim();
    if (!path.startsWith('2x:')) return null;

    path = path.substring(3);
    return (model, _) {
      return new PathObserver(model, path, computeValue: (x) => 2 * x);
    };
  }
}
