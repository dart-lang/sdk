// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  void set setter(value) {}
  C operator [](index) => this;
  void operator []=(index, value) {}
  C get getterReturningC => this;
  C? get getterReturningNullableC => this;
}

class D {
  void set setter(value) {}
  D? operator [](index) => this;
  void operator []=(index, value) {}
}

void setterCall(C? c) {
  c?.setter = /*nonNullable*/ c;
}

void indexGetterCall(C? c) {
  c?.[/*nonNullable*/ c];
}

void indexSetterCall(C? c) {
  c?.[/*nonNullable*/ c] = /*nonNullable*/ c;
}

void setterCall_nullShorting(C? c, D? d) {
  c?.getterReturningC.setter = /*nonNullable*/ c;
  c?.getterReturningNullableC?.setter = /*nonNullable*/ c;
  c?.[0].setter = /*nonNullable*/ c;
  d?.[0]?.setter = /*nonNullable*/ d;
}

void indexGetterCall_nullShorting(C? c, D? d) {
  c?.getterReturningC[/*nonNullable*/ c];
  c?.getterReturningNullableC?.[/*nonNullable*/ c];
  c?.[0][/*nonNullable*/ c];
  d?.[0]?.[/*nonNullable*/ d];
}

void indexSetterCall_nullShorting(C? c, D? d) {
  c?.getterReturningC[/*nonNullable*/ c] = /*nonNullable*/ c;
  c?.getterReturningNullableC?.[/*nonNullable*/ c] = /*nonNullable*/ c;
  c?.[0][/*nonNullable*/ c] = /*nonNullable*/ c;
  d?.[0]?.[/*nonNullable*/ d] = /*nonNullable*/ d;
}

void null_aware_cascades_do_not_promote_target(C? c) {
  // Cascaded invocations act on an invisible temporary variable that
  // holds the result of evaluating the cascade target.  So
  // effectively, no promotion happens (because there is no way to
  // observe a change to the type of that variable).
  c?..setter = c;
  c?..[c];
  c?..[c] = c;
}

void null_aware_cascades_do_not_promote_others(C? c, int? i, int? j) {
  // Promotions that happen inside null-aware cascade sections
  // disappear after the cascade section, because they are not
  // guaranteed to execute.
  c?..setter = i!;
  c?..[i!];
  c?..[i!] = j!;
  i;
  j;
}

void normal_cascades_do_promote_others(C c, int? i, int? j, int? k, int? l) {
  // Promotions that happen inside non-null-aware cascade sections
  // don't disappear after the cascade section.
  c..setter = i!;
  c..[j!];
  c..[k!] = l!;
  /*nonNullable*/ i;
  /*nonNullable*/ j;
  /*nonNullable*/ k;
  /*nonNullable*/ l;
}
