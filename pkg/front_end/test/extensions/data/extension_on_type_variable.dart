// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*class: GeneralGeneric:
 builder-name=GeneralGeneric,
 builder-onTypes=[T],
 builder-supertype=Object,
 builder-type-params=[T],
 cls-name=GeneralGeneric,
 cls-supertype=Object,
 cls-type-params=[T]
*/
extension GeneralGeneric<T> on T {
  /*member: GeneralGeneric.method:
   builder-name=method,
   builder-params=[#this],
   builder-type-params=[T],
   member-name=method,
   member-params=[#this],
   member-type-params=[#T]
  */
  T method() => this;
}

main() {
}