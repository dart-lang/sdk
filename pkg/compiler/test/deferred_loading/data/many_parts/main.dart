// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*spec.library: 
 a_pre_fragments=[
  p10: {units: [18{b2, b3}], usedBy: [], needs: []},
  p11: {units: [19{b2, b4}], usedBy: [], needs: []},
  p12: {units: [21{b2, b5}], usedBy: [], needs: []},
  p13: {units: [26{b3, b4}], usedBy: [], needs: []},
  p14: {units: [27{b3, b5}], usedBy: [], needs: []},
  p15: {units: [30{b4, b5}], usedBy: [], needs: []},
  p16: {units: [5{b1, b2, b3}], usedBy: [], needs: []},
  p17: {units: [7{b1, b2, b4}], usedBy: [], needs: []},
  p18: {units: [11{b1, b2, b5}], usedBy: [], needs: []},
  p19: {units: [8{b1, b3, b4}], usedBy: [], needs: []},
  p1: {units: [1{b1}], usedBy: [], needs: []},
  p20: {units: [12{b1, b3, b5}], usedBy: [], needs: []},
  p21: {units: [14{b1, b4, b5}], usedBy: [], needs: []},
  p22: {units: [20{b2, b3, b4}], usedBy: [], needs: []},
  p23: {units: [22{b2, b3, b5}], usedBy: [], needs: []},
  p24: {units: [23{b2, b4, b5}], usedBy: [], needs: []},
  p25: {units: [28{b3, b4, b5}], usedBy: [], needs: []},
  p26: {units: [9{b1, b2, b3, b4}], usedBy: [], needs: []},
  p27: {units: [13{b1, b2, b3, b5}], usedBy: [], needs: []},
  p28: {units: [15{b1, b2, b4, b5}], usedBy: [], needs: []},
  p29: {units: [16{b1, b3, b4, b5}], usedBy: [], needs: []},
  p2: {units: [17{b2}], usedBy: [], needs: []},
  p30: {units: [24{b2, b3, b4, b5}], usedBy: [], needs: []},
  p31: {units: [2{b1, b2, b3, b4, b5}], usedBy: [], needs: []},
  p3: {units: [25{b3}], usedBy: [], needs: []},
  p4: {units: [29{b4}], usedBy: [], needs: []},
  p5: {units: [31{b5}], usedBy: [], needs: []},
  p6: {units: [3{b1, b2}], usedBy: [], needs: []},
  p7: {units: [4{b1, b3}], usedBy: [], needs: []},
  p8: {units: [6{b1, b4}], usedBy: [], needs: []},
  p9: {units: [10{b1, b5}], usedBy: [], needs: []}],
 b_finalized_fragments=[
  f10: [18{b2, b3}],
  f11: [19{b2, b4}],
  f12: [21{b2, b5}],
  f13: [26{b3, b4}],
  f14: [27{b3, b5}],
  f15: [30{b4, b5}],
  f16: [5{b1, b2, b3}],
  f17: [7{b1, b2, b4}],
  f18: [11{b1, b2, b5}],
  f19: [8{b1, b3, b4}],
  f1: [1{b1}],
  f20: [12{b1, b3, b5}],
  f21: [14{b1, b4, b5}],
  f22: [20{b2, b3, b4}],
  f23: [22{b2, b3, b5}],
  f24: [23{b2, b4, b5}],
  f25: [28{b3, b4, b5}],
  f26: [9{b1, b2, b3, b4}],
  f27: [13{b1, b2, b3, b5}],
  f28: [15{b1, b2, b4, b5}],
  f29: [16{b1, b3, b4, b5}],
  f2: [17{b2}],
  f30: [24{b2, b3, b4, b5}],
  f31: [2{b1, b2, b3, b4, b5}],
  f3: [25{b3}],
  f4: [29{b4}],
  f5: [31{b5}],
  f6: [3{b1, b2}],
  f7: [4{b1, b3}],
  f8: [6{b1, b4}],
  f9: [10{b1, b5}]],
 c_steps=[
  b1=(f31, f29, f28, f27, f26, f21, f20, f19, f18, f17, f16, f9, f8, f7, f6, f1),
  b2=(f31, f30, f28, f27, f26, f24, f23, f22, f18, f17, f16, f12, f11, f10, f6, f2),
  b3=(f31, f30, f29, f27, f26, f25, f23, f22, f20, f19, f16, f14, f13, f10, f7, f3),
  b4=(f31, f30, f29, f28, f26, f25, f24, f22, f21, f19, f17, f15, f13, f11, f8, f4),
  b5=(f31, f30, f29, f28, f27, f25, f24, f23, f21, f20, f18, f15, f14, f12, f9, f5)]
*/

