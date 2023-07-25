// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'instructions.dart';

abstract class _Instruction implements Serializable {}

abstract class _SingleByteInstruction implements _Instruction {
  final int byte;

  const _SingleByteInstruction(this.byte);

  @override
  void serialize(Serializer s) => s.writeByte(byte);
}

abstract class _MultiByteInstruction implements _Instruction {
  final List<int> bytes;

  const _MultiByteInstruction(this.bytes);

  @override
  void serialize(Serializer s) => s.writeBytes(bytes);
}

class _Unreachable extends _SingleByteInstruction {
  const _Unreachable() : super(0x00);
}

class _Nop extends _SingleByteInstruction {
  const _Nop() : super(0x01);
}

class _BeginNoEffectBlock extends _MultiByteInstruction {
  const _BeginNoEffectBlock() : super(const [0x02, 0x40]);
}

class _BeginOneOutputBlock implements _Instruction {
  final ValueType type;

  _BeginOneOutputBlock(this.type);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x02);
    s.write(type);
  }
}

class _BeginFunctionBlock implements _Instruction {
  final FunctionType type;

  _BeginFunctionBlock(this.type);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x02);
    s.writeSigned(type.index);
  }
}

class _BeginNoEffectLoop extends _MultiByteInstruction {
  const _BeginNoEffectLoop() : super(const [0x03, 0x40]);
}

class _BeginOneOutputLoop implements _Instruction {
  final ValueType type;

  _BeginOneOutputLoop(this.type);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x03);
    s.write(type);
  }
}

class _BeginFunctionLoop implements _Instruction {
  final FunctionType type;

  _BeginFunctionLoop(this.type);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x03);
    s.writeSigned(type.index);
  }
}

class _BeginNoEffectIf extends _MultiByteInstruction {
  const _BeginNoEffectIf() : super(const [0x04, 0x40]);
}

class _BeginOneOutputIf implements _Instruction {
  final ValueType type;

  _BeginOneOutputIf(this.type);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x04);
    s.write(type);
  }
}

class _BeginFunctionIf implements _Instruction {
  final FunctionType type;

  _BeginFunctionIf(this.type);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x04);
    s.writeSigned(type.index);
  }
}

class _Else extends _SingleByteInstruction {
  const _Else() : super(0x05);
}

class _BeginNoEffectTry extends _MultiByteInstruction {
  const _BeginNoEffectTry() : super(const [0x06, 0x40]);
}

class _BeginOneOutputTry implements _Instruction {
  final ValueType type;

  _BeginOneOutputTry(this.type);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x06);
    s.write(type);
  }
}

class _BeginFunctionTry implements _Instruction {
  final FunctionType type;

  _BeginFunctionTry(this.type);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x06);
    s.writeSigned(type.index);
  }
}

class _Catch implements _Instruction {
  final Tag tag;

  _Catch(this.tag);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x07);
    s.writeUnsigned(tag.index);
  }
}

class _CatchAll extends _SingleByteInstruction {
  const _CatchAll() : super(0x19);
}

class _Throw implements _Instruction {
  final Tag tag;

  _Throw(this.tag);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x08);
    s.writeUnsigned(tag.index);
  }
}

class _Rethrow implements _Instruction {
  final int labelIndex;

  _Rethrow(this.labelIndex);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x09);
    s.writeUnsigned(labelIndex);
  }
}

class _End extends _SingleByteInstruction {
  const _End() : super(0x0B);
}

class _Br implements _Instruction {
  final int labelIndex;

  _Br(this.labelIndex);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x0C);
    s.writeUnsigned(labelIndex);
  }
}

class _BrIf implements _Instruction {
  final int labelIndex;

  _BrIf(this.labelIndex);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x0D);
    s.writeUnsigned(labelIndex);
  }
}

class _BrTable implements _Instruction {
  final List<int> labelIndices;
  final int defaultLabelIndex;

  _BrTable(this.labelIndices, this.defaultLabelIndex);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x0E);
    s.writeUnsigned(labelIndices.length);
    for (final labelIndex in labelIndices) {
      s.writeUnsigned(labelIndex);
    }
    s.writeUnsigned(defaultLabelIndex);
  }
}

