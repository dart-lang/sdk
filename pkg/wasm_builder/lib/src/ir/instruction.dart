// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'instructions.dart';

abstract class Instruction implements Serializable {}

abstract class SingleByteInstruction implements Instruction {
  final int byte;

  const SingleByteInstruction(this.byte);

  @override
  void serialize(Serializer s) => s.writeByte(byte);
}

abstract class MultiByteInstruction implements Instruction {
  final List<int> bytes;

  const MultiByteInstruction(this.bytes);

  @override
  void serialize(Serializer s) => s.writeBytes(bytes);
}

class Unreachable extends SingleByteInstruction {
  const Unreachable() : super(0x00);
}

class Nop extends SingleByteInstruction {
  const Nop() : super(0x01);
}

class BeginNoEffectBlock extends MultiByteInstruction {
  const BeginNoEffectBlock() : super(const [0x02, 0x40]);
}

class BeginOneOutputBlock implements Instruction {
  final ValueType type;

  BeginOneOutputBlock(this.type);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x02);
    s.write(type);
  }
}

class BeginFunctionBlock implements Instruction {
  final FunctionType type;

  BeginFunctionBlock(this.type);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x02);
    s.writeSigned(type.index);
  }
}

class BeginNoEffectLoop extends MultiByteInstruction {
  const BeginNoEffectLoop() : super(const [0x03, 0x40]);
}

class BeginOneOutputLoop implements Instruction {
  final ValueType type;

  BeginOneOutputLoop(this.type);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x03);
    s.write(type);
  }
}

class BeginFunctionLoop implements Instruction {
  final FunctionType type;

  BeginFunctionLoop(this.type);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x03);
    s.writeSigned(type.index);
  }
}

class BeginNoEffectIf extends MultiByteInstruction {
  const BeginNoEffectIf() : super(const [0x04, 0x40]);
}

class BeginOneOutputIf implements Instruction {
  final ValueType type;

  BeginOneOutputIf(this.type);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x04);
    s.write(type);
  }
}

class BeginFunctionIf implements Instruction {
  final FunctionType type;

  BeginFunctionIf(this.type);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x04);
    s.writeSigned(type.index);
  }
}

class Else extends SingleByteInstruction {
  const Else() : super(0x05);
}

class BeginNoEffectTry extends MultiByteInstruction {
  const BeginNoEffectTry() : super(const [0x06, 0x40]);
}

class BeginOneOutputTry implements Instruction {
  final ValueType type;

  BeginOneOutputTry(this.type);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x06);
    s.write(type);
  }
}

class BeginFunctionTry implements Instruction {
  final FunctionType type;

  BeginFunctionTry(this.type);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x06);
    s.writeSigned(type.index);
  }
}

class Catch implements Instruction {
  final Tag tag;

  Catch(this.tag);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x07);
    s.writeUnsigned(tag.index);
  }
}

class CatchAll extends SingleByteInstruction {
  const CatchAll() : super(0x19);
}

class Throw implements Instruction {
  final Tag tag;

  Throw(this.tag);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x08);
    s.writeUnsigned(tag.index);
  }
}

class Rethrow implements Instruction {
  final int labelIndex;

  Rethrow(this.labelIndex);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x09);
    s.writeUnsigned(labelIndex);
  }
}

class End extends SingleByteInstruction {
  const End() : super(0x0B);
}

class Br implements Instruction {
  final int labelIndex;

  Br(this.labelIndex);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x0C);
    s.writeUnsigned(labelIndex);
  }
}

class BrIf implements Instruction {
  final int labelIndex;

  BrIf(this.labelIndex);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x0D);
    s.writeUnsigned(labelIndex);
  }
}

class BrTable implements Instruction {
  final List<int> labelIndices;
  final int defaultLabelIndex;

  BrTable(this.labelIndices, this.defaultLabelIndex);

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

class Return extends SingleByteInstruction {
  const Return() : super(0x0F);
}

class Call implements Instruction {
  final BaseFunction function;

  Call(this.function);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x10);
    s.writeUnsigned(function.index);
  }
}

class CallIndirect implements Instruction {
  final FunctionType type;
  final Table? table;

  CallIndirect(this.type, this.table);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x11);
    s.writeUnsigned(type.index);
    s.writeUnsigned(table?.index ?? 0);
  }
}

class CallRef implements Instruction {
  final FunctionType type;

