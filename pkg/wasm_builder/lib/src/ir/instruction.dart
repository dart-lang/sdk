// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../serialize/printer.dart';
import '../serialize/serialize.dart';
import 'ir.dart';

abstract mixin class Instruction implements Serializable {
  /// The [ValueType] types referenced by this instruction. Used to determine
  /// which types need to be included in the module. Unused types will not be
  /// emitted in the wasm output.
  List<ValueType> get usedValueTypes => const [];

  /// The [DefType] types referenced by this instruction. Used to determine
  /// which types need to be included in the module. Unused types will not be
  /// emitted in the wasm output.
  List<DefType> get usedDefTypes => const [];

  const Instruction();

  /// Whether the instruction is a "constant instruction", as defined by the
  /// Wasm spec.
  ///
  /// Constant instructions can be used in global initializers, element
  /// segments, data segments.
  bool get isConstant => false;

  /// The name of the instruction.
  String get name;

  /// Prints the text representation of this instruction to [p].
  ///
  /// Instructions that have fields should override this.
  void printTo(IrPrinter p) {
    p.write(name);
  }

  static Instruction deserializeConst(
      Deserializer d, Types types, Functions functions, Globals globals,
      {bool isConstOnlyUse = true}) {
    final byte = d.readByte();
    switch (byte) {
      case 0x0B:
        return End.deserialize(d);
      case 0x23:
        return GlobalGet.deserialize(d, globals);
      case 0x41:
        return I32Const.deserialize(d);
      case 0x42:
        return I64Const.deserialize(d);
      case 0x43:
        return F32Const.deserialize(d);
      case 0x44:
        return F64Const.deserialize(d);
      case 0xD0:
        return RefNull.deserialize(d, types);
      case 0xD2:
        return RefFunc.deserialize(d, functions);
      case 0xFB:
        {
          final byte2 = d.readByte();
          return switch (byte2) {
            0x00 => StructNew.deserialize(d, types),
            0x01 => StructNewDefault.deserialize(d, types),
            0x06 => ArrayNew.deserialize(d, types),
            0x07 => ArrayNewDefault.deserialize(d, types),
            0x08 => ArrayNewFixed.deserialize(d, types),
            0x1A => ExternInternalize.deserialize(d),
            0x1B => ExternExternalize.deserialize(d),
            _ =>
              throw "Invalid ${isConstOnlyUse ? 'const ' : ''}instruction byte: $byte $byte2"
          };
        }
      default:
        throw "Invalid ${isConstOnlyUse ? 'const ' : ''}instruction byte: $byte";
    }
  }

  static Instruction deserialize(
    Deserializer d,
    Types types,
    Tables tables,
    Tags tags,
    Globals globals,
    DataSegments dataSegments,
    Memories memories,
    Functions functions,
  ) {
    final instructionStart = d.offset;
    final byte = d.readByte();
    switch (byte) {
      case 0x00:
        return Unreachable.deserialize(d);
      case 0x01:
        return Nop.deserialize(d);
      case 0x02:
        return d.deserializeBlock(types, tags, BeginNoEffectBlock.deserialize,
            BeginOneOutputBlock.deserialize, BeginFunctionBlock.deserialize);
      case 0x03:
        return d.deserializeBlock(types, tags, BeginNoEffectLoop.deserialize,
            BeginOneOutputLoop.deserialize, BeginFunctionLoop.deserialize);
      case 0x04:
        return d.deserializeBlock(types, tags, BeginNoEffectIf.deserialize,
            BeginOneOutputIf.deserialize, BeginFunctionIf.deserialize);
      case 0x05:
        return Else.deserialize(d);
      case 0x06:
        return d.deserializeBlock(types, tags, BeginNoEffectTry.deserialize,
            BeginOneOutputTry.deserialize, BeginFunctionTry.deserialize);
      case 0x07:
        return CatchLegacy.deserialize(d, tags);
      case 0x08:
        return Throw.deserialize(d, tags);
      case 0x09:
        return Rethrow.deserialize(d);
      case 0x0A:
        return ThrowRef.deserialize(d);
      case 0x0C:
        return Br.deserialize(d);
      case 0x0D:
        return BrIf.deserialize(d);
      case 0x0E:
        return BrTable.deserialize(d);
      case 0x0F:
        return Return.deserialize(d);
      case 0x10:
        return Call.deserialize(d, functions);
      case 0x11:
        return CallIndirect.deserialize(d, types, tables);
      case 0x14:
        return CallRef.deserialize(d, types);
      case 0x19:
        return CatchAllLegacy.deserialize(d);
      case 0x1A:
        return Drop.deserialize(d);
      case 0x1B:
        return Select.deserialize(d);
      case 0x1C:
        return SelectWithType.deserialize(d, types);
      case 0x1F:
        return d.deserializeBlock(
            types,
            tags,
            BeginNoEffectTryTable.deserialize,
            BeginOneOutputTryTable.deserialize,
            BeginFunctionTryTable.deserialize);
      case 0x20:
        return LocalGet.deserialize(d);
      case 0x21:
        return LocalSet.deserialize(d);
      case 0x22:
        return LocalTee.deserialize(d);
      case 0x24:
        return GlobalSet.deserialize(d, globals);
      case 0x25:
        return TableGet.deserialize(d, tables);
      case 0x26:
        return TableSet.deserialize(d, tables);
      case 0x28:
        return I32Load.deserialize(d, memories);
      case 0x29:
        return I64Load.deserialize(d, memories);
      case 0x2A:
        return F32Load.deserialize(d, memories);
      case 0x2B:
        return F64Load.deserialize(d, memories);
      case 0x2C:
        return I32Load8S.deserialize(d, memories);
      case 0x2D:
        return I32Load8U.deserialize(d, memories);
      case 0x2E:
        return I32Load16S.deserialize(d, memories);
      case 0x2F:
        return I32Load16U.deserialize(d, memories);
      case 0x30:
        return I64Load8S.deserialize(d, memories);
      case 0x31:
        return I64Load8U.deserialize(d, memories);
      case 0x32:
        return I64Load16S.deserialize(d, memories);
      case 0x33:
        return I64Load16U.deserialize(d, memories);
      case 0x34:
        return I64Load32S.deserialize(d, memories);
      case 0x35:
        return I64Load32U.deserialize(d, memories);
      case 0x36:
        return I32Store.deserialize(d, memories);
      case 0x37:
        return I64Store.deserialize(d, memories);
      case 0x38:
        return F32Store.deserialize(d, memories);
      case 0x39:
        return F64Store.deserialize(d, memories);
      case 0x3A:
        return I32Store8.deserialize(d, memories);
      case 0x3B:
        return I32Store16.deserialize(d, memories);
      case 0x3C:
        return I64Store8.deserialize(d, memories);
      case 0x3D:
        return I64Store16.deserialize(d, memories);
      case 0x3E:
        return I64Store32.deserialize(d, memories);
      case 0x3F:
        return MemorySize.deserialize(d, memories);
      case 0x40:
        return MemoryGrow.deserialize(d, memories);
      case 0x45:
        return I32Eqz.deserialize(d);
      case 0x46:
        return I32Eq.deserialize(d);
      case 0x47:
        return I32Ne.deserialize(d);
      case 0x48:
        return I32LtS.deserialize(d);
      case 0x49:
        return I32LtU.deserialize(d);
      case 0x4A:
        return I32GtS.deserialize(d);
      case 0x4B:
        return I32GtU.deserialize(d);
      case 0x4C:
        return I32LeS.deserialize(d);
      case 0x4D:
        return I32LeU.deserialize(d);
      case 0x4E:
        return I32GeS.deserialize(d);
      case 0x4F:
        return I32GeU.deserialize(d);
      case 0x50:
        return I64Eqz.deserialize(d);
      case 0x51:
        return I64Eq.deserialize(d);
      case 0x52:
        return I64Ne.deserialize(d);
      case 0x53:
        return I64LtS.deserialize(d);
      case 0x54:
        return I64LtU.deserialize(d);
      case 0x55:
        return I64GtS.deserialize(d);
      case 0x56:
        return I64GtU.deserialize(d);
      case 0x57:
        return I64LeS.deserialize(d);
      case 0x58:
        return I64LeU.deserialize(d);
      case 0x59:
        return I64GeS.deserialize(d);
      case 0x5A:
        return I64GeU.deserialize(d);
      case 0x5B:
        return F32Eq.deserialize(d);
      case 0x5C:
        return F32Ne.deserialize(d);
      case 0x5D:
        return F32Lt.deserialize(d);
      case 0x5E:
        return F32Gt.deserialize(d);
      case 0x5F:
        return F32Le.deserialize(d);
      case 0x60:
        return F32Ge.deserialize(d);
      case 0x61:
        return F64Eq.deserialize(d);
      case 0x62:
        return F64Ne.deserialize(d);
      case 0x63:
        return F64Lt.deserialize(d);
      case 0x64:
        return F64Gt.deserialize(d);
      case 0x65:
        return F64Le.deserialize(d);
      case 0x66:
        return F64Ge.deserialize(d);
      case 0x67:
        return I32Clz.deserialize(d);
      case 0x68:
        return I32Ctz.deserialize(d);
      case 0x69:
        return I32Popcnt.deserialize(d);
      case 0x6A:
        return I32Add.deserialize(d);
      case 0x6B:
        return I32Sub.deserialize(d);
      case 0x6C:
        return I32Mul.deserialize(d);
      case 0x6D:
        return I32DivS.deserialize(d);
      case 0x6E:
        return I32DivU.deserialize(d);
      case 0x6F:
        return I32RemS.deserialize(d);
      case 0x70:
        return I32RemU.deserialize(d);
      case 0x71:
        return I32And.deserialize(d);
      case 0x72:
        return I32Or.deserialize(d);
      case 0x73:
        return I32Xor.deserialize(d);
      case 0x74:
        return I32Shl.deserialize(d);
      case 0x75:
        return I32ShrS.deserialize(d);
      case 0x76:
        return I32ShrU.deserialize(d);
      case 0x77:
        return I32Rotl.deserialize(d);
      case 0x78:
        return I32Rotr.deserialize(d);
      case 0x79:
        return I64Clz.deserialize(d);
      case 0x7A:
        return I64Ctz.deserialize(d);
      case 0x7B:
        return I64Popcnt.deserialize(d);
      case 0x7C:
        return I64Add.deserialize(d);
      case 0x7D:
        return I64Sub.deserialize(d);
      case 0x7E:
        return I64Mul.deserialize(d);
      case 0x7F:
        return I64DivS.deserialize(d);
      case 0x80:
        return I64DivU.deserialize(d);
      case 0x81:
        return I64RemS.deserialize(d);
      case 0x82:
        return I64RemU.deserialize(d);
      case 0x83:
        return I64And.deserialize(d);
      case 0x84:
        return I64Or.deserialize(d);
      case 0x85:
        return I64Xor.deserialize(d);
      case 0x86:
        return I64Shl.deserialize(d);
      case 0x87:
        return I64ShrS.deserialize(d);
      case 0x88:
        return I64ShrU.deserialize(d);
      case 0x89:
        return I64Rotl.deserialize(d);
      case 0x8A:
        return I64Rotr.deserialize(d);
      case 0x8B:
        return F32Abs.deserialize(d);
      case 0x8C:
        return F32Neg.deserialize(d);
      case 0x8D:
        return F32Ceil.deserialize(d);
      case 0x8E:
        return F32Floor.deserialize(d);
      case 0x8F:
        return F32Trunc.deserialize(d);
      case 0x90:
        return F32Nearest.deserialize(d);
      case 0x91:
        return F32Sqrt.deserialize(d);
      case 0x92:
        return F32Add.deserialize(d);
      case 0x93:
        return F32Sub.deserialize(d);
      case 0x94:
        return F32Mul.deserialize(d);
      case 0x95:
        return F32Div.deserialize(d);
      case 0x96:
        return F32Min.deserialize(d);
      case 0x97:
        return F32Max.deserialize(d);
      case 0x98:
        return F32Copysign.deserialize(d);
      case 0x99:
        return F64Abs.deserialize(d);
      case 0x9A:
        return F64Neg.deserialize(d);
      case 0x9B:
        return F64Ceil.deserialize(d);
      case 0x9C:
        return F64Floor.deserialize(d);
      case 0x9D:
        return F64Trunc.deserialize(d);
      case 0x9E:
        return F64Nearest.deserialize(d);
      case 0x9F:
        return F64Sqrt.deserialize(d);
      case 0xA0:
        return F64Add.deserialize(d);
      case 0xA1:
        return F64Sub.deserialize(d);
      case 0xA2:
        return F64Mul.deserialize(d);
      case 0xA3:
        return F64Div.deserialize(d);
      case 0xA4:
        return F64Min.deserialize(d);
      case 0xA5:
        return F64Max.deserialize(d);
      case 0xA6:
        return F64Copysign.deserialize(d);
      case 0xA7:
        return I32WrapI64.deserialize(d);
      case 0xA8:
        return I32TruncF32S.deserialize(d);
      case 0xA9:
        return I32TruncF32U.deserialize(d);
      case 0xAA:
        return I32TruncF64S.deserialize(d);
      case 0xAB:
        return I32TruncF64U.deserialize(d);
      case 0xAC:
        return I64ExtendI32S.deserialize(d);
      case 0xAD:
        return I64ExtendI32U.deserialize(d);
      case 0xAE:
        return I64TruncF32S.deserialize(d);
      case 0xAF:
        return I64TruncF32U.deserialize(d);
      case 0xB0:
        return I64TruncF64S.deserialize(d);
      case 0xB1:
        return I64TruncF64U.deserialize(d);
      case 0xB2:
        return F32ConvertI32S.deserialize(d);
      case 0xB3:
        return F32ConvertI32U.deserialize(d);
      case 0xB4:
        return F32ConvertI64S.deserialize(d);
      case 0xB5:
        return F32ConvertI64U.deserialize(d);
      case 0xB6:
        return F32DemoteF64.deserialize(d);
      case 0xB7:
        return F64ConvertI32S.deserialize(d);
      case 0xB8:
        return F64ConvertI32U.deserialize(d);
      case 0xB9:
        return F64ConvertI64S.deserialize(d);
      case 0xBA:
        return F64ConvertI64U.deserialize(d);
      case 0xBB:
        return F64PromoteF32.deserialize(d);
      case 0xBC:
        return I32ReinterpretF32.deserialize(d);
      case 0xBD:
        return I64ReinterpretF64.deserialize(d);
      case 0xBE:
        return F32ReinterpretI32.deserialize(d);
      case 0xBF:
        return F64ReinterpretI64.deserialize(d);
      case 0xC0:
        return I32Extend8S.deserialize(d);
      case 0xC1:
        return I32Extend16S.deserialize(d);
      case 0xC2:
        return I64Extend8S.deserialize(d);
      case 0xC3:
        return I64Extend16S.deserialize(d);
      case 0xC4:
        return I64Extend32S.deserialize(d);
      case 0xD1:
        return RefIsNull.deserialize(d);
      case 0xD3:
        return RefEq.deserialize(d);
      case 0xD4:
        return RefAsNonNull.deserialize(d);
      case 0xD5:
        return BrOnNull.deserialize(d);
      case 0xD6:
        return BrOnNonNull.deserialize(d);
      case 0xFB:
        {
          final opcode = d.readByte();
          switch (opcode) {
            case 0x02:
              return StructGet.deserialize(d, types);
            case 0x03:
              return StructGetS.deserialize(d, types);
            case 0x04:
              return StructGetU.deserialize(d, types);
            case 0x05:
              return StructSet.deserialize(d, types);
            case 0x09:
              return ArrayNewData.deserialize(d, types, dataSegments);
            case 0x0b:
              return ArrayGet.deserialize(d, types);
            case 0x0c:
              return ArrayGetS.deserialize(d, types);
            case 0x0d:
              return ArrayGetU.deserialize(d, types);
            case 0x0E:
              return ArraySet.deserialize(d, types);
            case 0x0F:
              return ArrayLen.deserialize(d);
            case 0x10:
              return ArrayFill.deserialize(d, types);
            case 0x11:
              return ArrayCopy.deserialize(d, types);
            case 0x14:
              return RefTest.deserialize(d, types, false);
            case 0x15:
              return RefTest.deserialize(d, types, true);
            case 0x16:
              return RefCast.deserialize(d, types, false);
            case 0x17:
              return RefCast.deserialize(d, types, true);
            case 0x18:
              return BrOnCast.deserialize(d, types);
            case 0x19:
              return BrOnCastFail.deserialize(d, types);
            case 0x1C:
              return I31New.deserialize(d);
            case 0x1D:
              return I31GetS.deserialize(d);
            case 0x1E:
              return I31GetU.deserialize(d);
            default:
              d.offset = instructionStart;
              return deserializeConst(d, types, functions, globals,
                  isConstOnlyUse: false);
          }
        }
      case 0xFC:
        {
          final opcode = d.readByte();
          return switch (opcode) {
            0x00 => I32TruncSatF32S.deserialize(d),
            0x01 => I32TruncSatF32U.deserialize(d),
            0x02 => I32TruncSatF64S.deserialize(d),
            0x03 => I32TruncSatF64U.deserialize(d),
            0x04 => I64TruncSatF32S.deserialize(d),
            0x05 => I64TruncSatF32U.deserialize(d),
            0x06 => I64TruncSatF64S.deserialize(d),
            0x07 => I64TruncSatF64U.deserialize(d),
            0x0B => MemoryFill.deserialize(d, memories),
            0x10 => TableSize.deserialize(d, tables),
            0x11 => TableFill.deserialize(d, tables),
            _ => throw "Invalid instruction byte: 0xFC $opcode"
          };
        }
      case 0xFD:
        {
          final opcode = d.readUnsigned();
          final instruction = V128Instruction.fromOpcode(opcode);
          if (instruction != null) return instruction;
          return switch (opcode) {
            0x0D => I8x16Shuffle.deserialize(d),
            0x15 => I8x16ExtractLaneS.deserialize(d),
            0x16 => I8x16ExtractLaneU.deserialize(d),
            0x17 => I8x16ReplaceLane.deserialize(d),
            0x18 => I16x8ExtractLaneS.deserialize(d),
            0x19 => I16x8ExtractLaneU.deserialize(d),
            0x1A => I16x8ReplaceLane.deserialize(d),
            0x1B => I32x4ExtractLane.deserialize(d),
            0x1C => I32x4ReplaceLane.deserialize(d),
            0x1D => I64x2ExtractLane.deserialize(d),
            0x1E => I64x2ReplaceLane.deserialize(d),
            0x1F => F32x4ExtractLane.deserialize(d),
            0x20 => F32x4ReplaceLane.deserialize(d),
            0x21 => F64x2ExtractLane.deserialize(d),
            0x22 => F64x2ReplaceLane.deserialize(d),
            _ => throw "Invalid instruction byte: 0xFD $opcode"
          };
        }
      default:
        d.offset = instructionStart;
        return deserializeConst(d, types, functions, globals,
            isConstOnlyUse: false);
    }
  }
}

