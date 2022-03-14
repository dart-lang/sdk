// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:dart2wasm/class_info.dart';
import 'package:dart2wasm/translator.dart';

import 'package:kernel/ast.dart';
import 'package:kernel/type_algebra.dart' show substitute;

import 'package:wasm_builder/wasm_builder.dart' as w;

class ConstantInfo {
  final Constant constant;
  final w.DefinedGlobal global;
  final w.DefinedFunction? function;

  ConstantInfo(this.constant, this.global, this.function);
}

typedef ConstantCodeGenerator = void Function(
    w.DefinedFunction?, w.Instructions);

/// Handles the creation of Dart constants. Can operate in two modes - eager and
/// lazy - controlled by [TranslatorOptions.lazyConstants].
///
/// Each (non-trivial) constant is assigned to a Wasm global. Multiple
/// occurrences of the same constant use the same global.
///
/// In eager mode, the constant is contained within the global initializer,
/// meaning all constants are initialized eagerly during module initialization.
/// In lazy mode, the global starts out uninitialized, and every use of the
/// constant checks the global to see if it has been initialized and calls an
/// initialization function otherwise.
class Constants {
  final Translator translator;
  final Map<Constant, ConstantInfo> constantInfo = {};
  final StringBuffer oneByteStrings = StringBuffer();
  final StringBuffer twoByteStrings = StringBuffer();
  late final w.DefinedFunction oneByteStringFunction;
  late final w.DefinedFunction twoByteStringFunction;
  late final w.DataSegment oneByteStringSegment;
  late final w.DataSegment twoByteStringSegment;
  late final w.DefinedGlobal emptyString;
  late final w.DefinedGlobal emptyTypeList;
  late final ClassInfo typeInfo = translator.classInfo[translator.typeClass]!;

  bool currentlyCreating = false;

  Constants(this.translator) {
    if (lazyConstants) {
      oneByteStringFunction = makeStringFunction(translator.oneByteStringClass);
      twoByteStringFunction = makeStringFunction(translator.twoByteStringClass);
    } else if (stringDataSegments) {
      oneByteStringSegment = m.addDataSegment();
      twoByteStringSegment = m.addDataSegment();
    }
    initEmptyString();
    initEmptyTypeList();
  }

  w.Module get m => translator.m;
  bool get lazyConstants => translator.options.lazyConstants;
  bool get stringDataSegments => translator.options.stringDataSegments;

  void initEmptyString() {
    ClassInfo info = translator.classInfo[translator.oneByteStringClass]!;
    translator.functions.allocateClass(info.classId);
    w.ArrayType arrayType =
        (info.struct.fields.last.type as w.RefType).heapType as w.ArrayType;

    if (lazyConstants) {
      w.RefType emptyStringType = info.nullableType;
      emptyString = m.addGlobal(w.GlobalType(emptyStringType));
      emptyString.initializer.ref_null(emptyStringType.heapType);
      emptyString.initializer.end();

      w.Instructions b = translator.initFunction.body;
      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);
      b.i32_const(0);
      translator.array_new_default(b, arrayType);
      translator.struct_new(b, info);
      b.global_set(emptyString);
    } else {
      w.RefType emptyStringType = info.nonNullableType;
      emptyString = m.addGlobal(w.GlobalType(emptyStringType, mutable: false));
      w.Instructions ib = emptyString.initializer;
      ib.i32_const(info.classId);
      ib.i32_const(initialIdentityHash);
      translator.array_init(ib, arrayType, 0);
      translator.struct_new(ib, info);
      ib.end();
    }

