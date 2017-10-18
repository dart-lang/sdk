// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// From Dart Language Specification, 0.12 M1, "7.6.2 Factories": It is
// a compile-time error if a redirecting factory constructor does not
// redirect to a non-redirecting factory constructor or to a
// generative constructor in a finite number of steps.

// TODO(ahe): The above specification will probably change to
// something like: "It is a compile-time error if a redirecting
// factory constructor redirects to itself, either directly or
// indirectly via a sequence of redirections."

class Foo extends Bar {
  factory Foo() = Bar; //# 01: compile-time error
}

class Bar {
  factory Bar() = Foo; //# 02: compile-time error
}

main() {
  new Foo();
}
