// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that contravariant occurrences of mutually dependent type
// variables in the bounds of all of these type variables are replaced with
// Null.

class D<X extends void Function(X, Y), Y extends void Function(X, Y)> {}

D d;

class E<X extends void Function(X)> {}

E e;

main() {}
