// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for generic mixin fields in checked mode.

class A<T> {
  T field;
}

class B<T> = Object with A<T>;

class C<T> extends B<T> {} //# 03: ok
class D extends B<int> {} //# 04: ok

class E = Object with A<int>;

class F extends E {} //# 06: ok

class G<T> extends Object with A<T> {} //# 07: ok
class H extends Object with A<int> {} //# 08: ok

void main() {
  new A<num>(); //# 01: ok
  new B<num>(); //# 02: ok
  new C<num>(); //# 03: continued
  new D(); //# 04: continued
  new E(); //# 05: ok
  new F(); //# 06: continued
  new G<num>(); //# 07: continued
  new H(); //# 08: continued
}
