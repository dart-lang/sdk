// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.reflected_type_classes;

@MirrorsUsed(targets: "test.reflected_type_classes")
import 'dart:mirrors';

import 'reflected_type_helper.dart';

class A<T> {}

class B extends A {}

class C extends A<num, int> {} // //# 01: static type warning
class D extends A<int> {}

class E<S> extends A<S> {}

class F<R> extends A<int> {}

class G {}

class H<A, B, C> {}

main() {
  // Declarations.
  expectReflectedType(reflectClass(A), null);
  expectReflectedType(reflectClass(B), B);
  expectReflectedType(reflectClass(C), C); // //# 01: continued
  expectReflectedType(reflectClass(D), D);
  expectReflectedType(reflectClass(E), null);
  expectReflectedType(reflectClass(F), null);
  expectReflectedType(reflectClass(G), G);
  expectReflectedType(reflectClass(H), null);

  // Instantiations.
  expectReflectedType(reflect(new A()).type, new A().runtimeType);
  expectReflectedType(reflect(new B()).type, new B().runtimeType);
  expectReflectedType(reflect(new C()).type, new C().runtimeType); // //# 01: continued
  expectReflectedType(reflect(new D()).type, new D().runtimeType);
  expectReflectedType(reflect(new E()).type, new E().runtimeType);
  expectReflectedType(reflect(new F()).type, new F().runtimeType);
  expectReflectedType(reflect(new G()).type, new G().runtimeType);
  expectReflectedType(reflect(new H()).type, new H().runtimeType);

  expectReflectedType(reflect(new A<num>()).type, new A<num>().runtimeType);
  expectReflectedType(reflect(new B<num>()).type.superclass, // //# 02: static type warning
                      new A<dynamic>().runtimeType); //         //# 02: continued
  expectReflectedType(reflect(new C<num>()).type.superclass, // //# 01: continued
                      new A<dynamic>().runtimeType); //         //# 01: continued
  expectReflectedType(reflect(new D<num>()).type.superclass, // //# 03: static type warning
                      new A<int>().runtimeType); //             //# 03: continued
  expectReflectedType(reflect(new E<num>()).type, new E<num>().runtimeType);
  expectReflectedType(
      reflect(new E<num>()).type.superclass, new A<num>().runtimeType);
  expectReflectedType(
      reflect(new F<num>()).type.superclass, new A<int>().runtimeType);
  expectReflectedType(reflect(new F<num>()).type, new F<num>().runtimeType);
  expectReflectedType(
      reflect(new H<num, num, num>()).type, new H<num, num, num>().runtimeType);
}
