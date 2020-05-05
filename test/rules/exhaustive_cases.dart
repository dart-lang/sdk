// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N exhaustive_cases`

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
