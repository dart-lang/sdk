// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test for instance field initializer expressions.

import "package:expect/expect.dart";

class Cheese {
  static const mild = 1;
  static const stinky = 2;

  // Instance fields with initializer expression.
  String name = "";
  var smell = mild;

  Cheese() {
    Expect.equals("", this.name);
    Expect.equals(Cheese.mild, this.smell);
  }

  Cheese.initInBlock(String s) {
    Expect.equals("", this.name);
    Expect.equals(Cheese.mild, this.smell);
    this.name = s;
  }

  Cheese.initFieldParam(this.name, this.smell) {}

  // Test that static const field Cheese.mild is not shadowed
  // by the parameter mild when compiling the field initializer
  // for instance field smell.
  Cheese.hideAndSeek(var mild) : name = mild {
    Expect.equals(mild, this.name);
    Expect.equals(Cheese.mild, this.smell);
  }
}

class HasNoExplicitConstructor {
  String s = "Tilsiter";
}

main() {
  var generic = new Cheese();
  Expect.equals("", generic.name);
  Expect.equals(Cheese.mild, generic.smell);

  var gruyere = new Cheese.initInBlock("Gruyere");
  Expect.equals("Gruyere", gruyere.name);
  Expect.equals(Cheese.mild, gruyere.smell);

  var munster = new Cheese.initFieldParam("Munster", Cheese.stinky);
  Expect.equals("Munster", munster.name);
  Expect.equals(Cheese.stinky, munster.smell);

  var brie = new Cheese.hideAndSeek("Brie");
  Expect.equals("Brie", brie.name);
  Expect.equals(Cheese.mild, brie.smell);

  var t = new HasNoExplicitConstructor();
  Expect.equals("Tilsiter", t.s);
}
