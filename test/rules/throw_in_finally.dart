// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N throw_in_finally`

class Ok {
  double compliantMethod() {
    var i = 5;
    try {
      i = 1 / 0;
    } catch (e) {
      print(e);
    } finally {
      i = i * i; // OK
    }
    return i;
  }
}

class BadThrow01 {
  double nonCompliantMethod() {
    try {
      print('hello world! ${1 / 0}');
    } catch (e) {
      print(e);
    } finally {
      if (1 > 0) {
        throw 'Find the hidden error :P'; // LINT
      } else {
        print('should catch nested throws!');
      }
    }
    return 1.0;
  }
}

class GoodThrow01 {
  double compliantMethod() {
    try {
      print('hello world! ${1 / 0}');
    } catch (e) {
      print(e);
    } finally {
      try {
        print(1 / 0);
      } catch (e) {
        throw new WeirdException(); // OK
      }
    }
    return 1.0;
  }
}

class WeirdException {}

Function registrationGuard;

void outer() {
  try {
    registrationGuard();
  } finally {
    registrationGuard = () {
      throw new WeirdException(); // OK
    };
  }
}
