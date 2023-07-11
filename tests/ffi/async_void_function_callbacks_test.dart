// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing dart:ffi async callbacks.
//
// VMOptions=--stacktrace-every=100
// VMOptions=--write-protect-code --no-dual-map-code
// VMOptions=--write-protect-code --no-dual-map-code --stacktrace-every=100
// VMOptions=--use-slow-path
// VMOptions=--use-slow-path --stacktrace-every=100
// VMOptions=--use-slow-path --write-protect-code --no-dual-map-code
// VMOptions=--use-slow-path --write-protect-code --no-dual-map-code --stacktrace-every=100
// VMOptions=--dwarf_stack_traces --no-retain_function_objects --no-retain_code_objects
// VMOptions=--test_il_serialization
// VMOptions=--profiler
// SharedObjects=ffi_test_functions

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:math';

import 'dart:io';

import "package:expect/expect.dart";

import 'dylib_utils.dart';

main(args, message) async {
  if (message != null) {
    // We've been spawned by Isolate.spawnUri. Run IsolateB.
    await IsolateB.entryPoint(message);
    return;
  }

  // Simple tests.
  await testNativeCallableHelloWorld();
  testNativeCallableDoubleCloseError();
  await testNativeCallableUseAfterFree();
  await testNativeCallableNestedCloseCall();
  await testNativeCallableThrowInsideCallback();

  // Message passing tests.
  globalVar = 1000;
  for (final sameGroup in [true, false]) {
    final isolateA = IsolateA(sameGroup);
    await isolateA.messageLoop();
    isolateA.close();
  }
  print("All tests completed :)");
}

final List<TestCase> messagePassingTestCases = [
  SanityCheck(),
  CallFromIsoAToIsoB(),
  CallFromIsoBToIsoA(),
  CallFromIsoAToIsoBViaNewThreadBlocking(),
  CallFromIsoBToIsoAViaNewThreadBlocking(),
  CallFromIsoAToIsoBViaNewThreadNonBlocking(),
  CallFromIsoBToIsoAViaNewThreadNonBlocking(),
  CallFromIsoAToBToA(),
  CallFromIsoBToAToB(),
  ManyCallsBetweenIsolates(),
  ManyCallsBetweenIsolatesViaNewThreadBlocking(),
  ManyCallsBetweenIsolatesViaNewThreadNonBlocking(),
];

var simpleFunctionResult = Completer<int>();
void simpleFunction(int a, int b) {
  simpleFunctionResult.complete(a + b);
}

testNativeCallableHelloWorld() async {
  final lib = NativeLibrary();
  final callback = NativeCallable<CallbackNativeType>.listener(simpleFunction);

  simpleFunctionResult = Completer<int>();
  lib.callFunctionOnSameThread(1000, callback.nativeFunction);

  Expect.equals(1123, await simpleFunctionResult.future);
  callback.close();
}

testNativeCallableDoubleCloseError() {
  final callback = NativeCallable<CallbackNativeType>.listener(simpleFunction);
  Expect.notEquals(nullptr, callback.nativeFunction);
  callback.close();
  Expect.equals(nullptr, callback.nativeFunction);
  Expect.throwsStateError(() {
    callback.close();
  });
}

testNativeCallableUseAfterFree() async {
  final lib = NativeLibrary();

  final callback = NativeCallable<CallbackNativeType>.listener(simpleFunction);
  final nativeFunction = callback.nativeFunction;
  callback.close();

  simpleFunctionResult = Completer<int>();
  lib.callFunctionOnSameThread(123, nativeFunction);

  await Future.delayed(Duration(milliseconds: 100));

  // The callback wasn't invoked, but we didn't crash either.
  Expect.equals(false, simpleFunctionResult.isCompleted);
}

NativeCallable? simpleFunctionAndCloseSelf_callable;
void simpleFunctionAndCloseSelf(int a, int b) {
  simpleFunctionAndCloseSelf_callable!.close();
  simpleFunctionResult.complete(a + b);
}

testNativeCallableNestedCloseCall() async {
  final lib = NativeLibrary();
  simpleFunctionAndCloseSelf_callable =
      NativeCallable<CallbackNativeType>.listener(simpleFunctionAndCloseSelf);

  simpleFunctionResult = Completer<int>();
  lib.callFunctionOnSameThread(
      1000, simpleFunctionAndCloseSelf_callable!.nativeFunction);

  Expect.equals(1123, await simpleFunctionResult.future);

  // The callback is already closed.
  Expect.equals(nullptr, simpleFunctionAndCloseSelf_callable!.nativeFunction);
}

