// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class I<T> {}
mixin M1<T> on I<T> {}

//////////////////////////////////////////////////////
// Mixin type argument inference is not performed on
// the "on" clause of a mixin
///////////////////////////////////////////////////////

mixin A00Mixin on I<int>, M1 {} /*@compile-error=unspecified*/

void main() {}