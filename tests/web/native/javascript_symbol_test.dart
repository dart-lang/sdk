// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';

import 'dart:_interceptors';

dynamic makeSymbolDynamic(String name) native;
JavaScriptSymbol makeSymbol(String name) native;

void setup() {
  JS('', r"""
(function(){
  self.makeSymbol = function(name){return Symbol(name)};
  self.makeSymbolDynamic = function(name){return Symbol(name)};
})()""");
}

main() {
  nativeTesting();
  setup();

  Expect.notEquals('Symbol(foo)', makeSymbol('foo'));
  Expect.notEquals('Symbol(foo)', makeSymbolDynamic('foo'));

  Expect.equals('Symbol(foo)', makeSymbol('foo').toString());
  Expect.equals('Symbol(foo)', makeSymbolDynamic('foo').toString());
  Expect.equals('Symbol(foo)', '${makeSymbol('foo')}');
  Expect.equals('Symbol(foo)', '${makeSymbolDynamic('foo')}');
}
