// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/expect.dart';

// Regression test for https://github.com/dart-lang/sdk/issues/45767.

class I<T> {}

class F<E extends F<E>> extends I<E> {}

// Extending F forces DDC to defer the superclass and trigger the bug
class A<T> extends F<A<Object?>> {}

class B<T> extends F<B<T?>> {}

void main() {
  Expect.isTrue(A<bool>() is I<A<Object?>>);
  Expect.equals(!hasSoundNullSafety, A<bool>() is I<A<Object>>);
  Expect.isTrue(B<bool>() is I<B<bool?>>);
  Expect.equals(!hasSoundNullSafety, B<bool>() is I<B<bool>>);
}
