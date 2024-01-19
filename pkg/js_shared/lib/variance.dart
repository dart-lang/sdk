// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Types of variances for type parameters.
/// This needs to be kept in sync with values of `Variance` in `dart:_rti`.
enum Variance { legacyCovariant, covariant, contravariant, invariant }
