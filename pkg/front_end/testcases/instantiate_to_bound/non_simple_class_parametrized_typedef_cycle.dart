// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that the cyclic non-simplicity issues are detected in case
// when both class declaration and a parametrized typedef participate in the
// cycle.

class Class1<X1 extends Typedef1> {}

typedef Typedef1 = void Function<Y1 extends Class1>();

class Class2<X2 extends Typedef2> {}

typedef Typedef2 = void Function<Y2 extends (Class2, int)>();

class Class3<X3 extends Typedef3> {}

typedef Typedef3 = (void Function<Y3 extends Class3>(), int);

main() {}
