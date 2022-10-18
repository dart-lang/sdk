// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart2wasm/class_info.dart';
import 'package:dart2wasm/code_generator.dart';
import 'package:dart2wasm/translator.dart';

import 'package:kernel/ast.dart';

import 'package:wasm_builder/wasm_builder.dart' as w;

/// Specialized code generation for external members.
///
/// The code is generated either inlined at the call site, or as the body of the
/// member in [generateMemberIntrinsic].
class Intrinsifier {
  final CodeGenerator codeGen;

  // The ABI type sizes are the same for 32-bit Wasm as for 32-bit ARM, so we
  // can just use an ABI enum index corresponding to a 32-bit ARM platform.
  static const int abiEnumIndex = 0; // androidArm

  static const w.ValueType boolType = w.NumType.i32;
  static const w.ValueType intType = w.NumType.i64;
  static const w.ValueType doubleType = w.NumType.f64;

  static final Map<w.ValueType, Map<w.ValueType, Map<String, CodeGenCallback>>>
      binaryOperatorMap = {
    intType: {
      intType: {
        '+': (b) => b.i64_add(),
        '-': (b) => b.i64_sub(),
        '*': (b) => b.i64_mul(),
        '~/': (b) {
          final arg2Local = b.addLocal(intType, isParameter: false);
          b.local_set(arg2Local);

          final arg1Local = b.addLocal(intType, isParameter: false);
          b.local_set(arg1Local);

          // Division special case: overflow in I64.
          // MIN_VALUE / -1 = (MAX_VALUE + 1), which wraps around to MIN_VALUE
          b.local_get(arg2Local);
          b.i64_const(-1);
          b.i64_eq();
          b.if_([], [intType]);
          b.local_get(arg1Local);
          b.i64_const(-9223372036854775808); // MIN_VALUE
          b.i64_eq();
          b.if_([], [intType]);
          b.i64_const(-9223372036854775808); // MIN_VALUE
          b.else_();
          b.local_get(arg1Local);
          b.local_get(arg2Local);
          b.i64_div_s();
          b.end();
          b.else_();
          b.local_get(arg1Local);
          b.local_get(arg2Local);
          b.i64_div_s();
          b.end();
        },
        '&': (b) => b.i64_and(),
        '|': (b) => b.i64_or(),
        '^': (b) => b.i64_xor(),
        '<<': (b) => b.i64_shl(),
        '>>': (b) => b.i64_shr_s(),
        '>>>': (b) => b.i64_shr_u(),
        '<': (b) => b.i64_lt_s(),
        '<=': (b) => b.i64_le_s(),
        '>': (b) => b.i64_gt_s(),
        '>=': (b) => b.i64_ge_s(),
      }
    },
    doubleType: {
      doubleType: {
        '+': (b) => b.f64_add(),
        '-': (b) => b.f64_sub(),
        '*': (b) => b.f64_mul(),
        '/': (b) => b.f64_div(),
        '<': (b) => b.f64_lt(),
        '<=': (b) => b.f64_le(),
        '>': (b) => b.f64_gt(),
        '>=': (b) => b.f64_ge(),
      }
    },
  };
  static final Map<w.ValueType, Map<String, CodeGenCallback>> unaryOperatorMap =
      {
    intType: {
      'unary-': (b) {
        b.i64_const(-1);
        b.i64_mul();
      },
      '~': (b) {
        b.i64_const(-1);
        b.i64_xor();
      },
      'toDouble': (b) {
        b.f64_convert_i64_s();
      },
    },
    doubleType: {
      'unary-': (b) {
        b.f64_neg();
      },
      'toInt': (b) {
        b.i64_trunc_sat_f64_s();
      },
      'roundToDouble': (b) {
        b.f64_nearest();
      },
      'floorToDouble': (b) {
        b.f64_floor();
      },
      'ceilToDouble': (b) {
        b.f64_ceil();
      },
      'truncateToDouble': (b) {
        b.f64_trunc();
      },
    },
  };
  static final Map<String, w.ValueType> unaryResultMap = {
    'toDouble': w.NumType.f64,
    'toInt': w.NumType.i64,
    'roundToDouble': w.NumType.f64,
    'floorToDouble': w.NumType.f64,
    'ceilToDouble': w.NumType.f64,
    'truncateToDouble': w.NumType.f64,
  };

  Translator get translator => codeGen.translator;
  w.Instructions get b => codeGen.b;

  DartType dartTypeOf(Expression exp) => codeGen.dartTypeOf(exp);

  w.ValueType typeOfExp(Expression exp) {
    return translator.translateType(dartTypeOf(exp));
  }

  static bool isComparison(String op) =>
      op == '<' || op == '<=' || op == '>' || op == '>=';

  Intrinsifier(this.codeGen);

  w.ValueType? generateInstanceGetterIntrinsic(InstanceGet node) {
    Expression receiver = node.receiver;
    DartType receiverType = dartTypeOf(receiver);
    String name = node.name.text;
    Member target = node.interfaceTarget;
    Class cls = target.enclosingClass!;

    // WasmAnyRef.isObject
    if (cls == translator.wasmAnyRefClass) {
      assert(name == "isObject");
      w.Label succeed = b.block(const [], const [w.NumType.i32]);
      w.Label fail = b.block(const [], const [w.RefType.any(nullable: false)]);
      codeGen.wrap(receiver, w.RefType.any(nullable: false));
      b.br_on_non_data(fail);
      b.ref_test(translator.topInfo.struct);
      b.br(succeed);
      b.end(); // fail
      b.drop();
      b.i32_const(0);
      b.end(); // succeed
      return w.NumType.i32;
    }

    // _WasmArray.length
    if (cls == translator.wasmArrayBaseClass) {
      assert(name == 'length');
      DartType elementType =
          (receiverType as InterfaceType).typeArguments.single;
      w.ArrayType arrayType = translator.arrayTypeForDartType(elementType);
      codeGen.wrap(receiver, w.RefType.def(arrayType, nullable: true));
      b.array_len(arrayType);
      b.i64_extend_i32_u();
      return w.NumType.i64;
    }

    // WasmTable.size
    if (cls == translator.wasmTableClass) {
      if (receiver is! StaticGet || receiver.target is! Field) {
        throw "Table size not directly on a static field"
            " at ${node.location}";
      }
      w.Table table = translator.getTable(receiver.target as Field)!;
      assert(name == "size");
      b.table_size(table);
      return w.NumType.i32;
    }

    // int.bitlength
    if (cls == translator.coreTypes.intClass && name == 'bitLength') {
      w.Local temp = codeGen.function.addLocal(w.NumType.i64);
      b.i64_const(64);
      codeGen.wrap(receiver, w.NumType.i64);
      b.local_tee(temp);
      b.local_get(temp);
      b.i64_const(63);
      b.i64_shr_s();
      b.i64_xor();
      b.i64_clz();
      b.i64_sub();
      return w.NumType.i64;
    }

    // _HashAbstractImmutableBase._indexNullable
    if (target == translator.hashImmutableIndexNullable) {
      ClassInfo info = translator.classInfo[translator.hashFieldBaseClass]!;
      codeGen.wrap(receiver, info.nullableType);
      b.struct_get(info.struct, FieldIndex.hashBaseIndex);
      return info.struct.fields[FieldIndex.hashBaseIndex].type.unpacked;
    }

    // _Compound._typedDataBase
    if (cls == translator.ffiCompoundClass && name == '_typedDataBase') {
      // A compound (subclass of Struct or Union) is represented by its i32
      // address. The _typedDataBase field contains a Pointer pointing to the
      // compound, whose representation is the same.
      codeGen.wrap(receiver, w.NumType.i32);
      return w.NumType.i32;
    }

    // Pointer.address
    if (cls == translator.ffiPointerClass && name == 'address') {
      // A Pointer is represented by its i32 address.
      codeGen.wrap(receiver, w.NumType.i32);
      b.i64_extend_i32_u();
      return w.NumType.i64;
    }

    return null;
  }