abstract class SingleByteInstruction extends Instruction {
  final int byte;

  const SingleByteInstruction(this.byte);

  @override
  void serialize(Serializer s) => s.writeByte(byte);
}

class Unreachable extends SingleByteInstruction {
  const Unreachable() : super(0x00);

  static Unreachable deserialize(Deserializer d) => const Unreachable();

  @override
  String get name => 'unreachable';
}

class Nop extends SingleByteInstruction {
  const Nop() : super(0x01);

  static Nop deserialize(Deserializer d) => const Nop();

  @override
  String get name => 'nop';
}

class BeginNoEffectBlock extends Instruction {
  const BeginNoEffectBlock();

  static BeginNoEffectBlock deserialize(Deserializer d, Tags _) {
    d.readByte();
    return const BeginNoEffectBlock();
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x02);
    s.writeByte(0x40);
  }

  @override
  String get name => 'block';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeLabelDefinition(0);
  }
}

class BeginOneOutputBlock extends Instruction {
  final ValueType type;

  @override
  List<ValueType> get usedValueTypes => [type];

  BeginOneOutputBlock(this.type);

  static BeginOneOutputBlock deserialize(Deserializer d, Tags _, Types types) {
    final type = ValueType.deserialize(d, types.defined);
    assert(type is! FunctionType);
    return BeginOneOutputBlock(type);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x02);
    s.write(type);
  }

  @override
  String get name => 'block';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeLabelDefinition(0);
    p.write(' ');
    p.write('(result ');
    p.writeValueType(type);
    p.write(')');
  }
}

class BeginFunctionBlock extends Instruction {
  final FunctionType type;

  @override
  List<DefType> get usedDefTypes => [type];

  BeginFunctionBlock(this.type);

  static BeginFunctionBlock deserialize(Deserializer d, Tags _, Types types) {
    return BeginFunctionBlock(types.defined[d.readSigned()] as FunctionType);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x02);
    s.write(type);
  }

  @override
  String get name => 'block';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeLabelDefinition(0);
    p.write(' ');
    p.writeFunctionType(type);
  }
}

class BeginNoEffectLoop extends Instruction {
  const BeginNoEffectLoop();

  @override
  void serialize(Serializer s) {
    s.writeByte(0x03);
    s.writeByte(0x40);
  }

  static BeginNoEffectLoop deserialize(Deserializer d, Tags _) {
    d.readByte();
    return const BeginNoEffectLoop();
  }

  @override
  String get name => 'loop';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeLabelDefinition(0);
  }
}

class BeginOneOutputLoop extends Instruction {
  final ValueType type;

  @override
  List<ValueType> get usedValueTypes => [type];

  BeginOneOutputLoop(this.type);

  static BeginOneOutputLoop deserialize(Deserializer d, Tags _, Types types) {
    final type = ValueType.deserialize(d, types.defined);
    return BeginOneOutputLoop(type);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x03);
    s.write(type);
  }

  @override
  String get name => 'loop';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeLabelDefinition(0);
    p.write(' ');
    p.writeValueType(type);
  }
}

class BeginFunctionLoop extends Instruction {
  final FunctionType type;

  @override
  List<DefType> get usedDefTypes => [type];

  BeginFunctionLoop(this.type);

  static BeginFunctionLoop deserialize(Deserializer d, Tags _, Types types) {
    return BeginFunctionLoop(types.defined[d.readSigned()] as FunctionType);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x03);
    s.write(type);
  }

  @override
  String get name => 'loop';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeLabelDefinition(0);
    p.write(' ');
    p.writeFunctionType(type);
  }
}

class BeginNoEffectIf extends Instruction {
  const BeginNoEffectIf();

  @override
  void serialize(Serializer s) {
    s.writeByte(0x04);
    s.writeByte(0x40);
  }

  static BeginNoEffectIf deserialize(Deserializer d, Tags _) {
    d.readByte();
    return const BeginNoEffectIf();
  }

  @override
  String get name => 'if';
}

class BeginOneOutputIf extends Instruction {
  final ValueType type;

  @override
  List<ValueType> get usedValueTypes => [type];

  BeginOneOutputIf(this.type);

  static BeginOneOutputIf deserialize(Deserializer d, Tags _, Types types) {
    final type = ValueType.deserialize(d, types.defined);
    return BeginOneOutputIf(type);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x04);
    s.write(type);
  }

  @override
  String get name => 'if';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' (result ');
    p.writeValueType(type);
    p.write(')');
  }
}

class BeginFunctionIf extends Instruction {
  final FunctionType type;

  @override
  List<DefType> get usedDefTypes => [type];

  BeginFunctionIf(this.type);

  static BeginFunctionIf deserialize(Deserializer d, Tags _, Types types) {
    return BeginFunctionIf(types.defined[d.readSigned()] as FunctionType);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x04);
    s.write(type);
  }

  @override
  String get name => 'if';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeFunctionType(type);
  }
}

class Else extends SingleByteInstruction {
  const Else() : super(0x05);

  static Else deserialize(Deserializer d) => const Else();

  @override
  String get name => 'else';
}

class BeginNoEffectTry extends Instruction {
  const BeginNoEffectTry();

  static BeginNoEffectTry deserialize(Deserializer d, Tags _) {
    d.readByte();
    return const BeginNoEffectTry();
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x06);
    s.writeByte(0x40);
  }

  @override
  String get name => 'try';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeLabelDefinition(0);
  }
}

class BeginOneOutputTry extends Instruction {
  final ValueType type;

  @override
  List<ValueType> get usedValueTypes => [type];

  BeginOneOutputTry(this.type);

  static BeginOneOutputTry deserialize(Deserializer d, Tags _, Types types) {
    final type = ValueType.deserialize(d, types.defined);
    assert(type is! FunctionType);
    return BeginOneOutputTry(type);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x06);
    s.write(type);
  }

  @override
  String get name => 'try';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeLabelDefinition(0);
    p.write(' ');
    p.writeValueType(type);
  }
}

class BeginFunctionTry extends Instruction {
  final FunctionType type;

  @override
  List<DefType> get usedDefTypes => [type];

  BeginFunctionTry(this.type);

  static BeginFunctionTry deserialize(Deserializer d, Tags _, Types types) {
    return BeginFunctionTry(types.defined[d.readSigned()] as FunctionType);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x06);
    s.write(type);
  }

  @override
  String get name => 'try';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeLabelDefinition(0);
    p.write(' ');
    p.writeFunctionType(type);
  }
}

class CatchLegacy extends Instruction {
  final Tag tag;

  CatchLegacy(this.tag);

  static CatchLegacy deserialize(Deserializer d, Tags tags) {
    return CatchLegacy(tags[d.readUnsigned()]);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x07);
    s.writeUnsigned(tag.index);
  }

  @override
  String get name => 'catch';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeTagReference(tag);
  }
}

class CatchAllLegacy extends SingleByteInstruction {
  const CatchAllLegacy() : super(0x19);

  static CatchAllLegacy deserialize(Deserializer d) => const CatchAllLegacy();

  @override
  String get name => 'catch_all';
}

class Throw extends Instruction {
  final Tag tag;

  Throw(this.tag);

  static Throw deserialize(Deserializer d, Tags tags) {
    return Throw(tags[d.readUnsigned()]);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x08);
    s.writeUnsigned(tag.index);
  }

  @override
  String get name => 'throw';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeTagReference(tag);
  }
}

class ThrowRef extends Instruction {
  const ThrowRef();

