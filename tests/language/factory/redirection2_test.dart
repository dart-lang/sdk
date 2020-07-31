// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that it is a compile-time error to have a redirection in a
// non-factory constructor.

class Foo {
  Foo()
  = Bar
//^
// [analyzer] SYNTACTIC_ERROR.REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR
// [cfe] Expected a function body or '=>'.
//^
// [cfe] Only factory constructor can specify '=' redirection.
//  ^
// [cfe] Constructors can't have a return type.
  ;
}

class Bar extends Foo {
  factory Bar() => Bar._();

  Bar._();
}

main() {
  Expect.isTrue(new Foo() is Foo);
  Expect.isFalse(new Foo() is Bar);
}
