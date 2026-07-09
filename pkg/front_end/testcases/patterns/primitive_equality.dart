// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void topLevel() {}

class Const {
  const Const();
}

class A {
  const A();
  int get hashCode => super.hashCode + 1;
}

class B {
  const B();
  bool operator ==(Object other) => super == other;
}

class C {
  const C();
  int get hashCode => super.hashCode + 1;
  bool operator ==(Object other) => super == other;
}

const a1 = A() == Const(); // Error
const a2 = Const() == A(); // Ok
const a3 = A() != Const(); // Error
const a4 = Const() != A(); // Ok
const a5 = A() == null; // Ok
const a6 = null == A(); // Ok
const a7 = A() != null; // Ok
const a8 = null != A(); // Ok

const b1 = B() == Const(); // Error
const b2 = Const() == B(); // Ok
const b3 = B() != Const(); // Error
const b4 = Const() != B(); // Ok
const b5 = B() == null; // Ok
const b6 = null == B(); // Ok
const b7 = B() != null; // Ok
const b8 = null != B(); // Ok

const c1 = C() == Const(); // Error
const c2 = Const() == C(); // Ok
const c3 = C() != Const(); // Error
const c4 = Const() != C(); // Ok
const c5 = C() == null; // Ok
const c6 = null == C(); // Ok
const c7 = C() != null; // Ok
const c8 = null != C(); // Ok

const d1 = true == Const(); // Ok
const d2 = Const() == true; // Ok
const d3 = true != Const(); // Ok
const d4 = Const() != true; // Ok

const e1 = 0 == Const(); // Ok
const e2 = Const() == 0; // Ok
const e3 = 0 != Const(); // Ok
const e4 = Const() != 0; // Ok

const f1 = '' == Const(); // Ok
const f2 = Const() == ''; // Ok
const f3 = '' != Const(); // Ok
const f4 = Const() != ''; // Ok

const g1 = #a == Const(); // Ok
const g2 = Const() == #a; // Ok
const g3 = #a != Const(); // Ok
const g4 = Const() != #a; // Ok

const h1 = const Symbol('b') == Const(); // Ok
const h2 = Const() == const Symbol('b'); // Ok
const h3 = const Symbol('b') != Const(); // Ok
const h4 = Const() != const Symbol('b'); // Ok

const i1 = Object == Const(); // Ok
const i2 = Const() == Object; // Ok
const i3 = Object != Const(); // Ok
const i4 = Const() != Object; // Ok

const j1 = [] == Const(); // Ok
const j2 = Const() == []; // Ok
const j3 = [] != Const(); // Ok
const j4 = Const() != []; // Ok

const k1 = {} == Const(); // Ok
const k2 = Const() == {}; // Ok
const k3 = {} != Const(); // Ok
const k4 = Const() != {}; // Ok

const l1 = {0} == Const(); // Ok
const l2 = Const() == {0}; // Ok
const l3 = {0} != Const(); // Ok
const l4 = Const() != {0}; // Ok

const n1 = topLevel == Const(); // Ok
const n2 = Const() == topLevel; // Ok
const n3 = topLevel != Const(); // Ok
const n4 = Const() != topLevel; // Ok

const o1 = 0.5 == Const(); // Ok
const o2 = Const() == 0.5; // Ok
const o3 = 0.5 != Const(); // Ok
const o4 = Const() != 0.5; // Ok

const set1 = {
  null, // Ok
  Const(), // Ok
  true, // Ok
  0, // Ok
  '', // Ok
  #a, // Ok
  const Symbol('b'), // Ok
  Object, // Ok
  [], // Ok
  {}, // Ok
  {0}, // Ok
  topLevel, // Ok
};

const set2 = {
  A(), // Error
};

const set3 = {
  B(), // Error
};

const set4 = {
  C(), // Error
};

const set5 = {
  0.5, // Error,
};

const map1 = {
  null: 0, // Ok
  Const(): 0, // Ok
  true: 0, // Ok
  0: 0, // Ok
  '': 0, // Ok
  #a: 0, // Ok
  const Symbol('b'): 0, // Ok
  Object: 0, // Ok
  []: 0, // Ok
  {}: 0, // Ok
  {0}: 0, // Ok
  topLevel: 0, // Ok
};

const map2 = {
  A(): 0, // Error
};

const map3 = {
  B(): 0, // Error
};

const map4 = {
  C(): 0, // Error
};

const map5 = {
  0.5: 0, // Error,
};
