// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[ClashingExtension,UniqueExtension1]*/

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


/*class: UniqueExtension1:
 builder-name=UniqueExtension1,
 builder-onType=String,
 extension-members=[static staticMethod=UniqueExtension1|staticMethod],
 extension-name=UniqueExtension1,
 extension-onType=String
*/
extension UniqueExtension1 on String {
  /*member: UniqueExtension1|staticMethod:
   builder-name=staticMethod,
   member-name=UniqueExtension1|staticMethod
  */
  static staticMethod() {}
}