void simpleFunctionThrows(int a, int b) {
  throw a + b;
}

testNativeCallableThrowInsideCallback() async {
  final lib = NativeLibrary();
  var caughtError;
  late final callback;

  runZonedGuarded(() {
    callback =
        NativeCallable<CallbackNativeType>.listener(simpleFunctionThrows);
  }, (Object error, StackTrace stack) {
    caughtError = error;
  });

  lib.callFunctionOnSameThread(1000, callback.nativeFunction);
  await Future.delayed(Duration(milliseconds: 100));

  Expect.equals(1123, caughtError);

  callback.close();
}

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

// Global variable that is 1000 on isolate A, and 2000 on isolate B.
late final int globalVar;

class SanityCheck extends TestCase {
  @override
  SendPort? sendIsoAResultsTo(AsyncTestManager atm) => atm.toIsoA;

  @override
  SendPort? sendIsoBResultsTo(AsyncTestManager atm) => atm.toIsoB;

  @override
  Future<void> runOnIsoA(IsolateA iso) async {
    Expect.equals(1000, globalVar);
    final result = iso.atm.call((responseId) => iso.natLib
        .callFunctionOnSameThread(
            responseId, Pointer.fromAddress(iso.fnPtrsA.addGlobalVarPtr)));
    print("SanityCheck.runOnIsoA message sent. Awaiting result...");
    Expect.equals(1123, await result);
  }

  @override
  Future<void> runOnIsoB(IsolateB iso) async {
    Expect.equals(2000, globalVar);
    final result = iso.atm.call((responseId) => iso.natLib
        .callFunctionOnSameThread(
            responseId, Pointer.fromAddress(iso.fnPtrsB.addGlobalVarPtr)));
    print("SanityCheck.runOnIsoB message sent. Awaiting result...");
    Expect.equals(2123, await result);
  }
}

class CallFromIsoAToIsoB extends TestCase {
  @override
  SendPort? sendIsoBResultsTo(AsyncTestManager atm) => atm.toIsoA;

  @override
  Future<void> runOnIsoA(IsolateA iso) async {
    final result = iso.atm.call((responseId) => iso.natLib
        .callFunctionOnSameThread(
            responseId, Pointer.fromAddress(iso.fnPtrsB.addGlobalVarPtr)));
    print("CallFromIsoAToIsoB.runOnIsoA message sent. Awaiting result...");
    Expect.equals(2123, await result);
  }
}

class CallFromIsoBToIsoA extends TestCase {
  @override
  SendPort? sendIsoAResultsTo(AsyncTestManager atm) => atm.toIsoB;

  @override
  Future<void> runOnIsoB(IsolateB iso) async {
    final result = iso.atm.call((responseId) => iso.natLib
        .callFunctionOnSameThread(
            responseId, Pointer.fromAddress(iso.fnPtrsA.addGlobalVarPtr)));
    print("CallFromIsoBToIsoA.runOnIsoB message sent. Awaiting result...");
    Expect.equals(1123, await result);
  }
}

class CallFromIsoAToIsoBViaNewThreadBlocking extends TestCase {
  @override
  SendPort? sendIsoBResultsTo(AsyncTestManager atm) => atm.toIsoA;

  @override
  Future<void> runOnIsoA(IsolateA iso) async {
    final result = iso.atm.call((responseId) => iso.natLib
        .callFunctionOnNewThreadBlocking(
            responseId, Pointer.fromAddress(iso.fnPtrsB.addGlobalVarPtr)));
    print(
        "CallFromIsoAToIsoBViaNewThreadBlocking.runOnIsoA message sent. Awaiting result...");
    Expect.equals(2123, await result);
  }
}

class CallFromIsoBToIsoAViaNewThreadBlocking extends TestCase {
  @override
  SendPort? sendIsoAResultsTo(AsyncTestManager atm) => atm.toIsoB;

  @override
  Future<void> runOnIsoB(IsolateB iso) async {
    final result = iso.atm.call((responseId) => iso.natLib
        .callFunctionOnNewThreadBlocking(
            responseId, Pointer.fromAddress(iso.fnPtrsA.addGlobalVarPtr)));
    print(
        "CallFromIsoBToIsoAViaNewThreadBlocking.runOnIsoB message sent. Awaiting result...");
    Expect.equals(1123, await result);
  }
}

