// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test case exercises the code path in type constraint generation where
// `T?` is constrained by `Object` from above, where `T` is a type parameter.

foo(Object x) {}

T? bar<T>() => null;

main() => foo(bar /*T <: Object*/ ());
