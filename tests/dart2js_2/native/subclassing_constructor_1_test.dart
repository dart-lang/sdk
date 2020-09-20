// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "native_testing.dart";
import 'dart:_js_helper' show setNativeSubclassDispatchRecord;
import 'dart:_interceptors'
    show findInterceptorForType, findConstructorForNativeSubclassType;

// Test that subclasses of native classes can be initialized by calling the
// 'upgrade' constructor.

var trace = [];

var log;

@Native("A")
class A {
  final a1 = log(101); // Only initialized IF named constructor called.
  get a2 native; // Initialized by native constructor.
  var a3; // Initialized only by A.two.
  var a4 = log(104);

  A.one();

  A.two() : a3 = log(103) {
    log('body(A.two)');
    log(a4 += increment);
  }

  A.three(x, this.a4) {
    log('body(A.three)');
    log(a4 = '($a4, $x)');
  }

  get increment => 10;
}

class B extends A {
  var b1;
  final b2 = log(202);
  var b3;

  B.one() : super.one();

  B.two()
      : b1 = log(201),
        b3 = log(203),
        super.two() {
    log('body(B.two)');
  }

  B.three([x]) : super.three(205, x);

  get increment => 20;
}

makeB() native;

@Creates('=Object')
getBPrototype() native;

void setup() {
  JS('', r"""
(function(){
  function B() { this.a2 = 102; }

  makeB = function(){return new B()};

  getBPrototype = function(){return B.prototype;};
})()""");
}

test_one() {
  trace = [];
  var constructor = findConstructorForNativeSubclassType(B, 'one');
  Expect.isNotNull(constructor);
  Expect.isNull(findConstructorForNativeSubclassType(B, 'Missing'));

  var b = makeB();
  Expect.isTrue(b is B);
  // Call constructor to initialize native object.
  var b2 = JS('', '#(#)', constructor, b);
  Expect.identical(b, b2);
  Expect.isTrue(b is B);

  Expect.equals(101, b.a1);
  Expect.equals(102, b.a2);
  Expect.equals(null, b.a3);
  Expect.equals(104, b.a4);
  Expect.equals(null, b.b1);
  Expect.equals(202, b.b2);
  Expect.equals(null, b.b3);

  Expect.equals('[202, 101, 104]', '$trace');
}

test_two() {
  trace = [];
  var constructor = findConstructorForNativeSubclassType(B, 'two');
  Expect.isNotNull(constructor);

  var b = makeB();
  Expect.isTrue(b is B);
  // Call constructor to initialize native object.
  JS('', '#(#)', constructor, b);
  Expect.isTrue(b is B);

  Expect.equals(101, b.a1);
  Expect.equals(102, b.a2);
  Expect.equals(103, b.a3);
  Expect.equals(124, b.a4);
  Expect.equals(201, b.b1);
  Expect.equals(202, b.b2);
  Expect.equals(203, b.b3);

  Expect.equals('[202, 201, 101, 104, 103, 203, body(A.two), 124, body(B.two)]',
      '$trace');
}

test_three() {
  trace = [];
  var constructor = findConstructorForNativeSubclassType(B, 'three');
  Expect.isNotNull(constructor);

  var b = makeB();
  Expect.isTrue(b is B);
  // Call constructor to initialize native object.
  //
  // Since the constructor takes some optional arguments that are not passed, it
  // is as though the web components runtime explicitly passed `null` for all
  // parameters.
  //
  // TODO(sra): The constructor returned by findConstructorForNativeSubclassType
  // should be a function that fills in the default values.
  JS('', '#(#)', constructor, b);
  Expect.isTrue(b is B);

  Expect.equals(101, b.a1);
  Expect.equals(102, b.a2);
  Expect.equals(null, b.a3);
  Expect.equals('(null, 205)', b.a4);
  Expect.equals(null, b.b1);
  Expect.equals(202, b.b2);
  Expect.equals(null, b.b3);
  print(trace);
  Expect.equals('[202, 101, 104, body(A.three), (null, 205)]', '$trace');
}

test_new() {
  trace = [];
  checkThrows(action, description) {
    Expect.throws(action, (e) => true, "'$description must fail'");
  }

  checkThrows(() => new B.one(), 'new B.one()');
  checkThrows(() => new B.two(), 'new B.two()');
  checkThrows(() => new B.three(), 'new B.three()');
  checkThrows(() => new B.three(1), 'new B.three(1)');
  checkThrows(() => new B.three([]), 'new B.three([])');
}

main() {
  nativeTesting();
  setup();
  log = (message) {
    trace.add('$message');
    return message;
  };

  setNativeSubclassDispatchRecord(getBPrototype(), findInterceptorForType(B));

  test_one();
  test_two();
  test_three();
  test_new();
}
