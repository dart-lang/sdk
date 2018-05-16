// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.target.dart_runner;

import 'package:kernel/target/targets.dart';
import 'package:kernel/target/vm.dart' show VmTarget;

class DartRunnerTarget extends VmTarget {
  DartRunnerTarget(TargetFlags flags) : super(flags);

  @override
  String get name => 'dart_runner';

  @override
  bool get enableSuperMixins => true;

  // This is the order that bootstrap libraries are loaded according to
  // `runtime/vm/object_store.h`.
  @override
  List<String> get extraRequiredLibraries => const <String>[
        'dart:async',
        'dart:collection',
        'dart:convert',
        'dart:developer',
        'dart:_internal',
        'dart:isolate',
        'dart:math',

        // The library dart:mirrors may be ignored by the VM, e.g. when built in
        // PRODUCT mode.
        'dart:mirrors',

        'dart:profiler',
        'dart:typed_data',
        'dart:nativewrappers',
        'dart:io',

        // Required for dart_runner.
        'dart:fuchsia.builtin',
        'dart:zircon',
        'dart:fuchsia',
        'dart:vmservice_io',
      ];
}
