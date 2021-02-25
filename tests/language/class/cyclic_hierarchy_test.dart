// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for cyclic class hierarchy seen in: https://github.com/flutter/flutter/issues/64011

class A extends B<C> {}

class C extends A {}

class B<T> {}

main() => print(A());
