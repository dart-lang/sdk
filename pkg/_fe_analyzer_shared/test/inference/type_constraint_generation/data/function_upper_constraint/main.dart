// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test case exercises the code path in type constraint generation where a
// function type is constrained by `Function` from `dart:core` from above.

foo1a(Function x) {}
Function(T) bar1a<T>() => (T _) {};

foo1b(Function(bool) x) {}
Function(T) bar1b<T>() => (T _) {};

foo2a(Function Function(num) x) {}
Function(T) Function(T) bar2a<T>() => ((T _) => (T _) {});

foo2b(Function(int) Function(num) x) {}
Function(T) Function(T) bar2b<T>() => ((T _) => (T _) {});

foo3a<T>(Function(Function(T)) x) {}
Function(Function) bar3a() => (Function _) {};

foo3b<T>(Function(Function(T)) x) {}
Function(Function(String)) bar3b() => (Function(String) _) {};

main() {
  foo1a(bar1a());
  foo1b(bar1b /*T :> bool*/ ());
  foo2a(bar2a /*T :> num*/ ());
  foo2b(bar2b /*T :> int,T :> num*/ ());
  foo3a(bar3a());
  foo3b /*T :> String*/ (bar3b());
}