    Constant emptyStringConstant = StringConstant("");
    constantInfo[emptyStringConstant] =
        ConstantInfo(emptyStringConstant, emptyString, null);
  }

  void initEmptyTypeList() {
    ClassInfo info = translator.classInfo[translator.immutableListClass]!;
    translator.functions.allocateClass(info.classId);
    w.RefType refType = info.struct.fields.last.type.unpacked as w.RefType;
    w.ArrayType arrayType = refType.heapType as w.ArrayType;

    // Create the empty type list with its type parameter uninitialized for now.
    if (lazyConstants) {
      w.RefType emptyListType = info.nullableType;
      emptyTypeList = m.addGlobal(w.GlobalType(emptyListType));
      emptyTypeList.initializer.ref_null(emptyListType.heapType);
      emptyTypeList.initializer.end();

      w.Instructions b = translator.initFunction.body;
      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);
      b.ref_null(typeInfo.struct); // Initialized later
      b.i64_const(0);
      b.i32_const(0);
      translator.array_new_default(b, arrayType);
      translator.struct_new(b, info);
      b.global_set(emptyTypeList);
    } else {
      w.RefType emptyListType = info.nonNullableType;
      emptyTypeList = m.addGlobal(w.GlobalType(emptyListType, mutable: false));
      w.Instructions ib = emptyTypeList.initializer;
      ib.i32_const(info.classId);
      ib.i32_const(initialIdentityHash);
      ib.ref_null(typeInfo.struct); // Initialized later
      ib.i64_const(0);
      translator.array_init(ib, arrayType, 0);
      translator.struct_new(ib, info);
      ib.end();
    }

    Constant emptyTypeListConstant = ListConstant(
        InterfaceType(translator.typeClass, Nullability.nonNullable), const []);
    constantInfo[emptyTypeListConstant] =
        ConstantInfo(emptyTypeListConstant, emptyTypeList, null);

    // Initialize the type parameter of the empty type list to the type object
    // for _Type, which itself refers to the empty type list.
    w.Instructions b = translator.initFunction.body;
    b.global_get(emptyTypeList);
    instantiateConstant(
        translator.initFunction,
        b,
        TypeLiteralConstant(
            InterfaceType(translator.typeClass, Nullability.nonNullable)),
        typeInfo.nullableType);
    b.struct_set(info.struct,
        translator.typeParameterIndex[info.cls!.typeParameters.single]!);
  }

  void finalize() {
    if (lazyConstants) {
      finalizeStrings();
    }
  }

  void finalizeStrings() {
    Uint8List oneByteStringsAsBytes =
        Uint8List.fromList(oneByteStrings.toString().codeUnits);
    assert(Endian.host == Endian.little);
    Uint8List twoByteStringsAsBytes =
        Uint16List.fromList(twoByteStrings.toString().codeUnits)
            .buffer
            .asUint8List();
    Uint8List stringsAsBytes = (BytesBuilder()
          ..add(twoByteStringsAsBytes)
          ..add(oneByteStringsAsBytes))
        .toBytes();

    w.Memory stringMemory =
        m.addMemory(stringsAsBytes.length, stringsAsBytes.length);
    m.addDataSegment(stringsAsBytes, stringMemory, 0);
    makeStringFunctionBody(translator.oneByteStringClass, oneByteStringFunction,
        (b) {
      b.i32_load8_u(stringMemory, twoByteStringsAsBytes.length);
    });
    makeStringFunctionBody(translator.twoByteStringClass, twoByteStringFunction,
        (b) {
      b.i32_const(1);
      b.i32_shl();
      b.i32_load16_u(stringMemory, 0);
    });
  }

  /// Create one of the two Wasm functions (one for each string type) called
  /// from every lazily initialized string constant (of that type) to create and
  /// initialize the string.
  ///
  /// The function signature is (i32 offset, i32 length) -> (ref stringClass)
  /// where offset and length are measured in characters and indicate the place
  /// in the corresponding string data segment from which to copy this string.
  w.DefinedFunction makeStringFunction(Class cls) {
    ClassInfo info = translator.classInfo[cls]!;
    w.FunctionType ftype = translator.functionType(
        const [w.NumType.i32, w.NumType.i32], [info.nonNullableType]);
    return m.addFunction(ftype, "makeString (${cls.name})");
  }

  void makeStringFunctionBody(Class cls, w.DefinedFunction function,
      void Function(w.Instructions) emitLoad) {
    ClassInfo info = translator.classInfo[cls]!;
    w.ArrayType arrayType =
        (info.struct.fields.last.type as w.RefType).heapType as w.ArrayType;

    w.Local offset = function.locals[0];
    w.Local length = function.locals[1];
    w.Local array = function.addLocal(
        translator.typeForLocal(w.RefType.def(arrayType, nullable: false)));
    w.Local index = function.addLocal(w.NumType.i32);

    w.Instructions b = function.body;
    b.local_get(length);
    translator.array_new_default(b, arrayType);
    b.local_set(array);

    b.i32_const(0);
    b.local_set(index);
    w.Label loop = b.loop();
    b.local_get(array);
    b.local_get(index);
    b.local_get(offset);
    b.local_get(index);
    b.i32_add();
    emitLoad(b);
    b.array_set(arrayType);
    b.local_get(index);
    b.i32_const(1);
    b.i32_add();
    b.local_tee(index);
    b.local_get(length);
    b.i32_lt_u();
    b.br_if(loop);
    b.end();

    b.i32_const(info.classId);
    b.i32_const(initialIdentityHash);
    b.local_get(array);
    translator.struct_new(b, info);
    b.end();
  }

  /// Ensure that the constant has a Wasm global assigned.
  ///
  /// In eager mode, sub-constants must have Wasm globals assigned before the
  /// global for the composite constant is assigned, since global initializers
  /// can only refer to earlier globals.
  void ensureConstant(Constant constant) {
    ConstantCreator(this).ensureConstant(constant);
  }

  /// Emit code to push a constant onto the stack.
  void instantiateConstant(w.DefinedFunction? function, w.Instructions b,
      Constant constant, w.ValueType expectedType) {
    if (expectedType == translator.voidMarker) return;
    ConstantInstantiator(this, function, b, expectedType).instantiate(constant);
  }
}

