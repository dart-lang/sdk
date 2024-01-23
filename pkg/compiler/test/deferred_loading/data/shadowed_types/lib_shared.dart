// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: A:
 class_unit=1{libb},
 type_unit=2{liba, libb}
*/
/*member: A.:member_unit=1{libb}*/
class A {}

/*class: B:
 class_unit=main{},
 type_unit=main{}
*/
/*member: B.:member_unit=main{}*/
class B {}

/*class: C_Parent:
 class_unit=1{libb},
 type_unit=main{}
*/
/*member: C_Parent.:member_unit=1{libb}*/
class C_Parent {}

/*class: D:
 class_unit=1{libb},
 type_unit=2{liba, libb}
*/
/*member: D.:member_unit=1{libb}*/
class D {}

/*class: E:
 class_unit=1{libb},
 type_unit=1{libb}
*/
/*member: E.:member_unit=1{libb}*/
class E extends D {}

/*class: F:
 class_unit=1{libb},
 type_unit=1{libb}
*/
/*member: F.:member_unit=1{libb}*/
class F {}
