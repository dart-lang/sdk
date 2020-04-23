// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:mirrors';

import 'package:expect/expect.dart';

int foobar = 1;

set foobaz(int x) {
  foobar = x;
}

void foo(Map<String, String> m) {
  print(m);
  print(m['bar']);
}

void bar<T extends num>(T a) {
  print(a);
}

class Foo {
  Map<String, String> bork;
  static Map<String, String> bark;
  static set woof(Map<String, String> x) {
    bark = x;
  }

  Foo(Map<String, String> m) {
    print(m);
  }

  Foo.a();

  static void baz(Map<String, String> m, {String bar}) {
    print('baz');
    print(m['bar']);
    print(bar);
  }

  void bar(Map<String, String> m) {
    print('bar');
    print(m.runtimeType);
  }
}

class FooBar<T extends num> {
  T bar;
  FooBar(this.bar) {
    print(bar);
  }

  set barz(T x) {
    bar = x;
  }

  factory FooBar.baz(T bar) {
    print(bar);
    return FooBar(bar);
  }

  void foobar<S>(T a, S b) {
    print(a);
    print(b);
  }
}

void badClassStaticInvoke() {
  Map<String, String> map = Map<String, String>();
  map['bar'] = 'Hello world!';
  final cm = reflectClass(Foo);
  Expect.throwsTypeError(() => cm.invoke(#baz, [
        map
      ], {
        #bar: {'boo': 'bah'}
      }));
}

void badStaticInvoke() {
  final im = reflect(foo) as ClosureMirror;
  Expect.throwsTypeError(() => im.apply(['Hello world!']));
}

void badInstanceInvoke() {
  final fooCls = Foo.a();
  final im = reflect(fooCls);
  Expect.throwsTypeError(() => im.invoke(#bar, ['Hello World!']));
}

void badConstructorInvoke() {
  final cm = reflectClass(Foo);
  Expect.throwsTypeError(() => cm.newInstance(Symbol(''), ['Hello World!']));
}

void badSetterInvoke() {
  final fooCls = Foo.a();
  final im = reflect(fooCls);
  Expect.throwsTypeError(() => im.setField(#bork, 'Hello World!'));
}

void badStaticSetterInvoke() {
  final cm = reflectClass(Foo);
  Expect.throwsTypeError(() => cm.setField(#bark, 'Hello World!'));
  Expect.throwsTypeError(() => cm.setField(#woof, 'Hello World!'));
}

void badGenericConstructorInvoke() {
  final cm = reflectType(FooBar, [int]) as ClassMirror;
  Expect.throwsTypeError(() => cm.newInstance(Symbol(''), ['Hello World!']));
}

void badGenericClassStaticInvoke() {
  final cm = reflectType(FooBar, [int]) as ClassMirror;
  final im = cm.newInstance(Symbol(''), [1]);
  Expect.throwsTypeError(() => im.invoke(#foobar, ['Hello', 'World']));
}

void badGenericFactoryInvoke() {
  final cm = reflectType(FooBar, [int]) as ClassMirror;
  Expect.throwsTypeError(() => cm.newInstance(Symbol('baz'), ['Hello World!']));
}

void badGenericStaticInvoke() {
  final im = reflect(bar) as ClosureMirror;
  Expect.throwsTypeError(() => im.apply(['Hello world!']));
}

void badGenericSetterInvoke() {
  final cm = reflectType(FooBar, [int]) as ClassMirror;
  final im = cm.newInstance(Symbol(''), [0]);
  Expect.throwsTypeError(() => im.setField(#bar, 'Hello world!'));
  Expect.throwsTypeError(() => im.setField(#barz, 'Hello world!'));
}

void badLibrarySetterInvoke() {
  final lm = currentMirrorSystem().findLibrary(Symbol(''));
  Expect.throwsTypeError(() => lm.setField(#foobar, 'Foobaz'));
  Expect.throwsTypeError(() => lm.setField(#foobaz, 'Foobaz'));
}

void main() {
  badClassStaticInvoke();
  badStaticInvoke();
  badInstanceInvoke();
  badConstructorInvoke();
  badSetterInvoke();
  badStaticSetterInvoke();
  badGenericConstructorInvoke();
  badGenericClassStaticInvoke();
  badGenericFactoryInvoke();
  badGenericStaticInvoke();
  badGenericSetterInvoke();
  badLibrarySetterInvoke();
}