class _Return extends _SingleByteInstruction {
  const _Return() : super(0x0F);
}

class _Call implements _Instruction {
  final BaseFunction function;

  _Call(this.function);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x10);
    s.writeUnsigned(function.index);
  }
}

class _CallIndirect implements _Instruction {
  final FunctionType type;
  final Table? table;

  _CallIndirect(this.type, this.table);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x11);
    s.writeUnsigned(type.index);
    s.writeUnsigned(table?.index ?? 0);
  }
}

class _CallRef implements _Instruction {
  final FunctionType type;

  _CallRef(this.type);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x14);
    s.writeUnsigned(type.index);
  }
}

class _Drop extends _SingleByteInstruction {
  const _Drop() : super(0x1A);
}

class _Select implements _Instruction {
  final ValueType type;

  _Select(this.type);

  @override
  void serialize(Serializer s) {
    if (type is NumType) {
      s.writeByte(0x1B);
    } else {
      s.writeByte(0x1C);
      s.writeUnsigned(1);
      s.write(type);
    }
  }
}

class _LocalGet implements _Instruction {
  final Local local;

  _LocalGet(this.local);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x20);
    s.writeUnsigned(local.index);
  }
}

class _LocalSet implements _Instruction {
  final Local local;

  _LocalSet(this.local);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x21);
    s.writeUnsigned(local.index);
  }
}

class _LocalTee implements _Instruction {
  final Local local;

  _LocalTee(this.local);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x22);
    s.writeUnsigned(local.index);
  }
}

class _GlobalGet implements _Instruction {
  final Global global;

  _GlobalGet(this.global);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x23);
    s.writeUnsigned(global.index);
  }
}

class _GlobalSet implements _Instruction {
  final Global global;

  _GlobalSet(this.global);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x24);
    s.writeUnsigned(global.index);
  }
}

class _TableSet implements _Instruction {
  final Table table;

  _TableSet(this.table);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x25);
    s.writeUnsigned(table.index);
  }
}

class _TableGet implements _Instruction {
  final Table table;

  _TableGet(this.table);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x26);
    s.writeUnsigned(table.index);
  }
}

class _TableSize implements _Instruction {
  final Table table;

  _TableSize(this.table);

  @override
  void serialize(Serializer s) {
    s.writeBytes([0xFC, 0x10]);
    s.writeUnsigned(table.index);
  }
}

class _Memory implements Serializable {
  final Memory memory;
  final int offset;
  final int align;

  _Memory(this.memory, {required this.offset, required this.align});

  @override
  void serialize(Serializer s) {
    if (memory.index == 0) {
      s.writeByte(align);
      s.writeUnsigned(offset);
    } else {
      s.writeByte(64 + align);
      s.writeUnsigned(offset);
      s.writeUnsigned(memory.index);
    }
  }
}

abstract class _MemoryInstruction implements _Instruction {
  final _Memory memory;
  final int encoding;

  _MemoryInstruction(this.memory, {required this.encoding});

  @override
  void serialize(Serializer s) {
    s.writeByte(encoding);
    memory.serialize(s);
  }
}

class _I32Load extends _MemoryInstruction {
  _I32Load(_Memory memory) : super(memory, encoding: 0x28);
}

class _I64Load extends _MemoryInstruction {
  _I64Load(_Memory memory) : super(memory, encoding: 0x29);
}

class _F32Load extends _MemoryInstruction {
  _F32Load(_Memory memory) : super(memory, encoding: 0x2A);
}

class _F64Load extends _MemoryInstruction {
  _F64Load(_Memory memory) : super(memory, encoding: 0x2B);
}

class _I32Load8S extends _MemoryInstruction {
  _I32Load8S(_Memory memory) : super(memory, encoding: 0x2C);
}

class _I32Load8U extends _MemoryInstruction {
  _I32Load8U(_Memory memory) : super(memory, encoding: 0x2D);
}

class _I32Load16S extends _MemoryInstruction {
  _I32Load16S(_Memory memory) : super(memory, encoding: 0x2E);
}

