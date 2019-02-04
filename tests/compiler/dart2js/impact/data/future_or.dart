// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";

/*element: main:
 dynamic=[runtimeType],
 runtimeType=[unknown:FutureOr<int>],
 static=[Future.value(1),assertIsSubtype(5),print(1),throwTypeError(1)],
 type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]
*/
@pragma('dart2js:disableFinal')
void main() {
  FutureOr<int> i = new Future<int>.value(0);
  print(i.runtimeType);
}