class CallFromIsoAToIsoBViaNewThreadNonBlocking extends TestCase {
  @override
  SendPort? sendIsoBResultsTo(AsyncTestManager atm) => atm.toIsoA;

  @override
  Future<void> runOnIsoA(IsolateA iso) async {
    final result = iso.atm.call((responseId) => iso.natLib
        .callFunctionOnNewThreadNonBlocking(
            responseId, Pointer.fromAddress(iso.fnPtrsB.addGlobalVarPtr)));
    print(
        "CallFromIsoAToIsoBViaNewThreadNonBlocking.runOnIsoA message sent. Awaiting result...");
    Expect.equals(2123, await result);
  }
}

class CallFromIsoBToIsoAViaNewThreadNonBlocking extends TestCase {
  @override
  SendPort? sendIsoAResultsTo(AsyncTestManager atm) => atm.toIsoB;

  @override
  Future<void> runOnIsoB(IsolateB iso) async {
    final result = iso.atm.call((responseId) => iso.natLib
        .callFunctionOnNewThreadNonBlocking(
            responseId, Pointer.fromAddress(iso.fnPtrsA.addGlobalVarPtr)));
    print(
        "CallFromIsoBToIsoAViaNewThreadNonBlocking.runOnIsoB message sent. Awaiting result...");
    Expect.equals(1123, await result);
  }
}

class CallFromIsoAToBToA extends TestCase {
  @override
  SendPort? sendIsoAResultsTo(AsyncTestManager atm) => atm.toIsoB;

  @override
  SendPort? sendIsoBResultsTo(AsyncTestManager atm) => atm.toIsoA;

  @override
  Future<void> runOnIsoA(IsolateA iso) async {
    final result = iso.atm.call((responseId) => iso.natLib
        .callFunctionOnSameThread(
            responseId,
            Pointer.fromAddress(
                iso.fnPtrsB.callFromIsoBToAAndMultByGlobalVarPtr)));
    print("CallFromIsoAToBToA.runOnIsoA message sent. Awaiting result...");
    Expect.equals(2000 * 1123, await result);
  }
}

class CallFromIsoBToAToB extends TestCase {
  @override
  SendPort? sendIsoAResultsTo(AsyncTestManager atm) => atm.toIsoB;

  @override
  SendPort? sendIsoBResultsTo(AsyncTestManager atm) => atm.toIsoA;

  @override
  Future<void> runOnIsoB(IsolateB iso) async {
    final result = iso.atm.call((responseId) => iso.natLib
        .callFunctionOnSameThread(
            responseId,
            Pointer.fromAddress(
                iso.fnPtrsA.callFromIsoAToBAndMultByGlobalVarPtr)));
    print("CallFromIsoBToAToB.runOnIsoB message sent. Awaiting result...");
    Expect.equals(1000 * 2123, await result);
  }
}

class ManyCallsBetweenIsolates extends TestCase {
  @override
  SendPort? sendIsoAResultsTo(AsyncTestManager atm) => atm.toIsoB;

  @override
  SendPort? sendIsoBResultsTo(AsyncTestManager atm) => atm.toIsoA;

  @override
  Future<void> runOnIsoA(IsolateA iso) async {
    print("ManyCallsBetweenIsolates.runOnIsoA sending messages.");
    await Future.wait(List.filled(100, null).map((_) async {
      final result = iso.atm.call((responseId) => iso.natLib
          .callFunctionOnSameThread(
              responseId, Pointer.fromAddress(iso.fnPtrsB.addGlobalVarPtr)));
      Expect.equals(2123, await result);
    }));
  }

  @override
  Future<void> runOnIsoB(IsolateB iso) async {
    print("ManyCallsBetweenIsolates.runOnIsoB sending messages.");
    await Future.wait(List.filled(100, null).map((_) async {
      final result = iso.atm.call((responseId) => iso.natLib
          .callFunctionOnSameThread(
              responseId, Pointer.fromAddress(iso.fnPtrsA.addGlobalVarPtr)));
      Expect.equals(1123, await result);
    }));
  }
}

class ManyCallsBetweenIsolatesViaNewThreadBlocking extends TestCase {
  @override
  SendPort? sendIsoAResultsTo(AsyncTestManager atm) => atm.toIsoB;