class _I32Load16U extends _MemoryInstruction {
  _I32Load16U(_Memory memory) : super(memory, encoding: 0x2F);
}

class _I64Load8S extends _MemoryInstruction {
  _I64Load8S(_Memory memory) : super(memory, encoding: 0x30);
}

class _I64Load8U extends _MemoryInstruction {
  _I64Load8U(_Memory memory) : super(memory, encoding: 0x31);
}

class _I64Load16S extends _MemoryInstruction {
  _I64Load16S(_Memory memory) : super(memory, encoding: 0x32);
}

class _I64Load16U extends _MemoryInstruction {
  _I64Load16U(_Memory memory) : super(memory, encoding: 0x33);
}

class _I64Load32S extends _MemoryInstruction {
  _I64Load32S(_Memory memory) : super(memory, encoding: 0x34);
}

class _I64Load32U extends _MemoryInstruction {
  _I64Load32U(_Memory memory) : super(memory, encoding: 0x35);
}

class _I32Store extends _MemoryInstruction {
  _I32Store(_Memory memory) : super(memory, encoding: 0x36);
}

class _I64Store extends _MemoryInstruction {
  _I64Store(_Memory memory) : super(memory, encoding: 0x37);
}

class _F32Store extends _MemoryInstruction {
  _F32Store(_Memory memory) : super(memory, encoding: 0x38);
}

class _F64Store extends _MemoryInstruction {
  _F64Store(_Memory memory) : super(memory, encoding: 0x39);
}

class _I32Store8 extends _MemoryInstruction {
  _I32Store8(_Memory memory) : super(memory, encoding: 0x3A);
}

class _I32Store16 extends _MemoryInstruction {
  _I32Store16(_Memory memory) : super(memory, encoding: 0x3B);
}

class _I64Store8 extends _MemoryInstruction {
  _I64Store8(_Memory memory) : super(memory, encoding: 0x3C);
}

class _I64Store16 extends _MemoryInstruction {
  _I64Store16(_Memory memory) : super(memory, encoding: 0x3D);
}

class _I64Store32 extends _MemoryInstruction {
  _I64Store32(_Memory memory) : super(memory, encoding: 0x3E);
}

class _MemorySize implements _Instruction {
  final Memory memory;

  _MemorySize(this.memory);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x3F);
    s.writeUnsigned(memory.index);
  }
}

class _MemoryGrow implements _Instruction {
  final Memory memory;

  _MemoryGrow(this.memory);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x40);
    s.writeUnsigned(memory.index);
  }
}

class _RefNull implements _Instruction {
  final HeapType heapType;

  _RefNull(this.heapType);

  @override
  void serialize(Serializer s) {
    s.writeByte(0xD0);
    s.write(heapType);
  }
}

class _RefIsNull extends _SingleByteInstruction {
  const _RefIsNull() : super(0xD1);
}

class _RefFunc implements _Instruction {
  final BaseFunction function;

  _RefFunc(this.function);

  @override
  void serialize(Serializer s) {
    s.writeByte(0xD2);
    s.writeUnsigned(function.index);
  }
}

class _RefAsNonNull extends _SingleByteInstruction {
  const _RefAsNonNull() : super(0xD3);
}

class _BrOnNull implements _Instruction {
  final int labelIndex;

  _BrOnNull(this.labelIndex);

  @override
  void serialize(Serializer s) {
    s.writeByte(0xD4);
    s.writeUnsigned(labelIndex);
  }
}

class _RefEq extends _SingleByteInstruction {
  const _RefEq() : super(0xD5);
}

class _BrOnNonNull implements _Instruction {
  final int labelIndex;

  _BrOnNonNull(this.labelIndex);

  @override
  void serialize(Serializer s) {
    s.writeByte(0xD6);
    s.writeUnsigned(labelIndex);
  }
}

class _StructGet implements _Instruction {
  final StructType structType;
  final int fieldIndex;

  _StructGet(this.structType, this.fieldIndex);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x03]);
    s.writeUnsigned(structType.index);
    s.writeUnsigned(fieldIndex);
  }
}

class _StructGetS implements _Instruction {
  final StructType structType;
  final int fieldIndex;

