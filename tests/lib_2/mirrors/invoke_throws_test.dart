// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.invoke_throws_test;

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

bool isMyException(e) => e is MyException;

main() {
  InstanceMirror im = reflect(new Class.noException());
  Expect.throws(() => im.getField(#getter), isMyException);
  Expect.throws(() => im.setField(#setter, ['arg']), isMyException);
  Expect.throws(() => im.invoke(#method, []), isMyException);
  Expect.throws(() => im.invoke(#triggerNoSuchMethod, []), isMyException);

  ClassMirror cm = reflectClass(Class);
  Expect.throws(() => cm.getField(#staticGetter), isMyException);
  Expect.throws(() => cm.setField(#staticSetter, ['arg']), isMyException);
  Expect.throws(() => cm.invoke(#staticFunction, []), isMyException);
  Expect.throws(() => cm.newInstance(#generative, []), isMyException);
  Expect.throws(() => cm.newInstance(#redirecting, []), isMyException);
  Expect.throws(() => cm.newInstance(#faktory, []), isMyException);
  Expect.throws(() => cm.newInstance(#redirectingFactory, []), isMyException);

  LibraryMirror lm = reflectClass(Class).owner;
  Expect.throws(() => lm.getField(#libraryGetter), isMyException);
  Expect.throws(() => lm.setField(#librarySetter, ['arg']), isMyException);
  Expect.throws(() => lm.invoke(#libraryFunction, []), isMyException);
}
