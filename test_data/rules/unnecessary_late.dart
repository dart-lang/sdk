// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N unnecessary_late`

late String unnecessaryTopLevelLate = ''; // LINT

late String necessaryTopLevelLate; // OK

late String unnecessaryListLateOne = '', // LINT
    unnecessaryListLateTwo = ''; // LINT

late String necessaryListLate, // OK
    unnecessaryListLate = ''; // LINT

String unnecessaryTopLevel = ''; // OK

class Test {
  static late String unnecessaryStaticLate = ''; // LINT

  static late String necessaryStaticLate; // OK

  static String unnecessaryStatic = ''; // OK

  void test() {
    late String necessaryLocal = ''; // OK
  }
}
