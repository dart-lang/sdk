// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'shared.dart' deferred as s1;

/*member: doA:
 OutputUnit(main, {}),
 constants=[ConstructedConstant(C())=OutputUnit(1, {s1, s2})]
*/
doA() async {
  await s1.loadLibrary();
  return s1.constant;
}