  CallRef(this.type);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x14);
    s.writeUnsigned(type.index);
  }
}

class Drop extends SingleByteInstruction {
  const Drop() : super(0x1A);
}

class Select implements Instruction {
  final ValueType type;

  Select(this.type);

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

class LocalGet implements Instruction {
  final Local local;

  LocalGet(this.local);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x20);
    s.writeUnsigned(local.index);
  }
}

class LocalSet implements Instruction {
  final Local local;

  LocalSet(this.local);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x21);
    s.writeUnsigned(local.index);
  }
}

class LocalTee implements Instruction {
  final Local local;

  LocalTee(this.local);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x22);
    s.writeUnsigned(local.index);
  }
}

class GlobalGet implements Instruction {
  final Global global;

  GlobalGet(this.global);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x23);
    s.writeUnsigned(global.index);
  }
}

class GlobalSet implements Instruction {
  final Global global;

  GlobalSet(this.global);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x24);
    s.writeUnsigned(global.index);
  }
}

class TableSet implements Instruction {
  final Table table;

  TableSet(this.table);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x25);
    s.writeUnsigned(table.index);
  }
}

class TableGet implements Instruction {
  final Table table;

  TableGet(this.table);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x26);
    s.writeUnsigned(table.index);
  }
}

class TableSize implements Instruction {
  final Table table;

  TableSize(this.table);

  @override
  void serialize(Serializer s) {
    s.writeBytes([0xFC, 0x10]);
    s.writeUnsigned(table.index);
  }
}

class MemoryOffsetAlign implements Serializable {
  final Memory memory;
  final int offset;
  final int align;

  MemoryOffsetAlign(this.memory, {required this.offset, required this.align});

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

abstract class MemoryInstruction implements Instruction {
  final MemoryOffsetAlign memory;
  final int encoding;

  MemoryInstruction(this.memory, {required this.encoding});

  @override
  void serialize(Serializer s) {
    s.writeByte(encoding);
    memory.serialize(s);
  }
}

class I32Load extends MemoryInstruction {
  I32Load(super.memory) : super(encoding: 0x28);
}

class I64Load extends MemoryInstruction {
  I64Load(super.memory) : super(encoding: 0x29);
}

class F32Load extends MemoryInstruction {
  F32Load(super.memory) : super(encoding: 0x2A);
}

class F64Load extends MemoryInstruction {
  F64Load(super.memory) : super(encoding: 0x2B);
}

class I32Load8S extends MemoryInstruction {
  I32Load8S(super.memory) : super(encoding: 0x2C);
}

class I32Load8U extends MemoryInstruction {
  I32Load8U(super.memory) : super(encoding: 0x2D);
}

class I32Load16S extends MemoryInstruction {
  I32Load16S(super.memory) : super(encoding: 0x2E);
}

class I32Load16U extends MemoryInstruction {
  I32Load16U(super.memory) : super(encoding: 0x2F);
}

class I64Load8S extends MemoryInstruction {
  I64Load8S(super.memory) : super(encoding: 0x30);
}

class I64Load8U extends MemoryInstruction {
  I64Load8U(super.memory) : super(encoding: 0x31);
}

class I64Load16S extends MemoryInstruction {
  I64Load16S(super.memory) : super(encoding: 0x32);
}

class I64Load16U extends MemoryInstruction {
  I64Load16U(super.memory) : super(encoding: 0x33);
}

class I64Load32S extends MemoryInstruction {
  I64Load32S(super.memory) : super(encoding: 0x34);
}

class I64Load32U extends MemoryInstruction {
  I64Load32U(super.memory) : super(encoding: 0x35);
}

class I32Store extends MemoryInstruction {
  I32Store(super.memory) : super(encoding: 0x36);
}

class I64Store extends MemoryInstruction {
  I64Store(super.memory) : super(encoding: 0x37);
}

class F32Store extends MemoryInstruction {
  F32Store(super.memory) : super(encoding: 0x38);
}

class F64Store extends MemoryInstruction {
  F64Store(super.memory) : super(encoding: 0x39);
}

class I32Store8 extends MemoryInstruction {
  I32Store8(super.memory) : super(encoding: 0x3A);
}

class I32Store16 extends MemoryInstruction {
  I32Store16(super.memory) : super(encoding: 0x3B);
}

class I64Store8 extends MemoryInstruction {
  I64Store8(super.memory) : super(encoding: 0x3C);
}

class I64Store16 extends MemoryInstruction {
  I64Store16(super.memory) : super(encoding: 0x3D);
}

class I64Store32 extends MemoryInstruction {
  I64Store32(super.memory) : super(encoding: 0x3E);
}

class MemorySize implements Instruction {
  final Memory memory;

