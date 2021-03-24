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

class C8 {
  int? bad;
}

userDefinableBinaryOpRhs(C8 c) {
  if (c.bad == null) return;
  1 +
      /*analyzer.notPromoted(propertyNotPromoted(target: member:C8.bad, type: int?))*/ c
          . /*cfe.notPromoted(propertyNotPromoted(target: member:C8.bad, type: int?))*/ bad;
}

class C9 {
  int? bad;
  f(int i) {}
}

questionQuestionRhs(C9 c, int? i) {
  // Note: "why not supported" functionality is currently not supported for the
  // RHS of `??` because it requires more clever reasoning than we currently do:
  // we would have to understand that the reason `i ?? c.bad` has a type of
  // `int?` rather than `int` is because `c.bad` was not promoted.  We currently
  // only support detecting non-promotion when the expression that had the wrong
  // type *is* the expression that wasn't promoted.
  if (c.bad == null) return;
  c.f(i ?? c.bad);
}

class C10 {
  D10? bad;
  f(bool b) {}
}

class D10 {
  bool operator ==(covariant D10 other) => true;
}

equalRhs(C10 c, D10 d) {
  if (c.bad == null) return;
  // Note: we don't report an error here because `==` always accepts `null`.
  c.f(d == c.bad);
  c.f(d != c.bad);
}

class C11 {
  bool? bad;
  f(bool b) {}
}

andOperand(C11 c, bool b) {
  if (c.bad == null) return;
  c.f(
      /*analyzer.notPromoted(propertyNotPromoted(target: member:C11.bad, type: bool?))*/ c
              . /*cfe.notPromoted(propertyNotPromoted(target: member:C11.bad, type: bool?))*/ bad &&
          b);
  c.f(b &&
      /*analyzer.notPromoted(propertyNotPromoted(target: member:C11.bad, type: bool?))*/ c
          . /*cfe.notPromoted(propertyNotPromoted(target: member:C11.bad, type: bool?))*/ bad);
}

class C12 {
  bool? bad;
  f(bool b) {}
}

orOperand(C12 c, bool b) {
  if (c.bad == null) return;
  c.f(
      /*analyzer.notPromoted(propertyNotPromoted(target: member:C12.bad, type: bool?))*/ c
              . /*cfe.notPromoted(propertyNotPromoted(target: member:C12.bad, type: bool?))*/ bad ||
          b);
  c.f(b ||
      /*analyzer.notPromoted(propertyNotPromoted(target: member:C12.bad, type: bool?))*/ c
          . /*cfe.notPromoted(propertyNotPromoted(target: member:C12.bad, type: bool?))*/ bad);
}
