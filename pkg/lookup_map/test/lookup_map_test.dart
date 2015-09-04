// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:lookup_map/lookup_map.dart';

import 'package:test/test.dart';

class Key {
  final int id;
  const Key(this.id);
}

class A{}
const B = const Key(1);
class C{}

main() {
  test('entries constructor', () {
    var m = const LookupMap(const [
        A, "the-text-for-A",
        B, "the-text-for-B",
        1.2, "the-text-for-1.2"]);
    expect(m[A], 'the-text-for-A');
    expect(m[B], 'the-text-for-B');
    expect(m[1.2], 'the-text-for-1.2');
    expect(m[C], null);
    expect(m[1.3], null);
  });

  test('pair constructor', () {
    var m = const LookupMap.pair(A, "the-text-for-A");
    expect(m[A], 'the-text-for-A');
    expect(m[B], null);
  });

  test('nested lookup', () {
    var m = const LookupMap(const [],
        const [const LookupMap.pair(A, "the-text-for-A")]);
    expect(m[A], 'the-text-for-A');
    expect(m[B], null);
  });

  test('entry shadows nested maps', () {
    var m = const LookupMap(const [
      A, "the-text-for-A2",
    ], const [
      const LookupMap.pair(A, "the-text-for-A1"),
    ]);
    expect(m[A], 'the-text-for-A2');
  });

  test('nested maps shadow in order', () {
    var m = const LookupMap(const [ ], const [
      const LookupMap.pair(A, "the-text-for-A1"),
      const LookupMap.pair(B, "the-text-for-B2"),
      const LookupMap.pair(A, "the-text-for-A2"),
      const LookupMap.pair(B, "the-text-for-B1"),
    ]);
    expect(m[A], 'the-text-for-A2');
    expect(m[B], 'the-text-for-B1');
  });

  // This test would fail if dart2js has a bug, but we keep it here for our
  // sanity.
  test('reachable lookups are not tree-shaken', () {
    var m = const LookupMap(const [
      A, B,
      B, C,
      C, 3.4,
    ]);
    expect(m[m[m[A]]], 3.4);
  });
}
