// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ast show Class;
import 'package:native_compiler/back_end/assembler.dart';
import 'package:native_compiler/back_end/code.dart';
import 'package:native_compiler/back_end/locations.dart';

/// Interface class for architecture-specific stub code generator.
abstract interface class StubCodeGenerator {
  Assembler generate();
}

/// Base class for architecture-specific stub factory.
///
/// Generates and caches stubs on demand.
abstract base class StubFactory {
  final CodeConsumer consumeGeneratedCode;
  Map<ast.Class, Code> _allocationStubs = {};
  Map<(Register, Register), Code> _writeBarrierStubs = {};

  StubFactory(this.consumeGeneratedCode);

  StubCodeGenerator allocationStubGenerator(ast.Class cls);

  StubCodeGenerator writeBarrierStubGenerator(
    Register objectReg,
    Register valueReg,
  );

  Code _generateCode(String name, StubCodeGenerator generator) {
    final asm = generator.generate();
    final code = Code(name, null, asm.bytes, asm.objectPool);
    consumeGeneratedCode(code);
    return code;
  }

  Code getAllocationStub(ast.Class cls) => _allocationStubs[cls] ??=
      _generateCode('AllocationStub for ${cls}', allocationStubGenerator(cls));

  Code getWriteBarrierStub(Register objectReg, Register valueReg) =>
      _writeBarrierStubs[(objectReg, valueReg)] ??= _generateCode(
        'WriteBarrierStub for $objectReg, $valueReg',
        writeBarrierStubGenerator(objectReg, valueReg),
      );
}
