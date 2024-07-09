// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'abi.dart' show kWasmAbiEnumIndex;
import 'class_info.dart';
import 'code_generator.dart';
import 'dynamic_forwarders.dart';
import 'translator.dart';
import 'types.dart';

typedef CodeGenCallback = void Function(CodeGenerator);

/// Specialized code generation for external members.
///
/// The code is generated either inlined at the call site, or as the body of
/// the member in [generateMemberIntrinsic].
class Intrinsifier {
  final CodeGenerator codeGen;

  static const w.ValueType boolType = w.NumType.i32;
  static const w.ValueType intType = w.NumType.i64;
  static const w.ValueType doubleType = w.NumType.f64;

  static final Map<w.ValueType, Map<w.ValueType, Map<String, CodeGenCallback>>>
      _binaryOperatorMap = {
    boolType: {
      boolType: {
        '|': (c) => c.b.i32_or(),
        '^': (c) => c.b.i32_xor(),
        '&': (c) => c.b.i32_and(),
      }
    },
    intType: {
      intType: {
        '+': (c) => c.b.i64_add(),
        '-': (c) => c.b.i64_sub(),
        '*': (c) => c.b.i64_mul(),
        '&': (c) => c.b.i64_and(),
        '|': (c) => c.b.i64_or(),
        '^': (c) => c.b.i64_xor(),
        '<': (c) => c.b.i64_lt_s(),
        '<=': (c) => c.b.i64_le_s(),
        '>': (c) => c.b.i64_gt_s(),
        '>=': (c) => c.b.i64_ge_s(),
        '~/': (c) => c.call(c.translator.truncDiv.reference),
      }
    },
    doubleType: {
      doubleType: {
        '+': (c) => c.b.f64_add(),
        '-': (c) => c.b.f64_sub(),
        '*': (c) => c.b.f64_mul(),
        '/': (c) => c.b.f64_div(),
        '<': (c) => c.b.f64_lt(),
        '<=': (c) => c.b.f64_le(),
        '>': (c) => c.b.f64_gt(),
        '>=': (c) => c.b.f64_ge(),
      }
    },
  };

  static final Map<w.ValueType, Map<String, CodeGenCallback>>
      _unaryOperatorMap = {
    intType: {
      'unary-': (c) {
        c.b.i64_const(-1);
        c.b.i64_mul();
      },
      '~': (c) {
        c.b.i64_const(-1);
        c.b.i64_xor();
      },
      'toDouble': (c) {
        c.b.f64_convert_i64_s();
      },
    },
    doubleType: {
      'unary-': (c) {
        c.b.f64_neg();
      },
      'floorToDouble': (c) {
        c.b.f64_floor();
      },
      'ceilToDouble': (c) {
        c.b.f64_ceil();
      },
      'truncateToDouble': (c) {
        c.b.f64_trunc();
      },
      '_toInt': (c) {
        c.b.i64_trunc_sat_f64_s();
      },
    },
  };

  static final Map<String, w.ValueType> _unaryResultMap = {
    'toDouble': w.NumType.f64,
    'floorToDouble': w.NumType.f64,
    'ceilToDouble': w.NumType.f64,
    'truncateToDouble': w.NumType.f64,
    '_toInt': w.NumType.i64,
  };

  Translator get translator => codeGen.translator;
  Types get types => codeGen.translator.types;
  w.InstructionsBuilder get b => codeGen.b;

  DartType dartTypeOf(Expression exp) => codeGen.dartTypeOf(exp);

  w.ValueType typeOfExp(Expression exp) {
    return translator.translateType(dartTypeOf(exp));
  }

  static bool isComparison(String op) =>
      op == '<' ||
      op == '<=' ||
      op == '>' ||
      op == '>=' ||
      op == '_le_u' ||
      op == '_lt_u';

  Intrinsifier(this.codeGen);