  w.ValueType? generateInstanceIntrinsic(InstanceInvocation node) {
    Expression receiver = node.receiver;
    DartType receiverType = dartTypeOf(receiver);
    String name = node.name.text;
    Procedure target = node.interfaceTarget;
    Class cls = target.enclosingClass!;

    // _TypedListBase._setRange
    if (cls == translator.typedListBaseClass && name == "_setRange") {
      // Always fall back to alternative implementation.
      b.i32_const(0);
      return w.NumType.i32;
    }

    // _TypedList._(get|set)(Int|Uint|Float)(8|16|32|64)
    if (cls == translator.typedListClass) {
      Match? match = RegExp("^_(get|set)(Int|Uint|Float)(8|16|32|64)\$")
          .matchAsPrefix(name);
      if (match != null) {
        bool setter = match.group(1) == "set";
        bool signed = match.group(2) == "Int";
        bool float = match.group(2) == "Float";
        int bytes = int.parse(match.group(3)!) ~/ 8;
        bool wide = bytes == 8;

        ClassInfo typedListInfo =
            translator.classInfo[translator.typedListClass]!;
        w.RefType arrayType = typedListInfo.struct
            .fields[FieldIndex.typedListArray].type.unpacked as w.RefType;
        w.ArrayType arrayHeapType = arrayType.heapType as w.ArrayType;
        w.ValueType valueType = float ? w.NumType.f64 : w.NumType.i64;
        w.ValueType intType = wide ? w.NumType.i64 : w.NumType.i32;

        // Prepare array and offset
        w.Local array = codeGen.addLocal(arrayType);
        w.Local offset = codeGen.addLocal(w.NumType.i32);
        codeGen.wrap(receiver, typedListInfo.nullableType);
        b.struct_get(typedListInfo.struct, FieldIndex.typedListArray);
        b.local_set(array);
        codeGen.wrap(node.arguments.positional[0], w.NumType.i64);
        b.i32_wrap_i64();
        b.local_set(offset);

        if (setter) {
          // Setter
          w.Local value = codeGen.addLocal(intType);
          codeGen.wrap(node.arguments.positional[1], valueType);
          if (wide) {
            if (float) {
              b.i64_reinterpret_f64();
            }
          } else {
            if (float) {
              b.f32_demote_f64();
              b.i32_reinterpret_f32();
            } else {
              b.i32_wrap_i64();
            }
          }
          b.local_set(value);

          for (int i = 0; i < bytes; i++) {
            b.local_get(array);
            b.local_get(offset);
            if (i > 0) {
              b.i32_const(i);
              b.i32_add();
            }
            b.local_get(value);
            if (i > 0) {
              if (wide) {
                b.i64_const(i * 8);
                b.i64_shr_u();
              } else {
                b.i32_const(i * 8);
                b.i32_shr_u();
              }
            }
            if (wide) {
              b.i32_wrap_i64();
            }
            b.array_set(arrayHeapType);
          }
          return translator.voidMarker;
        } else {
          // Getter
          for (int i = 0; i < bytes; i++) {
            b.local_get(array);
            b.local_get(offset);
            if (i > 0) {
              b.i32_const(i);
              b.i32_add();
            }
            if (signed && i == bytes - 1) {
              b.array_get_s(arrayHeapType);
            } else {
              b.array_get_u(arrayHeapType);
            }
            if (wide) {
              if (signed) {
                b.i64_extend_i32_s();
              } else {
                b.i64_extend_i32_u();
              }
            }
            if (i > 0) {
              if (wide) {
                b.i64_const(i * 8);
                b.i64_shl();
                b.i64_or();
              } else {
                b.i32_const(i * 8);
                b.i32_shl();
                b.i32_or();
              }
            }
          }

          if (wide) {
            if (float) {
              b.f64_reinterpret_i64();
            }
          } else {
            if (float) {
              b.f32_reinterpret_i32();
              b.f64_promote_f32();
            } else {
              if (signed) {
                b.i64_extend_i32_s();
              } else {
                b.i64_extend_i32_u();
              }
            }
          }
          return valueType;
        }
      }
    }

    // WasmAnyRef.toObject
    if (cls == translator.wasmAnyRefClass && name == "toObject") {
      w.Label succeed = b.block(const [], [translator.topInfo.nonNullableType]);
      w.Label fail = b.block(const [], const [w.RefType.any(nullable: false)]);
      codeGen.wrap(receiver, w.RefType.any(nullable: false));
      b.br_on_non_data(fail);
      b.br_on_cast(succeed, translator.topInfo.struct);
      b.end(); // fail
      codeGen.throwWasmRefError("a Dart object");
      b.end(); // succeed
      return translator.topInfo.nonNullableType;
    }

    // WasmIntArray.(readSigned|readUnsigned|write)
    // WasmFloatArray.(read|write)
    // WasmObjectArray.(read|write)
    if (cls.superclass == translator.wasmArrayBaseClass) {
      DartType elementType =
          (receiverType as InterfaceType).typeArguments.single;
      w.ArrayType arrayType = translator.arrayTypeForDartType(elementType);
      w.StorageType wasmType = arrayType.elementType.type;
      bool innerExtend =
          wasmType == w.PackedType.i8 || wasmType == w.PackedType.i16;
      bool outerExtend =
          wasmType.unpacked == w.NumType.i32 || wasmType == w.NumType.f32;
      switch (name) {
        case 'read':
        case 'readSigned':
        case 'readUnsigned':
          bool unsigned = name == 'readUnsigned';
          Expression array = receiver;
          Expression index = node.arguments.positional.single;
          codeGen.wrap(array, w.RefType.def(arrayType, nullable: true));
          codeGen.wrap(index, w.NumType.i64);
          b.i32_wrap_i64();
          if (innerExtend) {
            if (unsigned) {
              b.array_get_u(arrayType);
            } else {
              b.array_get_s(arrayType);
            }
          } else {
            b.array_get(arrayType);
          }
          if (outerExtend) {
            if (wasmType == w.NumType.f32) {
              b.f64_promote_f32();
              return w.NumType.f64;
            } else {
              if (unsigned) {
                b.i64_extend_i32_u();
              } else {
                b.i64_extend_i32_s();
              }
              return w.NumType.i64;
            }
          }
          return wasmType.unpacked;
        case 'write':
          Expression array = receiver;
          Expression index = node.arguments.positional[0];
          Expression value = node.arguments.positional[1];
          codeGen.wrap(array, w.RefType.def(arrayType, nullable: true));
          codeGen.wrap(index, w.NumType.i64);
          b.i32_wrap_i64();
          codeGen.wrap(value, typeOfExp(value));
          if (outerExtend) {
            if (wasmType == w.NumType.f32) {
              b.f32_demote_f64();
            } else {
              b.i32_wrap_i64();
            }
          }
          b.array_set(arrayType);
          return codeGen.voidMarker;
        default:
          throw "Unsupported array method: $name";
      }
    }

    // Wasm(I32|I64|F32|F64) conversions
    if (cls.superclass?.superclass == translator.wasmTypesBaseClass) {
      w.StorageType receiverType = translator.builtinTypes[cls]!;
      switch (receiverType) {
        case w.NumType.i32:
          codeGen.wrap(receiver, w.NumType.i32);
          switch (name) {
            case "toIntSigned":
              b.i64_extend_i32_s();
              return w.NumType.i64;
            case "toIntUnsigned":
              b.i64_extend_i32_u();
              return w.NumType.i64;
            case "toBool":
              b.i32_const(0);
              b.i32_ne();
              return w.NumType.i32;
            default:
              throw 'Unknown i32 conversion to $receiverType';
          }
        case w.NumType.i64:
          assert(name == "toInt");
          codeGen.wrap(receiver, w.NumType.i64);
          return w.NumType.i64;
        case w.NumType.f32:
          assert(name == "toDouble");
          codeGen.wrap(receiver, w.NumType.f32);
          b.f64_promote_f32();
          return w.NumType.f64;
        case w.NumType.f64:
          assert(name == "toDouble");
          codeGen.wrap(receiver, w.NumType.f64);
          return w.NumType.f64;
      }
    }

    // WasmTable.[] and WasmTable.[]=
    if (cls == translator.wasmTableClass) {
      if (receiver is! StaticGet || receiver.target is! Field) {
        throw "Table indexing not directly on a static field"
            " at ${node.location}";
      }
      w.Table table = translator.getTable(receiver.target as Field)!;
      codeGen.wrap(node.arguments.positional[0], w.NumType.i32);
      if (name == '[]') {
        b.table_get(table);
        return table.type;
      } else {
        assert(name == '[]=');
        codeGen.wrap(node.arguments.positional[1], table.type);
        b.table_set(table);
        return codeGen.voidMarker;
      }
    }

    // List.[] on list constants
    if (receiver is ConstantExpression &&
        receiver.constant is ListConstant &&
        name == '[]') {
      Expression arg = node.arguments.positional.single;

      // If the list is indexed by a constant, or the ABI index, just pick
      // the element at that constant index.
      int? constIndex = null;
      if (arg is IntLiteral) {
        constIndex = arg.value;
      } else if (arg is ConstantExpression) {
        Constant argConst = arg.constant;
        if (argConst is IntConstant) {
          constIndex = argConst.value;
        }
      } else if (arg is StaticInvocation) {
        if (arg.target.enclosingLibrary.name == "dart.ffi" &&
            arg.name.text == "_abi") {
          constIndex = abiEnumIndex;
        }
      }
      if (constIndex != null) {
        ListConstant list = receiver.constant as ListConstant;
        Expression element = ConstantExpression(list.entries[constIndex]);
        return codeGen.wrap(element, typeOfExp(element));
      }

      // Access the underlying array directly.
      ClassInfo info = translator.classInfo[translator.listBaseClass]!;
      w.RefType listType = info.nullableType;
      Field arrayField = translator.listBaseClass.fields
          .firstWhere((f) => f.name.text == '_data');
      int arrayFieldIndex = translator.fieldIndex[arrayField]!;
      w.ArrayType arrayType =
          (info.struct.fields[arrayFieldIndex].type as w.RefType).heapType
              as w.ArrayType;
      codeGen.wrap(receiver, listType);
      b.struct_get(info.struct, arrayFieldIndex);
      codeGen.wrap(arg, w.NumType.i64);
      b.i32_wrap_i64();
      b.array_get(arrayType);
      return translator.topInfo.nullableType;
    }

    if (node.arguments.positional.length == 1) {
      // Binary operator
      Expression left = node.receiver;
      Expression right = node.arguments.positional.single;
      DartType argType = dartTypeOf(right);
      if (argType is VoidType) return null;
      w.ValueType leftType = translator.translateType(receiverType);
      w.ValueType rightType = translator.translateType(argType);
      var code = binaryOperatorMap[leftType]?[rightType]?[name];
      if (code != null) {
        w.ValueType outType = isComparison(name) ? w.NumType.i32 : leftType;
        codeGen.wrap(left, leftType);
        codeGen.wrap(right, rightType);
        code(b);
        return outType;
      }
    } else if (node.arguments.positional.isEmpty) {
      // Unary operator
      Expression operand = node.receiver;
      w.ValueType opType = translator.translateType(receiverType);
      var code = unaryOperatorMap[opType]?[name];
      if (code != null) {
        codeGen.wrap(operand, opType);
        code(b);
        return unaryResultMap[name] ?? opType;
      }
    }

    return null;
  }

