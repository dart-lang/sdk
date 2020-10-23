// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../native_testing.dart';

abstract class NativeInterface {
  int get size;
  String get name;
  String? get optName;
  int method1();
  String method2();
  String? optMethod();
}

abstract class JSInterface {
  String get name;
  String? get optName;
}

class BBB implements NativeInterface {
  int get size => 300;
  String get name => 'Brenda';
  String? get optName => name;
  int method1() => 400;
  String method2() => 'brilliant!';
  String? optMethod() => method2();
}

void setup() {
  JS('', r"""
(function(){
  function AAA(s,n,m1,m2) {
    this.size = s;
    this.name = n;
    this.optName = n;
    this._m1 = m1;
    this._m2 = m2;
  }
  AAA.prototype.method1 = function(){return this._m1};
  AAA.prototype.method2 = function(){return this._m2};
  AAA.prototype.optMethod = function(){return this._m2};

  makeA = function() {
    return new AAA(100, 'Albert', 200, 'amazing!');
  };
  makeAX = function() {
    return new AAA(void 0, void 0, void 0, void 0);
  };

  self.nativeConstructor(AAA);

  function CCC(n) {
    this.name = n;
    this.optName = n;
  }

  makeC = function() {
    return new CCC('Carol');
  };
  makeCX = function() {
    return new CCC(void 0);
  };

  self.nativeConstructor(CCC);
})()""");
}

// The 'NativeInterface' version of the code is passed both native and Dart
// objects, so there will be an interceptor dispatch to the method. This tests
// that the null-check exists in the forwarding method.

@pragma('dart2js:noInline')
String describeNativeInterface(NativeInterface o) {
  return '${o.name} ${o.method2()} ${o.size} ${o.method1()}';
}

@pragma('dart2js:noInline')
String describeOptNativeInterface(NativeInterface o) {
  return '${o.optName} ${o.optMethod()}';
}

@pragma('dart2js:noInline')
String describeJSInterface(JSInterface o) {
  return '${o.name}';
}

@pragma('dart2js:noInline')
String describeOptJSInterface(JSInterface o) {
  return '${o.optName}';
}

const expectedA = 'Albert amazing! 100 200';
const expectedB = 'Brenda brilliant! 300 400';
const expectedOptA = 'Albert amazing!';
const expectedOptB = 'Brenda brilliant!';
const expectedOptX = 'null null';

const expectedC = 'Carol';
const expectedOptC = 'Carol';
const expectedOptCX = 'null';
