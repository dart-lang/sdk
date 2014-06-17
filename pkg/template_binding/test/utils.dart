// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library template_binding.test.utils;

import 'dart:async';
import 'dart:html';
import 'package:observe/observe.dart';

// Note: tests that import 'utils.dart' rely on the following line to make test
// smaller for dart2js and prevent timeouts in the test bots.
import 'package:observe/mirrors_used.dart';
import 'package:template_binding/template_binding.dart';
export 'package:observe/src/dirty_check.dart' show dirtyCheckZone;

/// A small method to help readability. Used to cause the next "then" in a chain
/// to happen in the next microtask:
///
///     future.then(endOfMicrotask).then(...)
endOfMicrotask(_) => new Future.value();

/// A small method to help readability. Used to cause the next "then" in a chain
/// to happen in the next microtask, after a timer:
///
///     future.then(nextMicrotask).then(...)
nextMicrotask(_) => new Future(() {});

final bool parserHasNativeTemplate = () {
  var div = new DivElement()..innerHtml = '<table><template>';
  return div.firstChild.firstChild != null &&
      div.firstChild.firstChild.tagName == 'TEMPLATE';
}();

recursivelySetTemplateModel(element, model, [delegate]) {
  for (var node in element.queryAll('*')) {
    if (isSemanticTemplate(node)) {
      templateBind(node)
          ..bindingDelegate = delegate
          ..model = model;
    }
  }
}

dispatchEvent(type, target) {
  target.dispatchEvent(new Event(type, cancelable: false));
}

class FooBarModel extends Observable {
  @observable var foo;
  @observable var bar;

  FooBarModel([this.foo, this.bar]);
}

@reflectable
class FooBarNotifyModel extends ChangeNotifier implements FooBarModel {
  var _foo;
  var _bar;

  FooBarNotifyModel([this._foo, this._bar]);

  get foo => _foo;
  set foo(value) {
    _foo = notifyPropertyChange(#foo, _foo, value);
  }

  get bar => _bar;
  set bar(value) {
    _bar = notifyPropertyChange(#bar, _bar, value);
  }
}

DivElement testDiv;

createTestHtml(s) {
  var div = new DivElement();
  div.setInnerHtml(s, treeSanitizer: new NullTreeSanitizer());
  testDiv.append(div);

  for (var node in div.querySelectorAll('*')) {
    if (isSemanticTemplate(node)) TemplateBindExtension.decorate(node);
  }

  return div;
}

createShadowTestHtml(s) {
  var div = new DivElement();
  var root = div.createShadowRoot();
  root.setInnerHtml(s, treeSanitizer: new NullTreeSanitizer());
  testDiv.append(div);

  for (var node in root.querySelectorAll('*')) {
    if (isSemanticTemplate(node)) TemplateBindExtension.decorate(node);
  }

  return root;
}

/**
 * Sanitizer which does nothing.
 */
class NullTreeSanitizer implements NodeTreeSanitizer {
  void sanitizeTree(Node node) {}
}

clearAllTemplates(node) {
  if (isSemanticTemplate(node)) {
    templateBind(node).clear();
  }
  for (var child = node.firstChild; child != null; child = child.nextNode) {
    clearAllTemplates(child);
  }
}
