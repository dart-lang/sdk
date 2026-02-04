// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import 'package:wasm_builder/wasm_builder.dart' as w;

import 'code_generator.dart' show EagerStaticFieldInitializerCodeGenerator;
import 'translator.dart';
import 'util.dart' as util;

/// Handles lazy initialization of static fields.
class Globals {
  final Translator translator;

  /// Maps a static field to its global holding the field value.
  final Map<Field, w.GlobalBuilder> _globals = {};

  /// When a global is read from a module other than the module defining it,
  /// this maps the global to the getter function defined and exported in
  /// the defining module.
  final Map<w.Global, w.BaseFunction> _globalGetters = {};
  final Map<w.Global, w.BaseFunction> _globalSetters = {};

  final Map<Field, w.Global> _globalInitializedFlag = {};
  final WasmGlobalImporter _globalsModuleMap;

  Globals(this.translator)
      : _globalsModuleMap = WasmGlobalImporter(translator, 'global');

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

  /// Return (and if needed create) the Wasm global corresponding to a static
  /// field.
  w.Global getGlobalForStaticField(Field field) {
    assert(!field.isLate);
    return _globals.putIfAbsent(field, () {
      w.ValueType fieldType = translator.translateTypeOfField(field);
      final module = translator.moduleForReference(field.fieldReference);
      final memberName = field.toString();

      // Maybe we can emit the initialization in the globals section. If so,
      // then that's preferred as we can make the global as non-mutable.
      final Constant? init = getConstantInitializer(field);
      if (init != null &&
          translator.constants
              .tryInstantiateEagerlyFrom(module, init, fieldType)) {
        // Initialized to a constant
        final global = module.globals.define(
            w.GlobalType(fieldType, mutable: !field.isFinal), memberName);
        translator.constants
            .instantiateConstant(global.initializer, init, fieldType);
        global.initializer.end();
        return global;
      }

      // Maybe we can emit the initialization in the start function. If so,
      // that's preferred as we don't need to pay for lazy-init check on each
      // access.
      final initializer = field.initializer;
      if (initializer != null && _initializeAtStartup(field)) {
        // The dummy value (if needed) needs to be created before we define
        // the global that may use it.
        final dummyCollector =
            translator.getDummyValuesCollectorForModule(module);
        dummyCollector.prepareDummyValue(module, fieldType);

        final global =
            module.globals.define(w.GlobalType(fieldType), memberName);
        dummyCollector.instantiateDummyValue(global.initializer, fieldType);
        global.initializer.end();

        if (module.module == translator.initFunction.enclosingModule) {
          // We have to initialize the global field in the same module as where
          // the field value is defined in.
          // TODO: Once dynamic modules only compile code for the submodule and
          // not the main module, we should turn this into an assert.
          EagerStaticFieldInitializerCodeGenerator(translator, field, global)
              .generate(translator.initFunction.body, [], null);
        }

        return global;
      }

      // We will have to initialize the global lazily, meaning each access will
      // check if it's initialized and if not, cause initialization.
      final w.ValueType globalType;
      if (fieldType is w.RefType && !fieldType.nullable) {
        // Null signals uninitialized
        globalType = fieldType.withNullability(true);
      } else {
        // Explicit initialization flag
        globalType = fieldType;
        final flag = module.globals
            .define(w.GlobalType(w.NumType.i32), "$memberName initialized");
        flag.initializer.i32_const(0);
        flag.initializer.end();
        _globalInitializedFlag[field] = flag;
      }

      final global =
          module.globals.define(w.GlobalType(globalType), memberName);
      translator
          .getDummyValuesCollectorForModule(module)
          .instantiateDummyValue(global.initializer, globalType);
      global.initializer.end();

      // Add initializer function to the compilation queue.
      translator.functions.getFunction(field.fieldReference);
      return global;
    });
  }

  /// Return the Wasm global containing the flag indicating whether this static
  /// field has been initialized, if such a flag global is needed.
  ///
  /// Note that [getGlobalForStaticField] must have been called for the field beforehand.
  w.Global? getGlobalInitializedFlag(Field variable) =>
      _globalInitializedFlag[variable];

  bool _initializeAtStartup(Annotatable node) =>
      util.getPragma<bool>(
          translator.coreTypes, node, 'wasm:initialize-at-startup',
          defaultValue: true) ??
      false;
}
