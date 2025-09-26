// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';
import 'util.dart';

/// The interface for the functions in a module.
class FunctionsBuilder with Builder<ir.Functions> {
  final ModuleBuilder _moduleBuilder;
  final _functionBuilders = <FunctionBuilder>[];
  final _importedFunctions = <ir.ImportedFunction>[];
  final _declaredFunctions = <ir.BaseFunction>{};
  int _nameCount = 0;
  ir.BaseFunction? _start;

  FunctionsBuilder(this._moduleBuilder);

  set start(ir.BaseFunction init) {
    assert(_start == null);
    _start = init;
  }

  void _addName(String? name, ir.BaseFunction function) {
    if (name != null) {
      _nameCount++;
    }
  }

  void collectUsedTypes(Set<ir.DefType> usedTypes) {
    for (final f in _functionBuilders) {
      usedTypes.add(f.type);
      f.body.collectUsedTypes(usedTypes);
    }
    for (final f in _importedFunctions) {
      usedTypes.add(f.type);
    }
  }

  /// Defines a new function in this module with the given function type.
  ///
  /// The [ir.DefinedFunction.body] must be completed (including the terminating
  /// `end`) before the module can be serialized.
  FunctionBuilder define(ir.FunctionType type, [String? name]) {
    final function =
        FunctionBuilder(_moduleBuilder, ir.FinalizableIndex(), type, name);
    _functionBuilders.add(function);
    _addName(name, function);
    return function;
  }

  /// Import a function into the module.
  ir.ImportedFunction import(String module, String name, ir.FunctionType type,
      [String? functionName]) {
    final function = ir.ImportedFunction(_moduleBuilder.module, module, name,
        ir.FinalizableIndex(), type, functionName);
    _importedFunctions.add(function);
    _addName(functionName, function);
    return function;
  }

  /// Declare [function] as a module element so it can be used in a constant
  /// context.
  void declare(ir.BaseFunction function) {
    assert(function.enclosingModule == _moduleBuilder.module);
    _declaredFunctions.add(function);
  }

  @override
  ir.Functions forceBuild() {
    final built = finalizeImportsAndBuilders<ir.DefinedFunction>(
        _importedFunctions, _functionBuilders);
    return ir.Functions(
        _start, _importedFunctions, built, [..._declaredFunctions], _nameCount);
  }
}
