// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class I<T> {}
class J<T> {}
mixin M0<T> implements I<T>, J<T> {}

//////////////////////////////////////////////////////
// Over-constrained results are caught
///////////////////////////////////////////////////////

class A with I<int>, J<double>, M0 {} /*@compile-error=unspecified*/

void main() {}