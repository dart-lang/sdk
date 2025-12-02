// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/utils/arena.dart';
import 'package:test/test.dart';

void main() {
  late Uint32Arena arena;

  setUp(() {
    arena = Uint32Arena();
  });

  test('allocate 0', () {
    expect(arena.allocate(0), equals(ArenaPointer.Null));
    expect(arena.allocate(42), isNot(equals(ArenaPointer.Null)));
    expect(arena.allocate(0), equals(ArenaPointer.Null));
  });

  test('allocate and access', () {
    final ptr1 = arena.allocate(3);
    expect(arena[ptr1], equals(0));
    expect(arena[ptr1 + 1], equals(0));
    expect(arena[ptr1 + 2], equals(0));
    arena[ptr1] = 0xabcdef01;
    arena[ptr1 + 1] = 0xabcdef02;
    arena[ptr1 + 2] = -3;
    final ptr2 = arena.allocate(2);
    expect(arena[ptr2], equals(0));
    expect(arena[ptr2 + 1], equals(0));
    arena[ptr2] = 0xf00d01;
    arena[ptr2 + 1] = 0xf00d02;
    expect(arena[ptr1], equals(0xabcdef01));
    expect(arena[ptr1 + 1], equals(0xabcdef02));
    expect(arena[ptr1 + 2], equals(0xfffffffd));
    expect(arena[ptr2], equals(0xf00d01));
    expect(arena[ptr2 + 1], equals(0xf00d02));
    arena[ptr1 + 1] = 123;
    expect(arena[ptr1], equals(0xabcdef01));
    expect(arena[ptr1 + 1], equals(123));
    expect(arena[ptr1 + 2], equals(0xfffffffd));
  });

  test('pointer arithmetic', () {
    final p1 = arena.allocate(2000);
    expect(p1 + 0, equals(p1));
    final p2 = p1 + 1200;
    final p3 = p2 + (-511);
    final p4 = p3 + (-689);
    expect(p4, equals(p1));
    expect(p1 + 689, equals(p3));
    expect((p1 + 17) + 1183, equals(p2));
    expect((p1 + 1491).toInt(), equals((p2 + 291).toInt()));
  });

  test('expand', () {
    final size1 = Uint32Arena.initialSize - 2;
    final p1 = arena.allocate(Uint32Arena.initialSize - 2);
    arena[p1] = 0x11111111;
    arena[p1 + (size1 - 1)] = 0x22222222;
    final p2 = arena.allocate(3);
    arena[p2] = 0xf00d0001;
    arena[p2 + 1] = 0xf00d0002;
    arena[p2 + 2] = 0xf00d0003;
    final size3 = Uint32Arena.initialSize << 3;
    final p3 = arena.allocate(size3);
    for (var i = 0; i < size3; ++i) {
      arena[p3 + i] = i << 3;
    }
    expect(arena[p1], equals(0x11111111));
    expect(arena[p1 + 1], equals(0));
    expect(arena[p1 + (size1 ~/ 2)], equals(0));
    expect(arena[p1 + (size1 - 2)], equals(0));
    expect(arena[p1 + (size1 - 1)], equals(0x22222222));
    expect(arena[p2], equals(0xf00d0001));
    expect(arena[p2 + 1], equals(0xf00d0002));
    expect(arena[p2 + 2], equals(0xf00d0003));
    for (int i = size3 - 1; i >= 0; --i) {
      expect(arena[p3 + i], equals(i << 3));
    }
  });

  test('double linked list', () {
    final n = 10;
    final nodes = <ArenaPointer>[];
    ArenaPointer prev = ArenaPointer.Null;
    for (var i = 0; i < n; ++i) {
      ArenaPointer node = arena.allocate(3); // 3 fields: payload, prev, next.
      nodes.add(node);
      arena[node] = i; // node.payload = i
      arena[node + 1] = prev.toInt(); // node.prev = prev
      arena[node + 2] = ArenaPointer.Null.toInt(); // node.next = null
      if (prev != ArenaPointer.Null) {
        arena[prev + 2] = node.toInt(); // prev.next = node
      }
      prev = node;
    }
    // Forward iteration.
    var i = 0;
    for (
      ArenaPointer node = nodes.first;
      node != ArenaPointer.Null;
      node = ArenaPointer(arena[node + 2])
    ) {
      expect(node, equals(nodes[i]));
      expect(arena[node], equals(i));
      ++i;
    }
    expect(i, equals(n));
    // Backwards iteration.
    i = n;
    for (
      ArenaPointer node = nodes.last;
      node != ArenaPointer.Null;
      node = ArenaPointer(arena[node + 1])
    ) {
      --i;
      expect(node, equals(nodes[i]));
      expect(arena[node], equals(i));
    }
    expect(i, equals(0));
  });
}
