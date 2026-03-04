// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:test/fake.dart';

/// Fake implementation of [DartRuntimeServiceBackend] that throws when
/// accessed.
///
/// Use when testing functionality of [DartRuntimeService] that does not require
/// a backend implementation.
base class FakeDartRuntimeServiceBackend extends Fake
    implements DartRuntimeServiceBackend {
  @override
  Future<void> shutdown() async {}
}
