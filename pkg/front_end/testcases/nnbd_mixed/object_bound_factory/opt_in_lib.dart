// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class1<T extends Object?> {
  factory Class1.redirect() = Class1._;
  const factory Class1.constRedirect() = Class1._;
  factory Class1.fact() => new Class1._();

  const Class1._();
}

class Class2<T extends Object> {
  factory Class2.redirect() = Class2._;
  const factory Class2.constRedirect() = Class2._;
  factory Class2.fact() => new Class2._();

  const Class2._();
}

class Class3<T extends String> {
  factory Class3.redirect() = Class3._;
  const factory Class3.constRedirect() = Class3._;
  factory Class3.fact() => new Class3._();

  const Class3._();
}

class Class4<T> {
  factory Class4.redirect() = Class4._;
  const factory Class4.constRedirect() = Class4._;
  factory Class4.fact() => new Class4._();

  const Class4._();
}

class Class5<T extends dynamic> {
  factory Class5.redirect() = Class5._;
  const factory Class5.constRedirect() = Class5._;
  factory Class5.fact() => new Class5._();

  const Class5._();
}

testOptIn() {
  new Class1.redirect();
  new Class1.constRedirect();
  const Class1.constRedirect();
  new Class1.fact();

  new Class2.redirect();
  new Class2.constRedirect();
  const Class2.constRedirect();
  new Class2.fact();

  new Class3.redirect();
  new Class3.constRedirect();
  const Class3.constRedirect();
  new Class3.fact();

  new Class4.redirect();
  new Class4.constRedirect();
  const Class4.constRedirect();
  new Class4.fact();

  new Class5.redirect();
  new Class5.constRedirect();
  const Class5.constRedirect();
  new Class5.fact();
}