  MemorySize(this.memory);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x3F);
    s.writeUnsigned(memory.index);
  }
}

class MemoryGrow implements Instruction {
  final Memory memory;

  MemoryGrow(this.memory);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x40);
    s.writeUnsigned(memory.index);
  }
}

class RefNull implements Instruction {
  final HeapType heapType;

  RefNull(this.heapType);

  @override
  void serialize(Serializer s) {
    s.writeByte(0xD0);
    s.write(heapType);
  }
}

class RefIsNull extends SingleByteInstruction {
  const RefIsNull() : super(0xD1);
}

class RefFunc implements Instruction {
  final BaseFunction function;

  RefFunc(this.function);

  @override
  void serialize(Serializer s) {
    s.writeByte(0xD2);
    s.writeUnsigned(function.index);
  }
}

class RefAsNonNull extends SingleByteInstruction {
  const RefAsNonNull() : super(0xD4);
}

class BrOnNull implements Instruction {
  final int labelIndex;

  BrOnNull(this.labelIndex);

  @override
  void serialize(Serializer s) {
    s.writeByte(0xD5);
    s.writeUnsigned(labelIndex);
  }
}

class RefEq extends SingleByteInstruction {
  const RefEq() : super(0xD3);
}

class BrOnNonNull implements Instruction {
  final int labelIndex;

  BrOnNonNull(this.labelIndex);

  @override
  void serialize(Serializer s) {
    s.writeByte(0xD6);
    s.writeUnsigned(labelIndex);
  }
}

class StructGet implements Instruction {
  final StructType structType;
  final int fieldIndex;

  StructGet(this.structType, this.fieldIndex);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x02]);
    s.writeUnsigned(structType.index);
    s.writeUnsigned(fieldIndex);
  }
}

class StructGetS implements Instruction {
  final StructType structType;
  final int fieldIndex;

  StructGetS(this.structType, this.fieldIndex);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x03]);
    s.writeUnsigned(structType.index);
    s.writeUnsigned(fieldIndex);
  }
}

class StructGetU implements Instruction {
  final StructType structType;
  final int fieldIndex;

  StructGetU(this.structType, this.fieldIndex);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x04]);
    s.writeUnsigned(structType.index);
    s.writeUnsigned(fieldIndex);
  }
}

class StructSet implements Instruction {
  final StructType structType;
  final int fieldIndex;

  StructSet(this.structType, this.fieldIndex);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x05]);
    s.writeUnsigned(structType.index);
    s.writeUnsigned(fieldIndex);
  }
}

class StructNew implements Instruction {
  final StructType structType;

  StructNew(this.structType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x00]);
    s.writeUnsigned(structType.index);
  }
}

class StructNewDefault implements Instruction {
  final StructType structType;

  StructNewDefault(this.structType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x01]);
    s.writeUnsigned(structType.index);
  }
}

class ArrayGet implements Instruction {
  final ArrayType arrayType;

  ArrayGet(this.arrayType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x0b]);
    s.writeUnsigned(arrayType.index);
  }
}

class ArrayGetS implements Instruction {
  final ArrayType arrayType;

  ArrayGetS(this.arrayType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x0c]);
    s.writeUnsigned(arrayType.index);
  }
}

class ArrayGetU implements Instruction {
  final ArrayType arrayType;

  ArrayGetU(this.arrayType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x0d]);
    s.writeUnsigned(arrayType.index);
  }
}

class ArraySet implements Instruction {
  final ArrayType arrayType;

  ArraySet(this.arrayType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x0E]);
    s.writeUnsigned(arrayType.index);
  }
}

class ArrayLen extends MultiByteInstruction {
  const ArrayLen() : super(const [0xFB, 0x0F]);
}

class ArrayNewFixed implements Instruction {
  final ArrayType arrayType;
  final int length;

  ArrayNewFixed(this.arrayType, this.length);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x08]);
    s.writeUnsigned(arrayType.index);
    s.writeUnsigned(length);
  }
}

class ArrayNew implements Instruction {
  final ArrayType arrayType;

  ArrayNew(this.arrayType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x06]);
    s.writeUnsigned(arrayType.index);
  }
}

