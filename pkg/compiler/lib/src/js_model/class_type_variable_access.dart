// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Enum that defines how a member has access to the current type variables.
enum ClassTypeVariableAccess {
  /// The member has no access to type variables.
  none,

  /// Type variables are accessible as a property on `this`.
  property,

  /// Type variables are accessible as parameters in the current context.
  parameter,

  /// If the current context is a generative constructor, type variables are
  /// accessible as parameters, otherwise type variables are accessible as
  /// a property on `this`.
  ///
  /// This is used for instance fields whose initializers are executed in the
  /// constructors.
  // TODO(johnniwinther): Avoid the need for this by adding a field-setter
  // to the J-model.
  instanceField,
}
