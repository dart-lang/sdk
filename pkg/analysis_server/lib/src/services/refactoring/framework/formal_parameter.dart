// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The kind of a formal parameter.
enum FormalParameterKind {
  requiredPositional,
  optionalPositional,
  requiredNamed,
  optionalNamed;

  bool get isNamed {
    return this == requiredNamed || this == optionalNamed;
  }

  bool get isOptionalPositional {
    return this == optionalPositional;
  }

  bool get isPositional {
    return this == requiredPositional || this == optionalPositional;
  }
}
