// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ast show Class;
import 'package:native_compiler/back_end/code.dart';
import 'package:native_compiler/back_end/locations.dart';
import 'package:native_compiler/runtime/vm_defs.dart';

/// Interface class for architecture-specific stub code generator.
abstract interface class StubCodeGenerator {
  Code generate(String name);
}

/// Reference to platform stub code.
///
/// It could be either [Code] if compiling a platform, or symbolic [StubCode]
/// which resolves to a stub code when module snapshot is loaded.
extension type PlatformStub._(Object /*Code|StubCode*/ code) implements Object;

/// Base class for architecture-specific stub factory.
///
/// Generates and caches stubs on demand.
abstract base class StubFactory {
  /// List of stubs included into a platform snapshot.
  /// Should match PLATFORM_STUB_LIST macro in runtime/vm/module_snapshot.cc.
  static const Set<StubCode> platformStubs = <StubCode>{
    .DynamicInvocationForwarder,
    .InvokeDartCode,
    .InvokeDartCodeFromBytecode,
    .Await,
    .AwaitWithTypeCheck,
    .YieldAsyncStar,
    .SuspendSyncStarAtStart,
    .SuspendSyncStarAtYield,
    .InitAsync,
    .InitAsyncStar,
    .InitSyncStar,
    .Resume,
    .ReturnAsync,
    .ReturnAsyncNotFuture,
    .ReturnAsyncStar,
    .AsyncExceptionHandler,
    .CloneSuspendState,
  };

  final CodeConsumer consumeGeneratedCode;
  final bool compilePlatform;
  final Map<StubCode, PlatformStub> _platformStubs = {};
  final Map<ast.Class, Code> _allocationStubs = {};
  final Map<(Register, Register, bool), Code> _writeBarrierStubs = {};
  final List<Code?> _subtypeTestCacheStubs = List<Code?>.filled(8, null);

  late final Code dynamicCallStub = _generateCode(
    'DynamicCallStub',
    dynamicCallStubGenerator(),
  );

  StubFactory(this.consumeGeneratedCode, {required this.compilePlatform});

  StubCodeGenerator getPlatformStubGenerator(StubCode stub);

  StubCodeGenerator allocationStubGenerator(ast.Class cls);

  StubCodeGenerator writeBarrierStubGenerator(
    Register objectReg,
    Register valueReg,
    bool isArray,
  );

  StubCodeGenerator dynamicCallStubGenerator();

  StubCodeGenerator subtypeTestCacheStubGenerator(int n);

  Code _generateCode(String name, StubCodeGenerator generator) {
    final code = generator.generate(name);
    consumeGeneratedCode(code);
    return code;
  }

  PlatformStub getPlatformStub(StubCode stub) =>
      _platformStubs[stub] ??= PlatformStub._(
        (compilePlatform && platformStubs.contains(stub))
            ? _generateCode('${stub.name}Stub', getPlatformStubGenerator(stub))
            : stub,
      );

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
