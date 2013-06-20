// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:mdv_observe/mdv_observe.dart';
import 'package:unittest/unittest.dart';

// This file contains code ported from:
// https://github.com/rafaelw/ChangeSummary/blob/master/tests/test.js

main() {
  group('PathObserver', observePathTests);
}

observePath(obj, path) => new PathObserver(obj, path);

sym(x) => new Symbol(x);

toSymbolMap(Map map) {
  var result = new ObservableMap.linked();
  map.forEach((key, value) {
    if (value is Map) value = toSymbolMap(value);
    result[new Symbol(key)] = value;
  });
  return result;
}

observePathTests() {

  test('Degenerate Values', () {
    expect(observePath(null, '').value, null);
    expect(observePath(123, '').value, 123);
    expect(observePath(123, 'foo.bar.baz').value, null);

    // shouldn't throw:
    observePath(123, '').values.listen((_) {}).cancel();
    observePath(null, '').value = null;
    observePath(123, '').value = 42;
    observePath(123, 'foo.bar.baz').value = 42;

    var foo = {};
    expect(observePath(foo, '').value, foo);

    foo = new Object();
    expect(observePath(foo, '').value, foo);

    expect(observePath(foo, 'a/3!').value, null);
  });

  test('get value at path ObservableBox', () {
    var obj = new ObservableBox(new ObservableBox(new ObservableBox(1)));

    expect(observePath(obj, '').value, obj);
    expect(observePath(obj, 'value').value, obj.value);
    expect(observePath(obj, 'value.value').value, obj.value.value);
    expect(observePath(obj, 'value.value.value').value, 1);

    obj.value.value.value = 2;
    expect(observePath(obj, 'value.value.value').value, 2);

    obj.value.value = new ObservableBox(3);
    expect(observePath(obj, 'value.value.value').value, 3);

    obj.value = new ObservableBox(4);
    expect(observePath(obj, 'value.value.value').value, null);
    expect(observePath(obj, 'value.value').value, 4);
  });


  test('get value at path ObservableMap', () {
    var obj = toSymbolMap({'a': {'b': {'c': 1}}});

    expect(observePath(obj, '').value, obj);
    expect(observePath(obj, 'a').value, obj[sym('a')]);
    expect(observePath(obj, 'a.b').value, obj[sym('a')][sym('b')]);
    expect(observePath(obj, 'a.b.c').value, 1);

    obj[sym('a')][sym('b')][sym('c')] = 2;
    expect(observePath(obj, 'a.b.c').value, 2);

    obj[sym('a')][sym('b')] = toSymbolMap({'c': 3});
    expect(observePath(obj, 'a.b.c').value, 3);

    obj[sym('a')] = toSymbolMap({'b': 4});
    expect(observePath(obj, 'a.b.c').value, null);
    expect(observePath(obj, 'a.b').value, 4);
  });

  test('set value at path', () {
    var obj = toSymbolMap({});
    observePath(obj, 'foo').value = 3;
    expect(obj[sym('foo')], 3);

    var bar = toSymbolMap({ 'baz': 3 });
    observePath(obj, 'bar').value = bar;
    expect(obj[sym('bar')], bar);

    observePath(obj, 'bar.baz.bat').value = 'not here';
    expect(observePath(obj, 'bar.baz.bat').value, null);
  });

  test('set value back to same', () {
    var obj = toSymbolMap({});
    var path = observePath(obj, 'foo');
    var values = [];
    path.values.listen((v) { values.add(v); });

    path.value = 3;
    expect(obj[sym('foo')], 3);
    expect(path.value, 3);

    observePath(obj, 'foo').value = 2;
    deliverChangeRecords();
    expect(path.value, 2);
    expect(observePath(obj, 'foo').value, 2);

    observePath(obj, 'foo').value = 3;
    deliverChangeRecords();
    expect(path.value, 3);

    deliverChangeRecords();
    expect(values, [2, 3]);
  });

  test('Observe and Unobserve - Paths', () {
    var arr = toSymbolMap({});

    arr[sym('foo')] = 'bar';
    var fooValues = [];
    var fooPath = observePath(arr, 'foo');
    var fooSub = fooPath.values.listen((v) {
      fooValues.add(v);
    });
    arr[sym('foo')] = 'baz';
    arr[sym('bat')] = 'bag';
    var batValues = [];
    var batPath = observePath(arr, 'bat');
    var batSub = batPath.values.listen((v) {
      batValues.add(v);
    });

    deliverChangeRecords();
    expect(fooValues, ['baz']);
    expect(batValues, []);

    arr[sym('foo')] = 'bar';
    fooSub.cancel();
    arr[sym('bat')] = 'boo';
    batSub.cancel();
    arr[sym('bat')] = 'boot';

    deliverChangeRecords();
    expect(fooValues, ['baz']);
    expect(batValues, []);
  });

  test('Path Value With Indices', () {
    var model = toObservable([]);
    observePath(model, '0').values.listen(expectAsync1((v) {
      expect(v, 123);
    }));
    model.add(123);
  });

  test('Path Observation', () {
    var model = new TestModel(const Symbol('a'),
        new TestModel(const Symbol('b'),
            new TestModel(const Symbol('c'), 'hello, world')));

    var path = observePath(model, 'a.b.c');
    var lastValue = null;
    var sub = path.values.listen((v) { lastValue = v; });

    model.value.value.value = 'hello, mom';

    expect(lastValue, null);
    deliverChangeRecords();
    expect(lastValue, 'hello, mom');

    model.value.value = new TestModel(const Symbol('c'), 'hello, dad');
    deliverChangeRecords();
    expect(lastValue, 'hello, dad');

    model.value = new TestModel(const Symbol('b'),
        new TestModel(const Symbol('c'), 'hello, you'));
    deliverChangeRecords();
    expect(lastValue, 'hello, you');

    model.value.value = 1;
    deliverChangeRecords();
    expect(lastValue, null);

    // Stop observing
    sub.cancel();

    model.value.value = new TestModel(const Symbol('c'),
        'hello, back again -- but not observing');
    deliverChangeRecords();
    expect(lastValue, null);

    // Resume observing
    sub = path.values.listen((v) { lastValue = v; });

    model.value.value.value = 'hello. Back for reals';
    deliverChangeRecords();
    expect(lastValue, 'hello. Back for reals');
  });

  test('observe map', () {
    var model = toSymbolMap({'a': 1});
    var path = observePath(model, 'a');

    var values = [path.value];
    var sub = path.values.listen((v) { values.add(v); });
    expect(values, [1]);

    model[sym('a')] = 2;
    deliverChangeRecords();
    expect(values, [1, 2]);

    sub.cancel();
    model[sym('a')] = 3;
    deliverChangeRecords();
    expect(values, [1, 2]);
  });
}

class TestModel extends ObservableBase {
  final Symbol fieldName;
  var _value;

  TestModel(this.fieldName, [initialValue]) : _value = initialValue;

  get value => _value;

  void set value(newValue) {
    _value = notifyPropertyChange(fieldName, _value, newValue);
  }

  getValueWorkaround(key) {
    if (key == fieldName) return value;
    return null;
  }
  void setValueWorkaround(key, newValue) {
    if (key == fieldName) value = newValue;
  }

  toString() => '#<$runtimeType $fieldName: $_value>';
}
