// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

class I<X> {}

mixin M0<T> implements I<T> {}

//////////////////////////////////////////////////////
// Inference does not use implements constraints on mixin
///////////////////////////////////////////////////////

// Error since class hierarchy is inconsistent
class A00 with M0 implements I<int> {}
//    ^^^
// [analyzer] COMPILE_TIME_ERROR.CONFLICTING_GENERIC_INTERFACES
// [cfe] 'A00' can't implement both 'I<dynamic>' and 'I<int>'

void main() {}