class ConstantInstantiator extends ConstantVisitor<w.ValueType> {
  final Constants constants;
  final w.DefinedFunction? function;
  final w.Instructions b;
  final w.ValueType expectedType;

  ConstantInstantiator(
      this.constants, this.function, this.b, this.expectedType);

  Translator get translator => constants.translator;
  w.Module get m => translator.m;

  void instantiate(Constant constant) {
    w.ValueType resultType = constant.accept(this);
    assert(!translator.needsConversion(resultType, expectedType),
        "For $constant: expected $expectedType, got $resultType");
  }

  @override
  w.ValueType defaultConstant(Constant constant) {
    ConstantInfo info = ConstantCreator(constants).ensureConstant(constant)!;
    w.ValueType globalType = info.global.type.type;
    if (globalType.nullable) {
      if (info.function != null) {
        // Lazily initialized constant.
        w.Label done = b.block(const [], [globalType.withNullability(false)]);
        b.global_get(info.global);
        b.br_on_non_null(done);
        b.call(info.function!);
        b.end();
      } else {
        // Constant initialized in the module init function.
        b.global_get(info.global);
        b.ref_as_non_null();
      }
      return globalType.withNullability(false);
    } else {
      // Constant initialized eagerly in a global initializer.
      b.global_get(info.global);
      return globalType;
    }
  }

  @override
  w.ValueType visitNullConstant(NullConstant node) {
    w.ValueType? expectedType = this.expectedType;
    if (expectedType != translator.voidMarker) {
      if (expectedType.nullable) {
        w.HeapType heapType =
            expectedType is w.RefType ? expectedType.heapType : w.HeapType.data;
        b.ref_null(heapType);
      } else {
        // This only happens in invalid but unreachable code produced by the
        // TFA dead-code elimination.
        b.comment("Non-nullable null constant");
        b.block(const [], [expectedType]);
        b.unreachable();
        b.end();
      }
    }
    return expectedType;
  }

  w.ValueType _maybeBox(w.ValueType wasmType, void Function() pushValue) {
    if (expectedType is w.RefType) {
      ClassInfo info = translator.classInfo[translator.boxedClasses[wasmType]]!;
      b.i32_const(info.classId);
      pushValue();
      translator.struct_new(b, info);
      return info.nonNullableType;
    } else {
      pushValue();
      return wasmType;
    }
  }

  @override
  w.ValueType visitBoolConstant(BoolConstant constant) {
    return _maybeBox(w.NumType.i32, () {
      b.i32_const(constant.value ? 1 : 0);
    });
  }

  @override
  w.ValueType visitIntConstant(IntConstant constant) {
    return _maybeBox(w.NumType.i64, () {
      b.i64_const(constant.value);
    });
  }

  @override
  w.ValueType visitDoubleConstant(DoubleConstant constant) {
    return _maybeBox(w.NumType.f64, () {
      b.f64_const(constant.value);
    });
  }
}

class ConstantCreator extends ConstantVisitor<ConstantInfo?> {
  final Constants constants;

  ConstantCreator(this.constants);

  Translator get translator => constants.translator;
  w.Module get m => constants.m;
  bool get lazyConstants => constants.lazyConstants;

  ConstantInfo? ensureConstant(Constant constant) {
    ConstantInfo? info = constants.constantInfo[constant];
    if (info == null) {
      info = constant.accept(this);
      if (info != null) {
        constants.constantInfo[constant] = info;
      }
    }
    return info;
  }