  w.ValueType? generateEqualsIntrinsic(EqualsCall node) {
    w.ValueType leftType = typeOfExp(node.left);
    w.ValueType rightType = typeOfExp(node.right);

    // Compare bool or Pointer
    if (leftType == boolType && rightType == boolType) {
      codeGen.wrap(node.left, w.NumType.i32);
      codeGen.wrap(node.right, w.NumType.i32);
      b.i32_eq();
      return w.NumType.i32;
    }

    // Compare int
    if (leftType == intType && rightType == intType) {
      codeGen.wrap(node.left, w.NumType.i64);
      codeGen.wrap(node.right, w.NumType.i64);
      b.i64_eq();
      return w.NumType.i32;
    }

    // Compare double
    if (leftType == doubleType && rightType == doubleType) {
      codeGen.wrap(node.left, w.NumType.f64);
      codeGen.wrap(node.right, w.NumType.f64);
      b.f64_eq();
      return w.NumType.i32;
    }

    return null;
  }

  w.ValueType? generateStaticGetterIntrinsic(StaticGet node) {
    Member target = node.target;

    // ClassID getters
    String? className = translator.getPragma(target, "wasm:class-id");
    if (className != null) {
      List<String> libAndClass = className.split("#");
      Class cls = translator.libraries
          .firstWhere(
              (l) => l.name == libAndClass[0] && l.importUri.scheme == 'dart')
          .classes
          .firstWhere((c) => c.name == libAndClass[1]);
      int classId = translator.classInfo[cls]!.classId;
      b.i64_const(classId);
      return w.NumType.i64;
    }

    // nullptr
    if (target.enclosingLibrary.name == "dart.ffi" &&
        target.name.text == "nullptr") {
      // A Pointer is represented by its i32 address.
      b.i32_const(0);
      return w.NumType.i32;
    }

    if (target.enclosingLibrary.name == "dart.core" &&
        target.name.text == "_isIntrinsified") {
      // This is part of the VM's [BigInt] implementation. We just return false.
      // TODO(joshualitt): Can we find another way to reuse this patch file
      // without hardcoding this case?
      b.i32_const(0);
      return w.NumType.i32;
    }

    return null;
  }