class ArrayNewDefault implements Instruction {
  final ArrayType arrayType;

  ArrayNewDefault(this.arrayType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x07]);
    s.writeUnsigned(arrayType.index);
  }
}

class ArrayNewData implements Instruction {
  final ArrayType arrayType;
  final BaseDataSegment data;

  ArrayNewData(this.arrayType, this.data);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x09]);
    s.writeUnsigned(arrayType.index);
    s.writeUnsigned(data.index);
  }
}

class ArrayCopy implements Instruction {
  final ArrayType destArrayType;
  final ArrayType sourceArrayType;

  ArrayCopy({required this.destArrayType, required this.sourceArrayType});

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x11]);
    s.writeUnsigned(destArrayType.index);
    s.writeUnsigned(sourceArrayType.index);
  }
}

class ArrayFill implements Instruction {
  final ArrayType arrayType;

  ArrayFill(this.arrayType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(const [0xFB, 0x10]);
    s.writeUnsigned(arrayType.index);
  }
}

class I31New extends MultiByteInstruction {
  const I31New() : super(const [0xFB, 0x1C]);
}

class I31GetS extends MultiByteInstruction {
  const I31GetS() : super(const [0xFB, 0x1D]);
}

class I31GetU extends MultiByteInstruction {
  const I31GetU() : super(const [0xFB, 0x1E]);
}

class RefTest implements Instruction {
  final RefType targetType;

  RefTest(this.targetType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(targetType.nullable ? const [0xFB, 0x15] : const [0xFB, 0x14]);
    s.write(targetType.heapType);
  }
}

class RefCast implements Instruction {
  final RefType targetType;

  RefCast(this.targetType);

  @override
  void serialize(Serializer s) {
    s.writeBytes(targetType.nullable ? const [0xFB, 0x17] : const [0xFB, 0x16]);
    s.write(targetType.heapType);
  }
}

class BrOnCast implements Instruction {
  final int labelIndex;
  final RefType inputType;
  final RefType targetType;

  BrOnCast(this.labelIndex, this.inputType, this.targetType);

  @override
  void serialize(Serializer s) {
    int flags = (inputType.nullable ? 0x01 : 0x00) |
        (targetType.nullable ? 0x02 : 0x00);
    s.writeBytes(const [0xFB, 0x18]);
    s.writeByte(flags);
    s.writeUnsigned(labelIndex);
    s.write(inputType.heapType);
    s.write(targetType.heapType);
  }
}

class BrOnCastFail implements Instruction {
  final int labelIndex;
  final RefType inputType;
  final RefType targetType;

  BrOnCastFail(this.labelIndex, this.inputType, this.targetType);

  @override
  void serialize(Serializer s) {
    int flags = (inputType.nullable ? 0x01 : 0x00) |
        (targetType.nullable ? 0x02 : 0x00);
    s.writeBytes(const [0xFB, 0x19]);
    s.writeByte(flags);
    s.writeUnsigned(labelIndex);
    s.write(inputType.heapType);
    s.write(targetType.heapType);
  }
}

class ExternInternalize extends MultiByteInstruction {
  const ExternInternalize() : super(const [0xFB, 0x1A]);
}

class ExternExternalize extends MultiByteInstruction {
  const ExternExternalize() : super(const [0xFB, 0x1B]);
}

class I32Const implements Instruction {
  final int value;

  I32Const(this.value);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x41);
    s.writeSigned(value);
  }
}

class I64Const implements Instruction {
  final int value;

  I64Const(this.value);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x42);
    s.writeSigned(value);
  }
}

class F32Const implements Instruction {
  final double value;

  F32Const(this.value);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x43);
    s.writeF32(value);
  }
}

class F64Const implements Instruction {
  final double value;

  F64Const(this.value);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x44);
    s.writeF64(value);
  }
}

class I32Eqz extends SingleByteInstruction {
  const I32Eqz() : super(0x45);
}

class I32Eq extends SingleByteInstruction {
  const I32Eq() : super(0x46);
}

class I32Ne extends SingleByteInstruction {
  const I32Ne() : super(0x47);
}

class I32LtS extends SingleByteInstruction {
  const I32LtS() : super(0x48);
}

class I32LtU extends SingleByteInstruction {
  const I32LtU() : super(0x49);
}

class I32GtS extends SingleByteInstruction {
  const I32GtS() : super(0x4A);
}

