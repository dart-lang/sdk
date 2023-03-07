// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/exhaustiveness/exhaustive.dart'
    as shared_exhaustive;

/// Runs [callback] with the full exhaustiveness algorithm enabled.
///
/// TODO(paulberry): remove this function (and the implementation of the
/// fallback exhaustiveness algorithm) when it is no longer needed.
Future<T> withFullExhaustivenessAlgorithm<T>(
    Future<T> Function() callback) async {
  var oldUseFallback = shared_exhaustive.useFallbackExhaustivenessAlgorithm;
  shared_exhaustive.useFallbackExhaustivenessAlgorithm = false;
  try {
    return await callback();
  } finally {
    shared_exhaustive.useFallbackExhaustivenessAlgorithm = oldUseFallback;
  }
}
