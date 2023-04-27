// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/minitest.dart';

import 'utils.dart';

class A {
  int x = 42;
  String arity1(int val) {
    val += 10;
    return val.toString();
  }
}

String arity1(int val) {
  val += 10;
  return val.toString();
}

void main() {
  group('Dynamic call of', () {
    dynamic instanceOfA = A();
    test('instance of a class with no `call()` method', () {
      try {
        instanceOfA();
      } on NoSuchMethodError catch (error) {
        var message = error.toString();
        expectStringContains("NoSuchMethodError: 'call'", message);
        expectStringContains("Receiver: Instance of 'A'", message);
      }
    });
    group('class instance', () {
      group('method tearoff', () {
        dynamic tearoff = instanceOfA.arity1;
        test('passing too many arguments', () {
          try {
            tearoff(1, 2);
          } on NoSuchMethodError catch (error) {
            var message = error.toString();
            expectStringContains("NoSuchMethodError: 'bound arity1'", message);
            expectStringContains('too many arguments', message);
          }
        });
        test('passing too few arguments', () {
          try {
            tearoff();
          } on NoSuchMethodError catch (error) {
            var message = error.toString();
            expectStringContains("NoSuchMethodError: 'bound arity1'", message);
            expectStringContains('too few arguments', message);
          }
        });
      });
    });
    group('top level function tearoff', () {
      dynamic dynamicFunction = arity1;
      test('passing too many arguments', () {
        try {
          dynamicFunction(1, 2);
        } on NoSuchMethodError catch (error) {
          var message = error.toString();
          expectStringContains("NoSuchMethodError: 'arity1'", message);
          expectStringContains('too many arguments', message);
        }
      });
      test('passing too few arguments', () {
        try {
          dynamicFunction();
        } on NoSuchMethodError catch (error) {
          var message = error.toString();
          expectStringContains("NoSuchMethodError: 'arity1'", message);
          expectStringContains('too few arguments', message);
        }
      });
    });
  });

  group('`Function.apply()`', () {
    dynamic dynamicFunction = arity1;
    group('top level function tearoff', () {
      test('passing too many arguments', () {
        try {
          Function.apply(dynamicFunction, [1, 2]);
        } on NoSuchMethodError catch (error) {
          var message = error.toString();
          expectStringContains("NoSuchMethodError: 'arity1'", message);
          expectStringContains('too many arguments', message);
        }
      });
      test('passing too few arguments', () {
        try {
          Function.apply(dynamicFunction, []);
        } on NoSuchMethodError catch (error) {
          var message = error.toString();
          expectStringContains("NoSuchMethodError: 'arity1'", message);
          expectStringContains('too few arguments', message);
        }
      });
    });
  });
}
