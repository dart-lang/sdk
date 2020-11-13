// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Sample showing how to do calls from C into Dart through native ports.
//
// This sample does not use FFI callbacks to do the callbacks at all. Instead,
// it sends a message to Dart through native ports, decodes the message in Dart
// does a method call in Dart and sends the result back to C through a native
// port.
//
// The disadvantage of this approach compared to `sample_async_callback.dart`
// is that it requires more boilerplate, because it does not use the automatic
// marshalling of data of the FFI.
//
// The advantage is that finalizers can be used when passing ownership of data
// (buffers) from C to Dart.

// @dart = 2.9

import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:expect/expect.dart';

import '../dylib_utils.dart';

var globalResult = 0;
var numCallbacks1 = 0;
var numCallbacks2 = 0;

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

  final interactiveCppRequests = ReceivePort()..listen(handleCppRequests);
  final int nativePort = interactiveCppRequests.sendPort.nativePort;
  registerSendPort(nativePort);
  print("Dart: Tell C to start worker threads.");
  startWorkSimulator2();

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
  stopWorkSimulator2();
  interactiveCppRequests.close();
  print("Dart: Done.");
}

int myCallback1(int a) {
  print("Dart:     myCallback1($a).");
  numCallbacks1++;
  return a + 3;
}

void myCallback2(int a) {
  print("Dart:     myCallback2($a).");
  globalResult += a;
  numCallbacks2++;
}

class CppRequest {
  final SendPort replyPort;
  final int pendingCall;
  final String method;
  final Uint8List data;

  factory CppRequest.fromCppMessage(List message) {
    return CppRequest._(message[0], message[1], message[2], message[3]);
  }

  CppRequest._(this.replyPort, this.pendingCall, this.method, this.data);

  String toString() => 'CppRequest(method: $method, ${data.length} bytes)';
}

class CppResponse {
  final int pendingCall;
  final Uint8List data;

  CppResponse(this.pendingCall, this.data);

  List toCppMessage() => List.from([pendingCall, data], growable: false);

  String toString() => 'CppResponse(message: ${data.length})';
}

void handleCppRequests(dynamic message) {
  final cppRequest = CppRequest.fromCppMessage(message);
  print('Dart:   Got message: $cppRequest');

  if (cppRequest.method == 'myCallback1') {
    // Use the data in any way you like. Here we just take the first byte as
    // the argument to the function.
    final int argument = cppRequest.data[0];
    final int result = myCallback1(argument);
    final cppResponse =
        CppResponse(cppRequest.pendingCall, Uint8List.fromList([result]));
    print('Dart:   Responding: $cppResponse');
    cppRequest.replyPort.send(cppResponse.toCppMessage());
  } else if (cppRequest.method == 'myCallback2') {
    final int argument = cppRequest.data[0];
    myCallback2(argument);
  }
}

final dl = dlopenPlatformSpecific("ffi_test_functions");

final registerSendPort = dl.lookupFunction<Void Function(Int64 sendPort),
    void Function(int sendPort)>('RegisterSendPort');

final startWorkSimulator2 =
    dl.lookupFunction<Void Function(), void Function()>('StartWorkSimulator2');

final stopWorkSimulator2 =
    dl.lookupFunction<Void Function(), void Function()>('StopWorkSimulator2');

Future asyncSleep(int ms) {
  return new Future.delayed(Duration(milliseconds: ms), () => true);
}
