// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';

part 'function.dart';

/// The interface for the functions in a module.
class FunctionsBuilder with Builder<ir.Functions> {
  final ModuleBuilder _module;
  final _functions = <ir.BaseFunction>[];
  final _functionBuilders = <FunctionBuilder>[];
  final _importedFunctions = <ir.Import>[];
  int _nameCount = 0;
  bool _anyFunctionsDefined = false;
  ir.BaseFunction? _start;

  FunctionsBuilder(this._module);

  /// This is guarded by [_anyFunctionsDefined].
  int get _index => _importedFunctions.length + _functionBuilders.length;

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
    _anyFunctionsDefined = true;
    final function = FunctionBuilder(_module, _index, type, name);
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
    if (_anyFunctionsDefined) {
      throw "All function imports must be specified before any definitions.";
    }
    final function =
        ir.ImportedFunction(module, name, _index, type, functionName);
    _importedFunctions.add(function);
    _addName(functionName, function);
    return function;
  }

  @override
  ir.Functions forceBuild() => ir.Functions(_start, _importedFunctions,
      _functionBuilders.map((f) => f.build()).toList(), _functions, _nameCount);
}
