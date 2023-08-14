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
//    ^^^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_GENERIC_INTERFACES
// [cfe] 'I with M0' can't implement both 'I<int>' and 'I<dynamic>'

class A01 extends J<int> with M1 {}
//    ^^^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_GENERIC_INTERFACES
// [cfe] 'J with M1' can't implement both 'J<int>' and 'J<dynamic>'

// Error since class hierarchy is inconsistent
class A02 extends A00 implements A01 {}
//    ^^^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_GENERIC_INTERFACES
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_GENERIC_INTERFACES
// [cfe] 'A02' can't implement both 'I<int>' and 'I<dynamic>'
// [cfe] 'A02' can't implement both 'J<dynamic>' and 'J<int>'

void main() {}
