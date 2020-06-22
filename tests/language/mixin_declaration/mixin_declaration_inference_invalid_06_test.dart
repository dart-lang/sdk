// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class I<X> {}
class J<X> {}

mixin M0<S, T> implements I<S>, J<T> {}

mixin M1<S, T> implements I<S>, J<T> {}

//////////////////////////////////////////////////////
// Inference does not use implements constraints on mixin
///////////////////////////////////////////////////////

class A00 extends I<int> with M0 {}

class A01 extends J<int> with M1 {}

// Error since class hierarchy is inconsistent
class A02 extends A00 implements A01 {} /*@compile-error=unspecified*/

void main() {}