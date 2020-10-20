// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[GeneralGeneric]*/

/*class: GeneralGeneric:
 builder-name=GeneralGeneric,
 builder-onType=T,
 builder-type-params=[T],
 extension-members=[
  method=GeneralGeneric|method,
  tearoff method=GeneralGeneric|get#method],
 extension-name=GeneralGeneric,
 extension-onType=T,
 extension-type-params=[T]
*/
extension GeneralGeneric<T> on T {
  /*member: GeneralGeneric|method:
   builder-name=method,
   builder-params=[#this],
   builder-type-params=[T],
   member-name=GeneralGeneric|method,
   member-params=[#this],
   member-type-params=[T]
  */
  T method() => this;

  /*member: GeneralGeneric|get#method:
   builder-name=method,
   builder-params=[#this],
   builder-type-params=[T],
   member-name=GeneralGeneric|get#method,
   member-params=[#this],
   member-type-params=[T]
  */
}

main() {
}