  w.ValueType getID(Expression node) {
    ClassInfo info = translator.topInfo;
    codeGen.wrap(node, info.nullableType);
    b.struct_get(info.struct, FieldIndex.classId);
    b.i64_extend_i32_u();
    return w.NumType.i64;
  }

  w.ValueType changeListClassID(StaticInvocation node, Class newClass) {
    ClassInfo receiverInfo = translator.classInfo[translator.listBaseClass]!;
    codeGen.wrap(
        node.arguments.positional.single, receiverInfo.nonNullableType);
    w.Local receiverLocal =
        codeGen.function.addLocal(receiverInfo.nonNullableType);
    b.local_tee(receiverLocal);
    // We ignore the type argument and just update the classID of the
    // receiver.
    // TODO(joshualitt): If the amount of free space is significant, it
    // might be worth doing a copy here.
    ClassInfo newInfo = translator.classInfo[newClass]!;
    ClassInfo topInfo = translator.topInfo;
    b.i32_const(newInfo.classId);
    b.struct_set(topInfo.struct, FieldIndex.classId);
    b.local_get(receiverLocal);
    return newInfo.nonNullableType;
  }

  w.ValueType? generateStaticIntrinsic(StaticInvocation node) {
    String name = node.name.text;
    Class? cls = node.target.enclosingClass;

    // dart:core static functions
    if (node.target.enclosingLibrary == translator.coreTypes.coreLibrary) {
      switch (name) {
        case "identical":
          Expression first = node.arguments.positional[0];
          Expression second = node.arguments.positional[1];
          DartType boolType = translator.coreTypes.boolNonNullableRawType;
          InterfaceType intType = translator.coreTypes.intNonNullableRawType;
          DartType doubleType = translator.coreTypes.doubleNonNullableRawType;
          List<DartType> types = [dartTypeOf(first), dartTypeOf(second)];
          if (types.every((t) => t == intType)) {
            codeGen.wrap(first, w.NumType.i64);
            codeGen.wrap(second, w.NumType.i64);
            b.i64_eq();
            return w.NumType.i32;
          }
          if (types.any((t) =>
              t is InterfaceType &&
              t != boolType &&
              t != doubleType &&
              !translator.hierarchy
                  .isSubtypeOf(intType.classNode, t.classNode))) {
            codeGen.wrap(first, w.RefType.eq(nullable: true));
            codeGen.wrap(second, w.RefType.eq(nullable: true));
            b.ref_eq();
            return w.NumType.i32;
          }
          break;
        case "_getHash":
          Expression arg = node.arguments.positional[0];
          w.ValueType objectType = translator.objectInfo.nullableType;
          codeGen.wrap(arg, objectType);
          b.struct_get(translator.objectInfo.struct, FieldIndex.identityHash);
          b.i64_extend_i32_u();
          return w.NumType.i64;
        case "_setHash":
          Expression arg = node.arguments.positional[0];
          Expression hash = node.arguments.positional[1];
          w.ValueType objectType = translator.objectInfo.nullableType;
          codeGen.wrap(arg, objectType);
          codeGen.wrap(hash, w.NumType.i64);
          b.i32_wrap_i64();
          b.struct_set(translator.objectInfo.struct, FieldIndex.identityHash);
          return codeGen.voidMarker;
        case "_throwObjectWithStackTrace":
          Expression object = node.arguments.positional[0];
          Expression stackTrace = node.arguments.positional[1];
          w.ValueType objectType = translator.topInfo.nonNullableType;
          w.ValueType stackTraceType =
              translator.stackTraceInfo.nonNullableType;
          codeGen.wrap(object, objectType);
          codeGen.wrap(stackTrace, stackTraceType);
          b.throw_(translator.exceptionTag);
          return codeGen.voidMarker;
        case "_getTypeRulesSupers":
          return translator.types.makeTypeRulesSupers(b);
        case "_getTypeRulesSubstitutions":
          return translator.types.makeTypeRulesSubstitutions(b);
        case "_getTypeNames":
          return translator.types.makeTypeNames(b);
        case "_getFunctionTypeRuntimeType":
          Expression object = node.arguments.positional[0];
          w.StructType closureBase =
              translator.closureLayouter.closureBaseStruct;
          codeGen.wrap(object, w.RefType.def(closureBase, nullable: true));
          b.struct_get(closureBase, FieldIndex.closureRuntimeType);
          return translator.types.typeClassInfo.nonNullableType;
        case "_getInterfaceTypeRuntimeType":
          Expression object = node.arguments.positional[0];
          Expression typeArguments = node.arguments.positional[1];
          ClassInfo info = translator.classInfo[translator.interfaceTypeClass]!;
          b.i32_const(info.classId);
          b.i32_const(initialIdentityHash);
          // Runtime types are never nullable.
          b.i32_const(0);
          getID(object);
          codeGen.wrap(typeArguments, translator.types.typeListExpectedType);
          b.struct_new(info.struct);
          return info.nonNullableType;
      }
    }

    // dart:_internal static functions
    if (node.target.enclosingLibrary.name == "dart._internal") {
      switch (name) {
        case "unsafeCast":
        case "unsafeCastOpaque":
          Expression operand = node.arguments.positional.single;
          // Just evaluate the operand and let the context convert it to the
          // expected type.
          return codeGen.wrap(operand, typeOfExp(operand));
        case "_nativeEffect":
          // Ignore argument
          return translator.voidMarker;
        case "allocateOneByteString":
          ClassInfo info = translator.classInfo[translator.oneByteStringClass]!;
          translator.functions.allocateClass(info.classId);
          w.ArrayType arrayType =
              translator.wasmArrayType(w.PackedType.i8, "WasmI8");
          Expression length = node.arguments.positional[0];
          b.i32_const(info.classId);
          b.i32_const(initialIdentityHash);
          codeGen.wrap(length, w.NumType.i64);
          b.i32_wrap_i64();
          b.array_new_default(arrayType);
          b.struct_new(info.struct);
          return info.nonNullableType;
        case "writeIntoOneByteString":
          ClassInfo info = translator.classInfo[translator.oneByteStringClass]!;
          w.ArrayType arrayType =
              translator.wasmArrayType(w.PackedType.i8, "WasmI8");
          Field arrayField = translator.oneByteStringClass.fields
              .firstWhere((f) => f.name.text == '_array');
          int arrayFieldIndex = translator.fieldIndex[arrayField]!;
          Expression string = node.arguments.positional[0];
          Expression index = node.arguments.positional[1];
          Expression codePoint = node.arguments.positional[2];
          codeGen.wrap(string, info.nonNullableType);
          b.struct_get(info.struct, arrayFieldIndex);
          codeGen.wrap(index, w.NumType.i64);
          b.i32_wrap_i64();
          codeGen.wrap(codePoint, w.NumType.i64);
          b.i32_wrap_i64();
          b.array_set(arrayType);
          return codeGen.voidMarker;
        case "allocateTwoByteString":
          ClassInfo info = translator.classInfo[translator.twoByteStringClass]!;
          translator.functions.allocateClass(info.classId);
          w.ArrayType arrayType =
              translator.wasmArrayType(w.PackedType.i16, "WasmI16");
          Expression length = node.arguments.positional[0];
          b.i32_const(info.classId);
          b.i32_const(initialIdentityHash);
          codeGen.wrap(length, w.NumType.i64);
          b.i32_wrap_i64();
          b.array_new_default(arrayType);
          b.struct_new(info.struct);
          return info.nonNullableType;
        case "writeIntoTwoByteString":
          ClassInfo info = translator.classInfo[translator.twoByteStringClass]!;
          w.ArrayType arrayType =
              translator.wasmArrayType(w.PackedType.i16, "WasmI16");
          Field arrayField = translator.oneByteStringClass.fields
              .firstWhere((f) => f.name.text == '_array');
          int arrayFieldIndex = translator.fieldIndex[arrayField]!;
          Expression string = node.arguments.positional[0];
          Expression index = node.arguments.positional[1];
          Expression codePoint = node.arguments.positional[2];
          codeGen.wrap(string, info.nonNullableType);
          b.struct_get(info.struct, arrayFieldIndex);
          codeGen.wrap(index, w.NumType.i64);
          b.i32_wrap_i64();
          codeGen.wrap(codePoint, w.NumType.i64);
          b.i32_wrap_i64();
          b.array_set(arrayType);
          return codeGen.voidMarker;
        case "floatToIntBits":
          codeGen.wrap(node.arguments.positional.single, w.NumType.f64);
          b.f32_demote_f64();
          b.i32_reinterpret_f32();
          b.i64_extend_i32_u();
          return w.NumType.i64;
        case "intBitsToFloat":
          codeGen.wrap(node.arguments.positional.single, w.NumType.i64);
          b.i32_wrap_i64();
          b.f32_reinterpret_i32();
          b.f64_promote_f32();
          return w.NumType.f64;
        case "doubleToIntBits":
          codeGen.wrap(node.arguments.positional.single, w.NumType.f64);
          b.i64_reinterpret_f64();
          return w.NumType.i64;
        case "intBitsToDouble":
          codeGen.wrap(node.arguments.positional.single, w.NumType.i64);
          b.f64_reinterpret_i64();
          return w.NumType.f64;
        case "getID":
          return getID(node.arguments.positional.single);
        case "makeListFixedLength":
          return changeListClassID(node, translator.fixedLengthListClass);
        case "makeFixedListUnmodifiable":
          return changeListClassID(node, translator.immutableListClass);
      }
    }

    // dart:ffi static functions
    if (node.target.enclosingLibrary.name == "dart.ffi") {
      // Pointer.fromAddress
      if (name == "fromAddress") {
        // A Pointer is represented by its i32 address.
        codeGen.wrap(node.arguments.positional.single, w.NumType.i64);
        b.i32_wrap_i64();
        return w.NumType.i32;
      }

      // Accesses to Pointer.value, Pointer.value=, Pointer.[], Pointer.[]= and
      // the members of structs and unions are desugared by the FFI kernel
      // transformations into calls to memory load and store functions.
      RegExp loadStoreFunctionNames = RegExp("^_(load|store)"
          "((Int|Uint)(8|16|32|64)|(Float|Double)(Unaligned)?|Pointer)\$");
      if (loadStoreFunctionNames.hasMatch(name)) {
        Expression pointerArg = node.arguments.positional[0];
        Expression offsetArg = node.arguments.positional[1];
        codeGen.wrap(pointerArg, w.NumType.i32);
        int offset;
        if (offsetArg is IntLiteral) {
          offset = offsetArg.value;
        } else if (offsetArg is ConstantExpression &&
            offsetArg.constant is IntConstant) {
          offset = (offsetArg.constant as IntConstant).value;
        } else {
          codeGen.wrap(offsetArg, w.NumType.i64);
          b.i32_wrap_i64();
          b.i32_add();
          offset = 0;
        }
        switch (name) {
          case "_loadInt8":
            b.i64_load8_s(translator.ffiMemory, offset);
            return w.NumType.i64;
          case "_loadUint8":
            b.i64_load8_u(translator.ffiMemory, offset);
            return w.NumType.i64;
          case "_loadInt16":
            b.i64_load16_s(translator.ffiMemory, offset);
            return w.NumType.i64;
          case "_loadUint16":
            b.i64_load16_u(translator.ffiMemory, offset);
            return w.NumType.i64;
          case "_loadInt32":
            b.i64_load32_s(translator.ffiMemory, offset);
            return w.NumType.i64;
          case "_loadUint32":
            b.i64_load32_u(translator.ffiMemory, offset);
            return w.NumType.i64;
          case "_loadInt64":
          case "_loadUint64":
            b.i64_load(translator.ffiMemory, offset);
            return w.NumType.i64;
          case "_loadFloat":
            b.f32_load(translator.ffiMemory, offset);
            b.f64_promote_f32();
            return w.NumType.f64;
          case "_loadFloatUnaligned":
            b.f32_load(translator.ffiMemory, offset, 0);
            b.f64_promote_f32();
            return w.NumType.f64;
          case "_loadDouble":
            b.f64_load(translator.ffiMemory, offset);
            return w.NumType.f64;
          case "_loadDoubleUnaligned":
            b.f64_load(translator.ffiMemory, offset, 0);
            return w.NumType.f64;
          case "_loadPointer":
            b.i32_load(translator.ffiMemory, offset);
            return w.NumType.i32;
          case "_storeInt8":
          case "_storeUint8":
            codeGen.wrap(node.arguments.positional[2], w.NumType.i64);
            b.i64_store8(translator.ffiMemory, offset);
            return translator.voidMarker;
          case "_storeInt16":
          case "_storeUint16":
            codeGen.wrap(node.arguments.positional[2], w.NumType.i64);
            b.i64_store16(translator.ffiMemory, offset);
            return translator.voidMarker;
          case "_storeInt32":
          case "_storeUint32":
            codeGen.wrap(node.arguments.positional[2], w.NumType.i64);
            b.i64_store32(translator.ffiMemory, offset);
            return translator.voidMarker;
          case "_storeInt64":
          case "_storeUint64":
            codeGen.wrap(node.arguments.positional[2], w.NumType.i64);
            b.i64_store(translator.ffiMemory, offset);
            return translator.voidMarker;
          case "_storeFloat":
            codeGen.wrap(node.arguments.positional[2], w.NumType.f64);
            b.f32_demote_f64();
            b.f32_store(translator.ffiMemory, offset);
            return translator.voidMarker;
          case "_storeFloatUnaligned":
            codeGen.wrap(node.arguments.positional[2], w.NumType.f64);
            b.f32_demote_f64();
            b.f32_store(translator.ffiMemory, offset, 0);
            return translator.voidMarker;
          case "_storeDouble":
            codeGen.wrap(node.arguments.positional[2], w.NumType.f64);
            b.f64_store(translator.ffiMemory, offset);
            return translator.voidMarker;
          case "_storeDoubleUnaligned":
            codeGen.wrap(node.arguments.positional[2], w.NumType.f64);
            b.f64_store(translator.ffiMemory, offset, 0);
            return translator.voidMarker;
          case "_storePointer":
            codeGen.wrap(node.arguments.positional[2], w.NumType.i32);
            b.i32_store(translator.ffiMemory, offset);
            return translator.voidMarker;
        }
      }
    }

    if (cls != null && translator.isWasmType(cls)) {
      // Wasm(Int|Float|Object)Array constructors
      if (cls.superclass == translator.wasmArrayBaseClass) {
        Expression length = node.arguments.positional[0];
        w.ArrayType arrayType =
            translator.arrayTypeForDartType(node.arguments.types.single);
        codeGen.wrap(length, w.NumType.i64);
        b.i32_wrap_i64();
        b.array_new_default(arrayType);
        return w.RefType.def(arrayType, nullable: false);
      }

      // (WasmFuncRef|WasmFunction).fromRef constructors
      if (cls == translator.wasmFunctionClass && name == "fromFuncRef") {
        Expression ref = node.arguments.positional[0];
        w.RefType resultType = typeOfExp(node) as w.RefType;
        w.Label succeed = b.block(const [], [resultType]);
        codeGen.wrap(ref, w.RefType.func(nullable: false));
        b.br_on_cast(succeed, resultType.heapType as w.FunctionType);
        codeGen.throwWasmRefError("a function with the expected signature");
        b.end(); // succeed
        return resultType;
      }

      // WasmFunction.fromFunction constructor
      if (cls == translator.wasmFunctionClass) {
        assert(name == "fromFunction");
        Expression f = node.arguments.positional[0];
        if (f is! ConstantExpression || f.constant is! StaticTearOffConstant) {
          throw "Argument to WasmFunction.fromFunction isn't a static function";
        }
        StaticTearOffConstant func = f.constant as StaticTearOffConstant;
        w.BaseFunction wasmFunction =
            translator.functions.getFunction(func.targetReference);
        w.Global functionRef = translator.makeFunctionRef(wasmFunction);
        b.global_get(functionRef);
        return functionRef.type.type;
      }

      // Wasm(AnyRef|FuncRef|EqRef|DataRef|I32|I64|F32|F64) constructors
      Expression value = node.arguments.positional[0];
      w.StorageType targetType = translator.builtinTypes[cls]!;
      switch (targetType) {
        case w.NumType.i32:
          switch (name) {
            case "fromInt":
              codeGen.wrap(value, w.NumType.i64);
              b.i32_wrap_i64();
              return w.NumType.i32;
            case "int8FromInt":
              codeGen.wrap(value, w.NumType.i64);
              b.i32_wrap_i64();
              b.i32_extend8_s();
              return w.NumType.i32;
            case "uint8FromInt":
              codeGen.wrap(value, w.NumType.i64);
              b.i32_wrap_i64();
              b.i32_const(0xFF);
              b.i32_and();
              return w.NumType.i32;
            case "int16FromInt":
              codeGen.wrap(value, w.NumType.i64);
              b.i32_wrap_i64();
              b.i32_extend16_s();
              return w.NumType.i32;
            case "uint16FromInt":
              codeGen.wrap(value, w.NumType.i64);
              b.i32_wrap_i64();
              b.i32_const(0xFFFF);
              b.i32_and();
              return w.NumType.i32;
            case "fromBool":
              codeGen.wrap(value, w.NumType.i32);
              return w.NumType.i32;
            default:
              throw 'Unhandled WasmI32 factory: $name';
          }

        case w.NumType.i64:
          codeGen.wrap(value, w.NumType.i64);
          return w.NumType.i64;
        case w.NumType.f32:
          codeGen.wrap(value, w.NumType.f64);
          b.f32_demote_f64();
          return w.NumType.f32;
        case w.NumType.f64:
          codeGen.wrap(value, w.NumType.f64);
          return w.NumType.f64;
        default:
          w.RefType valueType = targetType as w.RefType;
          codeGen.wrap(value, valueType);
          return valueType;
      }
    }

    // dart:wasm static functions
    if (node.target.enclosingLibrary.name == "dart.wasm") {
      Expression value = node.arguments.positional.single;
      switch (name) {
        case "_externalizeNonNullable":
          codeGen.wrap(value, w.RefType.any(nullable: false));
          b.extern_externalize();
          return w.RefType.extern(nullable: false);
        case "_externalizeNullable":
          codeGen.wrap(value, w.RefType.any(nullable: true));
          b.extern_externalize();
          return w.RefType.extern(nullable: true);
        case "_internalizeNonNullable":
          codeGen.wrap(value, w.RefType.extern(nullable: false));
          b.extern_internalize();
          return w.RefType.any(nullable: false);
        case "_internalizeNullable":
          codeGen.wrap(value, w.RefType.extern(nullable: true));
          b.extern_internalize();
          return w.RefType.any(nullable: true);
      }
    }

    return null;
  }