  @override
  SendPort? sendIsoBResultsTo(AsyncTestManager atm) => atm.toIsoA;

  @override
  Future<void> runOnIsoA(IsolateA iso) async {
    print(
        "ManyCallsBetweenIsolatesViaNewThreadBlocking.runOnIsoA sending messages.");
    await Future.wait(List.filled(100, null).map((_) async {
      final result = iso.atm.call((responseId) => iso.natLib
          .callFunctionOnNewThreadBlocking(
              responseId, Pointer.fromAddress(iso.fnPtrsB.addGlobalVarPtr)));
      Expect.equals(2123, await result);
    }));
  }

  @override
  Future<void> runOnIsoB(IsolateB iso) async {
    print(
        "ManyCallsBetweenIsolatesViaNewThreadBlocking.runOnIsoB sending messages.");
    await Future.wait(List.filled(100, null).map((_) async {
      final result = iso.atm.call((responseId) => iso.natLib
          .callFunctionOnNewThreadBlocking(
              responseId, Pointer.fromAddress(iso.fnPtrsA.addGlobalVarPtr)));
      Expect.equals(1123, await result);
    }));
  }
}

class ManyCallsBetweenIsolatesViaNewThreadNonBlocking extends TestCase {
  @override
  SendPort? sendIsoAResultsTo(AsyncTestManager atm) => atm.toIsoB;

  @override
  SendPort? sendIsoBResultsTo(AsyncTestManager atm) => atm.toIsoA;

  @override
  Future<void> runOnIsoA(IsolateA iso) async {
    print(
        "ManyCallsBetweenIsolatesViaNewThreadNonBlocking.runOnIsoA sending messages.");
    await Future.wait(List.filled(100, null).map((_) async {
      final result = iso.atm.call((responseId) => iso.natLib
          .callFunctionOnNewThreadNonBlocking(
              responseId, Pointer.fromAddress(iso.fnPtrsB.addGlobalVarPtr)));
      Expect.equals(2123, await result);
    }));
  }

  @override
  Future<void> runOnIsoB(IsolateB iso) async {
    print(
        "ManyCallsBetweenIsolatesViaNewThreadNonBlocking.runOnIsoB sending messages.");
    await Future.wait(List.filled(100, null).map((_) async {
      final result = iso.atm.call((responseId) => iso.natLib
          .callFunctionOnNewThreadNonBlocking(
              responseId, Pointer.fromAddress(iso.fnPtrsA.addGlobalVarPtr)));
      Expect.equals(1123, await result);
    }));
  }
}

class AsyncTestManager {
  int _lastResponseId = 0;
  final _pending = <int, Completer<Object>>{};
  final _recvPort = ReceivePort("AsyncTestManager");

  late final SendPort toIsoA;
  late final SendPort toIsoB;
  SendPort get toThis => _recvPort.sendPort;

  AsyncTestManager(this._lastResponseId) {
    _recvPort.listen((msg) {
      final response = msg as List;
      final id = response[0];
      final value = response[1];
      _pending[id]!.complete(value);
      _pending.remove(id);
    });
  }

  Future<Object> call(void Function(int) asyncFunc) {
    final responseId = ++_lastResponseId;
    final completer = Completer<Object>();
    _pending[responseId] = completer;
    asyncFunc(responseId);
    return completer.future;
  }

  void close() {
    _recvPort.close();
  }
}

SendPort? _callbackResultPort;

void addGlobalVar(int responseId, int x) {
  final result = x + globalVar;
  _callbackResultPort!.send([responseId, result]);
}

void callFromIsoBToAAndMultByGlobalVar(int responseIdToA, int x) {
  final iso = IsolateB.instance!;
  iso.atm
      .call((responseIdToB) => iso.natLib.callFunctionOnSameThread(
          responseIdToB, Pointer.fromAddress(iso.fnPtrsA.addGlobalVarPtr)))
      .then((response) {
    final result = (response as int) * globalVar;
    _callbackResultPort!.send([responseIdToA, result]);
  });
  print("callFromIsoBToAAndMultByGlobalVar message sent. Awaiting result...");
}

