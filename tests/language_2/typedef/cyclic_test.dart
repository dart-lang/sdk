// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that cyclic reference of a typedef is a compile-time error.

// To test various cyclic references the definition of the [:typedef A():] is
// split over several lines:
typedef

// Cyclic through return type.
A //# 01: compile-time error

    A // The name of the typedef

// Cyclic through type variable bound.
<T extends A> //# 10: compile-time error

// Cyclic through generic type variable bound.
<T extends List<A>> //# 11: compile-time error

    (// The left parenthesis of the typedef arguments.

// Cyclic through parameter type.
A a //# 02: compile-time error

// Cyclic through optional parameter type.
[A a] //# 03: compile-time error

// Cyclic through named parameter type.
{A a} //# 04: compile-time error

// Cyclic through generic parameter type.
List<A> a //# 05: compile-time error

// Cyclic through return type of function typed parameter.
A f() //# 06: compile-time error

// Cyclic through parameter type of function typed parameter.
f(A a) //# 07: compile-time error

// Cyclic through another typedef.
B b //# 08: compile-time error

// Cyclic through another more typedefs.
C c //# 09: compile-time error

// Reference through a class is not a cyclic self-reference.
Class c //# 12: ok

// Reference through a class type bound is not a cyclic self-reference.
Class c //# 13: compile-time error

    ); // The right parenthesis of the typedef arguments.

typedef B(A a);
typedef C(B b);

class Class
<T extends A> //# 13: continued
{
  A a; //# 12: continued
}

void testA(A a) {}

void main() {
  testA(null);
}
