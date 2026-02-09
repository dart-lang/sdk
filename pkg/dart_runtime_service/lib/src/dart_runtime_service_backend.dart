// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart_runtime_service.dart';

/// A backend implementation of a service used to inject non-common
/// functionality into a [DartRuntimeService].
abstract class DartRuntimeServiceBackend {
  Future<void> shutdown();
}
