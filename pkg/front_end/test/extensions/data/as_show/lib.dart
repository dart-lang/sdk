// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[Extension1]*/

/*class: Extension1:
 builder-name=Extension1,
 builder-onType=int,
 extension-members=[
  method1=Extension1|method1,
  tearoff method1=Extension1|get#method1],
 extension-name=Extension1,
 extension-onType=int
*/
extension Extension1 on int {
  /*member: Extension1|method1:
   builder-name=method1,
   builder-params=[#this],
   member-name=Extension1|method1,
   member-params=[#this]
  */
  method1() {}

  /*member: Extension1|get#method1:
   builder-name=method1,
   builder-params=[#this],
   member-name=Extension1|get#method1,
   member-params=[#this]*/
}
