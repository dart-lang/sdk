// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.metadata_scope;

import 'dart:mirrors';
import 'package:expect/expect.dart';

class Annotation {
  final contents;
  const Annotation(this.contents);
  toString() => "Annotation($contents)";
}

// Note there is no compile-time constant 'foo' in scope. In particular, A.foo
// is not in scope here.
@Annotation(foo) // //# 01: compile-time error
class A<@Annotation(foo) T> {
  @Annotation(foo)
  static foo() {}

  @Annotation(foo)
  static bar() {}
}

@Annotation(B.foo)
class B<@Annotation(B.foo) T> {
  @Annotation(B.foo)
  static foo() {}

  @Annotation(B.foo)
  static bar() {}
}

baz() {}

// Note the top-level function baz is in scope here, not C.baz.
@Annotation(baz)
class C<@Annotation(baz) T> {
  @Annotation(baz)
  static baz() {}
}

checkMetadata(DeclarationMirror mirror, List expectedMetadata) {
  Expect.listEquals(expectedMetadata.map(reflect).toList(), mirror.metadata);
}

main() {
  reflectClass(A).metadata;
  checkMetadata(reflectClass(A).declarations[#T], [const Annotation(A.foo)]);
  checkMetadata(reflectClass(A).declarations[#foo], [const Annotation(A.foo)]);
  checkMetadata(reflectClass(A).declarations[#bar], [const Annotation(A.foo)]);
  checkMetadata(reflectClass(B), [const Annotation(B.foo)]);
  checkMetadata(reflectClass(B).declarations[#T], [const Annotation(B.foo)]);
  checkMetadata(reflectClass(B).declarations[#foo], [const Annotation(B.foo)]);
  checkMetadata(reflectClass(B).declarations[#bar], [const Annotation(B.foo)]);
  // The top-level function baz, not C.baz.
  checkMetadata(reflectClass(C), [const Annotation(baz)]);
  // C.baz, not the top-level function baz.
  checkMetadata(reflectClass(C).declarations[#T], [const Annotation(C.baz)]);
  checkMetadata(reflectClass(C).declarations[#baz], [const Annotation(C.baz)]);
}
