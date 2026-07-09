// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

// Add an unused import to see that we're using actually the package config.
// Note, this will also succeed when using the dart-sdk package config.
// We will inherit that config if doing Isolate.spawnUri from within the SDK.
// The proper way to test Isolate.spawnUri is to do it from a Dart file run
// from a temp folder.
// ignore: unused_import
import 'package:meta/meta.dart';

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