class I32GtU extends SingleByteInstruction {
  const I32GtU() : super(0x4B);
}

class I32LeS extends SingleByteInstruction {
  const I32LeS() : super(0x4C);
}

class I32LeU extends SingleByteInstruction {
  const I32LeU() : super(0x4D);
}

class I32GeS extends SingleByteInstruction {
  const I32GeS() : super(0x4E);
}

class I32GeU extends SingleByteInstruction {
  const I32GeU() : super(0x4F);
}

class I64Eqz extends SingleByteInstruction {
  const I64Eqz() : super(0x50);
}

class I64Eq extends SingleByteInstruction {
  const I64Eq() : super(0x51);
}

class I64Ne extends SingleByteInstruction {
  const I64Ne() : super(0x52);
}

class I64LtS extends SingleByteInstruction {
  const I64LtS() : super(0x53);
}

class I64LtU extends SingleByteInstruction {
  const I64LtU() : super(0x54);
}

class I64GtS extends SingleByteInstruction {
  const I64GtS() : super(0x55);
}

class I64GtU extends SingleByteInstruction {
  const I64GtU() : super(0x56);
}

class I64LeS extends SingleByteInstruction {
  const I64LeS() : super(0x57);
}

class I64LeU extends SingleByteInstruction {
  const I64LeU() : super(0x58);
}

class I64GeS extends SingleByteInstruction {
  const I64GeS() : super(0x59);
}

class I64GeU extends SingleByteInstruction {
  const I64GeU() : super(0x5A);
}

class F32Eq extends SingleByteInstruction {
  const F32Eq() : super(0x5B);
}

class F32Ne extends SingleByteInstruction {
  const F32Ne() : super(0x5C);
}

class F32Lt extends SingleByteInstruction {
  const F32Lt() : super(0x5D);
}

class F32Gt extends SingleByteInstruction {
  const F32Gt() : super(0x5E);
}

class F32Le extends SingleByteInstruction {
  const F32Le() : super(0x5F);
}

class F32Ge extends SingleByteInstruction {
  const F32Ge() : super(0x60);
}

class F64Eq extends SingleByteInstruction {
  const F64Eq() : super(0x61);
}

class F64Ne extends SingleByteInstruction {
  const F64Ne() : super(0x62);
}

class F64Lt extends SingleByteInstruction {
  const F64Lt() : super(0x63);
}

class F64Gt extends SingleByteInstruction {
  const F64Gt() : super(0x64);
}

class F64Le extends SingleByteInstruction {
  const F64Le() : super(0x65);
}

class F64Ge extends SingleByteInstruction {
  const F64Ge() : super(0x66);
}

class I32Clz extends SingleByteInstruction {
  const I32Clz() : super(0x67);
}

class I32Ctz extends SingleByteInstruction {
  const I32Ctz() : super(0x68);
}

class I32Popcnt extends SingleByteInstruction {
  const I32Popcnt() : super(0x69);
}

class I32Add extends SingleByteInstruction {
  const I32Add() : super(0x6A);
}

class I32Sub extends SingleByteInstruction {
  const I32Sub() : super(0x6B);
}

class I32Mul extends SingleByteInstruction {
  const I32Mul() : super(0x6C);
}

class I32DivS extends SingleByteInstruction {
  const I32DivS() : super(0x6D);
}

class I32DivU extends SingleByteInstruction {
  const I32DivU() : super(0x6E);
}

class I32RemS extends SingleByteInstruction {
  const I32RemS() : super(0x6F);
}

class I32RemU extends SingleByteInstruction {
  const I32RemU() : super(0x70);
}

class I32And extends SingleByteInstruction {
  const I32And() : super(0x71);
}

class I32Or extends SingleByteInstruction {
  const I32Or() : super(0x72);
}

class I32Xor extends SingleByteInstruction {
  const I32Xor() : super(0x73);
}

class I32Shl extends SingleByteInstruction {
  const I32Shl() : super(0x74);
}

class I32ShrS extends SingleByteInstruction {
  const I32ShrS() : super(0x75);
}

class I32ShrU extends SingleByteInstruction {
  const I32ShrU() : super(0x76);
}

class I32Rotl extends SingleByteInstruction {
  const I32Rotl() : super(0x77);
}

class I32Rotr extends SingleByteInstruction {
  const I32Rotr() : super(0x78);
}

class I64Clz extends SingleByteInstruction {
  const I64Clz() : super(0x79);
}

