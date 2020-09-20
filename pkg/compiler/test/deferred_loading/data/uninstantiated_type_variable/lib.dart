// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// All of these types are considered instantiated because we create an instance
// of [C].

/*class: A:OutputUnit(1, {lib}), type=OutputUnit(1, {lib})*/
/*member: A.:OutputUnit(1, {lib})*/
class A {}

/*class: Box:OutputUnit(1, {lib}), type=OutputUnit(1, {lib})*/
/*member: Box.:OutputUnit(1, {lib})*/
class Box<T> {
  /*member: Box.value:OutputUnit(1, {lib})*/
  int value;
}

/*class: B:OutputUnit(1, {lib}), type=OutputUnit(1, {lib})*/
/*member: B.:OutputUnit(1, {lib})*/
class B<T> extends A {
  /*member: B.box:OutputUnit(1, {lib})*/
  final box = new Box<T>();
}

/*class: C:OutputUnit(1, {lib}), type=OutputUnit(1, {lib})*/
/*member: C.:OutputUnit(1, {lib})*/
class C extends B<N> {}

// N is not instantiated, but used as a type argument in C and indirectly in a
// Box<N>.
// If we don't mark it as part of the output unit of C, we accidentally add it
// to the main output unit. However, A is in the output unit of C so we fail
// when trying to finalize the declaration of N while loading the main output
// unit.
/*class: N:none, type=OutputUnit(1, {lib})*/
class N extends A {}
