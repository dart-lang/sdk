// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(johnniwinther): Ensure static type of Never access is Never.

propertyGet(Never never) {
  var v1 = /*Never*/never. /*Never*/foo;
  var v2 = /*Never*/never. /*Never*/hashCode;
  var v3 = /*Never*/never. /*Never*/runtimeType;
  var v4 = /*Never*/never. /*Never*/toString;
  var v5 = /*Never*/never. /*Never*/noSuchMethod;
}

propertySet(Never never) {
  var v1 = /*Never*/never
      . /*update: int!*/foo = /*int!*/42;
}

methodInvocation(Never never, Invocation invocation) {
  var v1 = /*Never*/never. /*invoke: Never*/foo();
  var v2 = /*Never*/never. /*invoke: Never*/hashCode();
  var v3 = /*Never*/never. /*invoke: Never*/runtimeType();
  var v4 = /*Never*/never. /*invoke: Never*/toString();
  var v5 = /*Never*/never
      . /*invoke: Never*/toString(foo: /*int!*/42);
  var v6 = /*Never*/never. /*invoke: Never*/noSuchMethod(
      /*Invocation!*/invocation);
  var v7 = /*Never*/never
      . /*invoke: Never*/noSuchMethod(/*int!*/42);
}

equals(Never never) {
  var v1 = /*Never*/never /*invoke: bool!*/== null;
  var v2 = /*Never*/never /*invoke: Never*/== /*Never*/never;
}

operator(Never never) {
  var v1 = /*Never*/never /*invoke: Never*/+ /*Never*/never;
  var v2 = /*invoke: Never*/- /*Never*/never;
  var v3 = /*Never*/never /*Never*/[
      /*Never*/never];
  var v4 = /*Never*/never /*update: Never*/[
      /*Never*/never] = /*Never*/never;
}
