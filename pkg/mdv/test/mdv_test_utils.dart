// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe_utils;

import 'dart:async';
import 'package:observe/observe.dart';
import 'package:unittest/unittest.dart';

toSymbolMap(Map map) {
  var result = new ObservableMap.linked();
  map.forEach((key, value) {
    if (value is Map) value = toSymbolMap(value);
    result[new Symbol(key)] = value;
  });
  return result;
}

class FooBarModel extends ObservableBase {
  @observable var foo;
  @observable var bar;

  FooBarModel([this.foo, this.bar]);
}

class FooBarNotifyModel extends ChangeNotifierBase implements FooBarModel {
  var _foo;
  var _bar;

  FooBarNotifyModel([this._foo, this._bar]);

  get foo => _foo;
  set foo(value) {
    _foo = notifyPropertyChange(const Symbol('foo'), _foo, value);
  }

  get bar => _bar;
  set bar(value) {
    _bar = notifyPropertyChange(const Symbol('bar'), _bar, value);
  }
}

// TODO(jmesserly): this is a copy/paste from observe_test_utils.dart
// Is it worth putting it in its own package, or in an existing one?

void performMicrotaskCheckpoint() {
  Observable.dirtyCheck();

  while (_pending.length > 0) {
    var pending = _pending;
    _pending = [];

    for (var callback in pending) {
      try {
        callback();
      } catch (e, s) {
        new Completer().completeError(e, s);
      }
    }

    Observable.dirtyCheck();
  }
}

List<Function> _pending = [];

wrapMicrotask(void testCase()) {
  return () {
    runZonedExperimental(() {
      try {
        testCase();
      } finally {
        performMicrotaskCheckpoint();
      }
    }, onRunAsync: (callback) => _pending.add(callback));
  };
}

observeTest(name, testCase) => test(name, wrapMicrotask(testCase));

solo_observeTest(name, testCase) => solo_test(name, wrapMicrotask(testCase));
