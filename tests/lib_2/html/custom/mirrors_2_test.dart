// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tests.html.mirrors_2_test;

@MirrorsUsed(targets: "tests.html.mirrors_2_test")
import 'dart:mirrors';
import 'dart:html';
import 'package:expect/expect.dart' show NoInline;
import 'package:test/test.dart';
import '../utils.dart';

/// Regression test for http://dartbug/28196
///
/// The constructor of a mixin application of a subclass of a Html element is
/// normally not used. With mirrors the constructor can become available. The
/// body of the factory has a 'receiver' with an exact type that is the mixin
/// application. The constructor body functions of the superclasses are called
/// using the interceptor calling convention. This creates an interceptor
/// constant of the mixin application type.  In issue 28196 the constant has a
/// name containing '+' symbols, causing the program to crash during
/// initializing the constant pool.

main() {
  var registered = false;
  setUp(() => customElementsReady.then((_) {
        if (!registered) {
          registered = true;
          document.registerElement(A.tag, A);
          document.registerElement(B.tag, B);
        }
      }));

  test('reflectClass', () {
    expect('AA', new A().token());
    expect('MM', new B().token());
    reflectClass(B);
  });
}

class A extends HtmlElement {
  static final tag = 'x-a';
  factory A() => new Element.tag(tag);

  A.created() : super.created() {
    // This function must not be inlined otherwise there is no reference to the
    // interceptor constant. The `@NoInline()` annotation does not seem reliable
    // on generative constructor bodies.
    try {
      uninlinedMethod();
      uninlinedMethod();
      uninlinedMethod();
    } finally {
      uninlinedMethod();
      uninlinedMethod();
      uninlinedMethod();
    }
  }
  @NoInline()
  uninlinedMethod() {}

  token() => 'AA';
}

class B extends A with M {
  static final tag = 'x-b';
  factory B() => new Element.tag(tag);
  B.created() : super.created();
}

class M {
  token() => 'MM';
}
