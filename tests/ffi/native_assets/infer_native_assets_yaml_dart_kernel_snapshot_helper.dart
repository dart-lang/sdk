// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';

// Add an unused import to see that we're using actually the package config.
// ignore: unused_import
import 'package:meta/meta.dart';

void main() {
  print('run tests');
  print('Platform.packageConfig: ${Platform.packageConfig}');

  final result = sumPlus42(3, 4);
  print(result);

  print('run done');
}

@Native<Int32 Function(Int32, Int32)>(symbol: 'SumPlus42')
external int sumPlus42(int a, int b);
