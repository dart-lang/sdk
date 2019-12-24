// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N slash_for_doc_comments`

/** lib */ //LINT
library test.rules.slash_for_doc_comments;

/** My class */ //LINT
class A {}

/// OK
class B {

  /** B */ //LINT
  B();

  /** x */ //LINT
  var x;

  /** y */ //LINT
  y() {
    /** l */ //LINT
    void l() {}
  }
}

/** G */ //LINT
enum G {
  /** A */ //LINT
  A,
  B
}

/** f */ //LINT
typedef bool F();

/** f */ //LINT
typedef F2 = bool Function();

/** z */ //LINT
z() => null;

/* meh */ //OK
class C {}

/** D */ //LINT
var D = String;

/** Z */ //LINT
class Z = B with C;

/** M1 */ //LINT
mixin M1 {}

/* meh */ //OK
mixin M2 {}

/** Ext */ //LINT
extension Ext on Object {
  /** e */ // LINT
  void e() { }
}

/** Unnamed */ //LINT
extension on A { }

