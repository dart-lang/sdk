// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[ClashingExtension,UniqueExtension2]*/

/*class: ClashingExtension:
 builder-name=ClashingExtension,
 builder-onType=String,
 extension-members=[static staticMethod=ClashingExtension|staticMethod],
 extension-name=ClashingExtension,
 extension-onType=String
*/
extension ClashingExtension on String {
  /*member: ClashingExtension|staticMethod:
   builder-name=staticMethod,
   member-name=ClashingExtension|staticMethod
  */
  static staticMethod() {}
}

/*class: UniqueExtension2:
 builder-name=UniqueExtension2,
 builder-onType=String,
 extension-members=[static staticMethod=UniqueExtension2|staticMethod],
 extension-name=UniqueExtension2,
 extension-onType=String
*/
extension UniqueExtension2 on String {
  /*member: UniqueExtension2|staticMethod:
   builder-name=staticMethod,
   member-name=UniqueExtension2|staticMethod
  */
  static staticMethod() {}
}
