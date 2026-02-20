// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import 'package:wasm_builder/wasm_builder.dart' as w;

import 'code_generator.dart' show EagerStaticFieldInitializerCodeGenerator;
import 'table_based_globals.dart';
import 'translator.dart';
import 'util.dart' as util;

/// If we have more than this number of fields of the same type, we prefer using
/// a wasm table to hold field values over globals.
const dartFieldTableUseCutoff = 10;

/// Handles lazy initialization of static fields.
class Globals {
  final Translator translator;

  /// When a global is read from a module other than the module defining it,
  /// this maps the global to the getter function defined and exported in
  /// the defining module.
  final Map<w.Global, w.BaseFunction> _globalGetters = {};
  final Map<w.Global, w.BaseFunction> _globalSetters = {};

  final WasmGlobalImporter _globalsModuleMap;

  Globals(this.translator)
      : _globalsModuleMap = WasmGlobalImporter(translator, 'global');

  void declareMainAppGlobalExportWithName(String name, w.Global exportable) {
    _globalsModuleMap.exportDefinitionWithName(name, exportable);
  }

  /// Reads the value of [w.Global] onto the stack in [b].
  ///
  /// Takes into account the calling module and the module the global belongs
  /// to. If they are not the same then accesses the global indirectly, either
  /// through an import or a getter call.
  w.ValueType readGlobal(w.InstructionsBuilder b, w.Global global) {
    final owningModule = translator.moduleToBuilder[global.enclosingModule]!;
    final callingModule = b.moduleBuilder;
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

  /// Dual to [readGlobal]
  void writeGlobal(w.InstructionsBuilder b, w.Global global) {
    final owningModule = translator.moduleToBuilder[global.enclosingModule]!;
    final callingModule = b.moduleBuilder;
    if (owningModule == callingModule) {
      b.global_set(global);
    } else if (translator.isMainModule(owningModule)) {
      final importedGlobal = _globalsModuleMap.get(global, callingModule);
      b.global_set(importedGlobal);
    } else {
      final setter = _globalSetters.putIfAbsent(global, () {
        final setterType =
            owningModule.types.defineFunction([global.type.type], const []);
        final setterFunction = owningModule.functions.define(setterType);
        final setterBody = setterFunction.body;
        setterBody.local_get(setterFunction.locals.single);
        setterBody.global_set(global);
        setterBody.end();
        return setterFunction;
      });
      translator.callFunction(setter, b);
    }
  }
}

class DartGlobals {
  final Translator translator;
  final Map<w.ValueType, int> _fieldTypeCount = {};

  final Map<Field, DartGlobalDefinition> _definitions = {};

  DartGlobals(this.translator) {
    for (final library in translator.component.libraries) {
      for (final field in library.fields) {
        final wasmType = translator.translateTypeOfField(field);
        _fieldTypeCount[wasmType] = (_fieldTypeCount[wasmType] ?? 0) + 1;
      }
      for (final klass in library.classes) {
        for (final field in klass.fields) {
          if (field.isInstanceMember) continue;
          final wasmType = translator.translateTypeOfField(field);
          _fieldTypeCount[wasmType] = (_fieldTypeCount[wasmType] ?? 0) + 1;
        }
      }
    }
  }

