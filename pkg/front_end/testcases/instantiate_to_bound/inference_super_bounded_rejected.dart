// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that super-bounded types that are produced by instantiate to
// bound are rejected when inferred as type arguments of constructor
// invocations.

class B<T extends Comparable<T>> {}

var y = new B();

main() {}
