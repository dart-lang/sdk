// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:observe/observe.dart';
import 'package:unittest/unittest.dart';
import 'observe_test_utils.dart';

main() => dirtyCheckZone().run(_runTests);

_runTests() {
  var list;
  var obs;
  var o1, o2, o3;
  var sub;
  int changes;

  setUp(() {
    list = toObservable([
      o1 = new TestModel()..a = (new TestModel()..b = 1),
      o2 = new TestModel()..a = (new TestModel()..b = 2),
      o3 = new TestModel()..a = (new TestModel()..b = 3)]);
    obs = new ListPathObserver(list, 'a.b');
    changes = 0;
    sub = obs.changes.listen((e) { changes++; });
  });

  tearDown(() {
    sub.cancel();
    list = obs = o1 = o2 = o3 = null;
  });

  test('list path observer noticed length changes', () {
    expect(o2.a.b, 2);
    expect(list[1].a.b, 2);
    return _nextMicrotask(null).then((_) {
      expect(changes, 0);
      list.removeAt(1);
    }).then(_nextMicrotask).then((_) {
      expect(changes, 1);
      expect(list[1].a.b, 3);
    });
  });

  test('list path observer delivers deep change', () {
    expect(o2.a.b, 2);
    expect(list[1].a.b, 2);
    int changes = 0;
    obs.changes.listen((e) { changes++; });
    return _nextMicrotask(null).then((_) {
      expect(changes, 0);
      o2.a.b = 4;
    }).then(_nextMicrotask).then((_) {
      expect(changes, 1);
      expect(list[1].a.b, 4);
      o1.a = new TestModel()..b = 5;
    }).then(_nextMicrotask).then((_) {
      expect(changes, 2);
      expect(list[0].a.b, 5);
    });
  });
}

_nextMicrotask(_) => new Future(() {});

@reflectable
class TestModel extends ChangeNotifier {
  var _a, _b;
  TestModel();

  get a => _a;
  void set a(newValue) { _a = notifyPropertyChange(#a, _a, newValue); }

  get b => _b;
  void set b(newValue) { _b = notifyPropertyChange(#b, _b, newValue); }
}