class I64Ctz extends SingleByteInstruction {
  const I64Ctz() : super(0x7A);
}

class I64Popcnt extends SingleByteInstruction {
  const I64Popcnt() : super(0x7B);
}

class I64Add extends SingleByteInstruction {
  const I64Add() : super(0x7C);
}

class I64Sub extends SingleByteInstruction {
  const I64Sub() : super(0x7D);
}

class I64Mul extends SingleByteInstruction {
  const I64Mul() : super(0x7E);
}

class I64DivS extends SingleByteInstruction {
  const I64DivS() : super(0x7F);
}

class I64DivU extends SingleByteInstruction {
  const I64DivU() : super(0x80);
}

class I64RemS extends SingleByteInstruction {
  const I64RemS() : super(0x81);
}

class I64RemU extends SingleByteInstruction {
  const I64RemU() : super(0x82);
}

class I64And extends SingleByteInstruction {
  const I64And() : super(0x83);
}

class I64Or extends SingleByteInstruction {
  const I64Or() : super(0x84);
}

class I64Xor extends SingleByteInstruction {
  const I64Xor() : super(0x85);
}

class I64Shl extends SingleByteInstruction {
  const I64Shl() : super(0x86);
}

class I64ShrS extends SingleByteInstruction {
  const I64ShrS() : super(0x87);
}

class I64ShrU extends SingleByteInstruction {
  const I64ShrU() : super(0x88);
}

class I64Rotl extends SingleByteInstruction {
  const I64Rotl() : super(0x89);
}

class I64Rotr extends SingleByteInstruction {
  const I64Rotr() : super(0x8A);
}

class F32Abs extends SingleByteInstruction {
  const F32Abs() : super(0x8B);
}

class F32Neg extends SingleByteInstruction {
  const F32Neg() : super(0x8C);
}

class F32Ceil extends SingleByteInstruction {
  const F32Ceil() : super(0x8D);
}

class F32Floor extends SingleByteInstruction {
  const F32Floor() : super(0x8E);
}

class F32Trunc extends SingleByteInstruction {
  const F32Trunc() : super(0x8F);
}

class F32Nearest extends SingleByteInstruction {
  const F32Nearest() : super(0x90);
}

class F32Sqrt extends SingleByteInstruction {
  const F32Sqrt() : super(0x91);
}

class F32Add extends SingleByteInstruction {
  const F32Add() : super(0x92);
}

class F32Sub extends SingleByteInstruction {
  const F32Sub() : super(0x93);
}

class F32Mul extends SingleByteInstruction {
  const F32Mul() : super(0x94);
}

class F32Div extends SingleByteInstruction {
  const F32Div() : super(0x95);
}

class F32Min extends SingleByteInstruction {
  const F32Min() : super(0x96);
}

class F32Max extends SingleByteInstruction {
  const F32Max() : super(0x97);
}

class F32Copysign extends SingleByteInstruction {
  const F32Copysign() : super(0x98);
}

class F64Abs extends SingleByteInstruction {
  const F64Abs() : super(0x99);
}

class F64Neg extends SingleByteInstruction {
  const F64Neg() : super(0x9A);
}

class F64Ceil extends SingleByteInstruction {
  const F64Ceil() : super(0x9B);
}

class F64Floor extends SingleByteInstruction {
  const F64Floor() : super(0x9C);
}

class F64Trunc extends SingleByteInstruction {
  const F64Trunc() : super(0x9D);
}

class F64Nearest extends SingleByteInstruction {
  const F64Nearest() : super(0x9E);
}

class F64Sqrt extends SingleByteInstruction {
  const F64Sqrt() : super(0x9F);
}

class F64Add extends SingleByteInstruction {
  const F64Add() : super(0xA0);
}

class F64Sub extends SingleByteInstruction {
  const F64Sub() : super(0xA1);
}

class F64Mul extends SingleByteInstruction {
  const F64Mul() : super(0xA2);
}

class F64Div extends SingleByteInstruction {
  const F64Div() : super(0xA3);
}

class F64Min extends SingleByteInstruction {
  const F64Min() : super(0xA4);
}

class F64Max extends SingleByteInstruction {
  const F64Max() : super(0xA5);
}

class F64Copysign extends SingleByteInstruction {
  const F64Copysign() : super(0xA6);
}

class I32WrapI64 extends SingleByteInstruction {
  const I32WrapI64() : super(0xA7);
}