  /// Generate inline code for an [InstanceGet] if the member is an inlined
  /// intrinsic.
  w.ValueType? generateInstanceGetterIntrinsic(InstanceGet node) {
    Expression receiver = node.receiver;
    String name = node.name.text;
    Member target = node.interfaceTarget;
    Class cls = target.enclosingClass!;

    // WasmAnyRef.isObject
    if (cls == translator.wasmAnyRefClass) {
      assert(name == "isObject");
      codeGen.wrap(receiver, w.RefType.any(nullable: false));
      b.ref_test(translator.topInfo.nonNullableType);
      return w.NumType.i32;
    }

    // WasmArrayRef.length
    if (cls == translator.wasmArrayRefClass) {
      assert(name == 'length');
      codeGen.wrap(receiver, w.RefType.array(nullable: false));
      b.array_len();
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

    // Pointer.address
    if (cls == translator.ffiPointerClass && name == 'address') {
      // A Pointer is represented by its i32 address.
      codeGen.wrap(receiver, w.NumType.i32);
      b.i64_extend_i32_u();
      return w.NumType.i64;
    }

    return null;
  }

  /// Generate inline code for an [InstanceInvocation] if the member is an
  /// inlined intrinsic.
  w.ValueType? generateInstanceIntrinsic(InstanceInvocation node) {
    Expression receiver = node.receiver;
    DartType receiverType = dartTypeOf(receiver);
    String name = node.name.text;
    Procedure target = node.interfaceTarget;
    Class cls = target.enclosingClass!;

    // WasmAnyRef.toObject
    if (cls == translator.wasmAnyRefClass && name == "toObject") {
      w.Label succeed = b.block(const [], [translator.topInfo.nonNullableType]);
      codeGen.wrap(receiver, const w.RefType.any(nullable: false));
      b.br_on_cast(succeed, const w.RefType.any(nullable: false),
          translator.topInfo.nonNullableType);
      codeGen.throwWasmRefError("a Dart object");
      b.end(); // succeed
      return translator.topInfo.nonNullableType;
    }

    // Wasm(I32|I64|F32|F64) conversions
    if (cls.superclass == translator.wasmTypesBaseClass) {
      w.StorageType? receiverType = translator.builtinTypes[cls];
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
          }
          codeGen.wrap(node.arguments.positional[0], w.NumType.i32);
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
            case "+":
              b.i32_add();
              return w.NumType.i32;
            case "-":
              b.i32_sub();
              return w.NumType.i32;
            case ">>":
              b.i32_shr_s();
              return w.NumType.i32;
            case "<":
              b.i32_lt_s();
              return boolType;
            case "<=":
              b.i32_le_s();
              return boolType;
            case "==":
              b.i32_eq();
              return boolType;
            case ">=":
              b.i32_ge_s();
              return boolType;
            case ">":
              b.i32_gt_s();
              return boolType;
            default:
              throw 'Unknown WasmI32 member $name';
          }
        case w.NumType.i64:
          switch (name) {
            case "toInt":
              codeGen.wrap(receiver, w.NumType.i64);
              return w.NumType.i64;
            case "leU":
              codeGen.wrap(receiver, w.NumType.i64);
              codeGen.wrap(node.arguments.positional[0], w.NumType.i64);
              b.i64_le_u();
              return boolType;
            case "ltU":
              codeGen.wrap(receiver, w.NumType.i64);
              codeGen.wrap(node.arguments.positional[0], w.NumType.i64);
              b.i64_lt_u();
              return boolType;
            case "geU":
              codeGen.wrap(receiver, w.NumType.i64);
              codeGen.wrap(node.arguments.positional[0], w.NumType.i64);
              b.i64_ge_u();
              return boolType;
            case "gtU":
              codeGen.wrap(receiver, w.NumType.i64);
              codeGen.wrap(node.arguments.positional[0], w.NumType.i64);
              b.i64_gt_u();
              return boolType;
            case "shl":
              codeGen.wrap(receiver, w.NumType.i64);
              codeGen.wrap(node.arguments.positional[0], w.NumType.i64);
              b.i64_shl();
              return w.NumType.i64;
            case "shrS":
              codeGen.wrap(receiver, w.NumType.i64);
              codeGen.wrap(node.arguments.positional[0], w.NumType.i64);
              b.i64_shr_s();
              return w.NumType.i64;
            case "shrU":
              codeGen.wrap(receiver, w.NumType.i64);
              codeGen.wrap(node.arguments.positional[0], w.NumType.i64);
              b.i64_shr_u();
              return w.NumType.i64;
            case "divS":
              codeGen.wrap(receiver, w.NumType.i64);
              codeGen.wrap(node.arguments.positional[0], w.NumType.i64);
              b.i64_div_s();
              return w.NumType.i64;
            default:
              throw 'Unknown WasmI64 member $name';
          }
        case w.NumType.f32:
          assert(name == "toDouble");
          codeGen.wrap(receiver, w.NumType.f32);
          b.f64_promote_f32();
          return w.NumType.f64;
        case w.NumType.f64:
          switch (name) {
            case "toDouble":
              codeGen.wrap(receiver, w.NumType.f64);
              return w.NumType.f64;
            case "truncSatS":
              codeGen.wrap(receiver, w.NumType.f64);
              b.i64_trunc_sat_f64_s();
              return w.NumType.i64;
            case "copysign":
              codeGen.wrap(receiver, w.NumType.f64);
              codeGen.wrap(node.arguments.positional[0], w.NumType.f64);
              b.f64_copysign();
              return w.NumType.f64;
            default:
              throw 'Unknown WasmF64 member $name';
          }
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
      int? constIndex;
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
          constIndex = kWasmAbiEnumIndex;
        }
      }
      if (constIndex != null) {
        final entries = (receiver.constant as ListConstant).entries;
        if (0 <= constIndex && constIndex < entries.length) {
          Expression element = ConstantExpression(entries[constIndex]);
          return codeGen.wrap(element, typeOfExp(element));
        }
      }

      return null;
    }

    if (node.arguments.positional.length == 1) {
      // Binary operator
      Expression left = node.receiver;
      Expression right = node.arguments.positional.single;
      DartType argType = dartTypeOf(right);
      w.ValueType leftType = translator.translateType(receiverType);
      w.ValueType rightType = translator.translateType(argType);
      var code = _binaryOperatorMap[leftType]?[rightType]?[name];
      if (code != null) {
        w.ValueType outType = isComparison(name) ? w.NumType.i32 : leftType;
        codeGen.wrap(left, leftType);
        codeGen.wrap(right, rightType);
        code(codeGen);
        return outType;
      }
    } else if (node.arguments.positional.isEmpty) {
      // Unary operator
      Expression operand = node.receiver;
      w.ValueType opType = translator.translateType(receiverType);
      var code = _unaryOperatorMap[opType]?[name];
      if (code != null) {
        codeGen.wrap(operand, opType);
        code(codeGen);
        return _unaryResultMap[name] ?? opType;
      }
    }

    return null;
  }

  /// Generate inline code for an [EqualsCall] with an unboxed receiver.
  w.ValueType? generateEqualsIntrinsic(EqualsCall node) {
    w.ValueType leftType = typeOfExp(node.left);
    w.ValueType rightType = typeOfExp(node.right);

    // Compare bool, Pointer or WasmI32.
    if (leftType == w.NumType.i32 && rightType == w.NumType.i32) {
      codeGen.wrap(node.left, w.NumType.i32);
      codeGen.wrap(node.right, w.NumType.i32);
      b.i32_eq();
      return w.NumType.i32;
    }

    // Compare int or WasmI64.
    if (leftType == w.NumType.i64 && rightType == w.NumType.i64) {
      codeGen.wrap(node.left, w.NumType.i64);
      codeGen.wrap(node.right, w.NumType.i64);
      b.i64_eq();
      return w.NumType.i32;
    }

    // Compare WasmF32.
    if (leftType == w.NumType.f32 && rightType == w.NumType.f32) {
      codeGen.wrap(node.left, w.NumType.f32);
      codeGen.wrap(node.right, w.NumType.f32);
      b.f32_eq();
      return w.NumType.i32;
    }

    // Compare double or WasmF64.
    if (leftType == doubleType && rightType == doubleType) {
      codeGen.wrap(node.left, w.NumType.f64);
      codeGen.wrap(node.right, w.NumType.f64);
      b.f64_eq();
      return w.NumType.i32;
    }

    return null;
  }

  /// Generate inline code for a [StaticGet] if the member is an inlined
  /// intrinsic.
  w.ValueType? generateStaticGetterIntrinsic(StaticGet node) {
    final Member target = node.target;
    final Class? cls = target.enclosingClass;

    // ClassID getters
    if (cls?.name == 'ClassID') {
      final libAndClassName = translator.getPragma(target, "wasm:class-id");
      if (libAndClassName != null) {
        List<String> libAndClassNameParts = libAndClassName.split("#");
        final String lib = libAndClassNameParts[0];
        final String className = libAndClassNameParts[1];
        Class cls = translator.libraries
            .firstWhere((l) => l.name == lib && l.importUri.scheme == 'dart',
                orElse: () =>
                    throw 'Library $lib not found (${target.location})')
            .classes
            .firstWhere((c) => c.name == className,
                orElse: () =>
                    throw 'Class $className not found in library $lib '
                        '(${target.location})');
        int classId = translator.classInfo[cls]!.classId;
        b.i32_const(classId);
        return w.NumType.i32;
      }

      if (target.name.text == 'firstNonMasqueradedInterfaceClassCid') {
        b.i32_const(
            translator.classIdNumbering.firstNonMasqueradedInterfaceClassCid);
        return w.NumType.i32;
      }
    }

    // nullptr
    if (target.enclosingLibrary.name == "dart.ffi" &&
        target.name.text == "nullptr") {
      // A Pointer is represented by its i32 address.
      b.i32_const(0);
      return w.NumType.i32;
    }

    if (node.target.enclosingLibrary == translator.coreTypes.coreLibrary) {
      switch (target.name.text) {
        case "_isIntrinsified":
          // This is part of the VM's [BigInt] implementation. We just return false.
          // TODO(joshualitt): Can we find another way to reuse this patch file
          // without hardcoding this case?
          b.i32_const(0);
          return w.NumType.i32;
        case "_noSubstitutionIndex":
          b.i32_const(RuntimeTypeInformation.noSubstitutionIndex);
          return w.NumType.i32;
        case "_typeRulesSupers":
          final type = translator
              .translateStorageType(types.rtt.typeRulesSupersType)
              .unpacked;
          translator.constants
              .instantiateConstant(null, b, types.rtt.typeRulesSupers, type);
          return type;
        case "_canonicalSubstitutionTable":
          final type = translator
              .translateStorageType(types.rtt.substitutionTableConstantType)
              .unpacked;
          translator.constants.instantiateConstant(
              null, b, types.rtt.substitutionTableConstant, type);
          return type;
        case "_typeNames":
          final type =
              translator.translateStorageType(types.rtt.typeNamesType).unpacked;
          if (translator.options.minify) {
            b.ref_null((type as w.RefType).heapType);
          } else {
            translator.constants
                .instantiateConstant(null, b, types.rtt.typeNames, type);
          }
          return type;
      }
    }

    return null;
  }

  /// Generate inline code for a [StaticInvocation] if the member is an inlined
  /// intrinsic.
  w.ValueType? generateStaticIntrinsic(StaticInvocation node) {
    String name = node.name.text;
    final Procedure target = node.target;
    final Library library = target.enclosingLibrary;
    Class? cls = target.enclosingClass;

    if (target.isExtensionMember && library == translator.wasmLibrary) {
      final (ext, extDescriptor) = translator.extensionOfMember(target);
      final memberName = extDescriptor.name.text;

      // extension WasmArrayExt on WasmArray<T>
      if (ext.name == 'WasmArrayExt') {
        final dartWasmArrayType = dartTypeOf(node.arguments.positional.first);
        final dartElementType =
            (dartWasmArrayType as InterfaceType).typeArguments.single;
        w.ArrayType arrayType =
            translator.arrayTypeForDartType(dartElementType);
        w.StorageType wasmType = arrayType.elementType.type;

        switch (memberName) {
          case '[]':
            final array = node.arguments.positional[0];
            final index = node.arguments.positional[1];
            codeGen.wrap(array, w.RefType.def(arrayType, nullable: false));
            codeGen.wrap(index, w.NumType.i64);
            b.i32_wrap_i64();
            if (wasmType is w.PackedType) {
              b.array_get_u(arrayType);
            } else {
              b.array_get(arrayType);
            }
            return wasmType.unpacked;
          case '[]=':
            final array = node.arguments.positional[0];
            final index = node.arguments.positional[1];
            final value = node.arguments.positional[2];
            codeGen.wrap(array, w.RefType.def(arrayType, nullable: false));
            codeGen.wrap(index, w.NumType.i64);
            b.i32_wrap_i64();
            codeGen.wrap(value, typeOfExp(value));
            b.array_set(arrayType);
            return codeGen.voidMarker;
          case 'copy':
            final destArray = node.arguments.positional[0];
            final destOffset = node.arguments.positional[1];
            final sourceArray = node.arguments.positional[2];
            final sourceOffset = node.arguments.positional[3];
            final size = node.arguments.positional[4];

            codeGen.wrap(destArray, w.RefType.def(arrayType, nullable: false));
            codeGen.wrap(destOffset, w.NumType.i64);
            b.i32_wrap_i64();
            codeGen.wrap(
                sourceArray, w.RefType.def(arrayType, nullable: false));
            codeGen.wrap(sourceOffset, w.NumType.i64);
            b.i32_wrap_i64();
            codeGen.wrap(size, w.NumType.i64);
            b.i32_wrap_i64();
            b.array_copy(arrayType, arrayType);
            return codeGen.voidMarker;
          case 'fill':
            final array = node.arguments.positional[0];
            final offset = node.arguments.positional[1];
            final value = node.arguments.positional[2];
            final size = node.arguments.positional[3];

            codeGen.wrap(array, w.RefType.def(arrayType, nullable: false));
            codeGen.wrap(offset, w.NumType.i64);
            b.i32_wrap_i64();
            codeGen.wrap(value, translator.translateType(dartElementType));
            codeGen.wrap(size, w.NumType.i64);
            b.i32_wrap_i64();
            b.array_fill(arrayType);
            return codeGen.voidMarker;
          case 'clone':
            // Until `array.new_copy` we need a special case for empty arrays.
            // https://github.com/WebAssembly/gc/issues/367
            final sourceArray = node.arguments.positional[0];

            final sourceArrayRefType =
                w.RefType.def(arrayType, nullable: false);
            final sourceArrayLocal = codeGen.addLocal(sourceArrayRefType);
            final newArrayLocal = codeGen.addLocal(sourceArrayRefType);

            codeGen.wrap(sourceArray, sourceArrayRefType);
            b.local_tee(sourceArrayLocal);

            b.array_len();
            b.if_([], [sourceArrayRefType]);
            // Non-empty array. Create new one with the first element of the
            // source, then copy the rest.
            b.local_get(sourceArrayLocal);
            b.i32_const(0);
            b.array_get(arrayType);
            b.local_get(sourceArrayLocal);
            b.array_len();
            b.array_new(arrayType);
            b.local_tee(newArrayLocal); // copy dest
            b.i32_const(1); // copy dest offset
            b.local_get(sourceArrayLocal); // copy source
            b.i32_const(1); // copy source offset

            // copy size
            b.local_get(sourceArrayLocal);
            b.array_len();
            b.i32_const(1);
            b.i32_sub();

            b.array_copy(arrayType, arrayType);

            b.local_get(newArrayLocal);
            b.else_();
            // Empty array.
            b.array_new_fixed(arrayType, 0);
            b.end();

            return sourceArrayRefType;
          default:
            throw 'Unhandled WasmArrayExt external method: $memberName';
        }
      }

      // extension (I8|I16|I32|I64|F32|F64)ArrayExt on WasmArray<...>
      if (ext.name.endsWith('ArrayExt')) {
        final dartWasmArrayType = dartTypeOf(node.arguments.positional.first);
        final dartElementType =
            (dartWasmArrayType as InterfaceType).typeArguments.single;
        w.ArrayType arrayType =
            translator.arrayTypeForDartType(dartElementType);
        w.StorageType wasmType = arrayType.elementType.type;

        final innerExtend =
            wasmType == w.PackedType.i8 || wasmType == w.PackedType.i16;
        final outerExtend =
            wasmType.unpacked == w.NumType.i32 || wasmType == w.NumType.f32;

        // WasmArray<I*>.(readSigned|readUnsigned|write)
        // WasmArray<F*>.(read|write)
        switch (memberName) {
          case 'read':
          case 'readSigned':
          case 'readUnsigned':
            final unsigned = memberName == 'readUnsigned';
            final array = node.arguments.positional[0];
            final index = node.arguments.positional[1];
            codeGen.wrap(array, w.RefType.def(arrayType, nullable: false));
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
            final array = node.arguments.positional[0];
            final index = node.arguments.positional[1];
            final value = node.arguments.positional[2];
            codeGen.wrap(array, w.RefType.def(arrayType, nullable: false));
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
        }
      }
    }

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
                  .isSubInterfaceOf(intType.classNode, t.classNode))) {
            codeGen.wrap(first, w.RefType.eq(nullable: true));
            codeGen.wrap(second, w.RefType.eq(nullable: true));
            b.ref_eq();
            return w.NumType.i32;
          }
          break;
        case "_isObjectClassId":
          final classId = node.arguments.positional.single;

          final objectClassId = translator
              .classIdNumbering.classIds[translator.coreTypes.objectClass]!;

          codeGen.wrap(classId, w.NumType.i32);
          b.emitClassIdRangeCheck([Range(objectClassId, objectClassId)]);
          return w.NumType.i32;
        case "_isClosureClassId":
          final classId = node.arguments.positional.single;

          final ranges = translator.classIdNumbering
              .getConcreteClassIdRanges(translator.coreTypes.functionClass);
          assert(ranges.length <= 1);

          codeGen.wrap(classId, w.NumType.i32);
          b.emitClassIdRangeCheck(ranges);
          return w.NumType.i32;
        case "_isRecordClassId":
          final classId = node.arguments.positional.single;

          final ranges = translator.classIdNumbering
              .getConcreteClassIdRanges(translator.coreTypes.recordClass);
          assert(ranges.length <= 1);

          codeGen.wrap(classId, w.NumType.i32);
          b.emitClassIdRangeCheck(ranges);
          return w.NumType.i32;
      }
    }

    // dart:_object_helper static functions.
    if (node.target.enclosingLibrary.name == 'dart._object_helper') {
      switch (name) {
        case "getIdentityHashField":
          Expression arg = node.arguments.positional[0];
          w.ValueType objectType = translator.objectInfo.nonNullableType;
          codeGen.wrap(arg, objectType);
          b.struct_get(translator.objectInfo.struct, FieldIndex.identityHash);
          b.i64_extend_i32_u();
          return w.NumType.i64;
        case "setIdentityHashField":
          Expression arg = node.arguments.positional[0];
          Expression hash = node.arguments.positional[1];
          w.ValueType objectType = translator.objectInfo.nonNullableType;
          codeGen.wrap(arg, objectType);
          codeGen.wrap(hash, w.NumType.i64);
          b.i32_wrap_i64();
          b.struct_set(translator.objectInfo.struct, FieldIndex.identityHash);
          return codeGen.voidMarker;
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
          ClassInfo info = translator.topInfo;
          codeGen.wrap(node.arguments.positional.single, info.nonNullableType);
          b.struct_get(info.struct, FieldIndex.classId);
          return w.NumType.i32;
        case "makeListFixedLength":
          return _changeListClassID(node, translator.fixedLengthListClass);
        case "makeFixedListUnmodifiable":
          return _changeListClassID(node, translator.immutableListClass);
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
      // WasmArray constructors
      if (cls == translator.wasmArrayClass) {
        final dartElementType = node.arguments.types.single;
        w.ArrayType arrayType =
            translator.arrayTypeForDartType(dartElementType);
        final elementType = arrayType.elementType.type;
        final isDefaultable = elementType is! w.RefType || elementType.nullable;
        if (!isDefaultable && node.arguments.positional.length == 1) {
          throw 'The element type $dartElementType does not have a default value'
              '- please use WasmArray<$dartElementType>.filled() instead.';
        }

        Expression length = node.arguments.positional[0];
        codeGen.wrap(length, w.NumType.i64);
        b.i32_wrap_i64();
        if (node.arguments.positional.length < 2) {
          b.array_new_default(arrayType);
        } else {
          Expression initialValue = node.arguments.positional[1];
          if (initialValue is NullLiteral ||
              initialValue is ConstantExpression &&
                  initialValue.constant is NullConstant) {
            // Initialize to `null`
            b.array_new_default(arrayType);
          } else {
            // Initialize to the provided value
            w.Local lengthTemp = codeGen.addLocal(w.NumType.i32);
            b.local_set(lengthTemp);
            codeGen.wrap(initialValue, arrayType.elementType.type.unpacked);
            b.local_get(lengthTemp);
            b.array_new(arrayType);
          }
        }
        return w.RefType.def(arrayType, nullable: false);
      }

      // (WasmFuncRef|WasmFunction).fromRef constructors
      if (cls == translator.wasmFunctionClass && name == "fromFuncRef") {
        Expression ref = node.arguments.positional[0];
        w.RefType resultType = typeOfExp(node) as w.RefType;
        w.Label succeed = b.block(const [], [resultType]);
        codeGen.wrap(ref, w.RefType.func(nullable: false));
        b.br_on_cast(succeed, w.RefType.func(nullable: false), resultType);
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

      // Wasm(AnyRef|FuncRef|EqRef|StructRef|I32|I64|F32|F64) constructors
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

    // dart:_wasm static functions
    if (node.target.enclosingLibrary.name == "dart._wasm") {
      switch (name) {
        case "_externalizeNonNullable":
          final value = node.arguments.positional.single;
          codeGen.wrap(value, w.RefType.any(nullable: false));
          b.extern_externalize();
          return w.RefType.extern(nullable: false);
        case "_externalizeNullable":
          final value = node.arguments.positional.single;
          codeGen.wrap(value, w.RefType.any(nullable: true));
          b.extern_externalize();
          return w.RefType.extern(nullable: true);
        case "_internalizeNonNullable":
          final value = node.arguments.positional.single;
          codeGen.wrap(value, w.RefType.extern(nullable: false));
          b.extern_internalize();
          return w.RefType.any(nullable: false);
        case "_internalizeNullable":
          final value = node.arguments.positional.single;
          codeGen.wrap(value, w.RefType.extern(nullable: true));
          b.extern_internalize();
          return w.RefType.any(nullable: true);
        case "_wasmExternRefIsNull":
          final value = node.arguments.positional.single;
          codeGen.wrap(value, w.RefType.extern(nullable: true));
          b.ref_is_null();
          return w.NumType.i32;
      }
    }

    return null;
  }

  w.ValueType _changeListClassID(StaticInvocation node, Class newClass) {
    ClassInfo receiverInfo = translator.classInfo[translator.listBaseClass]!;
    codeGen.wrap(
        node.arguments.positional.single, receiverInfo.nonNullableType);
    w.Local receiverLocal =
        codeGen.function.addLocal(receiverInfo.nonNullableType);
    b.local_set(receiverLocal);

    ClassInfo newInfo = translator.classInfo[newClass]!;
    translator.functions.recordClassAllocation(newInfo.classId);
    b.i32_const(newInfo.classId);
    b.i32_const(initialIdentityHash);
    b.local_get(receiverLocal);
    b.struct_get(
        receiverInfo.struct,
        translator.typeParameterIndex[
            translator.listBaseClass.typeParameters.single]!);
    b.local_get(receiverLocal);
    b.struct_get(receiverInfo.struct, FieldIndex.listLength);
    b.local_get(receiverLocal);
    b.struct_get(receiverInfo.struct, FieldIndex.listArray);
    b.struct_new(newInfo.struct);
    return newInfo.nonNullableType;
  }

  /// Generate inline code for a [ConstructorInvocation] if the constructor is
  /// an inlined intrinsic.
  w.ValueType? generateConstructorIntrinsic(ConstructorInvocation node) {
    String name = node.name.text;

    // WasmArray.literal
    final klass = node.target.enclosingClass;
    if (klass == translator.wasmArrayClass && name == "literal") {
      w.ArrayType arrayType =
          translator.arrayTypeForDartType(node.arguments.types.single);
      w.ValueType elementType = arrayType.elementType.type.unpacked;
      Expression value = node.arguments.positional[0];
      List<Expression> elements = value is ListLiteral
          ? value.expressions
          : value is ConstantExpression && value.constant is ListConstant
              ? (value.constant as ListConstant)
                  .entries
                  .map(ConstantExpression.new)
                  .toList()
              : throw "WasmArray.literal argument is not a list literal"
                  " at ${value.location}";
      for (Expression element in elements) {
        codeGen.wrap(element, elementType);
      }
      b.array_new_fixed(arrayType, elements.length);
      return w.RefType.def(arrayType, nullable: false);
    }

    return null;
  }

  /// Generate inline code for a [FunctionInvocation] if the function is an
  /// inlined intrinsic.
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
      b.call_ref(functionType);
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

  /// Generate Wasm function for an intrinsic member.
  bool generateMemberIntrinsic(Reference target, w.FunctionBuilder function,
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
      // Simple redirect to `_getMasqueradedRuntimeType`. This is done to keep
      // `Object.runtimeType` external. If `Object.runtimeType` is implemented
      // in Dart, the TFA will conclude that `null.runtimeType` never returns,
      // since it dispatches to `Object.runtimeType`, which uses the receiver
      // as non-nullable.
      w.Local receiver = paramLocals[0];
      b.local_get(receiver);
      codeGen.call(translator.getMasqueradedRuntimeType.reference);
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

      // If the references are identical, return true.
      b.local_get(first);
      b.local_get(second);
      b.ref_eq();
      b.if_();
      b.i32_const(1);
      b.return_();
      b.end();

      w.Label fail = b.block();

      // If either is `null`, or their class IDs are different, return false.
      b.local_get(first);
      b.br_on_null(fail);
      b.struct_get(translator.topInfo.struct, FieldIndex.classId);
      b.local_tee(cid);
      b.local_get(second);
      b.br_on_null(fail);
      b.struct_get(translator.topInfo.struct, FieldIndex.classId);
      b.i32_ne();
      b.br_if(fail);

      // Both bool?
      b.local_get(cid);
      b.i32_const(boolInfo.classId);
      b.i32_eq();
      b.if_();
      b.local_get(first);
      b.ref_cast(boolInfo.nonNullableType);
      b.struct_get(boolInfo.struct, FieldIndex.boxValue);
      b.local_get(second);
      b.ref_cast(boolInfo.nonNullableType);
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
      b.ref_cast(intInfo.nonNullableType);
      b.struct_get(intInfo.struct, FieldIndex.boxValue);
      b.local_get(second);
      b.ref_cast(intInfo.nonNullableType);
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
      b.ref_cast(doubleInfo.nonNullableType);
      b.struct_get(doubleInfo.struct, FieldIndex.boxValue);
      b.i64_reinterpret_f64();
      b.local_get(second);
      b.ref_cast(doubleInfo.nonNullableType);
      b.struct_get(doubleInfo.struct, FieldIndex.boxValue);
      b.i64_reinterpret_f64();
      b.i64_eq();
      b.return_();
      b.end();

      // Not identical
      b.end(); // fail
      b.i32_const(0);

      return true;
    }

    // _Closure._getClosureRuntimeType
    if (member == translator.getClosureRuntimeType) {
      final w.Local object = paramLocals[0];
      w.StructType closureBase = translator.closureLayouter.closureBaseStruct;
      b.local_get(object);
      b.ref_cast(w.RefType.def(closureBase, nullable: false));
      b.struct_get(closureBase, FieldIndex.closureRuntimeType);
      return true;
    }

    if (member.enclosingLibrary == translator.coreTypes.coreLibrary &&
        name == "identityHashCode") {
      final w.Local arg = paramLocals[0];
      final w.Local nonNullArg =
          function.addLocal(translator.topInfo.nonNullableType);
      final List<int> classIds = translator.valueClasses.keys
          .map((cls) => translator.classInfo[cls]!.classId)
          .toList()
        ..sort();

      // If the argument is `null`, return the hash code of `null`.
      final w.Label notNull =
          b.block(const [], [translator.topInfo.nonNullableType]);
      b.local_get(arg);
      b.br_on_non_null(notNull);
      b.i64_const(null.hashCode);
      b.return_();
      b.end(); // notNull
      b.local_set(nonNullArg);

      // Branch on class ID.
      final w.Label defaultLabel = b.block();
      final List<w.Label> labels =
          List.generate(classIds.length, (_) => b.block());
      b.local_get(nonNullArg);
      b.struct_get(translator.topInfo.struct, FieldIndex.classId);
      int labelIndex = 0;
      final List<w.Label> targets = List.generate(classIds.last + 1, (id) {
        return id == classIds[labelIndex] ? labels[labelIndex++] : defaultLabel;
      });
      b.br_table(targets, defaultLabel);

      // For value classes, dispatch to their `hashCode` implementation.
      for (final int id in classIds.reversed) {
        final Class cls = translator.valueClasses[translator.classes[id].cls!]!;
        final Procedure hashCodeProcedure =
            cls.procedures.firstWhere((p) => p.name.text == "hashCode");
        b.end(); // Jump target for class ID
        b.local_get(nonNullArg);
        codeGen.call(hashCodeProcedure.reference);
        b.return_();
      }

      // For all other classes, dispatch to the `hashCode` implementation in
      // `Object`.
      b.end(); // defaultLabel
      b.local_get(nonNullArg);
      codeGen.call(translator.objectHashCode.reference);
      return true;
    }

    // _typeArguments
    if (name == "_typeArguments" &&
        member.enclosingClass != translator.coreTypes.objectClass) {
      Class cls = member.enclosingClass!;
      ClassInfo classInfo = translator.classInfo[cls]!;
      w.ArrayType arrayType =
          (function.type.outputs.single as w.RefType).heapType as w.ArrayType;
      w.Local object = paramLocals[0];
      w.Local preciseObject = codeGen.addLocal(classInfo.nonNullableType);
      b.local_get(object);
      b.ref_cast(classInfo.nonNullableType);
      b.local_set(preciseObject);
      for (int i = 0; i < cls.typeParameters.length; i++) {
        TypeParameter typeParameter = cls.typeParameters[i];
        int typeParameterIndex = translator.typeParameterIndex[typeParameter]!;
        b.local_get(preciseObject);
        b.struct_get(classInfo.struct, typeParameterIndex);
      }
      b.array_new_fixed(arrayType, cls.typeParameters.length);
      return true;
    }

    // int members
    if (member.enclosingClass == translator.boxedIntClass &&
        member.function.body == null) {
      String op = member.name.text;
      if (functionNode.requiredParameterCount == 0) {
        CodeGenCallback? code = _unaryOperatorMap[intType]![op];
        if (code != null) {
          w.ValueType resultType = _unaryResultMap[op] ?? intType;
          w.ValueType inputType = function.type.inputs.single;
          w.ValueType outputType = function.type.outputs.single;
          b.local_get(function.locals[0]);
          translator.convertType(function, inputType, intType);
          code(codeGen);
          translator.convertType(function, resultType, outputType);
          return true;
        }
      } else if (functionNode.requiredParameterCount == 1) {
        CodeGenCallback? code = _binaryOperatorMap[intType]![intType]![op];
        if (code != null) {
          w.ValueType leftType = function.type.inputs[0];
          w.ValueType rightType = function.type.inputs[1];
          w.ValueType outputType = function.type.outputs.single;
          if (rightType == intType) {
            // int parameter
            b.local_get(function.locals[0]);
            translator.convertType(function, leftType, intType);
            b.local_get(function.locals[1]);
            code(codeGen);
            if (!isComparison(op)) {
              translator.convertType(function, intType, outputType);
            }
            return true;
          }
          // num parameter
          ClassInfo intInfo = translator.classInfo[translator.boxedIntClass]!;
          w.Label intArg = b.block(const [], [intInfo.nonNullableType]);
          b.local_get(function.locals[1]);
          b.br_on_cast(intArg, function.locals[1].type as w.RefType,
              intInfo.nonNullableType);
          // double argument
          b.drop();
          b.local_get(function.locals[0]);
          translator.convertType(function, leftType, intType);
          b.f64_convert_i64_s();
          b.local_get(function.locals[1]);
          translator.convertType(function, rightType, doubleType);
          // Inline double op
          CodeGenCallback doubleCode =
              _binaryOperatorMap[doubleType]![doubleType]![op]!;
          doubleCode(codeGen);
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
          code(codeGen);
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
        CodeGenCallback? code = _unaryOperatorMap[doubleType]![op];
        if (code != null) {
          w.ValueType resultType = _unaryResultMap[op] ?? doubleType;
          w.ValueType inputType = function.type.inputs.single;
          w.ValueType outputType = function.type.outputs.single;
          b.local_get(function.locals[0]);
          translator.convertType(function, inputType, doubleType);
          code(codeGen);
          translator.convertType(function, resultType, outputType);
          return true;
        }
      }
    }

    if (member.enclosingClass == translator.closureClass &&
        name == "_isInstantiationClosure") {
      assert(function.locals.length == 1);
      b.local_get(function.locals[0]); // ref _Closure
      b.emitInstantiationClosureCheck(translator);
      return true;
    }

    if (member.enclosingClass == translator.closureClass &&
        name == "_instantiatedClosure") {
      assert(function.locals.length == 1);
      b.local_get(function.locals[0]); // ref _Closure
      b.emitGetInstantiatedClosure(translator);
      return true;
    }

    if (member.enclosingClass == translator.closureClass &&
        name == "_instantiationClosureTypeHash") {
      assert(function.locals.length == 1);

      // Instantiation context, to be passed to the hash function.
      b.local_get(function.locals[0]); // ref _Closure
      b.ref_cast(w.RefType(translator.closureLayouter.closureBaseStruct,
          nullable: false));
      b.struct_get(translator.closureLayouter.closureBaseStruct,
          FieldIndex.closureContext);
      b.ref_cast(w.RefType(
          translator.closureLayouter.instantiationContextBaseStruct,
          nullable: false));

      // Hash function.
      b.local_get(function.locals[0]); // ref _Closure
      b.emitGetInstantiatedClosure(translator);
      b.emitGetClosureVtable(translator);
      b.ref_cast(w.RefType.def(
          translator.closureLayouter.genericVtableBaseStruct,
          nullable: false));
      b.struct_get(translator.closureLayouter.genericVtableBaseStruct,
          FieldIndex.vtableInstantiationTypeHashFunction);
      b.call_ref(
          translator.closureLayouter.instantiationClosureTypeHashFunctionType);

      return true;
    }

    if (member.enclosingClass == translator.closureClass &&
        name == "_instantiationClosureTypeEquals") {
      assert(function.locals.length == 2);

      final w.StructType closureBaseStruct =
          translator.closureLayouter.closureBaseStruct;

      final w.RefType instantiationContextBase = w.RefType(
          translator.closureLayouter.instantiationContextBaseStruct,
          nullable: false);

      b.local_get(function.locals[0]); // ref _Closure
      b.ref_cast(w.RefType(closureBaseStruct, nullable: false));
      b.struct_get(closureBaseStruct, FieldIndex.closureContext);
      b.ref_cast(instantiationContextBase);

      b.local_get(function.locals[1]); // ref _Closure
      b.ref_cast(w.RefType(closureBaseStruct, nullable: false));
      b.struct_get(closureBaseStruct, FieldIndex.closureContext);
      b.ref_cast(instantiationContextBase);

      b.local_get(function.locals[0]);
      b.emitGetInstantiatedClosure(translator);
      b.emitGetClosureVtable(translator);
      b.ref_cast(w.RefType.def(
          translator.closureLayouter.genericVtableBaseStruct,
          nullable: false));
      b.struct_get(translator.closureLayouter.genericVtableBaseStruct,
          FieldIndex.vtableInstantiationTypeComparisonFunction);

      b.call_ref(translator
          .closureLayouter.instantiationClosureTypeComparisonFunctionType);

      return true;
    }

    if (member.enclosingClass == translator.closureClass &&
        name == "_isInstanceTearOff") {
      assert(function.locals.length == 1);
      b.local_get(function.locals[0]); // ref _Closure
      b.emitTearOffCheck(translator);
      return true;
    }

    if (member.enclosingClass == translator.closureClass &&
        name == "_instanceTearOffReceiver") {
      assert(function.locals.length == 1);
      b.local_get(function.locals[0]); // ref _Closure
      b.emitGetTearOffReceiver(translator);
      return true;
    }

    if (member.enclosingClass == translator.closureClass && name == "_vtable") {
      assert(function.locals.length == 1);
      b.local_get(function.locals[0]); // ref _Closure
      b.emitGetClosureVtable(translator);
      return true;
    }

    if (member.enclosingClass == translator.coreTypes.functionClass &&
        name == "apply") {
      assert(function.type.inputs.length == 3);

      final closureLocal = function.locals[0]; // ref #ClosureBase
      final posArgsNullableLocal = function.locals[1]; // ref null Object
      final namedArgsLocal = function.locals[2]; // ref null Object

      // Create empty type arguments array.
      final typeArgsLocal = function.addLocal(translator.makeArray(function,
          translator.typeArrayType, 0, (elementType, elementIndex) {}));
      b.local_set(typeArgsLocal);

      // Create empty list for positional args if the argument is null
      final posArgsLocal =
          function.addLocal(translator.nullableObjectArrayTypeRef);
      b.local_get(posArgsNullableLocal);
      b.ref_is_null();

      b.if_([], [translator.nullableObjectArrayTypeRef]);
      translator.makeArray(
          function, translator.nullableObjectArrayType, 0, (_, __) {});

      b.else_();
      // List argument may be a custom list type, convert it to `WasmListBase`
      // with `WasmListBase.of`.
      translator.constants.instantiateConstant(
        function,
        b,
        TypeLiteralConstant(DynamicType()),
        translator.types.nonNullableTypeType,
      );
      b.local_get(posArgsNullableLocal);
      b.ref_as_non_null();
      codeGen.call(translator.listOf.reference);
      translator.getListBaseArray(b);
      b.end();
      b.local_set(posArgsLocal);

      // Convert named argument map to list, to be passed to shape and type
      // checkers and the dynamic call entry.
      final namedArgsListLocal =
          function.addLocal(translator.nullableObjectArrayTypeRef);
      b.local_get(namedArgsLocal);
      codeGen.call(translator.namedParameterMapToArray.reference);
      b.local_set(namedArgsListLocal);

      final noSuchMethodBlock = b.block();

      generateDynamicFunctionCall(translator, function, closureLocal,
          typeArgsLocal, posArgsLocal, namedArgsListLocal, noSuchMethodBlock);
      b.return_();

      b.end(); // noSuchMethodBlock

      generateNoSuchMethodCall(
          translator,
          function,
          () => b.local_get(closureLocal),
          () => createInvocationObject(translator, function, "call",
              typeArgsLocal, posArgsLocal, namedArgsListLocal));

      return true;
    }

    // Error._throw
    if (member.enclosingClass == translator.errorClass && name == "_throw") {
      final objectLocal = function.locals[0]; // ref #Top
      final stackTraceLocal = function.locals[1]; // ref Object

      final notErrorBlock = b.block([], [objectLocal.type]);

      final errorClassInfo = translator.classInfo[translator.errorClass]!;
      final errorRefType = errorClassInfo.nonNullableType;
      final stackTraceFieldIndex =
          translator.fieldIndex[translator.errorClassStackTraceField]!;
      b.local_get(objectLocal);
      b.br_on_cast_fail(
          notErrorBlock, objectLocal.type as w.RefType, errorRefType);

      final errorLocal = function.addLocal(errorRefType);
      b.local_tee(errorLocal);

      b.struct_get(errorClassInfo.struct, stackTraceFieldIndex);
      b.ref_is_null();
      b.if_();
      b.local_get(errorLocal);
      b.local_get(stackTraceLocal);
      b.struct_set(errorClassInfo.struct, stackTraceFieldIndex);
      b.end();

      b.local_get(objectLocal);
      b.end(); // notErrorBlock

      b.local_get(stackTraceLocal);
      b.throw_(translator.exceptionTag);

      return true;
    }

    if (member.enclosingClass == translator.wasmExternRefClass &&
        name == "nullRef") {
      b.ref_null(w.HeapType.noextern);
      return true;
    }

    return false;
  }
}
