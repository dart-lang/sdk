// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe_utils;

import 'dart:html';
import 'package:observe/observe.dart';
import 'package:unittest/unittest.dart';

import 'package:observe/src/microtask.dart';
export 'package:observe/src/microtask.dart';

final bool parserHasNativeTemplate = () {
  var div = new DivElement()..innerHtml = '<table><template>';
  return div.firstChild.firstChild != null &&
      div.firstChild.firstChild.tagName == 'TEMPLATE';
}();

toSymbolMap(Map map) {
  var result = new ObservableMap.linked();
  map.forEach((key, value) {
    if (value is Map) value = toSymbolMap(value);
    result[new Symbol(key)] = value;
  });
  return result;
}

recursivelySetTemplateModel(element, model, [delegate]) {
  for (var node in element.queryAll('*')) {
    if (node.isTemplate) {
      node.bindingDelegate = delegate;
      node.model = model;
    }
  }
}

dispatchEvent(type, target) {
  target.dispatchEvent(new Event(type, cancelable: false));
}

class FooBarModel extends ObservableBase {
  @observable var foo;
  @observable var bar;

  FooBarModel([this.foo, this.bar]);
}

@reflectable
class FooBarNotifyModel extends ChangeNotifierBase implements FooBarModel {
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

observeTest(name, testCase) => test(name, wrapMicrotask(testCase));

solo_observeTest(name, testCase) => solo_test(name, wrapMicrotask(testCase));