  static ThrowRef deserialize(Deserializer d) => const ThrowRef();

  @override
  void serialize(Serializer s) {
    s.writeByte(0x0a);
  }

  @override
  String get name => 'throw_ref';
}

class Rethrow extends Instruction {
  final int labelIndex;

  Rethrow(this.labelIndex);

  static Rethrow deserialize(Deserializer d) => Rethrow(d.readUnsigned());

  @override
  void serialize(Serializer s) {
    s.writeByte(0x09);
    s.writeUnsigned(labelIndex);
  }

  @override
  String get name => 'rethrow';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeLabelReference(labelIndex);
  }
}

class End extends SingleByteInstruction {
  const End() : super(0x0B);

  @override
  bool get isConstant => true;

  static End deserialize(Deserializer d) {
    return const End();
  }

  @override
  String get name => 'end';
}

class Br extends Instruction {
  final int labelIndex;

  Br(this.labelIndex);

  static Br deserialize(Deserializer d) => Br(d.readUnsigned());

  @override
  void serialize(Serializer s) {
    s.writeByte(0x0C);
    s.writeUnsigned(labelIndex);
  }

  @override
  String get name => 'br';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeLabelReference(labelIndex);
  }
}

class BrIf extends Instruction {
  final int labelIndex;

  BrIf(this.labelIndex);

  static BrIf deserialize(Deserializer d) => BrIf(d.readUnsigned());

  @override
  void serialize(Serializer s) {
    s.writeByte(0x0D);
    s.writeUnsigned(labelIndex);
  }

  @override
  String get name => 'br_if';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeLabelReference(labelIndex);
  }
}

class BrTable extends Instruction {
  final List<int> labelIndices;
  final int defaultLabelIndex;

  BrTable(this.labelIndices, this.defaultLabelIndex);

  static BrTable deserialize(Deserializer d) {
    return BrTable(d.readList((d) => d.readUnsigned()), d.readUnsigned());
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x0E);
    s.writeUnsigned(labelIndices.length);
    for (final labelIndex in labelIndices) {
      s.writeUnsigned(labelIndex);
    }
    s.writeUnsigned(defaultLabelIndex);
  }

  @override
  String get name => 'br_table';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    for (final labelIndex in labelIndices) {
      p.write(' ');
      p.writeLabelReference(labelIndex);
    }
    p.write(' ');
    p.writeLabelReference(defaultLabelIndex);
  }
}

class Return extends SingleByteInstruction {
  const Return() : super(0x0F);

  static Return deserialize(Deserializer d) => const Return();

  @override
  String get name => 'return';
}

class Call extends Instruction {
  final BaseFunction function;

  Call(this.function);

  static Call deserialize(Deserializer d, Functions functions) {
    return Call(functions[d.readUnsigned()]);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x10);
    s.writeUnsigned(function.index);
  }

  @override
  String get name => 'call';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeFunctionReference(function);
  }
}

class CallIndirect extends Instruction {
  final FunctionType type;
  final Table? table;

  @override
  List<DefType> get usedDefTypes => [type];

  CallIndirect(this.type, this.table);

  static CallIndirect deserialize(Deserializer d, Types types, Tables tables) {
    final type = types.defined[d.readTypeIndex()] as FunctionType;
    final table = tables[d.readUnsigned()];
    return CallIndirect(type, table);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x11);
    s.writeTypeIndex(type);
    s.writeUnsigned(table?.index ?? 0);
  }

  @override
  String get name => 'call_indirect';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.writeTableReference(table);
    p.write(' ');
    p.writeFunctionType(type);
  }
}

class CallRef extends Instruction {
  final FunctionType type;

  @override
  List<DefType> get usedDefTypes => [type];

  CallRef(this.type);

  static CallRef deserialize(Deserializer d, Types types) {
    return CallRef(types.defined[d.readTypeIndex()] as FunctionType);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x14);
    s.writeTypeIndex(type);
  }

  @override
  String get name => 'call_ref';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeDefTypeReference(type);
  }
}

class Drop extends SingleByteInstruction {
  const Drop() : super(0x1A);

  static Drop deserialize(Deserializer d) => const Drop();

  @override
  String get name => 'drop';
}

class Select extends Instruction {
  @override
  List<ValueType> get usedValueTypes => [];

  const Select();

  static Select deserialize(Deserializer d) {
    return const Select();
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x1B);
  }

  @override
  String get name => 'select';
}

class SelectWithType extends Instruction {
  final ValueType type;

  @override
  List<ValueType> get usedValueTypes => [type];

  SelectWithType(this.type);

  static SelectWithType deserialize(Deserializer d, Types types) {
    d.readUnsigned(); // vec_len
    return SelectWithType(ValueType.deserialize(d, types.defined));
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x1C);
    s.writeUnsigned(1);
    s.write(type);
  }

  @override
  String get name => 'select';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeValueType(type);
  }
}

class LocalGet extends Instruction {
  final Local local;

  LocalGet(this.local);

  static LocalGet deserialize(Deserializer d) {
    return LocalGet(Local(d.readUnsigned(), NumType.i32));
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x20);
    s.writeUnsigned(local.index);
  }

  @override
  String get name => 'local.get';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeLocalReference(local);
  }
}

class LocalSet extends Instruction {
  final Local local;

  LocalSet(this.local);

  static LocalSet deserialize(Deserializer d) {
    return LocalSet(Local(d.readUnsigned(), NumType.i32));
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x21);
    s.writeUnsigned(local.index);
  }

  @override
  String get name => 'local.set';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeLocalReference(local);
  }
}

class LocalTee extends Instruction {
  final Local local;

  LocalTee(this.local);

  static LocalTee deserialize(Deserializer d) {
    return LocalTee(Local(d.readUnsigned(), NumType.i32));
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x22);
    s.writeUnsigned(local.index);
  }

  @override
  String get name => 'local.tee';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeLocalReference(local);
  }
}

class GlobalGet extends Instruction {
  final Global global;

  GlobalGet(this.global);

  static GlobalGet deserialize(Deserializer d, Globals globals) {
    return GlobalGet(globals[d.readUnsigned()]);
  }

  @override
  bool get isConstant => true;

  @override
  void serialize(Serializer s) {
    s.writeByte(0x23);
    s.writeUnsigned(global.index);
  }

  @override
  String get name => 'global.get';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeGlobalReference(global);
  }
}

class GlobalSet extends Instruction {
  final Global global;

  GlobalSet(this.global);

  static GlobalSet deserialize(Deserializer d, Globals globals) {
    return GlobalSet(globals[d.readUnsigned()]);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x24);
    s.writeUnsigned(global.index);
  }

  @override
  String get name => 'global.set';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeGlobalReference(global);
  }
}

class TableSet extends Instruction {
  final Table table;

  TableSet(this.table);

  static TableSet deserialize(Deserializer d, Tables tables) {
    return TableSet(tables[d.readUnsigned()]);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x26);
    s.writeUnsigned(table.index);
  }

  @override
  String get name => 'table.set';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.writeTableReference(table);
  }
}

class TableGet extends Instruction {
  final Table table;

  TableGet(this.table);

  static TableGet deserialize(Deserializer d, Tables tables) {
    return TableGet(tables[d.readUnsigned()]);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x25);
    s.writeUnsigned(table.index);
  }

  @override
  String get name => 'table.get';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.writeTableReference(table);
  }
}

class TableFill extends Instruction {
  final Table table;

  TableFill(this.table);

  static TableFill deserialize(Deserializer d, Tables tables) {
    return TableFill(tables[d.readUnsigned()]);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFC);
    s.writeByte(0x11);
    s.writeUnsigned(table.index);
  }

  @override
  String get name => 'table.fill';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.writeTableReference(table);
  }
}

class TableSize extends Instruction {
  final Table table;

  TableSize(this.table);

  static TableSize deserialize(Deserializer d, Tables tables) {
    return TableSize(tables[d.readUnsigned()]);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFC);
    s.writeByte(0x10);
    s.writeUnsigned(table.index);
  }

  @override
  String get name => 'table.size';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.writeTableReference(table);
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

  static MemoryOffsetAlign deserialize(Deserializer d, Memories memories) {
    final alignAndMemory = d.readByte();
    final align = alignAndMemory & 0x3F;
    final offset = d.readUnsigned();
    final memoryIndex = (alignAndMemory & 0x40) != 0 ? d.readUnsigned() : 0;
    return MemoryOffsetAlign(memories[memoryIndex],
        offset: offset, align: align);
  }

  void printTo(IrPrinter p) {
    if (memory.index != 0) {
      p.writeMemoryReference(memory);
    }
    if (offset != 0) {
      p.write(' offset=$offset');
    }
    if (align != 0) {
      p.write(' align=${1 << align}');
    }
  }
}

abstract class MemoryInstruction extends Instruction {
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

