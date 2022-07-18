// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  const Foo(
    int Function(String)? a1,
    int Function(String)? a2,
    int Function(String)? a3,
    int Function(String)? a4,
    int Function(String)? a5,
    int Function(String)? a6,
    int Function(String)? a7,
    int Function(String)? a8,
    int Function(String)? a9,
    int Function(String)? a10,
    int Function(String)? a11,
    int Function(String)? a12,
    int Function(String)? a13,
    int Function(String)? a14,
    int Function(String)? a15,
    int Function(String)? a16,
    int Function(String)? a17,
    int Function(String)? a18,
    int Function(String)? a19,
    int Function(String)? a20,
    int Function(String)? a21,
    int Function(String)? a22,
    int Function(String)? a23,
    int Function(String)? a24,
  ) : _foo = a1 ??
            a2 ??
            a3 ??
            a4 ??
            a5 ??
            a6 ??
            a7 ??
            a8 ??
            a9 ??
            a10 ??
            a11 ??
            a12 ??
            a13 ??
            a14 ??
            a15 ??
            a16 ??
            a17 ??
            a18 ??
            a19 ??
            a20 ??
            a21 ??
            a22 ??
            a23 ??
            a24 ??
            bar;
  final int Function(String) _foo;
}

int bar(String o) => int.parse(o);

void main() {
  const Foo myValue = Foo(
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
    bool.fromEnvironment("baz") ? int.parse : null,
  );

  print(myValue);
  print(myValue);
  print(myValue);
  print(myValue);
}
