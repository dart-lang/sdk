// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';

import 'dart:_interceptors';

dynamic makeBigIntDynamic(String name) native;
JavaScriptBigInt makeBigInt(String name) native;

void setup() {
  JS('', r"""
(function(){
  self.makeBigInt = function(name){return BigInt(name)};
  self.makeBigIntDynamic = function(name){return BigInt(name)};
})()""");
}

main() {
  nativeTesting();
  setup();
  const s = '9876543210000000000000123456789';

  Expect.notEquals(s, makeBigInt(s));
  Expect.notEquals(s, makeBigIntDynamic(s));

  Expect.equals(s, makeBigInt(s).toString());
  Expect.equals(s, makeBigIntDynamic(s).toString());
  Expect.equals(s, '${makeBigInt(s)}');
  Expect.equals(s, '${makeBigIntDynamic(s)}');
}
