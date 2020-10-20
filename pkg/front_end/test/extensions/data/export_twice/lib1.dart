// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[E]*/

class A {}

/*class: E:
 builder-name=E,
 builder-onType=A,
 extension-members=[
  foo=E|foo,
  tearoff foo=E|get#foo],
 extension-name=E,extension-onType=A
*/
extension E on A {
  /*member: E|foo:
   builder-name=foo,
   builder-params=[#this],
   member-name=E|foo,
   member-params=[#this]
  */
  foo() {}

  /*member: E|get#foo:
   builder-name=foo,
   builder-params=[#this],
   member-name=E|get#foo,
   member-params=[#this]
  */
}
