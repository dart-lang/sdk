// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'functions.dart';

/// A function defined in a module.
class FunctionBuilder extends ir.BaseFunction
    with IndexableBuilder<ir.DefinedFunction> {
  /// All local variables defined in the function, including its inputs.
  List<ir.Local> get locals => body.locals;

  /// The body of the function.
  late final InstructionsBuilder body;

  FunctionBuilder(super.enclosingModule, super.index, super.type,
      [super.functionName]) {
    body = InstructionsBuilder(enclosingModule, type.inputs, type.outputs);
  }

  @override
  ir.DefinedFunction forceBuild() => ir.DefinedFunction(
      enclosingModule, body.build(), finalizableIndex, type, functionName);

  @override
  String toString() => functionName ?? "#$finalizableIndex";
}
