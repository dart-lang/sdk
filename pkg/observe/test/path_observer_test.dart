// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:observe/observe.dart';
import 'package:unittest/unittest.dart';
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
      expectPath(p, str, len) {
        var path = new PropertyPath(p);
        expect(path.toString(), str);
        expect(path.length, len, reason: 'expected path length $len for $path');
      }

      expectPath('/foo', '<invalid path>', 0);
      expectPath('abc', 'abc', 1);
      expectPath('a.b.c', 'a.b.c', 3);
      expectPath('a.b.c ', 'a.b.c', 3);
      expectPath(' a.b.c', 'a.b.c', 3);
      expectPath('  a.b.c   ', 'a.b.c', 3);
      expectPath('1.abc', '1.abc', 2);
      expectPath([#qux], 'qux', 1);
      expectPath([1, #foo, #bar], '1.foo.bar', 3);
    });

    test('caching and ==', () {
      var start = new PropertyPath('abc.0');
      for (int i = 1; i <= 100; i++) {
        expect(identical(new PropertyPath('abc.0'), start), true,
          reason: 'should return identical path');

        var p = new PropertyPath('abc.$i');
        expect(identical(p, start), false,
            reason: 'different paths should not be merged');
      }
      var end = new PropertyPath('abc.0');
      expect(identical(end, start), false,
          reason: 'first entry expired');
      expect(end, start, reason: 'different instances are equal');
    });

    test('hashCode equal', () {
      var a = new PropertyPath([#foo, 2, #bar]);
      var b = new PropertyPath('foo.2.bar');
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
    var path = new PathObserver(model, '0');
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

  TestModel();

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
