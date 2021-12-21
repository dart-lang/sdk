// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N exhaustive_cases`

// Enum-like
class E {
  final int i;
  const E._(this.i);

  static const e = E._(1);
  static const f = E._(2);
  static const g = E._(3);
}

void e(E e) {
  // Missing case.
  switch(e) { // LINT
    case E.e :
      print('e');
      break;
    case E.f :
      print('e');
  }
}

void ok(E e) {
  // All cases covered.
  switch(e) { // OK
    case E.e :
      print('e');
      break;
    case E.f :
      print('e');
      break;
    case E.g :
      print('e');
      break;
  }
}

void okDefault(E e) {
  // Missing cases w/ default is OK.
  switch(e) { // OK
    case E.e :
      print('e');
      break;
    default :
      print('default');
      break;
  }
}

// Not Enum-like
class Subclassed {
  const Subclassed._();

  static const e = Subclassed._();
  static const f = Subclassed._();
  static const g = Subclassed._();
}

class Subclass extends Subclassed {
  Subclass() : super._();
}

void s(Subclassed e) {
  switch(e) { // OK
    case Subclassed.e :
      print('e');
  }
}

// Not Enum-like
class TooFew {
  const TooFew._();

  static const e = TooFew._();
}

void t(TooFew e) {
  switch(e) { // OK
    case TooFew.e :
      print('e');
  }
}

// Not Enum-like
class PublicCons {
  const PublicCons();
  static const e = PublicCons();
  static const f = PublicCons();
}

void p(PublicCons e) {
  switch(e) { // OK
    case PublicCons.e :
      print('e');
  }
}

// Handled by analyzer
enum ActualEnum {
  e, f
}
void ae(ActualEnum e) {
  // ignore: missing_enum_constant_in_switch
  switch(e) { // OK
    case ActualEnum.e :
      print('e');
  }
}

// Some fields are deprecated.
class DeprecatedFields {
  final int i;
  const DeprecatedFields._(this.i);

  @deprecated
  static const oldFoo = newFoo;
  static const newFoo = DeprecatedFields._(1);
  static const bar = DeprecatedFields._(2);
  static const baz = DeprecatedFields._(3);
}

void dep(DeprecatedFields e) {
  switch (e) {
    // OK
    case DeprecatedFields.newFoo:
      print('newFoo');
      break;
    case DeprecatedFields.bar:
      print('bar');
      break;
    case DeprecatedFields.baz:
      print('baz');
      break;
  }

  switch (e) { // LINT
    case DeprecatedFields.newFoo:
      print('newFoo');
      break;
    case DeprecatedFields.baz:
      print('baz');
      break;
  }

  switch (e) {
    // OK
    case DeprecatedFields.oldFoo:
      print('oldFoo');
      break;
    case DeprecatedFields.bar:
      print('bar');
      break;
    case DeprecatedFields.baz:
      print('baz');
      break;
  }
}
