// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';
import 'dart:ffi';

import 'package:expect/async_helper.dart' show asyncEnd, asyncStart;
import 'package:expect/expect.dart';
import 'package:ffi/ffi.dart';

@Native<Handle Function(Int64 port)>(symbol: 'Dart_NewSendPort')
external SendPort newSendPort(int obj);

@Native<Handle Function(Handle, Pointer<Int64>)>(symbol: 'Dart_SendPortGetId')
external Object sendPortGetId(Object sendPort, Pointer<Int64> outId);

final class PortEx extends Struct {
  @Int64()
  external int portId;
  @Int64()
  external int originId;
}

@Native<Handle Function(PortEx portex)>(symbol: 'Dart_NewSendPortEx')
external SendPort newSendPortEx(PortEx portEx);

@Native<Handle Function(Handle, Pointer<PortEx>)>(
    symbol: 'Dart_SendPortGetIdEx')
external Object sendPortGetIdEx(Object sendPort, Pointer<PortEx> outPortExId);

class A {}

main() async {
  asyncStart();

  final rp = ReceivePort();
  rp.close();

  {
    Pointer<Int64> portId = calloc();
    sendPortGetId(rp.sendPort, portId);
    final sendPortThroughAPI = newSendPort(portId.value);
    sendPortThroughAPI.send('A');
    Expect.throwsArgumentError(() {
      sendPortThroughAPI.send(A());
    });
    calloc.free(portId);
  }

  {
    Pointer<PortEx> portExId = calloc();
    sendPortGetIdEx(rp.sendPort, portExId);
    final sendPortThroughAPI = newSendPortEx(portExId[0]);
    sendPortThroughAPI.send('A');
    sendPortThroughAPI.send(A());
    calloc.free(portExId);
  }

  asyncEnd();
}
