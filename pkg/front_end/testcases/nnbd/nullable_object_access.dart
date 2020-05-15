// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class CustomType extends Type {
  void call() {}
}

abstract class CustomInvocation implements Invocation {}

abstract class Class {
  CustomType get runtimeType;
  String noSuchMethod(covariant CustomInvocation invocation);
  bool operator ==(covariant Class o);
  String toString({Object o});
}

main() {}

void test(Class c1, Class? c2, Invocation invocation,
    CustomInvocation customInvocation) {
  CustomType runtimeType1 = c1.runtimeType; // ok
  var runtimeTypeVariable1 = c1.runtimeType;
  c1.runtimeType(); // ok

  String Function(CustomInvocation) noSuchMethodTearOff1 =
      c1.noSuchMethod; // ok
  var noSuchMethodTearOffVariable1 = c1.noSuchMethod;

  String noSuchMethod1a = c1.noSuchMethod(customInvocation); // ok
  String noSuchMethod1b = c1.noSuchMethod(invocation); // error
  var noSuchMethodVariable1 = c1.noSuchMethod(customInvocation);

  c1 == ''; // error
  c1 == c2; // ok

  String Function({Object o}) toStringTearOff1 = c1.toString; // ok
  var toStringTearOffVariable1 = c1.toString;

  c1.toString(o: c1); // ok

  CustomType runtimeType2 = c2.runtimeType; // error
  var runtimeTypeVariable2 = c2.runtimeType;
  c2.runtimeType(); // error

  String Function(CustomInvocation) noSuchMethodTearOff2 =
      c2.noSuchMethod; // error
  var noSuchMethodTearOffVariable2 = c2.noSuchMethod;

  int noSuchMethod2 = c2.noSuchMethod(invocation); // ok
  var noSuchMethodVariable2 = c2.noSuchMethod(invocation);

  // TODO(johnniwinther): Awaiting spec update about `==`. Before NNBD this
  // would cause an error but with the current (insufficient) specification for
  // `==` it is ok (even though `c1 == ''` is an error).
  c2 == ''; // ok or error?
  c2 == c1; // ok

  String Function({Object o}) toStringTearOff2 = c2.toString; // error
  var toStringTearOffVariable2 = c2.toString;

  c2.toString(o: c1); // error
}
