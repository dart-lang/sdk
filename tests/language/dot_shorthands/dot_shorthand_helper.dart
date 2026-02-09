// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Common classes and enums for testing dot shorthands.

enum Color { red, green, blue }

class Integer {
  static Integer get one => Integer(1);
  static Integer get two => Integer(2);
  static Integer? get nullable => null;
  static const Integer constOne = const Integer._(1);
  static const Integer constTwo = const Integer._(2);
  final int integer;
  Integer(this.integer);
  const Integer._(this.integer);
}

extension type IntegerExt(int integer) {
  static IntegerExt get one => IntegerExt(1);
  static IntegerExt get two => IntegerExt(2);
  static IntegerExt? get nullable => null;
  static const IntegerExt constOne = const IntegerExt._(1);
  static const IntegerExt constTwo = const IntegerExt._(2);
  const IntegerExt._(this.integer);
}

mixin IntegerMixin on Integer {
  static IntegerMixin get mixinOne => _IntegerWithMixin(1);
  static IntegerMixin get mixinTwo => _IntegerWithMixin(2);
  static IntegerMixin? get mixinNullable => null;
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

  ConstructorClass.integer(Integer integer) : x = 1;

  ConstructorClass.staticMember(StaticMember member) : x = 1;
  ConstructorClass.staticMemberExt(StaticMemberExt member) : x = 1;

  ConstructorClass.ctor(ConstructorClass ctor) : x = 1;

  const ConstructorClass.constRegular(this.x);
  const ConstructorClass.constNamed({this.x});
  const ConstructorClass.constOptional([this.x]);
}

class ConstructorWithNonFinal {
  final int x;

  ConstructorWithNonFinal get field => _constConstructorWithNonFinal;

  ConstructorWithNonFinal(this.x);
  const ConstructorWithNonFinal.constNamed(this.x);

  ConstructorWithNonFinal method() => ConstructorWithNonFinal(1);

  ConstructorWithNonFinal? methodNullable() => null;
}

// Prevent infinite recursion with fields.
const ConstructorWithNonFinal _constConstructorWithNonFinal =
    _ConstructorWithNonFinalSubclass(1);

class _ConstructorWithNonFinalSubclass extends ConstructorWithNonFinal {
  const _ConstructorWithNonFinalSubclass(int x) : super.constNamed(x);
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
  static StaticMember<int>? memberNullable() => null;
  static StaticMember<U> memberType<U, V>(U u) => StaticMember(u);
  static StaticMember<U>? memberTypeNullable<U, V>(U u) => null;

  static StaticMember<ConstructorClass> ctor(ConstructorClass c) =>
      StaticMember(c);

  static StaticMember<Integer> property(Integer i) => StaticMember(i);

  final T t;
  StaticMember get field => _constStaticMember;

  StaticMember(this.t);

  const StaticMember.constNamed(this.t);

  StaticMember method() => StaticMember.member();
  StaticMember? methodNullable() => null;
}

// Prevent infinite recursion with fields.
const StaticMember _constStaticMember = _StaticMemberSubclass(1);

class _StaticMemberSubclass<T> extends StaticMember<T> {
  const _StaticMemberSubclass(T t) : super.constNamed(t);
}

extension type StaticMemberExt<T>(T x) {
  static StaticMemberExt<int> member() => StaticMemberExt(1);
  static StaticMemberExt<int>? memberNullable() => null;
  static StaticMemberExt<U> memberType<U, V>(U u) => StaticMemberExt(u);
  static StaticMemberExt<U>? memberTypeNullable<U, V>(U u) => null;

  static StaticMemberExt<ConstructorClass> ctor(ConstructorClass c) =>
      StaticMemberExt(c);

  static StaticMemberExt<Integer> property(Integer i) => StaticMemberExt(i);
}
