// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@JS()
library mock_test;

import 'package:js/js.dart';
import 'package:expect/minitest.dart';

@JS()
external void eval(String code);

@JS()
class JSClass {}

@JS()
class DerivedA extends JSClass {
  external DerivedB get derivedB;
}

@JS()
external DerivedA get derivedA;

@JS()
class DerivedB extends JSClass {}

class MockDerivedA implements DerivedA {
  final DerivedB derivedB = new MockDerivedB();
}

class MockDerivedB implements DerivedB {}

void main() {
  eval(r"""
    function inherits(child, parent) {
      if (child.prototype.__proto__) {
        child.prototype.__proto__ = parent.prototype;
      } else {
        function tmp() {};
        tmp.prototype = parent.prototype;
        child.prototype = new tmp();
        child.prototype.constructor = child;
      }
    }
    function JSClass() {
    }
    function DerivedA() {
      JSClass.call(this);
      this.derivedB = new DerivedB();
    }
    inherits(DerivedA, JSClass);
    function DerivedB() {
      JSClass.call(this);
    }
    inherits(DerivedB, JSClass);
    var derivedA = new DerivedA();
  """);
  test('js', () {
    var jsA = derivedA;
    // `is` checks will return true for any two JS interop types.
    expect(jsA is JSClass, isTrue);
    expect(jsA is DerivedA, isTrue);
    expect(jsA is DerivedB, isTrue);

    expect(jsA is! MockDerivedA, isTrue);
    expect(jsA is! MockDerivedB, isTrue);
  });

  test('mock', () {
    var mockA = new MockDerivedA();
    expect(mockA is JSClass, isTrue); //# 44252: ok
    expect(mockA is DerivedA, isTrue);
    // Fails in dart2js
    // expect(mockA is! DerivedB, isTrue);
    expect(mockA is MockDerivedA, isTrue);
    expect(mockA is! MockDerivedB, isTrue);

    var mockB = mockA.derivedB;
    expect(mockB is JSClass, isTrue); //# 44252: continued
    // Fails in dart2js
    // expect(mockB is! DerivedA, isTrue);
    expect(mockB is DerivedB, isTrue);
    expect(mockB is! MockDerivedA, isTrue);
    expect(mockB is MockDerivedB, isTrue);
  });
}
