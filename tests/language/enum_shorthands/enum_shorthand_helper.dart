// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Common classes and enums for testing enum shorthands.

// SharedOptions=--enable-experiment=enum-shorthands

enum Color { red, green, blue }

class Integer {
  static Integer get one => Integer(1);
  static Integer get two => Integer(2);
  static const Integer constOne = const Integer._(1);
  static const Integer constTwo = const Integer._(2);
  final int integer;
  Integer(this.integer);
  const Integer._(this.integer);
}

extension type IntegerExt(int integer) {
  static IntegerExt get one => IntegerExt(1);
  static IntegerExt get two => IntegerExt(2);
  static const IntegerExt constOne = const IntegerExt._(1);
  static const IntegerExt constTwo = const IntegerExt._(2);
  const IntegerExt._(this.integer);
}

mixin IntegerMixin on Integer {
  static IntegerMixin get mixinOne => _IntegerWithMixin(1);
  static IntegerMixin get mixinTwo => _IntegerWithMixin(2);
  static const IntegerMixin mixinConstOne = const _IntegerWithMixin._(1);
  static const IntegerMixin mixinConstTwo = const _IntegerWithMixin._(2);
}

class _IntegerWithMixin extends Integer with IntegerMixin {
  const _IntegerWithMixin(int integer) : this._(integer);
  const _IntegerWithMixin._(super.integer) : super._();
}

// Selector chain test declarations.

class ConstructorClass {
  final int? x;
  ConstructorClass(this.x);
  ConstructorClass.regular(this.x);
  ConstructorClass.named({this.x});
  ConstructorClass.optional([this.x]);

  const ConstructorClass.constRegular(this.x);
  const ConstructorClass.constNamed({this.x});
  const ConstructorClass.constOptional([this.x]);
}

class UnnamedConstructor {}

class UnnamedConstructorTypeParameters<T> {}

extension type ConstructorExt(int? x) {
  ConstructorExt.regular(this.x);
  ConstructorExt.named({this.x});
  ConstructorExt.optional([this.x]);

  const ConstructorExt.constRegular(this.x);
  const ConstructorExt.constNamed({this.x});
  const ConstructorExt.constOptional([this.x]);
}

class StaticMember<T> {
  static StaticMember<int> member() => StaticMember(1);
  static StaticMember<U> memberType<U, V>(U u) => StaticMember(u);

  final T t;
  StaticMember(this.t);
}

extension type StaticMemberExt<T>(T x) {
  static StaticMemberExt<int> member() => StaticMemberExt(1);
  static StaticMemberExt<U> memberType<U, V>(U u) => StaticMemberExt(u);
}