  w.ValueType? generateConstructorIntrinsic(ConstructorInvocation node) {
    String name = node.name.text;

    // _Compound.#fromTypedDataBase
    if (name == "#fromTypedDataBase") {
      // A compound (subclass of Struct or Union) is represented by its i32
      // address. The argument to the #fromTypedDataBase constructor is a
      // Pointer, whose representation is the same.
      codeGen.wrap(node.arguments.positional.single, w.NumType.i32);
      return w.NumType.i32;
    }

    return null;
  }

  w.ValueType? generateFunctionCallIntrinsic(FunctionInvocation node) {
    Expression receiver = node.receiver;

    if (receiver is InstanceGet &&
        receiver.interfaceTarget == translator.wasmFunctionCall) {
      // Receiver is a WasmFunction
      assert(receiver.name.text == "call");
      w.RefType receiverType =
          translator.translateType(dartTypeOf(receiver.receiver)) as w.RefType;
      w.Local temp = codeGen.addLocal(receiverType);
      codeGen.wrap(receiver.receiver, receiverType);
      b.local_set(temp);
      w.FunctionType functionType = receiverType.heapType as w.FunctionType;
      assert(node.arguments.positional.length == functionType.inputs.length);
      for (int i = 0; i < node.arguments.positional.length; i++) {
        codeGen.wrap(node.arguments.positional[i], functionType.inputs[i]);
      }
      b.local_get(temp);
      b.call_ref();
      return translator.outputOrVoid(functionType.outputs);
    }

    if (receiver is InstanceInvocation &&
        receiver.interfaceTarget == translator.wasmTableCallIndirect) {
      // Receiver is a WasmTable.callIndirect
      assert(receiver.name.text == "callIndirect");
      Expression tableExp = receiver.receiver;
      if (tableExp is! StaticGet || tableExp.target is! Field) {
        throw "Table callIndirect not directly on a static field"
            " at ${node.location}";
      }
      w.Table table = translator.getTable(tableExp.target as Field)!;
      InterfaceType wasmFunctionType = InterfaceType(
          translator.wasmFunctionClass,
          Nullability.nonNullable,
          [receiver.arguments.types.single]);
      w.RefType receiverType =
          translator.translateType(wasmFunctionType) as w.RefType;
      w.Local tableIndex = codeGen.addLocal(w.NumType.i32);
      codeGen.wrap(receiver.arguments.positional.single, w.NumType.i32);
      b.local_set(tableIndex);
      w.FunctionType functionType = receiverType.heapType as w.FunctionType;
      assert(node.arguments.positional.length == functionType.inputs.length);
      for (int i = 0; i < node.arguments.positional.length; i++) {
        codeGen.wrap(node.arguments.positional[i], functionType.inputs[i]);
      }
      b.local_get(tableIndex);
      b.call_indirect(functionType, table);
      return translator.outputOrVoid(functionType.outputs);
    }

    return null;
  }