  static I32Load deserialize(Deserializer d, Memories memories) {
    return I32Load(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'i32.load';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class I64Load extends MemoryInstruction {
  I64Load(super.memory) : super(encoding: 0x29);

  static I64Load deserialize(Deserializer d, Memories memories) {
    return I64Load(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'i64.load';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class F32Load extends MemoryInstruction {
  F32Load(super.memory) : super(encoding: 0x2A);

  static F32Load deserialize(Deserializer d, Memories memories) {
    return F32Load(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'f32.load';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class F64Load extends MemoryInstruction {
  F64Load(super.memory) : super(encoding: 0x2B);

  static F64Load deserialize(Deserializer d, Memories memories) {
    return F64Load(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'f64.load';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class I32Load8S extends MemoryInstruction {
  I32Load8S(super.memory) : super(encoding: 0x2C);

  static I32Load8S deserialize(Deserializer d, Memories memories) {
    return I32Load8S(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'i32.load8_s';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class I32Load8U extends MemoryInstruction {
  I32Load8U(super.memory) : super(encoding: 0x2D);

  static I32Load8U deserialize(Deserializer d, Memories memories) {
    return I32Load8U(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'i32.load8_u';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class I32Load16S extends MemoryInstruction {
  I32Load16S(super.memory) : super(encoding: 0x2E);

  static I32Load16S deserialize(Deserializer d, Memories memories) {
    return I32Load16S(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'i32.load16_s';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class I32Load16U extends MemoryInstruction {
  I32Load16U(super.memory) : super(encoding: 0x2F);

  static I32Load16U deserialize(Deserializer d, Memories memories) {
    return I32Load16U(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'i32.load16_u';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class I64Load8S extends MemoryInstruction {
  I64Load8S(super.memory) : super(encoding: 0x30);

  static I64Load8S deserialize(Deserializer d, Memories memories) {
    return I64Load8S(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'i64.load8_s';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class I64Load8U extends MemoryInstruction {
  I64Load8U(super.memory) : super(encoding: 0x31);

  static I64Load8U deserialize(Deserializer d, Memories memories) {
    return I64Load8U(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'i64.load8_u';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class I64Load16S extends MemoryInstruction {
  I64Load16S(super.memory) : super(encoding: 0x32);

  static I64Load16S deserialize(Deserializer d, Memories memories) {
    return I64Load16S(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'i64.load16_s';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class I64Load16U extends MemoryInstruction {
  I64Load16U(super.memory) : super(encoding: 0x33);

  static I64Load16U deserialize(Deserializer d, Memories memories) {
    return I64Load16U(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'i64.load16_u';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class I64Load32S extends MemoryInstruction {
  I64Load32S(super.memory) : super(encoding: 0x34);

  static I64Load32S deserialize(Deserializer d, Memories memories) {
    return I64Load32S(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'i64.load32_s';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class I64Load32U extends MemoryInstruction {
  I64Load32U(super.memory) : super(encoding: 0x35);

  static I64Load32U deserialize(Deserializer d, Memories memories) {
    return I64Load32U(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'i64.load32_u';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class I32Store extends MemoryInstruction {
  I32Store(super.memory) : super(encoding: 0x36);

  static I32Store deserialize(Deserializer d, Memories memories) {
    return I32Store(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'i32.store';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class I64Store extends MemoryInstruction {
  I64Store(super.memory) : super(encoding: 0x37);

  static I64Store deserialize(Deserializer d, Memories memories) {
    return I64Store(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'i64.store';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class F32Store extends MemoryInstruction {
  F32Store(super.memory) : super(encoding: 0x38);

  static F32Store deserialize(Deserializer d, Memories memories) {
    return F32Store(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'f32.store';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class F64Store extends MemoryInstruction {
  F64Store(super.memory) : super(encoding: 0x39);

  static F64Store deserialize(Deserializer d, Memories memories) {
    return F64Store(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'f64.store';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class I32Store8 extends MemoryInstruction {
  I32Store8(super.memory) : super(encoding: 0x3A);

  static I32Store8 deserialize(Deserializer d, Memories memories) {
    return I32Store8(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'i32.store8';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class I32Store16 extends MemoryInstruction {
  I32Store16(super.memory) : super(encoding: 0x3B);

  static I32Store16 deserialize(Deserializer d, Memories memories) {
    return I32Store16(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'i32.store16';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class I64Store8 extends MemoryInstruction {
  I64Store8(super.memory) : super(encoding: 0x3C);

  static I64Store8 deserialize(Deserializer d, Memories memories) {
    return I64Store8(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'i64.store8';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class I64Store16 extends MemoryInstruction {
  I64Store16(super.memory) : super(encoding: 0x3D);

  static I64Store16 deserialize(Deserializer d, Memories memories) {
    return I64Store16(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'i64.store16';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class I64Store32 extends MemoryInstruction {
  I64Store32(super.memory) : super(encoding: 0x3E);

  static I64Store32 deserialize(Deserializer d, Memories memories) {
    return I64Store32(MemoryOffsetAlign.deserialize(d, memories));
  }

  @override
  String get name => 'i64.store32';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    memory.printTo(p);
  }
}

class MemorySize extends Instruction {
  final Memory memory;

  MemorySize(this.memory);

  static MemorySize deserialize(Deserializer d, Memories memories) {
    return MemorySize(memories[d.readUnsigned()]);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x3F);
    s.writeUnsigned(memory.index);
  }

  @override
  String get name => 'memory.size';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeMemoryReference(memory);
  }
}

class MemoryGrow extends Instruction {
  final Memory memory;

  MemoryGrow(this.memory);

  static MemoryGrow deserialize(Deserializer d, Memories memories) {
    return MemoryGrow(memories[d.readUnsigned()]);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x40);
    s.writeUnsigned(memory.index);
  }

  @override
  String get name => 'memory.grow';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeMemoryReference(memory);
  }
}

class MemoryFill extends Instruction {
  final Memory memory;

  MemoryFill(this.memory);

  static MemoryFill deserialize(Deserializer d, Memories memories) {
    return MemoryFill(memories[d.readUnsigned()]);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFC);
    s.writeUnsigned(0x0B);
    s.writeUnsigned(memory.index);
  }

  @override
  String get name => 'memory.fill';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.writeMemoryReference(memory);
  }
}

class RefNull extends Instruction {
  final HeapType heapType;

  @override
  List<DefType> get usedDefTypes {
    final type = heapType;
    return type is DefType ? [type] : const [];
  }

  RefNull(this.heapType);

  static RefNull deserialize(Deserializer d, Types types) {
    return RefNull(HeapType.deserialize(d, types.defined));
  }

  @override
  bool get isConstant => true;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xD0);
    s.write(heapType);
  }

  @override
  String get name => 'ref.null';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeHeapTypeReference(heapType);
  }
}

class RefIsNull extends SingleByteInstruction {
  const RefIsNull() : super(0xD1);

  static RefIsNull deserialize(Deserializer d) => const RefIsNull();

  @override
  String get name => 'ref.is_null';
}

class RefFunc extends Instruction {
  final BaseFunction function;

  RefFunc(this.function);

  static RefFunc deserialize(Deserializer d, Functions functions) {
    final index = d.readUnsigned();
    final function = functions[index];
    return RefFunc(function);
  }

  @override
  bool get isConstant => true;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xD2);
    s.writeUnsigned(function.index);
  }

  @override
  String get name => 'ref.func';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeFunctionReference(function);
  }
}

class RefAsNonNull extends SingleByteInstruction {
  const RefAsNonNull() : super(0xD4);

  static RefAsNonNull deserialize(Deserializer d) => const RefAsNonNull();

  @override
  String get name => 'ref.as_non_null';
}

class BrOnNull extends Instruction {
  final int labelIndex;

  BrOnNull(this.labelIndex);

  static BrOnNull deserialize(Deserializer d) => BrOnNull(d.readUnsigned());

  @override
  void serialize(Serializer s) {
    s.writeByte(0xD5);
    s.writeUnsigned(labelIndex);
  }

  @override
  String get name => 'br_on_null';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeLabelReference(labelIndex);
  }
}

class RefEq extends SingleByteInstruction {
  const RefEq() : super(0xD3);

  static RefEq deserialize(Deserializer d) => const RefEq();

  @override
  String get name => 'ref.eq';
}

class BrOnNonNull extends Instruction {
  final int labelIndex;

  BrOnNonNull(this.labelIndex);

  static BrOnNonNull deserialize(Deserializer d) =>
      BrOnNonNull(d.readUnsigned());

  @override
  void serialize(Serializer s) {
    s.writeByte(0xD6);
    s.writeUnsigned(labelIndex);
  }

  @override
  String get name => 'br_on_non_null';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeLabelReference(labelIndex);
  }
}

class StructGet extends Instruction {
  final StructType structType;
  final int fieldIndex;

  @override
  List<DefType> get usedDefTypes => [structType];

  StructGet(this.structType, this.fieldIndex);

  static StructGet deserialize(Deserializer d, Types types) {
    return StructGet(
        types.defined[d.readTypeIndex()] as StructType, d.readUnsigned());
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x02);
    s.writeTypeIndex(structType);
    s.writeUnsigned(fieldIndex);
  }

  @override
  String get name => 'struct.get';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeFieldReference(structType, fieldIndex);
  }
}

class StructGetS extends Instruction {
  final StructType structType;
  final int fieldIndex;

  @override
  List<DefType> get usedDefTypes => [structType];

  StructGetS(this.structType, this.fieldIndex);

  static StructGetS deserialize(Deserializer d, Types types) {
    return StructGetS(
        types.defined[d.readTypeIndex()] as StructType, d.readUnsigned());
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x03);
    s.writeTypeIndex(structType);
    s.writeUnsigned(fieldIndex);
  }

  @override
  String get name => 'struct.get_s';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeFieldReference(structType, fieldIndex);
  }
}

class StructGetU extends Instruction {
  final StructType structType;
  final int fieldIndex;

  @override
  List<DefType> get usedDefTypes => [structType];

  StructGetU(this.structType, this.fieldIndex);

  static StructGetU deserialize(Deserializer d, Types types) {
    return StructGetU(
        types.defined[d.readTypeIndex()] as StructType, d.readUnsigned());
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x04);
    s.writeTypeIndex(structType);
    s.writeUnsigned(fieldIndex);
  }

  @override
  String get name => 'struct.get_u';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeFieldReference(structType, fieldIndex);
  }
}

class StructSet extends Instruction {
  final StructType structType;
  final int fieldIndex;

  @override
  List<DefType> get usedDefTypes => [structType];

  StructSet(this.structType, this.fieldIndex);

  static StructSet deserialize(Deserializer d, Types types) {
    return StructSet(
        types.defined[d.readTypeIndex()] as StructType, d.readUnsigned());
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x05);
    s.writeTypeIndex(structType);
    s.writeUnsigned(fieldIndex);
  }

  @override
  String get name => 'struct.set';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeFieldReference(structType, fieldIndex);
  }
}

class StructNew extends Instruction {
  final StructType structType;

  @override
  List<DefType> get usedDefTypes => [structType];

  StructNew(this.structType);

  static StructNew deserialize(Deserializer d, Types types) {
    return StructNew(types.defined[d.readTypeIndex()] as StructType);
  }

  @override
  bool get isConstant => true;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x00);
    s.writeTypeIndex(structType);
  }

  @override
  String get name => 'struct.new';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeDefTypeReference(structType);
  }
}

class StructNewDefault extends Instruction {
  final StructType structType;

  @override
  List<DefType> get usedDefTypes => [structType];

  StructNewDefault(this.structType);

  static StructNewDefault deserialize(Deserializer d, Types types) {
    return StructNewDefault(types.defined[d.readTypeIndex()] as StructType);
  }

  @override
  bool get isConstant => true;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x01);
    s.writeTypeIndex(structType);
  }

  @override
  String get name => 'struct.new_default';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeDefTypeReference(structType);
  }
}

class ArrayGet extends Instruction {
  final ArrayType arrayType;

  @override
  List<DefType> get usedDefTypes => [arrayType];

  ArrayGet(this.arrayType);

  static ArrayGet deserialize(Deserializer d, Types types) {
    return ArrayGet(types.defined[d.readTypeIndex()] as ArrayType);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x0b);
    s.writeTypeIndex(arrayType);
  }

  @override
  String get name => 'array.get';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeDefTypeReference(arrayType);
  }
}

class ArrayGetS extends Instruction {
  final ArrayType arrayType;

  @override
  List<DefType> get usedDefTypes => [arrayType];

  ArrayGetS(this.arrayType);

  static ArrayGetS deserialize(Deserializer d, Types types) {
    return ArrayGetS(types.defined[d.readTypeIndex()] as ArrayType);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x0c);
    s.writeTypeIndex(arrayType);
  }

  @override
  String get name => 'array.get_s';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeDefTypeReference(arrayType);
  }
}

class ArrayGetU extends Instruction {
  final ArrayType arrayType;

  @override
  List<DefType> get usedDefTypes => [arrayType];

  ArrayGetU(this.arrayType);

  static ArrayGetU deserialize(Deserializer d, Types types) {
    return ArrayGetU(types.defined[d.readTypeIndex()] as ArrayType);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x0d);
    s.writeTypeIndex(arrayType);
  }

  @override
  String get name => 'array.get_u';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeDefTypeReference(arrayType);
  }
}

class ArraySet extends Instruction {
  final ArrayType arrayType;

  @override
  List<DefType> get usedDefTypes => [arrayType];

  ArraySet(this.arrayType);

  static ArraySet deserialize(Deserializer d, Types types) {
    return ArraySet(types.defined[d.readTypeIndex()] as ArrayType);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x0E);
    s.writeTypeIndex(arrayType);
  }

  @override
  String get name => 'array.set';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeDefTypeReference(arrayType);
  }
}

class ArrayLen extends Instruction {
  const ArrayLen();

  static ArrayLen deserialize(Deserializer d) => const ArrayLen();

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x0F);
  }

  @override
  String get name => 'array.len';
}

class ArrayNewFixed extends Instruction {
  final ArrayType arrayType;
  final int length;

  @override
  List<DefType> get usedDefTypes => [arrayType];

  ArrayNewFixed(this.arrayType, this.length);

  static ArrayNewFixed deserialize(Deserializer d, Types types) {
    return ArrayNewFixed(
        types.defined[d.readTypeIndex()] as ArrayType, d.readUnsigned());
  }

  @override
  bool get isConstant => true;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x08);
    s.writeTypeIndex(arrayType);
    s.writeUnsigned(length);
  }

  @override
  String get name => 'array.new_fixed';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeDefTypeReference(arrayType);
    p.write(' $length');
  }
}

class ArrayNew extends Instruction {
  final ArrayType arrayType;

  @override
  List<DefType> get usedDefTypes => [arrayType];

  ArrayNew(this.arrayType);

  static ArrayNew deserialize(Deserializer d, Types types) {
    return ArrayNew(types.defined[d.readTypeIndex()] as ArrayType);
  }

  @override
  bool get isConstant => true;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x06);
    s.writeTypeIndex(arrayType);
  }

  @override
  String get name => 'array.new';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeDefTypeReference(arrayType);
  }
}

class ArrayNewDefault extends Instruction {
  final ArrayType arrayType;

  @override
  List<DefType> get usedDefTypes => [arrayType];

  ArrayNewDefault(this.arrayType);

  static ArrayNewDefault deserialize(Deserializer d, Types types) {
    return ArrayNewDefault(types.defined[d.readTypeIndex()] as ArrayType);
  }

  @override
  bool get isConstant => true;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x07);
    s.writeTypeIndex(arrayType);
  }

  @override
  String get name => 'array.new_default';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeDefTypeReference(arrayType);
  }
}

class ArrayNewData extends Instruction {
  final ArrayType arrayType;
  final BaseDataSegment data;

  @override
  List<DefType> get usedDefTypes => [arrayType];

  ArrayNewData(this.arrayType, this.data);

  static ArrayNewData deserialize(
      Deserializer d, Types types, DataSegments dataSegments) {
    return ArrayNewData(types.defined[d.readTypeIndex()] as ArrayType,
        dataSegments.defined[d.readUnsigned()]);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x09);
    s.writeTypeIndex(arrayType);
    s.writeUnsigned(data.index);
  }

  @override
  String get name => 'array.new_data';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeDefTypeReference(arrayType);
    p.writeDataReference(data);
  }
}

class ArrayCopy extends Instruction {
  final ArrayType destArrayType;
  final ArrayType sourceArrayType;

  @override
  List<DefType> get usedDefTypes => [destArrayType, sourceArrayType];

  ArrayCopy({required this.destArrayType, required this.sourceArrayType});

  static ArrayCopy deserialize(Deserializer d, Types types) {
    return ArrayCopy(
        destArrayType: types.defined[d.readTypeIndex()] as ArrayType,
        sourceArrayType: types.defined[d.readTypeIndex()] as ArrayType);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x11);
    s.writeTypeIndex(destArrayType);
    s.writeTypeIndex(sourceArrayType);
  }

  @override
  String get name => 'array.copy';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeDefTypeReference(destArrayType);
    p.write(' ');
    p.writeDefTypeReference(sourceArrayType);
  }
}

class ArrayFill extends Instruction {
  final ArrayType arrayType;

  @override
  List<DefType> get usedDefTypes => [arrayType];

  ArrayFill(this.arrayType);

  static ArrayFill deserialize(Deserializer d, Types types) {
    return ArrayFill(types.defined[d.readTypeIndex()] as ArrayType);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x10);
    s.writeTypeIndex(arrayType);
  }

  @override
  String get name => 'array.fill';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeDefTypeReference(arrayType);
  }
}

class I31New extends Instruction {
  const I31New();

  static I31New deserialize(Deserializer d) => const I31New();

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x1C);
  }

  @override
  String get name => 'i31.new';
}

class I31GetS extends Instruction {
  const I31GetS();

  static I31GetS deserialize(Deserializer d) => const I31GetS();

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x1D);
  }

  @override
  String get name => 'i31.get_s';
}

class I31GetU extends Instruction {
  const I31GetU();

  static I31GetU deserialize(Deserializer d) => const I31GetU();

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x1E);
  }

  @override
  String get name => 'i31.get_u';
}

class RefTest extends Instruction {
  final RefType targetType;

  RefTest(this.targetType);

  static RefTest deserialize(Deserializer d, Types types, bool nullable) {
    return RefTest(
        RefType(HeapType.deserialize(d, types.defined), nullable: nullable));
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(targetType.nullable ? 0x15 : 0x14);
    s.write(targetType.heapType);
  }

  @override
  String get name => 'ref.test';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeRefTypeReference(targetType);
  }
}

class RefCast extends Instruction {
  final RefType targetType;

  @override
  List<ValueType> get usedValueTypes => [targetType];

  RefCast(this.targetType);

  static RefCast deserialize(Deserializer d, Types types, bool nullable) {
    return RefCast(
        RefType(HeapType.deserialize(d, types.defined), nullable: nullable));
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(targetType.nullable ? 0x17 : 0x16);
    s.write(targetType.heapType);
  }

  @override
  String get name => 'ref.cast';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeRefTypeReference(targetType);
  }
}

class BrOnCast extends Instruction {
  final int labelIndex;
  final RefType inputType;
  final RefType targetType;

  @override
  List<ValueType> get usedValueTypes => [inputType, targetType];

  BrOnCast(this.labelIndex, this.inputType, this.targetType);

  static BrOnCast deserialize(Deserializer d, Types types) {
    final flags = d.readByte();
    final labelIndex = d.readUnsigned();
    final inputHeapType = HeapType.deserialize(d, types.defined);
    final targetHeapType = HeapType.deserialize(d, types.defined);
    final inputType = RefType(inputHeapType, nullable: (flags & 0x01) != 0);
    final targetType = RefType(targetHeapType, nullable: (flags & 0x01) != 0);
    return BrOnCast(labelIndex, inputType, targetType);
  }

  @override
  void serialize(Serializer s) {
    int flags = (inputType.nullable ? 0x01 : 0x00) |
        (targetType.nullable ? 0x02 : 0x00);
    s.writeByte(0xFB);
    s.writeByte(0x18);
    s.writeByte(flags);
    s.writeUnsigned(labelIndex);
    s.write(inputType.heapType);
    s.write(targetType.heapType);
  }

  @override
  String get name => 'br_on_cast';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeLabelReference(labelIndex);
    p.write(' ');
    p.writeValueType(inputType);
    p.write(' ');
    p.writeValueType(targetType);
  }
}

class BrOnCastFail extends Instruction {
  final int labelIndex;
  final RefType inputType;
  final RefType targetType;

  @override
  List<ValueType> get usedValueTypes => [inputType, targetType];

  BrOnCastFail(this.labelIndex, this.inputType, this.targetType);

  static BrOnCastFail deserialize(Deserializer d, Types types) {
    final flags = d.readByte();
    final labelIndex = d.readUnsigned();
    final inputHeapType = HeapType.deserialize(d, types.defined);
    final targetHeapType = HeapType.deserialize(d, types.defined);

    final inputType = RefType(inputHeapType, nullable: (flags & 0x01) != 0);
    final targetType = RefType(targetHeapType, nullable: (flags & 0x01) != 0);

    return BrOnCastFail(labelIndex, inputType, targetType);
  }

  @override
  void serialize(Serializer s) {
    int flags = (inputType.nullable ? 0x01 : 0x00) |
        (targetType.nullable ? 0x02 : 0x00);
    s.writeByte(0xFB);
    s.writeByte(0x19);
    s.writeByte(flags);
    s.writeUnsigned(labelIndex);
    s.write(inputType.heapType);
    s.write(targetType.heapType);
  }

  @override
  String get name => 'br_on_cast_fail';

  @override
  void printTo(IrPrinter p) {
    p.write(name);
    p.write(' ');
    p.writeLabelReference(labelIndex);
    p.write(' ');
    p.writeValueType(inputType);
    p.write(' ');
    p.writeValueType(targetType);
  }
}

class ExternInternalize extends Instruction {
  const ExternInternalize();

  static ExternInternalize deserialize(Deserializer d) {
    return const ExternInternalize();
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x1A);
  }

  @override
  bool get isConstant => true;

  @override
  String get name => 'any.convert_extern';
}

class ExternExternalize extends Instruction {
  const ExternExternalize();

  static ExternExternalize deserialize(Deserializer d) {
    return const ExternExternalize();
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFB);
    s.writeByte(0x1B);
  }

  @override
  bool get isConstant => true;

  @override
  String get name => 'extern.externalize';
}

class I32Const extends Instruction {
  final int value;

