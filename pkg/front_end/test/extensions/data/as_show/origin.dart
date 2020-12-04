// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[Extension2]*/

/*class: Extension2:
 builder-name=Extension2,
 builder-onType=String,
 extension-members=[
  method2=Extension2|method2,
  tearoff method2=Extension2|get#method2],
 extension-name=Extension2,
 extension-onType=String
*/
extension Extension2 on String {
/*member: Extension2|method2:
   builder-name=method2,
   builder-params=[#this],
   member-name=Extension2|method2,
   member-params=[#this]
  */
method2() {}

/*member: Extension2|get#method2:
   builder-name=method2,
   builder-params=[#this],
   member-name=Extension2|get#method2,
   member-params=[#this]*/
}
