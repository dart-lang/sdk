// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Abstract base class for factories that can construct trees of expressions,
/// statements, initializers, and literal types based on tokens, inferred types,
/// and invocation targets.
///
/// TODO(paulberry): fill this with methods based on ResolutionStorer.
abstract class Factory<Expression, Statement, Initializer> {}
