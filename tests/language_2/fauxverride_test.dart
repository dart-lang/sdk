// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test the semantics of static members mixed with instance members.

// Following are relevant quotes from Dart Programming Language
// Specification, Draft Version 0.10, June 7, 2012.

// 7 Classes:

// "It is a compile-time error if a class has an instance method and a
// static member method with the same name."

// 7.1 Instance Methods:

// "Instance methods are functions (6) whose declarations are
// immediately contained within a class declaration and that are not
// declared static. The instance methods of a class C are those
// instance methods declared by C and the instance methods inherited
// by C from its superclass."

// 7.6 Static Methods

// "Static methods are functions whose declarations are immediately
// contained within a class declaration and that are declared
// static. The static methods of a class C are those static methods
// declared by C."

// 7.7 Static Variables

// "Static variables are variables whose declarations are immediately
// contained within a class declaration and that are declared
// static. The static variables of a class C are those static
// variables declared by C."

// "A static variable declaration of one of the forms static T v;,
// static T v = e; , static const T v = e; or static final T v = e;
// always induces an implicit static getter function (7.2) with
// signature static T get v whose invocation evaluates as described
// below (7.7.1)."

m() => 'top level';

class Super {
  // No error from hiding.
  static m() => 'super';

  static var i = 'super';

  static var i2 = 'super';

  instanceMethod() => m();

  instanceMethod2() => m();
}

class Sub extends Super {
  // According to 7.6, static methods are not inherited.
  static m() => 'sub';

  // According to 7.7, static variables are not inherited.
  static var i = 'sub';

  // According to 7.1, instance methods include those of the
  // superclass, and according to 7, it is a compile-time to have an
  // instance method and static method with the same name.
  static //# 03: compile-time error
  instanceMethod() => m();

  // According to 7.7, static variables are not inherited.
  static i2() => m();

  // According to 7.1, instance methods include those of the
  // superclass, and according to 7, it is a compile-time to have an
  // instance method and static method with the same
  // name. Furthermore, according to 7.7 a static variable induces an
  // implicit getter function (a static method).
  static var instanceMethod2; //# 05: compile-time error

  foo() => 'foo';
}

main() {
  Expect.equals('foo', new Sub().foo());
  Expect.equals('top level', m());
  Expect.equals('super', Super.m());
  Expect.equals('sub', Sub.m());
  Expect.equals('super', Super.i);
  Expect.equals('sub', Sub.i);
  Expect.equals('super', Super.i2);
  Expect.equals('sub', Sub.i2());
  Expect.equals('super', new Super().instanceMethod());
  Expect.equals('sub', new Sub().instanceMethod());
  Expect.equals('super', new Super().instanceMethod2());
  Expect.equals('super', new Sub().instanceMethod2());
}
