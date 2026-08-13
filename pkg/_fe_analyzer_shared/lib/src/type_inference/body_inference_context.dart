// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';

/// Base class for data structures used by the analyzer and front end to keep
/// track of information about the innermost function or closure being type
/// inferred.
abstract interface class SharedBodyInferenceContext {
  /// Returns `true` if this is an `async` or an `async*` function.
  bool get isAsync;

  /// The typing expectation for the subexpression of a `yield` statement inside
  /// the function.
  ///
  /// For `sync*` and `async*` functions, the expected type is the element type
  /// of the generated `Iterable` or `Stream`, respectively.
  SharedTypeSchemaView get sharedYieldContext;
}
