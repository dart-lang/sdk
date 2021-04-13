// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'lib_shared.dart';

@pragma('dart2js:noInline')
/*member: isA:member_unit=3{liba}*/
isA(foo) {
  return foo is A;
}

@pragma('dart2js:noInline')
/*member: isD:member_unit=3{liba}*/
isD(foo) {
  return foo is D;
}
