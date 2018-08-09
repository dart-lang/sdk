// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../kernel/kernel_ast_api.dart' show DartType, Node;

/// Callback interface used by builders to report the results of resolution
/// in library outlines to a client.
class OutlineListener {
  /// Stores given resolution data at the given [offset].
  ///
  /// If the token for which the data is stored is synthetic, then [isSynthetic]
  /// is set to `true`.
  ///
  /// [importIndex] is the index of the import directive in the library, and
  /// is used to store import prefixes.
  ///
  /// [reference] is the referenced declaration - a class, a typedef, a type
  /// parameter, etc.
  ///
  /// [type] is the type that was build from the [reference], for example code
  /// `List<int>` will have a reference to `List` and type `List<int>`, i.e.
  /// with type arguments applied.
  void store(int offset, bool isSynthetic,
      {int importIndex, Node reference, DartType type}) {}
}
