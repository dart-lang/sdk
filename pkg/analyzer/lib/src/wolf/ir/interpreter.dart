// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/wolf/ir/coded_ir.dart';
import 'package:analyzer/src/wolf/ir/ir.dart';
import 'package:meta/meta.dart';

/// Evaluates [ir], passing in [args], and returns the result.
///
/// This interpreter is neither efficient nor full-featured, so it shouldn't be
/// used in production code. It is solely intended to allow unit tests to verify
/// that an instruction sequence behaves as it's expected to.
@visibleForTesting
Object? interpret(CodedIRContainer ir, List<Object?> args) =>
    _IRInterpreter(ir).run(args);

class _IRInterpreter {
  final CodedIRContainer ir;
  final stack = <Object?>[];

  _IRInterpreter(this.ir);

  Object? run(List<Object?> args) {
    var functionType = Opcode.function.decodeType(ir, 0);
    var parameterCount = ir.countParameters(functionType);
    if (args.length != parameterCount) {
      throw StateError('Parameter count mismatch');
    }
    stack.addAll(args);
    var address = 1;
    while (true) {
      switch (ir.opcodeAt(address)) {
        case Opcode.end:
          assert(stack.length == 1);
          return stack.last;
        case Opcode.literal:
          var value = Opcode.literal.decodeValue(ir, address);
          stack.add(ir.decodeLiteral(value));
        case var opcode:
          throw UnimplementedError(
              'TODO(paulberry): implement ${opcode.describe()} in '
              '_IRInterpreter');
      }
      address++;
    }
  }
}