  I32Const(this.value);

  static I32Const deserialize(Deserializer d) {
    return I32Const(d.readSigned());
  }

  @override
  bool get isConstant => true;

  @override
  void serialize(Serializer s) {
    s.writeByte(0x41);
    s.writeSigned(value);
  }

  @override
  String get name => 'i32.const $value';
}

class I64Const extends Instruction {
  final int value;

  I64Const(this.value);

  static I64Const deserialize(Deserializer d) {
    return I64Const(d.readSigned());
  }

  @override
  bool get isConstant => true;

  @override
  void serialize(Serializer s) {
    s.writeByte(0x42);
    s.writeSigned(value);
  }

  @override
  String get name => 'i64.const $value';
}

class F32Const extends Instruction {
  final double value;

  F32Const(this.value);

  static F32Const deserialize(Deserializer d) {
    return F32Const(d.readF32());
  }

  @override
  bool get isConstant => true;

  @override
  void serialize(Serializer s) {
    s.writeByte(0x43);
    s.writeF32(value);
  }

  @override
  String get name => 'f32.const $value';
}

class F64Const extends Instruction {
  final double value;

  F64Const(this.value);

  static F64Const deserialize(Deserializer d) {
    return F64Const(d.readF64());
  }

  @override
  bool get isConstant => true;

  @override
  void serialize(Serializer s) {
    s.writeByte(0x44);
    s.writeF64(value);
  }

  @override
  String get name => 'f64.const $value';
}

class I32Eqz extends SingleByteInstruction {
  const I32Eqz() : super(0x45);

  static I32Eqz deserialize(Deserializer d) => const I32Eqz();

  @override
  String get name => 'i32.eqz';
}

class I32Eq extends SingleByteInstruction {
  const I32Eq() : super(0x46);

  static I32Eq deserialize(Deserializer d) => const I32Eq();

  @override
  String get name => 'i32.eq';
}

class I32Ne extends SingleByteInstruction {
  const I32Ne() : super(0x47);

  static I32Ne deserialize(Deserializer d) => const I32Ne();

  @override
  String get name => 'i32.ne';
}

class I32LtS extends SingleByteInstruction {
  const I32LtS() : super(0x48);

  static I32LtS deserialize(Deserializer d) => const I32LtS();

  @override
  String get name => 'i32.lt_s';
}

class I32LtU extends SingleByteInstruction {
  const I32LtU() : super(0x49);

  static I32LtU deserialize(Deserializer d) => const I32LtU();

  @override
  String get name => 'i32.lt_u';
}

class I32GtS extends SingleByteInstruction {
  const I32GtS() : super(0x4A);

  static I32GtS deserialize(Deserializer d) => const I32GtS();

  @override
  String get name => 'i32.gt_s';
}

class I32GtU extends SingleByteInstruction {
  const I32GtU() : super(0x4B);

  static I32GtU deserialize(Deserializer d) => const I32GtU();

  @override
  String get name => 'i32.gt_u';
}

class I32LeS extends SingleByteInstruction {
  const I32LeS() : super(0x4C);

  static I32LeS deserialize(Deserializer d) => const I32LeS();

  @override
  String get name => 'i32.le_s';
}

class I32LeU extends SingleByteInstruction {
  const I32LeU() : super(0x4D);

  static I32LeU deserialize(Deserializer d) => const I32LeU();

  @override
  String get name => 'i32.le_u';
}

class I32GeS extends SingleByteInstruction {
  const I32GeS() : super(0x4E);

  static I32GeS deserialize(Deserializer d) => const I32GeS();

  @override
  String get name => 'i32.ge_s';
}

class I32GeU extends SingleByteInstruction {
  const I32GeU() : super(0x4F);

  static I32GeU deserialize(Deserializer d) => const I32GeU();

  @override
  String get name => 'i32.ge_u';
}

class I64Eqz extends SingleByteInstruction {
  const I64Eqz() : super(0x50);

  static I64Eqz deserialize(Deserializer d) => const I64Eqz();

  @override
  String get name => 'i64.eqz';
}

class I64Eq extends SingleByteInstruction {
  const I64Eq() : super(0x51);

  static I64Eq deserialize(Deserializer d) => const I64Eq();

  @override
  String get name => 'i64.eq';
}

class I64Ne extends SingleByteInstruction {
  const I64Ne() : super(0x52);

  static I64Ne deserialize(Deserializer d) => const I64Ne();

  @override
  String get name => 'i64.ne';
}

class I64LtS extends SingleByteInstruction {
  const I64LtS() : super(0x53);

  static I64LtS deserialize(Deserializer d) => const I64LtS();

  @override
  String get name => 'i64.lt_s';
}

class I64LtU extends SingleByteInstruction {
  const I64LtU() : super(0x54);

  static I64LtU deserialize(Deserializer d) => const I64LtU();

  @override
  String get name => 'i64.lt_u';
}

class I64GtS extends SingleByteInstruction {
  const I64GtS() : super(0x55);

  static I64GtS deserialize(Deserializer d) => const I64GtS();

  @override
  String get name => 'i64.gt_s';
}

class I64GtU extends SingleByteInstruction {
  const I64GtU() : super(0x56);

  static I64GtU deserialize(Deserializer d) => const I64GtU();

  @override
  String get name => 'i64.gt_u';
}

class I64LeS extends SingleByteInstruction {
  const I64LeS() : super(0x57);

  static I64LeS deserialize(Deserializer d) => const I64LeS();

  @override
  String get name => 'i64.le_s';
}

class I64LeU extends SingleByteInstruction {
  const I64LeU() : super(0x58);

  static I64LeU deserialize(Deserializer d) => const I64LeU();

  @override
  String get name => 'i64.le_u';
}

class I64GeS extends SingleByteInstruction {
  const I64GeS() : super(0x59);

  static I64GeS deserialize(Deserializer d) => const I64GeS();

  @override
  String get name => 'i64.ge_s';
}

class I64GeU extends SingleByteInstruction {
  const I64GeU() : super(0x5A);

  static I64GeU deserialize(Deserializer d) => const I64GeU();

  @override
  String get name => 'i64.ge_u';
}

class F32Eq extends SingleByteInstruction {
  const F32Eq() : super(0x5B);

  static F32Eq deserialize(Deserializer d) => const F32Eq();

  @override
  String get name => 'f32.eq';
}

class F32Ne extends SingleByteInstruction {
  const F32Ne() : super(0x5C);

  static F32Ne deserialize(Deserializer d) => const F32Ne();

  @override
  String get name => 'f32.ne';
}

class F32Lt extends SingleByteInstruction {
  const F32Lt() : super(0x5D);

  static F32Lt deserialize(Deserializer d) => const F32Lt();

  @override
  String get name => 'f32.lt';
}

class F32Gt extends SingleByteInstruction {
  const F32Gt() : super(0x5E);

  static F32Gt deserialize(Deserializer d) => const F32Gt();

  @override
  String get name => 'f32.gt';
}

class F32Le extends SingleByteInstruction {
  const F32Le() : super(0x5F);

  static F32Le deserialize(Deserializer d) => const F32Le();

  @override
  String get name => 'f32.le';
}

class F32Ge extends SingleByteInstruction {
  const F32Ge() : super(0x60);

  static F32Ge deserialize(Deserializer d) => const F32Ge();

  @override
  String get name => 'f32.ge';
}

class F64Eq extends SingleByteInstruction {
  const F64Eq() : super(0x61);

  static F64Eq deserialize(Deserializer d) => const F64Eq();

  @override
  String get name => 'f64.eq';
}

class F64Ne extends SingleByteInstruction {
  const F64Ne() : super(0x62);

  static F64Ne deserialize(Deserializer d) => const F64Ne();

  @override
  String get name => 'f64.ne';
}

class F64Lt extends SingleByteInstruction {
  const F64Lt() : super(0x63);

  static F64Lt deserialize(Deserializer d) => const F64Lt();

  @override
  String get name => 'f64.lt';
}

class F64Gt extends SingleByteInstruction {
  const F64Gt() : super(0x64);

  static F64Gt deserialize(Deserializer d) => const F64Gt();

  @override
  String get name => 'f64.gt';
}

class F64Le extends SingleByteInstruction {
  const F64Le() : super(0x65);

  static F64Le deserialize(Deserializer d) => const F64Le();

