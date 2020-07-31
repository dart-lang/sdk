// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

propertyGet(Never never) {
  var v1 = never.foo;
  var v2 = never.hashCode;
  var v3 = never.runtimeType;
  var v4 = never.toString;
  var v5 = never.noSuchMethod;
}

propertySet(Never never) {
  var v1 = never.foo = 42;
}

methodInvocation(Never never, Invocation invocation) {
  var v1 = never.foo();
  var v2 = never.hashCode();
  var v3 = never.runtimeType();
  var v4 = never.toString();
  var v5 = never.toString(foo: 42);
  var v6 = never.noSuchMethod(invocation);
  var v7 = never.noSuchMethod(42);
}

equals(Never never) {
  var v1 = never == null;
  var v2 = never == never;
}

operator(Never never) {
  var v1 = never + never;
  var v2 = -never;
  var v3 = never[never];
  var v4 = never[never] = never;
}

main() {}
