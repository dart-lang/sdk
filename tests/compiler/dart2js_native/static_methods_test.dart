// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Accessing static native methods names:
//   plain declaration ->  use @Native tag as 'scope' for declared name.
//   identifier @JSName -> use @Native tag as 'scope' for @JSName.
//   other @JSName -> use @JSName as an expression.

import 'native_testing.dart';
import 'dart:_js_helper' show convertDartClosureToJS;

typedef int Callback(String s);

@Native("CC") // Tag can be different to class name.
class AA {
  // This name is not an identifier, so completely defines how to access method.
  @JSName('CC.foo')
  static int foo(String s) native;

  // This name is not an identifier, so completely defines how to access method.
  @JSName('CC.bar')
  static int bar(Callback c) native;
  static int baz(Callback c) {
    return bar(c);
  }

  // Compiler should automatically use the tag and the declared name, i.e. call
  // `CC.lepton`.
  static int lepton(Callback c) native;
  static int electron(c) => lepton(c);

  // Compiler should automatically use the tag and JSName, i.e. call
  // `CC.baryon`.
  @JSName('baryon')
  static int _baryon(Callback c) native;
  static int proton(c) => _baryon(c);
}

void setup() native r"""
// This code is all inside 'setup' and so not accessible from the global scope.

function CC(){}

CC.foo = function(s) { return s.length; }
CC.bar = function(f) { return f("Bye"); }
CC.lepton = function(f) { return f("Lepton"); }
CC.baryon = function(f) { return f("three quarks"); }

self.CC = CC;
""";

main() {
  nativeTesting();
  setup();

  // TODO(sra): Investigate why this line is necessary to get a correctly
  // compiled convertDartClosureToJS.  Without this line, the compiler crashes.
  convertDartClosureToJS(main, 1);

  Expect.equals(5, AA.foo("Hello"));

  Expect.equals(3, AA.bar((s) => s.length));
  Expect.equals(3, AA.baz((s) => s.length));

  Expect.equals(6, AA.lepton((s) => s.length));
  Expect.equals(6, AA.electron((s) => s.length));

  Expect.equals(12, AA._baryon((s) => s.length));
  Expect.equals(12, AA.proton((s) => s.length));
  Expect.throws(() => AA.baryon((s) => s.length)); // Not defined on AA.
}
