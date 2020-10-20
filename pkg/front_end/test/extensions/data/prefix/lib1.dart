// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[HiddenExtension1,ShownExtension1]*/

/*class: ShownExtension1:
 builder-name=ShownExtension1,
 builder-onType=String,
 extension-members=[static staticMethod=ShownExtension1|staticMethod],
 extension-name=ShownExtension1,
 extension-onType=String
*/
extension ShownExtension1 on String {
  /*member: ShownExtension1|staticMethod:
   builder-name=staticMethod,
   member-name=ShownExtension1|staticMethod
  */
  static void staticMethod() {}
}

/*class: HiddenExtension1:
 builder-name=HiddenExtension1,
 builder-onType=String,
 extension-members=[static staticMethod=HiddenExtension1|staticMethod],
 extension-name=HiddenExtension1,
 extension-onType=String
*/
extension HiddenExtension1 on String {
  /*member: HiddenExtension1|staticMethod:
   builder-name=staticMethod,
   member-name=HiddenExtension1|staticMethod
  */
  static void staticMethod() {}
}
