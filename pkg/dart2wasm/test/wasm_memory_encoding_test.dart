// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:expect/expect.dart';
import 'package:wasm_builder/wasm_builder.dart';

void main() {
  final builder = ModuleBuilder('memory_encoding', null);
  for (var i = 0; i < 130; i++) {
    builder.memories.define(false, 1);
  }
  final memories = builder.memories.build();

  void check(int memoryIndex, int offset, int align, List<int> bytes) {
    final operand = MemoryOffsetAlign(
      memories[memoryIndex],
      offset: offset,
      align: align,
    );
    final serializer = Serializer();
    operand.serialize(serializer);
    Expect.listEquals(bytes, serializer.data);

    // Decode the specification's bytes independently of the encoder. A round
    // trip alone would miss an encoder and decoder using the same wrong order.
    final deserializer = Deserializer(Uint8List.fromList(bytes));
    final decoded = MemoryOffsetAlign.deserialize(deserializer, memories);
    Expect.identical(memories[memoryIndex], decoded.memory);
    Expect.equals(offset, decoded.offset);
    Expect.equals(align, decoded.align);
    Expect.isTrue(deserializer.isAtEnd);
  }

  // With bit 6 set in the alignment field, memidx precedes the byte offset.
  check(0, 0, 0, [0x00, 0x00]);
  check(0, 258, 3, [0x03, 0x82, 0x02]);
  check(1, 0, 3, [0x43, 0x01, 0x00]);
  check(1, 258, 2, [0x42, 0x01, 0x82, 0x02]);
  check(129, 7, 0, [0x40, 0x81, 0x01, 0x07]);
  check(129, 258, 3, [0x43, 0x81, 0x01, 0x82, 0x02]);
}