class I32TruncF32S extends SingleByteInstruction {
  const I32TruncF32S() : super(0xA8);
}

class I32TruncF32U extends SingleByteInstruction {
  const I32TruncF32U() : super(0xA9);
}

class I32TruncF64S extends SingleByteInstruction {
  const I32TruncF64S() : super(0xAA);
}

class I32TruncF64U extends SingleByteInstruction {
  const I32TruncF64U() : super(0xAB);
}

class I64ExtendI32S extends SingleByteInstruction {
  const I64ExtendI32S() : super(0xAC);
}

class I64ExtendI32U extends SingleByteInstruction {
  const I64ExtendI32U() : super(0xAD);
}

class I64TruncF32S extends SingleByteInstruction {
  const I64TruncF32S() : super(0xAE);
}

class I64TruncF32U extends SingleByteInstruction {
  const I64TruncF32U() : super(0xAF);
}

class I64TruncF64S extends SingleByteInstruction {
  const I64TruncF64S() : super(0xB0);
}

class I64TruncF64U extends SingleByteInstruction {
  const I64TruncF64U() : super(0xB1);
}

class F32ConvertI32S extends SingleByteInstruction {
  const F32ConvertI32S() : super(0xB2);
}

class F32ConvertI32U extends SingleByteInstruction {
  const F32ConvertI32U() : super(0xB3);
}

class F32ConvertI64S extends SingleByteInstruction {
  const F32ConvertI64S() : super(0xB4);
}

class F32ConvertI64U extends SingleByteInstruction {
  const F32ConvertI64U() : super(0xB5);
}

class F32DemoteF64 extends SingleByteInstruction {
  const F32DemoteF64() : super(0xB6);
}

class F64ConvertI32S extends SingleByteInstruction {
  const F64ConvertI32S() : super(0xB7);
}

class F64ConvertI32U extends SingleByteInstruction {
  const F64ConvertI32U() : super(0xB8);
}

class F64ConvertI64S extends SingleByteInstruction {
  const F64ConvertI64S() : super(0xB9);
}

class F64ConvertI64U extends SingleByteInstruction {
  const F64ConvertI64U() : super(0xBA);
}

class F64PromoteF32 extends SingleByteInstruction {
  const F64PromoteF32() : super(0xBB);
}

class I32ReinterpretF32 extends SingleByteInstruction {
  const I32ReinterpretF32() : super(0xBC);
}

class I64ReinterpretF64 extends SingleByteInstruction {
  const I64ReinterpretF64() : super(0xBD);
}

class F32ReinterpretI32 extends SingleByteInstruction {
  const F32ReinterpretI32() : super(0xBE);
}

class F64ReinterpretI64 extends SingleByteInstruction {
  const F64ReinterpretI64() : super(0xBF);
}

class I32Extend8S extends SingleByteInstruction {
  const I32Extend8S() : super(0xC0);
}

class I32Extend16S extends SingleByteInstruction {
  const I32Extend16S() : super(0xC1);
}

class I64Extend8S extends SingleByteInstruction {
  const I64Extend8S() : super(0xC2);
}

class I64Extend16S extends SingleByteInstruction {
  const I64Extend16S() : super(0xC3);
}

class I64Extend32S extends SingleByteInstruction {
  const I64Extend32S() : super(0xC4);
}

class I32TruncSatF32S extends MultiByteInstruction {
  const I32TruncSatF32S() : super(const [0xFC, 0x00]);
}

class I32TruncSatF32U extends MultiByteInstruction {
  const I32TruncSatF32U() : super(const [0xFC, 0x01]);
}

class I32TruncSatF64S extends MultiByteInstruction {
  const I32TruncSatF64S() : super(const [0xFC, 0x02]);
}

class I32TruncSatF64U extends MultiByteInstruction {
  const I32TruncSatF64U() : super(const [0xFC, 0x03]);
}

class I64TruncSatF32S extends MultiByteInstruction {
  const I64TruncSatF32S() : super(const [0xFC, 0x04]);
}

class I64TruncSatF32U extends MultiByteInstruction {
  const I64TruncSatF32U() : super(const [0xFC, 0x05]);
}

class I64TruncSatF64S extends MultiByteInstruction {
  const I64TruncSatF64S() : super(const [0xFC, 0x06]);
}

class I64TruncSatF64U extends MultiByteInstruction {
  const I64TruncSatF64U() : super(const [0xFC, 0x07]);
}