  Constant? getConstantInitializer(Field variable) {
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
  DartGlobalDefinition getDefinitionForStaticField(Field field) {
    assert(!field.isLate);
    return _definitions.putIfAbsent(field, () {
      final fieldType = translator.translateTypeOfField(field);
      final numberOfFieldsWithSameType = _fieldTypeCount[fieldType]!;
      final useTableSlot =
          numberOfFieldsWithSameType >= dartFieldTableUseCutoff &&
              fieldType is w.RefType;

      final module = translator.moduleForReference(field.fieldReference);

      // If the initializer expression is a constant expression then the field
      // doesn't have to become lazy.
      //
      // If the type is non-nullable we prefer to use a global as using a table
      // can cause null checks on usages. Oterhwise we use [useTableSlot]
      // heuristic to determine whether to use a table or not.
      final Constant? init = getConstantInitializer(field);
      if (init != null &&
          translator.constants
              .tryInstantiateEagerlyFrom(module, init, fieldType)) {
        if (useTableSlot && fieldType.nullable) {
          return _defineTableBasedField(field, fieldType, module, init, null);
        }
        return _defineGlobalBasedField(
            field, fieldType, module, !field.isFinal, init, null);
      }

      // Maybe we can emit the initialization in the start function. If so,
      // that's preferred as we don't need to pay for lazy-init check on each
      // access.
      final initializer = field.initializer;
      if (initializer != null && _initializeAtStartup(field)) {
        final definition =
            _defineGlobalBasedField(field, fieldType, module, true, init, null);

        if (module.module == translator.initFunction.enclosingModule) {
          // We have to initialize the global field in the same module as where
          // the field value is defined in.
          // TODO: Once dynamic modules only compile code for the submodule and
          // not the main module, we should turn this into an assert.
          EagerStaticFieldInitializerCodeGenerator(
                  translator, field, definition.global)
              .generate(translator.initFunction.body, [], null);
        }

        return definition;
      }

      // Add initializer function to the compilation queue.
      translator.functions.getFunction(field.fieldReference);

      // We will have to initialize the global lazily, meaning each access will
      // check if it's initialized and if not, cause initialization.
      final w.ValueType newFieldType;
      final w.GlobalBuilder? initializerFlagGlobal;
      if (fieldType is w.RefType && !fieldType.nullable) {
        // Null signals uninitialized
        newFieldType = fieldType.withNullability(true);
        initializerFlagGlobal = null;
      } else {
        // Explicit initialization flag
        newFieldType = fieldType;
        initializerFlagGlobal = _defineInitializerFlag(field, module);
      }

      if (useTableSlot && newFieldType.nullable) {
        return _defineTableBasedField(field, newFieldType as w.RefType, module,
            null, initializerFlagGlobal);
      }
      return _defineGlobalBasedField(
          field, newFieldType, module, true, null, initializerFlagGlobal);
    });
  }

  w.GlobalBuilder _defineInitializerFlag(Field field, w.ModuleBuilder module) {
    final memberName = _memberName(field);
    final global = module.globals
        .define(w.GlobalType(w.NumType.i32), "$memberName initialized");
    global.initializer.i32_const(0);
    global.initializer.end();
    return global;
  }

  TableBasedDartGlobal _defineTableBasedField(
      Field field,
      w.RefType fieldType,
      w.ModuleBuilder module,
      Constant? init,
      w.GlobalBuilder? initializerFlag) {
    final table =
        translator.tableBasedGlobals.getTableForType(fieldType.heapType);
    if (init != null && init is! NullConstant) {
      return TableBasedDartGlobal(
          table,
          table.indexForObject(field, module, (ib) {
            translator.constants.instantiateConstant(ib, init, fieldType);
            ib.end();
          }));
    }
    return TableBasedDartGlobal(table, table.indexForObject(field),
        initializedFlag: initializerFlag);
  }

  WasmGlobalDartGlobal _defineGlobalBasedField(
      Field field,
      w.ValueType fieldType,
      w.ModuleBuilder module,
      bool mutable,
      Constant? init,
      w.GlobalBuilder? initializerFlag) {
    final memberName = _memberName(field);
    final global = module.globals
        .define(w.GlobalType(fieldType, mutable: mutable), memberName);
    if (init != null) {
      translator.constants
          .instantiateConstant(global.initializer, init, fieldType);
    } else {
      translator
          .getDummyValuesCollectorForModule(module)
          .instantiateLocalDummyValue(global.initializer, fieldType);
    }
    global.initializer.end();
    return WasmGlobalDartGlobal(global, initializedFlag: initializerFlag);
  }

  String _memberName(Field field) => field.toString();

  bool _initializeAtStartup(Annotatable node) =>
      util.getPragma<bool>(
          translator.coreTypes, node, 'wasm:initialize-at-startup',
          defaultValue: true) ??
      false;
}

sealed class DartGlobalDefinition {
  final w.Global? initializedFlag;
  DartGlobalDefinition({this.initializedFlag});

  w.ValueType get type;
  w.ValueType read(Translator translator, w.InstructionsBuilder b);
  void write(Translator translator, w.InstructionsBuilder b,
      void Function(w.InstructionsBuilder) pushValue);
}

final class WasmGlobalDartGlobal extends DartGlobalDefinition {
  final w.Global global;
  WasmGlobalDartGlobal(this.global, {super.initializedFlag});

  @override
  w.ValueType get type => global.type.type;

  @override
  w.ValueType read(Translator translator, w.InstructionsBuilder b) {
    return translator.globals.readGlobal(b, global);
  }

  @override
  void write(Translator translator, w.InstructionsBuilder b,
      void Function(w.InstructionsBuilder) pushValue) {
    pushValue(b);
    translator.globals.writeGlobal(b, global);
  }
}

final class TableBasedDartGlobal extends DartGlobalDefinition {
  final TypeSpecificGlobalTable table;
  final int index;

  TableBasedDartGlobal(this.table, this.index, {super.initializedFlag});

  @override
  w.ValueType get type => table.type;

  @override
  w.RefType read(Translator translator, w.InstructionsBuilder b) {
    final wasmTable = table.getWasmTable(b.moduleBuilder);
    b.i32_const(index);
    b.table_get(wasmTable);
    return wasmTable.type;
  }

  @override
  void write(Translator translator, w.InstructionsBuilder b,
      void Function(w.InstructionsBuilder) pushValue) {
    b.i32_const(index);
    pushValue(b);
    b.table_set(table.getWasmTable(b.moduleBuilder));
  }
}
