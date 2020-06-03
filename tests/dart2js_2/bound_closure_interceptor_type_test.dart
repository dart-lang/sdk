// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

// Test for type checks against tear-off closures generated in different
// optimization contexts.
//
// The type of a tear-off closure depends on the receiver when the method
// signature uses a type parameter of the method's class.  This means that type
// checking needs to reference the receiver correctly, either during closure
// creation or during the type test.

class A<T> {
  const A();
  void add(T x) {}
  T elementAt(int index) => index == 0 ? 42 : 'string';

  // This call get:elementAt has a known receiver type, so is is potentially
  // eligible for a dummy receiver optimization.
  getElementAt() => this.elementAt;
  // Same for get:add.
  getAdd() => this.add;

  toString() => 'A<$T>';
}

var getAddOfA = (a) => a.getAdd();
var getElementAtOfA = (a) => a.getElementAt();

var getAdd1 = (a) => a.add; // receiver has unknown type here.

var getAdd2 = (a) {
  // Call needs to be indirect to avoid inlining.
  if (a is A) return getAddOfA(a);
  return a.add;
};

var getElementAt1 = (a) => a.elementAt; // receiver has unknown type here.

var getElementAt2 = (a) {
  // Call needs to be indirect to avoid inlining.
  if (a is A) return getElementAtOfA(a);
  return a.elementAt;
};

typedef void IntToVoid(int x);
typedef void StringToVoid(String x);

typedef int IntToInt(int x);
typedef String IntToString(int x);
typedef T IntToT<T>(int x);

var inscrutable;

var checkers = {
  'IntToVoid': (x) => x is IntToVoid,
  'StringToVoid': (x) => x is StringToVoid,
  'IntToInt': (x) => x is IntToInt,
  'IntToString': (x) => x is IntToString,
  'IntToT<int>': (x) => x is IntToT<int>,
  'IntToT<String>': (x) => x is IntToT<String>,
};

var methods = {
  'getAdd1': (x) => getAdd1(x),
  'getAdd2': (x) => getAdd2(x),
  'getElementAt1': (x) => getElementAt1(x),
  'getElementAt2': (x) => getElementAt2(x),
};

main() {
  inscrutable = (x) => x;

  getAdd1 = inscrutable(getAdd1);
  getAdd2 = inscrutable(getAdd2);
  getElementAt1 = inscrutable(getElementAt1);
  getElementAt2 = inscrutable(getElementAt2);
  getAddOfA = inscrutable(getAddOfA);
  getElementAtOfA = inscrutable(getElementAtOfA);

  check(methodNames, objects, trueCheckNames) {
    for (var trueCheckName in trueCheckNames) {
      if (!checkers.containsKey(trueCheckName)) {
        Expect.fail("unknown check '$trueCheckName'");
      }
    }

    for (var object in objects) {
      for (var methodName in methodNames) {
        var methodFn = methods[methodName];
        var description = '$object';
        checkers.forEach((checkName, checkFn) {
          bool answer = trueCheckNames.contains(checkName);
          Expect.equals(answer, checkFn(methodFn(object)),
              '$methodName($description) is $checkName');
        });
      }
    }
  }

  var objectsDyn = [[], new A(), new A<dynamic>()];
  var objectsInt = [<int>[], new A<int>()];
  var objectsStr = [<String>[], new A<String>()];
  var objectsLst = [<List>[], new A<List>()];

  var m = ['getAdd1', 'getAdd2'];
  check(m, objectsDyn, ['IntToVoid', 'StringToVoid']);
  check(m, objectsInt, ['IntToVoid']);
  check(m, objectsStr, ['StringToVoid']);
  check(m, objectsLst, []);

  m = ['getElementAt1', 'getElementAt2'];
  check(m, objectsDyn, [
    'IntToInt',
    'IntToString',
    'IntToVoid',
    'IntToT<int>',
    'IntToT<String>'
  ]);
  check(m, objectsInt, ['IntToInt', 'IntToVoid', 'IntToT<int>']);
  check(m, objectsStr, ['IntToString', 'IntToVoid', 'IntToT<String>']);
  check(m, objectsLst, ['IntToVoid']);
}
