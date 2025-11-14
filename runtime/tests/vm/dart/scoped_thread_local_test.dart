// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests ScopedThreadLocal.
//
// VMOptions=--experimental-shared-data

import 'package:dart_internal/isolate_group.dart' show IsolateGroup;
import 'dart:_vm' show ScopedThreadLocal;

import "package:expect/expect.dart";

/// A collection used to identify cyclic lists during `toString` calls.
@pragma('vm:shared')
final toStringVisiting = ScopedThreadLocal<List<Object>>(() => <Object>[]);

/// Check if we are currently visiting [object] in a `toString` call.
bool isToStringVisiting(List<Object> toStringVisitingValue, Object object) {
  for (int i = 0; i < toStringVisitingValue.length; i++) {
    if (identical(object, toStringVisitingValue[i])) return true;
  }
  return false;
}

void _iterablePartsToStrings(Iterable<Object> iterable, List<String> parts) {
  Iterator<Object> it = iterable.iterator;
  // Initial run of elements, at least headCount, and then continue until
  // passing at most lengthLimit characters.
  while (it.moveNext()) {
    if (it.current is Iterable<Object>) {
      parts.add(iterableToShortString(it.current as Iterable<Object>));
    } else {
      parts.add("${it.current}");
    }
  }
}

String iterableToShortString(
  Iterable<Object> iterable, [
  String leftDelimiter = '(',
  String rightDelimiter = ')',
]) {
  return toStringVisiting.runInitialized((toStringVisitingValue) {
    if (isToStringVisiting(toStringVisitingValue, iterable)) {
      return "$leftDelimiter...$rightDelimiter";
    }
    List<String> parts = <String>[];
    toStringVisitingValue.add(iterable);
    try {
      _iterablePartsToStrings(iterable, parts);
    } finally {
      assert(identical(toStringVisitingValue.last, iterable));
      toStringVisitingValue.removeLast();
    }
    return (StringBuffer(leftDelimiter)
          ..writeAll(parts, ", ")
          ..write(rightDelimiter))
        .toString();
  });
}

@pragma('vm:shared')
final threadName = ScopedThreadLocal<String>();

main() {
  Expect.isFalse(toStringVisiting.isBound);
  Expect.throws(
    () {
      IsolateGroup.runSync(() {
        var l = <Object>["foo", "bar"];
        l.add(l);
        l.add("baz");
        final isBoundBefore = toStringVisiting.isBound;
        final result = iterableToShortString(l);
        final isBoundAfter = toStringVisiting.isBound;
        throw "isBoundBefore: $isBoundBefore, $result, isBoundAfter: $isBoundAfter";
      });
    },
    (e) =>
        e.toString() ==
        "isBoundBefore: false, (foo, bar, (...), baz), isBoundAfter: false",
  );
  {
    Expect.isFalse(toStringVisiting.isBound);
    var l = <Object>["foo", "bar"];
    l.add(l);
    l.add("baz");
    Expect.equals("(foo, bar, (...), baz)", iterableToShortString(l));
    Expect.isFalse(toStringVisiting.isBound);
  }

  Expect.equals(
    "123",
    IsolateGroup.runSync(() {
      return threadName.runWith("123", (s) {
        Expect.isTrue(threadName.isBound);
        return s;
      });
    }),
  );
  Expect.throws(
    () => IsolateGroup.runSync(() => threadName.value),
    (e) => e is StateError,
  );
  Expect.throws(() => threadName.value, (e) => e is StateError);
  Expect.equals(
    "name:123",
    threadName.runWith<String>("123", (String name) {
      Expect.isTrue(threadName.isBound);
      return "name:$name";
    }),
  );
  Expect.isFalse(threadName.isBound);
}
