// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'lib_shared.dart';

@pragma('dart2js:noInline')
/*member: createA:member_unit=1{libb}*/
createA() {
  return A();
}

@pragma('dart2js:noInline')
/*member: isB:member_unit=1{libb}*/
isB(foo) {
  return foo is B;
}

/*class: C:
 class_unit=1{libb},
 type_unit=main{}
*/
/*member: C.:member_unit=1{libb}*/
class C extends C_Parent {}

@pragma('dart2js:noInline')
/*member: createC:member_unit=1{libb}*/
createC() {
  return C();
}

@pragma('dart2js:noInline')
/*member: createE:member_unit=1{libb}*/
createE() {
  return E();
}

@pragma('dart2js:noInline')
/*member: isFWithUnused:member_unit=1{libb}*/
isFWithUnused(foo) {
  var unused = F();
  return foo is F;
}
