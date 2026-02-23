// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';

/// A function defined in a module.
class FunctionBuilder extends ir.BaseFunction
    with IndexableBuilder<ir.DefinedFunction> {
  final ModuleBuilder moduleBuilder;

  /// All local variables defined in the function, including its inputs.
  List<ir.Local> get locals => body.locals;

  /// The body of the function.
  late InstructionsBuilder _body;

  FunctionBuilder(
      this.moduleBuilder, ir.FinalizableIndex index, ir.FunctionType type,
      [String? functionName])
      : super(moduleBuilder.module, index, type, functionName) {
    _body = InstructionsBuilder(moduleBuilder, type.inputs, type.outputs);
  }

  InstructionsBuilder get body => _body;

  void replaceBody(InstructionsBuilder newBody) {
    _body = newBody;
  }

  @override
  ir.DefinedFunction forceBuild() => ir.DefinedFunction(
      enclosingModule, body.build(), finalizableIndex, type, functionName)
    ..isPure = isPure;

  @override
  String toString() => functionName ?? "#$finalizableIndex";
}