  ConstantInfo createConstant(
      Constant constant, w.RefType type, ConstantCodeGenerator generator) {
    assert(!type.nullable);
    if (lazyConstants) {
      // Create uninitialized global and function to initialize it.
      w.DefinedGlobal global =
          m.addGlobal(w.GlobalType(type.withNullability(true)));
      global.initializer.ref_null(type.heapType);
      global.initializer.end();
      w.FunctionType ftype = translator.functionType(const [], [type]);
      w.DefinedFunction function = m.addFunction(ftype, "$constant");
      generator(function, function.body);
      w.Local temp = function.addLocal(translator.typeForLocal(type));
      w.Instructions b2 = function.body;
      b2.local_tee(temp);
      b2.global_set(global);
      b2.local_get(temp);
      translator.convertType(function, temp.type, type);
      b2.end();

      return ConstantInfo(constant, global, function);
    } else {
      // Create global with the constant in its initializer.
      assert(!constants.currentlyCreating);
      constants.currentlyCreating = true;
      w.DefinedGlobal global = m.addGlobal(w.GlobalType(type, mutable: false));
      generator(null, global.initializer);
      global.initializer.end();
      constants.currentlyCreating = false;

      return ConstantInfo(constant, global, null);
    }
  }

  @override
  ConstantInfo? defaultConstant(Constant constant) => null;

  @override
  ConstantInfo? visitStringConstant(StringConstant constant) {
    bool isOneByte = constant.value.codeUnits.every((c) => c <= 255);
    ClassInfo info = translator.classInfo[isOneByte
        ? translator.oneByteStringClass
        : translator.twoByteStringClass]!;
    translator.functions.allocateClass(info.classId);
    w.RefType type = info.nonNullableType;
    return createConstant(constant, type, (function, b) {
      if (lazyConstants) {
        // Copy string contents from linear memory on initialization. The memory
        // is initialized by an active data segment for each string type.
        StringBuffer buffer =
            isOneByte ? constants.oneByteStrings : constants.twoByteStrings;
        int offset = buffer.length;
        int length = constant.value.length;
        buffer.write(constant.value);

        b.i32_const(offset);
        b.i32_const(length);
        b.call(isOneByte
            ? constants.oneByteStringFunction
            : constants.twoByteStringFunction);
      } else {
        w.ArrayType arrayType =
            (info.struct.fields.last.type as w.RefType).heapType as w.ArrayType;

        b.i32_const(info.classId);
        b.i32_const(initialIdentityHash);
        if (constants.stringDataSegments) {
          // Initialize string contents from passive data segment.
          w.DataSegment segment;
          Uint8List bytes;
          if (isOneByte) {
            segment = constants.oneByteStringSegment;
            bytes = Uint8List.fromList(constant.value.codeUnits);
          } else {
            assert(Endian.host == Endian.little);
            segment = constants.twoByteStringSegment;
            bytes = Uint16List.fromList(constant.value.codeUnits)
                .buffer
                .asUint8List();
          }
          int offset = segment.length;
          segment.append(bytes);
          b.i32_const(offset);
          b.i32_const(constant.value.length);
          translator.array_init_from_data(b, arrayType, segment);
        } else {
          // Initialize string contents from i32 constants on the stack.
          for (int charCode in constant.value.codeUnits) {
            b.i32_const(charCode);
          }
          translator.array_init(b, arrayType, constant.value.length);
        }
        translator.struct_new(b, info);
      }
    });
  }