  @override
  String get name => 'f64.le';
}

class F64Ge extends SingleByteInstruction {
  const F64Ge() : super(0x66);

  static F64Ge deserialize(Deserializer d) => const F64Ge();

  @override
  String get name => 'f64.ge';
}

class I32Clz extends SingleByteInstruction {
  const I32Clz() : super(0x67);

  static I32Clz deserialize(Deserializer d) => const I32Clz();

  @override
  String get name => 'i32.clz';
}

class I32Ctz extends SingleByteInstruction {
  const I32Ctz() : super(0x68);

  static I32Ctz deserialize(Deserializer d) => const I32Ctz();

  @override
  String get name => 'i32.ctz';
}

class I32Popcnt extends SingleByteInstruction {
  const I32Popcnt() : super(0x69);

  static I32Popcnt deserialize(Deserializer d) => const I32Popcnt();

  @override
  String get name => 'i32.popcnt';
}

class I32Add extends SingleByteInstruction {
  const I32Add() : super(0x6A);

  static I32Add deserialize(Deserializer d) => const I32Add();

  @override
  String get name => 'i32.add';
}

class I32Sub extends SingleByteInstruction {
  const I32Sub() : super(0x6B);

  static I32Sub deserialize(Deserializer d) => const I32Sub();

  @override
  String get name => 'i32.sub';
}

class I32Mul extends SingleByteInstruction {
  const I32Mul() : super(0x6C);

  static I32Mul deserialize(Deserializer d) => const I32Mul();

  @override
  String get name => 'i32.mul';
}

class I32DivS extends SingleByteInstruction {
  const I32DivS() : super(0x6D);

  static I32DivS deserialize(Deserializer d) => const I32DivS();

  @override
  String get name => 'i32.div_s';
}

class I32DivU extends SingleByteInstruction {
  const I32DivU() : super(0x6E);

  static I32DivU deserialize(Deserializer d) => const I32DivU();

  @override
  String get name => 'i32.div_u';
}

class I32RemS extends SingleByteInstruction {
  const I32RemS() : super(0x6F);

  static I32RemS deserialize(Deserializer d) => const I32RemS();

  @override
  String get name => 'i32.rem_s';
}

class I32RemU extends SingleByteInstruction {
  const I32RemU() : super(0x70);

  static I32RemU deserialize(Deserializer d) => const I32RemU();

  @override
  String get name => 'i32.rem_u';
}

class I32And extends SingleByteInstruction {
  const I32And() : super(0x71);

  static I32And deserialize(Deserializer d) => const I32And();

  @override
  String get name => 'i32.and';
}

class I32Or extends SingleByteInstruction {
  const I32Or() : super(0x72);

  static I32Or deserialize(Deserializer d) => const I32Or();

  @override
  String get name => 'i32.or';
}

class I32Xor extends SingleByteInstruction {
  const I32Xor() : super(0x73);

  static I32Xor deserialize(Deserializer d) => const I32Xor();

  @override
  String get name => 'i32.xor';
}

class I32Shl extends SingleByteInstruction {
  const I32Shl() : super(0x74);

  static I32Shl deserialize(Deserializer d) => const I32Shl();

  @override
  String get name => 'i32.shl';
}

class I32ShrS extends SingleByteInstruction {
  const I32ShrS() : super(0x75);

  static I32ShrS deserialize(Deserializer d) => const I32ShrS();

  @override
  String get name => 'i32.shr_s';
}

class I32ShrU extends SingleByteInstruction {
  const I32ShrU() : super(0x76);

  static I32ShrU deserialize(Deserializer d) => const I32ShrU();

  @override
  String get name => 'i32.shr_u';
}

class I32Rotl extends SingleByteInstruction {
  const I32Rotl() : super(0x77);

  static I32Rotl deserialize(Deserializer d) => const I32Rotl();

  @override
  String get name => 'i32.rotl';
}

class I32Rotr extends SingleByteInstruction {
  const I32Rotr() : super(0x78);

  static I32Rotr deserialize(Deserializer d) => const I32Rotr();

  @override
  String get name => 'i32.rotr';
}

class I64Clz extends SingleByteInstruction {
  const I64Clz() : super(0x79);

  static I64Clz deserialize(Deserializer d) => const I64Clz();

  @override
  String get name => 'i64.clz';
}

class I64Ctz extends SingleByteInstruction {
  const I64Ctz() : super(0x7A);

  static I64Ctz deserialize(Deserializer d) => const I64Ctz();

  @override
  String get name => 'i64.ctz';
}

class I64Popcnt extends SingleByteInstruction {
  const I64Popcnt() : super(0x7B);

  static I64Popcnt deserialize(Deserializer d) => const I64Popcnt();

  @override
  String get name => 'i64.popcnt';
}

class I64Add extends SingleByteInstruction {
  const I64Add() : super(0x7C);

  static I64Add deserialize(Deserializer d) => const I64Add();

  @override
  String get name => 'i64.add';
}

class I64Sub extends SingleByteInstruction {
  const I64Sub() : super(0x7D);

  static I64Sub deserialize(Deserializer d) => const I64Sub();

  @override
  String get name => 'i64.sub';
}

class I64Mul extends SingleByteInstruction {
  const I64Mul() : super(0x7E);

  static I64Mul deserialize(Deserializer d) => const I64Mul();

  @override
  String get name => 'i64.mul';
}

class I64DivS extends SingleByteInstruction {
  const I64DivS() : super(0x7F);

  static I64DivS deserialize(Deserializer d) => const I64DivS();

  @override
  String get name => 'i64.div_s';
}

class I64DivU extends SingleByteInstruction {
  const I64DivU() : super(0x80);

  static I64DivU deserialize(Deserializer d) => const I64DivU();

  @override
  String get name => 'i64.div_u';
}

class I64RemS extends SingleByteInstruction {
  const I64RemS() : super(0x81);

  static I64RemS deserialize(Deserializer d) => const I64RemS();

  @override
  String get name => 'i64.rem_s';
}

class I64RemU extends SingleByteInstruction {
  const I64RemU() : super(0x82);

  static I64RemU deserialize(Deserializer d) => const I64RemU();

  @override
  String get name => 'i64.rem_u';
}

class I64And extends SingleByteInstruction {
  const I64And() : super(0x83);

  static I64And deserialize(Deserializer d) => const I64And();

  @override
  String get name => 'i64.and';
}

class I64Or extends SingleByteInstruction {
  const I64Or() : super(0x84);

  static I64Or deserialize(Deserializer d) => const I64Or();

  @override
  String get name => 'i64.or';
}

class I64Xor extends SingleByteInstruction {
  const I64Xor() : super(0x85);

  static I64Xor deserialize(Deserializer d) => const I64Xor();

  @override
  String get name => 'i64.xor';
}

class I64Shl extends SingleByteInstruction {
  const I64Shl() : super(0x86);

  static I64Shl deserialize(Deserializer d) => const I64Shl();

  @override
  String get name => 'i64.shl';
}

class I64ShrS extends SingleByteInstruction {
  const I64ShrS() : super(0x87);

  static I64ShrS deserialize(Deserializer d) => const I64ShrS();

  @override
  String get name => 'i64.shr_s';
}

class I64ShrU extends SingleByteInstruction {
  const I64ShrU() : super(0x88);

  static I64ShrU deserialize(Deserializer d) => const I64ShrU();

  @override
  String get name => 'i64.shr_u';
}

class I64Rotl extends SingleByteInstruction {
  const I64Rotl() : super(0x89);

  static I64Rotl deserialize(Deserializer d) => const I64Rotl();

  @override
  String get name => 'i64.rotl';
}

class I64Rotr extends SingleByteInstruction {
  const I64Rotr() : super(0x8A);

  static I64Rotr deserialize(Deserializer d) => const I64Rotr();

  @override
  String get name => 'i64.rotr';
}

class F32Abs extends SingleByteInstruction {
  const F32Abs() : super(0x8B);

  static F32Abs deserialize(Deserializer d) => const F32Abs();

  @override
  String get name => 'f32.abs';
}

class F32Neg extends SingleByteInstruction {
  const F32Neg() : super(0x8C);

  static F32Neg deserialize(Deserializer d) => const F32Neg();

  @override
  String get name => 'f32.neg';
}

class F32Ceil extends SingleByteInstruction {
  const F32Ceil() : super(0x8D);

  static F32Ceil deserialize(Deserializer d) => const F32Ceil();

  @override
  String get name => 'f32.ceil';
}

class F32Floor extends SingleByteInstruction {
  const F32Floor() : super(0x8E);

  static F32Floor deserialize(Deserializer d) => const F32Floor();

  @override
  String get name => 'f32.floor';
}

class F32Trunc extends SingleByteInstruction {
  const F32Trunc() : super(0x8F);

  static F32Trunc deserialize(Deserializer d) => const F32Trunc();

  @override
  String get name => 'f32.trunc';
}

class F32Nearest extends SingleByteInstruction {
  const F32Nearest() : super(0x90);

  static F32Nearest deserialize(Deserializer d) => const F32Nearest();

  @override
  String get name => 'f32.nearest';
}

class F32Sqrt extends SingleByteInstruction {
  const F32Sqrt() : super(0x91);

  static F32Sqrt deserialize(Deserializer d) => const F32Sqrt();

  @override
  String get name => 'f32.sqrt';
}

class F32Add extends SingleByteInstruction {
  const F32Add() : super(0x92);

  static F32Add deserialize(Deserializer d) => const F32Add();

  @override
  String get name => 'f32.add';
}

class F32Sub extends SingleByteInstruction {
  const F32Sub() : super(0x93);

  static F32Sub deserialize(Deserializer d) => const F32Sub();

  @override
  String get name => 'f32.sub';
}

class F32Mul extends SingleByteInstruction {
  const F32Mul() : super(0x94);

  static F32Mul deserialize(Deserializer d) => const F32Mul();

  @override
  String get name => 'f32.mul';
}

class F32Div extends SingleByteInstruction {
  const F32Div() : super(0x95);

  static F32Div deserialize(Deserializer d) => const F32Div();

  @override
  String get name => 'f32.div';
}

class F32Min extends SingleByteInstruction {
  const F32Min() : super(0x96);

  static F32Min deserialize(Deserializer d) => const F32Min();

  @override
  String get name => 'f32.min';
}

class F32Max extends SingleByteInstruction {
  const F32Max() : super(0x97);

  static F32Max deserialize(Deserializer d) => const F32Max();

  @override
  String get name => 'f32.max';
}

class F32Copysign extends SingleByteInstruction {
  const F32Copysign() : super(0x98);

  static F32Copysign deserialize(Deserializer d) => const F32Copysign();

  @override
  String get name => 'f32.copysign';
}

class F64Abs extends SingleByteInstruction {
  const F64Abs() : super(0x99);

  static F64Abs deserialize(Deserializer d) => const F64Abs();

  @override
  String get name => 'f64.abs';
}

class F64Neg extends SingleByteInstruction {
  const F64Neg() : super(0x9A);

  static F64Neg deserialize(Deserializer d) => const F64Neg();

  @override
  String get name => 'f64.neg';
}

class F64Ceil extends SingleByteInstruction {
  const F64Ceil() : super(0x9B);

  static F64Ceil deserialize(Deserializer d) => const F64Ceil();

  @override
  String get name => 'f64.ceil';
}

class F64Floor extends SingleByteInstruction {
  const F64Floor() : super(0x9C);

  static F64Floor deserialize(Deserializer d) => const F64Floor();

  @override
  String get name => 'f64.floor';
}

class F64Trunc extends SingleByteInstruction {
  const F64Trunc() : super(0x9D);

  static F64Trunc deserialize(Deserializer d) => const F64Trunc();

  @override
  String get name => 'f64.trunc';
}

class F64Nearest extends SingleByteInstruction {
  const F64Nearest() : super(0x9E);

  static F64Nearest deserialize(Deserializer d) => const F64Nearest();

  @override
  String get name => 'f64.nearest';
}

class F64Sqrt extends SingleByteInstruction {
  const F64Sqrt() : super(0x9F);

  static F64Sqrt deserialize(Deserializer d) => const F64Sqrt();

  @override
  String get name => 'f64.sqrt';
}

class F64Add extends SingleByteInstruction {
  const F64Add() : super(0xA0);

  static F64Add deserialize(Deserializer d) => const F64Add();

  @override
  String get name => 'f64.add';
}

class F64Sub extends SingleByteInstruction {
  const F64Sub() : super(0xA1);

  static F64Sub deserialize(Deserializer d) => const F64Sub();

  @override
  String get name => 'f64.sub';
}

class F64Mul extends SingleByteInstruction {
  const F64Mul() : super(0xA2);

  static F64Mul deserialize(Deserializer d) => const F64Mul();

  @override
  String get name => 'f64.mul';
}

class F64Div extends SingleByteInstruction {
  const F64Div() : super(0xA3);

  static F64Div deserialize(Deserializer d) => const F64Div();

  @override
  String get name => 'f64.div';
}

class F64Min extends SingleByteInstruction {
  const F64Min() : super(0xA4);

  static F64Min deserialize(Deserializer d) => const F64Min();

  @override
  String get name => 'f64.min';
}

class F64Max extends SingleByteInstruction {
  const F64Max() : super(0xA5);

