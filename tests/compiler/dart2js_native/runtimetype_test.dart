// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:_js_helper";
import 'dart:_foreign_helper' show JS;

// Test to see runtimeType works on native classes and does not use the native
// constructor name.

@Native("TAGX")
class A {
}

@Native("TAGY")
class B extends A {
}

makeA() native;
makeB() native;

void setup() native """
// This code is all inside 'setup' and so not accesible from the global scope.
function inherits(child, parent) {
  function tmp() {};
  tmp.prototype = parent.prototype;
  child.prototype = new tmp();
  child.prototype.constructor = child;
}

function TAGX(){}
function TAGY(){}
inherits(TAGY, TAGX);

makeA = function(){return new TAGX};
makeB = function(){return new TAGY};
""";


testDynamicContext() {
  var a = makeA();
  var b = makeB();

  var aT = a.runtimeType;
  var bT = b.runtimeType;

  Expect.notEquals('TAGX', '$aT');
  Expect.notEquals('TAGY', '$bT');
}

testStaticContext() {
  var a = JS('A', '#', makeA());  // Force compiler to know type.
  var b = JS('B', '#', makeB());

  var aT = a.runtimeType;
  var bT = b.runtimeType;

  Expect.notEquals('TAGX', '$aT');
  Expect.notEquals('TAGY', '$bT');
}

main() {
  setup();

  testDynamicContext();
  testStaticContext();
}
