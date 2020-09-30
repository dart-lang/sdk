// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_type_to_string`

// SHARED

class A {
  String toString() {}
}

String takesFunction(Function f) {}

class TypeChildWithOverride extends Type {
  @override
  String toString() {}
}

class TypeGrandChildWithOverride extends TypeChildWithOverride {}

class TypeChildNoOverride extends Type {}

class TypeGrandChildNoOverride extends TypeChildNoOverride {}

mixin ToStringMixin {
  String toString() {}
}

// BAD

class Bad {
  void doBad(Function f) {
    A().runtimeType.toString(); // LINT
    TypeChildNoOverride().toString(); // LINT
    TypeGrandChildNoOverride().toString(); // LINT
  }
}

class BadWithType extends Type {
  Function passedFunction;

  BadWithType(Function func) : this.withFunc(func);
  BadWithType.withoutFunc() {}
  BadWithType.withFunc(this.passedFunction) {}
  BadWithType.withSelf(BadWithType badWithType)
      : this.withFunc(badWithType.toString); // LINT

  void doBad() {
    toString(); // LINT
    this.toString(); // LINT

    print('${toString()}'); // LINT
    print('${this.toString()}'); // LINT
    print('${takesFunction(toString)}'); // LINT
    print('${takesFunction(this.toString)}'); // LINT

    takesFunction(toString); // LINT
    takesFunction(this.toString); // LINT
    takesFunction(BadWithType.withoutFunc().toString); // LINT
    Bad().doBad(toString); // LINT
    Bad().doBad(this.toString); // LINT
    Bad().doBad(BadWithType.withoutFunc().toString); // LINT

    BadWithType(toString); // LINT
    BadWithType.withFunc(this.toString); // LINT

    ((Function internal) => internal())(toString); // LINT
  }
}

class BadWithTypeChild extends BadWithType {
  BadWithTypeChild(BadWithType badWithType)
      : super(badWithType.toString); // LINT
  BadWithTypeChild.redirect(BadWithType badWithType)
      : super.withFunc(badWithType.toString); // LINT
}

mixin callToStringOnBadWithType on BadWithType {
  void mixedBad() {
    toString(); // LINT
    this.toString(); // LINT
  }
}

extension ExtensionOnBadWithType on BadWithType {
  void extendedBad() {
    toString(); // LINT
    this.toString(); // LINT
  }
}

// GOOD

class Good {
  void doGood() {
    toString(); // OK
    A().toString(); // OK
    TypeChildWithOverride().toString(); // OK
    TypeGrandChildWithOverride().toString(); // OK

    final refToString = toString;
    refToString(); // OK?
    takesFunction(refToString); // OK
  }
}

class GoodWithType extends Type {
  Function passedFunction;

  GoodWithType.withFunc(this.passedFunction) {}
  GoodWithType.withSelf(GoodWithTypeAndMixin goodWithTypeAndMixin)
      : this.withFunc(goodWithTypeAndMixin.toString); // OK
  GoodWithType.withOther(Good good) : this.withFunc(good.toString); // OK

  void good() {
    String toString() => null;
    toString(); // OK
  }
}

class GoodWithTypeAndMixin extends Type with ToStringMixin {
  void doGood() {
    toString(); // OK
    this.toString(); // OK

    takesFunction(toString); // OK
    takesFunction(this.toString); // OK
    takesFunction(GoodWithTypeAndMixin().toString); // OK
  }
}

mixin CallToStringOnGoodWithType on GoodWithTypeAndMixin {
  void mixedGood() {
    toString(); // OK
    this.toString(); // OK
  }
}

extension ExtensionOnGoodWithTypeAndMixin on GoodWithTypeAndMixin {
  void extendedGood() {
    toString(); // OK
    this.toString(); // OK
  }
}

extension on int Function(int) {
  void extendedGood() {
    toString(); // OK
    this.toString(); // OK
  }
}
