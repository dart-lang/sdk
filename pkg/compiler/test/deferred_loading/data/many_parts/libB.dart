// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

/*member: v:member_unit=1{b1, b2, b3, b4, b5}*/
void v(Set<String> u, String name, int bit) {
  Expect.isTrue(u.add(name));
  Expect.equals(name[bit], '1');
}

@pragma('dart2js:noInline')
/*member: f_000_01:member_unit=2{b1}*/
f_000_01(Set<String> u, int b) => v(u, '00001', b);

@pragma('dart2js:noInline')
/*member: f_000_11:member_unit=3{b1, b2}*/
f_000_11(Set<String> u, int b) => v(u, '00011', b);

@pragma('dart2js:noInline')
/*member: f_001_01:member_unit=4{b1, b3}*/
f_001_01(Set<String> u, int b) => v(u, '00101', b);

@pragma('dart2js:noInline')
/*member: f_001_11:member_unit=5{b1, b2, b3}*/
f_001_11(Set<String> u, int b) => v(u, '00111', b);

@pragma('dart2js:noInline')
/*member: f_010_01:member_unit=6{b1, b4}*/
f_010_01(Set<String> u, int b) => v(u, '01001', b);

@pragma('dart2js:noInline')
/*member: f_010_11:member_unit=7{b1, b2, b4}*/
f_010_11(Set<String> u, int b) => v(u, '01011', b);

@pragma('dart2js:noInline')
/*spec|two-frag.member: f_011_01:member_unit=8{b1, b3, b4}*/
/*three-frag.member: f_011_01:member_unit=8{b1, b3, b4, b2, b5}*/
f_011_01(Set<String> u, int b) => v(u, '01101', b);

@pragma('dart2js:noInline')
/*member: f_011_11:member_unit=9{b1, b2, b3, b4}*/
f_011_11(Set<String> u, int b) => v(u, '01111', b);

@pragma('dart2js:noInline')
/*member: f_100_01:member_unit=10{b1, b5}*/
f_100_01(Set<String> u, int b) => v(u, '10001', b);

@pragma('dart2js:noInline')
/*member: f_100_11:member_unit=11{b1, b2, b5}*/
f_100_11(Set<String> u, int b) => v(u, '10011', b);

@pragma('dart2js:noInline')
/*spec|three-frag.member: f_101_01:member_unit=12{b1, b3, b5}*/
/*two-frag.member: f_101_01:member_unit=12{b1, b3, b5, b4, b2}*/
f_101_01(Set<String> u, int b) => v(u, '10101', b);

@pragma('dart2js:noInline')
/*member: f_101_11:member_unit=13{b1, b2, b3, b5}*/
f_101_11(Set<String> u, int b) => v(u, '10111', b);

@pragma('dart2js:noInline')
/*member: f_110_01:member_unit=14{b1, b4, b5}*/
f_110_01(Set<String> u, int b) => v(u, '11001', b);

@pragma('dart2js:noInline')
/*member: f_110_11:member_unit=15{b1, b2, b4, b5}*/
f_110_11(Set<String> u, int b) => v(u, '11011', b);

@pragma('dart2js:noInline')
/*member: f_111_01:member_unit=16{b1, b3, b4, b5}*/
f_111_01(Set<String> u, int b) => v(u, '11101', b);

@pragma('dart2js:noInline')
/*member: f_111_11:member_unit=1{b1, b2, b3, b4, b5}*/
f_111_11(Set<String> u, int b) => v(u, '11111', b);

@pragma('dart2js:noInline')
/*member: f_000_10:member_unit=17{b2}*/
f_000_10(Set<String> u, int b) => v(u, '00010', b);

@pragma('dart2js:noInline')
/*member: f_001_10:member_unit=18{b2, b3}*/
f_001_10(Set<String> u, int b) => v(u, '00110', b);

@pragma('dart2js:noInline')
/*member: f_010_10:member_unit=19{b2, b4}*/
f_010_10(Set<String> u, int b) => v(u, '01010', b);

@pragma('dart2js:noInline')
/*member: f_011_10:member_unit=20{b2, b3, b4}*/
f_011_10(Set<String> u, int b) => v(u, '01110', b);

@pragma('dart2js:noInline')
/*member: f_100_10:member_unit=21{b2, b5}*/
f_100_10(Set<String> u, int b) => v(u, '10010', b);

@pragma('dart2js:noInline')
/*member: f_101_10:member_unit=22{b2, b3, b5}*/
f_101_10(Set<String> u, int b) => v(u, '10110', b);

@pragma('dart2js:noInline')
/*member: f_110_10:member_unit=23{b2, b4, b5}*/
f_110_10(Set<String> u, int b) => v(u, '11010', b);

@pragma('dart2js:noInline')
/*member: f_111_10:member_unit=24{b2, b3, b4, b5}*/
f_111_10(Set<String> u, int b) => v(u, '11110', b);

@pragma('dart2js:noInline')
/*member: f_001_00:member_unit=25{b3}*/
f_001_00(Set<String> u, int b) => v(u, '00100', b);

@pragma('dart2js:noInline')
/*member: f_011_00:member_unit=26{b3, b4}*/
f_011_00(Set<String> u, int b) => v(u, '01100', b);

@pragma('dart2js:noInline')
/*member: f_101_00:member_unit=27{b3, b5}*/
f_101_00(Set<String> u, int b) => v(u, '10100', b);

@pragma('dart2js:noInline')
/*member: f_111_00:member_unit=28{b3, b4, b5}*/
f_111_00(Set<String> u, int b) => v(u, '11100', b);

@pragma('dart2js:noInline')
/*member: f_010_00:member_unit=29{b4}*/
f_010_00(Set<String> u, int b) => v(u, '01000', b);

@pragma('dart2js:noInline')
/*member: f_110_00:member_unit=30{b4, b5}*/
f_110_00(Set<String> u, int b) => v(u, '11000', b);

@pragma('dart2js:noInline')
/*member: f_100_00:member_unit=31{b5}*/
f_100_00(Set<String> u, int b) => v(u, '10000', b);
