// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

void main() async {
  asyncStart();

  var fi = Future<int>.value(1);
  var ffi = Future<Future<int>>.value(fi);

  // Sanity check.
  Expect.equals(type<int>(), typeOf(1));

  {
    int v = 1; //                          // Variable with type T.
    var f = await v; //                    // Variable with type FLATTEN(T).
    Expect.equals(type<int>(), typeOf(f)); // Dynamic check of static type of f.
    int s = f; //                          // Static check upper bound of f.
    f = 1; //                              // Static check lower bound of f.
    s.toString(); //                       // Avoid "unused variable" warning.
  }

  {
    Future<int> v = fi;
    var f = await v;
    Expect.equals(type<int>(), typeOf(f));
    int s = f;
    f = 1;
    s.toString();
  }

  {
    Future<Future<int>> v = ffi;
    var f = await v;
    Expect.equals(type<Future<int>>(), typeOf(f));
    Future<int> s = f;
    f = fi;
    s.toString();
  }

  {
    FutureOr<int> v = 1;
    var f = await v;
    Expect.equals(type<int>(), typeOf(f));
    int s = f;
    f = 1;
    s.toString();
  }

  {
    FutureOr<Future<int>> v = fi;
    var f = await v;
    Expect.equals(type<Future<int>>(), typeOf(f));
    Future<int> s = f;
    f = fi;
    s.toString();
  }

  {
    Future<FutureOr<int>> v = fi;
    var f = await v;
    Expect.equals(type<FutureOr<int>>(), typeOf(f));
    FutureOr<int> s = f;
    f = 1;
    f = fi;
    s.toString();
  }

  {
    FutureOr<FutureOr<int>> v = 1;
    var f = await v;
    Expect.equals(type<FutureOr<int>>(), typeOf(f));
    FutureOr<int> s = f;
    f = 1;
    f = fi;
    s.toString();
  }

  asyncEnd();
}

Type type<T>() => T;
Type typeOf<T>(T of) => T;
