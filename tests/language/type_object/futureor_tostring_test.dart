// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the `toString` of a `Type` object for a type that is,
// or that contains, a `FutureOr` type, including whether its trailing `? s
// are correct.
//
// The `toString` is performed on the **NORM**-normalized type,
// and **NORM**(`FutureOr<T>?`), with `N` bein **NORM**(`T`),
// may be either `FutureOr<N>` or `FutureOr<N>?`, depending on
// whether `T`/`N` is nullable or not.
//
// This test checks that the `toString` result always matches
// the correctly normalized type format.
// Also checks for types `T` where normalization removes or changes
// the `FutureOr`.

import "dart:async" show FutureOr;
import "package:expect/expect.dart";

void main() {
  // Generally assumes that `Type.toString()` mathches the canonical
  // format of the type, as used in the language specification,
  // with a leading name, `<...>` around type arguments,
  // and trailing `?` for the nullable union types,
  // and that it uses the same name for the same type every time,
  // even if the names have been minified.
  //
  // That is the case for all current implementations, in all modes,
  // even if `Type.toString()` doesn't document it.

  Match match = RegExp(r"^(.+)<(.+)<(.+)>>$")
      .matchAsPrefix((A<FutureOr<String>>).toString())!;
  String a = match[1]!;
  String fo = match[2]!;

  Expect.equals("$String", match[3]); // Sanity check.

  void testType<T>(String expected) {
    Expect.equals(expected, "$T");
  }

  void testRuntimeType(Object o, String expected) {
    Expect.equals(expected, "${o.runtimeType}");
  }

  void testNullable<B>() {
    assert(null is B);
    var b = "$B";
    // Equal to `B` for top types and `Object`.
    var fob = "${FutureOr<B>}";
    if (topOrObject<B>()) {
      Expect.equals(b, fob);
    } else if (isNull<B>()) {
      Expect.equals("${Future<B>}?", fob);
    } else {
      Expect.equals("$fo<$b>", fob);
    }
    testType<FutureOr<B>>(fob);
    testType<FutureOr<B>?>(fob);
    testType<FutureOr<B?>>(fob);
    testType<FutureOr<B?>?>(fob);
    testType<FutureOr<N<B?>>>(fob);
    testType<N<FutureOr<B>?>>(fob);

    var afob = "$a<$fob>";
    testType<A<FutureOr<B>?>>(afob);
    testType<A<FutureOr<B?>>>(afob);
    testType<A<FutureOr<B?>?>>(afob);
    testType<A<FutureOr<N<B?>>>>(afob);
    testType<A<N<FutureOr<B>?>>>(afob);
    testRuntimeType(A<FutureOr<B>?>(), afob);
    testRuntimeType(A<FutureOr<B?>>(), afob);
    testRuntimeType(A<FutureOr<B?>?>(), afob);
    testRuntimeType(A<FutureOr<N<B?>>>(), afob);
    testRuntimeType(A<N<FutureOr<B>?>>(), afob);
  }

  void testNotNullable<B>({bool alsoTestNullable = true}) {
    assert(null is! B);
    assert(!top<B>());
    var b = "$B";
    var fob = "${FutureOr<B>}";
    if (never<B>()) {
      Expect.equals("${Future<B>}", fob);
    } else if (topOrObject<B>()) {
      // Object.
      Expect.equals(b, fob);
    } else {
      Expect.equals("$fo<$b>", fob);
    }
    testType<FutureOr<B>>(fob);
    testType<FutureOr<B>?>("$fob?");
    testType<N<FutureOr<B>?>>("$fob?");
    testType<A<FutureOr<B>?>>("$a<$fob?>");
    testType<A<N<FutureOr<B>?>>>("$a<$fob?>");
    testRuntimeType(A<FutureOr<B>?>(), "$a<$fob?>");
    testRuntimeType(A<N<FutureOr<B>?>>(), "$a<$fob?>");

    if (alsoTestNullable) testNullable<B?>();
  }

  testNotNullable<String>();

  testNullable<dynamic>();
  testNullable<void>();

  testNotNullable<Object>();

  testNullable<Null>();

  testNotNullable<Never>();

  // Some more cases that could be non-trivial, but really aren't.
  testNotNullable<Future<Object>>();
  testNotNullable<Future<Object?>>();

  // Test nested `FutureOr`, since normalization of that is somewhat
  // non-trivial.
  testNotNullable<FutureOr<String>>(alsoTestNullable: false);
  testNullable<FutureOr<String>?>();
  testNullable<FutureOr<String?>>();
  testNullable<FutureOr<String?>?>();

  // A singleton record with nullable field, for good measure.
  testNotNullable<(String?,)>();
}

// Supports nesting nullables, like `N<N<N<int>>>`, which cannot
// syntactically be written as `int???`.
typedef N<T> = T?;

bool top<T>() => <Object?>[] is List<T>;
bool topOrObject<T>() => <Object>[] is List<T>;
bool never<T>() => <T>[] is List<Never>;
bool isNull<T>() => <T>[] is List<Null> && null is T;

class A<T> {}
