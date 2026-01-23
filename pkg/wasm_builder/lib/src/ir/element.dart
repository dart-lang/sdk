// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../serialize/serialize.dart';
import 'ir.dart';

sealed class ElementSegment implements Serializable {}

sealed class ActiveElementSegment extends ElementSegment {
  final Table table;
  final int startIndex;

  ActiveElementSegment(this.table, this.startIndex);
}

/// Initializes a specific table with function references.
///
/// NOTE: Can only be used if the table type is `RefType.func(nullable: true)`.
final class ActiveFunctionElementSegment extends ActiveElementSegment {
  final List<BaseFunction> entries;

  ActiveFunctionElementSegment(super.table, super.startIndex,
      [List<BaseFunction>? entries])
      : entries = entries ?? [];

  @override
  void serialize(Serializer s) {
    final useTable0Encoding = table.index == 0;
    if (useTable0Encoding) {
      s.writeByte(0x00);
    } else {
      s.writeByte(0x02);
      s.writeUnsigned(table.index);
    }
    s.serializeTableOffset(startIndex);

    if (!useTable0Encoding) {
      s.writeByte(_ElemKind.refFunc);
    }

    s.writeUnsigned(entries.length);
    for (var entry in entries) {
      s.writeUnsigned(entry.index);
    }
  }

  static ActiveFunctionElementSegment deserialize(
    Deserializer d,
    Module module,
    Types types,
    Functions functions,
    Tables tables,
    Globals globals,
  ) {
    final byte = d.readByte();
    assert(byte == 0x00 || byte == 0x02);

    final useTable0Encoding = byte == 0x00;
    final tableIndex = useTable0Encoding ? 0 : d.readUnsigned();

    final offset = d.deserializeTableOffset(types, functions, globals);

    if (!useTable0Encoding) {
      final elemKind = d.readByte();
      if (elemKind != _ElemKind.refFunc) {
        throw UnimplementedError('Unsupported element kind.');
      }
    }

    final table = tables[tableIndex];
    final tableElement = ActiveFunctionElementSegment(table, offset);
    final count = d.readUnsigned();
    for (int i = 0; i < count; i++) {
      tableElement.entries.add(functions[d.readUnsigned()]);
    }
    return tableElement;
  }
}

/// Initializes a specific table with initialization expressions.
final class ActiveExpressionElementSegment extends ActiveElementSegment {
  final RefType type;
  final List<List<Instruction>> expressions = [];

  ActiveExpressionElementSegment(super.table, this.type, super.startIndex);

  @override
  void serialize(Serializer s) {
    final useTableTable0RefNullFuncEncoding =
        table.index == 0 && type == RefType.func(nullable: true);
    if (useTableTable0RefNullFuncEncoding) {
      s.writeByte(0x04);
    } else {
      s.writeByte(0x06);
      s.writeUnsigned(table.index);
    }
    s.serializeTableOffset(startIndex);
    if (!useTableTable0RefNullFuncEncoding) {
      s.write(type);
    }
    s.writeUnsigned(expressions.length);
    for (final expression in expressions) {
      for (final instruction in expression) {
        instruction.serialize(s);
      }
    }
  }

  static ActiveExpressionElementSegment deserialize(
    Deserializer d,
    Module module,
    Types types,
    Functions functions,
    Tables tables,
    Globals globals,
  ) {
    final kind = d.readByte();
    assert(kind == 0x04 || kind == 0x06);

    final useTableTable0RefNullFuncEncoding = kind == 0x04;
    final tableIndex = useTableTable0RefNullFuncEncoding ? 0 : d.readUnsigned();
    final offset = d.deserializeTableOffset(types, functions, globals);
    final type = useTableTable0RefNullFuncEncoding
        ? RefType.func(nullable: true)
        : RefType.deserialize(d, types.defined);

    final table = tables[tableIndex];
    final tableElement = ActiveExpressionElementSegment(table, type, offset);
    final count = d.readUnsigned();
    for (int i = 0; i < count; i++) {
      final instructions = <Instruction>[];
      while (true) {
        final instruction =
            Instruction.deserializeConst(d, types, functions, globals);
        instructions.add(instruction);
        if (instruction is End) break;
      }
      tableElement.expressions.add(instructions);
    }
    return tableElement;
  }
}

final class DeclarativeElementSegment implements ElementSegment {
  final List<BaseFunction> entries;

  DeclarativeElementSegment(this.entries);

  @override
  void serialize(Serializer s) {
    if (entries.isEmpty) return;
    s.writeByte(0x03);
    s.writeByte(_ElemKind.refFunc);

    s.writeUnsigned(entries.length);
    for (final entry in entries) {
      s.writeUnsigned(entry.index);
    }
  }

  static DeclarativeElementSegment deserialize(
      Deserializer d, Functions functions) {
    if (d.readByte() != 0x03) {
      throw StateError('Expected declarative segment to start with 0x03.');
    }

    final elemkind = d.readByte();
    if (elemkind != _ElemKind.refFunc) {
      throw UnsupportedError('Unsupported element kind: $elemkind');
    }

    final declaredFunctions = d.readList((d) => functions[d.readUnsigned()]);
    return DeclarativeElementSegment(declaredFunctions);
  }
}

abstract class _ElemKind {
  static const refFunc = 0;
}

extension on Serializer {
  void serializeTableOffset(int offset) {
    I32Const(offset).serialize(this);
    End().serialize(this);
  }
}

extension on Deserializer {
  int deserializeTableOffset(
      Types types, Functions functions, Globals globals) {
    final i0 = Instruction.deserializeConst(this, types, functions, globals);
    final i1 = Instruction.deserializeConst(this, types, functions, globals);
    if (i0 is! I32Const || i1 is! End) {
      throw StateError('Expected offset to be encoded as '
          '`(i32.const <value>) (end)`. '
          'Got instead: (${i0.name}) (${i1.name})');
    }
    return i0.value;
  }
}