  @override
  ConstantInfo? visitInstanceConstant(InstanceConstant constant) {
    Class cls = constant.classNode;
    ClassInfo info = translator.classInfo[cls]!;
    translator.functions.allocateClass(info.classId);
    w.RefType type = info.nonNullableType;

    // Collect sub-constants for field values.
    const int baseFieldCount = 2;
    int fieldCount = info.struct.fields.length;
    List<Constant?> subConstants = List.filled(fieldCount, null);
    constant.fieldValues.forEach((reference, subConstant) {
      int index = translator.fieldIndex[reference.asField]!;
      assert(subConstants[index] == null);
      subConstants[index] = subConstant;
      ensureConstant(subConstant);
    });

    // Collect sub-constants for type arguments.
    Map<TypeParameter, DartType> substitution = {};
    List<DartType> args = constant.typeArguments;
    while (true) {
      for (int i = 0; i < cls.typeParameters.length; i++) {
        TypeParameter parameter = cls.typeParameters[i];
        DartType arg = substitute(args[i], substitution);
        substitution[parameter] = arg;
        int index = translator.typeParameterIndex[parameter]!;
        Constant typeArgConstant = TypeLiteralConstant(arg);
        subConstants[index] = typeArgConstant;
        ensureConstant(typeArgConstant);
      }
      Supertype? supertype = cls.supertype;
      if (supertype == null) break;
      cls = supertype.classNode;
      args = supertype.typeArguments;
    }

    return createConstant(constant, type, (function, b) {
      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);
      for (int i = baseFieldCount; i < fieldCount; i++) {
        Constant subConstant = subConstants[i]!;
        constants.instantiateConstant(
            function, b, subConstant, info.struct.fields[i].type.unpacked);
      }
      translator.struct_new(b, info);
    });
  }

  @override
  ConstantInfo? visitListConstant(ListConstant constant) {
    Constant typeArgConstant = TypeLiteralConstant(constant.typeArgument);
    ensureConstant(typeArgConstant);
    for (Constant subConstant in constant.entries) {
      ensureConstant(subConstant);
    }

    ClassInfo info = translator.classInfo[translator.immutableListClass]!;
    translator.functions.allocateClass(info.classId);
    w.RefType type = info.nonNullableType;
    return createConstant(constant, type, (function, b) {
      w.RefType refType = info.struct.fields.last.type.unpacked as w.RefType;
      w.ArrayType arrayType = refType.heapType as w.ArrayType;
      w.ValueType elementType = arrayType.elementType.type.unpacked;
      int length = constant.entries.length;
      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);
      constants.instantiateConstant(
          function, b, typeArgConstant, constants.typeInfo.nullableType);
      b.i64_const(length);
      if (lazyConstants) {
        // Allocate array and set each entry to the corresponding sub-constant.
        w.Local arrayLocal = function!.addLocal(
            refType.withNullability(!translator.options.localNullability));
        b.i32_const(length);
        translator.array_new_default(b, arrayType);
        b.local_set(arrayLocal);
        for (int i = 0; i < length; i++) {
          b.local_get(arrayLocal);
          b.i32_const(i);
          constants.instantiateConstant(
              function, b, constant.entries[i], elementType);
          b.array_set(arrayType);
        }
        b.local_get(arrayLocal);
        if (arrayLocal.type.nullable) {
          b.ref_as_non_null();
        }
      } else {
        // Push all sub-constants on the stack and initialize array from them.
        for (int i = 0; i < length; i++) {
          constants.instantiateConstant(
              function, b, constant.entries[i], elementType);
        }
        translator.array_init(b, arrayType, length);
      }
      translator.struct_new(b, info);
    });
  }

  @override
  ConstantInfo? visitStaticTearOffConstant(StaticTearOffConstant constant) {
    w.DefinedFunction closureFunction =
        translator.getTearOffFunction(constant.targetReference.asProcedure);
    int parameterCount = closureFunction.type.inputs.length - 1;
    w.StructType struct = translator.closureStructType(parameterCount);
    w.RefType type = w.RefType.def(struct, nullable: false);
    return createConstant(constant, type, (function, b) {
      ClassInfo info = translator.classInfo[translator.functionClass]!;
      translator.functions.allocateClass(info.classId);

      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);
      b.global_get(translator.globals.dummyGlobal); // Dummy context
      if (lazyConstants) {
        w.DefinedGlobal global = translator.makeFunctionRef(closureFunction);
        b.global_get(global);
      } else {
        b.ref_func(closureFunction);
      }
      translator.struct_new(b, parameterCount);
    });
  }

  @override
  ConstantInfo? visitTypeLiteralConstant(TypeLiteralConstant constant) {
    DartType cType = constant.type;
    assert(cType is! TypeParameterType);
    DartType type = cType is DynamicType ||
            cType is VoidType ||
            cType is NeverType ||
            cType is NullType
        ? translator.coreTypes.objectRawType(Nullability.nullable)
        : cType is FunctionType
            ? InterfaceType(translator.functionClass, cType.declaredNullability)
            : cType;
    if (type is! InterfaceType) throw "Not implemented: $constant";

    ListConstant typeArgs = ListConstant(
        InterfaceType(translator.typeClass, Nullability.nonNullable),
        type.typeArguments.map((t) => TypeLiteralConstant(t)).toList());
    ensureConstant(typeArgs);

    ClassInfo info = constants.typeInfo;
    translator.functions.allocateClass(info.classId);
    return createConstant(constant, info.nonNullableType, (function, b) {
      ClassInfo typeInfo = translator.classInfo[type.classNode]!;
      w.ValueType typeListExpectedType = info.struct.fields[3].type.unpacked;

      b.i32_const(info.classId);
      b.i32_const(initialIdentityHash);
      b.i64_const(typeInfo.classId);
      constants.instantiateConstant(
          function, b, typeArgs, typeListExpectedType);
      translator.struct_new(b, info);
    });
  }
}
