// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ast show Class;
import 'package:native_compiler/back_end/code.dart';
import 'package:native_compiler/back_end/locations.dart';

/// Interface class for architecture-specific stub code generator.
abstract interface class StubCodeGenerator {
  Code generate(String name);
}

/// Base class for architecture-specific stub factory.
///
/// Generates and caches stubs on demand.
abstract base class StubFactory {
  final CodeConsumer consumeGeneratedCode;
  Map<ast.Class, Code> _allocationStubs = {};
  Map<(Register, Register, bool), Code> _writeBarrierStubs = {};
  List<Code?> _subtypeTestCacheStubs = List<Code?>.filled(8, null);

  late final Code dynamicCallStub = _generateCode(
    'DynamicCallStub',
    dynamicCallStubGenerator(),
  );

  late final Code dynamicInvocationForwarderStub = _generateCode(
    'DynamicInvocationForwarderStub',
    dynamicInvocationForwarderStubGenerator(),
  );

  late final Code invokeDartCodeStub = _generateCode(
    'InvokeDartCodeStub',
    invokeDartCodeStubGenerator(),
  );

  late final Code invokeDartCodeFromBytecodeStub = _generateCode(
    'InvokeDartCodeFromBytecodeStub',
    invokeDartCodeFromBytecodeStubGenerator(),
  );

  late final Code awaitStub = _generateCode('AwaitStub', awaitStubGenerator());

  late final Code awaitWithTypeCheckStub = _generateCode(
    'AwaitWithTypeCheckStub',
    awaitWithTypeCheckStubGenerator(),
  );

  late final Code yieldAsyncStarStub = _generateCode(
    'YieldAsyncStarStub',
    yieldAsyncStarStubGenerator(),
  );

  late final Code suspendSyncStarAtStartStub = _generateCode(
    'SuspendSyncStarAtStartStub',
    suspendSyncStarAtStartStubGenerator(),
  );

  late final Code suspendSyncStarAtYieldStub = _generateCode(
    'SuspendSyncStarAtYieldStub',
    suspendSyncStarAtYieldStubGenerator(),
  );

  late final Code initAsyncStub = _generateCode(
    'InitAsyncStub',
    initAsyncStubGenerator(),
  );

  late final Code initAsyncStarStub = _generateCode(
    'InitAsyncStarStub',
    initAsyncStarStubGenerator(),
  );

  late final Code initSyncStarStub = _generateCode(
    'InitSyncStarStub',
    initSyncStarStubGenerator(),
  );

  late final Code resumeStub = _generateCode(
    'ResumeStub',
    resumeStubGenerator(),
  );

  late final Code returnAsyncStub = _generateCode(
    'ReturnAsyncStub',
    returnAsyncStubGenerator(),
  );

  late final Code returnAsyncNotFutureStub = _generateCode(
    'ReturnAsyncNotFutureStub',
    returnAsyncNotFutureStubGenerator(),
  );

  late final Code returnAsyncStarStub = _generateCode(
    'ReturnAsyncStarStub',
    returnAsyncStarStubGenerator(),
  );

  late final Code asyncExceptionHandlerStub = _generateCode(
    'AsyncExceptionHandlerStub',
    asyncExceptionHandlerStubGenerator(),
  );

  late final Code cloneSuspendStateStub = _generateCode(
    'CloneSuspendStateStub',
    cloneSuspendStateStubGenerator(),
  );

  StubFactory(this.consumeGeneratedCode);

  StubCodeGenerator allocationStubGenerator(ast.Class cls);

  StubCodeGenerator writeBarrierStubGenerator(
    Register objectReg,
    Register valueReg,
    bool isArray,
  );

  StubCodeGenerator dynamicCallStubGenerator();

  StubCodeGenerator dynamicInvocationForwarderStubGenerator();

  StubCodeGenerator invokeDartCodeStubGenerator();

  StubCodeGenerator invokeDartCodeFromBytecodeStubGenerator();

  StubCodeGenerator subtypeTestCacheStubGenerator(int n);

  StubCodeGenerator awaitStubGenerator();

  StubCodeGenerator awaitWithTypeCheckStubGenerator();

  StubCodeGenerator yieldAsyncStarStubGenerator();

  StubCodeGenerator suspendSyncStarAtStartStubGenerator();

  StubCodeGenerator suspendSyncStarAtYieldStubGenerator();

  StubCodeGenerator initAsyncStubGenerator();

  StubCodeGenerator initAsyncStarStubGenerator();

  StubCodeGenerator initSyncStarStubGenerator();

  StubCodeGenerator resumeStubGenerator();

  StubCodeGenerator returnAsyncStubGenerator();

  StubCodeGenerator returnAsyncNotFutureStubGenerator();

  StubCodeGenerator returnAsyncStarStubGenerator();

  StubCodeGenerator asyncExceptionHandlerStubGenerator();

  StubCodeGenerator cloneSuspendStateStubGenerator();

  Code _generateCode(String name, StubCodeGenerator generator) {
    final code = generator.generate(name);
    consumeGeneratedCode(code);
    return code;
  }

  Code getAllocationStub(ast.Class cls) => _allocationStubs[cls] ??=
      _generateCode('AllocationStub for ${cls}', allocationStubGenerator(cls));

  Code getWriteBarrierStub(
    Register objectReg,
    Register valueReg,
    bool isArray,
  ) => _writeBarrierStubs[(objectReg, valueReg, isArray)] ??= _generateCode(
    'WriteBarrierStub for $objectReg, $valueReg${isArray ? ' array' : ''}',
    writeBarrierStubGenerator(objectReg, valueReg, isArray),
  );

  Code getSubtypeTestCacheStub(int numInputs) =>
      _subtypeTestCacheStubs[numInputs] ??= _generateCode(
        'SubtypeTestCacheStub',
        subtypeTestCacheStubGenerator(numInputs),
      );
}