  static F64Max deserialize(Deserializer d) => const F64Max();

  @override
  String get name => 'f64.max';
}

class F64Copysign extends SingleByteInstruction {
  const F64Copysign() : super(0xA6);

  static F64Copysign deserialize(Deserializer d) => const F64Copysign();

  @override
  String get name => 'f64.copysign';
}

class I32WrapI64 extends SingleByteInstruction {
  const I32WrapI64() : super(0xA7);

  static I32WrapI64 deserialize(Deserializer d) => const I32WrapI64();

  @override
  String get name => 'i32.wrap_i64';
}

class I32TruncF32S extends SingleByteInstruction {
  const I32TruncF32S() : super(0xA8);

  static I32TruncF32S deserialize(Deserializer d) => const I32TruncF32S();

  @override
  String get name => 'i32.trunc_f32_s';
}

class I32TruncF32U extends SingleByteInstruction {
  const I32TruncF32U() : super(0xA9);

  static I32TruncF32U deserialize(Deserializer d) => const I32TruncF32U();

  @override
  String get name => 'i32.trunc_f32_u';
}

class I32TruncF64S extends SingleByteInstruction {
  const I32TruncF64S() : super(0xAA);

  static I32TruncF64S deserialize(Deserializer d) => const I32TruncF64S();

  @override
  String get name => 'i32.trunc_f64_s';
}

class I32TruncF64U extends SingleByteInstruction {
  const I32TruncF64U() : super(0xAB);

  static I32TruncF64U deserialize(Deserializer d) => const I32TruncF64U();

  @override
  String get name => 'i32.trunc_f64_u';
}

class I64ExtendI32S extends SingleByteInstruction {
  const I64ExtendI32S() : super(0xAC);

  static I64ExtendI32S deserialize(Deserializer d) => const I64ExtendI32S();

  @override
  String get name => 'i64.extend_i32_s';
}

class I64ExtendI32U extends SingleByteInstruction {
  const I64ExtendI32U() : super(0xAD);

  static I64ExtendI32U deserialize(Deserializer d) => const I64ExtendI32U();

  @override
  String get name => 'i64.extend_i32_u';
}

class I64TruncF32S extends SingleByteInstruction {
  const I64TruncF32S() : super(0xAE);

  static I64TruncF32S deserialize(Deserializer d) => const I64TruncF32S();

  @override
  String get name => 'i64.trunc_f32_s';
}

class I64TruncF32U extends SingleByteInstruction {
  const I64TruncF32U() : super(0xAF);

  static I64TruncF32U deserialize(Deserializer d) => const I64TruncF32U();

  @override
  String get name => 'i64.trunc_f32_u';
}

class I64TruncF64S extends SingleByteInstruction {
  const I64TruncF64S() : super(0xB0);

  static I64TruncF64S deserialize(Deserializer d) => const I64TruncF64S();

  @override
  String get name => 'i64.trunc_f64_s';
}

class I64TruncF64U extends SingleByteInstruction {
  const I64TruncF64U() : super(0xB1);

  static I64TruncF64U deserialize(Deserializer d) => const I64TruncF64U();

  @override
  String get name => 'i64.trunc_f64_u';
}

class F32ConvertI32S extends SingleByteInstruction {
  const F32ConvertI32S() : super(0xB2);

  static F32ConvertI32S deserialize(Deserializer d) => const F32ConvertI32S();

  @override
  String get name => 'f32.convert_i32_s';
}

class F32ConvertI32U extends SingleByteInstruction {
  const F32ConvertI32U() : super(0xB3);

  static F32ConvertI32U deserialize(Deserializer d) => const F32ConvertI32U();

  @override
  String get name => 'f32.convert_i32_u';
}

class F32ConvertI64S extends SingleByteInstruction {
  const F32ConvertI64S() : super(0xB4);

  static F32ConvertI64S deserialize(Deserializer d) => const F32ConvertI64S();

  @override
  String get name => 'f32.convert_i64_s';
}

class F32ConvertI64U extends SingleByteInstruction {
  const F32ConvertI64U() : super(0xB5);

  static F32ConvertI64U deserialize(Deserializer d) => const F32ConvertI64U();

  @override
  String get name => 'f32.convert_i64_u';
}

class F32DemoteF64 extends SingleByteInstruction {
  const F32DemoteF64() : super(0xB6);

  static F32DemoteF64 deserialize(Deserializer d) => const F32DemoteF64();

  @override
  String get name => 'f32.demote_f64';
}

class F64ConvertI32S extends SingleByteInstruction {
  const F64ConvertI32S() : super(0xB7);

  static F64ConvertI32S deserialize(Deserializer d) => const F64ConvertI32S();

  @override
  String get name => 'f64.convert_i32_s';
}

class F64ConvertI32U extends SingleByteInstruction {
  const F64ConvertI32U() : super(0xB8);

  static F64ConvertI32U deserialize(Deserializer d) => const F64ConvertI32U();

  @override
  String get name => 'f64.convert_i32_u';
}

class F64ConvertI64S extends SingleByteInstruction {
  const F64ConvertI64S() : super(0xB9);

  static F64ConvertI64S deserialize(Deserializer d) => const F64ConvertI64S();

  @override
  String get name => 'f64.convert_i64_s';
}

class F64ConvertI64U extends SingleByteInstruction {
  const F64ConvertI64U() : super(0xBA);

  static F64ConvertI64U deserialize(Deserializer d) => const F64ConvertI64U();

  @override
  String get name => 'f64.convert_i64_u';
}

class F64PromoteF32 extends SingleByteInstruction {
  const F64PromoteF32() : super(0xBB);

  static F64PromoteF32 deserialize(Deserializer d) => const F64PromoteF32();

  @override
  String get name => 'f64.promote_f32';
}

class I32ReinterpretF32 extends SingleByteInstruction {
  const I32ReinterpretF32() : super(0xBC);

  static I32ReinterpretF32 deserialize(Deserializer d) =>
      const I32ReinterpretF32();

  @override
  String get name => 'i32.reinterpret_f32';
}

class I64ReinterpretF64 extends SingleByteInstruction {
  const I64ReinterpretF64() : super(0xBD);

  static I64ReinterpretF64 deserialize(Deserializer d) =>
      const I64ReinterpretF64();

  @override
  String get name => 'i64.reinterpret_f64';
}

class F32ReinterpretI32 extends SingleByteInstruction {
  const F32ReinterpretI32() : super(0xBE);

  static F32ReinterpretI32 deserialize(Deserializer d) =>
      const F32ReinterpretI32();

  @override
  String get name => 'f32.reinterpret_i32';
}

class F64ReinterpretI64 extends SingleByteInstruction {
  const F64ReinterpretI64() : super(0xBF);

  static F64ReinterpretI64 deserialize(Deserializer d) =>
      const F64ReinterpretI64();

  @override
  String get name => 'f64.reinterpret_i64';
}

class I32Extend8S extends SingleByteInstruction {
  const I32Extend8S() : super(0xC0);

  static I32Extend8S deserialize(Deserializer d) => const I32Extend8S();

  @override
  String get name => 'i32.extend8_s';
}

class I32Extend16S extends SingleByteInstruction {
  const I32Extend16S() : super(0xC1);

  static I32Extend16S deserialize(Deserializer d) => const I32Extend16S();

  @override
  String get name => 'i32.extend16_s';
}

class I64Extend8S extends SingleByteInstruction {
  const I64Extend8S() : super(0xC2);

  static I64Extend8S deserialize(Deserializer d) => const I64Extend8S();

  @override
  String get name => 'i64.extend8_s';
}

class I64Extend16S extends SingleByteInstruction {
  const I64Extend16S() : super(0xC3);

  static I64Extend16S deserialize(Deserializer d) => const I64Extend16S();

  @override
  String get name => 'i64.extend16_s';
}

class I64Extend32S extends SingleByteInstruction {
  const I64Extend32S() : super(0xC4);

  static I64Extend32S deserialize(Deserializer d) => const I64Extend32S();

  @override
  String get name => 'i64.extend32_s';
}

class I32TruncSatF32S extends Instruction {
  const I32TruncSatF32S();

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFC);
    s.writeByte(0x00);
  }

  static I32TruncSatF32S deserialize(Deserializer d) => const I32TruncSatF32S();

  @override
  String get name => 'i32.trunc_sat_f32_s';
}

class I32TruncSatF32U extends Instruction {
  const I32TruncSatF32U();

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFC);
    s.writeByte(0x01);
  }

  static I32TruncSatF32U deserialize(Deserializer d) => const I32TruncSatF32U();

  @override
  String get name => 'i32.trunc_sat_f32_u';
}

class I32TruncSatF64S extends Instruction {
  const I32TruncSatF64S();

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFC);
    s.writeByte(0x02);
  }

  static I32TruncSatF64S deserialize(Deserializer d) => const I32TruncSatF64S();

  @override
  String get name => 'i32.trunc_sat_f64_s';
}

class I32TruncSatF64U extends Instruction {
  const I32TruncSatF64U();

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFC);
    s.writeByte(0x03);
  }

  static I32TruncSatF64U deserialize(Deserializer d) => const I32TruncSatF64U();

  @override
  String get name => 'i32.trunc_sat_f64_u';
}

class I64TruncSatF32S extends Instruction {
  const I64TruncSatF32S();

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFC);
    s.writeByte(0x04);
  }

  static I64TruncSatF32S deserialize(Deserializer d) => const I64TruncSatF32S();

  @override
  String get name => 'i64.trunc_sat_f32_s';
}

class I64TruncSatF32U extends Instruction {
  const I64TruncSatF32U();

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFC);
    s.writeByte(0x05);
  }

  static I64TruncSatF32U deserialize(Deserializer d) => const I64TruncSatF32U();

  @override
  String get name => 'i64.trunc_sat_f32_u';
}

class I64TruncSatF64S extends Instruction {
  const I64TruncSatF64S();

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFC);
    s.writeByte(0x06);
  }

  static I64TruncSatF64S deserialize(Deserializer d) => const I64TruncSatF64S();

  @override
  String get name => 'i64.trunc_sat_f64_s';
}

class I64TruncSatF64U extends Instruction {
  const I64TruncSatF64U();

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFC);
    s.writeByte(0x07);
  }

  static I64TruncSatF64U deserialize(Deserializer d) => const I64TruncSatF64U();

  @override
  String get name => 'i64.trunc_sat_f64_u';
}

enum V128Instruction with Instruction {
  i8x16Splat(0x0F, 'i8x16.splat'),
  i16x8Splat(0x10, 'i16x8.splat'),
  i32x4Splat(0x11, 'i32x4.splat'),
  i64x2Splat(0x12, 'i64x2.splat'),
  f32x4Splat(0x13, 'f32x4.splat'),
  f64x2Splat(0x14, 'f64x2.splat'),
  i8x16Eq(0x23, 'i8x16.eq'),
  i16x8Eq(0x2D, 'i16x8.eq'),
  i32x4Eq(0x37, 'i32x4.eq'),
  f32x4Eq(0x41, 'f32x4.eq'),
  f32x4Ne(0x42, 'f32x4.ne'),
  f32x4Lt(0x43, 'f32x4.lt'),
  f32x4Gt(0x44, 'f32x4.gt'),
  f32x4Le(0x45, 'f32x4.le'),
  f32x4Ge(0x46, 'f32x4.ge'),
  f64x2Eq(0x47, 'f64x2.eq'),
  f64x2Ne(0x48, 'f64x2.ne'),
  f64x2Lt(0x49, 'f64x2.lt'),
  f64x2Gt(0x4A, 'f64x2.gt'),
  f64x2Le(0x4B, 'f64x2.le'),
  f64x2Ge(0x4C, 'f64x2.ge'),
  v128Not(0x4D, 'v128.not'),
  v128And(0x4E, 'v128.and'),
  v128AndNot(0x4F, 'v128.andnot'),
  v128Or(0x50, 'v128.or'),
  v128Xor(0x51, 'v128.xor'),
  v128BitSelect(0x52, 'v128.bitselect'),
  v128AnyTrue(0x53, 'v128.any_true'),
  i8x16Neg(0x61, 'i8x16.neg'),
  i8x16AllTrue(0x63, 'i8x16.all_true'),
  f32x4Ceil(0x67, 'f32x4.ceil'),
  f32x4Floor(0x68, 'f32x4.floor'),
  f32x4Trunc(0x69, 'f32x4.trunc'),
  f32x4Nearest(0x6A, 'f32x4.nearest'),
  i8x16Add(0x6E, 'i8x16.add'),
  i8x16Sub(0x71, 'i8x16.sub'),
  f64x2Ceil(0x74, 'f64x2.ceil'),
  f64x2Floor(0x75, 'f64x2.floor'),
  f64x2Trunc(0x7A, 'f64x2.trunc'),
  f64x2Nearest(0x94, 'f64x2.nearest'),
  i16x8Neg(0x81, 'i16x8.neg'),
  i16x8AllTrue(0x83, 'i16x8.all_true'),
  i16x8Add(0x8E, 'i16x8.add'),
  i16x8Sub(0x91, 'i16x8.sub'),
  i16x8Mul(0x95, 'i16x8.mul'),
  i32x4Neg(0xA1, 'i32x4.neg'),
  i32x4AllTrue(0xA3, 'i32x4.all_true'),
  i32x4Add(0xAE, 'i32x4.add'),
  i32x4Sub(0xB1, 'i32x4.sub'),
  i32x4Mul(0xB5, 'i32x4.mul'),
  i32x4DotI16x8(0xBA, 'i32x4.dot_i16x8_s'),
  i64x2Neg(0xC1, 'i64x2.neg'),
  i64x2AllTrue(0xC3, 'i64x2.all_true'),
  i64x2Add(0xCE, 'i64x2.add'),
  i64x2Sub(0xD1, 'i64x2.sub'),
  i64x2Mul(0xD5, 'i64x2.mul'),
  i64x2Eq(0xD6, 'i64x2.eq'),
  f32x4Abs(0xE0, 'f32x4.abs'),
  f32x4Neg(0xE1, 'f32x4.neg'),
  f32x4Sqrt(0xE3, 'f32x4.sqrt'),
  f32x4Add(0xE4, 'f32x4.add'),
  f32x4Sub(0xE5, 'f32x4.sub'),
  f32x4Mul(0xE6, 'f32x4.mul'),
  f32x4Div(0xE7, 'f32x4.div'),
  f32x4Min(0xE8, 'f32x4.min'),
  f32x4Max(0xE9, 'f32x4.max'),
  f32x4PMin(0xEA, 'f32x4.pmin'),
  f32x4PMax(0xEB, 'f32x4.pmax'),
  f64x2Abs(0xEC, 'f64x2.abs'),
  f64x2Neg(0xED, 'f64x2.neg'),
  f64x2Sqrt(0xEF, 'f64x2.sqrt'),
  f64x2Add(0xF0, 'f64x2.add'),
  f64x2Sub(0xF1, 'f64x2.sub'),
  f64x2Mul(0xF2, 'f64x2.mul'),
  f64x2Div(0xF3, 'f64x2.div'),
  f64x2Min(0xF4, 'f64x2.min'),
  f64x2Max(0xF5, 'f64x2.max'),
  f64x2PMin(0xF6, 'f64x2.pmin'),
  f64x2PMax(0xF7, 'f64x2.pmax');

