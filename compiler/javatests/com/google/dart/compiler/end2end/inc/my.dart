// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var x = 0, y = 1;
void fn() { /* ... */ }

class Spoo<T> {
  Spoo() { }
  Spoo.other() { }
}

main() {
  // Static method reference to Other0.
  var v = Other0.value();
  
  // Reference Other1 via new.
  var o1 = new Other1();

  // Static field reference to Other3.
  var f = Other3.field;

  // Reference SomeClass via new, and SomeClassImpl transitively.
  var sc = new SomeClass(1);
  var msg = sc.message;

  // Reference global var defined in myother0.dart
  var gv = globalVar;

  // Reference global function defined in myother0.dart
  var gf = globalFunction();
}

class Qualifiers extends QualifierBase {
  void fn() {
    // Qualified reference to Other5's field.
    var field = other5.field;

    // Qualified reference to Other6's method.
    var result = other6.method();
  }
}

// Reference Other2 by subclassing it.
class Foo extends Other2 {
  foo() {
    // unqualified reference to superclass method.
    methodHole();

    // unqualified reference to superclass field.
    return hole;
  }

  int bar() {
    // qualified reference
    return super.not_hole.contents;
  }
}

// Reference Other4 using it as a type parameter bound.
class Bar<T extends Other4> {
}
