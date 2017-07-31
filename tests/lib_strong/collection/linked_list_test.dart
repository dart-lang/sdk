// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import "package:expect/expect.dart";

class MyEntry extends LinkedListEntry<MyEntry> {
  final int value;

  MyEntry(int this.value);

  String toString() => value.toString();
}

testInsert() {
  // Insert last.
  var list = new LinkedList<MyEntry>();
  for (int i = 0; i < 10; i++) {
    list.add(new MyEntry(i));
  }

  Expect.equals(10, list.length);

  int i = 0;
  for (var entry in list) {
    Expect.equals(i, entry.value);
    i++;
  }

  Expect.equals(10, i);

  list.clear();

  // Insert first.
  for (int i = 0; i < 10; i++) {
    list.addFirst(new MyEntry(i));
  }

  Expect.equals(10, list.length);

  i = 10;
  for (var entry in list) {
    Expect.equals(--i, entry.value);
  }
  Expect.equals(0, i);

  list.clear();

  // Insert after.
  list.addFirst(new MyEntry(0));
  for (int i = 1; i < 10; i++) {
    list.last.insertAfter(new MyEntry(i));
  }

  Expect.equals(10, list.length);

  i = 0;
  for (var entry in list) {
    Expect.equals(i, entry.value);
    i++;
  }

  Expect.equals(10, i);

  list.clear();

  // Insert before.
  list.addFirst(new MyEntry(0));
  for (int i = 1; i < 10; i++) {
    list.first.insertBefore(new MyEntry(i));
  }

  Expect.equals(10, list.length);

  i = 10;
  for (var entry in list) {
    Expect.equals(--i, entry.value);
  }
  Expect.equals(0, i);

  list.clear();
}

testRemove() {
  var list = new LinkedList<MyEntry>();
  for (int i = 0; i < 10; i++) {
    list.add(new MyEntry(i));
  }

  Expect.equals(10, list.length);

  list.remove(list.skip(5).first);

  Expect.equals(9, list.length);

  int i = 0;
  for (var entry in list) {
    if (i == 5) i++;
    Expect.equals(i, entry.value);
    i++;
  }

  Expect.listEquals(
      [0, 1, 2, 3, 4, 6, 7, 8, 9], list.map((e) => e.value).toList());

  for (int i = 0; i < 9; i++) {
    list.first.unlink();
  }

  Expect.throws(() => list.first);

  Expect.equals(0, list.length);
}

testBadAdd() {
  var list1 = new LinkedList<MyEntry>();
  list1.addFirst(new MyEntry(0));

  var list2 = new LinkedList<MyEntry>();
  Expect.throws(() => list2.addFirst(list1.first));

  Expect.throws(() => new MyEntry(0).unlink());
}

testConcurrentModificationError() {
  test(function(LinkedList<MyEntry> ll)) {
    var ll = new LinkedList<MyEntry>();
    for (int i = 0; i < 10; i++) {
      ll.add(new MyEntry(i));
    }
    Expect.throws(() => function(ll), (e) => e is ConcurrentModificationError);
  }

  test((ll) {
    for (var x in ll) {
      ll.remove(x);
    }
  });
  test((ll) {
    ll.forEach((x) {
      ll.remove(x);
    });
  });
  test((ll) {
    ll.any((x) {
      ll.remove(x);
      return false;
    });
  });
  test((ll) {
    ll.every((x) {
      ll.remove(x);
      return true;
    });
  });
  test((ll) {
    ll.fold(0, (x, y) {
      ll.remove(y);
      return x;
    });
  });
  test((ll) {
    ll.reduce((x, y) {
      ll.remove(y);
      return x;
    });
  });
  test((ll) {
    ll.where((x) {
      ll.remove(x);
      return true;
    }).forEach((_) {});
  });
  test((ll) {
    ll.map((x) {
      ll.remove(x);
      return x;
    }).forEach((_) {});
  });
  test((ll) {
    ll.expand((x) {
      ll.remove(x);
      return [x];
    }).forEach((_) {});
  });
  test((ll) {
    ll.takeWhile((x) {
      ll.remove(x);
      return true;
    }).forEach((_) {});
  });
  test((ll) {
    ll.skipWhile((x) {
      ll.remove(x);
      return true;
    }).forEach((_) {});
  });
  test((ll) {
    bool first = true;
    ll.firstWhere((x) {
      ll.remove(x);
      if (!first) return true;
      return first = false;
    });
  });
  test((ll) {
    ll.lastWhere((x) {
      ll.remove(x);
      return true;
    });
  });
  test((ll) {
    bool first = true;
    ll.singleWhere((x) {
      ll.remove(x);
      if (!first) return false;
      return !(first = false);
    });
  });
}

main() {
  testInsert();
  testRemove();
  testBadAdd();
  testConcurrentModificationError();
}
