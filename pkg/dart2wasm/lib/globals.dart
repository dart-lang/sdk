// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import 'package:wasm_builder/wasm_builder.dart' as w;

import 'package:dart2wasm/translator.dart';

/// Handles lazy initialization of static fields.
class Globals {
  final Translator translator;

  final Map<Field, w.Global> _globals = {};
  final Map<Field, w.BaseFunction> _globalInitializers = {};
  final Map<Field, w.Global> _globalInitializedFlag = {};
  final Map<w.FunctionType, w.BaseFunction> _dummyFunctions = {};
  final Map<w.HeapType, w.Global> _dummyValues = {};
  late final w.Global dummyStructGlobal;

  w.ModuleBuilder get m => translator.m;

  Globals(this.translator) {
    _initDummyValues();
  }

  void _initDummyValues() {
    // Create dummy struct for anyref/eqref/structref dummy values
    w.StructType structType = m.types.defineStruct("#DummyStruct");
    final dummyStructGlobalInit = m.globals.define(
        w.GlobalType(w.RefType.struct(nullable: false), mutable: false));
    final ib = dummyStructGlobalInit.initializer;
    ib.struct_new(structType);
    ib.end();
    _dummyValues[w.HeapType.any] = dummyStructGlobalInit;
    _dummyValues[w.HeapType.eq] = dummyStructGlobalInit;
    _dummyValues[w.HeapType.struct] = dummyStructGlobalInit;
    dummyStructGlobal = dummyStructGlobalInit;
  }

  /// Provide a dummy function with the given signature. Used for empty entries
  /// in vtables and for dummy values of function reference type.
  w.BaseFunction getDummyFunction(w.FunctionType type) {
    return _dummyFunctions.putIfAbsent(type, () {
      final function = m.functions.define(type, "#dummy function $type");
      final b = function.body;
      b.unreachable();
      b.end();
      return function;
    });
  }

  /// Returns whether the given function was provided by [getDummyFunction].
  bool isDummyFunction(w.BaseFunction function) {
    return _dummyFunctions[function.type] == function;
  }

  w.Global? _prepareDummyValue(w.ValueType type) {
    if (type is w.RefType && !type.nullable) {
      w.HeapType heapType = type.heapType;
      w.Global? foundGlobal = _dummyValues[heapType];
      if (foundGlobal != null) return foundGlobal;
      w.GlobalBuilder? global;
      if (heapType is w.DefType) {
        if (heapType is w.StructType) {
          for (w.FieldType field in heapType.fields) {
            _prepareDummyValue(field.type.unpacked);
          }
          global = m.globals.define(w.GlobalType(type, mutable: false));
          final ib = global.initializer;
          for (w.FieldType field in heapType.fields) {
            instantiateDummyValue(ib, field.type.unpacked);
          }
          ib.struct_new(heapType);
          ib.end();
        } else if (heapType is w.ArrayType) {
          global = m.globals.define(w.GlobalType(type, mutable: false));
          final ib = global.initializer;
          ib.array_new_fixed(heapType, 0);
          ib.end();
        } else if (heapType is w.FunctionType) {
          global = m.globals.define(w.GlobalType(type, mutable: false));
          final ib = global.initializer;
          ib.ref_func(getDummyFunction(heapType));
          ib.end();
        }
        _dummyValues[heapType] = global!;
      }
      return global;
    }

    return null;
  }

  /// Produce a dummy value of any Wasm type. For non-nullable reference types,
  /// the value is constructed in a global initializer, and the instantiation
  /// of the value merely reads the global.
  void instantiateDummyValue(w.InstructionsBuilder b, w.ValueType type) {
    switch (type) {
      case w.NumType.i32:
        b.i32_const(0);
        break;
      case w.NumType.i64:
        b.i64_const(0);
        break;
      case w.NumType.f32:
        b.f32_const(0);
        break;
      case w.NumType.f64:
        b.f64_const(0);
        break;
      default:
        if (type is w.RefType) {
          w.HeapType heapType = type.heapType;
          if (type.nullable) {
            b.ref_null(heapType.bottomType);
          } else {
            b.global_get(_prepareDummyValue(type)!);
          }
        } else {
          throw "Unsupported global type ${type} ($type)";
        }
        break;
    }
  }

  Constant? _getConstantInitializer(Field variable) {
    Expression? init = variable.initializer;
    if (init == null || init is NullLiteral) return NullConstant();
    if (init is IntLiteral) return IntConstant(init.value);
    if (init is DoubleLiteral) return DoubleConstant(init.value);
    if (init is BoolLiteral) return BoolConstant(init.value);
    if (init is StringLiteral) return StringConstant(init.value);
    if (init is ConstantExpression) return init.constant;
    return null;
  }

  /// Return (and if needed create) the Wasm global corresponding to a static
  /// field.
  w.Global getGlobal(Field variable) {
    assert(!variable.isLate);
    return _globals.putIfAbsent(variable, () {
      w.ValueType type = translator.translateType(variable.type);
      Constant? init = _getConstantInitializer(variable);
      if (init != null &&
          !(translator.constants.ensureConstant(init)?.isLazy ?? false)) {
        // Initialized to a constant
        final global =
            m.globals.define(w.GlobalType(type, mutable: !variable.isFinal));
        translator.constants
            .instantiateConstant(null, global.initializer, init, type);
        global.initializer.end();
        return global;
      } else {
        if (type is w.RefType && !type.nullable) {
          // Null signals uninitialized
          type = type.withNullability(true);
        } else {
          // Explicit initialization flag
          final flag = m.globals.define(w.GlobalType(w.NumType.i32));
          flag.initializer.i32_const(0);
          flag.initializer.end();
          _globalInitializedFlag[variable] = flag;
        }

        final global = m.globals.define(w.GlobalType(type));
        instantiateDummyValue(global.initializer, type);
        global.initializer.end();

        _globalInitializers[variable] =
            translator.functions.getFunction(variable.fieldReference);
        return global;
      }
    });
  }

  /// Return the Wasm global containing the flag indicating whether this static
  /// field has been initialized, if such a flag global is needed.
  ///
  /// Note that [getGlobal] must have been called for the field beforehand.
  w.Global? getGlobalInitializedFlag(Field variable) {
    return _globalInitializedFlag[variable];
  }

  /// Emit code to read a static field.
  w.ValueType readGlobal(w.InstructionsBuilder b, Field variable) {
    w.Global global = getGlobal(variable);
    w.BaseFunction? initFunction = _globalInitializers[variable];
    if (initFunction == null) {
      // Statically initialized
      b.global_get(global);
      return global.type.type;
    }
    w.Global? flag = _globalInitializedFlag[variable];
    if (flag != null) {
      // Explicit initialization flag
      assert(global.type.type == initFunction.type.outputs.single);
      b.global_get(flag);
      b.if_(const [], [global.type.type]);
      b.global_get(global);
      b.else_();
      b.call(initFunction);
      b.end();
    } else {
      // Null signals uninitialized
      w.Label block = b.block(const [], [initFunction.type.outputs.single]);
      b.global_get(global);
      b.br_on_non_null(block);
      b.call(initFunction);
      b.end();
    }
    return initFunction.type.outputs.single;
  }
}
