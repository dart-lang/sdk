// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

String returnImplicit() /*error*/ {
  print("foo");
}

String returnExplicit() {
  print("foo");
  return null; // error
}

String returnMixed(bool b) /*error*/ {
  if (b) {
    print("foo");
    return null; // error
  }
}

Future returnAsync1() async {} // ok

FutureOr returnAsync2() async {} // ok

FutureOr<int> returnAsync3() async {} // error

FutureOr<int?> returnAsync4() async {} // ok

returnAsync5() async {} // ok

Future<int?> returnAsync6() async {
  return null; // ok
}

Future<int?> returnAsync7() async {} // ok

Iterable yieldSync() sync* {} // ok

Stream yieldAsync() async* {} // ok

enum Enum { a, b }

Enum caseReturn1(Enum e) /* ok */ {
  switch (e) {
    case Enum.a:
      return e;
    case Enum.b:
      return e;
  }
}

Enum caseReturn2(Enum e) /* error */ {
  switch (e) {
    case Enum.a:
      return e;
    default:
  }
}

localFunctions() {
  String returnImplicit() /* error */ {
    print("foo");
  }

  String returnExplicit() {
    print("foo");
    return null; // error
  }

  String returnMixed(bool b) /* error */ {
    if (b) {
      print("foo");
      return null; // error
    }
  }

  Future returnAsync1() async {} // ok

  FutureOr returnAsync2() async {} // ok

  FutureOr<int> returnAsync3() async {} // error

  FutureOr<int?> returnAsync4() async {} // ok

  returnAsync5() async {} // ok

  Future<int?> returnAsync6() async {
    return null; // ok
  }

  Future<int?> returnAsync7() async {} // ok

  Iterable yieldSync() sync* {} // ok

  Stream yieldAsync() async* {} // ok

  Enum caseReturn1(Enum e) /* ok */ {
    switch (e) {
      case Enum.a:
        return e;
      case Enum.b:
        return e;
    }
  }

  Enum caseReturn2(Enum e) /* error */ {
    switch (e) {
      case Enum.a:
        return e;
      default:
    }
  }

  bool b = false;
  var local1 = () /* ok */ {
    if (b) return 0;
  }();
  var local2 = () /* ok */ {
    if (b) return null;
    if (!b) return 0;
  }();
}

main() {}
