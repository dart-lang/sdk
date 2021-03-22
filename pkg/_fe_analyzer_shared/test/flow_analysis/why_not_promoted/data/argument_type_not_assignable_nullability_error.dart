// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test contains a test case for each condition that can lead to the front
// end's `ArgumentTypeNotAssignableNullability` error, for which we wish to
// report "why not promoted" context information.

class C1 {
  int? bad;
  f(int i) {}
}

required_unnamed(C1 c) {
  if (c.bad == null) return;
  c.f(
      /*analyzer.notPromoted(propertyNotPromoted(target: member:C1.bad, type: int?))*/ c
          . /*cfe.notPromoted(propertyNotPromoted(target: member:C1.bad, type: int?))*/ bad);
}

class C2 {
  int? bad;
  f([int i = 0]) {}
}

optional_unnamed(C2 c) {
  if (c.bad == null) return;
  c.f(
      /*analyzer.notPromoted(propertyNotPromoted(target: member:C2.bad, type: int?))*/ c
          . /*cfe.notPromoted(propertyNotPromoted(target: member:C2.bad, type: int?))*/ bad);
}

class C3 {
  int? bad;
  f({required int i}) {}
}

required_named(C3 c) {
  if (c.bad == null) return;
  c.f(
      /*analyzer.notPromoted(propertyNotPromoted(target: member:C3.bad, type: int?))*/ i:
          c. /*cfe.notPromoted(propertyNotPromoted(target: member:C3.bad, type: int?))*/ bad);
}

class C4 {
  int? bad;
  f({int i = 0}) {}
}

optional_named(C4 c) {
  if (c.bad == null) return;
  c.f(
      /*analyzer.notPromoted(propertyNotPromoted(target: member:C4.bad, type: int?))*/ i:
          c. /*cfe.notPromoted(propertyNotPromoted(target: member:C4.bad, type: int?))*/ bad);
}

class C5 {
  List<int>? bad;
  f<T>(List<T> x) {}
}

type_inferred(C5 c) {
  if (c.bad == null) return;
  c.f(
      /*analyzer.notPromoted(propertyNotPromoted(target: member:C5.bad, type: List<int>?))*/ c
          . /*cfe.notPromoted(propertyNotPromoted(target: member:C5.bad, type: List<int>?))*/ bad);
}

class C6 {
  int? bad;
  C6(int i);
}

C6 constructor_with_implicit_new(C6 c) {
  if (c.bad == null) return;
  return C6(
      /*analyzer.notPromoted(propertyNotPromoted(target: member:C6.bad, type: int?))*/ c
          . /*cfe.notPromoted(propertyNotPromoted(target: member:C6.bad, type: int?))*/ bad);
}

class C7 {
  int? bad;
  C7(int i);
}

C7 constructor_with_explicit_new(C7 c) {
  if (c.bad == null) return;
  return new C7(
      /*analyzer.notPromoted(propertyNotPromoted(target: member:C7.bad, type: int?))*/ c
          . /*cfe.notPromoted(propertyNotPromoted(target: member:C7.bad, type: int?))*/ bad);
}
