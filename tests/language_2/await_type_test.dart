// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

void main() async {
  asyncStart();

  // Sanity check.
  Expect.equals(type<int>(), type(1));

  {
    int v = null; //                     // Variable with type T.
    var f = await v; //                  // Variable with type FLATTEN(T).
    Expect.equals(type<int>(), type(f)); // Dynamic check of static type of f.
    int s = f; //                        // Static check upper bound of f.
    f = 1; //                            // Static check lower bound of f.
    s.toString(); //                     // Avoid "unused variable" warning.
  }

  {
    Future<int> v = null;
    var f = await v;
    Expect.equals(type<int>(), type(f));
    int s = f;
    f = 1;
    s.toString();
  }

  {
    Future<Future<int>> v = null;
    var f = await v;
    Expect.equals(type<Future<int>>(), type(f));
    Future<int> s = f;
    f = Future<int>.value(1);
    s.toString();
  }

  {
    FutureOr<int> v = null;
    var f = await v;
    Expect.equals(type<int>(), type(f));
    int s = f;
    f = 1;
    s.toString();
  }

  {
    FutureOr<Future<int>> v = null;
    var f = await v;
    Expect.equals(type<Future<int>>(), type(f));
    Future<int> s = f;
    f = Future<int>.value(1);
    s.toString();
  }

  {
    Future<FutureOr<int>> v = null;
    var f = await v;
    Expect.equals(type<FutureOr<int>>(), type(f));
    FutureOr<int> s = f;
    f = 1;
    f = Future<int>.value(1);
    s.toString();
  }

  {
    FutureOr<FutureOr<int>> v = null;
    var f = await v;
    Expect.equals(type<FutureOr<int>>(), type(f));
    FutureOr<int> s = f;
    f = 1;
    f = Future<int>.value(1);
    s.toString();
  }

  asyncEnd();
}

Type type<T>([T of]) => T;