  _StructGetS(this.structType, this.fieldIndex);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x04]);
    s.writeUnsigned(structType.index);
    s.writeUnsigned(fieldIndex);
  }
}

class _StructGetU implements _Instruction {
  final StructType structType;
  final int fieldIndex;

  _StructGetU(this.structType, this.fieldIndex);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x05]);
    s.writeUnsigned(structType.index);
    s.writeUnsigned(fieldIndex);
  }
}

class _StructSet implements _Instruction {
  final StructType structType;
  final int fieldIndex;

  _StructSet(this.structType, this.fieldIndex);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x06]);
    s.writeUnsigned(structType.index);
    s.writeUnsigned(fieldIndex);
  }
}

class _StructNew implements _Instruction {
  final StructType structType;

  _StructNew(this.structType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x07]);
    s.writeUnsigned(structType.index);
  }
}

class _StructNewDefault implements _Instruction {
  final StructType structType;

  _StructNewDefault(this.structType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x08]);
    s.writeUnsigned(structType.index);
  }
}

class _ArrayGet implements _Instruction {
  final ArrayType arrayType;

  _ArrayGet(this.arrayType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x13]);
    s.writeUnsigned(arrayType.index);
  }
}

class _ArrayGetS implements _Instruction {
  final ArrayType arrayType;

  _ArrayGetS(this.arrayType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x14]);
    s.writeUnsigned(arrayType.index);
  }
}

class _ArrayGetU implements _Instruction {
  final ArrayType arrayType;

  _ArrayGetU(this.arrayType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x15]);
    s.writeUnsigned(arrayType.index);
  }
}

class _ArraySet implements _Instruction {
  final ArrayType arrayType;

  _ArraySet(this.arrayType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x16]);
    s.writeUnsigned(arrayType.index);
  }
}

class _ArrayLen extends _MultiByteInstruction {
  const _ArrayLen() : super(const [0xFB, 0x19]);
}

class _ArrayNewFixed implements _Instruction {
  final ArrayType arrayType;
  final int length;

  _ArrayNewFixed(this.arrayType, this.length);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x1a]);
    s.writeUnsigned(arrayType.index);
    s.writeUnsigned(length);
  }
}

class _ArrayNew implements _Instruction {
  final ArrayType arrayType;

  _ArrayNew(this.arrayType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x1b]);
    s.writeUnsigned(arrayType.index);
  }
}

class _ArrayNewDefault implements _Instruction {
  final ArrayType arrayType;

  _ArrayNewDefault(this.arrayType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x1c]);
    s.writeUnsigned(arrayType.index);
  }
}

class _ArrayNewData implements _Instruction {
  final ArrayType arrayType;
  final DataSegment data;

  _ArrayNewData(this.arrayType, this.data);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x1d]);
    s.writeUnsigned(arrayType.index);
    s.writeUnsigned(data.index);
  }
}

class _ArrayCopy implements _Instruction {
  final ArrayType destArrayType;
  final ArrayType sourceArrayType;

  _ArrayCopy({required this.destArrayType, required this.sourceArrayType});

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x18]);
    s.writeUnsigned(destArrayType.index);
    s.writeUnsigned(sourceArrayType.index);
  }
}

class _ArrayFill implements _Instruction {
  final ArrayType arrayType;

  _ArrayFill(this.arrayType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x0F]);
    s.writeUnsigned(arrayType.index);
  }
}

class _I31New extends _MultiByteInstruction {
  const _I31New() : super(const [0xFB, 0x20]);
}

class _I31GetS extends _MultiByteInstruction {
  const _I31GetS() : super(const [0xFB, 0x21]);
}

class _I31GetU extends _MultiByteInstruction {
  const _I31GetU() : super(const [0xFB, 0x22]);
}

class _RefTest implements _Instruction {
  final RefType targetType;

  _RefTest(this.targetType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(targetType.nullable ? const [0xFB, 0x48] : const [0xFB, 0x40]);
    s.write(targetType.heapType);
  }
}

class _RefCast implements _Instruction {
  final RefType targetType;

  _RefCast(this.targetType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(targetType.nullable ? const [0xFB, 0x49] : const [0xFB, 0x41]);
    s.write(targetType.heapType);
  }
}

