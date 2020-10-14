// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo(bool condition, Iterable<dynamic> iterable, List<int>? a, Set<int>? b,
    Iterable<int>? c, Map<int, int>? d) {
  return [
    {...a}, // Error.
    {...b}, // Error.
    {...c}, // Error.
    {...d}, // Error.
    <int, int>{...a}, // Error.
    <int>{...d}, // Error.
    {if (condition) ...a}, // Error.
    {if (condition) ...b}, // Error.
    {if (condition) ...c}, // Error.
    {if (condition) ...d}, // Error.
    {for (dynamic e in iterable) ...a}, // Error.
    {for (dynamic e in iterable) ...b}, // Error.
    {for (dynamic e in iterable) ...c}, // Error.
    {for (dynamic e in iterable) ...d}, // Error.
    {for (int i = 0; i < 42; ++i) ...a}, // Error.
    {for (int i = 0; i < 42; ++i) ...b}, // Error.
    {for (int i = 0; i < 42; ++i) ...c}, // Error.
    {for (int i = 0; i < 42; ++i) ...d}, // Error.

    {...?a}, // Ok.
    {...?b}, // Ok.
    {...?c}, // Ok.
    {...?d}, // Ok.
    {if (condition) ...?a}, // Ok.
    {if (condition) ...?b}, // Ok.
    {if (condition) ...?c}, // Ok.
    {if (condition) ...?d}, // Ok.
    {for (dynamic e in iterable) ...?a}, // Ok.
    {for (dynamic e in iterable) ...?b}, // Ok.
    {for (dynamic e in iterable) ...?c}, // Ok.
    {for (dynamic e in iterable) ...?d}, // Ok.
    {for (int i = 0; i < 42; ++i) ...?a}, // Ok.
    {for (int i = 0; i < 42; ++i) ...?b}, // Ok.
    {for (int i = 0; i < 42; ++i) ...?c}, // Ok.
    {for (int i = 0; i < 42; ++i) ...?d}, // Ok.
  ];
}

bar<X extends List<int>?, Y extends Set<int>?, Z extends Iterable<int>?,
        W extends Map<int, int>?>(
    bool condition, Iterable<dynamic> iterable, X x, Y y, Z z, W w) {
  return [
    {...x}, // Error.
    {...y}, // Error.
    {...z}, // Error.
    {...w}, // Error.
    <int, int>{...x}, // Error.
    <int>{...w}, // Error.
    {if (condition) ...x}, // Error.
    {if (condition) ...y}, // Error.
    {if (condition) ...z}, // Error.
    {if (condition) ...w}, // Error.
    {for (dynamic e in iterable) ...x}, // Error.
    {for (dynamic e in iterable) ...y}, // Error.
    {for (dynamic e in iterable) ...z}, // Error.
    {for (dynamic e in iterable) ...w}, // Error.
    {for (int i = 0; i < 42; ++i) ...x}, // Error.
    {for (int i = 0; i < 42; ++i) ...y}, // Error.
    {for (int i = 0; i < 42; ++i) ...z}, // Error.
    {for (int i = 0; i < 42; ++i) ...w}, // Error.

    {...?x}, // Ok.
    {...?y}, // Ok.
    {...?z}, // Ok.
    {...?w}, // Ok.
    {if (condition) ...?x}, // Ok.
    {if (condition) ...?y}, // Ok.
    {if (condition) ...?z}, // Ok.
    {if (condition) ...?w}, // Ok.
    {for (dynamic e in iterable) ...?x}, // Ok.
    {for (dynamic e in iterable) ...?y}, // Ok.
    {for (dynamic e in iterable) ...?z}, // Ok.
    {for (dynamic e in iterable) ...?w}, // Ok.
    {for (int i = 0; i < 42; ++i) ...?x}, // Ok.
    {for (int i = 0; i < 42; ++i) ...?y}, // Ok.
    {for (int i = 0; i < 42; ++i) ...?z}, // Ok.
    {for (int i = 0; i < 42; ++i) ...?w}, // Ok.
  ];
}

main() {}
