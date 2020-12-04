// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[HiddenExtension2,ShownExtension2]*/

/*class: HiddenExtension2:
 builder-name=HiddenExtension2,
 builder-onType=String,
 extension-members=[static staticMethod=HiddenExtension2|staticMethod],
 extension-name=HiddenExtension2,
 extension-onType=String
*/
extension HiddenExtension2 on String {
  /*member: HiddenExtension2|staticMethod:
   builder-name=staticMethod,
   member-name=HiddenExtension2|staticMethod
  */
  static void staticMethod() {}
}

/*class: ShownExtension2:
 builder-name=ShownExtension2,
 builder-onType=String,
 extension-members=[static staticMethod=ShownExtension2|staticMethod],
 extension-name=ShownExtension2,
 extension-onType=String
*/
extension ShownExtension2 on String {
  /*member: ShownExtension2|staticMethod:
   builder-name=staticMethod,
   member-name=ShownExtension2|staticMethod
  */
  static void staticMethod() {}
}
