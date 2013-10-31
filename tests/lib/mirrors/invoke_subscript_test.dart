// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.invoke_subscript_test;

import 'dart:mirrors';
import 'package:expect/expect.dart';

class Super {
  inheritedMethod(a, b) => a + b;
  staticFunctionInSuper(x) => x;
}

class Class extends Super {
  var field = 'f';
  get getter => 'g';
  set setter(v) => 's';
  method(x, y, z) => '$x-$y-$z';
  methodWithNamed(x, {y, z:'Z'}) => '$x+$y+$z';
  methodWithOptPos(x, [y, z='Z']) => '$x*$y*$z';

  static var staticField = 'sf';
  static get staticGetter => 'sg';
  static set staticSetter(v) => 'ss';
  static staticFunction(x, y, z) => '$x-$y-$z';
  static staticFunctionWithNamed(x, {y, z:'Z'}) => '$x+$y+$z';
  static staticFunctionWithOptPos(x, [y, z='Z']) => '$x*$y*$z';

}

var toplevelField ='tf';
get toplevelGetter => 'tg';
set toplevelSetter(v) => 'ts';
toplevelFunction(x, y, z) => '$x-$y-$z';
toplevelFunctionWithNamed(x, {y, z:'Z'}) => '$x+$y+$z';
toplevelFunctionWithOptPos(x, [y, z='Z']) => '$x*$y*$z';

expectArgumentError(f) {
  Expect.throws(f, (e) => e is ArgumentError);
}

main() {
  InstanceMirror im = reflect(new Class());
  Expect.equals('A-B-C', im[#method]('A', 'B', 'C').reflectee);
  Expect.throws(() => im[#method]('A', 'B', 'C', 'D'),
                (e) => e is NoSuchMethodError,
                'Wrong arity');
  Expect.equals(7, im[#inheritedMethod](3, 4).reflectee);
  expectArgumentError(() => im[#field]);
  expectArgumentError(() => im[#getter]);
  expectArgumentError(() => im[#setter]);
  expectArgumentError(() => im[#doesntExist]);
  expectArgumentError(() => im[#staticFunction]);

  ClassMirror cm = reflectClass(Class);
  Expect.equals('A-B-C', cm[#staticFunction]('A', 'B', 'C').reflectee);
  Expect.throws(() => cm[#staticFunction]('A', 'B', 'C', 'D'),
                (e) => e is NoSuchMethodError,
                'Wrong arity');
  expectArgumentError(() => cm[#staticField]);
  expectArgumentError(() => cm[#staticGetter]);
  expectArgumentError(() => cm[#staticSetter]);
  expectArgumentError(() => cm[#staticDoesntExist]);
  expectArgumentError(() => cm[#staticFunctionInSuper]);
  expectArgumentError(() => cm[#method]);

  LibraryMirror lm = cm.owner;
  Expect.equals('A-B-C', lm[#toplevelFunction]('A', 'B', 'C').reflectee);
  Expect.throws(() => lm[#toplevelFunction]('A', 'B', 'C', 'D'),
                (e) => e is NoSuchMethodError,
                'Wrong arity');

  expectArgumentError(() => lm[#toplevelField]);
  expectArgumentError(() => lm[#toplevelGetter]);
  expectArgumentError(() => lm[#toplevelSetter]);
  expectArgumentError(() => lm[#toplevelDoesntExist]);

  // dart2js might stop testing here.

  Expect.equals('A+B+Z', im[#methodWithNamed]('A', y: 'B').reflectee);
  Expect.equals('A*B*Z', im[#methodWithOptPos]('A', 'B').reflectee);
  Expect.throws(() => im[#methodWithNamed]('A', w: 'D'),
                (e) => e is NoSuchMethodError,
                'Wrong arity');
  Expect.throws(() => im[#method](),
                (e) => e is NoSuchMethodError,
                'Wrong arity');

  Expect.equals('A+B+Z', cm[#staticFunctionWithNamed]('A', y: 'B').reflectee);
  Expect.equals('A*B*Z', cm[#staticFunctionWithOptPos]('A', 'B').reflectee);
  Expect.throws(() => cm[#staticFunctionWithNamed]('A', w: 'D'),
                (e) => e is NoSuchMethodError,
                'Wrong arity');
  Expect.throws(() => cm[#staticFunctionWithOptPos](),
                (e) => e is NoSuchMethodError,
                'Wrong arity');

  Expect.equals('A+B+Z', lm[#toplevelFunctionWithNamed]('A', y: 'B').reflectee);
  Expect.equals('A*B*Z', lm[#toplevelFunctionWithOptPos]('A', 'B').reflectee);
  Expect.throws(() => lm[#toplevelFunctionWithNamed]('A', w: 'D'),
                (e) => e is NoSuchMethodError,
                'Wrong arity');
  Expect.throws(() => lm[#toplevelFunctionWithOptPos](),
                (e) => e is NoSuchMethodError,
                'Wrong arity');
}
