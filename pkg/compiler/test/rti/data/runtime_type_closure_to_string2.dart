// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:compiler/src/util/testing.dart';

class Class<T> {
  Class();
}

main() {
  /*spec.needsArgs,needsSignature*/
  local1<T>() {}

  /*spec.needsArgs,needsSignature,selectors=[Selector(call, call, arity=2, types=1)]*/
  local2<T>(t, s) => t;

  makeLive('${local1.runtimeType}');
  local2(0, '');
  new Class();
}
