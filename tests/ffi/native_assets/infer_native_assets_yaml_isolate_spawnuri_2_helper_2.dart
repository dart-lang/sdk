// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

void main(List<String> args, Object? message) {
  print('run tests');
  print('Platform.packageConfig: ${Platform.packageConfig}');
  final sendPort = message as SendPort;
  try {
    final result = sumPlus42(3, 4);
    sendPort.send(result);
  } catch (e, st) {
    sendPort.send([e.toString(), st.toString()]);
  }
  print('run done');
}

@Native<Int32 Function(Int32, Int32)>(symbol: 'SumPlus42')
external int sumPlus42(int a, int b);
