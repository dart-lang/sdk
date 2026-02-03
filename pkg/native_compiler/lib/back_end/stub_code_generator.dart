// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ast show Class;
import 'package:native_compiler/back_end/assembler.dart';
import 'package:native_compiler/back_end/code.dart';

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

  StubFactory(this.consumeGeneratedCode);

  StubCodeGenerator allocationStubGenerator(ast.Class cls);

  Code _generateCode(StubCodeGenerator generator) {
    final asm = generator.generate();
    final code = Code(null, asm.bytes, asm.objectPool);
    consumeGeneratedCode(code);
    return code;
  }

  Code getAllocationStub(ast.Class cls) =>
      _allocationStubs[cls] ??= _generateCode(allocationStubGenerator(cls));
}
