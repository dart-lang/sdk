// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*spec.library: 
 output_units=[
  f10: {units: [7{b1, b2, b4}], usedBy: [], needs: []},
  f11: {units: [5{b1, b2, b3}], usedBy: [], needs: []},
  f12: {units: [10{b1, b5}], usedBy: [], needs: []},
  f13: {units: [6{b1, b4}], usedBy: [], needs: []},
  f14: {units: [4{b1, b3}], usedBy: [], needs: []},
  f15: {units: [3{b1, b2}], usedBy: [], needs: []},
  f16: {units: [2{b1}], usedBy: [], needs: []},
  f17: {units: [24{b2, b3, b4, b5}], usedBy: [], needs: []},
  f18: {units: [23{b2, b4, b5}], usedBy: [], needs: []},
  f19: {units: [22{b2, b3, b5}], usedBy: [], needs: []},
  f1: {units: [1{b1, b2, b3, b4, b5}], usedBy: [], needs: []},
  f20: {units: [20{b2, b3, b4}], usedBy: [], needs: []},
  f21: {units: [21{b2, b5}], usedBy: [], needs: []},
  f22: {units: [19{b2, b4}], usedBy: [], needs: []},
  f23: {units: [18{b2, b3}], usedBy: [], needs: []},
  f24: {units: [17{b2}], usedBy: [], needs: []},
  f25: {units: [28{b3, b4, b5}], usedBy: [], needs: []},
  f26: {units: [27{b3, b5}], usedBy: [], needs: []},
  f27: {units: [26{b3, b4}], usedBy: [], needs: []},
  f28: {units: [25{b3}], usedBy: [], needs: []},
  f29: {units: [30{b4, b5}], usedBy: [], needs: []},
  f2: {units: [16{b1, b3, b4, b5}], usedBy: [], needs: []},
  f30: {units: [29{b4}], usedBy: [], needs: []},
  f31: {units: [31{b5}], usedBy: [], needs: []},
  f3: {units: [15{b1, b2, b4, b5}], usedBy: [], needs: []},
  f4: {units: [13{b1, b2, b3, b5}], usedBy: [], needs: []},
  f5: {units: [9{b1, b2, b3, b4}], usedBy: [], needs: []},
  f6: {units: [14{b1, b4, b5}], usedBy: [], needs: []},
  f7: {units: [12{b1, b3, b5}], usedBy: [], needs: []},
  f8: {units: [8{b1, b3, b4}], usedBy: [], needs: []},
  f9: {units: [11{b1, b2, b5}], usedBy: [], needs: []}],
 steps=[
  b1=(f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13, f14, f15, f16),
  b2=(f1, f17, f3, f4, f5, f18, f19, f20, f9, f10, f11, f21, f22, f23, f15, f24),
  b3=(f1, f17, f2, f4, f5, f25, f19, f20, f7, f8, f11, f26, f27, f23, f14, f28),
  b4=(f1, f17, f2, f3, f5, f25, f18, f20, f6, f8, f10, f29, f27, f22, f13, f30),
  b5=(f1, f17, f2, f3, f4, f25, f18, f19, f6, f7, f9, f29, f26, f21, f12, f31)]
*/

/*three-frag.library: 
 output_units=[
  f1: {units: [1{b1, b2, b3, b4, b5}], usedBy: [], needs: [3, 2]},
  f2: {units: [24{b2, b3, b4, b5}, 16{b1, b3, b4, b5}, 15{b1, b2, b4, b5}, 13{b1, b2, b3, b5}], usedBy: [1], needs: [3]},
  f3: {units: [9{b1, b2, b3, b4}, 28{b3, b4, b5}, 23{b2, b4, b5}, 22{b2, b3, b5}, 20{b2, b3, b4}, 14{b1, b4, b5}, 12{b1, b3, b5}, 8{b1, b3, b4}, 11{b1, b2, b5}, 7{b1, b2, b4}, 5{b1, b2, b3}, 30{b4, b5}, 27{b3, b5}], usedBy: [1, 2], needs: [4]},
  f4: {units: [26{b3, b4}, 21{b2, b5}, 19{b2, b4}, 18{b2, b3}, 10{b1, b5}, 6{b1, b4}, 4{b1, b3}, 3{b1, b2}, 31{b5}, 29{b4}, 25{b3}, 17{b2}, 2{b1}], usedBy: [3], needs: []}],
 steps=[
  b1=(f1, f2, f3, f4),
  b2=(f1, f2, f3, f4),
  b3=(f1, f2, f3, f4),
  b4=(f1, f2, f3, f4),
  b5=(f1, f2, f3, f4)]
*/

/*two-frag.library: 
 output_units=[
  f1: {units: [1{b1, b2, b3, b4, b5}], usedBy: [], needs: [2]},
  f2: {units: [24{b2, b3, b4, b5}, 16{b1, b3, b4, b5}, 15{b1, b2, b4, b5}, 13{b1, b2, b3, b5}, 9{b1, b2, b3, b4}, 28{b3, b4, b5}, 23{b2, b4, b5}, 22{b2, b3, b5}, 20{b2, b3, b4}, 14{b1, b4, b5}, 12{b1, b3, b5}], usedBy: [1], needs: [3]},
  f3: {units: [8{b1, b3, b4}, 11{b1, b2, b5}, 7{b1, b2, b4}, 5{b1, b2, b3}, 30{b4, b5}, 27{b3, b5}, 26{b3, b4}, 21{b2, b5}, 19{b2, b4}, 18{b2, b3}, 10{b1, b5}, 6{b1, b4}, 4{b1, b3}, 3{b1, b2}, 31{b5}, 29{b4}, 25{b3}, 17{b2}, 2{b1}], usedBy: [2], needs: []}],
 steps=[
  b1=(f1, f2, f3),
  b2=(f1, f2, f3),
  b3=(f1, f2, f3),
  b4=(f1, f2, f3),
  b5=(f1, f2, f3)]
*/

import 'lib1.dart';
import 'lib2.dart';
import 'lib3.dart';
import 'lib4.dart';
import 'lib5.dart';

/*member: main:member_unit=main{}*/
main() {
  entryLib1();
  entryLib2();
  entryLib3();
  entryLib4();
  entryLib5();
}
