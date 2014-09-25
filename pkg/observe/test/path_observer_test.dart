// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:observe/observe.dart';
import 'package:unittest/unittest.dart';
import 'package:observe/src/path_observer.dart'
    show getSegmentsOfPropertyPathForTesting,
         observerSentinelForTesting;

import 'observe_test_utils.dart';

// This file contains code ported from:
// https://github.com/rafaelw/ChangeSummary/blob/master/tests/test.js
// Dart note: getting invalid properties is an error, unlike in JS where it
// returns undefined. This difference comes up where we check for _throwsNSM in
// the tests below.
main() => dirtyCheckZone().run(() {
  group('PathObserver', observePathTests);

  group('PropertyPath', () {
    test('toString length', () {
      expectPath(p, str, len, [keys]) {
        var path = new PropertyPath(p);
        expect(path.toString(), str);
        expect(path.length, len, reason: 'expected path length $len for $path');
        if (keys == null) {
          expect(path.isValid, isFalse);
        } else {
          expect(path.isValid, isTrue);
          expect(getSegmentsOfPropertyPathForTesting(path), keys);
        }
      }

      expectPath('/foo', '<invalid path>', 0);
      expectPath('1.abc', '<invalid path>', 0);
      expectPath('abc', 'abc', 1, [#abc]);
      expectPath('a.b.c', 'a.b.c', 3, [#a, #b, #c]);
      expectPath('a.b.c ', 'a.b.c', 3, [#a, #b, #c]);
      expectPath(' a.b.c', 'a.b.c', 3, [#a, #b, #c]);
      expectPath('  a.b.c   ', 'a.b.c', 3, [#a, #b, #c]);
      expectPath('[1].abc', '[1].abc', 2, [1, #abc]);
      expectPath([#qux], 'qux', 1, [#qux]);
      expectPath([1, #foo, #bar], '[1].foo.bar', 3, [1, #foo, #bar]);
      expectPath([1, #foo, 'bar'], '[1].foo["bar"]', 3, [1, #foo, 'bar']);

      // From test.js: "path validity" test:

      expectPath('', '', 0, []);
      expectPath(' ', '', 0, []);
      expectPath(null, '', 0, []);
      expectPath('a', 'a', 1, [#a]);
      expectPath('a.b', 'a.b', 2, [#a, #b]);
      expectPath('a. b', 'a.b', 2, [#a, #b]);
      expectPath('a .b', 'a.b', 2, [#a, #b]);
      expectPath('a . b', 'a.b', 2, [#a, #b]);
      expectPath(' a . b ', 'a.b', 2, [#a, #b]);
      expectPath('a[0]', 'a[0]', 2, [#a, 0]);
      expectPath('a [0]', 'a[0]', 2, [#a, 0]);
      expectPath('a[0][1]', 'a[0][1]', 3, [#a, 0, 1]);
      expectPath('a [ 0 ] [ 1 ] ', 'a[0][1]', 3, [#a, 0, 1]);
      expectPath('[1234567890] ', '[1234567890]', 1, [1234567890]);
      expectPath(' [1234567890] ', '[1234567890]', 1, [1234567890]);
      expectPath('opt0', 'opt0', 1, [#opt0]);
      // Dart note: Modified to avoid a private Dart symbol:
      expectPath(r'$foo.$bar.baz_', r'$foo.$bar.baz_', 3,
          [#$foo, #$bar, #baz_]);
      // Dart note: this test is different because we treat ["baz"] always as a
      // indexing operation.
      expectPath('foo["baz"]', 'foo.baz', 2, [#foo, #baz]);
      expectPath('foo["b\\"az"]', 'foo["b\\"az"]', 2, [#foo, 'b"az']);
      expectPath("foo['b\\'az']", 'foo["b\'az"]', 2, [#foo, "b'az"]);
      expectPath([#a, #b], 'a.b', 2, [#a, #b]);
      expectPath([], '', 0, []);

      expectPath('.', '<invalid path>', 0);
      expectPath(' . ', '<invalid path>', 0);
      expectPath('..', '<invalid path>', 0);
      expectPath('a[4', '<invalid path>', 0);
      expectPath('a.b.', '<invalid path>', 0);
      expectPath('a,b', '<invalid path>', 0);
      expectPath('a["foo]', '<invalid path>', 0);
      expectPath('[0x04]', '<invalid path>', 0);
      expectPath('[0foo]', '<invalid path>', 0);
      expectPath('[foo-bar]', '<invalid path>', 0);
      expectPath('foo-bar', '<invalid path>', 0);
      expectPath('42', '<invalid path>', 0);
      expectPath('a[04]', '<invalid path>', 0);
      expectPath(' a [ 04 ]', '<invalid path>', 0);
      expectPath('  42   ', '<invalid path>', 0);
      expectPath('foo["bar]', '<invalid path>', 0);
      expectPath("foo['bar]", '<invalid path>', 0);
    });

    test('objects with toString are not supported', () {
      // Dart note: this was intentionally not ported. See path_observer.dart.
      expect(() => new PropertyPath([new Foo('a'), new Foo('b')]), throws);
    });

    test('invalid path returns null value', () {
      var path = new PropertyPath('a b');
      expect(path.isValid, isFalse);
      expect(path.getValueFrom({'a': {'b': 2}}), isNull);
    });


    test('caching and ==', () {
      var start = new PropertyPath('abc[0]');
      for (int i = 1; i <= 100; i++) {
        expect(identical(new PropertyPath('abc[0]'), start), true,
          reason: 'should return identical path');

        var p = new PropertyPath('abc[$i]');
        expect(identical(p, start), false,
            reason: 'different paths should not be merged');
      }
      var end = new PropertyPath('abc[0]');
      expect(identical(end, start), false,
          reason: 'first entry expired');
      expect(end, start, reason: 'different instances are equal');
    });

    test('hashCode equal', () {
      var a = new PropertyPath([#foo, 2, #bar]);
      var b = new PropertyPath('foo[2].bar');
      expect(identical(a, b), false, reason: 'only strings cached');
      expect(a, b, reason: 'same paths are equal');
      expect(a.hashCode, b.hashCode, reason: 'equal hashCodes');
    });

    test('hashCode not equal', () {
      expect(2.hashCode, isNot(3.hashCode),
          reason: 'test depends on 2 and 3 having different hashcodes');

      var a = new PropertyPath([2]);
      var b = new PropertyPath([3]);
      expect(a, isNot(b), reason: 'different paths');
      expect(a.hashCode, isNot(b.hashCode), reason: 'different hashCodes');
    });
  });

  group('CompoundObserver', compoundObserverTests);
});

observePathTests() {
  test('Degenerate Values', () {
    expect(new PathObserver(null, '').value, null);
    expect(new PathObserver(123, '').value, 123);
    expect(() => new PathObserver(123, 'foo.bar.baz').value, _throwsNSM('foo'));

    // shouldn't throw:
    new PathObserver(123, '')..open((_) {})..close();
    new PropertyPath('').setValueFrom(null, null);
    new PropertyPath('').setValueFrom(123, 42);
    expect(() => new PropertyPath('foo.bar.baz').setValueFrom(123, 42),
        _throwsNSM('foo'));
    var foo = {};
    expect(new PathObserver(foo, '').value, foo);

    foo = new Object();
    expect(new PathObserver(foo, '').value, foo);

    expect(new PathObserver(foo, 'a/3!').value, null);
  });

  test('get value at path ObservableBox', () {
    var obj = new ObservableBox(new ObservableBox(new ObservableBox(1)));

    expect(new PathObserver(obj, '').value, obj);
    expect(new PathObserver(obj, 'value').value, obj.value);
    expect(new PathObserver(obj, 'value.value').value, obj.value.value);
    expect(new PathObserver(obj, 'value.value.value').value, 1);

    obj.value.value.value = 2;
    expect(new PathObserver(obj, 'value.value.value').value, 2);

    obj.value.value = new ObservableBox(3);
    expect(new PathObserver(obj, 'value.value.value').value, 3);

    obj.value = new ObservableBox(4);
    expect(() => new PathObserver(obj, 'value.value.value').value,
        _throwsNSM('value'));
    expect(new PathObserver(obj, 'value.value').value, 4);
  });


  test('get value at path ObservableMap', () {
    var obj = toObservable({'a': {'b': {'c': 1}}});

    expect(new PathObserver(obj, '').value, obj);
    expect(new PathObserver(obj, 'a').value, obj['a']);
    expect(new PathObserver(obj, 'a.b').value, obj['a']['b']);
    expect(new PathObserver(obj, 'a.b.c').value, 1);

    obj['a']['b']['c'] = 2;
    expect(new PathObserver(obj, 'a.b.c').value, 2);

    obj['a']['b'] = toObservable({'c': 3});
    expect(new PathObserver(obj, 'a.b.c').value, 3);

    obj['a'] = toObservable({'b': 4});
    expect(() => new PathObserver(obj, 'a.b.c').value, _throwsNSM('c'));
    expect(new PathObserver(obj, 'a.b').value, 4);
  });

  test('set value at path', () {
    var obj = toObservable({});
    new PropertyPath('foo').setValueFrom(obj, 3);
    expect(obj['foo'], 3);

    var bar = toObservable({ 'baz': 3 });
    new PropertyPath('bar').setValueFrom(obj, bar);
    expect(obj['bar'], bar);

    expect(() => new PropertyPath('bar.baz.bat').setValueFrom(obj, 'not here'),
        _throwsNSM('bat='));
    expect(() => new PathObserver(obj, 'bar.baz.bat').value, _throwsNSM('bat'));
  });

  test('set value back to same', () {
    var obj = toObservable({});
    var path = new PathObserver(obj, 'foo');
    var values = [];
    path.open((x) {
      expect(x, path.value, reason: 'callback should get current value');
      values.add(x);
    });

    path.value = 3;
    expect(obj['foo'], 3);
    expect(path.value, 3);

    new PropertyPath('foo').setValueFrom(obj, 2);
    return new Future(() {
      expect(path.value, 2);
      expect(new PathObserver(obj, 'foo').value, 2);

      new PropertyPath('foo').setValueFrom(obj, 3);
    }).then(newMicrotask).then((_) {
      expect(path.value, 3);

    }).then(newMicrotask).then((_) {
      expect(values, [2, 3]);
    });
  });

  test('Observe and Unobserve - Paths', () {
    var arr = toObservable({});

    arr['foo'] = 'bar';
    var fooValues = [];
    var fooPath = new PathObserver(arr, 'foo');
    fooPath.open(fooValues.add);
    arr['foo'] = 'baz';
    arr['bat'] = 'bag';
    var batValues = [];
    var batPath = new PathObserver(arr, 'bat');
    batPath.open(batValues.add);

    return new Future(() {
      expect(fooValues, ['baz']);
      expect(batValues, []);

      arr['foo'] = 'bar';
      fooPath.close();
      arr['bat'] = 'boo';
      batPath.close();
      arr['bat'] = 'boot';

    }).then(newMicrotask).then((_) {
      expect(fooValues, ['baz']);
      expect(batValues, []);
    });
  });

  test('Path Value With Indices', () {
    var model = toObservable([]);
    var path = new PathObserver(model, '[0]');
    path.open(expectAsync((x) {
      expect(path.value, 123);
      expect(x, 123);
    }));
    model.add(123);
  });

  group('ObservableList', () {
    test('isNotEmpty', () {
      var model = new ObservableList();
      var path = new PathObserver(model, 'isNotEmpty');
      expect(path.value, false);

      path.open(expectAsync((_) {
        expect(path.value, true);
      }));
      model.add(123);
    });

    test('isEmpty', () {
      var model = new ObservableList();
      var path = new PathObserver(model, 'isEmpty');
      expect(path.value, true);

      path.open(expectAsync((_) {
        expect(path.value, false);
      }));
      model.add(123);
    });
  });

  for (var createModel in [() => new TestModel(), () => new WatcherModel()]) {
    test('Path Observation - ${createModel().runtimeType}', () {
      var model = createModel()..a =
          (createModel()..b = (createModel()..c = 'hello, world'));

      var path = new PathObserver(model, 'a.b.c');
      var lastValue = null;
      var errorSeen = false;
      runZoned(() {
        path.open((x) { lastValue = x; });
      }, onError: (e) {
        expect(e, _isNoSuchMethodOf('c'));
        errorSeen = true;
      });

      model.a.b.c = 'hello, mom';

      expect(lastValue, null);
      return new Future(() {
        expect(lastValue, 'hello, mom');

        model.a.b = createModel()..c = 'hello, dad';
      }).then(newMicrotask).then((_) {
        expect(lastValue, 'hello, dad');

        model.a = createModel()..b =
            (createModel()..c = 'hello, you');
      }).then(newMicrotask).then((_) {
        expect(lastValue, 'hello, you');

        model.a.b = 1;
        expect(errorSeen, isFalse);
      }).then(newMicrotask).then((_) {
        expect(errorSeen, isTrue);
        expect(lastValue, 'hello, you');

        // Stop observing
        path.close();

        model.a.b = createModel()..c = 'hello, back again -- but not observing';
      }).then(newMicrotask).then((_) {
        expect(lastValue, 'hello, you');

        // Resume observing
        new PathObserver(model, 'a.b.c').open((x) { lastValue = x; });

        model.a.b.c = 'hello. Back for reals';
      }).then(newMicrotask).then((_) {
        expect(lastValue, 'hello. Back for reals');
      });
    });
  }

  test('observe map', () {
    var model = toObservable({'a': 1});
    var path = new PathObserver(model, 'a');

    var values = [path.value];
    path.open(values.add);
    expect(values, [1]);

    model['a'] = 2;
    return new Future(() {
      expect(values, [1, 2]);

      path.close();
      model['a'] = 3;
    }).then(newMicrotask).then((_) {
      expect(values, [1, 2]);
    });
  });

  test('errors thrown from getter/setter', () {
    var model = new ObjectWithErrors();
    var observer = new PathObserver(model, 'foo');

    expect(() => observer.value, _throwsNSM('bar'));
    expect(model.getFooCalled, 1);

    expect(() { observer.value = 123; }, _throwsNSM('bar='));
    expect(model.setFooCalled, [123]);
  });

  test('object with noSuchMethod', () {
    var model = new NoSuchMethodModel();
    var observer = new PathObserver(model, 'foo');

    expect(observer.value, 42);
    observer.value = 'hi';
    expect(model._foo, 'hi');
    expect(observer.value, 'hi');

    expect(model.log, [#foo, const Symbol('foo='), #foo]);

    // These shouldn't throw
    observer = new PathObserver(model, 'bar');
    expect(observer.value, null, reason: 'path not found');
    observer.value = 42;
    expect(observer.value, null, reason: 'path not found');
  });

  test('object with indexer', () {
    var model = new IndexerModel();
    var observer = new PathObserver(model, 'foo');

    expect(observer.value, 42);
    expect(model.log, ['[] foo']);
    model.log.clear();

    observer.value = 'hi';
    expect(model.log, ['[]= foo hi']);
    expect(model._foo, 'hi');

    expect(observer.value, 'hi');

    // These shouldn't throw
    model.log.clear();
    observer = new PathObserver(model, 'bar');
    expect(observer.value, null, reason: 'path not found');
    expect(model.log, ['[] bar']);
    model.log.clear();

    observer.value = 42;
    expect(model.log, ['[]= bar 42']);
    model.log.clear();
  });

  test('regression for TemplateBinding#161', () {
    var model = toObservable({'obj': toObservable({'bar': false})});
    var ob1 = new PathObserver(model, 'obj.bar');
    var called = false;
    ob1.open(() { called = true; });

    var obj2 = new PathObserver(model, 'obj');
    obj2.open(() { model['obj']['bar'] = true; });

    model['obj'] = toObservable({ 'obj': 'obj' });

    return new Future(() {})
        .then((_) => expect(called, true));
  });
}

compoundObserverTests() {
  var model;
  var observer;
  bool called;
  var newValues;
  var oldValues;
  var observed;

  setUp(() {
    model = new TestModel(1, 2, 3);
    called = false;
  });

  callback(a, b, c) {
    called = true;
    newValues = a;
    oldValues = b;
    observed = c;
  }

  reset() {
    called = false;
    newValues = null;
    oldValues = null;
    observed = null;
  }

  expectNoChanges() {
    observer.deliver();
    expect(called, isFalse);
    expect(newValues, isNull);
    expect(oldValues, isNull);
    expect(observed, isNull);
  }

  expectCompoundPathChanges(expectedNewValues,
      expectedOldValues, expectedObserved, {deliver: true}) {
    if (deliver) observer.deliver();
    expect(called, isTrue);

    expect(newValues, expectedNewValues);
    var oldValuesAsMap = {};
    for (int i = 0; i < expectedOldValues.length; i++) {
      if (expectedOldValues[i] != null) {
        oldValuesAsMap[i] = expectedOldValues[i];
      }
    }
    expect(oldValues, oldValuesAsMap);
    expect(observed, expectedObserved);

    reset();
  }

  tearDown(() {
    observer.close();
    reset();
  });

  _path(s) => new PropertyPath(s);

  test('simple', () {
    observer = new CompoundObserver();
    observer.addPath(model, 'a');
    observer.addPath(model, 'b');
    observer.addPath(model, _path('c'));
    observer.open(callback);
    expectNoChanges();

    var expectedObs = [model, _path('a'), model, _path('b'), model, _path('c')];
    model.a = -10;
    model.b = 20;
    model.c = 30;
    expectCompoundPathChanges([-10, 20, 30], [1, 2, 3], expectedObs);

    model.a = 'a';
    model.c = 'c';
    expectCompoundPathChanges(['a', 20, 'c'], [-10, null, 30], expectedObs);

    model.a = 2;
    model.b = 3;
    model.c = 4;
    expectCompoundPathChanges([2, 3, 4], ['a', 20, 'c'], expectedObs);

    model.a = 'z';
    model.b = 'y';
    model.c = 'x';
    expect(observer.value, ['z', 'y', 'x']);
    expectNoChanges();

    expect(model.a, 'z');
    expect(model.b, 'y');
    expect(model.c, 'x');
    expectNoChanges();
  });

  test('reportChangesOnOpen', () {
    observer = new CompoundObserver(true);
    observer.addPath(model, 'a');
    observer.addPath(model, 'b');
    observer.addPath(model, _path('c'));

    model.a = -10;
    model.b = 20;
    observer.open(callback);
    var expectedObs = [model, _path('a'), model, _path('b'), model, _path('c')];
    expectCompoundPathChanges([-10, 20, 3], [1, 2, null], expectedObs,
        deliver: false);
  });

  test('All Observers', () {
    observer = new CompoundObserver();
    var pathObserver1 = new PathObserver(model, 'a');
    var pathObserver2 = new PathObserver(model, 'b');
    var pathObserver3 = new PathObserver(model, _path('c'));

    observer.addObserver(pathObserver1);
    observer.addObserver(pathObserver2);
    observer.addObserver(pathObserver3);
    observer.open(callback);

    var expectedObs = [observerSentinelForTesting, pathObserver1,
        observerSentinelForTesting, pathObserver2,
        observerSentinelForTesting, pathObserver3];
    model.a = -10;
    model.b = 20;
    model.c = 30;
    expectCompoundPathChanges([-10, 20, 30], [1, 2, 3], expectedObs);

    model.a = 'a';
    model.c = 'c';
    expectCompoundPathChanges(['a', 20, 'c'], [-10, null, 30], expectedObs);
  });

  test('Degenerate Values', () {
    observer = new CompoundObserver();
    observer.addPath(model, '.'); // invalid path
    observer.addPath('obj-value', ''); // empty path
    // Dart note: we don't port these two tests because in Dart we produce
    // exceptions for these invalid paths.
    // observer.addPath(model, 'foo'); // unreachable
    // observer.addPath(3, 'bar'); // non-object with non-empty path
    var values = observer.open(callback);
    expect(values.length, 2);
    expect(values[0], null);
    expect(values[1], 'obj-value');
    observer.close();
  });

  test('Heterogeneous', () {
    model.c = null;
    var otherModel = new TestModel(null, null, 3);

    twice(value) => value * 2;
    half(value) => value ~/ 2;

    var compound = new CompoundObserver();
    compound.addPath(model, 'a');
    compound.addObserver(new ObserverTransform(new PathObserver(model, 'b'),
                                               twice, setValue: half));
    compound.addObserver(new PathObserver(otherModel, 'c'));

    combine(values) => values[0] + values[1] + values[2];
    observer = new ObserverTransform(compound, combine);

    var newValue;
    transformCallback(v) {
      newValue = v;
      called = true;
    }
    expect(observer.open(transformCallback), 8);

    model.a = 2;
    model.b = 4;
    observer.deliver();
    expect(called, isTrue);
    expect(newValue, 13);
    called = false;

    model.b = 10;
    otherModel.c = 5;
    observer.deliver();
    expect(called, isTrue);
    expect(newValue, 27);
    called = false;

    model.a = 20;
    model.b = 1;
    otherModel.c = 5;
    observer.deliver();
    expect(called, isFalse);
    expect(newValue, 27);
  });
}

/// A matcher that checks that a closure throws a NoSuchMethodError matching the
/// given [name].
_throwsNSM(String name) => throwsA(_isNoSuchMethodOf(name));

/// A matcher that checkes whether an exception is a NoSuchMethodError matching
/// the given [name].
_isNoSuchMethodOf(String name) => predicate((e) =>
    e is NoSuchMethodError &&
    // Dart2js and VM error messages are a bit different, but they both contain
    // the name.
    ('$e'.contains("'$name'") || // VM error
     '$e'.contains('\'Symbol("$name")\''))); // dart2js error

class ObjectWithErrors {
  int getFooCalled = 0;
  List setFooCalled = [];
  @reflectable get foo {
    getFooCalled++;
    (this as dynamic).bar;
  }
  @reflectable set foo(value) {
    setFooCalled.add(value);
    (this as dynamic).bar = value;
  }
}

class NoSuchMethodModel {
  var _foo = 42;
  List log = [];

  // TODO(ahe): Remove @reflectable from here (once either of
  // http://dartbug.com/15408 or http://dartbug.com/15409 are fixed).
  @reflectable noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    log.add(name);
    if (name == #foo && invocation.isGetter) return _foo;
    if (name == const Symbol('foo=')) {
      _foo = invocation.positionalArguments[0];
      return null;
    }
    return super.noSuchMethod(invocation);
  }
}

class IndexerModel implements Indexable<String, dynamic> {
  var _foo = 42;
  List log = [];

  operator [](index) {
    log.add('[] $index');
    if (index == 'foo') return _foo;
  }

  operator []=(index, value) {
    log.add('[]= $index $value');
    if (index == 'foo') _foo = value;
  }
}

@reflectable
class TestModel extends ChangeNotifier {
  var _a, _b, _c;

  TestModel([this._a, this._b, this._c]);

  get a => _a;

  void set a(newValue) {
    _a = notifyPropertyChange(#a, _a, newValue);
  }

  get b => _b;

  void set b(newValue) {
    _b = notifyPropertyChange(#b, _b, newValue);
  }

  get c => _c;

  void set c(newValue) {
    _c = notifyPropertyChange(#c, _c, newValue);
  }
}

class WatcherModel extends Observable {
  // TODO(jmesserly): dart2js does not let these be on the same line:
  // @observable var a, b, c;
  @observable var a;
  @observable var b;
  @observable var c;

  WatcherModel();
}

class Foo {
  var value;
  Foo(this.value);
  String toString() => 'Foo$value';
}
