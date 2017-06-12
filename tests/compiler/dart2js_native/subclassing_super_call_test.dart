// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";
import 'dart:_js_helper' show setNativeSubclassDispatchRecord;
import 'dart:_interceptors'
    show findInterceptorForType, findConstructorForNativeSubclassType;

// Test for super access from classes that extend native classes.

@Native("N1")
class N1 {}

@Native("N2")
class N2 extends N1 {
  N2.init();
  String text;
  foo() native;
}

class AA extends N2 {
  AA.init() : super.init();
  String afield;
  afun() => 'afun:$afield';
}

class BB extends AA {
  BB.init() : super.init();

  get text => super.text;
  set text(value) => super.text = value;
  foo() => super.foo();

  get afield => super.afield;
  set afield(value) => super.afield = value;
  afun() => super.afun();
}

BB makeBB() native;

@Creates('=Object')
getBBPrototype() native;

void setup() native r"""
function N2() {}
N2.prototype.foo = function() { return "foo:" + this.text; }
function BB() {}
BB.prototype.__proto__ = N2.prototype;
makeBB = function(){return new BB;};

getBBPrototype = function(){return BB.prototype;};
""";

testSuperOnNative() {
  BB b1 = makeBB();
  BB b2 = makeBB();

  var constructor = findConstructorForNativeSubclassType(BB, 'init');
  Expect.isNotNull(constructor);
  JS('', '#(#)', constructor, b1);
  JS('', '#(#)', constructor, b2);

  b1.text = confuse('one');
  b2.text = confuse('two');

  print('b1.text ${confuse(b1).text}');
  print('b2.text ${confuse(b2).text}');

  print('b1.foo() ${confuse(b1).foo()}');
  print('b2.foo() ${confuse(b2).foo()}');

  Expect.equals('one', b1.text);
  Expect.equals('two', b2.text);

  Expect.equals('foo:one', b1.foo());
  Expect.equals('foo:two', b2.foo());

  confuse(b1).text = confuse('three');
  confuse(b2).text = confuse('four');

  Expect.equals('three', confuse(b1).text);
  Expect.equals('four', confuse(b2).text);

  Expect.equals('foo:three', confuse(b1).foo());
  Expect.equals('foo:four', confuse(b2).foo());
}

testSuperOnSubclassOfNative() {
  BB b1 = makeBB();
  BB b2 = makeBB();

  var constructor = findConstructorForNativeSubclassType(BB, 'init');
  Expect.isNotNull(constructor);
  JS('', '#(#)', constructor, b1);
  JS('', '#(#)', constructor, b2);

  b1.afield = confuse('one');
  b2.afield = confuse('two');

  print('b1.afield ${confuse(b1).afield}');
  print('b2.afield ${confuse(b2).afield}');

  print('b1.afun() ${confuse(b1).afun()}');
  print('b2.afun() ${confuse(b2).afun()}');

  Expect.equals('one', b1.afield);
  Expect.equals('two', b2.afield);

  Expect.equals('afun:one', b1.afun());
  Expect.equals('afun:two', b2.afun());

  confuse(b1).afield = confuse('three');
  confuse(b2).afield = confuse('four');

  Expect.equals('three', confuse(b1).afield);
  Expect.equals('four', confuse(b2).afield);

  Expect.equals('afun:three', confuse(b1).afun());
  Expect.equals('afun:four', confuse(b2).afun());
}

main() {
  nativeTesting();
  setup();

  setNativeSubclassDispatchRecord(getBBPrototype(), findInterceptorForType(BB));

  testSuperOnNative();
  testSuperOnSubclassOfNative();
}