class _BrOnCast implements _Instruction {
  final RefType targetType;
  final int labelIndex;

  _BrOnCast(this.targetType, this.labelIndex);

  @override
  void serialize(Serializer s) {
    s.writeBytes(targetType.nullable ? const [0xFB, 0x4A] : const [0xFB, 0x42]);
    s.writeUnsigned(labelIndex);
    s.write(targetType.heapType);
  }
}

class _BrOnCastFail implements _Instruction {
  final RefType targetType;
  final int labelIndex;

  _BrOnCastFail(this.targetType, this.labelIndex);

  @override
  void serialize(Serializer s) {
    s.writeBytes(targetType.nullable ? const [0xFB, 0x4B] : const [0xFB, 0x43]);
    s.writeUnsigned(labelIndex);
    s.write(targetType.heapType);
  }
}

class _ExternInternalize extends _MultiByteInstruction {
  const _ExternInternalize() : super(const [0xFB, 0x70]);
}

class _ExternExternalize extends _MultiByteInstruction {
  const _ExternExternalize() : super(const [0xFB, 0x71]);
}

class _I32Const implements _Instruction {
  final int value;

  _I32Const(this.value);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x41);
    s.writeSigned(value);
  }
}

class _I64Const implements _Instruction {
  final int value;

  _I64Const(this.value);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x42);
    s.writeSigned(value);
  }
}

class _F32Const implements _Instruction {
  final double value;

  _F32Const(this.value);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x43);
    s.writeF32(value);
  }
}

class _F64Const implements _Instruction {
  final double value;

  _F64Const(this.value);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x44);
    s.writeF64(value);
  }
}

class _I32Eqz extends _SingleByteInstruction {
  const _I32Eqz() : super(0x45);
}

class _I32Eq extends _SingleByteInstruction {
  const _I32Eq() : super(0x46);
}

class _I32Ne extends _SingleByteInstruction {
  const _I32Ne() : super(0x47);
}

class _I32LtS extends _SingleByteInstruction {
  const _I32LtS() : super(0x48);
}

class _I32LtU extends _SingleByteInstruction {
  const _I32LtU() : super(0x49);
}

class _I32GtS extends _SingleByteInstruction {
  const _I32GtS() : super(0x4A);
}

class _I32GtU extends _SingleByteInstruction {
  const _I32GtU() : super(0x4B);
}

class _I32LeS extends _SingleByteInstruction {
  const _I32LeS() : super(0x4C);
}

class _I32LeU extends _SingleByteInstruction {
  const _I32LeU() : super(0x4D);
}

class _I32GeS extends _SingleByteInstruction {
  const _I32GeS() : super(0x4E);
}

class _I32GeU extends _SingleByteInstruction {
  const _I32GeU() : super(0x4F);
}

class _I64Eqz extends _SingleByteInstruction {
  const _I64Eqz() : super(0x50);
}

class _I64Eq extends _SingleByteInstruction {
  const _I64Eq() : super(0x51);
}

class _I64Ne extends _SingleByteInstruction {
  const _I64Ne() : super(0x52);
}

class _I64LtS extends _SingleByteInstruction {
  const _I64LtS() : super(0x53);
}

class _I64LtU extends _SingleByteInstruction {
  const _I64LtU() : super(0x54);
}

class _I64GtS extends _SingleByteInstruction {
  const _I64GtS() : super(0x55);
}

class _I64GtU extends _SingleByteInstruction {
  const _I64GtU() : super(0x56);
}

class _I64LeS extends _SingleByteInstruction {
  const _I64LeS() : super(0x57);
}

class _I64LeU extends _SingleByteInstruction {
  const _I64LeU() : super(0x58);
}

class _I64GeS extends _SingleByteInstruction {
  const _I64GeS() : super(0x59);
}

class _I64GeU extends _SingleByteInstruction {
  const _I64GeU() : super(0x5A);
}

class _F32Eq extends _SingleByteInstruction {
  const _F32Eq() : super(0x5B);
}

class _F32Ne extends _SingleByteInstruction {
  const _F32Ne() : super(0x5C);
}

