// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "mixin_constructor_parameter_forwarding_test.dart";

// A private class that the mixin application cannot access syntactically,
// yet it needs an instance of it for the default value.
class _Private {
  const _Private();
}

class B2<T> implements B<T> {
  final T x;
  final Object y;
  const B2(T x, [Object y = const _Private()])
      : x = x,
        y = y;
}

// Leaking the constant value in a non-constant way which cannot be used
// for the default value of the mixin application.
Object get privateValue => const _Private();
