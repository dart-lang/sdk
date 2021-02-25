// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import "package:expect/expect.dart";

class MyEntry extends LinkedListEntry<MyEntry> {
  final int value;

  MyEntry(int this.value);

  String toString() => value.toString();

  int get hashCode => value.hashCode;
  bool operator ==(Object o) => o is MyEntry && value == o.value;
}

void testPreviousNext() {
  var list = LinkedList<MyEntry>();
  Expect.throws(() => list.first);
  Expect.throws(() => list.last);
  Expect.equals(0, list.length);

  for (int i = 0; i < 3; i++) {
    list.add(MyEntry(i));
  }
  Expect.equals(3, list.length);

  var entry = list.first;
  Expect.isNull(entry.previous);
  Expect.equals(0, entry.value);
  entry = entry.next!;
  Expect.equals(1, entry.value);
  entry = entry.next!;
  Expect.equals(2, entry.value);
  Expect.isNull(entry.next);
  entry = entry.previous!;
  Expect.equals(1, entry.value);
  entry = entry.previous!;
  Expect.equals(0, entry.value);
  Expect.isNull(entry.previous);
}

void testUnlinked() {
  var unlinked = MyEntry(0);
  Expect.isNull(unlinked.previous);
  Expect.isNull(unlinked.next);
  var list = LinkedList<MyEntry>();
  list.add(unlinked);
  Expect.isNull(unlinked.previous);
  Expect.isNull(unlinked.next);
  list.remove(unlinked);
  Expect.isNull(unlinked.previous);
  Expect.isNull(unlinked.next);
  list.add(unlinked);
  list.add(MyEntry(1));
  Expect.isNull(unlinked.previous);
  Expect.equals(1, unlinked.next!.value);
  list.remove(unlinked);
  Expect.isNull(unlinked.previous);
  Expect.isNull(unlinked.next);
  list.add(unlinked);
  Expect.isNull(unlinked.next);
  Expect.equals(1, unlinked.previous!.value);
}

void testInsert() {
  // Insert last.
  var list = LinkedList<MyEntry>();
  for (int i = 0; i < 10; i++) {
    list.add(MyEntry(i));
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
    list.addFirst(MyEntry(i));
  }

  Expect.equals(10, list.length);

  i = 10;
  for (var entry in list) {
    Expect.equals(--i, entry.value);
  }
  Expect.equals(0, i);

  list.clear();

  // Insert after.
  list.addFirst(MyEntry(0));
  for (int i = 1; i < 10; i++) {
    list.last.insertAfter(MyEntry(i));
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
  list.addFirst(MyEntry(0));
  for (int i = 1; i < 10; i++) {
    list.first.insertBefore(MyEntry(i));
  }

  Expect.equals(10, list.length);

  i = 10;
  for (var entry in list) {
    Expect.equals(--i, entry.value);
  }
  Expect.equals(0, i);

  list.clear();
}

void testRemove() {
  var list = LinkedList<MyEntry>();
  for (int i = 0; i < 10; i++) {
    list.add(MyEntry(i));
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

void testContains() {
  var list = LinkedList<MyEntry>();
  var entry5 = MyEntry(5);

  // Empty lists contains nothing.
  Expect.isFalse(list.contains(null));
  Expect.isFalse(list.contains(Object()));
  Expect.isFalse(list.contains(entry5));

  // Works for singleton lists.
  list.add(MyEntry(0));
  Expect.isTrue(list.contains(list.first));
  Expect.isFalse(list.contains(null));
  Expect.isFalse(list.contains(Object()));
  Expect.isFalse(list.contains(entry5));

  // Works for larger lists.
  for (int i = 1; i < 10; i++) {
    list.add(MyEntry(i));
  }
  for (var entry in list) {
    Expect.isTrue(list.contains(entry));
  }
  Expect.isFalse(list.contains(Object()));
  Expect.isFalse(list.contains(null));
  Expect.isFalse(list.contains(entry5));
  // Based on identity, not equality.
  Expect.equals(entry5, list.elementAt(5));
}

void testBadAdd() {
  var list1 = LinkedList<MyEntry>();
  list1.addFirst(MyEntry(0));

  var list2 = LinkedList<MyEntry>();
  Expect.throws(() => list2.addFirst(list1.first));

  Expect.throws(() => MyEntry(0).unlink());
}

void testConcurrentModificationError() {
  test(function(LinkedList<MyEntry> ll)) {
    var ll = LinkedList<MyEntry>();
    for (int i = 0; i < 10; i++) {
      ll.add(MyEntry(i));
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

void main() {
  testPreviousNext();
  testUnlinked();
  testInsert();
  testRemove();
  testContains();
  testBadAdd();
  testConcurrentModificationError();
}
