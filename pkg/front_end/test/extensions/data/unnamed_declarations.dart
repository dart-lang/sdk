// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[_extension#0,_extension#1,_extension#2,_extension#3,_extension#4]*/

class A1 {}

/*class: _extension#0:
 builder-name=_extension#0,
 builder-onType=A1,
 extension-members=[
  method=_extension#0|method,
  tearoff method=_extension#0|get#method],
 extension-name=_extension#0,
 extension-onType=A1
*/
extension on A1 {
  /*member: _extension#0|method:
     builder-name=method,
     builder-params=[#this],
     member-name=_extension#0|method,
     member-params=[#this]
  */
  method() {}

  /*member: _extension#0|get#method:
   builder-name=method,
   builder-params=[#this],
   member-name=_extension#0|get#method,
   member-params=[#this]
  */
}

/*class: _extension#1:
 builder-name=_extension#1,
 builder-onType=A1,
 extension-members=[
  method=_extension#1|method,
  tearoff method=_extension#1|get#method],
 extension-name=_extension#1,
 extension-onType=A1
*/
extension on A1 {
  /*member: _extension#1|method:
     builder-name=method,
     builder-params=[#this],
     member-name=_extension#1|method,
     member-params=[#this]
  */
  method() {}

  /*member: _extension#1|get#method:
   builder-name=method,
   builder-params=[#this],
   member-name=_extension#1|get#method,
   member-params=[#this]
  */
}

class B1<T> {}

/*class: _extension#2:
 builder-name=_extension#2,
 builder-onType=B1<T>,
 builder-type-params=[T],
 extension-members=[
  method=_extension#2|method,
  tearoff method=_extension#2|get#method],
 extension-name=_extension#2,
 extension-onType=B1<T>,
 extension-type-params=[T]
*/
extension <T> on B1<T> {
  /*member: _extension#2|method:
     builder-name=method,
     builder-params=[#this],
     builder-type-params=[T],
     member-name=_extension#2|method,
     member-params=[#this],
     member-type-params=[T]
  */
  method() {}

  /*member: _extension#2|get#method:
   builder-name=method,
   builder-params=[#this],
   builder-type-params=[T],
   member-name=_extension#2|get#method,
   member-params=[#this],
   member-type-params=[T]
  */
}

/*class: _extension#3:
 builder-name=_extension#3,
 builder-onType=B1<A1>,
 extension-members=[
  method=_extension#3|method,
  tearoff method=_extension#3|get#method],
 extension-name=_extension#3,
 extension-onType=B1<A1>
*/
extension on B1<A1> {
  /*member: _extension#3|method:
     builder-name=method,
     builder-params=[#this],
     member-name=_extension#3|method,
     member-params=[#this]
  */
  method() {}

  /*member: _extension#3|get#method:
   builder-name=method,
   builder-params=[#this],
   member-name=_extension#3|get#method,
   member-params=[#this]
  */
}

/*class: _extension#4:
 builder-name=_extension#4,
 builder-onType=B1<T>,
 builder-type-params=[T extends A1],
 extension-members=[
  method=_extension#4|method,
  tearoff method=_extension#4|get#method],
 extension-name=_extension#4,
 extension-onType=B1<T>,
 extension-type-params=[T extends A1]
*/
extension <T extends A1> on B1<T> {
  /*member: _extension#4|method:
     builder-name=method,
     builder-params=[#this],
     builder-type-params=[T extends A1],
     member-name=_extension#4|method,
     member-params=[#this],
     member-type-params=[T extends A1]
  */
  method() {}

  /*member: _extension#4|get#method:
   builder-name=method,
   builder-params=[#this],
   builder-type-params=[T extends A1],
   member-name=_extension#4|get#method,
   member-params=[#this],
   member-type-params=[T extends A1]
  */
}

main() {}
