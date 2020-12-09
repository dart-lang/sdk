// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*spec.library: 
 output_units=[
  f10: {units: [7{b1, b2, b4}], usedBy: [11, 29], needs: [9, 8]},
  f11: {units: [5{b1, b2, b3}], usedBy: [12, 21, 26], needs: [10, 8]},
  f12: {units: [10{b1, b5}], usedBy: [13, 31], needs: [11, 21]},
  f13: {units: [6{b1, b4}], usedBy: [14, 30], needs: [12, 22]},
  f14: {units: [4{b1, b3}], usedBy: [15, 28], needs: [13, 23]},
  f15: {units: [3{b1, b2}], usedBy: [16, 24], needs: [14, 23]},
  f16: {units: [2{b1}], usedBy: [], needs: [15]},
  f17: {units: [24{b2, b3, b4, b5}], usedBy: [3, 2], needs: [1]},
  f18: {units: [23{b2, b4, b5}], usedBy: [19, 20], needs: [5, 25]},
  f19: {units: [22{b2, b3, b5}], usedBy: [20, 6], needs: [18, 25]},
  f1: {units: [1{b1, b2, b3, b4, b5}], usedBy: [2, 17], needs: []},
  f20: {units: [20{b2, b3, b4}], usedBy: [9, 7, 6], needs: [19, 18]},
  f21: {units: [21{b2, b5}], usedBy: [22, 12], needs: [11, 26]},
  f22: {units: [19{b2, b4}], usedBy: [23, 13], needs: [21, 27]},
  f23: {units: [18{b2, b3}], usedBy: [15, 14], needs: [22, 27]},
  f24: {units: [17{b2}], usedBy: [], needs: [15]},
  f25: {units: [28{b3, b4, b5}], usedBy: [19, 18], needs: [5, 4]},
  f26: {units: [27{b3, b5}], usedBy: [27, 21], needs: [11, 29]},
  f27: {units: [26{b3, b4}], usedBy: [23, 22], needs: [26, 29]},
  f28: {units: [25{b3}], usedBy: [], needs: [14]},
  f29: {units: [30{b4, b5}], usedBy: [27, 26], needs: [10, 9]},
  f2: {units: [16{b1, b3, b4, b5}], usedBy: [3, 4], needs: [1, 17]},
  f30: {units: [29{b4}], usedBy: [], needs: [13]},
  f31: {units: [31{b5}], usedBy: [], needs: [12]},
  f3: {units: [15{b1, b2, b4, b5}], usedBy: [4, 5], needs: [2, 17]},
  f4: {units: [13{b1, b2, b3, b5}], usedBy: [5, 25], needs: [3, 2]},
  f5: {units: [9{b1, b2, b3, b4}], usedBy: [6, 18, 25], needs: [4, 3]},
  f6: {units: [14{b1, b4, b5}], usedBy: [7, 8], needs: [5, 20, 19]},
  f7: {units: [12{b1, b3, b5}], usedBy: [8, 9], needs: [6, 20]},
  f8: {units: [8{b1, b3, b4}], usedBy: [9, 11, 10], needs: [7, 6]},
  f9: {units: [11{b1, b2, b5}], usedBy: [10, 29], needs: [8, 20, 7]}],
 steps=[
  b1=(f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12, f13, f14, f15, f16),
  b2=(f1, f17, f3, f4, f5, f18, f19, f20, f9, f10, f11, f21, f22, f23, f15, f24),
  b3=(f1, f17, f2, f4, f5, f25, f19, f20, f7, f8, f11, f26, f27, f23, f14, f28),
  b4=(f1, f17, f2, f3, f5, f25, f18, f20, f6, f8, f10, f29, f27, f22, f13, f30),
  b5=(f1, f17, f2, f3, f4, f25, f18, f19, f6, f7, f9, f29, f26, f21, f12, f31)]
*/

/*three-frag.library: 
 output_units=[
  f1: {units: [1{b1, b2, b3, b4, b5}, 24{b2, b3, b4, b5}, 16{b1, b3, b4, b5}, 15{b1, b2, b4, b5}, 13{b1, b2, b3, b5}, 9{b1, b2, b3, b4}, 28{b3, b4, b5}, 23{b2, b4, b5}, 22{b2, b3, b5}, 20{b2, b3, b4}, 14{b1, b4, b5}], usedBy: [2, 3], needs: []},
  f2: {units: [12{b1, b3, b5}], usedBy: [3], needs: [1]},
  f3: {units: [8{b1, b3, b4, b2, b5}, 11{b1, b2, b5}, 7{b1, b2, b4}, 5{b1, b2, b3}, 30{b4, b5}, 27{b3, b5}, 26{b3, b4}, 21{b2, b5}, 19{b2, b4}, 18{b2, b3}, 10{b1, b5}, 31{b5}, 6{b1, b4}, 29{b4}, 4{b1, b3}, 25{b3}, 3{b1, b2}, 2{b1}, 17{b2}], usedBy: [], needs: [2, 1]}],
 steps=[
  b1=(f1, f2, f3),
  b2=(f1, f3),
  b3=(f1, f2, f3),
  b4=(f1, f3),
  b5=(f1, f2, f3)]
*/

/*two-frag.library: 
 output_units=[
  f1: {units: [1{b1, b2, b3, b4, b5}, 24{b2, b3, b4, b5}, 16{b1, b3, b4, b5}, 15{b1, b2, b4, b5}, 13{b1, b2, b3, b5}, 9{b1, b2, b3, b4}, 28{b3, b4, b5}, 23{b2, b4, b5}, 22{b2, b3, b5}, 20{b2, b3, b4}, 14{b1, b4, b5}], usedBy: [2], needs: []},
  f2: {units: [12{b1, b3, b5, b4, b2}, 8{b1, b3, b4}, 11{b1, b2, b5}, 7{b1, b2, b4}, 5{b1, b2, b3}, 30{b4, b5}, 27{b3, b5}, 26{b3, b4}, 21{b2, b5}, 19{b2, b4}, 18{b2, b3}, 10{b1, b5}, 31{b5}, 6{b1, b4}, 29{b4}, 4{b1, b3}, 25{b3}, 3{b1, b2}, 2{b1}, 17{b2}], usedBy: [], needs: [1]}],
 steps=[
  b1=(f1, f2),
  b2=(f1, f2),
  b3=(f1, f2),
  b4=(f1, f2),
  b5=(f1, f2)]
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
