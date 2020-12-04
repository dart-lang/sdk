// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[AmbiguousExtension1,AmbiguousExtension2,UnambiguousExtension1]*/

/*class: AmbiguousExtension1:
 builder-name=AmbiguousExtension1,
 builder-onType=String,
 extension-members=[
  static ambiguousStaticMethod1=AmbiguousExtension1|ambiguousStaticMethod1],
 extension-name=AmbiguousExtension1,
 extension-onType=String
*/
extension AmbiguousExtension1 on String {
  /*member: AmbiguousExtension1|ambiguousStaticMethod1:
   builder-name=ambiguousStaticMethod1,
   member-name=AmbiguousExtension1|ambiguousStaticMethod1
  */
  static void ambiguousStaticMethod1() {}
}

/*class: AmbiguousExtension2:
 builder-name=AmbiguousExtension2,
 builder-onType=String,
 extension-members=[
  static unambiguousStaticMethod1=AmbiguousExtension2|unambiguousStaticMethod1],
 extension-name=AmbiguousExtension2,
 extension-onType=String
*/
extension AmbiguousExtension2 on String {
  /*member: AmbiguousExtension2|unambiguousStaticMethod1:
   builder-name=unambiguousStaticMethod1,
   member-name=AmbiguousExtension2|unambiguousStaticMethod1
  */
  static void unambiguousStaticMethod1() {}
}

/*class: UnambiguousExtension1:
 builder-name=UnambiguousExtension1,
 builder-onType=String,
 extension-members=[
  static ambiguousStaticMethod2=UnambiguousExtension1|ambiguousStaticMethod2],
 extension-name=UnambiguousExtension1,
 extension-onType=String
*/
extension UnambiguousExtension1 on String {
  /*member: UnambiguousExtension1|ambiguousStaticMethod2:
   builder-name=ambiguousStaticMethod2,
   member-name=UnambiguousExtension1|ambiguousStaticMethod2
  */
  static void ambiguousStaticMethod2() {}
}
