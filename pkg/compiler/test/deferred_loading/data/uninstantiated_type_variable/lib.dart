// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// All of these types are considered instantiated because we create an instance
// of [C].

/*class: A:
 class_unit=1{lib},
 type_unit=1{lib}
*/
/*member: A.:member_unit=1{lib}*/
class A {}

/*class: Box:
 class_unit=1{lib},
 type_unit=1{lib}
*/
/*member: Box.:member_unit=1{lib}*/
class Box<T> {
  /*member: Box.value:member_unit=1{lib}*/
  int value;
}

/*class: B:
 class_unit=1{lib},
 type_unit=1{lib}
*/
/*member: B.:member_unit=1{lib}*/
class B<T> extends A {
  /*member: B.box:member_unit=1{lib}*/
  final box = new Box<T>();
}

/*class: C:
 class_unit=1{lib},
 type_unit=1{lib}
*/
/*member: C.:member_unit=1{lib}*/
class C extends B<N> {}

// N is not instantiated, but used as a type argument in C and indirectly in a
// Box<N>.
// If we don't mark it as part of the output unit of C, we accidentally add it
// to the main output unit. However, A is in the output unit of C so we fail
// when trying to finalize the declaration of N while loading the main output
// unit.
/*class: N:
 class_unit=none,
 type_unit=1{lib}
*/
class N extends A {}
