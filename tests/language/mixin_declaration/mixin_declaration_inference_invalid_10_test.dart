// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin I<T> {}

mixin J<T> {}

mixin M0<T> implements I<T>, J<T> {}

//////////////////////////////////////////////////////
// Over-constrained results are caught
///////////////////////////////////////////////////////

class A with I<int>, J<double>, M0 {}
//    ^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_GENERIC_INTERFACES
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_GENERIC_INTERFACES
// [cfe] 'Object with I, J, M0' can't implement both 'I<int>' and 'I<dynamic>'
// [cfe] 'Object with I, J, M0' can't implement both 'J<double>' and 'J<dynamic>'

void main() {}
