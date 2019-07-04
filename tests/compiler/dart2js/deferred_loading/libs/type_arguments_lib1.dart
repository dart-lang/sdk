// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'type_arguments_lib3.dart';

/*class: A:OutputUnit(1, {lib1})*/
class A<T> {
  /*strong.member: A.:OutputUnit(1, {lib1})*/
  const A();
}

/*class: B:OutputUnit(1, {lib1})*/
class B {}

/*strong.member: field1:OutputUnit(1, {lib1})*/
const dynamic field1 = /*strong.OutputUnit(1, {lib1})*/ const A<B>();

/*strong.member: field2:OutputUnit(1, {lib1})*/
const dynamic field2 = /*strong.OutputUnit(1, {lib1})*/ const A<F>();