  final int opcode;
  @override
  final String name;

  const V128Instruction(this.opcode, this.name);

  static List<V128Instruction?> _lookup = (() {
    final lookup = List<V128Instruction?>.filled(256, null);
    for (final v in values) {
      lookup[v.opcode] = v;
    }
    return lookup;
  })();

  static V128Instruction? fromOpcode(int opcode) => _lookup[opcode];

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFD);
    s.writeUnsigned(opcode);
  }
}

class I8x16Shuffle extends Instruction {
  const I8x16Shuffle(this.lanes);

  final List<int> lanes;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFD);
    s.writeUnsigned(0x0D);
    for (var lane in lanes) {
      s.writeByte(lane);
    }
  }

  static I8x16Shuffle deserialize(Deserializer d) =>
      I8x16Shuffle(List.generate(16, (_) => d.readByte()));

  @override
  String get name => 'i8x16.shuffle';

  @override
  String toString() => '$name ${lanes.join(' ')}';
}

class I8x16ExtractLaneS extends Instruction {
  const I8x16ExtractLaneS(this.lane);

  final int lane;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFD);
    s.writeUnsigned(0x15);
    s.writeByte(lane);
  }

  static I8x16ExtractLaneS deserialize(Deserializer d) =>
      I8x16ExtractLaneS(d.readByte());

  @override
  String get name => 'i8x16.extract_lane_s';
}

class I8x16ExtractLaneU extends Instruction {
  const I8x16ExtractLaneU(this.lane);

  final int lane;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFD);
    s.writeUnsigned(0x16);
    s.writeByte(lane);
  }

  static I8x16ExtractLaneU deserialize(Deserializer d) =>
      I8x16ExtractLaneU(d.readByte());

  @override
  String get name => 'i8x16.extract_lane_u';
}

class I8x16ReplaceLane extends Instruction {
  const I8x16ReplaceLane(this.lane);

  final int lane;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFD);
    s.writeUnsigned(0x17);
    s.writeByte(lane);
  }

  static I8x16ReplaceLane deserialize(Deserializer d) =>
      I8x16ReplaceLane(d.readByte());

  @override
  String get name => 'i8x16.replace_lane';
}

class I16x8ExtractLaneS extends Instruction {
  const I16x8ExtractLaneS(this.lane);

  final int lane;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFD);
    s.writeUnsigned(0x18);
    s.writeByte(lane);
  }

  static I16x8ExtractLaneS deserialize(Deserializer d) =>
      I16x8ExtractLaneS(d.readByte());

  @override
  String get name => 'i16x8.extract_lane_s';
}

class I16x8ExtractLaneU extends Instruction {
  const I16x8ExtractLaneU(this.lane);

  final int lane;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFD);
    s.writeUnsigned(0x19);
    s.writeByte(lane);
  }

  static I16x8ExtractLaneU deserialize(Deserializer d) =>
      I16x8ExtractLaneU(d.readByte());

  @override
  String get name => 'i16x8.extract_lane_u';
}

class I16x8ReplaceLane extends Instruction {
  const I16x8ReplaceLane(this.lane);

  final int lane;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFD);
    s.writeUnsigned(0x1A);
    s.writeByte(lane);
  }

  static I16x8ReplaceLane deserialize(Deserializer d) =>
      I16x8ReplaceLane(d.readByte());

  @override
  String get name => 'i16x8.replace_lane';
}

class I32x4ExtractLane extends Instruction {
  const I32x4ExtractLane(this.lane);

  final int lane;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFD);
    s.writeUnsigned(0x1B);
    s.writeByte(lane);
  }

  static I32x4ExtractLane deserialize(Deserializer d) =>
      I32x4ExtractLane(d.readByte());

  @override
  String get name => 'i32x4.extract_lane';
}

class I32x4ReplaceLane extends Instruction {
  const I32x4ReplaceLane(this.lane);

  final int lane;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFD);
    s.writeUnsigned(0x1C);
    s.writeByte(lane);
  }

  static I32x4ReplaceLane deserialize(Deserializer d) =>
      I32x4ReplaceLane(d.readByte());

  @override
  String get name => 'i32x4.replace_lane';
}

class I64x2ExtractLane extends Instruction {
  const I64x2ExtractLane(this.lane);

  final int lane;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFD);
    s.writeUnsigned(0x1D);
    s.writeByte(lane);
  }

  static I64x2ExtractLane deserialize(Deserializer d) =>
      I64x2ExtractLane(d.readByte());

  @override
  String get name => 'i64x2.extract_lane';
}

class I64x2ReplaceLane extends Instruction {
  const I64x2ReplaceLane(this.lane);

  final int lane;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFD);
    s.writeUnsigned(0x1E);
    s.writeByte(lane);
  }

  static I64x2ReplaceLane deserialize(Deserializer d) =>
      I64x2ReplaceLane(d.readByte());

  @override
  String get name => 'i64x2.replace_lane';
}

class F32x4ExtractLane extends Instruction {
  const F32x4ExtractLane(this.lane);

  final int lane;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFD);
    s.writeUnsigned(0x1F);
    s.writeByte(lane);
  }

  static F32x4ExtractLane deserialize(Deserializer d) =>
      F32x4ExtractLane(d.readByte());

  @override
  String get name => 'f32x4.extract_lane';
}

class F32x4ReplaceLane extends Instruction {
  const F32x4ReplaceLane(this.lane);

  final int lane;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFD);
    s.writeUnsigned(0x20);
    s.writeByte(lane);
  }

  static F32x4ReplaceLane deserialize(Deserializer d) =>
      F32x4ReplaceLane(d.readByte());

  @override
  String get name => 'f32x4.replace_lane';
}

class F64x2ExtractLane extends Instruction {
  const F64x2ExtractLane(this.lane);

  final int lane;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFD);
    s.writeUnsigned(0x21);
    s.writeByte(lane);
  }

  static F64x2ExtractLane deserialize(Deserializer d) =>
      F64x2ExtractLane(d.readByte());

  @override
  String get name => 'f64x2.extract_lane';
}

class F64x2ReplaceLane extends Instruction {
  const F64x2ReplaceLane(this.lane);

  final int lane;

  @override
  void serialize(Serializer s) {
    s.writeByte(0xFD);
    s.writeUnsigned(0x22);
    s.writeByte(lane);
  }

  static F64x2ReplaceLane deserialize(Deserializer d) =>
      F64x2ReplaceLane(d.readByte());

  @override
  String get name => 'f64x2.replace_lane';
}

class BeginNoEffectTryTable extends Instruction {
  final List<TryTableCatch> catches;

  BeginNoEffectTryTable(this.catches);

  static BeginNoEffectTryTable deserialize(Deserializer d, Tags tags) {
    d.readByte();
    final catches = d.readList((d) => TryTableCatch.deserialize(d, tags));
    return BeginNoEffectTryTable(catches);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x1F);
    s.writeByte(0x40);
    s.writeUnsigned(catches.length);
    for (final catch_ in catches) {
      catch_.serialize(s);
    }
  }

  @override
  String get name => 'try_table';
}

class BeginOneOutputTryTable extends Instruction {
  final ValueType type;
  final List<TryTableCatch> catches;

  @override
  List<ValueType> get usedValueTypes => [type];

  BeginOneOutputTryTable(this.type, this.catches);

  static BeginOneOutputTryTable deserialize(
      Deserializer d, Tags tags, Types types) {
    final type = ValueType.deserialize(d, types.defined);
    final catches = d.readList((d) => TryTableCatch.deserialize(d, tags));
    return BeginOneOutputTryTable(type, catches);
  }

  @override
  void serialize(Serializer s) {
    s.writeByte(0x1F);
    s.write(type);
    s.writeUnsigned(catches.length);
    for (final catch_ in catches) {
      catch_.serialize(s);
    }
  }

  @override
  String get name => 'try_table';
}

class BeginFunctionTryTable extends Instruction {
  final FunctionType type;
  final List<TryTableCatch> catches;

  BeginFunctionTryTable(this.type, this.catches);

  static BeginFunctionTryTable deserialize(
      Deserializer d, Tags tags, Types types) {
    final type = types.defined[d.readSigned()] as FunctionType;
    final catches = d.readList((d) => TryTableCatch.deserialize(d, tags));
    return BeginFunctionTryTable(type, catches);
  }

  @override
  List<DefType> get usedDefTypes => [type];

  @override
  void serialize(Serializer s) {
    s.writeByte(0x1F);
    s.write(type);
    s.writeUnsigned(catches.length);
    for (final catch_ in catches) {
      catch_.serialize(s);
    }
  }

  @override
  String get name => 'try_table';
}

abstract class TryTableCatch {
  final int labelIndex;

  TryTableCatch(this.labelIndex);

  void serialize(Serializer s);

  static TryTableCatch deserialize(Deserializer d, Tags tags) {
    final kind = d.readByte();
    switch (kind) {
      case 0x00:
        final tag = tags[d.readUnsigned()];
        final label = d.readUnsigned();
        return Catch(tag, label);
      case 0x01:
        final tag = tags[d.readUnsigned()];
        final label = d.readUnsigned();
        return CatchRef(tag, label);
      case 0x02:
        final label = d.readUnsigned();
        return CatchAll(label);
      case 0x03:
        final label = d.readUnsigned();
        return CatchAllRef(label);
      default:
        throw "Invalid TryTableCatch kind: $kind";
    }
  }
}

class Catch extends TryTableCatch {
  final Tag tag;

  Catch(this.tag, super.labelIndex);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x00);
    s.writeUnsigned(tag.index);
    s.writeUnsigned(labelIndex);
  }
}

class CatchRef extends TryTableCatch {
  final Tag tag;

  CatchRef(this.tag, super.labelIndex);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x01);
    s.writeUnsigned(tag.index);
    s.writeUnsigned(labelIndex);
  }
}

class CatchAll extends TryTableCatch {
  CatchAll(super.labelIndex);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x02);
    s.writeUnsigned(labelIndex);
  }
}

class CatchAllRef extends TryTableCatch {
  CatchAllRef(super.labelIndex);

  @override
  void serialize(Serializer s) {
    s.writeByte(0x03);
    s.writeUnsigned(labelIndex);
  }
}

extension on Serializer {
  void writeTypeIndex(DefType type) => writeUnsigned(type.index);
}

extension on Deserializer {
  int readTypeIndex() => readUnsigned();

  Instruction deserializeBlock(
      Types types,
      Tags tags,
      Instruction Function(Deserializer, Tags) deserializeNoInputNoOutput,
      Instruction Function(Deserializer, Tags, Types) deserializeOneOutput,
      Instruction Function(Deserializer, Tags, Types) deserializeGeneral) {
    if (peekByte() == 0x40) {
      // 0x40 means empty type, the block has neither inputs nor outputs.
      return deserializeNoInputNoOutput(this, tags);
    }
    final oldOffset = offset;
    final value = readSigned();
    offset = oldOffset;
    if (value < 0) {
      // not positive signed integer, the block has no inputs and exactly one
      // output.
      return deserializeOneOutput(this, tags, types);
    }
    // positive signed integer is index into defined types and must be a
    // function type representing the input & output types.
    return deserializeGeneral(this, tags, types);
  }
}
