// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that field initializers are evaluated in the right order.

int counter = 0;

class Mark {
  static StringBuffer buffer;
  Mark(value) {
    buffer.write('$value.');
  }
}

class OneField {
  var a = new Mark('a');

  OneField();

  OneField.init() : a = new Mark('ai');
}

class TwoFields {
  var b = new Mark('b');
  var a = new Mark('a');

  TwoFields();

  TwoFields.initA() : a = new Mark('ai');

  TwoFields.initB() : b = new Mark('bi');

  TwoFields.initBoth()
      : a = new Mark('ai'),
        b = new Mark('bi');
}

class InheritOneField extends OneField {
  var b = new Mark('b');

  InheritOneField() : super();

  InheritOneField.init()
      : b = new Mark('bi'),
        super();

  InheritOneField.superWithInit() : super.init();

  InheritOneField.initWithSuperInit_correctOrder()
      : b = new Mark('bi'),
        super.init();

  InheritOneField.initWithSuperInit_incorrectOrder()
      :
        super.init(), //# 01: compile-time error
        b = new Mark('bi')
        , super.init() //# none: ok
  ;
}

String run(callback) {
  Mark.buffer = new StringBuffer();
  callback();
  return Mark.buffer.toString();
}

main() {
  Expect.equals('a.', run(() => new OneField()));
  Expect.equals('a.ai.', run(() => new OneField.init()));

  Expect.equals('b.a.', run(() => new TwoFields()));
  Expect.equals('b.a.ai.', run(() => new TwoFields.initA()));
  Expect.equals('b.a.bi.', run(() => new TwoFields.initB()));
  Expect.equals('b.a.ai.bi.', run(() => new TwoFields.initBoth()));

  Expect.equals('b.a.', run(() => new InheritOneField()));
  Expect.equals('b.bi.a.', run(() => new InheritOneField.init()));
  Expect.equals('b.a.ai.', run(() => new InheritOneField.superWithInit()));
  Expect.equals(
      'b.bi.a.ai.', run(() => new InheritOneField.initWithSuperInit_correctOrder()));
  Expect.equals(
      'b.a.ai.bi.', run(() => new InheritOneField.initWithSuperInit_incorrectOrder()));
}