/*three-frag.library: 
 a_pre_fragments=[
  p1: {units: [26{b3, b4}, 21{b2, b5}, 19{b2, b4}, 18{b2, b3}, 10{b1, b5}, 6{b1, b4}, 4{b1, b3}, 3{b1, b2}, 31{b5}, 29{b4}, 25{b3}, 17{b2}, 1{b1}], usedBy: [p2], needs: []},
  p2: {units: [9{b1, b2, b3, b4}, 28{b3, b4, b5}, 23{b2, b4, b5}, 22{b2, b3, b5}, 20{b2, b3, b4}, 14{b1, b4, b5}, 12{b1, b3, b5}, 8{b1, b3, b4}, 11{b1, b2, b5}, 7{b1, b2, b4}, 5{b1, b2, b3}, 30{b4, b5}, 27{b3, b5}], usedBy: [p4, p3], needs: [p1]},
  p3: {units: [24{b2, b3, b4, b5}, 16{b1, b3, b4, b5}, 15{b1, b2, b4, b5}, 13{b1, b2, b3, b5}], usedBy: [p4], needs: [p2]},
  p4: {units: [2{b1, b2, b3, b4, b5}], usedBy: [], needs: [p2, p3]}],
 b_finalized_fragments=[
  f1: [26{b3, b4}, 21{b2, b5}, 19{b2, b4}, 18{b2, b3}, 10{b1, b5}, 6{b1, b4}, 4{b1, b3}, 3{b1, b2}, 31{b5}, 29{b4}, 25{b3}, 17{b2}, 1{b1}],
  f2: [9{b1, b2, b3, b4}, 28{b3, b4, b5}, 23{b2, b4, b5}, 22{b2, b3, b5}, 20{b2, b3, b4}, 14{b1, b4, b5}, 12{b1, b3, b5}, 8{b1, b3, b4}, 11{b1, b2, b5}, 7{b1, b2, b4}, 5{b1, b2, b3}, 30{b4, b5}, 27{b3, b5}],
  f3: [24{b2, b3, b4, b5}, 16{b1, b3, b4, b5}, 15{b1, b2, b4, b5}, 13{b1, b2, b3, b5}],
  f4: [2{b1, b2, b3, b4, b5}]],
 c_steps=[
  b1=(f4, f3, f2, f1),
  b2=(f4, f3, f2, f1),
  b3=(f4, f3, f2, f1),
  b4=(f4, f3, f2, f1),
  b5=(f4, f3, f2, f1)]
*/

/*two-frag.library: 
 a_pre_fragments=[
  p1: {units: [12{b1, b3, b5}, 8{b1, b3, b4}, 11{b1, b2, b5}, 7{b1, b2, b4}, 5{b1, b2, b3}, 30{b4, b5}, 27{b3, b5}, 26{b3, b4}, 21{b2, b5}, 19{b2, b4}, 18{b2, b3}, 10{b1, b5}, 6{b1, b4}, 4{b1, b3}, 3{b1, b2}, 31{b5}, 29{b4}, 25{b3}, 17{b2}, 1{b1}], usedBy: [p2], needs: []},
  p2: {units: [24{b2, b3, b4, b5}, 16{b1, b3, b4, b5}, 15{b1, b2, b4, b5}, 13{b1, b2, b3, b5}, 9{b1, b2, b3, b4}, 28{b3, b4, b5}, 23{b2, b4, b5}, 22{b2, b3, b5}, 20{b2, b3, b4}, 14{b1, b4, b5}], usedBy: [p3], needs: [p1]},
  p3: {units: [2{b1, b2, b3, b4, b5}], usedBy: [], needs: [p2]}],
 b_finalized_fragments=[
  f1: [12{b1, b3, b5}, 8{b1, b3, b4}, 11{b1, b2, b5}, 7{b1, b2, b4}, 5{b1, b2, b3}, 30{b4, b5}, 27{b3, b5}, 26{b3, b4}, 21{b2, b5}, 19{b2, b4}, 18{b2, b3}, 10{b1, b5}, 6{b1, b4}, 4{b1, b3}, 3{b1, b2}, 31{b5}, 29{b4}, 25{b3}, 17{b2}, 1{b1}],
  f2: [24{b2, b3, b4, b5}, 16{b1, b3, b4, b5}, 15{b1, b2, b4, b5}, 13{b1, b2, b3, b5}, 9{b1, b2, b3, b4}, 28{b3, b4, b5}, 23{b2, b4, b5}, 22{b2, b3, b5}, 20{b2, b3, b4}, 14{b1, b4, b5}],
  f3: [2{b1, b2, b3, b4, b5}]],
 c_steps=[
  b1=(f3, f2, f1),
  b2=(f3, f2, f1),
  b3=(f3, f2, f1),
  b4=(f3, f2, f1),
  b5=(f3, f2, f1)]
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