class _F32Lt extends _SingleByteInstruction {
  const _F32Lt() : super(0x5D);
}

class _F32Gt extends _SingleByteInstruction {
  const _F32Gt() : super(0x5E);
}

class _F32Le extends _SingleByteInstruction {
  const _F32Le() : super(0x5F);
}

class _F32Ge extends _SingleByteInstruction {
  const _F32Ge() : super(0x60);
}

class _F64Eq extends _SingleByteInstruction {
  const _F64Eq() : super(0x61);
}

class _F64Ne extends _SingleByteInstruction {
  const _F64Ne() : super(0x62);
}

class _F64Lt extends _SingleByteInstruction {
  const _F64Lt() : super(0x63);
}

class _F64Gt extends _SingleByteInstruction {
  const _F64Gt() : super(0x64);
}

class _F64Le extends _SingleByteInstruction {
  const _F64Le() : super(0x65);
}

class _F64Ge extends _SingleByteInstruction {
  const _F64Ge() : super(0x66);
}

class _I32Clz extends _SingleByteInstruction {
  const _I32Clz() : super(0x67);
}

class _I32Ctz extends _SingleByteInstruction {
  const _I32Ctz() : super(0x68);
}

class _I32Popcnt extends _SingleByteInstruction {
  const _I32Popcnt() : super(0x69);
}

class _I32Add extends _SingleByteInstruction {
  const _I32Add() : super(0x6A);
}

class _I32Sub extends _SingleByteInstruction {
  const _I32Sub() : super(0x6B);
}

class _I32Mul extends _SingleByteInstruction {
  const _I32Mul() : super(0x6C);
}

class _I32DivS extends _SingleByteInstruction {
  const _I32DivS() : super(0x6D);
}

class _I32DivU extends _SingleByteInstruction {
  const _I32DivU() : super(0x6E);
}

class _I32RemS extends _SingleByteInstruction {
  const _I32RemS() : super(0x6F);
}

class _I32RemU extends _SingleByteInstruction {
  const _I32RemU() : super(0x70);
}

class _I32And extends _SingleByteInstruction {
  const _I32And() : super(0x71);
}

class _I32Or extends _SingleByteInstruction {
  const _I32Or() : super(0x72);
}

class _I32Xor extends _SingleByteInstruction {
  const _I32Xor() : super(0x73);
}

class _I32Shl extends _SingleByteInstruction {
  const _I32Shl() : super(0x74);
}

class _I32ShrS extends _SingleByteInstruction {
  const _I32ShrS() : super(0x75);
}

class _I32ShrU extends _SingleByteInstruction {
  const _I32ShrU() : super(0x76);
}

class _I32Rotl extends _SingleByteInstruction {
  const _I32Rotl() : super(0x77);
}

class _I32Rotr extends _SingleByteInstruction {
  const _I32Rotr() : super(0x78);
}

class _I64Clz extends _SingleByteInstruction {
  const _I64Clz() : super(0x79);
}

class _I64Ctz extends _SingleByteInstruction {
  const _I64Ctz() : super(0x7A);
}

class _I64Popcnt extends _SingleByteInstruction {
  const _I64Popcnt() : super(0x7B);
}

class _I64Add extends _SingleByteInstruction {
  const _I64Add() : super(0x7C);
}

class _I64Sub extends _SingleByteInstruction {
  const _I64Sub() : super(0x7D);
}

class _I64Mul extends _SingleByteInstruction {
  const _I64Mul() : super(0x7E);
}

class _I64DivS extends _SingleByteInstruction {
  const _I64DivS() : super(0x7F);
}

class _I64DivU extends _SingleByteInstruction {
  const _I64DivU() : super(0x80);
}

class _I64RemS extends _SingleByteInstruction {
  const _I64RemS() : super(0x81);
}

class _I64RemU extends _SingleByteInstruction {
  const _I64RemU() : super(0x82);
}

class _I64And extends _SingleByteInstruction {
  const _I64And() : super(0x83);
}

class _I64Or extends _SingleByteInstruction {
  const _I64Or() : super(0x84);
}

class _I64Xor extends _SingleByteInstruction {
  const _I64Xor() : super(0x85);
}

