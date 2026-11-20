// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/byte_store.dart';

/// A mixin that provides a shared [MemoryByteStore] across tests in the same
/// Dart VM run.
mixin ByteStoreTestMixin {
  /// The byte store that is reused between tests. This allows reusing all
  /// unlinked and linked summaries for SDK, so that tests run much faster.
  /// However nothing is preserved between Dart VM runs, so changes to the
  /// implementation are still fully verified.
  static final MemoryByteStore _sharedByteStore = MemoryByteStore();

  /// The byte store used by this test instance.
  MemoryByteStore _byteStore = _sharedByteStore;

  /// Gets the byte store used by this test instance, which defaults to
  /// [_sharedByteStore] but can be overridden by calling [useEmptyByteStore].
  MemoryByteStore get byteStore => _byteStore;

  /// Call this method if the test needs to use the empty byte store, without
  /// any information cached.
  void useEmptyByteStore() {
    _byteStore = MemoryByteStore();
  }
}