void callFromIsoAToBAndMultByGlobalVar(int responseIdToB, int x) {
  final iso = IsolateA.instance!;
  iso.atm
      .call((responseIdToA) => iso.natLib.callFunctionOnSameThread(
          responseIdToA, Pointer.fromAddress(iso.fnPtrsB.addGlobalVarPtr)))
      .then((response) {
    final result = (response as int) * globalVar;
    _callbackResultPort!.send([responseIdToB, result]);
  });
  print("callFromIsoAToBAndMultByGlobalVar message sent. Awaiting result...");
}

typedef CallbackNativeType = Void Function(Int64, Int32);

class Callbacks {
  final NativeCallable addGlobalVarFn;
  final NativeCallable callFromIsoBToAAndMultByGlobalVarFn;
  final NativeCallable callFromIsoAToBAndMultByGlobalVarFn;

  Callbacks()
      : addGlobalVarFn =
            NativeCallable<CallbackNativeType>.listener(addGlobalVar),
        callFromIsoBToAAndMultByGlobalVarFn =
            NativeCallable<CallbackNativeType>.listener(
                callFromIsoBToAAndMultByGlobalVar),
        callFromIsoAToBAndMultByGlobalVarFn =
            NativeCallable<CallbackNativeType>.listener(
                callFromIsoAToBAndMultByGlobalVar);

  void close() {
    addGlobalVarFn.close();
    callFromIsoBToAAndMultByGlobalVarFn.close();
    callFromIsoAToBAndMultByGlobalVarFn.close();
  }
}

class FnPtrs {
  // Storing function pointers as ints so they can be sent to other isolates.
  final int addGlobalVarPtr;
  final int callFromIsoBToAAndMultByGlobalVarPtr;
  final int callFromIsoAToBAndMultByGlobalVarPtr;

  FnPtrs._(this.addGlobalVarPtr, this.callFromIsoBToAAndMultByGlobalVarPtr,
      this.callFromIsoAToBAndMultByGlobalVarPtr);

  static FnPtrs fromCallbacks(Callbacks callbacks) => FnPtrs._(
        callbacks.addGlobalVarFn.nativeFunction.address,
        callbacks.callFromIsoBToAAndMultByGlobalVarFn.nativeFunction.address,
        callbacks.callFromIsoAToBAndMultByGlobalVarFn.nativeFunction.address,
      );

  static FnPtrs fromList(List<int> ptrs) => FnPtrs._(ptrs[0], ptrs[1], ptrs[2]);
  List<int> toList() => [
        addGlobalVarPtr,
        callFromIsoBToAAndMultByGlobalVarPtr,
        callFromIsoAToBAndMultByGlobalVarPtr,
      ];
}

typedef FnRunnerNativeType = Void Function(Int64, Pointer);
typedef FnRunnerType = void Function(int, Pointer);

class NativeLibrary {
  late final FnRunnerType callFunctionOnSameThread;
  late final FnRunnerType callFunctionOnNewThreadBlocking;
  late final FnRunnerType callFunctionOnNewThreadNonBlocking;

  NativeLibrary() {
    callFunctionOnSameThread =
        ffiTestFunctions.lookupFunction<FnRunnerNativeType, FnRunnerType>(
            "CallFunctionOnSameThread");
    callFunctionOnNewThreadBlocking =
        ffiTestFunctions.lookupFunction<FnRunnerNativeType, FnRunnerType>(
            "CallFunctionOnNewThreadBlocking");
    callFunctionOnNewThreadNonBlocking =
        ffiTestFunctions.lookupFunction<FnRunnerNativeType, FnRunnerType>(
            "CallFunctionOnNewThreadNonBlocking");
  }
}

class TestCase {
  SendPort? sendIsoAResultsTo(AsyncTestManager atm) => null;
  SendPort? sendIsoBResultsTo(AsyncTestManager atm) => null;
  Future<void> runOnIsoA(IsolateA isoA) async {}
  Future<void> runOnIsoB(IsolateB isoB) async {}
}

class TestCaseSendPort {
  final SendPort sendPort;
  TestCaseSendPort(this.sendPort);
}

// IsolateA is the main isolate of the test. It spawns IsolateB.
class IsolateA {
  static IsolateA? instance;
  late final SendPort sendPort;
  final recvPort = ReceivePort("Isolate A ReceivePort");
  final atm = AsyncTestManager(1000000);
  final natLib = NativeLibrary();
  final callbacksA = Callbacks();
  late final FnPtrs fnPtrsA;
  late final FnPtrs fnPtrsB;
  final bool sameGroup;

