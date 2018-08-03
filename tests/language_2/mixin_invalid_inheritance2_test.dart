// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> = Object with Malformed; // //# 01: compile-time error
class C<T> = Object with T; //         //# 02: compile-time error
class C<T> = OBject with T<int>; //    //# 03: compile-time error

main() {
  new C<C>(); // //# 01: continued
  new C<C>(); // //# 02: continued
  new C<C>(); // //# 03: continued
}
