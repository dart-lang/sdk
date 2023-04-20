// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class I<X> {}

mixin M0<T> on I<T> {}

///////////////////////////////////////////////////////
// Inference happens from superclasses to subclasses
///////////////////////////////////////////////////////

// Error since class hierarchy is inconsistent
class A00 extends I with M0<int> {}
//    ^
// [cfe] 'I with M0' can't implement both 'I<dynamic>' and 'I<int>'
// [cfe] 'I<dynamic>' doesn't implement 'I<int>' so it can't be used with 'M0<int>'.
//                       ^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE

void main() {}
