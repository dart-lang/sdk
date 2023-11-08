// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';
import 'util.dart';

part 'function.dart';

/// The interface for the functions in a module.
class FunctionsBuilder with Builder<ir.Functions> {
  final ModuleBuilder _module;
  final _functions = <ir.BaseFunction>[];
  final _functionBuilders = <FunctionBuilder>[];
  final _importedFunctions = <ir.Import>[];
  int _nameCount = 0;
  ir.BaseFunction? _start;

  FunctionsBuilder(this._module);

  set start(ir.BaseFunction init) {
    assert(_start == null);
    _start = init;
  }

  void _addName(String? name, ir.BaseFunction function) {
    if (name != null) {
      _nameCount++;
    }
    _functions.add(function);
  }

  /// Defines a new function in this module with the given function type.
  ///
  /// The [DefinedFunction.body] must be completed (including the terminating
  /// `end`) before the module can be serialized.
  FunctionBuilder define(ir.FunctionType type, [String? name]) {
    final function =
        FunctionBuilder(_module, ir.FinalizableIndex(), type, name);
    _functionBuilders.add(function);
    _addName(name, function);
    return function;
  }

  /// Import a function into the module.
  ///
  /// All imported functions must be specified before any functions are declared
  /// using [FunctionsBuilder.define].
  ir.ImportedFunction import(String module, String name, ir.FunctionType type,
      [String? functionName]) {
    final function = ir.ImportedFunction(
        module, name, ir.FinalizableIndex(), type, functionName);
    _importedFunctions.add(function);
    _addName(functionName, function);
    return function;
  }

  @override
  ir.Functions forceBuild() {
    final built = finalizeImportsAndBuilders<ir.DefinedFunction>(
        _importedFunctions, _functionBuilders);
    return ir.Functions(
        _start, _importedFunctions, built, _functions, _nameCount);
  }
}
