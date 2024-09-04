// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import 'package:wasm_builder/wasm_builder.dart' as w;

import 'translator.dart';

/// Handles lazy initialization of static fields.
class Globals {
  final Translator translator;

  final Map<Field, w.GlobalBuilder> _globals = {};
  final Map<w.Global, w.BaseFunction> _globalGetters = {};
  final Map<w.Global, w.BaseFunction> _globalSetters = {};
  final Map<Field, w.BaseFunction> _globalInitializers = {};
  final Map<Field, w.Global> _globalInitializedFlag = {};
  final Map<(w.ModuleBuilder, w.FunctionType), w.BaseFunction> _dummyFunctions =
      {};
  final Map<w.HeapType, w.Global> _dummyValues = {};
  late final WasmGlobalImporter _globalsModuleMap =
      WasmGlobalImporter(translator, 'global');
  late final w.Global dummyStructGlobal;

  Globals(this.translator) {
    _initDummyValues();
  }

  void _initDummyValues() {
    // Create dummy struct for anyref/eqref/structref dummy values
    w.StructType structType =
        translator.typesBuilder.defineStruct("#DummyStruct");
    final dummyStructGlobalInit = translator.mainModule.globals.define(
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
  w.BaseFunction getDummyFunction(w.ModuleBuilder module, w.FunctionType type) {
    return _dummyFunctions.putIfAbsent((module, type), () {
      final function = module.functions.define(type, "#dummy function $type");
      final b = function.body;
      b.unreachable();
      b.end();
      return function;
    });
  }

  /// Returns whether the given function was provided by [getDummyFunction].
  bool isDummyFunction(w.ModuleBuilder module, w.BaseFunction function) {
    return _dummyFunctions[(module, function.type)] == function;
  }

  w.Global? _prepareDummyValue(w.ModuleBuilder module, w.ValueType type) {
    if (type is w.RefType && !type.nullable) {
      w.HeapType heapType = type.heapType;
      return _dummyValues.putIfAbsent(heapType, () {
        if (heapType is w.DefType) {
          if (heapType is w.StructType) {
            for (w.FieldType field in heapType.fields) {
              _prepareDummyValue(module, field.type.unpacked);
            }
            final global =
                module.globals.define(w.GlobalType(type, mutable: false));
            final ib = global.initializer;
            for (w.FieldType field in heapType.fields) {
              instantiateDummyValue(ib, field.type.unpacked);
            }
            ib.struct_new(heapType);
            ib.end();
            return global;
          } else if (heapType is w.ArrayType) {
            final global =
                module.globals.define(w.GlobalType(type, mutable: false));
            final ib = global.initializer;
            ib.array_new_fixed(heapType, 0);
            ib.end();
            return global;
          } else if (heapType is w.FunctionType) {
            final global =
                module.globals.define(w.GlobalType(type, mutable: false));
            final ib = global.initializer;
            ib.ref_func(getDummyFunction(module, heapType));
            ib.end();
            return global;
          }
        }
        throw 'Unexpected heapType: $heapType';
      });
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
            readGlobal(b, _prepareDummyValue(b.module, type)!);
          }
        } else {
          throw "Unsupported global type $type ($type)";
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

  /// Reads the value of [w.Global] onto the stack in [b].
  ///
  /// Takes into account the calling module and the module the global belongs
  /// to. If they are not the same then accesses the global indirectly, either
  /// through an import or a getter call.
  w.ValueType readGlobal(w.InstructionsBuilder b, w.Global global,
      {String importNameSuffix = ''}) {
    final owningModule = global.enclosingModule;
    final callingModule = b.module;
    if (owningModule == callingModule) {
      b.global_get(global);
    } else if (translator.isMainModule(owningModule)) {
      final importedGlobal = _globalsModuleMap.get(global, callingModule);
      b.global_get(importedGlobal);
    } else {
      final getter = _globalGetters.putIfAbsent(global, () {
        final getterType =
            owningModule.types.defineFunction(const [], [global.type.type]);
        final getterFunction = owningModule.functions.define(getterType);
        final getterBody = getterFunction.body;
        getterBody.global_get(global);
        getterBody.end();
        return getterFunction;
      });

      translator.callFunction(getter, b);
    }
    return global.type.type;
  }

  /// Sets the value of [w.Global] in [b].
  ///
  /// Takes into account the calling module and the module the global belongs
  /// to. If they are not the same then sets the global indirectly, either
  /// through an import or a setter call.
  void updateGlobal(w.InstructionsBuilder b,
      void Function(w.InstructionsBuilder b) pushValue, w.Global global) {
    final owningModule = global.enclosingModule;
    final callingModule = b.module;
    if (owningModule == callingModule) {
      pushValue(b);
      b.global_set(global);
    } else if (translator.isMainModule(owningModule)) {
      final importedGlobal = _globalsModuleMap.get(global, callingModule);
      pushValue(b);
      b.global_set(importedGlobal);
    } else {
      final setter = _globalSetters.putIfAbsent(global, () {
        final setterType =
            owningModule.types.defineFunction([global.type.type], const []);
        final setterFunction = owningModule.functions.define(setterType);
        final setterBody = setterFunction.body;
        setterBody.local_get(setterBody.locals.single);
        setterBody.global_set(global);
        setterBody.end();
        return setterFunction;
      });

      pushValue(b);
      translator.callFunction(setter, b);
    }
  }

  /// Return (and if needed create) the Wasm global corresponding to a static
  /// field.
  w.Global getGlobalForStaticField(Field field) {
    assert(!field.isLate);
    return _globals.putIfAbsent(field, () {
      final Constant? init = _getConstantInitializer(field);
      w.ValueType type = translator.translateTypeOfField(field);
      final module = translator.moduleForReference(field.fieldReference);
      if (init != null &&
          !(translator.constants.ensureConstant(init)?.isLazy ?? false)) {
        // Initialized to a constant
        final global =
            module.globals.define(w.GlobalType(type, mutable: !field.isFinal));
        translator.constants
            .instantiateConstant(global.initializer, init, type);
        global.initializer.end();
        return global;
      } else {
        if (type is w.RefType && !type.nullable) {
          // Null signals uninitialized
          type = type.withNullability(true);
        } else {
          // Explicit initialization flag
          final flag = module.globals.define(w.GlobalType(w.NumType.i32));
          flag.initializer.i32_const(0);
          flag.initializer.end();
          _globalInitializedFlag[field] = flag;
        }

        final global = module.globals.define(w.GlobalType(type));
        instantiateDummyValue(global.initializer, type);
        global.initializer.end();

        _globalInitializers[field] =
            translator.functions.getFunction(field.fieldReference);
        return global;
      }
    });
  }

  /// Return the Wasm global containing the flag indicating whether this static
  /// field has been initialized, if such a flag global is needed.
  ///
  /// Note that [getGlobalForStaticField] must have been called for the field beforehand.
  w.Global? getGlobalInitializedFlag(Field variable) {
    return _globalInitializedFlag[variable];
  }
}
