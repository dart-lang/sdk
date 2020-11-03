// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Sample showing how to do async callbacks by telling the Dart isolate to
// yields its execution thread to C so it can perform the callbacks on the
// main Dart thread.
//
// TODO(dartbug.com/37022): Update this when we get real async callbacks.

// @dart = 2.9

import 'dart:ffi';
import 'dart:isolate';

import 'package:expect/expect.dart';

import '../dylib_utils.dart';

int globalResult = 0;
int numCallbacks1 = 0;
int numCallbacks2 = 0;

main() async {
  print("Dart = Dart mutator thread executing Dart.");
  print("C Da = Dart mutator thread executing C.");
  print("C T1 = Some C thread executing C.");
  print("C T2 = Some C thread executing C.");
  print("C    = C T1 or C T2.");
  print("Dart: Setup.");
  Expect.isTrue(NativeApi.majorVersion == 2);
  Expect.isTrue(NativeApi.minorVersion >= 0);
  final initializeApi = dl.lookupFunction<IntPtr Function(Pointer<Void>),
      int Function(Pointer<Void>)>("InitDartApiDL");
  Expect.isTrue(initializeApi(NativeApi.initializeApiDLData) == 0);

  final interactiveCppRequests = ReceivePort()..listen(requestExecuteCallback);
  final int nativePort = interactiveCppRequests.sendPort.nativePort;
  registerCallback1(nativePort, callback1FP);
  registerCallback2(nativePort, callback2FP);
  print("Dart: Tell C to start worker threads.");
  startWorkSimulator();

  // We need to yield control in order to be able to receive messages.
  while (numCallbacks2 < 3) {
    print("Dart: Yielding (able to receive messages on port).");
    await asyncSleep(500);
  }
  print("Dart: Received expected number of callbacks.");

  Expect.equals(2, numCallbacks1);
  Expect.equals(3, numCallbacks2);
  Expect.equals(14, globalResult);

  print("Dart: Tell C to stop worker threads.");
  stopWorkSimulator();
  interactiveCppRequests.close();
  print("Dart: Done.");
}

int callback1(int a) {
  print("Dart:     callback1($a).");
  numCallbacks1++;
  return a + 3;
}

void callback2(int a) {
  print("Dart:     callback2($a).");
  globalResult += a;
  numCallbacks2++;
}

void requestExecuteCallback(dynamic message) {
  final int work_address = message;
  final work = Pointer<Work>.fromAddress(work_address);
  print("Dart:   Calling into C to execute callback ($work).");
  executeCallback(work);
  print("Dart:   Done with callback.");
}

final callback1FP = Pointer.fromFunction<IntPtr Function(IntPtr)>(callback1, 0);

final callback2FP = Pointer.fromFunction<Void Function(IntPtr)>(callback2);

final dl = dlopenPlatformSpecific("ffi_test_functions");

final registerCallback1 = dl.lookupFunction<
        Void Function(Int64 sendPort,
            Pointer<NativeFunction<IntPtr Function(IntPtr)>> functionPointer),
        void Function(int sendPort,
            Pointer<NativeFunction<IntPtr Function(IntPtr)>> functionPointer)>(
    'RegisterMyCallbackBlocking');

final registerCallback2 = dl.lookupFunction<
        Void Function(Int64 sendPort,
            Pointer<NativeFunction<Void Function(IntPtr)>> functionPointer),
        void Function(int sendPort,
            Pointer<NativeFunction<Void Function(IntPtr)>> functionPointer)>(
    'RegisterMyCallbackNonBlocking');

final startWorkSimulator =
    dl.lookupFunction<Void Function(), void Function()>('StartWorkSimulator');

final stopWorkSimulator =
    dl.lookupFunction<Void Function(), void Function()>('StopWorkSimulator');

final executeCallback = dl.lookupFunction<Void Function(Pointer<Work>),
    void Function(Pointer<Work>)>('ExecuteCallback');

class Work extends Struct {}

Future asyncSleep(int ms) {
  return new Future.delayed(Duration(milliseconds: ms));
}