  bool generateMemberIntrinsic(Reference target, w.DefinedFunction function,
      List<w.Local> paramLocals, w.Label? returnLabel) {
    Member member = target.asMember;
    if (member is! Procedure) return false;
    String name = member.name.text;
    FunctionNode functionNode = member.function;

    // Object.==
    if (member == translator.coreTypes.objectEquals) {
      b.local_get(paramLocals[0]);
      b.local_get(paramLocals[1]);
      b.ref_eq();
      return true;
    }

    // Object.runtimeType
    if (member.enclosingClass == translator.coreTypes.objectClass &&
        name == "runtimeType") {
      // Simple redirect to `_runtimeType`. This is done to keep
      // `Object.runtimeType` external, which seems to be necessary for the TFA.
      // If we don't do this, then the TFA assumes things like
      // `null.runtimeType` are impossible and inserts a throw.
      w.Local receiver = paramLocals[0];
      b.local_get(receiver);
      codeGen.call(translator.objectRuntimeType.reference);
      return true;
    }

    // identical
    if (member == translator.coreTypes.identicalProcedure) {
      w.Local first = paramLocals[0];
      w.Local second = paramLocals[1];
      ClassInfo boolInfo = translator.classInfo[translator.boxedBoolClass]!;
      ClassInfo intInfo = translator.classInfo[translator.boxedIntClass]!;
      ClassInfo doubleInfo = translator.classInfo[translator.boxedDoubleClass]!;
      w.Local cid = function.addLocal(w.NumType.i32);
      w.Label refEq = b.block();
      b.local_get(first);
      b.br_on_null(refEq);
      b.struct_get(translator.topInfo.struct, FieldIndex.classId);
      b.local_tee(cid);

      // Both bool?
      b.i32_const(boolInfo.classId);
      b.i32_eq();
      b.if_();
      b.local_get(first);
      b.ref_cast(boolInfo.struct);
      b.struct_get(boolInfo.struct, FieldIndex.boxValue);
      w.Label bothBool = b.block(const [], [boolInfo.nullableType]);
      b.local_get(second);
      b.br_on_cast(bothBool, boolInfo.struct);
      b.i32_const(0);
      b.return_();
      b.end();
      b.struct_get(boolInfo.struct, FieldIndex.boxValue);
      b.i32_eq();
      b.return_();
      b.end();

      // Both int?
      b.local_get(cid);
      b.i32_const(intInfo.classId);
      b.i32_eq();
      b.if_();
      b.local_get(first);
      b.ref_cast(intInfo.struct);
      b.struct_get(intInfo.struct, FieldIndex.boxValue);
      w.Label bothInt = b.block(const [], [intInfo.nullableType]);
      b.local_get(second);
      b.br_on_cast(bothInt, intInfo.struct);
      b.i32_const(0);
      b.return_();
      b.end();
      b.struct_get(intInfo.struct, FieldIndex.boxValue);
      b.i64_eq();
      b.return_();
      b.end();

      // Both double?
      b.local_get(cid);
      b.i32_const(doubleInfo.classId);
      b.i32_eq();
      b.if_();
      b.local_get(first);
      b.ref_cast(doubleInfo.struct);
      b.struct_get(doubleInfo.struct, FieldIndex.boxValue);
      b.i64_reinterpret_f64();
      w.Label bothDouble = b.block(const [], [doubleInfo.nullableType]);
      b.local_get(second);
      b.br_on_cast(bothDouble, doubleInfo.struct);
      b.i32_const(0);
      b.return_();
      b.end();
      b.struct_get(doubleInfo.struct, FieldIndex.boxValue);
      b.i64_reinterpret_f64();
      b.i64_eq();
      b.return_();
      b.end();

      // Compare as references
      b.end();
      b.local_get(first);
      b.local_get(second);
      b.ref_eq();

      return true;
    }

    // _typeArguments
    if (member.name.text == "_typeArguments") {
      Class cls = member.enclosingClass!;
      ClassInfo classInfo = translator.classInfo[cls]!;
      w.Local object = paramLocals[0];
      codeGen.makeList(translator.types.typeType, cls.typeParameters.length,
          (w.ValueType elementType, int i) {
        TypeParameter typeParameter = cls.typeParameters[i];
        int typeParameterIndex = translator.typeParameterIndex[typeParameter]!;
        b.local_get(object);
        b.ref_cast(classInfo.struct);
        b.struct_get(classInfo.struct, typeParameterIndex);
      });
      return true;
    }

    // (Int|Uint|Float)(8|16|32|64)(Clamped)?(List|ArrayView) constructors
    if (member.isExternal &&
        member.enclosingLibrary.name == "dart.typed_data") {
      if (member.isFactory) {
        String className = member.enclosingClass!.name;

        Match? match = RegExp("^(Int|Uint|Float)(8|16|32|64)(Clamped)?List\$")
            .matchAsPrefix(className);
        if (match != null) {
          int shift = int.parse(match.group(2)!).bitLength - 4;
          Class cls = member.enclosingLibrary.classes
              .firstWhere((c) => c.name == "_$className");
          ClassInfo info = translator.classInfo[cls]!;
          translator.functions.allocateClass(info.classId);
          w.ArrayType arrayType =
              translator.wasmArrayType(w.PackedType.i8, "i8");

          w.Local length = paramLocals[0];
          b.i32_const(info.classId);
          b.i32_const(initialIdentityHash);
          b.local_get(length);
          b.i32_wrap_i64();
          b.local_get(length);
          if (shift > 0) {
            b.i64_const(shift);
            b.i64_shl();
          }
          b.i32_wrap_i64();
          b.array_new_default(arrayType);
          b.struct_new(info.struct);
          return true;
        }

        match = RegExp("^_(Int|Uint|Float)(8|16|32|64)(Clamped)?ArrayView\$")
            .matchAsPrefix(className);
        if (match != null ||
            member.enclosingClass == translator.byteDataViewClass) {
          ClassInfo info = translator.classInfo[member.enclosingClass]!;
          translator.functions.allocateClass(info.classId);

          w.Local buffer = paramLocals[0];
          w.Local offsetInBytes = paramLocals[1];
          w.Local length = paramLocals[2];
          b.i32_const(info.classId);
          b.i32_const(initialIdentityHash);
          b.local_get(length);
          b.i32_wrap_i64();
          b.local_get(buffer);
          b.local_get(offsetInBytes);
          b.i32_wrap_i64();
          b.struct_new(info.struct);
          return true;
        }
      }

      // _TypedListBase.length
      // _TypedListView.offsetInBytes
      // _TypedListView._typedData
      // _ByteDataView.length
      // _ByteDataView.offsetInBytes
      // _ByteDataView._typedData
      if (member.isGetter) {
        Class cls = member.enclosingClass!;
        ClassInfo info = translator.classInfo[cls]!;
        b.local_get(paramLocals[0]);
        b.ref_cast(info.struct);
        // TODO(joshualitt): Because we currently merge getters to support
        // dynamic calls, the return types of `.length` and `.offsetInBytes` can
        // change. Should we decide to stop merging getters, we should remove
        // the conversions below.
        w.ValueType outputType = function.type.outputs.single;
        switch (name) {
          case "length":
            assert(cls == translator.typedListBaseClass ||
                cls == translator.byteDataViewClass);
            if (cls == translator.typedListBaseClass) {
              b.struct_get(info.struct, FieldIndex.typedListBaseLength);
            } else {
              b.struct_get(info.struct, FieldIndex.byteDataViewLength);
            }
            b.i64_extend_i32_u();
            translator.convertType(function, intType, outputType);
            return true;
          case "offsetInBytes":
            assert(cls == translator.typedListViewClass ||
                cls == translator.byteDataViewClass);
            if (cls == translator.typedListViewClass) {
              b.struct_get(info.struct, FieldIndex.typedListViewOffsetInBytes);
            } else {
              b.struct_get(info.struct, FieldIndex.byteDataViewOffsetInBytes);
            }
            b.i64_extend_i32_u();
            translator.convertType(function, intType, outputType);
            return true;
          case "_typedData":
            assert(cls == translator.typedListViewClass ||
                cls == translator.byteDataViewClass);
            if (cls == translator.typedListViewClass) {
              b.struct_get(info.struct, FieldIndex.typedListViewTypedData);
            } else {
              b.struct_get(info.struct, FieldIndex.byteDataViewTypedData);
            }
            return true;
        }
        throw "Unrecognized typed data getter: ${cls.name}.$name";
      }
    }

    // _asyncBridge2
    if (member.enclosingLibrary.name == "dart.async" &&
        name == "_asyncBridge2") {
      w.Local args = paramLocals[0];
      w.Local stack = paramLocals[1];
      const int stubFieldIndex = 0;

      b.local_get(args);
      b.local_get(stack);
      b.local_get(args);
      b.ref_cast(translator.functions.asyncStubBaseStruct);
      b.struct_get(translator.functions.asyncStubBaseStruct, stubFieldIndex);
      b.call_ref();
      return true;
    }

    // int members
    if (member.enclosingClass == translator.boxedIntClass &&
        member.function.body == null) {
      String op = member.name.text;
      if (functionNode.requiredParameterCount == 0) {
        CodeGenCallback? code = unaryOperatorMap[intType]![op];
        if (code != null) {
          w.ValueType resultType = unaryResultMap[op] ?? intType;
          w.ValueType inputType = function.type.inputs.single;
          w.ValueType outputType = function.type.outputs.single;
          b.local_get(function.locals[0]);
          translator.convertType(function, inputType, intType);
          code(b);
          translator.convertType(function, resultType, outputType);
          return true;
        }
      } else if (functionNode.requiredParameterCount == 1) {
        CodeGenCallback? code = binaryOperatorMap[intType]![intType]![op];
        if (code != null) {
          w.ValueType leftType = function.type.inputs[0];
          w.ValueType rightType = function.type.inputs[1];
          w.ValueType outputType = function.type.outputs.single;
          if (rightType == intType) {
            // int parameter
            b.local_get(function.locals[0]);
            translator.convertType(function, leftType, intType);
            b.local_get(function.locals[1]);
            code(b);
            if (!isComparison(op)) {
              translator.convertType(function, intType, outputType);
            }
            return true;
          }
          // num parameter
          ClassInfo intInfo = translator.classInfo[translator.boxedIntClass]!;
          w.Label intArg = b.block(const [], [intInfo.nonNullableType]);
          b.local_get(function.locals[1]);
          b.br_on_cast(intArg, intInfo.struct);
          // double argument
          b.drop();
          b.local_get(function.locals[0]);
          translator.convertType(function, leftType, intType);
          b.f64_convert_i64_s();
          b.local_get(function.locals[1]);
          translator.convertType(function, rightType, doubleType);
          // Inline double op
          CodeGenCallback doubleCode =
              binaryOperatorMap[doubleType]![doubleType]![op]!;
          doubleCode(b);
          if (!isComparison(op)) {
            translator.convertType(function, doubleType, outputType);
          }
          b.return_();
          b.end();
          // int argument
          translator.convertType(function, intInfo.nonNullableType, intType);
          w.Local rightTemp = function.addLocal(intType);
          b.local_set(rightTemp);
          b.local_get(function.locals[0]);
          translator.convertType(function, leftType, intType);
          b.local_get(rightTemp);
          code(b);
          if (!isComparison(op)) {
            translator.convertType(function, intType, outputType);
          }
          return true;
        }
      }
    }

    // double unary members
    if (member.enclosingClass == translator.boxedDoubleClass &&
        member.function.body == null) {
      String op = member.name.text;
      if (functionNode.requiredParameterCount == 0) {
        CodeGenCallback? code = unaryOperatorMap[doubleType]![op];
        if (code != null) {
          w.ValueType resultType = unaryResultMap[op] ?? doubleType;
          w.ValueType inputType = function.type.inputs.single;
          w.ValueType outputType = function.type.outputs.single;
          b.local_get(function.locals[0]);
          translator.convertType(function, inputType, doubleType);
          code(b);
          translator.convertType(function, resultType, outputType);
          return true;
        }
      }
    }

    return false;
  }
}
