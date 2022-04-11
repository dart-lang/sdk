// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Test {
  Test.foo() {}
  factory Test.bar() => new Test.foo();
}

class A1 {
  A1({x, y});
}

class B1 extends A1 {
  B1.foo({super.x}) : super(y: new Test.foo());
  B1.bar({super.x}) : super(y: new Test.bar());
}

class A2 {
  A2(x, {y});
}

class B2 extends A2 {
  B2.foo(super.x) : super(y: new Test.foo());
  B2.bar(super.x) : super(y: new Test.bar());
}

class A3 {
  A3(x, {y});
}

class B3 extends A3 {
  B3.foo({super.y}) : super(new Test.foo());
  B3.bar({super.y}) : super(new Test.bar());
}

class A4 {
  const A4({x, y});
}

class B4 extends A4 {
  B4.foo({super.x}) : super(y: new Test.foo());
  B4.bar({super.x}) : super(y: new Test.bar());
}

class A5 {
  const A5(x, {y});
}

class B5 extends A5 {
  B5.foo(super.x) : super(y: new Test.foo());
  B5.bar(super.x) : super(y: new Test.bar());
}

class A6 {
  const A6(x, {y});
}

class B6 extends A6 {
  B6.foo({super.y}) : super(new Test.foo());
  B6.bar({super.y}) : super(new Test.bar());
}

class A7 {
  const A7({x, y});
}

class B7 extends A7 {
  const B7.foo({super.x}) : super(y: new Test.foo()); // Error.
  const B7.bar({super.x}) : super(y: new Test.bar()); // Error.
}

class A8 {
  const A8(x, {y});
}

class B8 extends A8 {
  const B8.foo(super.x) : super(y: new Test.foo()); // Error.
  const B8.bar(super.x) : super(y: new Test.bar()); // Error.
}

class A9 {
  const A9(x, {y});
}

class B9 extends A9 {
  const B9.foo({super.y}) : super(new Test.foo()); // Error.
  const B9.bar({super.y}) : super(new Test.bar()); // Error.
}

main() {}
