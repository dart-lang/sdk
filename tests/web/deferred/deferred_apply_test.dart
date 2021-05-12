// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong

import 'package:expect/expect.dart';
import 'deferred_apply_lib.dart' deferred as lib;

// Test that the `_Required` sentinel in apply-metadata is initialized.
//
// This test is structured so that `Function.apply` is partioned out of the main
// unit into a 'part' file. `Function.apply` contains a reference to the
// `_Required` sentinel marker, which causes the marker to also be in that part.
// The apply-metadata for the functions [foo1] and [foo2] contains references to
// the sentinel that are in the main unit.
//
// This apparent reference to the deferred-loaded constant is not a problem
// because the apply-metadata is contained in a JavaScript function which is not
// called until the function is passed to `Function.apply`. The loading of the
// part containing `Function.apply` also loads the sentinel in advance of it
// being referenced.
//
// An implicit constraint here is that the apply-metadata must not be used
// outside of code that also references the sentinel.
//
// If the apply-metadata is created eagerly, or we add other uses of the
// apply-metadata, then we would need to ensure the constant is located to be
// available at that time.

main() {
  lib.loadLibrary().then((_) {
    Expect.equals('10', lib.apply1(foo1));
    Expect.equals('10,$text1', lib.apply1(foo2));
    Expect.throws(() => lib.apply2(foo2));
  });
}

class Text {
  final String string;
  final String source;
  const Text(this.string, [this.source = '']);
  String toString() => string;
}

String foo1({required int req1}) {
  return '$req1';
}

String foo2({required int req1, Text? text = text1}) {
  return '$req1,$text';
}

const text1 = Text(r"""
Those lines that I before have writ do lie,
Even those that said I could not love you dearer:
Yet then my judgment knew no reason why
My most full flame should afterwards burn clearer.
But reckoning Time, whose million'd accidents
Creep in 'twixt vows, and change decrees of kings,
Tan sacred beauty, blunt the sharp'st intents,
Divert strong minds to the course of altering things;
Alas! why, fearing of Time's tyranny,
Might I not then say, 'Now I love you best,'
When I was certain o'er incertainty,
Crowning the present, doubting of the rest?
   Love is a babe, then might I not say so,
   To give full growth to that which still doth grow?
""");
