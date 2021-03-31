// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'lib_shared.dart';

@pragma('dart2js:noInline')
createA() {
  return A();
}

@pragma('dart2js:noInline')
isB(foo) {
  return foo is B;
}

class C extends C_Parent {}

@pragma('dart2js:noInline')
createC() {
  return C();
}

@pragma('dart2js:noInline')
createE() {
  return E();
}

@pragma('dart2js:noInline')
isFWithUnused(foo) {
  var unused = F();
  return foo is F;
}
