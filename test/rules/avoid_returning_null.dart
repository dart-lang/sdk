// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N avoid_returning_null`

bool check = true;

bool getBool1() => null; // LINT
num getNum1() => null; // LINT
int getInt1() => null; // LINT
double getDouble1() => null; // LINT

bool getBool2() {
  if (check) {
    return null; // LINT
  }
  return true;
}

num getNum2() {
  if (check) {
    return null; // LINT
  }
  return 0;
}

int getInt2() {
  if (check) {
    return null; // LINT
  }
  return 0;
}

double getDouble2() {
  if (check) {
    return null; // LINT
  }
  return 0.0;
}

class Bad1 {
  bool getBool1() => null; // LINT
  num getNum1() => null; // LINT
  int getInt1() => null; // LINT
  double getDouble1() => null; // LINT

  bool getBool2() {
    if (check) {
      return null; // LINT
    }
    return true;
  }

  num getNum2() {
    if (check) {
      return null; // LINT
    }
    return 0;
  }

  int getInt2() {
    if (check) {
      return null; // LINT
    }
    return 0;
  }

  double getDouble2() {
    if (check) {
      return null; // LINT
    }
    return 0.0;
  }
}

class Bad2 {
  static bool getBool1() => null; // LINT
  static num getNum1() => null; // LINT
  static int getInt1() => null; // LINT
  static double getDouble1() => null; // LINT

  static bool getBool2() {
    if (check) {
      return null; // LINT
    }
    return true;
  }

  static num getNum2() {
    if (check) {
      return null; // LINT
    }
    return 0;
  }

  static int getInt2() {
    if (check) {
      return null; // LINT
    }
    return 0;
  }

  static double getDouble2() {
    if (check) {
      return null; // LINT
    }
    return 0.0;
  }
}

class Bad3 {
  bool get bool1 => null; // LINT
  num get num1 => null; // LINT
  int get int1 => null; // LINT
  double get double1 => null; // LINT

  bool get bool2 {
    if (check) {
      return null; // LINT
    }
    return true;
  }

  num get num2 {
    if (check) {
      return null; // LINT
    }
    return 0;
  }

  int get int2 {
    if (check) {
      return null; // LINT
    }
    return 0;
  }

  double get double2 {
    if (check) {
      return null; // LINT
    }
    return 0.0;
  }
}

class Bad4 {
  static bool get bool1 => null; // LINT
  static num get num1 => null; // LINT
  static int get int1 => null; // LINT
  static double get double1 => null; // LINT

  static bool get bool2 {
    if (check) {
      return null; // LINT
    }
    return true;
  }

  static num get num2 {
    if (check) {
      return null; // LINT
    }
    return 0;
  }

  static int get int2 {
    if (check) {
      return null; // LINT
    }
    return 0;
  }

  static double get double2 {
    if (check) {
      return null; // LINT
    }
    return 0.0;
  }
}

class A {
  dynamic foo() {
    return null; // OK
  }

  A bar() {
    return null; // OK
  }
}

// Exclude local function expressions.
class B {
  bool getBool2() {
    final foo = () {
      return null; // OK
    };

    foo();
    return true;
  }

  num getNum2() {
    final foo = () {
      return null; // OK
    };

    foo();
    return 0;
  }

  int getInt2() {
    final foo = () {
      return null; // OK
    };

    foo();
    return 0;
  }

  double getDouble2() {
    final foo = () {
      return null; // OK
    };

    foo();
    return 0.0;
  }
}
