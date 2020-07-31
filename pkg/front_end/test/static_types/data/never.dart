// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe:nnbd.library: nnbd=true*/

// TODO(johnniwinther): Ensure static type of Never access is Never.

propertyGet(Never never) {
  var v1 = /*cfe:nnbd.Never*/ never. /*cfe:nnbd.dynamic*/ foo;
  var v2 = /*cfe:nnbd.Never*/ never. /*cfe:nnbd.int!*/ hashCode;
  var v3 = /*cfe:nnbd.Never*/ never. /*cfe:nnbd.Type!*/ runtimeType;
  var v4 = /*cfe:nnbd.Never*/ never. /*cfe:nnbd.dynamic*/ toString;
  var v5 = /*cfe:nnbd.Never*/ never. /*cfe:nnbd.dynamic*/ noSuchMethod;
}

propertySet(Never never) {
  var v1 = /*cfe:nnbd.Never*/ never
      . /*cfe:nnbd.update: int!*/ foo = /*cfe:nnbd.int!*/ 42;
}

methodInvocation(Never never, Invocation invocation) {
  var v1 = /*cfe:nnbd.Never*/ never. /*cfe:nnbd.invoke: dynamic*/ foo();
  var v2 = /*cfe:nnbd.Never*/ never. /*cfe:nnbd.invoke: dynamic*/ hashCode();
  var v3 = /*cfe:nnbd.Never*/ never. /*cfe:nnbd.invoke: dynamic*/ runtimeType();
  var v4 = /*cfe:nnbd.Never*/ never. /*cfe:nnbd.invoke: dynamic*/ toString();
  var v5 = /*cfe:nnbd.Never*/ never
      . /*cfe:nnbd.invoke: dynamic*/ toString(foo: /*cfe:nnbd.int!*/ 42);
  var v6 = /*cfe:nnbd.Never*/ never. /*cfe:nnbd.invoke: dynamic*/ noSuchMethod(
      /*cfe:nnbd.Invocation!*/ invocation);
  var v7 = /*cfe:nnbd.Never*/ never
      . /*cfe:nnbd.invoke: dynamic*/ noSuchMethod(/*cfe:nnbd.int!*/ 42);
}

equals(Never never) {
  var v1 = /*cfe:nnbd.Never*/ never /*cfe:nnbd.invoke: bool!*/ == /*cfe:nnbd.Null*/ null;
  var v2 = /*cfe:nnbd.Never*/ never /*cfe:nnbd.invoke: bool!*/ == /*cfe:nnbd.Never*/ never;
}

operator(Never never) {
  var v1 = /*cfe:nnbd.Never*/ never /*cfe:nnbd.invoke: dynamic*/ + /*cfe:nnbd.Never*/ never;
  var v2 = /*cfe:nnbd.invoke: dynamic*/ - /*cfe:nnbd.Never*/ never;
  var v3 = /*cfe:nnbd.Never*/ never /*cfe:nnbd.dynamic*/ [
      /*cfe:nnbd.Never*/ never];
  var v4 = /*cfe:nnbd.Never*/ never /*cfe:nnbd.update: dynamic*/ [
      /*cfe:nnbd.Never*/ never] = /*cfe:nnbd.Never*/ never;
}
