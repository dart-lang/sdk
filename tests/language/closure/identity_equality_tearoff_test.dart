// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Test identity and equality of function/method tearoffs.

void checkIdentical(Object o1, Object o2) {
  Expect.isTrue(identical(o1, o2));
  Expect.isTrue(o1 == o2 && o2 == o1);
}

void checkEqual(Object o1, Object o2) {
  Expect.isTrue(o1 == o2 && o2 == o1);
  // The behavior of `identical` is unspecified, optimizations could
  // make a difference and should be allowed: Do not expect anything.
}

void checkUnequal(Object o1, Object o2) {
  Expect.isTrue(o1 != o2 && o2 != o1);
  // We expect that `identical` is never true when `==` yields false.
  Expect.isFalse(identical(o1, o2));
}

class CheckIdentical {
  const CheckIdentical(Object o1, Object o2) : assert(identical(o1, o2));
}

class CheckNotIdentical {
  const CheckNotIdentical(Object o1, Object o2) : assert(!identical(o1, o2));
}

void topLevelFunction() {}
X? genericTopLevelFunction<X>() => null;

class A {
  static void staticMethod() {}
  static X? genericStaticMethod<X>() => null;

  void instanceMethod() {}
  X? genericInstanceMethod<X>() => null;
}

const cTopLevelFunction = topLevelFunction;
const cGenericTopLevelFunction = genericTopLevelFunction;
const cStaticMethod = A.staticMethod;
const cGenericStaticMethod = A.genericStaticMethod;

const int? Function() cIntTopLevelFunction1 = genericTopLevelFunction;
const int? Function() cIntStaticMethod1 = A.genericStaticMethod;
const int? Function() cIntTopLevelFunction2 = genericTopLevelFunction;
const int? Function() cIntStaticMethod2 = A.genericStaticMethod;

const String? Function() cStringTopLevelFunction = genericTopLevelFunction;
const String? Function() cStringStaticMethod = A.genericStaticMethod;

int? Function() vIntTopLevelFunction1 = genericTopLevelFunction;
int? Function() vIntStaticMethod1 = A.genericStaticMethod;
int? Function() vIntTopLevelFunction2 = genericTopLevelFunction;
int? Function() vIntStaticMethod2 = A.genericStaticMethod;

String? Function() vStringTopLevelFunction = genericTopLevelFunction;
String? Function() vStringStaticMethod = A.genericStaticMethod;

