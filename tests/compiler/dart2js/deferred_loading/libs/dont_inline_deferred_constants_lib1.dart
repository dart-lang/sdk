// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dont_inline_deferred_constants_main.dart" show C;
import "dont_inline_deferred_constants_main.dart" as main;

/*strong.member: C1:OutputUnit(1, {lib1})*/
const C1 = "string1";

/*strong.member: C1b:OutputUnit(1, {lib1})*/
const C1b = /*strong.OutputUnit(1, {lib1})*/ const C("string1");

/*strong.member: C2:OutputUnit(1, {lib1})*/
const C2 = 1010;

/*strong.member: C2b:OutputUnit(1, {lib1})*/
const C2b = /*strong.OutputUnit(1, {lib1})*/ const C(1010);

/*class: D:null*/
class D {
  /*strong.member: D.C3:OutputUnit(1, {lib1})*/
  static const C3 = "string2";

  /*strong.member: D.C3b:OutputUnit(1, {lib1})*/
  static const C3b = /*strong.OutputUnit(1, {lib1})*/ const C("string2");
}

/*strong.member: C4:OutputUnit(1, {lib1})*/
const C4 = "string4";

/*strong.member: C5:OutputUnit(1, {lib1})*/
const C5 = /*strong.OutputUnit(main, {})*/ const C(1);

/*strong.member: C6:OutputUnit(1, {lib1})*/
const C6 = /*strong.OutputUnit(2, {lib1, lib2})*/ const C(2);

/*member: foo:OutputUnit(1, {lib1})*/
foo() {
  print("lib1");
  main.foo();
}
