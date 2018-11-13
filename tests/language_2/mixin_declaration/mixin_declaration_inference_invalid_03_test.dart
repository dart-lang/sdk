// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class I<X> {}

mixin M0<T> implements I<T> {}

//////////////////////////////////////////////////////
// Inference happens from superclasses to subclasses
///////////////////////////////////////////////////////

// Error since class hierarchy is inconsistent
class A00 extends Object with M0 implements I<int> {} /*@compile-error=unspecified*/

void main() {}