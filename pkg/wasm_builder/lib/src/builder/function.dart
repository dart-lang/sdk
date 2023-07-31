// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'functions.dart';

/// A function defined in a module.
class FunctionBuilder extends ir.BaseFunction with Builder<ir.DefinedFunction> {
  /// All local variables defined in the function, including its inputs.
  List<ir.Local> get locals => body.locals;

  /// The body of the function.
  late final InstructionsBuilder body;

  FunctionBuilder(ModuleBuilder module, super.index, super.type,
      [super.functionName]) {
    body = InstructionsBuilder(module, type.outputs);
    for (ir.ValueType paramType in type.inputs) {
      body.addLocal(paramType, isParameter: true);
    }
  }

  /// Add a local variable to the function.
  ir.Local addLocal(ir.ValueType type) =>
      body.addLocal(type, isParameter: false);

  @override
  ir.DefinedFunction forceBuild() =>
      ir.DefinedFunction(body.build(), index, type, functionName);

  @override
  String toString() => exportedName ?? "#$index";
}