void main() {
  var vTopLevelFunction = topLevelFunction;
  var vGenericTopLevelFunction = genericTopLevelFunction;
  var vStaticMethod = A.staticMethod;
  var vGenericStaticMethod = A.genericStaticMethod;

  var a = A();
  var vInstanceMethod = a.instanceMethod;
  var vGenericInstanceMethod = a.genericInstanceMethod;

  checkIdentical(topLevelFunction, topLevelFunction);
  checkIdentical(A.staticMethod, A.staticMethod);
  checkEqual(a.instanceMethod, a.instanceMethod);
  checkIdentical(genericTopLevelFunction, genericTopLevelFunction);
  checkIdentical(A.genericStaticMethod, A.genericStaticMethod);
  checkEqual(a.genericInstanceMethod, a.genericInstanceMethod);
  checkIdentical(topLevelFunction, cTopLevelFunction);
  checkIdentical(A.staticMethod, cStaticMethod);
  checkIdentical(genericTopLevelFunction, cGenericTopLevelFunction);
  checkIdentical(A.genericStaticMethod, cGenericStaticMethod);
  checkIdentical(topLevelFunction, vTopLevelFunction);
  checkIdentical(A.staticMethod, vStaticMethod);
  checkEqual(a.instanceMethod, vInstanceMethod);
  checkIdentical(genericTopLevelFunction, vGenericTopLevelFunction);
  checkIdentical(A.genericStaticMethod, vGenericStaticMethod);
  checkEqual(a.genericInstanceMethod, vGenericInstanceMethod);
  checkIdentical(cTopLevelFunction, vTopLevelFunction);
  checkIdentical(cStaticMethod, vStaticMethod);
  checkIdentical(cGenericTopLevelFunction, vGenericTopLevelFunction);
  checkIdentical(cGenericStaticMethod, vGenericStaticMethod);

  int? Function() vIntInstanceMethod1 = a.genericInstanceMethod;
  int? Function() vIntInstanceMethod2 = a.genericInstanceMethod;
  String? Function() vStringInstanceMethod = a.genericInstanceMethod;

  checkIdentical(cIntTopLevelFunction1, cIntTopLevelFunction2);
  checkIdentical(cIntStaticMethod1, cIntStaticMethod2);
  checkIdentical(cIntTopLevelFunction1, vIntTopLevelFunction2);
  checkIdentical(cIntStaticMethod1, vIntStaticMethod2);
  checkIdentical(vIntTopLevelFunction1, vIntTopLevelFunction2);
  checkIdentical(vIntStaticMethod1, vIntStaticMethod2);

  const CheckIdentical(topLevelFunction, topLevelFunction);
  const CheckIdentical(A.staticMethod, A.staticMethod);
  const CheckIdentical(genericTopLevelFunction, genericTopLevelFunction);
  const CheckIdentical(A.genericStaticMethod, A.genericStaticMethod);
  const CheckIdentical(topLevelFunction, cTopLevelFunction);
  const CheckIdentical(A.staticMethod, cStaticMethod);
  const CheckIdentical(genericTopLevelFunction, cGenericTopLevelFunction);
  const CheckIdentical(A.genericStaticMethod, cGenericStaticMethod);
  const CheckIdentical(cIntTopLevelFunction1, cIntTopLevelFunction2);
  const CheckIdentical(cIntStaticMethod1, cIntStaticMethod2);

  checkUnequal(topLevelFunction, genericTopLevelFunction);
  checkUnequal(topLevelFunction, A.staticMethod);
  checkUnequal(topLevelFunction, A.genericStaticMethod);
  checkUnequal(topLevelFunction, a.instanceMethod);
  checkUnequal(topLevelFunction, a.genericInstanceMethod);
  checkUnequal(genericTopLevelFunction, topLevelFunction);
  checkUnequal(genericTopLevelFunction, A.staticMethod);
  checkUnequal(genericTopLevelFunction, A.genericStaticMethod);
  checkUnequal(genericTopLevelFunction, a.instanceMethod);
  checkUnequal(genericTopLevelFunction, a.genericInstanceMethod);
  checkUnequal(A.staticMethod, topLevelFunction);
  checkUnequal(A.staticMethod, genericTopLevelFunction);
  checkUnequal(A.staticMethod, A.genericStaticMethod);
  checkUnequal(A.staticMethod, a.instanceMethod);
  checkUnequal(A.staticMethod, a.genericInstanceMethod);
  checkUnequal(A.genericStaticMethod, topLevelFunction);
  checkUnequal(A.genericStaticMethod, genericTopLevelFunction);
  checkUnequal(A.genericStaticMethod, A.staticMethod);
  checkUnequal(A.genericStaticMethod, a.instanceMethod);
  checkUnequal(A.genericStaticMethod, a.genericInstanceMethod);
  checkUnequal(a.instanceMethod, topLevelFunction);
  checkUnequal(a.instanceMethod, genericTopLevelFunction);
  checkUnequal(a.instanceMethod, A.staticMethod);
  checkUnequal(a.instanceMethod, A.genericStaticMethod);
  checkUnequal(a.instanceMethod, a.genericInstanceMethod);
  checkUnequal(a.genericInstanceMethod, topLevelFunction);
  checkUnequal(a.genericInstanceMethod, genericTopLevelFunction);
  checkUnequal(a.genericInstanceMethod, A.staticMethod);
  checkUnequal(a.genericInstanceMethod, A.genericStaticMethod);
  checkUnequal(a.genericInstanceMethod, a.instanceMethod);
  checkUnequal(topLevelFunction, cGenericTopLevelFunction);
  checkUnequal(topLevelFunction, cStaticMethod);
  checkUnequal(topLevelFunction, cGenericStaticMethod);
  checkUnequal(genericTopLevelFunction, cTopLevelFunction);
  checkUnequal(genericTopLevelFunction, cStaticMethod);
  checkUnequal(genericTopLevelFunction, cGenericStaticMethod);
  checkUnequal(A.staticMethod, cTopLevelFunction);
  checkUnequal(A.staticMethod, cGenericTopLevelFunction);
  checkUnequal(A.staticMethod, cGenericStaticMethod);
  checkUnequal(A.genericStaticMethod, cTopLevelFunction);
  checkUnequal(A.genericStaticMethod, cGenericTopLevelFunction);
  checkUnequal(A.genericStaticMethod, cStaticMethod);
  checkUnequal(a.instanceMethod, cTopLevelFunction);
  checkUnequal(a.instanceMethod, cGenericTopLevelFunction);
  checkUnequal(a.instanceMethod, cStaticMethod);
  checkUnequal(a.instanceMethod, cGenericStaticMethod);
  checkUnequal(a.genericInstanceMethod, cTopLevelFunction);
  checkUnequal(a.genericInstanceMethod, cGenericTopLevelFunction);
  checkUnequal(a.genericInstanceMethod, cStaticMethod);
  checkUnequal(a.genericInstanceMethod, cGenericStaticMethod);
  checkUnequal(topLevelFunction, vGenericTopLevelFunction);
  checkUnequal(topLevelFunction, vStaticMethod);
  checkUnequal(topLevelFunction, vGenericStaticMethod);
  checkUnequal(topLevelFunction, vInstanceMethod);
  checkUnequal(topLevelFunction, vGenericInstanceMethod);
  checkUnequal(genericTopLevelFunction, vTopLevelFunction);
  checkUnequal(genericTopLevelFunction, vStaticMethod);
  checkUnequal(genericTopLevelFunction, vGenericStaticMethod);
  checkUnequal(genericTopLevelFunction, vInstanceMethod);
  checkUnequal(genericTopLevelFunction, vGenericInstanceMethod);
  checkUnequal(A.staticMethod, vTopLevelFunction);
  checkUnequal(A.staticMethod, vGenericTopLevelFunction);
  checkUnequal(A.staticMethod, vGenericStaticMethod);
  checkUnequal(A.staticMethod, vInstanceMethod);
  checkUnequal(A.staticMethod, vGenericInstanceMethod);
  checkUnequal(A.genericStaticMethod, vTopLevelFunction);
  checkUnequal(A.genericStaticMethod, vGenericTopLevelFunction);
  checkUnequal(A.genericStaticMethod, vStaticMethod);
  checkUnequal(A.genericStaticMethod, vInstanceMethod);
  checkUnequal(A.genericStaticMethod, vGenericInstanceMethod);
  checkUnequal(a.instanceMethod, vTopLevelFunction);
  checkUnequal(a.instanceMethod, vGenericTopLevelFunction);
  checkUnequal(a.instanceMethod, vStaticMethod);
  checkUnequal(a.instanceMethod, vGenericStaticMethod);
  checkUnequal(a.instanceMethod, vGenericInstanceMethod);
  checkUnequal(a.genericInstanceMethod, vTopLevelFunction);
  checkUnequal(a.genericInstanceMethod, vGenericTopLevelFunction);
  checkUnequal(a.genericInstanceMethod, vStaticMethod);
  checkUnequal(a.genericInstanceMethod, vGenericStaticMethod);
  checkUnequal(a.genericInstanceMethod, vInstanceMethod);
  checkUnequal(cTopLevelFunction, vGenericTopLevelFunction);
  checkUnequal(cTopLevelFunction, vStaticMethod);
  checkUnequal(cTopLevelFunction, vGenericStaticMethod);
  checkUnequal(cTopLevelFunction, vInstanceMethod);
  checkUnequal(cTopLevelFunction, vGenericInstanceMethod);
  checkUnequal(cGenericTopLevelFunction, vTopLevelFunction);
  checkUnequal(cGenericTopLevelFunction, vStaticMethod);
  checkUnequal(cGenericTopLevelFunction, vGenericStaticMethod);
  checkUnequal(cGenericTopLevelFunction, vInstanceMethod);
  checkUnequal(cGenericTopLevelFunction, vGenericInstanceMethod);
  checkUnequal(cStaticMethod, vTopLevelFunction);
  checkUnequal(cStaticMethod, vGenericTopLevelFunction);
  checkUnequal(cStaticMethod, vGenericStaticMethod);
  checkUnequal(cStaticMethod, vInstanceMethod);
  checkUnequal(cStaticMethod, vGenericInstanceMethod);
  checkUnequal(cGenericStaticMethod, vTopLevelFunction);
  checkUnequal(cGenericStaticMethod, vGenericTopLevelFunction);
  checkUnequal(cGenericStaticMethod, vStaticMethod);
  checkUnequal(cGenericStaticMethod, vInstanceMethod);
  checkUnequal(cGenericStaticMethod, vGenericInstanceMethod);

  var a2 = A();
  var v2InstanceMethod = a2.instanceMethod;
  var v2GenericInstanceMethod = a2.genericInstanceMethod;

  checkUnequal(vInstanceMethod, v2InstanceMethod);
  checkUnequal(vGenericInstanceMethod, v2GenericInstanceMethod);

  const CheckNotIdentical(topLevelFunction, genericTopLevelFunction);
  const CheckNotIdentical(topLevelFunction, A.staticMethod);
  const CheckNotIdentical(topLevelFunction, A.genericStaticMethod);
  const CheckNotIdentical(genericTopLevelFunction, topLevelFunction);
  const CheckNotIdentical(genericTopLevelFunction, A.staticMethod);
  const CheckNotIdentical(genericTopLevelFunction, A.genericStaticMethod);
  const CheckNotIdentical(A.staticMethod, topLevelFunction);
  const CheckNotIdentical(A.staticMethod, genericTopLevelFunction);
  const CheckNotIdentical(A.staticMethod, A.genericStaticMethod);
  const CheckNotIdentical(A.genericStaticMethod, topLevelFunction);
  const CheckNotIdentical(A.genericStaticMethod, genericTopLevelFunction);
  const CheckNotIdentical(A.genericStaticMethod, A.staticMethod);
  const CheckNotIdentical(topLevelFunction, cGenericTopLevelFunction);
  const CheckNotIdentical(topLevelFunction, cStaticMethod);
  const CheckNotIdentical(topLevelFunction, cGenericStaticMethod);
  const CheckNotIdentical(genericTopLevelFunction, cTopLevelFunction);
  const CheckNotIdentical(genericTopLevelFunction, cStaticMethod);
  const CheckNotIdentical(genericTopLevelFunction, cGenericStaticMethod);
  const CheckNotIdentical(A.staticMethod, cTopLevelFunction);
  const CheckNotIdentical(A.staticMethod, cGenericTopLevelFunction);
  const CheckNotIdentical(A.staticMethod, cGenericStaticMethod);
  const CheckNotIdentical(A.genericStaticMethod, cTopLevelFunction);
  const CheckNotIdentical(A.genericStaticMethod, cGenericTopLevelFunction);
  const CheckNotIdentical(A.genericStaticMethod, cStaticMethod);

  checkUnequal(cIntTopLevelFunction1, cIntStaticMethod1);
  checkUnequal(cIntTopLevelFunction1, vIntStaticMethod1);
  checkUnequal(cIntTopLevelFunction1, vIntInstanceMethod1);
  checkUnequal(cIntStaticMethod1, vIntTopLevelFunction1);
  checkUnequal(cIntStaticMethod1, vIntInstanceMethod1);
  checkUnequal(vIntTopLevelFunction1, vIntStaticMethod1);
  checkUnequal(vIntTopLevelFunction1, vIntInstanceMethod1);
  checkUnequal(vIntStaticMethod1, vIntInstanceMethod1);

  int? Function() v2IntInstanceMethod = a2.genericInstanceMethod;

  checkUnequal(vIntInstanceMethod1, v2IntInstanceMethod);
  checkUnequal(vIntInstanceMethod1, vStringInstanceMethod);

  const CheckNotIdentical(cIntTopLevelFunction1, cIntStaticMethod1);

  const CheckNotIdentical(cIntTopLevelFunction1, cStringTopLevelFunction);
  const CheckNotIdentical(cIntStaticMethod1, cStringStaticMethod);

  <X>() {
    X? Function() vXTopLevelFunction1 = genericTopLevelFunction;
    X? Function() vXStaticMethod1 = A.genericStaticMethod;
    X? Function() vXTopLevelFunction2 = genericTopLevelFunction;
    X? Function() vXStaticMethod2 = A.genericStaticMethod;
    X? Function() vXInstanceMethod1 = a.genericInstanceMethod;
    X? Function() vXInstanceMethod2 = a.genericInstanceMethod;

    checkUnequal(vXTopLevelFunction1, vXStaticMethod1);
    checkUnequal(vXTopLevelFunction1, vXInstanceMethod1);
    checkUnequal(vXStaticMethod1, vXInstanceMethod1);

    int? Function() v2XInstanceMethod = a2.genericInstanceMethod;

    checkUnequal(vXInstanceMethod1, v2XInstanceMethod);
    checkUnequal(vXInstanceMethod1, vStringInstanceMethod);
  }<int>();
}
