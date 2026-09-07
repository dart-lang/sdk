// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ir/ir.dart' as ir;
import 'builder.dart';

/// A function defined in a module.
class FunctionBuilder with Builder<ir.DefinedFunction> {
  final ModuleBuilder moduleBuilder;
  final ir.DefinedFunction function;

  /// All local variables defined in the function, including its inputs.
  List<ir.Local> get locals => body.locals;

  /// The body of the function.
  InstructionsBuilder? _body;

  FunctionBuilder(this.moduleBuilder, this.function) {
    _body = InstructionsBuilder(
      moduleBuilder,
      function.type.inputs,
      function.type.outputs,
    );
  }

  ir.FunctionType get type => function.type;
  ir.FinalizableIndex get finalizableIndex => function.finalizableIndex;
  ir.Module get enclosingModule => function.enclosingModule;
  String? get functionName => function.functionName;
  String get name => function.name;

  bool get isPure => function.isPure;
  set isPure(bool value) => function.isPure = value;

  bool get isJSCalled => function.isJSCalled;
  set isJSCalled(bool value) => function.isJSCalled = value;

  int? get inlineHint => function.inlineHint;
  set inlineHint(int? value) => function.inlineHint = value;

  InstructionsBuilder get body => _body!;

  @override
  ir.DefinedFunction forceBuild() {
    function.body = body.build();
    _body = null;
    return function;
  }

  @override
  String toString() => function.toString();
}
