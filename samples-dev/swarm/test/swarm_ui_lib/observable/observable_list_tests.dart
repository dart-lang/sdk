// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observable_tests;

testObservableList() {
  test('ObservableList', () {
    final arr = new ObservableList<int>();

    // Add some initial data before listening
    arr.add(1);
    arr.add(2);
    arr.add(3);
    arr.add(1);
    arr.add(3);
    arr.add(4);

    expect(arr, orderedEquals([1, 2, 3, 1, 3, 4]));

    // Add a listener that saves the events
    EventSummary res = null;
    arr.addChangeListener((summary) {
      expect(res, isNull);
      res = summary;
      expect(res, isNotNull);
    });

    // execute some code with readonly operations only
    expect(res, isNull);
    bool called = false;
    EventBatch.wrap((e) {
      expect(arr, hasLength(6));
      expect(arr[0], equals(1));
      // TODO(sigmund): why we need write startIndex? it should be optional.
      expect(arr.indexOf(4, 0), equals(5));
      expect(arr.indexOf(1, 0), equals(0));
      expect(arr.indexOf(1, 1), equals(3));
      // TODO(rnystrom): Get rid of second arg when lastIndexOf has default.
      expect(arr.lastIndexOf(1, arr.length - 1), equals(3));
      expect(arr.last, equals(4));
      final copy = new List<int>();
      arr.forEach((i) {
        copy.add(i);
      });
      expect(copy, orderedEquals([1, 2, 3, 1, 3, 4]));
      called = true;
    })(null);
    expect(called, isTrue);
    expect(res, isNull); // no change from read-only operators

    // execute some code with mutations
    expect(res, isNull);
    called = false;
    expect(arr, orderedEquals([1, 2, 3, 1, 3, 4]));
    EventBatch.wrap((e) {
      arr.add(5); // 1 2 3 1 3 4(5)
      arr.add(6); // 1 2 3 1 3 4 5(6)
      arr[1] = arr[arr.length - 1]; // 1(6)3 1 3 4 5 6
      arr.add(7); // 1 6 3 1 3 4 5 6(7)
      arr[5] = arr[8]; // 1 6 3 1 3(7)5 6 7
      arr.add(42); // 1 6 3 1 3 7 5 6 7(42)
      expect(arr.removeAt(3), equals(1)); // 1 6 3( )3 7 5 6 7 42
      expect(arr.removeFirstElement(3), isTrue); // 1 6( )  3 7 5 6 7 42
      expect(arr.removeLast(), equals(42)); // 1 6     3 7 5 6 7(  )
      expect(arr.removeAllElements(6), equals(2)); // 1( )    3 7 5( )7
      called = true;
    })(null);
    expect(called, isTrue);
    expect(res, isNotNull);
    expect(res.events, hasLength(11));
    validateInsert(res.events[0], arr, null, 6, 5);
    validateInsert(res.events[1], arr, null, 7, 6);
    validateUpdate(res.events[2], arr, null, 1, 6, 2);
    validateInsert(res.events[3], arr, null, 8, 7);
    validateUpdate(res.events[4], arr, null, 5, 7, 4);
    validateInsert(res.events[5], arr, null, 9, 42);
    validateRemove(res.events[6], arr, null, 3, 1);
    validateRemove(res.events[7], arr, null, 2, 3);
    validateRemove(res.events[8], arr, null, 7, 42);
    validateRemove(res.events[9], arr, null, 1, 6);
    validateRemove(res.events[10], arr, null, 4, 6);
    expect(arr, orderedEquals([1, 3, 7, 5, 7]));

    res = null;
    expect(res, isNull);
    called = false;
    // execute global mutations like sort and clear
    EventBatch.wrap((e) {
      arr.add(1);
      arr.add(4);
      arr.add(10);
      arr.add(9);
      arr.sort((int a, int b) {
        return a - b;
      });
      called = true;
    })(null);
    expect(called, isTrue);
    expect(res, isNotNull);
    expect(res.events.length, equals(5));
    validateInsert(res.events[0], arr, null, 5, 1);
    validateInsert(res.events[1], arr, null, 6, 4);
    validateInsert(res.events[2], arr, null, 7, 10);
    validateInsert(res.events[3], arr, null, 8, 9);
    validateGlobal(res.events[4], arr);
    expect(arr, orderedEquals([1, 1, 3, 4, 5, 7, 7, 9, 10]));

    res = null;
    expect(res, isNull);
    called = false;
    EventBatch.wrap((e) {
      arr.clear();
      called = true;
    })(null);
    expect(called, isTrue);
    expect(res, isNotNull);
    expect(res.events, hasLength(1));
    validateGlobal(res.events[0], arr);
    expect(arr, orderedEquals([]));
  });
}
