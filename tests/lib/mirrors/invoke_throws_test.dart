// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.invoke_throws_test;

@MirrorsUsed(targets: "test.invoke_throws_test")
import 'dart:mirrors';

import 'package:expect/expect.dart';

class MyException {}

class Class {
  Class.noException();
  Class.generative() {
    throw new MyException();
  }
  Class.redirecting() : this.generative();
  factory Class.faktory() {
    throw new MyException();
  }
  factory Class.redirectingFactory() = Class.faktory;

  get getter {
    throw new MyException();
  }

  set setter(v) {
    throw new MyException();
  }

  method() {
    throw new MyException();
  }

  noSuchMethod(invocation) {
    throw new MyException();
  }

  static get staticGetter {
    throw new MyException();
  }

  static set staticSetter(v) {
    throw new MyException();
  }

  static staticFunction() {
    throw new MyException();
  }
}

get libraryGetter {
  throw new MyException();
}

set librarySetter(v) {
  throw new MyException();
}

libraryFunction() {
  throw new MyException();
}

main() {
  InstanceMirror im = reflect(new Class.noException());
  Expect.throws(() => im.getField(#getter), (e) => e is MyException);
  Expect.throws(() => im.setField(#setter, ['arg']), (e) => e is MyException);
  Expect.throws(() => im.invoke(#method, []), (e) => e is MyException);
  Expect.throws(
      () => im.invoke(#triggerNoSuchMethod, []), (e) => e is MyException);

  ClassMirror cm = reflectClass(Class);
  Expect.throws(() => cm.getField(#staticGetter), (e) => e is MyException);
  Expect.throws(
      () => cm.setField(#staticSetter, ['arg']), (e) => e is MyException);
  Expect.throws(() => cm.invoke(#staticFunction, []), (e) => e is MyException);
  Expect.throws(() => cm.newInstance(#generative, []), (e) => e is MyException);
  Expect.throws(
      () => cm.newInstance(#redirecting, []), (e) => e is MyException);
  Expect.throws(() => cm.newInstance(#faktory, []), (e) => e is MyException);
  Expect.throws(
      () => cm.newInstance(#redirectingFactory, []), (e) => e is MyException);

  LibraryMirror lm = reflectClass(Class).owner;
  Expect.throws(() => lm.getField(#libraryGetter), (e) => e is MyException);
  Expect.throws(
      () => lm.setField(#librarySetter, ['arg']), (e) => e is MyException);
  Expect.throws(() => lm.invoke(#libraryFunction, []), (e) => e is MyException);
}
