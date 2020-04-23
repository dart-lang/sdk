// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that initializers for final fields are evaluated in the right
// order.

int counter = 0;

class Mark {
  static StringBuffer buffer;
  Mark(value) {
    buffer.write('$value.');
  }
}

class OneField {
  final a = new Mark('a');
  OneField();
}

class TwoFields {
  final a = new Mark('a');
  final b = new Mark('b');
  TwoFields();
}

class InheritOneField extends OneField {
  final b = new Mark('b');
  InheritOneField();
}

class MixedFields extends OneField {
  final b = new Mark('b');
  var c = new Mark('c');
  final d = new Mark('d');
  MixedFields();
  MixedFields.c0() : c = new Mark('cc');
  MixedFields.c1()
      : c = new Mark('cc'),
        super();
}

String run(callback) {
  Mark.buffer = new StringBuffer();
  callback();
  return Mark.buffer.toString();
}

main() {
  Expect.equals('a.', run(() => new OneField()));
  Expect.equals('a.b.', run(() => new TwoFields()));
  Expect.equals('b.a.', run(() => new InheritOneField()));

  Expect.equals('b.c.d.a.', run(() => new MixedFields()));
  Expect.equals('b.c.d.cc.a.', run(() => new MixedFields.c0()));
  Expect.equals('b.c.d.cc.a.', run(() => new MixedFields.c1()));
}