class _I64Shl extends _SingleByteInstruction {
  const _I64Shl() : super(0x86);
}

class _I64ShrS extends _SingleByteInstruction {
  const _I64ShrS() : super(0x87);
}

class _I64ShrU extends _SingleByteInstruction {
  const _I64ShrU() : super(0x88);
}

class _I64Rotl extends _SingleByteInstruction {
  const _I64Rotl() : super(0x89);
}

class _I64Rotr extends _SingleByteInstruction {
  const _I64Rotr() : super(0x8A);
}

class _F32Abs extends _SingleByteInstruction {
  const _F32Abs() : super(0x8B);
}

class _F32Neg extends _SingleByteInstruction {
  const _F32Neg() : super(0x8C);
}

class _F32Ceil extends _SingleByteInstruction {
  const _F32Ceil() : super(0x8D);
}

class _F32Floor extends _SingleByteInstruction {
  const _F32Floor() : super(0x8E);
}

class _F32Trunc extends _SingleByteInstruction {
  const _F32Trunc() : super(0x8F);
}

class _F32Nearest extends _SingleByteInstruction {
  const _F32Nearest() : super(0x90);
}

class _F32Sqrt extends _SingleByteInstruction {
  const _F32Sqrt() : super(0x91);
}

class _F32Add extends _SingleByteInstruction {
  const _F32Add() : super(0x92);
}

class _F32Sub extends _SingleByteInstruction {
  const _F32Sub() : super(0x93);
}

class _F32Mul extends _SingleByteInstruction {
  const _F32Mul() : super(0x94);
}

class _F32Div extends _SingleByteInstruction {
  const _F32Div() : super(0x95);
}

class _F32Min extends _SingleByteInstruction {
  const _F32Min() : super(0x96);
}

class _F32Max extends _SingleByteInstruction {
  const _F32Max() : super(0x97);
}

class _F32Copysign extends _SingleByteInstruction {
  const _F32Copysign() : super(0x98);
}

class _F64Abs extends _SingleByteInstruction {
  const _F64Abs() : super(0x99);
}

class _F64Neg extends _SingleByteInstruction {
  const _F64Neg() : super(0x9A);
}

class _F64Ceil extends _SingleByteInstruction {
  const _F64Ceil() : super(0x9B);
}

class _F64Floor extends _SingleByteInstruction {
  const _F64Floor() : super(0x9C);
}

class _F64Trunc extends _SingleByteInstruction {
  const _F64Trunc() : super(0x9D);
}

class _F64Nearest extends _SingleByteInstruction {
  const _F64Nearest() : super(0x9E);
}

class _F64Sqrt extends _SingleByteInstruction {
  const _F64Sqrt() : super(0x9F);
}

class _F64Add extends _SingleByteInstruction {
  const _F64Add() : super(0xA0);
}

class _F64Sub extends _SingleByteInstruction {
  const _F64Sub() : super(0xA1);
}

class _F64Mul extends _SingleByteInstruction {
  const _F64Mul() : super(0xA2);
}

class _F64Div extends _SingleByteInstruction {
  const _F64Div() : super(0xA3);
}

class _F64Min extends _SingleByteInstruction {
  const _F64Min() : super(0xA4);
}

class _F64Max extends _SingleByteInstruction {
  const _F64Max() : super(0xA5);
}

class _F64Copysign extends _SingleByteInstruction {
  const _F64Copysign() : super(0xA6);
}

class _I32WrapI64 extends _SingleByteInstruction {
  const _I32WrapI64() : super(0xA7);
}

class _I32TruncF32S extends _SingleByteInstruction {
  const _I32TruncF32S() : super(0xA8);
}

class _I32TruncF32U extends _SingleByteInstruction {
  const _I32TruncF32U() : super(0xA9);
}

class _I32TruncF64S extends _SingleByteInstruction {
  const _I32TruncF64S() : super(0xAA);
}

class _I32TruncF64U extends _SingleByteInstruction {
  const _I32TruncF64U() : super(0xAB);
}

class _I64ExtendI32S extends _SingleByteInstruction {
  const _I64ExtendI32S() : super(0xAC);
}

