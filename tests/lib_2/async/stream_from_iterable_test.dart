// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test Stream.fromIterable.

import 'dart:async';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:async_helper/async_minitest.dart';

import 'event_helper.dart';

// Tests that various typed iterables that do not throw creates
// suitable streams.
void iterableTest<T>(Iterable<T> iterable) {
  asyncStart();
  List<T> expected = iterable.toList();
  Stream<T> stream = new Stream<T>.fromIterable(iterable);
  var events = <T>[];
  stream.listen(events.add, onDone: () {
    Expect.listEquals(expected, events, "fromIterable $iterable");
    asyncEnd();
  });
}

main() {
  asyncStart();

  iterableTest<Object>(<Object>[]);
  iterableTest<Null>(<Null>[]);
  iterableTest<Object>(<int>[1]);
  iterableTest<Object>(<Object>[1, "two", true, null]);
  iterableTest<int>(<int>[1, 2, 3, 4]);
  iterableTest<String>(<String>["one", "two", "three", "four"]);
  iterableTest<int>(new Iterable<int>.generate(1000, (i) => i));
  iterableTest<String>(
      new Iterable<int>.generate(1000, (i) => i).map((i) => "$i"));

  Iterable<int> iter = new Iterable.generate(25, (i) => i * 2);

  {
    // Test that the stream's .toList works.
    asyncStart();
    new Stream.fromIterable(iter).toList().then((actual) {
      List expected = iter.toList();
      Expect.equals(25, expected.length);
      Expect.listEquals(expected, actual);
      asyncEnd();
    });
  }

  {
    // Test that the stream's .map works.
    asyncStart();
    new Stream.fromIterable(iter).map((i) => i * 3).toList().then((actual) {
      List expected = iter.map((i) => i * 3).toList();
      Expect.listEquals(expected, actual);
      asyncEnd();
    });
  }

  {
    // Test that pause works.
    asyncStart();
    int ctr = 0;

    var stream = new Stream<int>.fromIterable(iter.map((x) {
      ctr++;
      return x;
    }));

    StreamSubscription subscription;
    var actual = [];
    subscription = stream.listen((int value) {
      actual.add(value);
      // Do a 10 ms pause during the playback of the iterable.
      Duration duration = const Duration(milliseconds: 10);
      if (value == 20) {
        asyncStart();
        int beforeCtr = ctr;
        subscription.pause(new Future.delayed(duration, () {}).whenComplete(() {
          Expect.equals(beforeCtr, ctr);
          asyncEnd();
        }));
      }
    }, onDone: () {
      Expect.listEquals(iter.toList(), actual);
      asyncEnd();
    });
  }

  {
    // Test that you can't listen twice..
    Stream stream = new Stream.fromIterable(iter);
    stream.listen((x) {}).cancel();
    Expect.throws<StateError>(() => stream.listen((x) {}));
  }

  {
    // Regression test for http://dartbug.com/14332.
    // This should succeed.
    var from = new Stream.fromIterable([1, 2, 3, 4, 5]);

    var c = new StreamController();
    var sink = c.sink;

    asyncStart(2);

    // if this goes first, test failed (hanged). Swapping addStream and toList
    // made failure go away.
    sink.addStream(from).then((_) {
      c.close();
      asyncEnd();
    });

    c.stream.toList().then((x) {
      Expect.listEquals([1, 2, 3, 4, 5], x);
      asyncEnd();
    });
  }

  {
    // Regression test for issue 14334 (#2)
    var from = new Stream.fromIterable([1, 2, 3, 4, 5]);

    // odd numbers as data events, even numbers as error events
    from = from.map((x) => x.isOdd ? x : throw x);

    var c = new StreamController();

    asyncStart();

    var data = [], errors = [];
    c.stream.listen(data.add, onError: errors.add, onDone: () {
      Expect.listEquals([1, 3, 5], data);
      Expect.listEquals([2, 4], errors);
      asyncEnd();
    });
    c.addStream(from).then((_) {
      c.close();
    });
  }

  {
    // Example from issue http://dartbug.com/33431.
    asyncStart();
    var asyncStarStream = () async* {
      yield 1;
      yield 2;
      throw "bad";
    }();
    collectEvents(asyncStarStream).then((events2) {
      Expect.listEquals(["value", 1, "value", 2, "error", "bad"], events2);
      asyncEnd();
    });

    Iterable<int> throwingIterable() sync* {
      yield 1;
      yield 2;
      throw "bad";
    }

    // Sanity check behavior.
    var it = throwingIterable().iterator;
    Expect.isTrue(it.moveNext());
    Expect.equals(1, it.current);
    Expect.isTrue(it.moveNext());
    Expect.equals(2, it.current);
    Expect.throws(it.moveNext, (e) => e == "bad");

    asyncStart();
    var syncStarStream = new Stream<int>.fromIterable(throwingIterable());
    collectEvents(syncStarStream).then((events1) {
      Expect.listEquals(["value", 1, "value", 2, "error", "bad"], events1);
      asyncEnd();
    });
  }

  {
    // Test error behavior. Changed when fixing issue 33431.
    // Iterable where "current" throws for third value, moveNext on fifth call.
    var m = new MockIterable<int>((n) {
      return n != 5 || (throw "moveNext");
    }, (n) {
      return n != 3 ? n : throw "current";
    });
    asyncStart();
    collectEvents(new Stream<int>.fromIterable(m)).then((events) {
      // Error on "current" does not stop iteration.
      // Error on "moveNext" does.
      Expect.listEquals([
        "value",
        1,
        "value",
        2,
        "error",
        "current",
        "value",
        4,
        "error",
        "moveNext"
      ], events);
      asyncEnd();
    });
  }

  asyncEnd();
}

// Collects value and error events in a list.
// Value events preceeded by "value", error events by "error".
// Completes on done event.
Future<List<Object>> collectEvents(Stream<Object> stream) {
  var c = new Completer<List<Object>>();
  var events = <Object>[];
  stream.listen((value) {
    events..add("value")..add(value);
  }, onError: (error) {
    events..add("error")..add(error);
  }, onDone: () {
    c.complete(events);
  });
  return c.future;
}

// Mock iterable.
// A `MockIterable<T>(f1, f2)` calls `f1` on `moveNext` calls with incrementing
// values starting from 1. Calls `f2` on `current` access, with the same integer
// as the most recent `f1` call.
class MockIterable<T> extends Iterable<T> {
  final bool Function(int) _onMoveNext;
  final T Function(int) _onCurrent;

  MockIterable(this._onMoveNext, this._onCurrent);

  Iterator<T> get iterator => MockIterator(_onMoveNext, _onCurrent);
}

class MockIterator<T> implements Iterator<T> {
  final bool Function(int) _onMoveNext;
  final T Function(int) _onCurrent;

  int _counter = 0;

  MockIterator(this._onMoveNext, this._onCurrent);

  bool moveNext() {
    _counter += 1;
    return _onMoveNext(_counter);
  }

  T get current {
    return _onCurrent(_counter);
  }
}
