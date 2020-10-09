// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'shared.dart' deferred as s2;

/*member: doB:
 constants=[ConstructedConstant(C())=1{s1, s2}],
 member_unit=main{}
*/
doB() async {
  await s2.loadLibrary();
  return s2.constant;
}
