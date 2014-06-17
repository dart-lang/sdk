// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library template_binding.test.binding_syntax;

import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'package:template_binding/template_binding.dart';
import 'package:observe/observe.dart';
import 'package:unittest/unittest.dart';
import 'utils.dart';

// Note: this test is executed by template_element_test.dart

syntaxTests(FooBarModel fooModel([foo, bar])) {
  test('prepareBinding', () {
    var model = fooModel('bar');
    var testSyntax = new TestBindingSyntax();
    var div = createTestHtml(
        '<template bind>{{ foo }}'
          '<template bind>{{ foo }}</template>'
        '</template>');
    var template = templateBind(div.firstChild);
    template
      ..model = model
      ..bindingDelegate = testSyntax;
    return new Future(() {
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
  });

  test('prepareInstanceModel', () {
    var model = toObservable([fooModel(1), fooModel(2), fooModel(3)]);

    var testSyntax = new TestModelSyntax();
    testSyntax.altModels.addAll([fooModel('a'), fooModel('b'), fooModel('c')]);

    var div = createTestHtml('<template repeat>{{ foo }}</template>');

    var template = div.nodes[0];
    templateBind(template)
      ..model = model
      ..bindingDelegate = testSyntax;
    return new Future(() {

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
  });

  test('prepareInstanceModel - reorder instances', () {
    var model = toObservable([0, 1, 2]);

    var div = createTestHtml('<template repeat>{{}}</template>');
    var template = div.firstChild;
    var delegate = new TestInstanceModelSyntax();

    templateBind(template)
      ..model = model
      ..bindingDelegate = delegate;
    return new Future(() {
      expect(delegate.prepareCount, 1);
      expect(delegate.callCount, 3);

      // Note: intentionally mutate in place.
      model.replaceRange(0, model.length, model.reversed.toList());
    }).then(endOfMicrotask).then((_) {
      expect(delegate.prepareCount, 1);
      expect(delegate.callCount, 3);
    });
  });

  test('prepareInstancePositionChanged', () {
    var model = toObservable(['a', 'b', 'c']);

    var div = createTestHtml('<template repeat>{{}}</template>');
    var delegate = new TestPositionChangedSyntax();

    var template = div.nodes[0];
    templateBind(template)
      ..model = model
      ..bindingDelegate = delegate;
    return new Future(() {

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
    }).then(endOfMicrotask).then((_) {

      expect(delegate.log, [['bindFn', 'c', 1]], reason: 'removed item');

      expect(div.nodes.skip(1).map((n) => n.text), ['a', 'c']);
    });
  });


  test('Update bindingDelegate with active template', () {
    var model = toObservable([1, 2]);

    var div = createTestHtml(
        '<template repeat>{{ \$index }} - {{ \$ident }}</template>');
    var template = templateBind(div.firstChild)
      ..bindingDelegate = new UpdateBindingDelegateA()
      ..model = model;

    return new Future(() {
      expect(div.nodes.length, 3);
      expect(div.nodes[1].text, 'i:0 - a:1');
      expect(div.nodes[2].text, 'i:1 - a:2');

      expect(() {
        template.bindingDelegate = new UpdateBindingDelegateB();
      }, throws);

      template.clear();
      expect(div.nodes.length, 1);

      template
        ..bindingDelegate = new UpdateBindingDelegateB()
        ..model = model;

      model.add(3);
    }).then(nextMicrotask).then((_) {
      // All instances should reflect delegateB
      expect(4, div.nodes.length);
      expect(div.nodes[1].text, 'I:0 - A:1-narg');
      expect(div.nodes[2].text, 'I:2 - A:2-narg');
      expect(div.nodes[3].text, 'I:4 - A:3-narg');
    });
  });

  test('Basic', () {
    var model = fooModel(2, 4);
    var div = createTestHtml(
        '<template bind>'
        '{{ foo }} + {{ 2x: bar }} + {{ 4x: bar }}</template>');
    var template = templateBind(div.firstChild);
    template
      ..model = model
      ..bindingDelegate = new TimesTwoSyntax();
    return new Future(() {
      expect(div.nodes.length, 2);
      expect(div.nodes.last.text, '2 + 8 + ');

      model.foo = 4;
      model.bar = 8;
    }).then(endOfMicrotask).then((_) {
      expect(div.nodes.last.text, '4 + 16 + ');
    });
  });

  test('CreateInstance', () {
    var delegateFoo = new SimpleTextDelegate('foo');
    var delegateBar = new SimpleTextDelegate('bar');

    var div = createTestHtml('<template bind>[[ 2x: bar ]]</template>');
    var template = templateBind(div.firstChild);
    template..bindingDelegate = delegateFoo..model = {};

    return new Future(() {
      expect(div.nodes.length, 2);
      expect(div.lastChild.text, 'foo');

      var fragment = template.createInstance({});
      expect(fragment.nodes.length, 1);
      expect(fragment.lastChild.text, 'foo');

      fragment = template.createInstance({}, delegateBar);
      expect(fragment.nodes.length, 1);
      expect(fragment.lastChild.text, 'bar');
    });
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
    return (model, node, oneTime) {
      var tagName = node is Element ? node.tagName : 'TEXT';
      log.add(['bindFn', model, tagName, id]);
      return oneTime ? new PropertyPath(path).getValueFrom(model) :
          new PathObserver(model, path);
    };
  }
}

class SimpleTextDelegate extends BindingDelegate {
  final String text;
  SimpleTextDelegate(this.text);

  prepareBinding(path, name, node) =>
      name != 'text' ? null : (_, __, ___) => text;
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
    return (model, _, oneTime) {
      return new ObserverTransform(new PathObserver(model, path), (x) => 2 * x);
    };
  }
}

class UpdateBindingDelegateBase extends BindingDelegate {
  bindingHandler(prefix, path) => (model, _, oneTime) =>
      new ObserverTransform(new PathObserver(model, path), (x) => '$prefix:$x');
}

class UpdateBindingDelegateA extends UpdateBindingDelegateBase {
  prepareBinding(path, name, node) {
    if (path == '\$ident') return bindingHandler('a', 'id');
    if (path == '\$index') return bindingHandler('i', 'index');
  }

  prepareInstanceModel(template) => (model) => toObservable({ 'id': model });

  prepareInstancePositionChanged(template) => (templateInstance, index) {
    templateInstance.model['index'] = index;
  };
}

class UpdateBindingDelegateB extends UpdateBindingDelegateBase {
  prepareBinding(path, name, node) {
    if (path == '\$ident') return bindingHandler('A', 'id');
    if (path == '\$index') return bindingHandler('I', 'index');
  }

  prepareInstanceModel(template) =>
      (model) => toObservable({ 'id': '${model}-narg' });


  prepareInstancePositionChanged(template) => (templateInstance, index) {
    templateInstance.model['index'] = 2 * index;
  };
}

