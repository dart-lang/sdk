// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: scope=[
  NamedExtension,
  _extension#1]*/

/*class: _extension#1:
 builder-name=_unnamed-extension_,
 builder-onType=String,
 extension-members=[static staticMethod=_extension#1|staticMethod],
 extension-name=_extension#1,
 extension-onType=String!
*/
extension on String {
  /*member: _extension#1|staticMethod:
   builder-name=staticMethod,
   member-name=_extension#1|staticMethod
  */
  static void staticMethod() {}
}

/*class: NamedExtension:
 builder-name=NamedExtension,
 builder-onType=String,
 extension-members=[static staticMethod=NamedExtension|staticMethod],
 extension-name=NamedExtension,
 extension-onType=String!
*/
extension NamedExtension on String {
  /*member: NamedExtension|staticMethod:
    builder-name=staticMethod,
    member-name=NamedExtension|staticMethod
  */
  static void staticMethod() {}
}
