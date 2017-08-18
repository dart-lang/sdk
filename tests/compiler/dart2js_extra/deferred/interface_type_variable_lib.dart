// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class I<T> {}

// C needs to include "N", otherwise checking for `is I<A>` will likely cause
// problems
class C extends A implements I<N> {}

class N extends A {}

doCheck(x) => x is I<A>;
