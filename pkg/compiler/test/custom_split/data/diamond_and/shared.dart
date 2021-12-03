// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@pragma('dart2js:noInline')
/*member: step12a:member_unit=1{step1, step2a, step2b, step3}*/
step12a() => '12a';

@pragma('dart2js:noInline')
/*member: step12a3:member_unit=1{step1, step2a, step2b, step3}*/
step12a3() => '12a3';

@pragma('dart2js:noInline')
/*member: step2a3:member_unit=2{step2a, step3}*/
step2a3() => '2a3';

@pragma('dart2js:noInline')
/*member: step12b:member_unit=1{step1, step2a, step2b, step3}*/
step12b() => '12b';

@pragma('dart2js:noInline')
/*member: step12b3:member_unit=1{step1, step2a, step2b, step3}*/
step12b3() => '12b3';

@pragma('dart2js:noInline')
/*member: step2b3:member_unit=4{step2b, step3}*/
step2b3() => '2b3';

@pragma('dart2js:noInline')
/*member: step2ab:member_unit=3{step2a, step2b, step3}*/
step2ab() => '2ab';

@pragma('dart2js:noInline')
/*member: step2ab3:member_unit=3{step2a, step2b, step3}*/
step2ab3() => '2ab3';

@pragma('dart2js:noInline')
/*member: step13:member_unit=1{step1, step2a, step2b, step3}*/
step13() => '13';

@pragma('dart2js:noInline')
/*member: step12ab:member_unit=1{step1, step2a, step2b, step3}*/
step12ab() => '12ab';

@pragma('dart2js:noInline')
/*member: step12ab3:member_unit=1{step1, step2a, step2b, step3}*/
step12ab3() => '12ab3';
