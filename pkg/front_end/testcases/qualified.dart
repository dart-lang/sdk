// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.qualified.main;

import "qualified_lib.dart" as lib;

part "qualified_part.dart";

class Bad extends lib.Missing {
  lib.Missing method() {}
  factory WrongName() {}
}

class WithMixin extends lib.Supertype with lib.Mixin {}

main() {
  new C<String>();
  new C<String>.a();
  new C<String>.b();
  new lib.C<String>();
  new lib.C<String>.a();
  new lib.C<String>.b();
  new WithMixin().supertypeMethod();
  new WithMixin().foo();
}
