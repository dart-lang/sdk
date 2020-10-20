// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[NamedExtension,_extension#0]*/

/*class: _extension#0:
 builder-name=_extension#0,
 builder-onType=String,
 extension-members=[static staticMethod=_extension#0|staticMethod],
 extension-name=_extension#0,
 extension-onType=String
*/
extension on String {
  /*member: _extension#0|staticMethod:
   builder-name=staticMethod,
   member-name=_extension#0|staticMethod
  */
  static void staticMethod() {}
}

/*class: NamedExtension:
 builder-name=NamedExtension,
 builder-onType=String,
 extension-members=[static staticMethod=NamedExtension|staticMethod],
 extension-name=NamedExtension,
 extension-onType=String
*/
extension NamedExtension on String {
  /*member: NamedExtension|staticMethod:
    builder-name=staticMethod,
    member-name=NamedExtension|staticMethod
  */
  static void staticMethod() {}
}
