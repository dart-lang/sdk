// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Enum values for how the target of a static type should be interpreted.
// TODO(48820): Move this back to static_type.dart
enum ClassRelation {
  /// The target is any subtype of the static type.
  subtype,

  /// The target is a subclass or mixin application of the static type.
  ///
  /// This corresponds to accessing a member through a this expression.
  thisExpression,

  /// The target is an exact instance of the static type.
  exact,
}
