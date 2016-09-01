// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.target.vm;

import 'targets.dart';
import '../ast.dart';
import '../transformations/mixin_full_resolution.dart' as mix;

/// Specializes the kernel IR to the Dart VM.
class VmTarget extends Target {
  String get name => 'vm';

  // This is the order that bootstrap libraries are loaded according to
  // `runtime/vm/object_store.h`.
  List<String> get extraRequiredLibraries => const <String>[
    'dart:async',
    'dart:collection',
    'dart:convert',
    'dart:developer',
    'dart:_internal',
    'dart:isolate',
    'dart:math',

    // dart:mirrors is required except in the PRODUCT configuration.
    // It is excluded here because the ahead-of time compiler uses the PRODUCT
    // configuration.

    'dart:profiler',
    'dart:typed_data',
    'dart:_vmservice',
  ];

  void transformProgram(Program program) {
    new mix.MixinFullResolution().transform(program);
  }
}
