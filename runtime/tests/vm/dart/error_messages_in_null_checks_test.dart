// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that NoSuchMethodError thrown from null checks
// corresponding to devirtualized calls in AOT mode have detailed messages
// (dartbug.com/32863).

import "package:expect/expect.dart";

class A {
  @pragma("vm:entry-point") // Prevent obfuscation
  void foo() {
    Expect.fail('A.foo should not be reachable');
  }

  @pragma("vm:entry-point") // Prevent obfuscation
  dynamic get bar {
    Expect.fail('A.bar should not be reachable');
  }

  @pragma("vm:entry-point") // Prevent obfuscation
  set bazz(int x) {
    Expect.fail('A.bazz should not be reachable');
  }
}

dynamic myNull;
dynamic doubleNull;
dynamic intNull;

main(List<String> args) {
  // Make sure value of `myNull` is not a compile-time null and
  // devirtualization happens.
  if (args.length > 42) {
    myNull = new A();
    doubleNull = 3.14;
    intNull = 2;
  }

  Expect.throws(
      () => myNull.foo(),
      (e) =>
          e is NoSuchMethodError &&
          e.toString().startsWith(
              'NoSuchMethodError: The method \'foo\' was called on null.'));

  Expect.throws(
      () => myNull.foo,
      (e) =>
          e is NoSuchMethodError &&
          e.toString().startsWith(
              'NoSuchMethodError: The getter \'foo\' was called on null.'));

  Expect.throws(
      () => myNull.bar,
      (e) =>
          e is NoSuchMethodError &&
          e.toString().startsWith(
              'NoSuchMethodError: The getter \'bar\' was called on null.'));

  Expect.throws(
      () => myNull.bar(),
      (e) =>
          e is NoSuchMethodError &&
          e.toString().startsWith(
              'NoSuchMethodError: The method \'bar\' was called on null.'));

  Expect.throws(
      () => myNull!,
      (e) =>
          e is TypeError &&
          e.toString().contains('Null check operator used on a null value'));

  Expect.throws(() {
    myNull.bazz = 3;
  },
      (e) =>
          e is NoSuchMethodError &&
          e.toString().startsWith(
              'NoSuchMethodError: The setter \'bazz=\' was called on null.'));

  Expect.throws(
      () => doubleNull + 2.17,
      (e) =>
          e is NoSuchMethodError &&
          e.toString().startsWith(
              'NoSuchMethodError: The method \'+\' was called on null.'));

  Expect.throws(
      () => 9.81 - doubleNull,
      (e) => hasUnsoundNullSafety
          ? (e is NoSuchMethodError &&
              // If '-' is specialized.
              (e.toString().startsWith(
                      'NoSuchMethodError: The method \'-\' was called on null.') ||
                  // If '-' is not specialized, it calls toDouble() internally.
                  e.toString().startsWith(
                      'NoSuchMethodError: The method \'toDouble\' was called on null.')))
          : (e is TypeError));

  Expect.throws(
      () => intNull * 7,
      (e) =>
          e is NoSuchMethodError &&
          e.toString().startsWith(
              'NoSuchMethodError: The method \'*\' was called on null.'));
}
