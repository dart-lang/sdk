// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Context type is propagated down in an if-null `??` expression.

import 'package:expect/expect.dart';

import '../dot_shorthand_helper.dart';

ConstructorClass ctorTest(ConstructorClass? ctor) => ctor ?? .new(1);

ConstructorClass ctorRegularTest(ConstructorClass? ctor) => ctor ?? .regular(1);

void noContextLHSContext(ConstructorClass? ctor) {
  ctor ?? .new(1);
  ctor ?? .regular(1);
}

ConstructorExt ctorExtTest(ConstructorExt? ctor) => ctor ?? .new(1);

ConstructorExt ctorExtRegularTest(ConstructorExt? ctor) => ctor ?? .regular(1);

void noContextLHSContextExt(ConstructorExt? ctor) {
  ctor ?? .new(1);
  ctor ?? .regular(1);
}

void main() {
  // Class
  var ctorDefault = ConstructorClass(2);

  Expect.isNotNull(ctorTest(null));
  Expect.equals(ctorTest(ctorDefault), ctorDefault);

  Expect.isNotNull(ctorRegularTest(null));
  Expect.equals(ctorRegularTest(ctorDefault), ctorDefault);

  noContextLHSContext(null);
  noContextLHSContext(ctorDefault);

  // Extension type
  var ctorExtDefault = ConstructorExt(2);

  Expect.isNotNull(ctorExtTest(null));
  Expect.equals(ctorExtTest(ctorExtDefault), ctorExtDefault);

  Expect.isNotNull(ctorExtRegularTest(null));
  Expect.equals(ctorExtRegularTest(ctorExtDefault), ctorExtDefault);

  noContextLHSContextExt(null);
  noContextLHSContextExt(ctorExtDefault);
}
