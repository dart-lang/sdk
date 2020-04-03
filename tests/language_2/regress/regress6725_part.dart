// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for a crash in dart2js.

part of crash_6725;

class Fisk {
  it1(x) {
    // "key" is unresolved and caused a crash in dart2js.
    // This is the original example the user reported.
    for (key in x) {
      print(key);
    }
  }

  it2(x) {
    // "length" is "intercepted" and handled differently from other
    // names when an instance of list is observed.
    for (length in x) {
      print(length);
    }
  }

  it3(x) {
    // We're pretty sure that there's no "fisk" that is "intercepted".
    for (fisk in x) {
      print(fisk);
    }
  }
}

class SubFisk extends Fisk {
  var key;
  var length;
  var fisk;
}

test() {
  Fisk f = new SubFisk();
  var m = (x) {
    for (undeclared in x) {
      print(undeclared);
    }
  };
  if (new DateTime.now().millisecondsSinceEpoch == 42) {
    f = null;
    m = (x) {};
  }

  f.it1([87, 42]);
  if (f.key != 42) {
    throw 'f.key != 42 (${f.key})';
  }

  f.it2([87, 42]);
  if (f.length != 42) {
    throw 'f.length != 42 (${f.length})';
  }

  f.it3([87, 42]);
  if (f.fisk != 42) {
    throw 'f.fisk != 42 (${f.fisk})';
  }

  try {
    m([87, 42]);
    throw 'NoSuchMethodError expected';
  } on NoSuchMethodError {
    // Expected.
  }
}
