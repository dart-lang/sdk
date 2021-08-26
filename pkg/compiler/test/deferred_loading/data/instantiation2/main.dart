// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*spec.library: 
 a_pre_fragments=[
  p1: {units: [1{b}], usedBy: [], needs: []},
  p2: {units: [3{c}], usedBy: [], needs: []},
  p3: {units: [2{b, c}], usedBy: [], needs: []}],
 b_finalized_fragments=[
  f1: [1{b}],
  f2: [3{c}],
  f3: [2{b, c}]],
 c_steps=[
  b=(f3, f1),
  c=(f3, f2)]
*/

/*two-frag.library: 
 a_pre_fragments=[
  p1: {units: [3{c}, 1{b}], usedBy: [p2], needs: []},
  p2: {units: [2{b, c}], usedBy: [], needs: [p1]}],
 b_finalized_fragments=[
  f1: [3{c}, 1{b}],
  f2: [2{b, c}]],
 c_steps=[
  b=(f2, f1),
  c=(f2, f1)]
*/

/*three-frag.library: 
 a_pre_fragments=[
  p1: {units: [1{b}], usedBy: [p3], needs: []},
  p2: {units: [3{c}], usedBy: [p3], needs: []},
  p3: {units: [2{b, c}], usedBy: [], needs: [p1, p2]}],
 b_finalized_fragments=[
  f1: [1{b}],
  f2: [3{c}],
  f3: [2{b, c}]],
 c_steps=[
  b=(f3, f1),
  c=(f3, f2)]
*/

// @dart = 2.7

// Test instantiations with the same type argument count used only in two
// deferred libraries.

/*class: global#Instantiation:
 class_unit=2{b, c},
 type_unit=2{b, c}
*/
/*class: global#Instantiation1:
 class_unit=2{b, c},
 type_unit=2{b, c}
*/

import 'lib1.dart' deferred as b;
import 'lib2.dart' deferred as c;

/*member: main:member_unit=main{}*/
main() async {
  await b.loadLibrary();
  await c.loadLibrary();
  print(b.m(3));
  print(c.m(3));
}
