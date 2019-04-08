// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/nullability/unit_propagation.dart';

/// Representation of a single node in the nullability inference graph.
///
/// Initially, this is just a wrapper over constraint variables, and the
/// nullability inference graph is encoded into the wrapped constraint
/// variables.  Over time this will be replaced by a first class representation
/// of the nullability inference graph.
class NullabilityNode {
  /// [ConstraintVariable] whose value will be set to `true` if this type needs
  /// to be nullable.
  ///
  /// If `null`, that means that an external constraint (outside the code being
  /// migrated) forces this type to be non-nullable.
  final ConstraintVariable nullable;

  /// [ConstraintVariable] whose value will be set to `true` if the usage of
  /// this type suggests that it is intended to be non-null (because of the
  /// presence of a statement or expression that would unconditionally lead to
  /// an exception being thrown in the case of a `null` value at runtime).
  ConstraintVariable nonNullIntent;

  NullabilityNode(this.nullable);
}