  IsolateA(this.sameGroup) {
    instance = this;
    fnPtrsA = FnPtrs.fromCallbacks(callbacksA);
    atm.toIsoA = atm.toThis;
    print("IsolateA fn ptr: ${fnPtrsA.addGlobalVarPtr.toRadixString(16)}");
  }

  Future<void> messageLoop() async {
    if (sameGroup) {
      await Isolate.spawn(IsolateB.entryPoint, recvPort.sendPort);
    } else {
      await Isolate.spawnUri(Platform.script, [], recvPort.sendPort);
    }
    int testIndex = 0;
    await for (final List msg in recvPort) {
      final cmd = msg[0] as String;
      final arg = msg[1];
      if (cmd == 'sendPort') {
        sendPort = arg;
        sendPort.send(['testPort', atm.toThis]);
        sendPort.send(['fnPtrs', fnPtrsA.toList()]);
      } else if (cmd == 'fnPtrs') {
        fnPtrsB = FnPtrs.fromList(arg);
      } else if (cmd == 'testPort') {
        atm.toIsoB = arg;
      } else if (cmd == 'next') {
        if (testIndex >= messagePassingTestCases.length) {
          sendPort.send(['exit', null]);
        } else {
          _callbackResultPort = null;
          sendPort.send(['testCase', testIndex]);
          final testCase = messagePassingTestCases[testIndex];
          print('\nRunning $testCase on IsoA');
          _callbackResultPort = testCase.sendIsoAResultsTo(atm);
        }
      } else if (cmd == 'run') {
        final testCase = messagePassingTestCases[testIndex];
        await testCase.runOnIsoA(this);
        print('Running $testCase on IsoA DONE\n');
        testIndex += 1;
        sendPort.send(['next', null]);
      } else if (cmd == 'exit') {
        break;
      } else {
        Expect.fail('Unknown message: $msg');
        break;
      }
    }
  }

  void close() {
    print("Closing Isolate A");
    recvPort.close();
    atm.close();
    callbacksA.close();
  }
}

// IsolateB is the secondary isolate of the test. It's spawned by IsolateA.
class IsolateB {
  static IsolateB? instance;
  final SendPort sendPort;
  final recvPort = ReceivePort("Isolate B ReceivePort");
  final atm = AsyncTestManager(2000000);
  final natLib = NativeLibrary();
  final callbacksB = Callbacks();
  late final FnPtrs fnPtrsA;
  late final FnPtrs fnPtrsB;

  IsolateB(this.sendPort) {
    instance = this;
    fnPtrsB = FnPtrs.fromCallbacks(callbacksB);
    atm.toIsoB = atm.toThis;
    print("IsolateB fn ptr: ${fnPtrsB.addGlobalVarPtr.toRadixString(16)}");
    sendPort.send(['sendPort', recvPort.sendPort]);
    sendPort.send(['testPort', atm.toThis]);
    sendPort.send(['fnPtrs', fnPtrsB.toList()]);
    sendPort.send(['next', null]);
  }

  Future<void> messageLoop() async {
    await for (final List msg in recvPort) {
      final cmd = msg[0] as String;
      final arg = msg[1];
      if (cmd == 'fnPtrs') {
        fnPtrsA = FnPtrs.fromList(arg);
      } else if (cmd == 'testPort') {
        atm.toIsoA = arg;
      } else if (cmd == 'testCase') {
        final testCase = messagePassingTestCases[arg];
        _callbackResultPort = testCase.sendIsoBResultsTo(atm);
        sendPort.send(['run', null]);
        print('\nRunning $testCase on IsoB');
        await testCase.runOnIsoB(this);
        print('Running $testCase on IsoB DONE\n');
      } else if (cmd == 'next') {
        _callbackResultPort = null;
        sendPort.send(['next', null]);
      } else if (cmd == 'exit') {
        sendPort.send(['exit', null]);
        break;
      } else {
        Expect.fail('Unknown message: $msg');
        break;
      }
    }
  }

  void close() {
    print("Closing Isolate B");
    recvPort.close();
    atm.close();
    callbacksB.close();
  }

  static Future<void> entryPoint(SendPort sendPort) async {
    globalVar = 2000;
    final isolateB = IsolateB(sendPort);
    await isolateB.messageLoop();
    isolateB.close();
  }
}
