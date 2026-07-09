// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@pragma('dart2js:noInline')
/*member: step12a:member_unit=1{step1, step2a, step2b}*/
step12a() => '12a';

@pragma('dart2js:noInline')
/*member: step12b:member_unit=1{step1, step2a, step2b}*/
step12b() => '12b';

@pragma('dart2js:noInline')
/*member: step12ab:member_unit=1{step1, step2a, step2b}*/
step12ab() => '12ab';

@pragma('dart2js:noInline')
/*member: step2ab:member_unit=3{step2a, step2b}*/
step2ab() => '2ab';
