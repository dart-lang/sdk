// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_testing.dart';

abstract class Interface {
  int get size;
  String get name;
  String? get optName;
  int method1();
  String method2();
}

@Native("AAA")
class AAA implements Interface {
  int get size native;
  String get name native;
  String? get optName native;
  int method1() native;
  String method2() native;
}

/// Returns an 'AAA' object that satisfies the interface.
AAA makeA() native;

/// Returns an 'AAA' object where each method breaks the interface's contract.
AAA makeAX() native;

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

  makeA = function() {return new AAA(100, 'Albert', 200, 'amazing!')};
  makeAX = function() {return new AAA(void 0, void 0, void 0, void 0)};

  self.nativeConstructor(AAA);
})()""");
}

class BBB implements Interface {
  int get size => 300;
  String get name => 'Brenda';
  String? get optName => name;
  int method1() => 400;
  String method2() => 'brilliant!';
}

List<Interface> items = [makeA(), BBB()];
