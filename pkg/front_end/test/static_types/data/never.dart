// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*cfe:nnbd.library: nnbd=true*/

// TODO(johnniwinther): Ensure static type of Never access is Never.

propertyGet(Never never) {
  var v1 = /*cfe:nnbd.Never*/ never. /*cfe:nnbd.Never*/ foo;
  var v2 = /*cfe:nnbd.Never*/ never. /*cfe:nnbd.Never*/ hashCode;
  var v3 = /*cfe:nnbd.Never*/ never. /*cfe:nnbd.Never*/ runtimeType;
  var v4 = /*cfe:nnbd.Never*/ never. /*cfe:nnbd.Never*/ toString;
  var v5 = /*cfe:nnbd.Never*/ never. /*cfe:nnbd.Never*/ noSuchMethod;
}

propertySet(Never never) {
  var v1 = /*cfe:nnbd.Never*/ never
      . /*cfe:nnbd.update: int!*/ foo = /*cfe:nnbd.int!*/ 42;
}

methodInvocation(Never never, Invocation invocation) {
  var v1 = /*cfe:nnbd.Never*/ never. /*cfe:nnbd.invoke: Never*/ foo();
  var v2 = /*cfe:nnbd.Never*/ never. /*cfe:nnbd.invoke: Never*/ hashCode();
  var v3 = /*cfe:nnbd.Never*/ never. /*cfe:nnbd.invoke: Never*/ runtimeType();
  var v4 = /*cfe:nnbd.Never*/ never. /*cfe:nnbd.invoke: Never*/ toString();
  var v5 = /*cfe:nnbd.Never*/ never
      . /*cfe:nnbd.invoke: Never*/ toString(foo: /*cfe:nnbd.int!*/ 42);
  var v6 = /*cfe:nnbd.Never*/ never. /*cfe:nnbd.invoke: Never*/ noSuchMethod(
      /*cfe:nnbd.Invocation!*/ invocation);
  var v7 = /*cfe:nnbd.Never*/ never
      . /*cfe:nnbd.invoke: Never*/ noSuchMethod(/*cfe:nnbd.int!*/ 42);
}

equals(Never never) {
  var v1 = /*cfe:nnbd.Never*/ never /*cfe:nnbd.invoke: bool!*/ == null;
  var v2 = /*cfe:nnbd.Never*/ never /*cfe:nnbd.invoke: Never*/ == /*cfe:nnbd.Never*/ never;
}

operator(Never never) {
  var v1 = /*cfe:nnbd.Never*/ never /*cfe:nnbd.invoke: Never*/ + /*cfe:nnbd.Never*/ never;
  var v2 = /*cfe:nnbd.invoke: Never*/ - /*cfe:nnbd.Never*/ never;
  var v3 = /*cfe:nnbd.Never*/ never /*cfe:nnbd.Never*/ [
      /*cfe:nnbd.Never*/ never];
  var v4 = /*cfe:nnbd.Never*/ never /*cfe:nnbd.update: Never*/ [
      /*cfe:nnbd.Never*/ never] = /*cfe:nnbd.Never*/ never;
}