class _I64ExtendI32U extends _SingleByteInstruction {
  const _I64ExtendI32U() : super(0xAD);
}

class _I64TruncF32S extends _SingleByteInstruction {
  const _I64TruncF32S() : super(0xAE);
}

class _I64TruncF32U extends _SingleByteInstruction {
  const _I64TruncF32U() : super(0xAF);
}

class _I64TruncF64S extends _SingleByteInstruction {
  const _I64TruncF64S() : super(0xB0);
}

class _I64TruncF64U extends _SingleByteInstruction {
  const _I64TruncF64U() : super(0xB1);
}

class _F32ConvertI32S extends _SingleByteInstruction {
  const _F32ConvertI32S() : super(0xB2);
}

class _F32ConvertI32U extends _SingleByteInstruction {
  const _F32ConvertI32U() : super(0xB3);
}

class _F32ConvertI64S extends _SingleByteInstruction {
  const _F32ConvertI64S() : super(0xB4);
}

class _F32ConvertI64U extends _SingleByteInstruction {
  const _F32ConvertI64U() : super(0xB5);
}

class _F32DemoteF64 extends _SingleByteInstruction {
  const _F32DemoteF64() : super(0xB6);
}

class _F64ConvertI32S extends _SingleByteInstruction {
  const _F64ConvertI32S() : super(0xB7);
}

class _F64ConvertI32U extends _SingleByteInstruction {
  const _F64ConvertI32U() : super(0xB8);
}

class _F64ConvertI64S extends _SingleByteInstruction {
  const _F64ConvertI64S() : super(0xB9);
}

class _F64ConvertI64U extends _SingleByteInstruction {
  const _F64ConvertI64U() : super(0xBA);
}

class _F64PromoteF32 extends _SingleByteInstruction {
  const _F64PromoteF32() : super(0xBB);
}

class _I32ReinterpretF32 extends _SingleByteInstruction {
  const _I32ReinterpretF32() : super(0xBC);
}

class _I64ReinterpretF64 extends _SingleByteInstruction {
  const _I64ReinterpretF64() : super(0xBD);
}

class _F32ReinterpretI32 extends _SingleByteInstruction {
  const _F32ReinterpretI32() : super(0xBE);
}

class _F64ReinterpretI64 extends _SingleByteInstruction {
  const _F64ReinterpretI64() : super(0xBF);
}

class _I32Extend8S extends _SingleByteInstruction {
  const _I32Extend8S() : super(0xC0);
}

class _I32Extend16S extends _SingleByteInstruction {
  const _I32Extend16S() : super(0xC1);
}

class _I64Extend8S extends _SingleByteInstruction {
  const _I64Extend8S() : super(0xC2);
}

class _I64Extend16S extends _SingleByteInstruction {
  const _I64Extend16S() : super(0xC3);
}

class _I64Extend32S extends _SingleByteInstruction {
  const _I64Extend32S() : super(0xC4);
}

class _I32TruncSatF32S extends _MultiByteInstruction {
  const _I32TruncSatF32S() : super(const [0xFC, 0x00]);
}

class _I32TruncSatF32U extends _MultiByteInstruction {
  const _I32TruncSatF32U() : super(const [0xFC, 0x01]);
}

class _I32TruncSatF64S extends _MultiByteInstruction {
  const _I32TruncSatF64S() : super(const [0xFC, 0x02]);
}

class _I32TruncSatF64U extends _MultiByteInstruction {
  const _I32TruncSatF64U() : super(const [0xFC, 0x03]);
}

class _I64TruncSatF32S extends _MultiByteInstruction {
  const _I64TruncSatF32S() : super(const [0xFC, 0x04]);
}

class _I64TruncSatF32U extends _MultiByteInstruction {
  const _I64TruncSatF32U() : super(const [0xFC, 0x05]);
}

class _I64TruncSatF64S extends _MultiByteInstruction {
  const _I64TruncSatF64S() : super(const [0xFC, 0x06]);
}

class _I64TruncSatF64U extends _MultiByteInstruction {
  const _I64TruncSatF64U() : super(const [0xFC, 0x07]);
}
