// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

// Derived from
//     co19/LanguageFeatures/Extension-types/
//       static_analysis_member_invocation_A01_t05

class A {}

class B implements A {
  @override
  IntET get hashCode => IntET(super.hashCode);

  @override
  TypeET get runtimeType => TypeET(super.runtimeType);

  @override
  BoolET operator ==(Object? other) => BoolET(other == this);
}

extension type ET1(B b) implements A {}

extension type ET2(B b) implements ET1, B {}

extension type IntET(int i) implements int {}

extension type TypeET(Type t) implements Type {}

extension type BoolET(bool b) implements bool {}

void test() {
  var e2 = ET2(B());
  ET1 e1 = e2;

  int hc1 = e1.hashCode; /* Ok */
  IntET hc2 = e2.hashCode; /* Ok */

  Type t1 = e1.runtimeType; /* Ok */
  TypeET t2 = e2.runtimeType; /* Ok */

  bool b1 = e1 == e1; /* Ok */
  BoolET b2 = e2 == e2; /* Error */
}