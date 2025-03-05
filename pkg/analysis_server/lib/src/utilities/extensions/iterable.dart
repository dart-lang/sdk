// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension IterableExtension<T> on Iterable<T> {
  /// Whether this Iterable contains any of [values].
  bool containsAny(Iterable<T> values) => values.any((v) => contains(v));
}
