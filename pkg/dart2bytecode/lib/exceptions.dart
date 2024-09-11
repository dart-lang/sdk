// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'bytecode_serialization.dart' show BufferedWriter, BufferedReader;

class TryBlock {
  static const int flagNeedsStackTrace = 1 << 0;
  static const int flagIsSynthetic = 1 << 1;

  final int tryIndex;
  final int outerTryIndex;
  final int startPC;
  int endPC = -1;
  int handlerPC = -1;
  int flags = 0;
  List<int> types = <int>[];

  TryBlock._(this.tryIndex, this.outerTryIndex, this.startPC);

  bool get needsStackTrace => (flags & flagNeedsStackTrace) != 0;

  void set needsStackTrace(bool value) {
    flags = (flags & ~flagNeedsStackTrace) | (value ? flagNeedsStackTrace : 0);
  }

  bool get isSynthetic => (flags & flagIsSynthetic) != 0;

  void set isSynthetic(bool value) {
    flags = (flags & ~flagIsSynthetic) | (value ? flagIsSynthetic : 0);
  }

  void write(BufferedWriter writer) {
    writer.writePackedUInt30(outerTryIndex + 1);
    writer.writePackedUInt30(startPC);
    writer.writePackedUInt30(endPC);
    writer.writePackedUInt30(handlerPC);
    writer.writeByte(flags);
    writer.writePackedUInt30(types.length);
    types.forEach(writer.writePackedUInt30);
  }

  factory TryBlock.read(BufferedReader reader, int tryIndex) {
    final outerTryIndex = reader.readPackedUInt30() - 1;
    final startPC = reader.readPackedUInt30();
    final tryBlock = new TryBlock._(tryIndex, outerTryIndex, startPC);

    tryBlock.endPC = reader.readPackedUInt30();
    tryBlock.handlerPC = reader.readPackedUInt30();
    tryBlock.flags = reader.readByte();
    tryBlock.types = new List<int>.generate(
        reader.readPackedUInt30(), (_) => reader.readPackedUInt30());

    return tryBlock;
  }

  @override
  String toString() => 'try-index $tryIndex, outer $outerTryIndex, '
      'start $startPC, end $endPC, handler $handlerPC, '
      '${needsStackTrace ? 'needs-stack-trace, ' : ''}'
      '${isSynthetic ? 'synthetic, ' : ''}'
      'types ${types.map((t) => 'CP#$t').toList()}';
}

class ExceptionsTable {
  List<TryBlock> blocks = <TryBlock>[];

  ExceptionsTable();

  TryBlock enterTryBlock(int startPC) {
    assert(blocks.isEmpty || blocks.last.startPC <= startPC);
    final tryBlock =
        new TryBlock._(blocks.length, _outerTryBlockIndex(startPC), startPC);
    blocks.add(tryBlock);
    return tryBlock;
  }

  int _outerTryBlockIndex(int startPC) {
    for (int i = blocks.length - 1; i >= 0; --i) {
      final tryBlock = blocks[i];
      if (tryBlock.endPC < 0 || tryBlock.endPC > startPC) {
        return i;
      }
    }
    return -1;
  }

  void write(BufferedWriter writer) {
    writer.writePackedUInt30(blocks.length);
    blocks.forEach((b) => b.write(writer));
  }

  ExceptionsTable.read(BufferedReader reader)
      : blocks = new List<TryBlock>.generate(reader.readPackedUInt30(),
            (int index) => new TryBlock.read(reader, index));

  @override
  String toString() {
    if (blocks.isEmpty) {
      return '';
    }
    StringBuffer sb = new StringBuffer();
    sb.writeln('ExceptionsTable {');
    for (var tryBlock in blocks) {
      sb.writeln('  $tryBlock');
    }
    sb.writeln('}');
    return sb.toString();
  }
}
