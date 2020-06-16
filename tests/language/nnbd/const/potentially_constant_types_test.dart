// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong

/// Test instance checks and casts in constants may use potentially constant
/// types, and evaluate appropriately.

import 'package:expect/expect.dart';

class C<T> {
  final bool isT;
  final bool isListT;
  final T? t;
  final List<T>? l;

  /// Check instance tests in isolation
  const C.test1(dynamic x)
      : isT = x is T,
        isListT = x is List<T>,
        t = null,
        l = null;

  /// Check casts to T in isolation
  const C.test2(dynamic x)
      : isT = true,
        isListT = false,
        t = x as T,
        l = null;

  /// Check casts to List<T> in isolation
  const C.test3(dynamic x)
      : isT = false,
        isListT = true,
        t = null,
        l = x as List<T>;

  /// Combine instance checks with casts, conditional expressions, promotion
  const C.test4(dynamic x)
      : isT = x is T,
        isListT = x is List<T>,
        t = (x is T) ? x : null,
        l = (x is List<T>) ? x : null;
}

void main() {
  {
    // Test instance checks of T
    const c1 = C<int>.test1(0);
    const c2 = C<int>.test1(0);
    const c3 = C<int>.test1(1);
    const c4 = C<int>.test1("hello");
    const c5 = C<int>.test1(null);
    Expect.identical(c1, c2);
    Expect.identical(c1, c3);
    Expect.notIdentical(c1, c4);
    Expect.notIdentical(c1, c5);
    Expect.isTrue(c1.isT);
    Expect.isTrue(c2.isT);
    Expect.isTrue(c3.isT);
    Expect.isFalse(c4.isT);
    Expect.isFalse(c5.isT);
    Expect.isFalse(c1.isListT);
    Expect.isFalse(c2.isListT);
    Expect.isFalse(c3.isListT);
    Expect.isFalse(c4.isListT);
    Expect.isFalse(c5.isListT);
  }
  {
    // Test instance checks of List<T>
    const c1 = C<int>.test1(<int>[0]);
    const c2 = C<int>.test1(<int>[0]);
    const c3 = C<int>.test1(<int>[1]);
    const c4 = C<int>.test1(<num>[1]);
    const c5 = C<num>.test1(<int>[1]);
    Expect.identical(c1, c2);
    Expect.identical(c1, c3);
    Expect.notIdentical(c1, c4);
    Expect.notIdentical(c1, c5);
    Expect.notIdentical(c4, c5);
    Expect.isFalse(c1.isT);
    Expect.isFalse(c2.isT);
    Expect.isFalse(c3.isT);
    Expect.isFalse(c4.isT);
    Expect.isFalse(c5.isT);
    Expect.isTrue(c1.isListT);
    Expect.isTrue(c2.isListT);
    Expect.isTrue(c3.isListT);
    Expect.isFalse(c4.isListT);
    Expect.isTrue(c5.isListT);
  }
  {
    // Test casts to T
    const c1 = C<int>.test2(0);
    const c2 = C<int>.test2(0);
    const c3 = C<num>.test2(1);
    Expect.identical(c1, c2);
    Expect.notIdentical(c1, c3);
  }
  {
    // Test casts to List<T>
    const c1 = C<int>.test3(<int>[0]);
    const c2 = C<int>.test3(<int>[0]);
    const c3 = C<num>.test3(<int>[0]);
    Expect.identical(c1, c2);
    Expect.notIdentical(c1, c3);
  }

  {
    // Combined tests
    const c1 = C<num>.test4(0);
    const c2 = C<num>.test4("hello");
    const c3 = C<num>.test4(<int>[0]);
    const c4 = C<num>.test4(<String>["hello"]);
    const c5 = C<int>.test4(<num>[0]);

    Expect.isTrue(c1.isT);
    Expect.isFalse(c1.isListT);
    Expect.equals(c1.t, 0);
    Expect.equals(c1.l, null);

    Expect.isFalse(c2.isT);
    Expect.isFalse(c2.isListT);
    Expect.equals(c2.t, null);
    Expect.equals(c2.l, null);

    Expect.isFalse(c3.isT);
    Expect.isTrue(c3.isListT);
    Expect.equals(c3.t, null);
    Expect.identical(c3.l, const <int>[0]);

    Expect.isFalse(c4.isT);
    Expect.isFalse(c4.isListT);
    Expect.equals(c4.t, null);
    Expect.equals(c4.l, null);

    Expect.isFalse(c5.isT);
    Expect.isFalse(c5.isListT);
    Expect.equals(c5.t, null);
    Expect.equals(c5.l, null);
  }
}
