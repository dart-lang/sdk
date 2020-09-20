// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class I<X, Y> {}

mixin M0<T> implements I<T, int> {}

mixin M1<T> implements I<String, T> {}

//////////////////////////////////////////////////////
// Inference is not bi-directional
///////////////////////////////////////////////////////


// M0<String>, M1<int> is a solution, but we shouldn't find it
// M0 inferred as M0<dynamic>
// M1 inferred as M1<dynamic>
class A with M0, M1 {} /*@compile-error=unspecified*/

void main() {}